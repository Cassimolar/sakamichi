require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YukaSugai_Sakurazaka = sgs.General(Sakamichi, "YukaSugai_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.IKiSei.YukaSugai_Sakurazaka = true
SKMC.SeiMeiHanDan.YukaSugai_Sakurazaka = {
    name = {11, 4, 4, 9},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {8, "ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {28, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_ma_li = sgs.CreateTriggerSkill {
    name = "sakamichi_ma_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
            local index = 1
            local n = 0
            if player:getOffensiveHorse() then
                n = n + 1
            end
            if player:getDefensiveHorse() then
                n = n + 1
            end
            if n ~= 0 then
                for _, p in sgs.qlist(use.to) do
                    if jink_table[index] == 1 then
                        jink_table[index] = 1 + n
                    end
                    index = index + 1
                end
                local jink_data = sgs.QVariant()
                jink_data:setValue(SKMC.table_to_IntList(jink_table))
                player:setTag("Jink_" .. use.card:toString(), jink_data)
            end
        end
        return false
    end,
}
sakamichi_ma_liDistance = sgs.CreateDistanceSkill {
    name = "#sakamichi_ma_liDistance",
    correct_func = function(self, from, to)
        if from:hasSkill("sakamichi_ma_li") and from:getDefensiveHorse() then
            return -1
        end
        if to:hasSkill("sakamichi_ma_li") and to:getOffensiveHorse() then
            return 1
        end
    end,
}
YukaSugai_Sakurazaka:addSkill(sakamichi_ma_li)
if not sgs.Sanguosha:getSkill("#sakamichi_ma_liDistance") then
    SKMC.SkillList:append(sakamichi_ma_liDistance)
end

sakamichi_wu_lang = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_lang",
    events = {sgs.EventPhaseStart, sgs.DamageCaused, sgs.CardFinished, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                player:setGender(sgs.General_Male)
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                if player:getGender() == damage.to:getGender() then
                    room:setCardFlag(damage.card, "wu_lang")
                else
                    if damage.to:isWounded() then
                        room:recover(damage.to, sgs.RecoverStruct(player, damage.card,
                            math.min(damage.damage, damage.to:getLostHp())))
                        return true
                    end
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") then
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            player:setGender(sgs.General_Female)
        end
        return false
    end,
}
YukaSugai_Sakurazaka:addSkill(sakamichi_wu_lang)

sakamichi_hui_mou = sgs.CreateTriggerSkill {
    name = "sakamichi_hui_mou",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:faceUp() and room:askForSkillInvoke(player, self:objectName(), data) then
            player:turnOver()
            local n = SKMC.number_correction(player, 1)
            if damage.damage == n then
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:isWounded() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(),
                        "@hui_mou_invoke:::" .. n, true, false)
                    if target then
                        room:recover(target, sgs.RecoverStruct(player, damage.card, n))
                    end
                end
            end
            return true
        end
        return false
    end,
}
YukaSugai_Sakurazaka:addSkill(sakamichi_hui_mou)

sgs.LoadTranslationTable {
    ["YukaSugai_Sakurazaka"] = "菅井 友香",
    ["&YukaSugai_Sakurazaka"] = "菅井 友香",
    ["#YukaSugai_Sakurazaka"] = "富婆",
    ["~YukaSugai_Sakurazaka"] = "何かご用ですか？",
    ["designer:YukaSugai_Sakurazaka"] = "Cassimolar",
    ["cv:YukaSugai_Sakurazaka"] = "菅井 友香",
    ["illustrator:YukaSugai_Sakurazaka"] = "Cassimolar",
    ["sakamichi_ma_li"] = "马力",
    [":sakamichi_ma_li"] = "锁定技，你的进攻马/防御马额外使其他角色计算与你的距离+1/你计算与其他角色的距离-1。你装备区每有一张坐骑牌，你使用的【杀】需要额外使用一张【闪】才能抵消。",
    ["sakamichi_wu_lang"] = "五郎",
    [":sakamichi_wu_lang"] = "你的回合内，你对与你性别相同/不同的角色使用【杀】造成伤害时，此【杀】不计入次数限制/防止此伤害并为其回复等量体力值。准备阶段，你可以将性别改为男性。结束阶段，你将性别改为女性。",
    ["sakamichi_hui_mou"] = "回眸",
    [":sakamichi_hui_mou"] = "当你受到伤害时，若你正面向上，你可以翻面并防止此次伤害，若此次伤害量为1，你可以令一名其他角色回复1点体力。",
    ["@hui_mou_invoke"] = "你可以令一名其他角色回复%arg点体力",
}
