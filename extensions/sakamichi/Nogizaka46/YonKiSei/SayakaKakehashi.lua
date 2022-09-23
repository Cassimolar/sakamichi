require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SayakaKakehashi = sgs.General(Sakamichi, "SayakaKakehashi", "Nogizaka46", 4, false)
SKMC.YonKiSei.SayakaKakehashi = true
SKMC.SeiMeiHanDan.SayakaKakehashi = {
    name = {11, 16, 7, 9, 9},
    ten_kaku = {27, "ji_xiong_hun_he"},
    jin_kaku = {23, "ji"},
    ji_kaku = {25, "ji"},
    soto_kaku = {29, "te_shu_ge"},
    sou_kaku = {52, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_hao_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_hao_shi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") then
            if player:hasSkill(self) then
                if player:faceUp() then
                    player:turnOver()
                end
                room:setPlayerChained(player, false)
                room:drawCards(player, 1, self:objectName())
            end
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() then
                    room:setPlayerMark(p, self:objectName(), 1)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_hao_shi_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_hao_shi_card_limit",
    limit_list = function(self, player)
        if player:hasSkill("sakamichi_hao_shi") then
            if player:getMark("sakamichi_hao_shi") == 0 then
                return "use"
            end
        end
        return ""
    end,
    limit_pattern = function(self, player)
        if player:hasSkill("sakamichi_hao_shi") then
            if player:getMark("sakamichi_hao_shi") == 0 then
                return "Peach"
            end
        end
        return ""
    end,
}
SayakaKakehashi:addSkill(sakamichi_hao_shi)
if not sgs.Sanguosha:getSkill("#sakamichi_hao_shi_card_limit") then
    SKMC.SkillList:append(sakamichi_hao_shi_card_limit)
end

sakamichi_huan_xing_card = sgs.CreateSkillCard {
    name = "sakamichi_huan_xingCard",
    skill_name = "sakamichi_huan_xing",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.to:turnOver()
        room:damage(
            sgs.DamageStruct(self:getSkillName(), effect.to, effect.from, SKMC.number_correction(effect.from, 1)))
        if effect.to:faceUp() then
            room:addPlayerMark(effect.to, "huan_xing_start_start_clear", 1)
        end
    end,
}
sakamichi_huan_xing_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_huan_xing",
    view_as = function()
        return sakamichi_huan_xing_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_huan_xingCard")
    end,
}
sakamichi_huan_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_huan_xing",
    view_as_skill = sakamichi_huan_xing_view_as,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("huan_xing_start_start_clear") ~= 0 then
                    p:gainAnExtraTurn()
                    p:turnOver()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SayakaKakehashi:addSkill(sakamichi_huan_xing)

sgs.LoadTranslationTable {
    ["SayakaKakehashi"] = "掛橋 沙耶香",
    ["&SayakaKakehashi"] = "掛橋 沙耶香",
    ["#SayakaKakehashi"] = "熊孩子",
    ["~SayakaKakehashi"] = "血の味がします",
    ["designer:SayakaKakehashi"] = "Cassimolar",
    ["cv:SayakaKakehashi"] = "掛橋 沙耶香",
    ["illustrator:SayakaKakehashi"] = "Cassimolar",
    ["sakamichi_hao_shi"] = "豪食",
    [":sakamichi_hao_shi"] = "锁定技，其他角色使用过【桃】前，你无法使用【桃】。你使用【桃】时复原武将牌且摸一张牌。",
    ["sakamichi_huan_xing"] = "唤醒",
    [":sakamichi_huan_xing"] = "出牌阶段限一次，你可以令一名角色翻面并受到其造成的1点伤害，然后若其武将牌正面向上，本回合结束时其执行一个额外的回合并翻面。",
}
