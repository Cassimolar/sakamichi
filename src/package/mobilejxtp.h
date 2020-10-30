#ifndef MOBILEJXTP_H
#define MOBILEJXTP_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "wind.h"

class MobileJXTPPackage : public Package
{
    Q_OBJECT

public:
    MobileJXTPPackage();
};

class MobileQingjianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileQingjianCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileQiangxiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileQiangxiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileNiepanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileNiepanCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class MobileZaiqiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileZaiqiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobilePoluCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobilePoluCard();
    bool targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MobileTiaoxinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileTiaoxinCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileZhijianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileZhijianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileFangquanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileFangquanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileGanluCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileGanluCard();
    void swapEquip(ServerPlayer *first, ServerPlayer *second) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MobileJieyueCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileJieyueCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class MobileAnxuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileAnxuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MobileGongqiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileGongqiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileZongxuanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileZongxuanCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class MobileZongxuanPutCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileZongxuanPutCard();
    void use(Room *, ServerPlayer *, QList<ServerPlayer *> &) const;
};

class MobileJunxingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileJunxingCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileMiejiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileMiejiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileMiejiDiscardCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileMiejiDiscardCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class MobileXianzhenCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileXianzhenCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileQiaoshuiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileQiaoshuiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MobileZongshihCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileZongshihCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class MobileDingpinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileDingpinCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileShenxingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileShenxingCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MobileBingyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileBingyiCard();

    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MobileJianyingDialog : public GuhuoDialog
{
    Q_OBJECT

public:
    static MobileJianyingDialog *getInstance(const QString &object);

protected:
    explicit MobileJianyingDialog(const QString &object);
    bool isButtonEnabled(const QString &button_name) const;
};

class MobileJianyingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileJianyingCard();
    bool targetFixed() const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &card_use) const;
};

class MobileYanzhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileYanzhuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileXingxueCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileXingxueCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    bool hasAliveTargets(ServerPlayer *player, QList<ServerPlayer *> &targets) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

#endif
