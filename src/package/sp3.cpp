#include "sp3.h"
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
#include "yjcm2013.h"
#include "wind.h"

class Duoduan : public TriggerSkill
{
public:
    Duoduan() : TriggerSkill("duoduan")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        if (player->getMark("duoduan-Clear") > 0) return false;

        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player) || !use.card->isKindOf("Slash")) return false;
        if (player->isNude()) return false;

        const Card *c = room->askForCard(player, "..", "@duoduan-card", data, Card::MethodRecast, NULL, false, objectName());
        if (!c) return false;
        room->addPlayerMark(player, "duoduan-Clear");

        LogMessage log;
        log.type = "$DuoduanRecast";
        log.from = player;
        log.arg = objectName();
        log.card_str = c->toString();
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        CardMoveReason reason(CardMoveReason::S_REASON_RECAST, player->objectName());
        reason.m_skillName = objectName();
        room->moveCardTo(c, player, NULL, Player::DiscardPile, reason);
        player->drawCards(1, "recast");

        if (use.from->isDead()) return false;
        if (use.from->canDiscard(use.from, "he")) {
            use.from->tag["duoduanForAI"] = data;
            const Card *dis = room->askForDiscard(use.from, objectName(), 1, 1, true, true, "@duoduan-discard");
            use.from->tag.remove("duoduanForAI");
            if (dis)
                use.no_respond_list << "_ALL_TARGETS";
            else {
                use.from->drawCards(2, objectName());
                use.nullified_list << "_ALL_TARGETS";
            }
        } else {
            use.from->drawCards(2, objectName());
            use.nullified_list << "_ALL_TARGETS";
        }
        data = QVariant::fromValue(use);
        return false;
    }
};

GongsunCard::GongsunCard()
{
    handling_method = Card::MethodDiscard;
}

void GongsunCard::onEffect(const CardEffectStruct &effect) const
{
    QStringList names;
    QList<int> ids;
    foreach (int id, Sanguosha->getRandomCards()) {
        const Card *c = Sanguosha->getEngineCard(id);
        if (c->isKindOf("DelayedTrick") || c->isKindOf("EquipCard")) continue;
        if (c->isKindOf("Slash") && c->objectName() != "slash") continue;
        QString name = c->objectName();
        if (names.contains(name)) continue;
        names << name;
        ids << id;
    }
    if (ids.isEmpty()) return;

    ServerPlayer *player = effect.from, *target = effect.to;
    Room *room = player->getRoom();

    room->fillAG(ids, player);
    int id = room->askForAG(player, ids, false, objectName());
    room->clearAG(player);

    LogMessage log;
    log.type = "#GongsunLimit";
    log.from = player;
    log.to << target;
    log.arg = Sanguosha->getEngineCard(id)->objectName();
    room->sendLog(log);

    QString class_name = Sanguosha->getEngineCard(id)->getClassName();
    QStringList limit_names = player->tag["GongsunLimited" + target->objectName()].toStringList();
    if (!limit_names.contains(class_name)) {
        limit_names << class_name;
        player->tag["GongsunLimited" + target->objectName()] = limit_names;
    }
    room->setPlayerCardLimitation(player, "use,response,discard", class_name + "|.|.|hand", false);
    room->setPlayerCardLimitation(target, "use,response,discard", class_name + "|.|.|hand", false);
    room->addPlayerMark(player, "&gongsun+" + Sanguosha->getEngineCard(id)->objectName());
    room->addPlayerMark(target, "&gongsun+" + Sanguosha->getEngineCard(id)->objectName());
}

class GongsunVS : public ViewAsSkill
{
public:
    GongsunVS() : ViewAsSkill("gongsun")
    {
        response_pattern = "@@gongsun";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && selected.length() < 2;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2)
            return NULL;

        GongsunCard *c = new GongsunCard;
        c->addSubcards(cards);
        return c;
    }
};

class Gongsun : public TriggerSkill
{
public:
    Gongsun() : TriggerSkill("gongsun")
    {
        events << EventPhaseStart << EventPhaseChanging << Death;
        view_as_skill = new GongsunVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->isDead() || !player->hasSkill(this) || player->getPhase() != Player::Play) return false;
            if (player->getCardCount() < 2 || !player->canDiscard(player, "he")) return false;
            room->askForUseCard(player, "@@gongsun", "@gongsun");
        } else {
            if (event == EventPhaseChanging) {
                if (data.value<PhaseChangeStruct>().to != Player::RoundStart) return false;
            } else {
                DeathStruct death = data.value<DeathStruct>();
                if (!death.who->hasSkill(this, true)) return false;
                if (player != death.who) return false;
            }

            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                QStringList limit_names = player->tag["GongsunLimited" + p->objectName()].toStringList();
                if (limit_names.isEmpty()) continue;
                player->tag.remove("GongsunLimited" + p->objectName());
                foreach (QString classname, limit_names) {
                    room->removePlayerCardLimitation(player, "use,response,discard", classname + "|.|.|hand");
                    bool remove = true;
                    foreach (ServerPlayer *d, room->getOtherPlayers(player)) {
                        if (d->tag["GongsunLimited" + p->objectName()].toStringList().contains(classname)) {
                            remove = false;
                            break;
                        }
                    }
                    if (remove)
                        room->removePlayerCardLimitation(p, "use,response,discard", classname + "|.|.|hand");

                    //room->removePlayerMark(player, "&gongsun+" + classname.toLower());
                    //room->removePlayerMark(p, "&gongsun+" + classname.toLower());
                    QString name;
                    foreach (int id, Sanguosha->getRandomCards()) {
                        const Card *c = Sanguosha->getEngineCard(id);
                        if (c->getClassName() == classname) {
                            name = c->objectName();
                            break;
                        }
                    }
                    if (!name.isEmpty()) {
                        room->removePlayerMark(player, "&gongsun+" + name);
                        room->removePlayerMark(p, "&gongsun+" + name);
                    }
                }
            }
        }
        return false;
    }
};

class Juanxia : public TriggerSkill
{
public:
    Juanxia() : TriggerSkill("juanxia")
    {
        events << EventPhaseChanging;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@juanxia-invoke", true, true);
        if (!t) return false;
        room->broadcastSkillInvoke(this);

        int num = 0;
        QString first_card;
        try {
            for (int i = 0; i < 2; i++) {

                QStringList cards;
                QList<const SingleTargetTrick *>singles = Sanguosha->findChildren<const SingleTargetTrick *>();
                foreach (const SingleTargetTrick *st, singles) {
                    if (!player->canUse(st, t, true)) continue;
                    QString name = st->objectName();
                    if (name.startsWith("_")) continue;
                    if (!ServerInfo.Extensions.contains("!" + st->getPackage()) && st->isNDTrick()
                        && !cards.contains(st->objectName()) && !st->isKindOf("Nullification") && name != first_card)
                        cards << name;
                }
                if (cards.isEmpty()) break;

                if (i == 1)
                    cards << "cancel";

                QString card_name = room->askForChoice(player, objectName(), cards.join("+"), QVariant::fromValue(t));
                if (card_name == "cancel") break;

                if (i == 0)
                    first_card = card_name;

                Card *card = Sanguosha->cloneCard(card_name);
                if (!card) continue;
                card->setSkillName("_juanxia");
                card->deleteLater();
                if (!player->canUse(card, t, true)) continue;

                if (card->isKindOf("Collateral")) {
                    QList<ServerPlayer *> victims;
                    foreach (ServerPlayer *p, room->getOtherPlayers(t)) {
                        if (t->canSlash(p))
                            victims << p;
                    }
                    if (victims.isEmpty()) continue;

                    ServerPlayer *collateral_victim = room->askForPlayerChosen(player, victims, "juanxia_collateral", "@zenhui-collateral:" + t->objectName());
                    t->tag["collateralVictim"] = QVariant::fromValue((collateral_victim));

                    LogMessage log;
                    log.type = "#CollateralSlash";
                    log.from = player;
                    log.to << collateral_victim;
                    room->sendLog(log);
                    room->doAnimate(1, t->objectName(), collateral_victim->objectName());
                }

                num++;
                room->useCard(CardUseStruct(card, player, t));
            }
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                if (num > 0 && t->isAlive())
                    room->addPlayerMark(t, "&juanxia+" + player->objectName(), num);
            }
            throw triggerEvent;
        }

        if (num > 0 && t->isAlive())
            room->addPlayerMark(t, "&juanxia+#" + player->objectName(), num);
        return false;
    }
};

class JuanxiaSlash : public TriggerSkill
{
public:
    JuanxiaSlash() : TriggerSkill("#juanxia-slash")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;

        QList<ServerPlayer *> tos;
        QHash<ServerPlayer *, int> hash;

        foreach (QString mark, player->getMarkNames()) {
            int mark_num = player->getMark(mark);
            if (!mark.startsWith("&juanxia+#") || mark_num <= 0) continue;
            QStringList marks = mark.split("#");
            if (marks.length() != 2) continue;
            room->setPlayerMark(player, mark, 0);
            ServerPlayer *to = room->findChild<ServerPlayer *>(marks.last());
            if (!to || to->isDead()) continue;
            hash[to] = mark_num;
            tos << to;
        }
        if (tos.isEmpty()) return false;
        room->sortByActionOrder(tos);

        foreach (ServerPlayer *to, tos) {
            if (player->isDead()) return false;
            if (to->isDead() || !player->canSlash(to, false)) continue;

            int mark_num = hash[to];
            if (mark_num <= 0) continue;

            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = to;
            log.arg = "juanxia";
            room->sendLog(log);
            room->notifySkillInvoked(to, "juanxia");

            QString prompt = "juanxia_slash:" + to->objectName() + "::" + QString::number(mark_num);
            if (!player->askForSkillInvoke("juanxia_slash", prompt, false)) continue;

            for (int i = 0; i < mark_num; i++) {
                if (player->isDead()) return false;
                if (to->isDead() || !player->canSlash(to, false)) break;

                Slash *slash = new Slash(Card::NoSuit, 0);
                slash->setSkillName("_juanxia");
                slash->deleteLater();
                room->useCard(CardUseStruct(slash, player, to));
            }
        }
        return false;
    }
};

class Dingcuo : public TriggerSkill
{
public:
    Dingcuo() : TriggerSkill("dingcuo")
    {
        events << Damage << Damaged;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent() || player->getMark("dingcuo-Clear") > 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(this);
        room->addPlayerMark(player, "dingcuo-Clear");

        QList<int> draw_ids = room->drawCardsList(player, 2, objectName());
        const Card *first = Sanguosha->getCard(draw_ids.first());
        const Card *last = Sanguosha->getCard(draw_ids.last());
        if (first->sameColorWith(last)) return false;
        if (player->canDiscard(player, "h"))
            room->askForDiscard(player, objectName(), 1, 1);
        return false;
    }
};

ZhouxuanCard::ZhouxuanCard()
{
    target_fixed = true;
}

void ZhouxuanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isDead()) return;
    ServerPlayer *target = room->askForPlayerChosen(source, room->getOtherPlayers(source), "zhouxuan", "@zhouxuan-invoke");
    room->doAnimate(1, source->objectName(), target->objectName());
    QStringList names;
    names << "EquipCard" << "TrickCard";
    foreach (int id, Sanguosha->getRandomCards()) {
        const Card *c = Sanguosha->getEngineCard(id);
        if (!c->isKindOf("BasicCard") || c->isKindOf("FireSlash") || c->isKindOf("ThunderSlash")) continue;
        QString name = c->objectName();
        if (names.contains(name)) continue;
        names << name;
    }
    if (names.isEmpty()) return;

    QString name = room->askForChoice(source, "zhouxuan", names.join("+"), QVariant::fromValue(target));

    /*LogMessage log;
    log.type = "#ZhouxuanChoice";
    log.from = source;
    log.to << target;
    log.arg = name;
    room->sendLog(log);*/

    /*QStringList zhouxuan = target->tag["Zhouxuan" + source->objectName()].toStringList();
    if (!zhouxuan.contains(name)) {
        zhouxuan << name;
        target->tag["Zhouxuan" + source->objectName()] = zhouxuan;
        room->addPlayerMark(target, "&zhouxuan+" + name);
    }*/
    if (target->tag["Zhouxuan" + source->objectName()].toString() == name) return;
    target->tag["Zhouxuan" + source->objectName()] = name;
    foreach (QString mark, target->getMarkNames()) {
        if (!mark.startsWith("&zhouxuan+") && !mark.endsWith("+#" + source->objectName())) continue;
        if (target->getMark(mark) <= 0) continue;
        room->setPlayerMark(target, mark, 0);
    }
    room->setPlayerMark(target, "&zhouxuan+" + name + "+#" + source->objectName(), 1, QList<ServerPlayer *>() << source);
}

class ZhouxuanVS : public OneCardViewAsSkill
{
public:
    ZhouxuanVS() :OneCardViewAsSkill("zhouxuan")
    {
        filter_pattern = ".";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZhouxuanCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ZhouxuanCard *c = new ZhouxuanCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class Zhouxuan : public TriggerSkill
{
public:
    Zhouxuan() : TriggerSkill("zhouxuan")
    {
        events << CardUsed << CardResponded << Death;
        view_as_skill = new ZhouxuanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            if (player != data.value<DeathStruct>().who) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                player->tag.remove("Zhouxuan" + p->objectName());
        } else {
            const Card *card = NULL;
            if (event == CardUsed)
                card = data.value<CardUseStruct>().card;
            else
                card = data.value<CardResponseStruct>().m_card;
            if (card == NULL || card->isKindOf("SkillCard")) return false;

            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead() || !p->hasSkill(this, true)) continue;
                QString zhouxuan = player->tag["Zhouxuan" + p->objectName()].toString();
                if (zhouxuan.isEmpty()) continue;
                player->tag.remove("Zhouxuan" + p->objectName());
                room->setPlayerMark(player, "&zhouxuan+" + zhouxuan + "+#" + p->objectName(), 0);

                if (p->isDead() || !p->hasSkill(this)) continue;
                bool same = false;
                if (card->isKindOf("EquipCard")) {
                    if (zhouxuan != "EquipCard")
                        continue;
                    else
                        same = true;
                }
                if (card->isKindOf("TrickCard")) {
                    if (zhouxuan != "TrickCard")
                        continue;
                    else
                        same = true;
                }
                if (!same) {
                    if (card->sameNameWith(zhouxuan))
                        same = true;
                }
                if (!same) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);

                QList<ServerPlayer *> _player;
                _player.append(p);
                QList<int> yiji_cards = room->getNCards(3, false);

                CardsMoveStruct move(yiji_cards, NULL, p, Player::PlaceTable, Player::PlaceHand,
                    CardMoveReason(CardMoveReason::S_REASON_PREVIEW, p->objectName(), objectName(), QString()));
                QList<CardsMoveStruct> moves;
                moves.append(move);
                room->notifyMoveCards(true, moves, false, _player);
                room->notifyMoveCards(false, moves, false, _player);

                QList<int> origin_yiji = yiji_cards;
                while (room->askForYiji(p, yiji_cards, objectName(), true, false, true, -1, room->getAlivePlayers())) {
                    CardsMoveStruct move(QList<int>(), p, NULL, Player::PlaceHand, Player::PlaceTable,
                        CardMoveReason(CardMoveReason::S_REASON_PREVIEW, p->objectName(), objectName(), QString()));
                    foreach (int id, origin_yiji) {
                        if (room->getCardPlace(id) != Player::DrawPile) {
                            move.card_ids << id;
                            yiji_cards.removeOne(id);
                        }
                    }
                    origin_yiji = yiji_cards;
                    QList<CardsMoveStruct> moves;
                    moves.append(move);
                    room->notifyMoveCards(true, moves, false, _player);
                    room->notifyMoveCards(false, moves, false, _player);
                    if (!p->isAlive())
                        return false;
                }

                if (!yiji_cards.isEmpty()) {
                    CardsMoveStruct move(yiji_cards, p, NULL, Player::PlaceHand, Player::PlaceTable,
                                         CardMoveReason(CardMoveReason::S_REASON_PREVIEW, p->objectName(), objectName(), QString()));
                    QList<CardsMoveStruct> moves;
                    moves.append(move);
                    room->notifyMoveCards(true, moves, false, _player);
                    room->notifyMoveCards(false, moves, false, _player);

                    DummyCard *dummy = new DummyCard(yiji_cards);
                    p->obtainCard(dummy, false);
                    delete dummy;
                }
            }
        }
        return false;
    }
};

class Fengji : public TriggerSkill
{
public:
    Fengji() : TriggerSkill("fengji")
    {
        events << EventPhaseStart << EventPhaseChanging << EventAcquireSkill << EventLoseSkill;
        global = true;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            player->tag["FengjiLastTurn"] = true;
            player->tag["FengjiHandNum"] = player->getHandcardNum();
            if (player->hasSkill(this, true))
                room->setPlayerMark(player, "&fengji", player->getHandcardNum());
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            if (!player->tag["FengjiLastTurn"].toBool()) return false;
            int n = player->tag["FengjiHandNum"].toInt();
            room->setPlayerMark(player, "&fengji", 0);
            if (!player->hasSkill(this) || player->getHandcardNum() < n) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->drawCards(2, objectName());
            room->setPlayerFlag(player, "fengji");
        } else {
            if (player->hasSkill(this, true)) {
                int n = player->tag["FengjiHandNum"].toInt();
                room->setPlayerMark(player, "&fengji", n);
            } else
                room->setPlayerMark(player, "&fengji", 0);
        }
        return false;
    }
};

class FengjiMaxCards : public MaxCardsSkill
{
public:
    FengjiMaxCards() : MaxCardsSkill("#fengji")
    {
    }

    int getFixed(const Player *target) const
    {
        if (target->hasFlag("fengji"))
            return target->getMaxHp();
        else
            return -1;
    }
};

class Wangzu : public TriggerSkill
{
public:
    Wangzu() : TriggerSkill("wangzu")
    {
        events << DamageInflicted;
    }

    int getFriends(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int fri = 0;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isYourFriend(player))
                fri++;
        }
        return fri;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("wangzu-Clear") > 0 || !player->canDiscard(player, "h")) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from == player) return false;

        bool most = true;
        int fri = getFriends(player);
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (getFriends(p) > fri) {
                most = false;
                break;
            }
        }

        bool invoke = false;
        QString number = QString::number(damage.damage);
        player->tag["WangzuDamage"] = data;

        if (most)
            invoke = room->askForCard(player, ".|.|.|hand", "@wangzu-discard:" + number, data, objectName());
        else
            invoke = player->askForSkillInvoke(this, "wangzu:" + number);

        player->tag.remove("WangzuDamage");

        if (!invoke) return false;
        room->broadcastSkillInvoke(this);

        if (!most) {
            QList<int> ids;
            foreach (int id, player->handCards()) {
                if (player->canDiscard(player, id))
                    ids << id;
            }
            if (ids.isEmpty()) return false;
            int id = ids.at(qrand() % ids.length());
            room->throwCard(id, player);
        }

        damage.damage--;
        data = QVariant::fromValue(damage);
        if (damage.damage <= 0)
            return true;
        return false;
    }
};

YingruiCard::YingruiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool YingruiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->inMyAttackRange(to_select) && to_select != Self;
}

void YingruiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    room->giveCard(from, to, this, "yingrui");

    if (to->isDead()) return;

    if (from->isDead())
        room->damage(DamageStruct("yingrui", NULL, to));
    else {
        const Card *card = room->askForExchange(to, "yingrui", 99999, 2, true, "@yingrui-give:" + from->objectName(), true, "EquipCard");
        if (card) {
           room->giveCard(to, from, card, "yingrui", true);
           delete card;
        } else
            room->damage(DamageStruct("yingrui", from->isAlive() ? from : NULL, to));
    }
}

class Yingrui : public OneCardViewAsSkill
{
public:
    Yingrui() : OneCardViewAsSkill("yingrui")
    {
        filter_pattern = ".";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YingruiCard");
    }

    const Card *viewAs(const Card *c) const
    {
        YingruiCard *card = new YingruiCard();
        card->addSubcard(c);
        return card;
    }
};

class Fuyuan : public TriggerSkill
{
public:
    Fuyuan() : TriggerSkill("fuyuan")
    {
        events << TargetConfirmed;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (!use.to.contains(player)) return false;

        if (use.card->isRed())
            room->addPlayerMark(player, "fuyuan_red-Clear", 1);

        int n = 0;
        if (use.card->isRed() && use.card->isKindOf("Slash"))
            n++;

        if (use.card->isKindOf("Slash") && player->getMark("fuyuan_red-Clear") == n) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this)) continue;
                if (!p->askForSkillInvoke(this, player)) continue;
                room->broadcastSkillInvoke(this);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class OLFengji : public PhaseChangeSkill
{
public:
    OLFengji() : PhaseChangeSkill("olfengji")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Draw) return false;
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        QStringList choices, chosen;
        choices << "draw" << "slash" << "cancel";
        while (choices.length() > 1) {
            if (player->isDead()) return false;
            QString choice = room->askForChoice(player, "olfengji", choices.join("+"), QVariant(), chosen.join("+"));
            if (choice == "cancel") break;
            choices.removeOne(choice);
            chosen << choice;
            ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@olfengji" + choice);
            room->doAnimate(1, player->objectName(), t->objectName());
            room->addPlayerMark(t, "&olfengji" + choice + "-SelfClear");
        }
        if (!chosen.contains("draw") && player->isAlive())
            room->addPlayerMark(player, "&olfengjidraw-SelfClear");
        if (!chosen.contains("slash") && player->isAlive())
            room->addPlayerMark(player, "&olfengjislash-SelfClear");
        return false;
    }
};

class OLFengjiDraw : public DrawCardsSkill
{
public:
    OLFengjiDraw() : DrawCardsSkill("#olfengji-draw")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&olfengjidraw-SelfClear") > 0;
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#ZhenguEffect";
        log.from = player;
        log.arg = "olfengji";
        room->sendLog(log);
        room->broadcastSkillInvoke("olfengji");
        return n += 2 * player->getMark("&olfengjidraw-SelfClear");
    }
};

class OLFengjiTargetMod : public TargetModSkill
{
public:
    OLFengjiTargetMod() : TargetModSkill("#olfengji-target")
    {
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->getPhase() == Player::Play)
            return qMax(0, 2 * from->getMark("&olfengjislash-SelfClear"));
        return 0;
    }
};

class TenyearMeibu : public PhaseChangeSkill
{
public:
    TenyearMeibu(const QString &meibu) : PhaseChangeSkill(meibu), meibu(meibu)
    {
        waked_skills = "tenyearzhixi";
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
            if (p->isDead() || !p->hasSkill(this) || !player->inMyAttackRange(p)) continue;
            if (!p->canDiscard(p, "he")) continue;
            const Card *card = room->askForCard(p, "..", "@" + meibu + "-dis:" + player->objectName(), QVariant::fromValue(player), objectName());
            if (!card) continue;
            room->broadcastSkillInvoke(objectName());

            if (meibu == "secondtenyearmeibu") {
                QString mark;
                foreach (QString mk, p->getMarkNames()) {
                    if (!mk.startsWith("&" + meibu + "+") || !mk.endsWith("-Clear") || p->getMark(mk) <= 0) continue;
                    mark = mk;
                    break;
                }
                QString string = card->getSuitString() + "_char";
                if (mark.isEmpty())
                    mark = "&" + meibu + "+" + string + "-Clear";
                else {
                    if (mark.contains(string)) return false;
                    room->setPlayerMark(p, mark, 0);
                    QString clear = "-Clear";
                    mark.chop(clear.length());
                    mark = mark + "+" + string + clear;
                }
                room->addPlayerMark(p, mark);
            }

            room->acquireOneTurnSkills(player, QString(), "tenyearzhixi");
        }
        return false;
    }
private:
    QString meibu;
};

class SecondTenyearMeibuGet : public TriggerSkill
{
public:
    SecondTenyearMeibuGet() : TriggerSkill("#secondtenyearmeibu-get")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!player->hasSkill("secondtenyearmeibu")) return false;
        QString mark;
        foreach (QString mk, player->getMarkNames()) {
            if (!mk.startsWith("&secondtenyearmeibu+") || !mk.endsWith("-Clear") || player->getMark(mk) <= 0) continue;
            mark = mk;
            break;
        }
        if (mark.isEmpty()) return false;

        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            if (move.reason.m_skillName != "tenyearzhixi") return false;
            QList<int> gets;
            foreach (int id, move.card_ids) {
                if (room->getCardPlace(id) != Player::DiscardPile) continue;
                const Card *card = Sanguosha->getCard(id);
                QString string = card->getSuitString() + "_char";
                if (!mark.contains(string)) continue;
                gets << id;
            }
            if (gets.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, "secondtenyearmeibu", true, true);
            DummyCard get(gets);
            room->obtainCard(player, &get, true);
        }
        return false;
    }
};

class TenyearMumu : public PhaseChangeSkill
{
public:
    TenyearMumu() : PhaseChangeSkill("tenyearmumu")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets, targets2;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p != player && !p->getEquips().isEmpty() && player->canDiscard(p, "e"))
                targets << p;
            if (p->getArmor())
                targets2 << p;
        }

        QStringList choices;
        if (!targets.isEmpty())
            choices << "discard";
        if (!targets2.isEmpty())
            choices << "get";
        if (choices.isEmpty()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        if (choice == "discard") {
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@tenyearmumu-dis");
            room->doAnimate(1, player->objectName(), target->objectName());
            if (!player->canDiscard(target, "e")) return false;
            int id = room->askForCardChosen(player, target, "e", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, target, player);
            room->addSlashCishu(player, 1);
        } else {
            ServerPlayer *target = room->askForPlayerChosen(player, targets2, objectName(), "@tenyearmumu-get");
            room->doAnimate(1, player->objectName(), target->objectName());
            if (!target->getArmor()) return false;
            room->obtainCard(player, target->getArmor(), true);
            room->addSlashCishu(player, -1);
        }
        return false;
    }
};

class SecondTenyearMumu : public PhaseChangeSkill
{
public:
    SecondTenyearMumu() : PhaseChangeSkill("secondtenyearmumu")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets, targets2;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p != player && !p->getEquips().isEmpty() && player->canDiscard(p, "e"))
                targets << p;
            if (!p->getEquips().isEmpty())
                targets2 << p;
        }

        QStringList choices;
        if (!targets.isEmpty())
            choices << "discard";
        if (!targets2.isEmpty())
            choices << "get";
        if (choices.isEmpty()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        if (choice == "discard") {
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@secondtenyearmumu-dis");
            room->doAnimate(1, player->objectName(), target->objectName());
            if (!player->canDiscard(target, "e")) return false;
            int id = room->askForCardChosen(player, target, "e", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, target, player);
            room->addSlashCishu(player, 1);
        } else {
            ServerPlayer *target = room->askForPlayerChosen(player, targets2, objectName(), "@secondtenyearmumu-get");
            room->doAnimate(1, player->objectName(), target->objectName());
            if (target->getEquips().isEmpty()) return false;
            int id = room->askForCardChosen(player, target, "e", objectName());
            room->obtainCard(player, id, true);
            room->addSlashCishu(player, -1);
        }
        return false;
    }
};

class TenyearZhixi : public TriggerSkill
{
public:
    TenyearZhixi() : TriggerSkill("tenyearzhixi")
    {
        events << CardUsed;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
        if (player->isKongcheng()) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->askForDiscard(player, objectName(), 1, 1);
        return false;
    }
};

YujueCard::YujueCard(QString zhihu) : zhihu(zhihu)
{
    target_fixed = true;
}

void YujueCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QStringList choices;
    for (int i = 0; i < 5; i++) {
        if (source->hasEquipArea(i))
            choices << QString::number(i);
    }
    if (choices.isEmpty()) return;

    QString choice = room->askForChoice(source, "yujue", choices.join("+"));
    source->throwEquipArea(choice.toInt());

    if (source->isDead()) return;

    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (p->isKongcheng()) continue;
        targets << p;
    }
    if (targets.isEmpty()) return;

    QString skill = "yujue";
    if (zhihu == "secondzhihu") skill = "secondyujue";
    ServerPlayer *target = room->askForPlayerChosen(source, targets, skill, "@yujue-invoke");
    room->doAnimate(1, source->objectName(), target->objectName());

    if (target->isKongcheng()) return;
    const Card *c = room->askForExchange(target, "yujue", 1, 1, false, "@yujue-give:" + source->objectName());
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), source->objectName(), "yujue", QString());
    room->obtainCard(source, c, reason, false);

    if (target->isDead() || source->isDead()) return;
    if (target->hasSkill(zhihu, true)) return;

    QStringList names = source->tag[zhihu + "_names"].toStringList();
    if (!names.contains(target->objectName())) {
        names << target->objectName();
        source->tag[zhihu + "_names"] = names;
    }
    room->acquireSkill(target, zhihu);
}

class YujueVS : public ZeroCardViewAsSkill
{
public:
    YujueVS() : ZeroCardViewAsSkill("yujue")
    {
    }

    const Card *viewAs() const
    {
        return new YujueCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->hasEquipArea() && !player->hasUsed("YujueCard");
    }
};

class Yujue : public PhaseChangeSkill
{
public:
    Yujue() : PhaseChangeSkill("yujue")
    {
        view_as_skill = new YujueVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        QStringList names = player->tag["zhihu_names"].toStringList();
        if (names.isEmpty()) return false;
        Room *room = player->getRoom();
        player->tag.remove("zhihu_names");
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!names.contains(p->objectName())) continue;
            if (!p->hasSkill("zhihu", true)) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;
        room->sortByActionOrder(targets);
        foreach (ServerPlayer *p, targets) {
            if (p->isDead() || !p->hasSkill("zhihu", true)) continue;
            room->detachSkillFromPlayer(p, "zhihu");
        }
        return false;
    }
};

SecondYujueCard::SecondYujueCard() : YujueCard("secondzhihu")
{
    target_fixed = true;
}

class SecondYujueVS : public ZeroCardViewAsSkill
{
public:
    SecondYujueVS() : ZeroCardViewAsSkill("secondyujue")
    {
    }

    const Card *viewAs() const
    {
        return new SecondYujueCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->hasEquipArea() && !player->hasUsed("SecondYujueCard");
    }
};

class SecondYujue : public PhaseChangeSkill
{
public:
    SecondYujue() : PhaseChangeSkill("secondyujue")
    {
        view_as_skill = new SecondYujueVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        QStringList names = player->tag["secondzhihu_names"].toStringList();
        if (names.isEmpty()) return false;
        Room *room = player->getRoom();
        player->tag.remove("secondzhihu_names");
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!names.contains(p->objectName())) continue;
            if (!p->hasSkill("secondzhihu", true)) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;
        room->sortByActionOrder(targets);
        foreach (ServerPlayer *p, targets) {
            if (p->isDead() || !p->hasSkill("secondzhihu", true)) continue;
            room->detachSkillFromPlayer(p, "secondzhihu");
        }
        return false;
    }
};

class Tuxing : public TriggerSkill
{
public:
    Tuxing() : TriggerSkill("tuxing")
    {
        events << ThrowEquipArea << DamageCaused;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == ThrowEquipArea) {
            if (!player->hasSkill(this)) return false;
            QVariantList areas = data.toList();
            for (int i = 0; i < areas.length(); i++) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->gainMaxHp(player);
                room->recover(player, RecoverStruct(player));
            }
            if (player->hasEquipArea()) return false;
            room->loseMaxHp(player, 4);
            room->addPlayerMark(player, "&tuxing");
        } else {
            int mark = player->getMark("&tuxing");
            if (mark <= 0) return false;
            DamageStruct damage = data.value<DamageStruct>();
            LogMessage log;
            log.type = "#TuxingDamage";
            log.from = player;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(damage.damage += mark);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(this);

            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class Zhihu : public TriggerSkill
{
public:
    Zhihu() : TriggerSkill("zhihu")
    {
        events << Damage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        if (player->getMark("zhihu-Clear") >= 2) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from == damage.to) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->addPlayerMark(player, "zhihu-Clear");
        player->drawCards(2, objectName());
        return false;
    }
};

class SecondZhihu : public TriggerSkill
{
public:
    SecondZhihu() : TriggerSkill("secondzhihu")
    {
        events << Damage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        if (player->getMark("secondzhihu-Clear") >= 3) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from == damage.to) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->addPlayerMark(player, "secondzhihu-Clear");
        player->drawCards(1, objectName());
        return false;
    }
};

SpNiluanCard::SpNiluanCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodUse;
}

bool SpNiluanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *card = Sanguosha->getCard(getSubcards().first());
    Slash *slash = new Slash(card->getSuit(), card->getNumber());
    slash->addSubcard(card);
    slash->setSkillName("spniluan");
    slash->deleteLater();
    return !Self->isLocked(slash) && slash->targetFilter(targets, to_select, Self);
}

void SpNiluanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    const Card *card = Sanguosha->getCard(getSubcards().first());
    Slash *slash = new Slash(card->getSuit(), card->getNumber());
    slash->addSubcard(card);
    slash->setSkillName("spniluan");
    room->setCardFlag(slash, "spniluan_slash");
    slash->deleteLater();
    room->useCard(CardUseStruct(slash, card_use.from, card_use.to), true);
}

class SpNiluanVS : public OneCardViewAsSkill
{
public:
    SpNiluanVS() : OneCardViewAsSkill("spniluan")
    {
        filter_pattern = ".|black";
        response_or_use = true;
    }

    const Card *viewAs(const Card *card) const
    {
        SpNiluanCard *c = new SpNiluanCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }
};

class SpNiluan : public TriggerSkill
{
public:
    SpNiluan() : TriggerSkill("spniluan")
    {
        events << DamageDone << CardFinished;
        view_as_skill = new SpNiluanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || !damage.from) return false;
            if (damage.card->getSkillName() != objectName() && !damage.card->hasFlag("spniluan_slash")) return false;
            room->setCardFlag(damage.card, "spniluan_damage");
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || use.from->isDead() || !use.m_addHistory) return false;
            if (use.card->getSkillName() != objectName() && !use.card->hasFlag("spniluan_slash")) return false;
            if (use.card->hasFlag("spniluan_damage")) return false;
            room->addPlayerHistory(use.from, "Slash", -1);
        }
        return false;
    }
};

WeiwuCard::WeiwuCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodUse;
}

bool WeiwuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *card = Sanguosha->getCard(getSubcards().first());
    Snatch *snatch = new Snatch(card->getSuit(), card->getNumber());
    snatch->addSubcard(card);
    snatch->setSkillName("weiwu");
    snatch->deleteLater();
    return !Self->isLocked(snatch) && snatch->targetFilter(targets, to_select, Self) && to_select->getHandcardNum() >= Self->getHandcardNum()
            && !Self->isProhibited(to_select, snatch);
}

void WeiwuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    const Card *card = Sanguosha->getCard(getSubcards().first());
    Snatch *snatch = new Snatch(card->getSuit(), card->getNumber());
    snatch->addSubcard(card);
    snatch->setSkillName("weiwu");
    snatch->deleteLater();
    room->useCard(CardUseStruct(snatch, card_use.from, card_use.to), true);
}

class Weiwu : public OneCardViewAsSkill
{
public:
    Weiwu() : OneCardViewAsSkill("weiwu")
    {
        filter_pattern = ".|red";
        response_or_use = true;
    }

    const Card *viewAs(const Card *card) const
    {
        WeiwuCard *c = new WeiwuCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        Snatch *snatch = new Snatch(Card::NoSuit, 0);
        snatch->setSkillName("weiwu");
        snatch->deleteLater();
        return !player->hasUsed("WeiwuCard") && !player->isLocked(snatch);
    }
};

class Gongjian : public TriggerSkill
{
public:
    Gongjian() : TriggerSkill("gongjian")
    {
        events << TargetSpecified;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        QStringList names = room->getTag("gongjian_slash_targets").toStringList();

        bool same = false;
        foreach (ServerPlayer *p, use.to) {
            if (!names.contains(p->objectName())) continue;
            same = true;
            break;
        }
        if (!same) return false;

        foreach (ServerPlayer *player, room->getAllPlayers()) {
            if (player->isDead() || !player->hasSkill(this)) continue;
            foreach (ServerPlayer *p, use.to) {
                if (player->isDead() || player->getMark("gongjian-Clear") > 0) return false;
                if (p->isDead() || !player->canDiscard(p, "he")) continue;
                player->tag["gongjianData"] = data;
                bool invoke = player->askForSkillInvoke(this, p);
                player->tag.remove("gongjianData");
                if (!invoke) continue;
                player->peiyin(this);
                room->addPlayerMark(player, "gongjian-Clear");

                int ad = Config.AIDelay;
                Config.AIDelay = 0;

                QList<Player::Place> orig_places;
                QList<int> cards;
                p->setFlags("gongjian_InTempMoving");

                for (int i = 0; i < 2; ++i) {
                    if (!player->canDiscard(p, "he")) break;
                    int id = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard, QList<int>(), i != 0);
                    if (id < 0) break;
                    Player::Place place = room->getCardPlace(id);
                    orig_places << place;
                    cards << id;
                    p->addToPile("#gongjian", id, false);
                }

                for (int i = 0; i < orig_places.length(); ++i) {
                    if (orig_places.isEmpty()) break;
                    room->moveCardTo(Sanguosha->getCard(cards.value(i)), p, orig_places.value(i), false);
                }

                p->setFlags("-gongjian_InTempMoving");
                Config.AIDelay = ad;

                if (!cards.isEmpty()) {
                    DummyCard dummy(cards);
                    room->throwCard(&dummy, p, player);
                    DummyCard *slash = new DummyCard;
                    slash->deleteLater();
                    foreach (int id, cards) {
                        if (!Sanguosha->getCard(id)->isKindOf("Slash")) continue;
                        slash->addSubcard(id);
                    }
                    if (slash->subcardsLength() <= 0) continue;
                    room->obtainCard(player, slash, true);
                }
            }
        }
        return false;
    }
};

class GongjianRecord : public TriggerSkill
{
public:
    GongjianRecord() : TriggerSkill("#gongjian-record")
    {
        events << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        QStringList names;
        foreach (ServerPlayer *p, use.to) {
            if (names.contains(p->objectName())) continue;
            names << p->objectName();
        }
        room->setTag("gongjian_slash_targets", names);
        return false;
    }
};

class Kuimang : public TriggerSkill
{
public:
    Kuimang() : TriggerSkill("kuimang")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (!player->tag["kuimang_damage_" + death.who->objectName()].toBool()) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(2, objectName());
        return false;
    }
};

class KuimangRecord : public TriggerSkill
{
public:
    KuimangRecord() : TriggerSkill("#kuimang-record")
    {
        events << PreDamageDone;
        global = true;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from) return false;
        damage.from->tag["kuimang_damage_" + damage.to->objectName()] = true;
        return false;
    }
};

class TenyearFuqi : public TriggerSkill
{
public:
    TenyearFuqi() : TriggerSkill("tenyearfuqi")
    {
        events << CardUsed;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;

        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, room->getOtherPlayers(use.from)) {
            if (use.from->distanceTo(p) != 1) continue;
            tos << p;
            use.no_respond_list << p->objectName();
        }
        if (tos.isEmpty()) return false;

        LogMessage log;
        log.type = "#FuqiNoResponse";
        log.from = use.from;
        log.arg = objectName();
        log.card_str = use.card->toString();
        log.to = tos;
        room->sendLog(log);
        room->notifySkillInvoked(use.from, objectName());
        room->broadcastSkillInvoke(objectName());

        data = QVariant::fromValue(use);
        return false;
    }
};

CixiaoCard::CixiaoCard()
{
    mute = true;
}

bool CixiaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (targets.length() > 1) return false;
    if (targets.isEmpty())
        return to_select->getMark("&cxyizi") > 0;
    return true;
}

bool CixiaoCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void CixiaoCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();

    room->broadcastSkillInvoke("cixiao");

    LogMessage log;
    log.from = card_use.from;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, card_use.from->objectName(), QString(), "cixiao", QString());
    room->moveCardTo(this, card_use.from, NULL, Player::DiscardPile, reason, true);

    thread->trigger(CardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void CixiaoCard::use(Room *, ServerPlayer *, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *first = targets.at(0);
    if (first->isDead() || first->getMark("&cxyizi") <= 0) return;
    ServerPlayer *second = targets.at(1);
    if (second->isDead()) return;

    first->loseMark("&cxyizi");
    second->gainMark("&cxyizi");
}

class CixiaoVS : public OneCardViewAsSkill
{
public:
    CixiaoVS() : OneCardViewAsSkill("cixiao")
    {
        filter_pattern = ".!";
        response_pattern = "@@cixiao";
    }

    const Card *viewAs(const Card *card) const
    {
        CixiaoCard *c = new CixiaoCard;
        c->addSubcard(card);
        return c;
    }
};

class Cixiao : public PhaseChangeSkill
{
public:
    Cixiao() : PhaseChangeSkill("cixiao")
    {
        view_as_skill = new CixiaoVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        bool yizi = false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark("&cxyizi") <= 0) continue;
            yizi = true;
            break;
        }
        if (yizi && player->canDiscard(player, "he"))
            room->askForUseCard(player, "@@cixiao", "@cixiao", -1, Card::MethodDiscard);
        else if (!yizi) {
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), "cixiao", "@cixiao-give", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            target->gainMark("&cxyizi");
        }
        return false;
    }
};

class CixiaoSkill : public TriggerSkill
{
public:
    CixiaoSkill() : TriggerSkill("#cixiao-skill")
    {
        events << MarkChanged;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    /*bool hasDingyuan(Room *room) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->hasSkill("cixiao"))
                return true;
        }
        return false;
    }*/

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        //if (!hasDingyuan(room)) return false;
        MarkStruct mark = data.value<MarkStruct>();
        if (mark.name != "&cxyizi") return false;
        if (player->getMark("&cxyizi") <= 0)
            room->detachSkillFromPlayer(player, "panshi");
        else
            room->acquireSkill(player, "panshi");
        return false;
    }
};

class Xianshuai : public TriggerSkill
{
public:
    Xianshuai() : TriggerSkill("xianshuai")
    {
        events << Damage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (room->getTag("XianshuaiFirstDamage").toInt() > 1) return false;
        DamageStruct damage = data.value<DamageStruct>();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
            p->drawCards(1, objectName());
            if (damage.from && p->isAlive() && p == damage.from && damage.to->isAlive())
                room->damage(DamageStruct("xianshuai", p, damage.to));
        }
        return false;
    }
};

class XianshuaiRecord : public TriggerSkill
{
public:
    XianshuaiRecord() : TriggerSkill("#xianshuai")
    {
        events << Damage << RoundStart;
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &) const
    {
        if (event == Damage) {
            int d = room->getTag("XianshuaiFirstDamage").toInt();
            room->setTag("XianshuaiFirstDamage", d + 1);
        } else
            room->removeTag("XianshuaiFirstDamage");
        return false;
    }
};

class Panshi : public TriggerSkill
{
public:
    Panshi() : TriggerSkill("panshi")
    {
        events << EventPhaseStart << DamageCaused << Damage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Start) return false;
            if (player->isKongcheng()) return false;
            //QList<ServerPlayer *> dingyuans = room->findPlayersBySkillName("cixiao");
            QList<ServerPlayer *> dingyuans;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->hasSkill("cixiao", true) && p != player) {
                    dingyuans << p;
                    room->setPlayerFlag(p, "dingyuan");
                }
            }
            if (dingyuans.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            try {
                while (!player->isKongcheng()) {
                    if (player->isDead()) break;
                    QList<int> cards = player->handCards();
                    ServerPlayer *dingyuan = room->askForYiji(player, cards, objectName(), false, false, false, 1,
                                            dingyuans, CardMoveReason(), "@panshi-give", false);
                    if (!dingyuan) {
                        dingyuan = dingyuans.at(qrand() % dingyuans.length());
                        const Card *card = player->getRandomHandCard();
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), dingyuan->objectName(), "panshi", QString());
                        room->obtainCard(dingyuan, card, reason, false);
                    }
                    dingyuans.removeOne(dingyuan);
                    room->setPlayerFlag(dingyuan, "-dingyuan");
                    foreach (ServerPlayer *p, dingyuans) {
                        if (!p->hasSkill("cixiao", true)) {
                            dingyuans.removeOne(p);
                            room->setPlayerFlag(p, "-dingyuan");
                        }
                    }

                    if (dingyuans.isEmpty()) break;
                }
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("dingyuan"))
                            room->setPlayerFlag(p, "-dingyuan");
                    }
                }
                throw triggerEvent;
            }

            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->hasFlag("dingyuan"))
                    room->setPlayerFlag(p, "-dingyuan");
            }
        } else {
            if (player->getPhase() != Player::Play) return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (!damage.to->hasSkill("cixiao", true)) return false;
            if (event == DamageCaused) {
                if (damage.to->isDead()) return false;
                LogMessage log;
                log.type = "#PanshiDamage";
                log.from = player;
                log.to << damage.to;
                log.arg = objectName();
                log.arg2 = QString::number(++damage.damage);
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                data = QVariant::fromValue(damage);
            } else {
                player->endPlayPhase();
            }
        }
        return false;
    }
};

JieyinghCard::JieyinghCard()
{
    mute = true;
}

bool JieyinghCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < Self->getMark("&jieyingh") && to_select->hasFlag("jieyingh_canchoose");
}

void JieyinghCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "jieyingh_extratarget");
}

class JieyinghVS : public ZeroCardViewAsSkill
{
public:
    JieyinghVS() : ZeroCardViewAsSkill("jieyingh")
    {
        response_pattern = "@@jieyingh";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        if (Self->hasFlag("jieyingh_now_use_collateral"))
            return new ExtraCollateralCard;
        else
            return new JieyinghCard;
    }
};

class Jieyingh : public TriggerSkill
{
public:
    Jieyingh() : TriggerSkill("jieyingh")
    {
        events << PreCardUsed << Damage << EventPhaseChanging;
        global = true;
        view_as_skill = new JieyinghVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damage) {
            if (player->getMark("&jieyingh") <= 0 || player->getPhase() == Player::NotActive) return false;
            LogMessage log;
            log.type = "#JieyinghEffect";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->setPlayerCardLimitation(player, "use", ".", true);
        } else if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            if (player->getMark("&jieyingh") <= 0) return false;
            room->setPlayerMark(player, "&jieyingh", 0);
        } else {
            if (player->getMark("&jieyingh") <= 0) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Nullification")) return false;
            if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
            if (player->getPhase() == Player::NotActive) return false;

            if (!use.card->isKindOf("Collateral")) {
                bool canextra = false;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (use.card->isKindOf("AOE") && p == player) continue;
                    if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                    if (use.card->targetFixed()) {
                        if (!use.card->isKindOf("Peach") || p->getLostHp() > 0) {
                            canextra = true;
                            room->setPlayerFlag(p, "jieyingh_canchoose");
                        }
                    } else {
                        if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                            canextra = true;
                            room->setPlayerFlag(p, "jieyingh_canchoose");
                        }
                    }
                }

                if (canextra == false) return false;
                player->tag["jieyinghData"] = data;
                const Card *card = room->askForUseCard(player, "@@jieyingh", "@jieyingh:" + use.card->objectName());
                player->tag.remove("jieyinghData");
                if (!card) return false;
                QList<ServerPlayer *> add;
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("jieyingh_canchoose"))
                        room->setPlayerFlag(p, "-jieyingh_canchoose");
                    if (p->hasFlag("jieyingh_extratarget")) {
                        room->setPlayerFlag(p,"-jieyingh_extratarget");
                        use.to.append(p);
                        add << p;
                    }
                }
                if (add.isEmpty()) return false;
                room->sortByActionOrder(add);
                LogMessage log;
                log.type = "#QiaoshuiAdd";
                log.from = player;
                log.to = add;
                log.card_str = use.card->toString();
                log.arg = "jieyingh";
                room->sendLog(log);
                foreach(ServerPlayer *p, add)
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
            } else {
                for (int i = 1; i <= player->getMark("&jieyingh"); i++) {
                    bool canextra = false;
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                        if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                            canextra = true;
                            break;
                        }
                    }
                    if (canextra == false) break;

                    QStringList toss;
                    QString tos;
                    foreach(ServerPlayer *t, use.to)
                        toss.append(t->objectName());
                    tos = toss.join("+");
                    room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", tos);
                    room->setPlayerFlag(player, "jieyingh_now_use_collateral");
                    room->askForUseCard(player, "@@jieyingh", "@jieyingh:" + use.card->objectName());
                    room->setPlayerFlag(player, "-jieyingh_now_use_collateral");
                    room->setPlayerProperty(player, "extra_collateral", QString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", QString());

                    foreach(ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("ExtraCollateralTarget")) {
                            room->setPlayerFlag(p,"-ExtraCollateralTarget");
                            LogMessage log;
                            log.type = "#QiaoshuiAdd";
                            log.from = player;
                            log.to << p;
                            log.card_str = use.card->toString();
                            log.arg = "jieyingh";
                            room->sendLog(log);
                            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                            use.to.append(p);
                            ServerPlayer *victim = p->tag["collateralVictim"].value<ServerPlayer *>();
                            Q_ASSERT(victim != NULL);
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
                    room->sortByActionOrder(use.to);
                    data = QVariant::fromValue(use);
                }
            }
        }
        return false;
    }
};

class JieyinghInvoke : public PhaseChangeSkill
{
public:
    JieyinghInvoke() : PhaseChangeSkill("#jieyingh-invoke")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish || !player->hasSkill("jieyingh")) return false;
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), "jieyingh", "@jieyingh-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke("jieyingh");
        room->addPlayerMark(target, "&jieyingh");
        return false;
    }
};

class JieyinghTargetMod : public TargetModSkill
{
public:
    JieyinghTargetMod() : TargetModSkill("#jieyingh-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (from->getMark("&jieyingh") > 0 && (card->isKindOf("Slash") || card->isNDTrick()) && !card->isKindOf("Nullification"))
            return 1000;
        else
            return 0;
    }
};

class Weipo : public TriggerSkill
{
public:
    Weipo() : TriggerSkill("weipo")
    {
        events << CardFinished << TargetSpecified << EventPhaseStart;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            player->tag["Weipo_Wuxiao"] = false;
        } else if (event == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
            foreach (ServerPlayer *p, use.to) {
                if (p == use.from) continue;
                if (p->isDead() || !p->hasSkill(this) || p->tag["Weipo_Wuxiao"].toBool()) continue;
                if (p->getHandcardNum() >= p->getMaxHp()) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                p->drawCards(p->getMaxHp() - p->getHandcardNum(), objectName());
                p->tag["weipo_" + use.card->toString()] = p->getHandcardNum() + 1;
            }
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                int n = p->tag["weipo_" + use.card->toString()].toInt() - 1;
                if (n >= 0) {
                    p->tag.remove("weipo_" + use.card->toString());
                    if (p->isDead() || p->getHandcardNum() >= n) continue;
                    p->tag["Weipo_Wuxiao"] = true;
                    if (use.from->isAlive() && !p->isKongcheng()) {
                        const Card *c = room->askForExchange(p, "weipo", 1, 1, false, "@weipo-give:" + use.from->objectName());
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, p->objectName(), use.from->objectName(), "weipo", QString());
                        room->obtainCard(use.from, c, reason, false);
                    }
                }
            }
        }
        return false;
    }
};

MinsiCard::MinsiCard()
{
    target_fixed = true;
}

void MinsiCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(2 * subcardsLength(), "minsi");
}

class MinsiVS : public ViewAsSkill
{
public:
    MinsiVS() : ViewAsSkill("minsi")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Self->isJilei(to_select)) return false;
        int num = 0;
        foreach (const Card *card, selected)
            num += card->getNumber();
        return num + to_select->getNumber() <= 13;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int num = 0;
        foreach (const Card *card, cards)
            num += card->getNumber();
        if (num != 13) return NULL;

        MinsiCard *c = new MinsiCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MinsiCard");
    }
};

class Minsi : public TriggerSkill
{
public:
    Minsi() : TriggerSkill("minsi")
    {
        events << CardsMoveOneTime;
        view_as_skill = new MinsiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.reason.m_skillName != objectName() || move.to != player || move.to_place != Player::PlaceHand) return false;
        QStringList minsi_black = player->property("minsi_black").toString().split("+");
        QVariantList minsi_red = player->tag["minsi_red"].toList();
        foreach (int id, move.card_ids) {
            const Card *card = Sanguosha->getCard(id);
            if (card->isRed()) {
                //room->ignoreCards(player, id); //万一之后有什么技能让红色牌视为黑色，这些牌需要计入手牌数？
                if (minsi_red.contains(id)) continue;
                minsi_red << id;
            } else if (card->isBlack()) {
                if (minsi_black.contains(QString::number(id))) continue;
                minsi_black << QString::number(id);
            }
        }
        room->setPlayerProperty(player, "minsi_black", minsi_black.join("+"));
        player->tag["minsi_red"] = minsi_red;
        return false;
    }
};

class MinsiEffect : public TriggerSkill
{
public:
    MinsiEffect() : TriggerSkill("#minsi-effect")
    {
        events << EventPhaseChanging << EventPhaseProceeding;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            player->tag.remove("minsi_red");
            room->setPlayerProperty(player, "minsi_black", QString());
        } else {
            if (player->getPhase() != Player::Discard) return false;
            QVariantList minsi_red = player->tag["minsi_red"].toList();
            if (minsi_red.isEmpty()) return false;
            room->ignoreCards(player, VariantList2IntList(minsi_red));
        }
        return false;
    }
};

class MinsiTargetMod : public TargetModSkill
{
public:
    MinsiTargetMod() : TargetModSkill("#minsi-target")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        QStringList minsi_black = from->property("minsi_black").toString().split("+");
        if ((!card->isVirtualCard() || card->subcardsLength() == 1) && minsi_black.contains(QString::number(card->getEffectiveId()))
                && card->isBlack())
            return 1000;
        else
            return 0;
    }
};

JijingCard::JijingCard()
{
    mute = true;
    will_throw = false;
    target_fixed = true;
}

void JijingCard::onUse(Room *, const CardUseStruct &) const
{
}

class JijingVS : public ViewAsSkill
{
public:
    JijingVS() : ViewAsSkill("jijing")
    {
        response_pattern = "@@jijing";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Self->isJilei(to_select)) return false;
        int judge_num = Self->property("jijing_judge").toInt();
        if (judge_num <= 0) return false;
        int num = 0;
        foreach (const Card *card, selected)
            num += card->getNumber();
        return num + to_select->getNumber() <= judge_num;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int judge_num = Self->property("jijing_judge").toInt();
        if (judge_num <= 0) return NULL;
        int num = 0;
        foreach (const Card *card, cards)
            num += card->getNumber();
        if (num != judge_num) return NULL;

        JijingCard *card = new JijingCard;
        card->addSubcards(cards);
        return card;
    }
};

class Jijing : public MasochismSkill
{
public:
    Jijing() : MasochismSkill("jijing")
    {
        view_as_skill = new JijingVS;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        if (!player->askForSkillInvoke(this)) return;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());

        JudgeStruct judge;
        judge.reason = objectName();
        judge.who = player;
        judge.pattern = ".";
        judge.play_animation = false;
        room->judge(judge);

        int number = judge.pattern.toInt();

        if (number <= 0) {
            room->recover(player, RecoverStruct(player));
            return;
        }

        room->setPlayerProperty(player, "jijing_judge", number);
        const Card *card = room->askForUseCard(player, "@@jijing", "@jijing:" + QString::number(number), -1, Card::MethodDiscard);
        room->setPlayerProperty(player, "jijing_judge", 0);
        if (!card) return;
        CardMoveReason reason(CardMoveReason::S_REASON_THROW, player->objectName(), "jijing", QString());
        room->throwCard(card, reason, player);
        room->recover(player, RecoverStruct(player));
    }
};

class JijingJudge : public TriggerSkill
{
public:
    JijingJudge() : TriggerSkill("#jijing-judge")
    {
        events << FinishJudge;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != "jijing") return false;
        judge->pattern = QString::number(judge->card->getNumber());
        return false;
    }
};

class Zhuide : public TriggerSkill
{
public:
    Zhuide() : TriggerSkill("zhuide")
    {
        events << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill(this);
    }

    int getDraw(const QString &name, Room *room) const
    {
        QList<int> ids;
        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if ((name == "slash" && card->isKindOf("Slash")) || card->objectName() == name)
                ids << id;
        }
        if (ids.isEmpty()) return -1;
        return ids.at(qrand() % ids.length());
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player)
            return false;

        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@zhuide-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());

        QStringList names;
        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (!card->isKindOf("BasicCard")) continue;
            QString name = card->objectName();
            if (card->isKindOf("Slash"))
                name = "slash";
            if (names.contains(name)) continue;
            names << name;
        }
        if (names.isEmpty()) return false;

        QList<int> draw_ids;
        foreach (QString name, names) {
            int id = getDraw(name, room);
            if (id <0) continue;
            draw_ids << id;
        }
        if (draw_ids.isEmpty()) return false;

        CardsMoveStruct move;
        move.card_ids = draw_ids;
        move.from = NULL;
        move.to = target;
        move.to_place = Player::PlaceHand;
        move.reason = CardMoveReason(CardMoveReason::S_REASON_DRAW, target->objectName(), objectName(), QString());
        room->moveCardsAtomic(move, true);

        return false;
    }
};

class Shiyuan : public TriggerSkill
{
public:
    Shiyuan() : TriggerSkill("shiyuan")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (!use.from || use.from->isDead() || use.from == player || !use.to.contains(player)) return false;
        int n = 1;
        if (room->getCurrent()->getKingdom() == "qun" && player->hasLordSkill("yuwei"))
            n++;

        int from_hp = use.from->getHp();
        int player_hp = player->getHp();
        int draw_num = 3;

        if (from_hp > player_hp) {
            if (player->getMark("shiyuan_dayu-Clear") >= n) return false;
            room->addPlayerMark(player, "shiyuan_dayu-Clear");
        } else if (from_hp == player_hp) {
            if (player->getMark("shiyuan_dengyu-Clear") >= n) return false;
            draw_num = 2;
            room->addPlayerMark(player, "shiyuan_dengyu-Clear");
        } else {
            if (player->getMark("shiyuan_xiaoyu-Clear") >= n) return false;
            draw_num = 1;
            room->addPlayerMark(player, "shiyuan_xiaoyu-Clear");
        }

        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(draw_num, objectName());
        return false;
    }
};

class SpDushi : public TriggerSkill
{
public:
    SpDushi() : TriggerSkill("spdushi")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill(this);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player)
            return false;

        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@spdushi-invoke", false, true);
        room->broadcastSkillInvoke(objectName());
        /*if (!target) {  askForPlayerChosen会自动随机选择
            if (death.damage && death.damage->from && death.damage->from->isAlive())
                target = death.damage->from;
            else
                target = room->getOtherPlayers(player).at(qrand() % room->getOtherPlayers(player).length());
        }*/
        room->handleAcquireDetachSkills(target, "spdushi");
        return false;
    }
};

class SpDushiDying : public TriggerSkill
{
public:
    SpDushiDying() : TriggerSkill("#spdushi-dying")
    {
        events << AskForPeaches << PreventPeach << AfterPreventPeach;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == AskForPeaches)
            return 7;
        return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == AskForPeaches) {
            if (player == room->getAllPlayers().first()) {
                DyingStruct dying = data.value<DyingStruct>();
                if (!dying.who->hasSkill("spdushi")) return false;
                room->sendCompulsoryTriggerLog(dying.who, "spdushi", true, true);
            }
        } else if (event == PreventPeach) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who->isAlive() && dying.who->hasSkill("spdushi") && player != dying.who) {
                player->setFlags("spdushi");
                room->addPlayerMark(player, "Global_PreventPeach");
            }
        } else {
            if (player->hasFlag("spdushi") && player->getMark("Global_PreventPeach") > 0) {
                player->setFlags("-spdushi");
                room->removePlayerMark(player, "Global_PreventPeach");
            }
        }
        return false;
    }
};

class SpDushiPro : public ProhibitSkill
{
public:
    SpDushiPro() : ProhibitSkill("#spdushi-pro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return to->hasSkill("spdushi") && card->isKindOf("Peach") && to->hasFlag("Global_Dying") && from != to;
    }
};

DaojiCard::DaojiCard()
{
    handling_method = Card::MethodDiscard;
}

bool DaojiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->getEquips().isEmpty();
}

void DaojiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->getEquips().isEmpty() || effect.from->isDead()) return;
    Room *room = effect.from->getRoom();
    int id = room->askForCardChosen(effect.from, effect.to, "e", "daoji");
    room->obtainCard(effect.from, id);

    const Card *equip = Sanguosha->getCard(id);
    if (!equip->isAvailable(effect.from)) return;

    effect.from->tag["daoji_equip"] = id + 1;
    effect.from->tag["daoji_target_" + QString::number(id + 1)] = QVariant::fromValue(effect.to);

    room->useCard(CardUseStruct(equip, effect.from, effect.from));

    effect.from->tag.remove("daoji_equip");
    effect.from->tag.remove("daoji_target_" + QString::number(id + 1));
}

class DaojiVS : public OneCardViewAsSkill
{
public:
    DaojiVS() : OneCardViewAsSkill("daoji")
    {
    }

    bool viewFilter(const Card *to_select) const
    {
        return !Self->isJilei(to_select) && !to_select->isKindOf("BasicCard");
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DaojiCard");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        DaojiCard *card = new DaojiCard;
        card->addSubcard(originalcard);
        return card;
    }
};

class Daoji : public TriggerSkill
{
public:
    Daoji() : TriggerSkill("daoji")
    {
        events << CardFinished;
        view_as_skill = new DaojiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Weapon")) return false;

        int use_id = use.card->getEffectiveId();
        int id = player->tag["daoji_equip"].toInt() - 1;
        if (id < 0 || use_id != id) return false;

        ServerPlayer *target = player->tag["daoji_target_" + QString::number(id + 1)].value<ServerPlayer *>();
        if (!target) return false;

        player->tag.remove("daoji_equip");
        player->tag.remove("daoji_target_" + QString::number(id + 1));

        if (target->isDead()) return false;
        room->damage(DamageStruct("daoji", player, target));
        return false;
    }
};

class TenyearDaoji : public TriggerSkill
{
public:
    TenyearDaoji() : TriggerSkill("tenyeardaoji")
    {
        events << CardUsed;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Weapon")) return false;
        room->addPlayerMark(player, "tenyeardaoji-Keep");
        if (player->getMark("tenyeardaoji-Keep") != 1) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this) || !p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);
            QStringList choices;
            if (room->CardInTable(use.card))
                choices << "obtain=" + use.card->objectName();
            choices << "limit=" + player->objectName();
            if (room->askForChoice(p, objectName(), choices.join("+"), data).startsWith("obtain"))
                room->obtainCard(p, use.card);
            else {
                if (player->isDead()) continue;
                room->addPlayerMark(player, "tenyeardaoji_limit-Clear");
            }
        }
        return false;
    }
};

class TenyearDaojiLimit : public CardLimitSkill
{
public:
    TenyearDaojiLimit() : CardLimitSkill("#tenyeardaoji-limit")
    {
    }

    QString limitList(const Player *target) const
    {
        if (target->getMark("tenyeardaoji_limit-Clear") > 0)
            return "use,response";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->getMark("tenyeardaoji_limit-Clear") > 0)
            return "Slash";
        else
            return QString();
    }
};

class Fuzhong : public TriggerSkill
{
public:
    Fuzhong() : TriggerSkill("fuzhong")
    {
        events << CardsMoveOneTime << DrawNCards << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            if (room->getTag("FirstRound").toBool()) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to != player || player->getPhase() != Player::NotActive || move.to_place != Player::PlaceHand) return false;
            room->sendCompulsoryTriggerLog(player, this);
            player->gainMark("&fzzhong");
        } else if (event == DrawNCards) {
            if (player->getMark("&fzzhong") < 1) return false;
            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = player;
            log.arg = "fuzhong";
            room->sendLog(log);
            room->notifySkillInvoked(player, "fuzhong");
            room->broadcastSkillInvoke("fuzhong");
            data = data.toInt() + 1;
        } else {
            if (player->getPhase() != Player::Finish) return false;
            if (player->getMark("&fzzhong") < 4) return false;
            ServerPlayer *to = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@fuzhong-damage", false, true);
            room->broadcastSkillInvoke(this);
            room->damage(DamageStruct("fuzhong", player, to));
            player->loseMark("&fzzhong", 4);
        }
        return false;
    }
};

class FuzhongMax : public MaxCardsSkill
{
public:
    FuzhongMax() : MaxCardsSkill("#fuzhong-max")
    {
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("fuzhong") && target->getMark("&fzzhong") >= 3)
            return 3;
        else
            return 0;
    }
};

class FuzhongDistance : public DistanceSkill
{
public:
    FuzhongDistance() : DistanceSkill("#fuzhong-distance")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill("fuzhong") && from->getMark("&fzzhong") >= 2)
            return -2;
        else
            return 0;
    }
};

class MobileNiluan : public PhaseChangeSkill
{
public:
    MobileNiluan() : PhaseChangeSkill("mobileniluan")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive() && target->getPhase() == Player::Finish && target->getMark("qieting") > 0;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (!p->canSlash(player, NULL, false)) continue;

            try {
                p->setFlags("MobileniluanSlash");
                const Card *slash = room->askForUseSlashTo(p, player, "@mobileniluan:" + player->objectName(), false, false, false,
                                    NULL, NULL, "mobileniluan_slash");
                if (!slash) {
                    p->setFlags("-MobileniluanSlash");
                    continue;
                }
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                    if (p->hasFlag("mobileniluan_damage_" + player->objectName()))
                        room->setPlayerFlag(p, "-mobileniluan_damage_" + player->objectName());
                }
                throw triggerEvent;
            }

            if (!p->hasFlag("mobileniluan_damage_" + player->objectName())) continue;
            if (player->isDead() || !p->canDiscard(player, "he")) continue;
            int id = room->askForCardChosen(p, player, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, player, p);
        }
        return false;
    }
};

class MobileNiluanLog : public TriggerSkill
{
public:
    MobileNiluanLog() : TriggerSkill("#mobileniluan-log")
    {
        events << ChoiceMade;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->hasFlag("MobileniluanSlash") && data.canConvert<CardUseStruct>()) {
            room->broadcastSkillInvoke("mobileniluan");
            room->notifySkillInvoked(player, "mobileniluan");

            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = "mobileniluan";
            room->sendLog(log);

            player->setFlags("-MobileniluanSlash");
        }
        return false;
    }
};

class MobileNiluanDamage : public TriggerSkill
{
public:
    MobileNiluanDamage() : TriggerSkill("#mobileniluan-damage")
    {
        events << DamageDone;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->isAlive() && damage.card && damage.card->isKindOf("Slash")) {
            if (!damage.card->hasFlag("mobileniluan_slash")) return false;
            room->setPlayerFlag(damage.from, "mobileniluan_damage_" + damage.to->objectName());
        }
        return false;
    }
};

class MobileXiaoxi : public OneCardViewAsSkill
{
public:
    MobileXiaoxi() : OneCardViewAsSkill("mobilexiaoxi")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.contains("slash") || pattern.contains("Slash");
    }

    bool viewFilter(const Card *card) const
    {
        if (!card->isBlack())
            return false;

        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            Slash *slash = new Slash(Card::SuitToBeDecided, -1);
            slash->addSubcard(card->getEffectiveId());
            slash->deleteLater();
            return slash->isAvailable(Self);
        }
        return true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Card *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard->getId());
        slash->setSkillName(objectName());
        return slash;
    }
};

PingjianDialog *PingjianDialog::getInstance()
{
    static PingjianDialog *instance;
    if (instance == NULL)
        instance = new PingjianDialog();

    return instance;
}

PingjianDialog::PingjianDialog()
{
    setObjectName("pingjian");
    setWindowTitle(Sanguosha->translate("pingjian"));
    group = new QButtonGroup(this);

    button_layout = new QVBoxLayout;
    setLayout(button_layout);
    connect(group, SIGNAL(buttonClicked(QAbstractButton *)), this, SLOT(selectSkill(QAbstractButton *)));
}

void PingjianDialog::popup()
{
    Self->tag.remove(objectName());
    foreach (QAbstractButton *button, group->buttons()) {
        button_layout->removeWidget(button);
        group->removeButton(button);
        delete button;
    }

    QStringList pingjian_skills = Self->property("pingjian_has_used_skills").toStringList();
    QStringList ava_generals;
    QStringList general_names = Sanguosha->getLimitedGeneralNames();
    foreach (QString general_name, general_names) {
        if (ava_generals.contains(general_name)) continue;
        const General *general = Sanguosha->getGeneral(general_name);
        if (!general) continue;
        foreach (const Skill *skill, general->getSkillList()) {
            if (!skill->isVisible() || skill->objectName() == "pingjian") continue;
            if (pingjian_skills.contains(skill->objectName())) continue;
            if (!skill->inherits("ViewAsSkill")) continue;

            const ViewAsSkill *vs = Sanguosha->getViewAsSkill(skill->objectName());
            if (!vs || !vs->isEnabledAtPlay(Self)) continue;

            QString translation = skill->getDescription();
            if (!translation.contains("出牌阶段限一次，") && !translation.contains("阶段技，") && !translation.contains("出牌阶段限一次。")
                    && !translation.contains("阶段技。")) continue;
            if (translation.contains("，出牌阶段限一次") || translation.contains("，阶段技") || translation.contains("（出牌阶段限一次") ||
                    translation.contains("（阶段技")) continue;
            ava_generals << general_name;
        }
    }

    QStringList generals;
    for (int i = 1; i <= 3; i++) {
        if (ava_generals.isEmpty()) break;
        QString general = ava_generals.at(qrand() % ava_generals.length());
        generals << general;
        ava_generals.removeOne(general);
    }
    if (generals.isEmpty()) return;

    foreach (QString general, generals) {
        bool has_general_button = false;

        foreach (const Skill *skill, Sanguosha->getGeneral(general)->getSkillList()) {
            if (!skill->isVisible() || skill->objectName() == "pingjian") continue;
            if (pingjian_skills.contains(skill->objectName())) continue;
            if (!skill->inherits("ViewAsSkill")) continue;

            const ViewAsSkill *vs = Sanguosha->getViewAsSkill(skill->objectName());
            if (!vs || !vs->isEnabledAtPlay(Self)) continue;

            QString translation = skill->getDescription();
            if (!translation.contains("出牌阶段限一次，") && !translation.contains("阶段技，") && !translation.contains("出牌阶段限一次。")
                    && !translation.contains("阶段技。")) continue;
            if (translation.contains("，出牌阶段限一次") || translation.contains("，阶段技") || translation.contains("（出牌阶段限一次") ||
                    translation.contains("（阶段技")) continue;

            if (!has_general_button) {
                has_general_button = true;
                QAbstractButton *button = createSkillButton(general);
                button->setEnabled(false);
                button_layout->addWidget(button);
            }

            QAbstractButton *button = createSkillButton(skill->objectName());
            button->setEnabled(true);
            button_layout->addWidget(button);
        }
    }

    exec();
}

void PingjianDialog::selectSkill(QAbstractButton *button)
{
    Self->tag[objectName()] = button->objectName();
    emit onButtonClick();
    accept();
}

QAbstractButton *PingjianDialog::createSkillButton(const QString &skill_name)
{
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (!skill) {
        const General *general = Sanguosha->getGeneral(skill_name);
        if (!general)
            return NULL;
    }

    QCommandLinkButton *button = new QCommandLinkButton(Sanguosha->translate(skill_name));
    button->setObjectName(skill_name);
    if (skill)
        button->setToolTip(skill->getDescription());

    group->addButton(button);
    return button;
}

PingjianCard::PingjianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

/*bool PingjianCard::targetFixed() const
{
    QString skill_name = Self->tag["pingjian"].toString();
    if (skill_name.isEmpty()) return false;

    const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
    if (vs_skill) {
        QList<const Card *> cards;
        foreach (int id, subcards)
            cards << Sanguosha->getCard(id);
        const Card *card = vs_skill->viewAs(cards);
        return card && card->targetFixed();
    }
    return false;
}*/

bool PingjianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QString skill_name = Self->tag["pingjian"].toString();
    if (skill_name.isEmpty()) return false;

    const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
    if (vs_skill) {
        QList<const Card *> cards;
        foreach (int id, subcards)
            cards << Sanguosha->getCard(id);
        const Card *card = vs_skill->viewAs(cards);
        return card && card->targetFilter(targets, to_select, Self);
    }
    return false;
}

bool PingjianCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    QString skill_name = Self->tag["pingjian"].toString();
    if (skill_name.isEmpty()) return false;

    const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
    if (vs_skill) {
        QList<const Card *> cards;
        foreach (int id, subcards)
            cards << Sanguosha->getCard(id);
        const Card *card = vs_skill->viewAs(cards);
        return card && card->targetsFeasible(targets, Self);
    }
    return false;
}

void PingjianCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QString skill_name = getUserString();
    if (skill_name.isEmpty()) return;

    QStringList skills = card_use.from->property("pingjian_has_used_skills").toStringList();
    skills << skill_name;
    room->setPlayerProperty(card_use.from, "pingjian_has_used_skills", skills);

    const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
    if (vs_skill) {
        QList<const Card *> cards;
        foreach (int id, subcards)
            cards << Sanguosha->getCard(id);
        const Card *card = vs_skill->viewAs(cards);
        if (card) {
            LogMessage log;
            log.from = card_use.from;
            log.type = "#InvokeSkill";
            log.arg = "pingjian";
            room->sendLog(log);
            room->notifySkillInvoked(card_use.from, "pingjian");
            room->broadcastSkillInvoke("pingjian");
            room->addPlayerHistory(card_use.from, "PingjianCard");

            if (!card->isMute())
                room->broadcastSkillInvoke(skill_name);

            room->addPlayerHistory(card_use.from, card->getClassName());

            CardUseStruct new_card_use;
            new_card_use.card = card;
            new_card_use.from = card_use.from;
            new_card_use.to = card_use.to;

            card->onUse(room, new_card_use);
        }
    }
}

class PingjianVS : public ViewAsSkill
{
public:
    PingjianVS() : ViewAsSkill("pingjian")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("PingjianCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString skill_name = Self->tag["pingjian"].toString();
        if (skill_name.isEmpty()) return false;
        const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
        if (vs_skill) return vs_skill->viewFilter(selected, to_select);
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString skill_name = Self->tag["pingjian"].toString();
        if (skill_name.isEmpty()) return NULL;
        const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
        if (vs_skill) {
            const Card *card = vs_skill->viewAs(cards);
            if (card) {
                PingjianCard *pj = new PingjianCard;
                pj->addSubcards(cards);
                pj->setUserString(skill_name);
                return pj;
            }
        }
        return NULL;
    }
};

class Pingjian : public TriggerSkill
{
public:
    Pingjian() : TriggerSkill("pingjian")
    {
        events << Damaged << EventPhaseStart;
        view_as_skill = new PingjianVS;
    }

    QDialog *getDialog() const
    {
        return PingjianDialog::getInstance();
    }

    void getpingjianskill(ServerPlayer *source, const QString &str, const QString &strr, TriggerEvent event, QVariant &data) const
    {
        Room *room = source->getRoom();
        QStringList pingjian_skills = source->property("pingjian_has_used_skills").toStringList();
        QStringList ava_generals;
        QStringList general_names = Sanguosha->getLimitedGeneralNames();
        foreach (QString general_name, general_names) {
            if (ava_generals.contains(general_name)) continue;
            const General *general = Sanguosha->getGeneral(general_name);
            foreach (const Skill *skill, general->getSkillList()) {
                if (!skill->isVisible() || skill->objectName() == "pingjian") continue;
                if (pingjian_skills.contains(skill->objectName())) continue;

                if (!skill->inherits("TriggerSkill")) continue;
                const TriggerSkill *triggerskill = Sanguosha->getTriggerSkill(skill->objectName());
                if (!triggerskill) continue;
                bool has_event = false;
                if (triggerskill->hasEvent(event))
                    has_event = true;
                else {
                    foreach (const Skill *related_sk, Sanguosha->getRelatedSkills(skill->objectName())) {
                        if (!related_sk || !related_sk->inherits("TriggerSkill")) continue;
                        const TriggerSkill *related_trigger = Sanguosha->getTriggerSkill(related_sk->objectName());
                        if (!related_trigger || !related_trigger->hasEvent(event)) continue;
                        has_event = true;
                    }
                }
                if (!has_event) continue;

                QString translation = skill->getDescription();
                if (!translation.contains(str) && !strr.isEmpty() && !translation.contains(strr)) continue;
                if (str == "结束阶段" && (translation.contains("的结束阶段") || translation.contains("结束阶段结束"))) continue;
                ava_generals << general_name;
            }
        }

        QStringList generals;
        for (int i = 1; i <= 3; i++) {
            if (ava_generals.isEmpty()) break;
            QString general = ava_generals.at(qrand() % ava_generals.length());
            generals << general;
            ava_generals.removeOne(general);
        }
        if (generals.isEmpty()) return;

        QString general = room->askForGeneral(source, generals);

        QStringList skills;
        foreach (const Skill *skill, Sanguosha->getGeneral(general)->getSkillList()) {
            if (!skill->isVisible() || skill->objectName() == "pingjian") continue;
            if (pingjian_skills.contains(skill->objectName())) continue;

            if (!skill->inherits("TriggerSkill")) continue;
            const TriggerSkill *triggerskill = Sanguosha->getTriggerSkill(skill->objectName());
            if (!triggerskill) continue;
            bool has_event = false;
            if (triggerskill->hasEvent(event))
                has_event = true;
            else {
                foreach (const Skill *related_sk, Sanguosha->getRelatedSkills(skill->objectName())) {
                    if (!related_sk || !related_sk->inherits("TriggerSkill")) continue;
                    const TriggerSkill *related_trigger = Sanguosha->getTriggerSkill(related_sk->objectName());
                    if (!related_trigger || !related_trigger->hasEvent(event)) continue;
                    has_event = true;
                }
            }
            if (!has_event) continue;

            QString translation = skill->getDescription();
            if (!translation.contains(str) && !strr.isEmpty() && !translation.contains(strr)) continue;
            if (str == "结束阶段" && (translation.contains("的结束阶段") || translation.contains("结束阶段结束"))) continue;
            skills << skill->objectName();
        }
        if (skills.isEmpty()) return;

        QString skill_name = room->askForChoice(source, "pingjian", skills.join("+"));
        pingjian_skills << skill_name;
        room->setPlayerProperty(source, "pingjian_has_used_skills", pingjian_skills);

        const TriggerSkill *triggerskill = Sanguosha->getTriggerSkill(skill_name);
        if (!triggerskill) return;
        bool has_event = false;
        if (triggerskill->getTriggerEvents().contains(event))
            has_event = true;
        else {
            foreach (const Skill *related_sk, Sanguosha->getRelatedSkills(skill_name)) {
                if (!related_sk || !related_sk->inherits("TriggerSkill")) continue;
                const TriggerSkill *related_trigger = Sanguosha->getTriggerSkill(related_sk->objectName());
                if (!related_trigger || !related_trigger->hasEvent(event)) continue;
                has_event = true;
                triggerskill = related_trigger;
                break;
            }
        }
        room->setPlayerProperty(source, "pingjian_triggerskill", skill_name);
        if (!has_event || !triggerskill->triggerable(source)) {
            room->setPlayerProperty(source, "pingjian_triggerskill", QString());
            return;
        }

        if (triggerskill->getFrequency(source) == Skill::Wake) {
            bool ok = triggerskill->canWake(event, source, data, room);
            if (!ok) {
                room->setPlayerProperty(source, "pingjian_triggerskill", QString());
                return;
            }
        }

        room->getThread()->addTriggerSkill(triggerskill);
        try {
            triggerskill->trigger(event, room, source, data);
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                room->setPlayerProperty(source, "pingjian_triggerskill", QString());
            throw triggerEvent;
        }
        room->setPlayerProperty(source, "pingjian_triggerskill", QString());
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damaged) {
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            getpingjianskill(player, "你受到伤害后", "你受到1点伤害后", event, data);
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            getpingjianskill(player, "结束阶段", "结束阶段开始", event, data);
        }
        return false;
    }
};

class Huqi : public MasochismSkill
{
public:
    Huqi() : MasochismSkill("huqi")
    {
        frequency = Compulsory;
    }

    void onDamaged(ServerPlayer *target, const DamageStruct &damage) const
    {
        if (target->getPhase() != Player::NotActive) return;
        Room *room = target->getRoom();
        room->sendCompulsoryTriggerLog(target, objectName(), true, true);
        JudgeStruct judge;
        judge.who = target;
        judge.reason = objectName();
        judge.pattern = ".|red";
        room->judge(judge);

        if (!judge.isGood()) return;
        if (!damage.from || damage.from->isDead()) return;
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("_huqi");
        slash->deleteLater();
        if (!target->canSlash(damage.from, slash, false)) return;
        room->useCard(CardUseStruct(slash, target, damage.from));
    }
};

class HuqiDistance : public DistanceSkill
{
public:
    HuqiDistance() : DistanceSkill("#huqi-distance")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill("huqi"))
            return -1;
        else
            return 0;
    }
};

ShoufuCard::ShoufuCard()
{
    target_fixed = true;
}

void ShoufuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(1, "shoufu");
    if (source->isKongcheng()) return;

    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (!p->getPile("sflu").isEmpty()) continue;
        targets << p;
    }
    if (targets.isEmpty()) return;

    if (!room->askForUseCard(source, "@@shoufu!", "@shoufu", Card::MethodNone)) {
        int id = source->getRandomHandCardId();
        targets.at(qrand() % targets.length())->addToPile("sflu", id);
    }
}

ShoufuPutCard::ShoufuPutCard()
{
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
    m_skillName = "shoufu";
}

bool ShoufuPutCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getPile("sflu").isEmpty();
}

void ShoufuPutCard::onUse(Room *, const CardUseStruct &card_use) const
{
    card_use.to.first()->addToPile("sflu", getSubcards());
}

class ShoufuVS : public ViewAsSkill
{
public:
    ShoufuVS() : ViewAsSkill("shoufu")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return false;
        else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE)
            return selected.isEmpty() && !to_select->isEquipped();
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (!cards.isEmpty()) return NULL;
            return new ShoufuCard;
        } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            if (cards.length() != 1) return NULL;
            ShoufuPutCard *c = new ShoufuPutCard;
            c->addSubcard(cards.first());
            return c;
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ShoufuCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@shoufu!";
    }
};

class Shoufu : public TriggerSkill
{
public:
    Shoufu() : TriggerSkill("shoufu")
    {
        events << CardsMoveOneTime << DamageInflicted;
        view_as_skill = new ShoufuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && !target->getPile("sflu").isEmpty();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageInflicted) {
            player->clearOnePrivatePile("sflu");
        } else {
            if (player->getPhase() != Player::Discard) return false;
            int basic = player->tag["shoufu_basic"].toInt();
            int trick = player->tag["shoufu_trick"].toInt();
            int equip = player->tag["shoufu_equip"].toInt();
            DummyCard *dummy = new DummyCard;

            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                foreach (int id, move.card_ids) {
                    const Card *card = Sanguosha->getCard(id);
                    if (card->isKindOf("BasicCard"))
                        basic++;
                    if (card->isKindOf("TrickCard"))
                        trick++;
                    if (card->isKindOf("EquipCard"))
                        equip++;
                }
                player->tag["shoufu_basic"] = basic >= 2 ? 0 : basic;
                player->tag["shoufu_trick"] = trick >= 2 ? 0 : trick;
                player->tag["shoufu_equip"] = equip >= 2 ? 0 : equip;

            }
            foreach (int id, player->getPile("sflu")) {
                const Card *card = Sanguosha->getCard(id);
                if ((card->isKindOf("BasicCard") && basic >= 2) || (card->isKindOf("TrickCard") && trick >= 2) ||
                        (card->isKindOf("EquipCard") && equip >= 2))
                    dummy->addSubcard(card);
            }
            if (dummy->subcardsLength() > 0) {
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "shoufu", QString());
                room->throwCard(dummy, reason, NULL);
            }
            delete dummy;
        }
        return false;
    }
};

class ShoufuLimit : public CardLimitSkill
{
public:
    ShoufuLimit() : CardLimitSkill("#shoufu-limit")
    {
    }

    bool hasShoufuPlayer(const Player *target) const
    {
        QList<const Player *> as = target->getAliveSiblings();
        as << target;
        foreach (const Player *p, as) {
            if (p->hasSkill("shoufu"))
                return true;
        }
        return false;
    }

    QString limitList(const Player *target) const
    {
        if (hasShoufuPlayer(target) && !target->getPile("sflu").isEmpty())
            return "use,response";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (hasShoufuPlayer(target) && !target->getPile("sflu").isEmpty()) {
            QStringList patterns;
            foreach (int id, target->getPile("sflu")) {
                const Card *card = Sanguosha->getCard(id);
                if (card->isKindOf("BasicCard") && !patterns.contains("BasicCard"))
                    patterns << "BasicCard";
                else if (card->isKindOf("TrickCard") && !patterns.contains("TrickCard"))
                    patterns << "TrickCard";
                else if (card->isKindOf("EquipCard") && !patterns.contains("EquipCard"))
                    patterns << "EquipCard";
            }
            return patterns.join(",");
        } else
            return QString();
    }
};

TenyearSongciCard::TenyearSongciCard()
{
    mute = true;
}

bool TenyearSongciCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getMark("tenyearsongci" + Self->objectName()) == 0;
}

void TenyearSongciCard::onEffect(const CardEffectStruct &effect) const
{
    int handcard_num = effect.to->getHandcardNum();
    int hp = effect.to->getHp();
    Room *room = effect.from->getRoom();
    room->setPlayerMark(effect.to, "@songci", 1);
    room->addPlayerMark(effect.to, "tenyearsongci" + effect.from->objectName());
    if (handcard_num > hp) {
        room->broadcastSkillInvoke("tenyearsongci", 2);
        room->askForDiscard(effect.to, "tenyearsongci", 2, 2, false, true);
    } else if (handcard_num <= hp) {
        room->broadcastSkillInvoke("tenyearsongci", 1);
        effect.to->drawCards(2, "tenyearsongci");
    }
}

class TenyearSongciViewAsSkill : public ZeroCardViewAsSkill
{
public:
    TenyearSongciViewAsSkill() : ZeroCardViewAsSkill("tenyearsongci")
    {
    }

    const Card *viewAs() const
    {
        return new TenyearSongciCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("tenyearsongci" + player->objectName()) == 0) return true;
        foreach(const Player *sib, player->getAliveSiblings())
            if (sib->getMark("tenyearsongci" + player->objectName()) == 0)
                return true;
        return false;
    }
};

class TenyearSongci : public TriggerSkill
{
public:
    TenyearSongci() : TriggerSkill("tenyearsongci")
    {
        events << CardUsed;
        view_as_skill = new TenyearSongciViewAsSkill;
    }


    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!data.value<CardUseStruct>().card->isKindOf("BifaCard")) return false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark("tenyearsongci" + player->objectName()) <= 0)
                return false;
        }

        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(1, objectName());
        return false;
    }
};

YoulongDialog *YoulongDialog::getInstance(const QString &object)
{
    static YoulongDialog *instance;
    if (instance == NULL || instance->objectName() != object)
        instance = new YoulongDialog(object);

    return instance;
}

YoulongDialog::YoulongDialog(const QString &object)
    : GuhuoDialog(object)
{
}

bool YoulongDialog::isButtonEnabled(const QString &button_name) const
{
    const Card *card = map[button_name];
    if (Self->getChangeSkillState("youlong") == 1 && !card->isNDTrick()) return false;
    if (Self->getChangeSkillState("youlong") == 2 && !card->isKindOf("BasicCard")) return false;
    return Self->getMark(objectName() + "_" + button_name) <= 0 && button_name != "normal_slash"
            && !Self->isCardLimited(card, Card::MethodUse) && card->isAvailable(Self);
}

YoulongCard::YoulongCard()
{
    mute = true;
}

bool YoulongCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    }

    const Card *_card = Self->tag.value("youlong").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    if (card && card->targetFixed())  //因源码bug，不得已而为之
        return targets.isEmpty() && to_select == Self && !Self->isProhibited(to_select, card, targets);
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

/*bool YoulongCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    }

    const Card *_card = Self->tag.value("youlong").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFixed();
}*/

bool YoulongCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    }

    const Card *_card = Self->tag.value("youlong").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetsFeasible(targets, Self);
}

const Card *YoulongCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    Room *room = source->getRoom();

    QString tl = user_string;
    if ((user_string.contains("slash") || user_string.contains("Slash"))
        && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList tl_list;
        if (card_use.from->getMark("youlong_slash") <= 0)
            tl_list << "slash";
        if (!Config.BanPackages.contains("maneuvering")) {
            if (card_use.from->getMark("youlong_thunder_slash") <= 0)
                tl_list << "thunder_slash";
            if (card_use.from->getMark("youlong_fire_slash") <= 0)
                tl_list << "fire_slash";
        }
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(source, "youlong_slash", tl_list.join("+"));
    }
    if (card_use.from->getMark("youlong_" + tl) > 0) return NULL;

    QStringList areas;
    for (int i = 0; i < 5; i++){
        if (source->hasEquipArea(i))
            areas << QString::number(i);
    }
    if (areas.isEmpty()) return NULL;

    if (source->getChangeSkillState("youlong") == 1) {
        room->addPlayerMark(source, "youlong_trick_lun");
        room->setChangeSkillState(source, "youlong", 2);
    } else {
        room->addPlayerMark(source, "youlong_basic_lun");
        room->setChangeSkillState(source, "youlong", 1);
    }

    QString area = room->askForChoice(source, "youlong", areas.join("+"));
    source->throwEquipArea(area.toInt());

    Card *use_card = Sanguosha->cloneCard(tl);
    use_card->setSkillName("youlong");
    use_card->deleteLater();

    room->addPlayerMark(source, "youlong_" + tl);

    //if (use_card->targetFixed())
        //card_use.to.clear();

    return use_card;
}

const Card *YoulongCard::validateInResponse(ServerPlayer *source) const
{
    Room *room = source->getRoom();
    QString tl;
    if (user_string == "peach+analeptic") {
        QStringList tl_list;
        if (source->getMark("youlong_peach") <= 0)
            tl_list << "peach";
        if (!Config.BanPackages.contains("maneuvering") && source->getMark("youlong_analeptic") <= 0)
            tl_list << "analeptic";
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(source, "youlong_saveself", tl_list.join("+"));
    } else if (user_string == "slash") {
        QStringList tl_list;
        if (source->getMark("youlong_slash") <= 0)
            tl_list << "slash";
        if (!Config.BanPackages.contains("maneuvering")) {
            if (source->getMark("youlong_thunder_slash") <= 0)
                tl_list << "thunder_slash";
            if (source->getMark("youlong_fire_slash") <= 0)
                tl_list << "fire_slash";
        }
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(source, "youlong_slash", tl_list.join("+"));
    } else
        tl = user_string;

    if (source->getMark("youlong_" + tl) > 0) return NULL;

    QStringList areas;
    for (int i = 0; i < 5; i++){
        if (source->hasEquipArea(i))
            areas << QString::number(i);
    }
    if (areas.isEmpty()) return NULL;

    if (source->getChangeSkillState("youlong") == 1) {
        room->addPlayerMark(source, "youlong_trick_lun");
        room->setChangeSkillState(source, "youlong", 2);
    } else {
        room->addPlayerMark(source, "youlong_basic_lun");
        room->setChangeSkillState(source, "youlong", 1);
    }

    QString area = room->askForChoice(source, "youlong", areas.join("+"));
    source->throwEquipArea(area.toInt());

    Card *use_card = Sanguosha->cloneCard(tl);
    use_card->setSkillName("youlong");
    use_card->deleteLater();

    room->addPlayerMark(source, "youlong_" + tl);

    return use_card;
}

class Youlong : public ZeroCardViewAsSkill
{
public:
    Youlong() : ZeroCardViewAsSkill("youlong")
    {
        change_skill = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (!player->hasEquipArea()) return false;
        return (player->getChangeSkillState(objectName()) == 1 && player->getMark("youlong_trick_lun") <= 0) ||
                (player->getChangeSkillState(objectName()) == 2 && player->getMark("youlong_basic_lun") <= 0);
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
            return false;
        if (!player->hasEquipArea()) return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;

        bool can_use = false, trick = false, basic = false;
        QStringList patterns = pattern.split("+");
        foreach (QString name, patterns) {
            name = name.toLower();
            if (player->getMark("youlong_" + name) > 0) continue;
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            can_use = true;
            if (card->isKindOf("BasicCard"))
                basic = true;
            else if (card->isNDTrick())
                trick = true;
        }
        if (!can_use) {
            patterns = pattern.split(",");
            foreach (QString name, patterns) {
                name = name.toLower();
                if (player->getMark("youlong_" + name) > 0) continue;
                Card *card = Sanguosha->cloneCard(name);
                if (!card) continue;
                card->deleteLater();
                can_use = true;
                if (card->isKindOf("BasicCard"))
                    basic = true;
                else if (card->isNDTrick())
                    trick = true;
            }
        }
        if (!can_use) return false;
        return (player->getMark("youlong_trick_lun") <= 0 && trick && player->getChangeSkillState("youlong") == 1) ||
                (player->getMark("youlong_basic_lun") <= 0 && basic && player->getChangeSkillState("youlong") == 2);
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        if (player->getMark("youlong_trick_lun") > 0) return false;
        return player->getMark("youlong_nullification") <= 0 && player->hasEquipArea() && player->getChangeSkillState("youlong") == 1;
    }

    const Card *viewAs() const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            YoulongCard *card = new YoulongCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            return card;
        }

        const Card *c = Self->tag.value("youlong").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            YoulongCard *card = new YoulongCard;
            card->setUserString(c->objectName());
            return card;
        } else
            return NULL;
        return NULL;
    }

    QDialog *getDialog() const
    {
        return YoulongDialog::getInstance("youlong");
    }
};

class Luanfeng : public TriggerSkill
{
public:
    Luanfeng() : TriggerSkill("luanfeng")
    {
        events << Dying;
        frequency = Limited;
        limit_mark = "@luanfengMark";
    }


    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("@luanfengMark") <= 0) return false;
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who->getMaxHp() < player->getMaxHp()) return false;
        if (!player->askForSkillInvoke(this, dying.who)) return false;

        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("wolongfengchu", "luanfeng");
        room->removePlayerMark(player, "@luanfengMark");

        int recover = qMin(3, dying.who->getMaxHp()) - dying.who->getHp();
        room->recover(dying.who, RecoverStruct(player, NULL, recover));
        QList<int> list;
        for (int i = 0; i < 5; i++) {
            if (!dying.who->hasEquipArea(i))
                list << i;
        }
        if (!list.isEmpty())
            dying.who->obtainEquipArea(list);
        int n = 6 - list.length() - dying.who->getHandcardNum();
        if (n > 0)
            dying.who->drawCards(n, objectName());
        if (dying.who == player) {
            foreach (QString mark, player->getMarkNames()) {
                if (mark.startsWith("youlong_") && !mark.endsWith("_lun") && player->getMark(mark) > 0)
                    room->setPlayerMark(player, mark, 0);
            }
        }
        return false;
    }
};

SecondZhanyiViewAsBasicCard::SecondZhanyiViewAsBasicCard()
{
    m_skillName = "secondzhanyi";
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool SecondZhanyiViewAsBasicCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    const Card *card = Self->tag.value("secondzhanyi").value<const Card *>();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool SecondZhanyiViewAsBasicCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *card = Self->tag.value("secondzhanyi").value<const Card *>();
    return card && card->targetFixed();
}

bool SecondZhanyiViewAsBasicCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *card = Self->tag.value("secondzhanyi").value<const Card *>();
    return card && card->targetsFeasible(targets, Self);
}

const Card *SecondZhanyiViewAsBasicCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *zhuling = card_use.from;
    Room *room = zhuling->getRoom();

    QString to_zhanyi = user_string;
    if (user_string == "slash" && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList guhuo_list;
        guhuo_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "normal_slash" << "thunder_slash" << "fire_slash";
        to_zhanyi = room->askForChoice(zhuling, "secondzhanyi_slash", guhuo_list.join("+"));
    }

    const Card *card = Sanguosha->getCard(subcards.first());
    QString user_str;
    if (to_zhanyi == "slash") {
        if (card->isKindOf("Slash"))
            user_str = card->objectName();
        else
            user_str = "slash";
    } else if (to_zhanyi == "normal_slash")
        user_str = "slash";
    else
        user_str = to_zhanyi;
    Card *use_card = Sanguosha->cloneCard(user_str, card->getSuit(), card->getNumber());
    use_card->setSkillName("secondzhanyi");
    use_card->addSubcard(subcards.first());
    use_card->deleteLater();
    return use_card;
}

const Card *SecondZhanyiViewAsBasicCard::validateInResponse(ServerPlayer *zhuling) const
{
    Room *room = zhuling->getRoom();

    QString to_zhanyi;
    if (user_string == "peach+analeptic") {
        QStringList guhuo_list;
        guhuo_list << "peach";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "analeptic";
        to_zhanyi = room->askForChoice(zhuling, "secondzhanyi_saveself", guhuo_list.join("+"));
    } else if (user_string == "slash") {
        QStringList guhuo_list;
        guhuo_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "normal_slash" << "thunder_slash" << "fire_slash";
        to_zhanyi = room->askForChoice(zhuling, "secondzhanyi_slash", guhuo_list.join("+"));
    } else
        to_zhanyi = user_string;

    const Card *card = Sanguosha->getCard(subcards.first());
    QString user_str;
    if (to_zhanyi == "slash") {
        if (card->isKindOf("Slash"))
            user_str = card->objectName();
        else
            user_str = "slash";
    } else if (to_zhanyi == "normal_slash")
        user_str = "slash";
    else
        user_str = to_zhanyi;
    Card *use_card = Sanguosha->cloneCard(user_str, card->getSuit(), card->getNumber());
    use_card->setSkillName("secondzhanyi");
    use_card->addSubcard(subcards.first());
    use_card->deleteLater();
    return use_card;
}

SecondZhanyiCard::SecondZhanyiCard()
{
    target_fixed = true;
}

void SecondZhanyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->loseHp(source);
    if (source->isAlive()) {
        const Card *c = Sanguosha->getCard(subcards.first());
        if (c->getTypeId() == Card::TypeBasic) {
            room->setPlayerMark(source, "ViewAsSkill_secondzhanyiEffect-PlayClear", 1);
            room->setPlayerMark(source, "Secondzhanyieffect-PlayClear", 1);
        } else if (c->getTypeId() == Card::TypeEquip)
            room->setPlayerMark(source, "secondzhanyiEquip-PlayClear", 1);
        else if (c->getTypeId() == Card::TypeTrick) {
            source->drawCards(3, "secondzhanyi");
            room->setPlayerMark(source, "secondzhanyiTrick-PlayClear", 1);
        }
    }
}

class SecondZhanyiVS : public OneCardViewAsSkill
{
public:
    SecondZhanyiVS() : OneCardViewAsSkill("secondzhanyi")
    {

    }

    bool isResponseOrUse() const
    {
        return Self->getMark("ViewAsSkill_secondzhanyiEffect-PlayClear") > 0;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (!player->hasUsed("SecondZhanyiCard"))
            return true;

        if (player->getMark("ViewAsSkill_secondzhanyiEffect-PlayClear") > 0)
            return true;

        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->getMark("ViewAsSkill_secondzhanyiEffect-PlayClear") == 0) return false;
        if (pattern.startsWith(".") || pattern.startsWith("@")) return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;
        for (int i = 0; i < pattern.length(); i++) {
            QChar ch = pattern[i];
            if (ch.isUpper() || ch.isDigit()) return false; // This is an extremely dirty hack!! For we need to prevent patterns like 'BasicCard'
        }
        return !(pattern == "nullification");
    }

    bool viewFilter(const Card *to_select) const
    {
        if (Self->getMark("ViewAsSkill_secondzhanyiEffect-PlayClear") > 0)
            return to_select->isKindOf("BasicCard");
        else
            return true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Self->getMark("ViewAsSkill_secondzhanyiEffect-PlayClear") == 0) {
            SecondZhanyiCard *zy = new SecondZhanyiCard;
            zy->addSubcard(originalCard);
            return zy;
        }

        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE
            || Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            SecondZhanyiViewAsBasicCard *card = new SecondZhanyiViewAsBasicCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            card->addSubcard(originalCard);
            return card;
        }

        const Card *c = Self->tag.value("secondzhanyi").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            SecondZhanyiViewAsBasicCard *card = new SecondZhanyiViewAsBasicCard;
            card->setUserString(c->objectName());
            card->addSubcard(originalCard);
            return card;
        } else
            return NULL;
    }
};

class SecondZhanyi : public TriggerSkill
{
public:
    SecondZhanyi() : TriggerSkill("secondzhanyi")
    {
        events << PreHpRecover << ConfirmDamage << PreCardUsed << PreCardResponded << TrickCardCanceling;
        view_as_skill = new SecondZhanyiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("secondzhanyi", true, false);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TrickCardCanceling) {
            CardEffectStruct effect = data.value<CardEffectStruct>();
            if (!effect.card->isKindOf("TrickCard")) return false;
            if (!effect.from || effect.from->getMark("secondzhanyiTrick-PlayClear") <= 0) return false;
            return true;
        } else if (event == PreHpRecover) {
            RecoverStruct recover = data.value<RecoverStruct>();
            if (!recover.card || !recover.card->hasFlag("secondzhanyi_effect")) return false;
            int old = recover.recover;
            ++recover.recover;
            int now = qMin(recover.recover, player->getMaxHp() - player->getHp());
            if (now <= 0)
                return true;
            if (recover.who && now > old) {
                LogMessage log;
                log.type = "#NewlonghunRecover";
                log.from = recover.who;
                log.to << player;
                log.arg = objectName();
                log.arg2 = QString::number(now);
                room->sendLog(log);
            }
            recover.recover = now;
            data = QVariant::fromValue(recover);
        } else if (event == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->hasFlag("secondzhanyi_effect") || !damage.by_user) return false;

            LogMessage log;
            log.type = "#NewlonghunDamage";
            log.from = player;
            log.to << damage.to;
            log.arg = objectName();
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        } else {
            if (player->getMark("Secondzhanyieffect-PlayClear") <= 0) return false;
            const Card *card = NULL;
            if (event == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (!card || !card->isKindOf("BasicCard")) return false;
            room->setPlayerMark(player, "Secondzhanyieffect-PlayClear", 0);
            room->setCardFlag(card, "secondzhanyi_effect");
        }
        return false;
    }
};

class SecondZhanyiEquip : public TriggerSkill
{
public:
    SecondZhanyiEquip() : TriggerSkill("#secondzhanyi-equip")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("secondzhanyiEquip-PlayClear") <= 0) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || use.to.isEmpty()) return false;
        room->sendCompulsoryTriggerLog(player, "secondzhanyi", true, true);
        foreach (ServerPlayer *p, use.to) {
            if (p->isDead() || !p->canDiscard(p, "he")) continue;
            const Card *c = room->askForDiscard(p, "secondzhanyi", 2, 2, false, true);
            if (!c || player->isDead()) continue;
            room->fillAG(c->getSubcards(), player);
            int id = room->askForAG(player, c->getSubcards(), false, "secondzhanyi");
            room->clearAG(player);
            room->obtainCard(player, id);
        }
        return false;
    }
};

class Pianchong : public DrawCardsSkill
{
public:
    Pianchong() : DrawCardsSkill("pianchong")
    {
        frequency = Frequent;
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        if (room->askForSkillInvoke(player, objectName())) {
            room->broadcastSkillInvoke("pianchong");
            QList<int> red, black;
            foreach (int id, room->getDrawPile()) {
                if (Sanguosha->getCard(id)->isBlack())
                    black << id;
                else if (Sanguosha->getCard(id)->isRed())
                    red << id;
            }
            DummyCard *dummy = new DummyCard;
            if (!red.isEmpty())
                dummy->addSubcard(red.at(qrand() % red.length()));
            if (!black.isEmpty())
                dummy->addSubcard(black.at(qrand() % black.length()));
            if (dummy->subcardsLength() > 0)
                room->obtainCard(player, dummy);
            delete dummy;
            QString choice = room->askForChoice(player, objectName(), "red+black");
            if (choice == "red")
                room->addPlayerMark(player, "&pianchong+red");
            else
                room->addPlayerMark(player, "&pianchong+black");
            return -n;
        } else
            return n;
    }
};

class PianchongEffect : public TriggerSkill
{
public:
    PianchongEffect() : TriggerSkill("#pianchong-effect")
    {
        events << CardsMoveOneTime << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() == Player::RoundStart) {
                room->setPlayerMark(player, "&pianchong+red", 0);
                room->setPlayerMark(player, "&pianchong+black", 0);
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (player != move.from) return false;
            if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)) return false;
            QList<int> red, black;
            foreach (int id, room->getDrawPile()) {
                if (Sanguosha->getCard(id)->isBlack())
                    black << id;
                else if (Sanguosha->getCard(id)->isRed())
                    red << id;
            }
            DummyCard *dummy = new DummyCard;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                    const Card *card = Sanguosha->getCard(move.card_ids.at(i));
                    if (card->isRed()) {
                        int mark = move.from->getMark("&pianchong+red");
                        for (int j = 0; j < mark; j++) {
                            if (black.isEmpty()) break;
                            int id = black.at(qrand() % black.length());
                            black.removeOne(id);
                            dummy->addSubcard(id);
                        }
                    } else if (card->isBlack()) {
                        int mark = move.from->getMark("&pianchong+black");
                        for (int j = 0; j < mark; j++) {
                            if (red.isEmpty()) break;
                            int id = red.at(qrand() % red.length());
                            red.removeOne(id);
                            dummy->addSubcard(id);
                        }
                    }
                }
            }
            if (dummy->subcardsLength() > 0)
                room->obtainCard(player, dummy);
            delete dummy;
        }
        return false;
    }
};

ZunweiCard::ZunweiCard()
{
}

bool ZunweiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QList<const Player *> all = QList<const Player *>(), al = Self->getAliveSiblings();
    foreach (const Player *p, al) {
        if (!Self->property("zunwei_draw").toBool() && p->getHandcardNum() > Self->getHandcardNum())
            all << p;
        else if (!Self->property("zunwei_equip").toBool() && p->getEquips().length() > Self->getEquips().length() && Self->hasEquipArea())
            all << p;
        else if (!Self->property("zunwei_recover").toBool() && p->getHp() > Self->getHp() && Self->getLostHp() > 0)
            all << p;
    }
    return targets.isEmpty() && all.contains(to_select);
}

void ZunweiCard::onEffect(const CardEffectStruct &effect) const
{
    QStringList choices;
    if (!effect.from->property("zunwei_draw").toBool() && effect.to->getHandcardNum() > effect.from->getHandcardNum())
        choices << "draw";
    if (!effect.from->property("zunwei_equip").toBool() && effect.to->getEquips().length() > effect.from->getEquips().length() && effect.from->hasEquipArea())
        choices << "equip";
    if (!effect.from->property("zunwei_recover").toBool() && effect.to->getHp() > effect.from->getHp() && effect.from->getLostHp() > 0)
        choices << "recover";
    if (choices.isEmpty()) return;

    Room *room = effect.from->getRoom();
    QString choice = room->askForChoice(effect.from, "zunwei", choices.join("+"), QVariant::fromValue(effect.to));
    if (choice == "draw") {
        room->setPlayerProperty(effect.from, "zunwei_draw", true);
        int num = effect.to->getHandcardNum() - effect.from->getHandcardNum();
        num = qMin(num, 5);
        effect.from->drawCards(num, "zunwei");
    } else if (choice == "recover") {
        room->setPlayerProperty(effect.from, "zunwei_recover", true);
        int recover = effect.to->getHp() - effect.from->getHp();
        recover = qMin(recover, effect.from->getMaxHp() - effect.from->getHp());
        room->recover(effect.from, RecoverStruct(effect.from, NULL, recover));
    } else {
       room->setPlayerProperty(effect.from, "zunwei_equip", true);
        QList<const Card *> equips;
        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (card->isKindOf("EquipCard") && effect.from->canUse(card))
                equips << card;
        }
        if (equips.isEmpty()) return;
        while (effect.to->getEquips().length() > effect.from->getEquips().length()) {
            if (effect.from->isDead()) break;
            if (equips.isEmpty()) break;
            const Card *equip = equips.at(qrand() % equips.length());
            equips.removeOne(equip);
            if (effect.from->canUse(equip))
                room->useCard(CardUseStruct(equip, effect.from, effect.from));
        }
    }
}

class Zunwei : public ZeroCardViewAsSkill
{
public:
    Zunwei() : ZeroCardViewAsSkill("zunwei")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->property("zunwei_draw").toBool() || (!player->property("zunwei_recover").toBool() && player->getLostHp() > 0) ||
                (!player->property("zunwei_equip").toBool() && player->hasEquipArea());
    }

    const Card *viewAs() const
    {
        ZunweiCard *card = new ZunweiCard;
        return card;
    }
};

class Juliao : public DistanceSkill
{
public:
    Juliao() : DistanceSkill("juliao")
    {
    }

    int getCorrect(const Player *, const Player *to) const
    {
        if (to->hasSkill(this)) {
            int extra = 0;
            QSet<QString> kingdom_set;
            if (to->parent()) {
                foreach(const Player *player, to->parent()->findChildren<const Player *>())
                {
                    if (player->isAlive())
                        kingdom_set << player->getKingdom();
                }
            }
            extra = kingdom_set.size();
            return qMax(0, extra - 1);
        } else
            return 0;
    }
};

class Taomie : public TriggerSkill
{
public:
    Taomie() : TriggerSkill("taomie")
    {
        events << Damage << Damaged << DamageCaused;
    }

    bool transferMark(ServerPlayer *to, Room *room) const
    {
        int n = 0;
        foreach (ServerPlayer *p, room->getOtherPlayers(to)) {
            if (to->isDead()) break;
            if (p->isAlive() && p->getMark("&taomie") > 0) {
                n++;
                int mark = p->getMark("&taomie");
                p->loseAllMarks("&taomie");
                to->gainMark("&taomie", mark);
            }
        }
        return n > 0;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (event == Damage) {
            if (damage.to->isDead() || damage.to->getMark("&taomie") > 0 || !player->askForSkillInvoke(this, damage.to)) return false;
            room->broadcastSkillInvoke(objectName());
            if (transferMark(damage.to, room)) return false;
            damage.to->gainMark("&taomie", 1);
        } else if (event == Damaged) {
            if (!damage.from || damage.from->isDead() || damage.from->getMark("&taomie") > 0 ||
                    !player->askForSkillInvoke(this, damage.from)) return false;
            room->broadcastSkillInvoke(objectName());
            if (transferMark(damage.from, room)) return false;
            damage.from->gainMark("&taomie", 1);
        } else {
            if (damage.to->isDead() || damage.to->getMark("&taomie") <= 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            QStringList choices;
            choices << "damage=" + damage.to->objectName();
            if (!damage.to->isAllNude())
                choices << "get=" + damage.to->objectName();
            choices << "all=" + damage.to->objectName();
            QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);

            /*LogMessage log;
            log.type = "#FumianFirstChoice";
            log.from = player;
            log.arg = "taomie:" + choice.split("=").first();
            room->sendLog(log);*/

            if (choice.startsWith("damage")) {
                ++damage.damage;
                data = QVariant::fromValue(damage);
            } else if (choice.startsWith("get")) {
                if (damage.to->isAllNude()) return false;
                int id = room->askForCardChosen(player, damage.to, "hej", objectName());
                room->obtainCard(player, id, false);
                if (player->isDead() || room->getCardPlace(id) != Player::PlaceHand || room->getCardOwner(id) != player) return false;
                QList<int> list;
                list << id;
                room->askForYiji(player, list, objectName());
            } else {
                damage.tips << "taomie_throwmark_" + damage.to->objectName();
                ++damage.damage;
                data = QVariant::fromValue(damage);
                if (damage.to->isAllNude()) return false;
                int id = room->askForCardChosen(player, damage.to, "hej", objectName());
                room->obtainCard(player, id, false);
                if (player->isDead() || room->getCardPlace(id) != Player::PlaceHand || room->getCardOwner(id) != player) return false;
                QList<int> list;
                list << id;
                room->askForYiji(player, list, objectName());
            }
        }
        return false;
    }
};

class TaomieMark : public TriggerSkill
{
public:
    TaomieMark() : TriggerSkill("#taomie-mark")
    {
        events << DamageComplete;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&taomie") > 0;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.tips.contains("taomie_throwmark_" + player->objectName())) return false;
        player->loseAllMarks("&taomie");
        return false;
    }
};

class Cangchu : public TriggerSkill
{
public:
    Cangchu() : TriggerSkill("cangchu")
    {
        events << GameStart << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GameStart) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&ccliang", qMin(3, room->alivePlayerCount()));
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to && move.to->isAlive() && move.to_place == Player::PlaceHand && move.to->getMark("cangchu-Clear") <= 0 &&
                    move.to->getPhase() == Player::NotActive && move.to == player && room->hasCurrent()) {
                int mark = player->getMark("&ccliang");
                if (mark >= room->alivePlayerCount()) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->addPlayerMark(player, "cangchu-Clear");
                player->gainMark("&ccliang");
            }
        }
        return false;
    }
};

class CangchuKeep : public MaxCardsSkill
{
public:
    CangchuKeep() : MaxCardsSkill("#cangchu-keep")
    {
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("cangchu"))
            return target->getMark("&ccliang");
        else
            return 0;
    }
};

class Liangying : public PhaseChangeSkill
{
public:
    Liangying() : PhaseChangeSkill("liangying")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Discard) return false;
        int mark = player->getMark("&ccliang");
        if (mark <= 0 || !player->askForSkillInvoke(objectName())) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());

        QStringList nums;
        for (int i = 1; i <= mark; i++)
            nums << QString::number(i);

        QString num = room->askForChoice(player, objectName(), nums.join("+"));
        player->drawCards(num.toInt(), objectName());
        if (player->isDead() || player->isKongcheng()) return false;

        QList<ServerPlayer *> alives = room->getAlivePlayers(), tos;
        while (!alives.isEmpty()) {
            if (player->isDead() || player->isKongcheng() || alives.isEmpty()) break;
            if (tos.length() >= num.toInt()) break;
            QList<int> hands = player->handCards();
            ServerPlayer *to = room->askForYiji(player, hands, objectName(), false, false, false, 1, alives, CardMoveReason(), "liangying-give");
            tos << to;
            alives.removeOne(to);
            room->addPlayerMark(to, "liangying-Clear");
        }

        foreach (ServerPlayer *p, room->getAllPlayers(true)) {
            if (p->getMark("liangying-Clear") > 0)
                room->setPlayerMark(p, "liangying-Clear", 0);
        }
        return false;
    }
};

class Shishou : public TriggerSkill
{
public:
    Shishou() : TriggerSkill("shishou")
    {
        events << CardUsed << Damaged << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            const Card *card = data.value<CardUseStruct>().card;
            if (!card->isKindOf("Analeptic")) return false;
            if (player->getMark("&ccliang") <= 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->loseMark("&ccliang");
        } else if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature != DamageStruct::Fire) return false;
            int lose = qMin(player->getMark("&ccliang"), damage.damage);
            if (lose <= 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->loseMark("&ccliang");
        } else {
            if (player->getPhase() != Player::Start) return false;
            if (player->getMark("&ccliang") > 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->loseHp(player);
        }
        return false;
    }
};

BazhanCard::BazhanCard(QString bazhan) : bazhan(bazhan)
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool BazhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int n = Self->getChangeSkillState(bazhan);
    if (n == 1)
        return targets.isEmpty() && to_select != Self;
    else if (n == 2)
        return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
    return false;
}

void BazhanCard::BazhanEffect(ServerPlayer *from, ServerPlayer *to) const
{
    if (from->isDead() || to->isDead()) return;
    QStringList choices;
    if (to->getLostHp() > 0)
        choices << "recover=" + to->objectName();
    choices << "reset=" + to->objectName() << "cancel";
    Room *room = from->getRoom();
    QString choice = room->askForChoice(from, "bazhan", choices.join("+"), QVariant::fromValue(to));
    if (choice == "cancel") return;
    if (choice.startsWith("recover"))
        room->recover(to, RecoverStruct(from));
    else {
        if (to->isChained())
            room->setPlayerChained(to);

        if (!to->faceUp())
            to->turnOver();
    }
}

void BazhanCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from= effect.from;
    ServerPlayer *to = effect.to;
    Room *room = from->getRoom();
    int n = from->getChangeSkillState(bazhan);
    bool caneffect = false;

    if (n == 1) {
        room->setChangeSkillState(from, bazhan, 2);
        room->giveCard(from, to, subcards, bazhan);
        foreach (int id, subcards) {
            const Card *card = Sanguosha->getCard(id);
            if (card->isKindOf("Analeptic") || card->getSuit() == Card::Heart) {
                caneffect = true;
                break;
            }
        }
        if (caneffect)
            BazhanEffect(from, to);
    } else if (n == 2) {
        room->setChangeSkillState(from, bazhan, 1);
        if (to->isKongcheng()) return;

        int num = 1;
        if (bazhan == "secondbazhan") {
            QStringList choices;
            choices << "1";
            if (to->getHandcardNum() >= 2)
                choices << "2";
            num = room->askForChoice(from, bazhan, choices.join("+"), QVariant::fromValue(to)).toInt();
        };
        QList<int> cards;
        if (bazhan == "bazhan") {
            int id = room->askForCardChosen(from, to, "h", bazhan);
            cards << id;
        } else if (bazhan == "secondbazhan") {
            to->setFlags(bazhan + "_InTempMoving");

            for (int i = 0; i < num; i++) {
                int id = room->askForCardChosen(from, to, "h", bazhan);
                cards << id;
                to->addToPile("#" + bazhan, id, false);
            }
            for (int i = 0; i < num; i++)
                room->moveCardTo(Sanguosha->getCard(cards.value(i)), to, Player::PlaceHand, false);
            to->setFlags("-" + bazhan + "_InTempMoving");
        }

        if (cards.isEmpty()) return;

        DummyCard dummy(cards);
        room->obtainCard(from, &dummy);

        foreach (int id, cards) {
            const Card *card = Sanguosha->getCard(id);
            if (card->isKindOf("Analeptic") || card->getSuit() == Card::Heart) {
                caneffect = true;
                break;
            }
        }
        if (caneffect)
            BazhanEffect(from, from);
    }
}

SecondBazhanCard::SecondBazhanCard() : BazhanCard("secondbazhan")
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

class Bazhan : public ViewAsSkill
{
public:
    Bazhan(const QString &bazhan) : ViewAsSkill(bazhan), bazhan(bazhan)
    {
        change_skill = true;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int n = Self->getChangeSkillState(bazhan);
        int num = 1;
        if (bazhan == "secondbazhan") num = 2;
        if (n == 1)
            return selected.length() < num && !to_select->isEquipped();
        return false;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (bazhan == "bazhan")
            return !player->hasUsed("BazhanCard");
        else if (bazhan == "secondbazhan")
            return !player->hasUsed("SecondBazhanCard");
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int n = Self->getChangeSkillState(bazhan);
        if (n != 1 && n != 2) return NULL;
        if (n == 2 && cards.length() != 0) return NULL;
        if (n == 1) {
            if (bazhan == "bazhan") {
                if (cards.length() != 1)
                    return NULL;
            } else if (bazhan == "secondbazhan") {
                if (cards.isEmpty() || cards.length() > 2)
                    return NULL;
            }
        }

        if (bazhan == "bazhan") {
            BazhanCard *card = new BazhanCard;
            if (n == 1)
                card->addSubcards(cards);
            return card;
        } else if (bazhan == "secondbazhan") {
            SecondBazhanCard *card = new SecondBazhanCard;
            if (n == 1)
                card->addSubcards(cards);
            return card;
        }
        return NULL;
    }
private:
    QString bazhan;
};

class Jiaoying : public TriggerSkill
{
public:
    Jiaoying(const QString &jiaoying) : TriggerSkill(jiaoying), jiaoying(jiaoying)
    {
        events << EventPhaseChanging << CardUsed << CardResponded;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            QString property = jiaoying + "_targets";
            foreach (ServerPlayer *fanyufeng, room->getAllPlayers()) {
                QStringList names = fanyufeng->property(property.toStdString().c_str()).toStringList();
                room->setPlayerProperty(fanyufeng, property.toStdString().c_str(), QStringList());
                if (fanyufeng->isDead() || !fanyufeng->hasSkill(this)) continue;

                QList<ServerPlayer *> targets;
                foreach (QString name, names) {
                    ServerPlayer *target = room->findChild<ServerPlayer *>(name);
                    if (!target || target->isDead() || targets.contains(target)) continue;
                    targets << target;
                }
                if (targets.isEmpty()) continue;
                room->sortByActionOrder(targets);

                foreach (ServerPlayer *p, targets) {
                    if (p->getMark(jiaoying + "_card-Clear") > 0) continue;
                    ServerPlayer *drawer = room->askForPlayerChosen(fanyufeng, room->getAlivePlayers(), objectName(), "@" + jiaoying  + "-invoke", false, true);
                    room->broadcastSkillInvoke(objectName());
                    int num = qMin(5, drawer->getMaxHp()) - drawer->getHandcardNum();
                    if (jiaoying == "secondjiaoying") num = 5 - drawer->getHandcardNum();
                    if (num > 0)
                        drawer->drawCards(num, objectName());
                }
            }
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                QString property = jiaoying + "_colors";
                QStringList colors = p->property(property.toStdString().c_str()).toStringList();
                room->setPlayerProperty(p, property.toStdString().c_str(), QStringList());
                if (colors.isEmpty()) continue;
                foreach (QString color, colors)
                    room->removePlayerCardLimitation(p, "use,response", ".|" + color + "|.|.$1");
            }
        } else {
            if (!room->hasCurrent()) return false;
            const Card *card = NULL;
            if (event == CardUsed)
                card = data.value<CardUseStruct>().card;
            else
                card = data.value<CardResponseStruct>().m_card;
            if (!card || card->isKindOf("SkillCard")) return false;
            if (player->getMark(jiaoying + "_effect-Clear") <= 0) return false;
            room->addPlayerMark(player, jiaoying + "_card-Clear");
        }
        return false;
    }
private:
    QString jiaoying;
};

class JiaoyingMove : public TriggerSkill
{
public:
    JiaoyingMove(const QString &jiaoying) : TriggerSkill("#" + jiaoying + "-move"), jiaoying(jiaoying)
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.to || !move.from || move.from != player || move.to == player || !move.from_places.contains(Player::PlaceHand) ||
                move.to_place != Player::PlaceHand) return false;

        room->sendCompulsoryTriggerLog(player, jiaoying, true, true);

        QString property_t = jiaoying + "_targets", property_c = jiaoying + "_colors";
        QStringList names = player->property(property_t.toStdString().c_str()).toStringList();
        if (!names.contains(move.to->objectName())) {
            names << move.to->objectName();
            room->setPlayerProperty(player, property_t.toStdString().c_str(), names);
            room->addPlayerMark((ServerPlayer *)move.to, jiaoying + "_effect-Clear");
        }

        for (int i = 0; i < move.card_ids.length(); i++) {
            const Card *card = Sanguosha->getCard(move.card_ids.at(i));
            QString color;
            if (card->isRed())
                color = "red";
            else if (card->isBlack())
                color = "black";
            else
                continue;
            QStringList colors = move.to->property(property_c.toStdString().c_str()).toStringList();
            if (colors.contains(color)) continue;
            colors << color;
            room->setPlayerProperty((ServerPlayer *)move.to, property_c.toStdString().c_str(), colors);
            room->setPlayerCardLimitation((ServerPlayer *)move.to, "use,response", ".|" + color + "|.|.", true);
        }
        return false;
    }
private:
    QString jiaoying;
};

class YangzhongVS : public ViewAsSkill
{
public:
    YangzhongVS() : ViewAsSkill("yangzhong")
    {
        response_pattern = "@@yangzhong";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() < 2 && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2)
            return NULL;

        DummyCard *card = new DummyCard;
        card->setSkillName(objectName());
        card->addSubcards(cards);
        return card;
    }
};

class Yangzhong : public TriggerSkill
{
public:
    Yangzhong() : TriggerSkill("yangzhong")
    {
        events << Damage << Damaged;
        view_as_skill = new YangzhongVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->isDead() || damage.to->isDead()) return false;
        if ((event == Damage && damage.from->hasSkill(this)) || (event == Damaged && damage.to->hasSkill(this))) {
            if (!damage.from->canDiscard(damage.from, "he") || damage.from->getCardCount() < 2) return false;
            if (!room->askForCard(damage.from, "@@yangzhong", "@yangzhong:" + damage.to->objectName(), data, objectName())) return false;
            room->broadcastSkillInvoke(objectName());
            if (damage.to->isAlive())
                room->loseHp(damage.to);
        }
        return false;
    }
};

class Huangkong : public TriggerSkill
{
public:
    Huangkong() : TriggerSkill("huangkong")
    {
        events << TargetConfirmed;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive || !player->isKongcheng()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player)) return false;
        if (use.card->isKindOf("Slash") || use.card->isNDTrick()) {
            room->sendCompulsoryTriggerLog(player, this);
            player->drawCards(2, objectName());
        }
        return false;
    }
};

LiluCard::LiluCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void LiluCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int mark = card_use.from->getMark("&lilu");
    int n = subcardsLength();
    room->setPlayerMark(card_use.from, "&lilu", n);
    room->giveCard(card_use.from, card_use.to.first(), this, "lilu");
    if (card_use.from->isAlive() && n > mark && mark > 0) {
        room->gainMaxHp(card_use.from);
        room->recover(card_use.from, RecoverStruct(card_use.from));
    }
}

class LiluVS : public ViewAsSkill
{
public:
    LiluVS() : ViewAsSkill("lilu")
    {
        response_pattern = "@@lilu!";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !to_select->isEquipped();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        LiluCard *c = new LiluCard;
        c->addSubcards(cards);
        return c;
    }
};

class Lilu : public PhaseChangeSkill
{
public:
    Lilu() : PhaseChangeSkill("lilu")
    {
        view_as_skill = new LiluVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Draw) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        int draw = qMin(player->getMaxHp(), 5) - player->getHandcardNum();
        if (draw > 0)
            player->drawCards(draw, objectName());
        if (player->isKongcheng()) return true;
        if (!room->askForUseCard(player, "@@lilu!", "@lilu", -1, Card::MethodNone)) {
            room->setPlayerMark(player, "&lilu", 1);
            ServerPlayer *to = room->getOtherPlayers(player).at(qrand() % room->getOtherPlayers(player).length());
            int id = player->getRandomHandCardId();
            room->giveCard(player, to, QList<int>() << id, objectName());
        }
        return true;
    }
};

class Yizhengc : public PhaseChangeSkill
{
public:
    Yizhengc() : PhaseChangeSkill("yizhengc")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@yizhengc-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(target, "&yizhengc+#" + player->objectName());
        return false;
    }
};

class YizhengcEffect : public TriggerSkill
{
public:
    YizhengcEffect() : TriggerSkill("#yizhengc")
    {
        events << EventPhaseStart << PreHpRecover << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int Yizhengnum(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int num = 0;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isAlive() && p->hasSkill("yizhengc") && p->getMaxHp() > player->getMaxHp() &&
                    player->getMark("&yizhengc+#" + p->objectName()) > 0) {
                room->sendCompulsoryTriggerLog(p, "yizhengc", true, true);
                room->loseMaxHp(p);
                num++;
            }
        }
        return num;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMark("&yizhengc+#" + player->objectName()) > 0)
                    room->setPlayerMark(p, "&yizhengc+#" + player->objectName(), 0);
            }
        } else if (event == PreHpRecover) {
            if (player->isDead()) return false;
            RecoverStruct recover = data.value<RecoverStruct>();
            int num = Yizhengnum(player) + qMin(recover.recover, player->getMaxHp() - player->getHp());
            num = qMin(num, player->getMaxHp() - player->getHp());
            if (num <= 0 || num == recover.recover) return false;
            recover.recover = num;
            data = QVariant::fromValue(recover);
        } else {
            if (player->isDead()) return false;
            int num = Yizhengnum(player);
            if (num <= 0) return false;
            DamageStruct damage = data.value<DamageStruct>();
            damage.damage += num;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class TenyearYixiang : public TriggerSkill
{
public:
    TenyearYixiang() : TriggerSkill("tenyearyixiang")
    {
        events << PreCardUsed << PreCardResponded << DamageCaused << CardEffected << SlashEffected << CardUsed;
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreCardUsed || triggerEvent == PreCardResponded)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->hasFlag("tenyearyixiang_first_card") && damage.to->isAlive() && damage.to->hasSkill(this)) {
                if (damage.to->getPhase() == Player::Play) return false;
                room->sendCompulsoryTriggerLog(damage.to, objectName(), true, true);
                damage.damage -= 1;
                data = QVariant::fromValue(damage);
                if (damage.damage <= 0)
                    return true;
            }
        } else if (event == CardEffected) {
            if (!player->hasSkill(this) || player->getPhase() == Player::Play) return false;
            const Card *card = data.value<CardEffectStruct>().card;
            if (card->isKindOf("Slash") || !card->isBlack() || !card->hasFlag("tenyearyixiang_second_card")) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            return true;
        } else if (event == SlashEffected) {
            if (!player->hasSkill(this) || player->getPhase() == Player::Play) return false;
            const Card *slash = data.value<SlashEffectStruct>().slash;
            if (!slash->isBlack() || !slash->hasFlag("tenyearyixiang_second_card")) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            return true;
        } else if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("DelayedTrick") || !use.card->isBlack() || !use.card->hasFlag("tenyearyixiang_second_card")) return false;
            if (!use.to.first()->hasSkill(this)) return false;
            room->sendCompulsoryTriggerLog(use.to.first(), objectName(), true, true);
            return true;
        } else {
            if (player->getPhase() != Player::Play) return false;
            const Card *card = NULL;
            if (event == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (!card || card->isKindOf("SkillCard")) return false;
            room->addPlayerMark(player, "tenyearyixiang_num-PlayClear");
            int mark = player->getMark("tenyearyixiang_num-PlayClear");
            if (mark == 1)
                room->setCardFlag(card, "tenyearyixiang_first_card");
            else if (mark == 2)
                room->setCardFlag(card, "tenyearyixiang_second_card");
        }
        return false;
    }
};

class TenyearYirang : public PhaseChangeSkill
{
public:
    TenyearYirang(const QString &tenyearyirang) : PhaseChangeSkill(tenyearyirang), tenyearyirang(tenyearyirang)
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        DummyCard *dummy = new DummyCard();
        foreach (const Card *c, player->getCards("he")) {
            if (!c->isKindOf("BasicCard"))
                dummy->addSubcard(c);
        }
        if (dummy->subcardsLength() > 0) {
            Room *room = player->getRoom();
            QList<ServerPlayer *> players;
            foreach(ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMaxHp() > player->getMaxHp() || tenyearyirang == "secondtenyearyirang")
                    players << p;
            }
            if (!players.isEmpty()) {
                ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@yirang-invoke", true, true);
                if (target) {
                    room->broadcastSkillInvoke(objectName());
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "yirang", QString());
                    room->obtainCard(target, dummy, reason, false);

                    if (target->getMaxHp() > player->getMaxHp())
                        room->gainMaxHp(player, target->getMaxHp() - player->getMaxHp());
                    else if (target->getMaxHp() < player->getMaxHp() && tenyearyirang == "tenyearyirang")
                        room->loseMaxHp(player, player->getMaxHp() - target->getMaxHp());

                    int n = qMin(dummy->subcardsLength(), player->getMaxHp() - player->getHp());
                    if (n > 0)
                        room->recover(player, RecoverStruct(player, NULL, n));
                }
            }
        }
        delete dummy;
        return false;
    }
private:
    QString tenyearyirang;
};

class NewFengpo : public TriggerSkill
{
public:
    NewFengpo() : TriggerSkill("newfengpo")
    {
        events << TargetSpecified;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (player->getMark("newfengpo-Clear") > 1) return false;
        if (use.to.length() != 1) return false;
        if (use.card->isKindOf("Slash") || use.card->isKindOf("Duel")) {
            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(objectName());

            int n = 0;
            foreach (const Card *card, use.to.first()->getHandcards()) {
                if (card->getSuit() == Card::Diamond)
                    ++n;
            }

            QString choice = room->askForChoice(player, objectName(), "drawCards+addDamage", data);
            if (choice == "drawCards") {
                if (n > 0)
                    player->drawCards(n, objectName());
            } else
                room->setTag("newfengpoaddDamage_" + use.card->toString(), n);
        }
        return false;
    }
};

class NewFengpoEffect : public TriggerSkill
{
public:
    NewFengpoEffect() : TriggerSkill("#newfengpo-effect")
    {
        events << DamageCaused << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent e, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (e == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card) return false;
            int n = room->getTag("newfengpoaddDamage_" + damage.card->toString()).toInt();
            if (n <= 0) return false;
            damage.damage += n;
            data = QVariant::fromValue(damage);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            int n = room->getTag("newfengpoaddDamage_" + use.card->toString()).toInt();
            if (n == 0) return false;
            room->removeTag("newfengpoaddDamage_" + use.card->toString());
        }
        return false;
    }
};

class NewFengpoRecord : public TriggerSkill
{
public:
    NewFengpoRecord() : TriggerSkill("#newfengpo-record")
    {
        events << PreCardUsed;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash") || use.card->isKindOf("Duel"))
            room->addPlayerMark(player, "newfengpo-Clear");
        return false;
    }
};

TianjiangCard::TianjiangCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool TianjiangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *card = Sanguosha->getCard(subcards.first());
    const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
    if (!equip) return false;
    int equip_index = static_cast<int>(equip->location());
    return targets.isEmpty() && to_select != Self && to_select->hasEquipArea(equip_index);
}

void TianjiangCard::onEffect(const CardEffectStruct &effect) const
{
    const Card *card = Sanguosha->getCard(subcards.first());
    const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
    if (!equip) return;
    int equip_index = static_cast<int>(equip->location());
    if (!effect.to->hasEquipArea(equip_index)) return;

    Room *room = effect.from->getRoom();
    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1(subcards, effect.to, Player::PlaceEquip, CardMoveReason(CardMoveReason::S_REASON_PUT, effect.from->objectName(),
                          "tianjiang", QString()));
    exchangeMove.push_back(move1);

    if (effect.to->getEquip(equip_index)) {
        CardsMoveStruct move2(effect.to->getEquip(equip_index)->getEffectiveId(), NULL, Player::DiscardPile,
            CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, effect.to->objectName()));
        exchangeMove.push_back(move2);
    }
    room->moveCardsAtomic(exchangeMove, true);

    if (!effect.from->isAlive()) return;
    QString name = card->objectName();
    if (name == "_hongduanqiang" || name == "_liecuidao" || name == "_shuibojian" || name == "_hunduwanbi" || name == "_tianleiren")
        effect.from->drawCards(2, "tianjiang");
}

class TianjiangVS : public OneCardViewAsSkill
{
public:
    TianjiangVS() :OneCardViewAsSkill("tianjiang")
    {
        filter_pattern = "EquipCard|.|.|equipped";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TianjiangCard *c = new TianjiangCard();
        c->addSubcard(originalCard);
        return c;
    }
};

class Tianjiang : public GameStartSkill
{
public:
    Tianjiang() : GameStartSkill("tianjiang")
    {
        view_as_skill = new TianjiangVS;
    }

    void onGameStart(ServerPlayer *player) const
    {
        QList<const EquipCard *> equips;
        Room *room = player->getRoom();

        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (!card->isKindOf("EquipCard")) continue;
            const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
            int equip_index = static_cast<int>(equip->location());
            if (!player->hasEquipArea(equip_index) || player->getEquip(equip_index)) continue;
            equips << equip;
        }
        if (equips.isEmpty()) return;

        QList<int> get_equips;
        const EquipCard *equip1 = equips.at(qrand() % equips.length());
        get_equips << equip1->getEffectiveId();

        int index = static_cast<int>(equip1->location());
        foreach (const EquipCard *equip, equips) {
            if (static_cast<int>(equip->location()) == index)
                equips.removeOne(equip);
        }
        if (!equips.isEmpty()) {
            const EquipCard *equip2 = equips.at(qrand() % equips.length());
            get_equips << equip2->getEffectiveId();
        }

        if (get_equips.isEmpty()) return;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), objectName(), QString());
        CardsMoveStruct move(get_equips, NULL, player, Player::DrawPile, Player::PlaceEquip, reason);
        room->moveCardsAtomic(move, true);
    }
};

ZhurenCard::ZhurenCard()
{
    target_fixed = true;
    handling_method = Card::MethodDiscard;
}

void ZhurenCard::ZhurenGetSlash(ServerPlayer *source) const
{
    Room *room = source->getRoom();
    QList<int> slashs;
    foreach (int id, room->getDrawPile()) {
        if (!Sanguosha->getCard(id)->isKindOf("Slash")) continue;
        slashs << id;
    }
    if (slashs.isEmpty()) return;
    int id = slashs.at(qrand() % slashs.length());
    room->obtainCard(source, id);
}

void ZhurenCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    const Card *card = Sanguosha->getCard(subcards.first());
    int number = card->getNumber();
    if (card->isKindOf("Lightning"))
        number = 13;
    int max_number = 85;
    if (number >= 5 && number <= 8)
        max_number = 90;
    else if (number >= 9 && number <= 12)
        max_number = 95;
    else if (number > 12)
        max_number = 100;

    int probability = qrand() % 100 + 1;
    if (probability > max_number)
        ZhurenGetSlash(source);
    else {
        QString name = "_hongduanqiang";
        if (card->isKindOf("Lightning"))
            name = "_tianleiren";
        else {
            if (card->getSuit() == Card::Club)
                name = "_shuibojian";
            else if (card->getSuit() == Card::Diamond)
                name = "_liecuidao";
            else if (card->getSuit() == Card::Spade)
                name = "_hunduwanbi";
        }

        int id = source->getDerivativeCard(name, Player::PlaceHand);
        if (id < 0)
            ZhurenGetSlash(source);
    }
}

class Zhuren : public OneCardViewAsSkill
{
public:
    Zhuren() :OneCardViewAsSkill("zhuren")
    {
        filter_pattern = ".|.|.|hand!";
        waked_skills = "_hongduanqiang,_tianleiren,_shuibojian,_liecuidao,_hunduwanbi";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ZhurenCard *c = new ZhurenCard();
        c->addSubcard(originalCard);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZhurenCard");
    }
};

class OLDuanbing : public TriggerSkill
{
public:
    OLDuanbing() : TriggerSkill("olduanbing")
    {
        events << TargetSpecified << PreCardUsed;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        if (event == PreCardUsed) {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (!player->canSlash(p, use.card, false) || player->distanceTo(p) != 1 || use.to.contains(p)) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *to = room->askForPlayerChosen(player, targets, objectName(), "@olduanbing-target", true);
            if (!to) return false;

            LogMessage log;
            log.type = "#QiaoshuiAdd";
            log.from = player;
            log.to << to;
            log.card_str = use.card->toString();
            log.arg = "olduanbing";
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            int index = qrand() % 2 + 1;
            if (player->getGeneralName().contains("heqi") || (!player->getGeneralName().contains("dingfeng") && player->getGeneral2Name().contains("heqi")))
                index = 3;
            room->broadcastSkillInvoke(objectName(), index);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), to->objectName());

            use.to << to;
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        } else {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();
            for (int i = 0; i < use.to.length(); i++) {
                if (jink_list.at(i).toInt() == 1)
                    jink_list.replace(i, QVariant(2));
            }
            player->tag["Jink_" + use.card->toString()] = QVariant::fromValue(jink_list);
        }
        return false;
    }
};

OLFenxunCard::OLFenxunCard()
{
}

void OLFenxunCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->setPlayerMark(effect.from, "fixed_distance_to_" + effect.to->objectName() + "-Clear", 1);
    QStringList targets = effect.from->tag["olfenxun_targets"].toStringList();
    if (targets.contains(effect.to->objectName())) return;
    targets << effect.to->objectName();
    effect.from->tag["olfenxun_targets"] = targets;
}

class OLFenxunVS : public ZeroCardViewAsSkill
{
public:
    OLFenxunVS() :ZeroCardViewAsSkill("olfenxun")
    {
    }

    const Card *viewAs() const
    {
        return new OLFenxunCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("OLFenxunCard");
    }
};

class OLFenxun : public TriggerSkill
{
public:
    OLFenxun() : TriggerSkill("olfenxun")
    {
        events << EventPhaseChanging;
        view_as_skill = new OLFenxunVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        QStringList targets = player->tag["olfenxun_targets"].toStringList();
        if (targets.isEmpty()) return false;
        player->tag.remove("olfenxun_targets");

        bool log = false;
        foreach (QString name, targets) {
            if (player->isDead() || !player->canDiscard(player, "he")) return false;
            if (player->getMark("olduanbing_did_damage" + name + "-Clear") > 0) continue;
            if (!log) {
                log = true;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            }
            room->askForDiscard(player, objectName(), 1, 1, false, true);
        }

        return false;
    }
};

class OLFenxunRecord : public TriggerSkill
{
public:
    OLFenxunRecord() : TriggerSkill("#olfenxun-record")
    {
        events << DamageDone;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from) return false;
        room->addPlayerMark(damage.from, "olduanbing_did_damage" + damage.to->objectName() + "-Clear");
        return false;
    }
};

class Polu : public TriggerSkill
{
public:
    Polu(const QString &polu) : TriggerSkill(polu), polu(polu)
    {
        events << EventPhaseStart << Damaged;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QString piliche = "_piliche";
        if (polu == "secondpolu")
            piliche = "_secondpiliche";

        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;

            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                foreach (const Card *c, p->getCards("ej")) {
                    const Card *card = Sanguosha->getEngineCard(c->getEffectiveId());
                    if (card->objectName() == piliche)
                        return false;
                }
            }

            if (polu == "secondpolu") {
                QList<int> list = room->getDrawPile() + room->getDiscardPile();
                foreach (int id, list) {
                    const Card *card = Sanguosha->getEngineCard(id);
                    if (card->objectName() == piliche)
                        return false;
                }
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    foreach (const Card *c, p->getCards("h")) {
                        const Card *card = Sanguosha->getEngineCard(c->getEffectiveId());
                        if (card->objectName() == piliche)
                            return false;
                    }
                }
            }

            int id = player->getDerivativeCard(piliche, Player::PlaceTable);
            if (id < 0) {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    QStringList piles = p->getPileNames();
                    piles.removeOne("wooden_ox");
                    foreach (const QString &pile, piles) {
                        foreach (int pile_id, p->getPile(pile)) {
                            const Card *card = Sanguosha->getEngineCard(pile_id);
                            if (card->objectName() == piliche) {
                                id = pile_id;
                                break;
                            }
                        }
                        if (id > 0)
                            break;
                    }
                    if (id > 0)
                        break;
                }
            }
            if (id < 0) return false;

            const Card *card = Sanguosha->getCard(id);

            if (polu == "polu") {
                if (!player->canUse(card)) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->useCard(CardUseStruct(card, player, player));
            } else {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                bool in_table = room->getCardPlace(id) == Player::PlaceTable;
                CardMoveReason reason(CardMoveReason::S_REASON_EXCLUSIVE, player->objectName());
                room->obtainCard(player, card, in_table ? reason : CardMoveReason(), false);
                if (player->isDead() || !player->canUse(card)) return false;
                room->useCard(CardUseStruct(card, player, player));
            }
        } else {
            if (player->getWeapon() && player->getWeapon()->objectName() == piliche) return false;
            int damage = data.value<DamageStruct>().damage;
            for (int i = 0; i < damage; i++) {
                if (player->isDead() || !player->hasSkill(this)) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                player->drawCards(1, objectName());
                if (player->isDead()) return false;

                if (polu == "secondpolu") {
                    QList<const Card *> weapons;
                    foreach (int id, room->getDrawPile()) {
                        const Card *card = Sanguosha->getCard(id);
                        if (!card->isKindOf("Weapon")) continue;
                        weapons << card;
                    }
                    if (weapons.isEmpty()) continue;
                    const Card *weapon = weapons.at(qrand() % weapons.length());
                    room->obtainCard(player, weapon, true);
                    if (player->isDead()) return false;
                    if (player->canUse(weapon))
                        room->useCard(CardUseStruct(weapon, player, player));
                }
            }
        }
        return false;
    }

private:
    QString polu;
};

class ChoulveVS : public ZeroCardViewAsSkill
{
public:
    ChoulveVS() :ZeroCardViewAsSkill("choulve")
    {
        response_pattern = "@@choulve!";
    }

    const Card *viewAs() const
    {
        QString name = Self->property("choulve_damage_card").toString();
        if (name.isEmpty()) return NULL;
        Card *use_card = Sanguosha->cloneCard(name);
        if (!use_card) return NULL;
        use_card->setSkillName("_choulve");
        return use_card;
    }
};

class Choulve : public PhaseChangeSkill
{
public:
    Choulve() : PhaseChangeSkill("choulve")
    {
        view_as_skill = new ChoulveVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isNude())
                tos << p;
        }
        if (tos.isEmpty()) return false;
        ServerPlayer *to = room->askForPlayerChosen(player, tos, objectName(), "@choulve-invoke", true, true);
        if (!to) return false;
        room->broadcastSkillInvoke(objectName());
        const Card *card = room->askForExchange(to, objectName(), 1, 1, true, "@choulve-give:" + player->objectName(), true);
        if (!card) return false;
        room->giveCard(to, player, card, objectName());
        delete card;

        QString name = player->property("choulve_damage_card").toString();
        if (name.isEmpty()) return false;

        Card *use_card = Sanguosha->cloneCard(name);
        if (!use_card) return false;
        use_card->setSkillName("_choulve");
        use_card->deleteLater();
        if (!player->canUse(use_card)) return false;

        if (use_card->targetFixed())
            room->useCard(CardUseStruct(use_card, player, player), true);
        else {
            if (room->askForUseCard(player, "@@choulve!", "@choulve:" + name)) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (player->canUse(use_card, p))
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = targets.at(qrand() % targets.length());
            room->useCard(CardUseStruct(use_card, player, target), true);
        }
        return false;
    }
};

class ChoulveRecord : public TriggerSkill
{
public:
    ChoulveRecord() : TriggerSkill("#choulve-record")
    {
        events << DamageDone;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || damage.card->isKindOf("SkillCard")) return false;
        QString name = damage.card->objectName();
        if (!damage.card->isKindOf("DelayedTrick")) {
            room->setPlayerProperty(damage.to, "choulve_damage_card", name);

            foreach (QString mark, damage.to->getMarkNames()) {
                if (mark.startsWith("&choulve+") && damage.to->getMark(mark) > 0)
                    room->setPlayerMark(damage.to, mark, 0);
            }

            if (damage.to->hasSkill("choulve", true))
                room->setPlayerMark(damage.to, "&choulve+" + name, 1);
        }

        QList<ServerPlayer *> players;
        players << damage.to;
        if (damage.from && damage.from->isAlive())
            players << damage.from;
        room->sortByActionOrder(players);

        foreach (ServerPlayer *p, players) {
            room->setPlayerProperty(p, "yhduwei_damage_card", name);

            foreach (QString mark, p->getMarkNames()) {
                if (mark.startsWith("&yhduwei+") && p->getMark(mark) > 0)
                    room->setPlayerMark(p, mark, 0);
            }

            if (p->hasSkill("yhduwei", true))
                room->setPlayerMark(p, "&yhduwei+" + name, 1);
        }
        return false;
    }
};

class Weiyi : public MasochismSkill
{
public:
    Weiyi() : MasochismSkill("weiyi")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return;
            if (!p->isAlive() || !p->hasSkill(this)) continue;
            QStringList targets = p->property("weiyi_targets").toStringList();
            if (targets.contains(player->objectName())) continue;

            QStringList choices;
            if (player->getHp() >= p->getHp())
                choices << "losehp=" + player->objectName();
            if (player->getHp() <= p->getHp() && player->isWounded())
                choices << "recover=" + player->objectName();
            if (choices.isEmpty()) continue;
            choices << "cancel";
            QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(player));
            if (choice == "cancel") continue;

            targets << player->objectName();
            room->setPlayerProperty(p, "weiyi_targets", targets);
            if (choice.startsWith("losehp")) {
                room->broadcastSkillInvoke(objectName(), 1);
                room->loseHp(player);
            } else {
                room->broadcastSkillInvoke(objectName(), 2);
                room->recover(player, RecoverStruct(p));
            }

        }
    }
};

JinzhiCard::JinzhiCard(QString skill_name): skill_name(skill_name)
{
    handling_method = Card::MethodDiscard;
}

bool JinzhiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        if (card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets)) {
            if (!card->isKindOf("Slash"))
                return true;
            else {
                if (Self->hasFlag("slashNoDistanceLimit"))
                    return true;

                int distance_fix = 0;
                if (Self->getWeapon() && subcards.contains(Self->getWeapon()->getId())) {
                    const Weapon *weapon = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
                    distance_fix += weapon->getRange() - Self->getAttackRange(false);
                }
                if (Self->getOffensiveHorse() && subcards.contains(Self->getOffensiveHorse()->getId()))
                    distance_fix += 1;
                return Self->canSlash(to_select, true, distance_fix);
            }
        }
    }

    const Card *_card = Self->tag.value(skill_name).value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    if (card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets)) {
        if (!card->isKindOf("Slash"))
            return true;
        else {
            if (Self->hasFlag("slashNoDistanceLimit"))
                return true;

            int distance_fix = 0;
            if (Self->getWeapon() && subcards.contains(Self->getWeapon()->getId())) {
                const Weapon *weapon = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
                distance_fix += weapon->getRange() - Self->getAttackRange(false);
            }
            if (Self->getOffensiveHorse() && subcards.contains(Self->getOffensiveHorse()->getId()))
                distance_fix += 1;
            return Self->canSlash(to_select, true, distance_fix);
        }
    }
    return false;
}

bool JinzhiCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    }

    const Card *_card = Self->tag.value(skill_name).value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFixed();
}

bool JinzhiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    }

    const Card *_card = Self->tag.value(skill_name).value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetsFeasible(targets, Self);
}

const Card *JinzhiCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    Room *room = source->getRoom();

    QString tl = user_string;
    if ((user_string.contains("slash") || user_string.contains("Slash"))
        && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList tl_list;
        tl_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            tl_list << "thunder_slash" << "fire_slash";
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(source, skill_name + "_slash", tl_list.join("+"));
    }

    room->addPlayerMark(source, "&" + skill_name + "_lun");

    LogMessage log;
    log.from = source;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    room->broadcastSkillInvoke(skill_name);

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, source->objectName(), QString(), "jinzhi", QString());
    QList<CardsMoveStruct> moves;
    foreach (int id, subcards) {
        CardsMoveStruct move(id, NULL, Player::DiscardPile, reason);
        moves.append(move);
    }
    room->moveCardsAtomic(moves, true);

    source->drawCards(1, skill_name);

    bool same = true;
    const Card *first = Sanguosha->getCard(subcards.first());
    foreach (int id, subcards) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->sameColorWith(first)) {
            same = false;
            break;
        }
    }

    if (!same) return NULL;

    Card *use_card = Sanguosha->cloneCard(tl);
    use_card->setSkillName("_" + skill_name);
    use_card->deleteLater();

    return use_card;
}

const Card *JinzhiCard::validateInResponse(ServerPlayer *source) const
{
    Room *room = source->getRoom();
    QString tl;
    if (user_string == "peach+analeptic") {
        QStringList tl_list;
        tl_list << "peach";
        if (!Config.BanPackages.contains("maneuvering"))
            tl_list << "analeptic";
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(source, skill_name + "_saveself", tl_list.join("+"));
    } else if (user_string == "slash") {
        QStringList tl_list;
        tl_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            tl_list << "thunder_slash" << "fire_slash";
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(source, skill_name + "_slash", tl_list.join("+"));
    } else
        tl = user_string;

    room->addPlayerMark(source, "&" + skill_name + "_lun");

    LogMessage log;
    log.from = source;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    room->broadcastSkillInvoke(skill_name);

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, source->objectName(), QString(), "jinzhi", QString());
    QList<CardsMoveStruct> moves;
    foreach (int id, subcards) {
        CardsMoveStruct move(id, NULL, Player::DiscardPile, reason);
        moves.append(move);
    }
    room->moveCardsAtomic(moves, true);

    source->drawCards(1, skill_name);

    bool same = true;
    const Card *first = Sanguosha->getCard(subcards.first());
    foreach (int id, subcards) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->sameColorWith(first)) {
            same = false;
            break;
        }
    }

    if (!same) return NULL;

    Card *use_card = Sanguosha->cloneCard(tl);
    use_card->setSkillName("_" + skill_name);
    use_card->deleteLater();

    return use_card;
}

class Jinzhi : public ViewAsSkill
{
public:
    Jinzhi(const QString &skill_name) : ViewAsSkill(skill_name), skill_name(skill_name)
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he");
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;

        bool basic = false;
        QStringList patterns = pattern.split("+");
        foreach (QString name, patterns) {
            name = name.toLower();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            if (card->isKindOf("BasicCard")) {
                basic = true;
                break;
            }
        }
        if (!basic) {
            patterns = pattern.split(",");
            foreach (QString name, patterns) {
                name = name.toLower();
                Card *card = Sanguosha->cloneCard(name);
                if (!card) continue;
                card->deleteLater();
                if (card->isKindOf("BasicCard")) {
                    basic = true;
                    break;
                }
            }
        }
        if (!basic) return false;
        return player->canDiscard(player, "he");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int mark = Self->getMark("&" + skill_name + "_lun") + 1;
        if (!Self->isJilei(to_select) && selected.length() < mark) {
            if (skill_name == "jinzhi")
                return true;
            else if (skill_name == "secondjinzhi") {
                if (selected.isEmpty())
                    return true;
                else {
                    return to_select->sameColorWith(selected.first());
                }
            }
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int mark = Self->getMark("&" + skill_name + "_lun") + 1;
        if (cards.length() != mark) return NULL;

        SkillCard *card = NULL;
        if (skill_name == "jinzhi")
            card = new JinzhiCard;
        else if (skill_name == "secondjinzhi")
            card = new SecondJinzhiCard;
        if (!card) return NULL;

        card->addSubcards(cards);

        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE ||
                Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
            card->setUserString(Sanguosha->getCurrentCardUsePattern());

            return card;
        }

        const Card *c = Self->tag.value(skill_name).value<const Card *>();
        if (c && c->isAvailable(Self)) {
            card->setUserString(c->objectName());
            return card;
        } else
            return NULL;
        return NULL;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance(skill_name, true, false);
    }

private:
    QString skill_name;
};

SecondJinzhiCard::SecondJinzhiCard() : JinzhiCard("secondjinzhi")
{
    handling_method = Card::MethodDiscard;
}

XingzuoCard::XingzuoCard()
{
    target_fixed = true;
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
}

void XingzuoCard::onUse(Room *, const CardUseStruct &) const
{
}

class XingzuoVS : public ViewAsSkill
{
public:
    XingzuoVS() : ViewAsSkill("xingzuo")
    {
        expand_pile = "#xingzuo";
        response_pattern = "@@xingzuo";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() < 2 * Self->getPile("#xingzuo").length())
            return !to_select->isEquipped();

        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        int hand = 0;
        int pile = 0;
        foreach (const Card *card, cards) {
            if (Self->getHandcards().contains(card))
                hand++;
            else if (Self->getPile("#xingzuo").contains(card->getEffectiveId()))
                pile++;
        }

        if (hand == pile && hand > 0) {
            XingzuoCard *c = new XingzuoCard;
            c->addSubcards(cards);
            return c;
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }
};

class Xingzuo : public PhaseChangeSkill
{
public:
    Xingzuo() : PhaseChangeSkill("xingzuo")
    {
        view_as_skill = new XingzuoVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());

        QList<int> views = room->getNCards(3, false, false);
        room->returnToEndDrawPile(views);

        LogMessage log;
        log.type = "$ViewEndDrawPile";
        log.from = player;
        log.arg = QString::number(3);
        log.card_str = IntList2StringList(views).join("+");
        room->sendLog(log, player);

        room->fillAG(views, player);
        if (player->isKongcheng()) {
            room->askForAG(player, views, true, objectName());
            room->clearAG(player);
            return false;
        }
        room->notifyMoveToPile(player, views, objectName(), Player::DrawPile, true);
        const Card *card = room->askForUseCard(player, "@@xingzuo", "@xingzuo", -1, Card::MethodNone);
        room->notifyMoveToPile(player, views, objectName(), Player::DrawPile, false);
        room->clearAG(player);
        if (!card) return false;

        room->addPlayerMark(player, "xingzuo-Clear");
        QList<int> get, hand;
        foreach (int id, card->getSubcards()) {
            if (views.contains(id))
                get << id;
            else
                hand << id;
        }

        if (!hand.isEmpty())
            room->moveCardsToEndOfDrawpile(player, hand, objectName(), false, true);
        if (!get.isEmpty() && player->isAlive()) {
            DummyCard gett(get);
            room->obtainCard(player, &gett, false);
        };
        return false;
    }
};

class XingzuoFinish : public PhaseChangeSkill
{
public:
    XingzuoFinish() : PhaseChangeSkill("#xingzuo-finish")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("xingzuo-Clear") > 0 && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        int mark = player->getMark("xingzuo-Clear");
        Room *room = player->getRoom();
        for (int i = 0; i < mark; i++) {
            if (player->isDead()) return false;

            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isKongcheng()) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;

            ServerPlayer *target = room->askForPlayerChosen(player, targets, "xingzuo", "@xingzuo-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke("xingzuo");

            QList<int> hands, handcards = target->handCards();
            int n = target->getHandcardNum();
            for (int i = 0; i < n; i++) {
                if (handcards.isEmpty()) break;
                int id = handcards.at(qrand() % handcards.length());
                handcards.removeOne(id);
                hands << id;
            }

            if (hands.isEmpty()) continue;

            QList<int> gets = room->getNCards(3, false, false);
            room->returnToEndDrawPile(gets);
            room->moveCardsToEndOfDrawpile(target, hands, "xingzuo");
            if (target->isAlive()) {
                DummyCard gett(gets);
                room->obtainCard(target, &gett, false);
            }
            if (hands.length() > 3 && player->isAlive())
                room->loseHp(player);
        }
        return false;
    }
};

MiaoxianCard::MiaoxianCard()
{
    handling_method = Card::MethodUse;
}

bool MiaoxianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    }

    const Card *_card = Self->tag.value("miaoxian").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool MiaoxianCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    }

    const Card *_card = Self->tag.value("miaoxian").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFixed();
}

bool MiaoxianCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    }

    const Card *_card = Self->tag.value("miaoxian").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetsFeasible(targets, Self);
}

const Card *MiaoxianCard::validate(CardUseStruct &card_use) const
{
    card_use.from->getRoom()->addPlayerMark(card_use.from, "miaoxian-Clear");
    Card *use_card = Sanguosha->cloneCard(user_string);
    use_card->setSkillName("miaoxian");
    use_card->addSubcards(subcards);
    use_card->deleteLater();

    return use_card;
}

const Card *MiaoxianCard::validateInResponse(ServerPlayer *source) const
{
    source->getRoom()->addPlayerMark(source, "miaoxian-Clear");
    Card *use_card = Sanguosha->cloneCard(user_string);
    use_card->setSkillName("miaoxian");
    use_card->addSubcards(subcards);
    use_card->deleteLater();

    return use_card;
}

class MiaoxianVS : public OneCardViewAsSkill
{
public:
    MiaoxianVS() : OneCardViewAsSkill("miaoxian")
    {
        filter_pattern = ".|black|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("miaoxian-Clear") > 0) return false;
        bool current = false;
        QList<const Player *> players = player->getAliveSiblings();
        players.append(player);
        foreach (const Player *p, players) {
            if (p->getPhase() != Player::NotActive) {
                current = true;
                break;
            }
        }
        if (!current) return false;
        int black = 0;
        foreach (const Card *card, player->getHandcards()) {
            if (card->isBlack())
                black++;
            if (black > 1)
                break;
        }
        return black == 1;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->getMark("miaoxian-Clear") > 0 || pattern != "nullification") return false;
        bool current = false;
        QList<const Player *> players = player->getAliveSiblings();
        players.append(player);
        foreach (const Player *p, players) {
            if (p->getPhase() != Player::NotActive) {
                current = true;
                break;
            }
        }
        if (!current) return false;
        int black = 0;
        foreach (const Card *card, player->getHandcards()) {
            if (card->isBlack())
                black++;
            if (black > 1)
                break;
        }
        return black == 1;
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        if (player->getMark("miaoxian-Clear") > 0) return false;
        ServerPlayer *current = player->getRoom()->getCurrent();
        if (!current || current->isDead() || current->getPhase() == Player::NotActive) return false;
        int black = 0;
        foreach (const Card *card, player->getHandcards()) {
            if (card->isBlack())
                black++;
            if (black > 1)
                break;
        }
        return black == 1;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            MiaoxianCard *card = new MiaoxianCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            card->addSubcard(originalCard);
            return card;
        }

        const Card *c = Self->tag.value("miaoxian").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            MiaoxianCard *card = new MiaoxianCard;
            card->setUserString(c->objectName());
            card->addSubcard(originalCard);
            return card;
        } else
            return NULL;
        return NULL;
    }
};

class Miaoxian : public TriggerSkill
{
public:
    Miaoxian() : TriggerSkill("miaoxian")
    {
        events << CardUsed << CardResponded;
        view_as_skill = new MiaoxianVS;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("miaoxian", false);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == CardUsed)
            card = data.value<CardUseStruct>().card;
        else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse) return false;
            card = res.m_card;
        }
        if (!card || card->isKindOf("SkillCard") || !card->isRed()) return false;

        bool red = false;
        foreach (const Card *c, player->getHandcards()) {
            if (!c->isRed()) continue;
            red = true;
            break;
        }
        if (red) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(1, objectName());
        return false;
    }
};

class Wangong : public TriggerSkill
{
public:
    Wangong() : TriggerSkill("wangong")
    {
        events << PreCardUsed << ConfirmDamage << EventAcquireSkill;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card->hasFlag("wangong_ConfirmDamage")) return false;
            LogMessage log;
            log.type = "#WangongDamage";
            log.from = player;
            log.to << damage.to;
            log.arg = objectName();
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
            data = QVariant::fromValue(damage);
        } else if (event == PreCardUsed) {
            if (player->getMark("&wangong") + player->getMark("wangong") <= 0) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            room->setCardFlag(use.card, "wangong_ConfirmDamage");
            room->setPlayerMark(player, "&wangong", 0);
            room->setPlayerMark(player, "wangong", 0);
            if (!use.m_addHistory) return false;
            use.m_addHistory = false;
            room->addPlayerHistory(player, use.card->getClassName(), -1);
            data = QVariant::fromValue(use);
        } else {
            if (data.toString() != objectName()) return false;
            if (player->getMark("wangong") <= 0) return false;
            room->setPlayerMark(player, "wangong", 0);
            room->setPlayerMark(player, "&wangong", 1);
        }
        return false;
    }
};

class WangongRecord : public TriggerSkill
{
public:
    WangongRecord() : TriggerSkill("#wangong-record")
    {
        events << CardFinished << EventLoseSkill;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventLoseSkill) {
            if (player->isDead() || data.toString() != "wangong") return false;
            int n = player->getMark("&wangong");
            if (n <= 0) return false;
            room->setPlayerMark(player, "&wangong", 0);
            room->setPlayerMark(player, "wangong", 1);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (use.card->isKindOf("BasicCard")) {
                if (player->hasSkill("wangong", true))
                    room->setPlayerMark(player, "&wangong", 1);
                else
                    room->setPlayerMark(player, "wangong", 1);
            } else {
               room->setPlayerMark(player, "&wangong", 0);
               room->setPlayerMark(player, "wangong", 0);
            }
        }
        return false;
    }
};

class WangongTargetMod : public TargetModSkill
{
public:
    WangongTargetMod() : TargetModSkill("#wangong-target")
    {
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("wangong") && from->getMark("&wangong") + from->getMark("wangong") > 0)
            return 1000;
        else
            return 0;
    }
};

class Mouni : public PhaseChangeSkill
{
public:
    Mouni(const QString &mouni) : PhaseChangeSkill(mouni), mouni(mouni)
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;

        QList<const Card *> slashs;
        foreach (const Card *c, player->getHandcards()) {
            if (c->isKindOf("Slash"))
                slashs << c;
        }
        if (slashs.isEmpty()) return false;

        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->canSlash(p, NULL, false))
                targets << p;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer * target = room->askForPlayerChosen(player, targets, objectName(), "@" + mouni + "-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());

        try {
            int use_time = 0;
            while (!slashs.isEmpty()) {
                if (player->isDead() || target->hasFlag(mouni + "_dying")) break;
                foreach (const Card *c, slashs) {
                    if (!c->isKindOf("Slash") || !player->canSlash(target, c, false)) continue;
                    use_time++;
                    room->setPlayerMark(player, mouni + "-Clear", 1);
                    room->setCardFlag(c, mouni + "_used_slash");
                    room->useCard(CardUseStruct(c, player, target));
                    break;
                }

                slashs.clear();
                foreach (const Card *c, player->getHandcards()) {
                    if (c->isKindOf("Slash") && player->canSlash(target, c, false))
                        slashs << c;
                }
                room->getThread()->delay();
            }
            target->setFlags("-" + mouni + "_dying");

            int damage = room->getTag(mouni + "_damage_slashs").toInt();
            room->removeTag(mouni + "_damage_slashs");
            if (player->isAlive()) {
                if (damage < use_time) {
                    if (!player->isSkipped(Player::Play))
                        player->skip(Player::Play);
                    if (mouni == "secondmouni" && !player->isSkipped(Player::Discard))
                        player->skip(Player::Discard);
                }
            }
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                target->setFlags("-" + mouni + "_dying");
                room->removeTag(mouni + "_damage_slashs");
            }
            throw triggerEvent;
        }

        return false;
    }
private:
    QString mouni;
};

class MouniDying : public TriggerSkill
{
public:
    MouniDying(const QString &mouni) : TriggerSkill("#" + mouni + "-dying"), mouni(mouni)
    {
        events << EnterDying << DamageDone;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EnterDying) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getMark(mouni + "-Clear") <= 0) continue;
                player->setFlags(mouni + "_dying");
                break;
            }
        } else {
            DamageStruct d = data.value<DamageStruct>();
            if (!d.card || !d.card->hasFlag(mouni + "_used_slash")) return false;
            room->setCardFlag(d.card, "-" + mouni + "_used_slash");
            int damage = room->getTag(mouni + "_damage_slashs").toInt();
            damage++;
            room->setTag(mouni + "_damage_slashs", damage);
        }
        return false;
    }
private:
    QString mouni;
};

class Zongfan : public TriggerSkill
{
public:
    Zongfan() : TriggerSkill("zongfan")
    {
        events << EventPhaseChanging;
        frequency = Wake;
        waked_skills = "zhangu";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &data, Room *) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        if (player->getMark("zongfan") > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMark("tunjiang_skip_play-Clear") > 0) return false;
        if (player->getMark("mouni-Clear") <= 0) return false;
        return true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->doSuperLightbox("zhangmiao", "zongfan");
        room->setPlayerMark(player, "zongfan", 1);

        QList<int> ids = player->handCards();
        int n = room->askForyiji(player, ids, objectName()).length();
        if (n <= 0 || player->isDead()) return false;

        n = qMin(n, 5);
        if (room->changeMaxHpForAwakenSkill(player, n)) {
            room->recover(player, RecoverStruct(player, NULL, qMin(n, player->getMaxHp() - player->getHp())));
            if (player->isDead()) return false;
            room->handleAcquireDetachSkills(player, "-mouni|zhangu");
        }
        return false;
    }
};

class Zhangu : public PhaseChangeSkill
{
public:
    Zhangu() : PhaseChangeSkill("zhangu")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        if (player->getMaxHp() <= 1) return false;
        if (!player->isKongcheng() && !player->getEquips().isEmpty()) return false;

        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->loseMaxHp(player);
        if (player->isDead()) return false;

        QList<int> basics, tricks, equips;
        foreach (int id, room->getDrawPile()) {
            const Card *c = Sanguosha->getCard(id);
            if (c->isKindOf("BasicCard"))
                basics << id;
            else if (c->isKindOf("TrickCard"))
                tricks << id;
            else if (c->isKindOf("EquipCard"))
                equips << id;
        }
        DummyCard *dummy = new DummyCard;
        dummy->deleteLater();
        if (!basics.isEmpty()) {
            int basic = basics.at(qrand() % basics.length());
            dummy->addSubcard(basic);
        }
        if (!tricks.isEmpty()) {
            int trick = tricks.at(qrand() % tricks.length());
            dummy->addSubcard(trick);
        }
        if (!equips.isEmpty()) {
            int equip = equips.at(qrand() % equips.length());
            dummy->addSubcard(equip);
        }
        if (dummy->subcardsLength() <= 0) return false;
        room->obtainCard(player, dummy, true);
        return false;
    }
};

SP3Package::SP3Package()
    : Package("sp3")
{
    General *yangyi = new General(this, "yangyi", "shu", 3);
    yangyi->addSkill(new Duoduan);
    yangyi->addSkill(new Gongsun);

    General *ol_yangyi = new General(this, "ol_yangyi", "shu", 3);
    ol_yangyi->addSkill(new Juanxia);
    ol_yangyi->addSkill(new JuanxiaSlash);
    ol_yangyi->addSkill(new Dingcuo);
    related_skills.insertMulti("juanxia", "#juanxia-slash");

    General *chendeng = new General(this, "chendeng", "qun", 3);
    chendeng->addSkill(new Zhouxuan);
    chendeng->addSkill(new Fengji);
    chendeng->addSkill(new FengjiMaxCards);
    related_skills.insertMulti("fengji", "#fengji");

    General *tenyear_chendeng = new General(this, "tenyear_chendeng", "qun", 3);
    tenyear_chendeng->addSkill(new Wangzu);
    tenyear_chendeng->addSkill(new Yingrui);
    tenyear_chendeng->addSkill(new Fuyuan);

    General *ol_chendeng = new General(this, "ol_chendeng", "qun", 4);
    ol_chendeng->addSkill(new OLFengji);
    ol_chendeng->addSkill(new OLFengjiDraw);
    ol_chendeng->addSkill(new OLFengjiTargetMod);
    related_skills.insertMulti("olfengji", "#olfengji-draw");
    related_skills.insertMulti("olfengji", "#olfengji-target");

    General *tenyear_sunluyu = new General(this, "tenyear_sunluyu", "wu", 3, false);
    tenyear_sunluyu->addSkill(new TenyearMeibu("tenyearmeibu"));
    tenyear_sunluyu->addSkill(new TenyearMumu);
    tenyear_sunluyu->addRelateSkill("tenyearzhixi");

    General *second_tenyear_sunluyu = new General(this, "second_tenyear_sunluyu", "wu", 3, false);
    second_tenyear_sunluyu->addSkill(new TenyearMeibu("secondtenyearmeibu"));
    second_tenyear_sunluyu->addSkill(new SecondTenyearMeibuGet);
    second_tenyear_sunluyu->addSkill(new SecondTenyearMumu);
    second_tenyear_sunluyu->addRelateSkill("tenyearzhixi");
    related_skills.insertMulti("secondtenyearmeibu", "#secondtenyearmeibu-get");

    General *liuhong = new General(this, "liuhong", "qun", 4);
    liuhong->addSkill(new Yujue);
    liuhong->addSkill(new Tuxing);
    liuhong->addRelateSkill("zhihu");

    General *second_liuhong = new General(this, "second_liuhong", "qun", 4);
    second_liuhong->addSkill(new SecondYujue);
    second_liuhong->addSkill("tuxing");
    second_liuhong->addRelateSkill("secondzhihu");

    General *sp_hansui = new General(this, "sp_hansui", "qun", 4);
    sp_hansui->addSkill(new SpNiluan);
    sp_hansui->addSkill(new Weiwu);

    General *zhujun = new General(this, "zhujun", "qun", 4);
    zhujun->addSkill(new Gongjian);
    zhujun->addSkill(new GongjianRecord);
    zhujun->addSkill(new FakeMoveSkill("gongjian"));
    zhujun->addSkill(new Kuimang);
    zhujun->addSkill(new KuimangRecord);
    related_skills.insertMulti("gongjian", "#gongjian-record");
    related_skills.insertMulti("gongjian", "#gongjian-fake-move");
    related_skills.insertMulti("kuimang", "#kuimang-record");

    General *tenyear_quyi = new General(this, "tenyear_quyi", "qun", 4);
    tenyear_quyi->addSkill(new TenyearFuqi);
    tenyear_quyi->addSkill("jiaozi");

    General *tenyear_dingyuan = new General(this, "tenyear_dingyuan", "qun", 4);
    tenyear_dingyuan->addSkill(new Cixiao);
    tenyear_dingyuan->addSkill(new CixiaoSkill);
    tenyear_dingyuan->addSkill(new Xianshuai);
    tenyear_dingyuan->addSkill(new XianshuaiRecord);
    tenyear_dingyuan->addRelateSkill("panshi");
    related_skills.insertMulti("cixiao", "#cixiao-skill");
    related_skills.insertMulti("xianshuai", "#xianshuai");

    General *hanfu = new General(this, "hanfu", "qun", 4);
    hanfu->addSkill(new Jieyingh);
    hanfu->addSkill(new JieyinghInvoke);
    hanfu->addSkill(new JieyinghTargetMod);
    hanfu->addSkill(new Weipo);
    related_skills.insertMulti("jieyingh", "#jieyingh-invoke");
    related_skills.insertMulti("jieyingh", "#jieyingh-target");

    General *wangrong = new General(this, "wangrong", "qun", 3, false);
    wangrong->addSkill(new Minsi);
    wangrong->addSkill(new MinsiEffect);
    wangrong->addSkill(new MinsiTargetMod);
    wangrong->addSkill(new Jijing);
    wangrong->addSkill(new JijingJudge);
    wangrong->addSkill(new Zhuide);
    related_skills.insertMulti("minsi", "#minsi-effect");
    related_skills.insertMulti("minsi", "#minsi-target");
    related_skills.insertMulti("jijing", "#jijing-judge");

    General *liubian = new General(this, "liubian$", "qun", 3);
    liubian->addSkill(new Shiyuan);
    liubian->addSkill(new SpDushi);
    liubian->addSkill(new SpDushiDying);
    liubian->addSkill(new SpDushiPro);
    liubian->addSkill(new Skill("yuwei$", Skill::Compulsory));
    related_skills.insertMulti("spdushi", "#spdushi-dying");
    related_skills.insertMulti("spdushi", "#spdushi-pro");

    General *hucheer = new General(this, "hucheer", "qun", 4);
    hucheer->addSkill(new Daoji);

    General *tenyear_hucheer = new General(this, "tenyear_hucheer", "qun", 4);
    tenyear_hucheer->addSkill(new TenyearDaoji);
    tenyear_hucheer->addSkill(new TenyearDaojiLimit);
    tenyear_hucheer->addSkill(new Fuzhong);
    tenyear_hucheer->addSkill(new FuzhongMax);
    tenyear_hucheer->addSkill(new FuzhongDistance);
    related_skills.insertMulti("tenyeardaoji", "#tenyeardaoji-limit");
    related_skills.insertMulti("fuzhong", "#fuzhong-max");
    related_skills.insertMulti("fuzhong", "#tenyeardaoji-distance");

    General *mobile_hansui = new General(this, "mobile_hansui", "qun", 4);
    mobile_hansui->addSkill(new MobileNiluan);
    mobile_hansui->addSkill(new MobileNiluanLog);
    mobile_hansui->addSkill(new MobileNiluanDamage);
    mobile_hansui->addSkill(new MobileXiaoxi);
    related_skills.insertMulti("mobileniluan", "#mobileniluan-log");
    related_skills.insertMulti("mobileniluan", "#mobileniluan-damage");

    General *xushao = new General(this, "xushao", "qun", 4);
    xushao->addSkill(new Pingjian);

    General *zhangling = new General(this, "zhangling", "qun", 3);
    zhangling->addSkill(new Huqi);
    zhangling->addSkill(new HuqiDistance);
    zhangling->addSkill(new Shoufu);
    zhangling->addSkill(new ShoufuLimit);
    related_skills.insertMulti("huqi", "#huqi-distance");
    related_skills.insertMulti("shoufu", "#shoufu-limit");

    General *tenyear_chenlin = new General(this, "tenyear_chenlin", "wei", 3);
    tenyear_chenlin->addSkill("bifa");
    tenyear_chenlin->addSkill(new TenyearSongci);

    General *wolongfengchu = new General(this, "wolongfengchu", "shu", 4);
    wolongfengchu->addSkill(new Youlong);
    wolongfengchu->addSkill(new Luanfeng);

    General *second_zhuling = new General(this, "second_zhuling", "wei", 4);
    second_zhuling->addSkill(new SecondZhanyi);
    second_zhuling->addSkill(new SecondZhanyiEquip);
    related_skills.insertMulti("secondzhanyi", "#secondzhanyi-equip");

    General *guozhao = new General(this, "guozhao", "wei", 3, false);
    guozhao->addSkill(new Pianchong);
    guozhao->addSkill(new PianchongEffect);
    guozhao->addSkill(new Zunwei);
    related_skills.insertMulti("pianchong", "#pianchong-effect");

    General *gongsunkang = new General(this, "gongsunkang", "qun", 4);
    gongsunkang->addSkill(new Juliao);
    gongsunkang->addSkill(new Taomie);
    gongsunkang->addSkill(new TaomieMark);
    related_skills.insertMulti("taomie", "#taomie-mark");

    General *chunyuqiong = new General(this, "chunyuqiong", "qun", 4);
    chunyuqiong->addSkill(new Cangchu);
    chunyuqiong->addSkill(new CangchuKeep);
    chunyuqiong->addSkill(new Liangying);
    chunyuqiong->addSkill(new Shishou);
    related_skills.insertMulti("cangchu", "#cangchu-keep");

    General *fanyufeng = new General(this, "fanyufeng", "qun", 3, false);
    fanyufeng->addSkill(new Bazhan("bazhan"));
    fanyufeng->addSkill(new Jiaoying("jiaoying"));
    fanyufeng->addSkill(new JiaoyingMove("jiaoying"));
    related_skills.insertMulti("jiaoying", "#jiaoying-move");

    General *second_fanyufeng = new General(this, "second_fanyufeng", "qun", 3, false);
    second_fanyufeng->addSkill(new Bazhan("secondbazhan"));
    second_fanyufeng->addSkill(new FakeMoveSkill("secondbazhan"));
    second_fanyufeng->addSkill(new Jiaoying("secondjiaoying"));
    second_fanyufeng->addSkill(new JiaoyingMove("secondjiaoying"));
    related_skills.insertMulti("secondbazhan", "#secondbazhan-fake-move");
    related_skills.insertMulti("secondjiaoying", "#secondjiaoying-move");

    General *zhaozhong = new General(this, "zhaozhong", "qun", 6);
    zhaozhong->addSkill(new Yangzhong);
    zhaozhong->addSkill(new Huangkong);

    General *caosong = new General(this, "caosong", "wei", 3);
    caosong->addSkill(new Lilu);
    caosong->addSkill(new Yizhengc);
    caosong->addSkill(new YizhengcEffect);
    related_skills.insertMulti("yizhengc", "#yizhengc");

    General *second_caosong = new General(this, "second_caosong", "wei", 4);
    second_caosong->addSkill("lilu");
    second_caosong->addSkill("yizhengc");

    General *tenyear_taoqian = new General(this, "tenyear_taoqian", "qun", 3);
    tenyear_taoqian->addSkill("zhaohuo");
    tenyear_taoqian->addSkill(new TenyearYixiang);
    tenyear_taoqian->addSkill(new TenyearYirang("tenyearyirang"));

    General *second_tenyear_taoqian = new General(this, "second_tenyear_taoqian", "qun", 3);
    second_tenyear_taoqian->addSkill("zhaohuo");
    second_tenyear_taoqian->addSkill("tenyearyixiang");
    second_tenyear_taoqian->addSkill(new TenyearYirang("secondtenyearyirang"));

    General *new_mayunlu = new General(this, "new_mayunlu", "shu", 4, false);
    new_mayunlu->addSkill(new NewFengpo);
    new_mayunlu->addSkill(new NewFengpoEffect);
    new_mayunlu->addSkill(new NewFengpoRecord);
    new_mayunlu->addSkill("mashu");
    related_skills.insertMulti("newfengpo", "#newfengpo-effect");
    related_skills.insertMulti("newfengpo", "#newfengpo-record");

    General *puyuan = new General(this, "puyuan", "shu", 4);
    puyuan->addSkill(new Tianjiang);
    puyuan->addSkill(new Zhuren);
    puyuan->addRelateSkill("_hongduanqiang");
    puyuan->addRelateSkill("_tianleiren");
    puyuan->addRelateSkill("_shuibojian");
    puyuan->addRelateSkill("_liecuidao");
    puyuan->addRelateSkill("_hunduwanbi");

    General *ol_dingfeng = new General(this, "ol_dingfeng", "wu", 4);
    ol_dingfeng->addSkill(new OLDuanbing);
    ol_dingfeng->addSkill(new OLFenxun);
    ol_dingfeng->addSkill(new OLFenxunRecord);
    related_skills.insertMulti("olfenxun", "#olfenxun-record");

    General *liuye = new General(this, "liuye", "wei", 3);
    liuye->addSkill(new Polu("polu"));
    liuye->addSkill(new Choulve);
    liuye->addSkill(new ChoulveRecord);
    related_skills.insertMulti("choulve", "#choulve-record");

    General *second_liuye = new General(this, "second_liuye", "wei", 3);
    second_liuye->addSkill(new Polu("secondpolu"));
    second_liuye->addSkill("choulve");

    General *panshu = new General(this, "panshu", "wu", 3, false);
    panshu->addSkill(new Weiyi);
    panshu->addSkill(new Jinzhi("jinzhi"));

    General *second_panshu = new General(this, "second_panshu", "wu", 3, false);
    second_panshu->addSkill("weiyi");
    second_panshu->addSkill(new Jinzhi("secondjinzhi"));

    General *ruanyu = new General(this, "ruanyu", "wei", 3);
    ruanyu->addSkill(new Xingzuo);
    ruanyu->addSkill(new XingzuoFinish);
    ruanyu->addSkill(new Miaoxian);
    related_skills.insertMulti("xingzuo", "#xingzuo-finish");

    General *huangzu = new General(this, "huangzu", "qun", 4);
    huangzu->addSkill(new Wangong);
    huangzu->addSkill(new WangongRecord);
    huangzu->addSkill(new WangongTargetMod);
    related_skills.insertMulti("wangong", "#wangong-record");
    related_skills.insertMulti("wangong", "#wangong-target");

    General *zhangmiao = new General(this, "zhangmiao", "qun", 4);
    zhangmiao->addSkill(new Mouni("mouni"));
    zhangmiao->addSkill(new MouniDying("mouni"));
    zhangmiao->addSkill(new Zongfan);
    zhangmiao->addRelateSkill("zhangu");
    related_skills.insertMulti("mouni", "#mouni-dying");

    General *second_zhangmiao = new General(this, "second_zhangmiao", "qun", 4);
    second_zhangmiao->addSkill(new Mouni("secondmouni"));
    second_zhangmiao->addSkill(new MouniDying("secondmouni"));
    second_zhangmiao->addSkill("zongfan");
    second_zhangmiao->addRelateSkill("zhangu");
    related_skills.insertMulti("secondmouni", "#secondmouni-dying");

    addMetaObject<GongsunCard>();
    addMetaObject<ZhouxuanCard>();
    addMetaObject<YingruiCard>();
    addMetaObject<YujueCard>();
    addMetaObject<SecondYujueCard>();
    addMetaObject<SpNiluanCard>();
    addMetaObject<WeiwuCard>();
    addMetaObject<CixiaoCard>();
    addMetaObject<JieyinghCard>();
    addMetaObject<MinsiCard>();
    addMetaObject<JijingCard>();
    addMetaObject<DaojiCard>();
    addMetaObject<PingjianCard>();
    addMetaObject<ShoufuCard>();
    addMetaObject<ShoufuPutCard>();
    addMetaObject<TenyearSongciCard>();
    addMetaObject<YoulongCard>();
    addMetaObject<SecondZhanyiViewAsBasicCard>();
    addMetaObject<SecondZhanyiCard>();
    addMetaObject<ZunweiCard>();
    addMetaObject<BazhanCard>();
    addMetaObject<SecondBazhanCard>();
    addMetaObject<LiluCard>();
    addMetaObject<TianjiangCard>();
    addMetaObject<ZhurenCard>();
    addMetaObject<OLFenxunCard>();
    addMetaObject<JinzhiCard>();
    addMetaObject<SecondJinzhiCard>();
    addMetaObject<XingzuoCard>();
    addMetaObject<MiaoxianCard>();

    skills << new TenyearZhixi << new Zhihu << new SecondZhihu << new Panshi << new Zhangu;
}

ADD_PACKAGE(SP3)
