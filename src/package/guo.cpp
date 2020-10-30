#include "guo.h"
#include "skill.h"
#include "standard.h"
#include "clientplayer.h"
#include "engine.h"
#include "settings.h"
#include "standard-skillcards.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "yingbian.h"

class JinTuishi : public TriggerSkill
{
public:
    JinTuishi() : TriggerSkill("jintuishi")
    {
        events << Appear;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent() || room->getCurrent() == player) return false;
        room->setPlayerMark(player, "&jintuishi-Clear", 1);
        return false;
    }
};

class JinTuishiEffect : public TriggerSkill
{
public:
    JinTuishiEffect() : TriggerSkill("#jintuishi-effect")
    {
        events << EventPhaseChanging;
        hide_skill = true;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || p->getMark("&jintuishi-Clear") <= 0) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *pl, room->getOtherPlayers(player)) {
                if (player->inMyAttackRange(pl) && player->canSlash(pl, NULL, true))
                    targets << pl;
            }
            if (targets.isEmpty()) return false;
            p->tag["jintuishi_from"] = QVariant::fromValue(player);
            ServerPlayer * target = room->askForPlayerChosen(p, targets, "jintuishi", "@jintuishi-invoke:" + player->objectName(), true);
            p->tag.remove("jintuishi_from");
            if (!target) continue;

            room->doAnimate(1, p->objectName(), target->objectName());
            LogMessage log;
            log.type = "#JinTuishiSlash";
            log.from = p;
            log.arg = "jintuishi";
            log.arg2 = "slash";
            log.to << target;
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(p, objectName());

            if (room->askForUseSlashTo(player, target, "@jintuishi_slash:" + target->objectName(), true, false, true, p)) continue;
            room->damage(DamageStruct("jintuishi", p, player));
        }

        return false;
    }
};

JinChoufaCard::JinChoufaCard()
{
}

bool JinChoufaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void JinChoufaCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isKongcheng()) return;
    const Card *card = effect.to->getRandomHandCard();
    Room *room = effect.from->getRoom();
    room->showCard(effect.to, card->getEffectiveId());

    room->addPlayerMark(effect.to, "jinchoufa_target");
    foreach (const Card *c, effect.to->getCards("h")) {
        if (c->getTypeId() == card->getTypeId()) continue;
        Slash *slash = new Slash(c->getSuit(), c->getNumber());
        slash->setSkillName("jinchoufa");
        WrappedCard *card = Sanguosha->getWrappedCard(c->getId());
        card->takeOver(slash);
        room->notifyUpdateCard(effect.to, c->getEffectiveId(), card);
    }
}

class JinChoufaVS : public ZeroCardViewAsSkill
{
public:
    JinChoufaVS() : ZeroCardViewAsSkill("jinchoufa")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JinChoufaCard");
    }

    const Card *viewAs() const
    {
        return new JinChoufaCard;
    }
};

class JinChoufa : public TriggerSkill
{
public:
    JinChoufa() : TriggerSkill("jinchoufa")
    {
        events << EventPhaseChanging;
        view_as_skill = new JinChoufaVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        if (player->getMark("jinchoufa_target") <= 0) return false;
        room->setPlayerMark(player, "jinchoufa_target", 0);
        room->filterCards(player, player->getCards("he"), true);
        return false;
    }
};

class JinZhaoran : public PhaseChangeSkill
{
public:
    JinZhaoran() : PhaseChangeSkill("jinzhaoran")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, "HandcardVisible_ALL-PlayClear");
        room->addPlayerMark(player, "jinzhaoran-PlayClear");
        if (!player->isKongcheng())
            room->showAllCards(player);
        return false;
    }
};

class JinZhaoranEffect : public TriggerSkill
{
public:
    JinZhaoranEffect() : TriggerSkill("#jinzhaoran-effect")
    {
        events << BeforeCardsMove;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    int getPriority(TriggerEvent) const
    {
        return 4;
    }

    bool isLastSuit(ServerPlayer *player, const Card *card) const
    {
        foreach (const Card *c, player->getHandcards()) {
            if (c == card) continue;
            if (c->getSuit() == card->getSuit())
                return false;
        }
        return true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from != player || move.from->getPhase() != Player::Play || !move.from_places.contains(Player::PlaceHand)) return false;
        if (player->getMark("jinzhaoran-PlayClear") <= 0) return false;

        for (int i = 0; i< move.card_ids.length(); i++) {
            if (player->isDead()) return false;
            const Card *card = Sanguosha->getCard(move.card_ids.at(i));
            if (move.from_places.at(i) != Player::PlaceHand) continue;
            if (player->getMark("jinzhaoran_suit" + card->getSuitString() + "-PlayClear") > 0) continue;
            if (!isLastSuit(player, card)) continue;

            room->sendCompulsoryTriggerLog(player, "jinzhaoran", true, true);
            room->addPlayerMark(player, "jinzhaoran_suit" + card->getSuitString() + "-PlayClear");

            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->canDiscard(p, "he"))
                    targets << p;
            }
            if (targets.isEmpty())
                player->drawCards(1, "jinzhaoran");
            else {
                ServerPlayer *target = room->askForPlayerChosen(player, targets, "jinzhaoran", "@jinzhaoran-discard", true);
                if (!target)
                    player->drawCards(1, "jinzhaoran");
                else {
                    room->doAnimate(1, player->objectName(), target->objectName());
                    if (!player->canDiscard(target, "he")) continue;
                    int id = room->askForCardChosen(player, target, "he", "jinzhaoran", false, Card::MethodDiscard);
                    room->throwCard(Sanguosha->getCard(id), target, player);
                }
            }
        }
        return false;
    }
};

class JinShiren : public TriggerSkill
{
public:
    JinShiren() : TriggerSkill("jinshiren")
    {
        events << Appear;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent(true) || room->getCurrent() == player) return false;
        if (room->getCurrent()->isKongcheng()) return false;
        JinYanxiCard *yanxi_card = new JinYanxiCard;
        yanxi_card->setSkillName("jinyanxi");
        yanxi_card->deleteLater();
        if (player->isProhibited(room->getCurrent(), yanxi_card)) return false;
        if (!player->askForSkillInvoke(this, room->getCurrent())) return false;
        room->broadcastSkillInvoke(objectName());
        room->useCard(CardUseStruct(yanxi_card, player, room->getCurrent()), true);
        return false;
    }
};

JinYanxiCard::JinYanxiCard()
{
}

bool JinYanxiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void JinYanxiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isKongcheng()) return;
    Room *room = effect.from->getRoom();
    int hand_id = effect.to->getRandomHandCardId();
    QList<int> list = room->getNCards(2, false);
    QList<int> new_list;
    room->returnToTopDrawPile(list);
    list << hand_id;
    //qShuffle(list);
    for (int i = 0; i < 3; i++) {
        int id = list.at(qrand() % list.length());
        new_list << id;
        list.removeOne(id);
        if (list.isEmpty()) break;
    }
    if (new_list.isEmpty()) return;

    room->fillAG(new_list, effect.from);
    int id = room->askForAG(effect.from, new_list, false, "jinyanxi");
    room->clearAG(effect.from);

    CardMoveReason reason1(CardMoveReason::S_REASON_UNKNOWN, effect.from->objectName(), "jinyanxi", QString());
    CardMoveReason reason2(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName(), "jinyanxi", QString());
    if (id == hand_id) {
        QList<CardsMoveStruct> exchangeMove;
        new_list.removeOne(hand_id);
        CardsMoveStruct move1(QList<int>() << hand_id, effect.to,  effect.from, Player::PlaceHand, Player::PlaceHand, reason2);
        CardsMoveStruct move2(new_list, effect.from, Player::PlaceHand, reason1);
        exchangeMove.append(move1);
        exchangeMove.append(move2);
        room->moveCardsAtomic(exchangeMove, false);
    } else {
        DummyCard dummy;
        dummy.addSubcard(id);
        room->obtainCard(effect.from, &dummy, reason1, false);
    }
}

class JinYanxiVS : public ZeroCardViewAsSkill
{
public:
    JinYanxiVS() : ZeroCardViewAsSkill("jinyanxi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JinYanxiCard");
    }

    const Card *viewAs() const
    {
        return new JinYanxiCard;
    }
};

class JinYanxi : public TriggerSkill
{
public:
    JinYanxi() : TriggerSkill("jinyanxi")
    {
        events << CardsMoveOneTime;
        view_as_skill = new JinYanxiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.reason.m_skillName != objectName()) return false;
        if (!move.to || move.to != player || move.to_place != Player::PlaceHand || move.to->getPhase() == Player::NotActive) return false;
        room->ignoreCards(player, move.card_ids);
        return false;
    }
};

JinSanchenCard::JinSanchenCard()
{
}

bool JinSanchenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getMark("jinsanchen_target-Clear") <= 0;
}

void JinSanchenCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.from, "&jinsanchen");
    room->addPlayerMark(effect.to, "jinsanchen_target-Clear");
    effect.to->drawCards(3, "jinsanchen");
    if (effect.to->isDead() || !effect.to->canDiscard(effect.to, "he")) return;
    const Card *card = room->askForDiscard(effect.to, "jinsanchen", 3, 3, false, true, "jinsanchen-discard");
    if (!card) return;
    QList<int> types;
    bool flag = true;
    foreach (int id, card->getSubcards()) {
        int type_id = Sanguosha->getCard(id)->getTypeId();
        if (!types.contains(type_id))
            types << type_id;
        else {
            flag = false;
            break;
        }
    }
    if (!flag) return;
    effect.to->drawCards(1, "jinsanchen");
    room->addPlayerMark(effect.from, "jinsanchen_times-PlayClear");
}

class JinSanchen : public ZeroCardViewAsSkill
{
public:
    JinSanchen() : ZeroCardViewAsSkill("jinsanchen")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("JinSanchenCard") < 1 + player->getMark("jinsanchen_times-PlayClear");
    }

    const Card *viewAs() const
    {
        return new JinSanchenCard;
    }
};

class JinZhaotao : public PhaseChangeSkill
{
public:
    JinZhaotao() : PhaseChangeSkill("jinzhaotao")
    {
        frequency = Wake;
        waked_skills = "jinpozhu";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark("jinzhaotao") > 0) return false;
        if (player->canWake("jinzhaotao")) return true;
        if (player->getMark("&jinsanchen") >= 3) {
            LogMessage log;
            log.type = "#JinZhaotaoWake";
            log.from = player;
            log.arg = QString::number(player->getMark("&jinsanchen"));
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("jin_duyu", "jinzhaotao");
        room->setPlayerMark(player, "jinzhaotao", 1);

        if (room->changeMaxHpForAwakenSkill(player))
            room->handleAcquireDetachSkills(player, "jinpozhu");
        return false;
    }
};

class JinPozhuVS : public OneCardViewAsSkill
{
public:
    JinPozhuVS() : OneCardViewAsSkill("jinpozhu")
    {
        filter_pattern = ".|.|.|hand";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("jinpozhu_wuxiao-Clear") <= 0;
    }

    const Card *viewAs(const Card *card) const
    {
        Chuqibuyi *c = new Chuqibuyi(card->getSuit(), card->getNumber());
        c->addSubcard(card);
        c->setSkillName(objectName());
        return c;
    }
};

class JinPozhu : public TriggerSkill
{
public:
    JinPozhu() : TriggerSkill("jinpozhu")
    {
        events << DamageDone << CardFinished;
        view_as_skill = new JinPozhuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Chuqibuyi") || damage.card->getSkillName() != "jinpozhu" ||
                    !damage.from || damage.from->isDead() || damage.from->getPhase() != Player::Play) return false;
            room->setCardFlag(damage.card, "jinpozhu_damage");
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Chuqibuyi") || !use.from || use.from->isDead() || use.card->getSkillName() != "jinpozhu" ||
                    use.from->getPhase() != Player::Play) return false;
            if (use.card->hasFlag("jinpozhu_damage")) return false;
            room->addPlayerMark(use.from, "jinpozhu_wuxiao-Clear");
        }
        return false;
    }
};

class JinZhongyun : public TriggerSkill
{
public:
    JinZhongyun() : TriggerSkill("jinzhongyun")
    {
        events << Damaged << HpRecover << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        if (event == Damaged || event == HpRecover) {
            if (player->getMark("jinzhongyun_hp-Clear") > 0 || player->getHp() != player->getHandcardNum()) return false;
            QStringList choices;
            if (player->isWounded())
                choices << "recover";
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->inMyAttackRange(p))
                    targets << p;
            }
            if (!targets.isEmpty())
                choices << "damage";
            if (choices.isEmpty()) return false;

            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->addPlayerMark(player, "jinzhongyun_hp-Clear");

            QString choice = room->askForChoice(player, objectName(), choices.join("+"));
            if (choice == "recover")
                room->recover(player, RecoverStruct(player));
            else {
                ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@jinzhongyun-damage");
                room->doAnimate(1, player->objectName(), target->objectName());
                room->damage(DamageStruct(objectName(), player, target));
            }
        } else {
            if (room->getTag("FirstRound").toBool()) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (player->getMark("jinzhongyun_move-Clear") > 0 || player->getHp() != player->getHandcardNum()) return false;
            bool can_trigger = false;
            if (move.from == player && move.from_places.contains(Player::PlaceHand))
                can_trigger = true;
            else if (move.to == player && move.to_place == Player::PlaceHand)
                can_trigger = true;
            if (!can_trigger) return false;

            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->addPlayerMark(player, "jinzhongyun_move-Clear");

            QStringList choices;
            choices << "draw";
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->canDiscard(p, "he"))
                    targets << p;
            }
            if (!targets.isEmpty())
                choices << "discard";
            QString choice = room->askForChoice(player, objectName(), choices.join("+"));
            if (choice == "draw")
                player->drawCards(1, objectName());
            else {
                ServerPlayer *target = room->askForPlayerChosen(player, targets, "jinzhongyun_discard", "@jinzhongyun-discard");
                if (!player->canDiscard(target, "he")) return false;
                room->doAnimate(1, player->objectName(), target->objectName());
                int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
                room->throwCard(id, target, player);
            }
        }
        return false;
    }
};

class JinShenpin : public RetrialSkill
{
public:
    JinShenpin() : RetrialSkill("jinshenpin")
    {
    }

    const Card *onRetrial(ServerPlayer *player, JudgeStruct *judge) const
    {
        if (player->isNude())
            return NULL;

        QStringList prompt_list;
        prompt_list << "@jinshenpin-card" << judge->who->objectName()
            << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");

        Room *room = player->getRoom();
        QString color;
        if (judge->card->isRed())
            color = "black";
        else if (judge->card->isBlack())
            color = "red";
        if (color.isEmpty()) return NULL;

        const Card *card = room->askForCard(player, ".|" + color, prompt, QVariant::fromValue(judge), Card::MethodResponse, judge->who, true);

        if (card)
            room->broadcastSkillInvoke(objectName());
        return card;
    }
};

class JinGaoling : public TriggerSkill
{
public:
    JinGaoling() : TriggerSkill("jingaoling")
    {
        events << Appear;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent() || room->getCurrent() == player) return false;
        QList<ServerPlayer *> wounded;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isWounded())
                wounded << p;
        }
        if (wounded.isEmpty()) return false;

        ServerPlayer *to = room->askForPlayerChosen(player, wounded, objectName(), "@jingaoling-invoke", true, true);
        if (!to) return false;
        room->broadcastSkillInvoke(this);

        room->recover(to, RecoverStruct(player));
        return false;
    }
};

class JinQimei : public PhaseChangeSkill
{
public:
    JinQimei() : PhaseChangeSkill("jinqimei")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        ServerPlayer *to = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@jinqimei-invoke", true, true);
        if (!to) return false;
        room->broadcastSkillInvoke(this);

        room->setPlayerMark(player, "&jinqimei_self+#" + to->objectName(), 1);
        room->setPlayerMark(to, "&jinqimei+#" + player->objectName(), 1);
        return false;
    }
};

class JinQimeiEffect : public TriggerSkill
{
public:
    JinQimeiEffect() : TriggerSkill("#jinqimei-effect")
    {
        events << EventPhaseStart << HpChanged << Death << CardsMoveOneTime;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            foreach (QString mark, player->getMarkNames()) {
                if (mark.startsWith("&jinqimei_self+#"))
                    room->setPlayerMark(player, mark, 0);
            }
            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                room->setPlayerMark(p, "&jinqimei+#" + player->objectName(), 0);
        } else if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                room->setPlayerMark(p, "&jinqimei+#" + player->objectName(), 0);
        } else if (event == HpChanged) {
            if (player->isDead()) return false;
            QList<ServerPlayer *> drawers;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                int mark = p->getMark("&jinqimei_self+#" + player->objectName());
                if (mark > 0 && player->getMark("jinqimei_self_hp" + p->objectName() + "-Clear") <= 0 &&
                        p->getMark("jinqimei_hp" + player->objectName() + "-Clear") <= 0 && player->getHp() == p->getHp()) {
                    drawers << p;
                    room->addPlayerMark(player, "jinqimei_self_hp" + p->objectName() + "-Clear");
                    room->addPlayerMark(p, "jinqimei_hp" + player->objectName() + "-Clear");
                }

            }
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                int mark = p->getMark("&jinqimei+#" + player->objectName());
                if (mark > 0 && p->getMark("jinqimei_self_hp" + player->objectName() + "-Clear") <= 0 &&
                        player->getMark("jinqimei_hp" + p->objectName() + "-Clear") <= 0 && player->getHp() == p->getHp()) {
                    drawers << p;
                    room->addPlayerMark(p, "jinqimei_self_hp" + player->objectName() + "-Clear");
                    room->addPlayerMark(player, "jinqimei_hp" + p->objectName() + "-Clear");
                }

            }
            if (!drawers.isEmpty()) {
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = player;
                log.arg = "jinqimei";
                room->sendLog(log);
                room->broadcastSkillInvoke("jinqimei");
            }
            room->drawCards(drawers, 1, objectName());
        } else {
            if (player->isDead()) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if ((move.to == player && move.to_place == Player::PlaceHand) ||
                    (move.from == player && move.from_places.contains(Player::PlaceHand))) {
                QList<ServerPlayer *> drawers;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    int mark = p->getMark("&jinqimei_self+#" + player->objectName());
                    if (mark > 0 && player->getMark("jinqimei_self_move" + p->objectName() + "-Clear") <= 0 &&
                       p->getMark("jinqimei_move" + player->objectName() + "-Clear") <= 0 && player->getHandcardNum() == p->getHandcardNum()) {
                        drawers << p;
                        room->addPlayerMark(player, "jinqimei_self_move" + p->objectName() + "-Clear");
                        room->addPlayerMark(p, "jinqimei_move" + player->objectName() + "-Clear");
                    }
                }
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    int mark = p->getMark("&jinqimei+#" + player->objectName());
                    if (mark > 0 && p->getMark("jinqimei_self_move" + player->objectName() + "-Clear") <= 0 &&
                       player->getMark("jinqimei_move" + p->objectName() + "-Clear") <= 0 && player->getHandcardNum() == p->getHandcardNum()) {
                        drawers << p;
                        room->addPlayerMark(p, "jinqimei_self_move" + player->objectName() + "-Clear");
                        room->addPlayerMark(player, "jinqimei_move" + p->objectName() + "-Clear");
                    }
                }
                if (!drawers.isEmpty()) {
                    LogMessage log;
                    log.type = "#ZhenguEffect";
                    log.from = player;
                    log.arg = "jinqimei";
                    room->sendLog(log);
                    room->broadcastSkillInvoke("jinqimei");
                }
                room->drawCards(drawers, 1, objectName());
            }
        }
        return false;
    }
};

class JinZhuiji : public PhaseChangeSkill
{
public:
    JinZhuiji() : PhaseChangeSkill("jinzhuiji")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(this);

        QStringList choices;
        if (player->isWounded())
            choices << "recover";
        choices << "draw";

        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        room->addPlayerMark(player, "jinzhuiji_" + choice + "-PlayClear");

        if (choice == "recover")
            room->recover(player, RecoverStruct(player));
        else
            player->drawCards(2, objectName());
        return false;
    }
};

class JinZhuijiEffect : public TriggerSkill
{
public:
    JinZhuijiEffect() : TriggerSkill("#jinzhuiji-effect")
    {
        events << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        int recover = player->getMark("jinzhuiji_recover-PlayClear"), draw = player->getMark("jinzhuiji_draw-PlayClear");
        bool send = true;

        for (int i = 0; i < recover; i++) {
            if (!player->canDiscard(player, "he")) break;
            if (i == 0) {
                send = false;
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = player;
                log.arg = "jinzhuiji";
                room->sendLog(log);
                room->notifySkillInvoked(player, "jinzhuiji");
                room->broadcastSkillInvoke("jinzhuiji");
            }
            room->askForDiscard(player, "jinzhuiji", 2, 2, false, true);
        }

        for (int i = 0; i < draw; i++) {
            if (player->isDead()) break;
            if (i == 0 && send) {
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = player;
                log.arg = "jinzhuiji";
                room->sendLog(log);
                room->notifySkillInvoked(player, "jinzhuiji");
                room->broadcastSkillInvoke("jinzhuiji");
            }
            room->loseHp(player);
        }
        return false;
    }
};

GuoPackage::GuoPackage()
    : Package("guo")
{

    General *jin_simazhao = new General(this, "jin_simazhao$", "jin", 3);
    jin_simazhao->addSkill(new JinTuishi);
    jin_simazhao->addSkill(new JinTuishiEffect);
    jin_simazhao->addSkill(new JinChoufa);
    jin_simazhao->addSkill(new JinZhaoran);
    jin_simazhao->addSkill(new JinZhaoranEffect);
    jin_simazhao->addSkill(new Skill("jinchengwu$", Skill::Compulsory));
    related_skills.insertMulti("jintuishi", "#jintuishi-effect");
    related_skills.insertMulti("jinzhaoran", "#jinzhaoran-effect");

    General *jin_wangyuanji = new General(this, "jin_wangyuanji", "jin", 3, false);
    jin_wangyuanji->addSkill(new JinShiren);
    jin_wangyuanji->addSkill(new JinYanxi);

    General *jin_duyu = new General(this, "jin_duyu", "jin", 4);
    jin_duyu->addSkill(new JinSanchen);
    jin_duyu->addSkill(new JinZhaotao);
    jin_duyu->addRelateSkill("jinpozhu");

    General *jin_weiguan = new General(this, "jin_weiguan", "jin", 3);
    jin_weiguan->addSkill(new JinZhongyun);
    jin_weiguan->addSkill(new JinShenpin);

    General *jin_xuangongzhu = new General(this, "jin_xuangongzhu", "jin", 3, false);
    jin_xuangongzhu->addSkill(new JinGaoling);
    jin_xuangongzhu->addSkill(new JinQimei);
    jin_xuangongzhu->addSkill(new JinQimeiEffect);
    jin_xuangongzhu->addSkill(new JinZhuiji);
    jin_xuangongzhu->addSkill(new JinZhuijiEffect);
    related_skills.insertMulti("jinqimei", "#jinqimei-effect");
    related_skills.insertMulti("jinzhuiji", "#jinzhuiji-effect");

    addMetaObject<JinChoufaCard>();
    addMetaObject<JinYanxiCard>();
    addMetaObject<JinSanchenCard>();

    skills << new JinPozhu;
}

ADD_PACKAGE(Guo)
