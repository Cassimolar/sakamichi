#include "mobilemouzhi.h"
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

MobileMouZhihengCard::MobileMouZhihengCard()
{
    target_fixed = true;
    will_throw = true;
    mute = true;
}

void MobileMouZhihengCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();

    if (card_use.from->hasInnateSkill("mobilemouzhiheng") || !card_use.from->hasSkill("jilve"))
        room->broadcastSkillInvoke("mobilemouzhiheng");
    else
        room->broadcastSkillInvoke("jilve", 4);

    LogMessage log;
    log.from = card_use.from;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    bool allhand = true;
    if (card_use.from->isKongcheng())
        allhand = false;
    if (allhand) {
        QList<int> sub = subcards;
        foreach(int id, card_use.from->handCards()) {
            if (!sub.contains(id)) {
                allhand = false;
                break;
            }
        }
    }
    if (allhand)
        room->setCardFlag(this, "mobilemouzhiheng_all_handcard_" + card_use.from->objectName());

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, card_use.from->objectName(), QString(), "mobilemouzhiheng", QString());
    room->moveCardTo(this, card_use.from, NULL, Player::DiscardPile, reason, true);

    thread->trigger(CardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void MobileMouZhihengCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int x = subcardsLength();
    bool all = hasFlag("mobilemouzhiheng_all_handcard_" + source->objectName());
    if (all)
        x = x + source->getMark("&mobilemouye") + 1;
    source->drawCards(x, "mobilemouzhiheng");
    if (all)
        source->loseMark("&mobilemouye");
}

class MobileMouZhiheng : public ViewAsSkill
{
public:
    MobileMouZhiheng() : ViewAsSkill("mobilemouzhiheng")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        MobileMouZhihengCard *zhiheng_card = new MobileMouZhihengCard;
        zhiheng_card->addSubcards(cards);
        return zhiheng_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("MobileMouZhihengCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@mobilemouzhiheng";
    }
};

class MobileMouTongye : public PhaseChangeSkill
{
public:
    MobileMouTongye() : PhaseChangeSkill("mobilemoutongye")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        QString choice = room->askForChoice(player, objectName(), "gaibian+bubian");

        LogMessage log;
        log.type = "#FumianFirstChoice";
        log.from = player;
        log.arg = objectName() + ":" + choice;
        room->sendLog(log);

        int equip = 0;
        foreach (ServerPlayer *p, room->getAlivePlayers())
            equip += p->getEquips().length();
        room->setTag("MobileMouTongyeEquipNum", equip);

        int phase = (int)Player::Start;
        room->addPlayerMark(player, "&mobilemoutongye" + choice + "-Self" + QString::number(phase) + "Clear");
        return false;
    }
};

class MobileMouTongyeEquip : public PhaseChangeSkill
{
public:
    MobileMouTongyeEquip() : PhaseChangeSkill("#mobilemoutongye")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Start;
    }

    void sendLog(ServerPlayer *player, bool get) const
    {
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#ZhenguEffect";
        log.from = player;
        log.arg = "mobilemoutongye";
        room->sendLog(log);
        room->notifySkillInvoked(player, "mobilemoutongye");
        player->peiyin("mobilemoutongye");
        if (get)
            player->gainMark("&mobilemouye");
        else
            player->loseMark("&mobilemouye");
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int phase = (int)Player::Start;
        int record_equip = room->getTag("MobileMouTongyeEquipNum").toInt();
        int equip = 0;
        foreach (ServerPlayer *p, room->getAlivePlayers())
            equip += p->getEquips().length();

        if (player->getMark("&mobilemoutongyegaibian-Self" + QString::number(phase) + "Clear") > 0) {
            if (record_equip != equip) {
                if (player->getMark("&mobilemouye") < 2)
                    sendLog(player, true);
            } else {
                if (player->getMark("&mobilemouye") > 0)
                    sendLog(player, false);
            }

        }
        if (player->getMark("&mobilemoutongyebubian-Self" + QString::number(phase) + "Clear") > 0) {
            if (record_equip == equip) {
                if (player->getMark("&mobilemouye") < 2)
                    sendLog(player, true);
            } else {
                if (player->getMark("&mobilemouye") > 0)
                    sendLog(player, false);
            }

        }
        return false;
    }
};

/*class MobileMouTongyeEquip : public TriggerSkill
{
public:
    MobileMouTongyeEquip() : TriggerSkill("#mobilemoutongye")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int phase = (int)Player::Start;
        QString pha = "-Self" + QString::number(phase) + "Clear";
        int zengjia = player->getMark("&mobilemoutongyezengjia" + pha);
        int jianshao = player->getMark("&mobilemoutongyejianshao" + pha);
        if (zengjia <= 0 && jianshao <= 0) return false;

        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from_places.contains(Player::PlaceEquip) || move.to_place == Player::PlaceEquip) {
            int _equip = room->getTag("MobileMouTongyeEquipNum").toInt();
            int equip = 0;
            foreach (ServerPlayer *p, room->getAlivePlayers())
                equip += p->getEquips().length();
            room->setTag("MobileMouTongyeEquipNum", equip);

            int ye = player->getMark("&mobilemouye");

            if (zengjia > 0) {
                if (equip > _equip && ye < 4) {
                    room->sendCompulsoryTriggerLog(player, "mobilemoutongye", true, true);
                    player->gainMark("&mobilemouye", (zengjia + ye < 4) ? zengjia : (4 - ye));
                } else if (equip < _equip && ye > 0) {
                    room->sendCompulsoryTriggerLog(player, "mobilemoutongye", true, true);
                    player->loseMark("&mobilemouye", zengjia);
                }
            }

            if (jianshao > 0) {
                if (equip < _equip && ye < 4) {
                    room->sendCompulsoryTriggerLog(player, "mobilemoutongye", true, true);
                    player->gainMark("&mobilemouye", (jianshao + ye < 4) ? jianshao : (4 - ye));
                } else if (equip > _equip && ye > 0) {
                    room->sendCompulsoryTriggerLog(player, "mobilemoutongye", true, true);
                    player->loseMark("&mobilemouye", jianshao);
                }
            }
        }
        return false;
    }
};*/

class MobileMouJiuyuan : public TriggerSkill
{
public:
    MobileMouJiuyuan() : TriggerSkill("mobilemoujiuyuan$")
    {
        events << CardUsed << PreHpRecover;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (player->getKingdom() != "wu" || !use.card->isKindOf("Peach")) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead() || !p->hasLordSkill(this)) continue;
                if (p->isWeidi())
                    room->sendCompulsoryTriggerLog(p, "weidi", true, true);
                else
                    room->sendCompulsoryTriggerLog(p, this);
                p->drawCards(1, objectName());
            }
        } else {
            if (!player->hasLordSkill(this)) return false;
            RecoverStruct rec = data.value<RecoverStruct>();
            if (rec.card && rec.card->isKindOf("Peach") && rec.who && rec.who != player && rec.who->getKingdom() == "wu") {
                QString skill = objectName();
                if (player->isWeidi())
                    skill = "weidi";

                LogMessage log;
                log.type = "#JiuyuanExtraRecover";
                log.from = player;
                log.to << rec.who;
                log.arg = skill;
                room->sendLog(log);
                room->notifySkillInvoked(player, skill);
                room->broadcastSkillInvoke(skill);

                rec.recover++;
                data = QVariant::fromValue(rec);
            }
        }
        return false;
    }
};

MobileMouZhiPackage::MobileMouZhiPackage()
    : Package("mobilemouzhi")
{
    General *mobilemou_sunquan = new General(this, "mobilemou_sunquan$", "wu", 4);
    mobilemou_sunquan->addSkill(new MobileMouZhiheng);
    mobilemou_sunquan->addSkill(new MobileMouTongye);
    mobilemou_sunquan->addSkill(new MobileMouTongyeEquip);
    mobilemou_sunquan->addSkill(new MobileMouJiuyuan);
    related_skills.insertMulti("mobilemoutongye", "#mobilemoutongye");

    addMetaObject<MobileMouZhihengCard>();
}

ADD_PACKAGE(MobileMouZhi)
