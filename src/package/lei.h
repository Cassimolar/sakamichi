#ifndef LEI_H
#define LEI_H

#include "package.h"
#include "card.h"
#include "skill.h"

class LeiPackage : public Package
{
    Q_OBJECT

public:
    LeiPackage();
};

class JueyanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JueyanCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class HuairouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HuairouCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class HongjuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HongjuCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class QingceCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QingceCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class XiongluanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XiongluanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class OLHongjuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLHongjuCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class OLQingceCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLQingceCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileHongjuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileHongjuCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

#endif
