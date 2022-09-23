require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

TenYamasaki_Keyakizaka = sgs.General(Sakamichi, "TenYamasaki_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.NiKiSei.TenYamasaki_Keyakizaka = true
SKMC.SeiMeiHanDan.TenYamasaki_Keyakizaka = {
    name = {3, 12, 4},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {4, "xiong"},
    soto_kaku = {7, "ji"},
    sou_kaku = {19, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_ding_dian = sgs.CreateTriggerSkill {
    name = "sakamichi_ding_dian",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isNDTrick() and use.to:length() > 1
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
            if not player:isKongcheng() then
                room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1, use.to)
            end
        end
        return false
    end,
}
TenYamasaki_Keyakizaka:addSkill(sakamichi_ding_dian)

sakamichi_zi_you = sgs.CreateTriggerSkill {
    name = "sakamichi_zi_you",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") then
            if player:hasFlag("zi_you_" .. SKMC.trueName(use.card)) then
                room:drawCards(player, 1, self:objectName())
            else
                room:setPlayerFlag(player, "zi_you_" .. SKMC.trueName(use.card))
            end
        end
        return false
    end,
}
sakamichi_zi_you_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_zi_you_target_mod",
    frequency = sgs.Skill_Compulsory,
    pattern = ".",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_zi_you") then
            return 1000
        else
            return 0
        end
    end,
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_jiu_xian") then
            return 1000
        else
            return 0
        end
    end,
}
TenYamasaki_Keyakizaka:addSkill(sakamichi_zi_you)
if not sgs.Sanguosha:getSkill("#sakamichi_zi_you_target_mod") then
    SKMC.SkillList:append(sakamichi_zi_you_target_mod)
end

sgs.LoadTranslationTable {
    ["TenYamasaki_Keyakizaka"] = "山﨑 天",
    ["&TenYamasaki_Keyakizaka"] = "山﨑 天",
    ["#TenYamasaki_Keyakizaka"] = "长女",
    ["~TenYamasaki_Keyakizaka"] = "一緒にやって頂けませんか？",
    ["designer:TenYamasaki_Keyakizaka"] = "Cassimolar",
    ["cv:TenYamasaki_Keyakizaka"] = "山﨑 天",
    ["illustrator:TenYamasaki_Keyakizaka"] = "Cassimolar",
    ["sakamichi_ding_dian"] = "顶点",
    [":sakamichi_ding_dian"] = "当你成为通常锦囊牌的目标时，若目标不唯一，你可以摸一张牌，然后你可以将一张手牌交给其中一个目标。",
    ["sakamichi_zi_you"] = "自由",
    [":sakamichi_zi_you"] = "锁定技，你使用牌无次数和距离限制。你的回合内，当你使用牌时，若你本回合内已使用过此牌名的牌，你摸一张牌。",
}
