require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KyokaYoneto = sgs.General(Sakamichi, "KyokaYoneto", "Nogizaka46", 3, false)
SKMC.NiKiSei.KyokaYoneto = true
SKMC.SeiMeiHanDan.KyokaYoneto = {
    name = {6, 14, 8, 7},
    ten_kaku = {20, "xiong"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_shui_yong = sgs.CreateTriggerSkill {
    name = "sakamichi_shui_yong",
    change_skill = true,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local n = room:getChangeSkillState(player, self:objectName())
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Fire and n == 1 and room:askForSkillInvoke(player, self:objectName(), data) then
            local card = room:askForCardChosen(player, damage.to, "hej", self:objectName(), true, sgs.Card_MethodNone)
            room:setEmotion(damage.to, "skill_nullify")
            room:obtainCard(player, card, room:getCardPlace(card) ~= sgs.Player_PlaceHand)
            room:setChangeSkillState(player, self:objectName(), 2)
            return true
        elseif damage.nature == sgs.DamageStruct_Thunder and n == 2 and not player:isNude() then
            local n = SKMC.number_correction(player, 1)
            if room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@shui_yong_thunder:::" .. n) then
                damage.damage = damage.damage + n
                data:setValue(damage)
                room:setChangeSkillState(player, self:objectName(), 1)
            end
        end
        return false
    end,
}
KyokaYoneto:addSkill(sakamichi_shui_yong)

sakamichi_fu_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_fu_zi",
    change_skill = true,
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetConfirmed, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local n = room:getChangeSkillState(player, self:objectName())
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from and use.from:objectName() ~= player:objectName() and use.to:contains(player)
                and not use.card:isKindOf("SkillCard") and n == 1 then
                local n = player:getHandcardNum()
                local m = use.from:getHandcardNum()
                if n <= m and room:askForSkillInvoke(player, self:objectName(), data) then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getHandcardNum() <= n then
                            targets:append(p)
                        end
                    end
                    local to = room:askForPlayerChosen(player, targets, self:objectName(), "fu_zi_invoke", true, true)
                    if to then
                        room:drawCards(to, 1, self:objectName())
                        room:setChangeSkillState(player, self:objectName(), 2)
                    end
                end
            end
            return false
        else
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() and n == 2 then
                local n = player:getHandcardNum()
                local m = damage.from:getHandcardNum()
                if m <= n and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setEmotion(damage.to, "skill_nullify")
                    room:drawCards(damage.from, 1, self:objectName())
                    room:setChangeSkillState(player, self:objectName(), 1)
                    return true
                end
            end
        end
    end,
}
KyokaYoneto:addSkill(sakamichi_fu_zi)

sakamichi_jin_dan = sgs.CreateTriggerSkill {
    name = "sakamichi_jin_dan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            local damage = death.damage
            if damage then
                local murderer = damage.from
                if murderer then
                    if SKMC.is_ki_be(murderer, 2) then
                        murderer:throwAllEquips()
                    else
                        room:acquireSkill(murderer, "sakamichi_fa_jia")
                        local EX = sgs.Sanguosha:getTriggerSkill("sakamichi_fa_jia")
                        EX:trigger(sgs.GameStart, room, murderer, sgs.QVariant())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        if target then
            return target:hasSkill(self)
        end
        return false
    end,
}
KyokaYoneto:addSkill(sakamichi_jin_dan)

sgs.LoadTranslationTable {
    ["KyokaYoneto"] = "米徳 京花",
    ["&KyokaYoneto"] = "米徳 京花",
    ["#KyokaYoneto"] = "乃木坂風格",
    ["~KyokaYoneto"] = "みなさんこんばんは，米徳京花です",
    ["designer:KyokaYoneto"] = "Cassimolar",
    ["cv:KyokaYoneto"] = "米徳 京花",
    ["illustrator:KyokaYoneto"] = "Cassimolar",
    ["sakamichi_shui_yong"] = "水泳",
    [":sakamichi_shui_yong"] = "转换技，①当你造成火焰伤害时，你可以防止此伤害，然后观看目标手牌并获得其区域内的一张牌；②当你造成雷电伤害时，你可以弃置一张牌，令此伤害+1。",
    [":sakamichi_shui_yong1"] = "转换技，①当你造成火焰伤害时，你可以防止此伤害，然后观看目标手牌并获得其区域内的一张牌；<font color=\"#01A5AF\"><s>②当你造成雷电伤害时，你可以弃置一张牌，令此伤害+1</s></font>。",
    [":sakamichi_shui_yong2"] = "转换技，<font color=\"#01A5AF\"><s>①当你造成火焰伤害时，你可以防止此伤害，然后观看目标手牌并获得其区域内的一张牌</s></font>；②当你造成雷电伤害时，你可以弃置一张牌，令此伤害+1。",
    ["@shui_yong_thunder"] = "你可以弃置一张牌来使此伤害+%arg",
    ["sakamichi_fu_zi"] = "抚子",
    [":sakamichi_fu_zi"] = "转换技，①当你成为其他角色使用牌的目标后，若你手牌不多于其，你可以令一名手牌数不多于你的角色摸一张牌；②当你受到其他角色造成的伤害时，若其手牌不多于你，你可以防止此伤害，然后其摸一张牌。",
    [":sakamichi_fu_zi1"] = "转换技，①当你成为其他角色使用牌的目标后，若你手牌不多于其，你可以令一名手牌数不多于你的角色摸一张牌；<font color=\"#01A5AF\"><s>②当你受到其他角色造成的伤害时，若其手牌不多于你，你可以防止此伤害，然后其摸一张牌</s></font>。",
    [":sakamichi_fu_zi2"] = "转换技，<font color=\"#01A5AF\"><s>①当你成为其他角色使用牌的目标后，若你手牌不多于其，你可以令一名手牌数不多于你的角色摸一张牌</s></font>；②当你受到其他角色造成的伤害时，若其手牌不多于你，你可以防止此伤害，然后其摸一张牌。",
    ["fu_zi_invoke"] = "你可以选择一名角色令其摸一张牌",
    ["sakamichi_jin_dan"] = "金蛋",
    [":sakamichi_jin_dan"] = "锁定技，当你死亡时，若伤害来源是二期生，伤害来源获得【发夹】（获得后不为主公也可发动），否则其须弃置装备区所有牌。",
}
