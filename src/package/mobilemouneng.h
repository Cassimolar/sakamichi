#ifndef MOBILEMOUNENG_H
#define MOBILEMOUNENG_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileMouNengPackage : public Package
{
    Q_OBJECT

public:
    MobileMouNengPackage();
};

class MobileMouYangweiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileMouYangweiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

#endif
