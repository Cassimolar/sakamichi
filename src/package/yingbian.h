#ifndef YINGBIAN_H
#define YINGBIAN_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "standard.h"
#include "maneuvering.h"

class YingbianPackage : public Package
{
    Q_OBJECT

public:
    YingbianPackage();
};

class IceSlash : public NatureSlash
{
    Q_OBJECT

public:
    Q_INVOKABLE IceSlash(Card::Suit suit, int number);
};

class Chuqibuyi : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE Chuqibuyi(Card::Suit suit, int number);

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class Dongzhuxianji : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE Dongzhuxianji(Card::Suit suit, int number);
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void onEffect(const CardEffectStruct &effect) const;
    bool isAvailable(const Player *player) const;
};

class Zhujinqiyuan : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE Zhujinqiyuan(Card::Suit suit, int number);

    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class Wuxinghelingshan : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE Wuxinghelingshan(Card::Suit suit, int number);
};

class Wutiesuolian : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE Wutiesuolian(Card::Suit suit, int number);
};

class Heiguangkai : public Armor
{
    Q_OBJECT

public:
    Q_INVOKABLE Heiguangkai(Card::Suit suit, int number);
};

class Huxinjing : public Armor
{
    Q_OBJECT

public:
    Q_INVOKABLE Huxinjing(Card::Suit suit, int number);
};

class Taigongyinfu : public Treasure
{
    Q_OBJECT

public:
    Q_INVOKABLE Taigongyinfu(Card::Suit suit, int number);
};

class Tianjitu : public Treasure
{
    Q_OBJECT

public:
    Q_INVOKABLE Tianjitu(Card::Suit suit, int number);
    void onInstall(ServerPlayer *player) const;
    void onUninstall(ServerPlayer *player) const;
};

class Tongque : public Treasure
{
    Q_OBJECT

public:
    Q_INVOKABLE Tongque(Card::Suit suit, int number);
    void onInstall(ServerPlayer *player) const;
    void onUninstall(ServerPlayer *player) const;
};

class Suijiyingbian : public TrickCard
{
    Q_OBJECT

public:
    Q_INVOKABLE Suijiyingbian(Card::Suit suit, int number);
    QString getSubtype() const;
    bool isAvailable(const Player *) const;
};

#endif
