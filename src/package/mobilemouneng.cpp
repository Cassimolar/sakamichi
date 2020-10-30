#include "mobilemouneng.h"
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

MobileMouYangweiCard::MobileMouYangweiCard()
{
    target_fixed = true;
}

void MobileMouYangweiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(2, "mobilemouyangwei");
    room->addPlayerMark(source, "mobilemouyangwei-PlayClear");
    room->setPlayerMark(source, "mobilemouyangweiUsed", 2);
}

class MobileMouYangweiVS : public ZeroCardViewAsSkill
{
public:
    MobileMouYangweiVS() : ZeroCardViewAsSkill("mobilemouyangwei")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileMouYangweiCard") && player->getMark("mobilemouyangweiUsed") <= 0;
    }

    const Card *viewAs() const
    {
        return new MobileMouYangweiCard;
    }
};

class MobileMouYangwei : public PhaseChangeSkill
{
public:
    MobileMouYangwei() : PhaseChangeSkill("mobilemouyangwei")
    {
        view_as_skill = new MobileMouYangweiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getMark("mobilemouyangweiUsed") > 0 && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        room->removePlayerMark(player, "mobilemouyangweiUsed");
        return false;
    }
};

class MobileMouYangweiEffect : public TriggerSkill
{
public:
    MobileMouYangweiEffect() : TriggerSkill("#mobilemouyangwei")
    {
        events << CardUsed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getMark("mobilemouyangwei-PlayClear") > 0 && target->getPhase() == Player::Play;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, use.to)
            p->addQinggangTag(use.card);
        return false;
    }
};

class MobileMouYangweiTargetMod : public TargetModSkill
{
public:
    MobileMouYangweiTargetMod() : TargetModSkill("#mobilemouyangwei-target")
    {
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->getPhase() == Player::Play)
            return from->getMark("mobilemouyangwei-PlayClear");
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->getPhase() == Player::Play && from->getMark("mobilemouyangwei-PlayClear") > 0)
            return 1000;
        else
            return 0;
    }
};

MobileMouNengPackage::MobileMouNengPackage()
    : Package("mobilemouneng")
{
    General *mobilemou_huaxiong = new General(this, "mobilemou_huaxiong", "qun", 4);
    mobilemou_huaxiong->setStartHp(2);
    mobilemou_huaxiong->setStartHujia(1);
    mobilemou_huaxiong->addSkill("tenyearyaowu");
    mobilemou_huaxiong->addSkill(new MobileMouYangwei);
    mobilemou_huaxiong->addSkill(new MobileMouYangweiEffect);
    mobilemou_huaxiong->addSkill(new MobileMouYangweiTargetMod);
    related_skills.insertMulti("mobilemouyangwei", "#mobilemouyangwei");
    related_skills.insertMulti("mobilemouyangwei", "#mobilemouyangwei-target");

    addMetaObject<MobileMouYangweiCard>();
}

ADD_PACKAGE(MobileMouNeng)
