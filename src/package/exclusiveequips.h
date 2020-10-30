#ifndef EXCLUSIVEEQUIPS_H
#define EXCLUSIVEEQUIPS_H

#include "standard.h"

class ExclusiveEquipPackage : public Package
{
    Q_OBJECT
public:
    ExclusiveEquipPackage();
};

class Hongduanqiang : public Weapon
{
    Q_OBJECT
public:
    Q_INVOKABLE Hongduanqiang(Card::Suit suit, int number);
};

class Liecuidao : public Weapon
{
    Q_OBJECT
public:
    Q_INVOKABLE Liecuidao(Card::Suit suit, int number);
};

class ShuibojianCard : public SkillCard
{
    Q_OBJECT
public:
    Q_INVOKABLE ShuibojianCard();
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
};

class Shuibojian : public Weapon
{
    Q_OBJECT
public:
    Q_INVOKABLE Shuibojian(Card::Suit suit, int number);
    void onUninstall(ServerPlayer *player) const;
};

class Hunduwanbi : public Weapon
{
    Q_OBJECT
public:
    Q_INVOKABLE Hunduwanbi(Card::Suit suit, int number);
};

class Tianleiren : public Weapon
{
    Q_OBJECT
public:
    Q_INVOKABLE Tianleiren(Card::Suit suit, int number);
};

class Piliche : public Weapon
{
    Q_OBJECT
public:
    Q_INVOKABLE Piliche(Card::Suit suit, int number);
};

class SecondPiliche : public Weapon
{
    Q_OBJECT
public:
    Q_INVOKABLE SecondPiliche(Card::Suit suit, int number);
};


class Sichengliangyu : public Treasure
{
    Q_OBJECT
public:
    Q_INVOKABLE Sichengliangyu(Card::Suit suit, int number);
};

class Tiejixuanyu : public Treasure
{
    Q_OBJECT
public:
    Q_INVOKABLE Tiejixuanyu(Card::Suit suit, int number);
};

class Feilunzhanyu : public Treasure
{
    Q_OBJECT
public:
    Q_INVOKABLE Feilunzhanyu(Card::Suit suit, int number);
};

class Qiongshu : public Treasure
{
    Q_OBJECT
public:
    Q_INVOKABLE Qiongshu(Card::Suit suit, int number);
};

class Xishu : public Treasure
{
    Q_OBJECT
public:
    Q_INVOKABLE Xishu(Card::Suit suit, int number);
};

class Jinshu : public Treasure
{
    Q_OBJECT
public:
    Q_INVOKABLE Jinshu(Card::Suit suit, int number);
};

#endif
