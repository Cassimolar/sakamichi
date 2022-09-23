require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MihoWatanabe_Hinatazaka = sgs.General(Sakamichi, "MihoWatanabe_Hinatazaka", "Hinatazaka46", 4, false)
table.insert(SKMC.NiKiSei, "MihoWatanabe_Hinatazaka")

--[[
    技能名：天萌
    描述：出牌阶段限一次，你可以选择一项：1.将一张♠牌当【乐不思蜀】使用；2.弃置一张♥手牌，直至你的下一回合开始之前，你受到的伤害-1。
]]
LuaLuanaturalcuteCard = sgs.CreateSkillCard {
    name = "LuanaturalcuteCard",
    skill_name = "Luanaturalcute",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "naturalcute", 1)
        local msg = sgs.LogMessage()
        msg.type = "#naturalcute_mark"
        msg.from = source
        room:sendLog(msg)
    end,
}
LuanaturalcuteVS = sgs.CreateOneCardViewAsSkill {
    name = "Luanaturalcute",
    filter_pattern = ".|heart,spade",
    view_as = function(self, card)
        local cd
        if card:getSuit() == sgs.Card_Spade then
            cd = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())
        else
            cd = LuaLuanaturalcuteCard:clone()
        end
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isNude() and not player:hasUsed("#LuanaturalcuteCard") and not player:hasFlag("naturalcute")
    end,
}
Luanaturalcute = sgs.CreateTriggerSkill {
    name = "Luanaturalcute",
    view_as_skill = LuanaturalcuteVS,
    events = {sgs.DamageInflicted, sgs.EventPhaseStart, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getMark("naturalcute") ~= 0 then
                local msg = sgs.LogMessage()
                msg.type = "#naturalcute"
                msg.from = player
                msg.arg = damage.damage
                damage.damage = damage.damage - 1
                msg.arg2 = damage.damage
                room:sendLog(msg)
                data:setValue(damage)
            end
            if damage.damage < 1 then
                return true
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:getMark("naturalcute") ~= 0 then
                room:setPlayerMark(player, "naturalcute", 0)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Indulgence") and use.card:getSkillName() == self:objectName() then
                room:setPlayerFlag(use.from, "naturalcute")
            end
        end
        return false
    end,
}
MihoWatanabe_Hinatazaka:addSkill(Luanaturalcute)

--[[
    技能名：怀才
    描述：限定技，当你退出濒死状态时，你可以减一点体力上限，获得【绝杀】。
]]
Luatalented = sgs.CreateTriggerSkill {
    name = "Luatalented",
    events = {sgs.QuitDying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@talented",
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:objectName() == player:objectName() and player:getMark("@talented") ~= 0
            and room:askForSkillInvoke(player, self:objectName(), data) then
            player:loseMark("@talented")
            room:loseMaxHp(player)
            room:handleAcquireDetachSkills(player, "Lualore", true)
        end
        return false
    end,
}
MihoWatanabe_Hinatazaka:addSkill(Luatalented)

sgs.LoadTranslationTable {
    ["MihoWatanabe_Hinatazaka"] = "渡邉 美穂",
    ["&MihoWatanabe_Hinatazaka"] = "渡邉 美穂",
    ["#MihoWatanabe_Hinatazaka"] = "天之萌",
    ["designer:MihoWatanabe_Hinatazaka"] = "Cassimolar",
    ["cv:MihoWatanabe_Hinatazaka"] = "渡邉 美穂",
    ["illustrator:MihoWatanabe_Hinatazaka"] = "Cassimolar",
    ["Luanaturalcute"] = "天萌",
    [":Luanaturalcute"] = "出牌阶段限一次，你可以选择一项：1.将一张♠牌当【乐不思蜀】使用；2.弃置一张♥手牌，直至你的下一回合开始之前，你受到的伤害-1。",
    ["#naturalcute_mark"] = "直到%from下一个回合开始前，%from受到伤害时伤害-1。",
    ["#naturalcute"] = "%from 发动了【<font color=\"yellow\"><b>天然</b></font>】，伤害点数从 %arg 点减少至 %arg2 点",
    ["Luatalented"] = "怀才",
    [":Luatalented"] = "限定技，当你退出濒死状态时，你可以减1点体力上限，获得【绝杀】。",
    ["@talented"] = "怀才",
}
