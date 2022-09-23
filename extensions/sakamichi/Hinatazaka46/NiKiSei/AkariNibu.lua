require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkariNibu_Hinatazaka = sgs.General(Sakamichi, "AkariNibu_Hinatazaka", "Hinatazaka46", 4, false)
table.insert(SKMC.NiKiSei, "AkariNibu_Hinatazaka")

--[[
    技能名：塔鸡
    描述：出牌阶段限一次，你可以弃置一名其他角色的一张牌，若此牌不为【桃】，本回合内其所有手牌均视为【桃】。
]]
LuatajiCard = sgs.CreateSkillCard {
    name = "LuatajiCard",
    skill_name = "Luataji",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = room:askForCardChosen(effect.from, effect.to, "hej", "Luataji", false, sgs.Card_MethodDiscard)
        room:throwCard(card, effect.to, effect.from)
        if not sgs.Sanguosha:getCard(card):isKindOf("Peach") then
            if not effect.to:hasSkill("#Luataji_filter", true) then
                room:acquireSkill(effect.to, "#Luataji_filter", false)
                room:filterCards(effect.to, effect.to:getCards("h"), true)
                local msg = sgs.LogMessage()
                msg.type = "#taji"
                msg.from = effect.from
                msg.to:append(effect.to)
                msg.card_str = sgs.Sanguosha:getCard(card):toString()
                msg.arg = "Luataji"
                room:sendLog(msg)
            end
        end
    end,
}
LuatajiVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luataji",
    view_as = function(self)
        return LuatajiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuatajiCard")
    end,
}
Luataji = sgs.CreateTriggerSkill {
    name = "Luataji",
    view_as_skill = LuatajiVS,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill("#Luataji_filter") then
                    room:detachSkillFromPlayer(p, "#Luataji_filter")
                    room:filterCards(p, p:getCards("h"), true)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Luataji_filter = sgs.CreateFilterSkill {
    name = "#Luataji_filter",
    view_filter = function(self, to_select)
        return sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
    end,
    view_as = function(self, card)
        local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
        peach:setSkillName("Luataji")
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(peach)
        return new
    end,
}
AkariNibu_Hinatazaka:addSkill(Luataji)
if not sgs.Sanguosha:getSkill("#Luataji_filter") then
    SKMC.SkillList:append(Luataji_filter)
end

--[[
    技能名：真纯
    描述：锁定技，当你受到伤害时/造成伤害时，若伤害量大于1，防止多余的伤害。
]]
Luazhenchun = sgs.CreateTriggerSkill {
    name = "Luazhenchun",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage > 1 then
            damage.damage = 1
            if event == sgs.DamageCaused then
                room:setEmotion(damage.to, "armor/silver_lion")
            else
                room:setEmotion(player, "armor/silver_lion")
            end
            data:setValue(damage)
        end
    end,
}
AkariNibu_Hinatazaka:addSkill(Luazhenchun)

sgs.LoadTranslationTable {
    ["AkariNibu_Hinatazaka"] = "丹生 明里",
    ["&AkariNibu_Hinatazaka"] = "丹生 明里",
    ["#AkariNibu_Hinatazaka"] = "奇跡少女",
    ["designer:AkariNibu_Hinatazaka"] = "Cassimolar",
    ["cv:AkariNibu_Hinatazaka"] = "丹生 明里",
    ["illustrator:AkariNibu_Hinatazaka"] = "Cassimolar",
    ["Luataji"] = "塔鸡",
    [":Luataji"] = "出牌阶段限一次，你可以弃置一名其他角色的一张牌，若此牌不为【桃】，本回合内其所有手牌均视为【桃】。",
    ["#taji"] = "%from因%arg弃置的%to的牌【%card】不为【桃】，本回合内%to所有手牌视为【桃】",
    ["Luazhenchun"] = "真纯",
    [":Luazhenchun"] = "锁定技，当你受到伤害时/造成伤害时，若伤害量大于1，防止多余的伤害。",
}
