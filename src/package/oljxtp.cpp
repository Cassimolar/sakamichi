#include "oljxtp.h"
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
#include "wind.h"

class OLPaoxiao : public TriggerSkill
{
public:
    OLPaoxiao() : TriggerSkill("olpaoxiao")
    {
        frequency = Compulsory;
        events << DamageCaused << SlashMissed;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == SlashMissed)
            room->setPlayerMark(player, "olpaoxiao_missed-Clear", 1);
        else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (player->getMark("olpaoxiao_missed-Clear") <= 0) return false;
            room->setPlayerMark(player, "olpaoxiao_missed-Clear", 0);
            LogMessage log;
            log.type = "#OlpaoxiaoDamage";
            log.from = player;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class OLPaoxiaoMod : public TargetModSkill
{
public:
    OLPaoxiaoMod() : TargetModSkill("#olpaoxiaomod")
    {
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("olpaoxiao"))
            return 1000;
        else
            return 0;
    }
};

class OLTishen : public PhaseChangeSkill
{
public:
    OLTishen() : PhaseChangeSkill("oltishen")
    {
        frequency = Limited;
        limit_mark = "@oltishenMark";
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start || player->getMark("@oltishenMark") <= 0) return false;
        if (player->getLostHp() <= 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("ol_jiezhangfei", "oltishen");
        room->removePlayerMark(player, "@oltishenMark");
        int x = player->getMaxHp() - player->getHp();
        if (x > 0) {
            room->recover(player, RecoverStruct(player, NULL, x));
            player->drawCards(x, objectName());
        }
        return false;
    }
};

class OLLongdan : public OneCardViewAsSkill
{
public:
    OLLongdan() : OneCardViewAsSkill("ollongdan")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->isWounded() || Slash::IsAvailable(player) || Analeptic::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "slash"
                || pattern == "jink"
                || (pattern.contains("peach") && player->getMark("Global_PreventPeach") == 0)
                || pattern == "analeptic";
    }

    bool viewFilter(const Card *to_select) const
    {
        const Card *card = to_select;

        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (Slash::IsAvailable(Self) && Analeptic::IsAvailable(Self) && Self->isWounded())
                return card->isKindOf("Jink") || card->isKindOf("Peach") || card->isKindOf("Analeptic");
            if (Slash::IsAvailable(Self) && Analeptic::IsAvailable(Self))
                return card->isKindOf("Jink") || card->isKindOf("Peach");
            if (Slash::IsAvailable(Self) && Self->isWounded())
                return card->isKindOf("Jink") || card->isKindOf("Analeptic");
            if (Analeptic::IsAvailable(Self) && Self->isWounded())
                return card->isKindOf("Peach") || card->isKindOf("Analeptic");
            if (Analeptic::IsAvailable(Self))
                return card->isKindOf("Peach");
            if (Slash::IsAvailable(Self))
                return card->isKindOf("Jink");
            if (Self->isWounded())
                return card->isKindOf("Analeptic");
        } else {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern == "slash")
                return card->isKindOf("Jink");
            else if (pattern == "peach+analeptic") {
                if (Self->getMark("Global_PreventPeach") > 0)
                    return card->isKindOf("Peach");
                return card->isKindOf("Peach") || card->isKindOf("Analeptic");
            } else if (pattern == "peach") {
                if (Self->getMark("Global_PreventPeach") == 0)
                    return card->isKindOf("Analeptic");
            } else if(pattern == "analeptic")
                return card->isKindOf("Peach");
            else if (pattern == "jink")
                return card->isKindOf("Slash");
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (originalCard->isKindOf("Slash")) {
            Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
            jink->addSubcard(originalCard);
            jink->setSkillName(objectName());
            return jink;
        } else if (originalCard->isKindOf("Jink")) {
            Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
            slash->addSubcard(originalCard);
            slash->setSkillName(objectName());
            return slash;
        } else if (originalCard->isKindOf("Peach")) {
            Analeptic *ana = new Analeptic(originalCard->getSuit(), originalCard->getNumber());
            ana->addSubcard(originalCard);
            ana->setSkillName(objectName());
            return ana;
        } else if (originalCard->isKindOf("Analeptic")) {
            Peach *peach = new Peach(originalCard->getSuit(), originalCard->getNumber());
            peach->addSubcard(originalCard);
            peach->setSkillName(objectName());
            return peach;
        } else
            return NULL;
    }
};

class OLYajiao : public TriggerSkill
{
public:
    OLYajiao() : TriggerSkill("olyajiao")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive) return false;
        const Card *cardstar = NULL;
        bool isHandcard = false;
        if (triggerEvent == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            cardstar = use.card;
            isHandcard = use.m_isHandcard;
        } else {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            cardstar = resp.m_card;
            isHandcard = resp.m_isHandcard;
        }
        if (isHandcard && room->askForSkillInvoke(player, objectName(), data)) {
            room->broadcastSkillInvoke(objectName());
            QList<int> ids = room->getNCards(1, false);
            CardsMoveStruct move(ids, NULL, Player::PlaceTable,
                CardMoveReason(CardMoveReason::S_REASON_TURNOVER, player->objectName(), "olyajiao", QString()));
            room->moveCardsAtomic(move, true);
            int id = ids.first();
            if (room->getCardPlace(id) == Player::PlaceTable)
                room->returnToTopDrawPile(ids);

            const Card *card = Sanguosha->getCard(id);
            player->setMark("olyajiao", id); // For AI
            if (card->getTypeId() == cardstar->getTypeId()) {
                room->fillAG(ids, player);
                ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "olyajiao-give", true, true);
                room->clearAG(player);
                if (!target) return false;
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "olyajiao", QString());
                room->obtainCard(target, card, reason, true);
            } else {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->inMyAttackRange(player) && player->canDiscard(p, "hej"))
                        targets << p;
                }
                if (targets.isEmpty()) return false;
                ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "olyajiao-discard", true, true);
                if (!target) return false;
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                int card_id = room->askForCardChosen(player, target, "hej", objectName(), false, Card::MethodDiscard);
                room->throwCard(Sanguosha->getCard(card_id), room->getCardPlace(card_id) == Player::PlaceDelayedTrick ? NULL : target, player);
            }
        }
        return false;
    }
};

class OLLeiji : public TriggerSkill
{
public:
    OLLeiji() : TriggerSkill("olleiji")
    {
        events << CardResponded << CardUsed << FinishJudge;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == "baonue") return false;
            if (judge->card->getSuit() != Card::Club && judge->card->getSuit() != Card::Spade) return false;
            int n = 2;
            if (judge->card->getSuit() == Card::Club) {
                n = 1;
                if (player->getLostHp() > 0)
                    room->recover(player, RecoverStruct(player));
            }
            if (player->isDead()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "olleiji-invoke:" + QString::number(n),
                                        false, true);
            room->damage(DamageStruct(objectName(), player, target, n, DamageStruct::Thunder));
        } else {
            const Card *card = NULL;
            if (event == CardUsed)
                card = data.value<CardUseStruct>().card;
            else
                card = data.value<CardResponseStruct>().m_card;
            if (card && (card->isKindOf("Jink") || card->isKindOf("Lightning"))) {
                if (!player->askForSkillInvoke(this)) return false;
                room->broadcastSkillInvoke(objectName());
                JudgeStruct judge;
                judge.pattern = ".|black";
                judge.good = false;
                judge.negative = true;
                judge.reason = objectName();
                judge.who = player;

                room->judge(judge);
            }
        }
        return false;
    }
};

class OLGuidao : public TriggerSkill
{
public:
    OLGuidao() : TriggerSkill("olguidao")
    {
        events << AskForRetrial;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        if (!TriggerSkill::triggerable(target))
            return false;

        if (target->isKongcheng()) {
            bool has_black = false;
            for (int i = 0; i < 5; i++) {
                const EquipCard *equip = target->getEquip(i);
                if (equip && equip->isBlack()) {
                    has_black = true;
                    break;
                }
            }
            return has_black;
        } else
            return true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        QStringList prompt_list;
        prompt_list << "@olguidao-card" << judge->who->objectName()
            << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");

        const Card *card = room->askForCard(player, ".|black", prompt, QVariant::fromValue(judge), Card::MethodResponse, judge->who, true, objectName());
        if (!card) return false;
        room->broadcastSkillInvoke(objectName());
        room->retrial(card, player, judge, objectName(), true);
        if (card->getSuit() == Card::Spade && card->getNumber() >= 2 && card->getNumber() <= 9)
            player->drawCards(1, objectName());
        return false;
    }
};

OLGuhuoCard::OLGuhuoCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool OLGuhuoCard::olguhuo(ServerPlayer *yuji) const
{
    Room *room = yuji->getRoom();
    QList<int> used_cards;
    QList<CardsMoveStruct> moves;
    foreach(int card_id, getSubcards())
        used_cards << card_id;
    room->setTag("OLGuhuoType", user_string);

    QList<ServerPlayer *> questioned;
    foreach (ServerPlayer *player, room->getOtherPlayers(yuji)) {
        if (player->hasSkill("chanyuan")) {
            LogMessage log;
            log.type = "#Chanyuan";
            log.from = player;
            log.arg = "chanyuan";
            room->sendLog(log);

            room->notifySkillInvoked(player, "chanyuan");
            room->broadcastSkillInvoke("chanyuan");
            room->setEmotion(player, "no-question");
            continue;
        }

        QString choice = room->askForChoice(player, "olguhuo", "noquestion+question");
        if (choice == "question")
            room->setEmotion(player, "question");
        else
            room->setEmotion(player, "no-question");

        LogMessage log;
        log.type = "#GuhuoQuery";
        log.from = player;
        log.arg = choice;
        room->sendLog(log);
        if (choice == "question")
            questioned << player;
    }

    LogMessage log;
    log.type = "$GuhuoResult";
    log.from = yuji;
    log.card_str = QString::number(subcards.first());
    room->sendLog(log);

    bool success = false;
    if (questioned.isEmpty()) {
        success = true;
        foreach(ServerPlayer *player, room->getOtherPlayers(yuji))
            room->setEmotion(player, ".");
        CardMoveReason reason(CardMoveReason::S_REASON_USE, yuji->objectName(), QString(), "olguhuo");
        CardsMoveStruct move(used_cards, yuji, NULL, Player::PlaceUnknown, Player::PlaceTable, reason);
        moves.append(move);
        room->moveCardsAtomic(moves, true);
    } else {
        const Card *card = Sanguosha->getCard(subcards.first());
        if (user_string == "peach+analeptic")
            success = card->objectName() == yuji->tag["OLGuhuoSaveSelf"].toString();
        else if (user_string == "slash")
            success = card->objectName().contains("slash");
        else if (user_string == "normal_slash")
            success = card->objectName() == "slash";
        else
            success = card->match(user_string);
        if (success) {
            CardMoveReason reason(CardMoveReason::S_REASON_USE, yuji->objectName(), QString(), "olguhuo");
            CardsMoveStruct move(used_cards, yuji, NULL, Player::PlaceUnknown, Player::PlaceTable, reason);
            moves.append(move);
            room->moveCardsAtomic(moves, true);
        } else {
            room->moveCardTo(this, yuji, NULL, Player::DiscardPile,
                CardMoveReason(CardMoveReason::S_REASON_PUT, yuji->objectName(), QString(), "olguhuo"), true);
        }
        foreach (ServerPlayer *player, room->getOtherPlayers(yuji)) {
            room->setEmotion(player, ".");
            if (success && questioned.contains(player)) {
                if (!player->canDiscard(player, "he"))
                    room->loseHp(player);
                else {
                    if (!room->askForDiscard(player, "olguhuo", 1, 1, true, true, "olguhuo-discard"))
                        room->loseHp(player);
                }
                if (player->isAlive())
                    room->acquireSkill(player, "chanyuan");
            } else if (!success && questioned.contains(player)) {
                player->drawCards(1, "olguhuo");
            }
        }
    }
    yuji->tag.remove("OLGuhuoSaveSelf");
    yuji->tag.remove("OLGuhuoSlash");
    room->addPlayerMark(yuji, "olguhuo-Clear");
    return success;
}

bool OLGuhuoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    const Card *_card = Self->tag.value("olguhuo").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool OLGuhuoCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *_card = Self->tag.value("olguhuo").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFixed();
}

bool OLGuhuoCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *_card = Self->tag.value("olguhuo").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetsFeasible(targets, Self);
}

const Card *OLGuhuoCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *yuji = card_use.from;
    Room *room = yuji->getRoom();

    QString to_guhuo = user_string;
    if (user_string == "slash"
        && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList guhuo_list;
        guhuo_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "normal_slash" << "thunder_slash" << "fire_slash";
        to_guhuo = room->askForChoice(yuji, "olguhuo_slash", guhuo_list.join("+"));
        yuji->tag["OLGuhuoSlash"] = QVariant(to_guhuo);
    }
    room->broadcastSkillInvoke("olguhuo");

    LogMessage log;
    log.type = card_use.to.isEmpty() ? "#GuhuoNoTarget" : "#Guhuo";
    log.from = yuji;
    log.to = card_use.to;
    log.arg = to_guhuo;
    log.arg2 = "olguhuo";

    room->sendLog(log);

    if (olguhuo(card_use.from)) {
        const Card *card = Sanguosha->getCard(subcards.first());
        QString user_str;
        if (to_guhuo == "slash") {
            if (card->isKindOf("Slash"))
                user_str = card->objectName();
            else
                user_str = "slash";
        } else if (to_guhuo == "normal_slash")
            user_str = "slash";
        else
            user_str = to_guhuo;
        Card *use_card = Sanguosha->cloneCard(user_str, card->getSuit(), card->getNumber());
        use_card->setSkillName("olguhuo");
        use_card->addSubcard(subcards.first());
        use_card->deleteLater();

        QList<ServerPlayer *> tos = card_use.to;
        foreach (ServerPlayer *to, tos) {
            const ProhibitSkill *skill = room->isProhibited(card_use.from, to, use_card);
            if (skill) {
                if (skill->isVisible()) {
                    LogMessage log;
                    log.type = "#SkillAvoid";
                    log.from = to;
                    log.arg = skill->objectName();
                    log.arg2 = use_card->objectName();
                    room->sendLog(log);

                    room->notifySkillInvoked(to, skill->objectName());
                    room->broadcastSkillInvoke(skill->objectName());
                } else {
                    const Skill *new_skill = Sanguosha->getMainSkill(skill->objectName());
                    if (new_skill && new_skill->isVisible()) {
                        if (to->hasSkill(new_skill)) {
                            QString skill_name = new_skill->objectName();
                            LogMessage log;
                            log.type = "#SkillAvoid";
                            log.from = to;
                            log.arg = skill_name;
                            log.arg2 = objectName();
                            room->sendLog(log);

                            room->notifySkillInvoked(to, skill_name);
                            room->broadcastSkillInvoke(skill_name);
                        } else if (yuji->hasSkill(new_skill)) {
                            QString skill_name = new_skill->objectName();
                            LogMessage log;
                            log.type = "#SkillAvoidFrom";
                            log.from = yuji;
                            log.to << to;
                            log.arg = skill_name;
                            log.arg2 = objectName();
                            room->sendLog(log);

                            room->notifySkillInvoked(yuji, skill_name);
                            room->broadcastSkillInvoke(skill_name);
                        }
                    }
                }
                card_use.to.removeOne(to);
            }
        }
        return use_card;
    } else
        return NULL;
}

const Card *OLGuhuoCard::validateInResponse(ServerPlayer *yuji) const
{
    Room *room = yuji->getRoom();
    room->broadcastSkillInvoke("olguhuo");

    QString to_guhuo;
    if (user_string == "peach+analeptic") {
        QStringList guhuo_list;
        guhuo_list << "peach";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "analeptic";
        to_guhuo = room->askForChoice(yuji, "olguhuo_saveself", guhuo_list.join("+"));
        yuji->tag["OLGuhuoSaveSelf"] = QVariant(to_guhuo);
    } else if (user_string == "slash") {
        QStringList guhuo_list;
        guhuo_list << "slash";
        if (!Config.BanPackages.contains("maneuvering"))
            guhuo_list << "normal_slash" << "thunder_slash" << "fire_slash";
        to_guhuo = room->askForChoice(yuji, "olguhuo_slash", guhuo_list.join("+"));
        yuji->tag["OLGuhuoSlash"] = QVariant(to_guhuo);
    } else
        to_guhuo = user_string;

    LogMessage log;
    log.type = "#GuhuoNoTarget";
    log.from = yuji;
    log.arg = to_guhuo;
    log.arg2 = "olguhuo";
    room->sendLog(log);

    if (olguhuo(yuji)) {
        const Card *card = Sanguosha->getCard(subcards.first());
        QString user_str;
        if (to_guhuo == "slash") {
            if (card->isKindOf("Slash"))
                user_str = card->objectName();
            else
                user_str = "slash";
        } else if (to_guhuo == "normal_slash")
            user_str = "slash";
        else
            user_str = to_guhuo;
        Card *use_card = Sanguosha->cloneCard(user_str, card->getSuit(), card->getNumber());
        use_card->setSkillName("olguhuo");
        use_card->addSubcard(subcards.first());
        use_card->deleteLater();
        return use_card;
    } else
        return NULL;
}

class OLGuhuo : public OneCardViewAsSkill
{
public:
    OLGuhuo() : OneCardViewAsSkill("olguhuo")
    {
        filter_pattern = ".|.|.|hand";
        response_or_use = true;
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

        if (player->isKongcheng() || player->getMark("olguhuo-Clear") > 0
            || pattern.startsWith(".") || pattern.startsWith("@"))
            return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;
        for (int i = 0; i < pattern.length(); i++) {
            QChar ch = pattern[i];
            if (ch.isUpper() || ch.isDigit()) return false; // This is an extremely dirty hack!! For we need to prevent patterns like 'BasicCard'
        }
        return true;
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
        return !player->isKongcheng() && player->getMark("olguhuo-Clear") <= 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE
            || Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            OLGuhuoCard *card = new OLGuhuoCard;
            card->setUserString(Sanguosha->currentRoomState()->getCurrentCardUsePattern());
            card->addSubcard(originalCard);
            return card;
        }

        const Card *c = Self->tag.value("olguhuo").value<const Card *>();
        if (c) {
            OLGuhuoCard *card = new OLGuhuoCard;
            if (!c->objectName().contains("slash"))
                card->setUserString(c->objectName());
            else
                card->setUserString(Self->tag["OLGuhuoSlash"].toString());
            card->addSubcard(originalCard);
            return card;
        } else
            return NULL;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("olguhuo");
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        ServerPlayer *current = player->getRoom()->getCurrent();
        if (!current || current->isDead() || current->getPhase() == Player::NotActive) return false;
        return (!player->isKongcheng() || !player->getHandPile().isEmpty()) && player->getMark("olguhuo-Clear") <= 0;
    }
};

class OLShebian : public TriggerSkill
{
public:
    OLShebian() : TriggerSkill("olshebian")
    {
        events << TurnedOver;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->canMoveField("e")) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        room->moveField(player, objectName(), false, "e");
        return false;
    }
};

OLQimouCard::OLQimouCard()
{
    target_fixed = true;
}

void OLQimouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->removePlayerMark(source, "@olqimouMark");
    room->doSuperLightbox("ol_weiyan", "olqimou");
    QStringList choices;
    for (int i = 1; i <= source->getHp(); i++) {
        choices << QString::number(i);
    }
    QString choice = room->askForChoice(source, "olqimou", choices.join("+"));
    int n = choice.toInt();
    room->loseHp(source, n);
    if (source->isAlive()) {
        source->drawCards(n, "olqimou");
        room->addDistance(source, -n);
        room->addSlashCishu(source, n);
    }
}

class OLQimou : public ZeroCardViewAsSkill
{
public:
    OLQimou() : ZeroCardViewAsSkill("olqimou")
    {
        frequency = Limited;
        limit_mark = "@olqimouMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getHp() > 0 && player->getMark("@olqimouMark") > 0;
    }

    const Card *viewAs() const
    {
        return new OLQimouCard;
    }
};

class OLHongyan : public FilterSkill
{
public:
    OLHongyan() : FilterSkill("olhongyan")
    {
    }

    static WrappedCard *changeToHeart(int cardId)
    {
        WrappedCard *new_card = Sanguosha->getWrappedCard(cardId);
        new_card->setSkillName("olhongyan");
        new_card->setSuit(Card::Heart);
        new_card->setModified(true);
        return new_card;
    }

    bool viewFilter(const Card *to_select) const
    {
        return to_select->getSuit() == Card::Spade;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        return changeToHeart(originalCard->getEffectiveId());
    }
};

class OLHongyanKeep : public MaxCardsSkill
{
public:
    OLHongyanKeep() : MaxCardsSkill("#olhongyan-keep")
    {
    }

    int getFixed(const Player *target) const
    {
        if (target->hasSkill("olhongyan")) {
            foreach (const Card *c, target->getEquips()) {
                if (c->getSuit() == Card::Heart)
                    return target->getMaxHp();
            }
            return -1;
        } else
            return -1;
    }
};

class OLPiaoling : public TriggerSkill
{
public:
    OLPiaoling() : TriggerSkill("olpiaoling")
    {
        events << EventPhaseChanging;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        JudgeStruct judge;
        judge.pattern = ".|heart";
        judge.who = player;
        judge.reason = objectName();
        room->judge(judge);

        if (judge.isBad() || player->isDead()) return false;
        if (!room->CardInPlace(judge.card, Player::DiscardPile)) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(),
            "olpiaoling-invoke:" + judge.card->objectName(), true);
        if (!target) {
            LogMessage log;
            log.type = "$PutCard2";
            log.from = player;
            log.card_str = judge.card->toString();
            room->sendLog(log);
            CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), "olpiaoling", QString());
            CardsMoveStruct move(judge.card->getEffectiveId(), NULL, NULL, Player::PlaceJudge, Player::DrawPile, reason);
            room->moveCardsAtomic(move, true);
        } else {
            room->doAnimate(1, player->objectName(), target->objectName());
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "olpiaoling", QString());
            room->obtainCard(target, judge.card, reason, true);
            if (player->isDead() || target != player || !player->canDiscard(player, "he")) return false;
            room->askForDiscard(player, objectName(), 1, 1, false, true);
        }
        return false;
    }
};

class OLLuanjiVS : public ViewAsSkill
{
public:
    OLLuanjiVS() : ViewAsSkill("olluanji")
    {
        response_or_use = true;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.isEmpty())
            return !to_select->isEquipped();
        else if (selected.length() == 1) {
            const Card *card = selected.first();
            return !to_select->isEquipped() && to_select->getSuit() == card->getSuit();
        } else
            return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() == 2) {
            ArcheryAttack *aa = new ArcheryAttack(Card::SuitToBeDecided, 0);
            aa->addSubcards(cards);
            aa->setSkillName(objectName());
            return aa;
        } else
            return NULL;
    }
};

class OLLuanji : public TriggerSkill
{
public:
    OLLuanji() : TriggerSkill("olluanji")
    {
        events << CardUsed;
        view_as_skill = new OLLuanjiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("ArcheryAttack") || use.to.length() < 2) return false;
        ServerPlayer *remove = room->askForPlayerChosen(player, use.to, objectName(), "olluanji-remove", true);
        if (!remove) return false;
        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(player, objectName());
        LogMessage log;
        log.type = "#QiaoshuiRemove";
        log.from = player;
        log.to << remove;
        log.card_str = use.card->toString();
        log.arg = "olluanji";
        room->sendLog(log);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), remove->objectName());
        use.to.removeOne(remove);
        data = QVariant::fromValue(use);
        return false;
    }
};

class OLXueyi : public TriggerSkill
{
public:
    OLXueyi() : TriggerSkill("olxueyi$")
    {
        events << GameStart << EventPhaseStart;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!player->hasLordSkill(this)) return false;
        if (event == GameStart) {
            int qun = 0;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getKingdom() == "qun")
                    qun++;
            }
            if (qun == 0) return false;
            QString name;
            if (player->hasSkill(this))
                name = objectName();
            else if (player->hasSkill("weidi"))
                name = "weidi";
            room->sendCompulsoryTriggerLog(player, name, true, true);
            player->gainMark("&olyi", qun);
        } else {
            if (player->getPhase() != Player::RoundStart) return false;
            if (player->getMark("&olyi") <= 0 || !player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            player->loseMark("&olyi");
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class OLXueyiKeep : public MaxCardsSkill
{
public:
    OLXueyiKeep() : MaxCardsSkill("#olxueyikeep$")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->hasLordSkill("olxueyi"))
            return 2 * target->getMark("&olyi");
        else
            return 0;
    }
};

class OLHuoji : public OneCardViewAsSkill
{
public:
    OLHuoji() : OneCardViewAsSkill("olhuoji")
    {
        filter_pattern = ".|red";
        response_or_use = true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        FireAttack *fire_attack = new FireAttack(originalCard->getSuit(), originalCard->getNumber());
        fire_attack->addSubcard(originalCard->getId());
        fire_attack->setSkillName(objectName());
        return fire_attack;
    }
};

class OLKanpo : public OneCardViewAsSkill
{
public:
    OLKanpo() : OneCardViewAsSkill("olkanpo")
    {
        filter_pattern = ".|black";
        response_pattern = "nullification";
        response_or_use = true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Card *ncard = new Nullification(originalCard->getSuit(), originalCard->getNumber());
        ncard->addSubcard(originalCard);
        ncard->setSkillName(objectName());
        return ncard;
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        bool black = false;
        if (player->isKongcheng()) {
            foreach (const Card *c, player->getCards("e")) {
                if (c->isBlack()) {
                    black = true;
                    break;
                }
            }
        } else
            black = true;
        return black || !player->getHandPile().isEmpty();
    }
};

class OLCangzhuo : public TriggerSkill
{
public:
    OLCangzhuo() : TriggerSkill("olcangzhuo")
    {
        events << EventPhaseProceeding;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Discard) return false;
        if (player->getMark("olcangzhuo_usedtrick-Clear") > 0) return false;
        QList<int> tricks;
        foreach (const Card *c, player->getCards("h")) {
            if (c->isKindOf("TrickCard"))
                tricks << c->getEffectiveId();
        }
        if (tricks.isEmpty()) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        room->ignoreCards(player, tricks);
        return false;
    }
};

class OLCangzhuoRecord : public TriggerSkill
{
public:
    OLCangzhuoRecord() : TriggerSkill("#olcangzhuo-record")
    {
        events << PreCardUsed;
        frequency = Compulsory;
        global = true;
    }
    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("TrickCard")) return false;
        room->addPlayerMark(player, "olcangzhuo_usedtrick-Clear");
        return false;
    }
};

class OLLianhuan : public OneCardViewAsSkill
{
public:
    OLLianhuan() : OneCardViewAsSkill("ollianhuan")
    {
        filter_pattern = ".|club";
        response_or_use = true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        IronChain *chain = new IronChain(originalCard->getSuit(), originalCard->getNumber());
        chain->addSubcard(originalCard);
        chain->setSkillName(objectName());
        return chain;
    }
};

class OLLianhuanMod : public TargetModSkill
{
public:
    OLLianhuanMod() : TargetModSkill("#ollianhuanmod")
    {
        frequency = NotFrequent;
        pattern = "IronChain";
    }

    int getExtraTargetNum(const Player *from, const Card *) const
    {
        if (from->hasSkill("ollianhuan"))
            return 1;
        else
            return 0;
    }
};

class OLNiepan : public TriggerSkill
{
public:
    OLNiepan() : TriggerSkill("olniepan")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@olniepanMark";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getMark("@olniepanMark") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *pangtong, QVariant &data) const
    {
        DyingStruct dying_data = data.value<DyingStruct>();
        if (dying_data.who != pangtong)
            return false;

        if (pangtong->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("ol_pangtong", "olniepan");

            room->removePlayerMark(pangtong, "@olniepanMark");

            pangtong->throwAllHandCardsAndEquips();
            /*QList<const Card *> tricks = pangtong->getJudgingArea();
            foreach (const Card *trick, tricks) {
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, pangtong->objectName());
                room->throwCard(trick, reason, NULL);
            }*/

            if (pangtong->isChained())
                room->setPlayerChained(pangtong);

            if (!pangtong->faceUp())
                pangtong->turnOver();

            pangtong->drawCards(3, objectName());

            if (pangtong->getLostHp() > 0) {
                int n = qMin(3 - pangtong->getHp(), pangtong->getMaxHp() - pangtong->getHp());
                room->recover(pangtong, RecoverStruct(pangtong, NULL, n));
            }

            QStringList skills;
            if (!pangtong->hasSkill("bazhen"))
                skills << "bazhen";
            if (!pangtong->hasSkill("olhuoji"))
                skills << "olhuoji";
            if (!pangtong->hasSkill("olkanpo"))
                skills << "olkanpo";
            if (skills.isEmpty()) return false;
            QString skill = room->askForChoice(pangtong, objectName(), skills.join("+"));
            room->handleAcquireDetachSkills(pangtong, skill);
        }
        return false;
    }
};

class OLJianchu : public TriggerSkill
{
public:
    OLJianchu() : TriggerSkill("oljianchu")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead() || !player->hasSkill(this)) break;
            if (p->isDead()) continue;
            if (!player->canDiscard(p, "he") || !player->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
            room->broadcastSkillInvoke(objectName());
            int to_throw = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard);
            const Card *card = Sanguosha->getCard(to_throw);
            room->throwCard(card, p, player);
            if (!card->isKindOf("BasicCard")) {
                LogMessage log;
                log.type = "#NoJink";
                log.from = p;
                room->sendLog(log);
                use.no_respond_list << p->objectName();
                data = QVariant::fromValue(use);
                room->addSlashCishu(player, 1);
            } else {
                if (!room->CardInTable(use.card)) continue;
                p->obtainCard(use.card, true);
            }
        }
        return false;
    }
};

class OLHanzhan : public TriggerSkill
{
public:
    OLHanzhan() : TriggerSkill("olhanzhan")
    {
        events << AskforPindianCard;
    }

    int getPriority(TriggerEvent) const
    {
        return 3;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QStringList pindian = data.toStringList();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (pindian.at(0) != p->objectName() && pindian.at(1) != p->objectName()) continue;
            if (!p->hasSkill(this)) continue;
            if (pindian.at(0) == p->objectName()) {
                if (pindian.at(3).toInt() && pindian.at(3).toInt() > 0) continue;
                ServerPlayer *anotherone = room->findPlayerByObjectName(pindian.at(1));
                if (!anotherone || anotherone->isDead() || anotherone->isKongcheng()) continue;
                if (!p->askForSkillInvoke(this, QVariant::fromValue(anotherone))) continue;
                room->broadcastSkillInvoke(objectName());
                QStringList newpindian;
                newpindian << pindian.at(0);
                newpindian << pindian.at(1);
                newpindian << pindian.at(2);
                newpindian << QString::number(anotherone->getRandomHandCardId());
                data = QVariant::fromValue(newpindian);
                break;
            }
            if (pindian.at(1) == p->objectName()) {
                if (pindian.at(2).toInt() && pindian.at(2).toInt() > 0) continue;
                ServerPlayer *anotherone = room->findPlayerByObjectName(pindian.at(0));
                if (!anotherone || anotherone->isDead() || anotherone->isKongcheng()) continue;
                if (!p->askForSkillInvoke(this, QVariant::fromValue(anotherone))) continue;
                room->broadcastSkillInvoke(objectName());
                QStringList newpindian;
                newpindian << pindian.at(0);
                newpindian << pindian.at(1);
                newpindian << QString::number(anotherone->getRandomHandCardId());
                newpindian << pindian.at(2);
                data = QVariant::fromValue(newpindian);
                break;
            }
        }
        return false;
    }
};

OLWulieCard::OLWulieCard()
{
    mute = true;
}

bool OLWulieCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.length() < Self->getHp() && to_select != Self;
}

void OLWulieCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->removePlayerMark(source, "@olwulieMark");
    room->broadcastSkillInvoke("olwulie");
    room->doSuperLightbox("ol_sunjian", "olwulie");
    if (targets.isEmpty()) return;
    room->loseHp(source, targets.length());
    foreach (ServerPlayer *p, targets) {
        if (p->isAlive())
            room->cardEffect(this, source, p);
    }
}

void OLWulieCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->gainMark("&ollie");
}

class OLWulieVS : public ZeroCardViewAsSkill
{
public:
    OLWulieVS() : ZeroCardViewAsSkill("olwulie")
    {
        response_pattern = "@@olwulie";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new OLWulieCard;
    }
};

class OLWulie : public TriggerSkill
{
public:
    OLWulie() : TriggerSkill("olwulie")
    {
        events << EventPhaseStart << DamageInflicted;
        frequency = Limited;
        limit_mark = "@olwulieMark";
        view_as_skill = new OLWulieVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish || !player->hasSkill(this)) return false;
            if (player->getMark("@olwulieMark") <= 0) return false;
            if (player->getHp() <= 0) return false;
            room->askForUseCard(player, "@@olwulie", "@olwulie");
        } else {
            if (player->getMark("&ollie") <= 0) return false;
            DamageStruct damage = data.value<DamageStruct>();
            LogMessage log;
            log.type = "#OlwuliePrevent";
            log.from = player;
            log.arg = objectName();
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);
            player->loseMark("&ollie");
            return true;
        }
        return false;
    }
};

OLFangquanCard::OLFangquanCard()
{
}

void OLFangquanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    ServerPlayer *liushan = effect.from, *player = effect.to;

    LogMessage log;
    log.type = "#Fangquan";
    log.from = liushan;
    log.to << player;
    room->sendLog(log);

    room->setTag("OLFangquanTarget", QVariant::fromValue(player));
}

class OLFangquanViewAsSkill : public OneCardViewAsSkill
{
public:
    OLFangquanViewAsSkill() : OneCardViewAsSkill("olfangquan")
    {
        filter_pattern = ".|.|.|hand";
        response_pattern = "@@olfangquan";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        OLFangquanCard *fangquan = new OLFangquanCard;
        fangquan->addSubcard(originalCard);
        return fangquan;
    }
};

class OLFangquan : public TriggerSkill
{
public:
    OLFangquan() : TriggerSkill("olfangquan")
    {
        events << EventPhaseChanging << EventPhaseStart;
        view_as_skill = new OLFangquanViewAsSkill;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseStart)
            return 1;
        else
            return TriggerSkill::getPriority(triggerEvent);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *liushan, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::Play) return false;
            if (!TriggerSkill::triggerable(liushan) || liushan->isSkipped(Player::Play)) return false;
            if (!liushan->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            liushan->setFlags(objectName());
            liushan->skip(Player::Play, true);
        } else if (triggerEvent == EventPhaseStart) {
            if (liushan->getPhase() == Player::Discard) {
                if (liushan->hasFlag(objectName())) {
                    room->setPlayerFlag(liushan, "-olfangquan");
                    if (!liushan->canDiscard(liushan, "h"))
                        return false;
                    room->askForUseCard(liushan, "@@olfangquan", "@olfangquan-give", -1, Card::MethodDiscard);
                }
            } else if (liushan->getPhase() == Player::NotActive) {
                if (!room->getTag("OLFangquanTarget").isNull()) {
                    ServerPlayer *target = room->getTag("OLFangquanTarget").value<ServerPlayer *>();
                    room->removeTag("OLFangquanTarget");
                    if (target->isAlive())
                        target->gainAnExtraTurn();
                }
            }
        }
        return false;
    }
};

class OLRuoyu : public PhaseChangeSkill
{
public:
    OLRuoyu() : PhaseChangeSkill("olruoyu$")
    {
        frequency = Wake;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Start
            && target->hasLordSkill("olruoyu")
            && target->isAlive()
            && target->getMark("olruoyu") == 0;
    }

    bool onPhaseChange(ServerPlayer *liushan) const
    {
        Room *room = liushan->getRoom();
        if (!liushan->isLowestHpPlayer()) return false;
        room->notifySkillInvoked(liushan, objectName());
        LogMessage log;
        log.type = "#RuoyuWake";
        log.from = liushan;
        log.arg = QString::number(liushan->getHp());
        log.arg2 = objectName();
        room->sendLog(log);
        if (liushan->isWeidi()) {
            room->broadcastSkillInvoke("weidi");
            QString generalName = "yuanshu";
            if (liushan->getGeneralName() == "tw_yuanshu" || (liushan->getGeneral2() != NULL && liushan->getGeneral2Name() == "tw_yuanshu"))
                generalName = "tw_yuanshu";
            room->doSuperLightbox(generalName, "ruoyu");
        } else {
            room->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("ol_liushan", "ruoyu");
        }
        room->setPlayerMark(liushan, "olruoyu", 1);
        if (room->changeMaxHpForAwakenSkill(liushan, 1)) {
            room->recover(liushan, RecoverStruct(liushan));
            QStringList skills;
            if (liushan->getMark("ruoyu") == 1 && liushan->isLord() && !liushan->hasSkill("jijiang"))
                skills << "jijiang";
            if (!liushan->hasSkill("olsishu"))
                skills << "olsishu";
            if (skills.isEmpty()) return false;
            room->handleAcquireDetachSkills(liushan, skills.join("|"));
        }
        return false;
    }
};

class OLSishu : public TriggerSkill
{
public:
    OLSishu() : TriggerSkill("olsishu")
    {
        events << StartJudge << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == StartJudge) {
            if (player->getMark("&olsishu") <= 0) return false;
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason != "indulgence") return false;
            LogMessage log;
            log.type = "#OLsishuEffect";
            log.from = player;
            log.arg = "olsishu";
            room->sendLog(log);
            judge->good = false;
        } else {
            if (!player->hasSkill(this) || player->getPhase() != Player::Play) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "olsishu-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->setPlayerMark(target, "&olsishu", 1);
        }
        return false;
    }
};

OLZhibaCard::OLZhibaCard()
{
    mute = true;
}

bool OLZhibaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getKingdom() == "wu" && Self->canPindian(to_select) && Self != to_select;
}

void OLZhibaCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to)) return;
    Room *room = effect.from->getRoom();
    if (effect.from->isWeidi())
        room->broadcastSkillInvoke("weidi");
    else
        room->broadcastSkillInvoke("olzhiba");
    PindianStruct *pindian = effect.from->PinDian(effect.to, "olzhiba", NULL);
    if (!pindian) return;
    if (pindian->from_number < pindian->to_number) return;
    if (pindian->from && !pindian->from->isDead() && pindian->from->hasLordSkill("olzhiba")) {
        DummyCard *dummy = new DummyCard();
        int from_card_id = pindian->from_card->getEffectiveId();
        int to_card_id = pindian->to_card->getEffectiveId();
        if (room->getCardPlace(from_card_id) == Player::DiscardPile)
            dummy->addSubcard(from_card_id);
        if (room->getCardPlace(to_card_id) == Player::DiscardPile && from_card_id != to_card_id)
            dummy->addSubcard(to_card_id);
        if (!dummy->getSubcards().isEmpty() && room->askForChoice(pindian->from, "olzhiba_pindian_obtain", "obtainPindianCards+reject") == "obtainPindianCards")
            pindian->from->obtainCard(dummy);
        delete dummy;
    }
}

class OLZhibaVS : public ZeroCardViewAsSkill
{
public:
    OLZhibaVS() : ZeroCardViewAsSkill("olzhiba$")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return hasTarget(player) && !player->hasUsed("OLZhibaCard") && player->canPindian();
    }

    bool hasTarget(const Player *player) const
    {
        QList<const Player *> as = player->getAliveSiblings();
        foreach (const Player *p, as) {
            if (p->getKingdom() == "wu")
                return true;
        }
        return false;
    }

    const Card *viewAs() const
    {
        return new OLZhibaCard;
    }
};

class OLZhiba : public TriggerSkill
{
public:
    OLZhiba() : TriggerSkill("olzhiba$")
    {
        events << GameStart << EventAcquireSkill << EventLoseSkill;
        view_as_skill = new OLZhibaVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if ((triggerEvent == GameStart && player->isLord())
            || (triggerEvent == EventAcquireSkill && data.toString() == "olzhiba")) {
            QList<ServerPlayer *> lords;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->hasLordSkill(this))
                    lords << p;
            }
            if (lords.isEmpty()) return false;

            QList<ServerPlayer *> players;
            if (lords.length() > 1)
                players = room->getAlivePlayers();
            else
                players = room->getOtherPlayers(lords.first());
            foreach (ServerPlayer *p, players) {
                if (!p->hasSkill("olzhiba_pindian"))
                    room->attachSkillToPlayer(p, "olzhiba_pindian");
            }
        } else if (triggerEvent == EventLoseSkill && data.toString() == "olzhiba") {
            QList<ServerPlayer *> lords;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->hasLordSkill(this))
                    lords << p;
            }
            if (lords.length() > 2) return false;

            QList<ServerPlayer *> players;
            if (lords.isEmpty())
                players = room->getAlivePlayers();
            else
                players << lords.first();
            foreach (ServerPlayer *p, players) {
                if (p->hasSkill("olzhiba_pindian"))
                    room->detachSkillFromPlayer(p, "olzhiba_pindian", true);
            }
        }
        return false;
    }
};

OLZhibaPindianCard::OLZhibaPindianCard()
{
    m_skillName = "olzhiba_pindian";
    mute = true;
}

bool OLZhibaPindianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select) && Self != to_select && to_select->hasLordSkill("olzhiba") &&
            to_select->getMark("olzhiba-PlayClear") <= 0;
}

void OLZhibaPindianCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.to, "olzhiba-PlayClear");
    if (!effect.from->canPindian(effect.to)) return;
    if (effect.to->isWeidi()) {
        room->broadcastSkillInvoke("weidi");
        room->notifySkillInvoked(effect.to, "weidi");
    }
    else {
        room->broadcastSkillInvoke("olzhiba");
        room->notifySkillInvoked(effect.to, "olzhiba");
    }
    if (room->askForChoice(effect.to, "olzhiba_pindian", "accept+reject") == "reject") {
        LogMessage log;
        log.type = "#ZhibaReject";
        log.from = effect.to;
        log.to << effect.from;
        log.arg = "olzhiba_pindian";
        room->sendLog(log);
        return;
    }
    PindianStruct *pindian = effect.from->PinDian(effect.to, "olzhiba_pindian", NULL);
    if (!pindian) return;
    if (pindian->from_number > pindian->to_number) return;
    if (pindian->to && !pindian->to->isDead() && pindian->to->hasLordSkill("olzhiba")) {
        DummyCard *dummy = new DummyCard();
        int from_card_id = pindian->from_card->getEffectiveId();
        int to_card_id = pindian->to_card->getEffectiveId();
        if (room->getCardPlace(from_card_id) == Player::DiscardPile)
            dummy->addSubcard(from_card_id);
        if (room->getCardPlace(to_card_id) == Player::DiscardPile && from_card_id != to_card_id)
            dummy->addSubcard(to_card_id);
        if (!dummy->getSubcards().isEmpty() && room->askForChoice(pindian->to, "olzhiba_pindian_obtain", "obtainPindianCards+reject") == "obtainPindianCards")
            pindian->to->obtainCard(dummy);
        delete dummy;
    }
}

class OLZhibaPindian : public ZeroCardViewAsSkill
{
public:
    OLZhibaPindian() : ZeroCardViewAsSkill("olzhiba_pindian")
    {
        attached_lord_skill = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return hasTarget(player) && player->getKingdom() == "wu";
    }

    bool hasTarget(const Player *player) const
    {
        QList<const Player *> as = player->getAliveSiblings();
        foreach (const Player *p, as) {
            if (p->hasLordSkill("olzhiba") && p->getMark("olzhiba-PlayClear") <= 0 && player->canPindian(p))
                return true;
        }
        return false;
    }

    const Card *viewAs() const
    {
        return new OLZhibaPindianCard;
    }
};

OLJXTPPackage::OLJXTPPackage()
    : Package("OLJXTP")
{
    General *ol_zhangfei = new General(this, "ol_zhangfei", "shu", 4);
    ol_zhangfei->addSkill(new OLPaoxiao);
    ol_zhangfei->addSkill(new OLPaoxiaoMod);
    ol_zhangfei->addSkill(new OLTishen);
    related_skills.insertMulti("olpaoxiao", "#olpaoxiaomod");

    General *ol_zhaoyun = new General(this, "ol_zhaoyun", "shu", 4);
    ol_zhaoyun->addSkill(new OLLongdan);
    ol_zhaoyun->addSkill(new OLYajiao);

    General *ol_zhangjiao = new General(this, "ol_zhangjiao$", "qun", 3);
    ol_zhangjiao->addSkill(new OLLeiji);
    ol_zhangjiao->addSkill(new OLGuidao);
    ol_zhangjiao->addSkill("huangtian");

    General *ol_yuji = new General(this, "ol_yuji", "qun", 3);
    ol_yuji->addSkill(new OLGuhuo);

    General *ol_xiahouyuan = new General(this, "ol_xiahouyuan", "wei", 4);
    ol_xiahouyuan->addSkill("tenyearshensu");
    ol_xiahouyuan->addSkill(new OLShebian);

    General *ol_weiyan = new General(this, "ol_weiyan", "shu", 4);
    ol_weiyan->addSkill("tenyearkuanggu");
    ol_weiyan->addSkill(new OLQimou);

    General *ol_xiaoqiao = new General(this, "ol_xiaoqiao", "wu", 3, false);
    ol_xiaoqiao->addSkill("tenyeartianxiang");
    ol_xiaoqiao->addSkill(new OLHongyan);
    ol_xiaoqiao->addSkill(new OLHongyanKeep);
    ol_xiaoqiao->addSkill(new OLPiaoling);
    related_skills.insertMulti("olhongyan", "#olhongyan-keep");

    General *ol_yuanshao = new General(this, "ol_yuanshao$", "qun", 4);
    ol_yuanshao->addSkill(new OLLuanji);
    ol_yuanshao->addSkill(new OLXueyi);
    ol_yuanshao->addSkill(new OLXueyiKeep);
    related_skills.insertMulti("olxueyi", "#olxueyikeep");

    General *ol_wolong = new General(this, "ol_wolong", "shu", 3);
    ol_wolong->addSkill("bazhen");
    ol_wolong->addSkill(new OLHuoji);
    ol_wolong->addSkill(new OLKanpo);
    ol_wolong->addSkill(new OLCangzhuo);
    ol_wolong->addSkill(new OLCangzhuoRecord);
    related_skills.insertMulti("olcangzhuo", "#olcangzhuo-record");

    General *ol_pangtong = new General(this, "ol_pangtong", "shu", 3);
    ol_pangtong->addSkill(new OLLianhuan);
    ol_pangtong->addSkill(new OLLianhuanMod);
    ol_pangtong->addSkill(new OLNiepan);
    related_skills.insertMulti("ollianhuan", "#ollianhuanmod");

    General *ol_pangde = new General(this, "ol_pangde", "qun", 4);
    ol_pangde->addSkill(new OLJianchu);
    ol_pangde->addSkill("mashu");

    General *ol_taishici = new General(this, "ol_taishici", "wu", 4);
    ol_taishici->addSkill("tianyi");
    ol_taishici->addSkill(new OLHanzhan);

    General *ol_sunjian = new General(this, "ol_sunjian", "wu", 4);
    ol_sunjian->addSkill("yinghun");
    ol_sunjian->addSkill(new OLWulie);

    General *second_ol_sunjian = new General(this, "second_ol_sunjian", "wu", 5, true, false, false, 4);
    second_ol_sunjian->addSkill("yinghun");
    second_ol_sunjian->addSkill("olwulie");

    //General *ol_zuoci = new General(this, "ol_zuoci", "qun", 3);

    //ol_zuoci->addSkill("xinsheng");

    General *ol_liushan = new General(this, "ol_liushan$", "shu", 3);
    ol_liushan->addSkill("xiangle");
    ol_liushan->addSkill(new OLFangquan);
    ol_liushan->addSkill(new OLRuoyu);
    ol_liushan->addRelateSkill("olsishu");

    General *ol_sunce = new General(this, "ol_sunce$", "wu", 4);
    ol_sunce->addSkill("jiang");
    ol_sunce->addSkill("hunzi");
    ol_sunce->addSkill(new OLZhiba);

    addMetaObject<OLGuhuoCard>();
    addMetaObject<OLQimouCard>();
    addMetaObject<OLWulieCard>();
    addMetaObject<OLFangquanCard>();
    addMetaObject<OLZhibaCard>();
    addMetaObject<OLZhibaPindianCard>();

    skills << new OLSishu << new OLZhibaPindian;
}

ADD_PACKAGE(OLJXTP)
