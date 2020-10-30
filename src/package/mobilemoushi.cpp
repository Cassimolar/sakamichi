#include "mobilemoushi.h"
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

MobileMouDuanliangCard::MobileMouDuanliangCard()
{
}

void MobileMouDuanliangCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    QString str = "=" + to->objectName();
    QString choice1 = room->askForChoice(from, "mobilemouduanliang", "weicheng" + str + "+leigu" + str, QVariant::fromValue(to));
    if (to->isDead()) return;
    str = "=" + from->objectName();
    QString choice2 = room->askForChoice(to, "mobilemouduanliang", "weicheng2" + str + "+leigu2" + str, QVariant::fromValue(from));

    choice1 = choice1.split("=").first();
    choice2 = choice2.split("=").first();
    if (choice2.startsWith(choice1) || to->isDead() || from->isDead()) return;

    if (choice1 == "weicheng") {
        if (to->containsTrick("supply_shortage")) {
            if (to->isNude()) return;
            int card_id = room->askForCardChosen(from, to, "he", "mobilemouduanliang");
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, from->objectName());
            room->obtainCard(from, Sanguosha->getCard(card_id),
                reason, room->getCardPlace(card_id) != Player::PlaceHand);
        } else {
            SupplyShortage *su = new SupplyShortage(Card::NoSuit, 0);
            su->setSkillName("_mobilemouduanliang");
            su->deleteLater();
            if (!to->hasJudgeArea() || !from->canUse(su, to, true) || to->containsTrick("supply_shortage")) return;
            su->addSubcard(room->drawCard());
            room->useCard(CardUseStruct(su, from, to), true);
        }
    } else {
        Duel *duel = new Duel(Card::NoSuit, 0);
        duel->deleteLater();
        duel->setSkillName("_mobilemouduanliang");
        if (from->canUse(duel, to, true))
            room->useCard(CardUseStruct(duel, from, to), true);
    }
}

class MobileMouDuanliang : public ZeroCardViewAsSkill
{
public:
    MobileMouDuanliang() : ZeroCardViewAsSkill("mobilemouduanliang")
    {
    }

    const Card *viewAs() const
    {
        return new MobileMouDuanliangCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("MobileMouDuanliangCard") < 2;
    }
};

MobileMouShipoCard::MobileMouShipoCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void MobileMouShipoCard::onUse(Room *room, const CardUseStruct &use) const
{
    ServerPlayer *player = use.from, *to = use.to.first();
    room->setPlayerProperty(player, "mobilemoushipo_card_ids", QString());
    room->giveCard(player, to, this, "mobilemoushipo");
}

class MobileMouShipoVS : public ViewAsSkill
{
public:
    MobileMouShipoVS() : ViewAsSkill("mobilemoushipo")
    {
        response_pattern = "@@mobilemoushipo";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        QStringList l = Self->property("mobilemoushipo_card_ids").toString().split("+");
        QList<int> li = StringList2IntList(l);
        return li.contains(to_select->getId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        MobileMouShipoCard *c = new MobileMouShipoCard;
        c->addSubcards(cards);
        return c;
    }
};

class MobileMouShipo : public PhaseChangeSkill
{
public:
    MobileMouShipo() : PhaseChangeSkill("mobilemoushipo")
    {
        view_as_skill = new MobileMouShipoVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();

        QStringList choices;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHp() < player->getHp() && !choices.contains("hp"))
                choices << "hp";
            if (p->containsTrick("supply_shortage") && !choices.contains("judge"))
                choices << "judge";
            if (choices.length() == 2)
                break;
        }
        if (choices.isEmpty()) return false;
        choices << "cancel";

        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        if (choice == "cancel") return false;

        LogMessage log;
        log.type = "#MobileMouShipoInvoke";
        log.from = player;
        log.arg = objectName();

        QList<ServerPlayer *> choose;
        if (choice == "hp") {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHp() < player->getHp())
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@mobilemoushipo-target");
            choose << t;
        } else {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->containsTrick("supply_shortage"))
                    choose << p;
            }
            if (choose.isEmpty()) return false;
        }

        foreach (ServerPlayer *p, choose)
            room->doAnimate(1, player->objectName(), p->objectName());

        log.to = choose;
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);

        QList<int> cards;
        foreach (ServerPlayer *p, choose) {
            if (p->isDead()) continue;
            if (player->isDead()) {
                room->damage(DamageStruct(objectName(), NULL, p));
                continue;
            }
            const Card *c = room->askForExchange(p, objectName(), 1, 1, false, "@mobilemoushipo-give:" + player->objectName(), true);
            if (c) {
                cards << c->getSubcards();
                room->giveCard(p, player, c, "mobilemoushipo");
            } else
                room->damage(DamageStruct(objectName(), NULL, p));
        }

        if (player->isDead()) return false;

        QList<int> ids;
        foreach (int id, cards) {
            if (!player->hasCard(id)) continue;
            ids << id;
        }
        if (ids.isEmpty()) return false;

        room->setPlayerProperty(player, "mobilemoushipo_card_ids", IntList2StringList(ids).join("+"));
        room->askForUseCard(player, "@@mobilemoushipo", "@mobilemoushipo", -1, Card::MethodNone);
        room->setPlayerProperty(player, "mobilemoushipo_card_ids", QString());
        return false;
    }
};

class MobileMouTieqi : public TriggerSkill
{
public:
    MobileMouTieqi() : TriggerSkill("mobilemoutieqi")
    {
        events << TargetSpecifying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, use.to) {
            if (!player->isAlive()) break;
            if (p->isDead()) continue;
            if (player->askForSkillInvoke(this, p)) {
                room->broadcastSkillInvoke(objectName());
                if (!tos.contains(p)) {
                    p->addMark("mobilemoutieqi");
                    room->addPlayerMark(p, "@skill_invalidity");
                    tos << p;

                    foreach(ServerPlayer *pl, room->getAllPlayers())
                        room->filterCards(pl, pl->getCards("he"), true);
                    JsonArray args;
                    args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
                    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
                }

                LogMessage log;
                log.type = "#NoJink";
                log.from = p;
                room->sendLog(log);

                use.no_respond_list << p->objectName();
                data = QVariant::fromValue(use);

                if (player->isDead() || p->isDead()) continue;

                QString str = "=" + p->objectName();
                QString choice1 = room->askForChoice(player, objectName(), "zhiqu" + str + "+raozhen" + str, QVariant::fromValue(p));
                if (p->isDead()) continue;
                str = "=" + player->objectName();
                QString choice2 = room->askForChoice(p, objectName(), "zhiqu2" + str + "+raozhen2" + str, QVariant::fromValue(player));

                choice1 = choice1.split("=").first();
                choice2 = choice2.split("=").first();
                if (choice2.startsWith(choice1) || p->isDead() || player->isDead()) continue;

                if (choice1 == "zhiqu") {
                    if (p->isNude()) continue;
                    int id = room->askForCardChosen(player, p, "he", objectName());
                    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                    room->obtainCard(player, Sanguosha->getCard(id), reason, room->getCardPlace(id) != Player::PlaceHand);
                } else
                    player->drawCards(2, objectName());
            }
        }
        return false;
    }
};

class MobileMouTieqiClear : public TriggerSkill
{
public:
    MobileMouTieqiClear() : TriggerSkill("#mobilemoutieqi")
    {
        events << EventPhaseChanging << Death;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *target, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive)
                return false;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != target || target != room->getCurrent())
                return false;
        }
        QList<ServerPlayer *> players = room->getAllPlayers(true);
        foreach (ServerPlayer *player, players) {
            if (player->getMark("mobilemoutieqi") == 0) continue;
            room->removePlayerMark(player, "@skill_invalidity", player->getMark("mobilemoutieqi"));
            player->setMark("mobilemoutieqi", 0);

            foreach(ServerPlayer *p, room->getAllPlayers())
                room->filterCards(p, p->getCards("he"), false);
            JsonArray args;
            args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
        }
        return false;
    }
};

MobileMouShiPackage::MobileMouShiPackage()
    : Package("mobilemoushi")
{
    General *mobilemou_xuhuang = new General(this, "mobilemou_xuhuang", "wei", 4);
    mobilemou_xuhuang->addSkill(new MobileMouDuanliang);
    mobilemou_xuhuang->addSkill(new MobileMouShipo);

    General *mobilemou_machao = new General(this, "mobilemou_machao", "shu", 4);
    mobilemou_machao->addSkill(new MobileMouTieqi);
    mobilemou_machao->addSkill(new MobileMouTieqiClear);
    mobilemou_machao->addSkill("mashu");
    related_skills.insertMulti("mobilemoutieqi", "#mobilemoutieqi");

    addMetaObject<MobileMouDuanliangCard>();
    addMetaObject<MobileMouShipoCard>();
}

ADD_PACKAGE(MobileMouShi)
