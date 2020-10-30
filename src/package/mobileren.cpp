#include "mobileren.h"
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

MobileRenRenshiCard::MobileRenRenshiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool MobileRenRenshiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getMark("mobilerenrenshi-PlayClear") <= 0;
}

void MobileRenRenshiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.to, "mobilerenrenshi-PlayClear");
    room->giveCard(effect.from, effect.to, this, "mobilerenrenshi");
}

class MobileRenRenshi : public OneCardViewAsSkill
{
public:
    MobileRenRenshi() : OneCardViewAsSkill("mobilerenrenshi")
    {
        filter_pattern = ".|.|.|hand";
    }

    const Card *viewAs(const Card *card) const
    {
        MobileRenRenshiCard *c = new MobileRenRenshiCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }
};

MobileRenBuqiCard::MobileRenBuqiCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void MobileRenBuqiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, card_use.from->objectName(), "mobilerenbuqi", QString());
    room->throwCard(this, reason, NULL);
}

class MobileRenBuqiVS : public ViewAsSkill
{
public:
    MobileRenBuqiVS() : ViewAsSkill("mobilerenbuqi")
    {
        expand_pile = "mrhxren";
        response_pattern = "@@mobilerenbuqi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() < 2 && Self->getPile("mrhxren").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2)
            return NULL;

        MobileRenBuqiCard *card = new MobileRenBuqiCard;
        card->addSubcards(cards);
        return card;
    }
};

class MobileRenBuqi : public TriggerSkill
{
public:
    MobileRenBuqi() : TriggerSkill("mobilerenbuqi")
    {
        events << Dying << Death;
        frequency = Compulsory;
        view_as_skill = new MobileRenBuqiVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QList<int> rens = player->getPile("mrhxren");
        if (event == Dying) {
            if (rens.length() < 2) return false;
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who == player) return false;
            room->sendCompulsoryTriggerLog(player, this);

            DummyCard *dummy = new DummyCard;
            dummy->deleteLater();

            if (rens.length() == 2) {
                dummy->addSubcards(rens);
                CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, player->objectName(), "mobilerenbuqi", QString());
                room->throwCard(dummy, reason, NULL);
                room->recover(dying.who, RecoverStruct(player->isAlive() ? player : NULL));
            } else {
                if (room->askForUseCard(player, "@@mobilerenbuqi", "@mobilerenbuqi", -1, Card::MethodNone))
                    room->recover(dying.who, RecoverStruct(player->isAlive() ? player : NULL));
                else {
                    dummy->addSubcard(rens.first());
                    dummy->addSubcard(rens.last());
                    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, player->objectName(), "mobilerenbuqi", QString());
                    room->throwCard(dummy, reason, NULL);
                    room->recover(dying.who, RecoverStruct(player->isAlive() ? player : NULL));
                }
            }
        } else {
            if (rens.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            player->clearOnePrivatePile("mrhxren");
        }
        return false;
    }
};

class MobileRenDebao : public TriggerSkill
{
public:
    MobileRenDebao() : TriggerSkill("mobilerendebao")
    {
        events << CardsMoveOneTime << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && move.to && move.to != player && player->getPile("mrhxren").length() < player->getMaxHp() &&
                    (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))) {
                room->sendCompulsoryTriggerLog(player, this);
                player->addToPile("mrhxren", room->drawCard());
            }
        } else {
            if (player->getPhase() != Player::Start || player->getPile("mrhxren").isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            LogMessage log;
            log.type = "$KuangbiGet";
            log.from = player;
            log.arg = "mrhxren";
            log.card_str = IntList2StringList(player->getPile("mrhxren")).join("+");
            room->sendLog(log);
            DummyCard dummy(player->getPile("mrhxren"));
            room->obtainCard(player, &dummy, true);
        }
        return false;
    }
};

class MobileRenSheyi : public TriggerSkill
{
public:
    MobileRenSheyi() : TriggerSkill("mobilerensheyi")
    {
        events << DamageInflicted;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this) || p->getHp() <= player->getHp()) continue;
            int give_num = qMax(1, p->getHp());
            if (p->getCardCount() < give_num) continue;

            p->tag["mobilerensheyi_data"] = data;
            QString prompt = QString("@mobilerensheyi-give:%1:%2:%3").arg(player->objectName()).arg(give_num).arg(damage.damage);
            const Card *card = room->askForExchange(p, objectName(), 999, give_num, true, prompt, true);
            p->tag.remove("mobilerensheyi_data");
            if (!card) continue;

            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = p;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(p, objectName());
            room->broadcastSkillInvoke(this);

            room->giveCard(p, player, card, objectName());
            delete card;
            return true;
        }
        return false;
    }
};

class MobileRenTianyin : public PhaseChangeSkill
{
public:
    MobileRenTianyin() : PhaseChangeSkill("mobilerentianyin")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        QList<int> basics, tricks, equips;
        Room *room = player->getRoom();

        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (player->getMark("mobilerensheyi_" + card->getType() + "-Clear") > 0) continue;
            if (card->isKindOf("BasicCard"))
                basics << id;
            else if (card->isKindOf("TrickCard"))
                tricks << id;
            else if (card->isKindOf("EquipCard"))
                equips << id;
        }

        DummyCard *dummy = new DummyCard;
        dummy->deleteLater();
        if (!basics.isEmpty()) {
            int id = basics.at(qrand() % basics.length());
            dummy->addSubcard(id);
        }
        if (!tricks.isEmpty()) {
            int id = tricks.at(qrand() % tricks.length());
            dummy->addSubcard(id);
        }
        if (!equips.isEmpty()) {
            int id = equips.at(qrand() % equips.length());
            dummy->addSubcard(id);
        }
        if (dummy->subcardsLength() == 0) return false;
        room->sendCompulsoryTriggerLog(player, this);
        room->obtainCard(player, dummy, true);
        return false;
    }
};

MobileRenBomingCard::MobileRenBomingCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void MobileRenBomingCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->giveCard(effect.from, effect.to, this, "mobilerenboming");
}

class MobileRenBomingVS : public OneCardViewAsSkill
{
public:
    MobileRenBomingVS() : OneCardViewAsSkill("mobilerenboming")
    {
        filter_pattern = ".";
    }

    const Card *viewAs(const Card *card) const
    {
        MobileRenBomingCard *c = new MobileRenBomingCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("MobileRenBomingCard") < 2;
    }
};

class MobileRenBoming : public TriggerSkill
{
public:
    MobileRenBoming() : TriggerSkill("mobilerenboming")
    {
        events << PreCardUsed << EventPhaseEnd << EventPhaseStart;
        view_as_skill = new MobileRenBomingVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("MobileRenBomingCard") || player->getPhase() != Player::Play) return false;
            room->addPlayerMark(player, "mobilerenboming-PlayClear");
        } else if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play) return false;
            int mark = player->getMark("mobilerenboming-PlayClear");
            room->setPlayerMark(player, "mobilerenboming-PlayClear", 0);
            if (mark >= 2)
                room->addPlayerMark(player, "mobilerenboming-Clear");
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            int mark = player->getMark("mobilerenboming-Clear");
            for (int i = 0; i < mark; i++) {
                room->sendCompulsoryTriggerLog(player, this);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class MobileRenEjian : public TriggerSkill
{
public:
    MobileRenEjian() : TriggerSkill("mobilerenejian")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool hasSameType(ServerPlayer *player, const Card *card) const
    {
        foreach (const Card *c, player->getCards("he")) {
            if (c == card) continue;
            if (c->getType() == card->getType())
                return true;
        }
        return false;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.to || move.to->isDead() || move.to == player || move.reason.m_skillName != "mobilerenboming") return false;
        if (move.to_place != Player::PlaceHand) return false;

        ServerPlayer *to = (ServerPlayer *)move.to;
        foreach (int id, move.card_ids) {
            QStringList ejian_names = player->tag["mobilerenejian_names"].toStringList();
            if (ejian_names.contains(move.to->objectName())) return false;

            const Card *card = Sanguosha->getCard(id);
            if (!hasSameType(to, card)) continue;

            room->sendCompulsoryTriggerLog(player, this);
            ejian_names << move.to->objectName();
            player->tag["mobilerenejian_names"] = ejian_names;
            room->setPlayerMark(to, "&mobilerenejian", 1);

            QStringList choices;
            choices << "damage" << "discard=" + card->getType();
            if (room->askForChoice(to, objectName(), choices.join("+"), QVariant::fromValue(player)) == "damage")
                room->damage(DamageStruct("mobilerenejian", NULL, to));
            else {
                room->showAllCards(to);
                DummyCard *dummy = new DummyCard();
                dummy->deleteLater();
                foreach (const Card *c, to->getCards("he")) {
                    if (c->getType() == card->getType() && to->canDiscard(to, c->getEffectiveId()))
                        dummy->addSubcard(c);
                }
                if (dummy->subcardsLength() > 0)
                    room->throwCard(dummy, to);
            }
        }
        return false;
    }
};

class MobileRenGuying : public TriggerSkill
{
public:
    MobileRenGuying() : TriggerSkill("mobilerenguying")
    {
        events << CardsMoveOneTime << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            if (!room->hasCurrent(true)) return false;
            if (player->getMark("mobilerenguying-Clear") > 0 || player->getPhase() != Player::NotActive) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from != player || move.card_ids.length() != 1) return false;
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD ||
                move.reason.m_reason == CardMoveReason::S_REASON_USE ||
                move.reason.m_reason == CardMoveReason::S_REASON_LETUSE ||
                move.reason.m_reason == CardMoveReason::S_REASON_RESPONSE) {
                room->sendCompulsoryTriggerLog(player, this);
                room->addPlayerMark(player, "mobilerenguying-Clear");
                room->addPlayerMark(player, "&mobilerenguying");

                ServerPlayer *current = room->getCurrent();
                const Card *card = Sanguosha->getEngineCard(move.card_ids.first());

                QStringList choices;
                if (!current->isNude())
                    choices << "give=" + player->objectName();
                choices << "obtain=" + player->objectName() + "=" + card->objectName();
                if (room->askForChoice(current, objectName(), choices.join("+"), QVariant::fromValue(player)).startsWith("give")) {
                    if (player->isDead()) return false;
                    const Card *give = current->getCards("he").at(qrand() % current->getCardCount());
                    room->giveCard(current, player, give, objectName());
                } else {
                    if (player->isDead()) return false;
                    room->obtainCard(player, card, true);
                    const Card *obtain = Sanguosha->getCard(card->getEffectiveId());
                    if (obtain->isKindOf("EquipCard") && player->canUse(obtain))
                        room->useCard(CardUseStruct(obtain, player, player));
                }
            }
        } else {
            if (player->getPhase() != Player::Start || player->getMark("&mobilerenguying") <= 0) return false;
            int mark = player->getMark("&mobilerenguying");
            room->askForDiscard(player, objectName(), mark, mark, false, true);
            room->setPlayerMark(player, "&mobilerenguying", 0);
        }
        return false;
    }
};

MobileRenMuzhenCard::MobileRenMuzhenCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool MobileRenMuzhenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int num = subcardsLength();
    if (num == 1) {
        const Card *card = Sanguosha->getCard(getEffectiveId());
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        if (!equip) return false;
        int equip_index = static_cast<int>(equip->location());
        return to_select->getEquip(equip_index) == NULL && !Self->isProhibited(to_select, card) && targets.isEmpty() && to_select != Self;
    } else if (num == 2)
        return !to_select->getEquips().isEmpty() && targets.isEmpty() && to_select != Self;

    return false;
}

void MobileRenMuzhenCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    int num = subcardsLength();
    if (num == 1) {
        room->addPlayerMark(effect.from, "mobilerenmuzhen_put-PlayClear");

        LogMessage log;
        log.type = "$ZhijianEquip";
        log.from = effect.to;
        log.card_str = QString::number(getEffectiveId());
        room->sendLog(log);

        room->moveCardTo(this, effect.from, effect.to, Player::PlaceEquip,
            CardMoveReason(CardMoveReason::S_REASON_PUT, effect.from->objectName(), "mobilerenmuzhen", QString()));

        if (effect.from->isDead() || effect.to->isDead() || effect.to->isKongcheng()) return;
        int id = room->askForCardChosen(effect.from, effect.to, "h", "mobilerenmuzhen");
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
        room->obtainCard(effect.from, Sanguosha->getCard(id), reason, false);
    } else if (num == 2) {
        room->addPlayerMark(effect.from, "mobilerenmuzhen_give-PlayClear");

        room->giveCard(effect.from, effect.to, this, "mobilerenmuzhen");
        if (effect.from->isDead() || effect.to->isDead() || effect.to->getEquips().isEmpty()) return;
        int id = room->askForCardChosen(effect.from, effect.to, "e", "mobilerenmuzhen");
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
        room->obtainCard(effect.from, Sanguosha->getCard(id), reason, false);
    }
}

class MobileRenMuzhen : public ViewAsSkill
{
public:
    MobileRenMuzhen() : ViewAsSkill("mobilerenmuzhen")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.isEmpty()) return true;
        if (Self->getMark("mobilerenmuzhen_give-PlayClear") > 0)
            return selected.isEmpty() && to_select->isKindOf("EquipCard");
        else if (Self->getMark("mobilerenmuzhen_put-PlayClear") > 0)
            return selected.length() < 2;
        return selected.length() < 2;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        if (Self->getMark("mobilerenmuzhen_give-PlayClear") > 0 && cards.length() != 1) return NULL;
        if (Self->getMark("mobilerenmuzhen_put-PlayClear") > 0 && cards.length() != 2) return NULL;

        MobileRenMuzhenCard *c = new MobileRenMuzhenCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("mobilerenmuzhen_give-PlayClear") <= 0 || player->getMark("mobilerenmuzhen_put-PlayClear") <= 0;
    }
};

/*class MobileRenYaohuVS : public OneCardViewAsSkill
{
public:
    MobileRenYaohuVS() : OneCardViewAsSkill("mobilerenyaohu")
    {
        filter_pattern = ".|.|.|#mobilerenyaohu";
        expand_pile = "#mobilerenyaohu";
        response_pattern = "@@mobilerenyaohu!";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileRenYaohuCard *c = new MobileRenYaohuCard;
        c->addSubcard(originalCard);
        return c;
    }
};*/

class MobileRenYaohu : public PhaseChangeSkill
{
public:
    MobileRenYaohu() : PhaseChangeSkill("mobilerenyaohu")
    {
        //view_as_skill = new MobileRenYaohuVS;
    }

    static QString getYaohuKingdom(const Player *player)
    {
        QString kingdom;
        foreach (QString mark, player->getMarkNames()) {
            if (!mark.startsWith("&mobilerenyaohu+:+") || player->getMark(mark) <= 0) continue;
            QStringList marks = mark.split("+");
            if (marks.length() != 3) continue;
            kingdom = marks.last();
            break;
        }
        if (kingdom.isEmpty() || !Sanguosha->getKingdoms().contains(kingdom)) return QString();
        return kingdom;
    }

    static int getYaohuTargetsNum(const Player *player)
    {
        if (!player->hasSkill("mobilerenyaohu", true)) return -1;

        QString kingdom = getYaohuKingdom(player);
        if (kingdom.isEmpty()) return -1;

        int num = 0;
        QList<const Player *> players = player->getAliveSiblings();
        players << player;
        foreach (const Player *p, players) {
            if (p->getKingdom() != kingdom) continue;
            num++;
        }
        return num;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Play;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;

            QList<int> sheng = p->getPile("mrlzsheng");
            if (sheng.isEmpty()) continue;

            QString kingdom = player->getKingdom(), yaohu_kingdom = getYaohuKingdom(p);
            if (kingdom != yaohu_kingdom || yaohu_kingdom.isEmpty()) continue;
            room->sendCompulsoryTriggerLog(p, this);

            //room->notifyMoveToPile(player, sheng, objectName(), Player::PlaceSpecial, true);  //会闪退
            //const Card *card = room->askForUseCard(player, "@@mobilerenyaohu!" , "@mobilerenyaohu:" + p->objectName());
            //room->notifyMoveToPile(player, sheng, objectName(), Player::PlaceSpecial, false);
            /*int id = -1;
            if (card)
                id = card->getEffectiveId();
            else
                id = sheng.at(qrand() % sheng.length());
            if (id < 0) continue;*/

            room->fillAG(sheng, player);
            int id = room->askForAG(player, sheng, false, objectName());
            room->clearAG(player);
            room->obtainCard(player, id);

            QStringList choices;
            foreach (ServerPlayer *q, room->getOtherPlayers(player)) {
                if (p == q || !p->canSlash(q, true)) continue;
                choices << "slash=" + p->objectName();
                break;
            }
            choices << "damagecard=" + p->objectName();
            QString choice = room->askForChoice(player, objectName(), choices.join("+"));

            if (choice.startsWith("slash")) {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *q, room->getOtherPlayers(player)) {
                    if (p == q || !p->canSlash(q, true)) continue;
                    targets << q;
                }

                if (targets.isEmpty()) {
                    room->addPlayerMark(player, "mobilerenyaohu_" + p->objectName() + "-PlayClear");
                    continue;
                }

                ServerPlayer *t = room->askForPlayerChosen(p, targets, objectName(), "@mobilerenyaohu-slash:" + player->objectName());
                room->doAnimate(1, p->objectName(), t->objectName());
                if (room->askForUseSlashTo(player, t, "@mobilerenyaohu-use:" + t->objectName(), true, false, true)) continue;
                room->addPlayerMark(player, "mobilerenyaohu_" + p->objectName() + "-PlayClear");
            } else
                room->addPlayerMark(player, "mobilerenyaohu_" + p->objectName() + "-PlayClear");
        }
        return false;
    }
};

class MobileRenJutu : public PhaseChangeSkill
{
public:
    MobileRenJutu() : PhaseChangeSkill("mobilerenjutu")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();

        QList<int> sheng = player->getPile("mrlzsheng");
        bool send_log = true;
        if (!sheng.isEmpty()) {
            room->sendCompulsoryTriggerLog(player, this);
            send_log = false;

            LogMessage log;
            log.type = "$KuangbiGet";
            log.from = player;
            log.arg = "mrlzsheng";
            log.card_str = IntList2StringList(sheng).join("+");
            room->sendLog(log);
            DummyCard get(sheng);
            room->obtainCard(player, &get);
        }

        int num = MobileRenYaohu::getYaohuTargetsNum(player);
        if (num < 0) return false;

        if (send_log)
            room->sendCompulsoryTriggerLog(player, this);

        player->drawCards(num + 1, objectName());
        if (player->isAlive() && !player->isNude() && num > 0) {
            const Card *ex = room->askForExchange(player, objectName(), num, num, true, "@mobilerenjutu-put:" + QString::number(num));
            player->addToPile("mrlzsheng", ex);
            delete ex;
        }
        return false;
    }
};

/*MobileRenYaohuCard::MobileRenYaohuCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
    mute = true;
}

void MobileRenYaohuCard::onUse(Room *, const CardUseStruct &) const
{
}*/

class MobileRenYaohuChooseKingdom : public PhaseChangeSkill
{
public:
    MobileRenYaohuChooseKingdom() : PhaseChangeSkill("#mobilerenyaohu-choosekingdom")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark("mobilerenyaohu_lun") > 0) return false;
        Room *room = player->getRoom();

        QStringList kingdoms;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            QString kingdom = p->getKingdom();
            if (kingdoms.contains(kingdom)) continue;
            kingdoms << kingdom;
        }
        if (kingdoms.isEmpty()) return false;

        room->sendCompulsoryTriggerLog(player, "mobilerenyaohu", true, true);
        room->addPlayerMark(player, "mobilerenyaohu_lun");

        QString kingdom = room->askForChoice(player, "mobilerenyaohu_choose_kingdom", kingdoms.join("+"));
        LogMessage log;
        log.type = "#ChooseKingdom";
        log.from = player;
        log.arg = kingdom;
        room->sendLog(log);

        foreach (QString mark, player->getMarkNames()) {
            if (!mark.startsWith("&mobilerenyaohu+:+") || player->getMark(mark) <= 0) continue;
            room->setPlayerMark(player, mark, 0);
        }
        room->setPlayerMark(player, "&mobilerenyaohu+:+" + kingdom, 1);
        return false;
    }
};

class MobileRenYaohuDamageCard : public TriggerSkill
{
public:
    MobileRenYaohuDamageCard() : TriggerSkill("#mobilerenyaohu-damagecard")
    {
        events << TargetSpecifying;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || !use.card->isDamageCard() || use.card->isKindOf("DelayedTrick")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead()) return false;
            if (p->isDead()) continue;
            int mark = player->getMark("mobilerenyaohu_" + p->objectName() + "-PlayClear");
            for (int i = 0; i < mark; i++) {
                if (player->isDead()) return false;
                if (p->isDead()) break;
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = player;
                log.arg = "mobilerenyaohu";
                room->sendLog(log);
                room->notifySkillInvoked(p, "mobilerenyaohu");
                room->broadcastSkillInvoke("mobilerenyaohu");

                if (player->getCardCount() < 2) {
                    use.to.removeOne(p);
                    data = QVariant::fromValue(use);
                    //break;
                } else {
                    const Card *ex = room->askForExchange(player, "mobilerenyaohu", 2, 2, true, "@mobilerenyaohu-give:" + p->objectName(), true);
                    if (!ex) {
                        use.to.removeOne(p);
                        data = QVariant::fromValue(use);
                        //break;
                    } else {
                        room->giveCard(player, p, ex, "mobilerenyaohu");
                        delete ex;
                    }
                }
            }
        }
        return false;
    }
};

class MobileRenHuaibi : public MaxCardsSkill
{
public:
    MobileRenHuaibi() : MaxCardsSkill("mobilerenhuaibi$")
    {
    }

    int getExtra(const Player *target) const
    {
        if (!target->hasLordSkill(this)) return 0;
        int num = MobileRenYaohu::getYaohuTargetsNum(target);
        num = qMax(num, 0);
        return num;
    }
};

MobileRenPackage::MobileRenPackage()
    : Package("mobileren")
{
    General *mobileren_huaxin = new General(this, "mobileren_huaxin", "wei", 3);
    mobileren_huaxin->addSkill(new MobileRenRenshi);
    mobileren_huaxin->addSkill(new MobileRenBuqi);
    mobileren_huaxin->addSkill(new MobileRenDebao);

    General *mobileren_caizhenji = new General(this, "mobileren_caizhenji", "wei", 3, false);
    mobileren_caizhenji->addSkill(new MobileRenSheyi);
    mobileren_caizhenji->addSkill(new MobileRenTianyin);

    General *mobileren_xujing = new General(this, "mobileren_xujing", "shu", 3);
    mobileren_xujing->addSkill(new MobileRenBoming);
    mobileren_xujing->addSkill(new MobileRenEjian);

    General *mobileren_xiangchong = new General(this, "mobileren_xiangchong", "shu", 4);
    mobileren_xiangchong->addSkill(new MobileRenGuying);
    mobileren_xiangchong->addSkill(new MobileRenMuzhen);

    General *mobileren_liuzhang = new General(this, "mobileren_liuzhang$", "qun", 3);
    mobileren_liuzhang->addSkill(new MobileRenJutu);
    mobileren_liuzhang->addSkill(new MobileRenYaohu);
    mobileren_liuzhang->addSkill(new MobileRenYaohuChooseKingdom);
    mobileren_liuzhang->addSkill(new MobileRenYaohuDamageCard);
    mobileren_liuzhang->addSkill(new MobileRenHuaibi);
    related_skills.insertMulti("mobilerenyaohu", "#mobilerenyaohu-choosekingdom");
    related_skills.insertMulti("mobilerenyaohu", "#mobilerenyaohu-damagecard");

    addMetaObject<MobileRenRenshiCard>();
    addMetaObject<MobileRenBuqiCard>();
    addMetaObject<MobileRenBomingCard>();
    addMetaObject<MobileRenMuzhenCard>();
    //addMetaObject<MobileRenYaohuCard>();
}

ADD_PACKAGE(MobileRen)
