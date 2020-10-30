#ifndef OLJXTP_H
#define OLJXTP_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "jxtp.h"
#include "standard-skillcards.h"
#include "mountain.h"

class OLJXTPPackage : public Package
{
    Q_OBJECT

public:
    OLJXTPPackage();
};

class OLJijiangCard : public JijiangCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLJijiangCard();
};

class OLHuangtianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLHuangtianCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
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

class OLTianxiangCard : public TenyearTianxiangCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLTianxiangCard();
};

class SecondOLHanzhanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SecondOLHanzhanCard();
    void onUse(Room *, const CardUseStruct &) const;
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

class OLChangbiaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLChangbiaoCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class OLTiaoxinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLTiaoxinCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class OLZaiqiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLZaiqiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class OLQiaobianCard : public QiaobianCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLQiaobianCard();
};

#endif
