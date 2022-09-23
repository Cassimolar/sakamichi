require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YukiYoda = sgs.General(Sakamichi, "YukiYoda$", "Nogizaka46", 3, false)
SKMC.SanKiSei.YukiYoda = true
SKMC.SeiMeiHanDan.YukiYoda = {
    name = {3, 5, 9, 7},
    ten_kaku = {8, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

YukiYoda:addSkill("sakamichi_shen_jing")

sakamichi_bu_she_yuki_yoda = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_she_yuki_yoda",
    frequency = sgs.Skill_Frequent,
    shiming_skill = true,
    waked_skills = "sakamichi_she_rou",
    events = {sgs.SlashMissed, sgs.SlashHit, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if effect.slash:isBlack() and effect.from and effect.from:isAlive() and effect.to
                and effect.to:hasSkill(self) and effect.to:getMark(self:objectName()) == 0 then
                room:askForUseSlashTo(effect.to, effect.from, "@bu_she_yuki_yoda_invoke:" .. effect.from:objectName(),
                    false, false, true, nil, nil, "bu_she_yuki_yoda")
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("bu_she_yuki_yoda") and effect.from and effect.from:hasSkill(self)
                and effect.from:getMark(self:objectName()) == 0 then
                room:sendShimingLog(effect.from, self)
                room:gainMaxHp(effect.from, SKMC.number_correction(effect.from, 1))
                room:recover(effect.from, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
                room:handleAcquireDetachSkills(effect.from, "sakamichi_she_rou")
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:isBlack() and player:hasSkill(self)
                and player:getMark(self:objectName()) == 0 then
                room:sendShimingLog(player, self, false)
                room:loseHp(player, player:getHp())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YukiYoda:addSkill(sakamichi_bu_she_yuki_yoda)

sakamichi_she_rou_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_she_rou",
    view_as = function(self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("she_rou_used") and sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason()
                   == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and not player:hasFlag("she_rou_used")
    end,
}
sakamichi_she_rou = sgs.CreateTriggerSkill {
    name = "sakamichi_she_rou",
    view_as_skill = sakamichi_she_rou_view_as,
    events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("she_rou_used") then
                        room:setPlayerFlag(p, "-she_rou_used")
                    end
                end
            end
        else
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                if use.card:getSkillName() == self:objectName() then
                    card = use.card
                end
            else
                local response = data:toCardResponse()
                if response.m_card:getSkillName() == self:objectName() then
                    card = response.m_card
                end
            end
            if card then
                room:setPlayerFlag(player, "she_rou_used")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_she_rou") then
    SKMC.SkillList:append(sakamichi_she_rou)
end

sakamichi_ye_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_ye_xing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardFinished, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.card:hasFlag("ye_xing") then
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
                room:setCardFlag(use.card, "-ye_xing")
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if player:getPhase() ~= sgs.Player_NotActive and damage.card and damage.card:isKindOf("Slash") then
                room:setCardFlag(damage.card, "ye_xing")
            end
        end
        return false
    end,
}
sakamichi_ye_xing_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_ye_xing_distance",
    correct_func = function(self, from, to)
        if from:hasSkill("sakamichi_ye_xing") then
            return -SKMC.number_correction(from, 1)
        end
    end,
}
YukiYoda:addSkill(sakamichi_ye_xing)
if not sgs.Sanguosha:getSkill("#sakamichi_ye_xing_distance") then
    SKMC.SkillList:append(sakamichi_ye_xing_distance)
end

sgs.LoadTranslationTable {
    ["YukiYoda"] = "与田 祐希",
    ["&YukiYoda"] = "与田 祐希",
    ["#YukiYoda"] = "天下第一",
    ["~YukiYoda"] = "ちっちゃいけど色気はあるとよ!",
    ["designer:YukiYoda"] = "Cassimolar",
    ["cv:YukiYoda"] = "与田 祐希",
    ["illustrator:YukiYoda"] = "Cassimolar",
    ["sakamichi_bu_she_yuki_yoda"] = "捕蛇",
    [":sakamichi_bu_she_yuki_yoda"] = "使命技，当你闪避黑色【杀】后，你可以对此【杀】使用者使用一张【杀】。成功：当你以此法使用的【杀】命中后，你增加1点体力上限并回复1点体力，然后获得【蛇肉】。失败：当你受到黑色【杀】造成的伤害后，失去所有体力。",
    ["@bu_she_yuki_yoda_invoke"] = "你可以对%src使用一张【杀】",
    ["sakamichi_she_rou"] = "蛇肉",
    [":sakamichi_she_rou"] = "<font color=\"#008000\"><b>每回合限一次</b></font>，当你需要使用或打出一张【杀】时，你可以视为使用或打出一张【杀】。",
    ["sakamichi_ye_xing"] = "野性",
    [":sakamichi_ye_xing"] = "锁定技，你计算与其他角色的距离-1。你的回合内，当你使用【杀】造成伤害后，此【杀】不计入使用次数限制。",
}
