#include "mobilezhi.h"
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
#include "wind.h"

MobileZhiQiaiCard::MobileZhiQiaiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void MobileZhiQiaiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->giveCard(effect.from, effect.to, this, "mobilezhiqiai");
    if (effect.from->isDead() || effect.to->isDead()) return;
    QStringList choices;
    if (effect.from->getLostHp() > 0)
        choices << "recover";
    choices << "draw";
    if (room->askForChoice(effect.to, "mobilezhiqiai", choices.join("+"), QVariant::fromValue(effect.from)) == "recover")
        room->recover(effect.from, RecoverStruct(effect.to));
    else
        effect.from->drawCards(2, "mobilezhiqiai");
}

class MobileZhiQiai : public OneCardViewAsSkill
{
public:
    MobileZhiQiai() : OneCardViewAsSkill("mobilezhiqiai")
    {
        filter_pattern = "^BasicCard";
    }

    const Card *viewAs(const Card *card) const
    {
        MobileZhiQiaiCard *c = new MobileZhiQiaiCard;
        c->addSubcard(card);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileZhiQiaiCard");
    }
};

class MobileZhiShanxi : public TriggerSkill
{
public:
    MobileZhiShanxi() : TriggerSkill("mobilezhishanxi")
    {
        events << EventPhaseStart << HpRecover;
    }

    bool transferMark(ServerPlayer *to, Room *room) const
    {
        int n = 0;
        foreach (ServerPlayer *p, room->getOtherPlayers(to)) {
            if (to->isDead()) break;
            if (p->isAlive() && p->getMark("&mobilezhixi") > 0) {
                n++;
                int mark = p->getMark("&mobilezhixi");
                p->loseAllMarks("&mobilezhixi");
                to->gainMark("&mobilezhixi", mark);
            }
        }
        return n > 0;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play || !player->hasSkill(this)) return false;
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMark("&mobilezhixi") > 0) continue;
                targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@mobilezhishanxi-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            if (transferMark(target, room)) return false;
            target->gainMark("&mobilezhixi");
        } else {
            if (player->getMark("&mobilezhixi") <= 0 || player->hasFlag("Global_Dying")) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this)) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                if (p == player || player->getCardCount() < 2)
                    room->loseHp(player);
                else {
                    const Card *card = room->askForExchange(player, objectName(), 2, 2, true, "mobilezhishanxi-give:" + p->objectName(), true);
                    if (!card)
                        room->loseHp(player);
                    else {
                        room->giveCard(player, p, card, objectName());
                        delete card;
                    }
                }
            }

        }
        return false;
    }
};

MobileZhiShamengCard::MobileZhiShamengCard()
{
}

void MobileZhiShamengCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->drawCards(2, "mobilezhishameng");
    effect.from->drawCards(3, "mobilezhishameng");
}

class MobileZhiShameng : public ViewAsSkill
{
public:
    MobileZhiShameng() : ViewAsSkill("mobilezhishameng")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped() || Self->isJilei(to_select) || selected.length() > 1) return false;
        if (selected.isEmpty()) return true;
        if (selected.length() == 1)
            return to_select->sameColorWith(selected.first());
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2) return NULL;
        MobileZhiShamengCard *c = new MobileZhiShamengCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileZhiShamengCard");
    }
};

class MobileZhiFubi : public GameStartSkill
{
public:
    MobileZhiFubi(const QString &mobilezhifubi_skill) : GameStartSkill(mobilezhifubi_skill), mobilezhifubi_skill(mobilezhifubi_skill)
    {
    }

    void onGameStart(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), mobilezhifubi_skill,
                       "@mobilezhifubi-invoke", true, true);
        if (!target) return;
        room->broadcastSkillInvoke(mobilezhifubi_skill);
        target->gainMark("&mobilezhifu");
    }

private:
    QString mobilezhifubi_skill;
};

class MobileZhiFubiKeep : public MaxCardsSkill
{
public:
    MobileZhiFubiKeep() : MaxCardsSkill("#mobilezhifubi")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->getMark("&mobilezhifu") > 0) {
            int sunshao = 0;
            foreach (const Player *p, target->getAliveSiblings()) {
                if (p->hasSkill("mobilezhifubi"))
                    sunshao++;
            }
            return 3 * sunshao;
        }
        return 0;
    }
};

class MobileZhiZuici : public TriggerSkill
{
public:
    MobileZhiZuici() : TriggerSkill("mobilezhizuici")
    {
        events << Dying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who != player) return false;
        QStringList areas;
        for (int i = 0; i < 5; i++) {
            if (player->getEquip(i) && player->hasEquipArea(i))
                areas << QString::number(i);
        }
        if (areas.isEmpty()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        QString area = room->askForChoice(player, objectName(), areas.join("+"));
        player->throwEquipArea(area.toInt());
        room->recover(player, RecoverStruct(player, NULL, 1 - player->getHp()));
        return false;
    }
};

class MobileZhiFubiStart : public PhaseChangeSkill
{
public:
    MobileZhiFubiStart(const QString &mobilezhifubi_skill) : PhaseChangeSkill("#" + mobilezhifubi_skill), mobilezhifubi_skill(mobilezhifubi_skill)
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        Player::Phase phase = Player::Play;
        if (mobilezhifubi_skill == "thirdmobilezhifubi")
            phase = Player::Start;
        return target != NULL && target->isAlive() && target->getMark("&mobilezhifu") > 0 && target->getPhase() == phase;
    }


    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(mobilezhifubi_skill)) continue;
            if (!p->askForSkillInvoke(mobilezhifubi_skill, player)) continue;
            room->broadcastSkillInvoke(mobilezhifubi_skill);

            QString choice = room->askForChoice(p, mobilezhifubi_skill, "max+slash", QVariant::fromValue(player));
            LogMessage log;
            log.type = "#FumianFirstChoice";
            log.from = p;
            log.arg = mobilezhifubi_skill + ":" + choice;
            room->sendLog(log);
            if (choice == "max")
                room->addMaxCards(player, 3);
            else
                room->addSlashCishu(player, 1);
        }
        return false;
    }
private:
    QString mobilezhifubi_skill;
};

SecondMobileZhiZuiciCard::SecondMobileZhiZuiciCard()
{
    target_fixed = true;
}

void SecondMobileZhiZuiciCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QStringList areas;
    for (int i = 0; i < 5; i++) {
        if (source->getEquip(i) && source->hasEquipArea(i))
            areas << QString::number(i);
    }
    if (areas.isEmpty()) return;
    QString area = room->askForChoice(source, "secondmobilezhizuici", areas.join("+"));
    source->throwEquipArea(area.toInt());
    room->recover(source, RecoverStruct(source, NULL, qMin(2, source->getMaxHp() - source->getHp())));

    bool hasmark = false;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->getMark("&mobilezhifu") > 0) {
            hasmark = true;
            break;
        }
    }

    if (hasmark && source->isAlive())
        room->askForUseCard(source, "@@secondmobilezhizuici", "@secondmobilezhizuici");
}

SecondMobileZhiZuiciMarkCard::SecondMobileZhiZuiciMarkCard()
{
}

bool SecondMobileZhiZuiciMarkCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (targets.isEmpty())
        return to_select->getMark("&mobilezhifu") > 0;
    else if (targets.length() == 1)
        return true;
    else
        return false;
}

bool SecondMobileZhiZuiciMarkCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void SecondMobileZhiZuiciMarkCard::onUse(Room *, const CardUseStruct &card_use) const
{
    if (card_use.to.length() != 2 || card_use.to.first()->getMark("&mobilezhifu") <= 0) return;
    card_use.to.first()->loseMark("&mobilezhifu");
    if (card_use.to.last()->isAlive())
        card_use.to.last()->gainMark("&mobilezhifu");
}

class SecondMobileZhiZuiciVS : public ZeroCardViewAsSkill
{
public:
    SecondMobileZhiZuiciVS() : ZeroCardViewAsSkill("secondmobilezhizuici")
    {
        response_pattern = "@@secondmobilezhizuici";
    }

    const Card *viewAs() const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            return new SecondMobileZhiZuiciCard;
        } else {
            if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@secondmobilezhizuici")
                return new SecondMobileZhiZuiciMarkCard;
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->hasEquipArea() && !player->getEquips().isEmpty();
    }
};

class SecondMobileZhiZuici : public TriggerSkill
{
public:
    SecondMobileZhiZuici() : TriggerSkill("secondmobilezhizuici")
    {
        events << Dying;
        view_as_skill = new SecondMobileZhiZuiciVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who != player) return false;
        QStringList areas;
        for (int i = 0; i < 5; i++) {
            if (player->getEquip(i) && player->hasEquipArea(i))
                areas << QString::number(i);
        }
        if (areas.isEmpty()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        QString area = room->askForChoice(player, objectName(), areas.join("+"));
        player->throwEquipArea(area.toInt());
        room->recover(player, RecoverStruct(player, NULL, qMin(2, player->getMaxHp() - player->getHp())));

        bool hasmark = false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark("&mobilezhifu") > 0) {
                hasmark = true;
                break;
            }
        }

        if (hasmark && player->isAlive())
            room->askForUseCard(player, "@@secondmobilezhizuici", "@secondmobilezhizuici");
        return false;
    }
};

MobileZhiDuojiCard::MobileZhiDuojiCard()
{
}

bool MobileZhiDuojiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->getEquips().isEmpty();
}

void MobileZhiDuojiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->removePlayerMark(effect.from, "@mobilezhiduojiMark");
    room->doSuperLightbox("mobilezhi_xunchen", "mobilezhiduoji");
    QList<int> equiplist = effect.to->getEquipsId();
    if (equiplist.isEmpty()) return;
    DummyCard equips(equiplist);
    room->obtainCard(effect.from, &equips);
}

class MobileZhiDuoji : public ViewAsSkill
{
public:
    MobileZhiDuoji() : ViewAsSkill("mobilezhiduoji")
    {
        frequency = Limited;
        limit_mark = "@mobilezhiduojiMark";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() < 2 && !to_select->isEquipped() && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2) return NULL;
        MobileZhiDuojiCard *c = new MobileZhiDuojiCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@mobilezhiduojiMark") > 0;
    }
};

MobileZhiJianzhanCard::MobileZhiJianzhanCard()
{
}

void MobileZhiJianzhanCard::onEffect(const CardEffectStruct &effect) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->deleteLater();
    slash->setSkillName("_mobilezhijianzhan");

    Room *room = effect.from->getRoom();
    QStringList choices;
    QList<ServerPlayer *> can_slash;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.to)) {
        if (!effect.to->canSlash(p, slash) || p->getHandcardNum() >= effect.to->getHandcardNum()) continue;
        can_slash << p;
    }
    if (!can_slash.isEmpty())
        choices << "slash";
    choices << "draw";

    QString choice = room->askForChoice(effect.to, "mobilezhijianzhan", choices.join("+"), QVariant::fromValue(effect.from));
    if (choice == "slash") {
        foreach (ServerPlayer *p, can_slash) {
            if (!effect.to->canSlash(p, slash) || p->getHandcardNum() >= effect.to->getHandcardNum())
                can_slash.removeOne(p);
        }
        if (can_slash.isEmpty()) return;
        ServerPlayer *to = room->askForPlayerChosen(effect.from, can_slash, "mobilezhijianzhan", "@mobilezhijianzhan-slash:" + effect.to->objectName());
        room->useCard(CardUseStruct(slash, effect.to, to));
    } else
        effect.from->drawCards(1, "mobilezhijianzhan");
}

class MobileZhiJianzhan : public ZeroCardViewAsSkill
{
public:
    MobileZhiJianzhan() : ZeroCardViewAsSkill("mobilezhijianzhan")
    {
    }

    const Card *viewAs() const
    {
        return new MobileZhiJianzhanCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileZhiJianzhanCard");
    }
};

SecondMobileZhiDuojiCard::SecondMobileZhiDuojiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void SecondMobileZhiDuojiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->addToPile("smzdjji", subcards);
}

SecondMobileZhiDuojiRemove::SecondMobileZhiDuojiRemove()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void SecondMobileZhiDuojiRemove::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "secondmobilezhiduoji", QString());
    room->throwCard(this, reason, NULL);
    card_use.from->drawCards(1, "secondmobilezhiduoji");
}

class SecondMobileZhiDuojiVS : public OneCardViewAsSkill
{
public:
    SecondMobileZhiDuojiVS() : OneCardViewAsSkill("secondmobilezhiduoji")
    {
        response_pattern = "@@secondmobilezhiduoji!";
        expand_pile = "smzdjji";
    }

    bool viewFilter(const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return true;
        else if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@secondmobilezhiduoji!")
                return Self->getPile("smzdjji").contains(to_select->getEffectiveId());
        return false;
    }

    const Card *viewAs(const Card *card) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            SecondMobileZhiDuojiCard *c = new SecondMobileZhiDuojiCard;
            c->addSubcard(card);
            return c;
        } else if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@secondmobilezhiduoji!") {
            SecondMobileZhiDuojiRemove *c = new SecondMobileZhiDuojiRemove;
            c->addSubcard(card);
            return c;
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SecondMobileZhiDuojiCard");
    }
};

class SecondMobileZhiDuoji : public TriggerSkill
{
public:
    SecondMobileZhiDuoji() : TriggerSkill("secondmobilezhiduoji")
    {
        events << CardFinished << EventPhaseChanging;
        view_as_skill = new SecondMobileZhiDuojiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && !target->getPile("smzdjji").isEmpty();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("EquipCard")) return false;
            if (room->getCardPlace(use.card->getEffectiveId()) != Player::PlaceEquip ||
                    room->getCardOwner(use.card->getEffectiveId()) != player) return false;

            ServerPlayer *xunchen = room->findPlayerBySkillName(objectName());
            if (!xunchen) return false;

            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = player;
            log.arg = "secondmobilezhiduoji";
            room->sendLog(log);
            room->notifySkillInvoked(xunchen, objectName());
            room->broadcastSkillInvoke(objectName());

            CardMoveReason _reason(CardMoveReason::S_REASON_EXTRACTION, xunchen->objectName());
            room->obtainCard(xunchen, use.card, _reason);

            QList<int> piles = player->getPile("smzdjji");
            if (player->isDead() || piles.isEmpty()) return false;

            CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "secondmobilezhiduoji", QString());
            if (piles.length() == 1) {
                room->throwCard(Sanguosha->getCard(piles.first()), reason, NULL);
                player->drawCards(1, objectName());
            } else {
                if (!room->askForUseCard(player, "@@secondmobilezhiduoji!", "@secondmobilezhiduoji", -1, Card::MethodNone)) {
                    int id = piles.at(qrand() % piles.length());
                    room->throwCard(Sanguosha->getCard(id), reason, NULL);
                    player->drawCards(1, objectName());
                }
            }
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;

            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = player;
            log.arg = "secondmobilezhiduoji";
            room->sendLog(log);

            ServerPlayer *xunchen = room->findPlayerBySkillName(objectName());
            if (xunchen) {
                room->notifySkillInvoked(xunchen, objectName());
                room->broadcastSkillInvoke(objectName());
            }

            QList<int> piles = player->getPile("smzdjji");
            CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "secondmobilezhiduoji", QString());
            DummyCard remove(piles);
            room->throwCard(&remove, reason, NULL);

            if (xunchen && xunchen->isAlive()) {
                QList<int> get;
                foreach (int id, piles) {
                    if (room->getCardPlace(id) != Player::DiscardPile) continue;
                    get << id;
                }
                if (get.isEmpty()) return false;
                DummyCard _get(get);
                room->obtainCard(xunchen, &_get);
            }
        }
        return false;
    }
};

MobileZhiWanweiCard::MobileZhiWanweiCard()
{
}

void MobileZhiWanweiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.from, "mobilezhiwanwei_lun");
    int hp = effect.from->getHp();
    if (hp + 1 > 0)
        room->recover(effect.to, RecoverStruct(effect.from, NULL, qMin(hp + 1, effect.to->getMaxHp() - effect.to->getHp())));
    if (hp > 0)
        room->loseHp(effect.from, hp);
}

class MobileZhiWanweiVS : public ZeroCardViewAsSkill
{
public:
    MobileZhiWanweiVS() : ZeroCardViewAsSkill("mobilezhiwanwei")
    {
    }

    const Card *viewAs() const
    {
        return new MobileZhiWanweiCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileZhiWanweiCard") && player->getMark("mobilezhiwanwei_lun") <= 0;
    }
};

class MobileZhiWanwei : public TriggerSkill
{
public:
    MobileZhiWanwei() : TriggerSkill("mobilezhiwanwei")
    {
        events << Dying;
        view_as_skill = new MobileZhiWanweiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (player == dying.who || player->getMark("mobilezhiwanwei_lun") >= 0) return false;
        int hp = player->getHp();
        if (hp + 1 <= 0) return false;
        if (!player->askForSkillInvoke(this, dying.who)) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, "mobilezhiwanwei_lun");
        room->recover(dying.who, RecoverStruct(player, NULL, qMin(hp + 1, dying.who->getMaxHp() - dying.who->getHp())));
        if (hp > 0)
            room->loseHp(player, hp);
        return false;
    }
};

class MobileZhiYuejianVS : public ViewAsSkill
{
public:
    MobileZhiYuejianVS() : ViewAsSkill("mobilezhiyuejian")
    {
        response_pattern = "@@mobilezhiyuejian";
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

class MobileZhiYuejian : public TriggerSkill
{
public:
    MobileZhiYuejian() : TriggerSkill("mobilezhiyuejian")
    {
        events << Dying;
        view_as_skill = new MobileZhiYuejianVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (player != dying.who || player->getCardCount() < 2 || !player->canDiscard(player, "he")) return false;
        if (!room->askForCard(player, "@@mobilezhiyuejian", "@mobilezhiyuejian", data, objectName())) return false;
        room->broadcastSkillInvoke(objectName());
        room->recover(player, RecoverStruct(player));
        return false;
    }
};

class MobileZhiYuejianMax : public MaxCardsSkill
{
public:
    MobileZhiYuejianMax() : MaxCardsSkill("#mobilezhiyuejian-max")
    {
    }

    int getFixed(const Player *target) const
    {
        if (target->hasSkill("mobilezhiyuejian"))
            return target->getMaxHp();
        else
            return -1;
    }
};

MobileZhiJianyuCard::MobileZhiJianyuCard()
{
}

bool MobileZhiJianyuCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.length() < 2;
}

bool MobileZhiJianyuCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void MobileZhiJianyuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->addPlayerMark(source, "mobilezhijianyu_lun");
    room->addPlayerMark(targets.first(), "&mobilezhijianyu+#" + source->objectName() + "#" + targets.last()->objectName());
    room->addPlayerMark(targets.last(), "&mobilezhijianyu+#" + source->objectName() + "#" + targets.first()->objectName());
}

class MobileZhiJianyuVS : public ZeroCardViewAsSkill
{
public:
    MobileZhiJianyuVS() : ZeroCardViewAsSkill("mobilezhijianyu")
    {
    }

    const Card *viewAs() const
    {
        return new MobileZhiJianyuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("mobilezhijianyu_lun") <= 0;
    }
};

class MobileZhiJianyu : public TriggerSkill
{
public:
    MobileZhiJianyu() : TriggerSkill("mobilezhijianyu")
    {
        events << EventPhaseStart << TargetSpecifying;
        view_as_skill = new MobileZhiJianyuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseStart)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                foreach (QString mark, p->getMarkNames()) {
                    if (mark.startsWith("&mobilezhijianyu+#" + player->objectName()) && p->getMark(mark) > 0)
                        room->setPlayerMark(p, mark, 0);
                }
            }
        } else {
            if (player->getPhase() != Player::Play) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            foreach (ServerPlayer *p, use.to) {
                if (p->isDead()) continue;
                int n = 0;
                foreach (ServerPlayer *feiyi, room->getAllPlayers()) {
                    if (feiyi->isDead() || !feiyi->hasSkill(this)) continue;
                    if (player->getMark("&mobilezhijianyu+#" + feiyi->objectName() + "#" + p->objectName()) > 0) {
                        room->sendCompulsoryTriggerLog(feiyi, objectName(), true, true);
                        n++;
                    }
                }
                if (n > 0)
                    p->drawCards(n, objectName());
            }
        }
        return false;
    }
};

class MobileZhiShengxi : public PhaseChangeSkill
{
public:
    MobileZhiShengxi() : PhaseChangeSkill("mobilezhishengxi")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (player->getMark("damage_point_round") > 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        player->getRoom()->broadcastSkillInvoke(objectName());
        player->drawCards(2, objectName());
        return false;
    }
};

class MobileZhiQinzheng : public TriggerSkill
{
public:
    MobileZhiQinzheng() : TriggerSkill("mobilezhiqinzheng")
    {
        events << CardUsed << CardResponded;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == CardUsed) {
            card = data.value<CardUseStruct>().card;
        } else
            card = data.value<CardResponseStruct>().m_card;

        if (!card || card->isKindOf("SkillCard")) return false;
        int mark = player->getMark("&mobilezhiqinzheng") + 1;
        room->setPlayerMark(player, "&mobilezhiqinzheng", mark);

        if (mark % 3 == 0 || mark % 5 == 0 || mark % 8 == 0) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            if (mark % 3 == 0)
                getQinzhengCard(player, 3);
            if (mark % 5 == 0 && player->isAlive())
                getQinzhengCard(player, 5);
            if (mark % 8 == 0 && player->isAlive())
                getQinzhengCard(player, 8);
        }
        return false;
    }

    void getQinzhengCard(ServerPlayer *player, int num) const
    {
        Room *room = player->getRoom();
        QList<int> card_ids;
        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (num == 3 && (card->isKindOf("Slash") || card->isKindOf("Jink")))
                card_ids << id;
            else if (num == 5 && (card->isKindOf("Peach") || card->isKindOf("Analeptic")))
                card_ids << id;
            else if (num == 8 && (card->isKindOf("ExNihilo") || card->isKindOf("Duel")))
                card_ids << id;
        }
        if (card_ids.isEmpty()) return;
        int id = card_ids.at(qrand() % card_ids.length());
        room->obtainCard(player, id, true);
    }
};

class MobileZhiQinzhengClear : public TriggerSkill
{
public:
    MobileZhiQinzhengClear() : TriggerSkill("#mobilezhiqinzheng-clear")
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
        if (data.toString() != "mobilezhiqinzheng") return false;
        room->setPlayerMark(player, "&mobilezhiqinzheng", 0);
        return false;
    }
};

class MobileZhiWuku : public TriggerSkill
{
public:
    MobileZhiWuku() : TriggerSkill("mobilezhiwuku")
    {
        events << CardUsed;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("EquipCard")) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || p->getMark("&mobilezhiwuku") >= 3) continue;
            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
            p->gainMark("&mobilezhiwuku");
        }
        return false;
    }
};

class MobileZhiSanchen : public PhaseChangeSkill
{
public:
    MobileZhiSanchen() : PhaseChangeSkill("mobilezhisanchen")
    {
        frequency = Wake;
        waked_skills = "mobilezhimiewu";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Finish || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMark("&mobilezhiwuku") < 3) return false;
        LogMessage log;
        log.type = "#MobileZhiSanchenWake";
        log.from = player;
        log.arg = QString::number(player->getMark("&mobilezhiwuku"));
        log.arg2 = objectName();
        room->sendLog(log);
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());
        room->doSuperLightbox("mobilezhi_duyu", objectName());
        room->setPlayerMark(player, "mobilezhisanchen", 1);
        if (room->changeMaxHpForAwakenSkill(player, 1)) {
            room->recover(player, RecoverStruct(player));
            room->handleAcquireDetachSkills(player, "mobilezhimiewu");
        }
        return false;
    }
};

MobileZhiMiewuCard::MobileZhiMiewuCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool MobileZhiMiewuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        if (card) {
            card->addSubcards(subcards);
            card->setSkillName("mobilezhimiewu");
        }
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    const Card *_card = Self->tag.value("mobilezhimiewu").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    card->addSubcards(subcards);
    card->setSkillName("mobilezhimiewu");
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool MobileZhiMiewuCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        if (card) {
            card->addSubcards(subcards);
            card->setSkillName("mobilezhimiewu");
        }
        return card && card->targetFixed();
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *_card = Self->tag.value("mobilezhimiewu").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    card->addSubcards(subcards);
    card->setSkillName("mobilezhimiewu");
    return card && card->targetFixed();
}

bool MobileZhiMiewuCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        if (card) {
            card->addSubcards(subcards);
            card->setSkillName("mobilezhimiewu");
        }
        return card && card->targetsFeasible(targets, Self);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *_card = Self->tag.value("mobilezhimiewu").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    card->addSubcards(subcards);
    card->setSkillName("mobilezhimiewu");
    return card && card->targetsFeasible(targets, Self);
}

const Card *MobileZhiMiewuCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;
    player->loseMark("&mobilezhiwuku");
    Room *room = player->getRoom();
    room->addPlayerMark(player, "mobilezhimiewu-Clear");

    QString to_yizan = user_string;
    if (user_string == "slash" && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList guhuo_list;
        guhuo_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "normal_slash" << "thunder_slash" << "fire_slash";
        to_yizan = room->askForChoice(player, "mobilezhimiewu_slash", guhuo_list.join("+"));
    }

    const Card *card = Sanguosha->getCard(subcards.first());
    QString user_str;
    if (to_yizan == "slash") {
        if (card->isKindOf("Slash"))
            user_str = card->objectName();
        else
            user_str = "slash";
    } else if (to_yizan == "normal_slash")
        user_str = "slash";
    else
        user_str = to_yizan;
    Card *use_card = Sanguosha->cloneCard(user_str, card->getSuit(), card->getNumber());
    use_card->setSkillName("mobilezhimiewu");
    use_card->addSubcards(getSubcards());
    room->setCardFlag(use_card, "mobilezhimiewu");
    use_card->deleteLater();
    return use_card;
}

const Card *MobileZhiMiewuCard::validateInResponse(ServerPlayer *player) const
{
    player->loseMark("&mobilezhiwuku");
    Room *room = player->getRoom();
    room->addPlayerMark(player, "mobilezhimiewu-Clear");

    QString to_yizan;
    if (user_string == "peach+analeptic") {
        QStringList guhuo_list;
        guhuo_list << "peach";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "analeptic";
        to_yizan = room->askForChoice(player, "mobilezhimiewu_saveself", guhuo_list.join("+"));
    } else if (user_string == "slash") {
        QStringList guhuo_list;
        guhuo_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "normal_slash" << "thunder_slash" << "fire_slash";
        to_yizan = room->askForChoice(player, "mobilezhimiewu_slash", guhuo_list.join("+"));
    } else
        to_yizan = user_string;

    const Card *card = Sanguosha->getCard(subcards.first());
    QString user_str;
    if (to_yizan == "slash") {
        if (card->isKindOf("Slash"))
            user_str = card->objectName();
        else
            user_str = "slash";
    } else if (to_yizan == "normal_slash")
        user_str = "slash";
    else
        user_str = to_yizan;
    Card *use_card = Sanguosha->cloneCard(user_str, card->getSuit(), card->getNumber());
    use_card->setSkillName("mobilezhimiewu");
    use_card->addSubcards(getSubcards());
    room->setCardFlag(use_card, "mobilezhimiewu");
    use_card->deleteLater();
    return use_card;
}

class MobileZhiMiewuVS : public ViewAsSkill
{
public:
    MobileZhiMiewuVS() : ViewAsSkill("mobilezhimiewu")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
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
        return player->getMark("&mobilezhiwuku") > 0 && player->getMark("mobilezhimiewu-Clear") <= 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
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
        if (player->getMark("&mobilezhiwuku") <= 0 || player->getMark("mobilezhimiewu-Clear") > 0) return false;
        if (pattern.startsWith(".") || pattern.startsWith("@")) return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;
        for (int i = 0; i < pattern.length(); i++) {
            QChar ch = pattern[i];
            if (ch.isUpper() || ch.isDigit()) return false; // This is an extremely dirty hack!! For we need to prevent patterns like 'BasicCard'
        }
        return true;
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        ServerPlayer *current = player->getRoom()->getCurrent();
        if (!current || current->isDead() || current->getPhase() == Player::NotActive) return false;
        return player->getMark("&mobilezhiwuku") > 0 && player->getMark("mobilezhimiewu-Clear") <= 0;
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
        return selected.isEmpty();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 1) return NULL;
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE
            || Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            MobileZhiMiewuCard *card = new MobileZhiMiewuCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            card->addSubcards(cards);
            return card;
        }

        const Card *c = Self->tag.value("mobilezhimiewu").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            MobileZhiMiewuCard *card = new MobileZhiMiewuCard;
            card->setUserString(c->objectName());
            card->addSubcards(cards);
            return card;
        }
        return NULL;
    }
};

class MobileZhiMiewu : public TriggerSkill
{
public:
    MobileZhiMiewu() : TriggerSkill("mobilezhimiewu")
    {
        events << CardFinished << CardResponded;
        view_as_skill = new MobileZhiMiewuVS;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("mobilezhimiewu", true, true, true, false, true);
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == CardFinished)
            card = data.value<CardUseStruct>().card;
        else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (res.m_isUse) return false;
            card = res.m_card;
        }
        if (!card || card->isKindOf("SkillCard") || (!card->hasFlag("mobilezhimiewu") && card->getSkillName() != objectName())) return false;
        player->drawCards(1, objectName());
        return false;
    }
};


MobileZhiPackage::MobileZhiPackage()
    : Package("mobilezhi")
{
    General *mobilezhi_wangcan = new General(this, "mobilezhi_wangcan", "wei", 3);
    mobilezhi_wangcan->addSkill(new MobileZhiQiai);
    mobilezhi_wangcan->addSkill(new MobileZhiShanxi);

    General *mobilezhi_chenzhen = new General(this, "mobilezhi_chenzhen", "shu", 3);
    mobilezhi_chenzhen->addSkill(new MobileZhiShameng);

    General *mobilezhi_sunshao = new General(this, "mobilezhi_sunshao", "wu", 3);
    mobilezhi_sunshao->addSkill(new MobileZhiFubi("mobilezhifubi"));
    mobilezhi_sunshao->addSkill(new MobileZhiFubiKeep);
    mobilezhi_sunshao->addSkill(new MobileZhiZuici);
    related_skills.insertMulti("mobilezhifubi", "#mobilezhifubi");

    General *second_mobilezhi_sunshao = new General(this, "second_mobilezhi_sunshao", "wu", 3);
    second_mobilezhi_sunshao->addSkill(new MobileZhiFubi("secondmobilezhifubi"));
    second_mobilezhi_sunshao->addSkill(new MobileZhiFubiStart("secondmobilezhifubi"));
    second_mobilezhi_sunshao->addSkill(new SecondMobileZhiZuici);

    General *third_mobilezhi_sunshao = new General(this, "third_mobilezhi_sunshao", "wu", 3);
    third_mobilezhi_sunshao->addSkill(new MobileZhiFubi("thirdmobilezhifubi"));
    third_mobilezhi_sunshao->addSkill(new MobileZhiFubiStart("thirdmobilezhifubi"));
    third_mobilezhi_sunshao->addSkill("secondmobilezhizuici");
    related_skills.insertMulti("thirdmobilezhifubi", "#thirdmobilezhifubi");

    General *mobilezhi_xunchen = new General(this, "mobilezhi_xunchen", "qun", 3);
    mobilezhi_xunchen->addSkill(new MobileZhiDuoji);
    mobilezhi_xunchen->addSkill(new MobileZhiJianzhan);

    General *second_mobilezhi_xunchen = new General(this, "second_mobilezhi_xunchen", "qun", 3);
    second_mobilezhi_xunchen->addSkill(new SecondMobileZhiDuoji);
    second_mobilezhi_xunchen->addSkill("mobilezhijianzhan");

    General *mobilezhi_bianfuren = new General(this, "mobilezhi_bianfuren", "wei", 3, false);
    mobilezhi_bianfuren->addSkill(new MobileZhiWanwei);
    mobilezhi_bianfuren->addSkill(new MobileZhiYuejian);
    mobilezhi_bianfuren->addSkill(new MobileZhiYuejianMax);
    related_skills.insertMulti("mobilezhiyuejian", "#mobilezhiyuejian-max");

    General *mobilezhi_feiyi = new General(this, "mobilezhi_feiyi", "shu", 3);
    mobilezhi_feiyi->addSkill(new MobileZhiJianyu);
    mobilezhi_feiyi->addSkill(new MobileZhiShengxi);

    General *mobilezhi_luotong = new General(this, "mobilezhi_luotong", "wu", 4);
    mobilezhi_luotong->addSkill(new MobileZhiQinzheng);
    mobilezhi_luotong->addSkill(new MobileZhiQinzhengClear);
    related_skills.insertMulti("mobilezhiqinzheng", "#mobilezhiqinzheng-clear");

    General *mobilezhi_duyu = new General(this, "mobilezhi_duyu", "qun", 4);
    mobilezhi_duyu->addSkill(new MobileZhiWuku);
    mobilezhi_duyu->addSkill(new MobileZhiSanchen);
    mobilezhi_duyu->addRelateSkill("mobilezhimiewu");

    skills << new MobileZhiMiewu;

    addMetaObject<MobileZhiQiaiCard>();
    addMetaObject<MobileZhiShamengCard>();
    addMetaObject<SecondMobileZhiZuiciCard>();
    addMetaObject<SecondMobileZhiZuiciMarkCard>();
    addMetaObject<MobileZhiDuojiCard>();
    addMetaObject<MobileZhiJianzhanCard>();
    addMetaObject<SecondMobileZhiDuojiCard>();
    addMetaObject<SecondMobileZhiDuojiRemove>();
    addMetaObject<MobileZhiWanweiCard>();
    addMetaObject<MobileZhiJianyuCard>();
    addMetaObject<MobileZhiMiewuCard>();
}

ADD_PACKAGE(MobileZhi)
