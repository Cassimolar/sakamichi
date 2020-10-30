#ifndef JXTP2_H
#define JXTP2_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "sp4.h"

class JXTP2Package : public Package
{
    Q_OBJECT

public:
    JXTP2Package();
};

class TenyearZongxuanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearZongxuanCard();
    void use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const;
};

class TenyearYjYanyuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearYjYanyuCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class TenyearJiaozhaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearJiaozhaoCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearGanluCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearGanluCard();
    void swapEquip(ServerPlayer *first, ServerPlayer *second) const;

    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class TenyearJianyanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearJianyanCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class TenyearAnxuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearAnxuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

#endif
