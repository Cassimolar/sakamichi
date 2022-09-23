require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SeiraNagashima = sgs.General(Sakamichi, "SeiraNagashima", "Nogizaka46", 4, false)
SKMC.IKiSei.SeiraNagashima = true
SKMC.SeiMeiHanDan.SeiraNagashima = {
    name = {5, 10, 13, 19},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {23, "ji"},
    ji_kaku = {32, "ji"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

sakamichi_ling_jun = sgs.CreateTriggerSkill {
    name = "sakamichi_ling_jun",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() then
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                        "invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. damage.damage)) then
                        damage.to = p
                        damage.transfer = true
                        room:damage(damage)
                        room:drawCards(player, p:getLostHp(), self:objectName())
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
SeiraNagashima:addSkill(sakamichi_ling_jun)

sakamichi_sha_xiao = sgs.CreateTriggerSkill {
    name = "sakamichi_sha_xiao",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, damage.damage, self:objectName())
            if not player:isKongcheng() then
                local card = room:askForCard(player, ".|.|.|hand", "@sha_xiao_invoke", data, sgs.Card_MethodNone)
                if card then
                    player:addToPile("sha_xiao", card:getEffectiveId(), true)
                end
            end
        end
        return false
    end,
}
sakamichi_sha_xiao_max_cards = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_sha_xiao_max_cards",
    extra_func = function(self, target)
        if target:hasSkill("sakamichi_sha_xiao") then
            return target:getPile("sha_xiao"):length()
        end
    end,
}
SeiraNagashima:addSkill(sakamichi_sha_xiao)
if not sgs.Sanguosha:getSkill("#sakamichi_sha_xiao_max_cards") then
    SKMC.SkillList:append(sakamichi_sha_xiao_max_cards)
end

sgs.LoadTranslationTable {
    ["SeiraNagashima"] = "永島 聖羅",
    ["&SeiraNagashima"] = "永島 聖羅",
    ["#SeiraNagashima"] = "笑颜满开",
    ["~SeiraNagashima"] = "ふ～ん チューしてぇ",
    ["designer:SeiraNagashima"] = "Cassimolar",
    ["cv:SeiraNagashima"] = "永島 聖羅",
    ["illustrator:SeiraNagashima"] = "Cassimolar",
    ["sakamichi_ling_jun"] = "领军",
    [":sakamichi_ling_jun"] = "其他乃木坂46势力角色受到伤害时，你可以代替其承受此伤害，然后该角色摸X张牌（X为你已损失的体力值）。",
    ["sakamichi_ling_jun:invoke"] = "是否发动【%arg】代替%src 承受此次%arg2点伤害",
    ["sakamichi_sha_xiao"] = "傻笑",
    [":sakamichi_sha_xiao"] = "你受到伤害后，你可以摸等同于伤害量的牌，然后你可以将一张手牌置于你的武将牌上，称为「傻笑」，每有一张「傻笑」，你的手牌上限便＋１。",
    ["@sha_xiao_invoke"] = "你可以将一张手牌置于你的武将牌上称为“傻笑”",
    ["sha_xiao"] = "傻笑",
}
