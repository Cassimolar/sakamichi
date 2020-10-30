#ifndef YINHU_H
#define YINHU_H

#include "package.h"
#include "standard.h"

class YinhuPackage : public Package
{
    Q_OBJECT

public:
    YinhuPackage();
};

class YHShecuoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHShecuoCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class YHYijieCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHYijieCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class YHZhushiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHZhushiCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class YHBianzhanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHBianzhanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class YHHuntianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHHuntianCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class YHJuxianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHJuxianCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class YHBuquePutCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHBuquePutCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class YHBuqueCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHBuqueCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &card_use) const;
    const Card *validateInResponse(ServerPlayer *source) const;
};

class YHXijianGiveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHXijianGiveCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class YHQuanwangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHQuanwangCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class YHPodiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHPodiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class YHYurenCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHYurenCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetFixed() const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &use) const;
    const Card *validateInResponse(ServerPlayer *player) const;
};

class YHMeiyingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHMeiyingCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class YHKunmoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YHKunmoCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetFixed() const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

#endif
