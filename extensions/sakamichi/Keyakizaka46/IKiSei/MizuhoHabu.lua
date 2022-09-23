require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MizuhoHabu_Keyakizaka = sgs.General(Sakamichi, "MizuhoHabu_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.MizuhoHabu = true
SKMC.SeiMeiHanDan.MizuhoHabu = {
    name = {3, 5, 13, 15},
    ten_kaku = {8, "ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {28, "xiong"},
    soto_kaku = {18, "ji"},
    sou_kaku = {36, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_hou_gong = sgs.CreateTriggerSkill {
    name = "sakamichi_hou_gong",
    events = {sgs.Damage, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if player:hasSkill(self) and damage.to:isFemale() and damage.to:objectName() == player:objectName() then
                room:askForUseSlashTo(damage.to, player, "@hou_gong_slash:" .. player:objectName(), false)
            end
        else
            if player:isFemale() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:objectName() ~= p:objectName() then
                        room:drawCards(p, 1, self:objectName())
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
MizuhoHabu_Keyakizaka:addSkill(sakamichi_hou_gong)

sakamichi_jing_kong = sgs.CreateTriggerSkill {
    name = "sakamichi_jing_kong",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isNDTrick() then
                room:addPlayerMark(player, "jing_kong_damage_" .. damage.card:getId(), damage.damage)
            end
        else
            local use = data:toCardUse()
            if use.card:isNDTrick() then
                local count = player:getMark("jing_kong_damage_" .. use.card:getId())
                if count == 0 then
                    room:askForUseCard(player, "slash", "@askforslash")
                else
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:drawCards(player, count, self:objectName())
                    end
                end
            end
        end
        return false
    end,
}
MizuhoHabu_Keyakizaka:addSkill(sakamichi_jing_kong)

sakamichi_ju_ren = sgs.CreateTriggerSkill {
    name = "sakamichi_ju_ren",
    -- frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local can_trigger = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:getHp() > p:getHp() then
                    can_trigger = true
                    break
                end
            end
            if can_trigger and room:askForSkillInvoke(player, self:objectName(), data) then
                room:setPlayerFlag(player, "ju_ren")
                if not room:askForUseCard(player, "slash", "@ju_ren_slash") then
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                        "@ju_ren_damage_invoke:::" .. SKMC.number_correction(player, 1))
                    room:loseHp(player, SKMC.number_correction(player, 1))
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, SKMC.number_correction(player, 1)))
                end
                room:setPlayerFlag(player, "-ju_ren")
            end
        end
        return false
    end,
}
sakamichi_ju_ren_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_ju_ren_target_mod",
    pattern = "Slash",
    extra_target_func = function(self, from, card)
        if from:hasSkill("sakamichi_ju_ren") then
            return 1000
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasFlag("ju_ren") then
            return 1000
        else
            return 0
        end
    end,
}
MizuhoHabu_Keyakizaka:addSkill(sakamichi_ju_ren)
if not sgs.Sanguosha:getSkill("#sakamichi_ju_ren_target_mod") then
    SKMC.SkillList:append(sakamichi_ju_ren_target_mod)
end

sgs.LoadTranslationTable {
    ["MizuhoHabu_Keyakizaka"] = "土生 瑞穂",
    ["&MizuhoHabu_Keyakizaka"] = "土生 瑞穂",
    ["#MizuhoHabu_Keyakizaka"] = "神の子",
    ["~MizuhoHabu_Keyakizaka"] = "私もゴボウ！",
    ["designer:MizuhoHabu_Keyakizaka"] = "Cassimolar",
    ["cv:MizuhoHabu_Keyakizaka"] = "土生 瑞穂",
    ["illustrator:MizuhoHabu_Keyakizaka"] = "Cassimolar",
    ["sakamichi_hou_gong"] = "后宫",
    [":sakamichi_hou_gong"] = "锁定技，你对其他女性角色造成伤害后，其可以对你使用一张【杀】；其他女性角色回复体力时，你摸一张牌。",
    ["@hou_gong_slash"] = "你可以对%src使用一张【杀】",
    ["sakamichi_jing_kong"] = "惊恐",
    [":sakamichi_jing_kong"] = "你使用通常锦囊牌结算完成时，若此牌：未造成伤害，你可以使用一张【杀】；造成伤害，你可以摸X张牌（X为此牌造成的伤害量）。",
    ["sakamichi_ju_ren"] = "巨人",
    [":sakamichi_ju_ren"] = "你使用【杀】时无目标上限。准备阶段，若你的体力不为全场最少，你可以使用一张无距离限制的【杀】或失去1点体力对一名其他角色造成1点伤害。",
    ["@ju_ren_slash"] = "你可以使用一张无距离限制的【杀】",
    ["@ju_ren_damage_invoke"] = "你可以选择一名其他角色对其造成%arg点伤害",
}
