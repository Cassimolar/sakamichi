require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HijiriKai = sgs.General(Zambi, "HijiriKai", "Zambi", 3, false)
table.insert(SKMC.SanKiSei, "HijiriKai")

--[[
    技能名：黑客
    描述：出牌阶段限一次，你可以展示牌堆顶的五张牌，你可以选择其中任意张花色不同的牌，然后选择一名其他角色令其选择获得其余的牌并受到等同于其获得牌花色数的伤害或令你获得你选择的牌。
]]
LuahakkaaCard = sgs.CreateSkillCard {
    name = "LuahakkaaCard",
    skill_name = "Luahakkaa",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local ids = room:getNCards(5)
        room:fillAG(ids)
        local list1, list2 = sgs.IntList(), sgs.IntList()
        while (not ids:isEmpty()) do
            local id = room:askForAG(effect.from, ids, true, self:objectName())
            if id ~= -1 then
                ids:removeOne(id)
                list1:append(id)
                room:takeAG(effect.from, id, false)
                for _, id1 in sgs.qlist(ids) do
                    if sgs.Sanguosha:getCard(id1):getSuit() == sgs.Sanguosha:getCard(id):getSuit() then
                        room:takeAG(nil, id1, false)
                        ids:removeOne(id1)
                        list2:append(id1)
                    end
                end
                for _, id1 in sgs.qlist(ids) do
                    if sgs.Sanguosha:getCard(id1):getSuit() == sgs.Sanguosha:getCard(id):getSuit() then
                        room:takeAG(nil, id1, false)
                        ids:removeOne(id1)
                        list2:append(id1)
                    end
                end
            else
                for _, id1 in sgs.qlist(ids) do
                    room:takeAG(nil, id1, false)
                    ids:removeOne(id1)
                    list2:append(id1)
                end
                break
            end
        end
        if room:askForChoice(effect.to, "Luahakkaa", "getlist1+getlist2") == "getlist1" then
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            if list1:length() ~= 0 then
                for _, card_id in sgs.qlist(list1) do
                    dummy:addSubcard(card_id)
                end
                effect.from:obtainCard(dummy)
            end
            dummy:clearSubcards()
            if list2:length() ~= 0 then
                for _, card_id in sgs.qlist(list2) do
                    dummy:addSubcard(card_id)
                end
                room:throwCard(dummy,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "Luahakkaa", ""), nil)
            end
            dummy:deleteLater()
        else
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            local suit = {}
            if list2:length() ~= 0 then
                for _, card_id in sgs.qlist(list2) do
                    if not table.contains(suit, sgs.Sanguosha:getCard(card_id):getSuit()) then
                        table.insert(suit, sgs.Sanguosha:getCard(card_id):getSuit())
                    end
                    dummy:addSubcard(card_id)
                end
                effect.to:obtainCard(dummy)
                room:damage(sgs.DamageStruct("Luahakkaa", effect.from, effect.to, #suit))
            end
            dummy:clearSubcards()
            if list1:length() ~= 0 then
                for _, card_id in sgs.qlist(list1) do
                    dummy:addSubcard(card_id)
                end
                room:throwCard(dummy,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, "Luahakkaa", ""), nil)
            end
            dummy:deleteLater()
        end
        room:clearAG()
        room:broadcastInvoke("clearAG")
    end,
}
Luahakkaa = sgs.CreateZeroCardViewAsSkill {
    name = "Luahakkaa",
    view_as = function(self, cards)
        return LuahakkaaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuahakkaaCard")
    end,
}
HijiriKai:addSkill(Luahakkaa)

--[[
    技能名：灵感
    描述：当你于回合外使用或打出基本牌时，你可以进行一次判定，若结果为红色，你可以观看牌堆顶的两张牌，然后将其中一张牌交给一名其他角色将另一张置入弃牌堆。
]]
Luareikan = sgs.CreateTriggerSkill {
    name = "Luareikan",
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and card:isKindOf("BasicCard") and player:getPhase() == sgs.Player_NotActive
            and room:askForSkillInvoke(player, self:objectName(), data) then
            local judge = sgs.JudgeStruct()
            judge.pattern = ".|red"
            judge.good = true
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            if judge:isGood() then
                local source = sgs.SPlayerList()
                source:append(player)
                local cards = room:getNCards(2, false)
                local move = sgs.CardsMoveStruct(cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
                local moves = sgs.CardsMoveList()
                moves:append(move)
                room:notifyMoveCards(true, moves, false, source)
                room:notifyMoveCards(false, moves, false, source)
                local ids = sgs.IntList()
                for _, id in sgs.qlist(cards) do
                    ids:append(id)
                end
                room:askForYiji(player, cards, self:objectName(), true, true, false, 1, room:getOtherPlayers(player),
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), self:objectName(), nil),
                    "@reikan_invoke")
                local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand,
                    sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(),
                        self:objectName(), nil))
                for _, id in sgs.qlist(ids) do
                    if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                        move.card_ids:append(id)
                        cards:removeOne(id)
                    end
                end
                ids = sgs.IntList()
                for _, id in sgs.qlist(cards) do
                    ids:append(id)
                end
                local moves = sgs.CardsMoveList()
                moves:append(move)
                room:notifyMoveCards(true, moves, false, source)
                room:notifyMoveCards(false, moves, false, source)
                if not player:isAlive() then
                    return
                end
                if not cards:isEmpty() then
                    local move = sgs.CardsMoveStruct(cards, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(),
                            nil))
                    local moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, source)
                    room:notifyMoveCards(false, moves, false, source)
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    for _, id in sgs.qlist(cards) do
                        dummy:addSubcard(id)
                    end
                    room:throwCard(dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil,
                        self:objectName(), ""), nil)
                end
            end
        end
        return false
    end,
}
HijiriKai:addSkill(Luareikan)

--[[
    技能名：恐高
    描述：锁定技，当其他角色使用【杀】指定你为目标时，若其不在你的攻击范围内，则你需要打出需要两张【闪】才能抵消此【杀】。
]]
Luakoushokyoufushou = sgs.CreateTriggerSkill {
    name = "Luakoushokyoufushou",
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") and player:objectName() == use.from:objectName() then
            local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
            local index = 1
            for _, p in sgs.qlist(use.to) do
                if p:hasSkill(self) and not p:inMyAttackRange(player) then
                    if jink_table[index] == 1 then
                        jink_table[index] = 2
                    end
                end
                index = index + 1
            end
            local jink_data = sgs.QVariant()
            jink_data:setValue(SKMC.table_to_IntList(jink_table))
            player:setTag("Jink_" .. use.card:toString(), jink_data)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HijiriKai:addSkill(Luakoushokyoufushou)

--[[
    技能名：献身
    描述：你死亡时可以令一名其他角色获得一枚“护”，当拥有“护”的角色受到火焰伤害时，其可以弃一枚“护”来防止此次伤害。
]]
Luagisei = sgs.CreateTriggerSkill {
    name = "Luagisei",
    events = {sgs.Death, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:hasSkill(self) then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@gisei-target")
                if target then
                    target:gainMark("@hu")
                end
            end
            return false
        else
            local damage = data:toDamage()
            if damage.to:objectName() == player:objectName() and player:getMark("@hu") ~= 0 and damage.nature
                == sgs.DamageStruct_Fire
                and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("gisei_invoke")) then
                player:loseMark("@hu")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HijiriKai:addSkill(Luagisei)

sgs.LoadTranslationTable {
    ["HijiriKai"] = "甲斐 聖",
    ["&HijiriKai"] = "甲斐 聖",
    ["#HijiriKai"] = "鉾鈴と彼女と",
    ["designer:HijiriKai"] = "Cassimolar",
    ["cv:HijiriKai"] = "与田 祐希",
    ["illustrator:HijiriKai"] = "Cassimolar",
    ["Luahakkaa"] = "黑客",
    [":Luahakkaa"] = "出牌阶段限一次，你可以展示牌堆顶的五张牌，你可以选择其中任意张花色不同的牌，然后选择一名其他角色令其选择获得其余的牌并受到等同于其获得牌花色数的伤害或令你获得你选择的牌。",
    ["getlist1"] = "令其获得其选择的牌",
    ["getlist2"] = "你获得其未选择牌并受到等同花色数的伤害",
    ["Luareikan"] = "灵感",
    [":Luareikan"] = "当你于回合外使用或打出基本牌时，你可以进行一次判定，若结果为红色，你可以观看牌堆顶的两张牌，然后将其中一张牌交给一名其他角色将另一张置入弃牌堆。",
    ["@reikan_invoke"] = "你可以将其中的一张牌交给一名其他角色",
    ["Luakoushokyoufushou"] = "恐高",
    [":Luakoushokyoufushou"] = "锁定技，当其他角色使用【杀】指定你为目标时，若其不在你的攻击范围内，则你需要打出需要两张【闪】才能抵消此【杀】。",
    ["Luagisei"] = "献身",
    [":Luagisei"] = "你死亡时可以令一名其他角色获得一枚“护”，当拥有“护”的角色受到火焰伤害时，其可以弃一枚“护”来防止此次伤害。",
    ["@gisei-target"] = "你可以选择一名其他角色令其获得一枚“护”",
    ["@hu"] = "护",
    ["Luagisei:gisei_invoke"] = "你可以弃一枚“护”来防止此次火焰伤害",
}
