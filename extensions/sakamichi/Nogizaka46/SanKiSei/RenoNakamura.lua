require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenoNakamura = sgs.General(Sakamichi, "RenoNakamura", "Nogizaka46", 4, false)
SKMC.SanKiSei.RenoNakamura = true
SKMC.SeiMeiHanDan.RenoNakamura = {
    name = {4, 7, 19, 2},
    ten_kaku = {11, "ji"},
    jin_kaku = {26, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {6, "da_ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_yu_zhe = sgs.CreateFilterSkill {
    name = "sakamichi_yu_zhe",
    view_filter = function(self, card)
        return card:isKindOf("TrickCard")
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:setSkillName(self:objectName())
        local cd = sgs.Sanguosha:getWrappedCard(card:getId())
        cd:takeOver(slash)
        return cd
    end,
}
sakamichi_yu_zhe_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_yu_zhe_target_mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_yu_zhe") then
            return 1
        else
            return 0
        end
    end,
    extra_target_func = function(self, from, card)
        if from:hasSkill("sakamichi_yu_zhe") then
            return 1
        else
            return 0
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_yu_zhe") then
            return 1
        else
            return 0
        end
    end,
}
RenoNakamura:addSkill(sakamichi_yu_zhe)
if not sgs.Sanguosha:getSkill("#sakamichi_yu_zhe_target_mod") then
    SKMC.SkillList:append(sakamichi_yu_zhe_target_mod)
end

sakamichi_cheng_yun_card = sgs.CreateSkillCard {
    name = "sakamichi_cheng_yunCard",
    skill_name = "sakamichi_cheng_yun",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@cheng_yun", 1)
        source:throwAllHandCards()
        room:setPlayerFlag(source, self:getSkillName())
        room:drawCards(source, 1, self:getSkillName())
    end,
}
sakamichi_cheng_yun_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_cheng_yun",
    view_as = function()
        return sakamichi_cheng_yun_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@cheng_yun") ~= 0 and not player:isKongcheng()
    end,
}
sakamichi_cheng_yun = sgs.CreateTriggerSkill {
    name = "sakamichi_cheng_yun",
    frequency = sgs.Skill_Limited,
    limit_mark = "@cheng_yun",
    view_as_skill = sakamichi_cheng_yun_view_as,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and player:hasFlag(self:objectName()) then
            for _, id in sgs.qlist(move.card_ids) do
                if id == player:getTag(self:objectName()):toInt() then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        if move.to and move.to:objectName() == player:objectName() and player:hasFlag(self:objectName())
            and move.reason.m_skillName and move.reason.m_skillName == self:objectName() then
            player:setTag(self:objectName(), sgs.QVariant(move.card_ids:first()))
        end
        return false
    end,
}
RenoNakamura:addSkill(sakamichi_cheng_yun)

sgs.LoadTranslationTable {
    ["RenoNakamura"] = "中村 麗乃",
    ["&RenoNakamura"] = "中村 麗乃",
    ["#RenoNakamura"] = "童颜",
    ["~RenoNakamura"] = "ゼンゼン ニホンゴ ダイスキダカラ",
    ["designer:RenoNakamura"] = "Cassimolar",
    ["cv:RenoNakamura"] = "中村 麗乃",
    ["illustrator:RenoNakamura"] = "Cassimolar",
    ["sakamichi_yu_zhe"] = "愚者",
    [":sakamichi_yu_zhe"] = "锁定技，你的锦囊牌均视为【杀】。出牌阶段，你使用【杀】的限制次数+1；你使用的【杀】的目标上限+1；你使用【杀】的距离+1。",
    ["sakamichi_cheng_yun"] = "乘云",
    [":sakamichi_cheng_yun"] = "限定技，出牌阶段，你可以弃置所有手牌，若如此做，你摸一张牌且本回合内此牌离开手牌时你重复此流程。",
    ["@cheng_yun"] = "乘云",
}
