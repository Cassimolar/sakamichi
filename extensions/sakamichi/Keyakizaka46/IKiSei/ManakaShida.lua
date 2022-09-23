require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManakaShida = sgs.General(Sakamichi, "ManakaShida", "Keyakizaka46", 4, false)
SKMC.IKiSei.ManakaShida = true
SKMC.SeiMeiHanDan.ManakaShida = {
    name = {7, 5, 13, 8},
    ten_kaku = {12, "xiong"},
    jin_kaku = {18, "ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_pan_ni = sgs.CreateTriggerSkill {
    name = "sakamichi_pan_ni",
    events = {sgs.TargetConfirming, sgs.SlashHit, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:hasSkill(self) then
                player:setTag(self:objectName(), sgs.QVariant(use.card:getEffectiveId()))
                room:askForUseSlashTo(player, use.from, "@pan_ni_slash:" .. use.from:objectName(), false, false, true,
                    nil, nil, "pan_ni_use")
                player:removeTag(self:objectName())
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("pan_ni_use") then
                if room:askForSkillInvoke(effect.from, self:objectName(), sgs.QVariant(
                    "@pan_ni_invoke:" .. effect.to:objectName() .. "::" .. effect.slash:objectName())) then
                    room:setCardFlag(effect.slash, "pan_ni_used")
                    room:setPlayerMark(effect.from, self:objectName(), effect.from:getTag(self:objectName()):toInt())
                end
                room:setCardFlag(effect.slash, "-pan_ni_use")
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                if damage.card:hasFlag("pan_ni_used") then
                    room:setCardFlag(damage.card, "-pan_ni_used")
                    return true
                end
                if damage.to:getMark(self:objectName()) ~= 0 and damage.card:getEffectiveId()
                    == damage.to:getMark(self:objectName()) then
                    room:setPlayerMark(damage.to, self:objectName(), 0)
                    damage.damage = damage.damage - SKMC.number_correction(damage.to, 1)
                    SKMC.send_message(room, "#pan_ni_damage", damage.to, damage.from, nil, damage.card:toString(),
                        self:objectName(), SKMC.number_correction(damage.to, 1), damage.damage)
                    data:setValue(damage)
                    if damage.damage < 1 then
                        return true
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
ManakaShida:addSkill(sakamichi_pan_ni)

sakamichi_kuang_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_kuang_qi",
    events = {sgs.EventPhaseProceeding, sgs.EventPhaseStart, sgs.CardUsed, sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish and player:hasSkill(self) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@kuang_qi_choice", true, true)
            if target then
                room:setPlayerMark(player, "kuang_qi_target" .. target:objectName(), 1)
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. target:getGeneralName(), 1)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self) then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:getMark("kuang_qi_target" .. p:objectName()) ~= 0 then
                    room:setPlayerMark(player, "kuang_qi_target" .. p:objectName(), 0)
                end
            end
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "&" .. self:objectName()) and player:getMark(mark) ~= 0 then
                    room:setPlayerMark(player, mark, 0)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("kuang_qi_target" .. player:objectName()) ~= 0 and not use.to:contains(p) then
                        room:setPlayerMark(p, "kuang_qi_card_" .. use.card:getEffectiveId(), 1)
                        use.to:append(p)
                    end
                end
                data:setValue(use)
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card then
                if damage.to:getMark("kuang_qi_target" .. player:objectName()) ~= 0 then
                    room:setPlayerMark(damage.to, "kuang_qi_damage_" .. damage.card:getEffectiveId(), 1)
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            for _, p in sgs.qlist(use.to) do
                if p:getMark("kuang_qi_target" .. use.from:objectName()) ~= 0 then
                    if p:getMark("kuang_qi_card_" .. use.card:getEffectiveId()) ~= 0 then
                        if p:getMark("kuang_qi_damage_" .. use.card:getEffectiveId()) == 0 then
                            room:drawCards(p, 1, self:objectName())
                            if use.from:isAlive() then
                                local choices = {}
                                local choice_1 = "damage=" .. use.from:objectName() .. "="
                                                     .. SKMC.number_correction(p, 1)
                                local choice_2 = "get=" .. use.from:objectName()
                                table.insert(choices, choice_1)
                                table.insert(choices, choice_2)
                                if use.from:isAllNude()
                                    or room:askForChoice(p, self:objectName(), table.concat(choices, "+")) == choice_1 then
                                    room:damage(sgs.DamageStruct(self:objectName(), p, use.from,
                                        SKMC.number_correction(p, 1)))
                                else
                                    local card = room:askForCardChosen(p, use.from, "hej", self:objectName(), false,
                                        sgs.Card_MethodNone)
                                    room:obtainCard(p, card)
                                end
                            end
                        else
                            room:setPlayerMark(p, "kuang_qi_damage_" .. use.card:getEffectiveId(), 0)
                        end
                        room:setPlayerMark(p, "kuang_qi_card_" .. use.card:getEffectiveId(), 0)
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
ManakaShida:addSkill(sakamichi_kuang_qi)

sgs.LoadTranslationTable {
    ["ManakaShida"] = "志田 愛佳",
    ["&ManakaShida"] = "志田 愛佳",
    ["#ManakaShida"] = "叛逆少女",
    ["~ManakaShida"] = "1日が24時間しかないこと",
    ["designer:ManakaShida"] = "Cassimolar",
    ["cv:ManakaShida"] = "志田 愛佳",
    ["illustrator:ManakaShida"] = "Cassimolar",
    ["sakamichi_pan_ni"] = "叛逆",
    [":sakamichi_pan_ni"] = "当你成为【杀】的目标时，你可以对此【杀】的使用着使用一张【杀】，若你使用的【杀】命中，你可以防止你使用的【杀】对其伤害并令其使用的【杀】对你造成的伤害-1。",
    ["@pan_ni_slash"] = "你可以对%src使用一张【杀】",
    ["sakamichi_pan_ni:@pan_ni_invoke"] = "你可以防止此【%arg】对%src造成的伤害",
    ["#pan_ni_damage"] = "%from 发动【%arg】令%to 使用的%card 对%from 造成的伤害-%arg2，伤害为%arg3",
    ["sakamichi_kuang_qi"] = "狂气",
    [":sakamichi_kuang_qi"] = "结束阶段，你可以选择一名其他角色，直到你的下个回合开始，其使用的【杀】的目标若不包含你则将你添加为额外目标，若此【杀】未对你造成伤害，你可以摸一张牌然后选择对其造成1点伤害或获得其区域内的一张牌。",
    ["@kuang_qi_choice"] = "你可以选择一名其他角色发动【狂气】",
    ["sakamichi_kuang_qi:damage"] = "对%src造成%arg点伤害",
    ["sakamichi_kuang_qi:get"] = "获得%src区域内的一张牌",
}
