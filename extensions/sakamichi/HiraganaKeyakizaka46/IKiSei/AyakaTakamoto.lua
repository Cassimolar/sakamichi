require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AyakaTakamoto_HiraganaKeyakizaka = sgs.General(Sakamichi, "AyakaTakamoto_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
SKMC.IKiSei.AyakaTakamoto_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.AyakaTakamoto_HiraganaKeyakizaka = {
    name = {10, 5, 11, 7},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_gong_dao = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_gong_dao",
    filter_pattern = "Slash",
    view_as = function(self, card)
        local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())
        archery_attack:addSubcard(card)
        archery_attack:setSkillName(self:objectName())
        return archery_attack
    end,
    enabled_at_play = function(self, player)
        return true
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "archery_attack"
    end,
}
sakamichi_gong_dao_attack_range = sgs.CreateAttackRangeSkill {
    name = "#sakamichi_gong_dao_attack_range",
    extra_func = function(self, player, include_weapon)
        if player:hasSkill("sakamichi_gong_dao") then
            return player:getHp()
        end
    end,
}
AyakaTakamoto_HiraganaKeyakizaka:addSkill(sakamichi_gong_dao)
if not sgs.Sanguosha:getSkill("#sakamichi_gong_dao_attack_range") then
    SKMC.SkillList:append(sakamichi_gong_dao_attack_range)
end

sakamichi_wen_bian = sgs.CreateTriggerSkill {
    name = "sakamichi_wen_bian",
    events = {sgs.TargetSpecified, sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isDamageCard() and use.card:isNDTrick() then
                local target = room:askForPlayerChosen(player, use.to, self:objectName(), "@wen_bian_invoke:::"
                    .. use.card:objectName() .. ":" .. self:objectName(), true, true)
                if target then
                    local choice_1 = "damage=" .. target:objectName() .. "=" .. use.card:objectName()
                    local choice_2 = "no_damage=" .. target:objectName() .. "=" .. use.card:objectName()
                    if room:askForChoice(player, self:objectName(), choice_1 .. "+" .. choice_2) == choice_1 then
                        room:setCardFlag(use.card, "wen_bian_damage_" .. target:objectName())
                    else
                        room:setCardFlag(use.card, "wen_bian_no_damage_" .. target:objectName())
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card then
                if damage.card:hasFlag("wen_bian_damage_" .. damage.to:objectName()) then
                    room:setCardFlag(damage.card, "-" .. "wen_bian_damage_" .. damage.to:objectName())
                    room:drawCards(player, 1, self:objectName())
                    room:drawCards(damage.to, 1, self:objectName())
                elseif damage.card:hasFlag("wen_bian_no_damage_" .. damage.to:objectName()) then
                    room:setCardFlag(damage.card, "-" .. "wen_bian_no_damage_" .. damage.to:objectName())
                    room:loseHp(player, SKMC.number_correction(player, 1))
                    room:loseHp(damage.to, SKMC.number_correction(player, 1))
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            for _, p in sgs.qlist(use.to) do
                if use.card:hasFlag("wen_bian_damage_" .. p:objectName()) then
                    room:loseHp(player, SKMC.number_correction(player, 1))
                    room:loseHp(p, SKMC.number_correction(player, 1))
                elseif use.card:hasFlag("wen_bian_no_damage_" .. p:objectName()) then
                    room:drawCards(player, 1, self:objectName())
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
AyakaTakamoto_HiraganaKeyakizaka:addSkill(sakamichi_wen_bian)

sgs.LoadTranslationTable {
    ["AyakaTakamoto_HiraganaKeyakizaka"] = "高本 彩花",
    ["&AyakaTakamoto_HiraganaKeyakizaka"] = "高本 彩花",
    ["#AyakaTakamoto_HiraganaKeyakizaka"] = "马尾女王",
    ["~AyakaTakamoto_HiraganaKeyakizaka"] = "問題が悪いんじゃないですかね？",
    ["designer:AyakaTakamoto_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:AyakaTakamoto_HiraganaKeyakizaka"] = "高本 彩花",
    ["illustrator:AyakaTakamoto_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_gong_dao"] = "弓道",
    [":sakamichi_gong_dao"] = "锁定技，你的攻击范围+X（X为你的体力值）。出牌阶段，你可以将一张【杀】当万箭齐发使用或打出。",
    ["sakamichi_wen_bian"] = "闻辨",
    [":sakamichi_wen_bian"] = "当你使用伤害类锦囊指定目标后，你可以选择其中一个目标，猜测其是否会受到此牌造成的伤害，若猜测：正确，你与其各摸一张牌；错误，你与其各失去1点体力。",
    ["@wen_bian_invoke"] = "你可以选择此【%arg】的一个目标发动【%arg2】",
    ["sakamichi_wen_bian:damage"] = "此【%arg】对%src造成伤害",
    ["sakamichi_wen_bian:no_damage"] = "此【%arg】不对%src造成伤害",
}
