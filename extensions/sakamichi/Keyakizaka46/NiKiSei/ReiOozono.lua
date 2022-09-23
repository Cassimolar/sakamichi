require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ReiOozono = sgs.General(Sakamichi, "ReiOozono", "Keyakizaka46", 3, false, true)
SKMC.NiKiSei.ReiOozono = true
SKMC.SeiMeiHanDan.ReiOozono = {
    name = {3, 13, 9},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {9, "xiong"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {25, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_xin_li_xue = sgs.CreateTriggerSkill {
    name = "sakamichi_xin_li_xue",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local card = room:askForCard(p, ".|.|.|hand", "@xin_li_xue_invoke", data, sgs.Card_MethodNone)
                if card then
                    p:addToPile("xin_li_xue", card:getEffectiveId(), false)
                end
            end
        elseif event == sgs.CardUsed and player:getPhase() == sgs.Player_Play then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and use.from and use.from:objectName()
                == player:objectName() and not player:hasFlag("xin_li_xue_used") then
                room:setPlayerFlag(player, "xin_li_xue_used")
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:getPile("xin_li_xue"):isEmpty() then
                        local card1 = sgs.Sanguosha:getCard(p:getPile("xin_li_xue"):first())
                        local card2 = use.card
                        local suit, number, name = card1:getSuit() == card2:getSuit(),
                            card1:getNumber() == card2:getNumber(), SKMC.true_name(card1) == SKMC.true_name(card2)
                        if suit or number or name then
                            room:showCard(p, p:getPile("xin_li_xue"):first())
                            if suit then
                                room:drawCards(p, 2, self:objectName())
                            end
                            if number then
                                player:turnOver()
                            end
                            if name then
                                player:endPlayPhase()
                            end
                            room:throwCard(card1, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "",
                                p:objectName(), self:objectName(), ""), p, p)
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if not p:getPile("xin_li_xue"):isEmpty() then
                    room:throwCard(sgs.Sanguosha:getCard(p:getPile("xin_li_xue"):first()), sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", p:objectName(), self:objectName(), ""), nil)
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("damage:" .. player:objectName())) then
                        room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
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
ReiOozono:addSkill(sakamichi_xin_li_xue)

sakamichi_bi_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_bi_ji",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and (use.card:isKindOf("TrickCard") and not use.card:isKindOf("DelayedTrick"))
            and use.from:objectName() == player:objectName() then
            local ids = sgs.IntList()
            if use.card:isVirtualCard() then
                ids = use.card:getSubcards()
            else
                ids:append(use.card:getEffectiveId())
            end
            if not ids:isEmpty() then
                local in_discard = true
                for _, id in sgs.qlist(ids) do
                    if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                        in_discard = false
                        break
                    end
                end
                if in_discard then
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if p:objectName() ~= player:objectName() and not p:isKongcheng() then
                            if room:askForCard(p, ".|.|.|hand", "@bi_ji_discard:" .. player:objectName() .. "::"
                                .. use.card:objectName(), data, self:objectName()) then
                                room:obtainCard(p, use.card)
                                break
                            end
                        end
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
ReiOozono:addSkill(sakamichi_bi_ji)

sgs.LoadTranslationTable {
    ["ReiOozono"] = "大園 玲",
    ["&ReiOozono"] = "大園 玲",
    ["#ReiOozono"] = "才色兼备",
    ["~ReiOozono"] = "選択肢にあふれている人生を楽しんでください",
    ["designer:ReiOozono"] = "Cassimolar",
    ["cv:ReiOozono"] = "大園 玲",
    ["illustrator:ReiOozono"] = "Cassimolar",
    ["sakamichi_xin_li_xue"] = "心理学",
    [":sakamichi_xin_li_xue"] = "其他角色准备阶段，你可以将一张手牌置于武将牌旁，若如此做，其本回合使用第一张牌时，若其使用的牌与此牌：花色/点数/牌名相同，你摸两张牌/令其翻面/结束其出牌阶段，并将此牌置入弃牌堆，结束阶段，若此牌在你武将牌旁，你将此牌置入弃牌堆并对其造成1点伤害。",
    ["sakamichi_xin_li_xue:damage"] = "是否对%src造成1点伤害",
    ["@xin_li_xue_invoke"] = "你可以发动【心理学】将一张手牌置于武将牌旁",
    ["xin_li_xue"] = "心理学",
    ["sakamichi_bi_ji"] = "笔记",
    [":sakamichi_bi_ji"] = "当一名其他角色使用的通常锦囊牌结算完成时，你可以弃置一张手牌获得之。",
    ["@bi_ji_discard"] = "你可以弃置一张手牌来获得%src使用的【%arg】",
}
