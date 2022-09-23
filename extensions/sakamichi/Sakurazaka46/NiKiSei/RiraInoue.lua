require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RiraInoue_Sakurazaka = sgs.General(Sakamichi, "RiraInoue_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.NiKiSei.RiraInoue_Sakurazaka = true
SKMC.SeiMeiHanDan.RiraInoue_Sakurazaka = {
    name = {4, 3, 11, 6},
    ten_kaku = {7, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {17, "ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "xiong",
    },
}

sakamichi_jie_su = sgs.CreateTriggerSkill {
    name = "sakamichi_jie_su",
    events = {sgs.TurnOver},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:objectName() ~= player:objectName() and p:faceUp()
                and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                p:turnOver()
                if player:getEquips():length() ~= 0 then
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    dummy:deleteLater()
                    dummy:addSubcards(player:getEquips())
                    room:obtainCard(p, dummy)
                    return true
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RiraInoue_Sakurazaka:addSkill(sakamichi_jie_su)

sakamichi_e_kouCard = sgs.CreateSkillCard {
    name = "sakamichi_e_kouCard",
    skill_name = "sakamichi_e_kou",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = room:askForCard(effect.to, "Slash", "eko_invoke:" .. effect.from:objectName(), sgs.QVariant(),
            sgs.Card_MethodNone)
        if card then
            room:obtainCard(effect.from, card, true)
        else
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            slash:deleteLater()
            slash:setSkillName(self:getSkillName())
            room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to), false)
        end
    end,
}
sakamichi_e_kou = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_e_kou",
    view_as = function(self)
        return sakamichi_e_kouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_e_kouCard")
    end,
}
RiraInoue_Sakurazaka:addSkill(sakamichi_e_kou)

sakamichi_e_yi = sgs.CreateTriggerSkill {
    name = "sakamichi_e_yi",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and not damage.to:isKongcheng()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:showAllCards(damage.to)
            local ids = sgs.IntList()
            for _, id in sgs.qlist(damage.to:handCards()) do
                if sgs.Sanguosha:getCard(id):isDamageCard() then
                    ids:append(id)
                end
            end
            if not ids:isEmpty() then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                dummy:deleteLater()
                dummy:addSubcards(ids)
                room:obtainCard(player, dummy)
            else
                room:damage(sgs.DamageStruct(self:objectName(), damage.to, player, SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
RiraInoue_Sakurazaka:addSkill(sakamichi_e_yi)

sgs.LoadTranslationTable {
    ["RiraInoue_Sakurazaka"] = "井上 梨名",
    ["&RiraInoue_Sakurazaka"] = "井上 梨名",
    ["#RiraInoue_Sakurazaka"] = "欺诈师",
    ["~RiraInoue_Sakurazaka"] = "頑張るなら良いの欲しい•••",
    ["designer:RiraInoue_Sakurazaka"] = "Cassimolar",
    ["cv:RiraInoue_Sakurazaka"] = "井上 梨名",
    ["illustrator:RiraInoue_Sakurazaka"] = "Cassimolar",
    ["sakamichi_jie_su"] = "借宿",
    [":sakamichi_jie_su"] = "其他角色翻至背面向上时，若你正面向上，你可以翻面并获得其装备区所有牌，然后防止其翻面。",
    ["sakamichi_jie_su:invoke"] = "你可以代替%src将武将牌翻面",
    ["sakamichi_e_kou"] = "恶口",
    [":sakamichi_e_kou"] = "出牌阶段限一次，你可以令一名其他角色选择交给你一张【杀】或视为你对其使用一张【杀】。",
    ["eko_invoke"] = "你需交给%src一张【杀】否则视为其对你使用一张【杀】",
    ["sakamichi_e_yi"] = "恶意",
    [":sakamichi_e_yi"] = "你使用【杀】对其他角色造成伤害后，你可以展示其手牌，若其中：有伤害牌，你获得之；没有伤害牌，你受到其造成的1点伤害。",
}
