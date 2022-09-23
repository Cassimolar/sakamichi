require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MikuniTakahashi = sgs.General(Sakamichi, "MikuniTakahashi", "Hinatazaka46", 3, false, true)
table.insert(SKMC.SanKiSei, "MikuniTakahashi")

MikuniTakahashi:addSkill("sakamichi_bu_fu")

--[[
    技能名：高挑
    描述：一名角色的出牌阶段开始时，若其距离与你为1，你可以弃置其至多X张牌，其中每弃置一张♠牌便视为其对你使用一张【杀】(X为其体力值)；锁定技，其他角色计算与你的距离-Y（Y为你已损失的体力值）。
]]
Luagaotiao = sgs.CreateTriggerSkill {
    name = "Luagaotiao",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:distanceTo(p) == 1 and not player:isAllNude()
                    and room:askForSkillInvoke(p, self:objectName(), data) then
                    local n = 0
                    for i = 1, player:getHp(), 1 do
                        local choices = {}
                        if not player:isAllNude() then
                            table.insert(choices, "gaotiao1")
                        end
                        table.insert(choices, "cancel")
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
                        if choice == "gaotiao1" then
                            local card = room:askForCardChosen(p, player, "hej", self:objectName(), false,
                                sgs.Card_MethodDiscard)
                            if sgs.Sanguosha:getCard(card):getSuit() == sgs.Card_Spade then
                                n = n + 1
                            end
                            room:throwCard(card, player, p)
                        else
                            break
                        end
                    end
                    if n ~= 0 then
                        for i = 1, n, 1 do
                            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                            slash:setSkillName(self:objectName())
                            room:useCard(sgs.CardUseStruct(slash, player, p), false)
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
LuagaotiaoDistance = sgs.CreateDistanceSkill {
    name = "#LuagaotiaoDistance",
    correct_func = function(self, from, to)
        if to:hasSkill("Luagaotiao") then
            return -to:getLostHp()
        end
    end,
}
MikuniTakahashi:addSkill(Luagaotiao)
if not sgs.Sanguosha:getSkill("#LuagaotiaoDistance") then
    SKMC.SkillList:append(LuagaotiaoDistance)
end

sgs.LoadTranslationTable {
    ["MikuniTakahashi"] = "髙橋 未来虹",
    ["&MikuniTakahashi"] = "髙橋 未来虹",
    ["#MikuniTakahashi"] = "高挑的彩虹",
    ["designer:MikuniTakahashi"] = "Cassimolar",
    ["cv:MikuniTakahashi"] = "髙橋 未来虹",
    ["illustrator:MikuniTakahashi"] = "Cassimolar",
    ["Luagaotiao"] = "高挑",
    [":Luagaotiao"] = "一名角色的出牌阶段开始时，若其距离与你为1，你可以弃置其至多X张牌，其中每弃置一张♠牌便视为其对你使用一张【杀】(X为其体力值)；锁定技，其他角色计算与你的距离-Y（Y为你已损失的体力值）。",
    ["Luagaotiao:gaotiao1"] = "弃置其一张牌",
}
