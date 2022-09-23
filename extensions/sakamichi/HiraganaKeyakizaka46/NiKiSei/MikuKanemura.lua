require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MikuKanemura_HiraganaKeyakizaka = sgs.General(Sakamichi, "MikuKanemura_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.NiKiSei, "MikuKanemura_HiraganaKeyakizaka")

--[[
    技能名：寿司
    描述：你于出牌阶段外一次获得至少两张手牌，你可以展示之，若这些牌：颜色相同，你可以令一名角色于其下个回合使用的第一张基本牌不计入使用次数限制；颜色不同，你可以令一名角色于其下个回合开始时摸一张牌且本回合内手牌上限+1。
]]
Luashousi = sgs.CreateTriggerSkill {
    name = "Luashousi",
    events = {sgs.CardsMoveOneTime, sgs.CardUsed, sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:hasSkill(self) and player:getPhase() ~= sgs.Player_Play then
                if not room:getTag("FirstRound"):toBool() and move.card_ids:length() >= 2
                    and (move.to and move.to:objectName() == player:objectName() and move.to_place
                        == sgs.Player_PlaceHand) and room:askForSkillInvoke(player, self:objectName(), data) then
                    local same = true
                    local first = sgs.Sanguosha:getCard(move.card_ids:first()):isRed()
                    for _, id in sgs.qlist(move.card_ids) do
                        room:showCard(player, id)
                        if first ~= sgs.Sanguosha:getCard(id):isRed() then
                            same = false
                        end
                    end
                    if same then
                        local p = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                            "@shousi_same")
                        room:addPlayerMark(p, "&sushi_same", 1)
                    else
                        player = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                            "@shousi_different")
                        room:addPlayerMark(player, "&sushi_different", 1)
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getMark("sushi_same") ~= 0 and player:getPhase() ~= sgs.Player_NotActive
                and use.card:isKindOf("BasicCard") then
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                    room:removePlayerMark(player, "sushi_same", 1)
                end
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start
            and player:getMark("sushi_different") ~= 0 then
            while player:getMark("sushi_different") ~= 0 do
                --				local toGainList = sgs.IntList()
                --				for _, id in sgs.qlist(room:getDiscardPile()) do
                --					if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                --						toGainList:append(id)
                --					end
                --				end
                --				if toGainList:length() ~= 0 then
                --					room:fillAG(toGainList, player)
                --					local card_id = room:askForAG(player, toGainList, false, self:objectName())
                --					if card_id ~= -1 then
                --						room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceHand, true)
                --						room:ignoreCards(player, card_id)
                --						room:removePlayerMark(player, "sushi_different", 1)
                --					end
                --					room:clearAG(player)
                --				else
                --					room:setPlayerMark(player, "sushi_different", 0)
                --					break
                --				end
                room:drawCards(player, 1, self:objectName())
                room:addMaxCards(player, 1, true)
                room:removePlayerMark(player, "sushi_different", 1)
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            if player:getMark("sushi_same") ~= 0 then
                room:setPlayerMark(player, "sushi_same", 0)
            end
            if player:getMark("sushi_different") ~= 0 then
                room:setPlayerMark(player, "sushi_different", 0)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if (player:getMark("&sushi_same") ~= 0 or player:getMark("&sushi_different") ~= 0) and change.to
                == sgs.Player_Start then
                if player:getMark("&sushi_same") ~= 0 then
                    room:setPlayerMark(player, "sushi_same", player:getMark("&sushi_same"))
                    room:setPlayerMark(player, "&sushi_same", 0)
                else
                    room:setPlayerMark(player, "sushi_different", player:getMark("&sushi_different"))
                    room:setPlayerMark(player, "&sushi_different", 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MikuKanemura_HiraganaKeyakizaka:addSkill(Luashousi)

--[[
    技能名：赠蛙
    描述：限定技，出牌阶段，你可以将任意张花色不同的牌交给任意名其他角色，你于此回合结束后可以进行一个额外的回合，若你以此法交给其他角色多于两张牌，你可以从弃牌堆选择获得类型不同的两张牌。
]]
LuazengwaCard = sgs.CreateSkillCard {
    name = "LuazengwaCard",
    skill_name = "Luazengwa",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, selected, to_select)
        return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:getMark("@zengwa") ~= 0 then
            effect.from:loseMark("@zengwa")
        end
        for _, id in sgs.qlist(self:getSubcards()) do
            room:setPlayerFlag(effect.from, "zengwa" .. sgs.Sanguosha:getCard(id):getSuitString())
        end
        room:obtainCard(effect.to, self, true)
        local n = 0
        if effect.from:hasFlag("zengwaspade") then
            n = n + 1
        end
        if effect.from:hasFlag("zengwaclub") then
            n = n + 1
        end
        if effect.from:hasFlag("zengwaheart") then
            n = n + 1
        end
        if effect.from:hasFlag("zengwadiamond") then
            n = n + 1
        end
        if n ~= 4 then
            if not room:askForUseCard(effect.from, "@@Luazengwa", "@zengwa_invoke", -1, sgs.Card_MethodNone, false) then
                if n >= 3 then
                    local ids = room:getDiscardPile()
                    room:fillAG(ids)
                    local list = sgs.IntList()
                    for i = 1, 2, 1 do
                        local id = room:askForAG(effect.from, ids, true, self:objectName())
                        if id ~= -1 then
                            ids:removeOne(id)
                            list:append(id)
                            room:takeAG(effect.from, id, false)
                            local goon = true
                            while goon do
                                if not ids:isEmpty() then
                                    for _, id1 in sgs.qlist(ids) do
                                        if sgs.Sanguosha:getCard(id1):getTypeId()
                                            == sgs.Sanguosha:getCard(id):getTypeId() then
                                            room:takeAG(nil, id1, false)
                                            ids:removeOne(id1)
                                            goon = false
                                        end
                                    end
                                    for _, id2 in sgs.qlist(ids) do
                                        if sgs.Sanguosha:getCard(id2):getTypeId()
                                            == sgs.Sanguosha:getCard(id):getTypeId() then
                                            goon = true
                                        end
                                    end
                                else
                                    goon = false
                                end
                            end
                        else
                            break
                        end
                    end
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    if list:length() ~= 0 then
                        for _, card_id in sgs.qlist(list) do
                            dummy:addSubcard(card_id)
                        end
                        effect.from:obtainCard(dummy)
                    end
                    dummy:clearSubcards()
                    room:clearAG()
                    room:broadcastInvoke("clearAG")
                end
            end
        else
            local ids = room:getDiscardPile()
            room:fillAG(ids)
            local list = sgs.IntList()
            for i = 1, 2, 1 do
                local id = room:askForAG(effect.from, ids, true, self:objectName())
                if id ~= -1 then
                    ids:removeOne(id)
                    list:append(id)
                    room:takeAG(effect.from, id, false)
                    local goon = true
                    while goon do
                        if not ids:isEmpty() then
                            for _, id1 in sgs.qlist(ids) do
                                if sgs.Sanguosha:getCard(id1):getTypeId() == sgs.Sanguosha:getCard(id):getTypeId() then
                                    room:takeAG(nil, id1, false)
                                    ids:removeOne(id1)
                                    goon = false
                                end
                            end
                            for _, id2 in sgs.qlist(ids) do
                                if sgs.Sanguosha:getCard(id2):getTypeId() == sgs.Sanguosha:getCard(id):getTypeId() then
                                    goon = true
                                end
                            end
                        else
                            goon = false
                        end
                    end
                else
                    break
                end
            end
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            if list:length() ~= 0 then
                for _, card_id in sgs.qlist(list) do
                    dummy:addSubcard(card_id)
                end
                effect.from:obtainCard(dummy)
            end
            dummy:clearSubcards()
            room:clearAG()
            room:broadcastInvoke("clearAG")
        end
        room:setPlayerFlag(effect.from, "zengwa")
    end,
}
LuazengwaVS = sgs.CreateViewAsSkill {
    name = "Luazengwa",
    n = 999,
    view_filter = function(self, selected, to_select)
        if sgs.Self:hasFlag("zengwa" .. to_select:getSuitString()) then
            return false
        end
        for _, card in ipairs(selected) do
            if card:getSuit() == to_select:getSuit() then
                return false
            end
        end
        return true
    end,
    view_as = function(self, cards)
        local cd = LuazengwaCard:clone()
        for _, card in ipairs(cards) do
            cd:addSubcard(card)
        end
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@zengwa") >= 1
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@Luazengwa")
    end,
}
Luazengwa = sgs.CreateTriggerSkill {
    name = "Luazengwa",
    frequency = sgs.Skill_Limited,
    limit_mark = "@zengwa",
    view_as_skill = LuazengwaVS,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive and player:hasFlag("zengwa") then
            room:setPlayerFlag(player, "-zengwa")
            SKMC.send_message(room, "#Fangquan", nil, player)
            player:gainAnExtraTurn()
        end
        return false
    end,
}
MikuKanemura_HiraganaKeyakizaka:addSkill(Luazengwa)

sgs.LoadTranslationTable {
    ["MikuKanemura_HiraganaKeyakizaka"] = "金村 美玖",
    ["&MikuKanemura_HiraganaKeyakizaka"] = "金村 美玖",
    ["#MikuKanemura_HiraganaKeyakizaka"] = "小壽司",
    ["designer:MikuKanemura_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MikuKanemura_HiraganaKeyakizaka"] = "金村 美玖",
    ["illustrator:MikuKanemura_HiraganaKeyakizaka"] = "PeriPeace",
    ["Luashousi"] = "寿司",
    [":Luashousi"] = "你于出牌阶段外一次获得至少两张手牌，你可以展示之，若这些牌：颜色相同，你可以令一名角色于其下个回合使用的第一张基本牌不计入使用次数限制；颜色不同，你可以令一名角色于其下个回合开始时摸一张牌且本回合内手牌上限+1。",
    ["@shousi_same"] = "你可以选择一名角色令其下回合使用的第一张牌不计入次数限制",
    ["sushi_same"] = "寿司-同",
    ["@shousi_different"] = "你可以选择一名角色令其下个回合开始摸一张牌且当回会手牌上限+1",
    ["sushi_different"] = "寿司-异",
    ["Luazengwa"] = "赠蛙",
    [":Luazengwa"] = "限定技，出牌阶段，你可以将任意张花色不同的牌交给任意名其他角色，你于此回合结束后可以进行一个额外的回合，若你以此法交给其他角色多于两张牌，你可以从弃牌堆选择获得类型不同的两张牌。",
    ["@zengwa"] = "赠蛙",
    ["@zengwa_invoke"] = "你可以将任意张花色不同的牌交给任意名其他角色",
}
