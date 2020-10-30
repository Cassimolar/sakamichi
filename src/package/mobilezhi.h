#ifndef MOBILEZHI_H
#define MOBILEZHI_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileZhiPackage : public Package
{
    Q_OBJECT

public:
    MobileZhiPackage();
};

class MobileZhiQiaiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileZhiQiaiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileZhiShamengCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileZhiShamengCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondMobileZhiZuiciCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondMobileZhiZuiciCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class SecondMobileZhiZuiciMarkCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondMobileZhiZuiciMarkCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void onUse(Room *, const CardUseStruct &card_use) const;
};

class MobileZhiDuojiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileZhiDuojiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileZhiJianzhanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileZhiJianzhanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondMobileZhiDuojiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondMobileZhiDuojiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondMobileZhiDuojiRemove : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondMobileZhiDuojiRemove();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class MobileZhiWanweiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileZhiWanweiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileZhiJianyuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileZhiJianyuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MobileZhiMiewuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileZhiMiewuCard();
    bool targetFixed() const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &card_use) const;
    const Card *validateInResponse(ServerPlayer *user) const;
};

#endif
