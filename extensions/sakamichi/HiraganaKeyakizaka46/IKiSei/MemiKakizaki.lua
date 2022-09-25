require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MemiKakizaki_HiraganaKeyakizaka = sgs.General(Sakamichi, "MemiKakizaki_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
SKMC.IKiSei.MemiKakizaki_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.MemiKakizaki_HiraganaKeyakizaka = {
	name = {9, 11, 8, 8},
	ten_kaku = {20, "xiong"},
	jin_kaku = {19, "xiong"},
	ji_kaku = {16, "da_ji"},
	soto_kaku = {17, "ji"},
	sou_kaku = {36, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "shui",
		jin_kaku = "shui",
		ji_kaku = "tu",
		san_sai = "xiong",
	},
}

sakamichi_mao_yu_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_mao_yu",
    filter_pattern = ".|heart",
    response_pattern = "peach,analeptic",
    response_or_use = true,
    view_as = function(self, card)
        local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
        peach:addSubcard(card)
        peach:setSkillName(self:objectName())
        return peach
    end,
    enabled_at_play = function(self, player)
        return player:getMark("mao_yu_lun_clear") == 0
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getMark("mao_yu_lun_clear") == 0
    end,
}
sakamichi_mao_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_mao_yu",
    view_as_skill = sakamichi_mao_yu_view_as,
    events = {sgs.CardUsed, sgs.DamageCaused, sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:getSuit() == sgs.Card_Heart and use.card:isDamageCard()
                and room:askForSkillInvoke(player, self:objectName(), data) then
                local choice_1 = "no_response==" .. use.card:objectName()
                local choice_2 = "damage==" .. use.card:objectName()
                if room:askForChoice(player, self:objectName(), choice_1 .. "+" .. choice_2) == choice_2 then
                    room:setCardFlag(use.card, "mao_yu_damage")
                else
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
            end
            if use.card:isKindOf("Peach") and use.card:getSkillName() == self:objectName() then
                room:setPlayerMark(player, "mao_yu_lun_clear", 1)
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("mao_yu_damage") then
                damage.damage = damage.damage + SKMC.number_correction(player, 1)
                data:setValue(damage)
            end
        else
            local use = data:toCardUse()
            if use.card:getSuit() == sgs.Card_Heart and (use.card:isKindOf(Slash) or use.card:isNDTrick())
                and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                room:setEmotion(player, "skill_nullify")
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
}
MemiKakizaki_HiraganaKeyakizaka:addSkill(sakamichi_mao_yu)

sakamichi_meng_ya = sgs.CreateTriggerSkill {
    name = "sakamichi_meng_ya",
    freueny = sgs.Skill_Compulsory,
    events = {},
    on_trigger = function()
    end,
}
sakamichi_meng_ya_1 = sgs.CreateFilterSkill {
    name = "sakamichi_meng_ya_1",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Diamond
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName(self:objectName())
        new_card:setSuit(sgs.Card_Heart)
        new_card:setModified(true)
        return new_card
    end,
}
sakamichi_meng_ya_2 = sgs.CreateFilterSkill {
    name = "sakamichi_meng_ya_2",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Diamond or to_select:getSuit() == sgs.Card_Club
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName(self:objectName())
        new_card:setSuit(sgs.Card_Heart)
        new_card:setModified(true)
        return new_card
    end,
}
sakamichi_meng_ya_3 = sgs.CreateFilterSkill {
    name = "sakamichi_meng_ya_3",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Diamond or to_select:getSuit() == sgs.Card_Club or to_select:getSuit()
                   == sgs.Card_Spade
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName(self:objectName())
        new_card:setSuit(sgs.Card_Heart)
        new_card:setModified(true)
        return new_card
    end,
}
sakamichi_meng_ya_trigger = sgs.CreateTriggerSkill {
    name = "#sakamichi_meng_ya_trigger",
    events = {sgs.HpChanged, sgs.MaxHpChanged},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local lost_hp = player:getLostHp()
        if lost_hp >= SKMC.number_correction(player, 1) then
            room:handleAcquireDetachSkills(player, "-sakamichi_meng_ya", false, true, false)
            if lost_hp >= SKMC.number_correction(player, 2) then
                room:handleAcquireDetachSkills(player, "-sakamichi_meng_ya_1", false, true)
                if lost_hp >= SKMC.number_correction(player, 3) then
                    room:handleAcquireDetachSkills(player, "sakamichi_meng_ya_3", false, true)
                else
                    room:handleAcquireDetachSkills(player, "-sakamichi_meng_ya_3", false, true)
                    room:handleAcquireDetachSkills(player, "sakamichi_meng_ya_2", false, true)
                end
            else
                room:handleAcquireDetachSkills(player, "-sakamichi_meng_ya_2", false, true)
                room:handleAcquireDetachSkills(player, "sakamichi_meng_ya_1", false, true)
            end
        else
            room:handleAcquireDetachSkills(player, "sakamichi_meng_ya", false, true, false)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and (target:hasSkill("sakamichi_meng_ya") or target:hasSkill("sakamichi_meng_ya_1")
                   or target:hasSkill("sakamichi_meng_ya_2") or target:hasSkill("sakamichi_meng_ya_3"))
    end,
}
MemiKakizaki_HiraganaKeyakizaka:addSkill(sakamichi_meng_ya)
if not sgs.Sanguosha:getSkill("sakamichi_meng_ya_1") then
    SKMC.SkillList:append(sakamichi_meng_ya_1)
end
if not sgs.Sanguosha:getSkill("sakamichi_meng_ya_2") then
    SKMC.SkillList:append(sakamichi_meng_ya_2)
end
if not sgs.Sanguosha:getSkill("sakamichi_meng_ya_3") then
    SKMC.SkillList:append(sakamichi_meng_ya_3)
end
if not sgs.Sanguosha:getSkill("#sakamichi_meng_ya_trigger") then
    SKMC.SkillList:append(sakamichi_meng_ya_trigger)
end

sgs.LoadTranslationTable {
    ["MemiKakizaki_HiraganaKeyakizaka"] = "柿崎 芽実",
    ["&MemiKakizaki_HiraganaKeyakizaka"] = "柿崎 芽実",
    ["#MemiKakizaki_HiraganaKeyakizaka"] = "法国人偶",
    ["~MemiKakizaki_HiraganaKeyakizaka"] = "お小遣いちょうだい",
    ["designer:MemiKakizaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MemiKakizaki_HiraganaKeyakizaka"] = "柿崎 芽実",
    ["illustrator:MemiKakizaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_mao_yu"] = "猫语",
    [":sakamichi_mao_yu"] = "轮次技，你可以将一张红桃牌当【桃】使用或打出。你使用红桃伤害牌时，你可以选择令此牌无法响应或造成的伤害+1。当你成为其他角色使用的红桃基本牌或通常锦囊牌的目标时，你可以令此牌对你无效。",
    ["sakamichi_mao_yu:no_response"] = "令此【%arg】无法响应",
    ["sakamichi_mao_yu:damage"] = "令此【%arg】造成的伤害+1",
    ["sakamichi_meng_ya"] = "萌芽",
    [":sakamichi_meng_ya"] = "锁定技，若你已损失的体力值：不小于1，你的方块牌均视为红桃牌；不小于2，你的梅花牌均视为红桃牌；不小于3，你的黑桃牌均视为红桃牌。",
    ["sakamichi_meng_ya_1"] = "萌芽",
    [":sakamichi_meng_ya_1"] = "锁定技，若你已损失的体力值：不小于1，你的方块牌均视为红桃牌；不小于2，你的梅花牌均视为红桃牌；不小于3，你的黑桃牌均视为红桃牌。",
    ["sakamichi_meng_ya_2"] = "萌芽",
    [":sakamichi_meng_ya_2"] = "锁定技，若你已损失的体力值：不小于1，你的方块牌均视为红桃牌；不小于2，你的梅花牌均视为红桃牌；不小于3，你的黑桃牌均视为红桃牌。",
    ["sakamichi_meng_ya_3"] = "萌芽",
    [":sakamichi_meng_ya_3"] = "锁定技，若你已损失的体力值：不小于1，你的方块牌均视为红桃牌；不小于2，你的梅花牌均视为红桃牌；不小于3，你的黑桃牌均视为红桃牌。",
}
