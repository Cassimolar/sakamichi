#include "yczh2016.h"
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

JiaozhaoCard::JiaozhaoCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void JiaozhaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->setPlayerMark(source, "ViewAsSkill_jiaozhaoEffect", 1);

    int selfcardid = this->getSubcards().first();
    room->showCard(source, selfcardid);
    room->setPlayerMark(source, "jiaozhao_showid-Clear", selfcardid + 1);

    int level = source->property("jiaozhao_level").toInt();
    if (level < 0)
        level = 0;
    if (level > 2)
        level = 2;

    ServerPlayer *target;
    if (level > 1)
        target = source;
    else {
        int distance = source->distanceTo(source->getNextAlive());
        foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
            if (source->distanceTo(p) < distance)
                distance = source->distanceTo(p);
        }
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
            if (source->distanceTo(p) == distance)
                targets << p;
        }
        if (targets.isEmpty()) return;
        target = room->askForPlayerChosen(source, targets, "jiaozhao", "@jiaozhao-target");
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, source->objectName(), target->objectName());
    }

    QStringList alllist;
    QList<int> ids;
    foreach(int id, Sanguosha->getRandomCards()) {
        const Card *c = Sanguosha->getEngineCard(id);
        if (c->isKindOf("EquipCard") || c->isKindOf("DelayedTrick")) continue;
        if (c->isNDTrick() && level < 1) continue;
        if (alllist.contains(c->objectName())) continue;
        alllist << c->objectName();
        ids << id;
    }
    if (ids.isEmpty()) return;

    room->fillAG(ids, target);
    int id = room->askForAG(target, ids, false, "jiaozhao");
    room->clearAG(target);

    const Card *c = Sanguosha->getEngineCard(id);
    QString name = c->objectName();
    LogMessage log;
    log.type = "#ShouxiChoice";
    log.from = target;
    log.arg = name;
    room->sendLog(log);
    room->setPlayerMark(source, "jiaozhao_id-Clear", id + 1);
}

class JiaozhaoVS : public OneCardViewAsSkill
{
public:
    JiaozhaoVS() : OneCardViewAsSkill("jiaozhao")
    {
        response_or_use = true;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (!selected.isEmpty()) return false;
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY && !Self->hasUsed("JiaozhaoCard"))
            return !to_select->isEquipped();
        int showid = Self->getMark("jiaozhao_showid-Clear") - 1;
        if (showid < 0) return false;
        return to_select->getEffectiveId() == showid;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY && !Self->hasUsed("JiaozhaoCard")) {
            JiaozhaoCard *card = new JiaozhaoCard;
            card->addSubcard(originalCard);
            return card;
        }
        int id = Self->getMark("jiaozhao_id-Clear") - 1;
        int showid = Self->getMark("jiaozhao_showid-Clear") - 1;
        if (id < 0 || showid < 0) return NULL;
        QString name = Sanguosha->getEngineCard(id)->objectName();
        Card *use_card = Sanguosha->cloneCard(name);
        if (!use_card) return NULL;
        use_card->setCanRecast(false);
        use_card->addSubcard(originalCard);
        use_card->setSkillName("jiaozhao");
        //use_card->deleteLater();  会导致游戏闪退
        return use_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->hasUsed("JiaozhaoCard")) {
            int id = player->getMark("jiaozhao_id-Clear") - 1;
            int showid = player->getMark("jiaozhao_showid-Clear") - 1;
            if (id < 0 || showid < 0) return false;
            QString name = Sanguosha->getEngineCard(id)->objectName();
            Card *use_card = Sanguosha->cloneCard(name);
            if (!use_card) return false;
            use_card->setCanRecast(false);
            use_card->addSubcard(showid);
            use_card->setSkillName("jiaozhao");
            use_card->deleteLater();
            return use_card->isAvailable(player);
        }
        return !player->hasUsed("JiaozhaoCard");
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_RESPONSE_USE)
            return false;
        if (pattern.startsWith(".") || pattern.startsWith("@"))
            return false;
        int id = player->getMark("jiaozhao_id-Clear") - 1;
        if (id < 0) return false;
        QString name = Sanguosha->getEngineCard(id)->objectName();
        if (name == "") return false;
        QString pattern_names = pattern;
        if (pattern.contains("slash") || pattern.contains("Slash"))
            pattern_names = Sanguosha->getSlashNames().join("+");
        else if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0)
            return false;
        else if (pattern == "peach+analeptic")
            return false;
        return pattern_names.split("+").contains(name);
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        int id = player->getMark("jiaozhao_id-Clear") - 1;
        if (id < 0) return false;
        QString name = Sanguosha->getEngineCard(id)->objectName();
        return name == "nullification";
    }
};

class Jiaozhao : public TriggerSkill
{
public:
    Jiaozhao() : TriggerSkill("jiaozhao")
    {
        events << EventPhaseChanging;
        view_as_skill = new JiaozhaoVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::NotActive && player->getMark("ViewAsSkill_jiaozhaoEffect") > 0)
            room->setPlayerMark(player, "ViewAsSkill_jiaozhaoEffect", 0);
        return false;
    }
};

class JiaozhaoPro : public ProhibitSkill
{
public:
    JiaozhaoPro() : ProhibitSkill("#jiaozhaopro")
    {
        frequency = NotFrequent;
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from == to && card->getSkillName() == "jiaozhao";
    }
};

class Danxin : public MasochismSkill
{
public:
    Danxin() : MasochismSkill("danxin")
    {
        frequency = Frequent;
    }

    void onDamaged(ServerPlayer *target, const DamageStruct &) const
    {
        if (target->askForSkillInvoke(objectName())){
            Room *room = target->getRoom();
            room->broadcastSkillInvoke(objectName());

            int level = target->property("jiaozhao_level").toInt();
            if (level > 1 || room->askForChoice(target, objectName(), "draw+up") == "draw")
                target->drawCards(1, objectName());
            else {
                LogMessage log;
                log.type = "#JiexunChange";
                log.from = target;
                log.arg = "jiaozhao";
                room->sendLog(log);
                level = level + 1;
                if (level > 2)
                    level = 2;
                room->setPlayerProperty(target, "jiaozhao_level", level);
                room->setPlayerMark(target, "&jiaozhao_level", level);
                QString translate = Sanguosha->translate(":jiaozhao" + QString::number(level));
                room->changeTranslation(target, "jiaozhao", translate);
            }
        }
    }
};

class Guizao : public TriggerSkill
{
public:
    Guizao() : TriggerSkill("guizao")
    {
        events << CardsMoveOneTime << EventPhaseEnd << EventPhaseChanging;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardsMoveOneTime) {
            if (player->getPhase() != Player::Discard) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                QVariantList discardlist = player->tag["guizao_dis"].toList();
                int i = 0;
                foreach (int card_id, move.card_ids) {
                    if (move.from == player && (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip))
                        discardlist << card_id;
                    i++;
                }
                player->tag["guizao_dis"] = discardlist;
            }
        } else if (triggerEvent == EventPhaseEnd) {
            QVariantList discardlist = player->tag["guizao_dis"].toList();
            player->tag.remove("guizao_dis");
            if (discardlist.length() < 2) return false;
            QStringList suits;
            bool ok = true;
            foreach (QVariant card_data, discardlist) {
                const Card *card = Sanguosha->getCard(card_data.toInt());
                if (suits.contains(card->getSuitString())) {
                    ok = false;
                    break;
                } else
                    suits << card->getSuitString();
            }
            if (!ok) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());
            QStringList choices;
            choices << "draw";
            if (player->getLostHp() > 0)
                choices << "recover";
            if (room->askForChoice(player, objectName(), choices.join("+")) == "draw")
                player->drawCards(1, objectName());
            else
                room->recover(player, RecoverStruct(player));
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from == Player::Discard) {
                player->tag.remove("guizao_dis");
            }
        }
        return false;
    }
};

JiyuCard::JiyuCard()
{
}

bool JiyuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty() && to_select->getMark("jiyu-PlayClear") <= 0 && !to_select->isKongcheng();
}

void JiyuCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();
    room->addPlayerMark(target, "jiyu-PlayClear");
    if (target->canDiscard(target, "h")) {
        const Card *c = room->askForDiscard(target, "jiyu", 1, 1);
        if (!c) {
            c = target->getCards("h").at(qrand() % target->getCards("h").length());
            room->throwCard(c, target, NULL);
        } else
            c = Sanguosha->getCard(c->getSubcards().first());

        room->setPlayerCardLimitation(source, "use", QString(".|%1|.|.").arg(c->getSuitString()), true);
        if (c->getSuit() == Card::Spade) {
            room->loseHp(target);
            source->turnOver();
        }
    }
}

class Jiyu : public ZeroCardViewAsSkill
{
public:
    Jiyu() : ZeroCardViewAsSkill("jiyu")
    {
    }

    const Card *viewAs() const
    {
        return new JiyuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        foreach (const Card *card, player->getHandcards()) {
            if (card->isAvailable(player))
                return true;
        }
        return false;
    }
};

DuliangCard::DuliangCard()
{
}

bool DuliangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->isKongcheng() && to_select != Self;
}

void DuliangCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (effect.to->isKongcheng()) return;
    int card_id = room->askForCardChosen(effect.from, effect.to, "h", "duliang");
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
    room->obtainCard(effect.from, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
    if (room->askForChoice(effect.from, "duliang", "watch+draw") == "draw")
        room->addPlayerMark(effect.to, "&duliang");
    else {
        QList<int> ids = room->getNCards(2, false);
        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = effect.to;
        log.card_str = IntList2StringList(ids).join("+");
        room->sendLog(log, effect.to);
        LogMessage newlog;
        newlog.type = "#ViewDrawPile";
        newlog.from = effect.to;
        newlog.arg = QString::number(2);
        foreach(ServerPlayer *p, room->getAllPlayers(true)) {
            if (p == effect.to) continue;
            room->sendLog(newlog, p);
        }
        room->fillAG(ids, effect.to);
        room->askForAG(effect.to, ids, true, "duliang");
        room->clearAG(effect.to);
        room->returnToTopDrawPile(ids);
        QList<int> to_obtain;
        foreach (int card_id, ids) {
            if (Sanguosha->getCard(card_id)->getTypeId() == Card::TypeBasic)
                to_obtain << card_id;
        }
        if (!to_obtain.isEmpty()) {
            DummyCard get(to_obtain);
            effect.to->obtainCard(&get, false);
        }
    }
}

class DuliangViewAsSkill : public ZeroCardViewAsSkill
{
public:
    DuliangViewAsSkill() : ZeroCardViewAsSkill("duliang")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DuliangCard");
    }

    const Card *viewAs() const
    {
        return new DuliangCard;
    }
};

class Duliang : public DrawCardsSkill
{
public:
    Duliang() : DrawCardsSkill("duliang")
    {
        view_as_skill = new DuliangViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&duliang") > 0;
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        int x = player->getMark("&duliang");
        Room *room = player->getRoom();
        room->setPlayerMark(player, "&duliang", 0);
        LogMessage log;
        log.type = "#DuliangEffect";
        log.from = player;
        log.arg = "duliang";
        log.arg2 = QString::number(x);
        room->sendLog(log);
        return n + x;
    }
};

class Fulin :public TriggerSkill
{
public:
    Fulin() : TriggerSkill("fulin")
    {
        events << EventPhaseProceeding << CardsMoveOneTime << EventPhaseChanging;
        frequency = Compulsory;
        global = true;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getAllPlayers(true))
                room->setPlayerProperty(p, "fulin_list", QString());
        } else if(triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!room->getTag("FirstRound").toBool() && move.to == player && move.to_place == Player::PlaceHand) {
                QStringList fulinlist;
                QString fulin = player->property("fulin_list").toString();
                if (!fulin.isEmpty())
                    fulinlist = fulin.split("+");
                foreach (int id, move.card_ids) {
                    QString str = QString::number(id);
                    if (fulinlist.contains(str)) continue;
                    fulinlist << str;
                }
                room->setPlayerProperty(player, "fulin_list", fulinlist.join("+"));
            }
        } else {
            if (!player->hasSkill(this) || player->getPhase() != Player::Discard) return false;
            QString fulin = player->property("fulin_list").toString();
            if (fulin.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, "fulin", true, true);
            QList<int> ids = StringList2IntList(fulin.split("+"));
            room->ignoreCards(player, ids);
        }
        return false;
    }
};

QinqingCard::QinqingCard()
{
}

bool QinqingCard::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const
{
    const Player *lord = NULL;
    QList<const Player *> as = Self->getAliveSiblings();
    as << Self;
    foreach (const Player *p, as) {
        if (p->getRole() == "lord") {
            lord = p;
            break;
        }
    }
    if (lord == NULL) return false;
    return to_select->inMyAttackRange(lord);
}

void QinqingCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) return;
        if (p->isDead()) continue;
        room->cardEffect(this, source, p);
    }
    ServerPlayer *lord = room->getLord();
    if (!lord) return;
    int num = 0;
    foreach (ServerPlayer *p, targets) {
        if (p->isAlive() && p->getHandcardNum() > lord->getHandcardNum())
            num++;
    }
    if (num > 0)
        source->drawCards(num, "qinqing");
}

void QinqingCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (effect.from->canDiscard(effect.to, "he")) {
        int card_id = room->askForCardChosen(effect.from, effect.to, "he", "qinqing", false, Card::MethodDiscard);
        room->throwCard(card_id, effect.to, effect.from);
    }
    effect.to->drawCards(1, "qinqing");
}

class QinqingVS : public ZeroCardViewAsSkill
{
public:
    QinqingVS() : ZeroCardViewAsSkill("qinqing")
    {
        response_pattern = "@@qinqing";
    }

    const Card *viewAs() const
    {
        return new QinqingCard;
    }
};

class Qinqing :public PhaseChangeSkill
{
public:
    Qinqing() : PhaseChangeSkill("qinqing")
    {
        view_as_skill = new QinqingVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        ServerPlayer *lord = room->getLord();
        if (!lord) return false;
        bool flag = false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->inMyAttackRange(lord)) {
                flag = true;
                break;
            }
        }
        if (!flag) return false;
        room->askForUseCard(player, "@@qinqing", "@qinqing");
        return false;
    }
};

HuishengCard::HuishengCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

class HuishengVS : public ViewAsSkill
{
public:
    HuishengVS() : ViewAsSkill("huisheng")
    {
        response_pattern = "@@huisheng";
    }

    bool viewFilter(const QList<const Card *> &, const Card *) const
    {
        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        HuishengCard *c = new HuishengCard;
        c->addSubcards(cards);
        return c;
    }
};

class Huisheng : public TriggerSkill
{
public:
    Huisheng() : TriggerSkill("huisheng")
    {
        events << DamageInflicted;
        view_as_skill = new HuishengVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from->isDead() || damage.from == player) return false;
        QStringList list = player->property("huisheng_targets").toStringList();
        if (list.contains(damage.from->objectName()) || player->isNude()) return false;

        room->setTag("HuishengDamage", data);
        const Card *card = room->askForUseCard(player, "@@huisheng", "@huisheng:" + damage.from->objectName());
        if (!card) {
            room->removeTag("HuishengDamage");
            return false;
        }

        QList<int> ids = card->getSubcards();
        room->fillAG(ids, damage.from);
        int candis = 0;
        foreach (const Card *c, damage.from->getCards("he")) {
            if (damage.from->canDiscard(damage.from, c->getEffectiveId()))
                candis++;
        }
        if (candis < ids.length()) {
            room->removeTag("HuishengDamage");
            list << damage.from->objectName();
            room->setPlayerProperty(player, "huisheng_targets", list);
            int id = room->askForAG(damage.from, ids, false, "huisheng");
            room->clearAG(damage.from);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, damage.from->objectName());
            room->obtainCard(damage.from, Sanguosha->getCard(id), reason, room->getCardPlace(id) != Player::PlaceHand);
            return true;
        } else {
            damage.from->tag["huisheng_ag_ids"] = IntList2VariantList(ids);
            if (!room->askForDiscard(damage.from, "huisheng", ids.length(), ids.length(), true, true,
                                     "huisheng-discard:" + QString::number(ids.length()))) {
                damage.from->tag.remove("huisheng_ag_ids");
                room->removeTag("HuishengDamage");
                list << damage.from->objectName();
                room->setPlayerProperty(player, "huisheng_targets", list);
                int id = room->askForAG(damage.from, ids, false, "huisheng");
                room->clearAG(damage.from);
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, damage.from->objectName());
                room->obtainCard(damage.from, Sanguosha->getCard(id), reason, room->getCardPlace(id) != Player::PlaceHand);
                return true;
            } else {
                damage.from->tag.remove("huisheng_ag_ids");
                room->removeTag("HuishengDamage");
                room->clearAG(damage.from);
            }
        }
        return false;
    }
};

KuangbiCard::KuangbiCard()
{
}

bool KuangbiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isNude();
}

void KuangbiCard::onEffect(const CardEffectStruct &effect) const{
    if (effect.to->isNude()) return;
    Room *room = effect.from->getRoom();
    const Card *card = room->askForExchange(effect.to, "kuangbi", 3, 1, true, "kuangbi-put:" + effect.from->objectName());
    QVariantList ids = effect.to->tag["kuangbi_ids" + effect.from->objectName()].toList();
    foreach (int id, card->getSubcards()) {
        if (ids.contains(id)) continue;
        ids << id;
    }
    effect.to->tag["kuangbi_ids" + effect.from->objectName()] = ids;
    effect.from->addToPile("kuangbi", card, true);
}

class KuangbiVS : public ZeroCardViewAsSkill
{
public:
    KuangbiVS() : ZeroCardViewAsSkill("kuangbi")
    {
    }

    const Card *viewAs() const
    {
        return new KuangbiCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("KuangbiCard");
    }
};

class Kuangbi : public PhaseChangeSkill
{
public:
    Kuangbi() : PhaseChangeSkill("kuangbi")
    {
        view_as_skill = new KuangbiVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            QVariantList ids = p->tag["kuangbi_ids" + player->objectName()].toList();
            if (ids.isEmpty()) continue;
            p->tag.remove("kuangbi_ids" + player->objectName());
            DummyCard *dummy = new DummyCard;
            foreach (QVariant card_data, ids) {
                if (player->getPile("kuangbi").contains(card_data.toInt())) {
                    dummy->addSubcard(card_data.toInt());
                }
            }
            if (dummy->subcardsLength() > 0) {
                LogMessage log;
                log.type = "$KuangbiGet";
                log.from = player;
                log.arg = "kuangbi";
                log.card_str = IntList2StringList(dummy->getSubcards()).join("+");
                room->sendLog(log);
                room->obtainCard(player, dummy, true);
                p->drawCards(dummy->subcardsLength(), objectName());
            }
            delete dummy;
        }
        return false;
    }
};

JisheDrawCard::JisheDrawCard()
{
    m_skillName = "jishe";
    target_fixed = true;
}

void JisheDrawCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(1, "jishe");
    room->addMaxCards(source, -1);
}

JisheCard::JisheCard()
{
}

bool JisheCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    return targets.length() < Self->getHp();
}

void JisheCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (!p->isAlive() || p->isChained()) continue;
        room->cardEffect(this, source, p);
    }
}

void JisheCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isChained()) return;
    effect.from->getRoom()->setPlayerChained(effect.to);
}

class JisheVS : public ZeroCardViewAsSkill
{
public:
    JisheVS() : ZeroCardViewAsSkill("jishe")
    {
        response_pattern = "@@jishe";
    }

    const Card *viewAs() const
    {
        if (Self->getPhase() == Player::Play)
            return new JisheDrawCard;
        return new JisheCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMaxCards() > 0;
    }
};

class Jishe : public PhaseChangeSkill
{
public:
    Jishe() : PhaseChangeSkill("jishe")
    {
        view_as_skill = new JisheVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        if (!player->isKongcheng() || player->getHp() <= 0) return false;
        player->getRoom()->askForUseCard(player, "@@jishe", "@jishe:" + QString::number(player->getHp()));
        return false;
    }
};

class Lianhuo : public TriggerSkill
{
public:
    Lianhuo() : TriggerSkill("lianhuo")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.nature == DamageStruct::Fire && player->isChained() && !damage.chain) {
            LogMessage log;
            log.type = "#LianhuoDamage";
            log.from = player;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

ZhigeCard::ZhigeCard()
{
}

bool ZhigeCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->inMyAttackRange(Self) && to_select != Self;
}

void ZhigeCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    bool use_slash = false;
    QList<ServerPlayer *> targets;
    foreach(ServerPlayer *p, room->getAlivePlayers()) {
        if (effect.to->canSlash(p, NULL, true))
            targets << p;
    }
    if (!targets.isEmpty())
        use_slash = room->askForUseSlashTo(effect.to, targets, "zhige-slash");
    if (!use_slash && effect.to->hasEquip()) {
        const Card *card = room->askForCard(effect.to, ".|.|.|equipped!", "zhige-give:" + effect.from->objectName(),
              QVariant::fromValue(effect.from), Card::MethodNone);
        if (!card)
            card = effect.to->getCards("e").at(qrand() % effect.to->getCards("e").length());
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "zhige", QString());
        room->obtainCard(effect.from, card, reason, true);
    }
}

class Zhige : public ZeroCardViewAsSkill
{
public:
    Zhige() : ZeroCardViewAsSkill("zhige")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZhigeCard") && player->getHandcardNum() > player->getHp();
    }

    const Card *viewAs() const
    {
        return new ZhigeCard;
    }
};

class Zongzuo : public GameStartSkill
{
public:
    Zongzuo() : GameStartSkill("zongzuo")
    {
        frequency = Compulsory;
    }

    void onGameStart(ServerPlayer *player) const
    {
        QStringList kingdoms;
        Room *room = player->getRoom();
        foreach(ServerPlayer *p, room->getAlivePlayers()) {
            if (!kingdoms.contains(p->getKingdom()))
                kingdoms << p->getKingdom();
        }
        if (kingdoms.isEmpty()) return;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        int gain = kingdoms.length();
        room->gainMaxHp(player, gain);
        room->recover(player, RecoverStruct(player, NULL, qMin(gain, (player->getMaxHp() - player->getHp()))));
    }
};

class ZongzuoDeath : public TriggerSkill
{
public:
    ZongzuoDeath() : TriggerSkill("#zongzuodeath")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who == player) return false;
        foreach(ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getKingdom() == death.who->getKingdom())
                return false;
        }
        room->sendCompulsoryTriggerLog(player, "zongzuo", true, true);
        room->loseMaxHp(player);
        return false;
    }
};

TaoluanDialog *TaoluanDialog::getInstance(const QString &object)
{
    static TaoluanDialog *instance;
    if (instance == NULL || instance->objectName() != object)
        instance = new TaoluanDialog(object);

    return instance;
}

TaoluanDialog::TaoluanDialog(const QString &object)
    : GuhuoDialog(object)
{
}

bool TaoluanDialog::isButtonEnabled(const QString &button_name) const
{
    const Card *card = map[button_name];
    return Self->getMark(objectName() + "_" + button_name) <= 0 && button_name != "normal_slash"
            && !Self->isCardLimited(card, Card::MethodUse) && card->isAvailable(Self);
}

TaoluanCard::TaoluanCard(QString this_skill_name) : this_skill_name(this_skill_name)
{
    mute = true;
    handling_method = Card::MethodUse;
    will_throw = false;
}

bool TaoluanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    const Card *_card = Self->tag.value(this_skill_name).value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool TaoluanCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *_card = Self->tag.value(this_skill_name).value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFixed();
}

bool TaoluanCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *_card = Self->tag.value(this_skill_name).value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetsFeasible(targets, Self);
}

const Card *TaoluanCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *zhangrang = card_use.from;
    Room *room = zhangrang->getRoom();

    QString tl = user_string;
    if (user_string == "slash"
        && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        QStringList tl_list;
        if (card_use.from->getMark(this_skill_name + "_slash") <= 0)
            tl_list << "slash";
        if (!Config.BanPackages.contains("maneuvering")) {
            if (card_use.from->getMark(this_skill_name + "_thunder_slash") <= 0)
                tl_list << "thunder_slash";
            if (card_use.from->getMark(this_skill_name + "_fire_slash") <= 0)
                tl_list << "fire_slash";
        }
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(zhangrang, "taoluan_slash", tl_list.join("+"));
    }
    if (card_use.from->getMark(this_skill_name + "_" + tl) > 0) return NULL;

    const Card *card = Sanguosha->getCard(subcards.first());
    Card *use_card = Sanguosha->cloneCard(tl, card->getSuit(), card->getNumber());
    use_card->setSkillName(this_skill_name);
    use_card->addSubcard(subcards.first());
    use_card->deleteLater();

    room->setCardFlag(use_card, this_skill_name);
    room->addPlayerMark(card_use.from, this_skill_name + "_" + tl);
    room->addPlayerMark(zhangrang, this_skill_name + "_" + card->getSuitString() + "-Clear");

    return use_card;
}

const Card *TaoluanCard::validateInResponse(ServerPlayer *zhangrang) const
{
    Room *room = zhangrang->getRoom();

    QString tl;
    if (user_string == "peach+analeptic") {
        QStringList tl_list;
        if (zhangrang->getMark(this_skill_name + "_peach") <= 0)
            tl_list << "peach";
        if (!Config.BanPackages.contains("maneuvering") && zhangrang->getMark(this_skill_name + "_analeptic") <= 0)
            tl_list << "analeptic";
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(zhangrang, "taoluan_saveself", tl_list.join("+"));
    } else if (user_string == "slash") {
        QStringList tl_list;
        if (zhangrang->getMark(this_skill_name + "_slash") <= 0)
            tl_list << "slash";
        if (!Config.BanPackages.contains("maneuvering")) {
            if (zhangrang->getMark(this_skill_name + "_thunder_slash") <= 0)
                tl_list << "thunder_slash";
            if (zhangrang->getMark(this_skill_name + "_fire_slash") <= 0)
                tl_list << "fire_slash";
        }
        if (tl_list.isEmpty()) return NULL;
        tl = room->askForChoice(zhangrang, "taoluan_slash", tl_list.join("+"));
    } else
        tl = user_string;

    if (zhangrang->getMark(this_skill_name + "_" + tl) > 0) return NULL;

    const Card *card = Sanguosha->getCard(subcards.first());
    Card *use_card = Sanguosha->cloneCard(tl, card->getSuit(), card->getNumber());
    use_card->setSkillName(this_skill_name);
    use_card->addSubcard(subcards.first());
    use_card->deleteLater();

    room->setCardFlag(use_card, this_skill_name);
    room->addPlayerMark(zhangrang, this_skill_name + "_" + tl);
    room->addPlayerMark(zhangrang, this_skill_name + "_" + card->getSuitString() + "-Clear");

    return use_card;
}

class TaoluanVS : public OneCardViewAsSkill
{
public:
    TaoluanVS() : OneCardViewAsSkill("taoluan")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("TaoluanInvalid-Clear") <= 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->getMark("TaoluanInvalid-Clear") > 0) return false;
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_RESPONSE_USE) return false;
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
        if (player->getMark("TaoluanInvalid-Clear") > 0) return false;
        return player->getMark("taoluan_nullification") <= 0;
    }

    bool viewFilter(const Card *) const
    {
        return true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE
            || Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            TaoluanCard *card = new TaoluanCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            card->addSubcard(originalCard);
            return card;
        }

        const Card *c = Self->tag.value("taoluan").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            TaoluanCard *card = new TaoluanCard;
            card->setUserString(c->objectName());
            card->addSubcard(originalCard);
            return card;
        } else
            return NULL;
        return NULL;
    }
};

class Taoluan : public TriggerSkill
{
public:
    Taoluan() : TriggerSkill("taoluan")
    {
        view_as_skill = new TaoluanVS;
        events << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    QDialog *getDialog() const
    {
        return TaoluanDialog::getInstance("taoluan");
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *zhangrang, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || !use.card->hasFlag(objectName())) return false;

        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(zhangrang, objectName());
        ServerPlayer *target = room->askForPlayerChosen(zhangrang, room->getOtherPlayers(zhangrang), objectName(), "@taoluan-choose");
        room->doAnimate(1, zhangrang->objectName(), target->objectName());

        QString type_name[4] = { QString(), "BasicCard", "TrickCard", "EquipCard" };
        QStringList types;
        types << "BasicCard" << "TrickCard" << "EquipCard";
        types.removeOne(type_name[use.card->getTypeId()]);
        const Card *card = room->askForCard(target, types.join(",") + "|.|.|.",
                "@taoluan-give:" + zhangrang->objectName() + "::" + use.card->getType(), data, Card::MethodNone);
        if (card) {
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), zhangrang->objectName(), objectName(), QString());
            room->obtainCard(zhangrang, card, reason, true);
            delete card;
        } else {
            room->loseHp(zhangrang);
            room->addPlayerMark(zhangrang, "TaoluanInvalid-Clear");
        }
        return false;
    }
};

TenyearTaoluanCard::TenyearTaoluanCard() : TaoluanCard("tenyeartaoluan")
{
    mute = true;
    handling_method = Card::MethodUse;
    will_throw = false;
}

class TenyearTaoluanVS : public OneCardViewAsSkill
{
public:
    TenyearTaoluanVS() : OneCardViewAsSkill("tenyeartaoluan")
    {
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("TenyearTaoluanInvalid-Clear") <= 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->getMark("TenyearTaoluanInvalid-Clear") > 0) return false;
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_RESPONSE_USE) return false;
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
        if (player->getMark("TenyearTaoluanInvalid-Clear") > 0) return false;
        return player->getMark("tenyeartaoluan_nullification") <= 0;
    }

    bool viewFilter(const Card *to_select) const
    {
        return Self->getMark("tenyeartaoluan_" + to_select->getSuitString() + "-Clear") <= 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE
            || Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            TenyearTaoluanCard *card = new TenyearTaoluanCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            card->addSubcard(originalCard);
            return card;
        }

        const Card *c = Self->tag.value("tenyeartaoluan").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            TenyearTaoluanCard *card = new TenyearTaoluanCard;
            card->setUserString(c->objectName());
            card->addSubcard(originalCard);
            return card;
        } else
            return NULL;
        return NULL;
    }
};

class TenyearTaoluan : public TriggerSkill
{
public:
    TenyearTaoluan() : TriggerSkill("tenyeartaoluan")
    {
        view_as_skill = new TenyearTaoluanVS;
        events << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    QDialog *getDialog() const
    {
        return TaoluanDialog::getInstance("tenyeartaoluan");
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *zhangrang, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || !use.card->hasFlag(objectName())) return false;

        room->broadcastSkillInvoke(objectName());
        room->notifySkillInvoked(zhangrang, objectName());
        ServerPlayer *target = room->askForPlayerChosen(zhangrang, room->getOtherPlayers(zhangrang), objectName(), "@taoluan-choose");
        room->doAnimate(1, zhangrang->objectName(), target->objectName());

        QString type_name[4] = { QString(), "BasicCard", "TrickCard", "EquipCard" };
        QStringList types;
        types << "BasicCard" << "TrickCard" << "EquipCard";
        types.removeOne(type_name[use.card->getTypeId()]);
        const Card *card = room->askForCard(target, types.join(",") + "|.|.|.",
                "@taoluan-give:" + zhangrang->objectName() + "::" + use.card->getType(), data, Card::MethodNone);
        if (card) {
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), zhangrang->objectName(), objectName(), QString());
            room->obtainCard(zhangrang, card, reason, true);
            delete card;
        } else {
            room->loseHp(zhangrang);
            room->addPlayerMark(zhangrang, "TenyearTaoluanInvalid-Clear");
        }
        return false;
    }
};

YCZH2016Package::YCZH2016Package()
    : Package("YCZH2016")
{
    General *guohuanghou = new General(this, "guohuanghou", "wei", 3, false);
    guohuanghou->addSkill(new Jiaozhao);
    guohuanghou->addSkill(new JiaozhaoPro);
    guohuanghou->addSkill(new Danxin);
    related_skills.insertMulti("jiaozhao", "#jiaozhaopro");

    General *sunziliufang = new General(this, "sunziliufang", "wei", 3);
    sunziliufang->addSkill(new Guizao);
    sunziliufang->addSkill(new Jiyu);

    General *liyan = new General(this, "liyan", "shu", 3);
    liyan->addSkill(new Duliang);
    liyan->addSkill(new Fulin);

    General *huanghao = new General(this, "huanghao", "shu", 3);
    huanghao->addSkill(new Qinqing);
    huanghao->addSkill(new Huisheng);

    General *sundeng = new General(this, "sundeng", "wu", 4);
    sundeng->addSkill(new Kuangbi);

    General *cenhun = new General(this, "cenhun", "wu", 3);
    cenhun->addSkill(new Jishe);
    cenhun->addSkill(new Lianhuo);

    General *liuyu = new General(this, "liuyu", "qun", 2);
    liuyu->addSkill(new Zhige);
    liuyu->addSkill(new Zongzuo);
    liuyu->addSkill(new ZongzuoDeath);
    related_skills.insertMulti("zongzuo", "#zongzuodeath");

    General *zhangrang = new General(this, "zhangrang", "qun", 3);
    zhangrang->addSkill(new Taoluan);

    General *tenyear_zhangrang = new General(this, "tenyear_zhangrang", "qun", 3);
    tenyear_zhangrang->addSkill(new TenyearTaoluan);

    addMetaObject<JiaozhaoCard>();
    addMetaObject<JiyuCard>();
    addMetaObject<DuliangCard>();
    addMetaObject<QinqingCard>();
    addMetaObject<HuishengCard>();
    addMetaObject<KuangbiCard>();
    addMetaObject<JisheDrawCard>();
    addMetaObject<JisheCard>();
    addMetaObject<ZhigeCard>();
    addMetaObject<TaoluanCard>();
    addMetaObject<TenyearTaoluanCard>();
}

ADD_PACKAGE(YCZH2016)
