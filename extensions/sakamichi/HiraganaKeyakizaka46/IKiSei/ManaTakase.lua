require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManaTakase_HiraganaKeyakizaka =
    sgs.General(Sakamichi, "ManaTakase_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 4, false)
SKMC.IKiSei.ManaTakase_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.ManaTakase_HiraganaKeyakizaka = {
	name = {10, 19, 13, 8},
	ten_kaku = {29, "te_shu_ge"},
	jin_kaku = {32, "ji"},
	ji_kaku = {21, "ji"},
	soto_kaku = {18, "ji"},
	sou_kaku = {50, "xiong"},
	GoGyouSanSai = {
		ten_kaku = "shui",
		jin_kaku = "mu",
		ji_kaku = "mu",
		san_sai = "da_ji",
	},
}

sakamichi_zhuan_yiCard = sgs.CreateSkillCard {
    name = "sakamichi_zhuan_yiCard",
    skill_name = "sakamichi_zhuan_yi",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getKingdom() ~= sgs.Self:getKingdom() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = room:askForCardChosen(effect.from, effect.to, "h", self:getSkillName())
        room:obtainCard(effect.from, card)
        local targets = room:getOtherPlayers(effect.from)
        targets:removeOne(effect.to)
        local target = room:askForYiji(effect.from, effect.from:handCards(), self:getSkillName(), false, false, false,
            1, targets)
        if effect.from:getKingdom() == effect.to:getKingdom() or effect.from:getKingdom() == target:getKingdom()
            or effect.to:getKingdom() == target:getKingdom() then
            room:drawCards(effect.from, 1, self:getSkillName())
        end
    end,
}
sakamichi_zhuan_yi = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_zhuan_yi",
    view_as = function(self)
        return sakamichi_zhuan_yiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_zhuan_yiCard")
    end,
}
ManaTakase_HiraganaKeyakizaka:addSkill(sakamichi_zhuan_yi)

sakamichi_xu_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_xu_yan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        local can_trigger = false
        if use.card:isVirtualCard() then
            if use.card:getSubcards():isEmpty() then
                can_trigger = true
            else
                for _, id in sgs.qlist(use.card:getSubcards()) do
                    if sgs.Sanguosha:getCard(id):objectName() ~= use.card:objectName() then
                        can_trigger = true
                        break
                    end
                end
            end
        else
            if use.card:objectName() ~= sgs.Sanguosha:getCard(use.card:getEffectiveId()):objectName() then
                can_trigger = true
            end
        end
        if can_trigger then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "xu_yan_invoke",
                true, true)
            if target then
                target:turnOver()
            end
        end
        return false
    end,
}
ManaTakase_HiraganaKeyakizaka:addSkill(sakamichi_xu_yan)

sgs.LoadTranslationTable {
    ["ManaTakase_HiraganaKeyakizaka"] = "高瀬 愛奈",
    ["&ManaTakase_HiraganaKeyakizaka"] = "高瀬 愛奈",
    ["#ManaTakase_HiraganaKeyakizaka"] = "练习笑容",
    ["~ManaTakase_HiraganaKeyakizaka"] = "I am a duck.",
    ["designer:ManaTakase_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:ManaTakase_HiraganaKeyakizaka"] = "高瀬 愛奈",
    ["illustrator:ManaTakase_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_zhuan_yi"] = "转译",
    [":sakamichi_zhuan_yi"] = "出牌阶段限一次，你可以获得一名势力与你不同的角色的一张手牌，然后你将一张手牌交给令一名其他角色，若你们三人的势力均不相同，你摸一张牌。",
    ["sakamichi_xu_yan"] = "虚言",
    [":sakamichi_xu_yan"] = "当你使用牌结算完成时，若此牌无对应的实体牌或对应的实体牌中有与此牌牌名不同牌，你可以令一名角色翻面。",
    ["xu_yan_invoke"] = "你可以令一名角色翻面",
}
