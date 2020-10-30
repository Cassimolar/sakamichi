#include "jxtp.h"
#include "settings.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "engine.h"
#include "maneuvering.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "json.h"
#include "exppattern.h"
#include "yjcm2013.h"

TenyearZhihengCard::TenyearZhihengCard()
{
    target_fixed = true;
    will_throw = true;
    mute = true;
}

void TenyearZhihengCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();

    if (card_use.from->hasInnateSkill("tenyearzhiheng") || !card_use.from->hasSkill("jilve"))
        room->broadcastSkillInvoke("tenyearzhiheng");
    else
        room->broadcastSkillInvoke("jilve", 4);

    LogMessage log;
    log.from = card_use.from;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    bool allhand = true;
    if (card_use.from->isKongcheng())
        allhand = false;
    if (allhand) {
        QList<int> sub = subcards;
        foreach(int id, card_use.from->handCards()) {
            if (!sub.contains(id)) {
                allhand = false;
                break;
            }
        }
    }
    if (allhand)
        room->setCardFlag(this, "tenyearzhiheng_all_handcard_" + card_use.from->objectName());

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, card_use.from->objectName(), QString(), "tenyearzhiheng", QString());
    room->moveCardTo(this, card_use.from, NULL, Player::DiscardPile, reason, true);

    thread->trigger(CardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void TenyearZhihengCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int x = subcardsLength();
    if (hasFlag("tenyearzhiheng_all_handcard_" + source->objectName()))
        x++;
    source->drawCards(x, "tenyearzhiheng");
}

class TenyearZhiheng : public ViewAsSkill
{
public:
    TenyearZhiheng() : ViewAsSkill("tenyearzhiheng")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        TenyearZhihengCard *zhiheng_card = new TenyearZhihengCard;
        zhiheng_card->addSubcards(cards);
        return zhiheng_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("TenyearZhihengCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@tenyearzhiheng";
    }
};

class TenyearJiuyuan : public TriggerSkill
{
public:
    TenyearJiuyuan() : TriggerSkill("tenyearjiuyuan$")
    {
        events << CardUsed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getKingdom() == "wu";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Peach") || !use.to.contains(player)) return false;
        QList<ServerPlayer *> sunquans;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->hasLordSkill(this)) continue;
            if (player->getHp() > p->getHp() && p->getLostHp() > 0)
                sunquans << p;
        }
        if (sunquans.isEmpty()) return false;
        ServerPlayer *sunquan = room->askForPlayerChosen(player, sunquans, objectName(), "@tenyearjiuyuan-invoke", true);
        if (!sunquan) return false;
        LogMessage log;
        log.type = "#InvokeOthersSkill";
        log.from = player;
        log.to << sunquan;
        log.arg = "tenyearjiuyuan";
        room->sendLog(log);
        if (!sunquan->isWeidi()) {
            room->notifySkillInvoked(sunquan, objectName());
            room->broadcastSkillInvoke(objectName());
        } else {
            room->notifySkillInvoked(sunquan, "weidi");
            room->broadcastSkillInvoke("weidi");
        }
        room->recover(sunquan, RecoverStruct(player));
        player->drawCards(1, objectName());
        return true;
    }
};

TenyearJieyinCard::TenyearJieyinCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool TenyearJieyinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
    if (equip) {
        int equip_index = static_cast<int>(equip->location());
        if (Self->getEquip(equip_index) == equip)
            return targets.isEmpty() && to_select->isMale() && !to_select->getEquip(equip_index) && !Self->isProhibited(to_select, card);
    }
    return targets.isEmpty() && to_select->isMale();
}

void TenyearJieyinCard::onEffect(const CardEffectStruct &effect) const
{
    const Card *card = Sanguosha->getCard(this->getSubcards().first());
    Room *room = effect.from->getRoom();
    bool move = false;
    if (card->isKindOf("EquipCard")) {
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        int equip_index = static_cast<int>(equip->location());
        if (!effect.to->getEquip(equip_index) && !effect.from->isProhibited(effect.to, card))
            move = true;
    }
    if (move) {
        LogMessage log;
        log.type = "$ZhijianEquip";
        log.from = effect.to;
        log.card_str = QString::number(getEffectiveId());
        room->sendLog(log);
        room->moveCardTo(card, effect.from, effect.to, Player::PlaceEquip,
            CardMoveReason(CardMoveReason::S_REASON_PUT,
            effect.from->objectName(), "tenyearjieyin", QString()));
    } else {
        if (!effect.from->canDiscard(effect.from, card->getEffectiveId())) return;
        CardMoveReason reason(CardMoveReason::S_REASON_THROW, effect.from->objectName(), "tenyearjieyin", QString());
        room->throwCard(this, reason, effect.from, NULL);
    }

    if (effect.from->getHp() == effect.to->getHp()) return;
    RecoverStruct recover(effect.from);
    if (effect.from->getHp() < effect.to->getHp()) {
        room->recover(effect.from, recover, true);
        effect.to->drawCards(1, "tenyearjieyin");
    } else {
        effect.from->drawCards(1, "tenyearjieyin");
        room->recover(effect.to, recover, true);
    }
}

class TenyearJieyin : public OneCardViewAsSkill
{
public:
    TenyearJieyin() :OneCardViewAsSkill("tenyearjieyin")
    {
    }

    bool viewFilter(const Card *to_select) const
    {
        if (to_select->isKindOf("EquipCard"))
            return true;
        return Self->canDiscard(Self, to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearJieyinCard *c = new TenyearJieyinCard();
        c->addSubcard(originalCard);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearJieyinCard");
    }
};

TenyearRendeCard::TenyearRendeCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool TenyearRendeCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getMark("tenyearrendetarget-PlayClear") <= 0;
}

void TenyearRendeCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "tenyearrende", QString());
    room->obtainCard(effect.to, this, reason, false);
    room->addPlayerMark(effect.to, "tenyearrendetarget-PlayClear");

    int old_value = effect.from->getMark("tenyearrende-PlayClear");
    int new_value = old_value + subcards.length();
    room->setPlayerMark(effect.from, "tenyearrende-PlayClear", new_value);

    if (old_value < 2 && new_value >= 2) {
        QList<int> list = room->getAvailableCardList(effect.from, "basic", "tenyearrende");
        if (list.isEmpty()) return;
        room->fillAG(list, effect.from);
        int id = room->askForAG(effect.from, list, true, "tenyearrende", "@tenyearrende-basic");
        room->clearAG(effect.from);
        if (id < 0) return;
        QString name = Sanguosha->getEngineCard(id)->objectName();
        room->setPlayerMark(effect.from, "tenyearrende_id-PlayClear", id + 1);
        Card *card = Sanguosha->cloneCard(name);
        if (!card) return;
        card->deleteLater();
        card->setSkillName("_tenyearrende");
        if (card->targetFixed()) {
            if (!effect.from->askForSkillInvoke("tenyearrende", QString("tenyearrende:%1").arg(name), false)) return;
            room->useCard(CardUseStruct(card, effect.from, effect.from));
        } else
            room->askForUseCard(effect.from, "@@tenyearrende", "@tenyearrende:" + name);
    }
}

class TenyearRende : public ViewAsSkill
{
public:
    TenyearRende() : ViewAsSkill("tenyearrende")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@tenyearrende")
            return false;
        return !to_select->isEquipped();
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearrende";
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (cards.isEmpty())
                return NULL;

            TenyearRendeCard *rende_card = new TenyearRendeCard;
            rende_card->addSubcards(cards);
            return rende_card;
        } else {
            if (!cards.isEmpty()) return NULL;
            int id = Self->getMark("tenyearrende_id-PlayClear") - 1;
            if (id < 0) return NULL;
            QString name = Sanguosha->getEngineCard(id)->objectName();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) return NULL;
            card->setSkillName("_tenyearrende");
            return card;
        }
    }
};

class TenyearWusheng : public OneCardViewAsSkill
{
public:
    TenyearWusheng() : OneCardViewAsSkill("tenyearwusheng")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.contains("slash") || pattern.contains("Slash");
    }

    bool viewFilter(const Card *card) const
    {
        if (!card->isRed())
            return false;

        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            Slash *slash = new Slash(Card::SuitToBeDecided, -1);
            slash->addSubcard(card->getEffectiveId());
            slash->deleteLater();
            return slash->isAvailable(Self);
        }
        return true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Card *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard->getId());
        slash->setSkillName(objectName());
        return slash;
    }
};

class TenyearWushengMod : public TargetModSkill
{
public:
    TenyearWushengMod() : TargetModSkill("#tenyearwushengmod")
    {
        frequency = NotFrequent;
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (from->hasSkill("tenyearwusheng") && card->getSuit() == Card::Diamond && card->isKindOf("Slash"))
            return 1000;
        else
            return 0;
    }
};

TenyearYijueCard::TenyearYijueCard()
{
}

bool TenyearYijueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void TenyearYijueCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isKongcheng()) return;
    Room *room = effect.from->getRoom();
    const Card *show_card = room->askForCardShow(effect.to, effect.from, "tenyearyijue");
    room->showCard(effect.to, show_card->getEffectiveId());

    if (show_card->isRed()) {
        room->obtainCard(effect.from, show_card, true);
        if (effect.to->isAlive() && effect.to->getLostHp() > 0 &&
                effect.from->askForSkillInvoke("tenyearyijue", QString("recover:%1").arg(effect.to->objectName()), false)) {
            room->recover(effect.to, RecoverStruct(effect.from));
        }
    } else if (show_card->isBlack()) {
        effect.to->addMark("tenyearyijue");
        room->setPlayerCardLimitation(effect.to, "use,response", ".|.|.|hand", true);
        room->addPlayerMark(effect.to, "@skill_invalidity");

        foreach(ServerPlayer *p, room->getAllPlayers())
            room->filterCards(p, p->getCards("he"), true);
        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
    }
}

class TenyearYijueVS : public OneCardViewAsSkill
{
public:
    TenyearYijueVS() : OneCardViewAsSkill("tenyearyijue")
    {
        filter_pattern = ".";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearYijueCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearYijueCard *card = new TenyearYijueCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class TenyearYijue : public TriggerSkill
{
public:
    TenyearYijue() : TriggerSkill("tenyearyijue")
    {
        events << EventPhaseChanging << Death << DamageCaused;
        view_as_skill = new TenyearYijueVS;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event != DamageCaused)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *target, QVariant &data) const
    {
        if (triggerEvent == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || damage.card->getSuit() != Card::Heart) return false;
            if (damage.from->hasSkill(this) && damage.to->getMark("tenyearyijue") > 0 && damage.from == room->getCurrent()) {
                LogMessage log;
                log.type = "#TenyearyijueBuff";
                log.from = damage.from;
                log.to << damage.to;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(++damage.damage);
                room->sendLog(log);
                data = QVariant::fromValue(damage);
            }
        } else {
            if (triggerEvent == EventPhaseChanging) {
                PhaseChangeStruct change = data.value<PhaseChangeStruct>();
                if (change.to != Player::NotActive)
                    return false;
            } else if (triggerEvent == Death) {
                DeathStruct death = data.value<DeathStruct>();
                if (death.who != target || target != room->getCurrent())
                    return false;
            }
            QList<ServerPlayer *> players = room->getAllPlayers(true);
            foreach (ServerPlayer *player, players) {
                int mark = player->getMark("tenyearyijue");
                if (mark == 0) continue;
                player->removeMark("tenyearyijue", mark);
                room->removePlayerMark(player, "@skill_invalidity", mark);

                foreach(ServerPlayer *p, room->getAllPlayers())
                    room->filterCards(p, p->getCards("he"), false);

                JsonArray args;
                args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
                room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

                room->removePlayerCardLimitation(player, "use,response", ".|.|.|hand$1");
            }
        }
        return false;
    }
};

class TenyearPaoxiao : public TargetModSkill
{
public:
    TenyearPaoxiao() : TargetModSkill("tenyearpaoxiao")
    {
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill(this))
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("tenyearpaoxiao-PlayClear") > 0 && from->hasSkill(this))
            return 1000;
        else
            return 0;
    }
};

class TenyearPaoxiaoMark : public TriggerSkill
{
public:
    TenyearPaoxiaoMark() : TriggerSkill("#tenyearpaoxiaomark")
    {
        frequency = Compulsory;
        events << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        room->addPlayerMark(player, "tenyearpaoxiao-PlayClear");
        return false;
    }
};

class TenyearTishen : public TriggerSkill
{
public:
    TenyearTishen() : TriggerSkill("tenyeartishen")
    {
        events << CardFinished << EventLoseSkill << EventPhaseChanging << EventPhaseEnd << Damage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            foreach(ServerPlayer *p, use.to) {
                if (p->isDead()) continue;
                if (use.card->hasFlag("tenyeartishen" + p->objectName())) {
                    use.card->setFlags("-tenyeartishen" + p->objectName());
                    continue;
                }
                if (!p->hasSkill(this) || p->getMark("&tenyeartishen") <= 0) continue;
                if (!room->CardInPlace(use.card, Player::DiscardPile)) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                room->obtainCard(p, use.card, true);
            }

        } else if (event == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (damage.to->isDead()) return false;
            room->setCardFlag(damage.card, "tenyeartishen" + damage.to->objectName());
        } else if (event == EventPhaseChanging) {
            if (player->isDead()) return false;
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::RoundStart) return false;
            room->setPlayerMark(player, "&tenyeartishen", 0);
        } else if (event == EventLoseSkill) {
            if (player->isDead() || data.toString() != objectName()) return false;
            room->setPlayerMark(player, "&tenyeartishen", 0);
        } else if (event == EventPhaseEnd) {
            if (player->isDead() || player->getPhase() != Player::Play || !player->hasSkill(this)) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            DummyCard *dummy = new DummyCard;
            foreach (const Card *c, player->getCards("he")) {
                if (!c->isKindOf("TrickCard") && !c->isKindOf("OffensiveHorse") && !c->isKindOf("DefensiveHorse")) continue;
                if (player->canDiscard(player, c->getEffectiveId()))
                    dummy->addSubcard(c);
            }
            if (dummy->subcardsLength() > 0)
                room->throwCard(dummy, player, NULL);
            delete dummy;
            room->setPlayerMark(player, "&tenyeartishen", 1);
        }
        return false;
    }
};

class TenyearGuanxing : public PhaseChangeSkill
{
public:
    TenyearGuanxing() : PhaseChangeSkill("tenyearguanxing")
    {
        frequency = Frequent;
    }

    int getPriority(TriggerEvent) const
    {
        return 1;
    }

    bool onPhaseChange(ServerPlayer *zhuge) const
    {
        if (zhuge->getPhase() == Player::Start || (zhuge->getPhase() == Player::Finish && zhuge->getMark("tenyearguanxing-Clear") > 0)) {
            if (!zhuge->askForSkillInvoke(this)) return false;
            Room *room = zhuge->getRoom();

            int index = qrand() % 2 + 1;
            if (zhuge->isJieGeneral("jiangwei", "zhugeliang") && zhuge->isJieGeneral("jiangwei", "wolong"))
                index += 2;
            room->broadcastSkillInvoke(objectName(), index);

            int num = 5;
            if (room->alivePlayerCount() < 4) num = 3;
            QList<int> guanxing = room->getNCards(num, false);
            LogMessage log;
            log.type = "$ViewDrawPile";
            log.from = zhuge;
            log.card_str = IntList2StringList(guanxing).join("+");
            room->sendLog(log, zhuge);
            QList<int> top_cards = room->askForGuanxing(zhuge, guanxing);
            /*bool allbottom = true;  //如果牌堆数量太少，就算选择放在牌堆底，还是会检测到id
            int n = qMin(room->getDrawPile().length(), num);
            for (int i = 0; i < n; i++) {
                int id = room->getDrawPile().at(i);
                if (guanxing.contains(id)) {
                    allbottom = false;
                    break;
                }
            }
            if ( n == 0 || !allbottom) return false;*/
            if (!top_cards.isEmpty()) return false;
            room->addPlayerMark(zhuge, "tenyearguanxing-Clear");
        }
        return false;
    }
};

class TenyearYajiao : public TriggerSkill
{
public:
    TenyearYajiao() : TriggerSkill("tenyearyajiao")
    {
        events << CardUsed << CardResponded;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive) return false;
        const Card *cardstar = NULL;
        bool isHandcard = false;
        if (triggerEvent == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            cardstar = use.card;
            isHandcard = use.m_isHandcard;
        } else {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            cardstar = resp.m_card;
            isHandcard = resp.m_isHandcard;
        }
        if (isHandcard && room->askForSkillInvoke(player, objectName(), data)) {
            room->broadcastSkillInvoke(objectName());
            QList<int> ids = room->getNCards(1, false);
            CardsMoveStruct move(ids, NULL, Player::PlaceTable,
                CardMoveReason(CardMoveReason::S_REASON_TURNOVER, player->objectName(), "tenyearyajiao", QString()));
            room->moveCardsAtomic(move, true);
            int id = ids.first();
            if (room->getCardPlace(id) == Player::PlaceTable)
                room->returnToTopDrawPile(ids);

            const Card *card = Sanguosha->getCard(id);
            room->fillAG(ids, player);
            bool dealt = false;
            player->setMark("tenyearyajiao", id); // For AI
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(),
                QString("@tenyearyajiao-give:::%1:%2\\%3").arg(card->objectName()).arg(card->getSuitString() + "_char").arg(card->getNumberString()));
            room->clearAG(player);
            dealt = true;
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "tenyearyajiao", QString());
            room->obtainCard(target, card, reason, true);
            if (card->getTypeId() != cardstar->getTypeId() && player->canDiscard(player, "he")) {
                room->askForDiscard(player, objectName(), 1, 1, false, true);
            }
            if (!dealt) {
                room->clearAG(player);
                if (room->getCardPlace(id) == Player::PlaceTable)
                    room->returnToTopDrawPile(ids);
            }
        }
        return false;
    }
};

class TenyearJizhi : public TriggerSkill
{
public:
    TenyearJizhi() : TriggerSkill("tenyearjizhi")
    {
        frequency = Frequent;
        events << CardUsed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("TrickCard")) return false;
        if (player->getMark("JilveEvent") > 0 || player->askForSkillInvoke(this)) {
            if (player->getMark("JilveEvent") > 0)
                room->broadcastSkillInvoke("jilve", 5);
            else
                room->broadcastSkillInvoke(objectName());
            QList<int> list = player->drawCardsList(1, objectName());
            int id = list.first();
            const Card *card = Sanguosha->getCard(id);
            if (room->getCardOwner(id) != player || room->getCardPlace(id) != Player::PlaceHand) return false;
            if (!card->isKindOf("BasicCard") || !player->canDiscard(player, id)) return false;
            room->fillAG(list, player);
            player->tag["tenyearjizhi_id"] = id;
            bool invoke = room->askForSkillInvoke(player, "tenyearjizhi_discard", "discard", false);
            player->tag.remove("tenyearjizhi_id");
            room->clearAG(player);
            if (!invoke) return false;
            room->throwCard(card, player, NULL);
            room->addMaxCards(player, 1);
        }
        return false;
    }
};

class TenyearJianxiong : public MasochismSkill
{
public:
    TenyearJianxiong() : MasochismSkill("tenyearjianxiong")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *caocao, const DamageStruct &damage) const
    {
        if (!caocao->askForSkillInvoke(this)) return;
        Room *room = caocao->getRoom();
        room->broadcastSkillInvoke(objectName());
        caocao->drawCards(1, objectName());

        const Card *card = damage.card;
        if (card && room->CardInTable(card))
            caocao->obtainCard(card);
    }
};

TenyearQingjianCard::TenyearQingjianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void TenyearQingjianCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (room->getCurrent())
        room->addPlayerMark(effect.from, "tenyearqingjian-Clear");
    QList<int> ids= getSubcards();
    LogMessage log;
    log.type = "$ShowCard";
    log.from = effect.from;
    log.card_str = IntList2StringList(ids).join("+");
    room->sendLog(log);
    room->fillAG(ids);
    room->getThread()->delay(1000);
    room->clearAG();
    if(effect.from != effect.to) {
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "tenyearqingjian", QString());
        room->obtainCard(effect.to, this, reason, true);
    }
    QList<int> list;
    foreach (int id, ids) {
        const Card *card = Sanguosha->getCard(id);
        if (list.contains(card->getTypeId())) continue;
        list << card->getTypeId();
    }
    if (list.isEmpty() || !room->hasCurrent(true)) return;
    room->addMaxCards(room->getCurrent(), list.length());
}

class TenyearQingjianVS : public ViewAsSkill
{
public:
    TenyearQingjianVS() : ViewAsSkill("tenyearqingjian")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *) const
    {
        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        TenyearQingjianCard *c = new TenyearQingjianCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearqingjian";
    }
};

class TenyearQingjian : public TriggerSkill
{
public:
    TenyearQingjian() : TriggerSkill("tenyearqingjian")
    {
        events << CardsMoveOneTime;
        view_as_skill = new TenyearQingjianVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!room->getTag("FirstRound").toBool() && player->getPhase() != Player::Draw && move.to == player && move.to_place == Player::PlaceHand) {
            if (player->isNude() || player->getMark("tenyearqingjian-Clear") > 0) return false;
            room->askForUseCard(player, "@@tenyearqingjian", "@tenyearqingjian");
        }
        return false;
    }
};

class TenyearLuoyi : public TriggerSkill
{
public:
    TenyearLuoyi() : TriggerSkill("tenyearluoyi")
    {
        events << EventPhaseStart << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::Draw || !player->hasSkill(this)) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            QList<int> ids = room->showDrawPile(player, 3, objectName());
            QList<int> card_to_throw;
            room->fillAG(ids, player);
            player->tag["tenyearluoyi_ids"] = IntList2VariantList(ids);
            bool invoke = player->askForSkillInvoke(this);
            player->tag.remove("tenyearluoyi_ids");
            if (!invoke) {
                room->clearAG(player);
                foreach (int id, ids) {
                    if (room->getCardPlace(id) == Player::PlaceTable)
                        card_to_throw << id;
                }
                if (!card_to_throw.isEmpty()){
                    DummyCard *dummy = new DummyCard(card_to_throw);
                    CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "tenyearluoyi", QString());
                    room->throwCard(dummy, reason, NULL);
                    delete dummy;
                }
                return false;
            }
            room->broadcastSkillInvoke(objectName());
            room->clearAG(player);
            room->addPlayerMark(player, "&tenyearluoyi");
            QList<int> card_to_gotback;
            for (int i = 0; i < 3; i++) {
                const Card *card = Sanguosha->getCard(ids[i]);
                if (card->getTypeId() == Card::TypeBasic || card->isKindOf("Weapon") || card->isKindOf("Duel"))
                    card_to_gotback << ids[i];
                else {
                    if (room->getCardPlace(ids[i]) == Player::PlaceTable)
                        card_to_throw << ids[i];
                }
            }
            if (!card_to_throw.isEmpty()) {
                DummyCard *dummy = new DummyCard(card_to_throw);
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "tenyearluoyi", QString());
                room->throwCard(dummy, reason, NULL);
                delete dummy;
            }
            if (!card_to_gotback.isEmpty()) {
                DummyCard *dummy = new DummyCard(card_to_gotback);
                room->obtainCard(player, dummy);
                delete dummy;
            }
            return true;
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::RoundStart && player->getMark("&tenyearluoyi") > 0)
                room->setPlayerMark(player, "&tenyearluoyi", 0);
        }
        return false;
    }
};

class TenyearLuoyiBuff : public TriggerSkill
{
public:
    TenyearLuoyiBuff() : TriggerSkill("#tenyearluoyibuff")
    {
        events << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getMark("&tenyearluoyi") > 0 && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *xuchu, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        const Card *reason = damage.card;
        if (reason && (reason->isKindOf("Slash") || reason->isKindOf("Duel"))) {
            LogMessage log;
            log.type = "#LuoyiBuff";
            log.from = xuchu;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }

        return false;
    }
};

class TenyearYiji : public MasochismSkill
{
public:
    TenyearYiji() : MasochismSkill("tenyearyiji")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *target, const DamageStruct &damage) const
    {
        Room *room = target->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            if (target->isAlive() && room->askForSkillInvoke(target, objectName(), QVariant::fromValue(damage))) {
                room->broadcastSkillInvoke(objectName());
                target->drawCards(2, objectName());
                if (!target->isKongcheng()) {
                    QList<int> handcards = target->handCards();
                    int n = 0;
                    QHash<ServerPlayer *, QStringList> hash;
                    while (n < 2) {
                        CardsMoveStruct yiji_move = room->askForYijiStruct(target, handcards, objectName(), false, false, true, 2 - n,
                                                    room->getOtherPlayers(target), CardMoveReason(), QString(), false, false);
                        if (!yiji_move.to || yiji_move.card_ids.isEmpty()) break;
                        n += yiji_move.card_ids.length();

                        QStringList id_strings = hash[(ServerPlayer *)yiji_move.to];
                        foreach (int id, yiji_move.card_ids)
                            id_strings << QString::number(id);
                        hash[(ServerPlayer *)yiji_move.to] = id_strings;
                    }

                    QList<CardsMoveStruct> moves;
                    foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                        if (p->isDead()) continue;
                        QList<int> ids = StringList2IntList(hash[p]);
                        if (ids.isEmpty()) continue;
                        hash.remove(p);
                        CardsMoveStruct move(ids, target, p, Player::PlaceHand, Player::PlaceHand,
                            CardMoveReason(CardMoveReason::S_REASON_GIVE, target->objectName(), p->objectName(), "tenyearyiji", QString()));
                        moves.append(move);
                    }
                    if (moves.isEmpty()) return;
                    room->moveCardsAtomic(moves, false);
                }
            } else
                break;
        }
    }
};

class TenyearLuoshen : public TriggerSkill
{
public:
    TenyearLuoshen() : TriggerSkill("tenyearluoshen")
    {
        events << EventPhaseStart << FinishJudge << EventPhaseProceeding << CardsMoveOneTime << EventPhaseChanging;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *zhenji, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (zhenji->getPhase() != Player::Start) return false;
            bool first = true;
            while (zhenji->askForSkillInvoke("tenyearluoshen")) {
                if (first) {
                    room->broadcastSkillInvoke(objectName());
                    first = false;
                }

                JudgeStruct judge;
                judge.pattern = ".|black";
                judge.good = true;
                judge.reason = objectName();
                judge.play_animation = false;
                judge.who = zhenji;
                judge.time_consuming = true;
                room->judge(judge);

                if (!judge.isGood()) break;
            }
        } else if (triggerEvent == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == objectName()) {
                if (judge->card->isBlack()) {
                    if (room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge) {
                        CardMoveReason reason(CardMoveReason::S_REASON_GOTCARD, zhenji->objectName(), "tenyearluoshen", QString());
                        room->obtainCard(zhenji, judge->card, reason, true);
                    }
                }
            }
        } else if (triggerEvent == EventPhaseProceeding) {
            if (zhenji->getPhase() != Player::Discard) return false;
            QVariantList luoshenlist = zhenji->tag["luoshen_list"].toList();
            if (luoshenlist.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(zhenji, "tenyearluoshen", true, true);
            room->ignoreCards(zhenji, VariantList2IntList(luoshenlist));
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            zhenji->tag.remove("luoshen_list");
        } else if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.reason.m_skillName != objectName()) return false;
            if (move.to == zhenji && move.to_place == Player::PlaceHand) {
                QVariantList luoshenlist = zhenji->tag["luoshen_list"].toList();
                foreach (int id, move.card_ids) {
                    if (luoshenlist.contains(QVariant(id))) continue;
                    luoshenlist << id;
                }
                zhenji->tag["luoshen_list"] = luoshenlist;
            }
        }
        return false;
    }
};

TenyearTuxiCard::TenyearTuxiCard()
{
}

bool TenyearTuxiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length() >= Self->getMark("tenyeartuxi") || to_select == Self)
        return false;

    return !to_select->isKongcheng();
}

void TenyearTuxiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->setFlags("TenyearTuxiTarget");
}

class TenyearTuxiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    TenyearTuxiViewAsSkill() : ZeroCardViewAsSkill("tenyeartuxi")
    {
        response_pattern = "@@tenyeartuxi";
    }

    const Card *viewAs() const
    {
        return new TenyearTuxiCard;
    }
};

class TenyearTuxi : public DrawCardsSkill
{
public:
    TenyearTuxi() : DrawCardsSkill("tenyeartuxi")
    {
        view_as_skill = new TenyearTuxiViewAsSkill;
    }

    int getPriority(TriggerEvent) const
    {
        return 1;
    }

    int getDrawNum(ServerPlayer *zhangliao, int n) const
    {
        Room *room = zhangliao->getRoom();
        int num = qMin(room->getOtherPlayers(zhangliao).length(), n);
        foreach(ServerPlayer *p, room->getOtherPlayers(zhangliao))
            p->setFlags("-TenyearTuxiTarget");

        if (num > 0) {
            room->setPlayerMark(zhangliao, "tenyeartuxi", num);
            int count = 0;
            if (room->askForUseCard(zhangliao, "@@tenyeartuxi", "@tuxi-card:::" + QString::number(num))) {
                foreach(ServerPlayer *p, room->getOtherPlayers(zhangliao))
                    if (p->hasFlag("TenyearTuxiTarget")) count++;
            } else {
                room->setPlayerMark(zhangliao, "tenyeartuxi", 0);
            }
            return n - count;
        } else
            return n;
    }
};

class TenyearTuxiAct : public TriggerSkill
{
public:
    TenyearTuxiAct() : TriggerSkill("#tenyeartuxi")
    {
        events << AfterDrawNCards;
    }

    bool triggerable(const ServerPlayer *player) const
    {
        return player != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *zhangliao, QVariant &) const
    {
        if (zhangliao->getMark("tenyeartuxi") == 0) return false;
        room->setPlayerMark(zhangliao, "tenyeartuxi", 0);

        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(zhangliao)) {
            if (p->hasFlag("TenyearTuxiTarget")) {
                p->setFlags("-TenyearTuxiTarget");
                targets << p;
            }
        }
        foreach (ServerPlayer *p, targets) {
            if (!zhangliao->isAlive())
                break;
            if (p->isAlive() && !p->isKongcheng()) {
                int card_id = room->askForCardChosen(zhangliao, p, "h", "tenyeartuxi");

                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, zhangliao->objectName());
                room->obtainCard(zhangliao, Sanguosha->getCard(card_id), reason, false);
            }
        }
        return false;
    }
};

TenyearQingnangCard::TenyearQingnangCard()
{
}

bool TenyearQingnangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->isWounded() && to_select->getMark("tenyearqingnang_target-PlayClear") <= 0;
}

void TenyearQingnangCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->recover(effect.to, RecoverStruct(effect.from));
    room->setPlayerMark(effect.to, "tenyearqingnang_target-PlayClear", 1);
    const Card *card = Sanguosha->getCard(getSubcards().first());
    if (card->isRed()) return;
    room->setPlayerMark(effect.from, "tenyearqingnang-PlayClear", 1);
}

class TenyearQingnang : public OneCardViewAsSkill
{
public:
    TenyearQingnang() : OneCardViewAsSkill("tenyearqingnang")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "h") && player->getMark("tenyearqingnang-PlayClear") <= 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearQingnangCard *qingnang_card = new TenyearQingnangCard;
        qingnang_card->addSubcard(originalCard);
        return qingnang_card;
    }
};

class TenyearLiyu : public TriggerSkill
{
public:
    TenyearLiyu() : TriggerSkill("tenyearliyu")
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isAlive() && player != damage.to && !damage.to->hasFlag("Global_DebutFlag") && !damage.to->isAllNude()
            && damage.card && damage.card->isKindOf("Slash")) {
            if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.to))) return false;
            room->broadcastSkillInvoke(objectName());
            int card_id = room->askForCardChosen(player, damage.to, "hej", "tenyearliyu");
            const Card *card = Sanguosha->getCard(card_id);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, card, reason, true);

            if (!card->isKindOf("EquipCard"))
                damage.to->drawCards(1, objectName());
            else {
                Duel *duel = new Duel(Card::NoSuit, 0);
                duel->setSkillName("_tenyearliyu");

                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (p != damage.to && !player->isProhibited(p, duel))
                        targets << p;
                }
                if (targets.isEmpty()) {
                    delete duel;
                    return false;
                }
                ServerPlayer *target = room->askForPlayerChosen(damage.to, targets, objectName(), "@tenyearliyu:" + player->objectName());
                if (player->isAlive() && target->isAlive() && !player->isLocked(duel))
                    room->useCard(CardUseStruct(duel, player, target));
                delete duel;
            }
        }
        return false;
    }
};

class TenyearBiyue : public PhaseChangeSkill
{
public:
    TenyearBiyue() : PhaseChangeSkill("tenyearbiyue")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *diaochan) const
    {
        if (diaochan->getPhase() == Player::Finish) {
            Room *room = diaochan->getRoom();
            if (room->askForSkillInvoke(diaochan, objectName())) {
                room->broadcastSkillInvoke(objectName());
                int n = 1;
                if (diaochan->isKongcheng()) n = 2;
                diaochan->drawCards(n, objectName());
            }
        }
        return false;
    }
};

class TenyearYaowu : public TriggerSkill
{
public:
    TenyearYaowu() : TriggerSkill("tenyearyaowu")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash") && player->isAlive()) {
            if (damage.card->isRed()) {
                if (!damage.from || damage.from->isDead()) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true, 2);
                QStringList choices;
                choices << "draw";
                if (damage.from->getLostHp() > 0) choices << "recover";
                if (room->askForChoice(damage.from, objectName(), choices.join("+")) == "draw")
                    damage.from->drawCards(1, objectName());
                else
                    room->recover(damage.from, RecoverStruct(damage.to));
            } else {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true, 1);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};


class TenyearLiegong : public TriggerSkill
{
public:
    TenyearLiegong() : TriggerSkill("tenyearliegong")
    {
        events << TargetSpecified << DamageCaused;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            int handnum = player->getHandcardNum();
            int hp = player->getHp();
            foreach (ServerPlayer *p, use.to) {
                if (p->getHandcardNum() > handnum && p->getHp() < hp) continue;
                if (!player->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
                if (p->getHandcardNum() <= handnum) {
                    LogMessage log;
                    log.type = "#NoJink";
                    log.from = p;
                    room->sendLog(log);
                    use.no_respond_list << p->objectName();
                }
                if (p->getHp() >= hp)
                    room->setCardFlag(use.card, "tenyearliegong_damage" + p->objectName());
            }
            data = QVariant::fromValue(use);
        } else if (event == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (damage.to->isDead()) return false;
            if (!damage.card->hasFlag("tenyearliegong_damage" + damage.to->objectName())) return false;
            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class TenyearLiegongMod : public TargetModSkill
{
public:
    TenyearLiegongMod() : TargetModSkill("#tenyearliegongmod")
    {
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (from->hasSkill("tenyearliegong") || from->hasSkill("mobilemouliegong"))
            return qMax(0, card->getNumber() - from->getAttackRange());
        else
            return 0;
    }
};

class TenyearKuanggu : public TriggerSkill
{
public:
    TenyearKuanggu() : TriggerSkill("tenyearkuanggu")
    {
        events << Damage;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        bool invoke = player->tag.value("InvokeTenyearKuanggu", false).toBool();
        player->tag["InvokeTenyearKuanggu"] = false;
        if (invoke) {
            DamageStruct damage = data.value<DamageStruct>();
            for (int i = 1; i <= damage.damage; i++) {
                if (!player->askForSkillInvoke(this)) break;
                int index = qrand() % 2 + 1;
                if (player->getGeneralName().startsWith("ol_") || player->getGeneral2Name().startsWith("ol_"))
                    index += 2;
                room->broadcastSkillInvoke(objectName(), index);
                QStringList choices;
                if (player->getLostHp() > 0)
                    choices << "recover";
                choices << "draw";
                if (room->askForChoice(player, objectName(), choices.join("+")) == "draw")
                    player->drawCards(1, objectName());
                else
                    room->recover(player, RecoverStruct(player));
            }
        }
        return false;
    }
};

class TenyearKuangguRecord : public TriggerSkill
{
public:
    TenyearKuangguRecord() : TriggerSkill("#tenyearkuanggu-record")
    {
        events << PreDamageDone;
        global = true;
    }

    bool trigger(TriggerEvent , Room *, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *weiyan = damage.from;
        if (weiyan && weiyan->isAlive() && damage.to->isAlive())
            weiyan->tag["InvokeTenyearKuanggu"] = (weiyan->distanceTo(damage.to) <= 1);
        return false;
    }
};

TenyearQimouCard::TenyearQimouCard()
{
    target_fixed = true;
}

void TenyearQimouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->removePlayerMark(source, "@tenyearqimouMark");
    room->doSuperLightbox("tenyear_weiyan", "tenyearqimou");
    QStringList choices;
    for (int i = 1; i <= source->getHp(); i++) {
        choices << QString::number(i);
    }
    QString choice = room->askForChoice(source, "tenyearqimou", choices.join("+"));
    int n = choice.toInt();
    room->loseHp(source, n);
    if (source->isAlive()) {
        room->addDistance(source, -n);
        room->addSlashCishu(source, n);
    }
}

class TenyearQimou : public ZeroCardViewAsSkill
{
public:
    TenyearQimou() : ZeroCardViewAsSkill("tenyearqimou")
    {
        frequency = Limited;
        limit_mark = "@tenyearqimouMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getHp() > 0 && player->getMark("@tenyearqimouMark") > 0;
    }

    const Card *viewAs() const
    {
        return new TenyearQimouCard;
    }
};

TenyearShensuCard::TenyearShensuCard()
{
    mute = true;
}

bool TenyearShensuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("_tenyearshensu");
    slash->deleteLater();
    return slash->targetFilter(targets, to_select, Self);
}

void TenyearShensuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("_tenyearshensu");
    foreach (ServerPlayer *target, targets) {
        if (!source->canSlash(target, slash, false))
            targets.removeOne(target);
    }

    if (targets.length() > 0) {
        room->useCard(CardUseStruct(slash, source, targets));
    }
}

class TenyearShensuViewAsSkill : public ViewAsSkill
{
public:
    TenyearShensuViewAsSkill() : ViewAsSkill("tenyearshensu")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@tenyearshensu");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern.endsWith("1") || pattern.endsWith("3"))
            return false;
        else
            return selected.isEmpty() && to_select->isKindOf("EquipCard") && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern.endsWith("1") || pattern.endsWith("3")) {
            return cards.isEmpty() ? new TenyearShensuCard : NULL;
        } else {
            if (cards.length() != 1)
                return NULL;

            TenyearShensuCard *card = new TenyearShensuCard;
            card->addSubcards(cards);

            return card;
        }
    }
};

class TenyearShensu : public TriggerSkill
{
public:
    TenyearShensu() : TriggerSkill("tenyearshensu")
    {
        events << EventPhaseChanging;
        view_as_skill = new TenyearShensuViewAsSkill;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *xiahouyuan, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::Judge && !xiahouyuan->isSkipped(Player::Judge)
            && !xiahouyuan->isSkipped(Player::Draw)) {
            if (Slash::IsAvailable(xiahouyuan) && room->askForUseCard(xiahouyuan, "@@tenyearshensu1", "@shensu1", 1)) {
                xiahouyuan->skip(Player::Judge, true);
                xiahouyuan->skip(Player::Draw, true);
            }
        } else if (Slash::IsAvailable(xiahouyuan) && change.to == Player::Play && !xiahouyuan->isSkipped(Player::Play)) {
            if (xiahouyuan->canDiscard(xiahouyuan, "he") && room->askForUseCard(xiahouyuan, "@@tenyearshensu2", "@shensu2", 2, Card::MethodDiscard))
                xiahouyuan->skip(Player::Play, true);
        } else if (change.to == Player::Discard && !xiahouyuan->isSkipped(Player::Discard)) {
            if (Slash::IsAvailable(xiahouyuan) && room->askForUseCard(xiahouyuan, "@@tenyearshensu3", "@tenyearshensu3", 3)) {
                xiahouyuan->skip(Player::Discard, true);
                xiahouyuan->turnOver();
            }
        }
        return false;
    }
};

class TenyearJushou : public PhaseChangeSkill
{
public:
    TenyearJushou() : PhaseChangeSkill("tenyearjushou")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        player->turnOver();
        player->drawCards(4, objectName());
        if (player->isKongcheng()) return false;

        QStringList list;
        foreach (const Card *c, player->getCards("h")) {
            if (c->isKindOf("EquipCard") && c->isAvailable(player) && !player->isCardLimited(c, Card::MethodUse))
                list << c->toString();
            else if (!c->isKindOf("EquipCard") && player->canDiscard(player, c->getEffectiveId()))
                list << c->toString();
        }

        if (list.isEmpty()) {
            LogMessage log;
            log.type = "#TenyearjushouShow";
            log.from = player;
            room->sendLog(log);
            room->showAllCards(player);
            return false;
        }

        QString pattern = list.join(",");
        if (!pattern.endsWith("!"))
            pattern = pattern + "!";
        const Card *card = room->askForCard(player, pattern, "@tenyearjushou", QVariant(), Card::MethodNone);
        if (!card) {
            QList<int> ids = StringList2IntList(list);
            card = Sanguosha->getCard(ids.at(qrand() % ids.length()));
        }
        if (card->isKindOf("EquipCard"))
            room->useCard(CardUseStruct(card, player, player));
        else {
            CardMoveReason reason(CardMoveReason::S_REASON_THROW, player->objectName(), "tenyearjushou", QString());
            room->throwCard(card, reason, player, NULL);
        }
        return false;
    }
};

class TenyearJieweiVS : public OneCardViewAsSkill
{
public:
    TenyearJieweiVS() : OneCardViewAsSkill("tenyearjiewei")
    {
        filter_pattern = ".|.|.|equipped";
        response_pattern = "nullification";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Card *ncard = new Nullification(originalCard->getSuit(), originalCard->getNumber());
        ncard->addSubcard(originalCard);
        ncard->setSkillName(objectName());
        return ncard;
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        return !player->getEquips().isEmpty();
    }
};

class TenyearJiewei : public TriggerSkill
{
public:
    TenyearJiewei() : TriggerSkill("tenyearjiewei")
    {
        events << TurnedOver;
        view_as_skill = new TenyearJieweiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!player->faceUp()) return false;
        if (!player->canDiscard(player, "he")) return false;
        if (!room->askForCard(player, "..", "@tenyearjiewei", QVariant(), objectName())) return false;
        room->broadcastSkillInvoke(objectName());
        room->moveField(player, "tenyearjiewei");
        return false;
    }
};

TenyearTianxiangCard::TenyearTianxiangCard(QString this_skill_name) : this_skill_name(this_skill_name)
{
    handling_method = Card::MethodDiscard;
}

void TenyearTianxiangCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    Room *room = effect.from->getRoom();
    if (room->askForChoice(effect.from, this_skill_name, "damage+losehp") == "damage") {
        room->damage(DamageStruct(this_skill_name, NULL, effect.to));
        if (effect.to->isDead()) return;
        int n = qMin(5, effect.to->getLostHp());
        if (n <= 0) return;
        effect.to->drawCards(n, this_skill_name);
    } else {
        room->loseHp(effect.to);
        if (effect.to->isDead()) return;
        room->obtainCard(effect.to, this, true);
    }
}

class TenyearTianxiangViewAsSkill : public OneCardViewAsSkill
{
public:
    TenyearTianxiangViewAsSkill() : OneCardViewAsSkill("tenyeartianxiang")
    {
        filter_pattern = ".|heart|.|hand";
        response_pattern = "@@tenyeartianxiang";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearTianxiangCard *tianxiangCard = new TenyearTianxiangCard;
        tianxiangCard->addSubcard(originalCard);
        return tianxiangCard;
    }
};

class TenyearTianxiang : public TriggerSkill
{
public:
    TenyearTianxiang() : TriggerSkill("tenyeartianxiang")
    {
        events << DamageInflicted;
        view_as_skill = new TenyearTianxiangViewAsSkill;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *xiaoqiao, QVariant &) const
    {
        if (xiaoqiao->canDiscard(xiaoqiao, "h")) {
            return room->askForUseCard(xiaoqiao, "@@tenyeartianxiang", "@tenyeartianxiang", -1, Card::MethodDiscard);
        }
        return false;
    }
};

class TenyearJianchu : public TriggerSkill
{
public:
    TenyearJianchu() : TriggerSkill("tenyearjianchu")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead() || !player->hasSkill(this)) break;
            if (p->isDead()) continue;
            if (!player->canDiscard(p, "he") || !player->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
            room->broadcastSkillInvoke(objectName());
            int to_throw = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard);
            const Card *card = Sanguosha->getCard(to_throw);
            room->throwCard(card, p, player);
            if (card->isKindOf("EquipCard")) {
                LogMessage log;
                log.type = "#NoJink";
                log.from = p;
                room->sendLog(log);
                use.no_respond_list << p->objectName();
                data = QVariant::fromValue(use);
            } else {
                if (!room->CardInTable(use.card)) continue;
                p->obtainCard(use.card, true);
            }
        }
        return false;
    }
};

TenyearSanyaoCard::TenyearSanyaoCard()
{
}

bool TenyearSanyaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QList<const Player *> players = Self->getAliveSiblings();
    int max = -1000;
    foreach (const Player *p, players) {
        if (max < p->getHp())
            max = p->getHp();
    }
    return to_select->getHp() == max && targets.length() < this->getSubcards().length() && to_select != Self;
}

bool TenyearSanyaoCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == this->getSubcards().length();
}

void TenyearSanyaoCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->getRoom()->damage(DamageStruct("tenyearsanyao", effect.from, effect.to));
}

class TenyearSanyao : public ViewAsSkill
{
public:
    TenyearSanyao() : ViewAsSkill("tenyearsanyao")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QList<const Player *> players = Self->getAliveSiblings();
        int max = -1000;
        foreach (const Player *p, players) {
            if (max < p->getHp())
                max = p->getHp();
        }
        int num = 0;
        foreach (const Player *p, players) {
            if (p->getHp() == max)
                num++;
        }
        return !Self->isJilei(to_select) && selected.length() < num;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearSanyaoCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        TenyearSanyaoCard *first = new TenyearSanyaoCard;
        first->addSubcards(cards);
        return first;
    }
};

class TenyearZhiman : public TriggerSkill
{
public:
    TenyearZhiman() : TriggerSkill("tenyearzhiman")
    {
        events << DamageCaused;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to == player || damage.to->isDead()) return false;
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());
            LogMessage log;
            log.type = "#Yishi";
            log.from = player;
            log.arg = objectName();
            log.to << damage.to;
            room->sendLog(log);
            if (damage.to->isAllNude()) return true;
            int card_id = room->askForCardChosen(player, damage.to, "hej", objectName());
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
            return true;
        }
        return false;
    }
};

class TenyearZhenjun : public PhaseChangeSkill
{
public:
    TenyearZhenjun() : PhaseChangeSkill("tenyearzhenjun")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (player->canDiscard(p, "he"))
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@tenyearzhenjun-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        int n = qMax(target->getHandcardNum() - target->getHp(), 1);
        n = qMin(target->getCards("he").length(), n);
        if (n <= 0) return false;

        QList<Player::Place> orig_places;
        QList<int> cards;
        target->setFlags("tenyearzhenjun_InTempMoving");

        for (int i = 0; i < n; ++i) {
            if (!player->canDiscard(target, "he")) break;
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            Player::Place place = room->getCardPlace(id);
            orig_places << place;
            cards << id;
            target->addToPile("#tenyearzhenjun", id, false);
        }
        for (int i = 0; i < n; ++i) {
            if (orig_places.isEmpty()) break;
            room->moveCardTo(Sanguosha->getCard(cards.value(i)), target, orig_places.value(i), false);
        }
        target->setFlags("-tenyearzhenjun_InTempMoving");

        if (!cards.isEmpty()) {
            DummyCard dummy(cards);
            room->throwCard(&dummy, target, player);
            int equips = 0;
            foreach (int id, cards) {
                const Card *card = Sanguosha->getCard(id);
                if (!card->isKindOf("EquipCard"))
                    equips++;
            }
            if (equips == 0) return false;

            int candis = 0;
            foreach (const Card *card, player->getCards("he")) {
                if (player->canDiscard(player, card->getEffectiveId()))
                    candis++;
            }
            if (candis < equips)
                target->drawCards(equips, objectName());
            else {
                if (!room->askForDiscard(player, objectName(), equips, equips, true, true, "tenyearzhenjun-discard:" + QString::number(equips)))
                    target->drawCards(equips, objectName());
            }
        }
        return false;
    }
};

class SecondTenyearZhenjun : public PhaseChangeSkill
{
public:
    SecondTenyearZhenjun() : PhaseChangeSkill("secondtenyearzhenjun")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start && player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (player->canDiscard(p, "he"))
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@tenyearzhenjun-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        int n = qMax(target->getHandcardNum() - target->getHp(), 1);
        n = qMin(target->getCards("he").length(), n);
        if (n <= 0) return false;

        QList<Player::Place> orig_places;
        QList<int> cards;
        target->setFlags("secondtenyearzhenjun_InTempMoving");

        for (int i = 0; i < n; ++i) {
            if (!player->canDiscard(target, "he")) break;
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            Player::Place place = room->getCardPlace(id);
            orig_places << place;
            cards << id;
            target->addToPile("#secondtenyearzhenjun", id, false);
        }
        for (int i = 0; i < n; ++i) {
            if (orig_places.isEmpty()) break;
            room->moveCardTo(Sanguosha->getCard(cards.value(i)), target, orig_places.value(i), false);
        }
        target->setFlags("-secondtenyearzhenjun_InTempMoving");

        if (!cards.isEmpty()) {
            DummyCard dummy(cards);
            room->throwCard(&dummy, target, player);
            foreach (int id, cards) {
                const Card *card = Sanguosha->getCard(id);
                if (card->isKindOf("EquipCard"))
                    return false;
            }

            QString prompt = QString("@secondtenyearzhenjun-discard:%1::%2").arg(target->objectName()).arg(cards.length());
            if (player->canDiscard(player, "he") && room->askForDiscard(player, objectName(), 1, 1, true, true, prompt)) return false;
            target->drawCards(cards.length(), objectName());
        }
        return false;
    }
};

class TenyearJingce : public PhaseChangeSkill
{
public:
    TenyearJingce() : PhaseChangeSkill("tenyearjingce")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() == Player::Finish) {
            if (player->getMark("tenyearjingce-Clear") < player->getHp()) return false;
            Room *room = player->getRoom();
            if (room->askForSkillInvoke(player, objectName())) {
                room->broadcastSkillInvoke(objectName());
                player->drawCards(2, objectName());
            }
        }
        return false;
    }
};

class TenyearJingceRecord : public TriggerSkill
{
public:
    TenyearJingceRecord() : TriggerSkill("#tenyearjingce-record")
    {
        events << PreCardUsed << CardResponded;
        global = true;
    }

    bool trigger(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        if ((triggerEvent == PreCardUsed || triggerEvent == CardResponded) && player->getPhase() != Player::NotActive) {
            const Card *card = NULL;
            if (triggerEvent == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct response = data.value<CardResponseStruct>();
                if (response.m_isUse)
                    card = response.m_card;
            }
            if (card && card->getTypeId() != Card::TypeSkill) {
                Room *room = player->getRoom();
                room->addPlayerMark(player, "tenyearjingce-Clear");

                room->addPlayerMark(player, "mobilerensheyi_" + card->getType() + "-Clear");

                QString suit_string = card->getSuitString();
                if (suit_string == "no_suit_black" || suit_string == "no_suit_red")
                    suit_string = "no_suit";

                room->setPlayerMark(player, "secondtenyearjingce" + suit_string + "-Clear", 1);
            }
        }
        return false;
    }
};

class SecondTenyearJingce : public PhaseChangeSkill
{
public:
    SecondTenyearJingce() : PhaseChangeSkill("secondtenyearjingce")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() == Player::Finish) {
            if (player->getMark("tenyearjingce-Clear") < player->getHp()) return false;
            Room *room = player->getRoom();
            if (room->askForSkillInvoke(player, objectName())) {
                room->broadcastSkillInvoke(objectName());

                QStringList suit_strings;
                suit_strings << "spade" << "heart" << "club" << "diamond" << "no_suit";
                int mark = 0;
                foreach (QString suit_string, suit_strings)
                    mark += player->getMark("secondtenyearjingce" + suit_string + "-Clear");

                RoomThread *thread = room->getThread();
                if (mark >= player->getHp()) {
                    player->setPhase(Player::Draw);
                    room->broadcastProperty(player, "phase");
                    if (!thread->trigger(EventPhaseStart, room, player))
                        thread->trigger(EventPhaseProceeding, room, player);
                    thread->trigger(EventPhaseEnd, room, player);

                    player->setPhase(Player::Play);
                    room->broadcastProperty(player, "phase");
                    if (!thread->trigger(EventPhaseStart, room, player))
                        thread->trigger(EventPhaseProceeding, room, player);
                    thread->trigger(EventPhaseEnd, room, player);

                    player->setPhase(Player::Finish);
                    room->broadcastProperty(player, "phase");
                } else {
                    if (room->askForChoice(player, objectName(), "draw+play") == "draw") {
                        player->setPhase(Player::Draw);
                        room->broadcastProperty(player, "phase");
                        RoomThread *thread = room->getThread();
                        if (!thread->trigger(EventPhaseStart, room, player))
                            thread->trigger(EventPhaseProceeding, room, player);
                        thread->trigger(EventPhaseEnd, room, player);
                    } else {
                        player->setPhase(Player::Play);
                        room->broadcastProperty(player, "phase");
                        if (!thread->trigger(EventPhaseStart, room, player))
                            thread->trigger(EventPhaseProceeding, room, player);
                        thread->trigger(EventPhaseEnd, room, player);
                    }
                    player->setPhase(Player::Finish);
                    room->broadcastProperty(player, "phase");
                }
            }
        }
        return false;
    }
};

class TenyearDangxian : public PhaseChangeSkill
{
public:
    TenyearDangxian() : PhaseChangeSkill("tenyeardangxian")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (player->getPhase() == Player::RoundStart) {
            //room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            LogMessage log;
            log.type = "#TenyeardangxianPlayPhase";
            log.from = player;
            log.arg = "tenyeardangxian";
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());

            player->setPhase(Player::Play);
            room->broadcastProperty(player, "phase");
            RoomThread *thread = room->getThread();
            room->setPlayerFlag(player, "tenyeardangxian");
            if (!thread->trigger(EventPhaseStart, room, player)) {
                if (player->hasFlag("tenyeardangxian"))
                    room->setPlayerFlag(player, "-tenyeardangxian");
                thread->trigger(EventPhaseProceeding, room, player);
            }
            if (player->hasFlag("tenyeardangxian"))
                room->setPlayerFlag(player, "-tenyeardangxian");
            thread->trigger(EventPhaseEnd, room, player);

            player->setPhase(Player::RoundStart);
            room->broadcastProperty(player, "phase");
        } else if (player->getPhase() == Player::Play) {
            if (!player->hasFlag("tenyeardangxian")) return false;
            room->setPlayerFlag(player, "-tenyeardangxian");
            if (player->getMark(objectName()) <= 0)
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            else {
                if (!player->askForSkillInvoke(objectName()))
                    return false;
                room->broadcastSkillInvoke(objectName());
            }
            room->loseHp(player);
            if (player->isDead()) return  false;
            QList<int> slash;
            foreach (int id, room->getDiscardPile()) {
                const Card *card = Sanguosha->getCard(id);
                if (!card->isKindOf("Slash")) continue;
                slash << id;
            }
            if (slash.isEmpty()) return false;
            room->obtainCard(player, slash.at(qrand() % slash.length()),true);
        }
        return false;
    }
};

class TenyearFuli : public TriggerSkill
{
public:
    TenyearFuli() : TriggerSkill("tenyearfuli")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@tenyearfuliMark";
    }

    int getKingdoms(Room *room) const
    {
        QSet<QString> kingdom_set;
        foreach(ServerPlayer *p, room->getAlivePlayers())
            kingdom_set << p->getKingdom();
        return kingdom_set.size();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *liaohua, QVariant &data) const
    {
        DyingStruct dying_data = data.value<DyingStruct>();
        if (dying_data.who != liaohua || liaohua->getMark("@tenyearfuliMark") <= 0) return false;
        if (liaohua->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());

            room->doSuperLightbox("tenyear_liaohua", "tenyearfuli");

            room->removePlayerMark(liaohua, "@tenyearfuliMark");
            int x = getKingdoms(room);
            int n = qMin(x - liaohua->getHp(), liaohua->getMaxHp() - liaohua->getHp());
            if (n > 0)
                room->recover(liaohua, RecoverStruct(liaohua, NULL, n));
            if (liaohua->getHandcardNum() < x)
                liaohua->drawCards(x - liaohua->getHandcardNum(), objectName());
            room->addPlayerMark(liaohua, "tenyeardangxian");
            QString translate = Sanguosha->translate(":tenyeardangxian2");
            room->changeTranslation(liaohua, "tenyeardangxian", translate);
            if (x >= 3)
                liaohua->turnOver();
        }
        return false;
    }
};

TenyearChunlaoCard::TenyearChunlaoCard(QString tenyearchunlao) : tenyearchunlao(tenyearchunlao)
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void TenyearChunlaoCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->addToPile("wine", this);
}

TenyearChunlaoWineCard::TenyearChunlaoWineCard(QString tenyearchunlao) : tenyearchunlao(tenyearchunlao)
{
    m_skillName = tenyearchunlao;
    mute = true;
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void TenyearChunlaoWineCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    ServerPlayer *who = room->getCurrentDyingPlayer();
    if (!who) return;

    if (subcards.length() != 0) {
        CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), tenyearchunlao, QString());
        DummyCard *dummy = new DummyCard(subcards);
        room->throwCard(dummy, reason, NULL);
        delete dummy;
        Analeptic *analeptic = new Analeptic(Card::NoSuit, 0);
        analeptic->setSkillName("_" + tenyearchunlao);
        room->useCard(CardUseStruct(analeptic, who, who, false));

        const Card *card = Sanguosha->getCard(getSubcards().first());
        if (card->getClassName() == "FireSlash")
            room->recover(source, RecoverStruct(source));
        else if (card->getClassName() == "ThunderSlash")
            source->drawCards(2, tenyearchunlao);
    }
}

class TenyearChunlaoViewAsSkill : public ViewAsSkill
{
public:
    TenyearChunlaoViewAsSkill(const QString &tenyearchunlao) : ViewAsSkill(tenyearchunlao), tenyearchunlao(tenyearchunlao)
    {
        expand_pile = "wine";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@" + tenyearchunlao
            || (pattern.contains("peach") && !player->getPile("wine").isEmpty());
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@" + tenyearchunlao)
            return to_select->isKindOf("Slash");
        else {
            ExpPattern pattern(".|.|.|wine");
            if (!pattern.match(Self, to_select)) return false;
            return selected.length() == 0;
        }
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@" + tenyearchunlao) {
            if (cards.length() == 0) return NULL;

            Card *acard = NULL;
            if (tenyearchunlao == "tenyearchunlao")
                acard = new TenyearChunlaoCard;
            else if (tenyearchunlao == "secondtenyearchunlao")
                acard = new SecondTenyearChunlaoCard;
            if (!acard) return NULL;
            acard->addSubcards(cards);
            acard->setSkillName(tenyearchunlao);
            return acard;
        } else {
            if (cards.length() != 1) return NULL;
            Card *wine = NULL;
            if (tenyearchunlao == "tenyearchunlao")
                wine = new TenyearChunlaoWineCard;
            else if (tenyearchunlao == "secondtenyearchunlao")
                wine = new SecondTenyearChunlaoWineCard;
            if (!wine) return NULL;
            wine->addSubcards(cards);
            wine->setSkillName(tenyearchunlao);
            return wine;
        }
    }

private:
    QString tenyearchunlao;
};

class TenyearChunlao : public PhaseChangeSkill
{
public:
    TenyearChunlao() : PhaseChangeSkill("tenyearchunlao")
    {
        view_as_skill = new TenyearChunlaoViewAsSkill("tenyearchunlao");
    }

    bool onPhaseChange(ServerPlayer *chengpu) const
    {
        Room *room = chengpu->getRoom();
        if (chengpu->getPhase() == Player::Finish && !chengpu->isKongcheng() && chengpu->getPile("wine").isEmpty())
            room->askForUseCard(chengpu, "@@tenyearchunlao", "@tenyearchunlao", -1, Card::MethodNone);
        return false;
    }
};

class SecondTenyearLihuoViewAsSkill : public OneCardViewAsSkill
{
public:
    SecondTenyearLihuoViewAsSkill() : OneCardViewAsSkill("secondtenyearlihuo")
    {
        filter_pattern = "%slash";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE
            && (pattern.contains("slash") || pattern.contains("Slash"));
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Card *acard = new FireSlash(originalCard->getSuit(), originalCard->getNumber());
        acard->addSubcard(originalCard->getId());
        acard->setSkillName(objectName());
        return acard;
    }
};

class SecondTenyearLihuo : public TriggerSkill
{
public:
    SecondTenyearLihuo() : TriggerSkill("secondtenyearlihuo")
    {
        events << PreDamageDone << CardFinished << ChangeSlash;
        view_as_skill = new SecondTenyearLihuoViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == PreDamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->isKindOf("Slash") && damage.card->getSkillName() == objectName()) {
                QVariantList slash_list = damage.from->tag["InvokeSecondTenyearLihuo"].toList();
                slash_list << QVariant::fromValue(damage.card);
                damage.from->tag["InvokeSecondTenyearLihuo"] = QVariant::fromValue(slash_list);
            }
        } else if (triggerEvent == ChangeSlash) {
            if (!TriggerSkill::triggerable(player)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->objectName() != "slash") return false;
            bool has_changed = false;
            QString skill_name = use.card->getSkillName();
            if (!skill_name.isEmpty()) {
                const Skill *skill = Sanguosha->getSkill(skill_name);
                if (skill && !skill->inherits("FilterSkill") && !skill->objectName().contains("guhuo"))
                    has_changed = true;
            }
            if (!has_changed || (use.card->isVirtualCard() && use.card->subcardsLength() == 0)) {
                FireSlash *fire_slash = new FireSlash(use.card->getSuit(), use.card->getNumber());
                if (!use.card->isVirtualCard() || use.card->subcardsLength() > 0)
                    fire_slash->addSubcard(use.card);
                fire_slash->setSkillName("secondtenyearlihuo");
                bool can_use = true;
                foreach (ServerPlayer *p, use.to) {
                    if (!player->canSlash(p, fire_slash, false)) {
                        can_use = false;
                        break;
                    }
                }
                if (can_use && room->askForSkillInvoke(player, "secondtenyearlihuo", data, false)) {
                    use.card = fire_slash;
                    data = QVariant::fromValue(use);
                }
            }
        } else if (triggerEvent == CardFinished) {
            if (player->isDead() || !player->hasSkill(this)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!player->hasFlag("Global_ProcessBroken")) {
                if (!use.card->isKindOf("Slash"))
                    return false;

                bool can_invoke = false;
                QVariantList slash_list = use.from->tag["InvokeSecondTenyearLihuo"].toList();
                foreach (QVariant card, slash_list) {
                    if (card.value<const Card *>() == use.card) {
                        can_invoke = true;
                        slash_list.removeOne(card);
                        use.from->tag["InvokeSecondTenyearLihuo"] = QVariant::fromValue(slash_list);
                        break;
                    }
                }
                if (can_invoke) {
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    room->loseHp(player, 1);
                }
            }

            if (player->isDead() || !use.card->isKindOf("Slash")) return false;
            if (!use.card->hasFlag("first_card_in_one_turn")) return false;
            if (!room->CardInPlace(use.card, Player::DiscardPile) || !player->askForSkillInvoke(this, "put")) return false;
            room->broadcastSkillInvoke(objectName());
            player->addToPile("wine", use.card);
        }
        return false;
    }
};

class SecondTenyearLihuoRecord : public TriggerSkill
{
public:
    SecondTenyearLihuoRecord() : TriggerSkill("#secondtenyearlihuo-record")
    {
        events << PreCardResponded << PreCardUsed;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 6;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        const Card *card = NULL;
        if (triggerEvent == PreCardUsed)
            card = data.value<CardUseStruct>().card;
        else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse) return false;
            card = res.m_card;
        }
        if (!card || card->isKindOf("SkillCard")) return false;
        if (player->getMark("secondtenyearlihuo-Clear") > 0 ) return false;
        room->setCardFlag(card, "first_card_in_one_turn");
        room->addPlayerMark(player, "secondtenyearlihuo-Clear");
        return false;
    }
};

class SecondTenyearLihuoTargetMod : public TargetModSkill
{
public:
    SecondTenyearLihuoTargetMod() : TargetModSkill("#secondtenyearlihuo-target")
    {
        frequency = NotFrequent;
    }

    int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (from->hasSkill("secondtenyearlihuo") && card->isKindOf("FireSlash"))
            return 1;
        else
            return 0;
    }
};

SecondTenyearChunlaoCard::SecondTenyearChunlaoCard() : TenyearChunlaoCard("secondtenyearchunlao")
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

SecondTenyearChunlaoWineCard::SecondTenyearChunlaoWineCard() : TenyearChunlaoWineCard("secondtenyearchunlao")
{
    m_skillName = "secondtenyearchunlao";
    mute = true;
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

class SecondTenyearChunlao : public TriggerSkill
{
public:
    SecondTenyearChunlao() : TriggerSkill("secondtenyearchunlao")
    {
        events << EventPhaseEnd;
        view_as_skill = new TenyearChunlaoViewAsSkill("secondtenyearchunlao");
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        {
            if (player->getPhase() == Player::Play && !player->isKongcheng() && player->getPile("wine").isEmpty())
                room->askForUseCard(player, "@@secondtenyearchunlao", "@secondtenyearchunlao", -1, Card::MethodNone);
            return false;
        }
    }
};

TenyearJiangchiCard::TenyearJiangchiCard()
{
    target_fixed = true;
    mute = true;
}

void TenyearJiangchiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (getSubcards().isEmpty()) {
        room->broadcastSkillInvoke("tenyearjiangchi", 1);
        source->drawCards(1, "tenyearjiangchi");
        room->setPlayerCardLimitation(source, "use,response", "Slash", true);
    } else if (getSubcards().length() == 1) {
        room->broadcastSkillInvoke("tenyearjiangchi", 2);
        room->addSlashJuli(source, 1000);
        room->addSlashCishu(source, 1);
    }
}

class TenyearJiangchiVS : public ViewAsSkill
{
public:
    TenyearJiangchiVS() : ViewAsSkill("tenyearjiangchi")
    {
    }
    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearjiangchi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && selected.isEmpty();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 0 && cards.length() != 1) return NULL;
        Card *acard = new TenyearJiangchiCard;
        if (!cards.isEmpty())
            acard->addSubcards(cards);
        return acard;
    }
};

class TenyearJiangchi : public TriggerSkill
{
public:
    TenyearJiangchi() : TriggerSkill("tenyearjiangchi")
    {
        events << EventPhaseEnd;
        view_as_skill = new TenyearJiangchiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *caozhang, QVariant &) const
    {
        if (caozhang->getPhase() != Player::Draw) return false;
        room->askForUseCard(caozhang, "@@tenyearjiangchi", "@tenyearjiangchi");
        return false;
    }
};

class SecondTenyearJiangchi : public PhaseChangeSkill
{
public:
    SecondTenyearJiangchi() : PhaseChangeSkill("secondtenyearjiangchi")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play || !player->askForSkillInvoke(this)) return false;

        Room *room = player->getRoom();
        QString choices = "two+one";
        if (player->canDiscard(player, "he"))
            choices += "+discard";
        QString choice = room->askForChoice(player, objectName(), choices);

        if (choice == "two") {
            room->broadcastSkillInvoke(objectName(), 1);
            player->drawCards(2, objectName());
            room->addPlayerMark(player, "secondtenyearjiangchi_limit-Clear");
            room->setPlayerCardLimitation(player, "use,response", "Slash", true);
        } else if (choice == "one") {
            room->broadcastSkillInvoke(objectName(), 1);
            player->drawCards(1, objectName());
        } else {
            room->broadcastSkillInvoke(objectName(), 2);
            room->askForDiscard(player, objectName(), 1, 1, false, true, QString(), ".", objectName());
            room->addPlayerMark(player, "secondtenyearjiangchi_slash-PlayClear");
        }
        return false;
    }
};

class SecondTenyearJiangchiClear : public TriggerSkill
{
public:
    SecondTenyearJiangchiClear() : TriggerSkill("#secondtenyearjiangchi-clear")
    {
        events << EventPhaseChanging << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->getMark("secondtenyearjiangchi_limit-Clear") <= 0) return false;
            room->removePlayerCardLimitation(death.who, "use,response", "Slash$1");
        } else {
            if (data.value<PhaseChangeStruct>().from != Player::Play) return false;
            if (player->getMark("secondtenyearjiangchi_limit-Clear") <= 0) return false;
            room->setPlayerMark(player, "secondtenyearjiangchi_limit-Clear", 0);
            room->removePlayerCardLimitation(player, "use,response", "Slash$1");
        }
        return false;
    }
};

class SecondTenyearJiangchiMod : public TargetModSkill
{
public:
    SecondTenyearJiangchiMod() : TargetModSkill("#secondtenyearjiangchi-target")
    {
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("secondtenyearjiangchi_slash-PlayClear") > 0)
            return 1;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("secondtenyearjiangchi_slash-PlayClear") > 0)
            return 1000;
        else
            return 0;
    }
};

TenyearWurongCard::TenyearWurongCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool TenyearWurongCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length() > 0 || to_select == Self)
        return false;
    return !to_select->isKongcheng();
}

void TenyearWurongCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();

    int index = qrand() % 2 + 1;
    if (effect.from->isJieGeneral("second_tenyear_zhangyi"))
        index += 2;
    room->broadcastSkillInvoke("tenyearwurong", index);

    const Card *c = room->askForExchange(effect.to, "tenyearwurong", 1, 1, false, "@tenyearwurong-show");

    room->showCard(effect.from, subcards.first());
    room->showCard(effect.to, c->getSubcards().first());

    const Card *card1 = Sanguosha->getCard(subcards.first());
    const Card *card2 = Sanguosha->getCard(c->getSubcards().first());

    if (card1->isKindOf("Slash") && !card2->isKindOf("Jink")) {
        room->damage(DamageStruct(objectName(), effect.from, effect.to));
    } else if (!card1->isKindOf("Slash") && card2->isKindOf("Jink")) {
        if (!effect.to->isNude()) {
            int id = room->askForCardChosen(effect.from, effect.to, "he", objectName());
            room->obtainCard(effect.from, id, false);
        }
    }

    delete c;
}

class TenyearWurong : public OneCardViewAsSkill
{
public:
    TenyearWurong() : OneCardViewAsSkill("tenyearwurong")
    {
        filter_pattern = ".|.|.|hand";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearWurongCard *fr = new TenyearWurongCard;
        fr->addSubcard(originalCard);
        return fr;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearWurongCard");
    }
};

class SecondTenyearShizhi : public FilterSkill
{
public:
    SecondTenyearShizhi() : FilterSkill("secondtenyearshizhi")
    {

    }

    bool viewFilter(const Card *to_select) const
    {
        Room *room = Sanguosha->currentRoom();
        ServerPlayer *player = room->getCardOwner(to_select->getId());
        return player != NULL && player->getHp() == 1 && to_select->isKindOf("Jink");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->setSkillName(objectName());
        WrappedCard *card = Sanguosha->getWrappedCard(originalCard->getId());
        card->takeOver(slash);
        return card;
    }
};

class SecondTenyearShizhiTrigger : public TriggerSkill
{
public:
    SecondTenyearShizhiTrigger() : TriggerSkill("#secondtenyearshizhi")
    {
        events << HpChanged << MaxHpChanged << EventAcquireSkill << EventLoseSkill << GameStart << Revived << Damage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == Damage) {
            if (!player->hasSkill("secondtenyearshizhi") || !player->isWounded()) return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || !damage.by_user || damage.card->getSkillName() != "secondtenyearshizhi")
                return false;
            room->sendCompulsoryTriggerLog(player, "secondtenyearshizhi", true, true);
            room->recover(player, RecoverStruct(player));
            return false;
        }

        if (triggerEvent == EventAcquireSkill || triggerEvent == EventLoseSkill) {
            if (data.toString() != "secondtenyearshizhi")
                return false;
        }

        if (triggerEvent == HpChanged || triggerEvent == MaxHpChanged || triggerEvent == GameStart) {
            if (!player->hasSkill(this))
                return false;
        }

        bool skillStateBefore = false;
        if (triggerEvent != EventAcquireSkill && triggerEvent != GameStart && triggerEvent != Revived)
            skillStateBefore = player->getMark("secondtenyearshizhi") > 0;

        bool skillStateAfter = false;
        if (triggerEvent == EventLoseSkill)
            skillStateAfter = true;
        else
            skillStateAfter = player->getHp() == 1;

        if (skillStateAfter != skillStateBefore)
            room->filterCards(player, player->getCards("he"), true);

        player->setMark("secondtenyearshizhi", skillStateAfter ? 1 : 0);

        return false;
    }
};

class TenyearYaoming : public TriggerSkill
{
public:
    TenyearYaoming() : TriggerSkill("tenyearyaoming")
    {
        events << Damage << Damaged;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (player->getMark("tenyearyaoming_dayu-Clear") <= 0 && p->getHandcardNum() > player->getHandcardNum() && player->canDiscard(p, "h"))
                targets << p;
            if (player->getMark("tenyearyaoming_xiaoyu-Clear") <= 0 && p->getHandcardNum() < player->getHandcardNum())
                targets << p;
            if (player->getMark("tenyearyaoming_dengyu-Clear") <= 0 && p->canDiscard(p, "he") && p->getHandcardNum() == player->getHandcardNum())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@tenyearyaoming-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        if (target->getHandcardNum() > player->getHandcardNum()) {
            room->addPlayerMark(player, "tenyearyaoming_dayu-Clear");
            if (!player->canDiscard(target, "h")) return false;
            int card_id = room->askForCardChosen(player, target, "h", objectName(), false, Card::MethodDiscard);
            room->throwCard(Sanguosha->getCard(card_id), target, player);
        } else if (target->getHandcardNum() < player->getHandcardNum()) {
            room->addPlayerMark(player, "tenyearyaoming_xiaoyu-Clear");
            target->drawCards(1, objectName());
        } else {
            room->addPlayerMark(player, "tenyearyaoming_dengyu-Clear");
            const Card * card = room->askForDiscard(target, objectName(), 2, 1, true, true, "tenyearyaoming-discard");
            if (!card) return false;
            target->drawCards(card->getSubcards().length(), objectName());
        }
        return false;
    }
};

class TenyearDanshou : public TriggerSkill
{
public:
    TenyearDanshou() : TriggerSkill("tenyeardanshou")
    {
        events << TargetConfirmed << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.to.contains(player) || !player->hasSkill(this)) return false;
            if (player->getMark("tenyeardanshou-Clear") > 0) return false;
            const Card *card = use.card;
            if (!card->isKindOf("BasicCard") && !card->isKindOf("TrickCard")) return false;
            int x = player->getMark("tenyeardanshou_target-Clear");
            QString num = QString::number(x);
            if (!player->askForSkillInvoke(this, QString("tenyeardanshou_invoke:%1").arg(num))) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "tenyeardanshou-Clear");
            player->drawCards(x, objectName());
        } else {
            if (player->getPhase() != Player::Finish) return false;
            foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
                if (player->isDead()) break;
                if (p->isDead() || !p->hasSkill(this)) continue;
                if (p->getMark("tenyeardanshou-Clear") > 0) continue;
                if (player->isKongcheng()) {
                    if (!p->askForSkillInvoke(objectName(), QString("tenyeardanshou_damage:%1").arg(player->objectName()))) continue;
                    room->broadcastSkillInvoke(objectName());
                    room->damage(DamageStruct(objectName(), p, player));
                } else {
                    int candis = 0;
                    foreach (const Card *c, p->getCards("he")) {
                        if (p->canDiscard(p, c->getEffectiveId()))
                            candis++;
                    }
                    int handnum = player->getHandcardNum();
                    if (candis < handnum) continue;
                    if (!room->askForDiscard(p, objectName(), handnum, handnum, true, true,
                    QString("@tenyeardanshou-dis:%1::%2").arg(player->objectName()).arg(handnum), ".", objectName())) continue;
                    room->damage(DamageStruct(objectName(), p, player));
                }
            }
        }
        return false;
    }
};

class TenyearDanshouRecord : public TriggerSkill
{
public:
    TenyearDanshouRecord() : TriggerSkill("#tenyeardanshou-record")
    {
        events << TargetConfirmed;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (!use.to.contains(player)) return false;
        room->addPlayerMark(player, "tenyeardanshou_target-Clear");
        return false;
    }
};

class TenyearZenhui : public TriggerSkill
{
public:
    TenyearZenhui() : TriggerSkill("tenyearzenhui")
    {
        events << TargetSpecifying << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (triggerEvent == CardFinished && (use.card->isKindOf("Slash") || use.card->isNDTrick())) {
            use.from->setFlags("-TenyearZenhuiUser_" + use.card->toString());
            return false;
        }
        if (!TriggerSkill::triggerable(player) || player->hasFlag(objectName()))
            return false;

        if (use.to.length() == 1 && (use.card->isKindOf("Slash") || use.card->isNDTrick())) {
            QList<ServerPlayer *> targets = room->getOtherPlayers(use.to.first());
            if (targets.contains(player))
                targets.removeOne(player);
            if (targets.isEmpty()) return false;
            use.from->tag["tenyearzenhui"] = data;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@tenyearzenhui-invoke:" + use.to.first()->objectName(), true, true);
            use.from->tag.remove("tenyearzenhui");
            if (target) {

                // Collateral
                ServerPlayer *collateral_victim = NULL;
                if (use.card->isKindOf("Collateral")) {
                    QList<ServerPlayer *> victims;
                    foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                        if (target->canSlash(p))
                            victims << p;
                    }
                    Q_ASSERT(!victims.isEmpty());
                    collateral_victim = room->askForPlayerChosen(player, victims, "tenyearzenhui_collateral", "@tenyearzenhui-collateral:" + target->objectName());
                    target->tag["collateralVictim"] = QVariant::fromValue((collateral_victim));

                    LogMessage log;
                    log.type = "#CollateralSlash";
                    log.from = player;
                    log.to << collateral_victim;
                    room->sendLog(log);
                }

                room->broadcastSkillInvoke(objectName());

                bool canbeextra = true;
                if (room->isProhibited(player, target, use.card) || !use.card->targetFilter(QList<const Player *>(), target, player))
                    canbeextra = false;
                if (target->isNude() && !canbeextra) return false;
                bool extra_target = true;
                if (!target->isNude()) {
                    QString pattern = "..";
                    QString prompt = "tenyearzenhui-give:" + player->objectName();
                    if (!canbeextra) {
                        pattern = "..!";
                        prompt = "tenyearzenhui-mustgive:" + player->objectName();
                    }
                    const Card *card = room->askForCard(target, pattern, prompt, data, Card::MethodNone);
                    if (!canbeextra && !card) {
                        card = target->getCards("he").at(qrand() % target->getCards("he").length());
                    }
                    if (card) {
                        extra_target = false;
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "tenyearzenhui", QString());
                        room->obtainCard(player, card, reason, false);

                        if (target->isAlive()) {
                            LogMessage log;
                            log.type = "#BecomeUser";
                            log.from = target;
                            log.card_str = use.card->toString();
                            room->sendLog(log);

                            target->setFlags("TenyearZenhuiUser_" + use.card->toString()); // For AI
                            use.from = target;
                            data = QVariant::fromValue(use);
                        }
                    }
                }
                if (extra_target) {
                    player->setFlags(objectName());
                    LogMessage log;
                    log.type = "#BecomeTarget";
                    log.from = target;
                    log.card_str = use.card->toString();
                    room->sendLog(log);

                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    if (use.card->isKindOf("Collateral") && collateral_victim)
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), collateral_victim->objectName());

                    use.to.append(target);
                    room->sortByActionOrder(use.to);
                    data = QVariant::fromValue(use);
                }
            }
        }
        return false;
    }
};

class TenyearJiaojin : public TriggerSkill
{
public:
    TenyearJiaojin() : TriggerSkill("tenyearjiaojin")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player) || player->getMark("tenyearjiaojin-Clear") > 0) return false;
        if (!use.from || use.from->isDead() || use.from == player) return false;
        if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
        if (!room->askForCard(player, ".Equip", "@tenyearjiaojin:" + use.from->objectName() + "::" + use.card->objectName(), data, objectName())) return false;
        room->broadcastSkillInvoke(objectName());
        use.nullified_list << player->objectName();
        data = QVariant::fromValue(use);
        //if (room->getCardPlace(use.card->getEffectiveId() != Player::PlaceTable)) return false;
        if (!room->CardInPlace(use.card, Player::PlaceTable)) return false;
        room->obtainCard(player, use.card);
        if (use.from->isFemale() && room->hasCurrent())
            room->addPlayerMark(player, "tenyearjiaojin-Clear");
        return false;
    }
};

class TenyearBenxiVS : public ZeroCardViewAsSkill
{
public:
    TenyearBenxiVS() : ZeroCardViewAsSkill("tenyearbenxi")
    {
        response_pattern = "@@tenyearbenxi!";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new ExtraCollateralCard;
    }
};

class TenyearBenxi : public TriggerSkill
{
public:
    TenyearBenxi() : TriggerSkill("tenyearbenxi")
    {
        events << CardUsed << DamageCaused << PreCardUsed << CardResponded;
        view_as_skill = new TenyearBenxiVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (player->getPhase() == Player::NotActive || use.card->isKindOf("SkillCard")) return false;
            //room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->notifySkillInvoked(player, objectName());
            room->addDistance(player, -1);
            room->addPlayerMark(player, "&tenyearbenxi-Clear");
        } else if (event == CardResponded) {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (player->getPhase() == Player::NotActive || res.m_card->isKindOf("SkillCard")) return false;
            if (!res.m_isUse) return false;
            room->notifySkillInvoked(player, objectName());
            room->addDistance(player, -1);
            room->addPlayerMark(player, "&tenyearbenxi-Clear");
        } else if (event == PreCardUsed) {
            if (player->getPhase() == Player::NotActive) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
            if (use.to.length() != 1) return false;
            bool allone = true;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->distanceTo(p) != 1) {
                    allone = false;
                    break;
                }
            }
            if (!allone) return false;
            QStringList choices, excepts;
            QList<ServerPlayer *> available_targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                if (use.from == p && use.card->isKindOf("AOE")) continue;
                if (use.card->targetFixed()) {
                    if (!use.card->isKindOf("Peach") || p->isWounded())
                        available_targets << p;
                } else {
                    if (use.card->targetFilter(QList<const Player *>(), p, player))
                        available_targets << p;
                }
            }
            if (!available_targets.isEmpty()) choices << "extra";
            choices << "ignore" << "noresponse" << "draw" <<"cancel";
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            for (int i = 1; i <= 2; i++) {
                if (choices.isEmpty()) break;
                QString choice = room->askForChoice(player, objectName(), choices.join("+"), data, excepts.join("+"));
                if (choice == "cancel") break;
                choices.removeOne(choice);
                excepts << choice;
                LogMessage log;
                log.type = "#FumianFirstChoice";
                log.from = player;
                log.arg = "tenyearbenxi:" + choice;
                room->sendLog(log);
                if (choice == "extra") {
                    ServerPlayer *target = NULL;
                    if (!use.card->isKindOf("Collateral"))
                        target = room->askForPlayerChosen(player, available_targets, objectName(), "@tenyearbenxi-extra:" + use.card->objectName());
                    else {
                        QStringList tos;
                        foreach(ServerPlayer *t, use.to)
                            tos.append(t->objectName());
                        room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                        room->setPlayerProperty(player, "extra_collateral_current_targets", tos.join("+"));
                        room->askForUseCard(player, "@@tenyearbenxi!", "@tenyearbenxi-extra:" + use.card->objectName());
                        room->setPlayerProperty(player, "extra_collateral", QString());
                        room->setPlayerProperty(player, "extra_collateral_current_targets", QString("+"));
                        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                            if (p->hasFlag("ExtraCollateralTarget")) {
                                p->setFlags("-ExtraCollateralTarget");
                                target = p;
                                break;
                            }
                        }
                        if (target == NULL) {
                            target = available_targets.at(qrand() % available_targets.length() - 1);
                            QList<ServerPlayer *> victims;
                            foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                                if (target->canSlash(p)
                                    && (!(p == player && p->hasSkill("kongcheng") && p->isLastHandCard(use.card, true)))) {
                                    victims << p;
                                }
                            }
                            Q_ASSERT(!victims.isEmpty());
                            target->tag["collateralVictim"] = QVariant::fromValue((victims.at(qrand() % victims.length() - 1)));
                        }
                    }
                    use.to.append(target);
                    room->sortByActionOrder(use.to);

                    if (use.card->hasFlag("tenyearbenxi_ignore"))
                        target->addQinggangTag(use.card);

                    LogMessage log;
                    log.type = "#QiaoshuiAdd";
                    log.from = player;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = "tenyearbenxi";
                    room->sendLog(log);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());

                    if (use.card->isKindOf("Collateral")) {
                        ServerPlayer *victim = target->tag["collateralVictim"].value<ServerPlayer *>();
                        if (victim) {
                            LogMessage log;
                            log.type = "#CollateralSlash";
                            log.from = player;
                            log.to << victim;
                            room->sendLog(log);
                            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());
                        }
                    }
                    data = QVariant::fromValue(use);
                } else if (choice == "ignore") {
                    room->setCardFlag(use.card, "tenyearbenxi_ignore");
                    foreach (ServerPlayer *p, use.to)
                        p->addQinggangTag(use.card);
                } else if (choice == "noresponse") {
                    use.no_offset_list << "_ALL_TARGETS";
                    data = QVariant::fromValue(use);
                } else {
                    room->setCardFlag(use.card, "tenyearbenxi_damage");
                }
            }
        } else if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->hasFlag("tenyearbenxi_damage")) return false;
            player->drawCards(1, objectName());
        }
        return false;
    }
};

TenyearKuangfuCard::TenyearKuangfuCard()
{
}

bool TenyearKuangfuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canDiscard(to_select, "e");
}

void TenyearKuangfuCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->getEquips().isEmpty()) return;
    Room *room = effect.from->getRoom();
    int card_id = room->askForCardChosen(effect.from, effect.to, "e", "tenyearkuangfu", false, Card::MethodDiscard);
    room->throwCard(card_id, effect.to, effect.from);
    if (effect.from->isDead()) return;
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("_tenyearkuangfu");
    slash->deleteLater();
    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.from)) {
        if (effect.from->canSlash(p, slash, false)) {
            targets << p;
        }
    }
    if (targets.isEmpty()) return;
    if (!room->askForUseCard(effect.from, "@@tenyearkuangfu!", "@tenyearkuangfu")) {
        ServerPlayer *target = targets.at(qrand() % targets.length());
        room->useCard(CardUseStruct(slash, effect.from , target), false);
    }

    bool damage = effect.from->getMark("tenyearkuangfu_damage-Clear") > 0;
    room->setPlayerMark(effect.from, "tenyearkuangfu_damage-Clear", 0);

    if (effect.to == effect.from && damage) {
        effect.from->drawCards(2, "tenyearkuangfu");
    } else if (effect.to != effect.from && !damage) {
        room->askForDiscard(effect.from, "tenyearkuangfu", 2, 2);
    }
}

class TenyearKuangfuVS : public ZeroCardViewAsSkill
{
public:
    TenyearKuangfuVS() : ZeroCardViewAsSkill("tenyearkuangfu")
    {
        response_pattern = "@@tenyearkuangfu!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearKuangfuCard");
    }

    const Card *viewAs() const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@tenyearkuangfu!") {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_tenyearkuangfu");
            return slash;
        }
        return new TenyearKuangfuCard;
    }
};

class TenyearKuangfu : public TriggerSkill
{
public:
    TenyearKuangfu() : TriggerSkill("tenyearkuangfu")
    {
        events << PreCardUsed << Damage;
        view_as_skill =new TenyearKuangfuVS;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName() == "tenyearkuangfu" && !use.card->isKindOf("SkillCard") && use.m_addHistory)
                room->addPlayerHistory(player, use.card->getClassName(), -1);
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->getSkillName() == "tenyearkuangfu" && !damage.card->isKindOf("SkillCard"))
                room->setPlayerMark(player, "tenyearkuangfu_damage-Clear", 1);
        }
        return false;
    }
};

class TenyearPojun : public TriggerSkill
{
public:
    TenyearPojun() : TriggerSkill("tenyearpojun")
    {
        events << TargetSpecified << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card != NULL && use.card->isKindOf("Slash") && TriggerSkill::triggerable(player)) {
                foreach (ServerPlayer *t, use.to) {
                    if (player->isDead()) return false;
                    if (t->isDead()) continue;
                    int n = qMin(t->getCards("he").length(), t->getHp());
                    if (n > 0 && player->askForSkillInvoke(this, QVariant::fromValue(t))) {
                        room->broadcastSkillInvoke(objectName());
                        QStringList dis_num;
                        for (int i = 1; i <= n; ++i)
                            dis_num << QString::number(i);

                        int ad = Config.AIDelay;
                        Config.AIDelay = 0;

                        bool ok = false;
                        int discard_n = room->askForChoice(player, objectName() + "_num", dis_num.join("+")).toInt(&ok);
                        if (!ok || discard_n == 0) {
                            Config.AIDelay = ad;
                            continue;
                        }

                        QList<Player::Place> orig_places;
                        QList<int> cards;
                        // fake move skill needed!!!
                        t->setFlags("tenyearpojun_InTempMoving");

                        for (int i = 0; i < discard_n; ++i) {
                            int id = room->askForCardChosen(player, t, "he", objectName() + "_dis", false, Card::MethodNone);
                            Player::Place place = room->getCardPlace(id);
                            orig_places << place;
                            cards << id;
                            t->addToPile("#mobilepojun", id, false);
                        }

                        for (int i = 0; i < discard_n; ++i)
                            room->moveCardTo(Sanguosha->getCard(cards.value(i)), t, orig_places.value(i), false);

                        t->setFlags("-tenyearpojun_InTempMoving");
                        Config.AIDelay = ad;

                        DummyCard dummy(cards);
                        t->addToPile("tenyearpojun", &dummy, false);

                        QList<int> equips;
                        bool has_trick = false;
                        foreach (int id, cards) {
                            if (Sanguosha->getCard(id)->isKindOf("EquipCard"))
                                equips << id;
                            else if (Sanguosha->getCard(id)->isKindOf("TrickCard"))
                                has_trick = true;
                        }

                        if (!equips.isEmpty()) {
                            room->fillAG(equips, player);
                            int id = room->askForAG(player, equips, false, objectName());
                            room->clearAG(player);
                            cards.removeOne(id);
                            room->throwCard(id, t, player);
                        }

                        if (has_trick)
                            player->drawCards(1, objectName());

                        // for record
                        if (!t->tag.contains("tenyearpojun") || !t->tag.value("tenyearpojun").canConvert(QVariant::Map))
                            t->tag["tenyearpojun"] = QVariantMap();

                        QVariantMap vm = t->tag["tenyearpojun"].toMap();
                        foreach (int id, cards)
                            vm[QString::number(id)] = player->objectName();

                        t->tag["tenyearpojun"] = vm;
                    }
                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->tag.contains("tenyearpojun")) {
                    QVariantMap vm = p->tag.value("tenyearpojun", QVariantMap()).toMap();
                    if (vm.values().contains(player->objectName())) {
                        QList<int> to_obtain;
                        foreach (const QString &key, vm.keys()) {
                            if (vm.value(key) == player->objectName())
                                to_obtain << key.toInt();
                        }

                        DummyCard dummy(to_obtain);
                        room->obtainCard(p, &dummy, false);

                        foreach (int id, to_obtain)
                            vm.remove(QString::number(id));

                        p->tag["tenyearpojun"] = vm;
                    }
                }
            }
        }
        return false;
    }
};

class TenyearDuanliang : public OneCardViewAsSkill
{
public:
    TenyearDuanliang() : OneCardViewAsSkill("tenyearduanliang")
    {
        filter_pattern = "BasicCard,EquipCard|black";
        response_or_use = true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        SupplyShortage *shortage = new SupplyShortage(originalCard->getSuit(), originalCard->getNumber());
        shortage->setSkillName(objectName());
        shortage->addSubcard(originalCard);
        return shortage;
    }
};

class TenyearDuanliangTargetMod : public TargetModSkill
{
public:
    TenyearDuanliangTargetMod() : TargetModSkill("#tenyearduanliang-target")
    {
        frequency = NotFrequent;
        pattern = "SupplyShortage";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->hasSkill("tenyearduanliang") && to && from->getHandcardNum() <= to->getHandcardNum())
            return 1000;
        else
            return 0;
    }
};

class TenyearJiezi : public TriggerSkill
{
public:
    TenyearJiezi() : TriggerSkill("tenyearjiezi")
    {
        events << EventPhaseSkipped;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Draw) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isAlive() && p->hasSkill(this)) {
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                p->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class TenyearCanshi : public TriggerSkill
{
public:
    TenyearCanshi() : TriggerSkill("tenyearcanshi")
    {
        events << DrawNCards << CardUsed << CardResponded;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == DrawNCards) {
            if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Draw) {
                int n = 0;
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isWounded())
                        ++n;
                }

                if (n > 0 && player->askForSkillInvoke(this)) {
                    room->broadcastSkillInvoke(objectName());
                    player->setFlags(objectName());
                    data = QVariant::fromValue(data.toInt() + n);
                }
            }
        } else {
            if (player->hasFlag(objectName())) {
                const Card *card = NULL;
                if (triggerEvent == CardUsed)
                    card = data.value<CardUseStruct>().card;
                else {
                    CardResponseStruct resp = data.value<CardResponseStruct>();
                    if (resp.m_isUse)
                        card = resp.m_card;
                }
                if (card != NULL && (card->isKindOf("Slash") || card->isNDTrick())) {
                    room->sendCompulsoryTriggerLog(player, objectName());
                    room->askForDiscard(player, objectName(), 1, 1, false, true, "@tenyearcanshi-discard");
                }
            }
        }
        return false;
    }
};

class TenyearChouhai : public TriggerSkill
{
public:
    TenyearChouhai() : TriggerSkill("tenyearchouhai")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash")) return false;
        if (player->isKongcheng()) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

TenyearYanzhuCard::TenyearYanzhuCard()
{
}

void TenyearYanzhuCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead()) return;
    if (effect.from->isDead() && !effect.to->canDiscard(effect.to, "he")) return;
    Room *room = effect.from->getRoom();

    if (effect.from->property("tenyearyanzhu_level_up").toBool()) {
        room->addPlayerMark(effect.to, "&tenyearyanzhu");
        return;
    }

    bool optional = effect.from->isAlive() ? true : false;
    optional = !effect.to->getEquips().isEmpty() ? true : false;
    QString prompt = optional ? "@tenyearyanzhu-discard:" + effect.from->objectName() : "@tenyearyanzhu-discard2";
    if (!room->askForDiscard(effect.to, "tenyearyanzhu", 1, 1, optional, true, prompt)) {
        QList<int> list = effect.to->getEquipsId();
        DummyCard *dummy = new DummyCard(list);
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
        room->obtainCard(effect.from, dummy, reason);
        delete dummy;
        room->setPlayerProperty(effect.from, "tenyearyanzhu_level_up", true);
        room->setPlayerProperty(effect.from, "tenyearxingxue_level_up", true);
        LogMessage log;
        log.type = "#JiexunChange";
        log.from = effect.from;
        if (effect.from->hasSkill("tenyearyanzhu"), true) {
            log.arg = "tenyearyanzhu";
            room->sendLog(log);
        }
        if (effect.from->hasSkill("tenyearxingxue"), true) {
            log.arg = "tenyearxingxue";
            room->sendLog(log);
        }
        QString translate = Sanguosha->translate(":tenyearyanzhu2");
        room->changeTranslation(effect.from, "tenyearyanzhu", translate);
        QString translate2 = Sanguosha->translate(":tenyearxingxue2");
        room->changeTranslation(effect.from, "tenyearxingxue", translate2);
    } else
        room->addPlayerMark(effect.to, "&tenyearyanzhu");
}

class TenyearYanzhuVS : public ZeroCardViewAsSkill
{
public:
    TenyearYanzhuVS() : ZeroCardViewAsSkill("tenyearyanzhu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearYanzhuCard");
    }

    const Card *viewAs() const
    {
        return new TenyearYanzhuCard;
    }
};

class TenyearYanzhu : public TriggerSkill
{
public:
    TenyearYanzhu() : TriggerSkill("tenyearyanzhu")
    {
        events << EventPhaseChanging << DamageInflicted;
        view_as_skill = new TenyearYanzhuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive() && target->getMark("&tenyearyanzhu") > 0;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::RoundStart) return false;
            room->setPlayerMark(player, "&tenyearyanzhu", 0);
        } else {
            LogMessage log;
            log.type = "#TenyearyanzhuDamage";
            log.from = player;
            log.arg = objectName();
            log.arg2 = QString::number(player->getMark("&tenyearyanzhu"));
            room->sendLog(log);

            DamageStruct damage = data.value<DamageStruct>();
            damage.damage += player->getMark("&tenyearyanzhu");
            data = QVariant::fromValue(damage);
            room->setPlayerMark(player, "&tenyearyanzhu", 0);
        }
        return false;
    }
};

TenyearXingxueCard::TenyearXingxueCard()
{
}

bool TenyearXingxueCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    int n = Self->property("tenyearxingxue_level_up").toBool() ? Self->getMaxHp() : Self->getHp();

    return targets.length() < n;
}

void TenyearXingxueCard::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const
{
    room->drawCards(targets, 1, "tenyearxingxue");

    foreach (ServerPlayer *p, targets) {
        if (p->isDead() || p->getHandcardNum() <= p->getHp()) continue;
        const Card *c = room->askForExchange(p, "tenyearxingxue", 1, 1, true, "@tenyearxingxue-put");
        int id = c->getSubcards().first();
        delete c;
        CardsMoveStruct m(id, NULL, Player::DrawPile, CardMoveReason(CardMoveReason::S_REASON_PUT, p->objectName()));
        room->setPlayerFlag(p, "Global_GongxinOperator");
        room->moveCardsAtomic(m, false);
        room->setPlayerFlag(p, "-Global_GongxinOperator");
    }
}

class TenyearXingxueVS : public ZeroCardViewAsSkill
{
public:
    TenyearXingxueVS() : ZeroCardViewAsSkill("tenyearxingxue")
    {
        response_pattern = "@@tenyearxingxue";
    }

    const Card *viewAs() const
    {
        return new TenyearXingxueCard;
    }
};

class TenyearXingxue : public PhaseChangeSkill
{
public:
    TenyearXingxue() : PhaseChangeSkill("tenyearxingxue")
    {
        view_as_skill = new TenyearXingxueVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return PhaseChangeSkill::triggerable(target) && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        int n = target->property("tenyearxingxue_level_up").toBool() ? target->getMaxHp() : target->getHp();
        if (n <= 0) return false;
        target->getRoom()->askForUseCard(target, "@@tenyearxingxue", "@tenyearxingxue:" + QString::number(n));
        return false;
    }
};

class TenyearQingxi : public TriggerSkill
{
public:
    TenyearQingxi() : TriggerSkill("tenyearqingxi")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") && !use.card->isKindOf("Duel")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead()) return false;
            if (p->isDead()) continue;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
            room->broadcastSkillInvoke(objectName());
            if (p->isDead()) continue;
            int n = 0;
            foreach (ServerPlayer *d, room->getOtherPlayers(player)) {
                if (player->inMyAttackRange(d))
                    n++;
            }
            int min = player->getWeapon() ? 4 : 2;
            n = qMin(n, min);

            if (n <= 0 || player->isDead()) {
                room->setCardFlag(use.card, "tenyearqingxi_" + p->objectName());
                JudgeStruct judge;
                judge.who = p;
                judge.reason = objectName();
                judge.pattern = ".|red";
                judge.good = false;
                room->judge(judge);

                if (judge.isBad())
                    use.no_respond_list << p->objectName();
            } else {
                if (!room->askForDiscard(p, objectName(), n, n, true, false, "@tenyearqingxi-discard:" + QString::number(n))) {
                    room->setCardFlag(use.card, "tenyearqingxi_" + p->objectName());
                    JudgeStruct judge;
                    judge.who = p;
                    judge.reason = objectName();
                    judge.pattern = ".|red";
                    judge.good = false;
                    room->judge(judge);

                    if (judge.isBad())
                        use.no_respond_list << p->objectName();
                } else {
                    if (p->isDead() || !player->getWeapon() || !p->canDiscard(player, player->getWeapon()->getEffectiveId())) continue;
                    room->throwCard(player->getWeapon(), player, p);
                }
            }
        }
        data = QVariant::fromValue(use);
        return false;
    }
};

class TenyearQingxiDamage : public TriggerSkill
{
public:
    TenyearQingxiDamage() : TriggerSkill("#tenyearqingxi-damage")
    {
        events << DamageInflicted;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card) return false;
        if (!damage.card->hasFlag("tenyearqingxi_" + player->objectName())) return false;
        //room->setCardFlag(damage.card, "-tenyearqingxi_" + player->objectName());
        ++damage.damage;
        data = QVariant::fromValue(damage);
        return false;
    }
};

class TenyearDuodao : public TriggerSkill
{
public:
    TenyearDuodao() : TriggerSkill("tenyearduodao")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || !use.to.contains(player) || !player->canDiscard(player, "he")) return false;
        if (!room->askForCard(player, "..", "@tenyearduodao:" + use.from->objectName(), data, objectName())) return false;
        room->broadcastSkillInvoke(objectName());
        if (!use.from || use.from->isDead() || !use.from->getWeapon()) return false;
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
        room->obtainCard(player, use.from->getWeapon(), reason);
        return false;
    }
};

class TenyearAnjian : public TriggerSkill
{
public:
    TenyearAnjian() : TriggerSkill("tenyearanjian")
    {
        events << TargetSpecified << CardFinished << DamageCaused;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            //damage.damage += damage.card->tag["Tenyearanjian_Damage"].toInt();
            damage.damage += room->getTag("Tenyearanjian_Damage" + damage.card->toString()).toInt();
            data = QVariant::fromValue(damage);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            if (event == TargetSpecified) {
                foreach (ServerPlayer *p, use.to) {
                    if (p->inMyAttackRange(player)) continue;
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    p->addQinggangTag(use.card);
                    room->setCardFlag(use.card, "tenyearanjian_" + p->objectName());
                    //int damage = use.card->tag["Tenyearanjian_Damage"].toInt();
                    //use.card->tag["Tenyearanjian_Damage"] = ++damage;
                    int damage = room->getTag("Tenyearanjian_Damage" + use.card->toString()).toInt();
                    room->setTag("Tenyearanjian_Damage" + use.card->toString(), ++damage);
                }
            } else
                room->removeTag("Tenyearanjian_Damage" + use.card->toString());
        }
        return false;
    }
};

class TenyearAnjianEffect : public TriggerSkill
{
public:
    TenyearAnjianEffect() : TriggerSkill("#tenyearanjian-effect")
    {
        events << Dying << AskForPeachesDone;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who != player) return false;
            if (!dying.damage || !dying.damage->card || !dying.damage->card->isKindOf("Slash")) return false;
            if (!dying.damage->card->hasFlag("tenyearanjian_" + player->objectName())) return false;
            player->tag["TenyearanjianForbidden"] = true;
            room->setPlayerCardLimitation(player, "use", "Peach", false);
        } else {
            if (!player->tag["TenyearanjianForbidden"].toBool()) return false;
            player->tag.remove("TenyearanjianForbidden");
            room->removePlayerCardLimitation(player, "use", "Peach$0");
        }
        return false;
    }
};

TenyearShenduanCard::TenyearShenduanCard()
{
    will_throw = false;
    handling_method = Card::MethodUse;
}

bool TenyearShenduanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *cc = Sanguosha->getCard(getSubcards().first());
    SupplyShortage *ss = new SupplyShortage(cc->getSuit(), cc->getNumber());
    ss->addSubcard(cc);
    ss->setSkillName("tenyearshenduan");
    ss->deleteLater();
    return ss->targetFilter(targets, to_select, Self) && !Self->isCardLimited(ss, Card::MethodUse) && !Self->isProhibited(to_select, ss)
            && to_select->hasJudgeArea();
}

void TenyearShenduanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setPlayerFlag(card_use.to.first(), "tenyearshenduan_target");
}

class TenyearShenduanVS : public OneCardViewAsSkill
{
public:
    TenyearShenduanVS() : OneCardViewAsSkill("tenyearshenduan")
    {
        response_pattern = "@@tenyearshenduan";
        expand_pile = "#tenyearshenduan";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return Self->getPile("#tenyearshenduan").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *card) const
    {
        TenyearShenduanCard *c = new TenyearShenduanCard;
        c->addSubcard(card);
        return c;
    }
};

class TenyearShenduan : public TriggerSkill
{
public:
    TenyearShenduan() : TriggerSkill("tenyearshenduan")
    {
        events << CardsMoveOneTime;
        view_as_skill = new TenyearShenduanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (Sanguosha->getBanPackages().contains("maneuvering")) return false;

        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player) return false;
        if (move.to_place == Player::DiscardPile
            && ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)) {
            QList<int> shenduan_card;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip) {
                    if (room->getCardPlace(move.card_ids.at(i)) == Player::DiscardPile) {
                        const Card *c = Sanguosha->getCard(move.card_ids.at(i));
                        if (c->isBlack() && (c->isKindOf("BasicCard") || c->isKindOf("EquipCard")))
                            shenduan_card << move.card_ids.at(i);
                    }
                }
            }
            if (shenduan_card.isEmpty()) return false;

            try {
                while (!shenduan_card.isEmpty()) {
                    room->notifyMoveToPile(player, shenduan_card, objectName(), Player::DiscardPile, true);

                    const Card *c = room->askForUseCard(player, "@@tenyearshenduan", "@tenyearshenduan");
                    if (!c) break;

                    room->notifyMoveToPile(player, shenduan_card, objectName(), Player::DiscardPile, false);

                    int id = c->getSubcards().first();
                    shenduan_card.removeOne(id);

                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("tenyearshenduan_target")) {
                            room->setPlayerFlag(p, "-tenyearshenduan_target");
                            const Card *cc = Sanguosha->getCard(id);
                            SupplyShortage *ss = new SupplyShortage(cc->getSuit(), cc->getNumber());
                            ss->addSubcard(cc);
                            ss->setSkillName("tenyearshenduan");
                            ss->deleteLater();
                            room->useCard(CardUseStruct(ss, player, p));
                            break;
                        }
                    }
                    if (player->isDead()) break;
                }
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                    if (!shenduan_card.isEmpty())
                        room->notifyMoveToPile(player, shenduan_card, objectName(), Player::DiscardPile, false);
                }
                throw triggerEvent;
            }
            if (!shenduan_card.isEmpty())
                room->notifyMoveToPile(player, shenduan_card, objectName(), Player::DiscardPile, false);
        }
        return false;
    }
};

class TenyearShenduanTargetMod : public TargetModSkill
{
public:
    TenyearShenduanTargetMod() : TargetModSkill("#tenyearshenduan-target")
    {
        frequency = NotFrequent;
        pattern = "SupplyShortage";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->getSkillName() == "tenyearshenduan")
            return 1000;
        else
            return 0;
    }
};

class TenyearYonglve : public PhaseChangeSkill
{
public:
    TenyearYonglve() : PhaseChangeSkill("tenyearyonglve")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && !target->getJudgingArea().isEmpty() && target->getPhase() == Player::Judge;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
            if (target->isDead() || target->getJudgingArea().isEmpty()) return false;
            if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(target, "j")) continue;
            QString prompt = "tenyearyonglve_out:" + target->objectName();
            if (p->inMyAttackRange(target))
                prompt = "tenyearyonglve_in:" + target->objectName();
            if (!p->askForSkillInvoke(this, prompt)) continue;
            room->broadcastSkillInvoke(objectName());
            int id = room->askForCardChosen(p, target, "j", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, NULL, p);
            if (p->isDead()) continue;
            if (p->inMyAttackRange(target))
                p->drawCards(1, objectName());
            else {
                Slash *slash = new Slash(Card::NoSuit, 0);
                slash->setSkillName("_tenyearyonglve");
                slash->deleteLater();
                if (!p->canSlash(target, slash, false)) continue;
                room->useCard(CardUseStruct(slash, p, target));
            }
        }
        return false;
    }
};

TenyearQiaoshuiCard::TenyearQiaoshuiCard()
{
}

bool TenyearQiaoshuiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void TenyearQiaoshuiCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;
    Room *room = effect.from->getRoom();
    if (effect.from->pindian(effect.to, "tenyearqiaoshui"))
        room->addPlayerMark(effect.from, "&tenyearqiaoshui-Clear");
    else {
        effect.from->endPlayPhase();
        room->addPlayerMark(effect.from, "tenyearqiaoshui_lose-Clear");
    }
}

TenyearQiaoshuiTargetCard::TenyearQiaoshuiTargetCard()
{
    mute = true;
}

bool TenyearQiaoshuiTargetCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < Self->getMark("tenyearqiaoshui_max_target-Clear") && to_select->hasFlag("tenyearqiaoshui_canchoose");
}

void TenyearQiaoshuiTargetCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setPlayerMark(card_use.from, "tenyearqiaoshui_max_target-Clear", 0);
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "tenyearqiaoshui_choose_target");
}

class TenyearQiaoshuiVS : public ZeroCardViewAsSkill
{
public:
    TenyearQiaoshuiVS() : ZeroCardViewAsSkill("tenyearqiaoshui")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canPindian();
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@tenyearqiaoshui");
    }

    const Card *viewAs() const
    {
        if (Self->hasFlag("tenyearqiaoshui_now_use_collateral"))
            return new ExtraCollateralCard;
        else {
            if (Sanguosha->currentRoomState()->getCurrentCardUsePattern().startsWith("@@tenyearqiaoshui"))
                return new TenyearQiaoshuiTargetCard;
            return new TenyearQiaoshuiCard;
        }
    }
};

class TenyearQiaoshui : public TriggerSkill
{
public:
    TenyearQiaoshui() : TriggerSkill("tenyearqiaoshui")
    {
        events << PreCardUsed << PreCardResponded << EventPhaseProceeding;
        view_as_skill = new TenyearQiaoshuiVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseProceeding) {
            if (player->getPhase() != Player::Discard) return false;
            if (player->getMark("tenyearqiaoshui_lose-Clear") <= 0) return false;
            QList<int> ids;
            foreach (const Card *c, player->getCards("h")) {
                if (!c->isKindOf("TrickCard")) continue;
                ids << c->getEffectiveId();
            }
            if (ids.isEmpty()) return false;
            room->ignoreCards(player, ids);
            return false;
        }
        const Card *card = NULL;
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            card = use.card;
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse) return false;
            card = res.m_card;
        }
        if (card == NULL || (!card->isKindOf("BasicCard") && !card->isNDTrick())) return false;

        int n = player->getMark("&tenyearqiaoshui-Clear");
        if (n <= 0) return false;
        room->setPlayerMark(player, "&tenyearqiaoshui-Clear", 0);
        room->setPlayerMark(player, "tenyearqiaoshui_max_target-Clear", n);

        if (event == PreCardResponded || card->isKindOf("Nullification")) return false;
        room->setCardFlag(card, "tenyearqiaoshui_distance");

        CardUseStruct use = data.value<CardUseStruct>();
        bool canextra = false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (use.card->isKindOf("AOE") && p == player) continue;
            if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
            if (use.card->targetFixed()) {
                if (!use.card->isKindOf("Peach") || p->getLostHp() > 0) {
                    canextra = true;
                    break;
                }
            } else {
                if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                    canextra = true;
                    break;
                }
            }
        }
        room->setCardFlag(use.card, "-tenyearqiaoshui_distance");

        QStringList choices;
        if (canextra)
            choices << "add";
        if (use.to.length() > 1)
            choices << "remove";
        if (choices.isEmpty()) return false;
        choices << "cancel";
        QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
        if (choice == "cancel") return false;

        if (choice == "add") {
            if (!card->isKindOf("Collateral")) {
                room->setCardFlag(use.card, "tenyearqiaoshui_distance");
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (use.card->isKindOf("AOE") && p == player) continue;
                    if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                    if (use.card->targetFixed()) {
                        if (!use.card->isKindOf("Peach") || p->getLostHp() > 0)
                            room->setPlayerFlag(p, "tenyearqiaoshui_canchoose");
                    } else {
                        if (use.card->targetFilter(QList<const Player *>(), p, player))
                            room->setPlayerFlag(p, "tenyearqiaoshui_canchoose");
                    }
                }
                room->setCardFlag(use.card, "-tenyearqiaoshui_distance");
                if (!room->askForUseCard(player, "@@tenyearqiaoshui1", "@tenyearqiaoshui1:" + use.card->objectName(), 1)) return false;
                QList<ServerPlayer *> add;
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("tenyearqiaoshui_canchoose"))
                        room->setPlayerFlag(p, "-tenyearqiaoshui_canchoose");
                    if (p->hasFlag("tenyearqiaoshui_choose_target")) {
                        room->setPlayerFlag(p,"-tenyearqiaoshui_choose_target");
                        use.to.append(p);
                        add << p;
                    }
                }
                if (add.isEmpty()) return false;
                room->sortByActionOrder(add);
                LogMessage log;
                log.type = "#QiaoshuiAdd";
                log.from = player;
                log.to = add;
                log.card_str = use.card->toString();
                log.arg = "tenyearqiaoshui";
                room->sendLog(log);
                foreach(ServerPlayer *p, add)
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
            } else {
                for (int i = 1; i <= n; i++) {
                    bool canextra = false;
                    room->setCardFlag(use.card, "tenyearqiaoshui_distance");
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                        if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                            canextra = true;
                            break;
                        }
                    }
                    if (canextra == false) {
                        room->setCardFlag(use.card, "-tenyearqiaoshui_distance");
                        break;
                    }
                    QStringList toss;
                    QString tos;
                    foreach(ServerPlayer *t, use.to)
                        toss.append(t->objectName());
                    tos = toss.join("+");
                    room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", tos);
                    room->setPlayerFlag(player, "tenyearqiaoshui_now_use_collateral");

                    const Card *card = room->askForUseCard(player, "@@tenyearqiaoshui1", "@tenyearqiaoshui1:" + use.card->objectName(), 1);

                    room->setPlayerFlag(player, "-tenyearqiaoshui_now_use_collateral");
                    room->setPlayerProperty(player, "extra_collateral", QString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", QString());
                    room->setCardFlag(use.card, "-tenyearqiaoshui_distance");

                    if (!card) break;

                    foreach(ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("ExtraCollateralTarget")) {
                            room->setPlayerFlag(p,"-ExtraCollateralTarget");
                            LogMessage log;
                            log.type = "#QiaoshuiAdd";
                            log.from = player;
                            log.to << p;
                            log.card_str = use.card->toString();
                            log.arg = "tenyearqiaoshui";
                            room->sendLog(log);
                            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                            use.to.append(p);
                            ServerPlayer *victim = p->tag["collateralVictim"].value<ServerPlayer *>();
                            Q_ASSERT(victim != NULL);
                            if (victim) {
                                LogMessage log;
                                log.type = "#CollateralSlash";
                                log.from = player;
                                log.to << victim;
                                room->sendLog(log);
                                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, p->objectName(), victim->objectName());
                            }
                        }
                    }
                    room->sortByActionOrder(use.to);
                    data = QVariant::fromValue(use);
                }
            }
        } else {
            foreach (ServerPlayer *p, use.to)
                room->setPlayerFlag(p, "tenyearqiaoshui_canchoose");
            if (!room->askForUseCard(player, "@@tenyearqiaoshui2", "@tenyearqiaoshui2:" + use.card->objectName(), 2)) return false;
            QList<ServerPlayer *> removes;
            foreach (ServerPlayer *p, use.to) {
                if (p->hasFlag("tenyearqiaoshui_choose_target")) {
                    room->setPlayerFlag(p, "-tenyearqiaoshui_choose_target");
                    removes << p;
                }
            }
            if (removes.isEmpty()) return false;
            room->sortByActionOrder(removes);
            LogMessage log;
            log.type = "#QiaoshuiRemove";
            log.from = player;
            log.to = removes;
            log.card_str = use.card->toString();
            log.arg = "tenyearqiaoshui";
            room->sendLog(log);
            foreach (ServerPlayer *p, removes) {
                room->doAnimate(1, player->objectName(), p->objectName());
                use.to.removeOne(p);
            }
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class TenyearQiaoshuiTargetMod : public TargetModSkill
{
public:
    TenyearQiaoshuiTargetMod() : TargetModSkill("#tenyearqiaoshui-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("tenyearqiaoshui_distance") && (card->isKindOf("BasicCard") || card->isNDTrick()))
            return 1000;
        else
            return 0;
    }
};

class TenyearAocaiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    TenyearAocaiViewAsSkill() : ZeroCardViewAsSkill("tenyearaocai")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->getPhase() != Player::NotActive || player->hasFlag("Global_TenyearAocaiFailed")) return false;
        if (pattern.contains("slash") || pattern.contains("Slash"))
            return Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE;
        else if (pattern == "peach")
            return player->getMark("Global_PreventPeach") == 0;
        else if (pattern.contains("analeptic"))
            return true;
        return false;
    }

    const Card *viewAs() const
    {
        TenyearAocaiCard *aocai_card = new TenyearAocaiCard;
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "peach+analeptic" && Self->getMark("Global_PreventPeach") > 0)
            pattern = "analeptic";
        aocai_card->setUserString(pattern);
        return aocai_card;
    }
};

class TenyearAocai : public TriggerSkill
{
public:
    TenyearAocai() : TriggerSkill("tenyearaocai")
    {
        events << CardAsked;
        view_as_skill = new TenyearAocaiViewAsSkill;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QString pattern = data.toStringList().first();
        if (player->getPhase() == Player::NotActive
            && (pattern.contains("slash") || pattern.contains("Slash") || pattern == "jink")
            && room->askForSkillInvoke(player, objectName(), data)) {
            int num = 2;
            if (player->isKongcheng())
                num = 4;
            QList<int> ids = room->getNCards(num, false);
            QList<int> enabled, disabled;
            foreach (int id, ids) {
                if (Sanguosha->getCard(id)->objectName().contains(pattern))
                    enabled << id;
                else
                    disabled << id;
            }
            int id = TenyearAocai::view(room, player, ids, enabled, disabled);
            if (id != -1) {
                const Card *card = Sanguosha->getCard(id);
                room->provide(card);
                return true;
            }
        }
        return false;
    }

    static int view(Room *room, ServerPlayer *player, QList<int> &ids, QList<int> &enabled, QList<int> &disabled)
    {
        int result = -1, index = -1;
        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(ids).join("+");
        room->sendLog(log, player);

        room->broadcastSkillInvoke("tenyearaocai");
        room->notifySkillInvoked(player, "tenyearaocai");
        if (enabled.isEmpty()) {
            JsonArray arg;
            arg << "." << false << JsonUtils::toJsonArray(ids);
            room->doNotify(player, QSanProtocol::S_COMMAND_SHOW_ALL_CARDS, arg);
        } else {
            room->fillAG(ids, player, disabled);
            int id = room->askForAG(player, enabled, true, "tenyearaocai");
            if (id != -1) {
                index = ids.indexOf(id);
                ids.removeOne(id);
                result = id;
            }
            room->clearAG(player);
        }

        QList<int> &drawPile = room->getDrawPile();
        for (int i = ids.length() - 1; i >= 0; i--)
            drawPile.prepend(ids.at(i));
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, QVariant(drawPile.length()));
        if (result == -1)
            room->setPlayerFlag(player, "Global_TenyearAocaiFailed");
        else {
            LogMessage log;
            log.type = "#AocaiUse";
            log.from = player;
            log.arg = "tenyearaocai";
            log.arg2 = QString("CAPITAL(%1)").arg(index + 1);
            room->sendLog(log);
        }
        return result;
    }
};

TenyearAocaiCard::TenyearAocaiCard()
{
}

bool TenyearAocaiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool TenyearAocaiCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
        return true;

    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetFixed();
}

bool TenyearAocaiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetsFeasible(targets, Self);
}

const Card *TenyearAocaiCard::validateInResponse(ServerPlayer *user) const
{
    Room *room = user->getRoom();
    int num = 2;
    if (user->isKongcheng())
        num = 4;
    QList<int> ids = room->getNCards(num, false);
    QStringList names = user_string.split("+");
    if (names.contains("slash")) names << "fire_slash" << "thunder_slash";

    QList<int> enabled, disabled;
    foreach (int id, ids) {
        if (names.contains(Sanguosha->getCard(id)->objectName()))
            enabled << id;
        else
            disabled << id;
    }

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = user;
    log.arg = "tenyearaocai";
    room->sendLog(log);

    int id = TenyearAocai::view(room, user, ids, enabled, disabled);
    return Sanguosha->getCard(id);
}

const Card *TenyearAocaiCard::validate(CardUseStruct &cardUse) const
{
    cardUse.m_isOwnerUse = false;
    ServerPlayer *user = cardUse.from;
    Room *room = user->getRoom();
    int num = 2;
    if (user->isKongcheng())
        num = 4;
    QList<int> ids = room->getNCards(num, false);
    QStringList names = user_string.split("+");
    if (names.contains("slash")) names << "fire_slash" << "thunder_slash";

    QList<int> enabled, disabled;
    foreach (int id, ids) {
        if (names.contains(Sanguosha->getCard(id)->objectName()))
            enabled << id;
        else
            disabled << id;
    }

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = user;
    log.arg = "tenyearaocai";
    room->sendLog(log);

    int id = TenyearAocai::view(room, user, ids, enabled, disabled);
    return Sanguosha->getCard(id);
}

TenyearDuwuCard::TenyearDuwuCard()
{
    mute = true;
}

bool TenyearDuwuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || qMax(0, to_select->getHp()) != subcardsLength())
        return false;

    if (Self->getWeapon() && subcards.contains(Self->getWeapon()->getId())) {
        const Weapon *weapon = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
        int distance_fix = weapon->getRange() - Self->getAttackRange(false);
        if (Self->getOffensiveHorse() && subcards.contains(Self->getOffensiveHorse()->getId()))
            distance_fix += 1;
        return Self->inMyAttackRange(to_select, distance_fix);
    } else if (Self->getOffensiveHorse() && subcards.contains(Self->getOffensiveHorse()->getId())) {
        return Self->inMyAttackRange(to_select, 1);
    } else
        return Self->inMyAttackRange(to_select);
}

void TenyearDuwuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    if (subcards.length() <= 1)
        room->broadcastSkillInvoke("tenyearduwu", 2);
    else
        room->broadcastSkillInvoke("tenyearduwu", 1);

    room->damage(DamageStruct("tenyearduwu", effect.from, effect.to));
}

class TenyearDuwuViewAsSkill : public ViewAsSkill
{
public:
    TenyearDuwuViewAsSkill() : ViewAsSkill("tenyearduwu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasFlag("TenyearDuwuEnterDying");
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        TenyearDuwuCard *duwu = new TenyearDuwuCard;
        if (!cards.isEmpty())
            duwu->addSubcards(cards);
        return duwu;
    }
};

class TenyearDuwu : public TriggerSkill
{
public:
    TenyearDuwu() : TriggerSkill("tenyearduwu")
    {
        events << QuitDying;
        view_as_skill = new TenyearDuwuViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.damage && dying.damage->getReason() == "tenyearduwu" && !dying.damage->chain && !dying.damage->transfer) {
            ServerPlayer *from = dying.damage->from;
            if (from && from->isAlive()) {
                room->setPlayerFlag(from, "TenyearDuwuEnterDying");
                room->loseHp(from, 1);
            }
        }
        return false;
    }
};

class TenyearDanlao : public TriggerSkill
{
public:
    TenyearDanlao() : TriggerSkill("tenyeardanlao")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.length() <= 1 || !use.to.contains(player)
            || (!use.card->isKindOf("TrickCard") && !use.card->isKindOf("Slash"))
            || !room->askForSkillInvoke(player, objectName(), data))
            return false;

        room->broadcastSkillInvoke(objectName());
        player->setFlags("-TenyearDanlaoTarget");
        player->setFlags("TenyearDanlaoTarget");
        player->drawCards(1, objectName());
        if (player->isAlive() && player->hasFlag("TenyearDanlaoTarget")) {
            player->setFlags("-TenyearDanlaoTarget");
            use.nullified_list << player->objectName();
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class TenyearJilei : public TriggerSkill
{
public:
    TenyearJilei() : TriggerSkill("tenyearjilei")
    {
        events << Damaged;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *yangxiu, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->isDead()) return false;

        if (room->askForSkillInvoke(yangxiu, objectName(), data)) {
            QString choice = room->askForChoice(yangxiu, objectName(), "BasicCard+EquipCard+TrickCard");
            room->broadcastSkillInvoke(objectName());

            LogMessage log;
            log.type = "#Jilei";
            log.from = damage.from;
            log.arg = choice;
            room->sendLog(log);

            QStringList jilei_list = damage.from->tag[objectName()].toStringList();
            if (jilei_list.contains(choice)) return false;
            jilei_list.append(choice);
            damage.from->tag[objectName()] = QVariant::fromValue(jilei_list);
            QString _type = choice + "|.|.|hand"; // Handcards only
            room->setPlayerCardLimitation(damage.from, "use,response,discard", _type, false);

            if (damage.from->getMark("&tenyearjilei+" + choice) == 0)
                room->setPlayerMark(damage.from, "&tenyearjilei+" + choice, 1);
        }
        return false;
    }
};

class TenyearJileiClear : public TriggerSkill
{
public:
    TenyearJileiClear() : TriggerSkill("#tenyearjilei-clear")
    {
        events << EventPhaseChanging << Death;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *target, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::RoundStart) return false;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != target) return false;
        }
        QStringList jilei_list = target->tag["tenyearjilei"].toStringList();
        if (!jilei_list.isEmpty()) {
            LogMessage log;
            log.type = "#JileiClear";
            log.from = target;
            room->sendLog(log);

            foreach (QString jilei_type, jilei_list) {
                room->removePlayerCardLimitation(target, "use,response,discard", jilei_type + "|.|.|hand$0");
                room->setPlayerMark(target, "&tenyearjilei+" + jilei_type, 0);
            }
            target->tag.remove("tenyearjilei");
        }
        return false;
    }
};

TenyearXianzhenCard::TenyearXianzhenCard()
{
    m_skillName = "tenyearxianzhen";
}

bool TenyearXianzhenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void TenyearXianzhenCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.from, m_skillName + "_Used-Clear");

    if (effect.from->pindian(effect.to, m_skillName, NULL)) {
        room->addPlayerMark(effect.to, "Armor_Nullified");
        room->addPlayerMark(effect.from, m_skillName + "_from-Clear");
        room->addPlayerMark(effect.to, m_skillName + "_to-Clear");
    } else {
        room->setPlayerCardLimitation(effect.from, "use", "Slash", true);
        room->addPlayerMark(effect.from, m_skillName + "_slash-Clear");
    }
}

SecondTenyearXianzhenCard::SecondTenyearXianzhenCard() : TenyearXianzhenCard()
{
    m_skillName = "secondtenyearxianzhen";
}

class TenyearXianzhenViewAsSkill : public ZeroCardViewAsSkill
{
public:
    TenyearXianzhenViewAsSkill(const QString &xianzhen) : ZeroCardViewAsSkill(xianzhen), xianzhen(xianzhen)
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (xianzhen == "tenyearxianzhen")
            return !player->hasUsed("TenyearXianzhenCard") && player->canPindian();
        else if (xianzhen == "secondtenyearxianzhen")
            return player->getMark("secondtenyearxianzhen_Used-Clear") <= 0 && player->canPindian();
        return false;
    }

    const Card *viewAs() const
    {
        if (xianzhen == "tenyearxianzhen")
            return new TenyearXianzhenCard;
        else if (xianzhen == "secondtenyearxianzhen")
            return new SecondTenyearXianzhenCard;
        return NULL;
    }
private:
    QString xianzhen;
};

class TenyearXianzhen : public TriggerSkill
{
public:
    TenyearXianzhen(const QString &xianzhen) : TriggerSkill(xianzhen), xianzhen(xianzhen)
    {
        events << EventPhaseChanging << Death << CardUsed << DamageCaused;
        view_as_skill = new TenyearXianzhenViewAsSkill(xianzhen);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getMark(xianzhen + "_from-Clear") > 0;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *gaoshun, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                if (p->getMark(xianzhen + "_to-Clear") <= 0) continue;
                room->removePlayerMark(p, "Armor_Nullified");
            }
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->getMark(xianzhen + "_to-Clear") <= 0) return false;
            room->removePlayerMark(death.who, "Armor_Nullified");
        } else if (triggerEvent == DamageCaused) {
            if (gaoshun->isDead() || xianzhen != "secondtenyearxianzhen") return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || damage.to->isDead() || damage.to->getMark("secondtenyearxianzhen_to-Clear") <= 0) return false;
            QString name = damage.card->objectName();
            if (damage.card->isKindOf("Slash"))
                name = "slash";
            if (gaoshun->getMark("secondtenyearxianzhen_" + name + "_" + damage.to->objectName() + "-Clear") > 0) return false;
            LogMessage log;
            log.type = "#YHHankaiDamage";
            log.from = gaoshun;
            log.to << damage.to;
            log.arg = objectName();
            log.arg2 = QString::number(damage.damage);
            log.arg3 = QString::number(damage.damage += 1);
            room->sendLog(log);
            room->notifySkillInvoked(gaoshun, objectName());
            data = QVariant::fromValue(damage);
            room->addPlayerMark(gaoshun, "secondtenyearxianzhen_" + name + "_" + damage.to->objectName() + "-Clear");
        } else {
            if (gaoshun->isDead() || xianzhen != "tenyearxianzhen") return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.to.length() != 1 || use.card->isKindOf("Collateral")) return false;
            if (use.card->isKindOf("Slash") || use.card->isNDTrick()) {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *target, room->getAlivePlayers()) {
                    if (target->isDead() || target->getMark("tenyearxianzhen_to-Clear") <= 0) continue;
                    if (!use.card->isKindOf("AOE") && !use.card->isKindOf("GlobalEffect")) {
                        if (use.to.contains(target) || room->isProhibited(gaoshun, target, use.card)) continue;
                        if (use.card->targetFixed()) {
                            if (!use.card->isKindOf("Peach") || target->isWounded())
                                targets << target;
                        } else {
                            if (use.card->targetFilter(QList<const Player *>(), target, gaoshun))
                                targets << target;
                        }
                    }
                }
                if (targets.isEmpty()) return false;
                while (!targets.isEmpty()) {
                    if (gaoshun->isDead()) break;
                    ServerPlayer *target = room->askForPlayerChosen(gaoshun, targets, objectName(),
                                  "@tenyearxianzhen-target:" + use.card->objectName(), true);
                    if (!target) break;
                    LogMessage log;
                    log.type = "#QiaoshuiAdd";
                    log.from = gaoshun;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = objectName();
                    room->sendLog(log);
                    room->doAnimate(1, gaoshun->objectName(), target->objectName());
                    use.to << target;
                    targets.removeOne(target);
                }
                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
            }
        }
        return false;
    }
private:
    QString xianzhen;
};

class TenyearXianzhenSlash : public TriggerSkill
{
public:
    TenyearXianzhenSlash(const QString &xianzhen) : TriggerSkill("#" + xianzhen + "-slash"), xianzhen(xianzhen)
    {
        events << EventPhaseProceeding;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark(xianzhen + "_slash-Clear") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *gaoshun, QVariant &) const
    {
        if (gaoshun->getPhase() != Player::Discard) return false;
        foreach (const Card *card, gaoshun->getHandcards()) {
            if (card->isKindOf("Slash"))
                room->ignoreCards(gaoshun, card);
        }
        return false;
    }
private:
    QString xianzhen;
};

class TenyearXianzhenTargetMod : public TargetModSkill
{
public:
    TenyearXianzhenTargetMod(const QString &xianzhen) : TargetModSkill("#" + xianzhen + "-target"), xianzhen(xianzhen)
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark(xianzhen + "_from-Clear") > 0 && to && to->getMark(xianzhen + "_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark(xianzhen + "_from-Clear") > 0 && to && to->getMark(xianzhen + "_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }
private:
    QString xianzhen;
};

class SecondTenyearJinjiu : public FilterSkill
{
public:
    SecondTenyearJinjiu() : FilterSkill("secondtenyearjinjiu")
    {
    }

    bool viewFilter(const Card *to_select) const
    {
        return to_select->objectName() == "analeptic";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Slash *slash = new Slash(originalCard->getSuit(), 13);
        slash->setSkillName(objectName());
        WrappedCard *card = Sanguosha->getWrappedCard(originalCard->getId());
        card->takeOver(slash);
        return card;
    }
};

class SecondTenyearJinjiuLimit : public CardLimitSkill
{
public:
    SecondTenyearJinjiuLimit() : CardLimitSkill("#secondtenyearjinjiu-limit")
    {
    }

    bool gaoshun(const Player *target) const
    {
        QList<const Player *> as = target->getAliveSiblings();
        as << target;
        foreach (const Player *p, as) {
            if (p->hasSkill("secondtenyearjinjiu") && p->getPhase() != Player::NotActive)
                return true;
        }
        return false;
    }

    QString limitList(const Player *target) const
    {
        if (gaoshun(target) && target->getPhase() == Player::NotActive)
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (gaoshun(target) && target->getPhase() == Player::NotActive)
            return "Analeptic";
        else
            return QString();
    }
};

class Tenyearbiluan : public DistanceSkill
{
public:
    Tenyearbiluan() : DistanceSkill("tenyearbiluan")
    {
        frequency = NotFrequent;
    }

    int getCorrect(const Player *, const Player *to) const
    {
        if (to->hasSkill(this))
            return to->property("tenyearbiluan_distance").toInt();
        return 0;
    }
};

class TenyearbiluanTrigger : public PhaseChangeSkill
{
public:
    TenyearbiluanTrigger() : PhaseChangeSkill("#tenyearbiluan-trigger")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (!player->hasSkill("tenyearbiluan") || player->getPhase() != Player::Finish || !player->canDiscard(player, "he")) return false;
        bool can_invoke = false;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->distanceTo(player) == 1) {
                can_invoke = true;
                break;
            }
        }
        if (!can_invoke) return false;
        if (!room->askForCard(player, "..", "@tenyearbiluan-discard", QVariant(), "tenyearbiluan")) return false;
        room->broadcastSkillInvoke("tenyearbiluan");
        //int distance = qMin(4, room->alivePlayerCount());
        //room->addDistance(player, distance, false, false);
        int distance = player->property("tenyearbiluan_distance").toInt();
        distance += qMin(4, room->alivePlayerCount());
        room->setPlayerProperty(player, "tenyearbiluan_distance", distance);
        return false;
    }
};

class TenyearLixia : public DistanceSkill
{
public:
    TenyearLixia() : DistanceSkill("tenyearlixia")
    {
    }

    int getCorrect(const Player *, const Player *to) const
    {
        if (to->hasSkill(this))
            return -to->property("tenyearlixia_distance").toInt();
        return 0;
    }
};

class TenyearLixiaTrigger : public PhaseChangeSkill
{
public:
    TenyearLixiaTrigger() : PhaseChangeSkill("#tenyearlixia-trigger")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isAlive() && p->hasSkill("tenyearlixia")) {
                if (player->inMyAttackRange(p)) continue;
                room->sendCompulsoryTriggerLog(p, "tenyearlixia", true, true);
                QString choice = room->askForChoice(p, "tenyearlixia", "self+other", QVariant::fromValue(player));
                if (choice == "self")
                    p->drawCards(1, "tenyearlixia");
                else
                    player->drawCards(2, "tenyearlixia");
                int distance = p->property("tenyearlixia_distance").toInt();
                distance++;
                room->setPlayerProperty(p, "tenyearlixia_distance", distance);
            }
        }
        return false;
    }
};

TenyearZishouCard::TenyearZishouCard()
{
    target_fixed = true;
}

void TenyearZishouCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(subcardsLength(), "tenyearzishou");
}

class TenyearZishouVS : public ViewAsSkill
{
public:
    TenyearZishouVS() : ViewAsSkill("tenyearzishou")
    {
        response_pattern = "@@tenyearzishou";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Self->isJilei(to_select) || to_select->isEquipped()) return false;
        foreach (const Card *c, selected) {
            if (to_select->getSuit() == c->getSuit())
                return false;
        }
        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        TenyearZishouCard *c = new TenyearZishouCard;
        c->addSubcards(cards);
        return c;
    }
};

class TenyearZishou : public TriggerSkill
{
public:
    TenyearZishou() : TriggerSkill("tenyearzishou")
    {
        events << DrawNCards << DamageCaused << EventPhaseStart;
        view_as_skill = new TenyearZishouVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DrawNCards) {
            if (!player->hasSkill(this)) return false;
            QSet<QString> kingdomSet;
            foreach(ServerPlayer *p, room->getAlivePlayers())
                kingdomSet.insert(p->getKingdom());

            int n = kingdomSet.count();
            if (!player->askForSkillInvoke(this, QString("tenyearzishou:" + QString::number(n)))) return false;
            room->broadcastSkillInvoke(objectName());
            room->setPlayerFlag(player, "tenyearzishou");
            data = data.toInt() + n;
        } else if (event == DamageCaused) {
            if (!player->hasFlag(objectName())) return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to->isAlive() && damage.to != player) {
                LogMessage log;
                log.type = "#OLzishouPrevent";
                log.from = player;
                log.to << damage.to;
                log.arg = objectName();
                log.arg2 = QString::number(damage.damage);
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                return true;
            }
        } else {
            if (!player->hasFlag(objectName()) || player->getPhase() != Player::Finish) return false;
            if (player->getMark("qieting") > 0 || !player->canDiscard(player, "h")) return false;
            room->askForUseCard(player, "@@tenyearzishou", "@tenyearzishou", -1, Card::MethodDiscard);
        }
        return false;
    }
};

class TenyearZongshi : public MaxCardsSkill
{
public:
    TenyearZongshi() : MaxCardsSkill("tenyearzongshi")
    {
    }

    int getExtra(const Player *target) const
    {
        int extra = 0;
        QSet<QString> kingdom_set;
        if (target->parent()) {
            foreach(const Player *player, target->parent()->findChildren<const Player *>())
            {
                if (player->isAlive())
                    kingdom_set << player->getKingdom();
            }
        }
        extra = kingdom_set.size();
        if (target->hasSkill(this))
            return extra;
        else
            return 0;
    }
};

class TenyearZongshiProtect : public TriggerSkill
{
public:
    TenyearZongshiProtect() : TriggerSkill("#tenyearzongshi-protect")
    {
        events << CardEffected;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->hasSkill("tenyearzongshi") && target->getHandcardNum() >= target->getMaxCards();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardEffectStruct effect = data.value<CardEffectStruct>();
        if (effect.card->isKindOf("SkillCard")) return false;
        if (effect.card->isKindOf("DelayedTrick") || (!effect.card->isBlack() && !effect.card->isRed())) {
            room->broadcastSkillInvoke("tenyearzongshi");
            room->notifySkillInvoked(effect.to, "tenyearzongshi");
            LogMessage log;
            log.type = "#TenyearzongshiAvoid";
            log.from = effect.to;
            log.arg = "tenyearzongshi";
            log.card_str = effect.card->toString();
            room->sendLog(log);
            return true;
        }
        return false;
    }
};

class TenyearXuanfeng : public TriggerSkill
{
public:
    TenyearXuanfeng() : TriggerSkill("tenyearxuanfeng")
    {
        events << CardsMoveOneTime << EventPhaseEnd << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    void perform(Room *room, ServerPlayer *lingtong) const
    {
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *target, room->getOtherPlayers(lingtong)) {
            if (lingtong->canDiscard(target, "he"))
                targets << target;
        }
        if (targets.isEmpty())
            return;

        if (lingtong->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName());

            ServerPlayer *first = room->askForPlayerChosen(lingtong, targets, "tenyearxuanfeng");
            room->doAnimate(1, lingtong->objectName(), first->objectName());
            ServerPlayer *second = NULL;
            int first_id = -1;
            int second_id = -1;
            if (first != NULL) {
                first_id = room->askForCardChosen(lingtong, first, "he", "tenyearxuanfeng", false, Card::MethodDiscard);
                room->throwCard(first_id, first, lingtong);
            }
            if (!lingtong->isAlive())
                return;
            targets.clear();
            foreach (ServerPlayer *target, room->getOtherPlayers(lingtong)) {
                if (lingtong->canDiscard(target, "he"))
                    targets << target;
            }
            if (!targets.isEmpty()) {
                second = room->askForPlayerChosen(lingtong, targets, "tenyearxuanfeng");
                room->doAnimate(1, lingtong->objectName(), second->objectName());
            }
            if (second != NULL) {
                second_id = room->askForCardChosen(lingtong, second, "he", "tenyearxuanfeng", false, Card::MethodDiscard);
                room->throwCard(second_id, second, lingtong);
            }
            if (lingtong->isDead() || lingtong->getPhase() == Player::NotActive) return;
            QList<ServerPlayer *> victims;
            if (first->isAlive())
                victims << first;
            if (second != NULL && second->isAlive() && second != first)
                victims << second;
            if (victims.isEmpty()) return;
            ServerPlayer *victim = room->askForPlayerChosen(lingtong, victims, "tenyearxuanfeng_damage", "@tenyearxuanfeng-invoke", true);
            if (!victim) return;
            room->doAnimate(1, lingtong->objectName(), victim->objectName());
            room->damage(DamageStruct("tenyearxuanfeng", lingtong, victim));
        }
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *lingtong, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            lingtong->setMark("tenyearxuanfeng", 0);
        } else if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from != lingtong)
                return false;

            if (lingtong->getPhase() == Player::Discard
                && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)
                lingtong->addMark("tenyearxuanfeng", move.card_ids.length());

            if (move.from_places.contains(Player::PlaceEquip) && TriggerSkill::triggerable(lingtong))
                perform(room, lingtong);
        } else if (triggerEvent == EventPhaseEnd && TriggerSkill::triggerable(lingtong)
            && lingtong->getPhase() == Player::Discard && lingtong->getMark("tenyearxuanfeng") >= 2) {
            perform(room, lingtong);
        }

        return false;
    }
};

TenyearyongjinCard::TenyearyongjinCard()
{
    target_fixed = true;
}

void TenyearyongjinCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->doSuperLightbox("tenyear_lingtong", "tenyearyongjin");
    room->removePlayerMark(source, "@tenyearyongjinMark");

    for (int i = 1; i <= 3; i++) {
        if (source->isDead()) return;
        bool flag = true;
        if (i == 1)
            flag = false;
        room->moveField(source, "tenyearyongjin", flag, "e");
    }
}

class Tenyearyongjin : public ZeroCardViewAsSkill
{
public:
    Tenyearyongjin() : ZeroCardViewAsSkill("tenyearyongjin")
    {
        frequency = Limited;
        limit_mark = "@tenyearyongjinMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("@tenyearyongjinMark") <= 0) return false;
        QList<const Player *> as = player->getAliveSiblings();
        as << player;
        foreach (const Player *p, as) {
            if (!p->getEquips().isEmpty())
                return true;
        }
        return false;
    }

    const Card *viewAs() const
    {
        return new TenyearyongjinCard;
    }
};


class TenyearEnyuan : public TriggerSkill
{
public:
    TenyearEnyuan() : TriggerSkill("tenyearenyuan")
    {
        events << CardsMoveOneTime << Damaged;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to == player && move.from && move.from->isAlive() && move.from != move.to && move.card_ids.size() >= 2 && move.reason.m_reason != CardMoveReason::S_REASON_PREVIEWGIVE
                    && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip)) {
                move.from->setFlags("TenyearEnyuanDrawTarget");
                bool invoke = room->askForSkillInvoke(player, objectName(), data);
                move.from->setFlags("-TenyearEnyuanDrawTarget");
                if (invoke) {
                    room->broadcastSkillInvoke(objectName());
                    room->drawCards((ServerPlayer *)move.from, 1, objectName());
                }
            }
        } else if (triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            ServerPlayer *source = damage.from;
            if (!source || source == player) return false;
            int x = damage.damage;
            for (int i = 0; i < x; i++) {
                if (source->isAlive() && player->isAlive() && room->askForSkillInvoke(player, objectName(), data)) {
                    room->broadcastSkillInvoke(objectName());
                    const Card *card = NULL;
                    if (!source->isKongcheng()) {
                        source->tag["tenyearenyuan_data"] = data;
                        card = room->askForExchange(source, objectName(), 1, 1, false, "EnyuanGive::" + player->objectName(), true);
                        source->tag.remove("tenyearenyuan_data");
                    }
                    if (card) {
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(),
                            player->objectName(), objectName(), QString());
                        reason.m_playerId = player->objectName();
                        room->moveCardTo(card, source, player, Player::PlaceHand, reason, true);
                        if (card->getSuit() != Card::Heart)
                            player->drawCards(1, objectName());
                        delete card;
                    } else {
                        room->loseHp(source);
                    }
                } else {
                    break;
                }
            }
        }
        return false;
    }
};

TenyearXuanhuoCard::TenyearXuanhuoCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void TenyearXuanhuoCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    CardMoveReason r(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "tenyearxuanhuo", QString());
    room->obtainCard(effect.to, this, r, false);

    if (effect.from->isDead()) return;
    QList<int> ava = room->getAvailableCardList(effect.to, "basic,trick", "tenyearxuanhuo");

    QStringList names;
    foreach (int id, ava) {
        const Card *card = Sanguosha->getEngineCard(id);
        if ((card->isKindOf("Slash") || card->isKindOf("Duel")) && !names.contains(card->objectName()))
            names << card->objectName();
    }

    DummyCard *handcards = effect.to->wholeHandCards();
    handcards->deleteLater();

    if (names.isEmpty() || room->alivePlayerCount() <= 2) {
        if (!effect.to->isKongcheng()) {
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), effect.from->objectName(), "tenyearxuanhuo", QString());
            room->obtainCard(effect.from, handcards, reason, false);
        }
    } else {
        QList<ServerPlayer *> targets;
        QList<ServerPlayer *> all_targets = room->getOtherPlayers(effect.to);
        if (all_targets.contains(effect.from))
            all_targets.removeOne(effect.from);
        foreach (QString name, names) {
            Card *card = Sanguosha->cloneCard(name);
            card->setSkillName("_tenyearxuanhuo");
            card->deleteLater();
            foreach (ServerPlayer *p, all_targets) {
                QList<ServerPlayer *> player_list;
                player_list << p;
                if (effect.to->canUse(card, player_list) && !targets.contains(p))
                    targets << p;
            }
        }
        if (targets.isEmpty()) {
            if (!effect.to->isKongcheng()) {
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), effect.from->objectName(), "tenyearxuanhuo", QString());
                room->obtainCard(effect.from, handcards, reason, false);
            }
        } else {
            if (room->askForChoice(effect.to, "tenyearxuanhuo", "use+give", QVariant::fromValue(effect.from)) == "give") {
                if (!effect.to->isKongcheng()) {
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), effect.from->objectName(), "tenyearxuanhuo", QString());
                    room->obtainCard(effect.from, handcards, reason, false);
                }
            } else {
                effect.from->tag["tenyearxuanhuo_target"] = QVariant::fromValue(effect.to);
                ServerPlayer *target = room->askForPlayerChosen(effect.from, targets, "tenyearxuanhuo", "@tenyearxuanhuo-target:" + effect.to->objectName());
                effect.from->tag.remove("tenyearxuanhuo_target");

                LogMessage log;
                log.type = "#TenyearxuanhuoTarget";
                log.from = effect.from;
                log.to << target;
                log.arg = "tenyearxuanhuo";
                room->sendLog(log);
                room->doAnimate(1, effect.from->objectName(), target->objectName());

                QStringList choices;
                foreach (QString name, names) {
                    Card *card = Sanguosha->cloneCard(name);
                    card->setSkillName("_tenyearxuanhuo");
                    card->deleteLater();
                    QList<ServerPlayer *> player_list;
                    player_list << target;
                    if (effect.to->canUse(card, player_list))
                        choices << name;
                }
                if (choices.isEmpty()) {
                    if (!effect.to->isKongcheng()) {
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), effect.from->objectName(), "tenyearxuanhuo", QString());
                        room->obtainCard(effect.from, handcards, reason, false);
                    }
                } else {
                    QString choice = room->askForChoice(effect.to, "tenyearxuanhuo", choices.join("+"));
                    Card *card = Sanguosha->cloneCard(choice);
                    card->setSkillName("_tenyearxuanhuo");
                    card->deleteLater();
                    room->useCard(CardUseStruct(card, effect.to, target));
                }
            }
        }
    }
}

class TenyearXuanhuoVS : public ViewAsSkill
{
public:
    TenyearXuanhuoVS() : ViewAsSkill("tenyearxuanhuo")
    {
        response_pattern = "@@tenyearxuanhuo";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const {
        return selected.length() < 2 && !to_select->isEquipped();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2)
            return NULL;

        TenyearXuanhuoCard *c = new TenyearXuanhuoCard;
        c->addSubcards(cards);
        return c;
    }
};

class TenyearXuanhuo : public TriggerSkill
{
public:
    TenyearXuanhuo() : TriggerSkill("tenyearxuanhuo")
    {
        events << EventPhaseEnd;
        view_as_skill = new TenyearXuanhuoVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Draw) return false;
        if (player->getHandcardNum() < 2 || room->alivePlayerCount() < 3) return false;
        room->askForUseCard(player, "@@tenyearxuanhuo", "@tenyearxuanhuo");
        return false;
    }
};

class TenyearZhuikong : public TriggerSkill
{
public:
    TenyearZhuikong() : TriggerSkill("tenyearzhuikong")
    {
        events << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::RoundStart)
            return false;

        foreach (ServerPlayer *fuhuanghou, room->getOtherPlayers(player)) {
            if (TriggerSkill::triggerable(fuhuanghou)
                && fuhuanghou->isWounded() && fuhuanghou->canPindian(player)
                && fuhuanghou->askForSkillInvoke(objectName(), player)) {
                room->broadcastSkillInvoke(objectName());
                PindianStruct *pindian = fuhuanghou->PinDian(player, objectName());
                if (pindian->success) {
                    room->setPlayerFlag(player, "tenyearzhuikong");
                } else {
                    int to_card_id = pindian->to_card->getEffectiveId();
                    if (room->getCardPlace(to_card_id) != Player::DiscardPile) return false;
                    room->obtainCard(fuhuanghou, to_card_id);
                    Slash *slash = new Slash(Card::NoSuit, 0);
                    slash->setSkillName("_tenyearzhuikong");
                    slash->deleteLater();
                    if (!player->canSlash(fuhuanghou, slash, false)) return false;
                    room->useCard(CardUseStruct(slash, player, fuhuanghou));
                }
            }
        }
        return false;
    }
};

class TenyearZhuikongProhibit : public ProhibitSkill
{
public:
    TenyearZhuikongProhibit() : ProhibitSkill("#tenyearzhuikong")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (card->getTypeId() != Card::TypeSkill && from->hasFlag("tenyearzhuikong"))
            return to != from;
        return false;
    }
};

class TenyearQiuyuan : public TriggerSkill
{
public:
    TenyearQiuyuan() : TriggerSkill("tenyearqiuyuan")
    {
        events << TargetConfirming;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        QList<ServerPlayer *> targets = room->getOtherPlayers(player);
        if (targets.contains(use.from))
            targets.removeOne(use.from);
        if (targets.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@tenyearqiuyuan-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());

        const Card *card = NULL;
        if (!target->isKongcheng()) {
            target->tag["tenyearqiuyuan_from"] = QVariant::fromValue(player);
            card = room->askForCard(target, "BasicCard+^Slash", "@tenyearqiuyuan-give:" + player->objectName(), data, Card::MethodNone);
            target->tag.remove("tenyearqiuyuan_from");
        }
        if (!card) {
            if (!use.from->canSlash(target, use.card, false)) return false;
            LogMessage log;
            log.type = "#BecomeTarget";
            log.from = target;
            log.card_str = use.card->toString();
            room->sendLog(log);
            use.to.append(target);
            room->sortByActionOrder(use.to);
            use.no_respond_list << target->objectName();
            data = QVariant::fromValue(use);
        } else {
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "tenyearqiuyuan", QString());
            room->obtainCard(player, card, reason);
        }
        return false;
    }
};


TenyearSidiCard::TenyearSidiCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void TenyearSidiCard::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "tenyearsidi", QString());
    room->throwCard(this, reason, NULL);
}

class TenyearSidiVS : public OneCardViewAsSkill
{
public:
    TenyearSidiVS() : OneCardViewAsSkill("tenyearsidi")
    {
        expand_pile = "sidi";
        filter_pattern = ".|.|.|sidi";
        response_pattern = "@@tenyearsidi";
    }

    const Card *viewAs(const Card *card) const
    {
        TenyearSidiCard *c = new TenyearSidiCard;
        c->addSubcard(card);
        return c;
    }
};

class TenyearSidi : public TriggerSkill
{
public:
    TenyearSidi() : TriggerSkill("tenyearsidi")
    {
        events << EventPhaseStart << EventPhaseEnd << Death;
        view_as_skill = new TenyearSidiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseEnd)
            return 0;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->isDead()) return false;
            if (player->hasSkill(this) && !player->isNude() && player->getPhase() == Player::Finish) {
                const Card *card = room->askForCard(player, "^BasicCard", "@tenyearsidi-put", data, Card::MethodNone, NULL, false, objectName());
                if (!card) return false;
                room->broadcastSkillInvoke(objectName());
                player->addToPile("sidi", card);
            }
            if (player->getPhase() == Player::Play) {
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (p->isDead() || !p->hasSkill(this) || p->getPile("sidi").isEmpty()) continue;
                    const Card *card = room->askForUseCard(p, "@@tenyearsidi", "@tenyearsidi:" + player->objectName(), -1, Card::MethodNone);
                    if (!card) continue;

                    QStringList victims = p->tag["tenyearsidi_victims"].toStringList();
                    if (!victims.contains(player->objectName())) {
                        victims << player->objectName();
                        p->tag["tenyearsidi_victims"] = victims;
                    }

                    const Card *c = Sanguosha->getCard(card->getSubcards().first());
                    QString color;
                    if (c->isRed())
                        color = "red";
                    else if (c->isBlack())
                        color = "black";
                    else
                        continue;

                    room->addPlayerMark(player, "&tenyearsidi+" + color + "-Clear");
                    QStringList limit_colors = player->tag["tenyearsidi_color"].toStringList();
                    if (!limit_colors.contains(color)) {
                        limit_colors << color;
                        player->tag["tenyearsidi_color"] = limit_colors;
                    }

                    room->setPlayerCardLimitation(player, "use,response", ".|" + color, true);
                }
            }
        } else {
            if (event == EventPhaseEnd && player->getPhase() != Player::Play) return false;
            if (event == Death) {
                DeathStruct death = data.value<DeathStruct>();
                if (death.who != player || !room->hasCurrent() || player != room->getCurrent())
                    return false;
            }
            QStringList limit_colors = player->tag["tenyearsidi_color"].toStringList();
            if (limit_colors.isEmpty()) return false;
            player->tag.remove("tenyearsidi_color");
            foreach (QString color, limit_colors)
                room->removePlayerCardLimitation(player, "use,response", QString(".|%1").arg(color));
        }
        return false;
    }
};

class TenyearSidiEffect : public TriggerSkill
{
public:
    TenyearSidiEffect() : TriggerSkill("#tenyearsidi-effect")
    {
        events << PreCardUsed << EventPhaseEnd;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            if (player->isDead()) return false;
            const Card *card = data.value<CardUseStruct>().card;
            if (!card->isKindOf("TrickCard")) return false;
            room->addPlayerMark(player, "tenyearsidi_trick-PlayClear");
        } else {
            if (player->getPhase() != Player::Play) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead() || !p->hasSkill("tenyearsidi")) continue;
                QStringList victims = p->tag["tenyearsidi_victims"].toStringList();
                if (!victims.contains(player->objectName())) continue;
                p->tag.remove("tenyearsidi_victims");

                bool send = false;
                if (player->getMark("newsidi_slash-PlayClear") <= 0) {
                    Slash *slash = new Slash(Card::NoSuit, 0);
                    slash->setSkillName("_tenyearsidi");
                    slash->deleteLater();
                    if (!p->canSlash(player, slash, false)) continue;
                    room->sendCompulsoryTriggerLog(p, "tenyearsidi", true);
                    send = true;
                    room->useCard(CardUseStruct(slash, p, player));
                }
                if (player->getMark("tenyearsidi_trick-PlayClear") <= 0) {
                    if (p->isDead()) continue;
                    if (!send)
                        room->sendCompulsoryTriggerLog(p, "tenyearsidi", true);
                    p->drawCards(2, "tenyearsidi");
                }
            }
        }
        return false;
    }
};

TenyearHuaiyiCard::TenyearHuaiyiCard()
{
    target_fixed = true;
}

void TenyearHuaiyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isKongcheng()) return;
    room->showAllCards(source);

    QList<int> blacks;
    QList<int> reds;
    foreach (const Card *c, source->getHandcards()) {
        if (c->isRed())
            reds << c->getId();
        else
            blacks << c->getId();
    }

    if (reds.isEmpty() || blacks.isEmpty()) {
        source->drawCards(1, "tenyearhuaiyi");
        room->addPlayerMark(source, "tenyearhuaiyi-PlayClear");
        return;
    }

    QString to_discard = room->askForChoice(source, "tenyearhuaiyi", "black+red");
    QList<int> *pile = NULL;
    if (to_discard == "black")
        pile = &blacks;
    else
        pile = &reds;

    int n = pile->length();

    room->setPlayerMark(source, "tenyearhuaiyi_num-PlayClear", n);

    DummyCard dm(*pile);
    room->throwCard(&dm, source);

    room->askForUseCard(source, "@@tenyearhuaiyi", "@tenyearhuaiyi:" + QString::number(n), -1, Card::MethodNone);
}

TenyearHuaiyiSnatchCard::TenyearHuaiyiSnatchCard()
{
    handling_method = Card::MethodNone;
    m_skillName = "tenyearhuaiyi";
}

bool TenyearHuaiyiSnatchCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int n = Self->getMark("tenyearhuaiyi_num-PlayClear");
    if (targets.length() >= n)
        return false;

    if (to_select == Self)
        return false;

    if (to_select->isNude())
        return false;

    return true;
}

void TenyearHuaiyiSnatchCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;

    QList<ServerPlayer *> to = card_use.to;

    room->sortByActionOrder(to);

    int get = 0;
    foreach (ServerPlayer *p, to) {
        if (player->isDead()) return;
        if (p->isDead() || p->isNude()) continue;
        int id = room->askForCardChosen(player, p, "he", "tenyearhuaiyi");
        player->obtainCard(Sanguosha->getCard(id), false);
        get++;
    }

    if (get >= 2)
        room->loseHp(player);
}

class TenyearHuaiyi : public ZeroCardViewAsSkill
{
public:
    TenyearHuaiyi() : ZeroCardViewAsSkill("tenyearhuaiyi")
    {

    }

    const Card *viewAs() const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@tenyearhuaiyi")
            return new TenyearHuaiyiSnatchCard;
        else
            return new TenyearHuaiyiCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->isKongcheng()) return false;
        if (player->getMark("tenyearhuaiyi-PlayClear") <= 0)
            return !player->hasUsed("TenyearHuaiyiCard");
        return player->usedTimes("TenyearHuaiyiCard") < 2;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearhuaiyi";
    }
};

class Tenyearjueqing : public TriggerSkill
{
public:
    Tenyearjueqing() : TriggerSkill("tenyearjueqing")
    {
        events << DamageCaused << Predamage;
    }

    Frequency getFrequency(const Player *target) const
    {
        if (target != NULL) {
            return target->getMark("tenyearjueqing") <= 0 ? NotFrequent : Compulsory;
        }
        return Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (event == DamageCaused) {
            if (player->getMark(objectName()) > 0) return false;
            if (damage.to->isDead()) return false;
            player->tag["tenyearjueqing_data"] = data;
            if (!player->askForSkillInvoke(objectName(), damage.to)) {
                player->tag.remove("tenyearjueqing_data");
                return false;
            };
            player->tag.remove("tenyearjueqing_data");
            room->broadcastSkillInvoke(objectName());
            room->loseHp(player, damage.damage);
            damage.damage = 2 * damage.damage;
            damage.tips << "tenyearjueqing_" + damage.to->objectName();
            data = QVariant::fromValue(damage);
        } else {
            if (player->getMark(objectName()) <= 0) return false;
            if (damage.to->isDead()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->loseHp(damage.to, damage.damage, damage.ignore_hujia);
            return true;
        }
        return false;
    }
};

class TenyearjueqingComplete : public TriggerSkill
{
public:
    TenyearjueqingComplete() : TriggerSkill("#tenyearjueqing")
    {
        events << DamageComplete;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->isDead() || !damage.from->hasSkill("tenyearjueqing", true) ||
                !damage.tips.contains("tenyearjueqing_" + damage.to->objectName()) || damage.from->getMark("tenyearjueqing") > 0) return false;
        room->setPlayerMark(damage.from, "tenyearjueqing", 1);
        QString translate = Sanguosha->translate(":tenyearjueqing2");
        room->changeTranslation(damage.from, "tenyearjueqing", translate);
        room->doNotify(damage.from, QSanProtocol::S_COMMAND_UPDATE_SKILL, QVariant("tenyearjueqing"));
        return false;
    }
};

TenyearGongqiCard::TenyearGongqiCard()
{
    target_fixed = true;
    handling_method = Card::MethodDiscard;
}

void TenyearGongqiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->setPlayerFlag(source, "InfinityAttackRange");
    const Card *cd = Sanguosha->getCard(subcards.first());
    room->setPlayerMark(source, "tenyeargongqi_slash_" + cd->getSuitString() + "-Clear", 1);
    if (cd->isKindOf("EquipCard")) {
        QList<ServerPlayer *> targets;
        foreach(ServerPlayer *p, room->getOtherPlayers(source))
            if (source->canDiscard(p, "he")) targets << p;
        if (!targets.isEmpty()) {
            ServerPlayer *to_discard = room->askForPlayerChosen(source, targets, "tenyeargongqi", "@gongqi-discard", true);
            if (to_discard)
                room->throwCard(room->askForCardChosen(source, to_discard, "he", "tenyeargongqi", false, Card::MethodDiscard),
                                to_discard, source);
        }
    }
}

class TenyearGongqi : public OneCardViewAsSkill
{
public:
    TenyearGongqi() : OneCardViewAsSkill("tenyeargongqi")
    {
        filter_pattern = ".!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearGongqiCard");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        TenyearGongqiCard *card = new TenyearGongqiCard;
        card->addSubcard(originalcard->getId());
        card->setSkillName(objectName());
        return card;
    }
};

class TenyearGongqiTargetMod : public TargetModSkill
{
public:
    TenyearGongqiTargetMod() : TargetModSkill("#tenyeargongqi-target")
    {
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (from->getMark("tenyeargongqi_slash_" + card->getSuitString() + "-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

TenyearJiefanCard::TenyearJiefanCard()
{
}

bool TenyearJiefanCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void TenyearJiefanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (room->getTag("TurnLengthCount").toInt() == 1)
        room->addPlayerMark(source, "tenyearjiefan_reflash-Clear");

    room->removePlayerMark(source, "@tenyearjiefanMark");
    ServerPlayer *target = targets.first();
    source->tag["TenyearJiefanTarget"] = QVariant::fromValue(target);
    room->doSuperLightbox("tenyear_handang", "tenyearjiefan");

    foreach (ServerPlayer *player, room->getAllPlayers()) {
        if (player->isAlive() && player->inMyAttackRange(target))
            room->cardEffect(this, source, player);
    }
    source->tag.remove("TenyearJiefanTarget");
}

void TenyearJiefanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    ServerPlayer *target = effect.from->tag["TenyearJiefanTarget"].value<ServerPlayer *>();
    QVariant data = effect.from->tag["TenyearJiefanTarget"];
    if (target && !room->askForCard(effect.to, ".Weapon", "@jiefan-discard::" + target->objectName(), data))
        target->drawCards(1, "tenyearjiefan");
}

class TenyearJiefanVS : public ZeroCardViewAsSkill
{
public:
    TenyearJiefanVS() : ZeroCardViewAsSkill("tenyearjiefan")
    {
        frequency = Limited;
        limit_mark = "@tenyearjiefanMark";
    }

    const Card *viewAs() const
    {
        return new TenyearJiefanCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@tenyearjiefanMark") >= 1;
    }
};

class TenyearJiefan : public TriggerSkill
{
public:
    TenyearJiefan() : TriggerSkill("tenyearjiefan")
    {
        events << EventPhaseChanging;
        frequency = Limited;
        limit_mark = "@tenyearjiefanMark";
        view_as_skill = new TenyearJiefanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        if (player->getMark("tenyearjiefan_reflash-Clear") <= 0) return false;
        //if (player->getMark("@tenyearjiefanMark") > 0) return false;
        room->addPlayerMark(player, "@tenyearjiefanMark");
        return false;
    }
};

class TenyearZhongyong : public TriggerSkill
{
public:
    TenyearZhongyong() : TriggerSkill("tenyearzhongyong")
    {
        events << SlashMissed << CardFinished;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == SlashMissed) {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            QVariantList slash = player->tag["tenyearzhongyong_slash" + effect.slash->toString()].toList();
            if (effect.slash->isVirtualCard() && effect.slash->subcardsLength() > 0) {
                foreach (int id, effect.slash->getSubcards()) {
                    if (slash.contains(QVariant(id))) continue;
                    slash << id;
                }
            } else if (!effect.slash->isVirtualCard()) {
                if (!slash.contains(QVariant(effect.slash->getEffectiveId())))
                    slash << effect.slash->getEffectiveId();
            }
            player->tag["tenyearzhongyong_slash" + effect.slash->toString()] = slash;

            if (!effect.jink) return false;
            QVariantList jink = player->tag["tenyearzhongyong_jink" + effect.slash->toString()].toList();
            if (effect.jink->isVirtualCard() && effect.jink->subcardsLength() > 0) {
                foreach (int id, effect.jink->getSubcards()) {
                    if (jink.contains(QVariant(id))) continue;
                    jink << id;
                }
            } else if (!effect.jink->isVirtualCard()) {
                if (!jink.contains(QVariant(effect.jink->getEffectiveId())))
                    jink << effect.jink->getEffectiveId();
            }
            player->tag["tenyearzhongyong_jink" + effect.slash->toString()] = jink;
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;

            QVariantList slash = player->tag["tenyearzhongyong_slash" + use.card->toString()].toList();
            QVariantList jink = player->tag["tenyearzhongyong_jink" + use.card->toString()].toList();
            QList<int> slash_ids = VariantList2IntList(slash);
            QList<int> jink_ids = VariantList2IntList(jink);

            foreach (int id, slash_ids) {
                if (room->getCardPlace(id) != Player::DiscardPile)
                    slash_ids.removeOne(id);
            }
            foreach (int id, jink_ids) {
                if (room->getCardPlace(id) != Player::DiscardPile)
                    jink_ids.removeOne(id);
            }

            QList<int> give_list = slash_ids + jink_ids;
            if (give_list.isEmpty()) return false;

            room->fillAG(give_list, player);
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@tenyearzhongyong-invoke",
                                   true, true);
            room->clearAG(player);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());

            room->giveCard(player, target, give_list, objectName(), true);

            if (target->isDead()) return false;
            bool red = false, black = false;
            foreach (int id, give_list) {
                const Card *card = Sanguosha->getCard(id);
                if (card->isRed())
                    red = true;
                else if (card->isBlack())
                    black = true;
                if (red && black)
                    break;
            }

            if (red) {
                QList<ServerPlayer *> tos;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (player->inMyAttackRange(p) && target->canSlash(p, NULL, true))
                        tos << p;
                }
                if (!tos.isEmpty())
                    room->askForUseSlashTo(target, tos, "@newzhongyong-slash");
            }

            if (black && target->isAlive())
                target->drawCards(1, objectName());
        }
        return false;
    }
};

class TenyearJigong : public PhaseChangeSkill
{
public:
    TenyearJigong() : PhaseChangeSkill("tenyearjigong")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play || !player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());

        QString choice = room->askForChoice(player, objectName(), "1+2+3");
        int num = choice.toInt();

        room->setPlayerMark(player, "tenyearjigong_maxcards-Clear", num);
        player->drawCards(num, objectName());
        return false;
    }
};

class TenyearJigongMax : public MaxCardsSkill
{
public:
    TenyearJigongMax() : MaxCardsSkill("#tenyearjigong")
    {
    }

    int getFixed(const Player *target) const
    {
        if (target->getMark("tenyearjigong_maxcards-Clear") > 0)
            return target->getMark("damage_point_play_phase");

        return -1;
    }
};

class TenyearJigongRecover : public PhaseChangeSkill
{
public:
    TenyearJigongRecover() : PhaseChangeSkill("#tenyearjigong-recover")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        if (target == NULL || !target->isAlive()) return false;
        int draw = target->getMark("tenyearjigong_maxcards-Clear");
        int damage = target->getMark("damage_point_play_phase");
        return damage >= draw && draw > 0 && target->getPhase() == Player::Discard && target->isWounded();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, "tenyearjigong", true, true);
        room->recover(player, RecoverStruct(player));
        return false;
    }
};

class TenyearJiezhong : public PhaseChangeSkill
{
public:
    TenyearJiezhong() : PhaseChangeSkill("tenyearjiezhong")
    {
        frequency = Limited;
        limit_mark = "@tenyearjiezhongMark";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->hasSkill(this) && target->getMark("@tenyearjiezhongMark") > 0 &&
                target->getPhase() == Player::Play;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke("tenyearjiezhong");
        room->doSuperLightbox("tenyear_guanping", "tenyearjiezhong");
        room->removePlayerMark(player, "@tenyearjiezhongMark");
        player->drawCards(player->getMaxHp() - player->getHandcardNum(), objectName());
        return false;
    }
};

class TenyearLongyin : public TriggerSkill
{
public:
    TenyearLongyin() : TriggerSkill("tenyearlongyin")
    {
        events << CardUsed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Play;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash")) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "he")) continue;
                const Card *card = room->askForCard(p, "..", "@tenyearlongyin:" + use.from->objectName(), data, objectName());
                if (!card) continue;
                room->broadcastSkillInvoke(objectName());
                if (use.m_addHistory) {
                    room->addPlayerHistory(player, use.card->getClassName(), -1);
                    use.m_addHistory = false;
                    data = QVariant::fromValue(use);
                }
                if (use.card->isRed())
                    p->drawCards(1, objectName());
                if (card->getNumber() == use.card->getNumber() && p->hasSkill("tenyearjiezhong", true) &&
                        p->getMark("@tenyearjiezhongMark") <= 0) {
                    LogMessage log;
                    log.type = "#TenyearLongyinReset";
                    log.from = p;
                    log.arg = objectName();
                    log.arg2 = "tenyearjiezhong";
                    room->sendLog(log);
                    room->addPlayerMark(p, "@tenyearjiezhongMark");
                }
            }
        }
        return false;
    }
};

class TenyearQieting : public TriggerSkill
{
public:
    TenyearQieting() : TriggerSkill("tenyearqieting")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            QList<int> disable_ids;
            for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
                if (player->getEquip(i) && (p->getEquip(i) || !p->hasEquipArea(i)))
                    disable_ids << player->getEquip(i)->getEffectiveId();
            }
            if (player->getEquips().length() > disable_ids.length() && p->askForSkillInvoke(this, "move:" + player->objectName())) {
                room->broadcastSkillInvoke(this);
                int id = room->askForCardChosen(p, player, "e", objectName(), false, Card::MethodNone, disable_ids);
                if (id >= 0) {
                    const Card *card = Sanguosha->getCard(id);
                    room->moveCardTo(card, p, Player::PlaceEquip);
                }
            }
            if (player->getMark("qieting") <= 0 && p->isAlive() && p->hasSkill(this)) {
                room->sendCompulsoryTriggerLog(p, this);
                p->drawCards(1, objectName());
            }
        }
        return false;
    }
};

TenyearXianzhouDamageCard::TenyearXianzhouDamageCard()
{
    mute = true;
    m_skillName = "tenyearxianzhou";
}

void TenyearXianzhouDamageCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    //room->sortByActionOrder(card_use.to);
    CardUseStruct use = card_use;
    room->sortByActionOrder(use.to);
    foreach (ServerPlayer *p, use.to)
        room->damage(DamageStruct("tenyearxianzhou", use.from->isAlive() ? use.from : NULL, p));
}

bool TenyearXianzhouDamageCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QString name = Self->property("tenyearxianzhou_target").toString();
    if (name.isEmpty()) return false;
    //const Player *target = Self->findChild<const Player *>(name);

    const Player *target = NULL;
    QList<const Player *> as = Self->getAliveSiblings();
    as << Self;
    foreach (const Player *p, as) {
        if (p->objectName() == name) {
            target = p;
            break;
        }
    }

    if (!target) return false;
    return targets.length() < Self->getMark("tenyearxianzhou") && target->inMyAttackRange(to_select);
}

TenyearXianzhouCard::TenyearXianzhouCard()
{
}

bool TenyearXianzhouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void TenyearXianzhouCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->removePlayerMark(effect.from, "@tenyearxianzhouMark");
    room->doSuperLightbox("tenyear_caifuren", "tenyearxianzhou");

    DummyCard *dummy = new DummyCard(effect.from->getEquipsId());
    int len = dummy->subcardsLength();
    room->setPlayerMark(effect.from, "tenyearxianzhou", len);
    effect.to->obtainCard(dummy);
    delete dummy;

    room->recover(effect.from, RecoverStruct(effect.from, NULL, qMin(len, effect.from->getMaxHp() - effect.from->getHp())));
    if (effect.from->isDead() || effect.to->isDead()) return;
    bool attack = false;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (effect.to->inMyAttackRange(p)) {
            attack = true;
            break;
        }
    }
    if (!attack) return;

    room->setPlayerProperty(effect.from, "tenyearxianzhou_target", effect.to->objectName());
    room->askForUseCard(effect.from, "@@tenyearxianzhou", "@tenyearxianzhou:" + effect.to->objectName() + "::" + QString::number(len));
}

class TenyearXianzhou : public ZeroCardViewAsSkill
{
public:
    TenyearXianzhou() : ZeroCardViewAsSkill("tenyearxianzhou")
    {
        frequency = Skill::Limited;
        limit_mark = "@tenyearxianzhouMark";
        response_pattern = "@@tenyearxianzhou";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@tenyearxianzhouMark") > 0 && player->getEquips().length() > 0;
    }

    const Card *viewAs() const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@tenyearxianzhou") {
            return new TenyearXianzhouDamageCard;
        } else {
            return new TenyearXianzhouCard;
        }
    }
};

TenyearShenxingCard::TenyearShenxingCard()
{
    target_fixed = true;
}

void TenyearShenxingCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isAlive())
        room->drawCards(source, 1, "tenyearshenxing");
}

class TenyearShenxing : public ViewAsSkill
{
public:
    TenyearShenxing() : ViewAsSkill("tenyearshenxing")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() < qMin(2, Self->usedTimes("TenyearShenxingCard")) && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != qMin(2, Self->usedTimes("TenyearShenxingCard")))
            return NULL;

        TenyearShenxingCard *card = new TenyearShenxingCard;
        card->addSubcards(cards);
        return card;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }
};

TenyearBingyiCard::TenyearBingyiCard()
{
}

bool TenyearBingyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    Card::Color color = Card::Colorless;
    foreach (const Card *c, Self->getHandcards()) {
        if (color == Card::Colorless)
            color = c->getColor();
        else if (c->getColor() != color)
            return targets.isEmpty();
    }
    return targets.length() <= Self->getHandcardNum();
}

bool TenyearBingyiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    Card::Color color = Card::Colorless;
    foreach (const Card *c, Self->getHandcards()) {
        if (color == Card::Colorless)
            color = c->getColor();
        else if (c->getColor() != color)
            return false;
    }
    return targets.length() < Self->getHandcardNum();
}

void TenyearBingyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->showAllCards(source);

    bool same_number = true;
    QList<const Card *>cards = source->getHandcards();
    int num = cards.first()->getNumber();
    foreach (const Card *c, source->getHandcards()) {
        if (c->getNumber() != num) {
            same_number = false;
            break;
        }
    }

    foreach(ServerPlayer *p, targets)
        room->drawCards(p, 1, "tenyearbingyi");
    if (same_number && source->isAlive())
        source->drawCards(1, "tenyearbingyi");
}

class TenyearBingyiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    TenyearBingyiViewAsSkill() : ZeroCardViewAsSkill("tenyearbingyi")
    {
        response_pattern = "@@tenyearbingyi";
    }

    const Card *viewAs() const
    {
        return new TenyearBingyiCard;
    }
};

class TenyearBingyi : public PhaseChangeSkill
{
public:
    TenyearBingyi() : PhaseChangeSkill("tenyearbingyi")
    {
        view_as_skill = new TenyearBingyiViewAsSkill;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() != Player::Finish || target->isKongcheng()) return false;
        target->getRoom()->askForUseCard(target, "@@tenyearbingyi", "@tenyearbingyi");
        return false;
    }
};

JXTPPackage::JXTPPackage()
    : Package("JXTP")
{
    General *tenyear_sunquan = new General(this, "tenyear_sunquan$", "wu", 4);
    tenyear_sunquan->addSkill(new TenyearZhiheng);
    tenyear_sunquan->addSkill(new TenyearJiuyuan);

    General *tenyear_sunshangxiang = new General(this, "tenyear_sunshangxiang", "wu", 3, false);
    tenyear_sunshangxiang->addSkill(new TenyearJieyin);
    tenyear_sunshangxiang->addSkill("xiaoji");

    General *tenyear_liubei = new General(this, "tenyear_liubei$", "shu", 4);
    tenyear_liubei->addSkill(new TenyearRende);
    tenyear_liubei->addSkill("jijiang");

    General *tenyear_guanyu = new General(this, "tenyear_guanyu", "shu", 4);
    tenyear_guanyu->addSkill(new TenyearWusheng);
    tenyear_guanyu->addSkill(new TenyearWushengMod);
    tenyear_guanyu->addSkill(new TenyearYijue);
    related_skills.insertMulti("tenyearwusheng", "#tenyearwushengmod");

    General *tenyear_zhangfei = new General(this, "tenyear_zhangfei", "shu", 4);
    tenyear_zhangfei->addSkill(new TenyearPaoxiao);
    tenyear_zhangfei->addSkill(new TenyearPaoxiaoMark);
    tenyear_zhangfei->addSkill(new TenyearTishen);
    related_skills.insertMulti("tenyearpaoxiao", "#tenyearpaoxiaomark");

    General *tenyear_zhugeliang = new General(this, "tenyear_zhugeliang", "shu", 3);
    tenyear_zhugeliang->addSkill(new TenyearGuanxing);
    tenyear_zhugeliang->addSkill("kongcheng");

    General *tenyear_zhaoyun = new General(this, "tenyear_zhaoyun", "shu", 4);
    tenyear_zhaoyun->addSkill("longdan");
    tenyear_zhaoyun->addSkill(new TenyearYajiao);

    General *tenyear_huangyueying = new General(this, "tenyear_huangyueying", "shu", 3, false);
    tenyear_huangyueying->addSkill(new TenyearJizhi);
    tenyear_huangyueying->addSkill("qicai");

    General *tenyear_caocao = new General(this, "tenyear_caocao$", "wei", 4);
    tenyear_caocao->addSkill(new TenyearJianxiong);
    tenyear_caocao->addSkill("hujia");

    General *tenyear_xiahoudun = new General(this, "tenyear_xiahoudun", "wei", 4);
    tenyear_xiahoudun->addSkill("ganglie");
    tenyear_xiahoudun->addSkill(new TenyearQingjian);

    General *tenyear_xuchu = new General(this, "tenyear_xuchu", "wei", 4);
    tenyear_xuchu->addSkill(new TenyearLuoyi);
    tenyear_xuchu->addSkill(new TenyearLuoyiBuff);
    related_skills.insertMulti("tenyearluoyi", "#tenyearluoyibuff");

    General *tenyear_guojia = new General(this, "tenyear_guojia", "wei", 3);
    tenyear_guojia->addSkill("tiandu");
    tenyear_guojia->addSkill(new TenyearYiji);

    General *tenyear_zhenji = new General(this, "tenyear_zhenji", "wei", 3, false);
    tenyear_zhenji->addSkill("qingguo");
    tenyear_zhenji->addSkill(new TenyearLuoshen);

    General *tenyear_zhangliao = new General(this, "tenyear_zhangliao", "wei");
    tenyear_zhangliao->addSkill(new TenyearTuxi);
    tenyear_zhangliao->addSkill(new TenyearTuxiAct);
    related_skills.insertMulti("tenyeartuxi", "#tenyeartuxi");

    General *tenyear_huatuo = new General(this, "tenyear_huatuo", "qun", 3);
    tenyear_huatuo->addSkill("jijiu");
    tenyear_huatuo->addSkill(new TenyearQingnang);

    General *tenyear_lvbu = new General(this, "tenyear_lvbu", "qun", 5);
    tenyear_lvbu->addSkill("wushuang");
    tenyear_lvbu->addSkill(new TenyearLiyu);

    General *tenyear_diaochan = new General(this, "tenyear_diaochan", "qun", 3, false);
    tenyear_diaochan->addSkill("lijian");
    tenyear_diaochan->addSkill(new TenyearBiyue);

    General *tenyear_huaxiong = new General(this, "tenyear_huaxiong", "qun", 6);
    tenyear_huaxiong->addSkill(new TenyearYaowu);

    General *tenyear_huangzhong = new General(this, "tenyear_huangzhong", "shu", 4);
    tenyear_huangzhong->addSkill(new TenyearLiegong);
    tenyear_huangzhong->addSkill(new TenyearLiegongMod);
    related_skills.insertMulti("tenyearliegong", "#tenyearliegongmod");

    General *tenyear_weiyan = new General(this, "tenyear_weiyan", "shu", 4);
    tenyear_weiyan->addSkill(new TenyearKuanggu);
    tenyear_weiyan->addSkill(new TenyearKuangguRecord);
    tenyear_weiyan->addSkill(new TenyearQimou);
    related_skills.insertMulti("tenyearkuanggu", "#tenyearkuanggu-record");

    General *tenyear_xiahouyuan = new General(this, "tenyear_xiahouyuan", "wei", 4);
    tenyear_xiahouyuan->addSkill(new TenyearShensu);
    tenyear_xiahouyuan->addSkill(new SlashNoDistanceLimitSkill("tenyearshensu"));
    related_skills.insertMulti("tenyearshensu", "#tenyearshensu-slash-ndl");

    General *tenyear_caoren = new General(this, "tenyear_caoren", "wei", 4);
    tenyear_caoren->addSkill(new TenyearJushou);
    tenyear_caoren->addSkill(new TenyearJiewei);

    General *tenyear_xiaoqiao = new General(this, "tenyear_xiaoqiao", "wu", 3, false);
    tenyear_xiaoqiao->addSkill(new TenyearTianxiang);
    tenyear_xiaoqiao->addSkill("hongyan");

    General *tenyear_pangde = new General(this, "tenyear_pangde", "qun", 4);
    tenyear_pangde->addSkill(new TenyearJianchu);
    tenyear_pangde->addSkill("mashu");

    General *tenyear_masu = new General(this, "tenyear_masu", "shu", 3);
    tenyear_masu->addSkill(new TenyearSanyao);
    tenyear_masu->addSkill(new TenyearZhiman);

    General *tenyear_yujin = new General(this, "tenyear_yujin", "wei", 4);
    tenyear_yujin->addSkill(new TenyearZhenjun);
    tenyear_yujin->addSkill(new FakeMoveSkill("tenyearzhenjun"));
    related_skills.insertMulti("tenyearzhenjun", "#tenyearzhenjun-fake-move");

    General *second_tenyear_yujin = new General(this, "second_tenyear_yujin", "wei", 4);
    second_tenyear_yujin->addSkill(new SecondTenyearZhenjun);
    second_tenyear_yujin->addSkill(new FakeMoveSkill("secondtenyearzhenjun"));
    related_skills.insertMulti("secondtenyearzhenjun", "#secondtenyearzhenjun-fake-move");

    General *tenyear_guohuai = new General(this, "tenyear_guohuai", "wei", 4);
    tenyear_guohuai->addSkill(new TenyearJingce);
    tenyear_guohuai->addSkill(new TenyearJingceRecord);
    related_skills.insertMulti("tenyearjingce", "#tenyearjingce-record");

    General *second_tenyear_guohuai = new General(this, "second_tenyear_guohuai", "wei", 4);
    second_tenyear_guohuai->addSkill(new SecondTenyearJingce);

    General *tenyear_liaohua = new General(this, "tenyear_liaohua", "shu", 4);
    tenyear_liaohua->addSkill(new TenyearDangxian);
    tenyear_liaohua->addSkill(new TenyearFuli);

    General *tenyear_chengpu = new General(this, "tenyear_chengpu", "wu", 4);
    tenyear_chengpu->addSkill("lihuo");
    tenyear_chengpu->addSkill(new TenyearChunlao);

    General *second_tenyear_chengpu = new General(this, "second_tenyear_chengpu", "wu", 4);
    second_tenyear_chengpu->addSkill(new SecondTenyearLihuo);
    second_tenyear_chengpu->addSkill(new SecondTenyearLihuoRecord);
    second_tenyear_chengpu->addSkill(new SecondTenyearLihuoTargetMod);
    second_tenyear_chengpu->addSkill(new SecondTenyearChunlao);
    related_skills.insertMulti("secondtenyearlihuo", "#secondtenyearlihuo-record");
    related_skills.insertMulti("secondtenyearlihuo", "#secondtenyearlihuo-target");

    General *tenyear_caozhang = new General(this, "tenyear_caozhang", "wei", 4);
    tenyear_caozhang->addSkill(new TenyearJiangchi);

    General *second_tenyear_caozhang = new General(this, "second_tenyear_caozhang", "wei", 4);
    second_tenyear_caozhang->addSkill(new SecondTenyearJiangchi);
    second_tenyear_caozhang->addSkill(new SecondTenyearJiangchiClear);
    second_tenyear_caozhang->addSkill(new SecondTenyearJiangchiMod);
    related_skills.insertMulti("secondtenyearjiangchi", "#secondtenyearlihuo-clear");
    related_skills.insertMulti("secondtenyearjiangchi", "#secondtenyearjiangchi-target");

    General *tenyear_zhangyi = new General(this, "tenyear_zhangyi", "shu", 4);
    tenyear_zhangyi->addSkill(new TenyearWurong);
    tenyear_zhangyi->addSkill("shizhi");

    General *second_tenyear_zhangyi = new General(this, "second_tenyear_zhangyi", "shu", 5);
    second_tenyear_zhangyi->addSkill("tenyearwurong");
    second_tenyear_zhangyi->addSkill(new SecondTenyearShizhi);
    second_tenyear_zhangyi->addSkill(new SecondTenyearShizhiTrigger);
    related_skills.insertMulti("secondtenyearshizhi", "#secondtenyearshizhi");

    General *tenyear_quancong = new General(this, "tenyear_quancong", "wu", 4);
    tenyear_quancong->addSkill(new TenyearYaoming);

    General *tenyear_zhuran = new General(this, "tenyear_zhuran", "wu", 4);
    tenyear_zhuran->addSkill(new TenyearDanshou);
    tenyear_zhuran->addSkill(new TenyearDanshouRecord);
    related_skills.insertMulti("tenyeardanshou", "#tenyeardanshou-record");

    General *tenyear_sunluban = new General(this, "tenyear_sunluban", "wu", 3, false);
    tenyear_sunluban->addSkill(new TenyearZenhui);
    tenyear_sunluban->addSkill(new TenyearJiaojin);

    General *tenyear_wuyi = new General(this, "tenyear_wuyi", "shu", 4);
    tenyear_wuyi->addSkill(new TenyearBenxi);

    General *tenyear_panfeng = new General(this, "tenyear_panfeng", "qun", 4);
    tenyear_panfeng->addSkill(new TenyearKuangfu);
    tenyear_panfeng->addSkill(new SlashNoDistanceLimitSkill("tenyearkuangfu"));
    related_skills.insertMulti("tenyearkuangfu", "#tenyearkuangfu-slash-ndl");

    General *tenyear_xusheng = new General(this, "tenyear_xusheng", "wu", 4);
    tenyear_xusheng->addSkill(new TenyearPojun);
    tenyear_xusheng->addSkill(new FakeMoveSkill("tenyearpojun"));
    related_skills.insertMulti("tenyearpojun", "#tenyearpojun-fake-move");

    General *tenyear_xuhuang = new General(this, "tenyear_xuhuang", "wei", 4);
    tenyear_xuhuang->addSkill(new TenyearDuanliang);
    tenyear_xuhuang->addSkill(new TenyearDuanliangTargetMod);
    tenyear_xuhuang->addSkill(new TenyearJiezi);
    related_skills.insertMulti("tenyearduanliang", "#tenyearduanliang-target");

    General *tenyear_sunhao = new General(this, "tenyear_sunhao$", "wu", 5);
    tenyear_sunhao->addSkill(new TenyearCanshi);
    tenyear_sunhao->addSkill(new TenyearChouhai);
    tenyear_sunhao->addSkill("guiming");

    General *tenyear_sunxiu = new General(this, "tenyear_sunxiu$", "wu", 3);
    tenyear_sunxiu->addSkill(new TenyearYanzhu);
    tenyear_sunxiu->addSkill(new TenyearXingxue);
    tenyear_sunxiu->addSkill("zhaofu");

    General *tenyear_caoxiu = new General(this, "tenyear_caoxiu", "wei", 4);
    tenyear_caoxiu->addSkill(new TenyearQingxi);
    tenyear_caoxiu->addSkill(new TenyearQingxiDamage);
    tenyear_caoxiu->addSkill("qianju");
    related_skills.insertMulti("tenyearqingxi", "#tenyearqingxi-damage");

    General *tenyear_panzhangmazhong = new General(this, "tenyear_panzhangmazhong", "wu", 4);
    tenyear_panzhangmazhong->addSkill(new TenyearDuodao);
    tenyear_panzhangmazhong->addSkill(new TenyearAnjian);
    tenyear_panzhangmazhong->addSkill(new TenyearAnjianEffect);
    related_skills.insertMulti("tenyearanjian", "#tenyearanjian-effect");

    General *tenyear_hanhaoshihuan = new General(this, "tenyear_hanhaoshihuan", "wei", 4);
    tenyear_hanhaoshihuan->addSkill(new TenyearShenduan);
    tenyear_hanhaoshihuan->addSkill(new TenyearShenduanTargetMod);
    tenyear_hanhaoshihuan->addSkill(new TenyearYonglve);
    related_skills.insertMulti("tenyearshenduan", "#tenyearshenduan-target");

    General *tenyear_jianyong = new General(this, "tenyear_jianyong", "shu", 3);
    tenyear_jianyong->addSkill(new TenyearQiaoshui);
    tenyear_jianyong->addSkill(new TenyearQiaoshuiTargetMod);
    tenyear_jianyong->addSkill("zongshih");
    related_skills.insertMulti("tenyearqiaoshui", "#tenyearqiaoshui-target");

    General *tenyear_zhugeke = new General(this, "tenyear_zhugeke", "wu", 3);
    tenyear_zhugeke->addSkill(new TenyearAocai);
    tenyear_zhugeke->addSkill(new TenyearDuwu);

    General *tenyear_yangxiu = new General(this, "tenyear_yangxiu", "wei", 3);
    tenyear_yangxiu->addSkill(new TenyearDanlao);
    tenyear_yangxiu->addSkill(new TenyearJilei);
    tenyear_yangxiu->addSkill(new TenyearJileiClear);
    related_skills.insertMulti("tenyearjilei", "#tenyearjilei-clear");

    General *tenyear_gaoshun = new General(this, "tenyear_gaoshun", "qun", 4);
    tenyear_gaoshun->addSkill(new TenyearXianzhen("tenyearxianzhen"));
    tenyear_gaoshun->addSkill(new TenyearXianzhenSlash("tenyearxianzhen"));
    tenyear_gaoshun->addSkill(new TenyearXianzhenTargetMod("tenyearxianzhen"));
    tenyear_gaoshun->addSkill("jinjiu");
    related_skills.insertMulti("tenyearxianzhen", "#tenyearxianzhen-slash");
    related_skills.insertMulti("tenyearxianzhen", "#tenyearxianzhen-target");

    General *second_tenyear_gaoshun = new General(this, "second_tenyear_gaoshun", "qun", 4);
    second_tenyear_gaoshun->setImage("tenyear_gaoshun");
    second_tenyear_gaoshun->addSkill(new TenyearXianzhen("secondtenyearxianzhen"));
    second_tenyear_gaoshun->addSkill(new TenyearXianzhenSlash("secondtenyearxianzhen"));
    second_tenyear_gaoshun->addSkill(new TenyearXianzhenTargetMod("secondtenyearxianzhen"));
    second_tenyear_gaoshun->addSkill(new SecondTenyearJinjiu);
    second_tenyear_gaoshun->addSkill(new SecondTenyearJinjiuLimit);
    related_skills.insertMulti("secondtenyearxianzhen", "#secondtenyearxianzhen-slash");
    related_skills.insertMulti("secondtenyearxianzhen", "#secondtenyearxianzhen-target");
    related_skills.insertMulti("secondtenyearjinjiu", "#secondtenyearjinjiu-limit");

    General *tenyear_shixie = new General(this, "tenyear_shixie", "qun", 3);
    tenyear_shixie->addSkill(new Tenyearbiluan);
    tenyear_shixie->addSkill(new TenyearbiluanTrigger);
    tenyear_shixie->addSkill(new TenyearLixia);
    tenyear_shixie->addSkill(new TenyearLixiaTrigger);
    related_skills.insertMulti("tenyearbiluan", "#tenyearbiluan-trigger");
    related_skills.insertMulti("tenyearlixia", "#tenyearlixia-trigger");

    General *tenyear_liubiao = new General(this, "tenyear_liubiao", "qun", 3);
    tenyear_liubiao->addSkill(new TenyearZishou);
    tenyear_liubiao->addSkill(new TenyearZongshi);
    tenyear_liubiao->addSkill(new TenyearZongshiProtect);
    related_skills.insertMulti("tenyearzongshi", "#tenyearzongshi-protect");

    General *tenyear_lingtong = new General(this, "tenyear_lingtong", "wu", 4);
    tenyear_lingtong->addSkill(new TenyearXuanfeng);
    tenyear_lingtong->addSkill(new Tenyearyongjin);

    General *tenyear_fazheng = new General(this, "tenyear_fazheng", "shu", 3);
    tenyear_fazheng->addSkill(new TenyearEnyuan);
    tenyear_fazheng->addSkill(new TenyearXuanhuo);

    General *tenyear_fuhuanghou = new General(this, "tenyear_fuhuanghou", "qun", 3, false);
    tenyear_fuhuanghou->addSkill(new TenyearZhuikong);
    tenyear_fuhuanghou->addSkill(new TenyearZhuikongProhibit);
    tenyear_fuhuanghou->addSkill(new TenyearQiuyuan);
    related_skills.insertMulti("tenyearzhuikong", "#tenyearzhuikong");

    General *tenyear_caozhen = new General(this, "tenyear_caozhen", "wei", 4);
    tenyear_caozhen->addSkill(new TenyearSidi);
    tenyear_caozhen->addSkill(new TenyearSidiEffect);
    related_skills.insertMulti("tenyearsidi", "#tenyearsidi-effect");

    General *tenyear_gongsunyuan = new General(this, "tenyear_gongsunyuan", "qun", 4);
    tenyear_gongsunyuan->addSkill(new TenyearHuaiyi);

    General *tenyear_zhangchunhua = new General(this, "tenyear_zhangchunhua", "wei", 3, false);
    tenyear_zhangchunhua->addSkill(new Tenyearjueqing);
    tenyear_zhangchunhua->addSkill(new TenyearjueqingComplete);
    tenyear_zhangchunhua->addSkill("nosshangshi");
    related_skills.insertMulti("tenyearjueqing", "#tenyearjueqing");

    General *tenyear_handang = new General(this, "tenyear_handang", "wu", 4);
    tenyear_handang->addSkill(new TenyearGongqi);
    tenyear_handang->addSkill(new TenyearGongqiTargetMod);
    tenyear_handang->addSkill(new TenyearJiefan);
    related_skills.insertMulti("tenyeargongqi", "#tenyeargongqi-target");

    General *tenyear_zhoucang = new General(this, "tenyear_zhoucang", "shu", 4);
    tenyear_zhoucang->addSkill(new TenyearZhongyong);

    General *tenyear_guotupangji = new General(this, "tenyear_guotupangji", "qun", 3);
    tenyear_guotupangji->addSkill(new TenyearJigong);
    tenyear_guotupangji->addSkill(new TenyearJigongMax);
    tenyear_guotupangji->addSkill(new TenyearJigongRecover);
    tenyear_guotupangji->addSkill("shifei");
    related_skills.insertMulti("tenyearjigong", "#tenyearjigong");
    related_skills.insertMulti("tenyearjigong", "#tenyearjigong-recover");

    General *tenyear_guanping = new General(this, "tenyear_guanping", "shu", 4);
    tenyear_guanping->addSkill(new TenyearJiezhong);
    tenyear_guanping->addSkill(new TenyearLongyin);

    General *tenyear_caifuren = new General(this, "tenyear_caifuren", "qun", 3, false);
    tenyear_caifuren->addSkill(new TenyearQieting);
    tenyear_caifuren->addSkill(new TenyearXianzhou);

    General *tenyear_guyong = new General(this, "tenyear_guyong", "wu", 3);
    tenyear_guyong->addSkill(new TenyearShenxing);
    tenyear_guyong->addSkill(new TenyearBingyi);

    addMetaObject<TenyearZhihengCard>();
    addMetaObject<TenyearJieyinCard>();
    addMetaObject<TenyearRendeCard>();
    addMetaObject<TenyearYijueCard>();
    addMetaObject<TenyearQingjianCard>();
    addMetaObject<TenyearTuxiCard>();
    addMetaObject<TenyearQingnangCard>();
    addMetaObject<TenyearQimouCard>();
    addMetaObject<TenyearShensuCard>();
    addMetaObject<TenyearTianxiangCard>();
    addMetaObject<TenyearSanyaoCard>();
    addMetaObject<TenyearChunlaoCard>();
    addMetaObject<TenyearChunlaoWineCard>();
    addMetaObject<SecondTenyearChunlaoCard>();
    addMetaObject<SecondTenyearChunlaoWineCard>();
    addMetaObject<TenyearJiangchiCard>();
    addMetaObject<TenyearWurongCard>();
    addMetaObject<TenyearKuangfuCard>();
    addMetaObject<TenyearYanzhuCard>();
    addMetaObject<TenyearXingxueCard>();
    addMetaObject<TenyearShenduanCard>();
    addMetaObject<TenyearQiaoshuiCard>();
    addMetaObject<TenyearQiaoshuiTargetCard>();
    addMetaObject<TenyearAocaiCard>();
    addMetaObject<TenyearDuwuCard>();
    addMetaObject<TenyearXianzhenCard>();
    addMetaObject<SecondTenyearXianzhenCard>();
    addMetaObject<TenyearZishouCard>();
    addMetaObject<TenyearyongjinCard>();
    addMetaObject<TenyearXuanhuoCard>();
    addMetaObject<TenyearSidiCard>();
    addMetaObject<TenyearHuaiyiCard>();
    addMetaObject<TenyearHuaiyiSnatchCard>();
    addMetaObject<TenyearGongqiCard>();
    addMetaObject<TenyearJiefanCard>();
    addMetaObject<TenyearXianzhouDamageCard>();
    addMetaObject<TenyearXianzhouCard>();
    addMetaObject<TenyearShenxingCard>();
    addMetaObject<TenyearBingyiCard>();
}

ADD_PACKAGE(JXTP)
