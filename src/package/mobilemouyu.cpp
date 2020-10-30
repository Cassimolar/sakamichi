#include "mobilemouyu.h"
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
#include "json.h"

class MobileMouLiegong : public TriggerSkill
{
public:
    MobileMouLiegong() : TriggerSkill("mobilemouliegong")
    {
        events << TargetSpecified << CardUsed << CardResponded << TargetConfirmed;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || use.to.length() != 1) return false;
            ServerPlayer *to = use.to.first();
            if (!player->askForSkillInvoke(this, to)) return false;
            player->peiyin(this);

            room->setCardFlag(use.card, "mobilemouliegongUsed");
            room->setCardFlag(use.card, "mobilemouliegongUsed_" + player->objectName());

            QString record = player->property("MobileMouLiegongRecords").toString();
            if (record.isEmpty()) return false;
            QStringList records = record.split(",");

            int attack = records.length() - 1;
            if (attack <= 0) return false;

            QList<int> shows = room->showDrawPile(player, attack, objectName(), false);
            room->fillAG(shows);
            room->getThread()->delay(1000);
            room->clearAG();

            int damage = 0;
            foreach (int id, shows) {
                const Card *c = Sanguosha->getCard(id);
                if (records.contains(c->getSuitString()))
                    damage++;
            }
            if (damage > 0)
                room->setCardFlag(use.card, "mobilemouliegongAddDamage_" + QString::number(damage));
            room->addPlayerMark(to, "mobilemouliegongTarget-Clear");
            room->setPlayerProperty(to, "MobileMouLiegongTargetRecords", records.join(","));
        } else {
            const Card *card = NULL;
            if (event == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                card = use.card;
            } else if (event == CardResponded) {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            } else if (event == TargetConfirmed) {
                CardUseStruct use = data.value<CardUseStruct>();
                if (use.from == player || !use.to.contains(player)) return false;
                card = use.card;
            }
            if (!card || card->isKindOf("SkillCard") || !card->hasSuit()) return false;

            QString record = player->property("MobileMouLiegongRecords").toString(), suit = card->getSuitString();
            QStringList records;
            if (!record.isEmpty())
                records = record.split(",");
            if (records.contains(suit)) return false;
            records << suit;
            room->setPlayerProperty(player, "MobileMouLiegongRecords", records.join(","));
            foreach (QString mark, player->getMarkNames()) {
                if (!mark.startsWith("&mobilemouliegong+#record") || player->getMark(mark) <= 0) continue;
                room->setPlayerMark(player, mark, 0);
            }
            QString mark = "&mobilemouliegong+#record";
            foreach (QString suit, records)
                mark = mark + "+" + suit + "_char";
            room->setPlayerMark(player, mark, 1);
        }
        return false;
    }
};

class MobileMouLiegongEffect : public TriggerSkill
{
public:
    MobileMouLiegongEffect() : TriggerSkill("#mobilemouliegong")
    {
        events << ConfirmDamage << CardFinished << PreCardResponded << SlashHit << EventLoseSkill; // << JinkEffect;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == PreCardResponded || event == SlashHit || event == CardFinished)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventLoseSkill) {
            if (data.toString() != "mobilemouliegong") return false;
            //room->setPlayerProperty(player, "MobileMouLiegongRecords", QString());
            foreach (QString mark, player->getMarkNames()) {
                if (!mark.startsWith("&mobilemouliegong+#record") || player->getMark(mark) <= 0) continue;
                room->setPlayerMark(player, mark, 0);
            }
        } else if (event == SlashHit) {
            SlashEffectStruct slash = data.value<SlashEffectStruct>();
            if (!slash.slash->hasFlag("mobilemouliegongUsed")) return false;
            room->setPlayerMark(slash.to, "mobilemouliegongTarget-Clear", 0);
            room->setPlayerProperty(slash.to, "MobileMouLiegongTargetRecords", QString());
        } else if (event == PreCardResponded) {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse || !res.m_toCard || !res.m_toCard->hasFlag("mobilemouliegongUsed")) return false;
            room->setPlayerMark(player, "mobilemouliegongTarget-Clear", 0);
            room->setPlayerProperty(player, "MobileMouLiegongTargetRecords", QString());
        } else if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || !use.card->hasFlag("mobilemouliegongUsed")) return false;

            foreach (ServerPlayer *p, room->getAllPlayers(true)) {   //这里没有考虑场上多个烈弓，会把其他人给的烈弓debuff一起清除掉
                room->setPlayerMark(p, "mobilemouliegongTarget-Clear", 0);
                room->setPlayerProperty(p, "MobileMouLiegongTargetRecords", QString());
            }

            ServerPlayer *from = NULL;
            foreach (QString flag, use.card->getFlags()) {
                if (!flag.startsWith("mobilemouliegongUsed_")) continue;
                QStringList flags = flag.split("_");
                if (flags.length() != 2) continue;
                QString name = flags.last();
                from = room->findPlayerByObjectName(name, true);
                if (from)
                    break;
            }
            if (!from) return false;
            room->setPlayerProperty(from, "MobileMouLiegongRecords", QString());
            foreach (QString mark, from->getMarkNames()) {
                if (!mark.startsWith("&mobilemouliegong+#record") || from->getMark(mark) <= 0) continue;
                room->setPlayerMark(from, mark, 0);
            }
        } else if (event == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || !damage.to || damage.to->isDead()) return false;
            int d = 0;
            foreach (QString flag, damage.card->getFlags()) {
                if (!flag.startsWith("mobilemouliegongAddDamage_")) continue;
                QStringList flags = flag.split("_");
                if (flags.length() != 2) continue;
                d = flags.last().toInt();
                if (d > 0)
                    break;
            }
            if (d <= 0) return false;

            LogMessage log;
            log.type = "#YHHankaiDamage";
            log.from = player;
            log.to << damage.to;
            log.arg = "mobilemouliegong";
            log.arg2 = QString::number(damage.damage);
            log.arg3 = QString::number(damage.damage += d);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class MobileMouLiegongLimit : public CardLimitSkill
{
public:
    MobileMouLiegongLimit() : CardLimitSkill("#mobilemouliegong-limit")
    {
        frequency = NotFrequent;
    }

    QString limitList(const Player *target) const
    {
        QString record = target->property("MobileMouLiegongTargetRecords").toString();
        if (!record.isEmpty())
            return "use";
        return QString();
    }

    QString limitPattern(const Player *target) const
    {
        QString record = target->property("MobileMouLiegongTargetRecords").toString();
        if (!record.isEmpty())
            return "Jink|" + record;
        return QString();
    }
};

MobileMouKejiCard::MobileMouKejiCard()
{
    target_fixed = true;
}

void MobileMouKejiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->addPlayerMark(source, "mobilemoukeji-PlayClear", subcardsLength() + 1);
    if (subcards.isEmpty()) {
        room->loseHp(source);
        if (source->isAlive())
            source->gainHujia(2, 5);
    } else
        source->gainHujia(1, 5);
}

class MobileMouKeji : public ViewAsSkill
{
public:
    MobileMouKeji() : ViewAsSkill("mobilemoukeji")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.isEmpty() && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int mark = Self->getMark("mobilemoukeji-PlayClear");
        if (mark <= 0 && !cards.isEmpty() && cards.length() != 1) return NULL;
        if (mark == 1 && cards.length() != 1) return NULL;
        if (mark >= 2 && !cards.isEmpty()) return NULL;
        MobileMouKejiCard *c = new MobileMouKejiCard;
        if (!cards.isEmpty())
            c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("mobilemoudujiang") > 0)
            return !player->hasUsed("MobileMouKejiCard");
        return player->getMark("mobilemoukeji-PlayClear") < 3;
    }
};

class MobileMouKejiMax : public MaxCardsSkill
{
public:
    MobileMouKejiMax() : MaxCardsSkill("#mobilemoukeji-max")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("mobilemoukeji"))
            return qMax(target->getHujia(), 0);
        else
            return 0;
    }
};

class MobileMouKejiLimit : public CardLimitSkill
{
public:
    MobileMouKejiLimit() : CardLimitSkill("#mobilemoukeji-limit")
    {
        frequency = NotFrequent;
    }

    QString limitList(const Player *target) const
    {
        if (target->hasSkill("mobilemoukeji") && !target->hasFlag("Global_Dying"))
            return "use";
        return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->hasSkill("mobilemoukeji") && !target->hasFlag("Global_Dying"))
            return "Peach";
        return QString();
    }
};

class MobileMouDujiang : public PhaseChangeSkill
{
public:
    MobileMouDujiang() : PhaseChangeSkill("mobilemoudujiang")
    {
        frequency = Wake;
        waked_skills = "mobilemouduojing";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getHujia() >= 3) {
            LogMessage log;
            log.type = "#MobileMouDujiang";
            log.from = player;
            log.arg = QString::number(player->getHujia());
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
        player->peiyin(this);
        room->doSuperLightbox("mobilemou_lvmeng", objectName());

        room->setPlayerMark(player, "mobilemoudujiang", 1);
        if (room->changeMaxHpForAwakenSkill(player, 0))
            room->acquireSkill(player, "mobilemouduojing");
        return false;
    }
};

class MobileMouDuojiang : public TriggerSkill
{
public:
    MobileMouDuojiang() : TriggerSkill("mobilemouduojing")
    {
        events << TargetSpecifying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead() || player->getHujia() <= 0) return false;
            if (p == player || p->isDead()) continue;
            if (!player->askForSkillInvoke(this, p)) continue;
            player->peiyin(this);
            player->loseHujia(1);
            if (p->isAlive())
                p->addQinggangTag(use.card);
            if (player->isAlive() && p->isAlive() && !p->isKongcheng()) {
                int card_id = room->askForCardChosen(player, p, "h", "mobilemouduojing");
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, Sanguosha->getCard(card_id),
                    reason, room->getCardPlace(card_id) != Player::PlaceHand);
            }
            if (player->isAlive())
                room->addSlashCishu(player, 1);
        }
        return false;
    }
};

class MobileMouXiayuanRecord : public TriggerSkill
{
public:
    MobileMouXiayuanRecord() : TriggerSkill("#mobilemouxiayuan")
    {
        events << DamageDone;
        global = true;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        return TriggerSkill::getPriority(triggerEvent) - 1;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        int d = damage.damage, hujia = player->getHujia();
        if (hujia > d || d <= 0 || hujia <= 0) return false;
        QStringList tips = damage.tips;
        foreach (QString tip, tips) {
            if (!tip.startsWith("MobileMouDuojiangDamage_")) continue;
            tips.removeOne(tip);
        }
        tips << "MobileMouDuojiangDamage_" + QString::number(hujia);
        damage.tips = tips;
        data = QVariant::fromValue(damage);
        return false;
    }
};

class MobileMouXiayuan : public MasochismSkill
{
public:
    MobileMouXiayuan() : MasochismSkill("mobilemouxiayuan")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        Room *room = player->getRoom();
        int d = 0;
        foreach (QString tip, damage.tips) {
            if (!tip.startsWith("MobileMouDuojiangDamage_")) continue;
            QStringList tips = tip.split("_");
            if (tips.length() != 2) continue;
            d = tips.last().toInt();
            if (d > 0) break;
        }
        if (d <= 0) return;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return;
            if (p->isDead() || !p->hasSkill(this) || p->getMark("mobilemouxiayuan_lun") > 0
                    || !p->canDiscard(p, "he") || p->getCardCount() < 2) continue;
            if (!room->askForDiscard(p, objectName(), 2, 2, true, false, "@mobilemouxiayuan:" + player->objectName() + "::" + QString::number(d),
                                     ".|.|.|hand", objectName())) continue;
            room->addPlayerMark(p, "mobilemouxiayuan_lun");
            if (player->isAlive())
                player->gainHujia(d, 5);
        }
    }
};

class MobileMouJieyue : public PhaseChangeSkill
{
public:
    MobileMouJieyue() : PhaseChangeSkill("mobilemoujieyue")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@mobilemoujieyue-invoke", true, true);
        if (!t) return false;
        room->broadcastSkillInvoke(this);
        t->gainHujia(1, 5);
        t->drawCards(2, objectName());
        if (t->isAlive() && !t->isNude() && player->isAlive()) {
            const Card *ex = room->askForExchange(t, objectName(), 2, 2, true, "@mobilemoujieyue-give:" + player->objectName());
            room->giveCard(t, player, ex, objectName());
            delete ex;
        }
        return false;
    }
};

MobileMouYuPackage::MobileMouYuPackage()
    : Package("mobilemouyu")
{
    General *mobilemou_huangzhong = new General(this, "mobilemou_huangzhong", "shu", 4);
    mobilemou_huangzhong->addSkill(new MobileMouLiegong);
    mobilemou_huangzhong->addSkill(new MobileMouLiegongEffect);
    mobilemou_huangzhong->addSkill(new MobileMouLiegongLimit);
    mobilemou_huangzhong->addSkill("#tenyearliegongmod");
    related_skills.insertMulti("mobilemouliegong", "#mobilemouliegong");
    related_skills.insertMulti("mobilemouliegong", "#mobilemouliegong-limit");
    related_skills.insertMulti("mobilemouliegong", "#tenyearliegongmod");

    General *mobilemou_lvmeng = new General(this, "mobilemou_lvmeng", "wu", 4);
    mobilemou_lvmeng->addSkill(new MobileMouKeji);
    mobilemou_lvmeng->addSkill(new MobileMouKejiMax);
    mobilemou_lvmeng->addSkill(new MobileMouKejiLimit);
    mobilemou_lvmeng->addSkill(new MobileMouDujiang);
    mobilemou_lvmeng->addRelateSkill("mobilemouduojing");
    related_skills.insertMulti("mobilemoukeji", "#mobilemoukeji-max");
    related_skills.insertMulti("mobilemoukeji", "#mobilemoukeji-limit");

    General *mobilemou_yujin = new General(this, "mobilemou_yujin", "wei", 4);
    mobilemou_yujin->addSkill(new MobileMouXiayuan);
    mobilemou_yujin->addSkill(new MobileMouXiayuanRecord);
    mobilemou_yujin->addSkill(new MobileMouJieyue);
    related_skills.insertMulti("mobilemouxiayuan", "#mobilemouxiayuan");

    addMetaObject<MobileMouKejiCard>();

    skills << new MobileMouDuojiang;
}

ADD_PACKAGE(MobileMouYu)
