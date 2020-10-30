#include "mobilexin.h"
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

MobileXinYinjuCard::MobileXinYinjuCard()
{
}

void MobileXinYinjuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (!effect.to->canSlash(effect.from, false) ||
            !room->askForUseSlashTo(effect.to, effect.from, "@mobilexinyinju-slash:" + effect.from->objectName(), false))
        room->addPlayerMark(effect.to, "&mobilexinyinju");
}

class MobileXinYinjuVS : public ZeroCardViewAsSkill
{
public:
    MobileXinYinjuVS() : ZeroCardViewAsSkill("mobilexinyinju")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileXinYinjuCard");
    }

    const Card *viewAs() const
    {
        return new MobileXinYinjuCard;
    }
};

class MobileXinYinju : public PhaseChangeSkill
{
public:
    MobileXinYinju() : PhaseChangeSkill("mobilexinyinju")
    {
        view_as_skill = new MobileXinYinjuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&mobilexinyinju") > 0 && target->getPhase() == Player::Start;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#ZhenguEffect";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);
        room->setPlayerMark(player, "&mobilexinyinju", 0);
        if (!player->isSkipped(Player::Play))
            player->skip(Player::Play);
        if (!player->isSkipped(Player::Discard))
            player->skip(Player::Discard);
        return false;
    }
};

class MobileXinChijie : public TriggerSkill
{
public:
    MobileXinChijie() : TriggerSkill("mobilexinchijie")
    {
        events << TargetConfirming;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (use.to.length() != 1 || !use.to.contains(player) || use.from == player || player->getMark("mobilexinchijie-Clear") > 0) return false;
        if (!player->askForSkillInvoke(this, data)) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, "mobilexinchijie-Clear");

        JudgeStruct judge;
        judge.who = player;
        judge.reason = objectName();
        judge.pattern = ".|.|6~100";
        judge.good = true;
        room->judge(judge);

        if (!judge.isGood()) return false;
        use.to.removeOne(player);
        data = QVariant::fromValue(use);
        return false;
    }
};

MobileXinCunsiCard::MobileXinCunsiCard()
{
}

bool MobileXinCunsiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void MobileXinCunsiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->turnOver();
    if (effect.to->isDead()) return;
    Room *room = effect.from->getRoom();
    QList<int> slashs, ids = room->getDrawPile() + room->getDiscardPile();
    foreach (int id, ids) {
        if (Sanguosha->getCard(id)->isKindOf("Slash"))
            slashs << id;
    }
    if (!slashs.isEmpty())
        room->obtainCard(effect.to, slashs.at(qrand() % slashs.length()));
    room->addPlayerMark(effect.to, "&mobilexincunsi");
}

class MobileXinCunsiVS : public ZeroCardViewAsSkill
{
public:
    MobileXinCunsiVS() : ZeroCardViewAsSkill("mobilexincunsi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileXinCunsiCard") && player->faceUp();
    }

    const Card *viewAs() const
    {
        return new MobileXinCunsiCard;
    }
};

class MobileXinCunsi : public TriggerSkill
{
public:
    MobileXinCunsi() : TriggerSkill("mobilexincunsi")
    {
        events << DamageCaused << PreCardUsed;
        view_as_skill = new MobileXinCunsiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            int mark = player->getMark("&mobilexincunsi");
            if (mark <= 0) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            room->setPlayerMark(player, "&mobilexincunsi", 0);
            int n = room->getTag("mobilexincunsi_damage_" + use.card->toString()).toInt();
            room->setTag("mobilexincunsi_damage_" + use.card->toString(), n + mark);
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            int n = room->getTag("mobilexincunsi_damage_" + damage.card->toString()).toInt();
            room->removeTag("mobilexincunsi_damage_" + damage.card->toString());

            LogMessage log;
            log.type = "#MobileXinCunsiDamage";
            log.from = damage.from;
            log.arg = QString::number(damage.damage);
            damage.damage += n;
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class MobileXinGuixiu : public TriggerSkill
{
public:
    MobileXinGuixiu() : TriggerSkill("mobilexinguixiu")
    {
        events << Damaged << TurnedOver;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == Damaged) {
            if (player->faceUp()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->turnOver();
        } else {
            if (!player->faceUp()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class SecondMobileXinGuixiu : public PhaseChangeSkill
{
public:
    SecondMobileXinGuixiu() : PhaseChangeSkill("secondmobilexinguixiu")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        int hp = player->getHp();
        Room *room = player->getRoom();
        if (hp % 2 == 0) {
            if (player->isWounded())
                room->sendCompulsoryTriggerLog(player, this);
            room->recover(player, RecoverStruct(player));
        } else {
            room->sendCompulsoryTriggerLog(player, this);
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class SecondMobileXinQingyu : public TriggerSkill
{
public:
    SecondMobileXinQingyu() : TriggerSkill("secondmobilexinqingyu")
    {
        events << EventPhaseStart << DamageInflicted << Dying;
        shiming_skill = true;
        waked_skills = "secondmobilexinxuancun";
        frequency = NotCompulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark(objectName()) > 0) return false;
        if  (event == DamageInflicted) {
            int num = 0;
            foreach (int id, player->handCards() + player->getEquipsId()) {
                if (!player->canDiscard(player, id)) continue;
                num++;
                if (num > 1) break;
            }
            if (num < 2) return false;
            room->sendCompulsoryTriggerLog(player, this, 1);
            room->askForDiscard(player, objectName(), 2, 2, false, true);
            return true;
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Start) return false;
            if (player->getLostHp() == 0 && player->isKongcheng()) {
                room->sendShimingLog(player, this);
                room->handleAcquireDetachSkills(player, "secondmobilexinxuancun");
            }
        } else {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who != player) return false;
            room->sendShimingLog(player, this, false);
            room->loseMaxHp(player);
        }
        return false;
    }
};

class SecondMobileXinXuancun : public PhaseChangeSkill
{
public:
    SecondMobileXinXuancun() : PhaseChangeSkill("secondmobilexinxuancun")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::NotActive;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;
            int draw = p->getHp() - p->getHandcardNum();
            if (draw <= 0 || !p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);
            draw = qMin(draw, 2);
            player->drawCards(draw, objectName());
        }
        return false;
    }
};

class MobileXinHeji : public TriggerSkill
{
public:
    MobileXinHeji() : TriggerSkill("mobilexinheji")
    {
        events << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.length() != 1) return false;
        if (!use.card->isKindOf("Duel") && !(use.card->isKindOf("Slash") && use.card->isRed())) return false;
        if (use.to.first()->isDead()) return false;

        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->deleteLater();
        Duel *duel = new Duel(Card::NoSuit, 0);
        duel->deleteLater();

        ServerPlayer *to = use.to.first();

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (to->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || p == to) continue;
            if (p->isLocked(slash, true) && p->isLocked(duel, true)) continue;
            if (p->isProhibited(to, duel) && p->isProhibited(to, slash)) continue;

            QStringList hand_pile_names;
            foreach (QString pile, p->getPileNames()) {
                if (pile.startsWith("&") || pile == "wooden_ox")
                    hand_pile_names << pile;
            }

            const Card *card = room->askForCard(p, "Slash,Duel|.|.|hand," + hand_pile_names.join(","), "@mobilexinheji-use:" + to->objectName(), data,
                               Card::MethodUse, to, true);
            if (!card) continue;

            QList<int> subcards;
            if (card->isVirtualCard())
                subcards = card->getSubcards();
            else
                subcards << card->getEffectiveId();
            if (subcards.isEmpty()) continue;

            QList<int> hand_pile = p->getHandPile(), hand_ids = p->handCards();
            bool is_hand_card = true;
            foreach (int id, subcards) {
                if (!hand_pile.contains(id) && !hand_ids.contains(id)) {
                    is_hand_card = false;
                    break;
                }
            }
            if (!is_hand_card) continue;

            LogMessage log;
            log.type = "#InvokeSkill";
            log.arg = "mobilexinheji";
            log.from = p;
            room->sendLog(log);
            room->notifySkillInvoked(p, "mobilexinheji");
            room->broadcastSkillInvoke("mobilexinheji");

            room->useCard(CardUseStruct(card, p, to), false);

            if (!card->isVirtualCard() && p->isAlive()) {
                QList<int> reds, ids = room->getDrawPile() + room->getDiscardPile();
                foreach (int id, ids) {
                    if (Sanguosha->getCard(id)->isRed())
                        reds << id;
                }
                if (!reds.isEmpty())
                    room->obtainCard(p, reds.at(qrand() % reds.length()));
            }
        }
        return false;
    }
};

MobileXinMouliCard::MobileXinMouliCard()
{
    handling_method = Card::MethodNone;
    will_throw = false;
}

void MobileXinMouliCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->giveCard(effect.from, effect.to, this, "mobilexinmouli");
    if (effect.to->isDead()) return;
    //effect.to->gainMark("&mobilexinli+#" + effect.from->objectName());
    LogMessage log;
    log.type = "#GetMark";
    log.from = effect.to;
    log.arg = "mobilexinli";
    log.arg2 = QString::number(1);
    room->sendLog(log);
    room->addPlayerMark(effect.to, "&mobilexinli+#" + effect.from->objectName());
}

class MobileXinMouliVS : public OneCardViewAsSkill
{
public:
    MobileXinMouliVS() : OneCardViewAsSkill("mobilexinmouli")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileXinMouliCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileXinMouliCard *card = new MobileXinMouliCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class MobileXinMouli : public TriggerSkill
{
public:
    MobileXinMouli() : TriggerSkill("mobilexinmouli")
    {
        events << MarkChanged << EventPhaseStart << CardFinished;
        view_as_skill = new MobileXinMouliVS;
    }

    bool hasMouLiMark(ServerPlayer *player) const
    {
        foreach (QString mark, player->getMarkNames()) {
            if (!mark.startsWith("&mobilexinli") || player->getMark(mark) <= 0) continue;
            return true;
        }
        return false;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == MarkChanged) {
            MarkStruct mark = data.value<MarkStruct>();
            if (!mark.name.startsWith("&mobilexinli")) return false;
            if (hasMouLiMark(player)) {
                if (player->hasSkill("mobilexinmouli_effect", true) || player->isDead()) return false;
                room->attachSkillToPlayer(player, "mobilexinmouli_effect");
            } else {
                if (!player->hasSkill("mobilexinmouli_effect", true)) return false;
                room->detachSkillFromPlayer(player, "mobilexinmouli_effect", true);
            }
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;

            foreach (ServerPlayer *p, room->getAllPlayers(true))
                room->setPlayerMark(p, "mobilexinmouli_first_finish-Keep", 0);

            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead()) continue;
                int num = p->getMark("&mobilexinli+#" + player->objectName());
                if (num <= 0) continue;

                LogMessage log;
                log.type = "#LoseMark";
                log.from = p;
                log.arg = "mobilexinli";
                log.arg2 = QString::number(num);
                room->sendLog(log);

                room->setPlayerMark(p, "&mobilexinli+#" + player->objectName(), 0);
            }
        } else if (event == CardFinished) {  //偷懒，改成第一次结算完，而不是使用的第一张结算完
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.from || use.from->getMark("mobilexinmouli_first_finish-Keep") > 0) return false;
            if (use.card->isKindOf("Slash") || use.card->isKindOf("Jink")) {
                room->addPlayerMark(use.from, "mobilexinmouli_first_finish-Keep");
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isDead() || !p->hasSkill(this)) continue;
                    if (use.from->getMark("&mobilexinli+#" + p->objectName()) > 0) {
                        room->sendCompulsoryTriggerLog(p, this);
                        p->drawCards(3, objectName());
                    }
                }
            }
        }
        return false;
    }
};

class MobileXinMouliEffect : public OneCardViewAsSkill
{
public:
    MobileXinMouliEffect() : OneCardViewAsSkill("mobilexinmouli_effect")
    {
        attached_lord_skill = true;
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        const Card *card = to_select;

        switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
        case CardUseStruct::CARD_USE_REASON_PLAY: {
            return card->isBlack();
        }
        case CardUseStruct::CARD_USE_REASON_RESPONSE:
        case CardUseStruct::CARD_USE_REASON_RESPONSE_USE: {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern.contains("slash") || pattern.contains("Slash"))
                return card->isBlack();
            else if (pattern == "jink")
                return card->isRed();
        }
        default:
            return false;
        }
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
            return false;
        return pattern == "jink" || pattern.contains("slash") || pattern.contains("Slash");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (originalCard->isRed()) {
            Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
            jink->addSubcard(originalCard);
            jink->setSkillName(objectName());
            return jink;
        } else if (originalCard->isBlack()) {
            Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
            slash->addSubcard(originalCard);
            slash->setSkillName(objectName());
            return slash;
        } else
            return NULL;
    }
};

class MobileXinZifu : public TriggerSkill
{
public:
    MobileXinZifu() : TriggerSkill("mobilexinzifu")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who == player) return false;
        if (death.who->getMark("&mobilexinli+#" + player->objectName()) <= 0) return false;
        room->sendCompulsoryTriggerLog(player, this);
        room->loseMaxHp(player, 2);
        return false;
    }
};

class MobileXinXunyi : public TriggerSkill
{
public:
    MobileXinXunyi() : TriggerSkill("mobilexinxunyi")
    {
        events << GameStart << Death;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GameStart) {
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@mobilexinxunyi-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(this);

            LogMessage log;
            log.type = "#GetMark";
            log.from = target;
            log.arg = "mobilexinyi";
            log.arg2 = QString::number(1);
            room->sendLog(log);
            room->addPlayerMark(target, "&mobilexinyi+#" + player->objectName());
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player) return false;
            int mark = death.who->getMark("&mobilexinyi+#" + player->objectName());
            if (mark <= 0) return false;

            QList<ServerPlayer *> players = room->getOtherPlayers(death.who);
            players.removeOne(player);
            if (players.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@mobilexinxunyi-transfer", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(this);

            LogMessage log;
            log.type = "#MobileXinXunyiTransferMark";
            log.from = player;
            log.to << target;
            log.arg = "mobilexinyi";
            log.arg2 = QString::number(mark);
            room->sendLog(log);
            room->setPlayerMark(death.who, "&mobilexinyi+#" + player->objectName(), 0);
            room->addPlayerMark(target, "&mobilexinyi+#" + player->objectName(), mark);
        }
        return false;
    }
};

class MobileXinXunyiEffect : public TriggerSkill
{
public:
    MobileXinXunyiEffect() : TriggerSkill("#mobilexinxunyi")
    {
        events << Damaged << Damage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    QList<ServerPlayer *> getYiTargets(ServerPlayer *player, int type, bool discard) const
    {
        QList<ServerPlayer *> targets;
        Room *room = player->getRoom();

        if (type == 0) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("&mobilexinyi+#" + player->objectName()) > 0 && player->hasSkill("mobilexinxunyi")) {
                    if (!discard || p->canDiscard(p, "he"))
                        targets << p;
                }
            }
        } else {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->getMark("&mobilexinyi+#" + p->objectName()) > 0 && p->hasSkill("mobilexinxunyi")) {
                    if (!discard || p->canDiscard(p, "he"))
                        targets << p;
                }
            }
        }

        return targets;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (event == Damaged) {
            /*for (int num = 0; num < 2; num++) {
                QList<ServerPlayer *> targets = getYiTargets(player, num);
                if (damage.from)
                    targets.removeOne(damage.from);
                foreach (ServerPlayer *target, targets) {
                    for (int i = 0; i < damage.damage; i++) {
                        if (target->isDead() || !target->canDiscard(target, "he")) break;
                        room->sendCompulsoryTriggerLog(player, "mobilexinxunyi", true, true);
                        room->askForDiscard(target, "mobilexinxunyi", 1, 1, false, true);
                    }
                }
            }*/
            if (player->hasSkill("mobilexinxunyi")) {
                QList<ServerPlayer *> targets = getYiTargets(player, 0, true);
                if (damage.from)
                    targets.removeOne(damage.from);
                for (int i = 0; i < damage.damage; i++) {
                    room->sendCompulsoryTriggerLog(player, "mobilexinxunyi", true, true);
                    foreach (ServerPlayer *target, targets) {
                        if (target->isDead() || !target->canDiscard(target, "he") || !player->hasSkill("mobilexinxunyi")) break;
                        room->askForDiscard(target, "mobilexinxunyi", 1, 1, false, true);
                    }
                }
            }

            QList<ServerPlayer *> targets = getYiTargets(player, 1, true);
            if (damage.from)
                targets.removeOne(damage.from);
            for (int i = 0; i < damage.damage; i++) {
                foreach (ServerPlayer *target, targets) {
                    if (target->isDead() || !target->hasSkill("mobilexinxunyi") || !target->canDiscard(target, "he")) continue;
                    room->sendCompulsoryTriggerLog(target, "mobilexinxunyi", true, true);
                    room->askForDiscard(target, "mobilexinxunyi", 1, 1, false, true);
                }
            }
        } else {
            if (player->hasSkill("mobilexinxunyi")) {
                QList<ServerPlayer *> targets = getYiTargets(player, 0, false);
                if (damage.to->getMark("&mobilexinyi+#" + player->objectName()) > 0)
                    targets.removeOne(damage.to);
                for (int i = 0; i < damage.damage; i++) {
                    room->sendCompulsoryTriggerLog(player, "mobilexinxunyi", true, true);
                    //room->drawCards(targets, 1, objectName());
                    foreach (ServerPlayer *target, targets) {
                        if (target->isDead()) continue;
                        target->drawCards(1, "mobilexinxunyi");
                    }
                }
            }

            QList<ServerPlayer *> targets = getYiTargets(player, 1, false);
            if (player->getMark("&mobilexinyi+#" + damage.to->objectName()) > 0)
                targets.removeOne(damage.to);
            foreach (ServerPlayer *target, targets) {
                if (target->isDead() || !target->hasSkill("mobilexinxunyi")) continue;
                room->sendCompulsoryTriggerLog(target, "mobilexinxunyi", true, true);
                for (int i = 0; i < damage.damage; i++) {
                    if (target->isDead() || !target->hasSkill("mobilexinxunyi")) break;
                    target->drawCards(1, "mobilexinxunyi");
                }
            }
        }
        return false;
    }
};

class MobileXinXianghai : public FilterSkill
{
public:
    MobileXinXianghai() : FilterSkill("mobilexinxianghai")
    {
    }

    bool viewFilter(const Card *to_select) const
    {
        Room *room = Sanguosha->currentRoom();
        Player::Place place = room->getCardPlace(to_select->getEffectiveId());
        return to_select->isKindOf("EquipCard") && place == Player::PlaceHand;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Analeptic *ana = new Analeptic(originalCard->getSuit(), originalCard->getNumber());
        ana->setSkillName(objectName());
        WrappedCard *card = Sanguosha->getWrappedCard(originalCard->getId());
        card->takeOver(ana);
        return card;
    }
};

class MobileXinXianghaiMax : public MaxCardsSkill
{
public:
    MobileXinXianghaiMax() : MaxCardsSkill("#mobilexinxianghai")
    {
    }

    int getExtra(const Player *target) const
    {
        int reduce = 0;
        foreach (const Player *p, target->getAliveSiblings()) {
            if (!p->hasSkill("mobilexinxianghai")) continue;
            reduce--;
        }
        return reduce;
    }
};

MobileXinChuhaiCard::MobileXinChuhaiCard()
{
    target_fixed = true;
}

void MobileXinChuhaiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(1, "mobilexinchuhai");
    if (source->isDead()) return;

    QList<ServerPlayer *> pindian_targets;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (!source->canPindian(p)) continue;
        pindian_targets << p;
    }
    if (pindian_targets.isEmpty()) return;

    ServerPlayer *pindian_target = room->askForPlayerChosen(source, pindian_targets, "mobilexinchuhai", "@mobilexinchuhai-invoke", false);
    room->doAnimate(1, source->objectName(), pindian_target->objectName());
    if (!source->canPindian(pindian_target, false)) return;

    if (source->pindian(pindian_target, "mobilexinchuhai")) {
        if (source->isDead() || pindian_target->isDead()) return;

        room->addPlayerMark(source, "mobilexinchuhai_from-PlayClear");
        room->addPlayerMark(pindian_target, "mobilexinchuhai_to-PlayClear");

        if (!pindian_target->isKongcheng()) {
            room->doGongxin(source, pindian_target, QList<int>(), "mobilexinchuhai");

            QList<int> type_ids, get_ids;
            foreach (const Card *c, pindian_target->getHandcards()) {
                int type_id = c->getTypeId();
                if (!type_ids.contains(type_id))
                    type_ids << type_id;
            }

            foreach (int type_id, type_ids) {
                QList<int> cards = room->getDiscardPile() + room->getDrawPile(), list;
                foreach (int id, cards) {
                    if (Sanguosha->getCard(id)->getTypeId() == type_id)
                        list << id;
                }
                if (!list.isEmpty()) {
                    int id = list.at(qrand() % list.length());
                    get_ids << id;
                }
            }

            if (!get_ids.isEmpty()) {
                DummyCard get(get_ids);
                room->obtainCard(source, &get, true);
            }
        }
    }
}

class MobileXinChuhaiVS : public ZeroCardViewAsSkill
{
public:
    MobileXinChuhaiVS() : ZeroCardViewAsSkill("mobilexinchuhai")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileXinChuhaiCard");
    }

    const Card *viewAs() const
    {
        return new MobileXinChuhaiCard;
    }
};

class MobileXinChuhai : public TriggerSkill
{
public:
    MobileXinChuhai() : TriggerSkill("mobilexinchuhai")
    {
        events << Damage;
        view_as_skill = new MobileXinChuhaiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("mobilexinchuhai_from-PlayClear") > 0 && target->hasEquipArea()
                && target->getEquips().length() < 5;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->getMark("mobilexinchuhai_to-PlayClear") <= 0) return false;

        QList<int> cards = room->getDiscardPile() + room->getDrawPile();
        QList<const Card *> equips;
        foreach (int id, cards) {
            const Card *card = Sanguosha->getCard(id);
            if (!card->isKindOf("EquipCard")) continue;
            const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
            if (!equip) continue;
            int equip_index = static_cast<int>(equip->location());
            if (player->getEquip(equip_index) || !player->hasEquipArea(equip_index)) continue;
            equips << card;
        }

        if (equips.isEmpty()) return false;

        room->sendCompulsoryTriggerLog(player, this);
        const Card *equip = equips.at(qrand() % equips.length());

        LogMessage log;
        log.type = room->getCardPlace(equip->getEffectiveId()) == Player::DrawPile ? "$MobileXinChuhaiPutEquipFromDrawPile" : "$MobileXinChuhaiPutEquipFromDiscardPile";
        log.from = player;
        log.card_str = equip->toString();
        room->sendLog(log);

        room->moveCardTo(equip, NULL, player, Player::PlaceEquip,
            CardMoveReason(CardMoveReason::S_REASON_PUT,
            player->objectName(), "mobilexinchuhai", QString()));


        return false;
    }
};

class MobileXinMingshi : public MasochismSkill
{
public:
    MobileXinMingshi() : MasochismSkill("mobilexinmingshi")
    {
        frequency = Compulsory;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        if (!damage.from) return;
        Room *room = player->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            if (damage.from->isDead() || !damage.from->canDiscard(damage.from, "he")) return;
            if (!player->hasSkill(this)) return;
            room->sendCompulsoryTriggerLog(player, this);
            room->askForDiscard(damage.from, objectName(), 1, 1, false, true);
        }
    }
};

MobileXinLirangCard::MobileXinLirangCard()
{
    target_fixed = true;
}

void MobileXinLirangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> hands = source->handCards(), handcards;
    source->throwAllHandCards();
    if (source->isDead()) return;

    foreach (int id, hands) {
        if (room->getCardPlace(id) == Player::DiscardPile)
            handcards << id;
    }
    if (handcards.isEmpty()) return;

    int hp = source->getHp();
    if (hp < 1) return;

    room->setPlayerFlag(source, "mobilexinlirang_InTempMoving");

    CardMoveReason r(CardMoveReason::S_REASON_UNKNOWN, source->objectName());
    CardsMoveStruct fake_move(handcards, NULL, source, Player::DiscardPile, Player::PlaceHand, r);
    QList<CardsMoveStruct> moves;
    moves << fake_move;
    QList<ServerPlayer *> _source;
    _source << source;
    room->notifyMoveCards(true, moves, true, _source);
    room->notifyMoveCards(false, moves, true, _source);

    int num = qMin(hp, handcards.length());
    QList<int> ids = room->askForyiji(source, handcards, "mobilexinlirang", false, true, true, num,
                                      room->getOtherPlayers(source), CardMoveReason(), "@mobilexinlirang-give:" + QString::number(num));

    foreach (int id, ids)
        handcards.removeOne(id);
    if (!ids.isEmpty()) {
        CardsMoveStruct move(ids, source, NULL, Player::PlaceHand, Player::DiscardPile,
            CardMoveReason(CardMoveReason::S_REASON_UNKNOWN, source->objectName(), "mobilexinlirang", QString()));
        QList<CardsMoveStruct> moves;
        moves.append(move);
        room->notifyMoveCards(true, moves, false, _source);
        room->notifyMoveCards(false, moves, false, _source);
    }

    if (!handcards.isEmpty()) {
        CardsMoveStruct fake_move2(handcards, source, NULL, Player::PlaceHand, Player::DiscardPile, r);
        QList<CardsMoveStruct> moves2;
        moves2 << fake_move2;
        room->notifyMoveCards(true, moves2, true, _source);
        room->notifyMoveCards(false, moves2, true, _source);
    }

    room->setPlayerFlag(source, "-mobilexinlirang_InTempMoving");

    if (ids.isEmpty()) return;
    source->drawCards(1, "mobilexinlirang");
}

class MobileXinLirang : public ZeroCardViewAsSkill
{
public:
    MobileXinLirang() : ZeroCardViewAsSkill("mobilexinlirang")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileXinLirangCard") && player->canDiscard(player, "h");
    }

    const Card *viewAs() const
    {
        return new MobileXinLirangCard;
    }
};

class MobileXinMingfa : public PhaseChangeSkill
{
public:
    MobileXinMingfa() : PhaseChangeSkill("mobilexinmingfa")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish || player->isNude()) return false;
        Room *room = player->getRoom();
        const Card *card = room->askForCard(player, "..", "@mobilexinmingfa-show", QVariant(), Card::MethodNone);
        if (!card) return false;
        player->tag["MobileXinMingfaCard"] = QVariant::fromValue(card);
        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);
        room->showCard(player, card->getEffectiveId());
        return false;
    }
};

class MobileXinMingfaPindian : public TriggerSkill
{
public:
    MobileXinMingfaPindian() : TriggerSkill("#mobilexinmingfa-pindian")
    {
        events << EventPhaseStart << PindianVerifying;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->isDead() || player->getPhase() != Player::Play) return false;
            const Card *card = player->tag["MobileXinMingfaCard"].value<const Card *>();
            player->tag.remove("MobileXinMingfaCard");
            if (!card || !player->hasCard(card->getEffectiveId())) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!player->canPindian(p)) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;
            room->fillAG(QList<int>() << card->getEffectiveId(), player);
            ServerPlayer *t = room->askForPlayerChosen(player, targets, "mobilexinmingfa", "@mobilexinmingfa-pindian", false, true);
            room->clearAG(player);
            room->broadcastSkillInvoke("mobilexinmingfa");

            PindianStruct *pindian = player->PinDian(t, "mobilexinmingfa", card);
            if (player->isDead()) return false;
            if (pindian->success) {
                if (t->isAlive() && !t->isNude()) {
                    int id = room->askForCardChosen(player, t, "he", "mobilexinmingfa");
                    room->obtainCard(player, id, false);
                }
                int number = Sanguosha->getEngineCard(pindian->from_card->getEffectiveId())->getNumber() - 1;
                QList<int> ids;
                foreach (int id, room->getDrawPile()) {
                    if (Sanguosha->getCard(id)->getNumber() == number)
                        ids << id;
                }
                if (ids.isEmpty()) return false;
                int id = ids.at(qrand() % ids.length());
                room->obtainCard(player, id);
            } else
                room->addPlayerMark(player, "mobilexinmingfa-Clear");
        } else {
            PindianStruct *pindian = data.value<PindianStruct *>();
            QList<ServerPlayer *> pindian_players;
            pindian_players << pindian->from << pindian->to;
            room->sortByActionOrder(pindian_players);

            foreach (ServerPlayer *p, pindian_players) {
                LogMessage log;
                log.type = "#MobileXinMingfaPindian";
                log.from = p;
                log.arg = "mobilexinmingfa";
                if (p->hasSkill("mobilexinmingfa") && p == pindian->from) {
                    pindian->from_number += 2;
                    pindian->from_number = qMin(pindian->from_number, 13);
                    log.arg2 = QString::number(pindian->from_number);
                    room->sendLog(log);
                    room->notifySkillInvoked(p, "mobilexinmingfa");
                    room->broadcastSkillInvoke("mobilexinmingfa");
                    data = QVariant::fromValue(pindian);
                } else if (p->hasSkill("mobilexinmingfa") && p == pindian->to) {
                    pindian->to_number += 2;
                    pindian->to_number = qMin(pindian->to_number, 13);
                    log.arg2 = QString::number(pindian->to_number);
                    room->sendLog(log);
                    room->notifySkillInvoked(p, "mobilexinmingfa");
                    room->broadcastSkillInvoke("mobilexinmingfa");
                    data = QVariant::fromValue(pindian);
                }
            }
        }
        return false;
    }
};

class MobileXinMingfaPro : public ProhibitSkill
{
public:
    MobileXinMingfaPro() : ProhibitSkill("#mobilexinmingfa-pro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from->getMark("mobilexinmingfa-Clear") > 0 && from != to && !card->isKindOf("SkillCard");
    }
};

MobileXinRongbeiCard::MobileXinRongbeiCard()
{
}

bool MobileXinRongbeiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getEquips().length() < S_EQUIP_AREA_LENGTH;
}

void MobileXinRongbeiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *to = effect.to;
    Room *room = to->getRoom();

    room->removePlayerMark(effect.from, "@mobilexinrongbeiMark");
    room->doSuperLightbox("mobilexin_yanghu", "mobilexinrongbei");

    QList<int> areas;

    for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
        if (to->getEquip(i)) continue;
        areas << i;
    }
    if (areas.isEmpty()) return;

    QList<const EquipCard *> equips;
    foreach (int id, room->getDrawPile()) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->isKindOf("EquipCard")) continue;
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        int equip_index = static_cast<int>(equip->location());
        if (to->getEquip(equip_index)) continue;
        equips << equip;
    }
    if (equips.isEmpty()) return;

    for (int i = 0; i < areas.length(); i++) {
        if (to->isDead()) return;
        int area = areas.at(i);

        QList<const Card *> equip_cards;
        foreach (const EquipCard *ec, equips) {
            int equip_index = static_cast<int>(ec->location());
            if (equip_index == area)
                equip_cards << ec;
        }
        if (equip_cards.isEmpty()) continue;
        const Card *equip = equip_cards.at(qrand() % equip_cards.length());
        room->obtainCard(to, equip);
        if (to->isAlive() && to->hasEquipArea(area) && !to->isLocked(equip, true) && !to->isProhibited(to, equip))
            room->useCard(CardUseStruct(equip, to, to));
    }
}

class MobileXinRongbei : public ZeroCardViewAsSkill
{
public:
    MobileXinRongbei() : ZeroCardViewAsSkill("mobilexinrongbei")
    {
        frequency = Limited;
        limit_mark = "@mobilexinrongbeiMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@mobilexinrongbeiMark") > 0;
    }

    const Card *viewAs() const
    {
        return new MobileXinRongbeiCard;
    }
};

class SecondMobileXinXingqi : public TriggerSkill
{
public:
    SecondMobileXinXingqi() : TriggerSkill("secondmobilexinxingqi")
    {
        events << CardUsed << CardResponded << EventPhaseStart;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QString bei = player->property("second_mobilexin_wangling_bei").toString();
        QStringList beis;
        if (!bei.isEmpty())
            beis = bei.split("+");

        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            if (beis.isEmpty()) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(this);
            QString choice = room->askForChoice(player, objectName(), bei);
            beis.removeOne(choice);
            room->setPlayerProperty(player, "second_mobilexin_wangling_bei", beis.isEmpty() ? QString() : beis.join("+"));

            LogMessage log;
            log.type = "#SecondMobileXinXingqiRemove";
            log.from = player;
            log.arg = choice;
            room->sendLog(log);

            QList<int> ids;
            foreach (int id, room->getDrawPile()) {
                const Card *card = Sanguosha->getCard(id);
                if (!card->sameNameWith(choice)) continue;
                ids << id;
            }
            if (ids.isEmpty()) return false;

            int id = ids.at(qrand() % ids.length());
            room->obtainCard(player, id);
        } else {
            const Card *card = NULL;
            if (event == CardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (!card || card->isKindOf("DelayedTrick") || card->isKindOf("SkillCard")) return false;

            QString name = card->objectName();
            if (card->isKindOf("Slash"))
                name = "slash";
            if (beis.contains(name)) return false;

            LogMessage log;
            log.type = "#SecondMobileXinXingqiLog";
            log.from = player;
            log.arg = objectName();
            log.arg2 = name;
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(this);

            beis << name;
            room->setPlayerProperty(player, "second_mobilexin_wangling_bei", beis.join("+"));
        }
        return false;
    }
};

class SecondMobileXinZifu : public TriggerSkill
{
public:
    SecondMobileXinZifu() : TriggerSkill("secondmobilexinzifu")
    {
        events << EventPhaseEnd;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (player->getMark("secondmobilexinzifu-PlayClear") > 0) return false;
        room->sendCompulsoryTriggerLog(player, this);
        room->addMaxCards(player, -1);
        room->setPlayerProperty(player, "second_mobilexin_wangling_bei", QString());
        return false;
    }
};

class SecondMobileXinZifuRecord : public TriggerSkill
{
public:
    SecondMobileXinZifuRecord() : TriggerSkill("#secondmobilexinzifu-record")
    {
        events << EventPhaseStart << PreCardUsed;
        global = true;
    }

    /*int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseEnd)
            return TriggerSkill::getPriority(triggerEvent) - 1;
        return TriggerSkill::getPriority(triggerEvent);
    }*/

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            if (player->getPhase() != Player::Play) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            room->setPlayerMark(player, "secondmobilexinzifu-PlayClear", 1);
        } else {
            if (player->getPhase() != Player::Start) return false;
            QString bei = player->property("second_mobilexin_wangling_bei").toString();
            if (!bei.isEmpty()) return false;
            room->setPlayerMark(player, "secondmobilexinmibei-Clear", 1);
        }
        return false;
    }
};

class SecondMobileXinMibei : public TriggerSkill
{
public:
    SecondMobileXinMibei() : TriggerSkill("secondmobilexinmibei")
    {
        events << EventPhaseEnd << CardFinished;
        shiming_skill = true;
        waked_skills = "secondmobilexinmouli";
        frequency = NotCompulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("secondmobilexinmibei") > 0) return false;
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Discard) return false;
            if (player->getMark("secondmobilexinmibei-Clear") <= 0) return false;
            QString bei = player->property("second_mobilexin_wangling_bei").toString();
            if (!bei.isEmpty()) return false;
            room->sendShimingLog(player, this, false, 2);
            room->loseMaxHp(player);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            QString bei = player->property("second_mobilexin_wangling_bei").toString();
            if (bei.isEmpty()) return false;
            QStringList beis = bei.split("+");
            if (beis.length() < 2 * (S_CARD_TYPE_LENGTH - 1)) return false;

            QHash<QString, int> hash;
            foreach (QString name, beis) {
                const Card *card = Sanguosha->findChild<const Card *>(name);
                if (!card) continue;
                int num = hash[card->getType()];
                num++;
                hash[card->getType()] = num;
            }

            int basic = hash["basic"], equip = hash["equip"], trick = hash["trick"];
            if (basic < 2 || equip < 2 || trick < 2) return false;

            room->sendShimingLog(player, this, true, 1);

            QList<int> basics, tricks, equips;
            foreach (int id, room->getDrawPile()) {
                const Card *card = Sanguosha->getCard(id);
                if (card->isKindOf("BasicCard"))
                    basics << id;
                else if (card->isKindOf("TrickCard"))
                    tricks << id;
                else if (card->isKindOf("EquipCard"))
                    equips << id;
            }

            DummyCard *dummy = new DummyCard();
            dummy->deleteLater();

            if (!basics.isEmpty()) {
                int id = basics.at(qrand() % basics.length());
                dummy->addSubcard(id);
            }
            if (!tricks.isEmpty()) {
                int id = tricks.at(qrand() % tricks.length());
                dummy->addSubcard(id);
            }
            if (!equips.isEmpty()) {
                int id = equips.at(qrand() % equips.length());
                dummy->addSubcard(id);
            }

            if (dummy->subcardsLength() > 0)
                room->obtainCard(player, dummy);

            room->acquireSkill(player, "secondmobilexinmouli");
        }
        return false;
    }
};

SecondMobileXinMouliCard::SecondMobileXinMouliCard()
{
}

void SecondMobileXinMouliCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    if (from->isDead()) return;
    QString bei = from->property("second_mobilexin_wangling_bei").toString();
    if (bei.isEmpty()) return;

    QStringList beis = bei.split("+");
    Room *room = from->getRoom();

    QString choice = room->askForChoice(to, "secondmobilexinmouli", bei);
    beis.removeOne(choice);
    room->setPlayerProperty(from, "second_mobilexin_wangling_bei", beis.isEmpty() ? QString() : beis.join("+"));

    LogMessage log;
    log.type = "#SecondMobileXinXingqiRemove";
    log.from = from;
    log.arg = choice;
    room->sendLog(log);

    QList<int> ids;
    foreach (int id, room->getDrawPile()) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->sameNameWith(choice)) continue;
        ids << id;
    }
    if (ids.isEmpty()) return;

    int id = ids.at(qrand() % ids.length());
    room->obtainCard(to, id);
}

class SecondMobileXinMouli : public ZeroCardViewAsSkill
{
public:
    SecondMobileXinMouli() : ZeroCardViewAsSkill("secondmobilexinmouli")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SecondMobileXinMouliCard") && !player->property("second_mobilexin_wangling_bei").toString().isEmpty();
    }

    const Card *viewAs() const
    {
        return new SecondMobileXinMouliCard;
    }
};

MobileXinPackage::MobileXinPackage()
    : Package("mobilexin")
{
    General *mobilexin_xinpi = new General(this, "mobilexin_xinpi", "wei", 3);
    mobilexin_xinpi->addSkill(new MobileXinYinju);
    mobilexin_xinpi->addSkill(new MobileXinChijie);

    General *mobilexin_mifuren = new General(this, "mobilexin_mifuren", "shu", 3, false);
    mobilexin_mifuren->addSkill(new MobileXinCunsi);
    mobilexin_mifuren->addSkill(new MobileXinGuixiu);

    General *second_mobilexin_mifuren = new General(this, "second_mobilexin_mifuren", "shu", 3, false);
    second_mobilexin_mifuren->addSkill(new SecondMobileXinGuixiu);
    second_mobilexin_mifuren->addSkill(new SecondMobileXinQingyu);
    second_mobilexin_mifuren->addRelateSkill("secondmobilexinxuancun");

    General *mobilexin_wujing = new General(this, "mobilexin_wujing", "wu", 4);
    mobilexin_wujing->addSkill(new MobileXinHeji);

    General *mobilexin_wangling = new General(this, "mobilexin_wangling", "wei", 4);
    mobilexin_wangling->addSkill(new MobileXinMouli);
    mobilexin_wangling->addSkill(new MobileXinZifu);

    General *second_mobilexin_wangling = new General(this, "second_mobilexin_wangling", "wei", 4);
    second_mobilexin_wangling->setImage("mobilexin_wangling");
    second_mobilexin_wangling->addSkill(new SecondMobileXinXingqi);
    second_mobilexin_wangling->addSkill(new SecondMobileXinZifu);
    second_mobilexin_wangling->addSkill(new SecondMobileXinZifuRecord);
    second_mobilexin_wangling->addSkill(new SecondMobileXinMibei);
    second_mobilexin_wangling->addRelateSkill("secondmobilexinmouli");
    related_skills.insertMulti("secondmobilexinzifu", "#secondmobilexinzifu-record");

    General *mobilexin_wangfuzhaolei = new General(this, "mobilexin_wangfuzhaolei", "shu", 4);
    mobilexin_wangfuzhaolei->addSkill(new MobileXinXunyi);
    mobilexin_wangfuzhaolei->addSkill(new MobileXinXunyiEffect);
    related_skills.insertMulti("mobilexinxunyi", "#mobilexinxunyi");

    General *mobilexin_zhouchu = new General(this, "mobilexin_zhouchu", "wu", 4);
    mobilexin_zhouchu->addSkill(new MobileXinXianghai);
    mobilexin_zhouchu->addSkill(new MobileXinXianghaiMax);
    mobilexin_zhouchu->addSkill(new MobileXinChuhai);
    related_skills.insertMulti("mobilexinxianghai", "#mobilexinxianghai");

    General *mobilexin_kongrong = new General(this, "mobilexin_kongrong", "qun", 3);
    mobilexin_kongrong->addSkill(new MobileXinMingshi);
    mobilexin_kongrong->addSkill(new MobileXinLirang);

    General *mobilexin_yanghu = new General(this, "mobilexin_yanghu", "qun", 3);
    mobilexin_yanghu->addSkill(new MobileXinMingfa);
    mobilexin_yanghu->addSkill(new MobileXinMingfaPindian);
    mobilexin_yanghu->addSkill(new MobileXinMingfaPro);
    mobilexin_yanghu->addSkill(new MobileXinRongbei);
    related_skills.insertMulti("mobilexinmingfa", "#mobilexinmingfa-pindian");
    related_skills.insertMulti("mobilexinmingfa", "#mobilexinmingfa-pro");

    addMetaObject<MobileXinYinjuCard>();
    addMetaObject<MobileXinCunsiCard>();
    addMetaObject<MobileXinMouliCard>();
    addMetaObject<MobileXinChuhaiCard>();
    addMetaObject<MobileXinLirangCard>();
    addMetaObject<MobileXinRongbeiCard>();
    addMetaObject<SecondMobileXinMouliCard>();

    skills << new SecondMobileXinXuancun << new MobileXinMouliEffect << new SecondMobileXinMouli;
}

ADD_PACKAGE(MobileXin)
