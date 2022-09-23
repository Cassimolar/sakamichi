require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

-- 黑桃杀
for i = 9, 10 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(0)
    card:setNumber(i)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(0)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 梅花杀
for i = 2, 7 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(1)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
for i = 8, 11 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(1)
    card:setNumber(i)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(1)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 红桃杀
local card = sgs.Sanguosha:cloneCard("slash")
card:setSuit(2)
card:setNumber(10)
card:setParent(SakamichiCard)
for i = 10, 11 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(2)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 方块杀
for i = 6, 10 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(3)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("slash")
card:setSuit(3)
card:setNumber(13)
card:setParent(SakamichiCard)
-- 冰杀
for i = 7, 8 do
    local card = sgs.Sanguosha:cloneCard("ice_slash")
    card:setSuit(0)
    card:setNumber(i)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("ice_slash")
    card:setSuit(0)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("ice_slash")
card:setSuit(0)
card:setNumber(8)
card:setParent(SakamichiCard)
-- 雷杀
for i = 4, 6 do
    local card = sgs.Sanguosha:cloneCard("thunder_slash")
    card:setSuit(0)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
for i = 5, 8 do
    local card = sgs.Sanguosha:cloneCard("thunder_slash")
    card:setSuit(1)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 火杀
local card = sgs.Sanguosha:cloneCard("fire_slash")
card:setSuit(2)
card:setNumber(4)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("fire_slash")
card:setSuit(2)
card:setNumber(7)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("fire_slash")
card:setSuit(2)
card:setNumber(10)
card:setParent(SakamichiCard)
for i = 4, 5 do
    local card = sgs.Sanguosha:cloneCard("fire_slash")
    card:setSuit(3)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 红桃闪
local card = sgs.Sanguosha:cloneCard("jink")
card:setSuit(2)
card:setNumber(2)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("jink")
card:setSuit(2)
card:setNumber(2)
card:setParent(SakamichiCard)
for i = 8, 9 do
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
for i = 11, 13 do
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 方块闪
local card = sgs.Sanguosha:cloneCard("jink")
card:setSuit(3)
card:setNumber(2)
card:setParent(SakamichiCard)
for i = 2, 11 do
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
for i = 6, 8 do
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
for i = 10, 11 do
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("jink")
card:setSuit(3)
card:setNumber(11)
card:setParent(SakamichiCard)
-- 红桃桃
for i = 3, 6 do
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
for i = 6, 9 do
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("peach")
card:setSuit(2)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 方块桃
local card = sgs.Sanguosha:cloneCard("peach")
card:setSuit(3)
card:setNumber(2)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("peach")
card:setSuit(3)
card:setNumber(3)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("peach")
card:setSuit(3)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 酒
local card = sgs.Sanguosha:cloneCard("analeptic")
card:setSuit(0)
card:setNumber(3)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("analeptic")
card:setSuit(0)
card:setNumber(9)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("analeptic")
card:setSuit(1)
card:setNumber(3)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("analeptic")
card:setSuit(1)
card:setNumber(9)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("analeptic")
card:setSuit(3)
card:setNumber(9)
card:setParent(SakamichiCard)
-- 随机应变
local card = sgs.Sanguosha:cloneCard("suijiyingbian")
card:setSuit(2)
card:setNumber(4)
card:setParent(SakamichiCard)
-- 铁索连环
for i = 11, 12 do
    local card = sgs.Sanguosha:cloneCard("iron_chain")
    card:setSuit(0)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
for i = 10, 13 do
    local card = sgs.Sanguosha:cloneCard("iron_chain")
    card:setSuit(1)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 五谷丰登
local card = sgs.Sanguosha:cloneCard("amazing_grace")
card:setSuit(2)
card:setNumber(3)
card:setParent(SakamichiCard)
-- 桃园结义
local card = sgs.Sanguosha:cloneCard("god_salvation")
card:setSuit(2)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 南蛮入侵
local card = sgs.Sanguosha:cloneCard("savage_assault")
card:setSuit(0)
card:setNumber(7)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("savage_assault")
card:setSuit(0)
card:setNumber(13)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("savage_assault")
card:setSuit(1)
card:setNumber(7)
card:setParent(SakamichiCard)
-- 万箭齐发
local card = sgs.Sanguosha:cloneCard("archery_attack")
card:setSuit(2)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 决斗
local card = sgs.Sanguosha:cloneCard("duel")
card:setSuit(0)
card:setNumber(1)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("duel")
card:setSuit(1)
card:setNumber(1)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("duel")
card:setSuit(3)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 出其不意
local card = sgs.Sanguosha:cloneCard("chuqibuyi")
card:setSuit(0)
card:setNumber(5)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("chuqibuyi")
card:setSuit(1)
card:setNumber(5)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("chuqibuyi")
card:setSuit(2)
card:setNumber(5)
card:setParent(SakamichiCard)
-- 火攻
for i = 2, 3 do
    local card = sgs.Sanguosha:cloneCard("fire_attack")
    card:setSuit(2)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("fire_attack")
card:setSuit(3)
card:setNumber(13)
card:setParent(SakamichiCard)
-- 洞烛先机
for i = 7, 9 do
    local card = sgs.Sanguosha:cloneCard("dongzhuxianji")
    card:setSuit(2)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("dongzhuxianji")
card:setSuit(2)
card:setNumber(11)
card:setParent(SakamichiCard)
-- 顺手牵羊
for i = 3, 4 do
    local card = sgs.Sanguosha:cloneCard("snatch")
    card:setSuit(0)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("snatch")
card:setSuit(0)
card:setNumber(11)
card:setParent(SakamichiCard)
for i = 3, 4 do
    local card = sgs.Sanguosha:cloneCard("snatch")
    card:setSuit(3)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 过河拆桥
local card = sgs.Sanguosha:cloneCard("dismantlement")
card:setSuit(0)
card:setNumber(4)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("dismantlement")
card:setSuit(2)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 逐近弃远
local card = sgs.Sanguosha:cloneCard("zhujinqiyuan")
card:setSuit(0)
card:setNumber(3)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("zhujinqiyuan")
card:setSuit(0)
card:setNumber(12)
card:setParent(SakamichiCard)
for i = 3, 4 do
    local card = sgs.Sanguosha:cloneCard("zhujinqiyuan")
    card:setSuit(1)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
-- 借刀杀人
local card = sgs.Sanguosha:cloneCard("collateral")
card:setSuit(1)
card:setNumber(13)
card:setParent(SakamichiCard)
-- 无懈可击
local card = sgs.Sanguosha:cloneCard("nullification")
card:setSuit(0)
card:setNumber(11)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("nullification")
card:setSuit(0)
card:setNumber(13)
card:setParent(SakamichiCard)
for i = 12, 13 do
    local card = sgs.Sanguosha:cloneCard("nullification")
    card:setSuit(1)
    card:setNumber(i)
    card:setParent(SakamichiCard)
end
local card = sgs.Sanguosha:cloneCard("nullification")
card:setSuit(2)
card:setNumber(1)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("nullification")
card:setSuit(2)
card:setNumber(13)
card:setParent(SakamichiCard)
-- 乐不思蜀
for i = 0, 2 do
    local card = sgs.Sanguosha:cloneCard("indulgence")
    card:setSuit(i)
    card:setNumber(6)
    card:setParent(SakamichiCard)
end
-- 兵粮寸断
local card = sgs.Sanguosha:cloneCard("supply_shortage")
card:setSuit(0)
card:setNumber(10)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("supply_shortage")
card:setSuit(1)
card:setNumber(4)
card:setParent(SakamichiCard)
-- 闪电
local card = sgs.Sanguosha:cloneCard("lightning")
card:setSuit(2)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 诸葛连弩
local card = sgs.Sanguosha:cloneCard("crossbow")
card:setSuit(1)
card:setNumber(1)
card:setParent(SakamichiCard)
local card = sgs.Sanguosha:cloneCard("crossbow")
card:setSuit(3)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 古锭刀
local card = sgs.Sanguosha:cloneCard("guding_blade")
card:setSuit(0)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 飞龙夺凤
dragon_phoenix_skill = sgs.CreateTriggerSkill {
    name = "dragon_phoenix",
    events = {sgs.TargetSpecified, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() and player:hasWeapon("dragon_phoenix")
                and use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(use.to) do
                    if p:canDiscard(p, "he") and room:askForSkillInvoke(player, self:objectName(), data) then
                        room:askForDiscard(p, "dragon_phoenix", 1, 1, false, true)
                        room:setEmotion(player, "weapon/double_sword")
                    end
                end
            end
        else
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and dying.damage and dying.damage.from
                and dying.damage.from:hasWeapon("dragon_phoenix") and dying.damage.card
                and dying.damage.card:isKindOf("Slash") then
                if not dying.who:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
                    local id = room:askForCardChosen(dying.damage.from, dying.who, "h", "dragon_phoenix")
                    room:obtainCard(dying.damage.from, sgs.Sanguosha:getCard(id),
                        room:getCardPlace(id) ~= sgs.Player_PlaceHand)
                    room:setEmotion(player, "weapon/double_sword")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("dragon_phoenix") then
    SKMC.SkillList:append(dragon_phoenix_skill)
end
dragon_phoenix = sgs.CreateWeapon {
    name = "dragon_phoenix",
    range = 2,
    number = 2,
    suit = sgs.Card_Spade,
    on_install = function(self, player)
        player:getRoom():acquireSkill(player, dragon_phoenix_skill)
    end,
    on_uninstall = function(self, player)
        player:getRoom():detachSkillFromPlayer(player, "dragon_phoenix")
    end,
}
dragon_phoenix:clone():setParent(SakamichiCard)
sgs.LoadTranslationTable {
    ["dragon_phoenix"] = "飞龙夺凤",
    [":dragon_phoenix"] = " 装备牌·武器\
    <b>攻击范围</b>：2\
    <b>武器技能</b>：当你使用【杀】指定角色为目标后，你可以令该角色弃置一张牌。你的【杀】令目标角色进入濒死时，你可以获得其一张手牌。",
}
-- 寒冰剑
local card = sgs.Sanguosha:cloneCard("ice_sword")
card:setSuit(0)
card:setNumber(2)
card:setParent(SakamichiCard)
-- 青釭剑
local card = sgs.Sanguosha:cloneCard("qinggang_sword")
card:setSuit(0)
card:setNumber(6)
card:setParent(SakamichiCard)
-- 青龙偃月刀
local card = sgs.Sanguosha:cloneCard("blade")
card:setSuit(0)
card:setNumber(5)
card:setParent(SakamichiCard)
-- 丈八蛇矛
local card = sgs.Sanguosha:cloneCard("spear")
card:setSuit(0)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 贯石斧
local card = sgs.Sanguosha:cloneCard("axe")
card:setSuit(3)
card:setNumber(5)
card:setParent(SakamichiCard)
-- 乌铁锁链
local card = sgs.Sanguosha:cloneCard("wutiesuolian")
card:setSuit(3)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 银月枪
local card = sgs.Sanguosha:cloneCard("moon_spear")
card:setSuit(3)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 朱雀羽扇
local card = sgs.Sanguosha:cloneCard("fan")
card:setSuit(3)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 麒麟弓
local card = sgs.Sanguosha:cloneCard("kylin_bow")
card:setSuit(2)
card:setNumber(5)
card:setParent(SakamichiCard)
-- 八卦阵
local card = sgs.Sanguosha:cloneCard("eight_diagram")
card:setSuit(0)
card:setNumber(2)
card:setParent(SakamichiCard)
-- 白银狮子
local card = sgs.Sanguosha:cloneCard("silver_lion")
card:setSuit(1)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 仁王盾
local card = sgs.Sanguosha:cloneCard("renwang_shield")
card:setSuit(1)
card:setNumber(2)
card:setParent(SakamichiCard)
-- 黑光铠
local card = sgs.Sanguosha:cloneCard("heiguangkai")
card:setSuit(1)
card:setNumber(2)
card:setParent(SakamichiCard)
-- 藤甲
for i = 0, 1 do
    local card = sgs.Sanguosha:cloneCard("vine")
    card:setSuit(i)
    card:setNumber(2)
    card:setParent(SakamichiCard)
end
-- 大宛
local dayuan = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Spade, 13)
dayuan:setObjectName("dayuan")
dayuan:setParent(SakamichiCard)
-- 赤兔
local chituchitu = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Heart, 5)
chituchitu:setObjectName("chitu")
chituchitu:setParent(SakamichiCard)
-- 紫骍
local zixing = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Diamond, 13)
zixing:setObjectName("zixing")
zixing:setParent(SakamichiCard)
-- 绝影
local jueying = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Spade, 5)
jueying:setObjectName("jueying")
jueying:setParent(SakamichiCard)
-- 的卢
local dilu = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Club, 5)
dilu:setObjectName("dilu")
dilu:setParent(SakamichiCard)
-- 爪黄飞电
local zhuahuangfeidian = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Heart, 13)
zhuahuangfeidian:setObjectName("zhuahuangfeidian")
zhuahuangfeidian:setParent(SakamichiCard)
-- 骅骝
local hualiu = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Diamond, 13)
hualiu:setObjectName("hualiu")
hualiu:setParent(SakamichiCard)
-- 太公阴符
local card = sgs.Sanguosha:cloneCard("taigongyinfu")
card:setSuit(0)
card:setNumber(1)
card:setParent(SakamichiCard)
-- 天机图
local card = sgs.Sanguosha:cloneCard("tianjitu")
card:setSuit(1)
card:setNumber(12)
card:setParent(SakamichiCard)
-- 木牛流马
local card = sgs.Sanguosha:cloneCard("wooden_ox")
card:setSuit(3)
card:setNumber(5)
card:setParent(SakamichiCard)
-- =========================专属卡牌=========================--
-- 浮雷
FuLei = sgs.CreateTrickCard {
    name = "_fu_lei",
    class_name = "FuLei",
    subtype = "delayed_trick",
    subclass = sgs.LuaTrickCard_TypeDelayedTrick,
    target_fixed = false,
    can_recast = false,
    is_cancelable = true,
    movable = true,
    filter = function(self, targets, to_select)
        if #targets == 0 then
            if not sgs.Self:containsTrick(self:objectName()) then
                return to_select:objectName() == sgs.Self:objectName()
            else
                for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
                    if not p:containsTrick(self:objectName()) then
                        return to_select:objectName() == sgs.Self:objectName()
                    end
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local target = effect.to
        local judge = sgs.JudgeStruct()
        local room = target:getRoom()
        judge.pattern = ".|spade"
        judge.good = false
        judge.reason = self:objectName()
        judge.who = target
        room:judge(judge)
        if judge:isBad() then
            local num = self:getTag("FuLei"):toInt()
            room:damage(sgs.DamageStruct(self, nil, target, num + 1, sgs.DamageStruct_Thunder))
            self:setTag("FuLei", sgs.QVariant(num + 1))
        end
        self.on_nullified(self, target)
    end,
}
FuLei:setParent(SakamichiExclusiveCard)
sgs.LoadTranslationTable {
    ["_fu_lei"] = "浮雷",
    [":_fu_lei"] = " 延时锦囊\
    <b>时机</b>：出牌阶段\
    <b>目标</b>：你\
    <b>效果</b>：将此牌置于目标角色判定区内。其判定阶段进行判定：若结果为♠，其受到X点雷电伤害并将【浮雷】移动至其下家判定区内（X为此锦囊判定结果为♠的次数）。",
}
