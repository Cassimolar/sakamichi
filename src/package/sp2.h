#ifndef SP2_H
#define SP2_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "standard.h"
#include "wind.h"

class SP2Package : public Package
{
    Q_OBJECT

public:
    SP2Package();
};

class LvemingCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE LvemingCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TunjunCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TunjunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    QList<int> removeList(QList<int> equips, QList<int> ids) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class DenglouCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DenglouCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class MobileLiezhiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileLiezhiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
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

class JianjieCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JianjieCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JianjieHuojiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JianjieHuojiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class JianjieLianhuanCard : public SkillCard
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

class OLLuanzhanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE OLLuanzhanCard();
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

class TenyearFenglveCard :public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearFenglveCard();

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TenyearFenglveGiveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearFenglveGiveCard();
    void onUse(Room *, const CardUseStruct &) const;
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

class SecondZhiyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SecondZhiyiCard();

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
    bool shuijingJudge(Room *room) const;
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

class TenyearNewShichouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearNewShichouCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const;
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

class SpMouzhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SpMouzhuCard();
    bool targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class BeizhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE BeizhuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class XuezhaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XuezhaoCard(const QString &xuezhao = "xuezhao");
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
private:
    QString xuezhao;
};

class SecondXuezhaoCard : public XuezhaoCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SecondXuezhaoCard();
};

class NewZhoufuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE NewZhoufuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void use(Room *, ServerPlayer *, QList<ServerPlayer *> &targets) const;
};

class TenyearZhoufuCard : public NewZhoufuCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearZhoufuCard();
};

class LiushiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE LiushiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileTongjiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MobileTongjiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class BaiyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE BaiyiCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    bool targetsFeasible(const QList<const Player *> &targets, const Player *) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JinglveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JinglveCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class HongyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HongyiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondHongyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SecondHongyiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

#endif
