require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

WuNai = sgs.General(Sakamichi, "WuNai", "AutisticGroup", 2, true, true)

--[[
    技能名：加推
    描述：游戏开始时/回合开始时，你可以选择一名不为你的“推”的角色成为你的“推”；回合结束时，你可以将一张手牌交给一名你的“推”，锁定技，你的额定摸牌数为X/2（X为场上你的“推”的数量，X/2向下取整）。
]]
Luajiatui = sgs.CreateTriggerSkill {
    name = "Luajiatui",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("oshi" .. player:objectName()) == 0 then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jiatui_invoke", true, true)
                if target then
                    room:setPlayerMark(target, "oshi" .. player:objectName(), 1)
                    room:addPlayerMark(target, "@Oshi", 1)
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("oshi" .. player:objectName()) ~= 0 then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1, targets,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), self:objectName(), nil),
                    "@jiatui_give", false)
            end
        elseif event == sgs.DrawNCards then
            local count = 0
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("oshi" .. player:objectName()) ~= 0 then
                    count = count + 1
                end
            end
            local n = math.floor(count / 2)
            data:setValue(n)
        end
        return false
    end,
}
WuNai:addSkill(Luajiatui)

--[[
    技能名：DD
    描述：锁定技，游戏开始时，你获得【举义】、【巨贾】、【资援】、【握手】、【应援】；弃牌阶段开始时，你须依次交给每名你的“推”至少一张牌，否则从你的“推”将其移除。
]]
LuaDD_WuNai = sgs.CreateTriggerSkill {
    name = "LuaDD_WuNai",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            room:handleAcquireDetachSkills(player, "juyi|jugu|ziyuan|Luawoshou|sakamichi_ying_yuan", true)
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("oshi" .. player:objectName()) then
                    local card = room:askForCard(player, ".|.|.|hand,equipped", "@dd_WuNai_give:" .. p:objectName(),
                        data, sgs.Card_MethodNone)
                    if card then
                        p:obtainCard(card)
                    else
                        room:setPlayerMark(p, "oshi" .. player:objectName(), 0)
                        room:removePlayerMark(p, "@Oshi", 1)
                    end
                end
            end
        end
        return false
    end,
}
WuNai:addSkill(LuaDD_WuNai)

sgs.LoadTranslationTable {
    ["WuNai"] = "无奈",
    ["&WuNai"] = "无奈",
    ["#WuNai"] = "想被壽司吃的",
    ["designer:WuNai"] = "Cassimolar",
    ["cv:WuNai"] = "无奈",
    ["illustrator:"] = "Cassimolar",
    ["Luajiatui"] = "加推",
    [":Luajiatui"] = "游戏开始时/回合开始时，你可以选择一名不为你的“推”的角色成为你的“推”；回合结束时，你可以将一张手牌交给一名你的“推”，锁定技，你的额定摸牌数为X/2（X为场上你的“推”的数量，X/2向下取整）。",
    ["@jiatui_invoke"] = "你可以选择一名其他角色成为你的“推”",
    ["@jiatui_give"] = "你可以将一张手牌交给你的“推”",
    ["LuaDD_WuNai"] = "DD",
    [":LuaDD_WuNai"] = "锁定技，游戏开始时，你获得【举义】、【巨贾】、【资援】、【握手】、【应援】；弃牌阶段开始时，你须依次交给每名你的“推”至少一张牌，否则从你的“推”将其移除。",
    ["@dd_WuNai_give"] = "你须将一张牌交给%src，否则其将从你的“推”中移除",
}
