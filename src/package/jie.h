#ifndef JIE_H
#define JIE_H

#include "package.h"
#include "card.h"
#include "skill.h"

class JiePackage : public Package
{
    Q_OBJECT

public:
    JiePackage();
};

class JinBolanSkillCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinBolanSkillCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
