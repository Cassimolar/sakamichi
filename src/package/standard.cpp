#include "standard.h"
#include "serverplayer.h"
#include "room.h"
#include "skill.h"
#include "maneuvering.h"
#include "clientplayer.h"
#include "engine.h"
#include "client.h"
#include "exppattern.h"
#include "roomthread.h"
#include "wrapped-card.h"

QString BasicCard::getType() const
{
    return "basic";
}

Card::CardType BasicCard::getTypeId() const
{
    return TypeBasic;
}

TrickCard::TrickCard(Suit suit, int number)
    : Card(suit, number), cancelable(true)
{
    handling_method = Card::MethodUse;
}

void TrickCard::setCancelable(bool cancelable)
{
    this->cancelable = cancelable;
}

QString TrickCard::getType() const
{
    return "trick";
}

Card::CardType TrickCard::getTypeId() const
{
    return TypeTrick;
}

bool TrickCard::isCancelable(const CardEffectStruct &effect) const
{
    Q_UNUSED(effect);
    return cancelable;
}

QString EquipCard::getType() const
{
    return "equip";
}

Card::CardType EquipCard::getTypeId() const
{
    return TypeEquip;
}

bool EquipCard::isAvailable(const Player *player) const
{
    if (this->targetFixed()) {
        const EquipCard *equip = qobject_cast<const EquipCard *>(this->getRealCard());
        int equip_index = static_cast<int>(equip->location());
        return !player->isProhibited(player, this) && Card::isAvailable(player) && player->hasEquipArea(equip_index);
    }
    return Card::isAvailable(player);
}

void EquipCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;

    ServerPlayer *player = use.from;
    if (use.to.isEmpty())
        use.to << player;

    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();
    thread->trigger(PreCardUsed, room, use.from, data);

    use = data.value<CardUseStruct>();

    QList<int> used_cards;
    used_cards << card_use.card->getEffectiveId();

    QList<CardsMoveStruct> moves;
    CardMoveReason reason(CardMoveReason::S_REASON_USE, use.from->objectName(), QString(), use.card->getSkillName(), QString());
    if (card_use.to.size() == 1)
        reason.m_targetId = use.to.first()->objectName();
    reason.m_extraData = QVariant::fromValue(use.card);
    foreach (int id, used_cards) {
        CardsMoveStruct move(id, NULL, Player::PlaceTable, reason);
        moves.append(move);
    }
    room->moveCardsAtomic(moves, true);

    thread->trigger(CardUsed, room, use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, use.from, data);
}

void EquipCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (targets.isEmpty() || targets.first()->isDead()) {
        CardMoveReason reason(CardMoveReason::S_REASON_USE, source->objectName(), QString(), this->getSkillName(), QString());
        room->moveCardTo(this, NULL, Player::DiscardPile, reason, true);
    }
    int equipped_id = Card::S_UNKNOWN_CARD_ID;
    ServerPlayer *target = targets.first();
    if (target->getEquip(location()))
        equipped_id = target->getEquip(location())->getEffectiveId();

    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1(getEffectiveId(), target, Player::PlaceEquip,
        CardMoveReason(CardMoveReason::S_REASON_USE, target->objectName()));
    exchangeMove.push_back(move1);
    if (equipped_id != Card::S_UNKNOWN_CARD_ID) {
        CardsMoveStruct move2(equipped_id, NULL, Player::DiscardPile,
            CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, target->objectName()));
        exchangeMove.push_back(move2);
    }
    LogMessage log;
    log.from = target;
    log.type = "$Install";
    log.card_str = QString::number(getEffectiveId());
    room->sendLog(log);

    room->moveCardsAtomic(exchangeMove, true);
}

static bool isEquipSkillViewAsSkill(const Skill *s)
{
    if (s == NULL)
        return false;

    if (s->inherits("ViewAsSkill"))
        return true;

    if (s->inherits("TriggerSkill")) {
        const TriggerSkill *ts = qobject_cast<const TriggerSkill *>(s);
        if (ts == NULL)
            return false;

        if (ts->getViewAsSkill() != NULL)
            return true;
    }

    return false;
}

void EquipCard::onInstall(ServerPlayer *player) const
{
    const Skill *skill = Sanguosha->getSkill(this);

    if (skill != NULL) {
        Room *room = player->getRoom();
        if (skill->inherits("TriggerSkill")) {
            const TriggerSkill *trigger_skill = qobject_cast<const TriggerSkill *>(skill);
            room->getThread()->addTriggerSkill(trigger_skill);
        }

        if (isEquipSkillViewAsSkill(skill))
            room->attachSkillToPlayer(player, objectName());
    }
}

void EquipCard::onUninstall(ServerPlayer *player) const
{
    const Skill *skill = Sanguosha->getSkill(this);
    if (isEquipSkillViewAsSkill(skill))
        player->getRoom()->detachSkillFromPlayer(player, objectName(), true);
}

QString GlobalEffect::getSubtype() const
{
    return "global_effect";
}

void GlobalEffect::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    QList<ServerPlayer *> targets, all_players = room->getAllPlayers();
    foreach (ServerPlayer *player, all_players) {
        const ProhibitSkill *skill = room->isProhibited(source, player, this);
        if (skill) {
            if (skill->isVisible()) {
                LogMessage log;
                log.type = "#SkillAvoid";
                log.from = player;
                log.arg = skill->objectName();
                log.arg2 = objectName();
                room->sendLog(log);

                room->notifySkillInvoked(player, skill->objectName());
                room->broadcastSkillInvoke(skill->objectName());
            } else {
                const Skill *new_skill = Sanguosha->getMainSkill(skill->objectName());
                if (new_skill && new_skill->isVisible()) {
                    if (player->hasSkill(new_skill)) {
                        QString skill_name = new_skill->objectName();
                        LogMessage log;
                        log.type = "#SkillAvoid";
                        log.from = player;
                        log.arg = skill_name;
                        log.arg2 = objectName();
                        room->sendLog(log);

                        room->notifySkillInvoked(player, skill_name);
                        room->broadcastSkillInvoke(skill_name);
                    } else if (source->hasSkill(new_skill)) {
                        QString skill_name = new_skill->objectName();
                        LogMessage log;
                        log.type = "#SkillAvoidFrom";
                        log.from = source;
                        log.to << player;
                        log.arg = skill_name;
                        log.arg2 = objectName();
                        room->sendLog(log);

                        room->notifySkillInvoked(source, skill_name);
                        room->broadcastSkillInvoke(skill_name);
                    }
                }
            }
        } else
            targets << player;
    }

    CardUseStruct use = card_use;
    use.to = targets;
    TrickCard::onUse(room, use);
}

bool GlobalEffect::isAvailable(const Player *player) const
{
    bool canUse = false;
    QList<const Player *> players = player->getAliveSiblings();
    players << player;
    foreach (const Player *p, players) {
        if (player->isProhibited(p, this))
            continue;

        canUse = true;
        break;
    }

    return canUse && TrickCard::isAvailable(player);
}

QString AOE::getSubtype() const
{
    return "aoe";
}

bool AOE::isAvailable(const Player *player) const
{
    bool canUse = false;
    QList<const Player *> players = player->getAliveSiblings();
    foreach (const Player *p, players) {
        if (player->isProhibited(p, this))
            continue;

        canUse = true;
        break;
    }

    return canUse && TrickCard::isAvailable(player);
}

void AOE::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    QList<ServerPlayer *> targets, other_players = room->getOtherPlayers(source);
    foreach (ServerPlayer *player, other_players) {
        const ProhibitSkill *skill = room->isProhibited(source, player, this);
        if (skill) {
            if (skill->isVisible()) {
                LogMessage log;
                log.type = "#SkillAvoid";
                log.from = player;
                log.arg = skill->objectName();
                log.arg2 = objectName();
                room->sendLog(log);

                room->notifySkillInvoked(player, skill->objectName());
                room->broadcastSkillInvoke(skill->objectName());
            } else {
                const Skill *new_skill = Sanguosha->getMainSkill(skill->objectName());
                if (new_skill && new_skill->isVisible()) {
                    if (player->hasSkill(new_skill)) {
                        QString skill_name = new_skill->objectName();
                        LogMessage log;
                        log.type = "#SkillAvoid";
                        log.from = player;
                        log.arg = skill_name;
                        log.arg2 = objectName();
                        room->sendLog(log);

                        room->notifySkillInvoked(player, skill_name);
                        room->broadcastSkillInvoke(skill_name);
                    } else if (source->hasSkill(new_skill)) {
                        QString skill_name = new_skill->objectName();
                        LogMessage log;
                        log.type = "#SkillAvoidFrom";
                        log.from = source;
                        log.to << player;
                        log.arg = skill_name;
                        log.arg2 = objectName();
                        room->sendLog(log);

                        room->notifySkillInvoked(source, skill_name);
                        room->broadcastSkillInvoke(skill_name);
                    }
                }
            }
        } else
            targets << player;
    }

    CardUseStruct use = card_use;
    use.to = targets;
    TrickCard::onUse(room, use);
}

QString SingleTargetTrick::getSubtype() const
{
    return "single_target_trick";
}

bool SingleTargetTrick::targetFilter(const QList<const Player *> &, const Player *, const Player *) const
{
    return true;
}

DelayedTrick::DelayedTrick(Suit suit, int number, bool movable)
    : TrickCard(suit, number), movable(movable)
{
    judge.negative = true;
}

void DelayedTrick::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    WrappedCard *wrapped = Sanguosha->getWrappedCard(this->getEffectiveId());
    use.card = wrapped;

    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();
    thread->trigger(PreCardUsed, room, use.from, data);
    use = data.value<CardUseStruct>();

    LogMessage log;
    log.from = use.from;
    log.to = use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    //CardMoveReason reason(CardMoveReason::S_REASON_USE, use.from->objectName(), use.to.first()->objectName(), this->getSkillName(), QString());
    //room->moveCardTo(this, use.to.first(), Player::PlaceDelayedTrick, reason, true);

    QList<int> used_cards;
    used_cards << use.card->getEffectiveId();

    QList<CardsMoveStruct> moves;
    CardMoveReason reason(CardMoveReason::S_REASON_USE, use.from->objectName(), QString(), use.card->getSkillName(), QString());
    if (card_use.to.size() == 1)
        reason.m_targetId = use.to.first()->objectName();
    reason.m_extraData = QVariant::fromValue(use.card);
    foreach (int id, used_cards) {
        CardsMoveStruct move(id, NULL, Player::PlaceTable, reason);
        moves.append(move);
    }
    room->moveCardsAtomic(moves, true);

    thread->trigger(CardUsed, room, use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, use.from, data);
}

void DelayedTrick::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QStringList nullified_list = room->getTag("CardUseNullifiedList").toStringList();
    bool all_nullified = nullified_list.contains("_ALL_TARGETS");
    //if (all_nullified || targets.isEmpty()) {
    if (all_nullified || targets.isEmpty() || nullified_list.contains(targets.first()->objectName())) {
        if (movable) {
            onNullified(source);
            if (room->getCardOwner(getEffectiveId()) != source) return;
        }
        CardMoveReason reason(CardMoveReason::S_REASON_USE, source->objectName(), QString(), this->getSkillName(), QString());
        //room->moveCardTo(this, room->getCardOwner(getEffectiveId()), NULL, Player::DiscardPile, reason, true);
        reason.m_extraData = QVariant::fromValue(this->getRealCard());
        room->moveCardTo(this, source, NULL, Player::DiscardPile, reason, true);
    } else {
        if (targets.first()->isAlive()) {
            CardMoveReason reason(CardMoveReason::S_REASON_USE, source->objectName(), targets.first()->objectName(), this->getSkillName(), QString());
            reason.m_extraData = QVariant::fromValue(this->getRealCard());
            room->moveCardTo(this, targets.first(), Player::PlaceDelayedTrick, reason, true);
        } else {
            CardMoveReason reason(CardMoveReason::S_REASON_USE, source->objectName(), targets.first()->objectName(), this->getSkillName(), QString());
            reason.m_extraData = QVariant::fromValue(this->getRealCard());
            room->moveCardTo(this, NULL, NULL, Player::DiscardPile, reason, true);
        }
    }
}

QString DelayedTrick::getSubtype() const
{
    return "delayed_trick";
}

void DelayedTrick::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    CardMoveReason reason(CardMoveReason::S_REASON_USE, effect.to->objectName(), getSkillName(), QString());
    room->moveCardTo(this, NULL, Player::PlaceTable, reason, true);

    LogMessage log;
    log.from = effect.to;
    log.type = "#DelayedTrick";
    log.arg = effect.card->objectName();
    room->sendLog(log);

    JudgeStruct judge_struct = judge;
    judge_struct.who = effect.to;
    room->judge(judge_struct);

    if (judge_struct.isBad()) {
        takeEffect(effect.to);
        if (room->getCardOwner(getEffectiveId()) == NULL) {
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, QString());
            room->throwCard(this, reason, NULL);
        }
    } else if (movable) {
        onNullified(effect.to);
    } else {
        if (room->getCardOwner(getEffectiveId()) == NULL) {
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, QString());
            room->throwCard(this, reason, NULL);
        }
    }
}

void DelayedTrick::onNullified(ServerPlayer *target) const
{
    Room *room = target->getRoom();
    RoomThread *thread = room->getThread();
    if (movable) {
        QList<ServerPlayer *> players = room->getOtherPlayers(target);
        players << target;
        ServerPlayer *p = NULL;

        foreach (ServerPlayer *player, players) {
            if (player->containsTrick(objectName()))
                continue;

            const ProhibitSkill *skill = room->isProhibited(target, player, this);
            if (skill) {
                if (skill->isVisible()) {
                    LogMessage log;
                    log.type = "#SkillAvoid";
                    log.from = player;
                    log.arg = skill->objectName();
                    log.arg2 = objectName();
                    room->sendLog(log);

                    room->notifySkillInvoked(player, skill->objectName());
                    room->broadcastSkillInvoke(skill->objectName());
                } else {
                    const Skill *new_skill = Sanguosha->getMainSkill(skill->objectName());
                    if (new_skill && new_skill->isVisible()) {
                        if (player->hasSkill(new_skill)) {
                            QString skill_name = new_skill->objectName();
                            LogMessage log;
                            log.type = "#SkillAvoid";
                            log.from = player;
                            log.arg = skill_name;
                            log.arg2 = objectName();
                            room->sendLog(log);

                            room->notifySkillInvoked(player, skill_name);
                            room->broadcastSkillInvoke(skill_name);
                        } else if (target->hasSkill(new_skill)) {
                            QString skill_name = new_skill->objectName();
                            LogMessage log;
                            log.type = "#SkillAvoidFrom";
                            log.from = target;
                            log.to << player;
                            log.arg = skill_name;
                            log.arg2 = objectName();
                            room->sendLog(log);

                            room->notifySkillInvoked(target, skill_name);
                            room->broadcastSkillInvoke(skill_name);
                        }
                    }
                }
                continue;
            }

            CardMoveReason reason(CardMoveReason::S_REASON_TRANSFER, target->objectName(), QString(), this->getSkillName(), QString());
            room->moveCardTo(this, target, player, Player::PlaceDelayedTrick, reason, true);

            if (target == player) break;

            CardUseStruct use;
            use.from = NULL;
            use.to << player;
            use.card = this;
            QVariant data = QVariant::fromValue(use);
            thread->trigger(TargetConfirming, room, player, data);
            CardUseStruct new_use = data.value<CardUseStruct>();
            if (new_use.to.isEmpty()) {
                p = player;
                break;
            }

            foreach(ServerPlayer *p, room->getAllPlayers())
                thread->trigger(TargetConfirmed, room, p, data);
            break;
        }
        if (p)
            onNullified(p);
    } else {
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, target->objectName());
        room->throwCard(this, reason, NULL);
    }
}

Weapon::Weapon(Suit suit, int number, int range)
    : EquipCard(suit, number), range(range)
{
    can_recast = true;
}

bool Weapon::isAvailable(const Player *player) const
{
    QString mode = player->getGameMode();
    if (mode == "04_1v3" && !player->isCardLimited(this, Card::MethodRecast))
        return true;
    return !player->isCardLimited(this, Card::MethodUse) && EquipCard::isAvailable(player);
}

int Weapon::getRange() const
{
    return range;
}

QString Weapon::getSubtype() const
{
    return "weapon";
}

void Weapon::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    ServerPlayer *player = card_use.from;
    if (room->getMode() == "04_1v3"
        && use.card->isKindOf("Weapon")
        && (player->isCardLimited(use.card, Card::MethodUse)
        || (!player->getHandPile().contains(getEffectiveId())
        && player->askForSkillInvoke("weapon_recast", QVariant::fromValue(use))))) {
        CardMoveReason reason(CardMoveReason::S_REASON_RECAST, player->objectName());
        reason.m_eventName = "weapon_recast";
        room->moveCardTo(use.card, player, NULL, Player::DiscardPile, reason);
        player->broadcastSkillInvoke("@recast");

        LogMessage log;
        log.type = "#UseCard_Recast";
        log.from = player;
        log.card_str = use.card->toString();
        room->sendLog(log);

        player->drawCards(1, "weapon_recast");
        return;
    }
    EquipCard::onUse(room, use);
}

EquipCard::Location Weapon::location() const
{
    return WeaponLocation;
}

QString Weapon::getCommonEffectName() const
{
    return "weapon";
}

QString Armor::getSubtype() const
{
    return "armor";
}

EquipCard::Location Armor::location() const
{
    return ArmorLocation;
}

QString Armor::getCommonEffectName() const
{
    return "armor";
}

Horse::Horse(Suit suit, int number, int correct)
    : EquipCard(suit, number), correct(correct)
{
}

int Horse::getCorrect() const
{
    return correct;
}

void Horse::onInstall(ServerPlayer *) const
{
}

void Horse::onUninstall(ServerPlayer *) const
{
}

QString Horse::getCommonEffectName() const
{
    return "horse";
}

OffensiveHorse::OffensiveHorse(Card::Suit suit, int number, int correct)
    : Horse(suit, number, correct)
{
}

QString OffensiveHorse::getSubtype() const
{
    return "offensive_horse";
}

DefensiveHorse::DefensiveHorse(Card::Suit suit, int number, int correct)
    : Horse(suit, number, correct)
{
}

QString DefensiveHorse::getSubtype() const
{
    return "defensive_horse";
}

EquipCard::Location Horse::location() const
{
    if (correct > 0)
        return DefensiveHorseLocation;
    else
        return OffensiveHorseLocation;
}

QString Treasure::getSubtype() const
{
    return "treasure";
}

EquipCard::Location Treasure::location() const
{
    return TreasureLocation;
}

QString Treasure::getCommonEffectName() const
{
    return "treasure";
}

class GameRuleProhibit : public ProhibitSkill
{
public:
    GameRuleProhibit() : ProhibitSkill("gameruleprohibit")
    {
    }

    bool isProhibited(const Player *, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (card->isKindOf("DelayedTrick"))
            return !to->hasJudgeArea();
        else if (card->isKindOf("EquipCard")) {
            const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
            int equip_index = static_cast<int>(equip->location());
            return !to->hasEquipArea(equip_index);
        }
        return false;
    }
};

class GameRuleEquipMove : public TriggerSkill
{
public:
    GameRuleEquipMove() : TriggerSkill("gameruleequipmove")
    {
        events << BeforeCardsMove;
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 6;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.to || move.to_place != Player::PlaceEquip) return false;
        DummyCard *dummy = new DummyCard;
        foreach (int id, move.card_ids) {
            const Card *card = Sanguosha->getEngineCard(id);
            if (!card->isKindOf("EquipCard")) continue;
            const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
            int equip_index = static_cast<int>(equip->location());
            if (move.to->hasEquipArea(equip_index)) continue;
            dummy->addSubcard(card);
        }
        if (dummy->getSubcards().isEmpty()) {
            delete dummy;
            return false;
        }
        move.removeCardIds(dummy->getSubcards());
        data = QVariant::fromValue(move);
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, move.from->objectName() , "" , "");
        room->throwCard(dummy, reason, NULL);
        delete dummy;
        return false;
    }
};

class GameRuleMaxCards : public MaxCardsSkill
{
public:
    GameRuleMaxCards() : MaxCardsSkill("gamerulemaxcards")
    {
    }

    int getExtra(const Player *target) const
    {
        int a = target->property("ExtraMaxCards_OneTurn").toInt();
        int b = target->property("ExtraMaxCards_Forever").toInt();
        return a + b;
    }
};

class GameRuleAttackRange : public AttackRangeSkill
{
public:
    GameRuleAttackRange() : AttackRangeSkill("gameruleattackrange")
    {
    }

    int getExtra(const Player *target, bool) const
    {
        int a = target->property("ExtraAttackRange_OneTurn").toInt();
        int b = target->property("ExtraAttackRange_Forever").toInt();
        return a + b;
    }
};

class GameRuleSlashBuff : public TargetModSkill
{
public:
    GameRuleSlashBuff() : TargetModSkill("gameruleslashbuff")
    {
        pattern = "Slash";
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        int a = from->property("ExtraSlashCishu_OneTurn").toInt();
        int b = from->property("ExtraSlashCishu_Forever").toInt();
        return a + b;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        int a = from->property("ExtraSlashJuli_OneTurn").toInt();
        int b = from->property("ExtraSlashJuli_Forever").toInt();
        return a + b;
    }

    int getExtraTargetNum(const Player *from, const Card *) const
    {
        int a = from->property("ExtraSlashMubiao_OneTurn").toInt();
        int b = from->property("ExtraSlashMubiao_Forever").toInt();
        return a + b;
    }
};

class GameRuleDistanceFrom : public DistanceSkill
{
public:
    GameRuleDistanceFrom() : DistanceSkill("gameruledistancefrom")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        int a = from->property("ExtraDistance_From_OneTurn").toInt();
        int b = from->property("ExtraDistance_From_Forever").toInt();
        return a + b;
    }
};

class GameRuleDistanceTo : public DistanceSkill
{
public:
    GameRuleDistanceTo() : DistanceSkill("gameruledistanceto")
    {
    }

    int getCorrect(const Player *, const Player *to) const
    {
        int a = to->property("ExtraDistance_To_OneTurn").toInt();
        int b = to->property("ExtraDistance_To_Forever").toInt();
        return a + b;
    }
};

class GameRuleChangeSkillState : public TriggerSkill
{
public:
    GameRuleChangeSkillState() : TriggerSkill("gamerulechangeskillstate")
    {
        events << GameStart << EventAcquireSkill << EventLoseSkill;
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 3;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GameStart) {
            foreach (const Skill *sk, player->getSkillList()) {
                if (sk->isChangeSkill()) {
                    int n = player->getChangeSkillState(sk->objectName());
                    room->setChangeSkillState(player, sk->objectName(), n);
                }
            }
        } else if (event == EventAcquireSkill) {
            const Skill *sk = Sanguosha->getSkill(data.toString());
            if (sk && sk->isVisible() && sk->isChangeSkill()) {
                int n = player->getChangeSkillState(sk->objectName());
                room->setChangeSkillState(player, sk->objectName(), n);
            }
        } else if (event == EventLoseSkill) {
            const Skill *sk = Sanguosha->getSkill(data.toString());
            if (sk && sk->isVisible() && sk->isChangeSkill()) {
                int n = player->getChangeSkillState(sk->objectName());
                room->setPlayerMark(player, "&" + sk->objectName() + "+" + QString::number(n) + "_num", 0);
            }
        }
        return false;
    }
};

StandardPackage::StandardPackage()
    : Package("standard")
{
    addGenerals();

    patterns["."] = new ExpPattern(".|.|.|hand");
    patterns[".S"] = new ExpPattern(".|spade|.|hand");
    patterns[".C"] = new ExpPattern(".|club|.|hand");
    patterns[".H"] = new ExpPattern(".|heart|.|hand");
    patterns[".D"] = new ExpPattern(".|diamond|.|hand");

    patterns[".black"] = new ExpPattern(".|black|.|hand");
    patterns[".red"] = new ExpPattern(".|red|.|hand");

    patterns[".."] = new ExpPattern(".");
    patterns["..S"] = new ExpPattern(".|spade");
    patterns["..C"] = new ExpPattern(".|club");
    patterns["..H"] = new ExpPattern(".|heart");
    patterns["..D"] = new ExpPattern(".|diamond");

    patterns[".Basic"] = new ExpPattern("BasicCard");
    patterns[".Trick"] = new ExpPattern("TrickCard");
    patterns[".Equip"] = new ExpPattern("EquipCard");

    patterns[".Weapon"] = new ExpPattern("Weapon");
    patterns["slash"] = new ExpPattern("Slash");
    patterns["jink"] = new ExpPattern("Jink");
    patterns["peach"] = new  ExpPattern("Peach");
    patterns["nullification"] = new ExpPattern("Nullification");
    patterns["peach+analeptic"] = new ExpPattern("Peach,Analeptic");

    skills << new GameRuleProhibit << new GameRuleEquipMove << new GameRuleMaxCards << new GameRuleAttackRange << new GameRuleSlashBuff
           << new GameRuleDistanceFrom <<  new GameRuleDistanceTo << new GameRuleChangeSkillState;
}

ADD_PACKAGE(Standard)

