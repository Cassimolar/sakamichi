#include "sp2.h"
#include "client.h"
#include "general.h"
#include "skill.h"
#include "standard-skillcards.h"
#include "engine.h"
#include "maneuvering.h"
#include "json.h"
#include "settings.h"
#include "clientplayer.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "yjcm2013.h"
#include "wind.h"
#include "sp4.h"

LvemingCard::LvemingCard()
{
}

bool LvemingCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getEquips().length() < Self->getEquips().length();
}

void LvemingCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.from, "&lveming");
    QStringList nums;
    for (int i = 1; i < 14; i++) {
        nums << QString::number(i);
    }
    QString choice = room->askForChoice(effect.to, "lveming", nums.join("+"));
    LogMessage log;
    log.type = "#FumianFirstChoice";
    log.from = effect.to;
    log.arg = choice;
    room->sendLog(log);

    JudgeStruct judge;
    judge.pattern = ".";
    judge.who = effect.from;
    judge.reason = "lveming";
    judge.play_animation = false;
    room->judge(judge);

    int number = judge.pattern.toInt();

    if (number == choice.toInt()) {
        room->damage(DamageStruct("lveming", effect.from, effect.to, 2));
    } else {
        if (effect.to->isAllNude()) return;
        const Card *card = effect.to->getCards("hej").at(qrand() % effect.to->getCards("hej").length());
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
        room->obtainCard(effect.from, card, reason, room->getCardPlace(card->getEffectiveId()) != Player::PlaceHand);
    }
}

class LvemingVS : public ZeroCardViewAsSkill
{
public:
    LvemingVS() : ZeroCardViewAsSkill("lveming")
    {
    }

    const Card *viewAs() const
    {
        return new LvemingCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("LvemingCard") && !player->getEquips().isEmpty();
    }
};

class Lveming : public TriggerSkill
{
public:
    Lveming() : TriggerSkill("lveming")
    {
        events << FinishJudge;
        view_as_skill = new LvemingVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != objectName()) return false;
        judge->pattern = QString::number(judge->card->getNumber());
        return false;
    }
};


TunjunCard::TunjunCard()
{
}

bool TunjunCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

QList<int> TunjunCard::removeList(QList<int> equips, QList<int> ids) const
{
    foreach (int id, ids)
        equips.removeOne(id);
    return equips;
}

void TunjunCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->doSuperLightbox("sp_zhangji", "tunjun");
    room->removePlayerMark(effect.from, "@tunjunMark");

    int n = effect.from->getMark("&lveming");
    if (n <= 0) return;

    QList<int> weapon, armor, defensivehorse, offensivehorse, treasure, equips;
    foreach (int id, room->getDrawPile()) {
        equips << id;
        const Card *card = Sanguosha->getCard(id);
        if (card->isKindOf("Weapon"))
            weapon << id;
        else if (card->isKindOf("Armor"))
            armor << id;
        else if (card->isKindOf("DefensiveHorse"))
            defensivehorse << id;
        else if (card->isKindOf("OffensiveHorse"))
            offensivehorse << id;
        else if (card->isKindOf("Treasure"))
            treasure << id;
        else
            equips.removeOne(id);
    }
    if (equips.isEmpty()) return;

    QList<int> use_cards;
    for (int i = 0; i < n; i++) {
        if (equips.isEmpty()) break;
        int id = equips.at(qrand() % equips.length());
        use_cards << id;
        if (weapon.contains(id))
            equips = removeList(equips, weapon);
        else if (armor.contains(id))
            equips = removeList(equips, armor);
        else if (defensivehorse.contains(id))
            equips = removeList(equips, defensivehorse);
        else if (offensivehorse.contains(id))
            equips = removeList(equips, offensivehorse);
        else if (treasure.contains(id))
            equips = removeList(equips, treasure);
    }
    if (use_cards.isEmpty()) return;

    foreach (int id, use_cards) {
        if (effect.from->isDead()) return;
        const Card *card = Sanguosha->getCard(id);
        if (!card->isAvailable(effect.to)) continue;
        room->useCard(CardUseStruct(card, effect.to, effect.to), true);
    }
}

class Tunjun : public ZeroCardViewAsSkill
{
public:
    Tunjun() : ZeroCardViewAsSkill("tunjun")
    {
        frequency = Limited;
        limit_mark = "@tunjunMark";
    }

    const Card *viewAs() const
    {
        return new TunjunCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@tunjunMark") > 0 && player->getMark("&lveming") > 0;
    }
};

class Sanwen : public TriggerSkill
{
public:
    Sanwen() : TriggerSkill("sanwen")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (room->getTag("FirstRound").toBool()) return false;
        if (player->getMark("sanwen-Clear") > 0) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.to || move.to != player || move.to_place != Player::PlaceHand) return false;
        DummyCard *dummy = new DummyCard;
        QList<const Card *> handcards = player->getCards("h");
        if (handcards.isEmpty()) return false;
        QList<int> shows;
        foreach (int id, move.card_ids) {
            const Card *card = Sanguosha->getCard(id);
            if (room->getCardPlace(id) != Player::PlaceHand || room->getCardOwner(id) != player) continue;
            foreach (const Card *c, handcards) {
                if (c->sameNameWith(card) && !move.card_ids.contains(c->getEffectiveId())) {
                    if (!dummy->getSubcards().contains(id))
                        dummy->addSubcard(id);
                    if (!shows.contains(id))
                        shows << id;
                    if (!shows.contains(c->getEffectiveId()))
                        shows << c->getEffectiveId();
                }
            }
        }
        QList<int> subcards = dummy->getSubcards();
        if (dummy->subcardsLength() > 0 && player->askForSkillInvoke(this, IntList2VariantList(subcards))) {
            room->broadcastSkillInvoke(objectName());
            LogMessage log;
            log.type = "$ShowCard";
            log.from = player;
            log.card_str = IntList2StringList(shows).join("+");
            room->sendLog(log);
            room->fillAG(shows);
            room->getThread()->delay();
            room->clearAG();
            room->addPlayerMark(player, "sanwen-Clear");
            room->throwCard(dummy, player, NULL);
            player->drawCards(2 * subcards.length());
        }
        delete dummy;
        return false;
    }
};

class Qiai : public TriggerSkill
{
public:
    Qiai() : TriggerSkill("qiai")
    {
        events << EnterDying;
        frequency = Limited;
        limit_mark = "@qiaiMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getMark("@qiaiMark") <= 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->removePlayerMark(player, "@qiaiMark");
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("wangcan", "qiai");

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isAlive() && !p->isNude()) {
                const Card *card = room->askForCard(p, "..", "qiai-give:" + player->objectName(), QVariant::fromValue(player), Card::MethodNone);
                if (!card)
                    card = p->getCards("he").at(qrand() % p->getCards("he").length());
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, p->objectName(), player->objectName(), "qiai", QString());
                room->obtainCard(player, card, reason, false);
            }
        }
        return false;
    }
};

DenglouCard::DenglouCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool DenglouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getEngineCard(id);
    if (card->targetFixed())
        return to_select == Self;
    return card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

void DenglouCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getEngineCard(id);
    if (card->targetFixed()) return;
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "denglou_target");
}

class DenglouVS : public OneCardViewAsSkill
{
public:
    DenglouVS() : OneCardViewAsSkill("denglou")
    {
        response_pattern = "@@denglou!";
        frequency = Limited;
        limit_mark = "@denglouMark";
    }

    bool viewFilter(const Card *to_select) const
    {
        QStringList cards = Self->property("denglou_ids").toString().split("+");
        return cards.contains(to_select->toString());
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs(const Card *originalcard) const
    {
        DenglouCard *card = new DenglouCard;
        card->addSubcard(originalcard);
        return card;
    }
};

class Denglou : public PhaseChangeSkill
{
public:
    Denglou() : PhaseChangeSkill("denglou")
    {
        frequency = Limited;
        limit_mark = "@denglouMark";
        view_as_skill = new DenglouVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (!player->isKongcheng() || player->getMark("@denglouMark") <= 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->removePlayerMark(player, "@denglouMark");
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("wangcan", "denglou");

        QList<int> views = room->getNCards(4);
        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(views).join("+");
        room->sendLog(log, player);

        DummyCard *dummy = new DummyCard;
        foreach (int id, views) {
            if (!Sanguosha->getCard(id)->isKindOf("BasicCard")) {
                dummy->addSubcard(id);
                views.removeOne(id);
            }
        }
        if (dummy->subcardsLength() > 0)
            room->obtainCard(player, dummy, true);
        delete dummy;
        if (views.isEmpty()) return false;

        QList<ServerPlayer *> _player;
        _player.append(player);

        while (!views.isEmpty()) {
            if (player->isDead()) break;
            QList<int> use_ids;

            foreach (int id, views) {
                const Card *card = Sanguosha->getEngineCard(id);
                if (player->isLocked(card)) continue;
                if (card->targetFixed()) {
                    if (card->isAvailable(player)) {
                        use_ids << id;
                    }
                } else {
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (player->isProhibited(p, card) || !card->targetFilter(QList<const Player *>(), p, player)) continue;
                        use_ids << id;
                        break;
                    }
                }
            }
            if (use_ids.isEmpty()) break;

            CardsMoveStruct move(views, NULL, player, Player::PlaceTable, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_PREVIEW, player->objectName(), objectName(), QString()));
            QList<CardsMoveStruct> moves;
            moves.append(move);
            room->notifyMoveCards(true, moves, false, _player);
            room->notifyMoveCards(false, moves, false, _player);

            room->setPlayerProperty(player, "denglou_ids", IntList2StringList(use_ids).join("+"));

            const Card *c = room->askForUseCard(player, "@@denglou!", "@denglou");

            room->setPlayerProperty(player, "denglou_ids", QString());

            CardsMoveStruct move2(views, player, NULL, Player::PlaceHand, Player::PlaceTable,
                CardMoveReason(CardMoveReason::S_REASON_PREVIEW, player->objectName(), objectName(), QString()));
            QList<CardsMoveStruct> moves2;
            moves2.append(move2);
            room->notifyMoveCards(true, moves2, false, _player);
            room->notifyMoveCards(false, moves2, false, _player);

            QList<ServerPlayer *> tos;
            const Card *use = NULL;

            if (!c) {
                int id = use_ids.at(qrand() & use_ids.length());
                views.removeOne(id);
                use = Sanguosha->getEngineCard(id);
            } else {
                int id = c->getSubcards().first();
                views.removeOne(id);
                use = Sanguosha->getEngineCard(id);
            }

            if (use->targetFixed())
                room->useCard(CardUseStruct(use, player, player));
            else {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("denglou_target")) {
                        room->setPlayerFlag(p, "-denglou_target");
                        tos << p;
                    }
                }
                if (!tos.isEmpty()) {
                    room->sortByActionOrder(tos);
                    room->useCard(CardUseStruct(use, player, tos), false);
                } else {
                    QList<ServerPlayer *> ava;
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (player->isProhibited(p, use) || !use->targetFilter(QList<const Player *>(), p, player)) continue;
                        ava << p;
                    }
                    if (ava.isEmpty()) continue;
                    room->useCard(CardUseStruct(use, player, ava.at(qrand() % ava.length())));
                }
            }
        }

        if (views.isEmpty()) return false;

        DummyCard *new_dummy = new DummyCard(views);
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "denglou", QString());
        room->throwCard(new_dummy, reason, NULL);
        delete new_dummy;
        return false;
    }
};

class Gangzhi : public TriggerSkill
{
public:
    Gangzhi() : TriggerSkill("gangzhi")
    {
        frequency = Compulsory;
        events << Predamage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        QList<ServerPlayer *> players;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead()) return false;

        if (damage.from && damage.from->isAlive() && damage.from->hasSkill(this))
            players << damage.from;
        if (damage.to && damage.to->isAlive() && damage.to->hasSkill(this))
            players << damage.to;
        if (players.isEmpty()) return false;

        room->sortByActionOrder(players);
        ServerPlayer *player = players.first();
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->loseHp(damage.to, damage.damage, damage.ignore_hujia);
        return true;
    }
};

class Beizhan : public TriggerSkill
{
public:
    Beizhan() : TriggerSkill("beizhan")
    {
        events << EventPhaseChanging << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (!player->hasSkill(this)) return false;
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@beizhan-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());

            QStringList names = room->getTag("beizhan_targets").toStringList();
            if (!names.contains(target->objectName())) {
                names << target->objectName();
                room->setTag("beizhan_targets", names);
            }
            room->setPlayerMark(target, "&beizhan", 1);
            int n = qMin(target->getMaxHp(), 5);
            if (target->getHandcardNum() >= n) return false;
            target->drawCards(n - target->getHandcardNum(), objectName());
        } else {
            if (player->getPhase() != Player::RoundStart) return false;
            room->setPlayerMark(player, "&beizhan", 0);
            QStringList names = room->getTag("beizhan_targets").toStringList();
            if (!names.contains(player->objectName())) return false;
            names.removeAll(player->objectName());
            room->setTag("beizhan_targets", names);
            int hand = player->getHandcardNum();
            bool max = true;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p != player && p->getHandcardNum() > hand)
                    max = false;
            }
            if (max == false) return false;
            LogMessage log;
            log.type = "#BeizhanEffect";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->addPlayerMark(player, "beizhan_pro-Clear");
        }
        return false;
    }
};

class BeizhanPro : public ProhibitSkill
{
public:
    BeizhanPro() : ProhibitSkill("#beizhan-prohibit")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from != to && from->getMark("beizhan_pro-Clear") > 0 && !card->isKindOf("SkillCard");
    }
};

class MobileShouye : public TriggerSkill
{
public:
    MobileShouye() : TriggerSkill("mobileshouye")
    {
        events << TargetConfirmed << BeforeCardsMove;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard") || use.to.length() != 1 || !use.to.contains(player)) return false;
            if (!use.from || use.from->isDead() || use.from == player) return false;
            if (player->getMark("mobileshouye-Clear") > 0 || !room->hasCurrent()) return false;
            player->tag["mobileshouyeForAI"] = data;
            bool invoke = player->askForSkillInvoke(this, QVariant::fromValue(use.from));
            player->tag.remove("mobileshouyeForAI");
            if (!invoke) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "mobileshouye-Clear");

            QString shouce = room->askForChoice(player, objectName(), "kaicheng+qixi");
            QString gongce = room->askForChoice(use.from, objectName(), "quanjun+fenbing");
            LogMessage log;
            log.type = "#MobileshouyeDuice";
            log.from = player;
            log.arg = "mobileshouye:" + shouce;
            log.to << use.from;
            log.arg2 = "mobileshouye:" + gongce;
            room->sendLog(log);

            if ((shouce == "kaicheng" && gongce == "fenbing") || (shouce == "qixi" && gongce == "quanjun")) {
                log.type = "#MobileshouyeDuiceSucceed";
                room->sendLog(log);
                use.nullified_list << player->objectName();
                data = QVariant::fromValue(use);
                room->setCardFlag(use.card, objectName() + player->objectName());
            } else {
                log.type = "#MobileshouyeDuiceFail";
                room->sendLog(log);
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from_places.contains(Player::PlaceTable) && move.to_place == Player::DiscardPile
                    && move.reason.m_reason == CardMoveReason::S_REASON_USE) {
                const Card *card = move.reason.m_extraData.value<const Card *>();
                if (!card || !card->hasFlag(objectName() + player->objectName())) return false;
                room->setCardFlag(card, "-" + objectName() + player->objectName());
                QList<int> ids;
                if (card->isVirtualCard())
                    ids = card->getSubcards();
                else
                    ids << card->getEffectiveId();

                if (ids.isEmpty() || !room->CardInTable(card)) return false;
                player->obtainCard(card, true);
                move.removeCardIds(ids);
                data = QVariant::fromValue(move);
            }
        }
        return false;
    }
};

MobileLiezhiCard::MobileLiezhiCard()
{
}

bool MobileLiezhiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < 2 && Self->canDiscard(to_select, "hej") && to_select != Self;
}

void MobileLiezhiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    if (!effect.from->canDiscard(effect.to, "hej")) return;
    Room *room = effect.from->getRoom();
    int card_id = room->askForCardChosen(effect.from, effect.to, "hej", "mobileliezhi", false, Card::MethodDiscard);
    room->throwCard(card_id, room->getCardPlace(card_id) == Player::PlaceDelayedTrick ? NULL : effect.to, effect.from);
}

class MobileLiezhiVS : public ZeroCardViewAsSkill
{
public:
    MobileLiezhiVS() : ZeroCardViewAsSkill("mobileliezhi")
    {
        response_pattern = "@@mobileliezhi";
    }

    const Card *viewAs() const
    {
        return new MobileLiezhiCard;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }
};

class MobileLiezhi : public TriggerSkill
{
public:
    MobileLiezhi() : TriggerSkill("mobileliezhi")
    {
        events << EventPhaseStart << Death << EventLoseSkill << Damaged;
        view_as_skill = new MobileLiezhiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->hasSkill(this) && player->getPhase() == Player::Start && player->isAlive()) {
                if (player->getMark("mobileliezhi_disabled") > 0) return false;
                bool candis = false;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (player->canDiscard(p, "hej")) {
                        candis = true;
                        break;
                    }
                }
                if (!candis) return false;
                room->askForUseCard(player, "@@mobileliezhi", "@mobileliezhi");
            } else if (player->getPhase() == Player::Finish && player->hasSkill(this, true)) {
                if (player->getMark("mobileliezhi_disabled") <= 0) return false;
                room->setPlayerMark(player, "mobileliezhi_disabled", 0);
            }
        } else if (event == Damaged) {
            if (!player->isAlive() || !player->hasSkill(this)) return false;
            LogMessage log;
            log.type = "#MobileliezhiDisabled";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "mobileliezhi_disabled");
        } else {
            if (event == Death) {
                DeathStruct death = data.value<DeathStruct>();
                if (death.who != player || !player->hasSkill(this)) return false;
            } else if (event == EventLoseSkill) {
                if (data.toString() != objectName() || player->isDead()) return false;
            }
            if (player->getMark("mobileliezhi_disabled") <= 0) return false;
            room->setPlayerMark(player, "mobileliezhi_disabled", 0);
        }
        return false;
    }
};

class Ranshang : public TriggerSkill
{
public:
    Ranshang() : TriggerSkill("ranshang")
    {
        events << EventPhaseStart << Damaged;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature != DamageStruct::Fire) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            //player->gainMark("@rsran", damage.damage);
            player->gainMark("&rsran", damage.damage);
        } else {
            if (player->getPhase() != Player::Finish || player->getMark("&rsran") <= 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->loseHp(player, player->getMark("&rsran"));
        }
        return false;
    }
};

class Hanyong : public TriggerSkill
{
public:
    Hanyong() : TriggerSkill("hanyong")
    {
        events << CardUsed << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            if (!player->hasSkill(this)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("ArcheryAttack") && !use.card->isKindOf("SavageAssault")) return false;
            if (player->getHp() >= room->getTag("TurnLengthCount").toInt()) return false;
            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(objectName());
            room->setCardFlag(use.card, "hanyong");
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->hasFlag(objectName()) || damage.to->isDead()) return false;
            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class TenyearRanshang : public TriggerSkill
{
public:
    TenyearRanshang() : TriggerSkill("tenyearranshang")
    {
        events << EventPhaseStart << Damaged;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature != DamageStruct::Fire) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&rsran", damage.damage);
        } else {
            if (player->getPhase() != Player::Finish) return false;
            int mark = player->getMark("&rsran");
            if (mark <= 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->loseHp(player, mark);
            if (player->isDead()) return false;
            //int lose = qMin(2, player->getMaxHp());
            //if (lose <= 0) return false;
            if (mark <= 2) return false;
            room->loseMaxHp(player, 2);
            if (player->isDead()) return false;
            player->drawCards(2, objectName());
        }
        return false;
    }
};

class TenyearHanyong : public TriggerSkill
{
public:
    TenyearHanyong() : TriggerSkill("tenyearhanyong")
    {
        events << CardUsed << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            if (!player->hasSkill(this)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("ArcheryAttack") && !use.card->isKindOf("SavageAssault") &&
                    !(use.card->objectName() == "slash" && use.card->getSuit() == Card::Spade)) return false;
            if (!player->isWounded()) return false;
            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(objectName());
            room->setCardFlag(use.card, "tenyearhanyong");
            if (player->getHp() <= room->getTag("TurnLengthCount").toInt()) return false;
            player->gainMark("&rsran");
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->hasFlag(objectName()) || damage.to->isDead()) return false;
            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
   }
};

class Langxi : public PhaseChangeSkill
{
public:
    Langxi() : PhaseChangeSkill("langxi")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHp() <= player->getHp())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@langxi-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        int n = qrand() % 3;
        if (n == 0) {
            LogMessage log;
            log.type = "#Damage";
            log.from = player;
            log.to << target;
            log.arg = QString::number(n);
            log.arg2 = "normal_nature";
            room->sendLog(log);
            return false;
        }
        room->damage(DamageStruct(objectName(), player, target, n));
        return false;
    }
};

class Yisuan : public TriggerSkill
{
public:
    Yisuan() : TriggerSkill("yisuan")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play || player->getMark("yisuan-PlayClear") > 0) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DiscardPile || !move.from || move.from != player) return false;
        if ((move.from_places.contains(Player::PlaceTable) && (move.reason.m_reason == CardMoveReason::S_REASON_USE ||
          move.reason.m_reason == CardMoveReason::S_REASON_LETUSE))) {
            const Card *card = move.reason.m_extraData.value<const Card *>();
            if (!card || !card->isKindOf("TrickCard")) return false;
            player->tag["yisuanForAI"] = QVariant::fromValue(card);
            bool invoke = player->askForSkillInvoke(this, QString("yisuan_invoke:%1").arg(card->objectName()));
            player->tag.remove("yisuanForAI");
            if (!invoke) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "yisuan-PlayClear");
            room->loseMaxHp(player);
            if (player->isDead()) return false;
            room->obtainCard(player, card, true);
        }
        return false;
    }
};

class Xingluan : public TriggerSkill
{
public:
    Xingluan(const QString &xingluan) : TriggerSkill(xingluan), xingluan(xingluan)
    {
        events << CardFinished;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play || player->getMark(xingluan + "-PlayClear") > 0) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || use.to.length() != 1) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, xingluan + "-PlayClear");
        QList<int> ids;
        foreach (int id, room->getDrawPile()) {
            if (Sanguosha->getCard(id)->getNumber() == 6)
                ids << id;
        }
        if (ids.isEmpty()) {
            if (xingluan == "xingluan") {
                LogMessage log;
                log.type = "#XingluanNoSix";
                log.arg = QString::number(6);
                room->sendLog(log);
            } else if (xingluan == "tenyearxingluan")
                player->drawCards(6, xingluan);
            return false;
        }
        int id = ids.at(qrand() % ids.length());
        room->obtainCard(player, id, true);
        return false;
    }
private:
    QString xingluan;
};

TanbeiCard::TanbeiCard()
{
}

void TanbeiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead()) return;
    Room *room = effect.from->getRoom();
    QStringList choices;
    if (!effect.to->isAllNude())
        choices << "get";
    choices << "nolimit";

    QString choice = room->askForChoice(effect.to, "tanbei", choices.join("+"), QVariant::fromValue(effect.from));
    if (choice == "get") {
        const Card *c = effect.to->getCards("hej").at(qrand() % effect.to->getCards("hej").length());
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
        room->obtainCard(effect.from, c, reason, room->getCardPlace(c->getEffectiveId()) != Player::PlaceHand);
        room->addPlayerMark(effect.from, "tanbei_pro_from-Clear");
        room->addPlayerMark(effect.to, "tanbei_pro_to-Clear");
    } else {
        room->addPlayerMark(effect.from, "tanbei_from-Clear");
        room->addPlayerMark(effect.to, "tanbei_to-Clear");
    }
}

class Tanbei : public ZeroCardViewAsSkill
{
public:
    Tanbei() : ZeroCardViewAsSkill("tanbei")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TanbeiCard");
    }

    const Card *viewAs() const
    {
        return new TanbeiCard;
    }
};


class TanbeiTargetMod : public TargetModSkill
{
public:
    TanbeiTargetMod() : TargetModSkill("#tanbei-target")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("tanbei_from-Clear") > 0 && to && to->getMark("tanbei_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("tanbei_from-Clear") > 0 && to && to->getMark("tanbei_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

class TanbeiPro : public ProhibitSkill
{
public:
    TanbeiPro() : ProhibitSkill("#tanbei-pro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from->getMark("tanbei_pro_from-Clear") > 0 && to->getMark("tanbei_pro_to-Clear") > 0 && !card->isKindOf("SkillCard");
    }
};

SidaoCard::SidaoCard()
{
    mute = true;
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodUse;
}

void SidaoCard::onUse(Room *, const CardUseStruct &) const
{
}

class SidaoVS : public OneCardViewAsSkill
{
public:
    SidaoVS() : OneCardViewAsSkill("sidao")
    {
        response_pattern = "@@sidao";
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        if (to_select->isEquipped()) return false;
        QString name = Self->property("sidao_target").toString();
        const Player *to = NULL;
        foreach (const Player *p, Self->getAliveSiblings()) {
            if (p->objectName() == name) {
                to = p;
                break;
            }
        }
        if (!to) return false;
        Snatch *snatch = new Snatch(to_select->getSuit(), to_select->getNumber());
        snatch->setSkillName("sidao");
        snatch->addSubcard(to_select);
        snatch->deleteLater();
        return snatch->targetFilter(QList<const Player *>(), to, Self) && !Self->isLocked(snatch) && !Self->isProhibited(to, snatch);
    }

    const Card *viewAs(const Card *originalcard) const
    {
        SidaoCard *c = new SidaoCard;
        c->addSubcard(originalcard);
        return c;
    }
};

class Sidao : public TriggerSkill
{
public:
    Sidao() : TriggerSkill("sidao")
    {
        events << CardFinished;
        view_as_skill = new SidaoVS;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.from->isDead() || use.card->isKindOf("SkillCard")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (p == use.from || p->isDead()) continue;
            room->addPlayerMark(p, "sidao_" + use.from->objectName() + "-PlayClear");
            if (!p->isAllNude() && p->getMark("sidao_" + use.from->objectName() + "-PlayClear") == 2 && use.from->hasSkill(this) &&
                    use.from->getMark("sidao-PlayClear") <= 0) {
                room->setPlayerProperty(use.from, "sidao_target", p->objectName());
                const Card *c = room->askForUseCard(use.from, "@@sidao", "@sidao:" + p->objectName());
                if (!c) {
                    room->setPlayerProperty(use.from, "sidao_target", QString());
                    continue;
                }
                room->setPlayerProperty(use.from, "sidao_target", QString());
                room->addPlayerMark(use.from, "sidao-PlayClear");
                c = Sanguosha->getCard(c->getSubcards().first());
                Snatch *snatch = new Snatch(c->getSuit(), c->getNumber());
                snatch->setSkillName("sidao");
                snatch->addSubcard(c);
                snatch->deleteLater();
                room->useCard(CardUseStruct(snatch, use.from, p), true);
            }
        }
        return false;
    }
};

class SidaoTargetMod : public TargetModSkill
{
public:
    SidaoTargetMod() : TargetModSkill("#sidao-target")
    {
        frequency = NotFrequent;
        pattern = "Snatch";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->getSkillName() == "sidao")
            return 1000;
        else
            return 0;
    }
};

JianjieCard::JianjieCard()
{
    mute = true;
}

bool JianjieCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
        if (targets.isEmpty())
            return to_select->getMark("&dragon_signet") > 0 || to_select->getMark("&phoenix_signet") > 0;
        else if (targets.length() == 1)
            return true;
        else
            return false;
    }
    return targets.length() < 2;
}

bool JianjieCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void JianjieCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();

    room->broadcastSkillInvoke("jianjie");

    LogMessage log;
    log.from = card_use.from;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    thread->trigger(CardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void JianjieCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
        QStringList choices;
        if (targets.first()->getMark("&dragon_signet") > 0)
            choices << "dragon";
        if (targets.first()->getMark("&phoenix_signet") > 0)
            choices << "phoenix";
        if (choices.isEmpty()) return;
        QString choice = room->askForChoice(source, "jianjie", choices.join("+"), QVariant::fromValue(targets.first()));
        QString mark = "&" + choice + "_signet";
        int n = targets.first()->getMark(mark);
        if (n > 0) {
            targets.first()->loseAllMarks(mark);
            targets.last()->gainMark(mark, n);
            return;
        }
    }
    targets.first()->gainMark("&dragon_signet");
    targets.last()->gainMark("&phoenix_signet");
}

class JianjieVS : public ZeroCardViewAsSkill
{
public:
    JianjieVS() : ZeroCardViewAsSkill("jianjie")
    {
        response_pattern = "@@jianjie!";
    }

    const Card *viewAs() const
    {
        return new JianjieCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JianjieCard") && player->getMark("jianjie_Round-Keep") > 1;
    }
};

class Jianjie : public TriggerSkill
{
public:
    Jianjie() : TriggerSkill("jianjie")
    {
        events << EventPhaseStart << Death << MarkChanged << TurnStart;
        view_as_skill = new JianjieVS;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TurnStart) {
            if (!player->faceUp()) return false;
            if (player->getMark("jianjie_Round-Keep") >= 2) return false;
            room->addPlayerMark(player, "jianjie_Round-Keep");
        }
        else if (event == EventPhaseStart) {
            if (player->isDead()) return false;
            if (player->getPhase() != Player::Start || player->getMark("jianjie-Keep") > 0) return false;
            room->addPlayerMark(player, "jianjie-Keep");
            if (!player->hasSkill(this)) return false;
            if (room->askForUseCard(player, "@@jianjie!", "@jianjie")) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            ServerPlayer *first = room->getAlivePlayers().at(qrand() % room->getAlivePlayers().length());
            ServerPlayer *second = room->getOtherPlayers(first).at(qrand() % room->getOtherPlayers(first).length());
            room->doAnimate(1, player->objectName(), first->objectName());
            room->doAnimate(1, player->objectName(), second->objectName());
            first->gainMark("&dragon_signet");
            second->gainMark("&phoenix_signet");
        } else if (event == Death) {
            if (!player->hasSkill(this)) return false;
            DeathStruct death = data.value<DeathStruct>();
            int dragon = death.who->getMark("&dragon_signet");
            int phoenix = death.who->getMark("&phoenix_signet");
            if (dragon > 0) {
                ServerPlayer *to = room->askForPlayerChosen(player, room->getAlivePlayers(), "jianjie_dragon", "@jianjie-dragon", true, true);
                if (!to) return false;
                room->broadcastSkillInvoke(objectName());
                death.who->loseAllMarks("&dragon_signet");
                to->gainMark("&dragon_signet", dragon);
            }
            if (phoenix > 0) {
                ServerPlayer *to = room->askForPlayerChosen(player, room->getAlivePlayers(), "jianjie_phoenix", "@jianjie-phoenix", true, true);
                if (!to) return false;
                room->broadcastSkillInvoke(objectName());
                death.who->loseAllMarks("&phoenix_signet");
                to->gainMark("&phoenix_signet", phoenix);
            }
        } else {
            MarkStruct mark = data.value<MarkStruct>();
            int dragon = player->getMark("&dragon_signet");
            int phoenix = player->getMark("&phoenix_signet");
            if (mark.name == "&dragon_signet") {
                if (dragon > 0 && phoenix > 0)
                    room->handleAcquireDetachSkills(player, "jianjiehuoji|jianjieyeyan", false, false);
                else if (dragon > 0)
                    room->handleAcquireDetachSkills(player, "jianjiehuoji", false, false);
                if (dragon <= 0)
                    room->handleAcquireDetachSkills(player, "-jianjiehuoji|-jianjieyeyan", true, false);
            } else if (mark.name == "&phoenix_signet") {
                if (dragon > 0 && phoenix > 0)
                    room->handleAcquireDetachSkills(player, "jianjielianhuan|jianjieyeyan", false, false);
                else if (phoenix > 0)
                    room->handleAcquireDetachSkills(player, "jianjielianhuan", false, false);
                if (phoenix <= 0)
                    room->handleAcquireDetachSkills(player, "-jianjielianhuan|-jianjieyeyan", true, false);
            }
        }
        return false;
    }
};

JianjieHuojiCard::JianjieHuojiCard()
{
    will_throw = false;
    handling_method = Card::MethodUse;
}

bool JianjieHuojiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    FireAttack *fire_attack = new FireAttack(card->getSuit(), card->getNumber());
    fire_attack->addSubcard(card);
    fire_attack->setSkillName("jianjiehuoji");
    fire_attack->deleteLater();
    if (Self->isLocked(fire_attack)) return false;
    return fire_attack->targetFilter(targets, to_select, Self);
}

void JianjieHuojiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    FireAttack *fire_attack = new FireAttack(card->getSuit(), card->getNumber());
    fire_attack->addSubcard(card);
    fire_attack->setSkillName("jianjiehuoji");
    fire_attack->deleteLater();
    room->useCard(CardUseStruct(fire_attack, card_use.from, card_use.to));
}

class JianjieHuoji : public OneCardViewAsSkill
{
public:
    JianjieHuoji() : OneCardViewAsSkill("jianjiehuoji")
    {
        filter_pattern = ".|red";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        FireAttack *fire_attack = new FireAttack(Card::NoSuit, 0);
        fire_attack->setSkillName("jianjiehuoji");
        fire_attack->deleteLater();
        return player->usedTimes("JianjieHuojiCard") < 3 && !player->isLocked(fire_attack);
    }

    const Card *viewAs(const Card *originalcard) const
    {
        JianjieHuojiCard *card = new JianjieHuojiCard;
        card->addSubcard(originalcard->getId());
        return card;
    }
};

JianjieLianhuanCard::JianjieLianhuanCard()
{
    will_throw = false;
    handling_method = Card::MethodUse;
    can_recast = true;
}

bool JianjieLianhuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    IronChain *iron_chain = new IronChain(card->getSuit(), card->getNumber());
    iron_chain->addSubcard(card);
    iron_chain->setSkillName("jianjielianhuan");
    iron_chain->deleteLater();
    if (Self->isLocked(iron_chain)) return false;
    return iron_chain->targetFilter(targets, to_select, Self);
}

bool JianjieLianhuanCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    IronChain *iron_chain = new IronChain(card->getSuit(), card->getNumber());
    iron_chain->addSubcard(card);
    iron_chain->setSkillName("jianjielianhuan");
    iron_chain->deleteLater();
    return iron_chain->targetsFeasible(targets, Self);
}

void JianjieLianhuanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    IronChain *iron_chain = new IronChain(card->getSuit(), card->getNumber());
    iron_chain->addSubcard(card);
    iron_chain->setSkillName("jianjielianhuan");
    iron_chain->deleteLater();

    if (card_use.to.isEmpty()) {
        CardMoveReason reason(CardMoveReason::S_REASON_RECAST, card_use.from->objectName());
        reason.m_skillName = this->getSkillName();
        QList<int> ids = getSubcards();
        QList<CardsMoveStruct> moves;
        foreach (int id, ids) {
            CardsMoveStruct move(id, NULL, Player::DiscardPile, reason);
            moves << move;
        }
        room->moveCardsAtomic(moves, true);
        card_use.from->broadcastSkillInvoke("@recast");

        LogMessage log;
        log.type = "#UseCard_Recast";
        log.from = card_use.from;
        log.card_str = iron_chain->toString();
        room->sendLog(log);

        card_use.from->drawCards(1, "recast");
        return;
    }
    room->useCard(CardUseStruct(iron_chain, card_use.from, card_use.to));
}

class JianjieLianhuan : public OneCardViewAsSkill
{
public:
    JianjieLianhuan() : OneCardViewAsSkill("jianjielianhuan")
    {
        filter_pattern = ".|club";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        IronChain *iron_chain = new IronChain(Card::NoSuit, 0);
        iron_chain->setSkillName("jianjielianhuan");
        iron_chain->deleteLater();
        return player->usedTimes("JianjieLianhuanCard") < 3 && !player->isLocked(iron_chain) &&
                !player->isCardLimited(iron_chain, Card::MethodRecast);
    }

    const Card *viewAs(const Card *originalcard) const
    {
        JianjieLianhuanCard *card = new JianjieLianhuanCard;
        card->addSubcard(originalcard->getId());
        return card;
    }
};

void JianjieYeyanCard::damage(ServerPlayer *shenzhouyu, ServerPlayer *target, int point) const
{
    shenzhouyu->getRoom()->damage(DamageStruct("jianjieyeyan", shenzhouyu, target, point, DamageStruct::Fire));
}

GreatJianjieYeyanCard::GreatJianjieYeyanCard()
{
    mute = true;
    m_skillName = "jianjieyeyan";
}

bool GreatJianjieYeyanCard::targetFilter(const QList<const Player *> &, const Player *, const Player *) const
{
    Q_ASSERT(false);
    return false;
}

bool GreatJianjieYeyanCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    if (subcards.length() != 4) return false;
    QList<Card::Suit> allsuits;
    foreach (int cardId, subcards) {
        const Card *card = Sanguosha->getCard(cardId);
        if (allsuits.contains(card->getSuit())) return false;
        allsuits.append(card->getSuit());
    }

    //We can only assign 2 damage to one player
    //If we select only one target only once, we assign 3 damage to the target
    if (targets.toSet().size() == 1)
        return true;
    else if (targets.toSet().size() == 2)
        return targets.size() == 3;
    return false;
}

bool GreatJianjieYeyanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select,
    const Player *, int &maxVotes) const
{
    int i = 0;
    foreach(const Player *player, targets)
        if (player == to_select) i++;
    maxVotes = qMax(3 - targets.size(), 0) + i;
    return maxVotes > 0;
}

void GreatJianjieYeyanCard::use(Room *room, ServerPlayer *shenzhouyu, QList<ServerPlayer *> &targets) const
{
    int criticaltarget = 0;
    int totalvictim = 0;
    QMap<ServerPlayer *, int> map;

    foreach(ServerPlayer *sp, targets)
        map[sp]++;

    if (targets.size() == 1)
        map[targets.first()] += 2;

    foreach (ServerPlayer *sp, map.keys()) {
        if (map[sp] > 1) criticaltarget++;
        totalvictim++;
    }
    if (criticaltarget > 0) {
        room->broadcastSkillInvoke("jianjieyeyan");
        shenzhouyu->loseAllMarks("&dragon_signet");
        shenzhouyu->loseAllMarks("&phoenix_signet");
        room->doSuperLightbox("simahui", "jianjieyeyan");
        room->loseHp(shenzhouyu, 3);

        QList<ServerPlayer *> targets = map.keys();
        room->sortByActionOrder(targets);
        foreach(ServerPlayer *sp, targets)
            damage(shenzhouyu, sp, map[sp]);
    }
}

SmallJianjieYeyanCard::SmallJianjieYeyanCard()
{
    mute = true;
    m_skillName = "jianjieyeyan";
}

bool SmallJianjieYeyanCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return !targets.isEmpty();
}

bool SmallJianjieYeyanCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.length() < 3;
}

void SmallJianjieYeyanCard::use(Room *room, ServerPlayer *shenzhouyu, QList<ServerPlayer *> &targets) const
{
    room->broadcastSkillInvoke("jianjieyeyan");
    shenzhouyu->loseAllMarks("&dragon_signet");
    shenzhouyu->loseAllMarks("&phoenix_signet");
    room->doSuperLightbox("simahui", "jianjieyeyan");
    Card::use(room, shenzhouyu, targets);
}

void SmallJianjieYeyanCard::onEffect(const CardEffectStruct &effect) const
{
    damage(effect.from, effect.to, 1);
}

class JianjieYeyan : public ViewAsSkill
{
public:
    JianjieYeyan() : ViewAsSkill("jianjieyeyan")
    {
        frequency = Limited;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("&dragon_signet") > 0 && player->getMark("&phoenix_signet") > 0;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() >= 4)
            return false;

        if (to_select->isEquipped())
            return false;

        if (Self->isJilei(to_select))
            return false;

        foreach (const Card *item, selected) {
            if (to_select->getSuit() == item->getSuit())
                return false;
        }

        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() == 0)
            return new SmallJianjieYeyanCard;
        if (cards.length() != 4)
            return NULL;

        GreatJianjieYeyanCard *card = new GreatJianjieYeyanCard;
        card->addSubcards(cards);

        return card;
    }
};

class Chenghao : public MasochismSkill
{
public:
    Chenghao() : MasochismSkill("chenghao")
    {
        frequency = Frequent;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (damage.nature == DamageStruct::Normal) return;
            if (player->isDead() || !player->isChained() || damage.chain) return;
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (!p->askForSkillInvoke(this)) continue;
            room->broadcastSkillInvoke(objectName());

            QList<ServerPlayer *> _player;
            _player.append(p);
            int n = 0;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isChained())
                    n++;
            }
            if (n <= 0) return;

            QList<int> ids = room->getNCards(n, false);
            CardsMoveStruct move(ids, NULL, p, Player::PlaceTable, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_PREVIEW, p->objectName(), objectName(), QString()));
            QList<CardsMoveStruct> moves;
            moves.append(move);
            room->notifyMoveCards(true, moves, false, _player);
            room->notifyMoveCards(false, moves, false, _player);

            QList<int> origin_ids = ids;
            while (room->askForYiji(p, ids, objectName(), true, false, true, -1, room->getAlivePlayers())) {
                CardsMoveStruct move(QList<int>(), p, NULL, Player::PlaceHand, Player::PlaceTable,
                    CardMoveReason(CardMoveReason::S_REASON_PREVIEW, p->objectName(), objectName(), QString()));
                foreach (int id, origin_ids) {
                    if (room->getCardPlace(id) != Player::DrawPile) {
                        move.card_ids << id;
                        ids.removeOne(id);
                    }
                }
                origin_ids = ids;
                QList<CardsMoveStruct> moves;
                moves.append(move);
                room->notifyMoveCards(true, moves, false, _player);
                room->notifyMoveCards(false, moves, false, _player);
                if (!p->isAlive())
                    break;
            }

            if (!ids.isEmpty()) {
                if (p->isAlive()) {
                    CardsMoveStruct move(ids, p, NULL, Player::PlaceHand, Player::PlaceTable,
                                         CardMoveReason(CardMoveReason::S_REASON_PREVIEW, p->objectName(), objectName(), QString()));
                    QList<CardsMoveStruct> moves;
                    moves.append(move);
                    room->notifyMoveCards(true, moves, false, _player);
                    room->notifyMoveCards(false, moves, false, _player);

                    DummyCard *dummy = new DummyCard(ids);
                    p->obtainCard(dummy, false);
                    delete dummy;
                } else {
                    DummyCard *dummy = new DummyCard(ids);
                    CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, p->objectName(), objectName(), QString());
                    room->throwCard(dummy, reason, NULL);
                    delete dummy;
                }

            }
        }
    }
};

class Yinshi : public TriggerSkill
{
public:
    Yinshi() : TriggerSkill("yinshi")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.nature != DamageStruct::Normal || (damage.card && damage.card->isKindOf("TrickCard"))) {
            if (player->getMark("&dragon_signet") > 0 || player->getMark("&phoenix_signet") > 0 || player->getEquip(1)) return false;
            LogMessage log;
            log.type = "#YinshiPrevent";
            log.from = player;
            log.arg = objectName();
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
            return true;
        }
        return false;
    }
};

class SpFenxin : public TriggerSkill
{
public:
    SpFenxin() : TriggerSkill("spfenxin")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who == player) return false;
        QString role = death.who->getRole();
        if (player->getMark("jieyuan_" + role + "-Keep") > 0) return false;
        room->addPlayerMark(player, "jieyuan_" + role + "-Keep");
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        return false;
    }
};

class Xiying : public TriggerSkill
{
public:
    Xiying(const QString &xiying) : TriggerSkill(xiying), xiying(xiying)
    {
        events << EventPhaseStart << Death << EventPhaseChanging << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseStart)
            return TriggerSkill::getPriority(event);
        return 5;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (xiying == "secondxiying" && player->isAlive() && player->getPhase() == Player::Finish) {
                int mark = player->getMark("secondxiying_damage-Clear");
                for (int i = 0; i < mark; i++) {
                    QList<int> ids;
                    foreach (int id, room->getDrawPile()) {
                        const Card *card = Sanguosha->getCard(id);
                        if (card->isKindOf("Slash") || (card->isDamageCard() && card->isNDTrick()))
                            ids << id;
                    }
                    if (ids.isEmpty()) {
                        LogMessage log;
                        log.type = "#SecondXiyingFail";
                        log.arg = objectName();
                        log.from = player;
                        room->sendLog(log);
                        room->notifySkillInvoked(player, objectName());
                        room->broadcastSkillInvoke(this);
                        break;
                    } else {
                        room->sendCompulsoryTriggerLog(player, this);
                        int id = ids.at(qrand() % ids.length());
                        room->obtainCard(player, id, true);
                    }
                }
            }

            if (!player->isAlive() || !player->hasSkill(this) || player->getPhase() != Player::Play) return false;
            if (!player->canDiscard(player, "h")) return false;
            if (!room->askForCard(player, "EquipCard,TrickCard|.|.|hand", xiying + "-invoke", data, objectName())) return false;
            room->addPlayerMark(player, xiying + "_used-PlayClear");
            room->broadcastSkillInvoke(objectName());
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!room->askForDiscard(p, objectName(), 1, 1, true, true, xiying + "-discard")) {
                    LogMessage log;
                    log.type = "#XiyingEffect";
                    log.from = p;
                    room->sendLog(log);
                    room->setPlayerCardLimitation(p, "use,response", ".", true);
                    room->addPlayerMark(p, xiying + "_limit-Clear");
                }
            }
        } else if (event == EventPhaseEnd) {
            if (xiying != "secondxiying" || player->isDead() || player->getPhase() != Player::Play) return false;
            if (player->getMark("secondxiying_used-PlayClear") <= 0 || player->getMark("damage_point_play_phase") <= 0) return false;
            room->setPlayerMark(player, "secondxiying_used-PlayClear", 0);
            room->addPlayerMark(player, "secondxiying_damage-Clear");
        } else {
            if (event == Death) {
                DeathStruct death = data.value<DeathStruct>();
                if (death.who != player || (room->getCurrent() && player != room->getCurrent())) return false;
            } else {
                PhaseChangeStruct change = data.value<PhaseChangeStruct>();
                if (change.to != Player::NotActive) return false;
            }
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                int mark = p->getMark(xiying + "_limit-Clear");
                room->setPlayerMark(p, xiying + "_limit-Clear", 0);
                for (int i = 0; i < mark; i++)
                    room->removePlayerCardLimitation(p, "use,response", ".$1");
            }
        }
        return false;
    }
private:
    QString xiying;
};

LuanzhanCard::LuanzhanCard()
{
    mute = true;
}

bool LuanzhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int n = Self->getMark("luanzhan_target_num-Clear");
    return targets.length() < n && to_select->hasFlag("luanzhan_canchoose");
}

void LuanzhanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "luanzhan_extratarget");
}

class LuanzhanVS : public ZeroCardViewAsSkill
{
public:
    LuanzhanVS() : ZeroCardViewAsSkill("luanzhan")
    {
        response_pattern = "@@luanzhan";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        if (Self->hasFlag("luanzhan_now_use_collateral"))
            return new ExtraCollateralCard;
        else
            return new LuanzhanCard;
    }
};

class Luanzhan : public TriggerSkill
{
public:
    Luanzhan() : TriggerSkill("luanzhan")
    {
        events << TargetSpecified << PreCardUsed;
        view_as_skill = new LuanzhanVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (event == PreCardUsed) {
            int n = player->getMark("&luanzhanMark") + player->getMark("luanzhanMark");
            if (n <= 0) return false;
            if (use.card->isKindOf("SkillCard")) return false;
            if (!use.card->isKindOf("Slash") && !(use.card->isBlack() && use.card->isNDTrick())) return false;
            if (use.card->isKindOf("Nullification")) return false;
            if (!use.card->isKindOf("Collateral") && use.card->targetFixed()) {
                bool canextra = false;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (use.card->isKindOf("AOE") && p == player) continue;
                    if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                    canextra = true;
                    room->setPlayerFlag(p, "luanzhan_canchoose");
                }
                if (canextra == false) return false;
                room->addPlayerMark(player, "luanzhan_target_num-Clear", n);
                player->tag["luanzhanData"] = data;
                if (!room->askForUseCard(player, "@@luanzhan", QString("@luanzhan:%1::%2").arg(use.card->objectName()).arg(QString::number(n)))) {
                    player->tag.remove("luanzhanData");
                    room->setPlayerMark(player, "luanzhan_target_num-Clear", 0);
                    return false;
                }
                player->tag.remove("luanzhanData");
                room->setPlayerMark(player, "luanzhan_target_num-Clear", 0);
                QList<ServerPlayer *> add;
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("luanzhan_canchoose"))
                        room->setPlayerFlag(p, "-luanzhan_canchoose");
                    if (p->hasFlag("luanzhan_extratarget")) {
                        room->setPlayerFlag(p,"-luanzhan_extratarget");
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
                log.arg = "luanzhan";
                room->sendLog(log);
                foreach(ServerPlayer *p, add)
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
            } else if (use.card->isKindOf("Collateral")) {
                for (int i = 1; i <= n; i++) {
                    bool canextra = false;
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                        if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                            canextra = true;
                            break;
                        }
                    }
                    if (canextra == false) break;
                    QStringList toss;
                    QString tos;
                    foreach(ServerPlayer *t, use.to)
                        toss.append(t->objectName());
                    tos = toss.join("+");
                    room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", tos);
                    room->setPlayerFlag(player, "luanzhan_now_use_collateral");
                    room->askForUseCard(player, "@@luanzhan", QString("@luanzhan:%1::%2").arg(use.card->objectName()).arg(QString::number(n)));
                    room->setPlayerFlag(player, "-luanzhan_now_use_collateral");
                    room->setPlayerProperty(player, "extra_collateral", QString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", QString());
                    foreach(ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("ExtraCollateralTarget")) {
                            room->setPlayerFlag(p, "-ExtraCollateralTarget");
                            LogMessage log;
                            log.type = "#QiaoshuiAdd";
                            log.from = player;
                            log.to << p;
                            log.card_str = use.card->toString();
                            log.arg = "luanzhan";
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
            if (!use.card->isKindOf("Slash") && !(use.card->isBlack() && use.card->isNDTrick())) return false;
            int n = player->getMark("&luanzhanMark") + player->getMark("luanzhanMark");
            int length = use.to.length();
            if (length < n) {
                room->setPlayerMark(player, "&luanzhanMark", 0);
                room->setPlayerMark(player, "luanzhanMark", 0);
            }
        }
        return false;
    }
};

class LuanzhanTargetMod : public TargetModSkill
{
public:
    LuanzhanTargetMod() : TargetModSkill("#luanzhan-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (from->hasSkill("luanzhan") && (card->isKindOf("Slash") || (card->isBlack() && card->isNDTrick())))
            return from->getMark("&luanzhanMark") + from->getMark("luanzhanMark");
        else
            return 0;
    }
};

class LuanzhanMark : public TriggerSkill
{
public:
    LuanzhanMark() : TriggerSkill("#luanzhan-mark")
    {
        events << PreDamageDone;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->isAlive()) {
            if (damage.from->hasSkill("luanzhan", true) || damage.from->hasSkill("olluanzhan", true))
                room->addPlayerMark(damage.from, "&luanzhanMark");
            else
                room->addPlayerMark(damage.from, "luanzhanMark");
        }
        if (damage.to && damage.to->isAlive()) {
            if (damage.to->hasSkill("olluanzhan", true))
                room->addPlayerMark(damage.to, "&luanzhanMark");
            else
                room->addPlayerMark(damage.to, "olluanzhanMark");
        }
        return false;
    }
};

OLLuanzhanCard::OLLuanzhanCard()
{
    mute = true;
}

bool OLLuanzhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int n = Self->getMark("olluanzhan_target_num-Clear");
    return targets.length() < n && to_select->hasFlag("olluanzhan_canchoose");
}

void OLLuanzhanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "olluanzhan_extratarget");
}

class OLLuanzhanVS : public ZeroCardViewAsSkill
{
public:
    OLLuanzhanVS() : ZeroCardViewAsSkill("olluanzhan")
    {
        response_pattern = "@@olluanzhan";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        if (Self->hasFlag("olluanzhan_now_use_collateral"))
            return new ExtraCollateralCard;
        else
            return new OLLuanzhanCard;
    }
};

class OLLuanzhan : public TriggerSkill
{
public:
    OLLuanzhan() : TriggerSkill("olluanzhan")
    {
        events << TargetSpecified << PreCardUsed;
        view_as_skill = new OLLuanzhanVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (event == PreCardUsed) {
            int n = player->getMark("&luanzhanMark") + player->getMark("luanzhanMark") + player->getMark("olluanzhanMark");
            if (n <= 0) return false;
            if (use.card->isKindOf("SkillCard")) return false;
            if (!use.card->isKindOf("Slash") && !(use.card->isBlack() && use.card->isNDTrick())) return false;
            if (use.card->isKindOf("Nullification")) return false;
            if (!use.card->isKindOf("Collateral") && use.card->targetFixed()) {
                bool canextra = false;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (use.card->isKindOf("AOE") && p == player) continue;
                    if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                    canextra = true;
                    room->setPlayerFlag(p, "olluanzhan_canchoose");
                }
                if (canextra == false) return false;
                room->addPlayerMark(player, "olluanzhan_target_num-Clear", n);
                player->tag["olluanzhanData"] = data;
                if (!room->askForUseCard(player, "@@olluanzhan", QString("@luanzhan:%1::%2").arg(use.card->objectName()).arg(QString::number(n)))) {
                    player->tag.remove("olluanzhanData");
                    room->setPlayerMark(player, "olluanzhan_target_num-Clear", 0);
                    return false;
                }
                player->tag.remove("olluanzhanData");
                room->setPlayerMark(player, "olluanzhan_target_num-Clear", 0);
                QList<ServerPlayer *> add;
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("olluanzhan_canchoose"))
                        room->setPlayerFlag(p, "-olluanzhan_canchoose");
                    if (p->hasFlag("olluanzhan_extratarget")) {
                        room->setPlayerFlag(p,"-olluanzhan_extratarget");
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
                log.arg = "olluanzhan";
                room->sendLog(log);
                foreach(ServerPlayer *p, add)
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
            } else if (use.card->isKindOf("Collateral")) {
                for (int i = 1; i <= n; i++) {
                    bool canextra = false;
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                        if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                            canextra = true;
                            break;
                        }
                    }
                    if (canextra == false) break;
                    QStringList toss;
                    QString tos;
                    foreach(ServerPlayer *t, use.to)
                        toss.append(t->objectName());
                    tos = toss.join("+");
                    room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", tos);
                    room->setPlayerFlag(player, "olluanzhan_now_use_collateral");
                    room->askForUseCard(player, "@@olluanzhan", QString("@luanzhan:%1::%2").arg(use.card->objectName()).arg(QString::number(n)));
                    room->setPlayerFlag(player, "-olluanzhan_now_use_collateral");
                    room->setPlayerProperty(player, "extra_collateral", QString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", QString());
                    foreach(ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("ExtraCollateralTarget")) {
                            room->setPlayerFlag(p,"-ExtraCollateralTarget");
                            LogMessage log;
                            log.type = "#QiaoshuiAdd";
                            log.from = player;
                            log.to << p;
                            log.card_str = use.card->toString();
                            log.arg = "olluanzhan";
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
            if (!use.card->isKindOf("Slash") && !(use.card->isBlack() && use.card->isNDTrick())) return false;
            int n = player->getMark("&luanzhanMark") + player->getMark("luanzhanMark") + player->getMark("olluanzhanMark");
            int length = use.to.length();
            if (length < n) {
                room->setPlayerMark(player, "luanzhanMark", 0);
                room->setPlayerMark(player, "olluanzhanMark", 0);
                room->setPlayerMark(player, "&luanzhanMark", floor(n / 2));
            }
        }
        return false;
    }
};

class OLLuanzhanTargetMod : public TargetModSkill
{
public:
    OLLuanzhanTargetMod() : TargetModSkill("#olluanzhan-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (from->hasSkill("olluanzhan") && (card->isKindOf("Slash") || (card->isBlack() && card->isNDTrick())))
            return from->getMark("&luanzhanMark") + from->getMark("luanzhanMark") + from->getMark("olluanzhanMark");
        else
            return 0;
    }
};

NeifaCard::NeifaCard()
{
}

bool NeifaCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() >= 0 && targets.length() <= 1;
}

bool NeifaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getCardCount(true, true) > to_select->getHandcardNum();
}

void NeifaCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (targets.isEmpty())
        source->drawCards(2, "neifa");
    else {
        foreach (ServerPlayer *p, targets) {
            if (source->isDead()) return;
            if (p->isDead() || p->getCards("ej").isEmpty()) continue;
            int card_id = room->askForCardChosen(source, p, "ej", "neifa");
            room->obtainCard(source, card_id, true);
        }
    }
}

class NeifaVS : public ZeroCardViewAsSkill
{
public:
    NeifaVS() : ZeroCardViewAsSkill("neifa")
    {
    }

    const Card *viewAs() const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@neifa")
            return new NeifaCard;
        else
            return new ExtraCollateralCard;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@neifa");
    }
};

class Neifa : public TriggerSkill
{
public:
    Neifa() : TriggerSkill("neifa")
    {
        events << EventPhaseStart << CardUsed << PreCardUsed;
        view_as_skill = new NeifaVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            if (!room->askForUseCard(player, "@@neifa", "@neifa")) return false;
            if (player->isDead() || !player->canDiscard(player, "he")) return false;

            const Card *card = room->askForDiscard(player, objectName(), 1, 1, false, true);
            if (!card) return false;
            card = Sanguosha->getCard(card->getSubcards().first());

            if (card->isKindOf("BasicCard")) {
                room->setPlayerCardLimitation(player, "use", "TrickCard,EquipCard", true);
                int x = qMin(5, NeifaX(player));
                if (x <= 0) return false;
                room->addPlayerMark(player, "&neifa+basic-Clear", x);
                room->addSlashCishu(player, x);
                room->addSlashMubiao(player, 1);
            } else {
                room->setPlayerCardLimitation(player, "use", "BasicCard", true);
                room->setPlayerFlag(player, "neifa_not_basic");
                int x = qMin(5, NeifaX(player));
                if (x <= 0) return false;
                room->addPlayerMark(player, "&neifa+notbasic-Clear", x);
            }
        } else if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("EquipCard")) return false;

            int n = player->getMark("&neifa+notbasic-Clear");
            n = qMin(5, n);
            int mark = player->getMark("neifa_equip-Clear");
            room->addPlayerMark(player, "neifa_equip-Clear");
            if (n <= 0 || mark >= 2) return false;

            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->drawCards(n, objectName());
        } else {
            if (!player->hasFlag("neifa_not_basic")) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isNDTrick() || use.card->isKindOf("Nullification")) return false;

            QList<ServerPlayer *> ava;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (use.card->isKindOf("AOE") && p == use.from) continue;
                if (use.to.contains(p) || room->isProhibited(use.from, p, use.card)) continue;
                if (use.card->targetFixed())
                    ava << p;
                else {
                    if (use.card->targetFilter(QList<const Player *>(), p, use.from))
                        ava << p;
                }
            }

            QStringList choices;
            if (!ava.isEmpty())
                choices << "add";
            if (use.to.length() > 1)
                choices << "remove";
            if (choices.isEmpty()) return false;
            choices << "cancel";

            QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
            if (choice == "cancel") return false;

            if (!use.card->isKindOf("Collateral")) {
                if (choice == "add") {
                    ServerPlayer *target = room->askForPlayerChosen(player, ava, objectName(), "@neifa-add:" + use.card->objectName());
                    LogMessage log;
                    log.type = "#QiaoshuiAdd";
                    log.from = player;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = "neifa";
                    room->sendLog(log);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName());
                    use.to << target;
                    room->sortByActionOrder(use.to);
                } else {
                    ServerPlayer *target = room->askForPlayerChosen(player, use.to, objectName(), "@neifa-remove:" + use.card->objectName());
                    LogMessage log;
                    log.type = "#QiaoshuiRemove";
                    log.from = player;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = "neifa";
                    room->sendLog(log);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName());
                    use.to.removeOne(target);
                }
            } else {
                if (choice == "add") {
                    QStringList tos;
                    foreach(ServerPlayer *t, use.to)
                        tos.append(t->objectName());

                    room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", tos);
                    room->askForUseCard(player, "@@neifa!", "@neifa1:" + use.card->objectName(), 1);
                    room->setPlayerProperty(player, "extra_collateral", QString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", QString("+"));

                    bool extra = false;
                    foreach(ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("ExtraCollateralTarget")) {
                            room->setPlayerFlag(p,"-ExtraCollateralTarget");
                            extra = true;
                            LogMessage log;
                            log.type = "#QiaoshuiAdd";
                            log.from = player;
                            log.to << p;
                            log.card_str = use.card->toString();
                            log.arg = "neifa";
                            room->sendLog(log);
                            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                            room->notifySkillInvoked(player, objectName());
                            room->broadcastSkillInvoke(objectName());

                            use.to.append(p);
                            room->sortByActionOrder(use.to);
                            ServerPlayer *victim = p->tag["collateralVictim"].value<ServerPlayer *>();
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

                    if (!extra) {
                        ServerPlayer *target = ava.at(qrand() % ava.length());
                        QList<ServerPlayer *> victims;
                        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                            if (target->canSlash(p)
                                && (!(p == use.from && p->hasSkill("kongcheng") && p->isLastHandCard(use.card, true)))) {
                                victims << p;
                            }
                        }
                        Q_ASSERT(!victims.isEmpty());
                        ServerPlayer *victim = victims.at(qrand() % victims.length());
                        target->tag["collateralVictim"] = QVariant::fromValue(victim);
                        LogMessage log;
                        log.type = "#QiaoshuiAdd";
                        log.from = player;
                        log.to << target;
                        log.card_str = use.card->toString();
                        log.arg = "neifa";
                        room->sendLog(log);
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                        room->notifySkillInvoked(player, objectName());
                        room->broadcastSkillInvoke(objectName());

                        use.to.append(target);
                        room->sortByActionOrder(use.to);

                        LogMessage newlog;
                        newlog.type = "#CollateralSlash";
                        newlog.from = player;
                        newlog.to << victim;
                        room->sendLog(newlog);
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());
                    }
                } else {
                    ServerPlayer *target = room->askForPlayerChosen(player, use.to, objectName(), "@neifa-remove:" + use.card->objectName());
                    LogMessage log;
                    log.type = "#QiaoshuiRemove";
                    log.from = player;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = "neifa";
                    room->sendLog(log);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName());
                    use.to.removeOne(target);
                }
            }
            data = QVariant::fromValue(use);
        }
        return false;
    }
private:
    int NeifaX(ServerPlayer *player) const
    {
        int x = 0;
        foreach (const Card *c, player->getCards("h")) {
            if (!player->canUse(c))
                x++;
        }

        return x;
    }
};

FenglveCard::FenglveCard()
{
    target_fixed = true;
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
}

void FenglveCard::onUse(Room *, const CardUseStruct &) const
{
}

class FenglveVS : public ViewAsSkill
{
public:
    FenglveVS() : ViewAsSkill("fenglve")
    {
        expand_pile = "#fenglve";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QList<const Card *> hand = Self->getHandcards();
        QList<const Card *> equip = Self->getEquips();
        QList<int> judge = Self->getPile("#fenglve");
        int x = 0;
        if (!hand.isEmpty()) x++;
        if (!equip.isEmpty()) x++;
        if (!judge.isEmpty()) x++;
        if (selected.length() < x) {
            if (selected.isEmpty())
                return true;
            else if (selected.length() == 1) {
                if (hand.contains(selected.first()))
                    return !hand.contains(to_select);
                else if (equip.contains(selected.first()))
                    return !equip.contains(to_select);
                else
                    return !judge.contains(to_select->getEffectiveId());
            } else {
                if (Self->hasCard(selected.first()->getEffectiveId()) && Self->hasCard(selected.last()->getEffectiveId()))
                    return judge.contains(to_select->getEffectiveId());
                else if (hand.contains(selected.first()) && judge.contains(selected.last()->getEffectiveId()))
                    return equip.contains(to_select);
                else if (hand.contains(selected.last()) && judge.contains(selected.first()->getEffectiveId()))
                    return equip.contains(to_select);
                else if (equip.contains(selected.first()) && judge.contains(selected.last()->getEffectiveId()))
                    return hand.contains(to_select);
                else if (equip.contains(selected.last()) && judge.contains(selected.first()->getEffectiveId()))
                    return hand.contains(to_select);
            }
        }
        return false;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@fenglve!";
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        int x = 0;
        if (!Self->isKongcheng()) x++;
        if (!Self->getEquips().isEmpty()) x++;
        if (!Self->getPile("#fenglve").isEmpty()) x++;
        if (cards.length() != x) return NULL;

        FenglveCard *card = new FenglveCard;
        card->addSubcards(cards);
        return card;
    }
};

class Fenglve : public TriggerSkill
{
public:
    Fenglve() : TriggerSkill("fenglve")
    {
        events << EventPhaseStart << Pindian;
        view_as_skill = new FenglveVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (!player->canPindian(p)) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@fenglve-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            if (player->pindian(target, objectName())) {
                if (target->isAllNude()) return false;

                QList<int> judge_ids = target->getJudgingAreaID();

                if (!judge_ids.isEmpty())
                    room->notifyMoveToPile(target, judge_ids, objectName(), Player::PlaceDelayedTrick, true);

                const Card *c = room->askForUseCard(target, "@@fenglve!", "@fenglve:" + player->objectName());

                if (!judge_ids.isEmpty())
                    room->notifyMoveToPile(target, judge_ids, objectName(), Player::PlaceDelayedTrick, false);

                DummyCard *dummy = new DummyCard;
                if (!c) {
                    if (!target->isKongcheng())
                        dummy->addSubcard(target->getRandomHandCardId());
                    if (!target->getEquips().isEmpty())
                        dummy->addSubcard(target->getEquips().at(qrand() % target->getEquips().length()));
                    if (!judge_ids.isEmpty())
                        dummy->addSubcard(judge_ids.at(qrand() % judge_ids.length()));
                    if (dummy->subcardsLength() > 0) {
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "fenglve", QString());
                        room->obtainCard(player, dummy, reason, false);
                    }
                } else {
                    dummy->addSubcards(c->getSubcards());
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "fenglve", QString());
                    room->obtainCard(player, dummy, reason, false);
                }
                delete dummy;
            } else {
                if (player->isNude()) return false;
                const Card *card = room->askForExchange(player, objectName(), 1, 1, true, "fenglve-give:" + target->objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "fenglve", QString());
                room->obtainCard(target, card, reason, false);
            }
        } else {
            PindianStruct *pindian = data.value<PindianStruct *>();
            if (pindian->reason != objectName()) return false;
            /*const Card *card = NULL;
            ServerPlayer *target = NULL;
            if (pindian->from == player) {
                card = pindian->from_card;
                target = pindian->to;
            } else if (pindian->to == player) {
                card = pindian->to_card;
                target = pindian->from;
            }
            if (!card || !target || target->isDead()) return false;*/
            if (pindian->from != player) return false;
            if (pindian->to->isDead() || !room->CardInTable(pindian->from_card)) return false;
            if (!player->askForSkillInvoke(this, QString("fenglve_invoke:%1::%2").arg(pindian->to->objectName()).arg(pindian->from_card->objectName())))
                return false;
            room->broadcastSkillInvoke(objectName());
            room->obtainCard(pindian->to, pindian->from_card, true);
        }
        return false;
    }
};

MoushiCard::MoushiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void MoushiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    Room *room = effect.from->getRoom();
    QStringList names = effect.to->property("moushi_from").toStringList();
    if (!names.contains(effect.from->objectName())) {
        names << effect.from->objectName();
        room->setPlayerProperty(effect.to, "moushi_from", names);
    }
    room->setPlayerMark(effect.to, "&moushi", 1);
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "moushi", QString());
    room->obtainCard(effect.to, this, reason, false);
}

class MoushiVS : public OneCardViewAsSkill
{
public:
    MoushiVS() :OneCardViewAsSkill("moushi")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MoushiCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MoushiCard *c = new MoushiCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class Moushi : public TriggerSkill
{
public:
    Moushi() : TriggerSkill("moushi")
    {
        events << EventPhaseChanging << Death << Damage;
        view_as_skill = new MoushiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *current = room->getCurrent();
        if (event == EventPhaseChanging) {
            if (!current || current != player) return false;
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from != Player::Play) return false;
            room->setPlayerProperty(player, "moushi_from", QStringList());
            room->setPlayerMark(player, "&moushi", 0);
        } else if (event == Damage) {
            if (player->isDead() || !current || current != player || player->getPhase() != Player::Play) return false;
            QStringList names = player->property("moushi_from").toStringList();
            if (names.isEmpty()) return false;

            DamageStruct damage = data.value<DamageStruct>();
            if (player->getMark("moushi_" + damage.to->objectName() + "-Clear") > 0) return false;
            room->addPlayerMark(player, "moushi_" + damage.to->objectName() + "-Clear");

            QList<ServerPlayer *> xunchens;
            foreach (QString str, names) {
                ServerPlayer *xunchen = room->findPlayerByObjectName(str);
                if (xunchen && xunchen->isAlive() && xunchen->hasSkill(this))
                    xunchens << xunchen;
            }
            if (xunchens.isEmpty()) return false;

            room->sortByActionOrder(xunchens);
            foreach (ServerPlayer *p, xunchens) {
                if (p->isAlive() && p->hasSkill(this)) {
                    room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                    p->drawCards(1, objectName());
                }
            }
        } else {
            DeathStruct death = data.value<DeathStruct>();
            room->setPlayerProperty(death.who, "moushi_from", QStringList());
            room->setPlayerMark(death.who, "&moushi", 0);
        }
        return false;
    }
};

TenyearFenglveCard::TenyearFenglveCard()
{
}

bool TenyearFenglveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void TenyearFenglveCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from, *target = effect.to;
    if (!source->canPindian(target, false)) return;

    PindianStruct *pindian = source->PinDian(target, "fenglve");
    if (!pindian) return;

    Room *room = source->getRoom();
    if (pindian->success) {
        if (target->isDead() || target->isAllNude()) return;
        if (target->getCardCount(true, true) <= 2) {
            DummyCard *dummy = new DummyCard(target->getJudgingAreaID() + target->handCards() + target->getEquipsId());
            dummy->deleteLater();
            room->giveCard(target, source, dummy, "tenyearfenglve");
        } else {
            QList<int> judge_ids = target->getJudgingAreaID();

            if (!judge_ids.isEmpty())
                room->notifyMoveToPile(target, judge_ids, "tenyearfenglve", Player::PlaceDelayedTrick, true);

            const Card *c = room->askForUseCard(target, "@@tenyearfenglve!", "@tenyearfenglve:" + source->objectName());

            if (!judge_ids.isEmpty())
                room->notifyMoveToPile(target, judge_ids, "tenyearfenglve", Player::PlaceDelayedTrick, false);

            DummyCard *dummy = new DummyCard;
            dummy->deleteLater();

            if (!c) {
                QList<int> ids = target->getJudgingAreaID() + target->handCards() + target->getEquipsId();
                for (int i = 0; i < 2; i++) {
                    int id = ids.at(qrand() % ids.length());
                    ids.removeOne(id);
                    dummy->addSubcard(id);
                }
            } else
                dummy->addSubcards(c->getSubcards());

            if (dummy->subcardsLength() > 0)
               room->giveCard(target, source, dummy, "tenyearfenglve");
        }
    } else if (pindian->from_number == pindian->to_number) {
        LogMessage log;
        log.type = "#TenyearFenglvePingju";
        log.from = source;
        log.to << target;
        log.arg = "tenyearfenglve";
        room->sendLog(log);
        int used = source->usedTimes("TenyearFenglveCard");
        if (used == 0) return;
        room->addPlayerHistory(source, "TenyearFenglveCard", -used);
    } else {
        if (target->isAlive() && room->CardInPlace(pindian->from_card, Player::DiscardPile))
            room->obtainCard(target, pindian->from_card);
    }
}

TenyearFenglveGiveCard::TenyearFenglveGiveCard()
{
    handling_method = Card::MethodNone;
    mute = true;
    will_throw = false;
    target_fixed = true;
}

void TenyearFenglveGiveCard::onUse(Room *, const CardUseStruct &) const
{
}

class TenyearFenglve : public ViewAsSkill
{
public:
    TenyearFenglve() : ViewAsSkill("tenyearfenglve")
    {
        expand_pile = "#tenyearfenglve";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            return false;
        } else {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern == "@@tenyearfenglve!")
                return selected.length() < 2;
        }
        return false;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearFenglveCard") && player->canPindian();
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearfenglve!";
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (!cards.isEmpty()) return NULL;
            return new TenyearFenglveCard;
        } else {
            if (cards.length() != 2) return NULL;
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern == "@@tenyearfenglve!") {
                TenyearFenglveGiveCard *c = new TenyearFenglveGiveCard;
                c->addSubcards(cards);
                return c;
            }
        }
        return NULL;
    }
};

class Anyong : public TriggerSkill
{
public:
    Anyong() :TriggerSkill("anyong")
    {
        events << Damage << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseChanging)
            return 0;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from->getMark("anyong_damage-Keep") != 1 || damage.from->getPhase() == Player::NotActive) return false;
            //不用damage_point_turn-Clear这个mark，因为死亡时会清零
            if (damage.damage != 1) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (damage.to->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "he")) continue;
                if (!room->askForCard(p, "..", "@anyong-discard:" + damage.to->objectName(), data, objectName())) continue;
                room->broadcastSkillInvoke(this);
                room->damage(DamageStruct(objectName(), p, damage.to));
            }
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers(true))
                room->setPlayerMark(p, "anyong_damage-Keep", 0);
        }
        return false;
    }
};

class AnyongRecord : public TriggerSkill
{
public:
    AnyongRecord() :TriggerSkill("#anyong")
    {
        events << Damage;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->getPhase() == Player::NotActive) return false;
        room->addPlayerMark(damage.from, "anyong_damage-Keep");
        return false;
    }
};

JixuCard::JixuCard()
{
}

bool JixuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.isEmpty())
        return to_select != Self;
    else {
        int hp = targets.first()->getHp();
        return to_select != Self && to_select->getHp() == hp;
    }
}

void JixuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    bool has_slash = false;
    foreach (const Card *c, source->getCards("h")) {
        if (c->isKindOf("Slash")) {
            has_slash = true;
            break;
        }
    }

    QStringList choices;
    QList<ServerPlayer *> players;
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) return;
        if (p->isDead()) continue;
        QString choice = room->askForChoice(p, "jixu", "has+not", QVariant::fromValue(source));
        if (p->isAlive()) {
            choices << choice;
            players << p;
        }
    }
    if (choices.isEmpty() || players.isEmpty()) return;

    QList<ServerPlayer *> nots;
    QList<ServerPlayer *> hass;

    int i = -1;
    foreach (ServerPlayer *p, players) {
        i++;
        if (i > choices.length()) break;
        if (p->isDead()) continue;

        QString str = choices.at(i);
        QString result = "wrong";
        if ((str == "has" && has_slash) || (str == "not" && !has_slash))
            result = "correct";

        LogMessage log;
        log.type = "#JixuChoice";
        log.from = p;
        log.arg = "jixu:" + str;
        log.arg2 = "jixu:" + result;
        room->sendLog(log);
        if (str == "has")
            hass << p;
        else
            nots << p;
    }

    if (has_slash) {
        if (nots.isEmpty()) {
            LogMessage log;
            log.type = "#JixuStop";
            log.from = source;
            room->sendLog(log);

            source->endPlayPhase(false);
            return;
        }
        foreach (ServerPlayer *p, nots) {
            room->addPlayerMark(p, "jixu_choose_not" + source->objectName() + "-PlayClear");
            room->addPlayerMark(p, "&jixu_wrong-PlayClear");
        }
        source->drawCards(nots.length(), "jixu");
    } else {
        if (hass.isEmpty()) {
            LogMessage log;
            log.type = "#JixuStop";
            log.from = source;
            room->sendLog(log);

            source->endPlayPhase(false);
            return;
        }
        foreach (ServerPlayer *p, hass) {
            if (source->isDead()) return;
            if (p->isDead() || !source->canDiscard(p, "he")) continue;
            int id = room->askForCardChosen(source, p, "he", "jixu", false, Card::MethodDiscard);
            room->throwCard(id, p, source);
        }
        source->drawCards(hass.length(), "jixu");
    }
}

class JixuVS : public ZeroCardViewAsSkill
{
public:
    JixuVS() : ZeroCardViewAsSkill("jixu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JixuCard");
    }

    const Card *viewAs() const
    {
        return new JixuCard;
    }
};

class Jixu : public TriggerSkill
{
public:
    Jixu() :TriggerSkill("jixu")
    {
        //events << TargetSpecified; 这个时机加目标，会崩
        events << CardUsed;
        view_as_skill = new JixuVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;

        QList<ServerPlayer *> add;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isAlive() && !use.to.contains(p) && p->getMark("jixu_choose_not" + player->objectName() + "-PlayClear") > 0
                    && player->canSlash(p, use.card, false)) {
                add << p;
                use.to.append(p);
            }
        }

        if (!add.isEmpty()) {
            room->sortByActionOrder(add);
            foreach (ServerPlayer *p, add)
                room->doAnimate(1, player->objectName(), p->objectName());

            LogMessage log;
            log.type = "#JixuSlash";
            log.from = player;
            log.arg = objectName();
            log.to = add;
            log.card_str = use.card->toString();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());

            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

KannanCard::KannanCard()
{
}

bool KannanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return Self->canPindian(to_select) && targets.isEmpty() && to_select->getMark("kannan_target-PlayClear") <= 0;
}

void KannanCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;

    Room *room = effect.from->getRoom();
    int n = effect.from->pindianInt(effect.to, "kannan");
    if (n == 1) {
        room->addPlayerMark(effect.from, "kannan-PlayClear");
        room->addPlayerMark(effect.from, "&kannan");
    } else if (n == -1) {
        room->addPlayerMark(effect.to, "kannan_target-PlayClear");
        room->addPlayerMark(effect.to, "&kannan");
    }
}

class KannanVS : public ZeroCardViewAsSkill
{
public:
    KannanVS() : ZeroCardViewAsSkill("kannan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("kannan-PlayClear") > 0) return false;
        if (player->usedTimes("KannanCard") >= player->getHp()) return false;
        foreach (const Player *p, player->getAliveSiblings()) {
            if (player->canPindian(p) && p->getMark("kannan_target-PlayClear") <= 0)
                return true;
        }
        return false;
    }

    const Card *viewAs() const
    {
        return new KannanCard;
    }
};

class Kannan : public TriggerSkill
{
public:
    Kannan() :TriggerSkill("kannan")
    {
        events << CardUsed << ConfirmDamage << CardFinished;
        view_as_skill = new KannanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || use.from->isDead() || use.from->getMark("&kannan") <= 0) return false;
            int n = use.from->getMark("&kannan");
            room->setPlayerMark(use.from, "&kannan", 0);
            room->setTag("kannan_damage" + use.card->toString() + use.from->objectName(), n);
        } else if (event == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card) return false;
            int n = room->getTag("kannan_damage" + damage.card->toString() + damage.from->objectName()).toInt();
            if (n <= 0 || damage.from->isDead() || damage.to->isDead()) return false;
            LogMessage log;
            log.type = "#KannanDamage";
            log.from = damage.from;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(damage.damage += n);
            log.to << damage.to;
            room->sendLog(log);
            data = QVariant::fromValue(damage);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            room->removeTag("kannan_damage" + use.card->toString() + use.from->objectName());
        }
        return false;
    }
};

class Jijun : public TriggerSkill
{
public:
    Jijun() :TriggerSkill("jijun")
    {
        events << CardsMoveOneTime << TargetSpecified;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetSpecified) {
            if (player->getPhase() != Player::Play) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (use.card->isKindOf("Weapon") || !use.card->isKindOf("EquipCard")) {
                if (!use.to.contains(player)) return false;
                if (!player->askForSkillInvoke(this)) return false;
                room->broadcastSkillInvoke(objectName());
                JudgeStruct judge;
                judge.pattern = ".";
                judge.play_animation = false;
                judge.who = player;
                judge.reason = objectName();
                room->judge(judge);
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.to && move.to_place == Player::DiscardPile && move.reason.m_skillName == objectName() &&
                    move.reason.m_reason == CardMoveReason::S_REASON_JUDGEDONE)
                player->addToPile("jjfang", move.card_ids);
        }
        return false;
    }
};

FangtongCard::FangtongCard()
{
    will_throw = false;
    target_fixed = true;
    mute = true;
    handling_method = Card::MethodNone;
}

void FangtongCard::onUse(Room *, const CardUseStruct &) const
{
}

class FangtongVS : public ViewAsSkill
{
public:
    FangtongVS() : ViewAsSkill("fangtong")
    {
        expand_pile = "jjfang";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return Self->getPile("jjfang").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        FangtongCard *c = new FangtongCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@fangtong!";
    }
};

class Fangtong : public PhaseChangeSkill
{
public:
    Fangtong() : PhaseChangeSkill("fangtong")
    {
        view_as_skill = new FangtongVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (player->getPile("jjfang").isEmpty()) return false;

        Room *room = player->getRoom();
        if (!player->canDiscard(player, "he")) return false;
        const Card *c = room->askForCard(player, "..", "fangtong-invoke", QVariant(), objectName());
        if (!c) return false;
        room->broadcastSkillInvoke(objectName());

        if (player->isDead() || player->getPile("jjfang").isEmpty()) return false;

        CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, player->objectName(), "fangtong", QString());
        const Card *card = NULL;
        QList<int> fang = player->getPile("jjfang");
        if (fang.length() == 1)
            card = Sanguosha->getCard(fang.first());
        else {
            card = room->askForUseCard(player, "@@fangtong!", "@fangtong");
            if (!card) {
                card = Sanguosha->getCard(fang.at(qrand() % fang.length()));
            }
        }
        if (!card) return false;
        room->throwCard(card, reason, NULL);

        if (player->isDead()) return false;

        int num = Sanguosha->getCard(c->getSubcards().first())->getNumber();
        QList<int> ids;
        if (card->isVirtualCard())
            ids = card->getSubcards();
        else
            ids << card->getEffectiveId();
        foreach (int id, ids) {
            num += Sanguosha->getCard(id)->getNumber();
        }
        if (num != 36) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@fangtong-damage");
        room->doAnimate(1, player->objectName(), target->objectName());
        room->damage(DamageStruct(objectName(), player, target, 3, DamageStruct::Thunder));
        return false;
    }
};

FenyueCard::FenyueCard()
{
}

bool FenyueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return Self->canPindian(to_select) && targets.isEmpty();
}

void FenyueCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;
    PindianStruct *pindian = effect.from->PinDian(effect.to, "fenyue");
    if (!pindian) return;
    if (pindian->from_number <= pindian->to_number) return;

    int num = pindian->from_card->getNumber();
    Room *room = effect.from->getRoom();

    if (num <= 5) {
        if (!effect.to->isNude()) {
            int card_id = room->askForCardChosen(effect.from, effect.to, "he", "fenyue");
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
            room->obtainCard(effect.from, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
        }
    }

    if (num <= 9) {
        QList<int> slashs;
        foreach (int id, room->getDrawPile()) {
            if (Sanguosha->getCard(id)->isKindOf("Slash"))
               slashs << id;
        }
        if (!slashs.isEmpty()) {
            int id = slashs.at(qrand() % slashs.length());
            effect.from->obtainCard(Sanguosha->getCard(id), true);
        }
    }

    if (num <= 13) {
        ThunderSlash *thunder_slash = new ThunderSlash(Card::NoSuit, 0);
        thunder_slash->setSkillName("_fenyue");
        thunder_slash->deleteLater();
        if (effect.from->canSlash(effect.to, thunder_slash, false))
            room->useCard(CardUseStruct(thunder_slash, effect.from, effect.to), false);
    }
}

class FenyueVS : public ZeroCardViewAsSkill
{
public:
    FenyueVS() : ZeroCardViewAsSkill("fenyue")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (!player->canPindian()) return false;
        /*int x = 0;
        foreach(const Player *p, player->parent()->findChildren<const Player *>())
        {
            if (p->isAlive() && !player->isYourFriend(p))
                x++;
        }*/
        int x = player->getMark("fenyue-PlayClear");
        return player->usedTimes("FenyueCard") < x;
    }

    const Card *viewAs() const
    {
        return new FenyueCard;
    }
};

class Fenyue : public TriggerSkill
{
public:
    Fenyue() : TriggerSkill("fenyue")
    {
        events << EventPhaseStart << CardFinished << EventAcquireSkill << Death;
        view_as_skill = new FenyueVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        int n = 0;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!player->isYourFriend(p))
                n++;
        }
        room->setPlayerMark(player, "fenyue-PlayClear", n);
        return false;
    }
};

class FenyueRevived : public TriggerSkill
{
public:
    FenyueRevived() : TriggerSkill("#fenyue-revived")
    {
        events << Revived;
        view_as_skill = new FenyueVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isDead() || !p->hasSkill("fenyue") || p->getPhase() != Player::Play) return false;
            int n = 0;
            foreach (ServerPlayer *q, room->getOtherPlayers(p)) {
                if (!p->isYourFriend(q))
                    n++;
            }
            room->setPlayerMark(p, "fenyue-PlayClear", n);
        }
        return false;
    }
};

class Jiedao : public TriggerSkill
{
public:
    Jiedao() :TriggerSkill("jiedao")
    {
        events << DamageCaused << DamageComplete;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (event == DamageCaused) {
            if (player->getMark("jiedao-Clear") > 0 || !room->hasCurrent() || !player->hasSkill(this) || player->getLostHp() <= 0) return false;
            if (damage.to->isDead() || !player->askForSkillInvoke(this, damage.to)) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "jiedao-Clear");

            QStringList choices;
            for (int i = 1; i <= player->getLostHp(); i++) {
                choices << QString::number(i);
            }
            QString choice = room->askForChoice(player, "jiedao", choices.join("+"), data);
            int n = choice.toInt();
            LogMessage log;
            log.type = "#JiedaoDamage";
            log.from = player;
            log.arg = choice;
            room->sendLog(log);

            damage.damage += n;
            damage.tips << "jiedao_addDamage:" + choice + ":" + player->objectName();
            data = QVariant::fromValue(damage);
        } else {
            if (player->isDead()) return false;

            int n = 0;
            ServerPlayer *from = NULL;

            foreach (QString tip, damage.tips) {
                if (!tip.startsWith("jiedao_addDamage:")) continue;
                QStringList tips = tip.split(":");
                if (tips.length() != 3) continue;
                n = tips.at(1).toInt();
                from = room->findChild<ServerPlayer *>(tips.last());
                break;
            }

            if (n <= 0 || !from || from->isDead()) return false;
            room->askForDiscard(from, objectName(), n, n, false, true);
        }
        return false;
    }
};

class Xuhe : public TriggerSkill
{
public:
    Xuhe() :TriggerSkill("xuhe")
    {
        events << EventPhaseStart << EventPhaseEnd;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (event == EventPhaseStart) {
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->loseMaxHp(player);
            if (player->isDead()) return false;

            QStringList choices;
            QList<ServerPlayer *> players;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->distanceTo(p) <= 1)
                    players << p;
            }
            if (players.isEmpty()) return false;

            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->distanceTo(p) <= 1 && player->canDiscard(p, "he")) {
                    choices << "discard";
                    break;
                }
            }
            choices << "draw";
            if (room->askForChoice(player, objectName(), choices.join("+")) == "discard") {
                foreach (ServerPlayer *p, players) {
                    if (player->isDead()) return false;
                    if (p->isAlive() && player->distanceTo(p) <= 1 && player->canDiscard(p, "he")) {
                        int card_id = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard);
                        room->throwCard(card_id, p, player);
                    }
                }
            } else {
                room->drawCards(players, 1, objectName());
            }

        } else {
            int maxhp = player->getMaxHp();
            bool invoke = false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMaxHp() > maxhp) {
                    invoke = true;
                    break;
                }
            }
            if (!invoke) return false;
            room->sendCompulsoryTriggerLog(player, this);
            room->gainMaxHp(player);

            QStringList choices;
            if (player->isWounded())
                choices << "recover";
            choices << "selfdraw";
            QString choice = room->askForChoice(player, objectName(), choices.join("+"));
            if (choice == "recover")
                room->recover(player, RecoverStruct(player));
            else
                player->drawCards(2, objectName());
        }
        return false;
    }
};

class Lixun : public TriggerSkill
{
public:
    Lixun() :TriggerSkill("lixun")
    {
        events << DamageInflicted << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageInflicted) {
            DamageStruct damage = data.value<DamageStruct>();
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&lxzhu", damage.damage);
            return true;
        } else {
            if (player->getPhase() != Player::Play) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            JudgeStruct judge;
            judge.pattern = ".";
            judge.play_animation = false;
            judge.who = player;
            judge.reason = objectName();
            room->judge(judge);

            int zhu = player->getMark("&lxzhu"), number = judge.pattern.toInt();
            if (number >= zhu) return false;

            const Card *card = room->askForDiscard(player, objectName(), zhu, zhu);

            if (!card) {
                room->loseHp(player, zhu);
                return false;
            }
            int dis = zhu - card->subcardsLength();
            if (dis <= 0) return false;
            room->loseHp(player, dis);
        }
        return false;
    }
};

class LixunJudge : public TriggerSkill
{
public:
    LixunJudge() : TriggerSkill("#lixun-judge")
    {
        events << FinishJudge;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != "lixun") return false;
        judge->pattern = QString::number(judge->card->getNumber());
        return false;
    }
};


SpKuizhuCard::SpKuizhuCard()
{
    mute = true;
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void SpKuizhuCard::onUse(Room *, const CardUseStruct &) const
{
}

class SpKuizhuVS : public ViewAsSkill
{
public:
    SpKuizhuVS() : ViewAsSkill("spkuizhu")
    {
        expand_pile = "#spkuizhu";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !to_select->isEquipped() && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        int hand = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card))
                hand++;
            else if (Self->getPile("#spkuizhu").contains(card->getEffectiveId()))
                pile++;
        }

        if (hand == pile) {
            SpKuizhuCard *c = new SpKuizhuCard;
            c->addSubcards(cards);
            return c;
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@spkuizhu";
    }
};

class SpKuizhu : public TriggerSkill
{
public:
    SpKuizhu() :TriggerSkill("spkuizhu")
    {
        events << EventPhaseEnd;
        view_as_skill = new SpKuizhuVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;

        int hp = player->getNextAlive()->getHp();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHp() > hp)
                hp = p->getHp();
        }

        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHp() == hp)
                players << p;
        }
        if (players.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@spkuizhu-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());

        int hand = player->getHandcardNum();
        int num = qMin(5 - hand, target->getHandcardNum() - hand);
        if (num > 0)
            player->drawCards(num, objectName());

        if (player->isKongcheng()) return false;

        LogMessage log;
        log.type = "$ViewAllCards";
        log.from = target;
        log.to << player;
        log.card_str = IntList2StringList(player->handCards()).join("+");
        room->sendLog(log, target);

        if (!target->canDiscard(target, "h")) return false;
        room->notifyMoveToPile(target, player->handCards(), objectName(), Player::PlaceHand, true);

        const Card *c = room->askForUseCard(target, "@@spkuizhu", "@spkuizhu:" + player->objectName());

        room->notifyMoveToPile(target, player->handCards(), objectName(), Player::PlaceHand, false);

        if (c) {
            QList<int> ids1, ids2;
            foreach (int id, c->getSubcards()) {
                if (target->handCards().contains(id))
                    ids1 << id;
                else if (player->handCards().contains(id))
                    ids2 << id;
            }
            CardMoveReason reason1(CardMoveReason::S_REASON_THROW, target->objectName());
            CardsMoveStruct move1(ids1, target, NULL, Player::PlaceHand, Player::DiscardPile, reason1);
            CardMoveReason reason2(CardMoveReason::S_REASON_EXTRACTION, target->objectName());
            CardsMoveStruct move2(ids2, player, target, Player::PlaceHand, Player::PlaceHand, reason2);
            QList<CardsMoveStruct> moves;
            moves << move1 << move2;

            LogMessage log;
            log.type = "$DiscardCard";
            log.from = target;
            log.card_str = IntList2StringList(ids1).join("+");
            room->sendLog(log);

            room->moveCardsAtomic(moves, false);

            if (ids2.length() < 2) return false;

            QStringList choices;
            if (player->getMark("&lxzhu") > 0)
                choices << "mark";
            if (target->isAlive()) {
                foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                    if (target->inMyAttackRange(p)) {
                        choices << "damage";
                        break;
                    }
                }
            }
            if (choices.isEmpty()) return false;

            QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(target));
            if (choice == "mark" && player->getMark("&lxzhu") > 0)
                player->loseMark("&lxzhu");
            else if (choice == "damage" && target->isAlive()) {
                QList<ServerPlayer *> attack;
                foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                    if (target->inMyAttackRange(p))
                        attack << p;
                }
                if (attack.isEmpty()) return false;
                ServerPlayer *to = room->askForPlayerChosen(target, attack, objectName(), "@spkuizhu-damage");
                room->doAnimate(1, target->objectName(), to->objectName());
                room->damage(DamageStruct(objectName(), target, to));
            }
        }
        return false;
    }
};

class Zhaohuo : public TriggerSkill
{
public:
    Zhaohuo() : TriggerSkill("zhaohuo")
    {
        events << Dying;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who == player) return false;
        if (player->getMaxHp() == 1) return false;
        int n = qrand() % 2 + 1;
        if (player->isJieGeneral())
            n += 2;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true, n);
        if (player->getMaxHp() < 1) {
            room->gainMaxHp(player, 1 - player->getMaxHp());
        } else {
            int change = player->getMaxHp() - 1;
            room->loseMaxHp(player, change);
            player->drawCards(change, objectName());
        }
        return false;
    }
};

class Yixiang : public TriggerSkill
{
public:
    Yixiang() : TriggerSkill("yixiang")
    {
        events << TargetConfirmed;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("yixiang-Clear") > 0 || !room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (!use.from || use.from->isDead() || use.from->getHp() <= player->getHp() || !use.to.contains(player)) return false;
        QList<int> get;
        foreach (int id, room->getDrawPile()) {
            const Card *c = Sanguosha->getCard(id);
            if (!c->isKindOf("BasicCard")) continue;
            foreach (const Card *card, player->getCards("he")) {
                if (card->sameNameWith(c)) continue;
                get << id;
                break;
            }
        }
        if (get.isEmpty()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, "yixiang-Clear");
        int id = get.at(qrand() % get.length());
        player->obtainCard(Sanguosha->getCard(id), false);
        return false;
    }
};

class Yirang : public PhaseChangeSkill
{
public:
    Yirang() : PhaseChangeSkill("yirang")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        DummyCard *dummy = new DummyCard();
        foreach (const Card *c, player->getCards("he")) {
            if (!c->isKindOf("BasicCard"))
                dummy->addSubcard(c);
        }
        if (dummy->subcardsLength() > 0) {
            Room *room = player->getRoom();
            QList<ServerPlayer *> players;
            foreach(ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMaxHp() > player->getMaxHp())
                    players << p;
            }
            if (!players.isEmpty()) {
                ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@yirang-invoke", true, true);
                if (target) {
                    room->broadcastSkillInvoke(objectName());
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "yirang", QString());
                    room->obtainCard(target, dummy, reason, false);
                    if (target->getMaxHp() > player->getMaxHp())
                        room->gainMaxHp(player, target->getMaxHp() - player->getMaxHp());
                    else if (target->getMaxHp() < player->getMaxHp())
                        room->loseMaxHp(player, player->getMaxHp() - target->getMaxHp());
                    QList<int> types;
                    foreach (int id, dummy->getSubcards()) {
                        if (!types.contains(Sanguosha->getCard(id)->getTypeId()))
                            types << Sanguosha->getCard(id)->getTypeId();
                    }
                    if (types.length() > 0) {
                        int n = qMin(types.length(), player->getMaxHp() - player->getHp());
                        if (n > 0)
                            room->recover(player, RecoverStruct(player, NULL, n));
                    }
                }
            }
        }
        delete dummy;
        return false;
    }
};

PingcaiCard::PingcaiCard()
{
    target_fixed = true;
    mute = true;
}

bool PingcaiCard::isOK(Room *room, const QString &name) const
{
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (Sanguosha->translate(p->getGeneralName()).contains(name))
            return true;
        if (p->getGeneral2() && Sanguosha->translate(p->getGeneral2Name()).contains(name))
            return true;
    }
    return false;
}

bool PingcaiCard::shuijingJudge(Room *room) const
{
    if (isOK(room, "司马徽") && room->canMoveField("e"))
        return true;
    else {
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getArmor())
                targets << p;
        }

        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->getArmor() && p->hasEquipArea(1))
                tos << p;
        }
        if (!targets.isEmpty() && !tos.isEmpty())
            return true;
    }
    return false;
}

void PingcaiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->broadcastSkillInvoke("pingcai", 1);
    QString choices = "pcwolong+pcfengchu+pcxuanjian";
    if (shuijingJudge(room))
        choices = "pcwolong+pcfengchu+pcshuijing+pcxuanjian";
    QString choice = room->askForChoice(source, "pingcai", choices);
    LogMessage log;
    log.type = "#FumianFirstChoice";
    log.from = source;
    log.arg = "pingcai:" + choice;
    room->sendLog(log);
    if (source->isDead()) return;

    QList<ServerPlayer *> targets;
    if (choice == "pcwolong") {
        room->broadcastSkillInvoke("pingcai", 2);
        if (isOK(room, "卧龙诸葛亮")) {
            room->askForUseCard(source, "@@pingcai1", "@pingcai-wolong2", 1);
        } else {
            ServerPlayer *target = room->askForPlayerChosen(source, room->getAlivePlayers(), "pingcai_wolong" ,"@pingcai-wolong1");
            room->doAnimate(1, source->objectName(), target->objectName());
            room->damage(DamageStruct("pingcai", source, target, 1, DamageStruct::Fire));
        }
    } else if (choice == "pcfengchu") {
        room->broadcastSkillInvoke("pingcai", 3);
        int n = 3;
        if (isOK(room, "庞统"))
            n = 4;
        room->setPlayerMark(source, "pingcai_fengchu_mark-Clear", n);
        room->askForUseCard(source, "@@pingcai2", "@pingcai-fengchu:" + QString::number(n), 2);
    } else if (choice == "pcshuijing") {
        room->broadcastSkillInvoke("pingcai", 4);
        if (isOK(room, "司马徽"))
            room->moveField(source, "pingcai", false, "e");
        else {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getArmor())
                    targets << p;
            }

            QList<ServerPlayer *> tos;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (!p->getArmor() && p->hasEquipArea(1))
                    tos << p;
            }
            if (targets.isEmpty() || tos.isEmpty()) return;
            ServerPlayer *from = room->askForPlayerChosen(source, targets, "pingcai_shuijing_from", "@pingcai-shuijing");
            if (!from->getArmor()) return;
            const Card *armor = Sanguosha->getCard(from->getArmor()->getEffectiveId());
            ServerPlayer *to =  room->askForPlayerChosen(source, tos, "pingcai_shuijing_to", "@movefield-to:" + armor->objectName());
            if (from->isProhibited(to, armor) || !to->hasEquipArea(1) || to->getArmor()) return;
            room->moveCardTo(armor, to, Player::PlaceEquip, true);
        }
    } else {
        room->broadcastSkillInvoke("pingcai", 5);
        ServerPlayer *target = room->askForPlayerChosen(source, room->getAlivePlayers(), "pingcai_xuanjian", "@pingcai-xuanjian");
        room->doAnimate(1, source->objectName(), target->objectName());
        target->drawCards(1, "pingcai");
        room->recover(target, RecoverStruct(source));
        if (isOK(room, "徐庶"))
            source->drawCards(1, "pingcai");
    }
}

PingcaiWolongCard::PingcaiWolongCard()
{
    mute = true;
    m_skillName = "pingcai";
}

bool PingcaiWolongCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.length() < 2;
}

void PingcaiWolongCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QList<ServerPlayer *> tos = card_use.to;
    room->sortByActionOrder(tos);
    foreach (ServerPlayer *p, tos)
        room->doAnimate(1, card_use.from->objectName(), p->objectName());
    foreach (ServerPlayer *p, tos)
        room->damage(DamageStruct("pingcai", card_use.from, p, 1, DamageStruct::Fire));
}

PingcaiFengchuCard::PingcaiFengchuCard()
{
    mute = true;
    m_skillName = "pingcai";
}

bool PingcaiFengchuCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    int n = Self->getMark("pingcai_fengchu_mark-Clear");
    return targets.length() < n;
}

void PingcaiFengchuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QList<ServerPlayer *> tos = card_use.to;
    room->sortByActionOrder(tos);
    foreach (ServerPlayer *p, tos)
        room->doAnimate(1, card_use.from->objectName(), p->objectName());
    foreach (ServerPlayer *p, tos) {
        if (p->isChained()) continue;
        room->setPlayerChained(p);
    }
}

class Pingcai : public ZeroCardViewAsSkill
{
public:
    Pingcai() : ZeroCardViewAsSkill("pingcai")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("PingcaiCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@pingcai");
    }

    const Card *viewAs() const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@pingcai1")
            return new PingcaiWolongCard;
        else if (pattern == "@@pingcai2")
            return new PingcaiFengchuCard;
        else
            return new PingcaiCard;
    }
};

class Yinshiy : public TriggerSkill
{
public:
    Yinshiy() : TriggerSkill("yinshiy")
    {
        events << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        Player::Phase phase = data.value<PhaseChangeStruct>().to;
        if (phase != Player::Start && phase != Player::Judge && phase != Player::Finish) return false;
        if (player->isSkipped(phase)) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->skip(phase);
        return false;
    }
};

class YinshiyPro : public ProhibitSkill
{
public:
    YinshiyPro() : ProhibitSkill("#yinshiy-pro")
    {
    }

    bool isProhibited(const Player *, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return to->hasSkill("yinshiy") && card->isKindOf("DelayedTrick");
    }
};

class Chijiec : public GameStartSkill
{
public:
    Chijiec() : GameStartSkill("chijiec")
    {
    }

    void onGameStart(ServerPlayer *player) const
    {
        if (!player->askForSkillInvoke(this)) return;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());

        QStringList kingdoms;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!kingdoms.contains(p->getKingdom()))
                kingdoms << p->getKingdom();
        }
        if (kingdoms.isEmpty()) return;
        QString kingdom = room->askForChoice(player, objectName(), kingdoms.join("+"));
        LogMessage log;
        log.type = "#ChijieKingdom";
        log.from = player;
        log.arg = kingdom;
        room->sendLog(log);
        room->setPlayerProperty(player, "kingdom", kingdom);
    }
};

WaishiCard::WaishiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool WaishiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getHandcardNum() >= subcardsLength();
}

void WaishiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *a = effect.from;
    ServerPlayer *b = effect.to;
    if (a->isDead() || b->isDead()) return;

    QList<int> subcards = getSubcards();
    QList<int> hand = b->handCards();
    QList<int> ids;
    for (int i = 1; i <= subcards.length(); i++) {
        int id = hand.at(qrand() % hand.length());
        hand.removeOne(id);
        ids << id;
        if (hand.isEmpty()) break;
    }

    Room *room = a->getRoom();
    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1(subcards, b, Player::PlaceHand,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, a->objectName(), b->objectName(), "waishi", QString()));
    CardsMoveStruct move2(ids, a, Player::PlaceHand,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, b->objectName(), a->objectName(), "waishi", QString()));
    exchangeMove.push_back(move1);
    exchangeMove.push_back(move2);
    room->moveCardsAtomic(exchangeMove, false);

    if (a->isDead() || b->isDead()) return;
    if (a->getKingdom() == b->getKingdom() || b->getHandcardNum() > a->getHandcardNum())
        a->drawCards(1, "waishi");
}

class Waishi : public ViewAsSkill
{
public:
    Waishi() : ViewAsSkill("waishi")
    {
    }

    int getKingdom(const Player *player) const
    {
        QStringList kingdoms;
        foreach (const Player *p, player->getAliveSiblings()) {
            if (!kingdoms.contains(p->getKingdom()))
                kingdoms << p->getKingdom();
        }
        if (!kingdoms.contains(player->getKingdom()))
            kingdoms << player->getKingdom();
        return kingdoms.length();
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        return selected.length() < getKingdom(Self);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        WaishiCard *c = new WaishiCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("WaishiCard") < 1 + player->getMark("&waishi_extra");
    }
};

class Renshe : public MasochismSkill
{
public:
    Renshe() : MasochismSkill("renshe")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        if (!player->askForSkillInvoke(this)) return;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());

        QStringList kingdoms;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getKingdom() != player->getKingdom())
                kingdoms << p->getKingdom();
        }

        QStringList choices;
        if (!kingdoms.isEmpty())
            choices << "change";
        choices << "extra" << "draw";

        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        if (choice == "change") {
            QString kingdom = room->askForChoice(player, "renshe_change", kingdoms.join("+"));
            LogMessage log;
            log.type = "#ChijieKingdom";
            log.from = player;
            log.arg = kingdom;
            room->sendLog(log);
            room->setPlayerProperty(player, "kingdom", kingdom);
        } else if (choice == "extra") {
            LogMessage log;
            log.type = "#FumianFirstChoice";
            log.from = player;
            log.arg = "renshe:extra";
            room->sendLog(log);
            room->addPlayerMark(player, "&waishi_extra");
        } else {
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@renshe-target");
            room->doAnimate(1, player->objectName(), target->objectName());
            QList<ServerPlayer *> all;
            all << player << target;
            room->sortByActionOrder(all);
            room->drawCards(all, 1, objectName());
        }
    }
};

class RensheMark : public TriggerSkill
{
public:
    RensheMark() : TriggerSkill("#renshe-mark")
    {
        events << EventPhaseChanging;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.from == Player::Play)
            room->setPlayerMark(player, "&waishi_extra", 0);
        else if (change.to == Player::NotActive)
            room->setPlayerMark(player, "&waishi_extra", 0);
        return false;
    }
};

class Xuewei : public TriggerSkill
{
public:
    Xuewei() : TriggerSkill("xuewei")
    {
        events << EventPhaseStart << EventPhaseChanging << DamageInflicted << Death << EventLoseSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->isDead() || player->getPhase() != Player::Start || !player->hasSkill(this)) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@xuewei-invoke", true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(player, objectName());

            LogMessage log;
            log.type = "#ChoosePlayerWithSkill";
            log.from = player;
            log.to << target;
            log.arg = objectName();
            room->sendLog(log, player);

            log.type = "#InvokeSkill";
            room->sendLog(log, room->getOtherPlayers(player, true));

            room->doAnimate(1, player->objectName(), target->objectName(), QList<ServerPlayer *>() << player);

            QStringList names = player->property("Xuewei_targets").toStringList();
            if (!names.contains(target->objectName()))
                names << target->objectName();
            room->setPlayerProperty(player, "Xuewei_targets", names);

            QList<ServerPlayer *> viewers;
            viewers << player;
            room->addPlayerMark(target, "&xuewei", 1, viewers);
        } else if (event == DamageInflicted) {
            if (player->isDead()) return false;
            DamageStruct damage = data.value<DamageStruct>();
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead() || !p->hasSkill(this)) continue;
                QStringList names = p->property("Xuewei_targets").toStringList();
                if (!names.contains(player->objectName())) continue;
                names.removeOne(player->objectName());
                room->setPlayerProperty(p, "Xuewei_targets", names);
                room->setPlayerMark(player, "&xuewei", 0);

                LogMessage log;
                log.type = "#XueweiPrevent";
                log.from = p;
                log.to << player;
                log.arg = objectName();
                log.arg2 = QString::number(damage.damage);
                room->sendLog(log);
                room->broadcastSkillInvoke(objectName());
                room->notifySkillInvoked(p, objectName());

                room->damage(DamageStruct(objectName(), NULL, p, damage.damage));
                if (p->isAlive() && damage.from && damage.from->isAlive()) {
                    room->doAnimate(1, p->objectName(), damage.from->objectName());
                    room->damage(DamageStruct(objectName(), p, damage.from, damage.damage, damage.nature));
                }
                return true;
            }
        } else {
            if (event == EventPhaseChanging) {
                if (player->isDead()) return false;
                PhaseChangeStruct change = data.value<PhaseChangeStruct>();
                if (change.to != Player::RoundStart) return false;
            } else if (event == EventLoseSkill) {
                if (player->isDead()) return false;
                if (data.toString() != objectName()) return false;
            } else if (event == Death)
                if (data.value<DeathStruct>().who != player) return false;

            QStringList names = player->property("Xuewei_targets").toStringList();
            foreach (QString name, names) {
                ServerPlayer *p = room->findPlayerByObjectName(name);
                if (p)
                    room->setPlayerMark(p, "&xuewei", 0);
            }
            room->setPlayerProperty(player, "Xuewei_targets", QStringList());
        }
        return false;
    }
};

class Liechi : public TriggerSkill
{
public:
    Liechi() : TriggerSkill("liechi")
    {
        events << EnterDying;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (!dying.damage) return false;
        ServerPlayer *from = dying.damage->from;
        if (from && from->isAlive() && from->canDiscard(from, "he")) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->askForDiscard(from, objectName(), 1, 1, false, true);
        }
        return false;
    }
};

ZhiyiCard::ZhiyiCard()
{
    mute = true;
}

bool ZhiyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QString name = Self->property("zhiyi_card_name").toString();
    if (name == QString()) return false;

    Card *c = Sanguosha->cloneCard(name);
    c->setSkillName("_zhiyi");
    c->deleteLater();
    if (!c) return false;

    return c->targetFilter(targets, to_select, Self);
}

bool ZhiyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    QString name = Self->property("zhiyi_card_name").toString();
    if (name == QString()) return false;

    Card *c = Sanguosha->cloneCard(name);
    c->setSkillName("_zhiyi");
    c->deleteLater();
    if (!c) return false;

    return c->targetsFeasible(targets, Self);
}

void ZhiyiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QString name = card_use.from->property("zhiyi_card_name").toString();
    room->setPlayerProperty(card_use.from, "zhiyi_card_name", QString());
    if (name == QString()) return;

    Card *c = Sanguosha->cloneCard(name);
    c->setSkillName("_zhiyi");
    c->deleteLater();

    room->useCard(CardUseStruct(c, card_use.from, card_use.to), false);
}

class ZhiyiVS : public ZeroCardViewAsSkill
{
public:
    ZhiyiVS() : ZeroCardViewAsSkill("zhiyi")
    {
        response_pattern = "@@zhiyi!";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new ZhiyiCard;
    }
};

class Zhiyi : public TriggerSkill
{
public:
    Zhiyi() : TriggerSkill("zhiyi")
    {
        events << CardUsed << CardResponded << CardFinished;
        frequency = Compulsory;
        view_as_skill = new ZhiyiVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->hasFlag("zhiyi_card")) return false;
            Card *c = Sanguosha->cloneCard(use.card->objectName());
            c->setSkillName("_" + objectName());
            c->deleteLater();
            if (player->isLocked(c)) return false;
            if (c->targetFixed()) {
                if (player->isProhibited(player, c)) return false;
                if (!c->isKindOf("Peach") || player->isWounded())
                    room->useCard(CardUseStruct(c, player, player), false);
            } else {
                room->setPlayerProperty(player, "zhiyi_card_name", c->objectName());

                if (room->askForUseCard(player, "@@zhiyi!", "@zhiyi:" + c->objectName())) return false;

                room->setPlayerProperty(player, "zhiyi_card_name", QString());
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (c->targetFilter(QList<const Player *>(), p, player)) {
                        targets << p;
                    }
                }
                if (targets.isEmpty()) return false;
                ServerPlayer *target = targets.at(qrand() % targets.length());
                room->useCard(CardUseStruct(c, player, target), false);
            }
        } else if (event == CardUsed) {
            if (player->getMark("zhiyi-Clear") > 0) return false;
            const Card *card = data.value<CardUseStruct>().card;
            if (!card || !card->isKindOf("BasicCard")) return false;

            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->addPlayerMark(player, "zhiyi-Clear");

            QStringList choices;
            Card *c = Sanguosha->cloneCard(card);
            c->setSkillName("_" + objectName());
            if (!player->isLocked(c)) {
                if (c->targetFixed() && !player->isProhibited(player, c)) {
                    if (!c->isKindOf("Peach") || player->isWounded())
                        choices << "use";
                } else if (!c->targetFixed()) {
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (c->targetFilter(QList<const Player *>(), p, player)) {
                            choices << "use";
                            break;
                        }
                    }
                }
            }
            choices << "draw";

            QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(card));
            if (choice == "use")
                room->setCardFlag(card, "zhiyi_card");
            else
                player->drawCards(1, objectName());
            delete c;
        } else {
            if (player->getMark("zhiyi-Clear") > 0) return false;
            const Card *card = data.value<CardResponseStruct>().m_card;
            if (!card || !card->isKindOf("BasicCard")) return false;

            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->addPlayerMark(player, "zhiyi-Clear");

            QStringList choices;
            Card *c = Sanguosha->cloneCard(card->objectName());
            c->setSkillName("_" + objectName());
            QList<ServerPlayer *> targets;
            if (c->targetFixed()) {
                if (c->isAvailable(player))
                    choices << "use";
            } else {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (c->targetFilter(QList<const Player *>(), p, player))
                        targets << p;
                }
            }
            if (!targets.isEmpty())
                choices << "use";
            choices << "draw";

            QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(card));
            if (choice == "use") {
                if (c->targetFixed())
                    room->useCard(CardUseStruct(c, player, player), false);
                else {
                    room->setPlayerProperty(player, "zhiyi_card_name", c->objectName());

                    if (room->askForUseCard(player, "@@zhiyi!", "@zhiyi:" + c->objectName())) return false;

                    room->setPlayerProperty(player, "zhiyi_card_name", QString());

                    ServerPlayer *target = targets.at(qrand() % targets.length());
                    room->useCard(CardUseStruct(c, player, target), false);
                }
            }
            else
                player->drawCards(1, objectName());
            delete c;
        }
        return false;
    }
};

SecondZhiyiCard::SecondZhiyiCard()
{
    mute = true;
}

bool SecondZhiyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QString name = Self->property("secondzhiyi_card_name").toString();
    if (name == QString()) return false;

    Card *c = Sanguosha->cloneCard(name);
    c->setSkillName("_secondzhiyi");
    c->deleteLater();
    if (!c) return false;

    return c->targetFilter(targets, to_select, Self);
}

bool SecondZhiyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    QString name = Self->property("secondzhiyi_card_name").toString();
    if (name == QString()) return false;

    Card *c = Sanguosha->cloneCard(name);
    c->setSkillName("_secondzhiyi");
    c->deleteLater();
    if (!c) return false;

    return c->targetsFeasible(targets, Self);
}

void SecondZhiyiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QString name = card_use.from->property("secondzhiyi_card_name").toString();
    room->setPlayerProperty(card_use.from, "secondzhiyi_card_name", QString());
    if (name == QString()) return;

    Card *c = Sanguosha->cloneCard(name);
    c->setSkillName("_secondzhiyi");
    c->deleteLater();

    room->useCard(CardUseStruct(c, card_use.from, card_use.to), false);
}

class SecondZhiyiVS : public ZeroCardViewAsSkill
{
public:
    SecondZhiyiVS() : ZeroCardViewAsSkill("secondzhiyi")
    {
        response_pattern = "@@secondzhiyi!";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new SecondZhiyiCard;
    }
};

class SecondZhiyi : public PhaseChangeSkill
{
public:
    SecondZhiyi() : PhaseChangeSkill("secondzhiyi")
    {
        frequency = Compulsory;
        view_as_skill = new SecondZhiyiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            QStringList used_cards = p->tag["SecondZhiyiUsedCard"].toStringList();
            if (used_cards.isEmpty()) continue;

            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
            QStringList choices;

            foreach (QString card_name, used_cards) {
                Card *c = Sanguosha->cloneCard(card_name);
                if (!c) continue;
                c->setSkillName("_secondzhiyi");
                if (p->canUse(c))
                    choices << card_name;
                delete c;
            }
            choices << "draw";
            QString choice = room->askForChoice(p, objectName(), choices.join("+"));
            if (choice == "draw")
                p->drawCards(1, objectName());
            else {
                Card *c = Sanguosha->cloneCard(choice);
                c->setSkillName("_secondzhiyi");
                c->deleteLater();
                if (c->targetFixed())
                    room->useCard(CardUseStruct(c, p, p), false);
                else {
                    room->setPlayerProperty(p, "secondzhiyi_card_name", choice);
                    const Card *zhiyi_card = room->askForUseCard(p, "@@secondzhiyi!", "@secondzhiyi:" + choice);
                    room->setPlayerProperty(p, "secondzhiyi_card_name", QString());
                    if (!zhiyi_card) {
                        QList<ServerPlayer *> targets;
                        foreach (ServerPlayer *target, room->getAlivePlayers()) {
                            if (c->targetFilter(QList<const Player *>(), target, p) && !p->isProhibited(target, c))
                                targets << target;
                        }
                        if (targets.isEmpty())
                            p->drawCards(1, objectName());
                        else {
                            ServerPlayer *to = targets.at(qrand() % targets.length());
                            room->useCard(CardUseStruct(c, p, to), false);
                        }
                    }
                }
            }
        }
        return false;
    }
};

class SecondZhiyiRecord : public TriggerSkill
{
public:
    SecondZhiyiRecord() : TriggerSkill("#secondzhiyi-record")
    {
        events << CardUsed << CardResponded << EventPhaseChanging;
        frequency = Compulsory;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers(true))
                p->tag.remove("SecondZhiyiUsedCard");
        } else {
            if (player->isDead()) return false;
            const Card *c = NULL;
            if (event == CardResponded)
                c = data.value<CardResponseStruct>().m_card;
            else
                c = data.value<CardUseStruct>().card;
            if (c == NULL || !c->isKindOf("BasicCard")) return false;
            QStringList used_cards = player->tag["SecondZhiyiUsedCard"].toStringList();
            if (used_cards.contains(c->objectName())) return false;
            used_cards << c->objectName();
            player->tag["SecondZhiyiUsedCard"] = used_cards;
        }
        return false;
    }
};

class Jimeng : public PhaseChangeSkill
{
public:
    Jimeng() : PhaseChangeSkill("jimeng")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        QList<ServerPlayer *> targets;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isNude())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@jimeng-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        if (target->isNude()) return false;
        int id = room->askForCardChosen(player, target, "he", objectName());
        room->obtainCard(player, id, false);
        if (player->isNude() || player->getHp() <= 0) return false;

        int n = qMin(player->getCardCount(), player->getHp());
        QString prompt = QString("@jimeng-give:%1::%2").arg(target->objectName()).arg(QString::number(n));
        const Card *c = room->askForExchange(player, objectName(), n, n, true, prompt);
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "jimeng", QString());
        room->obtainCard(target, c, reason, false);
        return false;
    }
};

class Shuaiyan : public PhaseChangeSkill
{
public:
    Shuaiyan() : PhaseChangeSkill("shuaiyan")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Discard) return false;
        if (player->getHandcardNum() <= 1) return false;
        QList<ServerPlayer *> targets;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isNude())
                targets << p;
        }

        if (targets.isEmpty()) {
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->showAllCards(player);
            return false;
        }

        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@shuaiyan-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        room->showAllCards(player);
        if (target->isNude()) return false;
        const Card *c = room->askForExchange(target, objectName(), 1, 1, true, "@shuaiyan-give:" + player->objectName());
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "shuaiyan", QString());
        room->obtainCard(player, c, reason, false);
        return false;
    }
};

class Tuogu : public TriggerSkill
{
public:
    Tuogu() : TriggerSkill("tuogu")
    {
        events << Death;
        frequency = Limited;
        limit_mark = "@tuoguMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *who = data.value<DeathStruct>().who;
        if (!who || who == player || player->getMark("@tuoguMark") <= 0) return false;

        QStringList list;

        QString name = who->getGeneralName();
        const General *g = Sanguosha->getGeneral(name);
        if (g) {
            QList<const Skill *> skills = g->getSkillList();
            foreach (const Skill *skill, skills) {
                if (!skill->isVisible()) continue;
                //if (skill->getFrequency() == Skill::Limited) continue;
                if (skill->isLimitedSkill()) continue;
                if (skill->getFrequency() == Skill::Wake) continue;
                if (skill->isLordSkill()) continue;
                if (!list.contains(skill->objectName()))
                    list << skill->objectName();
            }
        }

        if (who->getGeneral2()) {
            QString name2 = who->getGeneral2Name();
            const General *g2 = Sanguosha->getGeneral(name2);
            if (g2) {
                QList<const Skill *> skills2 = g2->getSkillList();
                foreach (const Skill *skill, skills2) {
                    if (!skill->isVisible()) continue;
                    //if (skill->getFrequency() == Skill::Limited) continue;
                    if (skill->isLimitedSkill()) continue;
                    if (skill->getFrequency() == Skill::Wake) continue;
                    if (skill->isLordSkill()) continue;
                    if (!list.contains(skill->objectName()))
                        list << skill->objectName();
                }
            }
        }

        if (list.isEmpty()) return false;
        if (!player->askForSkillInvoke(this, QVariant::fromValue(who))) return false;

        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("caoshuang", "tuogu");
        room->removePlayerMark(player, "@tuoguMark");

        QString skill = room->askForChoice(who, objectName(), list.join("+"), QVariant::fromValue(player));
        if (player->hasSkill(skill)) return false;
        room->acquireSkill(player, skill);
        return false;
    }
};

class Shanzhuan : public TriggerSkill
{
public:
    Shanzhuan() : TriggerSkill("shanzhuan")
    {
        events << Damage << EventPhaseChanging;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damage) {
            ServerPlayer *to = data.value<DamageStruct>().to;
            if (!to || to->isDead() || to == player || to->isNude() || !to->hasJudgeArea() || !to->getJudgingArea().isEmpty()) return false;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(to))) return false;
            room->broadcastSkillInvoke(objectName());

            int id = room->askForCardChosen(player, to, "he", objectName());
            const Card *card = Sanguosha->getCard(id);

            LogMessage log;
            log.from = player;
            log.to << to;
            log.card_str = card->toString();
            if (card->isKindOf("DelayedTrick")) {
                log.type = "$ShanzhuanPut";
            } else {
                log.type = "$ShanzhuanViewAsPut";
                Indulgence *indulgence = new Indulgence(card->getSuit(), card->getNumber());
                indulgence->setSkillName("shanzhuan");
                WrappedCard *c = Sanguosha->getWrappedCard(card->getId());
                c->takeOver(indulgence);
                room->broadcastUpdateCard(room->getAllPlayers(true), card->getId(), indulgence);
                if (card->isRed()) {
                    Indulgence *indulgence = new Indulgence(card->getSuit(), card->getNumber());
                    indulgence->setSkillName("shanzhuan");
                    WrappedCard *c = Sanguosha->getWrappedCard(card->getId());
                    c->takeOver(indulgence);
                    room->broadcastUpdateCard(room->getAllPlayers(true), card->getId(), indulgence);
                } else if (card->isBlack()) {
                    SupplyShortage *supply_shortage = new SupplyShortage(card->getSuit(), card->getNumber());
                    supply_shortage->setSkillName("shanzhuan");
                    WrappedCard *c = Sanguosha->getWrappedCard(card->getId());
                    c->takeOver(supply_shortage);
                    room->broadcastUpdateCard(room->getAllPlayers(true), card->getId(), supply_shortage);
                } else {
                    return false;
                }
                log.arg = card->objectName();
            }
            if (to->containsTrick(card->objectName())) return false;
            room->sendLog(log);
            CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), to->objectName(), "shanzhuan", QString());
            room->moveCardTo(card, to, to, Player::PlaceDelayedTrick, reason, true);
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            if (player->getMark("damage_point_round") > 0) return false;
            if (!player->askForSkillInvoke(this, "draw")) return false;
            room->broadcastSkillInvoke(objectName());
            player->drawCards(1, objectName());
        }

        return false;
    }
};

class SecondTuogu : public TriggerSkill
{
public:
    SecondTuogu() : TriggerSkill("secondtuogu")
    {
        events << Death;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *who = data.value<DeathStruct>().who;
        if (!who || who == player) return false;

        QStringList list;

        QString name = who->getGeneralName();
        const General *g = Sanguosha->getGeneral(name);
        if (g) {
            QList<const Skill *> skills = g->getSkillList();
            foreach (const Skill *skill, skills) {
                if (!skill->isVisible()) continue;
                //if (skill->getFrequency() == Skill::Limited) continue;
                if (skill->isLimitedSkill()) continue;
                if (skill->getFrequency() == Skill::Wake) continue;
                if (skill->isLordSkill()) continue;
                if (!list.contains(skill->objectName()))
                    list << skill->objectName();
            }
        }

        if (who->getGeneral2()) {
            QString name2 = who->getGeneral2Name();
            const General *g2 = Sanguosha->getGeneral(name2);
            if (g2) {
                QList<const Skill *> skills2 = g2->getSkillList();
                foreach (const Skill *skill, skills2) {
                    if (!skill->isVisible()) continue;
                    //if (skill->getFrequency() == Skill::Limited) continue;
                    if (skill->isLimitedSkill()) continue;
                    if (skill->getFrequency() == Skill::Wake) continue;
                    if (skill->isLordSkill()) continue;
                    if (!list.contains(skill->objectName()))
                        list << skill->objectName();
                }
            }
        }

        if (list.isEmpty()) return false;
        if (!player->askForSkillInvoke(this, QVariant::fromValue(who))) return false;
        room->broadcastSkillInvoke(objectName());
        QString sk = player->property("secondtuogu_skill").toString();
        QString skill = room->askForChoice(who, objectName(), list.join("+"), QVariant::fromValue(player));
        room->setPlayerProperty(player, "secondtuogu_skill", skill);
        /*QStringList sks;
        if (player->hasSkill(sk))
            sks << "-" + sk;
        if (!player->hasSkill(skill))
            sks << skill;
        if (sks.isEmpty()) return false;
        room->handleAcquireDetachSkills(player, sks);*/
        if (player->hasSkill(sk))
            room->detachSkillFromPlayer(player, sk);
        if (player->isAlive() && !player->hasSkill(skill))
            room->acquireSkill(player, skill);
        return false;
    }
};

class Zhengjian : public TriggerSkill
{
public:
    Zhengjian() : TriggerSkill("zhengjian")
    {
        events << EventPhaseStart << EventLoseSkill << PreCardUsed << PreCardResponded << Death;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->isDead() || !player->hasSkill(this)) return false;
            if (player->getPhase() == Player::Finish) {
                ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@zhengjian-invoke", false, true);
                room->broadcastSkillInvoke(objectName());
                QStringList names = player->property("ZhengjianTargets").toStringList();
                if (names.contains(target->objectName())) return false;
                names << target->objectName();
                room->setPlayerProperty(player, "ZhengjianTargets", names);
                target->gainMark("&zhengjian");
            } else if (player->getPhase() == Player::RoundStart) {
                QStringList names = player->property("ZhengjianTargets").toStringList();
                if (names.isEmpty()) return false;
                room->setPlayerProperty(player, "ZhengjianTargets", QStringList());

                QList<ServerPlayer *> sp;
                foreach (QString name, names) {
                    ServerPlayer *target = room->findPlayerByObjectName(name);
                    if (target && target->isAlive() && !sp.contains(target))
                        sp << target;
                }
                if (sp.isEmpty()) return false;

                bool peiyin = false;
                room->sortByActionOrder(sp);
                foreach (ServerPlayer *p, sp) {
                    int mark = p->getMark("&zhengjiandraw");
                    room->setPlayerMark(p, "&zhengjiandraw", 0);
                    mark = qMin(5, mark);
                    mark = qMin(mark, p->getMaxHp());
                    if (mark > 0) {
                        if (!peiyin) {
                            peiyin = true;
                            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                        }
                        p->drawCards(mark, objectName());
                    }
                    if (p->getMark("&zhengjian") > 0) {
                        if (!peiyin) {
                            peiyin = true;
                            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                        }
                        p->loseAllMarks("&zhengjian");
                    }
                }
            }
        } else if (event == PreCardUsed) {
            if (player->getMark("&zhengjian") <= 0) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "&zhengjiandraw");
        } else if (event == PreCardResponded) {
            if (player->getMark("&zhengjian") <= 0) return false;
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (res.m_card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "&zhengjiandraw");
        } else {
            if (event == EventLoseSkill) {
                if (player->isDead() || data.toString() != objectName()) return false;
            } else if (event == Death) {
                if (data.value<DeathStruct>().who != player) return false;
            }

            QStringList names = player->property("ZhengjianTargets").toStringList();
            if (names.isEmpty()) return false;
            room->setPlayerProperty(player, "ZhengjianTargets", QStringList());

            QList<ServerPlayer *> sp;
            foreach (QString name, names) {
                ServerPlayer *target = room->findPlayerByObjectName(name);
                if (target && target->isAlive() && !sp.contains(target))
                    sp << target;
            }
            if (sp.isEmpty()) return false;

            room->sortByActionOrder(sp);
            foreach (ServerPlayer *p, sp) {
                room->setPlayerMark(p, "&zhengjian", 0);
                room->setPlayerMark(p, "&zhengjiandraw", 0);
            }
        }
        return false;
    }
};

GaoyuanCard::GaoyuanCard()
{
}

bool GaoyuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty())
        return false;

    if (to_select->hasFlag("GaoyuanSlashSource") || to_select == Self)
        return false;

    const Player *from = NULL;
    foreach (const Player *p, Self->getAliveSiblings()) {
        if (p->hasFlag("GaoyuanSlashSource")) {
            from = p;
            break;
        }
    }

    const Card *slash = Card::Parse(Self->property("gaoyuan").toString());
    if (from && !from->canSlash(to_select, slash, false))
        return false;
    return to_select->getMark("&zhengjian") > 0;
}

void GaoyuanCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->setFlags("GaoyuanTarget");
}

class GaoyuanVS : public OneCardViewAsSkill
{
public:
    GaoyuanVS() : OneCardViewAsSkill("gaoyuan")
    {
        filter_pattern = ".";
        response_pattern = "@@gaoyuan";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        GaoyuanCard *c = new GaoyuanCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class Gaoyuan : public TriggerSkill
{
public:
    Gaoyuan() : TriggerSkill("gaoyuan")
    {
        events << TargetConfirming;
        view_as_skill = new GaoyuanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();

        if (use.card->isKindOf("Slash") && use.to.contains(player) && player->canDiscard(player, "he")) {
            QList<ServerPlayer *> players = room->getOtherPlayers(player);
            players.removeOne(use.from);

            bool can_invoke = false;
            foreach (ServerPlayer *p, players) {
                if (use.from->canSlash(p, use.card, false) && p->getMark("&zhengjian") > 0) {
                    can_invoke = true;
                    break;
                }
            }

            if (can_invoke) {
                QString prompt = "@gaoyuan:" + use.from->objectName();
                room->setPlayerFlag(use.from, "GaoyuanSlashSource");
                // a temp nasty trick
                player->tag["gaoyuan-card"] = QVariant::fromValue(use.card); // for the server (AI)
                room->setPlayerProperty(player, "gaoyuan", use.card->toString()); // for the client (UI)
                if (room->askForUseCard(player, "@@gaoyuan", prompt, -1, Card::MethodDiscard)) {
                    player->tag.remove("gaoyuan-card");
                    room->setPlayerProperty(player, "gaoyuan", QString());
                    room->setPlayerFlag(use.from, "-GaoyuanSlashSource");
                    foreach (ServerPlayer *p, players) {
                        if (p->hasFlag("GaoyuanTarget")) {
                            p->setFlags("-GaoyuanTarget");
                            if (!use.from->canSlash(p, false))
                                return false;
                            use.to.removeOne(player);
                            use.to.append(p);
                            room->sortByActionOrder(use.to);
                            data = QVariant::fromValue(use);
                            room->getThread()->trigger(TargetConfirming, room, p, data);
                            return false;
                        }
                    }
                } else {
                    player->tag.remove("gaoyuan-card");
                    room->setPlayerProperty(player, "gaoyuan", QString());
                    room->setPlayerFlag(use.from, "-GaoyuanSlashSource");
                }
            }
        }
        return false;
    }
};

class Zhaohan : public PhaseChangeSkill
{
public:
    Zhaohan() : PhaseChangeSkill("zhaohan")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        int n = room->getTag("Player_Start_Phase_Num_" + player->objectName()).toInt();
        if (n <= 4) {
            room->sendCompulsoryTriggerLog(player, this, 1);
            room->gainMaxHp(player);
            room->recover(player, RecoverStruct(player));
        } else if (n > 4 && n <= 7) {
            room->sendCompulsoryTriggerLog(player, this, 2);
            room->loseMaxHp(player);
        }
        return false;
    }
};

class ZhaohanNum : public PhaseChangeSkill
{
public:
    ZhaohanNum() : PhaseChangeSkill("#zhaohan-num")
    {
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 6;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        int num = room->getTag("Player_Start_Phase_Num_" + player->objectName()).toInt();
        num++;
        room->setTag("Player_Start_Phase_Num_" + player->objectName(), num);
        return false;
    }
};

class Rangjie : public MasochismSkill
{
public:
    Rangjie() : MasochismSkill("rangjie")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        Room *room = player->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            if (player->isDead() || !player->askForSkillInvoke(this)) return;
            room->broadcastSkillInvoke(objectName());

            QStringList choices;
            if (room->canMoveField("ej"))
                choices << "move";
            choices << "BasicCard" << "TrickCard" << "EquipCard";

            QString choice = room->askForChoice(player, objectName(), choices.join("+"));
            if (choice == "move")
                room->moveField(player, objectName(), false, "ej");
            else {
                const char *ch = choice.toStdString().c_str();
                QList<int> ids;
                foreach (int id, room->getDrawPile()) {
                    if (Sanguosha->getCard(id)->isKindOf(ch))
                        ids << id;
                }
                if (ids.isEmpty()) continue;
                int id = ids.at(qrand() % ids.length());
                room->obtainCard(player, id, true);
            }
            if (player->isDead()) return;
            player->drawCards(1, objectName());
        }
    }
};

YizhengCard::YizhengCard()
{
}


bool YizhengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select) && to_select->getHp() <= Self->getHp();
}

void YizhengCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;
    Room *room = effect.from->getRoom();
    if (effect.from->pindian(effect.to, "yizheng"))
        room->addPlayerMark(effect.to, "&yizheng");
    else
        room->loseMaxHp(effect.from);
}

class YizhengVS : public ZeroCardViewAsSkill
{
public:
    YizhengVS() : ZeroCardViewAsSkill("yizheng")
    {
    }

    const Card *viewAs() const
    {
        return new YizhengCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YizhengCard") && player->canPindian();
    }
};

class Yizheng : public TriggerSkill
{
public:
    Yizheng() : TriggerSkill("yizheng")
    {
        events << EventPhaseChanging;
        view_as_skill = new YizhengVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::Draw || player->isSkipped(Player::Draw) || player->getMark("&yizheng") <= 0) return false;
        LogMessage log;
        log.type = "#YizhengEffect";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);
        room->broadcastSkillInvoke(objectName());
        room->setPlayerMark(player, "&yizheng", 0);
        player->skip(Player::Draw);
        return false;
    }
};

XingZhilveSlashCard::XingZhilveSlashCard()
{
    mute = true;
    m_skillName = "xingzhilve";
}

bool XingZhilveSlashCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(NoSuit, 0);
    slash->setSkillName("_xingzhilve");
    slash->deleteLater();
    return slash->targetFilter(targets, to_select, Self);
}

void XingZhilveSlashCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    if (card_use.from->isDead()) return;
    QList<ServerPlayer *> tos = card_use.to;
    room->sortByActionOrder(tos);
    Slash *slash = new Slash(NoSuit, 0);
    slash->setSkillName("_xingzhilve");
    slash->deleteLater();
    room->useCard(CardUseStruct(slash, card_use.from, tos), false);
}

XingZhilveCard::XingZhilveCard()
{
    target_fixed = true;
}

void XingZhilveCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->loseHp(source);
    if (source->isDead()) return;

    QStringList choices;
    if (room->canMoveField())
        choices << "move";
    choices << "draw";

    if (room->askForChoice(source, "xingzhilve", choices.join("+")) == "move")
        room->moveField(source, "xingzhilve");
    else {
        source->drawCards(1, "xingzhilve");
        if (source->isDead()) return;

        Slash *slash = new Slash(NoSuit, 0);
        slash->setSkillName("_xingzhilve");
        slash->deleteLater();

        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
            if (slash->targetFilter(QList<const Player *>(), p, source)) {
                targets << p;
            }
        }
        if (targets.isEmpty()) {
            room->addMaxCards(source, 1);
            return;
        }
        if (targets.length() == 1)
            room->useCard(CardUseStruct(slash, source, targets), false);
        else if (!room->askForUseCard(source, "@@xingzhilve!", "@xingzhilve")) {
            ServerPlayer *target = targets.at(qrand() % targets.length());
            room->useCard(CardUseStruct(slash, source, target), false);
        }
    }
    if (source->isDead()) return;
    room->addMaxCards(source, 1);
}

class XingZhilve : public ZeroCardViewAsSkill
{
public:
    XingZhilve() : ZeroCardViewAsSkill("xingzhilve")
    {
        response_pattern = "@@xingzhilve!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("XingZhilveCard");
    }

    const Card *viewAs() const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@xingzhilve!")
            return new XingZhilveSlashCard;
        return new XingZhilveCard;
    }
};

class XingWeifeng : public TriggerSkill
{
public:
    XingWeifeng() : TriggerSkill("xingweifeng")
    {
        events << CardFinished << EventPhaseStart << DamageInflicted << Death;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            if (player->isDead() || !player->hasSkill(this) || player->getPhase() != Player::Play) return false;
            if (player->getMark("xingweifeng-PlayClear") > 0) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") && !use.card->isKindOf("FireAttack") && !use.card->isKindOf("Duel") &&
                    !use.card->isKindOf("ArcheryAttack") && !use.card->isKindOf("SavageAssault")) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, use.to) {
                if (hasJuMark(p) || p == player) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;

            room->addPlayerMark(player, "xingweifeng-PlayClear");
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@xingweifeng-invoke", false, true);
            room->broadcastSkillInvoke(objectName());
            QString name = use.card->objectName();
            if (use.card->isKindOf("Slash"))
                name = "slash";
            target->gainMark("&xingju+[+" + name + "+]");
        } else if (event == DamageInflicted) {
            if (player->isDead() || !hasJuMark(player)) return false;
            DamageStruct damage = data.value<DamageStruct>();
            const Card *card = damage.card;
            if (!card) return false;
            if (!card->isKindOf("Slash") && !card->isKindOf("FireAttack") && !card->isKindOf("Duel") &&
                    !card->isKindOf("ArcheryAttack") && !card->isKindOf("SavageAssault")) return false;

            QString name = card->objectName();
            if (card->isKindOf("Slash"))
                name = "slash";

            foreach (QString mark, player->getMarkNames()) {
                if (mark.startsWith("&xingju") && player->getMark(mark) > 0) {
                    QStringList m = mark.split("+");
                    QString mm = m.at(2);

                    player->loseAllMarks(mark);

                    int n = damage.damage;
                    int x = damage.damage;
                    if (mm == name) {
                        foreach (ServerPlayer *p, room->getAllPlayers()) {
                            if (p->isDead() || !p->hasSkill(this)) continue;
                            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                            n++;
                        }
                        if (x == n) continue;
                        LogMessage log;
                        log.type = "#XingWeifeng";
                        log.from = player;
                        log.arg = QString::number(x);
                        log.arg2 = QString::number(n);
                        room->sendLog(log);

                        damage.damage = n;
                        data = QVariant::fromValue(damage);
                    } else {
                        foreach (ServerPlayer *p, room->getAllPlayers()) {
                            if (p->isDead() || !p->hasSkill(this) || player->isKongcheng()) continue;
                            room->sendCompulsoryTriggerLog(p, objectName(), true, true);

                            int id = room->askForCardChosen(p, player, "he", objectName(), false);
                            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, p->objectName());
                            room->obtainCard(p, Sanguosha->getCard(id), reason, room->getCardPlace(id) != Player::PlaceHand);
                        }
                    }
                }
            }
        } else {
            if (event == EventPhaseStart) {
                if (player->isDead() || !player->hasSkill(this)) return false;
                if (player->getPhase() != Player::Start) return false;
            } else if (event == Death) {
                ServerPlayer *who = data.value<DeathStruct>().who;
                if (who != player || !who->hasSkill(this)) return false;
            }

            bool flag = false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (hasJuMark(p)) {
                    flag = true;
                    break;
                }
            }
            if (!flag) return false;

            room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            foreach (ServerPlayer *p, room->getAllPlayers()) {
                foreach (QString mark, p->getMarkNames()) {
                    if (mark.startsWith("&xingju") && p->getMark(mark) > 0)
                        p->loseAllMarks(mark);
                }
            }
        }
        return false;
    }
private:
    bool hasJuMark(ServerPlayer *player) const
    {
        foreach (QString mark, player->getMarkNames()) {
            if (mark.startsWith("&xingju") && player->getMark(mark) > 0)
                return true;
        }
        return false;
    }
};

XingZhiyanCard::XingZhiyanCard()
{
    handling_method = Card::MethodNone;
    will_throw = false;
}

bool XingZhiyanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void XingZhiyanCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead() || effect.from->isDead()) return;
    Room *room = effect.to->getRoom();
    room->addPlayerMark(effect.from, "xingzhiyan_give-PlayClear");
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "xingzhiyan", QString());
    room->obtainCard(effect.to, this, reason, false);
}

XingZhiyanDrawCard::XingZhiyanDrawCard()
{
    target_fixed = true;
    m_skillName = "xingzhiyan";
}

void XingZhiyanDrawCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isDead()) return;
    room->addPlayerMark(source, "xingzhiyan_draw-PlayClear");
    int draw = source->getMaxHp() - source->getHandcardNum();
    if (draw <= 0) return;
    source->drawCards(draw, "xingzhiyan");
}

class XingZhiyan : public ViewAsSkill
{
public:
    XingZhiyan() : ViewAsSkill("xingzhiyan")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Self->getMark("xingzhiyan_give-PlayClear") <= 0)
            return selected.length() < (Self->getHandcardNum() - Self->getHp()) && !to_select->isEquipped();
        else if (Self->getMark("xingzhiyan_draw-PlayClear") <= 0)
            return false;
        else
            return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty() && Self->getMark("xingzhiyan_draw-PlayClear") <= 0 && Self->getMaxHp() > Self->getHandcardNum())
            return new XingZhiyanDrawCard;
        else if (!cards.isEmpty() && cards.length() == Self->getHandcardNum() - Self->getHp() &&
                 Self->getMark("xingzhiyan_give-PlayClear") <= 0 && Self->getHandcardNum() > Self->getHp()) {
            XingZhiyanCard *c = new XingZhiyanCard;
            c->addSubcards(cards);
            return c;
        } else
            return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return (player->getMark("xingzhiyan_draw-PlayClear") <= 0 && player->getMaxHp() > player->getHandcardNum()) ||
                (player->getMark("xingzhiyan_give-PlayClear") <= 0 && player->getHandcardNum() > player->getHp());
    }
};

class XingZhiyanPro : public ProhibitSkill
{
public:
    XingZhiyanPro() : ProhibitSkill("#xingzhiyan-pro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from->getMark("xingzhiyan_draw-PlayClear") > 0 && from != to && !card->isKindOf("SkillCard");
    }
};

XingJinfanCard::XingJinfanCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void XingJinfanCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->addToPile("&xingling", this);
}

class XingJinfanVS : public ViewAsSkill
{
public:
    XingJinfanVS(const QString &xingjinfan_skill) : ViewAsSkill(xingjinfan_skill), xingjinfan_skill(xingjinfan_skill)
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QList<int> ling = Self->getPile("&xingling");
        QStringList suits;
        foreach (int id, ling) {
            if (!suits.contains(Sanguosha->getCard(id)->getSuitString()))
                suits << Sanguosha->getCard(id)->getSuitString();
        }
        foreach (const Card *c, selected) {
            if (!suits.contains(c->getSuitString()))
                suits << c->getSuitString();
        }
        return !to_select->isEquipped() && !suits.contains(to_select->getSuitString());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        XingJinfanCard *c = new XingJinfanCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@" + xingjinfan_skill;
    }

private:
    QString xingjinfan_skill;
};

class XingJinfan : public TriggerSkill
{
public:
    XingJinfan() : TriggerSkill("xingjinfan")
    {
        events << EventPhaseStart << CardsMoveOneTime;
        view_as_skill = new XingJinfanVS("xingjinfan");
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Discard || player->isKongcheng()) return false;
            room->askForUseCard(player, "@@xingjinfan", "@xingjinfan");
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && move.from_places.contains(Player::PlaceSpecial) && move.from_pile_names.contains("&xingling")) {
                for (int i = 0; i < move.card_ids.length(); i++) {
                    if (move.from_places.at(i) == Player::PlaceSpecial && move.from_pile_names.at(i) == "&xingling") {
                        QList<int> list;
                        foreach (int id, room->getDrawPile()) {
                            if (Sanguosha->getCard(id)->getSuit() == Sanguosha->getCard(move.card_ids.at(i))->getSuit())
                                list << id;
                        }
                        if (list.isEmpty()) continue;
                        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                        int id = list.at(qrand() % list.length());
                        room->obtainCard(player, id, true);
                    }
                }
            }
        }
        return false;
    }
};

class XingJinfanLose : public TriggerSkill
{
public:
    XingJinfanLose(const QString &xingjinfan_skill) : TriggerSkill("#" + xingjinfan_skill +"-lose"), xingjinfan_skill(xingjinfan_skill)
    {
        events << EventLoseSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        if (data.toString() != xingjinfan_skill) return false;
        if (player->getPile("&xingling").isEmpty()) return  false;
        player->clearOnePrivatePile("&xingling");
        return false;
    }

private:
    QString xingjinfan_skill;
};

class XingSheque : public PhaseChangeSkill
{
public:
    XingSheque() : PhaseChangeSkill("xingsheque")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead() || player->getEquips().isEmpty()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (!p->canSlash(player, NULL, false)) continue;

            p->setFlags("XingshequeSlash");
            const Card *slash = room->askForUseSlashTo(p, player, "@xingsheque:" + player->objectName(), false, false, false,
                                NULL, NULL, "SlashIgnoreArmor");
            if (!slash) {
                p->setFlags("-XingshequeSlash");
                continue;
            }
        }
        return false;
    }
};

class XingShequeLog : public TriggerSkill
{
public:
    XingShequeLog() : TriggerSkill("#xingsheque-log")
    {
        events << ChoiceMade;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->hasFlag("XingshequeSlash") && data.canConvert<CardUseStruct>()) {
            room->broadcastSkillInvoke("xingsheque");
            room->notifySkillInvoked(player, "xingsheque");

            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = "xingsheque";
            room->sendLog(log);

            player->setFlags("-XingshequeSlash");
        }
        return false;
    }
};

class SecondXingJinfan : public TriggerSkill
{
public:
    SecondXingJinfan() : TriggerSkill("secondxingjinfan")
    {
        events << EventPhaseStart << CardsMoveOneTime;
        view_as_skill = new XingJinfanVS("secondxingjinfan");
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() == Player::Discard && !player->isKongcheng())
                room->askForUseCard(player, "@@secondxingjinfan", "@xingjinfan");
            else if (player->getPhase() == Player::RoundStart && !player->getPile("&xingling").isEmpty()) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                LogMessage log;
                log.type = "$KuangbiGet";
                log.from = player;
                log.arg = "&xingling";
                log.card_str = IntList2StringList(player->getPile("&xingling")).join("+");
                room->sendLog(log);
                DummyCard ling(player->getPile("&xingling"));
                room->obtainCard(player, &ling, true);
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && move.from_places.contains(Player::PlaceSpecial) &&
                    move.from_pile_names.contains("&xingling") && move.from->getPhase() == Player::NotActive) {
                for (int i = 0; i < move.card_ids.length(); i++) {
                    if (move.from_places.at(i) == Player::PlaceSpecial && move.from_pile_names.at(i) == "&xingling") {
                        QList<int> list;
                        foreach (int id, room->getDrawPile()) {
                            if (Sanguosha->getCard(id)->getSuit() == Sanguosha->getCard(move.card_ids.at(i))->getSuit())
                                list << id;
                        }
                        if (list.isEmpty()) continue;
                        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                        int id = list.at(qrand() % list.length());
                        room->obtainCard(player, id, true);
                    }
                }
            }
        }
        return false;
    }
};

class Tushe : public TriggerSkill
{
public:
    Tushe() : TriggerSkill("tushe")
    {
        events << TargetSpecified;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || use.card->isKindOf("EquipCard") || use.to.isEmpty()) return false;
        foreach (const Card *c, player->getCards("he"))
            if (c->isKindOf("BasicCard")) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        player->drawCards(use.to.length(), objectName());
        return false;
    }
};

LimuCard::LimuCard()
{
    mute = true;
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodUse;
}

void LimuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    const Card *c = Sanguosha->getCard(getSubcards().first());
    Indulgence *indulgence = new Indulgence(c->getSuit(), c->getNumber());
    indulgence->addSubcard(c);
    indulgence->setSkillName("limu");
    indulgence->deleteLater();
    if (card_use.from->isProhibited(card_use.from, indulgence)) return;
    room->useCard(CardUseStruct(indulgence, card_use.from, card_use.from), true);
    room->recover(card_use.from, RecoverStruct(card_use.from));
}

class Limu : public OneCardViewAsSkill
{
public:
    Limu() : OneCardViewAsSkill("limu")
    {
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        if (to_select->getSuit() != Card::Diamond) return false;
        Indulgence *indulgence = new Indulgence(to_select->getSuit(), to_select->getNumber());
        indulgence->addSubcard(to_select);
        indulgence->setSkillName("limu");
        indulgence->deleteLater();
        return !Self->isLocked(indulgence) && !Self->isProhibited(Self, indulgence);
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        Indulgence *indulgence = new Indulgence(Card::NoSuit, 0);
        indulgence->setSkillName("limu");
        indulgence->deleteLater();
        return player->hasJudgeArea() && !player->containsTrick("indulgence") && !Self->isProhibited(Self, indulgence);
    }

    const Card *viewAs(const Card *originalcard) const
    {
        LimuCard *c = new LimuCard;
        c->addSubcard(originalcard);
        return c;
    }
};

class LimuTargetMod : public TargetModSkill
{
public:
    LimuTargetMod() : TargetModSkill("#limu-target")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (from->hasSkill("limu") && !from->getJudgingArea().isEmpty() && to && from->inMyAttackRange(to))
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->hasSkill("limu") && !from->getJudgingArea().isEmpty() && to && from->inMyAttackRange(to))
            return 1000;
        else
            return 0;
    }
};

class TenyearFenyin : public TriggerSkill
{
public:
    TenyearFenyin() : TriggerSkill("tenyearfenyin")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
        //global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DiscardPile) return false;
        if (player->getPhase() == Player::NotActive) return false;

        QString mark = QString();
        foreach (QString m, player->getMarkNames()) {
            if (m.startsWith("&tenyearfenyin") && player->getMark(m) > 0) {
                mark = m;
                break;
            }
        }
        foreach (int id, move.card_ids) {
            const Card *c = Sanguosha->getCard(id);
            if (mark == QString() || !mark.contains(c->getSuitString() + "_char")) {
                int index = qrand() % 2 + 1;
                if (!player->getGeneralName().contains("liuzan") && !player->getGeneral2Name().contains("liuzan") &&
                        (player->getGeneralName().contains("wufan") || player->getGeneral2Name().contains("wufan")))
                    index += 2;

                room->sendCompulsoryTriggerLog(player, objectName(), true, true, index);

                if (mark != QString()) {
                    room->setPlayerMark(player, mark, 0);
                    QString len = "-Clear";
                    int length = len.length();
                    mark.chop(length);
                } else
                    mark = "&tenyearfenyin";

                mark = mark + "+" + c->getSuitString() + "_char-Clear";
                room->addPlayerMark(player, mark);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

LijiCard::LijiCard()
{
}

void LijiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->getRoom()->damage(DamageStruct("liji", effect.from, effect.to));
}

class LijiVS : public OneCardViewAsSkill
{
public:
    LijiVS() : OneCardViewAsSkill("liji")
    {
        filter_pattern = ".";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        int alive = player->getMark("liji_alive_num-Clear");
        if (alive <= 0) return false;
        int n = floor(player->getMark("&liji-Clear") / alive);
        return player->usedTimes("LijiCard") < n;
    }

    const Card *viewAs(const Card *originalcard) const
    {
        LijiCard *c = new LijiCard;
        c->addSubcard(originalcard->getId());
        return c;
    }
};

class Liji : public TriggerSkill
{
public:
    Liji() : TriggerSkill("liji")
    {
        events << CardsMoveOneTime << EventPhaseStart;
        view_as_skill = new LijiVS;
        //global = true;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseStart)
            return 5;
        else
            return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            int alive = 8;
            if (room->alivePlayerCount() < 5)
                alive = 4;
            room->setPlayerMark(player, "liji_alive_num-Clear", alive);
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to || move.to_place != Player::DiscardPile) return false;
            if (player->getPhase() == Player::NotActive) return false;
            room->addPlayerMark(player, "&liji-Clear", move.card_ids.length());
        }
        return false;
     }
};

JuesiCard::JuesiCard()
{
}

bool JuesiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && Self->inMyAttackRange(to_select);
}

void JuesiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead() || !effect.to->canDiscard(effect.to, "he")) return;

    Room *room = effect.from->getRoom();
    effect.to->tag["juesiSource"] = QVariant::fromValue(effect.from);
    const Card *c = room->askForDiscard(effect.to, "juesi", 1, 1, false, true);
    effect.to->tag.remove("juesiSource");
    if (!c) return;
    c = Sanguosha->getCard(c->getSubcards().first());
    if (!c->isKindOf("Slash") && effect.from->isAlive() && effect.from->getHp() <= effect.to->getHp()) {
        Duel *duel = new Duel(Card::NoSuit, 0);
        duel->setSkillName("_juesi");
        if (!duel->isAvailable(effect.from) || effect.from->isCardLimited(duel, Card::MethodUse) || effect.from->isProhibited(effect.to, duel)) return;
        duel->setFlags("YUANBEN");
        room->useCard(CardUseStruct(duel, effect.from, effect.to), true);
    }
}

class Juesi : public OneCardViewAsSkill
{
public:
    Juesi() : OneCardViewAsSkill("juesi")
    {
        filter_pattern = "Slash";
    }

    const Card *viewAs(const Card *originalcard) const
    {
        JuesiCard *c = new JuesiCard;
        c->addSubcard(originalcard->getId());
        return c;
    }
};

class NewShichou : public TargetModSkill
{
public:
    NewShichou() : TargetModSkill("newshichou")
    {
        frequency = NotFrequent;
    }

    int getExtraTargetNum(const Player *from, const Card *) const
    {
        if (from->hasSkill(this))
            return qMax(1, from->getLostHp());
        else
            return 0;
    }
};

TenyearNewShichouCard::TenyearNewShichouCard()
{
}

bool TenyearNewShichouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < Self->getLostHp() && to_select->hasFlag("tenyearnewshichou_canchoose");
}

void TenyearNewShichouCard::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets)
        room->setPlayerFlag(p, "tenyearnewshichou_extra_target");
}

class TenyearNewShichouVS : public ZeroCardViewAsSkill
{
public:
    TenyearNewShichouVS() : ZeroCardViewAsSkill("tenyearnewshichou")
    {
        response_pattern = "@@tenyearnewshichou";
    }

    const Card *viewAs() const
    {
        return new TenyearNewShichouCard;
    }
};

class TenyearNewShichou : public TriggerSkill
{
public:
    TenyearNewShichou() : TriggerSkill("tenyearnewshichou")
    {
        events << CardUsed << CardFinished;
        view_as_skill = new TenyearNewShichouVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || player->getLostHp() <= 0) return false;
            bool can_invoke = false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (use.to.contains(p) || !use.card->targetFilter(QList<const Player *>(), p, player)) continue;
                room->setPlayerFlag(p, "tenyearnewshichou_canchoose");
                can_invoke = true;
            }
            if (!can_invoke) return false;

            player->tag["tenyearnewshichou_data"] = data;
            if (!room->askForUseCard(player, "@@tenyearnewshichou", "@tenyearnewshichou:" + use.card->objectName())) {
                player->tag.remove("tenyearnewshichou_data");
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (!p->hasFlag("tenyearnewshichou_canchoose")) continue;
                    room->setPlayerFlag(p, "-tenyearnewshichou_canchoose");
                }
                return false;
            }
            player->tag.remove("tenyearnewshichou_data");
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->hasFlag("tenyearnewshichou_canchoose"))
                    room->setPlayerFlag(p, "-tenyearnewshichou_canchoose");
                if (p->hasFlag("tenyearnewshichou_extra_target")) {
                    room->setPlayerFlag(p, "-tenyearnewshichou_extra_target");
                    use.to.append(p);
                }
            }
            room->setCardFlag(use.card, "tenyearnewshichou_effect");
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || !use.card->hasFlag("tenyearnewshichou_effect") ||
                    use.card->hasFlag("tenyearnewshichou_damage")) return false;
            if (!room->CardInPlace(use.card, Player::DiscardPile)) return false;
            room->obtainCard(player, use.card);
        }
        return false;
    }
};

class TenyearNewShichouDamage : public TriggerSkill
{
public:
    TenyearNewShichouDamage() : TriggerSkill("#tenyearnewshichou")
    {
        events << DamageDone;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash") || !damage.card->hasFlag("tenyearnewshichou_effect")) return false;
        room->setCardFlag(damage.card, "tenyearnewshichou_damage");
        return false;
    }
};

class Zhenlve : public TriggerSkill
{
public:
    Zhenlve() : TriggerSkill("zhenlve")
    {
        events << TargetConfirmed << TrickCardCanceling;
        frequency = Compulsory;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == TargetConfirmed)
            return -1;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TrickCardCanceling) {
            CardEffectStruct effect = data.value<CardEffectStruct>();
            if (!effect.card->isNDTrick()) return false;
            if (!effect.from || effect.from->isDead() || !effect.from->hasSkill(this)) return false;
            //room->sendCompulsoryTriggerLog(effect.from, objectName(), true, true);
            return true;
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isNDTrick() || use.from->isDead() || !use.from->hasSkill(this)) return false;
            if (player != use.to.first()) return false;
            room->sendCompulsoryTriggerLog(use.from, objectName(), true, true);
        }
        return false;
    }
};

class ZhenlvePro : public ProhibitSkill
{
public:
    ZhenlvePro() : ProhibitSkill("#zhenlve-pro")
    {
    }

    bool isProhibited(const Player *, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return to->hasSkill("zhenlve") && card->isKindOf("DelayedTrick");
    }
};

JianshuCard::JianshuCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool JianshuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (to_select == Self || targets.length() >= 2) return false;
    if (targets.isEmpty()) return true;
    if (targets.length() == 1)
        return targets.first()->inMyAttackRange(to_select);
    return false;
}

bool JianshuCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void JianshuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();

    LogMessage log;
    log.from = card_use.from;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    thread->trigger(CardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void JianshuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (source->getGeneralName() == "second_new_sp_jiaxu" || (source->getGeneralName() != "new_sp_jiaxu" &&
                                                            source->getGeneral2Name() == "second_new_sp_jiaxu"))
        room->doSuperLightbox("second_new_sp_jiaxu", "jianshu");
    else
        room->doSuperLightbox("new_sp_jiaxu", "jianshu");

    room->removePlayerMark(source, "@jianshuMark");

    ServerPlayer *a = targets.first();
    ServerPlayer *b = targets.last();
    if (a->isDead() || (b != NULL && b->isDead())) return;

    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), a->objectName(), "jianshu", QString());
    room->obtainCard(a, this, reason, true);

    if (a->isDead() || !b || b->isDead() || !a->canPindian(b, false)) return;

    room->doAnimate(1, a->objectName(), b->objectName());
    int pindian = a->pindianInt(b, "jianshu");

    ServerPlayer *winner = NULL;
    QList<ServerPlayer *> losers;

    if (pindian == 1) {
        winner = a;
        losers << b;
    } else if (pindian == -1) {
        winner = b;
        losers << a;
    } else if (pindian == 0) {
        losers << a << b;
        //if (a == b)
            //losers.removeOne(a);
    }

    if (winner != NULL) {
        if (!winner->isDead())
            room->askForDiscard(winner, "jianshu", 2, 2, false, true);
    }

    if (losers.isEmpty()) return;
    room->sortByActionOrder(losers);
    foreach (ServerPlayer *p, losers) {
        if (p->isAlive())
            room->loseHp(p);
    }
}

class Jianshu : public OneCardViewAsSkill
{
public:
    Jianshu() : OneCardViewAsSkill("jianshu")
    {
        filter_pattern = ".|black|.|hand";
        frequency = Limited;
        limit_mark = "@jianshuMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@jianshuMark") > 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        JianshuCard *c = new JianshuCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class Yongdi : public PhaseChangeSkill
{
public:
    Yongdi() : PhaseChangeSkill("yongdi")
    {
        frequency = Limited;
        limit_mark = "@yongdiMark";
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark("@yongdiMark") <= 0) return false;
        Room *room = player->getRoom();

        QList<ServerPlayer *> males;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isMale())
                males << p;
        }
        if (males.isEmpty()) return false;

        ServerPlayer *male = room->askForPlayerChosen(player, males, objectName(), "@yongdi-invoke", true, true);
        if (!male) return false;

        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("new_sp_jiaxu", "yongdi");
        room->removePlayerMark(player, "@yongdiMark");

        room->gainMaxHp(male);
        room->recover(male, RecoverStruct(player));

        QStringList skills;

        foreach (const Skill *skill, male->getGeneral()->getVisibleSkillList()) {
            if (skill->isLordSkill() && !male->hasLordSkill(skill, true) && !skills.contains(skill->objectName()))
                skills << skill->objectName();
        }

        if (male->getGeneral2()) {
            foreach (const Skill *skill, male->getGeneral2()->getVisibleSkillList()) {
                if (skill->isLordSkill() && !male->hasLordSkill(skill, true) && !skills.contains(skill->objectName()))
                    skills << skill->objectName();
            }
        }

        if (skills.isEmpty()) return false;
        room->handleAcquireDetachSkills(male, skills);
        return false;
    }
};

class NewYongdi : public MasochismSkill
{
public:
    NewYongdi() : MasochismSkill("newyongdi")
    {
        frequency = Limited;
        limit_mark = "@newyongdiMark";
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        if (player->getMark("@newyongdiMark") <= 0) return;
        Room *room = player->getRoom();

        QList<ServerPlayer *> males;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isMale())
                males << p;
        }
        if (males.isEmpty()) return;

        ServerPlayer *male = room->askForPlayerChosen(player, males, objectName(), "@newyongdi-invoke", true, true);
        if (!male) return;

        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("second_new_sp_jiaxu", "newyongdi");
        room->removePlayerMark(player, "@newyongdiMark");

        room->gainMaxHp(male);

        if (male->isLord()) return;
        QStringList skills;

        foreach (const Skill *skill, male->getGeneral()->getVisibleSkillList()) {
            if (skill->isLordSkill() && !male->hasLordSkill(skill, true) && !skills.contains(skill->objectName()))
                skills << skill->objectName();
        }

        if (male->getGeneral2()) {
            foreach (const Skill *skill, male->getGeneral2()->getVisibleSkillList()) {
                if (skill->isLordSkill() && !male->hasLordSkill(skill, true) && !skills.contains(skill->objectName()))
                    skills << skill->objectName();
            }
        }

        if (skills.isEmpty()) return;
        room->handleAcquireDetachSkills(male, skills);
        return;
    }
};

NewxuehenCard::NewxuehenCard()
{
}

bool NewxuehenCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    return targets.length() < Self->getLostHp();
}

void NewxuehenCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (p->isAlive() && !p->isChained()) {
            room->setPlayerChained(p);
        }
    }
    if (source->isDead()) return;

    ServerPlayer *to = room->askForPlayerChosen(source, targets, "newxuehen", "@newxuehen-invoke");
    room->doAnimate(1, source->objectName(), to->objectName());
    room->damage(DamageStruct("newxuehen", source, to, 1, DamageStruct::Fire));
}

class Newxuehen : public OneCardViewAsSkill
{
public:
    Newxuehen() : OneCardViewAsSkill("newxuehen")
    {
        filter_pattern = ".|red";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("NewxuehenCard") && player->getLostHp() > 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        NewxuehenCard *card = new NewxuehenCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class NewHuxiao : public TriggerSkill
{
public:
    NewHuxiao() : TriggerSkill("newhuxiao")
    {
        events << Damage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.nature != DamageStruct::Fire || !damage.from || damage.from->isDead() || !damage.from->hasSkill(this) ||
            damage.to->isDead()) return false;
        room->sendCompulsoryTriggerLog(damage.from, objectName(), true, true);
        damage.to->drawCards(1, objectName());
        room->addPlayerMark(damage.from, "newhuxiao_from-Clear");
        room->addPlayerMark(damage.to, "newhuxiao_to-Clear");
        return false;
    }
};

class NewHuxiaoTargetMod : public TargetModSkill
{
public:
    NewHuxiaoTargetMod() : TargetModSkill("#newhuxiao-target")
    {
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("newhuxiao_from-Clear") > 0 && to && to->getMark("newhuxiao_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

class NewWuji : public PhaseChangeSkill
{
public:
    NewWuji() : PhaseChangeSkill("newwuji")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Finish || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMark("damage_point_round") >= 3) {
            LogMessage log;
            log.type = "#WujiWake";
            log.from = player;
            log.arg = QString::number(player->getMark("damage_point_round"));
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());

        room->broadcastSkillInvoke(objectName());

        room->doSuperLightbox("new_guanyinping", "newwuji");

        room->setPlayerMark(player, "newwuji", 1);
        if (room->changeMaxHpForAwakenSkill(player, 1)) {
            room->recover(player, RecoverStruct(player));

            if (player->isAlive())
                room->handleAcquireDetachSkills(player, "-newhuxiao");

            if (player->isDead()) return false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                foreach (const Card *c, p->getCards("ej")) {
                    if (Sanguosha->getEngineCard(c->getEffectiveId())->objectName() == "blade") {
                        room->obtainCard(player, c, true);
                        return false;
                    }
                }
            }

            QList<int> list = room->getDrawPile() + room->getDiscardPile();
            foreach (int id, list) {
                if (Sanguosha->getEngineCard(id)->objectName() == "blade") {
                    room->obtainCard(player, id, true);
                    return false;
                }
            }
        }
        return false;
    }
};

class ZishuGet : public TriggerSkill
{
public:
    ZishuGet() : TriggerSkill("#zishu-get")
    {
        events << CardsMoveOneTime << EventPhaseChanging;
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseChanging)
            return TriggerSkill::getPriority(triggerEvent) - 1;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            if (room->getTag("FirstRound").toBool() || !room->hasCurrent() || room->getCurrent() == player) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to && move.to->isAlive() && move.to_place == Player::PlaceHand) {
                QVariantList ids = player->tag["Zishu_ids"].toList();
                foreach (int id, move.card_ids) {
                    if (ids.contains(QVariant(id))) continue;
                    ids << id;
                }
                player->tag["Zishu_ids"] = ids;
            }
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers(true))
                p->tag.remove("Zishu_ids");
        }
        return false;
    }
};

class Zishu : public TriggerSkill
{
public:
    Zishu() : TriggerSkill("zishu")
    {
        events << CardsMoveOneTime << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead() || !p->hasSkill(this)) continue;
                QVariantList ids = p->tag["Zishu_ids"].toList();
                if (ids.isEmpty()) continue;
                QList<int> list;
                foreach (int id, p->handCards()) {
                    if (ids.contains(QVariant(id)) && p->canDiscard(p, id))
                        list << id;
                }
                if (list.isEmpty()) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true, 2);
                DummyCard *dummy = new DummyCard(list);
                room->throwCard(dummy, p, NULL);
                delete dummy;
            }
        } else {
            if (player->getPhase() == Player::NotActive || !player->hasSkill(this)) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.to || move.to != player || move.to_place != Player::PlaceHand || move.reason.m_skillName == objectName()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true, 1);
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class Yingyuan : public TriggerSkill
{
public:
    Yingyuan() : TriggerSkill("yingyuan")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive) return false;
        const Card *card = NULL;
        if (event == CardUsed)
            card = data.value<CardUseStruct>().card;
        else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse) return false;
            card = res.m_card;
        }

        if (card == NULL || card->isKindOf("SkillCard")) return false;
        if (player->getMark("yingyuan" + card->getType() + "-Clear") > 0) return false;

        player->tag["yingyuanCard"] = QVariant::fromValue(card);
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@yingyuan:" + card->getType(), true, true);
        player->tag.remove("yingyuanCard");
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, "yingyuan" + card->getType() + "-Clear");

        QList<int> list;
        foreach (int id, room->getDrawPile()) {
            if (Sanguosha->getCard(id)->getType() == card->getType())
                list << id;
        }
        if (list.isEmpty()) return false;

        int id = list.at(qrand() % list.length());
        room->obtainCard(target, id, true);

        return false;
    }
};

class MobileYingyuan : public TriggerSkill
{
public:
    MobileYingyuan() : TriggerSkill("mobileyingyuan")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive) return false;

        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DiscardPile) return false;
        if (move.from_places.contains(Player::PlaceTable) && (move.reason.m_reason == CardMoveReason::S_REASON_USE ||
             move.reason.m_reason == CardMoveReason::S_REASON_LETUSE)) {
            const Card *card = move.reason.m_extraData.value<const Card *>();
            if (!card || card->isKindOf("SkillCard") || !room->CardInPlace(card, Player::DiscardPile)) return false;
            if (!move.from || move.from != player) return false;

            QString name = card->objectName();
            if (card->isKindOf("Slash"))
                name = "slash";
            if (player->getMark("mobileyingyuan" + name + "-Clear") > 0) return false;

            player->tag["mobileyingyuanCard"] = QVariant::fromValue(card);
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(),
                                                            "@mobileyingyuan:" + card->objectName(), true, true);
            player->tag.remove("mobileyingyuanCard");
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "mobileyingyuan" + name + "-Clear");

            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "mobileyingyuan", QString());
            room->obtainCard(target, card, reason, true);
        }
        return false;
    }
};

class NewZhendu : public PhaseChangeSkill
{
public:
    NewZhendu() : PhaseChangeSkill("newzhendu")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (player->getPhase() != Player::Play)
            return false;

        foreach (ServerPlayer *hetaihou, room->getAllPlayers()) {
            if (!TriggerSkill::triggerable(hetaihou))
                continue;

            if (!hetaihou->isAlive() || !hetaihou->canDiscard(hetaihou, "h"))
                continue;
            if (room->askForCard(hetaihou, ".", "@newzhendu-discard:" + player->objectName(), QVariant::fromValue(player), objectName())) {
                Analeptic *analeptic = new Analeptic(Card::NoSuit, 0);
                analeptic->setSkillName("_newzhendu");
                room->useCard(CardUseStruct(analeptic, player, QList<ServerPlayer *>()), true);
                if (player != hetaihou && player->isAlive())
                    room->damage(DamageStruct(objectName(), hetaihou, player));
            }
        }
        return false;
    }
};

class NewQiluan : public TriggerSkill
{
public:
    NewQiluan() : TriggerSkill("newqiluan")
    {
        events << Death << EventPhaseChanging;
        frequency = Frequent;
        global = true;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player)
                return false;
            if (!room->hasCurrent()) return false;
            ServerPlayer *killer = death.damage ? death.damage->from : NULL;
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                int n = 1;
                if (killer && killer == p)
                    n = 3;
                p->addMark("newqiluan-Clear", n);
            }
        } else {
            if (!room->hasCurrent()) return false;
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isAlive() && p->getMark("newqiluan-Clear") > 0 && p->hasSkill(this) && p->askForSkillInvoke(this)) {
                        room->broadcastSkillInvoke(objectName());
                        p->drawCards(p->getMark("newqiluan-Clear"), objectName());
                    }
                }
            }
        }
        return false;
    }
};

LizhanCard::LizhanCard()
{
}

bool LizhanCard::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *) const
{
    return to_select->isWounded();
}

void LizhanCard::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const
{
    room->drawCards(targets, 1, "lizhan");
}

class LizhanVS : public ZeroCardViewAsSkill
{
public:
    LizhanVS() : ZeroCardViewAsSkill("lizhan")
    {
        response_pattern = "@@lizhan";
    }

    const Card *viewAs() const
    {
        return new LizhanCard;
    }
};

class Lizhan : public TriggerSkill
{
public:
    Lizhan() : TriggerSkill("lizhan")
    {
        events << EventPhaseChanging;
        view_as_skill = new LizhanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        bool has_wounded = false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isWounded()) {
                has_wounded = true;
                break;
            }
        }
        if (!has_wounded) return false;
        room->askForUseCard(player, "@@lizhan", "@lizhan");
        return false;
    }
};

WeikuiCard::WeikuiCard()
{
}

bool WeikuiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void WeikuiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->loseHp(effect.from);
    if (effect.from->isDead() || effect.to->isDead() || effect.to->isKongcheng()) return;

    QList<int> dis;
    bool has_jink = false;
    foreach (const Card *c, effect.to->getCards("h")) {
        if (c->isKindOf("Jink"))
            has_jink = true;
        if (effect.from->canDiscard(effect.to, c->getEffectiveId()))
            dis << c->getEffectiveId();
    }

    int id = room->doGongxin(effect.from, effect.to, dis, "weikui");

    if (has_jink) {
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("_weikui");
        slash->deleteLater();
        if (effect.from->canSlash(effect.to, slash, false))
            room->useCard(CardUseStruct(slash, effect.from, effect.to), false);
        room->setPlayerMark(effect.from, "fixed_distance_to_" + effect.to->objectName() + "-Clear", 1);
    } else {
        if (!effect.from->canDiscard(effect.to, id)) return;
        room->throwCard(id, effect.to, effect.from);
    }
}

class Weikui : public ZeroCardViewAsSkill
{
public:
    Weikui() : ZeroCardViewAsSkill("weikui")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("WeikuiCard");
    }

    const Card *viewAs() const
    {
        return new WeikuiCard;
    }
};

class YingjianVS : public ZeroCardViewAsSkill
{
public:
    YingjianVS() : ZeroCardViewAsSkill("yingjian")
    {
        response_pattern = "@@yingjian";
    }

    const Card *viewAs() const
    {
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("yingjian");
        return slash;
    }
};

class Yingjian : public PhaseChangeSkill
{
public:
    Yingjian() : PhaseChangeSkill("yingjian")
    {
        view_as_skill = new YingjianVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("yingjian");
        slash->deleteLater();

        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->canSlash(p, slash, false)) {
                room->askForUseCard(player, "@@yingjian", "@yingjian");
                return false;
            }
        }
        return false;
    }
};

MubingCard::MubingCard()
{
    mute = true;
    target_fixed = true;
    will_throw = false;
}

void MubingCard::onUse(Room *, const CardUseStruct &) const
{
}

class MubingVS : public ViewAsSkill
{
public:
    MubingVS() : ViewAsSkill("mubing")
    {
        response_pattern = "@@mubing";
        expand_pile = "#mubing";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped()) return false;
        if (selected.isEmpty()) return true;

        int hand = 0;
        int pile = 0;
        foreach (const Card *card, selected) {
            if (Self->getHandcards().contains(card))
                hand += card->getNumber();
            else if (Self->getPile("#mubing").contains(card->getEffectiveId()))
                pile += card->getNumber();
        }
        if (Self->getHandcards().contains(to_select))
            return hand + to_select->getNumber() >= pile;
        else if (Self->getPile("#mubing").contains(to_select->getEffectiveId()))
            return hand >= pile + to_select->getNumber();
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hand = 0;
        int hand_num = 0;
        int pile = 0;
        int pile_num = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card)) {
                hand += card->getNumber();
                hand_num++;
            } else if (Self->getPile("#mubing").contains(card->getEffectiveId())) {
                pile += card->getNumber();
                pile_num++;
            }
        }

        if (hand >= pile && hand_num > 0 && pile_num > 0) {
            MubingCard *c = new MubingCard;
            c->addSubcards(cards);
            return c;
        }

        return NULL;
    }
};

class Mubing : public PhaseChangeSkill
{
public:
    Mubing() : PhaseChangeSkill("mubing")
    {
        view_as_skill = new MubingVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        bool up = player->property("mubing_levelup").toBool();
        int show_num = 3;
        if (up)
            show_num++;

        QList<int> list = room->showDrawPile(player, show_num, objectName(), false);
        room->fillAG(list);
        room->getThread()->delay();
        room->notifyMoveToPile(player, list, objectName(), Player::DrawPile, true);

        const Card *c = room->askForUseCard(player, "@@mubing", "@mubing");

        room->clearAG();
        room->notifyMoveToPile(player, list, objectName(), Player::DrawPile, false);

        if (!c) return false;

        DummyCard *dummy = new DummyCard;
        DummyCard *card = new DummyCard;
        DummyCard *all = new DummyCard;

        dummy->deleteLater();
        card->deleteLater();
        all->deleteLater();

        all->addSubcards(list);

        foreach (int id, c->getSubcards()) {
            if (!player->handCards().contains(id)) {
                list.removeOne(id);
                card->addSubcard(id);
            } else
                dummy->addSubcard(id);
        }

        room->clearAG();

        LogMessage log;
        log.type = "$DiscardCardWithSkill";
        log.from = player;
        log.arg = objectName();
        log.card_str = IntList2StringList(dummy->getSubcards()).join("+");
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());

        CardMoveReason reason(CardMoveReason::S_REASON_THROW, player->objectName(), QString(), "mubing", QString());
        room->moveCardTo(dummy, player, NULL, Player::DiscardPile, reason, true);
        if (player->isAlive()) {
            CardMoveReason reason(CardMoveReason::S_REASON_UNKNOWN, player->objectName(), objectName(), QString());
            room->obtainCard(player, card, reason, true);
            if (!list.isEmpty()) {
                DummyCard *left = new DummyCard;
                left->addSubcards(list);
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, QString(), objectName(), QString());
                room->throwCard(left, reason, NULL);
                delete left;
            }
            if (up && player->isAlive()) {
                QList<int> give = card->getSubcards();
                while (room->askForYiji(player, give, objectName(), false, true)) {
                    if (player->isDead()) break;
                }
            }
        } else {
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, QString(), objectName(), QString());
            room->throwCard(all, reason, NULL);
        }
        return false;
    }
};

ZiquCard::ZiquCard()
{
    mute = true;
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void ZiquCard::onUse(Room *, const CardUseStruct &) const
{
}

class ZiquVS : public OneCardViewAsSkill
{
public:
    ZiquVS() : OneCardViewAsSkill("ziqu")
    {
        response_pattern = "@@ziqu!";
    }

    bool viewFilter(const Card *to_select) const
    {
        int num = Self->getHandcards().first()->getNumber();
        QList<const Card *> cards = Self->getHandcards() + Self->getEquips();
        foreach (const Card *c, cards) {
            if (c->getNumber() > num)
                num = c->getNumber();
        }
        return to_select->getNumber() >= num;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ZiquCard *card = new ZiquCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Ziqu : public TriggerSkill
{
public:
    Ziqu() : TriggerSkill("ziqu")
    {
        events << DamageCaused;
        view_as_skill = new ZiquVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead() || damage.to == player) return false;
        QStringList names = player->property("ziqu_names").toStringList();
        if (names.contains(damage.to->objectName())) return false;
        if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.to))) return false;
        room->broadcastSkillInvoke(objectName());
        names << damage.to->objectName();
        room->setPlayerProperty(player, "ziqu_names", names);
        if (!damage.to->isNude()) {
            QList<const Card *> big;
            const Card *give = NULL;
            int num = damage.to->getCards("he").first()->getNumber();
            foreach (const Card *c, damage.to->getCards("he")) {
                if (c->getNumber() > num)
                    num = c->getNumber();
            }
            foreach (const Card *c, damage.to->getCards("he")) {
                if (c->getNumber() >= num)
                    big << c;
            }
            if (big.length() == 1)
                give = big.first();
            else
                give = room->askForUseCard(damage.to, "@@ziqu!", "@ziqu:" + player->objectName());
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, damage.to->objectName(), player->objectName(), objectName(), QString());
            if (give == NULL)
                give = big.at(qrand() % big.length());
            if (give == NULL) return false;
            room->obtainCard(player, give, reason, true);
        }
        return true;
    }
};

class Diaoling : public PhaseChangeSkill
{
public:
    Diaoling() : PhaseChangeSkill("diaoling")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        int mark = player->getMark("&mubing") + player->getMark("mubing_num");
        if (mark >= 6) {
            LogMessage log;
            log.type = "#DiaolingWake";
            log.from = player;
            log.arg = "mubing";
            log.arg2 = QString::number(mark);
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(player, objectName());
        room->doSuperLightbox("sp_zhangliao", objectName());
        room->setPlayerProperty(player, "mubing_levelup", true);
        room->setPlayerMark(player, objectName(), 1);
        if (room->changeMaxHpForAwakenSkill(player, 0)) {
            QStringList choices;
            if (player->getLostHp() > 0)
                choices << "recover";
            choices << "draw";
            if (room->askForChoice(player, objectName(), choices.join("+")) == "recover")
                room->recover(player, RecoverStruct(player));
            else
                player->drawCards(2, objectName());
            if (player->hasSkill("mubing", true)) {
                LogMessage log;
                log.type = "#JiexunChange";
                log.from = player;
                log.arg = "mubing";
                room->sendLog(log);
            }
            QString translate = Sanguosha->translate(":mubing2");
            room->changeTranslation(player, "mubing", translate);
        }
        return false;
    }
};

class DiaolingRecord : public TriggerSkill
{
public:
    DiaolingRecord() : TriggerSkill("#diaoling-record")
    {
        events << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.reason.m_skillName != "mubing") return false;
        if (!move.to || move.to_place != Player::PlaceHand) return false;
        int n = 0;
        foreach (int id, move.card_ids) {
            const Card *c = Sanguosha->getCard(id);
            if (c->isKindOf("Slash"))
                n++;
            else if (c->isKindOf("Weapon"))
                n++;
            else if (c->isKindOf("TrickCard") && c->isDamageCard())
                n++;
        }
        if (n <= 0) return false;
        if (player->hasSkill("diaoling", true) && player->getMark("diaoling") <= 0)
            room->addPlayerMark(player, "&mubing", n);
        else
            room->addPlayerMark(player, "mubing_num", n);
        return false;
    }
};

SpMouzhuCard::SpMouzhuCard()
{
}

bool SpMouzhuCard::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const
{
    if (to_select == Self) return false;
    QString choice = Self->tag["spmouzhu"].toString();
    if (choice == "distance")
        return Self->distanceTo(to_select) == 1;
    else
        return to_select->getHp() == Self->getHp();
    return false;
}

void SpMouzhuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) return;
        if (p->isDead() || p->isKongcheng()) continue;
        room->cardEffect(this, source, p);
    }
}

void SpMouzhuCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from, *p = effect.to;
    Room *room = source->getRoom();

    const Card *c = room->askForExchange(p, "spmouzhu", 1, 1, false, "@spmouzhu-give:" + source->objectName());
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, p->objectName(), source->objectName(), "spmouzhu", QString());
    room->obtainCard(source, c, reason, false);
    if (p->isDead() || source->isDead() || p->getHandcardNum() >= source->getHandcardNum()) return;

    Slash *slash = new Slash(Card::NoSuit, 0);
    Duel *duel = new Duel(Card::NoSuit, 0);
    slash->setSkillName("_spmouzhu");
    duel->setSkillName("_spmouzhu");
    slash->deleteLater();
    duel->deleteLater();

    QStringList choices;
    if (!p->isCardLimited(slash, Card::MethodUse) && p->canSlash(source, slash, false))
        choices << "slash";
    if (!p->isCardLimited(duel, Card::MethodUse) && !p->isProhibited(source, duel))
        choices << "duel";
    if (choices.isEmpty()) return;

    QString choice = room->askForChoice(p, "spmouzhu", choices.join("+"));
    if (choice == "slash")
        room->useCard(CardUseStruct(slash, p, source));
    else
        room->useCard(CardUseStruct(duel, p, source));
}

class SpMouzhu : public ZeroCardViewAsSkill
{
public:
    SpMouzhu() : ZeroCardViewAsSkill("spmouzhu")
    {
    }

    const Card *viewAs() const
    {
        return new SpMouzhuCard;
    }

    QDialog *getDialog() const
    {
        return TiansuanDialog::getInstance("spmouzhu", "distance,hp");
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SpMouzhuCard");
    }
};

class SpYanhuo : public TriggerSkill
{
public:
    SpYanhuo() : TriggerSkill("spyanhuo")
    {
        events << Death << ConfirmDamage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player || !player->hasSkill(this)) return false;
            if (!player->askForSkillInvoke(this)) return false;
            player->peiyin(this);
            int num = room->getTag("SpYanhuoSlashDamage").toInt();
            room->setTag("SpYanhuoSlashDamage", ++num);
            room->addPlayerMark(player, "&spyanhuo-Keep");
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            int num = room->getTag("SpYanhuoSlashDamage").toInt();
            if (num <= 0) return false;

            LogMessage log;
            log.type = "#SPYanhuoDamage";
            log.from = player;
            log.arg = objectName();
            log.arg2 = QString::number(num);
            room->sendLog(log);

            damage.damage += num;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

BeizhuCard::BeizhuCard()
{
}

bool BeizhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void BeizhuCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead() || effect.to->isKongcheng()) return;

    Room *room = effect.from->getRoom();
    room->doGongxin(effect.from, effect.to, QList<int>(), "beizhu");

    QList<int> slashs;
    foreach (const Card *c, effect.to->getCards("h")) {
        if (c->isKindOf("Slash")) {
            slashs << c->getEffectiveId();
        }
    }
    if (slashs.isEmpty()) {
        if (!effect.from->canDiscard(effect.to, "he")) return;
        int card_id = room->askForCardChosen(effect.from, effect.to, "he", "beizhu", true, Card::MethodDiscard);
        room->throwCard(card_id, effect.to, effect.from);
        if (effect.from->isDead() || effect.to->isDead()) return;
        QList<int> slash_ids;
        foreach (int id, room->getDrawPile()) {
            if (Sanguosha->getCard(id)->isKindOf("Slash"))
                slash_ids << id;
        }
        if (slash_ids.isEmpty()) return;
        if (!effect.from->askForSkillInvoke("beizhu", QString("beizhu:" + effect.to->objectName()), false)) return;
        room->obtainCard(effect.to, slash_ids.at(qrand() % slash_ids.length()), true);
    } else {
        try {
            QVariantList list = effect.from->tag["beizhu_slash"].toList();
            foreach (int id, slashs) {
                //if (list.contains(QVariant(id))) continue;
                list << id;
            }
            effect.from->tag["beizhu_slash"] = list;
            foreach (int id, slashs) {
                const Card *slash = Sanguosha->getCard(id);
                if (!effect.to->canSlash(effect.from, slash, false)) continue;
                room->useCard(CardUseStruct(slash, effect.to, effect.from));
            }
            effect.from->tag.remove("beizhu_slash");
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                effect.from->tag.remove("beizhu_slash");
            throw triggerEvent;
        }
    }
}

class BeizhuVS : public ZeroCardViewAsSkill
{
public:
    BeizhuVS() : ZeroCardViewAsSkill("beizhu")
    {
    }

    const Card *viewAs() const
    {
        return new BeizhuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("BeizhuCard");
    }
};

class Beizhu : public MasochismSkill
{
public:
    Beizhu() : MasochismSkill("beizhu")
    {
        view_as_skill = new BeizhuVS;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        if (!damage.card || !damage.card->isKindOf("Slash")) return;
        QVariantList list = player->tag["beizhu_slash"].toList();
        if (!list.contains(damage.card->getEffectiveId())) return;
        list.removeOne(damage.card->getEffectiveId());
        player->tag["beizhu_slash"] = list;
        player->getRoom()->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(damage.damage, objectName());
    }
};

class Chengzhao : public PhaseChangeSkill
{
public:
    Chengzhao() : PhaseChangeSkill("chengzhao")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive() && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (p->getMark("chengzhao-Clear") < 2) continue;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *t, room->getOtherPlayers(p)) {
                if (p->canPindian(t))
                    targets << t;
            }
            if (targets.isEmpty()) continue;
            ServerPlayer *target = room->askForPlayerChosen(p, targets, objectName(), "@chengzhao-invoke", true, true);
            if (!target || !p->canPindian(target, false)) continue;
            room->broadcastSkillInvoke(objectName());
            if (!p->pindian(target, objectName())) continue;
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_chengzhao");
            slash->deleteLater();
            if (!p->canSlash(target, slash, false)) continue;
            target->addQinggangTag(slash);
            room->useCard(CardUseStruct(slash, p, target));
        }
        return false;
    }
};

class ChengzhaoRecord : public TriggerSkill
{
public:
    ChengzhaoRecord() : TriggerSkill("#chengzhao-record")
    {
        events << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to && move.to == player && move.to_place == Player::PlaceHand)
            room->addPlayerMark(player, "chengzhao-Clear", move.card_ids.length());
        return false;
    }
};

XuezhaoCard::XuezhaoCard(const QString &xuezhao) : xuezhao(xuezhao)
{
}

bool XuezhaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (xuezhao == "xuezhao")
        return targets.length() < Self->getHp() && to_select != Self;
    else if (xuezhao == "secondxuezhao")
        return targets.length() < Self->getMaxHp() && to_select != Self;
    return false;
}

void XuezhaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QVariant data = QVariant::fromValue(source);
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) return;
        if (p->isDead()) continue;
        const Card *card = room->askForCard(p, "..", "@" + xuezhao + "-give:" + source->objectName(), data, Card::MethodNone);
        if (card) {
            room->giveCard(p, source, card, xuezhao);
            p->drawCards(1, xuezhao);
            if (source->isAlive())
                room->addSlashCishu(source, 1);
        } else
            room->addPlayerMark(p, xuezhao + "_no_respond" + source->objectName() + "-Clear");
    }
}

SecondXuezhaoCard::SecondXuezhaoCard() : XuezhaoCard("secondxuezhao")
{
}

class XuezhaoVS : public OneCardViewAsSkill
{
public:
    XuezhaoVS(const QString &xuezhao) : OneCardViewAsSkill(xuezhao), xuezhao(xuezhao)
    {
        filter_pattern = ".|.|.|hand!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        QString classname = "XuezhaoCard";
        if (xuezhao == "secondxuezhao")
            classname = "SecondXuezhaoCard";
        return !player->hasUsed(classname);
    }

    const Card *viewAs(const Card *originalcard) const
    {
        if (xuezhao == "xuezhao") {
            XuezhaoCard *card = new XuezhaoCard;
            card->addSubcard(originalcard);
            return card;
        } else if (xuezhao == "secondxuezhao") {
            SecondXuezhaoCard *card = new SecondXuezhaoCard;
            card->addSubcard(originalcard);
            return card;
        }
        return NULL;
    }
private:
    QString xuezhao;
};

class Xuezhao : public TriggerSkill
{
public:
    Xuezhao(const QString &xuezhao) : TriggerSkill(xuezhao), xuezhao(xuezhao)
    {
        events << TargetSpecified;
        view_as_skill = new XuezhaoVS(xuezhao);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.from || use.card->isKindOf("SkillCard")) return false;
        QList<ServerPlayer *> no_responds;
        foreach (ServerPlayer *p, use.to) {
            if (p->getMark(xuezhao + "_no_respond" + use.from->objectName() + "-Clear") > 0) {
                no_responds << p;
                use.no_respond_list << p->objectName();
            }
        }
        if (no_responds.isEmpty()) return false;
        LogMessage log;
        log.type = "#FuqiNoResponse";
        log.from = use.from;
        log.arg = objectName();
        log.card_str = use.card->toString();
        log.to = no_responds;
        room->sendLog(log);
        room->notifySkillInvoked(use.from, objectName());
        room->broadcastSkillInvoke(objectName());
        data = QVariant::fromValue(use);
        return false;
    }
private:
    QString xuezhao;
};

NewZhoufuCard::NewZhoufuCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool NewZhoufuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getPile("incantation").isEmpty();
}

void NewZhoufuCard::use(Room *, ServerPlayer *, QList<ServerPlayer *> &targets) const
{
    targets.first()->addToPile("incantation", this);
}

TenyearZhoufuCard::TenyearZhoufuCard() : NewZhoufuCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

class NewZhoufuVS : public OneCardViewAsSkill
{
public:
    NewZhoufuVS(const QString &zhoufu) : OneCardViewAsSkill(zhoufu), zhoufu(zhoufu)
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (zhoufu == "newzhoufu")
            return !player->hasUsed("NewZhoufuCard");
        else if (zhoufu == "tenyearzhoufu")
            return !player->hasUsed("TenyearZhoufuCard");
        return false;
    }

    const Card *viewAs(const Card *originalcard) const
    {
        if (zhoufu == "newzhoufu") {
            NewZhoufuCard *card = new NewZhoufuCard;
            card->addSubcard(originalcard);
            return card;
        } else if (zhoufu == "tenyearzhoufu") {
            TenyearZhoufuCard *card = new TenyearZhoufuCard;
            card->addSubcard(originalcard);
            return card;
        }
        return NULL;
    }
private:
    QString zhoufu;
};

class NewZhoufu : public TriggerSkill
{
public:
    NewZhoufu(const QString &zhoufu) : TriggerSkill(zhoufu), zhoufu(zhoufu)
    {
        events << StartJudge << EventPhaseChanging;
        view_as_skill = new NewZhoufuVS(zhoufu);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == StartJudge) {
            if (player->getPile("incantation").isEmpty()) return false;
            int card_id = player->getPile("incantation").first();

            JudgeStruct *judge = data.value<JudgeStruct *>();
            judge->card = Sanguosha->getCard(card_id);

            LogMessage log;
            log.type = "$ZhoufuJudge";
            log.from = player;
            log.arg = objectName();
            log.card_str = QString::number(judge->card->getEffectiveId());
            room->sendLog(log);

            room->moveCardTo(judge->card, NULL, judge->who, Player::PlaceJudge,
                CardMoveReason(CardMoveReason::S_REASON_JUDGE,
                judge->who->objectName(),
                QString(), QString(), judge->reason), true);
            judge->updateResult();
            room->setTag("SkipGameRule", true);
        } else {
            if (zhoufu != "newzhoufu") return false;
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *zhangbao, room->getAllPlayers()) {
                    if (zhangbao->isDead() || !zhangbao->hasSkill(this)) continue;
                    bool send = true;
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (p->isDead() || p->getMark("newzhoufu_lost-Clear") <= 0) continue;
                        if (send) {
                            send = false;
                            room->sendCompulsoryTriggerLog(zhangbao, objectName(), true, true);
                        }
                        room->loseHp(p);
                    }
                }
            }
        }
        return false;
    }
private:
    QString zhoufu;
};

class NewZhoufuRecord : public TriggerSkill
{
public:
    NewZhoufuRecord() : TriggerSkill("#newzhoufu-record")
    {
        events << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from && move.from == player && move.from_places.contains(Player::PlaceSpecial)
                && move.from_pile_names.contains("incantation")) {
            room->addPlayerMark(player, "newzhoufu_lost-Clear");
        }
        return false;
    }
};

class NewYingbing : public TriggerSkill
{
public:
    NewYingbing() : TriggerSkill("newyingbing")
    {
        events << CardUsed << CardResponded;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPile("incantation").length() > 0;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == CardUsed)
            card = data.value<CardUseStruct>().card;
        else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse) return false;
            card = res.m_card;
        }

        if (card == NULL || card->isKindOf("SkillCard")) return false;

        foreach (ServerPlayer *zhangbao, room->getAllPlayers()) {
            if (zhangbao->isDead() || !zhangbao->hasSkill(this) || player->getPile("incantation").isEmpty()) continue;

            foreach (int id, player->getPile("incantation")) {
                const Card *c = Sanguosha->getCard(id);
                if (c->getSuit() != card->getSuit()) continue;
                room->sendCompulsoryTriggerLog(zhangbao, objectName(), true, true);
                zhangbao->drawCards(1, objectName());

                int num = zhangbao->tag["newyingbing" + QString::number(id)].toInt();
                zhangbao->tag["newyingbing" + QString::number(id)] = ++num;

                if (zhangbao->tag["newyingbing" + QString::number(id)].toInt() > 1) {
                    zhangbao->tag.remove("newyingbing" + QString::number(id));
                    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), objectName(), QString());
                    room->throwCard(Sanguosha->getCard(id), reason, NULL);
                }
            }
        }
        return false;
    }
};

class TenyearYingbing : public TriggerSkill
{
public:
    TenyearYingbing() : TriggerSkill("tenyearyingbing")
    {
        events << TargetSpecified;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (p->getPile("incantation").isEmpty()) continue;
            if (player->getMark("tenyearyingbing_" + p->objectName() + "-Clear") > 0) continue;
            room->addPlayerMark(player, "tenyearyingbing_" + p->objectName() + "-Clear");
            room->sendCompulsoryTriggerLog(player, this);
            player->drawCards(2, objectName());
        }
        return false;
    }
};

LiushiCard::LiushiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool LiushiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(NoSuit, 0);
    slash->deleteLater();
    slash->setSkillName("_liushi");
    return !Self->isLocked(slash) && slash->targetFilter(targets, to_select, Self);
}

void LiushiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    CardMoveReason reason(CardMoveReason::S_REASON_PUT, effect.from->objectName(), "liushi", QString());
    room->moveCardTo(this, NULL, Player::DrawPile, reason, true);

    if (effect.from->isDead() || effect.to->isDead()) return;
    Slash *slash = new Slash(NoSuit, 0);
    slash->deleteLater();
    slash->setSkillName("_liushi");
    room->setCardFlag(slash, "liushi_slash");
    if (effect.from->isCardLimited(slash, Card::MethodUse) || !effect.from->canSlash(effect.to, slash, false)) return;
    room->useCard(CardUseStruct(slash, effect.from, effect.to), false);
}

class LiushiVS : public OneCardViewAsSkill
{
public:
    LiushiVS() : OneCardViewAsSkill("liushi")
    {
        filter_pattern = ".|heart";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        LiushiCard *c = new LiushiCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class Liushi : public TriggerSkill
{
public:
    Liushi() : TriggerSkill("liushi")
    {
        events << DamageComplete;
        view_as_skill = new LiushiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash") ||
                (damage.card->getSkillName() != objectName() && !damage.card->hasFlag("liushi_slash"))) return false;
        int n = player->tag["LiushiDamage"].toInt();
        player->tag["LiushiDamage"] = ++n;
        room->addMaxCards(player, -1, false);
        room->setPlayerMark(player, "&liushi", n);
        return false;
    }
};

class Zhanwan : public TriggerSkill
{
public:
    Zhanwan() : TriggerSkill("zhanwan")
    {
        events << EventPhaseEnd;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Discard && target->tag["LiushiDamage"].toInt() > 0
                && target->getMark("liushi_num-Clear") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            int mark = player->getMark("liushi_num-Clear");
            if (mark <= 0) return false;
            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
            p->drawCards(mark, objectName());
            int n = player->tag["LiushiDamage"].toInt();
            room->addMaxCards(player, n, false);
            player->tag.remove("LiushiDamage");
            room->setPlayerMark(player, "&liushi", 0);
        }
        return false;
    }
};

class ZhanwanMove : public TriggerSkill
{
public:
    ZhanwanMove() : TriggerSkill("#zhanwan-move")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from->isDead() || move.from->getPhase() != Player::Discard) return false;
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            ServerPlayer *from = room->findChild<ServerPlayer *>(move.from->objectName());
            if (!from || from->isDead()) return false;
            room->addPlayerMark(from, "liushi_num-Clear", move.card_ids.length());
        }
        return false;
    }
};

class MobileWangzun : public PhaseChangeSkill
{
public:
    MobileWangzun() : PhaseChangeSkill("mobilewangzun")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::RoundStart;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || player->getHp() <= p->getHp()) continue;
            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
            if (player->isLord()) {
                p->drawCards(2, objectName());
                room->addMaxCards(player, -1);
            } else
                p->drawCards(1, objectName());
        }
        return false;
    }
};

MobileTongjiCard::MobileTongjiCard()
{
    mute = true;
}

bool MobileTongjiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty()) return false;
    if (to_select->hasFlag("MobileTongjiSlashSource") || to_select == Self) return false;

    const Player *from = NULL;
    foreach (const Player *p, Self->getAliveSiblings()) {
        if (p->hasFlag("MobileTongjiSlashSource")) {
            from = p;
            break;
        }
    }
    const Card *slash = Card::Parse(Self->property("mobiletongji").toString());
    if (from && !from->canSlash(to_select, slash, false)) return false;
    int card_id = subcards.first();
    int range_fix = 0;
    if (Self->getWeapon() && Self->getWeapon()->getId() == card_id) {
        const Weapon *weapon = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
        range_fix += weapon->getRange() - Self->getAttackRange(false);
    } else if (Self->getOffensiveHorse() && Self->getOffensiveHorse()->getId() == card_id) {
        range_fix += 1;
    }
    return to_select->hasSkill("mobiletongji") && Self->inMyAttackRange(to_select, range_fix);
}

void MobileTongjiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();

    room->broadcastSkillInvoke("mobiletongji");
    room->notifySkillInvoked(card_use.to.first(), "mobiletongji");

    LogMessage log;
    log.from = card_use.from;
    log.to << card_use.to;
    log.type = "$MobileTongjiUse";
    log.card_str = IntList2StringList(subcards).join("+");
    log.arg = "mobiletongji";
    room->sendLog(log);
    room->doAnimate(1, card_use.from->objectName(), card_use.to.first()->objectName());

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, card_use.from->objectName(), QString(), "mobiletongji", QString());
    room->moveCardTo(this, card_use.from, NULL, Player::DiscardPile, reason, true);

    thread->trigger(CardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void MobileTongjiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->setFlags("MobileTongjiTarget");
}

class MobileTongjiVS : public OneCardViewAsSkill
{
public:
    MobileTongjiVS() : OneCardViewAsSkill("mobiletongji")
    {
        filter_pattern = ".";
        response_pattern = "@@mobiletongji";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileTongjiCard *c = new MobileTongjiCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class MobileTongji : public TriggerSkill
{
public:
    MobileTongji() : TriggerSkill("mobiletongji")
    {
        events << TargetConfirming;
        view_as_skill = new MobileTongjiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        if (!use.to.contains(player) || !player->canDiscard(player, "he")) return false;

        bool yuanshu = false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this) || p == use.from) continue;
            if (!player->inMyAttackRange(p) || !use.from->canSlash(p, use.card, false)) continue;
            yuanshu = true;
            break;
        }
        if (!yuanshu) return false;

        QString prompt = "@mobiletongji:" + use.from->objectName();
        room->setPlayerFlag(use.from, "MobileTongjiSlashSource");
        player->tag["mobiletongji-card"] = QVariant::fromValue(use.card); // for the server (AI)
        room->setPlayerProperty(player, "mobiletongji", use.card->toString()); // for the client (UI)

        if (room->askForUseCard(player, "@@mobiletongji", prompt, -1, Card::MethodDiscard)) {
            player->tag.remove("mobiletongji-card");
            room->setPlayerProperty(player, "mobiletongji", QString());
            room->setPlayerFlag(use.from, "-MobileTongjiSlashSource");
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->hasFlag("MobileTongjiTarget")) {
                    p->setFlags("-MobileTongjiTarget");
                    if (!use.from->canSlash(p, false))
                        return false;
                    use.to.removeOne(player);
                    use.to.append(p);
                    room->sortByActionOrder(use.to);
                    data = QVariant::fromValue(use);
                    room->getThread()->trigger(TargetConfirming, room, p, data);
                    return false;
                }
            }
        } else {
            player->tag.remove("mobiletongji-card");
            room->setPlayerProperty(player, "mobiletongji", QString());
            room->setPlayerFlag(use.from, "-MobileTongjiSlashSource");
        }
        return false;
    }
};

BaiyiCard::BaiyiCard()
{
}

bool BaiyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() < 2;
}

bool BaiyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void BaiyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    source->tag["BaiyiUsed"] = true;
    room->doSuperLightbox("simashi", "baiyi");
    room->removePlayerMark(source, "@baiyiMark");
    if (targets.first()->isDead() || targets.last()->isDead()) return;
    room->swapSeat(targets.first(), targets.last());
}

class Baiyi : public ZeroCardViewAsSkill
{
public:
    Baiyi() : ZeroCardViewAsSkill("baiyi")
    {
        limit_mark = "@baiyiMark";
        frequency = Limited;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@baiyiMark") > 0 && player->isWounded();
    }

    const Card *viewAs() const
    {
        return new BaiyiCard;
    }
};

JinglveCard::JinglveCard()
{
}

bool JinglveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->isKongcheng() && to_select != Self;
}

void JinglveCard::onEffect(const CardEffectStruct &effect) const
{
    QStringList names = effect.from->tag["Jinglve_targets"].toStringList();
    if (!names.contains(effect.to->objectName())) {
        names << effect.to->objectName();
        effect.from->tag["Jinglve_targets"] = names;
    }
    if (effect.to->isDead() || effect.to->isKongcheng() || effect.from->isDead()) return;
    Room *room = effect.from->getRoom();
    int id = room->doGongxin(effect.from, effect.to, effect.to->handCards(), "jinglve");
    if (id < 0) return;

    LogMessage log;
    log.type = "$JinglveMark";
    log.from = effect.from;
    log.to << effect.to;
    log.card_str = QString::number(id);
    room->sendLog(log, effect.from);

    const Card *card = Sanguosha->getEngineCard(id);
    QString mark = "&jinglve+:+" + card->objectName() + "+" + card->getSuitString() + "_char" + "+" + card->getNumberString();
    room->addPlayerMark(effect.to, mark, 1, QList<ServerPlayer *>() << effect.from);

    QVariantList sishi = effect.to->tag["Sishi" + effect.from->objectName()].toList();
    if (!sishi.contains(id)) {
        sishi << id;
        effect.to->tag["Sishi" + effect.from->objectName()] = sishi;
    }
}

class JinglveVS : public ZeroCardViewAsSkill
{
public:
    JinglveVS() : ZeroCardViewAsSkill("jinglve")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JinglveCard");
    }

    const Card *viewAs() const
    {
        return new JinglveCard;
    }
};

class Jinglve : public TriggerSkill
{
public:
    Jinglve() : TriggerSkill("jinglve")
    {
        events << CardUsed << CardsMoveOneTime << EventPhaseChanging << Death << JinkEffect << NullificationEffect;
        view_as_skill = new JinglveVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == JinkEffect || event == NullificationEffect) {
            const Card *c = data.value<const Card *>();
            if (!c || c->isKindOf("SkillCard")) return false;
            QList<int> subcards;
            if (c->isVirtualCard())
                subcards = c->getSubcards();
            else
                subcards << c->getEffectiveId();
            if (subcards.isEmpty()) return false;

            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isAlive() && p->hasSkill(this)) {
                    QVariantList sishi = player->tag["Sishi" + p->objectName()].toList();
                    if (sishi.isEmpty()) continue;
                    QList<int> sishi_ids = VariantList2IntList(sishi);
                    QList<int> sishi_subcards;
                    foreach (int id, subcards) {
                        if (sishi_ids.contains(id)) {
                            sishi_subcards << id;
                            sishi.removeOne(id);
                            player->tag["Sishi" + p->objectName()] = sishi;
                            SishiRemoveMark(id, player);
                        }
                    }
                    if (sishi_subcards.isEmpty()) continue;
                    LogMessage log;
                    log.type = "#JinglveUse";
                    log.from = p;
                    log.to << player;
                    log.arg = objectName();
                    log.arg2 = c->objectName();
                    log.card_str = IntList2StringList(sishi_subcards).join("+");
                    room->sendLog(log);
                    room->notifySkillInvoked(p, objectName());
                    room->broadcastSkillInvoke(objectName());
                    return true;
                }
            }
        } else if (event == CardUsed) {
            if (player->isDead()) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (use.card->isKindOf("Nullification")) return false;
            QList<int> subcards;
            if (use.card->isVirtualCard())
                subcards = use.card->getSubcards();
            else
                subcards << use.card->getEffectiveId();
            if (subcards.isEmpty()) return false;

            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isAlive() && p->hasSkill(this)) {
                    QVariantList sishi = player->tag["Sishi" + p->objectName()].toList();
                    if (sishi.isEmpty()) continue;
                    QList<int> sishi_ids = VariantList2IntList(sishi);
                    QList<int> sishi_subcards;
                    foreach (int id, subcards) {
                        if (sishi_ids.contains(id)) {
                            sishi_subcards << id;
                            sishi.removeOne(id);
                            player->tag["Sishi" + p->objectName()] = sishi;
                            SishiRemoveMark(id, player);
                        }
                    }
                    if (sishi_subcards.isEmpty()) continue;
                    LogMessage log;
                    log.type = "#JinglveUse";
                    log.from = p;
                    log.to << player;
                    log.arg = objectName();
                    log.arg2 = use.card->objectName();
                    log.card_str = IntList2StringList(sishi_subcards).join("+");
                    room->sendLog(log);
                    room->notifySkillInvoked(p, objectName());
                    room->broadcastSkillInvoke(objectName());
                    return true;
                }
            }
        } else if (event == Death) {
            ServerPlayer *who = data.value<DeathStruct>().who;
            if (who != player) return false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                who->tag.remove("Sishi" + p->objectName());
                p->tag.remove("Sishi" + who->objectName());
            }
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->isDead()) return false;
                if (p->isAlive() && p->hasSkill(this)) {
                    QVariantList sishi = player->tag["Sishi" + p->objectName()].toList();
                    if (sishi.isEmpty()) continue;
                    QList<int> sishi_ids = VariantList2IntList(sishi);
                    DummyCard *dummy = new DummyCard;
                    dummy->deleteLater();
                    foreach (const Card *c, player->getCards("hej")) {
                        if (sishi_ids.contains(c->getEffectiveId()))
                            dummy->addSubcard(c);
                    }
                    if (dummy->subcardsLength() <= 0) continue;
                    room->sendCompulsoryTriggerLog(p, objectName(), true);
                    p->obtainCard(dummy, false);
                }
            }
        } else if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player
            && (move.from_places.contains(Player::PlaceEquip) || move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceJudge))) {
                if (move.to && move.to == player
                && (move.to_place == Player::PlaceEquip || move.to_place == Player::PlaceHand || move.to_place == Player::PlaceJudge)) return false;
                if (move.reason.m_reason == CardMoveReason::S_REASON_USE || move.reason.m_reason == CardMoveReason::S_REASON_LETUSE) {
                    if (move.to_place == Player::PlaceTable)
                        return false;
                }
                foreach (int id, move.card_ids) {
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        QVariantList sishi = player->tag["Sishi" + p->objectName()].toList();
                        if (sishi.isEmpty() || !sishi.contains(id)) continue;
                        sishi.removeOne(id);
                        player->tag["Sishi" + p->objectName()] = sishi;
                        SishiRemoveMark(id, player);

                        if (move.to_place == Player::DiscardPile) {
                            if (move.reason.m_reason != CardMoveReason::S_REASON_USE && move.reason.m_reason != CardMoveReason::S_REASON_LETUSE) {
                                if (room->getCardPlace(id) == Player::DiscardPile) {
                                    room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                                    room->obtainCard(p, id, true);
                                }
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    void SishiRemoveMark(int id, ServerPlayer *owner) const
    {
        const Card *card = Sanguosha->getEngineCard(id);
        QString mark = "&jinglve+:+" + card->objectName() + "+" + card->getSuitString() + "_char" + "+" + card->getNumberString();
        owner->getRoom()->removePlayerMark(owner, mark);
    }
};

class Shanli : public PhaseChangeSkill
{
public:
    Shanli() : PhaseChangeSkill("shanli")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (!player->tag["BaiyiUsed"].toBool() || player->tag["Jinglve_targets"].toStringList().length() < 2) return false;
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("simashi", objectName());
        room->addPlayerMark(player, objectName());

        if (room->changeMaxHpForAwakenSkill(player)) {
            if (player->isDead()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@shanli-invoke");
            room->doAnimate(1, player->objectName(), target->objectName());
            QStringList lords = Sanguosha->getLords();
            QStringList all_lord_skills;
            foreach (QString lord, lords) {
                const General *general = Sanguosha->getGeneral(lord);
                QList<const Skill *> skills = general->findChildren<const Skill *>();
                foreach (const Skill *skill, skills) {
                    if (skill->isLordSkill() && skill->isVisible() && !all_lord_skills.contains(skill->objectName()))
                        all_lord_skills << skill->objectName();
                }
            }

            QStringList lord_skills;
            for (int i = 1; i <= 3; i++) {
                if (all_lord_skills.isEmpty()) break;
                QString lordskill = all_lord_skills.at(qrand() % all_lord_skills.length());
                all_lord_skills.removeOne(lordskill);
                lord_skills << lordskill;
            }
            if (lord_skills.isEmpty()) return false;

            QString skill = room->askForChoice(player, objectName(), lord_skills.join("+"), QVariant::fromValue(target));
            if (target->hasLordSkill(skill, true)) return false;
            room->acquireSkill(target, skill);
        }
        return false;
    }
};

HongyiCard::HongyiCard()
{
    handling_method = Card::MethodDiscard;
}

void HongyiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    QStringList names = effect.from->property("hongyi_targets").toStringList();
    if (!names.contains(effect.to->objectName())) {
        names << effect.to->objectName();
        room->setPlayerProperty(effect.from, "hongyi_targets", names);
    }
    room->addPlayerMark(effect.to, "&hongyi");
}

class HongyiVS : public ViewAsSkill
{
public:
    HongyiVS() : ViewAsSkill("hongyi")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int n = 0;
        foreach (const Player *p, Self->getSiblings()) {
            if (p->isDead()) {
                n++;
                if (n >= 2)
                    break;
            }
        }
        if (n == 0) return false;
        return !Self->isJilei(to_select) && selected.length() < n;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int n = 0;
        foreach (const Player *p, Self->getSiblings()) {
            if (p->isDead()) {
                n++;
                if (n >= 2)
                    break;
            }
        }
        if (cards.length() != n) return NULL;

        HongyiCard *c = new HongyiCard;
        if (!cards.isEmpty())
            c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("HongyiCard");
    }
};

class Hongyi : public TriggerSkill
{
public:
    Hongyi() : TriggerSkill("hongyi")
    {
        events << DamageCaused << EventPhaseStart << Death << FinishJudge;
        view_as_skill = new HongyiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseStart)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            QStringList names = player->property("hongyi_targets").toStringList();
            if (names.isEmpty()) return false;
            room->setPlayerProperty(player, "hongyi_targets", QStringList());
            foreach (QString name, names) {
                ServerPlayer *p = room->findChild<ServerPlayer *>(name);
                if (!p) continue;
                room->setPlayerMark(p, "&hongyi", 0);
            }
        } else if (event == DamageCaused) {
            if (player->isDead() || player->getMark("&hongyi") <= 0) return false;
            DamageStruct damage = data.value<DamageStruct>();
            int mark = player->getMark("&hongyi");
            for (int i = 1; i <= mark; i++) {
                if (player->isDead()) break;
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);

                JudgeStruct judge;
                judge.who = player;
                judge.reason = objectName();
                judge.pattern = ".";
                judge.play_animation = false;
                room->judge(judge);

                Card::Color color = (Card::Color)(judge.pattern.toInt());

                if (color == Card::Red)
                    room->drawCards(damage.to, 1, objectName());
                else if (color == Card::Black)
                    damage.damage -= 1;
            }
            if (damage.damage <= 0)
                return true;
            else
                data = QVariant::fromValue(damage);
        } else if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (!death.who->hasSkill(this, true) || player != death.who) return false;
            QStringList names = player->property("hongyi_targets").toStringList();
            if (names.isEmpty()) return false;
            room->setPlayerProperty(player, "hongyi_targets", QStringList());
            foreach (QString name, names) {
                ServerPlayer *p = room->findChild<ServerPlayer *>(name);
                if (!p) continue;
                room->setPlayerMark(p, "&hongyi", 0);
            }
        } else if (event == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason != objectName()) return false;
            judge->pattern = QString::number(int(judge->card->getColor()));
        }
        return false;
    }
};

class Quanfeng : public TriggerSkill
{
public:
    Quanfeng() : TriggerSkill("quanfeng")
    {
        frequency = Compulsory;
        limited_skill = true;
        limit_mark = "@quanfengMark";
        events << Death;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark(getLimitMark()) <= 0) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->doSuperLightbox("yanghuiyu", objectName());
        room->removePlayerMark(player, getLimitMark());

        DeathStruct death = data.value<DeathStruct>();
        QList<const Skill*> skills = death.who->getSkillList();
        QStringList gets;
        foreach (const Skill *skill, skills) {
            if (skill->isLimitedSkill()) continue;
            if (skill->getFrequency() == Skill::Wake) continue;
            if (skill->isLordSkill()) continue;
            if (gets.contains(skill->objectName())) continue;
            gets << skill->objectName();
        }
        if (!gets.isEmpty()) {
            QString skill = room->askForChoice(player, objectName(), gets.join("+"));
            room->acquireSkill(player, skill);
        }
        room->gainMaxHp(player);
        room->recover(player, RecoverStruct(player));
        return false;
    }
};

SecondHongyiCard::SecondHongyiCard()
{
}

void SecondHongyiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    QStringList names = effect.from->property("secondhongyi_targets").toStringList();
    if (!names.contains(effect.to->objectName())) {
        names << effect.to->objectName();
        room->setPlayerProperty(effect.from, "secondhongyi_targets", names);
    }
    room->addPlayerMark(effect.to, "&secondhongyi");
}

class SecondHongyiVS : public ZeroCardViewAsSkill
{
public:
    SecondHongyiVS() : ZeroCardViewAsSkill("secondhongyi")
    {
    }

    const Card *viewAs() const
    {
        return new SecondHongyiCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SecondHongyiCard");
    }
};

class SecondHongyi : public TriggerSkill
{
public:
    SecondHongyi() : TriggerSkill("secondhongyi")
    {
        events << DamageCaused << EventPhaseStart << Death << FinishJudge;
        view_as_skill = new SecondHongyiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseStart)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            QStringList names = player->property("secondhongyi_targets").toStringList();
            if (names.isEmpty()) return false;
            room->setPlayerProperty(player, "secondhongyi_targets", QStringList());
            foreach (QString name, names) {
                ServerPlayer *p = room->findChild<ServerPlayer *>(name);
                if (!p) continue;
                room->setPlayerMark(p, "&secondhongyi", 0);
            }
        } else if (event == DamageCaused) {
            if (player->isDead() || player->getMark("&secondhongyi") <= 0) return false;
            DamageStruct damage = data.value<DamageStruct>();
            int mark = player->getMark("&secondhongyi");
            for (int i = 1; i <= mark; i++) {
                if (player->isDead()) break;
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);

                JudgeStruct judge;
                judge.who = player;
                judge.reason = objectName();
                judge.pattern = ".";
                judge.play_animation = false;
                room->judge(judge);

                Card::Color color = (Card::Color)(judge.pattern.toInt());

                if (color == Card::Red)
                    room->drawCards(damage.to, 1, objectName());
                else if (color == Card::Black)
                    damage.damage -= 1;
            }
            if (damage.damage <= 0)
                return true;
            else
                data = QVariant::fromValue(damage);
        } else if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (!death.who->hasSkill(this, true) || player != death.who) return false;
            QStringList names = player->property("secondhongyi_targets").toStringList();
            if (names.isEmpty()) return false;
            room->setPlayerProperty(player, "secondhongyi_targets", QStringList());
            foreach (QString name, names) {
                ServerPlayer *p = room->findChild<ServerPlayer *>(name);
                if (!p) continue;
                room->setPlayerMark(p, "&secondhongyi", 0);
            }
        } else if (event == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason != objectName()) return false;
            judge->pattern = QString::number(int(judge->card->getColor()));
        }
        return false;
    }
};

class SecondQuanfeng : public TriggerSkill
{
public:
    SecondQuanfeng() : TriggerSkill("secondquanfeng")
    {
        events << Death << AskForPeaches;
        frequency = Limited;
        limit_mark = "@secondquanfengMark";
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("@secondquanfengMark") <= 0) return false;
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player) return false;
            if (!player->hasSkill("secondhongyi")) return false;
            if (!player->askForSkillInvoke(this, death.who)) return false;
            room->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("second_yanghuiyu", "secondquanfeng");
            room->removePlayerMark(player, "@secondquanfengMark");
            room->handleAcquireDetachSkills(player, "-secondhongyi");

            QStringList skills;
            const General *general = Sanguosha->getGeneral(death.who->getGeneralName());
            foreach (const Skill *sk, general->getSkillList()) {
                if (!sk->isVisible() || sk->isLordSkill()) continue;
                if (skills.contains(sk->objectName())) continue;
                skills << sk->objectName();
            }
            if (death.who->getGeneral2()) {
                const General *general2 = Sanguosha->getGeneral(death.who->getGeneral2Name());
                foreach (const Skill *sk, general2->getSkillList()) {
                    if (!sk->isVisible() || sk->isLordSkill()) continue;
                    if (skills.contains(sk->objectName())) continue;
                    skills << sk->objectName();
                }
            }
            if (!skills.isEmpty())
                room->handleAcquireDetachSkills(player, skills);
            room->gainMaxHp(player);
            room->recover(player, RecoverStruct(player));
        } else {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who != player) return false;
            if (!player->hasSkill(this) || !player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("second_yanghuiyu", "secondquanfeng");
            room->removePlayerMark(player, "@secondquanfengMark");
            room->gainMaxHp(player, 2);
            room->recover(player, RecoverStruct(player, NULL, 4));
        }
        return false;
    }
};

SP2Package::SP2Package()
    : Package("sp2")
{
    General *sp_zhangji = new General(this, "sp_zhangji", "qun", 4);
    sp_zhangji->addSkill(new Lveming);
    sp_zhangji->addSkill(new Tunjun);

    General *wangcan = new General(this, "wangcan", "qun", 3);
    wangcan->addSkill(new Sanwen);
    wangcan->addSkill(new Qiai);
    wangcan->addSkill(new Denglou);

    General *shenpei = new General(this, "shenpei", "qun", 3);
    shenpei->addSkill(new Gangzhi);
    shenpei->addSkill(new Beizhan);
    shenpei->addSkill(new BeizhanPro);
    related_skills.insertMulti("beizhan", "#beizhan-prohibit");

    General *mobile_shenpei = new General(this, "mobile_shenpei", "qun", 3, true, false, false, 2);
    mobile_shenpei->addSkill(new MobileShouye);
    mobile_shenpei->addSkill(new MobileLiezhi);

    General *wutugu = new General(this, "wutugu", "qun", 15);
    wutugu->addSkill(new Ranshang);
    wutugu->addSkill(new Hanyong);

    General *tenyear_wutugu = new General(this, "tenyear_wutugu", "qun", 15);
    tenyear_wutugu->addSkill(new TenyearRanshang);
    tenyear_wutugu->addSkill(new TenyearHanyong);

    General *lijue = new General(this, "lijue", "qun", 6, true, false, false, 4);
    lijue->addSkill(new Langxi);
    lijue->addSkill(new Yisuan);

    General *fanchou = new General(this, "fanchou", "qun", 4);
    fanchou->addSkill(new Xingluan("xingluan"));

    General *tenyear_fanchou = new General(this, "tenyear_fanchou", "qun", 4);
    tenyear_fanchou->addSkill(new Xingluan("tenyearxingluan"));

    General *guosi = new General(this, "guosi", "qun", 4);
    guosi->addSkill(new Tanbei);
    guosi->addSkill(new TanbeiTargetMod);
    guosi->addSkill(new TanbeiPro);
    guosi->addSkill(new Sidao);
    guosi->addSkill(new SidaoTargetMod);
    related_skills.insertMulti("tanbei", "#tanbei-target");
    related_skills.insertMulti("tanbei", "#tanbei-pro");
    related_skills.insertMulti("sidao", "#sidao-target");

    General *simahui = new General(this, "simahui", "qun", 3);
    simahui->addSkill(new Jianjie);
    simahui->addSkill(new Chenghao);
    simahui->addSkill(new Yinshi);
    simahui->addRelateSkill("jianjiehuoji");
    simahui->addRelateSkill("jianjielianhuan");
    simahui->addRelateSkill("jianjieyeyan");

    General *sp_lingju = new General(this, "sp_lingju", "qun", 3, false);
    sp_lingju->addSkill("jieyuan");
    sp_lingju->addSkill(new SpFenxin);

    General *gaolan = new General(this, "gaolan", "qun", 4);
    gaolan->addSkill(new Xiying("xiying"));

    General *second_gaolan = new General(this, "second_gaolan", "qun", 4);
    second_gaolan->addSkill(new Xiying("secondxiying"));

    General *tadun = new General(this, "tadun", "qun", 4);
    tadun->addSkill(new Luanzhan);
    tadun->addSkill(new LuanzhanTargetMod);
    tadun->addSkill(new LuanzhanMark);
    related_skills.insertMulti("luanzhan", "#luanzhan-target");
    related_skills.insertMulti("luanzhan", "#luanzhan-mark");

    General *ol_tadun = new General(this, "ol_tadun", "qun", 4);
    ol_tadun->addSkill(new OLLuanzhan);
    ol_tadun->addSkill(new OLLuanzhanTargetMod);
    related_skills.insertMulti("olluanzhan", "#olluanzhan-target");

    General *yuantanyuanshang = new General(this, "yuantanyuanshang", "qun", 4);
    yuantanyuanshang->addSkill(new Neifa);

    General *xunchen = new General(this, "xunchen", "qun", 3);
    xunchen->addSkill(new Fenglve);
    xunchen->addSkill(new Moushi);

    General *tenyear_xunchen = new General(this, "tenyear_xunchen", "qun", 3);
    tenyear_xunchen->addSkill(new TenyearFenglve);
    tenyear_xunchen->addSkill(new Anyong);
    tenyear_xunchen->addSkill(new AnyongRecord);
    related_skills.insertMulti("anyong", "#anyong");

    General *sp_taishici = new General(this, "sp_taishici", "qun", 4);
    sp_taishici->addSkill(new Jixu);

    General *liuyao = new General(this, "liuyao", "qun", 4);
    liuyao->addSkill(new Kannan);

    General *zhangliang = new General(this, "zhangliang", "qun", 4);
    zhangliang->addSkill(new Jijun);
    zhangliang->addSkill(new Fangtong);

    General *huangfusong = new General(this, "huangfusong", "qun", 4);
    huangfusong->addSkill(new Fenyue);
    huangfusong->addSkill(new FenyueRevived);
    related_skills.insertMulti("fenyue", "#fenyue-revived");

    General *mangyachang = new General(this, "mangyachang", "qun", 4);
    mangyachang->addSkill(new Jiedao);

    General *xingdaorong = new General(this, "xingdaorong", "qun", 6, true, false, false, 4);
    xingdaorong->addSkill(new Xuhe);

    General *lisu = new General(this, "lisu", "qun", 2);
    lisu->addSkill(new Lixun);
    lisu->addSkill(new LixunJudge);
    lisu->addSkill(new SpKuizhu);
    related_skills.insertMulti("lixun", "#lixun-judge");

    General *taoqian = new General(this, "taoqian", "qun", 3);
    taoqian->addSkill(new Zhaohuo);
    taoqian->addSkill(new Yixiang);
    taoqian->addSkill(new Yirang);

    General *pangdegong = new General(this, "pangdegong", "qun", 3);
    pangdegong->addSkill(new Pingcai);
    pangdegong->addSkill(new Yinshiy);
    pangdegong->addSkill(new YinshiyPro);
    related_skills.insertMulti("yinshiy", "#yinshiy-pro");

    General *nanshengmi = new General(this, "nanshengmi", "qun", 3);
    nanshengmi->addSkill(new Chijiec);
    nanshengmi->addSkill(new Waishi);
    nanshengmi->addSkill(new Renshe);
    nanshengmi->addSkill(new RensheMark);
    related_skills.insertMulti("renshe", "#renshe-mark");

    General *furong = new General(this, "furong", "shu", 4);
    furong->addSkill(new Xuewei);
    furong->addSkill(new Liechi);

    General *sp_zhangyi = new General(this, "sp_zhangyi", "shu", 4);
    sp_zhangyi->addSkill(new Zhiyi);

    General *second_sp_zhangyi = new General(this, "second_sp_zhangyi", "shu", 4);
    second_sp_zhangyi->addSkill(new SecondZhiyi);
    second_sp_zhangyi->addSkill(new SecondZhiyiRecord);
    related_skills.insertMulti("secondzhiyi", "#secondzhiyi-record");

    General *dengzhi = new General(this, "dengzhi", "shu", 3);
    dengzhi->addSkill(new Jimeng);
    dengzhi->addSkill(new Shuaiyan);

    General *caoshuang = new General(this, "caoshuang", "wei", 4);
    caoshuang->addSkill(new Tuogu);
    caoshuang->addSkill(new Shanzhuan);

    General *second_caoshuang = new General(this, "second_caoshuang", "wei", 4);
    second_caoshuang->addSkill(new SecondTuogu);
    second_caoshuang->addSkill("shanzhuan");

    General *mobile_sufei = new General(this, "mobile_sufei", "qun", 4);
    mobile_sufei->addSkill(new Zhengjian);
    mobile_sufei->addSkill(new Gaoyuan);

    General *yangbiao = new General(this, "yangbiao", "qun", 3);
    yangbiao->addSkill(new Zhaohan);
    yangbiao->addSkill(new ZhaohanNum);
    yangbiao->addSkill(new Rangjie);
    yangbiao->addSkill(new Yizheng);
    related_skills.insertMulti("zhaohan", "#zhaohan-num");

    General *xingzhanghe = new General(this, "xingzhanghe", "qun", 4);
    xingzhanghe->addSkill(new XingZhilve);
    xingzhanghe->addSkill(new SlashNoDistanceLimitSkill("xingzhilve"));
    related_skills.insertMulti("xingzhilve", "#xingzhilve-slash-ndl");

    General *xingzhangliao = new General(this, "xingzhangliao", "qun", 4);
    xingzhangliao->addSkill(new XingWeifeng);

    General *xingxuhuang = new General(this, "xingxuhuang", "qun", 4);
    xingxuhuang->addSkill(new XingZhiyan);
    xingxuhuang->addSkill(new XingZhiyanPro);
    related_skills.insertMulti("xingzhiyan", "#xingzhiyan-pro");

    General *xingganning = new General(this, "xingganning", "qun", 4);
    xingganning->addSkill(new XingJinfan);
    xingganning->addSkill(new XingJinfanLose("xingjinfan"));
    xingganning->addSkill(new XingSheque);
    xingganning->addSkill(new XingShequeLog);
    related_skills.insertMulti("xingjinfan", "#xingjinfan-lose");
    related_skills.insertMulti("xingjinfan", "#xingsheque-log");

    General *second_xingganning = new General(this, "second_xingganning", "qun", 4);
    second_xingganning->addSkill(new SecondXingJinfan);
    second_xingganning->addSkill(new XingJinfanLose("secondxingjinfan"));
    second_xingganning->addSkill("xingsheque");
    related_skills.insertMulti("secondxingjinfan", "#secondxingjinfan-lose");

    General *liuyan = new General(this, "liuyan", "qun", 3);
    liuyan->addSkill(new Tushe);
    liuyan->addSkill(new Limu);
    liuyan->addSkill(new LimuTargetMod);
    related_skills.insertMulti("limu", "#limu-target");

    General *tenyear_liuzan = new General(this, "tenyear_liuzan", "wu", 4);
    tenyear_liuzan->addSkill(new TenyearFenyin);
    tenyear_liuzan->addSkill(new Liji);

    General *new_sppangde = new General(this, "new_sppangde", "wei", 4);
    new_sppangde->addSkill(new Juesi);
    new_sppangde->addSkill("mashu");

    General *new_spmachao = new General(this, "new_spmachao", "qun", 4);
    new_spmachao->addSkill(new Skill("newzhuiji", Skill::Compulsory));
    new_spmachao->addSkill(new NewShichou);

    General *tenyear_new_spmachao = new General(this, "tenyear_new_spmachao", "qun", 4);
    tenyear_new_spmachao->addSkill("newzhuiji");
    tenyear_new_spmachao->addSkill(new TenyearNewShichou);
    tenyear_new_spmachao->addSkill(new TenyearNewShichouDamage);
    related_skills.insertMulti("tenyearnewshichou", "#tenyearnewshichou");

    General *new_sp_jiaxu = new General(this, "new_sp_jiaxu", "wei", 3);
    new_sp_jiaxu->addSkill(new Zhenlve);
    new_sp_jiaxu->addSkill(new ZhenlvePro);
    new_sp_jiaxu->addSkill(new Jianshu);
    new_sp_jiaxu->addSkill(new Yongdi);
    related_skills.insertMulti("zhenlve", "#zhenlve-pro");

    General *second_new_sp_jiaxu = new General(this, "second_new_sp_jiaxu", "wei", 3);
    second_new_sp_jiaxu->addSkill("zhenlve");
    second_new_sp_jiaxu->addSkill("jianshu");
    second_new_sp_jiaxu->addSkill(new NewYongdi);

    General *new_guanyinping = new General(this, "new_guanyinping", "shu", 3, false);
    new_guanyinping->addSkill(new Newxuehen);
    new_guanyinping->addSkill(new NewHuxiao);
    new_guanyinping->addSkill(new NewHuxiaoTargetMod);
    new_guanyinping->addSkill(new NewWuji);
    related_skills.insertMulti("newhuxiao", "#newhuxiao-target");

    General *new_maliang = new General(this, "new_maliang", "shu", 3);
    new_maliang->addSkill(new Zishu);
    new_maliang->addSkill(new ZishuGet);
    new_maliang->addSkill(new Yingyuan);
    related_skills.insertMulti("newhuxiao", "#zishu-get");

    General *new_mobile_maliang = new General(this, "new_mobile_maliang", "shu", 3);
    new_mobile_maliang->addSkill("zishu");
    new_mobile_maliang->addSkill(new MobileYingyuan);

    General *new_sphetaihou = new General(this, "new_sphetaihou", "qun", 3, false);
    new_sphetaihou->addSkill(new NewZhendu);
    new_sphetaihou->addSkill(new NewQiluan);

    General *sp_caoren = new General(this, "sp_caoren", "wei", 4);
    sp_caoren->addSkill(new Lizhan);
    sp_caoren->addSkill(new Weikui);

    General *mobile_sunru = new General(this, "mobile_sunru", "wu", 3, false);
    mobile_sunru->addSkill(new Yingjian);
    mobile_sunru->addSkill(new SlashNoDistanceLimitSkill("yingjian"));
    mobile_sunru->addSkill("shixin");
    related_skills.insertMulti("yingjian", "#yingjian-slash-ndl");

    General *sp_zhangliao = new General(this, "sp_zhangliao", "qun", 4);
    sp_zhangliao->addSkill(new Mubing);
    sp_zhangliao->addSkill(new Ziqu);
    sp_zhangliao->addSkill(new Diaoling);
    sp_zhangliao->addSkill(new DiaolingRecord);
    related_skills.insertMulti("diaoling", "#diaoling-record");

    General *sp_hejin = new General(this, "sp_hejin", "qun", 4);
    sp_hejin->addSkill(new SpMouzhu);
    sp_hejin->addSkill(new SpYanhuo);

    General *dingyuan = new General(this, "dingyuan", "qun", 4);
    dingyuan->addSkill(new Beizhu);

    General *dongcheng = new General(this, "dongcheng", "qun", 4);
    dongcheng->addSkill(new Chengzhao);
    dongcheng->addSkill(new ChengzhaoRecord);
    related_skills.insertMulti("chengzhao", "#chengzhao-record");

    General *tenyear_dongcheng = new General(this, "tenyear_dongcheng", "qun", 4);
    tenyear_dongcheng->addSkill(new Xuezhao("xuezhao"));

    General *second_tenyear_dongcheng = new General(this, "second_tenyear_dongcheng", "qun", 4);
    second_tenyear_dongcheng->addSkill(new Xuezhao("secondxuezhao"));

    General *new_zhangbao = new General(this, "new_zhangbao", "qun", 3);
    new_zhangbao->addSkill(new NewZhoufu("newzhoufu"));
    new_zhangbao->addSkill(new NewZhoufuRecord);
    new_zhangbao->addSkill(new NewYingbing);
    related_skills.insertMulti("newzhoufu", "#newzhoufu-record");

    General *tenyear_zhangbao = new General(this, "tenyear_zhangbao", "qun", 3);
    tenyear_zhangbao->setImage("zhangbao");
    tenyear_zhangbao->addSkill(new NewZhoufu("tenyearzhoufu"));
    tenyear_zhangbao->addSkill(new TenyearYingbing);

    General *caoxing = new General(this, "caoxing", "qun", 4);
    caoxing->addSkill(new Liushi);
    caoxing->addSkill(new SlashNoDistanceLimitSkill("liushi"));
    caoxing->addSkill(new Zhanwan);
    caoxing->addSkill(new ZhanwanMove);
    related_skills.insertMulti("liushi", "#liushi-slash-ndl");
    related_skills.insertMulti("zhanwan", "#zhanwan-move");

    General *mobile_yuanshu = new General(this, "mobile_yuanshu", "qun", 4);
    mobile_yuanshu->addSkill(new MobileWangzun);
    mobile_yuanshu->addSkill(new MobileTongji);

    General *simashi = new General(this, "simashi", "wei", 4);
    simashi->addSkill(new Baiyi);
    simashi->addSkill(new Jinglve);
    simashi->addSkill(new Shanli);

    General *yanghuiyu = new General(this, "yanghuiyu", "wei", 3, false);
    yanghuiyu->addSkill(new Hongyi);
    yanghuiyu->addSkill(new Quanfeng);

    General *second_yanghuiyu = new General(this, "second_yanghuiyu", "wei", 3, false);
    second_yanghuiyu->addSkill(new SecondHongyi);
    second_yanghuiyu->addSkill(new SecondQuanfeng);

    addMetaObject<LvemingCard>();
    addMetaObject<TunjunCard>();
    addMetaObject<DenglouCard>();
    addMetaObject<MobileLiezhiCard>();
    addMetaObject<TanbeiCard>();
    addMetaObject<SidaoCard>();
    addMetaObject<JianjieCard>();
    addMetaObject<JianjieHuojiCard>();
    addMetaObject<JianjieLianhuanCard>();
    addMetaObject<JianjieYeyanCard>();
    addMetaObject<SmallJianjieYeyanCard>();
    addMetaObject<GreatJianjieYeyanCard>();
    addMetaObject<LuanzhanCard>();
    addMetaObject<OLLuanzhanCard>();
    addMetaObject<NeifaCard>();
    addMetaObject<FenglveCard>();
    addMetaObject<MoushiCard>();
    addMetaObject<TenyearFenglveCard>();
    addMetaObject<TenyearFenglveGiveCard>();
    addMetaObject<JixuCard>();
    addMetaObject<KannanCard>();
    addMetaObject<FangtongCard>();
    addMetaObject<FenyueCard>();
    addMetaObject<SpKuizhuCard>();
    addMetaObject<ZhiyiCard>();
    addMetaObject<SecondZhiyiCard>();
    addMetaObject<PingcaiCard>();
    addMetaObject<PingcaiWolongCard>();
    addMetaObject<PingcaiFengchuCard>();
    addMetaObject<WaishiCard>();
    addMetaObject<GaoyuanCard>();
    addMetaObject<YizhengCard>();
    addMetaObject<XingZhilveCard>();
    addMetaObject<XingZhilveSlashCard>();
    addMetaObject<XingZhiyanCard>();
    addMetaObject<XingZhiyanDrawCard>();
    addMetaObject<XingJinfanCard>();
    addMetaObject<LimuCard>();
    addMetaObject<LijiCard>();
    addMetaObject<JuesiCard>();
    addMetaObject<TenyearNewShichouCard>();
    addMetaObject<JianshuCard>();
    addMetaObject<NewxuehenCard>();
    addMetaObject<LizhanCard>();
    addMetaObject<WeikuiCard>();
    addMetaObject<MubingCard>();
    addMetaObject<ZiquCard>();
    addMetaObject<SpMouzhuCard>();
    addMetaObject<BeizhuCard>();
    addMetaObject<XuezhaoCard>();
    addMetaObject<SecondXuezhaoCard>();
    addMetaObject<NewZhoufuCard>();
    addMetaObject<TenyearZhoufuCard>();
    addMetaObject<LiushiCard>();
    addMetaObject<MobileTongjiCard>();
    addMetaObject<BaiyiCard>();
    addMetaObject<JinglveCard>();
    addMetaObject<HongyiCard>();
    addMetaObject<SecondHongyiCard>();

    skills << new JianjieHuoji << new JianjieLianhuan << new JianjieYeyan;
}

ADD_PACKAGE(SP2)
