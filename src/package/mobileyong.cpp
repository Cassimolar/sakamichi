#include "mobileyong.h"
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

class MobileYongXiangzhen : public TriggerSkill
{
public:
    MobileYongXiangzhen() : TriggerSkill("mobileyongxiangzhen")
    {
        events << CardFinished;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *) const
    {
        return true;
    }

    QList<ServerPlayer *> getDamageFroms(Room *room, const Card *card) const
    {
        QList<ServerPlayer *> froms;
        foreach (QString flag, card->getFlags()) {
            if (!flag.startsWith("MobileYongXiangzhen_SavageAssault_DamageFrom_")) continue;
            QString name = flag.split("_").last();
            ServerPlayer *from = room->findChild<ServerPlayer *>(name);
            if (!from || from->isDead() || froms.contains(from)) continue;
            froms << from;
        }
        return froms;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("SavageAssault")) return false;
        QList<ServerPlayer *> froms = getDamageFroms(room, use.card);
        if (froms.isEmpty()) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            room->sendCompulsoryTriggerLog(p, this);
            QList<ServerPlayer *> drawers = froms;
            drawers << p;
            room->sortByActionOrder(drawers);
            room->drawCards(drawers, 1, objectName());
        }
        return false;
    }
};

class MobileYongXiangzhenRecord : public TriggerSkill
{
public:
    MobileYongXiangzhenRecord() : TriggerSkill("#mobileyongxiangzhen-record")
    {
        events << DamageDone;
        frequency = Compulsory;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("SavageAssault")) return false;
        if (!damage.from) return false;
        room->setCardFlag(damage.card, "MobileYongXiangzhen_SavageAssault_DamageFrom_" + damage.from->objectName());
        return false;
    }
};

class MobileYongXiangzhenNullify : public TriggerSkill
{
public:
    MobileYongXiangzhenNullify() : TriggerSkill("#mobileyongxiangzhen")
    {
        events << CardEffected;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!player->hasSkill("mobileyongxiangzhen")) return false;
        CardEffectStruct effect = data.value<CardEffectStruct>();
        if (effect.card->isKindOf("SavageAssault")) {
            room->broadcastSkillInvoke("mobileyongxiangzhen");
            room->notifySkillInvoked(player, "mobileyongxiangzhen");
            LogMessage log;
            log.type = "#SkillNullify";
            log.from = player;
            log.arg = "mobileyongxiangzhen";
            log.arg2 = "savage_assault";
            room->sendLog(log);
            return true;
        }
        return false;
    }
};

class MobileYongFangzong : public ProhibitSkill
{
public:
    MobileYongFangzong() : ProhibitSkill("mobileyongfangzong")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (from->getMark("mobileyongxizhan-Clear") > 0 || to->getMark("mobileyongxizhan-Clear") > 0) return false;
        if (!card->isDamageCard() || card->isKindOf("DelayedTrick")) return false;
        return (from->hasSkill(this) && from->inMyAttackRange(to) && from->getPhase() == Player::Play) ||
                (to->hasSkill(this) && from->inMyAttackRange(to));
    }
};

class MobileYongFangzongDraw : public PhaseChangeSkill
{
public:
    MobileYongFangzongDraw() : PhaseChangeSkill("#mobileyongfangzong")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish || !player->hasSkill("mobileyongfangzong") || player->getMark("mobileyongxizhan-Clear") > 0) return false;
        Room *room = player->getRoom();
        int alive = room->alivePlayerCount(), hand = player->getHandcardNum();
        if (alive <= hand) return false;
        room->sendCompulsoryTriggerLog(player, "mobileyongfangzong", true, true);
        player->drawCards(alive - hand, "mobileyongfangzong");
        return false;
    }
};

class MobileYongXizhan : public PhaseChangeSkill
{
public:
    MobileYongXizhan() : PhaseChangeSkill("mobileyongxizhan")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::RoundStart;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            room->sendCompulsoryTriggerLog(p, this);

            if (!p->canDiscard(p, "he")) {
                room->loseHp(p);
                continue;
            }

            const Card *card = room->askForDiscard(p, objectName(), 1, 1, true, true, "@mobileyongxizhan-discard");
            if (!card) {
                room->loseHp(p);
                continue;
            }

            room->addPlayerMark(p, "mobileyongxizhan-Clear");

            if (player->isDead()) continue;

            Card::Suit suit = Sanguosha->getCard(card->getSubcards().first())->getSuit();
            if (suit == Card::Spade) {
                Analeptic *ana = new Analeptic(Card::NoSuit, 0);
                ana->setSkillName("_mobileyongxizhan");
                ana->deleteLater();
                if (player->canUse(ana, player, true))
                    room->useCard(CardUseStruct(ana, player, player), true);
            } else if (suit == Card::Club) {
                IronChain *ic = new IronChain(Card::NoSuit, 0);
                ic->setSkillName("_mobileyongxizhan");
                ic->deleteLater();
                if (p->canUse(ic, player, true))
                    room->useCard(CardUseStruct(ic, p, player), true);
            } else if (suit == Card::Heart) {
                ExNihilo *ex = new ExNihilo(Card::NoSuit, 0);
                ex->setSkillName("_mobileyongxizhan");
                ex->deleteLater();
                if (p->canUse(ex, p, true))
                    room->useCard(CardUseStruct(ex, p, p), true);
            } else if (suit == Card::Diamond) {
                FireSlash *fire_slash = new FireSlash(Card::NoSuit, 0);
                fire_slash->setSkillName("_mobileyongxizhan");
                fire_slash->deleteLater();
                if (p->canSlash(player, fire_slash, false))
                    room->useCard(CardUseStruct(fire_slash, p, player), true);
            }
        }
        return false;
    }
};

class MobileYongZaoli : public TriggerSkill
{
public:
    MobileYongZaoli() : TriggerSkill("mobileyongzaoli")
    {
        events << CardUsed << CardResponded << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart || player->getMark("&myzlli") <= 0) return false;
            room->sendCompulsoryTriggerLog(player, this);
            int mark = player->getMark("&myzlli");
            player->loseAllMarks("&myzlli");
            int num = 0;
            if (player->isAlive() && player->canDiscard(player, "he"))
                num = room->askForDiscard(player, objectName(), 99999, 1, false, true, "@mobileyongzaoli-discard")->subcardsLength();
            player->drawCards(mark + num, objectName());
            room->loseHp(player);
        } else {
            if (player->getMark("&myzlli") >= 4) return false;
            if (event == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                if (use.card->isKindOf("SkillCard") || !use.m_isHandcard) return false;
            } else if (event == CardResponded) {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (res.m_card->isKindOf("SkillCard") || !res.m_isHandcard) return false;
            }
            room->sendCompulsoryTriggerLog(player, this);
            player->gainMark("&myzlli");
        }
        return false;
    }
};

class MobileYongZaoliLimit : public CardLimitSkill
{
public:
    MobileYongZaoliLimit() : CardLimitSkill("#mobileyongzaoli-limit")
    {
    }

    QString limitList(const Player *target) const
    {
        if (target->getPhase() == Player::Play && target->hasSkill("mobileyongzaoli"))
            return "use,response";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->getPhase() == Player::Play && target->hasSkill("mobileyongzaoli")) {
            QStringList fulin_list = target->property("fulin_list").toString().split("+");
            QStringList patterns;
            foreach (const Card *card, target->getHandcards()) {
                QString str = card->toString();
                if (!fulin_list.contains(str))
                    patterns << str;
            }
            return patterns.join(",");
        } else
            return QString();
    }
};

MobileYongJungongCard::MobileYongJungongCard()
{
    target_fixed = true;
}

void MobileYongJungongCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->addPlayerMark(source, "&mobileyongjungong-Clear");
    int mark = source->getMark("&mobileyongjungong-Clear");
    if (subcardsLength() == 0)
        room->loseHp(source, mark);
    if (source->isDead()) return;

    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("_mobileyongjungong");
    slash->deleteLater();
    if (source->isLocked(slash)) return;

    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (!source->canSlash(p, slash, false)) continue;
        targets << p;
    }
    if (targets.isEmpty()) return;

    if (targets.length() == 1) {
        ServerPlayer *t = targets.first();
        room->useCard(CardUseStruct(slash, source, t));
        return;
    }

    if (room->askForUseCard(source, "@@mobileyongjungong!", "@mobileyongjungong", -1, Card::MethodUse, false)) return;
    ServerPlayer *t = targets.at(qrand() % targets.length());
    room->useCard(CardUseStruct(slash, source, t));
}

class MobileYongJungongVS : public ViewAsSkill
{
public:
    MobileYongJungongVS() : ViewAsSkill("mobileyongjungong")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern == "@@mobileyongjungong!")
            return false;
        return !Self->isJilei(to_select) && selected.length() < Self->getMark("&mobileyongjungong-Clear") + 1;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern == "@@mobileyongjungong!") {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_mobileyongjungong");
            return slash;
        }

        if (cards.isEmpty())
            return new MobileYongJungongCard;

        if (cards.length() != Self->getMark("&mobileyongjungong-Clear") + 1) return NULL;
        MobileYongJungongCard *c = new MobileYongJungongCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("mobileyongjungong-Clear") <= 0;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@mobileyongjungong!";
    }
};

class MobileYongJungong : public TriggerSkill
{
public:
    MobileYongJungong() : TriggerSkill("mobileyongjungong")
    {
        events << PreChangeSlash << DamageDone;
        view_as_skill = new MobileYongJungongVS;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreChangeSlash)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == PreChangeSlash) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || use.card->getSkillName() != "mobileyongjungong") return false;
            room->setCardFlag(use.card, "mobileyongjungong_slash_" + use.from->objectName());
        } else {
            if (!room->hasCurrent()) return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            ServerPlayer *from = NULL;
            foreach (QString flag, damage.card->getFlags()) {
                if (!flag.startsWith("mobileyongjungong_slash_")) continue;
                QStringList flags = flag.split("_");
                if (flags.length() != 3) continue;
                QString name = flags.last();
                from = room->findPlayerByObjectName(name, true);
                break;
            }
            if (!from || from->isDead()) return false;
            room->addPlayerMark(from, "mobileyongjungong-Clear");
        }
        return false;
    }
};

class MobileYongJungongtMod : public TargetModSkill
{
public:
    MobileYongJungongtMod() : TargetModSkill("#mobileyongjungong-target")
    {
        frequency = NotFrequent;
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->getSkillName() == "mobileyongjungong")
            return 1000;
        else
            return 0;
    }
};

class MobileYongDengli : public TriggerSkill
{
public:
    MobileYongDengli() : TriggerSkill("mobileyongdengli")
    {
        events << TargetSpecifying << TargetConfirming;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        if (triggerEvent == TargetSpecifying) {
            foreach (ServerPlayer *p ,use.to) {
                if (p->isDead() || p->getHp() != player->getHp()) continue;
                if (!player->askForSkillInvoke(this, data)) break;
                room->broadcastSkillInvoke(objectName());
                player->drawCards(1, objectName());
            }
        } else {
            if (!use.to.contains(player)) return false;
            if (!use.from || use.from->isDead() || use.from->getHp() != player->getHp()) return false;
            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(objectName());
            player->drawCards(1, objectName());
        }
        return false;
    }
};

MobileYongPackage::MobileYongPackage()
    : Package("mobileyong")
{
    General *mobileyong_huaman = new General(this, "mobileyong_huaman", "shu", 4, false);
    mobileyong_huaman->addSkill(new MobileYongXiangzhen);
    mobileyong_huaman->addSkill(new MobileYongXiangzhenRecord);
    mobileyong_huaman->addSkill(new MobileYongXiangzhenNullify);
    mobileyong_huaman->addSkill(new MobileYongFangzong);
    mobileyong_huaman->addSkill(new MobileYongFangzongDraw);
    mobileyong_huaman->addSkill(new MobileYongXizhan);
    related_skills.insertMulti("mobileyongxiangzhen", "#mobileyongxiangzhen-record");
    related_skills.insertMulti("mobileyongxiangzhen", "#mobileyongxiangzhen");
    related_skills.insertMulti("mobileyongfangzong", "#mobileyongfangzong");

    General *mobileyong_sunyi = new General(this, "mobileyong_sunyi", "wu", 4);
    mobileyong_sunyi->addSkill(new MobileYongZaoli);
    mobileyong_sunyi->addSkill(new MobileYongZaoliLimit);
    related_skills.insertMulti("mobileyongzaoli", "#mobileyongzaoli-limit");

    General *mobileyong_gaolan = new General(this, "mobileyong_gaolan", "qun", 4);
    mobileyong_gaolan->addSkill(new MobileYongJungong);
    mobileyong_gaolan->addSkill(new MobileYongJungongtMod);
    mobileyong_gaolan->addSkill(new MobileYongDengli);
    related_skills.insertMulti("mobileyongjungong", "#mobileyongjungong-target");

    addMetaObject<MobileYongJungongCard>();
}

ADD_PACKAGE(MobileYong)
