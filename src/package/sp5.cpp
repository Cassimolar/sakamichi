#include "sp5.h"
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
#include "json.h"
#include "yjcm2013.h"
#include "wind.h"

ZhouxuanzCard::ZhouxuanzCard()
{
    mute = true;
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void ZhouxuanzCard::onUse(Room *, const CardUseStruct &) const
{
}

class ZhouxuanzVS :public OneCardViewAsSkill
{
public:
    ZhouxuanzVS() :OneCardViewAsSkill("zhouxuanz")
    {
        expand_pile = "spzhxuan";
        response_pattern = "@@zhouxuanz";
        filter_pattern = ".|.|.|spzhxuan";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ZhouxuanzCard *card = new ZhouxuanzCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Zhouxuanz : public TriggerSkill
{
public:
    Zhouxuanz() : TriggerSkill("zhouxuanz")
    {
        events << EventPhaseStart << EventPhaseEnd << CardUsed << CardResponded;
        view_as_skill = new ZhouxuanzVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->isKongcheng() || player->getPhase() != Player::Discard) return false;
            int num = 5 - player->getPile("spzhxuan").length();
            if (num <= 0) return false;
            const Card *card = room->askForExchange(player, objectName(), num, 1, false, "@zhouxuanz-put", true);
            if (!card) return false;

            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName());

            player->addToPile("spzhxuan", card);
            delete card;
        } else if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play || player->getPile("spzhxuan").isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, objectName());
            player->clearOnePrivatePile("spzhxuan");
        } else {
            QList<int> xuan = player->getPile("spzhxuan");
            if (xuan.isEmpty()) return false;

            const Card *card = NULL;
            if (event == CardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (!card || card->isKindOf("SkillCard")) return false;

            room->sendCompulsoryTriggerLog(player, objectName());

            int num = 1;
            int hand = player->getHandcardNum();
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHandcardNum() >= hand) {
                    num = player->getPile("spzhxuan").length();
                    break;
                }
            }
            player->drawCards(num, objectName());
            if (player->isDead() || player->getPile("spzhxuan").isEmpty()) return false;

            int id = -1;
            if (xuan.length() == 1)
                id = xuan.first();
            else {
                const Card *c = room->askForUseCard(player, "@@zhouxuanz", "@zhouxuanz", -1, Card::MethodNone);
                if (c)
                    id = c->getSubcards().first();
            }
            if (id < 0)
                id = xuan.first();
            CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, player->objectName(), objectName(), QString());
            room->throwCard(Sanguosha->getCard(id), reason, NULL);
        }
        return false;
    }
};

class Xianlve : public PhaseChangeSkill
{
public:
    Xianlve() : PhaseChangeSkill("xianlve")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isLord() && target->getPhase() == Player::Start;
    }

    static QString getOldName(ServerPlayer *player)
    {
        QString old;
        foreach (QString mark, player->getMarkNames()) {
            if (!mark.startsWith("&xianlve+:+") || player->getMark(mark) <= 0) continue;
            QStringList marks = mark.split("+");
            if (marks.length() != 3) continue;
            old = marks.last();
            break;
        }
        return old;
    }

    static void changeTrick(ServerPlayer *player, QString trick_name)
    {
        QString old = getOldName(player);
        if (old == trick_name) return;
        Room *room = player->getRoom();
        if (!old.isEmpty())
            room->setPlayerMark(player, "&xianlve+:+" + old, 0);
        if (!trick_name.isEmpty())
            room->setPlayerMark(player, "&xianlve+:+" + trick_name, 1);
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        if (!isNormalGameMode(room->getMode()))
            return false;

        QList<int> all_tricks = Sanguosha->getRandomCards(), tricks;
        QStringList names;
        foreach (int id, all_tricks) {
            const Card *c = Sanguosha->getEngineCard(id);
            if (!c->isKindOf("TrickCard")) continue;
            QString name = c->objectName();
            if (names.contains(name)) continue;
            names << name;
            tricks << id;
        }
        if (tricks.isEmpty()) return false;

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (!p->askForSkillInvoke(this)) continue;
            room->broadcastSkillInvoke(objectName());
            room->fillAG(tricks, p);
            int id = room->askForAG(p, tricks, false, objectName());
            room->clearAG(p);
            changeTrick(p, Sanguosha->getEngineCard(id)->objectName());
        }
        return false;
    }
};

class XianlveEffect : public TriggerSkill
{
public:
    XianlveEffect() : TriggerSkill("#xianlve-effect")
    {
        events << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("TrickCard")) return false;

        QString name = use.card->objectName();
        QList<int> all_tricks = Sanguosha->getRandomCards(), tricks;
        QStringList names;
        foreach (int id, all_tricks) {
            const Card *c = Sanguosha->getEngineCard(id);
            if (!c->isKindOf("TrickCard")) continue;
            QString name = c->objectName();
            if (names.contains(name)) continue;
            names << name;
            tricks << id;
        }

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill("xianlve")) continue;
            if (p->getMark("xianlve_used-Clear") > 0) continue;
            QString trick = Xianlve::getOldName(p);
            if (trick != name) continue;

            room->addPlayerMark(p, "xianlve_used-Clear");
            room->sendCompulsoryTriggerLog(p, "xianlve", true, true);

            QList<int> draw_ids = room->drawCardsList(p, 2, "xianlve"), ids;
            foreach (int id, draw_ids) {
                if (p->hasCard(id))
                    ids << id;
            }
            if (ids.isEmpty()) continue;

            QHash<ServerPlayer *, QStringList> hash;

            while (p->isAlive()) {
                CardsMoveStruct yiji_move = room->askForYijiStruct(p, ids, objectName(), true, false, true, -1,
                                            room->getOtherPlayers(p), CardMoveReason(), QString(), false, false);
                if (!yiji_move.to || yiji_move.card_ids.isEmpty()) break;

                QStringList id_strings = hash[(ServerPlayer *)yiji_move.to];
                foreach (int id, yiji_move.card_ids) {
                    id_strings << QString::number(id);
                    ids.removeOne(id);
                }
                hash[(ServerPlayer *)yiji_move.to] = id_strings;
                if (ids.isEmpty()) break;
            }

            QList<CardsMoveStruct> moves;
            foreach (ServerPlayer *pp, room->getOtherPlayers(p)) {
                if (pp->isDead()) continue;
                QList<int> ids = StringList2IntList(hash[pp]);
                if (ids.isEmpty()) continue;
                hash.remove(pp);
                CardsMoveStruct move(ids, p, pp, Player::PlaceHand, Player::PlaceHand,
                    CardMoveReason(CardMoveReason::S_REASON_GIVE, p->objectName(), pp->objectName(), "xianlve", QString()));
                moves.append(move);
            }
            if (!moves.isEmpty())
                room->moveCardsAtomic(moves, false);

            if (p->isAlive() && !tricks.isEmpty()) {
                room->fillAG(tricks, p);
                int id = room->askForAG(p, tricks, true, "xianlve");
                room->clearAG(p);
                QString name;
                if (id > 0)
                    name = Sanguosha->getEngineCard(id)->objectName();
                Xianlve::changeTrick(p, name);
            }
        }
        return false;
    }
};

ZaowangCard::ZaowangCard()
{
}

bool ZaowangCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void ZaowangCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *to = effect.to;
    Room *room = to->getRoom();

    room->removePlayerMark(effect.from, "@zaowangMark");
    room->doSuperLightbox("dongzhao", "zaowang");

    room->gainMaxHp(to);
    room->recover(to, RecoverStruct(effect.from));
    to->drawCards(3, "zaowang");

    if (to->isDead()) return;
    room->setPlayerMark(to, "&zaowang", 1);
}

class ZaowangVS : public ZeroCardViewAsSkill
{
public:
    ZaowangVS() : ZeroCardViewAsSkill("zaowang")
    {
    }

    const Card *viewAs() const
    {
        return new ZaowangCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@zaowangMark") > 0;
    }
};

class Zaowang : public TriggerSkill
{
public:
    Zaowang() : TriggerSkill("zaowang")
    {
        events << Death << BeforeGameOverJudge;
        view_as_skill = new ZaowangVS;
        frequency = Limited;
        limit_mark = "@zaowangMark";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (!isNormalGameMode(room->getMode())) return false;
        DeathStruct death = data.value<DeathStruct>();

        if (event == BeforeGameOverJudge) {
            if (!death.who->isLord()) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getRole() == "loyalist" && p->getMark("&zaowang") > 0) {
                    LogMessage log;
                    log.type = "#ZhenguEffect";
                    log.from = p;
                    log.arg = "zaowang";
                    room->sendLog(log);
                    room->broadcastSkillInvoke("zaowang");

                    room->setPlayerMark(p, "&zaowang", 0);
                    room->setPlayerProperty(death.who, "role", "loyalist");
                    room->setPlayerProperty(p, "role", "lord");
                    break;
                }
            }
        } else {
            if (death.who->getRole() != "rebel" || death.who->getMark("&zaowang") <= 0) return false;
            if (!death.damage || !death.damage->from) return false;
            //if (!death.damage->from->getRole().startsWith("l")) return false;
            if (death.damage->from->getRole() == "lord" || death.damage->from->getRole() == "loyalist") {
                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = death.who;
                log.arg = "zaowang";
                room->sendLog(log);
                room->broadcastSkillInvoke("zaowang");
                room->gameOver("lord+loyalist");
            }
        }
        return false;
    }
};

GuowuCard::GuowuCard()
{
    mute = true;
}

bool GuowuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < 2 * Self->getMark("guowu_three-PlayClear") && to_select->hasFlag("guowu_canchoose");
}

void GuowuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to)
        room->setPlayerFlag(p, "guowu_choose");
}

class GuowuVS : public ZeroCardViewAsSkill
{
public:
    GuowuVS() : ZeroCardViewAsSkill("guowu")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@guowu");
    }

    const Card *viewAs() const
    {
        if (Self->hasFlag("guowu_now_use_collateral"))
            return new ExtraCollateralCard;
        else
            return new GuowuCard;
    }
};

class Guowu : public TriggerSkill
{
public:
    Guowu() : TriggerSkill("guowu")
    {
        events << PreCardUsed;
        view_as_skill = new GuowuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Play && target->getMark("guowu_three-PlayClear") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;

        QList<ServerPlayer *> extras = room->getCardTargets(player, use.card, use.to);
        if (extras.isEmpty()) return false;

        int mark = 2 * player->getMark("guowu_three-PlayClear");

        if (use.card->isKindOf("Collateral")) {
            for (int i = 0; i < mark; i++) {
                extras = room->getCardTargets(player, use.card, use.to);
                if (extras.isEmpty()) break;

                QStringList toss;
                foreach(ServerPlayer *t, use.to)
                    toss.append(t->objectName());
                room->setPlayerProperty(player, "extra_collateral", use.card->toString());
                room->setPlayerProperty(player, "extra_collateral_current_targets", toss.join("+"));
                room->setPlayerFlag(player, "guowu_now_use_collateral");

                const Card *card = room->askForUseCard(player, "@@guowu1", "@guowu1:" + use.card->objectName(), 1);

                room->setPlayerFlag(player, "-guowu_now_use_collateral");
                room->setPlayerProperty(player, "extra_collateral", QString());
                room->setPlayerProperty(player, "extra_collateral_current_targets", QString());

                if (!card) break;

                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("ExtraCollateralTarget")) {
                        room->setPlayerFlag(p,"-ExtraCollateralTarget");
                        LogMessage log;
                        log.type = "#QiaoshuiAdd";
                        log.from = player;
                        log.to << p;
                        log.card_str = use.card->toString();
                        log.arg = "guowu";
                        room->sendLog(log);
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
        } else {
            foreach (ServerPlayer *p, extras)
                room->setPlayerFlag(p, "guowu_canchoose");

            room->askForUseCard(player, "@@guowu2", "@guowu2:" + use.card->objectName() + "::" + QString::number(mark), 2);

            QList<ServerPlayer *> adds;
            foreach (ServerPlayer *p, extras) {
                room->setPlayerFlag(p, "-guowu_canchoose");
                if (p->hasFlag("guowu_choose")) {
                    adds << p;
                    room->setPlayerFlag(p, "-guowu_choose");
                }
            }
            if (adds.isEmpty()) return false;

            room->sortByActionOrder(adds);
            LogMessage log;
            log.type = "#QiaoshuiAdd";
            log.from = player;
            log.to = adds;
            log.card_str = use.card->toString();
            log.arg = "guowu";
            room->sendLog(log);
            foreach(ServerPlayer *p, adds)
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

            use.to << adds;
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class GuowuShow : public PhaseChangeSkill
{
public:
    GuowuShow() : PhaseChangeSkill("#guowu-show")
    {
    }

    int getTypeNum(ServerPlayer *player) const
    {
        QList<int> type_ids;
        foreach (const Card *c, player->getHandcards()) {
            int id = c->getTypeId();
            if (type_ids.contains(id)) continue;
            type_ids << id;
        }
        return type_ids.length();
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play || player->isKongcheng() || !player->hasSkill("guowu")) return false;
        int n = getTypeNum(player);
        if (!player->askForSkillInvoke("guowu", "guowu:" + QString::number(n))) return false;

        Room *room = player->getRoom();
        room->broadcastSkillInvoke("guowu");
        room->showAllCards(player);

        n = getTypeNum(player);

        LogMessage log;
        log.type = "#GuoWuType";
        log.from = player;
        log.arg = QString::number(n);
        room->sendLog(log);

        //room->setPlayerMark(player, "guowu-PlayClear", n);以免此阶段再次发动“帼武”出bug

        if (n >= 1) {
            QList<int> slashs;
            foreach (int id, room->getDiscardPile()) {
                if (Sanguosha->getCard(id)->isKindOf("Slash"))
                    slashs << id;
            }
            if (!slashs.isEmpty()) {
                int id = slashs.at(qrand() % slashs.length());
                room->obtainCard(player, id);
            }
        }

        if (n >= 2 && player->isAlive())
            room->addPlayerMark(player, "guowu_two-PlayClear");

        if (n >= 3 && player->isAlive())
            room->addPlayerMark(player, "guowu_three-PlayClear");
        return false;
    }
};

class GuowuTargetMod : public TargetModSkill
{
public:
    GuowuTargetMod() : TargetModSkill("#guowu-target")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("guowu_two-PlayClear") > 0)
            return 1000;
        else
            return 0;
    }
};

class Zhuangrong : public TriggerSkill
{
public:
    Zhuangrong() : TriggerSkill("zhuangrong")
    {
        events << EventPhaseChanging;
        frequency = Wake;
        waked_skills = "shenwei,wushuang";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool canWake(TriggerEvent, ServerPlayer *, QVariant &data, Room *) const
    {
        return data.value<PhaseChangeStruct>().to == Player::NotActive;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || p->getMark(objectName()) > 0) continue;
            if (p->canWake(objectName()) || p->getHandcardNum() == 1 || p->getHp() == 1) {
                room->sendCompulsoryTriggerLog(p, this);
                room->doSuperLightbox("lvlingqi", "zhuangrong");
                room->setPlayerMark(p, objectName(), 1);

                if (room->changeMaxHpForAwakenSkill(p)) {
                    int recover = p->getMaxHp() - p->getHp();
                    room->recover(p, RecoverStruct(p, NULL, recover));
                    p->drawCards(p->getMaxHp() - p->getHandcardNum(), objectName());
                    room->handleAcquireDetachSkills(p, "shenwei|wushuang");
                }
            }
        }
        return false;
    }
};

class Liedan : public PhaseChangeSkill
{
public:
    Liedan() : PhaseChangeSkill("liedan")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Start;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || p->getMark("&zhuangdan-SelfClear") > 0) continue;
            room->sendCompulsoryTriggerLog(p, this);

            int handpl = player->getHandcardNum(), handp = p->getHandcardNum(),
                hppl = player->getHp(), hpp = p->getHp(),
                equippl = player->getEquips().length(), equipp = p->getEquips().length(),
                num = 0;

            if (handp > handpl)
                num++;
            if (hpp > hppl)
                num++;
            if (equipp > equippl)
                num++;

            p->drawCards(num, objectName());

            if (num == 3 && p->isAlive() && p->getMaxHp() < 8)
                room->gainMaxHp(p);
            else if (num == 0 && p->isAlive()) {
                room->loseHp(p);
                if (p->isAlive())
                    p->gainMark("&xhjldlie");
            }
        }
        return false;
    }
};

class LiedanDead : public PhaseChangeSkill
{
public:
    LiedanDead() : PhaseChangeSkill("#liedan-dead")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Start &&
                target->hasSkill("liedan") && target->getMark("&zhuangdan-SelfClear") <= 0 && target->getMark("&xhjldlie") >= 5;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, "liedan", true, true);
        room->killPlayer(player);
        return false;
    }
};

class Zhuangdan : public TriggerSkill
{
public:
    Zhuangdan() : TriggerSkill("zhuangdan")
    {
        events << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool isMaxHandcardnumPlayer(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int hand = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() >= hand)
                return false;
        }
        return true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this) || !isMaxHandcardnumPlayer(p)) continue;
            room->sendCompulsoryTriggerLog(p, this);
            room->setPlayerMark(p, "&zhuangdan-SelfClear", 1);
        }
        return false;
    }
};

YuqiCard::YuqiCard()
{
    mute = true;
    target_fixed = true;
    will_throw = false;
}

void YuqiCard::onUse(Room *, const CardUseStruct &) const
{
}

class YuqiVS : public ViewAsSkill
{
public:
    YuqiVS() : ViewAsSkill("yuqi")
    {
        expand_pile = "#yuqi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (!Self->getPile("#yuqi").contains(to_select->getEffectiveId())) return false;
        int num = Self->getMark("yuqi_help");
        return selected.length() < num;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        int num = Self->getMark("yuqi_help");
        if (cards.length() > num) return NULL;

        YuqiCard *c = new YuqiCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@yuqi");
    }
};


class Yuqi : public MasochismSkill
{
public:
    Yuqi() : MasochismSkill("yuqi")
    {
        view_as_skill = new YuqiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        Room *room = player->getRoom();
        if (!room->hasCurrent()) return;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return;
            if (p->isDead() || !p->hasSkill(this) || p->getMark("yuqi-Clear") >= 2) continue;

            int juli = p->getMark("SkillDescriptionArg1_yuqi");
            juli = qMax(0, juli);
            if (p->distanceTo(player) > juli) continue;

            if (!p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);

            room->addPlayerMark(p, "yuqi-Clear");

            int guankan = p->getMark("SkillDescriptionArg2_yuqi");
            guankan = guankan == 0 ? 3 : guankan;
            guankan = qMin(guankan, 5);
            guankan = qMax(3, guankan);

            int jiaogei = p->getMark("SkillDescriptionArg3_yuqi");
            jiaogei = jiaogei == 0 ? 1 : jiaogei;
            jiaogei = qMin(jiaogei, 5);
            jiaogei = qMax(1, jiaogei);

            QList<int> views = room->showDrawPile(p, guankan, objectName(), false);

            room->notifyMoveToPile(p, views, objectName(), Player::DrawPile, true);
            room->setPlayerMark(p, "yuqi_help", jiaogei);
            const Card *card = room->askForUseCard(p, "@@yuqi1", "@yuqi1:" + player->objectName() + "::" + QString::number(jiaogei), 1, Card::MethodNone);
            room->setPlayerMark(p, "yuqi_help", 0);
            room->notifyMoveToPile(p, views, objectName(), Player::DrawPile, false);

            QList<int> gives;
            if (card)
                gives = card->getSubcards();

            if (!gives.isEmpty()) {
                foreach (int id, gives)
                    views.removeOne(id);
                room->giveCard(p, player, gives, objectName());
            }

            if (p->isDead() || views.isEmpty()) continue;

            int huode = p->getMark("SkillDescriptionArg4_yuqi");
            huode = huode == 0 ? 1 : huode;
            huode = qMin(huode, 5);
            huode = qMax(1, huode);

            room->notifyMoveToPile(p, views, objectName(), Player::DrawPile, true);
            room->setPlayerMark(p, "yuqi_help", huode);
            const Card *card2 = room->askForUseCard(p, "@@yuqi2", "@yuqi2:" + QString::number(huode), 2, Card::MethodNone);
            room->setPlayerMark(p, "yuqi_help", 0);
            room->notifyMoveToPile(p, views, objectName(), Player::DrawPile, false);

            if (!card2) continue;
            room->obtainCard(p, card2, false);
        }
    }
};

class Shanshen : public TriggerSkill
{
public:
    Shanshen() : TriggerSkill("shanshen")
    {
        events << Death;
        frequency = Frequent;
    }

    static QStringList YuqiAddNumChoices(ServerPlayer *p, int num)
    {
        QStringList choices;

        int juli = qMin(p->getMark("SkillDescriptionArg1_yuqi"), 5);
        juli = qMax(0, juli);

        int guankan = p->getMark("SkillDescriptionArg2_yuqi");
        guankan = guankan == 0 ? 3 : guankan;
        guankan = qMin(guankan, 5);
        guankan = qMax(3, guankan);

        int jiaogei = p->getMark("SkillDescriptionArg3_yuqi");
        jiaogei = jiaogei == 0 ? 1 : jiaogei;
        jiaogei = qMin(jiaogei, 5);
        jiaogei = qMax(1, jiaogei);

        int huode = p->getMark("SkillDescriptionArg4_yuqi");
        huode = huode == 0 ? 1 : huode;
        huode = qMin(huode, 5);
        huode = qMax(1, huode);

        if (juli < 5) {
            juli += num;
            juli = qMin(5, juli);
            choices << "juli=" + QString::number(juli);
        }
        if (guankan < 5) {
            guankan += num;
            guankan = qMin(5, guankan);
            choices << "guankan=" + QString::number(guankan);
        }
        if (jiaogei < 5) {
            jiaogei += num;
            jiaogei = qMin(5, jiaogei);
            choices << "jiaogei=" + QString::number(jiaogei);
        }
        if (huode < 5) {
            huode += num;
            huode = qMin(5, huode);
            choices << "huode=" + QString::number(huode);
        }

        return choices;
    }

    static void YuqiAddNum(ServerPlayer *p, int num, const QString &skill)
    {
        Room *room = p->getRoom();

        QStringList choices = YuqiAddNumChoices(p, num);
        if (choices.isEmpty()) return;

        QString choice = room->askForChoice(p, skill, choices.join("+"));

        int number = 1, least = 0;
        if (choice.startsWith("guankan")) {
            least = 3;
            number = 2;
        } else if (choice.startsWith("jiaogei")) {
            least = 1;
            number = 3;
        } else if (choice.startsWith("huode")) {
            least = 1;
            number = 4;
        }

        if (p->getMark("SkillDescriptionArg2_yuqi") == 0)
            room->setPlayerMark(p, "SkillDescriptionArg2_yuqi", 3);
        if (p->getMark("SkillDescriptionArg3_yuqi") == 0)
            room->setPlayerMark(p, "SkillDescriptionArg3_yuqi", 1);
        if (p->getMark("SkillDescriptionArg4_yuqi") == 0)
            room->setPlayerMark(p, "SkillDescriptionArg4_yuqi", 1);

        QString mark_name = "SkillDescriptionArg" + QString::number(number) + "_yuqi";
        int mark = p->getMark(mark_name);
        mark = qMax(mark, least);
        mark += num;
        mark = qMin(5, mark);
        room->setPlayerMark(p, mark_name, mark);

        room->changeTranslation(p, "yuqi", 2);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (!death.who || death.who == player || YuqiAddNumChoices(player, 2).isEmpty() || !player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(this);

        YuqiAddNum(player, 2, objectName());

        if (player->isAlive() && !player->tag["kuimang_damage_" + death.who->objectName()].toBool())
            room->recover(player, RecoverStruct(player));
        return false;
    }
};

class Xianjing : public PhaseChangeSkill
{
public:
    Xianjing() : PhaseChangeSkill("xianjing")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start || Shanshen::YuqiAddNumChoices(player, 1).isEmpty() || !player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(this);
        Shanshen::YuqiAddNum(player, 1, objectName());
        if (player->getLostHp() > 0) return false;
        Shanshen::YuqiAddNum(player, 1, objectName());
        return false;
    }
};

class Huguan : public TriggerSkill
{
public:
    Huguan() : TriggerSkill("huguan")
    {
        events << CardResponded << CardUsed;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Play && target->getMark("wanglie-PlayClear") == 1;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (event == CardUsed)
            card = data.value<CardUseStruct>().card;
        else {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (!resp.m_isUse) return false;
            card = resp.m_card;
        }
        if (!card || card->isKindOf("SkillCard") || !card->isRed()) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (!p->askForSkillInvoke(this, player)) continue;

            int index = qrand() % 2 + 1;
            if (p->getGeneralName().contains("wangyue") || p->getGeneral2Name().contains("wangyue"))
                index += 2;
            room->broadcastSkillInvoke(this, index);

            int suit = int(room->askForSuit(p, objectName()));

            LogMessage log;
            log.type = "#ChooseSuit";
            log.from = p;
            log.arg = Card::Suit2String(Card::Suit(suit));
            room->sendLog(log);

            if (!room->hasCurrent()) continue;
            QVariantList suits = player->tag["HuguanSuits"].toList();
            if (suits.contains(QVariant(suit))) continue;
            suits << suit;
            player->tag["HuguanSuits"] = suits;
        }
        return false;
    }
};

class HuguanIgnore : public TriggerSkill
{
public:
    HuguanIgnore() : TriggerSkill("#huguan")
    {
        events << EventPhaseProceeding << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseProceeding) {
            if (player->isDead() || player->getPhase() != Player::Discard) return false;
            QVariantList suits = player->tag["HuguanSuits"].toList();
            if (suits.isEmpty()) return false;
            QList<int> _suits = VariantList2IntList(suits);

            foreach (const Card *card, player->getHandcards()) {
                int suit = int(card->getSuit());
                if (!_suits.contains(suit)) continue;
                room->ignoreCards(player, card);
            }
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            player->tag.remove("HuguanSuits");
        }
        return false;
    }
};

class Yaopei : public TriggerSkill
{
public:
    Yaopei() : TriggerSkill("yaopei")
    {
        events << CardsMoveOneTime << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardsMoveOneTime && TriggerSkill::triggerable(player)) {
            ServerPlayer *current = room->getCurrent();
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();

            if (!current || player == current || current->getPhase() != Player::Discard)
                return false;

            QVariantList discard_suits = current->tag["YaopeiDiscardSuits"].toList();

            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                int i = 0;
                foreach (int card_id, move.card_ids) {
                    if (move.from == current && (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip)) {
                        int suit = (int)Sanguosha->getCard(card_id)->getSuit();
                        discard_suits << suit;
                    }
                    i++;
                }
            }
            current->tag["YaopeiDiscardSuits"] = discard_suits;
        } else if (triggerEvent == EventPhaseEnd && player->getPhase() == Player::Discard) {
            QVariantList discard_suits = player->tag["YaopeiDiscardSuits"].toList();
            if (discard_suits.isEmpty()) return false;

            try {
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (p->isDead() || !p->hasSkill(this)) continue;

                    QVariantList discard_suits = player->tag["YaopeiDiscardSuits"].toList();

                    QStringList can_discards;
                    foreach (const Card *card, p->getCards("he")) {
                        int suit = (int)card->getSuit();
                        if (!discard_suits.contains(QVariant(suit)) && p->canDiscard(p, card->getEffectiveId()))
                            can_discards << card->toString();
                    }
                    if (can_discards.isEmpty() || !room->askForCard(p, can_discards.join(","), "@yaopei-discard",
                                                 QVariant::fromValue(player), objectName())) continue;

                    if (p->isDead()) continue;

                    QStringList choices;
                    choices << "self=" + player->objectName();
                    if (player->isAlive())
                        choices << "other=" + player->objectName();

                    QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(player));
                    if (choice.startsWith("self")) {
                        room->recover(p, RecoverStruct(p));
                        player->drawCards(2, objectName());
                    } else {
                        room->recover(player, RecoverStruct(p));
                        p->drawCards(2, objectName());
                    }
                }
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                    player->tag.remove("YaopeiDiscardSuits");
                throw triggerEvent;
            }

            player->tag.remove("YaopeiDiscardSuits");
        }
        return false;
    }
};

HeqiaCard::HeqiaCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool HeqiaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self) return false;
    if (subcards.isEmpty())
        return !to_select->isKongcheng();
    return true;
}

void HeqiaCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to, *geter = NULL;
    Room *room = from->getRoom();

    int num = subcardsLength();

    if (subcards.isEmpty()) {
        if (to->isNude()) return;
        const Card *card = room->askForExchange(to, "heqia", 99999, 1, true, "@heqia-give:" + from->objectName());
        geter = from;
        num = card->subcardsLength();
        room->giveCard(to, from, card, "heqia");
        delete card;
    } else {
        geter = to;
        room->giveCard(from, to, this, "heqia");
    }
    if (!geter || geter->isDead() || geter->isKongcheng() || num <= 0) return;

    QList<int> cards = room->getAvailableCardList(geter, "basic", "heqia");
    room->fillAG(cards, geter);
    int id = room->askForAG(geter, cards, true, "heqia");
    room->clearAG(geter);
    if (id < 0) return;

    const Card *card = Sanguosha->getEngineCard(id);
    QString name = card->objectName();

    int extra = qMax(num - 1, 0);
    if (card->targetFixed())
        num = num - 1;

    room->setPlayerProperty(geter, "heqia_card_name", name);
    room->setPlayerMark(geter, "heqia_get_card", num);
    QString prompt = "@heqia2:" + name + "::" + QString::number(extra);
    room->askForUseCard(geter, "@@heqia2", prompt, 2, Card::MethodUse, false);
    room->setPlayerProperty(geter, "heqia_card_name", QString());
    room->setPlayerMark(geter, "heqia_get_card", 0);
}

HeqiaUseCard::HeqiaUseCard()
{
    will_throw = false;
    handling_method = Card::MethodUse;
    m_skillName = "heqia";
    mute = true;
}

bool HeqiaUseCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int mark = Self->getMark("heqia_get_card");
    QString name = Self->property("heqia_card_name").toString();
    if (name.isEmpty()) return false;

    Card *card = Sanguosha->cloneCard(name, Card::SuitToBeDecided, -1);
    card->addSubcard(this);
    card->setSkillName("_heqia");
    card->deleteLater();

    if (mark <= 0 && card->targetFixed())
        return !Self->isProhibited(Self, card) && to_select == Self &&
                !Self->isLocked(card) && card->isAvailable(Self); // card->targetFilter(targets, Self, Self)

    if (card->isKindOf("Peach") && !to_select->isWounded())
        return false;

    if (card->targetFixed())
        return targets.length() < mark && !Self->isProhibited(to_select, card) && //&& card->targetFilter(targets, to_select, Self) &&
                !Self->isLocked(card) && card->isAvailable(Self) && to_select != Self;

    return targets.length() < mark && !Self->isProhibited(to_select, card) && card->targetFilter(targets, to_select, Self) &&
            !Self->isLocked(card) && card->isAvailable(Self);
}

bool HeqiaUseCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    QString name = Self->property("heqia_card_name").toString();
    if (name.isEmpty()) return false;
    Card *card = Sanguosha->cloneCard(name, Card::SuitToBeDecided, -1);
    card->addSubcard(this);
    card->setSkillName("_heqia");
    card->deleteLater();
    if (Self->isLocked(card) || !card->isAvailable(Self)) return false;
    if (card->targetFixed())
        return true;
    return !targets.isEmpty();
}

void HeqiaUseCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *from = card_use.from;
    QString name = from->property("heqia_card_name").toString();
    if (name.isEmpty()) return;

    Card *card = Sanguosha->cloneCard(name, Card::SuitToBeDecided, -1);
    card->addSubcard(this);
    card->setSkillName("_heqia");
    card->deleteLater();
    if (from->isLocked(card) || !card->isAvailable(from)) return;

    QList<ServerPlayer *> tos = card_use.to;
    if (card->targetFixed() && !tos.contains(from))
        tos << from;
    room->sortByActionOrder(tos);
    room->useCard(CardUseStruct(card, from, tos), false);
}

class HeqiaVS : public ViewAsSkill
{
public:
    HeqiaVS() : ViewAsSkill("heqia")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->getCurrentCardUsePattern().endsWith("1"))
            return true;

        QString name = Self->property("heqia_card_name").toString();
        if (name.isEmpty()) return false;
        Card *card = Sanguosha->cloneCard(name, Card::SuitToBeDecided, -1);
        card->addSubcard(to_select);
        card->setSkillName("_heqia");
        card->deleteLater();
        return selected.isEmpty() && !Self->isLocked(card) && card->isAvailable(Self);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->getCurrentCardUsePattern().endsWith("1")) {
            HeqiaCard *c = new HeqiaCard;
            if (!cards.isEmpty())
                c->addSubcards(cards);
            return c;
        } else {
            if (cards.isEmpty()) return NULL;
            HeqiaUseCard *c = new HeqiaUseCard;
            c->addSubcards(cards);
            return c;
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@heqia");
    }
};

class Heqia : public PhaseChangeSkill
{
public:
    Heqia() : PhaseChangeSkill("heqia")
    {
        view_as_skill = new HeqiaVS;
    }

    /*QDialog *getDialog() const
    {
        //if (Sanguosha->getCurrentCardUsePattern() == "@@heqia1") return NULL;
        return GuhuoDialog::getInstance("heqia", true, false, false);
    }*/

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        Room *room = player->getRoom();
        room->askForUseCard(player, "@@heqia1", "@heqia1", 1, Card::MethodNone);
        return false;
    }
};

class HeqiaTargetMod : public TargetModSkill
{
public:
    HeqiaTargetMod() : TargetModSkill("#heqia")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->getSkillName() == "heqia")
            return 1000;
        else
            return 0;
    }

    int getExtraTargetNum(const Player *from, const Card *card) const
    {
        int mark = from->getMark("heqia_get_card");
        if (card->getSkillName() == "heqia")
            return qMax(0, mark--);
        else
            return 0;
    }
};

class Yinyi : public TriggerSkill
{
public:
    Yinyi() : TriggerSkill("yinyi")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent() || player->getMark("yinyi-Clear") > 0) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from || damage.from == player || damage.nature == DamageStruct::Normal) return false;
        if (damage.from->getHandcardNum() == player->getHandcardNum() ||
                damage.from->getHp() == player->getHp()) return false;

        room->addPlayerMark(player, "yinyi-Clear");
        LogMessage log;
        log.type = "#RenshiPrevent";
        log.from = player;
        log.arg = objectName();
        log.to << damage.from;
        log.arg2 = QString::number(damage.damage);
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);
        return true;
    }
};

class Lanjiang : public PhaseChangeSkill
{
public:
    Lanjiang() : PhaseChangeSkill("lanjiang")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();

        QList<ServerPlayer *> players;
        int hand = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getHandcardNum() >= hand)
                players << p;
        }
        if (players.isEmpty() || !player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(this);

        foreach (ServerPlayer *p, players) {
            if (player->isDead()) return false;
            if (p->isDead()) continue;
            if (!p->askForSkillInvoke("lanjiang_draw", "lanjiang:" + player->objectName(), false)) continue;
            player->drawCards(1, objectName());
        }
        if (player->isDead()) return false;

        QList<ServerPlayer *> targets;
        hand = player->getHandcardNum();
        foreach (ServerPlayer *p, players) {
            if (p->isDead()) continue;
            if (p->getHandcardNum() == hand)
                targets << p;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@lanjiang-damage", true);
        if (!t) return false;
        room->doAnimate(1, player->objectName(), t->objectName());
        room->damage(DamageStruct(objectName(), player, t));

        if (player->isDead()) return false;

        targets.clear();
        hand = player->getHandcardNum();
        foreach (ServerPlayer *p, players) {
            if (p->isDead()) continue;
            if (p->getHandcardNum() < hand)
                targets << p;
        }
        if (targets.isEmpty()) return false;

        t = room->askForPlayerChosen(player, targets, objectName(), "@lanjiang-draw");
        room->doAnimate(1, player->objectName(), t->objectName());
        t->drawCards(1, objectName());
        return false;
    }
};

class Mingluan : public PhaseChangeSkill
{
public:
    Mingluan() : PhaseChangeSkill("mingluan")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        if (!room->getTag("MingLuanRecover").toBool()) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this) || !p->canDiscard(p, "he")) continue;
            if (!room->askForCard(p, "..", "@mingluan-discard", QVariant(), objectName())) continue;
            room->broadcastSkillInvoke(this);
            ServerPlayer *current = room->getCurrent();
            if (!current || current->isDead()) continue;
            int hand = current->getHandcardNum(), han = p->getHandcardNum();
            if (hand + han > 5)
                hand = 5 - han;
            if (hand > 0)
                p->drawCards(hand, objectName());
        }
        return false;
    }
};

class MingluanRecord : public TriggerSkill
{
public:
    MingluanRecord() : TriggerSkill("#mingluan")
    {
        events << HpRecover << EventPhaseChanging;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == HpRecover) {
            if (!room->hasCurrent()) return false;
            room->setTag("MingLuanRecover", true);
        } else {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setTag("MingLuanRecover", false);
        }
        return false;
    }
};

class Bingqing : public TriggerSkill
{
public:
    Bingqing() : TriggerSkill("bingqing")
    {
        events << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card || use.card->isKindOf("SkillCard") || !use.card->hasSuit()) return false;
        QString suit_str = use.card->getSuitString();
        if (player->getMark("bingqing_" + suit_str + "-PlayClear") > 0) return false;
        room->addPlayerMark(player, "bingqing_" + suit_str + "-PlayClear");
        room->addPlayerMark(player, "bingqing_suit-PlayClear");

        if (!player->hasSkill(this)) return false;

        int mark = player->getMark("bingqing_suit-PlayClear");
        QList<ServerPlayer *> players = room->getAlivePlayers();

        if (mark == 4) {
            players = room->getOtherPlayers(player);
            ServerPlayer *t = room->askForPlayerChosen(player, players, objectName(), "@bingqing-damage", true, true);
            if (!t) return false;
            room->broadcastSkillInvoke(this);
            room->damage(DamageStruct(objectName(), player, t));
        } else if (mark == 3) {
            players.clear();
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (player->canDiscard(p, "hej"))
                    players << p;
            }
            if (players.isEmpty()) return false;
            ServerPlayer *t = room->askForPlayerChosen(player, players, objectName(), "@bingqing-discard", true, true);
            if (!t) return false;
            room->broadcastSkillInvoke(this);
            int id = room->askForCardChosen(player, t, "hej", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, t, player);
        } else if (mark == 2) {
            ServerPlayer *t = room->askForPlayerChosen(player, players, objectName(), "@bingqing-draw", true, true);
            if (!t) return false;
            room->broadcastSkillInvoke(this);
            t->drawCards(2, objectName());
        }
        return false;
    }
};

class Yingfeng : public PhaseChangeSkill
{
public:
    Yingfeng() : PhaseChangeSkill("yingfeng")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        Room *room = player->getRoom();

        bool has_mark = false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark("&mjyffeng") > 0)
                has_mark = true;
            else
                targets << p;
        }
        if (targets.isEmpty()) return false;

        if (has_mark) {
            ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@yingfeng-transfer", true, true);
            if (!t) return false;
            room->broadcastSkillInvoke(this);
            int mark = 0;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                int m = p->getMark("&mjyffeng");
                mark += m;
                p->loseAllMarks("&mjyffeng");
            }
            if (t->isAlive() && mark > 0)
                t->gainMark("&mjyffeng", mark);
        } else {
            ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@yingfeng-gain", true, true);
            if (!t) return false;
            room->broadcastSkillInvoke(this);
            t->gainMark("&mjyffeng");
        }
        return false;
    }
};

class YingfengTarget : public TargetModSkill
{
public:
    YingfengTarget() : TargetModSkill("#yingfeng")
    {
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        bool has_yingfeng = false;
        QList<const Player *> als = from->getAliveSiblings();
        als << from;
        foreach (const Player *p, als) {
            if (p->hasSkill("yingfeng")) {
                has_yingfeng = true;
                break;
            }
        }

        if (has_yingfeng && from->getMark("&mjyffeng") > 0)
            return 1000;
        return 0;
    }
};

class JixianZL : public TriggerSkill
{
public:
    JixianZL() : TriggerSkill("jixianzl")
    {
        events << EventPhaseEnd;
    }

    static int getSkills(ServerPlayer *player)
    {
        int num = 0;
        foreach (const Skill *sk, player->getVisibleSkillList()) {
            if (sk->isAttachedLordSkill()) continue;
            num++;
        }
        return num;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Draw) return false;

        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->deleteLater();
        slash->setSkillName("jixianzl");

        QList<ServerPlayer *> players;
        int skill = getSkills(player);
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!player->canSlash(p, slash, false)) continue;
            if (!p->getEquips().isEmpty())
                players << p;
            else if (p->getLostHp() == 0)
                players << p;
            else if (getSkills(p) > skill)
                players << p;
        }
        if (players.isEmpty()) return false;

        ServerPlayer *t = room->askForPlayerChosen(player, players, objectName(), "@jixianzl-slash", true);
        if (!t) return false;

        room->setCardFlag(slash, "jixianzl_slash_to_" + t->objectName());
        room->setCardFlag(slash, "jixianzl_slash_from_" + player->objectName());

        room->useCard(CardUseStruct(slash, player, t), true);
        return false;
    }
};

class JixianZLEffect : public TriggerSkill
{
public:
    JixianZLEffect() : TriggerSkill("#jixianzl")
    {
        events << CardFinished << DamageDone;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (!damage.card->hasFlag("jixianzl_slash_to_" + player->objectName())) return false;
            room->setCardFlag(damage.card, "jixianzl_slash_damage");
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || !use.card->isKindOf("Slash")) return false;

            ServerPlayer *from = NULL, *to = NULL;
            foreach (QString flag, use.card->getFlags()) {
                if (!flag.startsWith("jixianzl_slash_from_")) continue;
                QStringList flags = flag.split("_");
                if (flags.length() != 4) continue;
                from = room->findChild<ServerPlayer *>(flags.last());
                break;
            }
            foreach (QString flag, use.card->getFlags()) {
                if (!flag.startsWith("jixianzl_slash_to_")) continue;
                QStringList flags = flag.split("_");
                if (flags.length() != 4) continue;
                to = room->findChild<ServerPlayer *>(flags.last());
                break;
            }

            if (!from || from->isDead()) return false;

            if (to && to->isAlive()) {
                int num = 0;
                if (!to->getEquips().isEmpty())
                    num++;
                if (to->getLostHp() == 0)
                    num++;
                if (JixianZL::getSkills(to) > JixianZL::getSkills(from))
                    num++;
                from->drawCards(num, "jixianzl");
            }

            if (use.card->hasFlag("jixianzl_slash_damage")) return false;
            room->loseHp(from);
        }
        return false;
    }
};

class TenyearZhanyi : public PhaseChangeSkill
{
public:
    TenyearZhanyi() : PhaseChangeSkill("tenyearzhanyi")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;

        QStringList choices;
        foreach (const Card *c, player->getCards("he")) {
            int id = c->getEffectiveId();
            if (c->isKindOf("BasicCard") && player->canDiscard(player, id) && !choices.contains("basic"))
                choices << "basic";
            else if (c->isKindOf("TrickCard") && player->canDiscard(player, id) && !choices.contains("trick"))
                choices << "trick";
            else if (c->isKindOf("EquipCard") && player->canDiscard(player, id) && !choices.contains("equip"))
                choices << "equip";
        }
        if (choices.isEmpty()) return false;
        choices << "cancel";

        Room *room = player->getRoom();
        QString choice = room->askForChoice(player, objectName(), choices.join("+"));
        if (choice == "cancel") return false;

        QStringList choice_list, pattern_list;
        choice_list << "basic" << "trick" << "equip";
        pattern_list << "BasicCard" << "TrickCard" << "EquipCard";

        QString pattern = pattern_list.at(choice_list.indexOf(choice));

        foreach (QString cho, choice_list) {
            if (cho == choice) continue;
            room->addPlayerMark(player, "tenyearzhanyi_" + cho + "-Clear");
        }

        DummyCard *dummy = new DummyCard();
        dummy->deleteLater();
        foreach (const Card *c, player->getCards("he")) {
            int id = c->getEffectiveId();
            if (c->isKindOf(pattern.toStdString().c_str()) && player->canDiscard(player, id))
                dummy->addSubcard(id);
        }
        if (dummy->subcardsLength() > 0) {
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            player->peiyin(this);

            room->throwCard(dummy, player);
        }
        return false;
    }
};

class TenyearZhanyiEffect : public TriggerSkill
{
public:
    TenyearZhanyiEffect() : TriggerSkill("#tenyearzhanyi")
    {
        events << ConfirmDamage << PreHpRecover << CardUsed << EventPhaseProceeding;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int basic = player->getMark("tenyearzhanyi_basic-Clear");
        int trick = player->getMark("tenyearzhanyi_trick-Clear");
        int equip = player->getMark("tenyearzhanyi_equip-Clear");

        if (event == CardUsed) {
            if (player->isDead()) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("TrickCard") && trick > 0) {
                room->sendCompulsoryTriggerLog(player, "tenyearzhanyi", true, true);
                player->drawCards(trick, "tenyearzhanyi");
            } else if (use.card->isKindOf("EquipCard") && equip > 0) {
                for (int i = 0; i < equip; i++) {
                    if (player->isDead()) return false;
                    QList<ServerPlayer *> targets;
                    foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                        if (player->canDiscard(p, "he"))
                            targets << p;
                    }
                    if (targets.isEmpty()) return false;
                    ServerPlayer *t = room->askForPlayerChosen(player, targets, "tenyearzhanyi", "@tenyearzhanyi-discard", true, true);
                    if (!t) break;
                    player->peiyin("tenyearzhanyi");
                    int id = room->askForCardChosen(player, t, "he", "tenyearzhanyi", false, Card::MethodDiscard);
                    room->throwCard(id, t, player);
                }
            }
        } else if (event == EventPhaseProceeding) {
            if (player->isDead() || player->getPhase() != Player::Discard || trick <= 0) return false;
            foreach (const Card *c, player->getCards("h")) {
                if (c->isKindOf("TrickCard"))
                    room->ignoreCards(player, c);
            }
        } else if (event == ConfirmDamage) {
            if (basic <= 0) return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("BasicCard")) return false;
            damage.damage += basic;
            LogMessage log;
            log.type = "#NewlonghunDamage";
            log.from = player;
            log.to << damage.to;
            log.arg = "tenyearzhanyi";
            log.arg2 = QString::number(damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, "tenyearzhanyi");
            player->peiyin("tenyearzhanyi");
            data = QVariant::fromValue(damage);
        } else if (event == PreHpRecover) {
            RecoverStruct recover = data.value<RecoverStruct>();
            if (!recover.card || !recover.card->isKindOf("BasicCard") || !recover.who) return false;
            basic = recover.who->getMark("tenyearzhanyi_basic-Clear");
            if (basic <= 0) return false;
            int old = recover.recover;
            recover.recover += basic;
            int now = qMin(recover.recover, player->getMaxHp() - player->getHp());
            if (now <= 0)
                return true;
            if (now > old) {
                LogMessage log;
                log.type = "#NewlonghunRecover";
                log.from = recover.who;
                log.to << player;
                log.arg = "tenyearzhanyi";
                log.arg2 = QString::number(now);
                room->sendLog(log);
                room->notifySkillInvoked(recover.who, "tenyearzhanyi");
                recover.who->peiyin("tenyearzhanyi");
            }
            recover.recover = now;
            data = QVariant::fromValue(recover);
        }
        return false;
    }
};

class TenyearZhanyiTarget : public TargetModSkill
{
public:
    TenyearZhanyiTarget() : TargetModSkill("#tenyearzhanyi-mod")
    {
        pattern = "BasicCard";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("tenyearzhanyi_basic-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

JinhuiCard::JinhuiCard()
{
    target_fixed = true;
}

void JinhuiCard::usecard(Room *room, ServerPlayer *source, ServerPlayer *target, const Card *card) const
{
    QList<ServerPlayer *> targets;
    targets << target;
    if (card->isKindOf("Collateral")) {
        QList<ServerPlayer *> victims;
        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
            if (target->canSlash(p))
                victims << p;
        }
        if (victims.isEmpty()) return;
        ServerPlayer *victim = room->askForPlayerChosen(source, victims, "jinhui_collateral", "@jinhui-collateral:" + target->objectName());
        target->tag["collateralVictim"] = QVariant::fromValue(victim);
        LogMessage log;
        log.type = "#CollateralSlash";
        log.from = source;
        log.to << victim;
        room->sendLog(log);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());
        targets << victim;
    }
    if (card->targetFixed())
        room->useCard(CardUseStruct(card, source, source));
    else
       room->useCard(CardUseStruct(card, source, targets));
}

void JinhuiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> drawpile, show;
    QStringList names;
    foreach (int id, room->getDrawPile()) {
        const Card *card = Sanguosha->getCard(id);
        if (!card->isSingleTargetCard()) continue;
        QString name = card->objectName();
        if (!names.contains(name))
            names << name;
        drawpile << id;
    }

    int i = 0;
    while (i < 3) {
        if (drawpile.isEmpty()) break;
        i++;
        int id = drawpile.at(qrand() % drawpile.length());
        show << id;
        const Card *card = Sanguosha->getCard(id);
        foreach (int idd, drawpile) {
            const Card *c = Sanguosha->getCard(idd);
            if (card->sameNameWith(c))
                drawpile.removeOne(idd);
        }
    }
    if (show.isEmpty()) return;

    CardsMoveStruct move(show, NULL, Player::PlaceTable,
        CardMoveReason(CardMoveReason::S_REASON_TURNOVER, source->objectName(), "jinhui", QString()));
    room->moveCardsAtomic(move, true);

    ServerPlayer *t = room->askForPlayerChosen(source, room->getOtherPlayers(source), "jinhui", "@jinhui-choose");
    room->doAnimate(1, source->objectName(), t->objectName());

    try {
        QList<int> uses;
        foreach (int id, show) {
            const Card *c = Sanguosha->getCard(id);
            room->setCardFlag(c, "jinhui_card");
            if (t->canUse(c, c->targetFixed() ? t : source, true))
                uses << id;
            room->setCardFlag(c, "-jinhui_card");
        }
        if (!uses.isEmpty()) {
            room->notifyMoveToPile(t, uses, "jinhui", Player::PlaceTable, true);
            const Card *card = room->askForUseCard(t, "@@jinhui2!", "@jinhui2", 2);
            room->notifyMoveToPile(t, uses, "jinhui", Player::PlaceTable, false);
            int id = -1;
            if (!card) {
                id = show.at(qrand() % show.length());
                card = Sanguosha->getCard(id);
            } else
                id = card->getSubcards().first();
            show.removeOne(id);
            const Card *t_card = Sanguosha->getCard(id);
            usecard(room, t, source, t_card);
        }

        for (int i = 0; i < 2; i++) {
            if (source->isDead()) break;
            uses.clear();
            foreach (int id, show) {
                const Card *c = Sanguosha->getCard(id);
                room->setCardFlag(c, "jinhui_card");
                if (source->canUse(c, c->targetFixed() ? source : t, true))
                    uses << id;
                room->setCardFlag(c, "-jinhui_card");
            }
            if (!uses.isEmpty()) {
                room->notifyMoveToPile(source, uses, "jinhui", Player::PlaceTable, true);
                const Card *card = room->askForUseCard(source, "@@jinhui1", "@jinhui1", 1);
                room->notifyMoveToPile(source, uses, "jinhui", Player::PlaceTable, false);
                if (!card) break;
                int id = card->getSubcards().first();
                show.removeOne(id);
                const Card *t_card = Sanguosha->getCard(id);
                usecard(room, source, t, t_card);
            }
        }

        if (!show.isEmpty()) {
            DummyCard *dummy = new DummyCard(show);
            dummy->deleteLater();
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, source->objectName(), "jinhui", QString());
            room->throwCard(dummy, reason, NULL);
        }
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
            if (!show.isEmpty()) {
                DummyCard *dummy = new DummyCard(show);
                dummy->deleteLater();
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, source->objectName(), "jinhui", QString());
                room->throwCard(dummy, reason, NULL);
            }
        }
        throw triggerEvent;
    }
}

JinhuiUseCard::JinhuiUseCard()
{
    will_throw = false;
    target_fixed = true;
    m_skillName = "jinhui";
    mute = true;
}

void JinhuiUseCard::onUse(Room *, const CardUseStruct &) const
{
}

class Jinhui : public ViewAsSkill
{
public:
    Jinhui() : ViewAsSkill("jinhui")
    {
        expand_pile = "#jinhui";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return false;
        return selected.isEmpty() && Self->getPile("#jinhui").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return new JinhuiCard();

        if (cards.isEmpty()) return NULL;
        JinhuiUseCard *card = new JinhuiUseCard();
        card->addSubcards(cards);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JinhuiCard");
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@jinhui");
    }
};

class JinhuiTarget : public TargetModSkill
{
public:
    JinhuiTarget() : TargetModSkill("#jinhui-target")
    {
        frequency = NotFrequent;
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("jinhui_card"))
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("jinhui_card"))
            return 1000;
        else
            return 0;
    }
};

class Qingman : public TriggerSkill
{
public:
    Qingman() : TriggerSkill("qingman")
    {
        events << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getnum(ServerPlayer *player) const
    {
        int num = 0;
        for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
            if (player->hasEquipArea(i) && !player->getEquip(i))
                num++;
        }
        return num;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        ServerPlayer *current = room->getCurrent();
        if (!current || current->isDead()) return false;
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            int num = getnum(current);
            if (num > p->getHandcardNum()) {
                room->sendCompulsoryTriggerLog(p, this);
                p->drawCards(num - p->getHandcardNum(), objectName());
            }
        }
        return false;
    }
};

class Saodi : public TriggerSkill
{
public:
    Saodi() : TriggerSkill("saodi")
    {
        events << TargetSpecifying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
        if (use.card->isKindOf("Collateral")) return false;
        ServerPlayer *first = use.to.first();
        if (use.to.length() != 1 || first == player) return false;

        QList<ServerPlayer *> rights, lefts;

        ServerPlayer *next = player->getNextAlive();
        while (next != first) {
            rights << next;
            next = next->getNextAlive();
        }

        next = first->getNextAlive();
        while (next != player) {
            lefts << next;
            next = next->getNextAlive();
        }

        int right = rights.length(), left = lefts.length();

        if (right <= 0 || left <= 0) return false;
        QString name = use.card->objectName();
        QStringList choices;
        if (right < left)
            choices << "right=" + name;
        else if (left < right)
            choices << "left=" + name;
        else {
            choices << "right=" + name;
            choices << "left=" + name;
        }
        choices << "cancel";

        QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
        if (choice == "cancel") return false;

        room->sortByActionOrder(lefts);

        LogMessage log;
        log.type = "#QiaoshuiAdd";
        log.from = player;
        log.card_str = use.card->toString();
        log.arg = objectName();
        log.to = choice.startsWith("right") ? rights : lefts;
        room->sendLog(log);

        foreach (ServerPlayer *p, log.to)
            room->doAnimate(1, player->objectName(), p->objectName());

        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);

        use.to << log.to;
        data = QVariant::fromValue(use);
        return false;
    }
};

class Zhuitao : public TriggerSkill
{
public:
    Zhuitao() : TriggerSkill("zhuitao")
    {
        events << EventPhaseStart << Damage;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Start) return false;
            QList<ServerPlayer *> players;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMark("&zhuitao+#" + player->objectName()) <= 0)
                    players << p;
            }
            if (players.isEmpty()) return false;
            ServerPlayer *t = room->askForPlayerChosen(player, players, objectName(), "@zhuitao-invoke", true, true);
            if (!t) return false;
            room->broadcastSkillInvoke(this);
            room->addPlayerMark(t, "&zhuitao+#" + player->objectName());
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to->isDead() || damage.to->getMark("&zhuitao+#" + player->objectName()) <= 0) return false;
            LogMessage log;
            log.type = "#ZhuitaoDistance";
            log.arg = objectName();
            log.from = player;
            log.to << damage.to;
            room->sendLog(log);
            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(this);
            room->setPlayerMark(damage.to, "&zhuitao+#" + player->objectName(), 0);
        }
        return false;
    }
};

class ZhuitaoDistance : public DistanceSkill
{
public:
    ZhuitaoDistance() : DistanceSkill("#zhuitao")
    {
    }

    int getCorrect(const Player *from, const Player *to) const
    {
        if (from->hasSkill("zhuitao"))
            return -to->getMark("&zhuitao+#" + from->objectName());
        else
            return 0;
    }
};

JiqiaosyCard::JiqiaosyCard()
{
    will_throw = false;
    target_fixed = true;
    m_skillName = "jiqiaosy";
    mute = true;
}

void JiqiaosyCard::onUse(Room *, const CardUseStruct &) const
{
}

class JiqiaosyVS : public OneCardViewAsSkill
{
public:
    JiqiaosyVS() : OneCardViewAsSkill("jiqiaosy")
    {
        expand_pile = "jiqiaosy";
        filter_pattern = ".|.|.|jiqiaosy";
        response_pattern = "@@jiqiaosy!";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        JiqiaosyCard *card = new JiqiaosyCard();
        card->addSubcard(originalCard);
        return card;
    }
};

class Jiqiaosy : public TriggerSkill
{
public:
    Jiqiaosy() : TriggerSkill("jiqiaosy")
    {
        events << EventPhaseStart << CardFinished;
        view_as_skill = new JiqiaosyVS;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            int maxhp = player->getMaxHp();
            if (maxhp <= 0 || !player->askForSkillInvoke(this, "jiqiaosy:" + QString::number(maxhp))) return false;
            room->broadcastSkillInvoke(this);
            player->addToPile(objectName(), room->getNCards(maxhp));
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard")) return false;
            QList<int> jiqiaosy = player->getPile(objectName());
            if (jiqiaosy.isEmpty()) return false;

            room->sendCompulsoryTriggerLog(player, this);

            int id = -1;
            if (jiqiaosy.length() == 1)
                id = jiqiaosy.first();
            else {
                const Card *card = room->askForUseCard(player, "@@jiqiaosy!", "@jiqiaosy", -1, Card::MethodNone);
                if (card)
                    id = card->getSubcards().first();
                else
                    id = jiqiaosy.at(qrand() % jiqiaosy.length());
            }
            if (id < 0) return false;

            LogMessage log;
            log.type = "$KuangbiGet";
            log.from = player;
            log.arg = "jiqiaosy";
            log.card_str = QString::number(id);
            room->sendLog(log);
            room->obtainCard(player, id);

            if (player->isDead()) return false;

            jiqiaosy = player->getPile(objectName());
            int red = 0, black = 0;

            foreach (int id, jiqiaosy) {
                const Card *card = Sanguosha->getCard(id);
                if (card->isRed())
                    red++;
                else if (card->isBlack())
                    black++;
            }

            if (red == black)
                room->recover(player, RecoverStruct(player));
            else
                room->loseHp(player);
        }
        return false;
    }
};

class JiqiaosyEnter : public TriggerSkill
{
public:
    JiqiaosyEnter() : TriggerSkill("#jiqiaosy")
    {
        events << EventPhaseEnd;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && !target->getPile("jiqiaosy").isEmpty() && target->getPhase() == Player::Play;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, "jiqiaosy", true, true);
        player->clearOnePrivatePile("jiqiaosy");
        return false;
    }
};

class Xiongyisy : public TriggerSkill
{
public:
    Xiongyisy() : TriggerSkill("xiongyisy")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@xiongyisyMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("@xiongyisyMark") <= 0) return false;
        if (!player->askForSkillInvoke(this, data)) return false;

        player->peiyin(this);
        room->doSuperLightbox("sunyi", "xiongyisy");
        room->removePlayerMark(player, "@xiongyisyMark");

        bool xushi = false;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (Sanguosha->translate(p->getGeneralName()).contains("徐氏") ||
                    (p->getGeneral2() && Sanguosha->translate(p->getGeneral2Name()).contains("徐氏"))) {
                xushi = true;
                break;
            }
        }

        int n = -1;
        if (!xushi) {
            n = qMin(3, player->getMaxHp()) - player->getHp();
            if (n > 0)
                room->recover(player, RecoverStruct(player, NULL, n));
            room->setPlayerProperty(player, "ChangeHeroMaxHp", player->getMaxHp() + 1);
            room->changeHero(player, "xushi", false, false);
            if (player->getPile("jiqiaosy").isEmpty()) return false;
            player->clearOnePrivatePile("jiqiaosy");
        } else {
            n = qMin(1, player->getMaxHp()) - player->getHp();
            if (n > 0)
                room->recover(player, RecoverStruct(player, NULL, n));
            room->acquireSkill(player, "hunzi");
        }
        return false;
    }
};

XiongmangCard::XiongmangCard()
{
    mute = true;
}

bool XiongmangCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *slash = Card::Parse(Self->property("xiongmang").toString());
    return slash && !to_select->hasFlag("xiongmang_target") && targets.length() < slash->subcardsLength() - 1 &&
            Self->canSlash(to_select, slash);
}

void XiongmangCard::onUse(Room *room, const CardUseStruct &use) const
{
    foreach (ServerPlayer *p, use.to)
        room->setPlayerFlag(p, "xiongmang_add_target");
}

class XiongmangVS : public ViewAsSkill
{
public:
    XiongmangVS() : ViewAsSkill("xiongmang")
    {
        response_or_use = true;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->getCurrentCardUsePattern() == "@@xiongmang") return false;
        if (to_select->isEquipped()) return false;
        Slash *slash = new Slash(Card::SuitToBeDecided, -1);
        slash->setSkillName(objectName());
        slash->deleteLater();
        foreach (const Card *c, selected) {
            if (c->getSuit() == to_select->getSuit()) return false;
            slash->addSubcard(c);
        }
        slash->addSubcard(to_select);
        return !Self->isLocked(to_select, true);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            if (cards.isEmpty()) return NULL;
            Card *slash = new Slash(Card::SuitToBeDecided, -1);
            slash->addSubcards(cards);
            slash->setSkillName(objectName());
            return slash;
        } else if (Sanguosha->getCurrentCardUsePattern() == "@@xiongmang") {
            if (!cards.isEmpty()) return NULL;
            return new XiongmangCard;
        }

        return NULL;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.contains("slash") || pattern.contains("Slash") || pattern == "@@xiongmang";
    }
};

class Xiongmang : public TriggerSkill
{
public:
    Xiongmang() : TriggerSkill("xiongmang")
    {
        events << PreChangeSlash;
        view_as_skill = new XiongmangVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        if (use.card->getSkillName() != objectName() && !use.card->hasFlag(objectName())) return false;
        room->setCardFlag(use.card, "xiongmang_" + player->objectName());

        foreach (ServerPlayer *p, use.to)
            room->setPlayerFlag(p, "xiongmang_target");
        room->setPlayerProperty(player, "xiongmang", use.card->toString());

        int n = use.card->subcardsLength() - 1;
        if (n <= 0) return false;
        const Card *c = room->askForUseCard(player, "@@xiongmang", "@xiongmang:" + QString::number(n), -1, Card::MethodNone);

        foreach (ServerPlayer *p, use.to)
            room->setPlayerFlag(p, "-xiongmang_target");
        room->setPlayerProperty(player, "xiongmang", QString());

        if (!c) return false;

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->hasFlag("xiongmang_add_target")) {
                room->setPlayerFlag(p, "-xiongmang_add_target");
                use.to << p;
            }
        }
        room->sortByActionOrder(use.to);
        data = QVariant::fromValue(use);
        return false;
    }
};

class XiongmangDamage : public TriggerSkill
{
public:
    XiongmangDamage() : TriggerSkill("#xiongmang")
    {
        events << DamageDone << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash") || !damage.from) return false;
            room->setCardFlag(damage.card, "xiongmang_damage");
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || use.card->hasFlag("xiongmang_damage")) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isAlive() && use.card->hasFlag("xiongmang_" + p->objectName()) && p->getMaxHp() > 1) {
                    room->sendCompulsoryTriggerLog(p, "xiongmang", true, true);
                    room->loseMaxHp(p);
                }
            }
        }
        return false;
    }
};

JianliangCard::JianliangCard()
{
}

bool JianliangCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.length() < 2;
}

void JianliangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (p->isAlive()) {
            room->cardEffect(this, source, p);
        }
    }
}

void JianliangCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->drawCards(1, "jianliang");
}

class JianliangVS : public ZeroCardViewAsSkill
{
public:
    JianliangVS() :ZeroCardViewAsSkill("jianliang")
    {
        response_pattern = "@@jianliang";
    }

    const Card *viewAs() const
    {
        return new JianliangCard;
    }
};

class Jianliang : public PhaseChangeSkill
{
public:
    Jianliang() : PhaseChangeSkill("jianliang")
    {
        view_as_skill = new JianliangVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
       if (player->getPhase() != Player::Draw) return false;
       Room *room = player->getRoom();
       int hand = player->getHandcardNum();
       foreach (ServerPlayer *p, room->getAlivePlayers()) {
           if (p->getHandcardNum() > hand) {
               room->askForUseCard(player, "@@jianliang", "@jianliang", -1, Card::MethodNone);
               break;
           }
       }
       return false;
    }
};

WeimengCard::WeimengCard()
{
}

bool WeimengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void WeimengCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    int hp = from->getHp();
    if (to->isKongcheng() || hp <= 0) return;

    Room *room = from->getRoom();
    QList<int> gets;

    int ad = Config.AIDelay;
    Config.AIDelay = 0;
    to->setFlags("weimeng_InTempMoving");

    for (int i = 0; i < hp; i++) {
        if (to->isKongcheng()) break;
        int id = room->askForCardChosen(from, to, "h", "weimeng", false, Card::MethodNone, QList<int>(), i != 0);
        if (id < 0) break;
        gets << id;
        to->addToPile("#weimeng", id, false);
    }

    foreach (int id, gets)
        room->moveCardTo(Sanguosha->getCard(id), to, Player::PlaceHand, false);

    to->setFlags("-weimeng_InTempMoving");
    Config.AIDelay = ad;

    DummyCard dummy(gets);
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, from->objectName());
    room->obtainCard(from, &dummy, reason, false);

    if (from->isNude() || from->isDead() || to->isDead()) return;

    int all_get = 0, get = gets.length(), all_give = 0;
    foreach (int id, gets)
        all_get += Sanguosha->getCard(id)->getNumber();

    QString prompt = "@weimeng:" + to->objectName() + ":" + QString::number(get) + ":" + QString::number(all_get);
    const Card *ex = room->askForExchange(from, "weimeng", get, get, true, prompt);
    room->giveCard(from, to, ex, "weimeng");
    foreach (int id, ex->getSubcards())
        all_give += Sanguosha->getCard(id)->getNumber();
    delete ex;

    if (all_give > all_get)
        from->drawCards(1, "weimeng");
    else if (all_give < all_get) {
        if (from->isDead() || to->isDead() || !from->canDiscard(to, "hej")) return;
        int id = room->askForCardChosen(from, to, "hej", "weimeng", false, Card::MethodDiscard);
        room->throwCard(id, to, from);
    }
}

class Weimeng : public ZeroCardViewAsSkill
{
public:
    Weimeng() :ZeroCardViewAsSkill("weimeng")
    {
    }

    const Card *viewAs() const
    {
        return new WeimengCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getHp() > 0 && !player->hasUsed("WeimengCard");
    }
};

class Yusui : public TriggerSkill
{
public:
    Yusui() : TriggerSkill("yusui")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isBlack() || use.from == player || !use.to.contains(player) || player->getMark("yusui-Clear") > 0) return false;

        if (!player->askForSkillInvoke(this, use.from)) return false;
        player->peiyin(this);
        room->loseHp(player);

        if (player->isDead()) return false;

        int handf = use.from->getHandcardNum(), hand = player->getHandcardNum();
        int hpf = use.from->getHp(), hp = player->getHp();
        QStringList choices;
        if (handf > hand)
            choices << "discard=" + use.from->objectName() + "=" + QString::number(hand);
        if (hpf > hp)
            choices << "hp=" + use.from->objectName() + "=" + QString::number(hp);
        if (choices.isEmpty()) return false;

        QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(use.from));
        room->addPlayerMark(player, "yusui-Clear");

        if (choice.startsWith("discard")) {
            int dis = use.from->getHandcardNum() - player->getHandcardNum();
            if (dis > 0)
                room->askForDiscard(use.from, objectName(), dis, dis);
        } else if (choice.startsWith("hp")) {
            int lose = use.from->getHp() - player->getHp();
            if (lose > 0)
                room->loseHp(use.from, lose);
        }
        return false;
    }
};

BoyanCard::BoyanCard()
{
}

void BoyanCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    int draw = qMin(5, to->getMaxHp()) - to->getHandcardNum();
    if (draw > 0)
        to->drawCards(draw, "boyan");
    room->addPlayerMark(to, "boyan-Clear");
}

class Boyan : public ZeroCardViewAsSkill
{
public:
    Boyan() :ZeroCardViewAsSkill("boyan")
    {
    }

    const Card *viewAs() const
    {
        return new BoyanCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("BoyanCard");
    }
};

class BoyanLimit : public CardLimitSkill
{
public:
    BoyanLimit() : CardLimitSkill("#boyan-limit")
    {
        frequency = NotFrequent;
    }

    QString limitList(const Player *target) const
    {
        if (target->getMark("boyan-Clear") > 0)
            return "use";
        return QString();
    }

    QString limitPattern(const Player *target) const
    {
        if (target->getMark("boyan-Clear") > 0)
            return ".|.|.|hand";
        return QString();
    }
};

class Yuanchou : public TriggerSkill
{
public:
    Yuanchou() : TriggerSkill("yuanchou")
    {
        events << CardUsed;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || !use.card->isBlack()) return false;

        QList<ServerPlayer *> players;
        if (player->isAlive() && player->hasSkill(this))
            players << player;
        foreach (ServerPlayer *p, use.to) {
            if (p->hasSkill(this) && p != use.from)
                players << p;
        }
        room->sortByActionOrder(players);
        foreach (ServerPlayer *p, players)
            room->sendCompulsoryTriggerLog(p, this);

        QList<ServerPlayer *> playerss;
        if (players.contains(player)) {
            foreach (ServerPlayer *p, use.to) {
                playerss << p;
                p->addQinggangTag(use.card);
            }
        }
        foreach (ServerPlayer *p, players) {
            if (p == player || playerss.contains(p)) continue;
            p->addQinggangTag(use.card);
        }
        return false;
    }
};

class JueshengVS : public ZeroCardViewAsSkill
{
public:
    JueshengVS() : ZeroCardViewAsSkill("juesheng")
    {
    }

    const Card *viewAs() const
    {
        Duel *duel = new Duel(Card::NoSuit, 0);
        duel->setSkillName("juesheng");
        return duel;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        Duel *duel = new Duel(Card::NoSuit, 0);
        duel->setSkillName("juesheng");
        duel->deleteLater();
        return duel->isAvailable(player) && player->getMark("@jueshengMark") > 0;
    }
};

class Juesheng : public TriggerSkill
{
public:
    Juesheng() : TriggerSkill("juesheng")
    {
        events << PreCardUsed << DamageCaused << CardFinished << EventPhaseChanging;
        frequency = Limited;
        limit_mark = "@jueshengMark";
        view_as_skill = new JueshengVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(event);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Duel") || use.card->getSkillName() != objectName()) return false;

            room->removePlayerMark(player, "@jueshengMark");
            room->doSuperLightbox("fanjiangzhangda", objectName());

            QStringList targets;
            foreach (ServerPlayer *p, use.to)
                targets << p->objectName();
            room->setTag("Juesheng_" + use.card->toString(), targets);
        } else if (event == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            room->removeTag("Juesheng_" + use.card->toString());
        } else if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            if (player->isDead() || player->getMark("juesheng_mark-Keep") <= 0 || !player->hasSkill(this, true)) return false;
            room->detachSkillFromPlayer(player, objectName());
        } else if (event == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Duel") || damage.card->getSkillName() != objectName()) return false;

            QString name = damage.to->objectName();
            QStringList names = room->getTag("Juesheng_" + damage.card->toString()).toStringList();
            if (!names.contains(name)) return false;
            names.removeOne(name);
            room->setTag("Juesheng_" + damage.card->toString(), names);

            int x = damage.to->property("JueshengSlashNum").toInt();

            LogMessage log;
            log.type = "#JueshengDamage";
            log.from = damage.from;
            log.to << damage.to;
            log.arg = objectName();
            log.arg2 = QString::number(x);
            room->sendLog(log);

            if (x > 0) {
                damage.damage = x;
                data = QVariant::fromValue(damage);
            }
            if (!damage.to->hasSkill(objectName(), true)) {
                int flag = damage.to->getMark("juesheng_mark-Keep") <= 0;
                room->setPlayerMark(damage.to, "juesheng_mark-Keep", 1);
                room->acquireSkill(damage.to, objectName(), true, flag);
            }
            if (x <= 0)
                return true;
        }
        return false;
    }
};

class JueshengRecord : public TriggerSkill
{
public:
    JueshengRecord() : TriggerSkill("#juesheng")
    {
        events  << CardFinished;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        int x = player->property("JueshengSlashNum").toInt();
        x++;
        room->setPlayerProperty(player, "JueshengSlashNum", x);
        return false;
    }
};

class Zengou : public TriggerSkill
{
public:
    Zengou() : TriggerSkill("zengou")
    {
        events  << CardUsed << CardResponded << JinkEffect;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *jink = NULL;
        if (event == JinkEffect) {
            jink = data.value<const Card *>();
            if (jink && room->getTag("zengou_" + jink->toString()).toBool()) {
                room->removeTag("zengou_" + jink->toString());
                return true;
            }
        } else {
            if (event == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                jink = use.card;
            } else if (event == CardResponded) {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                jink = res.m_card;
            }
            if (!jink || !jink->isKindOf("Jink")) return false;

            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill(this) || !p->inMyAttackRange(player)) continue;

                QStringList choices;
                foreach (const Card *c, p->getCards("he")) {
                    if (!c->isKindOf("BasicCard") && p->canDiscard(p, c->getEffectiveId())) {
                        choices << "discard=" + player->objectName();
                        break;
                    }
                }
                choices << "lose=" + player->objectName();
                choices << "cancel";

                QString choice = room->askForChoice(p, objectName(), choices.join("+"), data);
                if (choice == "cancel") continue;
                if (choice.startsWith("lose")) {
                    LogMessage log;
                    log.type = "#InvokeSkill";
                    log.from = p;
                    log.arg = objectName();
                    room->sendLog(log);
                    room->notifySkillInvoked(p, objectName());
                    p->peiyin(this);
                    room->loseHp(p);
                } else {
                    if (!room->askForCard(p, "^BasicCard", "@zengou-discard", data, objectName()))
                        continue;
                }

                room->setTag("zengou_" + jink->toString(), true);
                if (p->isAlive() && room->CardInTable(jink))
                    room->obtainCard(p, jink);
            }
        }
        return false;
    }
};

class Zhangji : public PhaseChangeSkill
{
public:
    Zhangji() : PhaseChangeSkill("zhangji")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Finish;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (p->getMark("zhongzuo_damage-Clear") > 0) {
                if (p->askForSkillInvoke(this, "draw:" + player->objectName())) {
                    p->peiyin(this);
                    player->drawCards(2, objectName());
                }
            }
            if (p->isAlive() && player->isAlive() && p->getMark("zhongzuo_damaged-Clear") > 0 && player->canDiscard(player, "he")) {
                if (p->askForSkillInvoke(this, "discard:" + player->objectName())) {
                    p->peiyin(this);
                    room->askForDiscard(player, objectName(), 2, 2, false, true);
                }
            }
        }
        return false;
    }
};

class JinHuaiyuan : public TriggerSkill
{
public:
    JinHuaiyuan() : TriggerSkill("jinhuaiyuan")
    {
        events << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QString InitialHandCard = player->property("InitialHandCards").toString();
        if (InitialHandCard.isEmpty()) return false;
        QList<int> InitialHandCards = StringList2IntList(InitialHandCard.split("+"));
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player || !move.from_places.contains(Player::PlaceHand)) return false;
        for (int i = 0; i < move.card_ids.length(); i++) {
            if (player->isDead()) break;
            if (move.from_places.at(i) != Player::PlaceHand) continue;
            int id = move.card_ids.at(i);
            if (!InitialHandCards.contains(id)) continue;

            ServerPlayer *t = room->askForPlayerChosen(player, room->getAllPlayers(), objectName(), "@jinhuaiyuan-target", false, true);
            player->peiyin(this);

            QStringList choices;
            choices << "maxcards=" + t->objectName() << "attack=" + t->objectName() << "draw=" + t->objectName();
            QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(t));
            if (choice.startsWith("maxcards"))
                room->addPlayerMark(t, "&jinhuaiyuanmaxcards");
            else if (choice.startsWith("attack"))
                room->addPlayerMark(t, "&jinhuaiyuanattack");
            else
                t->drawCards(1, objectName());
        }
        return false;
    }
};

class JinHuaiyuanDeath : public TriggerSkill
{
public:
    JinHuaiyuanDeath() : TriggerSkill("#jinhuaiyuan")
    {
        events << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->hasSkill("jinhuaiyuan");
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player) return false;

        int max = player->getMark("&jinhuaiyuanmaxcards"), attack = player->getMark("&jinhuaiyuanattack");
        if (max <= 0 && attack <= 0) return false;

        QString prompt = QString("@jinhuaiyuan-death:%1::%2").arg(max).arg(attack);
        ServerPlayer *t = room->askForPlayerChosen(player, room->getOtherPlayers(player), "jinhuaiyuan", prompt, true, true);
        if (!t) return false;
        player->peiyin("jinhuaiyuan");

        room->setPlayerMark(player, "&jinhuaiyuanmaxcards", 0);
        room->setPlayerMark(player, "&jinhuaiyuanattack", 0);

        room->addPlayerMark(t, "&jinhuaiyuanmaxcards", max);
        room->addPlayerMark(t, "&jinhuaiyuanattack", max);
        return false;
    }
};

class JinHuaiyuanKeep : public MaxCardsSkill
{
public:
    JinHuaiyuanKeep() : MaxCardsSkill("#jinhuaiyuan-keep")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target) const
    {
        return target->getMark("&jinhuaiyuanmaxcards");
    }
};

class JinHuaiyuanAttack : public AttackRangeSkill
{
public:
    JinHuaiyuanAttack() : AttackRangeSkill("#jinhuaiyuan-attack")
    {
        frequency = NotFrequent;
    }

    int getExtra(const Player *target, bool) const
    {
        return target->getMark("&jinhuaiyuanattack");
    }
};

JinChongxinCard::JinChongxinCard()
{
}

bool JinChongxinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->isKongcheng() && Self != to_select;
}

void JinChongxinCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();

    QList<ServerPlayer *> players;
    players << from << to;
    room->sortByActionOrder(players);

    foreach (ServerPlayer *p, players) {
        if (p->isDead() || p->isNude()) continue;

        QList<const Card *> recasts;
        foreach (const Card *c, p->getCards("he")) {
            if (p->isCardLimited(c, Card::MethodRecast, true)) continue;
            if (p->isCardLimited(c, Card::MethodRecast, false)) continue;
            recasts << c;
        }
        if (recasts.isEmpty()) continue;

        const Card *c = room->askForCard(p, "..", "@jinchongxin-recast", QVariant::fromValue(from), Card::MethodRecast);
        if (!c)
            c = recasts.at(qrand() % recasts.length());

        LogMessage log;
        log.type = "$RecastCard";
        log.from = p;
        log.card_str = c->toString();
        room->sendLog(log);

        room->moveCardTo(c, p, NULL, Player::DiscardPile, CardMoveReason(CardMoveReason::S_REASON_RECAST, p->objectName(), "jinchongxin", ""));
        p->drawCards(1, "recast");
    }
}

class JinChongxin : public ZeroCardViewAsSkill
{
public:
    JinChongxin() : ZeroCardViewAsSkill("jinchongxin")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        bool recast = false;
        foreach (const Card *c, player->getHandcards() + player->getEquips()) {
            if (player->isCardLimited(c, Card::MethodRecast, true)) continue;
            if (player->isCardLimited(c, Card::MethodRecast, false)) continue;
            recast = true;
            break;
        }
        return recast && !player->hasUsed("JinChongxinCard");
    }

    const Card *viewAs() const
    {
        return new JinChongxinCard;
    }
};

class JinDezhang : public PhaseChangeSkill
{
public:
    JinDezhang() : PhaseChangeSkill("jindezhang")
    {
        frequency = Wake;
        waked_skills = "jinweishu";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        QString InitialHandCard = player->property("InitialHandCards").toString();
        if (InitialHandCard.isEmpty()) return true;
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);
        room->doSuperLightbox("jin_yanghu", "jindezhang");
        room->addPlayerMark(player, objectName());
        if (room->changeMaxHpForAwakenSkill(player))
            room->acquireSkill(player, "jinweishu");
        return false;
    }
};

class JinWeishu : public TriggerSkill
{
public:
    JinWeishu() : TriggerSkill("jinweishu")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.reason.m_reason == CardMoveReason::S_REASON_DRAW) {
            if (move.to == player && move.to_place == Player::PlaceHand && move.from_places.contains(Player::DrawPile) &&
                    move.reason.m_skillName != objectName() && player->getPhase() != Player::Draw) {
                ServerPlayer *t = room->askForPlayerChosen(player, room->getAllPlayers(), objectName(), "@jinweishu-draw", false, true);
                player->peiyin(this);
                t->drawCards(1, objectName());
            }
        } else if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip)) &&
                    player->getPhase() != Player::Discard) {
                for (int i = 0; i < move.card_ids.length(); i++) {
                    if (player->isDead()) break;
                    if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                        QList<ServerPlayer *> targets;
                        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                            if (player->canDiscard(p, "he"))
                                targets << p;
                        }
                        if (targets.isEmpty()) break;
                        ServerPlayer *t = room->askForPlayerChosen(player, targets, "jinweishu_dis", "@jinweishu-discard", false, true);
                        player->peiyin(this);
                        int id = room->askForCardChosen(player, t, "he", objectName(), false, Card::MethodDiscard);
                        room->throwCard(id, t, player);
                    }
                }
            }
        }
        return false;
    }
};

class Kuangcai : public PhaseChangeSkill
{
public:
    Kuangcai() : PhaseChangeSkill("kuangcai")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int damage = player->getMark("damage_point_round"), used = player->getMark("tenyearjingce-Clear");
        if (player->getPhase() == Player::Discard) {
            LogMessage log;
            log.type = "#KuangcaiMaxCards";
            log.from = player;
            log.arg = objectName();
            if (used <= 0) {
                log.arg2 = "kuangcaiadd";
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                player->peiyin(this);
                room->addMaxCards(player, 1, false);
            } else {
                if (damage <= 0) {
                    log.arg2 = "kuangcaireduce";
                    room->sendLog(log);
                    room->notifySkillInvoked(player, objectName());
                    player->peiyin(this);
                    room->addMaxCards(player, -1, false);
                }
            }
        } else if (player->getPhase() == Player::Finish) {
            if (damage > 0) {
                room->sendCompulsoryTriggerLog(player, this);
                damage = qMin(5, damage);
                player->drawCards(damage, objectName());
            }
        }
        return false;
    }
};

class KuangcaiTarget : public TargetModSkill
{
public:
    KuangcaiTarget() : TargetModSkill("#kuangcai")
    {
        pattern = "^SkillCard";
    }

    int getDistanceLimit(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("kuangcai"))
            return 1000;
        else
            return 0;
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill("kuangcai"))
            return 1000;
        else
            return 0;
    }
};

class Shejian : public TriggerSkill
{
public:
    Shejian() : TriggerSkill("shejian")
    {
        events  << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || use.from == player || player->getMark("shejian-Clear") > 2 || !use.to.contains(player) ||
           player->hasFlag("Global_Dying") || !player->canDiscard(player, "h") || player->getHandcardNum() < 2) return false;
        const Card *card = room->askForDiscard(player, objectName(), 99999, 2, true, false, "@shejian:" + use.from->objectName(), ".", objectName());
        if (!card) return false;
        room->addPlayerMark(player, "shejian-Clear");

        ServerPlayer *from = use.from;
        int num = card->subcardsLength();
        QStringList choices;
        if (player->canDiscard(from, "he"))
            choices << "discard=" + from->objectName() + "=" + QString::number(num);
        choices << "damage=" + from->objectName();

        QString choice = room->askForChoice(player, objectName(), choices.join("+"), data);
        if (choice.startsWith("damage"))
            room->damage(DamageStruct(objectName(), player, from));
        else {
            int ad = Config.AIDelay;
            Config.AIDelay = 0;

            QList<Player::Place> orig_places;
            QList<int> cards;
            from->setFlags("shejian_InTempMoving");

            for (int i = 0; i < num; ++i) {
                if (!player->canDiscard(from, "he")) break;
                int id = room->askForCardChosen(player, from, "he", objectName(), false, Card::MethodDiscard);
                Player::Place place = room->getCardPlace(id);
                orig_places << place;
                cards << id;
                from->addToPile("#shejian", id, false);
            }

            for (int i = 0; i < orig_places.length(); ++i)
                room->moveCardTo(Sanguosha->getCard(cards.value(i)), from, orig_places.value(i), false);

            from->setFlags("-shejian_InTempMoving");
            Config.AIDelay = ad;

            if (!cards.isEmpty()) {
                DummyCard dummy(cards);
                room->throwCard(&dummy, from, player);
            }
        }
        return false;
    }
};

ChanniCard::ChanniCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void ChanniCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    room->giveCard(from, to, this, "channi");
    if (to->isDead() || (to->isKongcheng() && to->getHandPile().isEmpty())) return;

    int length = subcardsLength();
    room->setPlayerMark(to, "channi_mark-Clear", length);
    room->setPlayerProperty(to, "ChanniSkillFrom", from->objectName());
    room->askForUseCard(to, "@@channi", "@channi:" + QString::number(length));
}

class ChanniVS : public ViewAsSkill
{
public:
    ChanniVS() : ViewAsSkill("channi")
    {
        response_or_use = true;
        response_pattern = "@@channi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->getCurrentCardUsePattern() == "@@channi") {
            if (to_select->isEquipped() || selected.length() >= Self->getMark("channi_mark-Clear")) return false;
            Duel *duel = new Duel(Card::SuitToBeDecided, -1);
            duel->setSkillName("_channi");
            duel->addSubcards(selected);
            duel->addSubcard(to_select);
            return !Self->isLocked(duel);
        }
        return Self->getHandcards().contains(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        if (Sanguosha->getCurrentCardUsePattern() == "@@channi") {
            Duel *duel = new Duel(Card::SuitToBeDecided, -1);
            duel->setSkillName("_channi");
            duel->addSubcards(cards);
            return duel;
        }

        ChanniCard *c = new ChanniCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ChanniCard");
    }
};

class Channi : public TriggerSkill
{
public:
    Channi() : TriggerSkill("channi")
    {
        events  << Damage << Damaged << PreCardUsed;
        view_as_skill = new ChanniVS;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || !use.card->isKindOf("Duel") || use.card->getSkillName() != objectName()) return false;
            QString name = player->property("ChanniSkillFrom").toString();
            if (name.isEmpty()) return false;
            room->setPlayerProperty(player, "ChanniSkillFrom", QString());
            room->setCardFlag(use.card, "channi_use_from_" + player->objectName());
            room->setCardFlag(use.card, "channi_from_" + name);
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Duel") || damage.card->getSkillName() != objectName()) return false;
            if (!damage.card->hasFlag("channi_use_from_" + player->objectName())) return false;

            if (event == Damage) {
                if (player->isDead()) return false;
                int num = damage.card->subcardsLength();
                player->drawCards(num, objectName());
            } else {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isDead() || !damage.card->hasFlag("channi_from_" + p->objectName())) continue;
                    p->throwAllHandCards();
                }
            }
        }
        return false;
    }
};

class Nifu : public TriggerSkill
{
public:
    Nifu() : TriggerSkill("nifu")
    {
        events  << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            int num = p->getHandcardNum() - 3;
            if (num < 0) {
                room->sendCompulsoryTriggerLog(p, this, 2);
                p->drawCards(-num, objectName());
            } else if (num > 0 && p->canDiscard(p, "h")) {
                room->sendCompulsoryTriggerLog(p, this, 1);
                room->askForDiscard(p, objectName(), num, num);
            }
        }
        return false;
    }
};

class Tiqi : public TriggerSkill
{
public:
    Tiqi() : TriggerSkill("tiqi")
    {
        events  << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::Play || player->isSkipped(Player::Play)) return false;
        int mark = player->getMark("tiqi_record-Clear");
        mark = qAbs(2 - mark);
        if (mark == 0) return false;

        QString _mark = QString::number(mark);
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (!p->askForSkillInvoke(this, "tiqi:" + _mark)) continue;
            p->drawCards(mark, objectName());
            if (player->isAlive() && p->isAlive()) {
                QStringList choices;
                choices << "zeng=" + player->objectName() + "=" + _mark << "jian=" + player->objectName() + "=" + _mark << "cancel";
                QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(player));
                if (choice == "cancel") continue;

                LogMessage log;
                log.type = "#TiqiMaxCards" + choice.split("=").first();
                log.from = p;
                log.to << player;
                log.arg = _mark;
                room->sendLog(log);

                int num = mark;
                if (choice.startsWith("jian"))
                    num = -num;
                room->addMaxCards(player, num);
            }
        }
        return false;
    }
};

class TiqiRecord : public TriggerSkill
{
public:
    TiqiRecord() : TriggerSkill("#tiqi")
    {
        events  << EventPhaseStart << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Draw) return false;
            room->setPlayerMark(player, "tiqi_record-Clear", 0);
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to != player || player->getPhase() != Player::Draw) return false;
            if (move.reason.m_reason != CardMoveReason::S_REASON_DRAW) return false;
            int num = 0;
            for (int i = 0; i < move.card_ids.length(); i++) {
                if (move.from_places.at(i) == Player::DrawPile)
                    num++;
            }
            room->addPlayerMark(player, "tiqi_record-Clear", num);
        }
        return false;
    }
};

BaoshuCard::BaoshuCard()
{
}

bool BaoshuCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    return targets.length() < Self->getMaxHp();
}

void BaoshuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    int y = targets.length();
    room->setCardFlag(this, "baoshu_num_y_" + QString::number(y));
    foreach (ServerPlayer *p, targets) {
        if (p->isAlive())
            room->cardEffect(this, source, p);
    }
}

void BaoshuCard::onEffect(const CardEffectStruct &effect) const
{
    int y = 0;
    foreach (QString flag, getFlags()) {
        if (!flag.startsWith("baoshu_num_y_")) continue;
        QStringList flags = flag.split("_");
        if (flags.length() != 4) continue;
        y = flags.last().toInt();
        break;
    }
    y = qMax(y, 1);
    int num = effect.from->getMaxHp() - y + 1;
    num = qMax(1, num);
    effect.to->getRoom()->addPlayerMark(effect.to, "&fybsshu", num);
}

class BaoshuVS : public ZeroCardViewAsSkill
{
public:
    BaoshuVS() : ZeroCardViewAsSkill("baoshu")
    {
        response_pattern = "@@baoshu";
    }

    const Card *viewAs() const
    {
        return new BaoshuCard;
    }
};

class Baoshu : public PhaseChangeSkill
{
public:
    Baoshu() : PhaseChangeSkill("baoshu")
    {
        view_as_skill = new BaoshuVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        if (player->getMaxHp() <= 0) return false;
        player->getRoom()->askForUseCard(player, "@@baoshu", "@baoshu", -1, Card::MethodNone);
        return false;
    }
};

class BaoshuDraw : public TriggerSkill
{
public:
    BaoshuDraw() : TriggerSkill("#baoshu")
    {
        events  << DrawNCards << AfterDrawNCards;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&fybsshu") > 0;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DrawNCards) {
            LogMessage log;
            log.type = "#ZhenguEffect";
            log.from = player;
            log.arg = "baoshu";
            room->sendLog(log);
            int n = data.toInt(), mark = player->getMark("&fybsshu");
            data = QVariant::fromValue(n + mark);
        } else {
            player->loseAllMarks("&fybsshu");
        }
        return false;
    }
};

class Tianyun : public PhaseChangeSkill
{
public:
    Tianyun() : PhaseChangeSkill("tianyun")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::RoundStart;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int seat = player->getPlayerSeat(), turn = room->getTag("TurnLengthCount").toInt();
        if (seat != turn) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;

            QList<int> suits;
            foreach (const Card *c, p->getCards("h")) {
                int suit = (int)c->getSuit();
                if (suits.contains(suit)) continue;
                suits << suit;
            }
            int num = qMax(suits.length(), 1);

            if (!p->askForSkillInvoke(this, "tianyun:" + QString::number(num))) continue;
            p->peiyin(this);

            QList<int> ids = room->getNCards(num, false);
            QList<int> puts = room->askForGuanxing(p, ids);
            if (!puts.isEmpty() || p->isDead()) continue;

            ServerPlayer *t = room->askForPlayerChosen(p, room->getAlivePlayers(), objectName(), "@tianyun-draw:" + QString::number(num), true);
            if (!t) continue;
            room->doAnimate(1, p->objectName(), t->objectName());
            t->drawCards(num, objectName());
            room->loseHp(p);
        }
        return false;
    }
};

class TianyunInitial : public TriggerSkill
{
public:
    TianyunInitial() : TriggerSkill("#tianyun")
    {
        events  << AfterDrawInitialCards;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        QList<int> suits;
        foreach (const Card *c, player->getCards("h")) {
            int suit = (int)c->getSuit();
            suits << suit;
        }
        QList<const Card *> cards;
        foreach (int id, room->getDrawPile()) {
            const Card *c = Sanguosha->getCard(id);
            int suit = (int)c->getSuit();
            if (suits.contains(suit)) continue;
            cards << c;
        }
        if (cards.isEmpty()) return false;

        DummyCard *dummy = new DummyCard();
        dummy->deleteLater();

        while (!cards.isEmpty()) {
            const Card *card = cards.at(qrand() % cards.length());
            dummy->addSubcard(card);
            foreach (const Card *c, cards) {
                if (c->getSuit() == card->getSuit())
                    cards.removeOne(c);
            }
        }
        if (dummy->subcardsLength() > 0) {
            room->sendCompulsoryTriggerLog(player, "tianyun", true, true);
            room->obtainCard(player, dummy, false);
        }
        return false;
    }
};

class Yuyan : public TriggerSkill
{
public:
    Yuyan() : TriggerSkill("yuyan")
    {
        events  << RoundStart << EventPhaseChanging;
        waked_skills = "tenyearfenyin";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == RoundStart) {
            if (player->isDead() || !player->hasSkill(this)) return false;

            ServerPlayer *t = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@yuyan-target", false);

            LogMessage log;
            log.type = "#ChoosePlayerWithSkill";
            log.from = player;
            log.to << t;
            log.arg = objectName();
            room->sendLog(log, player);

            log.type = "#InvokeSkill";
            room->sendLog(log, room->getOtherPlayers(player, true));

            room->doAnimate(1, player->objectName(), t->objectName(), QList<ServerPlayer *>() << player);

            room->notifySkillInvoked(player, objectName());
            player->peiyin(this);

            room->setPlayerMark(t, "&yuyan+#" + player->objectName() + "_lun", 1, QList<ServerPlayer *>() << player);
            room->setPlayerMark(t, "yuyan_hide_" + player->objectName() + "_lun", 1);
        } else {
            //if (player->isDead()) return false;
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            bool fenyin = player->tag["YuyanFenyin"].toBool();
            if (!fenyin) return false;
            player->tag.remove("YuyanFenyin");
            room->handleAcquireDetachSkills(player, "-tenyearfenyin");
        }
        return false;
    }
};

class YuyanDying : public TriggerSkill
{
public:
    YuyanDying() : TriggerSkill("#yuyan-dying")
    {
        events  << EnterDying << RoundStart;
        global = true;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EnterDying)
            return -1;
        else
            return 5;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *, QVariant &) const
    {
        if (event == EnterDying) {
            int d = room->getTag("YuyanFirstDying").toInt();
            room->setTag("YuyanFirstDying", d + 1);
        } else
            room->removeTag("YuyanFirstDying");
        return false;
    }
};

class YuyanEffect : public TriggerSkill
{
public:
    YuyanEffect() : TriggerSkill("#yuyan")
    {
        events  << Dying << Damage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == Damage) {
            if (room->getTag("XianshuaiFirstDamage").toInt() > 1) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->getMark("&yuyan+#" + p->objectName() + "_lun") <= 0) continue;
                if (player->getMark("yuyan_hide_" + p->objectName() + "_lun") > 0) {
                    room->setPlayerMark(player, "yuyan_hide_" + p->objectName(), 0);
                    room->setPlayerMark(player, "&yuyan+#" + p->objectName() + "_lun", 0);
                    room->setPlayerMark(player, "&yuyan+#" + p->objectName() + "_lun", 1);
                }
                if (p->isAlive()) {
                    room->sendCompulsoryTriggerLog(p, "yuyan", true, true);
                    p->drawCards(2, "yuyan");
                }
            }
        } else {
            if (room->getTag("YuyanFirstDying").toInt() > 1) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->getMark("&yuyan+#" + p->objectName() + "_lun") <= 0) continue;
                if (player->getMark("yuyan_hide_" + p->objectName() + "_lun") > 0) {
                    room->setPlayerMark(player, "yuyan_hide_" + p->objectName(), 0);
                    room->setPlayerMark(player, "&yuyan+#" + p->objectName() + "_lun", 0);
                    room->setPlayerMark(player, "&yuyan+#" + p->objectName() + "_lun", 1);
                }
                if (p->isAlive()) {
                    room->sendCompulsoryTriggerLog(p, "yuyan", true, true);
                    if (!p->hasSkill("tenyearfenyin", true)) {
                        p->tag["YuyanFenyin"] = true;
                        room->handleAcquireDetachSkills(p, "tenyearfenyin");
                    }
                }
            }
        }
        return false;
    }
};

class Bingjie : public PhaseChangeSkill
{
public:
    Bingjie() : PhaseChangeSkill("bingjie")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (!player->askForSkillInvoke(this)) return false;
        player->peiyin(this);
        Room *room = player->getRoom();
        room->loseMaxHp(player);
        if (player->isAlive())
            room->addPlayerMark(player, "&bingjie-Clear");
        return false;
    }
};

class BingjieEffect : public TriggerSkill
{
public:
    BingjieEffect() : TriggerSkill("#bingjie")
    {
        events  << TargetSpecified;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&bingjie-Clear") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") && !use.card->isNDTrick()) return false;
        int mark = player->getMark("&bingjie-Clear");
        foreach (ServerPlayer *p, use.to) {
            if (p == player) continue;
            for (int i = 0; i < mark; i++) {
                if (p->isDead() || !p->canDiscard(p, "he")) continue;

                LogMessage log;
                log.type = "#ZhenguEffect";
                log.from = player;
                log.arg = "bingjie";
                room->sendLog(log);
                room->notifySkillInvoked(player, "bingjie");
                player->peiyin("bingjie");

                room->askForDiscard(p, "bingjie", 1, 1, false, true);
            }
        }
        return false;
    }
};

class Zhengding : public TriggerSkill
{
public:
    Zhengding() : TriggerSkill("zhengding")
    {
        events  << CardUsed << CardResponded;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive) return false;

        const Card *my_card = NULL, *card = NULL;
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            my_card = use.card;
            card = use.whocard;
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            my_card = res.m_card;
            card = res.m_toCard;
        }

        if (!card || !my_card || card->isKindOf("SkillCard") || my_card->isKindOf("SkillCard") || !card->sameColorWith(my_card)) return false;

        ServerPlayer *from = room->getCardUser(card);
        if (!from || from == player) return false;

        room->sendCompulsoryTriggerLog(player, this);
        room->gainMaxHp(player);
        return false;
    }
};

YijiaoCard::YijiaoCard()
{
}

void YijiaoCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    QString choice = room->askForChoice(from, "yijiao", "1+2+3+4", QVariant::fromValue(to));
    int mark = 10 * choice.toInt();
    to->gainMark("&lcwyjyi", mark);
}

class YijiaoVS : public ZeroCardViewAsSkill
{
public:
    YijiaoVS() : ZeroCardViewAsSkill("yijiao")
    {
    }

    const Card *viewAs() const
    {
        return new YijiaoCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YijiaoCard");
    }
};

class Yijiao : public TriggerSkill
{
public:
    Yijiao() : TriggerSkill("yijiao")
    {
        events  << PreCardUsed << PreCardResponded << EventPhaseChanging << EventPhaseStart;
        view_as_skill = new YijiaoVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            player->loseAllMarks("&lcwyjyi");
        } else if (event == EventPhaseStart) {
            if (player->getPhase() == Player::Finish) {
                int yi = player->getMark("&lcwyjyi"), num = player->getMark("&yijiao_num-Clear"),
                        licaiwei = room->findPlayersBySkillName(objectName()).length();
                if (yi <=0) return false;
                if (num > yi) {
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (p->isDead() || !p->hasSkill(this)) continue;
                        room->sendCompulsoryTriggerLog(p, this);
                        p->drawCards(2, objectName());
                    }
                } else if (num < yi) {
                    if (player->isDead()) return false;
                    LogMessage log;
                    log.from = player;
                    log.type = "#ZhenguEffect";
                    log.arg = objectName();
                    room->sendLog(log);
                    for (int i = 0; i < licaiwei; i++) {
                        if (player->isDead() || !player->canDiscard(player, "h")) break;
                        QList<int> ids;
                        foreach (int id, player->handCards()) {
                            if (player->canDiscard(player, id))
                                ids << id;
                        }
                        if (ids.isEmpty()) break;
                        int id = ids.at(qrand() % ids.length());
                        room->throwCard(id, player);
                    }
                } else
                    room->addPlayerMark(player, "yijiao_extra_turn", licaiwei);
            } else if (player->getPhase() == Player::NotActive) {
                if (player->getMark("yijiao_extra_turn") <= 0) return false;
                LogMessage log;
                log.from = player;
                log.type = "#ZhenguEffect";
                log.arg = objectName();
                room->sendLog(log);
                room->removePlayerMark(player, "yijiao_extra_turn");
                if (player->isAlive())
                    player->gainAnExtraTurn();
            }
        } else {
            if (!room->hasCurrent() || player->isDead() || player->getMark("&lcwyjyi") <= 0) return false;
            const Card *card = NULL;
            if (event == PreCardUsed)
                card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                card = res.m_card;
            }
            if (!card || card->isKindOf("SkillCard")) return false;
            int number = card->getNumber();
            if (number == 0) return false;
            room->addPlayerMark(player, "&yijiao_num-Clear", number);
        }
        return false;
    }
};

class Qibie : public TriggerSkill
{
public:
    Qibie() : TriggerSkill("qibie")
    {
        events << Death;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who == player || !player->canDiscard(player, "h")) return false;
        if (!player->askForSkillInvoke(this)) return false;
        player->peiyin(this);

        QList<int> hands = player->handCards();
        DummyCard *dummy = new DummyCard();
        dummy->deleteLater();

        foreach(int id, hands) {
            if (player->canDiscard(player, id))
                dummy->addSubcard(id);
        }

        int length = dummy->subcardsLength();
        if (length > 0) {
            CardMoveReason reason(CardMoveReason::S_REASON_THROW, player->objectName(), objectName(), QString());
            room->throwCard(dummy, reason, player);
            if (player->isDead()) return false;
            room->recover(player, RecoverStruct());
            player->drawCards(++length, objectName());
        }
        return false;
    }
};

XunliPutCard::XunliPutCard()
{
    mute = true;
    m_skillName = "xunli";
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void XunliPutCard::onUse(Room *, const CardUseStruct &) const
{
}

XunliCard::XunliCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void XunliCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> pile = source->getPile("jpxlli");
    QList<int> to_handcard;
    QList<int> to_pile;
    foreach (int id, subcards) {
        if (pile.contains(id))
            to_handcard << id;
        else
            to_pile << id;
    }

    Q_ASSERT(to_handcard.length() == to_pile.length());

    if (to_pile.length() == 0 || to_handcard.length() != to_pile.length()) return;

    source->addToPile("jpxlli", to_pile);

    DummyCard to_handcard_x(to_handcard);
    CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, source->objectName());
    room->obtainCard(source, &to_handcard_x, reason);
}

class XunliVS : public ViewAsSkill
{
public:
    XunliVS() : ViewAsSkill("xunli")
    {
        expand_pile = "jpxlli,#xunli";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern == "@@xunli2!") {
            int put = 9 - Self->getPile("jpxlli").length();
            return Self->getPile("#xunli").contains(to_select->getEffectiveId()) && selected.length() < put;
        } else if (pattern == "@@xunli1") {
            if (to_select->isEquipped()) return false;
            if (selected.length() >= 2 * Self->getPile("jpxlli").length()) return false;
            if (Self->getHandcards().contains(to_select) && to_select->isBlack()) return true;
            if (Self->getPile("jpxlli").contains(to_select->getEffectiveId())) return true;
            return false;
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        QString pattern = Sanguosha->getCurrentCardUsePattern();
        if (pattern == "@@xunli2!") {
            XunliPutCard *c = new XunliPutCard;
            c->addSubcards(cards);
            return c;
        } else if (pattern == "@@xunli1") {
            int hand = 0;
            int pile = 0;
            foreach (const Card *card, cards) {
                if (Self->getHandcards().contains(card))
                    hand++;
                else if (Self->getPile("jpxlli").contains(card->getEffectiveId()))
                    pile++;
            }

            if (hand == pile) {
                XunliCard *c = new XunliCard;
                c->addSubcards(cards);
                return c;
            }
        }
        return NULL;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@xunli");
    }
};

class Xunli : public TriggerSkill
{
public:
    Xunli() : TriggerSkill("xunli")
    {
        events << CardsMoveOneTime << EventPhaseStart;
        view_as_skill = new XunliVS;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            int put = 9 - player->getPile("jpxlli").length();
            if (put <= 0) return false;

            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                QList<int> blacks;
                foreach (int id, move.card_ids) {
                    if (room->getCardPlace(id) != Player::DiscardPile) continue;
                    if (!Sanguosha->getCard(id)->isBlack()) continue;
                    blacks << id;
                }
                if (blacks.isEmpty()) return false;
                room->sendCompulsoryTriggerLog(player, this);

                if (blacks.length() <= put)
                    player->addToPile("jpxlli", blacks);
                else {
                    room->notifyMoveToPile(player, blacks, objectName(), Player::DiscardPile, true);
                    const Card *card = room->askForUseCard(player, "@@xunli2!", "@xunli2:" + QString::number(put), 2, Card::MethodNone);
                    room->notifyMoveToPile(player, blacks, objectName(), Player::DiscardPile, false);
                    if (card)
                       player->addToPile("jpxlli", card);
                    else {
                        QList<int> puts;
                        for (int i = 0; i < put; i++) {
                            if (blacks.isEmpty()) break;
                            int id = blacks.at(qrand() % blacks.length());
                            blacks.removeOne(id);
                            puts << id;
                        }
                        if (!puts.isEmpty())
                            player->addToPile("jpxlli", puts);
                    }
                }
            }
        } else {
            if (player->getPhase() != Player::Play || player->getPile("jpxlli").isEmpty() || player->isKongcheng()) return false;
            room->askForUseCard(player, "@@xunli1", "@xunli1", 1, Card::MethodNone);
        }
        return false;
    }
};

ZhishiCard::ZhishiCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void ZhishiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, source->objectName(), "zhishi", QString());
    room->throwCard(this, reason, NULL);
}

class ZhishiVS : public ViewAsSkill
{
public:
    ZhishiVS() : ViewAsSkill("zhishi")
    {
        expand_pile = "jpxlli";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return Self->getPile("jpxlli").contains(to_select->getEffectiveId());
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        ZhishiCard *c = new ZhishiCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@zhishi";
    }
};

class Zhishi : public TriggerSkill
{
public:
    Zhishi() : TriggerSkill("zhishi")
    {
        events << TargetConfirmed << Dying;
        view_as_skill = new ZhishiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && !target->getPile("jpxlli").isEmpty();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QString mark = "&zhishi+#" + player->objectName();

        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash")) return false;
            foreach (ServerPlayer *to, use.to) {
                if (player->isDead() || player->getPile("jpxlli").isEmpty()) break;
                if (to->isDead() || to->getMark(mark) <= 0) continue;
                player->tag["ZhishiTarget"] = QVariant::fromValue(to);
                const Card *card = room->askForUseCard(player, "@@zhishi", "@zhishi:" + to->objectName(), -1, Card::MethodNone);
                player->tag.remove("ZhishiTarget");
                if (!card) continue;
                to->drawCards(card->subcardsLength(), objectName());
            }
        } else {
            DyingStruct dying = data.value<DyingStruct>();
            ServerPlayer *dy = dying.who;
            if (!dy || dy->isDead() || dy->getMark(mark) <= 0) return false;
            player->tag["ZhishiTarget"] = QVariant::fromValue(dy);
            const Card *card = room->askForUseCard(player, "@@zhishi", "@zhishi:" + dy->objectName(), -1, Card::MethodNone);
            player->tag.remove("ZhishiTarget");
            if (!card) return false;
            dy->drawCards(card->subcardsLength(), objectName());
        }
        return false;
    }
};

class ZhishiChoose : public PhaseChangeSkill
{
public:
    ZhishiChoose() : PhaseChangeSkill("#zhishi")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (!player->hasSkill("zhishi") || player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        ServerPlayer *t = room->askForPlayerChosen(player, room->getAlivePlayers(), "zhishi", "@zhishi-invoke", true, true);
        if (!t) return false;
        player->peiyin("zhishi");
        room->setPlayerMark(t, "&zhishi+#" + player->objectName(), 1);
        return false;
    }
};

class ZhishiMark : public PhaseChangeSkill
{
public:
    ZhishiMark() : PhaseChangeSkill("#zhishi-mark")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers())
            room->setPlayerMark(p, "&zhishi+#" + player->objectName(), 0);
        return false;
    }
};

LieyiCard::LieyiCard()
{
}

void LieyiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    QList<int> lis = from->getPile("jpxlli");

    try {
        while (!lis.isEmpty()) {
            if (from->isDead() || to->isDead()) break;

            QList<int> uses;
            foreach (int id, lis) {
                const Card *c = Sanguosha->getCard(id);
                if (c->targetFixed()) continue;
                room->setCardFlag(c, "lieyi_use_card");
                if ((!c->isKindOf("Slash") && from->canUse(c, to, true)) || (c->isKindOf("Slash") && from->canSlash(to, c)))
                    uses << id;
                room->setCardFlag(c, "-lieyi_use_card");
            }
            if (uses.isEmpty()) break;

            room->fillAG(uses, from);
            int id = room->askForAG(from, uses, false, "lieyi", "@lieyi-use:" + to->objectName());
            room->clearAG(from);
            lis.removeOne(id);

            room->setCardFlag(id, "lieyi_use_card");
            room->setCardFlag(id, "Global_SlashAvailabilityChecker");
            room->useCard(CardUseStruct(Sanguosha->getCard(id), from, to));
        }

        if (!lis.isEmpty()) {
            DummyCard dis(lis);
            CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, from->objectName(), "lieyi", QString());
            room->throwCard(&dis, reason, NULL);
        }

        if (to->hasFlag("lieyi_dying")) {
            room->setPlayerFlag(to, "-lieyi_dying");
            return;
        }
        room->loseHp(from);
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken || triggerEvent == StageChange)
            room->setPlayerFlag(to, "-lieyi_dying");
        throw triggerEvent;
    }
}

class LieyiVS : public ZeroCardViewAsSkill
{
public:
    LieyiVS() : ZeroCardViewAsSkill("lieyi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("LieyiCard") && !player->getPile("jpxlli").isEmpty();
    }

    const Card *viewAs() const
    {
        return new LieyiCard;
    }
};

class Lieyi : public TriggerSkill
{
public:
    Lieyi() : TriggerSkill("lieyi")
    {
        events << Dying;
        view_as_skill = new LieyiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        ServerPlayer *dy = dying.who;
        if (!dy || dy->isDead() || !dying.damage || !dying.damage->card) return false;
        if (!dying.damage->card->hasFlag("lieyi_use_card")) return false;
        room->setPlayerFlag(dy, "lieyi_dying");
        return false;
    }
};

class LieyiTarget : public TargetModSkill
{
public:
    LieyiTarget() : TargetModSkill("#lieyi")
    {
        frequency = NotFrequent;
    }

    int getResidueNum(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("lieyi_use_card"))
            return 1000;
        else
            return 0;
    }

    int getDistanceLimit(const Player *, const Card *card, const Player *) const
    {
        if (card->hasFlag("lieyi_use_card"))
            return 1000;
        else
            return 0;
    }
};

ManwangCard::ManwangCard()
{
    target_fixed = true;
}

void ManwangCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int n = subcardsLength();
    if (n >= 1 && source->getMark("manwang_remove_last") < 4)
        room->acquireSkill(source, "panqin");
    if (n >= 2 && source->getMark("manwang_remove_last") < 3)
        source->drawCards(1, "manwang");
    if (n >= 3 && source->getMark("manwang_remove_last") < 2)
        room->recover(source, RecoverStruct(source));
    if (n >= 4 && source->getMark("manwang_remove_last") < 1) {
        source->drawCards(2, "manwang");
        room->detachSkillFromPlayer(source, "panqin");
    }
}

class Manwang : public ViewAsSkill
{
public:
    Manwang() : ViewAsSkill("manwang")
    {
        waked_skills = "panqin";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        ManwangCard *c = new ManwangCard;
        c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he");
    }
};

class Panqin : public TriggerSkill
{
public:
    Panqin() : TriggerSkill("panqin")
    {
        events << EventPhaseEnd << CardUsed;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play && player->getPhase() != Player::Discard) return false;

            QVariantList dis = player->tag["PanqinRecord"].toList();
            QList<int> subcards;
            foreach (QVariant card_data, dis) {
                int card_id = card_data.toInt();
                if (room->getCardPlace(card_id) == Player::DiscardPile)
                    subcards << card_id;
            }
            if (subcards.isEmpty()) return false;

            SavageAssault *sa = new SavageAssault(Card::SuitToBeDecided, -1);
            sa->deleteLater();
            sa->setSkillName("panqin");
            sa->addSubcards(subcards);
            if (!player->canUse(sa)) return false;

            room->fillAG(subcards, player);
            bool invoke = player->askForSkillInvoke(this, "panqin", false);
            room->clearAG(player);
            if (!invoke) return false;

            room->useCard(CardUseStruct(sa, player, player), true);
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("SavageAssault") || use.card->getSkillName() != objectName()) return false;
            int mark = player->getMark("manwang_remove_last"), length = use.to.length(), sub = use.card->subcardsLength();

            if (length >= sub && mark < 4) {
                room->sendCompulsoryTriggerLog(player, this);

                mark = qMax(0, mark);
                mark++;
                if (mark == 1) {
                    player->drawCards(2, "manwang");
                    room->detachSkillFromPlayer(player, "panqin");
                } else if (mark == 2)
                    room->recover(player, RecoverStruct(player));
                else if (mark == 3)
                    player->drawCards(1, "manwang");
                else if (mark >= 4)
                    room->acquireSkill(player, "panqin");

                if (mark > 4) return false;
                room->setPlayerMark(player, "manwang_remove_last", mark);
                room->changeTranslation(player, "manwang", 5 - mark);
            }
        }
        return false;
    }
};

class PanqinRecord : public TriggerSkill
{
public:
    PanqinRecord() : TriggerSkill("#panqin")
    {
        events << CardsMoveOneTime << EventPhaseChanging;
        global = true;
    }

    bool trigger(TriggerEvent event, Room *, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.from) return false;
            if (move.from->getPhase() != Player::Play && move.from->getPhase() != Player::Discard) return false;
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                ServerPlayer *from = (ServerPlayer *)move.from;
                QVariantList dis = from->tag["PanqinRecord"].toList();
                int i = 0;
                foreach (int card_id, move.card_ids) {
                    if (!dis.contains(QVariant(card_id))) {
                        if (move.from_places[i] == Player::PlaceHand || move.from_places[i] == Player::PlaceEquip)
                            dis << card_id;
                    }
                    i++;
                }
                from->tag["PanqinRecord"] = dis;
            }
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from != Player::Play && change.from != Player::Discard) return false;
            player->tag.remove("PanqinRecord");
        }
        return false;
    }
};

class Jinjian : public TriggerSkill
{
public:
    Jinjian() : TriggerSkill("jinjian")
    {
        events << DamageCaused << DamageInflicted;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (player->getMark("&jinjianadd-Clear") > 0 || player->getMark("&jinjianreduce-Clear") > 0) {
            if (!damage.tips.contains("jinjian_invoke"))  //处理对自己造成伤害的问题，可以先+1再-1
                return false;
        }

        int change = 1;
        QString mark = "&jinjianreduce-Clear";
        bool invoke = true;
        player->tag["JinjianDamage"] = data;

        if (event == DamageCaused)
            invoke = player->askForSkillInvoke(this, "add");
        else {
            invoke = player->askForSkillInvoke(this, "reduce");
            change = -1;
            mark = "&jinjianadd-Clear";
        }

        player->tag.remove("JinjianDamage");

        if (!invoke) return false;
        player->peiyin(this);

        damage.tips << "jinjian_invoke";
        damage.damage += change;
        data = QVariant::fromValue(damage);

        if (room->hasCurrent())
            room->addPlayerMark(player, mark);

        if (damage.damage <= 0)
            return true;
        return false;
    }
};

class JinjianEffect : public TriggerSkill
{
public:
    JinjianEffect() : TriggerSkill("#jinjian")
    {
        events << DamageCaused << DamageInflicted;
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!room->hasCurrent()) return false;

        DamageStruct damage = data.value<DamageStruct>();
        int d = damage.damage;
        if (damage.tips.contains("jinjian_invoke")) {
            //damage.tips.removeOne("jinjian_invoke");
            //data = QVariant::fromValue(damage);
            return false;
        }

        if (event == DamageInflicted) {
            int mark = player->getMark("&jinjianadd-Clear");
            if (mark <= 0) return false;
            room->setPlayerMark(player, "&jinjianadd-Clear", 0);

            damage.damage += mark;
            data = QVariant::fromValue(damage);

            LogMessage log;
            log.type = "#JinjianDamage";
            log.from = player;
            log.arg = "jinjian";
            log.arg2 = QString::number(d);
            log.arg3 = QString::number(damage.damage);
            room->sendLog(log);
            room->notifySkillInvoked(player, "jinjian");
            player->peiyin("jinjian");
        } else {
            int mark = player->getMark("&jinjianreduce-Clear");
            if (mark <= 0) return false;
            room->setPlayerMark(player, "&jinjianreduce-Clear", 0);

            damage.damage -= mark;
            data = QVariant::fromValue(damage);

            room->notifySkillInvoked(player, "jinjian");
            player->peiyin("jinjian");

            LogMessage log;
            log.type = "#JinjianDamage";
            log.from = player;
            log.arg = "jinjian";
            log.arg2 = QString::number(d);

            if (damage.damage <= 0) {
                log.type = "#JinjianPreventDamage";
                room->sendLog(log);
                return true;
            }

            log.arg3 = QString::number(damage.damage);
            room->sendLog(log);
        }
        return false;
    }
};

class Renzheng : public TriggerSkill
{
public:
    Renzheng() : TriggerSkill("renzheng")
    {
        events << DamageComplete;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();

        int start_damage = 0;
        foreach (QString tip, damage.tips) {
            if (!tip.startsWith("STARTDAMAGE:")) continue;
            QStringList tips = tip.split(":");
            if (tips.length() != 2) continue;
            start_damage = tips.last().toInt();
            if (start_damage >= 0)
                break;
        }

        if (damage.prevented || damage.damage <= 0 || damage.damage < start_damage) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead() || !p->hasSkill(this)) continue;
                room->sendCompulsoryTriggerLog(p, this);
                p->drawCards(2, objectName());
            }
        }
        return false;
    }
};

DunshiCard::DunshiCard()
{
    mute = true;
}

bool DunshiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        if (card && card->targetFixed())  //因源码bug，不得已而为之
            return targets.isEmpty() && to_select == Self && !Self->isProhibited(to_select, card, targets);
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    const Card *card = Self->tag.value("dunshi").value<const Card *>();
    if (card && card->targetFixed())  //因源码bug，不得已而为之
        return targets.isEmpty() && to_select == Self && !Self->isProhibited(to_select, card, targets);
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

/*bool DunshiCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFixed();
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *card = Self->tag.value("dunshi").value<const Card *>();
    return card && card->targetFixed();
}*/

bool DunshiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return true;
    }

    const Card *card = Self->tag.value("dunshi").value<const Card *>();
    return card && card->targetsFeasible(targets, Self);
}

const Card *DunshiCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;
    Room *room = player->getRoom();

    room->addPlayerMark(player, "dunshi_used-Clear");

    QString to_dunshi = user_string;
    if ((user_string.contains("slash") || user_string.contains("Slash")) && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        if (player->getMark("dunshi_used_slash") > 0) return NULL;
        to_dunshi = "slash";
    }

    Card *use_card = Sanguosha->cloneCard(to_dunshi);
    use_card->setSkillName("dunshi");
    use_card->deleteLater();

    QStringList cards;
    cards << "slash" << "jink" << "peach" << "analeptic";
    room->setPlayerMark(player, "dunshi_card-Clear", cards.indexOf(to_dunshi) + 1);

    return use_card;
}

const Card *DunshiCard::validateInResponse(ServerPlayer *player) const
{
    Room *room = player->getRoom();

    room->addPlayerMark(player, "dunshi_used-Clear");

    QString to_dunshi;
    if (user_string == "peach+analeptic") {
        QStringList guhuo_list;
        if (player->getMark("dunshi_used_peach") <= 0)
            guhuo_list << "peach";
        if (Sanguosha->hasCard("analeptic") && player->getMark("dunshi_used_analeptic") <= 0)
            guhuo_list << "analeptic";
        if (guhuo_list.isEmpty()) return NULL;
        to_dunshi = room->askForChoice(player, "dunshi_saveself", guhuo_list.join("+"));
    } else if (user_string.contains("slash") || user_string.contains("Slash")) {
        if (player->getMark("dunshi_used_slash") > 0) return NULL;
        to_dunshi = "slash";
    } else {
        if (player->getMark("dunshi_used_" + user_string) > 0) return NULL;
        to_dunshi = user_string;
    }

    Card *use_card = Sanguosha->cloneCard(to_dunshi);
    use_card->setSkillName("dunshi");
    use_card->deleteLater();

    QStringList cards;
    cards << "slash" << "jink" << "peach" << "analeptic";
    room->setPlayerMark(player, "dunshi_card-Clear", cards.indexOf(to_dunshi) + 1);

    return use_card;
}

class DunshiVS : public ZeroCardViewAsSkill
{
public:
    DunshiVS() : ZeroCardViewAsSkill("dunshi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("dunshi_used-Clear") > 0) return false;
        return player->getMark("dunshi_used_slash") <= 0 || player->getMark("dunshi_used_peach") <= 0 ||
                player->getMark("dunshi_used_analeptic") <= 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (pattern.contains("slash") || pattern.contains("Slash") || pattern.contains("Jink") || pattern.contains("jink") ||
                pattern.contains("peach") || pattern.contains("analeptic")) {
            if (player->getMark("dunshi_used-Clear") > 0) return false;
            if (pattern.startsWith(".") || pattern.startsWith("@")) return false;
            if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;
            for (int i = 0; i < pattern.length(); i++) {
                QChar ch = pattern[i];
                if (ch.isUpper() || ch.isDigit()) return false; // This is an extremely dirty hack!! For we need to prevent patterns like 'BasicCard'
            }

            bool ok = false;
            foreach (QString pa, pattern.split("+")) {
                if (!pa.contains("slash") && !pa.contains("Slash") && !pa.contains("Jink") && !pa.contains("jink") &&
                        !pa.contains("peach") && !pa.contains("analeptic")) continue;
                QString name = pa;
                if (pa.contains("slash") || pa.contains("Slash"))
                    name = "slash";
                else if (pa.contains("jink") || pa.contains("Jink"))
                    name = "jink";

                if (player->getMark("dunshi_used_" + pa) <= 0) {
                    ok = true;
                    break;
                }
            }

            return ok;
        }
        return false;
    }

    const Card *viewAs() const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE
            || Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
            DunshiCard *card = new DunshiCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            return card;
        }

        const Card *c = Self->tag.value("dunshi").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            DunshiCard *card = new DunshiCard;
            card->setUserString(c->objectName());
            return card;
        }
        return NULL;
    }
};

class Dunshi : public TriggerSkill
{
public:
    Dunshi() : TriggerSkill("dunshi")
    {
        events << DamageCaused;
        view_as_skill = new DunshiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("dunshi", true, false);
    }

    QStringList getSkills(ServerPlayer *player) const
    {
        QStringList skills, choices;

        QStringList general_names = Sanguosha->getLimitedGeneralNames();
        foreach (QString name, general_names) {
            const General *general = Sanguosha->getGeneral(name);
            if (!general) continue;
            QList<const Skill *> sks = general->getVisibleSkillList();
            foreach (const Skill *sk, sks) {
                if (skills.contains(sk->objectName())) continue;
                QString sk_name = Sanguosha->translate(sk->objectName());
                if (!sk_name.contains("仁") && !sk_name.contains("义") && !sk_name.contains("礼") && !sk_name.contains("智") &&
                        !sk_name.contains("信")) continue;
                if (player->hasSkill(sk, true)) continue;
                skills << sk->objectName();
            }
        }

        for (int i = 0; i < 3; i++) {
            if (skills.isEmpty()) break;
            QString choice = skills.at(qrand() % skills.length());
            skills.removeOne(choice);
            choices << choice;
        }

        return choices;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *current = room->getCurrent();
        if (!current || player != current) return false;

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead()) continue;
            int mark = p->getMark("dunshi_card-Clear");
            if (mark <= 0) continue;

            room->setPlayerMark(p, "dunshi_card-Clear", 0);
            room->sendCompulsoryTriggerLog(p, this);

            QStringList cards;
            cards << "slash" << "jink" << "peach" << "analeptic";
            QString card = cards[mark - 1];

            bool prevent = false, draw_card = false, delete_card = false;

            for (int i = 0; i < 2; i++) {
                if (p->isDead()) break;

                QStringList choices;
                if (!prevent)
                    choices << "skill=" + player->objectName();
                if (!draw_card) {
                    int draw = p->getMark("SkillDescriptionArg1_dunshi");
                    choices << "draw=" + QString::number(draw);
                }
                if (!delete_card)
                    choices << "delete=" + card;

                QString choice = room->askForChoice(p, objectName(), choices.join("+"), data);

                if (choice.startsWith("skill")) {
                    prevent = true;
                    if (player->isAlive()) {
                        QStringList skills = getSkills(player);
                        if (skills.isEmpty()) continue;
                        QString sk = room->askForChoice(p, "dunshi_chooseskill", skills.join("+"), QVariant::fromValue(player));
                        room->acquireSkill(player, sk);
                    }
                } else if (choice.startsWith("draw")) {
                    draw_card = true;
                    int draw = p->getMark("SkillDescriptionArg1_dunshi");
                    room->loseMaxHp(p);
                    p->drawCards(draw, objectName());
                } else {
                    delete_card = true;
                    room->addPlayerMark(p, "SkillDescriptionArg1_dunshi");
                    room->addPlayerMark(p, "dunshi_used_" + card);

                    QString deletes = p->property("SkillDescriptionRecord_dunshi").toString();
                    QStringList delete_list;
                    if (!deletes.isEmpty())
                        delete_list = deletes.split("+");

                    if (!delete_list.contains(card)) {
                        LogMessage log;
                        log.type = "#DunshiDelete";
                        log.from = p;
                        log.arg = objectName();
                        log.arg2 = card;
                        room->sendLog(log);

                        delete_list << card;
                        room->setPlayerProperty(p, "SkillDescriptionRecord_dunshi", delete_list.join("+"));
                    }

                    room->changeTranslation(p, objectName(), 1);
                }
            }

            if (prevent)
                return true;
        }
        return false;
    }
};

ChenjianCard::ChenjianCard()
{
    mute = true;
    will_throw = false;
}

bool ChenjianCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.length() == 0;
}

void ChenjianCard::onUse(Room *room, const CardUseStruct &use) const
{
    room->addPlayerMark(use.to.first(), "chenjian_target-Clear");
}

class ChenjianVS : public OneCardViewAsSkill
{
public:
    ChenjianVS() : OneCardViewAsSkill("chenjian")
    {
        expand_pile = "#chenjian";
    }

    bool viewFilter(const Card *to_select) const
    {
        int id = to_select->getEffectiveId();
        if (Self->hasCard(id))
            return Self->canDiscard(Self, id);
        else if (Self->getPile("#chenjian").contains(id)) {
            const Card *card = Sanguosha->getCard(id);
            return card->isAvailable(Self) && !Self->isLocked(card) && Sanguosha->getCurrentCardUsePattern() != "@@chenjian2";
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (Self->getHandcards().contains(originalCard)) {
            ChenjianCard *card = new ChenjianCard;
            card->addSubcard(originalCard);
            return card;
        }
        return originalCard;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@chenjian");
    }
};

class Chenjian : public PhaseChangeSkill
{
public:
    Chenjian() : PhaseChangeSkill("chenjian")
    {
        view_as_skill = new ChenjianVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start) return false;
        int num = player->getMark("SkillDescriptionArg1_chenjian");
        num = qMax(num, 3);
        if (!player->askForSkillInvoke(this, "chenjian:" + QString::number(num))) return false;
        player->peiyin(this);

        Room *room = player->getRoom();
        QList<int> ids = room->showDrawPile(player, num, objectName());

        QString pattern = "@@chenjian1", prompt = "@chenjian1";
        int xxx = 0;
        try {
            for (int i = 0; i < 2; i++) {
                if (player->isDead() || ids.isEmpty()) break;

                if (!pattern.endsWith("2"))
                    room->notifyMoveToPile(player, ids, objectName(), Player::PlaceTable, true);

                room->fillAG(ids, player);
                const Card *c = room->askForUseCard(player, pattern, prompt, 1);
                room->clearAG(player);

                if (!pattern.endsWith("2"))
                    room->notifyMoveToPile(player, ids, objectName(), Player::PlaceTable, false);
                if (!c) break;

                xxx++;

                int card_id = c->getSubcards().first();
                const Card *ccc = Sanguosha->getCard(card_id);
                Card::Suit suit = ccc->getSuit();

                ServerPlayer *geter = NULL;
                foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                    if (p->getMark("chenjian_target-Clear") > 0) {
                        room->setPlayerMark(p, "chenjian_target-Clear", 0);
                        geter = p;
                        room->doAnimate(1, player->objectName(), p->objectName());
                        break;
                    }
                }

                if (geter) {
                    pattern = "@@chenjian3";
                    prompt = "@chenjian3";

                    room->throwCard(ccc, player);
                    if (geter->isDead()) continue;

                    DummyCard *dummy = new DummyCard;
                    dummy->deleteLater();
                    foreach (int id, ids) {
                        if (Sanguosha->getCard(id)->getSuit() == suit) {
                            ids.removeOne(id);
                            dummy->addSubcard(id);
                        };
                    }
                    if (dummy->subcardsLength() > 0)
                        room->obtainCard(geter, dummy);
                } else {
                    ids.removeOne(card_id);

                    pattern = "@@chenjian2";
                    prompt = "@chenjian2";
                }
            }

            if (xxx >= 2) {
                if (num < 5) {
                    num++;
                    room->setPlayerMark(player, "SkillDescriptionArg1_chenjian", num);
                    room->changeTranslation(player, objectName(), 1);
                }

                if (player->isAlive()) {
                    QList<int> recast;
                    foreach (int id, player->handCards()) {
                        if (!player->isCardLimited(Sanguosha->getCard(id), Card::MethodRecast, true))
                            recast << id;
                    }

                    if (!recast.isEmpty()) {
                        CardMoveReason reason(CardMoveReason::S_REASON_RECAST, player->objectName());
                        reason.m_skillName = objectName();
                        CardsMoveStruct move(recast, NULL, Player::DiscardPile, reason);
                        room->moveCardsAtomic(move, true);
                        player->broadcastSkillInvoke("@recast");
                        LogMessage log;
                        log.type = "$RecastCard";
                        log.from = player;
                        log.card_str = IntList2StringList(recast).join("+");
                        room->sendLog(log);
                        player->drawCards(1, "recast");
                    }
                }
            }

            if (!ids.isEmpty()) {
                DummyCard *dummy = new DummyCard(ids);
                dummy->deleteLater();
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), objectName(), QString());
                room->throwCard(dummy, reason, NULL);
            }
        }
        catch (TriggerEvent triggerEvent) {
            if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
                foreach (ServerPlayer *p, room->getAllPlayers(true))
                    room->setPlayerMark(p, "chenjian_target-Clear", 0);
                if (!ids.isEmpty()) {
                    DummyCard *dummy = new DummyCard(ids);
                    dummy->deleteLater();
                    CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), objectName(), QString());
                    room->throwCard(dummy, reason, NULL);
                }
            }
            throw triggerEvent;
        }
        return false;
    }
};

class Xixiu : public TriggerSkill
{
public:
    Xixiu() : TriggerSkill("xixiu")
    {
        events << TargetConfirming << BeforeCardsMove;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SkillCard") || !use.to.contains(player) || !use.from || use.from == player) return false;
            if (!use.card->hasSuit()) return false;
            Card::Suit suit = use.card->getSuit();
            foreach (const Card *card, player->getEquips()) {
                if (card->getSuit() != suit) continue;
                room->sendCompulsoryTriggerLog(player, this);
                player->drawCards(1, objectName());
                return true;
            }
        } else {
            if (player->getEquips().length() != 1) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from != player || !move.from_places.contains(Player::PlaceEquip)) return false;
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                QString from = move.reason.m_playerId;
                if (from.isEmpty() || from == player->objectName()) return false;
                int equip_id = player->getEquipsId().first();
                foreach (int id, move.card_ids) {
                    if (id != equip_id) continue;
                    room->sendCompulsoryTriggerLog(player, this);
                    move.card_ids.removeOne(id);
                    data = QVariant::fromValue(move);
                    return false;
                }
            }
        }
        return false;
    }
};

YuanyuCard::YuanyuCard()
{
    target_fixed = true;
}

void YuanyuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(1, "yuanyu");
    if (!source->isKongcheng()) {
        const Card * c = room->askForExchange(source, "yuanyu", 1, 1, false, "@yuanyu-put");
        source->addToPile("zyyyyuan", c);
        delete c;
    }
    if (source->isDead()) return;
    ServerPlayer *t = room->askForPlayerChosen(source, room->getOtherPlayers(source), "yuanyu", "@yuanyu-target");
    room->doAnimate(1, source->objectName(), t->objectName());
    room->setPlayerMark(t, "&yuanyu+#" + source->objectName(), 1);
}

class YuanyuVS : public ZeroCardViewAsSkill
{
public:
    YuanyuVS() : ZeroCardViewAsSkill("yuanyu")
    {
    }

    const Card *viewAs() const
    {
        return new YuanyuCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YuanyuCard");
    }
};

class Yuanyu : public TriggerSkill
{
public:
    Yuanyu() : TriggerSkill("yuanyu")
    {
        events << Damage;
        view_as_skill = new YuanyuVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && !target->isKongcheng();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        int n = damage.damage;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isDead() || player->getMark("&yuanyu+#" + p->objectName()) <= 0) continue;
            if (player->isDead() || player->isKongcheng()) return false;
            room->sendCompulsoryTriggerLog(p, this);
            for (int i = 0; i < n; i++) {
                if (player->isDead() || player->isKongcheng()) return false;
                const Card * c = room->askForExchange(player, "yuanyu", 1, 1, false, "@yuanyu-put2:" + p->objectName());
                p->addToPile("zyyyyuan", c);
                delete c;
            }
        }
        return false;
    }
};

class Xiyan : public TriggerSkill
{
public:
    Xiyan() : TriggerSkill("xiyan")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to == player && move.to_place == Player::PlaceSpecial && move.to_pile_name == "zyyyyuan") {
            QList<Card::Suit> suits;
            QList<int> yuans = player->getPile("zyyyyuan");
            foreach (int id, yuans) {
                const Card *card = Sanguosha->getCard(id);
                Card::Suit suit = card->getSuit();
                if (suits.contains(suit)) continue;
                suits << suit;
            }
            if (suits.length() < 4) return false;
            room->sendCompulsoryTriggerLog(player, this);

            foreach (ServerPlayer *p, room->getOtherPlayers(player))
                room->setPlayerMark(p, "&yuanyu+#" + player->objectName(), 0);

            LogMessage log;
            log.type = "$KuangbiGet";
            log.from = player;
            log.arg = "zyyyyuan";
            log.card_str = IntList2StringList(yuans).join("+");
            room->sendLog(log);
            DummyCard dummy(yuans);
            room->obtainCard(player, &dummy, true);

            ServerPlayer *current = room->getCurrent();
            if (!current) return false;

            if (current == player) {
                room->addPlayerMark(current, "&xiyan1-Clear");
                room->addMaxCards(current, 4);
            } else {
                room->addPlayerMark(current, "&xiyan2-Clear");
                room->addMaxCards(current, -4);
                room->setPlayerCardLimitation(current, "use", "BasicCard", true);
            }
        }
        return false;
    }
};

class XiyanTargetMod : public TargetModSkill
{
public:
    XiyanTargetMod() : TargetModSkill("#xiyan")
    {
        pattern = "^SkillCard";
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->getMark("&xiyan1-Clear") > 0)
            return 1000;
        else
            return 0;
    }
};

class JinZhefu : public TriggerSkill
{
public:
    JinZhefu() : TriggerSkill("jinzhefu")
    {
        events << CardFinished << PostCardResponded;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive) return false;

        const Card *card = NULL;
        if (event == CardFinished)
            card = data.value<CardUseStruct>().card;
        else
            card = data.value<CardResponseStruct>().m_card;
        if (!card || !card->isKindOf("BasicCard")) return false;

        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isKongcheng()) continue;
            targets << p;
        }
        if (targets.isEmpty()) return false;

        QString name = card->objectName();
        ServerPlayer *t = room->askForPlayerChosen(player, targets, objectName(), "@jinzhefu-invoke:" + name, true, true);
        if (!t) return false;
        player->peiyin(this);

        QString pattern = card->getClassName();
        if (card->isKindOf("Slash")) {
            pattern = "Slash";
            name = "slash";
        }

        if (room->askForDiscard(t, objectName(), 1, 1, true, false, "@jinzhefu-discard:" + player->objectName() + "::" + name, pattern))
            return false;
        room->damage(DamageStruct(objectName(), player, t));
        return false;
    }
};

class JinYidu : public TriggerSkill
{
public:
    JinYidu() : TriggerSkill("jinyidu")
    {
        events << CardFinished;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.length() != 1) return false;
        if (use.card->isKindOf("Slash") || (use.card->isDamageCard() && use.card->isNDTrick())) {
            ServerPlayer *to = use.to.first();
            if (to->isKongcheng() || use.card->hasFlag("DamageDone_" + to->objectName())) return false;
            if (!player->askForSkillInvoke(this, to)) return false;
            player->peiyin(this);

            int ad = Config.AIDelay;
            Config.AIDelay = 0;
            to->setFlags("jinyidu_InTempMoving");

            QList<int> cards;
            for (int i = 0; i < 3; i++) {
                if (to->isKongcheng()) break;
                int id = room->askForCardChosen(player, to, "h", objectName(), false, Card::MethodNone, QList<int>(), i != 0);
                if (id < 0) break;
                cards << id;
                to->addToPile("#jinyidu", id, false);
            }
            foreach (int id, cards)
                room->moveCardTo(Sanguosha->getCard(id), to, Player::PlaceHand, false);

            to->setFlags("-jinyidu_InTempMoving");
            Config.AIDelay = ad;

            room->showCard(to, cards);

            Card::Color color = Sanguosha->getCard(cards.first())->getColor();
            foreach (int id, cards) {
                if (Sanguosha->getCard(id)->getColor() != color)
                    return false;
            }

            QList<int> to_throw;
            foreach (int id, cards) {
                if (!to->canDiscard(to, id)) continue;
                to_throw << id;
            }
            if (to_throw.isEmpty()) return false;

            DummyCard dummy(to_throw);
            room->throwCard(&dummy, to);
        }
        return false;
    }
};

class Xingchong : public TriggerSkill
{
public:
    Xingchong() : TriggerSkill("xingchong")
    {
        events << RoundStart;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        int max = player->getMaxHp();
        if (max <= 0 || !player->askForSkillInvoke(this)) return false;
        player->peiyin(this);

        int _max = max + 1;
        QStringList choices;
        for (int i = 0; i < _max; i++)
            choices << "xingchong=" + QString::number(i);
        QString choice = room->askForChoice(player, objectName(), choices.join("+"));

        int draw = choice.split("=").last().toInt();
        player->drawCards(draw, objectName());
        if (player->isNude()) return false;

        int show = max - draw;
        if (show <= 0) return false;

        const Card *ex = room->askForExchange(player, objectName(), show, 1, false, "@xingchong-show:" + QString::number(show), true);
        if (!ex) return false;

        QList<int> subcards = ex->getSubcards();
        foreach (int id, subcards)
            room->setPlayerMark(player, "xingchong_" + QString::number(id) + "_lun", 1);
        room->showCard(player, subcards);
        delete ex;
        return false;
    }
};

class XingchongDraw : public TriggerSkill
{
public:
    XingchongDraw() : TriggerSkill("#xingchong")
    {
        events << CardsMoveOneTime;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player) return false;
        if (!move.from_places.contains(Player::PlaceHand)) return false;
        for (int i = 0; i < move.card_ids.length(); i++) {
            if (move.from_places.at(i) != Player::PlaceHand) continue;
            int id = move.card_ids.at(i);
            if (player->getMark("xingchong_" + QString::number(id) + "_lun") <= 0) continue;
            room->setPlayerMark(player, "xingchong_" + QString::number(id) + "_lun", 0);
            if (player->isDead()) continue;
            room->sendCompulsoryTriggerLog(player, "xingchong", true, true);
            player->drawCards(2, "xingchong");
        }
        return false;
    }
};

class Liunian : public TriggerSkill
{
public:
    Liunian() : TriggerSkill("liunian")
    {
        events << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        int times = room->getTag("SwapPile").toInt();
        if (times > 2) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            if (times == 1) {
                if (p->getMark("liunian1-Keep") > 0) continue;
                room->sendCompulsoryTriggerLog(p, this);
                room->setPlayerMark(p, "liunian1-Keep", 1);
                room->gainMaxHp(p);
            } else if (times == 2) {
                if (p->getMark("liunian2-Keep") > 0) continue;
                room->sendCompulsoryTriggerLog(p, this);
                room->setPlayerMark(p, "liunian2-Keep", 1);
                room->recover(p, RecoverStruct(p));
                room->addMaxCards(p, 10);
                room->addPlayerMark(p, "&liunian2");
            }
        }
        return false;
    }
};

SP5Package::SP5Package()
    : Package("sp5")
{
    General *sp_zhanghe = new General(this, "sp_zhanghe", "qun", 4);
    sp_zhanghe->addSkill(new Zhouxuanz);

    General *dongzhao = new General(this, "dongzhao", "wei", 3);
    dongzhao->addSkill(new Xianlve);
    dongzhao->addSkill(new XianlveEffect);
    dongzhao->addSkill(new Zaowang);
    related_skills.insertMulti("xianlve", "#xianlve-effect");

    General *lvlingqi = new General(this, "lvlingqi", "qun", 4, false);
    lvlingqi->addSkill(new Guowu);
    lvlingqi->addSkill(new GuowuShow);
    lvlingqi->addSkill(new GuowuTargetMod);
    lvlingqi->addSkill(new Zhuangrong);
    lvlingqi->addRelateSkill("shenwei");
    lvlingqi->addRelateSkill("wushuang");
    related_skills.insertMulti("guowu", "#guowu-show");
    related_skills.insertMulti("guowu", "#guowu-target");

    General *xiahoujie = new General(this, "xiahoujie", "wei", 5);
    xiahoujie->addSkill(new Liedan);
    xiahoujie->addSkill(new LiedanDead);
    xiahoujie->addSkill(new Zhuangdan);
    related_skills.insertMulti("liedan", "#liedan-dead");

    General *caojinyu = new General(this, "caojinyu", "wei", 3, false);
    caojinyu->addSkill(new Yuqi);
    caojinyu->addSkill(new Shanshen);
    caojinyu->addSkill(new Xianjing);

    General *wangtao = new General(this, "wangtao", "shu", 3, false);
    wangtao->addSkill(new Huguan);
    wangtao->addSkill(new HuguanIgnore);
    wangtao->addSkill(new Yaopei);
    related_skills.insertMulti("huguan", "#huguan");

    General *tenyear_pangdegong = new General(this, "tenyear_pangdegong", "qun", 3);
    tenyear_pangdegong->addSkill(new Heqia);
    tenyear_pangdegong->addSkill(new HeqiaTargetMod);
    tenyear_pangdegong->addSkill(new Yinyi);
    related_skills.insertMulti("heqia", "#heqia");

    General *sp_wuyan = new General(this, "sp_wuyan", "wu", 4);
    sp_wuyan->addSkill(new Lanjiang);

    General *wangyue = new General(this, "wangyue", "shu", 3, false);
    wangyue->addSkill("huguan");
    wangyue->addSkill(new Mingluan);
    wangyue->addSkill(new MingluanRecord);
    related_skills.insertMulti("mingluan", "#mingluan");

    General *maojie = new General(this, "maojie", "wei", 3);
    maojie->addSkill(new Bingqing);
    maojie->addSkill(new Yingfeng);
    maojie->addSkill(new YingfengTarget);
    related_skills.insertMulti("yingfeng", "#yingfeng");

    General *ol_zhuling = new General(this, "ol_zhuling", "wei", 4);
    ol_zhuling->addSkill(new JixianZL);
    ol_zhuling->addSkill(new JixianZLEffect);
    related_skills.insertMulti("jixianzl", "#jixianzl");

    General *tenyear_zhuling = new General(this, "tenyear_zhuling", "wei", 4);
    tenyear_zhuling->addSkill(new TenyearZhanyi);
    tenyear_zhuling->addSkill(new TenyearZhanyiEffect);
    tenyear_zhuling->addSkill(new TenyearZhanyiTarget);
    related_skills.insertMulti("tenyearzhanyi", "#tenyearzhanyi");
    related_skills.insertMulti("tenyearzhanyi", "#tenyearzhanyi-mod");

    General *zhaoyan = new General(this, "zhaoyan", "wu", 3, false);
    zhaoyan->addSkill(new Jinhui);
    zhaoyan->addSkill(new JinhuiTarget);
    zhaoyan->addSkill(new Qingman);
    related_skills.insertMulti("jinhui", "#jinhui-target");

    General *tianyu = new General(this, "tianyu", "wei", 4);
    tianyu->addSkill(new Saodi);
    tianyu->addSkill(new Zhuitao);
    tianyu->addSkill(new ZhuitaoDistance);
    related_skills.insertMulti("zhuitao", "#zhuitao");

    General *sunyi = new General(this, "sunyi", "wu", 5);
    sunyi->addSkill(new Jiqiaosy);
    sunyi->addSkill(new JiqiaosyEnter);
    sunyi->addSkill(new Xiongyisy);
    related_skills.insertMulti("jiqiaosy", "#jiqiaosy");

    General *haomeng = new General(this, "haomeng", "qun", 7);
    haomeng->addSkill(new Xiongmang);
    haomeng->addSkill(new XiongmangDamage);
    related_skills.insertMulti("xiongmang", "#xiongmang");

    General *tenyear_dengzhi = new General(this, "tenyear_dengzhi", "shu", 3);
    tenyear_dengzhi->addSkill(new Jianliang);
    tenyear_dengzhi->addSkill(new Weimeng);
    tenyear_dengzhi->addSkill(new FakeMoveSkill("weimeng"));
    related_skills.insertMulti("weimeng", "#weimeng-fake-move");

    General *fengxi = new General(this, "fengxi", "wu", 3);
    fengxi->addSkill(new Yusui);
    fengxi->addSkill(new Boyan);
    fengxi->addSkill(new BoyanLimit);
    related_skills.insertMulti("boyan", "#boyan-limit");

    General *fanjiangzhangda = new General(this, "fanjiangzhangda", "wu", 4);
    fanjiangzhangda->addSkill(new Yuanchou);
    fanjiangzhangda->addSkill(new Juesheng);
    fanjiangzhangda->addSkill(new JueshengRecord);
    related_skills.insertMulti("juesheng", "#juesheng");

    General *qinghegongzhu = new General(this, "qinghegongzhu", "wei", 3, false);
    qinghegongzhu->addSkill(new Zengou);
    qinghegongzhu->addSkill(new Zhangji);

    General *jin_yanghu = new General(this, "jin_yanghu", "jin", 4);
    jin_yanghu->addSkill(new JinHuaiyuan);
    jin_yanghu->addSkill(new JinHuaiyuanDeath);
    jin_yanghu->addSkill(new JinHuaiyuanKeep);
    jin_yanghu->addSkill(new JinHuaiyuanAttack);
    jin_yanghu->addSkill(new JinChongxin);
    jin_yanghu->addSkill(new JinDezhang);
    related_skills.insertMulti("jinhuaiyuan", "#jinhuaiyuan");
    related_skills.insertMulti("jinhuaiyuan", "#jinhuaiyuan-keep");
    related_skills.insertMulti("jinhuaiyuan", "#jinhuaiyuan-attack");

    General *miheng = new General(this, "miheng", "qun", 3);
    miheng->addSkill(new Kuangcai);
    miheng->addSkill(new KuangcaiTarget);
    miheng->addSkill(new Shejian);
    miheng->addSkill(new FakeMoveSkill("shejian"));
    related_skills.insertMulti("kuangcai", "#kuangcai");
    related_skills.insertMulti("shejian", "#shejian-fake-move");

    General *yanfuren = new General(this, "yanfuren", "qun", 3, false);
    yanfuren->addSkill(new Channi);
    yanfuren->addSkill(new Nifu);

    General *fengyu = new General(this, "fengyu", "qun", 3, false);
    fengyu->addSkill(new Tiqi);
    fengyu->addSkill(new TiqiRecord);
    fengyu->addSkill(new Baoshu);
    fengyu->addSkill(new BaoshuDraw);
    related_skills.insertMulti("tiqi", "#tiqi");
    related_skills.insertMulti("baoshu", "#baoshu");

    General *wufan = new General(this, "wufan", "wu", 4);
    wufan->addSkill(new Tianyun);
    wufan->addSkill(new TianyunInitial);
    wufan->addSkill(new Yuyan);
    wufan->addSkill(new YuyanDying);
    wufan->addSkill(new YuyanEffect);
    related_skills.insertMulti("tianyun", "#tianyun");
    related_skills.insertMulti("yuyan", "#yuyan-dying");
    related_skills.insertMulti("yuyan", "#yuyan");

    General *maridi = new General(this, "maridi", "qun", 6);
    maridi->setStartHp(4);
    maridi->addSkill(new Bingjie);
    maridi->addSkill(new BingjieEffect);
    maridi->addSkill(new Zhengding);
    related_skills.insertMulti("bingjie", "#bingjie");

    General *licaiwei = new General(this, "licaiwei", "qun", 3, false);
    licaiwei->addSkill(new Yijiao);
    licaiwei->addSkill(new Qibie);

    General *jiping = new General(this, "jiping", "qun", 3);
    jiping->addSkill(new Xunli);
    jiping->addSkill(new Zhishi);
    jiping->addSkill(new ZhishiChoose);
    jiping->addSkill(new ZhishiMark);
    jiping->addSkill(new Lieyi);
    jiping->addSkill(new LieyiTarget);
    related_skills.insertMulti("zhishi", "#zhishi");
    related_skills.insertMulti("zhishi", "#zhishi-mark");
    related_skills.insertMulti("lieyi", "#lieyi");

    General *sp_menghuo = new General(this, "sp_menghuo", "qun", 4);
    sp_menghuo->addSkill(new Manwang);

    General *luotong = new General(this, "luotong", "wu", 3);
    luotong->addSkill(new Jinjian);
    luotong->addSkill(new JinjianEffect);
    luotong->addSkill(new Renzheng);
    related_skills.insertMulti("jinjian", "#jinjian");

    General *guanning = new General(this, "guanning", "qun", 7);
    guanning->setStartHp(3);
    guanning->addSkill(new Dunshi);

    General *tengyin = new General(this, "tengyin", "wu", 3);
    tengyin->addSkill(new Chenjian);
    tengyin->addSkill(new Xixiu);

    General *zhangyao = new General(this, "zhangyao", "wu", 3, false);
    zhangyao->addSkill(new Yuanyu);
    zhangyao->addSkill(new Xiyan);
    zhangyao->addSkill(new XiyanTargetMod);
    related_skills.insertMulti("xiyan", "#xiyan");

    General *jin_guohuai = new General(this, "jin_guohuai", "jin", 3, false);
    jin_guohuai->addSkill(new JinZhefu);
    jin_guohuai->addSkill(new JinYidu);
    jin_guohuai->addSkill(new FakeMoveSkill("jinyidu"));
    related_skills.insertMulti("jinyidu", "#jinyidu-fake-move");

    General *tenggongzhu = new General(this, "tenggongzhu", "wu", 3, false);
    tenggongzhu->addSkill(new Xingchong);
    tenggongzhu->addSkill(new XingchongDraw);
    tenggongzhu->addSkill(new Liunian);
    related_skills.insertMulti("xingchong", "#xingchong");

    addMetaObject<ZhouxuanzCard>();
    addMetaObject<ZaowangCard>();
    addMetaObject<GuowuCard>();
    addMetaObject<YuqiCard>();
    addMetaObject<HeqiaCard>();
    addMetaObject<HeqiaUseCard>();
    addMetaObject<JinhuiCard>();
    addMetaObject<JinhuiUseCard>();
    addMetaObject<JiqiaosyCard>();
    addMetaObject<XiongmangCard>();
    addMetaObject<JianliangCard>();
    addMetaObject<WeimengCard>();
    addMetaObject<BoyanCard>();
    addMetaObject<JinChongxinCard>();
    addMetaObject<ChanniCard>();
    addMetaObject<BaoshuCard>();
    addMetaObject<YijiaoCard>();
    addMetaObject<XunliPutCard>();
    addMetaObject<XunliCard>();
    addMetaObject<ZhishiCard>();
    addMetaObject<LieyiCard>();
    addMetaObject<ManwangCard>();
    addMetaObject<DunshiCard>();
    addMetaObject<ChenjianCard>();
    addMetaObject<YuanyuCard>();

    skills << new JinWeishu << new Panqin << new PanqinRecord;
    related_skills.insertMulti("panqin", "#panqin");
}

ADD_PACKAGE(SP5)
