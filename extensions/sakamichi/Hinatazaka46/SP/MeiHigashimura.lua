require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MeiHigashimura_Hinatazaka_sp = sgs.General(Sakamichi, "MeiHigashimura_Hinatazaka_sp", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "MeiHigashimura_Hinatazaka_sp")

--[[
    技能名：五岁
    描述：锁定技，体力值大于你的角色对你使用牌时，其须交给你一张手牌，否则此牌对你无效。
]]
Luawusui = sgs.CreateTriggerSkill {
    name = "Luawusui",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if not use.to:contains(player) or use.card:isKindOf("SkillCard")
                or (use.from and use.from:getHp() <= player:getHp()) then
                return false
            end
            local card = room:askForCard(use.from, ".",
                "@wusui_give:" .. player:objectName() .. "::" .. use.card:objectName(), data, sgs.Card_MethodNone)
            if card then
                player:obtainCard(card)
            else
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
}
MeiHigashimura_Hinatazaka_sp:addSkill(Luawusui)

--[[
    技能名：变猫
    描述：你的回合内你使用【杀】无距离限制且无视防具；你的回合外当你受到伤害时可以弃置一张【闪】防止此伤害。
]]
Luabianmao = sgs.CreateTriggerSkill {
    name = "Luabianmao",
    events = {sgs.CardUsed, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed and player:getPhase() ~= sgs.Player_NotActive then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                room:setCardFlag(use.card, "SlashIgnoreArmor")
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getPhase() == sgs.Player_NotActive then
                local card = room:askForCard(player, "Jink", "@bianmao_invoke", data, sgs.Card_MethodDiscard, nil,
                    false, self:objectName(), false)
                if card then
                    room:setEmotion(damage.to, "skill_nullify")
                    return true
                end
            end
        end
        return false
    end,
}
LuabianmaoMod = sgs.CreateTargetModSkill {
    name = "#LuabianmaoMod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card)
        if from:hasSkill("Luabianmao") and from:getPhase() ~= sgs.Player_NotActive then
            return 1000
        else
            return 0
        end
    end,
}
MeiHigashimura_Hinatazaka_sp:addSkill(Luabianmao)
if not sgs.Sanguosha:getSkill("#LuabianmaoMod") then
    SKMC.SkillList:append(LuabianmaoMod)
end

sgs.LoadTranslationTable {
    ["MeiHigashimura_Hinatazaka_sp"] = "東村 芽依",
    ["&MeiHigashimura_Hinatazaka_sp"] = "SP 東村 芽依",
    ["#MeiHigashimura_Hinatazaka_sp"] = "五歲貓咪",
    ["designer:MeiHigashimura_Hinatazaka_sp"] = "Cassimolar",
    ["cv:MeiHigashimura_Hinatazaka_sp"] = "東村 芽依",
    ["illustrator:MeiHigashimura_Hinatazaka_sp"] = "Cassimolar",
    ["Luawusui"] = "五岁",
    [":Luawusui"] = "锁定技，体力值大于你的角色对你使用牌时，其须交给你一张手牌，否则此牌对你无效。",
    ["@wusui_give"] = "请交给%src 一张手牌否则此 %arg 对其无效",
    ["Luabianmao"] = "变猫",
    [":Luabianmao"] = "你的回合内你使用【杀】无距离限制且无视防具；你的回合外当你受到伤害时可以弃置一张【闪】防止此伤害。",
    ["@bianmao_invoke"] = "你可以弃置一张【闪】来防止此伤害",
}
