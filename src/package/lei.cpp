#include "lei.h"
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

class Wanglie : public TriggerSkill
{
public:
    Wanglie() : TriggerSkill("wanglie")
    {
        events << PreCardUsed << PreCardResponded << CardResponded << CardUsed;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (event == PreCardUsed) {
            if (data.value<CardUseStruct>().card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "wanglie-PlayClear");
        } else if (event == PreCardResponded) {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_card->isKindOf("SkillCard") || !resp.m_isUse) return false;
            room->addPlayerMark(player, "wanglie-PlayClear");
        } else if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (player->isDead() || !player->hasSkill(this) || !player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(objectName());
            use.no_respond_list << "_ALL_TARGETS";
            data = QVariant::fromValue(use);
            room->setPlayerCardLimitation(player, "use", ".", true);
        } else {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_card->isKindOf("SkillCard") || !resp.m_isUse) return false;
            if (player->isDead() || !player->hasSkill(this) || !player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(objectName());
            room->setCardFlag(resp.m_card, "no_respond_" + player->objectName() + "_ALL_TARGETS");
            room->setPlayerCardLimitation(player, "use", ".", true);
        }
        return false;
    }
};

class WanglieMod : public TargetModSkill
{
public:
    WanglieMod() : TargetModSkill("#wangliemod")
    {
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("wanglie") && from->getPhase() == Player::Play && from->getMark("wanglie-PlayClear") <= 0)
            return 1000;
        else
            return 0;
    }
};

class Zuilun : public TriggerSkill
{
public:
    Zuilun() : TriggerSkill("zuilun")
    {
        events << CardsMoveOneTime << EventPhaseStart;
        global = true;
    }

    int ZuilunGetNum(ServerPlayer *player) const
    {
        int num = 0;
        Room *room = player->getRoom();
        if (player->getMark("damage_point_round") > 0)
            num++;
        bool minhandnum = true;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHandcardNum() < player->getHandcardNum()) {
                minhandnum = false;
                break;
            }
        }
        if (minhandnum == true)
            num++;
        if (player->getMark("zuilun_discard-Clear") <= 0)
            num++;
        return num;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (!player->hasSkill(this) || player->getPhase() != Player::Finish) return false;
            int num = ZuilunGetNum(player);
            if (!player->askForSkillInvoke(this, "zuilun_get:" + QString::number(num))) return false;
            room->broadcastSkillInvoke(objectName());
            /*LogMessage log;
            log.type = "#ZuilunNum";
            log.from = player;
            log.arg = QString::number(num);
            room->sendLog(log);*/
            num = ZuilunGetNum(player);
            room->askForGuanxing(player, room->getNCards(3, false), Room::GuanxingUpOnly);
            if (num == 0) {
                ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@zuilun-lose");
                room->doAnimate(1, player->objectName(), target->objectName());
                QList<ServerPlayer *> losers;
                losers << player << target;
                room->sortByActionOrder(losers);
                foreach (ServerPlayer *p, losers) {
                    if (p->isDead()) continue;
                    room->loseHp(p);
                }
            } else {
                DummyCard get(room->getNCards(num ,false));
                room->obtainCard(player, &get, false);
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD
                    && player->getPhase() != Player::NotActive)
                room->addPlayerMark(player, "zuilun_discard-Clear");
        }
        return false;
    }
};

class Fuyin : public TriggerSkill
{
public:
    Fuyin() : TriggerSkill("fuyin")
    {
        events << TargetConfirmed;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player)) return false;
        if (!use.card->isKindOf("Slash") && !use.card->isKindOf("Duel")) return false;
        if (player->getMark("fuyin-Clear") > 0) return false;
        room->addPlayerMark(player, "fuyin-Clear");
        if (use.from->isDead()) return false;
        if (player->getHandcardNum() > use.from->getHandcardNum()) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        use.nullified_list << player->objectName();
        data = QVariant::fromValue(use);
        return false;
    }
};

class Liangyin : public TriggerSkill
{
public:
    Liangyin() : TriggerSkill("liangyin")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place == Player::PlaceSpecial) {
            if (move.to_pile_name.startsWith("#")) return false;
            bool invoke = false;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceSpecial) continue;
                invoke = true;
                break;
            }

            if (!invoke) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHandcardNum() > player->getHandcardNum())
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@liangyin-draw", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            target->drawCards(1, objectName());
        } else if (move.to && move.to_place == Player::PlaceHand) {
            if (!move.from_places.contains(Player::PlaceSpecial)) return false;
            bool invoke = false;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) != Player::PlaceSpecial) continue;
                if (move.from_pile_names.at(i).startsWith("#")) continue;
                invoke = true;
                break;
            }
            if (!invoke) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHandcardNum() < player->getHandcardNum() && !p->isNude())
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@liangyin-discard", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            if (!target->canDiscard(target, "he")) return false;
            room->askForDiscard(target, objectName(), 1, 1, false, true);
        }
        return false;
    }
};

class Kongsheng : public PhaseChangeSkill
{
public:
    Kongsheng() : PhaseChangeSkill("kongsheng")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (player->getPhase() == Player::Start) {
            if (player->isNude()) return false;
            const Card *card = room->askForExchange(player, objectName(), player->getCards("he").length(), 1, true, "kongsheng-put", true);
            if (!card) return false;
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(player, objectName());
            player->addToPile(objectName(), card);
            delete card;
        } else if (player->getPhase() == Player::Finish) {
            QList<int> pile = player->getPile(objectName());
            if (pile.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            DummyCard *dummy = new DummyCard();
            foreach (int id, pile) {
                if (player->isDead()) break;
                const Card *card = Sanguosha->getCard(id);
                if (card->isKindOf("EquipCard")) {
                    if (!card->isAvailable(player) || player->isProhibited(player, card)) {
                        dummy->addSubcard(id);
                    } else
                        room->useCard(CardUseStruct(card, player, player), true);;
                } else
                    dummy->addSubcard(id);
            }
            if (player->isAlive() && !dummy->getSubcards().isEmpty()) {
                LogMessage log;
                log.type = "$KuangbiGet";
                log.from = player;
                log.arg = "kongsheng";
                log.card_str = IntList2StringList(dummy->getSubcards()).join("+");
                room->sendLog(log);
                room->obtainCard(player, dummy, true);
            }
            delete dummy;
        }
        return false;
    }
};

class QianjieChain : public TriggerSkill
{
public:
    QianjieChain() : TriggerSkill("#qianjie-chain")
    {
        events << ChainStateChange;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->isChained()) return false;
        room->sendCompulsoryTriggerLog(player, "qianjie", true, true);
        return true;
    }
};

class Qianjie : public ProhibitSkill
{
public:
    Qianjie() : ProhibitSkill("qianjie")
    {
    }

    bool isProhibited(const Player *, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return to->hasSkill("qianjie") && card->isKindOf("DelayedTrick");
    }
};

class QianjiePindianPro : public ProhibitPindianSkill
{
public:
    QianjiePindianPro() : ProhibitPindianSkill("#qianjiepindianpro")
    {
    }

    bool isPindianProhibited(const Player *from, const Player *to) const
    {
        return to->hasSkill("qianjie") && from != to;
    }
};

JueyanCard::JueyanCard()
{
    target_fixed = true;
}

void JueyanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QStringList choices;
    if (source->hasEquipArea(0)) choices << "0";
    if (source->hasEquipArea(1)) choices << "1";
    if (source->hasEquipArea(2) || source->hasEquipArea(3)) choices << "23";
    if (source->hasEquipArea(4)) choices << "4";
    if (choices.isEmpty()) return;
    QString choice = room->askForChoice(source, "jueyan", choices.join("+"), QVariant());
    if (choice == "0") {
        source->throwEquipArea(0);
        room->addSlashCishu(source, 3);
    } else if (choice == "1") {
        source->throwEquipArea(1);
        source->drawCards(3, objectName());
        room->addMaxCards(source, 3);
    } else if (choice == "23") {
        QList<int> list;
        list << 2 << 3;
        source->throwEquipArea(list);
        room->setPlayerFlag(source, "jueyan_distance");
    } else {
        source->throwEquipArea(4);
        if (!source->hasSkill("jizhi")) {
            room->acquireOneTurnSkills(source, "jueyan", "tenyearjizhi");
        }
    }
}

class Jueyan : public ZeroCardViewAsSkill
{
public:
    Jueyan() : ZeroCardViewAsSkill("jueyan")
    {
    }

    const Card *viewAs() const
    {
        return new JueyanCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->hasEquipArea() && !player->hasUsed("JueyanCard");
    }
};

class JueyanTargetMod : public TargetModSkill
{
public:
    JueyanTargetMod() : TargetModSkill("#jueyantargetmod")
    {
        pattern = ".";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasFlag("jueyan_distance"))
            return 1000;
        else
            return 0;
    }
};

class Poshi : public PhaseChangeSkill
{
public:
    Poshi() : PhaseChangeSkill("poshi")
    {
        frequency = Wake;
        waked_skills = "huairou";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        if (player->getPhase() == Player::Start && player->getMark("poshi") <= 0) {
            return player->canWake("poshi") || !player->hasEquipArea() || player->getHp() == 1;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("lei_lukang", "poshi");
        room->setPlayerMark(player, "poshi", 1);
        if (room->changeMaxHpForAwakenSkill(player)) {
            if (player->getHandcardNum() < player->getMaxHp())
                player->drawCards(player->getMaxHp() - player->getHandcardNum(), objectName());
            room->handleAcquireDetachSkills(player, "-jueyan|huairou");
        }
        return false;
    }
};

HuairouCard::HuairouCard()
{
    target_fixed = true;
    will_throw = false;
    can_recast = true;
    handling_method = Card::MethodRecast;
}

void HuairouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    LogMessage log;
    log.type = "#UseCard_Recast";
    log.from = source;
    log.card_str = QString::number(this->getSubcards().first());
    room->sendLog(log);
    room->moveCardTo(this, source, NULL, Player::DiscardPile, CardMoveReason(CardMoveReason::S_REASON_RECAST, source->objectName(), objectName(), ""));
    source->drawCards(1, objectName());
}

class Huairou : public OneCardViewAsSkill
{
public:
    Huairou() : OneCardViewAsSkill("huairou")
    {
        filter_pattern = "EquipCard";
    }

    const Card *viewAs(const Card *c) const
    {
        HuairouCard *card = new HuairouCard;
        card->addSubcard(c);
        return card;
    }
};

class Zhengu : public TriggerSkill
{
public:
    Zhengu() : TriggerSkill("zhengu")
    {
        events << EventPhaseStart;
    }

     bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
         if (player->getPhase() != Player::Finish) return false;
         ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@zhengu-invoke", true, true);
         if (!target) return false;
         room->broadcastSkillInvoke(objectName());
         room->addPlayerMark(player, "zhengu-Clear");
         QStringList list = player->property("zhengu_targets").toStringList();
         if (list.contains(target->objectName())) return false;
         list << target->objectName();
         room->setPlayerProperty(player, "zhengu_targets", list);
         room->addPlayerMark(target, "&zhengu");
         return false;
    }
};

class ZhenguEffect : public TriggerSkill
{
public:
    ZhenguEffect() : TriggerSkill("#zhengueffect")
    {
        events << EventPhaseChanging << Death << EventLoseSkill;
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
                if (player->getMark("zhengu-Clear") > 0) {
                    foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                        QStringList list = player->property("zhengu_targets").toStringList();
                        if (!list.contains(p->objectName())) continue;
                        int h = player->getHandcardNum();
                        int hh = p->getHandcardNum();
                        if (h == hh) continue;
                        LogMessage log;
                        log.type = "#ZhenguEffect";
                        log.from = p;
                        log.arg = "zhengu";
                        room->sendLog(log);
                        room->notifySkillInvoked(player, "zhengu");
                        room->broadcastSkillInvoke("zhengu");
                        if (h > hh)
                            p->drawCards(qMin(h - hh, 5 - hh), "zhengu");
                        else
                            room->askForDiscard(p, "zhengu", hh - h, hh - h, false, false);
                    }
                }

                if (player->isDead()) return false;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    QStringList list = p->property("zhengu_targets").toStringList();
                    if (list.contains(player->objectName())) {
                        list.removeOne(player->objectName());
                        room->setPlayerProperty(p, "zhengu_targets", list);
                        room->removePlayerMark(player, "&zhengu");
                        int h = p->getHandcardNum();
                        int hh = player->getHandcardNum();
                        if (h == hh) continue;
                        LogMessage log;
                        log.type = "#ZhenguEffect";
                        log.from = player;
                        log.arg = "zhengu";
                        room->sendLog(log);
                        room->notifySkillInvoked(p, "zhengu");
                        room->broadcastSkillInvoke("zhengu");
                        if (h > hh)
                            player->drawCards(qMin(h - hh, 5 - hh), objectName());
                        else
                            room->askForDiscard(player, "zhengu", hh - h, hh - h, false, false);
                    }
                }
            }
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->objectName() != player->objectName()) return false;
            if (death.who->hasSkill("zhengu")) {
                room->setPlayerProperty(player, "zhengu_targets", QStringList());
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (p->getMark("&zhengu") > 0)
                         room->removePlayerMark(p, "&zhengu");
                }
            }
            if (player->getMark("&zhengu") > 0)
                 room->removePlayerMark(player, "&zhengu");
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                QStringList list = p->property("zhengu_targets").toStringList();
                if (list.contains(player->objectName())) {
                    list.removeOne(player->objectName());
                    room->setPlayerProperty(p, "zhengu_targets", list);
                }
            }
        } else if (triggerEvent == EventLoseSkill) {
            if (data.toString() != "zhengu") return false;
            if (!player->isAlive()) return false;
            room->setPlayerProperty(player, "zhengu_targets", QStringList());
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMark("&zhengu") > 0)
                     room->removePlayerMark(p, "&zhengu");
            }
        }
        return false;
    }
};

class Zhengrong : public TriggerSkill
{
public:
    Zhengrong() : TriggerSkill("zhengrong")
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead() || damage.to == player || damage.to->getHandcardNum() <= player->getHandcardNum() || damage.to->isNude()) return false;
        QVariant newdata = QVariant::fromValue(damage.to);
        if (!player->askForSkillInvoke(objectName(), newdata)) return false;
        room->broadcastSkillInvoke(objectName());
        int card_id = room->askForCardChosen(player, damage.to, "he", "zhengrong");
        player->addToPile("rong", card_id);
        return false;
    }
};

HongjuCard::HongjuCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
    target_fixed = true;
}

void HongjuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QList<int> pile = card_use.from->getPile("rong");
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
    log.arg = QString::number(to_pile.length());
    log.arg2 = "hongju";
    room->sendLog(log);

    card_use.from->addToPile("rong", to_pile);

    DummyCard to_handcard_x(to_handcard);
    CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, card_use.from->objectName());
    room->obtainCard(card_use.from, &to_handcard_x, reason, true);
}

class HongjuVS : public ViewAsSkill
{
public:
    HongjuVS() : ViewAsSkill("hongju")
    {
        response_pattern = "@@hongju";
        expand_pile = "rong";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() < 2 * Self->getPile("rong").length())
            return !to_select->isEquipped();

        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hand = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card))
                hand++;
            else if (Self->getPile("rong").contains(card->getEffectiveId()))
                pile++;
        }

        if (hand == pile) {
            HongjuCard *c = new HongjuCard;
            c->addSubcards(cards);
            return c;
        }

        return NULL;
    }
};

class Hongju : public PhaseChangeSkill
{
public:
    Hongju() : PhaseChangeSkill("hongju")
    {
        frequency = Wake;
        view_as_skill = new HongjuVS;
        waked_skills = "qingce";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark("hongju") > 0) return false;
        if (player->canWake("hongju")) return true;
        if (player->getPile("rong").length() >= 3) {
            if (room->alivePlayerCount() < room->getAllPlayers(true).length())
                return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("guanqiujian", "hongju");
        room->setPlayerMark(player, "hongju", 1);
        if (!player->isKongcheng())
            room->askForUseCard(player, "@@hongju", "@hongju");
        if (player->isAlive() && room->changeMaxHpForAwakenSkill(player))
            room->handleAcquireDetachSkills(player, "qingce");
        return false;
    }
};

QingceCard::QingceCard()
{
    handling_method = Card::MethodNone;
    will_throw = false;
}

bool QingceCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getCardCount(true, true) > to_select->getHandcardNum();
}

void QingceCard::onEffect(const CardEffectStruct &effect) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "qingce", QString());
    Room *room = effect.to->getRoom();
    room->throwCard(this, reason, NULL);
    if (effect.to->getCards("ej").isEmpty()) return;
    int card_id = room->askForCardChosen(effect.from, effect.to, "ej", "qingce", false, Card::MethodDiscard);
    room->throwCard(card_id, room->getCardPlace(card_id) == Player::PlaceDelayedTrick ? NULL : effect.to, effect.from);
}

class Qingce : public OneCardViewAsSkill
{
public:
    Qingce() : OneCardViewAsSkill("qingce")
    {
        filter_pattern = ".|.|.|rong";
        expand_pile = "rong";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->getPile("rong").isEmpty();
    }

    const Card *viewAs(const Card *originalCard) const
    {
        QingceCard *card = new QingceCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Leiyongsi : public TriggerSkill
{
public:
    Leiyongsi() : TriggerSkill("leiyongsi")
    {
        events << DrawNCards << EventPhaseEnd;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == DrawNCards) {
            QStringList kingdoms;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (kingdoms.contains(p->getKingdom())) continue;
                kingdoms << p->getKingdom();
            }
            LogMessage log;
            log.type = "#LeiyongsiDrawNum";
            log.from = player;
            log.arg = "leiyongsi";
            log.arg2 = QString::number(kingdoms.length());
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
            data = QVariant::fromValue(kingdoms.length());
        } else {
            if (player->getPhase() != Player::Play) return false;
            int point = player->getMark("damage_point_round");
            LogMessage log;
            log.from = player;
            log.arg = QString::number(point);
            if (point == 0) {
                int draw = player->getHp() - player->getHandcardNum();
                if (draw < 0) draw = 0;
                log.type = "#LeiyongsiDraw";
                log.arg2 = QString::number(draw);
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                if (draw > 0)
                    player->drawCards(draw, objectName());
            } else if (point > 1) {
                log.type = "#LeiyongsiMax";
                log.arg2 = QString::number(player->getLostHp());
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                room->addPlayerMark(player, "leiyongsi-Clear");
            }
        }
        return false;
    }
};

class LeiyongsiMaxCards : public MaxCardsSkill
{
public:
    LeiyongsiMaxCards() : MaxCardsSkill("#leiyongsimaxmards")
    {
    }

    int getFixed(const Player *target) const
    {
        if (target->hasSkill("leiyongsi") && target->getMark("leiyongsi-Clear") > 0)
            return target->getLostHp();
        else
            return -1;
    }
};

class Leiweidi : public TriggerSkill
{
public:
    Leiweidi() : TriggerSkill("leiweidi$")
    {
        events << CardsMoveOneTime << EventPhaseEnd;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!player->hasLordSkill(this)) return false;
        if (player->getPhase() != Player::Discard) return false;
        if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                QVariantList discard_list = player->tag["leiweidi_ids"].toList();
                foreach (int id, move.card_ids) {
                    if (discard_list.contains(QVariant(id))) continue;
                    discard_list << id;
                }
                player->tag["leiweidi_ids"] = discard_list;
            }
        } else {
            if (player->getPhase() != Player::Discard) return false;
            QVariantList discard_list = player->tag["leiweidi_ids"].toList();
            player->tag.remove("leiweidi_ids");
            QList<ServerPlayer *> quns;
            foreach(ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getKingdom() == "qun")
                    quns << p;
            }
            if (quns.isEmpty()) return false;
            if (player->isDead()) return false;

            QList<int> dis_list;
            foreach (QVariant card_data, discard_list) {
                int card_id = card_data.toInt();
                if (room->getCardPlace(card_id) == Player::DiscardPile)
                    dis_list << card_id;
            }
            if (dis_list.isEmpty()) return false;

            QList<ServerPlayer *> _player;
            _player << player;
            CardsMoveStruct move(dis_list, NULL, player, Player::DiscardPile, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_RECYCLE, player->objectName(), objectName(), QString()));
            QList<CardsMoveStruct> moves;
            moves.append(move);
            room->notifyMoveCards(true, moves, true, _player);
            room->notifyMoveCards(false, moves, true, _player);

            QList<int> origin_list = dis_list;
            bool flag = true;
            int num = 0;
            while (!dis_list.isEmpty()) {
                num++;
                if (num != 1)
                    flag = false;
                ServerPlayer *give = room->askForYiji(player, dis_list, objectName(), false, true, true, 1, quns,
                                                       CardMoveReason(), "leiweidi-give", flag);
                if (!give) break;
                CardsMoveStruct move(QList<int>(), player, NULL, Player::PlaceHand, Player::DiscardPile,
                    CardMoveReason(CardMoveReason::S_REASON_PUT, player->objectName(), NULL, objectName(), QString()));
                foreach (int id, origin_list) {
                    if (room->getCardPlace(id) != Player::DiscardPile) {
                        move.card_ids << id;
                        dis_list.removeOne(id);
                    }
                }
                origin_list = dis_list;
                QList<CardsMoveStruct> moves;
                moves.append(move);
                room->notifyMoveCards(true, moves, false, _player);
                room->notifyMoveCards(false, moves, false, _player);
                if (!player->isAlive()) return false;
                if (give && give->isAlive())
                    quns.removeOne(give);
                if (quns.isEmpty()) break;
            }

            if (!dis_list.isEmpty()) {
                CardsMoveStruct move(dis_list, player, NULL, Player::PlaceHand, Player::DiscardPile,
                                     CardMoveReason(CardMoveReason::S_REASON_PUT, player->objectName(), NULL, objectName(), QString()));
                QList<CardsMoveStruct> moves;
                moves.append(move);
                room->notifyMoveCards(true, moves, false, _player);
                room->notifyMoveCards(false, moves, false, _player);
            }
        }
        return false;
    }
};

class Congjian : public TriggerSkill
{
public:
    Congjian() : TriggerSkill("congjian")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("TrickCard") || use.to.length() <= 1) return false;
        if (!use.to.contains(player) || player->isNude()) return false;
        QList<ServerPlayer *> targets = use.to;
        targets.removeOne(player);
        if (targets.isEmpty()) return false;
        QList<int> cards = player->handCards() + player->getEquipsId();
        QList<int> give_ids = room->askForyiji(player, cards, objectName(), false, true, true, 1, targets, CardMoveReason(), "@congjian-give", true);
        if (give_ids.isEmpty()) return false;
        int num = 1;
        if (Sanguosha->getCard(give_ids.first())->isKindOf("EquipCard"))
            num++;
        player->drawCards(num, objectName());
        return false;
    }

    int getEffectIndex(const ServerPlayer *player, const Card *) const
    {
        int index = qrand() % 2 + 1;
        if (player->getGeneralName().contains("sp_tongyuan") || player->getGeneral2Name().contains("sp_tongyuan"))
            index = 3;
        return index;
    }
};

XiongluanCard::XiongluanCard()
{
}

bool XiongluanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void XiongluanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    room->removePlayerMark(effect.from, "@xiongluanMark");
    room->doSuperLightbox("zhangxiu", "xiongluan");
    effect.from->throwJudgeArea();
    effect.from->throwEquipArea();

    room->addPlayerMark(effect.from, "xiongluan_from-Clear");
    room->addPlayerMark(effect.to, "xiongluan_to-Clear");
}

class Xiongluan : public ZeroCardViewAsSkill
{
public:
    Xiongluan() : ZeroCardViewAsSkill("xiongluan")
    {
        frequency = Limited;
        limit_mark = "@xiongluanMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@xiongluanMark") >= 1 && (player->hasJudgeArea() || player->hasEquipArea());
    }

    const Card *viewAs() const
    {
        return new XiongluanCard;
    }
};

class XiongluanTargetMod : public TargetModSkill
{
public:
    XiongluanTargetMod() : TargetModSkill("#xiongluan-target")
    {
        frequency = Limited;
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("xiongluan_from-Clear") > 0 && to && to->getMark("xiongluan_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("xiongluan_from-Clear") > 0 && to && to->getMark("xiongluan_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

class XiongluanLimit : public CardLimitSkill
{
public:
    XiongluanLimit() : CardLimitSkill("#xiongluan-limit")
    {
        frequency = Limited;
    }

    QString limitList(const Player *target) const
    {
        if (target->getMark("xiongluan_to-Clear") > 0)
            return "use,response";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->getMark("xiongluan_to-Clear") > 0)
            return ".|.|.|hand";
        else
            return QString();
    }
};

class OLZhengrong : public TriggerSkill
{
public:
    OLZhengrong() : TriggerSkill("olzhengrong")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") && !(use.card->isKindOf("TrickCard") && use.card->isDamageCard())) return false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, use.to) {
            if (p->getHandcardNum() >= player->getHandcardNum() && !p->isNude())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@olzhengrong-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        int card_id = room->askForCardChosen(player, target, "he", "olzhengrong");
        player->addToPile("rong", card_id);
        return false;
    }
};

OLHongjuCard::OLHongjuCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
    target_fixed = true;
}

void OLHongjuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QList<int> pile = card_use.from->getPile("rong");
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
    log.arg = QString::number(to_pile.length());
    log.arg2 = "olhongju";
    room->sendLog(log);

    card_use.from->addToPile("rong", to_pile);

    DummyCard to_handcard_x(to_handcard);
    CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, card_use.from->objectName());
    room->obtainCard(card_use.from, &to_handcard_x, reason, true);
}

class OLHongjuVS : public ViewAsSkill
{
public:
    OLHongjuVS() : ViewAsSkill("olhongju")
    {
        response_pattern = "@@olhongju";
        expand_pile = "rong";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() < 2 * Self->getPile("rong").length())
            return !to_select->isEquipped();

        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hand = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card))
                hand++;
            else if (Self->getPile("rong").contains(card->getEffectiveId()))
                pile++;
        }

        if (hand == pile) {
            OLHongjuCard *c = new OLHongjuCard;
            c->addSubcards(cards);
            return c;
        }

        return NULL;
    }
};

class OLHongju : public PhaseChangeSkill
{
public:
    OLHongju() : PhaseChangeSkill("olhongju")
    {
        frequency = Wake;
        view_as_skill = new OLHongjuVS;
        waked_skills = "olqingce";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        if (player->getPhase() != Player::Start || player->getMark("olhongju") > 0) return false;
        if (player->canWake("olhongju")) return true;
        if (player->getPile("rong").length() >= 3)
            return true;
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("ol_guanqiujian", "olhongju");
        room->setPlayerMark(player, "olhongju", 1);
        if (!player->isKongcheng())
            room->askForUseCard(player, "@@olhongju", "@olhongju");
        if (player->isAlive() && room->changeMaxHpForAwakenSkill(player))
            room->handleAcquireDetachSkills(player, "olqingce");
        return false;
    }
};

OLQingceCard::OLQingceCard()
{
    will_throw = false;
}

bool OLQingceCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getCardCount(true, true) > to_select->getHandcardNum();
}

void OLQingceCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    //把顺序调整成先获得“荣”，再弃牌
    QList<int> list;
    foreach (int id, this->getSubcards()) {
        if (effect.from->getPile("rong").contains(id))
            list << id;
    }
    foreach (int id, this->getSubcards()) {
        if (!list.contains(id))
            list << id;
    }

    foreach (int id, list) {
        if (effect.from->getPile("rong").contains(id)) {
            LogMessage log;
            log.type = "$KuangbiGet";
            log.from = effect.from;
            log.arg = "rong";
            log.card_str = Sanguosha->getCard(id)->toString();
            room->sendLog(log);
            room->obtainCard(effect.from, id, true);
        }
        else {
            CardMoveReason reason(CardMoveReason::S_REASON_THROW, effect.from->objectName(), "olqingce", QString());
            room->throwCard(Sanguosha->getCard(id), reason, effect.from, NULL);
        }
    }

    if (effect.to->getCards("ej").isEmpty()) return;
    int card_id = room->askForCardChosen(effect.from, effect.to, "ej", "olqingce", false, Card::MethodDiscard);
    room->throwCard(card_id, room->getCardPlace(card_id) == Player::PlaceDelayedTrick ? NULL : effect.to, effect.from);
}

class OLQingce : public ViewAsSkill
{
public:
    OLQingce() : ViewAsSkill("olqingce")
    {
        expand_pile = "rong";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->getPile("rong").isEmpty();
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() >= 2 || to_select->isEquipped()) return false;
        if (selected.isEmpty()) return true;
        if (Self->getPile("rong").contains(selected.first()->getEffectiveId()))
            return Self->getHandcards().contains(to_select);
        else
            return Self->getPile("rong").contains(to_select->getEffectiveId());
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hand = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card))
                hand++;
            else if (Self->getPile("rong").contains(card->getEffectiveId()))
                pile++;
        }

        if (hand == pile && hand == 1) {
            OLQingceCard *card = new OLQingceCard;
            card->addSubcards(cards);
            return card;
        }
        return NULL;
    }
};

class MobileZhengrong : public TriggerSkill
{
public:
    MobileZhengrong() : TriggerSkill("mobilezhengrong")
    {
        events << PreCardUsed << CardUsed << PreCardResponded;
        frequency = Compulsory;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "mobilezhengrong_usedtimes-PlayClear");
        } else if (event == CardUsed) {
            if (player->getMark("mobilezhengrong_usedtimes-PlayClear") % 2 != 0) return false;
            if (!player->hasSkill(this)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            //if (use.to.isEmpty() || (use.to.length() == 1 && use.to.first() == player)) return false;

            bool has_other = false;
            foreach (ServerPlayer *p, use.to) {
                if (p != player) {
                    has_other = true;
                    break;
                }
            }
            if (!has_other) return  false;

            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!p->isNude())
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@mobilezhengrong-invoke", false, true);
            room->broadcastSkillInvoke(objectName());
            const Card * card = target->getCards("he").at(qrand() % target->getCards("he").length());
            player->addToPile("rong", card);
        } else {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_card->isKindOf("SkillCard") || !resp.m_isUse) return false;
            room->addPlayerMark(player, "mobilezhengrong_usedtimes-PlayClear");
        }
        return false;
    }
};

MobileHongjuCard::MobileHongjuCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
    target_fixed = true;
}

void MobileHongjuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QList<int> pile = card_use.from->getPile("rong");
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
    log.arg = QString::number(to_pile.length());
    log.arg2 = "mobilehongju";
    room->sendLog(log);

    card_use.from->addToPile("rong", to_pile);

    DummyCard to_handcard_x(to_handcard);
    CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, card_use.from->objectName());
    room->obtainCard(card_use.from, &to_handcard_x, reason, true);
}

class MobileHongjuVS : public ViewAsSkill
{
public:
    MobileHongjuVS() : ViewAsSkill("mobilehongju")
    {
        response_pattern = "@@mobilehongju";
        expand_pile = "rong";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() < 2 * Self->getPile("rong").length())
            return !to_select->isEquipped();

        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hand = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card))
                hand++;
            else if (Self->getPile("rong").contains(card->getEffectiveId()))
                pile++;
        }

        if (hand == pile) {
            MobileHongjuCard *c = new MobileHongjuCard;
            c->addSubcards(cards);
            return c;
        }

        return NULL;
    }
};

class MobileHongju : public PhaseChangeSkill
{
public:
    MobileHongju() : PhaseChangeSkill("mobilehongju")
    {
        frequency = Wake;
        view_as_skill = new MobileHongjuVS;
        waked_skills = "qingce";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark("mobilehongju") > 0) return false;
        if (player->canWake("mobilehongju")) return true;
        if (player->getPile("rong").length() >= 3) {
            if (room->alivePlayerCount() < room->getAllPlayers(true).length())
                return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("mobile_guanqiujian", "mobilehongju");
        room->setPlayerMark(player, "mobilehongju", 1);
        player->drawCards(player->getPile("rong").length(), objectName());
        if (!player->isKongcheng())
            room->askForUseCard(player, "@@mobilehongju", "@mobilehongju");
        if (player->isAlive() && room->changeMaxHpForAwakenSkill(player))
            room->handleAcquireDetachSkills(player, "qingce");
        return false;
    }
};

LeiPackage::LeiPackage()
    : Package("Lei")
{
    General *chendao = new General(this, "chendao", "shu", 4);
    chendao->addSkill(new Wanglie);
    chendao->addSkill(new WanglieMod);
    related_skills.insertMulti("wanglie", "#wangliemod");

    General *zhugezhan = new General(this, "zhugezhan", "shu", 3);
    zhugezhan->addSkill(new Zuilun);
    zhugezhan->addSkill(new Fuyin);

    General *zhoufei = new General(this, "zhoufei", "wu", 3, false);
    zhoufei->addSkill(new Liangyin);
    zhoufei->addSkill(new Kongsheng);

    General *lei_lukang = new General(this, "lei_lukang", "wu", 4);
    lei_lukang->addSkill(new Qianjie);
    lei_lukang->addSkill(new QianjieChain);
    lei_lukang->addSkill(new QianjiePindianPro);
    lei_lukang->addSkill(new Jueyan);
    lei_lukang->addSkill(new JueyanTargetMod);
    lei_lukang->addSkill(new Poshi);
    lei_lukang->addRelateSkill("huairou");
    related_skills.insertMulti("qianjie", "#qianjie-chain");
    related_skills.insertMulti("qianjie", "#qianjiepindianpro");
    related_skills.insertMulti("jueyan", "#jueyantargetmod");

    General *haozhao = new General(this, "haozhao", "wei", 4);
    haozhao->addSkill(new Zhengu);
    haozhao->addSkill(new ZhenguEffect);
    related_skills.insertMulti("zhengu", "#zhengueffect");

    General *guanqiujian = new General(this, "guanqiujian", "wei", 4);
    guanqiujian->addSkill(new Zhengrong);
    guanqiujian->addSkill(new Hongju);
    guanqiujian->addRelateSkill("qingce");

    General *ol_guanqiujian = new General(this, "ol_guanqiujian", "wei", 4);
    ol_guanqiujian->addSkill(new OLZhengrong);
    ol_guanqiujian->addSkill(new OLHongju);
    ol_guanqiujian->addRelateSkill("olqingce");

    General *mobile_guanqiujian = new General(this, "mobile_guanqiujian", "wei", 4);
    mobile_guanqiujian->addSkill(new MobileZhengrong);
    mobile_guanqiujian->addSkill(new MobileHongju);
    mobile_guanqiujian->addRelateSkill("qingce");

    General *lei_yuanshu = new General(this, "lei_yuanshu$", "qun", 4);
    lei_yuanshu->addSkill(new Leiyongsi);
    lei_yuanshu->addSkill(new LeiyongsiMaxCards);
    lei_yuanshu->addSkill(new Leiweidi);
    related_skills.insertMulti("leiyongsi", "#leiyongsimaxmards");

    General *zhangxiu = new General(this, "zhangxiu", "qun", 4);
    zhangxiu->addSkill(new Congjian);
    zhangxiu->addSkill(new Xiongluan);
    zhangxiu->addSkill(new XiongluanTargetMod);
    zhangxiu->addSkill(new XiongluanLimit);
    related_skills.insertMulti("xiongluan", "#xiongluan-target");
    related_skills.insertMulti("xiongluan", "#xiongluan-limit");

    addMetaObject<JueyanCard>();
    addMetaObject<HuairouCard>();
    addMetaObject<HongjuCard>();
    addMetaObject<QingceCard>();
    addMetaObject<XiongluanCard>();
    addMetaObject<OLHongjuCard>();
    addMetaObject<OLQingceCard>();
    addMetaObject<MobileHongjuCard>();

    skills << new Huairou << new Qingce << new OLQingce;
}

ADD_PACKAGE(Lei)
