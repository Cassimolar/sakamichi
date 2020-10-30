#ifndef MOBILEMOUSHI_H
#define MOBILEMOUSHI_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileMouShiPackage : public Package
{
    Q_OBJECT

public:
    MobileMouShiPackage();
};

class MobileMouDuanliangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileMouDuanliangCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileMouShipoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileMouShipoCard();
    void onUse(Room *room, const CardUseStruct &use) const;
};

#endif
