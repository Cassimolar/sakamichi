#ifndef MOBILEREN_H
#define MOBILEREN_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileRenPackage : public Package
{
    Q_OBJECT

public:
    MobileRenPackage();
};

class MobileRenRenshiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileRenRenshiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileRenBuqiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileRenBuqiCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class MobileRenBomingCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileRenBomingCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileRenMuzhenCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileRenMuzhenCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

/*class MobileRenYaohuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileRenYaohuCard();
    void onUse(Room *, const CardUseStruct &) const;
};*/

#endif
