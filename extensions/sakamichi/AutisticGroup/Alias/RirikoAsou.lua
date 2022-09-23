require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RirikoAsou = sgs.General(Sakamichi, "RirikoAsou", "AutisticGroup", 3, false)
table.insert(SKMC.IKiSei, "RirikoAsou")

--[[
    技能名：天赋
    描述：游戏开始时，你从随机五个未上场的武将的技能内进行两轮选择并获得你选择的技能；回合开始时，你可以选择失去一个以此法获得的技能并进行一轮选择。
]]
Luatianfu = sgs.CreateTriggerSkill {
    name = "Luatianfu",
    events = {sgs.GameStart, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            for x = 1, 2, 1 do
                local allnames = sgs.Sanguosha:getLimitedGeneralNames()
                local allplayers = room:getAllPlayers()
                for _, p in sgs.qlist(allplayers) do
                    local name = p:getGeneralName()
                    table.removeOne(allnames, name)
                end
                local targets = {}
                for i = 1, 5, 1 do
                    local count = #allnames
                    local index = math.random(1, count)
                    local selected = allnames[index]
                    table.insert(targets, selected)
                    table.removeOne(allnames, selected)
                end
                local generals = table.concat(targets, "+")
                local general = room:askForGeneral(player, generals)
                local target = sgs.Sanguosha:getGeneral(general)
                local skills = target:getVisibleSkillList()
                local skillnames = {}
                for _, skill in sgs.qlist(skills) do
                    if not skill:inherits("SPConvertSkill") then
                        local skillname = skill:objectName()
                        table.insert(skillnames, skillname)
                    end
                end
                local choices = table.concat(skillnames, "+")
                local skill = room:askForChoice(player, self:objectName(), choices)
                player:setTag("Luatianfu" .. x, sgs.QVariant(skill))
                room:handleAcquireDetachSkills(player, skill, true)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local oldskill1 = player:getTag("Luatianfu1"):toString()
            local oldskill2 = player:getTag("Luatianfu2"):toString()
            if oldskill1 ~= "" or oldskill2 ~= "" then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local oldskill = room:askForChoice(player, self:objectName(), oldskill1 .. "+" .. oldskill2)
                    local allnames = sgs.Sanguosha:getLimitedGeneralNames()
                    local allplayers = room:getAllPlayers()
                    for _, p in sgs.qlist(allplayers) do
                        local name = p:getGeneralName()
                        table.removeOne(allnames, name)
                    end
                    local targets = {}
                    for i = 1, 5, 1 do
                        local count = #allnames
                        local index = math.random(1, count)
                        local selected = allnames[index]
                        table.insert(targets, selected)
                        table.removeOne(allnames, selected)
                    end
                    local generals = table.concat(targets, "+")
                    local general = room:askForGeneral(player, generals)
                    local target = sgs.Sanguosha:getGeneral(general)
                    local skills = target:getVisibleSkillList()
                    local skillnames = {}
                    for _, skill in sgs.qlist(skills) do
                        if not skill:inherits("SPConvertSkill") then
                            local skillname = skill:objectName()
                            table.insert(skillnames, skillname)
                        end
                    end
                    local choices = table.concat(skillnames, "+")
                    local skill = room:askForChoice(player, self:objectName(), choices)
                    if oldskill == oldskill1 then
                        player:setTag("Luatianfu1", sgs.QVariant(skill))
                    else
                        player:setTag("Luatianfu2", sgs.QVariant(skill))
                    end
                    room:handleAcquireDetachSkills(player, "-" .. oldskill .. "|" .. skill, true)
                end
            end
        end
        return false
    end,
}
RirikoAsou:addSkill(Luatianfu)

--[[
    技能名：青春女子学園
    描述：当一名角色获得/失去技能时你可以令其摸一张牌/回复1点体力。
]]
Luaseishu = sgs.CreateTriggerSkill {
    name = "Luaseishu",
    events = {sgs.EventLoseSkill, sgs.EventAcquireSkill},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill(self) then
                if event == sgs.EventAcquireSkill then
                    if room:askForSkillInvoke(p, self:objectName(),
                        sgs.QVariant("draw:" .. player:objectName() .. "::" .. self:objectName())) then
                        player:drawCards(1)
                    end
                else
                    if player:isWounded() then
                        if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                            "recover:" .. player:objectName() .. "::" .. self:objectName())) then
                            room:recover(player, sgs.RecoverStruct(p))
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
RirikoAsou:addSkill(Luaseishu)

sgs.LoadTranslationTable {
    ["RirikoAsou"] = "麻生 梨里子",
    ["&RirikoAsou"] = "麻生 梨里子",
    ["#RirikoAsou"] = "全才",
    ["designer:RirikoAsou"] = "Cassimolar",
    ["cv:RirikoAsou"] = "能條 愛未",
    ["illustrator:RirikoAsou"] = "Cassimolar",
    ["Luatianfu"] = "天赋",
    [":Luatianfu"] = "游戏开始时，你从随机五个未上场的武将的技能内进行两轮选择并获得你选择的技能；回合开始时，你可以选择失去一个以此法获得的技能并进行一轮选择。",
    ["Luaseishu"] = "青春女子学園",
    [":Luaseishu"] = "当一名角色获得/失去技能时你可以令其摸一张牌/回复1点体力。",
    ["Luaseishu:draw"] = "是否发动%arg 令%src 摸一张牌",
    ["Luaseishu:recover"] = "是否发动%arg 令%src 回复1点体力",
}
