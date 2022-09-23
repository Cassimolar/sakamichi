require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManabuKishi = sgs.General(Sakamichi, "ManabuKishi", "AutisticGroup", 5, true)

--[[
    技能名：举枪
    描述：每个回合限一次，当你受到伤害后，你可以视为使用一张【决斗】。
]]
Luajuqiang = sgs.CreateTriggerSkill {
    name = "Luajuqiang",
    events = {sgs.Damaged, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.to and damage.to:objectName() == player:objectName() and player:hasSkill(self)
                and player:getMark("juqiang_used") == 0 then
                local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)
                local victims = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if not room:isProhibited(player, p, duel) then
                        victims:append(p)
                    end
                end
                local victim = nil
                if not victims:isEmpty() then
                    victim = room:askForPlayerChosen(player, victims, self:objectName(), "@juqiang-duel", true, false)
                    if victim then
                        room:setPlayerMark(player, "juqiang_used", 1)
                        room:useCard(sgs.CardUseStruct(duel, player, victim, false), false)
                    end
                end
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("juqiang_used") ~= 0 then
                        room:setPlayerMark(player, "juqiang_used", 0)
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
ManabuKishi:addSkill(Luajuqiang)

sgs.LoadTranslationTable {
    ["ManabuKishi"] = "岸 学",
    ["&ManabuKishi"] = "岸 学",
    ["#ManabuKishi"] = "傑克鮑爾",
    ["designer:ManabuKishi"] = "Cassimolar",
    ["cv:ManabuKishi"] = "岸 学",
    ["illustrator:ManabuKishi"] = "Cassimolar",
    ["Luajuqiang"] = "举枪",
    [":Luajuqiang"] = "<font color=\"green\"><b>每个回合限一次</b></font>，当你受到伤害后，你可以视为使用一张【决斗】。",
    ["@juqiang-duel"] = "你可以选择一名其他角色视为对其使用一张【决斗】",
}
