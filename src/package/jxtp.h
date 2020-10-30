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
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
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

class TenyearTuxiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearTuxiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
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

class TenyearTianxiangCard :public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearTianxiangCard(QString this_skill_name = "tenyeartianxiang");
    void onEffect(const CardEffectStruct &effect) const;
private:
    QString this_skill_name;
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
    Q_INVOKABLE TenyearChunlaoCard(QString tenyearchunlao = "tenyearchunlao");
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
private:
    QString tenyearchunlao;
};

class TenyearChunlaoWineCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearChunlaoWineCard(QString tenyearchunlao = "tenyearchunlao");
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
private:
    QString tenyearchunlao;
};

class SecondTenyearChunlaoCard : public TenyearChunlaoCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SecondTenyearChunlaoCard();
};

class SecondTenyearChunlaoWineCard : public TenyearChunlaoWineCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SecondTenyearChunlaoWineCard();
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

class TenyearKuangfuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearKuangfuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearYanzhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearYanzhuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearXingxueCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearXingxueCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const;
};

class TenyearShenduanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearShenduanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class TenyearQiaoshuiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearQiaoshuiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearQiaoshuiTargetCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearQiaoshuiTargetCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class TenyearAocaiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearAocaiCard();
    bool targetFixed() const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validateInResponse(ServerPlayer *user) const;
    const Card *validate(CardUseStruct &cardUse) const;
};

class TenyearDuwuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearDuwuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearXianzhenCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearXianzhenCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondTenyearXianzhenCard : public TenyearXianzhenCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SecondTenyearXianzhenCard();
};

class TenyearZishouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearZishouCard();
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearyongjinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearyongjinCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearXuanhuoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearXuanhuoCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearSidiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearSidiCard();
    void use(Room *room, ServerPlayer *, QList<ServerPlayer *> &) const;
};

class TenyearHuaiyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearHuaiyiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class TenyearHuaiyiSnatchCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearHuaiyiSnatchCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class TenyearGongqiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearGongqiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class TenyearJiefanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearJiefanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearXianzhouDamageCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearXianzhouDamageCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
};

class TenyearXianzhouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearXianzhouCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearShenxingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearShenxingCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TenyearBingyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearBingyiCard();

    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

#endif
