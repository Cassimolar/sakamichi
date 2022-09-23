require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkariFukuda = sgs.General(STU48, "AkariFukuda", "STU48", 3, false)
table.insert(SKMC.IKiSei, "AkariFukuda")

--[[
    技能名：大副
    描述：你可以将X张牌视为此回合未以此法使用过的基本牌或通常锦囊牌使用。（X为此技能此回合已发动次数+1）
]]
local patterns = {"slash", "jink", "peach", "analeptic", "god_salvation", "amazing_grace", "savage_assault",
    "archery_attack", "collateral", "ex_nihilo", "duel", "nullification", "snatch", "dismantlement", "fire_attack",
    "iron_chain"}
local pos = 0
LuaChiefOfficer_select = sgs.CreateSkillCard {
    name = "LuaChiefOfficer_select",
    skill_name = "LuaChiefOfficer",
    will_throw = false,
    target_fixed = true,
    handling_method = sgs.Card_MethodNone,
    on_use = function(self, room, source, targets)
        local choices = {}
        for _, name in ipairs(patterns) do
            local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            poi:setSkillName("LuaChiefOfficer")
            for _, cd in sgs.qlist(self:getSubcards()) do
                poi:addSubcard(cd)
            end
            if poi:isAvailable(source) and source:getMark("ChiefOfficer" .. name) == 0
                and not table.contains(sgs.Sanguosha:getBanPackages(), poi:getPackage()) then
                table.insert(choices, name)
            end
        end
        if next(choices) then
            table.insert(choices, "cancel")
            local pattern = room:askForChoice(source, "LuaChiefOfficer", table.concat(choices, "+"))
            if pattern and pattern ~= "cancel" then
                local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                if poi:targetFixed() then
                    poi:setSkillName("LuaChiefOfficer")
                    for _, cd in sgs.qlist(self:getSubcards()) do
                        poi:addSubcard(cd)
                    end
                    room:useCard(sgs.CardUseStruct(poi, source, source), true)
                else
                    pos = SKMC.get_pos(patterns, pattern)
                    room:setPlayerMark(source, "ChiefOfficerPos", pos)
                    local x = 1
                    for _, cd in sgs.qlist(self:getSubcards()) do
                        room:setPlayerProperty(source, "ChiefOfficer" .. x, sgs.QVariant(cd))
                        x = x + 1
                    end
                    room:setPlayerMark(source, "CO-Card", x)
                    room:askForUseCard(source, "@@LuaChiefOfficer", "@ChiefOfficer:::" .. pattern)
                end
            end
        end
    end,
}
LuaChiefOfficerCard = sgs.CreateSkillCard {
    name = "LucChiefOfficerCard",
    skill_name = "LuaChiefOfficer",
    will_throw = false,
    filter = function(self, targets, to_select)
        local name = ""
        local card
        local plist = sgs.PlayerList()
        for i = 1, #targets do
            plist:append(targets[i])
        end
        local aocaistring = self:getUserString()
        if aocaistring ~= "" then
            local uses = aocaistring:split("+")
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            for _, cd in sgs.qlist(self:getSubcards()) do
                card:addSubcard(cd)
            end
            if card and card:targetFixed() then
                return false
            else
                return card and card:targetFilter(plist, to_select, sgs.Self)
                           and not sgs.Self:isProhibited(to_select, card, plist)
            end
        end
        return true
    end,
    target_fixed = function(self)
        local name = ""
        local card
        local aocaistring = self:getUserString()
        if aocaistring ~= "" then
            local uses = aocaistring:split("+")
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        for _, cd in sgs.qlist(self:getSubcards()) do
            card:addSubcard(cd)
        end
        return card and card:targetFixed()
    end,
    feasible = function(self, targets)
        local name = ""
        local card
        local plist = sgs.PlayerList()
        for i = 1, #targets do
            plist:append(targets[i])
        end
        local aocaistring = self:getUserString()
        if aocaistring ~= "" then
            local uses = aocaistring:split("+")
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        for _, cd in sgs.qlist(self:getSubcards()) do
            card:addSubcard(cd)
        end
        return card and card:targetsFeasible(plist, sgs.Self)
    end,
    on_validate_in_response = function(self, user)
        local room = user:getRoom()
        local aocaistring = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
        if string.find(aocaistring, "+") then
            local uses = {}
            for _, name in pairs(aocaistring:split("+")) do
                if user:getMark("ChiefOfficer" .. name) == 0 then
                    table.insert(uses, name)
                end
            end
            local name = room:askForChoice(user, "LuaChiefOfficer", table.concat(uses, "+"))
            use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        for _, cd in sgs.qlist(self:getSubcards()) do
            use_card:addSubcard(cd)
        end
        use_card:setSkillName("LuaChiefOfficer")
        return use_card
    end,
    on_validate = function(self, card_use)
        local room = card_use.from:getRoom()
        local aocaistring = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
        if string.find(aocaistring, "+") then
            local uses = {}
            for _, name in pairs(aocaistring:split("+")) do
                if card_use.from:getMark("ChiefOfficer" .. name) == 0 then
                    table.insert(uses, name)
                end
            end
            local name = room:askForChoice(card_use.from, "LuaChiefOfficer", table.concat(uses, "+"))
            use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
        end
        if use_card == nil then
            return false
        end
        use_card:setSkillName("LuaChiefOfficer")
        local available = true
        for _, p in sgs.qlist(card_use.to) do
            if card_use.from:isProhibited(p, use_card) then
                available = false
                break
            end
        end
        if not available then
            return nil
        end
        for _, cd in sgs.qlist(self:getSubcards()) do
            use_card:addSubcard(cd)
        end
        return use_card
    end,
}
LuaChiefOfficerVS = sgs.CreateViewAsSkill {
    name = "LuaChiefOfficer",
    n = 999,
    response_or_use = true,
    view_filter = function(self, selected, to_select)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern and pattern == "@@LuaChiefOfficer" then
            return false
        else
            return #selected <= sgs.Self:getMark("CO-Used") + 1
        end
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            if #cards == sgs.Self:getMark("CO-Used") + 1 then
                local acard = LuaChiefOfficer_select:clone()
                for _, card in pairs(cards) do
                    acard:addSubcard(card)
                end
                return acard
            end
        else
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if string.find(pattern, "slash") or string.find(pattern, "Slash") then
                pattern = "slash+thunder_slash+fire_slash"
            end
            local acard = LuaChiefOfficerCard:clone()
            if pattern and pattern == "@@LuaChiefOfficer" then
                pattern = patterns[sgs.Self:getMark("ChiefOfficerPos")]
                for i = 1, sgs.Self:getMark("CO-Card") do
                    acard:addSubcard(sgs.Self:property("ChiefOfficer" .. i):toInt())
                end
                if #cards ~= 0 then
                    return
                end
            else
                if #cards ~= sgs.Self:getMark("CO-Used") + 1 then
                    return
                end
                for _, card in pairs(cards) do
                    acard:addSubcard(card)
                end
            end
            if pattern == "peach+analeptic" and sgs.Self:getMark("Global_PreventPeach") ~= 0 then
                pattern = "analeptic"
            end
            acard:setUserString(pattern)
            return acard
        end
    end,
    enabled_at_play = function(self, player)
        local choices = {}
        for _, name in ipairs(patterns) do
            local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
            if poi:isAvailable(player) and player:getMark("ChiefOfficer" .. name) == 0 then
                table.insert(choices, name)
            end
        end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasFlag("Global_Dying") or player:hasFlag("Global_Dying") then
                return false
            end
        end
        return next(choices)
    end,
    enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            return false
        end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasFlag("Global_Dying") or player:hasFlag("Global_Dying") then
                return false
            end
        end
        for _, p in pairs(pattern:split("+")) do
            if player:getMark(self:objectName() .. p) == 0 then
                return true
            end
        end
    end,
    enabled_at_nullification = function(self, player, pattern)
        return player:getMark("ChiefOfficernullification") == 0
    end,
}
LuaChiefOfficer = sgs.CreateTriggerSkill {
    name = "LuaChiefOfficer",
    view_as_skill = LuaChiefOfficerVS,
    events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed or event == sgs.CardResponded and player:hasSkill(self) then
            local card
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if card and card:getHandlingMethod() == sgs.Card_MethodUse then
                if card:getSkillName() == "LuaChiefOfficer" and player:getMark("ChiefOfficer" .. card:objectName()) == 0 then
                    room:addPlayerMark(player, "ChiefOfficer" .. card:objectName())
                    room:addPlayerMark(player, "CO-Used")
                end
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasSkill(self) then
                        room:setPlayerMark(p, "CO-Used", 0)
                        room:setPlayerMark(p, "CO-Card", 0)
                        for _, name in ipairs(patterns) do
                            if p:getMark("ChiefOfficer" .. name) ~= 0 then
                                room:removePlayerMark(p, "ChiefOfficer" .. name)
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
AkariFukuda:addSkill(LuaChiefOfficer)

sgs.LoadTranslationTable {
    ["AkariFukuda"] = "福田 朱里",
    ["&AkariFukuda"] = "福田 朱里",
    ["#AkariFukuda"] = "全能大副",
    ["designer:AkariFukuda"] = "Cassimolar",
    ["cv:AkariFukuda"] = "福田 朱里",
    ["illustrator:AkariFukuda"] = "Cassimolar",
    ["LuaChiefOfficer"] = "大副",
    [":LuaChiefOfficer"] = "你可以将X张牌视为此回合未以此法使用过的基本牌或通常锦囊牌使用。（X为此技能此回合已发动次数+1）",
    ["@ChiefOfficer"] = "请为此【 %arg 】选择目标",
    ["~LuaChiefOfficer"] = "选择若干角色 → 点击确定",
}
