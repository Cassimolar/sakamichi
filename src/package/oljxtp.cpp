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
#include "mountain.h"
#include "ai.h"
#include "jxtp.h"
#include "clientstruct.h"

class OLHujia : public Hujia
{
public:
    OLHujia() : Hujia("olhujia")
    {
    }
};

class OLHujiaDraw : public TriggerSkill
{
public:
    OLHujiaDraw() : TriggerSkill("#olhujia$")
    {
        events << CardUsed << CardResponded;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getKingdom() == "wei" && target->getPhase() == Player::NotActive;
    }

    QList<ServerPlayer *> getCaocaos(ServerPlayer *player) const
    {
        QList<ServerPlayer *> caocaos;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasLordSkill("olhujia") || p->getMark("olhujia-Clear") > 0) continue;
            caocaos << p;
        }
        return caocaos;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == CardUsed)
            card = data.value<CardUseStruct>().card;
        else
            card = data.value<CardResponseStruct>().m_card;
        if (!card || !card->isKindOf("Jink")) return false;

        QList<ServerPlayer *> caocaos = getCaocaos(player);
        while (player->isAlive() && !caocaos.isEmpty()) {
            ServerPlayer *drawer = room->askForPlayerChosen(player, caocaos, objectName(), "@olhujia-draw", true);
            if (!drawer) break;
            room->doAnimate(1, player->objectName(), drawer->objectName());
            room->addPlayerMark(drawer, "olhujia-Clear");
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << drawer;
            log.arg = drawer->isWeidi() ? "weidi" : "olhujia";
            room->sendLog(log);
            room->notifySkillInvoked(drawer, log.arg);
            if (drawer->isWeidi())
                room->broadcastSkillInvoke("weidi");
            else {
                int r = 1 + qrand() % 2;
                room->broadcastSkillInvoke("hujia", r);
            }
            drawer->drawCards(1, "olhujia");
            caocaos = getCaocaos(player);
        }
        return false;
    }
};

OLJijiangCard::OLJijiangCard() : JijiangCard("oljijiang")
{
    mute = true;
}

class OLJijiangVS : public ZeroCardViewAsSkill
{
public:
    OLJijiangVS() : ZeroCardViewAsSkill("oljijiang$")
    {
    }

    bool hasShuGenerals(const Player *player) const
    {
        foreach(const Player *p, player->getAliveSiblings())
            if (p->getKingdom() == "shu")
                return true;
        return false;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return hasShuGenerals(player) && !player->hasFlag("Global_JijiangFailed") && Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return hasShuGenerals(player)
            && (pattern.contains("slash") || pattern.contains("Slash") || pattern == "@jijiang")
            && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE
            && !player->hasFlag("Global_JijiangFailed");
    }

    const Card *viewAs() const
    {
        return new OLJijiangCard;
    }
};

class OLJijiang : public TriggerSkill
{
public:
    OLJijiang() : TriggerSkill("oljijiang$")
    {
        events << CardAsked << CardUsed << CardResponded;
        view_as_skill = new OLJijiangVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    QList<ServerPlayer *> getLiubeis(ServerPlayer *liubei) const
    {
        QList<ServerPlayer *> liubeis;
        Room *room = liubei->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(liubei)) {
            if (p->isDead() || !p->hasLordSkill(this) || p->getMark("oljijiang-Clear") > 0) continue;
            liubeis << p;
        }
        return liubeis;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *liubei, QVariant &data) const
    {
        if (event == CardAsked) {
            if (!liubei->hasLordSkill("oljijiang")) return false;

            QString pattern = data.toStringList().first();
            QString prompt = data.toStringList().at(1);
            if (pattern != "slash" || prompt.startsWith("@jijiang-slash") || prompt.startsWith("@oljijiang-slash"))
                return false;

            QList<ServerPlayer *> lieges = room->getLieges("shu", liubei);
            if (lieges.isEmpty())
                return false;


            if (!liubei->hasFlag("qinwangjijiang") && !room->askForSkillInvoke(liubei, objectName(), data))
                return false;

            if (!liubei->isLord() && liubei->hasSkill("weidi"))
                room->broadcastSkillInvoke("weidi");
            else {
                int r = 1 + qrand() % 2;
                if (!liubei->hasInnateSkill("jijiang") && liubei->getMark("ruoyu") > 0)
                    r += 2;
                else if (liubei->isJieGeneral())
                    r = qrand() % 2 + 5;

                room->broadcastSkillInvoke("jijiang", r);
            }

            foreach (ServerPlayer *liege, lieges) {
                const Card *slash = room->askForCard(liege, "slash", "@oljijiang-slash:" + liubei->objectName(),
                    QVariant(), Card::MethodResponse, liubei, false, QString(), true);
                if (slash) {
                    room->provide(slash);
                    return true;
                }
            }
        } else {
            if (liubei->getPhase() != Player::NotActive || liubei->getKingdom() != "shu") return false;
            const Card *card = NULL;
            if (event == CardUsed)
                card = data.value<CardUseStruct>().card;
            else
                card = data.value<CardResponseStruct>().m_card;
            if (!card || !card->isKindOf("Slash")) return false;
            QList<ServerPlayer *> liubeis = getLiubeis(liubei);
            while (liubei->isAlive() && !liubeis.isEmpty()) {
                ServerPlayer *drawer = room->askForPlayerChosen(liubei, liubeis, objectName(), "@oljijiang-draw", true);
                if (!drawer) break;
                room->doAnimate(1, liubei->objectName(), drawer->objectName());
                room->addPlayerMark(drawer, "oljijiang-Clear");
                LogMessage log;
                log.type = "#InvokeOthersSkill";
                log.from = liubei;
                log.to << drawer;
                log.arg = drawer->isWeidi() ? "weidi" : objectName();
                room->sendLog(log);
                room->notifySkillInvoked(drawer, objectName());
                if (drawer->isWeidi())
                    room->broadcastSkillInvoke("weidi");
                else {
                    int r = 1 + qrand() % 2;
                    if (!drawer->hasInnateSkill("jijiang") && drawer->getMark("ruoyu") > 0)
                        r += 2;
                    else if (drawer->isJieGeneral())
                        r = qrand() % 2 + 5;
                    room->broadcastSkillInvoke("jijiang", r);
                }
                drawer->drawCards(1, objectName());
                liubeis = getLiubeis(liubei);
            }
        }
        return false;
    }
};

class OLPaoxiao : public TriggerSkill
{
public:
    OLPaoxiao() : TriggerSkill("olpaoxiao")
    {
        frequency = Compulsory;
        events << DamageCaused << SlashMissed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == SlashMissed) {
            if (!player->hasSkill(this)) return false;
            room->addPlayerMark(player, "&olpaoxiao_missed-Clear");
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            int n = player->getMark("&olpaoxiao_missed-Clear");
            if (n <= 0) return false;
            room->setPlayerMark(player, "&olpaoxiao_missed-Clear", 0);
            LogMessage log;
            log.type = "#OlpaoxiaoDamage";
            log.from = player;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            damage.damage += n;
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
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
        room->doSuperLightbox("ol_zhangfei", "oltishen");
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
        return (pattern.contains("slash") || pattern.contains("Slash"))
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
            if (pattern.contains("slash") || pattern.contains("Slash"))
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
        frequency = Frequent;
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
                ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@olyajiao-give", true, true);
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
                ServerPlayer *target = room->askForPlayerChosen(player, targets, "olyajiao_discard", "@olyajiao-discard", true, true);
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
            if (!judge->reason.isEmpty() && Sanguosha->translate(judge->reason) == "暴虐") return false;
            if (judge->card->getSuit() != Card::Club && judge->card->getSuit() != Card::Spade) return false;
            int n = 2;
            if (judge->card->getSuit() == Card::Club) {
                n = 1;
                room->recover(player, RecoverStruct(player));
            }
            if (player->isDead()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@olleiji-invoke:" + QString::number(n),
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

OLHuangtianCard::OLHuangtianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "olhuangtian_attach";
    mute = true;
}

void OLHuangtianCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *zhangjiao = targets.first();
    if (zhangjiao->hasLordSkill("olhuangtian")) {
        room->addPlayerMark(zhangjiao, "olhuangtian-PlayClear");

        if (zhangjiao->isWeidi())
            room->broadcastSkillInvoke("weidi");
        else {
            int index = qrand() % 2 + 1;
            index += 4;
            room->broadcastSkillInvoke("huangtian", index);
        }

        room->notifySkillInvoked(zhangjiao, "olhuangtian");
        room->giveCard(source, zhangjiao, this, "olhuangtian", true);
    }
}

bool OLHuangtianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->hasLordSkill("olhuangtian")
        && to_select != Self && to_select->getMark("olhuangtian-PlayClear") <= 0;
}

class OLHuangtianViewAsSkill : public OneCardViewAsSkill
{
public:
    OLHuangtianViewAsSkill() :OneCardViewAsSkill("olhuangtian_attach")
    {
        attached_lord_skill = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        return to_select->isKindOf("Jink") || (to_select->getSuit() == Card::Spade && !to_select->isEquipped());
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getKingdom() == "qun";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        OLHuangtianCard *card = new OLHuangtianCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class OLHuangtian : public TriggerSkill
{
public:
    OLHuangtian() : TriggerSkill("olhuangtian$")
    {
        events << GameStart << EventAcquireSkill;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if ((triggerEvent == GameStart && player->hasLordSkill(this))
            || (triggerEvent == EventAcquireSkill && data.toString() == "olhuangtian")) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (!p->hasSkill("olhuangtian_attach", true))
                    room->attachSkillToPlayer(p, "olhuangtian_attach");
            }
        }
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

        QString choice = room->askForChoice(player, "olguhuo", "noquestion+question", QVariant::fromValue(yuji));
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
    if ((user_string.contains("slash") || (user_string.contains("Slash")))
        && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList guhuo_list;
        QList<const Slash *> slashs = Sanguosha->findChildren<const Slash *>();
        foreach (const Slash *slash, slashs) {
            QString name = slash->objectName();
            if (guhuo_list.contains(name) || ServerInfo.Extensions.contains("!" + slash->getPackage())) continue;
            guhuo_list << name;
        }

        if (guhuo_list.isEmpty())
            guhuo_list << "slash";
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
        QList<const Peach *> peachs = Sanguosha->findChildren<const Peach *>();
        foreach (const Peach *peach, peachs) {
            QString name = peach->objectName();
            if (guhuo_list.contains(name) || ServerInfo.Extensions.contains("!" + peach->getPackage())) continue;
            guhuo_list << name;
            break;
        }
        QList<const Analeptic *> anas = Sanguosha->findChildren<const Analeptic *>();
        foreach (const Analeptic *ana, anas) {
            QString name = ana->objectName();
            if (guhuo_list.contains(name) || ServerInfo.Extensions.contains("!" + ana->getPackage())) continue;
            guhuo_list << name;
            break;
        }

        if (guhuo_list.isEmpty())
            guhuo_list << "peach";
        to_guhuo = room->askForChoice(yuji, "olguhuo_saveself", guhuo_list.join("+"));
        yuji->tag["OLGuhuoSaveSelf"] = QVariant(to_guhuo);
    } else if (user_string.contains("slash") || user_string.contains("Slash")) {
        QStringList guhuo_list;
        QList<const Slash *> slashs = Sanguosha->findChildren<const Slash *>();
        foreach (const Slash *slash, slashs) {
            QString name = slash->objectName();
            if (guhuo_list.contains(name) || ServerInfo.Extensions.contains("!" + slash->getPackage())) continue;
            guhuo_list << name;
        }

        if (guhuo_list.isEmpty())
            guhuo_list << "slash";
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

OLTianxiangCard::OLTianxiangCard() : TenyearTianxiangCard("oltianxiang")
{
        handling_method = Card::MethodDiscard;
}

class OLTianxiangVS : public OneCardViewAsSkill
{
public:
    OLTianxiangVS() : OneCardViewAsSkill("oltianxiang")
    {
        filter_pattern = ".|heart";
        response_pattern = "@@oltianxiang";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        OLTianxiangCard *tianxiangCard = new OLTianxiangCard;
        tianxiangCard->addSubcard(originalCard);
        return tianxiangCard;
    }
};

class OLTianxiang : public TriggerSkill
{
public:
    OLTianxiang() : TriggerSkill("oltianxiang")
    {
        events << DamageInflicted;
        view_as_skill = new OLTianxiangVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *xiaoqiao, QVariant &) const
    {
        if (xiaoqiao->canDiscard(xiaoqiao, "he")) {
            return room->askForUseCard(xiaoqiao, "@@oltianxiang", "@oltianxiang", -1, Card::MethodDiscard);
        }
        return false;
    }

    int getEffectIndex(const ServerPlayer *player, const Card *) const
    {
        int index = qrand() % 2 + 1;
        if (!player->hasInnateSkill(this) && player->hasSkill("olluoyan"))
            index += 2;

        return index;
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

    int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return -2;
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
        frequency = Frequent;
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
        player->setMark("olpiaoling", judge.card->getEffectiveId()); // For AI
        ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(),
            "@olpiaoling-invoke:" + judge.card->objectName(), true);
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
        player->tag["olluanji_data"] = data;
        ServerPlayer *remove = room->askForPlayerChosen(player, use.to, objectName(), "@olluanji-remove", true);
        player->tag.remove("olluanji_data");
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
    OLXueyi(const QString &xueyi) : TriggerSkill(xueyi + "$"), xueyi(xueyi)
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
            if (!player->isWeidi())
                name = objectName();
            else
                name = "weidi";
            room->sendCompulsoryTriggerLog(player, name, true, true);
            player->gainMark("&olyi", xueyi == "olxueyi" ? qun : 2 * qun);
        } else {
            if ((xueyi == "olxueyi" && player->getPhase() == Player::RoundStart) ||
                    (xueyi == "secondolxueyi" && player->getPhase() == Player::Play)) {
                if (player->getMark("&olyi") <= 0 || !player->askForSkillInvoke(this)) return false;
                room->broadcastSkillInvoke(objectName());
                player->loseMark("&olyi");
                player->drawCards(1, objectName());
            }

        }
        return false;
    }
private:
    QString xueyi;
};

class OLXueyiKeep : public MaxCardsSkill
{
public:
    OLXueyiKeep(const QString &xueyi) : MaxCardsSkill("#" + xueyi + "-keep$"), xueyi(xueyi)
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->hasLordSkill(xueyi))
            return xueyi == "olxueyi" ? 2 * target->getMark("&olyi") : target->getMark("&olyi");
        else
            return 0;
    }
private:
    QString xueyi;
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

    int getEffectIndex(const ServerPlayer *player, const Card *) const
    {
        int index = qrand() % 2 + 1;
        if (player->getGeneralName().contains("pangtong") || player->getGeneral2Name().contains("pangtong"))
            index += 2;
        return index;
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

    int getEffectIndex(const ServerPlayer *player, const Card *) const
    {
        int index = qrand() % 2 + 1;
        if (player->getGeneralName().contains("pangtong") || player->getGeneral2Name().contains("pangtong"))
            index += 2;
        return index;
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

            int n = qMin(3 - pangtong->getHp(), pangtong->getMaxHp() - pangtong->getHp());
            if (n > 0)
                room->recover(pangtong, RecoverStruct(pangtong, NULL, n));

            QStringList skills;
            if (!pangtong->hasSkill("bazhen", true))
                skills << "bazhen";
            if (!pangtong->hasSkill("olhuoji", true))
                skills << "olhuoji";
            if (!pangtong->hasSkill("olkanpo", true))
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
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        PindianStruct *pindian = data.value<PindianStruct *>();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead()) continue;
            if (pindian->from != p && pindian->to != p) continue;
            if (!p->hasSkill(this)) continue;
            if (pindian->from == p) {
                if (pindian->to_card) continue;
                if (pindian->to->isDead() || pindian->to->isKongcheng()) continue;
                if (!p->askForSkillInvoke(this, QVariant::fromValue(pindian->to))) continue;
                room->broadcastSkillInvoke(objectName());
                pindian->to_card = pindian->to->getRandomHandCard();
            }
            if (pindian->to == p) {
                if (pindian->from_card) continue;
                if (pindian->from->isDead() || pindian->from->isKongcheng()) continue;
                if (!p->askForSkillInvoke(this, QVariant::fromValue(pindian->from))) continue;
                room->broadcastSkillInvoke(objectName());
                pindian->from_card = pindian->from->getRandomHandCard();
            }
        }
        return false;
    }
};

SecondOLHanzhanCard::SecondOLHanzhanCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    target_fixed = true;
}

void SecondOLHanzhanCard::onUse(Room *, const CardUseStruct &) const
{
}

class SecondOLHanzhanVS : public OneCardViewAsSkill
{
public:
    SecondOLHanzhanVS() : OneCardViewAsSkill("secondolhanzhan")
    {
        //filter_pattern = ".|.|.|#secondolhanzhan";
        expand_pile = "#secondolhanzhan";
        response_pattern = "@@secondolhanzhan";
    }

    bool viewFilter(const Card *to_select) const
    {
        return Self->getPile("#secondolhanzhan").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *originalCard) const
    {
        SecondOLHanzhanCard *c = new SecondOLHanzhanCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class SecondOLHanzhan : public TriggerSkill
{
public:
    SecondOLHanzhan() : TriggerSkill("secondolhanzhan")
    {
        events << AskforPindianCard << Pindian;
        view_as_skill = new SecondOLHanzhanVS;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == AskforPindianCard)
            return 3;
        return TriggerSkill::getPriority(event);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        PindianStruct *pindian = data.value<PindianStruct *>();
        if (event == AskforPindianCard) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead()) continue;
                if (pindian->from != p && pindian->to != p) continue;
                if (!p->hasSkill(this)) continue;
                if (pindian->from == p) {
                    if (pindian->to_card) continue;
                    if (pindian->to->isDead() || pindian->to->isKongcheng()) continue;
                    if (!p->askForSkillInvoke(this, QVariant::fromValue(pindian->to))) continue;
                    room->broadcastSkillInvoke(objectName());
                    pindian->to_card = pindian->to->getRandomHandCard();
                }
                if (pindian->to == p) {
                    if (pindian->from_card) continue;
                    if (pindian->from->isDead() || pindian->from->isKongcheng()) continue;
                    if (!p->askForSkillInvoke(this, QVariant::fromValue(pindian->from))) continue;
                    room->broadcastSkillInvoke(objectName());
                    pindian->from_card = pindian->from->getRandomHandCard();
                }
            }
        } else {
            QList<ServerPlayer *> pd;
            pd << pindian->from << pindian->to;
            room->sortByActionOrder(pd);
            foreach (ServerPlayer *p, pd) {
                if (p->isDead() || !p->hasSkill(this)) continue;

                QList<int> slash;
                if (pindian->from_number == pindian->to_number) {
                    if (pindian->from_card->isKindOf("Slash") && room->CardInTable(pindian->from_card))
                        slash << pindian->from_card->getEffectiveId();
                    if (pindian->to_card->isKindOf("Slash") && !slash.contains(pindian->to_card->getEffectiveId()) &&
                            room->CardInTable(pindian->to_card))
                        slash << pindian->to_card->getEffectiveId();
                } else {
                    if (pindian->from_card->isKindOf("Slash") && pindian->from_number > pindian->to_number &&
                            room->CardInTable(pindian->from_card))
                        slash << pindian->from_card->getEffectiveId();
                    else if (pindian->to_card->isKindOf("Slash") && pindian->to_number > pindian->from_number &&
                             room->CardInTable(pindian->to_card))
                        slash << pindian->to_card->getEffectiveId();
                    else if (!pindian->from_card->isKindOf("Slash") && pindian->to_card->isKindOf("Slash") &&
                             room->CardInTable(pindian->to_card))
                        slash << pindian->to_card->getEffectiveId();
                    else if (pindian->from_card->isKindOf("Slash") && !pindian->to_card->isKindOf("Slash") &&
                             room->CardInTable(pindian->from_card))
                        slash << pindian->from_card->getEffectiveId();
                }
                if (slash.isEmpty()) return false;

                room->notifyMoveToPile(p, slash, objectName(), Player::PlaceTable, true);
                const Card *c = room->askForUseCard(p, "@@secondolhanzhan", "@secondolhanzhan");
                room->notifyMoveToPile(p, slash, objectName(), Player::PlaceTable, false);
                if (!c) continue;
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = p;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(p, objectName());
                room->broadcastSkillInvoke(objectName());
                room->obtainCard(p, c, true);
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
        waked_skills = "oljijiang,olsishu";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (!player->hasLordSkill(this) || player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->isLowestHpPlayer()) {
            LogMessage log;
            log.type = "#RuoyuWake";
            log.from = player;
            log.arg = QString::number(player->getHp());
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *liushan) const
    {
        Room *room = liushan->getRoom();
        room->notifySkillInvoked(liushan, objectName());
        if (liushan->isWeidi()) {
            room->broadcastSkillInvoke("weidi");
            QString generalName = "yuanshu";
            if (liushan->getGeneralName() == "tw_yuanshu" || (liushan->getGeneral2() != NULL && liushan->getGeneral2Name() == "tw_yuanshu"))
                generalName = "tw_yuanshu";
            room->doSuperLightbox(generalName, "olruoyu");
        } else {
            room->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("ol_liushan", "olruoyu");
        }
        room->setPlayerMark(liushan, "olruoyu", 1);
        if (room->changeMaxHpForAwakenSkill(liushan, 1)) {
            int recover = qMin(3, liushan->getMaxHp()) - liushan->getHp();
            room->recover(liushan, RecoverStruct(liushan, NULL, recover));
            QStringList skills;
            if (liushan->getMark("olruoyu") == 1 && liushan->isLord() && !liushan->hasSkill("oljijiang", true))
                skills << "oljijiang";
            if (!liushan->hasSkill("olsishu", true))
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
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@olsishu-invoke", true, true);
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

class OLQiaomeng : public TriggerSkill
{
public:
    OLQiaomeng() : TriggerSkill("olqiaomeng")
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isAlive() && !damage.to->hasFlag("Global_DebutFlag")
            && damage.card && damage.card->isKindOf("Slash")
            && player->canDiscard(damage.to, "hej") && room->askForSkillInvoke(player, objectName(), QVariant::fromValue(damage.to))) {
            room->broadcastSkillInvoke(objectName());
            int id = room->askForCardChosen(player, damage.to, "hej", objectName(), false, Card::MethodDiscard);
            CardMoveReason reason(CardMoveReason::S_REASON_DISMANTLE, player->objectName(), damage.to->objectName(),
                objectName(), QString());
            const Card *c = Sanguosha->getCard(id);
            room->throwCard(c, reason, damage.to, player);
            if (c->isKindOf("Horse") && player->isAlive())
                room->obtainCard(player, c);
        }
        return false;
    }
};

class OLYicong : public DistanceSkill
{
public:
    OLYicong() : DistanceSkill("olyicong")
    {
    }

    int getCorrect(const Player *from, const Player *to) const
    {
        int correct = 0;
        if (from->hasSkill(this))
            correct--;
        if (to->hasSkill(this) && to->getHp() <= 2)
            correct++;

        return correct;
    }
};

class OLYicongEffect : public TriggerSkill
{
public:
    OLYicongEffect() : TriggerSkill("#olyicong-effect")
    {
        events << HpChanged;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int hp = player->getHp();
        int index = 0;
        int reduce = 0;
        if (data.canConvert<RecoverStruct>()) {
            int rec = data.value<RecoverStruct>().recover;
            if (hp > 2 && hp - rec <= 2)
                index = 1;
        } else {
            if (data.canConvert<DamageStruct>()) {
                DamageStruct damage = data.value<DamageStruct>();
                reduce = damage.damage;
            } else if (!data.isNull()) {
                reduce = data.toInt();
            }
            if (hp <= 2 && hp + reduce > 2)
                index = 2;
        }

        if (index > 0) {
            if (player->getGeneralName().contains("sp_")
                || (!player->getGeneralName().contains("sp_") && player->getGeneral2Name().contains("sp_")))
                index += 2;
            room->broadcastSkillInvoke("olyicong", index);
        }
        return false;
    }
};

class OLHuashen : public GameStartSkill
{
public:
    OLHuashen() : GameStartSkill("olhuashen")
    {
    }

    static void playAudioEffect(ServerPlayer *zuoci, const QString &skill_name)
    {
        zuoci->getRoom()->broadcastSkillInvoke(skill_name, zuoci->isMale(), -1);
    }

    static void AcquireGenerals(ServerPlayer *zuoci, int n, QStringList remove_list)
    {
        Room *room = zuoci->getRoom();
        QVariantList huashens = zuoci->tag["Huashens"].toList();
        QStringList list = GetAvailableGenerals(zuoci, remove_list);
        qShuffle(list);
        if (list.isEmpty()) return;
        n = qMin(n, list.length());

        QStringList acquired = list.mid(0, n);
        foreach (QString name, acquired) {
            huashens << name;
            const General *general = Sanguosha->getGeneral(name);
            if (general) {
                foreach (const TriggerSkill *skill, general->getTriggerSkills()) {
                    if (skill->isVisible())
                        room->getThread()->addTriggerSkill(skill);
                }
            }
        }
        zuoci->tag["Huashens"] = huashens;

        QStringList hidden;
        for (int i = 0; i < n; i++) hidden << "unknown";
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p == zuoci)
                room->doAnimate(QSanProtocol::S_ANIMATE_HUASHEN, zuoci->objectName(), acquired.join(":"), QList<ServerPlayer *>() << p);
            else
                room->doAnimate(QSanProtocol::S_ANIMATE_HUASHEN, zuoci->objectName(), hidden.join(":"), QList<ServerPlayer *>() << p);
        }

        LogMessage log;
        log.type = "#GetHuashen";
        log.from = zuoci;
        log.arg = QString::number(n);
        log.arg2 = QString::number(huashens.length());
        room->sendLog(log);

        LogMessage log2;
        log2.type = "#GetHuashenDetail";
        log2.from = zuoci;
        log2.arg = acquired.join("\\, \\");
        room->sendLog(log2, zuoci);

        room->setPlayerMark(zuoci, "@huashen", huashens.length());
    }

    static QStringList GetAvailableGenerals(ServerPlayer *zuoci, QStringList remove_list)
    {
        QSet<QString> all = Sanguosha->getLimitedGeneralNames().toSet();
        Room *room = zuoci->getRoom();
        if (isNormalGameMode(room->getMode())
            || room->getMode().contains("_mini_")
            || room->getMode() == "custom_scenario")
            all.subtract(Config.value("Banlist/Roles", "").toStringList().toSet());
        else if (room->getMode() == "06_XMode") {
            foreach(ServerPlayer *p, room->getAlivePlayers())
                all.subtract(p->tag["XModeBackup"].toStringList().toSet());
        } else if (room->getMode() == "02_1v1") {
            all.subtract(Config.value("Banlist/1v1", "").toStringList().toSet());
            foreach(ServerPlayer *p, room->getAlivePlayers())
                all.subtract(p->tag["1v1Arrange"].toStringList().toSet());
        }
        QSet<QString> huashen_set, room_set;
        QVariantList huashens = zuoci->tag["Huashens"].toList();
        foreach(QVariant huashen, huashens)
            huashen_set << huashen.toString();
        foreach (ServerPlayer *player, room->getAlivePlayers()) {
            QString name = player->getGeneralName();
            if (Sanguosha->isGeneralHidden(name)) {
                QString fname = Sanguosha->findConvertFrom(name);
                if (!fname.isEmpty()) name = fname;
            }
            room_set << name;

            if (!player->getGeneral2()) continue;

            name = player->getGeneral2Name();
            if (Sanguosha->isGeneralHidden(name)) {
                QString fname = Sanguosha->findConvertFrom(name);
                if (!fname.isEmpty()) name = fname;
            }
            room_set << name;
        }

        static QSet<QString> banned;
        if (banned.isEmpty()) {
            banned << "zuoci" << "guzhielai" << "dengshizai" << "yt_caochong" << "jiangboyue" << "ol_zuoci";
        }
        QSet<QString> remove_set = remove_list.toSet();
        return (all - banned - huashen_set - room_set - remove_set).toList();
    }

    static void SelectSkill(ServerPlayer *zuoci)
    {
        Room *room = zuoci->getRoom();
        playAudioEffect(zuoci, "olhuashen");
        QStringList ac_dt_list;

        QString huashen_skill = zuoci->tag["OLHuashenSkill"].toString();
        if (!huashen_skill.isEmpty())
            ac_dt_list.append("-" + huashen_skill);

        QVariantList huashens = zuoci->tag["Huashens"].toList();
        if (huashens.isEmpty()) return;

        QStringList huashen_generals;
        foreach(QVariant huashen, huashens)
            huashen_generals << huashen.toString();

        QStringList skill_names;
        QString skill_name;
        const General *general = NULL;
        AI* ai = zuoci->getAI();
        if (ai) {
            QHash<QString, const General *> hash;
            foreach (QString general_name, huashen_generals) {
                const General *general = Sanguosha->getGeneral(general_name);
                foreach (const Skill *skill, general->getVisibleSkillList()) {
                    if (skill->isLordSkill()
                        //|| skill->getFrequency() == Skill::Limited
                        || skill->isLimitedSkill()
                        || skill->getFrequency() == Skill::Wake)
                        continue;

                    if (!skill_names.contains(skill->objectName())) {
                        hash[skill->objectName()] = general;
                        skill_names << skill->objectName();
                    }
                }
            }
            if (skill_names.isEmpty()) return;
            skill_name = ai->askForChoice("olhuashen", skill_names.join("+"), QVariant());
            general = hash[skill_name];
            Q_ASSERT(general != NULL);
        } else {
            QString general_name = room->askForGeneral(zuoci, huashen_generals);
            general = Sanguosha->getGeneral(general_name);

            foreach (const Skill *skill, general->getVisibleSkillList()) {
                if (skill->isLordSkill()
                    //|| skill->getFrequency() == Skill::Limited
                    || skill->isLimitedSkill()
                    || skill->getFrequency() == Skill::Wake)
                    continue;

                skill_names << skill->objectName();
            }

            if (!skill_names.isEmpty())
                skill_name = room->askForChoice(zuoci, "olhuashen", skill_names.join("+"));
        }
        //Q_ASSERT(!skill_name.isNull() && !skill_name.isEmpty());

        QString kingdom = general->getKingdom();
        QStringList kingdoms = general->getKingdoms().split("+");
        if (kingdoms.length() > 1) {
            kingdoms.removeOne("god");
            room->setPlayerProperty(zuoci, "kingdom", room->askForKingdom(zuoci, general->objectName() + "_ChooseKingdom"));
        } else if (zuoci->getKingdom() != kingdom) {
            if (kingdom == "god")
                kingdom = room->askForKingdom(zuoci);
            room->setPlayerProperty(zuoci, "kingdom", kingdom);
        }

        if (zuoci->getGender() != general->getGender())
            zuoci->setGender(general->getGender());

        JsonArray arg;
        arg << QSanProtocol::S_GAME_EVENT_HUASHEN << zuoci->objectName() << general->objectName() << skill_name;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);

        zuoci->tag["OLHuashenSkill"] = skill_name;
        if (!skill_name.isEmpty())
            ac_dt_list.append(skill_name);
        room->handleAcquireDetachSkills(zuoci, ac_dt_list, true);
    }

    void onGameStart(ServerPlayer *zuoci) const
    {
        zuoci->getRoom()->notifySkillInvoked(zuoci, "olhuashen");
        AcquireGenerals(zuoci, 3, QStringList());
        SelectSkill(zuoci);
    }

    QDialog *getDialog() const
    {
        static HuashenDialog *dialog;

        if (dialog == NULL)
            dialog = new HuashenDialog;

        return dialog;
    }
};

class OLHuashenSelect : public PhaseChangeSkill
{
public:
    OLHuashenSelect() : PhaseChangeSkill("#olhuashen-select")
    {
    }

    int getPriority(TriggerEvent) const
    {
        return 4;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return PhaseChangeSkill::triggerable(target)
            && (target->getPhase() == Player::RoundStart || target->getPhase() == Player::NotActive);
    }

    bool onPhaseChange(ServerPlayer *zuoci) const
    {
        if (zuoci->hasSkill("olhuashen") && zuoci->askForSkillInvoke("olhuashen")) {
            Room *room = zuoci->getRoom();
            QStringList choices;
            choices << "change" << "exchangeone";
            if (zuoci->tag["Huashens"].toList().length() > 1)
                choices << "exchangetwo";
            QString choice = room->askForChoice(zuoci, "olhuashen", choices.join("+"));
            if (choice == "change")
                OLHuashen::SelectSkill(zuoci);
            else {
                int n = 1;
                if (choice == "exchangetwo")
                    n = 2;
                QStringList remove_list;
                for (int i = 1; i <= n; i++) {
                    QVariantList huashens = zuoci->tag["Huashens"].toList();
                    if (huashens.isEmpty()) break;

                    QStringList huashen_generals;
                    foreach(QVariant huashen, huashens)
                        huashen_generals << huashen.toString();

                    QString general_name = room->askForGeneral(zuoci, huashen_generals);
                    remove_list << general_name;
                    huashens.removeOne(general_name);
                    zuoci->tag["Huashens"] = huashens;
                }

                int length = remove_list.length();
                QStringList acquired = remove_list.mid(0, length);
                LogMessage log;
                log.type = "#RemoveHuashenDetail";
                log.from = zuoci;
                log.arg = QString::number(length);
                log.arg2 = acquired.join("\\, \\");
                room->sendLog(log);

                OLHuashen::AcquireGenerals(zuoci, length, remove_list);
            }
        }

        return false;
    }
};

class OLHuashenClear : public DetachEffectSkill
{
public:
    OLHuashenClear() : DetachEffectSkill("olhuashen")
    {
    }

    void onSkillDetached(Room *room, ServerPlayer *player) const
    {
        if (player->getKingdom() != player->getGeneral()->getKingdom() && player->getGeneral()->getKingdom() != "god")
            room->setPlayerProperty(player, "kingdom", player->getGeneral()->getKingdom());
        if (player->getGender() != player->getGeneral()->getGender())
            player->setGender(player->getGeneral()->getGender());
        QString huashen_skill = player->tag["OLHuashenSkill"].toString();
        if (!huashen_skill.isEmpty() && player->hasSkill(huashen_skill))
            room->detachSkillFromPlayer(player, huashen_skill, false, true);
        player->tag.remove("Huashens");
        room->setPlayerMark(player, "@huashen", 0);
    }
};

class OLJiuchiVS : public OneCardViewAsSkill
{
public:
    OLJiuchiVS() : OneCardViewAsSkill("oljiuchi")
    {
        filter_pattern = ".|spade|.|hand";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Analeptic::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return  pattern.contains("analeptic");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Analeptic *analeptic = new Analeptic(originalCard->getSuit(), originalCard->getNumber());
        analeptic->setSkillName(objectName());
        analeptic->addSubcard(originalCard->getId());
        return analeptic;
    }
};

class OLJiuchi : public TriggerSkill
{
public:
    OLJiuchi() : TriggerSkill("oljiuchi")
    {
        events << Damage;
        view_as_skill = new OLJiuchiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash") && damage.card->hasFlag("drank")) {
            if (player->hasSkill("benghuai")) {
                LogMessage log;
                log.type = "#BenghuaiNullification";
                log.from = player;
                log.arg = objectName();
                log.arg2 = "benghuai";
                room->sendLog(log);
                room->notifySkillInvoked(player, "oljiuchi");
                room->broadcastSkillInvoke("oljiuchi");
            }
            room->addPlayerMark(player, "benghuai_nullification-Clear");
        }
        return false;
    }
};

class OLJiuchiTargetMod : public TargetModSkill
{
public:
    OLJiuchiTargetMod() : TargetModSkill("#oljiuchi-target")
    {
        frequency = NotFrequent;
        pattern = "Analeptic";
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("oljiuchi"))
            return 1000;
        else
            return 0;
    }
};

class OLBaonue : public TriggerSkill
{
public:
    OLBaonue() : TriggerSkill("olbaonue$")
    {
        events << Damage;
        frequency = Frequent;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getKingdom() == "qun";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int damage = data.value<DamageStruct>().damage;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasLordSkill(this)) continue;
            for (int i = 1; i <= damage; i++) {
                if (p->isDead() || !p->hasLordSkill(this)) break;
                if (!p->askForSkillInvoke(this)) break;

                if (p->isWeidi()) {
                    room->notifySkillInvoked(p, "weidi");
                    room->broadcastSkillInvoke("weidi");
                } else {
                    room->notifySkillInvoked(p, objectName());
                    room->broadcastSkillInvoke(objectName());
                }

                JudgeStruct judge;
                judge.pattern = ".|spade";
                judge.reason = objectName();
                judge.good = true;
                judge.who = p;
                room->judge(judge);

                if (judge.isGood() && p->isAlive()) {
                    room->recover(p, RecoverStruct(p));
                    if (p->isAlive() && room->getCardPlace(judge.card->getEffectiveId()) == Player::DiscardPile)
                        p->obtainCard(judge.card);
                }
            }
        }
        return false;
    }
};

class OLJiuyuan : public TriggerSkill
{
public:
    OLJiuyuan() : TriggerSkill("oljiuyuan$")
    {
        events << PreHpRecover;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getKingdom() == "wu" && target->getPhase() != Player::NotActive;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        QList<ServerPlayer *> sunquans;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->hasLordSkill(this)) continue;
            if (player->getHp() >= p->getHp() && p->getLostHp() > 0)
                sunquans << p;
        }
        if (sunquans.isEmpty()) return false;
        ServerPlayer *sunquan = room->askForPlayerChosen(player, sunquans, objectName(), "@tenyearjiuyuan-invoke", true);
        if (!sunquan) return false;
        LogMessage log;
        log.type = "#InvokeOthersSkill";
        log.from = player;
        log.to << sunquan;
        log.arg = "oljiuyuan";
        room->sendLog(log);
        if (!sunquan->isWeidi()) {
            room->notifySkillInvoked(sunquan, objectName());
            room->broadcastSkillInvoke("jiuyuan");
        } else {
            room->notifySkillInvoked(sunquan, "weidi");
            room->broadcastSkillInvoke("weidi");
        }
        room->recover(sunquan, RecoverStruct(player));
        player->drawCards(1, objectName());
        return true;
    }
};

class OLBotu : public PhaseChangeSkill
{
public:
    OLBotu() : PhaseChangeSkill("olbotu")
    {
        frequency = Frequent;
    }

    int getPriority(TriggerEvent) const
    {
        return 1;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::NotActive) return false;
        QStringList botu_str = player->property("olbotu_suit").toStringList();
        Room *room = player->getRoom();
        room->setPlayerProperty(player, "olbotu_suit", QStringList());
        if (botu_str.length() < 4) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        player->gainAnExtraTurn();
        return false;
    }
};

class OLBotuMark : public TriggerSkill
{
public:
    OLBotuMark() : TriggerSkill("#olbotu-mark")
    {
        events << CardFinished << EventPhaseStart;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            if (player->getPhase() != Player::Play) return false;

            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;

            QString suit = use.card->getSuitString() + "_char";
            if (use.card->getSuit() == Card::NoSuit || use.card->getSuit() == Card::NoSuitRed || use.card->getSuit() == Card::NoSuitBlack)
                suit = "no_suit_char";
            QStringList botu_str = player->property("olbotu_suit").toStringList();
            if (botu_str.contains(suit)) return false;
            botu_str << suit;
            room->setPlayerProperty(player, "olbotu_suit", botu_str);

            if (!player->hasSkill("olbotu", true)) return false;

            foreach (QString m, player->getMarkNames()) {
                if (m.startsWith("&olbotu") && player->getMark(m) > 0) {
                    room->setPlayerMark(player, m, 0);
                }
            }
            QString mark = "&olbotu";
            foreach (QString str, botu_str) {
                if (mark.contains(str)) continue;
                mark = mark + "+" + str;
            }
            if (mark == "&olbotu") return false;
            room->setPlayerMark(player, mark, 1);
        } else {
            if (player->getPhase() != Player::NotActive) return false;
            foreach (QString m, player->getMarkNames()) {
                if (m.startsWith("&olbotu") && player->getMark(m) > 0) {
                    room->setPlayerMark(player, m, 0);
                }
            }
        }
        return false;
    }
};

class OLTuntian : public TriggerSkill
{
public:
    OLTuntian() : TriggerSkill("oltuntian")
    {
        events << CardsMoveOneTime << FinishJudge;
        frequency = Frequent;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target);
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player) {
                bool invoke = false;
                if (player->getPhase() == Player::NotActive && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                && !(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip))
                && player->askForSkillInvoke("oltuntian", data))
                    invoke = true;
                else if (player->getPhase() != Player::NotActive
                && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                    bool can_invoke = false;
                    foreach (int id, move.card_ids) {
                        if (Sanguosha->getCard(id)->isKindOf("Slash")) {
                            can_invoke = true;
                            break;
                        }
                    }
                    if (can_invoke && player->askForSkillInvoke("oltuntian", data))
                        invoke = true;
                }
                if (!invoke) return false;
                room->broadcastSkillInvoke("oltuntian");
                JudgeStruct judge;
                judge.pattern = ".|heart";
                judge.good = false;
                judge.reason = "oltuntian";
                judge.who = player;
                room->judge(judge);
            }
        } else if (triggerEvent == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == "oltuntian" && judge->isGood() && room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge)
                player->addToPile("field", judge->card->getEffectiveId());
        }
        return false;
    }
};

class OLTuntianDistance : public DistanceSkill
{
public:
    OLTuntianDistance() : DistanceSkill("#oltuntian-dist")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill("oltuntian"))
            return -from->getPile("field").length();
        else
            return 0;
    }
};

class OLZaoxian : public PhaseChangeSkill
{
public:
    OLZaoxian() : PhaseChangeSkill("olzaoxian")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getPile("field").length() >= 3) {
            LogMessage log;
            log.type = "#ZaoxianWake";
            log.from = player;
            log.arg = QString::number(player->getPile("field").length());
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *dengai) const
    {
        Room *room = dengai->getRoom();
        room->notifySkillInvoked(dengai, objectName());

        room->broadcastSkillInvoke(objectName());

        room->doSuperLightbox("ol_dengai", "olzaoxian");

        room->setPlayerMark(dengai, "olzaoxian", 1);
        if (room->changeMaxHpForAwakenSkill(dengai) && dengai->getMark("olzaoxian") == 1)
            room->acquireSkill(dengai, "jixi");

        int n = dengai->tag["OLzaoxianExtraTurn"].toInt();
        dengai->tag["OLzaoxianExtraTurn"] = ++n;
        return false;
    }
};

class OLZaoxianExtraTurn : public PhaseChangeSkill
{
public:
    OLZaoxianExtraTurn() : PhaseChangeSkill("#olzaoxian-extra-turn")
    {
        frequency = Wake;
    }

    int getPriority(TriggerEvent) const
    {
        return 1;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target->isAlive() && target->getPhase() == Player::NotActive;
    }

    bool onPhaseChange(ServerPlayer *dengai) const
    {
        int n = dengai->tag["OLzaoxianExtraTurn"].toInt();
        if (n <= 0) return false;
        dengai->tag["OLzaoxianExtraTurn"] = --n;
        dengai->gainAnExtraTurn();
        return false;
    }
};

OLChangbiaoCard::OLChangbiaoCard()
{
    will_throw = false;
    handling_method = Card::MethodUse;
}

bool OLChangbiaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(Card::SuitToBeDecided, 0);
    slash->addSubcards(subcards);
    slash->setSkillName("olchangbiao");
    slash->deleteLater();
    return slash->targetFilter(targets, to_select, Self);
}

void OLChangbiaoCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    Slash *slash = new Slash(Card::SuitToBeDecided, 0);
    slash->addSubcards(subcards);
    slash->setSkillName("olchangbiao");
    room->setCardFlag(slash, "olchangbiao");
    slash->deleteLater();

    room->useCard(CardUseStruct(slash, card_use.from, card_use.to), true);
}

class OLChangbiaoVS : public ViewAsSkill
{
public:
    OLChangbiaoVS() : ViewAsSkill("olchangbiao")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped()) return false;
        Slash *slash = new Slash(Card::SuitToBeDecided, 0);
        slash->addSubcards(selected);
        slash->addSubcard(to_select);
        slash->setSkillName("olchangbiao");
        slash->deleteLater();
        return !Self->isCardLimited(slash, Card::MethodUse, true);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        Slash *slash = new Slash(Card::SuitToBeDecided, 0);
        slash->addSubcards(cards);
        slash->setSkillName("olchangbiao");
        slash->deleteLater();
        if (Self->isCardLimited(slash, Card::MethodUse, true)) return NULL;

        OLChangbiaoCard *card = new OLChangbiaoCard;
        card->addSubcards(cards);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("OLChangbiaoCard") && Slash::IsAvailable(player);
    }
};

class OLChangbiao : public TriggerSkill
{
public:
    OLChangbiao() : TriggerSkill("olchangbiao")
    {
        events << DamageDone << EventPhaseEnd;
        view_as_skill = new OLChangbiaoVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || !damage.card->hasFlag("olchangbiao")) return false;
            int mark = 0;
            if (!damage.card->isVirtualCard())
                mark = 1;
            else
                mark = damage.card->subcardsLength();
            if (mark > 0 && damage.from && damage.from->isAlive())
                room->addPlayerMark(damage.from, "olchangbiao_draw-PlayClear", mark);
        } else {
            if (player->getPhase() != Player::Play) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead() || p->getMark("olchangbiao_draw-PlayClear") <= 0) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                p->drawCards(p->getMark("olchangbiao_draw-PlayClear"), objectName());
            }
        }
        return false;
    }
};

OLTiaoxinCard::OLTiaoxinCard()
{
}

bool OLTiaoxinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->inMyAttackRange(Self);
}

void OLTiaoxinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    const Card *use_slash = NULL;
    if (effect.to->canSlash(effect.from, NULL, false)) {
        try {
            use_slash = room->askForUseSlashTo(effect.to, effect.from, "@oltiaoxin-slash:" + effect.from->objectName(), true, false, false,
                   effect.from, this, "oltiaoxin_slash");
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->getMark("oltiaoxin_damage") > 0)
                        room->setPlayerMark(p, "oltiaoxin_damage", 0);
                }
            }
            throw triggerEvent;
        }
    }

    bool hasMark = effect.from->getMark("oltiaoxin_damage") > 0;

    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->getMark("oltiaoxin_damage") > 0)
            room->setPlayerMark(p, "oltiaoxin_damage", 0);
    }

    if ((!use_slash || !hasMark) && effect.from->canDiscard(effect.to, "he")) {
        room->throwCard(room->askForCardChosen(effect.from, effect.to, "he", "oltiaoxin", false, Card::MethodDiscard), effect.to, effect.from);
        room->addPlayerMark(effect.from, "oltiaoxin_extra-Clear");
    }
}

class OLTiaoxinVS : public ZeroCardViewAsSkill
{
public:
    OLTiaoxinVS() : ZeroCardViewAsSkill("oltiaoxin")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("oltiaoxin_extra-Clear") <= 0)
            return !player->hasUsed("OLTiaoxinCard");
        else
            return player->usedTimes("OLTiaoxinCard") < 2;
    }

    const Card *viewAs() const
    {
        return new OLTiaoxinCard;
    }
};

class OLTiaoxin : public TriggerSkill
{
public:
    OLTiaoxin() : TriggerSkill("oltiaoxin")
    {
        events << DamageDone;
        view_as_skill = new OLTiaoxinVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash") && damage.card->hasFlag("oltiaoxin_slash"))
            room->addPlayerMark(player, "oltiaoxin_damage");
        return false;
    }
};

class OLZhiji : public PhaseChangeSkill
{
public:
    OLZhiji() : PhaseChangeSkill("olzhiji")
    {
        frequency = Wake;
        waked_skills = "tenyearguanxing";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start && player->getPhase() != Player::Finish) return false;
        if (player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->isKongcheng()) {
            LogMessage log;
            log.type = "#ZhijiWake";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *jiangwei) const
    {
        Room *room = jiangwei->getRoom();
        room->notifySkillInvoked(jiangwei, objectName());

        room->broadcastSkillInvoke(objectName());

        room->doSuperLightbox("ol_jiangwei", "olzhiji");

        room->setPlayerMark(jiangwei, "olzhiji", 1);
        if (jiangwei->isWounded() && room->askForChoice(jiangwei, objectName(), "recover+draw") == "recover")
            room->recover(jiangwei, RecoverStruct(jiangwei));
        else
            room->drawCards(jiangwei, 2, objectName());
        if (room->changeMaxHpForAwakenSkill(jiangwei))
            room->acquireSkill(jiangwei, "tenyearguanxing");
        return false;
    }
};

OLZaiqiCard::OLZaiqiCard()
{
}

bool OLZaiqiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    return targets.length() < Self->getMark("mobilezaiqi-Clear");
}

void OLZaiqiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead()) return;
    QStringList choices;
    choices << "draw";
    if (effect.from->isAlive() && effect.from->isWounded())
        choices << "recover=" + effect.from->objectName();
    Room *room = effect.from->getRoom();
    QString choice = room->askForChoice(effect.to, "olzaiqi", choices.join("+"), QVariant::fromValue(effect.from));
    if (choice == "draw")
        effect.to->drawCards(1, "olzaiqi");
    else {
        room->recover(effect.from, RecoverStruct(effect.to));
    }
}

class OLZaiqiVS : public ZeroCardViewAsSkill
{
public:
    OLZaiqiVS() : ZeroCardViewAsSkill("olzaiqi")
    {
        response_pattern = "@@olzaiqi";
    }

    const Card *viewAs() const
    {
        return new OLZaiqiCard;
    }
};

class OLZaiqi : public PhaseChangeSkill
{
public:
    OLZaiqi() : PhaseChangeSkill("olzaiqi")
    {
        view_as_skill = new OLZaiqiVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        int n = player->getMark("mobilezaiqi-Clear");
        if (n <= 0) return false;
        player->getRoom()->askForUseCard(player, "@@olzaiqi", "@mobilezaiqi:" + QString::number(n));
        return false;
    }
};

class OLDuanliang : public OneCardViewAsSkill
{
public:
    OLDuanliang() : OneCardViewAsSkill("olduanliang")
    {
        filter_pattern = "BasicCard,EquipCard|black";
        response_or_use = true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        SupplyShortage *shortage = new SupplyShortage(originalCard->getSuit(), originalCard->getNumber());
        shortage->setSkillName(objectName());
        shortage->addSubcard(originalCard);
        return shortage;
    }
};

class OLDuanliangTargetMod : public TargetModSkill
{
public:
    OLDuanliangTargetMod() : TargetModSkill("#olduanliang-target")
    {
        frequency = NotFrequent;
        pattern = "SupplyShortage";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("olduanliang") && from->getMark("damage_point_round") <= 0)
            return 1000;
        else
            return 0;
    }
};

class OLJiezi : public TriggerSkill
{
public:
    OLJiezi() : TriggerSkill("oljiezi")
    {
        events << EventPhaseSkipped << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Draw;
    }

    bool isLeastHandcard(Room *room, ServerPlayer *player) const
    {
        if (player->getMark("&olxhzi") > 0) return false;
        int hand = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() < hand)
                return false;
        }
        return true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == EventPhaseSkipped) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isAlive() && p->hasSkill(this)) {
                    ServerPlayer *t = room->askForPlayerChosen(p, room->getAlivePlayers(), objectName(), "@oljiezi-target", true, true);
                    if (!t) continue;
                    room->broadcastSkillInvoke(this);
                    if (isLeastHandcard(room, t))
                        t->gainMark("&olxhzi");
                    else
                        t->drawCards(1, objectName());
                }
            }
        } else {
            if (player->isDead() || player->getMark("&olxhzi") <= 0) return false;

            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(this);

            player->loseAllMarks("&olxhzi");

            RoomThread *thread = room->getThread();
            if (!thread->trigger(EventPhaseStart, room, player))
                thread->trigger(EventPhaseProceeding, room, player);
            thread->trigger(EventPhaseEnd, room, player);

            player->setPhase(Player::Draw);
            room->broadcastProperty(player, "phase");
        }
        return false;
    }
};

OLQiaobianCard::OLQiaobianCard() : QiaobianCard()
{
    mute = true;
    m_skillName = "olqiaobian";
}

class OLQiaobianVS : public ZeroCardViewAsSkill
{
public:
    OLQiaobianVS() : ZeroCardViewAsSkill("olqiaobian")
    {
        response_pattern = "@@olqiaobian";
    }

    const Card *viewAs() const
    {
        return new OLQiaobianCard;
    }
};

class OLQiaobian : public TriggerSkill
{
public:
    OLQiaobian() : TriggerSkill("olqiaobian")
    {
        events << EventPhaseChanging;
        view_as_skill = new OLQiaobianVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *zhanghe, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        room->setPlayerMark(zhanghe, "olqiaobianPhase", (int)change.to);
        int index = 0;
        switch (change.to) {
        case Player::RoundStart:
        case Player::Start:
        case Player::Finish:
        case Player::NotActive: return false;

        case Player::Judge: index = 1; break;
        case Player::Draw: index = 2; break;
        case Player::Play: index = 3; break;
        case Player::Discard: index = 4; break;
        case Player::PhaseNone: Q_ASSERT(false);
        }

        if (index <= 0) return false;

        QStringList phases;
        phases << "judge" << "draw" << "play" << "discard";
        QString phase = phases.at(index - 1);

        QStringList choices;
        if (zhanghe->canDiscard(zhanghe, "he"))
            choices << "card=" + phase;
        if (zhanghe->getMark("&olzhbian") > 0)
            choices << "mark=" + phase;
        if (choices.isEmpty()) return false;
        choices << "cancel";

        QString choice = room->askForChoice(zhanghe, objectName(), choices.join("+"), data);
        if (choice == "cancel") return false;

        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = zhanghe;
        log.arg = objectName();
        room->sendLog(log);
        room->notifySkillInvoked(zhanghe, objectName());
        zhanghe->peiyin(this);

        if (choice.startsWith("mark"))
            zhanghe->loseMark("&olzhbian");
        else {
            QString discard_prompt = QString("#olqiaobian-%1").arg(index);
            room->askForDiscard(zhanghe, objectName(), 1, 1, false, true, discard_prompt);
        }

        if (!zhanghe->isAlive()) return false;

        QString use_prompt = QString("@olqiaobian-%1").arg(index);
        if (!zhanghe->isSkipped(change.to) && (index == 2 || index == 3))
            room->askForUseCard(zhanghe, "@@olqiaobian", use_prompt, index);
        zhanghe->skip(change.to, true);
        return false;
    }
};

class OLQiaobianGameStart : public GameStartSkill
{
public:
    OLQiaobianGameStart() : GameStartSkill("#olqiaobian")
    {
    }

    void onGameStart(ServerPlayer *player) const
    {
        if (!player->hasSkill("olqiaobian")) return;
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, "olqiaobian", true, true);
        player->gainMark("&olzhbian", 2);
    }
};

class OLQiaobianMark : public PhaseChangeSkill
{
public:
    OLQiaobianMark() : PhaseChangeSkill("#olqiaobian-mark")
    {
        global = true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        int n = player->getHandcardNum();
        QString record = player->property("SkillDescriptionRecord_olqiaobian").toString(), hand = QString::number(n);
        QStringList records;
        if (!record.isEmpty())
            records = record.split("+");
        if (records.contains(hand)) return false;
        Room *room = player->getRoom();
        bool empty = false;
        if (records.isEmpty())
            empty = true;
        records << hand;
        room->setPlayerProperty(player, "SkillDescriptionRecord_olqiaobian", records.join("+"));
        room->changeTranslation(player, "olqiaobian", 1);
        if (!empty && player->hasSkill("olqiaobian")) {
            room->sendCompulsoryTriggerLog(player, "olqiaobian", true, true);
            player->gainMark("&olzhbian");
        }
        return false;
    }
};

class OLBeige : public TriggerSkill
{
public:
    OLBeige() : TriggerSkill("olbeige")
    {
        events << Damaged << FinishJudge;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card == NULL || !damage.card->isKindOf("Slash"))
                return false;

            foreach (ServerPlayer *caiwenji, room->getAllPlayers()) {
                if (player->isDead()) return false;
                if (!TriggerSkill::triggerable(caiwenji)) continue;
                if (!caiwenji->isNude() && caiwenji->askForSkillInvoke(this, player)) {
                    caiwenji->peiyin(this);

                    JudgeStruct judge;
                    judge.good = true;
                    judge.play_animation = false;
                    judge.who = player;
                    judge.reason = objectName();
                    room->judge(judge);

                    QString suit = judge.pattern.split("+").first();
                    QString number = judge.pattern.split("+").last();
                    caiwenji->tag["OLbeigeTag"] = QVariant::fromValue(&judge);
                    const Card *card = room->askForDiscard(caiwenji, objectName(), 1, 1, true, true,
                        "@olbeige-discard:" + player->objectName() + ":" + number + ":" + "<img src='image/system/cardsuit/" + suit + ".png' height = 17/>");
                    caiwenji->tag.remove("OLbeigeTag");
                    if (!card) continue;

                    if (suit == "heart")
                        room->recover(player, RecoverStruct(caiwenji));
                    else if (suit == "diamond")
                        player->drawCards(2, objectName());
                    else if (suit == "club") {
                        if (damage.from && damage.from->isAlive())
                            room->askForDiscard(damage.from, objectName(), 2, 2, false, true);
                    } else if (suit == "spade") {
                        if (damage.from && damage.from->isAlive())
                            damage.from->turnOver();
                    }

                    if (caiwenji->isAlive()) {
                        if (card->getNumberString() == number) {
                            if (room->CardInPlace(card, Player::DiscardPile))
                                room->obtainCard(caiwenji, card);
                        }
                        if (card->getSuitString() == suit) {
                            if (room->CardInPlace(judge.card, Player::DiscardPile))
                                room->obtainCard(caiwenji, judge.card);
                        }
                    }
                }
            }
        } else {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason != objectName()) return false;
            judge->pattern = judge->card->getSuitString() + "+" + judge->card->getNumberString();
        }
        return false;
    }
};

OLJXTPPackage::OLJXTPPackage()
    : Package("OLJXTP")
{
    General *ol_caocao = new General(this, "ol_caocao$", "wei", 4);
    ol_caocao->setImage("caocao");
    ol_caocao->addSkill("tenyearjianxiong");
    ol_caocao->addSkill(new OLHujia);
    ol_caocao->addSkill(new OLHujiaDraw);
    related_skills.insertMulti("olhujia", "#olhujia");

    General *ol_liubei = new General(this, "ol_liubei$", "shu", 4);
    ol_liubei->addSkill("tenyearrende");
    ol_liubei->addSkill(new OLJijiang);

    General *ol_zhangfei = new General(this, "ol_zhangfei", "shu", 4);
    ol_zhangfei->addSkill(new OLPaoxiao);
    ol_zhangfei->addSkill(new OLPaoxiaoMod);
    ol_zhangfei->addSkill(new OLTishen);
    related_skills.insertMulti("olpaoxiao", "#olpaoxiaomod");

    General *ol_zhaoyun = new General(this, "ol_zhaoyun", "shu", 4);
    ol_zhaoyun->addSkill(new OLLongdan);
    ol_zhaoyun->addSkill(new OLYajiao);

    General *ol_sunquan = new General(this, "ol_sunquan$", "wu", 4);
    ol_sunquan->addSkill("tenyearzhiheng");
    ol_sunquan->addSkill(new OLJiuyuan);

    General *ol_lvmeng = new General(this, "ol_lvmeng", "wu", 4);
    ol_lvmeng->addSkill("keji");
    ol_lvmeng->addSkill("qinxue");
    ol_lvmeng->addSkill(new OLBotu);
    ol_lvmeng->addSkill(new OLBotuMark);
    related_skills.insertMulti("olbotu", "#olbotu-mark");

    General *ol_zhangjiao = new General(this, "ol_zhangjiao$", "qun", 3);
    ol_zhangjiao->addSkill(new OLLeiji);
    ol_zhangjiao->addSkill(new OLGuidao);
    ol_zhangjiao->addSkill("huangtian");

    General *second_ol_zhangjiao = new General(this, "second_ol_zhangjiao$", "qun", 3);
    second_ol_zhangjiao->addSkill("olleiji");
    second_ol_zhangjiao->addSkill("olguidao");
    second_ol_zhangjiao->addSkill(new OLHuangtian);

    General *ol_yuji = new General(this, "ol_yuji", "qun", 3);
    ol_yuji->addSkill(new OLGuhuo);

    General *ol_xiahouyuan = new General(this, "ol_xiahouyuan", "wei", 4);
    ol_xiahouyuan->addSkill("tenyearshensu");
    ol_xiahouyuan->addSkill(new OLShebian);

    General *ol_weiyan = new General(this, "ol_weiyan", "shu", 4);
    ol_weiyan->addSkill("tenyearkuanggu");
    ol_weiyan->addSkill(new OLQimou);

    General *ol_xiaoqiao = new General(this, "ol_xiaoqiao", "wu", 3, false);
    ol_xiaoqiao->addSkill(new OLTianxiang);
    ol_xiaoqiao->addSkill(new OLHongyan);
    ol_xiaoqiao->addSkill(new OLHongyanKeep);
    ol_xiaoqiao->addSkill(new OLPiaoling);
    related_skills.insertMulti("olhongyan", "#olhongyan-keep");

    General *ol_yuanshao = new General(this, "ol_yuanshao$", "qun", 4);
    ol_yuanshao->addSkill(new OLLuanji);
    ol_yuanshao->addSkill(new OLXueyi("olxueyi"));
    ol_yuanshao->addSkill(new OLXueyiKeep("olxueyi"));
    related_skills.insertMulti("olxueyi", "#olxueyi-keep");

    General *second_ol_yuanshao = new General(this, "second_ol_yuanshao$", "qun", 4);
    second_ol_yuanshao->addSkill("olluanji");
    second_ol_yuanshao->addSkill(new OLXueyi("secondolxueyi"));
    second_ol_yuanshao->addSkill(new OLXueyiKeep("secondolxueyi"));
    related_skills.insertMulti("secondolxueyi", "#secondolxueyi-keep");

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

    General *second_ol_taishici = new General(this, "second_ol_taishici", "wu", 4);
    second_ol_taishici->addSkill("tianyi");
    second_ol_taishici->addSkill(new SecondOLHanzhan);

    General *ol_sunjian = new General(this, "ol_sunjian", "wu", 4);
    ol_sunjian->addSkill("yinghun");
    ol_sunjian->addSkill(new OLWulie);

    General *second_ol_sunjian = new General(this, "second_ol_sunjian", "wu", 5, true, false, false, 4);
    second_ol_sunjian->addSkill("yinghun");
    second_ol_sunjian->addSkill("olwulie");

    General *ol_dongzhuo = new General(this, "ol_dongzhuo$", "qun", 8);
    ol_dongzhuo->addSkill(new OLJiuchi);
    ol_dongzhuo->addSkill(new OLJiuchiTargetMod);
    ol_dongzhuo->addSkill("roulin");
    ol_dongzhuo->addSkill("benghuai");
    ol_dongzhuo->addSkill(new OLBaonue);
    related_skills.insertMulti("oljiuchi", "#oljiuchi-target");

    General *ol_zuoci = new General(this, "ol_zuoci", "qun", 3);
    ol_zuoci->addSkill(new OLHuashen);
    ol_zuoci->addSkill(new OLHuashenSelect);
    ol_zuoci->addSkill(new OLHuashenClear);
    ol_zuoci->addSkill("xinsheng");
    related_skills.insertMulti("olhuashen", "#olhuashen-select");
    related_skills.insertMulti("olhuashen", "#olhuashen-clear");

    General *ol_liushan = new General(this, "ol_liushan$", "shu", 3);
    ol_liushan->addSkill("xiangle");
    ol_liushan->addSkill(new OLFangquan);
    ol_liushan->addSkill(new OLRuoyu);
    ol_liushan->addRelateSkill("oljijiang");
    ol_liushan->addRelateSkill("olsishu");

    General *ol_sunce = new General(this, "ol_sunce$", "wu", 4);
    ol_sunce->addSkill("jiang");
    ol_sunce->addSkill("hunzi");
    ol_sunce->addSkill(new OLZhiba);

    General *ol_dengai = new General(this, "ol_dengai", "wei", 4);
    ol_dengai->addSkill(new OLTuntian);
    ol_dengai->addSkill(new OLTuntianDistance);
    ol_dengai->addSkill(new OLZaoxian);
    ol_dengai->addSkill(new OLZaoxianExtraTurn);
    ol_dengai->addRelateSkill("jixi");
    related_skills.insertMulti("oltuntian", "#oltuntian-dist");
    related_skills.insertMulti("olzaoxian", "#olzaoxian-extra-turn");

    General *ol_gongsunzan = new General(this, "ol_gongsunzan", "qun", 4);
    ol_gongsunzan->addSkill(new OLQiaomeng);
    ol_gongsunzan->addSkill(new OLYicong);
    ol_gongsunzan->addSkill(new OLYicongEffect);
    related_skills.insertMulti("olyicong", "#olyicong-effect");

    General *ol_zhurong = new General(this, "ol_zhurong", "shu", 4, false);
    ol_zhurong->addSkill("juxiang");
    ol_zhurong->addSkill("lieren");
    ol_zhurong->addSkill(new OLChangbiao);
    ol_zhurong->addSkill(new SlashNoDistanceLimitSkill("olchangbiao"));
    related_skills.insertMulti("olchangbiao", "#olchangbiao-slash-ndl");

    General *ol_jiangwei = new General(this, "ol_jiangwei", "shu", 4);
    ol_jiangwei->addSkill(new OLTiaoxin);
    ol_jiangwei->addSkill(new OLZhiji);

    General *ol_menghuo = new General(this, "ol_menghuo", "shu", 4);
    ol_menghuo->addSkill("huoshou");
    ol_menghuo->addSkill(new OLZaiqi);

    General *ol_xuhuang = new General(this, "ol_xuhuang", "wei", 4);
    ol_xuhuang->addSkill(new OLDuanliang);
    ol_xuhuang->addSkill(new OLDuanliangTargetMod);
    ol_xuhuang->addSkill(new OLJiezi);

    General *ol_zhanghe = new General(this, "ol_zhanghe", "wei", 4);
    ol_zhanghe->addSkill(new OLQiaobian);
    ol_zhanghe->addSkill(new OLQiaobianGameStart);
    ol_zhanghe->addSkill(new OLQiaobianMark);
    related_skills.insertMulti("olqiaobian", "#olqiaobian");
    related_skills.insertMulti("olqiaobian", "#olqiaobian-mark");

    General *ol_caiwenji = new General(this, "ol_jie_caiwenji", "qun", 3, false);
    ol_caiwenji->addSkill(new OLBeige);
    ol_caiwenji->addSkill("duanchang");

    addMetaObject<OLJijiangCard>();
    addMetaObject<OLHuangtianCard>();
    addMetaObject<OLGuhuoCard>();
    addMetaObject<OLQimouCard>();
    addMetaObject<OLTianxiangCard>();
    addMetaObject<OLWulieCard>();
    addMetaObject<OLFangquanCard>();
    addMetaObject<OLZhibaCard>();
    addMetaObject<OLZhibaPindianCard>();
    addMetaObject<SecondOLHanzhanCard>();
    addMetaObject<OLChangbiaoCard>();
    addMetaObject<OLTiaoxinCard>();
    addMetaObject<OLZaiqiCard>();
    addMetaObject<OLQiaobianCard>();

    skills << new OLHuangtianViewAsSkill << new OLSishu << new OLZhibaPindian;
}

ADD_PACKAGE(OLJXTP)
