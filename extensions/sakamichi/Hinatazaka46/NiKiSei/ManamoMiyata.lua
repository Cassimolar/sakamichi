require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManamoMiyata_Hinatazaka = sgs.General(Sakamichi, "ManamoMiyata_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.NiKiSei, "ManamoMiyata_Hinatazaka")

--[[
    技能名：魅惑
    描述：锁定技，男性角色无法响应你使用的通常锦囊牌。
]]

ManamoMiyata_Hinatazaka:addSkill("Luameihuo")

--[[
    技能名：万叶
    描述：当你使用的通常锦囊牌结算完成时，若你的武将牌上没有同牌名的“诗歌”，你可以将此牌置于你的武将牌上称为“诗歌”；“诗歌”可以视为【无懈可以击】使用且无法以此法置入“诗歌”；回合结束时，你可以将一张“诗歌”交给一名其他角色；当一名角色进入濒死时，你可以弃置所有“诗歌”（至少一张）令其翻开牌堆顶等量的牌并获得其中的非♥牌，然后弃置其中的♥牌并回复等量体力。
]]
LuawanyeCard = sgs.CreateSkillCard {
    name = "LuawanyeCard",
    skill_name = "Luawanye",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, selected, to_select)
        return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
    end,
}
LuawanyeVS = sgs.CreateOneCardViewAsSkill {
    name = "Luawanye",
    filter_pattern = ".|.|.|shige",
    expand_pile = "shige",
    view_as = function(self, card)
        local cd
        if sgs.Self:hasFlag("wanye_fin") then
            cd = LuawanyeCard:clone()
        else
            cd = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
            cd:setSkillName(self:objectName())
        end
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "nullification" or pattern == "@@Luawanye"
    end,
    enabled_at_nullification = function(self, player)
        return not player:getPile("shige"):isEmpty()
    end,
}
Luawanye = sgs.CreateTriggerSkill {
    name = "Luawanye",
    view_as_skill = LuawanyeVS,
    events = {sgs.CardFinished, sgs.EventPhaseEnd, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished and player:hasSkill(self) then
            local use = data:toCardUse()
            if use.card and use.card:isNDTrick() and use.card:getSkillName() ~= self:objectName() then
                local can = true
                for _, id in sgs.qlist(player:getPile("shige")) do
                    if sgs.Sanguosha:getCard(id):objectName() == use.card:objectName() then
                        can = false
                        break
                    end
                end
                if can
                    and room:askForSkillInvoke(player, self:objectName(),
                        sgs.QVariant("put:::" .. use.card:objectName())) then
                    player:addToPile("shige", use.card)
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish and player:hasSkill(self) then
            room:setPlayerFlag(player, "wanye_fin")
            room:askForUseCard(player, "@@Luawanye", "@Luawanye-card")
            room:setPlayerFlag(player, "-wanye_fin")
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:getPile("shige"):isEmpty() and room:askForSkillInvoke(p, self:objectName(), data) then
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        local x = p:getPile("shige"):length()
                        for _, id in sgs.qlist(p:getPile("shige")) do
                            dummy:addSubcard(id)
                        end
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "",
                            p:objectName(), self:objectName(), "")
                        room:throwCard(dummy, reason, nil)
                        dummy:deleteLater()
                        local ids = room:getNCards(x, false)
                        local move = sgs.CardsMoveStruct()
                        move.card_ids = ids
                        move.to = nil
                        move.to_place = sgs.Player_PlaceTable
                        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(),
                            self:objectName(), nil)
                        room:moveCardsAtomic(move, true)
                        local card_to_throw = {}
                        local card_to_gotback = {}
                        for i = 0, x - 1, 1 do
                            local id = ids:at(i)
                            local card = sgs.Sanguosha:getCard(id)
                            local suit = card:getSuit()
                            if suit == sgs.Card_Heart then
                                table.insert(card_to_throw, id)
                            else
                                table.insert(card_to_gotback, id)
                            end
                        end
                        if #card_to_throw > 0 then
                            local dummy1 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                            for _, id in ipairs(card_to_throw) do
                                dummy1:addSubcard(id)
                            end
                            room:recover(player, sgs.RecoverStruct(p, nil, #card_to_throw))
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                player:objectName(), self:objectName(), nil)
                            room:throwCard(dummy1, reason, nil)
                            dummy1:deleteLater()
                        end
                        if #card_to_gotback > 0 then
                            local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                            for _, id in ipairs(card_to_gotback) do
                                dummy2:addSubcard(id)
                            end
                            room:obtainCard(player, dummy2)
                            dummy2:deleteLater()
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
ManamoMiyata_Hinatazaka:addSkill(Luawanye)

--[[
    技能名：文艺
    描述：你使用通常锦囊牌时，若你使用的上一张牌是锦囊牌，你可以选择回复1点体力或失去1点体力摸两张牌。
]]
Luawenyi = sgs.CreateTriggerSkill {
    name = "Luawenyi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isNDTrick() then
            if player:getMark("wenyi") == 1 then
                local choices = {}
                if player:isWounded() then
                    table.insert(choices, "wenyi1")
                end
                table.insert(choices, "wenyi2")
                table.insert(choices, "cancel")
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                if choice == "wenyi1" then
                    room:recover(player, sgs.RecoverStruct(player, use.card, 1))
                elseif choice == "wenyi2" then
                    room:loseHp(player)
                    room:drawCards(player, 2, self:objectName())
                end
            end
        end
        if use.card and not use.card:isKindOf("SkillCard") then
            if use.card:isKindOf("TrickCard") then
                room:setPlayerMark(player, "wenyi", 1)
            else
                room:setPlayerMark(player, "wenyi", 0)
            end
        end
        return false
    end,
}
ManamoMiyata_Hinatazaka:addSkill(Luawenyi)

sgs.LoadTranslationTable {
    ["ManamoMiyata_Hinatazaka"] = "宮田 愛萌",
    ["&ManamoMiyata_Hinatazaka"] = "宮田 愛萌",
    ["#ManamoMiyata_Hinatazaka"] = "文學少女",
    ["designer:ManamoMiyata_Hinatazaka"] = "Cassimolar",
    ["cv:ManamoMiyata_Hinatazaka"] = "宮田 愛萌",
    ["illustrator:ManamoMiyata_Hinatazaka"] = "Cassimolar",
    ["Luawanye"] = "万叶",
    [":Luawanye"] = "当你使用的通常锦囊牌结算完成时，若你的武将牌上没有同牌名的“诗歌”，你可以将此牌置于你的武将牌上称为“诗歌”；“诗歌”可以视为【无懈可以击】使用且无法以此法置入“诗歌”；回合结束时，你可以将一张“诗歌”交给一名其他角色；当一名角色进入濒死时，你可以弃置所有“诗歌”（至少一张）令其翻开牌堆顶等量的牌并获得其中的非♥牌，然后弃置其中的♥牌并回复等量体力。",
    ["shige"] = "诗歌",
    ["Luawanye:put"] = "是否将此【%arg】置入“诗歌”",
    ["@Luawanye-card"] = "你可以将一张“诗歌”交给一名其他角色",
    ["Luawenyi"] = "文艺",
    [":Luawenyi"] = "你使用通常锦囊牌时，若你使用的上一张牌是锦囊牌，你可以选择回复1点体力或失去1点体力摸两张牌。",
    ["Luawenyi:wenyi1"] = "回复1点体力",
    ["Luawenyi:wenyi2"] = "失去1点体力并摸两张牌",
}
