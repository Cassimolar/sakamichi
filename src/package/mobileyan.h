#ifndef MOBILEYAN_H
#define MOBILEYAN_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileYanPackage : public Package
{
    Q_OBJECT

public:
    MobileYanPackage();
};

class MobileYanYajunCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYanYajunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileYanYajunPutCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYanYajunPutCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class MobileYanZundiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYanZundiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileYanYanjiaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYanYanjiaoCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileYanJincuiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYanJincuiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileYanShangyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYanShangyiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_selet, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
