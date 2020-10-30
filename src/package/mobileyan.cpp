#include "mobileyan.h"
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

MobileYanYajunCard::MobileYanYajunCard()
{
    will_throw = false;
    handling_method = Card::MethodPindian;
}

bool MobileYanYajunCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void MobileYanYajunCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    ServerPlayer *from = effect.from, *to = effect.to;

    PindianStruct *pindian = from->PinDian(to, "mobileyanyajun", this);
    if (pindian->success) {
        QList<int> pindian_ids;
        if (room->CardInPlace(pindian->from_card, Player::DiscardPile))
            pindian_ids << pindian->from_card->getEffectiveId();
        if (room->CardInPlace(pindian->to_card, Player::DiscardPile) && !pindian_ids.contains(pindian->to_card->getEffectiveId()))
            pindian_ids << pindian->to_card->getEffectiveId();
        if (pindian_ids.isEmpty()) return;

        room->notifyMoveToPile(from, pindian_ids, "mobileyanyajun", Player::DiscardPile, true);

        try {
            room->askForUseCard(from, "@@mobileyanyajun2", "@mobileyanyajun2", 2, Card::MethodNone);
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                room->notifyMoveToPile(from, pindian_ids, "mobileyanyajun", Player::DiscardPile, false);
            throw triggerEvent;
        }

        room->notifyMoveToPile(from, pindian_ids, "mobileyanyajun", Player::DiscardPile, false);

    } else
        room->addMaxCards(from, -1);
}

MobileYanYajunPutCard::MobileYanYajunPutCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
    m_skillName = "mobileyanyajun";
}

void MobileYanYajunPutCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    LogMessage log;
    log.type = "$YinshicaiPut";
    log.from = card_use.from;
    log.card_str = IntList2StringList(subcards).join("+");
    room->sendLog(log);
    CardMoveReason reason(CardMoveReason::S_REASON_PUT, card_use.from->objectName(), "mobileyanyajun", QString());
    room->moveCardTo(this, NULL, Player::DrawPile, reason, true);
}

class MobileYanYajunVS : public OneCardViewAsSkill
{
public:
    MobileYanYajunVS() : OneCardViewAsSkill("mobileyanyajun")
    {
        expand_pile = "#mobileyanyajun";
    }

    bool viewFilter(const Card *to_select) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern.endsWith("2"))
            return Self->getPile("#mobileyanyajun").contains(to_select->getEffectiveId());
        else if (pattern.endsWith("1")) {
            QStringList strs = Self->property("MobileYanYajunIds").toString().split("+");
            QList<int> ids = StringList2IntList(strs);
            return ids.contains(to_select->getEffectiveId());
        }
        return false;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
       return pattern.startsWith("@@mobileyanyajun") ;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern.endsWith("2")) {
            MobileYanYajunPutCard *c = new MobileYanYajunPutCard();
            c->addSubcard(originalCard);
            return c;
        } else if (pattern.endsWith("1")) {
            MobileYanYajunCard *c = new MobileYanYajunCard();
            c->addSubcard(originalCard);
            return c;
        }
        return NULL;
    }
};

class MobileYanYajun : public TriggerSkill
{
public:
    MobileYanYajun() : TriggerSkill("mobileyanyajun")
    {
        events << DrawNCards << EventPhaseStart;
        view_as_skill = new MobileYanYajunVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DrawNCards) {
            room->sendCompulsoryTriggerLog(player, this);
            data = data.toInt() + 1;
        } else {
            if (player->getPhase() != Player::Play || !player->canPindian()) return false;
            QString fulin = player->property("fulin_list").toString();
            if (fulin.isEmpty()) return false;

            QStringList this_turn_cards, fulinlist = fulin.split("+");
            foreach (QString str, fulinlist) {
                int id = str.toInt();
                if (!id || id < 0) continue;
                if (!player->hasCard(id)) continue;
                this_turn_cards << str;
            }
            if (this_turn_cards.isEmpty()) return false;

            room->setPlayerProperty(player, "MobileYanYajunIds", this_turn_cards.join("+"));
            try {
                room->askForUseCard(player, "@@mobileyanyajun1", "@mobileyanyajun1", 1, Card::MethodPindian);
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                    room->setPlayerProperty(player, "MobileYanYajunIds", QString());
                throw triggerEvent;
            }

            room->setPlayerProperty(player, "MobileYanYajunIds", QString());
        }
        return false;
    }
};

MobileYanZundiCard::MobileYanZundiCard()
{
}

bool MobileYanZundiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void MobileYanZundiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    if (from->isDead()) return;
    Room *room = from->getRoom();

    JudgeStruct judge;
    judge.who = from;
    judge.pattern = ".";
    judge.reason = "mobileyanzundi";
    judge.play_animation = false;
    room->judge(judge);

    if (to->isDead()) return;
    QString color = judge.pattern;
    if (color == "red")
        room->moveField(to, "mobileyanzundi", true, "ej");
    else if (color == "black")
        to->drawCards(3, "mobileyanzundi");
}

class MobileYanZundiVS : public OneCardViewAsSkill
{
public:
    MobileYanZundiVS() : OneCardViewAsSkill("mobileyanzundi")
    {
        filter_pattern = ".|.|.|hand!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileYanZundiCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileYanZundiCard *c = new MobileYanZundiCard();
        c->addSubcard(originalCard);
        return c;
    }
};

class MobileYanZundi : public TriggerSkill
{
public:
    MobileYanZundi() : TriggerSkill("mobileyanzundi")
    {
        events << FinishJudge;
        view_as_skill = new MobileYanZundiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != objectName()) return false;
        judge->pattern = judge->card->getColorString();
        return false;
    }
};

class MobileYanDifei : public MasochismSkill
{
public:
    MobileYanDifei() : MasochismSkill("mobileyandifei")
    {
        frequency = Compulsory;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        if (player->getMark("mobileyandifei_used-Clear") > 0) return;
        Room *room = player->getRoom();
        if (!room->hasCurrent()) return;
        room->sendCompulsoryTriggerLog(player, this);
        room->addPlayerMark(player, "mobileyandifei_used-Clear");
        if (!player->canDiscard(player, "he") || !room->askForDiscard(player, objectName(), 1, 1, true, true, "@mobileyandifei-discard"))
            player->drawCards(1, objectName());
        if (player->isDead() || player->isKongcheng()) return;
        room->showAllCards(player);
        if (!damage.card || !damage.card->hasSuit() || damage.card->isKindOf("SkillCard")) return;
        Card::Suit suit = damage.card->getSuit();
        foreach (const Card *card, player->getHandcards()) {
            if (card->getSuit() == suit) return;
        }
        room->recover(player, RecoverStruct(player));
    }
};

MobileYanYanjiaoCard::MobileYanYanjiaoCard()
{
}

void MobileYanYanjiaoCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    QStringList suits;
    foreach (const Card *card, from->getHandcards()) {
        QString suit = card->getSuitString();
        if (suits.contains(suit)) continue;
        suits << suit;
    }
    if (suits.isEmpty()) return;

    QString suit = room->askForChoice(from, "mobileyanyanjiao", suits.join("+"), QVariant::fromValue(to));
    DummyCard *dummy = new DummyCard();
    dummy->deleteLater();
    foreach (const Card *card, from->getHandcards()) {
        if (card->getSuitString() == suit)
        dummy->addSubcard(card);
    }
    if (dummy->subcardsLength() <= 0) return;

    room->addPlayerMark(from, "&mobileyanyanjiao_draw", dummy->subcardsLength());
    room->giveCard(from, to, dummy, "mobileyanyanjiao");
    room->damage(DamageStruct("mobileyanyanjiao", from, to));
}

class MobileYanYanjiaoVS : public ZeroCardViewAsSkill
{
public:
    MobileYanYanjiaoVS() : ZeroCardViewAsSkill("mobileyanyanjiao")
    {
    }

    const Card *viewAs() const
    {
        return new MobileYanYanjiaoCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileYanYanjiaoCard") && !player->isKongcheng();
    }
};

class MobileYanYanjiao : public PhaseChangeSkill
{
public:
    MobileYanYanjiao() : PhaseChangeSkill("mobileyanyanjiao")
    {
        view_as_skill = new MobileYanYanjiaoVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&mobileyanyanjiao_draw") > 0 && target->getPhase() == Player::RoundStart;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        int mark = player->getMark("&mobileyanyanjiao_draw");
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#ZhenguEffect";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);
        room->setPlayerMark(player, "&mobileyanyanjiao_draw", 0);
        player->drawCards(mark, objectName());
        return false;
    }
};

class MobileYanZhenting : public TriggerSkill
{
public:
    MobileYanZhenting() : TriggerSkill("mobileyanzhenting")
    {
        events << TargetConfirming;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card || !(use.card->isKindOf("Slash") || use.card->isKindOf("DelayedTrick"))) return false;

        foreach (ServerPlayer *jw, room->getOtherPlayers(player)) {
            if (!use.to.contains(player)) return false;
            if (jw->isDead() || !jw->hasSkill(this) || use.to.contains(jw)) continue;
            if (jw == use.from || !jw->inMyAttackRange(player) || jw->getMark("mobileyanzhenting_used-Clear") > 0) continue;
            if (!jw->askForSkillInvoke(this, "mobileyanzhenting_replace:" + player->objectName() + "::" + use.card->objectName())) continue;
            room->addPlayerMark(jw, "mobileyanzhenting_used-Clear");
            room->broadcastSkillInvoke(this);
            use.to.removeOne(player);
            use.to << jw;
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);

            QStringList choices;
            if (use.from && use.from->isAlive() && jw->canDiscard(use.from, "h"))
                choices << "discard=" + use.from->objectName();
            choices << "draw" << "cancel";

            QString choice = room->askForChoice(jw, objectName(), choices.join("+"), QVariant::fromValue(use.from));
            if (choice == "cancel") {
                room->getThread()->trigger(TargetConfirming, room, jw, data);
                continue;
            }
            if (choice == "draw")
                jw->drawCards(1, objectName());
            else {
                if (!jw->canDiscard(use.from, "h")) continue;
                int id = room->askForCardChosen(jw, use.from, "h", objectName(), false, Card::MethodDiscard);
                room->throwCard(id, use.from, jw);
            }
            room->getThread()->trigger(TargetConfirming, room, jw, data);
        }
        return false;
    }
};

MobileYanJincuiCard::MobileYanJincuiCard()
{
}

void MobileYanJincuiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    room->doSuperLightbox("mobileyan_jiangwan", "mobileyanjincui");
    room->removePlayerMark(from, "@mobileyanjincuiMark");

    room->swapSeat(from, to);

    if (from->isDead()) return;
    int hp = from->getHp();
    if (hp > 0)
        room->loseHp(from, hp);
}

class MobileYanJincui : public ZeroCardViewAsSkill
{
public:
    MobileYanJincui() : ZeroCardViewAsSkill("mobileyanjincui")
    {
        frequency = Limited;
        limit_mark = "@mobileyanjincuiMark";
    }

    const Card *viewAs() const
    {
        return new MobileYanJincuiCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@mobileyanjincuiMark") > 0;
    }
};

class MobileYanJianyi : public PhaseChangeSkill
{
public:
    MobileYanJianyi() : PhaseChangeSkill("mobileyanjianyi")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::NotActive;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            QVariantList armors = room->getTag("MobileYanJianyiRecord").toList();
            QList<int> ids;
            foreach (QVariant id, armors) {
                if (room->getCardPlace(id.toInt()) == Player::DiscardPile)
                    ids << id.toInt();
            }
            if (ids.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(p, this);
            room->fillAG(ids, p);
            int id = room->askForAG(p, ids, false, objectName());
            room->clearAG(p);
            room->obtainCard(p, id);
        }
        return false;
    }

};

class MobileYanJianyiRecord : public TriggerSkill
{
public:
    MobileYanJianyiRecord() : TriggerSkill("#mobileyanjianyi-record")
    {
        events << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            QVariantList armors = room->getTag("MobileYanJianyiRecord").toList();
            foreach (int id, move.card_ids) {
                const Card *card = Sanguosha->getCard(id);
                if (!card->isKindOf("Armor") || armors.contains(QVariant::fromValue(id))) continue;
                armors << id;
            }
            room->setTag("MobileYanJianyiRecord", armors);
        }
        return false;
    }
};

MobileYanShangyiCard::MobileYanShangyiCard()
{
}

bool MobileYanShangyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_selet, const Player *Self) const
{
    return targets.isEmpty() && to_selet != Self && !to_selet->isKongcheng();
}

void MobileYanShangyiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    if (!from->isKongcheng())
        room->doGongxin(to, from, QList<int>(), "mobileyanjincui");
    if (to->isAlive() && !to->isKongcheng()) {
        int id = room->doGongxin(from, to, to->handCards(), "mobileyanjincui");
        if (id < 0)
            id = to->getRandomHandCardId();
        room->obtainCard(from, id, false);
    }
}

class MobileYanShangyi : public OneCardViewAsSkill
{
public:
    MobileYanShangyi() : OneCardViewAsSkill("mobileyanshangyi")
    {
        filter_pattern = ".!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileYanShangyiCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileYanShangyiCard *c = new MobileYanShangyiCard();
        c->addSubcard(originalCard);
        return c;
    }
};

MobileYanPackage::MobileYanPackage()
    : Package("mobileyan")
{
    General *mobileyan_cuiyan = new General(this, "mobileyan_cuiyan", "wei", 3);
    mobileyan_cuiyan->addSkill(new MobileYanYajun);
    mobileyan_cuiyan->addSkill(new MobileYanZundi);

    General *mobileyan_zhangchangpu = new General(this, "mobileyan_zhangchangpu", "wei", 3, false);
    mobileyan_zhangchangpu->addSkill(new MobileYanDifei);
    mobileyan_zhangchangpu->addSkill(new MobileYanYanjiao);

    General *mobileyan_jiangwan = new General(this, "mobileyan_jiangwan", "shu", 3);
    mobileyan_jiangwan->addSkill(new MobileYanZhenting);
    mobileyan_jiangwan->addSkill(new MobileYanJincui);

    General *mobileyan_jiangqin = new General(this, "mobileyan_jiangqin", "wu", 4);
    mobileyan_jiangqin->addSkill(new MobileYanJianyi);
    mobileyan_jiangqin->addSkill(new MobileYanJianyiRecord);
    mobileyan_jiangqin->addSkill(new MobileYanShangyi);
    related_skills.insertMulti("mobileyanjianyi", "#mobileyanjianyi-record");

    addMetaObject<MobileYanYajunCard>();
    addMetaObject<MobileYanYajunPutCard>();
    addMetaObject<MobileYanZundiCard>();
    addMetaObject<MobileYanYanjiaoCard>();
    addMetaObject<MobileYanJincuiCard>();
    addMetaObject<MobileYanShangyiCard>();
}

ADD_PACKAGE(MobileYan)
