require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiImaizumi = sgs.General(Sakamichi, "YuiImaizumi", "Keyakizaka46", 3, false)
SKMC.IKiSei.YuiImaizumi = true
SKMC.SeiMeiHanDan.YuiImaizumi = {
    name = {4, 9, 7, 11},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "da_ji",
    },
}

sakamichi_wu_meiCard = sgs.CreateSkillCard {
    name = "sakamichi_wu_meiCard",
    skill_name = "sakamichi_wu_mei",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:hasFlag("wu_mei_target")
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasFlag("wu_mei_target") then
                room:setPlayerFlag(p, "-wu_mei_target")
            end
        end
        room:loseHp(effect.to)
    end,
}
sakamichi_wu_mei_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_wu_mei",
    filter_pattern = ".",
    response_pattern = "@@sakamichi_wu_mei",
    view_as = function(self, card)
        local SkillCard = sakamichi_wu_meiCard:clone()
        SkillCard:addSubcard(card)
        return SkillCard
    end,
}
sakamichi_wu_mei = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_mei",
    view_as_skill = sakamichi_wu_mei_view_as,
    events = {sgs.TargetConfirming, sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and use.from and use.from:hasSkill(self) and use.to:contains(player)
                and use.from:objectName() ~= player:objectName() then
                room:setCardFlag(use.card, "wu_mei")
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("wu_mei") then
                room:setCardFlag(damage.card, "wu_mei_damage")
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("wu_mei") then
                room:setCardFlag(use.card, "-wu_mei")
                if use.card:hasFlag("wu_mei_damage") then
                    room:setCardFlag(use.card, "-wu_mei_damage")
                else
                    if player:isAlive() then
                        for _, p in sgs.qlist(use.to) do
                            room:setPlayerFlag(p, "wu_mei_target")
                        end
                        if not room:askForUseCard(player, "@@sakamichi_wu_mei",
                            "@wu_mei_invoke:::" .. use.card:objectName()) then
                            for _, p in sgs.qlist(use.to) do
                                if p:hasFlag("wu_mei_target") then
                                    room:setPlayerFlag(p, "-wu_mei_target")
                                end
                            end
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
YuiImaizumi:addSkill(sakamichi_wu_mei)

sakamichi_ruo_li = sgs.CreateTriggerSkill {
    name = "sakamichi_ruo_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:getHp() > player:getHp() then
            damage.damage = damage.damage - SKMC.number_correction(player, 1)
            data:setValue(damage)
            if damage.damage < 1 then
                return true
            end
        end
        return false
    end,
}
YuiImaizumi:addSkill(sakamichi_ruo_li)

sakamichi_fei_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_fei_yu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getKingdom() == "Keyakizaka46" then
                    room:loseHp(p)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuiImaizumi:addSkill(sakamichi_fei_yu)

sgs.LoadTranslationTable {
    ["YuiImaizumi"] = "今泉 佑唯",
    ["&YuiImaizumi"] = "今泉 佑唯",
    ["#YuiImaizumi"] = "泉妹",
    ["~YuiImaizumi"] = "オニオンリング",
    ["designer:YuiImaizumi"] = "Cassimolar",
    ["cv:YuiImaizumi"] = "今泉 佑唯",
    ["illustrator:YuiImaizumi"] = "Cassimolar",
    ["sakamichi_wu_mei"] = "五妹",
    [":sakamichi_wu_mei"] = "你使用的目标包含其他角色的牌结算完成时，若此牌未造成伤害，你可以弃置一张牌令此牌目标中的一名角色失去1点体力。",
    ["@wu_mei_invoke"] = "你可以弃置一张牌选择此%arg的目标中一名角色失去1点体力",
    ["~sakamichi_wu_mei"] = "选择一张牌 → 选择一名角色 → 点击确定",
    ["sakamichi_ruo_li"] = "弱力",
    [":sakamichi_ruo_li"] = "锁定技，你对体力值大于你的角色造成伤害时，伤害-1。",
    ["sakamichi_fei_yu"] = "蜚语",
    [":sakamichi_fei_yu"] = "锁定技，你死亡时所有欅坂46势力角色失去1点体力。",
}
