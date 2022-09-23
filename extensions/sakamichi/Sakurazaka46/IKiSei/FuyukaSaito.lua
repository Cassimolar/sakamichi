require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

FuyukaSaito_Sakurazaka = sgs.General(Sakamichi, "FuyukaSaito_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.IKiSei.FuyukaSaito_Sakurazaka = true
SKMC.SeiMeiHanDan.FuyukaSaito_Sakurazaka = {
    name = {17, 18, 5, 17, 7},
    ten_kaku = {35, "ji"},
    jin_kaku = {23, "ji"},
    ji_kaku = {29, "te_shu_ge"},
    soto_kaku = {41, "ji"},
    sou_kaku = {64, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_chou_sheCard = sgs.CreateSkillCard {
    name = "sakamichi_chou_sheCard",
    skill_name = "sakamichi_chou_she",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() then
            return to_select:getEquip(sgs.Sanguosha:getCard(self:getEffectiveId()):getRealCard():toEquipCard()
                :location()) == nil
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), self:getSkillName(), "")
        room:moveCardTo(self, source, target, sgs.Player_PlaceEquip, reason)
        room:addPlayerMark(effect.to, "chou_she", 1)
        room:addPlayerMark(effect.to, "Equips_Nullified_to_Yourself", 1)
    end,
}
sakamichi_chou_she_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_chou_she",
    filter_pattern = "EquipCard",
    view_as = function(self, card)
        local cd = sakamichi_chou_sheCard:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}
sakamichi_chou_she = sgs.CreateTriggerSkill {
    name = "sakamichi_chou_she",
    view_as_skill = sakamichi_chou_she_view_as,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start and player:getMark("chou_she") ~= 0 then
            room:setPlayerMark(player, "chou_she", player:getMark("chou_she"))
            room:removePlayerMark(player, "Equips_Nullified_to_Yourself", player:getMark("chou_she"))
        end
        return false
    end,
}
FuyukaSaito_Sakurazaka:addSkill(sakamichi_chou_she)

sakamichi_di_pin = sgs.CreateTriggerSkill {
    name = "sakamichi_di_pin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:getEquips():length() < damage.to:getEquips():length() then
            damage.damage = damage.damage - SKMC.number_correction(player, 1)
            data:setValue(damage)
            if damage.damage == 0 then
                return true
            end
        end
        return false
    end,
}
FuyukaSaito_Sakurazaka:addSkill(sakamichi_di_pin)

sakamichi_tou_daiCard = sgs.CreateSkillCard {
    name = "sakamichi_tou_daiCard",
    skill_name = "sakamichi_tou_dai",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@tou_dai")
        room:setPlayerFlag(effect.from, "tou_dai" .. effect.to:objectName())
    end,
}
sakamichi_tou_dai_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_tou_dai",
    view_filter = function(self, to_select)
        return (not to_select:isKindOf("BasicCard") and to_select:getSuit() == sgs.Card_Heart)
                   or to_select:isKindOf("EquipCard")
    end,
    view_as = function(self, card)
        local cd = sakamichi_tou_daiCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@tou_dai") ~= 0
    end,
}
sakamichi_tou_dai = sgs.CreateTriggerSkill {
    name = "sakamichi_tou_dai",
    view_as_skill = sakamichi_tou_dai_view_as,
    frequency = sgs.Skill_Limited,
    limit_mark = "@tou_dai",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if player:hasFlag("tou_dai" .. p:objectName()) then
                for i = SKMC.number_correction(player, 1), damage.damage, SKMC.number_correction(player, 1) do
                    if p:isWounded() then
                        room:recover(p, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                    end
                end
            end
        end
        return false
    end,
}
FuyukaSaito_Sakurazaka:addSkill(sakamichi_tou_dai)

sgs.LoadTranslationTable {
    ["FuyukaSaito_Sakurazaka"] = "齋藤 冬優花",
    ["&FuyukaSaito_Sakurazaka"] = "齋藤 冬優花",
    ["#FuyukaSaito_Sakurazaka"] = "品味泥沼",
    ["~FuyukaSaito_Sakurazaka"] = "何で？",
    ["designer:FuyukaSaito_Sakurazaka"] = "Cassimolar",
    ["cv:FuyukaSaito_Sakurazaka"] = "齋藤 冬優花",
    ["illustrator:FuyukaSaito_Sakurazaka"] = "Cassimolar",
    ["sakamichi_chou_she"] = "丑设",
    [":sakamichi_chou_she"] = "出牌阶段限一次，你可以将一张装备牌置于一名其他角色的装备区，若如此做，直到其下个回合开始，其装备无效。",
    ["sakamichi_di_pin"] = "低品",
    [":sakamichi_di_pin"] = "锁定技，你对装备区装备数量多于你的角色造成伤害时，此伤害-1。",
    ["sakamichi_tou_dai"] = "头带",
    [":sakamichi_tou_dai"] = "限定技，出牌阶段，你可以弃置一张红桃非基本牌或一张装备牌并选择一名其他角色，本回合内，你每造成1点伤害令其回复1点体力。",
}
