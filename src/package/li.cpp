#include "li.h"
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
#include "yingbian.h"

class JinBuchen : public TriggerSkill
{
public:
    JinBuchen() : TriggerSkill("jinbuchen")
    {
        events << Appear;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent() || room->getCurrent() == player || room->getCurrent()->isNude()) return false;
        if (!player->askForSkillInvoke(this, room->getCurrent())) return false;
        room->broadcastSkillInvoke(objectName());
        int card_id = room->askForCardChosen(player, room->getCurrent(), "he", "jinbuchen");
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
        room->obtainCard(player, Sanguosha->getCard(card_id),
            reason, room->getCardPlace(card_id) != Player::PlaceHand);
        return false;
    }
};

JinYingshiCard::JinYingshiCard()
{
    target_fixed = true;
}

void JinYingshiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int maxhp = card_use.from->getMaxHp();
    if (maxhp <= 0) return;
    QList<int> list = room->getNCards(maxhp, false);
    room->returnToTopDrawPile(list);
    room->fillAG(list, card_use.from);
    room->askForAG(card_use.from, list, true, "jinyingshi");
    room->clearAG(card_use.from);
}

class JinYingshi : public ZeroCardViewAsSkill
{
public:
    JinYingshi() : ZeroCardViewAsSkill("jinyingshi")
    {
        frequency = Compulsory;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMaxHp() > 0;
    }

    const Card *viewAs() const
    {
        return new JinYingshiCard;
    }
};

JinXiongzhiCard::JinXiongzhiCard()
{
    target_fixed = true;
}

void JinXiongzhiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->removePlayerMark(source, "@jinxiongzhiMark");
    room->doSuperLightbox("jin_simayi", "jinxiongzhi");

    while (true) {
        if (source->isDead()) return;

        QList<int> list = room->getNCards(1, false);
        room->returnToTopDrawPile(list);
        const Card *card = Sanguosha->getCard(list.first());

        room->notifyMoveToPile(source, list, "jinxiongzhi", Player::DrawPile, true);

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = source;
        log.card_str = card->toString();
        room->sendLog(log, source);

        if (!source->canUse(card)) {
            room->notifyMoveToPile(source, list, "jinxiongzhi", Player::DrawPile, false);
            room->fillAG(list, source);
            room->askForAG(source, list, true, "jinxiongzhi");
            room->clearAG(source);
            break;
        } else {
            if (card->targetFixed()) {
                room->useCard(CardUseStruct(card, source, source), true);
            } else {
                QList<ServerPlayer *> targets;
                room->setPlayerMark(source, "jinxiongzhi_id-PlayClear", list.first() + 1);
                if (room->askForUseCard(source, "@@jinxiongzhi!", "@jinxiongzhi:" + card->objectName())) {
                    room->notifyMoveToPile(source, list, "jinxiongzhi", Player::DrawPile, false);
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (!p->hasFlag("jinxiongzhi_target")) continue;
                        room->setPlayerFlag(p, "-jinxiongzhi_target");
                        targets << p;
                    }
                } else {
                    room->notifyMoveToPile(source, list, "jinxiongzhi", Player::DrawPile, false);
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (source->canUse(card, QList<ServerPlayer *>() << p))
                            targets << p;
                    }
                }
                if (targets.isEmpty()) break;
                room->useCard(CardUseStruct(card, source, targets), true);
            }
        }
    }
}

JinXiongzhiUseCard::JinXiongzhiUseCard()
{
    m_skillName = "jinxiongzhi";
    handling_method = Card::MethodUse;
}

bool JinXiongzhiUseCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int id = Self->getMark("jinxiongzhi_id-PlayClear") - 1;
    if (id < 0) return false;
    const Card *card = Sanguosha->getCard(id);
    return card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card);
}

bool JinXiongzhiUseCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    int id = Self->getMark("jinxiongzhi_id-PlayClear") - 1;
    if (id < 0) return false;
    const Card *card = Sanguosha->getCard(id);
    return card->targetsFeasible(targets, Self);
}

void JinXiongzhiUseCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "jinxiongzhi_target");
}

class JinXiongzhi : public ViewAsSkill
{
public:
    JinXiongzhi() : ViewAsSkill("jinxiongzhi")
    {
        response_pattern = "@@jinxiongzhi!";
        frequency = Limited;
        limit_mark = "@jinxiongzhiMark";
        expand_pile = "#jinxiongzhi";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@jinxiongzhiMark") > 0;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->getCurrentCardUsePattern() == "@@jinxiongzhi!" && selected.isEmpty())
            return to_select->getId() == Self->getMark("jinxiongzhi_id-PlayClear") - 1;
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->getCurrentCardUsePattern() == "@@jinxiongzhi!" && cards.length() == 1) {
            JinXiongzhiUseCard *c = new JinXiongzhiUseCard;
            c->addSubcards(cards);
            return c;
        }
        if (cards.isEmpty())
            return new JinXiongzhiCard;
        return NULL;
    }
};

class JinQuanbian : public TriggerSkill
{
public:
    JinQuanbian(const QString &name) : TriggerSkill(name), name(name)
    {
        events << CardUsed << CardResponded;
        global = true;
    }

    int getPriority(TriggerEvent) const
    {
        return 3;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;

        const Card *card = NULL;
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.m_isHandcard || use.card->isKindOf("SkillCard")) return false;
            card = use.card;
            if (name != "secondjinquanbian" || !use.card->isKindOf("EquipCard"))
                room->addPlayerMark(player, name + "_used-PlayClear");
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isHandcard || res.m_card->isKindOf("SkillCard")) return false;
            card = res.m_card;
            if (res.m_isUse)
                room->addPlayerMark(player, name + "_used-PlayClear");
        }

        if (!card || card->isKindOf("SkillCard")) return false;

        QString suitstring = card->getSuitString();
        if (suitstring == "no_suit_black" || suitstring == "no_suit_red")
            suitstring = "no_suit";
        if (player->getMark(name + "_" + suitstring + "-PlayClear") > 0) return false;
        room->addPlayerMark(player, name + "_" + suitstring + "-PlayClear");

        if (!player->hasSkill(this) || player->getMaxHp() <= 0 || !player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        QList<int> list = room->getNCards(player->getMaxHp(), false);
        //room->returnToTopDrawPile(list);  guanxing会放回去，这里不能return回去
        QList<int> enabled, disabled;
        foreach (int id, list) {
            QString suitstr = Sanguosha->getCard(id)->getSuitString();
            if (suitstr == "no_suit_black" || suitstr == "no_suit_red")
                suitstr = "no_suit";
            if (suitstr == suitstring)
                disabled << id;
            else
                enabled << id;
        }
        if (enabled.isEmpty()) {
            room->fillAG(list, player);
            room->askForAG(player, list, true, objectName());
            room->clearAG(player);
            room->askForGuanxing(player, list, Room::GuanxingUpOnly);
            return false;
        }
        room->fillAG(list, player, disabled);
        int id = room->askForAG(player, enabled, false, objectName());
        room->clearAG(player);
        room->obtainCard(player, id, true);
        list.removeOne(id);
        if (player->isDead()) {
            room->returnToTopDrawPile(list);
            return false;
        }
        room->askForGuanxing(player, list, Room::GuanxingUpOnly);

        return false;
    }
private:
    QString name;
};

class JinQuanbianLimit : public CardLimitSkill
{
public:
    JinQuanbianLimit(const QString &name) : CardLimitSkill("#" + name + "-limit"), name(name)
    {
    }

    QString limitList(const Player *target) const
    {
        if (target->hasSkill(name) && target->getMark(name + "_used-PlayClear") >= target->getMaxHp() && target->getPhase() == Player::Play)
            return "use";
        else
            return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->hasSkill(name) && target->getMark(name + "_used-PlayClear") >= target->getMaxHp() && target->getPhase() == Player::Play)
            return ".|.|.|hand";
        else
            return QString();
    }
private:
    QString name;
};

class JinHuishi : public DrawCardsSkill
{
public:
    JinHuishi() : DrawCardsSkill("jinhuishi")
    {
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        int draw_num = room->getDrawPile().length();
        if (draw_num >= 10)
            draw_num = draw_num % 10;
        if (!player->askForSkillInvoke(this, QString("jinhuishi_invoke:%1").arg(QString::number(draw_num)))) return n;
        room->broadcastSkillInvoke(objectName());
        if (draw_num <= 0) return -n;
        int get_num = floor(draw_num / 2);
        if (get_num <= 0) {
            QList<int> list = room->getNCards(draw_num, false);
            room->returnToEndDrawPile(list);
            LogMessage log;
            log.type = "$ViewDrawPile";
            log.from = player;
            log.card_str = IntList2StringList(list).join("+");
            room->sendLog(log, player);
            room->fillAG(list, player);
            room->askForAG(player, list, true, objectName());
            room->clearAG(player);
            return -n;
        }

        QList<int> list = room->getNCards(draw_num, false);
        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(list).join("+");
        room->sendLog(log, player);

        QList<int> enabled = list, disabled;
        while (disabled.length() < get_num) {
            if (player->isDead()) break;
            room->fillAG(list, player, disabled);
            int id = room->askForAG(player, enabled, false, objectName());
            room->clearAG(player);
            enabled.removeOne(id);
            disabled << id;
            if (enabled.isEmpty()) break;
        }
        if (player->isAlive()) {
            DummyCard get(disabled);
            room->obtainCard(player, &get, false);
            room->returnToEndDrawPile(enabled);
        } else
            room->returnToTopDrawPile(list);

        return -n;
    }
};

JinQinglengCard::JinQinglengCard()
{
    will_throw = false;
    target_fixed = true;
}

void JinQinglengCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    QString name = card_use.from->property("jinqingleng_now_target").toString();
    if (name.isEmpty()) return;
    ServerPlayer *target = room->findChild<ServerPlayer *>(name);
    if (!target || target->isDead()) return;

    const Card *card = Sanguosha->getCard(subcards.first());
    IceSlash *slash = new IceSlash(card->getSuit(), card->getNumber());
    slash->addSubcard(card);
    slash->deleteLater();
    slash->setSkillName("jinqingleng");
    if (!card_use.from->canSlash(target, slash, false)) return;

    room->useCard(CardUseStruct(slash, card_use.from, target));
}

class JinQinglengVS : public OneCardViewAsSkill
{
public:
    JinQinglengVS() : OneCardViewAsSkill("jinqingleng")
    {
        response_pattern = "@@jinqingleng";
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        QString name = Self->property("jinqingleng_now_target").toString();
        if (name.isEmpty()) return false;
        //Player *player = Self->findChild<Player *>(name);
        const Player *player = NULL;
        foreach (const Player *p, Self->getAliveSiblings()) {
            if (p->objectName() == name) {
                player = p;
                break;
            }
        }
        if (player == NULL || player->isDead()) return false;
        IceSlash *slash = new IceSlash(to_select->getSuit(), to_select->getNumber());
        slash->addSubcard(to_select);
        slash->deleteLater();
        slash->setSkillName("jinqingleng");
        return Self->canSlash(player, slash, false);
    }

    const Card *viewAs(const Card *originalCard) const
    {
        JinQinglengCard *c = new JinQinglengCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class JinQingleng : public TriggerSkill
{
public:
    JinQingleng() : TriggerSkill("jinqingleng")
    {
        events << CardUsed << EventPhaseChanging;
        view_as_skill = new JinQinglengVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            if (!player->hasSkill(this)) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard") || use.card->getSkillName() != objectName()) return false;
            QStringList target_names = player->property("jinqingleng_targets").toStringList();
            int num = 0;
            foreach (ServerPlayer *p, use.to) {
                if (target_names.contains(p->objectName())) continue;
                num++;
                target_names << p->objectName();
            }
            room->setPlayerProperty(player, "jinqingleng_targets", target_names);
            if (num > 0) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                player->drawCards(num, objectName());
            }
        } else if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this)) continue;
                int num = player->getHp() + player->getHandcardNum();
                int draw_num = room->getDrawPile().length();
                if (draw_num >= 10)
                    draw_num = draw_num % 10;
                if (num < draw_num) return false;
                room->setPlayerProperty(p, "jinqingleng_now_target", player->objectName());
                room->askForUseCard(p, "@@jinqingleng", "@jinqingleng:" + player->objectName());
                room->setPlayerProperty(p, "jinqingleng_now_target", QString());
            }
        }
        return false;
    }
};

class JinXuanmu : public TriggerSkill
{
public:
    JinXuanmu() : TriggerSkill("jinxuanmu")
    {
        events << Appear;
        frequency = Compulsory;
        hide_skill = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!room->hasCurrent() || room->getCurrent() == player) return false;
        room->setPlayerMark(player, "&jinxuanmu-Clear", 1);
        return false;
    }
};

class JinXuanmuPrevent : public TriggerSkill
{
public:
    JinXuanmuPrevent() : TriggerSkill("#jinxuanmu")
    {
        events << DamageInflicted;
        frequency = Compulsory;
        hide_skill = true;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&jinxuanmu-Clear") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.damage <= 0) return false;
        LogMessage log;
        log.type = "#MobilejinjiuPrevent";
        log.from = player;
        log.arg = "jinxuanmu";
        log.arg2 = QString::number(damage.damage);
        room->sendLog(log);
        room->notifySkillInvoked(player, "jinxuanmu");
        room->broadcastSkillInvoke("jinxuanmu");
        return true;
    }
};

class Qiaoyan : public TriggerSkill
{
public:
    Qiaoyan() : TriggerSkill("qiaoyan")
    {
        events << DamageCaused;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead() || !damage.to->hasSkill(this) || damage.to == damage.from || damage.to->getPhase() != Player::NotActive) return false;
        room->sendCompulsoryTriggerLog(damage.to, objectName(), true, true);
        QList<int> zhu = damage.to->getPile("qyzhu");
        if (zhu.isEmpty()) {
            damage.to->drawCards(1, objectName());
            if (damage.to->isDead() || damage.to->isNude()) return true;
            const Card *card = room->askForExchange(damage.to, objectName(), 1, 1, true, "@qiaoyan-put");
            damage.to->addToPile("qyzhu", card);
            delete card;
            return true;
        } else {
            DummyCard get(zhu);
            room->obtainCard(player, &get);
        }
        return false;
    }
};

class Xianzhu : public PhaseChangeSkill
{
public:
    Xianzhu() : PhaseChangeSkill("xianzhu")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        QList<int> zhu = player->getPile("qyzhu");
        if (zhu.isEmpty()) return false;
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getAllPlayers(), objectName(), "@xianzhu-invoke", false, true);
        room->broadcastSkillInvoke(objectName());

        DummyCard get(zhu);
        if (target == player) {
            LogMessage log;
            log.type = "$KuangbiGet";
            log.from = player;
            log.arg = "qyzhu";
            log.card_str = IntList2StringList(zhu).join("+");
            room->sendLog(log);
        }
        room->obtainCard(target, &get);
        if (target == player || target->isDead()) return false;

        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("_xianzhu");
        slash->deleteLater();
        if (target->isLocked(slash)) return false;
        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (player->inMyAttackRange(p) && target->canSlash(p, slash, false))
                tos << p;
        }
        if (tos.isEmpty()) return false;
        player->tag["xianzhu_slash_from"] = QVariant::fromValue(target);
        ServerPlayer *to = room->askForPlayerChosen(player, tos, "xianzhu_target", "@xianzhu-target");
        player->tag.remove("xianzhu_slash_from");
        room->useCard(CardUseStruct(slash, target, to));
        return false;
    }
};

class JinCaiwangVS : public ZeroCardViewAsSkill
{
public:
    JinCaiwangVS(const QString &jincaiwang) : ZeroCardViewAsSkill(jincaiwang), jincaiwang(jincaiwang)
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player) && player->getJudgingArea().length() == 1;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return (pattern == "jink" && player->getHandcardNum() == 1) ||
               (pattern == "nullification" && player->getEquips().length() == 1 &&
                    Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_RESPONSE) ||
                ((pattern.contains("slash") || pattern.contains("Slash")) && player->getJudgingArea().length() == 1);
    }

    const Card *viewAs() const
    {
        switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
        case CardUseStruct::CARD_USE_REASON_PLAY: {
            Slash *slash = new Slash(Card::SuitToBeDecided, -1);
            slash->addSubcard(Self->getJudgingArea().first());
            slash->setSkillName(objectName());
            return slash;
        }
        case CardUseStruct::CARD_USE_REASON_RESPONSE:
        case CardUseStruct::CARD_USE_REASON_RESPONSE_USE: {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern.contains("slash") || pattern.contains("Slash")) {
                Slash *slash = new Slash(Card::SuitToBeDecided, -1);
                slash->addSubcard(Self->getJudgingArea().first());
                slash->setSkillName(objectName());
                return slash;
            } else if (pattern == "jink") {
                Jink *jink = new Jink(Card::SuitToBeDecided, -1);
                jink->addSubcard(Self->getHandcards().first());
                jink->setSkillName(objectName());
                return jink;
            } else if (pattern == "nullification") {
                Nullification *nullification = new Nullification(Card::SuitToBeDecided, -1);
                nullification->addSubcard(Self->getEquips().first());
                nullification->setSkillName(objectName());
                return nullification;
            }
        }
        default:
            return NULL;
        }
        return NULL;
    }
private:
    QString jincaiwang;
};

class JinCaiwang : public TriggerSkill
{
public:
    JinCaiwang(const QString &jincaiwang) : TriggerSkill(jincaiwang), jincaiwang(jincaiwang)
    {
        events << CardResponded << CardUsed;
        view_as_skill = (jincaiwang == "jincaiwang") ? NULL : new JinCaiwangVS(jincaiwang);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        const Card *tocard = NULL;
        ServerPlayer *who;
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            card = use.card;
            tocard = use.whocard;
            who = use.who;
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            card = res.m_card;
            tocard = res.m_toCard;
            who = res.m_who;
        }
        if (!card || !tocard || card->isKindOf("SkillCard") || tocard->isKindOf("SkillCard") || !card->sameColorWith(tocard)) return false;
        if (!who || who->isDead() || who == player) return false;

        ServerPlayer *user = room->getCardUser(tocard);
        if (!user || user != who) return false;

        QList<ServerPlayer *> players;
        players << who << player;
        room->sortByActionOrder(players);

        foreach (ServerPlayer *p, players) {
            ServerPlayer *thrower, *victim;
            if (p == who) {
                thrower = who;
                victim = player;
            } else {
                thrower = player;
                victim = who;
            }
            if (thrower && thrower->isAlive() && thrower->hasSkill(this) && victim && victim->isAlive() && !victim->isNude()) {
                QString prompt = QString("jincaiwang_discard:%1").arg(victim->objectName());
                if (victim->getMark("&jinnaxiang+#" + thrower->objectName()) > 0) {
                    prompt = QString("jincaiwang_get:%1").arg(victim->objectName());
                    if (!thrower->askForSkillInvoke(this, prompt)) continue;
                    room->broadcastSkillInvoke(objectName());
                    int id = room->askForCardChosen(thrower, victim, "he", objectName());
                    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, thrower->objectName());
                    room->obtainCard(thrower, Sanguosha->getCard(id),
                        reason, room->getCardPlace(id) != Player::PlaceHand);
                } else {
                    if (!thrower->canDiscard(victim, "he")) continue;
                    if (!thrower->askForSkillInvoke(this, prompt)) continue;
                    room->broadcastSkillInvoke(objectName());
                    int id = room->askForCardChosen(thrower, victim, "he", objectName(), false, Card::MethodDiscard);
                    room->throwCard(id, victim, thrower);
                }
            }
        }
        return false;
    }
private:
    QString jincaiwang;
};

class JinNaxiang : public TriggerSkill
{
public:
    JinNaxiang() : TriggerSkill("jinnaxiang")
    {
        events << Damage << Damaged;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (event == Damage) {
            if (damage.from == damage.to || damage.to->isDead() || !damage.to->hasSkill(this)) return false;
            room->sendCompulsoryTriggerLog(damage.to, objectName(), true, true);
            room->setPlayerMark(damage.from, "&jinnaxiang+#" + damage.to->objectName(), 1);
        } else {
            if (!damage.from || damage.from->isDead() || damage.from == damage.to || !damage.from->hasSkill(this)) return false;
            room->sendCompulsoryTriggerLog(damage.from, objectName(), true, true);
            room->setPlayerMark(damage.to, "&jinnaxiang+#" + damage.from->objectName(), 1);
        }
        return false;
    }
};

class JinNaxiangClear : public PhaseChangeSkill
{
public:
    JinNaxiangClear() : PhaseChangeSkill("#jinnaxiang-clear")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::RoundStart;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getMark("&jinnaxiang+#" + player->objectName()) > 0)
                room->setPlayerMark(p, "&jinnaxiang+#" + player->objectName(), 0);
        }
        return false;
    }
};

ChexuanCard::ChexuanCard()
{
    target_fixed = true;
}

void ChexuanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isDead() || !source->hasTreasureArea() || source->getTreasure()) return;
    QList<int> ids;
    int id1 = source->getDerivativeCard("_sichengliangyu", Player::PlaceTable);
    int id2 = source->getDerivativeCard("_tiejixuanyu", Player::PlaceTable);
    int id3 = source->getDerivativeCard("_feilunzhanyu", Player::PlaceTable);
    if (id1 > 0)
        ids << id1;
    if (id2 > 0)
        ids << id2;
    if (id3 > 0)
        ids << id3;
    if (ids.isEmpty()) return;

    room->fillAG(ids, source);
    int id = room->askForAG(source, ids, false, "chexuan");
    room->clearAG(source);

    LogMessage log;
    log.type = "$Install";
    log.from = source;
    log.card_str = QString::number(id);
    room->sendLog(log);

    CardMoveReason reason(CardMoveReason::S_REASON_PUT, "chexuan");
    CardsMoveStruct move(id, NULL, (Player *)source, Player::PlaceTable, Player::PlaceEquip, reason);
    room->moveCardsAtomic(move, true);
}

class ChexuanVS : public OneCardViewAsSkill
{
public:
    ChexuanVS() : OneCardViewAsSkill("chexuan")
    {
        filter_pattern = ".|black!";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ChexuanCard *c = new ChexuanCard;
        c->addSubcard(originalCard);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->getTreasure();
    }
};

class Chexuan : public TriggerSkill
{
public:
    Chexuan() : TriggerSkill("chexuan")
    {
        events << CardsMoveOneTime;
        view_as_skill = new ChexuanVS;
        waked_skills = "_sichengliangyu,_tiejixuanyu,_feilunzhanyu";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player || move.reason.m_reason == CardMoveReason::S_REASON_CHANGE_EQUIP || !move.from_places.contains(Player::PlaceEquip))
            return false;
        for (int i = 0; i < move.card_ids.length(); i++) {
            if (player->isDead()) return false;
            if (move.from_places.at(i) != Player::PlaceEquip) continue;
            const Card *card = Sanguosha->getCard(move.card_ids.at(i));
            if (!card->isKindOf("Treasure")) continue;

            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());

            JudgeStruct judge;
            judge.who = player;
            judge.reason = objectName();
            judge.good = true;
            judge.pattern = ".|black";
            room->judge(judge);

            if (judge.isGood() && player->isAlive() && player->hasTreasureArea() && !player->getTreasure()) {
                QList<int> ids;
                int id1 = player->getDerivativeCard("_sichengliangyu", Player::PlaceTable);
                int id2 = player->getDerivativeCard("_tiejixuanyu", Player::PlaceTable);
                int id3 = player->getDerivativeCard("_feilunzhanyu", Player::PlaceTable);
                if (id1 > 0)
                    ids << id1;
                if (id2 > 0)
                    ids << id2;
                if (id3 > 0)
                    ids << id3;
                if (ids.isEmpty()) continue;
                int id = ids.at(qrand() % ids.length());

                LogMessage log;
                log.type = "$Install";
                log.from = player;
                log.card_str = QString::number(id);
                room->sendLog(log);

                CardMoveReason reason(CardMoveReason::S_REASON_PUT, "chexuan");
                CardsMoveStruct move(id, NULL, (Player *)player, Player::PlaceTable, Player::PlaceEquip, reason);
                room->moveCardsAtomic(move, true);
            }
        }
        return false;
    }
};

class Qiangshou : public DistanceSkill
{
public:
    Qiangshou() : DistanceSkill("qiangshou")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill(this) && from->getTreasure())
            return -1;
        else
            return 0;
    }
};

CaozhaoDialog *CaozhaoDialog::getInstance(const QString &object)
{
    static CaozhaoDialog *instance;
    if (instance == NULL || instance->objectName() != object)
        instance = new CaozhaoDialog(object);

    return instance;
}

CaozhaoDialog::CaozhaoDialog(const QString &object)
    : GuhuoDialog(object)
{
}

bool CaozhaoDialog::isButtonEnabled(const QString &button_name) const
{
    QStringList names = Self->property("CaozhaoNames").toStringList();
    return !names.contains(button_name) && button_name != "normal_slash";
}

CaozhaoCard::CaozhaoCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void CaozhaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int first = subcards.first();
    room->showCard(source, first);
    QString name = user_string;
    LogMessage log;
    log.type = "#ShouxiChoice";
    log.from = source;
    log.arg = name;
    room->sendLog(log);

    QStringList names = source->property("CaozhaoNames").toStringList();
    names << name;
    room->setPlayerProperty(source, "CaozhaoNames", names);

    QList<ServerPlayer *> targets;
    int hp = source->getHp();
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (p->getHp() <= hp)
            targets << p;
    }
    if (targets.isEmpty()) return;
    ServerPlayer *target = room->askForPlayerChosen(source, targets, "caozhao", "@caozhao-target");
    room->doAnimate(1, source->objectName(), target->objectName());

    const Card *e_card = Sanguosha->getEngineCard(first), *card = Sanguosha->getCard(first);
    QStringList choices;
    choices << "view=" + e_card->objectName() + "=" + user_string << "losehp";
    QString choice = room->askForChoice(target, "caozhao", choices.join("+"), QVariant::fromValue(source));

    if (choice == "losehp")
        room->loseHp(target);
    else {
        if (source->isDead()) return;
        ServerPlayer *geter = room->askForPlayerChosen(source, room->getOtherPlayers(source), "caozhao_give", "@caozhao-give", true);
        if (!geter)
            geter = source;
        else
            room->giveCard(source, geter, subcards, "caozhao", true);
        Card *view = Sanguosha->cloneCard(name, card->getSuit(), card->getNumber());
        view->setSkillName("caozhao");
        WrappedCard *wr = Sanguosha->getWrappedCard(first);
        wr->takeOver(view);
        room->notifyUpdateCard(geter, first, wr);
    }
}

class Caozhao : public OneCardViewAsSkill
{
public:
    Caozhao() : OneCardViewAsSkill("caozhao")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("CaozhaoCard");
    }

    QDialog *getDialog() const
    {
        return CaozhaoDialog::getInstance("caozhao");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        const Card *card = Self->tag.value("caozhao").value<const Card *>();
        if (!card) return NULL;
        CaozhaoCard *c = new CaozhaoCard;
        c->setUserString(card->objectName());
        c->addSubcard(originalcard);
        return c;
    }
};

class OLXibing : public TriggerSkill
{
public:
    OLXibing() : TriggerSkill("olxibing")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from == player) return false;
        QStringList choices;
        if (player->canDiscard(damage.from, "he"))
            choices << "discard=" + damage.from->objectName();
        if (player->canDiscard(player, "he"))
            choices << "discard_self";
        if (choices.isEmpty()) return false;
        if (!player->askForSkillInvoke(this, data)) return false;
        room->broadcastSkillInvoke(this);
        QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);

        ServerPlayer *thrower = player, *victim = damage.from;
        if (choice == "discard_self")
            victim = player;
        if (thrower->isDead() || victim->isDead()) return false;

        int ad = Config.AIDelay;
        Config.AIDelay = 0;

        QList<Player::Place> orig_places;
        QList<int> cards;
        victim->setFlags("olxibing_InTempMoving");

        for (int i = 0; i < 2; ++i) {
            if (!thrower->canDiscard(victim, "he")) break;
            int id = room->askForCardChosen(thrower, victim, "he", objectName(), false, Card::MethodDiscard);
            Player::Place place = room->getCardPlace(id);
            orig_places << place;
            cards << id;
            victim->addToPile("#olxibing", id, false);
        }

        for (int i = 0; i < cards.length(); ++i)
            room->moveCardTo(Sanguosha->getCard(cards.value(i)), victim, orig_places.value(i), false);

        victim->setFlags("-olxibing_InTempMoving");
        Config.AIDelay = ad;

        DummyCard dummy(cards);
        room->throwCard(&dummy, victim, thrower);

        if (player->isDead() || damage.from->isDead()) return false;
        int hand = player->getHandcardNum(), hand2 = damage.from->getHandcardNum();
        if (hand == hand2) return false;

        room->addPlayerMark(player, "olxibing_to-Clear");
        ServerPlayer *drawer = player;
        if (hand > hand2)
            drawer = damage.from;

        drawer->drawCards(2, objectName());
        if (drawer->isAlive())
            room->addPlayerMark(drawer, "olxibing_from-Clear");

        return false;
    }
};

class OLXibingPro : public ProhibitSkill
{
public:
    OLXibingPro() : ProhibitSkill("#olxibing-pro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from && from->getMark("olxibing_from-Clear") > 0 && to->getMark("olxibing_to-Clear") > 0 && !card->isKindOf("SkillCard");
    }
};

LiPackage::LiPackage()
    : Package("li")
{
    new General(this, "yinni_hide", "jin", 1, true, true, true);

    General *jin_simayi = new General(this, "jin_simayi", "jin", 3);
    jin_simayi->addSkill(new JinBuchen);
    jin_simayi->addSkill(new JinYingshi);
    jin_simayi->addSkill(new JinXiongzhi);
    jin_simayi->addSkill(new JinQuanbian("jinquanbian"));
    jin_simayi->addSkill(new JinQuanbianLimit("jinquanbian"));
    related_skills.insertMulti("jinquanbian", "#jinquanbian-limit");

    General *second_jin_simayi = new General(this, "second_jin_simayi", "jin", 3);
    second_jin_simayi->addSkill("jinbuchen");
    second_jin_simayi->addSkill("jinyingshi");
    second_jin_simayi->addSkill("jinxiongzhi");
    second_jin_simayi->addSkill(new JinQuanbian("secondjinquanbian"));
    second_jin_simayi->addSkill(new JinQuanbianLimit("secondjinquanbian"));
    related_skills.insertMulti("secondjinquanbian", "#secondjinquanbian-limit");

    General *jin_zhangchunhua = new General(this, "jin_zhangchunhua", "jin", 3, false);
    jin_zhangchunhua->addSkill(new JinHuishi);
    jin_zhangchunhua->addSkill(new JinQingleng);
    jin_zhangchunhua->addSkill(new JinXuanmu);
    jin_zhangchunhua->addSkill(new JinXuanmuPrevent);
    related_skills.insertMulti("jinxuanmu", "#jinxuanmu");

    General *ol_lisu = new General(this, "ol_lisu", "qun", 3);
    ol_lisu->addSkill(new Qiaoyan);
    ol_lisu->addSkill(new Xianzhu);

    General *jin_simazhou = new General(this, "jin_simazhou", "jin", 4);
    jin_simazhou->addSkill(new JinCaiwang("jincaiwang"));
    jin_simazhou->addSkill(new JinNaxiang);
    jin_simazhou->addSkill(new JinNaxiangClear);
    related_skills.insertMulti("jinnaxiang", "#jinnaxiang-clear");

    General *second_jin_simazhou = new General(this, "second_jin_simazhou", "jin", 4);
    second_jin_simazhou->addSkill(new JinCaiwang("secondjincaiwang"));
    second_jin_simazhou->addSkill("jinnaxiang");

    General *cheliji = new General(this, "cheliji", "qun", 4);
    cheliji->addSkill(new Chexuan);
    cheliji->addSkill(new Qiangshou);
    cheliji->addRelateSkill("_sichengliangyu");
    cheliji->addRelateSkill("_tiejixuanyu");
    cheliji->addRelateSkill("_feilunzhanyu");

    General *ol_huaxin = new General(this, "ol_huaxin", "wei", 3);
    ol_huaxin->addSkill(new Caozhao);
    ol_huaxin->addSkill(new OLXibing);
    ol_huaxin->addSkill(new FakeMoveSkill("olxibing"));
    ol_huaxin->addSkill(new OLXibingPro);
    related_skills.insertMulti("olxibing", "#olxibing-fake-move");
    related_skills.insertMulti("olxibing", "#olxibing-pro");

    addMetaObject<JinYingshiCard>();
    addMetaObject<JinXiongzhiCard>();
    addMetaObject<JinXiongzhiUseCard>();
    addMetaObject<JinQinglengCard>();
    addMetaObject<ChexuanCard>();
    addMetaObject<CaozhaoCard>();
}

ADD_PACKAGE(Li)
