#include "serverplayer.h"
#include "skill.h"
#include "engine.h"
#include "standard.h"
#include "maneuvering.h"
#include "ai.h"
#include "settings.h"
#include "recorder.h"
#include "banpair.h"
#include "lua-wrapper.h"
#include "json.h"
#include "gamerule.h"
#include "util.h"
#include "exppattern.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "socket.h"

using namespace QSanProtocol;

const int ServerPlayer::S_NUM_SEMAPHORES = 6;

ServerPlayer::ServerPlayer(Room *room)
    : Player(room), m_isClientResponseReady(false), m_isWaitingReply(false),
    socket(NULL), room(room),
    ai(NULL), trust_ai(new TrustAI(this)), recorder(NULL),
    _m_phases_index(0), next(NULL)
{
    semas = new QSemaphore *[S_NUM_SEMAPHORES];
    for (int i = 0; i < S_NUM_SEMAPHORES; i++)
        semas[i] = new QSemaphore(0);
}

ServerPlayer::~ServerPlayer()
{
    for (int i = 0; i < S_NUM_SEMAPHORES; i++)
        delete semas[i];
    delete[] semas;
    delete trust_ai;
}

void ServerPlayer::drawCard(const Card *card)
{
    handcards << card;
}

Room *ServerPlayer::getRoom() const
{
    return room;
}

void ServerPlayer::broadcastSkillInvoke(const QString &card_name) const
{
    room->broadcastSkillInvoke(card_name, isMale(), -1);
}

void ServerPlayer::broadcastSkillInvoke(const Card *card) const
{
    if (card->isMute())
        return;

    QString skill_name = card->getSkillName();
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (skill == NULL) {
        if (card->getCommonEffectName().isNull())
            broadcastSkillInvoke(card->objectName());
        else
            room->broadcastSkillInvoke(card->getCommonEffectName(), "common");
        return;
    } else {
        int index = skill->getEffectIndex(this, card);
        if (index == 0) return;

        if ((index == -1 && skill->getSources().isEmpty()) || index == -2) {
            if (card->getCommonEffectName().isNull())
                broadcastSkillInvoke(card->objectName());
            else
                room->broadcastSkillInvoke(card->getCommonEffectName(), "common");
        } else {
            ServerPlayer *player = room->findChild<ServerPlayer *>(objectName());
            if (player)
                player->peiyin(skill_name, index);
            else
                room->broadcastSkillInvoke(skill_name, index);
        }
    }
}

void ServerPlayer::peiyin(const Skill *skill, int type)
{
    Q_ASSERT(skill != NULL);
    if (!skill) return;
    room->broadcastSkillInvoke(skill, type, this);
}

void ServerPlayer::peiyin(const QString &skillName, int type)
{
    room->broadcastSkillInvoke(skillName, type, this);
}

int ServerPlayer::getRandomHandCardId() const
{
    return getRandomHandCard()->getEffectiveId();
}

const Card *ServerPlayer::getRandomHandCard() const
{
    int index = qrand() % handcards.length();
    return handcards.at(index);
}

void ServerPlayer::obtainCard(const Card *card, bool unhide)
{
    CardMoveReason reason(CardMoveReason::S_REASON_GOTCARD, objectName());
    room->obtainCard(this, card, reason, unhide);
}

void ServerPlayer::throwAllEquips()
{
    QList<const Card *> equips = getEquips();

    if (equips.isEmpty()) return;

    DummyCard *card = new DummyCard;
    foreach (const Card *equip, equips) {
        if (!isJilei(card))
            card->addSubcard(equip);
    }
    if (card->subcardsLength() > 0)
        room->throwCard(card, this);
    delete card;
}

void ServerPlayer::throwAllHandCards()
{
    int card_length = getHandcardNum();
    room->askForDiscard(this, QString(), card_length, card_length);
}

void ServerPlayer::throwAllHandCardsAndEquips()
{
    int card_length = getCardCount();
    room->askForDiscard(this, QString(), card_length, card_length, false, true);
}

void ServerPlayer::throwAllMarks(bool visible_only)
{
    // throw all marks
    foreach (QString mark_name, marks.keys()) {
        if (mark_name == "@bossExp" || (visible_only && !mark_name.startsWith("@") && !mark_name.startsWith("&")) || mark_name.endsWith("-Keep"))
            continue;

        int n = marks.value(mark_name, 0);
        if (n != 0)
            room->setPlayerMark(this, mark_name, 0);
    }
}

void ServerPlayer::clearOnePrivatePile(QString pile_name)
{
    if (!piles.contains(pile_name))
        return;
    QList<int> &pile = piles[pile_name];

    if (pile.isEmpty()) return;

    DummyCard *dummy = new DummyCard(pile);
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, this->objectName());
    room->throwCard(dummy, reason, NULL);
    delete dummy;
    piles.remove(pile_name);
}

void ServerPlayer::clearPrivatePiles()
{
    foreach(QString pile_name, piles.keys())
        clearOnePrivatePile(pile_name);
    piles.clear();
}

void ServerPlayer::bury()
{
    clearFlags();
    clearHistory();
    throwAllCards();
    throwAllMarks();
    clearPrivatePiles();

    room->clearPlayerCardLimitation(this, false);
}

void ServerPlayer::throwAllCards()
{
    DummyCard *card = isKongcheng() ? new DummyCard : wholeHandCards();
    foreach(const Card *equip, getEquips())
        card->addSubcard(equip);
    if (card->subcardsLength() != 0)
        room->throwCard(card, this);
    delete card;

    QList<const Card *> tricks = getJudgingArea();
    foreach (const Card *trick, tricks) {
        CardMoveReason reason(CardMoveReason::S_REASON_THROW, this->objectName());
        room->throwCard(trick, reason, NULL);
    }
}

void ServerPlayer::drawCards(int n, const QString &reason, bool isTop, bool visible)
{
    room->drawCards(this, n, reason, isTop, visible);
}

QList<int> ServerPlayer::drawCardsList(int n, const QString &reason, bool isTop, bool visible)
{
    return room->drawCardsList(this, n, reason, isTop, visible);
}

bool ServerPlayer::askForSkillInvoke(const QString &skill_name, const QVariant &data, bool notify)
{
    return room->askForSkillInvoke(this, skill_name, data, notify);
}

bool ServerPlayer::askForSkillInvoke(const Skill *skill, const QVariant &data, bool notify)
{
    Q_ASSERT(skill != NULL);
    return askForSkillInvoke(skill->objectName(), data, notify);
}

bool ServerPlayer::askForSkillInvoke(const QString &skill_name, ServerPlayer *player, bool notify)
{
    return askForSkillInvoke(skill_name, player == NULL ? QVariant() : QVariant::fromValue(player), notify);
}

bool ServerPlayer::askForSkillInvoke(const Skill *skill, ServerPlayer *player, bool notify)
{
    Q_ASSERT(skill != NULL);
    return askForSkillInvoke(skill->objectName(), player, notify);
}

QList<int> ServerPlayer::forceToDiscard(int discard_num, bool include_equip, bool is_discard, const QString &pattern)
{
    QList<int> to_discard;

    QString flags = "h";
    if (include_equip)
        flags.append("e");

    QList<const Card *> all_cards = getCards(flags);
    qShuffle(all_cards);
    ExpPattern exp_pattern(pattern);

    for (int i = 0; i < all_cards.length(); i++) {
        if (!exp_pattern.match(this, all_cards.at(i)))
            continue;
        if (!is_discard || !isJilei(all_cards.at(i)))
            to_discard << all_cards.at(i)->getId();
        if (to_discard.length() == discard_num)
            break;
    }

    return to_discard;
}

int ServerPlayer::aliveCount() const
{
    return room->alivePlayerCount();
}

int ServerPlayer::getHandcardNum() const
{
    return handcards.length();
}

void ServerPlayer::setSocket(ClientSocket *socket)
{
    if (socket) {
        connect(socket, SIGNAL(disconnected()), this, SIGNAL(disconnected()));
        connect(socket, SIGNAL(message_got(const char *)), this, SLOT(getMessage(const char *)));
        connect(this, SIGNAL(message_ready(QString)), this, SLOT(sendMessage(QString)));
    } else {
        if (this->socket) {
            this->disconnect(this->socket);
            this->socket->disconnect(this);
            this->socket->disconnectFromHost();
            this->socket->deleteLater();
        }

        disconnect(this, SLOT(sendMessage(QString)));
    }

    this->socket = socket;
}

void ServerPlayer::kick()
{
    room->notifyProperty(this, this, "flags", "is_kicked");
    if (socket != NULL)
        socket->disconnectFromHost();
    setSocket(NULL);
}

void ServerPlayer::getMessage(const char *message)
{
    QString request = message;
    if (request.endsWith("\n"))
        request.chop(1);

    emit request_got(request);
}

void ServerPlayer::unicast(const QString &message)
{
    emit message_ready(message);

    if (recorder)
        recorder->recordLine(message);
}

void ServerPlayer::startNetworkDelayTest()
{
    test_time = QDateTime::currentDateTime();
    Packet packet(S_SRC_ROOM | S_TYPE_NOTIFICATION | S_DEST_CLIENT, S_COMMAND_NETWORK_DELAY_TEST);
    invoke(&packet);
}

qint64 ServerPlayer::endNetworkDelayTest()
{
    return test_time.msecsTo(QDateTime::currentDateTime());
}

void ServerPlayer::startRecord()
{
    recorder = new Recorder(this);
}

void ServerPlayer::saveRecord(const QString &filename)
{
    if (recorder)
        recorder->save(filename);
}

void ServerPlayer::addToSelected(const QString &general)
{
    selected.append(general);
}

QStringList ServerPlayer::getSelected() const
{
    return selected;
}

QString ServerPlayer::findReasonable(const QStringList &generals, bool no_unreasonable)
{
    foreach (QString name, generals) {
        if (Config.Enable2ndGeneral) {
            if (getGeneral()) {
                if (!BanPair::isBanned(getGeneralName()) && BanPair::isBanned(getGeneralName(), name)) continue;
            } else {
                if (BanPair::isBanned(name)) continue;
            }

            if (Config.EnableHegemony && getGeneral()
                && getGeneral()->getKingdom() != Sanguosha->getGeneral(name)->getKingdom())
                continue;
        }
        if (Config.EnableBasara) {
            QStringList ban_list = Config.value("Banlist/Basara").toStringList();
            if (ban_list.contains(name)) continue;
        }
        if (Config.GameMode == "zombie_mode") {
            QStringList ban_list = Config.value("Banlist/Zombie").toStringList();
            if (ban_list.contains(name))continue;
        }
        if (Config.GameMode.endsWith("p")
            || Config.GameMode.endsWith("pd")
            || Config.GameMode.endsWith("pz")
            || Config.GameMode.contains("_mini_")
            || Config.GameMode == "custom_scenario") {
            QStringList ban_list = Config.value("Banlist/Roles").toStringList();
            if (ban_list.contains(name)) continue;
        }

        return name;
    }

    if (no_unreasonable)
        return QString();

    return generals.first();
}

void ServerPlayer::clearSelected()
{
    selected.clear();
}

void ServerPlayer::sendMessage(const QString &message)
{
    if (socket) {
#ifndef QT_NO_DEBUG
        printf("%s", qPrintable(objectName()));
#endif
#ifdef LOGNETWORK
        emit Sanguosha->logNetworkMessage("send "+this->objectName()+":"+message);
#endif
        socket->send(message);
    }
}

void ServerPlayer::invoke(const AbstractPacket *packet)
{
    unicast(packet->toString());
}

QString ServerPlayer::reportHeader() const
{
    QString name = objectName();
    return QString("%1 ").arg(name.isEmpty() ? tr("Anonymous") : name);
}

void ServerPlayer::removeCard(const Card *card, Place place)
{
    switch (place) {
    case PlaceHand: {
        handcards.removeOne(card);
        break;
    }
    case PlaceEquip: {
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        if (equip == NULL)
            equip = qobject_cast<const EquipCard *>(Sanguosha->getEngineCard(card->getEffectiveId()));
        Q_ASSERT(equip != NULL);
        equip->onUninstall(this);

        WrappedCard *wrapped = Sanguosha->getWrappedCard(card->getEffectiveId());
        removeEquip(wrapped);

        bool show_log = true;
        foreach(QString flag, flags)
            if (flag.endsWith("_InTempMoving")) {
                show_log = false;
                break;
            }
        if (show_log) {
            LogMessage log;
            log.type = "$Uninstall";
            log.card_str = wrapped->toString();
            log.from = this;
            room->sendLog(log);
        }
        break;
    }
    case PlaceDelayedTrick: {
        removeDelayedTrick(card);
        break;
    }
    case PlaceSpecial: {
        int card_id = card->getEffectiveId();
        QString pile_name = getPileName(card_id);

        //@todo: sanity check required
        if (!pile_name.isEmpty())
            piles[pile_name].removeOne(card_id);

        break;
    }
    default:
        break;
    }
}

void ServerPlayer::addCard(const Card *card, Place place)
{
    switch (place) {
    case PlaceHand: {
        handcards << card;
        break;
    }
    case PlaceEquip: {
        WrappedCard *wrapped = Sanguosha->getWrappedCard(card->getEffectiveId());
        const EquipCard *equip = qobject_cast<const EquipCard *>(wrapped->getRealCard());
        setEquip(wrapped);
        equip->onInstall(this);
        break;
    }
    case PlaceDelayedTrick: {
        addDelayedTrick(card);
        break;
    }
    default:
        break;
    }
}

bool ServerPlayer::isLastHandCard(const Card *card, bool contain) const
{
    if (!card->isVirtualCard()) {
        return handcards.length() == 1 && handcards.first()->getEffectiveId() == card->getEffectiveId();
    } else if (card->getSubcards().length() > 0) {
        if (!contain) {
            foreach (int card_id, card->getSubcards()) {
                if (!handcards.contains(Sanguosha->getCard(card_id)))
                    return false;
            }
            return handcards.length() == card->getSubcards().length();
        } else {
            foreach (const Card *ncard, handcards) {
                if (!card->getSubcards().contains(ncard->getEffectiveId()))
                    return false;
            }
            return true;
        }
    }
    return false;
}

QList<int> ServerPlayer::handCards() const
{
    QList<int> cardIds;
    foreach(const Card *card, handcards)
        cardIds << card->getId();
    return cardIds;
}

QList<const Card *> ServerPlayer::getHandcards() const
{
    return handcards;
}

QList<const Card *> ServerPlayer::getCards(const QString &flags) const
{
    QList<const Card *> cards;
    if (flags.contains("h"))
        cards << handcards;
    if (flags.contains("e"))
        cards << getEquips();
    if (flags.contains("j"))
        cards << getJudgingArea();

    return cards;
}

DummyCard *ServerPlayer::wholeHandCards() const
{
    if (isKongcheng()) return NULL;

    DummyCard *dummy_card = new DummyCard;
    foreach(const Card *card, handcards)
        dummy_card->addSubcard(card->getId());

    return dummy_card;
}

QList<int> ServerPlayer::getHandPile() const
{
    QList<int> handpile = Player::getHandPile();
    if (tag.value("TaoxiHere", false).toBool()) {
        bool ok = false;
        int id = tag.value("TaoxiId").toInt(&ok);
        if (ok && !handpile.contains(id))
            handpile << id;
    }

    return handpile;
}

bool ServerPlayer::hasNullification() const
{
    foreach (const Card *card, handcards) {
        if (card->objectName() == "nullification")
            return true;
    }
    foreach (int id, getHandPile()) {
        if (Sanguosha->getCard(id)->objectName() == "nullification")
            return true;
    }

    foreach (const Skill *skill, getVisibleSkillList(true)) {
        if (!hasSkill(skill)) continue;
        if (skill->inherits("ViewAsSkill")) {
            const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(skill);
            if (vsskill->isEnabledAtNullification(this)) return true;
        } else if (skill->inherits("TriggerSkill")) {
            const TriggerSkill *trigger_skill = qobject_cast<const TriggerSkill *>(skill);
            if (trigger_skill && trigger_skill->getViewAsSkill()) {
                const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(trigger_skill->getViewAsSkill());
                if (vsskill && vsskill->isEnabledAtNullification(this)) return true;
            }
        }
    }

    return false;
}

bool ServerPlayer::pindian(ServerPlayer *target, const QString &reason, const Card *card1)
{
    Q_ASSERT(this->canPindian(target, false));

    LogMessage log;
    log.type = "#Pindian";
    log.from = this;
    log.to << target;
    room->sendLog(log);

    PindianStruct *pindian_struct = new PindianStruct;
    pindian_struct->from = this;
    pindian_struct->to = target;
    pindian_struct->from_card = card1;
    pindian_struct->to_card = NULL;
    pindian_struct->reason = reason;

    RoomThread *thread = room->getThread();
    QVariant data = QVariant::fromValue(pindian_struct);
    thread->trigger(AskforPindianCard, room, this, data);

    PindianStruct *new_star = data.value<PindianStruct *>();
    card1 = new_star->from_card;
    const Card *card2 = new_star->to_card;

    if (card1 == NULL && card2 == NULL) {
        QList<const Card *> cards = room->askForPindianRace(this, target, reason);
        card1 = cards.first();
        card2 = cards.last();
    } else if (card2 == NULL) {
        if (card1->isVirtualCard()) {
            int card_id = card1->getEffectiveId();
            card1 = Sanguosha->getCard(card_id);
        }
        card2 = room->askForPindian(target, this, target, reason);
    } else if (card1 == NULL) {
        if (card2->isVirtualCard()) {
            int card_id = card2->getEffectiveId();
            card2 = Sanguosha->getCard(card_id);
        }
        card1 = room->askForPindian(this, this, target, reason);
    }

    if (card1 == NULL || card2 == NULL) return false;

    pindian_struct->from_card = card1;
    pindian_struct->to_card = card2;
    pindian_struct->from_number = card1->getNumber();
    pindian_struct->to_number = card2->getNumber();

    QList<CardsMoveStruct> moves;
    CardsMoveStruct move_table_1;
    move_table_1.card_ids << pindian_struct->from_card->getEffectiveId();
    move_table_1.from = room->getCardOwner(pindian_struct->from_card->getEffectiveId());
    move_table_1.to = NULL;
    move_table_1.to_place = Player::PlaceTable;
    move_table_1.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->from->objectName(),
        pindian_struct->to->objectName(), pindian_struct->reason, QString());

    CardsMoveStruct move_table_2;
    move_table_2.card_ids << pindian_struct->to_card->getEffectiveId();
    move_table_2.from = room->getCardOwner(pindian_struct->to_card->getEffectiveId());
    move_table_2.to = NULL;
    move_table_2.to_place = Player::PlaceTable;
    move_table_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());

    moves.append(move_table_1);
    moves.append(move_table_2);
    room->moveCardsAtomic(moves, true);

    log.type = "$PindianResult";
    log.from = pindian_struct->from;
    log.card_str = QString::number(pindian_struct->from_card->getEffectiveId());
    room->sendLog(log);

    log.type = "$PindianResult";
    log.from = pindian_struct->to;
    log.card_str = QString::number(pindian_struct->to_card->getEffectiveId());
    room->sendLog(log);

    thread->trigger(PindianVerifying, room, this, data);

    pindian_struct->success = pindian_struct->from_number > pindian_struct->to_number;

    log.type = pindian_struct->success ? "#PindianSuccess" : "#PindianFailure";
    log.from = this;
    log.to.clear();
    log.to << target;
    log.card_str.clear();
    room->sendLog(log);

    JsonArray arg;
    arg << S_GAME_EVENT_REVEAL_PINDIAN << objectName() << pindian_struct->from_card->getEffectiveId() << target->objectName()
        << pindian_struct->to_card->getEffectiveId() << pindian_struct->success << reason;
    room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

    thread->trigger(Pindian, room, this, data);

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
        if (pindian_struct->to_card->getEffectiveId() != pindian_struct->from_card->getEffectiveId()) {
            CardsMoveStruct move_discard_2;
            move_discard_2.card_ids << pindian_struct->to_card->getEffectiveId();
            move_discard_2.from = pindian_struct->to;
            move_discard_2.to = NULL;
            move_discard_2.to_place = Player::DiscardPile;
            move_discard_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());
            moves.append(move_discard_2);
        }
    }
    if (!moves.isEmpty())
        room->moveCardsAtomic(moves, true);

    QVariant decisionData = QVariant::fromValue(QString("pindian:%1:%2:%3:%4:%5")
        .arg(reason)
        .arg(this->objectName())
        .arg(pindian_struct->from_card->getEffectiveId())
        .arg(target->objectName())
        .arg(pindian_struct->to_card->getEffectiveId()));
    thread->trigger(ChoiceMade, room, this, decisionData);

    return pindian_struct->success;
}

int ServerPlayer::pindianInt(ServerPlayer *target, const QString &reason, const Card *card1)
{
    Q_ASSERT(this->canPindian(target, false));

    LogMessage log;
    log.type = "#Pindian";
    log.from = this;
    log.to << target;
    room->sendLog(log);

    PindianStruct *pindian_struct = new PindianStruct;
    pindian_struct->from = this;
    pindian_struct->to = target;
    pindian_struct->from_card = card1;
    pindian_struct->to_card = NULL;
    pindian_struct->reason = reason;

    RoomThread *thread = room->getThread();
    QVariant data = QVariant::fromValue(pindian_struct);
    thread->trigger(AskforPindianCard, room, this, data);

    PindianStruct *new_star = data.value<PindianStruct *>();
    card1 = new_star->from_card;
    const Card *card2 = new_star->to_card;

    if (card1 == NULL && card2 == NULL) {
        QList<const Card *> cards = room->askForPindianRace(this, target, reason);
        card1 = cards.first();
        card2 = cards.last();
    } else if (card2 == NULL) {
        if (card1->isVirtualCard()) {
            int card_id = card1->getEffectiveId();
            card1 = Sanguosha->getCard(card_id);
        }
        card2 = room->askForPindian(target, this, target, reason);
    } else if (card1 == NULL) {
        if (card2->isVirtualCard()) {
            int card_id = card2->getEffectiveId();
            card2 = Sanguosha->getCard(card_id);
        }
        card1 = room->askForPindian(this, this, target, reason);
    }

    if (card1 == NULL || card2 == NULL) return -2;

    pindian_struct->from_card = card1;
    pindian_struct->to_card = card2;
    pindian_struct->from_number = card1->getNumber();
    pindian_struct->to_number = card2->getNumber();

    QList<CardsMoveStruct> moves;
    CardsMoveStruct move_table_1;
    move_table_1.card_ids << pindian_struct->from_card->getEffectiveId();
    move_table_1.from = room->getCardOwner(pindian_struct->from_card->getEffectiveId());
    move_table_1.to = NULL;
    move_table_1.to_place = Player::PlaceTable;
    move_table_1.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->from->objectName(),
        pindian_struct->to->objectName(), pindian_struct->reason, QString());

    CardsMoveStruct move_table_2;
    move_table_2.card_ids << pindian_struct->to_card->getEffectiveId();
    move_table_2.from = room->getCardOwner(pindian_struct->to_card->getEffectiveId());
    move_table_2.to = NULL;
    move_table_2.to_place = Player::PlaceTable;
    move_table_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());

    moves.append(move_table_1);
    moves.append(move_table_2);
    room->moveCardsAtomic(moves, true);

    log.type = "$PindianResult";
    log.from = pindian_struct->from;
    log.card_str = QString::number(pindian_struct->from_card->getEffectiveId());
    room->sendLog(log);

    log.type = "$PindianResult";
    log.from = pindian_struct->to;
    log.card_str = QString::number(pindian_struct->to_card->getEffectiveId());
    room->sendLog(log);

    thread->trigger(PindianVerifying, room, this, data);

    pindian_struct->success = pindian_struct->from_number > pindian_struct->to_number;

    log.type = pindian_struct->success ? "#PindianSuccess" : "#PindianFailure";
    log.from = this;
    log.to.clear();
    log.to << target;
    log.card_str.clear();
    room->sendLog(log);

    JsonArray arg;
    arg << S_GAME_EVENT_REVEAL_PINDIAN << objectName() << pindian_struct->from_card->getEffectiveId() << target->objectName()
        << pindian_struct->to_card->getEffectiveId() << pindian_struct->success << reason;
    room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

    thread->trigger(Pindian, room, this, data);

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
        if (pindian_struct->to_card->getEffectiveId() != pindian_struct->from_card->getEffectiveId()) {
            CardsMoveStruct move_discard_2;
            move_discard_2.card_ids << pindian_struct->to_card->getEffectiveId();
            move_discard_2.from = pindian_struct->to;
            move_discard_2.to = NULL;
            move_discard_2.to_place = Player::DiscardPile;
            move_discard_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());
            moves.append(move_discard_2);
        }
    }
    if (!moves.isEmpty())
        room->moveCardsAtomic(moves, true);

    QVariant decisionData = QVariant::fromValue(QString("pindian:%1:%2:%3:%4:%5")
        .arg(reason)
        .arg(this->objectName())
        .arg(pindian_struct->from_card->getEffectiveId())
        .arg(target->objectName())
        .arg(pindian_struct->to_card->getEffectiveId()));
    thread->trigger(ChoiceMade, room, this, decisionData);

    if (pindian_struct->success) return 1;
    else if (pindian_struct->from_number == pindian_struct->to_number) return 0;
    else if (pindian_struct->from_number < pindian_struct->to_number) return -1;
    return -2;
}

PindianStruct *ServerPlayer::PinDian(ServerPlayer *target, const QString &reason, const Card *card1)
{
    Q_ASSERT(this->canPindian(target, false));

    LogMessage log;
    log.type = "#Pindian";
    log.from = this;
    log.to << target;
    room->sendLog(log);

    PindianStruct *pindian_struct = new PindianStruct;
    pindian_struct->from = this;
    pindian_struct->to = target;
    pindian_struct->from_card = card1;
    pindian_struct->to_card = NULL;
    pindian_struct->reason = reason;

    RoomThread *thread = room->getThread();
    QVariant data = QVariant::fromValue(pindian_struct);
    thread->trigger(AskforPindianCard, room, this, data);

    PindianStruct *new_star = data.value<PindianStruct *>();
    card1 = new_star->from_card;
    const Card *card2 = new_star->to_card;

    if (card1 == NULL && card2 == NULL) {
        QList<const Card *> cards = room->askForPindianRace(this, target, reason);
        card1 = cards.first();
        card2 = cards.last();
    } else if (card2 == NULL) {
        if (card1->isVirtualCard()) {
            int card_id = card1->getEffectiveId();
            card1 = Sanguosha->getCard(card_id);
        }
        card2 = room->askForPindian(target, this, target, reason);
    } else if (card1 == NULL) {
        if (card2->isVirtualCard()) {
            int card_id = card2->getEffectiveId();
            card2 = Sanguosha->getCard(card_id);
        }
        card1 = room->askForPindian(this, this, target, reason);
    }

    if (card1 == NULL || card2 == NULL) return NULL;

    pindian_struct->from_card = card1;
    pindian_struct->to_card = card2;
    pindian_struct->from_number = card1->getNumber();
    pindian_struct->to_number = card2->getNumber();

    QList<CardsMoveStruct> moves;
    CardsMoveStruct move_table_1;
    move_table_1.card_ids << pindian_struct->from_card->getEffectiveId();
    move_table_1.from = room->getCardOwner(pindian_struct->from_card->getEffectiveId());
    move_table_1.to = NULL;
    move_table_1.to_place = Player::PlaceTable;
    move_table_1.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->from->objectName(),
        pindian_struct->to->objectName(), pindian_struct->reason, QString());

    CardsMoveStruct move_table_2;
    move_table_2.card_ids << pindian_struct->to_card->getEffectiveId();
    move_table_2.from = room->getCardOwner(pindian_struct->to_card->getEffectiveId());
    move_table_2.to = NULL;
    move_table_2.to_place = Player::PlaceTable;
    move_table_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());

    moves.append(move_table_1);
    moves.append(move_table_2);
    room->moveCardsAtomic(moves, true);

    log.type = "$PindianResult";
    log.from = pindian_struct->from;
    log.card_str = QString::number(pindian_struct->from_card->getEffectiveId());
    room->sendLog(log);

    log.type = "$PindianResult";
    log.from = pindian_struct->to;
    log.card_str = QString::number(pindian_struct->to_card->getEffectiveId());
    room->sendLog(log);

    thread->trigger(PindianVerifying, room, this, data);

    pindian_struct->success = pindian_struct->from_number > pindian_struct->to_number;

    log.type = pindian_struct->success ? "#PindianSuccess" : "#PindianFailure";
    log.from = this;
    log.to.clear();
    log.to << target;
    log.card_str.clear();
    room->sendLog(log);

    JsonArray arg;
    arg << S_GAME_EVENT_REVEAL_PINDIAN << objectName() << pindian_struct->from_card->getEffectiveId() << target->objectName() << pindian_struct->to_card->getEffectiveId() << pindian_struct->success << reason;
    room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

    data = QVariant::fromValue(pindian_struct);
    thread->trigger(Pindian, room, this, data);

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
        if (pindian_struct->to_card->getEffectiveId() != pindian_struct->from_card->getEffectiveId()) {
            CardsMoveStruct move_discard_2;
            move_discard_2.card_ids << pindian_struct->to_card->getEffectiveId();
            move_discard_2.from = pindian_struct->to;
            move_discard_2.to = NULL;
            move_discard_2.to_place = Player::DiscardPile;
            move_discard_2.reason = CardMoveReason(CardMoveReason::S_REASON_PINDIAN, pindian_struct->to->objectName());
            moves.append(move_discard_2);
        }
    }
    if (!moves.isEmpty())
        room->moveCardsAtomic(moves, true);

    QVariant decisionData = QVariant::fromValue(QString("pindian:%1:%2:%3:%4:%5")
        .arg(reason)
        .arg(this->objectName())
        .arg(pindian_struct->from_card->getEffectiveId())
        .arg(target->objectName())
        .arg(pindian_struct->to_card->getEffectiveId()));
    thread->trigger(ChoiceMade, room, this, decisionData);

    return pindian_struct;
}

void ServerPlayer::turnOver()
{
    if (room->getThread()->trigger(TurnOver, room, this)) return;
    setFaceUp(!faceUp());
    room->broadcastProperty(this, "faceup");

    LogMessage log;
    log.type = "#TurnOver";
    log.from = this;
    log.arg = faceUp() ? "face_up" : "face_down";
    room->sendLog(log);

    room->getThread()->trigger(TurnedOver, room, this);
}

bool ServerPlayer::changePhase(Player::Phase from, Player::Phase to)
{
    RoomThread *thread = room->getThread();
    setPhase(PhaseNone);

    PhaseChangeStruct phase_change;
    phase_change.from = from;
    phase_change.to = to;
    QVariant data = QVariant::fromValue(phase_change);

    bool skip = thread->trigger(EventPhaseChanging, room, this, data);
    if (skip && to != NotActive) {
        setPhase(from);
        return true;
    }

    setPhase(to);
    room->broadcastProperty(this, "phase");

    if (!phases.isEmpty())
        phases.removeFirst();

    if (!thread->trigger(EventPhaseStart, room, this)) {
        if (getPhase() != NotActive)
            thread->trigger(EventPhaseProceeding, room, this);
    }
    if (getPhase() != NotActive)
        thread->trigger(EventPhaseEnd, room, this);

    return false;
}

void ServerPlayer::play(QList<Player::Phase> set_phases)
{
    if (!set_phases.isEmpty()) {
        if (!set_phases.contains(NotActive))
            set_phases << NotActive;
    } else
        set_phases << RoundStart << Start << Judge << Draw << Play
        << Discard << Finish << NotActive;

    QList<Player::Phase> all_phases;
    all_phases << RoundStart << Start << Judge << Draw << Play << Discard << Finish;
    QStringList phase_names;
    phase_names << "roundstart" << "start" << "judge" << "draw" << "play" << "discard" << "finish";
    foreach (Player::Phase pha, set_phases) {
        int n = all_phases.indexOf(pha);
        if (n < 0) continue;
        QString phase_name = phase_names.at(n);
        if (!phase_name.isEmpty() && getMark("LostPlayerPhase_" + phase_name) > 0)
            set_phases.removeOne(pha);
    }

    phases = set_phases;
    _m_phases_state.clear();
    for (int i = 0; i < phases.size(); i++) {
        PhaseStruct _phase;
        _phase.phase = phases[i];
        _m_phases_state << _phase;
    }

    for (int i = 0; i < _m_phases_state.size(); i++) {
        if (isDead()) {
            changePhase(getPhase(), NotActive);
            break;
        }

        _m_phases_index = i;
        PhaseChangeStruct phase_change;
        phase_change.from = getPhase();
        phase_change.to = phases[i];

        RoomThread *thread = room->getThread();
        setPhase(PhaseNone);
        QVariant data = QVariant::fromValue(phase_change);

        bool skip = thread->trigger(EventPhaseChanging, room, this, data);
        phase_change = data.value<PhaseChangeStruct>();
        _m_phases_state[i].phase = phases[i] = phase_change.to;

        setPhase(phases[i]);
        room->broadcastProperty(this, "phase");

        if (phases[i] != NotActive && (skip || _m_phases_state[i].skipped != 0)) {
            QVariant isCost = QVariant::fromValue(_m_phases_state[i].skipped < 0);
            bool cancel_skip = thread->trigger(EventPhaseSkipping, room, this, isCost);
            if (!cancel_skip) {
                thread->trigger(EventPhaseSkipped, room, this);
                continue;
            }
        }

        if (!thread->trigger(EventPhaseStart, room, this)) {
            if (getPhase() != NotActive)
                thread->trigger(EventPhaseProceeding, room, this);
        }
        if (getPhase() != NotActive)
            thread->trigger(EventPhaseEnd, room, this);
        else
            break;
    }
}

QList<Player::Phase> &ServerPlayer::getPhases()
{
    return phases;
}

void ServerPlayer::skip(Player::Phase phase, bool isCost)
{
    for (int i = _m_phases_index; i < _m_phases_state.size(); i++) {
        if (_m_phases_state[i].phase == phase) {
            if (_m_phases_state[i].skipped != 0) {
                if (isCost && _m_phases_state[i].skipped == 1)
                    _m_phases_state[i].skipped = -1;
                return;
            }
            _m_phases_state[i].skipped = (isCost ? -1 : 1);
            break;
        }
    }

    static QStringList phase_strings;
    if (phase_strings.isEmpty())
        phase_strings << "round_start" << "start" << "judge" << "draw"
        << "play" << "discard" << "finish" << "not_active";
    int index = static_cast<int>(phase);

    LogMessage log;
    log.type = "#SkipPhase";
    log.from = this;
    log.arg = phase_strings.at(index);
    room->sendLog(log);
}

void ServerPlayer::insertPhase(Player::Phase phase)
{
    PhaseStruct _phase;
    _phase.phase = phase;
    phases.insert(_m_phases_index, phase);
    _m_phases_state.insert(_m_phases_index, _phase);
}

bool ServerPlayer::isSkipped(Player::Phase phase)
{
    for (int i = _m_phases_index; i < _m_phases_state.size(); i++) {
        if (_m_phases_state[i].phase == phase)
            return (_m_phases_state[i].skipped != 0);
    }
    return false;
}

void ServerPlayer::gainMark(const QString &mark, int n)
{
    if (n == 0) return;
    int value = getMark(mark) + n;

    QString new_mark = mark;
    if (mark.startsWith("&"))
        new_mark = new_mark.mid(1);

    LogMessage log;
    log.type = "#GetMark";
    log.from = this;
    log.arg = new_mark;
    log.arg2 = QString::number(n);

    room->sendLog(log);
    room->setPlayerMark(this, mark, value);
}

void ServerPlayer::loseMark(const QString &mark, int n)
{
    if (getMark(mark) == 0 || n == 0) return;
    int value = getMark(mark) - n;
    if (value < 0) {
        value = 0;
        n = getMark(mark);
    }

    QString new_mark = mark;
    if (mark.startsWith("&"))
        new_mark = new_mark.mid(1);

    LogMessage log;
    log.type = "#LoseMark";
    log.from = this;
    log.arg = new_mark;
    log.arg2 = QString::number(n);

    room->sendLog(log);
    room->setPlayerMark(this, mark, value);
}

void ServerPlayer::loseAllMarks(const QString &mark_name)
{
    loseMark(mark_name, getMark(mark_name));
}

void ServerPlayer::gainHujia(int n, int max_num)
{
    if (n <= 0) return;

    int num = n, hujia = getHujia();
    if (max_num > 0) {
        if (hujia >= max_num) return;
        if (hujia + n > max_num)
            num = max_num - hujia;
    }

    RoomThread *thread = room->getThread();
    QVariant data = num;
    if (thread->trigger(GainHujia, room, this, data)) return;

    num = data.toInt();
    if (num <= 0) return;

    int value = getHujia() + num;

    LogMessage log;
    log.type = "#GetHujia";
    log.from = this;
    log.arg = QString::number(num);

    room->sendLog(log);
    room->setPlayerMark(this, "@HuJia", value);

    thread->trigger(GainedHujia, room, this, data);
}

void ServerPlayer::loseHujia(int n)
{
    if (getHujia() == 0 || n <= 0) return;

    int num = n;
    RoomThread *thread = room->getThread();
    QVariant data = num;
    if (thread->trigger(LoseHujia, room, this, data)) return;

    num = data.toInt();
    if (num <= 0) return;

    int value = getHujia() - num;
    if (value < 0) {
        value = 0;
        num = getHujia();
    }

    LogMessage log;
    log.type = "#LoseHuJia";
    log.from = this;
    log.arg = QString::number(num);

    room->sendLog(log);
    room->setPlayerMark(this, "@HuJia", value);

    thread->trigger(LostHujia, room, this, data);
}

void ServerPlayer::loseAllHujias()
{
    loseHujia(getHujia());
}

void ServerPlayer::addSkill(const QString &skill_name)
{
    const Skill *skill = Sanguosha->getMainSkill(skill_name);
    if (!skill)
        skill = Sanguosha->getSkill(skill_name);
    if (room->getMode() == "03_1v2" && skill && skill->isLordSkill()) return;

    Player::addSkill(skill_name);
    JsonArray args;
    args << (int)QSanProtocol::S_GAME_EVENT_ADD_SKILL;
    args << objectName();
    args << skill_name;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
}

void ServerPlayer::loseSkill(const QString &skill_name)
{
    Player::loseSkill(skill_name);
    JsonArray args;
    args << (int)QSanProtocol::S_GAME_EVENT_LOSE_SKILL;
    args << objectName();
    args << skill_name;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
}

void ServerPlayer::setGender(General::Gender gender)
{
    if (gender == getGender())
        return;
    Player::setGender(gender);
    JsonArray args;
    args << (int)QSanProtocol::S_GAME_EVENT_CHANGE_GENDER;
    args << objectName();
    args << (int)gender;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
}

bool ServerPlayer::isOnline() const
{
    return getState() == "online";
}

void ServerPlayer::setAI(AI *ai)
{
    this->ai = ai;
}

AI *ServerPlayer::getAI() const
{
    if (getState() == "online")
        return NULL;
    else if (getState() == "trust" && !Config.EnableCheat)
        return trust_ai;
    else
        return ai;
}

AI *ServerPlayer::getSmartAI() const
{
    return ai;
}

void ServerPlayer::addVictim(ServerPlayer *victim)
{
    victims.append(victim);
}

QList<ServerPlayer *> ServerPlayer::getVictims() const
{
    return victims;
}

void ServerPlayer::setNext(ServerPlayer *next)
{
    this->next = next;
}

ServerPlayer *ServerPlayer::getNext() const
{
    return next;
}

ServerPlayer *ServerPlayer::getNextAlive(int n) const
{
    bool hasAlive = (room->getAlivePlayers().length() > 0);
    ServerPlayer *next = const_cast<ServerPlayer *>(this);
    if (!hasAlive) return next;
    for (int i = 0; i < n; i++) {
        do next = next->next; while (next->isDead());
    }
    return next;
}

int ServerPlayer::getGeneralMaxHp() const
{
    int max_hp = 0;

    if (getGeneral2() == NULL)
        max_hp = getGeneral()->getMaxHp();
    else {
        int first = getGeneral()->getMaxHp();
        int second = getGeneral2()->getMaxHp();

        int plan = Config.MaxHpScheme;
        if (Config.GameMode.contains("_mini_") || Config.GameMode == "custom_scenario") plan = 1;

        switch (plan) {
        case 3: max_hp = (first + second) / 2; break;
        case 2: max_hp = qMax(first, second); break;
        case 1: max_hp = qMin(first, second); break;
        default:
            max_hp = first + second - Config.Scheme0Subtraction; break;
        }

        max_hp = qMax(max_hp, 1);
    }

    if (room->hasWelfare(this))
        max_hp++;

    return max_hp;
}

int ServerPlayer::getGeneralStartHp() const
{
    int start_hp = 0;

    if (getGeneral2() == NULL)
        start_hp = getGeneral()->getStartHp();
    else {
        int first = getGeneral()->getStartHp();
        int second = getGeneral2()->getStartHp();

        int plan = Config.MaxHpScheme;
        if (Config.GameMode.contains("_mini_") || Config.GameMode == "custom_scenario") plan = 1;

        switch (plan) {
        case 3: start_hp = (first + second) / 2; break;
        case 2: start_hp = qMax(first, second); break;
        case 1: start_hp = qMin(first, second); break;
        default:
            start_hp = first + second - Config.Scheme0Subtraction; break;
        }

        start_hp = qMax(start_hp, 1);
    }

    if (room->hasWelfare(this))
        start_hp++;

    return start_hp;
}

int ServerPlayer::getGeneralStartHujia() const
{
    int start_hujia = 0;
    if (getGeneral2() == NULL)
        start_hujia = getGeneral()->getStartHujia();
    else {
        int first = getGeneral()->getStartHujia();
        int second = getGeneral2()->getStartHujia();
        start_hujia = first + second;
    }
    return start_hujia;
}

QString ServerPlayer::getGameMode() const
{
    return room->getMode();
}

QString ServerPlayer::getIp() const
{
    if (socket)
        return socket->peerAddress();
    else
        return QString();
}

void ServerPlayer::introduceTo(ServerPlayer *player)
{
    QString screen_name = screenName().toUtf8().toBase64();
    QString avatar = property("avatar").toString();

    JsonArray introduce_str;
    introduce_str << objectName() << screen_name << avatar;

    if (player)
        room->doNotify(player, S_COMMAND_ADD_PLAYER, introduce_str);
    else {
        QList<ServerPlayer *> players = room->getPlayers();
        players.removeOne(this);
        room->doBroadcastNotify(players, S_COMMAND_ADD_PLAYER, introduce_str);
    }
}

void ServerPlayer::marshal(ServerPlayer *player) const
{
    room->notifyProperty(player, this, "maxhp");
    room->notifyProperty(player, this, "hp");
    room->notifyProperty(player, this, "gender");
    room->notifyProperty(player, this, "player_seat");

    if (getKingdom() != getGeneral()->getKingdom())
        room->notifyProperty(player, this, "kingdom");

    if (isAlive()) {
        room->notifyProperty(player, this, "seat");
        if (getPhase() != Player::NotActive)
            room->notifyProperty(player, this, "phase");
    } else {
        room->notifyProperty(player, this, "alive");
        room->notifyProperty(player, this, "role");
        room->doNotify(player, S_COMMAND_KILL_PLAYER, objectName());
    }

    if (!faceUp())
        room->notifyProperty(player, this, "faceup");

    if (isChained())
        room->notifyProperty(player, this, "chained");

    QList<ServerPlayer*> players;
    players << player;

    QList<CardsMoveStruct> moves;

    if (!isKongcheng()) {
        CardsMoveStruct move;
        foreach (const Card *card, handcards) {
            move.card_ids << card->getId();
            if (player == this) {
                WrappedCard *wrapped = qobject_cast<WrappedCard *>(room->getCard(card->getId()));
                if (wrapped->isModified())
                    room->notifyUpdateCard(player, card->getId(), wrapped);
            }
        }
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceHand;

        if (player == this)
            move.to = player;

        moves << move;
    }

    if (hasEquip()) {
        CardsMoveStruct move;
        foreach (const Card *card, getEquips()) {
            move.card_ids << card->getId();
            WrappedCard *wrapped = qobject_cast<WrappedCard *>(room->getCard(card->getId()));
            if (wrapped->isModified())
                room->notifyUpdateCard(player, card->getId(), wrapped);
        }
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceEquip;

        moves << move;
    }

    if (!getJudgingAreaID().isEmpty()) {
        CardsMoveStruct move;
        foreach(int card_id, getJudgingAreaID())
            move.card_ids << card_id;
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceDelayedTrick;

        moves << move;
    }

    if (!moves.isEmpty()) {
        room->notifyMoveCards(true, moves, false, players);
        room->notifyMoveCards(false, moves, false, players);
    }

    if (!getPileNames().isEmpty()) {
        CardsMoveStruct move;
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceSpecial;
        foreach (QString pile, piles.keys()) {
            move.card_ids.clear();
            move.card_ids.append(piles[pile]);
            move.to_pile_name = pile;

            QList<CardsMoveStruct> moves2;
            moves2 << move;

            bool open = pileOpen(pile, player->objectName());

            room->notifyMoveCards(true, moves2, open, players);
            room->notifyMoveCards(false, moves2, open, players);
        }
    }

    foreach (QString mark_name, marks.keys()) {
        if (mark_name.startsWith("@") || mark_name.startsWith("&")) {
            int value = getMark(mark_name);
            if (value > 0) {
                JsonArray arg;
                arg << objectName() << mark_name << value;
                room->doNotify(player, S_COMMAND_SET_MARK, arg);
            }
        }
    }

    foreach (const Skill *skill, getVisibleSkillList(true)) {
        QString skill_name = skill->objectName();
        JsonArray args1;
        args1 << S_GAME_EVENT_ACQUIRE_SKILL << objectName() << skill_name;
        room->doNotify(player, S_COMMAND_LOG_EVENT, args1);
    }

    foreach(QString flag, flags)
        room->notifyProperty(player, this, "flags", flag);

    foreach (QString item, history.keys()) {
        int value = history.value(item);
        if (value > 0) {
            JsonArray arg;
            arg << item << value;
            room->doNotify(player, S_COMMAND_ADD_HISTORY, arg);
        }
    }

    if (hasShownRole())
        room->notifyProperty(player, this, "role");
}

void ServerPlayer::addToPile(const QString &pile_name, const Card *card, bool open, QList<ServerPlayer *> open_players)
{
    QList<int> card_ids;
    if (card->isVirtualCard())
        card_ids = card->getSubcards();
    else
        card_ids << card->getEffectiveId();
    return addToPile(pile_name, card_ids, open, open_players);
}

void ServerPlayer::addToPile(const QString &pile_name, int card_id, bool open, QList<ServerPlayer *> open_players)
{
    QList<int> card_ids;
    card_ids << card_id;
    return addToPile(pile_name, card_ids, open, open_players);
}

void ServerPlayer::addToPile(const QString &pile_name, QList<int> card_ids, bool open, QList<ServerPlayer *> open_players)
{
    return addToPile(pile_name, card_ids, open, open_players, CardMoveReason());
}

void ServerPlayer::addToPile(const QString &pile_name, QList<int> card_ids,
    bool open, QList<ServerPlayer *> open_players, CardMoveReason reason)
{
    if (!open) {
        if (open_players.isEmpty()) {
            foreach (int id, card_ids) {
                ServerPlayer *owner = room->getCardOwner(id);
                if (owner && !open_players.contains(owner))
                    open_players << owner;
            }
        }
    } else {
        open_players = room->getAllPlayers();
    }
    foreach(ServerPlayer *p, open_players)
        setPileOpen(pile_name, p->objectName());
    piles[pile_name].append(card_ids);

    CardsMoveStruct move;
    move.card_ids = card_ids;
    move.to = this;
    move.to_place = Player::PlaceSpecial;
    move.reason = reason;
    room->moveCardsAtomic(move, open);
}

void ServerPlayer::exchangeFreelyFromPrivatePile(const QString &skill_name, const QString &pile_name, int upperlimit, bool include_equip)
{
    QList<int> pile = getPile(pile_name);
    if (pile.isEmpty()) return;

    QString tempMovingFlag = QString("%1_InTempMoving").arg(skill_name);
    room->setPlayerFlag(this, tempMovingFlag);

    int ai_delay = Config.AIDelay;
    Config.AIDelay = 0;

    QList<int> will_to_pile, will_to_handcard;
    while (!pile.isEmpty()) {
        room->fillAG(pile, this);
        int card_id = room->askForAG(this, pile, true, skill_name);
        room->clearAG(this);
        if (card_id == -1) break;

        pile.removeOne(card_id);
        will_to_handcard << card_id;
        if (pile.length() >= upperlimit) break;

        CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, this->objectName());
        room->obtainCard(this, Sanguosha->getCard(card_id), reason, false);
    }

    Config.AIDelay = ai_delay;

    int n = will_to_handcard.length();
    if (n == 0) return;
    const Card *exchange_card = room->askForExchange(this, skill_name, n, n, include_equip);
    will_to_pile = exchange_card->getSubcards();
    delete exchange_card;

    QList<int> will_to_handcard_x = will_to_handcard, will_to_pile_x = will_to_pile;
    QList<int> duplicate;
    foreach (int id, will_to_pile) {
        if (will_to_handcard_x.contains(id)) {
            duplicate << id;
            will_to_pile_x.removeOne(id);
            will_to_handcard_x.removeOne(id);
            n--;
        }
    }

    if (n == 0) {
        addToPile(pile_name, will_to_pile, false);
        room->setPlayerFlag(this, "-" + tempMovingFlag);
        return;
    }

    LogMessage log;
    log.type = "#QixingExchange";
    log.from = this;
    log.arg = QString::number(n);
    log.arg2 = skill_name;
    room->sendLog(log);

    addToPile(pile_name, duplicate, false);
    room->setPlayerFlag(this, "-" + tempMovingFlag);
    addToPile(pile_name, will_to_pile_x, false);

    room->setPlayerFlag(this, tempMovingFlag);
    addToPile(pile_name, will_to_handcard_x, false);
    room->setPlayerFlag(this, "-" + tempMovingFlag);

    DummyCard *dummy = new DummyCard(will_to_handcard_x);
    CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, this->objectName());
    room->obtainCard(this, dummy, reason, false);
    delete dummy;
}

void ServerPlayer::gainAnExtraTurn()
{
    ServerPlayer *current = room->getCurrent();
    try {
        room->setCurrent(this);
        room->setTag("Global_ExtraTurn" + this->objectName(), true);
        room->getThread()->trigger(TurnStart, room, this);
        room->removeTag("Global_ExtraTurn" + this->objectName());
        room->setCurrent(current);
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken) {
            if (getPhase() != Player::NotActive) {
                const GameRule *game_rule = NULL;
                if (room->getMode() == "04_1v3")
                    game_rule = qobject_cast<const GameRule *>(Sanguosha->getTriggerSkill("hulaopass_mode"));
                else
                    game_rule = qobject_cast<const GameRule *>(Sanguosha->getTriggerSkill("game_rule"));
                if (game_rule) {
                    QVariant v;
                    game_rule->trigger(EventPhaseEnd, room, this, v);
                }
                changePhase(getPhase(), Player::NotActive);
            }
            room->setCurrent(current);
        }
        throw triggerEvent;
    }
}

void ServerPlayer::copyFrom(ServerPlayer *sp)
{
    ServerPlayer *b = this;
    ServerPlayer *a = sp;

    b->handcards = QList<const Card *>(a->handcards);
    b->phases = QList<ServerPlayer::Phase>(a->phases);
    b->selected = QStringList(a->selected);

    Player *c = b;
    c->copyFrom(a);
}

bool ServerPlayer::CompareByActionOrder(ServerPlayer *a, ServerPlayer *b)
{
    Room *room = a->getRoom();
    return room->getFront(a, b) == a;
}

void ServerPlayer::throwEquipArea(int i)
{
    Q_ASSERT(i > -1 && i < 5);
    QVariantList list;
    if (hasEquipArea(i)) {
        setEquipArea(i, false);
        if (i == 0) room->broadcastProperty(this, "hasweaponarea");
        else if (i == 1) room->broadcastProperty(this, "hasarmorarea");
        else if (i == 2) room->broadcastProperty(this, "hasdefensivehorsearea");
        else if (i == 3) room->broadcastProperty(this, "hasoffensivehorsearea");
        else if (i == 4) room->broadcastProperty(this, "hastreasurearea");

        QStringList areas;
        areas << "weapon_area" << "armor_area" << "defensive_horse_area" << "offensive_horse_area" << "treasure_area";
        LogMessage log;
        log.type = "#ThrowArea";
        log.from = this;
        log.arg = areas.at(i);
        room->sendLog(log);

        DummyCard *card = new DummyCard;
        if (this->getEquip(i)) {
            card->addSubcard(this->getEquip(i));
            room->throwCard(card, this);
        }
        delete card;
        list << i;
        room->setPlayerMark(this, "@Equip" + QString::number(i) + "lose", 1);
    }
    if (!list.isEmpty()) {
        RoomThread *thread = room->getThread();
        QVariant data = list;
        thread->trigger(ThrowEquipArea, room, this, data);
    }
}

void ServerPlayer::throwEquipArea(QList<int> list)
{
    foreach (int i, list) {
        Q_ASSERT(i > -1 && i < 5);
    }

    QVariantList newlist;
    DummyCard *card = new DummyCard;
    foreach (int i, list) {
        if (hasEquipArea(i)) {
            setEquipArea(i, false);
            if (i == 0) room->broadcastProperty(this, "hasweaponarea");
            else if (i == 1) room->broadcastProperty(this, "hasarmorarea");
            else if (i == 2) room->broadcastProperty(this, "hasdefensivehorsearea");
            else if (i == 3) room->broadcastProperty(this, "hasoffensivehorsearea");
            else if (i == 4) room->broadcastProperty(this, "hastreasurearea");

            QStringList areas;
            areas << "weapon_area" << "armor_area" << "defensive_horse_area" << "offensive_horse_area" << "treasure_area";
            LogMessage log;
            log.type = "#ThrowArea";
            log.from = this;
            log.arg = areas.at(i);
            room->sendLog(log);

            if (this->getEquip(i))
                card->addSubcard(this->getEquip(i));
            newlist << i;
        }
    }
    if (card->subcardsLength() > 0) room->throwCard(card, this);
    delete card;
    if (newlist.isEmpty()) return;
    QList<int> _newlist = VariantList2IntList(newlist);
    foreach (int i, _newlist)
        room->setPlayerMark(this, "@Equip" + QString::number(i) + "lose", 1);
    RoomThread *thread = room->getThread();
    QVariant data = newlist;
    thread->trigger(ThrowEquipArea, room, this, data);
}

void ServerPlayer::throwEquipArea()
{
    QVariantList list;
    for (int i = 0; i < 5; i++) {
        if (hasEquipArea(i)) {
            setEquipArea(i, false);
            list << i;
        }
    }
    room->broadcastProperty(this, "hasweaponarea");
    room->broadcastProperty(this, "hasarmorarea");
    room->broadcastProperty(this, "hasdefensivehorsearea");
    room->broadcastProperty(this, "hasoffensivehorsearea");
    room->broadcastProperty(this, "hastreasurearea");
    if (!list.isEmpty()) {
        LogMessage log;
        log.type = "#ThrowArea";
        log.from = this;
        log.arg = "equip_area";
        room->sendLog(log);
    }
    //this->throwAllEquips();
    QList<const Card *> equips = getEquips();
    DummyCard *card = new DummyCard;
    foreach (const Card *equip, equips) {
        card->addSubcard(equip);
    }
    if (card->subcardsLength() > 0)
        room->throwCard(card, this);
    delete card;
    room->setPlayerMark(this, "@Equip5lose", 1);
    if (!list.isEmpty()) {
        RoomThread *thread = room->getThread();
        QVariant data = list;
        thread->trigger(ThrowEquipArea, room, this, data);
    }
}

void ServerPlayer::obtainEquipArea(int i)
{
    Q_ASSERT(i > -1 && i < 5);
    QVariantList list;
    if (!hasEquipArea(i)) {
        setEquipArea(i, true);
        if (i == 0) room->broadcastProperty(this, "hasweaponarea");
        else if (i == 1) room->broadcastProperty(this, "hasarmorarea");
        else if (i == 2) room->broadcastProperty(this, "hasdefensivehorsearea");
        else if (i == 3) room->broadcastProperty(this, "hasoffensivehorsearea");
        else if (i == 4) room->broadcastProperty(this, "hastreasurearea");

        QStringList areas;
        areas << "weapon_area" << "armor_area" << "defensive_horse_area" << "offensive_horse_area" << "treasure_area";
        LogMessage log;
        log.type = "#ObtainArea";
        log.from = this;
        log.arg = areas.at(i);
        room->sendLog(log);

        room->setPlayerMark(this, "@Equip5lose", 0);
        room->setPlayerMark(this, "@Equip"+ QString::number(i) + "lose", 0);
        for (int m = 0; m < 5; m++) {
            if (!hasEquipArea(m))
                room->setPlayerMark(this, "@Equip"+ QString::number(m) + "lose", 1);
        }
        list << i;
    }
    if (!list.isEmpty()) {
        RoomThread *thread = room->getThread();
        QVariant data = list;
        thread->trigger(ObtainEquipArea, room, this, data);
    }
}

void ServerPlayer::obtainEquipArea(QList<int> list)
{
    foreach (int i, list) {
        Q_ASSERT(i > -1 && i < 5);
    }

    QVariantList newlist;
    foreach (int i, list) {
        if (!hasEquipArea(i)) {
            setEquipArea(i, true);
            if (i == 0) room->broadcastProperty(this, "hasweaponarea");
            else if (i == 1) room->broadcastProperty(this, "hasarmorarea");
            else if (i == 2) room->broadcastProperty(this, "hasdefensivehorsearea");
            else if (i == 3) room->broadcastProperty(this, "hasoffensivehorsearea");
            else if (i == 4) room->broadcastProperty(this, "hastreasurearea");
            newlist << i;

            QStringList areas;
            areas << "weapon_area" << "armor_area" << "defensive_horse_area" << "offensive_horse_area" << "treasure_area";
            LogMessage log;
            log.type = "#ObtainArea";
            log.from = this;
            log.arg = areas.at(i);
            room->sendLog(log);
        }
    }
    if (newlist.isEmpty()) return;
    room->setPlayerMark(this, "@Equip5lose", 0);
    QList<int> _newlist = VariantList2IntList(newlist);
    foreach (int i, _newlist)
        room->setPlayerMark(this, "@Equip" + QString::number(i) + "lose", 0);
    for (int m = 0; m < 5; m++) {
        if (!hasEquipArea(m)) {
            room->setPlayerMark(this, "@Equip" + QString::number(m) + "lose", 1);
        }
    }
    RoomThread *thread = room->getThread();
    QVariant data = newlist;
    thread->trigger(ObtainEquipArea, room, this, data);
}

void ServerPlayer::obtainEquipArea()
{
    QVariantList list;
    for (int i = 0; i < 5; i++) {
        if (!hasEquipArea(i)) {
            setEquipArea(i, true);
            list << i;
        }
    }
    room->broadcastProperty(this, "hasweaponarea");
    room->broadcastProperty(this, "hasarmorarea");
    room->broadcastProperty(this, "hasdefensivehorsearea");
    room->broadcastProperty(this, "hasoffensivehorsearea");
    room->broadcastProperty(this, "hastreasurearea");

    if (!list.isEmpty()) {
        LogMessage log;
        log.type = "#ObtainArea";
        log.from = this;
        log.arg = "equip_area";
        room->sendLog(log);
    }

    room->setPlayerMark(this, "@Equip5lose", 0);
    room->setPlayerMark(this, "@Equip0lose", 0);
    room->setPlayerMark(this, "@Equip1lose", 0);
    room->setPlayerMark(this, "@Equip2lose", 0);
    room->setPlayerMark(this, "@Equip3lose", 0);
    room->setPlayerMark(this, "@Equip4lose", 0);
    if (!list.isEmpty()) {
        RoomThread *thread = room->getThread();
        QVariant data = list;
        thread->trigger(ObtainEquipArea, room, this, data);
    }
}

void ServerPlayer::throwJudgeArea()
{
    bool flag = false;
    if (hasJudgeArea()) {
        setJudgeArea(false);
        room->broadcastProperty(this, "hasjudgearea");

        LogMessage log;
        log.type = "#ThrowArea";
        log.from = this;
        log.arg = "judge_area";
        room->sendLog(log);

        QList<const Card *> tricks = getJudgingArea();
        DummyCard *card = new DummyCard;
        foreach (const Card *trick, tricks) {
           card->addSubcard(trick);
        }
        if (card->subcardsLength() > 0) {
            CardMoveReason reason(CardMoveReason::S_REASON_THROW, this->objectName());
            room->throwCard(card, reason, NULL);
        }
        delete card;
        flag = true;
    }
    room->setPlayerMark(this, "@Judgelose", 1);
    if (flag) {
        RoomThread *thread = room->getThread();
        thread->trigger(ThrowJudgeArea, room, this);
    }
}

void ServerPlayer::obtainJudgeArea()
{
    bool flag = false;
    if (!hasJudgeArea()) {
        setJudgeArea(true);
        room->broadcastProperty(this, "hasjudgearea");
        LogMessage log;
        log.type = "#ObtainArea";
        log.from = this;
        log.arg = "judge_area";
        room->sendLog(log);
        flag = true;
    }
    room->setPlayerMark(this, "@Judgelose", 0);
    if (flag) {
        RoomThread *thread = room->getThread();
        thread->trigger(ObtainJudgeArea, room, this);
    }
}

ServerPlayer *ServerPlayer::getSaver() const
{
    QStringList list = this->property("My_Dying_Saver").toStringList();
    if (list.isEmpty()) return NULL;
    QString name = list.first();
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->objectName() == name)
            return p;
    }
    return NULL;
}

bool ServerPlayer::isLowestHpPlayer(bool only)
{
    int hp = getHp();
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->getHp() < hp || (only && p->getHp() <= hp))
            return false;
    }
    return true;
}

void ServerPlayer::ViewAsEquip(const QString &equip_name, bool can_duplication)
{
    if (equip_name == QString()) return;
    QStringList equips = property("View_As_Equips_List").toString().split("+");
    if (!can_duplication && equips.contains(equip_name)) return;
    equips << equip_name;
    room->setPlayerProperty(this, "View_As_Equips_List", equips.join("+"));
}

void ServerPlayer::removeViewAsEquip(const QString &equip_name, bool remove_all_duplication)
{
    QStringList equips = property("View_As_Equips_List").toString().split("+");
    if (equip_name == QString() || equip_name == ".") {
        room->setPlayerProperty(this, "View_As_Equips_List", QString());
        return;
    }
    if (!equips.contains(equip_name)) return;
    equips.removeOne(equip_name);
    if (remove_all_duplication) {
        foreach (QString str, equips) {
            if (str == equip_name)
                equips.removeOne(str);
        }
    }
    room->setPlayerProperty(this, "View_As_Equips_List", equips.join("+"));
}

bool ServerPlayer::canUse(const Card *card, QList<ServerPlayer *> players, bool player_must_be_target)
{
    QList<ServerPlayer *> new_players = players;
    if (new_players.isEmpty()) new_players = room->getAlivePlayers();

    if (player_must_be_target && new_players.length() == 1 && isProhibited(new_players.first(), card))
        return false;

    if (!card || new_players.isEmpty() || !card->isAvailable(this)) return false;
    if (card->isKindOf("Slash") && !Slash::IsAvailable(this)) return false;
    if (card->isKindOf("Analeptic") && !Analeptic::IsAvailable(this)) return false;

    if (card->targetFixed()) {
        if (!isLocked(card)) {
            if (card->isKindOf("AOE") || card->isKindOf("GlobalEffect") || !isProhibited(this, card))
                return true;
        }
    } else {
        foreach (ServerPlayer *p, new_players) {
            if (!isLocked(card) && !isProhibited(p, card) && card->targetFilter(QList<const Player *>(), p, this))
                return true;
        }
    }
    return false;
}

bool ServerPlayer::canUse(const Card *card, ServerPlayer *player, bool player_must_be_target)
{
    if (!player)
        return canUse(card);
    else
        return canUse(card, QList<ServerPlayer *>() << player, player_must_be_target);
}

void ServerPlayer::endPlayPhase(bool sendLog)
{
    if (getPhase() != Player::Play || isDead()) return;
    if (hasFlag("Global_PlayPhaseTerminated")) return;
    if (sendLog) {
        LogMessage log;
        log.type = "#EndPlayPhase";
        log.from = this;
        log.arg = "play";
        room->sendLog(log);
    }
    room->setPlayerFlag(this, "Global_PlayPhaseTerminated");
}

void ServerPlayer::breakYinniState()
{
    if (property("yinni_general").toString().isEmpty() && property("yinni_general2").toString().isEmpty()) return;
    QString generalname = property("yinni_general").toString();
    QString general2name = property("yinni_general2").toString();
    room->setPlayerProperty(this, "yinni_general", QString());
    room->setPlayerProperty(this, "yinni_general2", QString());

    if (getGeneralName() != "yinni_hide" && getGeneral2Name() != "yinni_hide") return;

    QStringList name;
    if (getGeneral()) {
        if (getGeneralName() == "yinni_hide")
            generalname = generalname.isEmpty() ? getGeneralName() : generalname;
        else
            generalname = getGeneralName();
        //name << Sanguosha->translate(generalname);
        name << generalname;
    }
    if (getGeneral2()) {
        if (getGeneral2Name() == "yinni_hide")
            general2name = general2name.isEmpty() ? getGeneral2Name() : general2name;
        else
            general2name = getGeneral2Name();
        //name << Sanguosha->translate(general2name);
        name << general2name;
    }
    if (!name.isEmpty()) {  //这么处理可能会有一些bug，再说吧。。。
        LogMessage log;

        log.from = this;
        //log.arg = name.join("/");  双将时发送的log是???/???
        if (getGeneral2()) {
            log.type = "#BreakYinniState2";
            log.arg = name.first();
            log.arg2 = name.last();
        } else {
            log.type = "#BreakYinniState";
            log.arg = generalname;
        }
        room->sendLog(log);

        if (!generalname.isEmpty() && generalname != getGeneralName())
            room->changeHero(this, generalname, false, false, false, false);
        if (!general2name.isEmpty() && general2name != getGeneral2Name())
            room->changeHero(this, general2name, false, false, true, false);

        Player::setMaxHp(getGeneralMaxHp());
        Player::setHp(getGeneralStartHp());
        room->broadcastProperty(this, "maxhp");
        room->broadcastProperty(this, "hp");

        room->getThread()->trigger(Appear, room, this);
    }
}

void ServerPlayer::enterYinniState(int type)
{
    if (type > 0) {  //只变主将
        room->setPlayerProperty(this, "yinni_general", getGeneralName());
        QString kingdom = getKingdom();
        room->setPlayerProperty(this, "yinni_general_kingdom", kingdom);
        room->changeHero(this, "yinni_hide", false, false, false, false);
        //room->setPlayerProperty(this, "kingdom", kingdom); 写在changeHero里了
    } else if (type == 0) {  //主将、副将都变
        room->setPlayerProperty(this, "yinni_general", getGeneralName());
        QString kingdom = getKingdom();
        room->setPlayerProperty(this, "yinni_general_kingdom", kingdom);
        room->changeHero(this, "yinni_hide", true, false, false, false);
        if (getGeneral2()) {
            room->setPlayerProperty(this, "yinni_general2", getGeneral2Name());
            room->changeHero(this, "yinni_hide", true, false, true, false);
        }
    } else {  //只变副将
        if (!getGeneral2()) return;
        room->setPlayerProperty(this, "yinni_general2", getGeneral2Name());
        room->changeHero(this, "yinni_hide", false, false, true, false);
    }
}

int ServerPlayer::getDerivativeCard(const QString &card_name, Player::Place place, bool visible) const
{
   if (card_name.isEmpty()) return -1;

   foreach (int id, Sanguosha->getRandomCards(true)) {
       const Card *card = Sanguosha->getCard(id);
       if (card->objectName() != card_name || room->getCardPlace(id) != Player::PlaceTable) continue;
       if (place == Player::PlaceTable) return id;

       if (card->isKindOf("EquipCard")) {
           const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
           int equip_index = static_cast<int>(equip->location());
           if (!hasEquipArea(equip_index) && place == Player::PlaceEquip) return id;

           CardMoveReason reason;
           if (place == Player::PlaceEquip)
               reason.m_reason = CardMoveReason::S_REASON_PUT;
           else
               reason.m_reason = CardMoveReason::S_REASON_EXCLUSIVE;
           reason.m_playerId = objectName();

           CardsMoveStruct move(id, NULL, (Player *)this, Player::PlaceTable, place, reason);
           room->moveCardsAtomic(move, visible);
           return id;
       } else {
           if (place == Player::PlaceEquip) return id;

            CardMoveReason reason(CardMoveReason::S_REASON_EXCLUSIVE, objectName());
            CardsMoveStruct move(id, NULL, (Player *)this, Player::PlaceTable, place, reason);
            room->moveCardsAtomic(move, visible);
           return id;
       }
   }
   return -1;
}

void ServerPlayer::setCanWake(const QString &skill_name, const QString &waked_skill_name)
{
    QStringList names = tag[waked_skill_name + "_SKILLCANWAKE"].toStringList();
    if (names.contains(skill_name)) return;
    names << skill_name;
    tag[waked_skill_name + "_SKILLCANWAKE"] = names;
    room->setPlayerMark(this, "&" + skill_name + "+:+" + waked_skill_name, 1);
}

bool ServerPlayer::canWake(const QString &waked_skill_name)
{
    QStringList names = tag[waked_skill_name + "_SKILLCANWAKE"].toStringList();
    if (names.isEmpty()) return false;
    this->tag.remove(waked_skill_name + "_SKILLCANWAKE");

    LogMessage log;
    log.type = "#WakeSkillCanWake";
    log.from = this;
    log.arg = names.first();
    log.arg2 = waked_skill_name;
    room->sendLog(log);
    room->notifySkillInvoked(this, waked_skill_name);
    room->broadcastSkillInvoke(waked_skill_name);

    foreach (QString skill_name, names) {
        QString mark = "&" + skill_name + "+:+" + waked_skill_name;
        if (getMark(mark) <= 0) continue;
        room->setPlayerMark(this, mark, 0);
    }

    return true;
}
