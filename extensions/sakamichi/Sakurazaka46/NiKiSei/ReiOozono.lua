require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ReiOozono_Sakurazaka = sgs.General(Sakamichi, "ReiOozono_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.NiKiSei.ReiOozono_Sakurazaka = true
SKMC.SeiMeiHanDan.ReiOozono_Sakurazaka = {
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

sakamichi_ling_di = sgs.CreateTriggerSkill {
    name = "sakamichi_ling_di",
    events = {sgs.EventPhaseStart, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and not player:isKongcheng()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            player:throwAllHandCards()
            room:setPlayerFlag(player, "ling_di")
        elseif event == sgs.DrawNCards and player:hasFlag("ling_di") then
            local n = data:toInt()
            n = 0
            data:setValue(n)
            local ids = room:getDiscardPile()
            room:fillAG(ids)
            local list = sgs.IntList()
            for i = 1, SKMC.number_correction(player, 2) + player:getLostHp(), 1 do
                local id = room:askForAG(player, ids, true, self:objectName())
                if id ~= -1 then
                    ids:removeOne(id)
                    list:append(id)
                    room:takeAG(player, id, false)
                else
                    break
                end
            end
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            dummy:deleteLater()
            if list:length() ~= 0 then
                dummy:addSubcards(list)
                player:obtainCard(dummy)
            end
            dummy:clearSubcards()
            room:clearAG()
            room:broadcastInvoke("clearAG")
        end
        return false
    end,
}
ReiOozono_Sakurazaka:addSkill(sakamichi_ling_di)

sakamichi_hei_daiCard = sgs.CreateSkillCard {
    name = "sakamichi_hei_daiCard",
    skill_name = "sakamichi_hei_dai",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local ids = room:getNCards(1, false)
        local id = ids:first()
        local card = sgs.Sanguosha:getCard(id)
        room:moveCardTo(card, nil, nil, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,
            source:objectName(), self:objectName(), nil), true)
        if card:getSuit() == sgs.Card_Heart then
            local card_ex
            if not source:isKongcheng() then
                local card_data = sgs.QVariant()
                card_data:setValue(card)
                card_ex = room:askForCard(source, ".", "@hei_dai_exchange:::" .. card:objectName(), card_data,
                    sgs.Card_MethodNone)
            end
            if card_ex then
                local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(),
                    self:objectName(), nil)
                local reason2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE, source:objectName(),
                    self:objectName(), nil)
                local move1 = sgs.CardsMoveStruct()
                move1.card_ids:append(card_ex:getEffectiveId())
                move1.from = source
                move1.to = nil
                move1.to_place = sgs.Player_DrawPile
                move1.reason = reason1
                local move2 = sgs.CardsMoveStruct()
                move2.card_ids = ids
                move2.from = nil
                move2.to = source
                move2.to_place = sgs.Player_PlaceHand
                move2.reason = reason2
                local moves = sgs.CardsMoveList()
                moves:append(move1)
                moves:append(move2)
                room:moveCardsAtomic(moves, false)
            else
                room:moveCardTo(card, nil, nil, sgs.Player_DrawPile,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), nil, self:objectName(), nil),
                    false)
            end
            room:setPlayerFlag(source, "hei_dai")
        elseif card:getSuit() == sgs.Card_Spade then
            room:obtainCard(source, card)
        else
            room:moveCardTo(card, nil, nil, sgs.Player_DrawPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
                source:objectName(), nil, self:objectName(), nil), false)
            room:setPlayerFlag(source, "hei_dai")
        end
    end,
}
sakamichi_hei_dai = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_hei_dai",
    view_as = function()
        return sakamichi_hei_daiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("hei_dai")
    end,
}
ReiOozono_Sakurazaka:addSkill(sakamichi_hei_dai)

sakamichi_cai_zhi = sgs.CreateTriggerSkill {
    name = "sakamichi_cai_zhi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused, sgs.CardUsed, sgs.CardEffected},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isDamageCard() and damage.card:isNDTrick() then
                damage.damage = damage.damage + SKMC.number_correction(player, 1)
                data:setValue(damage)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isNDTrick() then
                local break_trick = {"snatch", "dismantlement", "collateral", "zhujinqiyuan"}
                local function_trick = {"god_salvation", "amazing_grace", "ex_nihilo", "nullification", "iron_chain",
                    "dongzhuxianji"}
                if table.contains(break_trick, use.card:objectName()) then
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
                if table.contains(function_trick, use.card:objectName()) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        elseif event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("DelayedTrick") then
                SKMC.send_message(room, "#cai_zhi", player, nil, nil, effect.card:toString(), self:objectName())
                return true
            end
        end
        return false
    end,
}
ReiOozono_Sakurazaka:addSkill(sakamichi_cai_zhi)

sgs.LoadTranslationTable {
    ["ReiOozono_Sakurazaka"] = "大園 玲",
    ["&ReiOozono_Sakurazaka"] = "大園 玲",
    ["#ReiOozono_Sakurazaka"] = "笔记侦探",
    ["~ReiOozono_Sakurazaka"] = "いけますね",
    ["designer:ReiOozono_Sakurazaka"] = "Cassimolar",
    ["cv:ReiOozono_Sakurazaka"] = "大園 玲",
    ["illustrator:ReiOozono_Sakurazaka"] = "Cassimolar",
    ["sakamichi_ling_di"] = "玲帝",
    [":sakamichi_ling_di"] = "准备阶段，你可以弃置所有手牌，若如此做，本回合摸牌阶段你放弃摸牌，并从弃牌堆选择获得X+2张牌（X为你已损失体力值）。",
    ["sakamichi_hei_dai"] = "黑带",
    [":sakamichi_hei_dai"] = "出牌阶段限一次，你可以展示牌堆顶一张牌，若此牌为：红桃，你可以用一张手牌替换之；黑桃，你获得之，且本技能视为未发动过。",
    ["@hei_dai_exchange"] = "你可以用一张手牌交换此【%arg】",
    ["sakamichi_cai_zhi"] = "才智",
    [":sakamichi_cai_zhi"] = "锁定技，你使用的伤害类锦囊造成伤害时伤害+1，你使用的破坏类锦囊无法响应，你使用功能类锦囊时摸一张牌，延时锦囊牌对你无效。",
    ["#cai_zhi"] = "%from 的【%arg】被触发，%card对 %from 无效",
}
