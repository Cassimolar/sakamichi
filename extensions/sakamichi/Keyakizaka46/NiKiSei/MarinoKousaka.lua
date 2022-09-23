require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MarinoKousaka = sgs.General(Sakamichi, "MarinoKousaka", "Keyakizaka46", 3, false, true)
SKMC.NiKiSei.MarinoKousaka = true
SKMC.SeiMeiHanDan.MarinoKousaka = {
    name = {8, 7, 8, 7, 2},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_hu_laCard = sgs.CreateSkillCard {
    name = "sakamichi_hu_laCard",
    skill_name = "sakamichi_hu_la",
    target_fixed = true,
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    on_use = function(self, room, source, targets)
        source:addToPile("&hu_la", self)
    end,
}
sakamichi_hu_la_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_hu_la",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_hu_laCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_hu_laCard")
    end,
}
sakamichi_hu_la = sgs.CreateTriggerSkill {
    name = "sakamichi_hu_la",
    view_as_skill = sakamichi_hu_la_view_as,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive
            and move.from_places and move.from_places:contains(sgs.Player_PlaceSpecial)
            and table.contains(move.from_pile_names, "&hu_la") then
            local card = room:askForCard(player, ".|.|.|hand", "@hu_la_invoke", data, sgs.Card_MethodNone)
            if card then
                player:addToPile("&hu_la", card)
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
MarinoKousaka:addSkill(sakamichi_hu_la)

sakamichi_duan_fa = sgs.CreateTriggerSkill {
    name = "sakamichi_duan_fa",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Fire and room:askForSkillInvoke(player, self:objectName(), data) then
            room:loseHp(player, SKMC.number_correction(player, 1))
            room:setEmotion(damage.to, "skill_nullify")
            return true
        end
        return false
    end,
}
MarinoKousaka:addSkill(sakamichi_duan_fa)

sakamichi_e_meng = sgs.CreateTriggerSkill {
    name = "sakamichi_e_meng",
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and (move.from:objectName() == player:objectName())
                and move.from_places:contains(sgs.Player_PlaceHand) then
                if event == sgs.BeforeCardsMove then
                    if not player:isKongcheng() then
                        for _, id in sgs.qlist(player:handCards()) do
                            if not move.card_ids:contains(id) then
                                return false
                            end
                        end
                        player:addMark(self:objectName())
                    end
                else
                    if player:getMark(self:objectName()) ~= 0 then
                        player:removeMark(self:objectName())
                        local targets = sgs.SPlayerList()
                        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        slash:deleteLater()
                        slash:setSkillName(self:objectName())
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            if player:canSlash(p, slash, false) then
                                targets:append(p)
                            end
                        end
                        local target =
                            room:askForPlayerChosen(player, targets, self:objectName(), "@e_meng_slash", true)
                        if target then
                            room:useCard(sgs.CardUseStruct(slash, player, target), false)
                        end
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == self:objectName() then
                room:drawCards(player, 2, self:objectName())
            end
        end
        return false
    end,
}
MarinoKousaka:addSkill(sakamichi_e_meng)

sgs.LoadTranslationTable {
    ["MarinoKousaka"] = "幸阪 茉里乃",
    ["&MarinoKousaka"] = "幸阪 茉里乃",
    ["#MarinoKousaka"] = "死亡金属",
    ["~MarinoKousaka"] = "全然。全然ちゃうなぁ",
    ["designer:MarinoKousaka"] = "Cassimolar",
    ["cv:MarinoKousaka"] = "幸阪 茉里乃",
    ["illustrator:MarinoKousaka"] = "Cassimolar",
    ["sakamichi_hu_la"] = "呼啦",
    [":sakamichi_hu_la"] = "出牌阶段限一次，你可以将一张手牌置于你的武将牌上称为「呼啦」并可以视为手牌使用或打出；你的回合外，当你失去「呼啦」时，你可以将一张手牌置入「呼啦」，然后你摸一张牌。",
    ["@hu_la_invoke"] = "你可以将一张手牌置入「呼啦」",
    ["&hu_la"] = "呼啦",
    ["sakamichi_duan_fa"] = "断发",
    [":sakamichi_duan_fa"] = "当你受到火焰伤害时，你可以失去1点体力防止此次伤害。",
    ["@duan_fa"] = "发",
    ["sakamichi_e_meng"] = "噩梦",
    [":sakamichi_e_meng"] = "当你失去最后的手牌时，你可以视为对一名其他角色使用一张【杀】，若此【杀】造成伤害，你可以摸两张牌。",
    ["@e_meng_slash"] = "你可以选择一名其他角色视为对其使用一张【杀】",
}
