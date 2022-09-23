require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MisaEto = sgs.General(Sakamichi, "MisaEto", "Nogizaka46", 4, false)
SKMC.IKiSei.MisaEto = true
SKMC.SeiMeiHanDan.MisaEto = {
    name = {16, 18, 9, 11},
    ten_kaku = {34, "xiong"},
    jin_kaku = {27, "ji_xiong_hun_he"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {54, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_jiu_xian_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jiu_xian",
    response_pattern = "analeptic",
    filter_pattern = ".|black|.|hand",
    view_as = function(self, card)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
        analeptic:setSkillName(self:objectName())
        analeptic:addSubcard(card)
        return analeptic
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
        card:deleteLater()
        if player:isCardLimited(card, sgs.Card_MethodUse) or player:isProhibited(player, card) then
            return false
        end
        return
            player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, card)
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "analeptic")
    end,
}
sakamichi_jiu_xian = sgs.CreateTriggerSkill {
    name = "sakamichi_jiu_xian",
    view_as_skill = sakamichi_jiu_xian_view_as,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Analeptic") and use.card:getSkillName() == self:objectName() then
            if use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
            end
        end
    end,
}
sakamichi_jiu_xian_Mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_jiu_xian_Mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Analeptic",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_jiu_xian") then
            return 1000
        else
            return 0
        end
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_jiu_xian", "#sakamichi_jiu_xian_Mod")
MisaEto:addSkill(sakamichi_jiu_xian)
MisaEto:addSkill(sakamichi_jiu_xian_Mod)

sakamichi_guan_jiu = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_jiu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Slash") and not use.card:hasFlag("drank") and use.from:hasSkill(self) then
                SKMC.send_message(room, "#guan_jiu_from", player, nil, nil, use.card:toString(), self:objectName())
                room:setCardFlag(use.card, "drank")
                use.card:setTag("drank", sgs.QVariant(use.card:getTag("drank"):toInt() + 1))
                return false
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and not damage.card:hasFlag("drank") then
                SKMC.send_message(room, "#guan_jiu_to", damage.from, nil, nil, damage.card:toString(), self:objectName())
                damage.damage = damage.damage + 1
                data:setValue(damage)
                return false
            end
        end
    end,
}
MisaEto:addSkill(sakamichi_guan_jiu)

sgs.LoadTranslationTable {
    ["MisaEto"] = "衛藤 美彩",
    ["&MisaEto"] = "衛藤 美彩",
    ["#MisaEto"] = "酒仙",
    ["~MisaEto"] = "チン 、ゲン 、サイ！♡",
    ["designer:MisaEto"] = "Cassimolar",
    ["cv:MisaEto"] = "衛藤 美彩",
    ["illustrator:MisaEto"] = "Cassimolar",
    ["sakamichi_jiu_xian"] = "酒仙",
    [":sakamichi_jiu_xian"] = "你可以将黑色手牌当【酒】使用或打出，你使用【酒】无次数限制。",
    ["~sakamichi_jiu_xian"] = "选择一张黑色手牌 → 点击确定",
    ["sakamichi_guan_jiu"] = "灌酒",
    [":sakamichi_guan_jiu"] = "锁定技，你使用的【杀】将额外附加一张【酒】，当你受到【杀】造成的伤害时，若此【杀】不为【酒】【杀】则此伤害+1。",
    ["#guan_jiu_from"] = "%from 的【%arg】被触发，此【%card】被视为【<font color=\"yellow\"><b>酒</b></font>】【<font color=\"yellow\"><b>杀</b></font>】。",
    ["#guan_jiu_to"] = "%to 的【%arg】被触发，%from 的此张【%card】对 %to 造成的伤害增加<font color=\"yellow\"><b>1</b></font>点。",
}
