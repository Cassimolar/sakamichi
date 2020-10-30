#include "yjcm2014.h"
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
#include "yjcm2013.h"

DingpinCard::DingpinCard()
{
}

bool DingpinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->isWounded() && !to_select->hasFlag("dingpin");
}

void DingpinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();

    JudgeStruct judge;
    judge.who = effect.to;
    judge.good = true;
    judge.pattern = ".|black";
    judge.reason = "dingpin";

    room->judge(judge);

    if (judge.isGood()) {
        room->setPlayerFlag(effect.to, "dingpin");
        effect.to->drawCards(effect.to->getLostHp(), "dingpin");
    } else {
        effect.from->turnOver();
    }
}

class DingpinViewAsSkill : public OneCardViewAsSkill
{
public:
    DingpinViewAsSkill() : OneCardViewAsSkill("dingpin")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        //if (!player->canDiscard(player, "h") || player->getMark("dingpin") == 0xE) return false;
        if (!player->canDiscard(player, "h")) return false;
        if (!player->hasFlag("dingpin") && player->isWounded()) return true;
        foreach (const Player *p, player->getAliveSiblings()) {
            if (!p->hasFlag("dingpin") && p->isWounded()) return true;
        }
        return false;
    }

    bool viewFilter(const Card *to_select) const
    {
        //return !to_select->isEquipped() && (Self->getMark("dingpin") & (1 << int(to_select->getTypeId()))) == 0;
        return !to_select->isEquipped() && Self->getMark("dingpin_" + to_select->getType() + "-Clear") == 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        DingpinCard *card = new DingpinCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Dingpin : public TriggerSkill
{
public:
    Dingpin() : TriggerSkill("dingpin")
    {
        events << EventPhaseChanging << PreCardUsed << CardResponded << BeforeCardsMove;
        view_as_skill = new DingpinViewAsSkill;
        global = true;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->hasFlag("dingpin"))
                        room->setPlayerFlag(p, "-dingpin");
                }
                /*if (player->getMark("dingpin") > 0)
                    room->setPlayerMark(player, "dingpin", 0);*/
            }
        } else {
            if (!player->isAlive() || player->getPhase() == Player::NotActive) return false;
            if (triggerEvent == PreCardUsed || triggerEvent == CardResponded) {
                const Card *card = NULL;
                if (triggerEvent == PreCardUsed) {
                    card = data.value<CardUseStruct>().card;
                } else {
                    CardResponseStruct resp = data.value<CardResponseStruct>();
                    if (resp.m_isUse)
                        card = resp.m_card;
                }
                if (!card || card->getTypeId() == Card::TypeSkill) return false;
                recordDingpinCardType(room, player, card, true);
            } else if (triggerEvent == BeforeCardsMove) {
                CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
                if (player != move.from
                    || ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) != CardMoveReason::S_REASON_DISCARD))
                    return false;
                foreach (int id, move.card_ids) {
                    const Card *c = Sanguosha->getCard(id);
                    recordDingpinCardType(room, player, c, false);
                }
            }
        }
        return false;
    }

private:
    void recordDingpinCardType(Room *room, ServerPlayer *player, const Card *card, bool isUse) const
    {
        /*if (player->getMark("dingpin") == 0xE) return;
        int typeID = (1 << int(card->getTypeId()));
        int mark = player->getMark("dingpin");
        if ((mark & typeID) == 0)
            room->setPlayerMark(player, "dingpin", mark | typeID);*/
        room->addPlayerMark(player, "dingpin_" + card->getType() + "-Clear");
        if (isUse && player->getPhase() == Player::Play && card->getTypeId() != Card::TypeSkill)
            room->addPlayerMark(player, "langmie_" + QString::number(card->getTypeId()) + "-PlayClear");
        if (isUse && player->getPhase() != Player::NotActive && card->getTypeId() != Card::TypeSkill)
            room->addPlayerMark(player, "secondlangmie_" + QString::number(card->getTypeId()) + "-Clear");
    }
};

class Faen : public TriggerSkill
{
public:
    Faen() : TriggerSkill("faen")
    {
        events << TurnedOver << ChainStateChanged;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == ChainStateChanged && !player->isChained()) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (!player->isAlive()) return false;
            if (TriggerSkill::triggerable(p)
                && room->askForSkillInvoke(p, objectName(), QVariant::fromValue(player))) {
                room->broadcastSkillInvoke(objectName());
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

SidiCard::SidiCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void SidiCard::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "sidi", QString());
    room->throwCard(this, reason, NULL);
}

class SidiVS : public OneCardViewAsSkill
{
public:
    SidiVS() : OneCardViewAsSkill("sidi")
    {
        response_pattern = "@@sidi";
        filter_pattern = ".|.|.|sidi";
        expand_pile = "sidi";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        SidiCard *sd = new SidiCard;
        sd->addSubcard(originalCard);
        return sd;
    }
};

class Sidi : public TriggerSkill
{
public:
    Sidi() : TriggerSkill("sidi")
    {
        events << CardResponded << EventPhaseStart << EventPhaseChanging;
        //frequency = Frequent;
        view_as_skill = new SidiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from == Player::Play)
                room->setPlayerMark(player, "sidi", 0);
        } else if (triggerEvent == CardResponded) {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_isUse && resp.m_card->isKindOf("Jink")) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (TriggerSkill::triggerable(p) && (p == player || p->getPhase() != Player::NotActive)
                        && room->askForSkillInvoke(p, objectName(), data)) {
                        room->broadcastSkillInvoke(objectName(), 1);
                        QList<int> ids = room->getNCards(1, false); // For UI
                        CardsMoveStruct move(ids, NULL, Player::PlaceTable,
                            CardMoveReason(CardMoveReason::S_REASON_TURNOVER, p->objectName(), "sidi", QString()));
                        room->moveCardsAtomic(move, true);
                        p->addToPile("sidi", ids);
                    }
                }
            }
        } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Play) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->getPhase() != Player::Play) return false;
                if (TriggerSkill::triggerable(p) && p->getPile("sidi").length() > 0 && room->askForUseCard(p, "@@sidi", "sidi_remove:remove", -1, Card::MethodNone))
                    room->addPlayerMark(player, "sidi");
            }
        }
        return false;
    }

    int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return 2;
    }
};

class SidiTargetMod : public TargetModSkill
{
public:
    SidiTargetMod() : TargetModSkill("#sidi-target")
    {
    }

    int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        return card->isKindOf("Slash") ? -from->getMark("sidi") : 0;
    }
};

class ShenduanViewAsSkill : public OneCardViewAsSkill
{
public:
    ShenduanViewAsSkill() : OneCardViewAsSkill("shenduan")
    {
        response_pattern = "@@shenduan";
    }

    bool viewFilter(const Card *to_select) const
    {
        QStringList shenduan = Self->property("shenduan").toString().split("+");
        foreach (QString id, shenduan) {
            bool ok;
            if (id.toInt(&ok) == to_select->getEffectiveId() && ok)
                return true;
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        SupplyShortage *ss = new SupplyShortage(originalCard->getSuit(), originalCard->getNumber());
        ss->addSubcard(originalCard);
        ss->setSkillName("_shenduan");
        return ss;
    }
};

class Shenduan : public TriggerSkill
{
public:
    Shenduan() : TriggerSkill("shenduan")
    {
        events << BeforeCardsMove;
        view_as_skill = new ShenduanViewAsSkill;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player)
            return false;
        if (move.to_place == Player::DiscardPile
            && ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)) {

            int i = 0;
            QList<int> shenduan_card;
            foreach (int card_id, move.card_ids) {
                const Card *c = Sanguosha->getCard(card_id);
                if (room->getCardOwner(card_id) == move.from
                    && (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip)
                    && c->isBlack() && c->getTypeId() == Card::TypeBasic) {
                    shenduan_card << card_id;
                }
                i++;
            }
            if (shenduan_card.isEmpty())
                return false;

            room->setPlayerProperty(player, "shenduan", IntList2StringList(shenduan_card).join("+"));
            do {
                if (!room->askForUseCard(player, "@@shenduan", "@shenduan-use")) break;
                QList<int> ids = StringList2IntList(player->property("shenduan").toString().split("+"));
                QList<int> to_remove;
                foreach (int card_id, shenduan_card) {
                    if (!ids.contains(card_id))
                        to_remove << card_id;
                }
                move.removeCardIds(to_remove);
                data = QVariant::fromValue(move);
                shenduan_card = ids;
            } while (!shenduan_card.isEmpty());
        }
        return false;
    }
};

class ShenduanUse : public TriggerSkill
{
public:
    ShenduanUse() : TriggerSkill("#shenduan")
    {
        events << PreCardUsed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SupplyShortage") && use.card->getSkillName() == "shenduan") {
            QList<int> ids = StringList2IntList(player->property("shenduan").toString().split("+"));
            ids.removeOne(use.card->getEffectiveId());
            room->setPlayerProperty(player, "shenduan", IntList2StringList(ids).join("+"));
        }
        return false;
    }
};

class ShenduanTargetMod : public TargetModSkill
{
public:
    ShenduanTargetMod() : TargetModSkill("#shenduan-target")
    {
        pattern = "SupplyShortage";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->getSkillName() == "shenduan")
            return 1000;
        else
            return 0;
    }
};

class Yonglve : public PhaseChangeSkill
{
public:
    Yonglve() : PhaseChangeSkill("yonglve")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() != Player::Judge) return false;
        Room *room = target->getRoom();
        foreach (ServerPlayer *hs, room->getOtherPlayers(target)) {
            if (target->isDead() || target->getJudgingArea().isEmpty()) break;
            if (!TriggerSkill::triggerable(hs) || !hs->inMyAttackRange(target)) continue;
            if (room->askForSkillInvoke(hs, objectName())) {
                room->broadcastSkillInvoke(objectName());
                int id = room->askForCardChosen(hs, target, "j", objectName(), false, Card::MethodDiscard);
                room->throwCard(id, NULL, hs);
                if (hs->isAlive() && target->isAlive() && hs->canSlash(target, false)) {
                    room->setTag("YonglveUser", QVariant::fromValue(hs));
                    Slash *slash = new Slash(Card::NoSuit, 0);
                    slash->setSkillName("_yonglve");
                    room->useCard(CardUseStruct(slash, hs, target));
                }
            }
        }
        return false;
    }
};

class YonglveSlash : public TriggerSkill
{
public:
    YonglveSlash() : TriggerSkill("#yonglve")
    {
        events << PreDamageDone << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == PreDamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->isKindOf("Slash") && damage.card->getSkillName() == "yonglve")
                damage.card->setFlags("YonglveDamage");
        } else if (!player->hasFlag("Global_ProcessBroken")) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash") && use.card->getSkillName() == "yonglve" && !use.card->hasFlag("YonglveDamage")) {
                ServerPlayer *hs = room->getTag("YonglveUser").value<ServerPlayer *>();
                if (hs)
                    hs->drawCards(1, "yonglve");
            }
        }
        return false;
    }
};

class Benxi : public TriggerSkill
{
public:
    Benxi() : TriggerSkill("benxi")
    {
        events << EventPhaseChanging << CardFinished << EventAcquireSkill << EventLoseSkill;
        frequency = Compulsory;
        // global = true; // forgotten? @para
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                room->setPlayerMark(player, "&benxi", 0);
                room->setPlayerMark(player, "benxi", 0);
            }
        } else if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() != Card::TypeSkill
                && player->isAlive() && player->getPhase() != Player::NotActive) {
                room->addPlayerMark(player, "benxi");
                if (TriggerSkill::triggerable(player))
                    room->setPlayerMark(player, "&benxi", player->getMark("benxi"));
            }
        } else if (triggerEvent == EventAcquireSkill || triggerEvent == EventLoseSkill) {
            QString name = data.toString();
            if (name != objectName()) return false;
            int num = (triggerEvent == EventAcquireSkill) ? player->getMark("benxi") : 0;
            room->setPlayerMark(player, "&benxi", num);
        }
        return false;
    }
};

// the part of Armor ignorance is coupled in Player::hasArmorEffect

class BenxiTargetMod : public TargetModSkill
{
public:
    BenxiTargetMod() : TargetModSkill("#benxi-target")
    {
    }

    int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (from->hasSkill("benxi") && isAllAdjacent(from, card))
            return 1;
        else
            return 0;
    }

private:
    bool isAllAdjacent(const Player *from, const Card *card) const
    {
        int rangefix = 0;
        if (card->isVirtualCard() && from->getOffensiveHorse()
            && card->getSubcards().contains(from->getOffensiveHorse()->getEffectiveId()))
            rangefix = 1;
        foreach (const Player *p, from->getAliveSiblings()) {
            if (from->distanceTo(p, rangefix) != 1)
                return false;
        }
        return true;
    }
};

class BenxiDistance : public DistanceSkill
{
public:
    BenxiDistance() : DistanceSkill("#benxi-dist")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill("benxi") && from->getPhase() != Player::NotActive)
            return -from->getMark("benxi");
        return 0;
    }
};

class Qiangzhi : public TriggerSkill
{
public:
    Qiangzhi() : TriggerSkill("qiangzhi")
    {
        events << EventPhaseStart << CardUsed << CardResponded;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Play;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            player->setMark(objectName(), 0);
            if (TriggerSkill::triggerable(player)) {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (!p->isKongcheng())
                        targets << p;
                }
                if (targets.isEmpty()) return false;
                ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "qiangzhi-invoke", true, true);
                if (target) {
                    room->broadcastSkillInvoke(objectName(), 1);
                    int id = room->askForCardChosen(player, target, "h", objectName());
                    room->showCard(target, id);
                    player->setMark(objectName(), static_cast<int>(Sanguosha->getCard(id)->getTypeId()));
                }
            }
        } else if (player->getMark(objectName()) > 0) {
            const Card *card = NULL;
            if (triggerEvent == CardUsed) {
                card = data.value<CardUseStruct>().card;
            } else {
                CardResponseStruct resp = data.value<CardResponseStruct>();
                if (resp.m_isUse)
                    card = resp.m_card;
            }
            if (card && static_cast<int>(card->getTypeId()) == player->getMark(objectName())
                && room->askForSkillInvoke(player, objectName(), data)) {
                if (!player->hasSkill(this)) {
                    LogMessage log;
                    log.type = "#InvokeSkill";
                    log.from = player;
                    log.arg = objectName();
                    room->sendLog(log);
                }
                room->broadcastSkillInvoke(objectName(), 2);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class Xiantu : public TriggerSkill
{
public:
    Xiantu() : TriggerSkill("xiantu")
    {
        events << EventPhaseStart << EventPhaseEnd << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Play) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                p->setFlags("-XiantuInvoked");
                if (!player->isAlive()) return false;
                if (TriggerSkill::triggerable(p) && room->askForSkillInvoke(p, objectName())) {
                    room->broadcastSkillInvoke(objectName());
                    p->setFlags("XiantuInvoked");
                    p->drawCards(2, objectName());
                    if (p->isAlive() && player->isAlive()) {
                        if (!p->isNude()) {
                            int num = qMin(2, p->getCardCount(true));
                            const Card *to_give = room->askForExchange(p, objectName(), num, num, true,
                                QString("@xiantu-give::%1:%2").arg(player->objectName()).arg(num));
                            player->obtainCard(to_give, false);
                            delete to_give;
                        }
                    }
                }
            }
        } else if (triggerEvent == EventPhaseEnd) {
            if (player->getPhase() == Player::Play) {
                QList<ServerPlayer *> zhangsongs;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("XiantuInvoked")) {
                        p->setFlags("-XiantuInvoked");
                        zhangsongs << p;
                    }
                }
                if (player->getMark("XiantuKill") > 0) {
                    player->setMark("XiantuKill", 0);
                    return false;
                }
                foreach (ServerPlayer *zs, zhangsongs) {
                    LogMessage log;
                    log.type = "#Xiantu";
                    log.from = player;
                    log.to << zs;
                    log.arg = objectName();
                    room->sendLog(log);

                    room->loseHp(zs);
                }
            }
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.damage && death.damage->from && death.damage->from->getPhase() == Player::Play)
                death.damage->from->addMark("XiantuKill");
        }
        return false;
    }
};

class Zhongyong : public TriggerSkill
{
public:
    Zhongyong() : TriggerSkill("zhongyong")
    {
        events << SlashMissed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();

        const Card *jink = effect.jink;
        if (!jink) return false;
        QList<int> ids;
        if (!jink->isVirtualCard()) {
            if (room->getCardPlace(jink->getEffectiveId()) == Player::DiscardPile)
                ids << jink->getEffectiveId();
        } else {
            foreach (int id, jink->getSubcards()) {
                if (room->getCardPlace(id) == Player::DiscardPile)
                    ids << id;
            }
        }
        if (ids.isEmpty()) return false;

        room->fillAG(ids, player);
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(effect.to), objectName(),
            "zhongyong-invoke:" + effect.to->objectName(), true, true);
        room->clearAG(player);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        DummyCard *dummy = new DummyCard(ids);
        room->obtainCard(target, dummy);
        delete dummy;

        if (player->isAlive() && effect.to->isAlive() && target != player) {
            if (!player->canSlash(effect.to, NULL, false))
                return false;
            if (room->askForUseSlashTo(player, effect.to, QString("zhongyong-slash:%1").arg(effect.to->objectName()), false, true))
                return true;
        }
        return false;
    }
};

ShenxingCard::ShenxingCard()
{
    target_fixed = true;
}

void ShenxingCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isAlive())
        room->drawCards(source, 1, "shenxing");
}

class Shenxing : public ViewAsSkill
{
public:
    Shenxing() : ViewAsSkill("shenxing")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() < 2 && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2)
            return NULL;

        ShenxingCard *card = new ShenxingCard;
        card->addSubcards(cards);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getCardCount(true) >= 2 && player->canDiscard(player, "he");
    }
};

BingyiCard::BingyiCard()
{
}

bool BingyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
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

bool BingyiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
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

void BingyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->showAllCards(source);
    foreach(ServerPlayer *p, targets)
        room->drawCards(p, 1, "bingyi");
}

class BingyiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    BingyiViewAsSkill() : ZeroCardViewAsSkill("bingyi")
    {
        response_pattern = "@@bingyi";
    }

    const Card *viewAs() const
    {
        return new BingyiCard;
    }
};

class Bingyi : public PhaseChangeSkill
{
public:
    Bingyi() : PhaseChangeSkill("bingyi")
    {
        view_as_skill = new BingyiViewAsSkill;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() != Player::Finish || target->isKongcheng()) return false;
        target->getRoom()->askForUseCard(target, "@@bingyi", "@bingyi-card");
        return false;
    }
};

class Zenhui : public TriggerSkill
{
public:
    Zenhui() : TriggerSkill("zenhui")
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
        if (triggerEvent == CardFinished && (use.card->isKindOf("Slash") || (use.card->isNDTrick() && use.card->isBlack()))) {
            use.from->setFlags("-ZenhuiUser_" + use.card->toString());
            return false;
        }
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Play || player->hasFlag(objectName()))
            return false;

        if (use.to.length() == 1 && !use.card->targetFixed()
            && (use.card->isKindOf("Slash") || (use.card->isNDTrick() && use.card->isBlack()))) {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p != player && p != use.to.first() && !room->isProhibited(player, p, use.card) && use.card->targetFilter(QList<const Player *>(), p, player))
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            use.from->tag["zenhui"] = data;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "zenhui-invoke:" + use.to.first()->objectName(), true, true);
            use.from->tag.remove("zenhui");
            if (target) {
                player->setFlags(objectName());

                // Collateral
                ServerPlayer *collateral_victim = NULL;
                if (use.card->isKindOf("Collateral")) {
                    QList<ServerPlayer *> victims;
                    foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                        if (target->canSlash(p))
                            victims << p;
                    }
                    Q_ASSERT(!victims.isEmpty());
                    collateral_victim = room->askForPlayerChosen(player, victims, "zenhui_collateral", "@zenhui-collateral:" + target->objectName());
                    target->tag["collateralVictim"] = QVariant::fromValue((collateral_victim));

                    LogMessage log;
                    log.type = "#CollateralSlash";
                    log.from = player;
                    log.to << collateral_victim;
                    room->sendLog(log);
                }

                room->broadcastSkillInvoke(objectName());

                bool extra_target = true;
                if (!target->isNude()) {
                    const Card *card = room->askForCard(target, "..", "@zenhui-give:" + player->objectName(), data, Card::MethodNone);
                    if (card) {
                        extra_target = false;
                        player->obtainCard(card);

                        if (target->isAlive()) {
                            LogMessage log;
                            log.type = "#BecomeUser";
                            log.from = target;
                            log.card_str = use.card->toString();
                            room->sendLog(log);

                            target->setFlags("ZenhuiUser_" + use.card->toString()); // For AI
                            use.from = target;
                            data = QVariant::fromValue(use);
                        }
                    }
                }
                if (extra_target) {
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

class Jiaojin : public TriggerSkill
{
public:
    Jiaojin() : TriggerSkill("jiaojin")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->isMale() && player->canDiscard(player, "he")) {
            if (room->askForCard(player, ".Equip", "@jiaojin", data, objectName())) {
                room->broadcastSkillInvoke(objectName());

                LogMessage log;
                log.type = "#Jiaojin";
                log.from = player;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(--damage.damage);
                room->sendLog(log);

                if (damage.damage < 1)
                    return true;
                data = QVariant::fromValue(damage);
            }
        }
        return false;
    }
};

class Youdi : public PhaseChangeSkill
{
public:
    Youdi() : PhaseChangeSkill("youdi")
    {
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() != Player::Finish || target->isNude()) return false;
        Room *room = target->getRoom();
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
            if (p->canDiscard(target, "he")) players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *player = room->askForPlayerChosen(target, players, objectName(), "youdi-invoke", true, true);
        if (player) {
            room->broadcastSkillInvoke(objectName());
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, target, player);
            if (!Sanguosha->getCard(id)->isKindOf("Slash") && player->isAlive() && !player->isNude()) {
                int id2 = room->askForCardChosen(target, player, "he", "youdi_obtain");
                room->obtainCard(target, id2, false);
            }
        }
        return false;
    }
};

class Qieting : public TriggerSkill
{
public:
    Qieting() : TriggerSkill("qieting")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive || player->getMark("qieting") > 0) return false;
        foreach (ServerPlayer *caifuren, room->getAllPlayers()) {
            if (!TriggerSkill::triggerable(caifuren) || caifuren == player) continue;
            QStringList choices;
            for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
                if (player->getEquip(i) && !caifuren->getEquip(i) && caifuren->hasEquipArea(i))
                    choices << QString::number(i);
            }
            choices << "draw" << "cancel";
            QString choice = room->askForChoice(caifuren, objectName(), choices.join("+"), QVariant::fromValue(player));
            if (choice == "cancel") {
                continue;
            } else {
                LogMessage log;
                log.type = "#InvokeSkill";
                log.arg = objectName();
                log.from = caifuren;
                room->sendLog(log);
                room->notifySkillInvoked(caifuren, objectName());
                if (choice == "draw") {
                    room->broadcastSkillInvoke(objectName(), 2);
                    caifuren->drawCards(1, objectName());
                } else {
                    room->broadcastSkillInvoke(objectName(), 1);
                    int index = choice.toInt();
                    const Card *card = player->getEquip(index);
                    room->moveCardTo(card, caifuren, Player::PlaceEquip);
                }
            }
        }
        return false;
    }
};

class QietingRecord : public TriggerSkill
{
public:
    QietingRecord() : TriggerSkill("#qieting-record")
    {
        events << PreCardUsed << TurnStart;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 6;
    }

    bool trigger(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == PreCardUsed && player->isAlive() && player->getPhase() != Player::NotActive
            && player->getMark("qieting") == 0) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() != Card::TypeSkill) {
                foreach (ServerPlayer *p, use.to) {
                    if (p != player) {
                        player->addMark("qieting");
                        return false;
                    }
                }
            }
        } else if (triggerEvent == TurnStart) {
            player->setMark("qieting", 0);
        }
        return false;
    }
};

XianzhouDamageCard::XianzhouDamageCard()
{
    mute = true;
}

void XianzhouDamageCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardUsed, room, use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, use.from, data);
}

bool XianzhouDamageCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    return targets.length() == Self->getMark("xianzhou");
}

bool XianzhouDamageCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < Self->getMark("xianzhou") && Self->inMyAttackRange(to_select);
}

void XianzhouDamageCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->getRoom()->damage(DamageStruct("xianzhou", effect.from, effect.to));
}

XianzhouCard::XianzhouCard()
{
}

bool XianzhouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void XianzhouCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->removePlayerMark(effect.from, "@handover");
    //room->doLightbox("$XianzhouAnimate");
    room->doSuperLightbox("caifuren", "xianzhou");

    int len = 0;
    DummyCard *dummy = new DummyCard;
    foreach (const Card *c, effect.from->getEquips()) {
        dummy->addSubcard(c);
        len++;
    }
    room->setPlayerMark(effect.to, "xianzhou", len);
    effect.to->obtainCard(dummy);
    delete dummy;

    bool rec = true;
    int count = 0;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.to)) {
        if (effect.to->inMyAttackRange(p)) {
            count++;
            if (count >= len) {
                rec = false;
                break;
            }
        }
    }

    if ((rec || !room->askForUseCard(effect.to, "@xianzhou", "@xianzhou-damage:::" + QString::number(len))))
        room->recover(effect.from, RecoverStruct(effect.to, NULL, qMin(len, effect.from->getMaxHp() - effect.from->getHp())));
}

class Xianzhou : public ZeroCardViewAsSkill
{
public:
    Xianzhou() : ZeroCardViewAsSkill("xianzhou")
    {
        frequency = Skill::Limited;
        limit_mark = "@handover";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@handover") > 0 && player->getEquips().length() > 0;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@xianzhou";
    }

    const Card *viewAs() const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@xianzhou") {
            return new XianzhouDamageCard;
        } else {
            return new XianzhouCard;
        }
    }
};

Jianying::Jianying() : TriggerSkill("jianying")
{
    frequency = Frequent;
    events << CardUsed << CardResponded << EventPhaseChanging << EventLoseSkill;
    jianying = "Jianying";
    global = true;
}

bool Jianying::trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
{
    QString lastsuit = jianying + "Suit", lastnumber = jianying + "Number";

    if (triggerEvent == CardUsed || triggerEvent == CardResponded) {
        const Card *card = NULL;
        if (triggerEvent == CardUsed)
            card = data.value<CardUseStruct>().card;
        else if (triggerEvent == CardResponded) {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_isUse)
                card = resp.m_card;
        }
        if (!card || card->getTypeId() == Card::TypeSkill) return false;
        if (!card->hasSuit() && card->getNumber() <= 0) return false;

        if (card->hasSuit() && player->getPhase() != Player::NotActive)
            room->setPlayerProperty(player, "MobileJianyingLastSuitString", card->getSuitString());

        if (jianying == "TenyearJianying" || player->getPhase() == Player::Play) {
            int suit = player->getMark(lastsuit), number = player->getMark(lastnumber);
            player->setMark(lastsuit, int(card->getSuit()) + 1);
            player->setMark(lastnumber, card->getNumber());

            if (player->isAlive() && player->hasSkill(objectName(), true)) {
                foreach (QString mark, player->getMarkNames()) {
                    if (!mark.startsWith("&" + objectName() + "+") && !mark.contains("+#record")) continue;
                    room->setPlayerMark(player, mark, 0);
                }
                QString jianyingmark = QString("&%1+%2+%3+#record").arg(objectName()).arg(card->getSuitString() + "_char")
                        .arg(card->getNumberString());
                room->setPlayerMark(player, jianyingmark, 1);
            }

            if (player->isAlive() && player->hasSkill(objectName())
                && ((suit > 0 && int(card->getSuit()) + 1 == suit)
                || (number > 0 && card->getNumber() == number))
                && room->askForSkillInvoke(player, objectName(), data)) {
                room->broadcastSkillInvoke(objectName());
                room->drawCards(player, 1, objectName());
            }
        }
    } else if (triggerEvent == EventPhaseChanging) {
        if (jianying == "TenyearJianying") return false;
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.from == Player::Play) {
            player->setMark(lastsuit, 0);
            player->setMark(lastnumber, 0);
            room->setPlayerProperty(player, "MobileJianyingLastSuitString", QString());

            foreach (QString mark, player->getMarkNames()) {
                if (mark.startsWith("&tenyearjianying")) continue;  //在jianying和mobilejianying里会移除这些标记，因为都是global，三个技能都触发
                if (!mark.startsWith("&" + objectName() + "+") && !mark.contains("+#record")) continue;
                room->setPlayerMark(player, mark, 0);
            }
        }
    } else if (triggerEvent == EventLoseSkill) {
        if (data.toString() != objectName()) return false;
        if (player->hasSkill(this, true)) return false;
        foreach (QString mark, player->getMarkNames()) {
            if (!mark.startsWith("&" + objectName() + "+") && !mark.contains("+#record")) continue;
            room->setPlayerMark(player, mark, 0);
        }
    }
    return false;
}

class Shibei : public MasochismSkill
{
public:
    Shibei() : MasochismSkill("shibei")
    {
        frequency = Compulsory;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        Room *room = player->getRoom();
        if (player->getMark("shibei") > 0) {
            room->sendCompulsoryTriggerLog(player, this);

            if (player->getMark("shibei") == 1)
                room->recover(player, RecoverStruct(player));
            else
                room->loseHp(player);
        }
    }
};

class ShibeiRecord : public TriggerSkill
{
public:
    ShibeiRecord() : TriggerSkill("#shibei-record")
    {
        events << PreDamageDone << EventPhaseChanging;
        frequency = Compulsory;
        global = true;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach(ServerPlayer *p, room->getAlivePlayers())
                    p->setMark("shibei", 0);
            }
        } else if (triggerEvent == PreDamageDone) {
            ServerPlayer *current = room->getCurrent();
            if (!current || current->isDead() || current->getPhase() == Player::NotActive)
                return false;
            player->addMark("shibei");
        }
        return false;
    }
};

class NewSidi : public TriggerSkill
{
public:
    NewSidi() : TriggerSkill("newsidi")
    {
        events << EventPhaseEnd << EventPhaseStart << PreCardUsed << EventPhaseChanging << Death;
        global = true;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->isDead() || player->getPhase() != Player::Play) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this) || p->getEquips().isEmpty() || !p->canDiscard(p, "he")) continue;
                QStringList pattern;
                foreach (const Card *c, p->getEquips()) {
                    if (c->isRed() && !pattern.contains("red"))
                        pattern << "red";
                    else if (c->isBlack() && !pattern.contains("black"))
                        pattern << "black";
                    if (pattern.contains("red") && pattern.contains("black")) break;
                }
                if (pattern.isEmpty()) continue;
                const Card *card = room->askForCard(p, "^BasicCard|" + pattern.join(","), "@newsidi-discard:" + player->objectName(), data, objectName());
                if (!card) continue;
                room->broadcastSkillInvoke(objectName());
                QString colour = "";
                if (card->isBlack())
                    colour = "black";
                else if (card->isRed())
                    colour = "red";
                if (colour == "") continue;
                QStringList colours = player->property("newsidi_colour").toStringList();
                if (!colours.contains(colour)) {
                    colours << colour;
                    room->setPlayerProperty(player, "newsidi_colour", colours);
                    room->setPlayerCardLimitation(player, "use,response", QString(".|%1").arg(colour), true);
                    room->addPlayerMark(player, "&newsidi+" + colour + "-Clear");
                }
                QStringList sidis = player->property("newsidi_from").toStringList();
                if (sidis.contains(p->objectName())) continue;
                sidis << p->objectName();
                room->setPlayerProperty(player, "newsidi_from", sidis);
            }
        } else if (event == EventPhaseEnd) {
            if (player->isDead() || player->getPhase() != Player::Play) return false;
            if (player->getMark("newsidi_slash-PlayClear") > 0) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this)) continue;
                QStringList sidis = player->property("newsidi_from").toStringList();
                if (!sidis.contains(p->objectName())) continue;
                sidis.removeOne(p->objectName());
                room->setPlayerProperty(player, "newsidi_from", sidis);
                Slash *slash = new Slash(Card::NoSuit, 0);
                slash->setSkillName("_newsidi");
                slash->deleteLater();
                if (!p->canSlash(player, slash, false)) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true);
                room->useCard(CardUseStruct(slash, p, player));
            }
        } else if (event == PreCardUsed) {
            if (player->isDead() || player->getPhase() != Player::Play) return false;
            const Card *card = data.value<CardUseStruct>().card;
            if (!card->isKindOf("Slash")) return false;
            room->addPlayerMark(player, "newsidi_slash-PlayClear");
        } else {
            if (event == EventPhaseChanging) {
                if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            }
            room->setPlayerProperty(player, "newsidi_colour", QStringList());
            room->setPlayerProperty(player, "newsidi_from", QStringList());
        }
        return false;
    }
};

NewDingpinCard::NewDingpinCard()
{
}

bool NewDingpinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getMark("newdingpin_to-PlayClear") <=0 && to_select != Self;
}

void NewDingpinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.to, "newdingpin_to-PlayClear");
    room->addPlayerMark(effect.from, "&newdingpin-PlayClear");

    int type = Sanguosha->getCard(getSubcards().first())->getTypeId();
    room->addPlayerMark(effect.from, "newdingpin_card" + QString::number(type) + "-PlayClear");

    if (effect.from->isDead() || effect.to->isDead()) return;
    QStringList choices;
    choices << "draw";
    if (!effect.to->isNude())
        choices << "discard";
    QString choice = room->askForChoice(effect.from, "newdingpin", choices.join("+"));
    int n = effect.from->getMark("&newdingpin-PlayClear");
    if (choice == "draw")
        effect.to->drawCards(n, "newdingpin");
    else
        room->askForDiscard(effect.to, "newdingpin", n, n, false, true);
    if (effect.from->isDead() || effect.to->isDead() || !effect.to->isWounded() || effect.from->isChained()) return;
    room->setPlayerChained(effect.from);
}

class NewDingpin : public OneCardViewAsSkill
{
public:
    NewDingpin() : OneCardViewAsSkill("newdingpin")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    bool viewFilter(const Card *to_select) const
    {
        int n = Self->getMark("newdingpin_card" + QString::number(to_select->getTypeId()) + "-PlayClear");
        return n <= 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        NewDingpinCard *card = new NewDingpinCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class NewFaen : public TriggerSkill
{
public:
    NewFaen() : TriggerSkill("newfaen")
    {
        events << TurnedOver << ChainStateChanged;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == ChainStateChanged && !player->isChained()) return false;
        if (triggerEvent == TurnedOver && !player->faceUp()) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (!player->isAlive()) return false;
            if (TriggerSkill::triggerable(p)
                && room->askForSkillInvoke(p, objectName(), QVariant::fromValue(player))) {
                room->broadcastSkillInvoke(objectName());
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class NewZhongyong : public TriggerSkill
{
public:
    NewZhongyong() : TriggerSkill("newzhongyong")
    {
        events << SlashMissed << CardFinished;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == SlashMissed) {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            QVariantList slash = player->tag["newzhongyong_slash" + effect.slash->toString()].toList();
            if (effect.slash->isVirtualCard() && effect.slash->subcardsLength() > 0) {
                foreach (int id, effect.slash->getSubcards()) {
                    if (slash.contains(QVariant(id))) continue;
                    slash << id;
                }
            } else if (!effect.slash->isVirtualCard()) {
                if (!slash.contains(QVariant(effect.slash->getEffectiveId())))
                    slash << effect.slash->getEffectiveId();
            }
            player->tag["newzhongyong_slash" + effect.slash->toString()] = slash;

            if (!effect.jink) return false;
            QVariantList jink = player->tag["newzhongyong_jink" + effect.slash->toString()].toList();
            if (effect.jink->isVirtualCard() && effect.jink->subcardsLength() > 0) {
                foreach (int id, effect.jink->getSubcards()) {
                    if (jink.contains(QVariant(id))) continue;
                    jink << id;
                }
            } else if (!effect.jink->isVirtualCard()) {
                if (!jink.contains(QVariant(effect.jink->getEffectiveId())))
                    jink << effect.jink->getEffectiveId();
            }
            player->tag["newzhongyong_jink" + effect.slash->toString()] = jink;
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;

            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (use.to.contains(p)) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;

            QVariantList slash = player->tag["newzhongyong_slash" + use.card->toString()].toList();
            QVariantList jink = player->tag["newzhongyong_jink" + use.card->toString()].toList();
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

            QStringList choices;
            if (!slash_ids.isEmpty())
                choices << "slash";
            if (!jink_ids.isEmpty())
                choices << "jink";
            if (choices.isEmpty()) return false;

            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@newzhongyong-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());

            QList<int> give_list;
            QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
            if (choice == "slash")
                give_list = slash_ids;
            else
                give_list = jink_ids;
            room->giveCard(player, target, give_list, objectName(), true);

            if (target->isDead()) return false;
            bool red = false;
            foreach (int id, give_list) {
                if (Sanguosha->getCard(id)->isRed()) {
                    red = true;
                    break;
                }
            }
            if (!red) return false;

            QList<ServerPlayer *> tos;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (player->inMyAttackRange(p) && target->canSlash(p, NULL, true))
                    tos << p;
            }
            if (tos.isEmpty()) return false;
            room->askForUseSlashTo(target, tos, "@newzhongyong-slash");
        }
        return false;
    }
};

class Fenli : public TriggerSkill
{
public:
    Fenli() : TriggerSkill("fenli")
    {
        events << EventPhaseChanging;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        Player::Phase phase = data.value<PhaseChangeStruct>().to;
        if (player->isSkipped(phase)) return false;
        if (phase == Player::Draw) {
            int hand = player->getHandcardNum();
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHandcardNum() > hand)
                    return false;
            }
            if (!player->askForSkillInvoke(this, "draw")) return false;
        } else if (phase == Player::Play) {
            int hp = player->getHp();
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHp() > hp)
                    return false;
            }
            if (!player->askForSkillInvoke(this, "play")) return false;
        } else if (phase == Player::Discard) {
            int equip = player->getEquips().length();
            if (equip <= 0) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getEquips().length() > equip)
                    return false;
            }
            if (!player->askForSkillInvoke(this, "discard")) return false;
        } else
            return false;

        room->broadcastSkillInvoke(objectName());
        player->skip(phase);
        return false;
    }
};

PingkouCard::PingkouCard()
{
}

bool PingkouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < Self->getMark("pingkou_phase_skipped-Clear") && to_select != Self;
}

void PingkouCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->getRoom()->damage(DamageStruct("pingkou", effect.from, effect.to));
}

class PingkouVS : public ZeroCardViewAsSkill
{
public:
    PingkouVS() : ZeroCardViewAsSkill("pingkou")
    {
        response_pattern = "@@pingkou";
    }

    const Card *viewAs() const
    {
        return new PingkouCard;
    }
};

class Pingkou : public TriggerSkill
{
public:
    Pingkou() : TriggerSkill("pingkou")
    {
        events << EventPhaseChanging << EventPhaseSkipped;
        view_as_skill = new PingkouVS;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            int max = player->getMark("pingkou_phase_skipped-Clear");
            if (player->isDead() || !player->hasSkill(this) || max <= 0) return false;
            max = qMin(max, room->alivePlayerCount() - 1);
            room->askForUseCard(player, "@@pingkou", "@pingkou:" + QString::number(max));
        } else
            room->addPlayerMark(player, "pingkou_phase_skipped-Clear", 1);
        return false;
    }
};

class OLBenxiVS : public ZeroCardViewAsSkill
{
public:
    OLBenxiVS() : ZeroCardViewAsSkill("olbenxi")
    {
        response_pattern = "@@olbenxi!";
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

class OLBenxi : public TriggerSkill
{
public:
    OLBenxi() : TriggerSkill("olbenxi")
    {
        events << CardUsed << Damage << PreCardUsed << CardResponded;
        view_as_skill =new OLBenxiVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (player->getPhase() == Player::NotActive || use.card->isKindOf("SkillCard")) return false;
            //room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->notifySkillInvoked(player, objectName());
            room->addDistance(player, -1);
            room->addPlayerMark(player, "&olbenxi-Clear");
        } else if (event == CardResponded) {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (player->getPhase() == Player::NotActive || res.m_card->isKindOf("SkillCard")) return false;
            if (!res.m_isUse) return false;
            room->notifySkillInvoked(player, objectName());
            room->addDistance(player, -1);
            room->addPlayerMark(player, "&olbenxi-Clear");
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
                log.arg = "olbenxi:" + choice;
                room->sendLog(log);
                if (choice == "extra") {
                    ServerPlayer *target = NULL;
                    if (!use.card->isKindOf("Collateral"))
                        target = room->askForPlayerChosen(player, available_targets, objectName(), "@olbenxi-extra:" + use.card->objectName());
                    else {
                        QStringList tos;
                        foreach(ServerPlayer *t, use.to)
                            tos.append(t->objectName());
                        room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                        room->setPlayerProperty(player, "extra_collateral_current_targets", tos.join("+"));
                        room->askForUseCard(player, "@@olbenxi!", "@olbenxi-extra:" + use.card->objectName());
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

                    if (use.card->hasFlag("olbenxi_ignore"))
                        target->addQinggangTag(use.card);

                    LogMessage log;
                    log.type = "#QiaoshuiAdd";
                    log.from = player;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = "olbenxi";
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
                    room->setCardFlag(use.card, "olbenxi_ignore");
                    foreach (ServerPlayer *p, use.to)
                        p->addQinggangTag(use.card);
                } else if (choice == "noresponse") {
                    use.no_offset_list << "_ALL_TARGETS";
                    data = QVariant::fromValue(use);
                } else {
                    room->setCardFlag(use.card, "olbenxi_damage");
                }
            }
        } else if (event == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->hasFlag("olbenxi_damage")) return false;
            player->drawCards(1, objectName());
        }
        return false;
    }
};

YJCM2014Package::YJCM2014Package()
    : Package("YJCM2014")
{
    General *caifuren = new General(this, "caifuren", "qun", 3, false); // YJ 301
    caifuren->addSkill(new Qieting);
    caifuren->addSkill(new QietingRecord);
    caifuren->addSkill(new Xianzhou);
    related_skills.insertMulti("qieting", "#qieting-record");

    General *caozhen = new General(this, "caozhen", "wei"); // YJ 302
    caozhen->addSkill(new Sidi);
    caozhen->addSkill(new SidiTargetMod);
    related_skills.insertMulti("sidi", "#sidi-target");

    General *new_caozhen = new General(this, "new_caozhen", "wei");
    new_caozhen->addSkill(new NewSidi);

    General *chenqun = new General(this, "chenqun", "wei", 3); // YJ 303
    chenqun->addSkill(new Dingpin);
    chenqun->addSkill(new Faen);

    General *new_chenqun = new General(this, "new_chenqun", "wei", 3);
    new_chenqun->addSkill(new NewDingpin);
    new_chenqun->addSkill(new NewFaen);

    General *guyong = new General(this, "guyong", "wu", 3); // YJ 304
    guyong->addSkill(new Shenxing);
    guyong->addSkill(new Bingyi);

    General *hanhaoshihuan = new General(this, "hanhaoshihuan", "wei"); // YJ 305
    hanhaoshihuan->addSkill(new Shenduan);
    hanhaoshihuan->addSkill(new ShenduanUse);
    hanhaoshihuan->addSkill(new ShenduanTargetMod);
    hanhaoshihuan->addSkill(new Yonglve);
    hanhaoshihuan->addSkill(new YonglveSlash);
    related_skills.insertMulti("shenduan", "#shenduan");
    related_skills.insertMulti("shenduan", "#shenduan-target");
    related_skills.insertMulti("yonglve", "#yonglve");

    General *jvshou = new General(this, "jvshou", "qun", 3); // YJ 306
    jvshou->addSkill(new Jianying);
    jvshou->addSkill(new Shibei);
    jvshou->addSkill(new ShibeiRecord);
    related_skills.insertMulti("shibei", "#shibei-record");

    General *sunluban = new General(this, "sunluban", "wu", 3, false); // YJ 307
    sunluban->addSkill(new Zenhui);
    sunluban->addSkill(new Jiaojin);

    General *wuyi = new General(this, "wuyi", "shu"); // YJ 308
    wuyi->addSkill(new Benxi);
    wuyi->addSkill(new BenxiTargetMod);
    wuyi->addSkill(new BenxiDistance);
    related_skills.insertMulti("benxi", "#benxi-target");
    related_skills.insertMulti("benxi", "#benxi-dist");

    General *ol_wuyi = new General(this, "ol_wuyi", "shu");
    ol_wuyi->addSkill(new OLBenxi);

    General *zhangsong = new General(this, "zhangsong", "shu", 3); // YJ 309
    zhangsong->addSkill(new Qiangzhi);
    zhangsong->addSkill(new Xiantu);

    General *zhoucang = new General(this, "zhoucang", "shu"); // YJ 310
    zhoucang->addSkill(new Zhongyong);

    General *new_zhoucang = new General(this, "new_zhoucang", "shu");
    new_zhoucang->addSkill(new NewZhongyong);

    General *zhuhuan = new General(this, "zhuhuan", "wu"); // YJ 311
    zhuhuan->addSkill(new Youdi);

    General *new_zhuhuan = new General(this, "new_zhuhuan", "wu");
    new_zhuhuan->addSkill(new Fenli);
    new_zhuhuan->addSkill(new Pingkou);

    addMetaObject<DingpinCard>();
    addMetaObject<ShenxingCard>();
    addMetaObject<BingyiCard>();
    addMetaObject<XianzhouCard>();
    addMetaObject<XianzhouDamageCard>();
    addMetaObject<SidiCard>();
    addMetaObject<NewDingpinCard>();
    addMetaObject<PingkouCard>();
}

ADD_PACKAGE(YJCM2014)
