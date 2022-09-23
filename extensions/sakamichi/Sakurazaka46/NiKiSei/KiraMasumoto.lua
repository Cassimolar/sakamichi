require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KiraMasumoto_Sakurazaka = sgs.General(Sakamichi, "KiraMasumoto_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.NiKiSei.KiraMasumoto_Sakurazaka = true
SKMC.SeiMeiHanDan.KiraMasumoto_Sakurazaka = {
    name = {14, 5, 14, 7},
    ten_kaku = {19, "xiong"},
    jin_kaku = {19, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {21, "ji"},
    sou_kaku = {40, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "shui",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

sakamichi_zeng_li = sgs.CreateTriggerSkill {
    name = "sakamichi_zeng_li",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        if n > 0 then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@zeng_li_invoke", true, true)
            if target then
                room:drawCards(target, 1, self:objectName())
                data:setValue(n - 1)
            end
        end
        return false
    end,
}

sakamichi_feng_chi = sgs.CreateTriggerSkill {
    name = "sakamichi_feng_chi",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local ids = sgs.IntList()
            for _, card in sgs.qlist(player:getJudgingArea()) do
                ids:append(card:getEffectiveId())
            end
            if not ids:isEmpty() then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                dummy:deleteLater()
                dummy:addSubcards(ids)
                room:throwCard(dummy, player, player)
            end
        end
        return false
    end,
}
KiraMasumoto_Sakurazaka:addSkill(sakamichi_feng_chi)

sakamichi_you_yue = sgs.CreateTriggerSkill {
    name = "sakamichi_you_yue",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Discard and player:hasSkill(self) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() < player:getHandcardNum() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1,
                    targets, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                        self:objectName(), nil), "@you_yue_invoke", true)
                if target then
                    room:setPlayerFlag(target, "you_yue" .. player:objectName())
                end
            end
        elseif player:getPhase() == sgs.Player_Draw then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:hasFlag("you_yue" .. p:objectName()) then
                    room:drawCards(p, 1, self:objectName())
                    room:setPlayerFlag(player, "-you_yue" .. p:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KiraMasumoto_Sakurazaka:addSkill(sakamichi_you_yue)

sakamichi_qu_yueCard = sgs.CreateSkillCard {
    name = "sakamichi_qu_yueCard",
    skill_name = "sakamichi_qu_yue",
    filter = function(self, targets, to_seleted)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local ids = room:getNCards(3, false)
        local move = sgs.CardsMoveStruct()
        move.card_ids = ids
        move.to = nil
        move.to_place = sgs.Player_PlaceTable
        move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, effect.to:objectName(),
            self:objectName(), nil)
        room:moveCardsAtomic(move, true)
        if effect.to:objectName() == effect.from:objectName() then
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            dummy:deleteLater()
            dummy:addSubcards(ids)
            room:obtainCard(effect.from, dummy)
        else
            for _, id in sgs.qlist(ids) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("Slash") then
                    card:setSkillName(self:objectName())
                    room:useCard(sgs.CardUseStruct(card, effect.from, effect.to))
                    ids:removeOne(id)
                end
            end
            if not ids:isEmpty() then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                dummy:deleteLater()
                dummy:addSubcards(ids)
                room:loseHp(effect.to, SKMC.number_correction(effect.from, 1))
                room:obtainCard(effect.to, dummy)
            end
        end
    end,
}
sakamichi_qu_yue = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_qu_yue",
    view_as = function()
        return sakamichi_qu_yueCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_qu_yueCard")
    end,
}
KiraMasumoto_Sakurazaka:addSkill(sakamichi_qu_yue)

sgs.LoadTranslationTable {
    ["KiraMasumoto_Sakurazaka"] = "増本 綺良",
    ["&KiraMasumoto_Sakurazaka"] = "増本 綺良",
    ["#KiraMasumoto_Sakurazaka"] = "起爆剂",
    ["~KiraMasumoto_Sakurazaka"] = "恐竜だよ～",
    ["designer:KiraMasumoto_Sakurazaka"] = "Cassimolar",
    ["cv:KiraMasumoto_Sakurazaka"] = "増本 綺良",
    ["illustrator:KiraMasumoto_Sakurazaka"] = "Cassimolar",
    ["sakamichi_zeng_li"] = "赠礼",
    [":sakamichi_zeng_li"] = "摸牌阶段，你可以少摸一张牌，然后选择一名其他角色，令其摸一张牌。",
    ["sakamichi_feng_chi"] = "风驰",
    [":sakamichi_feng_chi"] = "准备阶段，你可以选择一个花色并进行判定，若结果不为该花色，你弃置判定区所有牌。",
    ["sakamichi_you_yue"] = "优越",
    [":sakamichi_you_yue"] = "弃牌阶段开始时，你可以将一张手牌交给一名手牌数小于你的角色，若如此做，其下个摸牌阶段开始时，你摸一张牌。",
    ["@you_yue_invoke"] = "你可以将一张手牌交给一名手牌数小于你的角色",
    ["sakamichi_qu_yue"] = "取悦",
    [":sakamichi_qu_yue"] = "出牌阶段限一次，你可以选择一名角色令其翻开牌堆顶的三张牌，若其中有【杀】则视为你对其使用之，然后其失去1点体力获得剩余的牌，若该角色为你，你直接获得这三张牌且不失去体力。",
}
