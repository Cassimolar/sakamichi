require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RanzeTerada = sgs.General(Sakamichi, "RanzeTerada", "Nogizaka46", 3, false)
SKMC.NiKiSei.RanzeTerada = true
SKMC.SeiMeiHanDan.RanzeTerada = {
    name = {6, 5, 19, 5},
    ten_kaku = {11, "ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "da_ji",
    },
}

sakamichi_luan_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_luan_shi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            local can = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getRole() == "rebel" then
                    can = true
                    break
                end
            end
            if can and room:askForSkillInvoke(player, self:objectName(), data) then
                if room:askForChoice(player, self:objectName(), "draw+play") == "draw" then
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Draw)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                else
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Play)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                end
            end
        end
        return false
    end,
}
RanzeTerada:addSkill(sakamichi_luan_shi)

sakamichi_bai_tou_xie_lao = sgs.CreateTriggerSkill {
    name = "sakamichi_bai_tou_xie_lao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@bai_tou",
    events = {sgs.EventPhaseStart, sgs.DamageInflicted, sgs.DamageComplete, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:hasSkill(self) then
                if player:getMark("bai_tou_xie_lao_invoke") == 0 then
                    if player:getCards("he"):length() > 2 and room:askForSkillInvoke(player, self:objectName(), data) then
                        room:removePlayerMark(player, "@bai_tou")
                        room:setPlayerMark(player, "bai_tou_xie_lao_invoke", 1)
                        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
                        room:addPlayerMark(target, "@xie_lao")
                        local tagvalue = sgs.QVariant()
                        tagvalue:setValue(target)
                        room:setTag(player:objectName() .. "bai_tou_xie_lao_target", tagvalue)
                        local card = room:askForExchange(player, self:objectName(), 2, 2, true, "@bai_tou_xie_lao_give")
                        room:obtainCard(target, card, false)
                    end
                end
            end
        elseif event == sgs.DamageInflicted then
            if player:hasSkill(self:objectName(), true) then
                local tag = room:getTag(player:objectName() .. "bai_tou_xie_lao_target")
                if tag then
                    local target = tag:toPlayer()
                    if target then
                        room:setPlayerFlag(target, "bai_tou_xie_lao")
                        if player:objectName() ~= target:objectName() then
                            local damage = data:toDamage()
                            damage.to = target
                            damage.transfer = true
                            room:damage(damage)
                            return true
                        end
                    end
                end
            end
        elseif event == sgs.DamageComplete then
            if player:hasFlag("bai_tou_xie_lao") then
                local damage = data:toDamage()
                room:drawCards(player, damage.damage, self:objectName())
                room:setPlayerFlag(player, "-bai_tou_xie_lao")
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if player:getMark("@xie_lao") > 0 and player:objectName() == dying.who:objectName() then
                room:removePlayerMark(player, "@xie_lao")
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasSkill(self:objectName(), true) then
                        local tag = room:getTag(p:objectName() .. "bai_tou_xie_lao_target")
                        local target = tag:toPlayer()
                        if target and target:objectName() == player:objectName() then
                            room:removeTag(p:objectName() .. "bai_tou_xie_lao_target")
                        end
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
RanzeTerada:addSkill(sakamichi_bai_tou_xie_lao)

sakamichi_bao_yan_card = sgs.CreateSkillCard {
    name = "sakamcihi_bao_yanCard",
    skill_name = "sakamichi_bao_yan",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@bao_yan", 1)
        if effect.to:objectName() == effect.from:objectName() then
            room:setPlayerMark(effect.to, "&number_correction_locking", 100)
            SKMC.send_message(room, "#number_correction_locking", effect.from, effect.to, nil, nil, self:getSkillName(),
                100)
        else
            room:addPlayerMark(effect.to, "&number_correction_plus", SKMC.number_correction(effect.from, 1))
            SKMC.send_message(room, "#number_correction_plus", effect.from, effect.to, nil, nil, self:getSkillName(), 1)
        end
    end,
}
sakamichi_bao_yan = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_bao_yan",
    frequency = sgs.Skill_Limited,
    limit_mark = "@bao_yan",
    view_as = function(self)
        return sakamichi_bao_yan_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@bao_yan") ~= 0
    end,
}
RanzeTerada:addSkill(sakamichi_bao_yan)

sakamichi_zi_xing_che = sgs.CreateTriggerSkill {
    name = "sakamichi_zi_xing_che",
    frequency = sgs.Skill_Wake,
    events = {sgs.Damage},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            if not damage.to:inMyAttackRange(player) then
                return true
            end
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerMark(player, self:objectName(), 1)
        room:addPlayerMark(player, "zi_xing_che", 1)
        SKMC.send_message(room, "#zi_xing_che", player, nil, nil, nil, self:objectName())
    end,
}
sakamichi_zi_xing_che_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_zi_xing_che_distance",
    correct_func = function(self, from, to)
        if from:getMark("zi_xing_che") ~= 0 then
            return -SKMC.number_correction(from, 1)
        end
    end,
}
sakamichi_zi_xing_che_attack_range = sgs.CreateAttackRangeSkill {
    name = "#sakamichi_zi_xing_che_attack_range",
    extra_func = function(self, player, include_weapon)
        if player:getMark("zi_xing_che") ~= 0 then
            return SKMC.number_correction(player, 1)
        end
    end,
}
RanzeTerada:addSkill(sakamichi_zi_xing_che)
if not sgs.Sanguosha:getSkill("#sakamichi_zi_xing_che_distance") then
    SKMC.SkillList:append(sakamichi_zi_xing_che_distance)
end
if not sgs.Sanguosha:getSkill("#sakamichi_zi_xing_che_attack_range") then
    SKMC.SkillList:append(sakamichi_zi_xing_che_attack_range)
end

sgs.LoadTranslationTable {
    ["RanzeTerada"] = "寺田 蘭世",
    ["&RanzeTerada"] = "寺田 蘭世",
    ["#RanzeTerada"] = "势不可挡",
    ["~RanzeTerada"] = "らんぜの勢いとまらんぜ！",
    ["designer:RanzeTerada"] = "Cassimolar",
    ["cv:RanzeTerada"] = "寺田 蘭世",
    ["illustrator:RanzeTerada"] = "Cassimolar",
    ["sakamichi_luan_shi"] = "乱世",
    [":sakamichi_luan_shi"] = "结束阶段，若场上存在〔反贼〕，你可以执行一个额外的摸牌阶段或出牌阶段。",
    ["sakamichi_luan_shi:draw"] = "额外一个摸牌阶段",
    ["sakamichi_luan_shi:play"] = "额外一个出牌阶段",
    ["sakamichi_bai_tou_xie_lao"] = "白头偕老",
    [":sakamichi_bai_tou_xie_lao"] = "限定技，准备阶段，你可以交给一名其他角色两张牌。当你受到伤害时，将此伤害转移给该角色，然后该角色摸X张牌，直到其第一次进入濒死（X为伤害值）。",
    ["@bai_tou"] = "白头",
    ["@xie_lao"] = "偕老",
    ["@bai_tou_xie_lao_give"] = "请选择两张牌交给【白头偕老】目标",
    ["sakamichi_bao_yan"] = "爆言",
    [":sakamichi_bao_yan"] = "限定技，出牌阶段，你可以令一名角色武将牌的上的阿拉伯数字+1，若该角色为你，则加至100。",
    ["@bao_yan"] = "爆言",
    ["sakamichi_zi_xing_che"] = "自行车",
    [":sakamichi_zi_xing_che"] = "觉醒技，当你使用【杀】造成伤害后，若你不在目标的攻击范围内，你的攻击范围+1，你与其他角色的距离-1。",
    ["#zi_xing_che"] = "%from 的【%arg】触发，%from 的攻击范围+1，与其他角色的距离-1。",
}
