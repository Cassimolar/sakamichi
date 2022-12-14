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
    ["ManakaShida"] = "?????? ??????",
    ["&ManakaShida"] = "?????? ??????",
    ["#ManakaShida"] = "????????????",
    ["~ManakaShida"] = "1??????24????????????????????????",
    ["designer:ManakaShida"] = "Cassimolar",
    ["cv:ManakaShida"] = "?????? ??????",
    ["illustrator:ManakaShida"] = "Cassimolar",
    ["sakamichi_pan_ni"] = "??????",
    [":sakamichi_pan_ni"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????-1???",
    ["@pan_ni_slash"] = "????????????%src?????????????????????",
    ["sakamichi_pan_ni:@pan_ni_invoke"] = "?????????????????????%arg??????%src???????????????",
    ["#pan_ni_damage"] = "%from ?????????%arg??????%to ?????????%card ???%from ???????????????-%arg2????????????%arg3",
    ["sakamichi_kuang_qi"] = "??????",
    [":sakamichi_kuang_qi"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1?????????????????????????????????????????????",
    ["@kuang_qi_choice"] = "???????????????????????????????????????????????????",
    ["sakamichi_kuang_qi:damage"] = "???%src??????%arg?????????",
    ["sakamichi_kuang_qi:get"] = "??????%src?????????????????????",
}
