require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkihoOnuma = sgs.General(Sakamichi, "AkihoOnuma", "Keyakizaka46", 3, false, true)
SKMC.NiKiSei.AkihoOnuma = true
SKMC.SeiMeiHanDan.AkihoOnuma = {
    name = {3, 8, 12, 9},
    ten_kaku = {11, "ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_heng_tiao = sgs.CreateTriggerSkill {
    name = "sakamichi_heng_tiao",
    events = {sgs.DamageCaused, sgs.DamageInflicted, sgs.TurnedOver},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if player:faceUp() and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("plus")) then
                player:turnOver()
                damage.damage = damage.damage + SKMC.number_correction(player, 1)
                data:setValue(damage)
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:faceUp() and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("minus")) then
                player:turnOver()
                damage.damage = damage.damage - SKMC.number_correction(player, 1)
                data:setValue(damage)
                if damage.damage < 1 then
                    return true
                end
            end
        else
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw")) then
                room:drawCards(player, 2, self:objectName())
            end
        end
        return false
    end,
}
AkihoOnuma:addSkill(sakamichi_heng_tiao)

sakamichi_jing_moCard = sgs.CreateSkillCard {
    name = "sakamichi_jing_moCard",
    skill_name = "sakamichi_jing_mo",
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:distanceTo(to_select) == 1
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        effect.to:obtainCard(card)
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(effect.from)) do
            if effect.from:distanceTo(p) == 1 then
                targets:append(p)
            end
        end
        if not targets:isEmpty() then
            local target = room:askForPlayerChosen(effect.from, targets, self:getSkillName(), "@jing_mo_invoke", true,
                true)
            if target then
                room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, target,
                    SKMC.number_correction(effect.from, 1)))
            end
        end
    end,
}
sakamichi_jing_mo = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jing_mo",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skillcard = sakamichi_jing_moCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        for _, p in sgs.qlist(player:getSiblings()) do
            if player:distanceTo(p) == 1 then
                return not player:isKongcheng() and not player:hasUsed("#sakamichi_jing_moCard")
            end
        end
        return false
    end,
}
AkihoOnuma:addSkill(sakamichi_jing_mo)

sakamichi_zhu_luan = sgs.CreateTriggerSkill {
    name = "sakamichi_zhu_luan",
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag("FirstRound"):toBool() and move.card_ids:length() >= 2 and move.to and move.to:objectName()
            == player:objectName() and move.to_place == sgs.Player_PlaceHand then
            local current = room:getCurrent()
            if current:objectName() == player:objectName()
                or room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:::" .. self:objectName())) then
                room:drawCards(current, 1, self:objectName())
            end
        end
        return false
    end,
}
AkihoOnuma:addSkill(sakamichi_zhu_luan)

sgs.LoadTranslationTable {
    ["AkihoOnuma"] = "大沼 晶保",
    ["&AkihoOnuma"] = "大沼 晶保",
    ["#AkihoOnuma"] = "水产偶像",
    ["~AkihoOnuma"] = "なんだと思いますか？",
    ["designer:AkihoOnuma"] = "Cassimolar",
    ["cv:AkihoOnuma"] = "大沼 晶保",
    ["illustrator:AkihoOnuma"] = "Cassimolar",
    ["sakamichi_heng_tiao"] = "横跳",
    [":sakamichi_heng_tiao"] = "当你造成/受到伤害时，若你正面向上，你可以翻面，若如此做，你令此次伤害+1/-1。你翻面时，你可以摸两张牌。",
    ["sakamichi_heng_tiao:plus"] = "是否将你的武将牌翻面来令此次伤害+1",
    ["sakamichi_heng_tiao:minus"] = "是否将你的武将牌翻面来令此次伤害-1",
    ["sakamichi_heng_tiao:draw"] = "是否摸两张牌",
    ["sakamichi_jing_mo"] = "井魔",
    [":sakamichi_jing_mo"] = "出牌阶段限一次，你可以将一张手牌交给一名你与其距离为1的角色，若如此做，你可以对一名你与其距离为1的角色造成1点伤害。",
    ["@jing_mo_invoke"] = "你可以对一名距离为1的角色造成1点伤害",
    ["sakamichi_zhu_luan"] = "助乱",
    [":sakamichi_zhu_luan"] = "当你一次性获得至少两张手牌时，你可以令当前回合角色摸一张牌。",
    ["sakamichi_zhu_luan:draw"] = "是否发动【%arg】令当前回合角色摸一张牌",
}
