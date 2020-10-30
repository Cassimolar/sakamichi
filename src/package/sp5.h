#ifndef SP5_H
#define SP5_H

#include "package.h"
#include "card.h"
#include "standard.h"

class SP5Package : public Package
{
    Q_OBJECT

public:
    SP5Package();
};

class ZhouxuanzCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZhouxuanzCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class ZaowangCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZaowangCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class GuowuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE GuowuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class YuqiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YuqiCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class HeqiaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HeqiaCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class HeqiaUseCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HeqiaUseCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class JinhuiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinhuiCard();
    void usecard(Room *room, ServerPlayer *source, ServerPlayer *target, const Card *card) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class JinhuiUseCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinhuiUseCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class JiqiaosyCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JiqiaosyCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class XiongmangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XiongmangCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &use) const;
};

class JianliangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JianliangCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class WeimengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE WeimengCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class BoyanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE BoyanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class JinChongxinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinChongxinCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class ChanniCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ChanniCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class BaoshuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE BaoshuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class YijiaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YijiaoCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class XunliPutCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XunliPutCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class XunliCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XunliCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class ZhishiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhishiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class LieyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE LieyiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class ManwangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ManwangCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class DunshiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE DunshiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    //bool targetFixed() const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &use) const;
    const Card *validateInResponse(ServerPlayer *player) const;
};

class ChenjianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ChenjianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onUse(Room *room, const CardUseStruct &use) const;
};

class YuanyuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YuanyuCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

#endif
