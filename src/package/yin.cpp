#include "yin.h"
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

class Juzhan : public TriggerSkill
{
public:
    Juzhan() : TriggerSkill("juzhan")
    {
        events << TargetSpecified << TargetConfirmed;
        change_skill = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        int n = room->getChangeSkillState(player, objectName());
        if (event == TargetConfirmed && n <= 1) {
            if (use.from == player || !use.to.contains(player)) return false;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(use.from))) return false;
            room->broadcastSkillInvoke(objectName());
            QList<ServerPlayer *> sp;
            sp << use.from << player;
            room->sortByActionOrder(sp);
            room->drawCards(sp, 1, objectName());
            if (!room->getCurrent() || room->getCurrent()->getPhase() == Player::NotActive) return false;
            room->addPlayerMark(use.from, "juzhan_from-Clear");
            room->addPlayerMark(player, "juzhan_to-Clear");
            room->setChangeSkillState(player, objectName(), 2);
        } else if (event == TargetSpecified && n == 2) {
            foreach (ServerPlayer *p, use.to) {
                if (player->isDead()) return false;
                if (p->isNude() || !player->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
                room->broadcastSkillInvoke(objectName());
                int card_id = room->askForCardChosen(player, p, "he", objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
                if (room->getCurrent() && room->getCurrent()->getPhase() != Player::NotActive) {
                    room->addPlayerMark(player, "juzhan_from-Clear");
                    room->addPlayerMark(p, "juzhan_to-Clear");
                }
                room->setChangeSkillState(player, objectName(), 1);
                break;
            }
        }
        return false;
    }
};

class JuzhanPro : public ProhibitSkill
{
public:
    JuzhanPro() : ProhibitSkill("#juzhanpro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from->getMark("juzhan_from-Clear") > 0 && to->getMark("juzhan_to-Clear") > 0 && !card->isKindOf("SkillCard");
    }
};

FeijunCard::FeijunCard()
{
    target_fixed = true;
}

void FeijunCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isDead()) return;
    int handcardnum = source->getHandcardNum();
    int equipnum = source->getEquips().length();
    QList<ServerPlayer *> handp;
    QList<ServerPlayer *> equipp;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->getHandcardNum() > handcardnum)
            handp << p;
        if (p->getEquips().length() > equipnum)
            equipp << p;
    }
    QStringList choices;
    if (!handp.isEmpty()) choices << "givehand";
    if (!equipp.isEmpty()) choices << "discardequip";
    if (choices.isEmpty()) return;
    QString choice = room->askForChoice(source, "feijun", choices.join("+"), QVariant());
    if (choice == "givehand") {
        ServerPlayer *target = room->askForPlayerChosen(source, handp, "feijun", "feijun-choosehand");
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, source->objectName(), target->objectName());
        room->addPlayerMark(target, "feijun_hasused");
        if (target->isKongcheng()) return;
        const Card *card = room->askForExchange(target, "feijun", 1, 1, true, "feijun-givehand:" + source->objectName());
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "feijun", QString());
        room->obtainCard(source, card, reason, false);
    } else {
        ServerPlayer *target = room->askForPlayerChosen(source, equipp, "feijun", "feijun-chooseequip");
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, source->objectName(), target->objectName());
        room->addPlayerMark(target, "feijun_hasused");
        if (!target->canDiscard(target, "e")) return;
        room->askForDiscard(target, "feijun", 1, 1, false, true, "feijun-discardequip", ".|.|.|equip");
    }
}

class Feijun : public OneCardViewAsSkill
{
public:
    Feijun() : OneCardViewAsSkill("feijun")
    {
        filter_pattern = ".";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        FeijunCard *card = new FeijunCard;
        card->addSubcard(originalCard);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("FeijunCard");
    }
};

class Binglve : public TriggerSkill
{
public:
    Binglve() : TriggerSkill("binglve")
    {
        events << ChoiceMade;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QStringList data_str = data.toString().split(":");
        if (data_str.first() == "playerChosen" && data_str.at(1) == "feijun" && data_str.last() != NULL) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->objectName() == data_str.last() && p->getMark("feijun_hasused") <= 0) {
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    player->drawCards(2, objectName());
                    break;
                }
            }
        }
        return false;
    }
};

class Huaiju : public TriggerSkill
{
public:
    Huaiju() : TriggerSkill("huaiju")
    {
        events << GameStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->gainMark("&orange", 3);
        return false;
    }
};

class HuaijuEffect : public TriggerSkill
{
public:
    HuaijuEffect() : TriggerSkill("#huaijueffect")
    {
        events << DamageInflicted << DrawNCards;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("&orange") <= 0) return false;
        QList<ServerPlayer *> lujis = room->findPlayersBySkillName(objectName());
        if (lujis.isEmpty()) return false;
        if (triggerEvent == DamageInflicted) {
            DamageStruct damage = data.value<DamageStruct>();
            foreach (ServerPlayer *p, lujis) {
                room->notifySkillInvoked(p, "huaiju");
                room->broadcastSkillInvoke("huaiju");
            }
            player->loseMark("&orange");
            LogMessage log;
            log.type = "#HuaijuPrevent";
            log.from = player;
            log.arg = "huaiju";
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);
            return true;
        } else {
            foreach (ServerPlayer *p, lujis) {
                room->notifySkillInvoked(p, "huaiju");
                room->broadcastSkillInvoke("huaiju");
            }
            LogMessage log;
            log.type = "#HuaijuDraw";
            log.from = player;
            log.arg = "huaiju";
            log.arg2 = QString::number(lujis.length());
            room->sendLog(log);
            data.setValue(data.toInt() + lujis.length());
        }
        return false;
    }
};

class HuaijuDeath : public TriggerSkill
{
public:
    HuaijuDeath() : TriggerSkill("#huaijudeath")
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
        QList<ServerPlayer *> players;
        if (player->getMark("&orange") > 0) players << player;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark("&orange") > 0)
                players << p;
        }
        if (players.isEmpty()) return false;
        room->sendCompulsoryTriggerLog(player, "huaiju", true, true);
        room->sortByActionOrder(players);
        foreach (ServerPlayer *p, players) {
            if (p->getMark("&orange") > 0)
                p->loseAllMarks("&orange");
        }
        return false;
    }
};

class Weili : public PhaseChangeSkill
{
public:
    Weili() : PhaseChangeSkill("weili")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), "weili", "weili-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        QStringList choices;
        choices << "losehp";
        if (player->getMark("&orange") > 0) choices << "losemark";
        QString choice = room->askForChoice(player, "weili", choices.join("+"), QVariant());
        if (choice == "losehp")
            room->loseHp(player);
        else
            player->loseMark("&orange");
        target->gainMark("&orange");
        return false;
    }
};

class Zhenglun : public TriggerSkill
{
public:
    Zhenglun() : TriggerSkill("zhenglun")
    {
        events << EventPhaseChanging;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::Draw) return false;
        if (player->isSkipped(Player::Draw)) return false;
        if (player->getMark("&orange") > 0) return false;
        if (!player->askForSkillInvoke(objectName(), data)) return false;
        room->broadcastSkillInvoke(objectName());
        player->skip(Player::Draw);
        player->gainMark("&orange");
        return false;
    }
};

KuizhuCard::KuizhuCard()
{
    mute = true;
}

bool KuizhuCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    int n = 0;
    for (int i = 0; i < targets.length(); i++) {
        n = n + targets.at(i)->getHp();
    }
    return (targets.length() > 0 && targets.length() <= Self->getMark("kuizhu-Clear")) || (n == Self->getMark("kuizhu-Clear"));
}

bool KuizhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int n = Self->getMark("kuizhu-Clear");
    for (int i = 0; i < targets.length(); i++) {
        n = n - targets.at(i)->getHp();
    }
    return (targets.length() < Self->getMark("kuizhu-Clear")) || to_select->getHp() <= n;
}

void KuizhuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->broadcastSkillInvoke("kuizhu");
    int n = 0;
    foreach (ServerPlayer *p, targets) {
        n = n + p->getHp();
    }
    QStringList choices;
    if (targets.length() <= source->getMark("kuizhu-Clear")) choices << "draw";
    if (n == source->getMark("kuizhu-Clear")) choices << "damage";
    QString choice = room->askForChoice(source, "kuizhu", choices.join("+"), QVariant());
    if (choice == "draw")
        room->setPlayerFlag(source,"kuizhu_draw");
    else
        room->setPlayerFlag(source,"kuizhu_damage");
    try {
        foreach (ServerPlayer *p, targets) {
            if (p->isAlive()) {
                room->cardEffect(this, source, p);
            }
        }
        if (source->hasFlag("kuizhu_draw"))
            room->setPlayerFlag(source,"-kuizhu_draw");
        if (source->hasFlag("kuizhu_damage")) {
            room->setPlayerFlag(source,"-kuizhu_damage");
            if (targets.length() >= 2 && source->isAlive())
                room->damage(DamageStruct("kuizhu", NULL, source));
        }
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
            if (source->hasFlag("kuizhu_draw"))
                room->setPlayerFlag(source,"-kuizhu_draw");
            if (source->hasFlag("kuizhu_damage"))
                room->setPlayerFlag(source,"-kuizhu_damage");
        }
        throw triggerEvent;
    }
}

void KuizhuCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->hasFlag("kuizhu_draw"))
        effect.to->drawCards(1, "kuizhu");
    if (effect.from->hasFlag("kuizhu_damage"))
        effect.from->getRoom()->damage(DamageStruct("kuizhu", effect.from, effect.to));
}

class KuizhuViewAsSkill : public ZeroCardViewAsSkill
{
public:
    KuizhuViewAsSkill() : ZeroCardViewAsSkill("kuizhu")
    {
        response_pattern = "@@kuizhu";
    }

    const Card *viewAs() const
    {
        return new KuizhuCard;
    }
};

class Kuizhu : public TriggerSkill
{
public:
    Kuizhu() : TriggerSkill("kuizhu")
    {
        events << CardsMoveOneTime << EventPhaseEnd;
        view_as_skill = new KuizhuViewAsSkill;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Discard) return false;
        if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)
                room->addPlayerMark(player, "kuizhu-Clear", move.card_ids.length());
        } else {
            int num = player->getMark("kuizhu-Clear");
            if (num <= 0) return false;
            room->askForUseCard(player, "@@kuizhu", "@kuizhu", -1, Card::MethodNone);
            room->setPlayerMark(player, "kuizhu-Clear", 0);
        }
        return false;
    }
};

class Chezheng : public TriggerSkill
{
public:
    Chezheng() : TriggerSkill("chezheng")
    {
        events << EventPhaseEnd << CardFinished;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (triggerEvent == EventPhaseEnd){
            int count = player->getMark("chezheng-Clear");
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!p->inMyAttackRange(player))
                    targets << p;
            }
            if (count >= targets.length()) return false;
            QList<ServerPlayer *> targetss;
            foreach (ServerPlayer *p, targets) {
                if (player->canDiscard(p, "he"))
                    targetss << p;
            }
            if (targetss.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            ServerPlayer *target = room->askForPlayerChosen(player, targetss, "chezheng", "chezheng-discard");
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, target, player);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "chezheng-Clear");
        }

        return false;
    }
};

class ChezhengPro : public ProhibitSkill
{
public:
    ChezhengPro() : ProhibitSkill("#chezhengpro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from->hasSkill("chezheng") && from->getPhase() == Player::Play && !to->inMyAttackRange(from) && from != to && !card->isKindOf("SkillCard");
    }
};

class Lijun : public TriggerSkill
{
public:
    Lijun() : TriggerSkill("lijun$")
    {
        events << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getKingdom() == "wu" && target->getPhase() == Player::Play;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card && use.card->isKindOf("Slash") && room->getCardPlace(use.card->getEffectiveId()) == Player::DiscardPile) {
            QList<ServerPlayer *> sunliangs;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->hasLordSkill(objectName()) && p->getMark("lijun-Clear") <= 0)
                    sunliangs << p;
            }
            if (sunliangs.isEmpty()) return false;
            ServerPlayer *sunliang = room->askForPlayerChosen(player, sunliangs, "lijun", "lijun-give", true);
            if (!sunliang) return false;
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << sunliang;
            log.arg = "lijun";
            room->sendLog(log);
            if (!sunliang->isWeidi()) {
                room->notifySkillInvoked(sunliang, objectName());
                room->broadcastSkillInvoke(objectName());
            } else {
                room->notifySkillInvoked(sunliang, "weidi");
                room->broadcastSkillInvoke("weidi");
            }
            room->addPlayerMark(sunliang, "lijun-Clear");
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), sunliang->objectName(), "lijun", QString());
            room->obtainCard(sunliang, use.card, reason, true);
            QVariant new_data = QVariant::fromValue(player);
            if (!sunliang->askForSkillInvoke(objectName(), new_data)) return false;
            if (!sunliang->isWeidi())
                room->broadcastSkillInvoke(objectName());
            else
                room->broadcastSkillInvoke("weidi");
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class Qizhi : public TriggerSkill
{
public:
    Qizhi() : TriggerSkill("qizhi")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("BasicCard") || use.card->isKindOf("TrickCard")) {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (use.to.contains(p) || !player->canDiscard(p, "he")) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, "qizhi", "qizhi-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "&qizhi-Clear");
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, target, player);
            target->drawCards(1, objectName());
        }
        return false;
    }
};

class Jinqu : public PhaseChangeSkill
{
public:
    Jinqu() : PhaseChangeSkill("jinqu")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (!player->askForSkillInvoke(objectName())) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        player->drawCards(2, objectName());
        int n = player->getHandcardNum() - player->getMark("&qizhi-Clear");
        if (n > 0)
            room->askForDiscard(player, objectName(), n, n);
        return false;
    }
};

class Jianxiang : public TriggerSkill
{
public:
    Jianxiang() : TriggerSkill("jianxiang")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player) || use.card->isKindOf("SkillCard") || use.from == player) return false;
        int n = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHandcardNum() < n)
                n = p->getHandcardNum();
        }

        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHandcardNum() == n)
                targets << p;
        }

        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "jianxiang-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        target->drawCards(1, objectName());
        return false;
    }
};

ShenshiCard::ShenshiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool ShenshiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const QList<const Player *> as = Self->getAliveSiblings();
    int n = as.first()->getHandcardNum();
    foreach (const Player *p, as) {
        if (p->getHandcardNum() > n)
            n = p->getHandcardNum();
    }
    return targets.isEmpty() && to_select != Self && to_select->getHandcardNum() == n;
}

void ShenshiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->setChangeSkillState(effect.from, "shenshi", 2);
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "shenshi", QString());
    room->obtainCard(effect.to, this, reason, false);
    room->damage(DamageStruct("shenshi", effect.from, effect.to));
}

class ShenshiVS : public OneCardViewAsSkill
{
public:
    ShenshiVS() : OneCardViewAsSkill("shenshi")
    {
        filter_pattern = ".";
        change_skill = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ShenshiCard") && player->getChangeSkillState("shenshi") <= 1;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ShenshiCard *card = new ShenshiCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Shenshi : public TriggerSkill
{
public:
    Shenshi() : TriggerSkill("shenshi")
    {
        events << Death << Damaged;
        view_as_skill = new ShenshiVS;
        change_skill = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.damage && death.damage->from && death.damage->getReason() == "shenshi") {
                ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "shenshi-invoke", true, true);
                if (!target) return false;
                room->broadcastSkillInvoke(objectName());
                if (target->getHandcardNum() < 4)
                    target->drawCards(4 - target->getHandcardNum(), objectName());
            }
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from != player && !damage.from->isKongcheng() && player->getChangeSkillState(objectName()) == 2) {
                if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.from))) return false;
                room->setChangeSkillState(player, "shenshi", 1);
                room->doGongxin(player, damage.from, QList<int>(), objectName());
                if (player->isKongcheng()) return false;
                const Card *card = room->askForExchange(player, objectName(), 1, 1, true, "shenshi-give:" + damage.from->objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), damage.from->objectName(), "shenshi", QString());
                room->obtainCard(damage.from, card, reason, false);
                int id = card->getSubcards().first();
                QVariantList ids = damage.from->tag["shenshi_" + player->objectName()].toList();
                if (!ids.contains(QVariant(id)))
                    ids << id;
                damage.from->tag["shenshi_" + player->objectName()] = ids;
            }
        }
        return false;
    }
};

class ShenshiEffect : public TriggerSkill
{
public:
    ShenshiEffect() : TriggerSkill("#shenshi-effect")
    {
        events << EventPhaseChanging << Death << EventLoseSkill;
        view_as_skill = new ShenshiVS;
        change_skill = true;
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
            QList<ServerPlayer *> draws;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                foreach (ServerPlayer *pp, room->getOtherPlayers(p)) {
                    QVariantList ids = p->tag["shenshi_" + pp->objectName()].toList();
                    if (!ids.isEmpty()) {
                        p->tag.remove("shenshi_" + pp->objectName());
                        bool has = false;
                        QList<int> idds = VariantList2IntList(ids);
                        foreach (int id, idds) {
                            if (p->handCards().contains(id) || p->getEquips().contains(Sanguosha->getCard(id))) {
                                has = true;
                                break;
                            }
                        }

                        if (has && pp->hasSkill("shenshi"))
                            draws << pp;
                    }
                }
            }
            if (draws.isEmpty()) return false;
            room->sortByActionOrder(draws);
            foreach (ServerPlayer *p, draws) {
                if (p->getHandcardNum() < 4) {
                    room->sendCompulsoryTriggerLog(p, "shenshi", true, true);
                    p->drawCards(4 - p->getHandcardNum());
                }
            }
        } else {
            if (event == Death) {
                DeathStruct death = data.value<DeathStruct>();
                if (death.who != player) return false;
            } else if (event == EventLoseSkill) {
                if (data.toString() != "shenshi") return false;
            }
            foreach (ServerPlayer *p, room->getOtherPlayers(player, true)) {
                p->tag.remove("shenshi_" + player->objectName());
            }
        }
        return false;
    }
};

ChenglveCard::ChenglveCard()
{
    target_fixed = true;
}

void ChenglveCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int n = source->getChangeSkillState("chenglve");
    int dis_num = 0;
    if (n <= 1) {
        room->setChangeSkillState(source, "chenglve", 2);
        dis_num = 2;
        source->drawCards(1, "chenglve");
    } else if (n == 2) {
        room->setChangeSkillState(source, "chenglve", 1);
        dis_num = 1;
        source->drawCards(2, "chenglve");
    }
    if (dis_num == 0) return;
    const Card *card = room->askFordiscard(source, "chenglve", dis_num, dis_num, false);
    if (!card) return;
    QString mark = "&chenglve";
    foreach (int id, card->getSubcards()) {
        const Card *c = Sanguosha->getCard(id);
        room->addPlayerMark(source, "chenglve_" + c->getSuitString() + "-Clear");
        QString m = c->getSuitString() + "_char";
        if (mark.contains(m)) continue;
        mark = mark + "+" + m;
    }
    mark = mark + "-Clear";
    room->addPlayerMark(source, mark);
}

class Chenglve : public ZeroCardViewAsSkill
{
public:
    Chenglve() : ZeroCardViewAsSkill("chenglve")
    {
        change_skill = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ChenglveCard");
    }

    const Card *viewAs() const
    {
        return new ChenglveCard;
    }
};

class ChenglveTargetMod : public TargetModSkill
{
public:
    ChenglveTargetMod() : TargetModSkill("#chenglve-target")
    {
        pattern = ".";
        change_skill = true;
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (!card->isKindOf("SkillCard") && from->getMark("chenglve_" + card->getSuitString() + "-Clear") > 0)
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (!card->isKindOf("SkillCard") && from->getMark("chenglve_" + card->getSuitString() + "-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

class YinShicai : public TriggerSkill
{
public:
    YinShicai() : TriggerSkill("yinshicai")
    {
        events << CardFinished;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        QString n = QString::number(use.card->getTypeId());
        if (!room->getCurrent() || room->getCurrent()->getPhase() == Player::NotActive) return false;
        if (player->getMark("yinshicai" + n + "-Clear") > 0) return false;
        room->addPlayerMark(player, "yinshicai" + n + "-Clear");
        if (use.card->isKindOf("DelayedTrick")) return false;
        if (use.card->isVirtualCard() && use.card->subcardsLength() == 0) return false;

        bool invoke = false;
        QList<int> ids;
        if (use.card->isKindOf("EquipCard")) {
            if (room->getCardOwner(use.card->getEffectiveId()) == player && room->getCardPlace(use.card->getEffectiveId()) == Player::PlaceEquip) {
                ids << use.card->getEffectiveId();
                invoke = true;
            }
        } else {
            if (use.card->isVirtualCard())
                ids = use.card->getSubcards();
            else
                ids << use.card->getEffectiveId();
            foreach (int id, ids) {
                if (room->getCardPlace(id) != Player::DiscardPile)
                    return false;
            }
            invoke = true;
        }
        if (!invoke) return false;

        if (!player->askForSkillInvoke(this, QString("yinshicai_invoke:%1").arg(use.card->objectName()))) return false;
        room->broadcastSkillInvoke(objectName());
        if (room->getCardOwner(ids.first()) == NULL) {
            LogMessage log;
            log.type = "$YinshicaiPut";
            log.from = player;
            log.card_str = IntList2StringList(ids).join("+");
            room->sendLog(log);
        }
        CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), "yinshicai", QString());
        room->moveCardTo(use.card, NULL, Player::DrawPile, reason, true);
        player->drawCards(1, objectName());
        return false;
    }
};

class Mingren : public TriggerSkill
{
public:
    Mingren() : TriggerSkill("mingren")
    {
        events << GameStart << EventPhaseStart;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == GameStart) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->drawCards(1, objectName());
            if (player->isKongcheng()) return false;
            const Card *card = room->askForExchange(player, objectName(), 1, 1, false, "mingren-put");
            player->addToPile("mrren", card);
        } else {
            if (player->getPhase() != Player::Finish || player->isKongcheng() || player->getPile("mrren").isEmpty()) return false;
            const Card *card = room->askForExchange(player, objectName(), 1, 1, false, "mingren-change", true);
            if (!card) return false;
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());

            QList<int> ids = player->getPile("mrren");
            player->addToPile("mrren", card);

            DummyCard to_handcard_x(ids);
            CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, player->objectName());
            room->obtainCard(player, &to_handcard_x, reason, false);
        }
        return false;
    }
};

ZhenliangCard::ZhenliangCard()
{
}

bool ZhenliangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int n = qAbs(to_select->getHp() - Self->getHp());
    n = qMax(1, n);
    return targets.isEmpty() && n == getSubcards().length() && Self->inMyAttackRange(to_select) && to_select != Self;
}

void ZhenliangCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->setChangeSkillState(effect.from, "zhenliang", 2);
    room->damage(DamageStruct("zhenliang", effect.from, effect.to));
}

class ZhenliangVS : public ViewAsSkill
{
public:
    ZhenliangVS() : ViewAsSkill("zhenliang")
    {
        change_skill = true;
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        const Card *card = Sanguosha->getCard(Self->getPile("mrren").first());
        return !Self->isJilei(to_select) && to_select->sameColorWith(card);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        ZhenliangCard *card = new ZhenliangCard;
        card->addSubcards(cards);
        card->setSkillName(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("ZhenliangCard") && player->getChangeSkillState("zhenliang") <= 1
                && !player->getPile("mrren").isEmpty();
    }
};

class Zhenliang : public TriggerSkill
{
public:
    Zhenliang() : TriggerSkill("zhenliang")
    {
        events << BeforeCardsMove;
        view_as_skill = new ZhenliangVS;
        change_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getChangeSkillState("zhenliang") != 2) return false;
        if (player->getPile("mrren").isEmpty()) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DiscardPile) return false;
        if ((move.from_places.contains(Player::PlaceTable) && (move.reason.m_reason == CardMoveReason::S_REASON_USE ||
             move.reason.m_reason == CardMoveReason::S_REASON_LETUSE)) || move.reason.m_reason == CardMoveReason::S_REASON_RESPONSE) {
            const Card *card = move.reason.m_extraData.value<const Card *>();
            if (!card) return false;
            const Card *ren = Sanguosha->getCard(player->getPile("mrren").first());
            if (card->getTypeId() != ren->getTypeId()) return false;
            ServerPlayer *from = room->findPlayerByObjectName(move.reason.m_playerId);
            if (!from || player != from || player->getPhase() != Player::NotActive) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "zhenliang-draw", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->setChangeSkillState(player, "zhenliang", 1);
            target->drawCards(1, objectName());
        }

        return false;
    }
};

YinPackage::YinPackage()
    : Package("Yin")
{
    General *yanyan = new General(this, "yanyan", "shu", 4);
    yanyan->addSkill(new Juzhan);
    yanyan->addSkill(new JuzhanPro);
    related_skills.insertMulti("juzhan", "#juzhanpro");

    General *wangping = new General(this, "wangping", "shu", 4);
    wangping->addSkill(new Feijun);
    wangping->addSkill(new Binglve);

    General *luji = new General(this, "luji", "wu", 3);
    luji->addSkill(new Huaiju);
    luji->addSkill(new HuaijuEffect);
    luji->addSkill(new HuaijuDeath);
    luji->addSkill(new Weili);
    luji->addSkill(new Zhenglun);
    related_skills.insertMulti("huaiju", "#huaijueffect");
    related_skills.insertMulti("huaiju", "#huaijudeath");

    General *sunliang = new General(this, "sunliang$", "wu", 3);
    sunliang->addSkill(new Kuizhu);
    sunliang->addSkill(new Chezheng);
    sunliang->addSkill(new ChezhengPro);
    sunliang->addSkill(new Lijun);
    related_skills.insertMulti("chezheng", "#chezhengpro");

    General *wangji = new General(this, "wangji", "wei", 3);
    wangji->addSkill(new Qizhi);
    wangji->addSkill(new Jinqu);

    General *kuailiangkuaiyue = new General(this, "kuailiangkuaiyue", "wei", 3);
    kuailiangkuaiyue->addSkill(new Jianxiang);
    kuailiangkuaiyue->addSkill(new Shenshi);
    kuailiangkuaiyue->addSkill(new ShenshiEffect);
    related_skills.insertMulti("shenshi", "#shenshi-effect");

    General *yin_xuyou = new General(this, "yin_xuyou", "qun", 3);
    yin_xuyou->addSkill(new Chenglve);
    yin_xuyou->addSkill(new ChenglveTargetMod);
    yin_xuyou->addSkill(new YinShicai);
    yin_xuyou->addSkill(new Skill("cunmu", Skill::Compulsory)); //耦合进了Room::drawCards
    related_skills.insertMulti("chenglve", "#chenglve-target");

    General *luzhi = new General(this, "luzhi", "qun", 3);
    luzhi->addSkill(new Mingren);
    luzhi->addSkill(new Zhenliang);

    addMetaObject<FeijunCard>();
    addMetaObject<KuizhuCard>();
    addMetaObject<ShenshiCard>();
    addMetaObject<ChenglveCard>();
    addMetaObject<ZhenliangCard>();
}

ADD_PACKAGE(Yin)
