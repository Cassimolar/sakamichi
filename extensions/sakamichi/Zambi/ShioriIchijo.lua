require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ShioriIchijo = sgs.General(Zambi, "ShioriIchijo", "Zambi", 3, false)
table.insert(SKMC.SanKiSei, "ShioriIchijo")

--[[
    技能名：安静
    描述：当你重铸牌时，你可以选择一项：1.弃置一张牌，本回合内手牌上限+1；2.摸一张牌，本回合内手牌上限-1。
]]
Luaotonashii = sgs.CreateTriggerSkill {
    name = "Luaotonashii",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                == sgs.CardMoveReason_S_REASON_RECAST then
                local choice = room:askForChoice(player, "Luaotonashii", "discard+drawcard+cancel")
                if choice == "discard" then
                    room:askForDiscard(player, self:objectName(), 1, 1, false, true)
                    room:addPlayerMark(player, "otonashii_plus", 1)
                elseif choice == "drawcard" then
                    room:drawCards(player, 1, self:objectName())
                    room:addPlayerMark(player, "otonashii_minus", 1)
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            if player:getMark("otonashii_plus") ~= 0 then
                room:setPlayerMark(player, "otonashii_plus", 0)
            end
            if player:getMark("otonashii_minus") ~= 0 then
                room:setPlayerMark(player, "otonashii_minus", 0)
            end
        end
        return false
    end,
}
LuaotonashiiMax = sgs.CreateMaxCardsSkill {
    name = "#LuaotonashiiMax",
    extra_func = function(self, target)
        local n = 0
        if target:getMark("otonashii_plus") ~= 0 then
            n = n + target:getMark("otonashii_plus")
        end
        if target:getMark("otonashii_minus") ~= 0 then
            n = n - target:getMark("otonashii_minus")
        end
        return n
    end,
}
ShioriIchijo:addSkill(Luaotonashii)
if not sgs.Sanguosha:getSkill("#LuaotonashiiMax") then
    SKMC.SkillList:append(LuaotonashiiMax)
end

--[[
    技能名：谦让
    描述：出牌阶段，你可以重铸手牌，每种类型限一次；每回合当你以此法重铸第二/三张牌时，你可以令一名其他角色摸一张牌。
]]
LuamodestCard = sgs.CreateSkillCard {
    name = "LuamodestCard",
    skill_name = "Luamodest",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("BasicCard") then
            room:setPlayerFlag(source, "modestBasicCard")
        end
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("TrickCard") then
            room:setPlayerFlag(source, "modestTrickCard")
        end
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("EquipCard") then
            room:setPlayerFlag(source, "modestEquipCard")
        end
        local n = 0
        if source:hasFlag("modestBasicCard") then
            n = n + 1
        end
        if source:hasFlag("modestTrickCard") then
            n = n + 1
        end
        if source:hasFlag("modestEquipCard") then
            n = n + 1
        end
        room:moveCardTo(self, source, nil, sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), "Luamodest", ""))
        room:broadcastSkillInvoke("@recast")
        local msg = sgs.LogMessage()
        msg.type = "#UseCard_Recast"
        msg.from = source
        msg.card_str = tostring(self:getSubcards():first())
        room:sendLog(msg)
        source:drawCards(1, "recast")
        if n >= 2 then
            local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), "Luamodest", "@modest_invoke",
                true, false)
            if target then
                room:drawCards(target, 1, "Luamodest")
            end
        end
    end,
}
Luamodest = sgs.CreateOneCardViewAsSkill {
    name = "Luamodest",
    view_filter = function(self, to_select)
        if sgs.Self:hasFlag("modestBasicCard") then
            if sgs.Self:hasFlag("modestTrickCard") then
                return not to_select:isKindOf("BasicCard") and not to_select:isKindOf("TrickCard")
            end
            if sgs.Self:hasFlag("modestEquipCard") then
                return not to_select:isKindOf("BasicCard") and not to_select:isKindOf("EquipCard")
            end
            return not to_select:isKindOf("BasicCard")
        end
        if sgs.Self:hasFlag("modestTrickCard") then
            if sgs.Self:hasFlag("modestBasicCard") then
                return not to_select:isKindOf("TrickCard") and not to_select:isKindOf("BasicCard")
            end
            if sgs.Self:hasFlag("modestEquipCard") then
                return not to_select:isKindOf("TrickCard") and not to_select:isKindOf("EquipCard")
            end
            return not to_select:isKindOf("TrickCard")
        end
        if sgs.Self:hasFlag("modestEquipCard") then
            if sgs.Self:hasFlag("modestBasicCard") then
                return not to_select:isKindOf("EquipCard") and not to_select:isKindOf("BasicCard")
            end
            if sgs.Self:hasFlag("modestTrickCard") then
                return not to_select:isKindOf("EquipCard") and not to_select:isKindOf("TrickCard")
            end
            return not to_select:isKindOf("EquipCard")
        end
        return true
    end,
    view_as = function(self, card)
        local cd = LuamodestCard:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return ((not player:hasFlag("modestBasicCard")) or (not player:hasFlag("modestTrickCard"))
                   or (not player:hasFlag("modestEquipCard"))) and not player:isKongcheng()
    end,
}
ShioriIchijo:addSkill(Luamodest)

sgs.LoadTranslationTable {
    ["ShioriIchijo"] = "一条 詩織",
    ["&ShioriIchijo"] = "一条 詩織",
    ["#ShioriIchijo"] = "歌姫の衣装",
    ["designer:ShioriIchijo"] = "Cassimolar",
    ["cv:ShioriIchijo"] = "伊藤 理々杏",
    ["illustrator:ShioriIchijo"] = "Cassimolar",
    ["Luaotonashii"] = "安静",
    [":Luaotonashii"] = "当你重铸牌时，你可以选择一项：1.弃置一张牌，本回合内手牌上限+1；2.摸一张牌，本回合内手牌上限-1。",
    ["Luaotonashii:discard"] = "弃置一张牌本回合手牌上限+1",
    ["Luaotonashii:drawcard"] = "摸一张牌本回合手牌上限-1",
    ["Luaotonashii:cancel"] = "取消",
    ["Luamodest"] = "谦让",
    [":Luamodest"] = "出牌阶段，你可以重铸手牌，每种类型限一次；每回合当你以此法重铸第二/三张牌时，你可以令一名其他角色摸一张牌。",
    ["@modest_invoke"] = "你可以令一名其他角色摸一张牌",
}
