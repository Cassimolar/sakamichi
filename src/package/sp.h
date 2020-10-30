#ifndef _SP_H
#define _SP_H

#include "package.h"
#include "card.h"
#include "standard.h"
#include "wind.h"

class SPPackage : public Package
{
    Q_OBJECT

public:
    SPPackage();
};

class MiscellaneousPackage : public Package
{
    Q_OBJECT

public:
    MiscellaneousPackage();
};

class SPCardPackage : public Package
{
    Q_OBJECT

public:
    SPCardPackage();
};

class HegemonySPPackage : public Package
{
    Q_OBJECT

public:
    HegemonySPPackage();
};

class SPMoonSpear : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE SPMoonSpear(Card::Suit suit = Diamond, int number = 12);
};

class Yongsi : public TriggerSkill
{
public:
    Yongsi();
    bool trigger(TriggerEvent triggerEvent, Room *room, ServerPlayer *yuanshu, QVariant &data) const;

protected:
    virtual int getKingdoms(ServerPlayer *yuanshu) const;
};

class WeidiDialog : public QDialog
{
    Q_OBJECT

public:
    static WeidiDialog *getInstance();

public slots:
    void popup();
    void selectSkill(QAbstractButton *button);

private:
    explicit WeidiDialog();

    QAbstractButton *createSkillButton(const QString &skill_name);
    QButtonGroup *group;
    QVBoxLayout *button_layout;

signals:
    void onButtonClick();
};

class YuanhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YuanhuCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class XuejiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XuejiCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class BifaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE BifaCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class SongciCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SongciCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class QiangwuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QiangwuCard();

    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class YinbingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YinbingCard();

    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class XiemuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XiemuCard();

    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class ShefuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ShefuCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class ShefuDialog : public GuhuoDialog
{
    Q_OBJECT

public:
    static ShefuDialog *getInstance(const QString &object);

protected:
    explicit ShefuDialog(const QString &object);
    bool isButtonEnabled(const QString &button_name) const;
};

class OLXingwuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLXingwuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearXingwuCard : public OLXingwuCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearXingwuCard();
};

class ZhoufuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhoufuCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class QujiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QujiCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class XintanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XintanCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MeibuFilter : public FilterSkill
{
public:
    MeibuFilter(const QString &skill_name);

    bool viewFilter(const Card *to_select) const;

    const Card *viewAs(const Card *originalCard) const;

private:
    QString n;
};

class XionghuoCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE XionghuoCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class LianzhuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE LianzhuCard(QString lianzhu = "lianzhu");
    void onEffect(const CardEffectStruct &effect) const;
private:
    QString lianzhu;
};

class TenyearLianzhuCard : public LianzhuCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TenyearLianzhuCard();
};

class SpCanshiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpCanshiCard();
    bool targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class FanghunCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FanghunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &card_use) const;
    const Card *validateInResponse(ServerPlayer *player) const;
};

class OLFanghunCard : public FanghunCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLFanghunCard();
};

class MobileFanghunCard : public FanghunCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileFanghunCard();
};

class TenyearFanghunCard : public FanghunCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearFanghunCard();
};

class MobileXushenCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileXushenCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class OLZhennanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE OLZhennanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class ShanjiaCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ShanjiaCard(QString shanjia = "shanjia");
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
private:
    QString shanjia;
};

class OLShanjiaCard : public ShanjiaCard
{
    Q_OBJECT
public:
    Q_INVOKABLE OLShanjiaCard();
};

class YingshiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE YingshiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class ZengdaoCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZengdaoCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class ZengdaoRemoveCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZengdaoRemoveCard();
    void onUse(Room *room, const CardUseStruct &) const;
};

#endif
