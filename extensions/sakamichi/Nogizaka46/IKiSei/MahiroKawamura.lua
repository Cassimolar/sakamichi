require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MahiroKawamura = sgs.General(Sakamichi, "MahiroKawamura", "Nogizaka46", 3, false)
SKMC.IKiSei.MahiroKawamura = true
SKMC.SeiMeiHanDan.MahiroKawamura = {
    name = {3, 7, 10, 9},
    ten_kaku = {10, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {19, "xiong"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_wu_niang_card = sgs.CreateSkillCard {
    name = "sakamichi_wu_niangCard",
    skill_name = "sakamichi_wu_niang",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:drawCards(effect.to, 2, self:getSkillName())
        if effect.to:getHandcardNum() > effect.to:getMaxHp() then
            effect.to:turnOver()
        end
    end,
}
sakamichi_wu_niang = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_wu_niang",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_wu_niang_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "h") and not player:hasUsed("#sakamichi_wu_niangCard")
    end,
}
MahiroKawamura:addSkill(sakamichi_wu_niang)

sakamichi_ge_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_ge_ji",
    events = {sgs.TurnedOver, sgs.ChainStateChanged},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                "invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. SKMC.number_correction(p, 1))) then
                room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MahiroKawamura:addSkill(sakamichi_ge_ji)

sgs.LoadTranslationTable {
    ["MahiroKawamura"] = "川村 真洋",
    ["&MahiroKawamura"] = "川村 真洋",
    ["#MahiroKawamura"] = "关西柴犬",
    ["~MahiroKawamura"] = "髪の毛に神経通ってる",
    ["designer:MahiroKawamura"] = "Cassimolar",
    ["cv:MahiroKawamura"] = "川村 真洋",
    ["illustrator:MahiroKawamura"] = "Cassimolar",
    ["sakamichi_wu_niang"] = "舞娘",
    [":sakamichi_wu_niang"] = "出牌阶段限一次，你可以弃置一张牌，令一名其他角色摸两张牌，然后若其手牌数大于体力上限，其翻面。",
    ["sakamichi_ge_ji"] = "歌姬",
    [":sakamichi_ge_ji"] = "当一名角色武将牌状态改变后，你可以对其造成1点伤害。",
    ["sakamichi_ge_ji:invoke"] = "是否发动【%arg】对%src 造成%arg2点伤害",
}
