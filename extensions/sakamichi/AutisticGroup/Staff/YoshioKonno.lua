YoshioKonno = sgs.General(Sakamichi, "YoshioKonno", "AutisticGroup", 4, true)

--[[
    技能名：今野的野望
    描述：你可以说出一张基本牌或通常锦囊牌的名称，并背面朝上使用或打出一张手牌。若无其他角色质疑，则亮出此牌并按你所述之牌结算。若有其他角色质疑则亮出验明：若为真，质疑者各失去1点体力；若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真，此牌仍然进行结算，否则无论真假，将此牌置入弃牌堆。
]]
local patterns = {"slash", "jink", "peach", "analeptic", "nullification", "snatch", "dismantlement", "collateral",
    "ex_nihilo", "duel", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "god_salvation",
    "iron_chain"}
if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
    table.insert(patterns, 2, "thunder_slash")
    table.insert(patterns, 2, "fire_slash")
    table.insert(patterns, 2, "normal_slash")
end
local slash_patterns = {"slash", "normal_slash", "thunder_slash", "fire_slash"}
local pos = 0
yabo_select = sgs.CreateSkillCard {
    name = "yabo_select",
    skill_name = "Luakonnonoyabo",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    target_fixed = true,
    mute = true,
    on_use = function(self, room, source, targets)
        local type = {}
        local basic = {}
        local sttrick = {}
        local mttrick = {}
        for _, cd in ipairs(patterns) do
            local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, -1)
            if card then
                card:deleteLater()
                if card:isAvailable(source) then
                    if card:getTypeId() == sgs.Card_TypeBasic then
                        table.insert(basic, cd)
                    elseif card:isKindOf("SingleTargetTrick") then
                        table.insert(sttrick, cd)
                    else
                        table.insert(mttrick, cd)
                    end
                    if cd == "slash" then
                        table.insert(basic, "normal_slash")
                    end
                end
            end
        end
        if #basic ~= 0 then
            table.insert(type, "basic")
        end
        if #sttrick ~= 0 then
            table.insert(type, "single_target_trick")
        end
        if #mttrick ~= 0 then
            table.insert(type, "multiple_target_trick")
        end
        local typechoice = ""
        if #type > 0 then
            typechoice = room:askForChoice(source, "Luakonnonoyabo", table.concat(type, "+"))
        end
        local choices = {}
        if typechoice == "basic" then
            choices = table.copyFrom(basic)
        elseif typechoice == "single_target_trick" then
            choices = table.copyFrom(sttrick)
        elseif typechoice == "multiple_target_trick" then
            choices = table.copyFrom(mttrick)
        end
        local pattern = room:askForChoice(source, "yabo-new", table.concat(choices, "+"))
        if pattern then
            if string.sub(pattern, -5, -1) == "slash" then
                pos = SKMC.get_pos(slash_patterns, pattern)
                room:setPlayerMark(source, "YaboSlashPos", pos)
            end
            pos = SKMC.get_pos(patterns, pattern)
            room:setPlayerMark(source, "YaboPos", pos)
            room:askForUseCard(source, "@Luakonnonoyabo", "@@Luakonnonoyabo")
        end
    end,
}
function questionOrNot(player)
    local room = player:getRoom()
    local konno = room:findPlayerBySkillName("Luakonnonoyabo")
    local yaboname = room:getTag("YaboType"):toString()
    if yaboname == "peach+analeptic" then
        yaboname = "peach"
    end
    if yaboname == "normal_slash" then
        yaboname = "slash"
    end
    local yabocard = sgs.Sanguosha:cloneCard(yaboname, sgs.Card_NoSuit, -1)
    local yabotype = yabocard:getClassName()
    if yabotype and yabotype == "AmazingGrace" then
        return "noquestion"
    end
    if yabotype:match("Slash") then
        if konno:getState() ~= "robot" and math.random(1, 4) == 1 and not sgs.questioner then
            return "question"
        end
    end
    if math.random(1, 6) == 1 and player:getHp() >= 3 and player:getHp() > player:getLostHp() then
        return "question"
    end
    local players = room:getOtherPlayers(player)
    players = sgs.QList2Table(players)
    local x = math.random(1, 5)
    if sgs.questioner then
        return "noquestion"
    end
    local questioner = room:getOtherPlayers(player):at(0)
    return player:objectName() == questioner:objectName() and x ~= 1 and "question" or "noquestion"
end

function yabo(self, player)
    local room = player:getRoom()
    local players = room:getOtherPlayers(player)
    local used_cards = sgs.IntList()
    local moves = sgs.CardsMoveList()
    for _, card_id in sgs.qlist(self:getSubcards()) do
        used_cards:append(card_id)
    end
    local questioned = sgs.SPlayerList()
    for _, p in sgs.qlist(players) do
        if p:hasSkill("LuaChanyuan") then
            local log = sgs.LogMessage()
            log.type = "#LuaChanyuan"
            log.from = player
            log.to:append(p)
            log.arg = "LuaChanyuan"
            room:sendLog(log)
            room:notifySkillInvoked(p, "LuaChanyuan")
            room:setEmotion(p, "no-question")
        else
            local choice = "noquestion"
            if p:getState() == "online" then
                choice = room:askForChoice(p, "yabo", "noquestion+question")
            else
                room:getThread():delay(sgs.GetConfig("OriginAIDelay", ""))
                choice = questionOrNot(p)
            end
            if choice == "question" then
                sgs.questioner = p
                room:setEmotion(p, "question")
                questioned:append(p)
            else
                room:setEmotion(p, "no-question")
            end
            local log = sgs.LogMessage()
            log.type = "#YaboQuery"
            log.from = p
            log.arg = choice
            room:sendLog(log)
        end
    end
    room:removeTag("YaboType")
    local log = sgs.LogMessage()
    log.type = "#YaboResult"
    log.from = player
    local subcards = self:getSubcards()
    log.card_str = tostring(subcards:first())
    room:sendLog(log)
    local success = false
    local canuse = false
    if questioned:isEmpty() then
        canuse = true
        for _, p in sgs.qlist(players) do
            room:setEmotion(p, ".")
        end
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, player:objectName(), "", "yabo")
        local move = sgs.CardsMoveStruct()
        move.card_ids = used_cards
        move.from = player
        move.to = nil
        move.to_place = sgs.Player_PlaceTable
        move.reason = reason
        moves:append(move)
        room:moveCardsAtomic(moves, true)
    else
        local card = sgs.Sanguosha:getCard(subcards:first())
        local user_string = self:getUserString()
        if user_string == "peach+analeptic" then
            success = card:objectName() == player:getTag("YaboSaveSelf"):toString()
        elseif user_string == "slash" then
            success = string.sub(card:objectName(), -5, -1) == "slash"
        elseif user_string == "normal_slash" then
            success = card:objectName() == "slash"
        else
            success = card:match(user_string)
        end
        if success then
            for _, p in sgs.qlist(questioned) do
                room:loseHp(p)
            end
        else
            for _, p in sgs.qlist(questioned) do
                if p:isAlive() then
                    p:drawCards(1)
                end
            end
        end
        if success and card:getSuit() == sgs.Card_Heart then
            canuse = true
        end
        if canuse then
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, player:objectName(), "", "yabo")
            local move = sgs.CardsMoveStruct()
            move.card_ids = used_cards
            move.from = player
            move.to = nil
            move.to_place = sgs.Player_PlaceTable
            move.reason = reason
            moves:append(move)
            room:moveCardsAtomic(moves, true)
        else
            room:moveCardTo(self, player, nil, sgs.Player_DiscardPile,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "", "yabo"), true)
        end
        for _, p in sgs.qlist(players) do
            room:setEmotion(p, ".")
        end
    end
    player:removeTag("YaboSaveSelf")
    return canuse
end

LuakonnonoyaboCard = sgs.CreateSkillCard {
    name = "Luakonnonoyabo",
    skill_name = "Luakonnonoyabo",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    player = nil,
    on_use = function(self, room, source)
        from = source
    end,
    filter = function(self, targets, to_select, player)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
            and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@Luakonnonoyabo" then
            local card = nil
            if self:getUserString() ~= "" then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
                card:setSkillName("yabo")
            end
            if card and card:targetFixed() then
                return false
            end
            local qtargets = sgs.PlayerList()
            for _, p in ipairs(targets) do
                qtargets:append(p)
            end
            return card and card:targetFilter(qtargets, to_select, sgs.Self)
                       and not sgs.Self:isProhibited(to_select, card, qtargets)
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return false
        end
        local pattern = patterns[player:getMark("YaboPos")]
        if pattern == "normal_slash" then
            pattern = "slash"
        end
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("Luakonnonoyabo")
        if card and card:targetFixed() then
            return false
        end
        local qtargets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        return card and card:targetFilter(qtargets, to_select, sgs.Self)
                   and not sgs.Self:isProhibited(to_select, card, qtargets)
    end,
    target_fixed = function(self)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
            and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@Luakonnonoyabo" then
            local card = nil
            if self:getUserString() ~= "" then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
            end
            return card and card:targetFixed()
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local pattern = patterns[from:getMark("YaboPos")]
        if pattern == "normal_slash" then
            pattern = "slash"
        end
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        return card and card:targetFixed()
    end,
    feasible = function(self, targets)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
            and sgs.Sanguosha:getCurrentCardUsePattern() ~= "@Luakonnonoyabo" then
            local card = nil
            if self:getUserString() ~= "" then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
                card:setSkillName("Luakonnonoyabo")
            end
            local qtargets = sgs.PlayerList()
            for _, p in ipairs(targets) do
                qtargets:append(p)
            end
            return card and card:targetsFeasible(qtargets, sgs.Self)
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local pattern = patterns[sgs.Self:getMark("YaboPos")]
        if pattern == "normal_slash" then
            pattern = "slash"
        end
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:setSkillName("Luakonnonoyabo")
        local qtargets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        return card and card:targetsFeasible(qtargets, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local player = card_use.from
        local room = player:getRoom()
        local to_yabo = self:getUserString()
        if to_yabo == "slash" and sgs.Sanguosha:getCurrentCardUseReason()
            == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and sgs.Sanguosha:getCurrentCardUsePattern()
            ~= "@Luakonnonoyabo" then
            local yabo_list = {}
            table.insert(yabo_list, "slash")
            if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                table.insert(yabo_list, "normal_slash")
                table.insert(yabo_list, "thunder_slash")
                table.insert(yabo_list, "fire_slash")
            end
            to_yabo = room:askForChoice(player, "yabo_slash", table.concat(yabo_list, "+"))
            pos = SKMC.get_pos(slash_patterns, to_yabo)
            room:setPlayerMark(player, "YaboSlashPos", pos)
        end
        local log = sgs.LogMessage()
        if card_use.to:isEmpty() then
            log.type = "#YaboNoTarget"
        else
            log.type = "#Yabo"
        end
        log.from = player
        log.to = card_use.to
        log.arg = to_yabo
        log.arg2 = "Luakonnonoyabo"
        room:sendLog(log)
        room:setTag("YaboType", sgs.QVariant(self:getUserString()))
        if yabo(self, player) then
            local subcards = self:getSubcards()
            local card = sgs.Sanguosha:getCard(subcards:first())
            local user_str
            if to_yabo == "slash" then
                if card:isKindOf("Slash") then
                    user_str = card:objectName()
                else
                    user_str = "slash"
                end
            elseif to_yabo == "normal_slash" then
                user_str = "slash"
            else
                user_str = to_yabo
            end
            local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
            use_card:setSkillName("Luakonnonoyabo")
            use_card:addSubcard(card)
            use_card:deleteLater()
            return use_card
        else
            return nil
        end
    end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()
        local to_yabo
        if self:getUserString() == "peach+analeptic" then
            local yabo_list = {}
            table.insert(yabo_list, "peach")
            if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                table.insert(yabo_list, "analeptic")
            end
            to_yabo = room:askForChoice(player, "yabo_saveself", table.concat(yabo_list, "+"))
            player:setTag("YaboSaveSelf", sgs.QVariant(to_yabo))
        elseif self:getUserString() == "slash" then
            local yabo_list = {}
            table.insert(yabo_list, "slash")
            if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                table.insert(yabo_list, "normal_slash")
                table.insert(yabo_list, "thunder_slash")
                table.insert(yabo_list, "fire_slash")
            end
            to_yabo = room:askForChoice(player, "yabo_slash", table.concat(yabo_list, "+"))
            pos = SKMC.get_pos(slash_patterns, to_yabo)
            room:setPlayerMark(player, "YaboSlashPos", pos)
        else
            to_yabo = self:getUserString()
        end
        local log = sgs.LogMessage()
        log.type = "#YaboNoTarget"
        log.from = player
        log.arg = to_yabo
        log.arg2 = "Luakonnonoyabo"
        room:sendLog(log)
        room:setTag("YaboType", sgs.QVariant(self:getUserString()))
        if yabo(self, player) then
            local subcards = self:getSubcards()
            local card = sgs.Sanguosha:getCard(subcards:first())
            local user_str
            if to_yabo == "slash" then
                if card:isKindOf("Slash") then
                    user_str = card:objectName()
                else
                    user_str = "slash"
                end
            elseif to_yabo == "normal_slash" then
                user_str = "slash"
            else
                user_str = to_yabo
            end
            local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
            use_card:setSkillName("Luakonnonoyabo")
            use_card:addSubcard(subcards:first())
            use_card:deleteLater()
            return use_card
        else
            return nil
        end
    end,
}
Luakonnonoyabo = sgs.CreateViewAsSkill {
    name = "Luakonnonoyabo",
    n = 1,
    enabled_at_response = function(self, player, pattern)
        if pattern == "@Luakonnonoyabo" then
            return not player:isKongcheng()
        end
        if player:isKongcheng() or string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
            return false
        end
        if pattern == "peach" and player:getMark("Global_PreventPeach") ~= 0 then
            return false
        end
        return true
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
    end,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            if sgs.Sanguosha:getCurrentCardUsePattern() == "@Luakonnonoyabo" then
                local pattern = patterns[sgs.Self:getMark("YaboPos")]
                if pattern == "normal_slash" then
                    pattern = "slash"
                end
                local c = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
                if c and #cards == 1 then
                    c:deleteLater()
                    local card = LuakonnonoyaboCard:clone()
                    if not string.find(c:objectName(), "slash") then
                        card:setUserString(c:objectName())
                    else
                        card:setUserString(slash_patterns[sgs.Self:getMark("YaboSlashPos")])
                    end
                    card:addSubcard(cards[1])
                    return card
                else
                    return nil
                end
            elseif #cards == 1 then
                local card = LuakonnonoyaboCard:clone()
                card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
                card:addSubcard(cards[1])
                return card
            else
                return nil
            end
        elseif #cards == 0 then
            local cd = yabo_select:clone()
            return cd
        end
    end,
    enabled_at_nullification = function(self, player)
        return not player:isKongcheng()
    end,
}
YoshioKonno:addSkill(Luakonnonoyabo)

sgs.LoadTranslationTable {
    ["YoshioKonno"] = "今野 義雄",
    ["&YoshioKonno"] = "今野 義雄",
    ["#YoshioKonno"] = "今野無能",
    ["designer:YoshioKonno"] = "Cassimolar",
    ["cv:YoshioKonno"] = "今野 義雄",
    ["illustrator:YoshioKonno"] = "Cassimolar",
    ["Luakonnonoyabo"] = "今野的野望",
    [":Luakonnonoyabo"] = "你可以说出一张基本牌或通常锦囊牌的名称，并背面朝上使用或打出一张手牌。若无其他角色质疑，则亮出此牌并按你所述之牌结算。若有其他角色质疑则亮出验明：若为真，质疑者各失去1点体力；若为假，质疑者各摸一张牌。除非被质疑的牌为红桃且为真，此牌仍然进行结算，否则无论真假，将此牌置入弃牌堆。",
    ["yabo_select"] = "今野的野望",
    ["Yabo-new"] = "今野的野望",
    ["@@Luakonnonoyabo"] = "选择你要用于【今野的野望】的手牌",
    ["~Luakonnonoyabo"] = "选择一张手牌 → 点击确定",
    ["#Yabo"] = "%from 发动了【%arg2】，声明此牌为 【%arg】，指定的目标为 %to",
    ["#YaboNoTarget"] = "%from 发动了【%arg2】，声明此牌为 【%arg】",
    ["#YaboCannotQuestion"] = "%from 当前体力值为 %arg，无法质疑",
    ["#YaboQuery"] = "%from 表示 %arg",
    ["#YaboResult"] = "%from 的【<font color=\"yellow\"><b>今野的野望</b></font>】牌是 %card",
}
