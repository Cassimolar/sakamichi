#include "mobilejxtp.h"
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
#include "yjcm2013.h"
#include "yjcm2014.h"
#include "json.h"

class MobileLiyong : public TriggerSkill
{
public:
    MobileLiyong() : TriggerSkill("mobileliyong")
    {
        events << SlashMissed << TargetSpecified << ConfirmDamage << Damage;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == SlashMissed) {
            if (player->getPhase() != Player::Play || !player->hasSkill(this)) return false;
            room->setPlayerMark(player, "&mobileliyong-PlayClear", 1);
        } else if (event == TargetSpecified) {
            if (player->getPhase() != Player::Play || player->getMark("&mobileliyong-PlayClear") <= 0) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            room->setPlayerMark(player, "&mobileliyong-PlayClear", 0);

            if (use.to.isEmpty()) return false;
            LogMessage log;
            log.type = "#MobileliyongSkillInvalidity";
            log.from = player;
            log.to = use.to;
            log.arg = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(player, objectName());

            use.no_respond_list << "_ALL_TARGETS";
            room->setCardFlag(use.card, "mobileliyong_damage");

            foreach (ServerPlayer *p, use.to) {
                if (p->isDead()) continue;
                p->addMark("mobileliyong");
                room->addPlayerMark(p, "@skill_invalidity");
            }
            data = QVariant::fromValue(use);
        } else if (event == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card->isKindOf("Slash") || !damage.card->hasFlag("mobileliyong_damage")) return false;
            ++damage.damage;
            data = QVariant::fromValue(damage);
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card->isKindOf("Slash") || !damage.card->hasFlag("mobileliyong_damage")) return false;
            if (damage.to->isDead()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->loseHp(player);
        }
        return false;
    }
};

class MobileLiyongClear : public TriggerSkill
{
public:
    MobileLiyongClear() : TriggerSkill("#mobileliyong-clear")
    {
        events << EventPhaseChanging << Death;
        frequency = Compulsory;
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
            if (death.who != target || target->getPhase() != Player::Play)
                return false;
        }
        QList<ServerPlayer *> players = room->getAllPlayers();
        foreach (ServerPlayer *player, players) {
            if (player->getMark("mobileliyong") == 0) continue;
            room->removePlayerMark(player, "@skill_invalidity", player->getMark("mobileliyong"));
            player->setMark("mobileliyong", 0);

            foreach(ServerPlayer *p, room->getAllPlayers())
                room->filterCards(p, p->getCards("he"), false);
            JsonArray args;
            args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
        }
        return false;
    }
};

MobileQingjianCard::MobileQingjianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void MobileQingjianCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "mobileqingjian", QString());
    effect.from->getRoom()->obtainCard(effect.to, this, reason, false);
}

class MobileQingjianVS : public ViewAsSkill
{
public:
    MobileQingjianVS() : ViewAsSkill("mobileqingjian")
    {
        expand_pile = "mobileqingjian";
        response_pattern = "@@mobileqingjian!";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return Self->getPile("mobileqingjian").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        MobileQingjianCard *c = new MobileQingjianCard;
        c->addSubcards(cards);
        return c;
    }
};

class MobileQingjian : public TriggerSkill
{
public:
    MobileQingjian() : TriggerSkill("mobileqingjian")
    {
        events << EventPhaseChanging;
        view_as_skill = new MobileQingjianVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || p->getPile("mobileqingjian").isEmpty()) continue;
            while (!p->getPile("mobileqingjian").isEmpty()) {
                if (p->isDead()) break;
                if (!room->askForUseCard(p, "@@mobileqingjian!", "@mobileqingjian")) {
                    ServerPlayer *target = room->getOtherPlayers(p).at(qrand() % room->getOtherPlayers(p).length());
                    LogMessage log;
                    log.type = "#ChoosePlayerWithSkill";
                    log.from = p;
                    log.to << target;
                    log.arg = "mobileqingjian";
                    room->sendLog(log);
                    room->notifySkillInvoked(p, "mobileqingjian");
                    room->broadcastSkillInvoke(objectName());
                    room->doAnimate(1, p->objectName(), target->objectName());
                    DummyCard *dummy = new DummyCard(p->getPile("mobileqingjian"));
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, p->objectName(), target->objectName(), "mobileqingjian", QString());
                    room->obtainCard(target, dummy, reason, false);
                    delete dummy;
                }
            }
            if (p->isAlive() && p->getMark("mobileqingjian_num-Clear") > 1)
                p->drawCards(1, objectName());
        }
        return false;
    }
};

class MobileQingjianPut : public TriggerSkill
{
public:
    MobileQingjianPut() : TriggerSkill("#mobileqingjian-put")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!room->getTag("FirstRound").toBool() && player->getPhase() != Player::Draw && move.to == player && move.to_place == Player::PlaceHand) {
            if (!room->hasCurrent()) return false;
            if (player->isKongcheng() || player->getMark("mobileqingjian-Clear") > 0) return false;
            const Card *c = room->askForExchange(player, "mobileqingjian", 99999, 1, false, "@mobileqingjian-put", true);
            if (!c) return false;
            room->addPlayerMark(player, "mobileqingjian-Clear");
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = "mobileqingjian";
            room->sendLog(log);
            room->notifySkillInvoked(player, "mobileqingjian");
            room->broadcastSkillInvoke("mobileqingjian");
            player->addToPile("mobileqingjian", c);
        } else if (move.from == player && move.from_places.contains(Player::PlaceSpecial) && move.from_pile_names.contains("mobileqingjian")
                   && move.reason.m_reason == CardMoveReason::S_REASON_GIVE && move.reason.m_skillName == "mobileqingjian") {
            int length = 0;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::PlaceSpecial && move.from_pile_names.at(i) == "mobileqingjian")
                    length++;
            }
            if (length <= 0) return false;
            room->addPlayerMark(player, "mobileqingjian_num-Clear", length);
        }
        return false;
    }
};

class MobileFenji : public TriggerSkill
{
public:
    MobileFenji() : TriggerSkill("mobilefenji")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
            if (player->isDead()) return false;
            if (p->isDead() || !player->isKongcheng()) continue;
            if (!p->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
            room->broadcastSkillInvoke(objectName());
            player->drawCards(2, objectName());
            room->loseHp(p);
        }

        return false;
    }
};

MobileQiangxiCard::MobileQiangxiCard()
{
}

bool MobileQiangxiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self)
        return false;

    int rangefix = 0;
    if (!subcards.isEmpty() && Self->getWeapon() && Self->getWeapon()->getId() == subcards.first()) {
        const Weapon *card = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
        rangefix += card->getRange() - Self->getAttackRange(false);
    }

    return Self->inMyAttackRange(to_select, rangefix) && to_select->getMark("mobileqiangxi_used-PlayClear") <= 0;
}

void MobileQiangxiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    room->addPlayerMark(effect.to, "mobileqiangxi_used-PlayClear");

    if (subcards.isEmpty())
        room->loseHp(effect.from);

    room->damage(DamageStruct("mobileqiangxi", effect.from, effect.to));
}

class MobileQiangxi : public ViewAsSkill
{
public:
    MobileQiangxi() : ViewAsSkill("mobileqiangxi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        foreach (const Player *p, player->getAliveSiblings()) {
            if (player->inMyAttackRange(p) && p->getMark("mobileqiangxi_used-PlayClear") <= 0)
                return true;
        }
        return false;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.isEmpty() && to_select->isKindOf("Weapon") && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return new MobileQiangxiCard;
        else if (cards.length() == 1) {
            MobileQiangxiCard *card = new MobileQiangxiCard;
            card->addSubcards(cards);

            return card;
        } else
            return NULL;
    }
};

class MobileJieming : public MasochismSkill
{
public:
    MobileJieming() : MasochismSkill("mobilejieming")
    {
    }

    void onDamaged(ServerPlayer *xunyu, const DamageStruct &damage) const
    {
        Room *room = xunyu->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            ServerPlayer *to = room->askForPlayerChosen(xunyu, room->getAlivePlayers(), objectName(), "@mobilejieming-invoke", true, true);
            if (!to) break;
            room->broadcastSkillInvoke(objectName());
            to->drawCards(2, objectName());
            if (to->getHandcardNum() < to->getMaxHp() && xunyu->isAlive())
                xunyu->drawCards(1, objectName());
            if (!xunyu->isAlive())
                break;
        }
    }
};

MobileNiepanCard::MobileNiepanCard()
{
    target_fixed = true;
}

void MobileNiepanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->doSuperLightbox("mobile_pangtong", "mobileniepan");

    room->removePlayerMark(source, "@mobileniepanMark");

    source->throwAllHandCardsAndEquips();
    QList<const Card *> tricks = source->getJudgingArea();
    foreach (const Card *trick, tricks) {
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, source->objectName());
        room->throwCard(trick, reason, NULL);
    }

    source->drawCards(3, objectName());

    int n = qMin(3 - source->getHp(), source->getMaxHp() - source->getHp());
    if (n > 0)
        room->recover(source, RecoverStruct(source, NULL, n));

    if (source->isChained())
        room->setPlayerChained(source);

    if (!source->faceUp())
        source->turnOver();
}

class MobileNiepanVS : public ZeroCardViewAsSkill
{
public:
    MobileNiepanVS() : ZeroCardViewAsSkill("mobileniepan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@mobileniepanMark") > 0;
    }

    const Card *viewAs() const
    {
        return new MobileNiepanCard;
    }
};

class MobileNiepan : public TriggerSkill
{
public:
    MobileNiepan() : TriggerSkill("mobileniepan")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@mobileniepanMark";
        view_as_skill = new MobileNiepanVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getMark("@mobileniepanMark") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *pangtong, QVariant &data) const
    {
        DyingStruct dying_data = data.value<DyingStruct>();
        if (dying_data.who != pangtong)
            return false;

        if (pangtong->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("mobile_pangtong", "mobileniepan");

            room->removePlayerMark(pangtong, "@mobileniepanMark");

            pangtong->throwAllHandCardsAndEquips();
            QList<const Card *> tricks = pangtong->getJudgingArea();
            foreach (const Card *trick, tricks) {
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, pangtong->objectName());
                room->throwCard(trick, reason, NULL);
            }

            pangtong->drawCards(3, objectName());

            int n = qMin(3 - pangtong->getHp(), pangtong->getMaxHp() - pangtong->getHp());
            if (n > 0)
                room->recover(pangtong, RecoverStruct(pangtong, NULL, n));

            if (pangtong->isChained())
                room->setPlayerProperty(pangtong, "chained", false);

            if (!pangtong->faceUp())
                pangtong->turnOver();

        }
        return false;
    }
};

class MobileShuangxiongVS : public OneCardViewAsSkill
{
public:
    MobileShuangxiongVS() : OneCardViewAsSkill("mobileshuangxiong")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("mobileshuangxiong-Clear") != 0;
    }

    bool viewFilter(const Card *card) const
    {
        if (card->isEquipped())
            return false;
        int red = Self->getMark("mobileshuangxiong_red-Clear");
        int black = Self->getMark("mobileshuangxiong_black-Clear");
        int nosuit = Self->getMark("mobileshuangxiong_nosuit-Clear");
        if (red > 0 && black > 0 && nosuit > 0) return false;
        if (red > 0 && black > 0) return card->getSuit() == Card::NoSuit;
        if (red > 0 && nosuit > 0) return card->isBlack();
        if (black > 0 && nosuit > 0) return card->isRed();
        if (red > 0) return !card->isRed();
        if (black > 0) return !card->isBlack();
        if (nosuit > 0) return card->getSuit() != Card::NoSuit;
        return true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Duel *duel = new Duel(originalCard->getSuit(), originalCard->getNumber());
        duel->addSubcard(originalCard);
        duel->setSkillName("mobileshuangxiong");
        return duel;
    }
};

class MobileShuangxiong : public TriggerSkill
{
public:
    MobileShuangxiong() : TriggerSkill("mobileshuangxiong")
    {
        events << EventPhaseStart << Damaged << EventPhaseChanging;
        view_as_skill = new MobileShuangxiongVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Draw) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "mobileshuangxiong-Clear");
            QList<int> ids = room->getNCards(2, false);
            room->returnToTopDrawPile(ids);
            LogMessage log;
            log.type = "$TurnOver";
            log.from = player;
            log.card_str = IntList2StringList(ids).join("+");
            room->sendLog(log);
            room->fillAG(ids);
            int id = room->askForAG(player, ids, false, objectName());
            room->clearAG();
            room->obtainCard(player, id, true);
            const Card *card = Sanguosha->getCard(id);
            if (card->isRed()) {
                room->addPlayerMark(player, "mobileshuangxiong_red-Clear");
            } else if (card->isBlack()) {
                room->addPlayerMark(player, "mobileshuangxiong_black-Clear");
            } else
                room->addPlayerMark(player, "mobileshuangxiong_nosuit-Clear");
            return true;
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            room->setPlayerProperty(player, "mobileshuangxiong", QString());
        } else if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.from || !damage.card->isKindOf("Duel") || damage.card->getSkillName() != "mobileshuangxiong") return false;
            QVariantList slash_list = damage.from->tag["DuelSlash" + damage.card->toString()].toList();
            QList<int> get;
            foreach (int id, VariantList2IntList(slash_list)) {
                if (room->getCardPlace(id) == Player::DiscardPile)
                    get << id;
            }
            if (get.isEmpty()) return false;
            if (!player->askForSkillInvoke(this, QString("mobileshuangxiong_invoke:%1").arg(damage.from->objectName()))) return false;
            room->broadcastSkillInvoke(objectName());
            DummyCard *dummy = new DummyCard(get);
            room->obtainCard(player, dummy);
            delete dummy;
        }
        return false;
    }
};

class MobileLuanjiVS : public ViewAsSkill
{
public:
    MobileLuanjiVS() : ViewAsSkill("mobileluanji")
    {
        response_or_use = true;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QStringList suits = Self->property("mobileluanji_suitstring").toString().split("+");
        if (selected.isEmpty() || selected.length() == 1)
            return !to_select->isEquipped() && !suits.contains(to_select->getSuitString());
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

class MobileLuanji : public TriggerSkill
{
public:
    MobileLuanji() : TriggerSkill("mobileluanji")
    {
        events << PreCardUsed << EventPhaseChanging << CardResponded << CardFinished << PreDamageDone;
        view_as_skill = new MobileLuanjiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("ArcheryAttack") || use.card->getSkillName() != "mobileluanji") return false;
            if (!use.card->isVirtualCard() || use.card->getSubcards().isEmpty()) return false;
            QStringList suits = player->property("mobileluanji_suitstring").toString().split("+");
            foreach (int id, use.card->getSubcards()) {
                const Card *card = Sanguosha->getCard(id);
                if (!suits.contains(card->getSuitString()))
                    suits << card->getSuitString();
            }
            room->setPlayerProperty(player, "mobileluanji_suitstring", suits.join("+"));
        } else if (event == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive)
                room->setPlayerProperty(player, "mobileluanji_suitstring", QStringList());
        } else if (event == CardResponded) {
            CardResponseStruct res = data.value<CardResponseStruct>();
            const Card *card = res.m_card;
            if (!card->isKindOf("Jink")) return false;
            const Card *tocard = res.m_toCard;
            if (!tocard || !tocard->isKindOf("ArcheryAttack")) return false;
            ServerPlayer *who = res.m_who;
            if (!who->hasSkill(this) || player->isDead()) return false;
            player->drawCards(1, objectName());
        } else if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("ArcheryAttack")) return false;
            if (use.card->hasFlag("mobileluanji_damage")) {
                room->setCardFlag(use.card, "-mobileluanji_damage");
                return false;
            }
            if (use.to.length() > 0 && player->hasSkill(this)) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                player->drawCards(use.to.length(), objectName());
            }
        } else if (event == PreDamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("ArcheryAttack") || !damage.from || !damage.by_user) return false;
            room->setCardFlag(damage.card, "mobileluanji_damage");
        }
        return false;
    }
};

MobileZaiqiCard::MobileZaiqiCard()
{
}

bool MobileZaiqiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    return targets.length() < Self->getMark("mobilezaiqi-Clear");
}

void MobileZaiqiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead()) return;
    QStringList choices;
    choices << "draw";
    if (effect.from->isAlive() && effect.from->isWounded())
        choices << "recover=" + effect.from->objectName();
    Room *room = effect.from->getRoom();
    QString choice = room->askForChoice(effect.to, "mobilezaiqi", choices.join("+"), QVariant::fromValue(effect.from));
    if (choice == "draw")
        effect.to->drawCards(1, "mobilezaiqi");
    else {
        room->recover(effect.from, RecoverStruct(effect.to));
    }
}

class MobileZaiqiVS : public ZeroCardViewAsSkill
{
public:
    MobileZaiqiVS() : ZeroCardViewAsSkill("mobilezaiqi")
    {
        response_pattern = "@@mobilezaiqi";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new MobileZaiqiCard;
    }
};

class MobileZaiqi : public TriggerSkill
{
public:
    MobileZaiqi() : TriggerSkill("mobilezaiqi")
    {
        events << CardsMoveOneTime << EventPhaseEnd;
        view_as_skill = new MobileZaiqiVS;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            if (!room->getCurrent() || room->getCurrent()->getPhase() == Player::NotActive) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to_place != Player::DiscardPile) return false;
            foreach (int id, move.card_ids) {
                if (Sanguosha->getCard(id)->isRed())
                    room->addPlayerMark(player, "mobilezaiqi-Clear");
            }
        } else {
            if (player->isDead() || !player->hasSkill(this) || player->getPhase() != Player::Discard) return false;
            int n = player->getMark("mobilezaiqi-Clear");
            if (n <= 0) return false;
            room->askForUseCard(player, "@@mobilezaiqi", "@mobilezaiqi:" + QString::number(n));
        }

        return false;
    }
};

class MobileLieren : public TriggerSkill
{
public:
    MobileLieren() : TriggerSkill("mobilelieren")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead()) break;
            if (p->isDead() || !player->canPindian(p) || !player->askForSkillInvoke(this, QVariant::fromValue(p))) continue;
            room->broadcastSkillInvoke(objectName());
            PindianStruct *pindian = player->PinDian(p, "mobilelieren", NULL);
            if (!pindian) return false;
            if (pindian->from_number > pindian->to_number) {
                if (p->isNude()) continue;
                int card_id = room->askForCardChosen(player, p, "he", objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
            } else {
                if (p->isDead()) continue;
                int from_id = pindian->from_card->getEffectiveId();
                int to_id = pindian->to_card->getEffectiveId();
                if (room->getCardPlace(from_id) != Player::DiscardPile || room->getCardPlace(to_id) != Player::DiscardPile) continue;
                QList<CardsMoveStruct> exchangeMove;
                QList<int> from_ids, to_ids;
                from_ids << from_id;
                to_ids << to_id;
                CardsMoveStruct move1(to_ids, player, Player::PlaceHand,
                    CardMoveReason(CardMoveReason::S_REASON_SWAP, player->objectName(), p->objectName(), "mobilelieren", QString()));
                CardsMoveStruct move2(from_ids, p, Player::PlaceHand,
                    CardMoveReason(CardMoveReason::S_REASON_SWAP, p->objectName(), player->objectName(), "mobilelieren", QString()));
                exchangeMove.push_back(move1);
                exchangeMove.push_back(move2);
                room->moveCardsAtomic(exchangeMove, true);
            }
        }
        return false;
    }
};

class MobileXingshang : public TriggerSkill
{
public:
    MobileXingshang() : TriggerSkill("mobilexingshang")
    {
        events << Death;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *caopi, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        ServerPlayer *player = death.who;
        if (caopi == player) return false;
        QStringList choices;
        if (!player->isNude())
            choices << "get";
        if (caopi->getLostHp() > 0)
            choices << "recover";
        if (choices.isEmpty()) return false;
        if (caopi->isAlive() && room->askForSkillInvoke(caopi, objectName(), data)) {
            room->broadcastSkillInvoke(objectName());
            QString choice = room->askForChoice(caopi, objectName(), choices.join("+"), data);
            if (choice == "get") {
                DummyCard *dummy = new DummyCard(player->handCards());
                QList <const Card *> equips = player->getEquips();
                foreach(const Card *card, equips)
                    dummy->addSubcard(card);

                if (dummy->subcardsLength() > 0) {
                    CardMoveReason reason(CardMoveReason::S_REASON_RECYCLE, caopi->objectName());
                    room->obtainCard(caopi, dummy, reason, false);
                }
                delete dummy;
            } else {
                room->recover(caopi, RecoverStruct(caopi));
            }
        }
        return false;
    }
};

class MobileFangzhu : public MasochismSkill
{
public:
    MobileFangzhu() : MasochismSkill("mobilefangzhu")
    {
    }

    void onDamaged(ServerPlayer *caopi, const DamageStruct &) const
    {
        Room *room = caopi->getRoom();
        ServerPlayer *to = room->askForPlayerChosen(caopi, room->getOtherPlayers(caopi), objectName(),
            "@mobilefangzhu-invoke", caopi->getMark("JilveEvent") != int(Damaged), true);
        if (to) {
            if (caopi->hasInnateSkill("fangzhu") || !caopi->hasSkill("jilve")) {
                room->broadcastSkillInvoke("mobilefangzhu");
            } else
                room->broadcastSkillInvoke("jilve", 2);

            int losthp = caopi->getLostHp();
            if (losthp <= 0) {
                QString choice = room->askForChoice(to, objectName(), "turnover+losehp");
                if (choice == "turnover")
                    to->turnOver();
                else
                    room->loseHp(to);
                return;
            }

            int candis = 0;
            foreach (const Card *c, to->getCards("he")) {
                if (to->canDiscard(to, c->getEffectiveId()))
                    candis++;
            }
            if (candis < losthp) {
                to->drawCards(losthp, objectName());
                to->turnOver();
            } else {
                if (room->askForDiscard(to, objectName(), losthp, losthp, true, true, "mobilefangzhu-discard:" + QString::number(losthp))) {
                    room->loseHp(to);
                    return;
                }
                to->drawCards(losthp, objectName());
                to->turnOver();
            }
        }
    }
};

MobilePoluCard::MobilePoluCard()
{
}

bool MobilePoluCard::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const
{
    if (Self->isDead())
        return to_select != Self;
    return true;
}

void MobilePoluCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->addPlayerMark(source, "mobilepolu_usedtimes");
    int mark = source->getMark("mobilepolu_usedtimes");
    room->drawCards(targets, mark, "mobilepolu");
}

class MobilePoluVS : public ZeroCardViewAsSkill
{
public:
    MobilePoluVS() : ZeroCardViewAsSkill("mobilepolu")
    {
        response_pattern = "@@mobilepolu";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new MobilePoluCard;
    }
};

class MobilePolu : public TriggerSkill
{
public:
    MobilePolu() : TriggerSkill("mobilepolu")
    {
        events << Death;
        view_as_skill = new MobilePoluVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        int n = 0;
        if (death.who == player && player->hasSkill(this))
            n++;
        if (death.damage && death.damage->from && death.damage->from == player && player->hasSkill(this))//&& player->isAlive()
            n++;
        if (n == 0) return false;
        for (int i = 1; i <= n; i++) {
            int mark = player->getMark("mobilepolu_usedtimes");
            if (!room->askForUseCard(player, "@@mobilepolu", "@mobilepolu:" + QString::number(mark + 1))) break;
        }
        return false;
    }
};

class MobileJiuchiVS : public OneCardViewAsSkill
{
public:
    MobileJiuchiVS() : OneCardViewAsSkill("mobilejiuchi")
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

class MobileJiuchi : public TriggerSkill
{
public:
    MobileJiuchi() : TriggerSkill("mobilejiuchi")
    {
        events << Damage;
        view_as_skill = new MobileJiuchiVS;
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
                room->notifySkillInvoked(player, "mobilejiuchi");
                room->broadcastSkillInvoke("mobilejiuchi");
            }
            room->addPlayerMark(player, "benghuai_nullification-Clear");
        }
        return false;
    }
};

class MobileTuntian : public TriggerSkill
{
public:
    MobileTuntian() : TriggerSkill("mobiletuntian")
    {
        events << CardsMoveOneTime << FinishJudge;
        frequency = Frequent;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getPhase() == Player::NotActive;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                && !(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip))
                && player->askForSkillInvoke("mobiletuntian", data)) {
                room->broadcastSkillInvoke("mobiletuntian");
                JudgeStruct judge;
                judge.pattern = ".|heart";
                judge.good = false;
                judge.reason = "mobiletuntian";
                judge.who = player;
                room->judge(judge);
            }
        } else if (triggerEvent == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == "mobiletuntian" && judge->isGood() && room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge)
                player->addToPile("field", judge->card->getEffectiveId());
            else if (judge->reason == "mobiletuntian" && !judge->isGood() && room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge)
                room->obtainCard(player, judge->card, true);
        }
        return false;
    }
};

class MobileTuntianDistance : public DistanceSkill
{
public:
    MobileTuntianDistance() : DistanceSkill("#mobiletuntian-dist")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill("mobiletuntian"))
            return -from->getPile("field").length();
        else
            return 0;
    }
};

MobileTiaoxinCard::MobileTiaoxinCard()
{
}

void MobileTiaoxinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    bool use_slash = false;
    if (effect.to->canSlash(effect.from, NULL, false))
        use_slash = room->askForUseSlashTo(effect.to, effect.from, "@mobiletiaoxin-slash:" + effect.from->objectName());
    if (!use_slash && effect.from->canDiscard(effect.to, "he"))
        room->throwCard(room->askForCardChosen(effect.from, effect.to, "he", "mobiletiaoxin", false, Card::MethodDiscard), effect.to, effect.from);
}

class MobileTiaoxin : public ZeroCardViewAsSkill
{
public:
    MobileTiaoxin() : ZeroCardViewAsSkill("mobiletiaoxin")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileTiaoxinCard");
    }

    const Card *viewAs() const
    {
        return new MobileTiaoxinCard;
    }
};

class MobileZhiji : public PhaseChangeSkill
{
public:
    MobileZhiji() : PhaseChangeSkill("mobilezhiji")
    {
        frequency = Wake;
        waked_skills = "tenyearguanxing";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark("mobilezhiji") > 0) return false;
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

        room->doSuperLightbox("mobile_jiangwei", "mobilezhiji");

        room->setPlayerMark(jiangwei, "mobilezhiji", 1);

        if (jiangwei->isWounded() && room->askForChoice(jiangwei, objectName(), "recover+draw") == "recover")
            room->recover(jiangwei, RecoverStruct(jiangwei));
        else
            room->drawCards(jiangwei, 2, objectName());

        if (room->changeMaxHpForAwakenSkill(jiangwei))
            room->acquireSkill(jiangwei, "tenyearguanxing");
        return false;
    }
};

class MobileHunzi : public PhaseChangeSkill
{
public:
    MobileHunzi() : PhaseChangeSkill("mobilehunzi")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getHp() <= 2) {
            LogMessage log;
            log.type = "#HunziWake";
            log.from = player;
            log.arg = QString::number(player->getHp());
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *sunce) const
    {
        Room *room = sunce->getRoom();
        room->notifySkillInvoked(sunce, objectName());

        room->broadcastSkillInvoke(objectName());

        room->doSuperLightbox("mobile_sunce", "mobilehunzi");

        room->setPlayerMark(sunce, "mobilehunzi", 1);
        if (room->changeMaxHpForAwakenSkill(sunce))
            room->handleAcquireDetachSkills(sunce, "yingzi|yinghun");
        return false;
    }
};

class MobileBeige : public TriggerSkill
{
public:
    MobileBeige() : TriggerSkill("mobilebeige")
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
            if (damage.card == NULL || !damage.card->isKindOf("Slash") || damage.to->isDead())
                return false;

            foreach (ServerPlayer *caiwenji, room->getAllPlayers()) {
                if (!TriggerSkill::triggerable(caiwenji)) continue;
                if (caiwenji->canDiscard(caiwenji, "he") && room->askForCard(caiwenji, "..", "@mobilebeige:" + player->objectName(), data, objectName())) {
                    room->broadcastSkillInvoke(objectName());
                    JudgeStruct judge;
                    judge.good = true;
                    judge.play_animation = false;
                    judge.who = player;
                    judge.reason = objectName();

                    room->judge(judge);

                    Card::Suit suit = (Card::Suit)(judge.pattern.toInt());
                    switch (suit) {
                    case Card::Heart: {
                        int n = qMin(player->getMaxHp() - player->getHp(), damage.damage);
                        if (n > 0)
                            room->recover(player, RecoverStruct(caiwenji, NULL, n));
                        break;
                    }
                    case Card::Diamond: {
                        player->drawCards(3, objectName());
                        break;
                    }
                    case Card::Club: {
                        if (damage.from && damage.from->isAlive())
                            room->askForDiscard(damage.from, "mobilebeige", 2, 2, false, true);
                        break;
                    }
                    case Card::Spade: {
                        if (damage.from && damage.from->isAlive())
                            damage.from->turnOver();

                        break;
                    }
                    default:
                        break;
                    }
                }
            }
        } else {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason != objectName()) return false;
            judge->pattern = QString::number(int(judge->card->getSuit()));
        }
        return false;
    }
};

MobileZhijianCard::MobileZhijianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool MobileZhijianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self)
        return false;

    const Card *card = Sanguosha->getCard(subcards.first());
    const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
    int equip_index = static_cast<int>(equip->location());
    return to_select->getEquip(equip_index) == NULL && !Self->isProhibited(to_select, card);
}

void MobileZhijianCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *erzhang = effect.from;
    erzhang->getRoom()->moveCardTo(this, erzhang, effect.to, Player::PlaceEquip,
        CardMoveReason(CardMoveReason::S_REASON_PUT,
        erzhang->objectName(), "mobilezhijian", QString()));

    LogMessage log;
    log.type = "$ZhijianEquip";
    log.from = effect.to;
    log.card_str = QString::number(getEffectiveId());
    erzhang->getRoom()->sendLog(log);

    erzhang->drawCards(1, "mobilezhijian");
}

class MobileZhijianVS : public OneCardViewAsSkill
{
public:
    MobileZhijianVS() :OneCardViewAsSkill("mobilezhijian")
    {
        filter_pattern = "EquipCard|.|.|hand";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileZhijianCard *zhijian_card = new MobileZhijianCard;
        zhijian_card->addSubcard(originalCard);
        return zhijian_card;
    }
};

class MobileZhijian : public TriggerSkill
{
public:
    MobileZhijian() : TriggerSkill("mobilezhijian")
    {
        events << CardUsed;
        view_as_skill = new MobileZhijianVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("EquipCard") || player->getPhase() != Player::Play) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->drawCards(1, "mobilezhijian");
        return false;
    }
};

MobileFangquanCard::MobileFangquanCard()
{
}

void MobileFangquanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    ServerPlayer *liushan = effect.from, *player = effect.to;

    LogMessage log;
    log.type = "#Fangquan";
    log.from = liushan;
    log.to << player;
    room->sendLog(log);

    room->setTag("MobileFangquanTarget", QVariant::fromValue(player));
}

class MobileFangquanViewAsSkill : public OneCardViewAsSkill
{
public:
    MobileFangquanViewAsSkill() : OneCardViewAsSkill("mobilefangquan")
    {
        filter_pattern = ".|.|.|hand!";
        response_pattern = "@@mobilefangquan";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileFangquanCard *fangquan = new MobileFangquanCard;
        fangquan->addSubcard(originalCard);
        return fangquan;
    }
};

class MobileFangquan : public TriggerSkill
{
public:
    MobileFangquan() : TriggerSkill("mobilefangquan")
    {
        events << EventPhaseChanging << EventPhaseStart;
        view_as_skill = new MobileFangquanViewAsSkill;
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
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *liushan, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            switch (change.to) {
            case Player::Play: {
                bool invoked = false;
                if (!TriggerSkill::triggerable(liushan) || liushan->isSkipped(Player::Play))
                    return false;
                invoked = liushan->askForSkillInvoke(this);
                if (invoked) {
                    room->broadcastSkillInvoke(objectName());
                    liushan->setFlags(objectName());
                    liushan->skip(Player::Play, true);
                }
                break;
            }
            case Player::NotActive: {
                if (liushan->hasFlag(objectName())) {
                    if (!liushan->canDiscard(liushan, "h"))
                        return false;
                    room->askForUseCard(liushan, "@@mobilefangquan", "@mobilefangquan-give", -1, Card::MethodDiscard);
                }
                break;
            }
            default:
                break;
            }
        } else if (triggerEvent == EventPhaseStart && liushan->getPhase() == Player::NotActive) {
            Room *room = liushan->getRoom();
            if (!room->getTag("MobileFangquanTarget").isNull()) {
                ServerPlayer *target = room->getTag("MobileFangquanTarget").value<ServerPlayer *>();
                room->removeTag("MobileFangquanTarget");
                if (target->isAlive())
                    target->gainAnExtraTurn();
            }
        }
        return false;
    }
};

class MobileFangquanMax : public MaxCardsSkill
{
public:
    MobileFangquanMax() : MaxCardsSkill("#mobilefangquan-max")
    {
    }

    int getFixed(const Player *target) const
    {
        if (target->hasFlag("mobilefangquan"))
            return target->getMaxHp();
        else
            return -1;
    }
};

class MobilePojun : public TriggerSkill
{
public:
    MobilePojun() : TriggerSkill("mobilepojun")
    {
        events << TargetSpecified << EventPhaseChanging << DamageCaused;
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
                        t->setFlags("mobilepojun_InTempMoving");

                        for (int i = 0; i < discard_n; ++i) {
                            int id = room->askForCardChosen(player, t, "he", objectName() + "_dis", false, Card::MethodNone);
                            Player::Place place = room->getCardPlace(id);
                            orig_places << place;
                            cards << id;
                            t->addToPile("#mobilepojun", id, false);
                        }

                        for (int i = 0; i < discard_n; ++i)
                            room->moveCardTo(Sanguosha->getCard(cards.value(i)), t, orig_places.value(i), false);

                        t->setFlags("-mobilepojun_InTempMoving");
                        Config.AIDelay = ad;

                        DummyCard dummy(cards);
                        t->addToPile("mobilepojun", &dummy, false, QList<ServerPlayer *>() << t);

                        // for record
                        if (!t->tag.contains("mobilepojun") || !t->tag.value("mobilepojun").canConvert(QVariant::Map))
                            t->tag["mobilepojun"] = QVariantMap();

                        QVariantMap vm = t->tag["mobilepojun"].toMap();
                        foreach (int id, cards)
                            vm[QString::number(id)] = player->objectName();

                        t->tag["mobilepojun"] = vm;
                    }
                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->tag.contains("mobilepojun")) {
                    QVariantMap vm = p->tag.value("mobilepojun", QVariantMap()).toMap();
                    foreach (ServerPlayer *d, room->getAllPlayers()) {
                        if (vm.values().contains(d->objectName())) {
                            QList<int> to_obtain;
                            foreach (const QString &key, vm.keys()) {
                                if (vm.value(key) == d->objectName())
                                    to_obtain << key.toInt();
                            }

                            DummyCard dummy(to_obtain);
                            room->obtainCard(p, &dummy, false);

                            foreach (int id, to_obtain)
                                vm.remove(QString::number(id));

                            p->tag["mobilepojun"] = vm;
                        }
                    }
                }
            }
        } else if (triggerEvent == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.from->hasSkill(this) || damage.to->isDead()) return false;
            if (!damage.card || !damage.card->isKindOf("Slash") || !damage.by_user) return false;
            if (damage.from->getHandcardNum() < damage.to->getHandcardNum()) return false;
            if (damage.from->getEquips().length() < damage.to->getEquips().length()) return false;
            LogMessage log;
            log.type = "#MobilepojunDamage";
            log.from = damage.from;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);

            room->notifySkillInvoked(damage.from, objectName());
            room->broadcastSkillInvoke(objectName());

            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

MobileGanluCard::MobileGanluCard()
{
}

void MobileGanluCard::swapEquip(ServerPlayer *first, ServerPlayer *second) const
{
    Room *room = first->getRoom();

    QList<int> equips1, equips2;
    foreach(const Card *equip, first->getEquips())
        equips1.append(equip->getId());
    foreach(const Card *equip, second->getEquips())
        equips2.append(equip->getId());

    QList<CardsMoveStruct> exchangeMove;
    CardsMoveStruct move1(equips1, second, Player::PlaceEquip,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, first->objectName(), second->objectName(), "mobileganlu", QString()));
    CardsMoveStruct move2(equips2, first, Player::PlaceEquip,
        CardMoveReason(CardMoveReason::S_REASON_SWAP, second->objectName(), first->objectName(), "mobileganlu", QString()));
    exchangeMove.push_back(move2);
    exchangeMove.push_back(move1);
    room->moveCardsAtomic(exchangeMove, false);
}

bool MobileGanluCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

bool MobileGanluCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.isEmpty())
        return true;
    else if (targets.length() == 1) {
        int n1 = targets.first()->getEquips().length();
        int n2 = to_select->getEquips().length();
        return qAbs(n1 - n2) <= Self->getLostHp() || targets.first() == Self || to_select == Self;
    }
    return false;
}

void MobileGanluCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    LogMessage log;
    log.type = "#GanluSwap";
    log.from = source;
    log.to = targets;
    room->sendLog(log);

    swapEquip(targets.first(), targets[1]);
}

class MobileGanlu : public ZeroCardViewAsSkill
{
public:
    MobileGanlu() : ZeroCardViewAsSkill("mobileganlu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileGanluCard");
    }

    const Card *viewAs() const
    {
        return new MobileGanluCard;
    }
};

MobileJieyueCard::MobileJieyueCard()
{
    mute = true;
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void MobileJieyueCard::onUse(Room *, const CardUseStruct &) const
{
}

class MobileJieyueVS : public ViewAsSkill
{
public:
    MobileJieyueVS() : ViewAsSkill("mobilejieyue")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.isEmpty()) return true;
        if (selected.length() == 1) {
            if (Self->getHandcards().contains(selected.first()) && !Self->getEquips().isEmpty())
                return to_select->isEquipped();
            else if (Self->getEquips().contains(selected.first()) && !Self->isKongcheng())
                return !to_select->isEquipped();
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        int x = 0;
        if (!Self->isKongcheng())
            x++;
        if (!Self->getEquips().isEmpty())
            x++;
        if (cards.length() != x) return NULL;

        MobileJieyueCard *c = new MobileJieyueCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@mobilejieyue";
    }
};

class MobileJieyue : public PhaseChangeSkill
{
public:
    MobileJieyue() : PhaseChangeSkill("mobilejieyue")
    {
        view_as_skill = new MobileJieyueVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (player->isNude()) return false;

        Room *room = player->getRoom();
        QList<int> list = player->handCards() + player->getEquipsId();
        ServerPlayer *target = room->askForYiji(player, list, objectName(), false, false, true, 1,
                     room->getOtherPlayers(player), CardMoveReason(), "mobilejieyue-invoke", true);
        if (!target || target->isDead()) return false;

        if (target->isNude()) {
            player->drawCards(3, objectName());
            return false;
        }

        const Card *card = room->askForUseCard(target, "@@mobilejieyue", "@mobilejieyue:" + player->objectName());
        if (card) {
            DummyCard *dummy = new DummyCard;
            QList<int> ids = card->getSubcards();
            foreach (int id, target->handCards() + target->getEquipsId()) {
                if (ids.contains(id)) continue;
                if (!target->canDiscard(target, id)) continue;
                dummy->addSubcard(id);
            }
            if (dummy->subcardsLength() > 0)
                room->throwCard(dummy, target, NULL);
            delete dummy;
        } else {
            player->drawCards(3, objectName());
        }
        return false;
    }
};

class MobileDangxian : public PhaseChangeSkill
{
public:
    MobileDangxian() : PhaseChangeSkill("mobiledangxian")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (player->getPhase() == Player::RoundStart) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            QList<int> slash;
            foreach (int id, room->getDiscardPile()) {
                if (Sanguosha->getCard(id)->isKindOf("Slash"))
                    slash << id;
            }
            if (!slash.isEmpty())
                room->obtainCard(player, slash.at(qrand() % slash.length()), true);

            if (player->isDead()) return false;

            player->setPhase(Player::Play);
            room->broadcastProperty(player, "phase");
            RoomThread *thread = room->getThread();
            if (!thread->trigger(EventPhaseStart, room, player))
                thread->trigger(EventPhaseProceeding, room, player);
            thread->trigger(EventPhaseEnd, room, player);

            player->setPhase(Player::RoundStart);
            room->broadcastProperty(player, "phase");
        }
        return false;
    }
};

class MobileFuli : public TriggerSkill
{
public:
    MobileFuli() : TriggerSkill("mobilefuli")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@mobilefuliMark";
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
        if (dying_data.who != liaohua || liaohua->getMark("@mobilefuliMark") <= 0) return false;
        if (liaohua->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());

            room->doSuperLightbox("mobile_liaohua", "mobilefuli");

            room->removePlayerMark(liaohua, "@mobilefuliMark");
            int x = getKingdoms(room);
            int n = qMin(x - liaohua->getHp(), liaohua->getMaxHp() - liaohua->getHp());
            if (n > 0)
                room->recover(liaohua, RecoverStruct(liaohua, NULL, n));
            foreach(ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getHp() >= liaohua->getHp())
                    return false;
            }
            liaohua->turnOver();
        }
        return false;
    }
};

MobileAnxuCard::MobileAnxuCard()
{
}

bool MobileAnxuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.isEmpty())
        return to_select != Self;
    if (targets.length() == 1) {
        if (targets.first()->isNude())
            return to_select != Self && !to_select->isNude();
        else
            return to_select != Self;
    }
    return targets.length() < 2;
}

bool MobileAnxuCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void MobileAnxuCard::onUse(Room *room, const CardUseStruct &card_use) const
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

void MobileAnxuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (targets.last()->isNude()) return;

    int id = room->askForCardChosen(targets.first(), targets.last(), "he", "mobileanxu");
    Player::Place place = room->getCardPlace(id);
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, targets.first()->objectName(), "mobileanxu", QString());
    room->obtainCard(targets.first(), Sanguosha->getCard(id), reason, place != Player::PlaceHand);

    if (place != Player::PlaceHand) return;
    source->drawCards(1, "mobileanxu");
}

class MobileAnxuVS : public ZeroCardViewAsSkill
{
public:
    MobileAnxuVS() : ZeroCardViewAsSkill("mobileanxu")
    {
    }

    const Card *viewAs() const
    {
        return new MobileAnxuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileAnxuCard");
    }
};

class MobileAnxu : public TriggerSkill
{
public:
    MobileAnxu() : TriggerSkill("mobileanxu")
    {
        events << CardsMoveOneTime;
        view_as_skill = new MobileAnxuVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from && move.from->isAlive() && move.to && move.to->isAlive() && move.to_place == Player::PlaceHand &&
            move.reason.m_skillName == objectName() && (move.from_places.contains(Player::PlaceEquip) || move.from_places.contains(Player::PlaceHand))) {
            if (move.from->getHandcardNum() == move.to->getHandcardNum()) return false;
            ServerPlayer *from = room->findPlayerByObjectName(move.from->objectName());
            ServerPlayer *to = room->findPlayerByObjectName(move.to->objectName());
            if (!from || from->isDead() || !to || to->isDead()) return false;
            ServerPlayer *less = from;
            if (to->getHandcardNum() < from->getHandcardNum())
                less = to;

            if (!player->askForSkillInvoke(this, QVariant::fromValue(less))) return false;
            room->broadcastSkillInvoke(objectName());
            less->drawCards(1, objectName());
        }
        return false;
    }
};

class MobileZongshi : public PhaseChangeSkill
{
public:
    MobileZongshi() : PhaseChangeSkill("mobilezongshi")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() == Player::Start && player->getHandcardNum() > player->getHp()) {
            Room *room = player->getRoom();
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->addSlashCishu(player, 1000);
        }
        return false;
    }
};

class MobileZongshiKeep : public MaxCardsSkill
{
public:
    MobileZongshiKeep() : MaxCardsSkill("#mobilezongshi-keep")
    {
    }

    int getExtra(const Player *target) const
    {
        int extra = 0;
        QSet<QString> kingdom_set;
        if (target->parent()) {
            foreach(const Player *player, target->parent()->findChildren<const Player *>())
            {
                if (player->isAlive())
                    kingdom_set << player->getKingdom();
            }
        }
        extra = kingdom_set.size();
        if (target->hasSkill("mobilezongshi"))
            return extra;
        else
            return 0;
    }
};

class MobileYicong : public DistanceSkill
{
public:
    MobileYicong() : DistanceSkill("mobileyicong")
    {
    }

    int getCorrect(const Player *from, const Player *to) const
    {
        int correct = 0;
        if (from->hasSkill(this))
            correct = correct + qMin(0, 1 - from->getHp());
        if (to->hasSkill(this))
            correct = correct + qMax(0, to->getLostHp() -1);
        return correct;
    }
};

class MobileXuanfeng : public TriggerSkill
{
public:
    MobileXuanfeng() : TriggerSkill("mobilexuanfeng")
    {
        events << CardsMoveOneTime << EventPhaseEnd << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    void perform(Room *room, ServerPlayer *lingtong) const
    {
        QStringList choices;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *target, room->getOtherPlayers(lingtong)) {
            if (lingtong->canDiscard(target, "he"))
                targets << target;
        }
        if (!targets.isEmpty())
            choices << "discard";
        if (room->canMoveField("e", room->getOtherPlayers(lingtong), room->getOtherPlayers(lingtong)))
            choices << "move";
        if (choices.isEmpty())
            return;

        if (lingtong->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName());
            QString choice = room->askForChoice(lingtong, objectName(), choices.join("+"));

            if (choice == "discard") {
                ServerPlayer *first = room->askForPlayerChosen(lingtong, targets, "mobilexuanfeng");
                room->doAnimate(1, lingtong->objectName(), first->objectName());
                ServerPlayer *second = NULL;
                int first_id = -1;
                int second_id = -1;
                if (first != NULL) {
                    first_id = room->askForCardChosen(lingtong, first, "he", "mobilexuanfeng", false, Card::MethodDiscard);
                    room->throwCard(first_id, first, lingtong);
                }
                if (!lingtong->isAlive())
                    return;
                targets.clear();
                foreach (ServerPlayer *target, room->getOtherPlayers(lingtong)) {
                    if (lingtong->canDiscard(target, "he"))
                        targets << target;
                }
                if (!targets.isEmpty()) {
                    second = room->askForPlayerChosen(lingtong, targets, "mobilexuanfeng");
                    room->doAnimate(1, lingtong->objectName(), second->objectName());
                }
                if (second != NULL) {
                    second_id = room->askForCardChosen(lingtong, second, "he", "mobilexuanfeng", false, Card::MethodDiscard);
                    room->throwCard(second_id, second, lingtong);
                }
            } else {
                if (!room->canMoveField("e", room->getOtherPlayers(lingtong), room->getOtherPlayers(lingtong))) return;
                room->moveField(lingtong, objectName(), false, "e", room->getOtherPlayers(lingtong), room->getOtherPlayers(lingtong));
            }
        }
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *lingtong, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            lingtong->setMark("mobilexuanfeng", 0);
        } else if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from != lingtong)
                return false;

            if (lingtong->getPhase() == Player::Discard
                && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)
                lingtong->addMark("mobilexuanfeng", move.card_ids.length());

            if (move.from_places.contains(Player::PlaceEquip) && TriggerSkill::triggerable(lingtong))
                perform(room, lingtong);
        } else if (triggerEvent == EventPhaseEnd && TriggerSkill::triggerable(lingtong)
            && lingtong->getPhase() == Player::Discard && lingtong->getMark("mobilexuanfeng") >= 2) {
            perform(room, lingtong);
        }

        return false;
    }
};

class MobileJiushiVS : public ZeroCardViewAsSkill
{
public:
    MobileJiushiVS() : ZeroCardViewAsSkill("mobilejiushi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Analeptic::IsAvailable(player) && player->faceUp();
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern.contains("analeptic") && player->faceUp();
    }

    const Card *viewAs() const
    {
        Analeptic *analeptic = new Analeptic(Card::NoSuit, 0);
        analeptic->setSkillName(objectName());
        return analeptic;
    }
};

class MobileJiushi : public TriggerSkill
{
public:
    MobileJiushi() : TriggerSkill("mobilejiushi")
    {
        events << PreCardUsed << PreDamageDone << Damaged << TurnedOver;
        view_as_skill = new MobileJiushiVS;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    void getTrick(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<int> tricks;
        foreach (int id, room->getDrawPile()) {
            if (Sanguosha->getCard(id)->isKindOf("TrickCard"))
                tricks << id;
        }
        if (tricks.isEmpty()) return;
        int id = tricks.at(qrand() % tricks.length());
        room->obtainCard(player, id, true);
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName() == "mobilejiushi")
                player->turnOver();
        } else if (triggerEvent == TurnedOver) {
            if (!player->property("mobilejiushi_levelup").toBool()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            getTrick(player);
        } else if (triggerEvent == Damaged) {
            bool facedown = player->tag.value("MobilePredamagedFace").toBool();
            player->tag.remove("MobilePredamagedFace");
            if (facedown && !player->faceUp() && player->askForSkillInvoke("mobilejiushi", data)) {
                room->broadcastSkillInvoke("mobilejiushi");
                player->turnOver();
                if (player->property("mobilejiushi_levelup").toBool()) return false;
                getTrick(player);
            }
        } else if (triggerEvent == PreDamageDone) {
            player->tag["MobilePredamagedFace"] = !player->faceUp();
        }
        return false;
    }
};

class MobileChengzhang : public PhaseChangeSkill
{
public:
    MobileChengzhang() : PhaseChangeSkill("mobilechengzhang")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        int mark = player->getMark("&mobilechengzhang") + player->getMark("mobilechengzhang_num");
        if (mark < 7) return false;
        LogMessage log;
        log.type = "#MobilechengzhangWake";
        log.from = player;
        log.arg = QString::number(mark);
        log.arg2 = objectName();
        room->sendLog(log);
        return true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("mobile_caozhi", "mobilechengzhang");
        room->setPlayerMark(player, "mobilechengzhang", 1);
        if (room->changeMaxHpForAwakenSkill(player, 0)) {
            room->recover(player, RecoverStruct(player));
            player->drawCards(1, objectName());
            room->setPlayerProperty(player, "mobilejiushi_levelup", true);
            QString translate = Sanguosha->translate(":mobilejiushi2");
            room->changeTranslation(player, "mobilejiushi", translate);
        }
        return false;
    }
};

class MobileChengzhangRecord : public TriggerSkill
{
public:
    MobileChengzhangRecord() : TriggerSkill("#mobilechengzhang")
    {
        events << Damaged << Damage;
        //frequency = Wake;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int n = data.value<DamageStruct>().damage;
        if (player->hasSkill("mobilechengzhang", true))
            room->addPlayerMark(player, "&mobilechengzhang", n);
        else
            room->addPlayerMark(player, "mobilechengzhang_num", n);
        return false;
    }
};

MobileGongqiCard::MobileGongqiCard()
{
}

bool MobileGongqiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && Self->canDiscard(to_select, "he");
}

void MobileGongqiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->isDead() || effect.to->isDead()) return;
    if (!effect.from->canDiscard(effect.to, "he")) return;

    Room *room = effect.from->getRoom();
    int id = room->askForCardChosen(effect.from, effect.to, "he", "mobilegongqi", false, Card::MethodDiscard);
    room->throwCard(id, effect.to, effect.from);
}

class MobileGongqi : public OneCardViewAsSkill
{
public:
    MobileGongqi() : OneCardViewAsSkill("mobilegongqi")
    {
        filter_pattern = "^BasicCard";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileGongqiCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileGongqiCard *c = new MobileGongqiCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class MobileGongqiAttack : public AttackRangeSkill
{
public:
    MobileGongqiAttack() : AttackRangeSkill("#mobilegongqi-attack")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target, bool) const
    {
        if (target->hasSkill("mobilegongqi") && (target->getOffensiveHorse() || target->getDefensiveHorse()))
            return 1000;
        return 0;
    }
};

class MobileQuanji : public TriggerSkill
{
public:
    MobileQuanji() : TriggerSkill("mobilequanji")
    {
        events << EventPhaseEnd << Damaged;
        frequency = Frequent;
    }

    void doQuanji(ServerPlayer *player) const
    {
        player->drawCards(1, objectName());
        if (player->isAlive() && !player->isKongcheng()) {
            Room *room = player->getRoom();
            int card_id;
            if (player->getHandcardNum() == 1) {
                room->getThread()->delay();
                card_id = player->handCards().first();
            } else {
                const Card *card = room->askForExchange(player, "quanji", 1, 1, false, "QuanjiPush");
                card_id = card->getEffectiveId();
                delete card;
            }
            player->addToPile("power", card_id);
        }
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play || player->getHandcardNum() <= player->getHp()) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            doQuanji(player);
        } else {
            int n = data.value<DamageStruct>().damage;
            for (int i = 0; i < n; i++) {
                if (!player->askForSkillInvoke(this)) return false;
                room->broadcastSkillInvoke(objectName());
                doQuanji(player);
            }
        }
        return false;
    }
};

class MobileQuanjiKeep : public MaxCardsSkill
{
public:
    MobileQuanjiKeep() : MaxCardsSkill("#mobilequanji")
    {
        frequency = Frequent;
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill("mobilequanji"))
            return target->getPile("power").length();
        else
            return 0;
    }
};

class MobileLihuo : public TriggerSkill
{
public:
    MobileLihuo() : TriggerSkill("mobilelihuo")
    {
        events << ChangeSlash << DamageCaused << PreDamageDone << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == ChangeSlash) {
            if (!TriggerSkill::triggerable(player)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->objectName() != "slash") return false;
            FireSlash *fire_slash = new FireSlash(use.card->getSuit(), use.card->getNumber());
            fire_slash->deleteLater();
            if (!use.card->isVirtualCard() || use.card->subcardsLength() > 0) {
                if (use.card->isVirtualCard())
                    fire_slash->addSubcards(use.card->getSubcards());
                else
                    fire_slash->addSubcard(use.card);
            }
            fire_slash->setSkillName("mobilelihuo");

            bool can_use = true;
            bool has_chained = false;
            foreach (ServerPlayer *p, use.to) {
                if (!player->canSlash(p, fire_slash, false)) {
                    can_use = false;
                }
                if (p->isChained())
                    has_chained = true;
                if (!can_use && has_chained) break;
            }
            if (can_use && room->askForSkillInvoke(player, "mobilelihuo", data, false)) {
                room->broadcastSkillInvoke(objectName());
                use.card = fire_slash;
                if (has_chained)
                    room->setCardFlag(use.card, "mobilelihuo");
                data = QVariant::fromValue(use);
            }
        } else if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || damage.card->getSkillName() != objectName() || !damage.card->hasFlag("mobilelihuo")) return false;
            ++damage.damage;
            data = QVariant::fromValue(damage);
        } else if (event == PreDamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || damage.card->getSkillName() != objectName()) return false;
            if (damage.from->isDead() || !damage.from->hasSkill(this)) return false;
            int n = damage.from->tag["mobilelihuo" + damage.card->toString()].toInt();
            n += damage.damage;
            damage.from->tag["mobilelihuo" + damage.card->toString()] = n;
        } else if (event == CardFinished) {
            if (TriggerSkill::triggerable(player) && !player->hasFlag("Global_ProcessBroken")) {
                CardUseStruct use = data.value<CardUseStruct>();
                if (use.card->getSkillName() != objectName()) return false;
                int n = player->tag["mobilelihuo" + use.card->toString()].toInt();
                n = floor(n / 2);
                player->tag.remove("mobilelihuo" + use.card->toString());
                if (n <= 0) return false;
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->loseHp(player, n);
            }
        }
        return false;
    }
};

MobileZongxuanCard::MobileZongxuanCard()
{
    target_fixed = true;
}

void MobileZongxuanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(1, "mobilezongxuan");
    if (source->isDead() || source->isNude()) return;
    const Card *c = room->askForExchange(source, "mobilezongxuan", 1, 1, true, "mobilezongxuan-put");
    CardMoveReason reason(CardMoveReason::S_REASON_PUT, source->objectName(), "mobilezongxuan", QString());
    room->moveCardTo(c, NULL, Player::DrawPile, reason, false);
}

MobileZongxuanPutCard::MobileZongxuanPutCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
    m_skillName = "mobilezongxuan";
}

void MobileZongxuanPutCard::use(Room *, ServerPlayer *, QList<ServerPlayer *> &) const
{
}

class MobileZongxuanVS : public ViewAsSkill
{
public:
    MobileZongxuanVS() : ViewAsSkill("mobilezongxuan")
    {
        response_pattern = "@@mobilezongxuan";
        expand_pile = "#mobilezongxuan";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return false;
        else
            return Self->getPile("#mobilezongxuan").contains(to_select->getEffectiveId());
        return false;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileZongxuanCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (!cards.isEmpty()) return NULL;
            return new MobileZongxuanCard;
        } else {
            if (cards.isEmpty()) return NULL;
            MobileZongxuanPutCard *put = new MobileZongxuanPutCard;
            put->addSubcards(cards);
            return put;
        }
        return NULL;
    }
};

class MobileZongxuan : public TriggerSkill
{
public:
    MobileZongxuan() : TriggerSkill("mobilezongxuan")
    {
        events << CardsMoveOneTime;
        view_as_skill = new MobileZongxuanVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from != player)
            return false;
        if (move.to_place == Player::DiscardPile
            && ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD)) {
            QList<int> zongxuan_card;
            for (int i = 0; i < move.card_ids.length(); i++) {
                int id = move.card_ids.at(i);
                if ((move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip) &&
                        room->getCardPlace(id) == Player::DiscardPile)
                    zongxuan_card << id;
            }
            if (zongxuan_card.isEmpty())
                return false;

            room->notifyMoveToPile(player, zongxuan_card, objectName(), Player::DiscardPile, true);

            try {
                const Card *c = room->askForUseCard(player, "@@mobilezongxuan", "@mobilezongxuan");
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

                    CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), "mobilezongxuan", QString());
                    room->moveCardTo(c, NULL, Player::DrawPile, reason, true, true);
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

MobileJunxingCard::MobileJunxingCard()
{
}

void MobileJunxingCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isDead()) return;
    int length = subcardsLength();
    int can_dis = 0;
    QList<int> list = effect.to->handCards() + effect.to->getEquipsId();
    foreach (int id, list) {
        if (effect.to->canDiscard(effect.to, id))
            can_dis++;
    }

    if (can_dis < length) {
        effect.to->turnOver();
        effect.to->drawCards(length, "mobilejunxing");
        return;
    }

    Room *room = effect.from->getRoom();
    effect.to->tag["mobilejunxing_effect"] = QVariant::fromValue(effect.from);
    const Card *card = room->askForDiscard(effect.to, "mobilejunxing", length, length, true, true);
    effect.to->tag.remove("mobilejunxing_effect");
    if (!card) {
        effect.to->turnOver();
        effect.to->drawCards(length, "mobilejunxing");
    } else
        room->loseHp(effect.to);
}

class MobileJunxing : public ViewAsSkill
{
public:
    MobileJunxing() : ViewAsSkill("mobilejunxing")
    {
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !to_select->isEquipped();
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileJunxingCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        MobileJunxingCard *c = new MobileJunxingCard;
        c->addSubcards(cards);
        return c;
    }
};

class MobileJueceRecord : public TriggerSkill
{
public:
    MobileJueceRecord() : TriggerSkill("#mobilejuece-record")
    {
        events << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip))) return false;
        ServerPlayer *from = room->findPlayerByObjectName(move.from->objectName());
        if (!from) return false;
        room->addPlayerMark(from, "mobilejuece-Clear");
        return false;
    }
};

class MobileJuece : public PhaseChangeSkill
{
public:
    MobileJuece() : PhaseChangeSkill("mobilejuece")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getMark("mobilejuece-Clear") > 0)
                players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@mobilejuece", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        room->damage(DamageStruct(objectName(), player, target));
        return false;
    }
};

MobileMiejiCard::MobileMiejiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool MobileMiejiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isNude();
}

void MobileMiejiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->showCard(effect.from, getSubcards().first());

    CardMoveReason reason(CardMoveReason::S_REASON_PUT, effect.from->objectName(), QString(), "mobilemieji", QString());
    room->moveCardTo(this, effect.from, NULL, Player::DrawPile, reason, true);

    QList<const Card *> trick, nottrick;
    foreach (const Card *c, effect.to->getCards("he")) {
        if (c->isKindOf("TrickCard"))
            trick << c;
        else if (!c->isKindOf("TrickCard") && effect.to->canDiscard(effect.to, c->getEffectiveId()))
            nottrick << c;
    }

    if (trick.isEmpty() && nottrick.isEmpty()) return;

    if (trick.isEmpty() && !nottrick.isEmpty())
        room->askForDiscard(effect.to, "mobilemieji", 2, 2, false, true, "@mobilemieji_nottrick", "^TrickCard");
    else if (nottrick.isEmpty() && !trick.isEmpty()) {
        const Card *c = room->askForExchange(effect.to, "mobilemieji", 1, 1, false, "@mobilemieji_trick:" + effect.from->objectName(), false, "TrickCard");
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), effect.from->objectName(), "mobilemieji", QString());
        room->obtainCard(effect.from, c, reason, true);
    } else {
        const Card *cc = room->askForUseCard(effect.to, "@@mobilemieji!", "@mobilemieji:" + effect.from->objectName());
        if (!cc) {
            if (!trick.isEmpty()) {
                const Card *give = trick.at(qrand() % trick.length());
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), effect.from->objectName(), "mobilemieji", QString());
                room->obtainCard(effect.from, give, reason, true);
                return;
            }
            if (!nottrick.isEmpty()) {
                DummyCard *dis = new DummyCard;
                const Card *d = nottrick.at(qrand() % nottrick.length());
                nottrick.removeOne(d);
                dis->addSubcard(d);
                if (!nottrick.isEmpty()) {
                    const Card *dd = nottrick.at(qrand() % nottrick.length());
                    dis->addSubcard(dd);
                }
                room->throwCard(dis, effect.to, NULL);
                delete dis;
            }
        } else {
            const Card *c = Sanguosha->getCard(cc->getSubcards().first());
            if (c->isKindOf("TrickCard")) {
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), effect.from->objectName(), "mobilemieji", QString());
                room->obtainCard(effect.from, c, reason, true);
            } else
                room->throwCard(cc, effect.to, NULL);
        }
    }

}

MobileMiejiDiscardCard::MobileMiejiDiscardCard()
{
    will_throw = false;
    target_fixed = true;
    mute = true;
    handling_method = Card::MethodNone;
    m_skillName = "mobilemieji";
}

void MobileMiejiDiscardCard::onUse(Room *, const CardUseStruct &) const
{
}

class MobileMieji : public ViewAsSkill
{
public:
    MobileMieji() : ViewAsSkill("mobilemieji")
    {
        response_pattern = "@@mobilemieji!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileMiejiCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return selected.isEmpty() && to_select->isKindOf("TrickCard") && to_select->isBlack();

        if (selected.length() > 1) return false;
        if (selected.isEmpty())
            return to_select->isKindOf("TrickCard") || (!to_select->isKindOf("TrickCard") && !Self->isJilei(to_select));
        if (selected.length() == 1 && selected.first()->isKindOf("TrickCard"))
            return false;
        if (selected.length() == 1 && !selected.first()->isKindOf("TrickCard"))
            return !to_select->isKindOf("TrickCard") && !Self->isJilei(to_select);
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (cards.length() != 1) return NULL;
            MobileMiejiCard *c = new MobileMiejiCard;
            c->addSubcards(cards);
            return c;
        } else {
            QList<const Card *> ccc = Self->getHandcards() + Self->getEquips();
            int n = 0;
            foreach (const Card *c, ccc) {
                if (!c->isKindOf("TrickCard") && !Self->isJilei(c))
                    n++;
            }
            n = qMin(n, 2);

            const Card *c = cards.first();
            if (c->isKindOf("TrickCard") && cards.length() != 1) return NULL;
            if (!c->isKindOf("TrickCard") && cards.length() != n) return NULL;

            MobileMiejiDiscardCard *dis = new MobileMiejiDiscardCard;
            dis->addSubcards(cards);
            return dis;
        }
        return NULL;
    }
};

MobileXianzhenCard::MobileXianzhenCard()
{
    will_throw = false;
    handling_method = Card::MethodPindian;
}

bool MobileXianzhenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void MobileXianzhenCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;

    Room *room = effect.from->getRoom();

    if (effect.from->pindian(effect.to, "mobilexianzhen")) {
        room->addPlayerMark(effect.to, "Armor_Nullified");
        room->addPlayerMark(effect.from, "mobilexianzhen_from-PlayClear");
        room->addPlayerMark(effect.to, "mobilexianzhen_to-PlayClear");
    } else {
        room->addPlayerMark(effect.from, "mobilexianzhen_lose-PlayClear");
        room->setPlayerCardLimitation(effect.from, "use", "Slash", true);
    }
}

class MobileXianzhenVS : public ZeroCardViewAsSkill
{
public:
    MobileXianzhenVS() : ZeroCardViewAsSkill("mobilexianzhen")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canPindian() && !player->hasUsed("MobileXianzhenCard");
    }

    const Card *viewAs() const
    {
       return new MobileXianzhenCard;
    }
};

class MobileXianzhen : public TriggerSkill
{
public:
    MobileXianzhen() : TriggerSkill("mobilexianzhen")
    {
        events << Pindian << EventPhaseProceeding;
        view_as_skill = new MobileXianzhenVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Pindian) {
            PindianStruct *pindian = data.value<PindianStruct *>();
            if (pindian->reason != objectName()) return false;
            if (!pindian->from_card->isKindOf("Slash")) return false;
            room->addPlayerMark(player, "mobilexianzhen_slash-Clear");
        } else {
            if (player->getPhase() != Player::Discard || player->getMark("mobilexianzhen_slash-Clear") <= 0) return false;
            QList<int> slash;
            foreach (const Card *c, player->getCards("h")) {
                if (c->isKindOf("Slash"))
                    slash << c->getEffectiveId();
            }
            if (slash.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player,objectName(), true, true);
            room->ignoreCards(player, slash);
        }
        return false;
    }
};

class MobileXianzhenClear : public TriggerSkill
{
public:
    MobileXianzhenClear() : TriggerSkill("#mobilexianzhen-clear")
    {
        events << EventPhaseEnd << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *gaoshun, QVariant &data) const
    {
        if (triggerEvent == EventPhaseEnd) {
            if (gaoshun->getPhase() != Player::Play) return false;
            if (gaoshun->getMark("mobilexianzhen_lose-PlayClear") > 0)
                room->removePlayerCardLimitation(gaoshun, "use", "Slash$1");

            if (gaoshun->getMark("mobilexianzhen_from-PlayClear") > 0) {
                foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                    if (p->getMark("mobilexianzhen_to-PlayClear") <= 0) continue;
                    room->removePlayerMark(p, "Armor_Nullified");
                }
            }
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->getMark("mobilexianzhen_lose-PlayClear") > 0)
                room->removePlayerCardLimitation(death.who, "use", "Slash$1");
            if (death.who->getMark("mobilexianzhen_to-PlayClear") > 0)
                room->removePlayerMark(death.who, "Armor_Nullified");
            if (death.who->getMark("mobilexianzhen_from-PlayClear") > 0) {
                death.who->gainMark("@sw");
                foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                    if (p->getMark("mobilexianzhen_to-PlayClear") <= 0) continue;
                    room->removePlayerMark(p, "Armor_Nullified");
                }
            }
        }
        return false;
    }
};

class MobileXianzhenTargetMod : public TargetModSkill
{
public:
    MobileXianzhenTargetMod() : TargetModSkill("#mobilexianzhen-target")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("mobilexianzhen_from-PlayClear") > 0 && to && to->getMark("mobilexianzhen_to-PlayClear") > 0)
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if (from->getMark("mobilexianzhen_from-PlayClear") > 0 && to && to->getMark("mobilexianzhen_to-PlayClear") > 0)
            return 1000;
        else
            return 0;
    }
};

class MobileJinjiu : public FilterSkill
{
public:
    MobileJinjiu() : FilterSkill("mobilejinjiu")
    {
    }

    bool viewFilter(const Card *to_select) const
    {
        return to_select->objectName() == "analeptic";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->setSkillName(objectName());
        WrappedCard *card = Sanguosha->getWrappedCard(originalCard->getId());
        card->takeOver(slash);
        return card;
    }
};

class MobileJinjiuLimit : public CardLimitSkill
{
public:
    MobileJinjiuLimit() : CardLimitSkill("#mobilejinjiu-limit")
    {
    }

    bool gaoshun(const Player *target) const
    {
        QList<const Player *> as = target->getAliveSiblings();
        as << target;
        foreach (const Player *p, as) {
            if (p->hasSkill("mobilejinjiu") && p->getPhase() != Player::NotActive)
                return true;
        }
        return false;
    }

    QString limitList(const Player *target) const
    {
        if (gaoshun(target) && target->getPhase() == Player::NotActive)
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (gaoshun(target) && target->getPhase() == Player::NotActive)
            return "Analeptic";
        else
            return QString();
    }
};

class MobileJinjiuEffect : public TriggerSkill
{
public:
    MobileJinjiuEffect() : TriggerSkill("#mobilejinjiu")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!player->hasSkill("mobilejinjiu")) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card->isKindOf("Slash")) return false;
        int drank = damage.card->tag["drank"].toInt();
        if (drank <= 0) return false;
        room->notifySkillInvoked(player, "mobilejinjiu");
        room->broadcastSkillInvoke("mobilejinjiu");
        int n = damage.damage;
        LogMessage log;
        log.type = "#MobilejinjiuReduce";
        log.from = player;
        log.arg = "mobilejinjiu";
        damage.damage -= drank;
        log.arg2 = QString::number(damage.damage);
        if (damage.damage <= 0) {
            log.type = "#MobilejinjiuPrevent";
            log.arg2 = QString::number(n);
            room->sendLog(log);
            return true;
        }
        room->sendLog(log);
        data = QVariant::fromValue(damage);
        return false;
    }
};

MobileQiaoshuiCard::MobileQiaoshuiCard()
{
}

bool MobileQiaoshuiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void MobileQiaoshuiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (!source->canPindian(targets.first(), false)) return;
    bool success = source->pindian(targets.first(), "mobileqiaoshui", NULL);
    if (success)
        source->setFlags("MobileQiaoshuiSuccess");
    else {
        source->setFlags("MobileQiaoshuiNotSuccess");
        room->setPlayerCardLimitation(source, "use", "TrickCard", true);
    }
}

class MobileQiaoshuiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    MobileQiaoshuiViewAsSkill() : ZeroCardViewAsSkill("mobileqiaoshui")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileQiaoshuiCard") && player->canPindian();
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@mobileqiaoshui!";
    }

    const Card *viewAs() const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern.endsWith("!"))
            return new ExtraCollateralCard;
        else
            return new MobileQiaoshuiCard;
    }
};

class MobileQiaoshui : public TriggerSkill
{
public:
    MobileQiaoshui() : TriggerSkill("mobileqiaoshui")
    {
        events << PreCardUsed << EventPhaseEnd;
        view_as_skill = new MobileQiaoshuiViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == EventPhaseEnd)
            return 0;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *jianyong, QVariant &data) const
    {
        if (jianyong->getPhase() != Player::Play) return false;
        if (event == PreCardUsed && jianyong->isAlive()) {
            if (!jianyong->hasFlag("MobileQiaoshuiSuccess")) return false;

            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isNDTrick() || use.card->isKindOf("BasicCard")) {
                jianyong->setFlags("-MobileQiaoshuiSuccess");
                if (Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_PLAY)
                    return false;

                QList<ServerPlayer *> available_targets;
                if (!use.card->isKindOf("AOE") && !use.card->isKindOf("GlobalEffect")) {
                    room->setPlayerFlag(jianyong, "MobileQiaoshuiExtraTarget");
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (use.to.contains(p) || room->isProhibited(jianyong, p, use.card)) continue;
                        if (use.card->targetFixed()) {
                            if (!use.card->isKindOf("Peach") || p->isWounded())
                                available_targets << p;
                        } else {
                            if (use.card->targetFilter(QList<const Player *>(), p, jianyong))
                                available_targets << p;
                        }
                    }
                    room->setPlayerFlag(jianyong, "-MobileQiaoshuiExtraTarget");
                }
                QStringList choices;
                choices << "cancel";
                if (use.to.length() > 1) choices.prepend("remove");
                if (!available_targets.isEmpty()) choices.prepend("add");
                if (choices.length() == 1) return false;

                QString choice = room->askForChoice(jianyong, "mobileqiaoshui", choices.join("+"), data);
                if (choice == "cancel")
                    return false;
                else if (choice == "add") {
                    ServerPlayer *extra = NULL;
                    if (!use.card->isKindOf("Collateral"))
                        extra = room->askForPlayerChosen(jianyong, available_targets, "qiaoshui", "@qiaoshui-add:::" + use.card->objectName());
                    else {
                        QStringList tos;
                        foreach(ServerPlayer *t, use.to)
                            tos.append(t->objectName());
                        room->setPlayerProperty(jianyong, "extra_collateral", use.card->toString());
                        room->setPlayerProperty(jianyong, "extra_collateral_current_targets", tos.join("+"));
                        room->askForUseCard(jianyong, "@@mobileqiaoshui!", "@qiaoshui-add:::collateral");
                        room->setPlayerProperty(jianyong, "extra_collateral", QString());
                        room->setPlayerProperty(jianyong, "extra_collateral_current_targets", QString("+"));
                        foreach (ServerPlayer *p, room->getOtherPlayers(jianyong)) {
                            if (p->hasFlag("ExtraCollateralTarget")) {
                                p->setFlags("-ExtraCollateralTarget");
                                extra = p;
                                break;
                            }
                        }
                        if (extra == NULL) {
                            extra = available_targets.at(qrand() % available_targets.length());
                            QList<ServerPlayer *> victims;
                            foreach (ServerPlayer *p, room->getOtherPlayers(extra)) {
                                if (extra->canSlash(p)
                                    && (!(p == jianyong && p->hasSkill("kongcheng") && p->isLastHandCard(use.card, true)))) {
                                    victims << p;
                                }
                            }
                            Q_ASSERT(!victims.isEmpty());
                            extra->tag["collateralVictim"] = QVariant::fromValue((victims.at(qrand() % victims.length())));
                        }
                    }
                    use.to.append(extra);
                    room->sortByActionOrder(use.to);

                    LogMessage log;
                    log.type = "#QiaoshuiAdd";
                    log.from = jianyong;
                    log.to << extra;
                    log.card_str = use.card->toString();
                    log.arg = "mobileqiaoshui";
                    room->sendLog(log);
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, jianyong->objectName(), extra->objectName());

                    if (use.card->isKindOf("Collateral")) {
                        ServerPlayer *victim = extra->tag["collateralVictim"].value<ServerPlayer *>();
                        if (victim) {
                            LogMessage log;
                            log.type = "#CollateralSlash";
                            log.from = jianyong;
                            log.to << victim;
                            room->sendLog(log);
                            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, extra->objectName(), victim->objectName());
                        }
                    }
                } else {
                    ServerPlayer *removed = room->askForPlayerChosen(jianyong, use.to, "qiaoshui", "@qiaoshui-remove:::" + use.card->objectName());
                    use.to.removeOne(removed);

                    LogMessage log;
                    log.type = "#QiaoshuiRemove";
                    log.from = jianyong;
                    log.to << removed;
                    log.card_str = use.card->toString();
                    log.arg = "mobileqiaoshui";
                    room->sendLog(log);
                }
            }
            data = QVariant::fromValue(use);
        } else if (event == EventPhaseEnd) {
            if (!jianyong->hasFlag("MobileQiaoshuiNotSuccess")) return false;
            jianyong->setFlags("-MobileQiaoshuiNotSuccess");
            room->removePlayerCardLimitation(jianyong, "use", "TrickCard");
        }
        return false;
    }
};

class MobileQiaoshuiTargetMod : public TargetModSkill
{
public:
    MobileQiaoshuiTargetMod() : TargetModSkill("#mobileqiaoshui-target")
    {
        frequency = NotFrequent;
        pattern = "Slash,TrickCard+^DelayedTrick";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasFlag("MobileQiaoshuiExtraTarget"))
            return 1000;
        else
            return 0;
    }
};

MobileZongshihCard::MobileZongshihCard()
{
    mute = true;
    handling_method = Card::MethodNone;
    will_throw = false;
    target_fixed = true;
}

void MobileZongshihCard::onUse(Room *, const CardUseStruct &) const
{
}

class MobileZongshihVS : public OneCardViewAsSkill
{
public:
    MobileZongshihVS() : OneCardViewAsSkill("mobilezongshih")
    {
        expand_pile = "#mobilezongshih_draw,#mobilezongshih_pindian";
        response_pattern = "@@mobilezongshih";
    }

    bool viewFilter(const Card *to_select) const
    {
        QList<int> draw = Self->getPile("#mobilezongshih_draw");
        QList<int> pdlist = Self->getPile("#mobilezongshih_pindian");
        return draw.contains(to_select->getEffectiveId()) || pdlist.contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileZongshihCard *card = new MobileZongshihCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class MobileZongshih : public TriggerSkill
{
public:
    MobileZongshih() : TriggerSkill("mobilezongshih")
    {
        events << Pindian;
        view_as_skill = new MobileZongshihVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        PindianStruct *pindian = data.value<PindianStruct *>();
        QList<ServerPlayer *> jianyongs;
        if (pindian->from->isAlive() && pindian->from->hasSkill(this))
            jianyongs << pindian->from;
        if (pindian->to->isAlive() && pindian->to->hasSkill(this))
            jianyongs << pindian->to;
        if (jianyongs.isEmpty()) return false;
        room->sortByActionOrder(jianyongs);

        foreach (ServerPlayer *p, jianyongs) {
            if (p->isDead() || !p->hasSkill(this) || !p->askForSkillInvoke(this)) continue;
            room->broadcastSkillInvoke(objectName());
            QList<int> draw = room->getNCards(1, false);
            room->returnToTopDrawPile(draw);
            LogMessage log;
            log.type = "$ViewDrawPile";
            log.from = p;
            log.card_str = IntList2StringList(draw).join("+");
            room->sendLog(log, p);
            room->notifyMoveToPile(p, draw, "mobilezongshih_draw", Player::DrawPile, true);

            QList<int> pdlist;
            if (pindian->from_number > pindian->to_number && room->getCardPlace(pindian->to_card->getEffectiveId()) == Player::PlaceTable)
                pdlist << pindian->to_card->getEffectiveId();
            else if (pindian->from_number < pindian->to_number && room->getCardPlace(pindian->from_card->getEffectiveId()) == Player::PlaceTable)
                pdlist << pindian->from_card->getEffectiveId();
            else if (pindian->from_number == pindian->to_number) {
                 if (room->getCardPlace(pindian->from_card->getEffectiveId()) == Player::PlaceTable)
                     pdlist << pindian->from_card->getEffectiveId();
                 if (room->getCardPlace(pindian->to_card->getEffectiveId()) == Player::PlaceTable && !pdlist.contains(pindian->to_card->getEffectiveId()))
                     pdlist << pindian->to_card->getEffectiveId();
            }
            if (!pdlist.isEmpty())
                room->notifyMoveToPile(p, pdlist, "mobilezongshih_pindian", Player::PlaceTable, true);

            const Card *c = room->askForUseCard(p, "@@mobilezongshih", "@mobilezongshih", -1, Card::MethodNone);
            room->notifyMoveToPile(p, draw, "mobilezongshih_draw", Player::DrawPile, false);
            if (!pdlist.isEmpty())
                room->notifyMoveToPile(p, pdlist, "mobilezongshih_pindian", Player::PlaceTable, false);
            if (!c) continue;
            room->obtainCard(p, c, false);
        }

        return false;
    }
};

class MobileDanshou : public PhaseChangeSkill
{
public:
    MobileDanshou() : PhaseChangeSkill("mobiledanshou")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            int n = p->getMark("mobiledanshou_num" + player->objectName() + "-Clear");
            if (n <= 0) {
                room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                p->drawCards(1, objectName());
            } else {
                if (player->isDead() || !p->canDiscard(p, "he")) continue;
                p->tag["mobiledanshou_target"] = QVariant::fromValue(player);
                const Card *card = room->askForDiscard(p, objectName(), n, n, true, true,
                            QString("@mobiledanshou-dis:%1::%2").arg(player->objectName()).arg(n), ".", objectName());
                p->tag.remove("mobiledanshou_target");
                if (!card) continue;
                delete card;
                room->damage(DamageStruct(objectName(), p, player));
            }
        }
        return false;
    }
};

class MobileDanshouRecord : public TriggerSkill
{
public:
    MobileDanshouRecord() : TriggerSkill("#mobiledanshou-record")
    {
        events << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        foreach (ServerPlayer *p, use.to)
            room->addPlayerMark(p, "mobiledanshou_num" + player->objectName() + "-Clear");
        return false;
    }
};

class MobileDuodao : public MasochismSkill
{
public:
    MobileDuodao() : MasochismSkill("mobileduodao")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        if (!damage.from || damage.from->isDead() || !damage.from->getWeapon()) return;
        if (!player->askForSkillInvoke(this, damage.from)) return;
        player->getRoom()->broadcastSkillInvoke(objectName());
        player->obtainCard(damage.from->getWeapon());
    }
};

class MobileAnjian : public TriggerSkill
{
public:
    MobileAnjian() : TriggerSkill("mobileanjian")
    {
        events << DamageCaused << TargetSpecified;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->hasFlag("mobileanjian_damage_" + damage.to->objectName())) return false;
            room->setCardFlag(damage.card, "-mobileanjian_damage_" + damage.to->objectName());
            ++damage.damage;
            data = QVariant::fromValue(damage);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || use.to.isEmpty()) return false;
            foreach (ServerPlayer *p, use.to) {
                if (player->isDead()) break;
                if (p->isDead() || p->inMyAttackRange(player)) continue;
                player->tag["mobileanjian_usedata"] = data;
                QString choice = room->askForChoice(player, objectName(), "noresponse+damage", QVariant::fromValue(p));
                player->tag.remove("mobileanjian_usedata");
                LogMessage log;
                log.type = "#FumianFirstChoice";
                log.from = player;
                log.arg = "mobileanjian:" + choice;
                room->sendLog(log);
                if (choice == "noresponse") {
                    use.no_respond_list << p->objectName();
                    data = QVariant::fromValue(use);
                } else
                    room->setCardFlag(use.card, "mobileanjian_damage_" + p->objectName());
            }
        }
        return false;
    }
};

class MobileZhuikong : public TriggerSkill
{
public:
    MobileZhuikong() : TriggerSkill("mobilezhuikong")
    {
        events << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::RoundStart)
            return false;

        foreach (ServerPlayer *fuhuanghou, room->getOtherPlayers(player)) {
            if (TriggerSkill::triggerable(fuhuanghou) && fuhuanghou->getMark("mobilezhuikong_lun") <= 0
                && player->getHp() >= fuhuanghou->getHp() && fuhuanghou->canPindian(player)
                && fuhuanghou->askForSkillInvoke(objectName(), player)) {
                room->broadcastSkillInvoke(objectName());
                room->addPlayerMark(fuhuanghou, "mobilezhuikong_lun");
                PindianStruct *pindian = fuhuanghou->PinDian(player, objectName());
                if (pindian->success) {
                    room->setPlayerFlag(player, "mobilezhuikong");
                } else {
                    int to_card_id = pindian->to_card->getEffectiveId();
                    if (room->getCardPlace(to_card_id) != Player::DiscardPile) return false;
                    room->obtainCard(fuhuanghou, to_card_id);
                    Slash *slash = new Slash(Card::NoSuit, 0);
                    slash->setSkillName("_mobilezhuikong");
                    slash->deleteLater();
                    if (!player->canSlash(fuhuanghou, slash, false)) return false;
                    room->useCard(CardUseStruct(slash, player, fuhuanghou));
                }
            }
        }
        return false;
    }
};

class MobileZhuikongProhibit : public ProhibitSkill
{
public:
    MobileZhuikongProhibit() : ProhibitSkill("#mobilezhuikong")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (card->getTypeId() != Card::TypeSkill && from->hasFlag("mobilezhuikong"))
            return to != from;
        return false;
    }
};

class MobileQiuyuan : public TriggerSkill
{
public:
    MobileQiuyuan() : TriggerSkill("mobileqiuyuan")
    {
        events << TargetConfirming;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        QList<ServerPlayer *> targets = room->getOtherPlayers(player);
        if (targets.contains(use.from))
            targets.removeOne(use.from);
        if (targets.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@mobileqiuyuan-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());

        const Card *card = NULL;
        if (!target->isKongcheng())
            card = room->askForCard(target, "BasicCard+^Slash", "@mobileqiuyuan-give:" + player->objectName(), data, Card::MethodNone);
        if (!card) {
            if (!use.from->canSlash(target, use.card, false)) return false;
            LogMessage log;
            log.type = "#BecomeTarget";
            log.from = target;
            log.card_str = use.card->toString();
            room->sendLog(log);
            use.to.append(target);
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        } else {
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), "mobileqiuyuan", QString());
            room->obtainCard(player, card, reason);
        }
        return false;
    }
};

class MobileJingce : public PhaseChangeSkill
{
public:
    MobileJingce() : PhaseChangeSkill("mobilejingce")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        int n = room->getTag("mobilejingce_record").toInt();
        if (n < player->getHp()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        player->drawCards(2, objectName());
        return false;
    }
};

class MobileJingceRecord : public TriggerSkill
{
public:
    MobileJingceRecord() : TriggerSkill("#mobilejingce-record")
    {
        events << CardsMoveOneTime << EventPhaseChanging;
        global = true;
    }

    int getPriority() const
    {
        return 0;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to_place == Player::DiscardPile && (move.reason.m_reason == CardMoveReason::S_REASON_USE ||
               move.reason.m_reason == CardMoveReason::S_REASON_RESPONSE || move.reason.m_reason == CardMoveReason::S_REASON_LETUSE)) {
                //改判打出的牌CardMoveReason::S_REASON_RETRIAL，置入弃牌堆的原因是判定，而不是打出
                if (player != move.from) return false;
                const Card *card = move.reason.m_extraData.value<const Card *>();
                if (!card || card->isKindOf("SkillCard")) return false;
                int n = room->getTag("mobilejingce_record").toInt();
                if (card->isVirtualCard())
                    n += card->subcardsLength();
                else
                    n++;
                room->setTag("mobilejingce_record", n);
            }
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setTag("mobilejingce_record", 0);
        }
        return false;
    }
};

MobileDingpinCard::MobileDingpinCard()
{
}

bool MobileDingpinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getMark("mobiledingpin_target-PlayClear") == 0;
}

void MobileDingpinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();

    JudgeStruct judge;
    judge.who = effect.to;
    judge.good = true;
    judge.pattern = ".|black";
    judge.reason = "mobiledingpin";

    room->judge(judge);

    if (judge.isGood()) {
        effect.to->drawCards(qMin(3, effect.to->getHp()), "mobiledingpin");
        room->addPlayerMark(effect.to, "mobiledingpin_target-PlayClear");
    } else {
        Card::Suit suit = (Card::Suit)(judge.pattern.toInt());
        if (suit == Card::Diamond)
            effect.from->turnOver();
        else if (suit == Card::Heart)
            room->removePlayerMark(effect.from, "dingpin_" + Sanguosha->getCard(subcards.first())->getType() + "-Clear");
    }
}

class MobileDingpinVS : public OneCardViewAsSkill
{
public:
    MobileDingpinVS() : OneCardViewAsSkill("mobiledingpin")
    {
    }

    bool viewFilter(const Card *to_select) const
    {
        return Self->getMark("dingpin_" + to_select->getType() + "-Clear") == 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MobileDingpinCard *card = new MobileDingpinCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class MobileDingpin : public TriggerSkill
{
public:
    MobileDingpin() : TriggerSkill("mobiledingpin")
    {
        events << FinishJudge;
        view_as_skill = new MobileDingpinVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != objectName()) return false;
        judge->pattern = QString::number(int(judge->card->getSuit()));
        return false;
    }
};

class MobileZhongyong : public TriggerSkill
{
public:
    MobileZhongyong() : TriggerSkill("mobilezhongyong")
    {
        events << SlashMissed << CardFinished << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.reason.m_skillName != objectName() || move.to_place != Player::PlaceHand || move.to != player) return false;
            QStringList limited = player->tag["mobilezhongyong_limited"].toStringList();
            foreach (int id, move.card_ids) {
                QString str = QString::number(id);
                if (limited.contains(str)) continue;
                limited << str;
                room->setPlayerCardLimitation(player, "use", str, true);
            }
            player->tag["mobilezhongyong_limited"] = limited;
        } else if (event == SlashMissed) {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            QStringList jink = player->tag["mobilezhongyong_" + effect.slash->toString()].toStringList();
            QString str = effect.jink->toString();
            if (!jink.contains(str)) {
                jink << str;
                player->tag["mobilezhongyong_" + effect.slash->toString()] = jink;
            }
        } else {
            if (player->getPhase() != Player::Play) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;

            QStringList jink = player->tag["mobilezhongyong_" + use.card->toString()].toStringList();
            player->tag.remove("mobilezhongyong_" + use.card->toString());

            CardMoveReason reason(CardMoveReason::S_REASON_RECYCLE, player->objectName(), objectName(), QString());

            if (jink.isEmpty()) {
                if (room->CardInPlace(use.card, Player::DiscardPile) && player->askForSkillInvoke(this, data)) {
                    room->broadcastSkillInvoke(this);
                    room->obtainCard(player, use.card, reason, true);
                }
            } else {
                QList<int> jinks;
                foreach (QString str, jink) {
                    const Card *card = Card::Parse(str);
                    if (!card || !room->CardInPlace(card, Player::DiscardPile)) continue;

                    if (card->isVirtualCard())
                        jinks << card->getSubcards();
                    else
                        jinks << card->getEffectiveId();
                }
                if (jinks.isEmpty()) return false;

                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (use.to.contains(p)) continue;
                    targets << p;
                }
                if (!targets.contains(player))
                    targets << player;
                if (targets.isEmpty()) return false;

                room->fillAG(jinks, player);
                ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@mobilezhongyong-invoke", true, true);
                room->clearAG(player);
                if (!target) return false;
                room->broadcastSkillInvoke(this);

                DummyCard get_jink(jinks);

                if (target == player) {
                    room->obtainCard(player, &get_jink, reason, true);
                    if (player->isAlive() && room->CardInPlace(use.card, Player::DiscardPile)) {
                        if (targets.contains(player))
                            targets.removeOne(player);
                        if (targets.isEmpty()) return false;
                        QList<int> slashs;
                        if (use.card->isVirtualCard())
                            slashs = use.card->getSubcards();
                        else
                            slashs << use.card->getEffectiveId();
                        if (slashs.isEmpty()) return false;
                        room->fillAG(slashs, player);
                        ServerPlayer *target2 = room->askForPlayerChosen(player, targets, "mobilezhongyong_slash", "@mobilezhongyong-give", true, false);
                        room->clearAG(player);
                        if (!target2) return false;
                        room->doAnimate(1, player->objectName(), target2->objectName());
                        CardMoveReason reason2(CardMoveReason::S_REASON_GIVE, player->objectName(), target2->objectName(), objectName(), QString());
                        room->obtainCard(target2, use.card, reason2, true);
                    }
                } else {
                    CardMoveReason reason2(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), objectName(), QString());
                    room->obtainCard(target, &get_jink, reason2, true);
                    if (player->isAlive()) {
                        room->addSlashCishu(player, 1);
                        room->addPlayerMark(player, "&mobilezhongyong");
                    }
                }
            }
        }
        return false;
    }
};

class MobileZhongyongEffect : public TriggerSkill
{
public:
    MobileZhongyongEffect() : TriggerSkill("#mobilezhongyong-effect")
    {
        events << PreCardUsed << ConfirmDamage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            int mark = player->getMark("&mobilezhongyong");
            if (!use.card->isKindOf("Slash") || mark <= 0) return false;
            room->setCardFlag(use.card, "mobilezhongyong_damage_" + QString::number(mark));
            room->setPlayerMark(player, "&mobilezhongyong", 0);
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card->isKindOf("Slash")) return false;
            int damage_num = 0;
            foreach (QString flag, damage.card->getFlags()) {
                if (!flag.startsWith("mobilezhongyong_damage_")) continue;
                QStringList flags = flag.split("_");
                if (flags.length() != 3) continue;
                damage_num = flags.last().toInt();
                break;
            }
            if (damage_num <= 0) return false;
            damage.damage += damage_num;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class MobileZhongyongRemove : public TriggerSkill
{
public:
    MobileZhongyongRemove() : TriggerSkill("#mobilezhongyong-remove")
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
            QStringList limited = p->tag["mobilezhongyong_limited"].toStringList();
            p->tag.remove("mobilezhongyong_limited");
            foreach (QString str, limited)
                room->removePlayerCardLimitation(p, "use", str + "$1");
        }
        return false;
    }
};

MobileShenxingCard::MobileShenxingCard()
{
    target_fixed = true;
}

void MobileShenxingCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isAlive()) {
        int n = 1;
        if (!Sanguosha->getCard(subcards.first())->sameColorWith(Sanguosha->getCard(subcards.last())))
            n++;
        room->drawCards(source, n, "mobileshenxing");
    }
}

class MobileShenxing : public ViewAsSkill
{
public:
    MobileShenxing() : ViewAsSkill("mobileshenxing")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() < 2 && !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2)
            return NULL;

        MobileShenxingCard *card = new MobileShenxingCard;
        card->addSubcards(cards);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getCardCount(true) >= 2 && player->canDiscard(player, "he") && player->usedTimes("MobileShenxingCard") < player->getHp();
    }
};

MobileBingyiCard::MobileBingyiCard()
{
}

bool MobileBingyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    QList<const Card *>cards = Self->getHandcards();
    if (cards.isEmpty()) return false;

    bool same_color = true, same_type = true;
    Card::Color color = cards.first()->getColor();
    int type_id = cards.first()->getTypeId();

    foreach (const Card *c, cards) {
        if (c->getColor() != color) {
            same_color = false;
            break;
        }
    }
    if (!same_color) {
        foreach (const Card *c, cards) {
            if (c->getTypeId() != type_id) {
                same_type = false;
                break;
            }
        }
    }
    if (!same_color && !same_type)
        return targets.isEmpty();
    return targets.length() <= Self->getHandcardNum();
}

bool MobileBingyiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    QList<const Card *>cards = Self->getHandcards();
    if (cards.isEmpty()) return false;

    bool same_color = true, same_type = true;
    Card::Color color = cards.first()->getColor();
    int type_id = cards.first()->getTypeId();

    foreach (const Card *c, cards) {
        if (c->getColor() != color) {
            same_color = false;
            break;
        }
    }
    if (!same_color) {
        foreach (const Card *c, cards) {
            if (c->getTypeId() != type_id) {
                same_type = false;
                break;
            }
        }
    }
    if (!same_color && !same_type)
        return false;
    return targets.length() < Self->getHandcardNum();
}

void MobileBingyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->showAllCards(source);
    foreach(ServerPlayer *p, targets)
        room->drawCards(p, 1, "mobilebingyi");
}

class MobileBingyiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    MobileBingyiViewAsSkill() : ZeroCardViewAsSkill("mobilebingyi")
    {
        response_pattern = "@@mobilebingyi";
    }

    const Card *viewAs() const
    {
        return new MobileBingyiCard;
    }
};

class MobileBingyi : public PhaseChangeSkill
{
public:
    MobileBingyi() : PhaseChangeSkill("mobilebingyi")
    {
        view_as_skill = new MobileBingyiViewAsSkill;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        if (target->getPhase() != Player::Finish || target->isKongcheng()) return false;
        target->getRoom()->askForUseCard(target, "@@mobilebingyi", "@mobilebingyi");
        return false;
    }
};

class MobileQieting : public TriggerSkill
{
public:
    MobileQieting() : TriggerSkill("mobileqieting")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::NotActive || player->getMark("damage_point_turn-Clear") > 0) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!TriggerSkill::triggerable(p) || !p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);

            QStringList choices;
            QList<int> disable_ids;
            if (player->isAlive()) {
                if (!player->isKongcheng())
                    choices << "view=" + player->objectName();
                for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
                    if (player->getEquip(i) && (p->getEquip(i) || !p->hasEquipArea(i)))
                        disable_ids << player->getEquip(i)->getEffectiveId();
                }
                if (player->getEquips().length() > disable_ids.length())
                    choices << "move=" + player->objectName();
            }
            choices << "draw";

            QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(player));
            if (choice == "draw")
                p->drawCards(1, objectName());
            else if (choice.startsWith("move")) {
                int id = room->askForCardChosen(p, player, "e", objectName(), false, Card::MethodNone, disable_ids);
                if (id >= 0) {
                    const Card *card = Sanguosha->getCard(id);
                    room->moveCardTo(card, p, Player::PlaceEquip);
                }
            } else {
                int n = qMin(player->getHandcardNum(), 2);
                if (n <= 0) return false;
                int ad = Config.AIDelay;
                Config.AIDelay = 0;
                QList<int> cards;
                player->setFlags("mobileqieting_InTempMoving");
                for (int i = 0; i < n; ++i) {
                    int id = room->askForCardChosen(p, player, "h", "mobileqieting_view");
                    cards << id;
                    player->addToPile("#mobileqieting", id, false);
                }
                for (int i = 0; i < n; ++i)
                    room->moveCardTo(Sanguosha->getCard(cards.value(i)), player, Player::PlaceHand, false);
                player->setFlags("-mobileqieting_InTempMoving");
                Config.AIDelay = ad;
                if (cards.isEmpty() || p->isDead()) return false;
                room->fillAG(cards, p);
                int id = room->askForAG(p, cards, false, objectName());
                room->clearAG(p);
                room->obtainCard(p, id, false);
            }
        }
        return false;
    }
};

MobileJianyingDialog *MobileJianyingDialog::getInstance(const QString &object)
{
    static MobileJianyingDialog *instance;
    if (instance == NULL || instance->objectName() != object)
        instance = new MobileJianyingDialog(object);

    return instance;
}

MobileJianyingDialog::MobileJianyingDialog(const QString &object)
    : GuhuoDialog(object, true, false)
{
}

bool MobileJianyingDialog::isButtonEnabled(const QString &button_name) const
{
    const Card *c = map[button_name];
    c->setFlags(objectName());
    return button_name != "normal_slash" && !Self->isCardLimited(c, Card::MethodUse) && c->isAvailable(Self);
}

MobileJianyingCard::MobileJianyingCard()
{
    mute = true;
    handling_method = Card::MethodUse;
    will_throw = false;
}

bool MobileJianyingCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *_card = Self->tag.value("mobilejianying").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    QString suitstring = Self->property("MobileJianyingLastSuitString").toString();
    if (!suitstring.isEmpty())
        card->setFlags("CardInformationHelper???" + suitstring + "???" + QString::number(card->getNumber()));
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool MobileJianyingCard::targetFixed() const
{
    const Card *_card = Self->tag.value("mobilejianying").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    QString suitstring = Self->property("MobileJianyingLastSuitString").toString();
    if (!suitstring.isEmpty())
        card->setFlags("CardInformationHelper???" + suitstring + "???" + QString::number(card->getNumber()));
    return card && card->targetFixed();
}

bool MobileJianyingCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    const Card *_card = Self->tag.value("mobilejianying").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    QString suitstring = Self->property("MobileJianyingLastSuitString").toString();
    if (!suitstring.isEmpty())
        card->setFlags("CardInformationHelper???" + suitstring + "???" + QString::number(card->getNumber()));
    return card && card->targetsFeasible(targets, Self);
}

const Card *MobileJianyingCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;
    Room *room = player->getRoom();

    QString tl = user_string;

    const Card *card = Sanguosha->getCard(subcards.first());
    Card *use_card = Sanguosha->cloneCard(tl, card->getSuit(), card->getNumber());
    use_card->setSkillName("mobilejianying");
    use_card->addSubcard(subcards.first());
    use_card->deleteLater();

    room->setCardFlag(use_card, "RemoveFromHistory");

    QString suitstring = player->property("MobileJianyingLastSuitString").toString();
    if (!suitstring.isEmpty())
        room->setCardFlag(use_card, "CardInformationHelper???" + suitstring + "???" + QString::number(card->getNumber()));

    return use_card;
}

class MobileJianyingVS : public OneCardViewAsSkill
{
public:
    MobileJianyingVS() : OneCardViewAsSkill("mobilejianying")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileJianyingCard");
    }

    bool viewFilter(const Card *card) const
    {
        const Card *_card = Self->tag.value("mobilejianying").value<const Card *>();
        if (_card == NULL)
            return false;
        Card *c = Sanguosha->cloneCard(_card);
        c->addSubcard(card);
        c->setSkillName(objectName());
        return c->isAvailable(Self) && !Self->isCardLimited(card, Card::MethodUse);
    }

    const Card *viewAs(const Card *originalCard) const
    {
        const Card *c = Self->tag.value("mobilejianying").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            MobileJianyingCard *card = new MobileJianyingCard;
            card->setUserString(c->objectName());
            card->addSubcard(originalCard);
            return card;
        }
        return NULL;
    }
};

class MobileJianying : public Jianying
{
public:
    MobileJianying() : Jianying()
    {
        setObjectName("mobilejianying");
        jianying = "MobileJianying";
        view_as_skill = new MobileJianyingVS;
        frequency = NotFrequent;
    }

    QDialog *getDialog() const
    {
        return MobileJianyingDialog::getInstance("mobilejianying");
    }
};

class MobileJianyingTargetMod : public TargetModSkill
{
public:
    MobileJianyingTargetMod() : TargetModSkill("#mobilejianying-target")
    {
        frequency = NotFrequent;
        pattern = "BasicCard";
    }

    int getResidueNum(const Player *, const Card *card, const Player *) const
    {
        if (card->getSkillName() == "mobilejianying" || card->hasFlag("mobilejianying"))
            return 1000;
        else
            return 0;
    }
};

MobileYanzhuCard::MobileYanzhuCard()
{
}

void MobileYanzhuCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    if (to->isAllNude()) return;
    Room *room = from->getRoom();
    QStringList choices;
    if (!to->getEquips().isEmpty())
        choices << "equip=" + from->objectName();
    choices << "obtain=" + from->objectName();
    QString choice = room->askForChoice(to, "mobileyanzhu", choices.join("+"), QVariant::fromValue(from));
    if (choice.startsWith("equip")) {
        DummyCard dummy;
        dummy.addSubcards(to->getEquips());
        room->obtainCard(from, &dummy);
        room->handleAcquireDetachSkills(from, "-mobileyanzhu");
        room->setPlayerProperty(from, "MobileXingxueLevelUp", true);
        room->changeTranslation(from, "mobilexingxue", 1);
    } else {
        int id = room->askForCardChosen(from, to, "hej", "mobileyanzhu");
        room->obtainCard(from, id, false);
    }
}

class MobileYanzhu : public ZeroCardViewAsSkill
{
public:
    MobileYanzhu() : ZeroCardViewAsSkill("mobileyanzhu")
    {
    }

    const Card *viewAs() const
    {
        return new MobileYanzhuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MobileYanzhuCard");
    }
};

MobileXingxueCard::MobileXingxueCard()
{
}

bool MobileXingxueCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    bool xingxue = Self->property("MobileXingxueLevelUp").toBool();
    int max = xingxue ? Self->getMaxHp() : Self->getHp();
    return targets.length() < max;
}

bool MobileXingxueCard::hasAliveTargets(ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (p == player) continue;
        if (p->isAlive())
            return true;
    }
    return false;
}

void MobileXingxueCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    bool xingxue = source->property("MobileXingxueLevelUp").toBool();
    QStringList target_names;
    foreach (ServerPlayer *t, targets)
        target_names << t->objectName();

    foreach (ServerPlayer *t, targets) {
        t->drawCards(1, "mobilexingxue");
        if (t->isAlive() && !t->isNude()) {
            QStringList choices;
            if (xingxue && hasAliveTargets(t, targets))
                choices << "give";
            choices << "put";

            QString choice = room->askForChoice(t, "mobilexingxue", choices.join("+"), target_names);

            if (choice == "put") {
                const Card *c = room->askForExchange(t, "mobilexingxue", 1, 1, true, "@xingxue-put");
                int id = c->getSubcards().first();
                delete c;

                CardsMoveStruct m(id, NULL, Player::DrawPile, CardMoveReason(CardMoveReason::S_REASON_PUT, t->objectName()));
                room->setPlayerFlag(t, "Global_GongxinOperator");
                room->moveCardsAtomic(m, false);
                room->setPlayerFlag(t, "-Global_GongxinOperator");
            } else {
                QList<ServerPlayer *> new_targets = targets;
                new_targets.removeOne(t);
                QList<int> cards = t->handCards() + t->getEquipsId();
                room->askForYiji(t, cards, "mobilexingxue", false, false, false, 1, new_targets);
            }
        }
    }
}

class MobileXingxueVS : public ZeroCardViewAsSkill
{
public:
    MobileXingxueVS() : ZeroCardViewAsSkill("mobilexingxue")
    {
        response_pattern = "@@mobilexingxue";
    }

    const Card *viewAs() const
    {
        return new MobileXingxueCard;
    }
};

class MobileXingxue : public PhaseChangeSkill
{
public:
    MobileXingxue() : PhaseChangeSkill("mobilexingxue")
    {
        view_as_skill = new MobileXingxueVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        bool xingxue = player->property("MobileXingxueLevelUp").toBool();
        int num = xingxue ? player->getMaxHp() : player->getHp();
        if (num <= 0) return false;
        player->getRoom()->askForUseCard(player, "@@mobilexingxue", "@mobilexingxue:" + QString::number(num));
        return false;
    }
};

MobileJXTPPackage::MobileJXTPPackage()
    : Package("MobileJXTP")
{
    General *mobile_zhangfei = new General(this, "mobile_zhangfei", "shu", 4);
    mobile_zhangfei->addSkill("tenyearpaoxiao");
    mobile_zhangfei->addSkill(new MobileLiyong);
    mobile_zhangfei->addSkill(new MobileLiyongClear);
    related_skills.insertMulti("mobileliyong", "#mobileliyong-clear");

    General *mobile_xiahoudun = new General(this, "mobile_xiahoudun", "wei", 4);
    mobile_xiahoudun->addSkill("ganglie");
    mobile_xiahoudun->addSkill(new MobileQingjian);
    mobile_xiahoudun->addSkill(new MobileQingjianPut);
    related_skills.insertMulti("mobileqingjian", "#mobileqingjian-put");

    General *mobile_zhoutai = new General(this, "mobile_zhoutai", "wu", 4);
    mobile_zhoutai->addSkill("buqu");
    mobile_zhoutai->addSkill(new MobileFenji);

    General *mobile_wolong = new General(this, "mobile_wolong", "shu", 3);
    mobile_wolong->addSkill("bazhen");
    mobile_wolong->addSkill("olhuoji");
    mobile_wolong->addSkill("olkanpo");

    General *mobile_dianwei = new General(this, "mobile_dianwei", "wei", 4);
    mobile_dianwei->addSkill(new MobileQiangxi);

    General *mobile_xunyu = new General(this, "mobile_xunyu", "wei", 3);
    mobile_xunyu->addSkill("quhu");
    mobile_xunyu->addSkill(new MobileJieming);

    General *mobile_pangtong = new General(this, "mobile_pangtong", "shu", 3);
    mobile_pangtong->addSkill("ollianhuan");
    mobile_pangtong->addSkill(new MobileNiepan);

    General *mobile_yanliangwenchou = new General(this, "mobile_yanliangwenchou", "qun", 4);
    mobile_yanliangwenchou->addSkill(new MobileShuangxiong);

    General *mobile_yuanshao = new General(this, "mobile_yuanshao$", "qun", 4);
    mobile_yuanshao->addSkill(new MobileLuanji);
    mobile_yuanshao->addSkill("xueyi");

    General *mobile_menghuo = new General(this, "mobile_menghuo", "shu", 4);
    mobile_menghuo->addSkill("huoshou");
    mobile_menghuo->addSkill(new MobileZaiqi);

    General *mobile_zhurong = new General(this, "mobile_zhurong", "shu", 4, false);
    mobile_zhurong->addSkill("juxiang");
    mobile_zhurong->addSkill(new MobileLieren);

    General *mobile_caopi = new General(this, "mobile_caopi$", "wei", 3);
    mobile_caopi->addSkill(new MobileXingshang);
    mobile_caopi->addSkill(new MobileFangzhu);
    mobile_caopi->addSkill("songwei");

    General *mobile_sunjian = new General(this, "mobile_sunjian", "wu", 4);
    mobile_sunjian->addSkill("yinghun");
    mobile_sunjian->addSkill(new MobilePolu);

    General *mobile_dongzhuo = new General(this, "mobile_dongzhuo$", "qun", 8);
    mobile_dongzhuo->addSkill(new MobileJiuchi);
    mobile_dongzhuo->addSkill("roulin");
    mobile_dongzhuo->addSkill("benghuai");
    mobile_dongzhuo->addSkill("baonue");

    General *mobile_dengai = new General(this, "mobile_dengai", "wei", 4);
    mobile_dengai->addSkill(new MobileTuntian);
    mobile_dengai->addSkill(new MobileTuntianDistance);
    mobile_dengai->addSkill("zaoxian");
    mobile_dengai->addRelateSkill("jixi");
    related_skills.insertMulti("mobiletuntian", "#mobiletuntian-dist");

    General *mobile_jiangwei = new General(this, "mobile_jiangwei", "shu", 4);
    mobile_jiangwei->addSkill(new MobileTiaoxin);
    mobile_jiangwei->addSkill(new MobileZhiji);
    mobile_jiangwei->addRelateSkill("tenyearguanxing");

    General *mobile_sunce = new General(this, "mobile_sunce$", "wu", 4);
    mobile_sunce->addSkill("jiang");
    mobile_sunce->addSkill(new MobileHunzi);
    mobile_sunce->addSkill("zhiba");

    General *mobile_caiwenji = new General(this, "mobile_caiwenji", "qun", 3, false);
    mobile_caiwenji->addSkill(new MobileBeige);
    mobile_caiwenji->addSkill("duanchang");

    General *mobile_erzhang = new General(this, "mobile_erzhang", "wu", 3);
    mobile_erzhang->addSkill(new MobileZhijian);
    mobile_erzhang->addSkill("guzheng");

    General *mobile_liushan = new General(this, "mobile_liushan$", "shu", 3);
    mobile_liushan->addSkill("xiangle");
    mobile_liushan->addSkill(new MobileFangquan);
    mobile_liushan->addSkill(new MobileFangquanMax);
    mobile_liushan->addSkill("ruoyu");
    related_skills.insertMulti("mobilefangquan", "#mobilefangquan-max");

    General *mobile_xusheng = new General(this, "mobile_xusheng", "wu", 4);
    mobile_xusheng->addSkill(new MobilePojun);
    mobile_xusheng->addSkill(new FakeMoveSkill("mobilepojun"));
    related_skills.insertMulti("mobilepojun", "#mobilepojun-fake-move");

    General *mobile_wuguotai = new General(this, "mobile_wuguotai", "wu", 3, false);
    mobile_wuguotai->addSkill(new MobileGanlu);
    mobile_wuguotai->addSkill("buyi");

    General *mobile_yujin = new General(this, "mobile_yujin", "wei", 4);
    mobile_yujin->addSkill(new MobileJieyue);

    General *mobile_liaohua = new General(this, "mobile_liaohua", "shu", 4);
    mobile_liaohua->addSkill(new MobileDangxian);
    mobile_liaohua->addSkill(new MobileFuli);

    General *mobile_bulianshi = new General(this, "mobile_bulianshi", "wu", 3, false);
    mobile_bulianshi->addSkill(new MobileAnxu);
    mobile_bulianshi->addSkill("zhuiyi");

    General *mobile_liubiao = new General(this, "mobile_liubiao", "qun", 3);
    mobile_liubiao->addSkill("olzishou");
    mobile_liubiao->addSkill(new MobileZongshi);
    mobile_liubiao->addSkill(new MobileZongshiKeep);
    related_skills.insertMulti("mobilezongshi", "#mobilezongshi-keep");

    General *mobile_gongsunzan = new General(this, "mobile_gongsunzan", "qun", 4);
    mobile_gongsunzan->addSkill(new MobileYicong);
    mobile_gongsunzan->addSkill("qiaomeng");

    General *mobile_lingtong = new General(this, "mobile_lingtong", "wu", 4);
    mobile_lingtong->addSkill(new MobileXuanfeng);

    General *mobile_caozhi = new General(this, "mobile_caozhi", "wei", 3);
    mobile_caozhi->addSkill("luoying");
    mobile_caozhi->addSkill(new MobileJiushi);
    mobile_caozhi->addSkill(new MobileChengzhang);
    mobile_caozhi->addSkill(new MobileChengzhangRecord);
    related_skills.insertMulti("mobilechengzhang", "#mobilechengzhang");

    General *mobile_handang = new General(this, "mobile_handang", "wu", 4);
    mobile_handang->addSkill(new MobileGongqi);
    mobile_handang->addSkill(new MobileGongqiAttack);
    mobile_handang->addSkill("jiefan");
    related_skills.insertMulti("mobilegongqi", "#mobilegongqi-attack");

    General *mobile_zhonghui = new General(this, "mobile_zhonghui", "wei", 4);
    mobile_zhonghui->addSkill(new MobileQuanji);
    mobile_zhonghui->addSkill(new MobileQuanjiKeep);
    mobile_zhonghui->addSkill("zili");
    mobile_zhonghui->addRelateSkill("paiyi");
    related_skills.insertMulti("mobilequanji", "#mobilequanji");

    General *mobile_chengpu = new General(this, "mobile_chengpu", "wu", 4);
    mobile_chengpu->addSkill(new MobileLihuo);
    mobile_chengpu->addSkill("chunlao");

    General *mobile_yufan = new General(this, "mobile_yufan", "wu", 3);
    mobile_yufan->addSkill(new MobileZongxuan);
    mobile_yufan->addSkill("zhiyan");

    General *mobile_manchong = new General(this, "mobile_manchong", "wei", 3);
    mobile_manchong->addSkill(new MobileJunxing);
    mobile_manchong->addSkill("yuce");

    General *mobile_liru = new General(this, "mobile_liru", "qun", 3);
    mobile_liru->addSkill(new MobileJuece);
    mobile_liru->addSkill(new MobileJueceRecord);
    mobile_liru->addSkill(new MobileMieji);
    mobile_liru->addSkill("fencheng");
    related_skills.insertMulti("mobilejuece", "#mobilejuece-record");

    General *mobile_gaoshun = new General(this, "mobile_gaoshun", "qun", 4);
    mobile_gaoshun->addSkill(new MobileXianzhen);
    mobile_gaoshun->addSkill(new MobileXianzhenClear);
    mobile_gaoshun->addSkill(new MobileXianzhenTargetMod);
    mobile_gaoshun->addSkill(new MobileJinjiu);
    mobile_gaoshun->addSkill(new MobileJinjiuLimit);
    mobile_gaoshun->addSkill(new MobileJinjiuEffect);
    related_skills.insertMulti("mobilexianzhen", "#mobilexianzhen-clear");
    related_skills.insertMulti("mobilexianzhen", "#mobilexianzhen-target");
    related_skills.insertMulti("mobilejinjiu", "#mobilejinjiu-limit");
    related_skills.insertMulti("mobilejinjiu", "#mobilejinjiu");

    General *mobile_jianyong = new General(this, "mobile_jianyong", "shu", 3);
    mobile_jianyong->addSkill(new MobileQiaoshui);
    mobile_jianyong->addSkill(new MobileQiaoshuiTargetMod);
    mobile_jianyong->addSkill(new MobileZongshih);
    related_skills.insertMulti("mobileqiaoshui", "#mobileqiaoshui-target");

    General *mobile_zhuran = new General(this, "mobile_zhuran", "wu", 4);
    mobile_zhuran->addSkill(new MobileDanshou);
    mobile_zhuran->addSkill(new MobileDanshouRecord);
    related_skills.insertMulti("mobiledanshou", "#mobiledanshou-record");

    General *mobile_panzhangmazhong = new General(this, "mobile_panzhangmazhong", "wu", 4);
    mobile_panzhangmazhong->addSkill(new MobileDuodao);
    mobile_panzhangmazhong->addSkill(new MobileAnjian);

    General *mobile_fuhuanghou = new General(this, "mobile_fuhuanghou", "qun", 3, false);
    mobile_fuhuanghou->addSkill(new MobileZhuikong);
    mobile_fuhuanghou->addSkill(new MobileZhuikongProhibit);
    mobile_fuhuanghou->addSkill(new MobileQiuyuan);
    related_skills.insertMulti("mobiledanshou", "#mobilezhuikong");

    General *mobile_guohuai = new General(this, "mobile_guohuai", "wei", 4);
    mobile_guohuai->addSkill(new MobileJingce);
    mobile_guohuai->addSkill(new MobileJingceRecord);
    related_skills.insertMulti("mobilejingce", "#mobilejingce-record");

    General *mobile_chenqun = new General(this, "mobile_chenqun", "wei", 3);
    mobile_chenqun->addSkill(new MobileDingpin);
    mobile_chenqun->addSkill("faen");

    General *mobile_zhoucang = new General(this, "mobile_zhoucang", "shu", 4);
    mobile_zhoucang->addSkill(new MobileZhongyong);
    mobile_zhoucang->addSkill(new MobileZhongyongEffect);
    mobile_zhoucang->addSkill(new MobileZhongyongRemove);
    related_skills.insertMulti("mobilezhongyong", "#mobilezhongyong-effect");
    related_skills.insertMulti("mobilezhongyong", "#mobilezhongyong-remove");

    General *mobile_guyong = new General(this, "mobile_guyong", "wu", 3);
    mobile_guyong->addSkill(new MobileShenxing);
    mobile_guyong->addSkill(new MobileBingyi);

    General *mobile_caifuren = new General(this, "mobile_caifuren", "qun", 3, false);
    mobile_caifuren->addSkill(new MobileQieting);
    mobile_caifuren->addSkill(new FakeMoveSkill("mobileqieting"));
    mobile_caifuren->addSkill("xianzhou");
    related_skills.insertMulti("mobileqieting", "#mobileqieting-fake-move");

    General *mobile_jushou = new General(this, "mobile_jushou", "qun", 3);
    mobile_jushou->addSkill(new MobileJianying);
    mobile_jushou->addSkill(new MobileJianyingTargetMod);
    mobile_jushou->addSkill("shibei");
    related_skills.insertMulti("mobilejianying", "#mobilejianying-target");

    General *mobile_sunxiu = new General(this, "mobile_sunxiu$", "wu", 3);
    mobile_sunxiu->addSkill(new MobileYanzhu);
    mobile_sunxiu->addSkill(new MobileXingxue);
    mobile_sunxiu->addSkill("zhaofu");

    addMetaObject<MobileQingjianCard>();
    addMetaObject<MobileQiangxiCard>();
    addMetaObject<MobileNiepanCard>();
    addMetaObject<MobileZaiqiCard>();
    addMetaObject<MobilePoluCard>();
    addMetaObject<MobileTiaoxinCard>();
    addMetaObject<MobileZhijianCard>();
    addMetaObject<MobileFangquanCard>();
    addMetaObject<MobileGanluCard>();
    addMetaObject<MobileJieyueCard>();
    addMetaObject<MobileAnxuCard>();
    addMetaObject<MobileGongqiCard>();
    addMetaObject<MobileZongxuanCard>();
    addMetaObject<MobileZongxuanPutCard>();
    addMetaObject<MobileJunxingCard>();
    addMetaObject<MobileMiejiCard>();
    addMetaObject<MobileMiejiDiscardCard>();
    addMetaObject<MobileXianzhenCard>();
    addMetaObject<MobileQiaoshuiCard>();
    addMetaObject<MobileZongshihCard>();
    addMetaObject<MobileDingpinCard>();
    addMetaObject<MobileShenxingCard>();
    addMetaObject<MobileBingyiCard>();
    addMetaObject<MobileJianyingCard>();
    addMetaObject<MobileYanzhuCard>();
    addMetaObject<MobileXingxueCard>();
}

ADD_PACKAGE(MobileJXTP)
