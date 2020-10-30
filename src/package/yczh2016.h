#ifndef YCZH2016_H
#define YCZH2016_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "wind.h"

class YCZH2016Package : public Package
{
    Q_OBJECT

public:
    YCZH2016Package();
};

class JiaozhaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JiaozhaoCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class JiyuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JiyuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class DuliangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE DuliangCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class QinqingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QinqingCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class HuishengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HuishengCard();
};

class KuangbiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE KuangbiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class JisheDrawCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JisheDrawCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class JisheCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JisheCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class ZhigeCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhigeCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TaoluanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TaoluanCard(QString this_skill_name = "taoluan");
    bool targetFixed() const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &card_use) const;
    const Card *validateInResponse(ServerPlayer *zhangrang) const;
private:
    QString this_skill_name;
};

class TaoluanDialog : public GuhuoDialog
{
    Q_OBJECT

public:
    static TaoluanDialog *getInstance(const QString &object);

protected:
    explicit TaoluanDialog(const QString &object);
    bool isButtonEnabled(const QString &button_name) const;
};

class TenyearTaoluanCard : public TaoluanCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearTaoluanCard();
};

#endif
