SKMC = {}
SKMC.SkillList = sgs.SkillList()

local Sakamichi = sgs.Package("Sakamichi", sgs.Package_GeneralPack)
local STU48 = sgs.Package("STU48", sgs.Package_GeneralPack)
local SakamichiGod = sgs.Package("SakamichiGod", sgs.Package_GeneralPack)
local Zambi = sgs.Package("Zambi", sgs.Package_GeneralPack)
local SakamichiCard = sgs.Package("SakamichiCard", sgs.Package_CardPack)
local SakamichiExclusiveCard = sgs.Package("SakamichiExclusiveCard", sgs.Package_CardPack)

SKMC.Packages = {}
table.insert(SKMC.Packages, Sakamichi)
table.insert(SKMC.Packages, STU48)
table.insert(SKMC.Packages, SakamichiGod)
table.insert(SKMC.Packages, Zambi)
table.insert(SKMC.Packages, SakamichiCard)
table.insert(SKMC.Packages, SakamichiExclusiveCard)

sgs.LoadTranslationTable {
    ["Sakamichi"] = "坂道杀·坂道",
    ["STU48"] = "坂道杀·STU48",
    ["SakamichiGod"] = "坂道杀·神",
    ["Zambi"] = "坂道杀·ザンビ",
    ["SakamichiCard"] = "坂道杀·卡牌",
    ["SakamichiExclusiveCard"] = "坂道杀·专属卡牌",
}

do
    require("lua.config")
    local config = config
    table.removeOne(config.kingdoms, "wei")
    table.removeOne(config.kingdoms, "shu")
    table.removeOne(config.kingdoms, "wu")
    table.removeOne(config.kingdoms, "qun")
    table.removeOne(config.kingdoms, "jin")
    table.removeOne(config.kingdoms, "god")
    table.insert(config.kingdoms, "Nogizaka46")
    table.insert(config.kingdoms, "Keyakizaka46")
    table.insert(config.kingdoms, "HiraganaKeyakizaka46")
    table.insert(config.kingdoms, "Yoshimotozaka46")
    table.insert(config.kingdoms, "Hinatazaka46")
    table.insert(config.kingdoms, "Sakurazaka46")
    table.insert(config.kingdoms, "SakamichiKenshusei")
    table.insert(config.kingdoms, "AutisticGroup")
    table.insert(config.kingdoms, "STU48")
    table.insert(config.kingdoms, "EqualLove")
    table.insert(config.kingdoms, "NotEqualMe")
    table.insert(config.kingdoms, "NearlyEqualJoy")
    table.insert(config.kingdoms, "god")
    table.insert(config.kingdoms, "Zambi")
    config.kingdom_colors.Nogizaka46 = "#7D2982"
    config.kingdom_colors.Keyakizaka46 = "#5EB054"
    config.kingdom_colors.HiraganaKeyakizaka46 = "#5EB054"
    config.kingdom_colors.Yoshimotozaka46 = "#E84709"
    config.kingdom_colors.Hinatazaka46 = "#7CC7E8"
    config.kingdom_colors.Sakurazaka46 = "#F19DB5"
    config.kingdom_colors.SakamichiKenshusei = "#738B95"
    config.kingdom_colors.AutisticGroup = "#8A807A"
    config.kingdom_colors.STU48 = "#CCEBFF"
    config.kingdom_colors.EqualLove = "#EA6C81"
    config.kingdom_colors.NotEqualMe = "#79CCBD"
    config.kingdom_colors.NearlyEqualJoy = "#FFDF6A"
    config.kingdom_colors.Zambi = "#412BB6"
end

sgs.LoadTranslationTable {
    ["Nogizaka46"] = "乃木坂46",
    ["Keyakizaka46"] = "欅坂46",
    ["HiraganaKeyakizaka46"] = "けやき坂46",
    ["Yoshimotozaka46"] = "吉本坂46",
    ["Hinatazaka46"] = "日向坂46",
    ["Sakurazaka46"] = "櫻坂46",
    ["SakamichiKenshusei"] = "坂道研修生",
    ["AutisticGroup"] = "自闭群",
    ["STU48"] = "STU48",
    ["EqualLove"] = "＝LOVE",
    ["NotEqualMe"] = "≠ME",
    ["NearlyEqualJoy"] = "≒JOY",
    ["Zambi"] = "ザンビ",
}


-- ====================================================================================================卡牌复刻====================================================================================================--
-- 黑桃杀
for i = 0, 1, 1 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(0)
    card:setNumber(i + 9)
    card:setParent(SakamichiCard)
end
for i = 0, 1, 1 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(0)
    card:setNumber(i + 9)
    card:setParent(SakamichiCard)
end
-- 梅花杀
for i = 0, 9, 1 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(1)
    card:setNumber(i + 2)
    card:setParent(SakamichiCard)
end
for i = 0, 3, 1 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(1)
    card:setNumber(i + 8)
    card:setParent(SakamichiCard)
end
-- 红桃杀
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(2)
    card:setNumber(10)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(2)
    card:setNumber(10)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(2)
    card:setNumber(11)
    card:setParent(SakamichiCard)
-- 方块杀
for i = 0, 4, 1 do
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(3)
    card:setNumber(i + 6)
    card:setParent(SakamichiCard)
end
    local card = sgs.Sanguosha:cloneCard("slash")
    card:setSuit(3)
    card:setNumber(13)
    card:setParent(SakamichiCard)
-- 红桃闪
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(2)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(2)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(13)
    card:setParent(SakamichiCard)
-- 方块闪
for i = 0, 9, 1 do
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(i + 2)
    card:setParent(SakamichiCard)
end
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(2)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(11)
    card:setParent(SakamichiCard)
-- 红桃桃
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(3)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(4)
    card:setParent(SakamichiCard)
for i = 0, 3, 1 do
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(i + 6)
    card:setParent(SakamichiCard)
end
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(12)
    card:setParent(SakamichiCard)
-- 方块桃
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(3)
    card:setNumber(12)
    card:setParent(SakamichiCard)
-- 五谷丰登
    local card = sgs.Sanguosha:cloneCard("amazing_grace")
    card:setSuit(2)
    card:setNumber(3)
    card:setParent(SakamichiCard)
-- 随机应变
    local card = sgs.Sanguosha:cloneCard("suijiyingbian")
    card:setSuit(2)
    card:setNumber(4)
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
-- 洞烛先机
for i = 0, 2, 1 do
    local card = sgs.Sanguosha:cloneCard("dongzhuxianji")
    card:setSuit(2)
    card:setNumber(i + 7)
    card:setParent(SakamichiCard)
end
    local card = sgs.Sanguosha:cloneCard("dongzhuxianji")
    card:setSuit(2)
    card:setNumber(11)
    card:setParent(SakamichiCard)
-- 顺手牵羊
    local card = sgs.Sanguosha:cloneCard("snatch")
    card:setSuit(0)
    card:setNumber(3)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("snatch")
    card:setSuit(0)
    card:setNumber(4)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("snatch")
    card:setSuit(0)
    card:setNumber(11)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("snatch")
    card:setSuit(3)
    card:setNumber(3)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("snatch")
    card:setSuit(3)
    card:setNumber(4)
    card:setParent(SakamichiCard)
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
    local card = sgs.Sanguosha:cloneCard("zhujinqiyuan")
    card:setSuit(1)
    card:setNumber(3)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("zhujinqiyuan")
    card:setSuit(1)
    card:setNumber(4)
    card:setParent(SakamichiCard)
-- 借刀杀人
    local card = sgs.Sanguosha:cloneCard("collateral")
    card:setSuit(1)
    card:setNumber(13)
    card:setParent(SakamichiCard)
-- 天机图
    local card = sgs.Sanguosha:cloneCard("tianjitu")
    card:setSuit(1)
    card:setNumber(12)
    card:setParent(SakamichiCard)
-- 无懈可以击
    local card = sgs.Sanguosha:cloneCard("nullification")
    card:setSuit(0)
    card:setNumber(11)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("nullification")
    card:setSuit(1)
    card:setNumber(12)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("nullification")
    card:setSuit(1)
    card:setNumber(13)
    card:setParent(SakamichiCard)
-- 乐不思蜀
for i = 0, 2, 1 do
    local card = sgs.Sanguosha:cloneCard("indulgence")
    card:setSuit(i)
    card:setNumber(6)
    card:setParent(SakamichiCard)
end
-- 太公阴符
    local card = sgs.Sanguosha:cloneCard("taigongyinfu")
    card:setSuit(0)
    card:setNumber(1)
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
-- 飞龙夺凤
dragon_phoenix_skill = sgs.CreateTriggerSkill {
    name = "dragon_phoenix",
    events = {sgs.TargetSpecified, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() and player:hasWeapon("dragon_phoenix") and use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(use.to) do
                    if p:canDiscard(p, "he") and room:askForSkillInvoke(player, self:objectName(), data) then
                        room:askForDiscard(p, "dragon_phoenix", 1, 1, false, true)
                        room:setEmotion(player, "weapon/double_sword")
                    end
                end
            end
        else
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and dying.damage and dying.damage.from and dying.damage.from:hasWeapon("dragon_phoenix") and dying.damage.card and
                dying.damage.card:isKindOf("Slash") then
                if not dying.who:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
                    local id = room:askForCardChosen(dying.damage.from, dying.who, "h", "dragon_phoenix")
                    room:obtainCard(dying.damage.from, sgs.Sanguosha:getCard(id), room:getCardPlace(id) ~= sgs.Player_PlaceHand)
                    room:setEmotion(player, "weapon/double_sword")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("dragon_phoenix") then SKMC.SkillList:append(dragon_phoenix_skill) end

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
-- 黑光铠
    local card = sgs.Sanguosha:cloneCard("heiguangkai")
    card:setSuit(1)
    card:setNumber(2)
    card:setParent(SakamichiCard)
-- 绝影
    local horse = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Spade, 5)
    horse:setObjectName("jueying")
    horse:setParent(SakamichiCard)
-- 的卢
    local horse = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Club, 5)
    horse:setObjectName("dilu")
    horse:setParent(SakamichiCard)
-- 爪黄飞电
    local horse = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Heart, 13)
    horse:setObjectName("zhuahuangfeidian")
    horse:setParent(SakamichiCard)
-- 赤兔
    local horse = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Heart, 5)
    horse:setObjectName("chitu")
    horse:setParent(SakamichiCard)
-- 大宛
    local horse = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Spade, 13)
    horse:setObjectName("dayuan")
    horse:setParent(SakamichiCard)
-- 紫骍
    local horse = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Diamond, 13)
    horse:setObjectName("zixing")
    horse:setParent(SakamichiCard)
-- 寒冰剑
    local card = sgs.Sanguosha:cloneCard("ice_sword")
    card:setSuit(0)
    card:setNumber(2)
    card:setParent(SakamichiCard)
-- 仁王盾
    local card = sgs.Sanguosha:cloneCard("renwang_shield")
    card:setSuit(1)
    card:setNumber(2)
    card:setParent(SakamichiCard)
-- 闪电
    local card = sgs.Sanguosha:cloneCard("lightning")
    card:setSuit(2)
    card:setNumber(12)
    card:setParent(SakamichiCard)
-- 冰杀
for i = 0, 1, 1 do
    local card = sgs.Sanguosha:cloneCard("ice_slash")
    card:setSuit(0)
    card:setNumber(i + 7)
    card:setParent(SakamichiCard)
end
for i = 0, 1, 1 do
    local card = sgs.Sanguosha:cloneCard("ice_slash")
    card:setSuit(0)
    card:setNumber(i + 7)
    card:setParent(SakamichiCard)
end
    local card = sgs.Sanguosha:cloneCard("ice_slash")
    card:setSuit(0)
    card:setNumber(8)
    card:setParent(SakamichiCard)
-- 雷杀
for i = 0, 2, 1 do
    local card = sgs.Sanguosha:cloneCard("thunder_slash")
    card:setSuit(0)
    card:setNumber(i + 4)
    card:setParent(SakamichiCard)
end
for i = 0, 3, 1 do
    local card = sgs.Sanguosha:cloneCard("thunder_slash")
    card:setSuit(1)
    card:setNumber(i + 5)
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
    local card = sgs.Sanguosha:cloneCard("fire_slash")
    card:setSuit(3)
    card:setNumber(4)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("fire_slash")
    card:setSuit(3)
    card:setNumber(5)
    card:setParent(SakamichiCard)
-- 闪
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(8)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(9)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(11)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(2)
    card:setNumber(12)
    card:setParent(SakamichiCard)
for i = 0, 2, 1 do
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(i + 6)
    card:setParent(SakamichiCard)
end
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(10)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("jink")
    card:setSuit(3)
    card:setNumber(11)
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
-- 桃
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(5)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(2)
    card:setNumber(6)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(3)
    card:setNumber(2)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("peach")
    card:setSuit(3)
    card:setNumber(3)
    card:setParent(SakamichiCard)
-- 火攻
    local card = sgs.Sanguosha:cloneCard("fire_attack")
    card:setSuit(2)
    card:setNumber(2)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("fire_attack")
    card:setSuit(2)
    card:setNumber(3)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("fire_attack")
    card:setSuit(3)
    card:setNumber(13)
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
-- 铁索连环
    local card = sgs.Sanguosha:cloneCard("iron_chain")
    card:setSuit(0)
    card:setNumber(11)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("iron_chain")
    card:setSuit(0)
    card:setNumber(12)
    card:setParent(SakamichiCard)
for i = 0, 3, 1 do
    local card = sgs.Sanguosha:cloneCard("iron_chain")
    card:setSuit(1)
    card:setNumber(i + 10)
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
-- 无懈可以击
    local card = sgs.Sanguosha:cloneCard("nullification")
    card:setSuit(0)
    card:setNumber(13)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("nullification")
    card:setSuit(2)
    card:setNumber(1)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("nullification")
    card:setSuit(2)
    card:setNumber(13)
    card:setParent(SakamichiCard)
-- 古锭刀
    local card = sgs.Sanguosha:cloneCard("guding_blade")
    card:setSuit(0)
    card:setNumber(1)
    card:setParent(SakamichiCard)
-- 朱雀羽扇
    local card = sgs.Sanguosha:cloneCard("fan")
    card:setSuit(3)
    card:setNumber(1)
    card:setParent(SakamichiCard)
-- 藤甲
    local card = sgs.Sanguosha:cloneCard("vine")
    card:setSuit(0)
    card:setNumber(2)
    card:setParent(SakamichiCard)
    local card = sgs.Sanguosha:cloneCard("vine")
    card:setSuit(1)
    card:setNumber(2)
    card:setParent(SakamichiCard)
-- 白银狮子
    local card = sgs.Sanguosha:cloneCard("silver_lion")
    card:setSuit(1)
    card:setNumber(1)
    card:setParent(SakamichiCard)
-- 骅骝
    horse = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Diamond, 13)
    horse:setObjectName("hualiu")
    horse:setParent(SakamichiCard)
-- 木牛流马
    local card = sgs.Sanguosha:cloneCard("wooden_ox")
    card:setSuit(3)
    card:setNumber(5)
    card:setParent(SakamichiCard)
-- 银月枪X
    local card = sgs.Sanguosha:cloneCard("moon_spear")
    card:setSuit(3)
    card:setNumber(12)
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
        -- return #targets == 0 and to_select:objectName() == sgs.Self:objectName() and not to_select:containsTrick(self:objectName())
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

-- ====================================================================================================函数和全局技能====================================================================================================--

SKMC.IKiSei = {}
SKMC.NiKiSei = {}
SKMC.SanKiSei = {}
SKMC.YonKiSei = {}
SKMC.GoKiSei = {}

SKMC.SeiMeiHanDan = {}

SKMC.Pattern = {
    BasicCard = {},
    TrickCard = {},
    EquipCard = {},
}
SKMC.Pattern.BasicCard = {
    Slash = {},
}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("BasicCard") and not card:isKindOf("Slash") then
        if not table.contains(SKMC.Pattern.BasicCard, card:objectName()) then
            table.insert(SKMC.Pattern.BasicCard, card:objectName())
        end
    end
end
SKMC.Pattern.BasicCard.Slash = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Slash") then
        if not table.contains(SKMC.Pattern.BasicCard.Slash, card:objectName()) then
            table.insert(SKMC.Pattern.BasicCard.Slash, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard = {
    SingleTargetTrick = {},
    MultipleTargetTrick = {},
    DelayedTrick = {},
}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("TrickCard") and not card:isKindOf("SingleTargetTrick") and not card:isKindOf("GlobalEffect") and
        not card:isKindOf("AOE") and not card:isKindOf("IronChain") and not card:isKindOf("DelayedTrick") then
        if not table.contains(SKMC.Pattern.TrickCard, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard.SingleTargetTrick = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("SingleTargetTrick") then
        if not table.contains(SKMC.Pattern.TrickCard.SingleTargetTrick, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard.SingleTargetTrick, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard.MultipleTargetTrick = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("IronChain") and card:isKindOf("GlobalEffect") or card:isKindOf("AOE") then
        if not table.contains(SKMC.Pattern.TrickCard.MultipleTargetTrick, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard.MultipleTargetTrick, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard.DelayedTrick = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("DelayedTrick") then
        if not table.contains(SKMC.Pattern.TrickCard.DelayedTrick, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard.DelayedTrick, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard = {
    Weapon = {},
    Armor = {},
    OffensiveHorse = {},
    DefensiveHorse = {},
    Treasure = {},
}
SKMC.Pattern.EquipCard.Weapon = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Weapon") then
        if not table.contains(SKMC.Pattern.EquipCard.Weapon, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.Weapon, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.Armor = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Armor") then
        if not table.contains(SKMC.Pattern.EquipCard.Armor, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.Armor, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.OffensiveHorse = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("OffensiveHorse") then
        if not table.contains(SKMC.Pattern.EquipCard.OffensiveHorse, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.OffensiveHorse, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.DefensiveHorse = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("DefensiveHorse") then
        if not table.contains(SKMC.Pattern.EquipCard.DefensiveHorse, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.DefensiveHorse, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.Treasure = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Treasure") then
        if not table.contains(SKMC.Pattern.EquipCard.Treasure, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.Treasure, card:objectName())
        end
    end
end

sgs.LoadTranslationTable {
    ["Slash"] = "杀",
    ["SingleTargetTrick"] = "单目标锦囊",
    ["MultipleTargetTrick"] = "多目标锦囊",
    ["DelayedTrick"] = "延时锦囊",
    ["Weapon"] = "武器",
    ["Armor"] = "防具",
    ["OffensiveHorse"] = "进攻马",
    ["DefensiveHorse"] = "防御马",
    ["Treasure"] = "宝物",
}

function SKMC.table_to_IntList(table)
    local list = sgs.IntList()
    for i = 1, #table, 1 do
        list:append(table[i])
    end
    return list
end

function SKMC.table_to_BoolList(table)
    local list = sgs.BoolList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

function SKMC.table_to_CardList(table)
    local list = sgs.CardList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

function SKMC.table_to_PlayerList(table)
    local list = sgs.PlayerList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

function SKMC.table_to_SPlayerList(table)
    local list = sgs.SPlayerList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

function SKMC.get_pos(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return 0
end

function SKMC.set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

function SKMC.is_normal_game_mode(mode_name)
    return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
end

function SKMC.get_available_generals(player, tag, remove_table)
    local all = sgs.Sanguosha:getLimitedGeneralNames()
    local room = player:getRoom()
    if (SKMC.is_normal_game_mode(room:getMode()) or room:getMode():find("_mini_") or room:getMode() == "custom_scenario") then
        table.removeTable(all, sgs.GetConfig("Banlist/Roles", ""):split(", "))
    elseif (room:getMode() == "04_1v3") then
        table.removeTable(all, sgs.GetConfig("Banlist/HulaoPass", ""):split(", "))
    elseif (room:getMode() == "06_XMode") then
        table.removeTable(all, sgs.GetConfig("Banlist/XMode", ""):split(", "))
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            table.removeTable(all, (p:getTag("XModeBackup"):toStringList()) or {})
        end
    elseif (room:getMode() == "02_1v1") then
        table.removeTable(all, sgs.GetConfig("Banlist/1v1", ""):split(", "))
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            table.removeTable(all, (p:getTag("1v1Arrange"):toStringList()) or {})
        end
    end
    if tag then
        local tag_remove = {}
        local tag_string = player:getTag(tag):toString()
        if tag_string and tag_string ~= "" then
            tag_remove = tag_string:split("+")
        end
        table.removeTable(all, tag_remove)
    end
    if remove_table then
        table.removeTable(all, remove_table)
    end
    for _, player in sgs.qlist(room:getAlivePlayers()) do
        local name = player:getGeneralName()
        if sgs.Sanguosha:isGeneralHidden(name) then
            local fname = sgs.Sanguosha:findConvertFrom(name);
            if fname ~= "" then
                name = fname
            end
        end
        table.removeOne(all, name)
        if not player:getGeneral2() == nil then
            name = player:getGeneral2Name()
        end
        if sgs.Sanguosha:isGeneralHidden(name) then
            local fname = sgs.Sanguosha:findConvertFrom(name);
            if fname ~= "" then
                name = fname
            end
        end
        table.removeOne(all, name)
    end
    return all
end

function SKMC.has_specific_kingdom_player(player, same, kingdom, except)
    local same_kingdom = true
    if same ~= nil then
        same_kingdom = same
    end
    local target_kingdom = player:getKingdom()
    if kingdom then
        target_kingdom = kingdom
    end
    for _, p in sgs.qlist(player:getSiblings()) do
        if p:isAlive() and p:objectName() ~= except then
            if same_kingdom then
                if p:getKingdom() == target_kingdom then
                    return true
                end
            else
                if p:getKingdom() ~= target_kingdom then
                    return true
                end
            end
        end
    end
    return false
end

function SKMC.is_ki_be(player, ki_be_tsu)
    local ki_be
    if ki_be_tsu == 1 then
        ki_be = SKMC.IKiSei
    elseif ki_be_tsu == 2 then
        ki_be = SKMC.NiKiSei
    elseif ki_be_tsu == 3 then
        ki_be = SKMC.SanKiSei
    elseif ki_be_tsu == 4 then
        ki_be = SKMC.YonKiSei
    elseif ki_be_tsu == 5 then
        ki_be = SKMC.GoKiSei
    end
    return ki_be[player:getGeneralName()] or ki_be[player:getGeneral2Name()]
end

function SKMC.list_index_of(qlist, item)
    local index = 0
    for _, i in sgs.qlist(qlist) do
        if i == item then
            return index
        end
        index = index + 1
    end
end

function SKMC.true_name(card)
    if card == nil then
        return ""
    end
    if card:objectName() == "fire_slash" or card:objectName() == "thunder_slash" or card:objectName() == "ice_slash" then
        return "slash"
    end
    return card:objectName()
end

function SKMC.send_message(room, msg_type, msg_from, msg_to, msg_tos, card_str, msg_arg, msg_arg2, msg_arg3, msg_arg4, msg_arg5)
    local msg = sgs.LogMessage()
    if msg_type then
        msg.type = msg_type
    end
    if msg_from then
        msg.from = msg_from
    end
    if msg_to then
        msg.to:append(msg_to)
    end
    if msg_tos then
        msg.to = msg_tos
    end
    if card_str then
        msg.card_str = card_str
    end
    if msg_arg then
        msg.arg = msg_arg
    end
    if msg_arg2 then
        msg.arg2 = msg_arg2
    end
    if msg_arg3 then
        msg.arg3 = msg_arg3
    end
    if msg_arg4 then
        msg.arg4 = msg_arg4
    end
    if msg_arg5 then
        msg.arg5 = msg_arg5
    end
    room:sendLog(msg)
end

function SKMC.run_judge(room, who, reason, pattern, good, negative, play_animation, time_consuming)
    local judge = sgs.JudgeStruct()
    judge.who = who
    judge.reason = reason
    judge.pattern = pattern
    if good ~= nil then
        judge.good = good
    else
        judge.good = true
    end
    if negative ~= nil then
        judge.negative = negative
    else
        judge.negative = false
    end
    if play_animation ~= nil then
        judge.play_animation = play_animation
    else
        judge.play_animation = true
    end
    if time_consuming ~= nil then
        judge.time_consuming = time_consuming
    else
        judge.time_consuming = false
    end
    room:judge(judge)
    local result = {}
    result.card = judge.card
    result.isGood = judge:isGood()
    result.isBad = judge:isBad()
    return result
end

function SKMC.number_correction(player, number)
    local n = (number + player:getMark("&number_correction_plus") - player:getMark("&number_correction_minus")) * (1 + player:getMark("&number_correction_multiple"))
    if player:getMark("&number_correction_locking") < n then
        return n
    else
        return player:getMark("&number_correction_locking")
    end
end

sgs.LoadTranslationTable {
        ["number_correction_plus"] = "阿拉伯数字增加",
        ["number_correction_minus"] = "阿拉伯数字减少",
        ["number_correction_multiple"] = "阿拉伯数字翻倍",
        ["number_correction_locking"] = "阿拉伯数字锁定为",

        ["#number_correction_plus"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字加%arg2",
        ["#number_correction_minus"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字减%arg2",
        ["#number_correction_multiple"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字翻%arg2倍",
        ["#number_correction_locking"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字锁定为%arg2",
}

function SKMC.get_string_word_number(str)
    if not str or type(str) ~= "string" or #str <= 0 then
        return nil
    end
    local len_in_byte = #str
    local count = 0
    local i = 1
    while true do
        local cur_byte = string.byte(str, i)
        if i > len_in_byte then
            break
        end
        local byte_count = 1
        if cur_byte > 0 and cur_byte < 128 then
            byte_count = 1
        elseif cur_byte >= 128 and cur_byte < 224 then
            byte_count = 2
        elseif cur_byte >= 224 and cur_byte < 240 then
            byte_count = 3
        elseif cur_byte >= 240 and cur_byte <= 247 then
            byte_count = 4
        else
            break
        end
        i = i + byte_count
        count = count + 1
    end
    return count
end

function SKMC.choice_log(player, choice)
    SKMC.send_message (player:getRoom(), "#choice", player, nil, nil, nil, choice)
end

sgs.LoadTranslationTable {
    ["#choice"] = "%from 选择了 %arg",
}

function SKMC.play_conversation(room, general_name, log, audio_type)
	if type(audio_type) ~= "string" then
		audio_type = "dun"
	end
	local thread = room:getThread()
	thread:delay(295)
	local i = SKMC.get_string_word_number(sgs.Sanguosha:translate(log))
	for a = 1, i do
		room:broadcastSkillInvoke(audio_type, "system")
		thread:delay(80)
	end
	thread:delay(1100)
end

function SKMC.play_conversation(room, general_name, log, audio_type)
    if type(audio_type) ~= "string" then
        audio_type = "dun"
    end
    local thread = room:getThread()
    thread:delay(295)
    local i = SKMC.get_string_word_number(sgs.Sanguosha:translate(log))
    for a = 1, i do
        room:broadcastSkillInvoke(audio_type, "system")
        thread:delay(80)
    end
    thread:delay(1100)
end

function SKMC.get_winner(room, victim)
    local function contains(plist, role)
        for _, p in sgs.qlist(plist) do
            if p:getRoleEnum() == role then
                return true
            end
        end
        return false
    end
    local r = victim:getRoleEnum()
    local sp = room:getOtherPlayers(victim)
    if r == sgs.Player_Lord then
        if (sp:length() == 1 and sp:first():getRole() == "renegade") then
            return "renegade"
        else
            return "rebel"
        end
    else
        if not contains(sp, sgs.Player_Rebel) and not contains(sp, sgs.Player_Renegade) then
            return "lord+loyalist"
        else
            return nil
        end
    end
end

function SKMC.fake_move(room, player, pile_name, id, movein, skill_name, targets)
    local ids = sgs.IntList()
    if type(id) == "number" then
        ids:append(id)
    else
        ids = id
    end
    local players = sgs.SPlayerList()
    if targets then
        players = targets
    else
        players = room:getAllPlayers(true)
    end
    if movein then
        local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
                                            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), skill_name, ""))
        move.to_pile_name = pile_name
        local moves = sgs.CardsMoveList()
        moves:append(move)
        room:notifyMoveCards(true, moves, false, players)
        room:notifyMoveCards(false, moves, false, players)
    else
        local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
                                            sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), skill_name, ""))
        move.from_pile_name = pile_name
        local moves = sgs.CardsMoveList()
        moves:append(move)
        room:notifyMoveCards(true, moves, false, players)
        room:notifyMoveCards(false, moves, false, players)
    end
end

player_mark_clear = sgs.CreateTriggerSkill {
    name = "#player_mark_clear",
    events = {sgs.TurnStart, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnStart then
            local n = 15
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                n = math.min(p:getSeat(), n)
            end
            if player:getSeat() == n and not room:getTag("ExtraTurn"):toBool() then
                if player:getMark("Global_TurnCount") == 0 then
                    room:broadcastSkillInvoke("gamestart", "system")
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        room:addPlayerMark(p, "mvpexp", 1)
                    end
                end
                room:setPlayerMark(player, "@clock_time", player:getMark("Global_TurnCount") + 1)
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, "_lun_clear") and p:getMark(mark) ~= 0 then
                            room:setPlayerMark(p, mark, 0)
                        end
                    end
                end
            end
        else
            for _, mark in sgs.list(player:getMarkNames()) do
                local event_start = string.find(mark, "_start_clear")
                local event_end = string.find(mark, "_end_clear")
                if (event_start and event == sgs.EventPhaseStart) or (event_end and event == sgs.EventPhaseEnd) then
                    local _mark
                    if event_start then
                        _mark = string.sub(mark, 1, event_start)
                    end
                    if event_end then
                        _mark = string.sub(mark, 1, event_end)
                    end
                    if string.find(_mark, player:getPhaseString()) then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("#player_mark_clear") then SKMC.SkillList:append(player_mark_clear) end

sakamichi_armor = sgs.CreateTriggerSkill {
    name = "sakamichi_armor",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardAsked, sgs.SlashEffected, sgs.CardEffected,
                sgs.DamageInflicted, sgs.TargetConfirmed, sgs.PreHpLost},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardAsked then
            local has_eight_diagram = false
            local skill_name = ""
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "eight_diagram") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_eight_diagram = true
                            skill_name = string.sub(mark, 2, string.find(mark, "+") - 1)
                        end
                    else
                        has_eight_diagram = true
                        skill_name = string.sub(mark, 2, string.find(mark, "+") - 1)
                    end
                end
            end
            if has_eight_diagram then
                local pattern = data:toStringList()[1]
                if pattern == "jink" then
                    if room:askForSkillInvoke(player, "eight_diagram", data) then
                        local result = SKMC.run_judge(room, player, skill_name, ".|red", true)
                        room:setEmotion(player, "armor/eight_diagram")
                        if result.isGood then
                            local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
                            jink:deleteLater()
                            jink:setSkillName(skill_name)
                            room:provide(jink)
                            return true
                        end
                    end
                end
            end
        elseif event == sgs.SlashEffected then
            local has_renwang_shield = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "renwang_shield") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_renwang_shield = true
                        end
                    else
                        has_renwang_shield = true
                    end
                end
            end
            if has_renwang_shield then
                local effect = data:toSlashEffect()
                if effect.slash:isBlack() then
                    room:setEmotion(player, "armor/renwang_shield")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "renwang_shield", effect.slash:objectName())
                    return true
                end
            end
            local has_vine = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "vine") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_vine = true
                        end
                    else
                        has_vine = true
                    end
                end
            end
            if has_vine then
                local effect = data:toSlashEffect()
                if effect.nature == sgs.DamageStruct_Normal then
                    room:setEmotion(player, "armor/vine")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "vine", effect.slash:objectName())
                    room:setPlayerFlag(effect.to, "Global_NonSkillNullify")
                    return true
                end
            end
        elseif event == sgs.CardEffected then
            local has_vine = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "vine") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_vine = true
                        end
                    else
                        has_vine = true
                    end
                end
            end
            if has_vine then
                local effect = data:toCardEffect()
                if effect.card:isKindOf("AOE") then
                    room:setEmotion(player, "armor/vine")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "vine", effect.card:objectName())
                    room:setPlayerFlag(effect.to, "Global_NonSkillNullify")
                    return true
                end
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local has_vine = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "vine") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_vine = true
                        end
                    else
                        has_vine = true
                    end
                end
            end
            if has_vine then
                if damage.nature == sgs.DamageStruct_Fire then
                    room:setEmotion(player, "armor/vineburn")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, damage.damage, damage.damage + 1)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
            local has_silver_lion = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "silver_lion") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_silver_lion = true
                        end
                    else
                        has_silver_lion = true
                    end
                end
            end
            if has_silver_lion then
                room:setEmotion(player, "armor/silver_lion")
                SKMC.send_message(room, "SilverLion", player, nil, nil, nil, damage.damage, "silver_lion")
                damage.damage = 1
                data:setValue(damage)
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local has_heiguangkai = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "heiguangkai") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_heiguangkai = true
                        end
                    else
                        has_heiguangkai = true
                    end
                end
            end
            if has_heiguangkai then
                if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:contains(player) and use.to:length() > 1 then
                    room:setEmotion(player, "armor/heiguangkai")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "heiguangkai", use.card:objectName())
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, player:objectName())
                    use.nullified_list = nullified_list
                    data:setValue(use)
                end
            end
        elseif event == sgs.PreHpLost then
            local has_seifuku_no_manekin = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "seifuku_no_manekin") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_seifuku_no_manekin = true
                        end
                    else
                        has_seifuku_no_manekin = true
                    end
                end
            end
            if has_seifuku_no_manekin then
                room:setEmotion(player, "skill_nullify")
                SKMC.send_message(room, "#seifuku_no_manekinProtect", player, nil, nil, nil, "seifuku_no_manekin")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target and target:isAlive() and target:getMark("Armor_Nullified") == 0 and
            not target:hasFlag("WuqianTarget") and target:getMark("Equips_Nullified_to_Yourself") == 0 then
            local list = target:getTag("Qinggang"):toStringList()
            return #list == 0
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_armor") then SKMC.SkillList:append(sakamichi_armor) end

sgs.LoadTranslationTable {
	["noarmor"] = "无防具",
}

wu_jie_te_xiao = sgs.CreateTriggerSkill {
    name = "#wu_jie_te_xiao",
    events = {sgs.CardUsed, sgs.CardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local card_star
        if event == sgs.CardUsed then
            card_star = data:toCardUse().card
        else
            card_star = data:toCardResponse().m_card
        end
        if card_star:isKindOf("EquipCard") then
            return
        end
        room:setEmotion(player, "wujie\\" .. card_star:objectName())
    end,
}
if not sgs.Sanguosha:getSkill("#wu_jie_te_xiao") then SKMC.SkillList:append(wu_jie_te_xiao) end

trig = sgs.CreateTriggerSkill {
    name = "trig",
    global = true,
    events = {sgs.FinishJudge, sgs.GameOverJudge, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.FinishJudge then
            local judge = data:toJudge()
            if judge:isGood() then
                return
            end
            if judge.reason == "indulgence" then
                room:setEmotion(judge.who, "indulgence")
            elseif judge.reason == "supply_shortage" then
                room:setEmotion(judge.who, "supply_shortage")
            elseif judge.reason == "lightning" then
                room:setEmotion(judge.who, "lightning")
            end
        elseif event == sgs.GameOverJudge then
            local current = room:getCurrent()
            local x = current:getMark("havekilled")
            if room:getAllPlayers(true):length() - room:alivePlayerCount() == 1 then
                sgs.Sanguosha:playSystemAudioEffect("yipo")
            end
            if (x > 1) and (x < 8) then
                sgs.Sanguosha:playSystemAudioEffect("lianpo" .. x)
                room:setEmotion(current, "lianpo\\" .. x)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_NotActive then
                room:setPlayerMark(player, "havekilled", 0)
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, "healed", 0)
                    room:setPlayerMark(p, "rescued", 0)
                end
            elseif player:getPhase() == sgs.Player_RoundStart then
                local jsonValue = {player:objectName(), "turnstart"}
                for _, p in sgs.qlist(room:getOtherPlayers(player, true)) do
                    room:doNotify(p, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("trig") then SKMC.SkillList:append(trig) end

mobile_effect = sgs.CreateTriggerSkill {
    name = "mobile_effect",
    global = true,
    events = {sgs.Damage, sgs.DamageComplete, sgs.EnterDying, sgs.GameOverJudge, sgs.HpRecover},
    priority = 9,
    on_trigger = function(self, event, player, data, room)
        local function damage_effect(n)
            if n == 3 then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:getThread():delay(3325)
            elseif n >= 4 then
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:getThread():delay(4000)
            end
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:getMark("mobile_damage") == 0 then
                damage_effect(damage.damage)
            end
        elseif event == sgs.EnterDying then
            local damage = data:toDying().damage
            if damage and damage.from and damage.to:isAlive() then
                if damage.damage >= 3 then
                    damage_effect(damage.damage)
                    room:addPlayerMark(damage.from, "mobile_damage")
                end
            end
        elseif event == sgs.DamageComplete then
            local damage = data:toDamage()
            if damage.from then
                room:setPlayerMark(damage.from, "mobile_damage", 0)
            end
        elseif event == sgs.GameOverJudge then
            local current = room:getCurrent()
            room:addPlayerMark(current, "havekilled", 1)
            local x = current:getMark("havekilled")
            if not room:getTag("FirstBlood"):toBool() then
                room:setTag("FirstBlood", sgs.QVariant(true))
                room:broadcastSkillInvoke(self:objectName(), 3)
                room:getThread():delay(2500)
            end
            if x == 2 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(2800)
            elseif x == 3 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(2800)
            elseif x == 4 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(3500)
            elseif x > 4 and x <= 7 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(4000)
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:objectName() == player:objectName() or (room:getCurrent():objectName() == player:objectName() and not recover.who) then
                room:addPlayerMark(player, "healed", recover.recover)
                if player:getMark("healed") >= 3 then
                    room:setPlayerMark(player, "healed", 0)
                    room:broadcastSkillInvoke(self:objectName(), 10)
                    room:getThread():delay(2000)
                end
            end
            if recover.who and player:objectName() ~= room:getCurrent():objectName() and recover.who:objectName() ~= player:objectName() then
                room:addPlayerMark(recover.who, "rescued", recover.recover)
                if recover.who:getMark("rescued") >= 3 and player:isAlive() then
                    room:setPlayerMark(recover.who, "rescued", 0)
                    room:broadcastSkillInvoke(self:objectName(), 11)
                    room:getThread():delay(2000)
                end
            end
        end
    end,
}
if not sgs.Sanguosha:getSkill("mobile_effect") then SKMC.SkillList:append(mobile_effect) end

sgs.LoadTranslationTable {
    ["mobile_effect"] = "手杀特效",
    [":mobile_effect"] = "鬼晓得这些特效是怎么触发的",
    ["$mobile_effect1"] = "癫狂屠戮！",
    ["$mobile_effect2"] = "无双！万军取首！",
    ["$mobile_effect3"] = "一破！卧龙出山！",
    ["$mobile_effect4"] = "双连！一战成名！",
    ["$mobile_effect5"] = "三连！下次一定！",
    ["$mobile_effect6"] = "四连！天下无敌！",
    ["$mobile_effect7"] = "五连！诛天灭地！",
    ["$mobile_effect8"] = "六连！诛天灭地！",
    ["$mobile_effect9"] = "七连！诛天灭地！",
    ["$mobile_effect10"] = "医术高超~",
    ["$mobile_effect11"] = "妙手回春~",
}

mvp_experience = sgs.CreateTriggerSkill {
    name = "#mvp_experience",
    events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardsMoveOneTime, sgs.PreDamageDone, sgs.HpLost, sgs.GameOverJudge},
    global = true,
    priority = 3,
    on_trigger = function(self, event, player, data, room)
        local room = player:getRoom()
        if not string.find(room:getMode(), "p") then
            return
        end
        if room:getTag("DisableMVP"):toBool() then
            return
        end
        local x = 1
        local conv = false
        if event == sgs.PreCardUsed or event == sgs.CardResponded then
            local card = nil
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:getTypeId() == sgs.Card_TypeBasic then
                room:addPlayerMark(player, "mvpexp", x)
            elseif card:getTypeId() == sgs.Card_TypeTrick then
                room:addPlayerMark(player, "mvpexp", 3 * x)
            elseif card:getTypeId() == sgs.Card_TypeEquip then
                room:addPlayerMark(player, "mvpexp", 2 * x)
            end
            if conv and math.random() < 0.1 then
                SKMC.play_conversation(room, player:getGeneralName(), "#mvpuse" .. math.floor(math.random(6)))
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if not move.to or player:objectName() ~= move.to:objectName() or (move.from and move.from:objectName() == move.to:objectName()) or
                (move.to_place ~= sgs.Player_PlaceHand and move.to_place ~= sgs.Player_PlaceEquip) or room:getTag("FirstRound"):toBool() then
                return false
            end
            room:addPlayerMark(player, "mvpexp", move.card_ids:length() * x)
        elseif event == sgs.PreDamageDone then
            local damage = data:toDamage()
            if damage.from then
                room:addPlayerMark(damage.from, "mvpexp", damage.damage * 5 * x)
                room:addPlayerMark(damage.to, "mvpexp", damage.damage * 2 * x)
                if conv then
                    SKMC.play_conversation(room, damage.from:getGeneralName(), "#mvpdamage" .. math.floor(math.random(6)))
                end
            end
        elseif event == sgs.HpLost then
            local lose = data:toInt()
            room:addPlayerMark(player, "mvpexp", lose * x)
            if conv and math.random() < 0.3 then
                SKMC.play_conversation(room, player:getGeneralName(), "#mvplose" .. math.floor(math.random(6)))
            end
        elseif event == sgs.GameOverJudge then
            local death = data:toDeath()
            if not death.who:isLord() then
                room:removePlayerMark(death.who, "mvpexp", 100)
            else
                for _, p in sgs.qlist(room:getOtherPlayers(death.who)) do
                    room:addPlayerMark(p, "mvpexp", 10 * x)
                end
                local damage = death.damage
                if damage and damage.from and damage.from:isAlive() and not damage.from:isLord() then
                    room:addPlayerMark(damage.from, "mvpexp", 5 * x)
                end
            end
            local t = SKMC.get_winner(room, death.who)
            if not t then
                return
            end
            local players = sgs.QList2Table(room:getAlivePlayers())
            local function loser(p)
                local tt = t:split("+")
                if not table.contains(tt, p:getRole()) then
                    return true
                end
                return false
            end
            for _, p in ipairs(players) do
                if loser(p) then
                    table.removeOne(players, p)
                end
            end
            local comp = function(a, b)
                return a:getMark("mvpexp") > b:getMark("mvpexp")
            end
            if #players > 1 then
                table.sort(players, comp)
            end
            local str = players[1]:getGeneralName()
            local str2 = players[1]:screenName()
            room:doAnimate(2, "skill=MobileMvp:" .. str .. ":" .. str2, "~" .. str)
            room:broadcastSkillInvoke("mobile_effect", 12)
            local thread = room:getThread()
            thread:delay(1100)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("#mvp_experience") then SKMC.SkillList:append(mvp_experience) end

ExtraCollateralCard = sgs.CreateSkillCard {
    name = "ExtraCollateral",
    filter = function(self, targets, to_select)
        local coll = sgs.Card_Parse(sgs.Self:property("extra_collateral"):toString())
        if not coll then
            return false
        end
        local tos = sgs.Self:property("extra_collateral_current_targets"):toString():split("+")
        if #targets == 0 then
            return not table.contains(tos, to_select:objectName()) and not sgs.Self:isProhibited(to_select, coll) and coll:targetFilter(SKMC.table_to_PlayerList(targets), to_select, sgs.Self)
        else
            return coll:targetFilter(SKMC.table_to_PlayerList(targets), to_select, sgs.Self)
        end
    end,
    about_to_use = function(self, room, use)
        local killer = use.to:first()
        local victim = use.to:last()
        room:setPlayerFlag(killer, "ExtraCollateralTarget")
        local _data = sgs.QVariant()
        _data:setValue(victim)
        killer:setTag("collateralVictim", _data)
    end,
}
ExtraCollateral = sgs.CreateZeroCardViewAsSkill {
    name = "ExtraCollateral",
    response_pattern = "@@ExtraCollateral",
    view_as = function()
        return ExtraCollateralCard:clone()
    end,
}
if not sgs.Sanguosha:getSkill("ExtraCollateral") then SKMC.SkillList:append(ExtraCollateral) end

-- =====================================================================================乃木坂46============================================================================================--

-- 松井 玲奈
RenaMatsui = sgs.General(Sakamichi, "RenaMatsui", "Nogizaka46", 8, false)
SKMC.IKiSei.RenaMatsui = true
SKMC.SeiMeiHanDan.RenaMatsui = {
    name = {8, 4, 9, 8},
    ten_kaku = {12, "xiong"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_ji_la = sgs.CreateTriggerSkill {
    name = "sakamichi_ji_la",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local hp_max = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getHp() > player:getHp() then
                        hp_max = false
                        break
                    end
                end
                if hp_max then
                    local choice = room:askForChoice(player, self:objectName(), "hp+maxhp")
                    SKMC.choice_log(player, choice)
                    if choice == "hp" then
                        room:loseHp(player, SKMC.number_correction(player, 1))
                        SKMC.send_message(room, "#ji_la_hp", player, nil, nil, nil, self:objectName(), player:getHp())
                    else
                        room:loseMaxHp(player, SKMC.number_correction(player, 1))
                        SKMC.send_message(room, "#ji_la_maxhp", player, nil, nil, nil, self:objectName(), player:getMaxHp())
                    end
                end
                return false
            elseif change.to == sgs.Player_Start then
                local hp_min = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if player:getHp() > p:getHp() then
                        hp_min = false
                        break
                    end
                end
                if hp_min then
                    room:setPlayerFlag(player, self:objectName())
                    SKMC.send_message(room, "#ji_la_vs", player, nil, nil, nil, self:objectName())
                end
                return false
            end
        elseif event == sgs.DamageCaused then
            if player:hasFlag(self:objectName()) then
                local damage = data:toDamage()
                if damage.chain or damage.transfer or not damage.by_user then
                    return false
                end
                if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
                    damage.damage = damage.damage + SKMC.number_correction(player, 1)
                    SKMC.send_message(room, "#ji_la_damage", player, damage.to, nil, damage.card:toString(), self:objectName(), damage.damage)
                    data:setValue(damage)
                end
                return false
            end
        end
    end,
}
RenaMatsui:addSkill(sakamichi_ji_la)

sgs.LoadTranslationTable {
    ["RenaMatsui"] = "松井 玲奈",
    ["&RenaMatsui"] = "松井 玲奈",
    ["#RenaMatsui"] = "激辣剽勇",
    ["~RenaMatsui"] = "才能なんて誰にでも備わってるもの",
    ["designer:RenaMatsui"] = "Cassimolar",
    ["cv:RenaMatsui"] = "松井 玲奈",
    ["illustrator:RenaMatsui"] = "Cassimolar",
    ["sakamichi_ji_la"] = "激辣",
    [":sakamichi_ji_la"] = "锁定技，结束阶段，若你是全场体力最多的角色，你须失去1点体力或减少1点体力上限。准备阶段，若你是全场体力最少的角色，本回合内你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1。",
    ["sakamichi_ji_la:hp"] = "体力",
    ["sakamichi_ji_la:maxhp"] = "体力上限",
    ["#ji_la_hp"] = "%from 的【%arg】触发，%from 选择失去<font color=\"yellow\"><b>1</b></font>点体力，%from 现在的体力为 %arg2 点",
    ["#ji_la_maxhp"] = "%from 的【%arg】触发，%from 选择失去<font color=\"yellow\"><b>1</b></font>点体力上限，%from 现在的体力上限为 %arg2 点",
    ["#ji_la_vs"] = "%from 的【%arg】触发，本回合内 %from 使用的【<font color=\"yellow\"><b>杀</b></font>】或【<font color=\"yellow\"><b>决斗</b></font>】（ %from 为伤害来源时）造成的伤害+1。",
    ["#ji_la_damage"] = "%from 的【%arg】触发，此%card 对 %to 造成的伤害为 %arg2 点",
}

-- 生駒 里奈
RinaIkoma = sgs.General(Sakamichi, "RinaIkoma$", "Nogizaka46", 4, false)
SKMC.IKiSei.RinaIkoma = true
SKMC.SeiMeiHanDan.RinaIkoma = {
    name = {5, 15, 7, 8},
    ten_kaku = {20, "xiong"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_xi_wang = sgs.CreateTriggerSkill {
    name = "sakamichi_xi_wang$",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:getKingdom() == "Nogizaka46" and dying.who:getMark("xi_wang_used") == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self:objectName()) and room:askForSkillInvoke(dying.who, self:objectName(), sgs.QVariant("invoke:" .. p:objectName() .. "::" .. self:objectName())) then
                    room:addPlayerMark(dying.who, "xi_wang_used", 1)
                    dying.who:throwAllHandCards()
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, SKMC.number_correction(p, 1)))
                    local n = 0
                    for _, pl in sgs.qlist(room:getAlivePlayers()) do
                        if pl:getKingdom() == "Nogizaka46" then
                            n = n + 1
                        end
                    end
                    room:drawCards(dying.who, n, self:objectName())
                    break
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaIkoma:addSkill(sakamichi_xi_wang)

sakamichi_jiao_huan_card = sgs.CreateSkillCard {
    name = "sakamichi_jiao_huanCard",
    skill_name = "sakamichi_jiao_huan",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return to_select:getHandcardNum() >= self:subcardsLength() and to_select:getKingdom() ~= sgs.Self:getKingdom()
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local cards = room:askForExchange(effect.to, self:getSkillName(), self:subcardsLength(), self:subcardsLength(), false,
                                            "@jiao_huang_sheng:" .. effect.from:objectName() .. "::" .. self:subcardsLength())
        room:obtainCard(effect.from, cards, false)
        room:obtainCard(effect.to, self, false)
    end,
}
sakamichi_jiao_huan = sgs.CreateViewAsSkill {
    name = "sakamichi_jiao_huan",
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cd = sakamichi_jiao_huan_card:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            cd:setSkillName(self:objectName())
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_jiao_huanCard") and not player:isKongcheng() and SKMC.has_specific_kingdom_player(player, false)
    end,
}
RinaIkoma:addSkill(sakamichi_jiao_huan)

sakamichi_shao_nian_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_shao_nian",
    view_as = function(self)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName(self:objectName())
        duel:addSubcards(sgs.Self:getHandcards())
        return duel
    end,
    enabled_at_play = function(self, player)
        return player:getMark("shao_nian_used") < 2 and not player:isKongcheng()
    end,
}
sakamichi_shao_nian = sgs.CreateTriggerSkill {
    name = "sakamichi_shao_nian",
    events = {sgs.CardFinished, sgs.PreDamageDone, sgs.EventPhaseChanging, sgs.CardUsed, sgs.DamageCaused},
    view_as_skill = sakamichi_shao_nian_view_as,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreDamageDone then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == self:objectName() and damage.from then
                room:drawCards(damage.to, 1, self:objectName())
                room:addPlayerMark(damage.to, "shao_nian_used")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == self:objectName() then
                room:drawCards(use.from, 1, self:objectName())
                room:addPlayerMark(use.from, "shao_nian_used")
                if use.card:hasFlag("shao_nian_damage") then
                    room:setCardFlag(use.card, "-shao_nian_damage")
                end
                if use.card:hasFlag("shao_nian_from" .. use.from:objectName()) then
                    room:setCardFlag(use.card, "-shao_nian_from" .. use.from:objectName())
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    room:setPlayerMark(p, "shao_nian_used", 0)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == self:objectName() and use.from:objectName() == player:objectName() and
                player:hasSkill(self:objectName()) then
                room:setCardFlag(use.card, "shao_nian_from" .. player:objectName())
                local no_respond_list = use.no_respond_list
                for _, p in sgs.qlist(use.to) do
                    if use.card:getSubcards():length() >= p:getHp() then
                        table.insert(no_respond_list, p:objectName())
                    end
                end
                if use.card:getSubcards():length() <= use.from:getHp() then
                    room:setCardFlag(use.card, "shao_nian_damage")
                end
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("shao_nian_damage") then
                local from
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if damage.card:hasFlag("shao_nian_from" .. p:objectName()) then
                        from = p
                    end
                end
                if from then
                    damage.damage = damage.damage + SKMC.number_correction(from, 1)
                else
                    damage.damage = damage.damage + 1
                end
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaIkoma:addSkill(sakamichi_shao_nian)

sgs.LoadTranslationTable {
    ["RinaIkoma"] = "生駒 里奈",
    ["&RinaIkoma"] = "生駒 里奈",
    ["#RinaIkoma"] = "水玉模様",
    ["~RinaIkoma"] = "反省とかはしていいけど、自分のことは責めなくていい",
    ["designer:RinaIkoma"] = "Cassimolar",
    ["cv:RinaIkoma"] = "生駒 里奈",
    ["illustrator:RinaIkoma"] = "Cassimolar",
    ["sakamichi_xi_wang"] = "希望",
    [":sakamichi_xi_wang"] = "主公技，每名乃木坂46势力角色限一次，其进入濒死时，其可以弃置所有手牌然后回复1点体力并摸X张牌（X为场上乃木坂46势力角色数）。",
    ["sakamichi_xi_wang:invoke"] = "是否发动%src 的【%arg】",
    ["sakamichi_jiao_huan"] = "交换",
    [":sakamichi_jiao_huan"] = "出牌阶段限一次，你可以与一名势力与你不同的角色交换等量的手牌和势力。",
    ["@jiao_huang_sheng"] = "请选择用于和%src交换的 %arg 张手牌",
    ["sakamichi_shao_nian"] = "少年",
    [":sakamichi_shao_nian"] = "出牌阶段，你可以将所有手牌当【决斗】使用，若此【决斗】对应的实体牌数大于或等于目标的体力值，其无法响应此【决斗】、小于等于你的体力值，此【决斗】造成伤害时，伤害+1，然后你和以此法受到伤害的角色各摸一张牌，若你于同一阶段内以此法摸过两张或更多的牌，则此技能失效直到回合结束。",
}

-- 市來 玲奈
RenaIchiki = sgs.General(Sakamichi, "RenaIchiki", "Nogizaka46", 3, false)
SKMC.IKiSei.RenaIchiki = true
SKMC.SeiMeiHanDan.RenaIchiki = {
    name = {5, 8, 9, 8},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {17, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_guo_biao_wu_card = sgs.CreateSkillCard {
    name = "sakamichi_guo_biao_wuCard",
    skill_name = "sakamichi_guo_biao_wu",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.to:isKongcheng() then
            room:setPlayerFlag(effect.to, "guo_biao_wu")
            SKMC.send_message(room, "#guo_biao_wu", effect.from, effect.to, nil, nil, self:getSkillName())
        else
            local data_for_ai = sgs.QVariant()
            data_for_ai:setValue(effect.from)
            local card = room:askForCard(effect.to, ".|.|.|hand", "@guo_biao_wu_give:" .. effect.from:objectName(), data_for_ai, sgs.Card_MethodNone)
            if card then
                room:obtainCard(effect.from, card, false)
                room:showCard(effect.from, self:getEffectiveId())
                room:showCard(effect.from, card:getEffectiveId())
                if sgs.Sanguosha:getCard(self:getEffectiveId()):getTypeId() == card:getTypeId() then
                    room:addSlashJuli(effect.from, 1000, true)
                    SKMC.send_message(room, "#guo_biao_wu_type", effect.from, effect.to)
                end
                if sgs.Sanguosha:getCard(self:getEffectiveId()):getSuit() == card:getSuit() then
                    room:addSlashMubiao(effect.from, 1, true)
                    SKMC.send_message(room, "#guo_biao_wu_suit", effect.from, effect.to)
                end
                if sgs.Sanguosha:getCard(self:getEffectiveId()):getNumber() == card:getNumber() then
                    room:setPlayerFlag(effect.from, "guo_biao_wu_number")
                    SKMC.send_message(room, "#guo_biao_wu_number", effect.from, effect.to)
                end
                if SKMC.true_name(sgs.Sanguosha:getCard(self:getEffectiveId())) == SKMC.true_name(card) then
                    room:addSlashCishu(effect.from, 1000, true)
                    SKMC.send_message(room, "#guo_biao_wu_name", effect.from, effect.to)
                end
            else
                room:setPlayerFlag(effect.to, "guo_biao_wu")
                SKMC.send_message(room, "#guo_biao_wu_wu", effect.from, effect.to, nil, nil, self:getSkillName())
            end
        end
        room:throwCard(self, effect.from, effect.from)
    end,
}
sakamichi_guo_biao_wu_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_guo_biao_wu",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_guo_biao_wu_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#sakamichi_guo_biao_wuCard")
    end,
}
sakamichi_guo_biao_wu = sgs.CreateTriggerSkill {
    name = "sakamichi_guo_biao_wu",
    view_as_skill = sakamichi_guo_biao_wu_view_as,
    events = {sgs.EventPhaseChanging, sgs.SlashProceed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:hasFlag("guo_biao_wu") then
                        room:setPlayerFlag(p, "-guo_biao_wu")
                    end
                end
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasSkill(self:objectName()) and effect.from:hasFlag("guo_biao_wu_number") then
                room:slashResult(effect, nil)
                return true
            end
        end
        return false
    end,
}
sakamichi_guo_biao_wu_Invalidity = sgs.CreateInvaliditySkill {
    name = "#sakamichi_guo_biao_wu_Invalidity",
    skill_valid = function(self, player, skill)
        if player:hasFlag("guo_biao_wu") then
            return false
        else
            return true
        end
    end,
}
RenaIchiki:addSkill(sakamichi_guo_biao_wu)
if not sgs.Sanguosha:getSkill("#sakamichi_guo_biao_wu_Invalidity") then SKMC.SkillList:append(sakamichi_guo_biao_wu_Invalidity) end

sakamichi_mi_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_shu",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.card:getSubcards():length() > 1 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    local ids = room:getNCards(use.card:getSubcards():length())
                    room:fillAG(ids)
                    local id1 = room:askForAG(p, ids, false, self:objectName())
                    room:moveCardTo(sgs.Sanguosha:getCard(id1), p, sgs.Player_PlaceHand, true)
                    room:takeAG(p, id1, false)
                    local id2 = room:askForAG(use.from, ids, false, self:objectName())
                    room:moveCardTo(sgs.Sanguosha:getCard(id2), use.from, sgs.Player_PlaceHand, true)
                    room:takeAG(use.from, id2, false)
                    room:clearAG()
                    room:broadcastInvoke("clearAG")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RenaIchiki:addSkill(sakamichi_mi_shu)

sgs.LoadTranslationTable {
    ["RenaIchiki"] = "市來 玲奈",
    ["&RenaIchiki"] = "市來 玲奈",
    ["#RenaIchiki"] = "初代学霸",
    ["~RenaIchiki"] = "にじゅう…",
    ["designer:RenaIchiki"] = "Cassimolar",
    ["cv:RenaIchiki"] = "市來 玲奈",
    ["illustrator:RenaIchiki"] = "Cassimolar",
    ["sakamichi_guo_biao_wu"] = "国标舞",
    [":sakamichi_guo_biao_wu"] = "出牌阶段限一次，你可以选择一张手牌并令一名其他角色交给你一张手牌，然后展示两张牌，若两张牌类别/花色/点数/牌名相同，你本回合内使用【杀】无距离限制/可以多指定一个目标/无法闪避/无次数限制；若其未交给你手牌，本回合内，其所有技能失效；然后弃置你选择的牌。",
    ["@guo_biao_wu_give"] = "请交给%src一张手牌，否则本回合你的技能失效",
    ["#guo_biao_wu"] = "%to 拒绝将一张手牌交给%from，因【%arg】其本回合内技能失效。",
    ["#guo_biao_wu_type"] = "%to 给%from 的牌与%from 选择的牌类别相同，本回合内%from 使用【杀】无距离限制。",
    ["#guo_biao_wu_suit"] = "%to 交给%from 的牌与%from 选择的牌花色相同，本回合内%from 使用【杀】可以额外指定一个目标。",
    ["#guo_biao_wu_number"] = "%to 交给%from 的牌与%from 选择的牌点数相同，本回合内%from 使用【杀】无法闪避。",
    ["#guo_biao_wu_name"] = "%to 交给%from 的牌与%from 选择的牌牌名相同，本回合内%from 使用【杀】无次数限制。",
    ["sakamichi_mi_shu"] = "秘书",
    [":sakamichi_mi_shu"] = "当一名角色使用牌时，若此牌对应的实体牌多于一张，你可以翻开牌堆顶等量的牌，你和其各选择获得其中的一张。",
}

-- 柏 幸奈
YukinaKashiwa = sgs.General(Sakamichi, "YukinaKashiwa", "Nogizaka46", 3, false)
SKMC.IKiSei.YukinaKashiwa = true
SKMC.SeiMeiHanDan.YukinaKashiwa = {
    name = {9, 8, 8},
    ten_kaku = {9, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {25, "ji"},
    go_gyo_san_sai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_tong_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_tong_xing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local damage = death.damage
        if damage and damage.from and damage.from:objectName() == player:objectName() then
            room:gainMaxHp(player, SKMC.number_correction(player, 1))
            if player:isWounded() then
                room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            end
            SKMC.send_message(room, "#GetHp", player, nil, nil, nil, player:getHp(), player:getMaxHp())
        end
        return false
    end,
}
sakamichi_tong_xing_Mod = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_tong_xing_Mod",
    fixed_func = function(self, target)
        if target:hasSkill("sakamichi_tong_xing") then
            return target:getMaxHp()
        else
            return -1
        end
    end,
}
YukinaKashiwa:addSkill(sakamichi_tong_xing)
if not sgs.Sanguosha:getSkill("#sakamichi_tong_xing_Mod") then SKMC.SkillList:append(sakamichi_tong_xing_Mod) end

sakamichi_gui_lian_card = sgs.CreateSkillCard {
    name = "sakamichi_gui_lianCard",
    skill_name = "sakamichi_gui_lian",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@wryface")
        local choice = room:askForChoice(effect.from, self:getSkillName(), "card_limitation=" .. effect.to:objectName() .. "+skill_invalidity=" .. effect.to:objectName())
        SKMC.choice_log(effect.from, choice)
        if choice == "card_limitation=" .. effect.to:objectName() then
            room:setPlayerCardLimitation(effect.to, "use,response", ".|.|.|hand", true)
            SKMC.send_message(room, "#gui_lian_card", effect.from, effect.to, nil, nil, self:getSkillName())
        else
            room:setPlayerFlag(effect.from, "gui_lian" .. effect.to:objectName())
            room:addPlayerMark(effect.to, "@skill_invalidity")
            SKMC.send_message(room, "#gui_lian_skill", effect.from, effect.to, nil, nil, self:getSkillName())
        end
    end,
}
sakamichi_gui_lian_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_gui_lian",
    view_as = function()
        return sakamichi_gui_lian_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@wryface") ~= 0
    end,
}
sakamichi_gui_lian = sgs.CreateTriggerSkill {
    name = "sakamichi_gui_lian",
    frequency = sgs.Skill_Limited,
    events = {sgs.EventPhaseChanging},
    limit_mark = "@wryface",
    view_as_skill = sakamichi_gui_lian_view_as,
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:hasFlag("gui_lian" .. p:objectName()) then
                    room:setPlayerFlag(player, "-gui_lian" .. p:ojectName())
                    room:removePlayerMark(p, "@skill_invalidity")
                end
            end
        end
        return false
    end,
}
YukinaKashiwa:addSkill(sakamichi_gui_lian)

sakamichi_tian_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_tian_shi",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_xiao_yan",
    events = {sgs.EventPhaseChanging},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if data:toPhaseChange().to == sgs.Player_Start and player:getMark("tian_shi_can_wake") ~= 0 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        if room:changeMaxHpForAwakenSkill(player, SKMC.number_correction(player, 1)) then
            room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            room:handleAcquireDetachSkills(player, "-sakamichi_gui_lian|sakamichi_xiao_yan")
            room:setPlayerMark(player, "@wryface", 0)
        end
        return false
    end,
}
sakamichi_tian_shi_record = sgs.CreateTriggerSkill {
    name = "#sakamichi_tian_shi_record",
    events = {sgs.Death, sgs.EnterDying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            local damage = death.damage
            if damage and damage.from and damage.from:objectName() == player:objectName() and player:hasSkill("sakamichi_tian_shi") and player:getMark("tian_shi_can_wake") == 0 and
                player:getMark("sakamichi_tian_shi") == 0 then
                room:setPlayerMark(player, "tian_shi_can_wake", 1)
            end
        else
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and player:hasSkill("sakamichi_tian_shi") and player:getMark("tian_shi_can_wake") == 0 and player:getMark("sakamichi_tian_shi") ==
                0 then
                room:setPlayerMark(player, "tian_shi_can_wake", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_tian_shi", "#sakamichi_tian_shi_record")
YukinaKashiwa:addSkill(sakamichi_tian_shi)
YukinaKashiwa:addSkill(sakamichi_tian_shi_record)

sakamichi_xiao_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from and death.damage.from:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_NotActive then
                room:setPlayerFlag(player, "sakamichi_xiao_yan")
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and player:hasFlag("sakamichi_xiao_yan") then
                room:setPlayerFlag(player, "-sakamichi_xiao_yan")
                SKMC.send_message(room, "#Fangquan", nil, player)
                player:gainAnExtraTurn()
            end
            return false
        end
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_xiao_yan") then SKMC.SkillList:append(sakamichi_xiao_yan) end

sakamichi_tao_cao = sgs.CreateTriggerSkill {
    name = "sakamichi_tao_cao",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_yi_cai",
    events = {sgs.EventPhaseStart},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPhase() == sgs.Player_Start and player:getHandcardNum() > player:getHp() and player:isWounded() then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        if room:changeMaxHpForAwakenSkill(player, -SKMC.number_correction(player, 1)) then
            if player:isWounded() then
                room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            end
            room:handleAcquireDetachSkills(player, "sakamichi_yi_cai")
        end
    end,
}
YukinaKashiwa:addSkill(sakamichi_tao_cao)

sakamichi_yi_cai = sgs.CreateTriggerSkill {
    name = "sakamichi_yi_cai",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                card = use.card
            elseif event == sgs.CardResponsed then
                card = data:toResponsed().m_card
            end
            if card and card:isNDTrick() then
                room:throwCard(card, nil)
                room:askForUseCard(player, "slash", "@askforslash")
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                if not damage.to:isAllNude() then
                    local card = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false, sgs.Card_MethodNone)
                    room:obtainCard(player, card)
                else
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_yi_cai") then SKMC.SkillList:append(sakamichi_yi_cai) end

sgs.LoadTranslationTable {
    ["YukinaKashiwa"] = "柏 幸奈",
    ["&YukinaKashiwa"] = "柏 幸奈",
    ["#YukinaKashiwa"] = "流浪偶像",
    ["~YukinaKashiwa"] = "我が道を行く",
    ["designer:YukinaKashiwa"] = "Cassimolar",
    ["cv:YukinaKashiwa"] = "柏 幸奈",
    ["illustrator:YukinaKashiwa"] = "Cassimolar",
    ["sakamichi_tong_xing"] = "童星",
    [":sakamichi_tong_xing"] = "锁定技，当你杀死一名角色后，你增加1点体力上限并回复1点体力。你的手牌上限等于你的体力上限。",
    ["sakamichi_gui_lian"] = "鬼脸",
    [":sakamichi_gui_lian"] = "限定技，出牌阶段，你可以令一名其他角色本回合内无法使用或打出手牌/非锁定技失效。",
    ["sakamichi_gui_lian:card_limitation"] = "令%src本回合内无法使用或打出手牌",
    ["sakamichi_gui_lian:skill_invalidity"] = "令%src本回合内非锁定技无效",
    ["#gui_lian_card"] = "%from 发动【%arg】令%to 本回合内无法使用或打出手牌",
    ["#gui_lian_skill"] = "%from 发动【%arg】令%to 本回合内非锁定技无效",
    ["@wryface"] = "鬼脸",
    ["sakamichi_tian_shi"] = "天使",
    [":sakamichi_tian_shi"] = "觉醒技，准备阶段，若你已杀死至少一名角色或进入过濒死，你增加1点体力上限并回复1点体力，然后失去【鬼脸】获得【笑颜】。",
    ["sakamichi_xiao_yan"] = "笑颜",
    [":sakamichi_xiao_yan"] = "锁定技，结束阶段，若本回合内你至少杀死一名角色，你执行一个额外的回合。",
    ["sakamichi_tao_cao"] = "桃草",
    [":sakamichi_tao_cao"] = "觉醒技，准备阶段，若你的手牌数大于你的体力值且你已受伤，你须减少1点体力上限并回复1点体力，然后获得【异才】。",
    ["sakamichi_yi_cai"] = "异才",
    [":sakamichi_yi_cai"] = "当你使用一张通常锦囊牌时（在它结算之前），你可以立即对攻击范围内的角色使用一张【杀】。当你使用【杀】造成伤害后，你可以获得目标区域内的一张牌（若目标区域内没有牌，则你摸一张牌）。",
}

-- 斎藤 ちはる
ChiharuSaito = sgs.General(Sakamichi, "ChiharuSaito", "Nogizaka46", 4, false)
SKMC.IKiSei.ChiharuSaito = true
SKMC.SeiMeiHanDan.ChiharuSaito = {
    name = {11, 18, 3, 4, 3},
    ten_kaku = {29, "te_shu_ge"},
    jin_kaku = {21, "ji"},
    ji_kaku = {10, "xiong"},
    soto_kaku = {18, "ji"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "shui",
        san_sai = "ji",
    },
}

sakamichi_jia_ge_card = sgs.CreateSkillCard {
    name = "sakamichi_jia_geCard",
    skill_name = "sakamichi_jia_ge",
    target_fixed = true,
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    on_use = function(self, room, source, targets)
        local target
        if not source:hasFlag("jia_ge") then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getNextAlive():objectName() == source:objectName() then
                    target = p
                end
            end
        else
            target = source:getNextAlive()
        end
        room:obtainCard(target, self)
        local choice = room:askForChoice(source, self:getSkillName(), "BasicCard+TrickCard+EquipCard")
        SKMC.choice_log(source, choice)
        local card = room:askForCard(target, choice, "@jia_ge_choice:" .. source:objectName() .. "::" .. choice, sgs.QVariant(), sgs.Card_MethodNone)
        if card then
            room:obtainCard(source, card)
        else
            room:drawCards(source, 2, self:getSkillName())
        end
        if not source:hasFlag("jia_ge") then
            room:setPlayerFlag(source, "jia_ge")
            room:askForUseCard(source, "@@sakamichi_jia_ge", "@jia_ge_invoke", -1, sgs.Card_MethodNone, false)
        end
    end,
}
sakamichi_jia_ge = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jia_ge",
    response_pattern = "",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_jia_ge_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#sakamichi_jia_geCard")
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_jia_ge")
    end,
}
ChiharuSaito:addSkill(sakamichi_jia_ge)

sakamichi_bao_zhong = sgs.CreateTriggerSkill {
    name = "sakamichi_bao_zhong",
    events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded, sgs.EventLoseSkill, sgs.PreHpRecover},
    priority = {6, 1, 1},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then
                player:setMark(self:objectName(), 0)
                room:setPlayerMark(player, "&bao_zhong+red", 0)
                room:setPlayerMark(player, "&bao_zhong+black", 0)
            end
        elseif (event == sgs.CardUsed or event == sgs.CardResponded) and player:hasSkill(self:objectName()) then
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                if player:objectName() == use.from:objectName() then
                    card = use.card
                end
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if card == nil or card:isKindOf("SkillCard") or player:getPhase() == sgs.Player_NotActive then
                return false
            end
            local color_int = function(acard)
                local int = 2
                if acard:isRed() then
                    int = 0
                elseif acard:isBlack() then
                    int = 1
                end
                return int
            end
            if player:getMark(self:objectName()) ~= 0 then
                local old_color = player:getMark(self:objectName()) - 1
                local d = sgs.QVariant()
                d:setValue(card)
                if old_color ~= color_int(card) and room:askForSkillInvoke(player, self:objectName(), d) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
            player:setMark(self:objectName(), color_int(card) + 1)
            if player:getMark(self:objectName()) == 1 then
                room:setPlayerMark(player, "&bao_zhong+black", 0)
                room:setPlayerMark(player, "&bao_zhong+red", 1)
            end
            if player:getMark(self:objectName()) == 2 then
                room:setPlayerMark(player, "&bao_zhong+red", 0)
                room:setPlayerMark(player, "&bao_zhong+black", 1)
            end
        elseif event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() then
                room:setPlayerMark(player, "&bao_zhong+black", 0)
                room:setPlayerMark(player, "&bao_zhong+red", 0)
                room:setPlayerMark(player, self:objectName(), 0)
            end
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:isFemale() and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
                recover.recover = recover.recover + SKMC.number_correction(player, 1)
                SKMC.send_message(room, "#bao_zhong_recover", recover.who, player, nil, nil, self:objectName(), recover.recover)
                data:setValue(recover)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ChiharuSaito:addSkill(sakamichi_bao_zhong)

sgs.LoadTranslationTable {
    ["ChiharuSaito"] = "斎藤 ちはる",
    ["&ChiharuSaito"] = "斎藤 ちはる",
    ["#ChiharuSaito"] = "朝日主播",
    ["~ChiharuSaito"] = "テレビゲーム、タノシー！！",
    ["designer:ChiharuSaito"] = "Cassimolar",
    ["cv:ChiharuSaito"] = "斎藤 ちはる",
    ["illustrator:ChiharuSaito"] = "Cassimolar",
    ["sakamichi_jia_ge"] = "家歌",
    [":sakamichi_jia_ge"] = "出牌阶段限一次，你可以将一张手牌交给你的上家，然后你指定一种类型的牌并令其选择交给你一张此类型的牌或令你摸两张牌，然后你可以对你的下家重复此流程。",
    ["@jia_ge_choice"] = "你需交给%src 一张 %arg 否则其摸两张牌",
    ["@jia_ge_invoke"] = "你可以将一张手牌交给下家",
    ["sakamichi_bao_zhong"] = "宝冢",
    [":sakamichi_bao_zhong"] = "女性角色令你回复体力时回复量+1。你的回合内，当你使用一张牌时，若此牌于你此回合内使用的上一张牌的颜色不同，你可以摸一张牌。",
    ["bao_zhong"] = "宝冢",
    ["#bao_zhong_recover"] = "%to 发动【%arg】令%from 对%to 的回复量加１，此次回复量为 %arg2 点",
}

-- 生田 絵梨花
ErikaIkuta = sgs.General(Sakamichi, "ErikaIkuta", "Nogizaka46", 3, false)
SKMC.IKiSei.ErikaIkuta = true
SKMC.SeiMeiHanDan.ErikaIkuta = {
    name = {5, 5, 12, 11, 7},
    ten_kaku = {10, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {30, "ji_xiong_hun_he"},
    soto_kaku = {23, "ji"},
    sou_kaku = {40, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_lan_tian = sgs.CreateTriggerSkill {
    name = "sakamichi_lan_tian$",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getKingdom() == "Nogizaka46" then
            local min = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() < player:getHandcardNum() then
                    min = false
                    break
                end
            end
            if min then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                        while min do
                            room:drawCards(player, 1, self:objectName())
                            for _, pl in sgs.qlist(room:getOtherPlayers(player)) do
                                if pl:getHandcardNum() < player:getHandcardNum() then
                                    min = false
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ErikaIkuta:addSkill(sakamichi_lan_tian)

sakamichi_xia_chu = sgs.CreateTriggerSkill {
    name = "sakamichi_xia_chu",
    events = {sgs.AskForPeaches, sgs.PreventPeach, sgs.AfterPreventPeach},
    priority = {7, 7, 7},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if event == sgs.AskForPeaches then
            if player:objectName() == room:getAllPlayers():first():objectName() then
                local current = room:getCurrent()
                if current and current:getPhase() ~= sgs.Player_NotActive and current:hasSkill(self:objectName()) then
                    room:notifySkillInvoked(current, self:objectName())
                    if current:objectName() ~= dying.who:objectName() then
                        SKMC.send_message(room, "#xia_chu_2", current, dying.who, nil, nil, self:objectName())
                    else
                        SKMC.send_message(room, "#xia_chu_1", current, nil, nil, nil, self:objectName())
                    end
                end
            end
        elseif event == sgs.PreventPeach then
            local current = room:getCurrent()
            if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive and current:hasSkill(self:objectName()) then
                if player:objectName() ~= current:objectName() and player:objectName() ~= dying.who:objectName() then
                    room:setPlayerFlag(player, "xia_chu")
                    room:addPlayerMark(player, "Global_PreventPeach")
                end
            end
        elseif event == sgs.AfterPreventPeach then
            if player:hasFlag("xia_chu") and player:getMark("Global_PreventPeach") > 0 then
                room:setPlayerFlag(player, "-xia_chu")
                room:removePlayerMark(player, "Global_PreventPeach")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ErikaIkuta:addSkill(sakamichi_xia_chu)

sakamichi_gang_qin_card = sgs.CreateSkillCard {
    name = "sakamichi_gang_qinCard",
    skill_name = "sakamichi_gang_qin",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark("gang_qin_jia_target") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:throwAllHandCards()
        effect.to:turnOver()
        room:drawCards(effect.to, 2, self:getSkillName())
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getMark("gang_qin_jia_target") ~= 0 then
                room:setPlayerMark(p, "gang_qin_jia_target", 0)
            end
        end
        room:setPlayerMark(effect.to, "gang_qin_jia_target", 1)
    end,
}
sakamichi_gang_qin = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_gang_qin",
    view_as = function()
        return sakamichi_gang_qin_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
    end,
}
ErikaIkuta:addSkill(sakamichi_gang_qin)

sakamichi_fen_lan_min_yao_card = sgs.CreateSkillCard {
    name = "sakamichi_fen_lan_min_yaoCard",
    skill_name = "sakamichi_fen_lan_min_yao",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        source:loseMark("@minyao")
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        local players = room:getOtherPlayers(effect.to)
        local distance_list = sgs.IntList()
        local nearest = 1000
        for _, player in sgs.qlist(players) do
            local distance = effect.to:distanceTo(player)
            distance_list:append(distance)
            nearest = math.min(nearest, distance)
        end
        local targets = sgs.SPlayerList()
        local count = distance_list:length()
        for i = 0, count - 1, 1 do
            if (distance_list:at(i) == nearest) and effect.to:canSlash(players:at(i), nil, false) then
                targets:append(players:at(i))
            end
        end
        if targets:length() > 0 then
            if not room:askForUseSlashTo(effect.to, targets, "@fen_lan_min_yao_slash") then
                room:loseHp(effect.to)
            end
        else
            room:loseHp(effect.to)
        end
    end,
}
sakamichi_fen_lan_min_yao = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_fen_lan_min_yao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@minyao",
    view_as = function()
        return sakamichi_fen_lan_min_yao_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@minyao") >= 1
    end,
}
ErikaIkuta:addSkill(sakamichi_fen_lan_min_yao)

sgs.LoadTranslationTable {
    ["ErikaIkuta"] = "生田 絵梨花",
    ["&ErikaIkuta"] = "生田 絵梨花",
    ["#ErikaIkuta"] = "第几次蓝天",
    ["~ErikaIkuta"] = "人はね、限界だと思ってからもうちょっといける。",
    ["designer:ErikaIkuta"] = "Cassimolar",
    ["cv:ErikaIkuta"] = "生田 絵梨花",
    ["illustrator:ErikaIkuta"] = "Cassimolar",
    ["sakamichi_lan_tian"] = "蓝天",
    [":sakamichi_lan_tian"] = "主公技，乃木坂46势力角色结束阶段，若其手牌数为全场最少，你可以令其摸牌至不为最少。",
    ["sakamichi_lan_tian:invoke"] = "是否令%src手牌摸至不为全场最少",
    ["sakamichi_xia_chu"] = "下厨",
    [":sakamichi_xia_chu"] = "锁定技，你的回合内，除你以外，只有处于濒死的角色可以使用【桃】。",
    ["#xia_chu_1"] = "%from 的【%arg】被触发，只能 %from 自救",
    ["#xia_chu_2"] = "%from 的【%arg】被触发，只有 %from 和 %to 才能救 %to",
    ["sakamichi_gang_qin"] = "钢琴",
    ["luagangqingjia"] = "钢琴",
    [":sakamichi_gang_qin"] = "出牌阶段，你可以弃置所有手牌（至少一张）令一名角色翻面并摸两张牌（无法对此技能的上一个目标使用）。",
    ["sakamichi_fen_lan_min_yao"] = "民谣",
    ["@minyao"] = "民谣",
    [":sakamichi_fen_lan_min_yao"] = "限定技，出牌阶段，你可以令所有其他角色各选择一项：对距离最近的另一名角色使用一张【杀】；失去1点体力。",
    ["@fen_lan_min_yao_slash"] = "请使用一张【杀】响应【芬兰民谣】",
}

-- 伊藤 寧々
NeneIto = sgs.General(Sakamichi, "NeneIto", "Nogizaka46", 4, false)
SKMC.IKiSei.NeneIto = true
SKMC.SeiMeiHanDan.NeneIto = {
    name = {6, 18, 14, 3},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {32, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {9, "xiong"},
    sou_kaku = {41, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_za_ji_card = sgs.CreateSkillCard {
    name = "sakamichi_za_jiCard",
    skill_name = "sakamichi_za_ji",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        local phase = sgs.Self:getMark("za_ji_Phase")
        if phase == sgs.Player_Draw then
            if to_select:objectName() ~= sgs.Self:objectName() then
                if not to_select:isKongcheng() then
                    return #targets < 2
                end
            end
        end
        return false
    end,
    feasible = function(self, targets)
        local phase = sgs.Self:getMark("za_ji_Phase")
        if phase == sgs.Player_Draw then
            if #targets > 0 then
                return #targets <= 2
            end
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local phase = source:getMark("za_ji_Phase")
        if phase == sgs.Player_Draw then
            if #targets > 0 then
                for _, p in pairs(targets) do
                    room:cardEffect(self, source, p)
                end
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if not effect.to:isKongcheng() then
            local card_id = room:askForCardChosen(effect.from, effect.to, "h", self:getSkillName())
            room:moveCardTo(sgs.Sanguosha:getCard(card_id), effect.from, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName()))
        end
    end,
}
sakamichi_za_ji_view_as = sgs.CreateViewAsSkill {
    name = "sakamichi_za_ji",
    n = 0,
    view_as = function()
        return sakamichi_za_ji_card:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@sakamichi_za_ji"
    end,
}
sakamichi_za_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_za_ji",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseChanging},
    view_as_skill = sakamichi_za_ji_view_as,
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        local nextphase = change.to
        room:setPlayerMark(player, "za_ji_Phase", nextphase)
        local index = 0
        if nextphase == sgs.Player_Judge then
            index = 1
        elseif nextphase == sgs.Player_Draw then
            index = 2
        elseif nextphase == sgs.Player_Play then
            index = 3
        elseif nextphase == sgs.Player_Discard then
            index = 4
        end
        if index > 0 and not player:isKongcheng() then
            if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "@za_ji_discard_" .. index) then
                if not player:isSkipped(nextphase) then
                    if index == 2 then
                        room:askForUseCard(player, "@sakamichi_za_ji", "@za_ji_" .. index, index)
                    elseif index == 3 then
                        room:moveField(player, self:objectName(), false, "ej")
                    end
                end
                player:skip(nextphase)
            end
        end
        return false
    end,
}
NeneIto:addSkill(sakamichi_za_ji)

sgs.LoadTranslationTable {
    ["NeneIto"] = "伊藤 寧々",
    ["&NeneIto"] = "伊藤 寧々",
    ["#NeneIto"] = "傘妹",
    ["~NeneIto"] = "そっちの伊藤落ちろ！",
    ["designer:NeneIto"] = "Cassimolar",
    ["cv:NeneIto"] = "伊藤 寧々",
    ["illustrator:NeneIto"] = "Cassimolar",
    ["sakamichi_za_ji"] = "杂技",
    [":sakamichi_za_ji"] = "你可以弃置一张手牌，跳过除准备阶段和结束阶段外的一个阶段，若你以此法：跳过摸牌阶段，你可以选择一至两名有手牌的其他角色，获得这些角色的各一张手牌；跳过出牌阶段，你可以将一名角色判定区/装备区里的一张牌置入另一名角色的判定区/装备区。",
    ["@za_ji_2"] = "你可以依次获得一至两名其他角色的各一张手牌",
    ["@za_ji_3"] = "你可以将场上的一张牌移动至另一名角色相应的区域内",
    ["@za_ji_discard_1"] = "你可以弃置 %arg 张手牌跳过判定阶段",
    ["@za_ji_discard_2"] = "你可以弃置 %arg 张手牌跳过摸牌阶段",
    ["@za_ji_discard_3"] = "你可以弃置 %arg 张手牌跳过出牌阶段",
    ["@za_ji_discard_4"] = "你可以弃置 %arg 张手牌跳过弃牌阶段",
    ["~sakamichi_za_ji2"] = "选择 1-2 名其他角色 → 点击确定",
}

-- 桜井 玲香
ReikaSakurai = sgs.General(Sakamichi, "ReikaSakurai", "Nogizaka46", 4, false)
SKMC.IKiSei.ReikaSakurai = true
SKMC.SeiMeiHanDan.ReikaSakurai = {
    name = {10, 4, 9, 9},
    ten_kaku = {14, "xiong"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_yuan_zhen = sgs.CreateTriggerSkill {
    name = "sakamichi_yuan_zhen",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.DamageCaused, sgs.PreHpRecover, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasSkill(self:objectName()) and
                (use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace")) then
                room:setCardFlag(use.card, "yuan_zhen")
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("yuan_zhen") and (damage.card:isKindOf("SavageAssault") or damage.card:isKindOf("ArcheryAttack")) then
                SKMC.send_message(room, "#yuan_zhen_damage", damage.from, damage.to, nil, damage.card:toString(), self:objectName(), damage.damage + 1)
                damage.damage = damage.damage + SKMC.number_correction(damage.from, 1)
                data:setValue(damage)
            end
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.card and recover.card:hasFlag("yuan_zhen") and recover.card:isKindOf("GodSalvation") then
                SKMC.send_message(room, "#yuan_zhen_recover", recover.who, player, nil, recover.card:toString(), self:objectName(), recover.recover + 1)
                recover.recover = recover.recover + SKMC.number_correction(recover.who, 1)
                data:setValue(recover)
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("yuan_zhen") then
                if use.card:isKindOf("AmazingGrace") then
                    for _, p in sgs.qlist(use.to) do
                        if p:isAlive() then
                            room:drawCards(p, 1, self:objectName())
                        end
                    end
                end
                room:setCardFlag(use.card, "-yuan_zhen")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ReikaSakurai:addSkill(sakamichi_yuan_zhen)

sakamichi_dui_zhang = sgs.CreateTriggerSkill {
    name = "sakamichi_dui_zhang",
    events = {sgs.CardUsed},
    priority = {7},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if use.to:length() > 1 and room:askForSkillInvoke(p, self:objectName(), data) then
                    local choice = room:askForKingdom(p)
                    local remove_targets = sgs.SPlayerList()
                    local new_targets = sgs.SPlayerList()
                    for _, pl in sgs.qlist(use.to) do
                        if pl:getKingdom() == choice then
                            remove_targets:append(pl)
                        else
                            new_targets:append(pl)
                        end
                    end
                    if remove_targets:length() > 0 then
                        SKMC.send_message(room, "#dui_zhang_remove", p, nil, remove_targets, use.card:toString(), self:objectName())
                    end
                    if new_targets:length() > 0 then
                        use.to = new_targets
                        data:setValue(use)
                    else
                        return true
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ReikaSakurai:addSkill(sakamichi_dui_zhang)

sgs.LoadTranslationTable {
    ["ReikaSakurai"] = "桜井 玲香",
    ["&ReikaSakurai"] = "桜井 玲香",
    ["#ReikaSakurai"] = "乃团队长",
    ["~ReikaSakurai"] = "My head is popcorn",
    ["designer:ReikaSakurai"] = "Cassimolar",
    ["cv:ReikaSakurai"] = "桜井 玲香",
    ["illustrator:ReikaSakurai"] = "Cassimolar",
    ["sakamichi_yuan_zhen"] = "圆阵",
    [":sakamichi_yuan_zhen"] = "锁定技，你使用的【南蛮入侵】、【万箭齐发】造成的伤害+1；你使用的【桃园结义】回复的体力值+1；你使用的【五谷丰登】结算完成时所有目标摸一张牌。",
    ["#yuan_zhen_damage"] = "%from 的【%arg】触发，%card 对%to 造成的伤害+1，伤害量为 %arg2 点",
    ["#yuan_zhen_recover"] = "%from 的【%arg】触发，%card 对%to 造成的回复+1，回复量为 %arg2 点",
    ["sakamichi_dui_zhang"] = "队长",
    [":sakamichi_dui_zhang"] = "当一名角色使用目标多于一的通常锦囊牌或基本牌时，你可以选择一个势力，从此牌的目标中移除该势力角色。",
    ["#dui_zhang_remove"] = "%from 发动【%arg】，%to 从%card 的目标中移除",
}

-- 伊藤 万理華
MarikaIto = sgs.General(Sakamichi, "MarikaIto", "Nogizaka46", 3, false)
SKMC.IKiSei.MarikaIto = true
SKMC.SeiMeiHanDan.MarikaIto = {
    name = {6, 18, 3, 11, 10},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {48, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "huo",
        GoGyouSanSai = "ji",
    },
}

sakamichi_huan_yi_card = sgs.CreateSkillCard {
    name = "sakamichi_huan_yiCard",
    skill_name = "sakamichi_huan_yi",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return true
        elseif #targets == 1 then
            local n1 = targets[1]:getEquips():length()
            local n2 = to_select:getEquips():length()
            return math.abs(n1 - n2) <= sgs.Self:getHandcardNum() - 1
        else
            return false
        end
    end,
    feasible = function(self, targets)
        if #targets == 0 then
            return true
        end
        if #targets == 2 and (targets[1]:getEquips():length() ~= 0 or targets[2]:getEquips():length() ~= 0) then
            return true
        end
    end,
    on_use = function(self, room, source, targets)
        if #targets == 0 then
            room:moveField(source, self:getSkillName(), false, "ej")
        else
            local equips1, equips2 = sgs.IntList(), sgs.IntList()
            for _, equip in sgs.qlist(targets[1]:getEquips()) do
                equips1:append(equip:getId())
            end
            for _, equip in sgs.qlist(targets[2]:getEquips()) do
                equips2:append(equip:getId())
            end
            local exchangeMove = sgs.CardsMoveList()
            local move1 = sgs.CardsMoveStruct(equips1, targets[2], sgs.Player_PlaceEquip,
                                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, targets[1]:objectName(), targets[2]:objectName(), self:getSkillName(), ""))
            local move2 = sgs.CardsMoveStruct(equips2, targets[1], sgs.Player_PlaceEquip,
                                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, targets[2]:objectName(), targets[1]:objectName(), self:getSkillName(), ""))
            exchangeMove:append(move2)
            exchangeMove:append(move1)
            room:moveCardsAtomic(exchangeMove, false)
            SKMC.send_message(room, "#huan_yi_swap", source, nil, targets, nil, self:getSkillName())
        end
    end,
}
sakamichi_huan_yi = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_huan_yi",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_huan_yi_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "h") and not player:hasUsed("#sakamichi_huan_yiCard")
    end,
}
MarikaIto:addSkill(sakamichi_huan_yi)

sakamichi_shi_shang_card = sgs.CreateSkillCard {
    name = "sakamichi_shi_shangCard",
    skill_name = "sakamichi_shi_shang",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() then
            return to_select:getEquip(sgs.Sanguosha:getCard(self:getEffectiveId()):getRealCard():toEquipCard():location()) == nil
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), self:getSkillName(), "")
        room:moveCardTo(self, effect.from, effect.to, sgs.Player_PlaceEquip, reason)
        SKMC.send_message(room, "#shi_shang_equip", effect.to, nil, nil, self:getSubcards():first():toString())
        room:drawCards(effect.from, 1, self:getSkillName())
        effect.from:gainMark("@dapei")
    end,
}
sakamichi_shi_shang = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_shi_shang",
    filter_pattern = "EquipCard|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_shi_shang_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}
MarikaIto:addSkill(sakamichi_shi_shang)

sakamichi_da_pei = sgs.CreateTriggerSkill {
    name = "sakamichi_da_pei",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_jiu_yi",
    events = {sgs.EventPhaseChanging},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if data:toPhaseChange().to == sgs.Player_Start and player:getMark("@dapei") >= 5 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        local choices = {}
        if player:isWounded() then
            table.insert(choices, "recover")
        end
        table.insert(choices, "draw")
        local choice = room:askForChoice(player, self:objectName(), choices)
        SKMC.choice_log(player, choice)
        if choice == "recover" then
            room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
        else
            room:drawCards(player, 2, self:objectName())
        end
        room:handleAcquireDetachSkills(player, "sakamichi_jiu_yi")
        return false
    end,
}
MarikaIto:addSkill(sakamichi_da_pei)

sakamichi_jiu_yi = sgs.CreateTriggerSkill {
    name = "sakamichi_jiu_yi",
    events = {sgs.BeforeCardsMove},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() ~= player:objectName() then
            if move.to_place == sgs.Player_DiscardPile then
                local card_ids = sgs.IntList()
                local i = 0
                for _, id in sgs.qlist(move.card_ids) do
                    if sgs.Sanguosha:getCard(id):getTypeId() == sgs.Card_TypeEquip and room:getCardOwner(id):objectName() == move.from:objectName() and
                        move.from_places:at(i) == sgs.Player_PlaceEquip then
                        card_ids:append(id)
                    end
                    i = i + 1
                end
                if not card_ids:isEmpty() and player:getMark("@dapei") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:removePlayerMark(player, "@dapei")
                    for _, id in sgs.qlist(card_ids) do
                        if player:isDead() then
                            break
                        end
                        if move.card_ids:contains(id) then
                            move.from_places:removeAt(move.card_ids:indexOf(id))
                            move.card_ids:removeOne(id)
                            data:setValue(move)
                        end
                        room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
                    end
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_jiu_yi") then SKMC.SkillList:append(sakamichi_jiu_yi) end

sgs.LoadTranslationTable {
    ["MarikaIto"] = "伊藤 万理華",
    ["&MarikaIto"] = "伊藤 万理華",
    ["#MarikaIto"] = "小圆脸",
    ["~MarikaIto"] = "アンダーの概念ぶっ壊してやる",
    ["designer:MarikaIto"] = "Cassimolar",
    ["cv:MarikaIto"] = "伊藤 万理華",
    ["illustrator:MarikaIto"] = "Cassimolar",
    ["sakamichi_huan_yi"] = "换衣",
    [":sakamichi_huan_yi"] = "出牌阶段限一次，你可以弃置一张手牌并选择一项：移动场上一张装备牌；令装备区的装备牌数量差不超过你手牌数的两名角色交换他们装备区的装备牌。",
    ["#huan_yi_swap"] = "%from 发动【%arg】交换了 %to 的装备",
    ["sakamichi_shi_shang"] = "时尚",
    [":sakamichi_shi_shang"] = "出牌阶段，你可以将手牌中的一张装备牌置于其他角色的装备区，然后你摸一张牌并获得一枚「搭配」标记。",
    ["#shi_shang_equip"] = "%from 被装备了 %card",
    ["sakamichi_da_pei"] = "搭配",
    [":sakamichi_da_pei"] = "觉醒技，准备阶段，若你拥有至少五枚「搭配」标记，你可以回复1点体力或摸两张牌，然后获得【旧衣】。",
    ["sakamichi_da_pei:recover"] = "回复体力",
    ["sakamichi_da_pei:draw"] = "摸两张牌",
    ["@dapei"] = "搭配",
    ["sakamichi_jiu_yi"] = "旧衣",
    [":sakamichi_jiu_yi"] = "其他角色装备区的装备牌以未经转化的方式置入弃牌堆时，你可以移除一枚「搭配」获得之。",
    ["@jiu_yi_discard"] = "你需要弃置一张装备区的牌",
}

-- 井上 小百合
SayuriInoue = sgs.General(Sakamichi, "SayuriInoue", "Nogizaka46", 4, false, false, false, 3)
SKMC.IKiSei.SayuriInoue = true
SKMC.SeiMeiHanDan.SayuriInoue = {
    name = {4, 3, 3, 6, 6},
    ten_kaku = {7, "ji"},
    jin_kaku = {6, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {22, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_man_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_man_shi",
    frequency = sgs.Skill_Wake,
    events = {sgs.MarkChanged},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if event == sgs.MarkChanged then
            local mark = data:toMark()
            if mark.name == "man_shi_recover" and player:getMark("man_shi_recover") >= SKMC.number_correction(player, 3) then
                return true
            end
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        room:drawCards(player, 2, self:objectName())
        room:setPlayerMark(player, "man_shi_recover", 0)
        return false
    end,
}
sakamichi_man_shi_record = sgs.CreateTriggerSkill {
    name = "#sakamichi_man_shi_record",
    events = {sgs.CardFinished, sgs.HpRecover, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Peach") then
                local ids = sgs.IntList()
                if use.card:isVirtualCard() then
                    ids = use.card:getSubcards()
                else
                    ids:append(use.card:getEffectiveId())
                end
                if not ids:isEmpty() then
                    local in_discard = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                            in_discard = false
                            break
                        end
                    end
                    if in_discard then
                        if player:hasSkill("sakamichi_man_shi") and player:getMark("man_shi_used") == 0 then
                            if player:getMark("sakamichi_man_shi") ~= 0 then
                                if room:askForSkillInvoke(player, "sakamichi_man_shi", data) then
                                    room:obtainCard(player, use.card, true)
                                    room:setPlayerMark(player, "man_shi_used", 1)
                                end
                            elseif player:getPhase() == sgs.Player_Play then
                                if room:askForSkillInvoke(player, "sakamichi_man_shi", data) then
                                    room:obtainCard(player, use.card, true)
                                    room:setPlayerMark(player, "man_shi_used", 1)
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:hasSkill("sakamichi_man_shi") and recover.who:getMark("sakamichi_man_shi") == 0 then
                room:addPlayerMark(recover.who, "man_shi_recover", recover.recover)
            end
        elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "man_shi_used", 0)
                room:setPlayerMark(p, "man_shi_recover", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_man_shi_record", "#sakamichi_man_shi_record")
SayuriInoue:addSkill(sakamichi_man_shi)
SayuriInoue:addSkill(sakamichi_man_shi_record)

sakamichi_chu_jin = sgs.CreateTriggerSkill {
    name = "sakamichi_chu_jin",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
            room:addMaxCards(player, SKMC.number_correction(player, move.card_ids:length()), true)
            SKMC.send_message(room, "#chu_jin_max", player, nil, nil, nil, self:objectName(), player:getMaxCards())
        end
        if move.from and move.to and move.from:objectName() == player:objectName() and move.from:objectName() ~= move.to:objectName() and
            (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:damage(sgs.DamageStruct(self:objectName(), player, room:findPlayerByObjectName(move.to:objectName()), SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
SayuriInoue:addSkill(sakamichi_chu_jin)

sakamichi_fei_ren_card = sgs.CreateSkillCard {
    name = "sakamichi_fei_renCard",
    skill_name = "sakamichi_fei_ren",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targtes)
        source:loseMark("@feiren")
        local x = source:getHp()
        room:loseHp(source, x)
        if source:isAlive() then
            room:drawCards(source, x + SKMC.number_correction(source, 1), self:getSkillName())
            room:setPlayerFlag(source, "fei_ren")
        end
    end,
}
sakamichi_fei_ren_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_fei_ren",
    view_as = function(self)
        return sakamichi_fei_ren_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@feiren") ~= 0
    end,
}
sakamichi_fei_ren = sgs.CreateTriggerSkill {
    name = "sakamichi_fei_ren",
    frequency = sgs.Skill_Limited,
    limit_mark = "@feiren",
    view_as_skill = sakamichi_fei_ren_view_as,
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and player:hasFlag("fei_ren") then
                room:setCardFlag(damage.card, "fei_ren")
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("fei_ren") and use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
            end
        end
    end,
}
sakamichi_fei_ren_Mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_fei_ren_Mod",
    pattern = ".",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_fei_ren") and from:hasFlag("fei_ren") then
            return 1000
        else
            return 0
        end
    end,
}
SayuriInoue:addSkill(sakamichi_fei_ren)
if not sgs.Sanguosha:getSkill("#sakamichi_fei_ren_Mod") then SKMC.SkillList:append(sakamichi_fei_ren_Mod) end

sgs.LoadTranslationTable {
    ["SayuriInoue"] = "井上 小百合",
    ["&SayuriInoue"] = "井上 小百合",
    ["#SayuriInoue"] = "百合连者",
    ["~SayuriInoue"] = "この曲売れなかったら世間がおかしいと思う",
    ["designer:SayuriInoue"] = "Cassimolar",
    ["cv:SayuriInoue"] = "井上 小百合",
    ["illustrator:SayuriInoue"] = "Cassimolar",
    ["sakamichi_man_shi"] = "慢食",
    [":sakamichi_man_shi"] = "出牌阶段限一次，你使用的【桃】结算完成时，你可以获得之；觉醒技，当你于一回合内造成了至少3点回复，你摸两张牌并将本技能修改为每回合限一次。",
    ["sakamichi_chu_jin"] = "储金",
    [":sakamichi_chu_jin"] = "你的回合内，你每获得一张手牌本回合你的手牌上限+1。其他角色获得你的牌后，你可以对其造成1点伤害。",
    ["#chu_jin_max"] = "%from 发动了【%arg】，本回合内%from 的手牌上限为 %arg2 张",
    ["sakamichi_fei_ren"] = "飞人",
    [":sakamichi_fei_ren"] = "限定技，出牌阶段，你可以失去X点体力然后摸X+1张牌（X为你当前的体力值），本回合内你使用牌无距离限制、你使用的【杀】造成伤害后不计入使用次数限制。",
    ["@feiren"] = "飞人",
}

-- 衛藤 美彩
MisaEto = sgs.General(Sakamichi, "MisaEto", "Nogizaka46", 4, false)
SKMC.IKiSei.MisaEto = true
SKMC.SeiMeiHanDan.MisaEto = {
    name = {16, 18, 9, 11},
    ten_kaku = {34, "xiong"},
    jin_kaku = {27, "ji_xiong_hun_he"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {54, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_jiu_xian_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jiu_xian",
    response_pattern = "analeptic",
    filter_pattern = ".|black|.|hand",
    view_as = function(self, card)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
        analeptic:setSkillName(self:objectName())
        analeptic:addSubcard(card)
        return analeptic
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
        card:deleteLater()
        if player:isCardLimited(card, sgs.Card_MethodUse) or player:isProhibited(player, card) then
            return false
        end
        return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, card)
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "analeptic")
    end,
}
sakamichi_jiu_xian = sgs.CreateTriggerSkill {
    name = "sakamichi_jiu_xian",
    view_as_skill = sakamichi_jiu_xian_view_as,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Analeptic") and use.card:getSkillName() == self:objectName() then
            if use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
            end
        end
    end,
}
sakamichi_jiu_xian_Mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_jiu_xian_Mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Analeptic",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_jiu_xian") then
            return 1000
        else
            return 0
        end
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_jiu_xian", "#sakamichi_jiu_xian_Mod")
MisaEto:addSkill(sakamichi_jiu_xian)
MisaEto:addSkill(sakamichi_jiu_xian_Mod)

sakamichi_guan_jiu = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_jiu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Slash") and not use.card:hasFlag("drank") and use.from:hasSkill(self:objectName()) then
                SKMC.send_message(room, "#guan_jiu_from", player, nil, nil, use.card:toString(), self:objectName())
                room:setCardFlag(use.card, "drank")
                use.card:setTag("drank", sgs.QVariant(use.card:getTag("drank"):toInt() + 1))
                return false
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and not damage.card:hasFlag("drank") then
                SKMC.send_message(room, "#guan_jiu_to", damage.from, nil, nil, damage.card:toString(), self:objectName())
                damage.damage = damage.damage + 1
                data:setValue(damage)
                return false
            end
        end
    end,
}
MisaEto:addSkill(sakamichi_guan_jiu)

sgs.LoadTranslationTable {
    ["MisaEto"] = "衛藤 美彩",
    ["&MisaEto"] = "衛藤 美彩",
    ["#MisaEto"] = "酒仙",
    ["~MisaEto"] = "チン 、ゲン 、サイ！♡",
    ["designer:MisaEto"] = "Cassimolar",
    ["cv:MisaEto"] = "衛藤 美彩",
    ["illustrator:MisaEto"] = "Cassimolar",
    ["sakamichi_jiu_xian"] = "酒仙",
    [":sakamichi_jiu_xian"] = "你可以将黑色手牌当【酒】使用或打出，你使用【酒】无次数限制。",
    ["~sakamichi_jiu_xian"] = "选择一张黑色手牌 → 点击确定",
    ["sakamichi_guan_jiu"] = "灌酒",
    [":sakamichi_guan_jiu"] = "锁定技，你使用的【杀】将额外附加一张【酒】，当你受到【杀】造成的伤害时，若此【杀】不为【酒】【杀】则此伤害+1。",
    ["#guan_jiu_from"] = "%from 的【%arg】被触发，此【%card】被视为【<font color=\"yellow\"><b>酒</b></font>】【<font color=\"yellow\"><b>杀</b></font>】。",
    ["#guan_jiu_to"] = "%to 的【%arg】被触发，%from 的此张【%card】对 %to 造成的伤害增加<font color=\"yellow\"><b>1</b></font>点。",
}

-- 宮澤 成良
SeiraMiyazawa = sgs.General(Sakamichi, "SeiraMiyazawa", "Nogizaka46", 3, false)
SKMC.IKiSei.SeiraMiyazawa = true
SKMC.SeiMeiHanDan.SeiraMiyazawa = {
    name = {10, 16, 6, 7},
    ten_kaku = {26, "xiong"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_hun_xue = sgs.CreateTriggerSkill {
    name = "sakamichi_hun_xue",
    events = {sgs.PindianVerifying, sgs.Pindian},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() and player:getKingdom() ~= pindian.to:getKingdom() then
                if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "@hun_xue_invoke") then
                    local choice = room:askForChoice(player, self:objectName(), "up+down", data)
                    SKMC.choice_log(player, choice)
                    if choice == "up" then
                        pindian.from_number = math.min(pindian.from_number + SKMC.number_correction(player, 5), 13)
                    elseif choice == "down" then
                        pindian.from_number = math.max(pindian.from_number - SKMC.number_correction(player, 5), 1)
                    end
                    SKMC.send_message(room, "#hun_xue" .. choice, player, nil, nil, nil, self:objectName(), pindian.from_number)
                end
            end
            if pindian.to:objectName() == player:objectName() and player:getKingdom() ~= pindian.from:getKingdom() then
                if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "@hun_xue_invoke") then
                    local choice = room:askForChoice(player, self:objectName(), "up+down", data)
                    SKMC.choice_log(player, choice)
                    if choice == "up" then
                        pindian.to_number = math.min(pindian.to_number + SKMC.number_correction(player, 5), 13)
                    elseif choice == "down" then
                        pindian.to_number = math.max(pindian.to_number - SKMC.number_correction(player, 5), 1)
                    end
                    SKMC.send_message(room, "#hun_xue_" .. choice, player, nil, nil, nil, self:objectName(), pindian.to_number)
                end
            end
        else
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() then
                if pindian.from_number <= pindian.to_number then
                    room:drawCards(player, 1, self:objectName())
                end
            end
            if pindian.to:objectName() == player:objectName() then
                if pindian.from_number >= pindian.to_number then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
SeiraMiyazawa:addSkill(sakamichi_hun_xue)

sakamichi_ba_lei_card = sgs.CreateSkillCard {
    name = "sakamichi_ba_leiCard",
    skill_name = "sakamichi_ba_lei",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return sgs.Self:objectName() ~= to_select:objectName() and sgs.Self:canPindian(to_select)
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local success = effect.from:pindian(effect.to, self:getSkillName(), self)
        local data = sgs.QVariant()
        data:setValue(effect.to)
        while success do
            if effect.to:isKongcheng() then
                break
            elseif effect.from:isKongcheng() then
                break
            elseif room:askForSkillInvoke(effect.from, self:getSkillName(), data) then
                success = effect.from:pindian(effect.to, self:getSkillName())
            else
                break
            end
        end
        if not success then
            room:loseHp(effect.from)
        end
    end,
}
sakamichi_ba_lei_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_ba_lei",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_ba_lei_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_ba_lei") and not player:isKongcheng()
    end,
}
sakamichi_ba_lei = sgs.CreateTriggerSkill {
    name = "sakamichi_ba_lei",
    events = {sgs.EventPhaseChanging, sgs.Pindian},
    view_as_skill = sakamichi_ba_lei_view_as,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Start and not player:isWounded() and not player:isKongcheng() then
                room:askForUseCard(player, "@@sakamichi_ba_lei", "@ba_lei_invoke")
            end
        else
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
                    room:obtainCard(player, pindian.to_card)
                end
            end
        end
        return false
    end,
}
SeiraMiyazawa:addSkill(sakamichi_ba_lei)

sakamichi_zu_qiu_card = sgs.CreateSkillCard {
    name = "sakamichi_zu_qiuCard",
    skill_name = "sakamichi_zu_qiu",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets == 0 then
            if not to_select:isKongcheng() then
                return to_select:getKingdom() ~= sgs.Self:getKingdom() and sgs.Self:canPindian(to_select)
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        effect.from:pindian(effect.to, self:getSkillName(), self)
    end,
}
sakamichi_zu_qiu_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_zu_qiu",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_zu_qiu_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_zu_qiuCard") and not player:isKongcheng() and SKMC.has_specific_kingdom_player(player, false)
    end,
}
sakamichi_zu_qiu = sgs.CreateTriggerSkill {
    name = "sakamichi_zu_qiu",
    view_as_skill = sakamichi_zu_qiu_view_as,
    events = {sgs.Pindian},
    on_trigger = function(self, event, player, data, room)
        local pindian = data:toPindian()
        if pindian.from:objectName() == player:objectName() and pindian.reason == self:objectName() then
            if pindian.from_number > pindian.to_number then
                room:obtainCard(pindian.from, pindian.from_card)
                room:obtainCard(pindian.from, pindian.to_card)
            else
                if pindian.from_number < pindian.to_number then
                    room:obtainCard(pindian.to, pindian.from_card)
                    room:obtainCard(pindian.to, pindian.to_card)
                end
            end
            return false
        end
    end,
}
SeiraMiyazawa:addSkill(sakamichi_zu_qiu)

sgs.LoadTranslationTable {
    ["SeiraMiyazawa"] = "宮澤 成良",
    ["&SeiraMiyazawa"] = "宮澤 成良",
    ["#SeiraMiyazawa"] = "日法混血",
    ["~SeiraMiyazawa"] = "",
    ["designer:SeiraMiyazawa"] = "Cassimolar",
    ["cv:SeiraMiyazawa"] = "宮澤 成良",
    ["illustrator:SeiraMiyazawa"] = "Cassimolar",
    ["sakamichi_hun_xue"] = "混血",
    [":sakamichi_hun_xue"] = "当你拼点牌亮出时，若目标的势力与你不同，你可以弃置一张手牌来令你此次拼点牌点数+5或-5。当你拼点没赢时，你可以摸一张牌。",
    ["@hun_xue_invoke"] = "你可以弃置一张手牌来使此次拼点点数+5或-5",
    ["sakamichi_hun_xue:up"] = "令你此次拼点点数加5",
    ["sakamichi_hun_xue:down"] = "令你此次拼点点数减5",
    ["#hun_xue_up"] = "%from 发动【%arg】使其此次拼点点数<font color=\"yellow\"><b>+5</b></font>，此次拼点点数为 %arg2",
    ["#hun_xue_down"] = "%from 发动【%arg】使其此次拼点点数<font color=\"yellow\"><b>-5</b></font>，此次拼点点数为 %arg2",
    ["sakamichi_ba_lei"] = "芭蕾",
    [":sakamichi_ba_lei"] = "准备阶段，若你未受伤，你可以拼点：若你赢，你可以获得对方的拼点牌，并可以立即再次与其拼点，你可以重复此流程直到你没赢或不愿意继续拼点为止；若你没赢，你失去1点体力。",
    ["@ba_lei_invoke"] = "你可以发动【芭蕾】与一名其他角色拼点",
    ["~sakamichi_ba_lei"] = "选择一张手牌 → 选择一名其他角色 → 点击确定",
    ["sakamichi_zu_qiu"] = "足球",
    [":sakamichi_zu_qiu"] = "出牌阶段限一次，你可以与一名势力与你不同的角色拼点，赢的一方获得双方的拼点牌。",
}

-- 秋元 真夏
ManatsuAkimoto = sgs.General(Sakamichi, "ManatsuAkimoto", "Nogizaka46", 3, false)
SKMC.IKiSei.ManatsuAkimoto = true
SKMC.SeiMeiHanDan.ManatsuAkimoto = {
    name = {9, 4, 10, 10},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zi_q_card = sgs.CreateSkillCard {
    name = "sakamichi_zi_q_Card",
    skill_name = "sakamichi_zi_q",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark("zi_q_illegal_target") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self)
        local result = SKMC.run_judge(room, effect.to, self:getSkillName(), ".")
        local suit = result.card:getSuitString()
        SKMC.send_message(room, "#zi_q_" .. suit, effect.to, nil, nil, nil, self:getSkillName())
        if suit == "spade" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            room:setPlayerFlag(effect.from, "zi_q" .. effect.to:objectName())
            room:addPlayerMark(effect.to, "@skill_invalidity")
        elseif suit == "heart" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            if effect.to:isWounded() then
                room:recover(effect.to, sgs.RecoverStruct(effect.from, self, 1))
            end
            effect.to:turnOver()
            room:setPlayerMark(effect.to, "zi_q_illegal_target", 1)
        elseif suit == "club" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            room:setPlayerFlag(effect.from, "zi_q_armor" .. effect.to:objectName())
            room:addPlayerMark(effect.to, "Armor_Nullified")
        elseif suit == "diamond" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            room:drawCards(effect.to, 4, self:getSkillName())
            if effect.to:getHandcardNum() + effect.to:getEquips():length() <= 2 then
                effect.to:throwAllHandCardsAndEquips()
            else
                room:askForDiscard(effect.to, self:getSkillName(), 2, 2, false, true)
            end
        end
    end,
}
sakamichi_zi_q_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_zi_q",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_zi_q_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        local have_legal_target = false
        for _, p in sgs.qlist(player:getSiblings()) do
            if p:getMark("zi_q_illegal_target") == 0 then
                have_legal_target = true
                break
            end
        end
        return have_legal_target and not player:hasFlag("zi_q_used")
    end,
}
sakamichi_zi_q = sgs.CreateTriggerSkill {
    name = "sakamichi_zi_q",
    events = {sgs.EventPhaseChanging},
    view_as_skill = sakamichi_zi_q_view_as,
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:hasFlag("zi_q" .. p:objectName()) then
                    room:removePlayerMark(p, "@skill_invalidity")
                    room:setPlayerFlag(player, "-zi_q" .. p:objectName())
                end
                if player:hasFlag("zi_q_armor" .. p:objectName()) then
                    room:removePlayerMark(p, "Armor_Nullified")
                    room:setPlayerFlag(player, "-zi_q_armor" .. p:objectName())
                end
            end
        end
        return false
    end,
}
ManatsuAkimoto:addSkill(sakamichi_zi_q)

sakamichi_xiao_ju_chang = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_ju_chang",
    events = {sgs.EventPhaseChanging, sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and room:askForSkillInvoke(player, self:objectName(), data) then
                player:turnOver()
            end
        else
            local use = data:toCardUse()
            if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and not player:faceUp() then
                SKMC.send_message(room, "#xiao_ju_chang_avoid", player, nil, nil, use.card:toString(), self:objectName())
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
}
ManatsuAkimoto:addSkill(sakamichi_xiao_ju_chang)

sakamichi_mo_yin_card = sgs.CreateSkillCard {
    name = "sakamichi_mo_yinCard",
    skill_name = "sakamichi_mo_yin",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        source:loseMark("@moyin")
        room:addPlayerMark(source, "mo_yin_used")
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        effect.to:turnOver()
    end,
}
sakamichi_mo_yin_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_mo_yin",
    view_as = function(self)
        return sakamichi_mo_yin_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@moyin") ~= 0
    end,
}
sakamichi_mo_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_mo_yin",
    frequency = sgs.Skill_Limited,
    limit_mark = "@moyin",
    view_as_skill = sakamichi_mo_yin_view_as,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start then
            if player:getMark("mo_yin_used") ~= 0 then
                room:setPlayerMark(player, "mo_yin_used", 0)
                player:turnOver()
            end
        end
        return false
    end,
}
ManatsuAkimoto:addSkill(sakamichi_mo_yin)

sgs.LoadTranslationTable {
    ["ManatsuAkimoto"] = "秋元 真夏",
    ["&ManatsuAkimoto"] = "秋元 真夏",
    ["#ManatsuAkimoto"] = "好玩不过",
    ["~ManatsuAkimoto"] = "雀の子 そこのけそこのけ 山椒の毛",
    ["designer:ManatsuAkimoto"] = "Cassimolar",
    ["cv:ManatsuAkimoto"] = "秋元 真夏",
    ["illustrator:ManatsuAkimoto"] = "Cassimolar",
    ["sakamichi_zi_q"] = "子Q",
    [":sakamichi_zi_q"] = "出牌阶段限一次，你可以将一张手牌交给一名未以此法翻面的其他角色令其进行判定，若判定结果为：黑桃，本回合内其非锁定技失效；红桃，其回复1点体力值并翻面，且此技能对其他角色视为未发动过；梅花，本回合内其防具失效；方块，其摸四张牌然后弃置两张牌。",
    ["#zi_q_spade"] = "本回合内%from 非锁定技失效",
    ["#zi_q_heart"] = "%from 回复1点体力并将武将牌翻面",
    ["#zi_q_club"] = "本回合内%from 防具无效",
    ["#zi_q_diamond"] = "%from 摸四张牌然后弃置两张牌",
    ["sakamichi_xiao_ju_chang"] = "小剧场",
    ["#xiao_ju_chang_avoid"] = "%from 的【%arg】被触发，%card对其无效",
    [":sakamichi_xiao_ju_chang"] = "结束阶段，你可以将翻面。你武将牌背面向上时，【杀】和通常锦囊牌对你无效。",
    ["sakamichi_mo_yin"] = "魔音",
    [":sakamichi_mo_yin"] = "限定技，出牌阶段，你可以令所有其他角色翻面，若如此做，你的下个准备阶段，你翻面。",
}

-- 高山 一実
KazumiTakayama = sgs.General(Sakamichi, "KazumiTakayama", "Nogizaka46", 3, false)
SKMC.IKiSei.KazumiTakayama = true
SKMC.SeiMeiHanDan.KazumiTakayama = {
    name = {10, 3, 1, 8},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {4, "xiong"},
    ji_kaku = {9, "xiong"},
    soto_kaku = {18, "ji"},
    sou_kaku = {22, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_jiao_zhu = sgs.CreateTriggerSkill {
    name = "sakamichi_jiao_zhu",
    events = {sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local result = SKMC.run_judge(room, player, self:objectName(), ".|spade,club")
                if result.card:getSuit() == sgs.Card_Spade then
                    room:drawCards(p, 1, self:objectName())
                elseif result.card:getSuit() == sgs.Card_Club then
                    if p:isWounded() then
                        room:recover(p, sgs.RecoverStruct(player, nil, SKMC.number_correction(p, 1)))
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KazumiTakayama:addSkill(sakamichi_jiao_zhu)

sakamichi_gai_ming_kazumi = sgs.CreateTriggerSkill {
    name = "sakamichi_gai_ming_kazumi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@gaimingkazumi",
    events = {sgs.AskForRetrial, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AskForRetrial then
            local judge = data:toJudge()
            local can_invoke = false
            if player:hasSkill(self:objectName()) then
                if player:isKongcheng() then
                    for _, equip in sgs.qlist(player:getEquips()) do
                        if equip:isBlack() then
                            can_invoke = true
                            break
                        end
                    end
                else
                    can_invoke = true
                end
                if can_invoke then
                    local card = room:askForCard(player, ".|black", "@gai_ming_kazumi_card:" .. judge.who:objectName() .. "::" ..judge.reason .. ":" .. judge.card:objectName(),
                                                    data, sgs.Card_MethodResponse, judge.who, true)
                    if card then
                        room:retrial(card, player, judge, self:objectName(), true)
                    end
                end
            end
        else
            local dying = data:toDying()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("@gaimingkazumi") ~= 0 and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("to:" .. dying.who:objectName() .. "::" .. self:objectName())) then
                    p:loseMark("@gaimingkazumi")
                    local result = SKMC.run_judge(room, dying.who, self:objectName(), ".|black", false)
                    if result.isGood == true then
                        room:recover(dying.who, sgs.RecoverStruct(p, nil, SKMC.number_correction(p, 1)))
                        local general_names = sgs.Sanguosha:getLimitedGeneralNames()
                        if (SKMC.is_normal_game_mode(room:getMode()) or room:getMode():find("_mini_") or room:getMode() == "custom_scenario") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/Roles", ""):split(", "))
                        elseif (room:getMode() == "04_1v3") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/HulaoPass", ""):split(", "))
                        elseif (room:getMode() == "06_XMode") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/XMode", ""):split(", "))
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                table.removeTable(general_names, (p:getTag("XModeBackup"):toStringList()) or {})
                            end
                        elseif (room:getMode() == "02_1v1") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/1v1", ""):split(", "))
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                table.removeTable(general_names, (p:getTag("1v1Arrange"):toStringList()) or {})
                            end
                        end
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            local name = p:getGeneralName()
                            if sgs.Sanguosha:isGeneralHidden(name) then
                                local fname = sgs.Sanguosha:findConvertFrom(name);
                                if fname ~= "" then
                                    name = fname
                                end
                            end
                            table.removeOne(general_names, name)
                            if p:getGeneral2() then
                                name = p:getGeneral2Name()
                            end
                            if sgs.Sanguosha:isGeneralHidden(name) then
                                local fname = sgs.Sanguosha:findConvertFrom(name);
                                if fname ~= "" then
                                    name = fname
                                end
                            end
                            table.removeOne(general_names, name)
                        end
                        local gai_ming_generals = {}
                        for _, name in ipairs(general_names) do
                            local general = sgs.Sanguosha:getGeneral(name)
                            if general:getKingdom() == dying.who:getKingdom() then
                                table.insert(gai_ming_generals, name)
                            end
                        end
                        local x = math.min(3, #gai_ming_generals)
                        local random = {}
                        repeat
                            local rand = math.random(1, #gai_ming_generals)
                            if not table.contains(random, gai_ming_generals[rand]) then
                                table.insert(random, (gai_ming_generals[rand]))
                            end
                        until #random == x
                        local general = room:askForGeneral(p, table.concat(random, "+"))
                        room:changeHero(dying.who, general, false)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KazumiTakayama:addSkill(sakamichi_gai_ming_kazumi)

sgs.LoadTranslationTable {
    ["KazumiTakayama"] = "高山 一実",
    ["&KazumiTakayama"] = "高山 一実",
    ["#KazumiTakayama"] = "肘哥",
    ["~KazumiTakayama"] = "Amazing!",
    ["designer:KazumiTakayama"] = "Cassimolar",
    ["cv:KazumiTakayama"] = "高山 一実",
    ["illustrator:KazumiTakayama"] = "Cassimolar",
    ["sakamichi_jiao_zhu"] = "教主",
    [":sakamichi_jiao_zhu"] = "一名角色造成/受到伤害后，其可以进行判定，若结果为：黑桃，你回复1点体力；梅花，你摸一张牌。",
    ["sakamichi_gai_ming_kazumi"] = "改名",
    [":sakamichi_gai_ming_kazumi"] = "一名角色的判定牌生效前，你可以打出一张黑色牌替换之。限定技，一名角色进入濒死时，你可以令其进行判定，若结果不为黑色，其回复1点体力并从随机三个未上场的同势力武将中选择一个替换其武将牌。",
    ["@gaimingkazumi"] = "改名",
    ["@gai_ming_kazumiCard"] = "你可以打出一张黑色牌来替换 %src 的 %arg 的判定牌 %arg2",
    ["sakamichi_gai_ming_kazumi:to"] = "%src 进入濒死，是否发动%arg",
}

-- 斉藤 優里
YuriSaito = sgs.General(Sakamichi, "YuriSaito", "Nogizaka46", 4, false)
SKMC.IKiSei.YuriSaito = true
SKMC.SeiMeiHanDan.YuriSaito = {
    name = {8, 18, 17, 7},
    ten_kaku = {26, "xiong"},
    jin_kaku = {35, "ji"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {50, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_kao_mo = sgs.CreateTriggerSkill {
    name = "sakamichi_kao_mo",
    events = {sgs.Damaged, sgs.EventPhaseStart, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:getPhase() ~= sgs.Player_NotActive then
                room:setPlayerMark(damage.to, "kao_mo_target", 1)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            local kao_mo_targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("kao_mo_target") > 0 then
                    kao_mo_targets:append(p)
                end
            end
            if kao_mo_targets:length() > 0 then
                local kaomoFrom = room:findPlayersBySkillName(self:objectName())
                for _, p in sgs.qlist(kaomoFrom) do
                    if not p:isNude() then
                        local targets_list = sgs.SPlayerList()
                        for _, target in sgs.qlist(kao_mo_targets) do
                            if p:canSlash(target, nil, false) then
                                targets_list:append(target)
                            end
                        end
                        if not targets_list:isEmpty() then
                            if p:askForSkillInvoke(self:objectName(), data) then
                                room:askForUseSlashTo(p, targets_list, "@kao_mo_slash", false, false)
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    room:setPlayerMark(p, "kao_mo_target", 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuriSaito:addSkill(sakamichi_kao_mo)

AutisticGroup_di = sgs.CreateTriggerSkill {
    name = "AutisticGroup_di",
    events = {sgs.Damage, sgs.Damaged, sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            room:addPlayerMark(player, damage.to:objectName() .. "qun_di_minus_finish_end_clear", SKMC.number_correction(player, 1))
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from then
                room:addPlayerMark(damage.from, player:objectName() .. "qun_di_plus_finish_end_clear", SKMC.number_correction(player, 1))
            end
        elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:distanceTo(p) == SKMC.number_correction(player, 1) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
AutisticGroup_di_distance = sgs.CreateDistanceSkill {
    name = "#AutisticGroup_di_distance",
    correct_func = function(self, from, to)
        return  0 - from:getMark(to:objectName() .. "qun_di_minus_finish_end_clear") + from:getMark(to:objectName() .. "qun_di_plus_finish_end_clear")
    end,
}
YuriSaito:addSkill(AutisticGroup_di)
if not sgs.Sanguosha:getSkill("#AutisticGroup_di_distance") then SKMC.SkillList:append(AutisticGroup_di_distance) end

sgs.LoadTranslationTable {
    ["YuriSaito"] = "斉藤 優里",
    ["&YuriSaito"] = "斉藤 優里",
    ["#YuriSaito"] = "啃肩噬臀",
    ["~YuriSaito"] = "私 好きですか？",
    ["designer:YuriSaito"] = "Cassimolar",
    ["cv:YuriSaito"] = "斉藤 優里",
    ["illustrator:YuriSaito"] = "Cassimolar",
    ["sakamichi_kao_mo"] = "尻魔",
    [":sakamichi_kao_mo"] = "每回合结束时，若当前回合角色对至少另一名其他角色造成过伤害，你可以对其中一名角色使用一张【杀】。",
    ["@kao_mo_slash"] = "你可以对一名角色使用一张杀",
    ["AutisticGroup_di"] = "裙底",
    [":AutisticGroup_di"] = "你对其他角色造成伤害后，本回合内你计算与其的距离-1；你受到其他角色造成的伤害后，本回合内其计算与你的距离+1。结束阶段，每有一名你与其距离为1的角色，你摸一张牌。",
}

-- 白石 麻衣
MaiShiraishi = sgs.General(Sakamichi, "MaiShiraishi$", "Nogizaka46", 4, false)
SKMC.IKiSei.MaiShiraishi = true
SKMC.SeiMeiHanDan.MaiShiraishi = {
    name = {5, 5, 11, 6},
    ten_kaku = {10, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {27, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_gong_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_gong_shi$",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and not use.card:isKindOf("SkillCard") and player:getKingdom() == "Nogizaka46" and player:getPhase() == sgs.Player_Play and not player:hasFlag("gong_shi_used") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self:objectName()) and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. p:objectName() .. "::" .. self:objectName())) then
                    room:setPlayerFlag(player, "gong_shi_used")
                    local pattern
                    if use.card:isKindOf("BasicCard") then
                        pattern = "BasicCard"
                    elseif use.card:isKindOf("TrickCard") then
                        pattern = "TrickCard"
                    elseif use.card:isKindOf("EquipCard") then
                        pattern = "EquipCard"
                    end
                    local judge = SKMC.run_judge(room, player, self:objectName(), pattern)
                    if judge.isGood then
                        room:drawCards(player, 1, self:objectName())
                        room:drawCards(p, 1, self:objectName())
                    end
                    break
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiShiraishi:addSkill(sakamichi_gong_shi)

sakamichi_nv_shen = sgs.CreateTriggerSkill {
    name = "sakamichi_nv_shen",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TurnOver, sgs.ChainStateChange},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnOver and player:faceUp() then
            if player:hasSkill(self:objectName()) then
                SKMC.send_message(room, "#nv_shen_turn_over", player, player, nil, nil, self:objectName())
                room:setEmotion(player, "skill_nullify")
                return true
            else
                local list = room:findPlayersBySkillName(self:objectName())
                for _, p in sgs.qlist(list) do
                    if not p:isNude() then
                        local has_red = false
                        for _, card in sgs.qlist(p:getCards("he")) do
                            if card:isRed() then
                                has_red = true
                                break
                            end
                        end
                        if p:canDiscard(p, "he") and has_red then
                            if p:askForSkillInvoke(self:objectName(), data) then
                                room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@nv_shen_discard", ".|red")
                                SKMC.send_message(room, "#nv_shen_turn_over", p, player, nil, nil, self:objectName())
                                room:setEmotion(player, "skill_nullify")
                                return true
                            end
                        end
                    end
                end
            end
        elseif event == sgs.ChainStateChange and (not player:isChained()) then
            if player:hasSkill(self:objectName()) then
                SKMC.send_message(room, "#nv_shen_chain_state_change", player, player, nil, nil, self:objectName())
                room:setEmotion(player, "skill_nullify")
                return true
            else
                local list = room:findPlayersBySkillName(self:objectName())
                for _, p in sgs.qlist(list) do
                    if not p:isNude() then
                        local has_red = false
                        for _, card in sgs.qlist(p:getCards("he")) do
                            if card:isRed() then
                                has_red = true
                                break
                            end
                        end
                        if p:canDiscard(p, "he") and has_red then
                            if p:askForSkillInvoke(self:objectName(), data) then
                                room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@nv_shen_discard", ".|red")
                                SKMC.send_message(room, "#nv_shen_chain_state_change", p, player, nil, nil, self:objectName())
                                room:setEmotion(player, "skill_nullify")
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_nv_shen_protect = sgs.CreateProhibitSkill {
    name = "#sakamichi_nv_shen_protect",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_nv_shen") and (card:isKindOf("SupplyShortage") or card:isKindOf("Indulgence"))
    end,
}
MaiShiraishi:addSkill(sakamichi_nv_shen)
if not sgs.Sanguosha:getSkill("#sakamichi_nv_shen_protect") then SKMC.SkillList:append(sakamichi_nv_shen_protect) end

sakamichi_hei_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_hei_shi",
    events = {sgs.PreHpRecover},
    on_trigger = function(self, event, player, data, room)
        local recover = data:toRecover()
        if recover.who and recover.who:objectName() ~= player:objectName() and recover.who:hasSkill(self:objectName())
            and room:askForSkillInvoke(recover.who, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName())) then
            local choice = room:askForChoice(recover.who, self:objectName(), "plus=" .. player:objectName() .. "+damage=" .. player:objectName() .. "=" .. recover.recover)
            SKMC.choice_log(recover.who, choice)
            if choice == "plus=" .. player:objectName() then
                recover.recover = recover.recover + SKMC.number_correction(recover.who, 1)
                data:setValue(recover)
            else
                local reason
                if recover.card then
                    reason = recover.card
                else
                    reason = self:objectName()
                end
                room:damage(sgs.DamageStruct(reason, recover.who, player, recover.recover))
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiShiraishi:addSkill(sakamichi_hei_shi)

sgs.LoadTranslationTable {
    ["MaiShiraishi"] = "白石 麻衣",
    ["&MaiShiraishi"] = "白石 麻衣",
    ["#MaiShiraishi"] = "乃团之颜",
    ["~MaiShiraishi"] = "後悔しないようにやりきろう！",
    ["designer:MaiShiraishi"] = "Cassimolar",
    ["cv:MaiShiraishi"] = "白石 麻衣",
    ["illustrator:MaiShiraishi"] = "Cassimolar",
    ["sakamichi_gong_shi"] = "共时",
    [":sakamichi_gong_shi"] = "主公技，乃木坂46势力角色出牌阶段限一次，其使用牌结算完成时可以进行判定，若判定牌与此牌类型相同，你与其各摸一张牌。",
    ["sakamichi_gong_shi:invoke"] = "是否发动%src 的【%arg】",
    ["sakamichi_nv_shen"] = "女神",
    [":sakamichi_nv_shen"] = "锁定技，你不能被翻面或横置，且不是【乐不思蜀】、【兵粮寸断】的合法目标。其他角色武将牌翻至背面时／横置时你可以弃置一张红色牌防止此次翻面／横置。",
    ["#nv_shen_turn_over"] = "%to 受到 %from【%arg】的影响，此次翻面被防止。",
    ["#nv_shen_chain_state_change"] = "%to 受到 %from【%arg】的影响，此次横置被防止。",
    ["@nv_shen_discard"] = "选择一张红色牌 → 点击确定",
    ["sakamichi_hei_shi"] = "黑石",
    [":sakamichi_hei_shi"] = "你令其他角色回复体力时，你可以令此次回复量+1或防止此次回复并对其造成等量伤害。",
    ["sakamichi_hei_shi:invoke"] = "是否对%src 发动【%arg】",
    ["sakamichi_hei_shi:plus"] = "令%src 本次回复量+1",
    ["sakamichi_hei_shi:damage"] = "对%src 造成%arg点伤害"
}

-- 橋本 奈々未
NanamiHashimoto = sgs.General(Sakamichi, "NanamiHashimoto$", "Nogizaka46", 3, false)
SKMC.IKiSei.NanamiHashimoto = true
SKMC.SeiMeiHanDan.NanamiHashimoto = {
    name = {16, 5, 8, 3, 5},
    ten_kaku = {21, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {37, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_zai_jian = sgs.CreateTriggerSkill {
    name = "sakamichi_zai_jian$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@zaijian",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if player:getMark("@zaijian") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            room:removePlayerMark(player, "@zaijian", 1)
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getKingdom() == "Nogizaka46" then
                    if player:objectName() ~= p:objectName() then
                        targets:append(p)
                    end
                    if p:hasJudgeArea() then
                        for _, card in sgs.qlist(p:getJudgingArea()) do
                            room:throwCard(card, p, player)
                        end
                    end
                    if not p:faceUp() then
                        p:turnOver()
                    end
                    room:setPlayerChained(p, false)
                end
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@zai_jian_choice:::" .. self:objectName(), true)
            if target then
                room:handleAcquireDetachSkills(target, self:objectName())
            end
        end
        return false
    end,
}
NanamiHashimoto:addSkill(sakamichi_zai_jian)

sakamichi_ming_yan_card = sgs.CreateSkillCard {
    name = "sakamichi_ming_yanCard",
    skill_name = "sakamichi_ming_yan",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            if self:getSuit() == sgs.Card_Club then
                if sgs.Self:distanceTo(to_select) == 1 then
                    local card = sgs.Sanguosha:cloneCard("supply_shortage", self:getSuit(), self:getNumber())
                    card:deleteLater()
                    card:addSubcard(self)
                    card:setSkillName(self:getSkillName())
                    return not to_select:containsTrick("supply_shortage") and not to_select:isProhibited(sgs.Self, card)
                end
            elseif self:getSuit() == sgs.Card_Diamond then
                local card = sgs.Sanguosha:cloneCard("indulgence", self:getSuit(), self:getNumber())
                card:deleteLater()
                card:addSubcard(self)
                card:setSkillName(self:getSkillName())
                return not to_select:containsTrick("indulgence") and not to_select:isProhibited(sgs.Self, card)
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card
        if self:getSuit() == sgs.Card_Club then
            card = sgs.Sanguosha:cloneCard("supply_shortage", self:getSuit(), self:getNumber())
        elseif self:getSuit() == sgs.Card_Diamond then
            card = sgs.Sanguosha:cloneCard("indulgence", self:getSuit(), self:getNumber())
        end
        card:deleteLater()
        card:addSubcard(self)
        card:setSkillName("sakamichi_ming_yan")
        room:useCard(sgs.CardUseStruct(card, effect.from, effect.to, true))
    end,
}
sakamichi_ming_yan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_ming_yan",
    response_pattern = "",
    filter_pattern = ".|club,diamond|.|hand,equipped",
    view_filter = function(self, to_select)
        if sgs.Self:hasFlag("ming_yan_club") then
            return to_select:getSuit() == sgs.Card_Club
        end
        if sgs.Self:hasFlag("ming_yan_diamond") then
            return to_select:getSuit() == sgs.Card_Diamond
        end
        return false
    end,
    view_as = function(self, card)
        local cd = sakamichi_ming_yan_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_ming_yan")
    end,
}
sakamichi_ming_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_ming_yan",
    frequency = sgs.Skill_Frequent,
    view_as_skill = sakamichi_ming_yan_view_as,
    events = {sgs.EventPhaseSkipping},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Draw then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    room:setPlayerFlag(p, "ming_yan_club")
                    room:askForUseCard(p, "@@sakamichi_ming_yan", "@ming_yan_invoke:::club:supply_shortage", -1)
                    room:setPlayerFlag(p, "-ming_yan_club")
                end
            end
        elseif player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    room:setPlayerFlag(p, "ming_yan_diamond")
                    room:askForUseCard(p, "@@sakamichi_ming_yan", "@ming_yan_invoke:::diamond:indulgence", -1)
                    room:setPlayerFlag(p, "-ming_yan_diamond")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanamiHashimoto:addSkill(sakamichi_ming_yan)

sakamichi_gai_ming_nanamihashimoto = sgs.CreateTriggerSkill {
    name = "sakamichi_gai_ming_nanamihashimoto",
    events = {sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        local prompt_list = {"@gai_ming_nanamihashimoto_card", judge.who:objectName(), self:objectName(), judge.reason, string.format("%d", judge.card:getEffectiveId())}
        local prompt = table.concat(prompt_list, ":")
        local card = room:askForCard(player, ".", prompt, data, sgs.Card_MethodResponse, judge.who, true)
        if card then
            room:retrial(card, player, judge, self:objectName(), false)
        end
        return false
    end,
    can_trigger = function(self, target)
        if not (target and target:isAlive() and target:hasSkill(self:objectName())) then
            return false
        end
        if target:isNude() then
            return false
        else
            return true
        end
    end,
}
NanamiHashimoto:addSkill(sakamichi_gai_ming_nanamihashimoto)

sgs.LoadTranslationTable {
    ["NanamiHashimoto"] = "橋本 奈々未",
    ["&NanamiHashimoto"] = "橋本 奈々未",
    ["#NanamiHashimoto"] = "便当偶像",
    ["~NanamiHashimoto"] = "桑田真澄の野球は心の野球",
    ["designer:NanamiHashimoto"] = "Cassimolar",
    ["cv:NanamiHashimoto"] = "橋本 奈々未",
    ["illustrator:NanamiHashimoto"] = "Cassimolar",
    ["sakamichi_zai_jian"] = "再见",
    [":sakamichi_zai_jian"] = "主公技，限定技，你进入濒死时，你可以令所有乃木坂46势力角色弃置其判定区的所有牌并将武将牌复原，并可以令一名其他乃木坂46势力角色获得本技能（获得后不为主公也可以发动）。",
    ["@zaijian"] = "再见",
    ["@zai_jian_choice"] = "你可以令一名其他乃木坂46势力角色获得【%arg】",
    ["sakamichi_ming_yan"] = "名言",
    [":sakamichi_ming_yan"] = "当一名其他角色跳过摸牌阶段/出牌阶段时，你可以将一张梅花牌/方块牌当【兵粮寸断】/【乐不思蜀】使用。",
    ["@ming_yan_invoke"] = "你可以将一张%arg牌视为【%arg2】使用",
    ["sakamichi_gai_ming_nanamihashimoto"] = "改命",
    [":sakamichi_gai_ming_nanamihashimoto"] = "一名角色的判定牌生效前，你可以打出一张牌代替之。",
    ["@gai_ming_nanamihashimoto_card"] = "请使用【%dest】来修改 %src 的 %arg 判定",
}

-- 安藤 美雲
MikumoAndo = sgs.General(Sakamichi, "MikumoAndo", "Nogizaka46", 3, false)
SKMC.IKiSei.MikumoAndo = true
SKMC.SeiMeiHanDan.MikumoAndo = {
    name = {6, 18, 9, 12},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {27, "ji_xiong_hun_he"},
    ji_kaku = {21, "ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {45, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_xiang_nan = sgs.CreateTriggerSkill {
    name = "sakamichi_xiang_nan",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw then
            if not player:isSkipped(sgs.Player_Draw) then
                if player:askForSkillInvoke(self:objectName(), sgs.QVariant("draw2play")) then
                    SKMC.send_message(room, "#draw2play", player, nil, nil, nil, self:objectName())
                    change.to = sgs.Player_Play
                    data:setValue(change)
                end
            end
        elseif change.to == sgs.Player_Play then
            if not player:isSkipped(sgs.Player_Play) then
                if player:askForSkillInvoke(self:objectName(), sgs.QVariant("play2draw")) then
                    SKMC.send_message(room, "#play2draw", player, nil, nil, nil, self:objectName())
                    change.to = sgs.Player_Draw
                    data:setValue(change)
                end
            end
        end
        return false
    end,
}
MikumoAndo:addSkill(sakamichi_xiang_nan)

sakamichi_yuan_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_yuan_qi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Discard and math.abs(player:getHandcardNum() - player:getHp()) <= player:getMaxHp() then
            SKMC.send_message(room, "#yuan_qi", player, nil, nil, nil, self:objectName())
            player:skip(change.to)
        end
        return false
    end,
}
MikumoAndo:addSkill(sakamichi_yuan_qi)

sakamichi_yu_jia = sgs.CreateTriggerSkill {
    name = "sakamichi_yu_jia",
    frequency = sgs.Skill_Frequent,
    events = {sgs.FinishJudge},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        local card = judge.card
        local card_data = sgs.QVariant()
        card_data:setValue(card)
        if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@yu_jia_invoke", true, true)
            if target and target:objectName() ~= player:objectName() then
                room:obtainCard(target, card)
                room:drawCards(player, 1, self:objectName())
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            else
                room:obtainCard(player, card)
            end
        end
    end,
}
MikumoAndo:addSkill(sakamichi_yu_jia)

sgs.LoadTranslationTable {
    ["MikumoAndo"] = "安藤 美雲",
    ["&MikumoAndo"] = "安藤 美雲",
    ["#MikumoAndo"] = "元気っ子",
    ["~MikumoAndo"] = "",
    ["designer:MikumoAndo"] = "Cassimolar",
    ["cv:MikumoAndo"] = "安藤 美雲",
    ["illustrator:MikumoAndo"] = "Cassimolar",
    ["sakamichi_xiang_nan"] = "湘南",
    [":sakamichi_xiang_nan"] = "你可以将你的摸牌阶段视为出牌阶段，出牌阶段视为摸牌阶段执行。",
    ["sakamichi_xiang_nan:draw2play"] = "您是否想发动【湘南】将 摸牌阶段 视为 出牌阶段？",
    ["sakamichi_xiang_nan:play2draw"] = "您是否想发动【湘南】将 出牌阶段 视为 摸牌阶段？",
    ["#draw2play"] = "%from 发动【%arg】将<font color=\"yellow\"><b> 摸牌阶段 </b></font>视为<font color=\"yellow\"><b> 出牌阶段 </b></font>",
    ["#play2draw"] = "%from 发动【%arg】将<font color=\"yellow\"><b> 出牌阶段 </b></font>视为<font color=\"yellow\"><b> 摸牌阶段 </b></font>",
    ["sakamichi_yuan_qi"] = "元气",
    [":sakamichi_yuan_qi"] = "锁定技，若你的手牌数与体力值的差不大于你的体力上限，你跳过弃牌阶段。",
    ["#yuan_qi"] = "%from 的【%arg】被触发",
    ["sakamichi_yu_jia"] = "瑜伽",
    [":sakamichi_yu_jia"] = "当你的判定牌生效后，你可以令一名角色获得之，若其不为你，你可以摸一张牌然后弃一张牌。",
    ["@yu_jia_invoke"] = "你可以选择一名角色令其获得此张判定牌",
}

-- 深川 麻衣
MaiFukagawa = sgs.General(Sakamichi, "MaiFukagawa$", "Nogizaka46", 3, false)
SKMC.IKiSei.MaiFukagawa = true
SKMC.SeiMeiHanDan.MaiFukagawa = {
    name = {11, 3, 11, 6},
    ten_kaku = {14, "xiong"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {17, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zi_yuan = sgs.CreateTriggerSkill {
    name = "sakamichi_zi_yuan$",
    events = {sgs.QuitDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:getKingdom() == "Nogizaka46" and dying.who:isWounded() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if dying.who:objectName() ~= p:objectName() and p:hasLordSkill(self:objectName()) and room:askForSkillInvoke(p, self:objectName(), data) then
                    local n = SKMC.number_correction(p, 1)
                    room:loseHp(p, n)
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, n))
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiFukagawa:addSkill(sakamichi_zi_yuan)

sakamichi_guang_hui = sgs.CreateTriggerSkill {
    name = "sakamichi_guang_hui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isWounded() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() and room:askForSkillInvoke(player, self:objectName(), data) then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@guang_hui_invoke:::" .. SKMC.number_correction(player, 1), true)
                if target then
                    room:recover(target, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                end
            end
        end
        return false
    end,
}
MaiFukagawa:addSkill(sakamichi_guang_hui)

sakamichi_sheng_mu = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_mu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.PreHpRecover, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Peach") then
                if use.from:hasSkill(self:objectName()) then
                    room:setCardFlag(use.card, "sheng_mu")
                end
            end
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.card and recover.card:hasFlag("sheng_mu") then
                local n = SKMC.number_correction(recover.who, 1)
                recover.recover = recover.recover + n
                data:setValue(recover)
                SKMC.send_message(room, "#sheng_mu_extra_recover", recover.who, player, nil, recover.card:toString(), self:objectName(), n, recover.recover)
                room:setCardFlag(recover.card, "-sheng_mu")
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:hasSkill(self:objectName()) and dying.damage and dying.damage.from and not dying.damage.from:isKongcheng() then
                dying.damage.from:throwAllCards()
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiFukagawa:addSkill(sakamichi_sheng_mu)

sgs.LoadTranslationTable {
    ["MaiFukagawa"] = "深川 麻衣",
    ["&MaiFukagawa"] = "深川 麻衣",
    ["#MaiFukagawa"] = "坚强的花蕾",
    ["~MaiFukagawa"] = "後悔しない選択",
    ["designer:MaiFukagawa"] = "Cassimolar",
    ["cv:MaiFukagawa"] = "深川 麻衣",
    ["illustrator:MaiFukagawa"] = "Cassimolar",
    ["sakamichi_zi_yuan"] = "紫苑",
    [":sakamichi_zi_yuan"] = "主公技，其他乃木坂46势力角色脱离濒死时，你可以失去1点体力令其回复等量体力值。",
    ["sakamichi_guang_hui"] = "光辉",
    [":sakamichi_guang_hui"] = "准备阶段，你可以令一名已受伤的角色回复1点体力。",
    ["@guang_hui_invoke"] = "你可以选择一名已受伤角色令其回复%arg点体力",
    ["sakamichi_sheng_mu"] = "圣母",
    [":sakamichi_sheng_mu"] = "锁定技，你使用的【桃】回复量+1。你进入濒死时，伤害来源须弃置所有手牌。",
    ["#sheng_mu_extra_recover"] = "%to 受到%from 的【%arg】的影响，此【%card】额外回复 <font color=\"yellow\"><b>1</b></font> 点体力，回复量为<font color=\"yellow\"><b>%arg2</b></font> 。",
}

-- 若月 佑美
YumiWakatsuki = sgs.General(Sakamichi, "YumiWakatsuki", "Nogizaka46", 4, false)
SKMC.IKiSei.YumiWakatsuki = true
SKMC.SeiMeiHanDan.YumiWakatsuki = {
    name = {8, 4, 7, 9},
    ten_kaku = {12, "xiong"},
    jin_kaku = {11, "ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {28, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_dou_hun = sgs.CreateTriggerSkill {
    name = "sakamichi_dou_hun",
    events = {sgs.TargetSpecified, sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (event == sgs.TargetSpecified and use.from:objectName() == player:objectName()) or (event == sgs.TargetConfirmed and use.to:contains(player)) then
            if use.card:isKindOf("Duel") then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
YumiWakatsuki:addSkill(sakamichi_dou_hun)

sakamichi_kuai_zi_jun = sgs.CreateTriggerSkill {
    name = "sakamichi_kuai_zi_jun",
    frequency = sgs.Skill_Wake,
    wakeed_skills = "sakamichi_kou_ji",
    events = {sgs.EventPhaseStart},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPhase() == sgs.Player_Start and player:getMark("duel_damage") >= SKMC.number_correction(player, 3) then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName(), 1)
        room:handleAcquireDetachSkills(player, "sakamichi_kou_ji")
        return false
    end,
}
sakamichi_kuai_zi_jun_record = sgs.CreateTriggerSkill {
    name = "sakamichi_kuai_zi_jun_record",
    events = {sgs.Damage},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Duel") then
            room:addPlayerMark(player, "duel_damage", damage.damage)
        end
        return false
    end,
}
YumiWakatsuki:addSkill(sakamichi_kuai_zi_jun)
if not sgs.Sanguosha:getSkill("sakamichi_kuai_zi_jun_record") then SKMC.SkillList:append(sakamichi_kuai_zi_jun_record) end

sakamichi_kou_ji_card = sgs.CreateSkillCard {
    name = "sakamichi_kou_jiCard",
    skill_name = "sakamichi_kou_ji",
    filter = function(self, targets, to_select)
        if #targets < 2 then
            local card = sgs.Sanguosha:cloneCard("duel", self:getSuit(), self:getNumber())
            card:deleteLater()
            card:addSubcard(self)
            card:setSkillName(self:getSkillName())
            return not to_select:isProhibited(sgs.Self, card)
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:cloneCard("duel", self:getSuit(), self:getNumber())
        card:deleteLater()
        card:addSubcard(self)
        card:setSkillName(self:getSkillName())
        room:useCard(sgs.CardUseStruct(card, source, SKMC.table_to_SPlayerList(targets), true))
    end,
}
sakamichi_kou_ji = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_kou_ji",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_kou_ji_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#sakamichi_kou_jiCard")
    end,

}
if not sgs.Sanguosha:getSkill("sakamichi_kou_ji") then SKMC.SkillList:append(sakamichi_kou_ji) end

sgs.LoadTranslationTable {
    ["YumiWakatsuki"] = "若月 佑美",
    ["&YumiWakatsuki"] = "若月 佑美",
    ["#YumiWakatsuki"] = "月少参上",
    ["~YumiWakatsuki"] = "我が輩は猫ではない。",
    ["designer:YumiWakatsuki"] = "Cassimolar",
    ["cv:YumiWakatsuki"] = "若月 佑美",
    ["illustrator:YumiWakatsuki"] = "Cassimolar",
    ["sakamichi_dou_hun"] = "斗魂",
    [":sakamichi_dou_hun"] = "当你成为【决斗】的目标后/使用【决斗】指定目标后，你可以摸一张牌。",
    ["sakamichi_kuai_zi_jun"] = "筷子君",
    [":sakamichi_kuai_zi_jun"] = "觉醒技，准备阶段，若你本局游戏内已使用【决斗】造成至少3点伤害，你获得【口技】",
    ["sakamichi_kou_ji"] = "口技",
    [":sakamichi_kou_ji"] = "出牌阶段限一次，你可以将一张手牌当【决斗】使用，你以此法使用的【决斗】可以额外指定一个目标。",
}

-- 西野 七瀬
NanaseNishino = sgs.General(Sakamichi, "NanaseNishino$", "Nogizaka46", 3, false)
SKMC.IKiSei.NanaseNishino = true
SKMC.SeiMeiHanDan.NanaseNishino = {
    name = {6, 11, 2, 19},
    ten_kaku = {17, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {25, "ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_ming_mei = sgs.CreateTriggerSkill {
    name = "sakamichi_ming_mei$",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:objectName() == player:objectName() and player:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("ming_mei_used" .. player:objectName()) == 0 and p:hasLordSkill(self:objectName()) and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName())) then
                    room:addPlayerMark(p, "ming_mei_used" .. player:objectName(), 1)
                    room:recover(player, sgs.RecoverStruct(p, nil, 1))
                    room:drawCards(player, 2, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanaseNishino:addSkill(sakamichi_ming_mei)

sakamichi_qian_shui = sgs.CreateTriggerSkill {
    name = "sakamichi_qian_shui",
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    priority = 1,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
            local target = room:getTag("qian_shui_target"):toPlayer()
            room:removeTag("qian_shui_target")
            if target and target:isAlive() then
                target:gainAnExtraTurn()
            end
        elseif event == sgs.EventPhaseChanging and player:hasSkill(self:objectName()) then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:turnOver()
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@qian_shui_choice")
                    local _data = sgs.QVariant()
                    _data:setValue(target)
                    room:setTag("qian_shui_target", _data)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanaseNishino:addSkill(sakamichi_qian_shui)

sakamichi_yuan_lu = sgs.CreateDistanceSkill {
    name = "sakamichi_yuan_lu",
    correct_func = function(self, from, to)
        if to:hasSkill(self:objectName()) then
            local m = from:getSeat()
            local n = to:getSeat()
            local l = 1
            for _, p in sgs.qlist(from:getAliveSiblings()) do
                l = l + 1
            end
            if m > n then
                return math.abs(math.abs(m - l - n) - math.abs(m - n))
            elseif n > m then
                return math.abs(math.abs(m + l -n) - math.abs(m - n))
            end
        end
    end,
}
NanaseNishino:addSkill(sakamichi_yuan_lu)

sgs.LoadTranslationTable {
    ["NanaseNishino"] = "西野 七瀬",
    ["&NanaseNishino"] = "西野 七瀬",
    ["#NanaseNishino"] = "光合成希望",
    ["~NanaseNishino"] = "勝ちたいならやれ、負けてもいいならやめろ！",
    ["designer:NanaseNishino"] = "Cassimolar",
    ["cv:NanaseNishino"] = "西野 七瀬",
    ["illustrator:NanaseNishino"] = "Cassimolar",
    ["sakamichi_ming_mei"] = "命美",
    [":sakamichi_ming_mei"] = "主公技，每名乃木坂46势力角色限一次，当其进入濒死时，你可以令其回复1点体力值并摸两张牌。",
    ["sakamichi_ming_mei:invoke"] = "是否发动对%src 发动【%arg】",
    ["sakamichi_qian_shui"] = "潜水",
    [":sakamichi_qian_shui"] = "结束阶段，你可以翻面，若如此做，你可以令一名其他角色在本回合结束后执行一个额外的回合。",
    ["@qian_shui_choice"] = "请选择一名其他角色令其进行一个额外的回合",
    ["sakamichi_yuan_lu"] = "远路",
    [":sakamichi_yuan_lu"] = "锁定技，其他角色计算与你的距离时总是选择较长路径。",
}

-- 松村 沙友理
SayuriMatsumura = sgs.General(Sakamichi, "SayuriMatsumura", "Nogizaka46", 3, false)
SKMC.IKiSei.SayuriMatsumura = true
SKMC.SeiMeiHanDan.SayuriMatsumura = {
    name = {8, 7, 7, 4, 11},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {23, "ji"},
    sou_kaku = {37, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

SayuriMatsumura:addSkill("sakamichi_xia_chu")

sakamichi_chi_huo = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_huo",
    events = {sgs.CardFinished, sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Peach") then
                local ids = sgs.IntList()
                if use.card:isVirtualCard() then
                    ids = use.card:getSubcards()
                else
                    ids:append(use.card:getEffectiveId())
                end
                if not ids:isEmpty() then
                    local in_discard = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                            in_discard = false
                            break
                        end
                    end
                    if in_discard then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if player:objectName() ~= p:objectName() and room:askForSkillInvoke(p, self:objectName(), data) then
                                room:loseHp(p)
                                room:obtainCard(p, use.card, true)
                                break
                            end
                        end
                    end
                end
            end
        elseif event == sgs.AskForRetrial then
            local judge = data:toJudge()
            if judge.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) and judge.reason == "supply_shortage" and room:askForSkillInvoke(player, self:objectName(), data) then
                local id = room:drawCard()
                room:getThread():delay()
                room:retrial(sgs.Sanguosha:getCard(id), player, judge, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SayuriMatsumura:addSkill(sakamichi_chi_huo)

sakamichi_ping_guo_quan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_ping_guo_quan",
    response_pattern = "analeptic",
    filter_pattern = "Peach",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
        card:deleteLater()
        if player:isCardLimited(card, sgs.Card_MethodUse) or player:isProhibited(player, card) then
            return false
        end
        return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, card)
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "analeptic")
    end,
}
sakamichi_ping_guo_quan = sgs.CreateTriggerSkill {
    name = "sakamichi_ping_guo_quan",
    view_as_skill = sakamichi_ping_guo_quan_view_as,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Analeptic") and use.card:getSkillName() == self:objectName() and player:getPhase() ~= sgs.Player_NotActive then
            room:setPlayerFlag(player, "ping_guo_quan")
        end
        if use.card:isKindOf("Slash") and player:hasFlag("ping_guo_quan") then
            room:setPlayerFlag(player, "-ping_guo_quan")
        end
        return false
    end,
}
sakamichi_ping_guo_quan_Mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_ping_guo_quan_Mod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_ping_guo_quan") and from:hasFlag("ping_guo_quan") then
            return 1000
        else
            return 0
        end
    end,
}
SayuriMatsumura:addSkill(sakamichi_ping_guo_quan)
if not sgs.Sanguosha:getSkill("#sakamichi_ping_guo_quan_Mod") then SKMC.SkillList:append(sakamichi_ping_guo_quan_Mod) end

sgs.LoadTranslationTable {
    ["SayuriMatsumura"] = "松村 沙友理",
    ["&SayuriMatsumura"] = "松村 沙友理",
    ["#SayuriMatsumura"] = "苹果公主",
    ["~SayuriMatsumura"] = "妥協じゃないです！方向転換です",
    ["designer:SayuriMatsumura"] = "Cassimolar",
    ["cv:SayuriMatsumura"] = "松村 沙友理",
    ["illustrator:"] = "Cassimolar",
    ["sakamichi_chi_huo"] = "吃货",
    [":sakamichi_chi_huo"] = "其他角色使用的【桃】结算完成时，你可以失去1点体力从弃牌堆获得之。你的【兵粮寸断】的判定牌生效前，你可以亮出牌堆顶的一张牌代替之。",
    ["sakamichi_ping_guo_quan"] = "苹果拳",
    [":sakamichi_ping_guo_quan"] = "你可以将【桃】当【酒】使用或打出。你的回合内，你以此法使用【酒】后，你使用的下一张【杀】无距离限制。",
}

-- 川後 陽菜
HinaKawago = sgs.General(Sakamichi, "HinaKawago", "Nogizaka46", 3, false)
SKMC.IKiSei.HinaKawago = true
SKMC.SeiMeiHanDan.HinaKawago = {
    name = {3, 9, 12, 11},
    ten_kaku = {12, "xiong"},
    jin_kaku = {21, "ji"},
    ji_kaku = {23, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_sheng_qi_card = sgs.CreateSkillCard {
    name = "sakamichi_sheng_qiCard",
    skill_name = "sakamichi_sheng_qi",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:loseHp(effect.from, SKMC.number_correction(effect.from, 1))
        room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
    end,
}
sakamichi_sheng_qi_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sheng_qi",
    view_as = function(self)
        return sakamichi_sheng_qi_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@shengqi") ~= 0
    end,
}
sakamichi_sheng_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_qi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@shengqi",
    view_as_skill = sakamichi_sheng_qi_view_as,
    events = {sgs.GameStart, sgs.HpRecover, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self:objectName()) then
                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@sheng_qi_invoke:::sheng_guang_dao_biao", true)
                if target then
                    room:addPlayerMark(target, "@sheng_guang_dao_biao")
                    room:addPlayerMark(target, "&" .. player:getGeneralName() .. "+ +" .. "sheng_guang_dao_biao")
                    room:addPlayerMark(target, player:objectName() .. "_sheng_guang_dao_biao")
                end
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:hasSkill(self:objectName()) and not recover.who:hasFlag("sheng_qi") then
                room:setPlayerFlag(recover.who, "sheng_qi")
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(recover.who:objectName() .. "_sheng_guang_dao_biao") ~= 0 or p:getMark(recover.who:objectName() .. "_xin_yang_dao_biao") ~= 0 then
                        room:recover(p, sgs.RecoverStruct(recover.who, recover.card, recover.recover))
                    end
                end
                room:setPlayerFlag(recover.who, "-sheng_qi")
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) and player:getMark("@shengqi") ~= 0 then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:::" .. self:objectName())) then
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(player:objectName() .. "_sheng_guang_dao_biao") == 0 or p:getMark(player:objectName() .. "_xin_yang_dao_biao") == 0 then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@sheng_qi_invoke:::xin_yang_dao_biao")
                    if target then
                        room:removePlayerMark(player, "@shengqi")
                        room:addPlayerMark(target, "@xin_yang_dao_biao")
                        room:addPlayerMark(target, "&" .. player:getGeneralName() .. "+ +" .. "xin_yang_dao_biao")
                        room:addPlayerMark(target, player:objectName() .. "_xin_yang_dao_biao")
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaKawago:addSkill(sakamichi_sheng_qi)

sakamichi_sheng_liao_card = sgs.CreateSkillCard {
    name = "sakamichi_sheng_liaoCard",
    skill_name = "sakamichi_sheng_liao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark("@sheng_liao_used") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@shengliao")
        room:recover(effect.to, sgs.RecoverStruct(effect.from, self, effect.from:getMaxHp()))
        room:addPlayerMark(effect.to, "@sheng_liao_used")
    end
}
sakamichi_sheng_liao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sheng_liao",
    view_as = function(self)
        return sakamichi_sheng_liao_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@shengliao") ~= 0
    end,
}
sakamichi_sheng_liao = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_liao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@shengliao",
    view_as_skill = sakamichi_sheng_liao_view_as,
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:getMark("@sheng_liao_used") == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("@shengliao") ~= 0 and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:removePlayerMark(p, "@shengliao")
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, p:getMaxHp()))
                    room:addPlayerMark(dying.who, "@sheng_liao_used")
                    break
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaKawago:addSkill(sakamichi_sheng_liao)

sgs.LoadTranslationTable {
    ["HinaKawago"] = "川後 陽菜",
    ["&HinaKawago"] = "川後 陽菜",
    ["#HinaKawago"] = "圣骑之巅",
    ["~HinaKawago"] = "歌ってもない！！出てもない！！！",
    ["designer:HinaKawago"] = "Cassimolar",
    ["cv:HinaKawago"] = "川後 陽菜",
    ["illustrator:HinaKawago"] = "Cassimolar",
    ["sakamichi_sheng_qi"] = "圣骑",
    ["@sheng_qi"] = "圣骑",
    [":sakamichi_sheng_qi"] = "游戏开始时，你可以令一名角色获得一枚「圣光道标」。出牌阶段限一次，你可以失去1点体力令一名角色回复1点体力。限定技，准备阶段，你可以失去本技能出牌阶段限一次的效果，令一名未获得你的「道标」的角色获得一枚「信仰道标」。你造成回复时，你的「道标」拥有者回复等量体力值（此回复无法被「道标」复制）。",
    ["@shengqi"] = "圣骑",
    ["sheng_guang_dao_biao"] = "圣光道标",
    ["xin_yang_dao_biao"] = "信仰道标",
    ["sakamichi_sheng_qi:invoke"] = "是否发动【%arg】令一名角色获得“信仰道标”",
    ["@sheng_qi_invoke"] = "你可以选择一名角色令其获得“%arg”",
    ["sakamichi_sheng_liao"] = "圣疗",
    [":sakamichi_sheng_liao"] = "限定技，一名未以此法回复过体力的角色进入濒死时/出牌阶段，你可以选择一名未以此法回复过体力的角色，你可以令其回复X点体力（X为你的体力上限）。",
}

-- 吉本 彩華
AyakaYoshimoto = sgs.General(Sakamichi, "AyakaYoshimoto", "Nogizaka46", 3, false)
SKMC.IKiSei.AyakaYoshimoto = true
SKMC.SeiMeiHanDan.AyakaYoshimoto = {
    name = {6, 5, 11, 10},
    ten_kaku = {11, "ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_wei_zhi = sgs.CreateTriggerSkill {
    name = "sakamichi_wei_zhi",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start and not player:isAllNude() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local m = player:getCards("hej"):length()
                local n = player:getHp()
                player:throwAllCards()
                room:drawCards(player, n, self:objectName())
                if math.abs(m - n) > player:getLostHp() then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not p:isAllNude() then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@wei_zhi_invoke", true, true)
                        if target then
                            local card = room:askForCardChosen(player, target, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
                            room:throwCard(card, target, player)
                        end
                    end
                end
            end
            return false
        end
    end,
}
AyakaYoshimoto:addSkill(sakamichi_wei_zhi)

sakamichi_yuan_c = sgs.CreateTriggerSkill {
    name = "sakamichi_yuan_c",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local players = sgs.SPlayerList()
        if death.who:objectName() == player:objectName() then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == "Nogizaka46" then
                    players:append(p)
                else
                    local lord_skill = {}
                    for _, skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
                        if skill:isLordSkill() and not p:hasLordSkill(skill:objectName()) then
                            table.insert(lord_skill, skill:objectName())
                        end
                    end
                    if p:getGeneral2() then
                        for _, skill in sgs.qlist(p:getGeneral2():getVisibleSkillList()) do
                            if skill:isLordSkill() and not p:hasLordSkill(skill:objectName()) then
                                table.insert(lord_skill, skill:objectName())
                            end
                        end
                    end
                    if #lord_skill > 0 then
                        players:append(p)
                    end
                end
            end
            if not players:isEmpty() then
                local target = room:askForPlayerChosen(player, players, self:objectName(), "@yuan_c_invoke", true, true)
                if target then
                    local lord_skill = {}
                    for _, skill in sgs.qlist(target:getGeneral():getVisibleSkillList()) do
                        if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) then
                            table.insert(lord_skill, skill:objectName())
                        end
                    end
                    if target:getGeneral2() then
                        for _, skill in sgs.qlist(target:getGeneral2():getVisibleSkillList()) do
                            if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) then
                                table.insert(lord_skill, skill:objectName())
                            end
                        end
                    end
                    if #lord_skill > 0 then
                        room:handleAcquireDetachSkills(target, table.concat(lord_skill, "|"))
                    end
                    local lords = sgs.Sanguosha:getLords()
                    for _, p in sgs.qlist(room:getOtherPlayers(target)) do
                        table.removeOne(lords, p:getGeneralName())
                    end
                    local lord_skills = {}
                    for _, lord in ipairs(lords) do
                        local general = sgs.Sanguosha:getGeneral(lord)
                        local skills = general:getSkillList()
                        for _, skill in sgs.qlist(skills) do
                            if skill:isLordSkill() then
                                if not target:hasSkill(skill:objectName()) then
                                    table.insert(lord_skills, skill:objectName())
                                end
                            end
                        end
                    end
                    if #lord_skills > 0 then
                        local choices = table.concat(lord_skills, "+")
                        local skill_name = room:askForChoice(target, self:objectName(), choices)
                        SKMC.choice_log(target, skill_name)
                        local skill = sgs.Sanguosha:getSkill(skill_name)
                        room:acquireSkill(target, skill)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}
AyakaYoshimoto:addSkill(sakamichi_yuan_c)

sgs.LoadTranslationTable {
    ["AyakaYoshimoto"] = "吉本 彩華",
    ["&AyakaYoshimoto"] = "吉本 彩華",
    ["#AyakaYoshimoto"] = "未知",
    ["designer:AyakaYoshimoto"] = "Cassimolar",
    ["cv:AyakaYoshimoto"] = "吉本 彩華",
    ["illustrator:AyakaYoshimoto"] = "Cassimolar",
    ["sakamichi_wei_zhi"] = "未知",
    [":sakamichi_wei_zhi"] = "准备阶段，若你区域内有牌，你可以弃置你区域内所有的牌并摸取等同你体力值的牌，若你以此法弃置的牌与摸取的牌的差不小于你已损失的体力值，你可以弃置场上一张牌。",
    ["@wei_zhi_invoke"] = "你可以弃置场上的一张牌",
    ["sakamichi_yuan_c"] = "元C",
    [":sakamichi_yuan_c"] = "你死亡时可以选择一名其他乃木坂46势力角色或武将牌上有主公技的角色，若其武将牌上有主公技你令其获得之，然后令其选择并获得一个未上场或已阵亡角色的主公技。",
    ["@yuan_c_invoke"] = "你可以选择一名“乃木坂46”势力角色或武将牌上有主公技的角色",
}

-- 大和 里菜
RinaYamato = sgs.General(Sakamichi, "RinaYamato", "Nogizaka46", 3, false)
SKMC.IKiSei.RinaYamato = true
SKMC.SeiMeiHanDan.RinaYamato = {
    name = {3, 8, 7, 11},
    ten_kaku = {11, "ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fan_qie_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_fan_qie",
    filter_pattern = ".|red",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
        card:deleteLater()
        if player:isCardLimited(card, sgs.Card_MethodUse) or player:isProhibited(player, card) then
            return false
        end
        return player:isWounded()
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "peach")
    end,
}
sakamichi_fan_qie = sgs.CreateTriggerSkill {
    name = "sakamichi_fan_qie",
    view_as_skill = sakamichi_fan_qie_view_as,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if data:toCardUse().card:getSkillName() == self:objectName() then
            if player:getHp() > SKMC.number_correction(player, 2) then
                room:loseHp(player, SKMC.number_correction(player, 1))
            end
        end
        return false
    end,
}
RinaYamato:addSkill(sakamichi_fan_qie)

sakamichi_yin_jiu = sgs.CreateTriggerSkill {
    name = "sakamichi_yin_jiu",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.SlashProceed, sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and p:canDiscard(p, "h") then
                        local cd = room:askForCard(p, ".|.|.|hand", "@yin_jiu_discard:" .. player:objectName(), sgs.QVariant(), self:objectName())
                        if cd then
                            local card = sgs.Sanguosha:cloneCard("analeptic", cd:getSuit(), cd:getNumber())
                            card:addSubcard(cd)
                            card:setSkillName(self:objectName())
                            room:useCard(sgs.CardUseStruct(card, player, player, true))
                            card:deleteLater()
                            if player:isAlive() then
                                room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
                            end
                        end
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Analeptic") and use.card:getSkillName() == self:objectName() then
                room:addPlayerHistory(use.from, use.card:getClassName(), -1)
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("drank") and effect.to:hasSkill(self:objectName()) then
                room:slashResult(effect, nil)
                return true
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("drank") and damage.to:hasSkill(self:objectName()) then
                room:drawCards(player, damage.damage, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaYamato:addSkill(sakamichi_yin_jiu)

sakamichi_bu_lun = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_lun",
    events = {sgs.EnterDying, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.damage and dying.damage.from and dying.who:objectName() ~= player:objectName() then
                if room:askForSkillInvoke(dying.damage.from, self:objectName(), sgs.QVariant("draw:" .. player:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from then
                if room:askForSkillInvoke(death.damage.from, self:objectName(), sgs.QVariant("losehp:" .. player:objectName())) then
                    room:loseHp(player, SKMC.number_correction(player, 1))
                end
            end
        end
        return false
    end,
}
RinaYamato:addSkill(sakamichi_bu_lun)

sgs.LoadTranslationTable {
    ["RinaYamato"] = "大和 里菜",
    ["&RinaYamato"] = "大和 里菜",
    ["#RinaYamato"] = "毒番茄",
    ["~RinaYamato"] = "",
    ["designer:RinaYamato"] = "Cassimolar",
    ["cv:RinaYamato"] = "大和 里菜",
    ["illustrator:RinaYamato"] = "Cassimolar",
    ["sakamichi_fan_qie"] = "番茄",
    [":sakamichi_fan_qie"] = "你可以将一张红色牌当【桃】使用或打出。你以此法使用的【桃】结算完成时，若你的体力大于2，你失去1点体力。",
    ["sakamichi_yin_jiu"] = "饮酒",
    [":sakamichi_yin_jiu"] = "其他角色出牌阶段开始时，你可以弃置一张手牌，视为其使用一张【酒】（不计入次数使用限制），并对其造成1点伤害。锁定技，你无法闪避【酒】【杀】，你受到【酒】【杀】造成的伤害后，你摸等同于伤害量的牌。",
    ["@yin_jiu_discard"] = "你可以弃置一张手牌发动【饮酒】视为%src 使用一张【酒】并对其造成1点伤害",
    ["sakamichi_bu_lun"] = "不伦",
    [":sakamichi_bu_lun"] = "其他角色进入濒死时，伤害来源可以令你摸一张牌。其他角色死亡时，伤害来源可以令你失去1点体力。",
    ["sakamichi_bu_lun:draw"] = "你可以发动 %src 的【不伦】令其摸一张牌",
    ["sakamichi_bu_lun:losehp"] = "你可以发动 %src 的【不伦】令其失去1点体力",
}

-- 中田 花奈
KanaNakada = sgs.General(Sakamichi, "KanaNakada", "Nogizaka46", 1, false)
SKMC.IKiSei.KanaNakada = true
SKMC.SeiMeiHanDan.KanaNakada = {
    name = {4, 5, 7, 8},
    ten_kaku = {9, "xiong"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_ou_xiang_chu = sgs.CreateTriggerSkill {
    name = "sakamichi_ou_xiang_chu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        local extra = 0
        local kingdoms = {}
        table.insert(kingdoms, player:getKingdom())
        for _, p in sgs.qlist(player:getSiblings()) do
            local flag = true
            for _, k in ipairs(kingdoms) do
                if p:getKingdom() == k then
                    flag = false
                    break
                end
            end
            if flag then
                table.insert(kingdoms, p:getKingdom())
            end
        end
        extra = #kingdoms
        room:gainMaxHp(player, extra)
        room:recover(player, sgs.RecoverStruct(player, nil, extra))
    end,
}
KanaNakada:addSkill(sakamichi_ou_xiang_chu)

sakamichi_zhi_long_mi_cheng_card = sgs.CreateSkillCard {
    name = "sakamichi_zhi_long_mi_chengCard",
    skill_name = "sakamichi_zhi_long_mi_cheng",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local players = room:getOtherPlayers(source)
        for _, p in sgs.qlist(players) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        room:loseHp(effect.to, SKMC.number_correction(effect.from, 1))
    end,
}
sakamichi_zhi_long_mi_cheng = sgs.CreateViewAsSkill {
    name = "sakamichi_zhi_long_mi_cheng",
    n = 3,
    view_filter = function(self, selected, to_select)
        if #selected <= 3 then
            if #selected ~= 0 then
                local suit = selected[1]:getSuit()
                return to_select:getSuit() == suit and not sgs.Self:isJilei(to_select)
            end
            return not sgs.Self:isJilei(to_select)
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 3 then
            local cd = sakamichi_zhi_long_mi_cheng_card:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            return cd
        end
    end,
}
KanaNakada:addSkill(sakamichi_zhi_long_mi_cheng)

sakamichi_zhong_tian_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_zhong_tian_dao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageForseen},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and SKMC.is_ki_be(damage.from, 3) then
            SKMC.send_message(room, "#zhong_tian_dao", damage.from, player, nil, nil, self:objectName(), SKMC.number_correction(player, 1))
            damage.damage = damage.damage + SKMC.number_correction(player, 1)
            data:setValue(damage)
        end
    end,
}
KanaNakada:addSkill(sakamichi_zhong_tian_dao)

sakamichi_ma_jiang = sgs.CreateTriggerSkill {
    name = "sakamichi_ma_jiang",
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and not player:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
            room:showAllCards(player)
            local colors = {}
            local all_different = true
            for _, c in sgs.qlist(player:getHandcards()) do
                local flag = true
                for _, color in ipairs(colors) do
                    if c:getSuit() == color then
                        flag = false
                        all_different = false
                        break
                    end
                end
                if not all_different then
                    break
                end
                if flag then
                    table.insert(colors, c:getSuit())
                end
            end
            if all_different and #colors > 0 then
                SKMC.send_message(room, "#ma_jiang", player, nil, nil, nil, self:objectName(), #colors)
                room:drawCards(player, #colors, self:objectName())
            end
        end
        return false
    end,
}
KanaNakada:addSkill(sakamichi_ma_jiang)

sgs.LoadTranslationTable {
    ["KanaNakada"] = "中田 花奈",
    ["&KanaNakada"] = "中田 花奈",
    ["#KanaNakada"] = "一石三鳥",
    ["~KanaNakada"] = "モノで釣ってるよ",
    ["designer:KanaNakada"] = "Cassimolar",
    ["cv:KanaNakada"] = "中田 花奈",
    ["illustrator:KanaNakada"] = "Cassimolar",
    ["sakamichi_ou_xiang_chu"] = "偶像厨",
    [":sakamichi_ou_xiang_chu"] = "锁定技，游戏开始时，你增加X点体力上限，并回复X点体力（X为场上势力数）。",
    ["sakamichi_zhi_long_mi_cheng"] = "智龙迷城",
    [":sakamichi_zhi_long_mi_cheng"] = "出牌阶段，你可以弃置三张同花色手牌，若如此做，所有其他角色失去1点体力。",
    ["sakamichi_zhong_tian_dao"] = "中田道",
    [":sakamichi_zhong_tian_dao"] = "锁定技，当你受到来自三期生的伤害时，伤害+1。",
    ["#zhong_tian_dao"] = "%to 的【%arg】被触发，三期生 %from 对 %to 造成的伤害增加<font color=\"yellow\"><b>1</b></font>点。",
    ["sakamichi_ma_jiang"] = "麻将",
    [":sakamichi_ma_jiang"] = "结束阶段，你可以展示手牌，若花色均不相同，则每有一种花色，你摸一张牌。",
    ["#ma_jiang"] = "%from 发动【%arg】展示手牌，花色均不相同共有%arg2种花色",
}

-- 星野 みなみ
MinamiHoshino = sgs.General(Sakamichi, "MinamiHoshino", "Nogizaka46", 3, false)
SKMC.IKiSei.MinamiHoshino = true
SKMC.SeiMeiHanDan.MinamiHoshino = {
    name = {9, 11, 3, 5, 3},
    ten_kaku = {20, "xiong"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {11, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_ai_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_ai_xin",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            local result = SKMC.run_judge(room, player, self:objectName(), ".|heart")
            if result.isGood then
                room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
MinamiHoshino:addSkill(sakamichi_ai_xin)

sakamichi_meng_hun = sgs.CreateTriggerSkill {
    name = "sakamichi_meng_hun",
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and not player:isKongcheng() and
            room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:" .. use.from:objectName() .. "::" .. use.card:objectName() .. ":" .. self:objectName())) then
            player:throwAllHandCards()
            SKMC.send_message(room, "#meng_hun_avoid", player, nil, nil, use.card:toString(), self:objectName())
            local nullified_list = use.nullified_list
            table.insert(nullified_list, player:objectName())
            use.nullified_list = nullified_list
            data:setValue(use)
            room:drawCards(player, 1, self:objectName())
            room:drawCards(use.from, 1, self:objectName())
        end
        return false
    end,
}
MinamiHoshino:addSkill(sakamichi_meng_hun)

sakamichi_shi_ba = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_ba",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand) or
            (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand))) and player:getHandcardNum() > 6 then
            SKMC.send_message(room, "#shi_ba_jin", player, nil, nil, nil, self:objectName())
            room:damage(sgs.DamageStruct(self:objectName(), nil, player, SKMC.number_correction(player, 1)))
        end
        return false
    end,
}
MinamiHoshino:addSkill(sakamichi_shi_ba)

sgs.LoadTranslationTable {
    ["MinamiHoshino"] = "星野 みなみ",
    ["&MinamiHoshino"] = "星野 みなみ",
    ["#MinamiHoshino"] = "小祖宗",
    ["~MinamiHoshino"] = "今ピンク大好きなんです❤",
    ["designer:MinamiHoshino"] = "Cassimolar",
    ["cv:MinamiHoshino"] = "星野 みなみ",
    ["illustrator:MinamiHoshino"] = "Cassimolar",
    ["sakamichi_ai_xin"] = "爱心",
    [":sakamichi_ai_xin"] = "当你受到伤害后，你可以进行判定，若结果为红桃，你回复1点体力。",
    ["sakamichi_meng_hun"] = "萌混",
    [":sakamichi_meng_hun"] = "当你成为【杀】或【决斗】的目标时，你可以弃置所有手牌令此牌对你无效，然后你和此牌的使用者各摸一张牌。",
    ["sakamichi_meng_hun:invoke"] = "是否弃置所有手牌发动【%arg2】令%src使用的【%arg】对你无效",
    ["sakamichi_shi_ba"] = "十八",
    [":sakamichi_shi_ba"] = "锁定技，当你手牌数发生改变后，若你的手牌数多于六张，则你受到1点无来源伤害。",
    ["#shi_ba_jin"] = "%from 受到【%arg】的影响，%from 受到1点无来源伤害",
}

-- 齋藤 飛鳥
AsukaSaito = sgs.General(Sakamichi, "AsukaSaito$", "Nogizaka46", 3, false)
SKMC.IKiSei.AsukaSaito = true
SKMC.SeiMeiHanDan.AsukaSaito = {
    name = {17, 18, 9, 11},
    ten_kaku = {35, "ji"},
    jin_kaku = {27, "ji_xiong_hun_he"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {28, "xiong"},
    sou_kaku = {55, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji",
    },
}

sakamichi_luo_zu = sgs.CreateDistanceSkill {
    name = "sakamichi_luo_zu$",
    frequency = sgs.Skill_Compulsory,
    correct_func = function(self, from, to)
        if from:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(from:getSiblings()) do
                if p:hasLordSkill(self:objectName()) and not p:getOffensiveHorse() then
                    return -1
                end
            end
        end
        if to:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(to:getSiblings()) do
                if p:hasLordSkill(self:objectName()) and not p:getDefensiveHorse() then
                    return 1
                end
            end
        end
    end,
}
AsukaSaito:addSkill(sakamichi_luo_zu)

sakamichi_tian_niao_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_tian_niao",
    response_pattern = "slash",
    filter_pattern = ".|red",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
}
sakamichi_tian_niao = sgs.CreateTriggerSkill {
    name = "sakamichi_tian_niao",
    view_as_skill = sakamichi_tian_niao_view_as,
    events = {sgs.SlashProceed, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.slash:getSkillName() == self:objectName() and effect.slash:getSuit() == sgs.Card_Heart then
                room:slashResult(effect, nil)
                return true
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == self:objectName() and sgs.Sanguosha:getCard(damage.card:getSubcards():first()) then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end,

}
AsukaSaito:addSkill(sakamichi_tian_niao)

sakamichi_an_niao = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_an_niao",
    response_pattern = "jink",
    filter_pattern = ".|black",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
}
sakamichi_an_niao_prohibit = sgs.CreateProhibitSkill {
    name = "#sakamichi_an_niao_prohibit",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_an_niao") and not to:faceUp() and (card:isKindOf("Slash") or card:isNDTrick())
    end,
}
AsukaSaito:addSkill(sakamichi_an_niao)
if not sgs.Sanguosha:getSkill("#sakamichi_an_niao_prohibit") then SKMC.SkillList:append(sakamichi_an_niao_prohibit) end

sakamichi_zi_bi_card = sgs.CreateSkillCard {
    name = "sakamichi_zi_biCard",
    skill_name = "sakamichi_zi_bi",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:turnOver()
        effect.to:turnOver()
        if effect.from:getHandcardNum() > effect.to:getHandcardNum() then
            room:drawCards(effect.to, 1, self:getSkillName())
        elseif effect.from:getHandcardNum() < effect.to:getHandcardNum() then
            room:drawCards(effect.from, 1, self:getSkillName())
        end
    end,
}
sakamichi_zi_bi = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_zi_bi",
    view_as = function(self)
        return sakamichi_zi_bi_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_zi_biCard") and player:faceUp()
    end,
}
AsukaSaito:addSkill(sakamichi_zi_bi)

sgs.LoadTranslationTable {
    ["AsukaSaito"] = "齋藤 飛鳥",
    ["&AsukaSaito"] = "齋藤 飛鳥",
    ["#AsukaSaito"] = "神選美少女",
    ["~AsukaSaito"] = "どえせお前うクリスマス過ごす相手いねーだる！",
    ["designer:AsukaSaito"] = "Cassimolar",
    ["cv:AsukaSaito"] = "齋藤 飛鳥",
    ["illustrator:AsukaSaito"] = "Cassimolar",
    ["sakamichi_luo_zu"] = "裸足",
    [":sakamichi_luo_zu"] = "主公技，锁定技，你未装备进攻马/防御马时，其他乃木坂46角色/其他角色计算到其他角色/其他乃木坂46的距离-/+1。",
    ["sakamichi_tian_niao"] = "甜鸟",
    [":sakamichi_tian_niao"] = "你可以将一张红色牌当【杀】使用或打出，若此牌为红桃则此【杀】无法闪避，若此牌为【桃】则此【杀】伤害+1。",
    ["~sakamichi_tian_niao"] = "选择一张红色手牌 → 点击确定",
    ["sakamichi_an_niao"] = "暗鸟",
    [":sakamichi_an_niao"] = "你可以将一张黑色牌当【闪】使用或打出。你的武将牌背面向上时不是【杀】和通常锦囊牌的合法目标。",
    ["~sakamichi_an_niao"] = "选择一张黑色手牌 → 点击确定",
    ["sakamichi_zi_bi"] = "自闭",
    [":sakamichi_zi_bi"] = "出牌阶段限一次，若你的武将牌正面向上，你可以选择一名其他角色，你与其翻面，然后手牌数少的角色摸一张牌。",
}

-- 樋口 日奈
HinaHiguchi = sgs.General(Sakamichi, "HinaHiguchi", "Nogizaka46", 3, false)
SKMC.IKiSei.HinaHiguchi = true
SKMC.SeiMeiHanDan.HinaHiguchi = {
    name = {15, 3, 4, 8},
    ten_kaku = {18, "ji"},
    jin_kaku = {7, "ji"},
    ji_kaku = {12, "xiong"},
    soto_kaku = {23, "ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_ying_yuan_hui = sgs.CreateTriggerSkill {
    name = "sakamichi_ying_yuan_hui",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:canSlash(damage.to, nil, true) then
                    room:askForUseSlashTo(p, damage.to, "@ying_yuan_hui_slash:" .. damage.to:objectName(), true, false)
                end
            end
        end
        return false
    end,
}

HinaHiguchi:addSkill(sakamichi_ying_yuan_hui)

sakamichi_mi_gan = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_gan",
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:isAlive() and p:objectName() ~= player:objectName() and p:canDiscard(p, "h") then
                local card = room:askForDiscard(p, self:objectName(), 1, 1, true, false, "@mi_gan_discard:" .. player:objectName())
                if card then
                    local m = SKMC.number_correction(p, 1)
                    n = n + m
                    SKMC.send_message(room, "#mi_gan", p, player, nil, nil, self:objectName(), m, n)
                    room:addPlayerMark(player, "@mi_gan")
                    data:setValue(n)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaHiguchi:addSkill(sakamichi_mi_gan)

sakamichi_zhi_ming = sgs.CreateTriggerSkill {
    name = "sakamichi_zhi_ming",
    events = {sgs.Damaged, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            local m = SKMC.number_correction(player, 1)
            if damage.from and damage.from:getMark("@mi_gan") ~= 0 and
                room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:" .. damage.from:objectName() .. "::" .. self:objectName() .. ":" .. m)) then
                room:addMaxCards(damage.from, -m)
                room:removePlayerMark(damage.from, "@mi_gan")
                room:setPlayerFlag(damage.from, "zhi_ming_used")
                room:setPlayerMark(player, damage.from:objectName() .. "zhi_ming", 1)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Discard then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("zhi_ming_used") then
                        if p:getHandcardNum() > p:getMaxCards() then
                            for _, pl in sgs.qlist(room:getAlivePlayers()) do
                                if pl:getMark(p:objectName() .. "zhi_ming") ~= 0 then
                                    room:drawCards(pl, 2, self:objectName())
                                    room:setPlayerMark(pl, p:objectName() .. "zhi_ming", 0)
                                end
                            end
                        end
                        room:setPlayerFlag(p, "-zhi_ming_used")
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaHiguchi:addSkill(sakamichi_zhi_ming)

sgs.LoadTranslationTable {
    ["HinaHiguchi"] = "樋口 日奈",
    ["&HinaHiguchi"] = "樋口 日奈",
    ["#HinaHiguchi"] = "和风美人",
    ["~HinaHiguchi"] = "でんちゃんの目が一瞬真っ黒に",
    ["designer:HinaHiguchi"] = "Cassimolar",
    ["cv:HinaHiguchi"] = "樋口 日奈",
    ["illustrator:HinaHiguchi"] = "Cassimolar",
    ["sakamichi_ying_yuan_hui"] = "应援会",
    [":sakamichi_ying_yuan_hui"] = "锁定技，当你使用【杀】造成伤害后，所有可以对目标使用【杀】的其他角色可以对其使用一张【杀】。",
    ["@ying_yuan_hui_slash"] = "你可以对%src 使用一张【杀】",
    ["sakamichi_mi_gan"] = "蜜柑",
    [":sakamichi_mi_gan"] = "其他角色摸牌阶段，你可以弃置一张手牌，令其额定摸牌数+1并获得一枚「蜜柑」标记。",
    ["@mi_gan_discard"] = "你可以弃置一张手牌令%src 额定摸牌数+1",
    ["@mi_gan"] = "蜜柑",
    ["~mi_gan"] = "选择一张手牌 → 点击确定",
    ["#mi_gan"] = "%to 受到了%from的【%arg】的影响，额定摸牌数+%arg2，额定摸牌数为%arg3",
    ["sakamichi_zhi_ming"] = "直名",
    [":sakamichi_zhi_ming"] = "你受到有「蜜柑」的角色造成的伤害后，你可以令其本回合手牌上限-1并移除一枚「蜜柑」，若本回合弃牌阶段开始时，其手牌数不小于手牌上限，你摸两张牌。",
    ["sakamichi_zhi_ming:invoke"] = "是否发动【%arg】令%src 本回合手牌上限-%arg2",
}

-- 岩瀬 佑美子
YumikoIwase = sgs.General(Sakamichi, "YumikoIwase", "Nogizaka46", 3, false)
SKMC.IKiSei.YumikoIwase = true
SKMC.SeiMeiHanDan.YumikoIwase = {
    name = {6, 19, 7, 9, 3},
    ten_kaku = {27, "ji_xiong_hun_he"},
    jin_kaku = {26, "xiong"},
    ji_kaku = {19, "xiong"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {46, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_da_jie = sgs.CreateTriggerSkill {
    name = "sakamichi_da_jie",
    events = {sgs.EventPhaseStart, sgs.MaxHpChanged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local max = 0
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMaxHp() > max then
                    max = p:getMaxHp()
                end
            end
            if player:getMaxHp() ~= max then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:gainMaxHp(player, SKMC.number_correction(player, 1))
                end
            else
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@da_jie_choice:::" .. SKMC.number_correction(player, 1), true)
                    if target then
                        room:recover(target, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                    end
                end
            end
        elseif event == sgs.MaxHpChanged then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:drawCards(player, 1, self:objectName())
                room:askForUseCard(player, "slash", "@askforslash")
            end
        end
        return false
    end,
}
YumikoIwase:addSkill(sakamichi_da_jie)

sakamichi_dian_wan = sgs.CreateTriggerSkill {
    name = "sakamichi_dian_wan",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:isAlive() and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. dying.who:objectName() .. "::" .. SKMC.number_correction(p, 1))) then
                    room:loseMaxHp(p, SKMC.number_correction(p, 1))
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, SKMC.number_correction(p, 1)))
                    room:drawCards(dying.who, 1, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoIwase:addSkill(sakamichi_dian_wan)

sakamichi_yue_tuan = sgs.CreateTriggerSkill {
    name = "sakamichi_yue_tuan",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) and player:getMark("yue_tuan_used") == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:isAlive() and p:canDiscard(p, "h") then
                    if room:askForDiscard(p, self:objectName(), 1, 1, true, false, "@yue_tuan_invoke:" .. player:objectName() .. "::" .. SKMC.number_correction(p, 1)) then
                        room:loseMaxHp(p, SKMC.number_correction(p, 1))
                        room:setPlayerMark(player, "yue_tuan", 1)
                        room:setPlayerMark(player, "yue_tuan" .. p:objectName(), 1)
                        room:setPlayerMark(player, "yue_tuan_used", 1)
                        player:skip(sgs.Player_Play)
                        break
                    end
                end
            end
        elseif change.to == sgs.Player_Discard then
            if player:getMark("yue_tuan") ~= 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getMark("yue_tuan" .. p:objectName()) ~= 0 then
                        room:drawCards(player, 2, self:objectName())
                        if player:isWounded() then
                            room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                        end
                        room:setPlayerMark(player, "yue_tuan" .. p:objectName(), 0)
                    end
                end
                room:setPlayerMark(player, "yue_tuan", 0)
                player:skip(sgs.Player_Discard)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoIwase:addSkill(sakamichi_yue_tuan)

sgs.LoadTranslationTable {
    ["YumikoIwase"] = "岩瀬 佑美子",
    ["&YumikoIwase"] = "岩瀬 佑美子",
    ["#YumikoIwase"] = "歐巴桑",
    ["~YumikoIwase"] = "もうBBAなんて呼ばせねーからな！！",
    ["designer:YumikoIwase"] = "Cassimolar",
    ["cv:YumikoIwase"] = "岩瀬 佑美子",
    ["illustrator:YumikoIwase"] = "Cassimolar",
    ["sakamichi_da_jie"] = "大姐",
    [":sakamichi_da_jie"] = "准备阶段，若你的体力上限不为全场最多，你可以增加1点体力上限；若你的体力上限为全场最多，你可以令一名角色回复1点体力。你的体力上限变化后，你可以摸一张牌并可以使用一张【杀】。",
    ["@da_jie_choice"] = "你可以选择一名其他角色令其回复%arg点体力",
    ["sakamichi_dian_wan"] = "电玩",
    [":sakamichi_dian_wan"] = "当一名角色进入濒死时，你可以失去1点体力上限，然后令其回复1点体力并摸一张牌。",
    ["sakamichi_yue_tuan"] = "乐团",
    [":sakamichi_yue_tuan"] = "每名角色限一次，一名角色出牌阶段开始时，你可以弃置一张手牌并失去1点体力上限令其跳过出牌阶段，若如此做，其摸两张牌并回复1点体力然后跳过弃牌阶段。",
    ["@yue_tuan_invoke"] = "你可以弃置一张手牌并失去%arg点体力上限来跳过%src 的出牌阶段",
}

-- 永島 聖羅
SeiraNagashima = sgs.General(Sakamichi, "SeiraNagashima", "Nogizaka46", 4, false)
SKMC.IKiSei.SeiraNagashima = true
SKMC.SeiMeiHanDan.SeiraNagashima = {
    name = {5, 10, 13, 19},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {23, "ji"},
    ji_kaku = {32, "ji"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

sakamichi_ling_jun = sgs.CreateTriggerSkill {
    name = "sakamichi_ling_jun",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() then
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. damage.damage)) then
                        damage.to = p
                        damage.transfer = true
                        room:damage(damage)
                        room:drawCards(player, p:getLostHp(), self:objectName())
                        return true
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}
SeiraNagashima:addSkill(sakamichi_ling_jun)

sakamichi_sha_xiao = sgs.CreateTriggerSkill {
    name = "sakamichi_sha_xiao",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, damage.damage, self:objectName())
            if not player:isKongcheng() then
                local card = room:askForCard(player, ".|.|.|hand", "@sha_xiao_invoke", data, sgs.Card_MethodNone)
                if card then
                    player:addToPile("sha_xiao", card:getEffectiveId(), true)
                end
            end
        end
        return false
    end,
}
sakamichi_sha_xiao_max_cards = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_sha_xiao_max_cards",
    extra_func = function(self, target)
        if target:hasSkill("sakamichi_sha_xiao") then
            return target:getPile("sha_xiao"):length()
        end
    end,
}
SeiraNagashima:addSkill(sakamichi_sha_xiao)
if not sgs.Sanguosha:getSkill("#sakamichi_sha_xiao_max_cards") then SKMC.SkillList:append(sakamichi_sha_xiao_max_cards) end

sgs.LoadTranslationTable {
    ["SeiraNagashima"] = "永島 聖羅",
    ["&SeiraNagashima"] = "永島 聖羅",
    ["#SeiraNagashima"] = "笑颜满开",
    ["~SeiraNagashima"] = "ふ～ん チューしてぇ",
    ["designer:SeiraNagashima"] = "Cassimolar",
    ["cv:SeiraNagashima"] = "永島 聖羅",
    ["illustrator:SeiraNagashima"] = "Cassimolar",
    ["sakamichi_ling_jun"] = "领军",
    [":sakamichi_ling_jun"] = "其他乃木坂46势力角色受到伤害时，你可以代替其承受此伤害，然后该角色摸X张牌（X为你已损失的体力值）。",
    ["sakamichi_ling_jun:invoke"] = "是否发动【%arg】代替%src 承受此次%arg2点伤害",
    ["sakamichi_sha_xiao"] = "傻笑",
    [":sakamichi_sha_xiao"] = "你受到伤害后，你可以摸等同于伤害量的牌，然后你可以将一张手牌置于你的武将牌上，称为「傻笑」，每有一张「傻笑」，你的手牌上限便＋１。",
    ["@sha_xiao_invoke"] = "你可以将一张手牌置于你的武将牌上称为“傻笑”",
    ["sha_xiao"] = "傻笑",
}

-- 中元 日芽香
HimekaNakamoto = sgs.General(Sakamichi, "HimekaNakamoto", "Nogizaka46", 4, false)
SKMC.IKiSei.HimekaNakamoto = true
SKMC.SeiMeiHanDan.HimekaNakamoto = {
    name = {4, 4, 4, 8, 9},
    ten_kaku = {8, "ji"},
    jin_kaku = {8, "ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {21, "ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_beam_card_1 = sgs.CreateSkillCard {
    name = "sakamichi_beamCard",
    skill_name = "sakamichi_beam",
    target_fixed = false,
    will_throw = true,
    filter = function(self, target, to_select)
        if self:getSubcards():length() == 2 or self:getSubcards():length() == 4 then
            return #target == 0
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if self:getSubcards():length() == 2 then
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to, SKMC.number_correction(effect.from, 1)))
        elseif self:getSubcards():length() == 4 then
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to, SKMC.number_correction(effect.from, 4)))
        end
    end,
}
sakamichi_beam_card_2 = sgs.CreateSkillCard {
    name = "sakamichi_beamCard",
    skill_name = "sakamichi_beam",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to, SKMC.number_correction(effect.from, 1)))
    end,
}
sakamichi_beam = sgs.CreateViewAsSkill {
    name = "sakamichi_beam",
    n = 4,
    view_filter = function(self, selected, to_select)
        if #selected >= 4 then
            return false
        end
        if to_select:isEquipped() then
            return false
        end
        for _, card in ipairs(selected) do
            if card:getSuit() == to_select:getSuit() then
                return false
            end
        end
        return true
    end,
    view_as = function(self, cards)
        if #cards > 4 or #cards < 2 then
            return nil
        end
        if #cards == 2 or #cards == 4 then
            local cd = sakamichi_beam_card_1:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            return cd
        elseif #cards == 3 then
            local cd = sakamichi_beam_card_2:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            return cd
        end
    end,
}
HimekaNakamoto:addSkill(sakamichi_beam)

sakamichi_ku_bi = sgs.CreateMaxCardsSkill {
    name = "sakamichi_ku_bi",
    extra_func = function(self, target)
        if target:hasSkill(self:objectName()) then
            return -1
        end
    end,
}
HimekaNakamoto:addSkill(sakamichi_ku_bi)

sakamichi_wang_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_wang_dao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from and death.damage.from:hasSkill(self:objectName()) then
                room:setPlayerMark(player, "wang_dao", 1)
            end
        elseif event == sgs.DrawNCards then
            if player:hasSkill(self:objectName()) then
                local count = data:toInt()
                data:setValue(count + (player:getMark("wang_dao") * SKMC.number_correction(player, 1)))
            end
        end

    end,
    can_trigger = function(self, target)
        return target
    end,
}

sgs.LoadTranslationTable {
    ["HimekaNakamoto"] = "中元 日芽香",
    ["&HimekaNakamoto"] = "中元 日芽香",
    ["#HimekaNakamoto"] = "小公主",
    ["~HimekaNakamoto"] = "ひめたんビーム",
    ["designer:HimekaNakamoto"] = "Cassimolar",
    ["cv:HimekaNakamoto"] = "中元 日芽香",
    ["illustrator:HimekaNakamoto"] = "Cassimolar",
    ["sakamichi_beam"] = "Beam",
    [":sakamichi_beam"] = "出牌阶段，你可以：弃置两张不同花色的手牌对一名角色造成1点伤害；弃置三张不同花色的手牌对所有角色造成1点伤害；弃置四张不同花色的手牌对一名角色造成4点伤害。",
    ["~sakamichi_beam"] = "选择二到四张不同花色手牌 → 点击确定",
    ["sakamichi_ku_bi"] = "苦逼",
    [":sakamichi_ku_bi"] = "锁定技，你的手牌上限-1。",
    ["sakamichi_wang_dao"] = "王道",
    [":sakamichi_wang_dao"] = "锁定技，每当你杀死一名角色后，你的摸牌阶段额定摸牌数+1。",
}

-- 川村 真洋
MahiroKawamura = sgs.General(Sakamichi, "MahiroKawamura", "Nogizaka46", 3, false)
SKMC.IKiSei.MahiroKawamura = true
SKMC.SeiMeiHanDan.MahiroKawamura = {
    name = {3, 7, 10, 9},
    ten_kaku = {10, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {19, "xiong"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_wu_niang_card = sgs.CreateSkillCard {
    name = "sakamichi_wu_niangCard",
    skill_name = "sakamichi_wu_niang",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:drawCards(effect.to, 2, self:getSkillName())
        if effect.to:getHandcardNum() > effect.to:getMaxHp() then
            effect.to:turnOver()
        end
    end,
}
sakamichi_wu_niang = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_wu_niang",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_wu_niang_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "h") and not player:hasUsed("#sakamichi_wu_niangCard")
    end,
}
MahiroKawamura:addSkill(sakamichi_wu_niang)

sakamichi_ge_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_ge_ji",
    events = {sgs.TurnedOver, sgs.ChainStateChanged},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. SKMC.number_correction(p, 1))) then
                room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MahiroKawamura:addSkill(sakamichi_ge_ji)

sgs.LoadTranslationTable {
    ["MahiroKawamura"] = "川村 真洋",
    ["&MahiroKawamura"] = "川村 真洋",
    ["#MahiroKawamura"] = "关西柴犬",
    ["~MahiroKawamura"] = "髪の毛に神経通ってる",
    ["designer:MahiroKawamura"] = "Cassimolar",
    ["cv:MahiroKawamura"] = "川村 真洋",
    ["illustrator:MahiroKawamura"] = "Cassimolar",
    ["sakamichi_wu_niang"] = "舞娘",
    [":sakamichi_wu_niang"] = "出牌阶段限一次，你可以弃置一张牌，令一名其他角色摸两张牌，然后若其手牌数大于体力上限，其翻面。",
    ["sakamichi_ge_ji"] = "歌姬",
    [":sakamichi_ge_ji"] = "当一名角色武将牌状态改变后，你可以对其造成1点伤害。",
    ["sakamichi_ge_ji:invoke"] = "是否发动【%arg】对%src 造成%arg2点伤害",
}

-- 和田 まあや
MaayaWada = sgs.General(Sakamichi, "MaayaWada", "Nogizaka46", 4, false)
SKMC.IKiSei.MaayaWada = true
SKMC.SeiMeiHanDan.MaayaWada = {
    name = {8, 5, 4, 3, 3},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {9, "xiong"},
    ji_kaku = {10, "xiong"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {23, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_mo_fang = sgs.CreateTriggerSkill {
    name = "sakamichi_mo_fang",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@mo_fang_invoke", true, true)
            if target then
                local mofang_skill_List = {}
                if player:getMark("mo_fang_once") == 0 then
                    for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                        if not skill:isLordSkill() then
                            table.insert(mofang_skill_List, skill:objectName())
                        end
                    end
                else
                    for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                        if not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and not skill:isShiMingSkill() then
                            table.insert(mofang_skill_List, skill:objectName())
                        end
                    end
                end
                local new_Skill = room:askForChoice(player, self:objectName(), table.concat(mofang_skill_List, "+"))
                SKMC.choice_log(player, new_Skill)
                local Skill_list = {}
                local old_Skill = player:getTag("mo_fang_skill"):toString()
                if old_Skill ~= "" then
                    table.insert(Skill_list, "-" .. old_Skill)
                end
                if new_Skill ~= "" then
                    local skill = sgs.Sanguosha:getSkill(new_Skill)
                    if skill:getFrequency() == sgs.Skill_Wake or skill:getFrequency() == sgs.Skill_Limited or skill:isShiMingSkill() then
                        room:setPlayerMark(player, "mo_fang_once", 1)
                    end
                    player:setTag("mo_fang_skill", sgs.QVariant(new_Skill))
                    table.insert(Skill_list, new_Skill)
                end
                room:handleAcquireDetachSkills(player, table.concat(Skill_list, "|"), true)
            end
        end
    end,
}
MaayaWada:addSkill(sakamichi_mo_fang)

sakamichi_ma_ya_card = sgs.CreateSkillCard {
    name = "sakamichi_ma_yaCard",
    skill_name = "sakamichi_ma_ya",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            for _, skill in sgs.qlist(to_select:getVisibleSkillList()) do
                if (skill:getFrequency() == sgs.Skill_Limited and to_select:getMark(skill:getLimitMark()) == 0) or
                    (skill:getFrequency() == sgs.Skill_Wake and to_select:getMark(skill:objectName()) == 0) or
                    (skill:isShiMingSkill() and to_select:getMark(skill:objectName()) == 0) then
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@maya")
        local skill_names = {}
        for _, skill in sgs.qlist(effect.to:getVisibleSkillList()) do
            if (skill:getFrequency() == sgs.Skill_Limited and effect.to:getMark(skill:getLimitMark()) == 0) or
                (skill:getFrequency() == sgs.Skill_Wake and effect.to:getMark(skill:objectName()) == 0) or
                (skill:isShiMingSkill() and effect.to:getMark(skill:objectName()) == 0) then
                table.insert(skill_names, skill:objectName())
            end
        end
        local skill_name = room:askForChoice(effect.from, self:getSkillName(), table.concat(skill_names, "+"))
        SKMC.choice_log(effect.from, skill_name)
        local skill = sgs.Sanguosha:getSkill(skill_name)
        if skill:getFrequency() == sgs.Skill_Limited then
            room:setPlayerMark(effect.to, skill:getLimitMark(), 1)
        elseif skill:getFrequency() == sgs.Skill_Wake then
            effect.to:setCanWake(self:getSkillName(), skill:objectName())
        elseif skill:isShiMingSkill() then
            room:sendShimingLog(effect.to, skill)
        end
    end,
}
sakamichi_ma_ya = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ma_ya",
    frequency = sgs.Skill_Limited,
    limit_mark = "@maya",
    view_as = function(self)
        return sakamichi_ma_ya_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@maya") ~= 0
    end,
}
MaayaWada:addSkill(sakamichi_ma_ya)

sgs.LoadTranslationTable {
    ["MaayaWada"] = "和田 まあや",
    ["&MaayaWada"] = "和田 まあや",
    ["#MaayaWada"] = "笨蛋天才",
    ["~MaayaWada"] = "天才とは、1％のひらめきと99％の運",
    ["designer:MaayaWada"] = "Cassimolar",
    ["cv:MaayaWada"] = "和田 まあや",
    ["illustrator:MaayaWada"] = "Cassimolar",
    ["sakamichi_mo_fang"] = "模仿",
    [":sakamichi_mo_fang"] = "准备阶段，你可以选择一名其他角色并获得其一个武将技能（主公技除外）直到你下次选择，你以此法仅可以获得一次限定技、觉醒技、使命技。",
    ["@mo_fang_invoke"] = "你可以选择一名其他角色获得其一个武将技能",
    ["sakamichi_ma_ya"] = "妈呀",
    [":sakamichi_ma_ya"] = "限定技，出牌阶段，你可以选择一名拥有已发动过限定技或未觉醒的觉醒技的角色，令其一个已发动过限定技视为未曾发动或未觉醒的觉醒技视为满足觉醒条件。",
    ["@maya"] = "妈呀",
}

-- 畠中 清羅
SeiraHatanaka = sgs.General(Sakamichi, "SeiraHatanaka", "Nogizaka46", 3, false)
SKMC.IKiSei.SeiraHatanaka = true
SKMC.SeiMeiHanDan.SeiraHatanaka = {
    name = {10, 4, 11, 19},
    ten_kaku = {14, "xiong"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {30, "ji_xiong_hun_he"},
    soto_kaku = {29, "te_shu_ge"},
    sou_kaku = {44, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_bu_liang = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_liang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:hasSkill(self:objectName()) and death.damage and death.damage.from and room:askForSkillInvoke(death.who, self:objectName(), data) then
                room:drawCards(death.damage.from, 3, self:objectName())
            end
        elseif event == sgs.Damage then
            if player:hasSkill(self:objectName()) then
                local damage = data:toDamage()
                if damage.to:objectName() ~= player:objectName() and not damage.to:isAllNude() then
                    local card = room:askForCardChosen(player, damage.to, "hej", self:objectName())
                    local unhide = room:getCardPlace(card) ~= sgs.Player_PlaceHand
                    room:obtainCard(player, card, unhide)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SeiraHatanaka:addSkill(sakamichi_bu_liang)

sakamichi_bao_dan = sgs.CreateTriggerSkill {
    name = "sakamichi_bao_dan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local response = data:toCardResponse()
        if response.m_card:isKindOf("Jink") and room:askForSkillInvoke(player, self:objectName(), data) then
            room:askForUseCard(player, "Slash", "@askforslash")
        end
        return false
    end,
}
SeiraHatanaka:addSkill(sakamichi_bao_dan)

sgs.LoadTranslationTable {
    ["SeiraHatanaka"] = "畠中 清羅",
    ["&SeiraHatanaka"] = "畠中 清羅",
    ["#SeiraHatanaka"] = "自我主张",
    ["~SeiraHatanaka"] = "人生黙ったう終わり。",
    ["designer:SeiraHatanaka"] = "Cassimolar",
    ["cv:SeiraHatanaka"] = "畠中 清羅",
    ["illustrator:SeiraHatanaka"] = "Cassimolar",
    ["sakamichi_bu_liang"] = "不良",
    [":sakamichi_bu_liang"] = "锁定技，杀死你的角色摸三张牌，你对其他角色造成伤害后获得其区域内的一张牌。",
    ["sakamichi_bao_dan"] = "爆弹",
    [":sakamichi_bao_dan"] = "当你使用或打出【闪】后，你可以使用一张【杀】。",
}

-- 能條 愛未
AmiNoujo = sgs.General(Sakamichi, "AmiNoujo", "Nogizaka46", 3, false)
SKMC.IKiSei.AmiNoujo = true
SKMC.SeiMeiHanDan.AmiNoujo = {
    name = {10, 11, 13, 5},
    ten_kaku = {21, "ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_shuo_chang = sgs.CreateTriggerSkill {
    name = "sakamichi_shuo_chang",
    frequency = sgs.Skill_Compulsory,
    change_skill = true,
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                room:setChangeSkillState(player, self:objectName(), 1)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isNDTrick() then
                if player:hasFlag("shuo_chang_trick") then
                    room:setPlayerMark(player, "&shuo_chang_trick_finish_end_claer", 0)
                    room:setPlayerFlag(player, "-shuo_chang_trick")
                    room:drawCards(player, 1, self:objectName())
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
                if player:getChangeSkillState(self:objectName()) == 1 then
                    room:setChangeSkillState(player, self:objectName(), 2)
                    room:setPlayerFlag(player, "shuo_chang_basic")
                    room:addPlayerMark(player, "shuo_chang_count_finish_end_clear")
                    room:setPlayerMark(player, "&shuo_chang_basic_finish_end_claer", 1)
                    if player:hasFlag("fa_ze_used") then
                        room:setPlayerFlag(player, "-fa_ze_used")
                    end
                end
            end
            if use.card:isKindOf("BasicCard") then
                if player:getChangeSkillState(self:objectName()) == 2 then
                    room:setChangeSkillState(player, self:objectName(), 1)
                    room:setPlayerFlag(player, "shuo_chang_trick")
                    room:addPlayerMark(player, "shuo_chang_count_finish_end_clear")
                    room:setPlayerMark(player, "&shuo_chang_trick_finish_end_claer", 1)
                    if player:hasFlag("fa_ze_used") then
                        room:setPlayerFlag(player, "-fa_ze_used")
                    end
                end
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if player:hasFlag("shuo_chang_basic") then
                room:setPlayerMark(player, "&shuo_chang_basic_finish_end_claer", 0)
                room:setPlayerFlag(player, "-shuo_chang_basic")
                room:setCardFlag(use.card, "RemoveFromHistory")
            end
        end
        return false
    end,
}
sakamichi_shuo_chang_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_shuo_chang_mod",
    pattern = "BasicCard",
    distance_limit_func = function(self, from, card, to)
        if from:hasFlag("shuo_chang_basic") then
            return 1000
        else
            return 0
        end
    end,
}
AmiNoujo:addSkill(sakamichi_shuo_chang)
if not sgs.Sanguosha:getSkill("#sakamichi_shuo_chang_mod") then SKMC.SkillList:append(sakamichi_shuo_chang_mod) end

sakamichi_jiao_sang = sgs.CreateTriggerSkill {
    name = "sakamichi_jiao_sang",
    frequency = sgs.Skill_Wake,
    waked_skill = "sakamichi_fa_ze",
    events = {sgs.EventPhaseProceeding},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPhase() == sgs.Player_Finish and player:getMark("shuo_chang_count_finish_end_clear") >= 5 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerMark(player, self:objectName(), 1)
        room:handleAcquireDetachSkills(player, "sakamichi_fa_ze")
    end,
}
AmiNoujo:addSkill(sakamichi_jiao_sang)

sakamichi_fa_ze_card = sgs.CreateSkillCard {
    name = "sakamichi_fa_zeCard",
    skill_name = "sakamichi_fa_ze",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:getSkillName(), ""))
        room:broadcastSkillInvoke("@recast")
        SKMC.send_message(room, "#UseCard_Recast", source, nil, nil, nil, self:getSubcards():first():toString())
        room:drawCards(source, 1, "recast")
        room:setPlayerFlag(source, "fa_ze_used")
    end,
}
sakamichi_fa_ze = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_fa_ze",
    filter_pattern = ".",
    view_as = function(self, card)
        local cd = sakamichi_fa_ze_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("fa_ze_used")
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_fa_ze") then SKMC.SkillList:append(sakamichi_fa_ze) end

sgs.LoadTranslationTable {
    ["AmiNoujo"] = "能條 愛未",
    ["&AmiNoujo"] = "能條 愛未",
    ["#AmiNoujo"] = "舞台大佬",
    ["~AmiNoujo"] = "あみあみハリケーン",
    ["designer:AmiNoujo"] = "Cassimolar",
    ["cv:AmiNoujo"] = "能條 愛未",
    ["illustrator:AmiNoujo"] = "Cassimolar",
    ["sakamichi_shuo_chang"] = "说唱",
    [":sakamichi_shuo_chang"] = "锁定技，准备阶段，本技能重置为①。转换技，出牌阶段，①你使用通常锦囊牌时，本回合你使用的下一张基本牌无距离限制且不计入次数限制；②你使用基本牌时，本回合内你使用的下一张通常锦囊牌无法响应且摸一张牌。",
    ['shuo_chang_basic_finish_end_claer'] = "基本牌不计入次数",
    ['shuo_chang_trick_finish_end_claer'] = "通常锦囊牌无法响应",
    ["sakamichi_jiao_sang"] = "脚桑",
    [":sakamichi_jiao_sang"] = "觉醒技，结束阶段，若你回合内发动【说唱】至少五次，你增加1点体力上限并获得【法则】。",
    ["sakamichi_fa_ze"] = "法则",
    [":sakamichi_fa_ze"] = "出牌阶段限一次，你可以重铸一张牌，当你发动【说唱】时，此技能视为未曾发动。",
}

-- 山本 穂乃香
HonokaYamamoto = sgs.General(Sakamichi, "HonokaYamamoto", "Nogizaka46", 3, false)
SKMC.IKiSei.HonokaYamamoto = true
SKMC.SeiMeiHanDan.HonokaYamamoto = {
    name = {3, 5, 15, 2, 9},
    ten_kaku = {8, "ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {26, "xiong"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {34, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "shui",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zheng_xian = sgs.CreateTriggerSkill {
    name = "sakamichi_zheng_xian",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.TurnStart},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:objectName() ~= player:objectName() and p:faceUp() and room:askForSkillInvoke(p, self:objectName(), data) then
                p:turnOver()
                local tag = room:getTag("zheng_xian")
                if tag then
                    local pl = tag:toPlayer()
                    if not pl then
                        tag:setValue(player)
                        room:setTag("zheng_xian", tag)
                        player:gainMark("@zhengxian")
                    end
                end
                room:setCurrent(p)
                p:play()
                return true
            end
        end
        local tag = room:getTag("zheng_xian")
        if tag then
            local p = tag:toPlayer()
            if p and not player:hasFlag("isExtraTurn") then
                p:loseMark("@zhengxian")
                room:setCurrent(p)
                room:setTag("zheng_xian", sgs.QVariant())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HonokaYamamoto:addSkill(sakamichi_zheng_xian)

sakamichi_kang_zheng_card = sgs.CreateSkillCard {
    name = "sakamichi_kang_zhengCard",
    skill_name = "sakamichi_kang_zheng",
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:canSlash(to_select, nil, false)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:turnOver()
        local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        card:deleteLater()
        card:setSkillName(self:getSkillName())
        room:useCard(sgs.CardUseStruct(card, effect.from, effect.to))
    end,
}
sakamichi_kang_zheng_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_kang_zheng",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_kang_zheng_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_kang_zheng")
    end,
}
sakamichi_kang_zheng = sgs.CreateTriggerSkill {
    name = "sakamichi_kang_zheng",
    view_as_skill = sakamichi_kang_zheng_view_as,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if not player:faceUp() and not player:isKongcheng() then
            room:askForUseCard(player, "@@sakamichi_kang_zheng", "@kang_zheng_invoke", -1, sgs.Card_MethodDiscard, false)
        end
    end,
}
HonokaYamamoto:addSkill(sakamichi_kang_zheng)

sgs.LoadTranslationTable {
    ["HonokaYamamoto"] = "山本 穂乃香",
    ["&HonokaYamamoto"] = "山本 穂乃香",
    ["#HonokaYamamoto"] = "童星陨落",
    ["~HonokaYamamoto"] = "",
    ["designer:HonokaYamamoto"] = "Cassimolar",
    ["cv:HonokaYamamoto"] = "山本 穂乃香",
    ["illustrator:HonokaYamamoto"] = "Cassimolar",
    ["sakamichi_zheng_xian"] = "争先",
    [":sakamichi_zheng_xian"] = "其他角色的回合开始前，若你的武将牌正面向上，你可以翻面并执行一个额外的回合，此回合结束后，进入该角色的回合。",
    ["@zhenxian"] = "争先",
    ["sakamichi_kang_zheng"] = "抗争",
    [":sakamichi_kang_zheng"] = "当你的武将牌背面向上时受到伤害后，你可以翻面并弃置一张手牌视为对一名其他角色使用一张【杀】。",
    ["@kang_zheng_invoke"] = "你可以弃置一张手牌视为对一名其他角色使用一张【杀】",
    ["~sakamichi_kang_zheng"] = "选择一张手牌 → 选择一名其他角色 → 点击确定",
}

-- 渡辺 みり愛
MiriaWatanabe = sgs.General(Sakamichi, "MiriaWatanabe", "Nogizaka46", 3, false)
SKMC.NiKiSei.MiriaWatanabe = true
SKMC.SeiMeiHanDan.MiriaWatanabe = {
    name = {12, 5, 3, 2, 13},
    ten_kaku = {17, "ji"},
    jin_kaku = {8, "ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_cheng_shu_card = sgs.CreateSkillCard {
    name = "sakamichi_cheng_shuCard",
    skill_name = "sakamichi_cheng_shu",
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark("cheng_shu")
    end,
    feasible = function(self, targets)
        return #targets > 0 and #targets <= sgs.Self:getMark("cheng_shu")
    end,
    on_use = function(self, room, source, targets)
        for _, p in pairs(targets) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
        local choices = {"cheng_shu_1"}
        local all_nude = false
        for _, p in pairs(targets) do
            if p:isAllNude() then
                all_nude = true
            end
        end
        if not all_nude then
            table.insert(choices, "cheng_shu_2")
        end
        local choice = room:askForChoice(source, self:getSkillName(), table.concat(choices, "+"))
        SKMC.choice_log(source, choice)
        for _, p in pairs(targets) do
            if choice == "cheng_shu_1" then
                room:drawCards(p, 1, self:getSkillName())
            else
                local id = room:askForCardChosen(source, p, "hej", self:getSkillName(), false, sgs.Card_MethodDiscard)
                room:throwCard(id, p, source)
            end
        end
        room:setPlayerMark(source, "cheng_shu", 0)
    end,
}
sakamichi_cheng_shu_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_cheng_shu",
    view_as = function(self, cards)
        return sakamichi_cheng_shu_card:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_cheng_shu")
    end,
}
sakamichi_cheng_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_cheng_shu",
    frequency = sgs.Skill_Compulsory,
    view_as_skill = sakamichi_cheng_shu_view_as,
    events = {sgs.CardEffected, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("DelayedTrick") then
                SKMC.send_message(room, "#cheng_shu", player, nil, nil, effect.card:toString(), self:objectName())
                return true
            end
        elseif player:getPhase() == sgs.Player_Discard then
            if event == sgs.CardsMoveOneTime then
                local move = data:toMoveOneTime()
                if move.to_place == sgs.Player_DiscardPile then
                    if move.from and move.from:objectName() == player:objectName() and
                        bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
                        room:addPlayerMark(player, "cheng_shu", move.card_ids:length())
                    end
                end
            elseif event == sgs.EventPhaseEnd then
                if player:getMark("cheng_shu") > 0 then
                    room:askForUseCard(player, "@@sakamichi_cheng_shu", "@cheng_shu_choice:::" .. self:objectName(), -1, sgs.Card_MethodUse)
                end
            end
        end
        return false
    end,
}
MiriaWatanabe:addSkill(sakamichi_cheng_shu)

sakamichi_da_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_da_shi",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and not use.to:contains(p) then
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        if p:isWounded() then
                            room:recover(p, sgs.RecoverStruct(player, use.card, SKMC.number_correction(p, 1)))
                        else
                            room:drawCards(p, 1, self:objectName())
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MiriaWatanabe:addSkill(sakamichi_da_shi)

sgs.LoadTranslationTable {
    ["MiriaWatanabe"] = "渡辺 みり愛",
    ["&MiriaWatanabe"] = "渡辺 みり愛",
    ["#MiriaWatanabe"] = "假萝莉",
    ["~MiriaWatanabe"] = "100万人の人に愛されたい",
    ["designer:MiriaWatanabe"] = "Cassimolar",
    ["cv:MiriaWatanabe"] = "渡辺 みり愛",
    ["illustrator:MiriaWatanabe"] = "Cassimolar",
    ["sakamichi_cheng_shu"] = "成熟",
    [":sakamichi_cheng_shu"] = "锁定技，延时类锦囊对你无效。弃牌阶段结束时，你可以选择：令至多X名角色各摸一张牌；分别弃置至多X名区域内有牌的角色区域内的一张牌（X为你本阶段弃牌数）。",
    ["#cheng_shu"] = "%from 的【%arg】被触发，【%card】对 %from 无效",
    ["@cheng_shu_choice"] = "请选择发动【%arg】的目标",
    ["~sakamichi_cheng_shu"] = "选择若干名角色 → 点击确定",
    ["cheng_shu_1"] = "令这些角色各摸一张牌",
    ["cheng_shu_2"] = "分别弃置这些角色各一张牌",
    ["sakamichi_da_shi"] = "大食",
    [":sakamichi_da_shi"] = "其他角色使用【桃】时，若目标不包含你且你：已受伤，你可以回复1点体力；未受伤，你可以摸一张牌。",
}

-- 新内 眞衣
MaiShinnuchi = sgs.General(Sakamichi, "MaiShinnuchi", "Nogizaka46", 4, false)
SKMC.NiKiSei.MaiShinnuchi = true
SKMC.SeiMeiHanDan.MaiShinnuchi = {
    name = {13, 4, 10, 6},
    ten_kaku = {17, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_dao_shui = sgs.CreateTriggerSkill {
    name = "sakamichi_dao_shui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.SlashMissed},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toSlashEffect()
        local card
        if not player:getDefensiveHorse() and effect.to:getDefensiveHorse() then
            card = effect.to:getDefensiveHorse()
        end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:" .. effect.to:objectName() .. "::" .. self:objectName() .. ":" .. card:toString())) then
            room:obtainCard(player, card, true)
        end
        card = nil
        if not player:getOffensiveHorse() and effect.to:getOffensiveHorse() then
            card = effect.to:getOffensiveHorse()
        end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:" .. effect.to:objectName() .. "::" .. self:objectName() .. ":" .. card:toString())) then
            room:obtainCard(player, card, true)
        end
    end,
}
MaiShinnuchi:addSkill(sakamichi_dao_shui)

sakamichi_chang_tui_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_chang_tui_target_mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Slash",
    extra_target_func = function(self, player, card)
        if player:hasSkill("sakamichi_chang_tui") then
            return player:getMark("&" .. "sakamichi_chang_tui")
        else
            return 0
        end
    end,
}
sakamichi_chang_tui = sgs.CreateTriggerSkill {
    name = "sakamichi_chang_tui",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Horse") then
            room:addPlayerMark(player, "&" .. self:objectName(), 1)
        end
        return false
    end,
}
MaiShinnuchi:addSkill(sakamichi_chang_tui)
if not sgs.Sanguosha:getSkill("#sakamichi_chang_tui_target_mod") then SKMC.SkillList:append(sakamichi_chang_tui_target_mod) end

sgs.LoadTranslationTable {
    ["MaiShinnuchi"] = "新内 眞衣",
    ["&MaiShinnuchi"] = "新内 眞衣",
    ["#MaiShinnuchi"] = "零期生",
    ["~MaiShinnuchi"] = "OL、アイドル  明日からもよろしくお願いします！",
    ["designer:MaiShinnuchi"] = "Cassimolar",
    ["cv:MaiShinnuchi"] = "新内 眞衣",
    ["illustrator:MaiShinnuchi"] = "Cassimolar",
    ["sakamichi_dao_shui"] = "盗水",
    [":sakamichi_dao_shui"] = "当你使用的【杀】被闪避时，若目标装备区有坐骑牌，且你对应区域无坐骑牌，你可以获得之。",
    ["sakamichi_dao_shui:invoke"] = "是否发动【%arg】获得%src 的【%arg2】",
    ["sakamichi_chang_tui"] = "长腿",
    [":sakamichi_chang_tui"] = "锁定技，你使用的【杀】可以多指定X个目标（X为你使用过的坐骑牌数）。",
}

-- 北野 日奈子
HinakoKitano = sgs.General(Sakamichi, "HinakoKitano", "Nogizaka46", 4, false)
SKMC.NiKiSei.HinakoKitano = true
SKMC.SeiMeiHanDan.HinakoKitano = {
    name = {5, 11, 4, 8, 3},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

sakamichi_guai_li = sgs.CreateTriggerSkill {
    name = "sakamichi_guai_li",
    events = {sgs.DrawNCards, sgs.EventPhaseChanging, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            local count = data:toInt()
            if room:askForSkillInvoke(player, self:objectName(), data) then
                count = count + 1
                room:setPlayerFlag(player, self:objectName())
                room:setPlayerMark(player, self:objectName(), 1)
                data:setValue(count)
                SKMC.send_message(room, "#guai_li_draw", player)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) and player:getMark(self:objectName()) ~= 0 then
                SKMC.send_message(room, "#guai_li_skip", player, nil, nil, nil, self:objectName())
                player:skip(sgs.Player_Draw)
                room:setPlayerMark(player, self:objectName(), 0)
            end
        elseif event == sgs.DamageCaused and player:hasFlag(self:objectName()) then
            local damage = data:toDamage()
            if damage.chain or damage.transfer or (not damage.by_user) then
                return false
            end
            local reason = damage.card
            if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
                local n = SKMC.number_correction(player, 1)
                SKMC.send_message(room, "#guai_li_damage", player, damage.to, nil, nil, self:objectName(), n, damage.damage)
                damage.damage = damage.damage + n
                data:setValue(damage)
            end
            return false
        end
    end,
}
HinakoKitano:addSkill(sakamichi_guai_li)

sakamichi_si_guo_card = sgs.CreateSkillCard {
    name = "sakamichi_si_guoCard",
    skill_name = "sakamichi_si_guo",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@siguo")
        if source:hasEquipArea(0) then
            source:throwEquipArea(0)
            local choices = {"si_guo_1", "si_guo_2", "si_guo_3", "si_guo_4", "si_guo_5", "si_guo_6"}
            local choice1 = room:askForChoice(source, self:getSkillName(), table.concat(choices, "+"))
            table.removeOne(choices, choice1)
            table.insert(choices, "cancel")
            local choice2 = room:askForChoice(source, self:getSkillName(), table.concat(choices, "+"))
            if choice2 ~= "cancel" then
                SKMC.send_message(room, "#si_guo_choice_2", source, nil, nil, nil, choice1, choice2)
                room:setPlayerFlag(source, choice1)
                room:setPlayerFlag(source, choice2)
            else
                SKMC.send_message(room, "#si_guo_choice", source, nil, nil, nil, choice1)
                room:setPlayerMark(source, choice1, 1)
            end
        end
    end,
}
sakamichi_si_guo_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_si_guo",
    filter_pattern = "Weapon",
    view_as = function(self, card)
        local cd = sakamichi_si_guo_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@siguo") ~= 0
    end,
}
sakamichi_si_guo = sgs.CreateTriggerSkill {
    name = "sakamichi_si_guo",
    frequency = sgs.Skill_Limited,
    limit_mark = "@siguo",
    view_as_skill = sakamichi_si_guo_view_as,
    events = {sgs.CardUsed, sgs.DamageCaused, sgs.SlashProceed, sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and (player:hasFlag("si_guo_3") or player:getMark("si_guo_3") ~= 0) then
                room:setCardFlag(use.card, "SlashIgnoreArmor")
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and (player:hasFlag("si_guo_4") or player:getMark("si_guo_4") ~= 0) then
                damage.damage = damage.damage + SKMC.number_correction(player, 1)
                data:setValue(damage)
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasFlag("si_guo_5") or effect.from:getMark("si_guo_5") ~= 0 then
                room:slashResult(effect, nil)
                return true
            end
        else
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and (player:hasFlag("si_guo_6") or player:getMark("si_guo_6") ~= 0) then
                for _, p in sgs.qlist(use.to) do
                    if not p:isNude() then
                        local id = room:askForCardChosen(use.from, use.to, "he", self:objectName(), false, sgs.Card_MethodDiscard, sgs.IntList(), true)
                        if id ~= -1 then
                            room:throwCard(id, p, player)
                        else
                            room:drawCards(player, 1, self:objectName())
                        end
                    else
                        room:drawCards(player, 1, self:objectName())
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_si_guo_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_si_guo_target_mod",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasFlag("si_guo_2") or from:getMark("si_guo_2") ~= 0 then
            return 1000
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasFlag("si_guo_1") or from:getMark("si_guo_1") ~= 0 then
            return 1000
        else
            return 0
        end
    end,
}
HinakoKitano:addSkill(sakamichi_si_guo)
if not sgs.Sanguosha:getSkill("#sakamichi_si_guo_target_mod") then SKMC.SkillList:append(sakamichi_si_guo_target_mod) end

sgs.LoadTranslationTable {
    ["HinakoKitano"] = "北野 日奈子",
    ["&HinakoKitano"] = "北野 日奈子",
    ["#HinakoKitano"] = "爆彈少女",
    ["~HinakoKitano"] = "うざい！ちね！",
    ["designer:HinakoKitano"] = "Cassimolar",
    ["cv:HinakoKitano"] = "北野 日奈子",
    ["illustrator:HinakoKitano"] = "Cassimolar",
    ["sakamichi_guai_li"] = "怪力",
    [":sakamichi_guai_li"] = "摸牌阶段，你可以多摸一张牌，本回合内你使用的【杀】和【决斗】造成伤害时，伤害+1，若如此做，跳过你的下一个摸牌阶段。",
    ["#guai_li_draw"] = "本回合内 %from 使用的【杀】和【决斗】（ %from 为伤害来源时）造成的伤害+<font color=\"yellow\"><b>1</b></font>",
    ["#guai_li_skip"] = "%from 的【%arg】被触发",
    ["#guai_li_damage"] = "%from 的【%arg】被触发，%to 此次受到的伤害+<font color=\"yellow\"><b>%arg2</b></font>, 此次伤害为<font color=\"yellow\"><b>%arg3</b></font>点",
    ["sakamichi_si_guo"] = "撕锅",
    [":sakamichi_si_guo"] = "限定技，出牌阶段，若你有武器栏，你可以弃置一张武器牌并废除武器栏然后选择，使用【杀】：无距离限制；无次数限制；无视防具；造成的伤害+1；无法闪避；指定目标时可以弃置其一张牌或摸一张牌。选择一个效果于本局游戏剩余时间内生效或选择两个效果本回合内生效。",
    ["si_guo_1"] = "使用【杀】无距离限制",
    ["si_guo_2"] = "使用【杀】无次数限制",
    ["si_guo_3"] = "使用【杀】无视防具",
    ["si_guo_4"] = "使用【杀】造成的伤害+1",
    ["si_guo_5"] = "使用【杀】无法闪避",
    ["si_guo_6"] = "使用【杀】指定目标后弃置其一张牌或摸一张牌",
    ["#si_guo_choice_1"] = "%from选择了本局游戏剩余时间内%arg",
    ["#si_guo_choice_2"] = "%from选择了本回合内%arg和%arg2",
}

-- 堀 未央奈
MionaHori = sgs.General(Sakamichi, "MionaHori$", "Nogizaka46", 3, false)
SKMC.NiKiSei.MionaHori = true
SKMC.SeiMeiHanDan.MionaHori = {
    name = {11, 5, 5, 8},
    ten_kaku = {11, "ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fa_jia = sgs.CreateTriggerSkill {
    name = "sakamichi_fa_jia$",
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and SKMC.has_specific_kingdom_player(player) then
            local list = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == player:getKingdom() then
                    list:append(p)
                end
            end
            local target = room:askForPlayerChosen(player, list, self:objectName(), "@fa_jia_invoke:::" .. self:objectName())
            if target then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("fa_jia" .. player:objectName()) ~= 0 then
                        room:removePlayerMark(p, "@fa_jia_target", 1)
                        room:setPlayerMark(p, "fa_jia" .. player:objectName(), 0)
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if string.find(mark, "&" .. self:objectName() .. "+") then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                    end
                end
                room:addPlayerMark(target, "@fa_jia_target", 1)
                room:setPlayerMark(target, "fa_jia" .. player:objectName(), 1)
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, self:objectName()) and player:getMark(mark) ~= 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
                if target:getArmor() then
                    room:setPlayerMark(player, "&" .. self:objectName() .. "+ +noarmor+ +" .. target:getArmor():objectName(), 1)
                end
                for _, mark in sgs.list(target:getMarkNames()) do
                    if string.find(mark, self:objectName()) and target:getMark(mark) ~= 0 then
                        room:setPlayerMark(target, mark, 0)
                    end
                end
                if player:getArmor() then
                    room:setPlayerMark(target, "&" .. self:objectName() .. "+ +noarmor+ +" .. player:getArmor():objectName(), 1)
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip) or
                (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip))) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("fa_jia" .. player:objectName()) ~= 0 or player:getMark("fa_jia" .. p:objectName()) ~= 0 then
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if string.find(mark, self:objectName()) and p:getMark(mark) ~= 0 then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                        if player:getArmor() then
                            room:setPlayerMark(p, "&" .. self:objectName() .. "+ +noarmor+ +" .. player:getArmor():objectName(), 1)
                        end
                    end
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:hasSkill(self:objectName()) or death.who:getMark("@fa_jia_target") ~= 0 then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("fa_jia" .. death.who:objectName()) ~= 0 or death.who:getMark("fa_jia" .. p:objectName()) ~= 0 then
                        room:setPlayerMark(p, "fa_jia" .. death.who:objectName(), 0)
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if string.find(mark, self:objectName()) and p:getMark(mark) ~= 0 then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                        if p:getMark("@fa_jia_target") ~= 0 then
                            room:removePlayerMark(p, "@fa_jia_target", 1)
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MionaHori:addSkill(sakamichi_fa_jia)

sakamichi_kuang_xiao = sgs.CreateTriggerSkill {
    name = "sakamichi_kuang_xiao",
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local choices = {}
        if player:isWounded() then
            table.insert(choices, "kuang_xiao_1==" .. damage.damage)
        end
        if not damage.to:isAllNude() then
            table.insert(choices, "kuang_xiao_2=" .. damage.to:objectName())
        end
        if #choices ~= 0 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                if choice == "kuang_xiao_1==" .. damage.damage then
                    room:recover(player, sgs.RecoverStruct(player, damage.card, damage.damage))
                elseif choice == "kuang_xiao_2=" .. damage.to:objectName() then
                    if (damage.to:getEquips():length() + damage.to:getHandcardNum() + damage.to:getJudgingArea():length()) > 2 then
                        for i = 1, 2, 1 do
                            local id = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
                            room:throwCard(id, damage.to, player)
                        end
                    else
                        damage.to:throwAllCards()
                    end
                    room:setEmotion(damage.to, "skill_nullify")
                    return true
                end
            end
        end
        return false
    end,
}
MionaHori:addSkill(sakamichi_kuang_xiao)

sakamichi_sang_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_sang_shi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@sangshi",
    events = {sgs.TurnedOver, sgs.EnterDying},
    on_trigger = function(self, event, player, data ,room)
        local can = true
        if event == sgs.TurnedOver then
            if not player:faceUp() then
                can = false
            end
        end
        if can and player:getMark("@sangshi") ~= 0 and not player:isLord() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:removePlayerMark(player, "@sangshi")
                if not player:isAllNude() then
                    local n = player:getCards("hej"):length()
                    player:throwAllCards()
                    room:drawCards(player, n, self:objectName())
                end
                local is_secondary_hero = not (sgs.Sanguosha:getGeneral(player:getGeneralName()):hasSkill(self:objectName()))
                room:changeHero(player, "minorimorozumi", false, false, is_secondary_hero)
                room:recover(player, sgs.RecoverStruct(player, nil, player:getMaxHp() - player:getHp()))
            end
        end
        return false
    end,
}
MionaHori:addSkill(sakamichi_sang_shi)

sgs.LoadTranslationTable {
    ["MionaHori"] = "堀 未央奈",
    ["&MionaHori"] = "堀 未央奈",
    ["#MionaHori"] = "谜之美少女",
    ["~MionaHori"] = "みんなより5秒くらい早く起きた",
    ["designer:MionaHori"] = "Cassimolar",
    ["cv:MionaHori"] = "堀 未央奈",
    ["illustrator:MionaHori"] = "Cassimolar",
    ["sakamichi_fa_jia"] = "发夹",
    ["#Luafajia_Armor"] = "发夹",
    [":sakamichi_fa_jia"] = "主公技，结束阶段，你可以选择一名与你势力相同的其他角色，直到你下次选择，你与其未装备防具的一方视为装备另一方装备区的防具。",
    ["@fa_jia_invoke"] = "你可以选择一名势力与你相同的角色发动【%arg】",
    ["sakamichi_kuang_xiao"] = "狂笑",
    [":sakamichi_kuang_xiao"] = "当你造成伤害时，你可以回复等量的体力值或防止该伤害然后弃置该角色区域内的两张牌。",
    ["kuang_xiao_1"] = "回复%arg点体力",
    ["kuang_xiao_2"] = "弃置%src区域内的两张牌",
    ["sakamichi_sang_shi"] = "丧尸",
    [":sakamichi_sang_shi"] = "限定技，当你武将牌翻至正面向上时或你进入濒死时，若你不为主公，你可以弃置区域内的所有牌并摸等量的牌，然后将武将牌替换为【舞いの名 - 諸積 実乃梨】并回复所有体力。",
    ["@sangshi"] = "丧尸",
}

-- 伊藤 かりん
KarinIto = sgs.General(Sakamichi, "KarinIto", "Nogizaka46", 3, false)
SKMC.NiKiSei.KarinIto = true
SKMC.SeiMeiHanDan.KarinIto = {
    name = {6, 18, 3, 2, 2},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {7, "ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_jiang_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_jiang_qi",
    events = {sgs.Damage, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            if player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName()) then
                room:drawCards(player, 1, self:objectName())
                player:turnOver()
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Start then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:faceUp() then
                        if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. SKMC.number_correction(p, 1))) then
                            room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KarinIto:addSkill(sakamichi_jiang_qi)

sakamichi_you_neng = sgs.CreateTriggerSkill {
    name = "sakamichi_you_neng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local n = SKMC.number_correction(player, 1)
        if damage.damage >= n then
            for i = 1, damage.damage, n do
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local _player = sgs.SPlayerList()
                    _player:append(player)
                    local card_ids = room:getNCards(2, false)
                    local move = sgs.CardsMoveStruct(card_ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                                                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
                    local moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _player)
                    room:notifyMoveCards(false, moves, false, _player)
                    local you_neng_ids = sgs.IntList()
                    for _, id in sgs.qlist(card_ids) do
                        you_neng_ids:append(id)
                    end
                    while room:askForYiji(player, card_ids, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
                        local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                                                            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
                        for _, id in sgs.qlist(you_neng_ids) do
                            if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                                move.card_ids:append(id)
                                card_ids:removeOne(id)
                            end
                        end
                        you_neng_ids = sgs.IntList()
                        for _, id in sgs.qlist(card_ids) do
                            you_neng_ids:append(id)
                        end
                        local moves = sgs.CardsMoveList()
                        moves:append(move)
                        room:notifyMoveCards(true, moves, false, _player)
                        room:notifyMoveCards(false, moves, false, _player)
                        if not player:isAlive() then
                            return
                        end
                    end
                    if not card_ids:isEmpty() then
                        local move = sgs.CardsMoveStruct(card_ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                                                            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
                        local moves = sgs.CardsMoveList()
                        moves:append(move)
                        room:notifyMoveCards(true, moves, false, _player)
                        room:notifyMoveCards(false, moves, false, _player)
                        local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                        card:deleteLater()
                        card:addSubcards(card_ids)
                        room:obtainCard(player, card, false)
                    end
                end
            end
        end
        return false
    end,
}
KarinIto:addSkill(sakamichi_you_neng)

sgs.LoadTranslationTable {
    ["KarinIto"] = "伊藤 かりん",
    ["&KarinIto"] = "伊藤 かりん",
    ["#KarinIto"] = "女流棋士",
    ["~KarinIto"] = "振り飛車党",
    ["designer:KarinIto"] = "Cassimolar",
    ["cv:KarinIto"] = "伊藤 かりん",
    ["illustrator:KarinIto"] = "Cassimolar",
    ["sakamichi_jiang_qi"] = "将棋",
    [":sakamichi_jiang_qi"] = "当你造成伤害后，你可以摸两张牌并翻面。其他角色准备阶段，若你的武将牌背面向上，你可以对其造成1点伤害。",
    ["sakamichi_jiang_qi:invoke"] = "你可以发动【%arg】对%src 造成%arg2点伤害",
    ["sakamichi_you_neng"] = "有能",
    [":sakamichi_you_neng"] = "当你造成1点伤害后，你可以观看牌堆顶的两张牌，然后分配给任意角色。",
}

-- 寺田 蘭世
RanzeTerada = sgs.General(Sakamichi, "RanzeTerada", "Nogizaka46", 3, false)
SKMC.NiKiSei.RanzeTerada = true
SKMC.SeiMeiHanDan.RanzeTerada = {
    name = {6, 5, 19, 5},
    ten_kaku = {11, "ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "da_ji",
    },
}

sakamichi_luan_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_luan_shi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            local can = false
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getRole() == "rebel" then
                    can = true
                    break
                end
            end
            if can and room:askForSkillInvoke(player, self:objectName(), data) then
                if room:askForChoice(player, self:objectName(), "draw+play") == "draw" then
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Draw)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                else
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Play)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                end
            end
        end
        return false
    end,
}
RanzeTerada:addSkill(sakamichi_luan_shi)

sakamichi_bai_tou_xie_lao = sgs.CreateTriggerSkill {
    name = "sakamichi_bai_tou_xie_lao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@baitou",
    events = {sgs.EventPhaseStart, sgs.DamageInflicted, sgs.DamageComplete, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then
                if player:getMark("bai_tou_xie_lao_invoke") == 0 then
                    if player:getCards("he"):length() > 2 and room:askForSkillInvoke(player, self:objectName(), data) then
                        player:loseMark("@baitou", 1)
                        room:setPlayerMark(player, "bai_tou_xie_lao_invoke", 1)
                        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
                        target:gainMark("@xielao")
                        local tagvalue = sgs.QVariant()
                        tagvalue:setValue(target)
                        room:setTag(player:objectName() .. "bai_tou_xie_lao_target", tagvalue)
                        local card = room:askForExchange(player, self:objectName(), 2, 2, true, "@bai_tou_xie_lao_give")
                        room:obtainCard(target, card, false)
                    end
                end
            end
        elseif event == sgs.DamageInflicted then
            if player:hasSkill(self:objectName(), true) then
                local tag = room:getTag(player:objectName() .. "bai_tou_xie_lao_target")
                if tag then
                    local target = tag:toPlayer()
                    if target then
                        room:setPlayerFlag(target, "bai_tou_xie_lao")
                        if player:objectName() ~= target:objectName() then
                            local damage = data:toDamage()
                            damage.to = target
                            damage.transfer = true
                            room:damage(damage)
                            return true
                        end
                    end
                end
            end
        elseif event == sgs.DamageComplete then
            if player:hasFlag("bai_tou_xie_lao") then
                local damage = data:toDamage()
                room:drawCards(player, damage.damage, self:objectName())
                room:setPlayerFlag(player, "-bai_tou_xie_lao")
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if player:getMark("@xielao") > 0 and player:objectName() == dying.who:objectName() then
                player:loseMark("@xielao")
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasSkill(self:objectName(), true) then
                        local tag = room:getTag(p:objectName() .. "bai_tou_xie_lao_target")
                        local target = tag:toPlayer()
                        if target and target:objectName() == player:objectName() then
                            room:removeTag(p:objectName() .. "bai_tou_xie_lao_target")
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RanzeTerada:addSkill(sakamichi_bai_tou_xie_lao)

sakamichi_bao_yan_card = sgs.CreateSkillCard {
    name = "sakamcihi_bao_yanCard",
    skill_name = "sakamichi_bao_yan",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@baoyan", 1)
        if effect.to:objectName() == effect.from:objectName() then
            room:setPlayerMark(effect.to, "&number_correction_locking", 100)
            SKMC.send_message(room, "#number_correction_locking", effect.from, effect.to, nil, nil, self:getSkillName(), 100)
        else
            room:addPlayerMark(effect.to, "&number_correction_plus", SKMC.number_correction(effect.from, 1))
            SKMC.send_message(room, "#number_correction_plus", effect.from, effect.to, nil, nil, self:getSkillName(), 1)
        end
    end,
}
sakamichi_bao_yan = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_bao_yan",
    frequency = sgs.Skill_Limited,
    limit_mark = "@baoyan",
    view_as = function(self)
        return sakamichi_bao_yan_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@baoyan") ~= 0
    end,
}
RanzeTerada:addSkill(sakamichi_bao_yan)

sakamichi_zi_xing_che = sgs.CreateTriggerSkill {
    name = "sakamichi_zi_xing_che",
    frequency = sgs.Skill_Wake,
    events = {sgs.Damage},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            if not damage.to:inMyAttackRange(player) then
                return true
            end
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerMark(player, self:objectName(), 1)
        room:addPlayerMark(player, "zi_xing_che", 1)
        SKMC.send_message(room, "#zi_xing_che", player, nil, nil, nil, self:objectName())
    end,
}
sakamichi_zi_xing_che_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_zi_xing_che_distance",
    correct_func = function(self, from, to)
        if from:getMark("zi_xing_che") ~= 0 then
            return -SKMC.number_correction(from, 1)
        end
    end,
}
sakamichi_zi_xing_che_attack_range = sgs.CreateAttackRangeSkill {
    name = "#sakamichi_zi_xing_che_attack_range",
    extra_func = function(self, player, include_weapon)
        if player:getMark("zi_xing_che") ~= 0 then
            return SKMC.number_correction(player, 1)
        end
    end,
}
RanzeTerada:addSkill(sakamichi_zi_xing_che)
if not sgs.Sanguosha:getSkill("#sakamichi_zi_xing_che_distance") then SKMC.SkillList:append(sakamichi_zi_xing_che_distance) end
if not sgs.Sanguosha:getSkill("#sakamichi_zi_xing_che_attack_range") then SKMC.SkillList:append(sakamichi_zi_xing_che_attack_range) end

sgs.LoadTranslationTable {
    ["RanzeTerada"] = "寺田 蘭世",
    ["&RanzeTerada"] = "寺田 蘭世",
    ["#RanzeTerada"] = "势不可挡",
    ["~RanzeTerada"] = "らんぜの勢いとまらんぜ！",
    ["designer:RanzeTerada"] = "Cassimolar",
    ["cv:RanzeTerada"] = "寺田 蘭世",
    ["illustrator:RanzeTerada"] = "Cassimolar",
    ["sakamichi_luan_shi"] = "乱世",
    [":sakamichi_luan_shi"] = "结束阶段，若场上存在〔反贼〕，你可以执行一个额外的摸牌阶段或出牌阶段。",
    ["sakamichi_luan_shi:draw"] = "额外一个摸牌阶段",
    ["sakamichi_luan_shi:play"] = "额外一个出牌阶段",
    ["sakamichi_bai_tou_xie_lao"] = "白头偕老",
    [":sakamichi_bai_tou_xie_lao"] = "限定技，准备阶段，你可以交给一名其他角色两张牌。当你受到伤害时，将此伤害转移给该角色，然后该角色摸X张牌，直到其第一次进入濒死（X为伤害值）。",
    ["@baitou"] = "白头",
    ["@xielao"] = "偕老",
    ["@bai_tou_xie_lao_give"] = "请选择两张牌交给【白头偕老】目标",
    ["sakamichi_bao_yan"] = "爆言",
    [":sakamichi_bao_yan"] = "限定技，出牌阶段，你可以令一名角色武将牌的上的阿拉伯数字+1，若该角色为你，则加至100。",
    ["@baoyan"] = "爆言",
    ["sakamichi_zi_xing_che"] = "自行车",
    [":sakamichi_zi_xing_che"] = "觉醒技，当你使用【杀】造成伤害后，若你不在目标的攻击范围内，你的攻击范围+1，你与其他角色的距离-1。",
    ["#zi_xing_che"] = "%from 的【%arg】触发，%from 的攻击范围+1，与其他角色的距离-1。",
}

-- 米徳 京花
KyokaYoneto = sgs.General(Sakamichi, "KyokaYoneto", "Nogizaka46", 3, false)
SKMC.NiKiSei.KyokaYoneto = true
SKMC.SeiMeiHanDan.KyokaYoneto = {
    name = {6, 14, 8, 7},
    ten_kaku = {20, "xiong"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_shui_yong = sgs.CreateTriggerSkill {
    name = "sakamichi_shui_yong",
    change_skill = true,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local n = room:getChangeSkillState(player, self:objectName())
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Fire and n == 1 and room:askForSkillInvoke(player, self:objectName(), data) then
            local card = room:askForCardChosen(player, damage.to, "hej", self:objectName(), true, sgs.Card_MethodNone)
            room:setEmotion(damage.to, "skill_nullify")
            room:obtainCard(player, card, room:getCardPlace(card) ~= sgs.Player_PlaceHand)
            room:setChangeSkillState(player, self:objectName(), 2)
            return true
        elseif damage.nature == sgs.DamageStruct_Thunder and n == 2 and not player:isNude() then
            local n = SKMC.number_correction(player, 1)
            if room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@shui_yong_thunder:::" .. n) then
                damage.damage = damage.damage + n
                data:setValue(damage)
                room:setChangeSkillState(player, self:objectName(), 1)
            end
        end
        return false
    end,
}
KyokaYoneto:addSkill(sakamichi_shui_yong)

sakamichi_fu_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_fu_zi",
    change_skill = true,
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetConfirmed, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local n = room:getChangeSkillState(player, self:objectName())
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from and use.from:objectName() ~= player:objectName() and use.to:contains(player) and not use.card:isKindOf("SkillCard") and n == 1 then
                local n = player:getHandcardNum()
                local m = use.from:getHandcardNum()
                if n <= m and room:askForSkillInvoke(player, self:objectName(), data) then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getHandcardNum() <= n then
                            targets:append(p)
                        end
                    end
                    local to = room:askForPlayerChosen(player, targets, self:objectName(), "fu_zi_invoke", true, true)
                    if to then
                        room:drawCards(to, 1, self:objectName())
                        room:setChangeSkillState(player, self:objectName(), 2)
                    end
                end
            end
            return false
        else
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() and n == 2 then
                local n = player:getHandcardNum()
                local m = damage.from:getHandcardNum()
                if m <= n and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setEmotion(damage.to, "skill_nullify")
                    room:drawCards(damage.from, 1, self:objectName())
                    room:setChangeSkillState(player, self:objectName(), 1)
                    return true
                end
            end
        end
    end,
}
KyokaYoneto:addSkill(sakamichi_fu_zi)

sakamichi_jin_dan = sgs.CreateTriggerSkill {
    name = "sakamichi_jin_dan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            local damage = death.damage
            if damage then
                local murderer = damage.from
                if murderer then
                    if SKMC.is_ki_be(murderer, 2) then
                        murderer:throwAllEquips()
                    else
                        room:acquireSkill(murderer, "sakamichi_fa_jia")
                        local EX = sgs.Sanguosha:getTriggerSkill("sakamichi_fa_jia")
                        EX:trigger(sgs.GameStart, room, murderer, sgs.QVariant())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        if target then
            return target:hasSkill(self:objectName())
        end
        return false
    end,
}
KyokaYoneto:addSkill(sakamichi_jin_dan)

sgs.LoadTranslationTable {
    ["KyokaYoneto"] = "米徳 京花",
    ["&KyokaYoneto"] = "米徳 京花",
    ["#KyokaYoneto"] = "乃木坂風格",
    ["~KyokaYoneto"] = "みなさんこんばんは，米徳京花です",
    ["designer:KyokaYoneto"] = "Cassimolar",
    ["cv:KyokaYoneto"] = "米徳 京花",
    ["illustrator:KyokaYoneto"] = "Cassimolar",
    ["sakamichi_shui_yong"] = "水泳",
    [":sakamichi_shui_yong"] = "转换技，①当你造成火焰伤害时，你可以防止此伤害，然后观看目标手牌并获得其区域内的一张牌；②当你造成雷电伤害时，你可以弃置一张牌，令此伤害+1。",
    [":sakamichi_shui_yong1"] = "转换技，①当你造成火焰伤害时，你可以防止此伤害，然后观看目标手牌并获得其区域内的一张牌；<font color=\"#01A5AF\"><s>②当你造成雷电伤害时，你可以弃置一张牌，令此伤害+1</s></font>。",
    [":sakamichi_shui_yong2"] = "转换技，<font color=\"#01A5AF\"><s>①当你造成火焰伤害时，你可以防止此伤害，然后观看目标手牌并获得其区域内的一张牌</s></font>；②当你造成雷电伤害时，你可以弃置一张牌，令此伤害+1。",
    ["@shui_yong_thunder"] = "你可以弃置一张牌来使此伤害+%arg",
    ["sakamichi_fu_zi"] = "抚子",
    [":sakamichi_fu_zi"] = "转换技，①当你成为其他角色使用牌的目标后，若你手牌不多于其，你可以令一名手牌数不多于你的角色摸一张牌；②当你受到其他角色造成的伤害时，若其手牌不多于你，你可以防止此伤害，然后其摸一张牌。",
    [":sakamichi_fu_zi1"] = "转换技，①当你成为其他角色使用牌的目标后，若你手牌不多于其，你可以令一名手牌数不多于你的角色摸一张牌；<font color=\"#01A5AF\"><s>②当你受到其他角色造成的伤害时，若其手牌不多于你，你可以防止此伤害，然后其摸一张牌</s></font>。",
    [":sakamichi_fu_zi2"] = "转换技，<font color=\"#01A5AF\"><s>①当你成为其他角色使用牌的目标后，若你手牌不多于其，你可以令一名手牌数不多于你的角色摸一张牌</s></font>；②当你受到其他角色造成的伤害时，若其手牌不多于你，你可以防止此伤害，然后其摸一张牌。",
    ["fu_zi_invoke"] = "你可以选择一名角色令其摸一张牌",
    ["sakamichi_jin_dan"] = "金蛋",
    [":sakamichi_jin_dan"] = "锁定技，当你死亡时，若伤害来源是二期生，伤害来源获得【发夹】（获得后不为主公也可发动），否则其须弃置装备区所有牌。",
}

-- 佐々木 琴子
KotokoSasaki = sgs.General(Sakamichi, "KotokoSasaki", "Nogizaka46", 4, false)
SKMC.NiKiSei.KotokoSasaki = true
SKMC.SeiMeiHanDan.KotokoSasaki = {
    name = {7, 3, 4, 12, 3},
    ten_kaku = {14, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_bing_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_bing_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Predamage, sgs.DamageForseen, sgs.PreHpLost},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Predamage then
            local damage = data:toDamage()
            local current = room:getCurrent()
            if current:hasSkill(self:objectName()) or player:hasSkill(self:objectName()) or damage.to:hasSkill(self:objectName()) then
                local from
                if current:hasSkill(self:objectName()) then
                    from = current
                elseif player:hasSkill(self:objectName()) then
                    from = player
                else
                    from = damage.to
                end
                SKMC.send_message(room, "#bing_yan", from, nil, nil, nil, self:objectName(), damage.damage)
                room:loseHp(damage.to, damage.damage)
                return true
            end
        elseif event == sgs.DamageForseen then
            local damage = data:toDamage()
            if not damage.from then
                local current = room:getCurrent()
                if current:hasSkill(self:objectName()) then
                    SKMC.send_message(room, "#bing_yan", current, nil, nil, nil, self:objectName(), damage.damage)
                    room:loseHp(damage.to, damage.damage)
                    return true
                end
            end
        elseif event == sgs.PreHpLost then
            if player:hasSkill(self:objectName()) and player:getPhase() ~= sgs.Player_NotActive then
                SKMC.send_message(room, "#bing_yan_protect", player, nil, nil, nil, self:objectName())
                room:setEmotion(player, "skill_nullify")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KotokoSasaki:addSkill(sakamichi_bing_yan)

sakamichi_sheng_you_card = sgs.CreateSkillCard {
    name = "sakamichi_sheng_youCard",
    skill_name = "sakamichi_sheng_you",
    filter = function(self, targets, to_select)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:deleteLater()
        local plist = sgs.PlayerList()
        for i = 1, #targets, 1 do
            plist:append(targets[i])
        end
        return slash:targetFilter(plist, to_select, sgs.Self) and sgs.Self:canSlash(to_select, slash, true)
    end ,
    on_validate = function(self, cardUse)
        cardUse.m_isOwnerUse = false
        local player = cardUse.from
        local room = player:getRoom()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:getSkillName())) do
            if p:objectName() ~= player:objectName() and
                room:askForSkillInvoke(p, self:getSkillName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. SKMC.number_correction(p, 1) .. ":" .. "slash")) then
                room:loseHp(p)
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                slash:setSkillName(self:getSkillName())
                slash:deleteLater()
                return slash
            end
        end
        room:setPlayerFlag(player, "sheng_you_failed")
        return nil
    end
}
sakamichi_sheng_you_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sheng_you_view_as&",
    view_as = function()
        return sakamichi_sheng_you_card:clone()
    end ,
    enabled_at_play = function(self, player)
        return not player:hasFlag("sheng_you_failed") and sgs.Slash_IsAvailable(player)
    end ,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and not player:hasFlag("sheng_you_failed")
    end
}
sakamichi_sheng_you = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_you",
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.CardAsked},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
            if player:hasSkill(self:objectName()) then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if not p:hasSkill("sakamichi_sheng_you_view_as") then
                        room:attachSkillToPlayer(p, "sakamichi_sheng_you_view_as")
                    end
                end
            end
        elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
            local no_one_has_this_skill = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self:objectName()) then
                    no_one_has_this_skill = false
                    break
                end
            end
            if no_one_has_this_skill then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill("sakamichi_sheng_you_view_as") then
                        room:detachSkillFromPlayer(p, self:objectName(), true)
                    end
                end
            end
        elseif event == sgs.CardAsked then
            local pattern = data:toStringList()[1]
            local prompt = data:toStringList()[2]
            if pattern == "jink" and not string.find(prompt, "@sheng_you_jink") then
                local to_help = sgs.QVariant()
                to_help:setValue(player)
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName()  then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. SKMC.number_correction(p, 1) .. ":" .. "jink")) then
                                room:loseHp(p)
                                local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
                                jink:deleteLater()
                                jink:setSkillName(self:objectName())
                                room:provide(jink)
                                return true
                            end
                        end
                    end
                end
            end
            if pattern == "slash" and not string.find(prompt, "@sheng_you_slash") then
                local to_help = sgs.QVariant()
                to_help:setValue(player)
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. SKMC.number_correction(p, 1) .. ":" .. "slash")) then
                                room:loseHp(p)
                                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                                slash:setSkillName(self:objectName())
                                slash:deleteLater()
                                room:provide(slash)
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}
KotokoSasaki:addSkill(sakamichi_sheng_you)
if not sgs.Sanguosha:getSkill("sakamichi_sheng_you_view_as") then SKMC.SkillList:append(sakamichi_sheng_you_view_as) end

sgs.LoadTranslationTable {
    ["KotokoSasaki"] = "佐々木 琴子",
    ["&KotokoSasaki"] = "佐々木 琴子",
    ["#KotokoSasaki"] = "古风美人",
    ["~KotokoSasaki"] = "もう、欲しがりやさんね♪",
    ["designer:KotokoSasaki"] = "Cassimolar",
    ["cv:KotokoSasaki"] = "佐々木 琴子",
    ["illustrator:KotokoSasaki"] = "Cassimolar",
    ["sakamichi_bing_yan"] = "冰颜",
    [":sakamichi_bing_yan"] = "锁定技，你造成或受到伤害均视为体力流失。你的回合内所有伤害均视为体力流失。你的回合内防止你的体力流失。",
    ["#bing_yan"] = "%from 的【%arg】被触发，此次%arg2点伤害视为体力流失",
    ["#bing_yan_protect"] = "%from 的【%arg】被触发，防止此次体力流失",
    ["sakamichi_sheng_you"] = "声优",
    [":sakamichi_sheng_you"] = "其他角色需要使用或打出【杀】／【闪】时，你可以失去1点体力视为其使用或打出了一张【杀】／【闪】。",
    ["sakamichi_sheng_you:invoke"] = "你可以失去%arg点体力为%src 提供一张【%arg2】",
    ["sakamichi_sheng_you_view_as"] = "声优",
    [":sakamichi_sheng_you_view_as"] = "当你需要使用或打出一张【杀】时，【声优】拥有者可以失去1点体力视为你使用或打出一张【杀】",
}

-- 西川 七海
nanaminishikawa = sgs.General(Sakamichi, "nanaminishikawa", "Nogizaka46", 4, false)
SKMC.NiKiSei.nanaminishikawa = true
SKMC.SeiMeiHanDan.nanaminishikawa = {
    name = {6, 3, 2, 9,},
    ten_kaku = {9, "xiong"},
    jin_kaku = {5, "ji"},
    ji_kaku = {11, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {20, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_chong_jing_card = sgs.CreateSkillCard {
    name = "sakamichi_chong_jingCard",
    skill_name = "sakamichi_chong_jing",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:drawCards(source, 4, self:getSkillName())
        local general_names = {}
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not table.contains(general_names, p:getGeneralName()) then
                table.insert(general_names, p:getGeneralName())
            end
            if not table.contains(general_names, p:getGeneral2Name()) then
                table.insert(general_names, p:getGeneral2Name())
            end
        end
        local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
        local chongjing_generals = {}
        for _, name in ipairs(all_generals) do
            local general = sgs.Sanguosha:getGeneral(name)
            if general:getKingdom() == "Nogizaka46" then
                if not table.contains(general_names, name) then
                    table.insert(chongjing_generals, name)
                end
            end
        end
        local general = room:askForGeneral(source, table.concat(chongjing_generals, "+"))
        source:setTag("newgeneral", sgs.QVariant(general))
        local is_secondary_hero = not sgs.Sanguosha:getGeneral(source:getGeneralName()):hasSkill(self:getSkillName())
        if is_secondary_hero then
            source:setTag("originalGeneral", sgs.QVariant(source:getGeneral2Name()))
        else
            source:setTag("originalGeneral", sgs.QVariant(source:getGeneralName()))
        end
        room:changeHero(source, general, false, false, is_secondary_hero)
        room:setPlayerFlag(source, self:getSkillName())
        room:acquireSkill(source, self:getSkillName(), false)
    end,
}
sakamichi_chong_jing_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_chong_jing",
    view_as = function()
        return sakamichi_chong_jing_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag(self:objectName())
    end,
}
sakamichi_chong_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_chong_jing",
    events = {sgs.EventPhaseChanging},
    view_as_skill = sakamichi_chong_jing_view_as,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            if player:hasFlag(self:objectName()) then
                local is_secondary_hero = player:getGeneralName() ~= player:getTag("newgeneral"):toString()
                room:changeHero(player, player:getTag("originalGeneral"):toString(), false, false, is_secondary_hero)
                room:killPlayer(player)
            end
        end
        return false
    end,
}
nanaminishikawa:addSkill(sakamichi_chong_jing)

sakamichi_ba_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_ba_qi",
    events = {sgs.Death, sgs.AskForPeachesDone},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            local alives = room:getAlivePlayers()
            if player:objectName() == death.who:objectName() and player:hasSkill(self:objectName()) then
                if not alives:isEmpty() then
                    local target = room:askForPlayerChosen(player, alives, self:objectName(), "@ba_qi_invoke", true, true)
                    if target then
                        local ai_data = sgs.QVariant()
                        ai_data:setValue(target)
                        local choice = room:askForChoice(player, self:objectName(), "draw+throw", ai_data)
                        if choice == "draw" then
                            room:drawCards(target, 3, self:objectName())
                        else
                            local count = math.min(3, target:getCardCount(true))
                            room:askForDiscard(target, self:objectName(), count, count, false, true)
                        end
                    end
                end
            end
            return
        else
            local dying = data:toDying()
            if player:getHp() <= 0 and dying.damage and dying.damage.from and player:hasSkill(self:objectName()) then
                dying.damage.from = player
                room:killPlayer(player, dying.damage)
                room:setTag("SkipGameRule", sgs.QVariant(true))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
nanaminishikawa:addSkill(sakamichi_ba_qi)

sakamichi_ni_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_ni_jing",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:objectName() ~= player:objectName() and player:canPindian(damage.to) and room:askForSkillInvoke(player, self:objectName(), data) then
            local success = player:pindian(damage.to, self:objectName(), nil)
            if success then
                room:recover(player, sgs.RecoverStruct(damage.to))
                room:loseHp(damage.to)
            else
                room:recover(damage.to, sgs.RecoverStruct(player))
                room:loseHp(player)
            end
            return false
        end
    end,
}
nanaminishikawa:addSkill(sakamichi_ni_jing)

sgs.LoadTranslationTable {
    ["nanaminishikawa"] = "西川 七海",
    ["&nanaminishikawa"] = "西川 七海",
    ["#nanaminishikawa"] = "背负过去",
    ["~nanaminishikawa"] = "",
    ["designer:nanaminishikawa"] = "Cassimolar",
    ["cv:nanaminishikawa"] = "西川 七海",
    ["illustrator:nanaminishikawa"] = "Cassimolar",
    ["sakamichi_chong_jing"] = "憧憬",
    [":sakamichi_chong_jing"] = "出牌阶段，你可以摸四张牌并变身为未上场或已阵亡的乃木坂46势力角色，本回合结束后你死亡。",
    ["sakamichi_ba_qi"] = "八期",
    [":sakamichi_ba_qi"] = "当你死亡时，你可以令一名角色摸三张牌或弃三张牌。锁定技，你死亡时，凶手视为自己。",
    ["@ba_qi_invoke"] = "你可以选择一名角色令其摸三张牌或弃置三张牌",
    ["sakamichi_ni_jing"] = "逆境",
    [":sakamichi_ni_jing"] = "当你对其他角色造成伤害后，你可以与其拼点，若你赢，你回复1点体力其失去1点体力；没赢，你失去1点体力其回复1点体力。",
}

-- 矢田 里沙子
RisakoYada = sgs.General(Sakamichi, "RisakoYada", "Nogizaka46", 3, false)
SKMC.NiKiSei.RisakoYada = true
SKMC.SeiMeiHanDan.RisakoYada = {
    name = {5, 5, 7, 7, 3},
    ten_kaku = {10, "xiong"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {17, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {27, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_bu_she = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_she",
    events = {sgs.AskForPeaches},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() ~= player:objectName() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:gainMaxHp(dying.who, SKMC.number_correction(player, 1))
                room:recover(dying.who, sgs.RecoverStruct(player, nil, player:getHp()))
                if player:getCards("he"):length() > 0 then
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    dummy:deleteLater()
                    dummy:addSubcards(player:getCards("he"))
                    room:obtainCard(dying.who, dummy, false)
                end
                room:killPlayer(player)
            end
        end
        return false
    end,
}
RisakoYada:addSkill(sakamichi_bu_she)

sakamichi_zhi_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_zhi_yu",
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        local recover_struct = data:toRecover()
        local recover = recover_struct.recover
        for i = 1, recover, SKMC.number_correction(player, 1) do
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@zhi_yu_invoke", true, true)
            if target then
                room:drawCards(target, 1, self:objectName())
            else
                break
            end
        end
        return false
    end,
}
RisakoYada:addSkill(sakamichi_zhi_yu)

sakamichi_bao_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_bao_yu",
    events = {sgs.StartJudge},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.reason == "indulgence" or judge.reason == "lightning" or judge.reason == "supply_shortage" or judge.reason == "WasabiOnigiri" then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    local card = room:askForCard(p, ".", "@bao_yu_discard:::" .. judge.reason, data, self:objectName())
                    if card then
                        judge.good = not judge.good
                        if not card:isKindOf("BasicCard") then
                            room:drawCards(p, 1, self:objectName())
                        end
                    end
                end
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RisakoYada:addSkill(sakamichi_bao_yu)

sgs.LoadTranslationTable {
    ["RisakoYada"] = "矢田 里沙子",
    ["&RisakoYada"] = "矢田 里沙子",
    ["#RisakoYada"] = "二期聖母",
    ["~RisakoYada"] = "やだやだやだー 覚えてくれなきゃ？やだー！！！",
    ["designer:RisakoYada"] = "Cassimolar",
    ["cv:RisakoYada"] = "矢田 里沙子",
    ["illustrator:RisakoYada"] = "Cassimolar",
    ["sakamichi_bu_she"] = "不舍",
    [":sakamichi_bu_she"] = "当一名其他角色处于濒死时，你可以令其增加1点体力上限并回复X点体力值（X为你的体力值）并获得你所有牌，然后你死亡。",
    ["sakamichi_zhi_yu"] = "治愈",
    [":sakamichi_zhi_yu"] = "每当你回复1点体力时，你可以令一名其他角色摸一张牌。",
    ["@zhi_yu_invoke"] = "你可以令一名其他角色摸一张牌",
    ["sakamichi_bao_yu"] = "保育",
    [":sakamichi_bao_yu"] = "当一名角色判定区的牌开始判定时，你可以弃置一张手牌令其此次判定结果反转，若你以此法弃置的牌不为基本牌，你摸一张牌。",
    ["@bao_yu_discard"] = "你可以弃置一张手牌令此【%arg】判定结果反转",
}

-- 山﨑 怜奈
RenaYamazaki = sgs.General(Sakamichi, "RenaYamazaki", "Nogizaka46", 3, false)
SKMC.NiKiSei.RenaYamazaki = true
SKMC.SeiMeiHanDan.RenaYamazaki = {
    name = {3, 12, 8, 8},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "shui",
        ji_kaku = "tu",
        san_sai = "xiong",
    },
}

sakamichi_li_nv = sgs.CreateTriggerSkill {
    name = "sakamichi_li_nv",
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            local li_nv_list = player:getTag(self:objectName()):toString():split(",")
            local list = sgs.IntList()
            local to_gain_list = sgs.IntList()
            for _, id in sgs.qlist(room:getDiscardPile()) do
                if not table.contains(li_nv_list, SKMC.true_name(sgs.Sanguosha:getCard(id))) then
                    list:append(id)
                end
            end
            if list:length() ~= 0 then
                room:fillAG(list)
                for i = 1, 2, 1 do
                    local id = room:askForAG(player, list, false, self:objectName())
                    if id ~= -1 then
                        table.insert(li_nv_list, SKMC.true_name(sgs.Sanguosha:getCard(id)))
                        room:setPlayerMark(player, "&" .. self:objectName() .. "+" .. SKMC.true_name(sgs.Sanguosha:getCard(id)), 1)
                        list:removeOne(id)
                        to_gain_list:append(id)
                        room:takeAG(player, id, false)
                        if not list:isEmpty() then
                            local temp_list = list
                            for _, id1 in sgs.qlist(temp_list) do
                                if SKMC.true_name(sgs.Sanguosha:getCard(id1)) == SKMC.true_name(sgs.Sanguosha:getCard(id)) then
                                    room:takeAG(nil, id1, false)
                                    list:removeOne(id1)
                                end
                            end
                        end
                    else
                        break
                    end
                end
                if to_gain_list:length() ~= 0 then
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    dummy:deleteLater()
                    dummy:addSubcards(to_gain_list)
                    player:obtainCard(dummy)
                end
                room:clearAG()
                room:broadcastInvoke("clearAG")
            end
            n = 0
            data:setValue(n)
            if #li_nv_list > room:getAlivePlayers():length() then
                li_nv_list = {}
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "&" .. self:objectName()) and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
            player:setTag(self:objectName(), sgs.QVariant(table.concat(li_nv_list, ",")))
        end
        return false
    end,
}
RenaYamazaki:addSkill(sakamichi_li_nv)

sakamichi_zhong_wen = sgs.CreateOneCardViewAsSkill{
    name = "sakamichi_zhong_wen" ,
    filter_pattern = "BasicCard|.|.|hand",
    guhuo_type = "rd",
    view_as = function(self, card)
        local cd = sgs.Self:getTag(self:objectName()):toCard()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasFlag("zhong_wen_used")
    end,
}
sakamichi_zhong_wen_used = sgs.CreateTriggerSkill {
    name = "#sakamichi_zhong_wen_used",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("TrickCard") and use.card:getSkillName() == "sakamichi_zhong_wen" then
            room:setPlayerFlag(player, "zhong_wen_used")
        end
        return false
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_zhong_wen", "#sakamichi_zhong_wen_used")
RenaYamazaki:addSkill(sakamichi_zhong_wen)
RenaYamazaki:addSkill(sakamichi_zhong_wen_used)

sgs.LoadTranslationTable {
    ["RenaYamazaki"] = "山﨑 怜奈",
    ["&RenaYamazaki"] = "山﨑 怜奈",
    ["#RenaYamazaki"] = "慶應智者",
    ["~RenaYamazaki"] = "私、とにかく「失敗上等」精神なんです。",
    ["designer:RenaYamazaki"] = "Cassimolar",
    ["cv:RenaYamazaki"] = "山崎 怜奈",
    ["illustrator:RenaYamazaki"] = "Cassimolar",
    ["sakamichi_li_nv"] = "历女",
    [":sakamichi_li_nv"] = "摸牌阶段，你可以放弃摸牌，改为从弃牌堆中选择获得两张未以此法记录过牌名且不同的牌并记录牌名的牌，若已记录的牌名超过X则复原本技能记录（X为场上存活角色数）。",
    ["sakamichi_zhong_wen"] = "中文",
    [":sakamichi_zhong_wen"] = "出牌阶段限一次，你可以将手牌中的一张基本牌当一张锦囊牌使用。",
}

-- 伊藤 純奈
JunnaIto = sgs.General(Sakamichi, "JunnaIto", "Nogizaka46", 4, false)
SKMC.NiKiSei.JunnaIto = true
SKMC.SeiMeiHanDan.JunnaIto = {
    name = {6, 18, 10, 8},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {28, "xiong"},
    ji_kaku = {28, "ji"},
    soto_kaku = {24, "xiong"},
    sou_kaku = {42, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_wen_mo = sgs.CreateTriggerSkill {
    name = "sakamichi_wen_mo",
    events = {sgs.TargetSpecified, sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified then
            if use.card:isKindOf("BasicCard") or use.card:isNDTrick()then
                room:setCardFlag(use.card, "wen_mo")
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:distanceTo(player) == SKMC.number_correction(player, 1) and p:getMark("wen_mo") == 0 then
                        room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
                        room:addPlayerMark(p, "wen_mo")
                        targets:append(p)
                    end
                end
                SKMC.send_message(room, "#wen_mo_target", player, nil, targets, use.card:toString(), self:objectName())
            end
        elseif event == sgs.CardFinished then
            if use.card:hasFlag("wen_mo") then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("wen_mo") ~= 0 then
                        room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand$0")
                        room:setPlayerMark(p, "wen_mo", 0)
                    end
                end
            end
        end
        return false
    end,
}
JunnaIto:addSkill(sakamichi_wen_mo)

sakamichi_dan_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_dan_shi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@danshi",
    events = {sgs.EventPhaseStart, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) and
            player:getMark("@danshi") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@danshi_invoke:::" .. self:objectName())
            if target then
                room:removePlayerMark(player, "@danshi")
                room:setFixedDistance(target, player, 1)
                room:setPlayerMark(target, "&" .. self:objectName() .. "+" .. player:getGeneralName(), 1)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if death.who:getMark("&" .. self:objectName() .. "+" .. p:getGeneralName()) ~= 0 then
                    room:removeFixedDistance(death.who, p, 1)
                    room:setPlayerMark(death.who, "&" .. self:objectName() .. "+" .. p:getGeneralName(), 0)
                    if p:hasSkill(self:objectName()) and death.damage and death.damage.from and death.damage.from:objectName() == p:objectName() then
                        room:setPlayerMark(p, "@danshi", 1)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
JunnaIto:addSkill(sakamichi_dan_shi)

sgs.LoadTranslationTable {
    ["JunnaIto"] = "伊藤 純奈",
    ["&JunnaIto"] = "伊藤 純奈",
    ["#JunnaIto"] = "年龄诈称",
    ["~JunnaIto"] = "あなたはクチビルオバケに恋をする",
    ["designer:JunnaIto"] = "Cassimolar",
    ["cv:JunnaIto"] = "伊藤 純奈",
    ["illustrator:JunnaIto"] = "Cassimolar",
    ["sakamichi_wen_mo"] = "吻魔",
    [":sakamichi_wen_mo"] = "锁定技，当你使用基本牌或通常锦囊牌指定目标后，距离你为1的角色无法使用或打出手牌直到此牌结算完毕。",
    ["#wen_mo_target"] = "%from 的【%arg】被触发，%to 无法使用或打出手牌直到【%card】结算完毕",
    ["sakamichi_dan_shi"] = "胆识",
    [":sakamichi_dan_shi"] = "限定技，准备阶段，你可以选择一名其他角色，令其本局游戏剩余时间与你的距离锁定为1，该角色死亡时，若凶手是你，此技能视未发动过。",
    ["@danshi"] = "胆识",
    ["@danshi_invoke"] = "你可以发动【%arg】选择一名其他角色令其与你的距离锁定为1",
}

-- 鈴木 絢音
AyaneSuzuki = sgs.General(Sakamichi, "AyaneSuzuki", "Nogizaka46", 4, false)
SKMC.NiKiSei.AyaneSuzuki = true
SKMC.SeiMeiHanDan.AyaneSuzuki = {
    name = {13, 4, 12, 9},
    ten_kaku = {17, "ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {22, "xiong"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fei_ji = sgs.CreateTargetModSkill {
    name = "sakamichi_fei_ji",
    pattern = "Slash, TrickCard",
    frequency = sgs.Skill_Compulsory,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill(self:objectName()) then
            return 1000
        else
            return 0
        end
    end,
}
AyaneSuzuki:addSkill(sakamichi_fei_ji)

sakamichi_wu_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_sheng",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Draw) then
            if player:askForSkillInvoke(self:objectName(), data) then
                player:skip(sgs.Player_Judge)
                player:skip(sgs.Player_Draw)
                local move = sgs.CardsMoveStruct()
                for _, card in sgs.qlist(player:getJudgingArea()) do
                    move.card_ids:append(card:getEffectiveId())
                end
                local candraw = false
                if move.card_ids:length() < 2 then
                    candraw = true
                end
                move.to = player
                move.to_place = sgs.Player_PlaceHand
                SKMC.send_message(room, "#wu_sheng_got", player, nil, nil, table.concat(sgs.QList2Table(move.card_ids), "+"))
                room:moveCardsAtomic(move, true)
                if candraw then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
AyaneSuzuki:addSkill(sakamichi_wu_sheng)

sakamichi_jie_zi_card = sgs.CreateSkillCard {
    name = "sakamichi_jie_ziCard",
    skill_name = "sakamichi_jie_zi",
    will_throw = true,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local player = source
        local name_num = SKMC.get_string_word_number(sgs.Sanguosha:translate(sgs.Sanguosha:getCard(self:getEffectiveId()):objectName()))
        local card_ids = room:getNCards(name_num)
        room:fillAG(card_ids)
        local to_get = sgs.IntList()
        local to_throw = sgs.IntList()
        while true do
            local sum = 0
            for _, id in sgs.qlist(to_get) do
                sum = sum + SKMC.get_string_word_number(sgs.Sanguosha:translate(sgs.Sanguosha:getCard(id):objectName()))
            end
            for _, id in sgs.qlist(card_ids) do
                if sum + SKMC.get_string_word_number(sgs.Sanguosha:translate(sgs.Sanguosha:getCard(id):objectName())) > name_num + 1 then
                    room:takeAG(nil, id, false)
                    card_ids:removeOne(id)
                    to_throw:append(id)
                end
            end
            if card_ids:isEmpty() then
                break
            end
            local card_id = room:askForAG(player, card_ids, true, self:getSkillName())
            if card_id == -1 then
                break
            end
            card_ids:removeOne(card_id)
            to_get:append(card_id)
            room:takeAG(player, card_id, false)
            if card_ids:isEmpty() then
                break
            end
        end
        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        dummy:deleteLater()
        if not to_get:isEmpty() then
            dummy:addSubcards(to_get)
            player:obtainCard(dummy)
            dummy:clearSubcards()
        end
        if not to_throw:isEmpty() or not card_ids:isEmpty() then
            dummy:addSubcards(to_throw)
            dummy:addSubcards(card_ids)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
            room:throwCard(dummy, reason, nil)
        end
        room:clearAG()
        room:broadcastInvoke("clearAG")
    end,
}
sakamichi_jie_zi = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jie_zi",
    filter_pattern = ".",
    view_as = function(self, card)
        local cd = sakamichi_jie_zi_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_jie_ziCard") and not player:isNude()
    end,
}
AyaneSuzuki:addSkill(sakamichi_jie_zi)

sgs.LoadTranslationTable {
    ["AyaneSuzuki"] = "鈴木 絢音",
    ["&AyaneSuzuki"] = "鈴木 絢音",
    ["#AyaneSuzuki"] = "秋田美人",
    ["~AyaneSuzuki"] = "お金ありますか？",
    ["designer:AyaneSuzuki"] = "Cassimolar",
    ["cv:AyaneSuzuki"] = "鈴木 絢音",
    ["illustrator:AyaneSuzuki"] = "Cassimolar",
    ["sakamichi_fei_ji"] = "飞机",
    [":sakamichi_fei_ji"] = "锁定技，你使用【杀】和锦囊牌无距离限制。",
    ["sakamichi_wu_sheng"] = "无声",
    [":sakamichi_wu_sheng"] = "你可以跳过你的判定阶段和摸牌阶段，然后获得你判定区内所有牌，若你以此法获得的牌少于两张，你摸一张牌。",
    ["#wu_sheng_got"] = "%from 获得其判定区内所有牌：%card",
    ["sakamichi_jie_zi"] = "解字",
    [":sakamichi_jie_zi"] = "出牌阶段限一次，你可以弃置一张牌，然后翻开牌堆顶的X张牌，选择并获得其中任意张牌名字数相加不大于X+1的牌（X为此牌的牌名字数）。",
}

-- 相楽 伊織
IoriSagara = sgs.General(Sakamichi, "IoriSagara", "Nogizaka46", 3, false)
SKMC.NiKiSei.IoriSagara = true
SKMC.SeiMeiHanDan.IoriSagara = {
    name = {9, 13, 6, 18},
    ten_kaku = {22, "xiong"},
    jin_kaku = {19, "xiong"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {46, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "huo",
        san_sai = "xiong",
    },
}

sakamichi_ruan_meng = sgs.CreateTriggerSkill {
    name = "sakamichi_ruan_meng",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EnterDying, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                local count = 0
                for _, p in sgs.qlist(room:getAllPlayers(true)) do
                    if p:isDead() then
                        count = count + 1
                    end
                end
                if count < math.floor(room:alivePlayerCount() / SKMC.number_correction(player, 2) - SKMC.number_correction(player, 1)) then
                    room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1) - player:getHp()))
                end
            end
        elseif event == sgs.Death then
            room:addMaxCards(player, 1, false)
        end
        return false
    end,
}

IoriSagara:addSkill(sakamichi_ruan_meng)

sakamichi_chu_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_chu_xin",
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            room:addPlayerMark(player, "@chu_xin", 2)
            player:turnOver()
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                player:drawCards(1)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if player:getMark("@chu_xin") > 0 then
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("extra_turn_invoke:::" .. self:objectName() .. ":" .. "@chu_xin")) then
                        room:removePlayerMark(player, "@chu_xin", 1)
                        SKMC.send_message(room, "#Fangquan", nil, player)
                        player:gainAnExtraTurn()
                    end
                end
            end
        end
        return false
    end,
}
IoriSagara:addSkill(sakamichi_chu_xin)

sgs.LoadTranslationTable {
    ["IoriSagara"] = "相楽 伊織",
    ["&IoriSagara"] = "相楽 伊織",
    ["#IoriSagara"] = "大型幼儿",
    ["~IoriSagara"] = "いや。分かるでしよ!",
    ["designer:IoriSagara"] = "Cassimolar",
    ["cv:IoriSagara"] = "相楽 伊織",
    ["illustrator:IoriSagara"] = "Cassimolar",
    [":sakamichi_ruan_meng"] = "锁定技，当你进入濒死时，若场上死亡角色数小于X/2-1（向下取整，X为场上角色数），你将体力值回复至1。当一名角色死亡时，你的手牌上限+1。",
    ["sakamichi_chu_xin"] = "初心",
    [":sakamichi_chu_xin"] = "游戏开始时，你获得两枚「初心」并翻面。回合开始时，你摸一张牌。回合结束时，你可以移除一枚「初心」执行一个额外回合。",
    ["@chu_xin"] = "初心",
    ["sakamichi_chu_xin:extra_turn_invoke"] = "你可以发动【%arg】弃置一枚“%arg2”获得一个额外的回合",
}

-- 中村 麗乃
RenoNakamura = sgs.General(Sakamichi, "RenoNakamura", "Nogizaka46", 4, false)
SKMC.SanKiSei.RenoNakamura = true
SKMC.SeiMeiHanDan.RenoNakamura = {
    name = {4, 7, 19, 2},
    ten_kaku = {11, "ji"},
    jin_kaku = {26, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {6, "da_ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_yu_zhe = sgs.CreateFilterSkill {
    name = "sakamichi_yu_zhe",
    view_filter = function(self, card)
        return card:isKindOf("TrickCard")
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:setSkillName(self:objectName())
        local cd = sgs.Sanguosha:getWrappedCard(card:getId())
        cd:takeOver(slash)
        return cd
    end,
}
sakamichi_yu_zhe_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_yu_zhe_target_mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_yu_zhe") then
            return 1
        else
            return 0
        end
    end,
    extra_target_func = function(self, from, card)
        if from:hasSkill("sakamichi_yu_zhe") then
            return 1
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_yu_zhe") then
            return 1
        else
            return 0
        end
    end,
}
RenoNakamura:addSkill(sakamichi_yu_zhe)
if not sgs.Sanguosha:getSkill("#sakamichi_yu_zhe_target_mod") then SKMC.SkillList:append(sakamichi_yu_zhe_target_mod) end

sakamichi_cheng_yun_card = sgs.CreateSkillCard {
    name = "sakamichi_cheng_yunCard",
    skill_name = "sakamichi_cheng_yun",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@cheng_yun", 1)
        source:throwAllHandCards()
        room:setPlayerFlag(source, self:getSkillName())
        room:drawCards(source, 1, self:getSkillName())
    end,
}
sakamichi_cheng_yun_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_cheng_yun",
    view_as = function()
        return sakamichi_cheng_yun_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@cheng_yun") ~= 0 and not player:isKongcheng()
    end,
}
sakamichi_cheng_yun = sgs.CreateTriggerSkill {
    name = "sakamichi_cheng_yun",
    frequency = sgs.Skill_Limited,
    limit_mark = "@cheng_yun",
    view_as_skill = sakamichi_cheng_yun_view_as,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and player:hasFlag(self:objectName()) then
            for _, id in sgs.qlist(move.card_ids) do
                if id == player:getTag(self:objectName()):toInt() then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        if move.to and move.to:objectName() == player:objectName() and player:hasFlag(self:objectName()) and move.reason.m_skillName and move.reason.m_skillName == self:objectName() then
            player:setTag(self:objectName(), sgs.QVariant(move.card_ids:first()))
        end
        return false
    end,
}
RenoNakamura:addSkill(sakamichi_cheng_yun)

sgs.LoadTranslationTable {
    ["RenoNakamura"] = "中村 麗乃",
    ["&RenoNakamura"] = "中村 麗乃",
    ["#RenoNakamura"] = "童颜",
    ["~RenoNakamura"] = "ゼンゼン ニホンゴ ダイスキダカラ",
    ["designer:RenoNakamura"] = "Cassimolar",
    ["cv:RenoNakamura"] = "中村 麗乃",
    ["illustrator:RenoNakamura"] = "Cassimolar",
    ["sakamichi_yu_zhe"] = "愚者",
    [":sakamichi_yu_zhe"] = "锁定技，你的锦囊牌均视为【杀】。出牌阶段，你使用【杀】的限制次数+1；你使用的【杀】的目标上限+1；你使用【杀】的距离+1。",
    ["sakamichi_cheng_yun"] = "乘云",
    [":sakamichi_cheng_yun"] = "限定技，出牌阶段，你可以弃置所有手牌，若如此做，你摸一张牌且本回合内此牌离开手牌时你重复此流程。",
    ["@cheng_yun"] = "乘云",
}

-- 大園 桃子
MomokoOozono = sgs.General(Sakamichi, "MomokoOozono$", "Nogizaka46", 3, false)
SKMC.SanKiSei.MomokoOozono = true
SKMC.SeiMeiHanDan.MomokoOozono = {
    name = {3, 13, 10, 3},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {23, "ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {6, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_shen_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_shen_jing$",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if player:getKingdom() == "Nogizaka46" and not use.card:isKindOf("SkillCard") and use.card:isVirtualCard() and use.card:subcardsLength() == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self:objectName()) and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName())) then
                    room:drawCards(player, 2, self:objectName())
                    if not player:isKongcheng() then
                        local card = room:askForCard(player, ".|.|.|hand!", "@shen_jing_give:" .. p:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
                        if card then
                            room:obtainCard(p, card, false)
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MomokoOozono:addSkill(sakamichi_shen_jing)

sakamichi_ai_ku = sgs.CreateTriggerSkill {
    name = "sakamichi_ai_ku",
    events = {sgs.Damaged, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.Damaged then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local result = SKMC.run_judge(room, player, self:objectName(), ".|heart", false)
                if result.isGood then
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    slash:setSkillName(self:objectName())
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:canSlash(p, slash, false) then
                            targets:append(p)
                        end
                    end
                    if targets:length() ~= 0 then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ai_ku_slash", true)
                        if target then
                            if damage.from and damage.from:isAlive() then
                                room:setPlayerMark(damage.from, "ai_ku_slash_" .. slash:getId(), 1)
                            end
                            room:useCard(sgs.CardUseStruct(slash, player, target), false)
                            if damage.from then
                                room:setPlayerMark(damage.from, "ai_ku_slash_" .. slash:getId(), 0)
                            end
                        end
                    end
                end
            end
        else
            if damage.card and damage.card:getSkillName() == self:objectName() then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("damage:" .. damage.to:objectName() .. "::" .. damage.card:objectName() .. ":" .. SKMC.number_correction(player, 1))) then
                    room:recover(player, sgs.RecoverStruct(player, damage.card, SKMC.number_correction(player, 1)))
                    return true
                end
            end
        end
        return false
    end,
}
MomokoOozono:addSkill(sakamichi_ai_ku)

sakamichi_tu_she_card = sgs.CreateSkillCard {
    name = "sakamichi_tu_sheCard",
    skill_name = "sakamichi_tu_she",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if room:askForChoice(effect.to, self:getSkillName(), "damage=" .. effect.from:objectName() .. "=" .. SKMC.number_correction(effect.from, 1) .. "+gain=" .. effect.from:objectName()) ==
            "damage=" .. effect.from:objectName() .. "=" .. SKMC.number_correction(effect.from ,1 ) then
            room:damage(sgs.DamageStruct(self:objectName(), effect.to, effect.from, SKMC.number_correction(effect.from, 1)))
        else
            if not effect.to:isAllNude() then
                local card = room:askForCardChosen(effect.from, effect.to, "hej", self:getSkillName(), false, sgs.Card_MethodNone)
                room:obtainCard(effect.from, card, room:getCardPlace(card) ~= sgs.Player_PlaceHand)
            end
        end
    end,
}
sakamichi_tu_she = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_tu_she",
    view_as = function(self)
        local cd = sakamichi_tu_she_card:clone()
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_tu_sheCard")
    end,
}
MomokoOozono:addSkill(sakamichi_tu_she)

sgs.LoadTranslationTable {
    ["MomokoOozono"] = "大園 桃子",
    ["&MomokoOozono"] = "大園 桃子",
    ["#MomokoOozono"] = "不再哭泣",
    ["~MomokoOozono"] = "話の分かんない人だ",
    ["designer:MomokoOozono"] = "Cassimolar",
    ["cv:MomokoOozono"] = "大園 桃子",
    ["illustrator:MomokoOozono"] = "Cassimolar",
    ["sakamichi_shen_jing"] = "蜃景",
    [":sakamichi_shen_jing"] = "主公技，乃木坂46势力角色使用卡牌结算完成时，若此牌无对应实体牌，你可以令其摸两张牌并交给你一张手牌。",
    ["sakamichi_shen_jing:invoke"] = "是否发动【%arg】令%src 摸两张牌并交给你一张手牌",
    ["@shen_jing_give"] = "请选择一张手牌交给%src",
    ["sakamichi_ai_ku"] = "爱哭",
    [":sakamichi_ai_ku"] = "当你受到伤害后，你可以判定，若结果不为红桃，你可以选择一名其他角色视为对其使用一张【杀】，若此【杀】对伤害来源造成伤害，你可以防止之并回复1点体力。",
    ["@ai_ku_slash"] = "你可以选择一名其他角色视为对其使用一张【杀】",
    ["sakamichi_ai_ku:damage"] = "是否防止此【%arg】对%src 造成的伤害并回复%arg2点体力",
    ["sakamichi_tu_she"] = "吐舌",
    [":sakamichi_tu_she"] = "出牌阶段限一次，你可以选择一名其他角色，令其选择对你造成1点伤害或令你获得其区域内的一张牌。",
    ["sakamichi_tu_she:damage"] = "对%src造成%arg点伤害",
    ["sakamichi_tu_she:gain"] = "令%src获得你区域内的一张牌",
}

-- 山下 美月
MizukiYamashita = sgs.General(Sakamichi, "MizukiYamashita$", "Nogizaka46", 3, false)
SKMC.SanKiSei.MizukiYamashita = true
SKMC.SeiMeiHanDan.MizukiYamashita = {
    name = {3, 3, 9, 4},
    ten_kaku = {6, "da_ji"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {7, "ji"},
    sou_kaku = {19, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_lian_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_lian_ji$",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) and
            use.to:length() == 1 and use.to:contains(player) and player:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self:objectName()) and not use.card:hasFlag("lian_ji" .. p:objectName()) and
                    room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. use.card:objectName())) then
                    room:drawCards(p, 1, self:objectName())
                    room:setCardFlag(use.card, "lian_ji" .. p:objectName())
                    room:useCard(sgs.CardUseStruct(use.card, player, player, true), true)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MizukiYamashita:addSkill(sakamichi_lian_ji)

sakamichi_jing_ye = sgs.CreateTriggerSkill {
    name = "sakamichi_jing_ye",
    frequency = sgs.Skill_Limited,
    limit_mark = "@jingye",
    events = {sgs.EventPhaseStart, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:hasSkill(self:objectName()) and player:getMark("@jingye") ~= 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@jing_ye_invoke:::" .. self:objectName(), true)
                if target then
                    room:removePlayerMark(player, "@jingye")
                    player:setShownRole(true)
                    SKMC.send_message(room, "#show_role", player, nil, nil, nil, player:getRole())
                    target:setShownRole(true)
                    SKMC.send_message(room, "#show_role", target, nil, nil, nil, target:getRole())
                    local same = false
                    if ((player:getRole() == "lord" or player:getRole() == "loyalist") and (target:getRole() == "lord" or target:getRole() == "loyalist")) or
                        (player:getRole() == "rebel" and target:getRole() == "rebel") then
                        same = true
                    end
                    if same then
                        room:setPlayerMark(target, "HandcardVisible_" .. player:objectName(), 1)
                        room:setPlayerMark(player, "HandcardVisible_" .. target:objectName(), 1)
                    else
                        room:setPlayerMark(target, "&" .. self:objectName() .. "+  +" .. player:getGeneralName(), 1)
                        room:setPlayerMark(target, self:objectName() .. "+" .. player:objectName(), 1)
                        room:setPlayerMark(player, "&" .. self:objectName() .. "+  +" .. target:getGeneralName(), 1)
                        room:setPlayerMark(player, self:objectName() .. "+" .. target:objectName(), 1)
                    end
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark(self:objectName() .. "+" .. player:objectName()) ~= 0 then
                    room:loseHp(p, damage.damage)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MizukiYamashita:addSkill(sakamichi_jing_ye)

sakamichi_yin_an = sgs.CreateTriggerSkill {
    name = "sakamichi_yin_an",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and use.card:isBlack() then
            for _, p in sgs.qlist(use.to) do
                local no_respond_list = use.no_respond_list
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:" .. p:objectName() .. ":" .. self:objectName() .. ":" .. use.card:objectName() .. ":" .. SKMC.number_correction(player, 1))) then
                    room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(player, 1)))
                    table.insert(no_respond_list, p:objectName())
                end
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        return false
    end,
}
sakamichi_yin_an_protect = sgs.CreateProhibitSkill {
    name = "#sakamichi_yin_an_protect",
    frequency = sgs.Skill_Compulsory,
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_yin_an") and (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) and card:isBlack()
    end,
}
MizukiYamashita:addSkill(sakamichi_yin_an)
if not sgs.Sanguosha:getSkill("#sakamichi_yin_an_protect") then SKMC.SkillList:append(sakamichi_yin_an_protect) end

sgs.LoadTranslationTable {
    ["MizukiYamashita"] = "山下 美月",
    ["&MizukiYamashita"] = "山下 美月",
    ["#MizukiYamashita"] = "小恶魔",
    ["~MizukiYamashita"] = "最下位じゃなければ1位",
    ["designer:MizukiYamashita"] = "Cassimolar",
    ["cv:MizukiYamashita"] = "山下 美月",
    ["illustrator:MizukiYamashita"] = "Cassimolar",
    ["sakamichi_lian_ji"] = "恋己",
    [":sakamichi_lian_ji"] = "主公技，乃木坂46势力角色使用基本牌或通常锦囊牌结算完成时，若此牌目标仅为其，你可以摸一张牌令此牌额外结算一次。",
    ["sakamichi_lian_ji:invoke"] = "你可以摸一张牌令%src使用的此【%arg】额外结算一次",
    ["sakamichi_jing_ye"] = "敬业",
    [":sakamichi_jing_ye"] = "限定技，准备阶段，你可以选择一名其他角色，你与其展示身份牌，若你们的胜利条件：相同，本局游戏剩余时间内，你们的手牌互相可见；不同，本局游戏剩余时间内，一方受到伤害后另一方失去等量的体力值。",
    ["@jingye"] = "敬业",
    ["#show_role"] = "%from 的身份为%arg",
    ["@jing_ye_invoke"] = "你可以发动选择一名其他角色发动【%arg】",
    ["sakamichi_yin_an"] = "阴暗",
    [":sakamichi_yin_an"] = "锁定技，你不是黑色基本牌/锦囊牌的合法目标。当你使用黑色基本牌/通常锦囊牌指定目标后，你可以受到目标造成的1点伤害令其无法响应此牌。",
    ["sakamichi_yin_an:invoke"] = "是否发动【%dest】受到来自%src的%arg2点伤害并令其无法响应此【%arg】",
}

-- 阪口 珠美
TamamiSakaguchi = sgs.General(Sakamichi, "TamamiSakaguchi", "Nogizaka46", 4, false)
SKMC.SanKiSei.TamamiSakaguchi = true
SKMC.SeiMeiHanDan.TamamiSakaguchi = {
    name = {7, 3, 10, 9},
    ten_kaku = {10, "xiong"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {19, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_wu_wei_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_wu_wei",
    response_pattern = "slash",
    filter_pattern = "Jink|.|.|hand",
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:addSubcard(card)
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
}
sakamichi_wu_wei = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_wei",
    events = {sgs.CardUsed},
    view_as_skill = sakamichi_wu_wei_view_as,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Slash") and use.card:getSkillName() == self:objectName() then
                room:setCardFlag(use.card, "SlashIgnoreArmor")
            end
        end
        return false
    end,
}
sakamichi_wu_wei_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_wu_wei_target_mod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_wu_wei") and card:getSkillName() == "sakamichi_wu_wei" then
            return 1000
        else
            return 0
        end
    end,
}
TamamiSakaguchi:addSkill(sakamichi_wu_wei)
if not sgs.Sanguosha:getSkill("#sakamichi_wu_wei_target_mod") then SKMC.SkillList:append(sakamichi_wu_wei_target_mod) end

sakamichi_gen_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_gen_xing",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying_data = data:toDying()
        local source = dying_data.who
        if source:objectName() == player:objectName() then
            if player:askForSkillInvoke(self:objectName(), data) then
                local result = SKMC.run_judge(room, player, self:objectName(), "BasicCard")
                if result.isGood then
                    room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                end
            end
        end
    end,
}
TamamiSakaguchi:addSkill(sakamichi_gen_xing)

sakamichi_tou_ming = sgs.CreateTriggerSkill {
    name = "sakamichi_tou_ming",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.to:length() ~= 1 and use.from and use.from:objectName() ~= player:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local nullified_list = use.nullified_list
            table.insert(nullified_list, player:objectName())
            use.nullified_list = nullified_list
            data:setValue(use)
        end
        return false
    end,
}
TamamiSakaguchi:addSkill(sakamichi_tou_ming)

sgs.LoadTranslationTable {
    ["TamamiSakaguchi"] = "阪口 珠美",
    ["&TamamiSakaguchi"] = "阪口 珠美",
    ["#TamamiSakaguchi"] = "有勇无谋",
    ["~TamamiSakaguchi"] = "根性だけは負けません!",
    ["designer:TamamiSakaguchi"] = "Cassimolar",
    ["cv:TamamiSakaguchi"] = "阪口 珠美",
    ["illustrator:TamamiSakaguchi"] = "Cassimolar",
    ["sakamichi_wu_wei"] = "无畏",
    [":sakamichi_wu_wei"] = "你可以将一张【闪】当【杀】使用或打出，你以此法使用的【杀】无距离限制且无视防具。",
    ["sakamichi_gen_xing"] = "根性",
    [":sakamichi_gen_xing"] = "当你进入濒死时，你可以判定，若结果为基本牌，你回复1点体力。",
    ["sakamichi_tou_ming"] = "透明",
    [":sakamichi_tou_ming"] = "锁定技，当你成为其他角色使用牌的目标时，若此牌目标不唯一，则此牌对你无效。",
}

-- 吉田 綾乃クリスティー
AyanoChristieYoshida = sgs.General(Sakamichi, "AyanoChristieYoshida", "Nogizaka46", 4, false)
SKMC.SanKiSei.AyanoChristieYoshida = true
SKMC.SeiMeiHanDan.AyanoChristieYoshida = {
    name = {6, 5, 14, 2, 2, 2, 2, 3, 2, 1},
    ten_kaku = {11, "ji"},
    jin_kaku = {19, "xiong"},
    ji_kaku = {28, "xiong"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "jin",
        san_sai = "da_ji",
    },
}

sakamichi_jia_lao_wai = sgs.CreateTriggerSkill {
    name = "sakamichi_jia_lao_wai",
    events = {sgs.GameStart, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self:objectName()) then
                local kingdom = room:askForKingdom(player)
                player:setTag(self:objectName(), sgs.QVariant(kingdom))
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. kingdom, 1)
            end
        elseif event == sgs.Damaged then
            if player:isAlive() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getKingdom() == p:getKingdom() or player:getKingdom() == p:getTag(self:objectName()):toString() then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            local choice_1 = "1=" .. player:objectName()
                            local choice_2 = "2=" .. player:objectName()
                            if room:askForChoice(p, self:objectName(), choice_1 .. "+" .. choice_2) == choice_1 then
                                room:drawCards(player, 1, self:objectName())
                                if not player:isNude() then
                                    if player:getHandcardNum() + player:getEquips():length() > 2 then
                                        room:askForDiscard(player, self:objectName(), 2, 2, false, true, nil, ".", self:objectName())
                                    else
                                        player:throwAllHandCardsAndEquips()
                                    end
                                end
                                room:drawCards(p, 2, self:objectName())
                                if not p:isNude() then
                                    room:askForDiscard(p, self:objectName(), 1, 1, false, true, nil, ".", self:objectName())
                                else
                                    p:throwAllHandCardsAndEquips()
                                end
                            else
                                room:drawCards(player, 2, self:objectName())
                                if not player:isNude() then
                                    room:askForDiscard(player, self:objectName(), 1, 1, false, true, nil, ".", self:objectName())
                                else
                                    player:throwAllHandCardsAndEquips()
                                end
                                room:drawCards(p, 1, self:objectName())
                                if not p:isNude() then
                                    if p:getHandcardNum() + p:getEquips():length() > 2 then
                                        room:askForDiscard(p, self:objectName(), 2, 2, false, true, nil, ".", self:objectName())
                                    else
                                        p:throwAllHandCardsAndEquips()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
AyanoChristieYoshida:addSkill(sakamichi_jia_lao_wai)

sakamichi_you_zhi = sgs.CreateTriggerSkill {
    name = "sakamichi_you_zhi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Start and player:getMark("you_zhi") ~= 0 then
                local difference = math.abs(player:getHandcardNum() - player:getMark("&" .. self:objectName()))
                if difference ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:drawCards(player, difference, self:objectName())
                end
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if player:getMark("you_zhi") == 0 then
                    room:setPlayerMark(player, "you_zhi", 1)
                end
                room:setPlayerMark(player, "&" .. self:objectName(), player:getHandcardNum())
            end
        end
        return false
    end,
}
AyanoChristieYoshida:addSkill(sakamichi_you_zhi)

sakamichi_quan_neng = sgs.CreateTriggerSkill {
    name = "sakamichi_quan_neng",
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            local skill_list = {}
            for _, skill in sgs.qlist(player:getGeneral():getVisibleSkillList()) do
                table.insert(skill_list, skill:objectName())
            end
            if player:getGeneral2() then
                for _, skill in sgs.qlist(player:getGeneral2():getVisibleSkillList()) do
                    table.insert(skill_list, skill:objectName())
                end
            end
            if #skill_list ~= 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        local skill_name = room:askForChoice(p, self:objectName(), table.concat(skill_list, "+"))
                        room:handleAcquireDetachSkills(p, skill_name)
                        room:loseMaxHp(p)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
AyanoChristieYoshida:addSkill(sakamichi_quan_neng)

sgs.LoadTranslationTable {
    ["AyanoChristieYoshida"] = "吉田 綾乃クリスティー",
    ["&AyanoChristieYoshida"] = "吉田 綾乃クリスティー",
    ["#AyanoChristieYoshida"] = "克里斯蒂",
    ["~AyanoChristieYoshida"] = "世界を平和にするぞ！",
    ["designer:AyanoChristieYoshida"] = "Cassimolar",
    ["cv:AyanoChristieYoshida"] = "吉田 綾乃クリスティー",
    ["illustrator:AyanoChristieYoshida"] = "Cassimolar",
    ["sakamichi_jia_lao_wai"] = "假老外",
    [":sakamichi_jia_lao_wai"] = "游戏开始时，你选择一个势力；一名角色受到伤害后，若其势力与你的势力或你以此法选择的势力相同，你可以令其摸一张牌然后弃置两张牌或摸两张牌然后弃置一张牌，然后你执行另一个选项。",
    ["sakamichi_jia_lao_wai:1"] = "令%src摸一张牌然后弃置两张牌",
    ["sakamichi_jia_lao_wai:2"] = "令%src摸两张牌然后弃置一张牌",
    ["sakamichi_you_zhi"] = "幼稚",
    [":sakamichi_you_zhi"] = "准备阶段，若你的手牌数和你上回合结束阶段手牌数不同，你可以摸等同于差值的牌。",
    ["sakamichi_quan_neng"] = "全能",
    [":sakamichi_quan_neng"] = "其他角色死亡时，你可以获得其武将牌上一个技能，若如此做，你减少1点体力上限。",
}

-- 向井 葉月
HazukiMukai = sgs.General(Sakamichi, "HazukiMukai", "Nogizaka46", 4, false)
SKMC.SanKiSei.HazukiMukai = true
SKMC.SeiMeiHanDan.HazukiMukai = {
    name = {6, 4, 12, 4},
    ten_kaku = {10, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {26, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_re_xue_card = sgs.CreateSkillCard {
    name = "sakamichi_re_xueCard",
    skill_name = "sakamichi_re_xue",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() then
            local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
            duel:deleteLater()
            duel:setSkillName(self:getSkillName())
            return duel:targetFilter(sgs.PlayerList(), to_select, sgs.Self)
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:loseHp(effect.from, SKMC.number_correction(effect.from, 1))
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
        duel:deleteLater()
        duel:setSkillName(self:getSkillName())
        room:useCard(sgs.CardUseStruct(duel, effect.from, effect.to))
    end,
}
sakamichi_re_xue = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_re_xue",
    view_as = function()
        return sakamichi_re_xue_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_re_xueCard")
    end,
}
HazukiMukai:addSkill(sakamichi_re_xue)

sakamichi_lian_zhan = sgs.CreateTriggerSkill {
    name = "sakamichi_lian_zhan",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Duel") then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
                if room:getCurrent():getMark("lian_zhan_" .. player:objectName() .. "_to_" .. p:objectName() .. "_finish_end_clear") == 0 then
                    local duel = sgs.Sanguosha:cloneCard("duel", damage.card:getSuit(), damage.card:getNumber())
                    duel:deleteLater()
                    duel:setSkillName(self:objectName())
                    if duel:targetFilter(sgs.PlayerList(), p, player) then
                        targets:append(p)
                    end
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@lian_zhan_invoke", true)
                if target then
                    room:setPlayerMark(room:getCurrent(), "lian_zhan_" .. player:objectName() .. "_to_" .. damage.to:objectName() .. "_finish_end_clear", 1)
                    local duel = sgs.Sanguosha:cloneCard("duel", damage.card:getSuit(), damage.card:getNumber())
                    duel:deleteLater()
                    duel:setSkillName(self:objectName())
                    room:useCard(sgs.CardUseStruct(duel, player, target, false))
                end
            end
        end
        return false
    end,
}
HazukiMukai:addSkill(sakamichi_lian_zhan)

sakamichi_qiang_yun = sgs.CreateTriggerSkill {
    name = "sakamichi_qiang_yun",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DrawInitialCards, sgs.BeforeCardsMove},
    priority = -1,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawInitialCards then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                for i = 1, 2, 1 do
                    local choices = {}
                    for k, v in pairs(SKMC.Pattern) do
                        if type(v) == "table" then
                            table.insert(choices, k)
                        else
                            table.insert(choices, v)
                        end
                    end
                    if i == 2 then
                        table.insert(choices, "cancel")
                    end
                    local choice
                    local _Pattern = SKMC.Pattern
                    while true do
                        choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                        if _Pattern[choice] ~= nil then
                            _Pattern = _Pattern[choice]
                            choices = {}
                            for k, v in pairs(_Pattern) do
                                if type(v) == "table" then
                                    table.insert(choices, k)
                                else
                                    table.insert(choices, v)
                                end
                            end
                        else
                            break
                        end
                    end
                    if choice ~= "cancel" then
                        local choice_pattern = player:getTag(self:objectName()):toString():split(",")
                        table.insert(choice_pattern, choice)
                        player:setTag(self:objectName(), sgs.QVariant(table.concat(choice_pattern, ",")))
                        if not player:hasFlag(self:objectName()) then
                            room:setPlayerFlag(player, self:objectName())
                        end
                    else
                        break
                    end
                end
            end
        elseif event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and player:hasFlag(self:objectName()) and
                move.to_place == sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_DrawPile) then
                room:setPlayerFlag(player, "-" .. self:objectName())
                local choice_pattern = player:getTag(self:objectName()):toString():split(",")
                player:removeTag(self:objectName())
                local pattern_1, pattern_2
                if #choice_pattern >= 1 then
                    pattern_1 = choice_pattern[1]
                end
                if #choice_pattern == 2 then
                    pattern_2 = choice_pattern[2]
                end
                local move_list = sgs.IntList()
                if pattern_1 ~= nil then
                    for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
                        if sgs.Sanguosha:getEngineCard(id):objectName() == pattern_1 and room:getCardPlace(id) == sgs.Player_DrawPile then
                            move_list:append(id)
                            break
                        end
                    end
                end
                if pattern_2 ~= nil then
                    for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
                        if sgs.Sanguosha:getEngineCard(id):objectName() == pattern_2 and room:getCardPlace(id) == sgs.Player_DrawPile then
                            move_list:append(id)
                            break
                        end
                    end
                end
                for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
                    if room:getCardPlace(id) == sgs.Player_DrawPile then
                        if move_list:length() ~= move.card_ids:length() then
                            move_list:append(id)
                        else
                            break
                        end
                    end
                end
                move.card_ids = move_list
                data:setValue(move)
            end
        end
        return false
    end,
}
HazukiMukai:addSkill(sakamichi_qiang_yun)

sgs.LoadTranslationTable {
    ["HazukiMukai"] = "向井 葉月",
    ["&HazukiMukai"] = "向井 葉月",
    ["#HazukiMukai"] = "铁血南推",
    ["~HazukiMukai"] = "お〜！",
    ["designer:HazukiMukai"] = "Cassimolar",
    ["cv:HazukiMukai"] = "向井 葉月",
    ["illustrator:HazukiMukai"] = "Cassimolar",
    ["sakamichi_re_xue"] = "热血",
    [":sakamichi_re_xue"] = "出牌阶段限一次，你可以失去1点体力视为对一名其他角色使用一张【决斗】。",
    ["sakamichi_lian_zhan"] = "连战",
    [":sakamichi_lian_zhan"] = "当你使用【决斗】对其他角色造成伤害后，你可以视为对另一名其他角色使用一张【决斗】（每回合每名其他角色只可以选择一次）。",
    ["@lian_zhan_invoke"] = "你可以选择另一名其他角色视为对其使用一张【决斗】",
    ["sakamichi_qiang_yun"] = "强运",
    [":sakamichi_qiang_yun"] = "分发起始手牌时，你可以至多选择两次牌名，你的起始手牌中必定包含所选择的牌。",
}

-- 岩本 蓮加
RenkaIwamoto = sgs.General(Sakamichi, "RenkaIwamoto", "Nogizaka46", 4, false)
SKMC.SanKiSei.RenkaIwamoto = true
SKMC.SeiMeiHanDan.RenkaIwamoto = {
    name = {8, 5, 13, 5},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_nv_di_view_as = sgs.CreateViewAsSkill {
    name = "sakamichi_nv_di",
    n = 2,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:isRed() or to_select:isBlack()
        elseif #selected == 1 then
            if selected[1]:isRed() then
                return to_select:isRed()
            elseif selected[1]:isBlack() then
                return to_select:isBlack()
            end
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local suit, number, color
            for _, card in ipairs(cards) do
                if suit and suit ~= card:getSuit() then
                    suit = sgs.Card_NoSuit
                else
                    suit = card:getSuit()
                end
                if number and number ~= card:getNumber() then
                    number = -1
                else
                    number = card:getNumber()
                end
                if card:isRed() then
                    color = "red"
                else
                    color = "black"
                end
            end
            if color == "red" then
                local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", suit, number)
                archery_attack:addSubcard(cards[1])
                archery_attack:addSubcard(cards[2])
                archery_attack:setSkillName(self:objectName())
                return archery_attack
            else
                local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", suit, number)
                savage_assault:addSubcard(cards[1])
                savage_assault:addSubcard(cards[2])
                savage_assault:setSkillName(self:objectName())
                return savage_assault
            end
        end
    end,
}
sakamichi_nv_di = sgs.CreateTriggerSkill {
    name = "sakamichi_nv_di",
    view_as_skill = sakamichi_nv_di_view_as,
    events = {sgs.PreCardUsed, sgs.Damage, sgs.CardFinished, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:getSkillName() == self:objectName() then
                room:addPlayerMark(player, "nv_di", use.to:length())
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() and player:hasSkill(self:objectName()) then
                if player:getMark("nv_di_damage") == 0 then
                    room:addPlayerMark(player, "nv_di_damage")
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == self:objectName() and player:hasSkill(self:objectName()) then
                if player:getMark("nv_di_damage") == 0 then
                    room:drawCards(player, player:getMark("nv_di"), self:objectName())
                    room:setPlayerMark(player, "nv_di", 0)
                else
                    room:setPlayerMark(player, "nv_di", 0)
                    room:setPlayerMark(player, "nv_di_damage", 0)
                end
            end
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()
            if response.m_toCard and response.m_toCard:getSkillName() == self:objectName() then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RenkaIwamoto:addSkill(sakamichi_nv_di)

sakamichi_bao_xiao_card = sgs.CreateSkillCard {
    name = "sakamichi_bao_xiaoCard",
    skill_name = "sakamichi_bao_xiao",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local difference = math.abs(effect.to:getHandcardNum() - effect.to:getMaxCards())
        if difference ~= 0 then
            if effect.to:getHandcardNum() > effect.to:getMaxCards() then
                room:askForDiscard(effect.to, self:getSkillName(), difference, difference, false, false, "@bao_xiao_discard:::" .. difference, ".", self:getSkillName())
            else
                room:drawCards(effect.to, difference, self:getSkillName())
            end
            room:addMaxCards(effect.from, difference)
        end
    end,
}
sakamichi_bao_xiao = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_bao_xiao",
    view_as = function(self)
        return sakamichi_bao_xiao_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_bao_xiaoCard")
    end,
}
RenkaIwamoto:addSkill(sakamichi_bao_xiao)

sgs.LoadTranslationTable {
    ["RenkaIwamoto"] = "岩本 蓮加",
    ["&RenkaIwamoto"] = "岩本 蓮加",
    ["#RenkaIwamoto"] = "青春无敌",
    ["~RenkaIwamoto"] = "じゃーん！",
    ["designer:RenkaIwamoto"] = "Cassimolar",
    ["cv:RenkaIwamoto"] = "岩本 蓮加",
    ["illustrator:RenkaIwamoto"] = "Cassimolar",
    ["sakamichi_nv_di"] = "女帝",
    [":sakamichi_nv_di"] = "出牌阶段，你可以将两张红/黑色牌当【万箭齐发】/【南蛮入侵】使用，其他角色响应你以此法使用的【万箭齐发】/【南蛮入侵】打出【闪】/【杀】时，摸一张牌。你以此法使用的【万箭齐发】/【南蛮入侵】结算完成时，若没有角色受到伤害，你摸等同于此【万箭齐发】/【南蛮入侵】指定目标数量的牌。",
    ["sakamichi_bao_xiao"] = "爆笑",
    [":sakamichi_bao_xiao"] = "出牌阶段限一次，你可以令一名角色手牌摸至或弃置手牌上限，本回合内你的手牌上限+X（X为其因此获得或失去手牌的数量）。",
    ["@bao_xiao_discard"] = "请弃置 %arg 张手牌",
}

-- 与田 祐希
YukiYoda = sgs.General(Sakamichi, "YukiYoda$", "Nogizaka46", 3, false)
SKMC.SanKiSei.YukiYoda = true
SKMC.SeiMeiHanDan.YukiYoda = {
    name = {3, 5, 9, 7},
    ten_kaku = {8, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

YukiYoda:addSkill("sakamichi_shen_jing")

sakamichi_bu_she_yuki_yoda = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_she_yuki_yoda",
    frequency = sgs.Skill_Frequent,
    shiming_skill = true,
    waked_skills = "sakamichi_she_rou",
    events = {sgs.SlashMissed, sgs.SlashHit, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if effect.slash:isBlack() and effect.from and effect.from:isAlive() and effect.to and effect.to:hasSkill(self:objectName()) and effect.to:getMark(self:objectName()) == 0 then
                room:askForUseSlashTo(effect.to, effect.from, "@bu_she_yuki_yoda_invoke:" .. effect.from:objectName(), false, false, true, nil, nil, "bu_she_yuki_yoda")
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("bu_she_yuki_yoda") and effect.from and effect.from:hasSkill(self:objectName()) and effect.from:getMark(self:objectName()) == 0 then
                room:sendShimingLog(effect.from, self)
                room:gainMaxHp(effect.from, SKMC.number_correction(effect.from, 1))
                room:recover(effect.from, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
                room:handleAcquireDetachSkills(effect.from, "sakamichi_she_rou")
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:isBlack() and player:hasSkill(self:objectName()) and player:getMark(self:objectName()) == 0 then
                room:sendShimingLog(player, self, false)
                room:loseHp(player, player:getHp())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YukiYoda:addSkill(sakamichi_bu_she_yuki_yoda)

sakamichi_she_rou_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_she_rou",
    view_as = function(self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("she_rou_used") and sgs.Slash_IsAvailable(player)
    end ,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and not player:hasFlag("she_rou_used")
    end
}
sakamichi_she_rou = sgs.CreateTriggerSkill {
    name = "sakamichi_she_rou",
    view_as_skill = sakamichi_she_rou_view_as,
    events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("she_rou_used") then
                        room:setPlayerFlag(p, "-she_rou_used")
                    end
                end
            end
        else
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                if use.card:getSkillName() == self:objectName() then
                    card = use.card
                end
            else
                local response = data:toCardResponse()
                if response.m_card:getSkillName() == self:objectName() then
                    card = response.m_card
                end
            end
            if card then
                room:setPlayerFlag(player, "she_rou_used")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_she_rou") then SKMC.SkillList:append(sakamichi_she_rou) end

sakamichi_ye_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_ye_xing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardFinished, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.card:hasFlag("ye_xing") then
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
                room:setCardFlag(use.card, "-ye_xing")
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if player:getPhase() ~= sgs.Player_NotActive and damage.card and damage.card:isKindOf("Slash") then
                room:setCardFlag(damage.card, "ye_xing")
            end
        end
        return false
    end,
}
sakamichi_ye_xing_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_ye_xing_distance",
    correct_func = function(self, from, to)
        if from:hasSkill("sakamichi_ye_xing") then
            return -SKMC.number_correction(from, 1)
        end
    end,
}
YukiYoda:addSkill(sakamichi_ye_xing)
if not sgs.Sanguosha:getSkill("#sakamichi_ye_xing_distance") then SKMC.SkillList:append(sakamichi_ye_xing_distance) end

sgs.LoadTranslationTable {
    ["YukiYoda"] = "与田 祐希",
    ["&YukiYoda"] = "与田 祐希",
    ["#YukiYoda"] = "天下第一",
    ["~YukiYoda"] = "ちっちゃいけど色気はあるとよ!",
    ["designer:YukiYoda"] = "Cassimolar",
    ["cv:YukiYoda"] = "与田 祐希",
    ["illustrator:YukiYoda"] = "Cassimolar",
    ["sakamichi_bu_she_yuki_yoda"] = "捕蛇",
    [":sakamichi_bu_she_yuki_yoda"] = "使命技，当你闪避黑色【杀】后，你可以对此【杀】使用者使用一张【杀】。成功：当你以此法使用的【杀】命中后，你增加1点体力上限并回复1点体力，然后获得【蛇肉】。失败：当你受到黑色【杀】造成的伤害后，失去所有体力。",
    ["@bu_she_yuki_yoda_invoke"] = "你可以对%src使用一张【杀】",
    ["sakamichi_she_rou"] = "蛇肉",
    [":sakamichi_she_rou"] = "<font color=\"#008000\"><b>每回合限一次</b></font>，当你需要使用或打出一张【杀】时，你可以视为使用或打出一张【杀】。",
    ["sakamichi_ye_xing"] = "野性",
    [":sakamichi_ye_xing"] = "锁定技，你计算与其他角色的距离-1。你的回合内，当你使用【杀】造成伤害后，此【杀】不计入使用次数限制。",
}

-- 久保 史緒里
ShioriKubo = sgs.General(Sakamichi, "ShioriKubo", "Nogizaka46", 4, false)
SKMC.SanKiSei.ShioriKubo = true
SKMC.SeiMeiHanDan.ShioriKubo = {
    name = {3, 9, 5, 14, 7},
    ten_kaku = {12, "xiong"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {26, "xiong"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_bo_ai = sgs.CreateTriggerSkill {
    name = "sakamichi_bo_ai",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("BasicCard") then
            local legal = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not use.to:contains(p) and not room:isProhibited(player, p, use.card) then
                    if use.card:targetFixed() then
                        if not use.card:isKindOf("Peach") or p:isWounded() then
                            legal:append(p)
                        end
                    else
                        if use.card:targetFilter(sgs.PlayerList(), p, player) then
                            legal:append(p)
                        end
                    end
                end
            end
            if not legal:isEmpty() then
                local extra_targets = sgs.SPlayerList()
                while not legal:isEmpty() and not player:isKongcheng() do
                    local target = room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1, legal,
                            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), self:objectName(), nil), "@bo_ai_invoke:::" .. use.card:objectName(), true)
                    if target then
                        legal:removeOne(target)
                        extra_targets:append(target)
                    else
                        break
                    end
                end
                if not extra_targets:isEmpty() then
                    for _, p in sgs.qlist(extra_targets) do
                        use.to:append(p)
                    end
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}
ShioriKubo:addSkill(sakamichi_bo_ai)

sakamichi_shi_qu = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_qu",
    events = {sgs.CardUsed, sgs.HpChanged, sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and player:objectName() == room:getCurrent():objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:hasFlag("shi_qu_used") and
                        room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. use.card:objectName())) then
                        local choices = {"0"}
                        for i = 1, room:getAlivePlayers():length(), 1 do
                            table.insert(choices, tostring(i))
                        end
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
                        local num = tonumber(choice)
                        SKMC.send_message(room, "#shi_qu_guess", p, player, nil, use.card:toString(), self:objectName(), num)
                        room:setPlayerMark(p, "shi_qu_" .. use.card:getId(), num)
                        room:setPlayerFlag(p, "shi_qu_used")
                        room:setCardFlag(use.card, "shi_qu")
                    end
                end
            end
        elseif event == sgs.HpChanged then
            local damage = data:toDamage()
            local recover = data:toRecover()
            if damage and damage.card and damage.card:hasFlag("shi_qu") and damage.damage > 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("shi_qu_" .. damage.card:getId()) ~= 0 then
                        room:addPlayerMark(p, "shi_qu_record_" .. damage.card:getId(), 1)
                    end
                end
            end
            if recover and recover.card and recover.card:hasFlag("shi_qu") and recover.recover > 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("shi_qu_" .. recover.card:getId()) ~= 0 then
                        room:addPlayerMark(p, "shi_qu_record_" .. recover.card:getId(), 1)
                    end
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("shi_qu") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    local guess_num = p:getMark("shi_qu_" .. use.card:getId())
                    local record_num = p:getMark("shi_qu_record_" .. use.card:getId())
                    room:setPlayerMark(p, "shi_qu_" .. use.card:getId(), 0)
                    room:setPlayerMark(p, "shi_qu_record_" .. use.card:getId(), 0)
                    SKMC.send_message(room, "#shi_qu_record", player, nil, nil, use.card:toString(), record_num)
                    if guess_num == record_num then
                        SKMC.send_message(room, "#shi_qu_guess_right", p)
                        room:drawCards(p, record_num, self:objectName())
                    else
                        SKMC.send_message(room, "#shi_qu_guess_wrong", p)
                    end
                end
                room:setCardFlag(use.card, "-shi_qu")
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:hasFlag("shi_qu_used") then
                        room:setPlayerFlag(p, "-shi_qu_used")
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ShioriKubo:addSkill(sakamichi_shi_qu)

sgs.LoadTranslationTable {
    ["ShioriKubo"] = "久保 史緒里",
    ["&ShioriKubo"] = "久保 史緒里",
    ["#ShioriKubo"] = "未来可以期",
    ["~ShioriKubo"] = "一番なんてないんだから",
    ["designer:ShioriKubo"] = "Cassimolar",
    ["cv:ShioriKubo"] = "久保 史緒里",
    ["illustrator:ShioriKubo"] = "Cassimolar",
    ["sakamichi_bo_ai"] = "博爱",
    [":sakamichi_bo_ai"] = "你使用基本牌时，若存在不为此牌目标的合法目标，你可以分别交给任意名为此牌的合法目标的其他角色一张手牌，然后将这些角色添加为此牌的额外目标。",
    ["@bo_ai_invoke"] = "你可以将一张手牌交给一名其他合法目标令其成为此【%arg】的额外目标",
    ["sakamichi_shi_qu"] = "识曲",
    [":sakamichi_shi_qu"] = "每回合限一次，当前回合角色使用基本牌或通常锦囊牌时，你可以猜测因此牌体力值发生变化的角色数，若猜中则你摸等量的牌。",
    ["sakamichi_shi_qu:invoke"] = "是否发动【%arg】猜测因%src 使用的【%arg2】体力值变化的角色数",
    ["#shi_qu_guess"] = "%from 发动【%arg】猜测因%to 使用的%card而体力值变化的角色为<font color\"Yellow\"><b>%arg2</b></font>名",
    ["#shi_qu_record"] = "因%from 使用的%card而体力值变化的角色为<font color\"Yellow\"><b>%arg</b></font>名",
    ["#shi_qu_guess_right"] = "%from 猜对了",
    ["#shi_qu_guess_wrong"] = "%from 猜错了",
}

-- 伊藤 理々杏
RiriaIto = sgs.General(Sakamichi, "RiriaIto", "Nogizaka46", 4, false)
SKMC.SanKiSei.RiriaIto = true
SKMC.SeiMeiHanDan.RiriaIto = {
    name = {6, 18, 11, 3, 7},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {29, "te_shu_ge"},
    ji_kaku = {21, "ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {45, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fa_kun = sgs.CreateTriggerSkill {
    name = "sakamichi_fa_kun",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseProceeding, sgs.TurnedOver},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.CardUsed or event == sgs.CardResponded) and player:getPhase() == sgs.Player_Play then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if not card:isKindOf("SkillCard") then
                room:addPlayerMark(player, "fa_kun_used_" .. SKMC.true_name(card) .. "_finish_end_clear", 1)
            end
        elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "fa_kun_used_") and player:getMark(mark) >= 2 then
                    player:turnOver()
                end
            end
        elseif event == sgs.TurnedOver then
            if player:faceUp() then
                room:drawCards(player, 3, self:objectName())
                room:askForUseCard(player, "slash", "@askforslash")
            else
                if player:isWounded() then
                    room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                end
            end
        end
        return false
    end,
}
RiriaIto:addSkill(sakamichi_fa_kun)

sakamichi_pi_ka = sgs.CreateFilterSkill {
    name = "sakamichi_pi_ka",
    view_filter = function(self, card)
        return card:isKindOf("DelayedTrick")
    end,
    view_as = function(self, card)
        local FuLei = sgs.Sanguosha:cloneCard("FuLei", card:getSuit(), card:getNumber())
        FuLei:setSkillName(self:objectName())
        local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
        wrap:takeOver(FuLei)
        return wrap
    end,
}
sakamichi_pi_ka_damage = sgs.CreateTriggerSkill {
    name = "#sakamichi_pi_ka_damage",
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.ConfirmDamage, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            damage.nature = sgs.DamageStruct_Thunder
            data:setValue(damage)
        else
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Thunder then
                SKMC.send_message(room, "#pi_ka", damage.to, nil, nil, nil, "sakamichi_pi_ka")
                room:setEmotion(damage.to, "skill_nullify")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill("sakamichi_pi_ka")
    end,
}
RiriaIto:addSkill(sakamichi_pi_ka)
if not sgs.Sanguosha:getSkill("#sakamichi_pi_ka_damage") then SKMC.SkillList:append(sakamichi_pi_ka_damage) end

sgs.LoadTranslationTable {
    ["RiriaIto"] = "伊藤 理々杏",
    ["&RiriaIto"] = "伊藤 理々杏",
    ["#RiriaIto"] = "南国之风",
    ["~RiriaIto"] = "乃木坂に南国の風を吹かせます",
    ["designer:RiriaIto"] = "Cassimolar",
    ["cv:RiriaIto"] = "伊藤 理々杏",
    ["illustrator:RiriaIto"] = "Cassimolar",
    ["sakamichi_fa_kun"] = "乏困",
    [":sakamichi_fa_kun"] = "锁定技，结束阶段，若本回合出牌阶段你使用过至少两张同名卡牌，你翻面；你牌翻至背面/正面向上时回复1点体力/摸三张牌并可以使用一张【杀】。",
    ["sakamichi_pi_ka"] = "皮卡",
    [":sakamichi_pi_ka"] = "锁定技，你的延时类锦囊均视为【浮雷】。你造成的伤害均为雷电伤害。防止你受到的雷电伤害。",
    ["#pi_ka"] = "%from 的【%arg】被触发，%from 受到的此次雷电伤害被防止",
}

-- 梅澤 美波
MinamiUmezawa = sgs.General(Sakamichi, "MinamiUmezawa", "Nogizaka46", 4, false)
SKMC.SanKiSei.MinamiUmezawa = true
SKMC.SeiMeiHanDan.MinamiUmezawa = {
    name = {10, 16, 9, 8},
    ten_kaku = {26, "xiong"},
    jin_kaku = {25, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {43, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_shen_chang = sgs.CreateTriggerSkill {
    name = "sakamichi_shen_chang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.SlashProceed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(use.to) do
                    if player:distanceTo(p) > SKMC.number_correction(player, 1) then
                        if use.m_addHistory then
                            room:addPlayerHistory(player, use.card:getClassName(), -1)
                            break
                        end
                    end
                end
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasSkill(self:objectName()) and effect.from:distanceTo(effect.to) == SKMC.number_correction(effect.from, 1) then
                room:slashResult(effect, nil)
                return true
            end
        end
        return false
    end,
}
MinamiUmezawa:addSkill(sakamichi_shen_chang)

sakamichi_shi_fu_card = sgs.CreateSkillCard {
    name = "sakamichi_shi_fuCard",
    skill_name = "sakamichi_shi_fu",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@shi_fu")
        room:drawCards(effect.from, effect.from:getLostHp(), self:getSkillName())
        room:addPlayerMark(effect.to, "Armor_Nullified")
        room:setPlayerFlag(effect.from, "shi_fu")
        room:setPlayerFlag(effect.from, "shi_fu_" .. effect.to:objectName())
    end
}
sakamichi_shi_fu_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_shi_fu",
    view_as = function()
        return sakamichi_shi_fu_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@shi_fu") ~= 0
    end,
}
sakamichi_shi_fu = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_fu",
    frequency = sgs.Skill_Limited,
    limit_mark = "@shi_fu",
    view_as_skill = sakamichi_shi_fu_view_as,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if player:hasFlag("shi_fu") then
                local refresh = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if player:hasFlag("shi_fu_" .. p:objectName()) then
                        room:setPlayerFlag(player, "-shi_fu_" .. p:objectName())
                        room:removePlayerMark(p, "Armor_Nullified")
                        refresh = false
                    end
                end
                if refresh then
                    room:setPlayerMark(player, "@shi_fu", 1)
                end
                room:setPlayerFlag(player, "-shi_fu")
            end
        end
        return false
    end,
}
MinamiUmezawa:addSkill(sakamichi_shi_fu)

sgs.LoadTranslationTable {
    ["MinamiUmezawa"] = "梅澤 美波",
    ["&MinamiUmezawa"] = "梅澤 美波",
    ["#MinamiUmezawa"] = "勇者",
    ["~MinamiUmezawa"] = "それも私たちの宿命です！！！",
    ["designer:MinamiUmezawa"] = "Cassimolar",
    ["cv:MinamiUmezawa"] = "梅澤 美波",
    ["illustrator:MinamiUmezawa"] = "Cassimolar",
    ["sakamichi_shen_chang"] = "身长",
    [":sakamichi_shen_chang"] = "锁定技，你对与其距离不为1角色使用【杀】不计入次数限制，你对与其距离为1的角色使用【杀】无法闪避。",
    ["sakamichi_shi_fu"] = "识服",
    [":sakamichi_shi_fu"] = "限定技，出牌阶段，你可以摸X张牌并令一名其他角色本回合内防具失效（X为你已损失体力值），本回合结束阶段，若其已死亡此技能视为未曾发动。",
    ["@shi_fu"] = "识服",
}

-- 佐藤 楓
KaedeSato = sgs.General(Sakamichi, "KaedeSato", "Nogizaka46", 3, false)
SKMC.SanKiSei.KaedeSato = true
SKMC.SeiMeiHanDan.KaedeSato = {
    name = {7, 18, 13},
    ten_kaku = {25, "ji"},
    jin_kaku = {31, "da_ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_bang_du = sgs.CreateTriggerSkill {
    name = "sakamichi_bang_du",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PreCardUsed, sgs.PreCardResponded, sgs.EventLoseSkill, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() then
                if player:getMark("&" .. self:objectName()) ~= 0 then
                    room:setPlayerMark(player, "&" .. self:objectName(), 0)
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
                if player:getMark("&" .. self:objectName()) ~= 0 then
                    room:setPlayerMark(player, "&" .. self:objectName(), 0)
                end
            end
        elseif player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
            local card
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and not card:isKindOf("SkillCard") then
                local jie_li_num = SKMC.number_correction(player, 1) * player:getEquips():length()
                local num = SKMC.number_correction(player, 4)
                if player:hasSkill("sakamichi_jie_li") then
                    num = num + jie_li_num
                end
                if not card:isVirtualCard() then
                    if room:getCardPlace(card:getId()) == sgs.Player_PlaceHand then
                        room:addPlayerMark(player, "&" .. self:objectName())
                    end
                else
                    for _, id in sgs.qlist(card:getSubcards()) do
                        if room:getCardPlace(id) == sgs.Player_PlaceHand then
                            room:addPlayerMark(player, "&" .. self:objectName())
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_bang_du_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_bang_du_target_mod",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_bang_du") then
            return 1000
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_bang_du") then
            return 1000
        else
            return 0
        end
    end,
}

sakamichi_bang_du_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_bang_du_card_limit",
    limit_list = function(self, player)
        if player:hasSkill("sakamichi_bang_du") then
            local num = SKMC.number_correction(player, 4)
            if player:hasSkill("sakamichi_jie_li") then
                num = num + SKMC.number_correction(player, 1) * player:getEquips():length()
            end
            if player:getMark("&sakamichi_bang_du") >= num then
                return "use"
            end
        end
        return ""
    end,
    limit_pattern = function(self, player)
        if player:hasSkill("sakamichi_bang_du") then
            local num = SKMC.number_correction(player, 4)
            if player:hasSkill("sakamichi_jie_li") then
                num = num + SKMC.number_correction(player, 1) * player:getEquips():length()
            end
            if player:getMark("&sakamichi_bang_du") >= num then
                return ".|.|.|hand"
            end
        end
        return ""
    end,
}

KaedeSato:addSkill(sakamichi_bang_du)
if not sgs.Sanguosha:getSkill("#sakamichi_bang_du_target_mod") then SKMC.SkillList:append(sakamichi_bang_du_target_mod) end
if not sgs.Sanguosha:getSkill("#sakamichi_bang_du_card_limit") then SKMC.SkillList:append(sakamichi_bang_du_card_limit) end

sakamichi_jie_li = sgs.CreateTriggerSkill {
    name = "sakamichi_jie_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        local equips_num = player:getEquips():length()
        local num = math.floor(equips_num / SKMC.number_correction(player, 2))
        data:setValue(n + num)
        return false
    end,
}
KaedeSato:addSkill(sakamichi_jie_li)

sakamichi_kou_sha = sgs.CreateTriggerSkill {
    name = "sakamichi_kou_sha",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.damage and dying.damage.card and dying.damage.card:isKindOf("Slash") and
            dying.damage.from and dying.damage.from:hasSkill(self:objectName()) and dying.damage.from:hasEquipArea() and
            room:askForSkillInvoke(dying.damage.from, self:objectName(),
            sgs.QVariant("invoke:" .. dying.who:objectName() .. "::" .. self:objectName() .. ":" .. SKMC.number_correction(dying.damage.from, 1))) then
            local equips_area = {"weapon_area", "armor_area", "offensive_horse_area", "defensive_horse_area", "treasure_area"}
            local equip_area = {}
            if dying.damage.from:hasWeaponArea() then
                table.insert(equip_area, "weapon_area")
            end
            if dying.damage.from:hasArmorArea() then
                table.insert(equip_area, "armor_area")
            end
            if dying.damage.from:hasOffensiveHorseArea() then
                table.insert(equip_area, "offensive_horse_area")
            end
            if dying.damage.from:hasDefensiveHorseArea() then
                table.insert(equip_area, "defensive_horse_area")
            end
            if dying.damage.from:hasTreasureArea() then
                table.insert(equip_area, "treasure_area")
            end
            if #equip_area > 0 then
                local choice = room:askForChoice(dying.damage.from, self:objectName(), table.concat(equip_area, "+"))
                for k, v in ipairs(equips_area) do
                    if v == choice then
                        room:loseMaxHp(dying.damage.from, SKMC.number_correction(dying.damage.from, 1))
                        dying.damage.from:throwEquipArea(k - 1)
                        room:killPlayer(dying.who, dying.damage)
                        break
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KaedeSato:addSkill(sakamichi_kou_sha)

sgs.LoadTranslationTable {
    ["KaedeSato"] = "佐藤 楓",
    ["&KaedeSato"] = "佐藤 楓",
    ["#KaedeSato"] = "棒读偶像",
    ["~KaedeSato"] = "ソウラツイデスナオッチャッテテ···",
    ["designer:KaedeSato"] = "Cassimolar",
    ["cv:KaedeSato"] = "佐藤 楓",
    ["illustrator:KaedeSato"] = "Cassimolar",
    ["sakamichi_bang_du"] = "棒读",
    [":sakamichi_bang_du"] = "锁定技，你使用牌无距离和次数限制，但出牌阶段你至多使用4张手牌。",
    ["sakamichi_jie_li"] = "接力",
    [":sakamichi_jie_li"] = "锁定技，你【棒读】中的数字+X，摸阶段你额外摸X/2张牌（向下取整，X为你装备区装备数）。",
    ["sakamichi_kou_sha"] = "扣杀",
    [":sakamichi_kou_sha"] = "当你使用【杀】令一名角色进入濒死时，你可以失去1点体力上限并废除一个装备区，令其直接死亡。",
    ["sakamichi_kou_sha:invoke"] = "是否发动【%arg】失去%arg2点体力上限并废除一个装备区令%src立即死亡"
}

-- 田村 真佑
MayuTamura = sgs.General(Sakamichi, "MayuTamura", "Nogizaka46", 3, false)
SKMC.YonKiSei.MayuTamura = true
SKMC.SeiMeiHanDan.MayuTamura = {
    name = {5, 7, 10, 7},
    ten_kaku = {12, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_da_gong = sgs.CreateTriggerSkill {
    name = "sakamichi_da_gong",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging, sgs.Damage, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
            if not player:hasFlag("da_gong_damage") then
                room:addPlayerMark(player, "&" .. self:objectName(), SKMC.number_correction(player, 1))
            end
        elseif event == sgs.Damage then
            room:setPlayerFlag(player, "da_gong_damage")
            room:setPlayerMark(player, "&" .. self:objectName(), 0)
        elseif event == sgs.DrawNCards then
            data:setValue(data:toInt() + player:getMark("&" .. self:objectName()))
        end
        return false
    end,
}
MayuTamura:addSkill(sakamichi_da_gong)

sakamichi_qiao_shou = sgs.CreateTriggerSkill {
    name = "sakamichi_qiao_shou",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local list = sgs.IntList()
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isKindOf("Slash") or card:isKindOf("EquipCard") then
                    list:append(card:getId())
                end
            end
            for _, id in sgs.qlist(player:getEquipsId()) do
                list:append(id)
            end
            local target = room:askForYiji(player, list, self:objectName(), false, false, true, 1, room:getOtherPlayers(player),
                            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), self:objectName(), nil), "@qiao_shou_invoke")
            if target then
                local target_List = room:getOtherPlayers(target)
                target_List:removeOne(player)
                local slash_target = room:askForPlayerChosen(player, target_List, self:objectName(), "@qiao_shou_slash:" .. target:objectName(), false, true)
                if not room:askForUseSlashTo(target, slash_target, "@qiao_shou_slash_to:" .. slash_target:objectName()) then
                    if target:getEquips():length() ~= 0 or target:getJudgingArea():length() ~= 0 then
                        local _target = sgs.SPlayerList()
                        _target:append(target)
                        room:moveField(player, self:objectName(), false, "ej", _target)
                    end
                end
            end
        end
        return false
    end,
}
MayuTamura:addSkill(sakamichi_qiao_shou)

sakamichi_zhu_ren_card = sgs.CreateSkillCard {
    name = "sakamichi_zhu_renCard",
    skill_name = "sakamichi_zhu_ren",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:isWounded()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if self:getSubcards():length() ~= 0 then
            if sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit() ~= sgs.Card_Heart then
            room:setPlayerFlag(effect.from, "zhu_ren_used")
            end
        else
            room:loseHp(effect.from, SKMC.number_correction(effect.from, 1))
        end
        room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)), true)
    end,
}
sakamichi_zhu_ren = sgs.CreateViewAsSkill {
    name = "sakamichi_zhu_ren",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        local cd = sakamichi_zhu_ren_card:clone()
        if #cards ~= 0 then
            cd:addSubcard(cards[1])
        end
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("zhu_ren_used")
    end,
}
MayuTamura:addSkill(sakamichi_zhu_ren)

sgs.LoadTranslationTable {
    ["MayuTamura"] = "田村 真佑",
    ["&MayuTamura"] = "田村 真佑",
    ["#MayuTamura"] = "厂妹",
    ["~MayuTamura"] = "私 面白い路線じゃないから",
    ["designer:MayuTamura"] = "Cassimolar",
    ["cv:MayuTamura"] = "田村 真佑",
    ["illustrator:MayuTamura"] = "Cassimolar",
    ["sakamichi_da_gong"] = "打工",
    [":sakamichi_da_gong"] = "锁定技，结束阶段，若本回合内你未造成伤害，你的摸牌阶段额定摸牌数+1，直到你于回合内造成伤害为止。",
    ["sakamichi_qiao_shou"] = "巧手",
    [":sakamichi_qiao_shou"] = "准备阶段，你可以交给一名其他角色一张【杀】或装备牌，令其对另一名你选择的其他角色使用一张【杀】，若其未如此做，你可以移动其判定区/装备区的一张牌。",
    ["@qiao_shou_invoke"] = "你可以交给一名其他角色一张【杀】或装备牌",
    ["@qiao_shou_slash"] = "请选择令%src使用【杀】的目标",
    ["@qiao_shou_slash_to"] = "请对%src使用一张【杀】",
    ["sakamichi_zhu_ren"] = "主任",
    [":sakamichi_zhu_ren"] = "出牌阶段限一次，你可以弃置一张手牌或失去1点体力令一名其他角色回复1点体力，若以此法弃置的牌为红桃或因此失去体力，此技能视为未曾发动。",
}

-- 林 瑠奈
RunaHayashi = sgs.General(Sakamichi, "RunaHayashi", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.RunaHayashi = true
SKMC.SeiMeiHanDan.RunaHayashi = {
    name = {8, 14, 8},
    ten_kaku = {8, "ji"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fan_lai_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_fan_lai",
    view_as = function(self)
        local cd = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(sgs.Self:getMark("fan_lai_play_end_clear")):objectName(),
                                            sgs.Sanguosha:getCard(sgs.Self:getMark("fan_lai_play_end_clear")):getSuit(),
                                            sgs.Sanguosha:getCard(sgs.Self:getMark("fan_lai_play_end_clear")):getNumber())
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        if player:getMark("fan_lai_play_end_clear") == 0 and player:getMark("fan_lai_play_end_clear") ~= 0 then
            if sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName() == "analeptic" then
                return sgs.Analeptic_IsAvailable(player)
            end
            if string.find(sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName(), "slash") then
                return sgs.Slash_IsAvailable(player)
            end
            if sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName() == "collateral" then
                local has_weapon = false
                for _, p in sgs.qlist(player:getAliveSiblings()) do
                    if p:getWeapon() then
                        has_weapon = true
                        break
                    end
                end
                return has_weapon
            end
            return true
        end
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getPhase() == sgs.Player_Play and player:getMark("fan_lai_play_end_clear") ~= 0 and player:getMark("fan_lai_play_end_clear") == 0 and
                sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName() == pattern
    end,
    enabled_at_nullification = function(self, player)
        return player:getPhase() == sgs.Player_Play and player:getMark("fan_lai_play_end_clear") ~= 0 and player:getMark("fan_lai_play_end_clear") == 0 and
                sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName() == "nullification"
    end,
}
sakamichi_fan_lai = sgs.CreateTriggerSkill {
    name = "sakamichi_fan_lai",
    view_as_skill = sakamichi_fan_lai_view_as,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed and player:getPhase() ~= sgs.Player_NotActive then
            local use = data:toCardUse()
            if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) and not use.card:isVirtualCard() then
                room:setPlayerMark(player, "fan_lai_play_end_clear", use.card:getId())
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, self:objectName()) then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. use.card:objectName(), 1)
            end
            if use.card:getSkillName() == self:objectName() then
                room:setPlayerMark(player, "fan_lai_play_end_clear", 1)
            end
        end
    end,
}
RunaHayashi:addSkill(sakamichi_fan_lai)

sakamichi_bai_yan_card = sgs.CreateSkillCard {
    name = "sakamichi_bai_yanCard",
    skill_name = "sakamichi_bai_yan",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "fan_lai_play_end_clear", 0)
    end,
}
sakamichi_bai_yan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_bai_yan",
    expand_pile = "raisu",
    filter_pattern = ".|.|.|raisu",
    view_as = function(self, card)
        local cd = sakamichi_bai_yan_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:getPile("raisu"):isEmpty() and not player:hasUsed("#sakamichi_bai_yanCard")
    end,
}
sakamichi_bai_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_bai_yan",
    view_as_skill = sakamichi_bai_yan_view_as,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:loseHp(player, SKMC.number_correction(player, 1))
            room:drawCards(player, 1, self:objectName())
            if damage.card then
                local ids = sgs.IntList()
                if damage.card:isVirtualCard() then
                    ids = damage.card:getSubcards()
                else
                    ids:append(damage.card:getEffectiveId())
                end
                if ids:length() > 0 then
                    local all_place_table = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                            all_place_table = false
                            break
                        end
                    end
                    if all_place_table then
                        room:obtainCard(player, damage.card)
                    end
                end
                if not player:isKongcheng() then
                    local card_id
                    if player:getHandcardNum() == 1 then
                        card_id = player:handCards():first()
                    else
                        local card = room:askForExchange(player, self:objectName(), 1, 1, false, "@bai_yan_push")
                        card_id = card:getEffectiveId()
                    end
                    player:addToPile("raisu", card_id)
                end
            end
        end
        return false
    end,
}
RunaHayashi:addSkill(sakamichi_bai_yan)

sgs.LoadTranslationTable {
    ["RunaHayashi"] = "林 瑠奈",
    ["&RunaHayashi"] = "林 瑠奈",
    ["#RunaHayashi"] = "林皇",
    ["~RunaHayashi"] = "ライスください",
    ["designer:RunaHayashi"] = "Cassimolar",
    ["cv:RunaHayashi"] = "林 瑠奈",
    ["illustrator:RunaHayashi"] = "Cassimolar",
    ["sakamichi_fan_lai"] = "饭来",
    [":sakamichi_fan_lai"] = "出牌阶段限一次，你可以视为使用了本回合上一张使用的非虚拟基本牌或通常锦囊牌。",
    ["sakamichi_bai_yan"] = "白眼",
    [":sakamichi_bai_yan"] = "当你受到一次伤害后，你可以失去1点体力并摸一张牌，然后获得造成伤害的牌，若如此做，你须将一张手牌置于武将牌上称为「米饭」。出牌阶段限一次，你可以移去一张「米饭」令【饭来】视为未发动过。",
    ["@bai_yan_push"] = "请将一张手牌置于武将牌上",
    ["raisu"] = "米饭",
}

-- 黒見 明香
HarukaKuromi = sgs.General(Sakamichi, "HarukaKuromi", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.HarukaKuromi = true
SKMC.SeiMeiHanDan.HarukaKuromi = {
    name = {11, 7, 8, 9},
    ten_kaku = {18, "ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "da_ji",
    },
}

sakamichi_san_liu_jiu = sgs.CreateTriggerSkill {
    name= "sakamichi_san_liu_jiu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == "@clock_time" then
            local n = player:getMark("@clock_time")
            for _, p in sgs.qlist(room:getAllPlayers(true)) do
                if p:hasSkill(self:objectName()) and p:isDead() then
                    if n == SKMC.number_correction(p, 3) or n == SKMC.number_correction(p, 6) or n == SKMC.number_correction(p, 9) then
                        room:revivePlayer(p)
                        room:drawCards(p, n, self:objectName())
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HarukaKuromi:addSkill(sakamichi_san_liu_jiu)

sakamichi_jian_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_jian_shu",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged, sgs.PreCardUsed, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName() ~= player:objectName() and damage.from:getWeapon() then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:obtainCard(player, damage.from:getWeapon())
                end
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play and use.card:getSkillName() ~= self:objectName() then
                for _, p in sgs.qlist(use.to) do
                    room:setPlayerMark(player, self:objectName() .. "_" .. p:objectName() .. "_used_play_end_clear", 1)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Weapon") then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                slash:deleteLater()
                slash:setSkillName(self:objectName())
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:canSlash(p, slash, false) then
                        targets:append(p)
                    end
                end
                if targets:length() ~= 0 then
                    room:useCard(sgs.CardUseStruct(slash, player, targets))
                end
            end
        end
        return false
    end,
}
sakamichi_jian_shu_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_jian_shu_target_mod",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_jian_shu") and from:getWeapon() and from:inMyAttackRange(to) and
            from:getMark("sakamichi_jian_shu_" .. to:objectName() .. "_used_play_end_clear") == 0 then
            return 1000
        else
            return 0
        end
    end,
}
HarukaKuromi:addSkill(sakamichi_jian_shu)
if not sgs.Sanguosha:getSkill("#sakamichi_jian_shu_target_mod") then SKMC.SkillList:append(sakamichi_jian_shu_target_mod) end

sgs.LoadTranslationTable {
    ["HarukaKuromi"] = "黒見 明香",
    ["&HarukaKuromi"] = "黒見 明香",
    ["#HarukaKuromi"] = "功夫美少女",
    ["~HarukaKuromi"] = "考えるな感じろ",
    ["designer:HarukaKuromi"] = "Cassimolar",
    ["cv:HarukaKuromi"] = "黒見 明香",
    ["illustrator:HarukaKuromi"] = "Cassimolar",
    ["sakamichi_san_liu_jiu"] = "三六九",
    [":sakamichi_san_liu_jiu"] = "锁定技，第3/6/9轮开始时，若你已死亡，你复活并摸等同于轮数的牌。",
    ["sakamichi_jian_shu"] = "剑术",
    [":sakamichi_jian_shu"] = "当你受到【杀】造成的伤害后，若伤害来源不为你且装备有武器，你可以获得之。出牌阶段，若你装备武器，你对攻击范围内此阶段未对其使用过【杀】的角色使用【杀】无次数限制。你使用武器牌时视为对其他角色使用一张【杀】。",
}

-- 柴田 柚菜
YunaShibata = sgs.General(Sakamichi, "YunaShibata", "Nogizaka46", 3, false)
SKMC.YonKiSei.YunaShibata = true
SKMC.SeiMeiHanDan.YunaShibata = {
	name = {10, 5, 9, 11},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {14, "xiong"},
	ji_kaku = {20, "xiong"},
	soto_kaku = {21, "ji"},
	sou_kaku = {35, "ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "huo",
		ji_kaku = "shui",
		san_sai = "xiong",
	},
}

sakamichi_ti_cao = sgs.CreateTriggerSkill {
    name = "sakamichi_ti_cao",
    change_skill = true,
    frequency = sgs.Skill_Frequent,
    events = {sgs.SlashHit, sgs.PreCardUsed, sgs.SlashMissed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.from and effect.from:objectName() == player:objectName() and player:hasSkill(self:objectName())
                and room:getChangeSkillState(player, self:objectName()) == 1 and room:askForSkillInvoke(player, self:objectName(), data) then
                room:setPlayerMark(player, "ti_cao_" .. effect.to:objectName(), 1)
                SKMC.send_message(room, "#ti_cao_hit", player, effect.to, nil, effect.slash:toString())
                room:setChangeSkillState(player, self:objectName(), 2)
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                if player:hasSkill(self:objectName()) then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if player:getMark("ti_cao_" .. p:objectName()) ~= 0 then
                            room:setPlayerMark(player, "ti_cao_" .. p:objectName(), 0)
                            SKMC.send_message(room, "#ti_cao_append", player, p, nil, use.card:toString(), self:objectName())
                            use.to:append(p)
                        end
                    end
                end
                for _, p in sgs.qlist(use.to) do
                    local nullified_list = use.nullified_list
                    if player:getMark(p:objectName() .. "_ti_cao") ~= 0 then
                        room:setPlayerMark(player, p:objectName() .. "_ti_cao", 0)
                        table.insert(nullified_list, p:objectName())
                        use.nullified_list = nullified_list
                    end
                end
                data:setValue(use)
            end
        elseif event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if effect.from and effect.from:objectName() == player:objectName() and effect.to:hasSkill(self:objectName())
                and room:getChangeSkillState(effect.to, self:objectName()) == 2 and room:askForSkillInvoke(effect.to, self:objectName(), data) then
                room:setPlayerMark(player, effect.to:objectName() .. "_ti_cao", 1)
                SKMC.send_message(room, "#ti_cao_miss", effect.to, player, nil, effect.slash:toString())
                room:setChangeSkillState(effect.to, self:objectName(), 1)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YunaShibata:addSkill(sakamichi_ti_cao)

sakamichi_ni_ai_card = sgs.CreateSkillCard {
    name = "sakamichi_ni_aiCard",
    skill_name = "sakamichi_ni_ai",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            for _, skill in sgs.qlist(to_select:getVisibleSkillList()) do
                if skill:isChangeSkill() then
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        for _, skill in sgs.qlist(effect.to:getVisibleSkillList()) do
            if skill:isChangeSkill() then
                SKMC.send_message(room, "#ni_ai_change", effect.from, effect.to, nil, nil, self:getSkillName(), skill:objectName())
                room:setChangeSkillState(effect.to, skill:objectName(), 1)
            end
        end
    end,
}
sakamichi_ni_ai_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ni_ai",
    view_as = function(self, card)
        return sakamichi_ni_ai_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_ni_aiCard")
    end,
}
sakamichi_ni_ai = sgs.CreateTriggerSkill {
    name = "sakamichi_ni_ai",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ni_ai",
    view_as_skill = sakamichi_ni_ai_view_as,
    events = {sgs.EventPhaseProceeding, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and player:getMark("@ni_ai") ~= 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@ni_ai_invoke:::" .. self:objectName(), true, true)
                if target then
                    room:removePlayerMark(player, "@ni_ai")
                    if not target:faceUp() then
                        target:turnOver()
                    end
                    room:setPlayerChained(target, false)
                    if target:getHp() ~= player:getHp() then
                        if target:getMaxHp() < player:getHp() then
                            room:setPlayerProperty(target, "maxhp", sgs.QVariant(player:getHp()))
                        end
                        room:setPlayerProperty(target, "hp", sgs.QVariant(player:getHp()))
                    end
                    if target:getHandcardNum() ~= player:getHandcardNum() then
                        if target:getHandcardNum() < player:getHandcardNum() then
                            target:drawCards(player:getHandcardNum() - target:getHandcardNum())
                        else
                            local n = target:getHandcardNum() - player:getHandcardNum()
                            room:askForDiscard(target, self:objectName(), n, n, false, false, "@ni_ai:::" .. n, ".", self:objectName())
                        end
                    end
                    room:setPlayerMark(target, player:objectName() .. "_ni_ai_" .. target:objectName(), 1)
                end
            end
            if player:getPhase() == sgs.Player_Start then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark(player:objectName() .. "_ni_ai_" .. p:objectName()) ~= 0 then
                        room:setPlayerMark(p, player:objectName() .. "_ni_ai_" .. p:objectName(), 0)
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() == player:objectName() then
                local can_trigger = false
                for _, mark in sgs.list(damage.to:getMarkNames()) do
                    if string.find(mark, "_ni_ai_") and damage.to:getMark(mark) ~= 0 then
                        if not string.find(mark, player:objectName()) then
                            can_trigger = true
                        end
                    end
                end
                if can_trigger then
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YunaShibata:addSkill(sakamichi_ni_ai)

sakamichi_yao_nv = sgs.CreateTriggerSkill {
    name = "sakamichi_yao_nv",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:setPlayerFlag(p, "yao_nv")
            end
        elseif change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasFlag("yao_nv") then
                    room:setPlayerFlag(p, "-yao_nv")
                end
            end
        end
        return false
    end,
}
sakamichi_yao_nv_invalidity = sgs.CreateInvaliditySkill {
    name = "#sakamichi_yao_nv_invalidity",
    frequency = sgs.Skill_Compulsory,
    skill_valid = function(self, player, skill)
        if player:hasFlag("yao_nv") and player:getKingdom() == "Nogizaka46" and SKMC.is_ki_be(player, 4) then
            return false
        else
            return true
        end
    end,
}
YunaShibata:addSkill(sakamichi_yao_nv)
if not sgs.Sanguosha:getSkill("#sakamichi_yao_nv_invalidity") then SKMC.SkillList:append(sakamichi_yao_nv_invalidity) end

sgs.LoadTranslationTable {
    ["YunaShibata"] = "柴田 柚菜",
    ["&YunaShibata"] = "柴田 柚菜",
    ["#YunaShibata"] = "笑顏扶持",
    ["~YunaShibata"] = "ブ～ンブ～ン、柚菜のもとに着陸してね",
    ["designer:YunaShibata"] = "Cassimolar",
    ["cv:YunaShibata"] = "柴田 柚菜",
    ["illustrator:YunaShibata"] = "Cassimolar",
    ["sakamichi_ti_cao"] = "体操",
    [":sakamichi_ti_cao"] = "转换技，①你使用【杀】命中目标后，你使用的下一张【杀】将添加其为额外目标；②你闪避其他角色使用的【杀】后，其对你使用的下一张【杀】对你无效。",
    ["#ti_cao_hit"] = "%from 使用的%card命中%to，%from使用的下一张【杀】将添加%to为额外目标",
    ["#ti_cao_append"] = "%from 发动【%arg】将%to 添加为%card的额外目标",
    ["#ti_cao_miss"] = "%from 闪避%to 使用的%card，%to 对%from 使用的下一张【杀】对%from 无效",
    ["sakamichi_ni_ai"] = "溺爱",
    [":sakamichi_ni_ai"] = "限定技，结束阶段，你可以令一名其他角色武将牌复原然后令其体力值和手牌数与你相同，若如此做，直到你下个准备阶段，其他角色对其造成伤害+1。出牌阶段限一次，你可以将一名角色的转换技重置为①。",
    ["@ni_ai"] = "溺爱",
    ["@ni_ai_invoke"] = "你可以选择一名其他角色发动【%arg】",
    ["#ni_ai_change"] = "%from 发动【%arg】将%to 的【%arg2】重置为状态①",
    ["sakamichi_yao_nv"] = "妖女",
    [":sakamichi_yao_nv"] = "锁定技，你的回合内，其他乃木坂46势力的四期角色的技能均失效。",
}

-- 清宮 レイ
ReiSeimiya = sgs.General(Sakamichi, "ReiSeimiya", "Nogizaka46", 4, false)
SKMC.YonKiSei.ReiSeimiya = true
SKMC.SeiMeiHanDan.ReiSeimiya = {
	name = {11, 10, 1, 2},
	ten_kaku = {21, "ji"},
	jin_kaku = {11, "ji"},
	ji_kaku = {3, "ji"},
	soto_kaku = {13, "da_ji"},
	sou_kaku = {24, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "mu",
		jin_kaku = "mu",
		ji_kaku = "huo",
		san_sai = "da_ji",
	},
}

sakamichi_huo_li = sgs.CreateTriggerSkill {
    name = "sakamichi_huo_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local n = SKMC.number_correction(player, 1)
        if event == sgs.DamageCaused and player:getPhase() ~= sgs.Player_NotActive then
            if not player:hasFlag(self:objectName() .. "_damage") then
                room:setPlayerFlag(player, self:objectName() .. "_damage")
                SKMC.send_message(room, "#huo_li_damage", player, damage.to, nil, nil, self:objectName(), damage.damage, n, damage.damage + n)
                damage.damage = damage.damage + n
                data:setValue(damage)
            end
        elseif event == sgs.DamageInflicted and player:getPhase() == sgs.Player_NotActive then
            if not player:hasFlag(self:objectName() .. "_damaged") then
                room:setPlayerFlag(player, self:objectName() .. "_damaged")
                SKMC.send_message(room, "#huo_li_damaged", player, damage.from, nil, nil, self:objectName(), damage.damage, n, damage.damage - n)
                damage.damage = damage.damage - n
                data:setValue(damage)
                if damage.damage < 1 then
                    SKMC.send_message(room, "#huo_li_damaged_cancel", player, damage.from, nil, nil, self:objectName())
                    return true
                end
            end
        end
        return false
    end,
}
ReiSeimiya:addSkill(sakamichi_huo_li)

sakamichi_tiao_chuang = sgs.CreateTriggerSkill {
    name = "sakamichi_tiao_chuang",
    events = {sgs.DamageInflicted, sgs.DamageComplete},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.DamageInflicted then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local can_trigger = true
                if player:objectName() ~= p:objectName() then
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, self:objectName()) and p:getMark(mark) ~= 0 then
                            can_trigger = false
                        end
                    end
                    if can_trigger and room:askForSkillInvoke(p, self:objectName(), data) then
                        room:setPlayerFlag(p, self:objectName())
                        room:setPlayerMark(p, self:objectName() .. player:objectName() .. "_lun_clear", damage.damage)
                        damage.to = p
                        damage.transfer = true
                        room:damage(damage)
                        return true
                    end
                end
            end
        elseif event == sgs.DamageComplete then
            if player:hasFlag(self:objectName()) then
                room:drawCards(player, player:getLostHp() , self:objectName())
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    local n = player:getMark(self:objectName() .. p:objectName() .. "_lun_clear")
                    if n ~= 0 then
                        local card
                        if player:getHandcardNum() + player:getEquips():length() <= n then
                            card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                            card:deleteLater()
                            card:addSubcards(player:getCards("he"))
                        else
                            card = room:askForExchange(player, self:objectName(), n, n, true, "@tiao_chuang:" .. p:objectName() .. "::" .. n)
                        end
                        room:obtainCard(p, card, false)
                    end
                end
                room:setPlayerFlag(player, "-" .. self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ReiSeimiya:addSkill(sakamichi_tiao_chuang)

sgs.LoadTranslationTable {
    ["ReiSeimiya"] = "清宮 レイ",
    ["&ReiSeimiya"] = "清宮 レイ",
    ["#ReiSeimiya"] = "小太阳",
    ["~ReiSeimiya"] = "私の人生SSRだ！",
    ["designer:ReiSeimiya"] = "Cassimolar",
    ["cv:ReiSeimiya"] = "清宮 レイ",
    ["illustrator:ReiSeimiya"] = "Cassimolar",
    ["sakamichi_huo_li"] = "活力",
    [":sakamichi_huo_li"] = "锁定技，你于回合内造成的第一次伤害+1。你于回合外受到的第一次伤害-1。",
    ["#huo_li_damage"] = "%from 的【%arg】被触发，%from 对 %to 造成的此次伤害由%arg2点增加%arg3点，此次伤害为%arg4点。",
    ["#huo_li_damaged"] = "%from 的【%arg】被触发，%to 对 %from 造成的此次伤害由%arg2点减少%arg3点，此次伤害为%arg4点。",
    ["#huo_li_damaged_cancel"] = "%from 的【%arg】被触发，防止%to 对 %from 造成的此次伤害。",
    ["sakamichi_tiao_chuang"] = "跳床",
    [":sakamichi_tiao_chuang"] = "每轮限一次，一名其他角色受到伤害时，你可以代替其承受此次伤害，然后你摸X张牌并交给其等同此次伤害量的牌（X为你已损失的体力值）。",
    ["@tiao_chuang"] = "你需要交给%src %arg张牌。",
}

-- 賀喜 遥香
HarukaKaki = sgs.General(Sakamichi, "HarukaKaki$", "Nogizaka46", 4, false)
SKMC.YonKiSei.HarukaKaki = true
SKMC.SeiMeiHanDan.HarukaKaki = {
    name = {12, 12, 12, 9},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {21, "ji"},
    sou_kaku = {45, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_chi_ze = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_ze$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@chi_ze",
    events = {sgs.EventPhaseProceeding, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and player:getMark("@chi_ze") ~= 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@chi_ze_invoke:::" .. self:objectName(), true)
                if target then
                    room:removePlayerMark(player, "@chi_ze", 1)
                    target:turnOver()
                    room:addPlayerMark(target, "&" .. self:objectName() .. "+ +_damage_start_start_clear", SKMC.number_correction(player, 1))
                end
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getMark("&" .. self:objectName() .. "+ +_damage_start_start_clear") ~= 0 and damage.from and damage.from:getKingdom() == "Nogizaka46" then
                damage.damage = damage.damage + player:getMark("&" .. self:objectName() .. "+ +_damage_start_start_clear")
                data:setValue(damage)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HarukaKaki:addSkill(sakamichi_chi_ze)

sakamichi_bai_ya = sgs.CreateFilterSkill {
    name = "sakamichi_bai_ya",
    view_filter = function(self, to_select)
        return to_select:isBlack()
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName(self:objectName())
        new_card:setSuit(sgs.Card_NoSuit)
        new_card:setModified(true)
        return new_card
    end,
}
sakamichi_bai_ya_trigger = sgs.CreateTriggerSkill {
    name = "#sakamichi_bai_ya_trigger",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isBlack() and damage.to:hasSkill("sakamichi_bai_ya") then
            SKMC.send_message(room, "#bai_ya_damage", nil, damage.to, nil, damage.card:toString(), "sakamichi_bai_ya", SKMC.number_correction(damage.to, 1))
            damage.damage = damage.damage - SKMC.number_correction(damage.to, 1)
            data:setValue(damage)
            if damage.damage < 1 then
                SKMC.send_message(room, "#bai_ya_damage_nil", nil, damage.to, nil, damage.card:toString(), "sakamichi_bai_ya")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HarukaKaki:addSkill(sakamichi_bai_ya)
if not sgs.Sanguosha:getSkill("#sakamichi_bai_ya_trigger") then SKMC.SkillList:append(sakamichi_bai_ya_trigger) end

sakamichi_zha_nan = sgs.CreateTriggerSkill {
    name = "sakamichi_zha_nan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpRecover},
    on_trigger= function(self, event, player, data, room)
        local recover = data:toRecover()
        local target_list = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isWounded() then
                target_list:append(p)
            end
        end
        if not target_list:isEmpty() then
            local target = room:askForPlayerChosen(player, target_list, self:objectName(), "@zha_nan_invoke:::" .. recover.recover, true)
            if target then
                room:recover(target, sgs.RecoverStruct(player, recover.card, recover.recover))
            end
        end
        return false
    end,
}
HarukaKaki:addSkill(sakamichi_zha_nan)

sgs.LoadTranslationTable {
    ["HarukaKaki"] = "賀喜 遥香",
    ["&HarukaKaki"] = "賀喜 遥香",
    ["#HarukaKaki"] = "喜子哥",
    ["~HarukaKaki"] = "痛い痛い痛い痛い",
    ["designer:HarukaKaki"] = "Cassimolar",
    ["cv:HarukaKaki"] = "賀喜 遥香",
    ["illustrator:HarukaKaki"] = "Cassimolar",
    ["sakamichi_chi_ze"] = "斥责",
    [":sakamichi_chi_ze"] = "主公技，限定技，结束阶段，你可以选择一名其他角色，令其翻面且直到其下个回合开始，受到来自乃木坂46势力角色造成的伤害+1。",
    ["@chi_ze"] = "斥责",
    ["@chi_ze_invoke"] = "你可以选择一名其他角色发动【%arg】",
    ["_damage_start_start_clear"] = "“乃木坂46”伤害+1",
    ["sakamichi_bai_ya"] = "白牙",
    [":sakamichi_bai_ya"] = "锁定技，你的黑色牌均视为无色。黑色牌对你造成的伤害-1。",
    ["#bai_ya_damage"] = "%to的【%arg】被触发，%card对%to造成的伤害-%arg2",
    ["#bai_ya_damage_nil"] = "%to的【%arg】被触发,防止%card对%to造成的伤害",
    ["sakamichi_zha_nan"] = "渣男",
    [":sakamichi_zha_nan"] = "当你回复体力后，你可以令一名其他角色回复等量的体力。",
    ["@zha_nan_invoke"] = "你可以令一名其他角色回复%arg点体力",
}

-- 弓木 奈於
NaoYumiki = sgs.General(Sakamichi, "NaoYumiki", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.NaoYumiki = true
SKMC.SeiMeiHanDan.NaoYumiki = {
	name = {3, 4, 8, 8},
	ten_kaku = {7, "ji"},
	jin_kaku = {12, "xiong"},
	ji_kaku = {16, "da_ji"},
	soto_kaku = {11, "ji"},
	sou_kaku = {23, "ji"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "mu",
		ji_kaku = "tu",
		san_sai = "ji",
	},
}

sakamichi_tong_yao = sgs.CreateTriggerSkill {
    name = "sakamichi_tong_yao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@tong_yao",
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:objectName() ~= p:objectName() and p:getMark("@tong_yao") ~= 0 and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:removePlayerMark(p, "@tong_yao")
                    local x = p:getMark("Global_TurnCount") * room:alivePlayerCount()
                    local ids = room:getNCards(x, false)
                    local card_to_gotback = {}
                    local move = sgs.CardsMoveStruct()
                    move.card_ids = ids
                    move.to = nil
                    move.to_place = sgs.Player_PlaceTable
                    move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, p:objectName(), self:objectName(), nil)
                    room:moveCardsAtomic(move, true)
                    room:fillAG(ids)
                    for _, id in sgs.qlist(ids) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:isDamageCard() and player:isAlive() then
                            room:takeAG(p, id, false)
                            room:useCard(sgs.CardUseStruct(card, p, player, false))
                        else
                            table.insert(card_to_gotback, id)
                        end
                    end
                    room:clearAG()
                    if #card_to_gotback > 0 then
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                        dummy:deleteLater()
                        for _, id in ipairs(card_to_gotback) do
                            dummy:addSubcard(id)
                        end
                        if player:isAlive() then
                            room:obtainCard(player, dummy)
                        else
                            room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, self:objectName(), nil), nil)
                        end
                    end

                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NaoYumiki:addSkill(sakamichi_tong_yao)

sakamichi_gong_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_gong_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardFinished, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            if player:getPhase() == sgs.Player_Play then
                local use = data:toCardUse()
                if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
                    local ids = sgs.IntList()
                    if use.card:isVirtualCard() then
                        ids = use.card:getSubcards()
                    else
                        ids:append(use.card:getEffectiveId())
                    end
                    if ids:length() > 0 then
                        local all_place_discard = true
                        for _, id in sgs.qlist(ids) do
                            if room:getCardPlace(id) ~= sgs.Player_Discard then
                                all_place_discard = false
                                break
                            end
                        end
                        if all_place_discard then
                            if player:hasSkill(self:objectName()) then
                                local not_has = true
                                for _,id in  sgs.qlist(player:getPile("gong_yan")) do
                                    if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(use.card) then
                                        not_has = false
                                        break
                                    end
                                end
                                if not_has then
                                    player:addToPile("gong_yan", use.card)
                                else
                                    player:endPlayPhase()
                                end
                            end
                        end
                    end
                end
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() then
                        local has = false
                        for _, id in sgs.qlist(p:getPile("gong_yan")) do
                            if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(use.card) then
                                has = true
                                break
                            end
                        end
                        if has then
                            room:drawCards(p, 1, self:objectName())
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NaoYumiki:addSkill(sakamichi_gong_yan)

sakamichi_mu_yu = sgs.CreateViewAsSkill {
    name = "sakamichi_mu_yu" ,
    n = 2,
    guhuo_type = "lsr",
    view_filter = function(self, selected, to_select)
        return #selected < 2 and not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local cd = sgs.Self:getTag(self:objectName()):toCard()
            cd:addSubcard(cards[1])
            cd:addSubcard(cards[2])
            cd:setSkillName(self:objectName())
            return cd
        end
        return false
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasFlag("mu_yu_used")
    end,
}
sakamichi_mu_yu_used = sgs.CreateTriggerSkill {
    name = "#sakamichi_mu_yu_used",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:getSkillName() == "sakamichi_mu_yu" then
            room:setPlayerFlag("mu_yu_used")
        end
        return false
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_mu_yu", "#sakamichi_mu_yu_used")
NaoYumiki:addSkill(sakamichi_mu_yu)
NaoYumiki:addSkill(sakamichi_mu_yu_used)

sakamichi_da_zhi = sgs.CreateTriggerSkill {
    name = "sakamichi_da_zhi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime, sgs.TrickCardCanceling},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) and move.to_place and move.to_place == sgs.Player_PlaceSpecial and
                move.to_pile_name and move.to_pile_name == "gong_yan" then
                local legal_card_name = {}
                for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isKindOf("BasicCard") or card:isNDTrick() then
                        if not table.contains(legal_card_name, SKMC.true_name(card)) then
                            table.insert(legal_card_name, SKMC.true_name(card))
                        end
                    end
                end
                for _, id in sgs.qlist(player:getPile("gong_yan")) do
                    table.removeOne(legal_card_name, SKMC.true_name(sgs.Sanguosha:getCard(id)))
                end
                if #legal_card_name == 0 then
                    room:gameOver(player:objectName())
                else
                    room:setPlayerMark(player, "&" .. self:objectName(), #legal_card_name)
                end
            end
        else
            local effect = data:toCardEffect()
            if effect.from and effect.from:hasSkill(self:objectName()) and effect.card:isNDTrick() then
                return true
            end
        end
        return false
    end,
    can_trigger= function(self, target)
        return target
    end,
}
NaoYumiki:addSkill(sakamichi_da_zhi)

sgs.LoadTranslationTable {
    ["NaoYumiki"] = "弓木 奈於",
    ["&NaoYumiki"] = "弓木 奈於",
    ["#NaoYumiki"] = "迷言制造机",
    ["~NaoYumiki"] = "お醤油って知ってますか？",
    ["designer:NaoYumiki"] = "Cassimolar",
    ["cv:NaoYumiki"] = "弓木 奈於",
    ["illustrator:NaoYumiki"] = "Cassimolar",
    ["sakamichi_tong_yao"] = "童谣",
    [":sakamichi_tong_yao"] = "限定技，其他角色结束阶段，你可以翻开牌堆顶X张牌，对其使用其中所有伤害牌，然后其获得剩余的牌（X为当前轮次数*场上角色数）。",
    ["@tong_yao"] = "童谣",
    ["sakamichi_gong_yan"] = "弓言",
    [":sakamichi_gong_yan"] = "锁定技，出牌阶段，你使用的基本牌和通常锦囊牌结算完成时，若你「弓言」中：未包含该牌名，将此牌置于你武将牌上称为「弓言」；已包含该牌名的牌，结束出牌阶段。其他角色出牌阶段使用你「弓言」中包含的牌名时，你摸一张牌。",
    ["gong_yan"] = "弓言",
    ["sakamichi_mu_yu"] = "木语",
    [":sakamichi_mu_yu"] = "出牌阶段限一次，你可将两张手牌当任意基本牌或通常锦囊牌使用。",
    ["sakamichi_da_zhi"] = "大智",
    [":sakamichi_da_zhi"] = "锁定技，当【弓言】记录所有可记录牌名时，你胜利。你的通常锦囊牌无法被【无懈可击】响应。",
}

-- 早川 聖来
SeiraHayakawa = sgs.General(Sakamichi, "SeiraHayakawa", "Nogizaka46", 4, false)
SKMC.YonKiSei.SeiraHayakawa = true
SKMC.SeiMeiHanDan.SeiraHayakawa = {
	name = {6, 3, 13, 7},
	ten_kaku = {9, "xiong"},
	jin_kaku = {16, "da_ji"},
	ji_kaku = {20, "xiong"},
	soto_kaku = {13, "da_ji"},
	sou_kaku = {29, "te_shu_ge"},
	GoGyouSanSai = {
		ten_kaku = "shui",
		jin_kaku = "tu",
		ji_kaku = "shui",
		san_sai = "xiong",
	},
}

sakamichi_sheng_tui = sgs.CreateFilterSkill {
    name = "sakamichi_sheng_tui",
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, to_select)
        return to_select:isKindOf("EquipCard") and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
    end,
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(cd)
        return new
    end,
}
sakamichi_sheng_tui_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_sheng_tui_distance",
    correct_func = function(self, from, to)
        if from:hasSkill("sakamichi_sheng_tui") then
            return -from:getLostHp()
        end
    end,
}
SeiraHayakawa:addSkill(sakamichi_sheng_tui)
if not sgs.Sanguosha:getSkill("#sakamichi_sheng_tui_distance") then SKMC.SkillList:append(sakamichi_sheng_tui_distance) end
sakamichi_ye_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_ye_xin",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardFinished, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getKingdom() == player:getKingdom() and p:objectName() ~= player:objectName() then
                    room:setPlayerFlag(p, "ye_xin_slash")
                    local target = sgs.QVariant()
                    target:setValue(player)
                    room:setTag("ye_xin", target)
                    if room:askForUseCard(p, "slash", "@askforslash") then
                        room:addSlashCishu(player, -SKMC.number_correction(p, 1))
                        SKMC.send_message(room, "#ye_xin_slash", p, player, nil, nil, self:objectName(), SKMC.number_correction(p, 1))
                    end
                    if p:hasFlag("ye_xin_slash") then
                        room:setPlayerFlag(p, "-ye_xin_slash")
                    end
                    room:removeTag("ye_xin")
                end
            end
        elseif event == sgs.CardUsed then
            if player:hasFlag("ye_xin_slash") then
                room:setCardFlag(data:toCardUse().card, "ye_xin_slash")
                room:setPlayerFlag(player, "-ye_xin_slash")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("ye_xin_slash") then
                room:setCardFlag(use.card, "-ye_xin_slash")
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("ye_xin_slash") then
                local target = room:getTag("ye_xin"):toPlayer()
                local num
                if damage.from then
                    num = -SKMC.number_correction(damage.from, 1)
                else
                    num = -1
                end
                room:addMaxCards(target, num)
                SKMC.send_message(room, "#ye_xin_max", player, target, nil, damage.card:toString(), self:objectName(), num)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}

SeiraHayakawa:addSkill(sakamichi_ye_xin)

sgs.LoadTranslationTable {
    ["SeiraHayakawa"] = "早川 聖来",
    ["&SeiraHayakawa"] = "早川 聖来",
    ["#SeiraHayakawa"] = "憨憨",
    ["~SeiraHayakawa"] = "聖来はお昼寝がした～い",
    ["designer:SeiraHayakawa"] = "Cassimolar",
    ["cv:SeiraHayakawa"] = "早川 聖来",
    ["illustrator:SeiraHayakawa"] = "Cassimolar",
    ["sakamichi_sheng_tui"] = "圣腿",
    [":sakamichi_sheng_tui"] = "锁定技，你手牌中的装备牌均视为【杀】；你计算与其他角色的距离-X（X为你已损失的体力值）。",
    ["sakamichi_ye_xin"] = "野心",
    [":sakamichi_ye_xin"] = "其他与你势力相同的角色出牌阶段开始时，你可使用一张【杀】，若如此做，本回合其使用【杀】的限制次数-1，若此【杀】造成伤害，本回合其手牌上限-1。",
    ["#ye_xin_slash"] = "%from 发动【%arg】使用了一张【杀】，本回合内%to 使用【杀】的限制次数-%arg2",
    ["#ye_xin_max"] = "%from 发动【%arg】使用了%card，%card造成了伤害，本回合内%to 手牌上限-%arg2",
}

-- 筒井 あやめ
AyameTsutsui = sgs.General(Sakamichi, "AyameTsutsui", "Nogizaka46", 3, false)
SKMC.YonKiSei.AyameTsutsui = true
SKMC.SeiMeiHanDan.AyameTsutsui = {
	name = {12, 4, 3, 3, 2},
	ten_kaku = {16, "da_ji"},
	jin_kaku = {7, "ji"},
	ji_kaku = {8, "ji"},
	soto_kaku = {17, "ji"},
	sou_kaku = {24, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "jin",
		ji_kaku = "jin",
		san_sai = "ji",
	},
}

sakamichi_la_meiCard = sgs.CreateSkillCard {
    name = "sakamichi_la_meiCard",
    skill_name = "sakamici_la_mei",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if sgs.Self:hasFlag("la_mei_recover") then
            return #targets < sgs.Self:getMark("la_mei_num") and to_select:isWounded()
        else
            return #targets < sgs.Self:getMark("la_mei_num")
        end
    end,
    on_effect = function(self, effect)
        if effect.from:hasFlag("la_mei_recover") then
            effect.from:getRoom():recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
        end
        if effect.from:hasFlag("la_mei_draw") then
            effect.from:getRoom():drawCards(effect.to, 1, self:getSkillName())
        end
    end
}
sakamichi_la_mei_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_la_mei",
    view_as = function(self, cards)
        return sakamichi_la_meiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@sakamichi_la_mei"
    end,
}
sakamichi_la_mei = sgs.CreateTriggerSkill {
    name = "sakamichi_la_mei",
    view_as_skill = sakamichi_la_mei_view_as,
    events = {sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        room:setPlayerMark(player, "la_mei_num", damage.damage)
        if event == sgs.Damage then
            local can_trigger = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isWounded() then
                    can_trigger = true
                    break
                end
            end
            if can_trigger then
                room:setPlayerFlag(player, "la_mei_recover")
                room:askForUseCard(player, "@@sakamichi_la_mei", "@la_mei_recover:::" .. damage.damage)
                room:setPlayerFlag(player, "-la_mei_recover")
            end
        elseif event == sgs.Damaged then
            room:setPlayerFlag(player, "la_mei_draw")
            room:askForUseCard(player, "@@sakamichi_la_mei", "@la_mei_draw:::" .. damage.damage)
            room:setPlayerFlag(player, "-la_mei_draw")
        end
        room:setPlayerMark(player, "la_mei_num", 0)
        return false
    end,
}
AyameTsutsui:addSkill(sakamichi_la_mei)

sakamichi_chen_wen = sgs.CreateTriggerSkill {
    name = "sakamichi_chen_wen",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if player:hasSkill(self:objectName()) and (use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack")) then
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if player:hasSkill(self:objectName()) then
                    room:setPlayerFlag(player, "chen_wen")
                end
                local last_turn_handcards_num = player:getTag(self:objectName()):toInt()
                if last_turn_handcards_num == player:getHandcardNum() then
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        room:drawCards(p, 1, self:objectName())
                        room:drawCards(player, 1, self:objectName())
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish then
                player:setTag(self:objectName(), sgs.QVariant(player:getHandcardNum()))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_chen_wen_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_chen_wen_card_limit",
    frequency = sgs.Skill_Compulsory,
    limit_list = function(self, player)
        local can_trigger = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasSkill("sakamichi_chen_wen") and p:hasFlag("chen_wen") then
                can_trigger = true
                break
            end
        end
        if can_trigger then
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        local can_trigger = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasSkill("sakamichi_chen_wen") and p:hasFlag("chen_wen") then
                can_trigger = true
                break
            end
        end
        if can_trigger then
            return "Nullification"
        else
            return ""
        end
    end,
}
AyameTsutsui:addSkill(sakamichi_chen_wen)
if not sgs.Sanguosha:getSkill("#sakamichi_chen_wen_card_limit") then SKMC.SkillList:append(sakamichi_chen_wen_card_limit) end

sgs.LoadTranslationTable {
    ["AyameTsutsui"] = "筒井 あやめ",
    ["&AyameTsutsui"] = "筒井 あやめ",
    ["#AyameTsutsui"] = "辣咩",
    ["~AyameTsutsui"] = "バーカ！",
    ["designer:AyameTsutsui"] = "Cassimolar",
    ["cv:AyameTsutsui"] = "筒井 あやめ",
    ["illustrator:AyameTsutsui"] = "Cassimolar",
    ["sakamichi_la_mei"] = "辣妹",
    [":sakamichi_la_mei"] = "当你造成伤害后，你可以令至多X名角色回复1点体力；当你受到伤害后，你可以令至多X名角色摸一张牌（X为伤害量）。。",
    ["@la_mei_recover"] = "你可以选择至多%arg名角色，令他们各回复1点体力",
    ["@la_mei_draw"] = "你可以选择至多%arg名角色，令他们各摸一张牌",
    ["sakamichi_chen_wen"] = "沉稳",
    [":sakamichi_chen_wen"] = "锁定技，【南蛮入侵】、【万箭齐发】对你无效。你的回合内其他角色无法使用【无懈可击】。一名角色准备阶段，若其手牌数与其上回合结束阶段相同，你与其各摸一张牌。",
}

-- 遠藤 さくら
SakuraEndo = sgs.General(Sakamichi, "SakuraEndo$", "Nogizaka46", 3, false)
SKMC.YonKiSei.SakuraEndo = true
SKMC.SeiMeiHanDan.SakuraEndo = {
    name = {13, 18, 3, 1, 3},
    ten_kaku = {31, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {7, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_ye_ming_card = sgs.CreateSkillCard {
    name = "sakamichi_ye_mingCard",
    skill_name = "sakamichi_ye_ming",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName() and to_select:getKingdom() == "Nogizaka46"
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local num = SKMC.number_correction(effect.from, 1)
        room:addPlayerMark(effect.to, "ye_ming_draw_end_clear", num)
        room:addMaxCards(effect.from, -num)
    end
}
sakamichi_ye_ming_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ye_ming",
    view_as = function()
        return sakamichi_ye_ming_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_ye_mingCard")
    end,
}
sakamichi_ye_ming = sgs.CreateTriggerSkill {
    name = "sakamichi_ye_ming$",
    view_as_skill = sakamichi_ye_ming_view_as,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        data:setValue(n + player:getMark("ye_ming_draw_end_clear"))
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_ye_ming_max_cards = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_ye_ming_max_cards",
    extra_func = function(self, target)
        if target:hasSkill("sakamichi_ye_ming") then
            local extra = 1
            for _, p in sgs.qlist(target:getSiblings()) do
                if p:isAlive() and p:getKingdom() == "Nogizaka46" then
                    extra = extra + 1
                end
            end
            return extra
        end
        return 0
    end,
}
SakuraEndo:addSkill(sakamichi_ye_ming)
if not sgs.Sanguosha:getSkill("#sakamichi_ye_ming_max_cards") then SKMC.SkillList:append(sakamichi_ye_ming_max_cards) end

sakamichi_luo_lei = sgs.CreateTriggerSkill {
    name = "sakamichi_luo_lei",
    frequency = sgs.Skill_Limited,
    limit_mark = "@luo_lei",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start and player:getMark("@luo_lei") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            room:removePlayerMark(player, "@luo_lei", 1)
            local lord_list = {}
            local lord_skills = {}
            for _, lord in ipairs(sgs.Sanguosha:getLords()) do
                if sgs.Sanguosha:getGeneral(lord):getKingdom() == "Nogizaka46" then
                    table.insert(lord_list, lord)
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                table.removeOne(lord_list, p:getGeneralName())
                table.removeOne(lord_list, p:getGeneral2Name())
            end
            if #lord_list ~= 0 then
                for _, lord in ipairs(lord_list) do
                    for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(lord):getSkillList()) do
                        if skill:isLordSkill() and not player:hasSkill(skill:objectName()) and not table.contains(lord_skills, skill:objectName()) then
                            table.insert(lord_skills, skill:objectName())
                        end
                    end
                end
                if #lord_skills ~= 0 then
                    local skill = sgs.Sanguosha:getSkill(room:askForChoice(player, self:objectName(), table.concat(lord_skills, "+")))
                    room:handleAcquireDetachSkills(player, skill:objectName())
                end
            end
        end
        return false
    end,
}
SakuraEndo:addSkill(sakamichi_luo_lei)

sakamichi_chuan_cheng_card = sgs.CreateSkillCard {
    name = "sakamichi_chuan_chengCard",
    skill_name = "sakamichi_chuan_cheng",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getKingdom() ~= "Nogizaka46"
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choices = {}
        if not effect.to:isKongcheng() then
            table.insert(choices, "chuan_cheng_1=" .. effect.to:objectName())
        end
        table.insert(choices, "chuan_cheng_2=" .. effect.to:objectName() .. "=" .. SKMC.number_correction(effect.from, 1))
        local choice = room:askForChoice(effect.from, self:getSkillName(), table.concat(choices, "+"))
        if choice == "chuan_cheng_1=" .. effect.to:objectName() then
            room:showAllCards(effect.to, effect.from)
        else
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to, SKMC.number_correction(effect.from, 1)))
        end
    end
}
sakamichi_chuan_cheng = sgs.CreateTriggerSkill {
    name = "sakamichi_chuan_cheng",
    shiming_skill = true,
    events = {sgs.EventPhaseProceeding, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:hasSkill(self:objectName()) and player:getMark(self:objectName()) == 0 and player:getPhase() == sgs.Player_Finish then
                local target_list = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getKingdom() ~= "Nogizaka46" then
                        target_list:append(p)
                    end
                end
                if target_list:length() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                    local target = room:askForPlayerChosen(player, target_list, self:objectName())
                    local choices = {}
                    if not target:isKongcheng() then
                        table.insert(choices, "chuan_cheng_1=" .. target:objectName())
                    end
                    table.insert(choices, "chuan_cheng_2=" .. target:objectName() .. "=" .. SKMC.number_correction(player, 1))
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                    if choice == "chuan_cheng_1=" .. target:objectName() then
                        room:showAllCards(target, player)
                    else
                        room:damage(sgs.DamageStruct(self:objectName(), player, target, SKMC.number_correction(player, 1)))
                    end
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who and dying.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) and player:getMark(self:objectName()) == 0 and dying.damage and
                dying.damage.from and dying.damage.from and dying.damage.from:objectName() ~= player:objectName() and dying.damage.from:getKingdom() == "Nogizaka46" then
                local detachList = {}
                for _, skill in sgs.qlist(player:getVisibleSkillList()) do
                    if skill:isLordSkill() then
                        table.insert(detachList, "-" .. skill:objectName())
                    end
                end
                room:sendShimingLog(player, self, false)
                room:handleAcquireDetachSkills(player, table.concat(detachList, "|"))
            end
            if dying.who and dying.who:objectName() == player:objectName() and player:getKingdom() == "Nogizaka46" then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark(self:objectName()) == 0 and player:objectName() ~= p:objectName() then
                        room:sendShimingLog(p, self)
                        for i = 1, 2, 1 do
                            local lord_list = {}
                            local lord_skills = {}
                            for _, lord in ipairs(sgs.Sanguosha:getLords()) do
                                if sgs.Sanguosha:getGeneral(lord):getKingdom() == "Nogizaka46" then
                                    table.insert(lord_list, lord)
                                end
                            end
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                table.removeOne(lord_list, p:getGeneralName())
                                table.removeOne(lord_list, p:getGeneral2Name())
                            end
                            if #lord_list ~= 0 then
                                for _, lord in ipairs(lord_list) do
                                    for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(lord):getSkillList()) do
                                        if skill:isLordSkill() and not p:hasSkill(skill:objectName()) and not table.contains(lord_skills, skill:objectName()) then
                                            table.insert(lord_skills, skill:objectName())
                                        end
                                    end
                                end
                                if #lord_skills ~= 0 then
                                    local skill = sgs.Sanguosha:getSkill(room:askForChoice(p, self:objectName(), table.concat(lord_skills, "+")))
                                    room:handleAcquireDetachSkills(p, skill:objectName())
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SakuraEndo:addSkill(sakamichi_chuan_cheng)

sgs.LoadTranslationTable {
    ["SakuraEndo"] = "遠藤 さくら",
    ["&SakuraEndo"] = "遠藤 さくら",
    ["#SakuraEndo"] = "乃团之巅",
    ["~SakuraEndo"] = "もう恥ずかしがらないぞー",
    ["designer:SakuraEndo"] = "Cassimolar",
    ["cv:SakuraEndo"] = "遠藤 さくら",
    ["illustrator:SakuraEndo"] = "Cassimolar",
    ["sakamichi_ye_ming"] = "夜明",
    [":sakamichi_ye_ming"] = "主公技，你的手牌上限+X（X为场上乃木坂46势力角色数）。出牌阶段限一次，你可以令任意名其他乃木坂46势力角色下个摸牌阶段额定摸牌数+1，若如此做，本回合内你减少等量的手牌上限。",
    ["sakamichi_luo_lei"] = "落泪",
    [":sakamichi_luo_lei"] = "限定技，准备阶段，你可以选择并获得一个已死亡或未登场的乃木坂46势力主公的主公技（获得后不为主公也可发动）。",
    ["@luo_lei"] = "落泪",
    ["sakamichi_chuan_cheng"] = "传承",
    [":sakamichi_chuan_cheng"] = "使命技，结束阶段，你可以选择一名非乃木坂46势力角色，观看其手牌或对其造成1点伤害。成功：其他乃木坂46势力角色进入濒死时，你选择并获得两个已死亡或未登场的乃木坂46势力主公的主公技（获得后不为主公也可发动）。失败：其他乃木坂46势力角色令你进入濒死时，你失去所有主公技。",
    ["sakamichi_chuan_cheng:chuan_cheng_1"] = "观看%src的手牌",
    ["sakamichi_chuan_cheng:chuan_cheng_2"] = "对%src造成%arg点伤害",
}

-- 佐藤 璃果
RikaSato = sgs.General(Sakamichi, "RikaSato", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.RikaSato = true
SKMC.SeiMeiHanDan.RikaSato = {
	name = {7, 18, 15, 8},
	ten_kaku = {25, "ji"},
	jin_kaku = {33, "te_shu_ge"},
	ji_kaku = {23, "ji"},
	soto_kaku = {15, "da_ji"},
	sou_kaku = {48, "ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "huo",
		ji_kaku = "huo",
		san_sai = "ji",
	},
}

sakamichi_li_ke = sgs.CreateTriggerSkill {
    name = "sakamichi_li_ke",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:canDiscard(player, "hej") and room:askForSkillInvoke(p, self:objectName(),
                    sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. use.card:objectName())) then
                    local id = room:askForCardChosen(p, player, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
                    room:throwCard(id, player, p)
                    local no_offset_list = use.no_offset_list
                    for _, pl in sgs.qlist(use.to) do
                        table.insert(no_offset_list, pl:objectName())
                    end
                    use.no_offset_list = no_offset_list
                    data:setValue(use)
                    if p:objectName() == player:objectName() then
                        room:drawCards(p, 1, self:objectName())
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RikaSato:addSkill(sakamichi_li_ke)

sakamichi_bian_cheng = sgs.CreateTriggerSkill {
    name = "sakamichi_bian_cheng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardFinished, sgs.EventPhaseProceeding, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                if not player:hasFlag("bian_cheng_not_draw") then
                    if use.card:getNumber() > player:getMark("bian_cheng_num_finish_end_clear") then
                        room:setPlayerMark(player, "bian_cheng_num_finish_end_clear", use.card:getNumber())
                        room:addPlayerMark(player, "bian_cheng_draw_finish_end_clear")
                    else
                        room:setPlayerFlag(player, "bian_cheng_not_draw")
                    end
                end
                if not player:hasFlag("bian_cheng_extra_turn") then
                    if player:getMark("bian_cheng_suit_finish_end_clear") == 0 then
                        if use.card:getSuit() == sgs.Card_Spade then
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 1)
                        end
                    elseif player:getMark("bian_cheng_suit_finish_end_clear") == 1 then
                        if use.card:getSuit() == sgs.Card_Heart then
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 2)
                        else
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 0)
                        end
                    elseif player:getMark("bian_cheng_suit_finish_end_clear") == 2 then
                        if use.card:getSuit() == sgs.Card_Club then
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 3)
                        else
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 0)
                        end
                    elseif player:getMark("bian_cheng_suit_finish_end_clear") == 3 then
                        if use.card:getSuit() == sgs.Card_Diamond then
                            room:setPlayerFlag(player, "bian_cheng_extra_turn")
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Finish then
                if not player:hasFlag("bian_cheng_not_draw") and player:getMark("bian_cheng_draw_finish_end_clear") ~= 0 then
                    room:drawCards(player, player:getMark("bian_cheng_draw_finish_end_clear"), self:objectName())
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                if player:hasFlag("bian_cheng_extra_turn") then
                    room:setPlayerFlag(player, "-bian_cheng_extra_turn")
                    player:gainAnExtraTurn()
                end
            end
        end
        return false
    end,
}
RikaSato:addSkill(sakamichi_bian_cheng)

sakamichi_ming_chan = sgs.CreateTriggerSkill {
    name = "sakamichi_ming_chan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and
            ((player:getPhase() == sgs.Player_Play and player:getMark(self:objectName() .. "_play_end_clear") == 0) or
            ((player:getPhase() == sgs.Player_Discard and player:getMark(self:objectName() .. "_discard_end_clear") == 0))) and
            bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
            local suits = {}
            for _, id in sgs.qlist(move.card_ids) do
                if not suits[sgs.Sanguosha:getCard(id):getSuitString()] then
                    suits[sgs.Sanguosha:getCard(id):getSuitString()] = true
                end
            end
            local ids = sgs.IntList()
            for _, id in sgs.qlist(room:getDiscardPile()) do
                if not suits[sgs.Sanguosha:getCard(id):getSuitString()] then
                    ids:append(id)
                end
            end
            if not ids:isEmpty() then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setPlayerMark(player, self:objectName() .. "_" .. player:getPhaseString() .. "_end_clear", 1)
                    room:fillAG(ids)
                    while not ids:isEmpty() do
                        local remove_list = sgs.IntList()
                        local to_gain = room:askForAG(player, ids, false, "sakamichi_ming_chan")
                        if to_gain then
                            room:takeAG(player, to_gain, true)
                            remove_list:append(to_gain)
                            for _, id in sgs.qlist(ids) do
                                if sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(to_gain):getSuit() then
                                    room:takeAG(nil, id, false)
                                    remove_list:append(id)
                                end
                            end
                        else
                            break
                        end
                        for _, id in sgs.qlist(remove_list) do
                            ids:removeOne(id)
                        end
                    end
                    room:clearAG()
                    room:broadcastInvoke("clearAG")
                end
            end
        end
        return false
    end,
}
RikaSato:addSkill(sakamichi_ming_chan)

sgs.LoadTranslationTable {
    ["RikaSato"] = "佐藤 璃果",
    ["&RikaSato"] = "佐藤 璃果",
    ["#RikaSato"] = "骇客少女",
    ["~RikaSato"] = "トキメキを大切に輝きたい",
    ["designer:RikaSato"] = "Cassimolar",
    ["cv:RikaSato"] = "佐藤 璃果",
    ["illustrator:RikaSato"] = "Cassimolar",
    ["sakamichi_li_ke"] = "理科",
    [":sakamichi_li_ke"] = "一名角色使用【杀】时，你可以弃置其一张牌令此【杀】不可响应，若该角色为你，你摸一张牌。",
    ["sakamichi_li_ke:invoke"] = "是否发动【%arg】弃置%src 一张牌令其使用的此【%arg2】无法响应",
    ["sakamichi_bian_cheng"] = "编程",
    [":sakamichi_bian_cheng"] = "结束阶段，若你本回合使用过的牌的点数严格递增，你可以摸X张牌（X为你本回合使用牌的数量）；若花色严格按照黑桃红桃梅花方块的顺序循环不小于一次，你执行一个额外的回合。",
    ["sakamichi_ming_chan"] = "名产",
    [":sakamichi_ming_chan"] = "<font color=\"green\"><b>出牌阶段和弃牌阶段各限一次</b></font>，当你的牌因弃置进入弃牌堆后，你可以从弃牌堆选择并获得与弃置牌花色均不相同的牌各一张。",
}

-- 北川 悠理
YuriKitagawa = sgs.General(Sakamichi, "YuriKitagawa", "Nogizaka46", 3, false)
SKMC.YonKiSei.YuriKitagawa = true
SKMC.SeiMeiHanDan.YuriKitagawa = {
	name = {5, 3, 11, 11},
	ten_kaku = {8, "ji"},
	jin_kaku = {14, "xiong"},
	ji_kaku = {22, "xiong"},
	soto_kaku = {16, "da_ji"},
	sou_kaku = {30, "ji_xiong_hun_he"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "huo",
		ji_kaku = "mu",
		san_sai = "ji",
	},
}

sakamichi_sheng_ye_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_sheng_ye",
    filter_pattern = ".|.|.|qi_ji",
    expand_pile = "qi_ji",
    view_as = function(self, card)
        if sgs.Self:hasFlag("sheng_ye_retrial") then
            local cd = sgs.Sanguosha:cloneCard(card)
            cd:addSubcard(card)
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return not player:getPile("qi_ji"):isEmpty() and player:hasFlag("sheng_ye_retrial")
    end,
}
sakamichi_sheng_ye = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_ye",
    view_as_skill = sakamichi_sheng_ye_view_as,
    events = {sgs.StartJudge, sgs.FinishJudge, sgs.AskForRetrial, sgs.CardsMoveOneTime, sgs.EventPhaseProceeding, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if event == sgs.StartJudge then
            if judge.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("guess:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. judge.reason)) then
                        local suit_str = sgs.Card_Suit2String(room:askForSuit(p, self:objectName()))
                        SKMC.choice_log(p, suit_str)
                        p:setTag(player:objectName() .. "_" .. self:objectName(), sgs.QVariant(suit_str))
                        room:setPlayerFlag(p, "sheng_ye_used")
                    end
                end
            end
        elseif event == sgs.FinishJudge then
            if judge.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("sheng_ye_used") then
                        local suit_str = p:getTag(player:objectName() .. "_" .. self:objectName()):toString()
                        if judge.card:getSuitString() == suit_str then
                            p:addToPile("qi_ji", room:getNCards(1))
                        end
                        room:setPlayerFlag(p, "-sheng_ye_used")
                        p:removeTag(player:objectName() .. "_" .. self:objectName())
                    end
                end
            end
        elseif event == sgs.AskForRetrial then
            if player:hasSkill(self:objectName()) and not player:getPile("qi_ji"):isEmpty() then
                room:setPlayerFlag(player, "sheng_ye_retrial")
                local card = room:askForCard(player, ".|.|.|qi_ji", "@sheng_ye_card:" .. judge.who:objectName() .. "::" ..judge.reason .. ":" .. judge.card:objectName(),
                                                data, sgs.Card_MethodResponse, judge.who, true)
                room:setPlayerFlag(player, "-sheng_ye_retrial")
                if card then
                    room:retrial(card, player, judge, self:objectName())
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) and move.to_place and move.to_place == sgs.Player_PlaceSpecial and
                move.to_pile_name and move.to_pile_name == "qi_ji" then
                room:addPlayerMark(player, "&" .. self:objectName(), move.card_ids:length())
            end
        elseif event == sgs.EventPhaseProceeding then
            if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 and player:getMark("&" .. self:objectName()) >= 20 then
                room:sendShimingLog(player, self:objectName())
                while player:getMark("sheng_ye_used") <= player:getMark("&" .. self:objectName()) do
                    local basic_pattern = {}
                    for _, pattern in ipairs(SKMC.Pattern.BasicCard.Slash) do
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                            card:deleteLater()
                            card:setSkillName(self:objectName())
                            if player:canSlash(p, card, false) and  not sgs.Sanguosha:isProhibited(player, p, card) then
                                table.insert(basic_pattern, pattern)
                                break
                            end
                        end
                    end
                    for _, pattern in ipairs(SKMC.Pattern.BasicCard) do
                        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                        card:deleteLater()
                        card:setSkillName(self:objectName())
                        if not card:isKindOf("Jink") and not table.contains(basic_pattern, pattern) and not sgs.Sanguosha:isProhibited(player, player, card) then
                            if card:isKindOf("Peach") then
                                if player:isWounded() then
                                    table.insert(basic_pattern, pattern)
                                end
                            else
                                table.insert(basic_pattern, pattern)
                            end
                        end
                    end
                    if #basic_pattern ~= 0 then
                        local pattern = basic_pattern[math.random(1, #basic_pattern)]
                        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                        card:deleteLater()
                        card:setSkillName(self:objectName())
                        if card:isKindOf("Slash") then
                            local target_list = sgs.SPlayerList()
                            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                                if player:canSlash(p, card, false) and  not sgs.Sanguosha:isProhibited(player, p, card) then
                                    target_list:append(p)
                                end
                            end
                            if not target_list:isEmpty() then
                                local target_index = math.random(1, target_list:length())
                                local index = 1
                                for _, p in sgs.qlist(target_list) do
                                    if index == target_index then
                                        room:useCard(sgs.CardUseStruct(card, player, p))
                                        room:addPlayerMark(player, "sheng_ye_used")
                                        break
                                    else
                                        index = index + 1
                                    end
                                end
                            end
                        else
                            room:useCard(sgs.CardUseStruct(card, player, player))
                            room:addPlayerMark(player, "sheng_ye_used")
                        end
                    end
                end
                room:setPlayerMark(player, "sheng_ye_used", 0)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) and player:getMark(self:objectName()) == 0 then
                room:sendShimingLog(player, self:objectName(), false)
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@sheng_ye_chosen:::" .. self:objectName())
                room:handleAcquireDetachSkills(target, self:objectName())
                target:addToPile("qi_ji", player:getPile("qi_ji"))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuriKitagawa:addSkill(sakamichi_sheng_ye)

sakamichi_mi_ma = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_ma",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() and move.to_place and move.to_place == sgs.Player_PlaceSpecial then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:drawCards(p, move.card_ids:length(), self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuriKitagawa:addSkill(sakamichi_mi_ma)

sgs.LoadTranslationTable {
    ["YuriKitagawa"] = "北川 悠理",
    ["&YuriKitagawa"] = "北川 悠理",
    ["#YuriKitagawa"] = "创造奇迹",
    ["~YuriKitagawa"] = "奇跡をおこす",
    ["designer:YuriKitagawa"] = "Cassimolar",
    ["cv:YuriKitagawa"] = "北川 悠理",
    ["illustrator:YuriKitagawa"] = "Cassimolar",
    ["sakamichi_sheng_ye"] = "奇迹",
    [":sakamichi_sheng_ye"] = "使命技，一名角色判定开始时，你可以猜测判定结果的花色，若正确你将牌堆顶的一张牌置于你的武将牌上称为「奇迹」；一名角色判定牌生效前，你可以打出一张「奇迹」代替之。成功：准备阶段，若你获得过至少20张「奇迹」，你视为随机使用等量的基本牌。失败，你死亡时，你令一名其他角色获得【奇迹】和你的「奇迹」。",
    ["qi_ji"] = "奇迹",
    ["sakamichi_sheng_ye:guess"] = "是否发动【%arg】猜测%src %arg2的判定牌的花色",
    ["@sheng_ye_card"] = "你可以打出一张「奇迹」来替换 %src 的 %arg 的判定牌 %arg2",
    ["@sheng_ye_chosen"] = "请选择一名其他角色令其获得【%arg】和你的「奇迹」",
    ["sakamichi_mi_ma"] = "密码",
    [":sakamichi_mi_ma"] = "当一张牌移出游戏时，你可以摸一张牌。",
}

-- 松岡 愛美
ManamiMatsuoka = sgs.General(Sakamichi, "ManamiMatsuoka", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.ManamiMatsuoka = true
SKMC.SeiMeiHanDan.ManamiMatsuoka = {
	name = {8, 8, 13, 9},
	ten_kaku = {16, "da_ji"},
	jin_kaku = {21, "ji"},
	ji_kaku = {22, "xiong"},
	soto_kaku = {17, "ji"},
	sou_kaku = {38, "ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "mu",
		ji_kaku = "mu",
		san_sai = "ji_xiong_hun_he",
	},
}

sakamichi_shu_xinCard = sgs.CreateSkillCard {
    name = "sakamichi_shu_xinCard",
    skill_name = "sakamichi_shu_xin",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        source:addToPile("&xin", self, false)
    end,
}
sakamichi_shu_xin_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_shu_xin",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_shu_xinCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_shu_xinCard")
    end,
}
sakamichi_shu_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_shu_xin",
    view_as_skill = sakamichi_shu_xin_view_as,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive and move.from_places and
                move.from_places:contains(sgs.Player_PlaceSpecial) and move.from_pile_names and table.contains(move.from_pile_names, "&xin") then
                room:drawCards(player, 2, self:objectName())
                room:setPlayerMark(player, "shu_xin", 1)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
            if player:getMark("shu_xin") ~= 0 then
                room:setPlayerMark(player, "shu_xin", 0)
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("Nogizaka46"))
            end
        elseif event == sgs.DrawNCards then
            if not player:getPile("&xin"):isEmpty() then
                for _, id in sgs.qlist(player:getPile("&xin")) do
                    room:obtainCard(player, id)
                end
                data:setValue(0)
            end
        end
        return false
    end,
}
ManamiMatsuoka:addSkill(sakamichi_shu_xin)

sakamichi_gui_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_gui_yin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) then
            if player:getKingdom() ~= "SakamichiKenshusei" then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("SakamichiKenshusei"))
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and use.from:objectName() == player:objectName() and player:getKingdom() == "Nogizaka46" then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
sakamichi_gui_yin_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_gui_yin_mod",
    pattern = ".",
    distance_limit_func = function(self, from, card)
        if from:hasSkill("sakamichi_gui_yin") then
            return 1000
        else
            return 0
        end
    end,
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_gui_yin") then
            return 1000
        end
    end,
}
ManamiMatsuoka:addSkill(sakamichi_gui_yin)
if not sgs.Sanguosha:getSkill("#sakamichi_gui_yin_mod") then SKMC.SkillList:append(sakamichi_gui_yin_mod) end

sgs.LoadTranslationTable {
    ["ManamiMatsuoka"] = "松岡 愛美",
    ["&ManamiMatsuoka"] = "松岡 愛美",
    ["#ManamiMatsuoka"] = "幻之四期",
    ["~ManamiMatsuoka"] = "",
    ["designer:ManamiMatsuoka"] = "Cassimolar",
    ["cv:ManamiMatsuoka"] = "松岡 愛美",
    ["illustrator:ManamiMatsuoka"] = "Cassimolar",
    ["sakamichi_shu_xin"] = "书信",
    [":sakamichi_shu_xin"] = "出牌阶段限一次，你可以将一张手牌背面向上置于你的武将牌上称为「信」。你可以将「信」视为手牌使用或打出。当你于回合外失去「信」时你摸两张牌并在你的下个出牌阶段开始将你的势力改为乃木坂46。摸牌阶段，若你有「信」则你放弃摸牌改为获得「信」。",
    ["&xin"] = "信",
    ["sakamichi_gui_yin"] = "归隐",
    [":sakamichi_gui_yin"] = "锁定技，准备阶段或结束阶段，若你的势力不为坂道研修生则改为坂道研修生；当你的势力为乃木坂46时，你使用牌无距离限制且可以摸一张牌。",
}

-- 矢久保 美緒
MioYakubo = sgs.General(Sakamichi, "MioYakubo", "Nogizaka46", 4, false)
SKMC.YonKiSei.MioYakubo = true
SKMC.SeiMeiHanDan.MioYakubo = {
	name = {5, 3, 9, 9, 14},
	ten_kaku = {17, "ji"},
	jin_kaku = {18, "ji"},
	ji_kaku = {23, "ji"},
	soto_kaku = {22, "xiong"},
	sou_kaku = {40, "ji_xiong_hun_he"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "jin",
		ji_kaku = "huo",
		san_sai = "xiong",
	},
}

sakamichi_xie_zui = sgs.CreateTriggerSkill {
    name = "sakamichi_xie_zui",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage, sgs.Damaged, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage or event == sgs.Damaged then
            local damage = data:toDamage()
            if (event == sgs.Damage and damage.from:objectName() == player:objectName() and player:hasSkill(self:objectName())) or
                (event == sgs.Damaged and damage.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) ) then
                if not damage.from:isKongcheng() then
                    if damage.from:getHandcardNum() == 1 then
                        damage.from:throwAllHandCards()
                    else
                        room:askForDiscard(damage.from, self:objectName(), 1, 1, false, false, nil, ".", self:objectName())
                    end
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) and death.damage and death.damage.from then
                local skill_list = {}
                for _, skill in sgs.qlist(death.damage.from:getVisibleSkillList()) do
                    if not skill:isAttachedLordSkill() then
                        table.insert(skill_list, "-" .. skill:objectName())
                    end
                end
                room:handleAcquireDetachSkills(death.damage.from, table.concat(skill_list, "|"))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MioYakubo:addSkill(sakamichi_xie_zui)

sakamichi_shuang_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_shuang_zi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getHandcardNum() < player:getHp() and room:askForSkillInvoke(player, self:objectName(), data) then
            local x = 0
            local can_trigger = player:isWounded()
            while player:getHandcardNum() < player:getHp() do
                room:drawCards(player, 1, self:objectName())
                x = x + 1
            end
            if can_trigger then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@shuang_zi_invoke:::" .. x, true)
                if target then
                    room:drawCards(target, x, self:objectName())
                end
            end
        end
        return false
    end,
}
MioYakubo:addSkill(sakamichi_shuang_zi)

sgs.LoadTranslationTable {
    ["MioYakubo"] = "矢久保 美緒",
    ["&MioYakubo"] = "矢久保 美緒",
    ["#MioYakubo"] = "可爱具象",
    ["~MioYakubo"] = "遠藤さくらちゃん♥",
    ["designer:MioYakubo"] = "Cassimolar",
    ["cv:MioYakubo"] = "矢久保 美緒",
    ["illustrator:MioYakubo"] = "Cassimolar",
    ["sakamichi_xie_zui"] = "谢罪",
    [":sakamichi_xie_zui"] = "锁定技，其他角色对你造成伤害后，其须弃置一张手牌；你死亡时，杀死你的角色失去所有技能。",
    ["sakamichi_shuang_zi"] = "双子",
    [":sakamichi_shuang_zi"] = "结束阶段，你可以将手牌补至X张（X为你的体力值），若你已受伤，你可以令一名其他角色摸等量的牌。",
    ["@shuang_zi_invoke"] = "你可以令一名其他角色摸%arg张牌",
}

-- 松尾 美佑
MiyuMatsuo = sgs.General(Sakamichi, "MiyuMatsuo", "Nogizaka46", 3, false)
SKMC.YonKiSei.MiyuMatsuo = true
SKMC.SeiMeiHanDan.MiyuMatsuo = {
	name = {8, 7, 9, 7},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {16, "da_ji"},
	ji_kaku = {16, "da_ji"},
	soto_kaku = {15, "da_ji"},
	sou_kaku = {31, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "tu",
		ji_kaku = "tu",
		san_sai = "ji",
	},
}

sakamichi_zhuan_zhe = sgs.CreateTriggerSkill {
    name = "sakamichi_zhuan_zhe",
    change_skill = true,
    events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.EventPhaseChanging, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if room:getChangeSkillState(player, self:objectName()) == 2 then
                    room:setChangeSkillState(player, self:objectName(), 1)
                    room:setPlayerProperty(player, "kingdom", sgs.QVariant("SakamichiKenshusei"))
                    room:setPlayerFlag(player, "zhuan_zhe_1")
                elseif room:getChangeSkillState(player, self:objectName()) == 1 then
                    room:setChangeSkillState(player, self:objectName(), 2)
                    room:setPlayerProperty(player, "kingdom", sgs.QVariant("Nogizaka46"))
                    room:setPlayerFlag(player, "zhuan_zhe_2")
                end
            end
        elseif event == sgs.DrawNCards then
            if player:hasFlag("zhuan_zhe_1") then
                data:setValue(data:toInt() + 1)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard and player:hasFlag("zhuan_zhe_1") then
                player:skip(change.to)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasFlag("zhuan_zhe_2") and use.card:isKindOf("Slash") then
                room:setCardFlag(use.card, "SlashIgnoreArmor")
            end
        end
        return false
    end,
}
sakamichi_zhuan_zhe_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_zhuan_zhe_target_mod",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_zhuan_zhe") and from:hasFlag("zhuan_zhe_2") then
            return 1
        end
    end,
}
sakamichi_zhuan_zhe_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_zhuan_zhe_card_limit",
    limit_list = function(self, player)
        if player:hasFlag("zhuan_zhe_1") and player:getPhase() == sgs.Player_Play then
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:hasFlag("zhuan_zhe_1") and player:getPhase() == sgs.Player_Play then
            return "Slash"
        else
            return ""
        end
    end,
}
MiyuMatsuo:addSkill(sakamichi_zhuan_zhe)
if not sgs.Sanguosha:getSkill("#sakamichi_zhuan_zhe_target_mod") then SKMC.SkillList:append(sakamichi_zhuan_zhe_target_mod) end
if not sgs.Sanguosha:getSkill("#sakamichi_zhuan_zhe_card_limit") then SKMC.SkillList:append(sakamichi_zhuan_zhe_card_limit) end

sakamichi_dan_lian = sgs.CreateTriggerSkill {
    name = "sakamichi_dan_lian",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetSpecified, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.to:length() == 1 then
                local last_target = player:getTag("sakamichi_dan_lian_last_target"):toPlayer()
                if last_target then
                    local target = use.to:first()
                    if last_target:objectName() == target:objectName() then
                        room:setCardFlag(use.card, self:objectName())
                    end
                end
                for _, mark in sgs.list(player:getMarkNames()) do
                    if mark:startsWith("&" .. self:objectName()) then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. use.to:first():getGeneralName(), 1)
                local _target = sgs.QVariant()
                _target:setValue(use.to:first())
                player:setTag("sakamichi_dan_lian_last_target", _target)
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag(self:objectName()) then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end,
}
MiyuMatsuo:addSkill(sakamichi_dan_lian)

sakamichi_sheng_si = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_si",
    frequency = sgs.Skill_Limited,
    limit_mark = "@sheng_si",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if player:getMark("@sheng_si") ~= 0 then
                    local target_list = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getKingdom() == "Nogizaka46" and SKMC.is_ki_be(p, 4) then
                            target_list:append(p)
                        end
                    end
                    if not target_list:isEmpty() then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            room:removePlayerMark(player, "@sheng_si")
                            local target = room:askForPlayerChosen(player, target_list, self:objectName(), "@sheng_si_chosen")
                            local skill_list = {}
                            for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                                table.insert(skill_list, skill:objectName())
                            end
                            if #skill_list ~= 0 then
                                local skill_name = room:askForChoice(player, self:objectName(), table.concat(skill_list, "+"))
                                SKMC.choice_log(player, skill_name)
                                room:acquireNextTurnSkills(player, self:objectName(), skill_name)
                                room:addPlayerMark(target, "&" .. self:objectName() .. "+ +" .. skill_name)
                            end
                        end
                    end
                else
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if mark:startsWith("&" .. self:objectName()) then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_sheng_si_invalidity = sgs.CreateInvaliditySkill {
    name = "#sakamichi_sheng_si_invalidity",
    skill_valid = function(self, player, skill)
        if player:getMark("&sakamichi_sheng_si+ +" .. skill:objectName()) ~= 0 then
            return false
        else
            return true
        end
    end,
}
MiyuMatsuo:addSkill(sakamichi_sheng_si)
if not sgs.Sanguosha:getSkill("#sakamichi_sheng_si_invalidity") then SKMC.SkillList:append(sakamichi_sheng_si_invalidity) end

sgs.LoadTranslationTable {
    ["MiyuMatsuo"] = "松尾 美佑",
    ["&MiyuMatsuo"] = "松尾 美佑",
    ["#MiyuMatsuo"] = "文武双全",
    ["~MiyuMatsuo"] = "あん？",
    ["designer:MiyuMatsuo"] = "Cassimolar",
    ["cv:MiyuMatsuo"] = "松尾 美佑",
    ["illustrator:MiyuMatsuo"] = "Cassimolar",
    ["sakamichi_zhuan_zhe"] = "转折",
    [":sakamichi_zhuan_zhe"] = "转换技，准备阶段，①修改你的势力为坂道研修生，本回合内：摸牌阶段多摸一张牌，出牌阶段你无法使用【杀】，跳过弃牌阶段；②修改你的势力为乃木坂46，本回合内：出牌阶段你可以使用【杀】的限制次数+1，你使用的【杀】无视防具。",
    ["sakamichi_dan_lian"] = "单恋",
    [":sakamichi_dan_lian"] = "当你使用【杀】指定目标后，若目标唯一且与你使用的上一张目标唯一的【杀】的目标相同，此【杀】造成伤害时，伤害+1。",
    ["sakamichi_sheng_si"] = "声似",
    [":sakamichi_sheng_si"] = "限定技，准备阶段，你可获得场上一名其他乃木坂46势力四期角色的一个技能直到你的下个回合开始，在此期间，其此技能失效。",
}

-- 金川 紗耶
SayaKanagawa = sgs.General(Sakamichi, "SayaKanagawa", "Nogizaka46", 4, false)
SKMC.YonKiSei.SayaKanagawa = true
SKMC.SeiMeiHanDan.SayaKanagawa = {
	name = {8, 3, 10, 9},
	ten_kaku = {11, "ji"},
	jin_kaku = {13, "da_ji"},
	ji_kaku = {19, "xiong"},
	soto_kaku = {17, "ji"},
	sou_kaku = {30, "ji_xiong_hun_he"},
	GoGyouSanSai = {
		ten_kaku = "mu",
		jin_kaku = "huo",
		ji_kaku = "shui",
		san_sai = "xiong",
	},
}

sakamichi_guan_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_xing",
    shiming_skill = true,
    events = {sgs.AfterDrawInitialCards, sgs.Death, sgs.Damaged, sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AfterDrawInitialCards and player:hasSkill(self:objectName()) and player:getMark(self:objectName()) == 0 then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@sakamichi_guan_xing_choice", false, true)
            local _data = sgs.QVariant()
            _data:setValue(target)
            player:setTag(self:objectName() .. "_target", _data)
            room:askForGuanxing(target, room:getNCards(math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, false), 0, true)
            room:askForGuanxing(player, room:getNCards(math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, true), 0, true)
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:objectName() ~= p:objectName() and p:getMark(self:objectName()) == 0 then
                        local target = p:getTag(self:objectName() .. "_target"):toPlayer()
                        if target and target:isAlive() then
                            room:askForGuanxing(target, room:getNCards(math.min(room:alivePlayerCount(), SKMC.number_correction(p, 5)), false, false), 0, true)
                        end
                        room:askForGuanxing(p, room:getNCards(math.min(room:alivePlayerCount(), SKMC.number_correction(p, 5)), false, true), 0, true)
                    end
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Thunder then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if damage.damage >= SKMC.number_correction(p, 3) then
                        if p:objectName() ~= player:objectName() then
                            if player:getMark(self:objectName()) == 0 then
                                room:sendShimingLog(p, self:objectName())
                                room:setPlayerMark(p, self:objectName() .. "_can_trigger", 1)
                            end
                        else
                            if player:getMark(self:objectName()) == 0 then
                                room:sendShimingLog(p, self:objectName(), false)
                                p:turnOver()
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) and
                player:getMark(self:objectName()) ~= 0 and player:getMark(self:objectName() .. "_can_trigger") ~= 0 then
                local target = player:getTag(self:objectName() .. "_target"):toPlayer()
                if target and target:isAlive() then
                    room:askForGuanxing(target, room:getNCards(math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, false), 0, true)
                end
                room:askForGuanxing(player, room:getNCards(math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, true), 0, true)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SayaKanagawa:addSkill(sakamichi_guan_xing)

sakamichi_ping_he = sgs.CreateTriggerSkill {
    name = "sakamichi_ping_he",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ping_he",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Thunder and player:getMark("@ping_he") ~= 0 and
            room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:::" .. self:objectName() .. ":" .. damage.damage)) then
            room:removePlayerMark(player, "@ping_he", 1)
            local choices = {}
            for i = 0, damage.damage, 1 do
                local x = i
                local y = damage.damage - i
                table.insert(choices, "recover=" .. x .. "=" .. y)
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                local x, y = string.match(choice, "recover=(%d+)=(%d+)")
                room:recover(player, sgs.RecoverStruct(player, nil, x))
                room:drawCards(player, y, self:objectName())
            -- end
            return true
        end
        return false
    end,
}
SayaKanagawa:addSkill(sakamichi_ping_he)

sgs.LoadTranslationTable {
    ["SayaKanagawa"] = "金川 紗耶",
    ["&SayaKanagawa"] = "金川 紗耶",
    ["#SayaKanagawa"] = "夜观星象",
    ["~SayaKanagawa"] = "ヘイワ！",
    ["designer:SayaKanagawa"] = "Cassimolar",
    ["cv:SayaKanagawa"] = "金川 紗耶",
    ["illustrator:SayaKanagawa"] = "Cassimolar",
    ["sakamichi_guan_xing"] = "观星",
    [":sakamichi_guan_xing"] = "使命技，分发起始手牌后，你选择一名其他角色，其与你分别观看牌堆底和牌堆顶X张牌，并可以将任意数量的牌以任意顺序置于牌堆顶或牌堆底，其他角色死亡时，你与该角色重复此流程（X为存活角色数且最大为5）。成功：当一名其他角色受到至少3点雷电伤害后，准备阶段，你可以与其重复此流程。失败：你受到至少3点雷电伤害后，你翻面。",
    ["@sakamichi_guan_xing_choice"] = "请选择一名和你一起看星星的角色",
    ["sakamichi_ping_he"] = "平和",
    [":sakamichi_ping_he"] = "限定技，当你受到雷电伤害时，你可以防止之并恢复X点体力摸Y张牌（X+Y等于此次伤害量）。",
    ["sakamichi_ping_he:invoke"] = "是否发动【%arg】防止此次%arg2点雷电伤害",
    ["sakamichi_ping_he:recover"] = "回复%src点体力摸%arg张牌",
}

-- 掛橋 沙耶香
SayakaKakehashi = sgs.General(Sakamichi, "SayakaKakehashi", "Nogizaka46", 4, false)
SKMC.YonKiSei.SayakaKakehashi = true
SKMC.SeiMeiHanDan.SayakaKakehashi = {
    name = {11, 16, 7, 9, 9},
    ten_kaku = {27, "ji_xiong_hun_he"},
    jin_kaku = {23, "ji"},
    ji_kaku = {25, "ji"},
    soto_kaku = {29, "te_shu_ge"},
    sou_kaku = {52, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_hao_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_hao_shi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") then
            if player:hasSkill(self:objectName()) then
                if player:faceUp() then
                    player:turnOver()
                end
                room:setPlayerChained(player, false)
                room:drawCards(player, 1, self:objectName())
            end
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() then
                    room:setPlayerMark(p, self:objectName(), 1)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_hao_shi_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_hao_shi_card_limit",
    limit_list = function(self, player)
        if player:hasSkill("sakamichi_hao_shi") then
            if player:getMark("sakamichi_hao_shi") == 0 then
                return "use"
            end
        end
        return ""
    end,
    limit_pattern = function(self, player)
        if player:hasSkill("sakamichi_hao_shi") then
            if player:getMark("sakamichi_hao_shi") == 0 then
                return "Peach"
            end
        end
        return ""
    end,
}
SayakaKakehashi:addSkill(sakamichi_hao_shi)
if not sgs.Sanguosha:getSkill("#sakamichi_hao_shi_card_limit") then SKMC.SkillList:append(sakamichi_hao_shi_card_limit) end

sakamichi_huan_xing_card = sgs.CreateSkillCard {
    name = "sakamichi_huan_xingCard",
    skill_name = "sakamichi_huan_xing",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.to:turnOver()
        room:damage(sgs.DamageStruct(self:getSkillName(), effect.to, effect.from, SKMC.number_correction(effect.from, 1)))
        if effect.to:faceUp() then
            room:addPlayerMark(effect.to, "huan_xing_start_start_clear", 1)
        end
    end,
}
sakamichi_huan_xing_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_huan_xing",
    view_as = function()
        return sakamichi_huan_xing_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_huan_xingCard")
    end,
}
sakamichi_huan_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_huan_xing",
    view_as_skill = sakamichi_huan_xing_view_as,
    events ={sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("huan_xing_start_start_clear") ~= 0 then
                    p:gainAnExtraTurn()
                    p:turnOver()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SayakaKakehashi:addSkill(sakamichi_huan_xing)

sgs.LoadTranslationTable {
    ["SayakaKakehashi"] = "掛橋 沙耶香",
    ["&SayakaKakehashi"] = "掛橋 沙耶香",
    ["#SayakaKakehashi"] = "熊孩子",
    ["~SayakaKakehashi"] = "血の味がします",
    ["designer:SayakaKakehashi"] = "Cassimolar",
    ["cv:SayakaKakehashi"] = "掛橋 沙耶香",
    ["illustrator:SayakaKakehashi"] = "Cassimolar",
    ["sakamichi_hao_shi"] = "豪食",
    [":sakamichi_hao_shi"] = "锁定技，其他角色使用过【桃】前，你无法使用【桃】。你使用【桃】时复原武将牌且摸一张牌。",
    ["sakamichi_huan_xing"] = "唤醒",
    [":sakamichi_huan_xing"] = "出牌阶段限一次，你可以令一名角色翻面并受到其造成的1点伤害，然后若其武将牌正面向上，本回合结束时其执行一个额外的回合并翻面。",
}

-- ====================================================================================================欅坂46====================================================================================================--

-- 石森 虹花
NijikaIshimori = sgs.General(Sakamichi, "NijikaIshimori", "Keyakizaka46", 3, false)
SKMC.IKiSei.NijikaIshimori = true
SKMC.SeiMeiHanDan.NijikaIshimori = {
	name = {5, 12, 9, 7},
	ten_kaku = {17, "ji"},
	jin_kaku = {21, "ji"},
	ji_kaku = {16, "da_ji"},
	soto_kaku = {12, "xiong"},
	sou_kaku = {33, "te_shu_ge"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "mu",
		ji_kaku = "tu",
		san_sai = "ji",
	},
}

sakamichi_mi_xuanCard = sgs.CreateSkillCard {
    name = "sakamichi_mi_xuanCard",
    skill_name = "sakamichi_mi_xuan",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:gainMaxHp(source, SKMC.number_correction(source, 1))
    end,
}
sakamichi_mi_xuan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_mi_xuan",
    filter_pattern = "Peach",
    view_as = function(self, card)
        local cd = sakamichi_mi_xuanCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_mi_xuanCard") and not player:isWounded()
    end,
}
sakamichi_mi_xuan = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_xuan",
    view_as_skill = sakamichi_mi_xuan_view_as,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:hasSkill(self:objectName()) then
            if player:getGeneral():getKingdom() ~= player:getKingdom() or (player:getGeneral2() and player:getGeneral2():getKingdom() ~= player:getKingdom()) then
                room:loseMaxHp(damage.to, SKMC.number_correction(damage.to, 1))
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NijikaIshimori:addSkill(sakamichi_mi_xuan)

sakamichi_chi_dun = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_dun",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        if math.abs(player:getHandcardNum() - player:getHp()) > n then
            n = n - 1
            data:setValue(n)
        end
        return false
    end,
}
NijikaIshimori:addSkill(sakamichi_chi_dun)

sakamichi_niu_langCard = sgs.CreateSkillCard {
    name = "sakamichi_niu_langCard",
    skill_name = "sakamichi_niu_lang",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getHp() < sgs.Self:getHp()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@niulang")
        room:setPlayerMark(effect.from, "niu_lang_to_" .. effect.to:objectName(), 1)
        room:setPlayerMark(effect.to, "niu_lang_from_" .. effect.from:objectName(), 1)
    end,
}
sakamichi_niu_lang_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_niu_lang",
    view_as = function(self)
        return sakamichi_niu_langCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getMark("@niulang") ~= 0 then
            for _, p in sgs.qlist(player:getSiblings()) do
                if p:getHp() < player:getHp() then
                    return true
                end
            end
        end
        return false
    end,
}
sakamichi_niu_lang = sgs.CreateTriggerSkill {
    name = "sakamichi_niu_lang",
    view_as_skill = sakamichi_niu_lang_view_as,
    frequency = sgs.Skill_Limited,
    limit_mark = "@niulang",
    events = {sgs.EventPhaseEnd, sgs.Damage, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "niu_lang_to_") and player:getMark(mark) ~= 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if string.find(mark, p:objectName()) then
                            local card = room:askForCard(player, ".", "@niu_lang_give:" .. p:objectName(), data, sgs.Card_MethodNone, p, false)
                            if card then
                                room:obtainCard(p, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), self:objectName(), ""), false)
                                if player:isWounded() then
                                    room:recover(player, sgs.RecoverStruct(p, nil, SKMC.number_correction(player, 1)))
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.Damage and player:getPhase() ~= sgs.Player_NotActive then
            local damage = data:toDamage()
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "niu_lang_from_") and player:getMark(mark) ~= 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if string.find(mark, p:objectName()) then
                            for i = SKMC.number_correction(p, 1), damage.damage, SKMC.number_correction(p, 1) do
                                room:drawCards(p, 1, self:objectName())
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if player:objectName() == dying.who:objectName() then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if (string.find(mark, "niu_lang_from_") or string.find(mark, "niu_lang_to_")) and player:getMark(mark) ~= 0 then
                        room:setPlayerMark(player, mark, 0)
                        for _, p in sgs.qlist(room:getOtherPlayers()) do
                            if string.find(mark, p:objectName()) then
                                for _, _mark in sgs.list(p:getMarkNames()) do
                                    if (string.find(_mark, "niu_lang_from_") or string.find(_mark, "niu_lang_to_")) and
                                        string.find(_mark, player:objectName()) and p:getMark(mark) ~= 0 then
                                        room:setPlayerMark(p, _mark, 0)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NijikaIshimori:addSkill(sakamichi_niu_lang)

sgs.LoadTranslationTable {
    ["NijikaIshimori"] = "石森 虹花",
    ["&NijikaIshimori"] = "石森 虹花",
    ["#NijikaIshimori"] = "巧克力人",
    ["~NijikaIshimori"] = "お前主食チョコだろ",
    ["designer:NijikaIshimori"] = "Cassimolar",
    ["cv:NijikaIshimori"] = "石森 虹花",
    ["illustrator:NijikaIshimori"] = "Cassimolar",
    ["sakamichi_mi_xuan"] = "密选",
    [":sakamichi_mi_xuan"] = "一名角色对你造成伤害时，若其角色势力和其武将牌势力不同，你失去1点体力上限防止此伤害。出牌阶段限一次，若你未受伤，你可以弃置一张【桃】来增加1点体力上限。",
    ["sakamichi_chi_dun"] = "迟钝",
    [":sakamichi_chi_dun"] = "锁定技，摸牌阶段，若你的体力值与你手牌数的差大于额定摸牌数，你少摸一张牌。",
    ["sakamichi_niu_lang"] = "牛郎",
    [":sakamichi_niu_lang"] = "限定技，出牌阶段，你可以选择一名体力值小于你的角色，直到你或其进入濒死：你的结束阶段可以交给其一张手牌，然后其令你回复1点体力；其于其回合内每造成1点伤害，你摸一张牌。",
    ["@niulang"] = "牛郎",
    ["@niu_lang_give"] = "你可以交给%src一张手牌",
}

-- 鈴木 泉帆
MizuhoSuzuki = sgs.General(Sakamichi, "MizuhoSuzuki", "Keyakizaka46", 3, false)
SKMC.IKiSei.MizuhoSuzuki = true
SKMC.SeiMeiHanDan.MizuhoSuzuki = {
	name = {13, 4, 9, 6},
	ten_kaku = {17, "ji"},
	jin_kaku = {13, "da_ji"},
	ji_kaku = {15, "da_ji"},
	soto_kaku = {19, "ji"},
	sou_kaku = {31, "ji"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "huo",
		ji_kaku = "mu",
		san_sai = "ji_xiong_hun_he",
	},
}

--[[
    技能名：年少
    描述：当你受到伤害时，若你的体力不为全场最多，你可以摸一张牌或弃置一张牌令此伤害-1。
]]
sakamichi_nian_shao = sgs.CreateTriggerSkill {
    name = "sakamichi_nian_shao",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            if not player:canDiscard(player, "he") and room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@nian_shao_discard") then
                damage.damage = damage.damage - 1
                data:setValue(damage)
                if damage.damage < 1 then
                    return true
                end
            else
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
MizuhoSuzuki:addSkill(sakamichi_nian_shao)

--[[
    技能名：亲阻
    描述：限定技，出牌阶段，你可以将势力修改为自闭群，然后增加1点体力上限并回复1点体力，然后若你的手牌数小于体力上限，你摸三张牌。
]]
sakamichi_qin_zuCard = sgs.CreateSkillCard {
    name = "sakamichi_qin_zuCard",
    skill_name = "sakamichi_qin_zu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        source:loseMark("@qin_zu")
        room:setPlayerProperty(source, "kingdom", sgs.QVariant("AutisticGroup"))
        room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1))
        room:recover(source, sgs.RecoverStruct(source, nil, 1))
        if source:getHandcardNum() < source:getMaxHp() then
            room:drawCards(source, 3, "sakamichi_qin_zu")
        end
    end,
}
sakamichi_qin_zu = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_qin_zu",
    frequency = sgs.Skill_Limited,
    limit_mark = "@qin_zu",
    view_as = function(self)
        return sakamichi_qin_zuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@qin_zu") ~= 0
    end,
}
MizuhoSuzuki:addSkill(sakamichi_qin_zu)

sgs.LoadTranslationTable {
    ["MizuhoSuzuki"] = "鈴木 泉帆",
    ["&MizuhoSuzuki"] = "鈴木 泉帆",
    ["#MizuhoSuzuki"] = "立教美人",
    ["~MizuhoSuzuki"] = "鈴木泉帆って誰？",
    ["designer:MizuhoSuzuki"] = "Cassimolar",
    ["cv:MizuhoSuzuki"] = "鈴木 泉帆",
    ["illustrator:MizuhoSuzuki"] = "Cassimolar",
    ["sakamichi_nian_shao"] = "年少",
    [":sakamichi_nian_shao"] = "当你受到伤害时，若你的体力不为全场最多，你可以摸一张牌或弃置一张牌令此伤害-1。",
    ["@nian_shao_discard"] = "你可以弃置一张牌来使此伤害-1，否则摸一张牌",
    ["sakamichi_qin_zu"] = "亲阻",
    [":sakamichi_qin_zu"] = "限定技，出牌阶段，你可以将势力修改为自闭群，然后增加1点体力上限并回复1点体力，然后若你的手牌数小于体力上限，你摸三张牌。",
    ["@qin_zu"] = "亲阻",
}

-- 平手 友梨奈
YurinaHirate = sgs.General(Sakamichi, "YurinaHirate$", "Keyakizaka46", 3, false)
SKMC.IKiSei.YurinaHirate = true
SKMC.SeiMeiHanDan.YurinaHirate = {
	name = {5, 4, 4, 11, 8},
	ten_kaku = {9, "xiong"},
	jin_kaku = {8, "ji"},
	ji_kaku = {23, "ji"},
	soto_kaku = {24, "da_ji"},
	sou_kaku = {32, "ji"},
	GoGyouSanSai = {
		ten_kaku = "shui",
		jin_kaku = "jin",
		ji_kaku = "huo",
		san_sai = "xiong",
	},
}

sakamichi_hei_yang = sgs.CreateTriggerSkill {
    name = "sakamichi_hei_yang$",
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isDamageCard() then
                if not damage.card:hasFlag("hei_yang_damage_done") then
                    if damage.card:hasFlag("hei_yang_damage") then
                        room:setCardFlag(damage.card, "hei_yang_damage_done")
                    else
                        damage.card:setFlags("hei_yang_damage")
                        damage.card:setTag("hei_yang", sgs.QVariant(damage.to:objectName()))
                    end
                end
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("hei_yang_damage") then
                room:setCardFlag(use.card, "-hei_yang_damage")
                if not use.card:hasFlag("hei_yang_damage_done") then
                    if use.from and (use.from:getKingdom() == "Keyakizaka46" or use.from:getKingdom() == "HiraganaKeyakizaka46") and use.to:length() > 1 then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if p:hasLordSkill(self:objectName()) and room:askForSKillInvoke(p, self:objectName(), data) then
                                for _, pl in sgs.qlist(use.to) do
                                    if pl:objectName() ~= use.card:getTag("hei_yang"):toString() then
                                        room:damage(sgs.DamageStruct(self:objectName(), p, pl, SKMC.number_correction(p, 1)))
                                    end
                                end
                            end
                        end
                    end
                else
                    room:setCardFlag(use.card, "-hei_yang_damage_done")
                end
                use.card:removeTag("hei_yang")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YurinaHirate:addSkill(sakamichi_hei_yang)

sakamichi_ping_shou = sgs.CreateTriggerSkill {
    name = "sakamichi_ping_shou",
    events = {sgs.PindianVerifying, sgs.SlashMissed, sgs.Pindian},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() or pindian.to:objectName() == player:objectName() then
                local target
                local target_point
                if pindian.from:objectName() == player:objectName() then
                    target = pindian.to
                    target_point = pindian.to_number
                else
                    target = pindian.from
                    target_point = pindian.from_number
                end
                if player:canDiscard(player, "he") and room:askForDiscard(player, self:objectName(), 1, 1, true, false, "@ping_shou_invoke:" .. target:objectName() .. "::" .. target_point) then
                    if pindian.from:objectName() == player:objectName() then
                        pindian.from_number = pindian.to_number
                    else
                        pindian.to_number = pindian.from_number
                    end
                end
            end
        elseif event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if player:canPindian(effect.to) and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@ping_shou_pindian:" .. effect.to:objectName())) then
                player:pindian(effect.to, self:objectName())
            end
        else
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() and pindian.reason == self:objectName() then
                if pindian.from_number == pindian.to_number then
                    room:drawCards(pindian.from, 1, self:objectName())
                    room:drawCards(pindian.to, 1, self:objectName())
                elseif pindian.from_number > pindian.to_number then
                    room:drawCards(pindian.to, 1, self:objectName())
                else
                    room:drawCards(pindian.from, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
YurinaHirate:addSkill(sakamichi_ping_shou)

sakamichi_ji_shang = sgs.CreateTriggerSkill {
    name = "sakamichi_ji_shang",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_tuo_tui",
    events = {sgs.CardsMoveOneTime},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPile("shang"):length() >= 6 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:gainMaxHp(player, SKMC.number_correction(player, 1))
        room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
        local lord_skill = {}
        for _, skill in sgs.qlist(player:getVisibleSkillList()) do
            if skill:isLordSkill() and player:hasLordSkill(skill:objectName()) then
                table.insert(lord_skill, "-" .. skill:objectName())
            end
        end
        room:handleAcquireDetachSkills(player, table.concat(lord_skill, "|"))
        room:handleAcquireDetachSkills(player, "sakamichi_tuo_tui")
        room:setPlayerProperty(player, "kingdom", sgs.QVariant("AutisticGroup"))
        room:addPlayerMark(player, self:objectName())
        return false
    end,
}
sakamichi_ji_shang_record = sgs.CreateTriggerSkill {
    name = "#sakamichi_ji_shang_record",
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if player:hasSkill("sakamichi_ji_shang") and player:getMark("sakamichi_ji_shang") == 0 then
            local damage = data:toDamage()
            if damage.card and not damage.card:isKindOf("SkillCard") then
                local ids = sgs.IntList()
                if damage.card:isVirtualCard() then
                    ids = damage.card:getSubcards()
                else
                    ids:append(damage.card:getEffectiveId())
                end
                if ids:length() > 0 then
                    local all_place_placetable = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                            all_place_placetable = false
                            break
                        end
                    end
                    if all_place_placetable then
                        local not_include = true
                        for _, id in sgs.qlist(player:getPile("shang")) do
                            if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(damage.card) then
                                not_include = false
                                break
                            end
                        end
                        if not_include then
                            player:addToPile("shang", damage.card)
                        end
                    end
                end
            end
        end
        return false
    end,
}
YurinaHirate:addSkill(sakamichi_ji_shang)
if not sgs.Sanguosha:getSkill("#sakamichi_ji_shang_record") then SKMC.SkillList:append(sakamichi_ji_shang_record) end

sakamichi_tuo_tui = sgs.CreateTriggerSkill {
    name = "sakamichi_tuo_tui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            for _, id in sgs.qlist(player:getPile("shang")) do
                if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(use.card) then
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                    break
                end
            end
        else
            for _, p in sgs.qlist(use.to) do
                if p:getKingdom() == "Keyakizaka46" or p:getKingdom() == "Sakurazaka46" then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_tuo_tui") then SKMC.SkillList:append(sakamichi_tuo_tui) end

sgs.LoadTranslationTable {
    ["YurinaHirate"] = "平手 友梨奈",
    ["&YurinaHirate"] = "平手 友梨奈",
    ["#YurinaHirate"] = "欅魂",
    ["~YurinaHirate"] = "エイプリルフールって何？嘘ついていいの？",
    ["designer:YurinaHirate"] = "Cassimolar",
    ["cv:YurinaHirate"] = "平手 友梨奈",
    ["illustrator:YurinaHirate"] = "Cassimolar",
    ["sakamichi_hei_yang"] = "黑羊",
    [":sakamichi_hei_yang"] = "主公技，欅坂46或けやき坂46势力的角色使用的伤害牌结算完成时，若此牌的目标多于一且此牌仅对一名角色造成伤害，你可以对此牌的其他目标造成1点伤害。",
    ["sakamichi_ping_shou"] = "平手",
    [":sakamichi_ping_shou"] = "你的拼点牌亮出时，你可以弃置一张牌令你的拼点牌点数等于拼点目标的拼点牌点数。你使用的【杀】被闪避时，你可以与其拼点，没赢的角色可以摸一张牌。",
    ["@ping_shou_invoke"] = "你可以弃置一张手牌来令你的拼点牌点数等于%src的拼点牌点数为%arg",
    ["sakamichi_ping_shou:@ping_shou_pindian"] = "你可以与%src进行一次拼点",
    ["sakamichi_ji_shang"] = "积伤",
    [":sakamichi_ji_shang"] = "觉醒技，当你受到伤害后，若你未受到过此牌名的牌造成过的伤害，将此牌置于你的武将牌上称为「伤」，当你拥有至少六张「伤」时，你增加1点体力上限并回复1点体力，然后失去所有主公技获得【脱退】并将势力改为自闭群。",
    ["shang"] = "伤",
    ["sakamichi_tuo_tui"] = "脱退",
    [":sakamichi_tuo_tui"] = "你使用牌时，若你的「伤」中包含此牌名，此牌无法响应。你使用牌指定欅坂46或櫻坂46势力的角色时可以摸一张牌。",
}

-- 小林 由依
YuiKobayashi_Keyakizaka = sgs.General(Sakamichi, "YuiKobayashi_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.YuiKobayashi_Keyakizaka = true
SKMC.SeiMeiHanDan.YuiKobayashi_Keyakizaka = {
	name = {3, 8, 5, 8},
	ten_kaku = {11, "ji"},
	jin_kaku = {13, "da_ji"},
	ji_kaku = {13, "da_ji"},
	soto_kaku = {11, "ji"},
	sou_kaku = {24, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "mu",
		jin_kaku = "huo",
		ji_kaku = "huo",
		san_sai = "da_ji",
	},
}

sakamichi_qiao_zhong = sgs.CreateTriggerSkill {
    name = "sakamichi_qiao_zhong$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@qiao_zhong",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local hasyurina = false
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if string.find(p:getGeneralName(), "YurinaHirate") or string.find(p:getGeneral2Name(), "YurinaHirate") then
                    hasyurina = true
                    break
                end
            end
            if not hasyurina and player:isLord() and player:getMark("@qiao_zhong") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                room:removePlayerMark(player, "@qiao_zhong")
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getKingdom() == "Keyakizaka46" then
                        if not p:faceUp() then
                            p:turnOver()
                        end
                        room:setPlayerChained(p, false)
                        room:recover(p, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                        room:drawCards(p, 1, self:objectName())
                        local general_1, general_2 = p:getGeneral(), p:getGeneral2()
                        local name_1, name_2 = p:getGeneralName(), p:getGeneral2Name()
                        local _general_1, _general_2
                        if general_1 then
                            if string.find(name_1, "Keyakizaka") then
                                _general_1 = sgs.Sanguosha:getGeneral(string.gsub(name_1, "Keyakizaka", "Sakurazaka"))
                            end
                            if not _general_1 or _general_1:getKingdom() ~= "Sakurazaka46" then
                                if general_1:getKingdom() == "Sakurazaka46" then
                                    _general_1 = general_1
                                end
                            end
                        end
                        if general_2 then
                            if string.find(name_2, "Keyakizaka") then
                                _general_2 = sgs.Sanguosha:getGeneral(string.gsub(name_2, "Keyakizaka", "Sakurazaka"))
                            end
                            if not _general_2 or _general_2:getKingdom() ~= "Sakurazaka46" then
                                if general_2:getKingdom() == "Sakurazaka46" then
                                    _general_2 = general_2
                                end
                            end
                        end
                        if _general_1 then
                            room:changeHero(p, _general_1:objectName(), false)
                        end
                        if _general_2 then
                            room:changeHero(p, _general_2:objectName(), false, true, true)
                        end
                    end
                end
            end
        end
        return false
    end,
}
YuiKobayashi_Keyakizaka:addSkill(sakamichi_qiao_zhong)

sakamichi_gu_du = sgs.CreateTriggerSkill {
    name = "sakamichi_gu_du",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            if player:isWounded() and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@wu_yu_invoke")) then
                room:recover(player, sgs.RecoverStruct(player, damage.card, SKMC.number_correction(player, 1)))
            else
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
sakamichi_gu_du_protect = sgs.CreateProhibitSkill {
    name = "#sakamichi_gu_du_protect",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_gu_du") and card:isKindOf("Peach") and to:objectName() ~= from:objectName()
    end,
}
YuiKobayashi_Keyakizaka:addSkill(sakamichi_gu_du)
if not sgs.Sanguosha:getSkill("#sakamichi_gu_du_protect") then SKMC.SkillList:append(sakamichi_gu_du_protect) end

sakamichi_kuang_quan = sgs.CreateTriggerSkill {
    name = "sakamichi_kuang_quan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Slash") then
                if use.card:isBlack() then
                    room:setCardFlag(use.card, "SlashIgnoreArmor")
                elseif use.card:isRed() then
                    if use.m_addHistory then
                        room:addPlayerHistory(player, use.card:getClassName(), -1)
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_kuang_quan_attack_range = sgs.CreateAttackRangeSkill {
    name = "#sakamichi_kuang_quan_attack_range",
    extra_func = function(self, player, include_weapon)
        if player:hasSkill("sakamichi_kuang_quan") then
            return SKMC.number_correction(player, 1)
        else
            return 0
        end
    end,
}
YuiKobayashi_Keyakizaka:addSkill(sakamichi_kuang_quan)
if not sgs.Sanguosha:getSkill("#sakamichi_kuang_quan_attack_range") then SKMC.SkillList:append(sakamichi_kuang_quan_attack_range) end

sgs.LoadTranslationTable {
    ["YuiKobayashi_Keyakizaka"] = "小林 由依",
    ["&YuiKobayashi_Keyakizaka"] = "小林 由依",
    ["#YuiKobayashi_Keyakizaka"] = "埼玉狂犬",
    ["~YuiKobayashi_Keyakizaka"] = "めっちゃ美味しい、すごいめっちゃ美味しい",
    ["designer:YuiKobayashi_Keyakizaka"] = "Cassimolar",
    ["cv:YuiKobayashi_Keyakizaka"] = "小林 由依",
    ["illustrator:YuiKobayashi_Keyakizaka"] = "Cassimolar",
    ["sakamichi_qiao_zhong"] = "敲钟",
    [":sakamichi_qiao_zhong"] = "主公技，限定技，准备阶段，若场上不存在【平手友梨奈】，你可以令场上所有欅坂46势力角色复原武将牌然后回复1点体力并摸一张牌，若该角色的武将有櫻坂46势力版本，替换其武将牌。",
    ["sakamichi_gu_du"] = "孤独",
    [":sakamichi_gu_du"] = "锁定技，你不是其他角色使用【杀】的合法目标。你使用【杀】造成伤害后，你回复1点体力或摸一张牌。",
    ["sakamichi_gu_du:@wu_yu_invoke"] = "你可以回复1点体力，否则摸一张牌",
    ["sakamichi_kuang_quan"] = "狂犬",
    [":sakamichi_kuang_quan"] = "锁定技，你的攻击范围+1；你使用的黑色【杀】无视防具；你使用的红色【杀】不计入使用次数限制。",
}

-- 原田 葵
AoiHarada_Keyakizaka = sgs.General(Sakamichi, "AoiHarada_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.AoiHarada_Keyakizaka = true
SKMC.SeiMeiHanDan.AoiHarada_Keyakizaka = {
	name = {10, 5, 12},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {17, "ji"},
	ji_kaku = {12, "xiong"},
	soto_kaku = {22, "xiong"},
	sou_kaku = {27, "ji_xiong_hun_he"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "jin",
		ji_kaku = "mu",
		san_sai = "ji_xiong_hun_he",
	},
}

sakamichi_xiao_xue_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_xue_sheng",
    events = {sgs.HpRecover, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.HpRecover and player:getPhase() ~= sgs.Player_NotActive then
            room:setPlayerFlag(player, "xiaoxuesheng")
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            if player:hasFlag("xiaoxuesheng") and not player:isKongcheng() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("@xiao_xue_sheng_invoke:" .. player:objectName())) then
                        room:drawCards(p, 2, self:objectName())
                        if p:objectName() ~= player:objectName() then
                            local cards = room:askForExchange(p, self:objectName(), 1, 1, false, "@xiao_xue_sheng_give_1:" .. player:objectName())
                            room:obtainCard(player, cards, false)
                        end
                    else
                        room:drawCards(player, 1, self:objectName())
                        if p:objectName() ~= player:objectName() then
                            local cards = room:askForExchange(player, self:objectName(), 2, 2, false, "@xiao_xue_sheng_give_2:" .. p:objectName())
                            room:obtainCard(p, cards, false)
                        end
                    end
                    if player:isKongcheng() then
                        break
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
AoiHarada_Keyakizaka:addSkill(sakamichi_xiao_xue_sheng)

sakamichi_dan_gaoCard = sgs.CreateSkillCard {
    name = "sakamichi_dan_gaoCard",
    skill_name = "sakamichi_dan_gao",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:isWounded()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local suit_str = sgs.Sanguosha:getCard(self:getSubcards():first()):getSuitString()
        room:recover(effect.to, sgs.RecoverStruct(effect.from, self, 1))
        if effect.to:getMark("dan_gao_" .. suit_str) == 0 then
            room:addPlayerMark(effect.to, "dan_gao_" .. suit_str)
            room:addPlayerMark(effect.to, "dan_gao")
        end
        local count = 0
        for _, mark in sgs.list(effect.to:getMarkNames()) do
            if string.find(mark, "dan_gao_") and effect.to:getMark(mark) ~= 0 then
                count = count + 1
            end
        end
        if count == 4 then
            room:handleAcquireDetachSkills(effect.to, "sakamichi_tang_niao_bing")
        end
        room:setPlayerFlag(effect.from, "dan_gao_use_" .. suit_str)
        if effect.from:hasFlag("dan_gao_use_heart") and effect.from:hasFlag("dan_gao_use_diamond") and effect.from:hasFlag("dan_gao_use_spade") and effect.from:hasFlag("dan_gao_use_club") then
            room:setPlayerFlag(effect.from, "dan_gao_used")
        end
    end,
}
sakamichi_dan_gao = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_dan_gao",
    filter_pattern = ".|.|.|hand",
    view_filter = function(self, to_select)
        return not sgs.Self:hasFlag("dan_gao_use_" .. to_select:getSuitString())
    end,
    view_as = function(self, card)
        local Card = sakamichi_dan_gaoCard:clone()
        Card:addSubcard(card:getId())
        Card:setSkillName(self:objectName())
        return Card
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("dan_gao_used")
    end,
}
AoiHarada_Keyakizaka:addSkill(sakamichi_dan_gao)

sakamichi_tang_niao_bing = sgs.CreateTriggerSkill {
    name = "sakamichi_tang_niao_bing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") then
            if not player:canDiscard(player, "he") or not room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@tang_niao_bing_discard") then
                room:loseHp(player, SKMC.number_correction(player, 1))
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_tang_niao_bing") then SKMC.SkillList:append(sakamichi_tang_niao_bing) end
AoiHarada_Keyakizaka:addRelateSkill("sakamichi_tang_niao_bing")

sgs.LoadTranslationTable {
    ["AoiHarada_Keyakizaka"] = "原田 葵",
    ["&AoiHarada_Keyakizaka"] = "原田 葵",
    ["#AoiHarada_Keyakizaka"] = "变人人",
    ["~AoiHarada_Keyakizaka"] = "高2です～",
    ["designer:AoiHarada_Keyakizaka"] = "Cassimolar",
    ["cv:AoiHarada_Keyakizaka"] = "原田 葵",
    ["illustrator:AoiHarada_Keyakizaka"] = "Cassimolar",
    ["sakamichi_xiao_xue_sheng"] = "小学生",
    [":sakamichi_xiao_xue_sheng"] = "每名角色结束阶段，若其有手牌且其本回合内回复过体力，你可以摸两张牌并交给其一张手牌或令其摸一张牌并交给你两张手牌。",
    ["sakamichi_xiao_xue_sheng:@xiao_xue_sheng_invoke"] = "你可以摸两张牌并交给%src一张手牌，否则%src摸一张牌并交给你两张手牌",
    ["@xiao_xue_sheng_give_1"] = "请选择交给%src的一张手牌",
    ["@xiao_xue_sheng_give_2"] = "请选择交给%src的两张手牌",
    ["sakamichi_dan_gao"] = "蛋糕",
    [":sakamichi_dan_gao"] = "出牌阶段，你可以弃置一张本回合内未以此法弃置过的花色的手牌令一名受伤角色回复1点体力，一名角色以此法回复体力的牌花色达到四种时其获得【糖尿病】。",
    ["sakamichi_tang_niao_bing"] = "糖尿病",
    [":sakamichi_tang_niao_bing"] = "锁定技，你使用【桃】时须弃置一张牌或失去1点体力。",
    ["@tang_niao_bing_discard"] = "请弃置一张牌，否则将失去1点体力",
}

-- 米谷 奈々未
NanamiYonetani = sgs.General(Sakamichi, "NanamiYonetani", "Keyakizaka46", 3, false)
SKMC.IKiSei.NanamiYonetani = true
SKMC.SeiMeiHanDan.NanamiYonetani = {
	name = {6, 7, 8, 3, 5},
	ten_kaku = {13, "da_ji"},
	jin_kaku = {15, "da_ji"},
	ji_kaku = {16, "da_ji"},
	soto_kaku = {14, "xiong"},
	sou_kaku = {29, "te_shu_ge"},
	GoGyouSanSai = {
		ten_kaku = "huo",
		jin_kaku = "tu",
		ji_kaku = "tu",
		san_sai = "da_ji",
	},
}

sakamichi_zhi_nv = sgs.CreateTriggerSkill {
    name = "sakamichi_zhi_nv",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.HpRecover, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:objectName() ~= player:objectName() and recover.who:isFemale() and player:canDisCard(player, "h") then
                room:askForDiscard(player, self:objectName(), 1, 1, false, false, "@zhi_nv_discard")
            end
        else
            local damage = data:toDamage()
            if damage.to and damage.to:isAlive() and damage.to:isFemale() and damage.to:objectName() ~= player:objectName() and player:canDiscard(damage.to, "hej") then
                local id = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
                room:throwCard(id, damage.to, player)
            end
        end
        return false
    end,
}
NanamiYonetani:addSkill(sakamichi_zhi_nv)

sakamichi_bo_xue = sgs.CreateTriggerSkill {
    name = "sakamichi_bo_xue",
    events = {sgs.CardUsed, sgs.Damaged, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("TrickCard") and not use.card:isKindOf("DelayedTrick") then
                local extra_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and not use.to:contains(p) and use.card:isAvailable(p) then
                        if use.card:targetFilter(sgs.PlayerList(), p, player) and room:askForSkillInvoke(p, self:objectName(),
                            sgs.QVariant("@bo_xue_invoke:" .. player:objectName() .. "::" .. use.card:objectName())) then
                            extra_targets:append(p)
                            room:setPlayerMark(p, "bo_xue" .. use.card:getEffectiveId(), 1)
                            room:setCardFlag(use.card, "bo_xue")
                        end
                    end
                end
                if not extra_targets:isEmpty() then
                    if use.card:isKindOf("Collateral") then
                        for _, p in sgs.qlist(extra_targets) do
                            local pl_list = sgs.SPlayerList()
                            for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                                local p_list = sgs.PlayerList()
                                p_list:append(p)
                                if use.card:targetFilter(p_list, pl, player) then
                                    pl_list:append(pl)
                                end
                            end
                            if pl_list:isEmpty() then
                                extra_targets:removeOne(p)
                            else
                                local victim = room:askForPlayerChosen(player, pl_list, self:objectName(), "@bo_xue_collateral:" .. p:objectName() .. "::" .. use.card:objectName())
                                local _data = sgs.QVariant()
                                _data:setValue(victim)
                                p:setTag("collateralVictim", _data)
                            end
                        end
                    end
                    for _, p in sgs.qlist(extra_targets) do
                        use.to:append(p)
                    end
                end
                room:sortByActionOrder(use.to)
                data:setValue(use)
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if player:hasSkill(self:objectName()) and damage.card and damage.card:hasFlag("bo_xue") and player:getMark("bo_xue" .. damage.card:getEffectiveId()) ~= 0 then
                player:obtainCard(damage.card)
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("bo_xue") then
                room:setCardFlag(use.card, "-bo_xue")
                for _, p in sgs.qlist(use.to) do
                    if p:getMark("bo_xue" .. use.card:getEffectiveId()) ~= 0 then
                        room:setPlayerMark(p, "bo_xue" .. use.card:getEffectiveId(), 0)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanamiYonetani:addSkill(sakamichi_bo_xue)

sakamichi_wu_ju = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_ju",
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and player:hasSkill(self:objectName()) and use.to:length() > 1 then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@wu_ju_invoke:" .. use.from:objectName() .. "::" .. use.card:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanamiYonetani:addSkill(sakamichi_wu_ju)

sgs.LoadTranslationTable {
    ["NanamiYonetani"] = "米谷 奈々未",
    ["&NanamiYonetani"] = "米谷 奈々未",
    ["#NanamiYonetani"] = "米警官",
    ["~NanamiYonetani"] = "色々違う！色々このグループ違う！",
    ["designer:NanamiYonetani"] = "Cassimolar",
    ["cv:NanamiYonetani"] = "米谷 奈々未",
    ["illustrator:NanamiYonetani"] = "Cassimolar",
    ["sakamichi_zhi_nv"] = "直女",
    [":sakamichi_zhi_nv"] = "锁定技，其他女性角色令你回复体力时你须弃置一张手牌；你对其他女性角色造成伤害后须弃置其区域内的一张牌。",
    ["sakamichi_bo_xue"] = "博学",
    [":sakamichi_bo_xue"] = "其他角色使用通常锦囊牌时，若你是此牌的合法目标，且不为此牌的目标，你可以成为此牌的额外目标，此牌对你造成伤害后，你获得此牌。",
    ["sakamichi_bo_xue:@bo_xue_invoke"] = "你可以成为%src使用的%arg的额外目标",
    ["sakamichi_wu_ju"] = "无惧",
    [":sakamichi_wu_ju"] = "当你成为卡牌的非唯一目标时，你可以摸一张牌令此牌无法响应。",
    ["sakamichi_wu_ju:@wu_ju_invoke"] = "你可以摸一张牌令%src使用的%arg无法响应",
}

-- 今泉 佑唯
YuiImaizumi = sgs.General(Sakamichi, "YuiImaizumi", "Keyakizaka46", 3, false)
SKMC.IKiSei.YuiImaizumi = true
SKMC.SeiMeiHanDan.YuiImaizumi = {
	name = {4, 9, 7, 11},
	ten_kaku = {13, "da_ji"},
	jin_kaku = {16, "da_ji"},
	ji_kaku = {18, "ji"},
	soto_kaku = {15, "da_ji"},
	sou_kaku = {31, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "huo",
		jin_kaku = "tu",
		ji_kaku = "jin",
		san_sai = "da_ji",
	},
}

sakamichi_wu_meiCard = sgs.CreateSkillCard {
    name = "sakamichi_wu_meiCard",
    skill_name = "sakamichi_wu_mei",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:hasFlag("wu_mei_target")
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasFlag("wu_mei_target") then
                room:setPlayerFlag(p, "-wu_mei_target")
            end
        end
        room:loseHp(effect.to)
    end,
}
sakamichi_wu_mei_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_wu_mei",
    filter_pattern = ".",
    response_pattern = "@@sakamichi_wu_mei",
    view_as = function(self, card)
        local SkillCard = sakamichi_wu_meiCard:clone()
        SkillCard:addSubcard(card)
        return SkillCard
    end,
}
sakamichi_wu_mei = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_mei",
    view_as_skill = sakamichi_wu_mei_view_as,
    events = {sgs.TargetConfirming, sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and use.from and use.from:hasSkill(self:objectName()) and use.to:contains(player) and use.from:objectName() ~= player:objectName() then
                room:setCardFlag(use.card, "wu_mei")
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("wu_mei") then
                room:setCardFlag(damage.card, "wu_mei_damage")
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("wu_mei") then
                room:setCardFlag(use.card, "-wu_mei")
                if use.card:hasFlag("wu_mei_damage") then
                    room:setCardFlag(use.card, "-wu_mei_damage")
                else
                    if player:isAlive() then
                        for _, p in sgs.qlist(use.to) do
                            room:setPlayerFlag(p, "wu_mei_target")
                        end
                        if not room:askForUseCard(player, "@@sakamichi_wu_mei", "@wu_mei_invoke:::" .. use.card:objectName()) then
                            for _, p in sgs.qlist(use.to) do
                                if p:hasFlag("wu_mei_target") then
                                    room:setPlayerFlag(p, "-wu_mei_target")
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuiImaizumi:addSkill(sakamichi_wu_mei)

sakamichi_ruo_li = sgs.CreateTriggerSkill {
    name = "sakamichi_ruo_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:getHp() > player:getHp() then
            damage.damage = damage.damage - SKMC.number_correction(player, 1)
            data:setValue(damage)
            if damage.damage < 1 then
                return true
            end
        end
        return false
    end,
}
YuiImaizumi:addSkill(sakamichi_ruo_li)

sakamichi_fei_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_fei_yu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getKingdom() == "Keyakizaka46" then
                    room:loseHp(p)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuiImaizumi:addSkill(sakamichi_fei_yu)

sgs.LoadTranslationTable {
    ["YuiImaizumi"] = "今泉 佑唯",
    ["&YuiImaizumi"] = "今泉 佑唯",
    ["#YuiImaizumi"] = "泉妹",
    ["~YuiImaizumi"] = "オニオンリング",
    ["designer:YuiImaizumi"] = "Cassimolar",
    ["cv:YuiImaizumi"] = "今泉 佑唯",
    ["illustrator:YuiImaizumi"] = "Cassimolar",
    ["sakamichi_wu_mei"] = "五妹",
    [":sakamichi_wu_mei"] = "你使用的目标包含其他角色的牌结算完成时，若此牌未造成伤害，你可以弃置一张牌令此牌目标中的一名角色失去1点体力。",
    ["@wu_mei_invoke"] = "你可以弃置一张牌选择此%arg的目标中一名角色失去1点体力",
    ["~sakamichi_wu_mei"] = "选择一张牌 → 选择一名角色 → 点击确定",
    ["sakamichi_ruo_li"] = "弱力",
    [":sakamichi_ruo_li"] = "锁定技，你对体力值大于你的角色造成伤害时，伤害-1。",
    ["sakamichi_fei_yu"] = "蜚语",
    [":sakamichi_fei_yu"] = "锁定技，你死亡时所有欅坂46势力角色失去1点体力。",
}

-- 志田 愛佳
ManakaShida = sgs.General(Sakamichi, "ManakaShida", "Keyakizaka46", 4, false)
SKMC.IKiSei.ManakaShida = true
SKMC.SeiMeiHanDan.ManakaShida = {
	name = {7, 5, 13, 8},
	ten_kaku = {12, "xiong"},
	jin_kaku = {18, "ji"},
	ji_kaku = {21, "ji"},
	soto_kaku = {15, "da_ji"},
	sou_kaku = {33, "te_shu_ge"},
	GoGyouSanSai = {
		ten_kaku = "mu",
		jin_kaku = "jin",
		ji_kaku = "mu",
		san_sai = "xiong",
	},
}

sakamichi_pan_ni = sgs.CreateTriggerSkill {
    name = "sakamichi_pan_ni",
    events = {sgs.TargetConfirming, sgs.SlashHit, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:hasSkill(self:objectName()) then
                player:setTag(self:objectName(), sgs.QVariant(use.card:getEffectiveId()))
                room:askForUseSlashTo(player, use.from, "@pan_ni_slash:" .. use.from:objectName(), false, false, true, nil, nil, "pan_ni_use")
                player:removeTag(self:objectName())
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("pan_ni_use") then
                if room:askForSkillInvoke(effect.from, self:objectName(), sgs.QVariant("@pan_ni_invoke:" .. effect.to:objectName() .. "::" .. effect.slash:objectName())) then
                    room:setCardFlag(effect.slash, "pan_ni_used")
                    room:setPlayerMark(effect.from, self:objectName(), effect.from:getTag(self:objectName()):toInt())
                end
                room:setCardFlag(effect.slash, "-pan_ni_use")
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                if damage.card:hasFlag("pan_ni_used") then
                    room:setCardFlag(damage.card, "-pan_ni_used")
                    return true
                end
                if damage.to:getMark(self:objectName()) ~= 0 and damage.card:getEffectiveId() == damage.to:getMark(self:objectName()) then
                    room:setPlayerMark(damage.to, self:objectName(), 0)
                    damage.damage = damage.damage - SKMC.number_correction(damage.to, 1)
                    SKMC.send_message(room, "#pan_ni_damage", damage.to, damage.from, nil, damage.card:toString(), self:objectName(), SKMC.number_correction(damage.to, 1), damage.damage)
                    data:setValue(damage)
                    if damage.damage < 1 then
                        return true
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ManakaShida:addSkill(sakamichi_pan_ni)

sakamichi_kuang_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_kuang_qi",
    events = {sgs.EventPhaseProceeding, sgs.EventPhaseStart, sgs.CardUsed, sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@kuang_qi_choice", true, true)
            if target then
                room:setPlayerMark(player, "kuang_qi_target" .. target:objectName(), 1)
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. target:getGeneralName(), 1)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self:objectName()) then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:getMark("kuang_qi_target" .. p:objectName()) ~= 0 then
                    room:setPlayerMark(player, "kuang_qi_target" .. p:objectName(), 0)
                end
            end
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "&" .. self:objectName()) and player:getMark(mark) ~= 0 then
                    room:setPlayerMark(player, mark, 0)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("kuang_qi_target" .. player:objectName()) ~= 0 and not use.to:contains(p) then
                        room:setPlayerMark(p, "kuang_qi_card_" .. use.card:getEffectiveId(), 1)
                        use.to:append(p)
                    end
                end
                data:setValue(use)
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card then
                if damage.to:getMark("kuang_qi_target" .. player:objectName()) ~= 0 then
                    room:setPlayerMark(damage.to, "kuang_qi_damage_" .. damage.card:getEffectiveId(), 1)
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            for _, p in sgs.qlist(use.to) do
                if p:getMark("kuang_qi_target" .. use.from:objectName()) ~= 0 then
                    if p:getMark("kuang_qi_card_" .. use.card:getEffectiveId()) ~= 0 then
                        if p:getMark("kuang_qi_damage_" .. use.card:getEffectiveId()) == 0 then
                            room:drawCards(p, 1, self:objectName())
                            if use.from:isAlive() then
                                local choices = {}
                                local choice_1 = "damage=" .. use.from:objectName() .."=" .. SKMC.number_correction(p, 1)
                                local choice_2 = "get=" .. use.from:objectName()
                                table.insert(choices, choice_1)
                                table.insert(choices, choice_2)
                                if use.from:isAllNude() or room:askForChoice(p, self:objectName(), table.concat(choices, "+")) == choice_1 then
                                    room:damage(sgs.DamageStruct(self:objectName(), p, use.from, SKMC.number_correction(p, 1)))
                                else
                                    local card = room:askForCardChosen(p, use.from, "hej", self:objectName(), false, sgs.Card_MethodNone)
                                    room:obtainCard(p, card)
                                end
                            end
                        else
                            room:setPlayerMark(p, "kuang_qi_damage_" .. use.card:getEffectiveId(), 0)
                        end
                        room:setPlayerMark(p, "kuang_qi_card_" .. use.card:getEffectiveId(), 0)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ManakaShida:addSkill(sakamichi_kuang_qi)

sgs.LoadTranslationTable {
    ["ManakaShida"] = "志田 愛佳",
    ["&ManakaShida"] = "志田 愛佳",
    ["#ManakaShida"] = "叛逆少女",
    ["~ManakaShida"] = "1日が24時間しかないこと",
    ["designer:ManakaShida"] = "Cassimolar",
    ["cv:ManakaShida"] = "志田 愛佳",
    ["illustrator:ManakaShida"] = "Cassimolar",
    ["sakamichi_pan_ni"] = "叛逆",
    [":sakamichi_pan_ni"] = "当你成为【杀】的目标时，你可以对此【杀】的使用着使用一张【杀】，若你使用的【杀】命中，你可以防止你使用的【杀】对其伤害并令其使用的【杀】对你造成的伤害-1。",
    ["@pan_ni_slash"] = "你可以对%src使用一张【杀】",
    ["sakamichi_pan_ni:@pan_ni_invoke"] = "你可以防止此【%arg】对%src造成的伤害",
    ["#pan_ni_damage"] = "%from 发动【%arg】令%to 使用的%card 对%from 造成的伤害-%arg2，伤害为%arg3",
    ["sakamichi_kuang_qi"] = "狂气",
    [":sakamichi_kuang_qi"] = "结束阶段，你可以选择一名其他角色，直到你的下个回合开始，其使用的【杀】的目标若不包含你则将你添加为额外目标，若此【杀】未对你造成伤害，你可以摸一张牌然后选择对其造成1点伤害或获得其区域内的一张牌。",
    ["@kuang_qi_choice"] = "你可以选择一名其他角色发动【狂气】",
    ["sakamichi_kuang_qi:damage"] = "对%src造成%arg点伤害",
    ["sakamichi_kuang_qi:get"] = "获得%src区域内的一张牌",
}

-- 長濱 ねる
NeruNagahama_Keyakizaka = sgs.General(Sakamichi, "NeruNagahama_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.NeruNagahama_Keyakizaka = true
SKMC.SeiMeiHanDan.NeruNagahama_Keyakizaka = {
	name = {8, 17, 4, 3},
	ten_kaku = {25, "ji"},
	jin_kaku = {21, "ji"},
	ji_kaku = {7, "ji"},
	soto_kaku = {11, "ji"},
	sou_kaku = {31, "ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "mu",
		ji_kaku = "jin",
		san_sai = "xiong",
	},
}

sakamichi_chi_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_dao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.EventPhaseStart, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            room:setPlayerMark(player, self:objectName(), 2)
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive and player:getMark(self:objectName()) == 2 then
                -- player:skip(change.to)
                change.to = sgs.Player_NotActive
                data:setValue(change)
            end
        elseif  event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 1 then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant(room:askForChoice(player, self:objectName(), "Keyakizaka46+HiraganaKeyakizaka46")))
                room:setPlayerMark(player, self:objectName(), 0)
                room:setPlayerFlag(player, "chi_dao")
                room:addAttackRange(player, player:getLostHp() + SKMC.number_correction(player, 2))
            elseif player:getPhase() == sgs.Player_NotActive and player:getMark(self:objectName()) == 2  then
                room:setPlayerMark(player, self:objectName(), 1)
            elseif player:getPhase() == sgs.Player_Play and player:hasFlag("chi_dao") then
                room:addSlashCishu(player, player:getLostHp() + SKMC.number_correction(player, 2))
            end
        elseif event == sgs.DrawNCards then
            local draw = data:toInt()
            if player:hasFlag("chi_dao") then
                data:setValue(draw + player:getLostHp() + SKMC.number_correction(player, 2))
            end
        end
        return false
    end,
}
NeruNagahama_Keyakizaka:addSkill(sakamichi_chi_dao)

sakamichi_guan_tui = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_tui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if player:getKingdom() == "Keyakizaka46" or player:getKingdom() == "HiraganaKeyakizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("@guan_tui_invoke:" .. player:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                    local card = room:askForCard(player, ".|.|.|hand!", "@guan_tui_give:" .. p:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
                    if card then
                        room:obtainCard(p, card, false)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NeruNagahama_Keyakizaka:addSkill(sakamichi_guan_tui)

sakamichi_meng_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_meng_yin",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.to:length() > 1 then
            local target = room:askForPlayerChosen(player, use.to, self:objectName(), "@meng_yin_choice:::" .. use.card:objectName(), true, true)
            if target then
                use.to:removeOne(target)
                data:setValue(use)
                room:damage(sgs.DamageStruct(self:objectName(), player, target, SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
NeruNagahama_Keyakizaka:addSkill(sakamichi_meng_yin)

sgs.LoadTranslationTable {
    ["NeruNagahama_Keyakizaka"] = "長濱 ねる",
    ["&NeruNagahama_Keyakizaka"] = "長濱 ねる",
    ["#NeruNagahama_Keyakizaka"] = "等待百年",
    ["~NeruNagahama_Keyakizaka"] = "8.6秒バズーカー",
    ["designer:NeruNagahama_Keyakizaka"] = "Cassimolar",
    ["cv:NeruNagahama_Keyakizaka"] = "長濱 ねる",
    ["illustrator:NeruNagahama_Keyakizaka"] = "Cassimolar",
    ["sakamichi_chi_dao"] = "迟到",
    [":sakamichi_chi_dao"] = "锁定技，跳过你的第一个回合；你的第二个回合开始时，你须将势力改为欅坂46或けやき坂46，本回合内：摸牌阶段你额外摸X张牌；出牌阶段你使用【杀】的限制次数+X；攻击范围+X（X为你已损失的体力值+2）。",
    ["sakamichi_guan_tui"] = "官推",
    [":sakamichi_guan_tui"] = "欅坂46或けやき坂46势力的角色造成伤害后，你可以令其摸一张牌然后交给你一张手牌。",
    ["sakamichi_guan_tui:@guan_tui_invoke"] = "是否令%src摸一张牌然后交给你一张手牌",
    ["@guan_tui_give"] = "请选择一张手牌交给%src",
    ["sakamichi_meng_yin"] = "萌音",
    [":sakamichi_meng_yin"] = "你使用目标多于一的卡牌时，你可以取消其中的一个目标，并对其造成1点伤害。",
    ["@meng_yin_choice"] = "你可以取消此%arg中的一个目标并对其造成1点伤害",
}

-- 小池 美波
MinamiKoike_Keyakizaka = sgs.General(Sakamichi, "MinamiKoike_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.MinamiKoike_Keyakizaka = true
SKMC.SeiMeiHanDan.MinamiKoike_Keyakizaka = {
	name = {3, 6, 9, 8},
	ten_kaku = {9, "xiong"},
	jin_kaku = {15, "da_ji"},
	ji_kaku = {17, "ji"},
	soto_kaku = {11, "ji"},
	sou_kaku = {26, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "shui",
		jin_kaku = "tu",
		ji_kaku = "jin",
		san_sai = "ji_xiong_hun_he",
	},
}

sakamichi_sa_jiaoCard = sgs.CreateSkillCard {
    name = "sakamichi_sa_jiaoCard",
    skill_name = "sakamichi_sa_jiao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.to:isNude() then
            room:setPlayerMark(effect.to, "sa_jiao_distance", 1)
        else
            local choice = room:askForChoice(effect.from, "sakamichi_sa_jiao", "BasicCard+TrickCard+EquipCard")
            local card = room:askForCard(effect.to, choice, "@sa_jiao_give_1:" .. effect.from:objectName() .. "::" .. choice, sgs.QVariant(), sgs.Card_MethodNone)
            if card then
                room:moveCardTo(card, effect.from, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.to:objectName(),
                                                                                            effect.from:objectName(), self:getSkillName(), ""))
                room:showCard(effect.from, card:getEffectiveId())
                room:addPlayerMark(effect.from, "sa_jiao" .. card:getClassName() .. "_finish_end_clear")
            else
                room:setPlayerCardLimitation(effect.to, "use,response", ".|.|.|hand", true)
            end
        end
    end,
}
sakamichi_sa_jiao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sa_jiao",
    view_as = function()
        return sakamichi_sa_jiaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_sa_jiaoCard")
    end,
}
sakamichi_sa_jiao = sgs.CreateTriggerSkill {
    name = "sakamichi_sa_jiao",
    view_as_skill = sakamichi_sa_jiao_view_as,
    events = {sgs.CardUsed, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
                local choice = room:askForChoice(player, self:objectName(), "BasicCard+TrickCard+EquipCard")
                local card = room:askForCard(damage.from, choice, "@sa_jiao_give_2:" .. player:objectName() .. "::" .. choice, sgs.QVariant(), sgs.Card_MethodNone)
                if card then
                    room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, damage.from:objectName(),
                                                                                            player:objectName(), self:objectName(), ""))
                    room:showCard(player, card:getEffectiveId())
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("sa_jiao_discard")) then
                        room:throwCard(card, player, player)
                        room:drawCards(player, 1, self:objectName())
                    end
                else
                    room:addMaxCards(damage.from, -1, true)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getMark("sa_jiao" .. use.card:getClassName() .. "_finish_end_clear") > 0 then
                local no_respond_list = use.no_respond_list
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    table.insert(no_respond_list, p:objectName())
                end
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MinamiKoike_Keyakizaka:addSkill(sakamichi_sa_jiao)

sakamichi_ruan_jiaoCard = sgs.CreateSkillCard {
    name = "sakamichi_ruan_jiaoCard",
    skill_name = "sakamichi_ruan_jiao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        -- local card = room:askForCard(effect.to, "Horse|.|.|equipped", "@ruan_jiao_discard:" .. effect.from:objectName(), sgs.QVariant(), self:objectName())
        if not room:askForDiscard(effect.to, self:getSkillName(), 1, 1, true, true, "@ruan_jiao_discard:" .. effect.from:objectName(), "Hourse|.|.|equipped", self:getSKillName()) then
            room:setPlayerFlag(effect.from, "ruan_jiao" .. effect.to:objectName())
        end
    end,
}
sakamichi_ruan_jiao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ruan_jiao",
    view_as = function()
        return sakamichi_ruan_jiaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_ruan_jiaoCard")
    end,
}
sakamichi_ruan_jiao = sgs.CreateTriggerSkill {
    name = "sakamichi_ruan_jiao",
    view_as_skill = sakamichi_ruan_jiao_view_as,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if player:hasFlag("ruan_jiao" .. damage.to:objectName()) then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
MinamiKoike_Keyakizaka:addSkill(sakamichi_ruan_jiao)

sakamichi_qi_e = sgs.CreateTriggerSkill {
    name = "sakamichi_qi_e",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getHandcardNum() < player:getHp() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    if room:askForChoice(p, self:objectName(), "draw=" .. player:objectName() .. "+damage=" .. player:objectName() .. "=" .. SKMC.number_correction(p, 1)) ==
                        "draw=" .. player:objectName() then
                        room:drawCards(player, 1, self:objectName())
                    else
                        room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}

sgs.LoadTranslationTable {
    ["MinamiKoike_Keyakizaka"] = "小池 美波",
    ["&MinamiKoike_Keyakizaka"] = "小池 美波",
    ["#MinamiKoike_Keyakizaka"] = "软池",
    ["~MinamiKoike_Keyakizaka"] = "何か悪いことしましたか？",
    ["designer:MinamiKoike_Keyakizaka"] = "Cassimolar",
    ["cv:MinamiKoike_Keyakizaka"] = "小池 美波",
    ["illustrator:MinamiKoike_Keyakizaka"] = "Cassimolar",
    ["sakamichi_sa_jiao"] = "撒娇",
    [":sakamichi_sa_jiao"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>/当你受到伤害后，你可以令一名其他角色/伤害来源交给你一张指定类型的牌并展示，本回合内你使用与此牌名称相同的牌不能被其他角色响应/你可以弃置此牌来摸一张牌；若其未如此做，本回合内其无法使用或打出手牌/其手牌上限-1。",
    ["@sa_jiao_give_1"] = "请交给%src一张%arg否则本回合内%src与你的距离为1",
    ["@sa_jiao_give_2"] = "请交给%src一张%arg否则本回合内手牌上限-1",
    ["sakamichi_sa_jiao:sa_jiao_discard"] = "是否弃置此牌来摸一张牌",
    ["sakamichi_ruan_jiao"] = "软脚",
    [":sakamichi_ruan_jiao"] = "出牌阶段限一次，你可以令一名其他角色弃置装备区的一张坐骑牌，若其未如此做，本回合内你对其造成伤害后摸一张牌。",
    ["@ruan_jiao_discard"] = "请弃置一张装备区的坐骑牌，否则本回合内%src对你造成伤害时可以摸一张牌",
    ["sakamichi_qi_e"] = "企鹅",
    [":sakamichi_qi_e"] = "每名角色结束阶段，若其手牌数小于其体力值，你可以令其摸一张牌或对其造成1点伤害。",
}

-- 原田 まゆ
MayuHarada = sgs.General(Sakamichi, "MayuHarada", "Keyakizaka46", 4, false)
SKMC.IKiSei.MayuHarada = true
SKMC.SeiMeiHanDan.MayuHarada = {
	name = {10, 5, 4, 3},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {9, "xiong"},
	ji_kaku = {7, "ji"},
	soto_kaku = {13, "da_ji"},
	sou_kaku = {22, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "shui",
		ji_kaku = "jin",
		san_sai = "ji_xiong_hun_he",
	},
}

sakamichi_shi_shengCard = sgs.CreateSkillCard {
    name = "sakamichi_shi_shengCard",
    skill_name = "sakamichi_shi_sheng",
    filter = function(self, targets, to_select)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:deleteLater()
        local _targets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            _targets:append(p)
        end
        return slash:targetFilter(_targets, to_select, sgs.Self)
    end,
    on_validate = function(self, carduse)
        carduse.m_isOwnerUse = false
        local room = carduse.from:getRoom()
        local shi = nil
        for _, p in sgs.qlist(room:getOtherPlayers(carduse.from)) do
            if p:getMark("shi_sheng_" .. p:objectName() .. carduse.from:objectName()) ~= 0 and carduse.from:getMark("shi_sheng_" .. p:objectName() .. carduse.from:objectName()) ~= 0 then
                shi = p
            end
        end
        if shi then
            local slash = room:askForCard(shi, "slash", "@shi_sheng_slash:" .. carduse.from:objectName(), sgs.QVariant(), sgs.Card_MethodResponse, nil, false, "", true)
            if slash then
                return slash
            end
        end
        room:setPlayerFlag(shi, "Global_Shi_Sheng_Failed")
        return nil
    end,
}
sakamichi_shi_sheng_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_shi_sheng",
    view_as = function(self, cards)
        return sakamichi_shi_shengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and not player:hasFlag("Global_Shi_Sheng_Failed")
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "slash") or string.find(pattern, "Slash") and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and
            not player:hasFlag("Global_Shi_Sheng_Failed")
    end,
}
sakamichi_shi_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_sheng",
    view_as_skill = sakamichi_shi_sheng_view_as,
    events = {sgs.GameStart, sgs.CardAsked},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart and player:hasSkill(self:objectName()) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@shi_sheng_choice", false, false)
            room:setPlayerMark(player, "shi_sheng_" .. target:objectName() .. player:objectName(), 1)
            room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. target:getGeneralName(), 1)
        elseif event == sgs.CardAsked then
            local pattern = data:toStringList()[1]
            if (string.find(pattern, "slash") or string.find(pattern, "Slash")) and player:hasSkill(self:objectName()) then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:getMark("shi_sheng_" .. p:objectName() .. player:objectName()) ~= 0 then
                        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@shi_sheng_slash:" .. p:objectName())) then
                            local slash = room:askForCard(p, "slash", "@shi_sheng_slash:" .. player:objectName(), data, sgs.Card_MethodResponse, nil, false, "", true)
                            if slash then
                                room:provide(slash)
                                return true
                            end
                        end
                    end
                end
            elseif pattern == "jink" then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("shi_sheng_" .. player:objectName() .. p:objectName()) ~= 0 then
                        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@shi_sheng_jink:" .. p:objectName())) then
                            local jink = room:askForCard(p, "jink", "@shi_sheng_jink:" .. player:objectName(), data, sgs.Card_MethodResponse, nil, false, "", true)
                            if jink then
                                room:provide(jink)
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MayuHarada:addSkill(sakamichi_shi_sheng)

sakamichi_bu_ya = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_ya",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if (player:getMark("shi_sheng_" .. p:objectName() .. player:objectName()) ~= 0 and player:hasSkill(self:objectName())) or
                    (p:getMark("shi_sheng_" .. player:objectName() .. p:objectName()) ~= 0 and p:hasSkill(self:objectName())) then
                    p:throwAllHandCardsAndEquips()
                    p:turnOver()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MayuHarada:addSkill(sakamichi_bu_ya)

sgs.LoadTranslationTable {
    ["MayuHarada"] = "原田 まゆ",
    ["&MayuHarada"] = "原田 まゆ",
    ["#MayuHarada"] = "不老不死",
    ["~MayuHarada"] = "",
    ["designer:MayuHarada"] = "Cassimolar",
    ["cv:MayuHarada"] = "原田 まゆ",
    ["illustrator:MayuHarada"] = "Cassimolar",
    ["sakamichi_shi_sheng"] = "师生",
    [":sakamichi_shi_sheng"] = "游戏开始时，你须选择一名其他角色成为你的老师；本局游戏内，你需要使用或打出【杀】时，其可以打出一张【杀】视为由你使用或打出；其需要使用或打出【闪】时，你可以打出一张【闪】视为其使用或打出。",
    ["@shi_sheng_choice"] = "请选择一名其他角色成为你的老师",
    ["sakamichi_shi_sheng:@shi_sheng_slash"] = "是否令%src为你提供一张【杀】",
    ["@shi_sheng_slash"] = "请打出一张【杀】视为由%src使用或打出",
    ["sakamichi_shi_sheng:@shi_sheng_jink"] = "是否令%src为你提供一张【闪】",
    ["@shi_sheng_jink"] = "请打出一张【闪】视为由%src使用或打出",
    ["sakamichi_bu_ya"] = "不雅",
    [":sakamichi_bu_ya"] = "锁定技，你或你的老师死亡时，另一名角色须弃置所有牌并翻面。",
}

-- 齋藤 冬優花
FuyukaSaito_Keyakizaka = sgs.General(Sakamichi, "FuyukaSaito_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.FuyukaSaito = true
SKMC.SeiMeiHanDan.FuyukaSaito = {
	name = {17, 18, 5, 17, 7},
	ten_kaku = {35, "ji"},
	jin_kaku = {23, "ji"},
	ji_kaku = {29, "te_shu_ge"},
	soto_kaku = {41, "ji"},
	sou_kaku = {64, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "huo",
		ji_kaku = "shui",
		san_sai = "xiong",
	},
}

sakamichi_tuan_ai = sgs.CreateTriggerSkill {
    name = "sakamichi_tuan_ai",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if player:getKingdom() == "Keyakizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
        if player:hasSkill(self:objectName()) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == "Keyakizaka46" then
                    targets:append(p)
                end
            end
            if targets:length() ~= 0 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@tuanai_invoke", true, false)
                if target then
                    room:drawCards(target, 1, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
FuyukaSaito_Keyakizaka:addSkill(sakamichi_tuan_ai)

sakamichi_jia_zhang = sgs.CreateTriggerSkill {
    name = "sakamichi_jia_zhang",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") and not use.card:isKindOf("SkillCard") then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isWounded() then
                    targets:append(p)
                end
            end
            if targets:length() ~= 0 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jia_zhang_invoke", true, false)
                if target then
                    for _, p in sgs.qlist(use.to) do
                        use.to:removeOne(p)
                    end
                    use.to:append(target)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}
FuyukaSaito_Keyakizaka:addSkill(sakamichi_jia_zhang)

sgs.LoadTranslationTable {
    ["FuyukaSaito_Keyakizaka"] = "齋藤 冬優花",
    ["&FuyukaSaito_Keyakizaka"] = "齋藤 冬優花",
    ["#FuyukaSaito_Keyakizaka"] = "裏隊長",
    ["~FuyukaSaito_Keyakizaka"] = "この腹が見えねえだ！",
    ["designer:FuyukaSaito_Keyakizaka"] = "Cassimolar",
    ["cv:FuyukaSaito_Keyakizaka"] = "齋藤 冬優花",
    ["illustrator:FuyukaSaito_Keyakizaka"] = "Cassimolar",
    ["sakamichi_tuan_ai"] = "团爱",
    [":sakamichi_tuan_ai"] = "其他欅坂46势力的角色回复体力时，你可以摸一张牌；你回复体力时，你可以令一名其他欅坂46势力的角色摸一张牌。",
    ["@tuanai_invoke"] = "你可以令一名其他“欅坂46”势力的角色摸一张牌",
    ["sakamichi_jia_zhang"] = "家长",
    [":sakamichi_jia_zhang"] = "当你使用【桃】时，你可以选择一名其他角色，令其成为此【桃】的目标。",
    ["@jia_zhang_invoke"] = "你可以选择一名受伤的其他角色令其成为此【桃】的目标",
}

-- 尾関 梨香
RikaOzeki_Keyakizaka = sgs.General(Sakamichi, "RikaOzeki_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.RikaOzeki_Keyakizaka = true
SKMC.SeiMeiHanDan.RikaOzeki_Keyakizaka = {
	name = {7, 14, 11, 9},
	ten_kaku = {21, "ji"},
	jin_kaku = {25, "ji"},
	ji_kaku = {20, "xiong"},
	soto_kaku = {16, "da_ji"},
	sou_kaku = {41, "ji"},
	GoGyouSanSai = {
		ten_kaku = "mu",
		jin_kaku = "tu",
		ji_kaku = "shui",
		san_sai = "xiong",
	},
}

sakamichi_qi_xing = sgs.CreateFilterSkill {
    name = "sakamichi_qi_xing",
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, to_select)
        return string.find(to_select:objectName(), "slash") or to_select:objectName() == "jink"
    end,
    view_as = function(self, card)
        local cd
        if string.find(card:objectName(), "slash") then
            cd = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
            cd:setSkillName(self:objectName())
        else
            cd = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
            cd:setSkillName(self:objectName())
        end
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(cd)
        return new
    end,
}
RikaOzeki_Keyakizaka:addSkill(sakamichi_qi_xing)

sakamichi_shi_jiang = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_jiang",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") then
            if not use.card:isVirtualCard() then
                if use.card:objectName() ~= sgs.Sanguosha:getCard(use.card:getEffectiveId()):objectName() then
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("@shi_jiang_invoke:" .. player:objectName())) then
                            room:drawCards(player, 1, self:objectName())
                        end
                    end
                end
            else
                if use.card:subcardsLength() > 0 then
                    local can_trigger = false
                    for _, id in sgs.qlist(use.card:getSubcards()) do
                        if use.card:objectName() ~= sgs.Sanguosha:getCard(id):objectName() then
                            can_trigger = true
                            break
                        end
                    end
                    if can_trigger then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("@shi_jiang_invoke:" .. player:objectName())) then
                                room:drawCards(player, 1, self:objectName())
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RikaOzeki_Keyakizaka:addSkill(sakamichi_shi_jiang)

sgs.LoadTranslationTable {
    ["RikaOzeki_Keyakizaka"] = "尾関 梨香",
    ["&RikaOzeki_Keyakizaka"] = "尾関 梨香",
    ["#RikaOzeki_Keyakizaka"] = "臥薪嘗膽",
    ["~RikaOzeki_Keyakizaka"] = "バッチグーです",
    ["designer:RikaOzeki_Keyakizaka"] = "Cassimolar",
    ["cv:RikaOzeki_Keyakizaka"] = "尾関 梨香",
    ["illustrator:RikaOzeki_Keyakizaka"] = "Cassimolar",
    ["sakamichi_qi_xing"] = "奇行",
    [":sakamichi_qi_xing"] = "锁定技，你的【杀】始终视为【闪】，你的【闪】始终视为【杀】。",
    ["sakamichi_shi_jiang"] = "师匠",
    [":sakamichi_shi_jiang"] = "当一名角色使用牌结算完成时，若此牌有对应实体牌，且对应实体牌中有与此牌牌名不同的牌，你可以令其摸一张牌。",
    ["sakamichi_shi_jiang:@shi_jiang_invoke"] = "是否发动【师匠】令%src摸一张牌",
}

-- 渡邉 理佐
RisaWatanabe_Keyakizaka = sgs.General(Sakamichi, "RisaWatanabe_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.RisaWatanabe_Keyakizaka = true
SKMC.SeiMeiHanDan.RisaWatanabe_Keyakizaka = {
	name = {12, 17, 11, 7},
	ten_kaku = {29, "te_shu_ge"},
	jin_kaku = {28, "xiong"},
	ji_kaku = {18, "ji"},
	soto_kaku = {19, "xiong"},
	sou_kaku = {47, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "shui",
		jin_kaku = "jin",
		ji_kaku = "jin",
		san_sai = "ji",
	},
}

sakamichi_hu_boCard = sgs.CreateSkillCard {
    name = "sakamichi_hu_boCard",
    skill_name = "sakamichi_hu_bo",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():first()), "hu_bo")
        room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(self:getSubcards():first()), source, source))
    end,
}
sakamichi_hu_bo_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_hu_bo",
    filter_pattern = "Slash",
    view_as = function(self, card)
        local cd = sakamichi_hu_boCard:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_hu_boCard")
    end,
}
sakamichi_hu_bo = sgs.CreateTriggerSkill {
    name = "sakamichi_hu_bo",
    view_as_skill = sakamichi_hu_bo_view_as,
    events = {sgs.Damage, sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("hu_bo") then
                room:setCardFlag(damage.card, "hu_bo_damage")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("hu_bo") and not use.card:isKindOf("SkillCard") then
                room:setCardFlag(use.card, "-hu_bo")
                if use.card:hasFlag("hu_bo_damage") then
                    room:setPlayerFlag(use.from, "hu_bo_damage")
                    room:setCardFlag(use.card, "-hu_bo_damage")
                else
                    room:drawCards(use.from, 3, self:objectName())
                    room:setPlayerFlag(use.from, "hu_bo_not_damage")
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard and player:hasFlag("hu_bo_not_damage") then
                player:skip(sgs.Player_Discard)
            end
        end
        return false
    end,
}
sakamichi_hu_bo_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_hu_bo_target_mod",
    pattern = ".",
    residue_func = function(self, player)
        if player:hasSkill("sakamichi_hu_bo") and player:hasFlag("hu_bo_damage") then
            return 1000
        end
    end,
    distance_limit_func = function(self, player)
        if player:hasSkill("sakamichi_hu_bo") and player:hasFlag("hu_bo_damage") then
            return 1000
        else
            return 0
        end
    end,
}
RisaWatanabe_Keyakizaka:addSkill(sakamichi_hu_bo)
if not sgs.Sanguosha:getSkill("#sakamichi_hu_bo_target_mod") then SKMC.SkillList:append(sakamichi_hu_bo_target_mod) end

sakamichi_ao_jiao = sgs.CreateTriggerSkill {
    name = "sakamichi_ao_jiao",
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            local jink = room:askForCard(player, "Jink", "@ao_jiao_discard", sgs.QVariant(), self:objectName())
            if jink then
                room:recover(player, sgs.RecoverStruct(player, jink, SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
RisaWatanabe_Keyakizaka:addSkill(sakamichi_ao_jiao)

sakamichi_shi_nue = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_nue",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
            if damage.to:isNude() or not room:askForDiscard(damage.to, self:objectName(), 1, 1, true, true, "@shi_nue_discard:" .. player:objectName()) then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
RisaWatanabe_Keyakizaka:addSkill(sakamichi_shi_nue)

sgs.LoadTranslationTable {
    ["RisaWatanabe_Keyakizaka"] = "渡邉 理佐",
    ["&RisaWatanabe_Keyakizaka"] = "渡邉 理佐",
    ["#RisaWatanabe_Keyakizaka"] = "不良蛙",
    ["~RisaWatanabe_Keyakizaka"] = "こぼしてんじゃねーよ！",
    ["designer:RisaWatanabe_Keyakizaka"] = "Cassimolar",
    ["cv:RisaWatanabe_Keyakizaka"] = "渡邉 理佐",
    ["illustrator:RisaWatanabe_Keyakizaka"] = "Cassimolar",
    ["sakamichi_hu_bo"] = "互搏",
    [":sakamichi_hu_bo"] = "出牌阶段限一次，你可以弃置一张【杀】视为对自己使用，若此【杀】：造成伤害，本回合内你使用牌无次数和距离限制；未造成伤害，你摸三张牌且跳过此回合的弃牌阶段。",
    ["sakamichi_ao_jiao"] = "傲娇",
    [":sakamichi_ao_jiao"] = "当你受到【杀】造成的伤害后，你可以弃置一张【闪】来回复1点体力。",
    ["@ao_jiao_discard"] = "你可以弃置一张【闪】来回复1点体力",
    ["sakamichi_shi_nue"] = "施虐",
    [":sakamichi_shi_nue"] = "当你使用【杀】造成伤害后，你可以令目标选择弃置一张牌或令你摸一张牌。",
    ["@shi_nue_discard"] = "请弃置一张牌否则%src将摸一张牌",
}

-- 守屋 茜
AkaneMoriya_Keyakiza = sgs.General(Sakamichi, "AkaneMoriya_Keyakiza", "Keyakizaka46", 4, false)
SKMC.IKiSei.AkaneMoriya_Keyakiza = true
SKMC.SeiMeiHanDan.AkaneMoriya_Keyakiza = {
	name = {6, 9, 9},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {18, "ji"},
	ji_kaku = {9, "xiong"},
	soto_kaku = {15, "da_ji"},
	sou_kaku = {24, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "jin",
		ji_kaku = "shui",
		san_sai = "ji",
	},
}

sakamichi_yan_li = sgs.CreateTriggerSkill {
    name = "sakamichi_yan_li",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseEnd, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, "yan_li_") and p:getMark(mark) ~= 0 then
                            for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                                if mark == "yan_li_" .. p:objectName() .. pl:objectName() .. "_start_start_clear" and
                                    not player:hasFlag("yan_li_damage_" .. pl:objectName()) then
                                    room:drawCards(p, 1, self:objectName())
                                    room:askForUseSlashTo(p, pl, "@yan_li_slash:" .. pl:objectName(), false)
                                end
                            end
                        end
                    end
                end
                if player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@yan_li_choice", true, false)
                    if target then
                        room:setPlayerMark(player, "yan_li_" .. player:objectName() .. target:objectName() .. "_start_start_clear", 1)
                        room:setPlayerMark(player, "&" .. self:objectName() .. target:getGeneralName() .. "_start_start_clear", 1)
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if player:objectName() == room:getCurrent():objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if mark == "yan_li_" .. p:objectName() .. damage.to:objectName() .. "_start_start_clear" and
                            not player:hasFlag("yan_li_damage_" .. damage.to:objectName()) then
                            room:setPlayerFlag(player, "yan_li_damage_" .. damage.to:objectName())
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
AkaneMoriya_Keyakiza:addSkill(sakamichi_yan_li)

sakamichi_bu_fu = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_fu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PindianVerifying, sgs.Damaged, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if pindian.from:hasSkill(self:objectName()) then
                pindian.from_number = 13
            end
            if pindian.to:hasSkill(self:objectName()) then
                pindian.to_number = 13
            end
        else
            local damage = data:toDamage()
            local target
            if event == sgs.Damage then
                target = damage.to
            else
                target = damage.from
            end
            if target and target:isALive() and player:canPindian(damage.from) then
                if player:pindianInt(target, self:objectName(), nil) == 1 then
                    if not target:isNude() then
                        local card_id = room:askForCardChosen(player, target, "he", self:objectName())
                        room:obtainCard(player, card_id, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
                    end
                end
            end
        end
        return false
    end,
}
AkaneMoriya_Keyakiza:addSkill(sakamichi_bu_fu)

sgs.LoadTranslationTable {
    ["AkaneMoriya_Keyakiza"] = "守屋 茜",
    ["&AkaneMoriya_Keyakiza"] = "守屋 茜",
    ["#AkaneMoriya_Keyakiza"] = "軍曹",
    ["~AkaneMoriya_Keyakiza"] = "絶対負けません",
    ["designer:AkaneMoriya_Keyakiza"] = "Cassimolar",
    ["cv:AkaneMoriya_Keyakiza"] = "守屋 茜",
    ["illustrator:AkaneMoriya_Keyakiza"] = "Cassimolar",
    ["sakamichi_yan_li"] = "严厉",
    [":sakamichi_yan_li"] = "结束阶段，你可以选择一名其他角色，直到你的下个准备阶段，若其他角色的未于其回合内对该角色造成伤害，你摸一张牌并可以对该角色使用一张【杀】。",
    ["@yan_li_choice"] = "你可以选择一名其他角色发动【严厉】",
    ["@yan_li_slash"] = "你可以对%src使用一张【杀】",
    ["@yan_li"] = "严厉",
    ["sakamichi_bu_fu"] = "不服",
    [":sakamichi_bu_fu"] = "锁定技，你的拼点牌点数始终为K。当你受到其他角色造成的伤害后/对其他角色造成伤害后，你可以与其拼点，若你赢，你可以获得其一张牌。",
}

-- 織田 奈那
NanaOda = sgs.General(Sakamichi, "NanaOda", "Keyakizaka46", 4, false)
SKMC.IKiSei.NanaOda = true
SKMC.SeiMeiHanDan.NanaOda = {
	name = {18, 5, 8, 7},
	ten_kaku = {23, "ji"},
	jin_kaku = {13, "da_ji"},
	ji_kaku = {15, "da_ji"},
	soto_kaku = {25, "ji"},
	sou_kaku = {38, "ji"},
	GoGyouSanSai = {
		ten_kaku = "huo",
		jin_kaku = "huo",
		ji_kaku = "tu",
		san_sai = "ji",
	},
}

sakamichi_he_san = sgs.CreateTriggerSkill {
    name = "sakamichi_he_san",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() then
            room:drawCards(damage.from, 1, self:objectName())
            room:drawCards(player, 1, self:objectName())
            if damage.from:getHandcardNum() > damage.from:getHp() then
                room:askForUseCard(damage.from, "slash", "@askforslash")
            end
        end
    end,
}
NanaOda:addSkill(sakamichi_he_san)

sakamichi_guan_chaCard = sgs.CreateSkillCard {
    name = "sakamichi_guan_chaCard",
    skill_name = "sakamichi_guan_cha",
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:isMale() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:showAllCards(effect.to, effect.from)
        if room:askForSkillInvoke(effect.to, self:getSKillName(), sgs.QVariant("@guan_cha_invoke:" .. effect.from:objectName())) then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:deleteLater()
            slash:setSkillName(self:getSkillName())
            room:setPlayerFlag(effect.from, "guan_cha")
            room:useCard(sgs.CardUseStruct(slash, effect.to, effect.from))
            if not effect.from:hasFlag("guan_cha") then
                room:drawCards(effect.from, 1, self:getSkillName())
            else
                if not effect.to:isKongcheng() then
                    room:setPlayerFlag(effect.from, "-guan_cha")
                    local card_id = room:askForCardChosen(effect.from, effect.to, "he", self:getSkillName(), false, sgs.Card_MethodNone, sgs.IntList(), true)
                    room:obtainCard(effect.from, card_id, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
                end
            end
        end
    end,
}
sakamichi_guan_cha_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_guan_cha",
    view_as = function(self)
        return sakamichi_guan_chaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_guan_chaCard")
    end,
}
sakamichi_guan_cha = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_cha",
    view_as_skill = sakamichi_guan_cha_view_as,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:hasFlag("guan_cha") then
                room:setPlayerFlag("-guan_cha")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanaOda:addSkill(sakamichi_guan_cha)

sgs.LoadTranslationTable {
    ["NanaOda"] = "織田 奈那",
    ["&NanaOda"] = "織田 奈那",
    ["#NanaOda"] = "魔王",
    ["~NanaOda"] = "女として見てないじゃん！",
    ["designer:NanaOda"] = "Cassimolar",
    ["cv:NanaOda"] = "織田 奈那",
    ["illustrator:NanaOda"] = "Cassimolar",
    ["sakamichi_he_san"] = "和善",
    [":sakamichi_he_san"] = "锁定技，当你受到伤害后，你可以令伤害来源和你各摸一张牌，然后若其手牌数大于体力值，其可以使用一张【杀】。",
    ["sakamichi_guan_cha"] = "观察",
    [":sakamichi_guan_cha"] = "出牌阶段限一次，你可以观看一名女性角色的手牌，若如此做，其可以视为对你使用一张【杀】，若此【杀】：对你造成伤害，你摸一张牌；未对你造成伤害，你可以获得其一张牌。",
    ["sakamichi_guan_cha:@guan_cha_invoke"] = "你可以视为对%src使用一张【杀】",
}

-- 鈴本 美愉
MiyuSuzumoto = sgs.General(Sakamichi, "MiyuSuzumoto", "Keyakizaka46", 3, false)
SKMC.IKiSei.MiyuSuzumoto = true
SKMC.SeiMeiHanDan.MiyuSuzumoto = {
	name = {13, 5, 9, 12},
	ten_kaku = {18, "ji"},
	jin_kaku = {14, "xiong"},
	ji_kaku = {21, "ji"},
	soto_kaku = {25, "ji"},
	sou_kaku = {39, "te_shu_ge"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "huo",
		ji_kaku = "mu",
		san_sai = "ji",
	},
}

sakamichi_li_ziCard = sgs.CreateSkillCard {
    name = "sakamichi_li_ziCard",
    skill_name = "sakamichi_li_zi",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:isWounded()
    end,
    on_effect = function(self, effect)
        effect.from:loseMark("@li_zi", math.max(effect.from:getLostHp(), SKMC.number_correction(effect.from, 1)))
        effect.from:getRoom():recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
    end,
}
sakamichi_li_zi_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_li_zi",
    view_as = function(self)
        return sakamichi_li_ziCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_li_ziCard") and player:getMark("@li_zi") >= math.max(player:getLostHp(), SKMC.number_correction(player, 1))
    end,
}
sakamichi_li_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_li_zi",
    view_as_skill = sakamichi_li_zi_view_as,
    events = {sgs.CardUsed, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasSkill(self:objectName()) and not use.card:isKindOf("SkillCard") then
                room:addPlayerMark(player, "@li_zi")
            end
        else
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and p:getMark("@li_zi") > math.max(p:getMaxHp(), player:getMaxHp()) then
                        room:removePlayerMark(p, "@li_zi", p:getMark("@li_zi"))
                        if not player:isKongcheng() then
                            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                            dummy:deleteLater()
                            dummy:addSubcards(player:getHandcards())
                            room:moveCardTo(dummy, player, p, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_ROB,
                                            player:objectName(), p:objectName(), self:objectName(), nil))
                            room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp()))
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MiyuSuzumoto:addSkill(sakamichi_li_zi)

sakamichi_chu_niang = sgs.CreateTriggerSkill {
    name = "sakamichi_chu_niang",
    frequency = sgs.Skill_Limited,
    limit_mark = "@chu_niang",
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
                if event == sgs.BeforeCardsMove then
                    if not player:isKongcheng() then
                        local can_trigger = true
                        for _, id in sgs.qlist(player:handCards()) do
                            if not move.card_ids:contains(id) then
                                can_trigger = false
                            end
                        end
                        if can_trigger then
                            if player:getMaxCards() == 0 and player:getPhase() == sgs.Player_Discard and
                                bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_RULEDISCARD then
                                room:setPlayerFlag(player, "chu_niang_zero_max_cards")
                            else
                                room:addPlayerMark(player, self:objectName())
                            end
                        end
                    end
                else
                    if player:getMark(self:objectName()) ~= 0 then
                        player:removeMark(self:objectName())
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if p:getMark("@chu_niang") ~= 0 and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("@chu_niang:" .. player:objectName())) then
                                p:loseMark("@chu_niang")
                                room:drawCards(player, player:getMaxHp(), self:objectName())
                            end
                        end
                    end
                end
            end
        else
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Discard and player:hasFlag("chu_niang_zero_max_cards") then
                room:setPlayerFlag(player, "-chu_niang_zero_max_cards")
                if player:getMark("@chu_niang") ~= 0 and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@chu_niang:" .. player:objectName())) then
                    player:loseMark("@chu_niang")
                    room:drawCards(player, player:getMaxHp(), self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MiyuSuzumoto:addSkill(sakamichi_chu_niang)

sakamichi_yan_yiCard = sgs.CreateSkillCard {
    name = "sakamichi_yan_yiCard",
    skill_name = "sakamichi_yan_yi",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            for _, skill in sgs.qlist(to_select:getVisibleSkillList()) do
                if skill:getFrequency() == sgs.Skill_Limited then
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:loseMark("@yanyi")
        local SkillList = {}
        for _, skill in sgs.qlist(effect.to:getVisibleSkillList()) do
            if skill:getFrequency() == sgs.Skill_Limited then
                table.insert(SkillList, skill:objectName())
            end
        end
        if #SkillList > 0 then
            local skill_name = room:askForChoice(effect.from, self:objectName(), table.concat(SkillList, "+"))
            room:setPlayerMark(effect.to, sgs.Sanguosha:getSkill(skill_name):getLimitMark(), 1)
        end
    end,
}
sakamichi_yan_yi = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_yan_yi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@yanyi",
    view_as = function(self)
        return sakamichi_yan_yiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@yanyi") ~= 0
    end,
}
MiyuSuzumoto:addSkill(sakamichi_yan_yi)

sgs.LoadTranslationTable {
    ["MiyuSuzumoto"] = "鈴本 美愉",
    ["&MiyuSuzumoto"] = "鈴本 美愉",
    ["#MiyuSuzumoto"] = "栗太郎",
    ["~MiyuSuzumoto"] = "おバカは帰りま～す！",
    ["designer:MiyuSuzumoto"] = "Cassimolar",
    ["cv:MiyuSuzumoto"] = "鈴本 美愉",
    ["illustrator:MiyuSuzumoto"] = "Cassimolar",
    ["sakamichi_li_zi"] = "栗子",
    [":sakamichi_li_zi"] = "你使用牌时获得一枚「栗」。其他角色的结束阶段，若你的「栗」数量大于X，你移除所有的「栗」获得其所有手牌，然后令其回复所有体力（X为你与其体力上限的较大值）。出牌阶段限一次，你可以移除Y枚「栗」令一名角色回复1点体力（Y为你已损失的体力值且不小于1）。",
    ["@li_zi"] = "栗子",
    ["sakamichi_chu_niang"] = "厨娘",
    [":sakamichi_chu_niang"] = "限定技，当一名角色失去最后的手牌时，你可以令其将手牌补至体力上限。",
    ["@chu_niang"] = "厨娘",
    ["sakamichi_chu_niang:@chu_niang"] = "你可以令%src将手牌补至体力上限",
    ["sakamichi_yan_yi"] = "颜艺",
    [":sakamichi_yan_yi"] = "限定技，出牌阶段，你可以令一名有限定技的角色的一个限定技视为未发动过。",
}

-- 佐藤 詩織
ShioriSato = sgs.General(Sakamichi, "ShioriSato", "Keyakizaka46", 4, false)
SKMC.IKiSei.ShioriSato = true
SKMC.SeiMeiHanDan.ShioriSato = {
	name = {7, 18, 13, 18},
	ten_kaku = {25, "ji"},
	jin_kaku = {31, "da_ji"},
	ji_kaku = {31, "da_ji"},
	soto_kaku = {25, "ji"},
	sou_kaku = {56, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "mu",
		ji_kaku = "mu",
		san_sai = "ji_xiong_hun_he",
	},
}

sakamichi_hua_lao = sgs.CreateTriggerSkill {
    name = "sakamichi_hua_lao",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and not player:isKongcheng() and
            room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@hua_lao")) then
            room:showAllCards(player)
            local red, black, colorless = 0, 0, 0
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isRed() then
                    red = red + 1
                elseif card:isBlack() then
                    black = black + 1
                elseif card:getColor() == sgs.Card_Colorless then
                    colorless = colorless + 1
                end
            end
            if red > black then
                if red > colorless then
                    room:setPlayerFlag(player, "hua_lao_red")
                elseif red < colorless then
                    room:setPlayerFlag(player, "hua_lao_colorless")
                else
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_colorless")
                end
            elseif black > red then
                if black > colorless then
                    room:setPlayerFlag(player, "hua_lao_black")
                elseif black < colorless then
                    room:setPlayerFlag(player, "hua_lao_colorless")
                else
                    room:setPlayerFlag(player, "hua_lao_black")
                    room:setPlayerFlag(player, "hua_lao_colorless")
                end
            elseif red == black then
                if red > colorless then
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_black")
                elseif red < colorless then
                    room:setPlayerFlag(player, "hua_lao_colorless")
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_black")
                else
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_black")
                    room:setPlayerFlag(player, "hua_lao_colorless")
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and
                ((use.card:isRed() and player:hasFlag("hua_lao_red")) or
                (use.card:isBlack() and player:hasFlag("hua_lao_black")) or
                (use.card:getColor() == sgs.Card_Colorless and player:hasFlag("hua_lao_colorless"))) then
                room:drawCards(player, 1, self:objectName())
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
            end
        end
        return false
    end,
}
ShioriSato:addSkill(sakamichi_hua_lao)

sakamichi_she_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_she_ji",
    events = {sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not player:hasFlag("mei_shu_used") and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@mei_shu:::" .. use.card:objectName())) then
            use.card:setSuit(room:askForSuit(player, self:objectName()))
            room:setPlayerFlag(player, "mei_shu_used")
        end
    end,
}
ShioriSato:addSkill(sakamichi_she_ji)

sgs.LoadTranslationTable {
    ["ShioriSato"] = "佐藤 詩織",
    ["&ShioriSato"] = "佐藤 詩織",
    ["#ShioriSato"] = "美术担当",
    ["~ShioriSato"] = "花ことば あの人想い 花選ぶ…",
    ["designer:ShioriSato"] = "Cassimolar",
    ["cv:ShioriSato"] = "佐藤 詩織",
    ["illustrator:ShioriSato"] = "Cassimolar",
    ["sakamichi_hua_lao"] = "话痨",
    [":sakamichi_hua_lao"] = "出牌阶段开始时，你可以展示所有手牌，若如此做，本回合内你使用与你展示手牌中相同颜色最多的颜色的牌时不计入使用次数限制且可以摸一张牌。",
    ["sakamichi_hua_lao:@hua_lao"] = "是否发动【话痨】展示所有手牌",
    ["sakamichi_she_ji"] = "设计",
    [":sakamichi_she_ji"] = "出牌阶段限一次，当你使用牌时，你可以改变其花色。",
    ["sakamichi_she_ji:@mei_shu"] = "是否改变此%arg的花色",
}

-- 上村 莉菜
RinaUemura_Keyakizaka = sgs.General(Sakamichi, "RinaUemura_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.RinaUemura_Keyakizaka = true
SKMC.SeiMeiHanDan.RinaUemura_Keyakizaka = {
	name = {3, 7, 10, 11},
	ten_kaku = {10, "xiong"},
	jin_kaku = {17, "ji"},
	ji_kaku = {21, "ji"},
	soto_kaku = {14, "xiong"},
	sou_kaku = {31, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "shui",
		jin_kaku = "jin",
		ji_kaku = "mu",
		san_sai = "ji",
	},
}

sakamichi_yao_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_yao_jing",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local card = nil
        if event == sgs.TargetConfirming or event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card:getColor() == sgs.Card_Colorless then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not p:getEquips():isEmpty() or p:getJudgingArea():length() > 0 then
                    targets:append(p)
                end
            end
            if targets:length() ~= 0 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@yaojing", true, false)
                if target then
                    local id = room:askForCardChosen(player, target, "ej", self:objectName(), false, sgs.Card_MethodNone)
                    room:moveCardsInToDrawpile(player, id, self:objectName(), 1, false)
                end
            end
        end
        return false
    end,
}
RinaUemura_Keyakizaka:addSkill(sakamichi_yao_jing)

sakamichi_xiao_hao = sgs.CreateViewAsSkill {
    name = "sakamichi_xiao_hao",
    n = 2,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:isEquipped()
        elseif #selected == 1 then
            return selected[1]:getColor() ~= to_select:getColor() and to_select:isEquipped()
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
            jink:deleteLater()
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:deleteLater()
            local cd = nil
            if sgs.Self:getPhase() ~= sgs.Player_NotActive then
                cd = slash
            else
                cd = jink
            end
            for _, c in ipairs(cards) do
                cd:addSubcard(c)
            end
            cd:setSkillName(self:objectName())
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return (pattern == "jink" and player:getPhase() == sgs.Player_NotActive) or
            ((string.find(pattern, "slash") or string.find(pattern, "Slash")) and player:getPhase() ~= sgs.Player_NotActive)
    end,
}
RinaUemura_Keyakizaka:addSkill(sakamichi_xiao_hao)

sgs.LoadTranslationTable {
    ["RinaUemura_Keyakizaka"] = "上村 莉菜",
    ["&RinaUemura_Keyakizaka"] = "上村 莉菜",
    ["#RinaUemura_Keyakizaka"] = "千叶妖精",
    ["~RinaUemura_Keyakizaka"] = "だと思うじゃないですか？",
    ["designer:RinaUemura_Keyakizaka"] = "Cassimolar",
    ["cv:RinaUemura_Keyakizaka"] = "上村 莉菜",
    ["illustrator:RinaUemura_Keyakizaka"] = "Cassimolar",
    ["sakamichi_yao_jing"] = "妖精",
    [":sakamichi_yao_jing"] = "当你使用或打出无色卡牌时/成为无色卡牌的目标时，你可以将场上的一张牌置于牌堆顶。",
    ["@yaojing"] = "你可以将场上的一张牌置于牌堆顶",
    ["sakamichi_xiao_hao"] = "小号",
    [":sakamichi_xiao_hao"] = "你的回合内/外，你可以将两张不同颜色的手牌视为【杀】/【闪】使用或打出。",
}

-- 土生 瑞穂
MizuhoHabu_Keyakizaka = sgs.General(Sakamichi, "MizuhoHabu_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.MizuhoHabu = true
SKMC.SeiMeiHanDan.MizuhoHabu = {
	name = {3, 5, 13, 15},
	ten_kaku = {8, "ji"},
	jin_kaku = {18, "ji"},
	ji_kaku = {28, "xiong"},
	soto_kaku = {18, "ji"},
	sou_kaku = {36, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "jin",
		ji_kaku = "jin",
		san_sai = "ji_xiong_hun_he",
	},
}

sakamichi_hou_gong = sgs.CreateTriggerSkill {
    name = "sakamichi_hou_gong",
    events = {sgs.Damage, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if player:hasSkill(self:objectName()) and damage.to:isFemale() and damage.to:objectName() == player:objectName() then
                room:askForUseSlashTo(damage.to, player, "@hou_gong_slash:" .. player:objectName(), false)
            end
        else
            if player:isFemale() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:objectName() ~= p:objectName() then
                        room:drawCards(p, 1, self:objectName())
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MizuhoHabu_Keyakizaka:addSkill(sakamichi_hou_gong)

sakamichi_jing_kong = sgs.CreateTriggerSkill {
    name = "sakamichi_jing_kong",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isNDTrick() then
                room:addPlayerMark(player, "jing_kong_damage_" .. damage.card:getId(), damage.damage)
            end
        else
            local use = data:toCardUse()
            if use.card:isNDTrick() then
                local count = player:getMark("jing_kong_damage_" .. use.card:getId())
                if count == 0 then
                    room:askForUseCard(player, "slash", "@askforslash")
                else
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:drawCards(player, count, self:objectName())
                    end
                end
            end
        end
        return false
    end,
}
MizuhoHabu_Keyakizaka:addSkill(sakamichi_jing_kong)

sakamichi_ju_ren = sgs.CreateTriggerSkill {
    name = "sakamichi_ju_ren",
    -- frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local can_trigger = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:getHp() > p:getHp() then
                    can_trigger = true
                    break
                end
            end
            if can_trigger and room:askForSkillInvoke(player, self:objectName(), data) then
                room:setPlayerFlag(player, "ju_ren")
                if not room:askForUseCard(player, "slash", "@ju_ren_slash") then
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@ju_ren_damage_invoke:::" .. SKMC.number_correction(player, 1))
                    room:loseHp(player, SKMC.number_correction(player, 1))
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, SKMC.number_correction(player, 1)))
                end
                room:setPlayerFlag(player, "-ju_ren")
            end
        end
        return false
    end,
}
sakamichi_ju_ren_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_ju_ren_target_mod",
    pattern = "Slash",
    extra_target_func = function(self, player)
        if player:hasSkill("sakamichi_ju_ren") then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card)
        if from:hasFlag("ju_ren") then
            return 1000
        else
            return 0
        end
    end,
}
MizuhoHabu_Keyakizaka:addSkill(sakamichi_ju_ren)
if not sgs.Sanguosha:getSkill("#sakamichi_ju_ren_target_mod") then SKMC.SkillList:append(sakamichi_ju_ren_target_mod) end

sgs.LoadTranslationTable {
    ["MizuhoHabu_Keyakizaka"] = "土生 瑞穂",
    ["&MizuhoHabu_Keyakizaka"] = "土生 瑞穂",
    ["#MizuhoHabu_Keyakizaka"] = "神の子",
    ["~MizuhoHabu_Keyakizaka"] = "私もゴボウ！",
    ["designer:MizuhoHabu_Keyakizaka"] = "Cassimolar",
    ["cv:MizuhoHabu_Keyakizaka"] = "土生 瑞穂",
    ["illustrator:MizuhoHabu_Keyakizaka"] = "Cassimolar",
    ["sakamichi_hou_gong"] = "后宫",
    [":sakamichi_hou_gong"] = "锁定技，你对其他女性角色造成伤害后，其可以对你使用一张【杀】；其他女性角色回复体力时，你摸一张牌。",
    ["@hou_gong_slash"] = "你可以对%src使用一张【杀】",
    ["sakamichi_jing_kong"] = "惊恐",
    [":sakamichi_jing_kong"] = "你使用通常锦囊牌结算完成时，若此牌：未造成伤害，你可以使用一张【杀】；造成伤害，你可以摸X张牌（X为此牌造成的伤害量）。",
    ["sakamichi_ju_ren"] = "巨人",
    [":sakamichi_ju_ren"] = "你使用【杀】时无目标上限。准备阶段，若你的体力不为全场最少，你可以使用一张无距离限制的【杀】或失去1点体力对一名其他角色造成1点伤害。",
    ["@ju_ren_slash"] = "你可以使用一张无距离限制的【杀】",
    ["@ju_ren_damage_invoke"] = "你可以选择一名其他角色对其造成%arg点伤害",
}

-- 長沢 菜々香
NanakoNagasawa = sgs.General(Sakamichi, "NanakoNagasawa", "Keyakizaka46", 3, false)
SKMC.IKiSei.NanakoNagasawa = true
SKMC.SeiMeiHanDan.NanakoNagasawa = {
	name = {8, 7, 11, 3, 9},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {18, "ji"},
	ji_kaku = {23, "ji"},
	soto_kaku = {20, "xiong"},
	sou_kaku = {38, "ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "jin",
		ji_kaku = "huo",
		san_sai = "xiong",
	},
}

sakamichi_xiao_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_ji",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if (event == sgs.DamageInflicted and player:getPhase() ~= sgs.Player_NotActive) or (event == sgs.DamageCaused and player:getPhase() == sgs.Player_NotActive) then
            damage.damage = damage.damage - SKMC.number_correction(player, 1)
            data:setValue(damage)
            if damage.damage <= 0 then
                return true
            end
        end
        return false
    end,
}
NanakoNagasawa:addSkill(sakamichi_xiao_ji)

sakamichi_da_wei = sgs.CreateTriggerSkill {
    name = "sakamichi_da_wei",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
        end
        return false
    end,
}
NanakoNagasawa:addSkill(sakamichi_da_wei)

sakamichi_mi_lianCard = sgs.CreateSkillCard {
    name = "sakamichi_mi_lianCard",
    skill_name = "sakamichi_mi_lian",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getHandcardNum() > sgs.Self:getHandcardNum()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@mi_lian")
        local _data = sgs.QVariant()
        _data:setValue(effect.to)
        effect.from:setTag("mi_lian", _data)
        room:setPlayerFlag(effect.from, "mi_lian")
        room:drawCards(effect.from, effect.to:getHandcardNum() - effect.from:getHandcardNum(), self:getSkillName())
        if effect.to:isWounded() then
            room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
        end
    end,
}
sakamichi_mi_lian_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_mi_lian",
    view_as = function(self)
        return sakamichi_mi_lianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@mi_lian") ~= 0
    end,
}
sakamichi_mi_lian = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_lian",
    view_as_skill = sakamichi_mi_lian_view_as,
    frequency = sgs.Skill_Limited,
    limit_mark = "@mi_lian",
    events = {sgs.EnterDying, sgs.Damage, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.damage and dying.damage.from and dying.damage.from:hasFlag("mi_lian") then
                local target = dying.damage.from:getTag("mi_lian"):toPlayer()
                if target and target:isAlive() then
                    if target:getHandcardNum() > dying.damage.from:getHandcardNum() then
                        room:drawCards(dying.damage.from, target:getHandcardNum() - dying.damage.from:getHandcardNum(), self:objectName())
                    end
                    if target:isWounded() then
                        room:recover(target, sgs.RecoverStruct(dying.damage.from, nil, SKMC.number_correction(dying.damage.from, 1)))
                    end
                end
            end
        elseif event == sgs.Damage then
            if player:hasSkill(self:objectName()) and player:hasFlag("mi_lian") then
                room:setPlayerFlag(player, "mi_lian_damage")
            end
        else
            if player:getPhase() == sgs.Player_Finish then
                if player:hasFlag("mi_lian") then
                    if not player:hasFlag("mi_lian_damage") then
                        player:throwAllHandCards()
                        room:loseHp(player, SKMC.number_correction(player, 1))
                    else
                        room:setPlayerFlag(player, "-mi_lian_damage")
                    end
                    room:setPlayerFlag(player, "-mi_lian")
                end
                if player:getTag("mi_lian") then
                    player:removeTag("mi_lian")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanakoNagasawa:addSkill(sakamichi_mi_lian)

sgs.LoadTranslationTable {
    ["NanakoNagasawa"] = "長沢 菜々香",
    ["&NanakoNagasawa"] = "長沢 菜々香",
    ["#NanakoNagasawa"] = "消極偶像",
    ["~NanakoNagasawa"] = "２人だから大丈夫だった",
    ["designer:NanakoNagasawa"] = "Cassimolar",
    ["cv:NanakoNagasawa"] = "長沢 菜々香",
    ["illustrator:NanakoNagasawa"] = "Cassimolar",
    ["sakamichi_xiao_ji"] = "消极",
    [":sakamichi_xiao_ji"] = "锁定技，你的回合内/外，你受到/造成的伤害-1。",
    ["sakamichi_da_wei"] = "大胃",
    [":sakamichi_da_wei"] = "当你使用【桃】时，你可以摸一张牌。",
    ["sakamichi_mi_lian"] = "秘恋",
    [":sakamichi_mi_lian"] = "限定技，出牌阶段，你可以选择一名手牌比你多的角色，你将手牌数补至与其相同，并令其回复1点体力，本回合内，当你令一名角色进入濒死时可以重复此流程，若你本回合未能造成伤害，你须弃置所有手牌并失去1点体力。",
    ["@mi_lian"] = "秘恋",
}

-- 菅井 友香
YukaSugai_Keyakizaka = sgs.General(Sakamichi, "YukaSugai_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.YukaSugai_Keyakizaka = true
SKMC.SeiMeiHanDan.YukaSugai_Keyakizaka = {
	name = {11, 4, 4, 9},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {8, "ji"},
	ji_kaku = {13, "da_ji"},
	soto_kaku = {20, "xiong"},
	sou_kaku = {28, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "jin",
		ji_kaku = "mu",
		san_sai = "xiong",
	},
}

sakamichi_qian_jin = sgs.CreateTriggerSkill {
    name = "sakamichi_qian_jin",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() then
                    local card1 = room:askForExchange(p, self:objectName(), p:distanceTo(player), p:distanceTo(player), true,
                                                        "@qian_jin:" .. player:objectName() .. "::" .. p:distanceTo(player), true)
                    if card1 then
                        room:obtainCard(player, card1, false)
                        local card2 = room:askForExchange(player, self:objectName(), player:distanceTo(p), player:distanceTo(p), true,
                                                            "@qian_jin:" .. p:objectName() .. "::" .. player:distanceTo(p), true)
                        if card2 then
                            room:obtainCard(p, card2, false)
                        else
                            room:setPlayerFlag(player, "qian_jin" .. p:objectName())
                        end
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                local nullified_list = use.nullified_list
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:hasFlag("qian_jin" .. p:objectName()) then
                        table.insert(nullified_list, p:objectName())
                        room:drawCards(p, 1, self:objectName())
                    end
                end
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YukaSugai_Keyakizaka:addSkill(sakamichi_qian_jin)

sakamichi_ma_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_ma_shu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Horse") then
                room:drawCards(player, 1, self:objectName())
            end
        else
            local move = data:toMoveOneTime()
            if move.from and (move.from:objectName() == player:objectName()) and move.from_places:contains(sgs.Player_PlaceEquip) then
                local i = 0
                for _, card_id in sgs.qlist(move.card_ids) do
                    if player:isAlive() and move.from_places:at(i) == sgs.Player_PlaceEquip and sgs.Sanguosha:getCard(card_id):isKindOf("Horse") then
                        room:loseHp(player)
                        i = i + 1
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_ma_shu_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_ma_shu_distance",
    correct_func = function(self, from, to)
        if to:hasSkill("sakamichi_ma_shu") then
            return 1
        end
        if from:hasSkill("sakamichi_ma_shu") then
            return -1
        end
    end,
}
YukaSugai_Keyakizaka:addSkill(sakamichi_ma_shu)
if not sgs.Sanguosha:getSkill("#sakamichi_ma_shu_distance") then SKMC.SkillList:append(sakamichi_ma_shu_distance) end

sgs.LoadTranslationTable {
    ["YukaSugai_Keyakizaka"] = "菅井 友香",
    ["&YukaSugai_Keyakizaka"] = "菅井 友香",
    ["#YukaSugai_Keyakizaka"] = "菅井樣",
    ["~YukaSugai_Keyakizaka"] = "私の腕筋なめんなよ！",
    ["designer:YukaSugai_Keyakizaka"] = "Cassimolar",
    ["cv:YukaSugai_Keyakizaka"] = "菅井 友香",
    ["illustrator:YukaSugai_Keyakizaka"] = "Cassimolar",
    ["sakamichi_qian_jin"] = "千金",
    [":sakamichi_qian_jin"] = "其他角色准备阶段，你可以交给其X张牌然后其需交给你Y张牌，否则本回合内其使用牌对你无效且你可以摸一张牌（X为你与其的距离，Y为其与你的距离）。",
    ["@qian_jin"] = "你可以交给%src%arg张牌",
    ["sakamichi_ma_shu"] = "马术",
    [":sakamichi_ma_shu"] = "锁定技，你计算与其他角色的距离-1，其他角色计算与你的距离+1；你使用坐骑牌时摸一张牌；当你失去装备区的坐骑牌时失去1点体力。",
    ["@mashu_discard"] = "你须弃置一张牌，否则将失去1点体力",
}

-- 渡辺 梨加
RikaWatanabe_Keyakizaka = sgs.General(Sakamichi, "RikaWatanabe_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.RikaWatanabe_Keyakizaka = true
SKMC.SeiMeiHanDan.RikaWatanabe_Keyakizaka = {
	name = {12, 5, 11, 5},
	ten_kaku = {17, "ji"},
	jin_kaku = {16, "da_ji"},
	ji_kaku = {16, "da_ji"},
	soto_kaku = {17, "ji"},
	sou_kaku = {33, "te_shu_ge"},
	GoGyouSanSai = {
		ten_kaku = "jin",
		jin_kaku = "mu",
		ji_kaku = "mu",
		san_sai = "da_ji",
	},
}

sakamichi_pei_yin_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_pei_yin",
    view_as = function()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_nullification = function(self, player)
        local room = sgs.Sanguosha:currentRoom()
        local top_card = sgs.Sanguosha:getCard(room:getDrawPile():first())
        return top_card:isKindOf("Nullification") and top_card:isRed()
    end,
}
sakamichi_pei_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_pei_yin",
    view_as_skill = sakamichi_pei_yin_view_as,
    events = {sgs.CardsMoveOneTime, sgs.BeforeCardsMove, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local pile = room:getDrawPile()
        if pile:isEmpty() then
            room:swapPile()
        end
        local id = pile:first()
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if move.from_places:contains(sgs.Player_DrawPile) or move.to_place == sgs.Player_DrawPile then
                    local players = sgs.SPlayerList()
                    players:append(p)
                    SKMC.fake_move(room, p, "&pei_yin", p:getMark("pei_yin"), false, self:objectName(), players)
                    if sgs.Sanguosha:getCard(p:getMark("pei_yin")):isBlack() then
                        room:removePlayerCardLimitation(player, "use,response", "" .. p:getMark("pei_yin"))
                    end
                    room:setPlayerMark(p, "pei_yin_1st", 0)
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("pei_yin_1st") == 0 then
                    local players = sgs.SPlayerList()
                    players:append(p)
                    SKMC.fake_move(room, p, "&pei_yin", id, true, self:objectName(), players)
                    if sgs.Sanguosha:getCard(id):isBlack() then
                        room:setPlayerCardLimitation(player, "use,response", "" .. id, false)
                    end
                    room:addPlayerMark(p, "pei_yin_1st")
                    room:setPlayerMark(p, "pei_yin", id)
                end
            end
        elseif event == sgs.PreCardUsed then
            if data:toCardUse().card:getId() == player:getMark("pei_yin") and player:hasSkill(self:objectName()) then
                room:broadcastSkillInvoke(self:objectName())
                room:notifySkillInvoked(player, self:objectName())
            end
        end
        return false
    end,
}
RikaWatanabe_Keyakizaka:addSkill(sakamichi_pei_yin)

sakamichi_dai_meng = sgs.CreateTriggerSkill {
    name = "sakamichi_dai_meng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.StartJudge},
    on_trigger = function(self, event, player, data, room)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
        end
        return false
    end,
}
RikaWatanabe_Keyakizaka:addSkill(sakamichi_dai_meng)

sakamichi_jian_wang = sgs.CreateTriggerSkill {
    name = "sakamichi_jian_wang",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if player:getHandcardNum() ~= player:getHp() and room:askForSkillInvoke(player, self:objectName(), data) then
                local card = room:askForCard(player, ".|.|.|hand", "@jian_wang_invoke", data, sgs.Card_MethodNone, nil, false, self:objectName(), false)
                if card then
                    room:moveCardsInToDrawpile(player, card, self:objectName(), 1, false)
                else
                    room:drawCards(player, 1, self:objectName())
                end
                local min, max = true, true
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getHandcardNum() > player:getHandcardNum() then
                        max = false
                    elseif p:getHandcardNum() < player:getHandcardNum() then
                        min = false
                    end
                end
                if min then
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Draw)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                end
                if max then
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Play)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                end
            end
        end
        return false
    end,
}
RikaWatanabe_Keyakizaka:addSkill(sakamichi_jian_wang)

sgs.LoadTranslationTable {
    ["RikaWatanabe_Keyakizaka"] = "渡辺 梨加",
    ["&RikaWatanabe_Keyakizaka"] = "渡辺 梨加",
    ["#RikaWatanabe_Keyakizaka"] = "大齡團寵",
    ["~RikaWatanabe_Keyakizaka"] = "わっしょい！やぁーー！",
    ["designer:RikaWatanabe_Keyakizaka"] = "Cassimolar",
    ["cv:RikaWatanabe_Keyakizaka"] = "渡辺 梨加",
    ["illustrator:RikaWatanabe_Keyakizaka"] = "Cassimolar",
    ["sakamichi_pei_yin"] = "配音",
    [":sakamichi_pei_yin"] = "牌堆顶的牌始终对你可见，若此牌为红色，你可以视为手牌使用或打出。",
    ["&pei_yin"] = "配音",
    ["sakamichi_dai_meng"] = "呆萌",
    [":sakamichi_dai_meng"] = "你的判定开始时，你可以摸一张牌。",
    ["sakamichi_jian_wang"] = "健忘",
    [":sakamichi_jian_wang"] = "结束阶段，若你的手牌数不等于体力值，你可以将一张手牌置于牌堆顶或摸一张牌，然后若你的手牌为：全场最少，你执行一个额外的摸牌阶段；全场最多，你执行一个额外的出牌阶段。",
    ["@jian_wang_invoke"] = "你可以将一张手牌置于牌堆顶，否则摸一张牌",
}

sgs.Sanguosha:addSkills(SKMC.SkillList)

return SKMC.Packages