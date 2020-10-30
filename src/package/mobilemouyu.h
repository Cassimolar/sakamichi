#ifndef MOBILEMOUYU_H
#define MOBILEMOUYU_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileMouYuPackage : public Package
{
    Q_OBJECT

public:
    MobileMouYuPackage();
};

class MobileMouKejiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileMouKejiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

#endif
