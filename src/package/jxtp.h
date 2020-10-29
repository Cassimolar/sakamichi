#ifndef JXTP_H
#define JXTP_H

#include "package.h"
#include "card.h"
#include "skill.h"

class JXTPPackage : public Package
{
    Q_OBJECT

public:
    JXTPPackage();
};

class TenyearZhihengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearZhihengCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearJieyinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearJieyinCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearRendeCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearRendeCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearYijueCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearYijueCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearQingjianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearQingjianCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearQingnangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearQingnangCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearQimouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearQimouCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearShensuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearShensuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class TenyearJushouCard :public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearJushouCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class TenyearTianxiangCard :public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearTianxiangCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearSanyaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearSanyaoCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearChunlaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearChunlaoCard();
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearChunlaoWineCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearChunlaoWineCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearJiangchiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearJiangchiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearWurongCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearWurongCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearDanshouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearDanshouCard();
};

class TenyearKuangfuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearKuangfuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearAnguoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearAnguoCard();
    bool isOK(ServerPlayer *player, const QString &flag) const;
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
