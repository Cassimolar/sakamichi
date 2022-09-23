require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AoiHarada_Keyakizaka = sgs.General(Sakamichi, "AoiHarada_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.AoiHarada_Keyakizaka = true
SKMC.SeiMeiHanDan.AoiHarada_Keyakizaka = {
    name = {10, 5, 12},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {17, "ji"},
    ji_kaku = {12, "xiong"},
    soto_kaku = {22, "xiong"},
    sou_kaku = {27, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_xiao_xue_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_xue_sheng",
    events = {sgs.HpRecover, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.HpRecover and player:getPhase() ~= sgs.Player_NotActive then
            room:setPlayerFlag(player, "xiaoxuesheng")
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            if player:hasFlag("xiaoxuesheng") and not player:isKongcheng() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(),
                        sgs.QVariant("@xiao_xue_sheng_invoke:" .. player:objectName())) then
                        room:drawCards(p, 2, self:objectName())
                        if p:objectName() ~= player:objectName() then
                            local cards = room:askForExchange(p, self:objectName(), 1, 1, false,
                                "@xiao_xue_sheng_give_1:" .. player:objectName())
                            room:obtainCard(player, cards, false)
                        end
                    else
                        room:drawCards(player, 1, self:objectName())
                        if p:objectName() ~= player:objectName() then
                            local cards = room:askForExchange(player, self:objectName(), 2, 2, false,
                                "@xiao_xue_sheng_give_2:" .. p:objectName())
                            room:obtainCard(p, cards, false)
                        end
                    end
                    if player:isKongcheng() then
                        break
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
AoiHarada_Keyakizaka:addSkill(sakamichi_xiao_xue_sheng)

sakamichi_dan_gaoCard = sgs.CreateSkillCard {
    name = "sakamichi_dan_gaoCard",
    skill_name = "sakamichi_dan_gao",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:isWounded()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local suit_str = sgs.Sanguosha:getCard(self:getSubcards():first()):getSuitString()
        room:recover(effect.to, sgs.RecoverStruct(effect.from, self, 1))
        if effect.to:getMark("dan_gao_" .. suit_str) == 0 then
            room:addPlayerMark(effect.to, "dan_gao_" .. suit_str)
            room:addPlayerMark(effect.to, "dan_gao")
        end
        local count = 0
        for _, mark in sgs.list(effect.to:getMarkNames()) do
            if string.find(mark, "dan_gao_") and effect.to:getMark(mark) ~= 0 then
                count = count + 1
            end
        end
        if count == 4 then
            room:handleAcquireDetachSkills(effect.to, "sakamichi_tang_niao_bing")
        end
        room:setPlayerFlag(effect.from, "dan_gao_use_" .. suit_str)
        if effect.from:hasFlag("dan_gao_use_heart") and effect.from:hasFlag("dan_gao_use_diamond")
            and effect.from:hasFlag("dan_gao_use_spade") and effect.from:hasFlag("dan_gao_use_club") then
            room:setPlayerFlag(effect.from, "dan_gao_used")
        end
    end,
}
sakamichi_dan_gao = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_dan_gao",
    filter_pattern = ".|.|.|hand",
    view_filter = function(self, to_select)
        return not sgs.Self:hasFlag("dan_gao_use_" .. to_select:getSuitString())
    end,
    view_as = function(self, card)
        local Card = sakamichi_dan_gaoCard:clone()
        Card:addSubcard(card:getId())
        Card:setSkillName(self:objectName())
        return Card
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("dan_gao_used")
    end,
}
AoiHarada_Keyakizaka:addSkill(sakamichi_dan_gao)

sakamichi_tang_niao_bing = sgs.CreateTriggerSkill {
    name = "sakamichi_tang_niao_bing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") then
            if not player:canDiscard(player, "he")
                or not room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@tang_niao_bing_discard") then
                room:loseHp(player, SKMC.number_correction(player, 1))
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_tang_niao_bing") then
    SKMC.SkillList:append(sakamichi_tang_niao_bing)
end
AoiHarada_Keyakizaka:addRelateSkill("sakamichi_tang_niao_bing")

sgs.LoadTranslationTable {
    ["AoiHarada_Keyakizaka"] = "原田 葵",
    ["&AoiHarada_Keyakizaka"] = "原田 葵",
    ["#AoiHarada_Keyakizaka"] = "变人人",
    ["~AoiHarada_Keyakizaka"] = "高2です～",
    ["designer:AoiHarada_Keyakizaka"] = "Cassimolar",
    ["cv:AoiHarada_Keyakizaka"] = "原田 葵",
    ["illustrator:AoiHarada_Keyakizaka"] = "Cassimolar",
    ["sakamichi_xiao_xue_sheng"] = "小学生",
    [":sakamichi_xiao_xue_sheng"] = "每名角色结束阶段，若其有手牌且其本回合内回复过体力，你可以摸两张牌并交给其一张手牌或令其摸一张牌并交给你两张手牌。",
    ["sakamichi_xiao_xue_sheng:@xiao_xue_sheng_invoke"] = "你可以摸两张牌并交给%src一张手牌，否则%src摸一张牌并交给你两张手牌",
    ["@xiao_xue_sheng_give_1"] = "请选择交给%src的一张手牌",
    ["@xiao_xue_sheng_give_2"] = "请选择交给%src的两张手牌",
    ["sakamichi_dan_gao"] = "蛋糕",
    [":sakamichi_dan_gao"] = "出牌阶段，你可以弃置一张本回合内未以此法弃置过的花色的手牌令一名受伤角色回复1点体力，一名角色以此法回复体力的牌花色达到四种时其获得【糖尿病】。",
    ["sakamichi_tang_niao_bing"] = "糖尿病",
    [":sakamichi_tang_niao_bing"] = "锁定技，你使用【桃】时须弃置一张牌或失去1点体力。",
    ["@tang_niao_bing_discard"] = "请弃置一张牌，否则将失去1点体力",
}
