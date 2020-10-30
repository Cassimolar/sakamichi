#include "jie.h"
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

class JinBolan : public TriggerSkill
{
public:
    JinBolan() : TriggerSkill("jinbolan")
    {
        events << EventPhaseStart << GameStart << EventAcquireSkill;
        frequency = Frequent;
    }

    static QStringList getSkills(ServerPlayer *player)
    {
        //QStringList all_skill_names = Sanguosha->getSkillNames();觉醒获得的技能也加进去了

        QStringList skill_names, skills;
        QStringList general_names = Sanguosha->getLimitedGeneralNames();
        foreach (QString general_name, general_names) {
            const General *general = Sanguosha->getGeneral(general_name);
            if (!general) continue;
            foreach (const Skill *skill, general->getSkillList()) {
                if (skill->objectName() == "jinbolan" || !skill->inherits("ViewAsSkill") || skill_names.contains(skill->objectName())) continue;
                if (!skill->isVisible() || skill->isAttachedLordSkill() || player->hasSkill(skill, true)) continue;

                const ViewAsSkill *vs = Sanguosha->getViewAsSkill(skill->objectName());
                if (!vs) continue;

                QString translation = skill->getDescription();
                if (!translation.contains("出牌阶段限一次，") && !translation.contains("阶段技，") && !translation.contains("出牌阶段限一次。")
                        && !translation.contains("阶段技。")) continue;
                if (translation.contains("，出牌阶段限一次") || translation.contains("，阶段技") || translation.contains("（出牌阶段限一次") ||
                        translation.contains("（阶段技")) continue;

                skill_names << skill->objectName();
            }
        }

        for (int i = 0; i < 3; i++) {
            if (skill_names.isEmpty()) break;
            int n = qrand() % skill_names.length();
            skills << skill_names.at(n);
            skill_names.removeOne(skills.last());
        }

        return skills;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart) {
            if (player->getPhase() != Player::Play) return false;
            if (!player->askForSkillInvoke(this)) return false;
            room->broadcastSkillInvoke(objectName());

            QStringList skill_names = getSkills(player);
            if (skill_names.isEmpty()) return false;

            QString skill = room->askForChoice(player, objectName(), skill_names.join("+"));
            player->tag["jinbolan_get_skill"] = skill;
            room->handleAcquireDetachSkills(player, skill);

        } else {
            if (event == EventAcquireSkill && data.toString() != objectName()) return false;
            QList<ServerPlayer *> players = room->getOtherPlayers(player, true);
            if (room->findPlayersBySkillName(objectName()).length() > 1)
                players = room->getAllPlayers(true);
            foreach (ServerPlayer *p, players) {
                if (p->hasSkill("jinbolan_skill", true)) continue;
                room->attachSkillToPlayer(p, "jinbolan_skill");
            }
        }
        return false;
    }
};

class JinBolanLose : public TriggerSkill
{
public:
    JinBolanLose() : TriggerSkill("#jinbolan")
    {
        events << EventPhaseEnd << Death;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd) {
            if (player->getPhase() != Player::Play) return false;
            QString skill1 = player->tag["jinbolan_get_skill"].toString();
            QString skill2 = player->tag["jinbolan_skill_get_skill"].toString();
            player->tag.remove("jinbolan_get_skill");
            player->tag.remove("jinbolan_skill_get_skill");
            if (!skill1.isEmpty())
                room->handleAcquireDetachSkills(player, "-" + skill1);
            if (!skill2.isEmpty())
                room->handleAcquireDetachSkills(player, "-" + skill2);
        } else {
            DeathStruct death = data.value<DeathStruct>();
            QString skill1 = death.who->tag["jinbolan_get_skill"].toString();
            QString skill2 = death.who->tag["jinbolan_skill_get_skill"].toString();
            death.who->tag.remove("jinbolan_get_skill");
            death.who->tag.remove("jinbolan_skill_get_skill");
            if (!skill1.isEmpty())
                room->handleAcquireDetachSkills(death.who, "-" + skill1);
            if (!skill2.isEmpty())
                room->handleAcquireDetachSkills(death.who, "-" + skill2);

        }
        return false;
    }
};

JinBolanSkillCard::JinBolanSkillCard()
{
    mute = true;
    m_skillName = "jinbolan_skill";
}

bool JinBolanSkillCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->hasSkill("jinbolan") && to_select != Self && to_select->getMark("jinbolan-PlayClear") <= 0;
}

void JinBolanSkillCard::onEffect(const CardEffectStruct &effect) const
{
    if (!effect.to->hasSkill("jinbolan")) return;

    Room *room = effect.from->getRoom();
    room->addPlayerMark(effect.to, "jinbolan-PlayClear");

    room->notifySkillInvoked(effect.to, "jinbolan");
    room->broadcastSkillInvoke("jinbolan");

    room->loseHp(effect.from);

    QStringList skill_names = JinBolan::getSkills(effect.from);
    if (skill_names.isEmpty() || effect.to->isDead()) return;

    QString skill = room->askForChoice(effect.to, "jinbolan_skill", skill_names.join("+"), QVariant::fromValue(effect.from));
    if (effect.from->isDead()) return;

    effect.from->tag["jinbolan_skill_get_skill"] = skill;
    room->handleAcquireDetachSkills(effect.from, skill);
}

class JinBolanSkill : public ZeroCardViewAsSkill
{
public:
    JinBolanSkill() : ZeroCardViewAsSkill("jinbolan_skill")
    {
        attached_lord_skill = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return hasTarget(player);
    }

    bool hasTarget(const Player *player) const
    {
        QList<const Player *> as = player->getAliveSiblings();
        foreach (const Player *p, as) {
            if (p->hasSkill("jinbolan") && p->getMark("jinbolan-PlayClear") <= 0)
                return true;
        }
        return false;
    }

    const Card *viewAs() const
    {
        return new JinBolanSkillCard;
    }
};

class JinYifa : public TriggerSkill
{
public:
    JinYifa() : TriggerSkill("jinyifa")
    {
        events << TargetSpecified << EventPhaseChanging;
        frequency = Compulsory;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TargetSpecified) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash") || (use.card->isBlack() && use.card->isNDTrick())) {
                foreach (ServerPlayer *p, use.to) {
                    if (player->isDead()) return false;
                    if (p->isDead() || !p->hasSkill(this) || p == use.from) continue;
                    room->sendCompulsoryTriggerLog(p, objectName(), true, true);
                    room->addPlayerMark(player, "&jinyifa");
                }
            }
        } else {
            if (player->getMark("&jinyifa") <= 0) return false;
            if (data.value<PhaseChangeStruct>().to != Player::NotActive) return false;
            room->setPlayerMark(player, "&jinyifa", 0);
        }
        return false;
    }
};

class JinYifaMax : public MaxCardsSkill
{
public:
    JinYifaMax() : MaxCardsSkill("#jinyifa")
    {
    }

    int getExtra(const Player *target) const
    {
        return -target->getMark("&jinyifa");
    }
};

class JinCanmou : public TriggerSkill
{
public:
    JinCanmou() : TriggerSkill("jincanmou")
    {
        events << TargetSpecifying;
    }

    bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isNDTrick() || use.card->isKindOf("Collateral")) return false;

        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (player->isDead()) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;

            int hand = player->getHandcardNum();
            foreach (ServerPlayer *q, room->getOtherPlayers(player)) {
                if (q->getHandcardNum() >= hand) return false;
            }
            QList<ServerPlayer *> targets = room->getCardTargets(player, use.card, use.to);
            if (targets.isEmpty()) return false;

            p->tag["JincanmouData"] = data;
            ServerPlayer *t = room->askForPlayerChosen(p, targets, objectName(), "@jincanmou-target:" + use.card->objectName(), true, true);
            p->tag.remove("JincanmouData");
            if (!t) continue;
            room->broadcastSkillInvoke(this);
            use.to << t;
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

class JinCongjian : public TriggerSkill
{
public:
    JinCongjian() : TriggerSkill("jincongjian")
    {
        events << TargetConfirming;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isNDTrick() || use.card->isKindOf("Collateral")) return false;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (use.to.length() != 1) return false;
            if (p->isDead() || !p->hasSkill(this)) continue;

            int hp = player->getHp();
            foreach (ServerPlayer *q, room->getOtherPlayers(player)) {
                if (q->getHp() >= hp) return false;
            }

            if (use.from && !use.from->canUse(use.card, p, true)) continue;
            p->tag["JincongjianData"] = data;
            bool invoke = p->askForSkillInvoke(this, "jincongjian:" + use.card->objectName());
            p->tag.remove("JincongjianData");
            if (!invoke) continue;
            use.to << p;
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
            room->setCardFlag(use.card, "jincongjian_" + p->objectName());
        }
        return false;
    }
};

class JinCongjianEffect : public TriggerSkill
{
public:
    JinCongjianEffect() : TriggerSkill("#jincongjian-effect")
    {
        events << DamageDone << CardFinished;
    }

    bool triggerable(const ServerPlayer *) const
    {
        return true;
    }

    bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->hasFlag("jincongjian_" + player->objectName())) return false;
            room->setCardFlag(damage.card, "jincongjian_damage_" + player->objectName());
        } else {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card->isNDTrick()) return false;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isDead()) continue;
                if (!use.card->hasFlag("jincongjian_damage_" + p->objectName())) continue;
                p->drawCards(2, "jincongjian");
            }
        }
        return false;
    }
};

JiePackage::JiePackage()
    : Package("jie-package")
{

    General *jin_zhongyan = new General(this, "jin_zhongyan", "jin", 3, false);
    jin_zhongyan->addSkill(new JinBolan);
    jin_zhongyan->addSkill(new JinBolanLose);
    jin_zhongyan->addSkill(new JinYifa);
    jin_zhongyan->addSkill(new JinYifaMax);
    related_skills.insertMulti("jinbolan", "#jinbolan");
    related_skills.insertMulti("jinyifa", "#jinyifa");

    General *jin_xinchang = new General(this, "jin_xinchang", "jin", 3);
    jin_xinchang->addSkill(new JinCanmou);
    jin_xinchang->addSkill(new JinCongjian);
    jin_xinchang->addSkill(new JinCongjianEffect);
    related_skills.insertMulti("jincongjian", "#jincongjian-effect");

    addMetaObject<JinBolanSkillCard>();

    skills << new JinBolanSkill;
}

ADD_PACKAGE(Jie)
