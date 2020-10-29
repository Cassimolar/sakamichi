#include "yczh2017.h"
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

class Jianzheng : public TriggerSkill
{
public:
    Jianzheng() : TriggerSkill("jianzheng")
    {
        events << TargetSpecifying;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (!p->hasSkill(objectName())) continue;
            if (use.to.isEmpty() || use.to.contains(p) || !use.from->inMyAttackRange(p) || p->isKongcheng()) continue;
            const Card *card = room->askForCard(p, ".|.|.|hand", "jianzheng-invoke", data, Card::MethodNone);
            if (!card) continue;
            room->moveCardTo(card, NULL, Player::DrawPile, false);
            use.to = QList<ServerPlayer *>();
            if (!use.card->isBlack())
                use.to << p;
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class Zhuandui : public TriggerSkill
{
public:
    Zhuandui() : TriggerSkill("zhuandui")
    {
        events << TargetSpecified << TargetConfirmed;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        if (event == TargetSpecified) {
            QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();
            int index = 0;
            foreach (ServerPlayer *p, use.to) {
                if (!player->isAlive()) break;
                if (player->canPindian(p) && player->askForSkillInvoke(this, QVariant::fromValue(p))) {
                    room->broadcastSkillInvoke(objectName());
                    if (player->pindian(p, objectName())) {
                        LogMessage log;
                        log.type = "#NoJink";
                        log.from = p;
                        room->sendLog(log);
                        jink_list.replace(index, QVariant(0));
                    }
                }
                index++;
            }
            player->tag["Jink_" + use.card->toString()] = QVariant::fromValue(jink_list);
        } else {
            if (use.from->isAlive() && use.to.contains(player) && player->canPindian(use.from) &&
                    player->askForSkillInvoke(this, QVariant::fromValue(use.from))) {
                if (player->pindian(use.from, objectName())) {
                    use.nullified_list << player->objectName();
                    data = QVariant::fromValue(use);
                }
            }
        }
        return false;
    }
};

class Tianbian : public TriggerSkill
{
public:
    Tianbian() : TriggerSkill("tianbian")
    {
        events << AskforPindianCard << PindianVerifying;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == AskforPindianCard) {
            if (!player->hasSkill(objectName())) return false;
            QStringList pindian = data.toStringList();
            if (pindian.at(0) == player->objectName()) {
                if (pindian.at(2).toInt() && pindian.at(2).toInt() > 0) return false;
                if (!player->askForSkillInvoke(this, data)) return false;
                room->broadcastSkillInvoke(objectName());
                QStringList newpindian;
                newpindian << pindian.at(0);
                newpindian << pindian.at(1);
                newpindian << QString::number(room->drawCard());
                newpindian << pindian.at(3);
                data = QVariant::fromValue(newpindian);
            } else if (pindian.at(1) == player->objectName()) {
                if (pindian.at(3).toInt() && pindian.at(3).toInt() > 0) return false;
                if (!player->askForSkillInvoke(this, data)) return false;
                room->broadcastSkillInvoke(objectName());
                QStringList newpindian;
                newpindian << pindian.at(0);
                newpindian << pindian.at(1);
                newpindian << pindian.at(2);
                newpindian << QString::number(room->drawCard());
                data = QVariant::fromValue(newpindian);
            }
        } else {
            PindianStruct *pindian = data.value<PindianStruct *>();
            if ((pindian->from->hasSkill(this) && pindian->from_card->getSuit() == Card::Heart) ||
                    (pindian->to->hasSkill(this) && pindian->to_card->getSuit() == Card::Heart)) {
                LogMessage log;
                log.type = "#TianbianK";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                if (pindian->from->objectName() == player->objectName())
                    pindian->from_number = 13;
                else
                    pindian->to_number = 13;
                data = QVariant::fromValue(pindian);
            }
        }
        return false;
    }
};

FumianCard::FumianCard()
{
    mute = true;
}

bool FumianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < Self->getMark("fumian_extra_target-Clear") && to_select->hasFlag("fumian_canchoose");
}

void FumianCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "fumian_extratarget");
}

class FumianVS : public ZeroCardViewAsSkill
{
public:
    FumianVS() : ZeroCardViewAsSkill("fumian")
    {
        response_pattern = "@@fumian";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        if (Self->hasFlag("fumian_now_use_collateral"))
            return new ExtraCollateralCard;
        else
            return new FumianCard;
    }
};

class Fumian : public TriggerSkill
{
public:
    Fumian() : TriggerSkill("fumian")
    {
        events << EventPhaseStart << DrawNCards << PreCardUsed;
        view_as_skill = new FumianVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Start) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            int n = 1;
            QString last_choice = player->property("fumian_choice").toString();
            QString choice = room->askForChoice(player, objectName(), "draw+target");
            LogMessage log;
            log.type = last_choice != NULL ? "#FumianChoice" : "#FumianFirstChoice";
            log.from = player;
            log.arg = "fumian:" + choice;
            log.arg2 = (last_choice != NULL && choice == last_choice) ? "fumiansame" : "fumiandifferent";
            room->sendLog(log);
            if (last_choice != NULL && choice != last_choice) n = 2;
            if (choice == "draw")
                room->addPlayerMark(player, "fumian_draw-Clear", n);
            else
                room->addPlayerMark(player, "fumian_target-Clear", n);
            room->setPlayerProperty(player, "fumian_choice", choice);
        } else if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            int n = player->getMark("fumian_target-Clear");
            if (n <= 0) return false;
            if (!use.card->isRed() || use.card->isKindOf("SkillCard") || player->getPhase() == Player::NotActive) return false;
            room->setPlayerMark(player, "fumian_target-Clear", 0);
            room->setPlayerMark(player, "fumian_extra_target-Clear", n);
            if (!use.card->isKindOf("BasicCard") && !use.card->isNDTrick()) return false;
            if (use.card->isKindOf("Nullification")) return false;
            room->setCardFlag(use.card, "fumian_distance");
            if (!use.card->isKindOf("Collateral")) {
                bool canextra = false;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (use.card->isKindOf("AOE") && p == player) continue;
                    if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                    if (use.card->targetFixed()) {
                        if (!use.card->isKindOf("Peach") || p->getLostHp() > 0) {
                            canextra = true;
                            room->setPlayerFlag(p, "fumian_canchoose");
                        }
                    } else {
                        if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                            canextra = true;
                            room->setPlayerFlag(p, "fumian_canchoose");
                        }
                    }
                }
                room->setCardFlag(use.card, "-fumian_distance");
                if (canextra == false) return false;
                if (!room->askForUseCard(player, "@@fumian", "@fumian:" + use.card->objectName())) return false;
                QList<ServerPlayer *> add;
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("fumian_canchoose"))
                        room->setPlayerFlag(p, "-fumian_canchoose");
                    if (p->hasFlag("fumian_extratarget")) {
                        room->setPlayerFlag(p,"-fumian_extratarget");
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
                log.arg = "fumian";
                room->sendLog(log);
                foreach(ServerPlayer *p, add)
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
            } else {
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
                    room->setPlayerFlag(player, "fumian_now_use_collateral");
                    room->askForUseCard(player, "@@fumian", "@fumian:" + use.card->objectName());
                    room->setPlayerFlag(player, "-fumian_now_use_collateral");
                    room->setPlayerProperty(player, "extra_collateral", QString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", QString());
                    room->setCardFlag(use.card, "-fumian_distance");
                    foreach(ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("ExtraCollateralTarget")) {
                            room->setPlayerFlag(p,"-ExtraCollateralTarget");
                            LogMessage log;
                            log.type = "#QiaoshuiAdd";
                            log.from = player;
                            log.to << p;
                            log.card_str = use.card->toString();
                            log.arg = "fumian";
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
            int marks = player->getMark("fumian_draw-Clear");
            if (marks <= 0) return false;
            data.setValue(data.toInt() + marks);
        }
        return false;
    }
};

class FumianTargetMod : public TargetModSkill
{
public:
    FumianTargetMod() : TargetModSkill("#fumian-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("fumian_distance") && card->isRed())
            return 1000;
        else
            return 0;
    }
};

class Daiyan : public PhaseChangeSkill
{
public:
    Daiyan() : PhaseChangeSkill("daiyan")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room* room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "daiyan-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        QString last_target = player->property("daiyan_target").toString();
        room->setPlayerProperty(player, "daiyan_target", target->objectName());
        QList<int> list;
        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (card->getSuit() == Card::Heart && card->isKindOf("BasicCard"))
                list << id;
        }
        if (!list.isEmpty()) {
            int id = list.at(qrand() % list.length());
            room->obtainCard(target, id, true);
        }
        if (last_target != target->objectName() && target->isAlive()) return false;
        room->loseHp(target);
        return false;
    }
};

ZhongjianCard::ZhongjianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool ZhongjianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getHandcardNum() > to_select->getHp();
}

void ZhongjianCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    int selfcardid = this->getSubcards().first();
    room->showCard(effect.from, selfcardid);
    int n = effect.to->getHandcardNum() - effect.to->getHp();
    if (n <= 0) return;
    QList<int> handlist, list;
    QStringList slist;
    foreach (int id, effect.to->handCards()) {
        handlist << id;
    }
    if (handlist.isEmpty()) return;
    for (int i = 1; i <= n; i++) {
        int id = handlist.at(qrand() % handlist.length());
        handlist.removeOne(id);
        list << id;
        slist << Sanguosha->getCard(id)->toString();
    }
    LogMessage log;
    log.type = "$ZhongjianShow";
    log.from = effect.from;
    log.to << effect.to;
    log.arg = QString::number(n);
    log.card_str = slist.join("+");
    room->sendLog(log);
    room->fillAG(list);
    room->getThread()->delay(2000);
    room->clearAG();
    bool samecolour = false, samenumber = false;
    const Card *card = Sanguosha->getCard(selfcardid);
    foreach (int id, list) {
        if (card->sameColorWith(Sanguosha->getCard(id)))
            samecolour = true;
        if (card->getNumber() == Sanguosha->getCard(id)->getNumber())
            samenumber = true;
        if (samecolour && samenumber) break;
    }
    LogMessage newlog;
    if (!samecolour && !samenumber) {
        newlog.type = "#ZhongjianResult_NoSame";
        room->sendLog(newlog);
        room->addPlayerMark(effect.from, "zhongjian_debuff");
        return;
    }
    newlog.type = "#ZhongjianResult";
    newlog.arg = samecolour == true ? "zhongjiansamecolour" : "zhongjiandifferentcolour";
    newlog.arg2 = samenumber == true ? "zhongjiansamenumber" : "zhongjiandifferentnumber";
    room->sendLog(newlog);
    if (samecolour) {
        QStringList choices;
        choices << "draw";
        if (effect.from->canDiscard(effect.to, "he"))
            choices << "discard";
        if (room->askForChoice(effect.from, "zhongjian", choices.join("+")) == "draw")
            effect.from->drawCards(1, "zhongjian");
        else {
            int card_id = room->askForCardChosen(effect.from, effect.to, "he", "zhongjian", false, Card::MethodDiscard);
            room->throwCard(card_id, effect.to, effect.from);
        }
    }
    if (samenumber)
        room->addPlayerMark(effect.from, "zhongjian-Clear");
}

class ZhongjianVS : public OneCardViewAsSkill
{
public:
    ZhongjianVS() : OneCardViewAsSkill("zhongjian")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("zhongjian-Clear") <= 0)
            return !player->hasUsed("ZhongjianCard");
        else
            return player->usedTimes("ZhongjianCard") < 2;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ZhongjianCard *card = new ZhongjianCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Zhongjian : public TriggerSkill
{
public:
    Zhongjian() : TriggerSkill("zhongjian")
    {
        events << Death << EventLoseSkill;
        view_as_skill = new ZhongjianVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player || !player->hasSkill(objectName())) return false;
            room->setPlayerMark(player, "zhongjian_debuff", 0);
        } else {
            if (data.toString() != objectName() || player->isDead()) return false;
            room->setPlayerMark(player, "zhongjian_debuff", 0);
        }
        return false;
    }
};

class ZhongjianMax : public MaxCardsSkill
{
public:
    ZhongjianMax() : MaxCardsSkill("#zhongjianmax")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("zhongjian"))
            return -target->getMark("zhongjian_debuff");
        else
            return 0;
    }
};

class Caishi : public TriggerSkill
{
public:
    Caishi() : TriggerSkill("caishi")
    {
        events << Death << EventLoseSkill << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->isDead() || !player->hasSkill(this) || player->getPhase() != Player::Draw) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            QStringList choices;
            choices << "max";
            if (player->getLostHp() > 0) choices << "recover";
            QString choice = room->askForChoice(player, "caishi", choices.join("+"));
            LogMessage log;
            log.type ="#FumianFirstChoice";
            log.from = player;
            log.arg = "caishi:" + choice;
            room->sendLog(log);
            if (choice == "max") {
                room->addPlayerMark(player, "caishi_buff");
                room->addPlayerMark(player, "caishi_others-Clear");
            } else {
                room->recover(player, RecoverStruct(player));
                room->addPlayerMark(player, "caishi_self-Clear");
            }
        } else if (event == EventLoseSkill) {
            if (data.toString() != objectName() || player->isDead()) return false;
            room->setPlayerMark(player, "caishi_buff", 0);
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player || !player->hasSkill(objectName())) return false;
            room->setPlayerMark(player, "caishi_buff", 0);
        }
        return false;
    }
};

class CaishiMax : public MaxCardsSkill
{
public:
    CaishiMax() : MaxCardsSkill("#caishimax")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("caishi"))
            return target->getMark("caishi_buff");
        else
            return 0;
    }
};

class CaishiPro : public ProhibitSkill
{
public:
    CaishiPro() : ProhibitSkill("#caishipro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (from->getMark("caishi_others-Clear") > 0 && !card->isKindOf("SkillCard"))
            return from != to;
        if (from->getMark("caishi_self-Clear") > 0 && !card->isKindOf("SkillCard"))
            return from == to;
        return false;
    }
};

class Qingxian : public TriggerSkill
{
public:
    Qingxian() : TriggerSkill("qingxian")
    {
        events << Damaged << HpRecover;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() <= 0)
                return false;
        }
        ServerPlayer *target = NULL;
        if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.from || damage.from->isDead()) return false;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.from))) return false;
            target = damage.from;
        } else {
            ServerPlayer *sp = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "qingxian-invoke", true, true);
            if (!sp) return false;
            target = sp;
        }
        if (target) {
            room->broadcastSkillInvoke(objectName());
            QStringList choices;
            choices << "losehp";
            if (target->getLostHp() > 0) choices << "recover";
            if (room->askForChoice(player, "qingxian", choices.join("+"))== "losehp") {
                room->loseHp(target);
                if (target->isDead()) return false;
                QList<int> equiplist;
                foreach (int id, room->getDrawPile()) {
                    const Card* card = Sanguosha->getCard(id);
                    if (card->isKindOf("EquipCard") && card->isAvailable(target) && !target->isProhibited(target, card))
                        equiplist << id;
                }
                if (equiplist.isEmpty()) return false;
                const Card* equip = Sanguosha->getCard(equiplist.at(qrand() % equiplist.length()));
                if (!equip->isAvailable(target) || target->isProhibited(target, equip)) return false;
                room->useCard(CardUseStruct(equip, target, target), true);
                if (equip->getSuit() != Card::Club) return false;
                player->drawCards(1, objectName());
            } else {
                if (target->getLostHp() > 0)
                    room->recover(target, RecoverStruct(player));
                QList<const Card *> equipcards;
                foreach (const Card *card, target->getCards("he")) {
                    if (card->isKindOf("EquipCard"))
                        equipcards << card;
                }
                if (equipcards.isEmpty()) {
                    room->showAllCards(target);
                    return false;
                }
                const Card *card = room->askForCard(target, "EquipCard!", "qingxian-discard");
                if (!card) {
                    card = equipcards.at(qrand() % equipcards.length());
                    room->throwCard(card, target, NULL);
                }
                if (card->getSuit() != Card::Club) return false;
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class Juexiang : public TriggerSkill
{
public:
    Juexiang() : TriggerSkill("juexiang")
    {
        events << Death << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->getMark("juexiang_buff") > 0)
                room->setPlayerMark(player, "juexiang_buff", 0);
            if (death.who != player || !player->hasSkill(objectName())) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "juexiang-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            QStringList skills;
            if (!target->hasSkill("jixian")) skills << "jixian";
            if (!target->hasSkill("liexian")) skills << "liexian";
            if (!target->hasSkill("rouxian")) skills << "rouxian";
            if (!target->hasSkill("hexian")) skills << "hexian";
            if (skills.isEmpty()) return false;
            QString skill_name = skills.at(qrand() % skills.length());
            room->handleAcquireDetachSkills(target, skill_name);
            room->addPlayerMark(target, "juexiang_buff");
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::RoundStart) return false;
            if (player->isAlive() && player->getMark("juexiang_buff") <= 0) return false;
            room->setPlayerMark(player, "juexiang_buff", 0);
        }
        return false;
    }
};

class JuexiangPro : public ProhibitSkill
{
public:
    JuexiangPro() : ProhibitSkill("#juexiangpro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return to->getMark("juexiang_buff") > 0 && from != to && card->getSuit() == Card::Club;
    }
};

class Jixian : public TriggerSkill
{
public:
    Jixian() : TriggerSkill("jixian")
    {
        events << Damaged;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() <= 0)
                return false;
        }
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->isDead()) return false;
        if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.from))) return false;
        room->broadcastSkillInvoke(objectName());
        room->loseHp(damage.from);
        if (damage.from->isDead()) return false;
        QList<int> equiplist;
        foreach (int id, room->getDrawPile()) {
            const Card* card = Sanguosha->getCard(id);
            if (card->isKindOf("EquipCard") && card->isAvailable(damage.from) && !damage.from->isProhibited(damage.from, card))
                equiplist << id;
        }
        if (equiplist.isEmpty()) return false;
        const Card* equip = Sanguosha->getCard(equiplist.at(qrand() % equiplist.length()));
        if (!equip->isAvailable(damage.from) || damage.from->isProhibited(damage.from, equip)) return false;
        room->useCard(CardUseStruct(equip, damage.from, damage.from), true);
        return false;
    }
};

class Liexian : public TriggerSkill
{
public:
    Liexian() : TriggerSkill("liexian")
    {
        events << HpRecover;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() <= 0)
                return false;
        }
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "liexian-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        room->loseHp(target);
        if (target->isDead()) return false;
        QList<int> equiplist;
        foreach (int id, room->getDrawPile()) {
            const Card* card = Sanguosha->getCard(id);
            if (card->isKindOf("EquipCard") && card->isAvailable(target) && !target->isProhibited(target, card))
                equiplist << id;
        }
        if (equiplist.isEmpty()) return false;
        const Card* equip = Sanguosha->getCard(equiplist.at(qrand() % equiplist.length()));
        if (!equip->isAvailable(target) || target->isProhibited(target, equip)) return false;
        room->useCard(CardUseStruct(equip, target, target), true);
        return false;
    }
};

class Rouxian : public TriggerSkill
{
public:
    Rouxian() : TriggerSkill("rouxian")
    {
        events << Damaged;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() <= 0)
                return false;
        }
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->isDead()) return false;
        if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.from))) return false;
        room->broadcastSkillInvoke(objectName());
        if (damage.from->getLostHp() > 0)
            room->recover(damage.from, RecoverStruct(player));
        QList<const Card *> equipcards;
        foreach (const Card *card, damage.from->getCards("he")) {
            if (card->isKindOf("EquipCard"))
                equipcards << card;
        }
        if (equipcards.isEmpty()) {
            room->showAllCards(damage.from);
            return false;
        }
        const Card *card = room->askForCard(damage.from, "EquipCard!", "qingxian-discard"); //rouxian-discard
        if (!card) {
            card = equipcards.at(qrand() % equipcards.length());
            room->throwCard(card, damage.from, NULL);
        }
        return false;
    }
};

class Hexian : public TriggerSkill
{
public:
    Hexian() : TriggerSkill("hexian")
    {
        events << HpRecover;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() <= 0)
                return false;
        }
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "hexian-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        if (target->getLostHp() > 0)
            room->recover(target, RecoverStruct(player));
        QList<const Card *> equipcards;
        foreach (const Card *card, target->getCards("he")) {
            if (card->isKindOf("EquipCard"))
                equipcards << card;
        }
        if (equipcards.isEmpty()) {
            room->showAllCards(target);
            return false;
        }
        const Card *card = room->askForCard(target, "EquipCard!", "qingxian-discard"); //hexian-discard
        if (!card) {
            card = equipcards.at(qrand() % equipcards.length());
            room->throwCard(card, target, NULL);
        }
        return false;
    }
};

WenguagiveCard::WenguagiveCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool WenguagiveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->hasSkill("wengua") && to_select->getMark("wengua-PlayClear") <= 0;
}

void WenguagiveCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->notifySkillInvoked(effect.to, "wengua");
    room->broadcastSkillInvoke("wengua");
    room->addPlayerMark(effect.to, "wengua-PlayClear");
    if (effect.from != effect.to) {
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "wengua", QString());
        room->obtainCard(effect.to, this, reason, false);
    }
    QList<ServerPlayer *> sp;
    sp << effect.from;
    if (!sp.contains(effect.to))
        sp << effect.to;
    room->sortByActionOrder(sp);
    int id = this->getSubcards().first();
    CardMoveReason reason(CardMoveReason::S_REASON_PUT, effect.to->objectName(), "wengua", QString());
    if (room->getCardOwner(id) != effect.to) return;
    if (effect.from != effect.to && room->getCardPlace(id) != Player::PlaceHand) return;
    if (effect.from == effect.to && room->getCardPlace(id) != Player::PlaceHand && room->getCardPlace(id) != Player::PlaceEquip) return;
    QString choice = room->askForChoice(effect.to, "wengua", "top+bottom+cancel");
    if (choice == "cancel") return;
    /*LogMessage log;
    log.type = "#FumianFirstChoice";
    log.from = effect.to;
    log.arg = "wengua:" + choice;
    room->sendLog(log);*/
    if (choice == "top") {
        room->moveCardTo(Sanguosha->getCard(id), NULL, Player::DrawPile, reason);
        room->drawCards(sp, 1, "wengua", false);
    } else {
        QList<int> card_ids;
        card_ids << id;
        room->moveCardsToEndOfDrawpile(effect.from, card_ids, "wengua", false);
        room->drawCards(sp, 1, "wengua");
    }
}

class Wenguagive : public OneCardViewAsSkill
{
public:
    Wenguagive() : OneCardViewAsSkill("wenguagive&")
    {
        filter_pattern = ".";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        WenguagiveCard *card = new WenguagiveCard;
        card->addSubcard(originalCard);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        QList<const Player *> as = player->getAliveSiblings();
        as << player;
        foreach (const Player *p, as) {
            if (p->hasSkill("wengua") && p->getMark("wengua-PlayClear") <= 0)
                return true;
        }
        return false;
    }
};

class Wengua : public TriggerSkill
{
public:
    Wengua() : TriggerSkill("wengua")
    {
        events << GameStart << EventAcquireSkill;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == GameStart || (event ==EventAcquireSkill && data.toString() == "wengua")) {
            foreach (ServerPlayer *p ,room->getAlivePlayers()) {
                if (p->hasSkill("wenguagive")) continue;
                room->attachSkillToPlayer(p, "wenguagive");
            }
        }
        return false;
    }
};

class Fuzhu : public PhaseChangeSkill
{
public:
    Fuzhu() : PhaseChangeSkill("fuzhu")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->getPhase() != Player::Finish || !player->isMale() || player->isDead()) break;
            if (room->getDrawPile().isEmpty()) break;
            if (p->isDead() || !p->hasSkill(this) || !p->canSlash(player, NULL, false)) continue;
            if (room->getDrawPile().length() > 10 * p->getHp()) continue;
            if (!p->askForSkillInvoke(this, QVariant::fromValue(player))) continue;
            room->broadcastSkillInvoke(objectName());
            int i = 0;
            foreach (int id, room->getDrawPile()) {
                if (p->isDead() || player->isDead()) break;
                const Card *card = Sanguosha->getCard(id);
                if (!card->isKindOf("Slash")) continue;
                if (p->canSlash(player, card, false)) {
                    room->useCard(CardUseStruct(card, p, player));
                    i++;
                    if (i == room->getAllPlayers(true).length()) break;
                }
            }
            room->swapPile();
        }
        return false;
    }
};

class Funan : public TriggerSkill
{
public:
    Funan() : TriggerSkill("funan")
    {
        events << CardResponded << CardUsed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        const Card *tocard = NULL;
        ServerPlayer *who;
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            card = use.card;
            tocard = use.whocard;
            who = use.who;
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            card = res.m_card;
            tocard = res.m_toCard;
            who = res.m_who;
        }
        if (card == NULL || tocard == NULL || card->isKindOf("SkillCard") || tocard->isKindOf("SkillCard")) return false;
        if (!who || who->isDead() || who == player || !who->hasSkill(this)) return false;

        Player::Place place = Player::PlaceTable;
        if (tocard->isKindOf("Nullification"))
            place = Player::DiscardPile;

        if (!room->CardInPlace(tocard, place)) return false;
        if (!who->askForSkillInvoke(this, QVariant::fromValue(player))) return false;
        room->broadcastSkillInvoke(objectName());

        bool level_up = who->property("funan_level_up").toBool();
        if (!level_up) {
            player->obtainCard(tocard, true);
            QStringList list;
            if (tocard->isVirtualCard()) {
                foreach (int id, tocard->getSubcards()) {
                    list << Sanguosha->getCard(id)->toString();
                    room->setPlayerCardLimitation(player, "use,response", Sanguosha->getCard(id)->toString(), true);
                }
            } else {
                list << tocard->toString();
                room->setPlayerCardLimitation(player, "use,response", tocard->toString(), true);
            }
            room->setPlayerProperty(player, "funan_limitlist", list);
        }

        if (event == CardUsed) {
            if (!room->CardInPlace(card, Player::PlaceTable)) return false;
        } else {
            if (data.value<CardResponseStruct>().m_isUse) {
                if (!room->CardInPlace(card, Player::PlaceTable)) return false;
            } else {
                if (!room->CardInPlace(card, Player::DiscardPile)) return false;
            }
        }
        who->obtainCard(card);
        return false;
    }
};

class FunanRemove : public TriggerSkill
{
public:
    FunanRemove() : TriggerSkill("#funanremove")
    {
        events << EventPhaseChanging << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player || player != room->getCurrent()) return false;
        }
        foreach(ServerPlayer *p, room->getAllPlayers(true)) {
            QStringList list = p->property("funan_limitlist").toStringList();
            if (list.isEmpty()) continue;
            foreach (QString str, list) {
                room->removePlayerCardLimitation(p, "use,response", str + "$1");
            }
        }
        return false;
    }
};

class Jiexun : public TriggerSkill
{
public:
    Jiexun() : TriggerSkill("jiexun")
    {
        events << EventPhaseStart << CardsMoveOneTime;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseStart)
            return 2;
        else
            return 5;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            int num = 0;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                foreach (const Card *c, p->getCards("ej")) {
                    if (c->getSuit() == Card::Diamond)
                        num++;
                }
            }
            //if (num <= 0) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "jiexun-invoke:" + QString::number(num), true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            int n = player->getMark("&jiexun-Keep");
            room->addPlayerMark(player, "&jiexun-Keep");
            if (num > 0)
                target->drawCards(num, objectName());
            if (n > 0)
                room->askForDiscard(target, objectName(), n, n, false, true);
            if (!target->hasFlag("jiexun")) return false;
            room->setPlayerFlag(target, "-jiexun");
            if (player->hasSkill("jiexun"))
                room->handleAcquireDetachSkills(player, "-jiexun");
            if (player->hasSkill("funan", true)) {
                LogMessage log;
                log.type = "#JiexunChange";
                log.from = player;
                log.arg = "funan";
                room->sendLog(log);
            }
            room->setPlayerProperty(player, "funan_level_up", true);
            room->setPlayerMark(player, "&funan", 1);
            QString translate = Sanguosha->translate(":funan2");
            Sanguosha->addTranslationEntry(":funan", translate.toStdString().c_str());
            room->doNotify(player, QSanProtocol::S_COMMAND_UPDATE_SKILL, QVariant("funan"));
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.reason.m_skillName != objectName()) return false;
            if (move.from && (move.from_places.contains(Player::PlaceEquip) || move.from_places.contains(Player::PlaceHand))) {
                ServerPlayer *from = room->findPlayerByObjectName(move.from->objectName());
                if (from && from->getCards("he").isEmpty())
                    room->setPlayerFlag(from, "jiexun");
            }
        }
        return false;
    }
};

class Shouxi : public TriggerSkill
{
public:
    Shouxi() : TriggerSkill("shouxi")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || !use.to.contains(player)) return false;
        QStringList alllist;
        QList<int> ids;
        QStringList list = player->property("shouxi_names").toStringList();
        foreach(int id, Sanguosha->getRandomCards()) {
            const Card *c = Sanguosha->getEngineCard(id);
            if (c->isKindOf("EquipCard")) continue;
            if (alllist.contains(c->objectName()) || list.contains(c->objectName())) continue;
            alllist << c->objectName();
            ids << id;
        }
        if (alllist.isEmpty() || !player->askForSkillInvoke(this, QVariant::fromValue(use.from))) return false;
        room->broadcastSkillInvoke(objectName());
        room->fillAG(ids, player);
        int id = room->askForAG(player, ids, false, objectName());
        room->clearAG(player);

        const Card *c = Sanguosha->getEngineCard(id);
        QString name = c->objectName();
        QString classname = c->getClassName();
        if (!list.contains(name)) {
            list << name;
            room->setPlayerProperty(player, "shouxi_names", list);
        }
        LogMessage log;
        log.type = "#ShouxiChoice";
        log.from = player;
        log.arg = name;
        room->sendLog(log);
        if (use.from->isDead() || !use.from->canDiscard(use.from, "h") || !room->askForCard(use.from, classname, "shouxi-discard:" + name, data)) {
            use.nullified_list << player->objectName();
            data = QVariant::fromValue(use);
        } else {
            if (player->isNude()) return false;
            int card_id = room->askForCardChosen(use.from, player, "he", "shouxi");
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, use.from->objectName());
            room->obtainCard(use.from, Sanguosha->getCard(card_id),
                reason, room->getCardPlace(card_id) != Player::PlaceHand);
        }
        return false;
    }
};

HuiminCard::HuiminCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool HuiminCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->hasFlag("huimin_target");
}

void HuiminCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "huimin_start_target");
}

class HuiminVS : public ViewAsSkill
{
public:
    HuiminVS() : ViewAsSkill("huimin")
    {
        response_pattern = "@@huimin!";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !to_select->isEquipped() && selected.length() < Self->getMark("huimin_length");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != Self->getMark("huimin_length")) return NULL;

        Card *acard = new HuiminCard;
        acard->addSubcards(cards);
        return acard;
    }
};

class Huimin : public PhaseChangeSkill
{
public:
    Huimin() : PhaseChangeSkill("huimin")
    {
        view_as_skill = new HuiminVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> sp;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHandcardNum() < p->getHp())
                sp << p;
        }
        if (sp.isEmpty()) return false;
        int length = sp.length();
        if (!player->askForSkillInvoke(this, QString("huimin_invoke:%1").arg(length))) return false;
        room->broadcastSkillInvoke(objectName());
        player->drawCards(length, objectName());
        QStringList cardlist;
        QList<int> ids;
        ServerPlayer *start_player = NULL;
        if (player->getHandcardNum() <= length) {
            foreach (int id, player->handCards()) {
                cardlist << Sanguosha->getCard(id)->toString();
                ids << id;
            }
        } else {
            foreach (ServerPlayer *p, sp)
                room->setPlayerFlag(p, "huimin_target");
            room->setPlayerMark(player, "huimin_length", length);
            const Card *card = room->askForUseCard(player, "@@huimin!", "@huimin:" + QString::number(length));
            room->setPlayerMark(player, "huimin_length", 0);
            if (!card) {
                foreach (ServerPlayer *p, sp) {
                    if (p->hasFlag("huimin_target"))
                        room->setPlayerFlag(p, "-huimin_target");
                }
                start_player = sp.at(qrand() % length);
                QList<int> handids;
                foreach (int id, player->handCards())
                    handids << id;
                for (int i = 1; i <= length; i++) {
                    int id = handids.at(qrand() % handids.length());
                    handids.removeOne(id);
                    ids << id;
                    cardlist << Sanguosha->getCard(id)->toString();
                    if (handids.isEmpty()) break;
                }
            } else {
                foreach (ServerPlayer *p, sp) {
                    if (p->hasFlag("huimin_target"))
                        room->setPlayerFlag(p, "-huimin_target");
                    if (p->hasFlag("huimin_start_target")) {
                        room->setPlayerFlag(p, "-huimin_start_target");
                        start_player = p;
                    }
                }
                ids = card->getSubcards();
                foreach (int id, ids)
                    cardlist << Sanguosha->getCard(id)->toString();
            }
        }
        LogMessage log;
        log.type = "$ShowCard";
        log.from = player;
        log.card_str = cardlist.join("+");
        room->sendLog(log);
        room->fillAG(ids);
        if (start_player == NULL)
            start_player = room->askForPlayerChosen(player, sp, objectName(), "huimin-chooseplayer");
        LogMessage newlog;
        newlog.type = "#HuiminPlayer";
        newlog.from = player;
        newlog.to << start_player;
        room->sendLog(newlog);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), start_player->objectName());
        while (!ids.isEmpty()) {
            int id = room->askForAG(start_player, ids, false, objectName());
            ids.removeOne(id);
            //room->takeAG(start_player, id, true); hui ka pai
            if (start_player != player)
                room->obtainCard(start_player, id, true);
            if (ids.isEmpty()) break;
            start_player = start_player->getNextAlive();
            while (!sp.contains(start_player)) {
                start_player = start_player->getNextAlive();
            }
        }
        room->clearAG();
        return false;
    }
};

class Bizhuan : public TriggerSkill
{
public:
    Bizhuan() : TriggerSkill("bizhuan")
    {
        events << TargetConfirmed << CardUsed;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getSuit() !=Card::Spade || use.card->isKindOf("SkillCard")) return false;
        if (event == TargetConfirmed && (use.from == player || !use.to.contains(player))) return false;
        if (player->getPile("book").length() >= 4) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        player->addToPile("book", room->drawCard());
        return false;
    }
};

class BizhuanKeep : public MaxCardsSkill
{
public:
    BizhuanKeep() : MaxCardsSkill("#bizhuankeep")
    {
        frequency = Frequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("bizhuan"))
            return target->getPile("book").length();
        else
            return 0;
    }
};

TongboCard::TongboCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    target_fixed = true;
}

void TongboCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QList<int> pile = card_use.from->getPile("book");
    QList<int> subCards = card_use.card->getSubcards();
    QList<int> to_handcard;
    QList<int> to_pile;
    foreach (int id, subCards) {
        if (pile.contains(id))
            to_handcard << id;
        else
            to_pile << id;
    }

    Q_ASSERT(to_handcard.length() == to_pile.length());

    if (to_pile.length() == 0 || to_handcard.length() != to_pile.length())
        return;

    LogMessage log;
    log.type = "#QixingExchange";
    log.from = card_use.from;
    log.arg = to_pile.length();
    log.arg2 = "tongbo";
    room->sendLog(log);

    card_use.from->addToPile("book", to_pile, false);

    DummyCard to_handcard_x(to_handcard);
    CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, card_use.from->objectName());
    room->obtainCard(card_use.from, &to_handcard_x, reason, false);

    QStringList suitlist;
    foreach (int id, card_use.from->getPile("book")) {
        QString str = Sanguosha->getCard(id)->getSuitString();
        if (!suitlist.contains(str))
            suitlist << str;
    }
    if (suitlist.length() < 4) return;
    QList<ServerPlayer *> _player;
    _player.append(card_use.from);
    QList<int> ids = card_use.from->getPile("book");

    CardsMoveStruct move(ids, card_use.from, card_use.from, Player::PlaceTable, Player::PlaceHand,
        CardMoveReason(CardMoveReason::S_REASON_PUT, card_use.from->objectName(), "tongbo", QString()));
    QList<CardsMoveStruct> moves;
    moves.append(move);
    room->notifyMoveCards(true, moves, false, _player);
    room->notifyMoveCards(false, moves, false, _player);

    QList<int> origin_ids = ids;
    while (room->askForYiji(card_use.from, ids, "tongbo", false, true, false, -1, room->getOtherPlayers(card_use.from))) {
        CardsMoveStruct move(QList<int>(), card_use.from, card_use.from, Player::PlaceHand, Player::PlaceTable,
            CardMoveReason(CardMoveReason::S_REASON_PUT, card_use.from->objectName(), "tongbo", QString()));
        foreach (int id, origin_ids) {
            if (room->getCardPlace(id) != Player::PlaceSpecial || room->getCardOwner(id) != card_use.from) {
                move.card_ids << id;
                ids.removeOne(id);
            }
        }
        origin_ids = ids;
        QList<CardsMoveStruct> moves;
        moves.append(move);
        room->notifyMoveCards(true, moves, false, _player);
        room->notifyMoveCards(false, moves, false, _player);
        if (!card_use.from->isAlive())
            return;
    }
}

class TongboVS : public ViewAsSkill
{
public:
    TongboVS() : ViewAsSkill("tongbo")
    {
        response_pattern = "@@tongbo";
        expand_pile = "book";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        return selected.length() < 2 * Self->getPile("book").length();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int notpile = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getPile("book").contains(card->getEffectiveId()))
                pile++;
            else
                notpile++;
        }

        if (notpile == pile) {
            TongboCard *c = new TongboCard;
            c->addSubcards(cards);
            return c;
        }

        return NULL;
    }
};

class Tongbo : public TriggerSkill
{
public:
    Tongbo() : TriggerSkill("tongbo")
    {
        events << EventPhaseEnd;
        view_as_skill = new TongboVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Draw) return false;
        if (player->isKongcheng() || player->getPile("book").isEmpty()) return false;
        room->askForUseCard(player, "@@tongbo", "@tongbo");
        return false;
    }
};

MobileQingxianCard::MobileQingxianCard()
{
}

bool MobileQingxianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < getSubcards().length() && to_select != Self;
}

bool MobileQingxianCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == getSubcards().length();
}

void MobileQingxianCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) break;
        if (p->isDead()) continue;
        room->cardEffect(this, source, p);
    }
    if (targets.length() == source->getHp() && source->isAlive())
        source->drawCards(1, "mobileqingxian");
}

void MobileQingxianCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    Room *room = effect.from->getRoom();
    if (effect.to->getEquips().length() > effect.from->getEquips().length())
        room->loseHp(effect.to);
    else if (effect.to->getEquips().length() == effect.from->getEquips().length())
        effect.to->drawCards(1, "mobileqingxian");
    else {
        if (effect.to->getLostHp() > 0)
            room->recover(effect.to, RecoverStruct(effect.from));
    }
}

class MobileQingxian : public ViewAsSkill
{
public:
    MobileQingxian() : ViewAsSkill("mobileqingxian")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int n = qMin(Self->getHp(), Self->getAliveSiblings().length());
        return selected.length() < n && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        MobileQingxianCard *c = new MobileQingxianCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("MobileQingxianCard") && player->getHp() > 0;
    }
};

class MobileJuexiang : public TriggerSkill
{
public:
    MobileJuexiang() : TriggerSkill("mobilejuexiang")
    {
        events << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill(this);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player)
            return false;

        if (death.damage && death.damage->from) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            death.damage->from->throwAllEquips();
            room->loseHp(death.damage->from);
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "mobilejuexiang-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            if (!target->hasSkill("mobilecanyun"))
                room->handleAcquireDetachSkills(target, "mobilecanyun");
            if (target->isDead()) return false;
            QList<ServerPlayer *> clubs;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                foreach (const Card *c, p->getCards("ej")) {
                    if (c->getSuit() == Card::Club && target->canDiscard(p, c->getEffectiveId()))
                        clubs << p;
                }
            }
            if (clubs.isEmpty()) return false;
            ServerPlayer *club = room->askForPlayerChosen(target, clubs, "mobilejuexiang_discard", "mobilejuexiang-discard", true);
            if (!club) return false;
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), club->objectName());
            QList<int> disabled_ids;
            foreach (const Card *c, club->getCards("ej")) {
                if (c->getSuit() != Card::Club || !target->canDiscard(club, c->getEffectiveId()))
                    disabled_ids << c->getEffectiveId();
            }
            if (disabled_ids.length() == club->getCards("ej").length()) return false;
            int card_id = room->askForCardChosen(target, club, "ej", objectName(), false, Card::MethodDiscard, disabled_ids);
            room->throwCard(card_id, room->getCardPlace(card_id) == Player::PlaceDelayedTrick ? NULL : club, target);
            if (target->hasSkill("mobilejuexiang")) return false;
            room->handleAcquireDetachSkills(target, "mobilejuexiang");
        }
        return false;
    }
};

MobileCanyunCard::MobileCanyunCard()
{
}

bool MobileCanyunCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < getSubcards().length() && to_select != Self && to_select->getMark("mobilecanyun_used" + Self->objectName()) <= 0;
}

bool MobileCanyunCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == getSubcards().length();
}

void MobileCanyunCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets)
        room->addPlayerMark(p, "mobilecanyun_used" + source->objectName());
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) break;
        if (p->isDead()) continue;
        room->cardEffect(this, source, p);
    }
    if (targets.length() == source->getHp() && source->isAlive())
        source->drawCards(1, "mobilecanyun");
}

void MobileCanyunCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    Room *room = effect.from->getRoom();
    if (effect.to->getEquips().length() > effect.from->getEquips().length())
        room->loseHp(effect.to);
    else if (effect.to->getEquips().length() == effect.from->getEquips().length())
        effect.to->drawCards(1, "mobilecanyun");
    else {
        if (effect.to->getLostHp() > 0)
            room->recover(effect.to, RecoverStruct(effect.from));
    }
}

class MobileCanyun : public ViewAsSkill
{
public:
    MobileCanyun() : ViewAsSkill("mobilecanyun")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int m = 0;
        foreach (const Player *p, Self->getAliveSiblings()) {
            if (p->getMark("mobilecanyun_used" + Self->objectName()) <= 0)
                m++;
        }
        int n = qMin(Self->getHp(), m);
        return selected.length() < n && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        MobileCanyunCard *c = new MobileCanyunCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("MobileCanyunCard") && player->getHp() > 0 && hastarget(player);
    }

    bool hastarget(const Player *player) const
    {
        foreach (const Player *p, player->getAliveSiblings()) {
            if (p->getMark("mobilecanyun_used" + player->objectName()) <= 0)
                return true;
        }
        return false;
    }
};

YCZH2017Package::YCZH2017Package()
    : Package("YCZH2017")
{
    General *qinmi = new General(this, "qinmi", "shu", 3);
    qinmi->addSkill(new Jianzheng);
    qinmi->addSkill(new Zhuandui);
    qinmi->addSkill(new Tianbian);

    General *wuxian = new General(this, "wuxian", "shu", 3, false);
    wuxian->addSkill(new Fumian);
    wuxian->addSkill(new FumianTargetMod);
    wuxian->addSkill(new Daiyan);
    related_skills.insertMulti("fumian", "#fumian-target");

    General *xinxianying = new General(this, "xinxianying", "wei", 3, false);
    xinxianying->addSkill(new Zhongjian);
    xinxianying->addSkill(new ZhongjianMax);
    xinxianying->addSkill(new Caishi);
    xinxianying->addSkill(new CaishiMax);
    xinxianying->addSkill(new CaishiPro);
    related_skills.insertMulti("zhongjian", "#zhongjianmax");
    related_skills.insertMulti("caishi", "#caishimax");
    related_skills.insertMulti("caishi", "#caishipro");

    General *jikang = new General(this, "jikang", "wei", 3);
    jikang->addSkill(new Qingxian);
    jikang->addSkill(new Juexiang);
    jikang->addSkill(new JuexiangPro);
    jikang->addRelateSkill("jixian");
    jikang->addRelateSkill("liexian");
    jikang->addRelateSkill("rouxian");
    jikang->addRelateSkill("hexian");
    related_skills.insertMulti("juexiang", "#juexiangpro");

    General *mobile_jikang = new General(this, "mobile_jikang", "wei", 3);
    mobile_jikang->addSkill(new MobileQingxian);
    mobile_jikang->addSkill(new MobileJuexiang);
    mobile_jikang->addRelateSkill("mobilecanyun");

    General *xushi = new General(this, "xushi", "wu", 3, false);
    xushi->addSkill(new Wengua);
    xushi->addSkill(new Fuzhu);

    General *xuezong = new General(this, "xuezong", "wu", 3);
    xuezong->addSkill(new Funan);
    xuezong->addSkill(new FunanRemove);
    xuezong->addSkill(new Jiexun);
    related_skills.insertMulti("funan", "#funanremove");

    General *caojie = new General(this, "caojie", "qun", 3, false);
    caojie->addSkill(new Shouxi);
    caojie->addSkill(new Huimin);

    General *caiyong = new General(this, "caiyong", "qun", 3);
    caiyong->addSkill(new Bizhuan);
    caiyong->addSkill(new BizhuanKeep);
    caiyong->addSkill(new Tongbo);
    related_skills.insertMulti("bizhuan", "#bizhuankeep");

    addMetaObject<FumianCard>();
    addMetaObject<ZhongjianCard>();
    addMetaObject<WenguagiveCard>();
    addMetaObject<HuiminCard>();
    addMetaObject<TongboCard>();
    addMetaObject<MobileQingxianCard>();
    addMetaObject<MobileCanyunCard>();

    skills << new Jixian << new Liexian << new Rouxian << new Hexian << new Wenguagive << new MobileCanyun;
}

ADD_PACKAGE(YCZH2017)
