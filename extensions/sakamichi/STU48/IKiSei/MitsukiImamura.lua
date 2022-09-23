require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MitsukiImamura = sgs.General(STU48, "MitsukiImamura", "STU48", 3, false)
table.insert(SKMC.IKiSei, "MitsukiImamura")

--[[
    技能名：船长
    描述：出牌阶段限一次，你可以弃置任意张手牌，若其中包含：
        花色为红桃，你可以为一名已受伤的角色回复1点体力；
        花色为方块，你可以令一名角色摸一张牌；
        花色为黑桃，你可以对一名角色造成1点雷电伤害；
        花色为梅花，你可以令一名角色翻面并将手牌补至体力上限；
        基本牌，你可以从牌堆和弃牌堆内获得一张你指定类型的基本牌；
        锦囊牌，此技能此次发动的其他效果均重复一次；
        装备牌，你可以移动场上一张牌；
        若上述条件均满足，此技能视为未发动过。
]]
LuaCaptainCard = sgs.CreateSkillCard {
    name = "LuaCaptainCard",
    skill_name = "LuaCaptain",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local HasHeart, HasDiamond, HasSpade, HasClub, HasBasic, HasTrick, HasEquip = false, false, false, false, false,
            false, false
        for _, id in sgs.qlist(self:getSubcards()) do
            if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
                HasHeart = true
            elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
                HasDiamond = true
            elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
                HasSpade = true
            elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Club then
                HasClub = true
            end
            if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                HasBasic = true
            elseif sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
                HasTrick = true
            elseif sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
                HasEquip = true
            end
        end
        local x = 0
        if HasTrick then
            x = 2
        else
            x = 1
        end
        for i = 1, x do
            if HasHeart then
                local Wounded = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isWounded() then
                        Wounded:append(p)
                    end
                end
                local target = room:askForPlayerChosen(source, Wounded, "LuaCaptain", "@Captain-Heart", true, false)
                if target then
                    room:recover(target, sgs.RecoverStruct(source, self))
                end
            end
            if HasDiamond then
                local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "LuaCaptain", "@Captain-Diamond",
                    true, false)
                if target then
                    room:drawCards(target, 1, "LuaCaptain")
                end
            end
            if HasSpade then
                local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "LuaCaptain", "@Captain-Spade",
                    true, false)
                if target then
                    room:damage(sgs.DamageStruct("LuaCaptain", source, target, 1, sgs.DamageStruct_Thunder))
                end
            end
            if HasClub then
                local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "LuaCaptain", "@Captain-Club",
                    true, false)
                if target then
                    target:turnOver()
                    if target:getHandcardNum() < target:getMaxHp() then
                        room:drawCards(target, target:getMaxHp() - target:getHandcardNum(), self:objectName())
                    end
                end
            end
            if HasBasic then
                local choice = room:askForChoice(source, "LuaCaptain",
                    "Slash+ThunderSlash+FireSlash+Jink+Peach+Analeptic")
                local whole_pile = room:getDiscardPile()
                for _, id in sgs.qlist(room:getDrawPile()) do
                    whole_pile:append(id)
                end
                local ids = sgs.IntList()
                for _, id in sgs.qlist(whole_pile) do
                    if choice == "Slash" then
                        if sgs.Sanguosha:getCard(id):isKindOf("Slash")
                            and not sgs.Sanguosha:getCard(id):isKindOf("ThunderSlash")
                            and not sgs.Sanguosha:getCard(id):isKindOf("FireSlash") then
                            ids:append(id)
                        end
                    else
                        if sgs.Sanguosha:getCard(id):isKindOf(choice) then
                            ids:append(id)
                        end
                    end
                end
                room:obtainCard(source, ids:at(math.random(0, ids:length() - 1)), false)
            end
            if HasEquip then
                local legaltargets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasEquip() or p:getJudgingArea():length() > 0 then
                        legaltargets:append(p)
                    end
                end
                if legaltargets:length() > 0 then
                    local target = room:askForPlayerChosen(source, legaltargets, "LuaCaptain", "@Captain-Equip", true,
                        false)
                    if target then
                        local card_id = room:askForCardChosen(source, target, "ej", "LuaCaptain")
                        local card = sgs.Sanguosha:getCard(card_id)
                        local place = room:getCardPlace(card_id)
                        local equip_index = -1
                        if place == sgs.Player_PlaceEquip then
                            local equip = card:getRealCard():toEquipCard()
                            equip_index = equip:location()
                        end
                        local tos = sgs.SPlayerList()
                        local list = room:getAlivePlayers()
                        for _, p in sgs.qlist(list) do
                            if equip_index ~= -1 then
                                if not p:getEquip(equip_index) then
                                    tos:append(p)
                                end
                            else
                                if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
                                    tos:append(p)
                                end
                            end
                        end
                        local tag = sgs.QVariant()
                        tag:setValue(target)
                        room:setTag("CaptainTarget", tag)
                        local to = room:askForPlayerChosen(source, tos, "LuaCaptain", "@Captain-EquipTo", true, false)
                        if to then
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(),
                                "LuaCaptain", "")
                            room:moveCardTo(card, target, to, place, reason)
                        end
                        room:removeTag("CaptainTarget")
                    end
                end
            end
            if not (HasHeart and HasDiamond and HasSpade and HasClub and HasBasic and HasTrick and HasEquip) then
                room:setPlayerFlag(source, "Captain_used")
            end
        end
    end,
}
LuaCaptain = sgs.CreateViewAsSkill {
    name = "LuaCaptain",
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cd = LuaCaptainCard:clone()
            for _, card in pairs(cards) do
                cd:addSubcard(card)
            end
            cd:setSkillName(self:objectName())
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("Captain_used")
    end,
}
MitsukiImamura:addSkill(LuaCaptain)

sgs.LoadTranslationTable {
    ["MitsukiImamura"] = "今村 美月",
    ["&MitsukiImamura"] = "今村 美月",
    ["#MitsukiImamura"] = "二代船长",
    ["designer:MitsukiImamura"] = "Cassimolar",
    ["cv:MitsukiImamura"] = "今村 美月",
    ["illustrator:MitsukiImamura"] = "Cassimolar",
    ["LuaCaptain"] = "船长",
    [":LuaCaptain"] = "出牌阶段限一次，你可以弃置任意张手牌，若其中包含：\
    花色为红桃，你可以为一名已受伤的角色回复1点体力；\
    花色为方块，你可以令一名角色摸一张牌；\
    花色为黑桃，你可以对一名角色造成1点雷电伤害；\
    花色为梅花，你可以令一名角色翻面并将手牌补至体力上限；\
    基本牌，你可以从牌堆和弃牌堆内获得一张你指定类型的基本牌；\
    锦囊牌，此技能此次发动的其他效果均重复一次；\
    装备牌，你可以移动场上一张牌；\
    若上述条件均满足，此技能视为未发动过。",
    ["@Captain-Heart"] = "你可以令一名已受伤角色回复1点体力",
    ["@Captain-Diamond"] = "你可以令一名角色摸一张牌",
    ["@Captain-Spade"] = "你可以对一名角色造成1点雷电伤害",
    ["@Captain-Club"] = "你可以令一名角色武将牌翻面并将手牌补至体力上限",
    ["LuaCaptain:Slash"] = "杀",
    ["LuaCaptain:ThunderSlash"] = "雷杀",
    ["LuaCaptain:FireSlash"] = "火杀",
    ["LuaCaptain:Jink"] = "闪",
    ["LuaCaptain:Peach"] = "桃",
    ["LuaCaptain:Analeptic"] = "酒",
    ["@Captain-Equip"] = "你可以移动场上一张牌",
    ["@Captain-EquipTo"] = "选择此牌移动至的目标",
}
