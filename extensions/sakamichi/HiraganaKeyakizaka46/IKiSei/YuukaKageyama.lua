require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuukaKageyama_HiraganaKeyakizaka = sgs.General(Sakamichi, "YuukaKageyama_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.IKiSei, "YuukaKageyama_HiraganaKeyakizaka")

--[[
    技能名：德才
    描述：你可以将任意锦囊视为【无懈可以击】使用；当你使用一张锦囊牌后，本回合内你的手牌上限+1。
]]
LuadecaiVS = sgs.CreateOneCardViewAsSkill {
    name = "Luadecai",
    response_pattern = "nullification",
    filter_pattern = "TrickCard",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_nullification = function(self, player)
        for _, card in sgs.qlist(player:getHandcards()) do
            if card:isKindOf("TrickCard") then
                return true
            end
        end
        return false
    end,
}
Luadecai = sgs.CreateTriggerSkill {
    name = "Luadecai",
    view_as_skill = LuadecaiVS,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("TrickCard") then
            room:addMaxCards(player, 1, true)
        end
        return false
    end,
}
YuukaKageyama_HiraganaKeyakizaka:addSkill(Luadecai)

--[[
    技能名：兼学
    描述：摸牌阶段，你可以额外摸至多两张牌，若如此做，本回合内你减少等量的手牌上限。
]]
Luajianxue = sgs.CreateTriggerSkill {
    name = "Luajianxue",
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local choice = room:askForChoice(player, self:objectName(), "jianxue_draw1+jianxue_draw2+cancel")
        if choice == "jianxue_draw1" then
            data:setValue(data:toInt() + 1)
            room:addMaxCards(player, -1, true)
        elseif choice == "jianxue_draw2" then
            data:setValue(data:toInt() + 2)
            room:addMaxCards(player, -2, true)
        end
        return false
    end,
}
YuukaKageyama_HiraganaKeyakizaka:addSkill(Luajianxue)

sgs.LoadTranslationTable {
    ["YuukaKageyama_HiraganaKeyakizaka"] = "影山 優佳",
    ["&YuukaKageyama_HiraganaKeyakizaka"] = "影山 優佳",
    ["#YuukaKageyama_HiraganaKeyakizaka"] = "德才兼備",
    ["designer:YuukaKageyama_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:YuukaKageyama_HiraganaKeyakizaka"] = "影山 優佳",
    ["illustrator:YuukaKageyama_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luadecai"] = "德才",
    [":Luadecai"] = "你可以将任意锦囊视为【无懈可以击】使用；当你使用一张锦囊牌后，本回合内你的手牌上限+1。",
    ["Luajianxue"] = "兼学",
    [":Luajianxue"] = "摸牌阶段，你可以额外摸至多两张牌，若如此做，本回合内你减少等量的手牌上限。",
    ["jianxue_draw1"] = "额外摸一张牌，本回合内手牌上限-1",
    ["jianxue_draw2"] = "额外摸两张牌，本回合内手牌上限-2",
}
