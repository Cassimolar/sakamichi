#include "challengedeveloper-scenario.h"
#include "scenario.h"
#include "skill.h"
#include "clientplayer.h"
#include "client.h"
#include "engine.h"
#include "standard.h"
#include "room.h"
#include "roomthread.h"
#include "wind.h"
#include "maneuvering.h"
#include "json.h"
#include "settings.h"
#include "time.h"

class ChallengeDeveloperRule : public ScenarioRule
{
public:
    ChallengeDeveloperRule(Scenario *scenario)
        : ScenarioRule(scenario)
    {
        events << GameReady << Death << RoundStart;
    }

    static QStringList getDevelopers()
    {
        QStringList developers;
        developers << "dev_chongmei" << "dev_duguanhe" << "dev_dudu" << "dev_db" << "dev_amira" << "dev_mye" << "dev_yizhiyongheng"
                   << "dev_yuanjiati" << "dev_funima" << "dev_para" << "dev_rara" << "dev_fsu" << "dev_hmqgg" << "dev_tak" << "dev_lzx"
                   << "dev_cheshen" << "dev_36li" << "dev_tan" << "dev_zhangzheng" << "dev_jiaqi" << "dev_zy" << "dev_jiaoshen";
        //developers << "dev_xusine";
        return developers;
    }

    static QStringList getSkills(ServerPlayer *player, const QString &kingdom, bool lord_skill, bool wake_skill, bool lua)
    {
        QStringList names = Sanguosha->getLimitedGeneralNames(kingdom), skills, _skills;
        QStringList lua_packages = Config.value("LuaPackages", QString()).toString().split("+");
        foreach (QString name, names) {
            const General *gen = Sanguosha->getGeneral(name);
            if (!gen) continue;
            if (!lua && lua_packages.contains(gen->getPackage())) continue;
            QList<const Skill *> gen_skills = gen->getVisibleSkillList();
            foreach (const Skill *sk, gen_skills) {
                if (skills.contains(sk->objectName())) continue;
                if (!lord_skill && sk->isLordSkill()) continue;
                if (!wake_skill && sk->getFrequency() == Skill::Wake) continue;
                if (sk->isHideSkill()) continue;
                if (player->hasSkill(sk, true)) continue;
                skills << sk->objectName();
            }
        }

        for (int i = 0; i < 5; i++) {
            QString skill = skills.at(qrand() % skills.length());
            _skills << skill;
            skills.removeOne(skill);
        }

        return _skills;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        switch (triggerEvent) {
        case GameReady: {
            QStringList developers = getDevelopers();
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isLord()) continue;
                QString developer = developers.at(qrand() % developers.length());
                developers.removeOne(developer);
                if (Sanguosha->getGeneral(developer))
                    room->changeHero(p, developer, false, false, false, false, Sanguosha->getGeneral(developer)->getStartHp());
            }

            ServerPlayer *lord = room->getLord();
            if (lord) {
                if (lord->askForSkillInvoke("ChallengeDeveloperRule", "change", false))
                    room->changeHero(lord, "sujiangf", true, false, false, false);

                if (lord->getKingdom() == "god")
                    room->setPlayerProperty(lord, "kingdom", room->askForKingdom(lord));

                for (int i = 0; i < 3; i++) {
                    if (lord->isDead()) break;
                    QStringList skills = getSkills(lord, lord->getKingdom(), false, false, false);
                    if (skills.isEmpty()) break;
                    QString skill = room->askForChoice(lord, "ChallengeDeveloperRuleSkill", skills.join("+"));
                    room->acquireSkill(lord, skill);
                }
            }
            break;
        }
        case Death: {
            DeathStruct death = data.value<DeathStruct>();
            ServerPlayer *lord = room->getLord();
            if (lord && death.who != lord && player == lord) {
                QString name = death.who->getGeneralName();
                const General *gen = Sanguosha->getGeneral(name);
                if (gen) {
                    QStringList get_skills;
                    QList<const Skill *> gen_skills = gen->getVisibleSkillList();
                    foreach (const Skill *sk, gen_skills) {
                        if (get_skills.contains(sk->objectName()) || lord->hasSkill(sk, true)) continue;
                        get_skills << sk->objectName();
                    }
                    if (!get_skills.isEmpty())
                        room->handleAcquireDetachSkills(lord, get_skills);
                }

                if (lord->isAlive())
                    room->recover(lord, RecoverStruct(NULL, NULL, qMin(2, lord->getMaxHp() - lord->getHp())));

                if (lord->isAlive())
                    lord->drawCards(2, "ChallengeDeveloperRule");
            }
            break;
        }
        case RoundStart: {
            if (player != room->getAlivePlayers().first()) return false;
            int round = data.toInt();
            if (round % 2 == 0) {
                room->doLightbox("#dashendenuhuo");
                ServerPlayer *lord = room->getLord();
                if (lord) {
                    lord->throwAllEquips();
                    foreach (ServerPlayer *p, room->getOtherPlayers(lord))
                        room->addAttackRange(p, 1, false);
                }
            } else {
                for (int i = 0; i < 2; i++) {
                    if (room->alivePlayerCount() <= 2) return false;

                    room->doLightbox("#mengxindekunhuo" + QString::number(i + 1));

                    int hp = -1000;
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (p->isLord()) continue;
                        if (p->getHp() > hp)
                            hp = p->getHp();
                    }
                    QList<ServerPlayer *> developers;
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (p->isLord()) continue;
                        if (p->getHp() == hp)
                            developers << p;
                    }
                    if (developers.isEmpty()) return false;
                    room->loseHp(developers.at(qrand() % developers.length()));

                    hp = player->getHp();
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (p->getHp() < hp)
                            return false;
                    }

                    room->getThread()->delay();
                }
            }
        }
        default:
            break;
        }

        return false;
    }
};

void ChallengeDeveloperScenario::onTagSet(Room *, const QString &) const
{
}

DevLvedongCard::DevLvedongCard()
{
    mute = true;
    m_skillName = "dev_lvedong";
}

bool DevLvedongCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
    } else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        return false;
    }

    const Card *_card = Self->tag.value("dev_lvedong").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool DevLvedongCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
        const Card *card = NULL;
        if (!user_string.isEmpty())
            card = Sanguosha->cloneCard(user_string.split("+").first());
        return card && card->targetsFeasible(targets, Self);
    }

    const Card *_card = Self->tag.value("dev_lvedong").value<const Card *>();
    if (_card == NULL)
        return false;

    Card *card = Sanguosha->cloneCard(_card);
    card->setCanRecast(false);
    card->deleteLater();
    return card && card->targetsFeasible(targets, Self);
}

const Card *DevLvedongCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    Room *room = source->getRoom();

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = source;
    log.arg = "dev_lvedong";
    room->sendLog(log);
    room->notifySkillInvoked(source, "dev_lvedong");
    room->broadcastSkillInvoke("dev_lvedong");

    QString tl = user_string;
    if ((user_string.contains("slash") || user_string.contains("Slash")))
        tl = "slash";

    QList<int> show_ids = room->showDrawPile(source, 2 + source->getLostHp(), "dev_lvedong", false);
    QList<int> disable_ids, enable_ids;
    foreach (int id, show_ids) {
        const Card *card = Sanguosha->getCard(id);
        if (card->sameNameWith(tl)) {
            enable_ids << id;
            continue;
        }
        if (tl == "slash" && card->getSuit() == Card::Diamond) {
            enable_ids << id;
            continue;
        }
        if (tl == "analeptic" && card->getSuit() == Card::Spade) {
            enable_ids << id;
            continue;
        }
        if (tl == "jink" && card->getSuit() == Card::Club) {
            enable_ids << id;
            continue;
        }
        disable_ids << id;
    }

    if (enable_ids.isEmpty()) {
        JsonArray arg;
        arg << "." << false << JsonUtils::toJsonArray(show_ids);
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_SHOW_ALL_CARDS, arg);

        room->setPlayerFlag(source, "Global_DevLvedongFailed");
        return NULL;
    }

    room->fillAG(show_ids, NULL, disable_ids);
    int id = room->askForAG(source, enable_ids, false, "dev_lvedong");
    room->clearAG();

    const Card *card = Sanguosha->getCard(id);
    if (card->sameNameWith(tl))
        return card;

    if (tl == "slash" && Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
        QStringList tl_list = Sanguosha->getSlashNames();
        if (tl_list.isEmpty()) {
            room->setPlayerFlag(source, "Global_DevLvedongFailed");
            return NULL;
        }
        tl = room->askForChoice(source, "dev_lvedong_slash", tl_list.join("+"));
    }

    Card *new_card = Sanguosha->cloneCard(tl, Card::SuitToBeDecided, -1);
    new_card->addSubcard(id);
    new_card->setSkillName("_dev_lvedong");
    new_card->deleteLater();

    return new_card;
}

const Card *DevLvedongCard::validateInResponse(ServerPlayer *source) const
{
    Room *room = source->getRoom();

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = source;
    log.arg = "dev_lvedong";
    room->sendLog(log);
    room->notifySkillInvoked(source, "dev_lvedong");
    room->broadcastSkillInvoke("dev_lvedong");

    QString tl;
    if (user_string == "peach+analeptic")
        tl = "analeptic";
    else if ((user_string.contains("slash") || user_string.contains("Slash")))
        tl = "slash";
    else
        tl = user_string;

    QList<int> show_ids = room->showDrawPile(source, 2 + source->getLostHp(), "dev_lvedong", false);
    QList<int> disable_ids, enable_ids;
    foreach (int id, show_ids) {
        const Card *card = Sanguosha->getCard(id);
        if (card->sameNameWith(tl)) {
            enable_ids << id;
            continue;
        }
        if (tl == "analeptic" && card->isKindOf("Peach")) {
            enable_ids << id;
            continue;
        }
        if (tl == "slash" && card->getSuit() == Card::Diamond) {
            enable_ids << id;
            continue;
        }
        if (tl == "analeptic" && card->getSuit() == Card::Spade) {
            enable_ids << id;
            continue;
        }
        if (tl == "jink" && card->getSuit() == Card::Club) {
            enable_ids << id;
            continue;
        }
        disable_ids << id;
    }

    if (enable_ids.isEmpty()) {
        JsonArray arg;
        arg << "." << false << JsonUtils::toJsonArray(show_ids);
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_SHOW_ALL_CARDS, arg);

        room->setPlayerFlag(source, "Global_DevLvedongFailed");
        return NULL;
    }

    room->fillAG(show_ids, NULL, disable_ids);
    int id = room->askForAG(source, enable_ids, false, "dev_lvedong");
    room->clearAG();

    const Card *card = Sanguosha->getCard(id);
    if (card->sameNameWith(tl) || (tl == "analeptic" && card->isKindOf("Peach")))
        return card;

    if (tl == "slash") {
        QStringList tl_list = Sanguosha->getSlashNames();
        if (tl_list.isEmpty()) {
            room->setPlayerFlag(source, "Global_DevLvedongFailed");
            return NULL;
        }
        tl = room->askForChoice(source, "dev_lvedong_slash", tl_list.join("+"));
    }

    Card *new_card = Sanguosha->cloneCard(tl, Card::SuitToBeDecided, -1);
    new_card->addSubcard(id);
    new_card->setSkillName("_dev_lvedong");
    new_card->deleteLater();

    return new_card;
}

class DevLvedong : public ZeroCardViewAsSkill
{
public:
    DevLvedong() : ZeroCardViewAsSkill("dev_lvedong")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->hasFlag("Global_DevLvedongFailed")) return false;
        return Slash::IsAvailable(player) || player->isWounded() || Analeptic::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->hasFlag("Global_DevLvedongFailed")) return false;
        if (pattern == "peach" && player->getMark("Global_PreventPeach") > 0) return false;

        bool basic = false;
        QStringList patterns = pattern.split("+");
        foreach (QString name, patterns) {
            name = name.toLower();
            Card *card = Sanguosha->cloneCard(name);
            if (!card) continue;
            card->deleteLater();
            if (card->isKindOf("BasicCard"))
                basic = true;
        }
        if (!basic) {
            patterns = pattern.split(",");
            foreach (QString name, patterns) {
                name = name.toLower();
                Card *card = Sanguosha->cloneCard(name);
                if (!card) continue;
                card->deleteLater();
                if (card->isKindOf("BasicCard"))
                    basic = true;
            }
        }
        return basic;
    }

    const Card *viewAs() const
    {
        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE ||
                Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE) {
            DevLvedongCard *card = new DevLvedongCard;
            card->setUserString(Sanguosha->getCurrentCardUsePattern());
            return card;
        }

        const Card *c = Self->tag.value("dev_lvedong").value<const Card *>();
        if (c && c->isAvailable(Self)) {
            DevLvedongCard *card = new DevLvedongCard;
            card->setUserString(c->objectName());
            return card;
        } else
            return NULL;
        return NULL;
    }

    QDialog *getDialog() const
    {
        return GuhuoDialog::getInstance("dev_lvedong", true, false);
    }
};

class DevCaiyi : public TriggerSkill
{
public:
    DevCaiyi() : TriggerSkill("dev_caiyi")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        foreach (ServerPlayer *p, use.to) {
            if (p->isDead()) continue;
            if (!player->askForSkillInvoke(this, p)) continue;
            room->broadcastSkillInvoke(this);
            if (room->askForDiscard(p, objectName(), 1, 1, true, false, "@dev_caiyi-discard", "Slash")) continue;
            use.no_respond_list << p->objectName();
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class DevJianshiVS : public ViewAsSkill
{
public:
    DevJianshiVS() : ViewAsSkill("dev_jianshi")
    {
        response_pattern = "nullification";
        expand_pile = "dev_jian";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return Self->getPile("dev_jian").contains(to_select->getEffectiveId()) && selected.length() < 2;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2) return NULL;
        Card *ncard = new Nullification(Card::SuitToBeDecided, -1);
        ncard->addSubcards(cards);
        ncard->setSkillName(objectName());
        return ncard;
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        return player->getPhase() == Player::NotActive && player->getPile("dev_jian").length() > 1;
    }
};

class DevJianshi : public TriggerSkill
{
public:
    DevJianshi() : TriggerSkill("dev_jianshi")
    {
        events << CardsMoveOneTime;
        view_as_skill = new DevJianshiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player) return false;
        if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)) return false;
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            QList<int> blacks;
            int i = 0;
            foreach (int id, move.card_ids) {
                if (!Sanguosha->getCard(id)->isBlack()) continue;
                if (room->getCardPlace(id) != Player::DiscardPile) continue;
                if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)
                    blacks << id;
                i++;
            }
            if (blacks.isEmpty()) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(this);
            player->addToPile("dev_jian", blacks);
        }
        return false;
    }
};

class DevCangdao : public TriggerSkill
{
public:
    DevCangdao() : TriggerSkill("dev_cangdao")
    {
        events << BeforeCardsMove;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from != player) return false;
        if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)) return false;
        if (move.to_place != Player::DiscardPile) return false;

        QList<int> equips;
        int i = 0;
        foreach (int id, move.card_ids) {
            if (!Sanguosha->getCard(id)->isKindOf("EquipCard")) continue;
            if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)
                equips << id;
            i++;
        }

        while (!equips.isEmpty()) {
            if (player->isDead()) return false;
            CardsMoveStruct yiji_move = room->askForYijiStruct(player, equips, objectName(), false, true, true, 1,
                            room->getOtherPlayers(player), CardMoveReason(), "@dev_cangdao-give", true);
            if (!yiji_move.to || yiji_move.card_ids.isEmpty()) break;

            foreach (int id, yiji_move.card_ids) {
                equips.removeOne(id);
                move.card_ids.removeOne(id);
                data = QVariant::fromValue(move);
            }

            ServerPlayer *to = (ServerPlayer *)yiji_move.to;
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->deleteLater();
            slash->setSkillName("_dev_cangdao");

            if (!player->canSlash(to, slash, false) ||!player->askForSkillInvoke(this, to)) return false;
            room->useCard(CardUseStruct(slash, player, to));
        }
        return false;
    }
};

class DevPianxian : public TriggerSkill
{
public:
    DevPianxian() : TriggerSkill("dev_pianxian")
    {
        events << CardsMoveOneTime << GameStart;
        frequency = Compulsory;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == CardsMoveOneTime)
            return 3;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime) {
            if (room->getTag("FirstRound").toBool()) return false;
            if (player->getPhase() != Player::NotActive) return false;

            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            int mark = 0;
            if (move.to == player && move.to_place == Player::PlaceHand)
                mark += move.card_ids.length();
            else if (move.from == player) {
                if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)) return false;
                for (int i = 0; i < move.card_ids.length(); i++) {
                    if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)
                        mark++;
                }
            }
            if (mark <= 0) return false;
            room->sendCompulsoryTriggerLog(player, this);
            player->gainMark("&dev_die", mark);
        } else {
            room->sendCompulsoryTriggerLog(player, this);
            player->gainMark("&dev_die", 3);
        }
        return false;
    }
};

class DevQuanneng : public TriggerSkill
{
public:
    DevQuanneng() : TriggerSkill("dev_quanneng")
    {
        events << CardsMoveOneTime << CardUsed << Dying << HpRecover << Damage;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("&dev_die") <= 0) return false;
        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && move.from_places.contains(Player::PlaceEquip)) {
                for (int i = 0; i < move.card_ids.size(); i++) {
                    if (!player->isAlive() || player->getMark("&dev_die") <= 0)
                        return false;
                    if (move.from_places[i] == Player::PlaceEquip) {
                        if (player->askForSkillInvoke(objectName(), "xiaoji")) {
                            room->broadcastSkillInvoke("xiaoji");
                            player->loseMark("&dev_die");
                            player->drawCards(2, objectName());
                        } else {
                            break;
                        }
                    }
                }
            }
        } else if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("TrickCard")) return false;
            if (player->askForSkillInvoke(this, "tenyearjizhi")) {
                room->broadcastSkillInvoke("tenyearjizhi");
                player->loseMark("&dev_die");
                QList<int> list = player->drawCardsList(1, objectName());
                int id = list.first();
                const Card *card = Sanguosha->getCard(id);
                if (room->getCardOwner(id) != player || room->getCardPlace(id) != Player::PlaceHand) return false;
                if (!card->isKindOf("BasicCard") || !player->canDiscard(player, id)) return false;
                room->fillAG(list, player);
                player->tag["tenyearjizhi_id"] = id;
                bool invoke = room->askForSkillInvoke(player, "tenyearjizhi_discard", "discard", false);
                player->tag.remove("tenyearjizhi_id");
                room->clearAG(player);
                if (!invoke) return false;
                room->throwCard(card, player, NULL);
                room->addMaxCards(player, 1);
            }
        } else if (event == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who->isKongcheng()) return false;
            if (dying.who->getHp() < 1 && player->askForSkillInvoke("dev_quanneng_buyi", dying.who)) {

                LogMessage log;
                log.from = player;
                log.arg = objectName();
                log.type = "#InvokeSkill";
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke("buyi");
                player->loseMark("&dev_die");

                const Card *card = NULL;
                if (player == dying.who)
                    card = room->askForCardShow(dying.who, player, "buyi");
                else {
                    int card_id = room->askForCardChosen(player, dying.who, "h", "buyi");
                    card = Sanguosha->getCard(card_id);
                }

                room->showCard(dying.who, card->getEffectiveId());

                if (card->getTypeId() != Card::TypeBasic) {
                    if (!dying.who->isJilei(card))
                        room->throwCard(card, dying.who);

                    room->recover(dying.who, RecoverStruct(player));
                }
            }
        } else if (event == HpRecover) {
            RecoverStruct recover_struct = data.value<RecoverStruct>();
            int recover = recover_struct.recover;
            for (int i = 0; i < recover; i++) {
                if (player->getMark("&dev_die") <= 0) break;
                ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), "shushen", "shushen-invoke", true, false);
                if (target) {
                    LogMessage log;
                    log.from = player;
                    log.arg = objectName();
                    log.type = "#ChoosePlayerWithSkill";
                    log.to << target;
                    room->sendLog(log);
                    room->notifySkillInvoked(player, objectName());
                    room->doAnimate(1, player->objectName(), target->objectName());
                    room->broadcastSkillInvoke("shushen", target->getGeneralName().contains("liubei") ? 2 : 1);
                    player->loseMark("&dev_die");
                    if (target->isWounded() && room->askForChoice(player, "shushen", "recover+draw", QVariant::fromValue(target)) == "recover")
                        room->recover(target, RecoverStruct(player));
                    else
                        target->drawCards(2, "shushen");
                } else {
                    break;
                }
            }
        } else if (event == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            ServerPlayer *target = damage.to;
            if (target->isDead()) return false;
            if (damage.card && damage.card->isKindOf("Slash") && player->canPindian(target) && !target->hasFlag("Global_DebutFlag") && !damage.chain && !damage.transfer
                && player->askForSkillInvoke("dev_quanneng_lieren", target)) {

                LogMessage log;
                log.from = player;
                log.arg = objectName();
                log.type = "#InvokeSkill";
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke("lieren", 1);
                player->loseMark("&dev_die");

                bool success = player->pindian(target, "lieren", NULL);
                if (!success) {
                    room->broadcastSkillInvoke("lieren", 3);
                    return false;
                }
                room->broadcastSkillInvoke("lieren", 2);

                if (!target->isNude()) {
                    int card_id = room->askForCardChosen(player, target, "he", "lieren");
                    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                    room->obtainCard(player, Sanguosha->getCard(card_id), reason, room->getCardPlace(card_id) != Player::PlaceHand);
                }
            }
        }
        return false;
    }
};

DevPofengCard::DevPofengCard()
{
    m_skillName = "dev_pofeng";
    target_fixed = true;
}

void DevPofengCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->drawCards(1, "dev_pofeng");
    int source_num = -1;
    if (source->canDiscard(source, "he")) {
        const Card *card = room->askForDiscard(source, "dev_pofeng", 1, 1, false, true);
        source_num = card->getNumber();
    }

    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (p->isDead()) continue;
        p->drawCards(1, "dev_pofeng");
        if (p->canDiscard(p, "he")) {
            p->tag["dev_pofeng_num"] = source_num;
            const Card *card = room->askForDiscard(p, "dev_pofeng", 1, 1, false, true, "@PofengAsk:" + QString::number(source_num));
            p->tag.remove("dev_pofeng_num");
            if (source_num < 0) continue;

            int p_num = card->getNumber();
            if (p_num > source_num)
                room->recover(p, RecoverStruct(source->isAlive() ? source : NULL));
            else if (p_num < source_num)
                room->loseHp(p);
            room->getThread()->delay();
        } else
            room->getThread()->delay();
    }
}

class DevPofeng : public ZeroCardViewAsSkill
{
public:
    DevPofeng() : ZeroCardViewAsSkill("dev_pofeng")
    {
    }

    const Card *viewAs() const
    {
        return new DevPofengCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DevPofengCard");
    }
};

DevXiaohunCard::DevXiaohunCard()
{
    m_skillName = "dev_xiaohun";
    target_fixed = true;
}

void DevXiaohunCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->doSuperLightbox("dev_dudu", "dev_xiaohun");
    room->removePlayerMark(source, "@dev_xiaohunMark");

    QList<int> hands = source->handCards();

    bool flag = false;
    QHash<ServerPlayer *, int> hash;
    QList<ServerPlayer *> targets = room->getOtherPlayers(source);
    foreach (ServerPlayer *p, targets)  //for AI
        room->setPlayerFlag(p, "dev_xiaohun");

    while (!hands.isEmpty()) {
        if (source->isDead() || targets.isEmpty()) break;

        CardsMoveStruct move = room->askForYijiStruct(source, hands, "dev_xiaohun", false, true, flag, 1, targets, CardMoveReason(),
                               "@dev_xiaohun-give", false, false);
        flag = true;
        if (!move.to || move.card_ids.isEmpty()) break;

        hands.removeOne(move.card_ids.first());
        ServerPlayer *to = (ServerPlayer *)move.to;
        targets.removeOne(to);
        room->setPlayerFlag(to, "-dev_xiaohun");

        hash[to] = move.card_ids.first() + 1;
    }

    foreach (ServerPlayer *p, room->getOtherPlayers(source))
        room->setPlayerFlag(p, "-dev_xiaohun");

    if (source->isDead()) return;
    QList<CardsMoveStruct> moves;
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (p->isDead()) continue;
        int id = hash[p] - 1;
        if (id < 0) continue;
        CardsMoveStruct move(id, source, p, Player::PlaceHand, Player::PlaceHand,
            CardMoveReason(CardMoveReason::S_REASON_GIVE, source->objectName(), p->objectName(), "dev_xiaohun", QString()));
        moves.append(move);
    }
    if (moves.isEmpty()) return;
    room->moveCardsAtomic(moves, true);

    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (p->isDead()) continue;
        int id = hash[p] - 1;
        if (id < 0) continue;
        int num = Sanguosha->getCard(id)->getNumber(), hp = p->getHp();
        if (hp == 0) continue;

        if (num % hp != 0)
            p->drawCards(2, "dev_xiaohun");
        else {
            if (source->isDead()) continue;
            int ad = Config.AIDelay;
            Config.AIDelay = 0;

            QList<Player::Place> orig_places;
            QList<int> cards;
            p->setFlags("dev_xiaohun_InTempMoving");

            for (int i = 0; i < 2; ++i) {
                if (!source->canDiscard(p, "he")) break;
                int id = room->askForCardChosen(source, p, "he", "dev_xiaohun", false, Card::MethodDiscard);
                Player::Place place = room->getCardPlace(id);
                orig_places << place;
                cards << id;
                p->addToPile("#dev_xiaohun", id, false);
            }

            p->setFlags("-dev_xiaohun_InTempMoving");
            Config.AIDelay = ad;

            if (!cards.isEmpty()) {
                for (int i = 0; i < orig_places.length(); ++i)
                    room->moveCardTo(Sanguosha->getCard(cards.value(i)), p, orig_places.value(i), false);

                DummyCard dummy(cards);
                room->throwCard(&dummy, p, source);
            }

            if (p->isDead()) continue;
            room->damage(DamageStruct("dev_xiaohun", source->isAlive() ? source : NULL, p, 1, DamageStruct::Fire));
        }
    }
}

class DevXiaohun : public ZeroCardViewAsSkill
{
public:
    DevXiaohun() : ZeroCardViewAsSkill("dev_xiaohun")
    {
        frequency = Limited;
        limit_mark = "@dev_xiaohunMark";
    }

    const Card *viewAs() const
    {
        return new DevXiaohunCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@dev_xiaohunMark") > 0 && !player->isKongcheng();
    }
};

class DevSaiche : public PhaseChangeSkill
{
public:
    DevSaiche() : PhaseChangeSkill("dev_saiche")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::RoundStart;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this) || p->isKongcheng()) continue;
            const Card *card = room->askForCard(p, ".|.|.|hand", "@dev_saiche-give:" + player->objectName(), QVariant::fromValue(player),
                                                Card::MethodNone, NULL, false, objectName());
            if (!card) continue;

            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = p;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(p, objectName());
            room->broadcastSkillInvoke(objectName());

            room->giveCard(p, player, card, objectName());
            room->setPlayerMark(player, "dev_saiche-Clear", 1);
        }
        return false;
    }
};

class DevSaichePro : public ProhibitSkill
{
public:
    DevSaichePro() : ProhibitSkill("#dev_saiche")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from->getMark("dev_saiche-Clear") > 0 && !card->isKindOf("SkillCard") && from->distanceTo(to) > 1;
    }
};

class DevZhuaji : public PhaseChangeSkill
{
public:
    DevZhuaji() : PhaseChangeSkill("dev_zhuaji")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, this);

        int mark = player->getMark("dev_zhuaji_use-Clear");
        QString skill;
        if (mark < 1)
            skill = "dev_110";
        else if (mark == 1)
            skill = "dev_119";
        else if (mark > 1)
            skill = "dev_110";
        if (skill.isEmpty()) return false;
        room->acquireNextTurnSkills(player, "dev_zhuaji", skill);
        return false;
    }
};

class DevZhuajiMark : public TriggerSkill
{
public:
    DevZhuajiMark() : TriggerSkill("#dev_zhuaji-mark")
    {
        frequency = Compulsory;
        global = true;
        events << PreCardUsed << PreCardResponded;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            if (data.value<CardUseStruct>().card->isKindOf("SkillCard"))
                return false;
        } else {
            CardResponseStruct res = data.value<CardResponseStruct>();
            if (!res.m_isUse || res.m_card->isKindOf("SkillCard"))
                return false;
        }
        if (player->isDead() || player->getPhase() != Player::Play)
            return false;
        room->addPlayerMark(player, "dev_zhuaji_use-Clear");
        return false;
    }
};

class Dev110 : public TriggerSkill
{
public:
    Dev110() : TriggerSkill("dev_110")
    {
        frequency = Compulsory;
        global = true;
        events << EventPhaseStart << DamageInflicted;
    }

    int getPriority(TriggerEvent event) const
    {
        if (event == EventPhaseStart)
            return 5;
        return 4;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart || player->isDead()) return false;
            room->setPlayerMark(player, "dev_110_first_time", 0);
            room->setPlayerMark(player, "dev_119_first_time", 0);
        } else {
            if (player->getMark("dev_110_first_time") > 0 || player->isDead() || !player->hasSkill(this) ||
                    player->getPhase() != Player::NotActive) return false;
            room->addPlayerMark(player, "dev_110_first_time");

            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.from || damage.from->isDead()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            damage.from->turnOver();
        }
        return false;
    }
};

class Dev119 : public TriggerSkill
{
public:
    Dev119() : TriggerSkill("dev_119")
    {
        frequency = Compulsory;
        global = true;
        events << DamageInflicted;
    }

    int getPriority(TriggerEvent) const
    {
        return 5;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (!player->hasSkill(this) || player->getPhase() != Player::NotActive) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.nature == DamageStruct::Normal) return false;
        if (player->getMark("dev_119_first_time") > 0 || player->isDead()) return false;
        room->addPlayerMark(player, "dev_119_first_time");

        LogMessage log;
        log.type = "#YinshiPrevent";
        log.from = player;
        log.arg = objectName();
        log.arg2 = QString::number(damage.damage);
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);

        return true;
    }
};

class Dev120 : public TriggerSkill
{
public:
    Dev120() : TriggerSkill("dev_120")
    {
        frequency = Compulsory;
        events << EventPhaseChanging;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
        if (!player->faceUp() || player->isChained() || player->getLostHp() > 0) {
            room->sendCompulsoryTriggerLog(player, this);
            if (!player->faceUp())
                player->turnOver();
            if (player->isChained())
                room->setPlayerChained(player);
            room->recover(player, RecoverStruct(player));
        }
        return false;
    }
};

class DevJiayao : public TriggerSkill
{
public:
    DevJiayao() : TriggerSkill("dev_jiayao")
    {
        frequency = Compulsory;
        events << Damage;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to == player || damage.to->isDead()) return false;
        room->sendCompulsoryTriggerLog(player, this);
        if (damage.to->canDiscard(damage.to, "h") && room->askForDiscard(damage.to, objectName(), 1, 1, true, false, "@dev_jiayao-discard"))
            return false;
        room->addPlayerMark(damage.to, "&dev_jiayao");
        return false;
    }
};

class DevJiayaoEffect : public DrawCardsSkill
{
public:
    DevJiayaoEffect() : DrawCardsSkill("#dev_jiayao")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&dev_jiayao") > 0;
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        int mark = player->getMark("&dev_jiayao");

        LogMessage log;
        log.type = "#ZhenguEffect";
        log.from = player;
        log.arg = "dev_jiayao";
        room->sendLog(log);

        room->setPlayerMark(player, "&dev_jiayao", 0);

        return n - mark;
    }
};

class DevShangyin : public TriggerSkill
{
public:
    DevShangyin() : TriggerSkill("dev_shangyin")
    {
        events << Dying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@dev_shangyin-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(this);
        target->drawCards(1, objectName());
        room->addSlashCishu(player, 1);
        return false;
    }
};

class DevXiancheng : public PhaseChangeSkill
{
public:
    DevXiancheng() : PhaseChangeSkill("dev_xiancheng")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        QList<int> slashs;
        Room *room = player->getRoom();
        foreach (int id, room->getDiscardPile()) {
            if (Sanguosha->getCard(id)->isKindOf("Slash"))
                slashs << id;
        }
        if (slashs.isEmpty()) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(this);
        if (slashs.length() == 1)
            room->obtainCard(player, slashs.first());
        else {
            room->fillAG(slashs, player);
            int id = room->askForAG(player, slashs, false, objectName());
            room->clearAG(player);
            room->obtainCard(player, id);
        }
        return false;
    }
};

DevChengzhiCard::DevChengzhiCard()
{
    target_fixed = true;
    m_skillName = "dev_chengzhi";
    will_throw = false;
    handling_method = Card::MethodNone;
}

void DevChengzhiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    CardsMoveStruct move(subcards, NULL, Player::DrawPile,
                         CardMoveReason(CardMoveReason::S_REASON_PUT, source->objectName(), "dev_chengzhi", QString()));
    room->moveCardsAtomic(move, true);
    ServerPlayer *dying = room->getCurrentDyingPlayer();
    if (!dying || dying->getHp() >= 1) return;
    room->recover(dying, RecoverStruct(source->isAlive() ? source : NULL, NULL, 1 - dying->getHp()));
}

class DevChengzhi : public OneCardViewAsSkill
{
public:
    DevChengzhi() : OneCardViewAsSkill("dev_chengzhi")
    {
        filter_pattern = "Slash";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.contains("peach");
    }

    const Card *viewAs(const Card *card) const
    {
        DevChengzhiCard *c = new DevChengzhiCard;
        c->addSubcard(card);
        return c;
    }
};

DevBanchengCard::DevBanchengCard()
{
    m_skillName = "dev_bancheng";
}

void DevBanchengCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    QList<int> cards = room->showDrawPile(effect.from, 2 + effect.from->getLostHp(), "dev_bancheng");
    int slash = 0;
    foreach (int id, cards) {
        if (Sanguosha->getCard(id)->isKindOf("Slash"))
            slash++;
    }
    if (slash > 0 && effect.to->isAlive())
        room->damage(DamageStruct("dev_bancheng", effect.from->isAlive() ? effect.from : NULL, effect.to, slash));
    if (effect.to->isAlive()) {
        room->fillAG(cards, effect.to);
        int id = room->askForAG(effect.to, cards, false, "dev_bancheng");
        cards.removeOne(id);
        room->clearAG(effect.to);
        room->obtainCard(effect.to, id);
    }
    if (!cards.isEmpty()) {
        DummyCard dummy(cards);
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, effect.from->objectName(), "dev_bancheng", QString());
        room->throwCard(&dummy, reason, NULL);
    }
}

class DevBanchengVS : public ZeroCardViewAsSkill
{
public:
    DevBanchengVS() : ZeroCardViewAsSkill("dev_bancheng")
    {
        response_pattern = "@@dev_bancheng";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DevBanchengCard");
    }

    const Card *viewAs() const
    {
        return new DevBanchengCard;
    }
};

class DevBancheng : public MasochismSkill
{
public:
    DevBancheng() : MasochismSkill("dev_bancheng")
    {
        view_as_skill = new DevBanchengVS;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        Room *room = player->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            if (player->isDead()) return;
            if (!room->askForUseCard(player, "@@dev_bancheng", "@dev_bancheng", -1, Card::MethodUse, false)) break;
        }
    }
};

class DevShuguang : public TriggerSkill
{
public:
    DevShuguang() : TriggerSkill("dev_shuguang")
    {
        events << Dying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *who = data.value<DyingStruct>().who;
        if (!who) return false;

        QStringList developers = ChallengeDeveloperRule::getDevelopers();
        QString name = who->getGeneralName();
        if (!developers.contains(name)) {
            if (who->getGeneral2()) {
                name = who->getGeneral2Name();
                if (!developers.contains(name)) return false;
            } else
                return false;
        }

        if (player->getMaxHp() < room->alivePlayerCount()) return false;
        if (!player->askForSkillInvoke(this, who)) return false;
        room->broadcastSkillInvoke(this);

        room->loseMaxHp(player);
        room->recover(who, RecoverStruct(player->isAlive() ? player : NULL, NULL, who->getMaxHp() - who->getHp()));
        return false;
    }
};

class DevBaoji : public TriggerSkill
{
public:
    DevBaoji() : TriggerSkill("dev_baoji")
    {
        events << DamageCaused;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int num = qrand() % 4;
        if (num == 0) return false;
        room->sendCompulsoryTriggerLog(player, this);
        DamageStruct damage = data.value<DamageStruct>();
        ++damage.damage;
        data = QVariant::fromValue(damage);
        return false;
    }
};

class DevShanbi : public TriggerSkill
{
public:
    DevShanbi() : TriggerSkill("dev_shanbi")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        int num = qrand() % 4;
        if (num == 0) return false;
        DamageStruct damage = data.value<DamageStruct>();

        LogMessage log;
        log.type = "#YinshiPrevent";
        log.from = player;
        log.arg = objectName();
        log.arg2 = QString::number(damage.damage);
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);

        return true;
    }
};

DevNiniCard::DevNiniCard()
{
    m_skillName = "dev_nini";
}

bool DevNiniCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindian(to_select);
}

void DevNiniCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.from->canPindian(effect.to, false)) return;
    Room *room = effect.from->getRoom();
    int id = room->drawCard();

    PindianStruct *pindian = effect.from->PinDian(effect.to, "dev_nini", Sanguosha->getCard(id));
    if (!pindian->success || effect.from->isDead()) return;

    id = pindian->from_card->getEffectiveId();
    if (room->getCardPlace(id) == Player::DiscardPile)
        room->obtainCard(effect.from, Sanguosha->getCard(id));
    room->addAttackRange(effect.from, 1);
}

class DevNini : public ZeroCardViewAsSkill
{
public:
    DevNini() : ZeroCardViewAsSkill("dev_nini")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DevNiniCard") && player->canPindian();
    }

    const Card *viewAs() const
    {
        return new DevNiniCard;
    }
};

class DevDanteng : public TriggerSkill
{
public:
    DevDanteng() : TriggerSkill("dev_danteng")
    {
        events << Damage;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPhase() == Player::Play;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this) || !p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);
            p->drawCards(1, objectName());

            if (p != player && !player->isWounded())
                player->endPlayPhase();
        }
        return true;
    }
};

DevGengxinCard::DevGengxinCard()
{
    m_skillName = "dev_gengxin";
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool DevGengxinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (subcards.isEmpty()) {
        return targets.isEmpty() && to_select->getWeapon() && Self->canDiscard(to_select, to_select->getEquip(0)->getEffectiveId());
    } else {
        return targets.isEmpty() && !to_select->getWeapon() && to_select->hasWeaponArea();
    }
    return false;
}

void DevGengxinCard::onEffect(const CardEffectStruct &effect) const
{
    time_t t;
    int tt = time(&t);
    effect.from->tag["DevGengxinTime"] = tt;

    Room *room = effect.from->getRoom();

    if (subcards.isEmpty()) {
        if (!effect.to->getWeapon() || !effect.from->canDiscard(effect.to, effect.to->getEquip(0)->getEffectiveId())) return;
        const Card *card = Sanguosha->getCard(effect.to->getEquip(0)->getEffectiveId());
        room->throwCard(card, effect.to, effect.from);
        if (effect.from->isDead()) return;
        const Weapon *weapon = qobject_cast<const Weapon *>(card->getRealCard());
        int range = weapon->getRange();
        effect.from->gainHujia(range);
    } else {
        if (effect.to->getWeapon()) return;

        LogMessage log;
        log.type = "$ZhijianEquip";
        log.from = effect.to;
        log.card_str = QString::number(getEffectiveId());
        room->sendLog(log);

        effect.to->broadcastSkillInvoke(Sanguosha->getCard(getEffectiveId()));
        room->moveCardTo(this, effect.from, effect.to, Player::PlaceEquip,
            CardMoveReason(CardMoveReason::S_REASON_PUT,
            effect.from->objectName(), "dev_gengxin", QString()));

        if (effect.from->isDead()) return;
        const Weapon *weapon = qobject_cast<const Weapon *>(Sanguosha->getCard(getEffectiveId())->getRealCard());
        int range = weapon->getRange();
        effect.from->gainHujia(range);
    }
}

class DevGengxinVS : public ViewAsSkill
{
public:
    DevGengxinVS() : ViewAsSkill("dev_gengxin")
    {
        response_pattern = "@@dev_gengxin";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.isEmpty() && to_select->isKindOf("Weapon");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() > 1) return NULL;
        DevGengxinCard *c = new DevGengxinCard;
        if (!cards.isEmpty())
            c->addSubcards(cards);
        return c;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }
};

class DevGengxin : public PhaseChangeSkill
{
public:
    DevGengxin() : PhaseChangeSkill("dev_gengxin")
    {
        view_as_skill = new DevGengxinVS;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();

        time_t t;
        int tt = time(&t);
        int old_t = player->tag["DevGengxinTime"].toInt();
        if (old_t == 0 || tt - old_t >= 90)
            room->askForUseCard(player, "@@dev_gengxin", "@dev_gengxin");
        else {
            LogMessage log;
            log.type = "#DevGengxinCD";
            log.from = player;
            log.arg = objectName();
            log.arg2 = QString::number(90 - tt + old_t);
            room->sendLog(log);
        }
        return false;
    }
};

class DevXueba : public TriggerSkill
{
public:
    DevXueba() : TriggerSkill("dev_xueba")
    {
        events << Dying;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *who = data.value<DyingStruct>().who;
        if (player->getMark("dev_xueba_used_" + who->objectName()) > 0) return false;
        Peach *peach = new Peach(Card::NoSuit, 0);
        peach->deleteLater();
        if (player->isCardLimited(peach, Card::MethodUse) || player->isProhibited(who, peach)) return false;

        const Card *used_peach = NULL;
        foreach (int id, room->getDrawPile()) {
            const Card *card = Sanguosha->getCard(id);
            if (card->isKindOf("Peach")) {
                used_peach = card;
                break;
            }
        }

        if (!used_peach || !player->askForSkillInvoke(this, who)) return false;
        room->broadcastSkillInvoke(this);
        room->addPlayerMark(player, "dev_xueba_used_" + who->objectName());
        room->useCard(CardUseStruct(used_peach, player, who), true);
        if (player->isAlive()) {
            QStringList skills = ChallengeDeveloperRule::getSkills(player, "god", true, true, true);
            if (skills.isEmpty()) return false;
            QString skill = room->askForChoice(player, objectName(), skills.join("+"));
            room->acquireSkill(player, skill);
        }
        return false;
    }
};

class DevMeihuo : public TriggerSkill
{
public:
    DevMeihuo() : TriggerSkill("dev_meihuo")
    {
        events << TargetConfirmed << SlashHit;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.to.contains(player) || !use.card->isKindOf("Slash") || (use.card->isVirtualCard() && use.card->subcardString() == 0))
                return false;
            if (!player->askForSkillInvoke(this, data)) return false;
            room->broadcastSkillInvoke(this);

            QList<int> ids;
            if (use.card->isVirtualCard())
                ids = use.card->getSubcards();
            else
                ids << use.card->getEffectiveId();

            LogMessage log;
            log.type = "$DevMeihuoRecast";
            log.from = player;
            log.card_str = IntList2StringList(ids).join("+");
            room->sendLog(log);

            CardMoveReason reason(CardMoveReason::S_REASON_RECAST, player->objectName());
            reason.m_skillName = objectName();
            CardsMoveStruct move(ids, NULL, Player::DiscardPile, reason);
            room->moveCardsAtomic(move, true);
            player->broadcastSkillInvoke("@recast");

            int draw = player->drawCardsList(1, "recast").first();
            if (!player->handCards().contains(draw)) return false;
            room->showCard(player, draw);

            if (Sanguosha->getCard(draw)->isKindOf("BasicCard")) {
                use.nullified_list << player->objectName();
                data = QVariant::fromValue(use);
            }
        } else {
            SlashEffectStruct slash = data.value<SlashEffectStruct>();
            if (slash.to->isDead() || slash.to->isKongcheng()) return false;
            if (!player->askForSkillInvoke(this, slash.to)) return false;
            room->broadcastSkillInvoke(this);

            int id = room->askForCardChosen(player, slash.to, "h", objectName(), false, Card::MethodRecast);

            LogMessage log;
            log.type = "$DevMeihuoRecastOther";
            log.from = player;
            log.to << slash.to;
            log.card_str = QString::number(id);
            room->sendLog(log);

            CardMoveReason reason(CardMoveReason::S_REASON_RECAST, player->objectName());
            reason.m_skillName = objectName();
            CardsMoveStruct move(id, NULL, Player::DiscardPile, reason);
            room->moveCardsAtomic(move, true);
            player->broadcastSkillInvoke("@recast");
            player->drawCards(1, "recast");
        }
        return false;
    }
};

class DevNvshen : public TriggerSkill
{
public:
    DevNvshen() : TriggerSkill("dev_nvshen")
    {
        events << ConfirmDamage << Damaged;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == ConfirmDamage)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (event == ConfirmDamage) {
            if (damage.to->getHujia() > 0 && !damage.ignore_hujia) {
                LogMessage log;
                log.type = "#DevNvshenIgnore";
                log.from = player;
                log.to << damage.to;
                log.arg = objectName();
                log.arg2 = QString::number(damage.to->getHujia());
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(this);
            }
            damage.ignore_hujia = true;
            data = QVariant::fromValue(damage);
        } else {
            for (int i = 0; i < damage.damage; i++) {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->getHp() > 1)
                        targets << p;
                }
                if (targets.isEmpty()) break;

                ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@dev_nvshen-invoke", true, true);
                if (!target) break;
                room->broadcastSkillInvoke(this);

                target->setHp(target->getHp() - 1);
                room->broadcastProperty(target, "hp");
                //target->gainHujia();
                room->addPlayerMark(target, "@HuJia");
            }
        }
        return false;
    }
};

class DevGepi : public PhaseChangeSkill
{
public:
    DevGepi() : PhaseChangeSkill("dev_gepi")
    {
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
            if (p->isDead() || !p->hasSkill(this) || !player->canDiscard(p, "he")) continue;
            if (!p->askForSkillInvoke(this, player)) continue;
            room->broadcastSkillInvoke(this);

            int id = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, p, player);

            if (player->isDead()) return false;
            QStringList skills;
            foreach (const Skill *sk, player->getVisibleSkillList()) {
                if (sk->isAttachedLordSkill() || sk->inherits("SPConvertSkill") || sk->isLordSkill() ||
                        sk->getFrequency() == Skill::Wake || skills.contains(sk->objectName())) continue;
                skills << sk->objectName();
            }

            if (skills.isEmpty())
                player->drawCards(3, objectName());
            else {
                QString skill_name = room->askForChoice(p, objectName(), skills.join("+"), QVariant::fromValue(player));
                room->addPlayerMark(player, "&dev_gepi+:+" + skill_name + "-Keep");

                foreach (ServerPlayer *p, room->getAllPlayers())
                    room->filterCards(p, p->getCards("he"), true);

                JsonArray args;
                args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
                room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

                const Skill *skill = Sanguosha->getSkill(skill_name);
                if (!skill) continue;
                if (!skill->getDescription().contains("出牌阶段"))
                    player->drawCards(3, objectName());
            }
        }
        return false;
    }
};

class DevGepiClear : public TriggerSkill
{
public:
    DevGepiClear() : TriggerSkill("#dev_gepi-clear")
    {
        events << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;

        bool gepi = false;
        foreach (QString mark, player->getMarkNames()) {
            if (!mark.startsWith("&dev_gepi+:+") || player->getMark(mark) <= 0) continue;
            gepi = true;
            room->setPlayerMark(player, mark, 0);
        }
        if (gepi) {
            foreach (ServerPlayer *p, room->getAllPlayers())
                room->filterCards(p, p->getCards("he"), false);

            JsonArray args;
            args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
        }
        return false;
    }
};

class DevGepiInv : public InvaliditySkill
{
public:
    DevGepiInv() : InvaliditySkill("#dev_gepi-inv")
    {
    }

    bool isSkillValid(const Player *player, const Skill *skill) const
    {
        return player->getMark("&dev_gepi+:+" + skill->objectName() + "-Keep") == 0;
    }
};

class DevChaidao : public TriggerSkill
{
public:
    DevChaidao() : TriggerSkill("dev_chaidao")
    {
        events << DamageCaused << DamageInflicted;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!player->getWeapon()) return false;

        if (event == DamageCaused) {
            if (!player->canDiscard(player, player->getEquip(0)->getEffectiveId()) || damage.to->isDead()) return false;
            if (!player->askForSkillInvoke(this, QString("DamageCaused:%1").arg(damage.to->objectName()))) return false;
            room->broadcastSkillInvoke(this);
            room->throwCard(player->getEquip(0), player);
            ++damage.damage;
            data = QVariant::fromValue(damage);
        } else {
            if (!damage.from || damage.from == player) return false;
            if (!player->askForSkillInvoke(this, QString("DamageInflicted:%1").arg(damage.from->objectName()))) return false;
            room->broadcastSkillInvoke(this);

            Collateral *coll = new Collateral(Card::NoSuit, 0);
            coll->setSkillName("_dev_chaidao");
            coll->deleteLater();

            if (damage.from->isDead() || damage.from->isCardLimited(coll, Card::MethodUse) || damage.from->isProhibited(player, coll))
                return true;
            QList<ServerPlayer *> targets;
            targets << player << damage.from;
            room->useCard(CardUseStruct(coll, damage.from, targets));
            return true;
        }
        return false;
    }
};

class DevSaodong : public TriggerSkill
{
public:
    DevSaodong() : TriggerSkill("dev_saodong")
    {
        events << DamageInflicted;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("TrickCard")) return false;
        if (!damage.from || damage.from->isDead() || damage.from == player || player->isNude()) return false;

        player->tag["dev_saodong_damage"] = data;
        const Card *card = room->askForExchange(player, objectName(), 1, 1, true,
                    QString("@dev_saodong-diamond:%1::%2").arg(damage.from->objectName()).arg(damage.card->objectName()), true, ".|diamond");
        player->tag.remove("dev_saodong_damage");
        if (!card) return false;

        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(this);

        room->giveCard(player, damage.from, card, objectName(), true);
        delete card;

        if (damage.from->isDead()) return false;
        damage.to = damage.from;
        damage.transfer = true;
        damage.transfer_reason = "dev_saodong";
        player->tag["TransferDamage"] = QVariant::fromValue(damage);
        return true;
    }
};

class DevSaodongUse : public MasochismSkill
{
public:
    DevSaodongUse() : MasochismSkill("#dev_saodong-use")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        if (!damage.from) return;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p == damage.from || p->isDead() || !p->hasSkill("dev_saodong") || p->isNude()) continue;
            QStringList patterns, choices;

            foreach (const Card *c, p->getCards("he")) {
                if (c->getSuit() == Card::Heart) {
                    Peach *peach = new Peach(Card::SuitToBeDecided, -1);
                    peach->addSubcard(c);
                    peach->deleteLater();
                    peach->setSkillName("dev_saodong");
                    if (peach->isAvailable(p)) {
                        patterns << c->toString();
                        if (!choices.contains("peach"))
                            choices << "peach";
                        continue;
                    }

                    ExNihilo *ex_nihilo = new ExNihilo(Card::SuitToBeDecided, -1);
                    ex_nihilo->addSubcard(c);
                    ex_nihilo->deleteLater();
                    ex_nihilo->setSkillName("dev_saodong");
                    if (ex_nihilo->isAvailable(p)) {
                        patterns << c->toString();
                        if (!choices.contains("ex_nihilo"))
                            choices << "ex_nihilo";
                    }
                }
            }

            if (patterns.isEmpty() || choices.isEmpty()) continue;

            const Card *card = room->askForCard(p, patterns.join(","), "@dev_saodong", QVariant(), Card::MethodNone);
            if (!card) continue;

            QString choice = room->askForChoice(p, "dev_saodong", choices.join("+"));
            Card *c = Sanguosha->cloneCard(choice, Card::SuitToBeDecided, -1);
            c->addSubcard(card);
            c->deleteLater();
            c->setSkillName("dev_saodong");
            room->useCard(CardUseStruct(c, p, p));
        }
    }
};

class DevZhiyu : public DrawCardsSkill
{
public:
    DevZhiyu() : DrawCardsSkill("dev_zhiyu")
    {
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> woundeds;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isWounded())
                woundeds << p;
        }
        if (woundeds.isEmpty()) return n;
        ServerPlayer *wounded = room->askForPlayerChosen(player, woundeds, objectName(), "@dev_zhiyu-invoke", true, true);
        if (!wounded) return n;
        room->broadcastSkillInvoke(this);
        room->recover(wounded, RecoverStruct(player));
        if (wounded->isAlive() && player->isAlive()) {
            int lost = wounded->getLostHp();
            lost = qMin(lost, 2);
            player->drawCards(lost, objectName());
        }
        return 0;
    }
};

class DevPinghe : public TriggerSkill
{
public:
    DevPinghe() : TriggerSkill("dev_pinghe")
    {
        events << Damage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash") || !damage.by_user || damage.chain || damage.transfer || damage.to->isDead())
            return false;
        if (player->getKingdom() == damage.to->getKingdom() || !player->canDiscard(damage.to, "h")) return false;
        int id = room->askForCardChosen(player, damage.to, "h", objectName(), false, Card::MethodDiscard);
        room->throwCard(id, damage.to, player);
        if (player->isDead() || damage.to->isDead()) return false;

        if (damage.to->getHandcardNum() >= damage.to->getHp()) {
            if (player->getLostHp() > 0) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->recover(player, RecoverStruct(player));
            }
        } else {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->drawCards(1, objectName());
        }
        return false;
    }
};

class DevZhiyin : public DrawCardsSkill
{
public:
    DevZhiyin() : DrawCardsSkill("dev_zhiyin")
    {
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->canDiscard(p, "j"))
                targets << p;
        }
        if (targets.isEmpty()) return n;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@dev_zhiyin-invoke", true, true);
        if (!target) return n;
        room->broadcastSkillInvoke(this);

        int id = room->askForCardChosen(player, target, "j", objectName(), false, Card::MethodDiscard);
        room->throwCard(id, NULL, player);
        target->drawCards(1, objectName());

        return n - 1;
    }
};

class DevJiaodao : public TriggerSkill
{
public:
    DevJiaodao() : TriggerSkill("dev_jiaodao")
    {
        events << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isNDTrick() || use.to.isEmpty()) return false;
        if (use.card->isKindOf("Collateral") || use.card->isKindOf("AmazingGrace") || use.card->isKindOf("IronChain")) return false;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;

            p->tag["dev_jiaodao_data"] = data;
            bool invoke = p->askForSkillInvoke(this, QString("dev_jiaodao:%1::%2").arg(player->objectName()).arg(use.card->objectName()));
            p->tag.remove("dev_jiaodao_data");

            if (!invoke) continue;
            room->broadcastSkillInvoke(this);

            LogMessage log;
            log.type = "#DevJiaodaoEffect";
            log.from = player;
            log.arg = use.card->objectName();
            room->sendLog(log);

            foreach (ServerPlayer *to, use.to) {
                if (to->isDead()) continue;
                CardEffectStruct effect;
                effect.from = player;
                effect.card = use.card;
                effect.to = to;
                effect.multiple = use.to.length() > 1;
                effect.nullified = use.nullified_list.contains(p->objectName());
                effect.no_respond = use.no_respond_list.contains(p->objectName());
                effect.no_offset = use.no_offset_list.contains(p->objectName());
                room->cardEffect(effect);
            }
        }
        return false;
    }
};

DevMeigongCard::DevMeigongCard()
{
    m_skillName = "dev_meigong";
}

void DevMeigongCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    foreach (const Skill *skill, effect.to->getVisibleSkillList()) {
        if (!skill->isLimitedSkill() || skill->getLimitMark().isEmpty()) continue;
        room->addPlayerMark(effect.to, skill->getLimitMark());
    }
}

class DevMeigongVS : public ZeroCardViewAsSkill
{
public:
    DevMeigongVS() : ZeroCardViewAsSkill("dev_meigong")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DevMeigongCard");
    }

    const Card *viewAs() const
    {
        return new DevMeigongCard;
    }
};

class DevMeigong : public PhaseChangeSkill
{
public:
    DevMeigong() : PhaseChangeSkill("dev_meigong")
    {
        view_as_skill = new DevMeigongVS;
    }

    int getPriority(TriggerEvent) const
    {
        return 6;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getPhase() == Player::Finish && target->getMark("dev_meigong_twice-Clear") <= 0;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> players = room->findPlayersBySkillName(objectName());
        if (players.isEmpty()) return false;
        foreach (ServerPlayer *p, players)
            room->sendCompulsoryTriggerLog(p, this);

        room->addPlayerMark(player, "dev_meigong_twice-Clear");
        room->getThread()->trigger(EventPhaseStart, room, player);
        return false;
    }
};

class DevQiliao : public PhaseChangeSkill
{
public:
    DevQiliao() : PhaseChangeSkill("dev_qiliao")
    {
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        Room *room = player->getRoom();
        int hp = player->getHp();
        hp = qMin(1, hp);

        foreach (int id, room->getDiscardPile()) {
            const Card *card = Sanguosha->getCard(id);
            int number = card->getNumber();
            if (number % hp != 0) continue;

            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(),
                                    "@dev_qiliao-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(this);
            target->drawCards(1, objectName());
            if (target->isAlive() && player->isAlive() && target->isWounded() &&
                    player->askForSkillInvoke(this, QString("recover:%1").arg(target->objectName()), false)) {
                room->recover(target, RecoverStruct(player));
                room->addPlayerMark(player, "&dev_qiliao");
                return false;
            } else
                return false;
        }
        return false;
    }
};

class DevQiliaoEffect : public TriggerSkill
{
public:
    DevQiliaoEffect() : TriggerSkill("#dev_qiliao-effect")
    {
        events << PreHpRecover;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->getMark("&dev_qiliao") > 0;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        RecoverStruct recover = data.value<RecoverStruct>();
        LogMessage log;
        log.from = player;
        log.arg = "dev_qiliao";
        log.arg2 = QString::number(recover.recover);
        log.type = "#DevQiliaoEffect";
        room->sendLog(log);
        room->notifySkillInvoked(player, "dev_qiliao");
        room->broadcastSkillInvoke("dev_qiliao");
        room->removePlayerMark(player, "&dev_qiliao");
        return true;
    }
};

class DevXuexi : public TriggerSkill
{
public:
    DevXuexi() : TriggerSkill("dev_xuexi")
    {
        events << CardUsed << CardResponded << CardsMoveOneTime;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play) return false;

        if (event == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to == player && move.to_place == Player::PlaceHand && move.reason.m_skillName == objectName()) {
                foreach (int id, move.card_ids) {
                    QString type = Sanguosha->getCard(id)->getType();
                    room->addPlayerMark(player, "dev_xuexi_" + type + "-Clear");
                }
            }
        } else {
            const Card *use_card = NULL;
            if (event == CardUsed)
                use_card = data.value<CardUseStruct>().card;
            else {
                CardResponseStruct res = data.value<CardResponseStruct>();
                if (!res.m_isUse) return false;
                use_card = res.m_card;
            }

            if (!use_card || use_card->isKindOf("SkillCard")) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(this);

            QList<int> ids = room->showDrawPile(player, 1, objectName());
            int id = ids.first();
            QString type = Sanguosha->getCard(id)->getType();

            DummyCard *dummy = new DummyCard(ids);
            dummy->deleteLater();
            if (player->getMark("dev_xuexi_" + type + "-Clear") > 0) {
                CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "dev_xuexi", QString());
                room->throwCard(dummy, reason, NULL);
            } else {
                CardMoveReason reason(CardMoveReason::S_REASON_GOTBACK, player->objectName(), "dev_xuexi", QString());
                room->obtainCard(player, dummy, reason);
            }
        }
        return false;
    }
};

class DevYukuai : public TriggerSkill
{
public:
    DevYukuai() : TriggerSkill("dev_yukuai")
    {
        events << EventPhaseEnd;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Discard) return false;
        int basic = 1, trick = 1, equip = 1;
        foreach (const Card *c, player->getHandcards()) {
            if (c->isKindOf("BasicCard"))
                basic = 0;
            else if (c->isKindOf("TrickCard"))
                trick = 0;
            else if (c->isKindOf("EquipCard"))
                equip = 0;
        }

        int num = basic + trick + equip;
        num = qMax(num, 1);
        room->sendCompulsoryTriggerLog(player, this);
        player->drawCards(num, objectName());
        return false;
    }
};

class DevGeili : public TriggerSkill
{
public:
    DevGeili() : TriggerSkill("dev_geili")
    {
        events << HpRecover;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, this);
        player->gainMark("&dev_geili_zhitu");
        return false;
    }
};

class DevGeiliPhase : public TriggerSkill
{
public:
    DevGeiliPhase() : TriggerSkill("#dev_geili")
    {
        events << EventPhaseStart << StartHpRecover;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead() || !p->hasSkill("dev_geili") || p->getMark("&dev_geili_zhitu") <= 0) continue;
                if (!p->askForSkillInvoke("dev_geili", player)) continue;
                room->broadcastSkillInvoke(this);
                p->loseMark("&dev_geili_zhitu");
                room->addPlayerMark(player, "dev_geili_effect-Clear");
            }
        } else {
            if (player->getMark("dev_geili_effect-Clear") <= 0) return false;

            LogMessage log;
            log.type = "#DevGeiliEffect";
            log.from = player;
            log.arg = "dev_geili";
            room->sendLog(log);
            room->broadcastSkillInvoke(this);

            RecoverStruct recover = data.value<RecoverStruct>();
            room->damage(DamageStruct(recover.card, recover.who, player, recover.recover));
            return true;
        }
        return false;
    }
};

class DevJiangyou : public GameStartSkill
{
public:
    DevJiangyou() : GameStartSkill("dev_jiangyou")
    {
        frequency = Compulsory;
    }

    void onGameStart(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        //room->sendCompulsoryTriggerLog(player, this);
        LogMessage log;
        log.from = player;
        log.arg = "dev_jiangyou";
        log.type = "#DevJiangyouEnterXiumian";
        room->sendLog(log);
        room->notifySkillInvoked(player, "dev_jiangyou");
        room->broadcastSkillInvoke("dev_jiangyou");

        player->setAlive(false);

        QVariant new_data = "dev_jiangyou_sleep";
        room->getThread()->trigger(EventForDiy, room, player, new_data);
    }
};

class DevJiangyouXiumian : public TriggerSkill
{
public:
    DevJiangyouXiumian() : TriggerSkill("#dev_jiangyou-xiumian")
    {
        events << CardFinished;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (!data.value<CardUseStruct>().card->isKindOf("TrickCard")) return false;

        foreach (ServerPlayer *p, room->getAllPlayers(true)) {
            if (!p->hasSkill("dev_jiangyou") || !room->getAlivePlayers().contains(p)) continue;

            LogMessage log;
            log.from = p;
            log.arg = "dev_jiangyou";

            if (p->isDead()) {
                room->addPlayerMark(p, "&dev_jiangyou_exit_xiumian");
                if (p->getMark("&dev_jiangyou_exit_xiumian") >= 5) {
                    room->setPlayerMark(p, "&dev_jiangyou_exit_xiumian", 0);
                    p->setAlive(true);

                    log.type = "#DevJiangyouExitXiumian";
                    room->sendLog(log);
                    room->notifySkillInvoked(p, "dev_jiangyou");
                    room->broadcastSkillInvoke("dev_jiangyou");

                    QVariant new_data = "dev_jiangyou_awaken";
                    room->getThread()->trigger(EventForDiy, room, p, new_data);
                }
            } else {
                room->addPlayerMark(p, "&dev_jiangyou_enter_xiumian");
                if (p->getMark("&dev_jiangyou_enter_xiumian") >= 10) {
                    room->setPlayerMark(p, "&dev_jiangyou_enter_xiumian", 0);
                    p->setAlive(false);

                    log.type = "#DevJiangyouEnterXiumian";
                    room->sendLog(log);
                    room->notifySkillInvoked(p, "dev_jiangyou");
                    room->broadcastSkillInvoke("dev_jiangyou");

                    QVariant new_data = "dev_jiangyou_sleep";
                    room->getThread()->trigger(EventForDiy, room, p, new_data);
                }
            }
        }
        return false;
    }
};

class DevJiangyouDeath : public TriggerSkill
{
public:
    DevJiangyouDeath() : TriggerSkill("#dev_jiangyou-death")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *who = data.value<DeathStruct>().who;
        if (who != player) return false;
        QStringList developers = ChallengeDeveloperRule::getDevelopers();
        if (!developers.contains(who->getGeneralName()) && !developers.contains(who->getGeneral2Name())) return false;

        foreach (ServerPlayer *p, room->getAllPlayers(true)) {
            if (!room->getAlivePlayers().contains(p) || !p->hasSkill("dev_jiangyou")) continue;
            if (p->isDead()) {
                p->setAlive(true);

                LogMessage log;
                log.from = p;
                log.arg = "dev_jiangyou";
                log.type = "#DevJiangyouExitXiumian";
                room->sendLog(log);
                room->notifySkillInvoked(p, "dev_jiangyou");
                room->broadcastSkillInvoke("dev_jiangyou");

                QVariant new_data = "dev_jiangyou_awaken";
                room->getThread()->trigger(EventForDiy, room, p, new_data);
            } else
                room->sendCompulsoryTriggerLog(p, "dev_jiangyou", true, true);

            room->setPlayerMark(p, "&dev_jiangyou_exit_xiumian", 0);
            room->setPlayerMark(p, "&dev_jiangyou_enter_xiumian", 0);
            room->handleAcquireDetachSkills(p, "-dev_jiangyou");
        }
        return false;
    }
};

class DevHeti : public TriggerSkill
{
public:
    DevHeti() : TriggerSkill("dev_heti")
    {
        events << Death << EventForDiy;
        frequency = Compulsory;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == Death)
            return TriggerSkill::getPriority(triggerEvent) - 1;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventForDiy) {
            if (data.toString() != "dev_jiangyou_awaken") return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            room->addPlayerMark(player, "&dev_heti");
            room->addMaxCards(player, 1, false);
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isDead()) continue;
                if (p->getGeneralName() == "dev_funima" || p->getGeneral2Name() == "dev_funima") {
                    room->addPlayerMark(p, "&dev_heti");
                    room->addMaxCards(p, 1, false);
                }
            }
        } else {
            ServerPlayer *who = data.value<DeathStruct>().who;
            if (who == player || player->getGeneral2Name() == "dev_funima") return false;
            if (who->getGeneralName() == "dev_funima" || who->getGeneral2Name() == "dev_funima") {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                room->changeHero(player, "dev_funima", false, false, true);
            }
        }
        return false;
    }
};

class DevJuanlaoVS : public ZeroCardViewAsSkill
{
public:
    DevJuanlaoVS() : ZeroCardViewAsSkill("dev_juanlao")
    {
    }

    const Card *viewAs() const
    {
        QString name = Self->property("dev_juanlao_card").toString();
        if (name.isEmpty()) return NULL;
        Card *c = Sanguosha->cloneCard(name);
        if (!c) return NULL;
        c->setSkillName("dev_juanlao");
        if (!c->isAvailable(Self)) {
            delete c;
            return NULL;
        }
        return c;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        QString name = Self->property("dev_juanlao_card").toString();
        if (name.isEmpty()) return false;
        Card *c = Sanguosha->cloneCard(name);
        if (!c) return false;
        c->deleteLater();
        c->setSkillName("dev_juanlao");
        return c->isAvailable(player) && player->getMark("dev_juanlao-PlayClear") <= 0;
    }
};

class DevJuanlao : public TriggerSkill
{
public:
    DevJuanlao() : TriggerSkill("dev_juanlao")
    {
        events << CardFinished << EventAcquireSkill << EventLoseSkill << PreCardUsed << EventPhaseChanging;
        view_as_skill = new DevJuanlaoVS;
        global = true;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (player->getPhase() != Player::NotActive && use.card->isNDTrick()) {
                int n = player->tag["dev_yegeng_num"].toInt();
                player->tag["dev_yegeng_num"] = ++n;
                if (player->hasSkill("dev_yegeng", true))
                    room->addPlayerMark(player, "&dev_yegeng");
            }
            if (use.card->getSkillName() != objectName() || player->getPhase() != Player::Play) return false;
            room->addPlayerMark(player, "dev_juanlao-PlayClear");
        } else if (event == CardFinished) {
            if (player->getPhase() == Player::NotActive) return false;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isNDTrick() || use.card->isVirtualCard()) return false;
            QString name = use.card->objectName();
            room->setPlayerProperty(player, "dev_juanlao_card", name);
            if (player->hasSkill(this, true)) {
                foreach (QString mark, player->getMarkNames()) {
                    if (!mark.startsWith("&dev_juanlao+:+") || player->getMark(mark) <= 0) continue;
                    room->setPlayerMark(player, mark, 0);
                }
                room->addPlayerMark(player, "&dev_juanlao+:+" + name);
            }
        } else if (event == EventAcquireSkill) {
            if (data.toString() == objectName() && player->hasSkill(this, true)) {
                QString name = player->property("dev_juanlao_card").toString();
                if (!name.isEmpty()) {
                    foreach (QString mark, player->getMarkNames()) {
                        if (!mark.startsWith("&dev_juanlao+:+") || player->getMark(mark) <= 0) continue;
                        room->setPlayerMark(player, mark, 0);
                    }
                    room->addPlayerMark(player, "&dev_juanlao+:+" + name);
                }
            } else if (data.toString() == "dev_yegeng" && player->hasSkill("dev_yegeng", true)) {
                int n = player->tag["dev_yegeng_num"].toInt();
                room->setPlayerMark(player, "&dev_yegeng", n);
            }
        } else if (event == EventLoseSkill) {
            if (data.toString() != objectName() || player->hasSkill(this, true)) return false;
            foreach (QString mark, player->getMarkNames()) {
                if (!mark.startsWith("&dev_juanlao+:+") || player->getMark(mark) <= 0) continue;
                room->setPlayerMark(player, mark, 0);
            }
        } else if (event == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setPlayerProperty(player, "dev_juanlao_card", QString());
            foreach (QString mark, player->getMarkNames()) {
                if (!mark.startsWith("&dev_juanlao+:+") || player->getMark(mark) <= 0) continue;
                room->setPlayerMark(player, mark, 0);
            }
        }
        return false;
    }
};

class DevYegeng : public PhaseChangeSkill
{
public:
    DevYegeng() : PhaseChangeSkill("dev_yegeng")
    {
        frequency = Compulsory;
        global = true;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::NotActive) return false;
        Room *room = player->getRoom();
        room->setPlayerMark(player, "&dev_yegeng", 0);
        int n = player->tag["dev_yegeng_num"].toInt();
        player->tag["dev_yegeng_num"] = 0;
        if (player->hasSkill(this) && n >= 3) {
            room->sendCompulsoryTriggerLog(player, this);
            player->gainAnExtraTurn();
        }
        return false;
    }
};

class DevJiaoqi : public TriggerSkill
{
public:
    DevJiaoqi() : TriggerSkill("dev_jiaoqi")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();
        int i = -1;
        foreach (ServerPlayer *p, use.to) {
            i++;
            if (player->isDead()) return false;
            if (p->isDead()) continue;
            if ((player->getWeapon() || player->getArmor()) && player->canDiscard(p, "e")) {
                if (player->askForSkillInvoke(this, QString("discard:%1").arg(p->objectName()))) {
                    room->broadcastSkillInvoke(this);
                    int id = room->askForCardChosen(player, p, "e", objectName(), false, Card::MethodDiscard);
                    room->throwCard(id, p, player);
                }
            }
            if (player->isAlive() && (player->getOffensiveHorse() || player->getDefensiveHorse())) {
                if (!player->askForSkillInvoke(this, QString("jink:%1").arg(p->objectName()))) continue;
                room->broadcastSkillInvoke(this);

                LogMessage log;
                log.type = "#DevJiaoqiJink";
                log.from = p;
                room->sendLog(log);

                if (jink_list.at(i) == 1)
                    jink_list.replace(i, QVariant(2));
                player->tag["Jink_" + use.card->toString()] = QVariant::fromValue(jink_list);
            }
        }
        player->tag["Jink_" + use.card->toString()] = QVariant::fromValue(jink_list);
        return false;
    }
};

class DevAojiao : public TriggerSkill
{
public:
    DevAojiao() : TriggerSkill("dev_aojiao")
    {
        events << TargetConfirming << EventPhaseStart;
        frequency = Wake;
        waked_skills = "dev_jiaohua";
    }

    bool canWake(TriggerEvent triggerEvent, ServerPlayer *player, QVariant &data, Room *) const
    {
        if (player->getMark(objectName()) > 0) return false;
        if (triggerEvent == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isKindOf("Slash") || !use.to.contains(player))
                return false;
        } else if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::Start)
                return false;
        }
        if (player->canWake(objectName())) return true;
        if (player->isWounded() && !player->getEquips().isEmpty())
            return true;
        return false;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, this);
        room->setPlayerMark(player, objectName(), 1);
        room->doSuperLightbox("dev_jiaoshen", "dev_aojiao");
        if (room->changeMaxHpForAwakenSkill(player))
            room->handleAcquireDetachSkills(player, "dev_jiaohua");
        return false;
    }
};

class DevJiaohuaVS : public OneCardViewAsSkill
{
public:
    DevJiaohuaVS() : OneCardViewAsSkill("dev_jiaohua")
    {
        response_or_use = true;
        response_pattern = "@@dev_jiaohua";
    }

    bool viewFilter(const Card *to_select) const
    {
        QStringList suitstrings;
        foreach (const Card *c, Self->getEquips()) {
            if (!suitstrings.contains(c->getSuitString()))
                suitstrings << c->getSuitString();
        }

        Slash *slash = new Slash(Card::SuitToBeDecided, -1);
        slash->addSubcard(to_select);
        slash->setSkillName("dev_jiaohua");
        slash->deleteLater();
        if (Self->isLocked(slash, true)) return false;

        return !to_select->isEquipped() && !suitstrings.isEmpty() && suitstrings.contains(to_select->getSuitString());
    }

    const Card *viewAs(const Card *card) const
    {
        Slash *slash = new Slash(Card::SuitToBeDecided, -1);
        slash->addSubcard(card);
        slash->setSkillName("dev_jiaohua");
        return slash;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }
};

class DevJiaohua : public TriggerSkill
{
public:
    DevJiaohua() : TriggerSkill("dev_jiaohua")
    {
        events << TargetConfirmed;
        view_as_skill = new DevJiaohuaVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || !use.to.contains(player) || player->getEquips().isEmpty() || player->isKongcheng()) return false;

        player->tag["dev_jiaohua_data"] = data;
        const Card *card = room->askForUseCard(player, "@@dev_jiaohua", "@dev_jiaohua");
        player->tag.remove("dev_jiaohua_data");

        if (card) {
            use.to.clear();
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

ChallengeDeveloperScenario::ChallengeDeveloperScenario()
    : Scenario("challengedeveloper")
{
    lord = "sujiang";
    rebels << "dev_duguanhe" << "dev_chongmei" << "dev_dudu" << "dev_db";

    rule = new ChallengeDeveloperRule(this);

    General *dev_xusine = new General(this, "dev_xusine", "god", 2, false, true, true);
    dev_xusine->addSkill(new DevLvedong);
    dev_xusine->addSkill(new DevCaiyi);

    General *dev_duguanhe = new General(this, "dev_duguanhe", "god", 4, true, true, true);
    dev_duguanhe->addSkill(new DevJianshi);
    dev_duguanhe->addSkill(new DevCangdao);

    General *dev_chongmei = new General(this, "dev_chongmei", "god", 3, false, true, true);
    dev_chongmei->addSkill(new DevPianxian);
    dev_chongmei->addSkill(new DevQuanneng);
    dev_chongmei->addRelateSkill("xiaoji");
    dev_chongmei->addRelateSkill("tenyearjizhi");
    dev_chongmei->addRelateSkill("buyi");
    dev_chongmei->addRelateSkill("shushen");
    dev_chongmei->addRelateSkill("lieren");

    General *dev_dudu = new General(this, "dev_dudu", "god", 4, true, true, true);
    dev_dudu->addSkill(new DevPofeng);
    dev_dudu->addSkill(new DevXiaohun);
    dev_dudu->addSkill(new FakeMoveSkill("dev_xiaohun"));
    related_skills.insertMulti("dev_xiaohun", "#dev_xiaohun-fake-move");

    General *dev_db = new General(this, "dev_db", "god", 3, true, true, true);
    dev_db->addSkill(new DevSaiche);
    dev_db->addSkill(new DevSaichePro);
    dev_db->addSkill(new DevZhuaji);
    dev_db->addSkill(new DevZhuajiMark);
    dev_db->addRelateSkill("dev_110");
    dev_db->addRelateSkill("dev_119");
    dev_db->addRelateSkill("dev_120");
    related_skills.insertMulti("dev_saiche", "#dev_saiche");
    related_skills.insertMulti("dev_zhuaji", "#dev_zhuaji-mark");

    General *dev_amira = new General(this, "dev_amira", "god", 3, false, true, true);
    dev_amira->addSkill(new DevJiayao);
    dev_amira->addSkill(new DevJiayaoEffect);
    dev_amira->addSkill(new DevShangyin);
    related_skills.insertMulti("dev_jiayao", "#dev_jiayao");

    General *dev_mye = new General(this, "dev_mye", "god", 3, true, true, true);
    dev_mye->addSkill(new DevXiancheng);
    dev_mye->addSkill(new DevChengzhi);
    dev_mye->addSkill(new DevBancheng);

    General *dev_yizhiyongheng = new General(this, "dev_yizhiyongheng", "god", 5, true, true, true);
    dev_yizhiyongheng->setStartHp(3);
    dev_yizhiyongheng->addSkill(new DevShuguang);

    General *dev_yuanjiati = new General(this, "dev_yuanjiati", "god", 2, true, true, true);
    dev_yuanjiati->addSkill(new DevBaoji);
    dev_yuanjiati->addSkill(new DevShanbi);

    General *dev_funima = new General(this, "dev_funima", "god", 3, true, true, true);
    dev_funima->addSkill(new DevNini);
    dev_funima->addSkill(new DevDanteng);

    General *dev_para = new General(this, "dev_para", "god", 3, true, true, true);
    dev_para->addSkill(new DevGengxin);
    dev_para->addSkill(new DevXueba);

    General *dev_rara = new General(this, "dev_rara", "god", 3, false, true, true);
    dev_rara->addSkill(new DevMeihuo);
    dev_rara->addSkill(new DevNvshen);

    General *dev_fsu = new General(this, "dev_fsu", "god", 5, true, true, true);
    dev_fsu->addSkill(new DevGepi);
    dev_fsu->addSkill(new DevGepiClear);
    dev_fsu->addSkill(new DevGepiInv);
    related_skills.insertMulti("dev_gepi", "#dev_gepi-clear");
    related_skills.insertMulti("dev_gepi", "#dev_gepi-inv");

    General *dev_hmqgg = new General(this, "dev_hmqgg", "god", 4, true, true, true);
    dev_hmqgg->addSkill(new DevChaidao);

    General *dev_tak = new General(this, "dev_tak", "god", 4, true, true, true);
    dev_tak->addSkill(new DevSaodong);
    dev_tak->addSkill(new DevSaodongUse);
    related_skills.insertMulti("dev_saodong", "#dev_saodong-use");

    General *dev_lzx = new General(this, "dev_lzx", "god", 3, false, true, true);
    dev_lzx->addSkill(new DevZhiyu);
    dev_lzx->addSkill(new DevPinghe);

    General *dev_cheshen = new General(this, "dev_cheshen", "god", 4, true, true, true);
    dev_cheshen->addSkill(new DevZhiyin);
    dev_cheshen->addSkill(new DevJiaodao);

    General *dev_36li = new General(this, "dev_36li", "god", 3, true, true, true);
    dev_36li->addSkill(new DevMeigong);
    dev_36li->addSkill(new DevQiliao);
    dev_36li->addSkill(new DevQiliaoEffect);
    related_skills.insertMulti("dev_qiliao", "#dev_qiliao-effect");

    General *dev_tan = new General(this, "dev_tan", "god", 3, true, true, true);
    dev_tan->addSkill(new DevXuexi);
    dev_tan->addSkill(new DevYukuai);

    General *dev_zhangzheng = new General(this, "dev_zhangzheng", "god", 4, true, true, true);
    dev_zhangzheng->addSkill(new DevGeili);
    dev_zhangzheng->addSkill(new DevGeiliPhase);
    related_skills.insertMulti("dev_geili", "#dev_geili");

    General *dev_jiaqi = new General(this, "dev_jiaqi", "god", 3, true, true, true);
    dev_jiaqi->addSkill(new DevJiangyou);
    dev_jiaqi->addSkill(new DevJiangyouXiumian);
    dev_jiaqi->addSkill(new DevJiangyouDeath);
    dev_jiaqi->addSkill(new DevHeti);
    related_skills.insertMulti("dev_jiangyou", "#dev_jiangyou-xiumian");
    related_skills.insertMulti("dev_jiangyou", "#dev_jiangyou-death");

    General *dev_zy = new General(this, "dev_zy", "god", 3, true, true, true);
    dev_zy->addSkill(new DevJuanlao);
    dev_zy->addSkill(new DevYegeng);

    General *dev_jiaoshen = new General(this, "dev_jiaoshen", "god", 4, true, true, true);
    dev_jiaoshen->addSkill(new DevJiaoqi);
    dev_jiaoshen->addSkill(new DevAojiao);
    dev_jiaoshen->addRelateSkill("dev_jiaohua");

    addMetaObject<DevLvedongCard>();
    addMetaObject<DevPofengCard>();
    addMetaObject<DevXiaohunCard>();
    addMetaObject<DevChengzhiCard>();
    addMetaObject<DevChengzhiCard>();
    addMetaObject<DevBanchengCard>();
    addMetaObject<DevNiniCard>();
    addMetaObject<DevGengxinCard>();
    addMetaObject<DevMeigongCard>();

    skills << new Dev110 << new Dev119 << new Dev120 << new DevJiaohua;
}
