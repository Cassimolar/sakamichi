#ifndef MOBILEXIN_H
#define MOBILEXIN_H

#include "package.h"
#include "card.h"
#include "skill.h"

class MobileXinPackage : public Package
{
    Q_OBJECT

public:
    MobileXinPackage();
};

class MobileXinYinjuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileXinYinjuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileXinCunsiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileXinCunsiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileXinMouliCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileXinMouliCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileXinChuhaiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileXinChuhaiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class MobileXinLirangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileXinLirangCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class MobileXinRongbeiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileXinRongbeiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondMobileXinMouliCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondMobileXinMouliCard();
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
