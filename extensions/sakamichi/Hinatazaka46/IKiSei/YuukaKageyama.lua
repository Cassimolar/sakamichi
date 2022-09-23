require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuukaKageyama_Hinatazaka = sgs.General(Sakamichi, "YuukaKageyama_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "YuukaKageyama_Hinatazaka")

--[[
    技能名：博才
    描述：出牌阶段，你可以重铸锦囊牌；当你使用/重铸锦囊时，你可以摸两/一张牌或回复1点体力；锁定技，你使用锦囊牌没有距离限制。
]]
LuabocaiCard = sgs.CreateSkillCard {
    name = "LuabocaiCard",
    skill_name = "Luabocai",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:moveCardTo(self, source, nil, sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), "Luabocai", ""))
        room:broadcastSkillInvoke("@recast")
        local msg = sgs.LogMessage()
        msg.type = "#UseCard_Recast"
        msg.from = source
        msg.card_str = tostring(self:getSubcards():first())
        room:sendLog(msg)
        source:drawCards(1, "recast")
    end,
}
LuabocaiVS = sgs.CreateOneCardViewAsSkill {
    name = "Luabocai",
    filter_pattern = "TrickCard",
    view_as = function(self, card)
        local skill_card = LuabocaiCard:clone()
        skill_card:addSubcard(card)
        skill_card:setSkillName(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#LuabocaiCard")
    end,
}
Luabocai = sgs.CreateTriggerSkill {
    name = "Luabocai",
    events = {sgs.CardUsed, sgs.CardsMoveOneTime},
    view_as_skill = LuabocaiVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("TrickCard") then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw2cards")) then
                    player:drawCards(2)
                else
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(player))
                    end
                end
            end
            return false
        else
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                == sgs.CardMoveReason_S_REASON_RECAST then
                for _, card_id in sgs.qlist(move.card_ids) do
                    if sgs.Sanguosha:getCard(card_id):isKindOf("TrickCard") then
                        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw1cards")) then
                            player:drawCards(1)
                        else
                            if player:isWounded() then
                                room:recover(player, sgs.RecoverStruct(player))
                            end
                        end
                    end
                end
            end
        end
    end,
}
LuabocaiMod = sgs.CreateTargetModSkill {
    name = "#LuabocaiMod",
    pattern = "TrickCard",
    distance_limit_func = function(self, from, card)
        if from:hasSkill("Luabocai") then
            return 1000
        else
            return 0
        end
    end,
}
YuukaKageyama_Hinatazaka:addSkill(Luabocai)
if not sgs.Sanguosha:getSkill("#LuabocaiMod") then
    SKMC.SkillList:append(LuabocaiMod)
end

--[[
    技能名：球判
    描述：出牌阶段限一次，你可以选择一张锦囊牌称为"门"并选择一名角色令其选择一张手牌称为"球"，展示"门"和“球”并翻开牌堆顶的一张牌称为“门”，若"球"的点数等于其中一张"门"的点数时，其失去1点体力，
        若"球"的点数处于两张"门"的点数范围外时，其须弃置两张手牌（不足则全弃），若"球"的点数处于两张"门"的点数范围内时，其可以选择回复1点体力或对一名其他角色造成1点伤害，然后你将所有"门"和"球"置入弃牌堆并选择摸两张牌或回复1点体力。
]]
LuaqiupanCard = sgs.CreateSkillCard {
    name = "LuaqiupanCard",
    skill_name = "Luaqiupan",
    target_fixed = false,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local card = room:askForExchange(targets[1], self:objectName(), 1, 1, false, "@qiupan_show")
        local cd = sgs.Sanguosha:getCard(room:drawCard())
        room:moveCardTo(sgs.Sanguosha:getCard(room:drawCard()), nil, sgs.Player_PlaceTable, true)
        room:showCard(source, self:getEffectiveId())
        room:showCard(source, cd:getEffectiveId())
        room:showCard(targets[1], card:getEffectiveId())
        local men1, men2 = 0, 0
        if sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() < cd:getNumber() then
            men1 = sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber()
            men2 = cd:getNumber()
        else
            men1 = cd:getNumber()
            men2 = sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber()
        end
        local msg1 = sgs.LogMessage()
        local msg2 = sgs.LogMessage()
        msg1.type = "#men_point"
        msg2.type = "#qiu_point"
        msg1.from = source
        msg2.from = targets[1]
        msg1.arg = men1
        msg1.arg2 = men2
        msg2.arg = card:getNumber()
        room:sendLog(msg1)
        if card:getNumber() == men1 or card:getNumber() == men2 then
            msg2.arg2 = "Hit_Goalpost"
            room:sendLog(msg2)
            room:loseHp(targets[1])
        elseif card:getNumber() < men1 or card:getNumber() > men2 then
            msg2.arg2 = "Outside_The_Goal"
            room:sendLog(msg2)
            if targets[1]:getHandcardNum() <= 2 then
                targets[1]:throwAllHandCards()
            else
                room:askForDiscard(targets[1], "Luaqiupan", 2, 2, false)
            end
        else
            msg2.arg2 = "In_The_Goal"
            room:sendLog(msg2)
            local target = room:askForPlayerChosen(targets[1], room:getOtherPlayers(targets[1]), "Luaqiupan",
                "@qiupan_invoke", true, false)
            if target then
                room:damage(sgs.DamageStruct("Luaqiupan", targets[1], target))
            elseif targets[1]:isWounded() then
                room:recover(targets[1], sgs.RecoverStruct(targets[1]))
            end
        end
        room:moveCardTo(self, source, nil, sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), "Luaqiupan", ""))
        room:moveCardTo(cd, source, nil, sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "Luaqiupan", ""))
        room:moveCardTo(card, source, nil, sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "Luaqiupan", ""))
        room:broadcastSkillInvoke("@recast")
        local msg = sgs.LogMessage()
        msg.type = "#UseCard_Recast"
        msg.from = source
        msg.card_str = tostring(self:getSubcards():first())
        room:sendLog(msg)
        source:drawCards(1, "recast")
    end,
}
Luaqiupan = sgs.CreateOneCardViewAsSkill {
    name = "Luaqiupan",
    filter_pattern = "TrickCard",
    view_as = function(self, card)
        local skill_card = LuaqiupanCard:clone()
        skill_card:addSubcard(card)
        skill_card:setSkillName(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#LuaqiupanCard")
    end,
}
YuukaKageyama_Hinatazaka:addSkill(Luaqiupan)

sgs.LoadTranslationTable {
    ["YuukaKageyama_Hinatazaka"] = "影山 優佳",
    ["&YuukaKageyama_Hinatazaka"] = "影山 優佳",
    ["#YuukaKageyama_Hinatazaka"] = "足球才女",
    ["designer:YuukaKageyama_Hinatazaka"] = "Cassimolar",
    ["cv:YuukaKageyama_Hinatazaka"] = "影山 優佳",
    ["illustrator:YuukaKageyama_Hinatazaka"] = "Cassimolar",
    ["Luabocai"] = "博才",
    [":Luabocai"] = "出牌阶段限一次，你可以重铸锦囊牌；当你使用/重铸锦囊时，你可以摸两张牌或回复1点体力/额外摸一张牌或回复1点体力；锁定技，你使用锦囊牌没有距离限制。",
    ["Luabocai:draw2cards"] = "是否摸两张牌，否则回复1点体力",
    ["Luabocai:draw1cards"] = "是否额外摸一张牌，否则回复1点体力",
    ["Luaqiupan"] = "球判",
    [":Luaqiupan"] = "出牌阶段限一次，你可以选择一张锦囊牌称为“门”并选择一名角色令其选择一张手牌称为“球”，展示“门”和“球”并翻开牌堆顶的一张牌称为“门”，若“球”的点数等于其中一张“门”的点数时，其失去1点体力，若“球”的点数处于两张“门”的点数范围外时，其须弃置两张手牌（不足则全弃），若“球”的点数处于两张“门”的点数范围内时，其可以选择回复1点体力或对一名其他角色造成1点伤害，然后你将所有“门”和“球”置入弃牌堆，来自你手牌的“门”视为重铸。",
    ["Luaqiupan:draw2cards"] = "是否摸两张牌，否则回复1点体力",
    ["@qiupan_show"] = "请选择一张手牌作为“球”展示",
    ["#men_point"] = "%from 的门的范围为%arg~%arg2",
    ["#qiu_point"] = "%from 的球的点数为%arg，%arg2",
    ["Hit_Goalpost"] = "球踢到了门柱",
    ["Outside_The_Goal"] = "球踢到了门外",
    ["In_The_Goal"] = "球进了",
}
