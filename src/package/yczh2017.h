#ifndef YCZH2017_H
#define YCZH2017_H

#include "package.h"
#include "card.h"
#include "skill.h"

class YCZH2017Package : public Package
{
    Q_OBJECT

public:
    YCZH2017Package();
};

class FumianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FumianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class ZhongjianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhongjianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class WenguagiveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE WenguagiveCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class WenguaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE WenguaCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class HuiminCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HuiminCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class TongboCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TongboCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class MobileQingxianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileQingxianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileCanyunCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileCanyunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearZhongjianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearZhongjianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class OLZhongjianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLZhongjianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
