require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SatsukiSugawara = sgs.General(Sakamichi, "SatsukiSugawara", "Nogizaka46", 3, false)
SKMC.GoKiSei.SatsukiSugawara = true
SKMC.SeiMeiHanDan.SatsukiSugawara = {
    name = {11, 10, 9, 4},
    ten_kaku = {21, "ji"},
    jin_kaku = {19, "xiong"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {34, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "huo",
        san_sai = "xiong",
    },
}

sakamichi_tong_cheCard = sgs.CreateSkillCard {
    name = "sakamichi_tong_cheCard",
    skill_name = "sakamichi_tong_che",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local target = effect.to
        local is_male = target:isMale()
        local suit
        if not is_male then
            local result = SKMC.run_judge(room, target, self:getSkillName(), ".")
            suit = result.card:getSuit()
        end
        if is_male or suit == sgs.Card_Spade then
            target:turnOver()
        end
        if is_male or suit == sgs.Card_Heart then
            if target:isWounded() then
                room:recover(target, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
            end
        end
        if is_male or suit == sgs.Card_Club then
            local choices = {}
            if not target:isKongcheng() then
                table.insert(choices, "throw_handcard")
            end
            if not target:getEquips():isEmpty() then
                table.insert(choices, "throw_equip")
            end
            if #choices ~= 0 then
                local choice = room:askForChoice(target, self:getSkillName(), table.concat(choices, "+"))
                if choice == "throw_handcard" then
                    target:throwAllHandCards()
                elseif choice == "throw_equip" then
                    target:throwAllEquips()
                end
            end
        end
        if is_male or suit == sgs.Card_Diamond then
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, target,
                SKMC.number_correction(effect.from, 1)))
        end
    end,
}
sakamichi_tong_che = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_tong_che",
    view_as = function(self)
        return sakamichi_tong_cheCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_tong_cheCard") and player:getEquips():isEmpty()
    end,
}
SatsukiSugawara:addSkill(sakamichi_tong_che)

sakamichi_xiao_ji_sugawara = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_ji_sugawara",
    frequency = sgs.Skill_Compulsory,
    priority = {1, 1, -1},
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.FinishRetrial},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or event == sgs.EventAcquireSkill then
            room:handleAcquireDetachSkills(player, "#sakamichi_xiao_ji_sugawara_revise", false)
        elseif event == sgs.FinishRetrial and player:hasSkill(self) then
            local judge = data:toJudge()
            room:setCardFlag(judge.card, "xiao_ji_sugawara")
            local cardlists = sgs.CardList()
            cardlists:append(judge.card)
            room:filterCards(judge.who, cardlists, true)
            judge:updateResult()
            SKMC.send_message(room, "$JudgeResult", player, nil, nil, judge.card:toString())
        end
        return false
    end,
}
sakamichi_xiao_ji_sugawara_revise = sgs.CreateFilterSkill {
    name = "#sakamichi_xiao_ji_sugawara_revise",
    view_filter = function(self, to_select)
        return to_select:hasFlag("xiao_ji_sugawara")
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName("sakamichi_xiao_ji")
        new_card:setSuit(sgs.Card_Diamond)
        new_card:setNumber(5)
        new_card:setModified(true)
        return new_card
    end,
}
SatsukiSugawara:addSkill(sakamichi_xiao_ji_sugawara)
if not sgs.Sanguosha:getSkill("#sakamichi_xiao_ji_sugawara_revise") then
    SKMC.SkillList:append(sakamichi_xiao_ji_sugawara_revise)
end

sgs.LoadTranslationTable {
    ["SatsukiSugawara"] = "菅原 咲月",
    ["&SatsukiSugawara"] = "菅原 咲月",
    ["#SatsukiSugawara"] = "直播鬼才",
    ["~SatsukiSugawara"] = "小吉でした",
    ["designer:SatsukiSugawara"] = "Cassimolar",
    ["cv:SatsukiSugawara"] = "菅原 咲月",
    ["illustrator:SatsukiSugawara"] = "Cassimolar",
    ["sakamichi_tong_che"] = "童车",
    [":sakamichi_tong_che"] = "出牌阶段限一次，若你未装备防具，你可以选择一名其他角色令其判定，若结果为：黑桃，其翻面；红桃，其回复1点体力；梅花，其选择弃置所有手牌或装备；方块，其受到1点伤害。若其为男性，其无需判定并执行所有分支。",
    ["sakamichi_xiao_ji_sugawara"] = "小吉",
    [":sakamichi_xiao_ji_sugawara"] = "锁定技，你的判定结果始终为方块5。",
}
