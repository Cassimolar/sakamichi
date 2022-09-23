require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MinamiKoike_Sakurazaka = sgs.General(Sakamichi, "MinamiKoike_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.IKiSei.MinamiKoike_Sakurazaka = true
SKMC.SeiMeiHanDan.MinamiKoike_Sakurazaka = {
    name = {3, 6, 9, 8},
    ten_kaku = {9, "xiong"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {26, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_tian_ka = sgs.CreateTriggerSkill {
    name = "sakamichi_tian_ka",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:hasSkill(self) and player:getPhase() ~= sgs.Player_NotActive
                and room:askForSkillInvoke(damage.to, self:objectName(), data) then
                local result = SKMC.run_judge(room, damage.to, self:objectName(), ".")
                if result.card:isBlack() then
                    room:setPlayerFlag(player, "tian_ka_1" .. damage.to:objectName())
                elseif result.card:isRed() then
                    room:setPlayerFlag(player, "tian_ka_2" .. damage.to:objectName())
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:hasFlag("tian_ka_1" .. p:objectName()) then
                        room:drawCards(p, 1, self:objectName())
                    end
                    if player:hasFlag("tian_ka_2" .. p:objectName()) then
                        local type
                        if use.card:isKindOf("BasicCard") then
                            type = "BasicCard"
                        elseif use.card:isKindOf("TrickCard") then
                            type = "TrickCard"
                        elseif use.card:isKindOf("EquipCard") then
                            type = "EquipCard"
                        end
                        room:askForUseCard(p, type, "@tian_ka_invoke:::" .. type)
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
MinamiKoike_Sakurazaka:addSkill(sakamichi_tian_ka)

LuayouyanCard = sgs.CreateSkillCard {
    name = "LuayouyanCard",
    skill_name = "Luayouyan",
    targetFixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
                   and not sgs.Self:hasFlag("youyan_used" .. to_select:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local type1
        local name1 = sgs.Sanguosha:getEngineCard(self:getSubcards():first()):objectName()
        if sgs.Sanguosha:getEngineCard(self:getSubcards():first()):isKindOf("BasicCard") then
            type1 = "BasicCard"
        elseif sgs.Sanguosha:getEngineCard(self:getSubcards():first()):isKindOf("TrickCard") then
            type1 = "TrickCard"
        elseif sgs.Sanguosha:getEngineCard(self:getSubcards():first()):isKindOf("EquipCard") then
            type1 = "EquipCard"
        end
        local card = room:askForCard(effect.to, ".|.|.|hand", "@youyan_discard")
        if card then
            local type2
            local name2 = card:objectName()
            if card:isKindOf("BasicCard") then
                type2 = "BasicCard"
            elseif card:isKindOf("TrickCard") then
                type2 = "TrickCard"
            elseif card:isKindOf("EquipCard") then
                type2 = "EquipCard"
            end
            if type1 == type2 then
                room:drawCards(effect.from, 2, "Luayouyan")
                room:drawCards(effect.to, 2, "Luayouyan")
            end
            room:setPlayerFlag(effect.from, "youyan_used" .. effect.to:objectName())
            if name1 ~= name2 then
                room:setPlayerFlag(effect.from, "youyan_used")
            end
        end
    end,
}
Luayouyan = sgs.CreateOneCardViewAsSkill {
    name = "Luayouyan",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local Card = LuayouyanCard:clone()
        Card:addSubcard(card:getId())
        Card:setSkillName(self:objectName())
        return Card
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("youyan_used")
    end,
}
MinamiKoike_Sakurazaka:addSkill(Luayouyan)

sgs.LoadTranslationTable {
    ["MinamiKoike_Sakurazaka"] = "小池 美波",
    ["&MinamiKoike_Sakurazaka"] = "小池 美波",
    ["#MinamiKoike_Sakurazaka"] = "心动师匠",
    ["~MinamiKoike_Sakurazaka"] = "もうアイドル名乗れないので！",
    ["designer:MinamiKoike_Sakurazaka"] = "Cassimolar",
    ["cv:MinamiKoike_Sakurazaka"] = "小池 美波",
    ["illustrator:MinamiKoike_Sakurazaka"] = "Cassimolar",
    ["sakamichi_tian_ka"] = "甜咖",
    [":sakamichi_tian_ka"] = "其他角色在其回合内对你造成伤害后，你可以判定，若结果为：黑色，本回合内其使用牌结算完成时，你摸一张牌；红色，本回合内其使用牌结算完成时，你可以使用一张同类型的牌。",
    ["@tian_ka_invoke"] = "你可以使用一张%arg",
    ["Luayouyan"] = "幼言",
    [":Luayouyan"] = "出牌阶段限一次，你可以弃置一张手牌选择一名其他角色，若其也弃置一张同类型的手牌，则你与其各摸两张牌，若弃置的两张牌牌名相同，则此技能本回合对未成为过此技能目标的其他角色视为未发动过。",
    ["@youyan_discard"] = "你可以弃置一张手牌",
}
