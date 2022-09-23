require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManamiMatsuoka = sgs.General(Sakamichi, "ManamiMatsuoka", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.ManamiMatsuoka = true
SKMC.SeiMeiHanDan.ManamiMatsuoka = {
    name = {8, 8, 13, 9},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {17, "ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_shu_xinCard = sgs.CreateSkillCard {
    name = "sakamichi_shu_xinCard",
    skill_name = "sakamichi_shu_xin",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        source:addToPile("&xin", self, false)
    end,
}
sakamichi_shu_xin_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_shu_xin",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_shu_xinCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_shu_xinCard")
    end,
}
sakamichi_shu_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_shu_xin",
    view_as_skill = sakamichi_shu_xin_view_as,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive
                and move.from_places and move.from_places:contains(sgs.Player_PlaceSpecial) and move.from_pile_names
                and table.contains(move.from_pile_names, "&xin") then
                room:drawCards(player, 2, self:objectName())
                room:setPlayerMark(player, "shu_xin", 1)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
            if player:getMark("shu_xin") ~= 0 then
                room:setPlayerMark(player, "shu_xin", 0)
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("Nogizaka46"))
            end
        elseif event == sgs.DrawNCards then
            if not player:getPile("&xin"):isEmpty() then
                for _, id in sgs.qlist(player:getPile("&xin")) do
                    room:obtainCard(player, id)
                end
                data:setValue(0)
            end
        end
        return false
    end,
}
ManamiMatsuoka:addSkill(sakamichi_shu_xin)

sakamichi_gui_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_gui_yin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start)
            or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) then
            if player:getKingdom() ~= "SakamichiKenshusei" then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("SakamichiKenshusei"))
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and use.from:objectName() == player:objectName()
                and player:getKingdom() == "Nogizaka46" then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
sakamichi_gui_yin_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_gui_yin_mod",
    pattern = ".",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_gui_yin") then
            return 1000
        else
            return 0
        end
    end,
}
ManamiMatsuoka:addSkill(sakamichi_gui_yin)
if not sgs.Sanguosha:getSkill("#sakamichi_gui_yin_mod") then
    SKMC.SkillList:append(sakamichi_gui_yin_mod)
end

sgs.LoadTranslationTable {
    ["ManamiMatsuoka"] = "松岡 愛美",
    ["&ManamiMatsuoka"] = "松岡 愛美",
    ["#ManamiMatsuoka"] = "幻之四期",
    ["~ManamiMatsuoka"] = "",
    ["designer:ManamiMatsuoka"] = "Cassimolar",
    ["cv:ManamiMatsuoka"] = "松岡 愛美",
    ["illustrator:ManamiMatsuoka"] = "Cassimolar",
    ["sakamichi_shu_xin"] = "书信",
    [":sakamichi_shu_xin"] = "出牌阶段限一次，你可以将一张手牌背面向上置于你的武将牌上称为「信」。你可以将「信」视为手牌使用或打出。当你于回合外失去「信」时你摸两张牌并在你的下个出牌阶段开始将你的势力改为乃木坂46。摸牌阶段，若你有「信」则你放弃摸牌改为获得「信」。",
    ["&xin"] = "信",
    ["sakamichi_gui_yin"] = "归隐",
    [":sakamichi_gui_yin"] = "锁定技，准备阶段或结束阶段，若你的势力不为坂道研修生则改为坂道研修生；当你的势力为乃木坂46时，你使用牌无距离限制且可以摸一张牌。",
}
