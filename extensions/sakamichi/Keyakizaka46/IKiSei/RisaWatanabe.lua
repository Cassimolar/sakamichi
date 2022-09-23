require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RisaWatanabe_Keyakizaka = sgs.General(Sakamichi, "RisaWatanabe_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.RisaWatanabe_Keyakizaka = true
SKMC.SeiMeiHanDan.RisaWatanabe_Keyakizaka = {
    name = {12, 17, 11, 7},
    ten_kaku = {29, "te_shu_ge"},
    jin_kaku = {28, "xiong"},
    ji_kaku = {18, "ji"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_hu_boCard = sgs.CreateSkillCard {
    name = "sakamichi_hu_boCard",
    skill_name = "sakamichi_hu_bo",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():first()), "hu_bo")
        room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(self:getSubcards():first()), source, source))
    end,
}
sakamichi_hu_bo_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_hu_bo",
    filter_pattern = "Slash",
    view_as = function(self, card)
        local cd = sakamichi_hu_boCard:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_hu_boCard")
    end,
}
sakamichi_hu_bo = sgs.CreateTriggerSkill {
    name = "sakamichi_hu_bo",
    view_as_skill = sakamichi_hu_bo_view_as,
    events = {sgs.Damage, sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("hu_bo") then
                room:setCardFlag(damage.card, "hu_bo_damage")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("hu_bo") and not use.card:isKindOf("SkillCard") then
                room:setCardFlag(use.card, "-hu_bo")
                if use.card:hasFlag("hu_bo_damage") then
                    room:setPlayerFlag(use.from, "hu_bo_damage")
                    room:setCardFlag(use.card, "-hu_bo_damage")
                else
                    room:drawCards(use.from, 3, self:objectName())
                    room:setPlayerFlag(use.from, "hu_bo_not_damage")
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard and player:hasFlag("hu_bo_not_damage") then
                player:skip(sgs.Player_Discard)
            end
        end
        return false
    end,
}
sakamichi_hu_bo_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_hu_bo_target_mod",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_hu_bo") and from:hasFlag("hu_bo_damage") then
            return 1000
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_hu_bo") and from:hasFlag("hu_bo_damage") then
            return 1000
        else
            return 0
        end
    end,
}
RisaWatanabe_Keyakizaka:addSkill(sakamichi_hu_bo)
if not sgs.Sanguosha:getSkill("#sakamichi_hu_bo_target_mod") then
    SKMC.SkillList:append(sakamichi_hu_bo_target_mod)
end

sakamichi_ao_jiao = sgs.CreateTriggerSkill {
    name = "sakamichi_ao_jiao",
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            local jink = room:askForCard(player, "Jink", "@ao_jiao_discard", sgs.QVariant(), self:objectName())
            if jink then
                room:recover(player, sgs.RecoverStruct(player, jink, SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
RisaWatanabe_Keyakizaka:addSkill(sakamichi_ao_jiao)

sakamichi_shi_nue = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_nue",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
            if damage.to:isNude()
                or not room:askForDiscard(damage.to, self:objectName(), 1, 1, true, true,
                    "@shi_nue_discard:" .. player:objectName()) then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
RisaWatanabe_Keyakizaka:addSkill(sakamichi_shi_nue)

sgs.LoadTranslationTable {
    ["RisaWatanabe_Keyakizaka"] = "渡邉 理佐",
    ["&RisaWatanabe_Keyakizaka"] = "渡邉 理佐",
    ["#RisaWatanabe_Keyakizaka"] = "不良蛙",
    ["~RisaWatanabe_Keyakizaka"] = "こぼしてんじゃねーよ！",
    ["designer:RisaWatanabe_Keyakizaka"] = "Cassimolar",
    ["cv:RisaWatanabe_Keyakizaka"] = "渡邉 理佐",
    ["illustrator:RisaWatanabe_Keyakizaka"] = "Cassimolar",
    ["sakamichi_hu_bo"] = "互搏",
    [":sakamichi_hu_bo"] = "出牌阶段限一次，你可以弃置一张【杀】视为对自己使用，若此【杀】：造成伤害，本回合内你使用牌无次数和距离限制；未造成伤害，你摸三张牌且跳过此回合的弃牌阶段。",
    ["sakamichi_ao_jiao"] = "傲娇",
    [":sakamichi_ao_jiao"] = "当你受到【杀】造成的伤害后，你可以弃置一张【闪】来回复1点体力。",
    ["@ao_jiao_discard"] = "你可以弃置一张【闪】来回复1点体力",
    ["sakamichi_shi_nue"] = "施虐",
    [":sakamichi_shi_nue"] = "当你使用【杀】造成伤害后，你可以令目标选择弃置一张牌或令你摸一张牌。",
    ["@shi_nue_discard"] = "请弃置一张牌否则%src将摸一张牌",
}
