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
        rangefix += card->getRange() - Self->getAttackRange(false);;
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
            ServerPlayer *to = room->askForPlayerChosen(xunyu, room->getAlivePlayers(), objectName(), "mobilejieming-invoke", true, true);
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

    if (source->getLostHp() > 0) {
        int n = qMin(3 - source->getHp(), source->getMaxHp() - source->getHp());
        room->recover(source, RecoverStruct(source, NULL, n));
    }

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

            if (pangtong->getLostHp() > 0) {
                int n = qMin(3 - pangtong->getHp(), pangtong->getMaxHp() - pangtong->getHp());
                room->recover(pangtong, RecoverStruct(pangtong, NULL, n));
            }

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
        if (selected.isEmpty())
            return !to_select->isEquipped() && !suits.contains(to_select->getSuitString());
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
            const Card *card = Sanguosha->getCard(use.card->getSubcards().first());
            QStringList suits = player->property("mobileluanji_suitstring").toString().split("+");
            if (!suits.contains(card->getSuitString())) {
                suits << card->getSuitString();
                room->setPlayerProperty(player, "mobileluanji_suitstring", suits.join("+"));
            }
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
    if (effect.from->isAlive() && effect.from->getLostHp() > 0)
        choices << "recover";
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
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            if (!room->getCurrent() || room->getCurrent()->getPhase() == Player::NotActive) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to_place != Player::DiscardPile) return false;
            foreach (int id, move.card_ids) {
                if (Sanguosha->getCard(id)->getSuit() == Card::Heart)
                    room->addPlayerMark(player, "mobilezaiqi-Clear");
            }
        } else {
            if (player->getPhase() != Player::Discard) return false;
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
            QString choice = room->askForChoice(caopi, objectName(), choices.join("+"));
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
            "mobilefangzhu-invoke", caopi->getMark("JilveEvent") != int(Damaged), true);
        if (to) {
            if (caopi->hasInnateSkill("fangzhu") || !caopi->hasSkill("jilve")) {
                room->broadcastSkillInvoke("mobilefangzhu");
            } else
                room->broadcastSkillInvoke("jilve", 2);
            int losthp = caopi->getLostHp();
            if (losthp <= 0) return;
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
        if (damage.card && damage.card->isKindOf("Slash")
            && (damage.card->isRed() || damage.card->hasFlag("drank"))) {
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
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return PhaseChangeSkill::triggerable(target)
            && target->getMark("mobilezhiji") == 0
            && target->getPhase() == Player::Start
            && target->isKongcheng();
    }

    bool onPhaseChange(ServerPlayer *jiangwei) const
    {
        Room *room = jiangwei->getRoom();
        room->notifySkillInvoked(jiangwei, objectName());

        LogMessage log;
        log.type = "#ZhijiWake";
        log.from = jiangwei;
        log.arg = objectName();
        room->sendLog(log);

        room->broadcastSkillInvoke(objectName());

        room->doSuperLightbox("mobile_jiangwei", "mobilezhiji");

        room->setPlayerMark(jiangwei, "mobilezhiji", 1);
        if (room->changeMaxHpForAwakenSkill(jiangwei)) {
            if (jiangwei->isWounded() && room->askForChoice(jiangwei, objectName(), "recover+draw") == "recover")
                room->recover(jiangwei, RecoverStruct(jiangwei));
            else
                room->drawCards(jiangwei, 2, objectName());
            if (!jiangwei->hasSkill("tenyearguanxing"))
                room->acquireSkill(jiangwei, "tenyearguanxing");
        }

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

    bool triggerable(const ServerPlayer *target) const
    {
        return PhaseChangeSkill::triggerable(target)
            && target->getMark("mobilehunzi") == 0
            && target->getPhase() == Player::Start
            && target->getHp() <= 2;
    }

    bool onPhaseChange(ServerPlayer *sunce) const
    {
        Room *room = sunce->getRoom();
        room->notifySkillInvoked(sunce, objectName());

        LogMessage log;
        log.type = "#HunziWake";
        log.from = sunce;
        log.arg = QString::number(sunce->getHp());
        log.arg2 = objectName();
        room->sendLog(log);

        room->broadcastSkillInvoke(objectName());

        room->doSuperLightbox("mobile_sunce", "mobilehunzi");

        room->setPlayerMark(sunce, "mobilehunzi", 1);
        if (room->changeMaxHpForAwakenSkill(sunce)) {
            QStringList skills;
            if (!sunce->hasSkill("yingzi"))
                skills << "yingzi";
            if (!sunce->hasSkill("yinghun"))
                skills << "yinghun";
            if (skills.isEmpty()) return false;
            room->handleAcquireDetachSkills(sunce, skills.join("|"));
        }
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

                        p->tag["mobilepojun"] = vm;
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
        if (player->isKongcheng()) return false;

        Room *room = player->getRoom();
        QList<int> list = player->handCards() + player->getEquipsId();
        ServerPlayer *target = room->askForYijiP(player, list, objectName(), false, false, true, 1,
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

class MobileChengzhang : public TriggerSkill
{
public:
    MobileChengzhang() : TriggerSkill("mobilechengzhang")
    {
        events << EventPhaseStart << Damaged << Damage;
        frequency = Wake;
        global = true;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive() && target->getMark(objectName()) <= 0;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (!player->hasSkill(this) || player->getPhase() != Player::Start) return false;
            int mark = player->getMark("&mobilechengzhang") + player->getMark("mobilechengzhang_num");
            if (mark < 7) return false;

            room->notifySkillInvoked(player, objectName());
            LogMessage log;
            log.type = "#MobilechengzhangWake";
            log.from = player;
            log.arg = QString::number(mark);
            log.arg2 = objectName();
            room->sendLog(log);
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
        } else {
            int n = data.value<DamageStruct>().damage;
            if (player->hasSkill(this))
                room->addPlayerMark(player, "&mobilechengzhang", n);
            else
                room->addPlayerMark(player, "mobilechengzhang_num", n);
        }
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
        events << CardUsed << DamageCaused << PreDamageDone << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            if (!TriggerSkill::triggerable(player)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->objectName() != "slash") return false;
            FireSlash *fire_slash = new FireSlash(use.card->getSuit(), use.card->getNumber());
            fire_slash->deleteLater();
            if (!use.card->isVirtualCard() || use.card->subcardsLength() > 0)
                fire_slash->addSubcard(use.card);
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
            if (can_use && room->askForSkillInvoke(player, "mobilelihuo", data)) {
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
                    room->moveCardTo(c, NULL, Player::DrawPile, reason, true);
                }
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                    if (!zongxuan_card.isEmpty())
                        room->notifyMoveToPile(player, zongxuan_card, objectName(), Player::DiscardPile, false);
                    throw triggerEvent;
                }
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

    Room * room = effect.from->getRoom();
    if (!room->askForDiscard(effect.to, "mobilejunxing", length, length, true, true)) {
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
        QStringList names = effect.from->property("mobilexianzhen_targets").toStringList();
        if (!names.contains(effect.to->objectName())) {
            names << effect.to->objectName();
            room->setPlayerProperty(effect.from, "mobilexianzhen_targets", names);
        }
        room->addPlayerMark(effect.to, "Armor_Nullified");
        room->insertAttackRangePair(effect.from, effect.to);;
        QStringList assignee_list = effect.from->property("extra_slash_specific_assignee").toString().split("+");
        assignee_list << effect.to->objectName();
        room->setPlayerProperty(effect.from, "extra_slash_specific_assignee", assignee_list.join("+"));
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
        events << EventPhaseChanging << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && !target->property("mobilexianzhen_targets").toStringList().isEmpty();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *gaoshun, QVariant &data) const
    {
        QStringList names = gaoshun->property("mobilexianzhen_targets").toStringList();
        QStringList assignee_list = gaoshun->property("extra_slash_specific_assignee").toString().split("+");

        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from != Player::Play) return false;
            if (gaoshun->getMark("mobilexianzhen_lose-PlayClear") > 0)
                room->removePlayerCardLimitation(gaoshun, "use", "Slash");

            foreach (QString name, names) {
                if (!assignee_list.contains(name)) continue;
                assignee_list.removeOne(name);
                ServerPlayer *target = room->findPlayerByObjectName(name, true);
                if (!target) continue;
                room->removeAttackRangePair(gaoshun, target);
                room->removePlayerMark(target, "Armor_Nullified");
            }
            room->setPlayerProperty(gaoshun, "mobilexianzhen_targets", QStringList());
            room->setPlayerProperty(gaoshun, "extra_slash_specific_assignee", assignee_list.join("+"));
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == gaoshun || !names.contains(death.who->objectName()) || !assignee_list.contains(death.who->objectName())) return false;
            names.removeOne(death.who->objectName());
            assignee_list.removeOne(death.who->objectName());
            room->removeAttackRangePair(gaoshun, death.who);
            room->setPlayerProperty(gaoshun, "mobilexianzhen_targets", names);
            room->setPlayerProperty(gaoshun, "extra_slash_specific_assignee", assignee_list.join("+"));
            room->removePlayerMark(death.who, "Armor_Nullified");
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
        pattern = "^Slash";
    }

    int getResidueNum(const Player *from, const Card *card, const Player *to) const
    {
        if (from->getMark("mobilexianzhen_from-PlayClear") > 0 && to->getMark("mobilexianzhen_to-PlayClear") > 0 && !card->isKindOf("SkillCard"))
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *to) const
    {
        if (from->getMark("mobilexianzhen_from-PlayClear") > 0 && to->getMark("mobilexianzhen_to-PlayClear") > 0 && !card->isKindOf("SkillCard"))
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

class MobileJinjiuEffect : public TriggerSkill
{
public:
    MobileJinjiuEffect() : TriggerSkill("#mobilejinjiu")
    {
        events << EventPhaseChanging << DamageInflicted << EventLoseSkill << EventAcquireSkill << Revived << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageInflicted) {
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
        } else if (event == EventPhaseChanging) {
            if (!player->hasSkill(this)) return false;
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::RoundStart) {
                foreach (ServerPlayer *p, room->getOtherPlayers(player))
                    room->setPlayerCardLimitation(p, "use", "Analeptic", true);
            } else if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getOtherPlayers(player))
                    room->removePlayerCardLimitation(p, "use", "Analeptic$1");
            }
        } else if (event == EventLoseSkill) {
            if (player->isDead() || player->getPhase() == Player::NotActive || data.toString() != objectName()) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                room->removePlayerCardLimitation(p, "use", "Analeptic$1");
        } else if (event == EventAcquireSkill) {
            if (player->isDead() || player->getPhase() == Player::NotActive || data.toString() != objectName()) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                room->setPlayerCardLimitation(p, "use", "Analeptic", true);
        } else if (event == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (!death.who->hasSkill(this)) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                room->removePlayerCardLimitation(p, "use", "Analeptic$1");
        } else if (event == Revived) {
            if (!room->hasCurrent() || room->getCurrent() == player || !room->getCurrent()->hasSkill(this)) return false;
            room->setPlayerCardLimitation(player, "use", "Analeptic", true);
        }
        return false;
    }
};

MobileJXTPPackage::MobileJXTPPackage()
    : Package("MobileJXTP")
{
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
    mobile_gaoshun->addSkill(new MobileJinjiuEffect);
    related_skills.insertMulti("mobilexianzhen", "#mobilexianzhen-clear");
    related_skills.insertMulti("mobilexianzhen", "#mobilexianzhen-target");
    related_skills.insertMulti("mobilejinjiu", "#mobilejinjiu");

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
}

ADD_PACKAGE(MobileJXTP)
