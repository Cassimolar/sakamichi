require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NaoYumiki = sgs.General(Sakamichi, "NaoYumiki", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.NaoYumiki = true
SKMC.SeiMeiHanDan.NaoYumiki = {
    name = {3, 4, 8, 8},
    ten_kaku = {7, "ji"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {23, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

sakamichi_tong_yao = sgs.CreateTriggerSkill {
    name = "sakamichi_tong_yao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@tong_yao",
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:objectName() ~= p:objectName() and p:getMark("@tong_yao") ~= 0
                    and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:removePlayerMark(p, "@tong_yao")
                    local x = p:getMark("Global_TurnCount") * room:alivePlayerCount()
                    local ids = room:getNCards(x, false)
                    local card_to_gotback = {}
                    local move = sgs.CardsMoveStruct()
                    move.card_ids = ids
                    move.to = nil
                    move.to_place = sgs.Player_PlaceTable
                    move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, p:objectName(),
                        self:objectName(), nil)
                    room:moveCardsAtomic(move, true)
                    room:fillAG(ids)
                    for _, id in sgs.qlist(ids) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:isDamageCard() and player:isAlive() then
                            room:takeAG(p, id, false)
                            room:useCard(sgs.CardUseStruct(card, p, player, false))
                        else
                            table.insert(card_to_gotback, id)
                        end
                    end
                    room:clearAG()
                    if #card_to_gotback > 0 then
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        dummy:deleteLater()
                        for _, id in ipairs(card_to_gotback) do
                            dummy:addSubcard(id)
                        end
                        if player:isAlive() then
                            room:obtainCard(player, dummy)
                        else
                            room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil,
                                self:objectName(), nil), nil)
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
NaoYumiki:addSkill(sakamichi_tong_yao)

sakamichi_gong_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_gong_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardFinished, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            if player:getPhase() == sgs.Player_Play then
                local use = data:toCardUse()
                if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
                    local ids = sgs.IntList()
                    if use.card:isVirtualCard() then
                        ids = use.card:getSubcards()
                    else
                        ids:append(use.card:getEffectiveId())
                    end
                    if ids:length() > 0 then
                        local all_place_discard = true
                        for _, id in sgs.qlist(ids) do
                            if room:getCardPlace(id) ~= sgs.Player_Discard then
                                all_place_discard = false
                                break
                            end
                        end
                        if all_place_discard then
                            if player:hasSkill(self) then
                                local not_has = true
                                for _, id in sgs.qlist(player:getPile("gong_yan")) do
                                    if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(use.card) then
                                        not_has = false
                                        break
                                    end
                                end
                                if not_has then
                                    player:addToPile("gong_yan", use.card)
                                else
                                    player:endPlayPhase()
                                end
                            end
                        end
                    end
                end
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() then
                        local has = false
                        for _, id in sgs.qlist(p:getPile("gong_yan")) do
                            if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(use.card) then
                                has = true
                                break
                            end
                        end
                        if has then
                            room:drawCards(p, 1, self:objectName())
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
NaoYumiki:addSkill(sakamichi_gong_yan)

sakamichi_mu_yu = sgs.CreateViewAsSkill {
    name = "sakamichi_mu_yu",
    n = 2,
    guhuo_type = "lsr",
    view_filter = function(self, selected, to_select)
        return #selected < 2 and not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local cd = sgs.Self:getTag(self:objectName()):toCard()
            cd:addSubcard(cards[1])
            cd:addSubcard(cards[2])
            cd:setSkillName(self:objectName())
            return cd
        end
        return false
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasFlag("mu_yu_used")
    end,
}
sakamichi_mu_yu_used = sgs.CreateTriggerSkill {
    name = "#sakamichi_mu_yu_used",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:getSkillName() == "sakamichi_mu_yu" then
            room:setPlayerFlag("mu_yu_used")
        end
        return false
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_mu_yu", "#sakamichi_mu_yu_used")
NaoYumiki:addSkill(sakamichi_mu_yu)
NaoYumiki:addSkill(sakamichi_mu_yu_used)

sakamichi_da_zhi = sgs.CreateTriggerSkill {
    name = "sakamichi_da_zhi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime, sgs.TrickCardCanceling},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and player:hasSkill(self) and move.to_place
                and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name and move.to_pile_name == "gong_yan" then
                local legal_card_name = {}
                for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isKindOf("BasicCard") or card:isNDTrick() then
                        if not table.contains(legal_card_name, SKMC.true_name(card)) then
                            table.insert(legal_card_name, SKMC.true_name(card))
                        end
                    end
                end
                for _, id in sgs.qlist(player:getPile("gong_yan")) do
                    table.removeOne(legal_card_name, SKMC.true_name(sgs.Sanguosha:getCard(id)))
                end
                if #legal_card_name == 0 then
                    room:gameOver(player:objectName())
                else
                    room:setPlayerMark(player, "&" .. self:objectName(), #legal_card_name)
                end
            end
        else
            local effect = data:toCardEffect()
            if effect.from and effect.from:hasSkill(self) and effect.card:isNDTrick() then
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NaoYumiki:addSkill(sakamichi_da_zhi)

sgs.LoadTranslationTable {
    ["NaoYumiki"] = "弓木 奈於",
    ["&NaoYumiki"] = "弓木 奈於",
    ["#NaoYumiki"] = "迷言制造机",
    ["~NaoYumiki"] = "お醤油って知ってますか？",
    ["designer:NaoYumiki"] = "Cassimolar",
    ["cv:NaoYumiki"] = "弓木 奈於",
    ["illustrator:NaoYumiki"] = "Cassimolar",
    ["sakamichi_tong_yao"] = "童谣",
    [":sakamichi_tong_yao"] = "限定技，其他角色结束阶段，你可以翻开牌堆顶X张牌，对其使用其中所有伤害牌，然后其获得剩余的牌（X为当前轮次数*场上角色数）。",
    ["@tong_yao"] = "童谣",
    ["sakamichi_gong_yan"] = "弓言",
    [":sakamichi_gong_yan"] = "锁定技，出牌阶段，你使用的基本牌和通常锦囊牌结算完成时，若你「弓言」中：未包含该牌名，将此牌置于你武将牌上称为「弓言」；已包含该牌名的牌，结束出牌阶段。其他角色出牌阶段使用你「弓言」中包含的牌名时，你摸一张牌。",
    ["gong_yan"] = "弓言",
    ["sakamichi_mu_yu"] = "木语",
    [":sakamichi_mu_yu"] = "出牌阶段限一次，你可将两张手牌当任意基本牌或通常锦囊牌使用。",
    ["sakamichi_da_zhi"] = "大智",
    [":sakamichi_da_zhi"] = "锁定技，当【弓言】记录所有可记录牌名时，你胜利。你的通常锦囊牌无法被【无懈可击】响应。",
}
