require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaayaWada = sgs.General(Sakamichi, "MaayaWada", "Nogizaka46", 4, false)
SKMC.IKiSei.MaayaWada = true
SKMC.SeiMeiHanDan.MaayaWada = {
    name = {8, 5, 4, 3, 3},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {9, "xiong"},
    ji_kaku = {10, "xiong"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {23, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_mo_fang = sgs.CreateTriggerSkill {
    name = "sakamichi_mo_fang",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@mo_fang_invoke", true, true)
            if target then
                local mofang_skill_List = {}
                if player:getMark("mo_fang_once") == 0 then
                    for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                        if not skill:isLordSkill() then
                            table.insert(mofang_skill_List, skill:objectName())
                        end
                    end
                else
                    for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                        if not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency()
                            ~= sgs.Skill_Limited and not skill:isShiMingSkill() then
                            table.insert(mofang_skill_List, skill:objectName())
                        end
                    end
                end
                local new_Skill = room:askForChoice(player, self:objectName(), table.concat(mofang_skill_List, "+"))
                SKMC.choice_log(player, new_Skill)
                local Skill_list = {}
                local old_Skill = player:getTag("mo_fang_skill"):toString()
                if old_Skill ~= "" then
                    table.insert(Skill_list, "-" .. old_Skill)
                end
                if new_Skill ~= "" then
                    local skill = sgs.Sanguosha:getSkill(new_Skill)
                    if skill:getFrequency() == sgs.Skill_Wake or skill:getFrequency() == sgs.Skill_Limited
                        or skill:isShiMingSkill() then
                        room:setPlayerMark(player, "mo_fang_once", 1)
                    end
                    player:setTag("mo_fang_skill", sgs.QVariant(new_Skill))
                    table.insert(Skill_list, new_Skill)
                end
                room:handleAcquireDetachSkills(player, table.concat(Skill_list, "|"), true)
            end
        end
    end,
}
MaayaWada:addSkill(sakamichi_mo_fang)

sakamichi_ma_ya_card = sgs.CreateSkillCard {
    name = "sakamichi_ma_yaCard",
    skill_name = "sakamichi_ma_ya",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            for _, skill in sgs.qlist(to_select:getVisibleSkillList()) do
                if (skill:getFrequency() == sgs.Skill_Limited and to_select:getMark(skill:getLimitMark()) == 0)
                    or (skill:getFrequency() == sgs.Skill_Wake and to_select:getMark(skill:objectName()) == 0)
                    or (skill:isShiMingSkill() and to_select:getMark(skill:objectName()) == 0) then
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@ma_ya")
        local skill_names = {}
        for _, skill in sgs.qlist(effect.to:getVisibleSkillList()) do
            if (skill:getFrequency() == sgs.Skill_Limited and effect.to:getMark(skill:getLimitMark()) == 0)
                or (skill:getFrequency() == sgs.Skill_Wake and effect.to:getMark(skill:objectName()) == 0)
                or (skill:isShiMingSkill() and effect.to:getMark(skill:objectName()) == 0) then
                table.insert(skill_names, skill:objectName())
            end
        end
        local skill_name = room:askForChoice(effect.from, self:getSkillName(), table.concat(skill_names, "+"))
        SKMC.choice_log(effect.from, skill_name)
        local skill = sgs.Sanguosha:getSkill(skill_name)
        if skill:getFrequency() == sgs.Skill_Limited then
            room:setPlayerMark(effect.to, skill:getLimitMark(), 1)
        elseif skill:getFrequency() == sgs.Skill_Wake then
            effect.to:setCanWake(self:getSkillName(), skill:objectName())
        elseif skill:isShiMingSkill() then
            room:sendShimingLog(effect.to, skill)
        end
    end,
}
sakamichi_ma_ya = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ma_ya",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ma_ya",
    view_as = function(self)
        return sakamichi_ma_ya_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@ma_ya") ~= 0
    end,
}
MaayaWada:addSkill(sakamichi_ma_ya)

sgs.LoadTranslationTable {
    ["MaayaWada"] = "和田 まあや",
    ["&MaayaWada"] = "和田 まあや",
    ["#MaayaWada"] = "笨蛋天才",
    ["~MaayaWada"] = "天才とは、1％のひらめきと99％の運",
    ["designer:MaayaWada"] = "Cassimolar",
    ["cv:MaayaWada"] = "和田 まあや",
    ["illustrator:MaayaWada"] = "Cassimolar",
    ["sakamichi_mo_fang"] = "模仿",
    [":sakamichi_mo_fang"] = "准备阶段，你可以选择一名其他角色并获得其一个武将技能（主公技除外）直到你下次选择，你以此法仅可以获得一次限定技、觉醒技、使命技。",
    ["@mo_fang_invoke"] = "你可以选择一名其他角色获得其一个武将技能",
    ["sakamichi_ma_ya"] = "妈呀",
    [":sakamichi_ma_ya"] = "限定技，出牌阶段，你可以选择一名拥有已发动过限定技或未觉醒的觉醒技的角色，令其一个已发动过限定技视为未曾发动或未觉醒的觉醒技视为满足觉醒条件。",
    ["@ma_ya"] = "妈呀",
}
