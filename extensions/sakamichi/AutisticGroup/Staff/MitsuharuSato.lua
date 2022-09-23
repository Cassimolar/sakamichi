require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MitsuharuSato = sgs.General(Sakamichi, "MitsuharuSato", "AutisticGroup", 4, true)

--[[
    技能名：涕零
    描述：你的回合开始时，你可以选择一名于你上个回合结束后造成并受到过伤害的角色，你摸一张牌然后交给其一张手牌，若其为“けやき坂46”或“日向坂46”势力的角色/你发动此技能三次，则将此技能修改为：你的回合开始时，你可以选择一名于你上个回合结束后造成并受到过伤害的角色，你与其各摸一张牌，然后你可以选择由你或其视为使用一张【决斗】。
]]
Luatiling = sgs.CreateTriggerSkill {
    name = "Luatiling",
    events = {sgs.EventPhaseStart, sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("tiling_damage" .. player:objectName()) ~= 0 then
                    if p:getMark("tiling_damaged" .. player:objectName()) ~= 0 then
                        targets:append(p)
                    end
                    room:setPlayerMark(p, "tiling_damage" .. player:objectName(), 0)
                end
                if p:getMark("tiling_damaged" .. player:objectName()) ~= 0 then
                    room:setPlayerMark(p, "tiling_damaged" .. player:objectName(), 0)
                end
            end
            if not targets:isEmpty() then
                local target =
                    room:askForPlayerChosen(player, targets, self:objectName(), "@tiling_invoke", true, false)
                if target then
                    room:drawCards(player, 1, self:objectName())
                    if player:getMark("tiling_wake") ~= 0 then
                        room:drawCards(target, 1, self:objectName())
                        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)
                        local victims = sgs.SPlayerList()
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            if not room:isProhibited(player, p, duel) then
                                victims:append(p)
                            end
                        end
                        local victim = nil
                        if not victims:isEmpty() then
                            victim = room:askForPlayerChosen(player, victims, self:objectName(),
                                "@tiling-duel1:" .. target:objectName(), true, false)
                            if victim then
                                room:useCard(sgs.CardUseStruct(duel, player, victim, false), false)
                            else
                                local victims2 = sgs.SPlayerList()
                                for _, p in sgs.qlist(room:getOtherPlayers(target)) do
                                    if not room:isProhibited(target, p, duel) then
                                        victims2:append(p)
                                    end
                                end
                                if not victims2:isEmpty() then
                                    victim = room:askForPlayerChosen(target, victims2, self:objectName(),
                                        "@tiling-duel2", false, false)
                                    room:useCard(sgs.CardUseStruct(duel, target, victim, false), false)
                                end
                            end
                        else
                            local victims2 = sgs.SPlayerList()
                            for _, p in sgs.qlist(room:getOtherPlayers(target)) do
                                if not room:isProhibited(target, p, duel) then
                                    victims2:append(p)
                                end
                            end
                            if not victims2:isEmpty() then
                                victim = room:askForPlayerChosen(target, victims2, self:objectName(), "@tiling-duel2",
                                    false, false)
                                room:useCard(sgs.CardUseStruct(duel, target, victim, false), false)
                            end
                        end
                    else
                        local card = room:askForCard(player, ".|.|.|hand!", "@tiling_give:" .. target:objectName(),
                            data, sgs.Card_MethodNone)
                        target:obtainCard(card)
                        room:addPlayerMark(player, "tiling_used", 1)
                        if (target:getKingdom() == "HiraganaKeyakizaka46" or target:getKingdom() == "Hinatazaka46")
                            or player:getMark("@tiling_used") == 3 then
                            room:setPlayerMark(player, "tiling_wake", 1)
                            room:setPlayerMark(player, "tiling_used", 0)
                        end
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getPhase() == sgs.Player_NotActive then
                        room:setPlayerMark(player, "tiling_damage" .. p:objectName(), 1)
                    end
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.to and damage.to:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getPhase() == sgs.Player_NotActive then
                        room:setPlayerMark(player, "tiling_damaged" .. p:objectName(), 1)
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
MitsuharuSato:addSkill(Luatiling)

sgs.LoadTranslationTable {
    ["MitsuharuSato"] = "佐藤 満春",
    ["&MitsuharuSato"] = "佐藤 満春",
    ["#MitsuharuSato"] = "公式藍推",
    ["designer:MitsuharuSato"] = "Cassimolar",
    ["cv:MitsuharuSato"] = "佐藤 満春",
    ["illustrator:MitsuharuSato"] = "Cassimolar",
    ["Luatiling"] = "涕零",
    [":Luatiling"] = "你的回合开始时，你可以选择一名于你上个回合结束后造成并受到过伤害的角色，你摸一张牌然后交给其一张手牌，若其为“けやき坂46”或“日向坂46”势力的角色/你发动此技能三次，则将此技能修改为：你的回合开始时，你可以选择一名于你上个回合结束后造成并受到过伤害的角色，你与其各摸一张牌，然后你可以选择由你或其视为使用一张【决斗】。",
    ["@tiling_invoke"] = "你可以选择一名角色发动【涕零】",
    ["@tiling-duel1"] = "你可以选择一名其他角色视为对其使用一张【决斗】",
    ["@tiling-duel2"] = "请选择一名其他角色视为对其使用一张【决斗】",
    ["@tiling_give"] = "请选择一张手牌交给%src",
}
