#ifndef GUO_H
#define GUO_H

#include "package.h"
#include "card.h"
#include "skill.h"

class GuoPackage : public Package
{
    Q_OBJECT

public:
    GuoPackage();
};

class JinChoufaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinChoufaCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class JinYanxiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinYanxiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class JinSanchenCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinSanchenCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
