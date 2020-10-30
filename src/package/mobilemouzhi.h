#ifndef MOBILEMOUZHI_H
#define MOBILEMOUZHI_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileMouZhiPackage : public Package
{
    Q_OBJECT

public:
    MobileMouZhiPackage();
};

class MobileMouZhihengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileMouZhihengCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

#endif
