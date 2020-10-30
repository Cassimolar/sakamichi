#ifndef SP1_H
#define SP1_H

#include "package.h"
#include "card.h"
#include "standard.h"
#include "wind.h"

class SP1Package : public Package
{
    Q_OBJECT

public:
    SP1Package();
};

class GusheCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE GusheCard(QString skill_name = "gushe");
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    int pindian(ServerPlayer *from, ServerPlayer *target, const Card *card1, const Card *card2) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
private:
    QString skill_name;
};

class TenyearGusheCard : public GusheCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TenyearGusheCard();
};

class DaoshuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DaoshuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class SpZhaoxinCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpZhaoxinCard();
    void use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class SpZhaoxinChooseCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpZhaoxinChooseCard();
};

class TongquCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TongquCard();
    bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class YinjuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE YinjuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class BusuanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE BusuanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SpQianxinCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SpQianxinCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class MobileSpQianxinCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileSpQianxinCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class JijieCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JijieCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class ZiyuanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZiyuanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class FumanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE FumanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class TunanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE TunanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class JianjiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE JianjiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class YizanCard : public SkillCard
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

class WuyuanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE WuyuanCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SecondMansiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondMansiCard();
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class DingpanCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DingpanCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class ShanxiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ShanxiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class MobileShanxiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileShanxiCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class GuolunCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE GuolunCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class DuanfaCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE DuanfaCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class QinguoCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE QinguoCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class ZhafuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ZhafuCard();
    void onEffect(const CardEffectStruct &effect) const;
};

class SongshuCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE SongshuCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class FuhaiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE FuhaiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

class MobileFuhaiCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE MobileFuhaiCard();
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const;
};

#endif
