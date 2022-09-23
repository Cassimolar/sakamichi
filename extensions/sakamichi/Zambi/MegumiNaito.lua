require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MegumiNaito = sgs.General(Zambi, "MegumiNaito", "Zambi", 4, false)
table.insert(SKMC.SanKiSei, "MegumiNaito")

--[[
    技能名：巨力
    描述：你可以将所有手牌当【杀】使用且此【杀】不计入使用次数限制；当你以法使用【杀】指定目标后，你可以摸X张牌（X为此【杀】对应实体牌中【杀】的数量），然后弃置一张牌。
]]
LuaattousuruhodonochikaraVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luaattousuruhodonochikara",
    view_as = function(self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName(self:objectName())
        slash:addSubcards(sgs.Self:getHandcards())
        return slash
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and sgs.Slash_IsAvailable(player)
    end,
}
Luaattousuruhodonochikara = sgs.CreateTriggerSkill {
    name = "Luaattousuruhodonochikara",
    events = {sgs.CardUsed},
    view_as_skill = LuaattousuruhodonochikaraVS,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == self:objectName() then
            if use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
            end
            local x = 0
            for _, id in sgs.qlist(use.card:getSubcards()) do
                if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
                    x = x + 1
                end
            end
            if x ~= 0 then
                room:drawCards(player, x, self:objectName())
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            end
        end
    end,
}
MegumiNaito:addSkill(Luaattousuruhodonochikara)

sgs.LoadTranslationTable {
    ["MegumiNaito"] = "内藤 恵美",
    ["&MegumiNaito"] = "内藤 恵美",
    ["#MegumiNaito"] = "ファンタジック",
    ["designer:MegumiNaito"] = "Cassimolar",
    ["cv:MegumiNaito"] = "岩本 蓮加",
    ["illustrator:MegumiNaito"] = "Cassimolar",
    ["Luaattousuruhodonochikara"] = "巨力",
    [":Luaattousuruhodonochikara"] = "你可以将所有手牌视为【杀】使用且此【杀】不计入使用次数限制；当你以法使用【杀】指定目标后，你可以摸X张牌（X为此【杀】对应实体牌中【杀】的数量），然后弃置一张牌。",
}
