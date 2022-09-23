require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HonoTamura_Sakurazaka = sgs.General(Sakamichi, "HonoTamura_Sakurazaka$", "Sakurazaka46", 3, false)
SKMC.NiKiSei.HonoTamura_Sakurazaka = true
SKMC.SeiMeiHanDan.HonoTamura_Sakurazaka = {
    name = {5, 7, 9, 2},
    ten_kaku = {12, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {11, "ji"},
    soto_kaku = {7, "ji"},
    sou_kaku = {23, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_liu_dan = sgs.CreateTriggerSkill {
    name = "sakamichi_liu_dan$",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if player:getKingdom() == "Sakurazaka46" and use.card:isKindOf("Slash") then
            local can_trigger = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasLordSkill(self) then
                    can_trigger = true
                    break
                end
            end
            if can_trigger then
                local extra_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(use.to) do
                    for _, pl in sgs.qlist(room:getAlivePlayers()) do
                        if pl:getNextAlive():objectName() == p:objectName() and not use.to:contains(pl)
                            and not extra_targets.contains(pl) and pl:getKingdom() ~= "Sakurazaka46" then
                            extra_targets:append(pl)
                        end
                    end
                    if not use.to:contains(p:getNextAlive()) and not extra_targets.contains(p:getNextAlive())
                        and p:getNextAlive():getKingdom() ~= "Sakurazaka46" then
                        extra_targets:append(p:getNextAlive())
                    end
                end
                if not extra_targets:isEmpty() then
                    for _, p in sgs.qlist(extra_targets) do
                        use.to:append(p)
                    end
                    data:setValue(use)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HonoTamura_Sakurazaka:addSkill(sakamichi_liu_dan)

sakamichi_jie_daoCard = sgs.CreateSkillCard {
    name = "sakamichi_jie_daoCard",
    skill_name = "sakamichi_jie_dao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card =
            room:askForCardChosen(effect.from, effect.to, "he", self:getSkillName(), false, sgs.Card_MethodNone)
        local place = room:getCardPlace(card)
        room:obtainCard(effect.from, card, place ~= sgs.Player_PlaceHand)
        if place == sgs.Player_PlaceHand then
            room:setPlayerMark(effect.to, "jie_dao_hand_" .. effect.from:objectName() .. "_start_end_clear", 1)
        else
            room:setPlayerMark(effect.to, "jie_dao_equip_" .. effect.from:objectName() .. "_start_end_clear", 1)
        end
    end,
}
sakamichi_jie_dao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_jie_dao",
    view_as = function()
        return sakamichi_jie_daoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_jie_daoCard")
    end,
}
sakamichi_jie_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_jie_dao",
    view_as_skill = sakamichi_jie_dao_view_as,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "jie_dao_") and player:getMark(mark) ~= 0 then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if string.find(mark, p:objectName()) then
                            if string.find(mark, "hand") then
                                local card = room:askForCard(p, ".|.|.|hand",
                                    "@jie_dao_invoke_hand:" .. player:objectName(), data, sgs.Card_MethodNone)
                                if card then
                                    room:obtainCard(player, card, false)
                                else
                                    p:turnOver()
                                end
                            elseif string.find(mark, "equip") then
                                local card = room:askForCard(p, ".|.|.|equip",
                                    "@jie_dao_invoke_equip:" .. player:objectName(), data, sgs.Card_MethodNone)
                                if card then
                                    room:obtainCard(player, card, false)
                                else
                                    p:turnOver()
                                end
                            end
                            room:setPlayerMark(player, mark, 0)
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
HonoTamura_Sakurazaka:addSkill(sakamichi_jie_dao)

sakamichi_qin_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_qin_yan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and not player:faceUp() then
            local ids = sgs.IntList()
            if use.card:isVirtualCard() then
                ids = use.card:getSubcards()
            else
                ids:append(use.card:getEffectiveId())
            end
            if not ids:isEmpty() then
                local all_place_discard = true
                for _, id in sgs.qlist(ids) do
                    if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                        all_place_discard = false
                        break
                    end
                end
                if all_place_discard then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                            "@qin_yan_invoke:::" .. use.card:objectName(), true)
                        if target then
                            room:obtainCard(target, use.card)
                            room:drawCards(player, 1, self:objectName())
                        end
                    end
                end
            end
        end
        return false
    end,
}
HonoTamura_Sakurazaka:addSkill(sakamichi_qin_yan)

sakamichi_tian_zhen = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_tian_zhen",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local nullification = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
        nullification:addSubcard(card)
        nullification:setSkillName(self:objectName())
        return nullification
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "nullification" and player:getPhase() == sgs.Player_NotActive
    end,
    enabled_at_nullification = function(self, player)
        return player:getPhase() == sgs.Player_NotActive
    end,
}
HonoTamura_Sakurazaka:addSkill(sakamichi_tian_zhen)

sgs.LoadTranslationTable {
    ["HonoTamura_Sakurazaka"] = "田村 保乃",
    ["&HonoTamura_Sakurazaka"] = "田村 保乃",
    ["#HonoTamura_Sakurazaka"] = "维尼",
    ["~HonoTamura_Sakurazaka"] = "そうですね•••",
    ["designer:HonoTamura_Sakurazaka"] = "Cassimolar",
    ["cv:HonoTamura_Sakurazaka"] = "田村 保乃",
    ["illustrator:HonoTamura_Sakurazaka"] = "Cassimolar",
    ["sakamichi_liu_dan"] = "流弹",
    [":sakamichi_liu_dan"] = "主公技，锁定技，你/与你势力不同的角色使用【杀】指定与你势力不同的角色/你的上家或下家时，若其上家或下家与你势力不同/其与你势力相同，且不为此【杀】的目标，则将其上家或下家/你添加为此【杀】的目标。",
    ["sakamichi_jie_dao"] = "借盗",
    [":sakamichi_jie_dao"] = "出牌阶段限一次，你可以获得一名其他角色的一张牌，其准备阶段，你须交给其一张相同区域的牌或翻面。",
    ["@jie_dao_invoke_hand"] = "你须交给%src一张手牌否则翻面",
    ["@jie_dao_invoke_equip"] = "你须交给%src一张装备区的牌否则翻面",
    ["sakamichi_qin_yan"] = "寝言",
    [":sakamichi_qin_yan"] = "当你使用的牌结算完成时，若你背面向上，你可以令一名其他角色获得之，然后你摸一张牌。",
    ["@qin_yan_invoke"] = "你可以令一名其他角色获得此【%arg】",
    ["sakamichi_tian_zhen"] = "天真",
    [":sakamichi_tian_zhen"] = "你的回合外，你可以将一张手牌当【无懈可击】使用。",
}
