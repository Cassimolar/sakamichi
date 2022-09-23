require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaiShinnuchi = sgs.General(Sakamichi, "MaiShinnuchi", "Nogizaka46", 4, false)
SKMC.NiKiSei.MaiShinnuchi = true
SKMC.SeiMeiHanDan.MaiShinnuchi = {
    name = {13, 4, 10, 6},
    ten_kaku = {17, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_dao_shui = sgs.CreateTriggerSkill {
    name = "sakamichi_dao_shui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.SlashMissed},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toSlashEffect()
        local card
        if not player:getDefensiveHorse() and effect.to:getDefensiveHorse() then
            card = effect.to:getDefensiveHorse()
        end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
            "invoke:" .. effect.to:objectName() .. "::" .. self:objectName() .. ":" .. card:toString())) then
            room:obtainCard(player, card, true)
        end
        card = nil
        if not player:getOffensiveHorse() and effect.to:getOffensiveHorse() then
            card = effect.to:getOffensiveHorse()
        end
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
            "invoke:" .. effect.to:objectName() .. "::" .. self:objectName() .. ":" .. card:toString())) then
            room:obtainCard(player, card, true)
        end
    end,
}
MaiShinnuchi:addSkill(sakamichi_dao_shui)

sakamichi_chang_tui_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_chang_tui_target_mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Slash",
    extra_target_func = function(self, player, card)
        if player:hasSkill("sakamichi_chang_tui") then
            return player:getMark("&" .. "sakamichi_chang_tui")
        else
            return 0
        end
    end,
}
sakamichi_chang_tui = sgs.CreateTriggerSkill {
    name = "sakamichi_chang_tui",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Horse") then
            room:addPlayerMark(player, "&" .. self:objectName(), 1)
        end
        return false
    end,
}
MaiShinnuchi:addSkill(sakamichi_chang_tui)
if not sgs.Sanguosha:getSkill("#sakamichi_chang_tui_target_mod") then
    SKMC.SkillList:append(sakamichi_chang_tui_target_mod)
end

sgs.LoadTranslationTable {
    ["MaiShinnuchi"] = "新内 眞衣",
    ["&MaiShinnuchi"] = "新内 眞衣",
    ["#MaiShinnuchi"] = "零期生",
    ["~MaiShinnuchi"] = "OL、アイドル  明日からもよろしくお願いします！",
    ["designer:MaiShinnuchi"] = "Cassimolar",
    ["cv:MaiShinnuchi"] = "新内 眞衣",
    ["illustrator:MaiShinnuchi"] = "Cassimolar",
    ["sakamichi_dao_shui"] = "盗水",
    [":sakamichi_dao_shui"] = "当你使用的【杀】被闪避时，若目标装备区有坐骑牌，且你对应区域无坐骑牌，你可以获得之。",
    ["sakamichi_dao_shui:invoke"] = "是否发动【%arg】获得%src 的【%arg2】",
    ["sakamichi_chang_tui"] = "长腿",
    [":sakamichi_chang_tui"] = "锁定技，你使用的【杀】可以多指定X个目标（X为你使用过的坐骑牌数）。",
}
