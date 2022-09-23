require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MarieMorimoto = sgs.General(Sakamichi, "MarieMorimoto", "Hinatazaka46", 3, false, true)
table.insert(SKMC.SanKiSei, "MarieMorimoto")

--[[
    技能名：吵闹
    描述：回合结束时，你可以选择一个势力，直到你的下个回合开始前，此势力的角色体力值发生变化时/死亡时你可以摸一/三张牌；限定技，当一名角色死亡时，你可以令一名角色摸X+1张牌，并于此回合结束后进行一个额外的出牌阶段（X为场上已阵亡角色数）。
]]
Luachaonao = sgs.CreateTriggerSkill {
    name = "Luachaonao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@chaonao",
    events = {sgs.EventPhaseEnd, sgs.EventPhaseStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:hasSkill(self)
            and room:askForSkillInvoke(player, self:objectName(), data) then
            local kingdom = room:askForKingdom(player)
            room:setPlayerMark(player, "noisy" .. kingdom, 1)
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:hasSkill(self) then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "noisy") and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
            if player:getPhase() == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("chaonao_target") ~= 0 then
                        local thread = room:getThread()
                        p:setPhase(sgs.Player_Play)
                        room:broadcastProperty(p, "phase")
                        if not thread:trigger(sgs.EventPhaseStart, room, p) then
                            thread:trigger(sgs.EventPhaseProceeding, room, p)
                        end
                        thread:trigger(sgs.EventPhaseEnd, room, p)
                        p:setPhase(sgs.Player_RoundStart)
                        room:broadcastProperty(p, "phase")
                        room:setPlayerMark(p, "chaonao_target", 0)
                    end
                end
            end
        elseif event == sgs.HpChanged or (event == sgs.MaxHpChanged and not player:isWounded()) then
            local kingdom = player:getKingdom()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("noisy" .. kingdom) ~= 0 then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            local kingdom = death.who:getKingdom()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("noisy" .. kingdom) ~= 0 then
                    room:drawCards(p, 3, self:objectName())
                end
                if p:getMark("@chaonao") ~= 0 then
                    local n = 1
                    for _, p in sgs.qlist(room:getAllPlayers(true)) do
                        if p:isDead() then
                            n = n + 1
                        end
                    end
                    local target = room:askForPlayerChosen(p, room:getAlivePlayers(), self:objectName(),
                        "@chaonao_invoke:::" .. n, true, true)
                    if target then
                        p:loseMark("@chaonao")
                        room:drawCards(target, n, self:objectName())
                        room:setPlayerMark(target, "chaonao_target", 1)
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
MarieMorimoto:addSkill(Luachaonao)

--[[
    技能名：天才
    描述：限定技，回合开始时，你可以获得场上一名其他角色的一个技能。
]]
Luatiancai = sgs.CreateTriggerSkill {
    name = "Luatiancai",
    frequency = sgs.Skill_Limited,
    limit_mark = "@tiancai",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start and player:getMark("@tiancai") ~= 0 then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@tiancai_invoke", true, true)
            if target then
                player:loseMark("@tiancai")
                local skill_List = {}
                for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                    table.insert(skill_List, skill:objectName())
                end
                local skill = room:askForChoice(player, self:objectName(), table.concat(skill_List, "+"))
                room:handleAcquireDetachSkills(player, skill, true)
                local EX = sgs.Sanguosha:getTriggerSkill(skill)
                EX:trigger(sgs.GameStart, room, player, sgs.QVariant())
            end
        end
    end,
}
MarieMorimoto:addSkill(Luatiancai)

sgs.LoadTranslationTable {
    ["MarieMorimoto"] = "森本 茉莉",
    ["&MarieMorimoto"] = "森本 茉莉",
    ["#MarieMorimoto"] = "瑪麗摩托",
    ["designer:MarieMorimoto"] = "Cassimolar",
    ["cv:MarieMorimoto"] = "森本 茉莉",
    ["illustrator:MarieMorimoto"] = "Cassimolar",
    ["Luachaonao"] = "吵闹",
    [":Luachaonao"] = "回合结束时，你可以选择一个势力，直到你的下个回合开始前，此势力的角色体力值发生变化时/死亡时你可以摸一/三张牌；限定技，当一名角色死亡时，你可以令一名角色摸X+1张牌，并于此回合结束后进行一个额外的出牌阶段（X为场上已阵亡角色数）。",
    ["@chaonao_invoke"] = "你可以令一名角色摸%arg张牌并于此回合结束后进行一个额外的出牌阶段",
    ["@chaonao"] = "吵闹",
    ["Luatiancai"] = "天才",
    ["@tiancai"] = "天才",
    [":Luatiancai"] = "限定技，回合开始时，你可以获得场上一名其他角色的一个技能。",
    ["@tiancai_invoke"] = "你可以选择一名其他角色获得其一个技能",
}
