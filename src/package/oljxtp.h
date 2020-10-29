#ifndef OLJXTP_H
#define OLJXTP_H

#include "package.h"
#include "card.h"
#include "skill.h"

class OLJXTPPackage : public Package
{
    Q_OBJECT

public:
    OLJXTPPackage();
};

class OLGuhuoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLGuhuoCard();
    bool olguhuo(ServerPlayer *yuji) const;

    bool targetFixed() const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;

    const Card *validate(CardUseStruct &card_use) const;
    const Card *validateInResponse(ServerPlayer *user) const;
};

class OLQimouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLQimouCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class OLWulieCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLWulieCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class OLFangquanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLFangquanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class OLZhibaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLZhibaCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class OLZhibaPindianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLZhibaPindianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
