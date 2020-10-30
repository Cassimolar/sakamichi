#include "yinhu.h"
#include "skill.h"
#include "engine.h"
#include "client.h"
#include "god.h"
#include "standard.h"
#include "maneuvering.h"
#include "clientplayer.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "json.h"
#include "clientstruct.h"
#include "wind.h"

YHShecuoCard::YHShecuoCard()
{
}

void YHShecuoCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    QStringList choices;
    choices << "limit=" + to->objectName() << "shuffle=" + to->objectName();
    QString choice = room->askForChoice(from, "yhshecuo", choices.join("+"), QVariant::fromValue(to));
    if (choice.startsWith("limit"))
        room->setPlayerMark(to, "&yhshecuo1", 1);
    else
        room->setPlayerMark(to, "&yhshecuo2", 1);
}

class YHShecuoVS : public ZeroCardViewAsSkill
{
public:
    YHShecuoVS() : ZeroCardViewAsSkill("yhshecuo")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YHShecuoCard");
    }

    const Card *viewAs() const
    {
        return new YHShecuoCard;
    }
};

class YHShecuo : public TriggerSkill
{
public:
    YHShecuo() :TriggerSkill("yhshecuo")
    {
        events << EventPhaseChanging << EventPhaseStart;
        view_as_skill = new YHShecuoVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Discard || player->getMark("&yhshecuo2") <= 0) return false;
            room->setPlayerMark(player, "&yhshecuo2", 0);

            QString fulin = player->property("fulin_list").toString();
            if (fulin.isEmpty()) return false;
            QStringList fulins = fulin.split("+");
            QList<int> fulin_ids = StringList2IntList(fulins), hands = player->handCards(), ids;
            foreach (int id, fulin_ids) {
                if (hands.contains(id))
                    ids << id;
            }
            if (ids.isEmpty()) return false;

            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = player;
            log.arg = "yhshecuo";
            room->sendLog(log);
            room->broadcastSkillInvoke("yhshecuo");

            room->shuffleIntoDrawPile(player, ids, objectName(), false);
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setPlayerMark(player, "&yhshecuo1", 0);
        }
        return false;
    }
};

class YHShecuoliLimit : public CardLimitSkill
{
public:
    YHShecuoliLimit() : CardLimitSkill("#yhshecuo-limit")
    {
    }

    QString limitList(const Player *target) const
    {
        if (target->getPhase() != Player::NotActive && target->getMark("&yhshecuo1") > 0)
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->getPhase() != Player::NotActive && target->getMark("&yhshecuo1") > 0) {
            QStringList fulin_list = target->property("fulin_list").toString().split("+");
            QStringList patterns;
            foreach (const Card *card, target->getHandcards()) {
                QString str = card->toString();
                if (fulin_list.contains(str))
                    patterns << str;
            }
            return patterns.join(",");
        } else
            return QString();
    }
};

class YHYingfu : public TriggerSkill
{
public:
    YHYingfu() :TriggerSkill("yhyingfu")
    {
        events << CardsMoveOneTime << EventPhaseStart;
    }

    static QList<ServerPlayer *> getFuPlayers(ServerPlayer *player)
    {
        QList<ServerPlayer *> players;
        Room *room = player->getRoom();
        QString mark = "&yhyffu+#" + player->objectName();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark(mark) > 0)
                players << p;
        }
        return players;
    }

    bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const
    {
        QList<ServerPlayer *> fus = getFuPlayers(player);
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Start || !fus.isEmpty()) return false;
            ServerPlayer *fu = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@yhyingfu-invoke", true, true);
            if (!fu) return false;
            room->broadcastSkillInvoke(this);

            LogMessage log;
            log.type = "#GetMark";
            log.from = fu;
            log.arg = "yhyffu";
            log.arg2 = QString::number(1);
            room->sendLog(log);

            room->setPlayerMark(fu, "&yhyffu+#" + player->objectName(), 1);

            room->gainMaxHp(fu);
            QString kingdom = fu->getKingdom();
            if (player->getKingdom() != kingdom)
                room->setPlayerProperty(player, "kingdom", kingdom);
        } else {
            if (player->getPhase() == Player::NotActive || fus.isEmpty()) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to != player || move.to_place != Player::PlaceHand) return false;
            QList<int> hands = player->handCards(), ids;
            foreach (int id, move.card_ids) {
                if (hands.contains(id))
                    ids << id;
            }
            if (ids.isEmpty()) return false;

            room->sendCompulsoryTriggerLog(player, this);

            ServerPlayer *fu = NULL;
            if (fus.length() == 1)
                fu = fus.first();
            else
                fu = room->askForPlayerChosen(player, fus, "yhyingfu_give", "@yhyingfu-give");
            if (!fu) return false;
            room->doAnimate(1, player->objectName(), fu->objectName());
            room->giveCard(player, fu, ids, objectName());
        }
        return false;
    }
};

class YHNabi : public TriggerSkill
{
public:
    YHNabi() :TriggerSkill("yhnabi")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room* room, ServerPlayer *player, QVariant &data) const
    {
        QList<ServerPlayer *> fus = YHYingfu::getFuPlayers(player);
        if (fus.isEmpty()) return false;

        player->tag["YHNabiDamage"] = data;
        ServerPlayer *fu = room->askForPlayerChosen(player, fus, objectName(), "@yhnabi-invoke", true, true);
        player->tag.remove("YHNabiDamage");
        if (!fu) return false;
        room->broadcastSkillInvoke(this);

        DamageStruct damage = data.value<DamageStruct>();
        damage.to = fu;
        damage.transfer = true;
        damage.transfer_reason = "yhnabi";
        damage.tips << "yhnabi:" + player->objectName();
        player->tag["TransferDamage"] = QVariant::fromValue(damage);

        return true;
    }
};

class YHNabiTransfer : public TriggerSkill
{
public:
    YHNabiTransfer() :TriggerSkill("#yhnabi")
    {
        events << DamageComplete;
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room* room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.transfer || damage.transfer_reason != "yhnabi") return false;

        ServerPlayer *player = NULL;
        foreach (QString tip, damage.tips) {
            if (!tip.startsWith("yhnabi:")) continue;
            QStringList tips = tip.split(":");
            if (tips.length() != 2) return false;
            player = room->findChild<ServerPlayer *>(tips.last());
            break;
        }
        if (!player || player->isDead()) return false;

        JudgeStruct judge;
        judge.who = player;
        judge.reason = "yhnabi";
        judge.pattern = ".|heart";
        judge.good = false;
        room->judge(judge);

        if (judge.isBad() || player->isDead()) return true;

        QStringList choices;
        if (player->isWounded())
            choices << "recover";
        choices << "draw";

        QString choice = room->askForChoice(player, "yhnabi", choices.join("+"));
        if (choice == "recover")
            room->recover(player, RecoverStruct(player));
        else
            player->drawCards(2, "yhnabi");

        return false;
    }
};

class YHHuanglong : public PhaseChangeSkill
{
public:
    YHHuanglong() :PhaseChangeSkill("yhhuanglong")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        return player->getPhase() == Player::NotActive;
    }

    bool huanglongJudge(ServerPlayer *player, int type) const
    {
        Room *room = player->getRoom();
        if (type == 1) {
            int hp = player->getHp();
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHp() >= hp)
                    return false;
            }
        } else {
            int hand = player->getHandcardNum();
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHandcardNum() >= hand)
                    return false;
            }
        }
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || p->getMark(objectName()) > 0) continue;
            if (p->canWake(objectName()) || huanglongJudge(p, 1) || huanglongJudge(p, 2)) {
                room->sendCompulsoryTriggerLog(p, this);
                room->doSuperLightbox("yh_sunquan", "yhhuanglong");
                room->setPlayerMark(p, "yhhuanglong", 1);
                if (room->changeMaxHpForAwakenSkill(p, 0)) {
                    QList<ServerPlayer *> fus = YHYingfu::getFuPlayers(p);
                    foreach (ServerPlayer *fu, fus) {
                        if (fu->isDead()) continue;
                        LogMessage log;
                        log.type = "#LoseMark";
                        log.from = fu;
                        log.arg = "yhyffu";
                        log.arg2 = QString::number(1);
                        room->sendLog(log);
                        room->setPlayerMark(fu, "&yhyffu+#" + p->objectName(), 0);
                        room->loseMaxHp(fu);
                    }
                    if (p->getKingdom() != "wu")
                        room->setPlayerProperty(p, "kingdom", "wu");
                    room->handleAcquireDetachSkills(p, "-yhyingfu|-yhnabi|tenyearzhiheng");
                    p->gainAnExtraTurn();
                }
            }
        }
        return false;
    }
};

YHYijieCard::YHYijieCard()
{
    will_throw = false;
    handling_method = Card::MethodUse;
    mute = true;
}

bool YHYijieCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    GodSalvation *gs = new GodSalvation(Card::SuitToBeDecided, -1);
    gs->addSubcards(subcards);
    gs->setSkillName("yhyijie");
    gs->deleteLater();

    return !Self->isLocked(gs) && targets.isEmpty() && !Self->isProhibited(to_select, gs, targets);
}

void YHYijieCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->addPlayerHistory(card_use.from, "YHYijieCard");

    GodSalvation *gs = new GodSalvation(Card::SuitToBeDecided, -1);
    gs->addSubcards(subcards);
    gs->setSkillName("yhyijie");
    gs->deleteLater();

    if (card_use.from->isLocked(gs)) return;

    foreach (ServerPlayer *p, card_use.to)
        room->addPlayerMark(p, "yhyijie_target-PlayClear");
    room->useCard(CardUseStruct(gs, card_use.from, card_use.to), true);

    QList<ServerPlayer *> targets;
    targets << card_use.from << card_use.to;
    room->sortByActionOrder(targets);
    room->drawCards(targets, 1, "yhyijie");
}

class YHYijieVS : public OneCardViewAsSkill
{
public:
    YHYijieVS() : OneCardViewAsSkill("yhyijie")
    {
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        if (to_select->isEquipped() || to_select->getSuit() != Card::Heart) return false;
        GodSalvation *gs = new GodSalvation(Card::SuitToBeDecided, -1);
        gs->addSubcard(to_select);
        gs->setSkillName("yhyijie");
        gs->deleteLater();
        return !Self->isLocked(gs);
    }

    const Card *viewAs(const Card *card) const
    {
        YHYijieCard *c = new YHYijieCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YHYijieCard");
    }
};

class YHYijie : public TriggerSkill
{
public:
    YHYijie() : TriggerSkill("yhyijie")
    {
        events << PreCardUsed;
        view_as_skill = new YHYijieVS;
    }

    int getPriority(TriggerEvent) const
    {
        return 7;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("GodSalvation") || use.card->getSkillName() != objectName()) return false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark("yhyijie_target-PlayClear") > 0) {
                room->setPlayerMark(p, "yhyijie_target-PlayClear", 0);
                targets << p;
            }
        }
        if (targets.isEmpty()) return false;
        room->sortByActionOrder(targets);
        use.to = targets;
        data = QVariant::fromValue(use);
        return false;
    }
};

class YHXinghanVS : public OneCardViewAsSkill
{
public:
    YHXinghanVS() : OneCardViewAsSkill("yhxinghan")
    {
        response_or_use = true;
        filter_pattern = "^BasicCard";
        change_skill = true;
    }

    const Card *viewAs(const Card *card) const
    {
        Slash *slash = new Slash(card->getSuit(), card->getNumber());
        slash->addSubcard(card);
        slash->setSkillName(objectName());
        return slash;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player) && player->getPhase() == Player::Play && player->getMark("yhxinghan-PlayClear") == 1;
    }
};

class YHXinghan : public PhaseChangeSkill
{
public:
    YHXinghan() : PhaseChangeSkill("yhxinghan")
    {
        view_as_skill = new YHXinghanVS;
        change_skill = true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play || player->getHandcardNum() < 2) return false;
        Room *room = player->getRoom();
        int state = player->getChangeSkillState(objectName());

        int n = 0;
        bool optional = true, notify = true;
        QString prompt = "@yhxinghan-give";
        QHash<ServerPlayer *, QStringList> hash;
        QList<int> hands = player->handCards();

        while (n < 2) {
            if (hands.isEmpty()) break;
            if (n != 0) {
                optional = false;
                notify = false;
                prompt = "@yhxinghan-give2";
            }

            CardsMoveStruct move = room->askForYijiStruct(player, hands, objectName(), false, false, optional, 2 - n, QList<ServerPlayer *>(),
                                                          CardMoveReason(), prompt, notify, false);
            if (!move.to || move.card_ids.isEmpty()) break;
            n += move.card_ids.length();

            ServerPlayer *to = (ServerPlayer *)move.to;
            QStringList ids = hash[to];
            foreach (int id, move.card_ids) {
                QString str = QString::number(id);
                hands.removeOne(id);
                if (!ids.contains(str))
                    ids << str;
            }
            hash[to] = ids;
        }

        QList<CardsMoveStruct> moves;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead()) continue;
            QList<int> ids = StringList2IntList(hash[p]);
            if (ids.isEmpty()) continue;
            CardsMoveStruct move(ids, player, p, Player::PlaceHand, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_GIVE, player->objectName(), p->objectName(), objectName(), QString()));
            moves.append(move);
        }
        if (moves.isEmpty()) return false;
        room->moveCardsAtomic(moves, false);

        room->setPlayerMark(player, "yhxinghan-PlayClear", state);
        room->setChangeSkillState(player, objectName(), state == 1 ? 2 : 1);
        return false;
    }
};

class YHXinghanDraw : public TriggerSkill
{
public:
    YHXinghanDraw() : TriggerSkill("#yhxinghan-draw")
    {
        events << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("yhxinghan-PlayClear") > 0 && target->getPhase() == Player::Play;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, "yhxinghan", true, true);
        player->drawCards(2, "yhxinghan");
        return false;
    }
};

class YHXinghanTarget : public TargetModSkill
{
public:
    YHXinghanTarget() : TargetModSkill("#yhxinghan-target")
    {
        frequency = NotFrequent;
        change_skill = true;
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("yhxinghan-PlayClear") == 2 && from->getPhase() == Player::Play)
            return 1000;
        else
            return 0;
    }
};

YHZhushiCard::YHZhushiCard()
{
    will_throw = false;
    mute = true;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void YHZhushiCard::onUse(Room *, const CardUseStruct &) const
{
}

class YHZhushiVS : public ViewAsSkill
{
public:
    YHZhushiVS() : ViewAsSkill("yhzhushi")
    {
        response_pattern = "@@yhzhushi!";
        expand_pile = "yhzsshi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (!Self->getPile("yhzsshi").contains(to_select->getEffectiveId())) return false;
        int type = to_select->getTypeId();
        foreach (const Card *card, selected) {
            if (card->getTypeId() == type)
                return false;
        }
        return true;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        YHZhushiCard *card = new YHZhushiCard;
        card->addSubcards(cards);
        return card;
    }
};

class YHZhushi : public PhaseChangeSkill
{
public:
    YHZhushi() : PhaseChangeSkill("yhzhushi")
    {
        frequency = Compulsory;
        view_as_skill = new YHZhushiVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        QList<int> shi = player->getPile("yhzsshi");
        if (shi.isEmpty()) return false;

        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);

        const Card *card = room->askForUseCard(player, "@@yhzhushi!", "@yhzhushi", -1, Card::MethodNone);
        QList<int> get;
        if (card)
            get = card->getSubcards();
        else {
            int id = shi.at(qrand() % shi.length());
            get << id;
        }

        LogMessage log;
        log.type = "$KuangbiGet";
        log.from = player;
        log.arg = "yhzsshi";
        log.card_str = IntList2StringList(get).join("+");
        room->sendLog(log);

        DummyCard *dummy = new DummyCard(get);
        dummy->deleteLater();

        player->obtainCard(dummy);
        foreach (int id, get)
            shi.removeOne(id);
        if (shi.isEmpty()) return false;

        DummyCard *dummy2 = new DummyCard(shi);
        dummy2->deleteLater();
        CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), "yhzhushi", QString());
        room->moveCardTo(dummy2, NULL, Player::DrawPile, reason, true);
        return false;
    }
};

class YHZhushiPut : public PhaseChangeSkill
{
public:
    YHZhushiPut() : PhaseChangeSkill("#yhzhushi")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && !target->isNude() && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead() || player->isNude()) return false;
            if (p->isDead() || !p->hasSkill("yhzhushi")) continue;
            room->sendCompulsoryTriggerLog(p, "yhzhushi", true, true);

            int num = 1;
            if (p->getMark("yhshijin") > 0) {
                int card_num = player->getCardCount();
                card_num = qMin(card_num, 2) + 1;
                QStringList choices;
                for (int i = 0; i < card_num; i++)
                    choices << QString::number(i) + "=" + player->objectName();
                QString choice = room->askForChoice(p, "yhzhushi", choices.join("+"), QVariant::fromValue(player));
                num = choice.split("=").first().toInt();
            }

            if (num <= 0) continue;

            QString prompt = "@yhzsshi-put:" + p->objectName() + "::" + QString::number(num);
            const Card *card = room->askForExchange(player, "yhzhushi", num, num, true, prompt);
            int length = card->subcardsLength();
            p->addToPile("yhzsshi", card);
            delete card;
            player->drawCards(length, "yhzhushi");
        }
        return false;
    }
};

class YHShijin : public PhaseChangeSkill
{
public:
    YHShijin() : PhaseChangeSkill("yhshijin")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        QStringList kingdoms;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            QString kingdom = p->getKingdom();
            if (kingdoms.contains(kingdom)) continue;
            kingdoms << kingdom;
        }
        if (kingdoms.length() > 2) return false;
        room->sendCompulsoryTriggerLog(player, this);
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->doSuperLightbox("yh_chenshou", "yhshijin");
        room->setPlayerMark(player, "yhshijin", 1);
        if (room->changeMaxHpForAwakenSkill(player, 1))
            room->changeTranslation(player, "yhzhushi", 1);
        return false;
    }
};

YHBianzhanCard::YHBianzhanCard()
{
}

bool YHBianzhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select) && to_select->getHandcardNum() > Self->getHandcardNum();
}

void YHBianzhanCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;


    PindianStruct *pindian = from->PinDian(to, "yhbianzhan");
    if (!pindian->success) return;

    from->drawCards(2, "yhbianzhan");
    Room *room = from->getRoom();
    if (room->getCardPlace(pindian->from_card->getEffectiveId()) != Player::DiscardPile) return;

    LogMessage log;
    log.type = "$PutCard2";
    log.from = from;
    log.card_str = pindian->from_card->toString();
    room->sendLog(log);

    CardMoveReason reason(CardMoveReason::S_REASON_PUT, from->objectName(), "yhbianzhan", QString());
    room->moveCardTo(pindian->from_card, NULL, Player::DrawPile, reason, true);
}

class YHBianzhan : public ZeroCardViewAsSkill
{
public:
    YHBianzhan() : ZeroCardViewAsSkill("yhbianzhan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canPindian();
    }

    const Card *viewAs() const
    {
        return new YHBianzhanCard;
    }
};

class YHJifeng : public TriggerSkill
{
public:
    YHJifeng() : TriggerSkill("yhjifeng")
    {
        events << EventPhaseEnd;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getMark(objectName()) > 0 || player->getPhase() != Player::Play) return false;
        if (!player->canDiscard(player, "he")) return false;
        if (!room->askForDiscard(player, objectName(), 2, 2, true, true, "@yhjifeng-discard", ".", objectName())) return false;
        room->broadcastSkillInvoke(this, 1);

        QList<int> ids = room->showDrawPile(player, 1, objectName());
        if (player->isDead()) {
            DummyCard *dummy = new DummyCard(ids);
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "yhjifeng", QString());
            room->throwCard(dummy, reason, NULL);
            delete dummy;
            return false;
        }

        int id = ids.first();
        room->obtainCard(player, id);

        const Card *card = Sanguosha->getCard(id);

        Card::Suit suit = card->getSuit();
        if (suit == Card::Diamond) {
            room->sendShimingLog(player, objectName());
            room->acquireSkill(player, "olhuoji");
            if (player->isDead()) return false;
            int number = card->getNumber();
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@yhjifeng-target:" + QString::number(number));
            room->addPlayerMark(target, "&yhjfkuangfeng", number);
        } else if (suit == Card::Spade) {
            room->sendShimingLog(player, objectName(), false);
            room->acquireSkill(player, "bazhen");
            player->throwAllHandCards();
        }
        return false;
    }
};

class YHJifengEffect : public TriggerSkill
{
public:
    YHJifengEffect() : TriggerSkill("#yhjifeng")
    {
        events << EventPhaseChanging << DamageForseen;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                int mark = p->getMark("&yhjfkuangfeng");
                if (mark <= 0) continue;
                room->removePlayerMark(p, "&yhjfkuangfeng");
            }
        } else {
            if (player->isDead() || player->getMark("&yhjfkuangfeng") <= 0) return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature == DamageStruct::Fire) {
                LogMessage log;
                log.type = "#GalePower";
                log.from = player;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(++damage.damage);
                room->sendLog(log);
                data = QVariant::fromValue(damage);
            }
        }
        return false;
    }
};

YHHuntianCard::YHHuntianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    target_fixed = true;
}

void YHHuntianCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_PUT, source->objectName(), "yhhuntian", QString());
    room->moveCardTo(this, NULL, Player::DrawPile, reason, false, true);

    if (source->isAlive() && source->askForSkillInvoke("yhhuntian", "yhhuntian", false)) {
        QList<int> card_ids = room->showDrawPile(source, 4, "yhhuntian");

        if (source->isDead()) {
            DummyCard *dummy = new DummyCard(card_ids);
            CardMoveReason reason2(CardMoveReason::S_REASON_NATURAL_ENTER, source->objectName(), "yhhuntian", QString());
            room->throwCard(dummy, reason2, NULL);
            delete dummy;
            return;
        }

        room->fillAG(card_ids);

        QList<int> to_get, to_throw;
        while (!card_ids.isEmpty()) {
            int card_id = room->askForAG(source, card_ids, false, "yhhuntian");
            card_ids.removeOne(card_id);
            to_get << card_id;
            // throw the rest cards that matches the same suit
            const Card *card = Sanguosha->getCard(card_id);
            Card::Suit suit = card->getSuit();

            room->takeAG(source, card_id, false);

            QList<int> _card_ids = card_ids;
            foreach (int id, _card_ids) {
                const Card *c = Sanguosha->getCard(id);
                if (c->getSuit() == suit) {
                    card_ids.removeOne(id);
                    room->takeAG(NULL, id, false);
                    to_throw.append(id);
                }
            }
        }

        room->clearAG();

        DummyCard *dummy = new DummyCard;
        if (!to_get.isEmpty()) {
            dummy->addSubcards(to_get);
            source->obtainCard(dummy);
        }
        dummy->clearSubcards();

        if (!to_throw.isEmpty()) {
            room->fillAG(to_throw, source);
            QString choice = room->askForChoice(source, "yhhuntian", "enter+put", IntList2VariantList(to_throw));
            room->clearAG(source);
            dummy->addSubcards(to_throw);
            if (choice == "enter") {
                CardMoveReason reason2(CardMoveReason::S_REASON_NATURAL_ENTER, source->objectName(), "yhhuntian", QString());
                room->throwCard(dummy, reason2, NULL);
            } else {
                LogMessage log;
                log.type = "$PutCard2";
                log.from = source;
                log.card_str = IntList2StringList(dummy->getSubcards()).join("+");
                room->sendLog(log);
                CardMoveReason reason2(CardMoveReason::S_REASON_PUT, source->objectName(), "yhhuntian", QString());
                room->moveCardTo(dummy, NULL, Player::DrawPile, reason2, true, true);
            }
        }
        delete dummy;
    }
}

class YHHuntian : public ViewAsSkill
{
public:
    YHHuntian() : ViewAsSkill("yhhuntian")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        return selected.length() < 4;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YHHuntianCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        YHHuntianCard *card = new YHHuntianCard;
        card->addSubcards(cards);
        return card;
    }
};

class YHCeri : public PhaseChangeSkill
{
public:
    YHCeri() : PhaseChangeSkill("yhceri")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        int hand = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHandcardNum() < hand)
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@yhceri-invoke", true, true);
        if (!t) return false;
        room->broadcastSkillInvoke(this);

        int n = t->getHandcardNum();

        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p != player && p != t) {
                JsonArray arr;
                arr << player->objectName() << t->objectName();
                room->doNotify(p, QSanProtocol::S_COMMAND_EXCHANGE_KNOWN_CARDS, arr);
            }
        }
        QList<CardsMoveStruct> exchangeMove;
        CardsMoveStruct move1(player->handCards(), t, Player::PlaceHand,
            CardMoveReason(CardMoveReason::S_REASON_SWAP, player->objectName(), t->objectName(), "yhceri", QString()));
        CardsMoveStruct move2(t->handCards(), player, Player::PlaceHand,
            CardMoveReason(CardMoveReason::S_REASON_SWAP, t->objectName(), player->objectName(), "yhceri", QString()));
        exchangeMove.push_back(move1);
        exchangeMove.push_back(move2);
        room->moveCardsAtomic(exchangeMove, false);

        LogMessage log;
        log.type = "#Dimeng";
        log.from = player;
        log.to << t;
        log.arg = QString::number(hand);
        log.arg2 = QString::number(n);
        room->sendLog(log);
        room->getThread()->delay();

        if (t->isDead()) return false;

        QString choice = room->askForChoice(t, objectName(), "3,4,5+6,8,10+5,12,13", QVariant::fromValue(player));

        log.type = "#FumianFirstChoice";
        log.from = t;
        log.arg = "yhceri:" + choice;
        room->sendLog(log);

        QStringList choices = choice.split(",");
        int num1 = choices.first().toInt(), num2 = choices.at(1).toInt(), num3 = choices.last().toInt();
        QList<int> nums1, nums2, nums3;
        foreach (int id, room->getDiscardPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (card->getNumber() == num1)
                nums1 << id;
            else if (card->getNumber() == num2)
                nums2 << id;
            else if (card->getNumber() == num3)
                nums3 << id;
        }

        if (nums1.isEmpty() || nums2.isEmpty() || nums3.isEmpty()) {
            if (player->isDead()) return false;
            room->damage(DamageStruct(objectName(), t->isAlive() ? t : NULL, player));
        } else {
            if (t->isDead()) return false;
            DummyCard *dummy = new DummyCard;
            dummy->deleteLater();
            num1 = nums1.at(qrand() % nums1.length());
            num2 = nums2.at(qrand() % nums2.length());
            num3 = nums3.at(qrand() % nums3.length());
            dummy->addSubcard(num1);
            dummy->addSubcard(num2);
            dummy->addSubcard(num3);
            room->obtainCard(t, dummy);
        }
        return false;
    }
};

class YHSancai : public PhaseChangeSkill
{
public:
    YHSancai() : PhaseChangeSkill("yhsancai")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play || !player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(this);

        player->drawCards(1, objectName());

        QList<ServerPlayer *> targets = room->getOtherPlayers(player);
        QHash<ServerPlayer *, int> hash;
        QList<int> hands = player->handCards();
        while (!hands.isEmpty()) {
            if (player->isDead()) return false;
            if (targets.isEmpty() || player->isKongcheng()) break;

            CardsMoveStruct move = room->askForYijiStruct(player, hands, objectName(), false, false, true, 1, targets,
                                                                 CardMoveReason(), "@yhsancai-give", false, false);
            if (!move.to || move.card_ids.isEmpty()) break;
            ServerPlayer *to = (ServerPlayer *)move.to;
            int id = move.card_ids.first();
            hash[to] = id + 1;
            hands.removeOne(id);
            targets.removeOne(to);
            room->setPlayerFlag(to, "yhsancai_give"); //for AI
        }

        foreach (ServerPlayer *p, room->getAllPlayers(true))
            room->setPlayerFlag(p, "-yhsancai_give");

        QList<CardsMoveStruct> moves;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead()) continue;
            int id = hash[p] - 1;
            if (id < 0) continue;
            CardsMoveStruct move(QList<int>() << id, player, p, Player::PlaceHand, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_GIVE, player->objectName(), p->objectName(), objectName(), QString()));
            moves.append(move);
        }
        if (moves.isEmpty()) return false;
        room->moveCardsAtomic(moves, false);

        room->addPlayerMark(player, "&yhsancai-PlayClear", moves.length());
        return false;
    }
};

class YHSancaiAttackRange : public AttackRangeSkill
{
public:
    YHSancaiAttackRange() : AttackRangeSkill("#yhsancai")
    {
        frequency = Frequent;
    }

    int getExtra(const Player *target, bool) const
    {
        if (target->getPhase() == Player::Play)
            return qMax(0, target->getMark("&yhsancai-PlayClear"));
        return 0;
    }
};

class YHJuyi : public TriggerSkill
{
public:
    YHJuyi() : TriggerSkill("yhjuyi")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player || move.to == player || !move.to) return false;
        if (!move.from_places.contains(Player::PlaceHand) || move.to_place != Player::PlaceHand) return false;
        room->sendCompulsoryTriggerLog(player, this);

        ServerPlayer *to = (ServerPlayer *)move.to, *from = (ServerPlayer *)move.from;
        if (to->canDiscard(to, "he") && room->askForDiscard(to, objectName(), 1, 1, true, true, "@yhjuyi-discard:" + from->objectName())) return false;
        from->drawCards(1, objectName());
        if (from->isAlive() && room->hasCurrent()) {
            room->addSlashCishu(from, 1);
            room->addPlayerMark(from, "&yhjuyi-Clear");
        }
        return false;
    }
};

class YHHanjie : public TriggerSkill
{
public:
    YHHanjie() : TriggerSkill("yhhanjie")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || !use.to.contains(player)) return false;
        if (use.card->isVirtualCard() || !room->CardInTable(use.card)) return false;
        if (!player->askForSkillInvoke(this, data)) return false;
        room->broadcastSkillInvoke(this);
        room->obtainCard(player, use.card);
        if (player->isCardLimited(use.card, Card::MethodPindian, true) || !player->handCards().contains(use.card->getEffectiveId())) return false;
        if (!player->canPindian(use.from, false)) return false;

        PindianStruct *pindian = player->PinDian(use.from, objectName(), use.card);

        if (pindian->success) {
            use.nullified_list << player->objectName();
            data = QVariant::fromValue(use);
            room->damage(DamageStruct(objectName(), player, use.from));
        } else {
            use.no_respond_list << player->objectName();
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

YHJuxianCard::YHJuxianCard()
{
    target_fixed = true;
}

void YHJuxianCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> drawpile = room->getDrawPile();
    if (drawpile.isEmpty()) return;

    QList<int> _drawpile;
    foreach (int id, drawpile)
        _drawpile << id;

    QList<int> all_cards = room->getNCards(drawpile.length(), false);
    while (!all_cards.isEmpty()) {
        int id = all_cards.at(qrand() % all_cards.length());
        room->returnToTopDrawPile(QList<int>() << id);
        all_cards.removeOne(id);
    }
    drawpile = room->getDrawPile();

    QList<int> ids;

    for (int i = 0; i < drawpile.length(); i++) {
        if (i > _drawpile.length()) break;
        if (_drawpile.at(i) == drawpile.at(i))
            ids << drawpile.at(i);
    }
    if (ids.isEmpty()) return;

    source->tag["YHJuxianIDS"] = IntList2VariantList(ids);  //for AI

    QList<ServerPlayer *> targets = room->getOtherPlayers(source);
    ServerPlayer *geter = NULL;
    room->fillAG(ids, source);

    if (targets.length() == 1) {
        room->askForAG(source, ids, true, "yhjuxian");
        geter = targets.first();
    } else
        geter = room->askForPlayerChosen(source, targets, "yhjuxian", "@yhjuxian-invoke");

    source->tag.remove("YHJuxianIDS");
    room->clearAG(source);

    if (geter) {
        room->doAnimate(1, source->objectName(), geter->objectName());
        DummyCard *dummy = new DummyCard(ids);
        dummy->deleteLater();
        CardMoveReason reason(CardMoveReason::S_REASON_PREVIEWGIVE, source->objectName(), geter->objectName(), "yhjuxian", QString());
        room->obtainCard(geter, dummy, reason, false);
    }
}

class YHJuxian : public ZeroCardViewAsSkill
{
public:
    YHJuxian() : ZeroCardViewAsSkill("yhjuxian")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("YHJuxianCard") < 2;
    }

    const Card *viewAs() const
    {
        return new YHJuxianCard;
    }
};

class YHDujian : public TriggerSkill
{
public:
    YHDujian() : TriggerSkill("yhdujian")
    {
        events << TargetSpecified;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || use.to.length() < 2) return false;
        if (!room->CardInTable(use.card)) return false;
        QList<ServerPlayer *> targets = use.to;
        targets.removeOne(player);
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@yhdujian-give", false, true);
        room->broadcastSkillInvoke(this);
        room->giveCard(player, target, use.card, objectName(), true);
        use.nullified_list << target->objectName();
        data = QVariant::fromValue(use);
        return false;
    }
};

class YHDujianTarget : public TargetModSkill
{
public:
    YHDujianTarget() : TargetModSkill("#yhdujian")
    {
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("yhdujian"))
            return 1000;
        else
            return 0;
    }
};

YHBuquePutCard::YHBuquePutCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "yhbuque_put";
    mute = true;
}

bool YHBuquePutCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getMark("yhbuque_put-PlayClear") <= 0 && to_select->hasSkill("yhbuque");
}

void YHBuquePutCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.first();
    room->addPlayerMark(target, "yhbuque_put-PlayClear");

    int num = qMin(3, room->getDrawPile().length());
    QStringList choices;
    for (int i = 0; i < num; i++)
        choices << QString::number(i + 1);
    if (choices.isEmpty()) return;

    QString choice = room->askForChoice(source, "yhbuque_put", choices.join("+"), QVariant::fromValue(target));
    num = choice.toInt();
    room->moveCardsInToDrawpile(source, subcards, "yhbuque_put", num, true);
}

class YHBuquePutVS : public OneCardViewAsSkill
{
public:
    YHBuquePutVS() : OneCardViewAsSkill("yhbuque_put")
    {
        filter_pattern = ".";
        attached_lord_skill = true;
    }

    const Card *viewAs(const Card *card) const
    {
        YHBuquePutCard *c = new YHBuquePutCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YHYijieCard");
    }
};

class YHBuquePut : public TriggerSkill
{
public:
    YHBuquePut() : TriggerSkill("yhbuque_put")
    {
        events << CardsMoveOneTime;
        view_as_skill = new YHBuquePutVS;
        attached_lord_skill = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 4;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DrawPile || move.reason.m_skillName != objectName()) return false;
        QVariantList list = room->getTag("YHBuqueCards").toList();
        foreach (int id, move.card_ids) {
            if (list.contains(QVariant(id))) continue;
            if (room->getCardPlace(id) != Player::DrawPile) continue;
            list << id;
        }
        room->setTag("YHBuqueCards", list);
        return false;
    }
};


YHBuqueCard::YHBuqueCard()
{
    mute = true;
}

bool YHBuqueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    return false;
}

bool YHBuqueCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    }

    return true;
}

const Card *YHBuqueCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    Room *room = source->getRoom();

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = source;
    log.arg = "yhbuque";
    room->sendLog(log);
    room->notifySkillInvoked(source, "yhbuque");
    room->broadcastSkillInvoke("yhbuque");

    QString tl = user_string;
    if ((user_string.contains("slash") || user_string.contains("Slash")))
        tl = "slash";

    QVariantList list = room->getTag("YHBuqueCards").toList();
    if (list.isEmpty()) {
        room->setPlayerFlag(source, "Global_YHBuqueFailed");
        return NULL;
    }
    QList<int> ids = VariantList2IntList(list);

    QList<int> disable_ids, enable_ids;
    foreach (int id, ids) {
        const Card *card = Sanguosha->getCard(id);
        if ((tl.isEmpty() && card->isAvailable(source)) || (!tl.isEmpty() && card->sameNameWith(tl)))
            enable_ids << id;
        else
            disable_ids << id;
    }

    if (enable_ids.isEmpty()) {
        JsonArray arg;
        arg << "." << false << JsonUtils::toJsonArray(ids);
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_SHOW_ALL_CARDS, arg);

        room->setPlayerFlag(source, "Global_YHBuqueFailed");
        return NULL;
    }

    room->fillAG(ids, source, disable_ids);
    int id = room->askForAG(source, enable_ids, false, "yhbuque");
    room->clearAG();

    const Card *card = Sanguosha->getCard(id);
    if (!tl.isEmpty() && !card->sameNameWith(tl)) return NULL;

    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
        room->setPlayerMark(source, "buqueCard", id + 1);
        if (!room->askForUseCard(source, "@@yhbuque", "@yhbuque:" + card->objectName()))
            room->setPlayerFlag(source, "Global_YHBuqueFailed");
        return NULL;
    } else
        return card;
    return NULL;
}

const Card *YHBuqueCard::validateInResponse(ServerPlayer *source) const
{
    Room *room = source->getRoom();

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = source;
    log.arg = "yhbuque";
    room->sendLog(log);
    room->notifySkillInvoked(source, "yhbuque");
    room->broadcastSkillInvoke("yhbuque");

    QString tl;
    if (user_string == "peach+analeptic")
        tl = "analeptic";
    else if ((user_string.contains("slash") || user_string.contains("Slash")))
        tl = "slash";
    else
        tl = user_string;

    QVariantList list = room->getTag("YHBuqueCards").toList();
    if (list.isEmpty()) {
        room->setPlayerFlag(source, "Global_YHBuqueFailed");
        return NULL;
    }
    QList<int> ids = VariantList2IntList(list);

    QList<int> disable_ids, enable_ids;
    foreach (int id, ids) {
        const Card *card = Sanguosha->getCard(id);
        if (card->sameNameWith(tl)) {
            enable_ids << id;
            continue;
        }
        if (tl == "analeptic" && card->isKindOf("Peach")) {
            enable_ids << id;
            continue;
        }
        disable_ids << id;
    }

    if (enable_ids.isEmpty()) {
        JsonArray arg;
        arg << "." << false << JsonUtils::toJsonArray(ids);
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_SHOW_ALL_CARDS, arg);

        room->setPlayerFlag(source, "Global_YHBuqueFailed");
        return NULL;
    }

    room->fillAG(ids, NULL, disable_ids);
    int id = room->askForAG(source, enable_ids, true, "yhbuque");
    room->clearAG();

    const Card *card = Sanguosha->getCard(id);
    if (card->sameNameWith(tl) || (tl == "analeptic" && card->isKindOf("Peach")))
        return card;

    return NULL;
}

class YHBuqueVS : public ZeroCardViewAsSkill
{
public:
    YHBuqueVS() : ZeroCardViewAsSkill("yhbuque")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasFlag("Global_YHBuqueFailed");
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        return !player->hasFlag("Global_YHBuqueFailed");
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (pattern == "@@yhbuque") return true;
        if (player->hasFlag("Global_YHBuqueFailed")) return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;
        if (pattern == "nullification") return true;

        bool basic = false;
        QStringList patterns = pattern.split("+");
        foreach (QString name, patterns) {
            name = name.toLower();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            if (card->isKindOf("BasicCard"))
                basic = true;
        }
        if (!basic) {
            patterns = pattern.split(",");
            foreach (QString name, patterns) {
                name = name.toLower();
                Card *card = Sanguosha->cloneCard(name);
                if (!card) continue;
                card->deleteLater();
                if (card->isKindOf("BasicCard"))
                    basic = true;
            }
        }
        return basic;
    }

    const Card *viewAs() const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE ||
                Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
            QString pattern = Sanguosha->getCurrentCardUsePattern();
            if (pattern == "@@yhbuque") {
                int id = Self->getMark("buqueCard") - 1;
                if (id < 0) return NULL;
                return Sanguosha->getCard(id);
            } else {
                YHBuqueCard *card = new YHBuqueCard;
                card->setUserString(Sanguosha->getCurrentCardUsePattern());
                return card;
            }
        }
        YHBuqueCard *card = new YHBuqueCard;
        return card;
    }
};

class YHBuque : public TriggerSkill
{
public:
    YHBuque() : TriggerSkill("yhbuque")
    {
        events << GameStart << EventAcquireSkill;
        view_as_skill = new YHBuqueVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == EventAcquireSkill && data.toString() != objectName()) return false;
        const Skill *sk = Sanguosha->getSkill("yhbuque_put");
        if (!sk) return false;
        const TriggerSkill *trigger_skill = qobject_cast<const TriggerSkill *>(sk);
        if (!trigger_skill) return false;
        room->getThread()->addTriggerSkill(trigger_skill);
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->hasSkill("yhbuque_put", true)) continue;
            room->attachSkillToPlayer(p, "yhbuque_put");
        }
        return false;
    }
};

class YHBuquePindian : public TriggerSkill
{
public:
    YHBuquePindian() : TriggerSkill("#yhbuque")
    {
        events << AskforPindianCard;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        QVariantList list = room->getTag("YHBuqueCards").toList();
        if (list.isEmpty()) return false;
        QList<int> ids = VariantList2IntList(list);

        PindianStruct *pindian = data.value<PindianStruct *>();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead()) continue;
            if (pindian->from != p && pindian->to != p) continue;
            if (!p->hasSkill("yhbuque")) continue;
            if (pindian->from == p) {
                if (pindian->from_card) continue;
                room->fillAG(ids, p);
                bool invoke = p->askForSkillInvoke("yhbuque", data);
                room->clearAG(p);
                if (!invoke) continue;
                room->broadcastSkillInvoke("yhbuque");
                room->fillAG(ids, p);
                int id = room->askForAG(p, ids, false, "yhbuque");
                room->clearAG(p);
                pindian->from_card = Sanguosha->getCard(id);
            } else if (pindian->to == p) {
                if (pindian->to_card) continue;
                room->fillAG(ids, p);
                bool invoke = p->askForSkillInvoke("yhbuque", data);
                room->clearAG(p);
                if (!invoke) continue;
                room->broadcastSkillInvoke("yhbuque");
                room->fillAG(ids, p);
                int id = room->askForAG(p, ids, false, "yhbuque");
                room->clearAG(p);
                pindian->to_card = Sanguosha->getCard(id);
            }
        }
        return false;
    }
};

class YHChenzhen : public TriggerSkill
{
public:
    YHChenzhen() : TriggerSkill("yhchenzhen")
    {
        events << StartJudge << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setTag("YHChenzhenJudge", false);
        } else {
            if (!room->hasCurrent() || room->getTag("YHChenzhenJudge").toBool()) return false;
            room->setTag("YHChenzhenJudge", true);

            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (room->getDrawPile().isEmpty()) return false;
                if (p->isDead() || !p->hasSkill(this)) continue;
                if (!p->askForSkillInvoke(this)) continue;
                room->broadcastSkillInvoke(this);

                QStringList choices;
                if (p->getMaxCards() > 0)
                    choices << "maxcard";
                if (p->getMaxHp() > 0)
                    choices << "maxhp";
                QString choice = room->askForChoice(p, objectName(), choices.join("+"));
                if (choice == "maxcard")
                    room->addMaxCards(p, -2, false);
                else
                    room->loseMaxHp(p, 2);

                if (p->isDead()) continue;

                int num = qMin(9, room->getDrawPile().length());
                if (num <= 0) continue;

                choices.clear();
                for (int i = 0; i < num; i++)
                    choices << QString::number(i + 1);

                choice = room->askForChoice(p, "yhchenzhen_num", choices.join("+"));
                num = choice.toInt();

                QVariantList list = room->getTag("YHBuqueCards").toList();
                QList<int> cards = room->getNCards(num, false);
                room->returnToTopDrawPile(cards);

                QStringList ups, downs;

                foreach (int id, cards) {
                    QVariant _id = QVariant(id);
                    if (list.contains(_id)) {
                        list.removeOne(id);
                        downs << QString::number(id);
                    } else {
                        list << id;
                        ups << QString::number(id);
                    }
                }
                room->setTag("YHBuqueCards", list);

                LogMessage log;
                log.from = p;
                if (!ups.isEmpty()) {
                    log.type = "$YHChenzhenUp";
                    log.card_str = ups.join("+");
                    room->sendLog(log);
                }
                if (!downs.isEmpty()) {
                    log.type = "$YHChenzhenDown";
                    log.card_str = downs.join("+");
                    room->sendLog(log);
                }
            }
        }
        return false;
    }
};

class YHZhanghua : public TriggerSkill
{
public:
    YHZhanghua(const QString &skill) : TriggerSkill("#" + skill + "-move"), skill(skill)
    {
        events << CardsMoveOneTime;
    }

    int getPriority(TriggerEvent) const
    {
        return 4;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player != room->getAllPlayers().first()) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from_places.contains(Player::DrawPile)) return false;
        QVariantList list = room->getTag("YHBuqueCards").toList();
        foreach (int id, move.card_ids) {
            if (!list.contains(QVariant(id))) continue;
            if (room->getCardPlace(id) == Player::DrawPile) continue;
            list.removeOne(id);
        }
        room->setTag("YHBuqueCards", list);
        return false;
    }

private:
    QString skill;
};

class YHSigong : public TriggerSkill
{
public:
    YHSigong() : TriggerSkill("yhsigong")
    {
        events << Appear;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@yhsigong-target", true, true);
        if (!t) return false;
        room->broadcastSkillInvoke(this);
        room->addPlayerMark(t, "&yhsigong+#" + player->objectName());
        room->addMaxCards(t, 1, false);
        return false;
    }
};

class YHSigongEffect : public TriggerSkill
{
public:
    YHSigongEffect() : TriggerSkill("#yhsigong")
    {
        events << EventPhaseEnd << CardsMoveOneTime << EventPhaseChanging;
        hide_skill = true;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Discard) return false;
            if (!room->getTag("YHSigongDiscard").toBool()) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                int mark = player->getMark("&yhsigong+#" + p->objectName());
                if (mark > 0 && p->isWounded())
                    room->sendCompulsoryTriggerLog(p, "yhsigong", true, true);
                for (int i = 0; i < mark; i++)
                    room->recover(p, RecoverStruct(p));
            }
        } else if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setTag("YHSigongDiscard", false);
        } else {
            if (!room->hasCurrent()) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.from) return false;
            if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)) return false;
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)
                room->setTag("YHSigongDiscard", true);
        }
        return false;
    }
};

YHXijianGiveCard::YHXijianGiveCard()
{
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
    m_skillName = "yhxijian_give";
}

bool YHXijianGiveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->hasSkill("yhxijian") && to_select->getMark("yhxijian_give-PlayClear") <= 0 && Self != to_select;
}

void YHXijianGiveCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    ServerPlayer *to = effect.to;
    room->giveCard(effect.from, to, this, "yhxijian_give");
    QVariantList list = to->tag["YHXijianCards"].toList();
    int id = getEffectiveId();
    if (list.contains(QVariant(id))) return;
    list << id;
    to->tag["YHXijianCards"] = list;
}

class YHXijianGive : public OneCardViewAsSkill
{
public:
    YHXijianGive() : OneCardViewAsSkill("yhxijian_give")
    {
        filter_pattern = ".|.|.|hand";
        attached_lord_skill = true;
    }

    const Card *viewAs(const Card *card) const
    {
        YHXijianGiveCard *c = new YHXijianGiveCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->isKongcheng();
    }
};

class YHXijian : public TriggerSkill
{
public:
    YHXijian() : TriggerSkill("yhxijian")
    {
        events << GameStart << EventAcquireSkill;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == EventAcquireSkill && data.toString() != objectName()) return false;
        const Skill *sk = Sanguosha->getSkill("yhxijian_give");
        if (!sk) return false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->hasSkill("yhxijian_give", true)) continue;
            room->attachSkillToPlayer(p, "yhxijian_give");
        }
        return false;
    }
};

class YHXijianEffect : public TriggerSkill
{
public:
    YHXijianEffect() : TriggerSkill("#yhxijian")
    {
        events << EventPhaseChanging << CardUsed << CardResponded;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseChanging)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            QList<ServerPlayer *> players = room->getAllPlayers(true);
            foreach (ServerPlayer *p, players) {
                int mark = p->getMark("yhxijian");
                if (mark == 0) continue;
                p->removeMark("yhxijian", mark);
                room->removePlayerMark(p, "@skill_invalidity", mark);

                foreach(ServerPlayer *q, room->getAllPlayers())
                    room->filterCards(q, q->getCards("he"), false);

                JsonArray args;
                args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
                room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
            }
        } else {
            QVariantList list = player->tag["YHXijianCards"].toList();
            if (list.isEmpty()) return false;
            QList<int> ids = VariantList2IntList(list);

            QList<ServerPlayer *> tos;
            const Card *card = NULL;
            if (event == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                card = use.card;
                tos = use.to;
            } else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (!card || card->isKindOf("SkillCard")) return false;

            QList<int> subcards;
            if (card->isVirtualCard())
                subcards = card->getSubcards();
            else
                subcards << card->getEffectiveId();

            bool can_invoke = false;
            foreach (int id, subcards) {
                if (ids.contains(id)) {
                    can_invoke = true;
                    ids.removeOne(id);
                }
            }

            if (!can_invoke) return false;

            list = IntList2VariantList(ids);
            player->tag["YHXijianCards"] = list;

            if (tos.isEmpty() || !room->hasCurrent()) {
                room->sendCompulsoryTriggerLog(player, "yhxijian", true, true);
                room->acquireNextTurnSkills(player, QString(), "xiangle");
            } else {
                ServerPlayer *to = room->askForPlayerChosen(player, tos, "yhxijian", "@yhxijian-target", true, true);
                if (to) {
                    room->broadcastSkillInvoke("yhxijian");
                    to->addMark("yhxijian");
                    room->addPlayerMark(to, "@skill_invalidity");

                    foreach(ServerPlayer *pl, room->getAllPlayers())
                        room->filterCards(pl, pl->getCards("he"), true);

                    JsonArray args;
                    args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
                    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
                } else {
                    room->sendCompulsoryTriggerLog(player, "yhxijian", true, true);
                    room->acquireNextTurnSkills(player, QString(), "xiangle");
                }
            }
        }
        return false;
    }
};

class YHBoben : public TriggerSkill
{
public:
    YHBoben() : TriggerSkill("yhboben")
    {
        events << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        room->addPlayerMark(player, "yhboben_slash-Clear");
        int dis_num = 2 - player->getMark("yhboben_slash-Clear");

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this) || p->getMark("yhboben_used-Clear") > 0) continue;
            if (dis_num > 0 && !p->canDiscard(p, "he")) continue;

            Duel *duel = new Duel(Card::NoSuit, 0);
            duel->deleteLater();
            duel->setSkillName("_yhboben");

            if (dis_num <= 0 && (player->isDead() || !p->canUse(duel, player, true))) continue;

            if (dis_num <= 0) {
                if (!p->askForSkillInvoke(this, player)) continue;
                room->broadcastSkillInvoke(objectName());
                room->addPlayerMark(p, "yhboben_used-Clear");
                room->useCard(CardUseStruct(duel, p, player), true);
            } else {
                const Card *card = room->askForDiscard(p, objectName(), dis_num, dis_num, true, true,
                      "@yhboben-discard:" + player->objectName() + "::" + QString::number(dis_num), ".", objectName());
                if (!card) continue;
                room->addPlayerMark(p, "yhboben_used-Clear");
                if (player->isDead() || !p->canUse(duel, player, true)) continue;
                foreach (int id, card->getSubcards()) {
                    if (Sanguosha->getCard(id)->isKindOf("BasicCard")) {
                       room->setCardFlag(duel, "yhboben_basic_" + p->objectName());
                       break;
                    }
                }
                room->useCard(CardUseStruct(duel, p, player), true);
            }
        }
        return false;
    }
};

class YHBobenDamage : public TriggerSkill
{
public:
    YHBobenDamage() : TriggerSkill("#yhboben")
    {
        events << DamageInflicted;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Duel") || !damage.card->hasFlag("yhboben_basic_" + player->objectName())) return false;
        LogMessage log;
        log.type = "#YHBobenDuel";
        log.from = player;
        log.arg = "yhboben";
        log.arg2 = "duel";
        room->sendLog(log);
        room->notifySkillInvoked(player, "yhboben");
        room->broadcastSkillInvoke("yhboben");
        return true;
    }
};

class YHHankai : public TriggerSkill
{
public:
    YHHankai() : TriggerSkill("yhhankai")
    {
        events << CardEffected << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            if (!player->getEquips().isEmpty()) return false;
            Analeptic *ana = new Analeptic(Card::NoSuit, 0);
            ana->deleteLater();
            ana->setSkillName("_yhhankai");
            if (!player->canUse(ana, player, true)) return false;
            room->sendCompulsoryTriggerLog(player, this);
            room->useCard(CardUseStruct(ana, player, player), true);
        } else {
            CardEffectStruct effect = data.value<CardEffectStruct>();
            if (effect.card->isKindOf("Analeptic")) {
                LogMessage log;
                log.type = "#SkillNullify";
                log.from = player;
                log.arg = objectName();
                log.arg2 = "analeptic";
                room->sendLog(log);
                room->broadcastSkillInvoke(this);
                room->notifySkillInvoked(player, objectName());

                int phase = (int)Player::RoundStart;
                room->addPlayerMark(player, "&yhhankai-Self" + QString::number(phase) + "Clear");
                return true;
            }
        }
        return false;
    }
};

class YHHankaiEffect : public TriggerSkill
{
public:
    YHHankaiEffect() : TriggerSkill("#yhhankai")
    {
        events << ConfirmDamage << Dying;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int phase = (int)Player::RoundStart;
        QString mark = "&yhhankai-Self" + QString::number(phase) + "Clear";

        if (event == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from->getMark(mark) > 0) {
                int m = damage.from->getMark(mark);
                LogMessage log;
                log.type = "#YHHankaiDamage";
                log.from = damage.from;
                log.to << damage.to;
                log.arg = "yhhankai";
                log.arg2 = QString::number(damage.damage);
                log.arg3 = QString::number(damage.damage += m);
                room->sendLog(log);
                room->notifySkillInvoked(damage.from, "yhhankai");
                room->broadcastSkillInvoke("yhhankai");
                data = QVariant::fromValue(damage);
            }
            if (damage.to->getMark(mark) > 0) {
                int m = damage.to->getMark(mark);
                LogMessage log;
                log.type = "#YHHankaiDamaged";
                log.from = damage.to;
                log.arg = "yhhankai";
                log.arg2 = QString::number(damage.damage);
                log.arg3 = QString::number(damage.damage += m);
                room->sendLog(log);
                room->notifySkillInvoked(damage.to, "yhhankai");
                room->broadcastSkillInvoke("yhhankai");
                data = QVariant::fromValue(damage);
            }
        } else {
            if (player->getMark(mark) <= 0) return false;
            DyingStruct dying = data.value<DyingStruct>();
            if (!dying.who || dying.who != player) return false;
            room->sendCompulsoryTriggerLog(player, "yhhankai", true, true);
            int recover = qMin(1 - player->getHp(), player->getMaxHp() - player->getHp());
            room->recover(player, RecoverStruct(player, NULL, recover));
            room->setPlayerMark(player, mark, 0);
        }
        return false;
    }
};

class YHHankaiLimit : public CardLimitSkill
{
public:
    YHHankaiLimit() : CardLimitSkill("#yhhankai-limit")
    {
    }

    QString limitList(const Player *target) const
    {
        int phase = (int)Player::RoundStart;
        QString mark = "&yhhankai-Self" + QString::number(phase) + "Clear";
        if (target->getMark(mark) > 0)
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        int phase = (int)Player::RoundStart;
        QString mark = "&yhhankai-Self" + QString::number(phase) + "Clear";
        if (target->getMark(mark) > 0)
            return "Analeptic|.|.|.";
        else
            return QString();
    }
};

class YHFeisha : public DistanceSkill
{
public:
    YHFeisha() : DistanceSkill("yhfeisha")
    {
    }

    int getCorrect(const Player *from, const Player *to) const
    {
        int num = 0;
        if (from->hasSkill(this)) {
            if (from->getHp() >= to->getHp())
                num--;
            if (from->getHandcardNum() >= to->getHandcardNum())
                num--;
        }
        return num;
    }
};

class YHJuantu : public TriggerSkill
{
public:
    YHJuantu() : TriggerSkill("yhjuantu")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || use.to.isEmpty()) return false;
        int mark = player->getMark("yhjuantu_num"), number = use.card->getNumber();
        if (mark <= 0 || number <= mark) return false;

        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isNude() || player->distanceTo(p) != 1) continue;
            players << p;
        }
        if (players.isEmpty()) return false;

        ServerPlayer *t = room->askForPlayerChosen(player, players, objectName(), "@yhjuantu-get", true, true);
        if (!t) return false;
        room->broadcastSkillInvoke(this);

        if (t->isNude()) return false;
        int id = room->askForCardChosen(player, t, "he", objectName());
        room->obtainCard(player, id, false);
        return false;
    }
};

class YHJuantuNumber : public TriggerSkill
{
public:
    YHJuantuNumber() : TriggerSkill("#yhjuantu")
    {
        events << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = data.value<CardUseStruct>().card;
        if (!card || card->isKindOf("SkillCard") || card->getNumber() <= 0) return false;
        room->setPlayerMark(player, "yhjuantu_num", card->getNumber());
        if (player->hasSkill("yhjuantu", true))
            room->setPlayerMark(player, "&yhjuantu", card->getNumber());
        return false;
    }
};

class YHJuantuClear : public TriggerSkill
{
public:
    YHJuantuClear() : TriggerSkill("#yhjuantu-clear")
    {
        events << EventLoseSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.toString() != "yhjuantu") return false;
        if (player->hasSkill("yhjuantu", true)) return false;
        room->setPlayerMark(player, "&yhjuantu", 0);
        return false;
    }
};

YHQuanwangCard::YHQuanwangCard()
{
}

void YHQuanwangCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    room->removePlayerMark(from, "@yhquanwangMark");
    room->doSuperLightbox("yh_shenmachao", "yhquanwang");

    DummyCard *handcards = from->wholeHandCards();
    room->giveCard(from, to, handcards, "yhquanwang");
    delete handcards;

    room->handleAcquireDetachSkills(from, "-yhjuantu|yhchouxi");
    if (to->isDead()) return;
    room->addPlayerMark(to, "yhquanwang_extra_turn");
}

class YHQuanwangVS : public ZeroCardViewAsSkill
{
public:
    YHQuanwangVS() : ZeroCardViewAsSkill("yhquanwang")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@yhquanwangMark") > 0 && !player->isKongcheng();
    }

    const Card *viewAs() const
    {
        return new YHQuanwangCard;
    }
};

class YHQuanwang : public PhaseChangeSkill
{
public:
    YHQuanwang() : PhaseChangeSkill("yhquanwang")
    {
        frequency = Limited;
        limit_mark = "@yhquanwangMark";
        view_as_skill = new YHQuanwangVS;
        waked_skills = "yhchouxi";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::NotActive;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            int mark = p->getMark("yhquanwang_extra_turn");
            room->setPlayerMark(p, "yhquanwang_extra_turn", 0);
            if (p->isDead() || mark <= 0) continue;
            for (int i = 0; i < mark; i++) {
                if (p->isDead()) break;
                p->gainAnExtraTurn();
            }
        }
        return false;
    }
};

class YHChouxi : public TriggerSkill
{
public:
    YHChouxi() : TriggerSkill("yhchouxi")
    {
        events << Dying;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (!dying.who || player->tag["YHChouxi_" + dying.who->objectName()].toBool()) return false;
        room->sendCompulsoryTriggerLog(player, this);
        player->tag["YHChouxi_" + dying.who->objectName()] = true;
        room->addPlayerMark(player, "&yhchouxi");
        return false;
    }
};

class YHChouxiDamage : public TriggerSkill
{
public:
    YHChouxiDamage() : TriggerSkill("#yhchouxi")
    {
        events << ConfirmDamage;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int mark = player->getMark("&yhchouxi");
        if (mark <= 0) return false;
        DamageStruct damage = data.value<DamageStruct>();
        LogMessage log;
        log.type = "#YHChouxiDamage";
        log.from = player;
        log.arg = "yhchouxi";
        log.arg2 = QString::number(damage.damage);
        log.arg3 = QString::number(damage.damage += mark);
        room->sendLog(log);
        room->notifySkillInvoked(player, "yhchouxi");
        room->broadcastSkillInvoke("yhchouxi");
        data = QVariant::fromValue(damage);
        return false;
    }
};

class YHChenwen : public TriggerSkill
{
public:
    YHChenwen() : TriggerSkill("yhchenwen")
    {
        events << DrawNCards << EventPhaseEnd << EventPhaseChanging;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DrawNCards) {
            QStringList choices;
            for (int i = 0; i < 3; i++)
                choices << "yhchenwen=" + QString::number(i + 1);
            choices << "cancel";
            QString choice = room->askForChoice(player, objectName(), choices.join("+"));
            if (choice == "cancel") return false;
            int num = choice.split("=").last().toInt();
            room->loseMaxHp(player, num);
            data = data.toInt() + num;
        } else if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play || !player->canDiscard(player, "h")) return false;
            const Card *c = room->askForDiscard(player, objectName(), 3, 1, true, false, "@yhchenwen-discard", ".|.|.|hand", objectName());
            if (!c) return false;
            room->gainMaxHp(player, c->subcardsLength());
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            if (player->getMark("damage_point_round") > 0) return false;
            QString _podi = player->property("SkillDescriptionRecord_yhpodi").toString();
            QStringList choices, podi = _podi.isEmpty() ? QStringList() : _podi.split("+");


            if (player->hasSkill("yhshouzhuang", true) && !player->tag["YHShouzhuangUnlock"].toBool())
                choices << "yhshouzhuang";
            if (player->hasSkill("yhpodi", true)) {
                for (int i = 0; i < 3; i++) {
                    int j = i + 2;
                    if (podi.contains(QString::number(j))) continue;
                    choices << "yhpodi" + QString::number(j);
                }
            }
            if (choices.isEmpty()) return false;
            choices << "cancel";
            QString choice = room->askForChoice(player, objectName(), choices.join("+"));
            if (choice == "cancel") return false;

            LogMessage log;
            log.type = "#YHChenwenInvoke";
            log.from = player;
            log.arg = objectName();
            log.arg2 = "yhchenwen:" + choice;
            room->sendLog(log);
            player->peiyin(this);
            room->notifySkillInvoked(player, objectName());

            if (choice == "yhshouzhuang") {
                player->tag["YHShouzhuangUnlock"] = true;
                room->changeTranslation(player, "yhshouzhuang", 1);
            } else {
                QString last = choice.at(choice.length() - 1);
                int n = last.toInt();
                podi << QString::number(n);
                room->setPlayerProperty(player, "SkillDescriptionRecord_yhpodi", podi.join("+"));
                room->changeTranslation(player, "yhpodi", 1);
            }
        }
        return false;
    }
};

class YHShouzhuang : public MasochismSkill
{
public:
    YHShouzhuang() : MasochismSkill("yhshouzhuang")
    {
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        ServerPlayer *from = damage.from;
        if (!from || from == player) return;

        int dam = 2 * damage.damage;
        player->tag["YHShouzhuangData"] = QVariant::fromValue(damage);

        int invoke = 0;
        if (player->tag["YHShouzhuangUnlock"].toBool())
            invoke = player->askForSkillInvoke(this, from) ? 1 : 0;
        else
            invoke = player->askForSkillInvoke(this, "yhshouzhuang:" + from->objectName() + "::" + QString::number(dam)) ? 2 : 0;
        player->tag.remove("YHShouzhuangData");

        if (invoke == 0) return;
        player->peiyin(this);

        Room *room = player->getRoom();
        if (invoke == 2)
            room->askForDiscard(from, objectName(), dam, dam, false, true);
        else {
            QStringList choices;
            int equip = player->getEquips().length();
            choices << "yhshouzhuang1=" + from->objectName() + "=" + QString::number(dam) << "yhshouzhuang2=" + from->objectName() + "=" + QString::number(equip);
            QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(from));
            int dis = choice.startsWith("yhshouzhuang1") ? dam : player->getEquips().length();
            if (dis <= 0) return;
            room->askForDiscard(from, objectName(), dis, dis, false, true);
        }
    }
};

YHPodiCard::YHPodiCard()
{
}

void YHPodiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    room->loseMaxHp(from);
    if (from->isDead()) return;

    QList<int> hands = to->handCards();
    if (!hands.isEmpty())
        //room->doGongxin(from, to, QList<int>(), "yhpodi");
        room->fillAG(hands, from);

    QString _podi = from->property("SkillDescriptionRecord_yhpodi").toString();
    QStringList podi = _podi.isEmpty() ? QStringList() : _podi.split("+");

    QStringList choices;
    if (!hands.isEmpty()) {
        choices << "1";
        if (podi.contains("2")) {
            bool candis = false;
            foreach (int id, hands) {
                if (from->canDiscard(to, id)) {
                    candis = true;
                    break;
                }
            }
            if (candis)
                choices << "2=" + to->objectName();
        }
    }

    if (podi.contains("3"))
        choices << "3=" + to->objectName();
    if (podi.contains("4"))
        choices << "4=" + to->objectName();
    choices << "cancel";

    QString choice = room->askForChoice(from, "yhpodi", choices.join("+"), QVariant::fromValue(to));
    room->clearAG(from);
    if (choice == "cancel") return;

    if (choice.startsWith("1")) {
        room->fillAG(hands, from);
        int id = room->askForAG(from, hands, false, "yhpodi", "@yhpodi-show");
        room->clearAG(from);
        room->showCard(to, id);
        if (Sanguosha->getCard(id)->isKindOf("BasicCard")) return;
        room->askForDiscard(from, "yhpodi", 1, 1, false, false);
    } else if (choice.startsWith("2")) {
        QList<int> able, disable;
        foreach (int id, hands) {
            if (from->canDiscard(to, id))
                able << id;
            else
                disable << id;
        }
        if (able.isEmpty()) return;

        room->fillAG(hands, from, disable);
        int id = room->askForAG(from, able, false, "yhpodi", "@yhpodi-discard");
        room->clearAG(from);
        room->throwCard(id, to, from);
        room->addPlayerMark(from, "yhpodi_juli_" + to->objectName() + "-Clear");
    } else if (choice.startsWith("3")) {
        from->drawCards(1, "yhpodi");
        room->addPlayerMark(from, "yhpodi_cishu_" + to->objectName() + "-Clear");
    } else {
        room->addPlayerMark(to, "&yhpodi_wuxiao-Keep");

        foreach(ServerPlayer *p, room->getAllPlayers())
            room->filterCards(p, p->getCards("he"), true);

        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

        podi.removeOne("4");
        room->setPlayerProperty(from, "SkillDescriptionRecord_yhpodi", podi.isEmpty() ? QString() : podi.join("+"));
        room->changeTranslation(from, "yhpodi", podi.isEmpty() ? 2 : 1);
    }
}

class YHPodiVS : public ZeroCardViewAsSkill
{
public:
    YHPodiVS() : ZeroCardViewAsSkill("yhpodi")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    const Card *viewAs() const
    {
        return new YHPodiCard;
    }
};

class YHPodi : public TriggerSkill
{
public:
    YHPodi() : TriggerSkill("yhpodi")
    {
        events << EventPhaseChanging;
        view_as_skill = new YHPodiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getAllPlayers(true)) {
            if (p->getMark("&yhpodi_wuxiao-Keep") <= 0) continue;
            room->setPlayerMark(p, "&yhpodi_wuxiao-Keep", 0);

            foreach(ServerPlayer *p, room->getAllPlayers())
                room->filterCards(p, p->getCards("he"), false);

            JsonArray args;
            args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
        }
        return false;
    }
};

class YHPodiInvalidity : public InvaliditySkill
{
public:
    YHPodiInvalidity() : InvaliditySkill("#yhpodi-inv")
    {
    }

    bool isSkillValid(const Player *player, const Skill *) const
    {
        return player->getMark("&yhpodi_wuxiao-Keep") <= 0;
    }
};

class YHPodiTargetMod : public TargetModSkill
{
public:
    YHPodiTargetMod() : TargetModSkill("#yhpodi-target")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (to && from->getMark("yhpodi_cishu_" + to->objectName() + "-Clear") > 0)
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (to && from->getMark("yhpodi_juli_" + to->objectName() + "-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

class YHDuweiVS : public OneCardViewAsSkill
{
public:
    YHDuweiVS() : OneCardViewAsSkill("yhduwei")
    {
        response_or_use = true;
        response_pattern = "@@yhduwei";
    }

    bool viewFilter(const Card *to_select) const
    {
        QString name = Self->property("yhduwei_damage_card").toString();
        if (name.isEmpty()) return false;
        Card *c = Sanguosha->cloneCard(name, Card::SuitToBeDecided, -1);
        if (!c) return false;
        c->setSkillName(objectName());
        c->addSubcard(to_select);
        c->deleteLater();
        return c->isAvailable(Self);
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("yhduwei-PlayClear") > 0) return false;
        QString name = player->property("yhduwei_damage_card").toString();
        if (name.isEmpty()) return false;
        Card *c = Sanguosha->cloneCard(name);
        if (!c) return false;
        c->setSkillName(objectName());
        c->deleteLater();
        return c->isAvailable(player);
    }

    const Card *viewAs(const Card *card) const
    {
        QString name = Self->property("yhduwei_damage_card").toString();
        if (name.isEmpty()) return NULL;
        Card *c = Sanguosha->cloneCard(name, Card::SuitToBeDecided, -1);
        if (!c) return NULL;
        c->setSkillName(objectName());
        c->addSubcard(card);
        return c;
    }
};

class YHDuwei : public TriggerSkill
{
public:
    YHDuwei() : TriggerSkill("yhduwei")
    {
        events << PreCardUsed << EventPhaseStart;
        view_as_skill = new YHDuweiVS;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.m_addHistory) return false;
            if (use.card->getSkillName() == objectName() || use.card->hasFlag("yhduwei_used_slash")) {
                room->addPlayerMark(player, "yhduwei-PlayClear");
                use.m_addHistory = false;
                room->addPlayerHistory(player, use.card->getClassName(), -1);
                data = QVariant::fromValue(use);
            }
        } else {
            if (player->getPhase() != Player::Finish) return false;
            QString name = player->property("yhduwei_damage_card").toString();
            if (name.isEmpty()) return false;
            room->askForUseCard(player, "@@yhduwei", "@yhduwei:" + name, -1, Card::MethodUse, false);
        }
        return false;
    }
};

class YHDuweiTargetMod : public TargetModSkill
{
public:
    YHDuweiTargetMod() : TargetModSkill("#yhduwei")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("yhduwei_used_slash") || card->getSkillName() == "yhduwei")
            return 1000;
        else
            return 0;
    }
};

class YHSiku : public TriggerSkill
{
public:
    YHSiku() : TriggerSkill("yhsiku")
    {
        events << Death;
        frequency = Limited;
        limit_mark = "@yhsikuMark";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill(this) && target->getMark("@yhsikuMark") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who->getHandcardNum() > player->getHandcardNum()) return false;

        ServerPlayer *from = NULL;
        if (death.damage && death.damage->from)
            from = death.damage->from;

        player->tag["YHSikuData"] = data;
        bool invoke = player->askForSkillInvoke(this, from != NULL ? "yhsiku:" + from->objectName() : "yhsiku2");
        player->tag.remove("YHSikuData");
        if (!invoke) return false;
        player->peiyin(this);

        room->removePlayerMark(player, "@yhsikuMark");
        room->doSuperLightbox("yh_dingfuren", "yhsiku");

        player->throwAllHandCards();
        if (!from) return false;

        QList<const Skill *> skills = from->getVisibleSkillList();
        QStringList detachList;
        foreach (const Skill *skill, skills) {
            if (!skill->inherits("SPConvertSkill") && !skill->isAttachedLordSkill())
                detachList.append("-" + skill->objectName());
        }
        room->handleAcquireDetachSkills(from, detachList);
        return false;
    }
};

class YHQingsi : public TriggerSkill
{
public:
    YHQingsi() : TriggerSkill("yhqingsi")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from && move.from_places.contains(Player::PlaceHand) && move.is_last_handcard && move.reason.m_skillName != "yhchuzhu") {
            ServerPlayer *from = (ServerPlayer *)move.from;
            if (from->isDead()) return false;

            player->tag["YHQingsiData"] = data;
            bool invoke = player->askForSkillInvoke(this, from);
            player->tag.remove("YHQingsiData");
            if (!invoke) return false;
            player->peiyin(this);

            QList<int> hands = from->handCards(), get;
            foreach (int id, move.card_ids) {
                if (hands.contains(id)) continue;
                get << id;
            }
            if (!get.isEmpty()) {
                DummyCard dummy(get);
                room->obtainCard(from, &dummy, false);
            }

            QList<ServerPlayer *> players;
            players << from << player;
            room->sortByActionOrder(players);
            room->drawCards(players, 1, objectName());

            room->loseHp(player);
            return false;
        }
        return false;
    }
};

class YHChuzhu : public TriggerSkill
{
public:
    YHChuzhu() : TriggerSkill("yhchuzhu")
    {
        events << Dying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dy = data.value<DyingStruct>();
        if (dy.who != player) return false;

        int mark = player->tag["YHQingsiNum"].toInt();
        ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(),
                                                   "@yhchuzhu-target:" + QString::number(mark), true, true);
        if (!t) return false;
        player->peiyin(this);

        QList<int> give = player->handCards() + player->getEquipsId();
        if (!give.isEmpty())
            room->giveCard(player, t, give, objectName());
        if (mark > 0)
            room->recover(t, RecoverStruct(player, NULL, qMin(mark, t->getMaxHp() - t->getHp())));
        DamageStruct damage;
        damage.from = player;
        room->killPlayer(player, &damage);
        return false;
    }
};

class YHChuzhuMark : public TriggerSkill
{
public:
    YHChuzhuMark() : TriggerSkill("#yhchuzhu")
    {
        events << ChoiceMade << EventAcquireSkill;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == ChoiceMade) {
            QString decisionString = data.toString();
            if (decisionString.isEmpty()) return false;
            QStringList decisionStrings = decisionString.split(":");
            if (decisionStrings.first() != "skillInvoke" || decisionStrings[1] != "yhqingsi" || decisionStrings.last() != "yes") return false;
            int mark = player->tag["YHQingsiNum"].toInt();
            mark++;
            player->tag["YHQingsiNum"] = mark;
            if (player->hasSkill("yhqingsi", true))
                room->addPlayerMark(player, "&yhqingsi_num");
        } else {
            QString skill = data.toString();
            if (skill != "yhqingsi" || !player->hasSkill("yhqingsi", true)) return false;
            int mark = player->tag["YHQingsiNum"].toInt();
            if (mark > 0)
                room->setPlayerMark(player, "&yhqingsi_num", mark);
        }
        return false;
    }
};

class YHHuairen : public TriggerSkill
{
public:
    YHHuairen() : TriggerSkill("yhhuairen")
    {
        events << DrawInitialCards << CardUsed << CardResponded;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DrawInitialCards) {
            room->sendCompulsoryTriggerLog(player, this);
            room->setPlayerFlag(player, "YHHuairenDrawCardsSkill");
            int max = player->getMaxHp(), hp = player->getHp();
            room->gainMaxHp(player, max);
            room->recover(player, RecoverStruct(player, NULL, qMin(hp, player->getMaxHp() - player->getHp())));
            data = data.toInt() * 2;
        } else {
            if (!player->getPile("yhlmren").isEmpty()) return false;
            const Card *card = NULL;
            if (event == CardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (!card || card->isKindOf("SkillCard") || !card->isRed()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class YHHuairenEffect : public TriggerSkill
{
public:
    YHHuairenEffect() : TriggerSkill("#yhhuairen")
    {
        events << AfterDrawInitialCards << HpRecover << Death;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == AfterDrawInitialCards) {
            if (!player->hasFlag("YHHuairenDrawCardsSkill")) return false;
            room->setPlayerFlag(player, "-YHHuairenDrawCardsSkill");
            if (player->isNude()) return false;
            const Card *c = room->askForCard(player, "..", "@yhhuairen-put", data, Card::MethodNone);
            player->addToPile("yhlmren", c);
        } else if (event == HpRecover) {
            int n = data.value<RecoverStruct>().recover;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getPile("yhlmren").isEmpty()) continue;
                room->addPlayerMark(p, "&yhhuairen_num", n);
                if (p->getMark("&yhhuairen_num") >= p->aliveCount()) {
                    room->sendCompulsoryTriggerLog(p, "yhhuairen", true, true);
                    room->setPlayerMark(p, "&yhhuairen_num", 0);
                    DummyCard get(p->getPile("yhlmren"));
                    CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, p->objectName());
                    room->obtainCard(p, &get, reason, true);
                    if (p->isAlive()) {
                        int max = floor(p->getMaxHp() / 2);
                        if (max > 0)
                            room->loseMaxHp(p, max);
                    }
                }
            }
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player) return false;
            if (player->getPile("yhlmren").isEmpty()) return false;
            if (player->getMark("&yhhuairen_num") >= player->aliveCount()) {
                room->sendCompulsoryTriggerLog(player, "yhhuairen", true, true);
                room->setPlayerMark(player, "&yhhuairen_num", 0);
                DummyCard get(player->getPile("yhlmren"));
                CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, player->objectName());
                room->obtainCard(player, &get, reason, true);
                if (player->isAlive()) {
                    int max = floor(player->getMaxHp() / 2);
                    if (max > 0)
                        room->loseMaxHp(player, max);
                }
            }
        }
        return false;
    }
};

class YHHuairenLimit : public CardLimitSkill
{
public:
    YHHuairenLimit() : CardLimitSkill("#yhhuairen-limit")
    {
    }

    QString limitList(const Player *target) const
    {
        if (target->hasSkill("yhhuairen") && !target->getPile("yhlmren").isEmpty())
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->hasSkill("yhhuairen") && !target->getPile("yhlmren").isEmpty())
            return "Slash|black";
        else
            return QString();
    }
};

YHYurenCard::YHYurenCard()
{
    will_throw = false;
    mute = true;
    handling_method = Card::MethodUse;
}

bool YHYurenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    }

    const Card *card = Self->tag.value("yhyuren").value<const Card *>();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool YHYurenCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    }

    const Card *card = Self->tag.value("yhyuren").value<const Card *>();
    return card && card->targetFixed();
}

bool YHYurenCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    }

    const Card *card = Self->tag.value("yhyuren").value<const Card *>();
    return card && card->targetsFeasible(targets, Self);
}

const Card *YHYurenCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;
    Room *room = player->getRoom();

    QString to_yizan = user_string;
    if ((user_string.contains("slash") || user_string.contains("Slash")) && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList guhuo_list = Sanguosha->getSlashNames();
        if (guhuo_list.isEmpty())
            guhuo_list << "slash";
        to_yizan = room->askForChoice(player, "yhyuren_slash", guhuo_list.join("+"));
    }

    Card *use_card = Sanguosha->cloneCard(to_yizan, Card::SuitToBeDecided, -1);
    use_card->setSkillName("yhyuren");
    use_card->addSubcards(getSubcards());
    use_card->deleteLater();
    return use_card;
}

const Card *YHYurenCard::validateInResponse(ServerPlayer *player) const
{
    Room *room = player->getRoom();

    QString to_yizan;
    if (user_string == "peach+analeptic") {
        QStringList guhuo_list;
        guhuo_list << "peach";
        if (Sanguosha->hasCard("analeptic"))
            guhuo_list << "analeptic";
        to_yizan = room->askForChoice(player, "yhyuren_saveself", guhuo_list.join("+"));
    } else if (user_string.contains("slash") || user_string.contains("Slash")) {
        QStringList guhuo_list = Sanguosha->getSlashNames();
        if (guhuo_list.isEmpty())
            guhuo_list << "slash";
        to_yizan = room->askForChoice(player, "yhyuren_slash", guhuo_list.join("+"));
    } else
        to_yizan = user_string;

    Card *use_card = Sanguosha->cloneCard(to_yizan, Card::SuitToBeDecided, -1);
    use_card->setSkillName("yhyuren");
    use_card->addSubcards(getSubcards());
    use_card->deleteLater();
    return use_card;
}

class YHYuren : public OneCardViewAsSkill
{
public:
    YHYuren() : OneCardViewAsSkill("yhyuren")
    {
        response_or_use = true;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("yhyuren", true, false);
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) return false;
        if (pattern.startsWith(".") || pattern.startsWith("@")) return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;
        QStringList patterns = pattern.split("+");
        foreach (QString name, patterns) {
            name = name.toLower();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            if (card->isKindOf("BasicCard"))
                return true;
        }
        patterns = pattern.split(",");
        foreach (QString name, patterns) {
            name = name.toLower();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            if (card->isKindOf("BasicCard"))
                return true;
        }
        return false;
    }

    bool viewFilter(const Card *to_select) const
    {
        return to_select->isKindOf("Slash") && !Self->isLocked(to_select);
    }

    const Card *viewAs(const Card *card) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            YHYurenCard *c = new YHYurenCard;
            c->setUserString(Sanguosha->getCurrentCardUsePattern());
            c->addSubcard(card);
            return c;
        }
        const Card *c = Self->tag.value("yhyuren").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            YHYurenCard *cc = new YHYurenCard;
            cc->setUserString(c->objectName());
            cc->addSubcard(card);
            return cc;
        }
        return NULL;
    }
};

class YHRangwei : public TriggerSkill
{
public:
    YHRangwei() : TriggerSkill("yhrangwei")
    {
        events << CardUsed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || !use.to.contains(player) || use.to.length() != 1) return false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isProhibited(p, use.card)) continue;  //这里不用canUse函数，免得【酒】被判定为不能用
            if (!use.card->targetFilter(QList<const Player *>(), p, player)) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@yhrangwei-target:" + use.card->objectName(), true, true);
        if (!t) return false;
        player->peiyin(this);
        room->addPlayerMark(t, "yhrangwei_target-Keep");

        use.to.removeOne(player);
        use.to << t;
        data = QVariant::fromValue(use);

        targets.clear();
        targets << player << t;
        room->sortByActionOrder(targets);

        foreach (ServerPlayer *p, targets)
            room->recover(p, RecoverStruct(player));

        return false;
    }
};

class YHPosi : public TriggerSkill
{
public:
    YHPosi() : TriggerSkill("yhposi")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill(this);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player) return false;

        if (death.damage && death.damage->from) {
            ServerPlayer *from = death.damage->from;
            if (from->isDead() || from == player) return false;

            bool invoke = false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("yhrangwei_target-Keep") <= 0) continue;
                if (!p->canDiscard(from, "he")) continue;
                invoke = true;
                break;
            }
            if (!invoke) return false;

            room->sendCompulsoryTriggerLog(player, this);

            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("yhrangwei_target-Keep") <= 0) continue;
                if (!p->canDiscard(from, "he")) continue;

                int id = room->askForCardChosen(p, from, "he", objectName(), false, Card::MethodDiscard);
                room->throwCard(id, from, p);

                if (p->getAI())
                    room->getThread()->delay();
            }

            if (from->isAlive() && !from->isNude())
                from->turnOver();
        }
        return false;
    }
};

class YHXiaoyun : public PhaseChangeSkill
{
public:
    YHXiaoyun() : PhaseChangeSkill("yhxiaoyun")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (!player->canDiscard(p, "ej")) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@yhxiaoyun-discard", true, true);
        if (!t) return false;
        player->peiyin(this);
        QString pattern = "TrickCard";
        int id = room->askForCardChosen(player, t, "ej", objectName(), false, Card::MethodDiscard);
        if (room->getCardPlace(id) == Player::PlaceEquip)
            pattern = "EquipCard";
        room->throwCard(id, t, player);
        if (player->isAlive())
            room->setPlayerCardLimitation(player, "use", pattern, true);
        return false;
    }
};

YHMeiyingCard::YHMeiyingCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void YHMeiyingCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    room->giveCard(from, to, this, "yhmeiying");
    if (to->isDead()) return;
    int id = subcards.first();
    if (!to->handCards().contains(id)) {
        room->loseHp(to);
        room->addPlayerMark(from, "yhmeiying_used-PlayClear");
        return;
    }
    const Card *c = Sanguosha->getCard(id);
    if (!to->canUse(c)) {
        room->loseHp(to);
        room->addPlayerMark(from, "yhmeiying_used-PlayClear");
    } else {
        room->setPlayerMark(to, "yhmeiying_id-PlayClear", id + 1);
        const Card *use = room->askForUseCard(to, "@@yhmeiying", "@yhmeiying:" + c->objectName());
        room->setPlayerMark(to, "yhmeiying_id-PlayClear", 0);
        if (!use) {
            room->loseHp(to);
            room->addPlayerMark(from, "yhmeiying_used-PlayClear");
        } else
            from->drawCards(1, "yhmeiying");
    }
}

class YHMeiying : public OneCardViewAsSkill
{
public:
    YHMeiying() : OneCardViewAsSkill("yhmeiying")
    {
        response_pattern = "@@yhmeiying";
    }

    bool viewFilter(const Card *to_select) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@yhmeiying")
            return to_select->getEffectiveId() == Self->getMark("yhmeiying_id-PlayClear") - 1;
        return !to_select->isAvailable(Self) && !to_select->isEquipped();
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("yhmeiying_used-PlayClear") <= 0;
    }

    const Card *viewAs(const Card *card) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@yhmeiying") {
            int id = Self->getMark("yhmeiying_id-PlayClear") - 1;
            if (id < 0) return NULL;
            const Card *card = Sanguosha->getCard(id);
            return card;
        }
        YHMeiyingCard *c = new YHMeiyingCard();
        c->addSubcard(card);
        return c;
    }
};

class YHBozhiVS : public ZeroCardViewAsSkill
{
public:
    YHBozhiVS() : ZeroCardViewAsSkill("yhbozhi")
    {
        response_pattern = "@@yhbozhi";
    }

    const Card *viewAs() const
    {
        QString name = Self->property("YHBozhiRecordTrick").toString();
        if (name.isEmpty()) return NULL;
        Card *c = Sanguosha->cloneCard(name, Card::NoSuit, 0);
        if (!c) return NULL;
        c->setSkillName(objectName());
        return c;
    }
};

class YHKudu : public TriggerSkill
{
public:
    YHKudu() : TriggerSkill("yhkudu")
    {
        events << TurnStart << EventPhaseStart;
    }

    Frequency getFrequency(const Player *target) const
    {
        if (target && target->getMark(objectName()) > 0)
            return NotFrequent;
        return Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        QStringList choices, phase_names;
        QString choice, phase_name;
        phase_names << "judge" << "draw" << "play" << "discard";

        if (event == TurnStart) {
            if (getFrequency(player) == NotFrequent || !player->faceUp()) return false;

            foreach (QString phase_name, phase_names) {
                if (player->getMark("LostPlayerPhase_" + phase_name) <= 0)
                    choices << "self=" + phase_name;
            }
            if (choices.isEmpty()) return false;

            room->sendCompulsoryTriggerLog(player, this);

            choice = room->askForChoice(player, objectName(), choices.join("+"));
            phase_name = choice.split("=").last();

            room->addPlayerMark(player, "LostPlayerPhase_" + phase_name);
            LogMessage log;
            log.from = player;
            log.type = "#YHKuduLosePhase";
            log.arg = phase_name;
            room->sendLog(log);

            QString lostphase = player->property("SkillDescriptionRecord_yhkudu").toString();
            QStringList lostphases;
            if (!lostphase.isEmpty())
                lostphases = lostphase.split("+");
            if (!lostphases.contains(phase_name)) {
                lostphases << phase_name;
                room->setPlayerProperty(player, "SkillDescriptionRecord_yhkudu", lostphases.join("+"));
                room->changeTranslation(player, objectName(), 1);
            }

            QVariant data = "yhkudu_lose_phase_" + phase_name;
            room->getThread()->trigger(EventForDiy, room, player, data);
        } else {
            if (getFrequency(player) == Compulsory || player->getPhase() != Player::Start) return false;

            for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
                if (!player->hasEquipArea(i)) continue;
                choices << QString::number(i);
            }
            if (choices.isEmpty()) return false;

            if (!player->askForSkillInvoke(this)) return false;
            player->peiyin(this);
            choice = room->askForChoice(player, objectName(), choices.join("+"));

            player->throwEquipArea(choice.toInt());
        }

        if (player->isDead()) return false;

        choices.clear();
        foreach (QString phase_name, phase_names)
            choices << "other=" + phase_name;
        choice = room->askForChoice(player, objectName(), choices.join("+"));
        phase_name = choice.split("=").last();

        ServerPlayer *last = player->tag["YHKuduPlayer"].value<ServerPlayer *>();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getMark("LostPlayerPhase_" + phase_name) > 0 || p == last) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@yhkudu-target:" + phase_name);
        room->doAnimate(1, player->objectName(), t->objectName());
        player->tag["YHKuduPlayer"] = QVariant::fromValue(t);
        room->setPlayerMark(t, "&yhkudu+:+" + phase_name, 1);
        return false;
    }
};

class YHKuduSkip : public TriggerSkill
{
public:
    YHKuduSkip() : TriggerSkill("#yhkudu")
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
        QStringList phase_names;
        phase_names << "judge" << "draw" << "play" << "discard";
        QList<Player::Phase> phases;
        phases << Player::Judge << Player::Draw << Player::Play << Player::Discard;

        int n = phases.indexOf(change.to);
        if (n < 0) return false;
        QString phase_name = phase_names.at(n);
        if (phase_name.isEmpty()) return false;

        QString mark = "&yhkudu+:+" + phase_name;
        if (player->getMark(mark) <= 0) return false;
        room->setPlayerMark(player, mark, 0);

        if (player->isSkipped(change.to)) return false;
        LogMessage log;
        log.type = "#ZhenguEffect";
        log.from = player;
        log.arg = "yhkudu";
        room->sendLog(log);
        player->skip(change.to);
        return false;
    }
};

YHKunmoCard::YHKunmoCard()
{
    mute = true;
    handling_method = Card::MethodUse;
    will_throw = false;
}

bool YHKunmoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *c = Sanguosha->getCard(subcards.first());
    return c->targetFilter(targets, to_select, Self);
}

bool YHKunmoCard::targetFixed() const
{
    const Card *c = Sanguosha->getCard(subcards.first());
    return c->targetFixed();
}

bool YHKunmoCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    const Card *c = Sanguosha->getCard(subcards.first());
    return c->targetsFeasible(targets, Self);
}

void YHKunmoCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *from = card_use.from;
    QList<ServerPlayer *> tos = card_use.to;
    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = from;
    log.arg = "yhkunmo";
    room->sendLog(log);
    room->notifySkillInvoked(from, "yhkunmo");
    from->peiyin("yhkunmo");
    if (tos.isEmpty())
        tos << from;
    room->useCard(CardUseStruct(Sanguosha->getCard(subcards.first()), from, tos));
}

class YHKunmoVS : public OneCardViewAsSkill
{
public:
    YHKunmoVS() : OneCardViewAsSkill("yhkunmo")
    {
        response_pattern = "@@yhkunmo";
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        return to_select->isAvailable(Self) && !Self->isLocked(to_select);
    }

    const Card *viewAs(const Card *originalCard) const
    {
        //return originalCard;
        YHKunmoCard *c = new YHKunmoCard();
        c->addSubcard(originalCard);
        return c;
    }
};

class YHKunmo : public TriggerSkill
{
public:
    YHKunmo() : TriggerSkill("yhkunmo")
    {
        events << EventPhaseSkipped << EventPhaseStart << EventPhaseChanging;
        view_as_skill = new YHKunmoVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseSkipped) {
            if (player->getPhase() == Player::Draw) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isDead() || !p->hasSkill(this) || !p->askForSkillInvoke(this)) continue;
                    p->peiyin(this);
                    p->drawCards(1, objectName());
                }
            } else if (player->getPhase() == Player::Play) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isDead() || !p->hasSkill(this)) continue;
                    room->askForUseCard(p, "@@yhkunmo", "@yhkunmo");
                }
            }
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            if (player->isDead() || !player->hasSkill(this) || !player->askForSkillInvoke(this)) return false;
            player->peiyin(this);
            player->drawCards(1, objectName());
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            if (player->isDead() || !player->hasSkill(this)) return false;
            room->askForUseCard(player, "@@yhkunmo", "@yhkunmo");
        }
        return false;
    }
};

class YHTanyou : public TriggerSkill
{
public:
    YHTanyou() : TriggerSkill("yhtanyou")
    {
        events << EventForDiy << Dying;
        frequency = Limited;
        limit_mark = "@yhtanyouMark";
        shiming_skill = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QStringList phase_names;
        phase_names << "judge" << "draw" << "play" << "discard";

        if (event == EventForDiy) {
            QString diy = data.toString();
            if (!diy.startsWith("yhkudu_lose_phase_")) return false;

            if (player->getMark("@yhtanyouMark") > 0) {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (p->getMaxHp() > 1)
                        targets << p;
                }

                if (!targets.isEmpty()) {
                    ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@yhtanyou-target", true, true);
                    if (t) {
                        player->peiyin(this, 1);

                        room->removePlayerMark(player, "@yhtanyouMark");
                        room->doSuperLightbox("yh_liufuren", objectName());

                        QStringList names = player->tag["YHTanyouPlayers"].toStringList();
                        if (!names.contains(t->objectName())) {
                            names << t->objectName();
                            player->tag["YHTanyouPlayers"] = names;
                        }

                        room->loseMaxHp(t);
                        room->addPlayerMark(t, "&yhtanyou_buff");
                    }

                }
            }

            if (player->getMark(objectName()) > 0) return false;

            bool lose_all = true;
            foreach (QString phase_name, phase_names) {
                if (player->getMark("LostPlayerPhase_" + phase_name) <= 0) {
                    lose_all = false;
                    break;
                }
            }
            if (!lose_all) return false;

            room->sendShimingLog(player, this);

            QList<ServerPlayer *> players;
            players << player;
            QStringList names = player->tag["YHTanyouPlayers"].toStringList();
            foreach (QString name, names) {
                ServerPlayer *p = room->findChild<ServerPlayer *>(name);
                if (p && p->isAlive() && !players.contains(p))
                    players << p;
            }
            room->sortByActionOrder(players);

            foreach (ServerPlayer *p, players) {
                room->gainMaxHp(p);
                room->recover(p, RecoverStruct(player));
            }

            foreach (QString phase_name, phase_names)
                room->setPlayerMark(player, "LostPlayerPhase_" + phase_name, 0);
            room->addPlayerMark(player, "yhkudu");
            room->changeTranslation(player, "yhkudu", 2);
        } else {
            if (player->getMark(objectName()) > 0) return false;
            DyingStruct dying = data.value<DyingStruct>();
            if (!dying.who) return false;
            QStringList names = player->tag["YHTanyouPlayers"].toStringList();
            if (dying.who == player || names.contains(dying.who->objectName())) {
                room->sendShimingLog(player, this, false);
                room->handleAcquireDetachSkills(player, "-yhkunmo");

                foreach (QString phase_name, phase_names)
                    room->setPlayerMark(player, "LostPlayerPhase_" + phase_name, 0);
                room->addPlayerMark(player, "yhkudu");
                room->changeTranslation(player, "yhkudu", 2);
            }
        }
        return false;
    }
};

class YHTanyouBuff : public PhaseChangeSkill
{
public:
    YHTanyouBuff() : PhaseChangeSkill("#yhtanyou")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&yhtanyou_buff") > 0;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;

        Room *room = player->getRoom();
        RoomThread *thread = room->getThread();
        int mark = player->getMark("&yhtanyou_buff");

        player->setPhase(Player::Play);
        room->broadcastProperty(player, "phase");

        for (int i = 0; i < mark; i++) {
            if (player->isDead()) return false;

            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = player;
            log.arg = "yhtanyou";
            room->sendLog(log);

            if (!thread->trigger(EventPhaseStart, room, player))
                thread->trigger(EventPhaseProceeding, room, player);
            thread->trigger(EventPhaseEnd, room, player);
        }

        player->setPhase(Player::RoundStart);
        room->broadcastProperty(player, "phase");
        return false;
    }
};

class YHBozhi : public TriggerSkill
{
public:
    YHBozhi() : TriggerSkill("yhbozhi")
    {
        events << CardFinished;
        view_as_skill = new YHBozhiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("BasicCard")) return false;
        QString name = player->property("YHBozhiRecordTrick").toString();
        if (name.isEmpty()) return false;
        Card *c = Sanguosha->cloneCard(name, Card::NoSuit, 0);
        if (!c) return false;
        c->setSkillName(objectName());
        c->deleteLater();
        if (!player->canUse(c)) return false;
        if (c->targetFixed()) {
            if (!player->askForSkillInvoke(this, "yhbozhi:" + name, false)) return false;
            room->useCard(CardUseStruct(c, player, player));
        } else
            room->askForUseCard(player, "@@yhbozhi", "@yhbozhi:" + name);
        return false;
    }
};

class YHBozhiRecord : public TriggerSkill
{
public:
    YHBozhiRecord() : TriggerSkill("#yhbozhi")
    {
        events << PreCardUsed << EventPhaseChanging;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            if (player->getPhase() == Player::NotActive) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("TrickCard"))
                room->addPlayerMark(player, "yhbozhi_trick-Clear");
            if (use.card->isNDTrick()) {
                QString name = player->property("YHBozhiRecordTrick").toString();
                if (!name.isEmpty()) return false;
                room->setPlayerProperty(player, "YHBozhiRecordTrick", use.card->objectName());
            }
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setPlayerProperty(player, "YHBozhiRecordTrick", QString());
        }
        return false;
    }
};

class YHJixiang : public TriggerSkill
{
public:
    YHJixiang() : TriggerSkill("yhjixiang")
    {
        events << EventPhaseEnd;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        int mark = player->getMark("yhbozhi_trick-Clear");
        mark = qMin(mark, 3);
        mark = qMax(1, mark);
        if (!player->askForSkillInvoke(this, "yhjixiang:" + QString::number(mark))) return false;
        player->peiyin(this);
        player->drawCards(mark, objectName());

        if (player->isDead() || player->isKongcheng()) return false;

        QHash<ServerPlayer *, QStringList> hash;
        QList<int> hands = player->handCards();
        int n = mark;

        while (n > 0) {
            if (player->isKongcheng()) break;

            CardsMoveStruct move = room->askForYijiStruct(player, hands, objectName(), false, false, false, n, room->getOtherPlayers(player),
                                                          CardMoveReason(), "@yhjixiang-give", false, false);
            if (!move.to || move.card_ids.isEmpty()) break;
            n -= move.card_ids.length();

            ServerPlayer *to = (ServerPlayer *)move.to;
            QStringList ids = hash[to];
            foreach (int id, move.card_ids) {
                QString str = QString::number(id);
                hands.removeOne(id);
                if (!ids.contains(str))
                    ids << str;
            }
            hash[to] = ids;
        }

        QList<CardsMoveStruct> moves;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead()) continue;
            QList<int> ids = StringList2IntList(hash[p]);
            if (ids.isEmpty()) continue;
            CardsMoveStruct move(ids, player, p, Player::PlaceHand, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_GIVE, player->objectName(), p->objectName(), objectName(), QString()));
            moves.append(move);
        }
        if (moves.isEmpty()) return false;
        room->moveCardsAtomic(moves, false);
        return false;
    }
};

class YHGuidu : public PhaseChangeSkill
{
public:
    YHGuidu() : PhaseChangeSkill("yhguidu")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        int hand = player->getHandcardNum();
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() > hand)
                players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *t = room->askForPlayerChosen(player, players, objectName(), "@yhguidu-target", true, true);
        if (!t) return false;
        player->peiyin(this);
        room->damage(DamageStruct(objectName(), player, t));
        return false;
    }
};

class YHDaobi : public TriggerSkill
{
public:
    YHDaobi() : TriggerSkill("yhdaobi")
    {
        events << Damage << Damaged;
        change_skill = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *from = damage.from, *to = damage.to;
        int n = player->getChangeSkillState(objectName());

        if (event == Damage) {
            if (n == 1 && to != player && !to->isNude()) {
                if (!player->askForSkillInvoke(this, to)) return false;
                player->peiyin(this);
                room->setChangeSkillState(player, objectName(), 2);
                int id = room->askForCardChosen(player, to, "he", objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, Sanguosha->getCard(id),
                    reason, room->getCardPlace(id) != Player::PlaceHand);
            }
        } else {
            if (n == 2 && from && from->isAlive() && from != player && !player->isNude()) {
                if (!from->askForSkillInvoke("yhdaobi_2", player, false)) return false;
                player->peiyin(this);
                room->notifySkillInvoked(player, objectName());
                LogMessage log;
                log.type = "#InvokeOthersSkill";
                log.from = from;
                log.to << player;
                log.arg = objectName();
                room->sendLog(log);
                room->setChangeSkillState(player, objectName(), 1);
                int id = room->askForCardChosen(from, player, "he", objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, from->objectName());
                room->obtainCard(from, Sanguosha->getCard(id),
                    reason, room->getCardPlace(id) != Player::PlaceHand);
            }
        }
        return false;
    }
};

class YHShanhaiVS :public OneCardViewAsSkill
{
public:
    YHShanhaiVS() :OneCardViewAsSkill("yhshanhai")
    {
        response_pattern = "@@yhshanhai";
    }

    bool viewFilter(const Card *to_select) const
    {
        Slash *slash = new Slash(Card::SuitToBeDecided, -1);
        slash->addSubcard(to_select);
        slash->setSkillName(objectName());
        slash->deleteLater();
        if (!slash->isAvailable(Self)) return false;
        QList<int> ids = StringList2IntList(Self->property("YHShanhaiGetIds").toString().split("+"));
        return ids.contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Slash *slash = new Slash(Card::SuitToBeDecided, -1);
        slash->addSubcard(originalCard);
        slash->setSkillName(objectName());
        return slash;
    }
};

class YHShanhai : public TriggerSkill
{
public:
    YHShanhai() : TriggerSkill("yhshanhai")
    {
        events << CardsMoveOneTime;
        view_as_skill = new YHShanhaiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.to != player || move.to_place != Player::PlaceHand) return false;
        QList<int> ids;
        for (int i = 0; i < move.card_ids.length(); i++) {
            if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)
                ids << move.card_ids.at(i);
        }
        if (ids.isEmpty()) return false;

        room->setPlayerProperty(player, "YHShanhaiGetIds", IntList2StringList(ids).join("+"));

        try {
            while (player->isAlive()) {  //这里其实有bug，如果插入了获得牌，之前的记录就没了
                if (!room->askForUseCard(player, "@@yhshanhai", "@yhshanhai")) break;
                QList<int> hands = player->handCards();
                foreach (int id, ids) {
                    if (!hands.contains(id))
                        ids.removeOne(id);
                }
                if (ids.isEmpty()) break;
                room->setPlayerProperty(player, "YHShanhaiGetIds", IntList2StringList(ids).join("+"));
            }
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                room->setPlayerProperty(player, "YHShanhaiGetIds", QString());
            throw triggerEvent;
        }

        room->setPlayerProperty(player, "YHShanhaiGetIds", QString());
        return false;
    }
};

class YHShanhaiTargetMod : public TargetModSkill
{
public:
    YHShanhaiTargetMod() : TargetModSkill("#yhshanhai")
    {
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *, const Card *card, const Player *) const
    {
        if (card->getSkillName() == "yhshanhai" || card->hasFlag("yhshanhai_used_slash"))
            return 1000;
        else
            return 0;
    }
};

class YHYanglian : public MasochismSkill
{
public:
    YHYanglian() : MasochismSkill("yhyanglian")
    {
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        QStringList generals = Sanguosha->getLimitedGeneralNames(), used = player->property("YHYanglianUsedYinni").toString().split("+"), yinnis;
        foreach (QString name, generals) {
            const General *gen = Sanguosha->getGeneral(name);
            if (!gen) continue;
            foreach (const Skill *sk, gen->getVisibleSkillList()) {
                if (!sk->isHideSkill() || yinnis.contains(sk->objectName()) || used.contains(sk->objectName())) continue;
                const TriggerSkill *triggerskill = Sanguosha->getTriggerSkill(sk->objectName());
                if (!triggerskill) continue;
                bool appear = false;
                if (!triggerskill->hasEvent(Appear)) {
                    foreach (const Skill *skill, Sanguosha->getRelatedSkills(sk->objectName())) {
                        const TriggerSkill *related_trigger = Sanguosha->getTriggerSkill(skill->objectName());
                        if (!related_trigger || !related_trigger->hasEvent(Appear)) continue;
                        appear = true;
                        break;
                    }
                } else
                    appear = true;
                if (!appear) continue;
                yinnis << sk->objectName();
            }
        }
        if (yinnis.isEmpty()) return;

        Room *room = player->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            if (player->isDead()) break;

            QStringList all_sk = yinnis, five_sk;
            for (int i = 0; i < 5; i++) {
                if (all_sk.isEmpty()) break;
                QString sk = all_sk.at(qrand() % all_sk.length());
                all_sk.removeOne(sk);
                five_sk << sk;
            }
            if (five_sk.isEmpty()) break;

            five_sk << "cancel";

            QString sk = room->askForChoice(player, objectName(), five_sk.join("+"), QVariant::fromValue(damage));
            if (sk == "cancel") break;

            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            player->peiyin(this);

            used = player->property("YHYanglianUsedYinni").toString().split("+");
            used << sk;
            yinnis.removeOne(sk);
            room->setPlayerProperty(player, "YHYanglianUsedYinni", used.join("+"));

            const TriggerSkill *triggerskill = Sanguosha->getTriggerSkill(sk);
            if (!triggerskill) continue;

            //const TriggerSkill *triggerskill_copy = triggerskill;

            if (!triggerskill->hasEvent(Appear)) {
                foreach (const Skill *skill, Sanguosha->getRelatedSkills(sk)) {
                    const TriggerSkill *related_trigger = Sanguosha->getTriggerSkill(skill->objectName());
                    if (!related_trigger || !related_trigger->hasEvent(Appear)) continue;
                    triggerskill = related_trigger;
                    break;
                }
            }

            room->setPlayerProperty(player, "pingjian_triggerskill", sk);
            room->getThread()->addTriggerSkill(triggerskill);

            try {
                QVariant data;
                triggerskill->trigger(Appear, room, player, data);
                if (player->isAlive() && !player->getGeneral2()) {

                    QStringList gens;
                    foreach (QString name, generals) {
                        const General *gen = Sanguosha->getGeneral(name);
                        if (!gen) continue;
                        foreach (const Skill *g_sk, gen->getVisibleSkillList()) {
                            if (g_sk->objectName() == sk) {
                                gens << name;
                                continue;
                            }
                        }
                    }
                    if (gens.isEmpty()) continue;
                    QString genn = room->askForGeneral(player, gens.join("+"));
                    if (!gens.contains(genn))
                        genn = gens.at(qrand() % gens.length());
                    room->addPlayerMark(player, "yhyanglian_add_general2-Keep");
                    room->changeHero(player, genn, false, false, true);
                }
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                    room->setPlayerProperty(player, "pingjian_triggerskill", QString());
                throw triggerEvent;
            }
            room->setPlayerProperty(player, "pingjian_triggerskill", QString());
        }
    }
};

class YHYanglianRemove : public TriggerSkill
{
public:
    YHYanglianRemove() : TriggerSkill("#yhyanglian")
    {
        events << DamageInflicted;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("yhyanglian_add_general2-Keep") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->setPlayerMark(player, "yhyanglian_add_general2-Keep", 0);
        if (!player->getGeneral2()) return false;
        room->sendCompulsoryTriggerLog(player, "yhyanglian", true, true);
        LogMessage log;
        log.type = "#YHXiandao2";
        log.arg = player->getGeneral2Name();
        log.from = player;
        room->sendLog(log);
        room->changeHero(player, QString(), false, false, true, false);
        return false;
    }
};

class YHXiandao : public PhaseChangeSkill
{
public:
    YHXiandao() : PhaseChangeSkill("yhxiandao")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;

        Room *room = player->getRoom();
        QStringList choices;
        int num = qMax(0, 4 - player->getHandcardNum());
        QString numm = QString::number(num);

        choices << "zhujiang=" + numm;
        if (player->getGeneral2())
            choices << "fujiang=" + numm;
        choices << "cancel";

        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        if (choice == "cancel") return false;

        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        player->peiyin(this);

        if (choice.startsWith("fujiang")) {
            LogMessage log;
            log.type = "#YHXiandao2";
            log.arg = player->getGeneral2Name();
            log.from = player;
            room->sendLog(log);
            room->changeHero(player, QString(), false, false, true, false);
            num = qMax(0, 4 - player->getHandcardNum());
            player->drawCards(num, objectName());
        } else {
            LogMessage log;
            log.type = "#YHXiandao1";
            log.arg = player->getGeneralName();
            log.from = player;
            room->sendLog(log);
            if (player->getGeneral2()) {
                QString name = player->getGeneral2Name();
                room->changeHero(player, QString(), false, false, true, false);
                room->changeHero(player, name, false, false, false, false);
            } else {
                room->setPlayerMark(player, "yhyanglian_add_general2-Keep", 0);
                QString name = player->isFemale() ? "sujiangf" : "sujiang";
                int maxhp = player->getMaxHp();
                int hp = player->getHp();
                General::Gender gender = player->getGender();
                room->changeHero(player, name, false, false, false, false);
                player->setGender(gender);
                player->setMaxHp(maxhp);
                room->broadcastProperty(player, "maxhp");
                player->setHp(hp);
                room->broadcastProperty(player, "hp");
            }
            num = qMax(0, 4 - player->getHandcardNum());
            player->drawCards(num, objectName());
        }
        return false;
    }
};

YinhuPackage::YinhuPackage()
    : Package("yinhu")
{
    General *yh_zhangwenyuan = new General(this, "yh_zhangwenyuan", "wei", 4);
    yh_zhangwenyuan->addSkill(new YHShecuo);
    yh_zhangwenyuan->addSkill(new YHShecuoliLimit);
    related_skills.insertMulti("yhshecuo", "#yhshecuo-limit");

    General *yh_sunquan = new General(this, "yh_sunquan", "wei", 4);
    yh_sunquan->setStartHp(3);
    yh_sunquan->addSkill(new YHYingfu);
    yh_sunquan->addSkill(new YHNabi);
    yh_sunquan->addSkill(new YHNabiTransfer);
    yh_sunquan->addSkill(new YHHuanglong);
    related_skills.insertMulti("yhnabi", "#yhnabi");

    General *yh_liuguanzhang = new General(this, "yh_liuguanzhang", "shu", 4);
    yh_liuguanzhang->addSkill(new YHYijie);
    yh_liuguanzhang->addSkill(new YHXinghan);
    yh_liuguanzhang->addSkill(new YHXinghanDraw);
    yh_liuguanzhang->addSkill(new YHXinghanTarget);
    related_skills.insertMulti("yhxinghan", "#yhxinghan-draw");
    related_skills.insertMulti("yhxinghan", "#yhxinghan-target");

    General *yh_chenshou = new General(this, "yh_chenshou", "shu", 3);
    yh_chenshou->addSkill(new YHZhushi);
    yh_chenshou->addSkill(new YHZhushiPut);
    yh_chenshou->addSkill(new Skill("yhqubi", Skill::Compulsory)); //耦合进了Room::drawCards
    yh_chenshou->addSkill(new YHShijin);
    related_skills.insertMulti("yhzhushi", "#yhzhushi");

    General *yh_zhugeliang = new General(this, "yh_zhugeliang", "wu", 3);
    yh_zhugeliang->addSkill(new YHBianzhan);
    yh_zhugeliang->addSkill(new YHJifeng);
    yh_zhugeliang->addSkill(new YHJifengEffect);

    General *yh_wangfan = new General(this, "yh_wangfan", "wu", 3);
    yh_wangfan->addSkill(new YHHuntian);
    yh_wangfan->addSkill(new YHCeri);

    General *yh_caocao = new General(this, "yh_caocao", "qun", 4);
    yh_caocao->addSkill(new YHSancai);
    yh_caocao->addSkill(new YHSancaiAttackRange);
    yh_caocao->addSkill(new YHJuyi);
    related_skills.insertMulti("yhsancai", "#yhsancai");

    General *yh_xunyu = new General(this, "yh_xunyu", "qun", 3);
    yh_xunyu->addSkill(new YHHanjie);
    yh_xunyu->addSkill(new YHJuxian);

    General *yh_zhanghua = new General(this, "yh_zhanghua", "jin", 3);
    yh_zhanghua->addSkill(new YHDujian);
    yh_zhanghua->addSkill(new YHDujianTarget);
    yh_zhanghua->addSkill(new YHBuque);
    yh_zhanghua->addSkill(new YHBuquePindian);
    yh_zhanghua->addSkill(new YHZhanghua("yhbuque"));
    yh_zhanghua->addSkill(new YHChenzhen);
    yh_zhanghua->addSkill(new YHZhanghua("yhchenzhen"));
    related_skills.insertMulti("yhdujian", "#yhdujian");
    related_skills.insertMulti("yhbuque", "#yhbuque");
    related_skills.insertMulti("yhbuque", "#yhbuque-move");
    related_skills.insertMulti("yhchenzhen", "#yhchenzhen-move");

    General *yh_liushan = new General(this, "yh_liushan", "jin", 3);
    yh_liushan->addSkill(new YHSigong);
    yh_liushan->addSkill(new YHSigongEffect);
    yh_liushan->addSkill(new YHXijian);
    yh_liushan->addSkill(new YHXijianEffect);
    related_skills.insertMulti("yhsigong", "#yhsigong");
    related_skills.insertMulti("yhxijian", "#yhxijian");

    General *yh_shenxuchu = new General(this, "yh_shenxuchu", "god", 4);
    yh_shenxuchu->addSkill(new YHBoben);
    yh_shenxuchu->addSkill(new YHBobenDamage);
    yh_shenxuchu->addSkill(new YHHankai);
    yh_shenxuchu->addSkill(new YHHankaiEffect);
    yh_shenxuchu->addSkill(new YHHankaiLimit);
    related_skills.insertMulti("yhboben", "#yhboben");
    related_skills.insertMulti("yhhankai", "#yhhankai");
    related_skills.insertMulti("yhhankai", "#yhhankai-limit");

    General *yh_shenmachao = new General(this, "yh_shenmachao", "god", 4);
    yh_shenmachao->addSkill(new YHFeisha);
    yh_shenmachao->addSkill(new YHJuantu);
    yh_shenmachao->addSkill(new YHJuantuNumber);
    yh_shenmachao->addSkill(new YHJuantuClear);
    yh_shenmachao->addSkill(new YHQuanwang);
    yh_shenmachao->addRelateSkill("yhchouxi");
    related_skills.insertMulti("yhjuantu", "#yhjuantu");
    related_skills.insertMulti("yhjuantu", "#yhjuantu-clear");

    General *yh_nvzhuangsimayi = new General(this, "yh_nvzhuangsimayi", "wei", 4, false);
    yh_nvzhuangsimayi->setStartHp(3);
    yh_nvzhuangsimayi->addSkill(new YHChenwen);
    yh_nvzhuangsimayi->addSkill(new YHShouzhuang);
    yh_nvzhuangsimayi->addSkill(new YHPodi);
    yh_nvzhuangsimayi->addSkill(new YHPodiInvalidity);
    yh_nvzhuangsimayi->addSkill(new YHPodiTargetMod);
    related_skills.insertMulti("yhpodi", "#yhpodi-inv");
    related_skills.insertMulti("yhpodi", "#yhpodi-target");

    General *yh_dingfuren = new General(this, "yh_dingfuren", "wei", 3, false);
    yh_dingfuren->addSkill(new YHDuwei);
    yh_dingfuren->addSkill(new YHDuweiTargetMod);
    yh_dingfuren->addSkill(new YHSiku);
    related_skills.insertMulti("yhduwei", "#yhduwei");

    General *yh_cuifuren = new General(this, "yh_cuifuren", "shu", 3, false);
    yh_cuifuren->addSkill(new YHQingsi);
    yh_cuifuren->addSkill(new YHChuzhu);
    yh_cuifuren->addSkill(new YHChuzhuMark);
    related_skills.insertMulti("yhchuzhu", "#yhchuzhu");

    General *yh_liumu = new General(this, "yh_liumu", "shu", 3, false);
    yh_liumu->addSkill(new YHHuairen);
    yh_liumu->addSkill(new YHHuairenEffect);
    yh_liumu->addSkill(new YHHuairenLimit);
    yh_liumu->addSkill(new YHYuren);
    related_skills.insertMulti("yhhuairen", "#yhhuairen");
    related_skills.insertMulti("yhhuairen", "#yhhuairen-limit");

    General *yh_zhupeilan = new General(this, "yh_zhupeilan", "wu", 3, false);
    yh_zhupeilan->addSkill(new YHRangwei);
    yh_zhupeilan->addSkill(new YHPosi);

    General *yh_sunlubansunluyu = new General(this, "yh_sunlubansunluyu", "wu", 3, false);
    yh_sunlubansunluyu->addSkill(new YHXiaoyun);
    yh_sunlubansunluyu->addSkill(new YHMeiying);

    General *yh_liufuren = new General(this, "yh_liufuren", "qun", 3, false);
    yh_liufuren->addSkill(new YHKudu);
    yh_liufuren->addSkill(new YHKuduSkip);
    yh_liufuren->addSkill(new YHKunmo);
    yh_liufuren->addSkill(new YHTanyou);
    yh_liufuren->addSkill(new YHTanyouBuff);
    related_skills.insertMulti("yhtanyou", "#yhtanyou");

    General *yh_zhenji = new General(this, "yh_zhenji", "qun", 3, false);
    yh_zhenji->addSkill(new YHBozhi);
    yh_zhenji->addSkill(new YHBozhiRecord);
    yh_zhenji->addSkill(new YHJixiang);
    related_skills.insertMulti("yhbozhi", "#yhbozhi");

    General *yh_jiananfeng = new General(this, "yh_jiananfeng", "jin", 3, false);
    yh_jiananfeng->addSkill(new YHGuidu);
    yh_jiananfeng->addSkill(new YHDaobi);
    yh_jiananfeng->addSkill(new YHShanhai);
    yh_jiananfeng->addSkill(new YHShanhaiTargetMod);
    related_skills.insertMulti("yhshanhai", "#yhshanhai");

    General *yh_weihuacun = new General(this, "yh_weihuacun", "jin", 3, false);
    yh_weihuacun->addSkill(new YHYanglian);
    yh_weihuacun->addSkill(new YHYanglianRemove);
    yh_weihuacun->addSkill(new YHXiandao);
    related_skills.insertMulti("yhyanglian", "#yhyanglian");

    addMetaObject<YHShecuoCard>();
    addMetaObject<YHYijieCard>();
    addMetaObject<YHZhushiCard>();
    addMetaObject<YHBianzhanCard>();
    addMetaObject<YHHuntianCard>();
    addMetaObject<YHJuxianCard>();
    addMetaObject<YHBuquePutCard>();
    addMetaObject<YHBuqueCard>();
    addMetaObject<YHXijianGiveCard>();
    addMetaObject<YHQuanwangCard>();
    addMetaObject<YHPodiCard>();
    addMetaObject<YHYurenCard>();
    addMetaObject<YHMeiyingCard>();
    addMetaObject<YHKunmoCard>();

    skills << new YHBuquePut << new YHXijianGive << new YHChouxi << new YHChouxiDamage;
    related_skills.insertMulti("yhchouxi", "#yhchouxi");
}

ADD_PACKAGE(Yinhu)
