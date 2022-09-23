require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaoIguchi_HiraganaKeyakizaka = sgs.General(Sakamichi, "MaoIguchi_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3, false)
SKMC.IKiSei.MaoIguchi_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.MaoIguchi_HiraganaKeyakizaka = {
    name = {4, 3, 10, 14},
    ten_kaku = {7, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "huo",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_jiu_guanCard = sgs.CreateSkillCard {
    name = "sakamichi_jiu_guanCard",
    skill_name = "sakamichi_jiu_guan",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
                   and to_select:hasSkill(self:getSkillName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
        analeptic:setSkillName(self:getSkillName())
        room:useCard(sgs.CardUseStruct(analeptic, effect.from, effect.from), true)
    end,
}
sakamichi_jiu_guan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jiu_guan_view_as&",
    response_pattern = "peach,analeptic",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_jiu_guanCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return (player:getKingdom() == "HiraganaKeyakizaka46" or player:getKingdom() == "Hinatazaka46")
                   and sgs.Analeptic_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return (player:getKingdom() == "HiraganaKeyakizaka46" or player:getKingdom() == "Hinatazaka46")
    end,
}
sakamichi_jiu_guan = sgs.CreateTriggerSkill {
    name = "sakamichi_jiu_guan",
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not p:hasSkill("sakamichi_jiu_guan_view_as") then
                    room:attachSkillToPlayer(p, "sakamichi_jiu_guan_view_as")
                end
            end
        elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
            local no_one_has_this_skill = true
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self) then
                    no_one_has_this_skill = false
                    break
                end
            end
            if no_one_has_this_skill then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:detachSkillFromPlayer(p, "sakamichi_jiu_guan_view_as", true)
                end
            end
        end
        return false
    end,
}
MaoIguchi_HiraganaKeyakizaka:addSkill(sakamichi_jiu_guan)
if not sgs.Sanguosha:getSkill("sakamichi_jiu_guan_view_as") then
    SKMC.SkillList:append(sakamichi_jiu_guan_view_as)
end

sakamichi_jie_fan = sgs.CreateTriggerSkill {
    name = "sakamichi_jie_fan",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Analeptic") and use.from:objectName() == player:objectName() and player:getPhase()
                ~= sgs.Player_NotActive then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                        "invoke:" .. player:objectName() .. "::" .. use.card:objectName())) then
                        room:addPlayerHistory(player, use.card:getClassName(), -1)
                        if player:isWounded() then
                            room:recover(player, sgs.RecoverStruct(p, use.card, SKMC.number_correction(p, 1)))
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
MaoIguchi_HiraganaKeyakizaka:addSkill(sakamichi_jie_fan)

sakamichi_chang_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_chang_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
            if not room:askForDiscard(player, self:objectName(), 1, 1, true) then
                player:endPlayPhase()
            end
        end
        return false
    end,
}
MaoIguchi_HiraganaKeyakizaka:addSkill(sakamichi_chang_yan)

sgs.LoadTranslationTable {
    ["MaoIguchi_HiraganaKeyakizaka"] = "井口 真緒",
    ["&MaoIguchi_HiraganaKeyakizaka"] = "井口 真緒",
    ["#MaoIguchi_HiraganaKeyakizaka"] = "妈妈桑",
    ["~MaoIguchi_HiraganaKeyakizaka"] = "私じゃダメなんですか",
    ["designer:MaoIguchi_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MaoIguchi_HiraganaKeyakizaka"] = "井口 真緒",
    ["illustrator:MaoIguchi_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_jiu_guan"] = "酒馆",
    [":sakamichi_jiu_guan"] = "けやき坂46或日向坂46势力的其他角色需要使用【酒】时，其可以交给你一张手牌视为其使用一张【酒】。",
    ["@jiu_niang_analeptic"] = "你可以弃置一张牌视为%src使用一张【酒】",
    ["sakamichi_jiu_guan_view_as"] = "酒馆",
    [":sakamichi_jiu_guan_view_as"] = "你可以令【酒馆】的拥有者交给你一张手牌视为你使用一张【酒】",
    ["sakamichi_jie_fan"] = "解烦",
    [":sakamichi_jie_fan"] = "一名角色于其回合内使用【酒】时，你可以令此【酒】不计入次数限制，若其已受伤你令其回复１点体力。",
    ["sakamichi_jie_fan:invoke"] = "是否令%src使用的【酒】不计入次数限制",
    ["sakamichi_chang_yan"] = "长言",
    [":sakamichi_chang_yan"] = "锁定技，出牌阶段，你使用牌时须弃置一张手牌，否则结束出牌阶段。",
}
