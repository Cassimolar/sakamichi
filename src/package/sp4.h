#ifndef SP4_H
#define SP4_H

#include "package.h"
#include "card.h"
#include "standard.h"

class SP4Package : public Package
{
    Q_OBJECT

public:
    SP4Package();
};

class Meirenji :public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE Meirenji(Card::Suit suit, int number);

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class Xiaolicangdao :public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE Xiaolicangdao(Card::Suit suit, int number);

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearLianjiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TenyearLianjiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class OLLianjiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE OLLianjiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileLianjiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileLianjiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class NewShuliangCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE NewShuliangCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class GuanxuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE GuanxuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class GuanxuChooseCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE GuanxuChooseCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class GuanxuDiscardCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE GuanxuDiscardCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class SpCuoruiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpCuoruiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondSpCuoruiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondSpCuoruiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TiansuanDialog : public QDialog
{
    Q_OBJECT

public:
    static TiansuanDialog *getInstance(const QString &name, const QString &choices = QString());

public slots:
    void popup();
    void selectChoice(QAbstractButton *button);

private:
    explicit TiansuanDialog(const QString &name, const QString &choices = QString());

    QAbstractButton *createChoiceButton(const QString &choice);
    bool MarkJudge(const QString &choice);
    QButtonGroup *group;
    QVBoxLayout *button_layout;
    QString tiansuan_choices;

signals:
    void onButtonClick();
};

class TiansuanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TiansuanCard();
    bool targetsFeasible(const QList<const Player *> &, const Player *) const;
    bool targetFilter(const QList<const Player *> &, const Player *, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class JuguanDialog : public QDialog
{
    Q_OBJECT

public:
    static JuguanDialog *getInstance(const QString &object, const QString &card_names);

public slots:
    void popup();
    void selectCard(QAbstractButton *button);

private:
    explicit JuguanDialog(const QString &object, const QString &card_names);

    virtual bool MarkJudge(const QString &button_name) const;
    virtual bool isButtonEnabled(const QString &button_name) const;
    QAbstractButton *createButton(const Card *card);
    QHash<QString, const Card *> map;
    QButtonGroup *group;
    QVBoxLayout *button_layout;
    QString cards;

signals:
    void onButtonClick();
};

class JuguanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JuguanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class QuxiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QuxiCard();
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class LiehouCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE LiehouCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearHuoshuiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TenyearHuoshuiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearQingchengCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TenyearQingchengCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class CuijianCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE CuijianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondCuijianCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondCuijianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class QingtanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QingtanCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class ZhukouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhukouCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class DifaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE DifaCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class ZhuningCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhuningCard();
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
