#ifndef MOBILEYONG_H
#define MOBILEYONG_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileYongPackage : public Package
{
    Q_OBJECT

public:
    MobileYongPackage();
};

class MobileYongJungongCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYongJungongCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

#endif
