require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkaneMoriya_Sakurazaka = sgs.General(Sakamichi, "AkaneMoriya_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.IKiSei.AkaneMoriya_Sakurazaka = true
SKMC.SeiMeiHanDan.AkaneMoriya_Sakurazaka = {
    name = {6, 9, 9},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {9, "xiong"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji",
    },
}

sakamichi_ren_nai = sgs.CreateTriggerSkill {
    name = "sakamichi_ren_nai",
    events = {sgs.Damaged, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Fire
                and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:::" .. damage.damage)) then
                room:drawCards(player, damage.damage, self:objectName())
            end
        else
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Normal
                and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("fire")) then
                damage.nature = sgs.DamageStruct_Fire
                data:setValue(damage)
            end
        end
        return false
    end,
}
AkaneMoriya_Sakurazaka:addSkill(sakamichi_ren_nai)

sakamichi_ying_dun = sgs.CreateTriggerSkill {
    name = "sakamichi_ying_dun",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ying_dun",
    events = {sgs.TargetConfirming, sgs.CardUsed, sgs.DamageCaused, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:length() == 1 and use.to:contains(player)
                and use.from:objectName() ~= player:objectName() then
                if player:getMark("@ying_dun") ~= 0 then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:removePlayerMark(player, "@ying_dun")
                        room:setPlayerMark(player, "ying_dun_slash", 1)
                        room:setPlayerMark(player, "ying_dun_damagetrick", 1)
                        room:setPlayerMark(player, "@ying_dun_on", 1)
                        local nullified_list = use.nullified_list
                        table.insert(nullified_list, player:objectName())
                        use.nullified_list = nullified_list
                        data:setValue(use)
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:getMark("ying_dun_slash") ~= 0 then
                room:setPlayerMark(player, "ying_dun_slash", 0)
                room:setPlayerMark(player, "ying_dun_damagetrick", 0)
                room:setCardFlag(use.card, "ying_dun")
                room:setPlayerMark(player, "@ying_dun_on", 0)
            end
            if use.card:isNDTrick() and use.card:isDamageCard() and player:getMark("ying_dun_damagetrick") ~= 0 then
                room:setPlayerMark(player, "ying_dun_damagetrick", 0)
                room:setPlayerMark(player, "ying_dun_slash", 0)
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS")
                use.no_respond_list = no_respond_list
                data:setValue(use)
                room:setPlayerMark(player, "@ying_dun_on", 0)
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("ying_dun") then
                damage.damage = damage.damage + SKMC.number_correction(player, 1)
                room:setCardFlag(damage.card, "-ying_dun")
                data:setValue(damage)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:getMark("@ying_dun_on") ~= 0 then
                if player:isWounded() then
                    room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                end
            end
        end
        return false
    end,
}
sakamichi_ying_dun_protect = sgs.CreateProhibitSkill {
    name = "#sakamichi_ying_dun_protect",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_ying_dun") and from:objectName() ~= to:objectName() and to:getMark("ying_dun_on")
                   ~= 0 and (card:isKindOf("Slash") or card:isNDTrick())
    end,
}
AkaneMoriya_Sakurazaka:addSkill(sakamichi_ying_dun)
if not sgs.Sanguosha:getSkill("#sakamichi_ying_dun_protect") then
    SKMC.SkillList:append(sakamichi_ying_dun_protect)
end

sakamichi_yang_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_yang_sheng",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        n = n + math.floor(player:getEquips():length() / SKMC.number_correction(player, 2))
        data:setValue(n)
        return false
    end,
}
sakamichi_yang_sheng_max = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_yang_sheng_max",
    extra_func = function(self, target)
        if target:hasSkill("sakamichi_yang_sheng") then
            return target:getEquips():length()
        end
    end,
}
AkaneMoriya_Sakurazaka:addSkill(sakamichi_yang_sheng)
if not sgs.Sanguosha:getSkill("#sakamichi_yang_sheng_max") then
    SKMC.SkillList:append(sakamichi_yang_sheng_max)
end

sgs.LoadTranslationTable {
    ["AkaneMoriya_Sakurazaka"] = "守屋 茜",
    ["&AkaneMoriya_Sakurazaka"] = "守屋 茜",
    ["#AkaneMoriya_Sakurazaka"] = "暗影疾行",
    ["~AkaneMoriya_Sakurazaka"] = "これマラソンなんで",
    ["designer:AkaneMoriya_Sakurazaka"] = "Cassimolar",
    ["cv:AkaneMoriya_Sakurazaka"] = "守屋 茜",
    ["illustrator:AkaneMoriya_Sakurazaka"] = "Cassimolar",
    ["sakamichi_ren_nai"] = "忍耐",
    [":sakamichi_ren_nai"] = "当你受到1点火焰伤害后，你可以摸一张牌；你受到无属性伤害时，你可以令此伤害为火焰伤害。",
    ["sakamichi_ren_nai:draw"] = "是否发动【忍耐】摸%arg张牌",
    ["sakamichi_ren_nai:fire"] = "是否发动【忍耐】令此次伤害为火焰伤害",
    ["sakamichi_ying_dun"] = "影遁",
    [":sakamichi_ying_dun"] = "限定技，当你成为其他角色使用的【杀】或通常锦囊牌的唯一目标时，你可以令此牌对你无效，若如此做，直到你下次使用【杀或伤害类锦囊时：你不是其他角色使用基本牌或通常锦囊牌的合法；你使用的下一张【杀】／伤害类锦囊伤害＋１／无法响应；准备阶段，你回复１点体力。",
    ["@ying_dun"] = "影遁",
    ["@ying_dun_on"] = "影遁",
    ["sakamichi_yang_sheng"] = "养生",
    [":sakamichi_yang_sheng"] = "锁定技，你的手牌上限+X；摸牌阶段，你额外摸X/2张牌（向下取整，X为你装备区的装备牌数）。",
}
