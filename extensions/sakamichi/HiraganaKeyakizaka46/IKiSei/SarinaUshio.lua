require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SarinaUshio_HiraganaKeyakizaka = sgs.General(Sakamichi, "SarinaUshio_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
SKMC.IKiSei.SarinaUshio_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.SarinaUshio_HiraganaKeyakizaka = {
    name = {15, 10, 11, 11},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {25, "ji"},
    ji_kaku = {32, "ji"},
    soto_kaku = {37, "ji"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_shou_maiCard = sgs.CreateSkillCard {
    name = "sakamichi_shou_maiCard",
    skill_name = "sakamichi_shou_mai",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getHandcardNum() < sgs.Self:getHandcardNum()
                   and not sgs.Self:hasFlag("shou_mai_" .. to_select:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self:getEffectiveId(), true)
        local target = room:askForPlayerChosen(effect.from, room:getOtherPlayers(effect.to), self:getSkillName(),
            "@shou_mai_choice:" .. effect.to:objectName())
        if not room:askForUseSlashTo(effect.to, target,
            "@shou_mai_slash:" .. target:objectName() .. ":" .. effect.from:objectName() .. ":"
                .. SKMC.number_correction(effect.from, 1)) then
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to,
                SKMC.number_correction(effect.from, 1)))
        end
    end,
}
sakamichi_shou_mai = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_shou_mai",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_shou_maiCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        for _, p in sgs.qlist(player:getSiblings()) do
            if not player:hasFlag("shou_mai_" .. p:objectName()) and p:getHandcardNum() < player:getHandcardNum() then
                return true
            end
        end
        return false
    end,
}
SarinaUshio_HiraganaKeyakizaka:addSkill(sakamichi_shou_mai)

sakamichi_ge_pai = sgs.CreateTriggerSkill {
    name = "sakamichi_ge_pai",
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.to_place == sgs.Player_DiscardPile
            and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
            == sgs.CardMoveReason_S_REASON_DISCARD then
            for i = 0, move.card_ids:length() - 1, 1 do
                local id = move.card_ids:at(i)
                if room:getCardPlace(id) == sgs.Player_DiscardPile and player:hasSkill(self) then
                    local card = room:askForCard(player, sgs.Sanguosha:getCard(id):getClassName() .. "|.|.|hand",
                        "@ge_pai_show:::" .. SKMC.true_name(sgs.Sanguosha:getCard(id)), data, sgs.Card_MethodNone)
                    if card then
                        room:showCard(player, card:getEffectiveId())
                        room:obtainCard(player, id)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SarinaUshio_HiraganaKeyakizaka:addSkill(sakamichi_ge_pai)

sgs.LoadTranslationTable {
    ["SarinaUshio_HiraganaKeyakizaka"] = "潮 紗理菜",
    ["&SarinaUshio_HiraganaKeyakizaka"] = "潮 紗理菜",
    ["#SarinaUshio_HiraganaKeyakizaka"] = "平假圣母",
    ["~SarinaUshio_HiraganaKeyakizaka"] = "下からきました",
    ["designer:SarinaUshio_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:SarinaUshio_HiraganaKeyakizaka"] = "潮 紗理菜",
    ["illustrator:SarinaUshio_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_shou_mai"] = "收买",
    [":sakamichi_shou_mai"] = "出牌阶段每名角色限一次，你可以将一张手牌交给一名手牌少于你的角色，并令其对一名其他角色使用一张【杀】，若其未如此做，你对其造成1点伤害。",
    ["@shou_mai_choice"] = "请选择%src使用【杀】的目标",
    ["@shou_mai_slash"] = "请对%src使用一张【杀】否则受到来自%dest的%arg点伤害",
    ["sakamichi_ge_pai"] = "歌牌",
    [":sakamichi_ge_pai"] = "其他角色弃置牌时，你可以展示一张同名手牌，若如此做，你获得此牌。",
    ["@ge_pai_show"] = "你可以展示一张【%arg】获得此【%arg】",
}
