require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MinoriMorozumi = sgs.General(Zambi, "MinoriMorozumi", "Zambi", 4, false)
table.insert(SKMC.NiKiSei, "MinoriMorozumi")

--[[
    技能名：级长
    描述：其他角色回合开始时，若你的武将牌正面朝上且在其攻击范围内，你可以将武将牌翻面，然后你和其各摸一张牌，若如此做，其本回合内使用牌不能指定除你以外的角色为目标。
]]
Luagakkiyuuiinchou = sgs.CreateTriggerSkill {
    name = "Luagakkiyuuiinchou",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local source = room:findPlayerBySkillName(self:objectName())
            if source and source:objectName() ~= player:objectName() then
                if source:faceUp() and player:inMyAttackRange(source) then
                    if source:askForSkillInvoke(self:objectName()) then
                        source:turnOver()
                        room:drawCards(source, 1, self:objectName())
                        room:drawCards(player, 1, self:objectName())
                        room:setPlayerFlag(source, "gakkiyuuiinchou_to")
                        room:setPlayerFlag(player, "gakkiyuuiinchou_from")
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
LuagakkiyuuiinchouProhibit = sgs.CreateProhibitSkill {
    name = "LuagakkiyuuiinchouProhibit",
    is_prohibited = function(self, from, to, card)
        if not card:isKindOf("SkillCard") and from:hasFlag("gakkiyuuiinchou_from") then
            return not to:hasFlag("gakkiyuuiinchou_to")
        end
        return false
    end,
}
MinoriMorozumi:addSkill(Luagakkiyuuiinchou)
if not sgs.Sanguosha:getSkill("LuagakkiyuuiinchouProhibit") then
    SKMC.SkillList:append(LuagakkiyuuiinchouProhibit)
end

--[[
    技能名：血战
    描述：当你使用或打出牌时，若你的武将牌背面朝上，你可以将武将牌翻至正面。
]]
Luachinamagusaitatakai = sgs.CreateTriggerSkill {
    name = "Luachinamagusaitatakai",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and not card:isKindOf("SkillCard") and not player:faceUp()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            player:turnOver()
        end
    end,
}
MinoriMorozumi:addSkill(Luachinamagusaitatakai)

--[[
    技能名：自尽
    描述：限定技，当你进入濒死时，你可以将体力值回复至1点，然后选择一名其他角色令其回复1点体力并摸3张牌，你的下个回合结束时，你死亡。
]]
Luajisatsu = sgs.CreateTriggerSkill {
    name = "Luajisatsu",
    events = {sgs.EnterDying, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Limited,
    limit_mark = "@inochi",
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and player:getMark("@inochi") ~= 0
                and room:askForSkillInvoke(player, self:objectName(), data) then
                player:loseMark("@inochi")
                room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@jisatsu_choice", false, true)
                if target then
                    room:recover(target, sgs.RecoverStruct(player, nil, 1))
                    room:drawCards(target, 3, self:objectName())
                end
                room:setPlayerMark(player, "jisatsu", 1)
            end
        elseif player:getPhase() == sgs.Player_Finish and player:getMark("jisatsu") ~= 0 then
            room:killPlayer(player)
        end
        return false
    end,
}
MinoriMorozumi:addSkill(Luajisatsu)

sgs.LoadTranslationTable {
    ["MinoriMorozumi"] = "諸積 実乃梨",
    ["&MinoriMorozumi"] = "諸積 実乃梨",
    ["#MinoriMorozumi"] = "舞いの名",
    ["designer:MinoriMorozumi"] = "Cassimolar",
    ["cv:MinoriMorozumi"] = "堀 未央奈",
    ["illustrator:MinoriMorozumi"] = "Cassimolar",
    ["Luagakkiyuuiinchou"] = "级长",
    [":Luagakkiyuuiinchou"] = "其他角色回合开始时，若你的武将牌正面朝上且在其攻击范围内，你可以将武将牌翻面，然后你和其各摸一张牌，若如此做，其本回合内使用牌不能指定除你以外的角色为目标。",
    ["Luachinamagusaitatakai"] = "血战",
    [":Luachinamagusaitatakai"] = "当你使用或打出牌时，若你的武将牌背面朝上，你可以将武将牌翻至正面。",
    ["Luajisatsu"] = "自尽",
    [":Luajisatsu"] = "限定技，当你进入濒死时，你可以将体力值回复至1点，然后选择一名其他角色令其回复1点体力并摸3张牌，你的下个回合结束时，你死亡。",
    ["@inochi"] = "命",
    ["@jisatsu_choice"] = "请选择一名其他角色令其回复1点体力值并摸三张牌",
}
