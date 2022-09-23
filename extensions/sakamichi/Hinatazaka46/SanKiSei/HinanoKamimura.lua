require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinanoKamimura_Hinatazaka = sgs.General(Sakamichi, "HinanoKamimura_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.SanKiSei, "HinanoKamimura_Hinatazaka")

--[[
    技能名：社礼
    描述：当你于回合内因弃置失去牌达到三张时，你可以选择至多一名角色，然后你和目标各摸一张牌
]]
Luasocialetiquette = sgs.CreateTriggerSkill {
    name = "Luasocialetiquette",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_NotActive
                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                == sgs.CardMoveReason_S_REASON_DISCARD then
                room:addPlayerMark(player, "socialetiquette", move.card_ids:length())
                if player:getMark("socialetiquette") >= 3 and not player:hasFlag("socialetiquette") then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                            "@socialetiquette_invoke", true, false)
                        room:drawCards(player, 1, self:objectName())
                        if target then
                            room:drawCards(target, 1, self:objectName())
                        end
                    end
                    room:setPlayerFlag(player, "socialetiquette")
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            if player:hasFlag("socialetiquette") then
                room:setPlayerFlag(player, "-socialetiquette")
            end
            room:setPlayerMark(player, "socialetiquette", 0)
        end
        return false
    end,
}
HinanoKamimura_Hinatazaka:addSkill(Luasocialetiquette)

--[[
    技能名：变球
    描述：转换技，出牌阶段限一次，①你可以摸两张牌，然后弃置一张手牌，若如此做，直到你的下一回合开始你使用【杀】无距离限制；②你选择两张手牌，你可以将其中点数较大的一张视为一张延时锦囊牌使用并弃置所选的另一张牌或弃置这两张牌。
]]
LuahenkakyuuCard = sgs.CreateSkillCard {
    name = "LuahenkakyuuCard",
    skill_name = "Luahenkakyuu",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        if self:getSubcards():length() ~= 0 then
            local id1 = self:getSubcards():first()
            local id2
            for _, id in sgs.qlist(self:getSubcards()) do
                if id1 ~= id then
                    id2 = id
                end
            end
            local max
            local min
            local throw = false
            if sgs.Sanguosha:getCard(id1):getNumber() > sgs.Sanguosha:getCard(id2):getNumber() then
                max = sgs.Sanguosha:getCard(id1)
                min = sgs.Sanguosha:getCard(id2)
            elseif sgs.Sanguosha:getCard(id1):getNumber() < sgs.Sanguosha:getCard(id2):getNumber() then
                max = sgs.Sanguosha:getCard(id2)
                min = sgs.Sanguosha:getCard(id1)
            else
                throw = true
            end
            if max then
                local DelayedTrick = {"indulgence", "lightning", "throw"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                    table.insert(DelayedTrick, 2, "supply_shortage")
                end
                local choice = room:askForChoice(source, "Luahenkakyuu", table.concat(DelayedTrick, "+"))
                if choice == "indulgence" or choice == "supply_shortage" or choice == "lightning" then
                    local cd = sgs.Sanguosha:cloneCard(choice, max:getSuit(), max:getNumber())
                    cd:addSubcard(max:getEffectiveId())
                    cd:setSkillName("Luahenkakyuu")
                    if choice == "indulgence" or choice == "supply_shortage" then
                        local targets_list = sgs.SPlayerList()
                        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
                            if not p:containsTrick(choice) and not p:isProhibited(source, cd)
                                and cd:targetFilter(sgs.PlayerList(), p, source) then
                                targets_list:append(p)
                            end
                        end
                        if targets_list:length() ~= 0 then
                            local target = room:askForPlayerChosen(source, targets_list, "Luahenkakyuu",
                                "@henkakyuu_choice:::" .. choice, false, false)
                            if target then
                                room:useCard(sgs.CardUseStruct(cd, source, target, true), true)
                                room:moveCardTo(min, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(
                                    sgs.CardMoveReason_S_REASON_THROW, source:objectName(), nil, "Luahenkakyuu", nil),
                                    true)
                            end
                        else
                            throw = true
                        end
                    else
                        if not source:containsTrick(choice) and not source:isProhibited(source, cd) then
                            room:useCard(sgs.CardUseStruct(cd, source, source, true), true)
                            room:moveCardTo(min, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_THROW, source:objectName(), nil, "Luahenkakyuu", nil), true)
                        else
                            throw = true
                        end
                    end
                else
                    throw = true
                end
            else
                throw = true
            end
            if throw then
                room:throwCard(self, source)
            end
            room:setChangeSkillState(source, "Luahenkakyuu", 1)
        else
            room:drawCards(source, 2, "Luahenkakyuu")
            room:askForDiscard(source, "Luahenkakyuu", 1, 1, true, false, "@henkakyuu_discard")
            room:setPlayerMark(source, "henkakyuu_longdan", 1)
            --	if not source:hasSkill("longdan") then
            --		room:handleAcquireDetachSkills(source, "longdan", true)
            --	end
            room:setChangeSkillState(source, "Luahenkakyuu", 2)
        end
    end,
}
LuahenkakyuuVS = sgs.CreateViewAsSkill {
    name = "Luahenkakyuu",
    n = 2,
    view_filter = function(self, selected, to_select)
        local n = sgs.Self:getChangeSkillState("Luahenkakyuu")
        if n == 2 then
            return #selected < 0
        elseif n == 1 then
            return #selected < 2 and not to_select:isEquipped()
        end
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            cd = LuahenkakyuuCard:clone()
            cd:addSubcard(cards[1])
            cd:addSubcard(cards[2])
            return cd
        end
        if #cards == 0 then
            cd = LuahenkakyuuCard:clone()
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuahenkakyuuCard")
    end,
}
Luahenkakyuu = sgs.CreateTriggerSkill {
    name = "Luahenkakyuu",
    change_skill = true,
    events = {sgs.EventPhaseStart},
    view_as_skill = LuahenkakyuuVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start and player:getMark("henkakyuu_longdan") ~= 0 then
            --	room:handleAcquireDetachSkills(player, "-longdan", true)
            room:setPlayerMark(player, "henkakyuu_longdan", 0)
        end
    end,
}
LuahenkakyuuMod = sgs.CreateTargetModSkill {
    name = "#LuahenkakyuuMod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("henkakyuu_longdan") and from:getMark("henkakyuu_longdan") ~= 0 then
            return 1000
        else
            return 0
        end
    end,
}
HinanoKamimura_Hinatazaka:addSkill(Luahenkakyuu)
if not sgs.Sanguosha:getSkill("#LuahenkakyuuMod") then
    SKMC.SkillList:append(LuahenkakyuuMod)
end

sgs.LoadTranslationTable {
    ["HinanoKamimura_Hinatazaka"] = "上村 ひなの",
    ["&HinanoKamimura_Hinatazaka"] = "上村 ひなの",
    ["#HinanoKamimura_Hinatazaka"] = "元気田支店長",
    ["designer:HinanoKamimura_Hinatazaka"] = "Cassimolar",
    ["cv:HinanoKamimura_Hinatazaka"] = "上村 ひなの",
    ["illustrator:HinanoKamimura_Hinatazaka"] = "Cassimolar",
    ["Luasocialetiquette"] = "社礼",
    [":Luasocialetiquette"] = "当你于回合内因弃置失去牌达到三张时，你可以选择至多一名角色，然后你和其各摸一张牌。",
    ["@socialetiquette_invoke"] = "你可以选择一名角色令其摸一张牌",
    ["Luahenkakyuu"] = "变球",
    [":Luahenkakyuu"] = "转换技，出牌阶段限一次，①你可以摸两张牌，然后弃置一张手牌，若如此做，直到你的下一回合开始你使用【杀】无距离限制；②你选择两张手牌，你可以将其中点数较大的一张视为一张延时锦囊牌使用并弃置所选的另一张牌或弃置这两张牌。",
    [":Luahenkakyuu1"] = "转换技，出牌阶段限一次，<font color=\"#01A5AF\"><s>①你可以摸两张牌，然后弃置一张手牌，若如此做，直到你的下一回合开始你使用【杀】无距离限制</s></font>；②你选择两张手牌，你可以将其中点数较大的一张视为一张延时锦囊牌使用并弃置所选的另一张牌或弃置这两张牌。",
    [":Luahenkakyuu2"] = "转换技，出牌阶段限一次，①你可以摸两张牌，然后弃置一张手牌，若如此做，直到你的下一回合开始你使用【杀】无距离限制；<font color=\"#01A5AF\"><s>②你选择两张手牌，你可以将其中点数较大的一张视为一张延时锦囊牌使用并弃置所选的另一张牌或弃置这两张牌。</s></font>",
    ["henakyuu:throw"] = "弃置",
    ["@henkakyuu_choice"] = "请为此%arg 选择一个目标",
    ["@henkakyuu_discard"] = "请弃置一张手牌",
}
