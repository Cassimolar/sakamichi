#include "jxtp.h"
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
#include "yjcm2013.h"

TenyearZhihengCard::TenyearZhihengCard()
{
    target_fixed = true;
    will_throw = false;
}

void TenyearZhihengCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    bool allhand = true;
    if (source->isKongcheng()) allhand = false;
    QList<int> sub = this->getSubcards();
    foreach(int id, source->handCards()) {
        if (!sub.contains(id)) {
            allhand = false;
            break;
        }
    }
    CardMoveReason reason(CardMoveReason::S_REASON_DISCARD, source->objectName(), "tenyearzhiheng", QString());
    room->throwCard(this, reason, source, NULL);
    int x = sub.length();
    if (allhand) x++;
    source->drawCards(x, "tenyearzhiheng");
}

class TenyearZhiheng : public ViewAsSkill
{
public:
    TenyearZhiheng() : ViewAsSkill("tenyearzhiheng")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        TenyearZhihengCard *zhiheng_card = new TenyearZhihengCard;
        zhiheng_card->addSubcards(cards);
        return zhiheng_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("TenyearZhihengCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@tenyearzhiheng";
    }
};

class TenyearJiuyuan : public TriggerSkill
{
public:
    TenyearJiuyuan() : TriggerSkill("tenyearjiuyuan$")
    {
        events << CardUsed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getKingdom() == "wu";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Peach") || !use.to.contains(player)) return false;
        QList<ServerPlayer *> sunquans;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->hasLordSkill(this)) continue;
            if (player->getHp() > p->getHp() && p->getLostHp() > 0)
                sunquans << p;
        }
        if (sunquans.isEmpty()) return false;
        ServerPlayer *sunquan = room->askForPlayerChosen(player, sunquans, objectName(), "tenyearjiuyuan-invoke", true);
        if (!sunquan) return false;
        LogMessage log;
        log.type = "#InvokeOthersSkill";
        log.from = player;
        log.to << sunquan;
        log.arg = "tenyearjiuyuan";
        room->sendLog(log);
        if (!sunquan->isWeidi()) {
            room->notifySkillInvoked(sunquan, objectName());
            room->broadcastSkillInvoke(objectName());
        } else {
            room->notifySkillInvoked(sunquan, "weidi");
            room->broadcastSkillInvoke("weidi");
        }
        if (sunquan->getLostHp() > 0)
            room->recover(sunquan, RecoverStruct(player));
        player->drawCards(1, objectName());
        return true;
    }
};

TenyearJieyinCard::TenyearJieyinCard()
{
    will_throw = false;
    //handling_method = Card::MethodNone;
}

bool TenyearJieyinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
    int equip_index = static_cast<int>(equip->location());
    if (Self->getEquip(equip_index) == equip)
        return targets.isEmpty() && to_select->isMale() && !to_select->getEquip(equip_index) && !Self->isProhibited(to_select, card);
    return targets.isEmpty() && to_select->isMale();
}

void TenyearJieyinCard::onEffect(const CardEffectStruct &effect) const
{
    const Card *card = Sanguosha->getCard(this->getSubcards().first());
    Room *room = effect.from->getRoom();
    bool move = false;
    if (card->isKindOf("EquipCard")) {
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        int equip_index = static_cast<int>(equip->location());
        if (!effect.to->getEquip(equip_index) && !effect.from->isProhibited(effect.to, card))
            move = true;
    }
    if (move) {
        LogMessage log;
        log.type = "$ZhijianEquip";
        log.from = effect.to;
        log.card_str = QString::number(getEffectiveId());
        room->sendLog(log);
        room->moveCardTo(card, effect.from, effect.to, Player::PlaceEquip,
            CardMoveReason(CardMoveReason::S_REASON_PUT,
            effect.from->objectName(), "tenyearjieyin", QString()));
    } else {
        CardMoveReason reason(CardMoveReason::S_REASON_DISCARD, effect.from->objectName(), "tenyearjieyin", QString());
        room->throwCard(this, reason, effect.from, NULL);
    }

    if (effect.from->getHp() == effect.to->getHp()) return;
    RecoverStruct recover(effect.from);
    if (effect.from->getHp() < effect.to->getHp()) {
        if (effect.from->getLostHp() > 0)
            room->recover(effect.from, recover, true);
        effect.to->drawCards(1, "tenyearjieyin");
    } else {
        effect.from->drawCards(1, "tenyearjieyin");
        if (effect.to->getLostHp() > 0)
            room->recover(effect.to, recover, true);
    }
}

class TenyearJieyin : public OneCardViewAsSkill
{
public:
    TenyearJieyin() :OneCardViewAsSkill("tenyearjieyin")
    {
        filter_pattern = ".";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearJieyinCard *c = new TenyearJieyinCard();
        c->addSubcard(originalCard);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearJieyinCard");
    }
};

TenyearRendeCard::TenyearRendeCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool TenyearRendeCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getMark("tenyearrendetarget-PlayClear") <= 0;
}

void TenyearRendeCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "tenyearrende", QString());
    room->obtainCard(effect.to, this, reason, false);
    room->addPlayerMark(effect.to, "tenyearrendetarget-PlayClear");

    int old_value = effect.from->getMark("tenyearrende-PlayClear");
    int new_value = old_value + subcards.length();
    room->setPlayerMark(effect.from, "tenyearrende-PlayClear", new_value);

    if (old_value < 2 && new_value >= 2) {
        QList<int> list = room->getAvailableCardList(effect.from, "basic", "tenyearrende");
        if (list.isEmpty()) return;
        room->fillAG(list, effect.from);
        int id = room->askForAG(effect.from, list, true, "tenyearrende");
        room->clearAG(effect.from);
        if (id < 0) return;
        QString name = Sanguosha->getEngineCard(id)->objectName();
        room->setPlayerMark(effect.from, "tenyearrende_id-PlayClear", id + 1);
        Card *card = Sanguosha->cloneCard(name);
        if (!card) return;
        card->deleteLater();
        card->setSkillName("_tenyearrende");
        if (card->targetFixed()) {
            if (!effect.from->askForSkillInvoke("tenyearrende", QString("tenyearrende:%1").arg(name), false)) return;
            room->useCard(CardUseStruct(card, effect.from, effect.from));
        } else
            room->askForUseCard(effect.from, "@@tenyearrende", "@tenyearrende:" + name);
    }
}

class TenyearRende : public ViewAsSkill
{
public:
    TenyearRende() : ViewAsSkill("tenyearrende")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@tenyearrende")
            return false;
        return !to_select->isEquipped();
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearrende";
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (cards.isEmpty())
                return NULL;

            TenyearRendeCard *rende_card = new TenyearRendeCard;
            rende_card->addSubcards(cards);
            return rende_card;
        } else {
            if (!cards.isEmpty()) return NULL;
            int id = Self->getMark("tenyearrende_id-PlayClear") - 1;
            if (id < 0) return NULL;
            QString name = Sanguosha->getEngineCard(id)->objectName();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) return NULL;
            card->setSkillName("_tenyearrende");
            return card;
        }
    }
};

class TenyearWusheng : public OneCardViewAsSkill
{
public:
    TenyearWusheng() : OneCardViewAsSkill("tenyearwusheng")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "slash";
    }

    bool viewFilter(const Card *card) const
    {
        if (!card->isRed())
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

class TenyearWushengMod : public TargetModSkill
{
public:
    TenyearWushengMod() : TargetModSkill("#tenyearwushengmod")
    {
        frequency = NotFrequent;
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (from->hasSkill("tenyearwusheng") && card->getSuit() == Card::Diamond && card->isKindOf("Slash"))
            return 1000;
        else
            return 0;
    }
};

TenyearYijueCard::TenyearYijueCard()
{
}

bool TenyearYijueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void TenyearYijueCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isKongcheng()) return;
    Room *room = effect.from->getRoom();
    const Card *show_card = room->askForCardShow(effect.to, effect.from, "tenyearyijue");
    room->showCard(effect.to, show_card->getEffectiveId());

    if (show_card->isRed()) {
        room->obtainCard(effect.from, show_card, true);
        if (effect.to->getLostHp() > 0 && room->askForChoice(effect.from, "tenyearyijue", "recover+cancel") == "recover") {
            room->recover(effect.to, RecoverStruct(effect.from));
        }
    } else if (show_card->isBlack()) {
        effect.to->addMark("tenyearyijue");
        room->setPlayerCardLimitation(effect.to, "use,response", ".|.|.|hand", true);
        room->addPlayerMark(effect.to, "@skill_invalidity");

        foreach(ServerPlayer *p, room->getAllPlayers())
            room->filterCards(p, p->getCards("he"), true);
        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
    }
}

class TenyearYijueVS : public OneCardViewAsSkill
{
public:
    TenyearYijueVS() : OneCardViewAsSkill("tenyearyijue")
    {
        filter_pattern = ".";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearYijueCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearYijueCard *card = new TenyearYijueCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class TenyearYijue : public TriggerSkill
{
public:
    TenyearYijue() : TriggerSkill("tenyearyijue")
    {
        events << EventPhaseChanging << Death << DamageCaused;
        view_as_skill = new TenyearYijueVS;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event != DamageCaused)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *target, QVariant &data) const
    {
        if (triggerEvent == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || damage.card->getSuit() != Card::Heart) return false;
            if (damage.from->hasSkill(this) && damage.to->getMark("tenyearyijue") > 0 && damage.from == room->getCurrent()) {
                LogMessage log;
                log.type = "#TenyearyijueBuff";
                log.from = damage.from;
                log.to << damage.to;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(++damage.damage);
                room->sendLog(log);
                data = QVariant::fromValue(damage);
            }
        } else {
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
                if (player->getMark("tenyearyijue") == 0) continue;
                player->removeMark("tenyearyijue");
                room->removePlayerMark(player, "@skill_invalidity");

                foreach(ServerPlayer *p, room->getAllPlayers())
                    room->filterCards(p, p->getCards("he"), false);

                JsonArray args;
                args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
                room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

                room->removePlayerCardLimitation(player, "use,response", ".|.|.|hand$1");
            }
        }
        return false;
    }
};

class TenyearPaoxiao : public TargetModSkill
{
public:
    TenyearPaoxiao() : TargetModSkill("tenyearpaoxiao")
    {
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill(this))
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("tenyearpaoxiao-PlayClear") > 0 && from->hasSkill(this))
            return 1000;
        else
            return 0;
    }
};

class TenyearPaoxiaoMark : public TriggerSkill
{
public:
    TenyearPaoxiaoMark() : TriggerSkill("#tenyearpaoxiaomark")
    {
        frequency = Compulsory;
        events << CardFinished;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        room->addPlayerMark(player, "tenyearpaoxiao-PlayClear");
        return false;
    }
};

class TenyearTishen : public TriggerSkill
{
public:
    TenyearTishen() : TriggerSkill("tenyeartishen")
    {
        events << CardFinished << EventLoseSkill << EventPhaseChanging << EventPhaseEnd << Damage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            foreach(ServerPlayer *p, use.to) {
                if (p->isDead()) continue;
                if (use.card->hasFlag("tenyeartishen" + p->objectName())) {
                    use.card->setFlags("-tenyeartishen" + p->objectName());
                    continue;
                }
                if (!p->hasSkill(this) || p->getMark("&tenyeartishen") <= 0) continue;
                if (!room->CardInPlace(use.card, Player::DiscardPile)) continue;
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                room->obtainCard(p, use.card, true);
            }

        } else if (event == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (damage.to->isDead()) return false;
            room->setCardFlag(damage.card, "tenyeartishen" + damage.to->objectName());
        } else if (event == EventPhaseChanging) {
            if (player->isDead()) return false;
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::RoundStart) return false;
            room->setPlayerMark(player, "&tenyeartishen", 0);
        } else if (event == EventLoseSkill) {
            if (player->isDead() || data.toString() != objectName()) return false;
            room->setPlayerMark(player, "&tenyeartishen", 0);
        } else if (event == EventPhaseEnd) {
            if (player->isDead() || player->getPhase() != Player::Play || !player->hasSkill(this)) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            DummyCard *dummy = new DummyCard;;
            foreach (const Card *c, player->getCards("he")) {
                if (!c->isKindOf("TrickCard") && !c->isKindOf("OffensiveHorse") && !c->isKindOf("DefensiveHorse")) continue;
                if (player->canDiscard(player, c->getEffectiveId()))
                    dummy->addSubcard(c);
            }
            if (dummy->subcardsLength() > 0)
                room->throwCard(dummy, player, NULL);
            delete dummy;
            room->setPlayerMark(player, "&tenyeartishen", 1);
        }
        return false;
    }
};

class TenyearGuanxing : public PhaseChangeSkill
{
public:
    TenyearGuanxing() : PhaseChangeSkill("tenyearguanxing")
    {
        frequency = Frequent;
    }

    int getPriority(TriggerEvent) const
    {
        return 1;
    }

    bool onPhaseChange(ServerPlayer *zhuge) const
    {
        if (zhuge->getPhase() == Player::Start || (zhuge->getPhase() == Player::Finish && zhuge->getMark("tenyearguanxing-Clear") > 0)) {
            if (!zhuge->askForSkillInvoke(this)) return false;
            Room *room = zhuge->getRoom();
            room->broadcastSkillInvoke(objectName());
            int num = 5;
            if (room->alivePlayerCount() < 4) num = 3;
            QList<int> guanxing = room->getNCards(num, false);
            LogMessage log;
            log.type = "$ViewDrawPile";
            log.from = zhuge;
            log.card_str = IntList2StringList(guanxing).join("+");
            room->sendLog(log, zhuge);
            room->askForGuanxing(zhuge, guanxing);
            /*bool allbottom = true;  //如果牌堆数量太少，就算选择放在牌堆底，还是会检测到id
            int n = qMin(room->getDrawPile().length(), num);
            for (int i = 0; i < n; i++) {
                int id = room->getDrawPile().at(i);
                if (guanxing.contains(id)) {
                    allbottom = false;
                    break;
                }
            }
            if ( n == 0 || !allbottom) return false;*/

            int toplength = room->getTag("Guanxing_TopLength").toInt();
            if (toplength > 0) return false;
            room->addPlayerMark(zhuge, "tenyearguanxing-Clear");
        }
        return false;
    }
};

class TenyearYajiao : public TriggerSkill
{
public:
    TenyearYajiao() : TriggerSkill("tenyearyajiao")
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
                CardMoveReason(CardMoveReason::S_REASON_TURNOVER, player->objectName(), "tenyearyajiao", QString()));
            room->moveCardsAtomic(move, true);
            int id = ids.first();
            if (room->getCardPlace(id) == Player::PlaceTable)
                room->returnToTopDrawPile(ids);

            const Card *card = Sanguosha->getCard(id);
            room->fillAG(ids, player);
            bool dealt = false;
            player->setMark("tenyearyajiao", id); // For AI
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(),
                QString("@tenyearyajiao-give:::%1:%2\\%3").arg(card->objectName()).arg(card->getSuitString() + "_char").arg(card->getNumberString()));
            room->clearAG(player);
            dealt = true;
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "tenyearyajiao", QString());
            room->obtainCard(target, card, reason, true);
            if (card->getTypeId() != cardstar->getTypeId() && player->canDiscard(player, "he")) {
                room->askForDiscard(player, objectName(), 1, 1, false, true);
            }
            if (!dealt) {
                room->clearAG(player);
                if (room->getCardPlace(id) == Player::PlaceTable)
                    room->returnToTopDrawPile(ids);
            }
        }
        return false;
    }
};

class TenyearJizhi : public TriggerSkill
{
public:
    TenyearJizhi() : TriggerSkill("tenyearjizhi")
    {
        frequency = Frequent;
        events << CardUsed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("TrickCard")) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        int id = room->drawCard();
        const Card *card = Sanguosha->getCard(id);
        CardMoveReason reason(CardMoveReason::S_REASON_DRAW, player->objectName(), "tenyearjizhi", QString());
        room->obtainCard(player, card, reason);
        if (!card->isKindOf("BasicCard") || !player->canDiscard(player, card->getEffectiveId())) return false;
        QList<int> ids;
        ids << id;
        room->fillAG(ids, player);
        bool invoke = room->askForSkillInvoke(player, "tenyearjizhi_discard", "discard", false);
        room->clearAG(player);
        if (!invoke) return false;
        room->throwCard(card, player, NULL);
        room->addMaxCards(player, 1);
        return false;
    }
};

class TenyearJianxiong : public MasochismSkill
{
public:
    TenyearJianxiong() : MasochismSkill("tenyearjianxiong")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *caocao, const DamageStruct &damage) const
    {
        if (!caocao->askForSkillInvoke(this)) return;
        Room *room = caocao->getRoom();
        room->broadcastSkillInvoke(objectName());
        caocao->drawCards(1, objectName());

        const Card *card = damage.card;
        if (card && room->CardInTable(card))
            caocao->obtainCard(card);
    }
};

TenyearQingjianCard::TenyearQingjianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void TenyearQingjianCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (room->getCurrent())
        room->addPlayerMark(effect.from, "tenyearqingjian-Clear");
    QList<int> ids= getSubcards();
    LogMessage log;
    log.type = "$ShowCard";
    log.from = effect.from;
    log.card_str = IntList2StringList(ids).join("+");
    room->sendLog(log);
    room->fillAG(ids);
    if(effect.from != effect.to) {
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "tenyearqingjian", QString());
        room->obtainCard(effect.to, this, reason, true);
    }
    room->getThread()->delay(1000);
    room->clearAG();
    QList<int> list;
    foreach (int id, ids) {
        const Card *card = Sanguosha->getCard(id);
        if (list.contains(card->getTypeId())) continue;
        list << card->getTypeId();
    }
    if (list.isEmpty() || !room->hasCurrent(true)) return;
    room->addMaxCards(room->getCurrent(), list.length());
}

class TenyearQingjianVS : public ViewAsSkill
{
public:
    TenyearQingjianVS() : ViewAsSkill("tenyearqingjian")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *) const
    {
        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        TenyearQingjianCard *c = new TenyearQingjianCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearqingjian";
    }
};

class TenyearQingjian : public TriggerSkill
{
public:
    TenyearQingjian() : TriggerSkill("tenyearqingjian")
    {
        events << CardsMoveOneTime;
        view_as_skill = new TenyearQingjianVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!room->getTag("FirstRound").toBool() && player->getPhase() != Player::Draw && move.to == player && move.to_place == Player::PlaceHand) {
            if (player->isNude() || player->getMark("tenyearqingjian-Clear") > 0) return false;
            room->askForUseCard(player, "@@tenyearqingjian", "@tenyearqingjian");
        }
        return false;
    }
};

class TenyearLuoyi : public TriggerSkill
{
public:
    TenyearLuoyi() : TriggerSkill("tenyearluoyi")
    {
        events << EventPhaseStart << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::Draw || !player->hasSkill(this)) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            QList<int> ids = room->showDrawPile(player, 3, objectName());
            QList<int> card_to_throw;
            room->fillAG(ids, player);
            if (!player->askForSkillInvoke(this)) {
                room->clearAG(player);
                foreach (int id, ids) {
                    if (room->getCardPlace(id) == Player::PlaceTable)
                        card_to_throw << id;
                }
                if (!card_to_throw.isEmpty()){
                    DummyCard *dummy = new DummyCard(card_to_throw);
                    CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "tenyearluoyi", QString());
                    room->throwCard(dummy, reason, NULL);
                    delete dummy;
                }
                return false;
            }
            room->broadcastSkillInvoke(objectName());
            room->clearAG(player);
            room->addPlayerMark(player, "&tenyearluoyi");
            QList<int> card_to_gotback;
            for (int i = 0; i < 3; i++) {
                const Card *card = Sanguosha->getCard(ids[i]);
                if (card->getTypeId() == Card::TypeBasic || card->isKindOf("Weapon") || card->isKindOf("Duel"))
                    card_to_gotback << ids[i];
                else {
                    if (room->getCardPlace(ids[i]) == Player::PlaceTable)
                        card_to_throw << ids[i];
                }
            }
            if (!card_to_throw.isEmpty()) {
                DummyCard *dummy = new DummyCard(card_to_throw);
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "tenyearluoyi", QString());
                room->throwCard(dummy, reason, NULL);
                delete dummy;
            }
            if (!card_to_gotback.isEmpty()) {
                DummyCard *dummy = new DummyCard(card_to_gotback);
                room->obtainCard(player, dummy);
                delete dummy;
            }
            return true;
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::RoundStart && player->getMark("&tenyearluoyi") > 0)
                room->setPlayerMark(player, "&tenyearluoyi", 0);
        }
        return false;
    }
};

class TenyearLuoyiBuff : public TriggerSkill
{
public:
    TenyearLuoyiBuff() : TriggerSkill("#tenyearluoyibuff")
    {
        events << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getMark("&tenyearluoyi") > 0 && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *xuchu, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        const Card *reason = damage.card;
        if (reason && (reason->isKindOf("Slash") || reason->isKindOf("Duel"))) {
            LogMessage log;
            log.type = "#LuoyiBuff";
            log.from = xuchu;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            data = QVariant::fromValue(damage);
        }

        return false;
    }
};

class TenyearYiji : public MasochismSkill
{
public:
    TenyearYiji() : MasochismSkill("tenyearyiji")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *target, const DamageStruct &damage) const
    {
        Room *room = target->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            if (target->isAlive() && room->askForSkillInvoke(target, objectName(), QVariant::fromValue(damage))) {
                room->broadcastSkillInvoke(objectName());
                target->drawCards(2, objectName());
                if (!target->isKongcheng()) {
                    QList<int> handcards = target->handCards();
                    int n = 0;
                    while (n < 2) {
                        int length = room->askForyiji(target, handcards, objectName(), false, false, true, 2 - n, room->getOtherPlayers(target));
                        if (length == 0) break;
                        n= n + length;
                    }
                }
            } else
                break;
        }
    }
};

class TenyearLuoshen : public TriggerSkill
{
public:
    TenyearLuoshen() : TriggerSkill("tenyearluoshen")
    {
        events << EventPhaseStart << FinishJudge << EventPhaseProceeding << CardsMoveOneTime << EventPhaseChanging;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *zhenji, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (zhenji->getPhase() != Player::Start) return false;
            bool first = true;
            while (zhenji->askForSkillInvoke("tenyearluoshen")) {
                if (first) {
                    room->broadcastSkillInvoke(objectName());
                    first = false;
                }

                JudgeStruct judge;
                judge.pattern = ".|black";
                judge.good = true;
                judge.reason = objectName();
                judge.play_animation = false;
                judge.who = zhenji;
                judge.time_consuming = true;
                room->judge(judge);
                if (!judge.card->isBlack()) break;
            }
        } else if (triggerEvent == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == objectName()) {
                if (judge->card->isBlack()) {
                    if (room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge) {
                        CardMoveReason reason(CardMoveReason::S_REASON_GOTCARD, zhenji->objectName(), "tenyearluoshen", QString());
                        room->obtainCard(zhenji, judge->card, reason, true);
                    }
                }
            }
        } else if (triggerEvent == EventPhaseProceeding) {
            if (zhenji->getPhase() != Player::Discard) return false;
            QVariantList luoshenlist = zhenji->tag["luoshen_list"].toList();
            if (luoshenlist.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(zhenji, "tenyearluoshen", true, true);
            room->ignoreCards(zhenji, VariantList2IntList(luoshenlist));
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            zhenji->tag.remove("luoshen_list");
        } else if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.reason.m_skillName != objectName()) return false;
            if (move.to == zhenji && move.to_place == Player::PlaceHand) {
                QVariantList luoshenlist = zhenji->tag["luoshen_list"].toList();
                foreach (int id, move.card_ids) {
                    if (luoshenlist.contains(QVariant(id))) continue;
                    luoshenlist << id;
                }
                zhenji->tag["luoshen_list"] = luoshenlist;
            }
        }
        return false;
    }
};

TenyearQingnangCard::TenyearQingnangCard()
{
}

bool TenyearQingnangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->isWounded() && to_select->getMark("tenyearqingnang_target-PlayClear") <= 0;
}

void TenyearQingnangCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (effect.to->getLostHp() > 0)
        room->recover(effect.to, RecoverStruct(effect.from));
    room->setPlayerMark(effect.to, "tenyearqingnang_target-PlayClear", 1);
    const Card *card = Sanguosha->getCard(getSubcards().first());
    if (card->isRed()) return;
    room->setPlayerMark(effect.from, "tenyearqingnang-PlayClear", 1);
}

class TenyearQingnang : public OneCardViewAsSkill
{
public:
    TenyearQingnang() : OneCardViewAsSkill("tenyearqingnang")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "h") && player->getMark("tenyearqingnang-PlayClear") <= 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearQingnangCard *qingnang_card = new TenyearQingnangCard;
        qingnang_card->addSubcard(originalCard);
        return qingnang_card;
    }
};

class TenyearLiyu : public TriggerSkill
{
public:
    TenyearLiyu() : TriggerSkill("tenyearliyu")
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isAlive() && player != damage.to && !damage.to->hasFlag("Global_DebutFlag") && !damage.to->isAllNude()
            && damage.card && damage.card->isKindOf("Slash")) {
            if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.to))) return false;
            room->broadcastSkillInvoke(objectName());
            int card_id = room->askForCardChosen(player, damage.to, "hej", "tenyearliyu");
            const Card *card = Sanguosha->getCard(card_id);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, card, reason, true);

            if (!card->isKindOf("EquipCard"))
                damage.to->drawCards(1, objectName());
            else {
                Duel *duel = new Duel(Card::NoSuit, 0);
                duel->setSkillName("_tenyearliyu");

                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (p != damage.to && !player->isProhibited(p, duel))
                        targets << p;
                }
                if (targets.isEmpty()) {
                    delete duel;
                    return false;
                }
                ServerPlayer *target = room->askForPlayerChosen(damage.to, targets, objectName(), "@tenyearliyu:" + player->objectName());
                if (player->isAlive() && target->isAlive() && !player->isLocked(duel))
                    room->useCard(CardUseStruct(duel, player, target));
                delete duel;
            }
        }
        return false;
    }
};

class TenyearBiyue : public PhaseChangeSkill
{
public:
    TenyearBiyue() : PhaseChangeSkill("tenyearbiyue")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *diaochan) const
    {
        if (diaochan->getPhase() == Player::Finish) {
            Room *room = diaochan->getRoom();
            if (room->askForSkillInvoke(diaochan, objectName())) {
                room->broadcastSkillInvoke(objectName());
                int n = 1;
                if (diaochan->isKongcheng()) n = 2;
                diaochan->drawCards(n, objectName());
            }
        }
        return false;
    }
};

class TenyearYaowu : public TriggerSkill
{
public:
    TenyearYaowu() : TriggerSkill("tenyearyaowu")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash") && player->isAlive()) {
            if (damage.card->isRed()) {
                if (!damage.from || damage.from->isDead()) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true, 2);
                QStringList choices;
                choices << "draw";
                if (damage.from->getLostHp() > 0) choices << "recover";
                if (room->askForChoice(damage.from, objectName(), choices.join("+")) == "draw")
                    damage.from->drawCards(1, objectName());
                else
                    room->recover(damage.from, RecoverStruct(damage.to));
            } else {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true, 1);
                player->drawCards(1, objectName());
            }
        }
        return false;
    }
};


class TenyearLiegong : public TriggerSkill
{
public:
    TenyearLiegong() : TriggerSkill("tenyearliegong")
    {
        events << TargetSpecified << DamageCaused;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            int handnum = player->getHandcardNum();
            int hp = player->getHp();
            foreach (ServerPlayer *p, use.to) {
                if (p->getHandcardNum() > handnum && p->getHp() < hp) continue;
                if (!player->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
                if (p->getHandcardNum() <= handnum) {
                    LogMessage log;
                    log.type = "#NoJink";
                    log.from = p;
                    room->sendLog(log);
                    use.no_respond_list << p->objectName();
                }
                if (p->getHp() >= hp)
                    room->setCardFlag(use.card, "tenyearliegong_damage" + p->objectName());
            }
            data = QVariant::fromValue(use);
        } else if (event == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (damage.to->isDead()) return false;
            if (!damage.card->hasFlag("tenyearliegong_damage" + damage.to->objectName())) return false;
            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class TenyearLiegongMod : public TargetModSkill
{
public:
    TenyearLiegongMod() : TargetModSkill("#tenyearliegongmod")
    {
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (from->hasSkill("tenyearliegong"))
            return qMax(0, card->getNumber() - from->getAttackRange());
        else
            return 0;
    }
};

class TenyearKuanggu : public TriggerSkill
{
public:
    TenyearKuanggu() : TriggerSkill("tenyearkuanggu")
    {
        events << Damage;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        bool invoke = player->tag.value("InvokeTenyearKuanggu", false).toBool();
        player->tag["InvokeTenyearKuanggu"] = false;
        if (invoke) {
            DamageStruct damage = data.value<DamageStruct>();
            for (int i = 1; i <= damage.damage; i++) {
                if (!player->askForSkillInvoke(this)) break;
                room->broadcastSkillInvoke(objectName());
                QStringList choices;
                if (player->getLostHp() > 0)
                    choices << "recover";
                choices << "draw";
                if (room->askForChoice(player, objectName(), choices.join("+")) == "draw")
                    player->drawCards(1, objectName());
                else {
                    if (player->getLostHp() > 0)
                        room->recover(player, RecoverStruct(player));
                }
            }
        }
        return false;
    }
};

class TenyearKuangguRecord : public TriggerSkill
{
public:
    TenyearKuangguRecord() : TriggerSkill("#tenyearkuanggu-record")
    {
        events << PreDamageDone;
        global = true;
    }

    bool trigger(TriggerEvent , Room *, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *weiyan = damage.from;
        if (weiyan && weiyan->isAlive() && damage.to->isAlive())
            weiyan->tag["InvokeTenyearKuanggu"] = (weiyan->distanceTo(damage.to) <= 1);
        return false;
    }
};

TenyearQimouCard::TenyearQimouCard()
{
    target_fixed = true;
}

void TenyearQimouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->removePlayerMark(source, "@tenyearqimouMark");
    room->doSuperLightbox("tenyear_weiyan", "tenyearqimou");
    QStringList choices;
    for (int i = 1; i <= source->getHp(); i++) {
        choices << QString::number(i);
    }
    QString choice = room->askForChoice(source, "tenyearqimou", choices.join("+"));
    int n = choice.toInt();
    room->loseHp(source, n);
    if (source->isAlive()) {
        room->addDistance(source, -n);
        room->addSlashCishu(source, n);
    }
}

class TenyearQimou : public ZeroCardViewAsSkill
{
public:
    TenyearQimou() : ZeroCardViewAsSkill("tenyearqimou")
    {
        frequency = Limited;
        limit_mark = "@tenyearqimouMark";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getHp() > 0 && player->getMark("@tenyearqimouMark") > 0;
    }

    const Card *viewAs() const
    {
        return new TenyearQimouCard;
    }
};

TenyearShensuCard::TenyearShensuCard()
{
    mute = true;
}

bool TenyearShensuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("_tenyearshensu");
    slash->deleteLater();
    return slash->targetFilter(targets, to_select, Self);
}

void TenyearShensuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("_tenyearshensu");
    foreach (ServerPlayer *target, targets) {
        if (!source->canSlash(target, slash, false))
            targets.removeOne(target);
    }

    if (targets.length() > 0) {
        room->useCard(CardUseStruct(slash, source, targets));
    }
}

class TenyearShensuViewAsSkill : public ViewAsSkill
{
public:
    TenyearShensuViewAsSkill() : ViewAsSkill("tenyearshensu")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@tenyearshensu");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern.endsWith("1") || pattern.endsWith("3"))
            return false;
        else
            return selected.isEmpty() && to_select->isKindOf("EquipCard") && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern.endsWith("1") || pattern.endsWith("3")) {
            return cards.isEmpty() ? new TenyearShensuCard : NULL;
        } else {
            if (cards.length() != 1)
                return NULL;

            TenyearShensuCard *card = new TenyearShensuCard;
            card->addSubcards(cards);

            return card;
        }
    }
};

class TenyearShensu : public TriggerSkill
{
public:
    TenyearShensu() : TriggerSkill("tenyearshensu")
    {
        events << EventPhaseChanging;
        view_as_skill = new TenyearShensuViewAsSkill;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *xiahouyuan, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::Judge && !xiahouyuan->isSkipped(Player::Judge)
            && !xiahouyuan->isSkipped(Player::Draw)) {
            if (Slash::IsAvailable(xiahouyuan) && room->askForUseCard(xiahouyuan, "@@tenyearshensu1", "@shensu1", 1)) {
                xiahouyuan->skip(Player::Judge, true);
                xiahouyuan->skip(Player::Draw, true);
            }
        } else if (Slash::IsAvailable(xiahouyuan) && change.to == Player::Play && !xiahouyuan->isSkipped(Player::Play)) {
            if (xiahouyuan->canDiscard(xiahouyuan, "he") && room->askForUseCard(xiahouyuan, "@@tenyearshensu2", "@shensu2", 2, Card::MethodDiscard))
                xiahouyuan->skip(Player::Play, true);
        } else if (change.to == Player::Discard && !xiahouyuan->isSkipped(Player::Discard)) {
            if (Slash::IsAvailable(xiahouyuan) && room->askForUseCard(xiahouyuan, "@@tenyearshensu3", "@tenyearshensu3", 3)) {
                xiahouyuan->skip(Player::Discard, true);
                xiahouyuan->turnOver();
            }
        }
        return false;
    }
};

TenyearJushouCard::TenyearJushouCard()
{
    target_fixed = true;
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
}

void TenyearJushouCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setPlayerProperty(card_use.from, "tenyearjushou", QString());
    int id = getSubcards().first();
    const Card *card = Sanguosha->getCard(id);
    if (card->isKindOf("EquipCard") && card->isAvailable(card_use.from) && !card_use.from->isCardLimited(card, Card::MethodUse))
        room->useCard(CardUseStruct(card, card_use.from, card_use.from));
    else if (!card->isKindOf("EquipCard") && card_use.from->canDiscard(card_use.from, id)) {
        CardMoveReason reason(CardMoveReason::S_REASON_DISCARD, card_use.from->objectName(), "tenyearjushou", QString());
        room->throwCard(this, reason, card_use.from, NULL);
    }
}

class TenyearJushouVS : public OneCardViewAsSkill
{
public:
    TenyearJushouVS() : OneCardViewAsSkill("tenyearjushou")
    {
        response_pattern = "@@tenyearjushou!";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        QStringList l = Self->property("tenyearjushou").toString().split("+");
        QList<int> li = StringList2IntList(l);
        return li.contains(to_select->getId());
    }

    const Card *viewAs(const Card *originalcard) const
    {
        TenyearJushouCard *card = new TenyearJushouCard;
        card->addSubcard(originalcard);
        return card;
    }
};

class TenyearJushou : public PhaseChangeSkill
{
public:
    TenyearJushou() : PhaseChangeSkill("tenyearjushou")
    {
        view_as_skill = new TenyearJushouVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        player->turnOver();
        player->drawCards(4, objectName());
        if (player->isKongcheng()) return false;
        QList<int> list;
        foreach (const Card *c, player->getCards("he")) {
            if (c->isKindOf("EquipCard") && c->isAvailable(player) && !player->isCardLimited(c, Card::MethodUse))
                list << c->getEffectiveId();
            else if (!c->isKindOf("EquipCard") && player->canDiscard(player, c->getEffectiveId()))
                list << c->getEffectiveId();
        }
        if (list.isEmpty()) {
            LogMessage log;
            log.type = "#TenyearjushouShow";
            log.from = player;
            room->sendLog(log);
            room->showAllCards(player);
            return false;
        }
        QString cardsList = IntList2StringList(list).join("+");
        room->setPlayerProperty(player, "tenyearjushou", cardsList);
        if (room->askForUseCard(player, "@@tenyearjushou!", "@tenyearjushou")) return false;
        room->setPlayerProperty(player, "tenyearjushou", QString());
        int id = list.at(qrand() % list.length());
        const Card *card = Sanguosha->getCard(id);
        if (card->isKindOf("EquipCard"))
            room->useCard(CardUseStruct(card, player, player));
        else {
            CardMoveReason reason(CardMoveReason::S_REASON_DISCARD, player->objectName(), "tenyearjushou", QString());
            room->throwCard(card, reason, player, NULL);
        }
        return false;
    }
};

class TenyearJieweiVS : public OneCardViewAsSkill
{
public:
    TenyearJieweiVS() : OneCardViewAsSkill("tenyearjiewei")
    {
        filter_pattern = ".|.|.|equipped";
        response_pattern = "nullification";
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
        return !player->getEquips().isEmpty();
    }
};

class TenyearJiewei : public TriggerSkill
{
public:
    TenyearJiewei() : TriggerSkill("tenyearjiewei")
    {
        events << TurnedOver;
        view_as_skill = new TenyearJieweiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!player->faceUp()) return false;
        if (!player->canDiscard(player, "he")) return false;
        if (!room->askForCard(player, "..", "@tenyearjiewei", QVariant(), objectName())) return false;
        room->broadcastSkillInvoke(objectName());
        room->moveField(player, "tenyearjiewei");
        return false;
    }
};

TenyearTianxiangCard::TenyearTianxiangCard()
{
}

void TenyearTianxiangCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    Room *room = effect.from->getRoom();
    if (room->askForChoice(effect.from, "tenyeartianxiang", "damage+losehp") == "damage") {
        room->damage(DamageStruct("tenyeartianxiang", NULL, effect.to));
        if (effect.to->isDead()) return;
        int n = qMin(5, effect.to->getLostHp());
        if (n <= 0) return;
        effect.to->drawCards(n, "tenyeartianxiang");
    } else {
        room->loseHp(effect.to);
        if (effect.to->isDead()) return;
        room->obtainCard(effect.to, this, true);
    }
}

class TenyearTianxiangViewAsSkill : public OneCardViewAsSkill
{
public:
    TenyearTianxiangViewAsSkill() : OneCardViewAsSkill("tenyeartianxiang")
    {
        filter_pattern = ".|heart|.|hand!";
        response_pattern = "@@tenyeartianxiang";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearTianxiangCard *tianxiangCard = new TenyearTianxiangCard;
        tianxiangCard->addSubcard(originalCard);
        return tianxiangCard;
    }
};

class TenyearTianxiang : public TriggerSkill
{
public:
    TenyearTianxiang() : TriggerSkill("tenyeartianxiang")
    {
        events << DamageInflicted;
        view_as_skill = new TenyearTianxiangViewAsSkill;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *xiaoqiao, QVariant &) const
    {
        if (xiaoqiao->canDiscard(xiaoqiao, "h")) {
            return room->askForUseCard(xiaoqiao, "@@tenyeartianxiang", "@tenyeartianxiang", -1, Card::MethodDiscard);
        }
        return false;
    }

    int getEffectIndex(const ServerPlayer *player, const Card *) const
    {
        int index = qrand() % 2 + 3;
        if (player->getGeneralName().startsWith("tenyear_") || (!player->getGeneralName().startsWith("tenyear_") && player->getGeneral2() &&
                player->getGeneral2Name().startsWith("tenyear_")))
            index -= 2;
        return index;
    }
};

class TenyearJianchu : public TriggerSkill
{
public:
    TenyearJianchu() : TriggerSkill("tenyearjianchu")
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
            if (card->isKindOf("EquipCard")) {
                LogMessage log;
                log.type = "#NoJink";
                log.from = p;
                room->sendLog(log);
                use.no_respond_list << p->objectName();
                data = QVariant::fromValue(use);
            } else {
                if (!room->CardInTable(use.card)) continue;
                p->obtainCard(use.card, true);
            }
        }
        return false;
    }
};

TenyearSanyaoCard::TenyearSanyaoCard()
{
}

bool TenyearSanyaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QList<const Player *> players = Self->getAliveSiblings();
    int max = -1000;
    foreach (const Player *p, players) {
        if (max < p->getHp())
            max = p->getHp();
    }
    return to_select->getHp() == max && targets.length() < this->getSubcards().length() && to_select != Self;
}

bool TenyearSanyaoCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == this->getSubcards().length();
}

void TenyearSanyaoCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->getRoom()->damage(DamageStruct("tenyearsanyao", effect.from, effect.to));
}

class TenyearSanyao : public ViewAsSkill
{
public:
    TenyearSanyao() : ViewAsSkill("tenyearsanyao")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QList<const Player *> players = Self->getAliveSiblings();
        int max = -1000;
        foreach (const Player *p, players) {
            if (max < p->getHp())
                max = p->getHp();
        }
        int num = 0;
        foreach (const Player *p, players) {
            if (p->getHp() == max)
                num++;
        }
        return !Self->isJilei(to_select) && selected.length() < num;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearSanyaoCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        TenyearSanyaoCard *first = new TenyearSanyaoCard;
        first->addSubcards(cards);
        return first;
    }
};

class TenyearZhiman : public TriggerSkill
{
public:
    TenyearZhiman() : TriggerSkill("tenyearzhiman")
    {
        events << DamageCaused;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to == player || damage.to->isDead()) return false;
        if (player->askForSkillInvoke(this, QVariant::fromValue(damage.to))) {
            room->broadcastSkillInvoke(objectName());
            LogMessage log;
            log.type = "#Yishi";
            log.from = player;
            log.arg = objectName();
            log.to << damage.to;
            room->sendLog(log);
            if (damage.to->isAllNude()) return false;
            int card_id = room->askForCardChosen(player, damage.to, "hej", objectName());
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
            return true;
        }
        return false;
    }
};

class TenyearZhenjun : public PhaseChangeSkill
{
public:
    TenyearZhenjun() : PhaseChangeSkill("tenyearzhenjun")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isNude())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "tenyearzhenjun-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        int n = qMax(target->getHandcardNum() - target->getHp(), 1);
        n = qMin(target->getCards("he").length(), n);
        if (n <= 0) return false;

        QList<Player::Place> orig_places;
        QList<int> cards;
        target->setFlags("tenyearzhenjun_InTempMoving");

        for (int i = 0; i < n; ++i) {
            if (!player->canDiscard(target, "he")) break;
            int id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            Player::Place place = room->getCardPlace(id);
            orig_places << place;
            cards << id;
            target->addToPile("#tenyearzhenjun", id, false);
        }
        for (int i = 0; i < n; ++i) {
            if (orig_places.isEmpty()) break;
            room->moveCardTo(Sanguosha->getCard(cards.value(i)), target, orig_places.value(i), false);
        }
        target->setFlags("-tenyearzhenjun_InTempMoving");

        if (!cards.isEmpty()) {
            DummyCard dummy(cards);
            room->throwCard(&dummy, target, player);
            int equips = 0;
            foreach (int id, cards) {
                const Card *card = Sanguosha->getCard(id);
                if (!card->isKindOf("EquipCard"))
                    equips++;
            }
            if (equips == 0) return false;

            int candis = 0;
            foreach (const Card *card, player->getCards("he")) {
                if (player->canDiscard(player, card->getEffectiveId()))
                    candis++;
            }
            if (candis < equips)
                target->drawCards(equips, objectName());
            else {
                if (!room->askForDiscard(player, objectName(), equips, equips, true, true, "tenyearzhenjun-discard:" + QString::number(equips)))
                    target->drawCards(equips, objectName());
            }
        }
        return false;
    }

};

class TenyearJingce : public PhaseChangeSkill
{
public:
    TenyearJingce() : PhaseChangeSkill("tenyearjingce")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() == Player::Finish) {
            if (player->getMark("tenyearjingce-Clear") < player->getHp()) return false;
            Room *room = player->getRoom();
            if (room->askForSkillInvoke(player, objectName())) {
                room->broadcastSkillInvoke(objectName());
                player->drawCards(2, objectName());
            }
        }
        return false;
    }
};

class TenyearJingceRecord : public TriggerSkill
{
public:
    TenyearJingceRecord() : TriggerSkill("#tenyearjingce-record")
    {
        events << PreCardUsed << CardResponded;
        global = true;
    }

    bool trigger(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        if ((triggerEvent == PreCardUsed || triggerEvent == CardResponded) && player->getPhase() != Player::NotActive) {
            const Card *card = NULL;
            if (triggerEvent == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct response = data.value<CardResponseStruct>();
                if (response.m_isUse)
                    card = response.m_card;
            }
            if (card && card->getTypeId() != Card::TypeSkill)
                player->addMark("tenyearjingce-Clear");
        }
        return false;
    }
};

class TenyearDangxian : public PhaseChangeSkill
{
public:
    TenyearDangxian() : PhaseChangeSkill("tenyeardangxian")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (player->getPhase() == Player::RoundStart) {
            //room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            LogMessage log;
            log.type = "#TenyeardangxianPlayPhase";
            log.from = player;
            log.arg = "tenyeardangxian";
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());

            player->setPhase(Player::Play);
            room->broadcastProperty(player, "phase");
            RoomThread *thread = room->getThread();
            room->setPlayerFlag(player, "tenyeardangxian");
            if (!thread->trigger(EventPhaseStart, room, player)) {
                if (player->hasFlag("tenyeardangxian"))
                    room->setPlayerFlag(player, "-tenyeardangxian");
                thread->trigger(EventPhaseProceeding, room, player);
            }
            if (player->hasFlag("tenyeardangxian"))
                room->setPlayerFlag(player, "-tenyeardangxian");
            thread->trigger(EventPhaseEnd, room, player);

            player->setPhase(Player::RoundStart);
            room->broadcastProperty(player, "phase");
        } else if (player->getPhase() == Player::Play) {
            if (!player->hasFlag("tenyeardangxian")) return false;
            room->setPlayerFlag(player, "-tenyeardangxian");
            if (player->getMark(objectName()) <= 0)
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            else {
                if (!player->askForSkillInvoke(objectName()))
                    return false;
                room->broadcastSkillInvoke(objectName());
            }
            room->loseHp(player);
            if (player->isDead()) return  false;
            QList<int> slash;
            foreach (int id, room->getDiscardPile()) {
                const Card *card = Sanguosha->getCard(id);
                if (!card->isKindOf("Slash")) continue;
                slash << id;
            }
            if (slash.isEmpty()) return false;
            room->obtainCard(player, slash.at(qrand() % slash.length()),true);
        }
        return false;
    }
};

class TenyearFuli : public TriggerSkill
{
public:
    TenyearFuli() : TriggerSkill("tenyearfuli")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@tenyearfuliMark";
    }

    int getKingdoms(Room *room) const
    {
        QSet<QString> kingdom_set;
        foreach(ServerPlayer *p, room->getAlivePlayers())
            kingdom_set << p->getKingdom();
        return kingdom_set.size();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *liaohua, QVariant &data) const
    {
        DyingStruct dying_data = data.value<DyingStruct>();
        if (dying_data.who != liaohua || liaohua->getMark("@tenyearfuliMark") <= 0) return false;
        if (liaohua->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());

            room->doSuperLightbox("tenyear_liaohua", "tenyearfuli");

            room->removePlayerMark(liaohua, "@tenyearfuliMark");
            int x = getKingdoms(room);
            int n = qMin(x - liaohua->getHp(), liaohua->getMaxHp() - liaohua->getHp());
            if (n > 0)
                room->recover(liaohua, RecoverStruct(liaohua, NULL, n));
            if (liaohua->getHandcardNum() < x)
                liaohua->drawCards(x - liaohua->getHandcardNum(), objectName());
            room->addPlayerMark(liaohua, "tenyeardangxian");
            QString translate = Sanguosha->translate(":tenyeardangxian2");
            room->changeTranslation(liaohua, "tenyeardangxian", translate);
            if (x >= 3)
                liaohua->turnOver();
        }
        return false;
    }
};

TenyearChunlaoCard::TenyearChunlaoCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void TenyearChunlaoCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->addToPile("wine", this);
}

TenyearChunlaoWineCard::TenyearChunlaoWineCard()
{
    m_skillName = "tenyearchunlao";
    mute = true;
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void TenyearChunlaoWineCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    ServerPlayer *who = room->getCurrentDyingPlayer();
    if (!who) return;

    if (subcards.length() != 0) {
        CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "tenyearchunlao", QString());
        DummyCard *dummy = new DummyCard(subcards);
        room->throwCard(dummy, reason, NULL);
        delete dummy;
        Analeptic *analeptic = new Analeptic(Card::NoSuit, 0);
        analeptic->setSkillName("_tenyearchunlao");
        room->useCard(CardUseStruct(analeptic, who, who, false));
    }
    const Card *card = Sanguosha->getCard(getSubcards().first());
    if (card->getClassName() == "FireSlash") {
        if (source->getLostHp() > 0)
            room->recover(source, RecoverStruct(source));
    } else if (card->getClassName() == "ThunderSlash") {
        source->drawCards(2, "tenyearchunlao");
    }
}

class TenyearChunlaoViewAsSkill : public ViewAsSkill
{
public:
    TenyearChunlaoViewAsSkill() : ViewAsSkill("tenyearchunlao")
    {
        expand_pile = "wine";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@tenyearchunlao"
            || (pattern.contains("peach") && !player->getPile("wine").isEmpty());
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@tenyearchunlao")
            return to_select->isKindOf("Slash");
        else {
            ExpPattern pattern(".|.|.|wine");
            if (!pattern.match(Self, to_select)) return false;
            return selected.length() == 0;
        }
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@tenyearchunlao") {
            if (cards.length() == 0) return NULL;

            Card *acard = new TenyearChunlaoCard;
            acard->addSubcards(cards);
            acard->setSkillName(objectName());
            return acard;
        } else {
            if (cards.length() != 1) return NULL;
            Card *wine = new TenyearChunlaoWineCard;
            wine->addSubcards(cards);
            wine->setSkillName(objectName());
            return wine;
        }
    }
};

class TenyearChunlao : public PhaseChangeSkill
{
public:
    TenyearChunlao() : PhaseChangeSkill("tenyearchunlao")
    {
        view_as_skill = new TenyearChunlaoViewAsSkill;
    }

    bool onPhaseChange(ServerPlayer *chengpu) const
    {
        Room *room = chengpu->getRoom();
        if (chengpu->getPhase() == Player::Finish && !chengpu->isKongcheng() && chengpu->getPile("wine").isEmpty())
            room->askForUseCard(chengpu, "@@tenyearchunlao", "@tenyearchunlao", -1, Card::MethodNone);
        return false;
    }
};

TenyearJiangchiCard::TenyearJiangchiCard()
{
    target_fixed = true;
}

void TenyearJiangchiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (getSubcards().isEmpty()) {
        source->drawCards(1, "tenyearjiangchi");
        room->setPlayerCardLimitation(source, "use,response", "Slash", true);
    } else if (getSubcards().length() == 1) {
        room->addSlashJuli(source, 1000);
        room->addSlashCishu(source, 1);
    }
}

class TenyearJiangchiVS : public ViewAsSkill
{
public:
    TenyearJiangchiVS() : ViewAsSkill("tenyearjiangchi")
    {
    }
    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyearjiangchi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && selected.isEmpty();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 0 && cards.length() != 1) return NULL;
        Card *acard = new TenyearJiangchiCard;
        if (!cards.isEmpty())
            acard->addSubcards(cards);
        return acard;
    }
};

class TenyearJiangchi : public TriggerSkill
{
public:
    TenyearJiangchi() : TriggerSkill("tenyearjiangchi")
    {
        events << EventPhaseEnd;
        view_as_skill = new TenyearJiangchiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *caozhang, QVariant &) const
    {
        if (caozhang->getPhase() != Player::Draw) return false;
        room->askForUseCard(caozhang, "@@tenyearjiangchi", "@tenyearjiangchi");
        return false;
    }
};

TenyearWurongCard::TenyearWurongCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool TenyearWurongCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length() > 0 || to_select == Self)
        return false;
    return !to_select->isKongcheng();
}

void TenyearWurongCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();

    const Card *c = room->askForExchange(effect.to, "tenyearwurong", 1, 1, false, "@tenyearwurong-show");

    room->showCard(effect.from, subcards.first());
    room->showCard(effect.to, c->getSubcards().first());

    const Card *card1 = Sanguosha->getCard(subcards.first());
    const Card *card2 = Sanguosha->getCard(c->getSubcards().first());

    if (card1->isKindOf("Slash") && !card2->isKindOf("Jink")) {
        room->damage(DamageStruct(objectName(), effect.from, effect.to));
    } else if (!card1->isKindOf("Slash") && card2->isKindOf("Jink")) {
        if (!effect.to->isNude()) {
            int id = room->askForCardChosen(effect.from, effect.to, "he", objectName());
            room->obtainCard(effect.from, id, false);
        }
    }

    delete c;
}

class TenyearWurong : public OneCardViewAsSkill
{
public:
    TenyearWurong() : OneCardViewAsSkill("tenyearwurong")
    {
        filter_pattern = ".|.|.|hand";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        TenyearWurongCard *fr = new TenyearWurongCard;
        fr->addSubcard(originalCard);
        return fr;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearWurongCard");
    }
};

class TenyearYaoming : public TriggerSkill
{
public:
    TenyearYaoming() : TriggerSkill("tenyearyaoming")
    {
        events << Damage << Damaged;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (player->getMark("tenyearyaoming_dayu-Clear") <= 0 && p->getHandcardNum() > player->getHandcardNum() && player->canDiscard(p, "h"))
                targets << p;
            if (player->getMark("tenyearyaoming_xiaoyu-Clear") <= 0 && p->getHandcardNum() < player->getHandcardNum())
                targets << p;
            if (player->getMark("tenyearyaoming_dengyu-Clear") <= 0 && p->canDiscard(p, "he") && p->getHandcardNum() == player->getHandcardNum())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "tenyearyaoming-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        if (target->getHandcardNum() > player->getHandcardNum()) {
            room->addPlayerMark(player, "tenyearyaoming_dayu-Clear");
            if (!player->canDiscard(target, "h")) return false;
            int card_id = room->askForCardChosen(player, target, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(Sanguosha->getCard(card_id), target, player);
        } else if (target->getHandcardNum() < player->getHandcardNum()) {
            room->addPlayerMark(player, "tenyearyaoming_xiaoyu-Clear");
            target->drawCards(1, objectName());
        } else {
            room->addPlayerMark(player, "tenyearyaoming_dengyu-Clear");
            const Card * card = room->askForExchange(target, objectName(), 2, 1, true, "tenyearyaoming-discard", true);
            if (!card) return false;
            room->throwCard(card, target, NULL);
            target->drawCards(card->getSubcards().length(), objectName());
        }
        return false;
    }
};

TenyearDanshouCard::TenyearDanshouCard()
{
    target_fixed = true;
}

class TenyearDanshouVS : public ViewAsSkill
{
public:
    TenyearDanshouVS() :ViewAsSkill("tenyeardanshou")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        return selected.length() < Self->getMark("tenyeardanshou_current_hand");
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@tenyeardanshou";
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != Self->getMark("tenyeardanshou_current_hand"))
            return NULL;
        TenyearDanshouCard *card = new TenyearDanshouCard;
        card->addSubcards(cards);
        return card;
    }
};

class TenyearDanshou : public TriggerSkill
{
public:
    TenyearDanshou() : TriggerSkill("tenyeardanshou")
    {
        events << TargetConfirmed << EventPhaseStart;
        view_as_skill = new TenyearDanshouVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.to.contains(player) || !player->hasSkill(this)) return false;
            if (player->getMark("tenyeardanshou-Clear") > 0) return false;
            const Card *card = use.card;
            if (!card->isKindOf("BasicCard") && !card->isKindOf("TrickCard")) return false;
            int x = player->getMark("tenyeardanshou_target-Clear");
            QString num = QString::number(x);
            if (!player->askForSkillInvoke(this, QString("tenyeardanshou_invoke:%1").arg(num))) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "tenyeardanshou-Clear");
            player->drawCards(x, objectName());
        } else {
            if (player->getPhase() != Player::Finish) return false;
            foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
                if (player->isDead()) break;
                if (p->getMark("tenyeardanshou-Clear") > 0) continue;
                if (player->isKongcheng()) {
                    if (!p->askForSkillInvoke(objectName(), QString("tenyeardanshou_damage:%1").arg(player->objectName()))) continue;
                    room->broadcastSkillInvoke(objectName());
                    room->damage(DamageStruct(objectName(), p, player));
                } else {
                    int candis = 0;
                    foreach (const Card *c, p->getCards("he")) {
                        if (p->canDiscard(p, c->getEffectiveId()))
                            candis++;
                    }
                    int handnum = player->getHandcardNum();
                    if (candis < handnum) continue;
                    room->setPlayerMark(p, "tenyeardanshou_current_hand", handnum);
                    if (!room->askForUseCard(p, "@@tenyeardanshou", "@tenyeardanshou:" + QString::number(handnum))) {
                        room->setPlayerMark(p, "tenyeardanshou_current_hand", 0);
                        continue;
                    }
                    room->setPlayerMark(p, "tenyeardanshou_current_hand", 0);
                    room->damage(DamageStruct(objectName(), p, player));
                }
            }
        }
        return false;
    }
};

class TenyearDanshouRecord : public TriggerSkill
{
public:
    TenyearDanshouRecord() : TriggerSkill("#tenyeardanshou-record")
    {
        events << TargetConfirmed;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (!use.to.contains(player)) return false;
        room->addPlayerMark(player, "tenyeardanshou_target-Clear");
        return false;
    }
};

class TenyearZenhui : public TriggerSkill
{
public:
    TenyearZenhui() : TriggerSkill("tenyearzenhui")
    {
        events << TargetSpecifying << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (triggerEvent == CardFinished && (use.card->isKindOf("Slash") || (use.card->isNDTrick() && use.card->isBlack()))) {
            use.from->setFlags("-TenyearZenhuiUser_" + use.card->toString());
            return false;
        }
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Play || player->hasFlag(objectName()))
            return false;

        if (use.to.length() == 1 && (use.card->isKindOf("Slash") || (use.card->isNDTrick() && use.card->isBlack()))) {
            QList<ServerPlayer *> targets = room->getOtherPlayers(use.to.first());
            if (targets.contains(player))
                targets.removeOne(player);
            if (targets.isEmpty()) return false;
            use.from->tag["tenyearzenhui"] = data;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "tenyearzenhui-invoke:" + use.to.first()->objectName(), true, true);
            use.from->tag.remove("tenyearzenhui");
            if (target) {

                // Collateral
                ServerPlayer *collateral_victim = NULL;
                if (use.card->isKindOf("Collateral")) {
                    QList<ServerPlayer *> victims;
                    foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                        if (target->canSlash(p))
                            victims << p;
                    }
                    Q_ASSERT(!victims.isEmpty());
                    collateral_victim = room->askForPlayerChosen(player, victims, "tenyearzenhui_collateral", "@tenyearzenhui-collateral:" + target->objectName());
                    target->tag["collateralVictim"] = QVariant::fromValue((collateral_victim));

                    LogMessage log;
                    log.type = "#CollateralSlash";
                    log.from = player;
                    log.to << collateral_victim;
                    room->sendLog(log);
                }

                room->broadcastSkillInvoke(objectName());

                bool canbeextra = true;
                if (room->isProhibited(player, target, use.card) || !use.card->targetFilter(QList<const Player *>(), target, player))
                    canbeextra = false;
                if (target->isNude() && !canbeextra) return false;
                bool extra_target = true;
                if (!target->isNude()) {
                    QString pattern = "..";
                    QString prompt = "tenyearzenhui-give:" + player->objectName();
                    if (!canbeextra) {
                        pattern = "..!";
                        prompt = "tenyearzenhui-mustgive:" + player->objectName();
                    }
                    const Card *card = room->askForCard(target, pattern, prompt, data, Card::MethodNone);
                    if (!canbeextra && !card) {
                        card = target->getCards("he").at(qrand() % target->getCards("he").length());
                    }
                    if (card) {
                        extra_target = false;
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "tenyearzenhui", QString());
                        room->obtainCard(player, card, reason, false);

                        if (target->isAlive()) {
                            LogMessage log;
                            log.type = "#BecomeUser";
                            log.from = target;
                            log.card_str = use.card->toString();
                            room->sendLog(log);

                            target->setFlags("TenyearZenhuiUser_" + use.card->toString()); // For AI
                            use.from = target;
                            data = QVariant::fromValue(use);
                        }
                    }
                }
                if (extra_target) {
                    player->setFlags(objectName());
                    LogMessage log;
                    log.type = "#BecomeTarget";
                    log.from = target;
                    log.card_str = use.card->toString();
                    room->sendLog(log);

                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    if (use.card->isKindOf("Collateral") && collateral_victim)
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), collateral_victim->objectName());

                    use.to.append(target);
                    room->sortByActionOrder(use.to);
                    data = QVariant::fromValue(use);
                }
            }
        }
        return false;
    }
};

class TenyearJiaojin : public TriggerSkill
{
public:
    TenyearJiaojin() : TriggerSkill("tenyearjiaojin")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player)) return false;
        if (!use.from || use.from->isDead() || !use.from->isMale()) return false;
        if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
        if (!room->askForCard(player, ".Equip", "@tenyearjiaojin", data, objectName())) return false;
        room->broadcastSkillInvoke(objectName());
        use.nullified_list << player->objectName();
        data = QVariant::fromValue(use);
        //if (room->getCardPlace(use.card->getEffectiveId() != Player::PlaceTable)) return false;
        if (!room->CardInPlace(use.card, Player::PlaceTable)) return false;
        room->obtainCard(player, use.card);
        return false;
    }
};

class TenyearBenxiVS : public ZeroCardViewAsSkill
{
public:
    TenyearBenxiVS() : ZeroCardViewAsSkill("tenyearbenxi")
    {
        response_pattern = "@@tenyearbenxi!";
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

class TenyearBenxi : public TriggerSkill
{
public:
    TenyearBenxi() : TriggerSkill("tenyearbenxi")
    {
        events << CardUsed << DamageCaused << PreCardUsed << CardResponded;
        view_as_skill =new TenyearBenxiVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (player->getPhase() == Player::NotActive || use.card->isKindOf("SkillCard")) return false;
            //room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->addPlayerMark(player, "tenyearbenxi_distance-Clear");
            LogMessage log;
            log.type = "#TenyearbenxiDistance";
            log.from = player;
            log.arg = "tenyearbenxi";
            log.arg2 = QString::number(-player->getMark("tenyearbenxi_distance-Clear"));
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->addDistance(player, -1);
        } else if (event == CardResponded) {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (player->getPhase() == Player::NotActive || res.m_card->isKindOf("SkillCard")) return false;
            if (!res.m_isUse) return false;
            room->addPlayerMark(player, "tenyearbenxi_distance-Clear");
            LogMessage log;
            log.type = "#TenyearbenxiDistance";
            log.from = player;
            log.arg = "tenyearbenxi";
            log.arg2 = QString::number(-player->getMark("tenyearbenxi_distance-Clear"));
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->addDistance(player, -1);
        } else if (event == PreCardUsed) {
            if (player->getPhase() == Player::NotActive) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
            if (use.to.length() != 1) return false;
            int allone = true;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->distanceTo(p) != 1) {
                    allone = false;
                    break;
                }
            }
            if (!allone) return false;
            QStringList choices;
            QList<ServerPlayer *> available_targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                if (use.from == p && use.card->isKindOf("AOE")) continue;
                if (use.card->targetFixed()) {
                    if (!use.card->isKindOf("Peach") || p->isWounded())
                        available_targets << p;
                } else {
                    if (use.card->targetFilter(QList<const Player *>(), p, player))
                        available_targets << p;
                }
            }
            if (!available_targets.isEmpty()) choices << "extra";
            choices << "ignore" << "noresponse" << "draw" <<"cancel";
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            for (int i = 1; i <= 2; i++) {
                if (choices.isEmpty()) break;
                QString choice = room->askForChoice(player, objectName(), choices.join("+"));
                if (choice == "cancel") break;
                choices.removeOne(choice);
                LogMessage log;
                log.type = "#FumianFirstChoice";
                log.from = player;
                log.arg = "tenyearbenxi:" + choice;
                room->sendLog(log);
                if (choice == "extra") {
                    ServerPlayer *target = NULL;
                    if (!use.card->isKindOf("Collateral"))
                        target = room->askForPlayerChosen(player, available_targets, objectName(), "tenyearbenxi-extra:" + use.card->objectName());
                    else {
                        QStringList tos;
                        foreach(ServerPlayer *t, use.to)
                            tos.append(t->objectName());
                        room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                        room->setPlayerProperty(player, "extra_collateral_current_targets", tos.join("+"));
                        room->askForUseCard(player, "@@tenyearbenxi!", "tenyearbenxi-extra:" + use.card->objectName());
                        room->setPlayerProperty(player, "extra_collateral", QString());
                        room->setPlayerProperty(player, "extra_collateral_current_targets", QString("+"));
                        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                            if (p->hasFlag("ExtraCollateralTarget")) {
                                p->setFlags("-ExtraCollateralTarget");
                                target = p;
                                break;
                            }
                        }
                        if (target == NULL) {
                            target = available_targets.at(qrand() % available_targets.length() - 1);
                            QList<ServerPlayer *> victims;
                            foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                                if (target->canSlash(p)
                                    && (!(p == player && p->hasSkill("kongcheng") && p->isLastHandCard(use.card, true)))) {
                                    victims << p;
                                }
                            }
                            Q_ASSERT(!victims.isEmpty());
                            target->tag["collateralVictim"] = QVariant::fromValue((victims.at(qrand() % victims.length() - 1)));
                        }
                    }
                    use.to.append(target);
                    room->sortByActionOrder(use.to);

                    if (use.card->hasFlag("tenyearbenxi_ignore"))
                        target->addQinggangTag(use.card);

                    room->setPlayerFlag(target, "no_offset_from");

                    LogMessage log;
                    log.type = "#QiaoshuiAdd";
                    log.from = player;
                    log.to << target;
                    log.card_str = use.card->toString();
                    log.arg = "tenyearbenxi";
                    room->sendLog(log);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());

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
                } else if (choice == "ignore") {
                    room->setCardFlag(use.card, "tenyearbenxi_ignore");
                    foreach (ServerPlayer *p, use.to)
                        p->addQinggangTag(use.card);
                } else if (choice == "noresponse") {
                    use.no_offset_list << "_ALL_TARGETS";
                    room->setCardFlag(use.card, "no_offset_card");
                    room->setPlayerFlag(player, "no_offset_from");
                    data = QVariant::fromValue(use);
                } else {
                    room->setCardFlag(use.card, "tenyearbenxi_damage");
                }
            }
        } else if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card->hasFlag("tenyearbenxi_damage")) return false;
            player->drawCards(1, objectName());
        }
        return false;
    }
};

TenyearKuangfuCard::TenyearKuangfuCard()
{
}

bool TenyearKuangfuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canDiscard(to_select, "e");
}

void TenyearKuangfuCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->getEquips().isEmpty()) return;
    Room *room = effect.from->getRoom();
    int card_id = room->askForCardChosen(effect.from, effect.to, "e", "tenyearkuangfu", false, Card::MethodDiscard);
    room->throwCard(card_id, effect.to, effect.from);
    if (effect.from->isDead()) return;
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName("_tenyearkuangfu");
    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.from)) {
        if (effect.from->canSlash(p, slash, false)) {
            targets << p;
        }
    }
    if (targets.isEmpty()) return;
    if (!room->askForUseCard(effect.from, "@@tenyearkuangfu!", "@tenyearkuangfu")) {
        ServerPlayer *target = targets.at(qrand() % targets.length() - 1);
        room->useCard(CardUseStruct(slash, effect.from , target), false);
    }

    bool damage = effect.from->getMark("tenyearkuangfu_damage") > 0;
    room->setPlayerMark(effect.from, "tenyearkuangfu_damage", 0);

    if (effect.to == effect.from && damage) {
        effect.from->drawCards(2, "tenyearkuangfu");
    } else if (effect.to != effect.from && !damage) {
        room->askForDiscard(effect.from, "tenyearkuangfu", 2, 2);
    }
}

class TenyearKuangfuVS : public ZeroCardViewAsSkill
{
public:
    TenyearKuangfuVS() : ZeroCardViewAsSkill("tenyearkuangfu")
    {
        response_pattern = "@@tenyearkuangfu!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearKuangfuCard");
    }

    const Card *viewAs() const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern() == "@@tenyearkuangfu!") {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_tenyearkuangfu");
            return slash;
        }
        return new TenyearKuangfuCard;
    }
};

class TenyearKuangfu : public TriggerSkill
{
public:
    TenyearKuangfu() : TriggerSkill("tenyearkuangfu")
    {
        events << PreCardUsed << Damage;
        view_as_skill =new TenyearKuangfuVS;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName() == "tenyearkuangfu" && !use.card->isKindOf("SkillCard") && use.m_addHistory)
                room->addPlayerHistory(player, use.card->getClassName(), -1);
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->getSkillName() == "tenyearkuangfu" && !damage.card->isKindOf("SkillCard"))
                room->setPlayerMark(player, "tenyearkuangfu_damage", 1);
        }
        return false;
    }
};

class TenyearPojun : public TriggerSkill
{
public:
    TenyearPojun() : TriggerSkill("tenyearpojun")
    {
        events << TargetSpecified << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card != NULL && use.card->isKindOf("Slash") && TriggerSkill::triggerable(player)) {
                foreach (ServerPlayer *t, use.to) {
                    if (player->isDead()) return false;
                    if (t->isDead()) continue;
                    int n = qMin(t->getCards("he").length(), t->getHp());
                    if (n > 0 && player->askForSkillInvoke(this, QVariant::fromValue(t))) {
                        room->broadcastSkillInvoke(objectName());
                        QStringList dis_num;
                        for (int i = 1; i <= n; ++i)
                            dis_num << QString::number(i);

                        int ad = Config.AIDelay;
                        Config.AIDelay = 0;

                        bool ok = false;
                        int discard_n = room->askForChoice(player, objectName() + "_num", dis_num.join("+")).toInt(&ok);
                        if (!ok || discard_n == 0) {
                            Config.AIDelay = ad;
                            continue;
                        }

                        QList<Player::Place> orig_places;
                        QList<int> cards;
                        // fake move skill needed!!!
                        t->setFlags("tenyearpojun_InTempMoving");

                        for (int i = 0; i < discard_n; ++i) {
                            int id = room->askForCardChosen(player, t, "he", objectName() + "_dis", false, Card::MethodNone);
                            Player::Place place = room->getCardPlace(id);
                            orig_places << place;
                            cards << id;
                            t->addToPile("#mobilepojun", id, false);
                        }

                        for (int i = 0; i < discard_n; ++i)
                            room->moveCardTo(Sanguosha->getCard(cards.value(i)), t, orig_places.value(i), false);

                        t->setFlags("-tenyearpojun_InTempMoving");
                        Config.AIDelay = ad;

                        DummyCard dummy(cards);
                        t->addToPile("tenyearpojun", &dummy);

                        QList<int> equips;
                        bool has_trick = false;
                        foreach (int id, cards) {
                            if (Sanguosha->getCard(id)->isKindOf("EquipCard"))
                                equips << id;
                            else if (Sanguosha->getCard(id)->isKindOf("TrickCard"))
                                has_trick = true;
                        }

                        if (!equips.isEmpty()) {
                            room->fillAG(equips, player);
                            int id = room->askForAG(player, equips, false, objectName());
                            room->clearAG(player);
                            cards.removeOne(id);
                            room->throwCard(id, t, player);
                        }

                        if (has_trick)
                            player->drawCards(1, objectName());

                        // for record
                        if (!t->tag.contains("tenyearpojun") || !t->tag.value("tenyearpojun").canConvert(QVariant::Map))
                            t->tag["tenyearpojun"] = QVariantMap();

                        QVariantMap vm = t->tag["tenyearpojun"].toMap();
                        foreach (int id, cards)
                            vm[QString::number(id)] = player->objectName();

                        t->tag["tenyearpojun"] = vm;
                    }
                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->tag.contains("tenyearpojun")) {
                    QVariantMap vm = p->tag.value("tenyearpojun", QVariantMap()).toMap();
                    if (vm.values().contains(player->objectName())) {
                        QList<int> to_obtain;
                        foreach (const QString &key, vm.keys()) {
                            if (vm.value(key) == player->objectName())
                                to_obtain << key.toInt();
                        }

                        DummyCard dummy(to_obtain);
                        room->obtainCard(p, &dummy, true);

                        foreach (int id, to_obtain)
                            vm.remove(QString::number(id));

                        p->tag["tenyearpojun"] = vm;
                    }
                }
            }
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

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() == Player::Start) {
            Room *room = target->getRoom();
            if (room->askForSkillInvoke(target, objectName())) {
                room->broadcastSkillInvoke(objectName());
                target->drawCards(1, objectName());
                if (!target->canDiscard(target, "he")) return false;
                const Card *cards = room->askForExchange(target, objectName(), 1, 1, true, "tenyearqianxi-discard");
                room->throwCard(cards, target, NULL);
                if (target->isDead()) return false;

                QString color = "red";
                if (!Sanguosha->getCard(cards->getSubcards().first())->isRed())
                    color = "black";
                target->tag[objectName()] = QVariant::fromValue(color);

                QList<ServerPlayer *> to_choose;
                foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                    if (target->distanceTo(p) == 1)
                        to_choose << p;
                }
                if (to_choose.isEmpty())
                    return false;

                ServerPlayer *victim = room->askForPlayerChosen(target, to_choose, objectName());
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());
                QString pattern = QString(".|%1|.|hand$0").arg(color);

                room->setPlayerFlag(victim, "TenyearQianxiTarget");
                //room->addPlayerMark(victim, QString("@qianxi_%1").arg(color));
                room->setPlayerMark(victim, "&tenyearqianxi+" + color + "-Clear", 1);
                room->setPlayerCardLimitation(victim, "use,response", pattern, false);

                LogMessage log;
                log.type = "#Qianxi";
                log.from = victim;
                log.arg = QString("no_suit_%1").arg(color);
                room->sendLog(log);
            }
        }
        return false;
    }
};

class TenyearQianxiClear : public TriggerSkill
{
public:
    TenyearQianxiClear() : TriggerSkill("#tenyearqianxi-clear")
    {
        events << EventPhaseChanging << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return !target->tag["tenyearqianxi"].toString().isNull();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive)
                return false;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player)
                return false;
        }

        QString color = player->tag["tenyearqianxi"].toString();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->hasFlag("TenyearQianxiTarget")) {
                room->setPlayerFlag(p, "-TenyearQianxiTarget");
                room->removePlayerCardLimitation(p, "use,response", QString(".|%1|.|hand$0").arg(color));
            }
        }
        return false;
    }
};

class TenyearDuanliang : public OneCardViewAsSkill
{
public:
    TenyearDuanliang() : OneCardViewAsSkill("tenyearduanliang")
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

class TenyearDuanliangTargetMod : public TargetModSkill
{
public:
    TenyearDuanliangTargetMod() : TargetModSkill("#tenyearduanliang-target")
    {
        frequency = NotFrequent;
        pattern = "SupplyShortage";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->hasSkill("tenyearduanliang") && from->getHandcardNum() <= to->getHandcardNum())
            return 1000;
        else
            return 0;
    }
};

class TenyearJiezi : public TriggerSkill
{
public:
    TenyearJiezi() : TriggerSkill("tenyearjiezi")
    {
        events << EventPhaseSkipped;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Draw) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isAlive() && p->hasSkill(this)) {
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                p->drawCards(1, objectName());
            }
        }
        return false;
    }
};

TenyearAnguoCard::TenyearAnguoCard()
{
}

bool TenyearAnguoCard::isOK(ServerPlayer *player, const QString &flag) const
{
    Room *room = player->getRoom();
    if (flag == "hand") {
        int hand = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() < hand)
                return false;
        }
    } else if (flag == "equip") {
        int equip = player->getEquips().length();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getEquips().length() < equip)
                return false;
        }
    }
    return true;
}

void TenyearAnguoCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead()) return;
    Room *room = effect.to->getRoom();
    bool hand = true;
    bool recover = true;
    bool equip = true;

    if (isOK(effect.to, "hand"))
        effect.to->drawCards(1, "tenyearanguo");
    else
        hand = false;

    if (effect.to->isAlive() && effect.to->isLowestHpPlayer())
        room->recover(effect.to, RecoverStruct(effect.from));
    else
        recover = false;

    QList<int> equips;
    foreach (int id, room->getDrawPile()) {
        if (Sanguosha->getCard(id)->isKindOf("EquipCard"))
            equips << id;
    }
    if (isOK(effect.to, "equip")) {
        if (!equips.isEmpty()) {
            int id = equips.at(qrand() % equips.length());
            const Card *c = Sanguosha->getCard(id);
            if (c->isAvailable(effect.to))
                room->useCard(CardUseStruct(c, effect.to, effect.to));
        }
    } else
        equip = false;

    if (!hand && effect.from->isAlive() && isOK(effect.from, "hand"))
        effect.from->drawCards(1, "tenyearanguo");

    if (!recover && effect.from->isAlive() && effect.from->isLowestHpPlayer())
        room->recover(effect.from, RecoverStruct(effect.from));

    if (!equip && effect.from->isAlive() && isOK(effect.from, "equip")) {
        if (!equips.isEmpty()) {
            int id = equips.at(qrand() % equips.length());
            const Card *c = Sanguosha->getCard(id);
            if (c->isAvailable(effect.from))
                room->useCard(CardUseStruct(c, effect.from, effect.from));
        }
    }
}

class TenyearAnguo : public ZeroCardViewAsSkill
{
public:
    TenyearAnguo() : ZeroCardViewAsSkill("tenyearanguo")
    {
    }

    const Card *viewAs() const
    {
        return new TenyearAnguoCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TenyearAnguoCard");
    }
};

class TenyearCanshi : public TriggerSkill
{
public:
    TenyearCanshi() : TriggerSkill("tenyearcanshi")
    {
        events << DrawNCards << CardUsed << CardResponded;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == DrawNCards) {
            if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Draw) {
                int n = 0;
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isWounded())
                        ++n;
                }

                if (n > 0 && player->askForSkillInvoke(this)) {
                    room->broadcastSkillInvoke(objectName());
                    player->setFlags(objectName());
                    data = QVariant::fromValue(data.toInt() + n);
                }
            }
        } else {
            if (player->hasFlag(objectName())) {
                const Card *card = NULL;
                if (triggerEvent == CardUsed)
                    card = data.value<CardUseStruct>().card;
                else {
                    CardResponseStruct resp = data.value<CardResponseStruct>();
                    if (resp.m_isUse)
                        card = resp.m_card;
                }
                if (card != NULL && (card->isKindOf("Slash") || card->isNDTrick())) {
                    room->sendCompulsoryTriggerLog(player, objectName());
                    room->askForDiscard(player, objectName(), 1, 1, false, true, "@tenyearcanshi-discard");
                }
            }
        }
        return false;
    }
};

class TenyearChouhai : public TriggerSkill
{
public:
    TenyearChouhai() : TriggerSkill("tenyearchouhai")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash")) return false;
        if (player->isKongcheng()) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

JXTPPackage::JXTPPackage()
    : Package("JXTP")
{
    General *tenyear_sunquan = new General(this, "tenyear_sunquan$", "wu", 4);
    tenyear_sunquan->addSkill(new TenyearZhiheng);
    tenyear_sunquan->addSkill(new TenyearJiuyuan);

    General *tenyear_sunshangxiang = new General(this, "tenyear_sunshangxiang", "wu", 3, false);
    tenyear_sunshangxiang->addSkill(new TenyearJieyin);
    tenyear_sunshangxiang->addSkill("xiaoji");

    General *tenyear_liubei = new General(this, "tenyear_liubei$", "shu", 4);
    tenyear_liubei->addSkill(new TenyearRende);
    tenyear_liubei->addSkill("jijiang");

    General *tenyear_guanyu = new General(this, "tenyear_guanyu", "shu", 4);
    tenyear_guanyu->addSkill(new TenyearWusheng);
    tenyear_guanyu->addSkill(new TenyearWushengMod);
    tenyear_guanyu->addSkill(new TenyearYijue);
    related_skills.insertMulti("tenyearwusheng", "#tenyearwushengmod");

    General *tenyear_zhangfei = new General(this, "tenyear_zhangfei", "shu", 4);
    tenyear_zhangfei->addSkill(new TenyearPaoxiao);
    tenyear_zhangfei->addSkill(new TenyearPaoxiaoMark);
    tenyear_zhangfei->addSkill(new TenyearTishen);
    related_skills.insertMulti("tenyearpaoxiao", "#tenyearpaoxiaomark");

    General *tenyear_zhugeliang = new General(this, "tenyear_zhugeliang", "shu", 3);
    tenyear_zhugeliang->addSkill(new TenyearGuanxing);
    tenyear_zhugeliang->addSkill("kongcheng");

    General *tenyear_zhaoyun = new General(this, "tenyear_zhaoyun", "shu", 4);
    tenyear_zhaoyun->addSkill("longdan");
    tenyear_zhaoyun->addSkill(new TenyearYajiao);

    General *tenyear_huangyueying = new General(this, "tenyear_huangyueying", "shu", 3, false);
    tenyear_huangyueying->addSkill(new TenyearJizhi);
    tenyear_huangyueying->addSkill("qicai");

    General *tenyear_caocao = new General(this, "tenyear_caocao$", "wei", 4);
    tenyear_caocao->addSkill(new TenyearJianxiong);
    tenyear_caocao->addSkill("hujia");

    General *tenyear_xiahoudun = new General(this, "tenyear_xiahoudun", "wei", 4);
    tenyear_xiahoudun->addSkill("ganglie");
    tenyear_xiahoudun->addSkill(new TenyearQingjian);

    General *tenyear_xuchu = new General(this, "tenyear_xuchu", "wei", 4);
    tenyear_xuchu->addSkill(new TenyearLuoyi);
    tenyear_xuchu->addSkill(new TenyearLuoyiBuff);
    related_skills.insertMulti("tenyearluoyi", "#tenyearluoyibuff");

    General *tenyear_guojia = new General(this, "tenyear_guojia", "wei", 3);
    tenyear_guojia->addSkill("tiandu");
    tenyear_guojia->addSkill(new TenyearYiji);

    General *tenyear_zhenji = new General(this, "tenyear_zhenji", "wei", 3, false);
    tenyear_zhenji->addSkill("qingguo");
    tenyear_zhenji->addSkill(new TenyearLuoshen);

    General *tenyear_huatuo = new General(this, "tenyear_huatuo", "qun", 3);
    tenyear_huatuo->addSkill("jijiu");
    tenyear_huatuo->addSkill(new TenyearQingnang);

    General *tenyear_lvbu = new General(this, "tenyear_lvbu", "qun", 5);
    tenyear_lvbu->addSkill("wushuang");
    tenyear_lvbu->addSkill(new TenyearLiyu);

    General *tenyear_diaochan = new General(this, "tenyear_diaochan", "qun", 3, false);
    tenyear_diaochan->addSkill("lijian");
    tenyear_diaochan->addSkill(new TenyearBiyue);

    General *tenyear_huaxiong = new General(this, "tenyear_huaxiong", "qun", 6);
    tenyear_huaxiong->addSkill(new TenyearYaowu);

    General *tenyear_huangzhong = new General(this, "tenyear_huangzhong", "shu", 4);
    tenyear_huangzhong->addSkill(new TenyearLiegong);
    tenyear_huangzhong->addSkill(new TenyearLiegongMod);
    related_skills.insertMulti("tenyearliegong", "#tenyearliegongmod");

    General *tenyear_weiyan = new General(this, "tenyear_weiyan", "shu", 4);
    tenyear_weiyan->addSkill(new TenyearKuanggu);
    tenyear_weiyan->addSkill(new TenyearKuangguRecord);
    tenyear_weiyan->addSkill(new TenyearQimou);
    related_skills.insertMulti("tenyearkuanggu", "#tenyearkuanggu-record");

    General *tenyear_xiahouyuan = new General(this, "tenyear_xiahouyuan", "wei", 4);
    tenyear_xiahouyuan->addSkill(new TenyearShensu);
    tenyear_xiahouyuan->addSkill(new SlashNoDistanceLimitSkill("tenyearshensu"));
    related_skills.insertMulti("tenyearshensu", "#tenyearshensu-slash-ndl");

    General *tenyear_caoren = new General(this, "tenyear_caoren", "wei", 4);
    tenyear_caoren->addSkill(new TenyearJushou);
    tenyear_caoren->addSkill(new TenyearJiewei);

    General *tenyear_xiaoqiao = new General(this, "tenyear_xiaoqiao", "wu", 3, false);
    tenyear_xiaoqiao->addSkill(new TenyearTianxiang);
    tenyear_xiaoqiao->addSkill("hongyan");

    General *tenyear_pangde = new General(this, "tenyear_pangde", "qun", 4);
    tenyear_pangde->addSkill(new TenyearJianchu);
    tenyear_pangde->addSkill("mashu");

    General *tenyear_masu = new General(this, "tenyear_masu", "shu", 3);
    tenyear_masu->addSkill(new TenyearSanyao);
    tenyear_masu->addSkill(new TenyearZhiman);

    General *tenyear_yujin = new General(this, "tenyear_yujin", "wei", 4);
    tenyear_yujin->addSkill(new TenyearZhenjun);
    tenyear_yujin->addSkill(new FakeMoveSkill("tenyearzhenjun"));
    related_skills.insertMulti("tenyearzhenjun", "#tenyearzhenjun-fake-move");

    General *tenyear_guohuai = new General(this, "tenyear_guohuai", "wei", 4);
    tenyear_guohuai->addSkill(new TenyearJingce);
    tenyear_guohuai->addSkill(new TenyearJingceRecord);
    related_skills.insertMulti("tenyearjingce", "#tenyearjingce-record");

    General *tenyear_liaohua = new General(this, "tenyear_liaohua", "shu", 4);
    tenyear_liaohua->addSkill(new TenyearDangxian);
    tenyear_liaohua->addSkill(new TenyearFuli);

    General *tenyear_chengpu = new General(this, "tenyear_chengpu", "wu", 4);
    tenyear_chengpu->addSkill("lihuo");
    tenyear_chengpu->addSkill(new TenyearChunlao);

    General *tenyear_caozhang = new General(this, "tenyear_caozhang", "wei", 4);
    tenyear_caozhang->addSkill(new TenyearJiangchi);

    General *tenyear_zhangyi = new General(this, "tenyear_zhangyi", "shu", 4);
    tenyear_zhangyi->addSkill(new TenyearWurong);
    tenyear_zhangyi->addSkill("shizhi");

    General *tenyear_quancong = new General(this, "tenyear_quancong", "wu", 4);
    tenyear_quancong->addSkill(new TenyearYaoming);

    General *tenyear_zhuran = new General(this, "tenyear_zhuran", "wu", 4);
    tenyear_zhuran->addSkill(new TenyearDanshou);
    tenyear_zhuran->addSkill(new TenyearDanshouRecord);
    related_skills.insertMulti("tenyeardanshou", "#tenyeardanshou-record");

    General *tenyear_sunluban = new General(this, "tenyear_sunluban", "wu", 3, false);
    tenyear_sunluban->addSkill(new TenyearZenhui);
    tenyear_sunluban->addSkill(new TenyearJiaojin);

    General *tenyear_wuyi = new General(this, "tenyear_wuyi", "shu", 4);
    tenyear_wuyi->addSkill(new TenyearBenxi);

    General *tenyear_panfeng = new General(this, "tenyear_panfeng", "qun", 4);
    tenyear_panfeng->addSkill(new TenyearKuangfu);
    tenyear_panfeng->addSkill(new SlashNoDistanceLimitSkill("tenyearkuangfu"));
    related_skills.insertMulti("tenyearkuangfu", "#tenyearkuangfu-slash-ndl");

    General *tenyear_xusheng = new General(this, "tenyear_xusheng", "wu", 4);
    tenyear_xusheng->addSkill(new TenyearPojun);
    tenyear_xusheng->addSkill(new FakeMoveSkill("tenyearpojun"));
    related_skills.insertMulti("tenyearpojun", "#tenyearpojun-fake-move");

    General *tenyear_madai = new General(this, "tenyear_madai", "shu", 4);
    tenyear_madai->addSkill(new TenyearQianxi);
    tenyear_madai->addSkill(new TenyearQianxiClear);
    tenyear_madai->addSkill("mashu");
    related_skills.insertMulti("tenyearqianxi", "#tenyearqianxi-clear");

    General *tenyear_xuhuang = new General(this, "tenyear_xuhuang", "wei", 4);
    tenyear_xuhuang->addSkill(new TenyearDuanliang);
    tenyear_xuhuang->addSkill(new TenyearDuanliangTargetMod);
    tenyear_xuhuang->addSkill(new TenyearJiezi);
    related_skills.insertMulti("tenyearduanliang", "#tenyearduanliang-target");

    General *tenyear_zhuzhi = new General(this, "tenyear_zhuzhi", "wu", 4);
    tenyear_zhuzhi->addSkill(new TenyearAnguo);

    General *tenyear_sunhao = new General(this, "tenyear_sunhao$", "wu", 5);
    tenyear_sunhao->addSkill(new TenyearCanshi);
    tenyear_sunhao->addSkill(new TenyearChouhai);
    tenyear_sunhao->addSkill("guiming");

    addMetaObject<TenyearZhihengCard>();
    addMetaObject<TenyearJieyinCard>();
    addMetaObject<TenyearRendeCard>();
    addMetaObject<TenyearYijueCard>();
    addMetaObject<TenyearQingjianCard>();
    addMetaObject<TenyearQingnangCard>();
    addMetaObject<TenyearQimouCard>();
    addMetaObject<TenyearShensuCard>();
    addMetaObject<TenyearJushouCard>();
    addMetaObject<TenyearTianxiangCard>();
    addMetaObject<TenyearSanyaoCard>();
    addMetaObject<TenyearChunlaoCard>();
    addMetaObject<TenyearChunlaoWineCard>();
    addMetaObject<TenyearJiangchiCard>();
    addMetaObject<TenyearWurongCard>();
    addMetaObject<TenyearDanshouCard>();
    addMetaObject<TenyearKuangfuCard>();
    addMetaObject<TenyearAnguoCard>();
}

ADD_PACKAGE(JXTP)

