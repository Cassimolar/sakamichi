require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NaoYumiki_AutisticGroup = sgs.General(Sakamichi, "NaoYumiki_AutisticGroup", "AutisticGroup", 3, false)
table.insert(SKMC.YonKiSei, "NaoYumiki_AutisticGroup")

--[[
    技能名：剧团
    描述：游戏开始时/当你造成/受到1点伤害后，你可以检视未上场或已阵亡的武将中的三个并选择将其中的一个加入你的“剧本”。
]]
function isNormalGameMode(mode_name)
    return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
end

function GetAvailableGenerals(nao)
    local all = sgs.Sanguosha:getLimitedGeneralNames()
    local room = nao:getRoom()
    if (isNormalGameMode(room:getMode()) or room:getMode():find("_mini_") or room:getMode() == "custom_scenario") then
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
    local juben = {}
    local juben_String = nao:getTag("juben"):toString()
    if juben_String and juben_String ~= "" then
        juben = juben_String:split("+")
    end
    table.removeTable(all, juben)
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

function GetScript(nao, n)
    local room = nao:getRoom();
    local juben = {}
    local juben_String = nao:getTag("juben"):toString()
    if juben_String and juben_String ~= "" then
        juben = juben_String:split("+")
    end
    local list = GetAvailableGenerals(nao)
    local acquired = {}
    if #list ~= 0 then
        for i = 1, n, 1 do
            local x = math.min(3, #list)
            local random = {}
            repeat
                local rand = math.random(1, #list)
                if not table.contains(random, list[rand]) then
                    table.insert(random, (list[rand]))
                end
            until #random == x
            local general_name = room:askForGeneral(nao, table.concat(random, "+"))
            table.insert(juben, general_name)
            table.insert(acquired, general_name)
            table.removeOne(list, general_name)
        end
        local hidden = {}
        for i = 1, n, 1 do
            table.insert(hidden, "unknown")
        end
        for _, p in sgs.qlist(room:getAllPlayers()) do
            local splist = sgs.SPlayerList()
            splist:append(p)
            if p:objectName() == nao:objectName() then
                room:doAnimate(4, nao:objectName(), table.concat(acquired, ":"), splist)
            else
                room:doAnimate(4, nao:objectName(), table.concat(hidden, ":"), splist);
            end
        end
        nao:setTag("juben", sgs.QVariant(table.concat(juben, "+")))
        local log = sgs.LogMessage()
        log.type = "#Getjuben"
        log.from = nao
        log.arg = n
        log.arg2 = #juben
        room:sendLog(log)
        room:setPlayerMark(nao, "@juben", #juben)
    end
end

function SelectScript(nao)
    local room = nao:getRoom()
    local juben = {}
    local juben_String = nao:getTag("juben"):toString()
    if juben_String and juben_String ~= "" then
        juben = juben_String:split("+")
    end
    if #juben == 0 then
        return
    end
    local jutuan_generals = {}
    for _, jutuan in pairs(juben) do
        table.insert(jutuan_generals, jutuan)
    end
    local general_name = room:askForGeneral(nao, table.concat(jutuan_generals, "+"))
    local log = sgs.LogMessage()
    log.type = "#Getyanyuan"
    log.from = nao
    log.arg = general_name
    room:sendLog(log)
    local maxhp = nao:getMaxHp()
    local hp = nao:getHp()
    room:changeHero(nao, general_name, false, false, true, true)
    room:setPlayerProperty(nao, "maxhp", sgs.QVariant(maxhp))
    room:setPlayerProperty(nao, "hp", sgs.QVariant(hp))
    local skill_names = {}
    local general = sgs.Sanguosha:getGeneral(general_name)
    assert(general)
    for _, skill in sgs.qlist(general:getVisibleSkillList()) do
        if skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
            if not table.contains(skill_names, skill:objectName()) then
                table.insert(skill_names, "-" .. skill:objectName())
            end
        end
    end
    if #skill_names > 0 then
        room:handleAcquireDetachSkills(nao, table.concat(skill_names, "|"), false)
    end
end

Luajutuan = sgs.CreateTriggerSkill {
    name = "Luajutuan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.GameStart, sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                GetScript(player, 1)
            end
        else
            local damage = data:toDamage()
            if room:askForSkillInvoke(player, self:objectName(), data) then
                GetScript(player, damage.damage)
            end
        end
    end,
}
NaoYumiki_AutisticGroup:addSkill(Luajutuan)

--[[
    技能名：演员
    描述：回合开始时/回合结束时，你可以从“剧本”中选择一名武将成为/替换你的副将（不会以游戏开始时的状态加入，且失去所有该武将的限定技和觉醒技）。
]]
Luayanyuan = sgs.CreateTriggerSkill {
    name = "Luayanyuan",
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start)
            or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                SelectScript(player)
            end
        end
    end,
}
NaoYumiki_AutisticGroup:addSkill(Luayanyuan)

sgs.LoadTranslationTable {
    ["NaoYumiki_AutisticGroup"] = "弓木 菜生",
    ["&NaoYumiki_AutisticGroup"] = "弓木 菜生",
    ["#NaoYumiki_AutisticGroup"] = "天然素材",
    ["designer:NaoYumiki_AutisticGroup"] = "Cassimolar",
    ["cv:NaoYumiki_AutisticGroup"] = "弓木 奈於",
    ["illustrator:NaoYumiki_AutisticGroup"] = "Cassimolar",
    ["#Getjuben"] = "%from 获得了 %arg 张“剧本”，现在共有 %arg2 张“剧本”",
    ["#Getyanyuan"] = "%from 选择了 %arg 成为她的副将",
    ["Luajutuan"] = "剧团",
    [":Luajutuan"] = "游戏开始时/当你造成/受到1点伤害后，你可以检视未上场或已阵亡的武将中的三个并选择将其中的一个加入你的“剧本”。",
    ["Luayanyuan"] = "演员",
    [":Luayanyuan"] = "回合开始时/回合结束时，你可以从“剧本”中选择一名武将成为/替换你的副将（不会以游戏开始时的状态加入，且失去所有该武将的限定技和觉醒技）。",
}
