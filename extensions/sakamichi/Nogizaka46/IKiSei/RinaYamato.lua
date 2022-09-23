require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaYamato = sgs.General(Sakamichi, "RinaYamato", "Nogizaka46", 3, false)
SKMC.IKiSei.RinaYamato = true
SKMC.SeiMeiHanDan.RinaYamato = {
    name = {3, 8, 7, 11},
    ten_kaku = {11, "ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fan_qie_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_fan_qie",
    filter_pattern = ".|red",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, -1)
        card:deleteLater()
        if player:isCardLimited(card, sgs.Card_MethodUse) or player:isProhibited(player, card) then
            return false
        end
        return player:isWounded()
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "peach")
    end,
}
sakamichi_fan_qie = sgs.CreateTriggerSkill {
    name = "sakamichi_fan_qie",
    view_as_skill = sakamichi_fan_qie_view_as,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if data:toCardUse().card:getSkillName() == self:objectName() then
            if player:getHp() > SKMC.number_correction(player, 2) then
                room:loseHp(player, SKMC.number_correction(player, 1))
            end
        end
        return false
    end,
}
RinaYamato:addSkill(sakamichi_fan_qie)

sakamichi_yin_jiu = sgs.CreateTriggerSkill {
    name = "sakamichi_yin_jiu",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.SlashProceed, sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and p:canDiscard(p, "h") then
                        local cd = room:askForCard(p, ".|.|.|hand", "@yin_jiu_discard:" .. player:objectName(),
                            sgs.QVariant(), self:objectName())
                        if cd then
                            local card = sgs.Sanguosha:cloneCard("analeptic", cd:getSuit(), cd:getNumber())
                            card:addSubcard(cd)
                            card:setSkillName(self:objectName())
                            room:useCard(sgs.CardUseStruct(card, player, player, true))
                            card:deleteLater()
                            if player:isAlive() then
                                room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
                            end
                        end
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Analeptic") and use.card:getSkillName() == self:objectName() then
                room:addPlayerHistory(use.from, use.card:getClassName(), -1)
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("drank") and effect.to:hasSkill(self) then
                room:slashResult(effect, nil)
                return true
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("drank")
                and damage.to:hasSkill(self) then
                room:drawCards(player, damage.damage, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaYamato:addSkill(sakamichi_yin_jiu)

sakamichi_bu_lun = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_lun",
    events = {sgs.EnterDying, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.damage and dying.damage.from and dying.who:objectName() ~= player:objectName() then
                if room:askForSkillInvoke(dying.damage.from, self:objectName(),
                    sgs.QVariant("draw:" .. player:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from then
                if room:askForSkillInvoke(death.damage.from, self:objectName(),
                    sgs.QVariant("losehp:" .. player:objectName())) then
                    room:loseHp(player, SKMC.number_correction(player, 1))
                end
            end
        end
        return false
    end,
}
RinaYamato:addSkill(sakamichi_bu_lun)

sgs.LoadTranslationTable {
    ["RinaYamato"] = "大和 里菜",
    ["&RinaYamato"] = "大和 里菜",
    ["#RinaYamato"] = "毒番茄",
    ["~RinaYamato"] = "",
    ["designer:RinaYamato"] = "Cassimolar",
    ["cv:RinaYamato"] = "大和 里菜",
    ["illustrator:RinaYamato"] = "Cassimolar",
    ["sakamichi_fan_qie"] = "番茄",
    [":sakamichi_fan_qie"] = "你可以将一张红色牌当【桃】使用或打出。你以此法使用的【桃】结算完成时，若你的体力大于2，你失去1点体力。",
    ["sakamichi_yin_jiu"] = "饮酒",
    [":sakamichi_yin_jiu"] = "其他角色出牌阶段开始时，你可以弃置一张手牌，视为其使用一张【酒】（不计入次数使用限制），并对其造成1点伤害。锁定技，你无法闪避【酒】【杀】，你受到【酒】【杀】造成的伤害后，你摸等同于伤害量的牌。",
    ["@yin_jiu_discard"] = "你可以弃置一张手牌发动【饮酒】视为%src 使用一张【酒】并对其造成1点伤害",
    ["sakamichi_bu_lun"] = "不伦",
    [":sakamichi_bu_lun"] = "其他角色进入濒死时，伤害来源可以令你摸一张牌。其他角色死亡时，伤害来源可以令你失去1点体力。",
    ["sakamichi_bu_lun:draw"] = "你可以发动 %src 的【不伦】令其摸一张牌",
    ["sakamichi_bu_lun:losehp"] = "你可以发动 %src 的【不伦】令其失去1点体力",
}
