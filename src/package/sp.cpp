#include "sp.h"
#include "client.h"
#include "general.h"
#include "skill.h"
#include "standard-skillcards.h"
#include "engine.h"
#include "maneuvering.h"
#include "json.h"
#include "settings.h"
#include "clientplayer.h"
#include "util.h"
#include "wrapped-card.h"
#include "room.h"
#include "roomthread.h"
#include "yjcm2013.h"
#include "wind.h"

class SPMoonSpearSkill : public WeaponSkill
{
public:
    SPMoonSpearSkill() : WeaponSkill("sp_moonspear")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::NotActive)
            return false;

        const Card *card = NULL;
        if (triggerEvent == CardUsed) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            card = card_use.card;
        } else if (triggerEvent == CardResponded) {
            card = data.value<CardResponseStruct>().m_card;
        }

        if (card == NULL || !card->isBlack()
            || (card->getHandlingMethod() != Card::MethodUse && card->getHandlingMethod() != Card::MethodResponse))
            return false;

        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *tmp, room->getAlivePlayers()) {
            if (player->inMyAttackRange(tmp))
                targets << tmp;
        }
        if (targets.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@sp_moonspear", true, true);
        if (!target) return false;
        room->setEmotion(player, "weapon/moonspear");
        if (!room->askForCard(target, "jink", "@moon-spear-jink", QVariant(), Card::MethodResponse, player))
            room->damage(DamageStruct(objectName(), player, target));
        return false;
    }
};

SPMoonSpear::SPMoonSpear(Suit suit, int number)
    : Weapon(suit, number, 3)
{
    setObjectName("sp_moonspear");
}

SPCardPackage::SPCardPackage()
    : Package("sp_cards")
{
    (new SPMoonSpear)->setParent(this);
    skills << new SPMoonSpearSkill;

    type = CardPack;
}

ADD_PACKAGE(SPCard)

HegemonySPPackage::HegemonySPPackage()
: Package("hegemony_sp")
{
    General *sp_heg_zhouyu = new General(this, "sp_heg_zhouyu", "wu", 3, true, true); // GSP 001
    sp_heg_zhouyu->addSkill("nosyingzi");
    sp_heg_zhouyu->addSkill("nosfanjian");

    General *sp_heg_xiaoqiao = new General(this, "sp_heg_xiaoqiao", "wu", 3, false, true); // GSP 002
    sp_heg_xiaoqiao->addSkill("tianxiang");
    sp_heg_xiaoqiao->addSkill("hongyan");
}

ADD_PACKAGE(HegemonySP)

class Jilei : public TriggerSkill
{
public:
    Jilei() : TriggerSkill("jilei")
    {
        events << Damaged;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *yangxiu, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *current = room->getCurrent();
        if (!current || current->getPhase() == Player::NotActive || current->isDead() || !damage.from)
            return false;

        if (room->askForSkillInvoke(yangxiu, objectName(), data)) {
            QString choice = room->askForChoice(yangxiu, objectName(), "BasicCard+EquipCard+TrickCard");
            room->broadcastSkillInvoke(objectName());

            LogMessage log;
            log.type = "#Jilei";
            log.from = damage.from;
            log.arg = choice;
            room->sendLog(log);

            QStringList jilei_list = damage.from->tag[objectName()].toStringList();
            if (jilei_list.contains(choice)) return false;
            jilei_list.append(choice);
            damage.from->tag[objectName()] = QVariant::fromValue(jilei_list);
            QString _type = choice + "|.|.|hand"; // Handcards only
            room->setPlayerCardLimitation(damage.from, "use,response,discard", _type, true);

            QString type_name = choice.replace("Card", "").toLower();
            if (damage.from->getMark("@jilei_" + type_name) == 0)
                room->addPlayerMark(damage.from, "@jilei_" + type_name);
        }

        return false;
    }
};

class JileiClear : public TriggerSkill
{
public:
    JileiClear() : TriggerSkill("#jilei-clear")
    {
        events << EventPhaseChanging << Death;
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
            if (death.who != target || target != room->getCurrent())
                return false;
        }
        QList<ServerPlayer *> players = room->getAllPlayers();
        foreach (ServerPlayer *player, players) {
            QStringList jilei_list = player->tag["jilei"].toStringList();
            if (!jilei_list.isEmpty()) {
                LogMessage log;
                log.type = "#JileiClear";
                log.from = player;
                room->sendLog(log);

                foreach (QString jilei_type, jilei_list) {
                    room->removePlayerCardLimitation(player, "use,response,discard", jilei_type + "|.|.|hand$1");
                    QString type_name = jilei_type.replace("Card", "").toLower();
                    room->setPlayerMark(player, "@jilei_" + type_name, 0);
                }
                player->tag.remove("jilei");
            }
        }

        return false;
    }
};

class Danlao : public TriggerSkill
{
public:
    Danlao() : TriggerSkill("danlao")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.length() <= 1 || !use.to.contains(player)
            || !use.card->isKindOf("TrickCard")
            || !room->askForSkillInvoke(player, objectName(), data))
            return false;

        room->broadcastSkillInvoke(objectName());
        player->setFlags("-DanlaoTarget");
        player->setFlags("DanlaoTarget");
        player->drawCards(1, objectName());
        if (player->isAlive() && player->hasFlag("DanlaoTarget")) {
            player->setFlags("-DanlaoTarget");
            use.nullified_list << player->objectName();
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

Yongsi::Yongsi() : TriggerSkill("yongsi")
{
    events << DrawNCards << EventPhaseStart;
    frequency = Compulsory;
}

int Yongsi::getKingdoms(ServerPlayer *yuanshu) const
{
    QSet<QString> kingdom_set;
    Room *room = yuanshu->getRoom();
    foreach(ServerPlayer *p, room->getAlivePlayers())
        kingdom_set << p->getKingdom();

    return kingdom_set.size();
}

bool Yongsi::trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *yuanshu, QVariant &data) const
{
    if (triggerEvent == DrawNCards) {
        int x = getKingdoms(yuanshu);
        data = data.toInt() + x;

        Room *room = yuanshu->getRoom();
        LogMessage log;
        log.type = "#YongsiGood";
        log.from = yuanshu;
        log.arg = QString::number(x);
        log.arg2 = objectName();
        room->sendLog(log);
        room->notifySkillInvoked(yuanshu, objectName());

        room->broadcastSkillInvoke("yongsi", x % 2 + 1);
    } else if (triggerEvent == EventPhaseStart && yuanshu->getPhase() == Player::Discard) {
        int x = getKingdoms(yuanshu);
        LogMessage log;
        log.type = yuanshu->getCardCount() > x ? "#YongsiBad" : "#YongsiWorst";
        log.from = yuanshu;
        log.arg = QString::number(log.type == "#YongsiBad" ? x : yuanshu->getCardCount());
        log.arg2 = objectName();
        room->sendLog(log);
        room->notifySkillInvoked(yuanshu, objectName());
        if (x > 0)
            room->askForDiscard(yuanshu, "yongsi", x, x, false, true);
    }

    return false;
}

class WeidiViewAsSkill : public ViewAsSkill
{
public:
    WeidiViewAsSkill() : ViewAsSkill("weidi")
    {
    }

    static QList<const ViewAsSkill *> getLordViewAsSkills(const Player *player)
    {
        const Player *lord = NULL;
        foreach (const Player *p, player->getAliveSiblings()) {
            if (p->isLord()) {
                lord = p;
                break;
            }
        }
        if (!lord) return QList<const ViewAsSkill *>();

        QList<const ViewAsSkill *> vs_skills;
        foreach (const Skill *skill, lord->getVisibleSkillList()) {
            if (skill->isLordSkill() && player->hasLordSkill(skill->objectName())) {
                const ViewAsSkill *vs = ViewAsSkill::parseViewAsSkill(skill);
                if (vs)
                    vs_skills << vs;
            }
        }
        return vs_skills;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        QList<const ViewAsSkill *> vs_skills = getLordViewAsSkills(player);
        foreach (const ViewAsSkill *skill, vs_skills) {
            if (skill->isEnabledAtPlay(player))
                return true;
        }
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        QList<const ViewAsSkill *> vs_skills = getLordViewAsSkills(player);
        foreach (const ViewAsSkill *skill, vs_skills) {
            if (skill->isEnabledAtResponse(player, pattern))
                return true;
        }
        return false;
    }

    bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        QList<const ViewAsSkill *> vs_skills = getLordViewAsSkills(player);
        foreach (const ViewAsSkill *skill, vs_skills) {
            if (skill->isEnabledAtNullification(player))
                return true;
        }
        return false;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString skill_name = Self->tag["weidi"].toString();
        if (skill_name.isEmpty()) return false;
        const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
        if (vs_skill) return vs_skill->viewFilter(selected, to_select);
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        QString skill_name = Self->tag["weidi"].toString();
        if (skill_name.isEmpty()) return NULL;
        const ViewAsSkill *vs_skill = Sanguosha->getViewAsSkill(skill_name);
        if (vs_skill) return vs_skill->viewAs(cards);
        return NULL;
    }
};

WeidiDialog *WeidiDialog::getInstance()
{
    static WeidiDialog *instance;
    if (instance == NULL)
        instance = new WeidiDialog();

    return instance;
}

WeidiDialog::WeidiDialog()
{
    setObjectName("weidi");
    setWindowTitle(Sanguosha->translate("weidi"));
    group = new QButtonGroup(this);

    button_layout = new QVBoxLayout;
    setLayout(button_layout);
    connect(group, SIGNAL(buttonClicked(QAbstractButton *)), this, SLOT(selectSkill(QAbstractButton *)));
}

void WeidiDialog::popup()
{
    Self->tag.remove(objectName());
    foreach (QAbstractButton *button, group->buttons()) {
        button_layout->removeWidget(button);
        group->removeButton(button);
        delete button;
    }

    QList<const ViewAsSkill *> vs_skills = WeidiViewAsSkill::getLordViewAsSkills(Self);
    int count = 0;
    QString name;
    foreach (const ViewAsSkill *skill, vs_skills) {
        QAbstractButton *button = createSkillButton(skill->objectName());
        button->setEnabled(skill->isAvailable(Self, Sanguosha->currentRoomState()->getCurrentCardUseReason(),
            Sanguosha->currentRoomState()->getCurrentCardUsePattern()));
        if (button->isEnabled()) {
            count++;
            name = skill->objectName();
        }
        button_layout->addWidget(button);
    }

    if (count == 0) {
        emit onButtonClick();
        return;
    } else if (count == 1) {
        Self->tag[objectName()] = name;
        emit onButtonClick();
        return;
    }

    exec();
}

void WeidiDialog::selectSkill(QAbstractButton *button)
{
    Self->tag[objectName()] = button->objectName();
    emit onButtonClick();
    accept();
}

QAbstractButton *WeidiDialog::createSkillButton(const QString &skill_name)
{
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (!skill) return NULL;

    QCommandLinkButton *button = new QCommandLinkButton(Sanguosha->translate(skill_name));
    button->setObjectName(skill_name);
    button->setToolTip(skill->getDescription());

    group->addButton(button);
    return button;
}

class Weidi : public GameStartSkill
{
public:
    Weidi() : GameStartSkill("weidi")
    {
        frequency = Compulsory;
        view_as_skill = new WeidiViewAsSkill;
    }

    void onGameStart(ServerPlayer *) const
    {
        return;
    }

    QDialog *getDialog() const
    {
        return WeidiDialog::getInstance();
    }
};

class Yicong : public DistanceSkill
{
public:
    Yicong() : DistanceSkill("yicong")
    {
    }

    int getCorrect(const Player *from, const Player *to) const
    {
        int correct = 0;
        if (from->hasSkill(this) && from->getHp() > 2)
            correct--;
        if (to->hasSkill(this) && to->getHp() <= 2)
            correct++;

        return correct;
    }
};

class YicongEffect : public TriggerSkill
{
public:
    YicongEffect() : TriggerSkill("#yicong-effect")
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
            if (player->getGeneralName() == "gongsunzan"
                || (player->getGeneralName() != "st_gongsunzan" && player->getGeneral2Name() == "gongsunzan"))
                index += 2;
            room->broadcastSkillInvoke("yicong", index);
        }
        return false;
    }
};

class Danji : public PhaseChangeSkill
{
public:
    Danji() : PhaseChangeSkill("danji")
    { // What a silly skill!
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getHandcardNum() > player->getHp()) {
            ServerPlayer *the_lord = room->getLord();
            if (the_lord && (the_lord->getGeneralName().contains("caocao") || the_lord->getGeneral2Name().contains("caocao"))) {
                LogMessage log;
                log.type = "#DanjiWake";
                log.from = player;
                log.arg = QString::number(player->getHandcardNum());
                log.arg2 = QString::number(player->getHp());
                room->sendLog(log);
                room->broadcastSkillInvoke(objectName());
                return true;
            }
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *guanyu) const
    {
        Room *room = guanyu->getRoom();
        room->notifySkillInvoked(guanyu, objectName());

        //room->doLightbox("$DanjiAnimate", 5000);
        room->doSuperLightbox("sp_guanyu", "danji");

        room->setPlayerMark(guanyu, "danji", 1);
        if (room->changeMaxHpForAwakenSkill(guanyu) && guanyu->getMark("danji") == 1)
            room->acquireSkill(guanyu, "mashu");
        return false;
    }
};

YuanhuCard::YuanhuCard()
{
    mute = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool YuanhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (!targets.isEmpty())
        return false;

    const Card *card = Sanguosha->getCard(subcards.first());
    const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
    int equip_index = static_cast<int>(equip->location());
    return to_select->getEquip(equip_index) == NULL;
}

void YuanhuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int index = -1;
    if (card_use.to.first() == card_use.from)
        index = 5;
    else if (card_use.to.first()->getGeneralName().contains("caocao"))
        index = 4;
    else {
        const Card *card = Sanguosha->getCard(card_use.card->getSubcards().first());
        if (card->isKindOf("Weapon"))
            index = 1;
        else if (card->isKindOf("Armor"))
            index = 2;
        else if (card->isKindOf("Horse"))
            index = 3;
    }
    room->broadcastSkillInvoke("yuanhu", index);
    SkillCard::onUse(room, card_use);
}

void YuanhuCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *caohong = effect.from;
    Room *room = caohong->getRoom();
    room->moveCardTo(this, caohong, effect.to, Player::PlaceEquip,
        CardMoveReason(CardMoveReason::S_REASON_PUT, caohong->objectName(), "yuanhu", QString()));

    const Card *card = Sanguosha->getCard(subcards.first());

    LogMessage log;
    log.type = "$ZhijianEquip";
    log.from = effect.to;
    log.card_str = QString::number(card->getEffectiveId());
    room->sendLog(log);

    if (card->isKindOf("Weapon")) {
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (effect.to->distanceTo(p) == 1 && caohong->canDiscard(p, "hej"))
                targets << p;
        }
        if (!targets.isEmpty()) {
            ServerPlayer *to_dismantle = room->askForPlayerChosen(caohong, targets, "yuanhu", "@yuanhu-discard:" + effect.to->objectName());
            int card_id = room->askForCardChosen(caohong, to_dismantle, "hej", "yuanhu", false, Card::MethodDiscard);
            room->throwCard(Sanguosha->getCard(card_id), to_dismantle, caohong);
        }
    } else if (card->isKindOf("Armor")) {
        effect.to->drawCards(1, "yuanhu");
    } else if (card->isKindOf("Horse")) {
        room->recover(effect.to, RecoverStruct(effect.from));
    }
}

class YuanhuViewAsSkill : public OneCardViewAsSkill
{
public:
    YuanhuViewAsSkill() : OneCardViewAsSkill("yuanhu")
    {
        filter_pattern = "EquipCard";
        response_pattern = "@@yuanhu";
    }

    const Card *viewAs(const Card *originalcard) const
    {
        YuanhuCard *first = new YuanhuCard;
        first->addSubcard(originalcard->getId());
        first->setSkillName(objectName());
        return first;
    }
};

class Yuanhu : public PhaseChangeSkill
{
public:
    Yuanhu() : PhaseChangeSkill("yuanhu")
    {
        view_as_skill = new YuanhuViewAsSkill;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        if (target->getPhase() == Player::Finish && !target->isNude())
            room->askForUseCard(target, "@@yuanhu", "@yuanhu-equip", -1, Card::MethodNone);
        return false;
    }
};

XuejiCard::XuejiCard()
{
}

bool XuejiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length() >= Self->getLostHp())
        return false;

    if (to_select == Self)
        return false;

    int range_fix = 0;
    if (Self->getWeapon() && Self->getWeapon()->getEffectiveId() == getEffectiveId()) {
        const Weapon *weapon = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
        range_fix += weapon->getRange() - Self->getAttackRange(false);
    } else if (Self->getOffensiveHorse() && Self->getOffensiveHorse()->getEffectiveId() == getEffectiveId())
        range_fix += 1;

    return Self->inMyAttackRange(to_select, range_fix);
}

void XuejiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    DamageStruct damage;
    damage.from = source;
    damage.reason = "xueji";

    foreach (ServerPlayer *p, targets) {
        damage.to = p;
        room->damage(damage);
    }
    foreach (ServerPlayer *p, targets) {
        if (p->isAlive())
            p->drawCards(1, "xueji");
    }
}

class Xueji : public OneCardViewAsSkill
{
public:
    Xueji() : OneCardViewAsSkill("xueji")
    {
        filter_pattern = ".|red!";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getLostHp() > 0 && player->canDiscard(player, "he") && !player->hasUsed("XuejiCard");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        XuejiCard *first = new XuejiCard;
        first->addSubcard(originalcard->getId());
        first->setSkillName(objectName());
        return first;
    }
};

class Huxiao : public TargetModSkill
{
public:
    Huxiao() : TargetModSkill("huxiao")
    {
    }

    int getResidueNum(const Player *from, const Card *, const Player *) const
    {
        if (from->hasSkill(this))
            return from->getMark(objectName());
        else
            return 0;
    }
};

class HuxiaoCount : public TriggerSkill
{
public:
    HuxiaoCount() : TriggerSkill("#huxiao-count")
    {
        events << SlashMissed << EventPhaseChanging;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == SlashMissed) {
            if (player->getPhase() == Player::Play)
                room->addPlayerMark(player, "huxiao");
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from == Player::Play)
                if (player->getMark("huxiao") > 0)
                    room->setPlayerMark(player, "huxiao", 0);
        }

        return false;
    }
};

class HuxiaoClear : public DetachEffectSkill
{
public:
    HuxiaoClear() : DetachEffectSkill("huxiao")
    {
    }

    void onSkillDetached(Room *room, ServerPlayer *player) const
    {
        room->setPlayerMark(player, "huxiao", 0);
    }
};

class Wuji : public PhaseChangeSkill
{
public:
    Wuji() : PhaseChangeSkill("wuji")
    {
        frequency = Wake;
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Finish || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMark("damage_point_round") >= 3) {
            LogMessage log;
            log.type = "#WujiWake";
            log.from = player;
            log.arg = QString::number(player->getMark("damage_point_round"));
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());

        room->broadcastSkillInvoke(objectName());
        //room->doLightbox("$WujiAnimate", 4000);

        room->doSuperLightbox("guanyinping", "wuji");

        room->setPlayerMark(player, "wuji", 1);
        if (room->changeMaxHpForAwakenSkill(player, 1)) {
            room->recover(player, RecoverStruct(player));
            if (player->getMark("wuji") == 1)
                room->detachSkillFromPlayer(player, "huxiao");
        }

        return false;
    }
};

class Baobian : public TriggerSkill
{
public:
    Baobian() : TriggerSkill("baobian")
    {
        events << GameStart << HpChanged << MaxHpChanged << EventAcquireSkill << EventLoseSkill;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventLoseSkill) {
            if (data.toString() == objectName()) {
                QStringList baobian_skills = player->tag["BaobianSkills"].toStringList();
                QStringList detachList;
                foreach(QString skill_name, baobian_skills)
                    detachList.append("-" + skill_name);
                room->handleAcquireDetachSkills(player, detachList);
                player->tag["BaobianSkills"] = QVariant();
            }
            return false;
        } else if (triggerEvent == EventAcquireSkill) {
            if (data.toString() != objectName()) return false;
        }

        if (!player->isAlive() || !player->hasSkill(this, true)) return false;

        acquired_skills.clear();
        detached_skills.clear();
        BaobianChange(room, player, 1, "shensu");
        BaobianChange(room, player, 2, "paoxiao");
        BaobianChange(room, player, 3, "tiaoxin");
        if (!acquired_skills.isEmpty() || !detached_skills.isEmpty())
            room->handleAcquireDetachSkills(player, acquired_skills + detached_skills);
        return false;
    }

private:
    void BaobianChange(Room *room, ServerPlayer *player, int hp, const QString &skill_name) const
    {
        QStringList baobian_skills = player->tag["BaobianSkills"].toStringList();
        if (player->getHp() <= hp) {
            if (!baobian_skills.contains(skill_name)) {
                room->notifySkillInvoked(player, "baobian");
                if (player->getHp() == hp)
                    room->broadcastSkillInvoke("baobian", 4 - hp);
                acquired_skills.append(skill_name);
                baobian_skills << skill_name;
            }
        } else {
            if (baobian_skills.contains(skill_name)) {
                detached_skills.append("-" + skill_name);
                baobian_skills.removeOne(skill_name);
            }
        }
        player->tag["BaobianSkills"] = QVariant::fromValue(baobian_skills);
    }

    mutable QStringList acquired_skills, detached_skills;
};

class TenyearBaobian : public TriggerSkill
{
public:
    TenyearBaobian() : TriggerSkill("tenyearbaobian")
    {
        events << Damaged;
        frequency = Compulsory;
        waked_skills = "tiaoxin,tenyearpaoxiao,tenyearshensu";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        foreach (QString sk, waked_skills.split(",")) {
            if (!player->hasSkill(sk, true)) {
                room->sendCompulsoryTriggerLog(player, this);
                room->acquireSkill(player, sk);
                break;
            }
        }
        return false;
    }
};

BifaCard::BifaCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool BifaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getPile("bifa").isEmpty() && to_select != Self;
}

void BifaCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.first();
    target->tag["BifaSource" + QString::number(getEffectiveId())] = QVariant::fromValue(source);
    target->addToPile("bifa", this, false);
}

class BifaViewAsSkill : public OneCardViewAsSkill
{
public:
    BifaViewAsSkill() : OneCardViewAsSkill("bifa")
    {
        filter_pattern = ".|.|.|hand";
        response_pattern = "@@bifa";
    }

    const Card *viewAs(const Card *originalcard) const
    {
        Card *card = new BifaCard;
        card->addSubcard(originalcard);
        return card;
    }
};

class Bifa : public TriggerSkill
{
public:
    Bifa() : TriggerSkill("bifa")
    {
        events << EventPhaseStart;
        view_as_skill = new BifaViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish && !player->isKongcheng()) {
            room->askForUseCard(player, "@@bifa", "@bifa-remove", -1, Card::MethodNone);
        } else if (player->getPhase() == Player::RoundStart && player->getPile("bifa").length() > 0) {
            int card_id = player->getPile("bifa").first();
            ServerPlayer *chenlin = player->tag["BifaSource" + QString::number(card_id)].value<ServerPlayer *>();
            QList<int> ids;
            ids << card_id;

            LogMessage log;
            log.type = "$BifaView";
            log.from = player;
            log.card_str = QString::number(card_id);
            log.arg = "bifa";
            room->sendLog(log, player);

            room->fillAG(ids, player);
            const Card *cd = Sanguosha->getCard(card_id);
            QString pattern;
            if (cd->isKindOf("BasicCard"))
                pattern = "BasicCard";
            else if (cd->isKindOf("TrickCard"))
                pattern = "TrickCard";
            else if (cd->isKindOf("EquipCard"))
                pattern = "EquipCard";
            QVariant data_for_ai = QVariant::fromValue(pattern);
            pattern.append("|.|.|hand");
            const Card *to_give = NULL;
            if (!player->isKongcheng() && chenlin && chenlin->isAlive())
                to_give = room->askForCard(player, pattern, "@bifa-give", data_for_ai, Card::MethodNone, chenlin);
            if (chenlin && to_give) {
                room->broadcastSkillInvoke(objectName(), 2);
                CardMoveReason reasonG(CardMoveReason::S_REASON_GIVE, player->objectName(), chenlin->objectName(), "bifa", QString());
                room->obtainCard(chenlin, to_give, reasonG, false);
                CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, player->objectName(), "bifa", QString());
                room->obtainCard(player, cd, reason, false);
            } else {
                room->broadcastSkillInvoke(objectName(), 3);
                CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), objectName(), QString());
                room->throwCard(cd, reason, NULL);
                room->loseHp(player);
            }
            room->clearAG(player);
            player->tag.remove("BifaSource" + QString::number(card_id));
        }
        return false;
    }

    int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return 1;
    }
};

SongciCard::SongciCard()
{
    mute = true;
}

bool SongciCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getMark("songci" + Self->objectName()) == 0 && to_select->getHandcardNum() != to_select->getHp();
}

void SongciCard::onEffect(const CardEffectStruct &effect) const
{
    int handcard_num = effect.to->getHandcardNum();
    int hp = effect.to->getHp();
    Room *room = effect.from->getRoom();
    room->setPlayerMark(effect.to, "@songci", 1);
    room->addPlayerMark(effect.to, "songci" + effect.from->objectName());
    if (handcard_num > hp) {
        room->broadcastSkillInvoke("songci", 2);
        room->askForDiscard(effect.to, "songci", 2, 2, false, true);
    } else if (handcard_num < hp) {
        room->broadcastSkillInvoke("songci", 1);
        effect.to->drawCards(2, "songci");
    }
}

class SongciViewAsSkill : public ZeroCardViewAsSkill
{
public:
    SongciViewAsSkill() : ZeroCardViewAsSkill("songci")
    {
    }

    const Card *viewAs() const
    {
        return new SongciCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("songci" + player->objectName()) == 0 && player->getHandcardNum() != player->getHp()) return true;
        foreach(const Player *sib, player->getAliveSiblings())
            if (sib->getMark("songci" + player->objectName()) == 0 && sib->getHandcardNum() != sib->getHp())
                return true;
        return false;
    }
};

class Songci : public TriggerSkill
{
public:
    Songci() : TriggerSkill("songci")
    {
        events << Death;
        view_as_skill = new SongciViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->hasSkill(this);
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getMark("@songci") > 0)
                room->setPlayerMark(p, "@songci", 0);
            if (p->getMark("songci" + player->objectName()) > 0)
                room->setPlayerMark(p, "songci" + player->objectName(), 0);
        }
        return false;
    }
};

class Xiuluo : public PhaseChangeSkill
{
public:
    Xiuluo() : PhaseChangeSkill("xiuluo")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return PhaseChangeSkill::triggerable(target)
            && target->getPhase() == Player::Start
            && target->canDiscard(target, "h")
            && hasDelayedTrick(target);
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        while (hasDelayedTrick(target) && target->canDiscard(target, "h")) {
            QStringList suits;
            foreach (const Card *jcard, target->getJudgingArea()) {
                if (!suits.contains(jcard->getSuitString()))
                    suits << jcard->getSuitString();
            }

            const Card *card = room->askForCard(target, QString(".|%1|.|hand").arg(suits.join(",")),
                "@xiuluo", QVariant(), objectName());
            if (!card || !hasDelayedTrick(target)) break;
            room->broadcastSkillInvoke(objectName());

            QList<int> avail_list, other_list;
            foreach (const Card *jcard, target->getJudgingArea()) {
                if (jcard->isKindOf("SkillCard")) continue;
                if (jcard->getSuit() == card->getSuit())
                    avail_list << jcard->getEffectiveId();
                else
                    other_list << jcard->getEffectiveId();
            }
            room->fillAG(avail_list + other_list, NULL, other_list);
            int id = room->askForAG(target, avail_list, false, objectName());
            room->clearAG();
            room->throwCard(id, NULL);
        }

        return false;
    }

private:
    static bool hasDelayedTrick(const ServerPlayer *target)
    {
        foreach(const Card *card, target->getJudgingArea())
            if (!card->isKindOf("SkillCard")) return true;
        return false;
    }
};

class Shenwei : public DrawCardsSkill
{
public:
    Shenwei() : DrawCardsSkill("#shenwei-draw")
    {
        frequency = Compulsory;
    }

    int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();

        room->broadcastSkillInvoke("shenwei");
        room->sendCompulsoryTriggerLog(player, "shenwei");

        return n + 2;
    }
};

class ShenweiKeep : public MaxCardsSkill
{
public:
    ShenweiKeep() : MaxCardsSkill("shenwei")
    {
    }

    int getExtra(const Player *target) const
    {
        if (target->hasSkill(this))
            return 2;
        else
            return 0;
    }
};

class Shenji : public TargetModSkill
{
public:
    Shenji() : TargetModSkill("shenji")
    {
    }

    int getExtraTargetNum(const Player *from, const Card *) const
    {
        if (from->hasSkill(this) && from->getWeapon() == NULL)
            return 2;
        else
            return 0;
    }
};

class XingwuRecord : public TriggerSkill
{
public:
    XingwuRecord() : TriggerSkill("#xingwu")
    {
        events << PreCardUsed << CardResponded;
        global = true;
    }

    bool trigger(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = NULL;
        if (triggerEvent == PreCardUsed)
            card = data.value<CardUseStruct>().card;
        else {
            CardResponseStruct response = data.value<CardResponseStruct>();
            if (response.m_isUse)
            card = response.m_card;
        }
        if (card && card->getTypeId() != Card::TypeSkill && card->getHandlingMethod() == Card::MethodUse) {
            int n = player->getMark("xingwu");
            if (card->isBlack())
                n |= 1;
            else if (card->isRed())
                n |= 2;
            player->setMark("xingwu", n);
        }
        return false;
    }
};

class Xingwu : public TriggerSkill
{
public:
    Xingwu() : TriggerSkill("xingwu")
    {
        events << EventPhaseStart << CardsMoveOneTime;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() == Player::Discard) {
                int n = player->getMark(objectName());
                bool red_avail = ((n & 2) == 0), black_avail = ((n & 1) == 0);
                if (player->isKongcheng() || (!red_avail && !black_avail))
                    return false;
                QString pattern = ".|.|.|hand";
                if (red_avail != black_avail)
                    pattern = QString(".|%1|.|hand").arg(red_avail ? "red" : "black");
                const Card *card = room->askForCard(player, pattern, "@xingwu", QVariant(), Card::MethodNone);
                if (card) {
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName(), 1);

                    LogMessage log;
                    log.type = "#InvokeSkill";
                    log.from = player;
                    log.arg = objectName();
                    room->sendLog(log);

                    player->addToPile(objectName(), card);
                }
            } else if (player->getPhase() == Player::RoundStart) {
                player->setMark(objectName(), 0);
            }
        } else if (triggerEvent == CardsMoveOneTime) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to == player && move.to_place == Player::PlaceSpecial && player->getPile(objectName()).length() >= 3) {
                player->clearOnePrivatePile(objectName());
                QList<ServerPlayer *> males;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->isMale())
                        males << p;
                }
                if (males.isEmpty()) return false;

                ServerPlayer *target = room->askForPlayerChosen(player, males, objectName(), "@xingwu-choose");
                room->broadcastSkillInvoke(objectName(), 2);
                room->damage(DamageStruct(objectName(), player, target, 2));

                if (!player->isAlive()) return false;
                QList<const Card *> equips = target->getEquips();
                if (!equips.isEmpty()) {
                    DummyCard *dummy = new DummyCard;
                    foreach (const Card *equip, equips) {
                        if (player->canDiscard(target, equip->getEffectiveId()))
                            dummy->addSubcard(equip);
                    }
                    if (dummy->subcardsLength() > 0)
                        room->throwCard(dummy, target, player);
                    delete dummy;
                }
            }
        }
        return false;
    }
};

class Luoyan : public TriggerSkill
{
public:
    Luoyan(const QString &luoyan) : TriggerSkill(luoyan), luoyan(luoyan)
    {
        events << CardsMoveOneTime << EventAcquireSkill << EventLoseSkill;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventLoseSkill && data.toString() == objectName()) {
            player->setMark(luoyan + "_help", 0);
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            QString skills = "-tianxiang|-liuli";
            if (luoyan == "olluoyan")
                skills = "-oltianxiang|-liuli";

            room->handleAcquireDetachSkills(player, skills, true);
        } else if (triggerEvent == EventAcquireSkill && data.toString() == objectName()) {
            if (!player->getPile("xingwu").isEmpty()) {
                player->setMark(luoyan + "_help", 1);
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);

                QString skills = "tianxiang|liuli";
                if (luoyan == "olluoyan")
                    skills = "oltianxiang|liuli";

                room->handleAcquireDetachSkills(player, skills);
            }
        } else if (triggerEvent == CardsMoveOneTime && player->isAlive() && player->hasSkill(this, true)) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to == player && move.to_place == Player::PlaceSpecial && move.to_pile_name == "xingwu") {
                if (!player->getPile("xingwu").isEmpty() && player->getMark(luoyan + "_help") <= 0) {
                    player->setMark(luoyan + "_help", 1);
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);

                    QString skills = "tianxiang|liuli";
                    if (luoyan == "olluoyan")
                        skills = "oltianxiang|liuli";

                    room->handleAcquireDetachSkills(player, skills);
                }
            } else if (move.from == player && move.from_places.contains(Player::PlaceSpecial)
                && move.from_pile_names.contains("xingwu")) {
                if (player->getPile("xingwu").isEmpty() && player->getMark(luoyan + "_help") > 0) {
                    player->setMark(luoyan + "_help", 0);
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);

                    QString skills = "-tianxiang|-liuli";
                    if (luoyan == "olluoyan")
                        skills = "-oltianxiang|-liuli";

                    room->handleAcquireDetachSkills(player, skills, true);
                }
            }
        }
        return false;
    }

private:
    QString luoyan;
};

OLXingwuCard::OLXingwuCard()
{
    mute = true;
    handling_method = Card::MethodNone;
    will_throw = false;
    m_skillName = "olxingwu";
}

void OLXingwuCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *from = effect.from, *to = effect.to;
    Room *room = from->getRoom();
    from->peiyin(m_skillName, 2);

    if (m_skillName == "tenyearxingwu" || from->getPile("xingwu").contains(subcards.first())) {
        CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, from->objectName(), m_skillName, QString());
        room->throwCard(this, reason, NULL);
    } else {
        from->turnOver();
        room->throwCard(this, from, NULL);
    }

    QList<const Card *> equips = to->getEquips();
    if (!equips.isEmpty()) {
        DummyCard *dummy = new DummyCard;
        foreach (const Card *equip, equips) {
            if (from->canDiscard(to, equip->getEffectiveId()))
                dummy->addSubcard(equip);
        }
        if (dummy->subcardsLength() > 0)
            room->throwCard(dummy, to, from);
        delete dummy;
    }

    if (to->isDead()) return;

    int damage = 2;

    if (m_skillName == "tenyearxingwu") {
        damage = 0;
        QList<Card::Suit> suits;
        foreach (int id, subcards) {
            const Card *c = Sanguosha->getCard(id);
            Card::Suit suit = c->getSuit();
            if (suits.contains(suit)) continue;
            suits << suit;
            damage++;
        }
        damage = qMax(damage, 1);
    }

    damage = to->isMale() ? damage : 1;
    room->damage(DamageStruct(m_skillName, from->isAlive() ? from : NULL, to, damage));
}

TenyearXingwuCard::TenyearXingwuCard() : OLXingwuCard()
{
    mute = true;
    handling_method = Card::MethodNone;
    will_throw = false;
    m_skillName = "tenyearxingwu";
}

class OLXingwuVS : public ViewAsSkill
{
public:
    OLXingwuVS(const QString &xingwu) : ViewAsSkill(xingwu), xingwu(xingwu)
    {
        expand_pile = "xingwu";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() >= 3) return false;
        if (selected.isEmpty())
            return Self->getPile("xingwu").contains(to_select->getEffectiveId()) ||
                (xingwu == "olxingwu" && Self->getHandcards().contains(to_select) && !Self->isJilei(to_select, true));
        else if (selected.length() == 1) {
            if (Self->getPile("xingwu").contains(selected.first()->getEffectiveId()))
                return selected.length() < 3 && Self->getPile("xingwu").contains(to_select->getEffectiveId());
            else
                return xingwu == "olxingwu" && selected.length() < 2 && Self->getHandcards().contains(to_select) && !Self->isJilei(to_select, true);
        } else if (selected.length() == 2) {
            if (Self->getPile("xingwu").contains(selected.first()->getEffectiveId()))
                return selected.length() < 3 && Self->getPile("xingwu").contains(to_select->getEffectiveId());
            else
                return false;
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        if (Self->getPile("xingwu").contains(cards.first()->getEffectiveId()) && cards.length() != 3) return NULL;
        if (Self->getHandcards().contains(cards.first()) && cards.length() != 2) return NULL;

        if (xingwu == "olxingwu") {
            OLXingwuCard *c = new OLXingwuCard;
            c->addSubcards(cards);
            return c;
        } else if (xingwu == "tenyearxingwu") {
            TenyearXingwuCard *c = new TenyearXingwuCard;
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
        return pattern == "@@" + xingwu;
    }

private:
    QString xingwu;
};

class OLXingwu : public PhaseChangeSkill
{
public:
    OLXingwu(const QString &xingwu) : PhaseChangeSkill(xingwu), xingwu(xingwu)
    {
        view_as_skill = new OLXingwuVS(xingwu);
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Discard || player->isNude()) return false;
        if (xingwu == "tenyearxingwu" && player->isKongcheng()) return false;

        QString pattern = "..";
        if(xingwu == "tenyearxingwu")
            pattern = ".|.|.|hand";

        Room *room = player->getRoom();
        const Card *card = room->askForCard(player, pattern, "@" + xingwu + "-card", QVariant(), Card::MethodNone);
        if (!card) return false;
        room->notifySkillInvoked(player, objectName());
        player->peiyin(objectName(), 1);

        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);

        player->addToPile("xingwu", card);

        if (player->isDead()) return false;
        if (player->getPile("xingwu").length() >= 3 || (player->getHandcardNum() >= 2 && xingwu == "olxingwu"))
            room->askForUseCard(player, "@@" + xingwu, "@olxingwu");
        return false;
    }

private:
    QString xingwu;
};

class Yanyu : public TriggerSkill
{
public:
    Yanyu() : TriggerSkill("yanyu")
    {
        events << EventPhaseStart << BeforeCardsMove << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            ServerPlayer *xiahou = room->findPlayerBySkillName(objectName());
            if (xiahou && player->getPhase() == Player::Play) {
                if (!xiahou->canDiscard(xiahou, "he")) return false;
                const Card *card = room->askForCard(xiahou, "..", "@yanyu-discard", QVariant(), objectName());
                if (card) {
                    room->broadcastSkillInvoke(objectName(), 1);
                    xiahou->addMark("YanyuDiscard" + QString::number(card->getTypeId()), 3);
                }
            }
        } else if (triggerEvent == BeforeCardsMove && TriggerSkill::triggerable(player)) {
            ServerPlayer *current = room->getCurrent();
            if (!current || current->getPhase() != Player::Play) return false;
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.to_place == Player::DiscardPile) {
                QList<int> ids, disabled;
                QList<int> all_ids = move.card_ids;
                foreach (int id, move.card_ids) {
                    const Card *card = Sanguosha->getCard(id);
                    if (player->getMark("YanyuDiscard" + QString::number(card->getTypeId())) > 0)
                        ids << id;
                    else
                        disabled << id;
                }
                if (ids.isEmpty()) return false;
                while (!ids.isEmpty()) {
                    room->fillAG(all_ids, player, disabled);
                    bool only = (all_ids.length() == 1);
                    int card_id = -1;
                    if (only)
                        card_id = ids.first();
                    else
                        card_id = room->askForAG(player, ids, true, objectName());
                    room->clearAG(player);
                    if (card_id == -1) break;
                    if (only)
                        player->setMark("YanyuOnlyId", card_id + 1); // For AI
                    const Card *card = Sanguosha->getCard(card_id);
                    ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(),
                        QString("@yanyu-give:::%1:%2\\%3").arg(card->objectName())
                        .arg(card->getSuitString() + "_char")
                        .arg(card->getNumberString()),
                        only, true);
                    player->setMark("YanyuOnlyId", 0);
                    if (target) {
                        player->removeMark("YanyuDiscard" + QString::number(card->getTypeId()));
                        Player::Place place = move.from_places.at(move.card_ids.indexOf(card_id));
                        QList<int> _card_id;
                        _card_id << card_id;
                        move.removeCardIds(_card_id);
                        data = QVariant::fromValue(move);
                        ids.removeOne(card_id);
                        disabled << card_id;
                        foreach (int id, ids) {
                            const Card *card = Sanguosha->getCard(id);
                            if (player->getMark("YanyuDiscard" + QString::number(card->getTypeId())) == 0) {
                                ids.removeOne(id);
                                disabled << id;
                            }
                        }
                        if (move.from && move.from->objectName() == target->objectName() && place != Player::PlaceTable) {
                            // just indicate which card she chose...
                            LogMessage log;
                            log.type = "$MoveCard";
                            log.from = target;
                            log.to << target;
                            log.card_str = QString::number(card_id);
                            room->sendLog(log);
                        }

                        room->broadcastSkillInvoke(objectName(), 2);
                        target->obtainCard(card);
                    } else
                        break;
                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    p->setMark("YanyuDiscard1", 0);
                    p->setMark("YanyuDiscard2", 0);
                    p->setMark("YanyuDiscard3", 0);
                }
            }
        }
        return false;
    }
};

class Xiaode : public TriggerSkill
{
public:
    Xiaode() : TriggerSkill("xiaode")
    {
        events << BuryVictim;
    }

    int getPriority(TriggerEvent) const
    {
        return -2;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
        ServerPlayer *xiahoushi = room->findPlayerBySkillName(objectName());
        if (!xiahoushi || !xiahoushi->tag["XiaodeSkill"].toString().isEmpty()) return false;
        QStringList skill_list = xiahoushi->tag["XiaodeVictimSkills"].toStringList();
        if (skill_list.isEmpty()) return false;
        if (!room->askForSkillInvoke(xiahoushi, objectName(), QVariant::fromValue(skill_list))) return false;
        QString skill_name = room->askForChoice(xiahoushi, objectName(), skill_list.join("+"));
        room->broadcastSkillInvoke(objectName());
        xiahoushi->tag["XiaodeSkill"] = skill_name;
        room->acquireSkill(xiahoushi, skill_name);
        return false;
    }
};

class XiaodeEx : public TriggerSkill
{
public:
    XiaodeEx() : TriggerSkill("#xiaode")
    {
        events << EventPhaseChanging << EventLoseSkill << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                QString skill_name = player->tag["XiaodeSkill"].toString();
                if (!skill_name.isEmpty()) {
                    room->detachSkillFromPlayer(player, skill_name, false, true);
                    player->tag.remove("XiaodeSkill");
                }
            }
        } else if (triggerEvent == EventLoseSkill && data.toString() == "xiaode") {
            QString skill_name = player->tag["XiaodeSkill"].toString();
            if (!skill_name.isEmpty()) {
                room->detachSkillFromPlayer(player, skill_name, false, true);
                player->tag.remove("XiaodeSkill");
            }
        } else if (triggerEvent == Death && TriggerSkill::triggerable(player)) {
            DeathStruct death = data.value<DeathStruct>();
            QStringList skill_list;
            skill_list.append(addSkillList(death.who->getGeneral()));
            skill_list.append(addSkillList(death.who->getGeneral2()));
            player->tag["XiaodeVictimSkills"] = QVariant::fromValue(skill_list);
        }
        return false;
    }

private:
    QStringList addSkillList(const General *general) const
    {
        if (!general) return QStringList();
        QStringList skill_list;
        foreach (const Skill *skill, general->getSkillList()) {
            if (skill->isVisible() && !skill->isLordSkill() && skill->getFrequency() != Skill::Wake)
                skill_list.append(skill->objectName());
        }
        return skill_list;
    }
};

ZhoufuCard::ZhoufuCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool ZhoufuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getPile("incantation").isEmpty();
}

void ZhoufuCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.first();
    target->tag["ZhoufuSource" + QString::number(getEffectiveId())] = QVariant::fromValue(source);
    target->addToPile("incantation", this);
}

class ZhoufuViewAsSkill : public OneCardViewAsSkill
{
public:
    ZhoufuViewAsSkill() : OneCardViewAsSkill("zhoufu")
    {
        filter_pattern = ".|.|.|hand";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZhoufuCard");
    }

    const Card *viewAs(const Card *originalcard) const
    {
        Card *card = new ZhoufuCard;
        card->addSubcard(originalcard);
        return card;
    }
};

class Zhoufu : public TriggerSkill
{
public:
    Zhoufu() : TriggerSkill("zhoufu")
    {
        events << StartJudge << EventPhaseChanging;
        view_as_skill = new ZhoufuViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->getPile("incantation").length() > 0;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == StartJudge) {
            int card_id = player->getPile("incantation").first();

            JudgeStruct *judge = data.value<JudgeStruct *>();
            judge->card = Sanguosha->getCard(card_id);

            LogMessage log;
            log.type = "$ZhoufuJudge";
            log.from = player;
            log.arg = objectName();
            log.card_str = QString::number(judge->card->getEffectiveId());
            room->sendLog(log);

            room->moveCardTo(judge->card, NULL, judge->who, Player::PlaceJudge,
                CardMoveReason(CardMoveReason::S_REASON_JUDGE,
                judge->who->objectName(),
                QString(), QString(), judge->reason), true);
            judge->updateResult();
            room->setTag("SkipGameRule", true);
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                int id = player->getPile("incantation").first();
                ServerPlayer *zhangbao = player->tag["ZhoufuSource" + QString::number(id)].value<ServerPlayer *>();
                if (zhangbao && zhangbao->isAlive())
                    zhangbao->obtainCard(Sanguosha->getCard(id));
            }
        }
        return false;
    }
};

class Yingbing : public TriggerSkill
{
public:
    Yingbing() : TriggerSkill("yingbing")
    {
        events << StartJudge;
        frequency = Frequent;
    }

    int getPriority(TriggerEvent) const
    {
        return -1;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        int id = judge->card->getEffectiveId();
        ServerPlayer *zhangbao = player->tag["ZhoufuSource" + QString::number(id)].value<ServerPlayer *>();
        if (zhangbao && TriggerSkill::triggerable(zhangbao)
            && zhangbao->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName());
            zhangbao->drawCards(2, "yingbing");
        }
        return false;
    }
};

class Kangkai : public TriggerSkill
{
public:
    Kangkai() : TriggerSkill("kangkai")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash")) {
            foreach (ServerPlayer *to, use.to) {
                if (!player->isAlive()) break;
                if (player->distanceTo(to) <= 1 && TriggerSkill::triggerable(player)) {
                    player->tag["KangkaiSlash"] = data;
                    bool will_use = room->askForSkillInvoke(player, objectName(), QVariant::fromValue(to));
                    player->tag.remove("KangkaiSlash");
                    if (!will_use) continue;

                    room->broadcastSkillInvoke(objectName());

                    player->drawCards(1, "kangkai");
                    if (!player->isNude() && player != to) {
                        const Card *card = NULL;
                        if (player->getCardCount() > 1) {
                            card = room->askForCard(player, "..!", "@kangkai-give:" + to->objectName(), data, Card::MethodNone);
                            if (!card)
                                card = player->getCards("he").at(qrand() % player->getCardCount());
                        } else {
                            Q_ASSERT(player->getCardCount() == 1);
                            card = player->getCards("he").first();
                        }
                        CardMoveReason r(CardMoveReason::S_REASON_GIVE, player->objectName(), objectName(), QString());
                        room->obtainCard(to, card, r);
                        if (card->getTypeId() == Card::TypeEquip && room->getCardOwner(card->getEffectiveId()) == to && !to->isLocked(card)) {
                            to->tag["KangkaiSlash"] = data;
                            to->tag["KangkaiGivenCard"] = QVariant::fromValue(card);
                            bool will_use = room->askForSkillInvoke(to, "kangkai_use", "use");
                            to->tag.remove("KangkaiSlash");
                            to->tag.remove("KangkaiGivenCard");
                            if (will_use)
                                room->useCard(CardUseStruct(card, to, to));
                        }
                    }
                }
            }
        }
        return false;
    }
};

class Shenxian : public TriggerSkill
{
public:
    Shenxian() : TriggerSkill("shenxian")
    {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (player->getPhase() == Player::NotActive && move.from && move.from->isAlive()
            && move.from->objectName() != player->objectName()
            && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
            && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
            foreach (int id, move.card_ids) {
                if (Sanguosha->getCard(id)->getTypeId() == Card::TypeBasic) {
                    if (room->askForSkillInvoke(player, objectName(), data)) {
                        room->broadcastSkillInvoke(objectName());
                        player->drawCards(1, "shenxian");
                    }
                    break;
                }
            }
        }
        return false;
    }
};

QiangwuCard::QiangwuCard()
{
    target_fixed = true;
}

void QiangwuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    JudgeStruct judge;
    judge.pattern = ".";
    judge.who = source;
    judge.reason = "qiangwu";
    judge.play_animation = false;
    room->judge(judge);

    bool ok = false;
    int num = judge.pattern.toInt(&ok);
    if (ok)
        room->setPlayerMark(source, "qiangwu", num);
}

class QiangwuViewAsSkill : public ZeroCardViewAsSkill
{
public:
    QiangwuViewAsSkill() : ZeroCardViewAsSkill("qiangwu")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QiangwuCard");
    }

    const Card *viewAs() const
    {
        return new QiangwuCard;
    }
};

class Qiangwu : public TriggerSkill
{
public:
    Qiangwu() : TriggerSkill("qiangwu")
    {
        events << EventPhaseChanging << PreCardUsed << FinishJudge;
        view_as_skill = new QiangwuViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive)
                room->setPlayerMark(player, "qiangwu", 0);
        } else if (triggerEvent == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == "qiangwu")
                judge->pattern = QString::number(judge->card->getNumber());
        } else if (triggerEvent == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash") && player->getMark("qiangwu") > 0
                && use.card->getNumber() > player->getMark("qiangwu")) {
                if (use.m_addHistory) {
                    room->addPlayerHistory(player, use.card->getClassName(), -1);
                    use.m_addHistory = false;
                    data = QVariant::fromValue(use);
                }
            }
        }
        return false;
    }
};

class QiangwuTargetMod : public TargetModSkill
{
public:
    QiangwuTargetMod() : TargetModSkill("#qiangwu-target")
    {
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (card->getNumber() < from->getMark("qiangwu"))
            return 1000;
        else
            return 0;
    }

    int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (from->getMark("qiangwu") > 0
            && (card->getNumber() > from->getMark("qiangwu") || card->hasFlag("Global_SlashAvailabilityChecker")))
            return 1000;
        else
            return 0;
    }
};

class Meibu : public TriggerSkill
{
public:
    Meibu() : TriggerSkill("meibu")
    {
        events << EventPhaseStart << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Play) {
            foreach (ServerPlayer *sunluyu, room->getOtherPlayers(player)) {
                if (!player->inMyAttackRange(sunluyu) && TriggerSkill::triggerable(sunluyu) && room->askForSkillInvoke(sunluyu, objectName())) {
                    room->broadcastSkillInvoke(objectName());
                    if (!player->hasSkill("#meibu-filter", true)) {
                        room->acquireSkill(player, "#meibu-filter", false);
                        room->filterCards(player, player->getCards("he"), false);
                    }
                    QVariantList sunluyus = player->tag[objectName()].toList();
                    sunluyus << QVariant::fromValue(sunluyu);
                    player->tag[objectName()] = QVariant::fromValue(sunluyus);
                    room->insertAttackRangePair(player, sunluyu);
                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;

            QVariantList sunluyus = player->tag[objectName()].toList();
            foreach (QVariant sunluyu, sunluyus) {
                ServerPlayer *s = sunluyu.value<ServerPlayer *>();
                room->removeAttackRangePair(player, s);
            }
            room->detachSkillFromPlayer(player, "#meibu-filter");

            player->tag[objectName()] = QVariantList();

            room->filterCards(player, player->getCards("he"), true);
        }
        return false;
    }

    int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        if (card->isKindOf("Slash"))
            return -2;
        
        return -1;
    }
};


MeibuFilter::MeibuFilter(const QString &skill_name) : FilterSkill(QString("#%1-filter").arg(skill_name)), n(skill_name)
{

}

bool MeibuFilter::viewFilter(const Card *to_select) const
{
    return to_select->getTypeId() == Card::TypeTrick;
}

const Card * MeibuFilter::viewAs(const Card *originalCard) const
{
    Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
    slash->setSkillName("_" + n);
    WrappedCard *card = Sanguosha->getWrappedCard(originalCard->getId());
    card->takeOver(slash);
    return card;
}

class Mumu : public TriggerSkill
{
public:
    Mumu() : TriggerSkill("mumu")
    {
        events << EventPhaseStart;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::Finish && player->getMark("damage_point_play_phase") == 0) {
            QList<ServerPlayer *> weapon_players, armor_players;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getWeapon() && player->canDiscard(p, p->getWeapon()->getEffectiveId()))
                    weapon_players << p;
                if (p != player && p->getArmor())
                    armor_players << p;
            }
            QStringList choices;
            choices << "cancel";
            if (!armor_players.isEmpty()) choices.prepend("armor");
            if (!weapon_players.isEmpty()) choices.prepend("weapon");
            if (choices.length() == 1) return false;
            QString choice = room->askForChoice(player, objectName(), choices.join("+"));
            if (choice == "cancel") {
                return false;
            } else {
                room->notifySkillInvoked(player, objectName());
                if (choice == "weapon") {
                    room->broadcastSkillInvoke(objectName(), 1);
                    ServerPlayer *victim = room->askForPlayerChosen(player, weapon_players, objectName(), "@mumu-weapon");
                    room->throwCard(victim->getWeapon(), victim, player);
                    player->drawCards(1, objectName());
                } else {
                    room->broadcastSkillInvoke(objectName(), 2);
                    ServerPlayer *victim = room->askForPlayerChosen(player, armor_players, objectName(), "@mumu-armor");
                    int equip = victim->getArmor()->getEffectiveId();
                    QList<CardsMoveStruct> exchangeMove;
                    CardsMoveStruct move1(equip, player, Player::PlaceEquip, CardMoveReason(CardMoveReason::S_REASON_ROB, player->objectName()));
                    exchangeMove.push_back(move1);
                    if (player->getArmor()) {
                        CardsMoveStruct move2(player->getArmor()->getEffectiveId(), NULL, Player::DiscardPile,
                            CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, player->objectName()));
                        exchangeMove.push_back(move2);
                    }
                    room->moveCardsAtomic(exchangeMove, true);
                }
            }
        }
        return false;
    }
};

YinbingCard::YinbingCard()
{
    will_throw = false;
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void YinbingCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->addToPile("yinbing", this);
}

class YinbingViewAsSkill : public ViewAsSkill
{
public:
    YinbingViewAsSkill() : ViewAsSkill("yinbing")
    {
        response_pattern = "@@yinbing";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return to_select->getTypeId() != Card::TypeBasic;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() == 0) return NULL;

        Card *acard = new YinbingCard;
        acard->addSubcards(cards);
        acard->setSkillName(objectName());
        return acard;
    }
};

class Yinbing : public TriggerSkill
{
public:
    Yinbing() : TriggerSkill("yinbing")
    {
        events << EventPhaseStart << Damaged;
        view_as_skill = new YinbingViewAsSkill;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Finish && !player->isNude()) {
            room->askForUseCard(player, "@@yinbing", "@yinbing", -1, Card::MethodNone);
        } else if (triggerEvent == Damaged && !player->getPile("yinbing").isEmpty()) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && (damage.card->isKindOf("Slash") || damage.card->isKindOf("Duel"))) {
                room->sendCompulsoryTriggerLog(player, objectName());

                QList<int> ids = player->getPile("yinbing");
                room->fillAG(ids, player);
                int id = room->askForAG(player, ids, false, objectName());
                room->clearAG(player);
                room->throwCard(id, NULL);
            }
        }

        return false;
    }
};

class Juedi : public PhaseChangeSkill
{
public:
    Juedi() : PhaseChangeSkill("juedi")
    {
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return PhaseChangeSkill::triggerable(target) && target->getPhase() == Player::Start
            && !target->getPile("yinbing").isEmpty();
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        if (!room->askForSkillInvoke(target, objectName())) return false;
        room->broadcastSkillInvoke(objectName());

        QList<ServerPlayer *> playerlist;
        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
            if (p->getHp() <= target->getHp())
                playerlist << p;
        }
        ServerPlayer *to_give = NULL;
        if (!playerlist.isEmpty())
            to_give = room->askForPlayerChosen(target, playerlist, objectName(), "@juedi", true);
        if (to_give) {
            room->recover(to_give, RecoverStruct(target));
            DummyCard *dummy = new DummyCard(target->getPile("yinbing"));
            room->obtainCard(to_give, dummy);
            delete dummy;
        } else {
            int len = target->getPile("yinbing").length();
            target->clearOnePrivatePile("yinbing");
            if (target->isAlive())
                room->drawCards(target, len, objectName());
        }
        return false;
    }
};

class Gongao : public TriggerSkill
{
public:
    Gongao() : TriggerSkill("gongao")
    {
        events << Death;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->broadcastSkillInvoke(objectName());
        room->sendCompulsoryTriggerLog(player, objectName());
        room->gainMaxHp(player);
        room->recover(player, RecoverStruct(player));
        return false;
    }
};

class Juyi : public PhaseChangeSkill
{
public:
    Juyi() : PhaseChangeSkill("juyi")
    {
        frequency = Wake;
        waked_skills = "benghuai,weizhong";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->isWounded() && player->getMaxHp() > player->aliveCount()) {
            LogMessage log;
            log.type = "#JuyiWake";
            log.from = player;
            log.arg = QString::number(player->getMaxHp());
            log.arg2 = QString::number(player->aliveCount());
            log.arg3 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *zhugedan) const
    {
        Room *room = zhugedan->getRoom();

        zhugedan->peiyin(objectName());
        room->notifySkillInvoked(zhugedan, objectName());
        //room->doLightbox("$JuyiAnimate");

        room->doSuperLightbox("zhugedan", "juyi");

        room->setPlayerMark(zhugedan, "juyi", 1);
        if (room->changeMaxHpForAwakenSkill(zhugedan, 0)) {
            int diff = zhugedan->getHandcardNum() - zhugedan->getMaxHp();
            if (diff < 0)
                room->drawCards(zhugedan, -diff, objectName());
            if (zhugedan->getMark("juyi") == 1)
                room->handleAcquireDetachSkills(zhugedan, "benghuai|weizhong");
        }

        return false;
    }
};

class Weizhong : public TriggerSkill
{
public:
    Weizhong() : TriggerSkill("weizhong")
    {
        events << MaxHpChanged;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->broadcastSkillInvoke(objectName());
        room->sendCompulsoryTriggerLog(player, objectName());

        player->drawCards(1, objectName());
        return false;
    }
};

class OLJuyi : public PhaseChangeSkill
{
public:
    OLJuyi() : PhaseChangeSkill("oljuyi")
    {
        frequency = Wake;
        waked_skills = "benghuai,olweizhong";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getMaxHp() > player->aliveCount()) {
            LogMessage log;
            log.type = "#JuyiWake";
            log.from = player;
            log.arg = QString::number(player->getMaxHp());
            log.arg2 = QString::number(player->aliveCount());
            log.arg3 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *zhugedan) const
    {
        Room *room = zhugedan->getRoom();
        zhugedan->peiyin(objectName());
        room->notifySkillInvoked(zhugedan, objectName());
        room->doSuperLightbox("ol_zhugedan", "oljuyi");

        room->setPlayerMark(zhugedan, "oljuyi", 1);
        if (room->changeMaxHpForAwakenSkill(zhugedan, 0)) {
            room->drawCards(zhugedan, zhugedan->getMaxHp(), objectName());
            room->handleAcquireDetachSkills(zhugedan, "benghuai|olweizhong");
        }
        return false;
    }
};

class OLWeizhong : public TriggerSkill
{
public:
    OLWeizhong() : TriggerSkill("olweizhong")
    {
        events << MaxHpChanged;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        room->sendCompulsoryTriggerLog(player, this);

        int x = 1, hand = player->getHandcardNum();
        bool min = true;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHandcardNum() < hand) {
                min = false;
                break;
            }
        }
        if (min)
            x = 2;

        player->drawCards(x, objectName());
        return false;
    }
};

XiemuCard::XiemuCard()
{
    target_fixed = true;
}

void XiemuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QString kingdom = room->askForKingdom(source, "xiemu");
    room->setPlayerMark(source, "@xiemu_" + kingdom, 1);
}

class XiemuViewAsSkill : public OneCardViewAsSkill
{
public:
    XiemuViewAsSkill() : OneCardViewAsSkill("xiemu")
    {
        filter_pattern = "Slash";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("XiemuCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        XiemuCard *card = new XiemuCard;
        card->addSubcard(originalCard);
        return card;
    }
};

class Xiemu : public TriggerSkill
{
public:
    Xiemu() : TriggerSkill("xiemu")
    {
        events << TargetConfirmed << EventPhaseStart;
        view_as_skill = new XiemuViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.from && player != use.from && use.card->getTypeId() != Card::TypeSkill
                && use.card->isBlack() && use.to.contains(player)
                && player->getMark("@xiemu_" + use.from->getKingdom()) > 0) {
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);

                room->notifySkillInvoked(player, objectName());
                player->drawCards(2, objectName());
            }
        } else {
            if (player->getPhase() == Player::RoundStart) {
                foreach (QString kingdom, Sanguosha->getKingdoms()) {
                    QString markname = "@xiemu_" + kingdom;
                    if (player->getMark(markname) > 0)
                        room->setPlayerMark(player, markname, 0);
                }
            }
        }
        return false;
    }
};

class Naman : public TriggerSkill
{
public:
    Naman() : TriggerSkill("naman")
    {
        events << BeforeCardsMove;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to_place != Player::DiscardPile) return false;
        const Card *to_obtain = NULL;
        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_RESPONSE) {
            if (move.from && player->objectName() == move.from->objectName())
                return false;
            to_obtain = move.reason.m_extraData.value<const Card *>();
            if (!to_obtain || !to_obtain->isKindOf("Slash"))
                return false;
        } else {
            return false;
        }
        if (to_obtain && room->askForSkillInvoke(player, objectName(), data)) {
            room->broadcastSkillInvoke(objectName());
            room->obtainCard(player, to_obtain);
            move.removeCardIds(move.card_ids);
            data = QVariant::fromValue(move);
        }

        return false;
    }
};

ShefuCard::ShefuCard()
{
    will_throw = false;
    target_fixed = true;
}

void ShefuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QString mark = "Shefu_" + user_string;
    source->setMark(mark, getEffectiveId() + 1);

    JsonArray arg;
    arg << source->objectName() << mark << (getEffectiveId() + 1);
    room->doNotify(source, QSanProtocol::S_COMMAND_SET_MARK, arg);

    source->addToPile("ambush", this, false);

    LogMessage log;
    log.type = "$ShefuRecord";
    log.from = source;
    log.card_str = QString::number(getEffectiveId());
    log.arg = user_string;
    room->sendLog(log, source);
}

ShefuDialog *ShefuDialog::getInstance(const QString &object)
{
    static ShefuDialog *instance;
    if (instance == NULL || instance->objectName() != object)
        instance = new ShefuDialog(object);

    return instance;
}

ShefuDialog::ShefuDialog(const QString &object)
    : GuhuoDialog(object, true, true, false, true, true)
{
}

bool ShefuDialog::isButtonEnabled(const QString &button_name) const
{
    return Self->getMark("Shefu_" + button_name) == 0;
}

class ShefuViewAsSkill : public OneCardViewAsSkill
{
public:
    ShefuViewAsSkill() : OneCardViewAsSkill("shefu")
    {
        filter_pattern = ".|.|.|hand";
        response_pattern = "@@shefu";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        const Card *c = Self->tag.value("shefu").value<const Card *>();
        if (c) {
            QString user_string = c->objectName();
            if (Self->getMark("Shefu_" + user_string) > 0)
                return NULL;

            ShefuCard *card = new ShefuCard;
            card->setUserString(user_string);
            card->addSubcard(originalCard);
            return card;
        } else
            return NULL;
    }
};

class Shefu : public PhaseChangeSkill
{
public:
    Shefu() : PhaseChangeSkill("shefu")
    {
        view_as_skill = new ShefuViewAsSkill;
    }

    bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        if (target->getPhase() != Player::Finish || target->isKongcheng())
            return false;
        room->askForUseCard(target, "@@shefu", "@shefu-prompt", -1, Card::MethodNone);
        return false;
    }

    QDialog *getDialog() const
    {
        return ShefuDialog::getInstance("shefu");
    }
};

class ShefuCancel : public TriggerSkill
{
public:
    ShefuCancel() : TriggerSkill("#shefu-cancel")
    {
        events << CardUsed << JinkEffect << NullificationEffect;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == JinkEffect) {
            bool invoked = false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (ShefuTriggerable(p, player)) {
                    room->setTag("ShefuData", data);
                    if (!room->askForSkillInvoke(p, "shefu_cancel", "data:::jink") || p->getMark("Shefu_jink") == 0)
                        continue;

                    room->broadcastSkillInvoke("shefu", 2);

                    invoked = true;

                    LogMessage log;
                    log.type = "#ShefuEffect";
                    log.from = p;
                    log.to << player;
                    log.arg = "jink";
                    log.arg2 = "shefu";
                    room->sendLog(log);

                    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "shefu", QString());
                    int id = p->getMark("Shefu_jink") - 1;
                    room->setPlayerMark(p, "Shefu_jink", 0);
                    room->throwCard(Sanguosha->getCard(id), reason, NULL);
                }
            }
            return invoked;
        } else if (triggerEvent == NullificationEffect) {
            bool invoked = false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (ShefuTriggerable(p, player)) {
                    room->setTag("ShefuData", data);
                    if (!room->askForSkillInvoke(p, "shefu_cancel", "data:::nullification") || p->getMark("Shefu_nullification") == 0)
                        continue;

                    room->broadcastSkillInvoke("shefu", 2);

                    invoked = true;

                    LogMessage log;
                    log.type = "#ShefuEffect";
                    log.from = p;
                    log.to << player;
                    log.arg = "nullification";
                    log.arg2 = "shefu";
                    room->sendLog(log);

                    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "shefu", QString());
                    int id = p->getMark("Shefu_nullification") - 1;
                    room->setPlayerMark(p, "Shefu_nullification", 0);
                    room->throwCard(Sanguosha->getCard(id), reason, NULL);
                }
            }
            return invoked;
        } else if (triggerEvent == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() != Card::TypeBasic && use.card->getTypeId() != Card::TypeTrick)
                return false;
            if (use.card->isKindOf("Nullification"))
                return false;
            QString card_name = use.card->objectName();
            if (card_name.contains("slash")) card_name = "slash";
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (ShefuTriggerable(p, player)) {
                    room->setTag("ShefuData", data);
                    if (!room->askForSkillInvoke(p, "shefu_cancel", "data:::" + card_name) || p->getMark("Shefu_" + card_name) == 0)
                        continue;

                    room->broadcastSkillInvoke("shefu", 2);

                    LogMessage log;
                    log.type = "#ShefuEffect";
                    log.from = p;
                    log.to << player;
                    log.arg = card_name;
                    log.arg2 = "shefu";
                    room->sendLog(log);

                    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "shefu", QString());
                    int id = p->getMark("Shefu_" + card_name) - 1;
                    room->setPlayerMark(p, "Shefu_" + card_name, 0);
                    room->throwCard(Sanguosha->getCard(id), reason, NULL);

                    use.nullified_list << "_ALL_TARGETS";
                }
            }
            data = QVariant::fromValue(use);
        }
        return false;
    }

    int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return 1;
    }

private:
    bool ShefuTriggerable(ServerPlayer *chengyu, ServerPlayer *user) const
    {
        return chengyu->getPhase() == Player::NotActive && chengyu != user
            && chengyu->hasSkill("shefu") && !chengyu->getPile("ambush").isEmpty();
    }
};

class BenyuViewAsSkill : public ViewAsSkill
{
public:
    BenyuViewAsSkill() : ViewAsSkill("benyu")
    {
        response_pattern = "@@benyu";
    }

    bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !to_select->isEquipped();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() < Self->getMark("benyu"))
            return NULL;

        DummyCard *card = new DummyCard;
        card->addSubcards(cards);
        return card;
    }
};

class Benyu : public MasochismSkill
{
public:
    Benyu() : MasochismSkill("benyu")
    {
        view_as_skill = new BenyuViewAsSkill;
    }

    void onDamaged(ServerPlayer *target, const DamageStruct &damage) const
    {
        if (!damage.from || damage.from->isDead())
            return;
        Room *room = target->getRoom();
        int from_handcard_num = damage.from->getHandcardNum(), handcard_num = target->getHandcardNum();
        QVariant data = QVariant::fromValue(damage);
        if (handcard_num == from_handcard_num) {
            return;
        } else if (handcard_num < from_handcard_num && handcard_num < 5 && room->askForSkillInvoke(target, objectName(), data)) {
            room->broadcastSkillInvoke(objectName(), 1);
            room->drawCards(target, qMin(5, from_handcard_num) - handcard_num, objectName());
        } else if (handcard_num > from_handcard_num) {
            room->setPlayerMark(target, objectName(), from_handcard_num + 1);
            //if (room->askForUseCard(target, "@@benyu", QString("@benyu-discard::%1:%2").arg(damage.from->objectName()).arg(from_handcard_num + 1), -1, Card::MethodDiscard)) 
            if (room->askForCard(target, "@@benyu", QString("@benyu-discard::%1:%2").arg(damage.from->objectName()).arg(from_handcard_num + 1), QVariant(), objectName())) {
                room->broadcastSkillInvoke(objectName(), 2);
                room->damage(DamageStruct(objectName(), target, damage.from));
            }
        }
        return;
    }
};

class FuluVS : public OneCardViewAsSkill
{
public:
    FuluVS() : OneCardViewAsSkill("fulu")
    {
        filter_pattern = "%slash";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE &&
                (pattern.contains("slash") || pattern.contains("Slash"));
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ThunderSlash *acard = new ThunderSlash(originalCard->getSuit(), originalCard->getNumber());
        acard->addSubcard(originalCard->getId());
        acard->setSkillName(objectName());
        return acard;
    }
};

class Fulu : public TriggerSkill
{
public:
    Fulu() : TriggerSkill("fulu")
    {
        events << ChangeSlash;
        view_as_skill = new FuluVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->objectName() != "slash") return false;
        bool has_changed = false;
        QString skill_name = use.card->getSkillName();
        if (!skill_name.isEmpty()) {
            const Skill *skill = Sanguosha->getSkill(skill_name);
            if (skill && !skill->inherits("FilterSkill") && !skill->objectName().contains("guhuo"))
                has_changed = true;
        }
        if (!has_changed || (use.card->isVirtualCard() && use.card->subcardsLength() == 0)) {
            ThunderSlash *thunder_slash = new ThunderSlash(use.card->getSuit(), use.card->getNumber());
            if (!use.card->isVirtualCard() || use.card->subcardsLength() > 0)
                thunder_slash->addSubcard(use.card);
            thunder_slash->setSkillName("fulu");
            bool can_use = true;
            foreach (ServerPlayer *p, use.to) {
                if (!player->canSlash(p, thunder_slash, false)) {
                    can_use = false;
                    break;
                }
            }
            if (can_use && room->askForSkillInvoke(player, "fulu", data, false)) {
                //room->broadcastSkillInvoke("fulu");
                use.card = thunder_slash;
                data = QVariant::fromValue(use);
            }
        }
        return false;
    }
};

class Zhuji : public TriggerSkill
{
public:
    Zhuji() : TriggerSkill("zhuji")
    {
        events << DamageCaused << FinishJudge;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature != DamageStruct::Thunder || !damage.from)
                return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (TriggerSkill::triggerable(p) && room->askForSkillInvoke(p, objectName(), data)) {
                    room->broadcastSkillInvoke(objectName());
                    JudgeStruct judge;
                    judge.good = true;
                    judge.play_animation = false;
                    judge.reason = objectName();
                    judge.pattern = ".";
                    judge.who = damage.from;

                    room->judge(judge);
                    if (judge.pattern == "black") {
                        LogMessage log;
                        log.type = "#ZhujiBuff";
                        log.from = p;
                        log.to << damage.to;
                        log.arg = QString::number(damage.damage);
                        log.arg2 = QString::number(++damage.damage);
                        room->sendLog(log);

                        data = QVariant::fromValue(damage);
                    }
                }
            }
        } else if (triggerEvent == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == objectName()) {
                judge->pattern = (judge->card->isRed() ? "red" : "black");
                if (room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge && judge->card->isRed())
                    player->obtainCard(judge->card);
            }
        }
        return false;
    }
};


class SpZhenwei : public TriggerSkill
{
public:
    SpZhenwei() : TriggerSkill("spzhenwei")
    {
        events << TargetConfirming << EventPhaseChanging;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (!p->getPile("zhenweipile").isEmpty()) {
                        DummyCard *dummy = new DummyCard(p->getPile("zhenweipile"));
                        room->obtainCard(p, dummy);
                        delete dummy;
                    }
                }
            }
            return false;
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card == NULL || use.to.length() != 1 || !(use.card->isKindOf("Slash") || (use.card->getTypeId() == Card::TypeTrick && use.card->isBlack())))
                return false;
            ServerPlayer *wp = room->findPlayerBySkillName(objectName());
            if (wp == NULL || wp->getHp() <= player->getHp())
                return false;
            if (!room->askForCard(wp, "..", QString("@sp_zhenwei:%1").arg(player->objectName()), data, objectName()))
                return false;
            room->broadcastSkillInvoke(objectName());
            QString choice = room->askForChoice(wp, objectName(), "draw+null", data);
            if (choice == "draw") {
                room->drawCards(wp, 1, objectName());

                if (use.card->isKindOf("Slash")) {
                    if (!use.from->canSlash(wp, use.card, false))
                        return false;
                }

                if (!use.card->isKindOf("DelayedTrick")) {
                    if (use.from->isProhibited(wp, use.card))
                        return false;

                    if (use.card->isKindOf("Collateral")) {
                        QList<ServerPlayer *> targets;
                        foreach (ServerPlayer *p, room->getOtherPlayers(wp)) {
                            if (wp->canSlash(p))
                                targets << p;
                        }

                        if (targets.isEmpty())
                            return false;

                        use.to.first()->tag.remove("collateralVictim");
                        ServerPlayer *target = room->askForPlayerChosen(use.from, targets, objectName(), QString("@dummy-slash2:%1").arg(wp->objectName()));
                        wp->tag["collateralVictim"] = QVariant::fromValue(target);

                        LogMessage log;
                        log.type = "#CollateralSlash";
                        log.from = use.from;
                        log.to << target;
                        room->sendLog(log);
                        room->doAnimate(1, wp->objectName(), target->objectName());
                    }
                    use.to = QList<ServerPlayer *>();
                    use.to << wp;
                    data = QVariant::fromValue(use);
                } else {
                    if (use.from->isProhibited(wp, use.card) || wp->containsTrick(use.card->objectName()))
                        return false;
                    room->moveCardTo(use.card, wp, Player::PlaceDelayedTrick, true);
                }
            } else {
                room->setCardFlag(use.card, "zhenweinull");
                use.from->addToPile("zhenweipile", use.card);

                use.nullified_list << "_ALL_TARGETS";
                data = QVariant::fromValue(use);
            }
            return false;
        }
        return false;
    }
};

class Junbing : public TriggerSkill
{
public:
    Junbing() : TriggerSkill("junbing")
    {
        events << EventPhaseStart;
    }

    bool triggerable(const ServerPlayer *player) const
    {
        return player && player->isAlive() && player->getPhase() == Player::Finish && player->getHandcardNum() <= 1;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        ServerPlayer *simalang = room->findPlayerBySkillName(objectName());
        if (!simalang || !simalang->isAlive())
            return false;
        if (player->askForSkillInvoke(this, QString("junbing_invoke:%1").arg(simalang->objectName()))) {
            room->broadcastSkillInvoke(objectName());
            room->notifySkillInvoked(simalang, objectName());
            player->drawCards(1);
            if (player->objectName() != simalang->objectName()) {
                DummyCard *cards = player->wholeHandCards();
                CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_GIVE, player->objectName());
                room->moveCardTo(cards, simalang, Player::PlaceHand, reason);

                int x = qMin(cards->subcardsLength(), simalang->getHandcardNum());

                if (x > 0) {
                    const Card *return_cards = room->askForExchange(simalang, objectName(), x, x, false, QString("@junbing-return:%1::%2").arg(player->objectName()).arg(cards->subcardsLength()));
                    CardMoveReason return_reason = CardMoveReason(CardMoveReason::S_REASON_GIVE, simalang->objectName());
                    room->moveCardTo(return_cards, player, Player::PlaceHand, return_reason);
                    delete return_cards;
                }
                delete cards;
            }
        }
        return false;
    }
};

QujiCard::QujiCard()
{
}

bool QujiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (subcardsLength() <= targets.length())
        return false;
    return to_select->isWounded();
}

bool QujiCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    if (targets.length() > 0) {
        foreach (const Player *p, targets) {
            if (!p->isWounded())
                return false;
        }
        return true;
    }
    return false;
}

void QujiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach(ServerPlayer *p, targets)
        room->cardEffect(this, source, p);

    foreach (int id, getSubcards()) {
        if (Sanguosha->getCard(id)->isBlack()) {
            room->loseHp(source);
            break;
        }
    }
}

void QujiCard::onEffect(const CardEffectStruct &effect) const
{
    RecoverStruct recover;
    recover.who = effect.from;
    recover.recover = 1;
    effect.to->getRoom()->recover(effect.to, recover);
}

class Quji : public ViewAsSkill
{
public:
    Quji() : ViewAsSkill("quji")
    {
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        return selected.length() < Self->getLostHp();
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->isWounded() && !player->hasUsed("QujiCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() == Self->getLostHp()) {
            QujiCard *quji = new QujiCard;
            quji->addSubcards(cards);
            return quji;
        }
        return NULL;
    }
};

class Canshi : public TriggerSkill
{
public:
    Canshi() : TriggerSkill("canshi")
    {
        events << EventPhaseStart << CardUsed << CardResponded;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Draw) {
                int n = 0;
                foreach (ServerPlayer *p, room->getAllPlayers()) {
                    if (p->isWounded())
                        ++n;
                }

                if (n > 0 && player->askForSkillInvoke(this)) {
                    room->broadcastSkillInvoke(objectName());
                    player->setFlags(objectName());
                    player->drawCards(n, objectName());
                    return true;
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
                if (card != NULL && (card->isKindOf("BasicCard") || card->isKindOf("TrickCard"))) {
                    room->sendCompulsoryTriggerLog(player, objectName());
                    if (!room->askForDiscard(player, objectName(), 1, 1, false, true, "@canshi-discard")) {
                        QList<const Card *> cards = player->getCards("he");
                        const Card *c = cards.at(qrand() % cards.length());
                        room->throwCard(c, player);
                    }
                }
            }
        }
        return false;
    }
};

class Chouhai : public TriggerSkill
{
public:
    Chouhai() : TriggerSkill("chouhai")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->isKongcheng()) {
            room->sendCompulsoryTriggerLog(player, objectName(), true);
            room->broadcastSkillInvoke(objectName());

            DamageStruct damage = data.value<DamageStruct>();
            ++damage.damage;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class Guiming : public TriggerSkill // play audio effect only. This skill is coupled in Player::isWounded().
{
public:
    Guiming() : TriggerSkill("guiming$")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && target->hasLordSkill(this) && target->getPhase() == Player::RoundStart;
    }

    int getPriority(TriggerEvent) const
    {
        return 6;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        foreach (const ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getKingdom() == "wu" && p->isWounded() && p->getHp() == p->getMaxHp()) {
                if (player->hasSkill("weidi"))
                    room->broadcastSkillInvoke("weidi");
                else
                    room->broadcastSkillInvoke(objectName());
                return false;
            }
        }

        return false;
    }
};

class Conqueror : public TriggerSkill
{
public:
    Conqueror() : TriggerSkill("conqueror")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card != NULL && use.card->isKindOf("Slash")) {
            int n = 0;
            foreach (ServerPlayer *target, use.to) {
                if (player->askForSkillInvoke(this, QVariant::fromValue(target))) {
                    QString choice = room->askForChoice(player, objectName(), "BasicCard+EquipCard+TrickCard", QVariant::fromValue(target));

                    room->broadcastSkillInvoke(objectName(), 1);

                    const Card *c = room->askForCard(target, choice, QString("@conqueror-exchange:%1::%2").arg(player->objectName()).arg(choice), choice, Card::MethodNone);
                    if (c != NULL) {
                        room->broadcastSkillInvoke(objectName(), 2);
                        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), objectName(), QString());
                        room->obtainCard(player, c, reason);
                        use.nullified_list << target->objectName();
                        data = QVariant::fromValue(use);
                    } else {
                        room->broadcastSkillInvoke(objectName(), 3);
                        QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();
                        jink_list[n] = 0;
                        player->tag["Jink_" + use.card->toString()] = jink_list;
                        LogMessage log;
                        log.type = "#NoJink";
                        log.from = target;
                        room->sendLog(log);
                    }
                }
                ++n;
            }
        }
        return false;
    }
};

class Fentian : public PhaseChangeSkill
{
public:
    Fentian() : PhaseChangeSkill("fentian")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *hanba) const
    {
        if (hanba->getPhase() != Player::Finish)
            return false;

        if (hanba->getHandcardNum() >= hanba->getHp())
            return false;

        QList<ServerPlayer*> targets;
        Room* room = hanba->getRoom();

        foreach (ServerPlayer *p, room->getOtherPlayers(hanba)) {
            if (hanba->inMyAttackRange(p) && !p->isNude())
                targets << p;
        }

        if (targets.isEmpty())
            return false;

        room->broadcastSkillInvoke(objectName());
        ServerPlayer *target = room->askForPlayerChosen(hanba, targets, objectName(), "@fentian-choose", false, true);
        int id = room->askForCardChosen(hanba, target, "he", objectName());
        hanba->addToPile("burn", id);
        return false;
    }
};

class FentianRange : public AttackRangeSkill
{
public:
    FentianRange() : AttackRangeSkill("#fentian")
    {

    }

    int getExtra(const Player *target, bool) const
    {
        if (target->hasSkill(this))
            return target->getPile("burn").length();

        return 0;
    }
};

class Zhiri : public PhaseChangeSkill
{
public:
    Zhiri() : PhaseChangeSkill("zhiri")
    {
        frequency = Wake;
        waked_skills = "xintan";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        if (player->getPile("burn").length() >= 3) {
            LogMessage log;
            log.from = player;
            log.type = "#ZhiriWake";
            log.arg = QString::number(player->getPile("burn").length());
            log.arg2 = objectName();
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *hanba) const
    {
        Room *room = hanba->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("hanba", "zhiri");

        room->setPlayerMark(hanba, objectName(), 1);
        if (room->changeMaxHpForAwakenSkill(hanba) && hanba->getMark("zhiri") > 0)
            room->acquireSkill(hanba, "xintan");

        return false;
    }

};

XintanCard::XintanCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool XintanCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void XintanCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *hanba = effect.from;
    Room *room = hanba->getRoom();

    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, hanba->objectName(), objectName(), QString());
    room->moveCardTo(this, NULL, Player::DiscardPile, reason, true);

    room->loseHp(effect.to);
}

class Xintan : public ViewAsSkill
{
public:
    Xintan() : ViewAsSkill("xintan")
    {
        expand_pile = "burn";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getPile("burn").length() >= 2 && !player->hasUsed("XintanCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() < 2)
            return Self->getPile("burn").contains(to_select->getId());

        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() == 2) {
            XintanCard *xt = new XintanCard;
            xt->addSubcards(cards);
            return xt;
        }

        return NULL;
    }
};

class Shajue : public TriggerSkill
{
public:
    Shajue() : TriggerSkill("shajue")
    {
        events << Dying;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who == player || dying.who->getHp() >= 0) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        player->gainMark("&brutal");
        if (!dying.damage || !dying.damage->card) return false;
        if (dying.damage->card->isKindOf("SkillCard") || !room->CardInTable(dying.damage->card)) return false;
        room->obtainCard(player, dying.damage->card);
        return false;
    }
};

XionghuoCard::XionghuoCard()
{
}

bool XionghuoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getMark("&brutal") <= 0 && to_select != Self;
}

void XionghuoCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->getMark("&brutal") < 0) return;
    effect.from->loseMark("&brutal");
    effect.to->gainMark("&brutal");
}

class XionghuoViewAsSkill : public ZeroCardViewAsSkill
{
public:
    XionghuoViewAsSkill() : ZeroCardViewAsSkill("xionghuo")
    {
    }

    const Card *viewAs() const
    {
        return new XionghuoCard;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("&brutal") > 0;
    }
};

class Xionghuo : public TriggerSkill
{
public:
    Xionghuo() : TriggerSkill("xionghuo")
    {
        events << DamageCaused << EventPhaseStart;
        view_as_skill = new XionghuoViewAsSkill;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->hasSkill(objectName()) && player->isAlive() && player->getMark("&brutal") > 0) {
                    room->sendCompulsoryTriggerLog(p, "xionghuo", true, true);
                    player->loseAllMarks("&brutal");
                    int i = qrand() % 3;
                    LogMessage log;
                    log.type = "#XionghuoEffect";
                    log.from = player;
                    log.arg = "xionghuo";
                    if (i == 0) {
                        log.arg2 = "xionghuo_choice0";
                        room->sendLog(log);
                        room->damage(DamageStruct(objectName(), p, player, 1, DamageStruct::Fire));
                        if (player->isAlive()) {
                            room->setPlayerMark(player, "xionghuo_from-Clear", 1);
                            room->setPlayerMark(p, "xionghuo_to-Clear", 1);
                        }
                    } else if (i == 1) {
                        log.arg2 = "xionghuo_choice1";
                        room->sendLog(log);
                        room->loseHp(player);
                        if (player->isAlive())
                            room->addMaxCards(player, -1);
                    } else {
                        log.arg2 = "xionghuo_choice2";
                        room->sendLog(log);
                        DummyCard *dummy = new DummyCard;
                        if (player->hasEquip()) {
                            int i = qrand() % player->getEquips().length();
                            dummy->addSubcard(player->getEquips().at(i));
                        }
                        if (!player->isKongcheng())
                            dummy->addSubcard(player->getRandomHandCardId());
                        if (dummy->subcardsLength() > 0)
                            room->obtainCard(p, dummy, false);
                        delete dummy;
                    }
                }
            }
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.from->hasSkill(objectName()) || damage.from == damage.to || damage.to->getMark("&brutal") <= 0) return false;
            LogMessage log;
            log.type = "#XionghuoDamage";
            log.from = damage.from;
            log.to << damage.to;
            log.arg = "xionghuo";
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class XionghuoMark : public GameStartSkill
{
public:
    XionghuoMark() : GameStartSkill("#xionghuomark")
    {
    }

    void onGameStart(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, "xionghuo", true, true);
        player->gainMark("&brutal", 3);
    }
};

class XionghuoPro : public ProhibitSkill
{
public:
    XionghuoPro() : ProhibitSkill("#xionghuopro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return card->isKindOf("Slash") && from->getMark("xionghuo_from-Clear") > 0 && to->getMark("xionghuo_to-Clear") > 0;
    }
};

class Falu : public TriggerSkill
{
public:
    Falu() : TriggerSkill("falu")
    {
        events << GameStart << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GameStart) {
            bool send = false;
            if (player->getMark("@flziwei") <= 0) {
                if (!send) {
                    send = true;
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                }
                player->gainMark("@flziwei");
            }
            if (player->getMark("@flhoutu") <= 0) {
                if (!send) {
                    send = true;
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                }
                player->gainMark("@flhoutu");
            }
            if (player->getMark("@flyuqing") <= 0) {
                if (!send) {
                    send = true;
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                }
                player->gainMark("@flyuqing");
            }
            if (player->getMark("@flgouchen") <= 0) {
                if (!send) {
                    send = true;
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                }
                player->gainMark("@flgouchen");
            }
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && move.to_place == Player::DiscardPile &&
            (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD &&
                    (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))) {
                bool send = false;
                for (int i = 0; i < move.card_ids.length(); i++) {
                    if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                        const Card *c = Sanguosha->getCard(move.card_ids.at(i));
                        if (c->getSuit() == Card::Spade) {
                            if (player->getMark("@flziwei") <= 0) {
                                if (!send) {
                                    send = true;
                                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                                }
                                player->gainMark("@flziwei");
                            }
                        } else if (c->getSuit() == Card::Club) {
                            if (player->getMark("@flhoutu") <= 0) {
                                if (!send) {
                                    send = true;
                                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                                }
                                player->gainMark("@flhoutu");
                            }
                        } else if (c->getSuit() == Card::Heart) {
                            if (player->getMark("@flyuqing") <= 0) {
                                if (!send) {
                                    send = true;
                                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                                }
                                player->gainMark("@flyuqing");
                            }
                        } else if (c->getSuit() == Card::Diamond) {
                            if (player->getMark("@flgouchen") <= 0) {
                                if (!send) {
                                    send = true;
                                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                                }
                                player->gainMark("@flgouchen");
                            }
                        }
                    }
                }
            }
        }
        return false;
    }
};

class ZhenyiVS : public OneCardViewAsSkill
{
public:
    ZhenyiVS() : OneCardViewAsSkill("zhenyi")
    {
        filter_pattern = ".|.|.|hand";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "peach+analeptic" && !player->hasFlag("Global_PreventPeach") && player->getMark("@flhoutu") > 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Peach *peach = new Peach(originalCard->getSuit(), originalCard->getNumber());
        peach->addSubcard(originalCard->getId());
        peach->setSkillName(objectName());
        return peach;
    }
};

class Zhenyi : public TriggerSkill
{
public:
    Zhenyi() : TriggerSkill("zhenyi")
    {
        events << AskForRetrial << DamageCaused << Damaged << PreCardUsed;
        view_as_skill = new ZhenyiVS;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageCaused) {
            if (player->getMark("@flyuqing") > 0) {
                player->tag["flyuqing"] = data;
                DamageStruct damage = data.value<DamageStruct>();
                bool invoke = player->askForSkillInvoke(this, QString("flyuqing:%1").arg(damage.to->objectName()));
                player->tag.remove("flyuqing");
                if (!invoke) return false;
                room->broadcastSkillInvoke(objectName());
                player->loseMark("@flyuqing");
                JudgeStruct judge;
                judge.pattern = ".|black";
                judge.who = player;
                judge.reason = objectName();
                judge.good = true;
                room->judge(judge);
                if (judge.isGood()) {
                    ++damage.damage;
                    data = QVariant::fromValue(damage);
                }
            }
        } else if (event == AskForRetrial) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (player->getMark("@flziwei") > 0) {
                player->tag["flziwei"] = data;
                bool invoke = player->askForSkillInvoke(this, QString("flziwei:%1").arg(judge->who->objectName()));
                player->tag.remove("flziwei");
                if (!invoke) return false;
                room->broadcastSkillInvoke(objectName());
                player->loseMark("@flziwei");
                QString choice = room->askForChoice(player, objectName(), "spade+heart", data);

                WrappedCard *new_card = Sanguosha->getWrappedCard(judge->card->getId());
                new_card->setSkillName("zhenyi");
                new_card->setNumber(5);
                new_card->setModified(true);
                new_card->deleteLater();

                if (choice == "spade")
                    new_card->setSuit(Card::Spade);
                else
                    new_card->setSuit(Card::Heart);

                LogMessage log;
                log.type = "#ZhenyiRetrial";
                log.from = player;
                log.to << judge->who;
                log.arg2 = QString::number(5);
                log.arg = new_card->getSuitString();
                room->sendLog(log);
                room->broadcastUpdateCard(room->getAllPlayers(true), judge->card->getId(), new_card);
                judge->updateResult();
            }
        } else if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName() != objectName()) return false;
            player->loseMark("@flhoutu");
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature == DamageStruct::Normal) return false;
            if (player->getMark("@flgouchen") <= 0 || !player->askForSkillInvoke(this, QString("flgouchen"))) return false;
            room->broadcastSkillInvoke(objectName());
            player->loseMark("@flgouchen");

            QList<int> basic, equip, trick;
            foreach (int id, room->getDrawPile()) {
                const Card *c = Sanguosha->getCard(id);
                if (c->isKindOf("BasicCard"))
                    basic << id;
                else if (c->isKindOf("EquipCard"))
                    equip << id;
                else if (c->isKindOf("TrickCard"))
                    trick << id;
            }

            DummyCard *dummy = new DummyCard;
            if (!basic.isEmpty())
                dummy->addSubcard(basic.at(qrand() % basic.length()));
            if (!equip.isEmpty())
                dummy->addSubcard(equip.at(qrand() % equip.length()));
            if (!trick.isEmpty())
                dummy->addSubcard(trick.at(qrand() % trick.length()));

            if (dummy->subcardsLength() > 0)
                room->obtainCard(player, dummy, false);
            delete dummy;
        }
        return false;
    }
};

class Dianhua : public PhaseChangeSkill
{
public:
    Dianhua() : PhaseChangeSkill("dianhua")
    {
        frequency = Frequent;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Start && player->getPhase() != Player::Finish) return false;
        int x = 0;
        if (player->getMark("@flziwei") > 0)
            x++;
        if (player->getMark("@flhoutu") > 0)
            x++;
        if (player->getMark("@flyuqing") > 0)
            x++;
        if (player->getMark("@flgouchen") > 0)
            x++;
        if (x == 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->askForGuanxing(player, room->getNCards(x, false), Room::GuanxingUpOnly);
        return false;
    }
};

class TenyearZhenyiVS : public OneCardViewAsSkill
{
public:
    TenyearZhenyiVS() : OneCardViewAsSkill("tenyearzhenyi")
    {
        filter_pattern = ".|.|.|hand";
        response_or_use = true;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern.contains("peach") && !player->hasFlag("Global_PreventPeach") && player->getMark("@flhoutu") > 0 &&
                player->getPhase() == Player::NotActive;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Peach *peach = new Peach(originalCard->getSuit(), originalCard->getNumber());
        peach->addSubcard(originalCard->getId());
        peach->setSkillName(objectName());
        return peach;
    }
};

class TenyearZhenyi : public TriggerSkill
{
public:
    TenyearZhenyi() : TriggerSkill("tenyearzhenyi")
    {
        events << AskForRetrial << DamageCaused << Damaged << PreCardUsed;
        view_as_skill = new TenyearZhenyiVS;
    }

    int getPriority(TriggerEvent triggerEvent) const
    {
        if (triggerEvent == PreCardUsed)
            return 5;
        return TriggerSkill::getPriority(triggerEvent);
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageCaused) {
            if (player->getMark("@flyuqing") > 0) {
                player->tag["flyuqing_tenyear"] = data;
                DamageStruct damage = data.value<DamageStruct>();
                bool invoke = player->askForSkillInvoke(this, QString("flyuqing:%1").arg(damage.to->objectName()));
                player->tag.remove("flyuqing_tenyear");
                if (!invoke) return false;
                room->broadcastSkillInvoke(objectName());
                player->loseMark("@flyuqing");
                ++damage.damage;
                data = QVariant::fromValue(damage);
            }
        } else if (event == AskForRetrial) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (player->getMark("@flziwei") > 0) {
                player->tag["flziwei_tenyear"] = data;
                bool invoke = player->askForSkillInvoke("tenyearzhenyi", QString("flziwei:%1").arg(judge->who->objectName()));
                player->tag.remove("flziwei_tenyear");
                if (!invoke) return false;
                room->broadcastSkillInvoke(objectName());
                player->loseMark("@flziwei");
                QString choice = room->askForChoice(player, "zhenyi", "spade+heart", data);

                WrappedCard *new_card = Sanguosha->getWrappedCard(judge->card->getId());
                new_card->setSkillName("tenyearzhenyi");
                new_card->setNumber(5);
                new_card->setModified(true);
                new_card->deleteLater();

                if (choice == "spade")
                    new_card->setSuit(Card::Spade);
                else
                    new_card->setSuit(Card::Heart);

                LogMessage log;
                log.type = "#ZhenyiRetrial";
                log.from = player;
                log.to << judge->who;
                log.arg2 = QString::number(5);
                log.arg = new_card->getSuitString();
                room->sendLog(log);
                room->broadcastUpdateCard(room->getAllPlayers(true), judge->card->getId(), new_card);
                judge->updateResult();
            }
        } else if (event == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName() != objectName()) return false;
            player->loseMark("@flhoutu");
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature == DamageStruct::Normal) return false;
            if (player->getMark("@flgouchen") <= 0 || !player->askForSkillInvoke("zhenyi", QString("flgouchen"))) return false;
            room->broadcastSkillInvoke(objectName());
            player->loseMark("@flgouchen");

            QList<int> basic, equip, trick;
            foreach (int id, room->getDrawPile()) {
                const Card *c = Sanguosha->getCard(id);
                if (c->isKindOf("BasicCard"))
                    basic << id;
                else if (c->isKindOf("EquipCard"))
                    equip << id;
                else if (c->isKindOf("TrickCard"))
                    trick << id;
            }

            DummyCard *dummy = new DummyCard;
            if (!basic.isEmpty())
                dummy->addSubcard(basic.at(qrand() % basic.length()));
            if (!equip.isEmpty())
                dummy->addSubcard(equip.at(qrand() % equip.length()));
            if (!trick.isEmpty())
                dummy->addSubcard(trick.at(qrand() % trick.length()));

            if (dummy->subcardsLength() > 0)
                room->obtainCard(player, dummy, false);
            delete dummy;
        }
        return false;
    }
};

class Zhidao : public TriggerSkill
{
public:
    Zhidao() : TriggerSkill("zhidao")
    {
        events << Damage;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() != Player::Play || player->getMark("zhidao-PlayClear") > 0) return false;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to == player) return false;
        room->addPlayerMark(player, "zhidao-PlayClear");

        if (damage.to->isDead() || damage.to->isAllNude()) return false;
        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
        DummyCard get;
        if (!damage.to->isKongcheng()) {
            int id = room->askForCardChosen(player, damage.to, "h", objectName());
            get.addSubcard(id);
        }
        if (!damage.to->getEquips().isEmpty()) {
            int id = room->askForCardChosen(player, damage.to, "e", objectName());
            get.addSubcard(id);
        }
        if (!damage.to->getJudgingArea().isEmpty()) {
            int id = room->askForCardChosen(player, damage.to, "j", objectName());
            get.addSubcard(id);
        }
        if (get.subcardsLength() > 0) {
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, &get, reason, false);
            room->addPlayerMark(player, "zhidao-Clear");
        }
        return false;
    }
};

class ZhidaoPro : public ProhibitSkill
{
public:
    ZhidaoPro() : ProhibitSkill("#zhidao-pro")
    {
    }

    bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        return from->getMark("zhidao-Clear") > 0 && from != to && !card->isKindOf("SkillCard");
    }
};

class SpJili : public TriggerSkill
{
public:
    SpJili() : TriggerSkill("spjili")
    {
        events << TargetConfirming;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || !use.card->isRed()) return false;
        if (!use.card->isKindOf("BasicCard") && !use.card->isNDTrick()) return false;

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || use.to.contains(p) || use.from == p || !p->hasSkill(this)) continue;
            if (player->distanceTo(p) != 1) return false;
            if (use.from && use.from->isAlive() && use.from->isProhibited(p, use.card)) continue;
            int n = 1;
            if (use.card->isKindOf("Peach") || use.card->isKindOf("ExNihilo") || use.card->isKindOf("Analeptic"))
                n = 2;
            //room->sendCompulsoryTriggerLog(p, objectName(), true, true, n);
            LogMessage log;
            log.type = "#SPJiliAdd";
            log.from = p;
            log.to << use.from;
            log.arg = objectName();
            log.arg2 = use.card->objectName();
            room->sendLog(log);
            room->notifySkillInvoked(p, objectName());
            room->broadcastSkillInvoke(objectName(), n);
            room->doAnimate(1, use.from->objectName(), p->objectName());

            use.to.append(p);
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
            room->getThread()->trigger(TargetConfirming, room, p, data);
        }
        return false;
    }
};

LianzhuCard::LianzhuCard(QString lianzhu) : lianzhu(lianzhu)
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void LianzhuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    int id = getSubcards().first();
    room->showCard(effect.from, id);
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), lianzhu, QString());
    room->obtainCard(effect.to, this, reason, true);
    if (effect.to->isDead()) return;
    const Card *card = Sanguosha->getCard(id);
    if (!card->isBlack()) {
        if (lianzhu == "tenyearlianzhu" && card->isRed())
            effect.from->drawCards(1, lianzhu);
        return;
    }
    effect.to->tag["LianzhuFrom"] = QVariant::fromValue(effect.from);
    const Card *dis = room->askForDiscard(effect.to, lianzhu, 2, 2, true, true, "lianzhu-discard:" + effect.from->objectName());
    effect.to->tag.remove("LianzhuFrom");
    if (dis) return;
    effect.from->drawCards(2, lianzhu);
}

TenyearLianzhuCard::TenyearLianzhuCard() : LianzhuCard("tenyearlianzhu")
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

class Lianzhu : public OneCardViewAsSkill
{
public:
    Lianzhu(const QString &lianzhu) : OneCardViewAsSkill(lianzhu), lianzhu(lianzhu)
    {
        filter_pattern = ".";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (lianzhu == "lianzhu")
            return !player->hasUsed("LianzhuCard");
        else if (lianzhu == "tenyearlianzhu")
            return !player->hasUsed("TenyearLianzhuCard");
        else
            return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (lianzhu == "lianzhu") {
            LianzhuCard *card = new LianzhuCard;
            card->addSubcard(originalCard);
            return card;
        } else if (lianzhu == "tenyearlianzhu") {
            TenyearLianzhuCard *card = new TenyearLianzhuCard;
            card->addSubcard(originalCard);
            return card;
        }
        return NULL;
    }
private:
    QString lianzhu;
};

class Xiahui : public TriggerSkill
{
public:
    Xiahui(const QString &xiahui) : TriggerSkill(xiahui), xiahui(xiahui)
    {
        events << EventPhaseProceeding << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseProceeding) {
            if (player->getPhase() != Player::Discard) return false;
            QList<int> blacks;
            foreach (int id, player->handCards()) {
                if (Sanguosha->getCard(id)->isBlack())
                    blacks << id;
            }
            if (blacks.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, this);
            room->ignoreCards(player, blacks);
        } else {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from == player && player->isAlive() &&
                    (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))) {
                if (move.to && move.to->isAlive() && move.to_place == Player::PlaceHand) {
                    ServerPlayer *to = (ServerPlayer *)move.to;
                    if (!to || to->isDead()) return false;
                    QString string = xiahui + "_limited" + player->objectName();
                    QVariantList limited = to->tag[string].toList();
                    for (int i = 0; i < move.card_ids.length(); i++) {
                        if (!Sanguosha->getCard(move.card_ids.at(i))->isBlack()) continue;
                        if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                            if (!limited.contains(QVariant(move.card_ids.at(i))))
                                limited << move.card_ids.at(i);
                        }
                    }
                    if (limited.isEmpty()) return false;
                    room->sendCompulsoryTriggerLog(player, this);
                    to->tag[string] = limited;

                    QList<int> limit_ids = VariantList2IntList(limited);
                    foreach (int id, limit_ids)
                        room->setPlayerCardLimitation(to, "use,response,discard", QString::number(id), false);
                }
            }
        }
        return false;
    }
private:
    QString xiahui;
};

class XiahuiClear : public TriggerSkill
{
public:
    XiahuiClear(const QString &xiahui) : TriggerSkill("#" + xiahui + "-clear"), xiahui(xiahui)
    {
        events << EventLoseSkill << HpChanged << Death << EventPhaseEnd;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventLoseSkill) {
            if (player->isDead() || data.toString() != xiahui) return false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                QString string = xiahui + "_limited" + player->objectName();
                QVariantList limited = p->tag[string].toList();
                if (limited.isEmpty()) continue;
                QList<int> limit_ids = VariantList2IntList(limited);
                p->tag.remove(string);

                foreach (int id, limit_ids) {
                    room->removePlayerCardLimitation(p, "use,response,discard", QString::number(id) + "$0");
                }
            }
        } else if (event == HpChanged) {
            if (player->isDead() || data.isNull() || data.canConvert<RecoverStruct>()) return false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                QString string = xiahui + "_limited" + p->objectName();
                QVariantList limited = player->tag[string].toList();
                if (limited.isEmpty()) continue;
                QList<int> limit_ids = VariantList2IntList(limited);
                player->tag.remove(string);

                foreach (int id, limit_ids) {
                    room->removePlayerCardLimitation(player, "use,response,discard", QString::number(id) + "$0");
                }
            }
        } else if (event == EventPhaseEnd) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (player->isDead()) return false;
                if (p->isDead() || !p->hasSkill("tenyearxiahui") || player->getMark("tenyearxiahui_lose_" + p->objectName() + "-Clear") <=0)
                    continue;
                QString string = "tenyearxiahui_limited" + p->objectName();
                QVariantList limited = player->tag[string].toList();
                if (limited.isEmpty()) continue;
                QList<int> limited_ids = VariantList2IntList(limited);
                bool contain = false;
                foreach (int id, player->handCards()) {
                    if (limited_ids.contains(id)) {
                        contain = true;
                        break;
                    }
                }
                if (contain) continue;
                room->sendCompulsoryTriggerLog(p, "tenyearxiahui", true, true);
                room->loseHp(player);
            }
        } else {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player && player->hasSkill("xiahui")) {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    QString string = xiahui + "_limited" + player->objectName();
                    QVariantList limited = p->tag[string].toList();
                    if (limited.isEmpty()) continue;
                    QList<int> limit_ids = VariantList2IntList(limited);
                    p->tag.remove(string);

                    foreach (int id, limit_ids) {
                        room->removePlayerCardLimitation(p, "use,response,discard", QString::number(id) + "$0");
                    }
                }
            } else {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    QString string = xiahui + "_limited" + p->objectName();
                    QVariantList limited = player->tag[string].toList();
                    if (limited.isEmpty()) continue;
                    QList<int> limit_ids = VariantList2IntList(limited);
                    player->tag.remove(string);

                    foreach (int id, limit_ids) {
                        room->removePlayerCardLimitation(player, "use,response,discard", QString::number(id) + "$0");
                    }
                }
            }
        }
        return false;
    }
private:
    QString xiahui;
};

class TenyearXiahuiMove : public TriggerSkill
{
public:
    TenyearXiahuiMove() : TriggerSkill("#tenyearxiahui-move")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from->isDead()) return false;
        if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)) return false;
        ServerPlayer *from = (ServerPlayer *)move.from;
        QString string = "tenyearxiahui_limited" + player->objectName();
        QVariantList limited = from->tag[string].toList();
        if (limited.isEmpty()) return false;
        QList<int> limited_ids = VariantList2IntList(limited);

        for (int i = 0; i < move.card_ids.length(); i++) {
            if (move.from_places.at(i) != Player::PlaceHand && move.from_places.at(i) != Player::PlaceEquip) continue;
            if (!limited_ids.contains(move.card_ids.at(i))) continue;
            room->addPlayerMark(from, "tenyearxiahui_lose_" + player->objectName() + "-Clear");
            break;
        }
        return false;
    }
};

class Fuqi : public TriggerSkill
{
public:
    Fuqi() : TriggerSkill("fuqi")
    {
        events << CardUsed;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;

        QList<ServerPlayer *> tos;
        foreach (ServerPlayer *p, room->getOtherPlayers(use.from)) {
            if (p->distanceTo(use.from) != 1) continue;
            tos << p;
            use.no_respond_list << p->objectName();
        }
        if (tos.isEmpty()) return false;

        LogMessage log;
        log.type = "#FuqiNoResponse";
        log.from = use.from;
        log.arg = objectName();
        log.card_str = use.card->toString();
        log.to = tos;
        room->sendLog(log);
        room->notifySkillInvoked(use.from, objectName());
        room->broadcastSkillInvoke(objectName());

        data = QVariant::fromValue(use);
        return false;
    }
};

class Jiaozi : public TriggerSkill
{
public:
    Jiaozi() : TriggerSkill("jiaozi")
    {
        events << DamageCaused << DamageInflicted;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        int hand = player->getHandcardNum();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHandcardNum() >= hand && p != player)
                return false;
        }

        LogMessage log;
        log.from = player;
        log.arg = objectName();
        if (event == DamageCaused) {
            if (damage.to->isDead()) return false;
            log.type = "#JiaoziDoDamage";
            log.to << damage.to;
        } else {
            log.type = "#JiaoziSufferDamage";
        }
        log.arg2 = QString::number(++damage.damage);
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());

        data = QVariant::fromValue(damage);
        return false;
    }
};

class Zongkui : public TriggerSkill
{
public:
    Zongkui() : TriggerSkill("zongkui")
    {
        events << EventPhaseStart << RoundStart;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return false;
            QList<ServerPlayer *> players;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getMark("&kui") <= 0)
                    players << p;
            }
            if (players.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@zongkui-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            target->gainMark("&kui");
        } else {
            int hp = player->getHp();
            QList<ServerPlayer *> players;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHp() < hp)
                    hp = p->getHp();
            }
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->getHp() == hp && p->getMark("&kui") <= 0)
                    players << p;
            }
            if (players.isEmpty()) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@zongkui-trigger");
            room->doAnimate(1, player->objectName(), target->objectName());
            target->gainMark("&kui");
        }
        return false;
    }
};

class Guju : public MasochismSkill
{
public:
    Guju() : MasochismSkill("guju")
    {
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &) const
    {
        if (player->getMark("&kui") <= 0) return;
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            room->sendCompulsoryTriggerLog(p, objectName(), true, true);
            p->drawCards(1, objectName());
        }
    }
};

class Baijia : public PhaseChangeSkill
{
public:
    Baijia() : PhaseChangeSkill("baijia")
    {
        frequency = Wake;
        waked_skills = "spcanshi";
    }

    bool canWake(TriggerEvent, ServerPlayer *player, QVariant &, Room *room) const
    {
        if (player->getPhase() != Player::Start || player->getMark(objectName()) > 0) return false;
        if (player->canWake(objectName())) return true;
        int mark = player->getMark("&baijia_num") + player->getMark("baijia_num");
        if (mark >= 7) {
            LogMessage log;
            log.type = "#BaijiaWake";
            log.from = player;
            log.arg = objectName();
            log.arg2 = QString::number(mark);
            room->sendLog(log);
            return true;
        }
        return false;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("beimihu", objectName());
        room->addPlayerMark(player, objectName());
        if (room->changeMaxHpForAwakenSkill(player, 1)) {
            room->recover(player, RecoverStruct(player));
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isAlive() && p->getMark("&kui") <= 0)
                    p->gainMark("&kui");
            }
            room->handleAcquireDetachSkills(player, "-guju|spcanshi");
        }
        return false;
    }
};

class BaijiaRecord : public TriggerSkill
{
public:
    BaijiaRecord() : TriggerSkill("#baijia")
    {
        events << CardsMoveOneTime;
        //frequency = Wake;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.to && move.to->isAlive() && move.to == player && move.to_place == Player::PlaceHand && move.reason.m_skillName == "guju") {
            if (player->hasSkill("baijia", true))
                room->addPlayerMark(player, "&baijia_num", move.card_ids.length());
            else
                room->addPlayerMark(player, "baijia_num", move.card_ids.length());
        }
        return false;
    }
};

SpCanshiCard::SpCanshiCard()
{
}

bool SpCanshiCard::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const
{
    QStringList names = Self->property("spcanshi_ava").toString().split("+");
    return to_select->getMark("&kui") > 0 && names.contains(to_select->objectName());
}

void SpCanshiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    foreach (ServerPlayer *p, card_use.to) {
        room->doAnimate(1, card_use.from->objectName(), p->objectName());
        room->setPlayerFlag(p, "spcanshi_extra");
    }
}

class SpCanshiVS : public ZeroCardViewAsSkill
{
public:
    SpCanshiVS() : ZeroCardViewAsSkill("spcanshi")
    {
        response_pattern = "@@spcanshi";
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        return new SpCanshiCard;
    }
};

class SpCanshi : public TriggerSkill
{
public:
    SpCanshi() : TriggerSkill("spcanshi")
    {
        events << TargetSpecifying;
        view_as_skill = new SpCanshiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("BasicCard") && !use.card->isNDTrick()) return false;
        if (use.card->isKindOf("Collateral")) return false;
        if (use.to.length() != 1) return false;
        if (use.from->hasSkill(this)) {
            QStringList ava;
            room->setCardFlag(use.card, "spcanshi_distance");
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if ((use.card->isKindOf("AOE") && p == use.from) || p->getMark("&kui") <= 0) continue;
                if (use.to.contains(p) || room->isProhibited(use.from, p, use.card)) continue;
                if (use.card->targetFixed()) {
                    if (!use.card->isKindOf("Peach") || p->isWounded())
                        ava << p->objectName();
                } else {
                    if (use.card->targetFilter(QList<const Player *>(), p, use.from))
                        ava << p->objectName();
                }
            }
            room->setCardFlag(use.card, "-spcanshi_distance");
            if (ava.isEmpty()) return false;
            QString names = ava.join("+");
            room->setPlayerProperty(player, "spcanshi_ava", names);
            player->tag["SPCanshiForAI"] = data;
            if (!room->askForUseCard(player, "@@spcanshi", "@spcanshi:" + use.card->objectName())) {
                room->setPlayerProperty(player, "spcanshi_ava", QString());
                player->tag.remove("SPCanshiForAI");
            } else {
                room->setPlayerProperty(player, "spcanshi_ava", QString());
                player->tag.remove("SPCanshiForAI");
                QList<ServerPlayer *> tos;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (p->hasFlag("spcanshi_extra")) {
                        room->setPlayerFlag(p, "-spcanshi_extra");
                        use.to.append(p);
                        tos << p;
                    }
                }
                if (tos.isEmpty()) return false;
                room->sortByActionOrder(tos);
                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
                LogMessage log;
                log.type = "#QiaoshuiAdd";
                log.from = player;
                log.to = tos;
                log.card_str = use.card->toString();
                log.arg = objectName();
                room->sendLog(log);
                room->broadcastSkillInvoke(objectName());
                room->notifySkillInvoked(player, objectName());
                foreach (ServerPlayer *p, tos) {
                    if (p->getMark("&kui") > 0)
                        p->loseAllMarks("&kui");
                }
            }
        } else {
            if (!use.to.first()->hasSkill(this) || use.from->getMark("&kui") <= 0) return false;
            use.to.first()->tag["SPCanshi"] = data;
            bool invoke = use.to.first()->askForSkillInvoke(this, QVariant::fromValue(use.from));
            use.to.first()->tag.remove("SPCanshi");
            if (!invoke) return false;
            room->broadcastSkillInvoke(objectName());
            use.to.removeOne(use.to.first());
            data = QVariant::fromValue(use);
            use.from->loseAllMarks("&kui");
        }
        return false;
    }
};

class SpCanshiMod : public TargetModSkill
{
public:
    SpCanshiMod() : TargetModSkill("#spcanshi-target")
    {
        frequency = NotFrequent;
        pattern = ".";
    }

    int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (card->hasFlag("spcanshi_distance") && from->hasSkill("spcanshi"))
            return 1000;
        else
            return 0;
    }
};

class Xiefang : public DistanceSkill
{
public:
    Xiefang() : DistanceSkill("xiefang")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill(this)) {
            int x=0;
            QList<const Player *> players = from->getAliveSiblings();
            players << from;
            foreach (const Player *p, players) {
                if (p->isFemale())
                    x++;
            }
            return -x;
        } else
            return 0;
    }
};

class Zhengnan : public TriggerSkill
{
public:
    Zhengnan() : TriggerSkill("zhengnan")
    {
        events << Death;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *guansuo, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        ServerPlayer *player = death.who;
        if (guansuo == player) return false;
        if (guansuo->isAlive() && room->askForSkillInvoke(guansuo, objectName(), data)) {
            room->broadcastSkillInvoke(objectName());
            QStringList choices;
            choices << "draw";
            if (!guansuo->hasSkill("wusheng", true)) choices << "wusheng";
            if (!guansuo->hasSkill("dangxian", true)) choices << "dangxian";
            if (!guansuo->hasSkill("zhiman"), true) choices << "zhiman";
            if (choices.isEmpty()) return false;
            QString choice = room->askForChoice(guansuo, "zhengnan", choices.join("+"), QVariant());
            if (choice == "draw")
                guansuo->drawCards(3, objectName());
            else {
                if (!guansuo->hasSkill(choice, true))
                    room->handleAcquireDetachSkills(guansuo, choice);
            }
        }
        return false;
    }
};

class OLZhengnan : public TriggerSkill
{
public:
    OLZhengnan() : TriggerSkill("olzhengnan")
    {
        events << Death;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *guansuo, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        ServerPlayer *player = death.who;
        if (guansuo == player) return false;
        if (guansuo->isAlive() && room->askForSkillInvoke(guansuo, objectName(), data)) {
            room->broadcastSkillInvoke(objectName());
            guansuo->drawCards(3, objectName());
            if (guansuo->isDead()) return false;
            QStringList choices;
            if (!guansuo->hasSkill("wusheng", true)) choices << "wusheng";
            if (!guansuo->hasSkill("dangxian", true)) choices << "dangxian";
            if (!guansuo->hasSkill("zhiman", true)) choices << "zhiman";
            if (choices.isEmpty()) return false;
            QString choice = room->askForChoice(guansuo, "olzhengnan", choices.join("+"), QVariant());
            if (!guansuo->hasSkill(choice))
                room->handleAcquireDetachSkills(guansuo, choice);
        }
        return false;
    }
};

class TenyearZhengnan : public TriggerSkill
{
public:
    TenyearZhengnan() : TriggerSkill("tenyearzhengnan")
    {
        events << Dying;
        frequency = Frequent;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *guansuo, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        QStringList names = guansuo->property("tenyearzhengnan_names").toStringList();
        if (names.contains(dying.who->objectName())) return false;
        if (!guansuo->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        names << dying.who->objectName();
        room->setPlayerProperty(guansuo, "tenyearzhengnan_names", names);
        room->recover(guansuo, RecoverStruct(guansuo));
        guansuo->drawCards(1, objectName());
        QStringList choices;
        if (!guansuo->hasSkill("tenyearwusheng", true)) choices << "wusheng";
        if (!guansuo->hasSkill("tenyeardangxian", true)) choices << "dangxian";
        if (!guansuo->hasSkill("tenyearzhiman", true)) choices << "zhiman";
        if (choices.isEmpty())
            guansuo->drawCards(3, objectName());
        else {
            QString choice = room->askForChoice(guansuo, "tenyearzhengnan", choices.join("+"), QVariant());
            if (!guansuo->hasSkill("tenyear" + choice, true))
                room->handleAcquireDetachSkills(guansuo, "tenyear" + choice);
        }
        return false;
    }
};

class MeiyingMark : public TriggerSkill
{
public:
    MeiyingMark() : TriggerSkill("meiyingmark")
    {
        events << MarkChanged;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        MarkStruct mark = data.value<MarkStruct>();
        if (mark.name == "&meiying" && mark.gain < 0)
            room->addPlayerMark(player, "meiying", -mark.gain);
        return false;
    }
};

FanghunCard::FanghunCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "fanghun";
}

bool FanghunCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
    CardUseStruct::CardUseReason reason = Sanguosha->currentRoomState()->getCurrentCardUseReason();

    if (this->subcardsLength() != 0 && (reason == CardUseStruct::CARD_USE_REASON_PLAY || (reason == CardUseStruct::CARD_USE_REASON_RESPONSE_USE &&
                                   (pattern.contains("slash") || pattern.contains("Slash"))))) {
        Slash *slash = new Slash(NoSuit, 0);
        slash->setSkillName("_longdan");
        slash->addSubcards(this->getSubcards());
        slash->deleteLater();
        return slash->targetFilter(targets, to_select, Self);
    }
    return false;
}

bool FanghunCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    CardUseStruct::CardUseReason reason = Sanguosha->currentRoomState()->getCurrentCardUseReason();
    QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();

    if (reason == CardUseStruct::CARD_USE_REASON_PLAY || (reason == CardUseStruct::CARD_USE_REASON_RESPONSE_USE &&
                                         (pattern.contains("slash") || pattern.contains("Slash")))) {
        const Card *card = Sanguosha->getCard(this->getSubcards().first());
        Slash *slash = new Slash(card->getSuit(), card->getNumber());
        slash->setSkillName("_longdan");
        slash->addSubcard(card);
        slash->deleteLater();
        QList<const Player *> players;
        foreach (const Player *p, targets) {
            players <<p;
        }
        return slash->targetsFeasible(players, Self);
    } else {
        return targets.length() == 0;
    }
}

const Card *FanghunCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;
    Room *room = player->getRoom();

    CardUseStruct::CardUseReason reason = Sanguosha->currentRoomState()->getCurrentCardUseReason();
    QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();

    if (reason == CardUseStruct::CARD_USE_REASON_PLAY || (reason == CardUseStruct::CARD_USE_REASON_RESPONSE_USE &&
                                            (pattern.contains("slash") || pattern.contains("Slash")))) {
        const Card *card = Sanguosha->getCard(this->getSubcards().first());
        Slash *slash = new Slash(card->getSuit(), card->getNumber());
        slash->setSkillName("_longdan");
        slash->addSubcard(card);
        slash->setFlags("JINGYIN");
        for (int i = card_use.to.length() - 1; i >=0 ; i--) {
            if (!player->canSlash(card_use.to.at(i)))
                card_use.to.removeOne(card_use.to.at(i));
        }
        slash->deleteLater();
        if (card_use.to.isEmpty()) return NULL;
        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = m_skillName;
        room->sendLog(log);
        room->notifySkillInvoked(player, m_skillName);
        room->broadcastSkillInvoke(m_skillName);
        player->loseMark("&meiying");
        room->setPlayerMark(player, m_skillName + "_id", this->getSubcards().first() + 1);
        //room->useCard(CardUseStruct(slash, player, card_use.to), player->getPhase() == Player::Play);
       // player->drawCards(1, objectName());
        return slash;
    } else {
        const Card *card = Sanguosha->getCard(this->getSubcards().first());
        Jink *jink = new Jink(card->getSuit(), card->getNumber());
        jink->setSkillName("_longdan");
        jink->addSubcard(card);
        jink->setFlags("JINGYIN");
        jink->deleteLater();
        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = m_skillName;
        room->sendLog(log);
        room->notifySkillInvoked(player, m_skillName);
        room->broadcastSkillInvoke(m_skillName);
        player->loseMark("&meiying");
        room->setPlayerMark(player, m_skillName + "_id", this->getSubcards().first() + 1);
        return jink;
    }
    return NULL;
}

const Card *FanghunCard::validateInResponse(ServerPlayer *player) const
{
    Room *room = player->getRoom();
    QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();

    if (pattern == "jink") {
        const Card *card = Sanguosha->getCard(this->getSubcards().first());
        Jink *jink = new Jink(card->getSuit(), card->getNumber());
        jink->setSkillName("_longdan");
        jink->addSubcard(card);
        jink->setFlags("JINGYIN");
        jink->deleteLater();
        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = m_skillName;
        room->sendLog(log);
        room->notifySkillInvoked(player, m_skillName);
        room->broadcastSkillInvoke(m_skillName);
        player->loseMark("&meiying");
        room->setPlayerMark(player, m_skillName + "_id", this->getSubcards().first() + 1);
        return jink;
    } else {
        const Card *card = Sanguosha->getCard(this->getSubcards().first());
        Slash *slash = new Slash(card->getSuit(), card->getNumber());
        slash->setSkillName("_longdan");
        slash->addSubcard(card);
        slash->setFlags("JINGYIN");
        slash->deleteLater();
        LogMessage log;
        log.type = "#InvokeSkill";
        log.from = player;
        log.arg = m_skillName;
        room->sendLog(log);
        room->notifySkillInvoked(player, m_skillName);
        room->broadcastSkillInvoke(m_skillName);
        player->loseMark("&meiying");
        room->setPlayerMark(player, m_skillName + "_id", this->getSubcards().first() + 1);
        return slash;
    }
    return NULL;
}

class FanghunViewAsSkill : public OneCardViewAsSkill
{
public:
    FanghunViewAsSkill(const QString &fanghun_skill) : OneCardViewAsSkill(fanghun_skill), fanghun_skill(fanghun_skill)
    {
        response_or_use = true;
    }

    bool viewFilter(const Card *to_select) const
    {
        const Card *card = to_select;

        switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
        case CardUseStruct::CARD_USE_REASON_PLAY: {
            return card->isKindOf("Jink");
        }
        case CardUseStruct::CARD_USE_REASON_RESPONSE:
        case CardUseStruct::CARD_USE_REASON_RESPONSE_USE: {
            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern.contains("slash") || pattern.contains("Slash"))
                return card->isKindOf("Jink");
            else if (pattern == "jink")
                return card->isKindOf("Slash");
        }
        default:
            return false;
        }
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player) && player->getMark("&meiying") > 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return (pattern == "jink" || pattern.contains("slash") || pattern.contains("Slash")) && player->getMark("&meiying") > 0;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        if (fanghun_skill == "fanghun") {
            FanghunCard *card = new FanghunCard;
            card->addSubcard(originalCard);
            return card;
        }
        if (fanghun_skill == "olfanghun") {
            OLFanghunCard *card = new OLFanghunCard;
            card->addSubcard(originalCard);
            return card;
        }
        if (fanghun_skill == "mobilefanghun") {
            MobileFanghunCard *card = new MobileFanghunCard;
            card->addSubcard(originalCard);
            return card;
        }
        if (fanghun_skill == "tenyearfanghun") {
            TenyearFanghunCard *card = new TenyearFanghunCard;
            card->addSubcard(originalCard);
            return card;
        }
        return NULL;
    }

private:
    QString fanghun_skill;
};

class FanghunDraw : public TriggerSkill
{
public:
    FanghunDraw(const QString &fanghun_skill) : TriggerSkill("#" + fanghun_skill), fanghun_skill(fanghun_skill)
    {
        events << CardResponded << CardFinished;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    int getPriority(TriggerEvent) const
    {
        return 0;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardResponded) {
            const Card *card = data.value<CardResponseStruct>().m_card;
            int id = card->getEffectiveId();
            foreach(ServerPlayer *p, room->getAllPlayers()) {
                int marks = p->getMark(fanghun_skill + "_id") - 1;
                if (marks < 0) continue;
                if (marks == id) {
                    room->setPlayerMark(player, fanghun_skill + "_id", 0);
                    p->drawCards(1, objectName());
                    break;
                }
            }
        } else if (triggerEvent == CardFinished) {
            const Card *card = data.value<CardUseStruct>().card;
            int id = card->getEffectiveId();
            foreach(ServerPlayer *p, room->getAllPlayers()) {
                int marks = p->getMark(fanghun_skill + "_id") - 1;
                if (marks < 0) continue;
                if (marks == id) {
                    room->setPlayerMark(player, fanghun_skill + "_id", 0);
                    p->drawCards(1, objectName());
                    break;
                }
            }
        }
        return false;
    }

private:
    QString fanghun_skill;
};

class Fanghun : public TriggerSkill
{
public:
    Fanghun() : TriggerSkill("fanghun")
    {
        events << Damage << Damaged;
        view_as_skill = new FanghunViewAsSkill("fanghun");
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash")) return false;
        if ((triggerEvent == Damage && damage.by_user) || triggerEvent == Damaged) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&meiying");
        }
        return false;
     }
};

class Fuhan : public PhaseChangeSkill
{
public:
    Fuhan() : PhaseChangeSkill("fuhan")
    {
        frequency = Limited;
        limit_mark = "@fuhanMark";
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        if (player->getMark("@fuhanMark") <= 0 || player->getMark("&meiying") <= 0) return false;
        QString num = QString::number(player->getMark("meiying") + player->getMark("&meiying"));
        if (!player->askForSkillInvoke("fuhan", QString("fuhan_invoke:%1").arg(num))) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("zhaoxiang", "fuhan");
        room->removePlayerMark(player, "@fuhanMark");
        int meiying = player->getMark("&meiying");
        player->loseAllMarks("&meiying");
        player->drawCards(meiying, objectName());
        QStringList shus = Sanguosha->getLimitedGeneralNames("shu");
        QStringList five_shus;
        for (int i = 1; i < 6; i++) {
            if (shus.isEmpty()) break;
            QString name = shus.at((qrand() % shus.length()));
            five_shus << name;
            shus.removeOne(name);
        }
        if (five_shus.isEmpty()) return false;
        QString shu_general = room->askForGeneral(player, five_shus);
        room->changeHero(player, shu_general, false, false, (player->getGeneralName() != "zhaoxiang" && player->getGeneral2Name() == "zhaoxiang"));
        int n = player->getMark("meiying");
        room->setPlayerProperty(player, "maxhp", n);
        int hp = player->getHp();
        bool recover = true;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHp() < hp) {
                recover = false;
                break;
            }
        }
        if (recover == false) return false;
        room->recover(player, RecoverStruct(player));
        return false;
    }
};

OLFanghunCard::OLFanghunCard() : FanghunCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "olfanghun";
}

class OLFanghun : public TriggerSkill
{
public:
    OLFanghun() : TriggerSkill("olfanghun")
    {
        events << Damage << Damaged;
        view_as_skill = new FanghunViewAsSkill("olfanghun");
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == Damage || triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if ((triggerEvent == Damage && damage.by_user) || triggerEvent == Damaged) {
                room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                player->gainMark("&meiying", damage.damage);
            }
        }
        return false;
     }
};

class OLFuhan : public PhaseChangeSkill
{
public:
    OLFuhan() : PhaseChangeSkill("olfuhan")
    {
        frequency = Limited;
        limit_mark = "@olfuhanMark";
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        if (player->getMark("@olfuhanMark") <= 0 || player->getMark("&meiying") <= 0) return false;
        int nn = player->getMark("meiying") + player->getMark("&meiying");
        nn = qMin(8, nn);
        nn = qMax(2, nn);
        QString num = QString::number(nn);
        if (!player->askForSkillInvoke("olfuhan", QString("olfuhan_invoke:%1").arg(num))) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("ol_zhaoxiang", "olfuhan");
        room->removePlayerMark(player, "@olfuhanMark");
        player->loseAllMarks("&meiying");
        QStringList shus = Sanguosha->getLimitedGeneralNames("shu");
        QStringList five_shus;
        for (int i = 1; i < 6; i++) {
            if (shus.isEmpty()) break;
            QString name = shus.at((qrand() % shus.length()));
            five_shus << name;
            shus.removeOne(name);
        }
        if (five_shus.isEmpty()) return false;
        QString shu_general = room->askForGeneral(player, five_shus);
        room->changeHero(player, shu_general, false, false, (player->getGeneralName() != "ol_zhaoxiang" && player->getGeneral2Name() == "ol_zhaoxiang"));
        int n = player->getMark("meiying");
        n = qMin(8, n);
        n = qMax(2, n);
        room->setPlayerProperty(player, "maxhp", n);
        room->recover(player, RecoverStruct(player));
        return false;
    }
};

MobileFanghunCard::MobileFanghunCard() : FanghunCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "mobilefanghun";
}

class MobileFanghun : public TriggerSkill
{
public:
    MobileFanghun() : TriggerSkill("mobilefanghun")
    {
        events << Damage;
        view_as_skill = new FanghunViewAsSkill("mobilefanghun");
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.card || !damage.card->isKindOf("Slash")) return false;
        if (damage.by_user) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&meiying", 1);
        }
        return false;
     }
};

class MobileFuhan : public PhaseChangeSkill
{
public:
    MobileFuhan() : PhaseChangeSkill("mobilefuhan")
    {
        frequency = Limited;
        limit_mark = "@mobilefuhanMark";
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart) return false;
        if (player->getMark("@mobilefuhanMark") <= 0) return false;

        Room *room = player->getRoom();
        int nn = player->getMark("meiying") + player->getMark("&meiying");
        if (nn <= 0) return false;
        nn = qMin(room->getPlayers().length(), nn);
        QString num = QString::number(nn);
        if (!player->askForSkillInvoke("mobilefuhan", QString("mobilefuhan_invoke:%1").arg(num))) return false;
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("mobile_zhaoxiang", "mobilefuhan");
        room->removePlayerMark(player, "@mobilefuhanMark");
        player->loseAllMarks("&meiying");

        QStringList shus = Sanguosha->getLimitedGeneralNames("shu");
        foreach (QString name, shus) {
            if (hasshu(name, room))
                shus.removeOne(name);
        }
        QStringList five_shus;
        for (int i = 1; i < 6; i++) {
            if (shus.isEmpty()) break;
            QString name = shus.at((qrand() % shus.length()));
            five_shus << name;
            shus.removeOne(name);
        }
        if (five_shus.isEmpty()) return false;
        QString shu_general = room->askForGeneral(player, five_shus);
        room->changeHero(player, shu_general, false, false, (player->getGeneralName() != "mobile_zhaoxiang" && player->getGeneral2Name() == "mobile_zhaoxiang"));
        int n = player->getMark("meiying");
        n = qMin(room->getPlayers().length(), n);
        room->setPlayerProperty(player, "maxhp", n);
        if (!player->isLowestHpPlayer()) return false;
        room->recover(player, RecoverStruct(player));
        return false;
    }

    bool hasshu(const QString name, Room *room) const
    {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getGeneralName() == name || p->getGeneral2Name() == name)
                return true;
        }
        return false;
    }
};

TenyearFanghunCard::TenyearFanghunCard() : FanghunCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "tenyearfanghun";
}

class TenyearFanghun : public TriggerSkill
{
public:
    TenyearFanghun() : TriggerSkill("tenyearfanghun")
    {
        events << TargetSpecified << TargetConfirmed;
        view_as_skill = new FanghunViewAsSkill("tenyearfanghun");
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return false;
        if (triggerEvent == TargetSpecified || (triggerEvent == TargetConfirmed && use.to.contains(player))) {
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->gainMark("&meiying", 1);
        }
        return false;
     }
};

class TenyearFuhan : public PhaseChangeSkill
{
public:
    TenyearFuhan() : PhaseChangeSkill("tenyearfuhan")
    {
        frequency = Limited;
        limit_mark = "@tenyearfuhanMark";
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::RoundStart || player->getMark("@tenyearfuhanMark") <= 0 ||
                player->getMark("&meiying") <= 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("tenyear_zhaoxiang", "tenyearfuhan");
        room->removePlayerMark(player, "@tenyearfuhanMark");
        int mark = player->getMark("&meiying");
        player->loseAllMarks("&meiying");
        player->drawCards(mark, objectName());

        if (!player->askForSkillInvoke("tenyearfuhan", QString("getskill"), false)) {
            if (!player->isLowestHpPlayer()) return false;
            room->recover(player, RecoverStruct(player));
            return false;
        }

        QStringList all_shus = Sanguosha->getLimitedGeneralNames("shu");
        foreach (QString shu, all_shus) {
            const General *g = Sanguosha->getGeneral(shu);
            if (!g || g->getVisibleSkillList().isEmpty())
                all_shus.removeOne(shu);
        }
        if (all_shus.isEmpty()) return false;

        int n = room->alivePlayerCount();
        n = qMax(n, 4);
        QStringList shus;
        for (int i = 1; i <= n; i++) {
            if (all_shus.isEmpty()) break;
            QString name = all_shus.at((qrand() % all_shus.length()));
            shus << name;
            all_shus.removeOne(name);
        }
        if (shus.isEmpty()) return false;

        for (int i = 1; i <= 2; i++) {
            if (shus.isEmpty() || player->isDead()) break;

            QString shu_general = room->askForGeneral(player, shus);
            const General *g = Sanguosha->getGeneral(shu_general);
            if (!g) {
                shus.removeOne(shu_general);
                continue;
            }
            QList<const Skill *> sks = g->getVisibleSkillList();
            if (sks.isEmpty()) {
                shus.removeOne(shu_general);
                continue;
            }
            QStringList sk_names;
            foreach (const Skill *sk, sks) {
                if (sk_names.contains(sk->objectName()) || player->hasSkill(sk, true)) continue;
                if (sk->isLimitedSkill() || sk->isLordSkill() || sk->getFrequency() == Skill::Wake) continue;
                sk_names << sk->objectName();
            }
            if (sk_names.isEmpty()) {
                shus.removeOne(shu_general);
                continue;
            }
            QString sk = room->askForChoice(player, objectName(), sk_names.join("+"));
            sk_names.removeOne(sk);
            if (sk_names.isEmpty())
                shus.removeOne(shu_general);

            room->acquireSkill(player, sk);
            if (i == 1) {
                if (!player->askForSkillInvoke("tenyearfuhan", QString("continue"), false))
                    break;
            }
        }

        if (!player->isLowestHpPlayer()) return false;
        room->recover(player, RecoverStruct(player));
        return false;
    }
};

class Wuniang : public TriggerSkill
{
public:
    Wuniang() : TriggerSkill("wuniang")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card;
        if (triggerEvent == CardUsed) card = data.value<CardUseStruct>().card;
        else card = data.value<CardResponseStruct>().m_card;
        if (!card || !card->isKindOf("Slash")) return false;
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isNude())
                players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@wuniang-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        if (target->isNude()) return false;
        int id = room->askForCardChosen(player, target, "he", objectName());
        room->obtainCard(player, id, false);
        if (target->isAlive()) target->drawCards(1, objectName());
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getGeneralName().contains("guansuo") || p->getGeneral2Name().contains("guansuo"))
                p->drawCards(1, objectName());
        }
        return false;
    }
};

class Xushen : public TriggerSkill
{
public:
    Xushen() : TriggerSkill("xushen")
    {
        events << QuitDying;
        frequency = Limited;
        limit_mark = "@xushenMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getMark("@xushenMark") <= 0) return false;
        ServerPlayer *saver = player->getSaver();
        if (!saver || !saver->isMale() || saver == player) return false;
        bool guansuo = false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getGeneralName().contains("guansuo") || p->getGeneral2Name().contains("guansuo")) {
                guansuo = true;
                break;
            }
        }
        if (guansuo) return false;
        if (!saver->askForSkillInvoke(objectName(), player, false)) return false;
        LogMessage log;
        log.type = "#InvokeOthersSkill";
        log.from = saver;
        log.to << player;
        log.arg = "xushen";
        room->sendLog(log);
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("baosanniang", "xushen");
        room->removePlayerMark(player, "@xushenMark");
        room->changeHero(saver, "guansuo", false, false);
        room->recover(player, RecoverStruct(player));
        if (!player->hasSkill("zhennan", true))
            room->handleAcquireDetachSkills(player, "zhennan");
        return false;
    }
};

class Zhennan : public TriggerSkill
{
public:
    Zhennan() : TriggerSkill("zhennan")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card = data.value<CardUseStruct>().card;
        if (!card->isKindOf("SavageAssault")) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@zhennan-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        int n = qrand() % 3 + 1;
        room->damage(DamageStruct(objectName(), player, target, n));
        return false;
    }
};

class Shuyong : public TriggerSkill
{
public:
    Shuyong() : TriggerSkill("shuyong")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card;
        if (triggerEvent == CardUsed)
            card = data.value<CardUseStruct>().card;
        else
            card = data.value<CardResponseStruct>().m_card;
        if (!card || !card->isKindOf("Slash")) return false;
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isAllNude())
                players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@shuyong-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        if (target->isAllNude()) return false;
        int id = room->askForCardChosen(player, target, "hej", objectName());
        room->obtainCard(player, id, false);
        if (target->isAlive())
            target->drawCards(1, objectName());
        return false;
    }
};

MobileXushenCard::MobileXushenCard()
{
    target_fixed = true;
}

void MobileXushenCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->doSuperLightbox("mobile_baosanniang", "mobilexushen");
    room->removePlayerMark(source, "@mobilexushenMark");
    int male = 0;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (!p->isMale()) continue;
        male++;
    }
    if (male <= 0) return;
    try {
        room->setPlayerFlag(source, "mobilexushen");
        room->loseHp(source, male);
        if (source->hasFlag("mobilexushen"))
            room->setPlayerFlag(source, "-mobilexushen");
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
            if (source->hasFlag("mobilexushen"))
                room->setPlayerFlag(source, "-mobilexushen");
        }
        throw triggerEvent;
    }
}

class MobileXushenVS : public ZeroCardViewAsSkill
{
public:
    MobileXushenVS() : ZeroCardViewAsSkill("mobilexushen")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("@mobilexushenMark") <= 0) return false;
        QList<const Player *> as = player->getAliveSiblings();
        as << player;
        foreach (const Player *p, as) {
            if (p->isMale())
                return true;
        }
        return false;
    }

    const Card *viewAs() const
    {
        return new MobileXushenCard;
    }
};

class MobileXushen : public TriggerSkill
{
public:
    MobileXushen() : TriggerSkill("mobilexushen")
    {
        events << QuitDying;
        frequency = Limited;
        limit_mark = "@mobilexushenMark";
        view_as_skill = new MobileXushenVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!player->hasFlag("mobilexushen")) return false;
        room->setPlayerFlag(player, "-mobilexushen");
        ServerPlayer *saver = player->getSaver();
        if (!saver) return false;
        if (!player->askForSkillInvoke(objectName(), QString("mobilexushen:%1").arg(saver->objectName()))) return false;
        QStringList skills;
        skills << "wusheng" << "dangxian";
        room->handleAcquireDetachSkills(saver, skills);
        return false;
    }
};

class MoboleZhennan : public TriggerSkill
{
public:
    MoboleZhennan() : TriggerSkill("mobolezhennan")
    {
        events << TargetSpecified;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard")) return false;
        if (use.to.length() <= 1) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (use.to.length() <= player->getHp()) return false;
            if (p->isDead() || !p->hasSkill(this) || !use.to.contains(p)) continue;
            if (!p->canDiscard(p, "he")) continue;
            if (!room->askForCard(p, "..", "@mobolezhennan-discard:" + player->objectName(), data, objectName())) continue;
            room->broadcastSkillInvoke(objectName());
            room->damage(DamageStruct(objectName(), p, player));
        }
        return false;
    }
};

class TenyearXushen : public TriggerSkill
{
public:
    TenyearXushen() : TriggerSkill("tenyearxushen")
    {
        events << QuitDying;
        frequency = Limited;
        limit_mark = "@tenyearxushenMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getMark("@tenyearxushenMark") <= 0) return false;
        ServerPlayer *saver = player->getSaver();
        if (!saver || saver == player) return false;
        bool guansuo = false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getGeneralName().contains("guansuo") || p->getGeneral2Name().contains("guansuo")) {
                guansuo = true;
                break;
            }
        }
        if (guansuo) return false;

        if (!player->askForSkillInvoke(objectName(), QVariant::fromValue(saver))) return false;
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("tenyear_baosanniang", "tenyearxushen");
        room->removePlayerMark(player, "@tenyearxushenMark");
        if (saver->askForSkillInvoke("tenyearxushenChange", "guansuo"))
            room->changeHero(saver, "tenyear_guansuo", false, false);
        saver->drawCards(3, objectName());
        room->recover(player, RecoverStruct(player));
        if (!player->hasSkill("tenyearzhennan", true))
            room->handleAcquireDetachSkills(player, "tenyearzhennan");
        return false;
    }
};

class TenyearZhennan : public TriggerSkill
{
public:
    TenyearZhennan() : TriggerSkill("tenyearzhennan")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("TrickCard") || !use.to.contains(player)) return false;
        if (use.to.length() <= 1) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@tenyearzhennan-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        room->damage(DamageStruct(objectName(), player, target));
        return false;
    }
};

class SecondWuniang : public TriggerSkill
{
public:
    SecondWuniang() : TriggerSkill("secondwuniang")
    {
        events << CardUsed << CardResponded;
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        const Card *card;
        if (triggerEvent == CardUsed) card = data.value<CardUseStruct>().card;
        else card = data.value<CardResponseStruct>().m_card;
        if (!card || !card->isKindOf("Slash")) return false;
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isNude())
                players << p;
        }
        if (players.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@wuniang-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        if (target->isNude()) return false;
        int id = room->askForCardChosen(player, target, "he", objectName());
        room->obtainCard(player, id, false);
        if (target->isAlive()) target->drawCards(1, objectName());
        if (!player->tag["secondxushen_used"].toBool()) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getGeneralName().contains("guansuo") || p->getGeneral2Name().contains("guansuo"))
                p->drawCards(1, objectName());
        }
        return false;
    }
};

class SecondXushen : public TriggerSkill
{
public:
    SecondXushen() : TriggerSkill("secondxushen")
    {
        events << Dying;
        frequency = Limited;
        limit_mark = "@secondxushenMark";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (player != dying.who || player->getMark("@secondxushenMark") <= 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        player->tag["secondxushen_used"] = true;
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("second_tenyear_baosanniang", "secondxushen");
        room->removePlayerMark(player, "@secondxushenMark");
        room->recover(player, RecoverStruct(player));
        if (player->isDead()) return false;
        room->acquireSkill(player, "secondzhennan");
        if (player->isDead()) return false;
        bool guansuo = false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getGeneralName().contains("guansuo") || p->getGeneral2Name().contains("guansuo")) {
                guansuo = true;
                break;
            }
        }
        if (guansuo) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@secondxushen-invoke", true);
        if (!target) return false;
        room->doAnimate(1, player->objectName(), target->objectName());
        if (target->askForSkillInvoke("tenyearxushenChange", "guansuo"))
            room->changeHero(target, "tenyear_guansuo", false, false);
        target->drawCards(3, objectName());
        return false;
    }
};

class SecondZhennan : public TriggerSkill
{
public:
    SecondZhennan() : TriggerSkill("secondzhennan")
    {
        events << TargetSpecified;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isNDTrick()) return false;
        if (use.to.length() <= 1) return false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isDead() || !p->hasSkill(this)) continue;
            ServerPlayer *target = room->askForPlayerChosen(p, room->getOtherPlayers(p), objectName(), "@tenyearzhennan-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->damage(DamageStruct(objectName(), p, target));
        }
        return false;
    }
};

class OLWuniang : public TriggerSkill
{
public:
    OLWuniang() : TriggerSkill("olwuniang")
    {
        events << CardFinished;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("olwuniang-Clear") > 0 || player->getPhase() == Player::NotActive) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash") || use.to.length() != 1) return false;
        ServerPlayer *to = use.to.first();
        if (to->isDead() || !to->canSlash(player, false) || !player->askForSkillInvoke(this, to)) return false;
        room->addPlayerMark(player, "olwuniang-Clear");
        room->broadcastSkillInvoke(objectName());
        room->askForUseSlashTo(to, player, "@olwuniang-slash:" + player->objectName(), false);
        if (player->isDead()) return false;
        player->drawCards(1, objectName());
        room->addSlashCishu(player, 1);
        return false;
    }
};

class OLXushen : public TriggerSkill
{
public:
    OLXushen() : TriggerSkill("olxushen")
    {
        events << Dying;
        frequency = Limited;
        limit_mark = "@olxushenMark";
        waked_skills = "olzhennan";
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (player != dying.who || player->getMark("@olxushenMark") <= 0) return false;
        if (!player->askForSkillInvoke(this)) return false;
        room->broadcastSkillInvoke(objectName());
        room->doSuperLightbox("ol_baosanniang", "olxushen");
        room->removePlayerMark(player, "@olxushenMark");
        room->recover(player, RecoverStruct(player, NULL, qMin(1 - player->getHp(), player->getMaxHp() - player->getHp())));
        if (player->isDead()) return false;
        room->acquireSkill(player, "olzhennan");
        if (player->isDead()) return false;
        bool guansuo = false;
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->getGeneralName().contains("guansuo") || p->getGeneral2Name().contains("guansuo")) {
                guansuo = true;
                break;
            }
        }
        if (guansuo) return false;
        QList<ServerPlayer *> males;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isMale())
                males << p;
        }
        if (males.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, males, objectName(), "@olxushen-invoke", true);
        if (!target) return false;
        room->doAnimate(1, player->objectName(), target->objectName());
        if (target->askForSkillInvoke("tenyearxushenChange", "guansuo"))
            room->changeHero(target, "ol_guansuo", false, false);
        return false;
    }
};

OLZhennanCard::OLZhennanCard()
{
    will_throw = false;
    mute = true;
    handling_method = Card::MethodUse;
}

bool OLZhennanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    SavageAssault *sa = new SavageAssault(Card::SuitToBeDecided, -1);
    sa->addSubcards(subcards);
    sa->setSkillName("olzhennan");
    sa->deleteLater();

    if (subcardsLength() >= Self->getAliveSiblings().length())
        return !Self->isLocked(sa, true);

    return !Self->isLocked(sa) && targets.length() < subcardsLength() && sa->targetFilter(targets, to_select, Self);
}

bool OLZhennanCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    if (subcardsLength() >= Self->getAliveSiblings().length())
        return true;
    return !targets.isEmpty();
}

void OLZhennanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->addPlayerMark(card_use.from, "olzhennan-PlayClear");

    SavageAssault *sa = new SavageAssault(Card::SuitToBeDecided, -1);
    sa->addSubcards(subcards);
    sa->setSkillName("olzhennan");
    sa->deleteLater();

    if (card_use.from->isLocked(sa)) return;

    foreach (ServerPlayer *p, card_use.to)
        room->addPlayerMark(p, "olzhennan_target-PlayClear");
    room->useCard(CardUseStruct(sa, card_use.from, card_use.to), true);
}

class OLZhennanVS : public ViewAsSkill
{
public:
    OLZhennanVS() : ViewAsSkill("olzhennan")
    {
        response_or_use = true;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped() || selected.length() >= Self->getAliveSiblings().length()) return false;
        SavageAssault *sa = new SavageAssault(Card::SuitToBeDecided, -1);
        sa->addSubcards(selected);
        sa->addSubcard(to_select);
        sa->setSkillName("olzhennan");
        sa->deleteLater();
        return !Self->isLocked(sa);
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty() || cards.length() > Self->getAliveSiblings().length()) return NULL;
        OLZhennanCard *zhennan = new OLZhennanCard;
        zhennan->addSubcards(cards);
        return zhennan;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("olzhennan-PlayClear") <= 0;
    }
};

class OLZhennan : public TriggerSkill
{
public:
    OLZhennan() : TriggerSkill("olzhennan")
    {
        events << PreCardUsed;
        view_as_skill = new OLZhennanVS;
    }

    int getPriority(TriggerEvent) const
    {
        return 7;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("SavageAssault") || use.card->getSkillName() != objectName()) return false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getMark("olzhennan_target-PlayClear") > 0) {
                room->setPlayerMark(p, "olzhennan_target-PlayClear", 0);
                targets << p;
            }
        }
        if (targets.isEmpty()) return false;
        room->sortByActionOrder(targets);
        use.to = targets;
        data = QVariant::fromValue(use);
        return false;
    }
};

class OLZhennanWuxiao : public TriggerSkill
{
public:
    OLZhennanWuxiao() : TriggerSkill("#olzhennan-wuxiao")
    {
        events << CardEffected;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardEffectStruct effect = data.value<CardEffectStruct>();
        if (effect.to->hasSkill("olzhennan") && effect.card->isKindOf("SavageAssault")) {
            LogMessage log;
            log.type = "#OLZhennanWuxiao";
            log.from = effect.to;
            log.arg = effect.card->objectName();
            log.arg2 = "olzhennan";
            room->sendLog(log);
            room->notifySkillInvoked(effect.to, "olzhennan");
            room->broadcastSkillInvoke("olzhennan");
            return true;
        }
        return false;
    }
};

class Lingren : public TriggerSkill
{
public:
    Lingren() : TriggerSkill("lingren")
    {
        events << TargetSpecified;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getMark("lingren-PlayClear") > 0 || player->getPhase() != Player::Play) return false;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash") || (use.card->isKindOf("TrickCard") && use.card->isDamageCard())) {
            QList<ServerPlayer *> targets = use.to;
            if (targets.contains(player))
                targets.removeOne(player);
            if (targets.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@lingren-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            room->addPlayerMark(player, "lingren-PlayClear");
            bool hasbasiccard = false;
            bool hastrickcard = false;
            bool hasequipcard = false;
            foreach (const Card *c, target->getCards("h")) {
                if (c->isKindOf("BasicCard"))
                    hasbasiccard = true;
                else if (c->isKindOf("TrickCard"))
                    hastrickcard = true;
                else if (c->isKindOf("EquipCard"))
                    hasequipcard = true;
                if (hasbasiccard && hastrickcard && hasequipcard)
                    break;
            }
            LogMessage log;
            log.type = "#LingrenGuess";
            log.from = player;
            log.to << target;

            QString choiceo = room->askForChoice(player, "lingren", "hasbasic+hasnobasic", QVariant::fromValue(target));
            log.arg = "lingren:" + choiceo;
            room->sendLog(log);

            QString choicet = room->askForChoice(player, "lingren", "hastrick+hasnotrick", QVariant::fromValue(target));
            log.arg = "lingren:" + choicet;
            room->sendLog(log);

            QString choiceth = room->askForChoice(player, "lingren", "hasequip+hasnoequip", QVariant::fromValue(target));
            log.arg = "lingren:" + choiceth;
            room->sendLog(log);

            int n = 0;
            if ((choiceo == "hasbasic" && hasbasiccard) || (choiceo == "hasnobasic" && !hasbasiccard))
                n++;
            if ((choicet == "hastrick" && hastrickcard) || (choicet == "hasnotrick" && !hastrickcard))
                n++;
            if ((choiceth == "hasequip" && hasequipcard) || (choiceth == "hasnoequip" && !hasequipcard))
                n++;

            log.type = "#LingrenGuessResult";
            log.arg= QString::number(n);
            room->sendLog(log);

            if (n == 0) return false;
            if (n == 3) {
                room->setPlayerFlag(target, "lingren_damage_to");
                room->setCardFlag(use.card, "lingren_damage_card");
                player->drawCards(2, objectName());
                room->acquireNextTurnSkills(player, objectName(), "jianxiong|xingshang");
            } else if (n == 2) {
                room->setPlayerFlag(target, "lingren_damage_to");
                room->setCardFlag(use.card, "lingren_damage_card");
                player->drawCards(2, objectName());
            } else {
                room->setPlayerFlag(target, "lingren_damage_to");
                room->setCardFlag(use.card, "lingren_damage_card");
            }
        }
        return false;
    }
};

class LingrenEffect : public TriggerSkill
{
public:
    LingrenEffect() : TriggerSkill("#lingreneffect")
    {
        events << DamageCaused;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isAlive() && damage.to->hasFlag("lingren_damage_to") && damage.card->hasFlag("lingren_damage_card")) {
            room->setPlayerFlag(damage.to, "-lingren_damage_to");
            room->setCardFlag(damage.card, "-lingren_damage_card");
            LogMessage log;
            log.type = "#LingrenDamage";
            log.from = damage.from;
            log.to << damage.to;
            log.arg = "lingren";
            log.arg2 = QString::number(++damage.damage);
            room->sendLog(log);
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class Fujian : public PhaseChangeSkill
{
public:
    Fujian() : PhaseChangeSkill("fujian")
    {
        frequency = Compulsory;
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Finish) return false;
        int n = player->getHandcardNum();
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getHandcardNum() < n)
                n = p->getHandcardNum();
        }
        if (n < 0) n = 0;
        ServerPlayer *target = room->getOtherPlayers(player).at(qrand() % room->getOtherPlayers(player).length());
        room->notifySkillInvoked(player, objectName());
        room->broadcastSkillInvoke(objectName());
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());;
        LogMessage log;
        log.type = "#FujianWatch";
        log.from = player;
        log.to << target;
        log.arg = "fujian";
        log.arg2 = QString::number(n);
        if (n == 0)
            room->sendLog(log);
        else {
            QList<int> handcards;
            QList<int> list;
            foreach (int id, target->handCards()) {
                handcards << id;
            }
            for (int i = 1; i <= n; i++) {
                if (handcards.isEmpty()) break;
                int id = handcards.at(qrand() % handcards.length());
                handcards.removeOne(id);
                list << id;
            }
            if (list.isEmpty())
                room->sendLog(log);
            else {
                QStringList slist;
                foreach (int id, list) {
                    slist << Sanguosha->getCard(id)->toString();
                }
                foreach(ServerPlayer *p, room->getAllPlayers(true)) {
                    if (p == player) continue;
                    room->sendLog(log, p);
                }
                log.type = "$FujianWatch";
                log.card_str = slist.join("+");
                room->sendLog(log, player);
                room->fillAG(list, player);
                room->askForAG(player, list, true, objectName());
                room->clearAG(player);
            }
        }
        return false;
    }
};

ShanjiaCard::ShanjiaCard(QString shanjia) : shanjia(shanjia)
{
    mute = true;
}

bool ShanjiaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    //slash->setSkillName("_" + getSkillName());
    slash->setSkillName("_" + shanjia);
    slash->deleteLater();
    return slash->targetFilter(targets, to_select, Self);
}

void ShanjiaCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    Slash *slash = new Slash(Card::NoSuit, 0);
    //slash->setSkillName("_" + getSkillName());
    slash->setSkillName("_" + shanjia);
    slash->deleteLater();

    room->useCard(CardUseStruct(slash, card_use.from, card_use.to), false);
}

OLShanjiaCard::OLShanjiaCard() : ShanjiaCard("olshanjia")
{
    mute = true;
}

class ShanjiaViewAsSkill : public ZeroCardViewAsSkill
{
public:
    ShanjiaViewAsSkill(const QString &shanjia) : ZeroCardViewAsSkill(shanjia), shanjia(shanjia)
    {
        response_pattern = "@@" + shanjia;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        //Slash *slash = new Slash(Card::NoSuit, 0);
        //slash->setSkillName("_shanjia");
        if (shanjia == "shanjia")
            return new ShanjiaCard;
        else if (shanjia == "olshanjia")
            return new OLShanjiaCard;
        return NULL;
    }

private:
    QString shanjia;
};

class Shanjia : public PhaseChangeSkill
{
public:
    Shanjia(const QString &shanjia) : PhaseChangeSkill(shanjia), shanjia(shanjia)
    {
        view_as_skill = new ShanjiaViewAsSkill(shanjia);
    }

    bool onPhaseChange(ServerPlayer *player) const
    {
        if (player->getPhase() != Player::Play) return false;
        if (!player->askForSkillInvoke(objectName())) return false;
        Room *room = player->getRoom();
        room->broadcastSkillInvoke(objectName());
        player->drawCards(3, objectName());

        int n = 3 - player->getMark("&" + shanjia) - player->getMark(shanjia + "Mark");
        bool flag = true;
        if (n > 0) {
            const Card *card = room->askForDiscard(player, objectName(), n, n , false, true, shanjia + "-discard:" + QString::number(n));
            foreach(int id, card->getSubcards()) {
                const Card *c = Sanguosha->getCard(id);
                if (c->isKindOf("BasicCard") || c->isKindOf("TrickCard")) {
                    flag = false;
                    break;
                }
            }
            delete card;
        }

        if (flag) {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_" + shanjia);

            bool distance_limit = shanjia == "shanjia" ? true : false;

            bool canslash = false;
            foreach(ServerPlayer *p, room->getAlivePlayers()) {
                if (player->canSlash(p, slash, distance_limit)) {
                    canslash = true;
                    break;
                }
            }
            if (canslash == false) return false;
            room->askForUseCard(player, "@@" + shanjia, "@" + shanjia);
        }
        return false;
    }

private:
    QString shanjia;
};

class ShanjiaRecord : public TriggerSkill
{
public:
    ShanjiaRecord() : TriggerSkill("#shanjia-record")
    {
        events << CardsMoveOneTime;
        global = true;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.from || move.from->isDead() || move.from != player) return false;
        int n = 0, m = 0;
        for (int i = 0; i < move.card_ids.length(); i++) {
            if (move.from_places[i] == Player::PlaceEquip)
                n++;
            if (Sanguosha->getCard(move.card_ids.at(i))->isKindOf("EquipCard") && move.reason.m_reason != CardMoveReason::S_REASON_USE &&
                    (move.from_places[i] == Player::PlaceEquip || move.from_places[i] == Player::PlaceHand))
                m++;
        }
        n = qMin(n, 3 - player->getMark("&shanjia") - player->getMark("shanjiaMark"));
        m = qMin(m, 3 - player->getMark("&olshanjia") - player->getMark("olshanjiaMark"));
        if (n > 0) {
            if (player->hasSkill("shanjia", true))
                room->addPlayerMark(player, "&shanjia", n);
            else
                room->addPlayerMark(player, "shanjiaMark", n);
        }
        if (m > 0) {
            if (player->hasSkill("olshanjia", true))
                room->addPlayerMark(player, "&olshanjia", m);
            else
                room->addPlayerMark(player, "olshanjiaMark", m);
        }
        return false;
    }
};

class Xianfu : public TriggerSkill
{
public:
    Xianfu() : TriggerSkill("xianfu")
    {
        events << Damaged << HpRecover;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == Damaged) {
            int d = data.value<DamageStruct>().damage;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                int mark = player->getMark("&xianfu+#" + p->objectName());
                if (p->isDead() || mark <= 0) continue;
                if (player->getMark("xianfu_hide_" + p->objectName()) > 0) {
                    room->setPlayerMark(player, "xianfu_hide_" + p->objectName(), 0);
                    room->setPlayerMark(player, "&xianfu+#" + p->objectName(), 0);
                    room->setPlayerMark(player, "&xianfu+#" + p->objectName(), mark);
                }
                for (int i = 0; i < mark; i++) {
                    if (p->isDead()) break;
                    room->sendCompulsoryTriggerLog(p, objectName(), true, true, qrand() % 2 + 3);
                    room->damage(DamageStruct(objectName(), NULL, p, d));
                }
            }
        } else {
            int rec = data.value<RecoverStruct>().recover;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                int mark = player->getMark("&xianfu+#" + p->objectName());
                if (p->isDead() || mark <= 0) continue;
                if (player->getMark("xianfu_hide_" + p->objectName()) > 0 && p->getLostHp() > 0) {
                    room->setPlayerMark(player, "xianfu_hide_" + p->objectName(), 0);
                    room->setPlayerMark(player, "&xianfu+#" + p->objectName(), 0);
                    room->setPlayerMark(player, "&xianfu+#" + p->objectName(), mark);
                }
                for (int i = 0; i < mark; i++) {
                    if (p->isDead()) break;
                    if (p->getLostHp() > 0)
                        room->sendCompulsoryTriggerLog(p, objectName(), true, true, qrand() % 2 + 5);
                    room->recover(p, RecoverStruct(p, NULL, qMin(rec, p->getMaxHp() - p->getHp())));
                }
            }
        }
        return false;
    }
};

class XianfuTarget : public GameStartSkill
{
public:
    XianfuTarget() : GameStartSkill("#xianfu-target")
    {
        frequency = Compulsory;
    }

    void onGameStart(ServerPlayer *player) const
    {
        if (!player->hasSkill("xianfu")) return;
        Room *room = player->getRoom();
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), "xianfu", "@xianfu-choose", false);

        room->notifySkillInvoked(player, "xianfu");
        player->peiyin("xianfu", qrand() % 2 + 1);

        LogMessage log;
        log.from = player;
        log.to << target;
        log.arg = "xianfu";
        log.type = "#ChoosePlayerWithSkill";
        room->sendLog(log, player);

        log.type = "#InvokeSkill";
        room->sendLog(log, room->getOtherPlayers(player, true));

        room->doAnimate(1, player->objectName(), target->objectName(), QList<ServerPlayer *>() << player);

        room->addPlayerMark(target, "&xianfu+#" + player->objectName(), 1, QList<ServerPlayer *>() << player);
        room->setPlayerMark(target, "xianfu_hide_" + player->objectName(), 1);
    }
};

class Chouce : public MasochismSkill
{
public:
    Chouce() : MasochismSkill("chouce")
    {
    }

    void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        Room *room = player->getRoom();
        for (int i = 0; i < damage.damage; i++) {
            if (player->isAlive() && room->askForSkillInvoke(player, objectName())) {
                player->peiyin(this);

                JudgeStruct judge;
                judge.pattern = ".";
                judge.play_animation = false;
                judge.reason = objectName();
                judge.who = player;
                room->judge(judge);

                Card::Color color = (Card::Color)(judge.pattern.toInt());

                if (color == Card::Black) {
                    QList<ServerPlayer *> targets;
                    foreach (ServerPlayer *p, room->getAlivePlayers()) {
                        if (player->canDiscard(p, "hej"))
                            targets << p;
                    }
                    if (targets.isEmpty()) continue;
                    ServerPlayer *target = room->askForPlayerChosen(player, targets, "chouce", "@chouce-discard");
                    room->doAnimate(1, player->objectName(), target->objectName());
                    int card_id = room->askForCardChosen(player, target, "hej", objectName(), false, Card::MethodDiscard);
                    room->throwCard(card_id, room->getCardPlace(card_id) == Player::PlaceDelayedTrick ? NULL : target, player);
                } else if (color == Card::Red) {
                    ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), "chouce_draw", "@chouce-draw");
                    room->doAnimate(1, player->objectName(), target->objectName());
                    int n = 1;
                    if (target->getMark("&xianfu+#" + player->objectName()) > 0) {
                        n = 2;
                        int mark = target->getMark("xianfu_hide_" + player->objectName());
                        if (mark > 0) {
                            room->setPlayerMark(target, "xianfu_hide_" + player->objectName(), 0);
                            room->setPlayerMark(target, "&xianfu+#" + player->objectName(), 0);
                            room->setPlayerMark(target, "&xianfu+#" + player->objectName(), mark);
                        }
                    }
                    target->drawCards(n, objectName());
                }
            } else
                break;
        }
    }
};

class ChouceJudge : public TriggerSkill
{
public:
    ChouceJudge() : TriggerSkill("#chouce-judge")
    {
        events << FinishJudge;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (judge->reason != "chouce") return false;
        judge->pattern = QString::number(int(judge->card->getColor()));
        return false;
    }
};

class Qianya : public TriggerSkill
{
public:
    Qianya() : TriggerSkill("qianya")
    {
        events << TargetConfirmed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.contains(player)) return false;
        if (use.card->isKindOf("TrickCard")) {
            if (player->isKongcheng()) return false;
            QList<int> handcards = player->handCards();
            room->askForYiji(player, handcards, objectName(), false, false, true, -1, QList<ServerPlayer *>(),
                             CardMoveReason(), "qianya-give", true);
        }
        return false;
    }
};

class Shuomeng : public TriggerSkill
{
public:
    Shuomeng() : TriggerSkill("shuomeng")
    {
        events << EventPhaseEnd;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() != Player::Play) return false;
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->canPindian(p))
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), "@shuomeng-invoke", true, true);
        if (!target) return false;
        room->broadcastSkillInvoke(objectName());
        bool success = player->pindian(target, objectName());
        if (success) {
            ExNihilo *ex_nihilo = new ExNihilo(Card::NoSuit, 0);
            ex_nihilo->setSkillName("_shuomeng");
            if (!player->isLocked(ex_nihilo) && !player->isProhibited(player, ex_nihilo))
                room->useCard(CardUseStruct(ex_nihilo, player, player));
        } else {
            Dismantlement *dismantlement = new Dismantlement(Card::NoSuit, 0);
            dismantlement->setSkillName("_shuomeng");
            if (!target->isLocked(dismantlement) && !target->isProhibited(player, dismantlement) &&
                    dismantlement->targetFilter(QList<const Player *>(), player, target))
                room->useCard(CardUseStruct(dismantlement, target, player));
        }
        return false;
    }
};

class Tuifeng : public TriggerSkill
{
public:
    Tuifeng() : TriggerSkill("tuifeng")
    {
        events << Damaged << EventPhaseStart;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            for (int i = 1; i <= damage.damage; i++) {
                if (player->isDead() || player->isNude()) break;
                const Card *card = room->askForCard(player, "..", "tuifeng-put", data, Card::MethodNone);
                if (!card) break;
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName());
                player->addToPile("tfeng", card);
            }
        } else {
            if (player->getPhase() != Player::Start) return false;
            int n = player->getPile("tfeng").length();
            if (n <= 0) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            player->clearOnePrivatePile("tfeng");
            player->drawCards(2 * n, objectName());
            room->addSlashCishu(player, n);
        }
        return false;
    }
};

class Andong : public TriggerSkill
{
public:
    Andong() : TriggerSkill("andong")
    {
        events << DamageInflicted << EventPhaseProceeding;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageInflicted) {
            if (!player->hasSkill(this)) return false;
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.from || damage.from->isDead() || damage.from == player) return false;
            if (!player->askForSkillInvoke(this, QVariant::fromValue(damage.from))) return false;
            room->broadcastSkillInvoke(objectName());
            QStringList choices;
            choices << "prevent" << "get";
            QString choice = room->askForChoice(damage.from, objectName(), choices.join("+"), data);
            LogMessage log;
            log.type = "#FumianFirstChoice";
            log.from = damage.from;
            log.arg = "andong:" + choice;
            room->sendLog(log);
            if (choice == "prevent") {
                room->addPlayerMark(damage.from, "andong_heart-Clear");
                return true;
            } else {
                room->doGongxin(player, damage.from, QList<int>(), objectName());
                QList<int> hearts;
                foreach (int id, damage.from->handCards()) {
                    if (Sanguosha->getCard(id)->getSuit() == Card::Heart) {
                        hearts << id;
                    }
                }
                if (hearts.isEmpty()) return false;
                DummyCard get(hearts);
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, &get, reason, false);
            }
        } else {
            if (player->getPhase() != Player::Discard) return false;
            if (player->getMark("andong_heart-Clear") <= 0) return false;
            QList<int> hearts;
            foreach (int id, player->handCards()) {
                if (Sanguosha->getCard(id)->getSuit() == Card::Heart)
                    hearts << id;
            }
            room->ignoreCards(player, hearts);
        }
        return false;
    }
};

YingshiCard::YingshiCard()
{
    target_fixed = true;
    will_throw = false;
}

void YingshiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->setPlayerProperty(source, "yingshi_name", QString());
    LogMessage log;
    log.type = "$KuangbiGet";
    log.from = source;
    log.arg = "yschou";
    log.card_str = Sanguosha->getCard(getSubcards().first())->toString();
    room->sendLog(log);
    room->obtainCard(source, this, true);
}

class YingshiVS : public OneCardViewAsSkill
{
public:
    YingshiVS() : OneCardViewAsSkill("yingshi")
    {
        expand_pile = "%yschou";
        response_pattern = "@@yingshi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() >= 2)
            return false;
        QString name = Self->property("yingshi_name").toString();
        QList<const Player *> as = Self->getAliveSiblings();
        as << Self;
        foreach (const Player *p, as) {
            if (!p->getPile("yschou").isEmpty() && p->objectName() == name) {
                return p->getPile("yschou").contains(to_select->getId());
            }
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        YingshiCard *card = new YingshiCard;
        card->addSubcard(originalCard);
        return card;
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }
};

class Yingshi : public TriggerSkill
{
public:
    Yingshi() : TriggerSkill("yingshi")
    {
        events << EventPhaseStart << Damage;
        view_as_skill = new YingshiVS;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play || !player->hasSkill(this)) return false;
            bool has_chou = false;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (!p->getPile("yschou").isEmpty()) {
                    has_chou = true;
                    break;
                }
            }
            if (has_chou) return false;
            QList<int> hearts;
            foreach (const Card *c, player->getCards("he")) {
                if (c->getSuit() == Card::Heart)
                    hearts << c->getEffectiveId();
            }
            if (hearts.isEmpty()) return false;
            ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@yingshi-invoke", true, true);
            if (!target) return false;
            room->broadcastSkillInvoke(objectName());
            target->addToPile("yschou", hearts);
        } else {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("Slash")) return false;
            if (damage.to->isDead() || damage.to->getPile("yschou").isEmpty()) return false;
            room->setPlayerProperty(player, "yingshi_name", damage.to->objectName());
            if (!room->askForUseCard(player, "@@yingshi", "@yingshi:" + damage.to->objectName()))
                room->setPlayerProperty(player, "yingshi_name", QString());
        }
        return false;
    }
};

class YingshiDeath : public TriggerSkill
{
public:
    YingshiDeath() : TriggerSkill("#yingshi-death")
    {
        events << Death;
        view_as_skill = new YingshiVS;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DeathStruct death = data.value<DeathStruct>();
        if (death.who == player || death.who->getPile("yschou").isEmpty()) return false;
        room->sendCompulsoryTriggerLog(player, "yingshi", true, true);
        DummyCard get(death.who->getPile("yschou"));
        room->obtainCard(player, &get, true);
        return false;
    }
};

class Weilu : public TriggerSkill
{
public:
    Weilu() : TriggerSkill("weilu")
    {
        events << Damaged << EventPhaseStart << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.from || damage.from == player) return false;
            room->sendCompulsoryTriggerLog(player, objectName(), true, true);
            QStringList names = player->property("weilu_damage_from").toStringList();
            if (!names.contains(damage.from->objectName())) {
                names << damage.from->objectName();
                room->setPlayerProperty(player, "weilu_damage_from", names);
                room->addPlayerMark(damage.from, "&weilu");
            }
        } else if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            QStringList names = player->property("weilu_damage_from").toStringList();
            if (names.isEmpty()) return false;
            bool log = true;
            foreach (QString name, names) {
                ServerPlayer *p = room->findPlayerByObjectName(name);
                if (!p || p->isDead() || p->getHp() <= 1) continue;
                if (log) {
                    log = false;
                    room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                }
                int lose = p->getHp() - 1;
                room->loseHp(p, lose);
                if (p->isAlive())
                    room->addPlayerMark(p, "weilu_losehp-Clear", lose);
            }
        } else {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return false;
            QStringList names = player->property("weilu_damage_from").toStringList();
            if (names.isEmpty()) return false;
            room->setPlayerProperty(player, "weilu_damage_from", QStringList());
            bool log = true;
            foreach (QString name, names) {
                ServerPlayer *p = room->findPlayerByObjectName(name);
                if (!p || p->isDead()) continue;
                if (p->getMark("&weilu") > 0)
                    room->removePlayerMark(p, "&weilu");
                int recover = p->getMark("weilu_losehp-Clear");
                room->setPlayerMark(p, "weilu_losehp-Clear", 0);
                recover = qMin(recover, p->getMaxHp() - p->getHp());
                if (recover > 0) {
                    if (log) {
                        log = false;
                        room->sendCompulsoryTriggerLog(player, objectName(), true, true);
                    }
                    room->recover(p, RecoverStruct(player, NULL, recover));
                }
            }
        }
        return false;
    }
};

ZengdaoCard::ZengdaoCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void ZengdaoCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->removePlayerMark(effect.from, "@zengdaoMark");
    room->doSuperLightbox("lvqian", "zengdao");
    effect.to->addToPile("zengdao", this);
}

ZengdaoRemoveCard::ZengdaoRemoveCard()
{
    mute = true;
    target_fixed = true;
    will_throw = false;
    m_skillName = "zengdao";
    handling_method = Card::MethodNone;
}

void ZengdaoRemoveCard::onUse(Room *room, const CardUseStruct &) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "zengdao", QString());
    room->throwCard(this, reason, NULL);
}

class ZengdaoVS : public ViewAsSkill
{
public:
    ZengdaoVS() : ViewAsSkill("zengdao")
    {
        expand_pile = "zengdao";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@zengdao!")
            return selected.isEmpty() && Self->getPile("zengdao").contains(to_select->getEffectiveId());
        return to_select->isEquipped();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "@@zengdao!") {
            ZengdaoRemoveCard *card = new ZengdaoRemoveCard;
            card->addSubcards(cards);
            return card;
        }
        ZengdaoCard *card = new ZengdaoCard;
        card->addSubcards(cards);
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@zengdaoMark") > 0 && !player->getEquips().isEmpty();
    }

    bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "@@zengdao!";
    }
};

class Zengdao : public TriggerSkill
{
public:
    Zengdao() : TriggerSkill("zengdao")
    {
        events << DamageCaused;
        view_as_skill = new ZengdaoVS;
        frequency = Limited;
        limit_mark = "@zengdaoMark";
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive() && !target->getPile("zengdao").isEmpty();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isDead()) return false;
        LogMessage log;
        log.type = "#Zengdao";
        log.from = player;
        log.arg = objectName();
        room->sendLog(log);

        CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "zengdao", QString());
        if (player->getPile("zengdao").length() == 1) {
            room->throwCard(Sanguosha->getCard(player->getPile("zengdao").first()), reason, NULL);
        } else {
            if (!room->askForUseCard(player, "@@zengdao!", "@zengdao")) {
                int id = player->getPile("zengdao").at(qrand() % player->getPile("zengdao").length());
                room->throwCard(Sanguosha->getCard(id), reason, NULL);
            }
        }
        LogMessage newlog;
        newlog.type = "#ZengdaoDamage";
        newlog.from = player;
        newlog.to << damage.to;
        newlog.arg = QString::number(damage.damage);
        newlog.arg2 = QString::number(++damage.damage);
        room->sendLog(newlog);

        data = QVariant::fromValue(damage);

        return false;
    }
};

SPPackage::SPPackage()
: Package("sp")
{
    General *yangxiu = new General(this, "yangxiu", "wei", 3); // SP 001
    yangxiu->addSkill(new Jilei);
    yangxiu->addSkill(new JileiClear);
    yangxiu->addSkill(new Danlao);
    related_skills.insertMulti("jilei", "#jilei-clear");

    General *sp_diaochan = new General(this, "sp_diaochan", "qun", 3, false, true); // SP 002
    sp_diaochan->addSkill("noslijian");
    sp_diaochan->addSkill("biyue");

    General *gongsunzan = new General(this, "gongsunzan", "qun"); // SP 003
    gongsunzan->addSkill(new Yicong);
    gongsunzan->addSkill(new YicongEffect);
    related_skills.insertMulti("yicong", "#yicong-effect");

    General *ol_sp_gongsunzan = new General(this, "ol_sp_gongsunzan", "qun");
    ol_sp_gongsunzan->addSkill("olyicong");

    General *yuanshu = new General(this, "yuanshu", "qun"); // SP 004
    yuanshu->addSkill(new Yongsi);
    yuanshu->addSkill(new Weidi);

    General *sp_sunshangxiang = new General(this, "sp_sunshangxiang", "shu", 3, false, true); // SP 005
    sp_sunshangxiang->addSkill("jieyin");
    sp_sunshangxiang->addSkill("xiaoji");

    General *sp_pangde = new General(this, "sp_pangde", "wei", 4, true, true); // SP 006
    sp_pangde->addSkill("mashu");
    sp_pangde->addSkill("mengjin");

    General *sp_guanyu = new General(this, "sp_guanyu", "wei", 4); // SP 007
    sp_guanyu->addSkill("wusheng");
    sp_guanyu->addSkill(new Danji);

    General *shenlvbu1 = new General(this, "shenlvbu1", "god", 8, true, true); // SP 008 (2-1)
    shenlvbu1->addSkill("mashu");
    shenlvbu1->addSkill("wushuang");

    General *shenlvbu2 = new General(this, "shenlvbu2", "god", 4, true, true); // SP 008 (2-2)
    shenlvbu2->addSkill("mashu");
    shenlvbu2->addSkill("wushuang");
    shenlvbu2->addSkill(new Xiuluo);
    shenlvbu2->addSkill(new ShenweiKeep);
    shenlvbu2->addSkill(new Shenwei);
    shenlvbu2->addSkill(new Shenji);
    related_skills.insertMulti("shenwei", "#shenwei-draw");

    General *sp_caiwenji = new General(this, "sp_caiwenji", "wei", 3, false, true); // SP 009
    sp_caiwenji->addSkill("beige");
    sp_caiwenji->addSkill("duanchang");

    General *sp_machao = new General(this, "sp_machao", "qun", 4, true, true); // SP 011
    sp_machao->addSkill("mashu");
    sp_machao->addSkill("nostieji");

    General *sp_jiaxu = new General(this, "sp_jiaxu", "wei", 3, true, true); // SP 012
    sp_jiaxu->addSkill("wansha");
    sp_jiaxu->addSkill("luanwu");
    sp_jiaxu->addSkill("weimu");

    General *caohong = new General(this, "caohong", "wei"); // SP 013
    caohong->addSkill(new Yuanhu);

    General *guanyinping = new General(this, "guanyinping", "shu", 3, false); // SP 014
    guanyinping->addSkill(new Xueji);
    guanyinping->addSkill(new Huxiao);
    guanyinping->addSkill(new HuxiaoCount);
    guanyinping->addSkill(new HuxiaoClear);
    guanyinping->addSkill(new Wuji);
    related_skills.insertMulti("huxiao", "#huxiao-count");
    related_skills.insertMulti("huxiao", "#huxiao-clear");

    General *sp_zhenji = new General(this, "sp_zhenji", "wei", 3, false, true); // SP 015
    sp_zhenji->addSkill("qingguo");
    sp_zhenji->addSkill("luoshen");

    General *liuxie = new General(this, "liuxie", "qun", 3);
    liuxie->addSkill("tianming");
    liuxie->addSkill("mizhao");

    General *lingju = new General(this, "lingju", "qun", 3, false);
    lingju->addSkill("jieyuan");
    lingju->addSkill("fenxin");

    General *fuwan = new General(this, "fuwan", "qun", 4);
    fuwan->addSkill("moukui");

    General *xiahouba = new General(this, "xiahouba", "shu"); // SP 019
    xiahouba->addSkill(new Baobian);

    General *tenyear_xiahouba = new General(this, "tenyear_xiahouba", "shu");
    tenyear_xiahouba->setImage("xiahouba");
    tenyear_xiahouba->addSkill(new TenyearBaobian);
    tenyear_xiahouba->addRelateSkill("tiaoxin");
    tenyear_xiahouba->addRelateSkill("tenyearpaoxiao");
    tenyear_xiahouba->addRelateSkill("tenyearshensu");

    General *chenlin = new General(this, "chenlin", "wei", 3); // SP 020
    chenlin->addSkill(new Bifa);
    chenlin->addSkill(new Songci);

    General *erqiao = new General(this, "erqiao", "wu", 3, false); // SP 021
    erqiao->addSkill(new Xingwu);
    erqiao->addSkill(new XingwuRecord);
    erqiao->addSkill(new Luoyan("luoyan"));
    related_skills.insertMulti("xingwu", "#xingwu");

    General *ol_erqiao = new General(this, "ol_erqiao", "wu", 3, false);
    ol_erqiao->addSkill(new OLXingwu("olxingwu"));
    ol_erqiao->addSkill(new Luoyan("olluoyan"));
    ol_erqiao->addRelateSkill("oltianxiang");
    ol_erqiao->addRelateSkill("liuli");

    General *tenyear_erqiao = new General(this, "tenyear_erqiao", "wu", 3, false);
    tenyear_erqiao->setImage("erqiao");
    tenyear_erqiao->addSkill(new OLXingwu("tenyearxingwu"));
    tenyear_erqiao->addSkill("olluoyan");
    tenyear_erqiao->addRelateSkill("oltianxiang");
    tenyear_erqiao->addRelateSkill("liuli");

    General *sp_shenlvbu = new General(this, "sp_shenlvbu", "god", 5, true, true); // SP 022
    sp_shenlvbu->addSkill("kuangbao");
    sp_shenlvbu->addSkill("wumou");
    sp_shenlvbu->addSkill("wuqian");
    sp_shenlvbu->addSkill("shenfen");

    General *xiahoushi = new General(this, "xiahoushi", "shu", 3, false); // SP 023
    xiahoushi->addSkill(new Yanyu);
    xiahoushi->addSkill(new Xiaode);
    xiahoushi->addSkill(new XiaodeEx);
    related_skills.insertMulti("xiaode", "#xiaode");

    General *sp_yuejin = new General(this, "sp_yuejin", "wei", 4, true); // SP 024
    sp_yuejin->addSkill("xiaoguo");

    General *zhangbao = new General(this, "zhangbao", "qun", 3); // SP 025
    zhangbao->addSkill(new Zhoufu);
    zhangbao->addSkill(new Yingbing);

    General *caoang = new General(this, "caoang", "wei"); // SP 026
    caoang->addSkill(new Kangkai);

    General *sp_zhugejin = new General(this, "sp_zhugejin", "wu", 3, true, true); // SP 027
    sp_zhugejin->addSkill("hongyuan");
    sp_zhugejin->addSkill("huanshi");
    sp_zhugejin->addSkill("mingzhe");

    General *xingcai = new General(this, "xingcai", "shu", 3, false); // SP 028
    xingcai->addSkill(new Shenxian);
    xingcai->addSkill(new Qiangwu);
    xingcai->addSkill(new QiangwuTargetMod);
    related_skills.insertMulti("qiangwu", "#qiangwu-target");

    General *sp_panfeng = new General(this, "sp_panfeng", "qun", 4, true); // SP 029
    sp_panfeng->addSkill("kuangfu");

    General *zumao = new General(this, "zumao", "wu"); // SP 030
    zumao->addSkill(new Yinbing);
    zumao->addSkill(new Juedi);

    General *sp_dingfeng = new General(this, "sp_dingfeng", "wu", 4, true); // SP 031
    sp_dingfeng->addSkill("duanbing");
    sp_dingfeng->addSkill("fenxun");

    General *zhugedan = new General(this, "zhugedan", "wei", 4); // SP 032
    zhugedan->addSkill(new Gongao);
    zhugedan->addSkill(new Juyi);

    General *ol_zhugedan = new General(this, "ol_zhugedan", "wei", 4);
    ol_zhugedan->setImage("zhugedan");
    ol_zhugedan->addSkill("gongao");
    ol_zhugedan->addSkill(new OLJuyi);

    General *sp_hetaihou = new General(this, "sp_hetaihou", "qun", 3, false); // SP 033
    sp_hetaihou->addSkill("zhendu");
    sp_hetaihou->addSkill("qiluan");

    General *sunluyu = new General(this, "sunluyu", "wu", 3, false); // SP 034
    sunluyu->addSkill(new Meibu);
    sunluyu->addSkill(new Mumu);

    General *maliang = new General(this, "maliang", "shu", 3); // SP 035
    maliang->addSkill(new Xiemu);
    maliang->addSkill(new Naman);

    General *chengyu = new General(this, "chengyu", "wei", 3);
    chengyu->addSkill(new Shefu);
    chengyu->addSkill(new ShefuCancel);
    chengyu->addSkill(new Benyu);
    related_skills.insertMulti("shefu", "#shefu-cancel");

    General *sp_ganfuren = new General(this, "sp_ganfuren", "shu", 3, false); // SP 037
    sp_ganfuren->addSkill("shushen");
    sp_ganfuren->addSkill("shenzhi");

    General *huangjinleishi = new General(this, "huangjinleishi", "qun", 3, false); // SP 038
    huangjinleishi->addSkill(new Fulu);
    huangjinleishi->addSkill(new Zhuji);

    General *sp_wenpin = new General(this, "sp_wenpin", "wei"); // SP 039
    sp_wenpin->addSkill(new SpZhenwei);

    General *simalang = new General(this, "simalang", "wei", 3); // SP 040
    simalang->addSkill(new Quji);
    simalang->addSkill(new Junbing);

    General *sunhao = new General(this, "sunhao$", "wu", 5); // SP 041, SE god god god god god god god god god god god god god god god god god god god god god god god god god god god god god god god god
    sunhao->addSkill(new Canshi);
    sunhao->addSkill(new Chouhai);
    sunhao->addSkill(new Guiming);

    General *ol_sunhao = new General(this, "ol_sunhao$", "wu", 5);
    ol_sunhao->addSkill("tenyearcanshi");
    ol_sunhao->addSkill("chouhai");
    ol_sunhao->addSkill("guiming");

    General *xurong = new General(this, "xurong", "qun", 4);
    xurong->addSkill(new Shajue);
    xurong->addSkill(new Xionghuo);
    xurong->addSkill(new XionghuoMark);
    xurong->addSkill(new XionghuoPro);
    related_skills.insertMulti("xionghuo", "#xionghuomark");
    related_skills.insertMulti("xionghuo", "#xionghuopro");

    General *zhangqiying = new General(this, "zhangqiying", "qun", 3, false);
    zhangqiying->addSkill(new Falu);
    zhangqiying->addSkill(new Zhenyi);
    zhangqiying->addSkill(new Dianhua);

    General *tenyear_zhangqiying = new General(this, "tenyear_zhangqiying", "qun", 3, false);
    tenyear_zhangqiying->addSkill("falu");
    tenyear_zhangqiying->addSkill(new TenyearZhenyi);
    tenyear_zhangqiying->addSkill("dianhua");

    General *yanbaihu = new General(this, "yanbaihu", "qun", 4);
    yanbaihu->addSkill(new Zhidao);
    yanbaihu->addSkill(new ZhidaoPro);
    yanbaihu->addSkill(new SpJili);
    related_skills.insertMulti("zhidao", "#zhidao-pro");

    General *dongbai = new General(this, "dongbai", "qun", 3, false);
    dongbai->addSkill(new Lianzhu("lianzhu"));
    dongbai->addSkill(new Xiahui("xiahui"));
    dongbai->addSkill(new XiahuiClear("xiahui"));
    related_skills.insertMulti("xiahui", "#xiahui-clear");

    General *tenyear_dongbai = new General(this, "tenyear_dongbai", "qun", 3, false);
    tenyear_dongbai->addSkill(new Lianzhu("tenyearlianzhu"));
    tenyear_dongbai->addSkill(new Xiahui("tenyearxiahui"));
    tenyear_dongbai->addSkill(new XiahuiClear("tenyearxiahui"));
    tenyear_dongbai->addSkill(new TenyearXiahuiMove);
    related_skills.insertMulti("tenyearxiahui", "#tenyearxiahui-clear");
    related_skills.insertMulti("tenyearxiahui", "#tenyearxiahui-move");

    General *quyi = new General(this, "quyi", "qun", 4);
    quyi->addSkill(new Fuqi);
    quyi->addSkill(new Jiaozi);

    General *beimihu = new General(this, "beimihu", "qun", 3, false);
    beimihu->addSkill(new Zongkui);
    beimihu->addSkill(new Guju);
    beimihu->addSkill(new Baijia);
    beimihu->addSkill(new BaijiaRecord);
    beimihu->addRelateSkill("spcanshi");
    related_skills.insertMulti("baijia", "#baijia");
    related_skills.insertMulti("spcanshi", "#spcanshi-target");

    General *guansuo = new General(this, "guansuo", "shu", 4);
    guansuo->addSkill(new Xiefang);
    guansuo->addSkill(new Zhengnan);

    General *ol_guansuo = new General(this, "ol_guansuo", "shu", 4);
    ol_guansuo->addSkill("xiefang");
    ol_guansuo->addSkill(new OLZhengnan);

    General *tenyear_guansuo = new General(this, "tenyear_guansuo", "shu", 4);
    tenyear_guansuo->addSkill("xiefang");
    tenyear_guansuo->addSkill(new TenyearZhengnan);

    General *zhaoxiang = new General(this, "zhaoxiang", "shu", 4, false);
    zhaoxiang->addSkill(new Fanghun);
    zhaoxiang->addSkill(new FanghunDraw("fanghun"));
    zhaoxiang->addSkill(new Fuhan);
    related_skills.insertMulti("fanghun", "#fanghun");

    General *ol_zhaoxiang = new General(this, "ol_zhaoxiang", "shu", 4, false);
    ol_zhaoxiang->addSkill(new OLFanghun);
    ol_zhaoxiang->addSkill(new FanghunDraw("olfanghun"));
    ol_zhaoxiang->addSkill(new OLFuhan);
    related_skills.insertMulti("olfanghun", "#olfanghun");

    General *mobile_zhaoxiang = new General(this, "mobile_zhaoxiang", "shu", 4, false);
    mobile_zhaoxiang->addSkill(new MobileFanghun);
    mobile_zhaoxiang->addSkill(new FanghunDraw("mobilefanghun"));
    mobile_zhaoxiang->addSkill(new MobileFuhan);
    related_skills.insertMulti("mobilefanghun", "#mobilefanghun");

    General *tenyear_zhaoxiang = new General(this, "tenyear_zhaoxiang", "shu", 4, false);
    tenyear_zhaoxiang->addSkill(new TenyearFanghun);
    tenyear_zhaoxiang->addSkill(new FanghunDraw("tenyearfanghun"));
    tenyear_zhaoxiang->addSkill(new TenyearFuhan);
    related_skills.insertMulti("tenyearfanghun", "#tenyearfanghun");

    General *baosanniang = new General(this, "baosanniang", "shu", 3, false);
    baosanniang->addSkill(new Wuniang);
    baosanniang->addSkill(new Xushen);
    baosanniang->addRelateSkill("zhennan");

    General *mobile_baosanniang = new General(this, "mobile_baosanniang", "shu", 3, false);
    mobile_baosanniang->addSkill(new Shuyong);
    mobile_baosanniang->addSkill(new MobileXushen);
    mobile_baosanniang->addSkill(new MoboleZhennan);

    General *tenyear_baosanniang = new General(this, "tenyear_baosanniang", "shu", 3, false);
    tenyear_baosanniang->addSkill("wuniang");
    tenyear_baosanniang->addSkill(new TenyearXushen);
    tenyear_baosanniang->addRelateSkill("tenyearzhennan");

    General *second_tenyear_baosanniang = new General(this, "second_tenyear_baosanniang", "shu", 3, false);
    second_tenyear_baosanniang->addSkill(new SecondWuniang);
    second_tenyear_baosanniang->addSkill(new SecondXushen);
    second_tenyear_baosanniang->addRelateSkill("secondzhennan");

    General *ol_baosanniang = new General(this, "ol_baosanniang", "shu", 4, false);
    ol_baosanniang->addSkill(new OLWuniang);
    ol_baosanniang->addSkill(new OLXushen);
    ol_baosanniang->addRelateSkill("olzhennan");

    General *caoying = new General(this, "caoying", "wei", 4, false);
    caoying->addSkill(new Lingren);
    caoying->addSkill(new LingrenEffect);
    caoying->addSkill(new Fujian);
    related_skills.insertMulti("lingren", "#lingreneffect");

    General *caochun = new General(this, "caochun", "wei", 4);
    caochun->addSkill(new Shanjia("shanjia"));
    caochun->addSkill(new ShanjiaRecord);
    related_skills.insertMulti("shanjia", "#shanjia-record");

    General *ol_caochun = new General(this, "ol_caochun", "wei", 4);
    ol_caochun->addSkill(new Shanjia("olshanjia"));
    ol_caochun->addSkill(new SlashNoDistanceLimitSkill("olshanjia"));
    related_skills.insertMulti("olshanjia", "#olshanjia-slash-ndl");

    General *xizhicai = new General(this, "xizhicai", "wei", 3);
    xizhicai->addSkill("tiandu");
    xizhicai->addSkill(new Xianfu);
    xizhicai->addSkill(new XianfuTarget);
    xizhicai->addSkill(new Chouce);
    xizhicai->addSkill(new ChouceJudge);
    related_skills.insertMulti("xianfu", "#xianfu-target");
    related_skills.insertMulti("chouce", "#chouce-judge");

    General *sunqian = new General(this, "sunqian", "shu", 3);
    sunqian->addSkill(new Qianya);
    sunqian->addSkill(new Shuomeng);

    General *litong = new General(this, "litong", "wei", 4);
    litong->addSkill(new Tuifeng);

    General *duji = new General(this, "duji", "wei", 3);
    duji->addSkill(new Andong);
    duji->addSkill(new Yingshi);
    duji->addSkill(new YingshiDeath);
    related_skills.insertMulti("yingshi", "#yingshi-death");

    General *lvqian = new General(this, "lvqian", "wei", 4);
    lvqian->addSkill(new Weilu);
    lvqian->addSkill(new Zengdao);

    addMetaObject<YuanhuCard>();
    addMetaObject<XuejiCard>();
    addMetaObject<BifaCard>();
    addMetaObject<SongciCard>();
    addMetaObject<OLXingwuCard>();
    addMetaObject<TenyearXingwuCard>();
    addMetaObject<ZhoufuCard>();
    addMetaObject<QiangwuCard>();
    addMetaObject<YinbingCard>();
    addMetaObject<XiemuCard>();
    addMetaObject<ShefuCard>();
    addMetaObject<QujiCard>();
    addMetaObject<XionghuoCard>();
    addMetaObject<LianzhuCard>();
    addMetaObject<TenyearLianzhuCard>();
    addMetaObject<SpCanshiCard>();
    addMetaObject<FanghunCard>();
    addMetaObject<OLFanghunCard>();
    addMetaObject<MobileFanghunCard>();
    addMetaObject<TenyearFanghunCard>();
    addMetaObject<MobileXushenCard>();
    addMetaObject<OLZhennanCard>();
    addMetaObject<ShanjiaCard>();
    addMetaObject<OLShanjiaCard>();
    addMetaObject<YingshiCard>();
    addMetaObject<ZengdaoCard>();
    addMetaObject<ZengdaoRemoveCard>();

    skills << new Weizhong << new OLWeizhong << new MeibuFilter("meibu") << new SpCanshi << new SpCanshiMod << new MeiyingMark
           << new Zhennan << new TenyearZhennan << new SecondZhennan << new OLZhennan << new OLZhennanWuxiao;
    related_skills.insertMulti("olzhennan", "#olzhennan-wuxiao");
}

ADD_PACKAGE(SP)

MiscellaneousPackage::MiscellaneousPackage()
: Package("miscellaneous")
{
    General *wz_daqiao = new General(this, "wz_nos_daqiao", "wu", 3, false, true); // WZ 001
    wz_daqiao->addSkill("nosguose");
    wz_daqiao->addSkill("liuli");

    General *wz_xiaoqiao = new General(this, "wz_xiaoqiao", "wu", 3, false, true); // WZ 002
    wz_xiaoqiao->addSkill("tianxiang");
    wz_xiaoqiao->addSkill("hongyan");

    General *pr_shencaocao = new General(this, "pr_shencaocao", "god", 3, true, true); // PR LE 005
    pr_shencaocao->addSkill("guixin");
    pr_shencaocao->addSkill("feiying");

    General *pr_nos_simayi = new General(this, "pr_nos_simayi", "wei", 3, true, true); // PR WEI 002
    pr_nos_simayi->addSkill("nosfankui");
    pr_nos_simayi->addSkill("nosguicai");

    General *Caesar = new General(this, "caesar", "god", 4); // E.SP 001
    Caesar->addSkill(new Conqueror);

    General *hanba = new General(this, "hanba", "qun", 4, false);
    hanba->addSkill(new Fentian);
    hanba->addSkill(new Zhiri);
    hanba->addSkill(new FentianRange);
    related_skills.insertMulti("fentian", "#fentian");
    hanba->addRelateSkill("xintan");

    skills << new Xintan;

    addMetaObject<XintanCard>();
}

ADD_PACKAGE(Miscellaneous)
