#ifndef YIN_H
#define YIN_H

#include "package.h"
#include "card.h"
#include "skill.h"

class YinPackage : public Package
{
    Q_OBJECT

public:
    YinPackage();
};

class FeijunCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FeijunCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class KuizhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE KuizhuCard();
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class ShenshiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ShenshiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class ChenglveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ChenglveCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class ZhenliangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhenliangCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
