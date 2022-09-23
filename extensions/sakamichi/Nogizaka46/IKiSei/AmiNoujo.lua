require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AmiNoujo = sgs.General(Sakamichi, "AmiNoujo", "Nogizaka46", 3, false)
SKMC.IKiSei.AmiNoujo = true
SKMC.SeiMeiHanDan.AmiNoujo = {
    name = {10, 11, 13, 5},
    ten_kaku = {21, "ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_shuo_chang = sgs.CreateTriggerSkill {
    name = "sakamichi_shuo_chang",
    frequency = sgs.Skill_Compulsory,
    change_skill = true,
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                room:setChangeSkillState(player, self:objectName(), 1)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isNDTrick() then
                if player:hasFlag("shuo_chang_trick") then
                    room:setPlayerMark(player, "&shuo_chang_trick_finish_end_clear", 0)
                    room:setPlayerFlag(player, "-shuo_chang_trick")
                    room:drawCards(player, 1, self:objectName())
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
                if player:getChangeSkillState(self:objectName()) == 1 then
                    room:setChangeSkillState(player, self:objectName(), 2)
                    room:setPlayerFlag(player, "shuo_chang_basic")
                    room:addPlayerMark(player, "shuo_chang_count_finish_end_clear")
                    room:setPlayerMark(player, "&shuo_chang_basic_finish_end_clear", 1)
                    if player:hasFlag("fa_ze_used") then
                        room:setPlayerFlag(player, "-fa_ze_used")
                    end
                end
            end
            if use.card:isKindOf("BasicCard") then
                if player:getChangeSkillState(self:objectName()) == 2 then
                    room:setChangeSkillState(player, self:objectName(), 1)
                    room:setPlayerFlag(player, "shuo_chang_trick")
                    room:addPlayerMark(player, "shuo_chang_count_finish_end_clear")
                    room:setPlayerMark(player, "&shuo_chang_trick_finish_end_clear", 1)
                    if player:hasFlag("fa_ze_used") then
                        room:setPlayerFlag(player, "-fa_ze_used")
                    end
                end
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if player:hasFlag("shuo_chang_basic") then
                room:setPlayerMark(player, "&shuo_chang_basic_finish_end_clear", 0)
                room:setPlayerFlag(player, "-shuo_chang_basic")
                room:setCardFlag(use.card, "RemoveFromHistory")
            end
        end
        return false
    end,
}
sakamichi_shuo_chang_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_shuo_chang_mod",
    pattern = "BasicCard",
    distance_limit_func = function(self, from, card, to)
        if from:hasFlag("shuo_chang_basic") then
            return 1000
        else
            return 0
        end
    end,
}
AmiNoujo:addSkill(sakamichi_shuo_chang)
if not sgs.Sanguosha:getSkill("#sakamichi_shuo_chang_mod") then
    SKMC.SkillList:append(sakamichi_shuo_chang_mod)
end

sakamichi_jiao_sang = sgs.CreateTriggerSkill {
    name = "sakamichi_jiao_sang",
    frequency = sgs.Skill_Wake,
    waked_skill = "sakamichi_fa_ze",
    events = {sgs.EventPhaseProceeding},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPhase() == sgs.Player_Finish and player:getMark("shuo_chang_count_finish_end_clear") >= 5 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerMark(player, self:objectName(), 1)
        room:handleAcquireDetachSkills(player, "sakamichi_fa_ze")
    end,
}
AmiNoujo:addSkill(sakamichi_jiao_sang)

sakamichi_fa_ze_card = sgs.CreateSkillCard {
    name = "sakamichi_fa_zeCard",
    skill_name = "sakamichi_fa_ze",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(
            sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), self:getSkillName(), ""))
        room:broadcastSkillInvoke("@recast")
        SKMC.send_message(room, "#UseCard_Recast", source, nil, nil, nil, self:getSubcards():first():toString())
        room:drawCards(source, 1, "recast")
        room:setPlayerFlag(source, "fa_ze_used")
    end,
}
sakamichi_fa_ze = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_fa_ze",
    filter_pattern = ".",
    view_as = function(self, card)
        local cd = sakamichi_fa_ze_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("fa_ze_used")
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_fa_ze") then
    SKMC.SkillList:append(sakamichi_fa_ze)
end

sgs.LoadTranslationTable {
    ["AmiNoujo"] = "能條 愛未",
    ["&AmiNoujo"] = "能條 愛未",
    ["#AmiNoujo"] = "舞台大佬",
    ["~AmiNoujo"] = "あみあみハリケーン",
    ["designer:AmiNoujo"] = "Cassimolar",
    ["cv:AmiNoujo"] = "能條 愛未",
    ["illustrator:AmiNoujo"] = "Cassimolar",
    ["sakamichi_shuo_chang"] = "说唱",
    [":sakamichi_shuo_chang"] = "锁定技，准备阶段，本技能重置为①。转换技，出牌阶段，①你使用通常锦囊牌时，本回合你使用的下一张基本牌无距离限制且不计入次数限制；②你使用基本牌时，本回合内你使用的下一张通常锦囊牌无法响应且摸一张牌。",
    ['shuo_chang_basic_finish_end_clear'] = "基本牌不计入次数",
    ['shuo_chang_trick_finish_end_clear'] = "通常锦囊牌无法响应",
    ["sakamichi_jiao_sang"] = "脚桑",
    [":sakamichi_jiao_sang"] = "觉醒技，结束阶段，若你回合内发动【说唱】至少五次，你增加1点体力上限并获得【法则】。",
    ["sakamichi_fa_ze"] = "法则",
    [":sakamichi_fa_ze"] = "出牌阶段限一次，你可以重铸一张牌，当你发动【说唱】时，此技能视为未曾发动。",
}
