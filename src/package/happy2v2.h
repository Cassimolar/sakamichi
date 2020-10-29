#ifndef HAPPY2V2_H
#define HAPPY2V2_H

#include "package.h"
#include "card.h"
#include "skill.h"

class Happy2v2Package : public Package
{
    Q_OBJECT

public:
    Happy2v2Package();
};

class KuijiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE KuijiCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

#endif
