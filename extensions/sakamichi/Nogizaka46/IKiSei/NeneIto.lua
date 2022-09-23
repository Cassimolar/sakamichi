require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NeneIto = sgs.General(Sakamichi, "NeneIto", "Nogizaka46", 4, false)
SKMC.IKiSei.NeneIto = true
SKMC.SeiMeiHanDan.NeneIto = {
    name = {6, 18, 14, 3},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {32, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {9, "xiong"},
    sou_kaku = {41, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_za_ji_card = sgs.CreateSkillCard {
    name = "sakamichi_za_jiCard",
    skill_name = "sakamichi_za_ji",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        local phase = sgs.Self:getMark("za_ji_Phase")
        if phase == sgs.Player_Draw then
            if to_select:objectName() ~= sgs.Self:objectName() then
                if not to_select:isKongcheng() then
                    return #targets < 2
                end
            end
        end
        return false
    end,
    feasible = function(self, targets)
        local phase = sgs.Self:getMark("za_ji_Phase")
        if phase == sgs.Player_Draw then
            if #targets > 0 then
                return #targets <= 2
            end
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local phase = source:getMark("za_ji_Phase")
        if phase == sgs.Player_Draw then
            if #targets > 0 then
                for _, p in pairs(targets) do
                    room:cardEffect(self, source, p)
                end
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if not effect.to:isKongcheng() then
            local card_id = room:askForCardChosen(effect.from, effect.to, "h", self:getSkillName())
            room:moveCardTo(sgs.Sanguosha:getCard(card_id), effect.from, sgs.Player_PlaceHand,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, effect.from:objectName()))
        end
    end,
}
sakamichi_za_ji_view_as = sgs.CreateViewAsSkill {
    name = "sakamichi_za_ji",
    n = 0,
    view_as = function()
        return sakamichi_za_ji_card:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@sakamichi_za_ji"
    end,
}
sakamichi_za_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_za_ji",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseChanging},
    view_as_skill = sakamichi_za_ji_view_as,
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        local nextphase = change.to
        room:setPlayerMark(player, "za_ji_Phase", nextphase)
        local index = 0
        if nextphase == sgs.Player_Judge then
            index = 1
        elseif nextphase == sgs.Player_Draw then
            index = 2
        elseif nextphase == sgs.Player_Play then
            index = 3
        elseif nextphase == sgs.Player_Discard then
            index = 4
        end
        if index > 0 and not player:isKongcheng() then
            if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "@za_ji_discard_" .. index) then
                if not player:isSkipped(nextphase) then
                    if index == 2 then
                        room:askForUseCard(player, "@sakamichi_za_ji", "@za_ji_" .. index, index)
                    elseif index == 3 then
                        room:moveField(player, self:objectName(), false, "ej")
                    end
                end
                player:skip(nextphase)
            end
        end
        return false
    end,
}
NeneIto:addSkill(sakamichi_za_ji)

sgs.LoadTranslationTable {
    ["NeneIto"] = "伊藤 寧々",
    ["&NeneIto"] = "伊藤 寧々",
    ["#NeneIto"] = "傘妹",
    ["~NeneIto"] = "そっちの伊藤落ちろ！",
    ["designer:NeneIto"] = "Cassimolar",
    ["cv:NeneIto"] = "伊藤 寧々",
    ["illustrator:NeneIto"] = "Cassimolar",
    ["sakamichi_za_ji"] = "杂技",
    [":sakamichi_za_ji"] = "你可以弃置一张手牌，跳过除准备阶段和结束阶段外的一个阶段，若你以此法：跳过摸牌阶段，你可以选择一至两名有手牌的其他角色，获得这些角色的各一张手牌；跳过出牌阶段，你可以将一名角色判定区/装备区里的一张牌置入另一名角色的判定区/装备区。",
    ["@za_ji_2"] = "你可以依次获得一至两名其他角色的各一张手牌",
    ["@za_ji_3"] = "你可以将场上的一张牌移动至另一名角色相应的区域内",
    ["@za_ji_discard_1"] = "你可以弃置 %arg 张手牌跳过判定阶段",
    ["@za_ji_discard_2"] = "你可以弃置 %arg 张手牌跳过摸牌阶段",
    ["@za_ji_discard_3"] = "你可以弃置 %arg 张手牌跳过出牌阶段",
    ["@za_ji_discard_4"] = "你可以弃置 %arg 张手牌跳过弃牌阶段",
    ["~sakamichi_za_ji2"] = "选择 1-2 名其他角色 → 点击确定",
}
