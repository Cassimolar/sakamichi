require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KiraMasumoto = sgs.General(Sakamichi, "KiraMasumoto", "Keyakizaka46", 3, false, true)
SKMC.NiKiSei.KiraMasumoto = true
SKMC.SeiMeiHanDan.KiraMasumoto = {
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

sakamichi_mi_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardResponded, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed or sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and card:isKindOf("BasicCard") or card:isNDTrick() then
                local result = SKMC.run_judge(room, player, self:objectName(), ".|spade", false)
                if result.card:getSuit() == sgs.Card_Spade then
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, "_ALL_TARGETS")
                    use.nullified_list = nullified_list
                    data:setValue(use)
                elseif result.card:getSuit() == sgs.Card_Heart then
                    room:setCardFlag(use.card, "mi_yan")
                elseif result.card:getSuit() == sgs.Card_Club then
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                elseif result.card:getSuit() == sgs.Card_Diamond then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        else
            if use.card:hasFlag("mi_yan") then
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
                        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                            "mi_yan_invoke:::" .. use.card:objectName(), true, true)
                        if target then
                            room:obtainCard(target, use.card)
                        end
                    end
                end
            end
        end
        return false
    end,
}
KiraMasumoto:addSkill(sakamichi_mi_yan)

sakamichi_ci_bei = sgs.CreateTriggerSkill {
    name = "sakamichi_ci_bei",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ci_bei",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:getMark("@ci_bei") ~= 0
                and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("to:" .. dying.who:objectName())) then
                room:removePlayerMark(p, "@ci_bei")
                room:recover(dying.who, sgs.RecoverStruct(p, nil, player:getMaxHp() - player:getHp()))
                break
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KiraMasumoto:addSkill(sakamichi_ci_bei)

sakamichi_hun_luanCard = sgs.CreateSkillCard {
    name = "sakamichi_hun_luanCard",
    skill_name = "sakamichi_hun_luan",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card_ids1 = effect.from:handCards()
        local card_ids2 = effect.to:handCards()
        if not card_ids1:isEmpty() then
            local move = sgs.CardsMoveStruct(card_ids1, effect.from, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), self:getSkillName(), ""))
            room:moveCardsAtomic(move, false)
        end
        if not card_ids2:isEmpty() then
            local move = sgs.CardsMoveStruct(card_ids2, effect.to, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.to:objectName(), self:getSkillName(), ""))
            room:moveCardsAtomic(move, false)
        end
        local card_ids = card_ids1
        for _, id in sgs.qlist(card_ids2) do
            card_ids:append(id)
        end
        local ids1 = sgs.IntList()
        local n = math.floor(card_ids:length() / 2)
        for i = 1, n, 1 do
            local table = sgs.QList2Table(card_ids)
            local n = math.random(1, #table)
            ids1:append(table[n])
            card_ids:removeOne(table[n])
        end
        local move1 = sgs.CardsMoveStruct(ids1, nil, effect.from, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, "", effect.from:objectName(), self:getSkillName(),
                ""))
        room:moveCardsAtomic(move1, false)
        local move2 = sgs.CardsMoveStruct(card_ids, nil, effect.to, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, "", effect.to:objectName(), self:getSkillName(), ""))
        room:moveCardsAtomic(move2, false)
    end,
}
sakamichi_hun_luan = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_hun_luan",
    view_as = function(self)
        return sakamichi_hun_luanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_hun_luanCard")
    end,
}
KiraMasumoto:addSkill(sakamichi_hun_luan)

sgs.LoadTranslationTable {
    ["KiraMasumoto"] = "増本 綺良",
    ["&KiraMasumoto"] = "増本 綺良",
    ["#KiraMasumoto"] = "天马行空",
    ["~KiraMasumoto"] = "私、虫は触れるのにダンボール触れないんです。",
    ["designer:KiraMasumoto"] = "Cassimolar",
    ["cv:KiraMasumoto"] = "増本 綺良",
    ["illustrator:KiraMasumoto"] = "Cassimolar",
    ["sakamichi_mi_yan"] = "迷言",
    [":sakamichi_mi_yan"] = "锁定技，当你使用基本牌或通常锦囊牌时，你须判定，若结果为：黑桃，此牌无效；红桃，此牌结算完成时你可以令一名其他角色获得之；梅花，此牌无法响应；方块，你摸一张牌。",
    ["sakamichi_ci_bei"] = "慈悲",
    [":sakamichi_ci_bei"] = "限定技，当一名角色进入濒死时，你可以令其回复所有体力。",
    ["sakamichi_ci_bei:to"] = "是否令%src将体力回复至体力上限",
    ["sakamichi_hun_luan"] = "混乱",
    [":sakamichi_hun_luan"] = "出牌阶段限一次，你可以选择一名有手牌的其他角色，将你们的手牌混合后，你获得其中的一半（向下取整），其获得剩余的牌。",
}
