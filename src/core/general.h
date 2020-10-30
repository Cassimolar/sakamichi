#ifndef _GENERAL_H
#define _GENERAL_H

class Skill;
class TriggerSkill;
class Package;
class QSize;

class General : public QObject
{
    Q_OBJECT
    Q_ENUMS(Gender)
    Q_PROPERTY(QString kingdom READ getKingdom CONSTANT)
    Q_PROPERTY(int maxhp READ getMaxHp CONSTANT)
    Q_PROPERTY(bool male READ isMale STORED false CONSTANT)
    Q_PROPERTY(bool female READ isFemale STORED false CONSTANT)
    Q_PROPERTY(Gender gender READ getGender CONSTANT)
    Q_PROPERTY(bool lord READ isLord CONSTANT)
    Q_PROPERTY(bool hidden READ isHidden CONSTANT)

public:
    explicit General(Package *package, const QString &name, const QString &kingdom,
        int max_hp = 4, bool male = true, bool hidden = false, bool never_shown = false, int start_hp = pow(2, 31) - 1, int start_hujia = 0);

    // property getters/setters
    int getMaxHp() const;
    QString getKingdom() const;
    QString getKingdoms() const;
    bool isMale() const;
    bool isFemale() const;
    bool isNeuter() const;
    bool isSexless() const;
    bool isLord() const;
    bool isHidden() const;
    bool isTotallyHidden() const;
    void setStartHp(int hp);
    int getStartHp() const;
    void setStartHujia(int hujia);
    int getStartHujia() const;
    void setImage(const QString &general_name);
    QString getImage() const;

    enum Gender
    {
        Sexless, Male, Female, Neuter
    };
    Gender getGender() const;
    void setGender(Gender gender);

    void addSkill(Skill *skill);
    void addSkill(const QString &skill_name);
    bool hasSkill(const QString &skill_name) const;
    bool hasHideSkill() const;
    QList<const Skill *> getSkillList() const;
    QList<const Skill *> getVisibleSkillList() const;
    QSet<const Skill *> getVisibleSkills() const;
    QSet<const TriggerSkill *> getTriggerSkills() const;

    void addRelateSkill(const QString &skill_name);
    QStringList getRelatedSkillNames() const;

    QString getPackage() const;
    QString getSkillDescription(bool include_name = false) const;
    QString getBriefName() const;

    inline QSet<QString> getExtraSkillSet() const
    {
        return extra_set;
    }

public slots:
    void lastWord() const;

private:
    QString kingdom;
    int max_hp;
    Gender gender;
    bool lord;
    QSet<QString> extra_set;
    QStringList skillname_list;
    QStringList related_skills;
    bool hidden;
    bool never_shown;
    int start_hp;
    int start_hujia;
    QString image;
};

#endif

