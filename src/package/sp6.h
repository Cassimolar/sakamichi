#ifndef SP6_H
#define SP6_H

#include "package.h"
#include "card.h"
#include "standard.h"

class SP6Package : public Package
{
    Q_OBJECT

public:
    SP6Package();
};

class QianlongCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QianlongCard();
    void onUse(Room *room, const CardUseStruct &use) const;
};

#endif
