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

class OLFanghunCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLFanghunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &card_use) const;
    const Card *validateInResponse(ServerPlayer *player) const;
};

class  XionghuoCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE XionghuoCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  YingshiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE YingshiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class  ZengdaoCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZengdaoCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  ZengdaoRemoveCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZengdaoRemoveCard();
    void onUse(Room *room, const CardUseStruct &) const;
};

class  GusheCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE GusheCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    int pindian(ServerPlayer *from, ServerPlayer *to, const Card *card1, const Card *card2) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class  DaoshuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DaoshuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  SpZhaoxinCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpZhaoxinCard();
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class  SpZhaoxinChooseCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpZhaoxinChooseCard();
};

class  YinjuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE YinjuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  BusuanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE BusuanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  SpQianxinCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpQianxinCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  JijieCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JijieCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class  ZiyuanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZiyuanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  FumanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE FumanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  TunanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TunanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  JianjiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JianjiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  YizanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE YizanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetFixed() const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    const Card *validate(CardUseStruct &use) const;
    const Card *validateInResponse(ServerPlayer *player) const;
};

class  WuyuanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE WuyuanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  DingpanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DingpanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  ShanxiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ShanxiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class  GuolunCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE GuolunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  DuanfaCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DuanfaCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class  QinguoCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE QinguoCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class  ZhafuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZhafuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  SongshuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SongshuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  FuhaiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE FuhaiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class  MobileFuhaiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileFuhaiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class  LianzhuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE LianzhuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class  SpCanshiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpCanshiCard();
    bool targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class  LvemingCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE LvemingCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  TunjunCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TunjunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    QList<int> removeList(QList<int> equips, QList<int> ids) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  DenglouCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DenglouCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class  MobileLiezhiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileLiezhiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class  JianjieCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JianjieCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class  JianjieHuojiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JianjieHuojiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class  JianjieLianhuanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JianjieLianhuanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class JianjieYeyanCard : public SkillCard
{
    Q_OBJECT

public:
    void damage(ServerPlayer *shenzhouyu, ServerPlayer *target, int point) const;
};

class GreatJianjieYeyanCard : public JianjieYeyanCard
{
    Q_OBJECT

public:
    Q_INVOKABLE GreatJianjieYeyanCard();

    bool targetFilter(const QList<const Player *> &targets,const Player *to_select, const Player *Self) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select,const Player *Self, int &maxVotes) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class SmallJianjieYeyanCard : public JianjieYeyanCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SmallJianjieYeyanCard();
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class LuanzhanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE LuanzhanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class NeifaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE NeifaCard();
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class FenglveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FenglveCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class MoushiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MoushiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class JixuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JixuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class KannanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE KannanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class FangtongCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FangtongCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class FenyueCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FenyueCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class SpKuizhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SpKuizhuCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class ZhiyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhiyiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class PingcaiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE PingcaiCard();
    bool isOK(Room *room, const QString &name) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class PingcaiWolongCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE PingcaiWolongCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class PingcaiFengchuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE PingcaiFengchuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class WaishiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE WaishiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class GaoyuanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE GaoyuanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class YizhengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YizhengCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class XingZhilveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XingZhilveCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class XingZhilveSlashCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XingZhilveSlashCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class XingZhiyanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XingZhiyanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class XingZhiyanDrawCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XingZhiyanDrawCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class XingJinfanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XingJinfanCard();
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class TanbeiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TanbeiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SidaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SidaoCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class LimuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE LimuCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class LijiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE LijiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class JuesiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JuesiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class JianshuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JianshuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class NewxuehenCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE NewxuehenCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class LizhanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE LizhanCard();
    bool targetFilter(const QList<const Player *> &, const Player *to_select, const Player *) const;
    void use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const;
};

class WeikuiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE WeikuiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MubingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MubingCard();
    void onUse(Room *, const CardUseStruct &) const;
};

class ZiquCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZiquCard();
    void onUse(Room *, const CardUseStruct &) const;
};


#endif

