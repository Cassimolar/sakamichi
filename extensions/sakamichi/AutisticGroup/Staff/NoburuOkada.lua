require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NoburuOkada = sgs.General(Sakamichi, "NoburuOkada", "AutisticGroup", 4, true)

--[[
    技能名：神舌
    描述：当你使用或打出一张牌时，若此牌与你使用或打出的上一张牌花色相同，你可以摸一张牌。
]]
Luashenshe = sgs.CreateTriggerSkill {
    name = "Luashenshe",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                if player:objectName() == use.from:objectName() then
                    card = use.card
                end
            else
                local response = data:toCardResponse()
                card = response.m_card
            end
            if card:getTypeId() == sgs.Card_TypeSkill then
                return false
            end
            local suit_str = card:getSuitString()
            if string.find(suit_str, "no_suit") then
                suit_str = "no_suit"
            end
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "&shenshe+") and player:getMark(mark) ~= 0 then
                    room:setPlayerMark(player, mark, 0)
                end
            end
            room:setPlayerMark(player, "&shenshe+" .. suit_str, 1)
            if suit_str == player:getTag("shensheSuit"):toString() then
                if player:askForSkillInvoke(self:objectName()) then
                    player:drawCards(1)
                end
            end
            player:setTag("shensheSuit", sgs.QVariant(suit_str))
        end
        return false
    end,
}
NoburuOkada:addSkill(Luashenshe)

sgs.LoadTranslationTable {
    ["NoburuOkada"] = "岡田 昇",
    ["&NoburuOkada"] = "岡田 昇",
    ["#NoburuOkada"] = "猥瑣岡田",
    ["designer:NoburuOkada"] = "Cassimolar",
    ["cv:NoburuOkada"] = "岡田 昇",
    ["illustrator:NoburuOkada"] = "Cassimolar",
    ["Luashenshe"] = "神舌",
    [":Luashenshe"] = "当你使用或打出一张牌时，若此牌与你使用或打出的上一张牌花色相同，你可以摸一张牌。",
    ["shenshe"] = "神舌",
}
