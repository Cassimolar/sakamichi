#include "jxtp2.h"
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
#include "exppattern.h"
#include "sp4.h"
#include "yjcm2014.h"

TenyearZongxuanCard::TenyearZongxuanCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    target_fixed = true;
}

void TenyearZongxuanCard::use(Room *, ServerPlayer *, QList<ServerPlayer *> &) const
{
}

class TenyearZongxuanVS : public ViewAsSkill
{
public:
    TenyearZongxuanVS() : ViewAsSkill("tenyearzongxuan")
    {
        expand_pile = "#tenyearzongxuan";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return Self->getPile("#tenyearzongxuan").contains(to_select->getEffectiveId());
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@tenyearzongxuan");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        TenyearZongxuanCard *card = new TenyearZongxuanCard;
        card->addSubcards(cards);
        return card;
    }
};

class TenyearZongxuan : public TriggerSkill
{
public:
    TenyearZongxuan() : TriggerSkill("tenyearzongxuan")
    {
        events << CardsMoveOneTime;
        view_as_skill = new TenyearZongxuanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from != player)
            return false;
        if (move.to_place == Player::DiscardPile
            && ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)) {

            int i = 0;
            QList<int> zongxuan_card, trick_card;
            foreach (int card_id, move.card_ids) {
                if (room->getCardPlace(card_id) == Player::DiscardPile
                    && (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip)) {
                    zongxuan_card << card_id;
                    if (Sanguosha->getCard(card_id)->isKindOf("TrickCard"))
                        trick_card << card_id;
                }
                i++;
            }
            if (zongxuan_card.isEmpty())
                return false;

            QString pattern = "@@tenyearzongxuan";
            if (!trick_card.isEmpty()) {
                ServerPlayer *geter = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@tenyearzongxuan-trick", true, true);
                if (geter) {
                    room->broadcastSkillInvoke(objectName());
                    pattern = pattern + "!";

                    room->fillAG(trick_card, geter);  //偷懒用AG
                    int id = room->askForAG(geter, trick_card, false, objectName());
                    zongxuan_card.removeOne(id);
                    room->clearAG(geter);
                    room->obtainCard(geter, id);
                }
            }

            if (player->isDead() || zongxuan_card.isEmpty()) return false;

            room->notifyMoveToPile(player, zongxuan_card, objectName(), Player::DiscardPile, true);

            try {
                const Card *c = room->askForUseCard(player, pattern, pattern.endsWith("!") ? "@tenyearzongxuan" : "@mobilezongxuan");
                if (c) {
                    QList<int> subcards = c->getSubcards();
                    foreach (int id, subcards) {
                        if (zongxuan_card.contains(id))
                            zongxuan_card.removeOne(id);
                    }
                    LogMessage log;
                    log.type = "$YinshicaiPut";
                    log.from = player;
                    log.card_str = IntList2StringList(subcards).join("+");
                    room->sendLog(log);

                    room->notifyMoveToPile(player, subcards, objectName(), Player::DiscardPile, false);

                    CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), "tenyearzongxuan", QString());
                    room->moveCardTo(c, NULL, Player::DrawPile, reason, true, true);
                } else {
                    if (pattern.endsWith("!")) {
                        int id = zongxuan_card.at(qrand() % zongxuan_card.length());
                        CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), "tenyearzongxuan", QString());
                        room->moveCardTo(Sanguosha->getCard(id), NULL, Player::DrawPile, reason, true);
                    }
                }
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                    if (!zongxuan_card.isEmpty())
                        room->notifyMoveToPile(player, zongxuan_card, objectName(), Player::DiscardPile, false);
                }
                throw triggerEvent;
            }
            if (!zongxuan_card.isEmpty())
                room->notifyMoveToPile(player, zongxuan_card, objectName(), Player::DiscardPile, false);
        }
        return false;
    }
};

class TenyearZhiyan : public PhaseChangeSkill
{
public:
    TenyearZhiyan() : PhaseChangeSkill("tenyearzhiyan")
    {
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() != Player::Finish)
            return false;

        Room *room = target->getRoom();
        ServerPlayer *to = room->askForPlayerChosen(target, room->getAlivePlayers(), objectName(), "@zhiyan-invoke", true, true);
        if (to) {
            room->broadcastSkillInvoke(objectName());
            QList<int> ids = room->drawCardsList(to, 1, objectName(), true, true);
            int id = ids.first();
            const Card *card = Sanguosha->getCard(id);
            if (!to->isAlive())
                return false;
            room->showCard(to, id);

            if (card->isKindOf("EquipCard")) {
                room->recover(to, RecoverStruct(target));
                if (to->isAlive() && to->canUse(card) && !to->getEquipsId().contains(id))
                    room->useCard(CardUseStruct(card, to, to));
            } else if (card->isKindOf("BasicCard"))
                target->drawCards(1, objectName());
        }
        return false;
    }
};

class TenyearQiaoshi : public PhaseChangeSkill
{
public:
    TenyearQiaoshi() : PhaseChangeSkill("tenyearqiaoshi")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!TriggerSkill::triggerable(p) || p->getHandcardNum() != player->getHandcardNum())
                continue;

            int i = 0;
            Card::Suit suit1 = Card::NoSuit, suit2 = Card::NoSuit;
            while (suit1 == suit2) {
                if (p->isDead() || player->isDead()) break;
                //if (p->getHandcardNum() != player->getHandcardNum()) break;
                if (!p->askForSkillInvoke(this, player)) break;

                if (i == 0)
                    room->broadcastSkillInvoke(this);
                i++;

                QList<ServerPlayer *> l;
                l << p << player;
                room->sortByActionOrder(l);

                int id1 = room->drawCardsList(l.first(), 1, objectName()).first();
                int id2 = room->drawCardsList(l.last(), 1, objectName()).first();
                suit1 = Sanguosha->getCard(id1)->getSuit();
                suit2 = Sanguosha->getCard(id2)->getSuit();
            }
        }
        return false;
    }
};

TenyearYjYanyuCard::TenyearYjYanyuCard()
{
    will_throw = false;
    can_recast = true;
    handling_method = Card::MethodRecast;
    target_fixed = true;
}

void TenyearYjYanyuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->broadcastSkillInvoke("tenyearyjyanyu");
    ServerPlayer *xiahou = card_use.from;

    CardMoveReason reason(CardMoveReason::S_REASON_RECAST, xiahou->objectName());
    reason.m_skillName = getSkillName();
    room->moveCardTo(this, xiahou, NULL, Player::DiscardPile, reason);
    //xiahou->broadcastSkillInvoke("@recast");

    int id = card_use.card->getSubcards().first();

    LogMessage log;
    log.type = "#UseCard_Recast";
    log.from = xiahou;
    log.card_str = QString::number(id);
    room->sendLog(log);

    xiahou->drawCards(1, "recast");

    xiahou->addMark("tenyearyjyanyu-PlayClear");
}

class TenyearYjYanyuVS : public OneCardViewAsSkill
{
public:
    TenyearYjYanyuVS() : OneCardViewAsSkill("tenyearyjyanyu")
    {
        filter_pattern = "Slash";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Self->isCardLimited(originalCard, Card::MethodRecast))
            return NULL;

        TenyearYjYanyuCard *recast = new TenyearYjYanyuCard;
        recast->addSubcard(originalCard);
        return recast;
    }
};

class TenyearYjYanyu : public TriggerSkill
{
public:
    TenyearYjYanyu() : TriggerSkill("tenyearyjyanyu")
    {
        view_as_skill = new TenyearYjYanyuVS;
        events << EventPhaseEnd;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        int recastNum = player->getMark("tenyearyjyanyu-PlayClear");
        if (recastNum <= 0) return false;

        QList<ServerPlayer *> malelist;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isMale())
                malelist << p;
        }

        if (malelist.isEmpty()) return false;

        recastNum = qMin(recastNum, 3);

        ServerPlayer *male = room->askForPlayerChosen(player, malelist, objectName(), "@tenyearyjyanyu-give:" + QString::number(recastNum), true, true);

        if (male != NULL) {
            room->broadcastSkillInvoke(objectName());
            male->drawCards(recastNum, objectName());
        }
        return false;
    }
};

class TenyearQianxi : public PhaseChangeSkill
{
public:
    TenyearQianxi() : PhaseChangeSkill("tenyearqianxi")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(this);
        player->drawCards(1, objectName());
        if (!player->canDiscard(player, "he")) return false;
        const Card *card = room->askForDiscard(player, objectName(), 1, 1, false, true);
        if (!card) return false;

        QList<ServerPlayer *> to_choose;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (player->distanceTo(p) == 1)
                to_choose << p;
        }
        if (to_choose.isEmpty()) return false;

        ServerPlayer *t = room->askForPlayerChosen(player, to_choose, objectName());
        room->doAnimate(1, player->objectName(), t->objectName());

        QString color = QString();
        if (card->isRed())
            color = "red";
        else if (card->isBlack())
            color = "black";

        room->addPlayerMark(t, "tenyearqianxi_target_" + player->objectName() + "-Clear");
        if (!color.isEmpty()) {
            QString mark = "&tenyearqianxi+" + color + "-Clear";
            room->addPlayerMark(t, mark);
        }
        return false;
    }
};

class TenyearQianxiDraw : public TriggerSkill
{
public:
    TenyearQianxiDraw() : TriggerSkill("#tenyearqianxi-draw")
    {
        events << HpRecover;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent()) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead()) continue;
            int mark = player->getMark("tenyearqianxi_target_" + p->objectName() + "-Clear");
            for (int i = 0; i < mark; i++) {
                room->sendCompulsoryTriggerLog(p, "tenyearqianxi", true, true);
                p->drawCards(2, "tenyearqianxi");
            }
        }
        return false;
    }
};

class TenyearQianxiLimit : public CardLimitSkill
{
public:
    TenyearQianxiLimit() : CardLimitSkill("#tenyearqianxi-limit")
    {
        frequency = NotFrequent;
    }

    QString limitList(const Player *target) const
    {
        foreach (QString mark, target->getMarkNames()) {
            if (target->getMark(mark) <= 0) continue;
            if (mark == "&tenyearqianxi+red-Clear") return "use,response";
            if (mark == "&tenyearqianxi+black-Clear") return "use,response";
        }
        return QString();
    }

    QString limitPattern(const Player *target) const
    {
        QStringList colors;
        foreach (QString mark, target->getMarkNames()) {
            if (target->getMark(mark) <= 0) continue;
            if (mark == "&tenyearqianxi+red-Clear" && !colors.contains("red"))
                colors << "red";
            else if (mark == "&tenyearqianxi+black-Clear" && !colors.contains("black"))
                colors << "black";
        }
        if (!colors.isEmpty())
            return ".|" + colors.join(",") + "|.|hand";
        return QString();
    }
};

TenyearJiaozhaoCard::TenyearJiaozhaoCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
    mute = true;
}

void TenyearJiaozhaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->setPlayerMark(source, "ViewAsSkill_tenyearjiaozhaoEffect", 1);

    int selfcardid = getSubcards().first();
    room->showCard(source, selfcardid);

    int level = source->property("tenyearjiaozhao_level").toInt();
    ServerPlayer *target;
    if (level >= 1)
        target = source;
    else {
        int distance = source->distanceTo(source->getNextAlive());
        foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
            if (source->distanceTo(p) < distance)
                distance = source->distanceTo(p);
        }
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
            if (source->distanceTo(p) == distance)
                targets << p;
        }
        if (targets.isEmpty()) return;
        target = room->askForPlayerChosen(source, targets, "tenyearjiaozhao", "@jiaozhao-target");
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, source->objectName(), target->objectName());
    }

    QStringList alllist;
    QList<int> ids;
    bool basic = source->getMark("tenyearjiaozhao_basic-Clear") > 0;
    bool trick = source->getMark("tenyearjiaozhao_trick-Clear") > 0;
    foreach(int id, Sanguosha->getRandomCards()) {
        const Card *c = Sanguosha->getEngineCard(id);
        if (c->isKindOf("EquipCard") || c->isKindOf("DelayedTrick")) continue;
        if (basic && c->isKindOf("BasicCard")) continue;
        if (trick && c->isKindOf("TrickCard")) continue;
        if (alllist.contains(c->objectName())) continue;
        alllist << c->objectName();
        ids << id;
    }
    if (ids.isEmpty()) return;

    room->fillAG(ids, target);
    int id = room->askForAG(target, ids, false, "tenyearjiaozhao");
    room->clearAG(target);

    const Card *card = Sanguosha->getEngineCard(id);
    QString name = card->objectName();

    LogMessage log;
    log.type = "#ShouxiChoice";
    log.from = target;
    log.arg = name;
    room->sendLog(log);

    room->setPlayerProperty(source, "tenyearjiaozhao_name", name);
    if (card->isKindOf("BasicCard")) {
        room->setPlayerProperty(source, "tenyearjiaozhao_basic_name", name);
        room->setPlayerMark(source, "tenyearjiaozhao_basic-Clear", selfcardid + 1);
    } else if (card->isKindOf("TrickCard")) {
        room->setPlayerProperty(source, "tenyearjiaozhao_trick_name", name);
        room->setPlayerMark(source, "tenyearjiaozhao_trick-Clear", selfcardid + 1);
    }
}

class TenyearJiaozhaoVS : public OneCardViewAsSkill
{
public:
    TenyearJiaozhaoVS() : OneCardViewAsSkill("tenyearjiaozhao")
    {
        response_or_use = true;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString choice = Self->tag["tenyearjiaozhao"].toString();
        if (choice.isEmpty() || !selected.isEmpty()) return false;
        if (choice == "show") return !to_select->isEquipped();
        if (choice.startsWith("use")) {
            int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
            int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
            return to_select->getEffectiveId() == basic || to_select->getEffectiveId() == trick;
        } else if (choice.startsWith("basic")) {
            int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
            return to_select->getEffectiveId() == basic;
        } else if (choice.startsWith("trick")) {
            int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
            return to_select->getEffectiveId() == trick;
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            QString choice = Self->tag["tenyearjiaozhao"].toString();
            if (choice.isEmpty()) return NULL;
            if (choice == "show") {
                TenyearJiaozhaoCard *card = new TenyearJiaozhaoCard;
                card->addSubcard(originalCard);
                return card;
            } else if (choice.startsWith("use")) {
                int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
                int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
                if (basic > -1) {
                    QString bname = Self->property("tenyearjiaozhao_basic_name").toString();
                    Card *use_card = Sanguosha->cloneCard(bname);
                    if (!use_card) return NULL;
                    use_card->setCanRecast(false);
                    use_card->addSubcard(originalCard);
                    use_card->setSkillName("tenyearjiaozhao");
                    return use_card;
                } else if (trick > -1) {
                    QString tname = Self->property("tenyearjiaozhao_trick_name").toString();
                    Card *use_card = Sanguosha->cloneCard(tname);
                    if (!use_card) return NULL;
                    use_card->setCanRecast(false);
                    use_card->addSubcard(originalCard);
                    use_card->setSkillName("tenyearjiaozhao");
                    return use_card;
                }
            } else if (choice.startsWith("basic")) {
                int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
                if (basic < 0) return NULL;
                QString bname = Self->property("tenyearjiaozhao_basic_name").toString();
                Card *use_card = Sanguosha->cloneCard(bname);
                if (!use_card) return NULL;
                use_card->setCanRecast(false);
                use_card->addSubcard(originalCard);
                use_card->setSkillName("tenyearjiaozhao");
                return use_card;
            } else if (choice.startsWith("trick")) {
                int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
                if (trick < 0) return NULL;
                QString tname = Self->property("tenyearjiaozhao_trick_name").toString();
                Card *use_card = Sanguosha->cloneCard(tname);
                if (!use_card) return NULL;
                use_card->setCanRecast(false);
                use_card->addSubcard(originalCard);
                use_card->setSkillName("tenyearjiaozhao");
                return use_card;
            }
        } else {
            QString pattern = Sanguosha->getCurrentCardUsePattern();
            if (pattern == "nullification") {
                int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
                if (trick < 0) return NULL;
                QString tname = Self->property("tenyearjiaozhao_trick_name").toString();
                if (tname != "nullification") return NULL;
                Card *use_card = Sanguosha->cloneCard(tname);
                if (!use_card) return NULL;
                use_card->setCanRecast(false);
                use_card->addSubcard(trick);
                use_card->setSkillName("tenyearjiaozhao");
                return use_card;
            } else {
                int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
                if (basic < 0) return NULL;
                QString bname = Self->property("tenyearjiaozhao_basic_name").toString();
                Card *use_card = Sanguosha->cloneCard(bname);
                if (!use_card) return NULL;
                use_card->setCanRecast(false);
                use_card->addSubcard(basic);
                use_card->setSkillName("tenyearjiaozhao");
                return use_card;
            }
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (!player->hasUsed("JiaozhaoCard")) return true;
        int level = player->property("tenyearjiaozhao_level").toInt();

        if (level < 2 && player->hasUsed("JiaozhaoCard")) {
            Card *use_card = NULL;
            QString bname = Self->property("tenyearjiaozhao_basic_name").toString();
            QString tname = Self->property("tenyearjiaozhao_trick_name").toString();
            int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
            int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;

            if (!bname.isEmpty() && basic > -1) {
                use_card = Sanguosha->cloneCard(bname);
                if (!use_card) return false;
                use_card->addSubcard(basic);
            } else if (!tname.isEmpty() && trick > -1) {
                use_card = Sanguosha->cloneCard(tname);
                if (!use_card) return false;
                use_card->addSubcard(trick);
            }

            use_card->setCanRecast(false);
            use_card->setSkillName("tenyearjiaozhao");
            return use_card->isAvailable(player);
        } else if (level >= 2)
            return true;
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_RESPONSE_USE)
            return false;
        if (pattern.startsWith(".") || pattern.startsWith("@"))
            return false;

        QString bname = player->property("tenyearjiaozhao_basic_name").toString();
        QString tname = player->property("tenyearjiaozhao_trick_name").toString();
        if (bname.isEmpty() && tname.isEmpty()) return false;

        int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
        int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
        if (!bname.isEmpty() && basic < 0) return false;
        if (!tname.isEmpty() && trick < 0) return false;

        if (pattern == "nullification")
            return tname == "nullification";

        int level = player->property("tenyearjiaozhao_level").toInt();
        QString pattern_names = pattern;
        if (pattern.contains("slash") || pattern.contains("Slash"))
            pattern_names = Sanguosha->getSlashNames().join("+");
        else if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0)
            return false;
        else if (pattern == "peach+analeptic")
            return level >= 2 && pattern_names.split("+").contains(bname);
        return pattern_names.split("+").contains(bname);
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        QString tname = player->property("tenyearjiaozhao_trick_name").toString();
        if (tname.isEmpty()) return false;
        int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
        return trick > -1 && tname == "nullification";
    }
};

class TenyearJiaozhao : public TriggerSkill
{
public:
    TenyearJiaozhao() : TriggerSkill("tenyearjiaozhao")
    {
        events << EventPhaseChanging;
        view_as_skill = new TenyearJiaozhaoVS;
    }

    QDialog *getDialog() const
    {
        return TiansuanDialog::getInstance("tenyearjiaozhao");
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::NotActive) {
            room->setPlayerMark(player, "ViewAsSkill_tenyearjiaozhaoEffect", 0);
            room->setPlayerProperty(player, "tenyearjiaozhao_basic_name", QString());
            room->setPlayerProperty(player, "tenyearjiaozhao_trick_name", QString());
        }
        return false;
    }
};

class TenyearJiaozhaoPro : public ProhibitSkill
{
public:
    TenyearJiaozhaoPro() : ProhibitSkill("#tenyearjiaozhao")
    {
        frequency = NotFrequent;
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from == to && card->getSkillName() == "tenyearjiaozhao" && from->property("tenyearjiaozhao_level") < 2;
    }
};

class TenyearDanxin : public MasochismSkill
{
public:
    TenyearDanxin() : MasochismSkill("tenyeardanxin")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *target, const DamageStruct &) const
    {
        if (target->askForSkillInvoke(objectName())){
            Room *room = target->getRoom();
            room->broadcastSkillInvoke(objectName());

            target->drawCards(1, objectName());

            int level = target->property("tenyearjiaozhao_level").toInt();
            if (level < 0)
                level = 0;
            if (level <= 1) {
                LogMessage log;
                log.type = "#JiexunChange";
                log.from = target;
                log.arg = "tenyearjiaozhao";
                room->sendLog(log);
                level = level + 1;
                if (level > 2)
                    level = 2;
                room->setPlayerProperty(target, "tenyearjiaozhao_level", level);
                room->setPlayerMark(target, "&tenyearjiaozhao_level", level);
                room->changeTranslation(target, "tenyearjiaozhao", level);
            }
        }
    }
};

TenyearGanluCard::TenyearGanluCard()
{
}

void TenyearGanluCard::swapEquip(ServerPlayer *first, ServerPlayer *second) const
{
    Room *room = first->getRoom();

    QList<int> equips1, equips2;
    foreach(const Card *equip, first->getEquips())
        equips1.append(equip->getId());
    foreach(const Card *equip, second->getEquips())
        equips2.append(equip->getId());

    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1(equips1, second, Player::PlaceEquip,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, first->objectName(), second->objectName(), "ganlu", QString()));
    CardsMoveStruct move2(equips2, first, Player::PlaceEquip,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, second->objectName(), first->objectName(), "ganlu", QString()));
    exchangeMove.push_back(move2);
    exchangeMove.push_back(move1);
    room->moveCardsAtomic(exchangeMove, false);
}

bool TenyearGanluCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

bool TenyearGanluCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (targets.isEmpty()) return true;
    if (targets.length() == 1) {
        if (targets.first()->getEquips().isEmpty())
            return !to_select->getEquips().isEmpty();
        else
            return true;
    }
    return false;
}

void TenyearGanluCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    LogMessage log;
    log.type = "#GanluSwap";
    log.from = source;
    log.to = targets;
    room->sendLog(log);

    ServerPlayer *first = targets.first(), *last = targets[1];

    swapEquip(first, last);

    if (source->isAlive() && first->isAlive() && last->isAlive() &&
            qAbs(first->getEquips().length() - last->getEquips().length()) > source->getLostHp())
        room->askForDiscard(source, "tenyearganlu", 2, 2);
}

class TenyearGanlu : public ZeroCardViewAsSkill
{
public:
    TenyearGanlu() : ZeroCardViewAsSkill("tenyearganlu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearGanluCard");
    }

    const Card *viewAs() const
    {
        return new TenyearGanluCard;
    }
};

class TenyearBuyi : public TriggerSkill
{
public:
    TenyearBuyi() : TriggerSkill("tenyearbuyi")
    {
        events << Dying << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *wuguotai, QVariant &data) const
    {
        if (event == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            ServerPlayer *player = dying.who;
            if (player->isKongcheng()) return false;
            if (player->getHp() < 1 && wuguotai->askForSkillInvoke(this, data)) {
                wuguotai->peiyin(this);
                const Card *card = NULL;
                if (player == wuguotai)
                    card = room->askForCardShow(player, wuguotai, objectName());
                else {
                    int card_id = room->askForCardChosen(wuguotai, player, "h", "tenyearbuyi");
                    card = Sanguosha->getCard(card_id);
                }

                room->showCard(player, card->getEffectiveId());

                if (card->getTypeId() != Card::TypeBasic) {
                    if (!player->isJilei(card)) {
                        CardMoveReason reason;
                        reason.m_reason = CardMoveReason::S_REASON_THROW;
                        reason.m_playerId = player->objectName();
                        reason.m_skillName = objectName();
                        room->throwCard(card, reason, player);
                    }
                    room->recover(player, RecoverStruct(wuguotai));
                }
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from->isAlive() && move.is_last_handcard && move.reason.m_skillName == objectName()) {
                room->sendCompulsoryTriggerLog(wuguotai, this);
                ServerPlayer *from = (ServerPlayer *)move.from;
                from->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class TenyearZhuhai : public PhaseChangeSkill
{
public:
    TenyearZhuhai() : PhaseChangeSkill("tenyearzhuhai")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Finish && target->getMark("damage_point_round") > 0;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || (p->isKongcheng() && p->getHandPile().isEmpty())) continue;

            QStringList hand_pile_names, cards;
            foreach (QString pile, p->getPileNames()) {
                if (pile.startsWith("&") || pile == "wooden_ox")
                    hand_pile_names << pile;
            }
            foreach (int id, p->handCards() + p->getHandPile()) {
                const Card *c = Sanguosha->getCard(id);

                Slash *slash = new Slash(c->getSuit(), c->getNumber());
                slash->addSubcard(c);
                slash->setSkillName(objectName());
                slash->deleteLater();

                Dismantlement *dismantlement = new Dismantlement(c->getSuit(), c->getNumber());
                dismantlement->addSubcard(c);
                dismantlement->setSkillName(objectName());
                dismantlement->deleteLater();

                if (p->canSlash(player, slash, false))
                    cards << QString::number(id);
                else if (p->canUse(dismantlement, player, true))
                    cards << QString::number(id);
            }
            if (cards.isEmpty()) continue;

            const Card *card = room->askForCard(p, "" + cards.join(",") + "|.|.|hand," + hand_pile_names.join(","), "@tenyearzhuhai:" + player->objectName(),
                               QVariant::fromValue(player), Card::MethodResponse, player, true);
            if (!card) continue;

            Slash *slash = new Slash(card->getSuit(), card->getNumber());
            slash->addSubcard(card);
            slash->setSkillName(objectName());
            slash->deleteLater();

            Dismantlement *dismantlement = new Dismantlement(card->getSuit(), card->getNumber());
            dismantlement->addSubcard(card);
            dismantlement->setSkillName(objectName());
            dismantlement->deleteLater();

            QStringList choices;
            if (p->canSlash(player, slash, false))
                choices << "slash=" + player->objectName();
            if (p->canUse(dismantlement, player, true))
                choices << "dismantlement=" + player->objectName();
            if (choices.isEmpty()) continue;

            QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(player));
            if (choice.startsWith("slash"))
                room->useCard(CardUseStruct(slash, p, player), true);
            else
                room->useCard(CardUseStruct(dismantlement, p, player), true);
        }
        return false;
    }
};

class TenyearQianxin : public TriggerSkill
{
public:
    TenyearQianxin() : TriggerSkill("tenyearqianxin")
    {
        events << Damage;
        frequency = Wake;
        waked_skills = "tenyearjianyan";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->isWounded()) {
            LogMessage log;
            log.type = "#QianxinWake";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(player, objectName());

        room->doSuperLightbox("tenyear_xushu", "tenyearqianxin");

        room->setPlayerMark(player, "tenyearqianxin", 1);
        if (room->changeMaxHpForAwakenSkill(player) && player->getMark("tenyearqianxin") == 1)
            room->acquireSkill(player, "tenyearjianyan");
        return false;
    }
};

TenyearJianyanCard::TenyearJianyanCard()
{
    target_fixed = true;
}

void TenyearJianyanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QStringList choice_list, pattern_list;

    if (source->getMark("tenyearjianyan_type-PlayClear") <= 0) {
        choice_list << "basic" << "trick" << "equip";
        pattern_list << "BasicCard" << "TrickCard" << "EquipCard";
    }
    if (source->getMark("tenyearjianyan_color-PlayClear") <= 0) {
        choice_list << "red" << "black";
        pattern_list << ".|red" << ".|black";
    }
    if (choice_list.isEmpty()) return;

    QString choice = room->askForChoice(source, "tenyearjianyan", choice_list.join("+"));
    int index = choice_list.indexOf(choice);
    QString pattern = pattern_list.at(index);

    if (index <= 2 && choice_list.contains("basic"))
        room->addPlayerMark(source, "tenyearjianyan_type-PlayClear");
    else
        room->addPlayerMark(source, "tenyearjianyan_color-PlayClear");

    LogMessage log;
    log.type = "#JianyanChoice";
    log.from = source;
    log.arg = choice;
    room->sendLog(log);

    int card_id = -1;
    foreach (int id, room->getDrawPile()) {
        const Card *card = Sanguosha->getCard(id);
        if (Sanguosha->matchExpPattern(pattern, NULL, card)) {
            card_id = id;
            break;
        }
    }
    if (card_id > -1) {
        CardsMoveStruct move(card_id, NULL, Player::PlaceTable,
            CardMoveReason(CardMoveReason::S_REASON_TURNOVER, source->objectName(), "tenyearjianyan", QString()));
        room->moveCardsAtomic(move, true);
        room->getThread()->delay();

        QList<ServerPlayer *> males;
        foreach (ServerPlayer *player, room->getAlivePlayers()) {
            if (player->isMale())
                males << player;
        }
        if (males.isEmpty() || source->isDead()) {
            DummyCard *dummy = new DummyCard();
            dummy->addSubcard(card_id);
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, source->objectName(), "tenyearjianyan", QString());
            room->throwCard(dummy, reason, NULL);
            delete dummy;
        } else {
            const Card *card = Sanguosha->getCard(card_id);
            if (!room->CardInTable(card)) return;

            room->fillAG(QList<int>() << card_id, source);
            source->setMark("tenyearjianyan", card_id); // For AI
            ServerPlayer *target = room->askForPlayerChosen(source, males, "tenyearjianyan",
                QString("@jianyan-give:::%1:%2\\%3").arg(card->objectName())
                .arg(card->getSuitString() + "_char")
                .arg(card->getNumberString()));
            room->clearAG(source);
            room->giveCard(source, target, card, "tenyearjianyan", true);
        }
    } else {
        LogMessage log;
        log.type = "#TenyearjianyanSwapPile";
        room->sendLog(log);
        room->swapPile();
    }
}

class TenyearJianyan : public ZeroCardViewAsSkill
{
public:
    TenyearJianyan() : ZeroCardViewAsSkill("tenyearjianyan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("tenyearjianyan_type-PlayClear") <= 0 || player->getMark("tenyearjianyan_color-PlayClear") <= 0;
    }

    const Card *viewAs() const
    {
        return new TenyearJianyanCard;
    }
};

TenyearAnxuCard::TenyearAnxuCard()
{
}

bool TenyearAnxuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (to_select == Self)
        return false;
    if (targets.isEmpty())
        return true;
    else if (targets.length() == 1)
        return to_select->getHandcardNum() != targets.first()->getHandcardNum();
    else
        return false;
}

bool TenyearAnxuCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void TenyearAnxuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QList<ServerPlayer *> selecteds = targets;
    ServerPlayer *from = selecteds.first()->getHandcardNum() < selecteds.last()->getHandcardNum() ? selecteds.takeFirst() : selecteds.takeLast();
    ServerPlayer *to = selecteds.takeFirst();
    int id = room->askForCardChosen(from, to, "h", "tenyearanxu");
    const Card *cd = Sanguosha->getCard(id);
    from->obtainCard(cd);
    room->showCard(from, id);
    if (cd->getSuit() != Card::Spade)
        source->drawCards(1, "tenyearanxu");
    if (from->isAlive() && to->isAlive() && from->getHandcardNum() != to->getHandcardNum())
        room->recover(source, RecoverStruct());
}

class TenyearAnxu : public ZeroCardViewAsSkill
{
public:
    TenyearAnxu() : ZeroCardViewAsSkill("tenyearanxu")
    {
    }

    const Card *viewAs() const
    {
        return new TenyearAnxuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearAnxuCard");
    }
};

class TenyearZhuiyi : public TriggerSkill
{
public:
    TenyearZhuiyi() : TriggerSkill("tenyearzhuiyi")
    {
        events << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill(this);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player) return false;
        QList<ServerPlayer *> targets = (death.damage && death.damage->from) ? room->getOtherPlayers(death.damage->from) :
            room->getAlivePlayers();
        if (targets.isEmpty()) return false;
        int alive = room->alivePlayerCount();
        if (alive <= 0) return false;
        QString prompt = "@tenyearzhuiyi-invoke:" + QString::number(alive);
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), prompt, true, true);
        if (!target) return false;
        player->peiyin(this);
        target->drawCards(alive, objectName());
        room->recover(target, RecoverStruct(player), true);
        return false;
    }
};

class TenyearJianying : public Jianying
{
public:
    TenyearJianying() : Jianying()
    {
        setObjectName("tenyearjianying");
        jianying = "TenyearJianying";
    }
};

class TenyearShibei : public MasochismSkill
{
public:
    TenyearShibei() : MasochismSkill("tenyearshibei")
    {
        frequency = Compulsory;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        Room *room = player->getRoom();
        if (player->getMark("shibei") > 0) {
            room->sendCompulsoryTriggerLog(player, this);

            if (player->getMark("shibei") == 1)
                room->recover(player, RecoverStruct(player));
            else if (player->getMark("shibei") == 2)
                room->loseHp(player);
        }
    }
};

JXTP2Package::JXTP2Package()
    : Package("JXTP2")
{
    General *tenyear_wangyi = new General(this, "tenyear_wangyi", "wei", 4, false);
    tenyear_wangyi->addSkill("zhenlie");
    tenyear_wangyi->addSkill("secondmiji");

    General *tenyear_yufan = new General(this, "tenyear_yufan", "wu", 3);
    tenyear_yufan->addSkill(new TenyearZongxuan);
    tenyear_yufan->addSkill(new TenyearZhiyan);

    General *tenyear_xiahoushi = new General(this, "tenyear_xiahoushi", "shu", 3, false);
    tenyear_xiahoushi->addSkill(new TenyearQiaoshi);
    tenyear_xiahoushi->addSkill(new TenyearYjYanyu);

    General *tenyear_madai = new General(this, "tenyear_madai", "shu", 4);
    tenyear_madai->addSkill(new TenyearQianxi);
    tenyear_madai->addSkill(new TenyearQianxiDraw);
    tenyear_madai->addSkill(new TenyearQianxiLimit);
    tenyear_madai->addSkill("mashu");
    related_skills.insertMulti("tenyearqianxi", "#tenyearqianxi-draw");
    related_skills.insertMulti("tenyearqianxi", "#tenyearqianxi-limit");

    General *tenyear_guohuanghou = new General(this, "tenyear_guohuanghou", "wei", 3, false);
    tenyear_guohuanghou->addSkill(new TenyearJiaozhao);
    tenyear_guohuanghou->addSkill(new TenyearJiaozhaoPro);
    tenyear_guohuanghou->addSkill(new TenyearDanxin);
    related_skills.insertMulti("tenyearjiaozhao", "#tenyearjiaozhao");

    General *tenyear_wuguotai = new General(this, "tenyear_wuguotai", "wu", 3, false);
    tenyear_wuguotai->addSkill(new TenyearGanlu);
    tenyear_wuguotai->addSkill(new TenyearBuyi);

    General *tenyear_xushu = new General(this, "tenyear_xushu", "shu", 4);
    tenyear_xushu->addSkill(new TenyearZhuhai);
    tenyear_xushu->addSkill(new TenyearQianxin);

    General *tenyear_bulianshi = new General(this, "tenyear_bulianshi", "wu", 3, false);
    tenyear_bulianshi->addSkill(new TenyearAnxu);
    tenyear_bulianshi->addSkill(new TenyearZhuiyi);

    General *tenyear_jushou = new General(this, "tenyear_jushou", "qun", 3);
    tenyear_jushou->addSkill(new TenyearJianying);
    tenyear_jushou->addSkill(new TenyearShibei);

    addMetaObject<TenyearZongxuanCard>();
    addMetaObject<TenyearYjYanyuCard>();
    addMetaObject<TenyearJiaozhaoCard>();
    addMetaObject<TenyearGanluCard>();
    addMetaObject<TenyearJianyanCard>();
    addMetaObject<TenyearAnxuCard>();

    skills << new TenyearJianyan;
}

ADD_PACKAGE(JXTP2)
