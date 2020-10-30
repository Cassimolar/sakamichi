#include "bei.h"
#include "skill.h"
#include "standard.h"
#include "clientplayer.h"
#include "engine.h"
#include "settings.h"
#include "standard-skillcards.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "yjcm2013.h"

class JinXijue : public TriggerSkill
{
public:
    JinXijue() : TriggerSkill("jinxijue")
    {
        events << GameStart << EventPhaseChanging << DrawNCards;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == DrawNCards)
            return 1;
        return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GameStart) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&jxjjue", 4);
        } else if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            int damage = player->getMark("damage_point_round");
            if (damage <= 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&jxjjue", damage);
        } else {
            if (player->getMark("&jxjjue") <= 0) return false;
            QList<ServerPlayer *> targets;
            foreach(ServerPlayer *p, room->getOtherPlayers(player))
                if (p->getHandcardNum() >= player->getHandcardNum())
                    targets << p;
            int num = qMin(targets.length(), data.toInt());
            foreach(ServerPlayer *p, room->getOtherPlayers(player))
                p->setFlags("-TuxiTarget");

            if (num > 0) {
                room->setPlayerMark(player, "tuxi", num);
                int count = 0;
                if (room->askForUseCard(player, "@@tuxi", "@tuxi-card:::" + QString::number(num))) {
                    player->loseMark("&jxjjue");
                    foreach(ServerPlayer *p, room->getOtherPlayers(player))
                        if (p->hasFlag("TuxiTarget")) count++;
                } else {
                    room->setPlayerMark(player, "tuxi", 0);
                }
                data = data.toInt() - count;
            }
        }
        return false;
    }
};

class JinXijueEffect : public TriggerSkill
{
public:
    JinXijueEffect() : TriggerSkill("#jinxijue-effect")
    {
        events << AfterDrawNCards << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            Room *room = player->getRoom();
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill("jinxijue") || p->getMark("&jxjjue") <= 0 || !p->canDiscard(p, "h")) continue;
                if (room->askForCard(p, ".Basic", "@xiaoguo", QVariant(), "xiaoguo")) {
                    p->loseMark("&jxjjue");
                    room->broadcastSkillInvoke("xiaoguo", 1);
                    if (!room->askForCard(player, ".Equip", "@xiaoguo-discard", QVariant())) {
                        room->broadcastSkillInvoke("xiaoguo", 2);
                        room->damage(DamageStruct("xiaoguo", p, player));
                    } else {
                        room->broadcastSkillInvoke("xiaoguo", 3);
                        if (p->isAlive())
                            p->drawCards(1, "xiaoguo");
                    }
                }
            }
        } else {
            if (player->getMark("tuxi") == 0) return false;
            room->setPlayerMark(player, "tuxi", 0);

            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->hasFlag("TuxiTarget")) {
                    p->setFlags("-TuxiTarget");
                    targets << p;
                }
            }
            foreach (ServerPlayer *p, targets) {
                if (!player->isAlive())
                    break;
                if (p->isAlive() && !p->isKongcheng()) {
                    int card_id = room->askForCardChosen(player, p, "h", "tuxi");

                    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                    room->obtainCard(player, Sanguosha->getCard(card_id), reason, false);
                }
            }
        }
        return false;
    }
};

class JinBaoQie : public TriggerSkill
{
public:
    JinBaoQie() : TriggerSkill("jinbaoqie")
    {
        events << Appear;
        frequency = Compulsory;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        QList<int> treasure, list = room->getDrawPile() + room->getDiscardPile();
        foreach (int id, list) {
            if (!Sanguosha->getCard(id)->isKindOf("Treasure")) continue;
            treasure << id;
        }
        if (treasure.isEmpty()) return false;
        int id = treasure.at(qrand() % treasure.length());
        room->obtainCard(player, id);
        if (room->getCardOwner(id) != player || room->getCardPlace(id) != Player::PlaceHand) return false;
        const Card *card = Sanguosha->getCard(id);
        if (!card->isKindOf("Treasure") || !player->canUse(card)) return false;
        if (!player->askForSkillInvoke(this, QString("jinbaoqie_use:%1").arg(card->objectName())), false) return false;
        room->useCard(CardUseStruct(card, player, player));
        return false;
    }
};

JinYishiCard::JinYishiCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void JinYishiCard::onUse(Room *, const CardUseStruct &) const
{
}

class JinYishiVS : public OneCardViewAsSkill
{
public:
    JinYishiVS() : OneCardViewAsSkill("jinyishi")
    {
        response_pattern = "@@jinyishi";
        expand_pile = "#jinyishi";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return Self->getPile("#jinyishi").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const Card *originalCard) const
    {
        JinYishiCard *c = new JinYishiCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class JinYishi : public TriggerSkill
{
public:
    JinYishi() : TriggerSkill("jinyishi")
    {
        events << CardsMoveOneTime;
        view_as_skill = new JinYishiVS;
    }


    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || room->getCurrent()->isDead() || player->getMark("jinyishi-Clear") > 0) return false;
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from == player || move.from->getPhase() != Player::Play || !move.from_places.contains(Player::PlaceHand))
            return false;

        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            int i = 0;
            QVariantList dis;
            foreach (int card_id, move.card_ids) {
                if (move.from_places[i] == Player::PlaceHand && room->getCardPlace(card_id) == Player::DiscardPile)
                    dis << card_id;
                i++;
            }
            if (dis.isEmpty()) return false;
            QList<int> discard = VariantList2IntList(dis);
            player->tag["jinyishi_from"] = QVariant::fromValue((ServerPlayer *)move.from);
            room->notifyMoveToPile(player, discard, objectName(), Player::DiscardPile, true);
            const Card *card = room->askForUseCard(player, "@@jinyishi", "@jinyishi:" + move.from->objectName(), -1, Card::MethodNone);
            room->notifyMoveToPile(player, discard, objectName(), Player::DiscardPile, false);
            player->tag.remove("jinyishi_from");
            if (!card) return false;

            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(player, objectName());

            room->addPlayerMark(player, "jinyishi-Clear");
            room->obtainCard((ServerPlayer *)move.from, card);
            if (player->isAlive()) {
                discard.removeOne(card->getSubcards().first());
                if (discard.isEmpty()) return false;
                DummyCard get(discard);
                room->obtainCard(player, &get);
            }
        }
        return false;
    }
};

JinShiduCard::JinShiduCard()
{
    will_throw = false;
    handling_method = Card::MethodPindian;
}

bool JinShiduCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void JinShiduCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;
    bool pindian = effect.from->pindian(effect.to, "jinshidu");
    if (!pindian) return;

    Room *room = effect.from->getRoom();
    DummyCard *handcards = effect.to->wholeHandCards();
    room->obtainCard(effect.from, handcards, false);
    delete handcards;

    if (effect.from->isDead() || effect.to->isDead()) return;
    int give = floor(effect.from->getHandcardNum() / 2);
    if (give <= 0) return;
    const Card *card = room->askForExchange(effect.from, "jinshidu", give, give, false, QString("jinshidu-give:%1::%2").arg(effect.to->objectName())
                                            .arg(QString::number(give)));
    room->giveCard(effect.from, effect.to, card, "jinshidu");
    delete card;
}

class JinShidu : public ZeroCardViewAsSkill
{
public:
    JinShidu() : ZeroCardViewAsSkill("jinshidu")
    {
    }

    const Card *viewAs() const
    {
        return new JinShiduCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canPindian() && !player->hasUsed("JinShiduCard");
    }
};

class JinTaoyin : public TriggerSkill
{
public:
    JinTaoyin() : TriggerSkill("jintaoyin")
    {
        events << Appear;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent(true) || room->getCurrent() == player) return false;
        if (!player->askForSkillInvoke(this, room->getCurrent())) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(room->getCurrent(), "&jintaoyin-Clear");
        room->addMaxCards(room->getCurrent(), -2);
        return false;
    }
};

class JinYimie : public TriggerSkill
{
public:
    JinYimie() : TriggerSkill("jinyimie")
    {
        events << DamageCaused;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("jinyimie-Clear") > 0) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to == player || damage.to->isDead()) return false;
        int n = damage.to->getHp() - damage.damage;
        if (n < 0)
            n = 0;
        if (!player->askForSkillInvoke(this, QString("jinyimie:%1::%2").arg(damage.to->objectName()).arg(QString::number(n)))) return false;
        room->broadcastSkillInvoke(objectName());
        room->addPlayerMark(player, "jinyimie-Clear");
        damage.tips << "jinyimie_damage_" + QString::number(n)
                    << "jinyimie_from_" + player->objectName()
                    <<"jinyimie_to_" + damage.to->objectName();
        room->loseHp(player);
        damage.damage += n;
        data = QVariant::fromValue(damage);
        return false;
    }
};

class JinYimieRecover : public TriggerSkill
{
public:
    JinYimieRecover() : TriggerSkill("#jinyimie-recover")
    {
        events << DamageComplete;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.tips.contains("jinyimie_to_" + player->objectName())) return false;
        int n = -1;
        ServerPlayer *from = NULL;
        foreach (QString tip, damage.tips) {
            if (tip.startsWith("jinyimie_damage_")) {
                QStringList tips = tip.split("_");
                if (tips.length() < 3) continue;
                n = tips.last().toInt();
            } else if (tip.startsWith("jinyimie_from_")) {
                QStringList tips = tip.split("_");
                if (tips.length() < 3) continue;
                from = room->findPlayerByObjectName(tips.last(), true);
            }

            if (n >= 0 && from) break;
        }
        if (n < 0 || !from) return false;

        int recover = qMin(player->getMaxHp() - player->getHp(), n);
        if (recover <= 0) return false;
        if (from->isDead()) from = NULL;
        room->recover(player, RecoverStruct(from, NULL, recover));
        return false;
    }
};

class JinTairan : public TriggerSkill
{
public:
    JinTairan() : TriggerSkill("jintairan")
    {
        events << EventPhaseStart << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            int mark = player->getMark("&jintairanrecover");
            QVariantList list = player->tag["jintairan_ids"].toList();
            if (mark > 0 || !list.isEmpty())
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            room->setPlayerMark(player, "&jintairanrecover", 0);
            room->setPlayerMark(player, "&jintairan+draw", 0);

            if (mark > 0)
                room->loseHp(player, mark);
            if (player->isDead()) return false;

            if (list.isEmpty()) return false;
            player->tag.remove("jintairan_ids");
            DummyCard dummy;
            foreach (int id, player->handCards()) {
                if (!list.contains(QVariant(id))) continue;
                dummy.addSubcard(id);
            }
            if (dummy.subcardsLength() > 0)
                room->throwCard(&dummy, player);
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            if (player->getLostHp() > 0 || player->getHandcardNum() < player->getMaxCards())
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);

            if (player->getLostHp() > 0){
                int lost = player->getMaxHp() - player->getHp();
                room->addPlayerMark(player, "&jintairanrecover", lost);
                room->recover(player, RecoverStruct(player, NULL, lost));
            }
            if (player->getHandcardNum() < player->getMaxCards()) {
                QList<int> draws = room->drawCardsList(player, player->getMaxCards() - player->getHandcardNum());

                QVariantList list = player->tag["jintairan_ids"].toList();
                foreach (int id, draws) {
                    if (list.contains(QVariant(id))) continue;
                    list << id;
                }

                player->tag["jintairan_ids"] = list;
                room->addPlayerMark(player, "&jintairan+draw", draws.length());
            }
        }
        return false;
    }
};

class JinTairanClear : public TriggerSkill
{
public:
    JinTairanClear() : TriggerSkill("#jintairan-clear")
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
        if (data.toString() != "jintairan") return false;
        room->setPlayerMark(player, "&jintairan", 0);
        player->tag.remove("jintairan_ids");
        return false;
    }
};

JinRuilveGiveCard::JinRuilveGiveCard()
{
    m_skillName = "jinruilve_give";
    will_throw = false;
    mute = true;
}

bool JinRuilveGiveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self != to_select && to_select->hasLordSkill("jinruilve") && to_select->getMark("jinruilve-PlayClear") <= 0;
}

void JinRuilveGiveCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.to, "jinruilve-PlayClear");
    if (effect.to->isWeidi()) {
        room->broadcastSkillInvoke("weidi");
        room->notifySkillInvoked(effect.to, "weidi");
    }
    else {
        room->broadcastSkillInvoke("jinruilve");
        room->notifySkillInvoked(effect.to, "jinruilve");
    }
    room->giveCard(effect.from, effect.to, this, "jinruilve", true);
}

class JinRuilveGive : public OneCardViewAsSkill
{
public:
    JinRuilveGive() : OneCardViewAsSkill("jinruilve_give")
    {
        attached_lord_skill = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        return to_select->isKindOf("Slash") || (to_select->isDamageCard() && to_select->isKindOf("TrickCard"));
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return hasTarget(player) && player->getKingdom() == "jin";
    }

    bool hasTarget(const Player *player) const
    {
        QList<const Player *> as = player->getAliveSiblings();
        foreach (const Player *p, as) {
            if (p->hasLordSkill("jinruilve") && p->getMark("jinruilve-PlayClear") <= 0)
                return true;
        }
        return false;
    }

    const Card *viewAs(const Card *card) const
    {
        JinRuilveGiveCard *c = new JinRuilveGiveCard;
        c->addSubcard(card);
        return c;
    }
};

class JinRuilve : public TriggerSkill
{
public:
    JinRuilve() : TriggerSkill("jinruilve$")
    {
        events << GameStart << EventAcquireSkill;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if ((event == GameStart && player->isLord()) || (event == EventAcquireSkill && data.toString() == objectName())) {
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
                if (!p->hasSkill("jinruilve_give"))
                    room->attachSkillToPlayer(p, "jinruilve_give");
            }
        }
        return false;
    }
};

class JinHuirong : public TriggerSkill
{
public:
    JinHuirong() : TriggerSkill("jinhuirong")
    {
        events << Appear;
        frequency = Compulsory;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@jinhuirong-invoke", false, true);
        room->broadcastSkillInvoke(objectName());
        if (target->isDead()) return false;
        if (target->getHandcardNum() > target->getHp())
            room->askForDiscard(target, objectName(), target->getHandcardNum() - target->getHp(), target->getHandcardNum() - target->getHp());
        else if (target->getHandcardNum() < target->getHp()) {
            int num = qMin(5, target->getHp()) - target->getHandcardNum();
            target->drawCards(num, objectName());
        }
        return false;
    }
};

class JinCiwei : public TriggerSkill
{
public:
    JinCiwei() : TriggerSkill("jinciwei")
    {
        events << CardUsed << CardResponded << JinkEffect << NullificationEffect;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == JinkEffect || event == NullificationEffect) {
            if (!player->hasFlag("jinciwei_wuxiao")) return false;
            room->setPlayerFlag(player, "-jinciwei_wuxiao");
            return true;
        }

        if (player->getPhase() == Player::NotActive) return false;
        const Card *card = NULL;
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("SkillCard"))
                room->addPlayerMark(player, "jinciwei_use_time-Clear");
            if (use.card->isKindOf("BasicCard") || use.card->isNDTrick())
                card = use.card;
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse) return false;
            if (!res.m_card->isKindOf("SkillCard"))
                room->addPlayerMark(player, "jinciwei_use_time-Clear");
            if (res.m_card->isKindOf("BasicCard") || res.m_card->isNDTrick())
                card = res.m_card;
        }
        if (!card || card->isKindOf("SkillCard") || !(card->isKindOf("BasicCard") || card->isNDTrick())) return false;

        if (player->getMark("jinciwei_use_time-Clear") != 2) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "he")) continue;
            p->tag["jinciwei-player"] = QVariant::fromValue(player);
            const Card *_card = room->askForCard(p, "..", QString("@jinciwei-discard:%1::%2").arg(player->objectName()).arg(card->objectName()),
                               data, objectName());
            p->tag.remove("jinciwei-player");
            if (!_card) continue;
            room->broadcastSkillInvoke(objectName());
            if (event == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                if (use.card->isKindOf("Nullification"))
                    room->setPlayerFlag(player, "jinciwei_wuxiao");
                else {
                    use.nullified_list << "_ALL_TARGETS";
                    data = QVariant::fromValue(use);
                }

            } else
                room->setPlayerFlag(player, "jinciwei_wuxiao");
        }

        return false;
    }
};

class JinCaiyuan : public TriggerSkill
{
public:
    JinCaiyuan() : TriggerSkill("jincaiyuan")
    {
        events << HpChanged << EventPhaseStart << EventPhaseChanging;
        frequency = Compulsory;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == HpChanged)
            room->setPlayerMark(player, "jincaiyuan_hpchanged", 1);
        else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Finish) return false;
            if (player->getMark("jincaiyuan_hpchanged") > 0) return false;
            if (!player->hasSkill(this) || !player->tag["FengjiLastTurn"].toBool()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->drawCards(2, objectName());
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setPlayerMark(player, "jincaiyuan_hpchanged", 0);
        }
        return false;
    }
};

class JinZhuoshengVS : public ZeroCardViewAsSkill
{
public:
    JinZhuoshengVS() : ZeroCardViewAsSkill("jinzhuosheng")
    {
        response_pattern = "@@jinzhuosheng!";
    }

    const Card *viewAs() const
    {
        return new ExtraCollateralCard;
    }
};

class JinZhuosheng : public TriggerSkill
{
public:
    JinZhuosheng() : TriggerSkill("jinzhuosheng")
    {
        events << CardUsed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || (use.card->isVirtualCard() && use.card->subcardsLength() != 1)) return false;
        int id = use.card->getEffectiveId();
        QStringList ids = player->property("jinzhuosheng_ids").toString().split("+");
        if (!ids.contains(QString::number(id))) return false;

        if (use.card->isKindOf("EquipCard")) {
            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(objectName());
            player->drawCards(1, objectName());
        } else if (use.card->isKindOf("BasicCard")) {
            if (!use.m_addHistory) return false;
            room->addPlayerHistory(player, use.card->getClassName(), -1);
            use.m_addHistory = false;
            data = QVariant::fromValue(use);
        } else if (use.card->isNDTrick()) {
            if (use.card->isKindOf("Nullification")) return false;

            QList<ServerPlayer *> available_targets;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                if (use.card->isKindOf("AOE") && p == use.from) continue;
                if (use.card->targetFixed())
                    available_targets << p;
                else {
                    if (use.card->targetFilter(QList<const Player *>(), p, player))
                        available_targets << p;
                }
            }
            QStringList choices;
            choices << "cancel";
            if (use.to.length() > 1) choices.prepend("remove");
            if (!available_targets.isEmpty()) choices.prepend("add");
            if (choices.length() == 1) return false;

            QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
            if (choice == "cancel")
                return false;
            else if (choice == "add") {
                ServerPlayer *extra = NULL;
                if (!use.card->isKindOf("Collateral"))
                    extra = room->askForPlayerChosen(player, available_targets, objectName(), "@qiaoshui-add:::" + use.card->objectName());
                else {
                    QStringList tos;
                    foreach(ServerPlayer *t, use.to)
                        tos.append(t->objectName());
                    room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", tos.join("+"));
                    room->askForUseCard(player, "@@jinzhuosheng!", "@qiaoshui-add:::collateral");
                    room->setPlayerProperty(player, "extra_collateral", QString());
                    room->setPlayerProperty(player, "extra_collateral_current_targets", QString("+"));
                    foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
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
                                && (!(p == player && p->hasSkill("kongcheng") && p->isLastHandCard(use.card, true)))) {
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
                log.from = player;
                log.to << extra;
                log.card_str = use.card->toString();
                log.arg = "jinzhuosheng";
                room->sendLog(log);
                room->broadcastSkillInvoke(objectName());
                room->notifySkillInvoked(player, objectName());
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), extra->objectName());

                if (use.card->isKindOf("Collateral")) {
                    ServerPlayer *victim = extra->tag["collateralVictim"].value<ServerPlayer *>();
                    if (victim) {
                        LogMessage log;
                        log.type = "#CollateralSlash";
                        log.from = player;
                        log.to << victim;
                        room->sendLog(log);
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, extra->objectName(), victim->objectName());
                    }
                }
            } else {
                ServerPlayer *removed = room->askForPlayerChosen(player, use.to, "jinzhuosheng", "@qiaoshui-remove:::" + use.card->objectName());
                use.to.removeOne(removed);

                LogMessage log;
                log.type = "#QiaoshuiRemove";
                log.from = player;
                log.to << removed;
                log.card_str = use.card->toString();
                log.arg = "jinzhuosheng";
                room->sendLog(log);
                room->broadcastSkillInvoke(objectName());
                room->notifySkillInvoked(player, objectName());
            }
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class JinZhuoshengTargetMod : public TargetModSkill
{
public:
    JinZhuoshengTargetMod() : TargetModSkill("#jinzhuosheng-target")
    {
        frequency = NotFrequent;
        pattern = "BasicCard";
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (card->isVirtualCard() && card->subcardsLength() != 1) return 0;
        int id = card->getEffectiveId();
        QStringList ids = from->property("jinzhuosheng_ids").toString().split("+");
        if (!ids.contains(QString::number(id))) return 0;

        if (from->hasSkill("jinzhuosheng"))
            return 1000;
        return 0;
    }
};

class JinZhuoshengRecord : public TriggerSkill
{
public:
    JinZhuoshengRecord() : TriggerSkill("#jinzhuosheng-record")
    {
        events << CardsMoveOneTime << RoundStart;
        global = true;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == RoundStart)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == RoundStart)
            room->setPlayerProperty(player, "jinzhuosheng_ids", QString());
        else {
            if (room->getTag("FirstRound").toBool()) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to != player || move.to_place != Player::PlaceHand) return false;
            if (move.reason.m_skillName == "jinzhuosheng") return false;
            QStringList ids = move.to->property("jinzhuosheng_ids").toString().split("+");
            int i = -1;
            foreach (int id, move.card_ids) {
                i++;
                if (move.from == player && move.from_places.at(i) == Player::PlaceHand) continue;
                if (ids.contains(QString::number(id))) continue;
                ids << QString::number(id);
            }
            room->setPlayerProperty((ServerPlayer *)move.to, "jinzhuosheng_ids", ids.join("+"));
        }
        return false;
    }
};

BeiPackage::BeiPackage()
    : Package("bei")
{
    General *jin_zhanghuyuechen = new General(this, "jin_zhanghuyuechen", "jin", 4);
    jin_zhanghuyuechen->addSkill(new JinXijue);
    jin_zhanghuyuechen->addSkill(new JinXijueEffect);
    related_skills.insertMulti("jinxijue", "#jinxijue-effect");

    General *jin_xiahouhui = new General(this, "jin_xiahouhui", "jin", 3, false);
    jin_xiahouhui->addSkill(new JinBaoQie);
    jin_xiahouhui->addSkill(new JinYishi);
    jin_xiahouhui->addSkill(new JinShidu);

    General *jin_simashi = new General(this, "jin_simashi$", "jin", 4, true, false, false, 3);
    jin_simashi->addSkill(new JinTaoyin);
    jin_simashi->addSkill(new JinYimie);
    jin_simashi->addSkill(new JinYimieRecover);
    jin_simashi->addSkill(new JinTairan);
    jin_simashi->addSkill(new JinTairanClear);
    jin_simashi->addSkill(new JinRuilve);
    related_skills.insertMulti("jinyimie", "#jinyimie-recover");
    related_skills.insertMulti("jintairan", "#jintairan-clear");

    General *jin_yanghuiyu = new General(this, "jin_yanghuiyu", "jin", 3, false);
    jin_yanghuiyu->addSkill(new JinHuirong);
    jin_yanghuiyu->addSkill(new JinCiwei);
    jin_yanghuiyu->addSkill(new JinCaiyuan);

    General *jin_shibao = new General(this, "jin_shibao", "jin", 4);
    jin_shibao->addSkill(new JinZhuosheng);
    jin_shibao->addSkill(new JinZhuoshengTargetMod);
    jin_shibao->addSkill(new JinZhuoshengRecord);
    related_skills.insertMulti("jinzhuosheng", "#jinzhuosheng-target");
    related_skills.insertMulti("jinzhuosheng", "#jinzhuosheng-record");

    addMetaObject<JinYishiCard>();
    addMetaObject<JinShiduCard>();
    addMetaObject<JinRuilveGiveCard>();

    skills << new JinRuilveGive;
}

ADD_PACKAGE(Bei)
