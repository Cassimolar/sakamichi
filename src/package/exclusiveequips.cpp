#include "exclusiveequips.h"
#include "client.h"
#include "engine.h"
#include "general.h"
#include "clientplayer.h"
#include "room.h"
#include "wrapped-card.h"
#include "roomthread.h"
#include "yjcm2013.h"

class HongduanqiangSkill : public WeaponSkill
{
public:
    HongduanqiangSkill() : WeaponSkill("_hongduanqiang")
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("_hongduanqiang-Clear") > 0) return false;

        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash") || !damage.by_user) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->setEmotion(player, "weapon/_hongduanqiang");
        room->addPlayerMark(player, "_hongduanqiang-Clear");

        JudgeStruct judge;
        judge.who = player;
        judge.reason = objectName();
        judge.pattern = ".";
        judge.play_animation = false;
        room->judge(judge);

        Card::Color color = (Card::Color)(judge.pattern.toInt());

        if (color == Card::Red)
            room->recover(player, RecoverStruct(player));
        else if (color == Card::Black)
            player->drawCards(2, objectName());
        return false;
    }
};

class HongduanqiangJudge : public TriggerSkill
{
public:
    HongduanqiangJudge() : TriggerSkill("#_hongduanqiang-judge")
    {
        events << FinishJudge;
        global = true;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != "_hongduanqiang") return false;
        judge->pattern = QString::number(int(judge->card->getColor()));
        return false;
    }
};

Hongduanqiang::Hongduanqiang(Suit suit, int number)
    : Weapon(suit, number, 3)
{
    setObjectName("_hongduanqiang");
}

class LiecuidaoTargetMod : public TargetModSkill
{
public:
    LiecuidaoTargetMod() : TargetModSkill("#_liecuidao-target")
    {
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        QList<int> ids;
        if (card->isVirtualCard() && card->subcardsLength() > 0)
            ids = card->getSubcards();
        else if (!card->isVirtualCard())
            ids << card->getEffectiveId();
        if (from->hasWeapon("_liecuidao") && (!(from->getWeapon() && ids.contains(from->getWeapon()->getEffectiveId()))
                                              || card->hasFlag("Global_SlashAvailabilityChecker")))
            return 1;
        else
            return 0;
    }
};

class LiecuidaoVS : public OneCardViewAsSkill
{
public:
    LiecuidaoVS() : OneCardViewAsSkill("_liecuidao")
    {
        response_pattern = "@@_liecuidao";
        filter_pattern = "..!";
    }

    bool viewFilter(const Card *to_select) const
    {
        return !(to_select->isEquipped() && to_select->objectName() == "_liecuidao");
    }

    const Card *viewAs(const Card *c) const
    {
        DummyCard *card = new DummyCard;
        card->setSkillName(objectName());
        card->addSubcard(c);
        return card;
    }
};

class LiecuidaoSkill : public WeaponSkill
{
public:
    LiecuidaoSkill() : WeaponSkill("_liecuidao")
    {
        events << DamageCaused;
        view_as_skill = new LiecuidaoVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("_liecuidao-Clear") >= 2) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash") || damage.chain || damage.transfer) return false;
        if (!player->canDiscard(player, "he")) return false;

        const Card *card = room->askForCard(player, "@@_liecuidao", "@_liecuidao:" + damage.to->objectName(), data, objectName());

        if (card) {
            room->setEmotion(player, "weapon/_liecuidao");
            room->addPlayerMark(player, "_liecuidao-Clear");
            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

Liecuidao::Liecuidao(Suit suit, int number)
    : Weapon(suit, number, 2)
{
    setObjectName("_liecuidao");
}

ShuibojianCard::ShuibojianCard()
{
    mute = true;
}

bool ShuibojianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return to_select->hasFlag("_shuibojian_canchoose") && targets.isEmpty();
}

void ShuibojianCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setEmotion(card_use.from, "weapon/_shuibojian");
    room->addPlayerMark(card_use.from, "_shuibojian-Clear");
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "_shuibojian_extratarget");
}

class ShuibojianVS : public ZeroCardViewAsSkill
{
public:
    ShuibojianVS() : ZeroCardViewAsSkill("_shuibojian")
    {
        response_pattern = "@@_shuibojian";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        if (Self->hasFlag("_shuibojian_now_use_collateral"))
            return new ExtraCollateralCard;
        else
            return new ShuibojianCard;
        return NULL;
    }
};

class ShuibojianSkill : public WeaponSkill
{
public:
    ShuibojianSkill() : WeaponSkill("_shuibojian")
    {
        events << PreCardUsed << CardsMoveOneTime;
        view_as_skill = new ShuibojianVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed && WeaponSkill::triggerable(player)) {
            if (!room->hasCurrent()) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            int n = player->getMark("_shuibojian-Clear");
            if (n >= 2) return false;
            if (use.card->isKindOf("Slash") || use.card->isNDTrick()) {
                if (use.card->isKindOf("Nullification")) return false;
                if (!use.card->isKindOf("Collateral")) {
                    bool canextra = false;
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (use.card->isKindOf("AOE") && p == player) continue;
                        if (use.to.contains(p) || room->isProhibited(player, p, use.card)) continue;
                        if (use.card->targetFixed()) {
                            canextra = true;
                            room->setPlayerFlag(p, "_shuibojian_canchoose");
                        } else {
                            if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                                canextra = true;
                                room->setPlayerFlag(p, "_shuibojian_canchoose");
                            }
                        }
                    }
                    if (canextra == false) return false;
                    player->tag["_shuibojianData"] = data;
                    if (!room->askForUseCard(player, "@@_shuibojian", "@_shuibojian:" + use.card->objectName())) {
                        player->tag.remove("_shuibojianData");
                        room->setPlayerMark(player, "_shuibojian_target_num-Clear", 0);
                        return false;
                    }
                    player->tag.remove("_shuibojianData");
                    room->setPlayerMark(player, "_shuibojian_target_num-Clear", 0);
                    QList<ServerPlayer *> add;
                    foreach(ServerPlayer *p, room->getAlivePlayers()) {
                        if (p->hasFlag("_shuibojian_canchoose"))
                            room->setPlayerFlag(p, "-_shuibojian_canchoose");
                        if (p->hasFlag("_shuibojian_extratarget")) {
                            room->setPlayerFlag(p,"-_shuibojian_extratarget");
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
                    log.arg = "_shuibojian";
                    room->sendLog(log);
                    room->notifySkillInvoked(player, "_shuibojian");
                    foreach(ServerPlayer *p, add)
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

                    room->sortByActionOrder(use.to);
                    data = QVariant::fromValue(use);
                } else if (use.card->isKindOf("Collateral")) {
                    for (int i = 1; i <= n; i++) {
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
                        room->setPlayerFlag(player, "_shuibojian_now_use_collateral");
                        room->askForUseCard(player, "@@_shuibojian", "@_shuibojian:" + use.card->objectName());
                        room->setPlayerFlag(player, "-_shuibojian_now_use_collateral");
                        room->setPlayerProperty(player, "extra_collateral", QString());
                        room->setPlayerProperty(player, "extra_collateral_current_targets", QString());
                        foreach(ServerPlayer *p, room->getAlivePlayers()) {
                            if (p->hasFlag("ExtraCollateralTarget")) {
                                room->setEmotion(player, "weapon/_shuibojian");
                                room->addPlayerMark(player, "_shuibojian-Clear");
                                room->setPlayerFlag(p, "-ExtraCollateralTarget");
                                LogMessage log;
                                log.type = "#QiaoshuiAdd";
                                log.from = player;
                                log.to << p;
                                log.card_str = use.card->toString();
                                log.arg = "_shuibojian";
                                room->sendLog(log);
                                room->notifySkillInvoked(player, "_shuibojian");
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
        } else if (player->hasFlag("_shuibojianRecover")) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from != player || !move.from_places.contains(Player::PlaceEquip))
                return false;
            for (int i = 0; i < move.card_ids.size(); i++) {
                if (move.from_places[i] != Player::PlaceEquip) continue;
                const Card *card = Sanguosha->getEngineCard(move.card_ids[i]);
                if (card->objectName() == objectName()) {
                    player->setFlags("-_shuibojianRecover");
                    if (player->isWounded()) {
                        LogMessage log;
                        log.type = "#TriggerEquipSkill";
                        log.from = player;
                        log.arg = objectName();
                        room->sendLog(log);
                        room->notifySkillInvoked(player, "_shuibojian");
                        room->setEmotion(player, "weapon/_shuibojian");
                    }
                    room->recover(player, RecoverStruct(NULL, card));
                }
            }
        }
        return false;
    }
};

Shuibojian::Shuibojian(Suit suit, int number)
    : Weapon(suit, number, 2)
{
    setObjectName("_shuibojian");
}

void Shuibojian::onUninstall(ServerPlayer *player) const
{
    if (player->isAlive() && player->hasWeapon(objectName(), false))
        player->setFlags("_shuibojianRecover");
}

class HunduwanbiSkill : public WeaponSkill
{
public:
    HunduwanbiSkill() : WeaponSkill("_hunduwanbi")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || use.to.isEmpty()) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead() || !WeaponSkill::triggerable(player)) return false;
            if (p->isDead()) continue;
            int mark = player->getMark("_hunduwanbi-Clear") + 1;
            if (!player->askForSkillInvoke(this, QString("_hunduwanbi:%1::%2").arg(p->objectName()).arg(mark))) continue;
            room->setEmotion(player, "weapon/_hunduwanbi");
            room->addPlayerMark(player, "_hunduwanbi-Clear");
            mark = qMin(mark, 5);
            if (mark > 0)
                room->loseHp(p, mark);
        }
        return false;
    }
};

Hunduwanbi::Hunduwanbi(Suit suit, int number)
    : Weapon(suit, number, 1)
{
    setObjectName("_hunduwanbi");
}

class TianleirenSkill : public WeaponSkill
{
public:
    TianleirenSkill() : WeaponSkill("_tianleiren")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || use.to.isEmpty()) return false;
        foreach (ServerPlayer *p, use.to) {
            if (player->isDead() || !WeaponSkill::triggerable(player)) return false;
            if (p->isDead()) continue;
            if (!player->askForSkillInvoke(this, p)) continue;
            room->setEmotion(player, "weapon/_tianleiren");

            int weapon_id = -1;
            if (player->getWeapon() && player->getWeapon()->objectName() == objectName()) {
                weapon_id = player->getWeapon()->getEffectiveId();
                room->setCardFlag(weapon_id, "using");
            }

            JudgeStruct judge;
            judge.who = p;
            judge.reason = objectName();
            judge.pattern = ".|black";
            judge.good = false;
            room->judge(judge);

            if (weapon_id > 0)
                room->setCardFlag(weapon_id, "-using");

            Card::Suit suit = (Card::Suit)(judge.pattern.toInt());

            if (suit == Card::Spade) {
                if (p->isAlive())
                    room->damage(DamageStruct(objectName(), NULL, p, 3, DamageStruct::Thunder));
            } else if (suit == Card::Club) {
                if (p->isAlive())
                    room->damage(DamageStruct(objectName(), NULL, p, 1, DamageStruct::Thunder));
                if (player->isAlive()) {
                    room->recover(player, RecoverStruct(player));
                    player->drawCards(1, objectName());
                }
            }
        }
        return false;
    }
};

class TianleirenJudge : public TriggerSkill
{
public:
    TianleirenJudge() : TriggerSkill("#_tianleiren-judge")
    {
        events << FinishJudge;
        global = true;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != "_tianleiren") return false;
        judge->pattern = QString::number(int(judge->card->getSuit()));
        return false;
    }
};


Tianleiren::Tianleiren(Suit suit, int number)
    : Weapon(suit, number, 4)
{
    setObjectName("_tianleiren");
}

class PilicheSkill : public WeaponSkill
{
public:
    PilicheSkill() : WeaponSkill("_piliche")
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead() || !damage.card || damage.card->isKindOf("SkillCard") || damage.card->isKindOf("DelayedTrick")) return false;

        DummyCard *dummy = new DummyCard;
        dummy->deleteLater();

        if (damage.to->getArmor() && player->canDiscard(damage.to, damage.to->getArmor()->getEffectiveId()))
            dummy->addSubcard(damage.to->getArmor()->getEffectiveId());
        if (damage.to->getDefensiveHorse() && player->canDiscard(damage.to, damage.to->getDefensiveHorse()->getEffectiveId()))
            dummy->addSubcard(damage.to->getDefensiveHorse()->getEffectiveId());
        if (dummy->subcardsLength() == 0) return false;
        if (!player->askForSkillInvoke(this, damage.to)) return false;
        room->setEmotion(player, "weapon/_piliche");
        room->throwCard(dummy, damage.to, damage.from);
        return false;
    }
};

Piliche::Piliche(Suit suit, int number)
    : Weapon(suit, number, 9)
{
    setObjectName("_piliche");
}

class SecondPilicheSkill : public WeaponSkill
{
public:
    SecondPilicheSkill() : WeaponSkill("_secondpiliche")
    {
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!player->canDiscard(damage.to, "e")) return false;

        DummyCard *dummy = new DummyCard;
        dummy->deleteLater();

        foreach (int id, damage.to->getEquipsId()) {
            if (player->canDiscard(damage.to, id))
                dummy->addSubcard(id);
        }

        if (dummy->subcardsLength() == 0) return false;
        if (!player->askForSkillInvoke(this, damage.to)) return false;
        room->setEmotion(player, "weapon/_secondpiliche");
        room->throwCard(dummy, damage.to, damage.from);
        return false;
    }
};

SecondPiliche::SecondPiliche(Suit suit, int number)
    : Weapon(suit, number, 9)
{
    setObjectName("_secondpiliche");
}

class SichengliangyuSkill : public TreasureSkill
{
public:
    SichengliangyuSkill() : TreasureSkill("_sichengliangyu")
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

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasTreasure(objectName())) continue;
            if (p->getHandcardNum() < p->getHp() && p->askForSkillInvoke(this)) {
                //room->setEmotion(p, "treasure/_sichengliangyu");
                p->drawCards(2, objectName());
                if (p->isAlive() && p->getTreasure() && p->getTreasure()->objectName() == objectName() &&
                        p->canDiscard(p, p->getTreasure()->getEffectiveId()))
                    room->throwCard(p->getTreasure(), NULL, p);
            }
        }
        return false;
    }
};

Sichengliangyu::Sichengliangyu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("_sichengliangyu");
}

class TiejixuanyuSkill : public TreasureSkill
{
public:
    TiejixuanyuSkill() : TreasureSkill("_tiejixuanyu")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("damage_point_round") <= 0 && target->canDiscard(target, "he");
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead() || !player->canDiscard(player, "he")) return false;
            if (p->isDead() || !p->hasTreasure(objectName())) continue;
            if (p->askForSkillInvoke(this, player)) {
                //room->setEmotion(p, "treasure/_tiejixuanyu");
                room->askForDiscard(player, objectName(), 2, 2, false, true);
                if (p->isAlive() && p->getTreasure() && p->getTreasure()->objectName() == objectName() &&
                        p->canDiscard(p, p->getTreasure()->getEffectiveId()))
                    room->throwCard(p->getTreasure(), NULL, p);
            }
        }
        return false;
    }
};

Tiejixuanyu::Tiejixuanyu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("_tiejixuanyu");
}

class FeilunzhanyuSkill : public TreasureSkill
{
public:
    FeilunzhanyuSkill() : TreasureSkill("_feilunzhanyu")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("_feilunzhanyu_used_notbasic-Clear") > 0 && !target->isNude();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead() || player->isNude()) return false;
            if (p->isDead() || !p->hasTreasure(objectName())) continue;
            if (p->askForSkillInvoke(this, player)) {
                //room->setEmotion(p, "treasure/_feilunzhanyu");

                const Card *card = room->askForExchange(player, objectName(), 1, 1, true, "@_feilunzhanyu-give:" + p->objectName());
                room->giveCard(player, p, card, objectName());
                delete card;

                if (p->isAlive() && p->getTreasure() && p->getTreasure()->objectName() == objectName() &&
                        p->canDiscard(p, p->getTreasure()->getEffectiveId()))
                    room->throwCard(p->getTreasure(), NULL, p);
            }
        }
        return false;
    }
};

class FeilunzhanyuRecord : public TriggerSkill
{
public:
    FeilunzhanyuRecord() : TriggerSkill("#_feilunzhanyu-record")
    {
        events << PreCardUsed;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || use.card->isKindOf("BasicCard")) return false;
        room->setPlayerMark(player, "_feilunzhanyu_used_notbasic-Clear", 1);
        return false;
    }
};

Feilunzhanyu::Feilunzhanyu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("_feilunzhanyu");
}

class QiongshuSkill : public TreasureSkill
{
public:
    QiongshuSkill() : TreasureSkill("_qiongshu")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        int num = damage.damage;
        if (!player->canDiscard(player, "he") || player->getCardCount() < num) return false;
        if (!room->askForDiscard(player, objectName(), num, num, true, true, "@_qiongshu-discard:" + QString::number(num), "^Qiongshu", objectName()))
            return false;
        //room->setEmotion(player, "treasure/_qiongshu");
        room->broadcastSkillInvoke(this);
        return true;
    }
};

Qiongshu::Qiongshu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("_qiongshu");
}

class XishuSkill : public TreasureSkill
{
public:
    XishuSkill() : TreasureSkill("_xishu")
    {
        events << EventPhaseChanging;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to != Player::Judge || player->isSkipped(Player::Judge)) return false;

        QStringList choices;
        if (!player->isSkipped(Player::Judge))
            choices << "judge";
        if (!player->isSkipped(Player::Discard))
            choices << "discard";
        if (choices.isEmpty()) return false;

        if (!player->askForSkillInvoke(this)) return false;
        //room->setEmotion(player, "treasure/_xishu");
        room->broadcastSkillInvoke(this);
        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        if (choice == "judge")
            player->skip(Player::Judge);
        else if (choice == "discard")
            player->skip(Player::Discard);
        return false;
    }
};

Xishu::Xishu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("_xishu");
}

class JinshuSkill : public TreasureSkill
{
public:
    JinshuSkill() : TreasureSkill("_jinshu")
    {
        events << EventPhaseEnd;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        int hand = player->getHandcardNum(), max = qMin(5, player->getMaxCards());
        if (hand >= max) return false;
        room->sendCompulsoryTriggerLog(player, this);
        //room->setEmotion(player, "treasure/_jinshu");
        player->drawCards(max - hand, objectName());
        return false;
    }
};

Jinshu::Jinshu(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("_jinshu");
}

class ExclusiveEquipSkill : public TriggerSkill
{
public:
    ExclusiveEquipSkill() : TriggerSkill("exclusiveequipskill")
    {
        events << BeforeCardsMove;
        frequency = Compulsory;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 50;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from != player) return false;

        QList<int> destroy;
        QStringList destroy_when_goto_discardpile, destroy_when_leave_equiparea, destroy_when_not_into_equiparea;
        destroy_when_goto_discardpile << "_hongduanqiang" << "_liecuidao" << "_shuibojian" << "_hunduwanbi" << "_tianleiren";

        destroy_when_leave_equiparea << "_piliche" << "_sichengliangyu" << "_tiejixuanyu" << "_feilunzhanyu";

        destroy_when_not_into_equiparea << "_qiongshu" << "_xishu" << "_jinshu";

        if (move.from_places.contains(Player::PlaceEquip) && move.to_place != Player::PlaceTable) {
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) != Player::PlaceEquip) continue;
                const Card *card = Sanguosha->getEngineCard(move.card_ids.at(i));
                if (!destroy_when_leave_equiparea.contains(card->objectName())) continue;
                destroy << move.card_ids.at(i);
            }
        }

        if (move.to_place != Player::PlaceEquip && move.to_place != Player::PlaceTable) {
            for (int i = 0; i < move.card_ids.length(); i++) {
                const Card *card = Sanguosha->getEngineCard(move.card_ids.at(i));
                if (!destroy_when_not_into_equiparea.contains(card->objectName())) continue;
                destroy << move.card_ids.at(i);
            }
        }

        if (move.to_place == Player::DiscardPile) {
            foreach (int id, move.card_ids) {
                if (destroy.contains(id)) continue;
                const Card *card = Sanguosha->getEngineCard(id);
                if (!destroy_when_goto_discardpile.contains(card->objectName())) continue;
                destroy << id;
            }
        }

        if (!destroy.isEmpty()) {
            move.removeCardIds(destroy);
            data = QVariant::fromValue(move);
            CardsMoveStruct new_move;
            new_move.card_ids = destroy;
            new_move.to = NULL;
            new_move.to_place = Player::PlaceTable;
            new_move.reason = move.reason;
            room->moveCardsAtomic(new_move, true);
        }
        return false;
    }
};

ExclusiveEquipPackage::ExclusiveEquipPackage()
    : Package("exclusiveequips", Package::CardPack)
{
    QList<Card *> cards;

    // spade
    cards << new Hunduwanbi(Card::Spade, 1) << new Tianleiren(Card::Spade, 1) << new Feilunzhanyu(Card::Spade, 5)
          << new Qiongshu(Card::Spade, 12);

    // club
    cards << new Shuibojian(Card::Club, 1) << new Tiejixuanyu(Card::Club, 5) << new Xishu(Card::Club, 12);

    // heart
    cards << new Hongduanqiang(Card::Heart, 1) << new Sichengliangyu(Card::Heart, 5) << new Jinshu(Card::Heart, 12);

    // diamond
    cards << new Liecuidao(Card::Diamond, 1) << new Piliche(Card::Diamond, 9) << new SecondPiliche(Card::Diamond, 9);

    foreach(Card *card, cards)
        card->setParent(this);

    addMetaObject<ShuibojianCard>();

    skills << new HongduanqiangSkill << new HongduanqiangJudge << new LiecuidaoTargetMod << new LiecuidaoSkill << new ShuibojianSkill
           << new HunduwanbiSkill << new TianleirenSkill << new TianleirenJudge << new PilicheSkill << new SecondPilicheSkill
           << new SichengliangyuSkill << new TiejixuanyuSkill << new FeilunzhanyuSkill << new FeilunzhanyuRecord << new QiongshuSkill
           << new XishuSkill << new JinshuSkill;

    skills << new ExclusiveEquipSkill;

    related_skills.insertMulti("_hongduanqiang", "#_hongduanqiang-judge");
    related_skills.insertMulti("_liecuidao", "#_liecuidao-target");
    related_skills.insertMulti("_tianleiren", "#_tianleiren-judge");
    related_skills.insertMulti("_feilunzhanyu", "#_feilunzhanyu-record");
}

ADD_PACKAGE(ExclusiveEquip)

