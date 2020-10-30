#include "sp1.h"
#include "client.h"
#include "general.h"
#include "skill.h"
#include "standard-skillcards.h"
#include "engine.h"
#include "maneuvering.h"
#include "json.h"
#include "settings.h"
#include "clientplayer.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "yjcm2013.h"
#include "wind.h"

GusheCard::GusheCard(QString skill_name) : skill_name(skill_name)
{
}

bool GusheCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < 3 && Self->canPindian(to_select);
}

int GusheCard::pindian(ServerPlayer *from, ServerPlayer *target, const Card *card1, const Card *card2) const
{
    if (card1 == NULL || card2 == NULL || !from->canPindian(target, false)) return -2;

    Room *room = from->getRoom();

    PindianStruct *pindian_struct = new PindianStruct;
    pindian_struct->from = from;
    pindian_struct->to = target;
    pindian_struct->from_card = card1;
    pindian_struct->to_card = card2;
    pindian_struct->from_number = card1->getNumber();
    pindian_struct->to_number = card2->getNumber();
    pindian_struct->reason = skill_name;
    QVariant data = QVariant::fromValue(pindian_struct);

    QList<CardsMoveStruct> moves;
    CardsMoveStruct move_table_1;
    move_table_1.card_ids << pindian_struct->from_card->getEffectiveId();
    move_table_1.from = pindian_struct->from;
    move_table_1.to = NULL;
    move_table_1.to_place = Player::PlaceTable;
    move_table_1.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->from->objectName(),
        pindian_struct->to->objectName(), pindian_struct->reason, QString());

    CardsMoveStruct move_table_2;
    move_table_2.card_ids << pindian_struct->to_card->getEffectiveId();
    move_table_2.from = pindian_struct->to;
    move_table_2.to = NULL;
    move_table_2.to_place = Player::PlaceTable;
    move_table_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());

    moves.append(move_table_1);
    moves.append(move_table_2);
    room->moveCardsAtomic(moves, true);

    LogMessage log;
    log.type = "$PindianResult";
    log.from = pindian_struct->from;
    log.card_str = QString::number(pindian_struct->from_card->getEffectiveId());
    room->sendLog(log);

    log.type = "$PindianResult";
    log.from = pindian_struct->to;
    log.card_str = QString::number(pindian_struct->to_card->getEffectiveId());
    room->sendLog(log);

    RoomThread *thread = room->getThread();
    thread->trigger(PindianVerifying, room, from, data);

    pindian_struct->success = pindian_struct->from_number > pindian_struct->to_number;

    log.type = pindian_struct->success ? "#PindianSuccess" : "#PindianFailure";
    log.from = from;
    log.to.clear();
    log.to << target;
    log.card_str.clear();
    room->sendLog(log);

    JsonArray arg;
    arg << QSanProtocol::S_GAME_EVENT_REVEAL_PINDIAN << objectName() << pindian_struct->from_card->getEffectiveId() << target->objectName()
        << pindian_struct->to_card->getEffectiveId() << pindian_struct->success << skill_name;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);

    thread->trigger(Pindian, room, from, data);

    moves.clear();
    if (room->getCardPlace(pindian_struct->from_card->getEffectiveId()) == Player::PlaceTable) {
        CardsMoveStruct move_discard_1;
        move_discard_1.card_ids << pindian_struct->from_card->getEffectiveId();
        move_discard_1.from = pindian_struct->from;
        move_discard_1.to = NULL;
        move_discard_1.to_place = Player::DiscardPile;
        move_discard_1.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->from->objectName(),
            pindian_struct->to->objectName(), pindian_struct->reason, QString());
        moves.append(move_discard_1);
    }

    if (room->getCardPlace(pindian_struct->to_card->getEffectiveId()) == Player::PlaceTable) {
        CardsMoveStruct move_discard_2;
        move_discard_2.card_ids << pindian_struct->to_card->getEffectiveId();
        move_discard_2.from = pindian_struct->to;
        move_discard_2.to = NULL;
        move_discard_2.to_place = Player::DiscardPile;
        move_discard_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());
        moves.append(move_discard_2);
    }
    if (!moves.isEmpty())
        room->moveCardsAtomic(moves, true);

    QVariant decisionData = QVariant::fromValue(QString("pindian:%1:%2:%3:%4:%5")
        .arg(skill_name)
        .arg(from->objectName())
        .arg(pindian_struct->from_card->getEffectiveId())
        .arg(target->objectName())
        .arg(pindian_struct->to_card->getEffectiveId()));
    thread->trigger(ChoiceMade, room, from, decisionData);

    if (pindian_struct->success) return 1;
    else if (pindian_struct->from_number == pindian_struct->to_number) return 0;
    else if (pindian_struct->from_number < pindian_struct->to_number) return -1;
    return -2;
}

void GusheCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (!source->canPindian()) return;
    LogMessage log;
    log.type = "#Pindian";
    log.from = source;
    log.to = targets;
    room->sendLog(log);

    const Card *cardss = NULL;
    QHash<ServerPlayer *, const Card *> hash;
    foreach (ServerPlayer *target, targets) {
        if (!source->canPindian(target, false)) continue;
        PindianStruct *pindian_struct = new PindianStruct;
        pindian_struct->from = source;
        pindian_struct->to = target;
        pindian_struct->from_card = cardss;
        pindian_struct->to_card = NULL;
        pindian_struct->reason = skill_name;

        RoomThread *thread = room->getThread();
        QVariant data = QVariant::fromValue(pindian_struct);
        thread->trigger(AskforPindianCard, room, source, data);

        PindianStruct *new_star = data.value<PindianStruct *>();
        cardss = new_star->from_card;
        const Card *cardt = new_star->to_card;

        if (cardss == NULL && cardt == NULL) {
            QList<const Card *> cards = room->askForPindianRace(source, target, skill_name);
            cardss = cards.first();
            cardt = cards.last();
        } else if (cardt == NULL) {
            if (cardss->isVirtualCard()) {
                int card_id = cardss->getEffectiveId();
                cardss = Sanguosha->getCard(card_id);
            }
            cardt = room->askForPindian(target, source, target, skill_name);
        } else if (cardss == NULL) {
            if (cardt->isVirtualCard()) {
                int card_id = cardt->getEffectiveId();
                cardt = Sanguosha->getCard(card_id);
            }
            cardss = room->askForPindian(source, source, target, skill_name);
        }
        hash[target] = cardt;
    }

    if (!cardss) return;

    foreach (ServerPlayer *target, targets) {
        if (!source->canPindian(target, false)) continue;
        int n = pindian(source, target, cardss, hash[target]);
        if (n == -2) continue;

        QList<ServerPlayer *>losers;
        if (n == 1)
            losers << target;
        else if (n == 0)
            losers << source << target;
        else if (n == -1)
            losers << source;
        if (losers.isEmpty()) continue;

        room->sortByActionOrder(losers);

        foreach (ServerPlayer *p, losers) {
            if (!p->canDiscard(p, "he"))
                source->drawCards(1, skill_name);
            else {
                p->tag[skill_name + "Discard"] = QVariant::fromValue(source);
                const Card *dis = room->askForDiscard(p, skill_name, 1, 1, true, true, "gushe-discard:" + source->objectName());
                p->tag.remove(skill_name + "Discard");
                if (!dis)
                    source->drawCards(1, skill_name);
            }
        }

        if (losers.contains(source))
            source->gainMark("&raoshe");
    }
}

class GusheVS : public ZeroCardViewAsSkill
{
public:
    GusheVS() : ZeroCardViewAsSkill("gushe")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("GusheCard") < 1 + player->getMark("gushe_extra-Clear") && player->canPindian();
    }

    const Card *viewAs() const
    {
        return new GusheCard;
    }
};

class Gushe : public TriggerSkill
{
public:
    Gushe() : TriggerSkill("gushe")
    {
        events << MarkChanged;
        view_as_skill = new GusheVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        MarkStruct mark = data.value<MarkStruct>();
        if (mark.name == "&raoshe" && player->getMark("&raoshe") >= 7)
            room->killPlayer(player);
        return false;
    }
};

class Jici : public TriggerSkill
{
public:
    Jici() : TriggerSkill("jici")
    {
        events << PindianVerifying;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        PindianStruct *pindian = data.value<PindianStruct *>();
        if (pindian->reason != "gushe") return false;

        QList<ServerPlayer *> pindian_players;
        pindian_players << pindian->from << pindian->to;
        room->sortByActionOrder(pindian_players);
        foreach (ServerPlayer *p, pindian_players) {
            if (p && p->isAlive() && p->hasSkill(this)) {
                int n = p->getMark("&raoshe");
                int number = (p == pindian->from) ? pindian->from_number : pindian->to_number;
                if (number < n) {
                    if (p->askForSkillInvoke(this, QString("jici_invoke:%1").arg(QString::number(n)))) {
                        room->broadcastSkillInvoke(objectName());
                        int num = 0;
                        if (p == pindian->from) {
                            pindian->from_number = qMin(13, pindian->from_number + n);
                            num = pindian->from_number;
                        } else {
                            pindian->to_number = qMin(13, pindian->to_number + n);
                            num = pindian->to_number;
                        }

                        LogMessage log;
                        log.type = "#JiciUp";
                        log.from = p;
                        log.arg = QString::number(num);
                        room->sendLog(log);

                        data = QVariant::fromValue(pindian);
                    }
                } else if (number == n) {
                    room->notifySkillInvoked(p, objectName());
                    room->broadcastSkillInvoke(objectName());
                    if (p->hasSkill("gushe")) {
                        LogMessage log;
                        log.type = "#Jici";
                        log.from = p;
                        log.arg = objectName();
                        log.arg2 = "gushe";
                        room->sendLog(log);
                    }

                    room->addPlayerMark(p, "gushe_extra-Clear");
                }
            }
        }
        return false;
    }
};

TenyearGusheCard::TenyearGusheCard() : GusheCard("tenyeargushe")
{
}

class TenyearGusheVS : public ZeroCardViewAsSkill
{
public:
    TenyearGusheVS() : ZeroCardViewAsSkill("tenyeargushe")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("tenyeargushe_pindian_win-Clear") < 7 - player->getMark("&raoshe") && player->canPindian();
    }

    const Card *viewAs() const
    {
        return new TenyearGusheCard;
    }
};

class TenyearGushe : public TriggerSkill
{
public:
    TenyearGushe() : TriggerSkill("tenyeargushe")
    {
        events << MarkChanged << Pindian;
        view_as_skill = new TenyearGusheVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == MarkChanged) {
            MarkStruct mark = data.value<MarkStruct>();
            if (mark.name == "&raoshe" && player->getMark("&raoshe") >= 7 && player->hasSkill(this))
                room->killPlayer(player);
        } else {
            PindianStruct *pindian = data.value<PindianStruct *>();
            if ((pindian->from == player && pindian->from_number > pindian->to_number) ||
                    (pindian->to == player && pindian->to_number > pindian->from_number))
                room->addPlayerMark(player, "tenyeargushe_pindian_win-Clear");
        }
        return false;
    }
};

class TenyearJici : public TriggerSkill
{
public:
    TenyearJici() : TriggerSkill("tenyearjici")
    {
        events << PindianVerifying << Death;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PindianVerifying) {
            PindianStruct *pindian = data.value<PindianStruct *>();
            QList<ServerPlayer *> pindian_players;
            pindian_players << pindian->from << pindian->to;
            room->sortByActionOrder(pindian_players);

            foreach (ServerPlayer *p, pindian_players) {
                if (p && p->isAlive() && p->hasSkill(this)) {
                    int n = p->getMark("&raoshe");
                    int number = (p == pindian->from) ? pindian->from_number : pindian->to_number;
                    if (number <= n) {
                        int num = 0;
                        if (p == pindian->from) {
                            pindian->from_number = qMin(13, pindian->from_number + n);
                            num = pindian->from_number;
                        } else {
                            pindian->to_number = qMin(13, pindian->to_number + n);
                            num = pindian->to_number;
                        }

                        LogMessage log;
                        log.type = "#TenyearJiciUp";
                        log.from = p;
                        log.arg = objectName();
                        log.arg2 = QString::number(num);
                        room->sendLog(log);
                        room->notifySkillInvoked(p, objectName());
                        room->broadcastSkillInvoke(objectName());

                        data = QVariant::fromValue(pindian);

                        QList<int> pindian_ids;
                        if (pindian->from_number >= pindian->to_number) {
                            if (room->CardInTable(pindian->from_card))
                                pindian_ids << pindian->from_card->getEffectiveId();
                            if (!pindian_ids.contains(pindian->to_card->getEffectiveId()) && room->CardInTable(pindian->to_card) &&
                                    pindian->from_number == pindian->to_number)
                                pindian_ids << pindian->to_card->getEffectiveId();
                        } else {
                            if (room->CardInTable(pindian->to_card))
                                pindian_ids << pindian->to_card->getEffectiveId();
                        }
                        if (pindian_ids.isEmpty()) continue;
                        DummyCard dummy(pindian_ids);
                        room->obtainCard(p, &dummy);
                    }
                }
            }
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (!death.who->hasSkill(this) || player != death.who) return false;
            if (!death.damage || !death.damage->from || death.damage->from->isDead()) return false;
            room->sendCompulsoryTriggerLog(death.who, objectName(), true, true);
            int mark = 7 - death.who->getMark("&raoshe");
            if (mark > 0 && death.damage->from->canDiscard(death.damage->from, "he"))
                room->askForDiscard(death.damage->from, objectName(), mark, mark, false, true);
            if (death.damage->from->isAlive())
                room->loseHp(death.damage->from);
        }
        return false;
    }
};

class Qingzhong : public TriggerSkill
{
public:
    Qingzhong() : TriggerSkill("qingzhong")
    {
        events << EventPhaseStart << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (event == EventPhaseStart) {
            if (!player->hasSkill(this) || !player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "qingzhong-PlayClear");
            player->drawCards(2, objectName());
        } else {
            if (player->getMark("qingzhong-PlayClear") <= 0) return false;
            room->setPlayerMark(player, "qingzhong-PlayClear", 0);
            if (player->isKongcheng()) return false;
            int n = player->getHandcardNum();
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getHandcardNum() < n)
                    n = p->getHandcardNum();
            }
            QList<ServerPlayer *> least_hand;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getHandcardNum() <= n)
                    least_hand << p;
            }
            if (least_hand.contains(player))
                least_hand.removeOne(player);
            if (least_hand.isEmpty()) return false;

            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            ServerPlayer *target = room->askForPlayerChosen(player, least_hand, objectName(), "@qingzhong-invoke");
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());

            LogMessage log;
            log.type = "#Dimeng";
            log.from = player;
            log.to << target;
            log.arg = QString::number(player->getHandcardNum());
            log.arg2 = QString::number(target->getHandcardNum());
            room->sendLog(log);
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p != player && p != target) {
                    JsonArray arr;
                    arr << player->objectName() << target->objectName();
                    room->doNotify(p, QSanProtocol::S_COMMAND_EXCHANGE_KNOWN_CARDS, arr);
                }
            }
            QList<CardsMoveStruct> exchangeMove;
            CardsMoveStruct move1(player->handCards(), target, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_SWAP, player->objectName(), target->objectName(), "qingzhong", QString()));
            CardsMoveStruct move2(target->handCards(), player, Player::PlaceHand,
                CardMoveReason(CardMoveReason::S_REASON_SWAP, target->objectName(), player->objectName(), "qingzhong", QString()));
            exchangeMove.push_back(move1);
            exchangeMove.push_back(move2);
            room->moveCardsAtomic(exchangeMove, false);
            room->getThread()->delay();
        }
        return false;
    }
};

class WeijingVS : public ZeroCardViewAsSkill
{
public:
    WeijingVS() : ZeroCardViewAsSkill("weijing")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player) && player->getMark("weijing_lun") <= 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
            return false;
        return (pattern == "jink" || pattern.contains("slash") || pattern.contains("Slash")) && player->getMark("weijing_lun") <= 0;
    }

    const Card *viewAs() const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY){
            Slash *slash = new Slash(Card::NoSuit, -1);
            slash->setSkillName(objectName());
            return slash;
        }

        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
            return NULL;
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "jink") {
            Jink *jink = new Jink(Card::NoSuit, 0);
            jink->setSkillName(objectName());
            return jink;
        } else if (pattern.contains("slash") || pattern.contains("Slash")) {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName(objectName());
            return slash;
        } else
            return NULL;
    }
};

class Weijing : public TriggerSkill
{
public:
    Weijing() : TriggerSkill("weijing")
    {
        events << PreCardUsed << PreCardResponded;
        view_as_skill = new WeijingVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard") || use.card->getSkillName() != objectName()) return false;
            card = use.card;
        } else {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_card->isKindOf("SkillCard") || resp.m_card->getSkillName() != objectName()) return false;
            card = resp.m_card;
        }
        if (!card) return false;
        room->addPlayerMark(player, "weijing_lun");
        return false;
    }
};

class Lvli : public TriggerSkill
{
public:
    Lvli() : TriggerSkill("lvli")
    {
        events << Damage << Damaged;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        ServerPlayer *current = room->getCurrent();
        if (!current || current->getPhase() == Player::NotActive) return false;
        int marks = player->getMark("lvli-Clear");
        int choujue = player->getMark("choujue");

        int max = 1;
        if (choujue > 0 && current == player)
            max = 2;
        if (marks >= max) return false;

        if (event == Damaged) {
            if (player->getMark("beishui") <= 0)
                return false;
        }

        if ((player->getHandcardNum() < player->getHp()) || (player->getHandcardNum() > player->getHp() && player->getLostHp() > 0)) {
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "lvli-Clear");
            if (player->getHandcardNum() < player->getHp()) {
                int draw = player->getHp() - player->getHandcardNum();
                if (draw <= 0) return false;
                player->drawCards(draw, objectName());
            } else if (player->getHandcardNum() > player->getHp() && player->getLostHp() > 0) {
                int recover = player->getHandcardNum() - player->getHp();
                recover = qMin(recover, player->getMaxHp() - player->getHp());
                if (recover <= 0) return false;
                room->recover(player, RecoverStruct(player, NULL, recover));
            }
        }
        return false;
    }
};

class Choujue : public TriggerSkill
{
public:
    Choujue() : TriggerSkill("choujue")
    {
        events << EventPhaseChanging;
        frequency = Wake;
        waked_skills = "beishui";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool canWake(TriggerEvent, ServerPlayer *, QVariant &data, Room *) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive)
            return false;
        return true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
        foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
            if (p->isDead() || p->getMark(objectName()) > 0 || !p->hasSkill(this)) continue;
            if (p->canWake("choujue") || qAbs(p->getHandcardNum() - p->getHp()) >= 3) {
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                room->doSuperLightbox("wenyang", "choujue");
                room->setPlayerMark(p, "choujue", 1);
                if (room->changeMaxHpForAwakenSkill(p)) {
                    if (!p->hasSkill("beishui", true))
                        room->acquireSkill(p, "beishui");
                    if (p->hasSkill("lvli"), true) {
                        LogMessage log;
                        log.type = "#JiexunChange";
                        log.from = p;
                        log.arg = "lvli";
                        room->sendLog(log);
                    }
                    QString translate;
                    if (p->getMark("beishui") > 0)
                         translate = Sanguosha->translate(":lvli4");
                    else
                        translate = Sanguosha->translate(":lvli2");
                    Sanguosha->addTranslationEntry(":lvli", translate.toStdString().c_str());
                    room->doNotify(p, QSanProtocol::S_COMMAND_UPDATE_SKILL, QVariant("lvli"));
                }
            }
        }
        return false;
    }
};

class Beishui : public PhaseChangeSkill
{
public:
    Beishui() : PhaseChangeSkill("beishui")
    {
        frequency = Wake;
        waked_skills = "qingjiao";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        if (player->getPhase() != Player::Start) return false;
        if (player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getHandcardNum() >= 2 && player->getHp() >= 2) return false;
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("wenyang", "beishui");
        room->setPlayerMark(player, "beishui", 1);
        if (room->changeMaxHpForAwakenSkill(player)) {
            room->acquireSkill(player, "qingjiao");
            if (player->hasSkill("lvli"), true) {
                LogMessage log;
                log.type = "#JiexunChange";
                log.from = player;
                log.arg = "lvli";
                room->sendLog(log);
            }
            QString translate;
            if (player->getMark("choujue") > 0)
                 translate = Sanguosha->translate(":lvli4");
            else
                translate = Sanguosha->translate(":lvli3");
            Sanguosha->addTranslationEntry(":lvli", translate.toStdString().c_str());
            room->doNotify(player, QSanProtocol::S_COMMAND_UPDATE_SKILL, QVariant("lvli"));
        }
        return false;
    }
};

class Qingjiao : public PhaseChangeSkill
{
public:
    Qingjiao() : PhaseChangeSkill("qingjiao")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (player->getPhase() == Player::Play && player->hasSkill(this)) {
            if (!player->canDiscard(player, "h")) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "qingjiao-Clear");
            player->throwAllHandCards();

            QList<int> ids = room->getDrawPile() + room->getDiscardPile();
            if (ids.isEmpty()) return false;

            QStringList names;
            foreach (int id, ids) {
                const Card *card = Sanguosha->getCard(id);
                QString name = card->objectName();
                if (card->isKindOf("Weapon"))
                    name = "Weapon";
                else if (card->isKindOf("Armor"))
                    name = "Armor";
                else if (card->isKindOf("DefensiveHorse"))
                    name = "DefensiveHorse";
                else if (card->isKindOf("OffensiveHorse"))
                    name = "OffensiveHorse";
                else if (card->isKindOf("Treasure"))
                    name = "Treasure";
                if (!names.contains(name))
                    names << name;
            }
            if (names.isEmpty()) return false;

            QStringList eight_names;
            int length = names.length();
            length = qMin(length, 8);
            for (int i = 0; i < length; i++) {
                int n = qrand() % names.length();
                QString str = names.at(n);
                names.removeOne(str);
                eight_names << str;
                if (names.isEmpty()) break;
            }
            if (eight_names.isEmpty()) return false;

            QList<int> get;
            foreach (QString name, eight_names) {
                QList<int> name_ids;
                foreach (int id, ids) {
                    const Card *card = Sanguosha->getCard(id);
                    const char *ch = name.toStdString().c_str();
                    if ((name == "Weapon" || name == "Armor" || name == "DefensiveHorse" || name == "OffensiveHorse" || name == "Treasure")
                            && card->isKindOf(ch))
                        name_ids << id;
                    else if ((name != "Weapon" && name != "Armor" && name != "DefensiveHorse" && name != "OffensiveHorse" && name != "Treasure") &&
                             name == card->objectName())
                        name_ids << id;
                }
                if (name_ids.isEmpty()) continue;
                get << name_ids.at(qrand() % name_ids.length());
            }
            if (get.isEmpty()) return false;
            DummyCard *dummy = new DummyCard(get);
            room->obtainCard(player, dummy, true);
            delete dummy;
        } else if (player->getPhase() == Player::Finish) {
            if (player->getMark("qingjiao-Clear") <= 0) return false;
            if (player->isNude()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->setPlayerMark(player, "qingjiao-Clear", 0);
            player->throwAllHandCardsAndEquips();
        }
        return false;
    }
};

class Weicheng : public TriggerSkill
{
public:
    Weicheng() : TriggerSkill("weicheng")
    {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from != player || !move.to || move.to == player || player->isDead()) return false;
        if (!move.from_places.contains(Player::PlaceHand) || move.to_place != Player::PlaceHand) return false;
        if (player->getHandcardNum() >= player->getHp()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        player->drawCards(1, objectName());
        return false;
    }
};

DaoshuCard::DaoshuCard()
{
}

bool DaoshuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && !to_select->isKongcheng();
}

void DaoshuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    Card::Suit suit = room->askForSuit(effect.from, "daoshu");

    LogMessage log;
    log.type = "#ChooseSuit";
    log.from = effect.from;
    log.arg = Card::Suit2String(suit);
    room->sendLog(log);

    if (effect.to->isKongcheng()) return;
    int id = room->askForCardChosen(effect.from, effect.to, "h", "daoshu");
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
    const Card *card = Sanguosha->getCard(id);
    room->obtainCard(effect.from, card, reason, true);

    if (effect.from->isDead() || effect.to->isDead()) return;
    if (card->getSuit() == suit) {
        room->damage(DamageStruct("daoshu", effect.from, effect.to));
        int times = effect.from->usedTimes("DaoshuCard");
        if (times > 0)
            room->addPlayerHistory(effect.from, "DaoshuCard", -times);
    } else {
        QList<const Card *> cards;
        foreach (const Card *c, effect.from->getCards("h")) {
            if (c->getSuit() != card->getSuit()) {
                cards << c;
            }
        }
        if (cards.isEmpty())
            room->showAllCards(effect.from);
        else {
            QStringList data;
            data << effect.to->objectName() << card->getSuitString();
            const Card *give = room->askForCard(effect.from, ".|^" + card->getSuitString() + "|.|hand!", "daoshu-give:" + effect.to->objectName(),
                                                data, Card::MethodNone);

            if (!give)
                give = cards.at(qrand() % cards.length());

            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "daoshu", QString());
            room->obtainCard(effect.to, give, reason, true);
        }
    }
}

class Daoshu : public ZeroCardViewAsSkill
{
public:
    Daoshu() : ZeroCardViewAsSkill("daoshu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DaoshuCard");
    }

    const Card *viewAs() const
    {
        DaoshuCard *card = new DaoshuCard;
        return card;
    }
};

class Xingzhao : public TriggerSkill
{
public:
    Xingzhao() : TriggerSkill("xingzhao")
    {
        events << CardUsed <<  EventPhaseChanging;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            if (getWounded(room) < 2) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("EquipCard")) return false;
            room->sendCompulsoryTriggerLog(player, "xingzhao", true, true);
            player->drawCards(1, "xingzhao");
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::Discard || getWounded(room) < 3 || player->isSkipped(Player::Discard)) return false;
            room->sendCompulsoryTriggerLog(player, "xingzhao", true, true);
            player->skip(Player::Discard);
        }
        return false;
    }

private:
    int getWounded(Room *room) const
    {
        int n = 0;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isWounded())
                n++;
        }
        return n;
    }
};

class XingzhaoXunxun : public TriggerSkill
{
public:
    XingzhaoXunxun() : TriggerSkill("#xingzhao-xunxun")
    {
        events << GameStart << HpChanged << MaxHpChanged << EventAcquireSkill << EventLoseSkill << Death << Revived;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventLoseSkill) {
            if (data.toString() == "xingzhao") {
                QStringList xingzhao_xunxun = player->tag["xingzhao_xunxun"].toStringList();
                player->tag["xingzhao_xunxun"] = QVariant();
                QStringList detachList;
                foreach(QString skill_name, xingzhao_xunxun)
                    detachList.append("-" + skill_name);
                if (!detachList.isEmpty())
                    room->handleAcquireDetachSkills(player, detachList);
            }
            return false;
        } else if (triggerEvent == EventAcquireSkill) {
            if (data.toString() != "xingzhao") return false;
            if (player->isDead() || !player->hasSkill(this)) return false;
            XunxunChange(room, player);
            return false;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player || !player->hasSkill(this)) return false;
        }

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (!p->isAlive() || !p->hasSkill("xingzhao")) continue;
            XunxunChange(room, p);
        }
        return false;
    }

private:
    void XunxunChange(Room *room, ServerPlayer *player) const
    {
        QStringList xingzhao_xunxun = player->tag["xingzhao_xunxun"].toStringList();
        int n = 0;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isWounded())
                n++;
        }
        if (n >= 1 && !xingzhao_xunxun.contains("xunxun") && !player->hasSkill("xunxun", true)) {
            xingzhao_xunxun << "xunxun";
            player->tag["xingzhao_xunxun"] = QVariant::fromValue(xingzhao_xunxun);
            room->sendCompulsoryTriggerLog(player, "xingzhao", true, true);
            room->acquireSkill(player, "xunxun");
        } else if (n < 1 && xingzhao_xunxun.contains("xunxun") && player->hasSkill("xunxun", true)) {
            player->tag["xingzhao_xunxun"] = QVariant();
            room->sendCompulsoryTriggerLog(player, "xingzhao", true, true);
            room->detachSkillFromPlayer(player, "xunxun");
        }
    }
};

class Daigong : public TriggerSkill
{
public:
    Daigong() : TriggerSkill("daigong")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->isKongcheng()) return false;
        if (!room->hasCurrent() || player->getMark("daigong-Clear") > 0) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.damage <= 0) return false;
        QVariant d = QVariant();
        if (damage.from && damage.from->isAlive())
            d = QVariant::fromValue(damage.from);
        if (!player->askForSkillInvoke(this, d)) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, "daigong-Clear");
        room->showAllCards(player);

        if (!damage.from || damage.from->isDead()) return false;
        QStringList suits;
        foreach (const Card *c, player->getCards("h")) {
            if (!suits.contains(c->getSuitString()))
                suits << c->getSuitString();
        }

        bool has = false;
        foreach (const Card *c, damage.from->getCards("h")) {
            QString str = c->getSuitString();
            if (!suits.contains(str)) {
                has = true;
                break;
            }
        }

        if (!has) {
            LogMessage log;
            log.type = "#Daigong";
            log.from = damage.from;
            log.to << player;
            log.arg = QString::number(damage.damage);
            room->sendLog(log);
            return true;
        } else {
            QStringList all_suits;
            all_suits << "spade" << "club" << "heart" << "diamond" << "no_suit_black" << "no_suit_red" << "no_suit";
            foreach (QString str, suits) {
                all_suits.removeOne(str);
            }
            if (all_suits.isEmpty()) {
                LogMessage log;
                log.type = "#Daigong";
                log.from = damage.from;
                log.to << player;
                log.arg = QString::number(damage.damage);
                room->sendLog(log);
                return true;
            } else {
                QString suitt = all_suits.join(",");
                QString pattern = ".|" + suitt + "|.|.";
                QStringList data_list;
                data_list << player->objectName() << suitt;
                const Card *give = room->askForCard(damage.from, pattern, "daigong-give:" + player->objectName(), data_list, Card::MethodNone);
                if (!give) {
                    LogMessage log;
                    log.type = "#Daigong";
                    log.from = damage.from;
                    log.to << player;
                    log.arg = QString::number(damage.damage);
                    room->sendLog(log);
                    return true;
                } else {
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, damage.from->objectName(), player->objectName(), "daigong", QString());
                    room->obtainCard(player, give, reason, true);
                }
            }
        }
        return false;
    }
};

SpZhaoxinCard::SpZhaoxinCard()
{
    target_fixed= true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void SpZhaoxinCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->addToPile("zxwang", this);
    source->drawCards(getSubcards().length(), "spzhaoxin");
}

SpZhaoxinChooseCard::SpZhaoxinChooseCard()
{
    m_skillName = "spzhaoxin";
    target_fixed= true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

class SpZhaoxinVS : public ViewAsSkill
{
public:
    SpZhaoxinVS() : ViewAsSkill("spzhaoxin")
    {
       expand_pile = "zxwang";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            return selected.length() < 3 - Self->getPile("zxwang").length() && Self->hasCard(to_select);
        }
        return Self->getPile("zxwang").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (cards.isEmpty())
                return NULL;
            SpZhaoxinCard *c = new SpZhaoxinCard;
            c->addSubcards(cards);
            return c;
        }
        if (cards.length() != 1)
            return NULL;
        SpZhaoxinChooseCard *c = new SpZhaoxinChooseCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SpZhaoxinCard") && player->getPile("zxwang").length() < 3;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@spzhaoxin" && !player->getPile("zxwang").isEmpty();
    }
};

class SpZhaoxin : public TriggerSkill
{
public:
    SpZhaoxin() : TriggerSkill("spzhaoxin")
    {
        events << EventPhaseEnd;
        view_as_skill = new SpZhaoxinVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Draw) return false;
        foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
            if (player->isDead() || !p->hasSkill(this)) return false;
            if (p->isDead() || p->getPile("zxwang").isEmpty()) continue;
            if (p != player && !p->inMyAttackRange(player)) continue;
            const Card *card = room->askForUseCard(p, "@@spzhaoxin", "@spzhaoxin:" + player->objectName());
            if (!card) continue;
            room->fillAG(QList<int>() << card->getSubcards().first(), player);
            if (!player->askForSkillInvoke(this, QString("spzhaoxin_get:%1::%2").arg(card->getSubcards().first()).arg(p->objectName()), false)) {
                room->clearAG(player);
                continue;
            }
            room->clearAG(player);
            if (p == player) {
                LogMessage log;
                log.type = "$KuangbiGet";
                log.from = player;
                log.arg = "zxwang";
                log.card_str = IntList2StringList(card->getSubcards()).join("+");
                room->sendLog(log);
            }
            player->obtainCard(card, true);
            if (!p->askForSkillInvoke(this, QString("spzhaoxin_damage:%1").arg(player->objectName()), false)) continue;
            room->damage(DamageStruct("spzhaoxin", p, player));
        }
        return false;
    }
};

class Zhongzuo : public TriggerSkill
{
public:
    Zhongzuo() : TriggerSkill("zhongzuo")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) ||
                    (p->getMark("zhongzuo_damaged-Clear") <= 0 && p->getMark("zhongzuo_damage-Clear") <= 0)) continue;
            ServerPlayer *target = room->askForPlayerChosen(p, room->getAlivePlayers(), objectName(), "@zhongzuo-invoke", true, true);
            if (!target) continue;
            room->broadcastSkillInvoke(objectName());
            target->drawCards(2, objectName());
            if (target->isWounded())
                p->drawCards(1, objectName());
        }
        return false;
    }
};

class ZhongzuoRecord : public TriggerSkill
{
public:
    ZhongzuoRecord() : TriggerSkill("#zhongzuo-record")
    {
        events << DamageDone;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to && damage.to->isAlive())
            room->addPlayerMark(damage.to, "zhongzuo_damaged-Clear");
        if (damage.from && damage.from->isAlive())
            room->addPlayerMark(damage.from, "zhongzuo_damage-Clear");
        return false;
    }
};

class Wanlan : public TriggerSkill
{
public:
    Wanlan() : TriggerSkill("wanlan")
    {
        events << Dying;
        frequency = Limited;
        limit_mark = "@wanlanMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        ServerPlayer *who = dying.who;
        if (player->getMark("@wanlanMark") <= 0 || !player->canDiscard(player, "h") ||
                !player->askForSkillInvoke(this, QVariant::fromValue(who))) return false;
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("jiakui", "wanlan");
        room->removePlayerMark(player, "@wanlanMark");
        player->throwAllHandCards();
        if (who->getHp() < 1) {
            int n = qMin(1 - who->getHp(), who->getMaxHp() - who->getHp());
            if (n > 0)
                room->recover(who, RecoverStruct(player, NULL, n));
        }
        ServerPlayer *current = room->getCurrent();
        if (current && current->isAlive() && current->getPhase() != Player::NotActive)
            room->addPlayerMark(current, "wanlan_" + player->objectName() + "-Clear");
        return false;
    }
};

class WanlanDamage : public TriggerSkill
{
public:
    WanlanDamage() : TriggerSkill("#wanlan-damage")
    {
        events << AskForPeachesDone;
        frequency = Limited;
        //limit_mark = "@wanlan";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
        ServerPlayer *current = room->getCurrent();
        if (current && current->isAlive() && current->getPhase() != Player::NotActive) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (current->getMark("wanlan_" + p->objectName() + "-Clear") > 0) {
                    room->setPlayerMark(current, "wanlan_" + p->objectName() + "-Clear", 0);
                    room->damage(DamageStruct("wanlan", p ,current));
                    break;
                }
            }
        }
        return false;
    }
};

TongquCard::TongquCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool TongquCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getMark("&tqqu") > 0 && to_select != Self;
}

bool TongquCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    int id = getSubcards().first();
    if (Self->canDiscard(Self, id))
        return true;
    return !targets.isEmpty();
}

void TongquCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int id = getSubcards().first();
    const Card *c = Sanguosha->getCard(id);
    if (card_use.to.isEmpty()) {
        if (card_use.from->canDiscard(card_use.from, id)) {
            CardMoveReason reason(CardMoveReason::S_REASON_THROW, card_use.from->objectName(), "tongqu", QString());
            room->throwCard(this, reason, card_use.from, NULL);
        } else {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(card_use.from)) {
                if (p->getMark("&tqqu") <= 0) continue;
                targets << p;
            }
            if (targets.isEmpty()) return;
            ServerPlayer *target = targets.at(qrand() % targets.length());
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, card_use.from->objectName(), target->objectName(), "tongqu", QString());
            room->obtainCard(target, this, reason, false);
            if (target->isAlive() && c->isKindOf("EquipCard") && c->isAvailable(target) && !target->isProhibited(target, c))
                room->useCard(CardUseStruct(c, target, target));
        }
    } else {
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, card_use.from->objectName(), card_use.to.first()->objectName(), "tongqu", QString());
        room->obtainCard(card_use.to.first(), this, reason, false);
        if (card_use.to.first()->isAlive() && c->isKindOf("EquipCard") && c->isAvailable(card_use.to.first())
                && !card_use.to.first()->isProhibited(card_use.to.first(), c))
            room->useCard(CardUseStruct(c, card_use.to.first(), card_use.to.first()));
    }
}

class TongquVS : public OneCardViewAsSkill
{
public:
    TongquVS() : OneCardViewAsSkill("tongqu")
    {
        filter_pattern = ".";
        response_pattern = "@@tongqu!";
    }

    const Card *viewAs(const Card *originalcard) const
    {
        TongquCard *c = new TongquCard;
        c->addSubcard(originalcard->getId());
        return c;
    }
};

class Tongqu : public TriggerSkill
{
public:
    Tongqu() : TriggerSkill("tongqu")
    {
        events << DrawNCards << AfterDrawNCards;
        view_as_skill = new TongquVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DrawNCards) {
            if (player->getMark("&tqqu") <= 0) return false;
            int length = 0;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead() || !p->hasSkill("tongqu")) continue;
                room->notifySkillInvoked(p, "tongqu");
                room->broadcastSkillInvoke("tongqu");
                length++;
            }
            if (length <= 0) return false;
            room->setPlayerFlag(player, "tongqu");
            room->addPlayerMark(player, "tongqu-Clear", length);
            LogMessage log;
            log.type = "#HuaijuDraw";
            log.from = player;
            log.arg = "tongqu";
            log.arg2 = QString::number(length);
            room->sendLog(log);
            data = QVariant::fromValue(data.toInt() + length);
        } else {
            if (!player->hasFlag("tongqu")) return false;
            room->setPlayerFlag(player, "-tongqu");
            int n = player->getMark("tongqu-Clear");
            if (n <= 0) return false;
            room->addPlayerMark(player, "tongqu-Clear", 0);
            for (int i = 0; i < n; i++) {
                if (player->isDead() || player->isNude()) return false;
                if (!room->askForUseCard(player, "@@tongqu!", "@tongqu")) {
                    QList<int> dis;
                    foreach (const Card *c, player->getCards("he")) {
                        if (!player->canDiscard(player, c->getEffectiveId())) continue;
                        dis << c->getEffectiveId();
                    }
                    if (!dis.isEmpty()) {
                        int id = dis.at(qrand() % dis.length());
                        room->throwCard(id, player);
                    } else {
                        const Card *c = player->getCards("he").at(qrand() % player->getCards("he").length());
                        QList<ServerPlayer *> targets;
                        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                            if (p->getMark("&tqqu") <= 0) continue;
                            targets << p;
                        }
                        if (targets.isEmpty()) return false;
                        ServerPlayer *target = targets.at(qrand() % targets.length());
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "tongqu", QString());
                        room->obtainCard(target, c, reason, false);
                        if (target->isAlive() && c->isKindOf("EquipCard") && c->isAvailable(target) && !target->isProhibited(target, c))
                            room->useCard(CardUseStruct(c, target, target));
                    }
                }
            }
        }
        return false;
    }
};

class TongquTrigger : public TriggerSkill
{
public:
    TongquTrigger() : TriggerSkill("#tongqu-trigger")
    {
        events << GameStart << EventPhaseStart << Dying;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GameStart) {
            room->sendCompulsoryTriggerLog(player, "tongqu", true, true);
            player->gainMark("&tqqu");
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Start) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getMark("&tqqu") > 0) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, "tongqu", "@tongqu-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke("tongqu");
            room->loseHp(player);
            target->gainMark("&tqqu");
        } else {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who->getMark("&tqqu") <= 0) return false;
            room->sendCompulsoryTriggerLog(player, "tongqu", true, true);
            dying.who->loseAllMarks("&tqqu");
        }
        return false;
    }
};

class NewWanlan : public TriggerSkill
{
public:
    NewWanlan() : TriggerSkill("newwanlan")
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
        if (damage.damage < player->getHp()) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "e")) continue;
            if (!p->askForSkillInvoke(this, QVariant::fromValue(player))) continue;
            room->broadcastSkillInvoke(objectName());
            p->throwAllEquips();
            return true;
        }
        return false;
    }
};

class Qianchong : public TriggerSkill
{
public:
    Qianchong() : TriggerSkill("qianchong")
    {
        events << CardsMoveOneTime << EventPhaseStart << EventAcquireSkill;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            if (QianchongJudge(player, "black") || QianchongJudge(player, "red")) return false;
            int n = 0;
            QString choice = room->askForChoice(player, objectName(), "basic+trick+equip");
            LogMessage log;
            log.type = "#QianchongChoice";
            log.from = player;
            log.arg = objectName();
            log.arg2 = choice;
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName(), 3);
            if (choice == "basic")
                n = 1;
            else if (choice == "trick")
                n = 2;
            else
                n = 3;
            room->addPlayerMark(player, "qianchong-Clear", n);
        } else {
            bool flag = false;
            if (event == CardsMoveOneTime) {
                CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
                if (move.from && move.from == player && move.from_places.contains(Player::PlaceEquip))
                    flag = true;
                if (move.to && move.to == player && move.to_place == Player::PlaceEquip)
                    flag = true;
            } else {
                if (data.toString() == objectName())
                    flag = true;
            }
            if (flag == true) {
                QString skill = player->property("qianchong_skill").toString();
                QStringList skills;
                int index = 1;
                if (QianchongJudge(player, "black") && !player->hasSkill("weimu", true) && skill == QString()) {
                    room->setPlayerProperty(player, "qianchong_skill", "weimu");
                    skills << "weimu";
                }
                if (!QianchongJudge(player, "black") && player->hasSkill("weimu", true) && skill == "weimu") {
                    room->setPlayerProperty(player, "qianchong_skill", QString());
                    skills << "-weimu";
                }
                if (QianchongJudge(player, "red") && !player->hasSkill("mingzhe", true) && skill == QString()) {
                    room->setPlayerProperty(player, "qianchong_skill", "mingzhe");
                    skills << "mingzhe";
                    index = 2;
                }
                if (!QianchongJudge(player, "red") && player->hasSkill("mingzhe", true) && skill == "mingzhe") {
                    room->setPlayerProperty(player, "qianchong_skill", QString());
                    skills << "-mingzhe";
                    index = 2;
                }
                if (!skills.isEmpty()) {
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true, index);
                    room->handleAcquireDetachSkills(player, skills);
                }
            }
        }
        return false;
    }
private:
    bool QianchongJudge(ServerPlayer *player, const QString &type) const
    {
        QList<const Card *>equips = player->getEquips();
        if (equips.isEmpty()) return false;
        if (type == "red") {
            foreach (const Card *c, equips) {
                if (!c->isRed())
                    return false;
            }
        } else if (type == "black") {
            foreach (const Card *c, equips) {
                if (!c->isBlack())
                    return false;
            }
        }
        return true;
    }
};

class QianchongLose : public TriggerSkill
{
public:
    QianchongLose() : TriggerSkill("#qianchong-lose")
    {
        events << EventLoseSkill;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.toString() != "qianchong") return false;
        QString skill = player->property("qianchong_skill").toString();
        room->setPlayerProperty(player, "qianchong_skill", QString());
        if (skill == QString()) return false;
        if (!player->hasSkill(skill)) return false;
        room->handleAcquireDetachSkills(player, "-" + skill);
        return false;
    }
};

class QianchongTargetMod : public TargetModSkill
{
public:
    QianchongTargetMod() : TargetModSkill("#qianchong-target")
    {
        pattern = ".";
    }

    int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (card->getTypeId() == from->getMark("qianchong-Clear"))
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (card->getTypeId() == from->getMark("qianchong-Clear"))
            return 1000;
        else
            return 0;
    }
};

class Shangjian : public PhaseChangeSkill
{
public:
    Shangjian() : PhaseChangeSkill("shangjian")
    {
        frequency = Frequent;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
       if (player->getPhase() != Player::Finish) return false;
       Room *room = player->getRoom();
       foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
           int n = p->getMark("shangjian-Clear");
           if (p->isDead() || n > p->getHp() || n <= 0 || !p->hasSkill(this)) continue;
           if (!p->askForSkillInvoke(this)) continue;
           room->broadcastSkillInvoke(objectName());
           room->setPlayerMark(p, "shangjian-Clear", 0);
           p->drawCards(n, objectName());
       }
       return false;
    }
};

class ShangjianMark : public TriggerSkill
{
public:
    ShangjianMark() : TriggerSkill("#shangjian-mark")
    {
        events << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from && move.from == player &&
                (move.from_places.contains(Player::PlaceEquip) || move.from_places.contains(Player::PlaceHand))) {
            if (move.to && move.to == player && (move.to_place == Player::PlaceEquip || move.to_place == Player::PlaceHand)) return false;
            int mark = 0;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceEquip || move.from_places.at(i) == Player::PlaceHand)
                    mark++;
            }
            if (mark > 0)
                room->addPlayerMark(player, "shangjian-Clear", mark);
        }
        return false;
    }
};

class Chijie : public TriggerSkill
{
public:
    Chijie() : TriggerSkill("chijie")
    {
        events << Damaged << DamageCaused << DamageDone << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard") || use.card->hasFlag("chijie_damage_done")) return false;
            foreach (ServerPlayer *p, use.to) {
                if (p->isDead() || !p->hasSkill(this) || use.from == p || p->getMark("chijie-Clear") > 0 ||
                        !room->CardInPlace(use.card, Player::DiscardPile)) continue;
                room->addPlayerMark(p, "chijie-Clear");
                room->sendCompulsoryTriggerLog(p, this);
                room->obtainCard(p, use.card);
            }
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || damage.card->isKindOf("SkillCard")) return false;
            if (event == Damaged) {
                if (!room->hasCurrent() || player->getMark("chijie-Clear") > 0 || player->isDead() || !player->hasSkill(this)) return false;
                if (room->getCardUser(damage.card) == player) return false;
                if (player->askForSkillInvoke(this, QString("chijie_damage:" + damage.card->objectName()))) {
                    room->addPlayerMark(player, "chijie-Clear");
                    room->setCardFlag(damage.card, "chijie");
                    room->setCardFlag(damage.card, "chijie_" + player->objectName());
                }
            } else if (event == DamageCaused) {
                if (damage.to->isDead() || damage.damage <= 0) return false;
                if (damage.card->hasFlag("chijie") && !damage.card->hasFlag("chijie_" + damage.to->objectName())) {
                    LogMessage log;
                    log.type = "#ChijiePrevent";
                    log.from = damage.to;
                    log.arg = objectName();
                    log.arg2 = QString::number(damage.damage);
                    room->sendLog(log);
                    return true;
                }
            } else
                room->setCardFlag(damage.card, "chijie_damage_done");
        }
        return false;
    }
};

YinjuCard::YinjuCard()
{
}

void YinjuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->doSuperLightbox("xinpi", "yinju");
    room->removePlayerMark(effect.from, "@yinjuMark");
    if (!room->hasCurrent()) return;
    room->addPlayerMark(effect.from, "yinju_from-Clear");
    room->addPlayerMark(effect.to, "yinju_to-Clear");
}

class YinjuVS : public ZeroCardViewAsSkill
{
public:
    YinjuVS() : ZeroCardViewAsSkill("yinju")
    {
        frequency = Limited;
        limit_mark = "@yinjuMark";
    }

    const Card *viewAs() const
    {
        return new YinjuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@yinjuMark") > 0;
    }
};

class Yinju : public TriggerSkill
{
public:
    Yinju() : TriggerSkill("yinju")
    {
        events << DamageCaused << TargetSpecified;
        view_as_skill = new YinjuVS;
        frequency = Limited;
        limit_mark = "@yinjuMark";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to->isDead()) return false;
            if (player->getMark("yinju_from-Clear") <= 0 || damage.to->getMark("yinju_to-Clear") <= 0) return false;
            LogMessage log;
            log.type = damage.to->getLostHp() > 0 ? "#YinjuPrevent1" : "#YinjuPrevent2";
            log.from = player;
            log.to << damage.to;
            log.arg = objectName();
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
            int n = qMin(damage.damage, damage.to->getMaxHp() - damage.to->getHp());
            if (n > 0)
                room->recover(damage.to, RecoverStruct(player, NULL, n));
            return true;
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (player->getMark("yinju_from-Clear") <= 0) return false;
            foreach (ServerPlayer *p, use.to) {
                if (p->getMark("yinju_to-Clear") <= 0) continue;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class Zhuilie : public TriggerSkill
{
public:
    Zhuilie() : TriggerSkill("zhuilie")
    {
        events << TargetSpecified << ConfirmDamage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            foreach (ServerPlayer *p, use.to) {
                if (!player->inMyAttackRange(p)) {
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    if (use.m_addHistory)
                        room->addPlayerHistory(player, use.card->getClassName(), -1);
                    JudgeStruct judge;
                    judge.reason = objectName();
                    judge.who = player;
                    judge.pattern = "Weapon,OffensiveHorse,DefensiveHorse";
                    judge.good = true;
                    room->judge(judge);

                    if (judge.isGood())
                        room->setCardFlag(use.card, "zhuilie_" + p->objectName());
                    else
                        room->loseHp(player);
                }
            }
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || damage.to->isDead()) return false;
            if (!damage.card->hasFlag("zhuilie_" + damage.to->objectName())) return false;
            room->setCardFlag(damage.card, "-zhuilie_" + damage.to->objectName());
            LogMessage log;
            log.type = damage.to->getHp() > 0 ? "#ZhuilieDamage" : "#ZhuiliePrevent";
            log.from = player;
            log.to << damage.to;
            log.arg = objectName();
            log.arg2 = QString::number(qMax(0, damage.to->getHp()));
            room->sendLog(log);
            if (damage.to->getHp() > 0) {
                damage.damage = damage.to->getHp();
                data = QVariant::fromValue(damage);
            } else
                return true;
            return false;
        }
        return false;
    }
};

class ZhuilieSlash : public TargetModSkill
{
public:
    ZhuilieSlash() : TargetModSkill("#zhuilie-slash")
    {
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("zhuilie"))
            return 1000;
        else
            return 0;
    }
};

class Tuiyan : public PhaseChangeSkill
{
public:
    Tuiyan(const QString &tuiyan) : PhaseChangeSkill(tuiyan), tuiyan(tuiyan)
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
       if (player->getPhase() != Player::Play) return false;
       if (!player->askForSkillInvoke(this)) return false;
       Room *room = player->getRoom();
       room->broadcastSkillInvoke(objectName());

       int n = 2;
       if (objectName() == "tenyeartuiyan")
           n = 3;

       QList<int> ids = room->getNCards(n, false);
       room->returnToTopDrawPile(ids);
       LogMessage log;
       log.type = "$ViewDrawPile";
       log.from = player;
       log.arg = QString::number(n);
       log.card_str = IntList2StringList(ids).join("+");
       room->sendLog(log, player);

       log.type = "#ViewDrawPile";
       room->sendLog(log, room->getOtherPlayers(player, true));

       room->fillAG(ids, player);
       room->askForAG(player, ids, true, objectName());
       room->clearAG(player);
       return false;
    }
private:
    QString tuiyan;
};

BusuanCard::BusuanCard()
{
}

void BusuanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    QStringList alllist;
    QList<int> ids;
    foreach(int id, Sanguosha->getRandomCards()) {
        const Card *c = Sanguosha->getEngineCard(id);
        if (c->isKindOf("EquipCard")) continue;
        if (alllist.contains(c->objectName())) continue;
        alllist << c->objectName();
        ids << id;
    }
    if (ids.isEmpty()) return;
    room->fillAG(ids, effect.from);
    int id = -1, id2 = -1;
    id = room->askForAG(effect.from, ids, false, "busuan");
    room->clearAG(effect.from);
    ids.removeOne(id);

    const Card *first_card = Sanguosha->getEngineCard(id);
    if (first_card->isKindOf("Slash")) {
        foreach (int id, ids) {
            if (Sanguosha->getEngineCard(id)->isKindOf("Slash"))
                ids.removeOne(id);
        }
    }

    if (!ids.isEmpty()) {
        room->fillAG(ids, effect.from);
        id2 = room->askForAG(effect.from, ids, false, "busuan");
        room->clearAG(effect.from);
    }

    QStringList list;
    QString name = first_card->objectName();
    list << name;
    QString name2 = QString();
    if (id2 >= 0) {
        name2 = Sanguosha->getEngineCard(id2)->objectName();
        list << name2;
    }
    LogMessage log;
    log.type = id2 >= 0 ? "#Busuantwo" : "#Busuanone";
    log.from = effect.from;
    log.arg = name;
    log.arg2 = name2;
    room->sendLog(log);

    if (list.isEmpty()) return;
    room->setPlayerProperty(effect.to, "busuan_names", list);
}

class BusuanVS : public ZeroCardViewAsSkill
{
public:
    BusuanVS() : ZeroCardViewAsSkill("busuan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("BusuanCard");
    }

    const Card *viewAs() const
    {
        return new BusuanCard;
    }
};

class Busuan : public DrawCardsSkill
{
public:
    Busuan() : DrawCardsSkill("busuan")
    {
        view_as_skill = new BusuanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        QStringList list = player->property("busuan_names").toStringList();
        if (list.isEmpty()) return n;

        Room *room = player->getRoom();
        room->setPlayerProperty(player, "busuan_names", QStringList());
        LogMessage log;
        log.type = "#BusuanEffect";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);

        DummyCard *dummy = new DummyCard();
        QList<int> all = room->getDrawPile() + room->getDiscardPile();
        foreach (QString str, list) {
            QList<int> ids;
            foreach (int id, all) {
                if (Sanguosha->getCard(id)->objectName() == str)
                    ids << id;
            }
            if (ids.isEmpty()) continue;
            int id = ids.at(qrand() % ids.length());
            dummy->addSubcard(id);
        }

        if (dummy->subcardsLength() > 0) {
            room->obtainCard(player, dummy, true);
        }
        delete dummy;
        return 0;
    }
};

class Mingjie : public TriggerSkill
{
public:
    Mingjie(const QString &mingjie) : TriggerSkill(mingjie), mingjie(mingjie)
    {
        events << EventPhaseStart << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            while (player->isAlive()) {
                if (player->isDead()) break;
                if (player->getMark(mingjie + "-Clear") > 0) break;
                if (player->getMark(mingjie + "_num-Clear") > 2) break;
                if (!player->askForSkillInvoke(this)) return false;
                room->broadcastSkillInvoke(objectName());
                player->drawCards(1, objectName(), true, true);
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.reason.m_skillName == objectName() && move.to && move.to == player) {
                if (move.card_ids.length() <= 0) return false;
                room->addPlayerMark(player, mingjie + "_num-Clear", move.card_ids.length());
                foreach (int id, move.card_ids) {
                    if (!Sanguosha->getCard(id)->isBlack()) continue;
                    room->addPlayerMark(player, mingjie + "-Clear");
                    if (mingjie == "mingjie" || (mingjie == "tenyearmingjie" && player->getHp() > 1))
                        room->loseHp(player);
                    break;
                }
            }
        }
        return false;
    }
private:
    QString mingjie;
};

SpQianxinCard::SpQianxinCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool SpQianxinCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void SpQianxinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    int length = room->getDrawPile().length();
    int alive = room->alivePlayerCount();
    if (alive > length)
        room->swapPile();

    QVariantList list = room->getTag("spqianxin_xin").toList();
    foreach (int id, getSubcards()) {
        if (!list.contains(QVariant(id)))
            list << id;
    }
    room->setTag("spqianxin_xin", QVariant::fromValue(list));
    room->addPlayerMark(effect.to, "spspqianxin_target" + effect.from->objectName());
    foreach (ServerPlayer *p, room->getAllPlayers(true))
        room->addPlayerMark(p, "spqianxin_disabled");

    if (room->getDrawPile().length() <= alive)
        room->moveCardsToEndOfDrawpile(effect.from, getSubcards(), "spqianxin");
    else {
        QStringList choices;
        int n = 1;
        int len = room->getDrawPile().length();
        while (n * alive <= len) {
            choices << QString::number(n * alive);
            n++;
        }
        if (choices.isEmpty()) return;
        QString choice = room->askForChoice(effect.from, "spqianxin", choices.join("+"));
        room->moveCardsInToDrawpile(effect.from, this, "spqianxin", choice.toInt());
    }
}

class SpQianxinVS : public ViewAsSkill
{
public:
    SpQianxinVS() : ViewAsSkill("spqianxin")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !to_select->isEquipped();
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SpQianxinCard") && player->getMark("spqianxin_disabled") == 0;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        SpQianxinCard *card = new SpQianxinCard;
        card->addSubcards(cards);
        return card;
    }
};

class SpQianxin : public TriggerSkill
{
public:
    SpQianxin() : TriggerSkill("spqianxin")
    {
        events << EventPhaseStart << CardsMoveOneTime << EventPhaseChanging;
        view_as_skill = new SpQianxinVS;
        global = true;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseChanging)
            return 0;
        else
            return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Discard) return false;
            if (player->getMark("spqianxin-Clear") <= 0) return false;
            room->setPlayerMark(player, "spqianxin-Clear", 0);
            foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this)) continue;
                if (player->getMark("spspqianxin_target" + p->objectName()) <= 0) continue;
                if (room->getTag("spqianxin_xin").toList().isEmpty())
                    room->setPlayerMark(player, "spspqianxin_target" + p->objectName(), 0);
                QStringList choices;
                choices << "draw";
                if (player->getMaxCards() > 0)
                    choices << "maxcards";
                if (choices.isEmpty()) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(p));

                LogMessage log;
                log.type = "#FumianFirstChoice";
                log.from = player;
                log.arg = "spqianxin:" + choice;
                room->sendLog(log);

                if ( choice == "draw") {
                    if (p->getHandcardNum() < 4)
                        p->drawCards(4 - p->getHandcardNum(), objectName());
                } else
                    room->addMaxCards(player, -2);
            }
        } else if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.from && move.from_places.contains(Player::DrawPile)) {
                QVariantList list = room->getTag("spqianxin_xin").toList();
                QList<int> ids = VariantList2IntList(list);
                foreach (int id, move.card_ids) {
                    if (ids.contains(id)) {
                        ids.removeOne(id);
                        if (move.to && move.to->isAlive() && move.to_place == Player::PlaceHand) {
                            QVariantList get = room->getTag("spqianxin_xin_get").toList();
                            if (!get.contains(QVariant(id))) {
                                get << id;
                            }
                            room->setTag("spqianxin_xin_get", QVariant::fromValue(get));
                            ServerPlayer *to = room->findPlayerByObjectName(move.to->objectName());
                            if (to && !to->isDead())
                                room->addPlayerMark(to, "spqianxin-Clear");
                        }
                    }
                }
                QVariantList new_list = IntList2VariantList(ids);
                room->setTag("spqianxin_xin", QVariant::fromValue(new_list));
                if (ids.isEmpty()) {
                    room->removeTag("spqianxin_xin");
                    foreach (ServerPlayer *p, room->getAllPlayers(true))
                        room->setPlayerMark(p, "spqianxin_disabled", 0);
                }
            }
            if (move.from && move.from->isAlive() && move.from_places.contains(Player::PlaceHand)) {
                QVariantList get = room->getTag("spqianxin_xin_get").toList();
                QList<int> ids = VariantList2IntList(get);
                ServerPlayer *from = room->findPlayerByObjectName(move.from->objectName());
                if (!from || from->isDead()) return false;
                foreach (int id, move.card_ids) {
                    if (ids.contains(id)) {
                        ids.removeOne(id);
                        room->removePlayerMark(from, "spqianxin-Clear");
                    }
                }
                QVariantList new_list = IntList2VariantList(ids);
                room->setTag("spqianxin_xin_get", QVariant::fromValue(new_list));
            }
        } else if (event == EventPhaseChanging){
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            room->removeTag("spqianxin_xin_get");
        }
        return false;
    }
};

class Zhenxing : public TriggerSkill
{
public:
    Zhenxing() : TriggerSkill("zhenxing")
    {
        events << EventPhaseStart << Damaged;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
        }
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());

        QStringList choices;
        choices << "1" << "2" << "3";
        QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
        QList<int> views = room->getNCards(choice.toInt(), false);
        room->returnToTopDrawPile(views);

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.arg = choice;
        log.card_str = IntList2StringList(views).join("+");
        room->sendLog(log, player);
        log.type = "#ViewDrawPile";
        room->sendLog(log, room->getOtherPlayers(player, true));

        QStringList suits, duplication;
        foreach (int id, views) {
            QString suit = Sanguosha->getCard(id)->getSuitString();
            if (!suits.contains(suit))
                suits << suit;
            else
                duplication << suit;
        }

        QList<int> enabled, disabled;
        foreach (int id, views) {
            if (duplication.contains(Sanguosha->getCard(id)->getSuitString()))
                disabled << id;
            else
                enabled << id;
        }

        if (enabled.isEmpty()) {
            room->fillAG(views, player);
            room->askForAG(player, views, true, objectName());
            room->clearAG(player);
            return false;
        }
        room->fillAG(views, player, disabled);
        if (!player->getAI() && enabled.length() == 1)
            room->getThread()->delay(1000);
        int id = room->askForAG(player, enabled, false, objectName());
        room->clearAG(player);
        room->obtainCard(player, id, false);
        return false;
    }
};

MobileSpQianxinCard::MobileSpQianxinCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void MobileSpQianxinCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> ids = getSubcards();
    QList<ServerPlayer *> players = room->getOtherPlayers(source);

    int n = 0;
    QList<CardsMoveStruct> moves;
    while (n < 2) {
        if (ids.isEmpty() || players.isEmpty()) break;

        int id = ids.at(qrand() % ids.length());
        ids.removeOne(id);

        ServerPlayer *to = players.at(qrand() % players.length());
        players.removeOne(to);

        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), to->objectName(), "mobilespqianxin", QString());
        CardsMoveStruct move(QList<int>() << id, to, Player::PlaceHand, reason);
        moves << move;
    }
    if (moves.isEmpty()) return;
    room->moveCardsAtomic(moves, false);
}

class MobileSpQianxinVS : public ViewAsSkill
{
public:
    MobileSpQianxinVS() : ViewAsSkill("mobilespqianxin")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped()) return false;
        int n = Self->getAliveSiblings().length();
        n = qMin(2, n);
        return selected.length() < n;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileSpQianxinCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        MobileSpQianxinCard *card = new MobileSpQianxinCard;
        card->addSubcards(cards);
        return card;
    }
};

class MobileSpQianxin : public PhaseChangeSkill
{
public:
    MobileSpQianxin() : PhaseChangeSkill("mobilespqianxin")
    {
        view_as_skill = new MobileSpQianxinVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive() && target->getPhase() == Player::RoundStart && !target->tag["mobilespqianxin_xin"].toList().isEmpty();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        player->tag.remove("mobilespqianxin_xin");
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;
            QStringList choices;
            choices << "draw";
            if (player->getMaxCards() > 0)
                choices << "maxcards";
            QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(p));
            LogMessage log;
            log.type = "#FumianFirstChoice";
            log.from = player;
            log.arg = "mobilespqianxin:" + choice;
            room->sendLog(log);

            if (choice == "draw")
                p->drawCards(2, objectName());
            else
                room->addMaxCards(player, -2);
        }
        return false;
    }
};

class MobileSpQianxinMove : public TriggerSkill
{
public:
    MobileSpQianxinMove() : TriggerSkill("#mobilespqianxin-move")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from && move.from_places.contains(Player::PlaceHand) && move.to && move.to_place == Player::PlaceHand
                && move.reason.m_skillName == "mobilespqianxin") {
            QVariantList xin = move.to->tag["mobilespqianxin_xin"].toList();
            foreach (int id, move.card_ids) {
                if (xin.contains(id)) continue;
                xin << id;
            }
            move.to->tag["mobilespqianxin_xin"] = xin;
        } else if (move.from && move.from_places.contains(Player::PlaceHand)) {
            QVariantList xin = move.from->tag["mobilespqianxin_xin"].toList();
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceHand) {
                    if (!xin.contains(move.card_ids.at(i))) continue;
                    xin.removeOne(move.card_ids.at(i));
                }
            }
            move.from->tag["mobilespqianxin_xin"] = xin;
        }
        return false;
    }
};

class MobileZhenxing : public TriggerSkill
{
public:
    MobileZhenxing() : TriggerSkill("mobilezhenxing")
    {
        events << EventPhaseStart << Damaged;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
        }
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());

        QList<int> views = room->getNCards(3, false);
        room->returnToTopDrawPile(views);

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.arg = QString::number(3);
        log.card_str = IntList2StringList(views).join("+");
        room->sendLog(log, player);
        log.type = "#ViewDrawPile";
        room->sendLog(log, room->getOtherPlayers(player, true));

        QStringList suits, duplication;
        foreach (int id, views) {
            QString suit = Sanguosha->getCard(id)->getSuitString();
            if (!suits.contains(suit))
                suits << suit;
            else
                duplication << suit;
        }

        QList<int> enabled, disabled;
        foreach (int id, views) {
            if (duplication.contains(Sanguosha->getCard(id)->getSuitString()))
                disabled << id;
            else
                enabled << id;
        }

        if (enabled.isEmpty()) {
            room->fillAG(views, player);
            room->askForAG(player, views, true, objectName());
            room->clearAG(player);
            return false;
        }
        room->fillAG(views, player, disabled);
        if (!player->getAI() && enabled.length() == 1)
            room->getThread()->delay(1000);
        int id = room->askForAG(player, enabled, false, objectName());
        room->clearAG(player);
        room->obtainCard(player, id, false);
        return false;
    }
};

JijieCard::JijieCard()
{
    target_fixed = true;
}

void JijieCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> ids = room->getNCards(1, false, false);
    room->returnToEndDrawPile(ids);

    QList<ServerPlayer *> _source;
    _source.append(source);
    CardsMoveStruct move(ids, NULL, source, Player::PlaceTable, Player::PlaceHand,
        CardMoveReason(CardMoveReason::S_REASON_PREVIEW, source->objectName(), "jijie", QString()));
    QList<CardsMoveStruct> moves;
    moves.append(move);
    room->notifyMoveCards(true, moves, false, _source);
    room->notifyMoveCards(false, moves, false, _source);

    QList<int> jijie_ids = ids;
    CardsMoveStruct jijie_move = room->askForYijiStruct(source, jijie_ids, "jijie", true, false, true, -1, room->getAlivePlayers(),
                                                        CardMoveReason(), QString(), false, false);

    CardsMoveStruct move2(ids, source, NULL, Player::PlaceHand, Player::PlaceTable,
                         CardMoveReason(CardMoveReason::S_REASON_PREVIEW, source->objectName(), "jijie", QString()));
    moves.clear();
    moves.append(move2);
    room->notifyMoveCards(true, moves, false, _source);
    room->notifyMoveCards(false, moves, false, _source);

    ServerPlayer *target = jijie_move.to != NULL ? (ServerPlayer *)jijie_move.to : NULL;
    if (!target)
        target = source;

    CardMoveReason reason(CardMoveReason::S_REASON_PREVIEWGIVE, source->objectName(), "jijie", QString());
    room->obtainCard(target, Sanguosha->getCard(ids.first()), reason, false);
}

class Jijie : public ZeroCardViewAsSkill
{
public:
    Jijie() : ZeroCardViewAsSkill("jijie")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JijieCard");
    }

    const Card *viewAs() const
    {
        return new JijieCard;
    }
};

class Jiyuan : public TriggerSkill
{
public:
    Jiyuan() : TriggerSkill("jiyuan")
    {
        events << Dying << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            if (!dying.who || dying.who->isDead()) return false;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(dying.who))) return false;
            room->broadcastSkillInvoke(objectName());
            dying.who->drawCards(1, objectName());
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from != player && move.reason.m_playerId != player->objectName()) return false;
            if ((move.to && move.to == player) || !move.to || move.to->isDead()) return false;
            if (move.reason.m_reason != CardMoveReason::S_REASON_GIVE && move.reason.m_reason != CardMoveReason::S_REASON_PREVIEWGIVE) return false;
            if (move.to_place != Player::PlaceHand) return false;
            ServerPlayer *to = room->findPlayerByObjectName(move.to->objectName());
            if (!to || to->isDead()) return false;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(to))) return false;
            room->broadcastSkillInvoke(objectName());
            to->drawCards(1, objectName());
        }
        return false;
    }
};

ZiyuanCard::ZiyuanCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void ZiyuanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "ziyuan", QString());
    room->obtainCard(effect.to, this, reason, true);

    if (effect.to->isAlive())
        room->recover(effect.to, RecoverStruct(effect.from));
}

class Ziyuan : public ViewAsSkill
{
public:
    Ziyuan() : ViewAsSkill("ziyuan")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped()) return false;
        int n = to_select->getNumber();
        int num = 0;
        foreach (const Card *c, selected) {
            num = num + c->getNumber();
        }
        return num + n <= 13;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZiyuanCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        int num = 0;
        foreach (const Card *c, cards) {
            num = num + c->getNumber();
        }
        if (num != 13) return NULL;

        ZiyuanCard *card = new ZiyuanCard;
        card->addSubcards(cards);
        return card;
    }
};

class Jugu : public GameStartSkill
{
public:
    Jugu() : GameStartSkill("jugu")
    {
        frequency = Compulsory;
    }

    void onGameStart(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int n = player->getMaxHp();
        if (n <= 0) return;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(n, objectName());
    }
};

class JuguMax : public MaxCardsSkill
{
public:
    JuguMax() : MaxCardsSkill("#jugu-max")
    {
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("jugu"))
            return target->getMaxHp();
        else
            return 0;
    }
};

class Bingzheng : public TriggerSkill
{
public:
    Bingzheng() : TriggerSkill("bingzheng")
    {
        events << EventPhaseEnd;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() != p->getHandcardNum())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@bingzheng-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        QStringList choices;
        if (!target->isKongcheng())
            choices << "discard";
        choices << "draw";
        QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(target));
        if (choice == "draw")
            target->drawCards(1, objectName());
        else {
            if (!target->canDiscard(target, "h")) return false;
            room->askForDiscard(target, objectName(), 1, 1);
        }
        if (target->isAlive() && player->isAlive() && target->getHp() == target->getHandcardNum()) {
            player->drawCards(1, objectName());
            if (player->isNude() || player == target) return false;
            QList<ServerPlayer *> players;
            players << target;
            QList<int> give = player->handCards() + player->getEquipsId();
            room->askForYiji(player, give, objectName(), false, false, true, -1, players, CardMoveReason(),
                             "bingzheng-give:" + target->objectName());
        }
        return false;
    }
};

class SheyanVS : public ZeroCardViewAsSkill
{
public:
    SheyanVS() : ZeroCardViewAsSkill("sheyan")
    {
        response_pattern = "@@sheyan!";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new ExtraCollateralCard;
    }
};

class Sheyan : public TriggerSkill
{
public:
    Sheyan() : TriggerSkill("sheyan")
    {
        events << TargetConfirming;
        view_as_skill = new SheyanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isNDTrick() || !use.to.contains(player)) return false;

        room->setCardFlag(use.card, "sheyan_distance");
        QList<ServerPlayer *> ava;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (use.card->isKindOf("AOE") && p == use.from) continue;
            if (use.to.contains(p) || room->isProhibited(use.from, p, use.card)) continue;
            if (use.card->targetFixed())
                ava << p;
            else {
                if (use.card->targetFilter(QList<const Player *>(), p, use.from))
                    ava << p;
            }
        }

        QStringList choices;
        if (!ava.isEmpty())
            choices << "add";
        if (use.to.length() > 1)
            choices << "remove";
        if (choices.isEmpty()) return false;
        choices << "cancel";

        QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
        if (choice == "cancel") return false;

        if (!use.card->isKindOf("Collateral")) {
            room->setCardFlag(use.card, "-sheyan_distance");
            if (choice == "add") {
                ServerPlayer *target = room->askForPlayerChosen(player, ava, objectName(), "@sheyan-add:" + use.card->objectName());
                LogMessage log;
                log.type = "#QiaoshuiAdd";
                log.from = player;
                log.to << target;
                log.card_str = use.card->toString();
                log.arg = "sheyan";
                room->sendLog(log);
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                use.to << target;
                room->sortByActionOrder(use.to);
            } else {
                ServerPlayer *target = room->askForPlayerChosen(player, use.to, objectName(), "@sheyan-remove:" + use.card->objectName());
                LogMessage log;
                log.type = "#QiaoshuiRemove";
                log.from = player;
                log.to << target;
                log.card_str = use.card->toString();
                log.arg = "sheyan";
                room->sendLog(log);
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                use.to.removeOne(target);
            }
        } else {
            if (choice == "add") {
                QStringList tos;
                foreach(ServerPlayer *t, use.to)
                    tos.append(t->objectName());

                room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                room->setPlayerProperty(player, "extra_collateral_current_targets", tos);
                room->askForUseCard(player, "@@sheyan!", "@sheyan:" + use.card->objectName());
                room->setPlayerProperty(player, "extra_collateral", QString());
                room->setPlayerProperty(player, "extra_collateral_current_targets", QString("+"));
                room->setCardFlag(use.card, "-sheyan_distance");

                bool extra = false;
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("ExtraCollateralTarget")) {
                        room->setPlayerFlag(p,"-ExtraCollateralTarget");
                        extra = true;
                        LogMessage log;
                        log.type = "#QiaoshuiAdd";
                        log.from = player;
                        log.to << p;
                        log.card_str = use.card->toString();
                        log.arg = "sheyan";
                        room->sendLog(log);
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                        room->notifySkillInvoked(player, objectName());
                        room->broadcastSkillInvoke(objectName());

                        use.to.append(p);
                        room->sortByActionOrder(use.to);
                        ServerPlayer *victim = p->tag["collateralVictim"].value<ServerPlayer *>();
                        if (victim) {
                            LogMessage log;
                            log.type = "#CollateralSlash";
                            log.from = player;
                            log.to << victim;
                            room->sendLog(log);
                            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, p->objectName(), victim->objectName());
                        }
                    }
                }

                if (!extra) {
                    ServerPlayer *target = ava.at(qrand() % ava.length());
                    QList<ServerPlayer *> victims;
                    foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                        if (target->canSlash(p)
                            && (!(p == use.from && p->hasSkill("kongcheng") && p->isLastHandCard(use.card, true)))) {
                            victims << p;
                        }
                    }
                    Q_ASSERT(!victims.isEmpty());
                    ServerPlayer *victim = victims.at(qrand() % victims.length());
                    target->tag["collateralVictim"] = QVariant::fromValue(victim);
                    LogMessage log;
                    log.type = "#QiaoshuiAdd";
                    log.from = player;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = "sheyan";
                    room->sendLog(log);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName());

                    use.to.append(target);
                    room->sortByActionOrder(use.to);

                    LogMessage newlog;
                    newlog.type = "#CollateralSlash";
                    newlog.from = player;
                    newlog.to << victim;
                    room->sendLog(newlog);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());
                }
            } else {
                ServerPlayer *target = room->askForPlayerChosen(player, use.to, objectName(), "@sheyan-remove:" + use.card->objectName());
                LogMessage log;
                log.type = "#QiaoshuiRemove";
                log.from = player;
                log.to << target;
                log.card_str = use.card->toString();
                log.arg = "sheyan";
                room->sendLog(log);
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                use.to.removeOne(target);
            }
        }
        data = QVariant::fromValue(use);
        return false;
    }
};

class SheyanTargetMod : public TargetModSkill
{
public:
    SheyanTargetMod() : TargetModSkill("#sheyan-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("sheyan_distance") && card->isNDTrick())
            return 1000;
        else
            return 0;
    }
};

FumanCard::FumanCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool FumanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getMark("fuman_target-PlayClear") <= 0;
}

void FumanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.to, "fuman_target-PlayClear");
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "fuman", QString());
    room->obtainCard(effect.to, this, reason, true);
    room->addPlayerMark(effect.to, "fuman_" + QString::number(getSubcards().first()) + effect.from->objectName());
}

class FumanVS : public OneCardViewAsSkill
{
public:
    FumanVS() : OneCardViewAsSkill("fuman")
    {
        filter_pattern = "Slash";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        foreach (const Player *p, player->getAliveSiblings()) {
            if (p->getMark("fuman_target-PlayClear") <= 0)
                return true;
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        FumanCard *c = new FumanCard();
        c->addSubcard(originalCard);
        return c;
    }
};

class Fuman : public TriggerSkill
{
public:
    Fuman() : TriggerSkill("fuman")
    {
        events << CardUsed << CardResponded << EventPhaseChanging;
        view_as_skill = new FumanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (QString mark, player->getMarkNames()) {
                if (mark.startsWith("fuman_") && player->getMark(mark) > 0)
                    room->setPlayerMark(player, mark ,0);
            }
        } else {
            const Card *card = NULL;
            if (event == CardUsed) {
                card = data.value<CardUseStruct>().card;
            } else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (card == NULL || card->isKindOf("SkillCard")) return false;

            QList<int> ids;
            if (card->isVirtualCard())
                ids = card->getSubcards();
            else
                ids << card->getEffectiveId();
            if (ids.isEmpty()) return false;

            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!p->hasSkill(this) || p->isDead()) continue;
                foreach (int id, ids) {
                    if (player->getMark("fuman_" + QString::number(id) + p->objectName()) > 0) {
                        room->setPlayerMark(player, "fuman_" + QString::number(id) + p->objectName(), 0);
                        room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                        p->drawCards(1, objectName());
                    }
                }
            }
        }
        return false;
    }
};

TunanCard::TunanCard()
{
}

void TunanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    QList<int> ids = room->getNCards(1, false);
    room->returnToTopDrawPile(ids);

    LogMessage log;
    log.type = "$ViewDrawPile";
    log.from = effect.to;
    log.arg = QString::number(1);
    log.card_str = IntList2StringList(ids).join("+");
    room->sendLog(log, effect.to);

    room->fillAG(ids, effect.to);
    room->askForAG(effect.to, ids, true, "tunan");

    QStringList choices;
    QList<ServerPlayer *> players, slash_to;
    const Card *card = Sanguosha->getCard(ids.first());
    card->setFlags("tunan_distance");
    if (effect.to->canUse(card))
        choices << "use";
    card->setFlags("-tunan_distance");

    Slash *slash = new Slash(card->getSuit(), card->getNumber());
    slash->addSubcard(card);
    slash->setSkillName("_tunan");
    slash->deleteLater();

    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (effect.to->canSlash(p, slash, true))
            slash_to << p;
    }
    if (!slash_to.isEmpty())
        choices << "slash";

    if (choices.isEmpty()) {
        room->clearAG(effect.to);
        return;
    }

    QString choice = room->askForChoice(effect.to, "tunan", choices.join("+"), QVariant::fromValue(card));
    room->clearAG(effect.to);
    room->addPlayerMark(effect.to, "tunan_id-PlayClear", ids.first() + 1);

    ServerPlayer *target = NULL;
    if (choice == "use") {
        if (card->targetFixed())
            room->useCard(CardUseStruct(card, effect.to, effect.to), false);
        else {
            if (!room->askForUseCard(effect.to, "@@tunan1!", "@tunan1:" + card->objectName(), 1)) {
                if (card->targetFixed())
                    target = effect.to;
                else
                    target = players.at(qrand() % players.length());

                if (target != NULL) {
                    if (card->isKindOf("Collateral")) {
                        QList<ServerPlayer *> victims;
                        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                            if (target->canSlash(p, NULL, true))
                                victims << p;
                        }
                        Q_ASSERT(!victims.isEmpty());
                        target->tag["collateralVictim"] = QVariant::fromValue((victims.at(qrand() % victims.length())));
                    }
                    room->useCard(CardUseStruct(card, effect.to, target), false);
                }
            }
        }
    } else {
        if (!room->askForUseCard(effect.to, "@@tunan2!", "@tunan2", 2)) {
            target = slash_to.at(qrand() % slash_to.length());
            if (target != NULL)
                room->useCard(CardUseStruct(slash, effect.to, target), false);
        }
    }
    if (card->hasFlag("tunan_distance"))
        card->setFlags("-tunan_distance");
    room->setPlayerMark(effect.to, "tunan_id-PlayClear", 0);
}

class Tunan : public ZeroCardViewAsSkill
{
public:
    Tunan() : ZeroCardViewAsSkill("tunan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TunanCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tunan1!" || pattern == "@@tunan2!";
    }

    const Card *viewAs() const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@tunan1!") {
            int id = Self->getMark("tunan_id-PlayClear") - 1;
            if (id < 0) return NULL;
            const Card *card = Sanguosha->getEngineCard(id);
            card->setFlags("tunan_distance");
            return card;
        } else if (pattern == "@@tunan2!") {
            int id = Self->getMark("tunan_id-PlayClear") - 1;
            if (id < 0) return NULL;
            const Card *card = Sanguosha->getEngineCard(id);
            Slash *slash = new Slash(card->getSuit(), card->getNumber());
            slash->addSubcard(card);
            slash->setSkillName("_tunan");
            return slash;
        } else
            return new TunanCard;
    }
};

class TunanTargetMod : public TargetModSkill
{
public:
    TunanTargetMod() : TargetModSkill("#tunan-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("tunan_distance"))
            return 1000;
        else
            return 0;
    }
};

class Bijing : public TriggerSkill
{
public:
    Bijing() : TriggerSkill("bijing")
    {
        events << EventPhaseStart << CardsMoveOneTime << EventLoseSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() == Player::Finish && player->hasSkill(this)) {
                if (player->isKongcheng()) return false;
                const Card *card = room->askForCard(player, ".|.|.|hand", "bijing-invoke", data, Card::MethodNone);
                if (!card) return false;
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());

                int id = card->getSubcards().first();
                QVariantList bijing = player->tag["BijingIds"].toList();
                if (!bijing.contains(QVariant(id)))
                    bijing << id;
                player->tag["BijingIds"] = bijing;
            } else if (player->getPhase() == Player::Start && player->hasSkill(this)) {
                QVariantList bijing = player->tag["BijingIds"].toList();
                QList<int> ids = VariantList2IntList(bijing);
                player->tag.remove("BijingIds");
                if (ids.isEmpty()) return false;

                DummyCard *dummy = new DummyCard();
                foreach (int id, player->handCards()) {
                    if (ids.contains(id))
                        dummy->addSubcard(id);
                }
                if (dummy->subcardsLength() > 0) {
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    room->throwCard(dummy, player, NULL);
                }
                delete dummy;
            } else if (player->getPhase() == Player::Discard) {
                int n = player->getMark("bijing_lose-Clear");
                if (n <= 0) return false;
                room->setPlayerMark(player, "bijing_lose-Clear", 0);
                QList<ServerPlayer *> losers;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasSkill(this)) {
                        int n = p->getMark("bijing_lose_from-Clear");
                        if (n > 0) {
                            for (int i = 0; i < n; i++) {
                                losers << p;
                            }
                            room->setPlayerMark(p, "bijing_lose_from-Clear", 0);
                        }
                    }
                }
                if (losers.isEmpty()) return false;

                int num = qMin(n, losers.length());
                for (int i = 0; i < num; i++) {
                    if (player->isDead()) return false;
                    foreach (ServerPlayer *p, losers) {
                        if (p->isDead() || !p->hasSkill(this))
                            losers.removeOne(p);
                    }
                    if (losers.isEmpty()) return false;
                    if (player->isNude()) {
                        LogMessage log;
                        log.type = "#BijingKongcheng";
                        log.from = losers.first();
                        log.to << player;
                        log.arg = objectName();
                        room->sendLog(log);
                        room->notifySkillInvoked(losers.first(), objectName());
                        room->broadcastSkillInvoke(objectName());
                        return false;
                    }
                    room->sendCompulsoryTriggerLog(losers.first(), objectName(), true, true);
                    losers.removeFirst();
                    room->askForDiscard(player, objectName(), 2, 2, false, true);
                    if (!player->canDiscard(player, "he")) return false;
                }
          }
        } else if (event == EventLoseSkill) {
            if (data.toString() != objectName()) return false;
            player->tag.remove("BijingIds");
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && player->hasSkill(this) && player->getPhase() == Player::NotActive &&
                    move.from_places.contains(Player::PlaceHand)) {
                ServerPlayer *current = room->getCurrent();
                if (!current || current->isDead()) return false;
                QVariantList bijing = player->tag["BijingIds"].toList();
                QList<int> ids = VariantList2IntList(bijing);
                foreach (int id, move.card_ids) {
                    if (ids.contains(id)) {
                        ids.removeOne(id);
                        room->addPlayerMark(player, "bijing_lose_from-Clear");
                        room->addPlayerMark(current, "bijing_lose-Clear");
                    }
                }
                QVariantList new_bijing = IntList2VariantList(ids);
                player->tag["BijingIds"] = new_bijing;
            }
        }
        return false;
    }
};

class Dianhu : public TriggerSkill
{
public:
    Dianhu() : TriggerSkill("dianhu")
    {
        events << Damage << HpRecover;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to->isDead() || !damage.from->hasSkill(this) || damage.damage <= 0) return false;
            ServerPlayer *target = damage.from->tag["DianhuTarget"].value<ServerPlayer *>();
            if (target && target->isAlive() && target == damage.to) {
                room->sendCompulsoryTriggerLog(damage.from, objectName(), true, true);
                damage.from->drawCards(1, objectName());
            }
        } else {
            RecoverStruct recover = data.value<RecoverStruct>();
            if (recover.recover <= 0) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (!p->hasSkill(this) || p->isDead()) continue;
                ServerPlayer *target = p->tag["DianhuTarget"].value<ServerPlayer *>();
                if (target && target->isAlive() && target == player) {
                    room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                    p->drawCards(1, objectName());
                }
            }
        }
        return false;
    }
};

class DianhuTarget : public GameStartSkill
{
public:
    DianhuTarget() : GameStartSkill("#dianhu-target")
    {
        frequency = Compulsory;
    }

    void onGameStart(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), "dianhu", "@dianhu-choose", false, true);
        room->broadcastSkillInvoke("dianhu");
        player->tag["DianhuTarget"] = QVariant::fromValue(target);
        room->addPlayerMark(target, "&dianhu");
    }
};

JianjiCard::JianjiCard()
{
}

void JianjiCard::onEffect(const CardEffectStruct &effect) const
{
    QList<int> ids = effect.to->drawCardsList(1, "jianji");
    if (ids.isEmpty()) return;
    if (effect.to->isDead()) return;

    Room *room = effect.from->getRoom();
    int id = ids.first();
    if (room->getCardPlace(id) != Player::PlaceHand || room->getCardOwner(id) != effect.to) return;

    const Card *card = Sanguosha->getCard(id);
    if (!effect.to->canUse(card)) return;

    room->addPlayerMark(effect.to, "jianji_id-PlayClear", id + 1);
    room->askForUseCard(effect.to, "@@jianji", "@jianji:" + card->objectName());
    room->setPlayerMark(effect.to, "jianji_id-PlayClear", 0);
}

class Jianji : public ZeroCardViewAsSkill
{
public:
    Jianji() : ZeroCardViewAsSkill("jianji")
    {
        response_pattern = "@@jianji";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JianjiCard");
    }

    const Card *viewAs() const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@jianji") {
            int id = Self->getMark("jianji_id-PlayClear") - 1;
            if (id < 0) return NULL;
            const Card *card = Sanguosha->getEngineCard(id);
            return card;
        }
        return new JianjiCard;
    }
};

class Jili : public TriggerSkill
{
public:
    Jili() : TriggerSkill("jili")
    {
        events << CardUsed << CardResponded;
        global = true;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == CardUsed)
            card = data.value<CardUseStruct>().card;
        else
            card = data.value<CardResponseStruct>().m_card;
        if (card == NULL || card->isKindOf("SkillCard")) return false;

        room->addPlayerMark(player, "jili-Clear");
        int attackrange = player->getAttackRange();
        if (player->getMark("jili-Clear") == attackrange && player->hasSkill(this) && player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());
            player->drawCards(attackrange, objectName());
        }
        return false;
    }
};

YizanCard::YizanCard()
{
    target_fixed = true;
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
}

bool YizanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    const Card *card = Self->tag.value("yizan").value<const Card *>();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool YizanCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *card = Self->tag.value("yizan").value<const Card *>();
    return card && card->targetFixed();
}

bool YizanCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *card = Self->tag.value("yizan").value<const Card *>();
    return card && card->targetsFeasible(targets, Self);
}

const Card *YizanCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;
    Room *room = player->getRoom();

    QString to_yizan = user_string;
    if ((user_string.contains("slash") || user_string.contains("Slash")) && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList guhuo_list = Sanguosha->getSlashNames();
        if (guhuo_list.isEmpty())
            guhuo_list << "slash";
        to_yizan = room->askForChoice(player, "yizan_slash", guhuo_list.join("+"));
    }

    Card *use_card = Sanguosha->cloneCard(to_yizan, Card::SuitToBeDecided, -1);
    use_card->setSkillName("yizan");
    use_card->addSubcards(getSubcards());
    use_card->deleteLater();
    return use_card;
}

const Card *YizanCard::validateInResponse(ServerPlayer *player) const
{
    Room *room = player->getRoom();

    QString to_yizan;
    if (user_string == "peach+analeptic") {
        QStringList guhuo_list;
        guhuo_list << "peach";
        if (Sanguosha->hasCard("analeptic"))
            guhuo_list << "analeptic";
        to_yizan = room->askForChoice(player, "yizan_saveself", guhuo_list.join("+"));
    } else if (user_string.contains("slash") || user_string.contains("Slash")) {
        QStringList guhuo_list = Sanguosha->getSlashNames();
        if (guhuo_list.isEmpty())
            guhuo_list << "slash";
        to_yizan = room->askForChoice(player, "yizan_slash", guhuo_list.join("+"));
    } else
        to_yizan = user_string;

    Card *use_card = Sanguosha->cloneCard(to_yizan, Card::SuitToBeDecided, -1);
    use_card->setSkillName("yizan");
    use_card->addSubcards(getSubcards());
    use_card->deleteLater();
    return use_card;
}

class YizanVS : public ViewAsSkill
{
public:
    YizanVS() : ViewAsSkill("yizan")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (pattern.startsWith(".") || pattern.startsWith("@")) return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;
        QStringList patterns = pattern.split("+");
        foreach (QString name, patterns) {
            name = name.toLower();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            if (card->isKindOf("BasicCard"))
                return true;
        }
        patterns = pattern.split(",");
        foreach (QString name, patterns) {
            name = name.toLower();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            if (card->isKindOf("BasicCard"))
                return true;
        }
        return false;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
            if (Self->isCardLimited(to_select, Card::MethodResponse))
                return false;
        } else {
            if (Self->isLocked(to_select))
                return false;
        }
        int level = Self->property("yizan_level").toInt();
        if (level <= 0) {
            if (selected.length() >= 2) return false;
            if (selected.isEmpty()) return true;
            if (selected.first()->isKindOf("BasicCard"))
                return true;
            else
                return to_select->isKindOf("BasicCard");
        } else if (level >= 1) {
            return selected.isEmpty() && to_select->isKindOf("BasicCard");
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int level = Self->property("yizan_level").toInt();
        int n = 2;
        if (level >= 1)
            n = 1;
        if (cards.length() != n) return NULL;
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE
            || Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            YizanCard *card = new YizanCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            card->addSubcards(cards);
            return card;
        }

        const Card *c = Self->tag.value("yizan").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            YizanCard *card = new YizanCard;
            card->setUserString(c->objectName());
            card->addSubcards(cards);
            return card;
        }
        return NULL;
    }
};

class Yizan : public TriggerSkill
{
public:
    Yizan() : TriggerSkill("yizan")
    {
        events << PreCardResponded << PreCardUsed;
        view_as_skill = new YizanVS;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("yizan", true, false);
    }

    int getPriority()
    {
        return 5;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == PreCardResponded)
            card = data.value<CardResponseStruct>().m_card;
        else
            card = data.value<CardUseStruct>().card;
        if (card == NULL || card->isKindOf("SkillCard") || card->getSkillName() != "yizan") return false;
        room->addPlayerMark(player, "&yizan");
        return false;
    }
};

class Longyuan : public PhaseChangeSkill
{
public:
    Longyuan() : PhaseChangeSkill("longyuan")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start) return false;
        if (player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMark("&yizan") < 3) return false;
        LogMessage log;
        log.type = "#LongyuanWake";
        log.from = player;
        log.arg = QString::number(player->getMark("&yizan"));
        log.arg2 = objectName();
        room->sendLog(log);
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(player, objectName());
        room->doSuperLightbox("zhaotongzhaoguang", "longyuan");
        room->setPlayerMark(player, "longyuan", 1);
        room->setPlayerProperty(player, "yizan_level", 1);
        if (room->changeMaxHpForAwakenSkill(player, 0)) {
            QString translate = Sanguosha->translate(":yizan2");
            room->changeTranslation(player, "yizan", translate);
        }
        return false;
    }
};

class Renshi : public TriggerSkill
{
public:
    Renshi() : TriggerSkill("renshi")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash") || damage.damage <= 0) return false;
        if (!player->isWounded()) return false;
        LogMessage log;
        log.type = "#RenshiPrevent";
        log.from = player;
        log.to << damage.from;
        log.arg = objectName();
        log.arg2 = QString::number(damage.damage);
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        if (room->CardInTable(damage.card))
            player->obtainCard(damage.card, true);
        room->loseMaxHp(player);
        return true;
    }
};

class Huaizi : public MaxCardsSkill
{
public:
    Huaizi() : MaxCardsSkill("huaizi")
    {
    }

    int getFixed(const Player *target) const
    {
        if (target->hasSkill("huaizi"))
            return target->getMaxHp();
        else
            return -1;
    }
};

WuyuanCard::WuyuanCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void WuyuanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "wuyuan", QString());
    room->obtainCard(effect.to, this, reason, true);

    const Card *card = Sanguosha->getCard(getSubcards().first());
    bool red = card->isRed() ? true : false;
    bool nature = (card->isKindOf("Slash") && card->objectName() != "slash") ? true : false;

    room->recover(effect.from, RecoverStruct(effect.from));
    int n = 1;
    if (nature)
        n = 2;
    effect.to->drawCards(n, "wuyuan");
    if (red)
        room->recover(effect.to, RecoverStruct(effect.from));
}

class Wuyuan : public OneCardViewAsSkill
{
public:
    Wuyuan() : OneCardViewAsSkill("wuyuan")
    {
        filter_pattern = "Slash";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("WuyuanCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        WuyuanCard *card = new WuyuanCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Yuxu : public TriggerSkill
{
public:
    Yuxu() : TriggerSkill("yuxu")
    {
        events << PreCardUsed << PreCardResponded << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (event == CardFinished) {
            if (!player->hasSkill(this)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (use.card->hasFlag("yuxu_ji")) {
                room->setCardFlag(use.card, "-yuxu_ji");
                if (!player->askForSkillInvoke(this, data)) return false;
                room->broadcastSkillInvoke(objectName());
                player->drawCards(1, objectName());
            } else if (use.card->hasFlag("yuxu_ou")) {
                room->setCardFlag(use.card, "-yuxu_ou");
                if (player->isNude()) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->askForDiscard(player, objectName(), 1, 1, false, true);
            }
        } else {
            const Card *card = NULL;
            if (event == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct resp = data.value<CardResponseStruct>();
                if (!resp.m_isUse) return false;
                card = data.value<CardResponseStruct>().m_card;
            }
            if (card == NULL || card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "yuxu_jiou-PlayClear");
            int n = player->getMark("yuxu_jiou-PlayClear") % 2;
            if (n == 0)
                room->setCardFlag(card, "yuxu_ou");
            else
                room->setCardFlag(card, "yuxu_ji");
        }
        return false;
    }
};

class Shijian : public TriggerSkill
{
public:
    Shijian() : TriggerSkill("shijian")
    {
        events << PreCardUsed << PreCardResponded << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (use.card->hasFlag("shijian_second")) {
                room->setCardFlag(use.card, "-shijian_second");
                foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
                    if (p->isAlive() && p->hasSkill(this) && p != player && !p->isNude()) {
                        if (room->askForCard(p, "..", "@shijian-discard:" + player->objectName(), QVariant::fromValue(player), objectName())) {
                            room->broadcastSkillInvoke(objectName());
                            room->acquireOneTurnSkills(player, QString(), "yuxu");
                        }
                    }
                }
            }
        } else {
            const Card *card = NULL;
            if (event == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct resp = data.value<CardResponseStruct>();
                if (!resp.m_isUse) return false;
                card = data.value<CardResponseStruct>().m_card;
            }
            if (card == NULL || card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "shijian-PlayClear");
            int n = player->getMark("shijian-PlayClear");
            if (n == 2)
                room->setCardFlag(card, "shijian_second");
        }
        return false;
    }
};

class SpManyi : public TriggerSkill
{
public:
    SpManyi() : TriggerSkill("spmanyi")
    {
        events << CardEffected;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardEffectStruct effect = data.value<CardEffectStruct>();
        if (effect.card->isKindOf("SavageAssault")) {
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(player, objectName());
            LogMessage log;
            log.type = "#SkillNullify";
            log.from = player;
            log.arg = objectName();
            log.arg2 = "savage_assault";
            room->sendLog(log);
            return true;
        }
        return false;
    }
};

class Mansi : public TriggerSkill
{
public:
    Mansi() : TriggerSkill("mansi")
    {
        events << CardFinished << PreDamageDone;
        frequency = Frequent;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("SavageAssault")) return false;
            //QStringList names = use.card->tag["MansiDamage"].toStringList();  AI无法获取到card的tag
            //use.card->removeTag("MansiDamage");
            QStringList names = room->getTag("MansiDamage" + use.card->toString()).toStringList();
            room->removeTag("MansiDamage" + use.card->toString());
            if (names.isEmpty()) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead() || !p->hasSkill(this)) continue;
                if (!p->askForSkillInvoke(objectName())) continue;
                room->broadcastSkillInvoke(objectName());
                p->drawCards(names.length(), objectName());
            }
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("SavageAssault")) return false;
            //QStringList names = damage.card->tag["MansiDamage"].toStringList();
            QStringList names = room->getTag("MansiDamage" + damage.card->toString()).toStringList();
            if (names.contains(damage.to->objectName())) return false;
            names << damage.to->objectName();
            //damage.card->tag["MansiDamage"] = names;
            room->setTag("MansiDamage" + damage.card->toString(), names);
        }
        return false;
    }
};

class Souying : public TriggerSkill
{
public:
    Souying() : TriggerSkill("souying")
    {
        events << DamageCaused;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *from = damage.from;
        ServerPlayer *to = damage.to;
        if (!from || !to || from->isDead() || to->isDead()) return false;
        room->addPlayerMark(from, "souying_damage_ " + to->objectName() + "-Clear");
        QList<ServerPlayer *> players;
        if (from->hasSkill(this) && to->isMale() && from->getMark("souying_damage_ " + to->objectName() + "-Clear") == 2)
            players << from;
        if (from->isMale() && to->hasSkill(this) && from->getMark("souying_damage_ " + to->objectName() + "-Clear") == 2 && !players.contains(to))
            players << to;
        if (players.isEmpty()) return false;
        room->sortByActionOrder(players);

        foreach (ServerPlayer *p, players) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (!p->canDiscard(p, "h") || p->getMark("souying_used-Clear") > 0) continue;
            if (!room->askForCard(p, ".", "souying-invoke:" + to->objectName(), data, objectName())) continue;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(p, "souying_used-Clear");
            if (p == from) {
                LogMessage log;
                log.type = "#SouyingAdd";
                log.from = from;
                log.to << to;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(++damage.damage);
                room->sendLog(log);
            } else if (p == to) {
                LogMessage log;
                log.type = (damage.damage > 1) ? "#SouyingReduce" : "#SouyingPrevent";
                log.from = from;
                log.to << to;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(--damage.damage);
                room->sendLog(log);
                if (damage.damage <= 0)
                    return true;
            }
        }
        data = QVariant::fromValue(damage);
        return false;
    }
};

class Zhanyuan : public PhaseChangeSkill
{
public:
    Zhanyuan() : PhaseChangeSkill("zhanyuan")
    {
        frequency = Wake;
        waked_skills = "xili";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        int mark = player->getMark("&zhanyuan_num") + player->getMark("zhanyuan_num");
        if (mark <= 7) return false;
        LogMessage log;
        log.type = "#ZhanyuanWake";
        log.from = player;
        log.arg = objectName();
        log.arg2 = QString::number(mark);
        room->sendLog(log);
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("huaman", objectName());
        room->addPlayerMark(player, objectName());
        if (room->changeMaxHpForAwakenSkill(player, 1)) {
            QList<ServerPlayer *> males;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isMale())
                    males << p;
            }
            if (males.isEmpty()) return false;
            ServerPlayer *male = room->askForPlayerChosen(player, males, objectName(), "@zhanyuan-invoke", true);
            if (!male) return false;
            room->doAnimate(1, player->objectName(), male->objectName());
            QList<ServerPlayer *> players;
            players << player;
            if (!players.contains(male))
                players << male;
            if (players.isEmpty()) return false;
            room->sortByActionOrder(players);
            foreach (ServerPlayer *p, players) {
                if (p->hasSkill("xili", true)) continue;
                room->handleAcquireDetachSkills(p, "xili");
            }
            if (player->hasSkill("mansi", true))
                room->handleAcquireDetachSkills(player, "-mansi");
        }
        return false;
    }
};


class ZhanyuanRecord : public TriggerSkill
{
public:
    ZhanyuanRecord(const QString &zhanyuan) : TriggerSkill("#" + zhanyuan), zhanyuan(zhanyuan)
    {
        events << CardsMoveOneTime;
        //frequency = Wake;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        QString mansi = "mansi";
        if (zhanyuan == "secondzhanyuan") mansi = "secondmansi";
        if (move.to && move.to->isAlive() && move.to == player && move.to_place == Player::PlaceHand && move.reason.m_skillName == mansi) {
            if (player->hasSkill(zhanyuan, true))
                room->addPlayerMark(player, "&" + zhanyuan + "_num", move.card_ids.length());
            else
                room->addPlayerMark(player, zhanyuan + "_num", move.card_ids.length());
        }
        return false;
    }
private:
    QString zhanyuan;
};

class Xili : public TriggerSkill
{
public:
    Xili() : TriggerSkill("xili")
    {
        events << TargetSpecified << DamageCaused << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.from->isDead() || !use.from->hasSkill(this, true) || use.from->getPhase() == Player::NotActive || !use.card->isKindOf("Slash")) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(use.from)) {
                if (p->isDead() || !p->hasSkill(this, true) || !p->canDiscard(p, "h") || p->getPhase() != Player::NotActive) continue;
                if (!room->askForCard(p, ".", "xili-invoke", data, objectName())) continue;
                room->broadcastSkillInvoke(objectName());
                //int n = use.card->tag["XiliDamage"].toInt();
                //use.card->tag["XiliDamage"] = n + 1;
                int n = room->getTag("XiliDamage" + use.card->toString()).toInt();
                room->setTag("XiliDamage" + use.card->toString(), n + 1);
            }
        } else if (event == CardFinished) {
              CardUseStruct use = data.value<CardUseStruct>();
              if (use.card->isKindOf("SkillCard")) return false;
              //use.card->removeTag("XiliDamage");
              room->removeTag("XiliDamage" + use.card->toString());
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || damage.to->isDead()) return false;
            //int n = damage.card->tag["XiliDamage"].toInt(); //ai操作时无法获取这个tag
            int n = room->getTag("XiliDamage" + damage.card->toString()).toInt();
            if (n <= 0) return false;
            damage.damage += n;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

SecondMansiCard::SecondMansiCard()
{
    mute = true;
    target_fixed = true;
}

void SecondMansiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    if (card_use.from->isKongcheng()) return;
    SavageAssault *sa = new SavageAssault(Card::SuitToBeDecided, 0);
    foreach (const Card *c, card_use.from->getHandcards())
        sa->addSubcard(c);
    sa->setSkillName("secondmansi");
    sa->deleteLater();
    if (!sa->isAvailable(card_use.from)) return;
    room->useCard(CardUseStruct(sa, card_use.from, QList<ServerPlayer *>()), true);
}

class SecondMansiVS : public ZeroCardViewAsSkill
{
public:
    SecondMansiVS() : ZeroCardViewAsSkill("secondmansi")
    {
    }

    const Card *viewAs() const
    {
        if (Self->isKongcheng()) return NULL;
        SavageAssault *sa = new SavageAssault(Card::SuitToBeDecided, 0);
        foreach (const Card *c, Self->getHandcards())
            sa->addSubcard(c);
        sa->setSkillName("secondmansi");
        sa->deleteLater();
        if (!sa->isAvailable(Self)) return NULL;
        //return sa;
        return new SecondMansiCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        SavageAssault *sa = new SavageAssault(Card::SuitToBeDecided, 0);
        foreach (const Card *c, player->getHandcards())
            sa->addSubcard(c);
        sa->setSkillName("secondmansi");
        sa->deleteLater();
        if (!sa->isAvailable(player)) return false;
        return !player->isKongcheng() && !player->hasUsed("SecondMansiCard");
    }
};

class SecondMansi : public MasochismSkill
{
public:
    SecondMansi() : MasochismSkill("secondmansi")
    {
        view_as_skill = new SecondMansiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        if (!damage.card || !damage.card->isKindOf("SavageAssault")) return;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
            p->drawCards(1, objectName());
        }
    }
};

class SecondSouying : public TriggerSkill
{
public:
    SecondSouying() : TriggerSkill("secondsouying")
    {
        events << TargetConfirmed;
    }

    bool triggerable(const ServerPlayer *target, Room *room) const
    {
        return target != NULL && room->hasCurrent();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (use.from != player) return false;
        if (use.to.length() != 1 || use.from->isDead()) return false;

        ServerPlayer *first = use.to.first();
        if (first == use.from || first->getMark("secondsouying_num_" + use.from->objectName() + first->objectName() + "-Clear") == 1) return false;

        QList<ServerPlayer *> huamans;
        if (use.from->hasSkill(this))
            huamans << use.from;
        if (first->hasSkill(this))
            huamans << first;
        if (huamans.isEmpty()) return false;
        room->sortByActionOrder(huamans);

        foreach (ServerPlayer *p, huamans) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (p->getMark("secondsouying-Clear") > 0 || !p->canDiscard(p, "he")) return false;

            QString prompt = "@secondsouying-dis:" + use.card->objectName();
            if (p == first)
                prompt = "@secondsouying-dis2:" + use.card->objectName();

            if (!room->askForCard(p, "..", prompt, data, objectName())) continue;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(p, "secondsouying-Clear");

            if (p == use.from) {
                if (!room->CardInTable(use.card)) return false;
                room->obtainCard(use.from, use.card, true);
            } else {
                use.nullified_list << p->objectName();
                data = QVariant::fromValue(use);
            }
        }
        return false;
    }
};

class SecondSouyingRecord : public TriggerSkill
{
public:
    SecondSouyingRecord() : TriggerSkill("#secondsouying-record")
    {
        events << PreCardUsed;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        foreach (ServerPlayer *p, use.to)
            room->addPlayerMark(p, "secondsouying_num_" + use.from->objectName() + p->objectName() + "-Clear");
        return false;
    }
};

class SecondZhanyuan : public PhaseChangeSkill
{
public:
    SecondZhanyuan() : PhaseChangeSkill("secondzhanyuan")
    {
        frequency = Wake;
        waked_skills = "secondxili";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        int mark = player->getMark("&secondzhanyuan_num") + player->getMark("secondzhanyuan_num");
        if (mark <= 7) return false;
        LogMessage log;
        log.type = "#ZhanyuanWake";
        log.from = player;
        log.arg = objectName();
        log.arg2 = QString::number(mark);
        room->sendLog(log);
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("second_huaman", objectName());
        room->addPlayerMark(player, objectName());
        if (room->changeMaxHpForAwakenSkill(player, 1)) {
            room->recover(player, RecoverStruct(player));
            QList<ServerPlayer *> males, geters;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isMale())
                    males << p;
            }
            if (!males.isEmpty()) {
                ServerPlayer *male = room->askForPlayerChosen(player, males, objectName(), "@secondzhanyuan-invoke", true);
                if (male) {
                    room->doAnimate(1, player->objectName(), male->objectName());
                    geters << male;
                }
            }
            if (!geters.contains(player))
                geters << player;
            if (geters.isEmpty()) return false;
            room->sortByActionOrder(geters);

            foreach (ServerPlayer *p, geters) {
                if (p->hasSkill("secondxili", true)) continue;
                room->handleAcquireDetachSkills(p, "secondxili");
            }
            if (player->hasSkill("secondmansi", true))
                room->handleAcquireDetachSkills(player, "-secondmansi");
        }
        return false;
    }
};

class SecondXili : public TriggerSkill
{
public:
    SecondXili() : TriggerSkill("secondxili")
    {
        events << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() != Player::NotActive && target->hasSkill(this, true);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->hasSkill(this, true)) return false;

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p == damage.from || p->getMark("secondxili-Clear") > 0) continue;
            if (!damage.from || damage.from->isDead() || !damage.from->hasSkill(this, true)) return false;
            if (damage.to->isDead() || damage.to->hasSkill(this, true)) return false;

            if (p->isDead() || !p->hasSkill(this) || p->getPhase() != Player::NotActive) continue;
            if (!p->canDiscard(p, "he")) continue;
            if (!room->askForCard(p, "..", "@secondxili-dis:" + damage.to->objectName(), data, objectName())) continue;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(p, "secondxili-Clear");

            LogMessage log;
            log.type = "#SecondxiliDamage";
            log.from = damage.from;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);

            QList<ServerPlayer *> drawers;
            drawers << p << damage.from;
            room->sortByActionOrder(drawers);
            room->drawCards(drawers, 2, objectName());
        }
        return false;
    }
};

class Hongde : public TriggerSkill
{
public:
    Hongde() : TriggerSkill("hongde")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        int n = 0;
        if (!room->getTag("FirstRound").toBool() && move.to && move.to == player && move.to_place == Player::PlaceHand) {
            if (move.card_ids.length() > 1)
                n++;
        }
        if (move.from && move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))) {
            int lose = 0;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                    lose++;
                    if (lose > 1)
                        break;
                }
            }
            if (lose > 1)
                n++;
        }

        if (n <= 0) return false;
        for (int i = 0; i < n; i++) {
            if (player->isDead() || !player->hasSkill(this)) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@hongde-invoke", true, true);
            if (!target) break;
            room->broadcastSkillInvoke(objectName());
            target->drawCards(1, objectName());
        }
        return false;
    }
};

DingpanCard::DingpanCard()
{
}

bool DingpanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && !to_select->getEquips().isEmpty();
}

void DingpanCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->drawCards(1, "dingpan");
    if (effect.to->getEquips().isEmpty() || effect.from->isDead()) return;

    Room *room = effect.from->getRoom();
    QStringList choices;
    if (effect.from->canDiscard(effect.to, "e"))
        choices << "discard";
    choices << "get";

    QString choice = room->askForChoice(effect.to, "dingpan", choices.join("+"), QVariant::fromValue(effect.from));
    if (choice == "discard") {
        if (!effect.from->canDiscard(effect.to, "e")) return;
        int id = room->askForCardChosen(effect.from, effect.to, "e", "dingpan", false, Card::MethodDiscard);
        room->throwCard(id, effect.to, effect.from);
    } else {
        DummyCard *dummy = new DummyCard;
        dummy->addSubcards(effect.to->getEquips());
        room->obtainCard(effect.to, dummy);
        delete dummy;
        room->damage(DamageStruct("dingpan", effect.from, effect.to));
    }
}

class DingpanVS : public ZeroCardViewAsSkill
{
public:
    DingpanVS() : ZeroCardViewAsSkill("dingpan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        /*int n = 0;
        QList<const Player *> as = player->getAliveSiblings();
        as << player;
        foreach (const Player *p, as) {
            if (p->getRole() == "rebel")
                n++;
        }*/
        int n = player->getMark("dingpan-PlayClear");
        return player->usedTimes("DingpanCard") < n;
    }

    const Card *viewAs() const
    {
        return new DingpanCard;
    }
};

class Dingpan : public TriggerSkill
{
public:
    Dingpan() : TriggerSkill("dingpan")
    {
        events << EventPhaseStart << CardFinished << EventAcquireSkill << Death;
        view_as_skill = new DingpanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        int n = 0;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getRole() == "rebel")
                n++;
        }
        room->setPlayerMark(player, "dingpan-PlayClear", n);
        return false;
    }
};

class DingpanRevived : public TriggerSkill
{
public:
    DingpanRevived() : TriggerSkill("#dingpan-revived")
    {
        events << Revived;
        view_as_skill = new DingpanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isDead() || !p->hasSkill("dingpan") || p->getPhase() != Player::Play) return false;
            int n = 0;
            foreach (ServerPlayer *q, room->getAlivePlayers()) {
                if (q->getRole() == "rebel")
                    n++;
            }
            room->setPlayerMark(p, "dingpan-PlayClear", n);
        }
        return false;
    }
};

class Qizhou : public TriggerSkill
{
public:
    Qizhou(const QString &skill_name) : TriggerSkill(skill_name), skill_name(skill_name)
    {
        events << CardsMoveOneTime << EventAcquireSkill;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        bool flag = false;
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && move.from_places.contains(Player::PlaceEquip))
                flag = true;
            if (move.to && move.to == player && move.to_place == Player::PlaceEquip)
                flag = true;
        } else {
            if (data.toString() == objectName())
                flag = true;
        }

        if (flag == true) {
            QStringList skills = player->tag[skill_name + "_skills"].toStringList();
            QStringList get_or_lose;
            if (QizhouNum(player) >= 1 && !player->hasSkill("mashu", true) && !skills.contains("mashu")) {
                skills << "mashu";
                player->tag[skill_name + "_skills"] = skills;
                get_or_lose << "mashu";
            }
            if (QizhouNum(player) < 1 && player->hasSkill("mashu", true) && skills.contains("mashu")) {
                skills.removeOne("mashu");
                player->tag[skill_name + "_skills"] = skills;
                get_or_lose << "-mashu";
            }

            if (QizhouNum(player) >= 2 && !player->hasSkill("yingzi", true) && !skills.contains("yingzi")) {
                skills << "yingzi";
                player->tag[skill_name + "_skills"] = skills;
                get_or_lose << "yingzi";
            }
            if (QizhouNum(player) < 2 && player->hasSkill("yingzi", true) && skills.contains("yingzi")) {
                skills.removeOne("yingzi");
                player->tag[skill_name + "_skills"] = skills;
                get_or_lose << "-yingzi";
            }

            QString duanbing = "duanbing";
            if (skill_name == "olqizhou")
                duanbing = "olduanbing";

            if (QizhouNum(player) >= 3 && !player->hasSkill(duanbing, true) && !skills.contains(duanbing)) {
                skills << duanbing;
                player->tag[skill_name + "_skills"] = skills;
                get_or_lose << duanbing;
            }

            if (QizhouNum(player) < 3 && player->hasSkill(duanbing, true) && skills.contains(duanbing)) {
                skills.removeOne(duanbing);
                player->tag[skill_name + "_skills"] = skills;
                get_or_lose << "-" + duanbing;
            }

            if (QizhouNum(player) >= 4 && !player->hasSkill("fenwei", true) && !skills.contains("fenwei")) {
                skills << "fenwei";
                player->tag[skill_name + "_skills"] = skills;
                int n = player->property("qizhou_fenwei_got").toInt();
                room->setPlayerProperty(player, "qizhou_fenwei_got", n + 1);
                get_or_lose << "fenwei";
            }
            if (QizhouNum(player) < 4 && player->hasSkill("fenwei", true) && skills.contains("fenwei")) {
                skills.removeOne("fenwei");
                player->tag[skill_name + "_skills"] = skills;
                get_or_lose << "-fenwei";
            }

            if (!get_or_lose.isEmpty()) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                bool flag = true;
                if (player->property("qizhou_fenwei_got").toInt() > 1)
                    flag = false;
                room->handleAcquireDetachSkills(player, get_or_lose, false, flag);
            }
        }
        return false;
    }

    static int QizhouNum(ServerPlayer *player)
    {
        QList<const Card *>equips = player->getEquips();
        QStringList suits;
        foreach (const Card *c, equips) {
            if (!suits.contains(c->getSuitString()))
                suits << c->getSuitString();
        }
        return suits.length();
    }

private:
    QString skill_name;
};

class QizhouLose : public TriggerSkill
{
public:
    QizhouLose(const QString &skill_name) : TriggerSkill("#" + skill_name + "-lose"), skill_name(skill_name)
    {
        events << EventLoseSkill;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.toString() != skill_name) return false;
        QStringList skills = player->tag[skill_name + "_skills"].toStringList();
        player->tag.remove(skill_name + "_skills");
        if (skills.isEmpty()) return false;
        QStringList new_list;
        foreach (QString str, skills) {
            if (player->hasSkill(str, true))
                new_list << "-" + str;
        }
        if (new_list.isEmpty()) return false;
        room->handleAcquireDetachSkills(player, new_list);
        return false;
    }
private:
    QString skill_name;
};

ShanxiCard::ShanxiCard()
{
    target_fixed = true;
}

void ShanxiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isDead()) return;
    QList<ServerPlayer *> players;
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (source->inMyAttackRange(p) && source->canDiscard(p, "he"))
            players << p;
    }
    if (players.isEmpty()) return;

    ServerPlayer *target = room->askForPlayerChosen(source, players, "shanxi", "@shanxi-choose");
    room->doAnimate(1, source->objectName(), target->objectName());
    int card_id = room->askForCardChosen(source, target, "he", "shanxi", false, Card::MethodDiscard);
    room->throwCard(card_id, target, source);

    ServerPlayer *watcher = NULL;
    ServerPlayer *watched = NULL;
    if (Sanguosha->getCard(card_id)->isKindOf("Jink")) {
        watcher = source;
        watched = target;
    } else {
        watcher = target;
        watched = source;
    }
    if (!watcher || !watched || watcher->isDead() || watched->isDead()) return;
    if (watched->isKongcheng()) return;
    room->doGongxin(watcher, watched, QList<int>(), "shanxi");
}

class Shanxi : public OneCardViewAsSkill
{
public:
    Shanxi() : OneCardViewAsSkill("shanxi")
    {
        filter_pattern = "BasicCard|red";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ShanxiCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ShanxiCard *card = new ShanxiCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class MobileQizhou : public TriggerSkill
{
public:
    MobileQizhou() : TriggerSkill("mobileqizhou")
    {
        events << CardsMoveOneTime << EventAcquireSkill;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        bool flag = false;
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && move.from_places.contains(Player::PlaceEquip))
                flag = true;
            if (move.to && move.to == player && move.to_place == Player::PlaceEquip)
                flag = true;
        } else {
            if (data.toString() == objectName())
                flag = true;
        }

        if (flag == true) {
            QStringList skills = player->property("mobileqizhou_skills").toStringList();
            QStringList get_or_lose;
            if (Qizhou::QizhouNum(player) >= 1 && !player->hasSkill("nosyingzi", true) && !skills.contains("nosyingzi")) {
                skills << "nosyingzi";
                room->setPlayerProperty(player, "mobileqizhou_skills", skills);
                get_or_lose << "nosyingzi";
            }
            if (Qizhou::QizhouNum(player) < 1 && player->hasSkill("nosyingzi", true) && skills.contains("nosyingzi")) {
                skills.removeOne("nosyingzi");
                room->setPlayerProperty(player, "mobileqizhou_skills", skills);
                get_or_lose << "-nosyingzi";
            }

            if (Qizhou::QizhouNum(player) >= 2 && !player->hasSkill("qixi", true) && !skills.contains("qixi")) {
                skills << "qixi";
                room->setPlayerProperty(player, "mobileqizhou_skills", skills);
                get_or_lose << "qixi";
            }
            if (Qizhou::QizhouNum(player) < 2 && player->hasSkill("qixi", true) && skills.contains("qixi")) {
                skills.removeOne("qixi");
                room->setPlayerProperty(player, "mobileqizhou_skills", skills);
                get_or_lose << "-qixi";
            }

            if (Qizhou::QizhouNum(player) >= 3 && !player->hasSkill("xuanfeng", true) && !skills.contains("xuanfeng")) {
                skills << "xuanfeng";
                room->setPlayerProperty(player, "mobileqizhou_skills", skills);
                get_or_lose << "xuanfeng";
            }
            if (Qizhou::QizhouNum(player) < 3 && player->hasSkill("xuanfeng", true) && skills.contains("xuanfeng")) {
                skills.removeOne("xuanfeng");
                room->setPlayerProperty(player, "mobileqizhou_skills", skills);
                get_or_lose << "-xuanfeng";
            }

            if (!get_or_lose.isEmpty()) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->handleAcquireDetachSkills(player, get_or_lose);
            }
        }
        return false;
    }
};

class MobileQizhouLose : public TriggerSkill
{
public:
    MobileQizhouLose() : TriggerSkill("#mobileqizhou-lose")
    {
        events << EventLoseSkill;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.toString() != "mobileqizhou") return false;
        QStringList skills = player->property("mobileqizhou_skills").toStringList();
        room->setPlayerProperty(player, "mobileqizhou_skills", QStringList());
        if (skills.isEmpty()) return false;
        QStringList new_list;
        foreach (QString str, skills) {
            if (player->hasSkill(str, true))
                new_list << "-" + str;
        }
        if (new_list.isEmpty()) return false;
        room->handleAcquireDetachSkills(player, new_list);
        return false;
    }
};

MobileShanxiCard::MobileShanxiCard()
{
    handling_method = Card::MethodDiscard;
}

void MobileShanxiCard::onEffect(const CardEffectStruct &effect) const
{
    int n = qMin(effect.to->getCards("he").length(), effect.from->getHp());
    if (n > 0) {
        QStringList dis_num;
        for (int i = 1; i <= n; ++i)
            dis_num << QString::number(i);

        int ad = Config.AIDelay;
        Config.AIDelay = 0;

        bool ok = false;
        Room *room = effect.from->getRoom();
        int discard_n = room->askForChoice(effect.from, "mobileshanxi", dis_num.join("+"), QVariant::fromValue(effect.to)).toInt(&ok);
        if (!ok || discard_n == 0) {
            Config.AIDelay = ad;
            return;
        }

        QList<Player::Place> orig_places;
        QList<int> cards;
        // fake move skill needed!!!
        effect.to->setFlags("mobileshanxi_InTempMoving");

        for (int i = 0; i < discard_n; ++i) {
            int id = room->askForCardChosen(effect.from, effect.to, "he", "mobileshanxi", false, Card::MethodNone);
            Player::Place place = room->getCardPlace(id);
            orig_places << place;
            cards << id;
            effect.to->addToPile("#mobileshanxi", id, false);
        }

        for (int i = 0; i < discard_n; ++i)
            room->moveCardTo(Sanguosha->getCard(cards.value(i)), effect.to, orig_places.value(i), false);

        effect.to->setFlags("-mobileshanxi_InTempMoving");
        Config.AIDelay = ad;

        DummyCard dummy(cards);
        effect.to->addToPile("mobileshanxi", &dummy, false, QList<ServerPlayer *>() << effect.to);

        // for record
        if (!effect.to->tag.contains("mobileshanxi") || !effect.to->tag.value("mobileshanxi").canConvert(QVariant::Map))
            effect.to->tag["mobileshanxi"] = QVariantMap();

        QVariantMap vm = effect.to->tag["mobileshanxi"].toMap();
        foreach (int id, cards)
            vm[QString::number(id)] = effect.from->objectName();

        effect.to->tag["mobileshanxi"] = vm;
    }
}

class MobileShanxiVS :public OneCardViewAsSkill
{
public:
    MobileShanxiVS() :OneCardViewAsSkill("mobileshanxi")
    {
        filter_pattern = "BasicCard|red!";
        response_pattern = "@@mobileshanxi";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileShanxiCard *card = new MobileShanxiCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class MobileShanxi : public PhaseChangeSkill
{
public:
    MobileShanxi() : PhaseChangeSkill("mobileshanxi")
    {
        view_as_skill = new MobileShanxiVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play || !player->canDiscard(player, "h")) return false;
        player->getRoom()->askForUseCard(player, "@@mobileshanxi", "@mobileshanxi", -1, Card::MethodDiscard);
        return false;
    }
};

class MobileShanxiGet : public TriggerSkill
{
public:
    MobileShanxiGet() : TriggerSkill("#mobileshanxi-get")
    {
        events << EventPhaseChanging << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive)
                return false;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player)
                return false;
        }

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->tag.contains("mobileshanxi")) {
                QVariantMap vm = p->tag.value("mobileshanxi", QVariantMap()).toMap();
                if (vm.values().contains(player->objectName())) {
                    QList<int> to_obtain;
                    foreach (const QString &key, vm.keys()) {
                        if (vm.value(key) == player->objectName())
                            to_obtain << key.toInt();
                    }

                    DummyCard dummy(to_obtain);
                    room->obtainCard(p, &dummy, false);

                    foreach (int id, to_obtain)
                        vm.remove(QString::number(id));

                    p->tag["mobileshanxi"] = vm;
                }
            }
        }
        return false;
    }
};

class Xiashu : public PhaseChangeSkill
{
public:
    Xiashu() : PhaseChangeSkill("xiashu")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play || player->isKongcheng()) return false;
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@xiashu-invoke", true, true);
        if (!target) return false;
        int index = qrand() % 2 + 1;
        if (player->getGeneralName().contains("tenyear_") || player->getGeneral2Name().contains("tenyear_"))
            index += 2;
        room->broadcastSkillInvoke(objectName(), index);

        DummyCard *handcards = player->wholeHandCards();
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "xiashu", QString());
        room->obtainCard(target, handcards, reason, false);
        delete handcards;

        if (target->isKongcheng()) return false;
        int hand = target->getHandcardNum();
        const Card *show = room->askForExchange(target, objectName(), hand, 1, false, "xiashu-show");
        QList<int> ids = show->getSubcards();
        LogMessage log;
        log.type = "$ShowCard";
        log.from = target;
        log.card_str = IntList2StringList(ids).join("+");
        room->sendLog(log);
        room->fillAG(ids);
        room->getThread()->delay();

        QStringList choices;
        choices << "getshow";
        if (ids.length() != hand)
            choices << "getnotshow";
        QString choice = room->askForChoice(player, objectName(), choices.join("+"), IntList2VariantList(ids));
        room->clearAG();
        if (choice == "getshow") {
            DummyCard *dummy = new DummyCard(ids);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, dummy, reason, false);
            delete dummy;
        } else {
            QList<int> get;
            foreach (int id, target->handCards()) {
                if (!ids.contains(id))
                    get << id;
            }
            if (get.isEmpty()) return false;
            DummyCard *dummy = new DummyCard(get);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, dummy, reason, false);
            delete dummy;
        }
        return false;
    }
};

class Kuanshi : public TriggerSkill
{
public:
    Kuanshi(const QString &kuanshi) : TriggerSkill(kuanshi), kuanshi(kuanshi)
    {
        events << EventPhaseStart << EventPhaseChanging;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseChanging)
            return 6;
        else
            return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@kuanshi-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->setPlayerMark(target, "&" + kuanshi + "+#" + player->objectName(), 1);
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::RoundStart) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->getMark("&" + kuanshi + "+#" + player->objectName()) <= 0) continue;
                    room->setPlayerMark(p, "&" + kuanshi + "+#" + player->objectName(), 0);
                }
            } else if (change.to == Player::Draw) {
                if (kuanshi != "kuanshi" || player->isSkipped(Player::Draw) || player->getMark("kuanshi_skip") <= 0) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->setPlayerMark(player, "kuanshi_skip", 0);
                player->skip(Player::Draw);
            }
        }
        return false;
    }
private:
    QString kuanshi;
};

class KuanshiMark : public TriggerSkill
{
public:
    KuanshiMark(const QString &kuanshi) : TriggerSkill("#" + kuanshi + "-mark"), kuanshi(kuanshi)
    {
        events << EventLoseSkill << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventLoseSkill) {
            if (data.toString() != kuanshi) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("&" + kuanshi + "+#" + player->objectName()) <= 0) continue;
                room->setPlayerMark(p, "&" + kuanshi + "+#" + player->objectName(), 0);
            }
        } else if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player) return false;
            if (!player->hasSkill(kuanshi, true)) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("&" + kuanshi + "+#" + player->objectName()) <= 0) continue;
                room->setPlayerMark(p, "&" + kuanshi + "+#" + player->objectName(), 0);
            }
        }
        return false;
    }
private:
    QString kuanshi;
};

class KuanshiEffect : public TriggerSkill
{
public:
    KuanshiEffect() : TriggerSkill("#kuanshi-effect")
    {
        events << DamageInflicted;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.damage <= 1) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead()) continue;
            if (damage.to->isDead() || damage.to->getMark("&kuanshi+#" + p->objectName()) <= 0) continue;
            LogMessage log;
            log.type = damage.from != NULL ? "#KuanshiEffect" : "#KuanshiNoFromEffect";
            log.from = damage.to;
            if (damage.from)
                log.to << damage.from;
            log.arg = "kuanshi";
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(p, "kuanshi");
            room->broadcastSkillInvoke("kuanshi");
            room->setPlayerMark(damage.to, "&kuanshi+#" + p->objectName(), 0);
            room->addPlayerMark(p, "kuanshi_skip");
            return true;
        }
        return false;
    }
};

class TenyearKuanshiEffect : public TriggerSkill
{
public:
    TenyearKuanshiEffect() : TriggerSkill("#tenyearkuanshi-effect")
    {
        events << Damaged;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead()) continue;
            if (damage.to->isDead() || damage.to->getMark("&tenyearkuanshi+#" + p->objectName()) <= 0) continue;
            room->addPlayerMark(damage.to, "tenyearkuanshi_damage-Clear", damage.damage);
            if (damage.to->getMark("tenyearkuanshi_damage-Clear") >= 2) {
                room->setPlayerMark(damage.to, "&tenyearkuanshi+#" + p->objectName(), 0);
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = damage.to;
                log.arg = "tenyearkuanshi";
                room->sendLog(log);
                room->notifySkillInvoked(p, "tenyearkuanshi");
                room->broadcastSkillInvoke("tenyearkuanshi");
                room->recover(damage.to, RecoverStruct(p));
            }
        }
        return false;
    }
};

GuolunCard::GuolunCard()
{
}

bool GuolunCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->isKongcheng() && to_select != Self;
}

void GuolunCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead() || effect.to->isKongcheng()) return;
    int id = effect.to->getRandomHandCardId();
    Room *room = effect.from->getRoom();
    room->showCard(effect.to, id);
    if (effect.from->isDead() || effect.from->isNude()) return;
    const Card *card = room->askForCard(effect.from, "..", "guolun-show", id, Card::MethodNone, effect.to);
    if (!card) return;
    int card_id = card->getEffectiveId();
    room->showCard(effect.from, card_id);

    int to_num = Sanguosha->getCard(id)->getNumber();
    int from_num = Sanguosha->getCard(card_id)->getNumber();
    if (to_num == from_num) return;

    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p != effect.from && p != effect.to) {
            JsonArray arr;
            arr << effect.from->objectName() << effect.to->objectName();
            room->doNotify(p, QSanProtocol::S_COMMAND_EXCHANGE_KNOWN_CARDS, arr);
        }
    }
    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1(QList<int>(), effect.to, Player::PlaceHand,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, effect.from->objectName(), effect.to->objectName(), "guolun", QString()));
    move1.card_ids << card_id;
    CardsMoveStruct move2(QList<int>(), effect.from, Player::PlaceHand,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, effect.to->objectName(), effect.from->objectName(), "guolun", QString()));
    move2.card_ids << id;
    exchangeMove.push_back(move1);
    exchangeMove.push_back(move2);
    room->moveCardsAtomic(exchangeMove, true);

    ServerPlayer *drawer = NULL;
    if (to_num < from_num)
        drawer = effect.to;
    else if (to_num > from_num)
        drawer = effect.from;
    if (drawer == NULL) return;
    drawer->drawCards(1, "guolun");
}

class Guolun : public ZeroCardViewAsSkill
{
public:
    Guolun() : ZeroCardViewAsSkill("guolun")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("GuolunCard");
    }

    const Card *viewAs() const
    {
        return new GuolunCard;
    }
};

class Songsang : public TriggerSkill
{
public:
    Songsang() : TriggerSkill("songsang")
    {
        events << Death;
        frequency = Limited;
        limit_mark = "@songsangMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who == player || !player->hasSkill(this)) return false;
        if (player->getMark("@songsangMark") <= 0 || !player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke("songsang");
        room->doSuperLightbox("sp_pangtong", "songsang");
        room->removePlayerMark(player, "@songsangMark");
        if (player->isWounded())
            room->recover(player, RecoverStruct(player));
        else
            room->gainMaxHp(player);
        if (player->hasSkill("zhanji")) return false;
        room->acquireSkill(player, "zhanji");
        return false;
    }
};

class Zhanji : public TriggerSkill
{
public:
    Zhanji() : TriggerSkill("zhanji")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to && move.to == player && move.to_place == Player::PlaceHand && move.from_places.contains(Player::DrawPile)) {
            if (move.reason.m_reason == CardMoveReason::S_REASON_DRAW && move.reason.m_skillName != objectName()) {
                if (player->getPhase() == Player::Play) {
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    player->drawCards(1, objectName());
                }
            }
        }
        return false;
    }
};

class Bizheng : public TriggerSkill
{
public:
    Bizheng() : TriggerSkill("bizheng")
    {
        events << EventPhaseEnd;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Draw) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@bizheng-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        target->drawCards(2, objectName());
        QList<ServerPlayer *> players;
        players << player << target;
        room->sortByActionOrder(players);
        foreach (ServerPlayer *p, players) {
            if (p->isAlive() && p->getHandcardNum() > p->getMaxHp()) {
                room->askForDiscard(p, objectName(), 2, 2, false, true);
            }
        }
        return false;
    }
};

class YidianVS : public ZeroCardViewAsSkill
{
public:
    YidianVS() : ZeroCardViewAsSkill("yidian")
    {
        response_pattern = "@@yidian";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new ExtraCollateralCard;
    }
};

class Yidian : public TriggerSkill
{
public:
    Yidian() : TriggerSkill("yidian")
    {
        events << PreCardUsed;
        view_as_skill = new YidianVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isNDTrick() && !use.card->isKindOf("BasicCard")) return false;

        room->setCardFlag(use.card, "yidian_distance");
        QList<ServerPlayer *> ava;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (use.card->isKindOf("AOE") && p == use.from) continue;
            if (use.to.contains(p) || room->isProhibited(use.from, p, use.card)) continue;
            if (use.card->targetFixed())
                ava << p;
            else {
                if (use.card->targetFilter(QList<const Player *>(), p, use.from))
                    ava << p;
            }
        }
        room->setCardFlag(use.card, "-yidian_distance");
        if (ava.isEmpty()) return false;

        QString name = use.card->objectName();
        if (use.card->isKindOf("Slash"))
            name = "slash";
        bool has = false;
        foreach (int id, room->getDiscardPile()) {
            const Card *card = Sanguosha->getCard(id);
            QString card_name = card->objectName();
            if (card->isKindOf("Slash"))
                card_name = "slash";
            if (card_name == name) {
                has = true;
                break;
            }
        }
        if (has) return false;
        ServerPlayer *target = NULL;
        if (!use.card->isKindOf("Collateral")) {
            player->tag["YidianData"] = data;
            target = room->askForPlayerChosen(player, ava, objectName(), "@yidian-invoke:" + name, true);
            player->tag.remove("YidianData");
        } else {
            QStringList tos;
            foreach(ServerPlayer *t, use.to)
                tos.append(t->objectName());

            room->setPlayerProperty(player, "extra_collateral", use.card->toString());
            room->setPlayerProperty(player, "extra_collateral_current_targets", tos.join("+"));
            room->askForUseCard(player, "@@yidian", "@yidian:" + name);
            room->setPlayerProperty(player, "extra_collateral", QString());
            room->setPlayerProperty(player, "extra_collateral_current_targets", QString("+"));

            foreach(ServerPlayer *p, room->getAlivePlayers()) {
                if (p->hasFlag("ExtraCollateralTarget")) {
                    room->setPlayerFlag(p,"-ExtraCollateralTarget");
                    target = p;
                    break;
                }
            }
        }
        if (!target) return false;
        LogMessage log;
        log.type = "#QiaoshuiAdd";
        log.from = player;
        log.to << target;
        log.card_str = use.card->toString();
        log.arg = "yidian";
        room->sendLog(log);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        use.to.append(target);
        room->sortByActionOrder(use.to);
        if (use.card->isKindOf("Collateral")) {
            ServerPlayer *victim = target->tag["collateralVictim"].value<ServerPlayer *>();
            if (victim) {
                LogMessage log;
                log.type = "#CollateralSlash";
                log.from = player;
                log.to << victim;
                room->sendLog(log);
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());
            }
        }
        data = QVariant::fromValue(use);
        return false;
    }
};

class YidianTargetMod : public TargetModSkill
{
public:
    YidianTargetMod() : TargetModSkill("#yidian-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("yidian_distance") && (card->isNDTrick() || card->isKindOf("BasicCard")))
            return 1000;
        else
            return 0;
    }
};

class Lianpian : public TriggerSkill
{
public:
    Lianpian() : TriggerSkill("lianpian")
    {
        events << TargetSpecifying <<  CardFinished << EventPhaseChanging;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            room->setPlayerProperty(player, "lianpian_targets", QStringList());
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (event == TargetSpecifying) {
                if (!player->hasSkill(this) || player->getMark("lianpian-PlayClear") >= 3) return false;
                if (!room->CardInTable(use.card)) return false;
                QList<ServerPlayer *> targets;
                QStringList names = player->property("lianpian_targets").toStringList();
                foreach (ServerPlayer *p, use.to) {
                    if (p->isAlive() && names.contains(p->objectName())) {
                        targets << p;
                    }
                }
                if (targets.isEmpty()) return false;
                if (!player->askForSkillInvoke(this)) return false;
                room->broadcastSkillInvoke(objectName());
                room->addPlayerMark(player, "lianpian-PlayClear");
                player->drawCards(1, objectName());
                if (targets.contains(player))
                    targets.removeOne(player);
                if (targets.isEmpty()) return false;
                ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@lianpian-give:" + use.card->objectName(), true, true);
                if (!target) return false;
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "lianpian", QString());
                room->obtainCard(target, use.card, reason, true);
            } else {
                if (!use.from || use.from->isDead()) return false;
                QStringList names;
                foreach (ServerPlayer *p, use.to) {
                    if (p->isAlive() && !names.contains(p->objectName()))
                        names << p->objectName();
                }
                room->setPlayerProperty(use.from, "lianpian_targets", names);
            }
        }
        return false;
    }
};

class Guanchao : public TriggerSkill
{
public:
    Guanchao() : TriggerSkill("guanchao")
    {
        events << EventPhaseStart << CardUsed << CardResponded << EventPhaseChanging;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            QString choice = room->askForChoice(player, objectName(), "up+down");
            LogMessage log;
            log.type = "#FumianFirstChoice";
            log.from = player;
            log.arg = "guanchao:" + choice;
            room->sendLog(log);
            room->setPlayerFlag(player, "guanchao_" + choice);
            room->setPlayerMark(player, "guanchao-PlayClear", -1); //避免第一张使用的牌点数为0的问题
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from != Player::Play) return false;
            if (player->hasFlag("guanchao_up"))
                room->setPlayerFlag(player, "-guanchao_up");
            if (player->hasFlag("guanchao_down"))
                room->setPlayerFlag(player, "-guanchao_down");
        } else {
            const Card *card = NULL;
            if (event == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                if (use.card->isKindOf("SkillCard")) return false;
                card = use.card;
            } else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse || res.m_card->isKindOf("SkillCard")) return false;
                card = res.m_card;
            }
            if (!card) return false;

            int mark = player->getMark("guanchao-PlayClear");
            int num = card->getNumber();
            if (mark < 0) {
                room->setPlayerMark(player, "guanchao-PlayClear", num);
                return false;
            }

            if (player->hasFlag("guanchao_up")) {
                if (num > mark) {
                    room->setPlayerMark(player, "guanchao-PlayClear", num);
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    player->drawCards(1, objectName());
                } else {
                    room->setPlayerFlag(player, "-guanchao_up");
                }
            } else if (player->hasFlag("guanchao_down")) {
                if (num < mark) {
                    room->setPlayerMark(player, "guanchao-PlayClear", num);
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    player->drawCards(1, objectName());
                } else {
                    room->setPlayerFlag(player, "-guanchao_down");
                }
            }
        }
        return false;
    }
};

class Xunxian : public TriggerSkill
{
public:
    Xunxian() : TriggerSkill("xunxian")
    {
        events << BeforeCardsMove;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DiscardPile) return false;
        if ((move.from_places.contains(Player::PlaceTable) && (move.reason.m_reason == CardMoveReason::S_REASON_USE ||
             move.reason.m_reason == CardMoveReason::S_REASON_LETUSE)) || move.reason.m_reason == CardMoveReason::S_REASON_RESPONSE) {
            const Card *card = move.reason.m_extraData.value<const Card *>();
            if (!card || card->isKindOf("SkillCard")) return false;
            ServerPlayer *from = room->findPlayerByObjectName(move.reason.m_playerId);
            if (!from || from->isDead() || !from->hasSkill(this)) return false;
            if (from->getMark("xunxian-Clear") > 0 || (room->getCurrent() && room->getCurrent() == from)) return false;
            if (move.reason.m_reason == CardMoveReason::S_REASON_USE || move.reason.m_reason == CardMoveReason::S_REASON_LETUSE) {
                if (!room->CardInPlace(card, Player::PlaceTable)) return false;
            }

            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(from)) {
                if (p->getHandcardNum() > from->getHandcardNum())
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(from, targets, objectName(), "@xunxian-give:" + card->objectName(), true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(from, "xunxian-Clear");
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, from->objectName(), target->objectName(), "xunxian", QString());
            room->obtainCard(target, card, reason, true);

            QList<int> ids;
            if (card->isVirtualCard())
                ids = card->getSubcards();
            else
                ids << card->getEffectiveId();
            move.removeCardIds(ids);
            data = QVariant::fromValue(move);
        }
        return false;
    }
};

class SpYoudi : public PhaseChangeSkill
{
public:
    SpYoudi() : PhaseChangeSkill("spyoudi")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish || player->isKongcheng()) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->canDiscard(player, "h"))
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@spyoudi-invoke", true, true);
        if (!target) return false;

        room->broadcastSkillInvoke(objectName());
        if (!target->canDiscard(player, "h")) return false;
        int card_id = room->askForCardChosen(target, player, "h", objectName(), false, Card::MethodDiscard);
        room->throwCard(card_id, player, target);
        const Card *card = Sanguosha->getCard(card_id);
        if (!card->isKindOf("Slash")) {
            if (target->isAlive() && !target->isNude()) {
                int card_id = room->askForCardChosen(player, target, "he", objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
            }
        }
        if (!card->isBlack())
            player->drawCards(1, objectName());
        return false;
    }
};

DuanfaCard::DuanfaCard()
{
    target_fixed = true;
}

void DuanfaCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int n = subcardsLength();
    room->addPlayerMark(source, "duanfa_num-PlayClear", n);
    source->drawCards(n, "duanfa");
}

class Duanfa : public ViewAsSkill
{
public:
    Duanfa() : ViewAsSkill("duanfa")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int n = Self->getMaxHp() - Self->getMark("duanfa_num-PlayClear");
        return !Self->isJilei(to_select) && to_select->isBlack() && selected.length() < n;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        DuanfaCard *c = new DuanfaCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMaxHp() > player->getMark("duanfa_num-PlayClear");
    }
};

QinguoCard::QinguoCard()
{
    mute = true;
}

bool QinguoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("qinguo");
    slash->deleteLater();
    return slash->targetFilter(targets, to_select, Self);
}

void QinguoCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("qinguo");
    slash->deleteLater();
    room->useCard(CardUseStruct(slash, card_use.from, card_use.to), false);
}

class QinguoVS : public ZeroCardViewAsSkill
{
public:
    QinguoVS() : ZeroCardViewAsSkill("qinguo")
    {
        response_pattern = "@@qinguo";
    }

    const Card *viewAs() const
    {
        return new QinguoCard;
    }
};

class Qinguo : public TriggerSkill
{
public:
    Qinguo() : TriggerSkill("qinguo")
    {
        events << CardFinished << BeforeCardsMove << CardsMoveOneTime;
        view_as_skill = new QinguoVS;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == BeforeCardsMove)
            return -1;
        else
            return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            if (player->getPhase() == Player::NotActive) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("EquipCard")) return false;
            bool can_slash = false;
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName(objectName());
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->canSlash(p, slash, true)) {
                    can_slash = true;
                    break;
                }
            }
            if (!can_slash) return false;
            room->askForUseCard(player, "@@qinguo", "@qinguo");
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if ((move.to && move.to == player && move.to_place == Player::PlaceEquip) ||
                    (move.from && move.from == player && move.from_places.contains(Player::PlaceEquip))) {
                if (event == BeforeCardsMove) {
                    room->setPlayerMark(player, "qinguo_equip_num", player->getEquips().length());
                } else {
                    int mark = player->getMark("qinguo_equip_num");
                    int num = player->getEquips().length();
                    if (num == player->getHp() && num != mark && player->getLostHp() > 0) {
                        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                        room->recover(player, RecoverStruct(player));
                    }
                }
            }
        }
        return false;
    }
};

class Lianhua : public PhaseChangeSkill
{
public:
    Lianhua() : PhaseChangeSkill("lianhua")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (player->getPhase() == Player::Play) {
            room->setPlayerProperty(player, "danxue_red", 0);
            room->setPlayerProperty(player, "danxue_black", 0);
            player->loseAllMarks("&danxue");
        } else if (player->getPhase() == Player::Start) {
            int red = player->property("danxue_red").toInt();
            int black = player->property("danxue_black").toInt();
            int all = red + black;
            if (all <= 3) {
                room->acquireOneTurnSkills(player, "lianhua", "yingzi");
                LianhuaCard(player, "peach");
            } else {
                if (red > black) {
                    room->acquireOneTurnSkills(player, "lianhua", "tenyearguanxing");
                    LianhuaCard(player, "ex_nihilo");
                } else if (black > red) {
                    room->acquireOneTurnSkills(player, "lianhua", "zhiyan");
                    LianhuaCard(player, "snatch");
                } else if (black == red) {
                    room->acquireOneTurnSkills(player, "lianhua", "gongxin");
                    QList<int> slash, duel, get;
                    QList<int> cards = room->getDiscardPile() + room->getDrawPile();
                    foreach (int id, cards) {
                        const Card *card = Sanguosha->getCard(id);
                        if (card->isKindOf("Slash"))
                            slash << id;
                        else if (card->objectName() == "duel")
                            duel << id;
                    }
                    if (!slash.isEmpty())
                        get << slash.at(qrand() % slash.length());
                    if (!duel.isEmpty())
                        get << duel.at(qrand() % duel.length());
                    if (get.isEmpty()) return false;
                    DummyCard *dummy = new DummyCard(get);
                    room->obtainCard(player, dummy, true);
                    delete dummy;
                }
            }
        }
        return false;
    }

private:
    void LianhuaCard(ServerPlayer *player, const QString &name) const
    {
        Room *room = player->getRoom();
        QList<int> cards = room->getDiscardPile() + room->getDrawPile();
        QList<int> ids;
        foreach (int id, cards) {
            if (Sanguosha->getCard(id)->objectName() == name)
                ids << id;
        }
        if (ids.isEmpty()) return;
        int id = ids.at(qrand() % ids.length());
        room->obtainCard(player, id, true);
    }
};

class LianhuaEffect : public TriggerSkill
{
public:
    LianhuaEffect() : TriggerSkill("#lianhua-effect")
    {
        events << Damaged << EventLoseSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            foreach (ServerPlayer *p, room->getOtherPlayers(damage.to)) {
                if (!damage.to || damage.to->isDead()) return false;
                if (p->isDead() || !p->hasSkill("lianhua") || p->getPhase() != Player::NotActive) continue;
                room->sendCompulsoryTriggerLog(p, "lianhua", true, true);
                if (damage.to->isYourFriend(p)) {
                    int n = p->property("danxue_red").toInt();
                    room->setPlayerProperty(p, "danxue_red", n + 1);
                } else {
                    int n = p->property("danxue_black").toInt();
                    room->setPlayerProperty(p, "danxue_black", n + 1);
                }
                p->gainMark("&danxue");
            }
        } else {
            if (data.toString() != "lianhua") return false;
            room->setPlayerProperty(player, "danxue_red", 0);
            room->setPlayerProperty(player, "danxue_black", 0);
            player->loseAllMarks("&danxue");
        }
        return false;
    }
};

ZhafuCard::ZhafuCard()
{
}

void ZhafuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->doSuperLightbox("gexuan", "zhafu");
    room->removePlayerMark(effect.from, "@zhafuMark");

    QStringList names = effect.to->property("zhafu_from").toStringList();
    if (names.contains(effect.from->objectName())) return;
    names << effect.from->objectName();
    room->setPlayerProperty(effect.to, "zhafu_from", names);
}

class ZhafuVS : public ZeroCardViewAsSkill
{
public:
    ZhafuVS() : ZeroCardViewAsSkill("zhafu")
    {
        frequency = Limited;
        limit_mark = "@zhafuMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@zhafuMark") > 0;
    }

    const Card *viewAs() const
    {
        return new ZhafuCard;
    }
};

class Zhafu : public PhaseChangeSkill
{
public:
    Zhafu() : PhaseChangeSkill("zhafu")
    {
        frequency = Limited;
        limit_mark = "@zhafuMark";
        view_as_skill = new ZhafuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Discard) return false;
        Room *room = player->getRoom();
        QStringList names = player->property("zhafu_from").toStringList();
        if (names.isEmpty()) return false;
        room->setPlayerProperty(player, "zhafu_from", QStringList());

        LogMessage log;
        log.type = (player->getHandcardNum() > 1) ? "#ZhafuEffect" : (!player->isKongcheng() ? "#ZhafuOne" : "#ZhafuZero");
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);
        if (player->getHandcardNum() <= 1) return false;

        QList<ServerPlayer *> players;
        foreach (QString name, names) {
            ServerPlayer *from = room->findPlayerByObjectName(name);
            if (from && from->isAlive() && from->hasSkill(this))
                players << from;
        }
        if (players.isEmpty()) return false;
        room->sortByActionOrder(players);

        foreach (ServerPlayer *p, players) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (player->getHandcardNum() <= 1) return false;
            int id = -1;
            const Card *card = room->askForCard(player, ".!", "zhafu-keep:" + p->objectName(), QVariant::fromValue(p), Card::MethodNone, p);
            if (!card) {
                card = player->getRandomHandCard();
                id = card->getEffectiveId();
            } else
                id = card->getSubcards().first();

            DummyCard *dummy = new DummyCard;
            foreach (const Card *c, player->getCards("h")) {
                if (c->getEffectiveId() != id)
                    dummy->addSubcard(c);
            }
            if (dummy->subcardsLength() > 0) {
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), p->objectName(), "zhafu", QString());
                room->obtainCard(p, dummy, reason, false);
            }
            delete dummy;
        }
        return false;
    }
};

SongshuCard::SongshuCard()
{
}

bool SongshuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void SongshuCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;
    Room *room = effect.from->getRoom();
    bool pindian = effect.from->pindian(effect.to, "songshu");
    if (pindian) {
        int n = effect.from->usedTimes("SongshuCard");
        room->addPlayerHistory(effect.from, "SongshuCard", -n);
    } else {
        QList<ServerPlayer *> drawers;
        drawers << effect.from << effect.to;
        room->sortByActionOrder(drawers);
        room->drawCards(drawers, 2, "songshu");
    }
}

class Songshu : public ZeroCardViewAsSkill
{
public:
    Songshu() : ZeroCardViewAsSkill("songshu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SongshuCard") && player->canPindian();
    }

    const Card *viewAs() const
    {
        return new SongshuCard;
    }
};

class Sibian : public PhaseChangeSkill
{
public:
    Sibian() : PhaseChangeSkill("sibian")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Draw) return false;
        if (!player->askForSkillInvoke(this)) return false;
        player->peiyin(this);

        Room *room = player->getRoom();
        QList<int> show = room->showDrawPile(player, 4, objectName());

        int max = Sanguosha->getCard(show.first())->getNumber();
        int min = Sanguosha->getCard(show.first())->getNumber();
        foreach (int id, show) {
            int num = Sanguosha->getCard(id)->getNumber();
            if (num > max)
                max = num;
            if (num < min)
                min = num;
        }
        DummyCard *dummy = new DummyCard;
        foreach (int id, show) {
            int num = Sanguosha->getCard(id)->getNumber();
            if (num == min || num == max) {
                dummy->addSubcard(id);
                show.removeOne(id);
            }
        }
        int length = dummy->subcardsLength();
        if (length > 0)
            room->obtainCard(player, dummy, true);
        delete dummy;

        DummyCard *dum = new DummyCard;
        dum->deleteLater();
        foreach (int id, show) {
            if (room->getCardPlace(id) == Player::PlaceTable)
                dum->addSubcard(id);
        }
        if (dum->subcardsLength() <= 0) return false;

        int hand = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() < hand)
                hand = p->getHandcardNum();
        }
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() == hand)
                targets << p;
        }

        if (!targets.isEmpty()) {
            room->fillAG(dum->getSubcards(), player);
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@sibian-give", true, true);
            room->clearAG(player);

            if (target)
                room->giveCard(player, target, dum, objectName(), true);
            else {
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "sibian", QString());
                room->throwCard(dum, reason, NULL);
            }
        } else {
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "sibian", QString());
            room->throwCard(dum, reason, NULL);
        }
        return true;
    }
};

class Biaozhao : public TriggerSkill
{
public:
    Biaozhao() : TriggerSkill("biaozhao")
    {
        events << EventPhaseStart << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() == Player::Finish) {
                if (player->isNude() || !player->getPile("bzbiao").isEmpty()) return false;
                const Card *card = room->askForCard(player, "..", "biaozhao-put", QVariant(), Card::MethodNone);
                if (!card) return false;
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);
                room->broadcastSkillInvoke(objectName());
                room->notifySkillInvoked(player, objectName());
                player->addToPile("bzbiao", card);
            } else if (player->getPhase() == Player::Start) {
                if (player->getPile("bzbiao").isEmpty()) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                player->clearOnePrivatePile("bzbiao");
                if (player->isDead()) return false;
                ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@biaozhao-invoke");
                room->doAnimate(1, player->objectName(), target->objectName());
                room->recover(target, RecoverStruct(player));
                int n = target->getHandcardNum();
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->getHandcardNum() > n)
                        n = p->getHandcardNum();
                }
                int draw = qMin(5, n - target->getHandcardNum());
                if (draw <= 0) return false;
                target->drawCards(draw, objectName());
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.to && move.to_place == Player::DiscardPile) {
                foreach (int id, move.card_ids) {
                    const Card *card = Sanguosha->getCard(id);
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (p->isDead() || !p->hasSkill(this) || p->getPile("bzbiao").isEmpty()) continue;
                        foreach (int idd, p->getPile("bzbiao")) {
                            if (p->isDead() || !p->hasSkill(this)) continue;
                            const Card *c = Sanguosha->getCard(idd);
                            if (card->getSuit() == c->getSuit() && card->getNumber() == c->getNumber()) {
                                room->sendCompulsoryTriggerLog(p, objectName() ,true, true);
                                if (((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) &&
                                        move.from && move.from->isAlive()) {
                                    ServerPlayer *from = room->findPlayerByObjectName(move.from->objectName());
                                    if (!from || from->isDead()) {
                                        CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), p->objectName(), "biaozhao", QString());
                                        room->throwCard(c, reason, NULL);
                                    } else {
                                        room->obtainCard(from, c, true);
                                    }
                                } else {
                                    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), p->objectName(), "biaozhao", QString());
                                    room->throwCard(c, reason, NULL);
                                }
                                room->loseHp(p);
                            }
                        }
                    }
                }
            }
        }
        return false;
    }
};

class Yechou : public TriggerSkill
{
public:
    Yechou() : TriggerSkill("yechou")
    {
        events << Death << EventPhaseChanging << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player || !death.who->hasSkill(this)) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getLostHp() > 1)
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@yechou-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(target, "&yechou");
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead() || p->getMark("&yechou") <= 0) continue;
                for (int i = 0; i < p->getMark("&yechou"); i++) {
                    if (p->isDead()) break;
                    LogMessage log;
                    log.type = "#YechouEffect";
                    log.from = p;
                    log.arg = objectName();
                    room->sendLog(log);
                    room->loseHp(p);
               }
            }
        } else {
            if (player->isDead()) return false;
            if (player->getPhase() != Player::RoundStart || player->getMark("&yechou") <= 0) return false;
            room->setPlayerMark(player, "&yechou", 0);
        }
        return false;
    }
};

class Guanwei : public TriggerSkill
{
public:
    Guanwei() : TriggerSkill("guanwei")
    {
        events << EventPhaseEnd << CardFinished << EventPhaseChanging;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play) return false;
            foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
                if (player->isDead()) return false;
                if (player->getMark("guanwei_disable-Clear") > 0 || player->getMark("guanwei_num-Clear") < 2) return false;
                if (p->isDead() || !p->hasSkill(this) || p->getMark("guanwei_used-Clear") > 0 || !p->canDiscard(p, "he")) continue;
                const Card *card = room->askForCard(p, "..", "guanwei-invoke:" + player->objectName(), QVariant::fromValue(player), objectName());
                if (!card) continue;
                room->broadcastSkillInvoke(objectName());
                room->addPlayerMark(p, "guanwei_used-Clear");
                player->drawCards(2, objectName());
                if (player->isDead()) return false;

                room->addPlayerHistory(player, ".");
                foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                    foreach (QString mark, p->getMarkNames()) {
                        if (mark.endsWith("-PlayClear") && p->getMark(mark) > 0)
                            room->setPlayerMark(p, mark, 0);
                    }
                }

                RoomThread *thread = room->getThread();
                if (!thread->trigger(EventPhaseStart, room, player)) {
                    thread->trigger(EventPhaseProceeding, room, player);
                }
                thread->trigger(EventPhaseEnd, room, player);
            }
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            room->setPlayerProperty(player, "guanwei_used_suit", QString());
        } else {
            if (player->isDead()) return false;
            //if (player->getPhase() == Player::NotActive) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "guanwei_num-Clear");
            QString suit = use.card->getSuitString();
            QString used_suit = player->property("guanwei_used_suit").toString();
            if (used_suit != QString() && used_suit != suit)
                room->addPlayerMark(player, "guanwei_disable-Clear");
            else if (used_suit == QString())
                room->setPlayerProperty(player, "guanwei_used_suit", suit);
        }
        return false;
    }
};

class Gongqing : public TriggerSkill
{
public:
    Gongqing() : TriggerSkill("gongqing")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->isDead()) return false;
        int n = damage.from->getAttackRange();
        if (n == 3) return false;

        LogMessage log;
        log.from = player;
        log.to << damage.from;
        log.arg = QString::number(damage.damage);
        if (n < 3) {
            if (damage.damage <= 1) return false;
            log.type = "#GongqingReduce";
            log.arg2 = QString::number(1);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
            damage.damage = 1;
        } else {
            log.type = "#GongqingAdd";
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
        }
        data = QVariant::fromValue(damage);
        return false;
    }
};

FuhaiCard::FuhaiCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void FuhaiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int sid = getSubcards().first();
    int tid = -1;
    ServerPlayer *now = source;
    int times = 0;

    while (!source->isKongcheng()) {
        if (source->isDead() || source->getMark("fuhai_disable-PlayClear") > 0) return;

        QStringList choices;
        ServerPlayer *next = now->getNextAlive();
        ServerPlayer *last = now->getNextAlive(room->alivePlayerCount() - 1);

        if (last->isAlive() && !last->isKongcheng() && last->getMark("fuhai-PlayClear") <= 0 && last != source)
            choices << "last";
        if (next != last && next->isAlive() && !next->isKongcheng() && next->getMark("fuhai-PlayClear") <= 0 && next != source)
            choices << "next";
        if (choices.isEmpty()) return;

        if (sid < 0) {
            source->tag["FuhaiNow"] = QVariant::fromValue(now);
            sid = room->askForCardShow(source, source, "fuhai")->getEffectiveId();
            source->tag.remove("FuhaiNow");
            if (sid < 0) return;
        }
        room->showCard(source, sid);

        QString  choice = room->askForChoice(source, "fuhai", choices.join("+"), QVariant::fromValue(now));
        if (choice == "last")
            now = last;
        else
            now = next;
        room->addPlayerMark(now, "fuhai-PlayClear");
        times++;

        if (now->isDead() || now->isKongcheng()) return;
        room->doAnimate(1, source->objectName(), now->objectName());
        now->tag["FuhaiID"] = sid + 1;
        tid = room->askForCardShow(now, source, "fuhai")->getEffectiveId();
        now->tag.remove("FuhaiID");
        if (tid < 0) return;
        room->showCard(now, tid);

        int snum = Sanguosha->getCard(sid)->getNumber();
        int tnum = Sanguosha->getCard(tid)->getNumber();
        if (snum >= tnum) {
            room->throwCard(sid, source, NULL);
        } else {
            room->throwCard(tid, now, NULL);
            QList<ServerPlayer *> players;
            players << source << now;
            room->sortByActionOrder(players);
            room->drawCards(players, times, "fuhai");
            room->addPlayerMark(source, "fuhai_disable-PlayClear");
        }
        sid = -1;
    }
}

class Fuhai : public OneCardViewAsSkill
{
public:
    Fuhai() : OneCardViewAsSkill("fuhai")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("fuhai_disable-PlayClear") > 0) return false;
        foreach (const Player *p, player->getAliveSiblings()) {
            if (p->getMark("fuhai-PlayClear") <= 0)
                return true;
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        FuhaiCard *c = new FuhaiCard;
        c->addSubcard(originalCard);
        return c;
    }
};

MobileFuhaiCard::MobileFuhaiCard()
{
    target_fixed = true;
}

void MobileFuhaiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QStringList choices;
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (p->isDead()) continue;
        QString choice = room->askForChoice(p, "mobilefuhai", "up+down");
        if (p->isAlive())
            choices << choice;
    }
    if (choices.isEmpty()) return;

    int i = 0;
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if  (i > choices.length()) break;
        if (p->isDead()) continue;
        LogMessage log;
        log.type = "#ShouxiChoice";
        log.from = p;
        log.arg = "mobilefuhai:" + choices.at(i);
        room->sendLog(log);
        i++;
    }

    int draw = 1;
    while (draw < choices.length()) {
        if (choices.at(draw - 1) != choices.at(draw)) break;
        draw++;
    }
    if (draw <= 1) return;
    source->drawCards(draw, "mobilefuhai");
}

class MobileFuhai : public ZeroCardViewAsSkill
{
public:
    MobileFuhai() : ZeroCardViewAsSkill("mobilefuhai")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileFuhaiCard");
    }

    const Card *viewAs() const
    {
        MobileFuhaiCard *c = new MobileFuhaiCard;
        return c;
    }
};

class Wenji : public TriggerSkill
{
public:
    Wenji() : TriggerSkill("wenji")
    {
        events << EventPhaseStart << CardUsed << EventPhaseChanging;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;

            QList<ServerPlayer *> players;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!p->isNude())
                    players << p;
            }
            if (players.isEmpty()) return false;
            ServerPlayer * target = room->askForPlayerChosen(player, players, objectName(), "@wenji-invoke", true, true);
            if (!target || target->isNude()) {
                room->setPlayerProperty(player, "wenji_name", QString());
                return false;
            }
            room->broadcastSkillInvoke(objectName());
            const Card *c = NULL;
            const Card *card = room->askForCard(target, "..", "wenji-give:" + player->objectName(), QVariant::fromValue(player), Card::MethodNone);
            if (!card) {
                card = target->getCards("he").at(qrand() % target->getCards("he").length());
                c = card;
            } else
                c = Sanguosha->getCard(card->getSubcards().first());

            if (!card || !c) return false;
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "wenji", QString());
            room->obtainCard(player, card, reason, true);

            QString name = c->objectName();
            room->setPlayerProperty(player, "wenji_name", name);

            if (c->isKindOf("Slash"))
                name = "slash";
            room->addPlayerMark(player, "&wenji+" + name + "-Clear");
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            room->setPlayerProperty(player, "wenji_name", QString());
        } else {
            if (player->getPhase() == Player::NotActive) return false;
            QString name = player->property("wenji_name").toString();
            if (name == QString()) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (!use.card->sameNameWith(name) || use.to.isEmpty()) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                use.no_respond_list << p->objectName();
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class Tunjiang : public TriggerSkill
{
public:
    Tunjiang() : TriggerSkill("tunjiang")
    {
        events << PreCardUsed << EventPhaseStart << EventPhaseSkipped;
        global = true;
        frequency = Frequent;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == PreCardUsed)
            return 6;
        else
            return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == PreCardUsed && player->isAlive() && player->getPhase() == Player::Play
            && player->getMark("tunjiang-Clear") <= 0) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() != Card::TypeSkill) {
                foreach (ServerPlayer *p, use.to) {
                    if (p != player) {
                        player->addMark("tunjiang-Clear");
                        return false;
                    }
                }
            }
        } else if (triggerEvent == EventPhaseStart) {
            //if (!player->hasSkill(this) || player->getPhase() != Player::Finish || player->isSkipped(Player::Play)) return false;
            if (!player->hasSkill(this) || player->getPhase() != Player::Finish) return false;
            if (player->getMark("tunjiang-Clear") > 0) return false;
            if (player->getMark("tunjiang_skip_play-Clear") > 0) return false;
            if (!player->askForSkillInvoke(this)) return false;
            QStringList kingdoms;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (!kingdoms.contains(p->getKingdom()))
                    kingdoms << p->getKingdom();
            }
            if (kingdoms.length() <= 0) return false;
            room->broadcastSkillInvoke(objectName());
            player->drawCards(kingdoms.length(), objectName());
        } else if (triggerEvent == EventPhaseSkipped) {
            if (player->getPhase() != Player::Play) return false;
            room->addPlayerMark(player, "tunjiang_skip_play-Clear");
        }
        return false;
    }
};

SP1Package::SP1Package()
: Package("sp1")
{
    General *wanglang = new General(this, "wanglang", "wei", 3);
    wanglang->addSkill(new Gushe);
    wanglang->addSkill(new Jici);

    General *tenyear_wanglang = new General(this, "tenyear_wanglang", "wei", 3);
    tenyear_wanglang->addSkill(new TenyearGushe);
    tenyear_wanglang->addSkill(new TenyearJici);

    General *sp_luzhi = new General(this, "sp_luzhi", "wei", 3);
    sp_luzhi->addSkill(new Qingzhong);
    sp_luzhi->addSkill(new Weijing);

    General *wenyang = new General(this, "wenyang", "wei", 5);
    wenyang->addSkill(new Lvli);
    wenyang->addSkill(new Choujue);
    wenyang->addRelateSkill("beishui");
    wenyang->addRelateSkill("qingjiao");

    General *jianggan = new General(this, "jianggan", "wei", 3);
    jianggan->addSkill(new Weicheng);
    jianggan->addSkill(new Daoshu);

    General *tangzi = new General(this, "tangzi", "wei", 4);
    tangzi->addSkill(new Xingzhao);
    tangzi->addSkill(new XingzhaoXunxun);
    tangzi->addRelateSkill("xunxun");
    related_skills.insertMulti("xingzhao", "#xingzhao-xunxun");

    General *simazhao = new General(this, "simazhao", "wei", 3);
    simazhao->addSkill(new Daigong);
    simazhao->addSkill(new SpZhaoxin);

    General *jiakui = new General(this, "jiakui", "wei", 3);
    jiakui->addSkill(new Zhongzuo);
    jiakui->addSkill(new ZhongzuoRecord);
    jiakui->addSkill(new Wanlan);
    jiakui->addSkill(new WanlanDamage);
    related_skills.insertMulti("zhongzuo", "#zhongzuo-record");
    related_skills.insertMulti("wanlan", "#wanlan-damage");

    General *new_jiakui = new General(this, "new_jiakui", "wei", 4);
    new_jiakui->addSkill(new Tongqu);
    new_jiakui->addSkill(new TongquTrigger);
    new_jiakui->addSkill(new NewWanlan);
    related_skills.insertMulti("tongqu", "#tongqu-trigger");

    General *wangyuanji = new General(this, "wangyuanji", "wei", 3, false);
    wangyuanji->addSkill(new Qianchong);
    wangyuanji->addSkill(new QianchongTargetMod);
    wangyuanji->addSkill(new QianchongLose);
    wangyuanji->addSkill(new Shangjian);
    wangyuanji->addSkill(new ShangjianMark);
    related_skills.insertMulti("qianchong", "#qianchong-target");
    related_skills.insertMulti("qianchong", "#qianchong-lose");
    related_skills.insertMulti("shangjian", "#shangjian-mark");

    General *xinpi = new General(this, "xinpi", "wei", 3);
    xinpi->addSkill(new Chijie);
    xinpi->addSkill(new Yinju);

    General *wangshuang = new General(this, "wangshuang", "wei", 8);
    wangshuang->addSkill(new Zhuilie);
    wangshuang->addSkill(new ZhuilieSlash);
    related_skills.insertMulti("zhuilie", "#zhuilie-slash");

    General *guanlu = new General(this, "guanlu", "wei", 3);
    guanlu->addSkill(new Tuiyan("tuiyan"));
    guanlu->addSkill(new Busuan);
    guanlu->addSkill(new Mingjie("mingjie"));

    General *tenyear_guanlu = new General(this, "tenyear_guanlu", "wei", 3);
    tenyear_guanlu->addSkill(new Tuiyan("tenyeartuiyan"));
    tenyear_guanlu->addSkill("busuan");
    tenyear_guanlu->addSkill(new Mingjie("tenyearmingjie"));

    General *zhanggong = new General(this, "zhanggong", "wei", 3);
    zhanggong->addSkill(new SpQianxin);
    zhanggong->addSkill(new Zhenxing);

    General *mobile_zhanggong = new General(this, "mobile_zhanggong", "wei", 3);
    mobile_zhanggong->addSkill(new MobileSpQianxin);
    mobile_zhanggong->addSkill(new MobileSpQianxinMove);
    mobile_zhanggong->addSkill(new MobileZhenxing);
    related_skills.insertMulti("mobilespqianxin", "#mobilespqianxin-move");

    General *sp_yiji = new General(this, "sp_yiji", "shu", 3);
    sp_yiji->addSkill(new Jijie);
    sp_yiji->addSkill(new Jiyuan);

    General *mizhu = new General(this, "mizhu", "shu", 3);
    mizhu->addSkill(new Ziyuan);
    mizhu->addSkill(new Jugu);
    mizhu->addSkill(new JuguMax);
    related_skills.insertMulti("jugu", "#jugu-max");

    General *dongyun = new General(this, "dongyun", "shu", 3);
    dongyun->addSkill(new Bingzheng);
    dongyun->addSkill(new Sheyan);
    dongyun->addSkill(new SheyanTargetMod);
    related_skills.insertMulti("sheyan", "#sheyan-target");

    General *mazhong = new General(this, "mazhong", "shu", 4);
    mazhong->addSkill(new Fuman);

    General *lvkai = new General(this, "lvkai", "shu", 3);
    lvkai->addSkill(new Tunan);
    lvkai->addSkill(new TunanTargetMod);
    lvkai->addSkill(new Bijing);
    related_skills.insertMulti("tunan", "#tunan-target");

    General *huangquan = new General(this, "huangquan", "shu", 3);
    huangquan->addSkill(new Dianhu);
    huangquan->addSkill(new DianhuTarget);
    huangquan->addSkill(new Jianji);
    related_skills.insertMulti("dianhu", "#dianhu-target");

    General *shamoke = new General(this, "shamoke", "shu", 4);
    shamoke->addSkill(new Jili);

    General *zhaotongzhaoguang = new General(this, "zhaotongzhaoguang", "shu", 4);
    zhaotongzhaoguang->addSkill(new Yizan);
    zhaotongzhaoguang->addSkill(new Longyuan);

    General *hujinding = new General(this, "hujinding", "shu", 6, false, false, false, 2);
    hujinding->addSkill(new Renshi);
    hujinding->addSkill(new Wuyuan);
    hujinding->addSkill(new Huaizi);

    General *xujing = new General(this, "xujing", "shu", 3);
    xujing->addSkill(new Yuxu);
    xujing->addSkill(new Shijian);

    General *huaman = new General(this, "huaman", "shu", 3, false);
    huaman->addSkill(new SpManyi);
    huaman->addSkill(new Mansi);
    huaman->addSkill(new Souying);
    huaman->addSkill(new Zhanyuan);
    huaman->addSkill(new ZhanyuanRecord("zhanyuan"));
    huaman->addRelateSkill("xili");
    related_skills.insertMulti("zhanyuan", "#zhanyuan");

    General *second_huaman = new General(this, "second_huaman", "shu", 3, false);
    second_huaman->addSkill("spmanyi");
    second_huaman->addSkill(new SecondMansi);
    second_huaman->addSkill(new SecondSouying);
    second_huaman->addSkill(new SecondSouyingRecord);
    second_huaman->addSkill(new SecondZhanyuan);
    second_huaman->addSkill(new ZhanyuanRecord("secondzhanyuan"));
    second_huaman->addRelateSkill("secondxili");
    related_skills.insertMulti("secondsouying", "#secondsouying-record");
    related_skills.insertMulti("secondzhanyuan", "#secondzhanyuan");

    General *buzhi = new General(this, "buzhi", "wu", 3);
    buzhi->addSkill(new Hongde);
    buzhi->addSkill(new Dingpan);
    buzhi->addSkill(new DingpanRevived);
    related_skills.insertMulti("dingpan", "#dingpan-revived");

    General *heqi = new General(this, "heqi", "wu", 4);
    heqi->addSkill(new Qizhou("qizhou"));
    heqi->addSkill(new QizhouLose("qizhou"));
    heqi->addSkill(new Shanxi);
    heqi->addRelateSkill("yingzi");
    heqi->addRelateSkill("duanbing");
    related_skills.insertMulti("qizhou", "#qizhou-lose");

    General *ol_heqi = new General(this, "ol_heqi", "wu", 4);
    ol_heqi->addSkill(new Qizhou("olqizhou"));
    ol_heqi->addSkill(new QizhouLose("olqizhou"));
    ol_heqi->addSkill("shanxi");
    ol_heqi->addRelateSkill("yingzi");
    ol_heqi->addRelateSkill("olduanbing");
    related_skills.insertMulti("olqizhou", "#olqizhou-lose");

    General *mobile_heqi = new General(this, "mobile_heqi", "wu", 4);
    mobile_heqi->addSkill(new MobileQizhou);
    mobile_heqi->addSkill(new MobileQizhouLose);
    mobile_heqi->addSkill(new MobileShanxi);
    mobile_heqi->addSkill(new MobileShanxiGet);
    mobile_heqi->addSkill(new FakeMoveSkill("mobileshanxi"));
    mobile_heqi->addRelateSkill("nosyingzi");
    related_skills.insertMulti("mobileqizhou", "#mobileqizhou-lose");
    related_skills.insertMulti("mobileshanxi", "#mobileshanxi-get");
    related_skills.insertMulti("mobileshanxi", "#mobileshanxi-fake-move");

    General *kanze = new General(this, "kanze", "wu", 3);
    kanze->addSkill(new Xiashu);
    kanze->addSkill(new Kuanshi("kuanshi"));
    kanze->addSkill(new KuanshiMark("kuanshi"));
    kanze->addSkill(new KuanshiEffect);
    related_skills.insertMulti("kuanshi", "#kuanshi-mark");
    related_skills.insertMulti("kuanshi", "#kuanshi-effect");

    General *tenyear_kanze = new General(this, "tenyear_kanze", "wu", 3);
    tenyear_kanze->addSkill("xiashu");
    tenyear_kanze->addSkill(new Kuanshi("tenyearkuanshi"));
    tenyear_kanze->addSkill(new KuanshiMark("tenyearkuanshi"));
    tenyear_kanze->addSkill(new TenyearKuanshiEffect);
    related_skills.insertMulti("tenyearkuanshi", "#tenyearkuanshi-mark");
    related_skills.insertMulti("tenyearkuanshi", "#tenyearkuanshi-effect");

    General *sp_pangtong = new General(this, "sp_pangtong", "wu", 3);
    sp_pangtong->addSkill(new Guolun);
    sp_pangtong->addSkill(new Songsang);
    sp_pangtong->addRelateSkill("zhanji");

    General *sunshao = new General(this, "sunshao", "wu", 3);
    sunshao->addSkill(new Bizheng);
    sunshao->addSkill(new Yidian);
    sunshao->addSkill(new YidianTargetMod);
    related_skills.insertMulti("yidian", "#yidian-target");

    General *sufei = new General(this, "sufei", "wu", 4);
    sufei->addSkill(new Lianpian);

    General *yanjun = new General(this, "yanjun", "wu", 3);
    yanjun->addSkill(new Guanchao);
    yanjun->addSkill(new Xunxian);

    General *zhoufang = new General(this, "zhoufang", "wu", 3);
    zhoufang->addSkill(new SpYoudi);
    zhoufang->addSkill(new Duanfa);

    General *lvdai = new General(this, "lvdai", "wu", 4);
    lvdai->addSkill(new Qinguo);

    General *gexuan = new General(this, "gexuan", "wu", 3);
    gexuan->addSkill(new Lianhua);
    gexuan->addSkill(new LianhuaEffect);
    gexuan->addSkill(new Zhafu);
    related_skills.insertMulti("lianhua", "#lianhua-effect");

    General *zhangwen = new General(this, "zhangwen", "wu", 3);
    zhangwen->addSkill(new Songshu);
    zhangwen->addSkill(new Sibian);

    General *xugong = new General(this, "xugong", "wu", 3);
    xugong->addSkill(new Biaozhao);
    xugong->addSkill(new Yechou);

    General *panjun = new General(this, "panjun", "wu", 3);
    panjun->addSkill(new Guanwei);
    panjun->addSkill(new Gongqing);

    General *weiwenzhugezhi = new General(this, "weiwenzhugezhi", "wu", 4);
    weiwenzhugezhi->addSkill(new Fuhai);

    General *mobile_weiwenzhugezhi = new General(this, "mobile_weiwenzhugezhi", "wu", 4);
    mobile_weiwenzhugezhi->addSkill(new MobileFuhai);

    General *liuqi = new General(this, "liuqi", "qun", 3);
    liuqi->addSkill(new Wenji);
    liuqi->addSkill(new Tunjiang);

    addMetaObject<GusheCard>();
    addMetaObject<TenyearGusheCard>();
    addMetaObject<DaoshuCard>();
    addMetaObject<SpZhaoxinCard>();
    addMetaObject<SpZhaoxinChooseCard>();
    addMetaObject<TongquCard>();
    addMetaObject<YinjuCard>();
    addMetaObject<BusuanCard>();
    addMetaObject<SpQianxinCard>();
    addMetaObject<MobileSpQianxinCard>();
    addMetaObject<JijieCard>();
    addMetaObject<ZiyuanCard>();
    addMetaObject<FumanCard>();
    addMetaObject<TunanCard>();
    addMetaObject<JianjiCard>();
    addMetaObject<YizanCard>();
    addMetaObject<WuyuanCard>();
    addMetaObject<SecondMansiCard>();
    addMetaObject<DingpanCard>();
    addMetaObject<ShanxiCard>();
    addMetaObject<MobileShanxiCard>();
    addMetaObject<GuolunCard>();
    addMetaObject<DuanfaCard>();
    addMetaObject<QinguoCard>();
    addMetaObject<ZhafuCard>();
    addMetaObject<SongshuCard>();
    addMetaObject<FuhaiCard>();
    addMetaObject<MobileFuhaiCard>();

    skills << new Beishui
           << new Qingjiao << new Zhanji << new Xili << new SecondXili;
}

ADD_PACKAGE(SP1)
