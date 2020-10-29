#ifndef DOUDIZHU_H
#define DOUDIZHU_H

#include "package.h"
#include "card.h"
#include "skill.h"

class DoudizhuPackage : public Package
{
    Q_OBJECT

public:
    DoudizhuPackage();
};

class FeiyangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FeiyangCard();
    void onUse(Room *room, const CardUseStruct &) const;
};

#endif
