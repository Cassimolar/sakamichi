#ifndef BEI_H
#define BEI_H

#include "package.h"
#include "card.h"
#include "skill.h"

class BeiPackage : public Package
{
    Q_OBJECT

public:
    BeiPackage();
};

class JinYishiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinYishiCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class JinShiduCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinShiduCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class JinRuilveGiveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinRuilveGiveCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
