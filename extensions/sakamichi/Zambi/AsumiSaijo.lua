require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AsumiSaijo = sgs.General(Zambi, "AsumiSaijo", "Zambi", 3, false)
table.insert(SKMC.IKiSei, "AsumiSaijo")

--[[
    技能名：好奇
    描述：当你的判定牌生效后，你可以摸一张牌。
]]
Luakoukishin = sgs.CreateTriggerSkill {
    name = "Luakoukishin",
    events = {sgs.FinishJudge},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
        end
        return false
    end,
}
AsumiSaijo:addSkill(Luakoukishin)

--[[
    技能名：社交
    描述：出牌阶段限一次，你可以令一名不处于连环状态的其他角色摸两张牌并横置其武将牌，若如此做，视为你对其使用一张【杀】。
]]
LuashakouCard = sgs.CreateSkillCard {
    name = "LuashakouCard",
    skill_name = "Luashakou",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
                   and not to_select:isChained()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:drawCards(effect.to, 2, "Luashakou")
        room:setPlayerChained(effect.to)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName("Luashakou")
        room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to))
    end,
}
Luashakou = sgs.CreateZeroCardViewAsSkill {
    name = "Luashakou",
    view_as = function()
        return LuashakouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}
AsumiSaijo:addSkill(Luashakou)

--[[
    技能名：风车
    描述：锁定技，回合开始时，你进行一次判定，若结果为♠，你失去1点体力且本回合内你造成的伤害均视为雷电属性伤害。
]]
Luakazaguruma = sgs.CreateTriggerSkill {
    name = "Luakazaguruma",
    events = {sgs.EventPhaseStart, sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local judge = sgs.JudgeStruct()
            judge.pattern = ".|spade"
            judge.good = false
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            if judge:isBad() then
                room:loseHp(player)
                room:setPlayerFlag(player, "kazaguruma")
            end
        else
            local damage = data:toDamage()
            if damage.nature ~= sgs.DamageStruct_Thunder and player:hasFlag("kazaguruma") then
                damage.nature = sgs.DamageStruct_Thunder
                data:setValue(damage)
            end
        end
        return false
    end,
}
AsumiSaijo:addSkill(Luakazaguruma)

sgs.LoadTranslationTable {
    ["AsumiSaijo"] = "西条 亜須未",
    ["&AsumiSaijo"] = "西条 亜須未",
    ["#AsumiSaijo"] = "いつもと違う様子",
    ["designer:AsumiSaijo"] = "Cassimolar",
    ["cv:AsumiSaijo"] = "秋元 真夏",
    ["illustrator:AsumiSaijo"] = "Cassimolar",
    ["Luakoukishin"] = "好奇",
    [":Luakoukishin"] = "当你的判定牌生效后，你可以摸一张牌。",
    ["Luashakou"] = "社交",
    [":Luashakou"] = "出牌阶段限一次，你可以令一名不处于连环状态的其他角色摸两张牌并横置其武将牌，若如此做，视为你对其使用一张【杀】。",
    ["Luakazaguruma"] = "风车",
    [":Luakazaguruma"] = "锁定技，回合开始时，你进行一次判定，若结果为♠，你失去1点体力且本回合内你造成的伤害均视为雷电属性伤害。",
}
