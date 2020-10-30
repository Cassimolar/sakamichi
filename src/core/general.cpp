#include "general.h"
#include "engine.h"
#include "skill.h"
#include "package.h"
#include "client.h"
#include "clientstruct.h"
#include "settings.h"

General::General(Package *package, const QString &name, const QString &kingdom,
    int max_hp, bool male, bool hidden, bool never_shown, int start_hp, int start_hujia)
    : QObject(package), kingdom(kingdom), max_hp(max_hp), gender(male ? Male : Female),
    hidden(hidden), never_shown(never_shown), start_hp(start_hp), start_hujia(start_hujia)
{
    static QChar lord_symbol('$');
    if (name.endsWith(lord_symbol)) {
        QString copy = name;
        copy.remove(lord_symbol);
        lord = true;
        setObjectName(copy);
    } else {
        lord = false;
        setObjectName(name);
    }
}

int General::getMaxHp() const
{
    return max_hp;
}

QString General::getKingdom() const
{
    QStringList kins = kingdom.split("+");
    QString kin = kins.first();
    if (kin == "god" && kins.length() > 1) {
        foreach (QString king, kins) {
            if (king == "god") continue;
            kin = king;
            break;
        }
    }
    return kin;
}

QString General::getKingdoms() const
{
    return kingdom;
}

bool General::isMale() const
{
    return gender == Male;
}

bool General::isFemale() const
{
    return gender == Female;
}

bool General::isNeuter() const
{
    return gender == Neuter;
}

bool General::isSexless() const
{
    return gender == Sexless;
}

void General::setGender(Gender gender)
{
    this->gender = gender;
}

General::Gender General::getGender() const
{
    return gender;
}

bool General::isLord() const
{
    return lord;
}

bool General::isHidden() const
{
    return hidden;
}

bool General::isTotallyHidden() const
{
    return never_shown;
}

void General::setStartHp(int hp)
{
    this->start_hp = qMin(hp, max_hp);
}

int General::getStartHp() const
{
    return qMin(start_hp, max_hp);
}

void General::setStartHujia(int hujia)
{
    this->start_hujia = hujia;
}

int General::getStartHujia() const
{
    return start_hujia;
}

void General::setImage(const QString &general_name)
{
    this->image = general_name;
}

QString General::getImage() const
{
    return image;
}

void General::addSkill(Skill *skill)
{
    if (!skill) {
        QMessageBox::warning(NULL, "", tr("Invalid skill added to general %1").arg(objectName()));
        return;
    }
    if (!skillname_list.contains(skill->objectName())) {
        skill->setParent(this);
        skillname_list << skill->objectName();
    }
}

void General::addSkill(const QString &skill_name)
{
    if (!skillname_list.contains(skill_name)) {
        extra_set.insert(skill_name);
        skillname_list << skill_name;
    }
}

bool General::hasSkill(const QString &skill_name) const
{
    return skillname_list.contains(skill_name);
}

QList<const Skill *> General::getSkillList() const
{
    QList<const Skill *> skills;
    foreach (QString skill_name, skillname_list) {
        if (skill_name == "mashu" && ServerInfo.DuringGame
            && ServerInfo.GameMode == "02_1v1" && ServerInfo.GameRuleMode != "Classical")
            skill_name = "xiaoxi";
        const Skill *skill = Sanguosha->getSkill(skill_name);
        skills << skill;
    }
    return skills;
}

QList<const Skill *> General::getVisibleSkillList() const
{
    QList<const Skill *> skills;
    foreach (const Skill *skill, getSkillList()) {
        if (skill->isVisible())
            skills << skill;
    }

    return skills;
}

QSet<const Skill *> General::getVisibleSkills() const
{
    return getVisibleSkillList().toSet();
}

QSet<const TriggerSkill *> General::getTriggerSkills() const
{
    QSet<const TriggerSkill *> skills;
    foreach (QString skill_name, skillname_list) {
        const TriggerSkill *skill = Sanguosha->getTriggerSkill(skill_name);
        if (skill)
            skills << skill;
    }
    return skills;
}

void General::addRelateSkill(const QString &skill_name)
{
    related_skills << skill_name;
}

QStringList General::getRelatedSkillNames() const
{
    return related_skills;
}

QString General::getPackage() const
{
    QObject *p = parent();
    if (p)
        return p->objectName();
    else
        return QString(); // avoid null pointer exception;
}

QString General::getSkillDescription(bool include_name) const
{
    QString description;

    QList<const Skill *> skills = getVisibleSkillList();
    QList<const Skill *> relatedskills;

    foreach (const Skill *skill, skills) {
        QString waked_skill = skill->getWakedSkills();
        if (waked_skill.isEmpty()) continue;
        QStringList waked_skills = waked_skill.split(",");
        foreach (QString sk, waked_skills) {
            const Skill *ski = Sanguosha->getSkill(sk);
            if (ski && ski->isVisible() && !skills.contains(ski)) {
                skills << ski;
                if (!relatedskills.contains(ski))
                    relatedskills << ski;
            }
        }
    }

    foreach (const QString &skill_name, getRelatedSkillNames()) {
        const Skill *skill = Sanguosha->getSkill(skill_name);
        if (skill && skill->isVisible() && !skills.contains(skill)) {
            skills << skill;
            if (!relatedskills.contains(skill))
                relatedskills << skill;
        }
    }

    foreach (const Skill *skill, skills) {
        QString skill_name = Sanguosha->translate(skill->objectName());
        QString desc = skill->getDescription();
        desc.replace("\n", "<br/>");
        if (!relatedskills.contains(skill))
            description.append(QString("<b>%1</b>: %2 <br/> <br/>").arg(skill_name).arg(desc));
        else
            description.append(QString("<font color=\"#01A5AF\"><b>%1</b></font>: <font color=\"#01A5AF\">%2</font> <br/> <br/>").arg(skill_name).arg(desc));
    }

    if (include_name) {
        QString name;
        QStringList kins = kingdom.split("+");
        QString color_str = Sanguosha->getKingdomColor(kins.first()).name();
        foreach (QString kin, kins)
            name.append(QString("<img src='image/kingdom/icon/%1.png'/>").arg(kin));
        name.append("     ").append(QString("<font color=%1><b>%2</b></font>     ").arg(color_str).arg(Sanguosha->translate(objectName())));

        int hujia = getStartHujia();
        if (hujia > 0)
            name.append("<img src='image/mark/@HuJia.png' height = 17/>").append("x").append(QString::number(hujia)).append("     ");

        int start_hp = getStartHp();
        start_hp = qMin(start_hp, max_hp);
        if (start_hp != max_hp) {
            for (int i = 0; i < start_hp; i++)
                name.append("<img src='image/system/magatamas/5.png' height = 12/>");
            for (int i = 0; i < max_hp - start_hp; i++)
                name.append("<img src='image/system/magatamas/0.png' height = 12/>");
        } else {
            for (int i = 0; i < max_hp; i++)
                name.append("<img src='image/system/magatamas/5.png' height = 12/>");
        }

        QString gender("  <img src='image/gender/%1.png' height=17 />");
        if (isMale())
            name.append(gender.arg("male"));
        else if (isFemale())
            name.append(gender.arg("female"));
        else if (isNeuter())
            name.append(gender.arg("neuter"));
        else if (isSexless())
            name.append(gender.arg("sexless"));

        name.append("<br/> <br/>");
        description.prepend(name);
    }

    return description;
}

QString General::getBriefName() const
{
    QString name = Sanguosha->translate("&" + objectName());
    if (name.startsWith("&"))
        name = Sanguosha->translate(objectName());

    return name;
}

void General::lastWord() const
{
    QString filename;
    int skin_index = Config.value(QString("HeroSkin/%1").arg(objectName()), 0).toInt();
    if (skin_index > 0) {
        filename = QString("image/heroskin/audio/%1/death/%2.ogg").arg(objectName() + "_" + QString::number(skin_index)).arg(objectName());
        if (QFile::exists(filename)) {
            Sanguosha->playAudioEffect(filename);
            return;
        }
    }

    filename = QString("audio/death/%1.ogg").arg(objectName());
    if (QFile::exists(filename)) {
        Sanguosha->playAudioEffect(filename);
        return;
    }

    QStringList origin_generals = objectName().split("_");
    if (origin_generals.length() > 1) {
        QString origin_general = origin_generals.last();
        if (Sanguosha->getGeneral(origin_general)) {
            skin_index = Config.value(QString("HeroSkin/%1").arg(origin_general), 0).toInt();
            if (skin_index > 0) {
                filename = QString("image/heroskin/audio/%1/death/%2.ogg").arg(origin_general + "_" + QString::number(skin_index)).arg(origin_general);
                if (QFile::exists(filename)) {
                    Sanguosha->playAudioEffect(filename);
                    return;
                }
            }
            filename = QString("audio/death/%1.ogg").arg(origin_general);
            Sanguosha->playAudioEffect(filename);
        }
    }
}

bool General::hasHideSkill() const
{
    foreach (const Skill *skill, getSkillList()) {
        if (skill->isHideSkill())
            return true;
    }
    return false;
}
