require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MeiHigashimura_HiraganaKeyakizaka = sgs.General(Sakamichi, "MeiHigashimura_HiraganaKeyakizaka", "HiraganaKeyakizaka46",
    4, false)
SKMC.IKiSei.MeiHigashimura_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.MeiHigashimura_HiraganaKeyakizaka = {
	name = {8, 7, 8, 8},
	ten_kaku = {15, "da_ji"},
	jin_kaku = {15, "da_ji"},
	ji_kaku = {16, "da_ji"},
	soto_kaku = {16, "da_ji"},
	sou_kaku = {31, "da_ji"},
	GoGyouSanSai = {
		ten_kaku = "tu",
		jin_kaku = "tu",
		ji_kaku = "tu",
		san_sai = "ji",
	},
}

sakamichi_wu_qiang_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_wu_qiang",
    filter_pattern = "EquipCard",
    response_pattern = "slash",
    response_or_use = true,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:addSubcard(card)
        slash:setSkillName(self:objectName())
        if card:isKindOf("Weapon") then
            slash:setFlags("wu_qiang_weapon")
        end
        return slash
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
}
sakamichi_wu_qiang = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_qiang",
    view_as_skill = sakamichi_wu_qiang_view_as,
    events = {sgs.Damage, sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == self:objectName() then
                local ids = sgs.IntList()
                if damage.card:isVirtualCard() then
                    ids = damage.card:getSubcards()
                else
                    ids:append(damage.card:getEffectiveId())
                end
                if ids:length() > 0 then
                    local all_place_table = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                            all_place_table = false
                            break
                        end
                    end
                    if all_place_table then
                        room:obtainCard(player, damage.card)
                    end
                end
            end
        elseif event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card:hasFlag("wu_qiang_weapon") then
                room:setCardFlag(card, "-wu_qiang_weapon")
            end
        end
        return false
    end,
}
sakamichi_wu_qiang_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_wu_qiang_target_mod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card)
        if card:hasFlag("wu_qiang_weapon") then
            return 1000
        else
            return 0
        end
    end,
}
MeiHigashimura_HiraganaKeyakizaka:addSkill(sakamichi_wu_qiang)
if not sgs.Sanguosha:getSkill("#sakamichi_wu_qiang_target_mod") then
    SKMC.SkillList:append(sakamichi_wu_qiang_target_mod)
end

sakamichi_dao_dan = sgs.CreateTriggerSkill {
    name = "sakamichi_dao_dan",
    events = {sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Collateral") then
            local targets = sgs.SPlayerList()
            local extra = nil
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not use.to:contains(p) and not room:isProhibited(player, p, use.card)
                    and use.card:targetFilter(sgs.PlayerList(), p, player) then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local tos = {}
                for _, t in sgs.qlist(use.to) do
                    table.insert(tos, t:objectName())
                end
                room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
                room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
                local used = room:askForUseCard(player, "@@ExtraCollateral", "@dao_dan_add:::collateral")
                room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(""))
                room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant("+"))
                if used then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:hasFlag("ExtraCollateralTarget") then
                            p:setFlags("-ExtraColllateralTarget")
                            extra = p
                            break
                        end
                    end
                    if extra == nil then
                        return false
                    end
                    use.to:append(extra)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}
sakamichi_dao_dan_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_dao_dan_target_mod",
    pattern = "Dismantlement,Snatch,Zhujinqiyuan",
    extra_target_func = function(self, from, card)
        if from:hasSkill("sakamichi_dao_dan") then
            return 1
        end
        return 0
    end,
}
MeiHigashimura_HiraganaKeyakizaka:addSkill(sakamichi_dao_dan)
if not sgs.Sanguosha:getSkill("#sakamichi_dao_dan_target_mod") then
    SKMC.SkillList:append(sakamichi_dao_dan_target_mod)
end

sgs.LoadTranslationTable {
    ["MeiHigashimura_HiraganaKeyakizaka"] = "東村 芽依",
    ["&MeiHigashimura_HiraganaKeyakizaka"] = "東村 芽依",
    ["#MeiHigashimura_HiraganaKeyakizaka"] = "淘气鬼",
    ["~MeiHigashimura_HiraganaKeyakizaka"] = "あーーー！",
    ["designer:MeiHigashimura_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MeiHigashimura_HiraganaKeyakizaka"] = "東村 芽依",
    ["illustrator:MeiHigashimura_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_wu_qiang"] = "舞枪",
    [":sakamichi_wu_qiang"] = "你可以将一张装备牌当【杀】使用或打出，若此牌为武器牌，此【杀】无距离限制，当此【杀】造成伤害时，你获得此牌。",
    ["sakamichi_dao_dan"] = "捣蛋",
    [":sakamichi_dao_dan"] = "你的破坏类锦囊可以额外指定一个目标。",
    ["@dao_dan_add"] = "请选择【%arg】的额外目标",
}
