#include "yingbian.h"
#include "standard.h"
#include "standard-equips.h"
#include "maneuvering.h"
#include "general.h"
#include "engine.h"
#include "client.h"
#include "room.h"
#include "ai.h"
#include "settings.h"
#include "clientplayer.h"
#include "clientstruct.h"
#include "util.h"
#include "wrapped-card.h"
#include "roomthread.h"
#include "wind.h"
#include "special1v1.h"

IceSlash::IceSlash(Suit suit, int number)
    : NatureSlash(suit, number, DamageStruct::Fire)
{
    setObjectName("ice_slash");
    nature = DamageStruct::Ice;
    damage_card = true;
    single_target = true;
}

Chuqibuyi::Chuqibuyi(Card::Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("chuqibuyi");
    damage_card = true;
}

bool Chuqibuyi::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    return targets.length() < total_num && !to_select->isKongcheng() && (to_select != Self || !Self->isLastHandCard(this, true));
}

void Chuqibuyi::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isKongcheng()) return;
    Room *room = effect.from->getRoom();

    int hand_id = effect.to->getRandomHandCardId();
    room->showCard(effect.to, hand_id);

    if (Sanguosha->getCard(hand_id)->getSuit() != getSuit())
        room->damage(DamageStruct(this, effect.from, effect.to));
}

Dongzhuxianji::Dongzhuxianji(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("dongzhuxianji");
    target_fixed = true;
}

void Dongzhuxianji::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    SingleTargetTrick::onUse(room, use);
}

bool Dongzhuxianji::isAvailable(const Player *player) const
{
    return !player->isProhibited(player, this) && TrickCard::isAvailable(player);
}

void Dongzhuxianji::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    QList<int> ids = room->getNCards(2, false);
    room->askForGuanxing(effect.to, ids, Room::GuanxingBothSides);
    effect.to->drawCards(2, "dongzhuxianji");
}

Zhujinqiyuan::Zhujinqiyuan(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("zhujinqiyuan");
}

bool Zhujinqiyuan::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    if (targets.length() < total_num && to_select != Self && !to_select->isAllNude()) {
        int distance = Self->distanceTo(to_select);
        if (distance <= 1)
            return true;
        else if (distance > 1)
            return Self->canDiscard(to_select, "hej");
    }
    return false;
}

void Zhujinqiyuan::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isAllNude()) return;
    Room *room = effect.from->getRoom();

    if (hasFlag("yb_zhuzhan1_buff")) {
        if (effect.from->canDiscard(effect.to, "hje")) {
            int id2 = room->askForCardChosen(effect.from, effect.to, "hej", "zhujinqiyuan", false, Card::MethodDiscard);
            room->throwCard(id2, room->getCardPlace(id2) == Player::PlaceDelayedTrick ? NULL : effect.to, effect.from);
        }
        if (effect.from->isAlive() && effect.to->isAlive() && !effect.to->isAllNude()) {
            int id1 = room->askForCardChosen(effect.from, effect.to, "hej", "zhujinqiyuan");
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
            room->obtainCard(effect.from, Sanguosha->getCard(id1), reason, room->getCardPlace(id1) != Player::PlaceHand);
        }
    } else {
        int distance = effect.from->distanceTo(effect.to);
        if (distance < 1) return;

        Card::HandlingMethod method = Card::MethodDiscard;
        if (distance == 1)
            method = Card::MethodNone;
        if (method == Card::MethodDiscard && !effect.from->canDiscard(effect.to, "hje")) return;

        int id = room->askForCardChosen(effect.from, effect.to, "hej", "zhujinqiyuan", false, method);

        if (method == Card::MethodDiscard)
            room->throwCard(id, room->getCardPlace(id) == Player::PlaceDelayedTrick ? NULL : effect.to, effect.from);
        else {
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
            room->obtainCard(effect.from, Sanguosha->getCard(id), reason, room->getCardPlace(id) != Player::PlaceHand);
        }
    }
}

class WuxinghelingshanVSSkill : public OneCardViewAsSkill
{
public:
    WuxinghelingshanVSSkill() : OneCardViewAsSkill("wuxinghelingshan")
    {
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        const Card *card = Self->tag.value("wuxinghelingshan").value<const Card *>();
        return to_select->objectName() != card->objectName() && to_select->isKindOf("NatureSlash");
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return NatureSlash::IsAvailable(player) && player->getMark("Equips_Nullified_to_Yourself") == 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE
            && (pattern.contains("slash") || pattern.contains("Slash")) && player->getMark("Equips_Nullified_to_Yourself") == 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        const Card *card = Self->tag.value("wuxinghelingshan").value<const Card *>();
        Card *slash = Sanguosha->cloneCard(card->objectName(), originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard);
        slash->setSkillName(objectName());
        return slash;
    }
};

class WuxinghelingshanSkill : public WeaponSkill
{
public:
    WuxinghelingshanSkill() : WeaponSkill("wuxinghelingshan")
    {
        events << ChangeSlash;
        view_as_skill = new WuxinghelingshanVSSkill;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("wuxinghelingshan", true, false);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("NatureSlash")) return false;
        QList<const NatureSlash *> slashs = Sanguosha->findChildren<const NatureSlash *>();
        QStringList choices;

        foreach (const NatureSlash *slash, slashs) {
            QString name = slash->objectName();
            if (name.startsWith("_") || name == use.card->objectName()) continue;
            if (!ServerInfo.Extensions.contains("!" + slash->getPackage()) && !choices.contains(slash->objectName())) {
                bool can_use = true;

                Card *card = Sanguosha->cloneCard(name, Card::SuitToBeDecided, 0);
                if (use.card->isVirtualCard() && use.card->subcardsLength() > 0)
                    card->addSubcards(use.card->getSubcards());
                else if (!use.card->isVirtualCard())
                    card->addSubcard(use.card);
                card->setSkillName(objectName());
                card->deleteLater();

                foreach (ServerPlayer *p, use.to) {
                    if (!player->canSlash(p, card, false)) {
                        can_use = false;
                        break;
                    }
                }
                if (can_use)
                    choices << name;
            }
        }

        if (choices.isEmpty() || !player->askForSkillInvoke(this, data, false)) return false;
        QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);

        room->setEmotion(player, "weapon/wuxinghelingshan");
        Card *card = Sanguosha->cloneCard(choice, Card::SuitToBeDecided, 0);
        if (use.card->isVirtualCard() && use.card->subcardsLength() > 0)
            card->addSubcards(use.card->getSubcards());
        else if (!use.card->isVirtualCard())
            card->addSubcard(use.card);
        card->setSkillName(objectName());
        card->deleteLater();

        use.card = card;
        data = QVariant::fromValue(use);

        return false;
    }
};

Wuxinghelingshan::Wuxinghelingshan(Suit suit, int number)
    : Weapon(suit, number, 4)
{
    setObjectName("wuxinghelingshan");
}

class WutiesuolianSkill : public WeaponSkill
{
public:
    WutiesuolianSkill() : WeaponSkill("wutiesuolian")
    {
        events << TargetSpecified;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || use.to.isEmpty()) return false;

        room->sendCompulsoryTriggerLog(player, objectName(), true);
        room->setEmotion(player, "weapon/wutiesuolian");

        foreach (ServerPlayer *p, use.to) {
            if (player->isDead() || !player->hasWeapon(objectName())) return false;
            if (p->isDead()) continue;
            if (p->isChained()) {
                LogMessage log;
                log.type = "#ViewAllCards";
                log.from = player;
                log.to << p;
                room->sendLog(log, room->getOtherPlayers(player, true));
                room->showAllCards(p, player);
            } else
                room->setPlayerChained(p);
        }
        return false;
    }
};

Wutiesuolian::Wutiesuolian(Suit suit, int number)
    : Weapon(suit, number, 3)
{
    setObjectName("wutiesuolian");
}

class HeiguangkaiSkill : public ArmorSkill
{
public:
    HeiguangkaiSkill() : ArmorSkill("heiguangkai")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.contains(player) && use.to.length() > 1) {
            if (use.card->isKindOf("Slash") || use.card->isNDTrick()) {
                LogMessage log;
                log.type = "#ArmorNullify";
                log.from = player;
                log.arg = objectName();
                log.arg2 = use.card->objectName();
                room->sendLog(log);

                room->setEmotion(player, "armor/heiguangkai");

                use.nullified_list << player->objectName();

                data = QVariant::fromValue(use);
            }
        }
        return false;
    }
};

Heiguangkai::Heiguangkai(Suit suit, int number)
    : Armor(suit, number)
{
    setObjectName("heiguangkai");
}

class HuxinjingSkill : public ArmorSkill
{
public:
    HuxinjingSkill() : ArmorSkill("huxinjing")
    {
        events << DamageInflicted;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return ArmorSkill::triggerable(target) && target->getArmor() && target->getArmor()->objectName() == objectName();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.damage >= player->getHp()) {
            if (!player->askForSkillInvoke(this)) return false;
            room->setEmotion(player, "armor/huxinjing");
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "huxinjing", QString());
            room->throwCard(player->getArmor(), reason, NULL);
            return true;
        }
        return false;
    }
};

Huxinjing::Huxinjing(Suit suit, int number)
    : Armor(suit, number)
{
    setObjectName("huxinjing");
}


class TaigongyinfuSkill : public TreasureSkill
{
public:
    TaigongyinfuSkill() : TreasureSkill("taigongyinfu")
    {
        events << EventPhaseStart << EventPhaseEnd;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (event == EventPhaseStart) {
            QList<ServerPlayer *> players;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isChained()) continue;
                players << p;
            }
            if (players.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@taigongyinfu-chain", true, true);
            if (!target) return false;
            room->setEmotion(player, "treasure/taigongyinfu");
            if (target->isChained()) return false;
            room->setPlayerChained(target);
        } else {
            if (player->isKongcheng()) return false;
            const Card *card = room->askForCard(player, ".|.|.|hand", "@taigongyinfu-recast", data, Card::MethodRecast);
            if (!card) return false;
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->setEmotion(player, "treasure/taigongyinfu");

            log.type = "#UseCard_Recast";
            log.card_str = card->toString();
            room->sendLog(log);

            CardMoveReason reason(CardMoveReason::S_REASON_RECAST, player->objectName());
            reason.m_skillName = objectName();
            CardsMoveStruct move(card->getEffectiveId(), NULL, Player::DiscardPile, reason);
            room->moveCardsAtomic(move, true);

            player->broadcastSkillInvoke("@recast");
            player->drawCards(1, "recast");
        }
        return false;
    }
};

Taigongyinfu::Taigongyinfu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("taigongyinfu");
}

class TianjituSkill : public TreasureSkill
{
public:
    TianjituSkill() : TreasureSkill("tianjitu")
    {
        events << CardsMoveOneTime;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (player->hasFlag("TianjituDiscard")) {
            if (move.to == player && move.to_place == Player::PlaceEquip) {
                for (int i = 0; i < move.card_ids.size(); i++) {
                    const Card *card = Sanguosha->getEngineCard(move.card_ids[i]);
                    if (card->objectName() == objectName()) {
                        player->setFlags("-TianjituDiscard");
                        room->setEmotion(player, "treasure/tianjitu");

                        bool discard = false;
                        foreach (const Card *card, player->getCards("he")) {
                            if (card->objectName() == objectName()) continue;
                            int id = card->getEffectiveId();
                            if (!player->canDiscard(player, id)) continue;
                            discard = true;
                        }
                        if (discard)
                            room->askForDiscard(player, objectName(), 1, 1, false, true, QString(), "^Tianjitu");
                    }
                }
            }
        }
        if (player->hasFlag("TianjituDraw")) {
            if (move.from != player || !move.from_places.contains(Player::PlaceEquip)) return false;
            for (int i = 0; i < move.card_ids.size(); i++) {
                if (move.from_places[i] != Player::PlaceEquip) continue;
                const Card *card = Sanguosha->getEngineCard(move.card_ids[i]);
                if (card->objectName() == objectName()) {
                    player->setFlags("-TianjituDraw");
                    room->setEmotion(player, "treasure/tianjitu");
                    player->drawCards(5 - player->getHandcardNum(), objectName());
                }
            }
        }
        return false;
    }
};

Tianjitu::Tianjitu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("tianjitu");
}

void Tianjitu::onInstall(ServerPlayer *player) const
{
    if (player->isAlive() && player->hasTreasure(objectName()))
        player->setFlags("TianjituDiscard");
    Treasure::onInstall(player);
}

void Tianjitu::onUninstall(ServerPlayer *player) const
{
    if (player->isAlive() && player->hasTreasure(objectName(), false))
        player->setFlags("TianjituDraw");
    Treasure::onUninstall(player);
}

Tongque::Tongque(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("tongque");
}

void Tongque::onInstall(ServerPlayer *player) const
{
    if (player->isAlive() && player->hasTreasure(objectName()))
        player->getRoom()->addPlayerMark(player, "YingBianDirectlyEffective");
    Treasure::onInstall(player);
}

void Tongque::onUninstall(ServerPlayer *player) const
{
    player->getRoom()->removePlayerMark(player, "YingBianDirectlyEffective");
    Treasure::onUninstall(player);
}

Suijiyingbian::Suijiyingbian(Suit suit, int number)
    : TrickCard(suit, number)
{
    target_fixed = true;
    setObjectName("suijiyingbian");
}

QString Suijiyingbian::getSubtype() const
{
    return "suijiyingbian";
}

bool Suijiyingbian::isAvailable(const Player *) const
{
   return false;
}

class SuijiyingbianSkill : public TriggerSkill
{
public:
    SuijiyingbianSkill() : TriggerSkill("suijiyingbian")
    {
        events << PreCardUsed << PreCardResponded << EventPhaseChanging << CardsMoveOneTime;
        global = true;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseChanging)
            return 0;
        return 6;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive) return false;

        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            player->tag.remove("SuijiyingbianFilter");
            QList<const Card *> suijiyingbians;
            foreach (const Card *c, player->getCards("h")) {
                int id = c->getEffectiveId();
                const Card *e_card = Sanguosha->getEngineCard(id);
                if (e_card->isKindOf("Suijiyingbian"))
                    suijiyingbians << c;
            }
            if (!suijiyingbians.isEmpty())
                room->filterCards(player, suijiyingbians, true);
        } else if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to && move.to == player && move.to_place == Player::PlaceHand) {
                QString name = player->tag["SuijiyingbianFilter"].toString();
                if (name.isEmpty()) return false;
                foreach (int id, move.card_ids) {
                    if (room->getCardOwner(id) != player || room->getCardPlace(id) != Player::PlaceHand) continue;
                    const Card *c = Sanguosha->getCard(id);
                    if (c->isKindOf("Suijiyingbian")) {
                        Card *suijiyingbian = Sanguosha->cloneCard(name, c->getSuit(), c->getNumber());
                        if (!suijiyingbian) return false;
                        suijiyingbian->setSkillName(objectName());
                        WrappedCard *ccc = Sanguosha->getWrappedCard(id);
                        ccc->takeOver(suijiyingbian);
                        room->notifyUpdateCard(player, id, ccc);
                    }
                }
            }
        } else {
            const Card *card = NULL;
            if (event == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else
                card = data.value<CardResponseStruct>().m_card;
            if (card && card->getSkillName() != objectName() && (card->isKindOf("BasicCard") || card->isNDTrick())) {
                player->tag["SuijiyingbianFilter"] = card->objectName();
                foreach (int id, player->handCards()) {
                    const Card *c = Sanguosha->getCard(id);
                    if (c->isKindOf("Suijiyingbian") || c->getSkillName() == objectName()) {
                        Card *suijiyingbian = Sanguosha->cloneCard(card->objectName(), c->getSuit(), c->getNumber());
                        if (!suijiyingbian) return false;
                        suijiyingbian->setSkillName(objectName());
                        WrappedCard *ccc = Sanguosha->getWrappedCard(id);
                        ccc->takeOver(suijiyingbian);
                        room->notifyUpdateCard(player, id, ccc);
                    }
                }
            }
        }
        return false;
    }
};

YingbianPackage::YingbianPackage()
    : Package("yingbian_cards", Package::CardPack)
{
    QList<Card *> cards;

    Card *slash1 = new Slash(Card::Spade, 9);
    slash1->setProperty("YingBianEffects", "yb_canqu2");
    Card *slash2 = new Slash(Card::Spade, 9);
    slash2->setProperty("YingBianEffects", "yb_canqu2");
    Card *slash3 = new Slash(Card::Spade, 10);
    slash3->setProperty("YingBianEffects", "yb_canqu2");
    Card *slash4 = new Slash(Card::Spade, 10);
    slash4->setProperty("YingBianEffects", "yb_canqu2");
    Card *slash5 = new Slash(Card::Club, 11);
    slash5->setProperty("YingBianEffects", "yb_canqu2");
    Card *slash6 = new Slash(Card::Diamond, 8);
    slash6->setProperty("YingBianEffects", "yb_canqu2");
    Card *slash7 = new Slash(Card::Club, 2);
    slash7->setProperty("YingBianEffects", "yb_kongchao3");
    Card *slash8 = new Slash(Card::Club, 3);
    slash8->setProperty("YingBianEffects", "yb_kongchao3");
    Card *slash9 = new Slash(Card::Club, 4);
    slash9->setProperty("YingBianEffects", "yb_kongchao3");
    Card *slash10 = new Slash(Card::Club, 5);
    slash10->setProperty("YingBianEffects", "yb_kongchao3");

    cards << slash1//yb_canqu2
          << slash2//yb_canqu2
          << slash3//yb_canqu2
          << slash4//yb_canqu2
          << slash7//yb_kongchao3
          << slash8//yb_kongchao3
          << slash9//yb_kongchao3
          << slash10//yb_kongchao3
          << new Slash(Card::Club, 6)
          << new Slash(Card::Club, 7)
          << new Slash(Card::Club, 8)
          << new Slash(Card::Club, 8)
          << new Slash(Card::Club, 11)
          << slash5//yb_canqu2
          << new Slash(Card::Heart, 10)
          << new Slash(Card::Heart, 10)
          << new Slash(Card::Heart, 11)
          << new Slash(Card::Diamond, 6)
          << new Slash(Card::Diamond, 7)
          << slash6//yb_canqu2
          << new Slash(Card::Diamond, 9)
          << new Slash(Card::Diamond, 13)

          << new IceSlash(Card::Spade, 7)
          << new IceSlash(Card::Spade, 7)
          << new IceSlash(Card::Spade, 8)
          << new IceSlash(Card::Spade, 8)
          << new IceSlash(Card::Spade, 8)

          << new ThunderSlash(Card::Spade, 4)
          << new ThunderSlash(Card::Spade, 5)
          << new ThunderSlash(Card::Spade, 6)
          << new ThunderSlash(Card::Club, 5)
          << new ThunderSlash(Card::Club, 6)
          << new ThunderSlash(Card::Club, 7)
          << new ThunderSlash(Card::Club, 8)
          << new ThunderSlash(Card::Club, 9)
          << new ThunderSlash(Card::Club, 9)
          << new ThunderSlash(Card::Club, 10)
          << new ThunderSlash(Card::Club, 10);

    Card *fire_slash1 = new FireSlash(Card::Heart, 10);
    fire_slash1->setProperty("YingBianEffects", "yb_canqu1");
    Card *fire_slash2 = new FireSlash(Card::Diamond, 4);
    fire_slash2->setProperty("YingBianEffects", "yb_canqu1");

    cards << new FireSlash(Card::Heart, 4)
          << new FireSlash(Card::Heart, 7)
          << fire_slash1//yb_canqu1
          << fire_slash2//yb_canqu1
          << new FireSlash(Card::Diamond, 5)
          << new FireSlash(Card::Diamond, 10);

    Card *jink1 = new Jink(Card::Heart, 2);
    jink1->setProperty("YingBianEffects", "yb_kongchao1");
    Card *jink2 = new Jink(Card::Heart, 2);
    jink2->setProperty("YingBianEffects", "yb_kongchao1");
    Card *jink3 = new Jink(Card::Diamond, 2);
    jink3->setProperty("YingBianEffects", "yb_kongchao1");
    Card *jink4 = new Jink(Card::Diamond, 2);
    jink4->setProperty("YingBianEffects", "yb_kongchao1");

    cards << jink1//yb_kongchao1
          << jink2//yb_kongchao1
          << new Jink(Card::Heart, 8)
          << new Jink(Card::Heart, 9)
          << new Jink(Card::Heart, 11)
          << new Jink(Card::Heart, 12)
          << new Jink(Card::Heart, 13)
          << jink3//yb_kongchao1
          << jink4//yb_kongchao1
          << new Jink(Card::Diamond, 3)
          << new Jink(Card::Diamond, 4)
          << new Jink(Card::Diamond, 5)
          << new Jink(Card::Diamond, 6)
          << new Jink(Card::Diamond, 6)
          << new Jink(Card::Diamond, 7)
          << new Jink(Card::Diamond, 7)
          << new Jink(Card::Diamond, 8)
          << new Jink(Card::Diamond, 8)
          << new Jink(Card::Diamond, 9)
          << new Jink(Card::Diamond, 10)
          << new Jink(Card::Diamond, 10)
          << new Jink(Card::Diamond, 11)
          << new Jink(Card::Diamond, 11)
          << new Jink(Card::Diamond, 11)

          << new Peach(Card::Heart, 3)
          << new Peach(Card::Heart, 4)
          << new Peach(Card::Heart, 5)
          << new Peach(Card::Heart, 6)
          << new Peach(Card::Heart, 6)
          << new Peach(Card::Heart, 7)
          << new Peach(Card::Heart, 8)
          << new Peach(Card::Heart, 9)
          << new Peach(Card::Heart, 12)
          << new Peach(Card::Diamond, 2)
          << new Peach(Card::Diamond, 3)
          << new Peach(Card::Diamond, 12)

          << new Analeptic(Card::Spade, 3)
          << new Analeptic(Card::Spade, 9)
          << new Analeptic(Card::Club, 3)
          << new Analeptic(Card::Club, 9)
          << new Analeptic(Card::Diamond, 9);

    Card *sa1 = new SavageAssault(Card::Spade, 7);
    sa1->setProperty("YingBianEffects", "yb_fujia2");
    Card *sa2 = new SavageAssault(Card::Spade, 13);
    sa2->setProperty("YingBianEffects", "yb_fujia2");

    cards << new ArcheryAttack(Card::Heart, 1)
          << sa1//yb_fujia2
          << sa2//yb_fujia2
          << new SavageAssault(Card::Club, 7);

    cards << new GodSalvation(Card::Heart, 1)
          << new AmazingGrace(Card::Heart, 3)
          << new AmazingGrace(Card::Heart, 4);

    Card *duel1 = new Duel(Card::Spade, 1);
    duel1->setProperty("YingBianEffects", "yb_fujia1");
    Card *duel2 = new Duel(Card::Club, 1);
    duel2->setProperty("YingBianEffects", "yb_fujia1");
    Card *zhu1 = new Zhujinqiyuan(Card::Spade, 12);
    zhu1->setProperty("YingBianEffects", "yb_zhuzhan1");
    Card *zhu2 = new Zhujinqiyuan(Card::Club, 3);
    zhu2->setProperty("YingBianEffects", "yb_zhuzhan1");
    Card *zhu3 = new Zhujinqiyuan(Card::Club, 4);
    zhu3->setProperty("YingBianEffects", "yb_zhuzhan1");
    Card *drowning1 = new Drowning(Card::Spade, 3);
    drowning1->setProperty("YingBianEffects", "yb_zhuzhan1");
    Card *drowning2 = new Drowning(Card::Spade, 4);
    drowning2->setProperty("YingBianEffects", "yb_zhuzhan1");
    Card *null1 = new Nullification(Card::Spade, 13);
    null1->setProperty("YingBianEffects", "yb_kongchao1");
    Card *null2 = new Nullification(Card::Heart, 13);
    null2->setProperty("YingBianEffects", "yb_kongchao2");
    Card *chu = new Chuqibuyi(Card::Heart, 3);
    chu->setProperty("YingBianEffects", "yb_zhuzhan2");

    cards << duel1//yb_fujia1
          << duel2//yb_fujia1
          << new Duel(Card::Diamond, 1)
          << new Zhujinqiyuan(Card::Spade, 3)
          << zhu1//yb_zhuzhan1
          << zhu2//yb_zhuzhan1
          << zhu3//yb_zhuzhan1
          << drowning1//yb_zhuzhan1
          << drowning2//yb_zhuzhan1
          << new Dismantlement(Card::Spade, 4)
          << new Dismantlement(Card::Heart, 2)
          << new Dismantlement(Card::Heart, 12)
          << new Snatch(Card::Spade, 11)
          << new Snatch(Card::Diamond, 3)
          << new Snatch(Card::Diamond, 4)
          << new IronChain(Card::Spade, 11)
          << new IronChain(Card::Spade, 12)
          << new IronChain(Card::Club, 10)
          << new IronChain(Card::Club, 11)
          << new IronChain(Card::Club, 12)
          << new IronChain(Card::Club, 13)
          << new Nullification(Card::Spade, 11)
          << null1//yb_kongchao1
          << new Nullification(Card::Club, 12)
          << new Nullification(Card::Club, 13)
          << new Nullification(Card::Heart, 1)
          << null2//yb_kongchao2
          << new Nullification(Card::Diamond, 13)
          << chu//yb_zhuzhan2
          << new Chuqibuyi(Card::Diamond, 12)
          << new Dongzhuxianji(Card::Heart, 7)
          << new Dongzhuxianji(Card::Heart, 8)
          << new Dongzhuxianji(Card::Heart, 9)
          << new Dongzhuxianji(Card::Heart, 11)
          << new Suijiyingbian(Card::Spade, 2);

    cards << new Indulgence(Card::Spade, 6)
          << new Indulgence(Card::Club, 6)
          << new Indulgence(Card::Heart, 6)
          << new SupplyShortage(Card::Spade, 10)
          << new SupplyShortage(Card::Club, 4)
          << new Lightning(Card::Heart, 12);

    cards << new GudingBlade(Card::Spade, 1)
          << new DoubleSword(Card::Spade, 2)
          << new Blade(Card::Spade, 5)
          << new QinggangSword(Card::Spade, 6)
          << new Spear(Card::Spade, 12)
          << new Crossbow(Card::Club, 1)
          << new KylinBow(Card::Heart, 5)
          << new Crossbow(Card::Diamond, 1)
          << new Wuxinghelingshan(Card::Diamond, 1)
          << new Axe(Card::Diamond, 5)
          << new Wutiesuolian(Card::Diamond, 12);

    cards << new EightDiagram(Card::Spade, 2)
          << new Vine(Card::Spade, 2)
          << new Vine(Card::Club, 2)
          << new RenwangShield(Card::Club, 2)
          << new Heiguangkai(Card::Club, 2)
          << new Huxinjing(Card::Club, 1);

    QList<Card *> horses;
    horses << new DefensiveHorse(Card::Spade, 5)
           << new DefensiveHorse(Card::Club, 5)
           << new DefensiveHorse(Card::Heart, 13)
           << new DefensiveHorse(Card::Diamond, 13)
           << new OffensiveHorse(Card::Spade, 13)
           << new OffensiveHorse(Card::Heart, 5)
           << new OffensiveHorse(Card::Diamond, 13);

    horses.at(0)->setObjectName("jueying");
    horses.at(1)->setObjectName("dilu");
    horses.at(2)->setObjectName("zhuahuangfeidian");
    horses.at(3)->setObjectName("hualiu");
    horses.at(4)->setObjectName("dayuan");
    horses.at(5)->setObjectName("chitu");
    horses.at(6)->setObjectName("zixing");

    cards << horses;

    cards << new Taigongyinfu(Card::Spade, 1)
          << new Tianjitu(Card::Club, 12)
          << new Tongque(Card::Club, 13)
          << new WoodenOx(Card::Diamond, 5);

    foreach(Card *card, cards)
        card->setParent(this);

    skills << new WuxinghelingshanSkill << new WutiesuolianSkill << new HeiguangkaiSkill << new HuxinjingSkill << new TaigongyinfuSkill
           << new TianjituSkill << new SuijiyingbianSkill;
}

ADD_PACKAGE(Yingbian)
