require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MiriaWatanabe = sgs.General(Sakamichi, "MiriaWatanabe", "Nogizaka46", 3, false)
SKMC.NiKiSei.MiriaWatanabe = true
SKMC.SeiMeiHanDan.MiriaWatanabe = {
    name = {12, 5, 3, 2, 13},
    ten_kaku = {17, "ji"},
    jin_kaku = {8, "ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_cheng_shu_card = sgs.CreateSkillCard {
    name = "sakamichi_cheng_shuCard",
    skill_name = "sakamichi_cheng_shu",
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark("cheng_shu")
    end,
    feasible = function(self, targets)
        return #targets > 0 and #targets <= sgs.Self:getMark("cheng_shu")
    end,
    on_use = function(self, room, source, targets)
        for _, p in pairs(targets) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
        local choices = {"cheng_shu_1"}
        local all_nude = false
        for _, p in pairs(targets) do
            if p:isAllNude() then
                all_nude = true
            end
        end
        if not all_nude then
            table.insert(choices, "cheng_shu_2")
        end
        local choice = room:askForChoice(source, self:getSkillName(), table.concat(choices, "+"))
        SKMC.choice_log(source, choice)
        for _, p in pairs(targets) do
            if choice == "cheng_shu_1" then
                room:drawCards(p, 1, self:getSkillName())
            else
                local id = room:askForCardChosen(source, p, "hej", self:getSkillName(), false, sgs.Card_MethodDiscard)
                room:throwCard(id, p, source)
            end
        end
        room:setPlayerMark(source, "cheng_shu", 0)
    end,
}
sakamichi_cheng_shu_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_cheng_shu",
    view_as = function(self, cards)
        return sakamichi_cheng_shu_card:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_cheng_shu")
    end,
}
sakamichi_cheng_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_cheng_shu",
    frequency = sgs.Skill_Compulsory,
    view_as_skill = sakamichi_cheng_shu_view_as,
    events = {sgs.CardEffected, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("DelayedTrick") then
                SKMC.send_message(room, "#cheng_shu", player, nil, nil, effect.card:toString(), self:objectName())
                return true
            end
        elseif player:getPhase() == sgs.Player_Discard then
            if event == sgs.CardsMoveOneTime then
                local move = data:toMoveOneTime()
                if move.to_place == sgs.Player_DiscardPile then
                    if move.from and move.from:objectName() == player:objectName()
                        and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                        == sgs.CardMoveReason_S_REASON_DISCARD then
                        room:addPlayerMark(player, "cheng_shu", move.card_ids:length())
                    end
                end
            elseif event == sgs.EventPhaseEnd then
                if player:getMark("cheng_shu") > 0 then
                    room:askForUseCard(player, "@@sakamichi_cheng_shu", "@cheng_shu_choice:::" .. self:objectName(), -1,
                        sgs.Card_MethodUse)
                end
            end
        end
        return false
    end,
}
MiriaWatanabe:addSkill(sakamichi_cheng_shu)

sakamichi_da_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_da_shi",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and not use.to:contains(p) then
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        if p:isWounded() then
                            room:recover(p, sgs.RecoverStruct(player, use.card, SKMC.number_correction(p, 1)))
                        else
                            room:drawCards(p, 1, self:objectName())
                        end
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
MiriaWatanabe:addSkill(sakamichi_da_shi)

sgs.LoadTranslationTable {
    ["MiriaWatanabe"] = "渡辺 みり愛",
    ["&MiriaWatanabe"] = "渡辺 みり愛",
    ["#MiriaWatanabe"] = "假萝莉",
    ["~MiriaWatanabe"] = "100万人の人に愛されたい",
    ["designer:MiriaWatanabe"] = "Cassimolar",
    ["cv:MiriaWatanabe"] = "渡辺 みり愛",
    ["illustrator:MiriaWatanabe"] = "Cassimolar",
    ["sakamichi_cheng_shu"] = "成熟",
    [":sakamichi_cheng_shu"] = "锁定技，延时类锦囊对你无效。弃牌阶段结束时，你可以选择：令至多X名角色各摸一张牌；分别弃置至多X名区域内有牌的角色区域内的一张牌（X为你本阶段弃牌数）。",
    ["#cheng_shu"] = "%from 的【%arg】被触发，【%card】对 %from 无效",
    ["@cheng_shu_choice"] = "请选择发动【%arg】的目标",
    ["~sakamichi_cheng_shu"] = "选择若干名角色 → 点击确定",
    ["cheng_shu_1"] = "令这些角色各摸一张牌",
    ["cheng_shu_2"] = "分别弃置这些角色各一张牌",
    ["sakamichi_da_shi"] = "大食",
    [":sakamichi_da_shi"] = "其他角色使用【桃】时，若目标不包含你且你：已受伤，你可以回复1点体力；未受伤，你可以摸一张牌。",
}
