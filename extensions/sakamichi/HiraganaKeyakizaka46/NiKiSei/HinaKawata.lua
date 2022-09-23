require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinaKawata_HiraganaKeyakizaka =
    sgs.General(Sakamichi, "HinaKawata_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3, false)
table.insert(SKMC.NiKiSei, "HinaKawata_HiraganaKeyakizaka")

--[[
    技能名：情报
    描述：出牌阶段限一次，你可以交给一名其他角色一张手牌，若如此做，直到你的下个回合开始，其手牌始终对所有人可见。
]]
LuaqingbaoCard = sgs.CreateSkillCard {
    name = "LuaqingbaoCard",
    skill_name = "Luaqingbao",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, selected, to_select)
        return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
        --		room:showAllCards(effect.to)
        room:setPlayerMark(effect.to, "HandcardVisible_ALL" .. effect.from:objectName(), 1)
    end,
}
LuaqingbaoVS = sgs.CreateOneCardViewAsSkill {
    name = "Luaqingbao",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skillcard = LuaqingbaoCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#LuaqingbaoCard")
    end,
}
Luaqingbao = sgs.CreateTriggerSkill {
    name = "Luaqingbao",
    view_as_skill = LuaqingbaoVS,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:hasSkill(self) and player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark("HandcardVisible_ALL" .. player:objectName()) ~= 0 then
                    room:setPlayerMark(p, "HandcardVisible_ALL" .. player:objectName(), 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaKawata_HiraganaKeyakizaka:addSkill(Luaqingbao)

--[[
    技能名：分析
    描述：限定技，出牌阶段，你可以选择一名其他角色，本局游戏剩余时间内，你和其受到伤害时，伤害+1。
]]
LuafenxiCard = sgs.CreateSkillCard {
    name = "LuafenxiCard",
    skill_name = "Luafenxi",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:loseMark("@fenxi")
        room:addPlayerMark(effect.from, "@fenxi_mark", 1)
        room:addPlayerMark(effect.to, "@fenxi_mark", 1)
    end,
}
LuafenxiVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luafenxi",
    view_as = function(self)
        return LuafenxiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@fenxi") ~= 0
    end,
}
Luafenxi = sgs.CreateTriggerSkill {
    name = "Luafenxi",
    view_as_skill = LuafenxiVS,
    frequency = sgs.Skill_Limited,
    limit_mark = "@fenxi",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:getMark("@fenxi_mark") ~= 0 then
            damage.damage = damage.damage + player:getMark("@fenxi_mark")
            data:setValue(damage)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaKawata_HiraganaKeyakizaka:addSkill(Luafenxi)

--[[
    技能名：熊猫
    描述：锁定技，你的红色卡牌均视为无色，你使用的黑色的基本牌和通常锦囊牌无法响应。
]]
Luaxiongmao = sgs.CreateFilterSkill {
    name = "Luaxiongmao",
    view_filter = function(self, to_select)
        return to_select:isRed()
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName(self:objectName())
        new_card:setSuit(sgs.Card_NoSuit)
        new_card:setModified(true)
        return new_card
    end,
}
Luaxiongmao_trigger = sgs.CreateTriggerSkill {
    name = "#Luaxiongmao_trigger",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isBlack() then
            local no_respond_list = use.no_respond_list
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                table.insert(no_respond_list, p:objectName())
                room:setCardFlag(use.card, "no_respond_" .. player:objectName() .. p:objectName())
            end
            use.no_respond_list = no_respond_list
            data:setValue(use)
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill("Luaxiongmao")
    end,
}
Sakamichi:insertRelatedSkills("Luaxiongmao", "#Luaxiongmao_trigger")
HinaKawata_HiraganaKeyakizaka:addSkill(Luaxiongmao)
HinaKawata_HiraganaKeyakizaka:addSkill(Luaxiongmao_trigger)

sgs.LoadTranslationTable {
    ["HinaKawata_HiraganaKeyakizaka"] = "河田 陽菜",
    ["&HinaKawata_HiraganaKeyakizaka"] = "河田 陽菜",
    ["#HinaKawata_HiraganaKeyakizaka"] = "團妹",
    ["designer:HinaKawata_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:HinaKawata_HiraganaKeyakizaka"] = "河田 陽菜",
    ["illustrator:HinaKawata_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luaqingbao"] = "情报",
    [":Luaqingbao"] = "出牌阶段限一次，你可以交给一名其他角色一张手牌，若如此做，直到你的下个回合开始，其手牌始终对所有人可见。",
    ["Luafenxi"] = "分析",
    [":Luafenxi"] = "限定技，出牌阶段，你可以选择一名其他角色，本局游戏剩余时间内，你和其受到伤害时，伤害+1。",
    ["@fenxi"] = "分析",
    ["@fenxi_mark"] = "分析",
    ["Luaxiongmao"] = "熊猫",
    [":Luaxiongmao"] = "锁定技，你的红色卡牌均视为无色，你使用的黑色的基本牌和通常锦囊牌无法响应。",
}
