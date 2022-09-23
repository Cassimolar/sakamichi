require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AsukaSaito = sgs.General(Sakamichi, "AsukaSaito$", "Nogizaka46", 3, false)
SKMC.IKiSei.AsukaSaito = true
SKMC.SeiMeiHanDan.AsukaSaito = {
    name = {17, 18, 9, 11},
    ten_kaku = {35, "ji"},
    jin_kaku = {27, "ji_xiong_hun_he"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {28, "xiong"},
    sou_kaku = {55, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji",
    },
}

sakamichi_luo_zu = sgs.CreateDistanceSkill {
    name = "sakamichi_luo_zu$",
    frequency = sgs.Skill_Compulsory,
    correct_func = function(self, from, to)
        if from:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(from:getSiblings()) do
                if p:hasLordSkill(self) and not p:getOffensiveHorse() then
                    return -1
                end
            end
        end
        if to:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(to:getSiblings()) do
                if p:hasLordSkill(self) and not p:getDefensiveHorse() then
                    return 1
                end
            end
        end
    end,
}
AsukaSaito:addSkill(sakamichi_luo_zu)

sakamichi_tian_niao_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_tian_niao",
    response_pattern = "slash",
    filter_pattern = ".|red",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
}
sakamichi_tian_niao = sgs.CreateTriggerSkill {
    name = "sakamichi_tian_niao",
    view_as_skill = sakamichi_tian_niao_view_as,
    events = {sgs.SlashProceed, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.slash:getSkillName() == self:objectName() and effect.slash:getSuit() == sgs.Card_Heart then
                room:slashResult(effect, nil)
                return true
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == self:objectName()
                and sgs.Sanguosha:getCard(damage.card:getSubcards():first()) then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end,

}
AsukaSaito:addSkill(sakamichi_tian_niao)

sakamichi_an_niao = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_an_niao",
    response_pattern = "jink",
    filter_pattern = ".|black",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
}
sakamichi_an_niao_prohibit = sgs.CreateProhibitSkill {
    name = "#sakamichi_an_niao_prohibit",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_an_niao") and not to:faceUp() and (card:isKindOf("Slash") or card:isNDTrick())
    end,
}
AsukaSaito:addSkill(sakamichi_an_niao)
if not sgs.Sanguosha:getSkill("#sakamichi_an_niao_prohibit") then
    SKMC.SkillList:append(sakamichi_an_niao_prohibit)
end

sakamichi_zi_bi_card = sgs.CreateSkillCard {
    name = "sakamichi_zi_biCard",
    skill_name = "sakamichi_zi_bi",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:turnOver()
        effect.to:turnOver()
        if effect.from:getHandcardNum() > effect.to:getHandcardNum() then
            room:drawCards(effect.to, 1, self:getSkillName())
        elseif effect.from:getHandcardNum() < effect.to:getHandcardNum() then
            room:drawCards(effect.from, 1, self:getSkillName())
        end
    end,
}
sakamichi_zi_bi = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_zi_bi",
    view_as = function(self)
        return sakamichi_zi_bi_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_zi_biCard") and player:faceUp()
    end,
}
AsukaSaito:addSkill(sakamichi_zi_bi)

sgs.LoadTranslationTable {
    ["AsukaSaito"] = "齋藤 飛鳥",
    ["&AsukaSaito"] = "齋藤 飛鳥",
    ["#AsukaSaito"] = "神選美少女",
    ["~AsukaSaito"] = "どえせお前うクリスマス過ごす相手いねーだる！",
    ["designer:AsukaSaito"] = "Cassimolar",
    ["cv:AsukaSaito"] = "齋藤 飛鳥",
    ["illustrator:AsukaSaito"] = "Cassimolar",
    ["sakamichi_luo_zu"] = "裸足",
    [":sakamichi_luo_zu"] = "主公技，锁定技，你未装备进攻马/防御马时，其他乃木坂46角色/其他角色计算到其他角色/其他乃木坂46的距离-/+1。",
    ["sakamichi_tian_niao"] = "甜鸟",
    [":sakamichi_tian_niao"] = "你可以将一张红色牌当【杀】使用或打出，若此牌为红桃则此【杀】无法闪避，若此牌为【桃】则此【杀】伤害+1。",
    ["~sakamichi_tian_niao"] = "选择一张红色手牌 → 点击确定",
    ["sakamichi_an_niao"] = "暗鸟",
    [":sakamichi_an_niao"] = "你可以将一张黑色牌当【闪】使用或打出。你的武将牌背面向上时不是【杀】和通常锦囊牌的合法目标。",
    ["~sakamichi_an_niao"] = "选择一张黑色手牌 → 点击确定",
    ["sakamichi_zi_bi"] = "自闭",
    [":sakamichi_zi_bi"] = "出牌阶段限一次，若你的武将牌正面向上，你可以选择一名其他角色，你与其翻面，然后手牌数少的角色摸一张牌。",
}
