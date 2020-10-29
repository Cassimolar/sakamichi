#include "doudizhu.h"
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

FeiyangCard::FeiyangCard()
{
    mute = true;
    target_fixed = true;
    will_throw = false;
}

void FeiyangCard::onUse(Room *, const CardUseStruct &) const
{
}

class FeiyangVS : public ViewAsSkill
{
public:
    FeiyangVS() : ViewAsSkill("feiyang")
    {
        response_pattern = "@@feiyang";
        expand_pile = "#feiyang";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() > 2 || to_select->isEquipped()) return false;
        QList<int> ids = Self->getPile("#feiyang");

        if (selected.isEmpty()) return true;
        if (selected.length() == 1) {
            if (ids.contains(selected.first()->getEffectiveId()))
                return !ids.contains(to_select->getEffectiveId());
            else
                return true;
        } else if (selected.length() == 2) {
            if (ids.contains(selected.first()->getEffectiveId()) || ids.contains(selected.last()->getEffectiveId()))
                return !ids.contains(to_select->getEffectiveId());
            else
                return ids.contains(to_select->getEffectiveId());
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hand = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card))
                hand++;
            else if (Self->getPile("#feiyang").contains(card->getEffectiveId()))
                pile++;
        }

        if (hand == 2 && pile == 1) {
            FeiyangCard *c = new FeiyangCard;
            c->addSubcards(cards);
            return c;
        }

        return NULL;
    }
};

class Feiyang : public PhaseChangeSkill
{
public:
    Feiyang() : PhaseChangeSkill("feiyang")
    {
        view_as_skill = new FeiyangVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Judge || !player->canDiscard(player, "j") || player->hasFlag(objectName())) return false;
        int n = 0;
        foreach (int id, player->handCards()) {
            if (player->canDiscard(player, id)) {
                n++;
                if (n >= 2)
                    break;
            }
        }
        if (n < 2) return false;
        Room *room = player->getRoom();
        room->notifyMoveToPile(player, player->getJudgingAreaID(), objectName(), Player::PlaceDelayedTrick, true);
        const Card *c = room->askForUseCard(player, "@@feiyang", "@feiyang");
        room->notifyMoveToPile(player, player->getJudgingAreaID(), objectName(), Player::PlaceDelayedTrick, false);
        if (!c) return false;

        room->setPlayerFlag(player, objectName());
        DummyCard *dummy = new DummyCard;
        DummyCard *card = new DummyCard;
        foreach (int id, c->getSubcards()) {
            if (!player->handCards().contains(id))
                card->addSubcard(id);
            else
                dummy->addSubcard(id);
        }

        LogMessage log;
        log.type = "$DiscardCardWithSkill";
        log.from = player;
        log.arg = objectName();
        log.card_str = IntList2StringList(dummy->getSubcards()).join("+");
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());

        CardMoveReason reason(CardMoveReason::S_REASON_THROW, player->objectName(), QString(), "feiyang", QString());
        room->moveCardTo(dummy, player, NULL, Player::DiscardPile, reason, true);

        if (player->isAlive() && card->subcardsLength() > 0) {
            int id = card->getSubcards().first();
            if (room->getCardOwner(id) && room->getCardOwner(id) == player && room->getCardPlace(id) == Player::PlaceDelayedTrick)
                room->throwCard(card, NULL, player);
        }

        delete dummy;
        delete card;
        return false;
    }
};

class Bahu : public PhaseChangeSkill
{
public:
    Bahu() : PhaseChangeSkill("bahu")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        player->getRoom()->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(1, objectName());
        return false;
    }
};

class BahuTargetMod : public TargetModSkill
{
public:
    BahuTargetMod() : TargetModSkill("#bahu-target")
    {
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("bahu"))
            return 1;
        else
            return 0;
    }
};

DoudizhuPackage::DoudizhuPackage()
    : Package("Doudizhu")
{
    related_skills.insertMulti("bahu", "#bahu-target");

    skills << new Feiyang << new Bahu << new BahuTargetMod;

    addMetaObject<FeiyangCard>();
}

ADD_PACKAGE(Doudizhu)
