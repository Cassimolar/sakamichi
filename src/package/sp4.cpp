#include "sp4.h"
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
#include "wind.h"
#include "json.h"

Meirenji::Meirenji(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("__meirenji");
    damage_card = true;
}

bool Meirenji::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    return targets.length() < total_num && to_select->isMale() && !to_select->isKongcheng() && to_select != Self;
}

void Meirenji::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    foreach (ServerPlayer *p, room->getAllPlayers()) {
        if (effect.to->isDead() || effect.to->isKongcheng()) break;
        if (p->isDead() || !p->isFemale()) continue;
        int id = room->askForCardChosen(p, effect.to, "h", objectName());
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, p->objectName());
        room->obtainCard(p, Sanguosha->getCard(id), reason, false);
        if (p->isAlive() && effect.from->isAlive() && !p->isKongcheng()) {
            const Card *card = room->askForCard(p, ".|.|.|hand", "@__meirenji-give:" + effect.from->objectName(),
                                                QVariant::fromValue(effect.from), Card::MethodNone);
            room->giveCard(p, effect.from, card, objectName());
        }
    }
    if (effect.from->isDead() || effect.to->isDead()) return;
    if (effect.from->getHandcardNum() > effect.to->getHandcardNum())
        room->damage(DamageStruct(this, effect.to, effect.from));
    else if (effect.from->getHandcardNum() < effect.to->getHandcardNum())
        room->damage(DamageStruct(this, effect.from, effect.to));
}

Xiaolicangdao::Xiaolicangdao(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("__xiaolicangdao");
    damage_card = true;
}

bool Xiaolicangdao::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    return targets.length() < total_num && to_select != Self;
}

void Xiaolicangdao::onEffect(const CardEffectStruct &effect) const
{
    effect.to->drawCards(qMin(5, effect.to->getLostHp()), objectName());
    if (effect.to->isDead()) return;
    effect.to->getRoom()->damage(DamageStruct(this, effect.from->isAlive() ? effect.from : NULL, effect.to));
}

class JingongViewAsSkill : public OneCardViewAsSkill
{
public:
    JingongViewAsSkill(const QString &name) : OneCardViewAsSkill(name), name(name)
    {
        response_or_use = true;
        filter_pattern = "EquipCard,Slash";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        const Card *c = Self->tag.value(name).value<const Card *>();
        if (!c || !c->isAvailable(Self) || Self->isCardLimited(c, Card::MethodUse)) return NULL;
        Card *card = Sanguosha->cloneCard(c->objectName());
        card->setCanRecast(false);
        card->addSubcard(originalCard);
        card->setSkillName(name);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark(name + "-PlayClear") <= 0;
    }

private:
    QString name;
};

class JingongSkill : public TriggerSkill
{
public:
    JingongSkill(const QString &name) : TriggerSkill(name), name(name)
    {
        events << EventPhaseStart << EventAcquireSkill << PreCardUsed;
        view_as_skill = new JingongViewAsSkill(name);
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance(name, false, true, true, false, true);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() == Player::Finish) {
                if (name != "jingong") return false;
                if (player->getMark("damage_point_round") > 0) return false;
                int mark = player->getMark(name + "_used-Clear");
                if (mark <= 0) return false;

                for (int i = 0; i < mark; i++) {
                    if (player->isDead()) break;

                    LogMessage log;
                    log.type = "#ZhenguEffect";
                    log.from = player;
                    log.arg = objectName();
                    room->sendLog(log);

                    room->loseHp(player);
                }
            }

            if (!player->hasSkill(this, true)) return false;
            if (player->getPhase() != Player::Play)
                return false;
        } else if (event == EventAcquireSkill) {
            if (data.toString() != name)
                return false;
        } else if (event == PreCardUsed) {
            if (!player->hasSkill(this, true)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isNDTrick() && use.card->getSkillName() == name) {
                room->addPlayerMark(player, name + "-PlayClear");
                room->addPlayerMark(player, name + "_used-Clear");
                return false;
            }
        }

        QStringList card_names, tricks;
        QList<const TrickCard*> all_tricks = Sanguosha->findChildren<const TrickCard *>();
        foreach (const TrickCard *card, all_tricks) {
            QString name = card->objectName();
            if (name.startsWith("_")) continue;
            if (!ServerInfo.Extensions.contains("!" + card->getPackage()) && card->isNDTrick()
                && !tricks.contains(card->objectName()) && !card->isKindOf("Nullification"))
                tricks << name;
        }
        qShuffle(tricks);
        foreach (QString name, tricks) {
            card_names.append(name);
            if (card_names.length() >= 2) break;
        }
        int n = qrand() % 2;
        if (n == 0)
            card_names << "__meirenji";
        else
            card_names << "__xiaolicangdao";

        QString property_name = name + "_tricks";
        room->setPlayerProperty(player, property_name.toStdString().c_str(), card_names.join("+"));
        return false;
    }

private:
    QString name;
};

TenyearLianjiCard::TenyearLianjiCard()
{
}

void TenyearLianjiCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.to->hasWeaponArea()) return;
    Room *room = effect.from->getRoom();
    QList<const Card *> weapons;
    foreach (int id, room->getDrawPile()) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->isKindOf("Weapon")) continue;
        if (!effect.to->canUse(card)) continue;
        weapons << card;
    }
    if (weapons.isEmpty()) return;

    const Card *weapon = weapons.at(qrand() % weapons.length());
    room->useCard(CardUseStruct(weapon, effect.to, effect.to));

    if (effect.to->isDead()) return;

    effect.to->tag["tenyearlianji_weapon"] = QVariant::fromValue(weapon); //FOR AI
    CardUseStruct use = room->askForUseSlashToStruct(effect.to, room->getOtherPlayers(effect.from),
                                                     "@tenyearlianji-slash:" + effect.from->objectName());
    effect.to->tag.remove("tenyearlianji_weapon");

    if (use.card) {
        room->addPlayerMark(effect.from, "tenyearlianji_choice_1");
        if (effect.to->isDead() || !effect.to->hasCard(weapon)) return;
        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, use.to) {
            if (!room->getAlivePlayers().contains(p)) continue;
            tos << p;
        }
        if (tos.isEmpty()) return;
        ServerPlayer *to = room->askForPlayerChosen(effect.to, tos, "tenyearlianji", "@tenyearlianji-give:" + weapon->objectName());
        room->giveCard(effect.to, to, weapon, "tenyearlianji", true);
    } else {
        room->addPlayerMark(effect.from, "tenyearlianji_choice_2");
        if (effect.from->isDead() || effect.to->isDead()) return;
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("_tenyearlianji");
        slash->deleteLater();
        if (effect.from->canUse(slash, effect.to))
            room->useCard(CardUseStruct(slash, effect.from, effect.to));
        if (effect.to->isAlive() && effect.to->hasCard(weapon) && effect.from->isAlive())
            room->giveCard(effect.to, effect.from, weapon, "tenyearlianji", true);
    }
}

class TenyearLianji : public OneCardViewAsSkill
{
public:
    TenyearLianji() : OneCardViewAsSkill("tenyearlianji")
    {
        filter_pattern = ".|.|.|hand!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearLianjiCard");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        TenyearLianjiCard *card = new TenyearLianjiCard;
        card->addSubcard(originalcard);
        return card;
    }
};

class TenyearMoucheng : public PhaseChangeSkill
{
public:
    TenyearMoucheng() : PhaseChangeSkill("tenyearmoucheng")
    {
        frequency = Wake;
        waked_skills = "tenyearjingong";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        return player->getMark("tenyearlianji_choice_1") >0 && player->getMark("tenyearlianji_choice_2") > 0;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->doSuperLightbox("tenyear_wangyun", "tenyearmoucheng");
        room->setPlayerMark(player, "tenyearmoucheng", 1);

        if (room->changeMaxHpForAwakenSkill(player, 0))
            room->handleAcquireDetachSkills(player, "-tenyearlianji|tenyearjingong");
        return false;
    }
};

OLLianjiCard::OLLianjiCard()
{
}

void OLLianjiCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.to->hasWeaponArea()) return;
    Room *room = effect.from->getRoom();
    QList<const Card *> weapons;
    foreach (int id, room->getDrawPile()) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->isKindOf("Weapon")) continue;
        if (!effect.to->canUse(card)) continue;
        weapons << card;
    }
    if (weapons.isEmpty()) return;

    const Card *weapon = weapons.at(qrand() % weapons.length());
    room->useCard(CardUseStruct(weapon, effect.to, effect.to));

    if (effect.to->isDead() || effect.from->isDead()) return;
    QList<ServerPlayer *> tos;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.to)) {
        if (effect.to->canSlash(p, NULL, true))
            tos << p;
    }
    if (tos.isEmpty()) return;

    ServerPlayer *to = room->askForPlayerChosen(effect.from, tos, "ollianji", "@ollianji-target:" + effect.to->objectName());
    LogMessage log;
    log.type = "#CollateralSlash";
    log.from = effect.from;
    log.to << to;
    room->sendLog(log);
    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, effect.to->objectName(), to->objectName());

    effect.to->tag["ollianji_weapon"] = QVariant::fromValue(weapon); //FOR AI

    if (room->askForUseSlashTo(effect.to, to, "@ollianji-slash:" + to->objectName(), true, false, false, effect.from, this,
                               "ollianji_slash_" + effect.from->objectName()))
        effect.to->tag.remove("ollianji_weapon");
    else {
        effect.to->tag.remove("ollianji_weapon");
        if (effect.from->isDead() || effect.to->isDead() || !effect.to->getWeapon()) return;

        const Card *weapon2 = Sanguosha->getCard(effect.to->getWeapon()->getEffectiveId());

        effect.from->tag["ollianji_give_weapon"] = QVariant::fromValue(weapon2); //FOR AI
        ServerPlayer *give = room->askForPlayerChosen(effect.from, room->getAlivePlayers(), "ollianji_give",
                                                      "@ollianji-give:" + weapon->objectName());
        effect.from->tag.remove("ollianji_give_weapon");
        room->giveCard(effect.from, give, weapon2, "ollianji", true);
    }

}

class OLLianji : public OneCardViewAsSkill
{
public:
    OLLianji() : OneCardViewAsSkill("ollianji")
    {
        filter_pattern = ".|.|.|hand!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("OLLianjiCard");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        OLLianjiCard *card = new OLLianjiCard;
        card->addSubcard(originalcard);
        return card;
    }
};

class OLMoucheng : public PhaseChangeSkill
{
public:
    OLMoucheng() : PhaseChangeSkill("olmoucheng")
    {
        frequency = Wake;
        waked_skills = "tenyearjingong";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMark("&ollianji") >= 3) {
            LogMessage log;
            log.type = "#OLMouchengWake";
            log.from = player;
            log.arg = QString::number(player->getMark("&ollianji"));
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());

        room->doSuperLightbox("ol_wangyun", "olmoucheng");
        room->setPlayerMark(player, "olmoucheng", 1);

        if (room->changeMaxHpForAwakenSkill(player, 0))
            room->handleAcquireDetachSkills(player, "-ollianji|tenyearjingong");
        return false;
    }
};

class OLMouchengUse : public TriggerSkill
{
public:
    OLMouchengUse() : TriggerSkill("#olmoucheng-use")
    {
        events << PreCardUsed;
        //frequency = Wake;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!data.value<CardUseStruct>().card->isKindOf("OLLianjiCard")) return false;
        if (!player->hasSkill("ollianji", true)) return false;
        room->addPlayerMark(player, "&ollianji");
        return false;
    }
};

class SecondOLMoucheng : public PhaseChangeSkill
{
public:
    SecondOLMoucheng() : PhaseChangeSkill("secondolmoucheng")
    {
        frequency = Wake;
        waked_skills = "tenyearjingong";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMark("&ollianjidamage") <= 0) return false;
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->setPlayerMark(player, "&ollianjidamage", 0);
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);

        room->doSuperLightbox("second_ol_wangyun", "secondolmoucheng");
        room->setPlayerMark(player, "secondolmoucheng", 1);

        if (room->changeMaxHpForAwakenSkill(player, 0))
            room->handleAcquireDetachSkills(player, "-ollianji|tenyearjingong");
        return false;
    }
};

class SecondOLMouchengDamage : public TriggerSkill
{
public:
    SecondOLMouchengDamage() : TriggerSkill("#secondolmoucheng-damage")
    {
        events << DamageDone;
        //frequency = Wake;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash")) {
            foreach (QString flag, damage.card->getFlags()) {
                if (!flag.startsWith("ollianji_slash_")) continue;
                QString name = flag.split("_").last();
                ServerPlayer *player = room->findChild<ServerPlayer *>(name);
                if (player && player->isAlive() && player->hasSkill("secondolmoucheng", true))
                    room->setPlayerMark(player, "&ollianjidamage", 1);
            }
        }
        return false;
    }
};

MobileLianjiCard::MobileLianjiCard()
{
}

bool MobileLianjiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < 2 && to_select != Self;
}

bool MobileLianjiCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void MobileLianjiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    QVariant data = QVariant::fromValue(use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();

    LogMessage log;
    log.from = card_use.from;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    thread->trigger(CardUsed, room, card_use.from, data);
    use = data.value<CardUseStruct>();
    thread->trigger(CardFinished, room, card_use.from, data);
}

void MobileLianjiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *first = targets.first(), *second = targets.last();
    QList<const Card *> weapons;
    foreach (int id, room->getDrawPile()) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->isKindOf("Weapon")) continue;
        if (!first->canUse(card)) continue;
        weapons << card;
    }
    if (weapons.isEmpty()) return;

    const Card *weapon = weapons.at(qrand() % weapons.length());
    room->useCard(CardUseStruct(weapon, first, first));

    if (first->isDead() || second->isDead()) return;

    QStringList names;
    names << "duel" << "savage_assault" << "archery_attack" << "slash";
    if (!Config.BanPackages.contains("maneuvering"))
        names << "fire_attack";

    QList<Card *> cards;
    foreach (QString name, names) {
        Card *card = Sanguosha->cloneCard(name);
        if (!card) continue;
        card->setSkillName("_mobilelianji");
        card->deleteLater();
        if (!first->canUse(card, second, true)) continue;
        cards << card;
    }
    if (cards.isEmpty()) return;

    Card *card = cards.at(qrand() % cards.length());
    room->setCardFlag(card, "mobilelianji_card_" + source->objectName());
    room->useCard(CardUseStruct(card, first, second));
}

class MobileLianjiVS : public ZeroCardViewAsSkill
{
public:
    MobileLianjiVS() : ZeroCardViewAsSkill("mobilelianji")
    {
    }

    const Card *viewAs() const
    {
        return new MobileLianjiCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileLianjiCard");
    }
};

class MobileLianji : public TriggerSkill
{
public:
    MobileLianji() : TriggerSkill("mobilelianji")
    {
        events << CardFinished << DamageDone;
        view_as_skill = new MobileLianjiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card) return false;
            foreach (QString flag, damage.card->getFlags()) {
                if (!flag.startsWith("mobilelianji_card_")) continue;
                int n = room->getTag("mobilelianji_card_damage_point_" + damage.card->toString()).toInt();
                n += damage.damage;
                room->setTag("mobilelianji_card_damage_point_" + damage.card->toString(), n);
                break;
            }
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            foreach (QString flag, use.card->getFlags()) {
                if (!flag.startsWith("mobilelianji_card_")) continue;

                int n = room->getTag("mobilelianji_card_damage_point_" + use.card->toString()).toInt();
                room->removeTag("mobilelianji_card_damage_point_" + use.card->toString());
                if (n <= 0) break;

                QString name = flag.split("_").last();
                ServerPlayer *source = room->findChild<ServerPlayer *>(name);
                if (!source || source->isDead()) break;

                source->gainMark("&mobilelianji", n);
                break;
            }
        }
        return false;
    }
};

class MobileMoucheng : public TriggerSkill
{
public:
    MobileMoucheng() : TriggerSkill("mobilemoucheng")
    {
        events << Damage;
        frequency = Wake;
        waked_skills = "jingong";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool canWake(TriggerEvent, ServerPlayer *, QVariant &, Room *) const
    {
        return true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || p->getMark(objectName()) > 0) continue;
            if (!p->canWake(objectName()) && p->getMark("&mobilelianji") <= 2) continue;

            LogMessage log;
            log.type = "#MobileMouchengWake";
            log.from = p;
            log.arg = QString::number(p->getMark("&mobilelianji"));
            log.arg2 = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(p, objectName());
            room->broadcastSkillInvoke(objectName());

            room->setPlayerMark(p, "&mobilelianji", 0);

            room->doSuperLightbox("mobile_wangyun", "mobilemoucheng");
            room->setPlayerMark(p, "mobilemoucheng", 1);

            if (room->changeMaxHpForAwakenSkill(p, 0))
                room->handleAcquireDetachSkills(p, "-mobilelianji|jingong");
        }
        return false;
    }
};

class NewTunchu : public DrawCardsSkill
{
public:
    NewTunchu() : DrawCardsSkill("newtunchu")
    {
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        if (player->getPile("food").isEmpty() && player->askForSkillInvoke("newtunchu")) {
            player->setFlags("newtunchu");
            player->getRoom()->broadcastSkillInvoke("newtunchu");
            return n + 2;
        }
        return n;
    }
};

class NewTunchuPut : public TriggerSkill
{
public:
    NewTunchuPut() : TriggerSkill("#newtunchu-put")
    {
        events << AfterDrawNCards;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->hasFlag("newtunchu");
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->hasFlag("newtunchu") && !player->isKongcheng()) {
            const Card *c = room->askForExchange(player, "newtunchu", 999, 1, false, "@newtunchu-put", true);
            if (c != NULL) {
                player->addToPile("food", c);
                delete c;
            }
        }
        return false;
    }
};

class NewTunchuLimit : public CardLimitSkill
{
public:
    NewTunchuLimit() : CardLimitSkill("#newtunchu-limit")
    {
    }

    QString limitList(const Player *target) const
    {
        if (target->hasSkill("newtunchu") && !target->getPile("food").isEmpty())
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->hasSkill("newtunchu") && !target->getPile("food").isEmpty())
            return "Slash";
        else
            return QString();
    }
};

NewShuliangCard::NewShuliangCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void NewShuliangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    CardMoveReason r(CardMoveReason::S_REASON_REMOVE_FROM_PILE, source->objectName(), "newshuliang", QString());
    room->moveCardTo(this, NULL, Player::DiscardPile, r, true);
}

class NewShuliangVS : public OneCardViewAsSkill
{
public:
    NewShuliangVS() : OneCardViewAsSkill("newshuliang")
    {
        response_pattern = "@@newshuliang";
        filter_pattern = ".|.|.|food";
        expand_pile = "food";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        NewShuliangCard *c = new NewShuliangCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class NewShuliang : public PhaseChangeSkill
{
public:
    NewShuliang() : PhaseChangeSkill("newshuliang")
    {
        view_as_skill = new NewShuliangVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Finish && target->getHandcardNum() < target->getHp();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || p->getPile("food").isEmpty()) continue;
            if (!room->askForUseCard(p, "@@newshuliang", "@newshuliang:" + player->objectName(), -1, Card::MethodNone)) continue;
            player->drawCards(2, objectName());
        }
        return false;
    }
};

class NewTianming : public TriggerSkill
{
public:
    NewTianming() : TriggerSkill("newtianming")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.contains(player) && use.card->isKindOf("Slash") && room->askForSkillInvoke(player, objectName())) {
            room->broadcastSkillInvoke(objectName(), 1);
            room->askForDiscard(player, objectName(), 2, 2, false, true);
            player->drawCards(2, objectName());

            int max = -1000;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getHp() > max)
                    max = p->getHp();
            }
            if (player->getHp() == max)
                return false;

            QList<ServerPlayer *> maxs;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getHp() == max)
                    maxs << p;
                if (maxs.size() > 1)
                    return false;
            }
            ServerPlayer *mosthp = maxs.first();
            if (room->askForSkillInvoke(mosthp, objectName())) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), mosthp->objectName());
                int index = 2;
                if (mosthp->isFemale())
                    index = 3;
                room->broadcastSkillInvoke(objectName(), index);
                room->askForDiscard(mosthp, objectName(), 2, 2, false, true);
                mosthp->drawCards(2, objectName());
            }
        }

        return false;
    }
};

GuanxuCard::GuanxuCard()
{
}

bool GuanxuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void GuanxuCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isKongcheng()) return;
    Room *room = effect.from->getRoom();
    QList<int> drawpile = room->getNCards(5, false), hands = effect.to->handCards(), _drawpile;
    room->returnToTopDrawPile(drawpile);

    foreach (int id, drawpile) //调整顺序
        _drawpile.prepend(id);

    LogMessage log;
    log.type = "$ViewAllCards";
    log.from = effect.from;
    log.to << effect.to;
    log.card_str = IntList2StringList(hands).join("+");
    room->sendLog(log);

    room->notifyMoveToPile(effect.from, hands, "guanxuhand", Player::PlaceHand, true);
    room->notifyMoveToPile(effect.from, _drawpile, "guanxudrawpile", Player::DrawPile, true);

    const Card *card = room->askForUseCard(effect.from, "@@guanxu1", "@guanxu1", 1, Card::MethodNone);

    room->notifyMoveToPile(effect.from, hands, "guanxuhand", Player::PlaceHand, false);
    room->notifyMoveToPile(effect.from, _drawpile, "guanxudrawpile", Player::DrawPile, false);

    if (!card || effect.to->isDead()) return;
    int hand_id = -1, drawpile_id = -1;
    foreach (int id, card->getSubcards()) {
        if (hands.contains(id))
            hand_id = id;
        else if (drawpile.contains(id))
            drawpile_id = id;
    }
    if (drawpile_id < 0 || hand_id < 0) return;

    int n = 1;
    foreach (int id, drawpile) {
        if (id == drawpile_id) break;
        n++;
    }

    room->obtainCard(effect.to, drawpile_id, false);
    room->moveCardsInToDrawpile(effect.to, hand_id, "guanxu", n);

    if (effect.from->isDead() || effect.to->isDead() || effect.to->getHandcardNum() < 3) return;

    QList<int> spade, club, heart, diamond, all;
    foreach (const Card *c, effect.to->getCards("h")) {
        if (c->getSuit() == Card::Spade)
            spade << c->getEffectiveId();
        if (c->getSuit() == Card::Club)
            club << c->getEffectiveId();
        if (c->getSuit() == Card::Heart)
            heart << c->getEffectiveId();
        if (c->getSuit() == Card::Diamond)
            diamond << c->getEffectiveId();
    }
    if (spade.length() >= 3)
        all += spade;
    if (club.length() >= 3)
        all += club;
    if (heart.length() >= 3)
        all += heart;
    if (diamond.length() >= 3)
        all += diamond;
    if (all.length() < 3) return;

    if (all.length() == 3) {
        DummyCard discard(all);
        room->throwCard(&discard, effect.to, effect.from);
        return;
    }

    room->notifyMoveToPile(effect.from, all, "guanxu", Player::PlaceHand, true);
    const Card *card2 = room->askForUseCard(effect.from, "@@guanxu2", "@guanxu2", 2, Card::MethodDiscard);
    room->notifyMoveToPile(effect.from, all, "guanxu", Player::PlaceHand, true);
    if (card2)
        room->throwCard(card2, effect.to, effect.from);
    else {
        int id = all.at(qrand() % all.length());
        Card::Suit suit = Sanguosha->getCard(id)->getSuit();
        QList<int> _discard;
        foreach (int id, all) {
            if (Sanguosha->getCard(id)->getSuit() != suit) continue;
            _discard << id;
            if (_discard.length() >= 3) break;
        }
        DummyCard discard(_discard);
        room->throwCard(&discard, effect.to, effect.from);
    }
}

GuanxuChooseCard::GuanxuChooseCard()
{
    target_fixed = true;
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
    m_skillName = "guanxu";
}

void GuanxuChooseCard::onUse(Room *, const CardUseStruct &) const
{
}

GuanxuDiscardCard::GuanxuDiscardCard()
{
    target_fixed = true;
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
    m_skillName = "guanxu";
}

void GuanxuDiscardCard::onUse(Room *, const CardUseStruct &) const
{
}

class Guanxu : public ViewAsSkill
{
public:
    Guanxu() : ViewAsSkill("guanxu")
    {
        expand_pile = "#guanxu,#guanxuhand,#guanxudrawpile";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            return false;
        } else {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern == "@@guanxu1") {
                if (selected.length() >= 2) return false;
                if (selected.isEmpty())
                    return Self->getPile("#guanxuhand").contains(to_select->getEffectiveId()) ||
                            Self->getPile("#guanxudrawpile").contains(to_select->getEffectiveId());
                else {
                    if (Self->getPile("#guanxuhand").contains(selected.first()->getEffectiveId()))
                        return Self->getPile("#guanxudrawpile").contains(to_select->getEffectiveId());
                    else
                        return Self->getPile("#guanxuhand").contains(to_select->getEffectiveId());
                }
            } else if (pattern == "@@guanxu2")
                return selected.length() < 3 && Self->getPile("#guanxu").contains(to_select->getEffectiveId());
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (!cards.isEmpty()) return NULL;
            return new GuanxuCard;
        } else {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern == "@@guanxu1") {
                if (cards.length() != 2) return NULL;
                GuanxuChooseCard *card = new GuanxuChooseCard;
                card->addSubcards(cards);
                return card;
            } else {
                if (cards.length() != 3) return NULL;
                GuanxuDiscardCard *card = new GuanxuDiscardCard;
                card->addSubcards(cards);
                return card;
            }
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("GuanxuCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@guanxu");
    }
};

class Yashi : public MasochismSkill
{
public:
    Yashi() : MasochismSkill("yashi")
    {
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        Room *room = player->getRoom();
        QStringList choices;
        if (damage.from && damage.from->isAlive())
            choices << "wuxiao=" + damage.from->objectName();
        GuanxuCard *card = new GuanxuCard;
        card->setSkillName("guanxu");
        card->deleteLater();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isKongcheng()|| player->isProhibited(p, card)) continue;
            choices << "guanxu";
            break;
        }

        if (choices.isEmpty() ||!player->askForSkillInvoke(this)) return;
        room->broadcastSkillInvoke(objectName());
        QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(damage));
        if (choice.startsWith("wuxiao")) {
            room->addPlayerMark(damage.from, "&yashi");

            foreach(ServerPlayer *p, room->getAllPlayers())
                room->filterCards(p, p->getCards("he"), true);

            JsonArray args;
            args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
        } else {
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isKongcheng() || player->isProhibited(p, card)) continue;
                targets << p;
            }
            if (targets.isEmpty()) return;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@yashi-guanxu");
            room->useCard(CardUseStruct(card, player, target), true);
        }
    }
};

class YashiClear : public PhaseChangeSkill
{
public:
    YashiClear() : PhaseChangeSkill("#yashi")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::RoundStart && target->getMark("&yashi") > 0;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        player->getRoom()->setPlayerMark(player, "&yashi", 0);

        foreach(ServerPlayer *p, room->getAllPlayers())
            room->filterCards(p, p->getCards("he"), false);

        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
        return false;
    }
};

class YashiInvalidity : public InvaliditySkill
{
public:
    YashiInvalidity() : InvaliditySkill("#yashi-invalidity")
    {
    }

    bool isSkillValid(const Player *player, const Skill *skill) const
    {
        return player->getMark("&yashi") == 0 || skill->getFrequency(player) == Skill::Compulsory ||
                skill->getFrequency(player) == Skill::Wake || skill->isAttachedLordSkill() || !skill->isVisible();
    }
};

class Zhente : public TriggerSkill
{
public:
    Zhente() : TriggerSkill("zhente")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("zhente-Clear") > 0) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player) || (!use.card->isRed() && !use.card->isBlack()) || use.from->isDead() || use.from == player) return false;
        if (!use.card->isKindOf("BasicCard") && !use.card->isNDTrick()) return false;

        player->tag["zhente_data"] = data;
        bool invoke = player->askForSkillInvoke(this, use.from);
        player->tag.remove("zhente_data");

        if (!invoke) return false;
        room->addPlayerMark(player, "zhente-Clear");
        room->broadcastSkillInvoke(objectName());

        use.from->tag["zhente_usefrom_data"] = data;
        QStringList choices;
        if (use.card->isRed())
            choices << "color=red";
        else
            choices << "color=black";
        choices << "wuxiao=" + player->objectName();
        QString choice = room->askForChoice(use.from, objectName(), choices.join("+"), QVariant::fromValue(player));
        use.from->tag.remove("zhente_usefrom_data");

        if (choice.startsWith("color")) {
            use.from->setMark("zhente_limit-Keep", 1);
            QString pattern = use.card->isRed() ? ".|red|.|." : ".|black|.|.";

            QStringList patterns = use.from->tag["zhente_limit"].toStringList();
            if (!patterns.contains(pattern)) {
                patterns << pattern;
                use.from->tag["zhente_limit"] = patterns;
            }

            room->setPlayerCardLimitation(use.from, "use", pattern, true);
        } else {
            use.nullified_list << player->objectName();
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class ZhenteClear : public TriggerSkill
{
public:
    ZhenteClear() : TriggerSkill("#zhente")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getAllPlayers(true)) {
            if (p->getMark("zhente_limit-Keep") <= 0) continue;
            p->setMark("zhente_limit-Keep", 0);

            QStringList patterns = p->tag["zhente_limit"].toStringList();
            if (patterns.isEmpty()) continue;

            foreach (QString pattern, patterns)
                room->removePlayerCardLimitation(p, "use", pattern + "$1");
        }
        return false;
    }
};

class Zhiwei : public TriggerSkill
{
public:
    Zhiwei() : TriggerSkill("zhiwei")
    {
        events << GameStart << EventPhaseEnd << EventPhaseStart << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GameStart) {
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@zhiwei-invoke", false, true);
            room->broadcastSkillInvoke(objectName());
            room->setPlayerMark(target, "&zhiwei+#" + player->objectName(), 1);
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getMark("&zhiwei+#" + player->objectName()) > 0)
                    return false;
            }
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@zhiwei-invoke2", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->setPlayerMark(target, "&zhiwei+#" + player->objectName(), 1);
        } else if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.from || move.from != player || player->getPhase() != Player::Discard) return false;
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                QVariantList discard = player->tag["ZhiweiDiscard"].toList();
                foreach (int id, move.card_ids) {
                    if (discard.contains(QVariant(id))) continue;
                    discard << id;
                }
                player->tag["ZhiweiDiscard"] = discard;
            }
        } else {
            if (player->getPhase() != Player::Discard) return false;
            QVariantList discard = player->tag["ZhiweiDiscard"].toList();
            player->tag.remove("ZhiweiDiscard");
            QList<int> list;
            foreach (QVariant id, discard) {
                int _id = id.toInt();
                if (!list.contains(_id) && room->getCardPlace(_id) == Player::DiscardPile)
                    list << _id;
            }
            if (list.isEmpty()) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMark("&zhiwei+#" + player->objectName()) <= 0) continue;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                DummyCard get(list);
                room->obtainCard(p, &get, true);
                break;
            }
        }
        return false;
    }
};

class ZhiweiEffect : public TriggerSkill
{
public:
    ZhiweiEffect() : TriggerSkill("#zhiwei")
    {
        events << Damage << Damaged;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == Damage) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->getMark("&zhiwei+#" + p->objectName()) <= 0 || p->isDead() || !p->hasSkill("zhiwei")) continue;
                room->sendCompulsoryTriggerLog(p, "zhiwei", true, true);
                p->drawCards(1, "zhiwei");
            }
        } else {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->getMark("&zhiwei+#" + p->objectName()) <= 0 || p->isDead() || !p->hasSkill("zhiwei")) continue;

                QList<int> can_discard;
                foreach (int id, p->handCards()) {
                    if (!p->canDiscard(p, id)) continue;
                    can_discard << id;
                }
                if (can_discard.isEmpty()) continue;

                room->sendCompulsoryTriggerLog(p, "zhiwei", true, true);
                int id = can_discard.at(qrand() % can_discard.length());
                room->throwCard(id, p, NULL);
            }
        }
        return false;
    }
};

SpCuoruiCard::SpCuoruiCard()
{
}

bool SpCuoruiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return !to_select->isKongcheng() && to_select != Self && targets.length() < Self->getHp();
}

void SpCuoruiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) return;
        if (p->isAlive() && !p->isKongcheng())
            room->cardEffect(this, source, p);
    }
}

void SpCuoruiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    int id = room->askForCardChosen(effect.from, effect.to, "h", "spcuorui");
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
    room->obtainCard(effect.from, Sanguosha->getCard(id), reason, false);
}

class SpCuoruiVS : public ZeroCardViewAsSkill
{
public:
    SpCuoruiVS() : ZeroCardViewAsSkill("spcuorui")
    {
        response_pattern = "@@spcuorui";
    }

    const Card *viewAs() const
    {
        return new SpCuoruiCard;
    }
};

class SpCuorui : public PhaseChangeSkill
{
public:
    SpCuorui() : PhaseChangeSkill("spcuorui")
    {
        view_as_skill = new SpCuoruiVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart || player->getHp() < 1 || player->getMark("spcuorui_round-Keep") != 1) return false;
        player->getRoom()->askForUseCard(player, "@@spcuorui", "@spcuorui");
        return false;
    }
};

class SpCuoruiRecord : public PhaseChangeSkill
{
public:
    SpCuoruiRecord() : PhaseChangeSkill("#spcuorui")
    {
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        player->getRoom()->addPlayerMark(player, "spcuorui_round-Keep");
        return false;
    }
};

class SpLiewei : public TriggerSkill
{
public:
    SpLiewei() : TriggerSkill("spliewei")
    {
        events << Dying;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (!dying.damage || !dying.damage->from || dying.damage->from != player || dying.who == player) return false;
        if (!room->hasCurrent()) return false;
        if (player->getMark("spliewei-Clear") >= player->getHp()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->addPlayerMark(player, "spliewei-Clear");
        room->broadcastSkillInvoke(objectName());
        player->drawCards(1, objectName());
        return false;
    }
};

SecondSpCuoruiCard::SecondSpCuoruiCard()
{
}

bool SecondSpCuoruiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return !to_select->isKongcheng() && to_select != Self && targets.length() < Self->getHp();
}

void SecondSpCuoruiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->doSuperLightbox("second_sp_niujin", "secondspcuorui");
    room->removePlayerMark(source, "@secondspcuoruiMark");
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) return;
        if (p->isAlive() && !p->isKongcheng())
            room->cardEffect(this, source, p);
    }
}

void SecondSpCuoruiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    int id = room->askForCardChosen(effect.from, effect.to, "h", "secondspcuorui");
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
    room->obtainCard(effect.from, Sanguosha->getCard(id), reason, false);
}

class SecondSpCuorui : public ZeroCardViewAsSkill
{
public:
    SecondSpCuorui() : ZeroCardViewAsSkill("secondspcuorui")
    {
        frequency = Limited;
        limit_mark = "@secondspcuoruiMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@secondspcuoruiMark") > 0 && player->getHp() > 0;
    }

    const Card *viewAs() const
    {
        return new SecondSpCuoruiCard;
    }
};

class SecondSpLiewei : public TriggerSkill
{
public:
    SecondSpLiewei() : TriggerSkill("secondspliewei")
    {
        events << Dying;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        player->drawCards(1, objectName());
        return false;
    }
};

TiansuanDialog *TiansuanDialog::getInstance(const QString &name, const QString &choices)
{
    static TiansuanDialog *instance;
    if (instance == NULL || instance->objectName() != name)
        instance = new TiansuanDialog(name, choices);

    return instance;
}

TiansuanDialog::TiansuanDialog(const QString &name, const QString &choices)
    : tiansuan_choices(choices)
{
    setObjectName(name);
    setWindowTitle(Sanguosha->translate(name));
    group = new QButtonGroup(this);

    button_layout = new QVBoxLayout;
    setLayout(button_layout);
    connect(group, SIGNAL(buttonClicked(QAbstractButton *)), this, SLOT(selectChoice(QAbstractButton *)));
}

bool TiansuanDialog::MarkJudge(const QString &choice)
{
    bool judge = true;
    QString mark = objectName() + "_tiansuan_remove_" + choice;
    foreach (QString m, Self->getMarkNames()) {
        if (m.startsWith(mark) && Self->getMark(m) > 0) {
            judge = false;
            break;
        }
    }
    return judge;
}

void TiansuanDialog::popup()
{
    Self->tag.remove(objectName());
    foreach (QAbstractButton *button, group->buttons()) {
        button_layout->removeWidget(button);
        group->removeButton(button);
        delete button;
    }

    QStringList choices;
    if (objectName() == "tiansuan") {
        for (int i = 0; i < 6; i++)
            choices << QString::number(i);
    } else if (objectName() == "olsanyao") {
        if (Self->getMark("olsanyao_hp-PlayClear") <= 0)
            choices << "hp";
        if (Self->getMark("olsanyao_hand-PlayClear") <= 0)
            choices << "hand";
    } else if (objectName() == "tenyearjiaozhao") {
        int level = Self->property("tenyearjiaozhao_level").toInt();
        int basic = Self->getMark("tenyearjiaozhao_basic-Clear") - 1;
        int trick = Self->getMark("tenyearjiaozhao_trick-Clear") - 1;
        QString bname = Self->property("tenyearjiaozhao_basic_name").toString();
        QString tname = Self->property("tenyearjiaozhao_trick_name").toString();

        bool play = Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY;
        if (level < 2) {
            if (!Self->hasUsed("TenyearJiaozhaoCard") && play)
                choices << "show";
            if (basic >= 0)
                choices << "use=" + bname;
            else if (trick >= 0)
                choices << "use=" + tname;
        } else {
            if (play && (basic < 0 || trick < 0))
                choices << "show";
            if (basic >= 0)
                choices << "basic=" + bname;
            if (trick >= 0)
                choices << "trick=" + tname;
        }
    } else {
        if (tiansuan_choices.isEmpty()) return;
        QStringList tiansuan_choices_list = tiansuan_choices.split(",");
        foreach (QString choice, tiansuan_choices_list) {
            if (choice.isEmpty() || !MarkJudge(choice)) continue;
            choices << choice;
        }
    }

    if (choices.isEmpty()) return;
    foreach (QString choice, choices) {
        QAbstractButton *button = createChoiceButton(choice);
        button->setEnabled(true);
        button_layout->addWidget(button);
    }

    exec();
}

void TiansuanDialog::selectChoice(QAbstractButton *button)
{
    Self->tag[objectName()] = button->objectName();
    emit onButtonClick();
    accept();
}

QAbstractButton *TiansuanDialog::createChoiceButton(const QString &choice)
{

    QString name = choice.split("=").last();
    QString _choice = objectName() + ":" + choice.split("=").first();
    QString translate = Sanguosha->translate(_choice);
    if (!name.isEmpty())
        translate.replace("%src", Sanguosha->translate(name));

    QCommandLinkButton *button = new QCommandLinkButton(translate);
    button->setObjectName(choice);

    QString effect = Sanguosha->translate(_choice + ":effect");
    if (effect != _choice + ":effect")
        button->setToolTip(effect);

    group->addButton(button);
    return button;
}

TiansuanCard::TiansuanCard()
{
    //target_fixed = true;  源码bug不得已而为之
}

bool TiansuanCard::targetFilter(const QList<const Player *> &, const Player *, const Player *) const
{
    return false;
}

bool TiansuanCard::targetsFeasible(const QList<const Player *> &, const Player *) const
{
    return true;
}

void TiansuanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->addPlayerMark(source, "tiansuan_lun");
    room->setEmotion(source, "chouqian");

    QString choice = user_string;
    QList<int> mingyunqians;
    int num = -1;
    if (!choice.isEmpty())
        num = choice.split(":").last().toInt();
    if (num > 0)
        mingyunqians << num;
    mingyunqians << 1 << 2 << 3 << 4 << 5;

    int mingyunqian = mingyunqians.at(qrand() % mingyunqians.length());

    LogMessage log;
    log.from = source;
    log.type = "#TiansuanMingyunqian";
    log.arg = "tiansuan" + QString::number(mingyunqian);
    room->sendLog(log);

    ServerPlayer *target = room->askForPlayerChosen(source, room->getAlivePlayers(), "tiansuan", "@tiansuan-mingyunqian:" + log.arg, false);
    room->doAnimate(1, source->objectName(), target->objectName());

    log.type = "#TiansuanMingyunqianTarget";
    log.to << target;
    room->sendLog(log);

    room->addPlayerMark(target, "&" + log.arg + "+#" + source->objectName());

    if (mingyunqian == 1) {
        room->doGongxin(source, target, QList<int>(), "tiansuan");
        QString flags = "hej";
        if (source == target)
            flags = "ej";
        if (target->getCards(flags).isEmpty()) return;
        int id = room->askForCardChosen(source, target, flags, "tiansuan", true);
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
        room->obtainCard(source, Sanguosha->getCard(id), reason);
    } else if (mingyunqian == 2) {
        QString flags = "he";
        if (source == target)
            flags = "e";
        if (target->getCards(flags).isEmpty()) return;
        int id = room->askForCardChosen(source, target, flags, "tiansuan");
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
        room->obtainCard(source, Sanguosha->getCard(id), reason);
    } else if (mingyunqian == 5)
        room->setPlayerCardLimitation(target, "use", "Peach,Analeptic", false);

}

class TiansuanVS : public ZeroCardViewAsSkill
{
public:
    TiansuanVS() : ZeroCardViewAsSkill("tiansuan")
    {
    }

    const Card *viewAs() const
    {
        QString choice = Self->tag["tiansuan"].toString();
        if (choice.isEmpty()) return NULL;
        TiansuanCard *card = new TiansuanCard;
        card->setUserString(choice);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("tiansuan_lun") <= 0;
    }
};

class Tiansuan : public TriggerSkill
{
public:
    Tiansuan() : TriggerSkill("tiansuan")
    {
        events << Death << EventPhaseStart;
        view_as_skill = new TiansuanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    void removeMingyunqian(ServerPlayer *player, ServerPlayer *player2) const
    {
        Room *room = player->getRoom();
        foreach (QString mark, player->getMarkNames()) {
            if (player->getMark(mark) <= 0) continue;
            if (mark.startsWith("&tiansuan") && mark.endsWith("+#" + player2->objectName()))
                room->setPlayerMark(player, mark, 0);
        }

        bool limit = false;
        foreach (QString mark, player->getMarkNames()) {
            if (player->getMark(mark) <= 0) continue;
            if (mark.startsWith("&tiansuan5")) {
                limit = true;
                break;
            }
        }
        if (!limit)
            room->removePlayerCardLimitation(player, "use", "Peach,Analeptic");
    }

    QDialog *getDialog() const
    {
        return TiansuanDialog::getInstance("tiansuan");
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death) {
            ServerPlayer *who = data.value<DeathStruct>().who;
            foreach (ServerPlayer *p, room->getAllPlayers())
                removeMingyunqian(p, who);

            foreach (QString mark, who->getMarkNames()) {
                if (who->getMark(mark) <= 0) continue;
                if (mark.startsWith("&tiansuan5"))
                    room->removePlayerCardLimitation(who, "use", "Peach,Analeptic");
            }
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            foreach (ServerPlayer *p, room->getAllPlayers())
                removeMingyunqian(p, player);
        }
        return false;
    }
};

class TiansuanEffect : public TriggerSkill
{
public:
    TiansuanEffect() : TriggerSkill("#tiansuan")
    {
        events << DamageInflicted << Damaged;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    int MingyunqianNum(ServerPlayer *player, int i) const
    {
        int num = 0;
        foreach (QString mark, player->getMarkNames()) {
            if (player->getMark(mark) <= 0) continue;
            if (mark.startsWith("&tiansuan" + QString::number(i)))
                num++;
        }
        return num;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();

        LogMessage log;
        log.from = player;

        if (event == DamageInflicted) {
            if (MingyunqianNum(player, 1) > 0) {
                log.type = "#TiansuanMingyunqianEffect1";
                log.arg = "tiansuan1";
                log.arg2 = QString::number(damage.damage);
                room->sendLog(log);
                return true;
            }

            if (MingyunqianNum(player, 2) > 0) {
                log.type = "#TiansuanMingyunqianEffect2";
                log.arg = "tiansuan2";
                log.arg2 = QString::number(damage.damage);
                room->sendLog(log);
                damage.damage = 1;
            }

            if (MingyunqianNum(player, 3) > 0) {
                log.type = "#TiansuanMingyunqianEffect3";
                log.arg = "tiansuan3";
                room->sendLog(log);
                damage.nature = DamageStruct::Fire;
                if (damage.damage > 1)
                    damage.damage = 1;
            }

            for (int i = 0; i < MingyunqianNum(player, 4); i++) {
                log.type = "#TiansuanMingyunqianEffect4";
                log.arg = "tiansuan4";
                room->sendLog(log);
                ++damage.damage;
            }

            for (int i = 0; i < MingyunqianNum(player, 5); i++) {
                log.type = "#TiansuanMingyunqianEffect4";
                log.arg = "tiansuan4";
                room->sendLog(log);
                ++damage.damage;
            }

            data = QVariant::fromValue(damage);
        } else {
            for (int i = 0; i < damage.damage * MingyunqianNum(player, 2); i ++)
                player->drawCards(1, "tiansuan");
        }
        return false;
    }
};

class Lulve : public PhaseChangeSkill
{
public:
    Lulve() : PhaseChangeSkill("lulve")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        int num = player->getHandcardNum();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isKongcheng() || p->getHandcardNum() >= num) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@lulve-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(this);

        if (target->isDead()) return false;
        QStringList choices;
        if (!target->isKongcheng())
            choices << "give=" + player->objectName();
        choices << "fanmian=" + player->objectName();

        QString choice = room->askForChoice(target, objectName(), choices.join("+"), QVariant::fromValue(player));

        if (choice.startsWith("give")) {
            room->giveCard(target, player, target->handCards(), objectName(), false);
            if (player->isAlive())
                player->turnOver();
        } else {
            target->turnOver();
            if (target->isDead() || player->isDead()) return false;
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_lulve");
            slash->deleteLater();
            if (!target->canSlash(player, slash, false)) return false;
            room->setCardFlag(slash, "YUANBEN");
            room->useCard(CardUseStruct(slash, target, player));
        }
        return false;
    }
};

class Zhuixi : public TriggerSkill
{
public:
    Zhuixi() : TriggerSkill("zhuixi")
    {
        events << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead()) return false;

        bool from = damage.from->faceUp();
        bool to = damage.to->faceUp();
        if (from == to) return false;

        QList<ServerPlayer *> players;
        if (damage.from->hasSkill(this))
            players << damage.from;
        if (damage.to->hasSkill(this))
            players << damage.to;
        room->sortByActionOrder(players);

        foreach (ServerPlayer *p, players) {
            room->sendCompulsoryTriggerLog(p, this);
            ++damage.damage;
        }
        data = QVariant::fromValue(damage);
        return false;
    }
};

class Wanggui : public TriggerSkill
{
public:
    Wanggui() : TriggerSkill("wanggui")
    {
        events << Damage << Damaged;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == Damage) {
            if (!room->hasCurrent() || player->getMark("wanggui-Clear") > 0) return false;
            QList<ServerPlayer *> targets;
            QString kingdom = player->getKingdom();
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getKingdom() != kingdom)
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@wanggui-damage", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(this, 1);
            room->addPlayerMark(player, "wanggui-Clear");
            room->damage(DamageStruct("wanggui", player, target));
        } else {
            QList<ServerPlayer *> targets;
            QString kingdom = player->getKingdom();
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getKingdom() == kingdom)
                    targets << p;
            }
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@wanggui-draw", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(this, 2);
            target->drawCards(1, objectName());
            if (target != player)
                player->drawCards(1, objectName());
        }
        return false;
    }
};

class Xibing : public TriggerSkill
{
public:
    Xibing() : TriggerSkill("xibing")
    {
        events << TargetSpecified;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Play && target->getRoom()->hasCurrent();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isBlack() || use.to.length() != 1) return false;
        if (use.card->isKindOf("Slash") || use.card->isNDTrick()) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) break;
                if (p->isDead() || !p->hasSkill(this) || p->getMark("xibing-Clear") > 0 || !p->askForSkillInvoke(this, player)) continue;
                room->broadcastSkillInvoke(this);
                room->addPlayerMark(p, "xibing-Clear");
                int draw_num = player->getHp() - player->getHandcardNum();
                if (draw_num <= 0) continue;
                player->drawCards(draw_num, objectName());
                room->setPlayerCardLimitation(player, "use", ".", true);
            }
        }
        return false;
    }
};

class Youyan : public TriggerSkill
{
public:
    Youyan() : TriggerSkill("youyan")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play && player->getPhase() != Player::Discard) return false;
        QString phase = QString::number(int(player->getPhase()));
        if (player->getMark("youyan-" + phase + "Clear") > 0) return false;

        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            if (move.from != player || !(move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip)))
                return false;
            if (move.to_place != Player::DiscardPile) return false;

            QList<Card::Suit> suits;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                    const Card *card = Sanguosha->getCard(move.card_ids.at(i));
                    if (!suits.contains(card->getSuit()))
                        suits << card->getSuit();
                }
            }
            if (suits.length() >= 4) return false;

            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(this);
            room->addPlayerMark(player, "youyan-" + phase + "Clear");

            QList<const Card *> cards;
            foreach (int id, room->getDrawPile()) {
                const Card *card = Sanguosha->getCard(id);
                if (suits.contains(card->getSuit())) continue;
                cards << card;
            }
            if (cards.isEmpty()) return false;

            DummyCard *dummy = new DummyCard;
            dummy->deleteLater();

            while (!cards.empty()) {
                const Card *card = cards.first();
                Card::Suit suit = card->getSuit();
                QList<const Card *> new_cards;
                foreach (const Card *c, cards) {
                    if (c->getSuit() != suit) continue;
                    new_cards << c;
                    cards.removeOne(c);
                }
                const Card *cd = new_cards.at(qrand() % new_cards.length());
                dummy->addSubcard(cd);
            }

            if (dummy->subcardsLength() == 0) return false;
            room->obtainCard(player, dummy, true);
        }
        return false;
    }
};

class Zhuihuan : public PhaseChangeSkill
{
public:
    Zhuihuan() : PhaseChangeSkill("zhuihuan")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(this);
        room->addPlayerMark(target, "&zhuihuan");
        return false;
    }
};

class ZhuihuanEffect : public TriggerSkill
{
public:
    ZhuihuanEffect() : TriggerSkill("#zhuihuan")
    {
        events << DamageDone << EventPhaseStart << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to->isDead() || damage.to->getMark("&zhuihuan") <= 0 || !damage.from) return false;
            QStringList names = damage.to->tag["zhuihuan_damage_from"].toStringList();
            if (names.contains(damage.from->objectName())) return false;
            names << damage.from->objectName();
            damage.to->tag["zhuihuan_damage_from"] = names;
        } else if (event == EventPhaseStart) {
            if (player->isDead() || player->getPhase() != Player::Start) return false;
            room->setPlayerMark(player, "&zhuihuan", 0);
            QStringList names = player->tag["zhuihuan_damage_from"].toStringList();
            player->tag.remove("zhuihuan_damage_from");

            bool effect = false;

            foreach (QString name, names) {
                ServerPlayer *p = room->findChild<ServerPlayer *>(name);
                if (!p || p->isDead()) continue;

                if (!effect) {
                    effect = true;
                    LogMessage log;
                    log.type = "#ZhenguEffect";
                    log.arg = "zhuihuan";
                    log.from = player;
                    room->sendLog(log);
                    room->broadcastSkillInvoke("zhuihuan");
                }

                if (p->getHp() > player->getHp())
                    room->damage(DamageStruct("zhuihuan", player, p, 2));
                else {
                    DummyCard *dummy = new DummyCard();
                    dummy->deleteLater();

                    QList<int> discards;
                    foreach (int id, p->handCards()) {
                        if (p->canDiscard(p, id))
                            discards << id;
                    }
                    for (int i = 0; i < 2; i++) {
                        if (discards.isEmpty()) break;
                        int id = discards.at(qrand() % discards.length());
                        discards.removeOne(id);
                        dummy->addSubcard(id);
                    }
                    if (dummy->subcardsLength() == 0) {
                        LogMessage log;
                        log.type = "#ZhuihuanCantDiscard";
                        log.from = p;
                        room->sendLog(log);
                    } else
                        room->throwCard(dummy, p, NULL);
                }
            }
        } else if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player) return false;
            death.who->tag.remove("zhuihuan_damage_from");
        }
        return false;
    }
};

class Kangge : public TriggerSkill
{
public:
    Kangge() : TriggerSkill("kangge")
    {
        events << EventPhaseStart << CardsMoveOneTime << Dying << Death;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getMark("jianjie_Round-Keep") != 1 || player->getPhase() != Player::RoundStart) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@kangge-target", false, true);
            room->broadcastSkillInvoke(this);
            room->setPlayerMark(target, "&kangge+#" + player->objectName(), 1);
        } else if (event == Dying) {
            if (player->getMark("kangge_lun") > 0) return false;
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who->getMark("&kangge+#" + player->objectName()) <= 0) return false;
            if (!player->askForSkillInvoke(this, dying.who)) return false;
            room->broadcastSkillInvoke(this);
            room->addPlayerMark(player, "kangge_lun");
            int recover_num = qMin(1 - dying.who->getHp(), dying.who->getMaxHp() - dying.who->getHp());
            room->recover(dying.who, RecoverStruct(player, NULL, recover_num));
        } else if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->getMark("&kangge+#" + player->objectName()) <= 0) return false;
            room->sendCompulsoryTriggerLog(player, this);
            player->throwAllHandCardsAndEquips();
            room->loseHp(player);
        } else {
            if (!room->hasCurrent() || player->getMark("kangge-Clear") > 0) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.to || move.to->getMark("&kangge+#" + player->objectName()) <= 0 || move.to->getPhase() != Player::NotActive) return false;
            if (!move.from_places.contains(Player::DrawPile) || move.reason.m_reason != CardMoveReason::S_REASON_DRAW) return false;
            int num = 0;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::DrawPile)
                    num++;
            }
            num = qMin(num, 3);
            if (num <= 0) return false;
            room->sendCompulsoryTriggerLog(player, this);
            room->addPlayerMark(player, "kangge-Clear");
            player->drawCards(num, objectName());
        }
        return false;
    }
};

class Jielie : public TriggerSkill
{
public:
    Jielie() : TriggerSkill("jielie")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from == player || damage.from->getMark("&kangge+#" + player->objectName()) > 0) return false;
        if (damage.damage <= 0) return false;
        player->tag["jielie_damage_data"] = data;
        bool invoke = player->askForSkillInvoke(this, "jielie:" + QString::number(damage.damage));
        player->tag.remove("jielie_damage_data");
        if (!invoke) return false;
        room->broadcastSkillInvoke(this);
        Card::Suit suit = room->askForSuit(player, objectName());
        LogMessage log;
        log.type = "#ChooseSuit";
        log.from = player;
        log.arg = Card::Suit2String(suit);
        room->sendLog(log);
        room->loseHp(player, damage.damage);
        if (player->isDead()) return true;
        QList<int> list, get;
        foreach (int id, room->getDiscardPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (card->getSuit() != suit) continue;
            list << id;
        }
        for (int i = 0; i < damage.damage; i++) {
            if (list.isEmpty()) break;
            int id = list.at(qrand() % list.length());
            list.removeOne(id);
            get << id;
        }
        if (get.isEmpty()) return true;
        DummyCard _get(get);
        room->obtainCard(player, &_get);
        return true;
    }
};

JuguanDialog *JuguanDialog::getInstance(const QString &object, const QString &card_names)
{
    static JuguanDialog *instance;
    if (instance == NULL || instance->objectName() != object)
        instance = new JuguanDialog(object, card_names);

    return instance;
}

JuguanDialog::JuguanDialog(const QString &object, const QString &card_names)
    : cards(card_names)
{
    setObjectName(object);
    setWindowTitle(Sanguosha->translate(object));
    group = new QButtonGroup(this);

    button_layout = new QVBoxLayout;
    setLayout(button_layout);
    connect(group, SIGNAL(buttonClicked(QAbstractButton *)), this, SLOT(selectCard(QAbstractButton *)));
}

bool JuguanDialog::MarkJudge(const QString &button_name) const
{
    bool judge = true;
    QString mark = objectName() + "_juguan_remove_" + button_name;
    foreach (QString m, Self->getMarkNames()) {
        if (m.startsWith(mark) && Self->getMark(m) > 0) {
            judge = false;
            break;
        }
    }
    return judge;
}

bool JuguanDialog::isButtonEnabled(const QString &button_name) const
{
    const Card *card = map[button_name];
    return !Self->isCardLimited(card, Card::MethodUse) && card->isAvailable(Self) && MarkJudge(button_name);
}

void JuguanDialog::popup()
{
    Self->tag.remove(objectName());
    foreach (QAbstractButton *button, group->buttons()) {
        button_layout->removeWidget(button);
        group->removeButton(button);
        delete button;
    }

    if (cards.isEmpty()) {
        emit onButtonClick();
        return;
    }

    QStringList names = cards.split(","), created;
    if (names.contains("all_slashs")) {
        names.removeOne("all_slashs");
        QStringList all_slashs = Sanguosha->getSlashNames();
        foreach (const QString name, all_slashs) {
            if (created.contains(name)) continue;
            created << name;
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->setSkillName(objectName());
            card->setParent(this);
            button_layout->addWidget(createButton(card));
        }
    }

    foreach (const QString name, names) {
        if (created.contains(name)) continue;
        created << name;
        Card *card = Sanguosha->cloneCard(name);
        if (!card) continue;
        card->setSkillName(objectName());
        card->setParent(this);
        button_layout->addWidget(createButton(card));
    }

    bool has_enabled_button = false;
    foreach (QAbstractButton *button, group->buttons()) {
        bool enabled = isButtonEnabled(button->objectName());
        if (enabled)
            has_enabled_button = true;
        button->setEnabled(enabled);
    }
    if (!has_enabled_button) {
        emit onButtonClick();
        return;
    }

    exec();
}

void JuguanDialog::selectCard(QAbstractButton *button)
{
    const Card *card = map.value(button->objectName());
    Self->tag[objectName()] = QVariant::fromValue(card);
    emit onButtonClick();
    accept();
}

QAbstractButton *JuguanDialog::createButton(const Card *card)
{
    QCommandLinkButton *button = new QCommandLinkButton(Sanguosha->translate(card->objectName()));
    button->setObjectName(card->objectName());
    button->setToolTip(card->getDescription());

    map.insert(card->objectName(), card);
    group->addButton(button);

    return button;
}

JuguanCard::JuguanCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodUse;
}

bool JuguanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *_card = Self->tag.value("juguan").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card->objectName());
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

void JuguanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QString str = getUserString();
    if (str.isEmpty()) return;
    Card *card = Sanguosha->cloneCard(str);
    if (!card) return;
    card->addSubcards(subcards);
    card->setSkillName("juguan");
    room->setCardFlag(card, "juguan:" + card_use.from->objectName());
    card->deleteLater();
    room->useCard(CardUseStruct(card, card_use.from, card_use.to), true);
}

class JuguanVS : public OneCardViewAsSkill
{
public:
    JuguanVS() : OneCardViewAsSkill("juguan")
    {
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        if (to_select->isEquipped()) return false;
        const Card *c = Self->tag.value("juguan").value<const Card *>();
        if (!c || !c->isAvailable(Self)) return false;
        Card *card = Sanguosha->cloneCard(c->objectName());
        if (!card) return false;
        card->addSubcard(to_select);
        card->setSkillName("juguan");
        card->deleteLater();
        return card->isAvailable(Self) && !Self->isLocked(card, true);
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JuguanCard") && !player->isKongcheng();
    }

    const Card *viewAs(const Card *originalCard) const
    {
        const Card *c = Self->tag.value("juguan").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            JuguanCard *card = new JuguanCard;
            card->addSubcard(originalCard);
            card->setUserString(c->objectName());
            return card;
        }
        return NULL;
    }
};

class Juguan : public TriggerSkill
{
public:
    Juguan() : TriggerSkill("juguan")
    {
        events << DamageDone << EventPhaseChanging << DrawNCards;
        view_as_skill = new JuguanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    QDialog *getDialog() const
    {
        return JuguanDialog::getInstance("juguan", "slash,duel");
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && (damage.card->isKindOf("Slash") || damage.card->isKindOf("Duel"))) {
                QString name;
                foreach (QString flag, damage.card->getFlags()) {
                    if (!flag.startsWith("juguan:")) continue;
                    QStringList flags = flag.split(":");
                    if (flags.length() != 2) continue;
                    name = flags.last();
                    break;
                }
                if (name.isEmpty()) return false;

                if (damage.from && damage.from->isAlive())
                    room->addPlayerMark(damage.to, "&juguan+#" + name + "-Keep");
            }
            if (damage.from)
                room->setPlayerMark(damage.from, "&juguan+#" + damage.to->objectName() + "-Keep", 0);
        } else if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::RoundStart) return false;
            int n = 0;
            QString mark = "&juguan+#" + player->objectName() + "-Keep";
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                if (p->getMark(mark) > 0) {
                    n++;
                    room->setPlayerMark(p, mark, 0);
                }
            }
            if (n > 0 && player->isAlive())
                room->addPlayerMark(player, "juguan_draw-Clear", n);
        } else {
            if (player->isDead()) return false;
            int mark = 2 * player->getMark("juguan_draw-Clear");
            if (mark <= 0) return false;
            room->setPlayerMark(player, "juguan_draw-Clear", 0);

            LogMessage log;
            log.type = "#JuguanExtraDraw";
            log.from = player;
            log.arg = objectName();
            log.arg2 = QString::number(mark);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(this);

            data = data.toInt() + mark;
        }
        return false;
    }
};

QuxiCard::QuxiCard()
{
    mute = true;
}

bool QuxiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (to_select == Self || targets.length() >= 2) return false;

    QString pattern = Sanguosha->getCurrentCardUsePattern();
    if (!pattern.startsWith("@@quxi")) return false;
    if (pattern.endsWith("1")) {
        if (targets.isEmpty()) return true;
        if (targets.length() == 1)
            return to_select->getHandcardNum() != targets.first()->getHandcardNum();
    } else if (pattern.endsWith("2")) {
        if (!targets.isEmpty()) {
            if (targets.first()->getMark("&quxifeng") > 0 || targets.first()->getMark("&quxiqian") > 0)
                return true;
            else
                return false;
        }
        QString death_name = Self->property("QuxiDeathPlayer").toString();
        //const Player *death = Self->findChild<const Player *>(death_name);  找不到death
        const Player *death = NULL;
        foreach (const Player *p, Self->getSiblings()) {
            if (p->objectName() == death_name) {
                death = p;
                break;
            }
        }
        if (death) {
            if (death->getMark("&quxifeng") > 0 || death->getMark("&quxiqian") > 0)
                return true;
            else
                return to_select->getMark("&quxifeng") > 0 || to_select->getMark("&quxiqian") > 0;
        } else if (!death)
            return to_select->getMark("&quxifeng") > 0 || to_select->getMark("&quxiqian") > 0;
    } else if (pattern.endsWith("3")) {
        if (targets.isEmpty())
            return to_select->getMark("&quxifeng") > 0 || to_select->getMark("&quxiqian") > 0;
        else
            return true;
    }
    return false;
}

bool QuxiCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    QString pattern = Sanguosha->getCurrentCardUsePattern();
    if (!pattern.startsWith("@@quxi")) return false;
    if (!pattern.endsWith("2"))
        return targets.length() == 2;
    else
        return targets.length() >= 1;
}

void QuxiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QString pattern = Sanguosha->getCurrentCardUsePattern();
    if (!pattern.startsWith("@@quxi")) return;
    if (pattern.endsWith("1"))
        SkillCard::onUse(room, card_use);
    else {
        CardUseStruct use = card_use;
        QVariant data = QVariant::fromValue(use);
        RoomThread *thread = room->getThread();

        thread->trigger(PreCardUsed, room, card_use.from, data);
        use = data.value<CardUseStruct>();

        room->broadcastSkillInvoke("quxi");

        LogMessage log;
        log.from = card_use.from;
        log.to << card_use.to;
        log.type = "#UseCard";
        log.card_str = toString();
        room->sendLog(log);

        thread->trigger(CardUsed, room, card_use.from, data);
        use = data.value<CardUseStruct>();
        thread->trigger(CardFinished, room, card_use.from, data);
    }
}

void QuxiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QString pattern = Sanguosha->getCurrentCardUsePattern();
    if (!pattern.startsWith("@@quxi")) return;

    if (pattern.endsWith("1")) {
        ServerPlayer *more, *less;
        if (targets.first()->getHandcardNum() > targets.last()->getHandcardNum()) {
            more = targets.first();
            less = targets.last();
        } else {
            more = targets.last();
            less = targets.first();
        }
        if (more->isNude()) return;
        int id = room->askForCardChosen(less, more, "he", "quxi");
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, less->objectName());
        room->obtainCard(less, Sanguosha->getCard(id), reason, room->getCardPlace(id) != Player::PlaceHand);
        if (less->isAlive())
            less->gainMark("&quxifeng");
        if (more->isAlive())
            more->gainMark("&quxiqian");
    } else {
        ServerPlayer *first = NULL, *last = NULL;
        QStringList choices;
        if (targets.length() == 1 && pattern.endsWith("2")) {
            QString death_name = source->property("QuxiDeathPlayer").toString();
            ServerPlayer *death = room->findChild<ServerPlayer *>(death_name);
            if (!death) return;
            first = death;
            last = targets.first();
        } else if (targets.length() >= 2) {
            first = targets.first();
            last = targets.last();
        }
        if (!first || !last) return;

        if (first->getMark("&quxifeng") > 0)
            choices << "feng";
        if (first->getMark("&quxiqian") > 0)
            choices << "qian";
        if (choices.isEmpty()) return;

        QString mark, choice = room->askForChoice(source, "quxi", choices.join("+"), QVariant::fromValue(first));
        mark = "&quxi" + choice;
        int num = first->getMark(mark);
        first->loseAllMarks(mark);
        last->gainMark(mark, num);
    }
}

class QuxiVS : public ZeroCardViewAsSkill
{
public:
    QuxiVS() : ZeroCardViewAsSkill("quxi")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@quxi");
    }

    const Card *viewAs() const
    {
        return new QuxiCard;
    }
};


class Quxi : public TriggerSkill
{
public:
    Quxi() : TriggerSkill("quxi")
    {
        events << EventPhaseEnd << Death << RoundStart;
        view_as_skill = new QuxiVS;
        frequency = Limited;
        limit_mark = "@quxiMark";
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play || player->getMark("@quxiMark") <= 0 || player->isSkipped(Player::Discard)) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("duxi", "quxi");
            room->removePlayerMark(player, "@quxiMark");

            player->skip(Player::Discard);
            if (player->faceUp())
                player->turnOver();
            if (player->isDead() || room->alivePlayerCount() <= 2) return false;
            if (room->askForUseCard(player, "@@quxi1", "@quxi1", 1, Card::MethodNone)) return false;

            QList<ServerPlayer *> a_list;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                int hand = p->getHandcardNum();
                foreach (ServerPlayer *pp, room->getOtherPlayers(player)) {
                    if (pp == p || pp->getHandcardNum() == hand) continue;
                    a_list << p;
                    break;
                }
            }
            if (a_list.isEmpty()) return false;
            ServerPlayer *a = a_list.at(qrand() % a_list.length());
            int hand = a->getHandcardNum();

            QList<ServerPlayer *> b_list;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p == a || p->getHandcardNum() == hand) continue;
                b_list << p;
            }
            if (b_list.isEmpty()) return false;
            ServerPlayer *b = b_list.at(qrand() % b_list.length());

            ServerPlayer *more, *less;
            if (a->getHandcardNum() > b->getHandcardNum()) {
                more = a;
                less = b;
            } else {
                more = b;
                less = a;
            }

            QList<ServerPlayer *> tos;
            tos << a << b;
            room->sortByActionOrder(tos);
            LogMessage log;
            log.from = player;
            log.to << tos;
            log.type = "#ChoosePlayerWithSkill";
            log.arg = objectName();
            room->sendLog(log);
            foreach (ServerPlayer *p, tos)
                room->doAnimate(1, player->objectName(), p->objectName());

            if (more->isNude()) return false;
            int id = room->askForCardChosen(less, more, "he", objectName());
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, less->objectName());
            room->obtainCard(less, Sanguosha->getCard(id), reason, room->getCardPlace(id) != Player::PlaceHand);
            if (less->isAlive())
                less->gainMark("&quxifeng");
            if (more->isAlive())
                more->gainMark("&quxiqian");
        } else if (event == RoundStart) {
            if (room->alivePlayerCount() < 3) return false;
            bool can_transfer = false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getMark("&quxifeng") > 0 || p->getMark("&quxiqian") > 0) {
                    can_transfer = true;
                    break;
                }
            }
            if (!can_transfer) return false;
            room->askForUseCard(player, "@@quxi3", "@quxi3", 3, Card::MethodNone);
        } else {
            if (room->alivePlayerCount() < 2) return false;
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player) return false;
            bool can_transfer = false;
            foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                if (p->getMark("&quxifeng") > 0 || p->getMark("&quxiqian") > 0) {
                    can_transfer = true;
                    break;
                }
            }
            if (!can_transfer) return false;
            room->setPlayerProperty(player, "QuxiDeathPlayer", death.who->objectName());
            room->askForUseCard(player, "@@quxi2", "@quxi2", 2, Card::MethodNone);
            room->setPlayerProperty(player, "QuxiDeathPlayer", QString());
        }
        return false;
    }
};

class QuxiDraw : public DrawCardsSkill
{
public:
    QuxiDraw() : DrawCardsSkill("#quxi")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && (target->getMark("&quxifeng") > 0 || target->getMark("&quxiqian") > 0);
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        int feng = player->getMark("&quxifeng"), qian = player->getMark("&quxiqian");
        if (feng == qian) return n;

        LogMessage log;
        log.type = "#ZhenguEffect";
        log.from = player;
        log.arg = "quxi";
        room->sendLog(log);
        room->broadcastSkillInvoke("quxi");

        return n + feng - qian;
    }
};

class Bixiong : public TriggerSkill
{
public:
    Bixiong() : TriggerSkill("bixiong")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Discard) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player) return false;
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            QString mark = "&bixiong+";
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) != Player::PlaceHand) continue;
                const Card *card = Sanguosha->getCard(move.card_ids.at(i));
                QString suit = card->getSuitString() + "_char";
                if (mark.contains(suit)) continue;
                mark = mark + "+" + suit;
            }
            if (mark == "&bixiong+") return false;
            room->sendCompulsoryTriggerLog(player, this);
            foreach (QString m, player->getMarkNames()) {
                if (!m.startsWith("&bixiong+") || player->getMark(m) <= 0) continue;
                room->setPlayerMark(player, m, 0);
            }
            room->addPlayerMark(player, mark);
        }
        return false;
    }
};

class BixiongClear : public PhaseChangeSkill
{
public:
    BixiongClear() : PhaseChangeSkill("#bixiong-clear")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        Room *room = player->getRoom();
        foreach (QString m, player->getMarkNames()) {
            if (!m.startsWith("&bixiong+") || player->getMark(m) <= 0) continue;
            room->setPlayerMark(player, m, 0);
        }
        return false;
    }
};

class BixiongProhibit : public ProhibitSkill
{
public:
    BixiongProhibit() : ProhibitSkill("#bixiong-prohibit")
    {
    }

    bool isProhibited(const Player *, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        QString mark;
        foreach (QString m, to->getMarkNames()) {
            if (!m.startsWith("&bixiong+") || to->getMark(m) <= 0) continue;
            mark = m;
            break;
        }
        return !mark.isEmpty() && mark.contains(card->getSuitString() + "_char");
    }
};

class Qigong : public TriggerSkill
{
public:
    Qigong() : TriggerSkill("qigong")
    {
        events << SlashMissed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        SlashEffectStruct slash = data.value<SlashEffectStruct>();
        if (slash.multiple || !slash.to->isAlive()) return false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->canSlash(slash.to, NULL, false)) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@qigong-invoke:" + slash.to->objectName(), true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(this);

        room->askForUseSlashTo(target, slash.to, "@qigong-slash:" + slash.to->objectName(), false, false, true, NULL, NULL, "SlashNoRespond");

        return false;
    }
};

LiehouCard::LiehouCard()
{
}

bool LiehouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->isKongcheng() && Self->inMyAttackRange(to_select);
}

void LiehouCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead() || effect.to->isKongcheng()) return;
    Room *room = effect.from->getRoom();
    const Card *card = room->askForExchange(effect.to, "liehou", 1, 1, false, "@liehou-give1:" + effect.from->objectName());
    room->giveCard(effect.to, effect.from, card, "liehou");
    delete card;

    if (effect.from->isDead() || effect.from->isKongcheng()) return;

    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.to)) {
        if (!effect.from->inMyAttackRange(p)) continue;
        targets << p;
    }
    if (targets.isEmpty()) return;

    effect.from->tag["LiehouTarget"] = QVariant::fromValue(effect.to);

    QList<int> hands = effect.from->handCards();
    room->askForYiji(effect.from, hands, "liehou", false, false, false, 1, targets, CardMoveReason(), "@liehou-give2");

    effect.from->tag.remove("LiehouTarget");
}

class Liehou : public ZeroCardViewAsSkill
{
public:
    Liehou() : ZeroCardViewAsSkill("liehou")
    {
    }

    const Card *viewAs() const
    {
        return new LiehouCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("LiehouCard");
    }
};

class Langmie : public TriggerSkill
{
public:
    Langmie() : TriggerSkill("langmie")
    {
        events << EventPhaseEnd << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play) return false;
            bool can_trigger = false;
            for (int i = 0; i < S_CARD_TYPE_LENGTH; i++) {
                if (i == 0) continue;
                if (player->getMark("langmie_" + QString::number(i) + "-PlayClear") >= 2) {
                    can_trigger = true;
                    break;
                }
            }
            if (!can_trigger) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead() || !p->hasSkill(this)) continue;
                if (!p->askForSkillInvoke(this, "draw")) continue;
                room->broadcastSkillInvoke(this);
                p->drawCards(1, objectName());
            }
        } else {
            if (player->getPhase() != Player::Finish) return false;
            if (player->getMark("damage_point_round") < 2) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "he")) continue;
                if (!room->askForCard(p, "..", "@langmie-dis:" + player->objectName(), data, objectName())) continue;
                room->broadcastSkillInvoke(this);
                room->damage(DamageStruct("langmie", p, player));
            }
        }
        return false;
    }
};

class SecondLangmie : public PhaseChangeSkill
{
public:
    SecondLangmie() : PhaseChangeSkill("secondlangmie")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Finish;
    }

    QStringList Choices(ServerPlayer *player) const
    {
        QStringList choices;
        for (int i = 0; i < S_CARD_TYPE_LENGTH; i++) {
            if (i == 0) continue;
            if (player->getMark("secondlangmie_" + QString::number(i) + "-Clear") >= 2) {
                choices << "draw";
                break;
            }
        }
        if (player->getMark("damage_point_round") >= 2)
            choices << "damage=" + player->objectName();
        return choices;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "he")) continue;
            QStringList choices = Choices(player);
            if (choices.isEmpty()) return false;
            if (choices.length() == 1) {
                if (choices.first() == "draw") {
                    if (room->askForCard(p, "..", "@secondlangmie-draw", QVariant(), objectName())) {
                        room->broadcastSkillInvoke(this);
                        p->drawCards(2, objectName());
                    }
                } else {
                    if (room->askForCard(p, "..", "@secondlangmie-damage:" + player->objectName(), QVariant::fromValue(player), objectName())) {
                        room->broadcastSkillInvoke(this);
                        room->damage(DamageStruct(objectName(), p, player));
                    }
                }
            } else {
                choices << "cancel";
                QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(player));
                if (choice == "cancel") continue;
                room->askForDiscard(p, objectName(), 1, 1, false, true, QString(), ".", objectName());
                if (choice == "draw")
                    p->drawCards(2, objectName());
                else
                    room->damage(DamageStruct(objectName(), p, player));
            }
        }
        return false;
    }
};

TenyearHuoshuiCard::TenyearHuoshuiCard()
{
}

bool TenyearHuoshuiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    int lose = qMax(1, Self->getLostHp());
    return targets.length() < lose;
}

void TenyearHuoshuiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    effect.to->addMark("tenyearhuoshui");
    room->addPlayerMark(effect.to, "@skill_invalidity");

    foreach(ServerPlayer *p, room->getAllPlayers())
        room->filterCards(p, p->getCards("he"), true);
    JsonArray args;
    args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
}

class TenyearHuoshuiVS : public ZeroCardViewAsSkill
{
public:
    TenyearHuoshuiVS() : ZeroCardViewAsSkill("tenyearhuoshui")
    {
        response_pattern = "@@tenyearhuoshui";
    }

    const Card *viewAs() const
    {
        return new TenyearHuoshuiCard;
    }
};

class TenyearHuoshui : public PhaseChangeSkill
{
public:
    TenyearHuoshui() : PhaseChangeSkill("tenyearhuoshui")
    {
        view_as_skill = new TenyearHuoshuiVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        int lose = qMax(1, player->getLostHp());
        player->getRoom()->askForUseCard(player, "@@tenyearhuoshui", "@tenyearhuoshui:" + QString::number(lose));
        return false;
    }
};

class TenyearHuoshuiClear : public TriggerSkill
{
public:
    TenyearHuoshuiClear() : TriggerSkill("#tenyearhuoshui-clear")
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
            if (player->getMark("tenyearhuoshui") == 0) continue;
            room->removePlayerMark(player, "@skill_invalidity", player->getMark("tenyearhuoshui"));
            player->setMark("tenyearhuoshui", 0);

            foreach(ServerPlayer *p, room->getAllPlayers())
                room->filterCards(p, p->getCards("he"), false);
            JsonArray args;
            args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
        }
        return false;
    }
};

TenyearQingchengCard::TenyearQingchengCard()
{
}

bool TenyearQingchengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->isMale() && to_select->getHandcardNum() <= Self->getHandcardNum();
}

void TenyearQingchengCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    ServerPlayer *a = effect.from;
    ServerPlayer *b = effect.to;
    b->setFlags("TenyearQingchengTarget");

    int n1 = a->getHandcardNum();
    int n2 = b->getHandcardNum();

    try {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p != a && p != b) {
                JsonArray arr;
                arr << a->objectName() << b->objectName();
                room->doNotify(p, QSanProtocol::S_COMMAND_EXCHANGE_KNOWN_CARDS, arr);
            }
        }
        QList<CardsMoveStruct> exchangeMove;
        CardsMoveStruct move1(a->handCards(), b, Player::PlaceHand,
            CardMoveReason(CardMoveReason::S_REASON_SWAP, a->objectName(), b->objectName(), "tenyearqingcheng", QString()));
        CardsMoveStruct move2(b->handCards(), a, Player::PlaceHand,
            CardMoveReason(CardMoveReason::S_REASON_SWAP, b->objectName(), a->objectName(), "tenyearqingcheng", QString()));
        exchangeMove.push_back(move1);
        exchangeMove.push_back(move2);
        room->moveCardsAtomic(exchangeMove, false);

        LogMessage log;
        log.type = "#Dimeng";
        log.from = a;
        log.to << b;
        log.arg = QString::number(n1);
        log.arg2 = QString::number(n2);
        room->sendLog(log);
        room->getThread()->delay();

        b->setFlags("-TenyearQingchengTarget");
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken || triggerEvent == StageChange)
            b->setFlags("-TenyearQingchengTarget");
        throw triggerEvent;
    }
}

class TenyearQingcheng : public ZeroCardViewAsSkill
{
public:
    TenyearQingcheng() : ZeroCardViewAsSkill("tenyearqingcheng")
    {
    }

    const Card *viewAs() const
    {
        return new TenyearQingchengCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearQingchengCard");
    }
};

class TenyearYuhua :public TriggerSkill
{
public:
    TenyearYuhua() : TriggerSkill("tenyearyuhua")
    {
        events << EventPhaseProceeding << EventPhaseStart;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == EventPhaseProceeding) {
            if (player->getPhase() != Player::Discard) return false;
            QList<int> not_basics;
            foreach (int id, player->handCards()) {
                if (!Sanguosha->getCard(id)->isKindOf("BasicCard"))
                    not_basics << id;
            }
            if (not_basics.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            room->ignoreCards(player, not_basics);
        } else {
            if (player->getPhase() != Player::Finish || player->getHandcardNum() <= player->getMaxHp()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            QList<int> ids = room->getNCards(1, false);
            room->askForGuanxing(player, ids, Room::GuanxingBothSides);
        }
        return false;
    }
};

class TenyearQirang : public TriggerSkill
{
public:
    TenyearQirang() : TriggerSkill("tenyearqirang")
    {
        events << CardUsed;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!data.value<CardUseStruct>().card->isKindOf("EquipCard")) return false;
        if (!player->askForSkillInvoke(this, data)) return false;
        room->broadcastSkillInvoke(this);

        QList<int> drawPile = room->getDrawPile();
        QList<int> trickIDs;
        foreach(int id, drawPile) {
            if (Sanguosha->getCard(id)->isKindOf("TrickCard"))
                trickIDs.append(id);
        }

        if (trickIDs.isEmpty()) {
            LogMessage msg;
            msg.type = "#olqirang-failed";
            room->sendLog(msg);
            return false;
        }
        int trick_id = trickIDs.at(qrand() % trickIDs.length());
        if (trick_id >= 0) {
            room->obtainCard(player, trick_id, true);
            if (player->isAlive() && Sanguosha->getCard(trick_id)->isNDTrick()) {
                QVariantList ids = player->tag["tenyearqirang_tricks"].toList();
                ids << trick_id;
                player->tag["tenyearqirang_tricks"] = ids;
            }
        }
        return false;
    }
};

class TenyearQirangEffect : public TriggerSkill
{
public:
    TenyearQirangEffect() : TriggerSkill("#tenyearqirang")
    {
        events << EventPhaseChanging << TargetSpecifying;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && !target->tag["tenyearqirang_tricks"].toList().isEmpty();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            player->tag.remove("tenyearqirang_tricks");
        } else {
            if (player->isDead()) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.to.length() != 1 || !use.card->isNDTrick() || use.card->isVirtualCard() || !use.card->getSkillName().isEmpty()) return false;
            int id = use.card->getEffectiveId();
            QVariantList ids = player->tag["tenyearqirang_tricks"].toList();
            if (!ids.contains(id)) return false;
            QList<ServerPlayer *> targets = room->getCardTargets(player, use.card, use.to);
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, "tenyearqirang", "@tenyearqirang-target:" + use.card->objectName(), true);
            if (!target) return false;
            room->broadcastSkillInvoke("tenyearqirang");
            room->doAnimate(1, player->objectName(), target->objectName());
            LogMessage log;
            log.type = "#QiaoshuiAdd";
            log.from = player;
            log.to << target;
            log.card_str = use.card->toString();
            log.arg = "tenyearqirang";
            room->sendLog(log);
            use.to << target;
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class Koulve : public TriggerSkill
{
public:
    Koulve(const QString &koulve) : TriggerSkill(koulve), koulve(koulve)
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead() || damage.to == player || damage.to->isKongcheng() || !player->askForSkillInvoke(this, damage.to)) return false;
        room->broadcastSkillInvoke(this);

        int num = 1;
        if (koulve == "secondkoulve")
            num = damage.to->getLostHp();
        if (num <= 0) return false;

        int ad = Config.AIDelay;
        Config.AIDelay = 0;
        damage.to->setFlags(koulve + "_InTempMoving");

        QList<int> show_ids;
        for (int i = 0; i < num; i++) {
            if (player->isDead() || damage.to->isDead() || damage.to->isKongcheng()) break;
            int id = room->askForCardChosen(player, damage.to, "h", objectName());
            show_ids << id;
            room->showCard(damage.to, id);
            damage.to->addToPile("#" + koulve, id, false);
        }

        for (int i = 0; i < show_ids.length(); ++i)
            room->moveCardTo(Sanguosha->getCard(show_ids.value(i)), damage.to, Player::PlaceHand, false);

        damage.to->setFlags("-" + koulve + "_InTempMoving");
        Config.AIDelay = ad;

        DummyCard *dummy = new DummyCard();
        dummy->deleteLater();
        bool red = false;

        foreach (int id, show_ids) {
            const Card *card = Sanguosha->getCard(id);
            if (card->isKindOf("Slash") || (card->isNDTrick() && card->isDamageCard()))
                dummy->addSubcard(card);
            if (card->isRed())
                red = true;
        }

        if (dummy->subcardsLength() > 0)
            room->obtainCard(player, dummy);
        if (red) {
            if (player->isWounded())
                room->loseMaxHp(player);
            else
                room->loseHp(player);
            player->drawCards(2, objectName());
        }

        return false;
    }
private:
    QString koulve;
};

class Suirenq : public TriggerSkill
{
public:
    Suirenq() : TriggerSkill("suirenq")
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
        if (death.who != player)
            return false;

        QList<int> ids;
        foreach (const Card *card, player->getHandcards()) {
            if (card->isKindOf("Slash") || (card->isNDTrick() && card->isDamageCard()))
                ids << card->getEffectiveId();
        }
        if (ids.isEmpty()) return false;

        ServerPlayer *to = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@suirenq-invoke", true, true);
        if (!to) return false;
        room->broadcastSkillInvoke(this);
        room->giveCard(player, to, ids, objectName(), true);

        return false;
    }
};

class FengshiMF : public TriggerSkill
{
public:
    FengshiMF() : TriggerSkill("fengshimf")
    {
        events << TargetSpecified << TargetConfirmed;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.length() != 1) return false;
        if (!use.card->isKindOf("BasicCard") && !use.card->isKindOf("TrickCard")) return false;
        if (event == TargetSpecified) {
            foreach (ServerPlayer *p, use.to) {
                if (player->isDead()) return false;
                if (p->isDead()) continue;
                if (p->getHandcardNum() < player->getHandcardNum()) {
                    if (!player->canDiscard(player, "he") || !player->canDiscard(p, "he")) continue;
                    if (!player->askForSkillInvoke(this, p)) continue;
                    room->broadcastSkillInvoke(this);
                    if (player->canDiscard(player, "he")) {
                        int id = room->askForCardChosen(player, player, "he", objectName(), false, Card::MethodDiscard);
                        room->throwCard(id, player);
                    }
                    if (player->canDiscard(p, "he")) {
                        int id = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard);
                        room->throwCard(id, p, player);
                    }
                    int num = room->getTag("FengshiMFDamage_" + use.card->toString()).toInt();
                    num++;
                    room->setTag("FengshiMFDamage_" + use.card->toString(), num);
                }
            }
        } else if (event == TargetConfirmed && use.to.contains(player)) {
            if (use.from && use.from->isAlive() && use.from->getHandcardNum() > player->getHandcardNum()) {
                if (!player->canDiscard(player, "he") || !player->canDiscard(use.from, "he")) return false;
                if (!use.from->askForSkillInvoke("fengshimf_other", player, false)) return false;

                LogMessage log;
                log.type = "#InvokeOthersSkill";
                log.from = use.from;
                log.to << player;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(this);

                if (player->canDiscard(player, "he")) {
                    int id = room->askForCardChosen(player, player, "he", objectName(), false, Card::MethodDiscard);
                    room->throwCard(id, player);
                }
                if (player->canDiscard(use.from, "he")) {
                    int id = room->askForCardChosen(player, use.from, "he", objectName(), false, Card::MethodDiscard);
                    room->throwCard(id, use.from, player);
                }
                int num = room->getTag("FengshiMFDamage_" + use.card->toString()).toInt();
                num++;
                room->setTag("FengshiMFDamage_" + use.card->toString(), num);
            }
        }
        return false;
    }
};

class FengshiMFDamage : public TriggerSkill
{
public:
    FengshiMFDamage() : TriggerSkill("#fengshimf")
    {
        events << DamageCaused << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card) return false;
            //if (!damage.card->isKindOf("BasicCard") && !damage.card->isKindOf("TrickCard")) return false;
            int num = room->getTag("FengshiMFDamage_" + damage.card->toString()).toInt();
            damage.damage += num;
            data = QVariant::fromValue(damage);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            //if (!use.card->isKindOf("BasicCard") && !use.card->isKindOf("TrickCard")) return false;
            room->removeTag("FengshiMFDamage_" + use.card->toString());
        }
        return false;
    }
};

CuijianCard::CuijianCard()
{
}

bool CuijianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && !to_select->isKongcheng();
}

void CuijianCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    DummyCard *jink = new DummyCard;
    jink->deleteLater();
    foreach (const Card *card, effect.to->getHandcards()) {
        if (card->isKindOf("Jink"))
            jink->addSubcard(card);
    }

    int length = jink->subcardsLength();
    if (length > 0) {
        if (effect.from == effect.to) return;
        if (effect.to->getArmor())
            jink->addSubcard(effect.to->getArmor());
        room->giveCard(effect.to, effect.from, jink, "cuijian", true);

        if (effect.from->isAlive() && effect.to->isAlive()) {
            int give = length;
            if (effect.from->getMark("tongyuan_peach-Keep") > 0)
                give = 1;
            if (give <= 0 || effect.from->isNude()) return;
            const Card *ex = room->askForExchange(effect.from, "cuijian", give, give, true,
                                                  "@cuijian-give:" + effect.to->objectName() + "::" + QString::number(give));
            room->giveCard(effect.from, effect.to, ex, "cuijian");
            delete ex;
        }
    } else {
        if (effect.from->isDead()) return;
        if (effect.from->getMark("tongyuan_nullification-Keep") > 0)
            effect.from->drawCards(1, "cuijian");
        else {
            if (!effect.from->canDiscard(effect.from, "h")) return;
            room->askForDiscard(effect.from, "cuijian", 1, 1, false, true);
        }
    }
}

class Cuijian : public ZeroCardViewAsSkill
{
public:
    Cuijian() : ZeroCardViewAsSkill("cuijian")
    {
    }

    const Card *viewAs() const
    {
        return new CuijianCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("CuijianCard");
    }
};

class Tongyuan : public TriggerSkill
{
public:
    Tongyuan() : TriggerSkill("tongyuan")
    {
        events << CardFinished;
        frequency = Compulsory;
    }

    void sendLog(ServerPlayer *player) const
    {
        if (!player->hasSkill("cuijian", true)) return;
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#TongyuanChangeTranslation";
        log.arg = objectName();
        log.arg2 = "cuijian";
        log.from = player;
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Peach")) {
            if (player->getMark("tongyuan_peach-Keep") <= 0) {
                sendLog(player);
                room->addPlayerMark(player, "tongyuan_peach-Keep");
                int num = player->getMark("tongyuan_nullification-Keep") > 0 ? 3 : 2;
                room->changeTranslation(player, "cuijian", num);
                room->changeTranslation(player, "tongyuan", num);
                if (num == 3)
                    room->setPlayerMark(player, "&tongyuan-Keep", 1);
            }
        } else if (use.card->isKindOf("Nullification")) {
            if (player->getMark("tongyuan_nullification-Keep") <= 0) {
                sendLog(player);
                room->addPlayerMark(player, "tongyuan_nullification-Keep");
                int num = player->getMark("tongyuan_peach-Keep") > 0 ? 3 : 1;
                room->changeTranslation(player, "cuijian", num);
                room->changeTranslation(player, "tongyuan", num);
                if (num == 3)
                    room->setPlayerMark(player, "&tongyuan-Keep", 1);
            }
        }
        return false;
    }
};

class TongyuanEffect : public TriggerSkill
{
public:
    TongyuanEffect() : TriggerSkill("#tongyuan")
    {
        events << CardUsed << PreHpRecover;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    void sendLog(ServerPlayer *player, const QString &name) const
    {
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#Tongyuan" + name;
        log.arg = "tongyuan";
        log.arg2 = name;
        log.from = player;
        room->sendLog(log);
        room->notifySkillInvoked(player, "tongyuan");
        room->broadcastSkillInvoke("tongyuan");
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            if (player->getMark("&tongyuan-Keep") <= 0) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Nullification")) {
                sendLog(player, "nullification");
                use.no_offset_list << "_ALL_TARGETS";
                data = QVariant::fromValue(use);
            } else if (use.card->isKindOf("Peach")) {
                sendLog(player, "peach");
                room->setCardFlag(use.card, "tongyuan_peach");
            }
        } else {
            RecoverStruct rec = data.value<RecoverStruct>();
            if (!rec.card || !rec.card->isKindOf("Peach") || !rec.card->hasFlag("tongyuan_peach")) return false;
            room->setCardFlag(rec.card, "-tongyuan_peach");
            ++rec.recover;
            data = QVariant::fromValue(rec);
        }
        return false;
    }
};

SecondCuijianCard::SecondCuijianCard()
{
}

bool SecondCuijianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && !to_select->isKongcheng();
}

void SecondCuijianCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    DummyCard *get = new DummyCard;
    get->deleteLater();
    bool jink = false;
    foreach (const Card *card, effect.to->getCards("he")) {
        if (card->isKindOf("Jink"))
            jink = true;
        if (card->isKindOf("Jink") || card->isKindOf("Armor"))
            get->addSubcard(card);
    }

    if (!jink) {
        if (effect.from->getMark("secondtongyuan_redtrick-Keep") > 0)
            effect.from->drawCards(2, "secondcuijian");
        return;
    }

    int length = get->subcardsLength();
    if (length > 0) {
        if (effect.from == effect.to) return;
        room->giveCard(effect.to, effect.from, get, "secondcuijian", true);
        if (effect.from->isAlive() && effect.to->isAlive()) {
            int give = length;
            if (effect.from->getMark("secondtongyuan_redbasic-Keep") > 0)
                give = 0;
            if (give <= 0 || effect.from->isNude()) return;
            const Card *ex = room->askForExchange(effect.from, "secondcuijian", give, give, true,
                                                  "@cuijian-give:" + effect.to->objectName() + "::" + QString::number(give));
            room->giveCard(effect.from, effect.to, ex, "secondcuijian");
            delete ex;
        }
    }
}

class SecondCuijian : public ZeroCardViewAsSkill
{
public:
    SecondCuijian() : ZeroCardViewAsSkill("secondcuijian")
    {
    }

    const Card *viewAs() const
    {
        return new SecondCuijianCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SecondCuijianCard");
    }
};

class SecondTongyuan : public TriggerSkill
{
public:
    SecondTongyuan() : TriggerSkill("secondtongyuan")
    {
        events << CardFinished << CardResponded;
        frequency = Compulsory;
    }

    void sendLog(ServerPlayer *player) const
    {
        if (!player->hasSkill("secondcuijian", true)) return;
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#TongyuanChangeTranslation";
        log.arg = objectName();
        log.arg2 = "secondcuijian";
        log.from = player;
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isRed()) return false;
            if (use.card->isKindOf("TrickCard")) {
                if (player->getMark("secondtongyuan_redtrick-Keep") <= 0) {
                    sendLog(player);
                    room->addPlayerMark(player, "secondtongyuan_redtrick-Keep");
                    int num = player->getMark("secondtongyuan_redbasic-Keep") > 0 ? 3 : 1;
                    room->changeTranslation(player, "secondcuijian", num);
                    room->changeTranslation(player, "secondtongyuan", num);
                    if (num == 3)
                        room->setPlayerMark(player, "&secondtongyuan-Keep", 1);
                }
            } else if (use.card->isKindOf("BasicCard")) {
                if (player->getMark("secondtongyuan_redbasic-Keep") <= 0) {
                    sendLog(player);
                    room->addPlayerMark(player, "secondtongyuan_redbasic-Keep");
                    int num = player->getMark("secondtongyuan_redtrick-Keep") > 0 ? 3 : 2;
                    room->changeTranslation(player, "secondcuijian", num);
                    room->changeTranslation(player, "secondtongyuan", num);
                    if (num == 3)
                        room->setPlayerMark(player, "&secondtongyuan-Keep", 1);
                }
            }
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (res.m_isUse || !res.m_card->isRed() || !res.m_card->isKindOf("BasicCard")) return false;
            if (player->getMark("secondtongyuan_redbasic-Keep") <= 0) {
                sendLog(player);
                room->addPlayerMark(player, "secondtongyuan_redbasic-Keep");
                int num = player->getMark("secondtongyuan_redtrick-Keep") > 0 ? 3 : 2;
                room->changeTranslation(player, "secondcuijian", num);
                room->changeTranslation(player, "secondtongyuan", num);
                if (num == 3)
                    room->setPlayerMark(player, "&secondtongyuan-Keep", 1);
            }
        }
        return false;
    }
};

class SecondTongyuanEffect : public TriggerSkill
{
public:
    SecondTongyuanEffect() : TriggerSkill("#secondtongyuan")
    {
        events << CardUsed << PreCardUsed;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&secondtongyuan-Keep") > 0;
    }

    void sendLog(ServerPlayer *player, const QString &name) const
    {
        Room *room = player->getRoom();
        LogMessage log;
        log.type = "#SecondTongyuanredtrick";
        log.arg = "secondtongyuan";
        log.arg2 = name;
        log.from = player;
        room->sendLog(log);
        room->notifySkillInvoked(player, "secondtongyuan");
        room->broadcastSkillInvoke("secondtongyuan");
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (event == CardUsed) {
            if (use.card->isRed() && use.card->isNDTrick()) {
                sendLog(player, use.card->objectName());
                use.no_respond_list << "_ALL_TARGETS";
                data = QVariant::fromValue(use);
            }
        } else {
            if (use.card->isRed() && use.card->isKindOf("BasicCard")) {
                QList<ServerPlayer *> targets = room->getCardTargets(player, use.card, use.to);
                if (targets.isEmpty()) return false;
                ServerPlayer *t = room->askForPlayerChosen(player, targets, "secondtongyuan", "@secondtongyuan-add:" + use.card->objectName(), true);
                if (!t) return false;
                LogMessage log;
                log.type = "#QiaoshuiAdd";
                log.from = player;
                log.to << t;
                log.card_str = use.card->toString();
                log.arg = "secondtongyuan";
                room->sendLog(log);
                room->broadcastSkillInvoke("secondtongyuan");
                room->notifySkillInvoked(player, "secondtongyuan");
                room->doAnimate(1, player->objectName(), t->objectName());
                use.to << t;
                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
            }
        }
        return false;
    }
};

class Chaofeng : public TriggerSkill
{
public:
    Chaofeng(const QString &chaofeng) : TriggerSkill(chaofeng), chaofeng(chaofeng)
    {
        events << DamageCaused;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play || player->getMark(chaofeng + "_used-PlayClear") > 0) return false;
        if (!player->canDiscard(player, "h")) return false;
        const Card *card = room->askForCard(player, ".|.|.|hand", "@" + chaofeng + "-discard", data, objectName());
        if (!card) return false;
        room->broadcastSkillInvoke(this);
        room->addPlayerMark(player, chaofeng + "_used-PlayClear");

        int x = 1;
        DamageStruct damage = data.value<DamageStruct>();

        if (!damage.card) {
            player->drawCards(x, objectName());
            return false;
        }

        if (chaofeng == "chaofeng") {
            if (damage.card->getSuit() == card->getSuit()) {
                x++;
                player->drawCards(x, objectName());
            }
            if (damage.card->getNumber() == card->getNumber()) {
                damage.damage++;
                data = QVariant::fromValue(damage);
            }
        } else if (chaofeng == "secondchaofeng") {
            if (damage.card->sameColorWith(card)) {
                x++;
                player->drawCards(x, objectName());
            }
            if (damage.card->getTypeId() == card->getTypeId()) {
                damage.damage++;
                data = QVariant::fromValue(damage);
            }

        }
        return false;
    }
private:
    QString chaofeng;
};

class Chuanshu : public PhaseChangeSkill
{
public:
    Chuanshu(const QString &chuanshu) : PhaseChangeSkill(chuanshu), chuanshu(chuanshu)
    {
        frequency = Limited;
        limit_mark = "@" + chuanshu + "Mark";
        waked_skills = "longdan,congjian,chuanyun";
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start || player->getMark(limit_mark) <= 0) return false;
        if (chuanshu == "chuanshu" && !player->isLowestHpPlayer()) return false;
        if (chuanshu == "secondchuanshu" && !player->isWounded()) return false;

        Room *room = player->getRoom();
        ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@chuanshu-invoke", true, true);
        if (!t) return false;

        room->broadcastSkillInvoke(this);
        room->removePlayerMark(player, limit_mark);
        room->doSuperLightbox(chuanshu == "chuanshu" ? "sp_tongyuan" : "second_sp_tongyuan", chuanshu);

        room->acquireSkill(t, chuanshu == "chuanshu" ? "chaofeng" : "secondchaofeng");
        if (chuanshu == "chuanshu")
            room->loseMaxHp(player);
        room->handleAcquireDetachSkills(player, "longdan|congjian|chuanyun");
        return false;
    }
private:
    QString chuanshu;
};

class ChuanshuDeath : public TriggerSkill
{
public:
    ChuanshuDeath(const QString &chuanshu) : TriggerSkill("#" + chuanshu), chuanshu(chuanshu)
    {
        events << Death;
        frequency = Limited;
        limit_mark = "@" + chuanshu + "Mark";
        waked_skills = "longdan,congjian,chuanyun";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill(chuanshu) && target->getMark(limit_mark) > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player) return false;
        ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), chuanshu, "@chuanshu-invoke", true, true);
        if (!t) return false;

        room->broadcastSkillInvoke(chuanshu);
        room->removePlayerMark(player, limit_mark);
        room->doSuperLightbox(chuanshu == "chuanshu" ? "sp_tongyuan" : "second_sp_tongyuan", chuanshu);

        room->acquireSkill(t, chuanshu == "chuanshu" ? "chaofeng" : "secondchaofeng");
        if (chuanshu == "chuanshu")
            room->loseMaxHp(player);
        room->handleAcquireDetachSkills(player, "longdan|congjian|chuanyun");
        return false;
    }
private:
    QString chuanshu;
};

class Xunde : public MasochismSkill
{
public:
    Xunde() : MasochismSkill("xunde")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        ServerPlayer *from = damage.from;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return;
            if (p->isDead() || !p->hasSkill(this) || p->distanceTo(player) > 1) continue;
            if (!p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);

            JudgeStruct judge;
            judge.who = p;
            judge.reason = objectName();
            judge.play_animation = false;
            judge.pattern = ".|.|.|.";
            room->judge(judge);

            QStringList choices;
            const Card *jcard = judge.card;
            if (jcard->getNumber() >= 6 && room->CardInPlace(jcard, Player::DiscardPile) && player->isAlive())
                choices << "obtain=" + player->objectName() + "=" + jcard->objectName();
            if (jcard->getNumber() <= 6 && from && from->isAlive() && !from->isKongcheng())
                choices << "discard=" + from->objectName();
            if (choices.isEmpty()) continue;

            p->tag["XundeJudgeForAI"] = QVariant::fromValue(&judge);
            QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(damage));
            p->tag.remove("XundeJudgeForAI");

            if (choice.startsWith("obtain")) {
                if (player->isDead()) continue;
                room->obtainCard(player, jcard);
            } else {
                if (from && from->isAlive() && from->canDiscard(from, "h"))
                    room->askForDiscard(from, objectName(), 1, 1);
            }
        }
    }
};

class Chuanyun : public TriggerSkill
{
public:
    Chuanyun() : TriggerSkill("chuanyun")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, use.to.toSet()) {
            if (player->isDead()) return false;
            if (!p->canDiscard(p, "e")) continue;
            if (!player->askForSkillInvoke(this, p)) continue;
            room->broadcastSkillInvoke(this);

            QList<int> equips = p->getEquipsId();
            foreach (int id, equips) {
                if (!p->canDiscard(p, id))
                    equips.removeOne(id);
            }
            if (equips.isEmpty()) continue;

            int equip = equips.at(qrand() % equips.length());
            room->throwCard(equip, p);
        }
        return false;
    }
};

class Chenjie : public TriggerSkill
{
public:
    Chenjie() : TriggerSkill("chenjie")
    {
        events << AskForRetrial;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->isNude()) return false;
        JudgeStruct *judge = data.value<JudgeStruct *>();
        QStringList prompt_list;
        prompt_list << "@chenjie-card" << judge->who->objectName()
            << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");

        const Card *card = room->askForCard(player, ".|" + judge->card->getSuitString(), prompt, QVariant::fromValue(judge),
                                            Card::MethodResponse, judge->who, true, objectName());
        if (!card) return false;
        room->broadcastSkillInvoke(objectName());
        room->retrial(card, player, judge, objectName());
        player->drawCards(2, objectName());
        return false;
    }
};

class JibingVS : public OneCardViewAsSkill
{
public:
    JibingVS() : OneCardViewAsSkill("jibing")
    {
        filter_pattern = ".|.|.|jbbing";
        expand_pile = "jbbing";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player) && !player->getPile("jbbing").isEmpty();
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->getPile("jbbing").isEmpty()) return false;
        return pattern == "jink" || pattern.contains("slash") || pattern.contains("Slash");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
        case CardUseStruct::CARD_USE_REASON_PLAY: {
            Slash *slash = new Slash(Card::SuitToBeDecided, -1);
            slash->setSkillName("jibing");
            slash->addSubcard(originalCard);
            return slash;
        }
        case CardUseStruct::CARD_USE_REASON_RESPONSE:
        case CardUseStruct::CARD_USE_REASON_RESPONSE_USE: {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern.contains("slash") || pattern.contains("Slash")) {
                Slash *slash = new Slash(Card::SuitToBeDecided, -1);
                slash->setSkillName("jibing");
                slash->addSubcard(originalCard);
                return slash;
            } else if (pattern == "jink") {
                Jink *jink = new Jink(Card::SuitToBeDecided, -1);
                jink->setSkillName("jibing");
                jink->addSubcard(originalCard);
                return jink;
            } else
                return NULL;
        }
        default:
            return NULL;
        }
        return NULL;
    }
};

class Jibing : public PhaseChangeSkill
{
public:
    Jibing() : PhaseChangeSkill("jibing")
    {
        view_as_skill = new JibingVS;
    }

    static int getKingdoms(ServerPlayer *player)
    {
        QStringList kingdoms;
        Room *room = player->getRoom();
        foreach(ServerPlayer *p, room->getAlivePlayers()) {
            QString kingdom = p->getKingdom();
            if (kingdoms.contains(kingdom)) continue;
            kingdoms << kingdom;
        }
        return kingdoms.length();
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() != Player::Draw) return false;
        if (target->getPile("jbbing").length() >= getKingdoms(target)) return false;
        if (!target->askForSkillInvoke(this)) return false;
        Room *room = target->getRoom();
        room->broadcastSkillInvoke(this);
        QList<int> ids = room->getNCards(2, false);
        target->addToPile("jbbing", ids);
        return true;
    }
};

class Wangjing : public TriggerSkill
{
public:
    Wangjing() : TriggerSkill("wangjing")
    {
        events << CardUsed << CardResponded;
        frequency = Compulsory;
    }

    bool isHighHpPlayer(ServerPlayer *player) const
    {
        int hp = player->getHp();
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHp() > hp)
                return false;
        }
        return true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardResponded) {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (res.m_card->getSkillName() != "jibing" || !res.m_who || res.m_who->isDead() || res.m_card->isKindOf("SkillCard")) return false;
            if (!isHighHpPlayer(res.m_who)) return false;
            room->sendCompulsoryTriggerLog(player, this);
            player->drawCards(1, objectName());
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (!use.card->hasFlag("jibing_slash") && use.card->getSkillName() != "jibing") return false;
            foreach (ServerPlayer *p, use.to) {
                if (player->isDead()) return false;
                if (p->isDead() || !isHighHpPlayer(p)) continue;
                room->sendCompulsoryTriggerLog(player, this);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};

class Moucuan : public PhaseChangeSkill
{
public:
    Moucuan() : PhaseChangeSkill("moucuan")
    {
        frequency = Wake;
        waked_skills = "binghuo";
    }

    bool canWake(TriggerEvent, ServerPlayer *target, QVariant &, Room *room) const
    {
      if (target->getMark("moucuan") > 0 || target->getPhase() != Player::Start) return false;
      if (target->canWake(objectName())) return true;
      if (target->getPile("jbbing").length() < Jibing::getKingdoms(target)) return false;
      LogMessage log;
      log.type = "#ZaoxianWake";
      log.from = target;
      log.arg = QString::number(target->getPile("jbbing").length());
      log.arg2 = objectName();
      room->sendLog(log);
      return true;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        room->notifySkillInvoked(target, objectName());
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("mayuanyi", "moucuan");
        room->setPlayerMark(target, "moucuan", 1);
        if (room->changeMaxHpForAwakenSkill(target))
            room->acquireSkill(target, "binghuo");
        return false;
    }
};

class Binghuo : public PhaseChangeSkill
{
public:
    Binghuo() : PhaseChangeSkill("binghuo")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || p->getMark("jibing_used-Clear") <= 0) continue;
            ServerPlayer *target = room->askForPlayerChosen(p, room->getAlivePlayers(), objectName(), "@binghuo-invoke", true, true);
            if (!target) continue;
            p->peiyin(this);

            JudgeStruct judge;
            judge.who = target;
            judge.reason = objectName();
            judge.play_animation = true;
            judge.pattern = ".|black";
            judge.good = false;
            judge.negative = true;
            room->judge(judge);

            if (judge.isBad())
                room->damage(DamageStruct("binghuo", p, target, 1, DamageStruct::Thunder));
        }

        return false;
    }
};

class BinghuoRecord : public TriggerSkill
{
public:
    BinghuoRecord() : TriggerSkill("#binghuo")
    {
        events << PreChangeSlash << PreCardUsed << PreCardResponded;
        global = true;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreChangeSlash)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->isDead()) return false;

        if (event == PreCardResponded) {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (res.m_card->getSkillName() != "jibing" || res.m_card->isKindOf("SkillCard")) return false;
            room->setPlayerMark(player, "jibing_used-Clear", 1);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            if (event == PreChangeSlash) {
                if (use.card->isKindOf("Slash") && use.card->getSkillName() == "jibing")
                    room->setCardFlag(use.card, "jibing_slash");
            } else {
                if (!use.card->hasFlag("jibing_slash") && use.card->getSkillName() != "jibing") return false;
                room->setPlayerMark(player, "jibing_used-Clear", 1);
            }
        }
        return false;
    }
};

class Huantu : public TriggerSkill
{
public:
    Huantu() : TriggerSkill("huantu")
    {
        events << EventPhaseChanging << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::Draw || player->isSkipped(Player::Draw)) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this) || p->isNude() || p->getMark("huantu_lun") > 0) continue;
                if (!p->inMyAttackRange(player)) continue;
                const Card *card = room->askForCard(p, "..", "@huantu-invoke:" + player->objectName(), data, Card::MethodNone);
                if (!card) continue;

                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = p;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(p, objectName());
                room->broadcastSkillInvoke(this);

                room->addPlayerMark(p, "huantu_lun");
                room->giveCard(p, player, card, objectName());
                player->addMark("huantu_players_" + p->objectName() + "-Clear");
                player->skip(Player::Draw);
            }
        } else {
            if (player->getPhase() != Player::Finish) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead()) continue;
                int mark = player->getMark("huantu_players_" + p->objectName() + "-Clear");
                if (mark <= 0) continue;

                if (!p->askForSkillInvoke(this, player)) continue;
                room->broadcastSkillInvoke(this);

                QStringList choices;
                if (player->isAlive())
                    choices << "recover=" + player->objectName();
                choices << "draw=" + player->objectName();

                QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(player));
                if (choice.startsWith("recover")) {
                    room->recover(player, RecoverStruct(p));
                    player->drawCards(2, objectName());
                } else {
                    p->drawCards(3, objectName());
                    if (p->isDead() || p->isKongcheng() || player->isDead()) continue;
                    const Card *cards = room->askForExchange(p, objectName(), 2, 2, false, "@huantu-give:" + player->objectName());
                    room->giveCard(p, player, cards, objectName());
                    delete cards;
                }
            }
        }
        return false;
    }
};

class Bihuo : public TriggerSkill
{
public:
    Bihuo() : TriggerSkill("bihuo")
    {
        events << QuitDying;
        frequency = Limited;
        limit_mark = "@bihuoMark";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (!p->hasSkill(this) || p->getMark("@bihuoMark") <= 0) continue;
            if (!p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);

            room->removePlayerMark(p, "@bihuoMark");
            room->doSuperLightbox("yanpu", "bihuo");

            player->drawCards(3, objectName());
            room->addPlayerMark(player, "&bihuo_lun");
        }
        return false;
    }
};

class BihuoDistance : public DistanceSkill
{
public:
    BihuoDistance() : DistanceSkill("#bihuo")
    {
        frequency = Limited;
    }

    int getCorrect(const Player *, const Player *to) const
    {
        if (to->getMark("&bihuo_lun") > 0) {
            int extra = 0;
            QSet<QString> kingdom_set;
            if (to->parent()) {
                foreach(const Player *player, to->parent()->findChildren<const Player *>()) {
                    if (player->isAlive())
                        kingdom_set << player->getKingdom();
                }
            }
            extra = kingdom_set.size();
            return to->getMark("&bihuo_lun") * extra;
        }
        return 0;
    }
};

class Yachai : public MasochismSkill
{
public:
    Yachai() : MasochismSkill("yachai")
    {
    }

    int getCeilHandcardNum(ServerPlayer *player) const
    {
        int num = player->getHandcardNum();
        num++;
        return floor(num / 2);
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        ServerPlayer *from = damage.from;
        if (!from || from->isDead() || !player->askForSkillInvoke(this, from)) return;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(this);

        QStringList choices;

        //int hand = ceil(from->getHandcardNum() / 2); 依然是向下取整，大概是因为int除以int还是int
        int hand = getCeilHandcardNum(from);
        if (hand > 0 && from->canDiscard(from, "h"))
            choices << "discard=" + QString::number(hand);
        choices << "limit=" + player->objectName();
        if (!damage.from->isKongcheng())
            choices << "show=" + player->objectName();
        if (choices.isEmpty()) return;

        QString choice = room->askForChoice(from, objectName(), choices.join("+"), QVariant::fromValue(damage));

        if (choice.startsWith("discard")) {
            //int hand = ceil(from->getHandcardNum() / 2);
            int hand = getCeilHandcardNum(from);
            if (hand > 0 && from->canDiscard(from, "h"))
                room->askForDiscard(from, objectName(), hand, hand);
        } else if (choice.startsWith("limit")) {
            room->addPlayerMark(from, "yachai_limit-Clear");
            player->drawCards(2, objectName());
        } else {
            if (from->isKongcheng()) return;
            room->showAllCards(from);
            QStringList suits;
            foreach (const Card *c, from->getHandcards()) {
                QString suit = c->getSuitString();
                if (suits.contains(suit)) continue;
                suits << suit;
            }
            if (suits.isEmpty()) return;
            QString suit = room->askForChoice(from, "yachai_suit", suits.join("+"), QVariant::fromValue(player));
            QList<int> ids;
            foreach (const Card *c, from->getHandcards()) {
                if (c->getSuitString() == suit)
                    ids << c->getEffectiveId();
            }
            if (ids.isEmpty() || player->isDead()) return;
            room->giveCard(from, player, ids, objectName(), true);
        }
    }
};

class YachaiLimit : public CardLimitSkill
{
public:
    YachaiLimit() : CardLimitSkill("#yachai-limit")
    {
    }

    QString limitList(const Player *target) const
    {
        if (target->getMark("yachai_limit-Clear") > 0)
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->getMark("yachai_limit-Clear") > 0)
            return ".|.|.|hand";
        else
            return QString();
    }
};

QingtanCard::QingtanCard()
{
    target_fixed = true;
}

void QingtanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QHash<ServerPlayer *, const Card *> hash;
    QStringList suits, cards;
    foreach(ServerPlayer *p, room->getAllPlayers(source)) {
        if (p->isDead() || p->isKongcheng()) continue;
        const Card *card = room->askForCardShow(p, source, "qingtan");
        hash[p] = card;
        cards << card->toString();
        QString suit = card->getSuitString();
        if (!suits.contains(suit))
            suits << suit;
    }
    foreach(ServerPlayer *p, room->getAllPlayers(source)) {
        const Card *card = hash[p];
        if (!card) continue;
        room->showCard(p, card->getEffectiveId());
    }

    suits << "cancel";
    QString suit = room->askForChoice(source, "qingtan", suits.join("+"), cards);
    if (suit == "cancel") return;

    QList<ServerPlayer *> drawers;
    DummyCard *dummy = new DummyCard();
    dummy->deleteLater();
    foreach(ServerPlayer *p, room->getAllPlayers(source)) {
        const Card *card = hash[p];
        if (!card || card->getSuitString() != suit) continue;
        dummy->addSubcard(card);
        drawers << p;
    }

    if (dummy->subcardsLength() > 0 && source->isAlive())
        room->obtainCard(source, dummy);

    if (!drawers.isEmpty())
        room->drawCards(drawers, 1, "qingtan");

    if (source->isDead()) return;

    QList<CardsMoveStruct> moves;

    CardMoveReason reason;
    reason.m_reason = CardMoveReason::S_REASON_DISMANTLE;
    reason.m_playerId = source->objectName();

    LogMessage log;
    log.type = "$DiscardCardByOther";
    log.from = source;

    foreach(ServerPlayer *p, room->getAllPlayers(source)) {
        if (p->isDead()) continue;
        const Card *card = hash[p];
        if (!card || card->getSuitString() == suit || !p->hasCard(card)) continue;

        log.to.clear();
        log.to << p;
        log.card_str = card->toString();
        room->sendLog(log);

        reason.m_targetId = p->objectName();

        CardsMoveStruct move(card->getEffectiveId(), p, NULL, Player::PlaceUnknown, Player::DiscardPile, reason);
        moves.append(move);
    }
    if (!moves.isEmpty())
        room->moveCardsAtomic(moves, true);
}

class Qingtan : public ZeroCardViewAsSkill
{
public:
    Qingtan() : ZeroCardViewAsSkill("qingtan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QingtanCard");
    }

    const Card *viewAs() const
    {
        return new QingtanCard;
    }
};

ZhukouCard::ZhukouCard()
{
}

bool ZhukouCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < 2 && to_select != Self;
}

bool ZhukouCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void ZhukouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *target, targets) {
        if (target->isAlive())
            room->cardEffect(this, source, target);
    }
}

void ZhukouCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    room->damage(DamageStruct("zhukou", effect.from->isAlive() ? effect.from : NULL, effect.to, 1));
}

class ZhukouVS : public ZeroCardViewAsSkill
{
public:
    ZhukouVS() : ZeroCardViewAsSkill("zhukou")
    {
        response_pattern = "@@zhukou";
    }

    const Card *viewAs() const
    {
        return new ZhukouCard;
    }
};

class Zhukou : public PhaseChangeSkill
{
public:
    Zhukou() : PhaseChangeSkill("zhukou")
    {
        view_as_skill = new ZhukouVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish || player->getMark("damage_point_round") > 0) return false;
        Room *room = player->getRoom();
        if (room->alivePlayerCount() < 3) return false;
        room->askForUseCard(player, "@@zhukou", "@zhukou");
        return false;
    }
};

class ZhukouDamage : public TriggerSkill
{
public:
    ZhukouDamage() : TriggerSkill("#zhukou")
    {
        events << Damage;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent() || !player->hasSkill("zhukou")) return false;
        ServerPlayer *current = room->getCurrent();
        if (current->getPhase() != Player::Play) return false;
        bool first = player->getMark("zhukou-PlayClear") == 0;
        room->addPlayerMark(player, "zhukou-PlayClear");
        if (!first) return false;
        int used = player->getMark("jingce");
        if (!player->askForSkillInvoke("zhukou", "zhukou_draw:" + QString::number(used))) return false;
        room->broadcastSkillInvoke("zhukou");
        player->drawCards(used, "zhukou");
        return false;
    }
};

class Mengqing : public PhaseChangeSkill
{
public:
    Mengqing() : PhaseChangeSkill("mengqing")
    {
        frequency = Wake;
        waked_skills = "yuyun";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark("mengqing") > 0) return false;
        if (player->canWake("mengqing")) return true;
        int wounded = 0;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isWounded())
                wounded++;
        }
        return wounded > player->getHp();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("zhouyi", "mengqing");
        room->setPlayerMark(player, "mengqing", 1);
        if (room->changeMaxHpForAwakenSkill(player, 3)) {
            int recover = qMin(3, player->getMaxHp() - player->getHp());
            room->recover(player, RecoverStruct(player, NULL, recover));
            if (player->isDead()) return false;
            room->handleAcquireDetachSkills(player, "-zhukou|yuyun");
        }
        return false;
    }
};

class Yuyun : public PhaseChangeSkill
{
public:
    Yuyun() : PhaseChangeSkill("yuyun")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        QString choice = room->askForChoice(player, objectName(), "hp+maxhp");
        if (choice == "hp")
            room->loseHp(player);
        else if (choice == "maxhp" && player->getMaxHp() > 1)
            room->loseMaxHp(player);

        if (player->isDead()) return false;

        int max = player->getLostHp() + 1;
        QStringList chosen, has_chosen;

        for (int i = 1; i <= max; i++) {
            if (player->isDead()) return false;
            QStringList choices;
            if (!chosen.contains("draw"))
                choices << "draw";
            if (!chosen.contains("damage"))
                choices << "damage";
            if (!chosen.contains("maxcard"))
                choices << "maxcard";

            if (!chosen.contains("obtain")) {
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (!p->isAllNude()) {
                        choices << "obtain";
                        break;
                    }
                }
            }

            if (!chosen.contains("drawmaxhp"))
                choices << "drawmaxhp";

            if (i > 1)
                choices << "cancel";

            choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant(), has_chosen.join("+"));
            if (choice == "cancel") break;
            chosen.append(choice);
            has_chosen.append(choice);
        }

        foreach (QString cho, chosen) {
            if (player->isDead()) return false;
            if (cho == "draw")
                player->drawCards(2, objectName());
            else if (cho == "damage") {
                ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@yuyun-damage");
                room->doAnimate(1, player->objectName(), t->objectName());
                room->damage(DamageStruct("yuyun", player, t));
                room->addPlayerMark(player, "yuyun_from-Clear");
                room->addPlayerMark(t, "yuyun_to-Clear");
            } else if (cho == "maxcard")
                room->addMaxCards(player, 999999);
            else if (cho == "obtain") {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (!p->isAllNude())
                        targets << p;
                }
                if (targets.isEmpty()) continue;
                ServerPlayer *t = room->askForPlayerChosen(player, targets, "yuyun_obtain", "@yuyun-obtain");
                room->doAnimate(1, player->objectName(), t->objectName());
                int id = room->askForCardChosen(player, t, "hej", objectName());
                room->obtainCard(player, id, false);
            } else if (cho == "drawmaxhp") {
                ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), "yuyun_drawmaxhp", "@yuyun-drawmaxhp");
                room->doAnimate(1, player->objectName(), t->objectName());
                int num = qMin(5, t->getMaxHp() - t->getHandcardNum());
                if (num > 0)
                    t->drawCards(num, objectName());
            }
        }
        return false;
    }
};

class YuyunTargetMod : public TargetModSkill
{
public:
    YuyunTargetMod() : TargetModSkill("#yuyun-target")
    {
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("yuyun_from-Clear") > 0 && to && to->getMark("yuyun_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("yuyun_from-Clear") > 0 && to && to->getMark("yuyun_to-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

class ZhengeVS : public ZeroCardViewAsSkill
{
public:
    ZhengeVS() : ZeroCardViewAsSkill("zhenge")
    {
        response_pattern = "@@zhenge!";
    }

    const Card *viewAs() const
    {
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("_zhenge");
        return slash;
    }
};

class Zhenge : public PhaseChangeSkill
{
public:
    Zhenge() : PhaseChangeSkill("zhenge")
    {
        view_as_skill = new ZhengeVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        ServerPlayer *t = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@zhenge-invoke", true, true);
        if (!t) return false;
        room->broadcastSkillInvoke(objectName());

        QStringList names = player->property("ZhengeTargets").toStringList();
        if (!names.contains(t->objectName())) {
            names << t->objectName();
            room->setPlayerProperty(player, "ZhengeTargets", names);
        }

        if (t->getMark("&zhenge") < 5) {
            room->addAttackRange(t, 1, false);
            room->addPlayerMark(t, "&zhenge");
        }
        if (t->isDead() || player->isDead()) return false;

        bool can_slash = false;
        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->deleteLater();
        slash->setSkillName("_zhenge");

        foreach (ServerPlayer *p, room->getOtherPlayers(t)) {
            if (!t->inMyAttackRange(p)) return false;
            if (t->canSlash(p, slash))
                can_slash = true;
        }
        if (!can_slash || !player->askForSkillInvoke(this, "zhenge_slash:" + t->objectName(), false)) return false;

        if (room->askForUseCard(t, "@@zhenge!", "@zhenge")) return false;

        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, room->getOtherPlayers(t)) {
            if (t->canSlash(p, slash))
                tos << p;
        }
        if (tos.isEmpty()) return false;
        ServerPlayer *to = tos.at(qrand() % tos.length());
        room->useCard(CardUseStruct(slash, t, to));
        return false;
    }
};

class Xinghan : public TriggerSkill
{
public:
    Xinghan() : TriggerSkill("xinghan")
    {
        events << Damage;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *) const
    {
        return true;
    }

    bool isOnlyMostHandcardNumPlayer(ServerPlayer *player) const
    {
        int num = player->getHandcardNum();
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() >= num)
                return true;
        }
        return false;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash") || !damage.card->hasFlag("xinghan_first_slash")) return false;

        ServerPlayer *user = room->getCardUser(damage.card);
        if (!user) return false;
        QString name = user->objectName();

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            QStringList names = p->property("ZhengeTargets").toStringList();
            if (!names.contains(name)) continue;
            room->sendCompulsoryTriggerLog(p, this);
            int x = 1;
            if (isOnlyMostHandcardNumPlayer(p)) //&& user->isAlive()
                x = qMin(5, user->getAttackRange());
            p->drawCards(x, objectName());
        }
        return false;
    }
};

class XinghanRecord : public TriggerSkill
{
public:
    XinghanRecord() : TriggerSkill("#xinghan-record")
    {
        events << PreCardUsed << EventPhaseStart;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            if (!room->hasCurrent()) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash") && !room->getTag("XinghanRecord").toBool()) {
                room->setTag("XinghanRecord", true);
                room->setCardFlag(use.card, "xinghan_first_slash");
            }
        } else {
            if (player->getPhase() != Player::NotActive) return false;
            room->setTag("XinghanRecord", false);
        }
        return false;
    }
};

class Tianze : public TriggerSkill
{
public:
    Tianze() : TriggerSkill("tianze")
    {
        events << FinishJudge << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (!judge->card->isBlack()) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead() || !p->hasSkill(this)) continue;
                room->sendCompulsoryTriggerLog(p, this);
                p->drawCards(1, objectName());
            }
        } else {
            if (player->getPhase() != Player::Play) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isBlack() || use.card->isKindOf("SkillCard") || !use.m_isHandcard) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this) || p->getMark("tianze-Clear") > 0) continue;
                if (!p->canDiscard(p, "he")) continue;
                const Card *card = room->askForCard(p, ".|black", "@tianze-discard:" + player->objectName(), data, objectName());
                if (!card) continue;
                room->addPlayerMark(p, "tianze-Clear");
                room->damage(DamageStruct("tianze", p, player));
            }
        }
        return false;
    }
};

DifaCard::DifaCard()
{
    target_fixed = true;
}

void DifaCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->addPlayerMark(source, "difa-Clear");
    QList<int> tricks, ids = room->getDrawPile() + room->getDiscardPile();
    foreach (int id, ids) {
        if (Sanguosha->getCard(id)->isKindOf("TrickCard"))
            tricks << id;
    }
    if (tricks.isEmpty()) return;
    room->fillAG(tricks, source);
    int trick = room->askForAG(source, tricks, false, "difa");
    room->clearAG(source);
    room->obtainCard(source, trick, true);
}

class DifaVS : public OneCardViewAsSkill
{
public:
    DifaVS() : OneCardViewAsSkill("difa")
    {
        response_pattern = "@@difa";
    }

    bool viewFilter(const Card *to_select) const
    {
        QStringList strs = Self->property("DifaCardStr").toString().split("+");
        QList<int> ids = StringList2IntList(strs);
        return ids.contains(to_select->getEffectiveId()) && Self->canDiscard(Self, to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *originalCard) const
    {
        DifaCard *c = new DifaCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class Difa : public TriggerSkill
{
public:
    Difa() : TriggerSkill("difa")
    {
        events << CardsMoveOneTime;
        view_as_skill = new DifaVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive || player->getMark("difa-Clear") > 0) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to != player || !move.from_places.contains(Player::DrawPile) || move.to_place != Player::PlaceHand) return false;

        QList<int> ids;
        for (int i = 0; i < move.card_ids.length(); i++) {
            int id = move.card_ids.at(i);
            if (room->getCardOwner(id) == player && room->getCardPlace(id) == Player::PlaceHand && player->canDiscard(player, id)) {
                if (move.from_places.at(i) == Player::DrawPile && Sanguosha->getCard(id)->isRed()) {
                    ids << id;
                }
            }
        }
        if (ids.isEmpty()) return false;

        QString str = IntList2StringList(ids).join("+");
        room->setPlayerProperty(player, "DifaCardStr", str);

        try {
            room->askForUseCard(player, "@@difa", "@difa", -1, Card::MethodDiscard);
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                room->setPlayerProperty(player, "DifaCardStr", QString());
            throw triggerEvent;
        }

        room->setPlayerProperty(player, "DifaCardStr", QString());
        return false;
    }
};

class Zhuangshu : public PhaseChangeSkill
{
public:
    Zhuangshu() : PhaseChangeSkill("zhuangshu")
    {
        waked_skills = "_qiongshu,_xishu,_jinshu";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::RoundStart;
    }

    int getBaoshu(Room *room, const QString &baoshu) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            QList<int> ids = p->getEquipsId() + p->getJudgingAreaID();
            foreach (int id, ids) {
                const Card *card = Sanguosha->getEngineCard(id);
                if (card->objectName() == baoshu)
                    return id;
            }
        }
        return -1;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "h")) continue;
            const Card *card = room->askForCard(p, "..", "@zhuangshu-discard:" + player->objectName(), QVariant::fromValue(player), objectName());
            if (!card) continue;
            room->broadcastSkillInvoke(this);

            if (player->isDead() || !player->hasTreasureArea() || player->getTreasure()) continue;

            QString baoshu = "_qiongshu";
            if (card->isKindOf("TrickCard"))
                baoshu = "_xishu";
            else if (card->isKindOf("EquipCard"))
                baoshu = "_jinshu";

            int id = getBaoshu(room, baoshu);
            if (id >= 0) {
                const Card *card = Sanguosha->getCard(id);
                CardMoveReason reason(CardMoveReason::S_REASON_TRANSFER, p->objectName(), "zhuangshu", QString());
                room->moveCardTo(card, player, Player::PlaceEquip, reason, true);
            } else {
                id = player->getDerivativeCard(baoshu, Player::PlaceEquip);
                if (id > 0 && room->getCardOwner(id) == player && room->getCardPlace(id) == Player::PlaceEquip) {
                    LogMessage log;
                    log.type = "#ZhuangshuEquip";
                    log.from = p;
                    log.to << player;
                    log.arg = baoshu;
                    room->sendLog(log);
                }
            }
        }
        return false;
    }
};

class ZhuangshuStart : public GameStartSkill
{
public:
    ZhuangshuStart() : GameStartSkill("#zhuangshu")
    {
    }

    void onGameStart(ServerPlayer *player) const
    {
        if (!player->hasSkill("zhuangshu")) return;
        if (!player->hasTreasureArea() || player->getTreasure()) return;

        QList<int> baoshus;
        QStringList baoshu_names;
        baoshu_names << "_qiongshu" << "_xishu" << "_jinshu";
        foreach (QString baoshu, baoshu_names) {
            int id = player->getDerivativeCard(baoshu, Player::PlaceTable);
            if (id > -1)
                baoshus << id;
        }
        if (baoshus.isEmpty()) return;

        if (!player->askForSkillInvoke("zhuangshu")) return;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke("zhuangshu");

        room->fillAG(baoshus, player);
        int id = room->askForAG(player, baoshus, false, "zhuangshu");
        room->clearAG(player);

        CardMoveReason reason(CardMoveReason::S_REASON_EXCLUSIVE, "zhuangshu");
        CardsMoveStruct move(id, NULL, player, Player::PlaceTable, Player::PlaceEquip, reason);
        room->moveCardsAtomic(move, true);
        if (room->getCardOwner(id) == player && room->getCardPlace(id) == Player::PlaceEquip) {
            LogMessage log;
            log.type = "#ZhuangshuEquip";
            log.from = player;
            log.to << player;
            log.arg = Sanguosha->getCard(id)->objectName();
            room->sendLog(log);
        }
        return;
    }
};

class ChuitiVS : public OneCardViewAsSkill
{
public:
    ChuitiVS() : OneCardViewAsSkill("chuiti")
    {
        response_pattern = "@@chuiti";
        expand_pile = "#chuiti";
    }

    bool viewFilter(const Card *to_select) const
    {
        return Self->getPile("#chuiti").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *originalCard) const
    {
        return originalCard;
    }
};

class Chuiti : public TriggerSkill
{
public:
    Chuiti() : TriggerSkill("chuiti")
    {
        events << CardsMoveOneTime;
        view_as_skill = new ChuitiVS;
    }

    bool hasBaoshu(Player *player) const
    {
        QStringList baoshu_names;
        baoshu_names << "_qiongshu" << "_xishu" << "_jinshu";
        foreach (const Card *card, player->getEquips()) {
            if (baoshu_names.contains(card->objectName()))
                return true;
        }
        return false;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("chuiti-Clear") > 0) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DiscardPile || !move.from) return false;

        if (move.from != player && !hasBaoshu(move.from)) return false;

        if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)) return false;
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            QList<int> ids;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                    int id = move.card_ids.at(i);
                    if (room->getCardPlace(id) == Player::DiscardPile) {
                        const Card *card = Sanguosha->getCard(id);
                        if (player->canUse(card))
                            ids << id;
                    }
                }
            }
            if (ids.isEmpty()) return false;

            room->notifyMoveToPile(player, ids, objectName(), Player::DiscardPile, true);

            try {
                room->askForUseCard(player, "@@chuiti", "@chuiti", -1, Card::MethodUse, true, NULL, NULL, "chuiti_use_card");
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                    room->notifyMoveToPile(player, ids, objectName(), Player::DiscardPile, false);
                throw triggerEvent;
            }

            room->notifyMoveToPile(player, ids, objectName(), Player::DiscardPile, false);
        }
        return false;
    }
};

class ChuitiLog : public TriggerSkill
{
public:
    ChuitiLog() : TriggerSkill("#chuiti-log")
    {
        events << ChoiceMade;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (data.isNull() || !data.canConvert<CardUseStruct>()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.from || !use.card || !use.card->hasFlag("chuiti_use_card")) return false;
        //room->setCardFlag(use.card, "-chuiti_use_card");

        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = use.from;
        log.arg = "chuiti";
        room->sendLog(log);
        room->notifySkillInvoked(use.from, "chuiti");
        room->broadcastSkillInvoke("chuiti");

        if (room->hasCurrent())
            room->addPlayerMark(use.from, "chuiti-Clear");
        return false;
    }
};

class Wanwei : public TriggerSkill
{
public:
    Wanwei() : TriggerSkill("wanwei")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("wanwei-Clear") > 0) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from == player && move.from_places.contains(Player::PlaceHand)
            && ((move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE
            && move.reason.m_playerId != move.reason.m_targetId)
            || (move.to && move.to != move.from && move.to_place == Player::PlaceHand
            && move.reason.m_reason != CardMoveReason::S_REASON_GIVE
            && move.reason.m_reason != CardMoveReason::S_REASON_SWAP))) {

            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(this);
            room->addPlayerMark(player, "wanwei-Clear");

            room->fillAG(move.card_ids, player);
            int id = room->askForAG(player, move.card_ids, false, objectName());
            room->clearAG(player);
            const Card *card = Sanguosha->getCard(id);

            QList<int> same_names;
            foreach (int id, room->getDrawPile()) {
                const Card *c = Sanguosha->getCard(id);
                if (c->sameNameWith(card))
                    same_names << id;
            }

            if (same_names.isEmpty()) {
                LogMessage log;
                log.type = "#WanweiDraw";
                log.from = player;
                log.arg = card->objectName();
                room->sendLog(log);
                player->drawCards(1, objectName());
            } else {
                int get = same_names.at(qrand() % same_names.length());
                room->obtainCard(player, get, false);
            }
        }
        return false;
    }
};

class Yuejian : public TriggerSkill
{
public:
    Yuejian() : TriggerSkill("yuejian")
    {
        events << BeforeCardsMove;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("yuejian-Clear") >= 2 || player->isKongcheng()) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from_places.contains(Player::PlaceTable) && move.to_place == Player::DiscardPile
            && (move.reason.m_reason == CardMoveReason::S_REASON_USE || move.reason.m_reason == CardMoveReason::S_REASON_LETUSE)) {

            CardUseStruct use = move.reason.m_useStruct;
            if (!use.card || use.card->isKindOf("SkillCard") || !use.from || use.from == player || !use.to.contains(player)) return false;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(use))) return false;
            room->broadcastSkillInvoke(this);
            room->addPlayerMark(player, "yuejian-Clear");

            room->showAllCards(player);
            if (!use.card->hasSuit() || !room->CardInTable(use.card)) return false;
            Card::Suit suit = use.card->getSuit();
            foreach (const Card *c, player->getHandcards()) {
                if (c->getSuit() == suit)
                    return false;
            }

            QList<int> subcards;
            if (use.card->isVirtualCard())
                subcards = use.card->getSubcards();
            else
                subcards << use.card->getEffectiveId();
            if (!subcards.isEmpty()) {
                move.removeCardIds(subcards);
                data = QVariant::fromValue(move);
            }

            room->obtainCard(player, use.card);
        }
        return false;
    }
};

ZhuningCard::ZhuningCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void ZhuningCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    room->giveCard(from, to, this, "zhuning");

    if (from->isDead()) return;
    QList<int> cards = room->getAvailableCardList(from, "basic,trick", "zhuning");
    foreach (int id, cards) {
        const Card *card = Sanguosha->getEngineCard(id);
        if (!card->isKindOf("Slash") && !card->isDamageCard())
            cards.removeOne(id);
    }
    if (cards.isEmpty()) return;

    room->fillAG(cards, from);
    int id = room->askForAG(from, cards, true, "zhuning");
    room->clearAG(from);
    if (id < 0) return;
    room->setPlayerMark(from, "zhuning_id-PlayClear", id + 1);

    try {
        room->askForUseCard(from, "@@zhuning", "@zhuning:" + Sanguosha->getEngineCard(id)->objectName(), -1, Card::MethodUse, false, NULL,
                            NULL, "zhuning_used_card_" + from->objectName());
    }
    catch (TriggerEvent e) {
        if (e == TurnBroken || e == StageChange) {
            room->setPlayerMark(from, "zhuning_id-PlayClear", 0);
        }
        throw e;
    }

    room->setPlayerMark(from, "zhuning_id-PlayClear", 0);
}

class ZhuningVS : public ViewAsSkill
{
public:
    ZhuningVS() : ViewAsSkill("zhuning")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern == "@@zhuning")
            return false;
        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern == "@@zhuning") {
            if (!cards.isEmpty()) return NULL;
            int id = Self->getMark("zhuning_id-PlayClear") - 1;
            if (id < 0) return NULL;
            const Card *card = Sanguosha->getEngineCard(id);
            Card *c = Sanguosha->cloneCard(card->objectName(), Card::NoSuit, 0);
            c->setSkillName("_zhuning");
            return c;
        }

        if (cards.isEmpty()) return NULL;
        ZhuningCard *c = new ZhuningCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("zhuning_extra-PlayClear") > 0)
            return player->usedTimes("ZhuningCard") < 2;
        return !player->hasUsed("ZhuningCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@zhuning";
    }
};

class Fengxiang : public TriggerSkill
{
public:
    Fengxiang() : TriggerSkill("fengxiang")
    {
        events << Damaged << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    static bool sortByXi(ServerPlayer *a, ServerPlayer *b)
    {
        return a->getMark("&lyznxi") > b->getMark("&lyznxi");
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QList<ServerPlayer *> players = room->getAlivePlayers();

        if (event == Damaged) {
            if (!player->hasSkill(this) || player->isDead()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            qSort(players.begin(), players.end(), sortByXi);

            int mark1 = players.first()->getMark("&lyznxi"), mark2 = players.at(1)->getMark("&lyznxi");
            if (mark1 > 0 && mark2 != mark1)
                room->recover(players.first(), RecoverStruct(player));
            else
                player->drawCards(1, objectName());
        } else {
            /*CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from != player) return false;
            if (!move.from_places.contains(Player::PlaceHand) && move.to_place != Player::PlaceHand) return false;

            ServerPlayer *mostxi = room->getTag("MostXiPlayer").value<ServerPlayer *>();
            qSort(players.begin(), players.end(), sortByXi);

            int mark1 = players.first()->getMark("&lyznxi"), mark2 = players.at(1)->getMark("&lyznxi");
            if (mark1 > 0 && mark2 != mark1) {
                room->setTag("MostXiPlayer", QVariant::fromValue(players.first()));
                if (players.first() != mostxi && mostxi) {
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (p->isDead() || !p->hasSkill(this)) continue;
                        room->sendCompulsoryTriggerLog(p, this);
                        p->drawCards(1, objectName());
                    }
                }
            }*/
            if (data.toString() != "fengxiang") return false;
            room->sendCompulsoryTriggerLog(player, this);
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class Zhuning : public TriggerSkill
{
public:
    Zhuning() : TriggerSkill("zhuning")
    {
        events << CardsMoveOneTime << DamageDone << CardFinished;
        view_as_skill = new ZhuningVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    /*int getPriority(TriggerEvent event) const
    {
        if (event == CardsMoveOneTime)
            return TriggerSkill::getPriority(event) + 2;
        return TriggerSkill::getPriority(event);
    }*/

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            QVariantList xi = room->getTag("ZhuningXi").toList();

            if (move.from == player && move.from_places.contains(Player::PlaceHand)) {
                foreach (int id, move.card_ids) {
                    if (!xi.contains(QVariant(id))) continue;
                    xi.removeOne(id);
                }
                room->setTag("ZhuningXi", xi);

                int mark = 0;
                foreach (int id, player->handCards()) {
                    if (!xi.contains(QVariant(id))) continue;
                    mark++;
                }
                room->setPlayerMark(player, "&lyznxi", mark);

                const TriggerSkill *fengxiang = Sanguosha->getTriggerSkill("fengxiang");  //神杀对CardsMoveOneTimeStruct的处理，导致只能这样做了
                if (fengxiang) {
                    ServerPlayer *mostxi = room->getTag("MostXiPlayer").value<ServerPlayer *>();
                    QList<ServerPlayer *> players = room->getAlivePlayers();
                    qSort(players.begin(), players.end(), Fengxiang::sortByXi);
                    int mark1 = players.first()->getMark("&lyznxi"), mark2 = players.at(1)->getMark("&lyznxi");
                    if (mark1 > 0 && mark2 != mark1) {
                        room->setTag("MostXiPlayer", QVariant::fromValue(players.first()));
                        if (players.first() != mostxi && mostxi) {
                            foreach (ServerPlayer *p, room->getAllPlayers()) {
                                if (p->isDead() || !p->hasSkill("fengxiang")) continue;
                                QVariant _data = "fengxiang";
                                fengxiang->trigger(CardsMoveOneTime, room, p, _data);
                            }
                        }
                    }
                }
            }

            if (move.to != player || move.to_place != Player::PlaceHand || move.reason.m_reason != CardMoveReason::S_REASON_GIVE ||
                    move.reason.m_skillName != objectName()) return false;
            foreach (int id, move.card_ids) {
                if (xi.contains(QVariant(id))) continue;
                xi << id;
            }
            room->setTag("ZhuningXi", xi);

            int mark = 0;
            foreach (int id, player->handCards()) {
                if (!xi.contains(QVariant(id))) continue;
                mark++;
            }
            room->setPlayerMark(player, "&lyznxi", mark);

            const TriggerSkill *fengxiang = Sanguosha->getTriggerSkill("fengxiang");
            if (fengxiang) {
                ServerPlayer *mostxi = room->getTag("MostXiPlayer").value<ServerPlayer *>();
                QList<ServerPlayer *> players = room->getAlivePlayers();
                qSort(players.begin(), players.end(), Fengxiang::sortByXi);
                int mark1 = players.first()->getMark("&lyznxi"), mark2 = players.at(1)->getMark("&lyznxi");
                if (mark1 > 0 && mark2 != mark1) {
                    room->setTag("MostXiPlayer", QVariant::fromValue(players.first()));
                    if (players.first() != mostxi && mostxi) {
                        foreach (ServerPlayer *p, room->getAllPlayers()) {
                            if (p->isDead() || !p->hasSkill("fengxiang")) continue;
                            QVariant _data = "fengxiang";
                            fengxiang->trigger(CardsMoveOneTime, room, p, _data);
                        }
                    }
                }
            }
        } else if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card) return false;
            if (damage.card->isKindOf("Slash") || (damage.card->isDamageCard() && damage.card->isNDTrick()))
                room->setCardFlag(damage.card, "zhuning_damaged");
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || use.card->hasFlag("zhuning_damaged")) return false;
            if (use.card->isKindOf("Slash") || (use.card->isDamageCard() && use.card->isNDTrick())) {
                ServerPlayer *user = NULL;
                foreach (QString flag, use.card->getFlags()) {
                    if (!flag.startsWith("zhuning_used_card_")) continue;
                    QString name = flag.split("_").last();
                    user = room->findChild<ServerPlayer *>(name);
                    if (user) break;
                }
                if (user && user->isAlive())
                    room->addPlayerMark(user, "zhuning_extra-PlayClear");
            }
        }

        return false;
    }
};

SP4Package::SP4Package()
    : Package("sp4")
{
    General *tenyear_wangyun = new General(this, "tenyear_wangyun", "qun", 4);
    tenyear_wangyun->addSkill(new TenyearLianji);
    tenyear_wangyun->addSkill(new TenyearMoucheng);
    tenyear_wangyun->addRelateSkill("tenyearjingong");

    General *ol_wangyun = new General(this, "ol_wangyun", "qun", 4);
    ol_wangyun->addSkill(new OLLianji);
    ol_wangyun->addSkill(new OLMoucheng);
    ol_wangyun->addSkill(new OLMouchengUse);
    ol_wangyun->addRelateSkill("tenyearjingong");
    related_skills.insertMulti("olmoucheng", "#olmoucheng-use");

    General *second_ol_wangyun = new General(this, "second_ol_wangyun", "qun", 4);
    second_ol_wangyun->addSkill("ollianji");
    second_ol_wangyun->addSkill(new SecondOLMoucheng);
    second_ol_wangyun->addSkill(new SecondOLMouchengDamage);
    second_ol_wangyun->addRelateSkill("tenyearjingong");
    related_skills.insertMulti("secondolmoucheng", "#secondolmoucheng-damage");

    General *mobile_wangyun = new General(this, "mobile_wangyun", "qun", 4);
    mobile_wangyun->addSkill(new MobileLianji);
    mobile_wangyun->addSkill(new MobileMoucheng);
    mobile_wangyun->addRelateSkill("jingong");

    General *new_lifeng = new General(this, "new_lifeng", "shu", 3);
    new_lifeng->addSkill(new NewTunchu);
    new_lifeng->addSkill(new NewTunchuPut);
    new_lifeng->addSkill(new NewTunchuLimit);
    new_lifeng->addSkill(new NewShuliang);
    related_skills.insertMulti("newtunchu", "#newtunchu-put");
    related_skills.insertMulti("newtunchu", "#newtunchu-limit");

    General *new_liuxie = new General(this, "new_liuxie", "qun", 3);
    new_liuxie->addSkill("mizhao");
    new_liuxie->addSkill(new NewTianming);

    General *huangchengyan = new General(this, "huangchengyan", "qun", 3);
    huangchengyan->addSkill(new Guanxu);
    huangchengyan->addSkill(new Yashi);
    huangchengyan->addSkill(new YashiClear);
    huangchengyan->addSkill(new YashiInvalidity);
    related_skills.insertMulti("yashi", "#yashi");
    related_skills.insertMulti("yashi", "#yashi-invalidity");

    General *luyusheng = new General(this, "luyusheng", "wu", 3, false);
    luyusheng->addSkill(new Zhente);
    luyusheng->addSkill(new ZhenteClear);
    luyusheng->addSkill(new Zhiwei);
    luyusheng->addSkill(new ZhiweiEffect);
    related_skills.insertMulti("zhente", "#zhente");
    related_skills.insertMulti("zhiwei", "#zhiwei");

    General *sp_niujin = new General(this, "sp_niujin", "wei", 4);
    sp_niujin->addSkill(new SpCuorui);
    sp_niujin->addSkill(new SpCuoruiRecord);
    sp_niujin->addSkill(new SpLiewei);
    related_skills.insertMulti("spcuorui", "#spcuorui");

    General *second_sp_niujin = new General(this, "second_sp_niujin", "wei", 4);
    second_sp_niujin->setImage("sp_niujin");
    second_sp_niujin->addSkill(new SecondSpCuorui);
    second_sp_niujin->addSkill(new SecondSpLiewei);

    General *zhouqun = new General(this, "zhouqun", "shu", 3);
    zhouqun->addSkill(new Tiansuan);
    zhouqun->addSkill(new TiansuanEffect);
    related_skills.insertMulti("tiansuan", "#tiansuan");

    General *liangxing = new General(this, "liangxing", "qun", 4);
    liangxing->addSkill(new Lulve);
    liangxing->addSkill(new Zhuixi);

    General *huaxin = new General(this, "huaxin", "wei", 3);
    huaxin->addSkill(new Wanggui);
    huaxin->addSkill(new Xibing);

    General *yangwan = new General(this, "yangwan", "shu", 3, false);
    yangwan->addSkill(new Youyan);
    yangwan->addSkill(new Zhuihuan);
    yangwan->addSkill(new ZhuihuanEffect);
    related_skills.insertMulti("zhuihuan", "#zhuihuan");

    General *tangji = new General(this, "tangji", "qun", 3, false);
    tangji->addSkill(new Kangge);
    tangji->addSkill(new Jielie);

    General *gaogan = new General(this, "gaogan", "qun", 4);
    gaogan->addSkill(new Juguan);

    General *duxi = new General(this, "duxi", "wei", 3);
    duxi->addSkill(new Quxi);
    duxi->addSkill(new QuxiDraw);
    duxi->addSkill(new Bixiong);
    duxi->addSkill(new BixiongClear);
    duxi->addSkill(new BixiongProhibit);
    related_skills.insertMulti("quxi", "#quxi");
    related_skills.insertMulti("bixiong", "#bixiong-clear");
    related_skills.insertMulti("bixiong", "#bixiong-prohibit");

    General *lvkuanglvxiang = new General(this, "lvkuanglvxiang", "qun", 4);
    lvkuanglvxiang->addSkill(new Qigong);
    lvkuanglvxiang->addSkill(new Liehou);

    General *duanwei = new General(this, "duanwei", "qun", 4);
    duanwei->addSkill(new Langmie);

    General *second_duanwei = new General(this, "second_duanwei", "qun", 4);
    second_duanwei->setImage("duanwei");
    second_duanwei->addSkill(new SecondLangmie);

    General *tenyear_zoushi = new General(this, "tenyear_zoushi", "qun", 3, false);
    tenyear_zoushi->addSkill(new TenyearHuoshui);
    tenyear_zoushi->addSkill(new TenyearHuoshuiClear);
    tenyear_zoushi->addSkill(new TenyearQingcheng);
    related_skills.insertMulti("tenyearhuoshui", "#tenyearhuoshui-clear");

    General *tenyear_zhugeguo = new General(this, "tenyear_zhugeguo", "shu", 3, false);
    tenyear_zhugeguo->addSkill(new TenyearYuhua);
    tenyear_zhugeguo->addSkill(new TenyearQirang);
    tenyear_zhugeguo->addSkill(new TenyearQirangEffect);
    related_skills.insertMulti("tenyearqirang", "#tenyearqirang");

    General *qiuliju = new General(this, "qiuliju", "qun", 6);
    qiuliju->setStartHp(4);
    qiuliju->addSkill(new Koulve("koulve"));
    qiuliju->addSkill(new Suirenq);

    General *second_qiuliju = new General(this, "second_qiuliju", "qun", 6);
    second_qiuliju->setStartHp(4);
    second_qiuliju->addSkill(new Koulve("secondkoulve"));
    second_qiuliju->addSkill(new FakeMoveSkill("secondkoulve"));
    second_qiuliju->addSkill("suirenq");
    related_skills.insertMulti("secondkoulve", "#secondkoulve-fake-move");

    General *mifangfushiren = new General(this, "mifangfushiren", "shu", 4);
    mifangfushiren->addSkill(new FengshiMF);
    mifangfushiren->addSkill(new FengshiMFDamage);
    related_skills.insertMulti("fengshimf", "#fengshimf");

    General *zhanghu = new General(this, "zhanghu", "wei", 4);
    zhanghu->addSkill(new Cuijian);
    zhanghu->addSkill(new Tongyuan);
    zhanghu->addSkill(new TongyuanEffect);
    related_skills.insertMulti("tongyuan", "#tongyuan");

    General *second_zhanghu = new General(this, "second_zhanghu", "wei", 4);
    second_zhanghu->addSkill(new SecondCuijian);
    second_zhanghu->addSkill(new SecondTongyuan);
    second_zhanghu->addSkill(new SecondTongyuanEffect);
    related_skills.insertMulti("secondtongyuan", "#secondtongyuan");

    General *sp_tongyuan = new General(this, "sp_tongyuan", "qun", 4);
    sp_tongyuan->addSkill(new Chaofeng("chaofeng"));
    sp_tongyuan->addSkill(new Chuanshu("chuanshu"));
    sp_tongyuan->addSkill(new ChuanshuDeath("chuanshu"));
    sp_tongyuan->addRelateSkill("longdan");
    sp_tongyuan->addRelateSkill("congjian");
    sp_tongyuan->addRelateSkill("chuanyun");
    related_skills.insertMulti("chuanshu", "#chuanshu");

    General *second_sp_tongyuan = new General(this, "second_sp_tongyuan", "qun", 4);
    second_sp_tongyuan->addSkill(new Chaofeng("secondchaofeng"));
    second_sp_tongyuan->addSkill(new Chuanshu("secondchuanshu"));
    second_sp_tongyuan->addSkill(new ChuanshuDeath("secondchuanshu"));
    second_sp_tongyuan->addRelateSkill("longdan");
    second_sp_tongyuan->addRelateSkill("congjian");
    second_sp_tongyuan->addRelateSkill("chuanyun");
    related_skills.insertMulti("secondchuanshu", "#secondchuanshu");

    General *simafu = new General(this, "simafu", "wei", 3);
    simafu->addSkill(new Xunde);
    simafu->addSkill(new Chenjie);

    General *mayuanyi = new General(this, "mayuanyi", "qun", 4);
    mayuanyi->addSkill(new Jibing);
    mayuanyi->addSkill(new Wangjing);
    mayuanyi->addSkill(new Moucuan);
    mayuanyi->addRelateSkill("binghuo");

    General *yanpu = new General(this, "yanpu", "qun", 3);
    yanpu->addSkill(new Huantu);
    yanpu->addSkill(new Bihuo);
    yanpu->addSkill(new BihuoDistance);
    related_skills.insertMulti("bihuo", "#bihuo");

    General *heyan = new General(this, "heyan", "wei", 3);
    heyan->addSkill(new Yachai);
    heyan->addSkill(new YachaiLimit);
    heyan->addSkill(new Qingtan);
    related_skills.insertMulti("yachai", "#yachai-limit");

    General *zhouyi = new General(this, "zhouyi", "wu", 3, false);
    zhouyi->addSkill(new Zhukou);
    zhouyi->addSkill(new ZhukouDamage);
    zhouyi->addSkill(new Mengqing);
    zhouyi->addRelateSkill("yuyun");
    related_skills.insertMulti("zhukou", "#zhukou");

    General *wanniangongzhu = new General(this, "wanniangongzhu", "qun", 3, false);
    wanniangongzhu->addSkill(new Zhenge);
    wanniangongzhu->addSkill(new Xinghan);
    wanniangongzhu->addSkill(new XinghanRecord);
    related_skills.insertMulti("xinghan", "#xinghan-record");

    General *zhangning = new General(this, "zhangning", "qun", 3, false);
    zhangning->addSkill(new Tianze);
    zhangning->addSkill(new Difa);

    General *fengfangnv = new General(this, "fengfangnv", "qun", 3, false);
    fengfangnv->addSkill(new Zhuangshu);
    fengfangnv->addSkill(new ZhuangshuStart);
    fengfangnv->addSkill(new Chuiti);
    fengfangnv->addSkill(new ChuitiLog);
    fengfangnv->addRelateSkill("_qiongshu");
    fengfangnv->addRelateSkill("_xishu");
    fengfangnv->addRelateSkill("_jinshu");
    related_skills.insertMulti("zhuangshu", "#zhuangshu");
    related_skills.insertMulti("chuiti", "#chuiti-log");

    General *bianfuren = new General(this, "bianfuren", "wei", 3, false);
    bianfuren->addSkill(new Wanwei);
    bianfuren->addSkill(new Yuejian);

    General *liuyong = new General(this, "liuyong", "shu", 3);
    liuyong->addSkill(new Zhuning);
    liuyong->addSkill(new Fengxiang);

    //addMetaObject<Meirenji>();
    //addMetaObject<Xiaolicangdao>();
    addMetaObject<TenyearLianjiCard>();
    addMetaObject<OLLianjiCard>();
    addMetaObject<MobileLianjiCard>();
    addMetaObject<NewShuliangCard>();
    addMetaObject<GuanxuCard>();
    addMetaObject<GuanxuChooseCard>();
    addMetaObject<GuanxuDiscardCard>();
    addMetaObject<SpCuoruiCard>();
    addMetaObject<SecondSpCuoruiCard>();
    addMetaObject<TiansuanCard>();
    addMetaObject<JuguanCard>();
    addMetaObject<QuxiCard>();
    addMetaObject<LiehouCard>();
    addMetaObject<TenyearHuoshuiCard>();
    addMetaObject<TenyearQingchengCard>();
    addMetaObject<CuijianCard>();
    addMetaObject<SecondCuijianCard>();
    addMetaObject<QingtanCard>();
    addMetaObject<ZhukouCard>();
    addMetaObject<DifaCard>();
    addMetaObject<ZhuningCard>();

    skills << new JingongSkill("jingong") << new JingongSkill("tenyearjingong") << new Chuanyun << new Binghuo << new BinghuoRecord
           << new Yuyun << new YuyunTargetMod;

    related_skills.insertMulti("binghuo", "#binghuo");
    related_skills.insertMulti("yuyun", "#yuyun-target");

    QList<Card *> cards;
    cards << new Meirenji(Card::NoSuit, 0) << new Xiaolicangdao(Card::NoSuit, 0);
    foreach(Card *card, cards)
        card->setParent(this);
}

ADD_PACKAGE(SP4)
