#include "sp6.h"
#include "settings.h"
#include "skill.h"
#include "standard.h"
#include "client.h"
#include "clientplayer.h"
#include "clientstruct.h"
#include "engine.h"
#include "maneuvering.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "json.h"

QianlongCard::QianlongCard()
{
    mute = true;
    handling_method = Card::MethodNone;
    will_throw = false;
    target_fixed = true;
}

void QianlongCard::onUse(Room *room, const CardUseStruct &use) const
{
    room->obtainCard(use.from, this, true);
}

class QianlongVS : public ViewAsSkill
{
public:
    QianlongVS() : ViewAsSkill("qianlong")
    {
        expand_pile = "#qianlong";
        response_pattern = "@@qianlong";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int losehp = Self->getLostHp();
        return selected.length() < losehp && Self->getPile("#qianlong").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        QianlongCard *c = new QianlongCard;
        c->addSubcards(cards);
        return c;
    }
};

class Qianlong : public MasochismSkill
{
public:
    Qianlong() : MasochismSkill("qianlong")
    {
        view_as_skill = new QianlongVS;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        if (!player->askForSkillInvoke(this)) return;
        player->peiyin(this);

        Room *room = player->getRoom();
        QList<int> shows = room->showDrawPile(player, 3, objectName(), false);
        room->fillAG(shows);

        int losehp = player->getLostHp();
        if (losehp <= 0) {
            room->askForGuanxing(player, shows, Room::GuanxingDownOnly);
            room->clearAG();
            return;
        }

        room->notifyMoveToPile(player, shows, objectName(), Player::DrawPile, true);
        const Card *c = room->askForUseCard(player, "@@qianlong", "@qianlong:" + QString::number(losehp));
        room->notifyMoveToPile(player, shows, objectName(), Player::DrawPile, false);

        if (c) {
            foreach (int id, c->getSubcards())
                shows.removeOne(id);
        }

        room->clearAG();
        if (!shows.isEmpty() && player->isAlive())
            room->askForGuanxing(player, shows, Room::GuanxingDownOnly);
    }
};

class Fensi : public PhaseChangeSkill
{
public:
    Fensi() : PhaseChangeSkill("fensi")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;

        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        int hp = player->getHp();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() >= hp)
                targets << p;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@fensi-damage", false, true);
        player->peiyin(this);
        room->damage(DamageStruct(objectName(), player, t));

        if (t->isAlive() && player->isAlive() && t != player) {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->deleteLater();
            room->setCardFlag(slash, "YUANBEN");
            slash->setSkillName("_fensi");
            if (t->canSlash(player, slash, false))
                room->useCard(CardUseStruct(slash, t, player), true);
        }
        return false;
    }
};

SP6Package::SP6Package()
    : Package("sp6")
{
    General *caomao = new General(this, "caomao$", "wei", 4);
    caomao->addSkill(new Qianlong);
    caomao->addSkill(new Fensi);

    addMetaObject<QianlongCard>();
}

ADD_PACKAGE(SP6)
