require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ArisaMineyoshi = sgs.General(STU48, "ArisaMineyoshi", "STU48", 3, false)
table.insert(SKMC.IKiSei, "ArisaMineyoshi")

--[[
    技能名：逗比
    描述：当你于回合外使用一张牌时，你可以摸一张牌，若此时你的体力值不大于1，你可以额外摸一张牌。
]]
Luadoubi = sgs.CreateTriggerSkill {
    name = "Luadoubi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_NotActive then
            local card
            if event == sgs.cardused then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and not card:isKindOf("SkillCard") and room:askForSkillInvoke(player, self:objectName(), data) then
                local n
                if player:getHp() <= 1 then
                    n = 2
                else
                    n = 1
                end
                room:drawCards(player, n, self:objectName())
            end
        end
        return false
    end,
}
ArisaMineyoshi:addSkill(Luadoubi)

--[[
    技能名：挑战
    描述：摸牌阶段开始时，你可以跳过摸牌，若如此做，本回合内，你的手牌无上限且造成1点伤害时可以摸一张牌并回复1点体力。
]]
Luatiaozhan = sgs.CreateTriggerSkill {
    name = "Luatiaozhan",
    events = {sgs.EventPhaseChanging, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw)
                and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("tiaozhan_skip")) then
                player:skip(sgs.Player_Draw)
                room:setPlayerFlag(player, "tiaozhan")
                room:addMaxCards(player, 1000, true)
            end
        else
            local damage = data:toDamage()
            if player:hasFlag("tiaozhan") then
                for i = 1, damage.damage do
                    room:drawCards(player, 1, self:objectName())
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(player, nil, 1))
                    end
                end
            end
        end
        return false
    end,
}
ArisaMineyoshi:addSkill(Luatiaozhan)

sgs.LoadTranslationTable {
    ["ArisaMineyoshi"] = "峯吉 愛梨沙",
    ["&ArisaMineyoshi"] = "峯吉 愛梨沙",
    ["#ArisaMineyoshi"] = "永遠の小學生",
    ["designer:ArisaMineyoshi"] = "Cassimolar",
    ["cv:ArisaMineyoshi"] = "峯吉 愛梨沙",
    ["illustrator:ArisaMineyoshi"] = "Cassimolar",
    ["Luadoubi"] = "逗比",
    [":Luadoubi"] = "当你于回合外使用一张牌时，你可以摸一张牌，若此时你的体力值不大于1，你可以额外摸一张牌。",
    ["Luatiaozhan"] = "挑战",
    [":Luatiaozhan"] = "摸牌阶段开始时，你可以跳过摸牌，若如此做，本回合内，你的手牌无上限且造成1点伤害时可以摸一张牌并回复1点体力。",
    ["Luatiaozhan:tiaozhan_skip"] = "你可以发动【挑战】跳过摸牌阶段",
}
