#include "happy2v2.h"
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

class HappyRule : public TriggerSkill
{
public:
    HappyRule() : TriggerSkill("happy_rule")
    {
        events << DrawNCards << DrawInitialCards;
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 10;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (room->getMode() != "04_2v2") return false;
        if (event == DrawNCards) {
            if (room->getTag("TurnLengthCount").toInt() != 1) return false;
            if (player != room->getPlayers().first()) return false;
            data = data.toInt() - 1;
        } else if (event == DrawInitialCards) {
            if (player != room->getPlayers().last()) return false;
            data = data.toInt() + 1;
        }
        return false;
    }
};

KuijiCard::KuijiCard()
{
    mute = true;
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodUse;
}

void KuijiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    const Card *c = Sanguosha->getCard(getSubcards().first());
    SupplyShortage *supply_shortage = new SupplyShortage(c->getSuit(), c->getNumber());
    supply_shortage->addSubcard(c);
    supply_shortage->setSkillName("kuiji");
    supply_shortage->deleteLater();
    if (card_use.from->isProhibited(card_use.from, supply_shortage)) return;
    room->useCard(CardUseStruct(supply_shortage, card_use.from, card_use.from), true);
    if (card_use.from->isDead()) return;
    card_use.from->drawCards(1, "kuiji");
    if (card_use.from->isDead()) return;

    QList<ServerPlayer *> enemies;
    foreach (ServerPlayer *p, room->getOtherPlayers(card_use.from)) {
        if (!card_use.from->isYourFriend(p))
            enemies << p;
    }
    if (enemies.isEmpty()) return;

    int hp = enemies.first()->getHp();
    foreach (ServerPlayer *p, enemies) {
        if (p->getHp() > hp)
            hp = p->getHp();
    }

    QList<ServerPlayer *> _enemies;
    foreach (ServerPlayer *p, enemies) {
        if (p->getHp() >= hp)
            _enemies << p;
    }
    if (_enemies.isEmpty()) return;

    ServerPlayer *enemy = room->askForPlayerChosen(card_use.from, _enemies, "kuiji", "@kuiji", true);
    if (!enemy) return;
    room->doAnimate(1, card_use.from->objectName(), enemy->objectName());
    room->damage(DamageStruct("kuiji", card_use.from, enemy, 2));
}

class KuijiVS : public OneCardViewAsSkill
{
public:
    KuijiVS() : OneCardViewAsSkill("kuiji")
    {
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        if (!to_select->isKindOf("BasicCard") || !to_select->isBlack()) return false;
        SupplyShortage *supply_shortage = new SupplyShortage(to_select->getSuit(), to_select->getNumber());
        supply_shortage->addSubcard(to_select);
        supply_shortage->setSkillName("kuiji");
        supply_shortage->deleteLater();
        return !Self->isJilei(supply_shortage) && !Self->isProhibited(Self, supply_shortage);
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        SupplyShortage *supply_shortage = new SupplyShortage(Card::NoSuit, 0);
        supply_shortage->setSkillName("kuiji");
        supply_shortage->deleteLater();
        return player->hasJudgeArea() && !player->containsTrick("supply_shortage") && !Self->isProhibited(Self, supply_shortage) &&
                !player->hasUsed("KuijiCard");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        KuijiCard *c = new KuijiCard;
        c->addSubcard(originalcard);
        return c;
    }
};

class Kuiji : public TriggerSkill
{
public:
    Kuiji() :TriggerSkill("kuiji")
    {
        events << Dying;
        view_as_skill = new KuijiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (!dying.damage || dying.damage->reason != objectName()) return false;
        if (player->isYourFriend(dying.who)) return false;

        //room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        QList<ServerPlayer *> friends;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isYourFriend(p))
                friends << p;
        }
        if (friends.isEmpty()) return false;

        int hp = friends.first()->getHp();
        foreach (ServerPlayer *p, friends) {
            if (p->getHp() < hp)
                hp = p->getHp();
        }

        QList<ServerPlayer *> _friends;
        foreach (ServerPlayer *p, friends) {
            if (p->getHp() <= hp && p->getLostHp() > 0)
                _friends << p;
        }
        if (_friends.isEmpty()) return false;

        ServerPlayer *fri = room->askForPlayerChosen(player, _friends, "kuiji", "@kuiji_recover");
        room->doAnimate(1, player->objectName(), fri->objectName());
        if (fri->getLostHp() > 0)
            room->recover(fri, RecoverStruct(player));
        return false;
    }
};

class HappyCuorui : public PhaseChangeSkill
{
public:
    HappyCuorui() :PhaseChangeSkill("happycuorui")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;

        Room *room = player->getRoom();
        QList<ServerPlayer *> friends;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isYourFriend(p) && player->canDiscard(p, "hej"))
                friends << p;
        }
        if (friends.isEmpty()) return false;

        ServerPlayer *fri = room->askForPlayerChosen(player, friends, "happycuorui", "@happycuorui", true, true);
        if (!fri) return false;
        room->broadcastSkillInvoke(objectName());

        if (!player->canDiscard(fri, "hej")) return false;
        int id = room->askForCardChosen(player, fri, "hej", objectName(), false, Card::MethodDiscard);
        room->throwCard(id, fri, player);

        if (!player->isAlive()) return false;

        const Card *throw_card = Sanguosha->getCard(id);
        QList<ServerPlayer *> enemies;
        QStringList choices;
        int hand = 0;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!player->isYourFriend(p)) {
                if (!p->getEquips().isEmpty()) {
                    foreach (const Card *c, p->getCards("e")) {
                        if (c->sameColorWith(throw_card) && player->canDiscard(p, c->getEffectiveId())) {
                            enemies << p;
                            break;
                        }
                    }
                }
                hand += p->getHandcardNum();
            }
        }
        if (!enemies.isEmpty())
            choices << "discard";
        if (hand > 0)
            choices << "show";
        if (choices.isEmpty()) return false;
        QString choice = room->askForChoice(player, objectName(), choices.join("+"));

        if (choice == "discard") {
            bool optional = false;
            QString prompt = "@happycuorui_discard:" + throw_card->getColor();
            for (int i = 1; i < 3; i++) {
                if (enemies.isEmpty() || player->isDead()) break;
                if (i == 2) {
                    optional = true;
                    prompt = "@happycuorui_discard2:" + throw_card->getColor();
                }

                enemies.clear();
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (!player->isYourFriend(p)) {
                        if (!p->getEquips().isEmpty()) {
                            foreach (const Card *c, p->getCards("e")) {
                                if (c->sameColorWith(throw_card) && player->canDiscard(p, c->getEffectiveId())) {
                                    enemies << p;
                                }
                            }
                        }
                    }
                }
                if (enemies.isEmpty()) break;
                ServerPlayer *enemy = room->askForPlayerChosen(player, enemies, objectName(), prompt, optional);
                if (!enemy) break;
                room->doAnimate(1, player->objectName(), enemy->objectName());
                if (!player->canDiscard(enemy, "e")) continue;
                QList<int> disabled_ids;
                foreach (const Card *c, enemy->getCards("e")) {
                    if (!c->sameColorWith(throw_card) || !player->canDiscard(enemy, c->getEffectiveId()))
                        disabled_ids << c->getEffectiveId();
                }
                int id = room->askForCardChosen(player, enemy, "e", objectName(), false, Card::MethodDiscard, disabled_ids);
                if (id < 0) continue;
                room->throwCard(id, enemy, player);
            }
        } else {
            QList<int> list;
            for (int i = 1; i < 3; i++) {
                enemies.clear();
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (!player->isYourFriend(p) && !p->isKongcheng()) {
                        if (p->getHandcardNum() == 1 && list.contains(p->handCards().first())) continue;
                        enemies << p;
                    }
                }
                if (enemies.isEmpty()) break;
                ServerPlayer *enemy = room->askForPlayerChosen(player, enemies, objectName(), "@happycuorui_show");
                room->doAnimate(1, player->objectName(), enemy->objectName());
                if (enemy->isKongcheng()) continue;

                QList<int> hand;
                foreach (int id, enemy->handCards()) {
                    if (list.contains(id)) continue;
                    hand << id;
                }
                if (hand.isEmpty()) continue;

                int n = qrand() % hand.length();
                int id = hand.at(n);
                if (!list.contains(id)) {
                    list << id;
                    room->showCard(enemy, id);
                }
            }

            DummyCard *dummy = new DummyCard;
            foreach (int id, list) {
                if (Sanguosha->getCard(id)->sameColorWith(throw_card))
                    dummy->addSubcard(id);
            }
            if (dummy->subcardsLength() > 0)
                player->obtainCard(dummy, true);
            delete dummy;
        }
        return false;
    }
};

Happy2v2Package::Happy2v2Package()
    : Package("Happy2v2")
{
    General *leitong = new General(this, "leitong", "shu", 4);
    leitong->addSkill(new Kuiji);

    General *wulan = new General(this, "wulan", "shu", 4);
    wulan->addSkill(new HappyCuorui);


    addMetaObject<KuijiCard>();

    skills << new HappyRule;
}

ADD_PACKAGE(Happy2v2)
