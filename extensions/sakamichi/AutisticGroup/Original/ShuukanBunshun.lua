require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ShuukanBunshun = sgs.General(Sakamichi, "ShuukanBunshun", "AutisticGroup", 3, true, true)

--[[
    技能名：采料
    描述：其他角色的弃牌阶段结束时，你可以获得角色于此阶段内弃置的基本牌并置于你的武将牌旁称为“料”，“料”可以视为手牌使用或打出。
]]
function strcontain(a, b)
    if a == "" then
        return false
    end
    local c = a:split("+")
    local k = false
    for i = 1, #c, 1 do
        if a[i] == b then
            k = true
            break
        end
    end
    return k
end

Luacailiao = sgs.CreateTriggerSkill {
    name = "Luacailiao",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local ShuukanBunshun = room:findPlayerBySkillName(self:objectName())
            local current = room:getCurrent()
            local move = data:toMoveOneTime()
            local source = move.from
            if source then
                if player:objectName() == source:objectName() then
                    if ShuukanBunshun and ShuukanBunshun:objectName() ~= current:objectName() then
                        if current:getPhase() == sgs.Player_Discard then
                            local tag = room:getTag("cailiaoGet")
                            local cailiaoGet = tag:toString()
                            tag = room:getTag("cailiaoOther")
                            local cailiaoOther = tag:toString()
                            if cailiaoGet == nil then
                                cailiaoGet = ""
                            end
                            if cailiaoOther == nil then
                                cailiaoOther = ""
                            end
                            for _, card_id in sgs.qlist(move.card_ids) do
                                if sgs.Sanguosha:getCard(card_id):isKindOf("BasicCard") then
                                    local flag =
                                        bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                                    if flag == sgs.CardMoveReason_S_REASON_DISCARD then
                                        if source:objectName() == current:objectName() then
                                            if cailiaoGet == "" then
                                                cailiaoGet = tostring(card_id)
                                            else
                                                cailiaoGet = cailiaoGet .. "+" .. tostring(card_id)
                                            end
                                        elseif not strcontain(cailiaoGet, tostring(card_id)) then
                                            if cailiaoOther == "" then
                                                cailiaoOther = tostring(card_id)
                                            else
                                                cailiaoOther = cailiaoOther .. "+" .. tostring(card_id)
                                            end
                                        end
                                    end
                                end
                            end
                            if cailiaoGet then
                                room:setTag("cailiaoGet", sgs.QVariant(cailiaoGet))
                            end
                            if cailiaoOther then
                                room:setTag("cailiaoOther", sgs.QVariant(cailiaoOther))
                            end
                        end
                    end
                end
            end
        else
            if player:getPhase() == sgs.Player_Discard then
                if not player:isDead() then
                    local ShuukanBunshun = room:findPlayerBySkillName("Luacailiao")
                    if ShuukanBunshun then
                        local tag = room:getTag("cailiaoGet")
                        local cailiao_cardsToGet
                        local cailiao_cardsOther
                        if tag then
                            cailiao_cardsToGet = tag:toString():split("+")
                        else
                            return false
                        end
                        tag = room:getTag("cailiaoOther")
                        if tag then
                            cailiao_cardsOther = tag:toString():split("+")
                        end
                        room:removeTag("cailiaoGet")
                        room:removeTag("cailiaoOther")
                        local cardsToGet = sgs.IntList()
                        local cards = sgs.IntList()
                        for i = 1, #cailiao_cardsToGet, 1 do
                            local card_data = cailiao_cardsToGet[i]
                            if card_data == nil then
                                return false
                            end
                            if card_data ~= "" then
                                local card_id = tonumber(card_data)
                                if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                                    cardsToGet:append(card_id)
                                    cards:append(card_id)
                                end
                            end
                        end
                        if cailiao_cardsOther then
                            for i = 1, #cailiao_cardsOther, 1 do
                                local card_data = cailiao_cardsOther[i]
                                if card_data == nil then
                                    return false
                                end
                                if card_data ~= "" then
                                    local card_id = tonumber(card_data)
                                    if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                                        cardsToGet:append(card_id)
                                        cards:append(card_id)
                                    end
                                end
                            end
                        end
                        if cardsToGet:length() > 0 then
                            local ai_data = sgs.QVariant()
                            ai_data:setValue(cards:length())
                            if ShuukanBunshun:askForSkillInvoke(self:objectName(), ai_data) then
                                ShuukanBunshun:addToPile("&liao", cards)
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
ShuukanBunshun:addSkill(Luacailiao)

--[[
    技能名：开炮
    描述：出牌阶段，你可以将三张不同花色的“料”置于一名其他角色的武将牌上视为“文春砲”，武将牌上有“文春砲”的角色在其下三个判定阶段分别进行一次判定，若判定结果为黑桃2~9，其受到3点无来源的伤害，三次判定完成后其获得其武将牌上所有“文春砲”。
]]
LuabunshunhouCard = sgs.CreateSkillCard {
    name = "LuabunshunhouCard",
    skill_name = "Luabunshunhou",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getPile("bunshunhou"):isEmpty()
    end,
    on_effect = function(self, effect)
        effect.from:getRoom():setPlayerMark(effect.to, "bunshunhou", 3)
        effect.to:addToPile("bunshunhou", self)
    end,
}
LuabunshunhouVS = sgs.CreateViewAsSkill {
    name = "Luabunshunhou",
    n = 3,
    filter_pattern = ".|.|.|&liao",
    expand_pile = "&liao",
    view_filter = function(self, selected, to_select)
        if sgs.Self:getPile("&liao"):contains(to_select:getEffectiveId()) then
            for _, card in ipairs(selected) do
                if card:getSuit() == to_select:getSuit() then
                    return false
                end
            end
        end
        return true
    end,
    view_as = function(self, cards)
        local cd = LuabunshunhouCard:clone()
        for _, card in pairs(cards) do
            cd:addSubcard(card)
        end
        cd:setSkillName(self:objectName())
        return cd
    end,
}
Luabunshunhou = sgs.CreateTriggerSkill {
    name = "Luabunshunhou",
    events = {sgs.EventPhaseProceeding},
    view_as_skill = LuabunshunhouVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Judge then
            if player:getMark("bunshunhou") ~= 0 and player:getPile("bunshunhou"):length() ~= 0 then
                local judge = sgs.JudgeStruct()
                judge.pattern = ".|spade|2~9"
                judge.good = false
                judge.reason = self:objectName()
                judge.who = player
                room:judge(judge)
                if judge:isBad() then
                    room:damage(sgs.DamageStruct(self:objectName(), nil, player, 3))
                end
                room:setPlayerMark(player, "bunshunhou", player:getMark("bunshunhou") - 1)
                if player:getMark("bunshunhou") == 0 then
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    for _, card in sgs.qlist(player:getPile("bunshunhou")) do
                        dummy:addSubcard(card);
                    end
                    room:obtainCard(player, dummy)
                    dummy:deleteLater()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ShuukanBunshun:addSkill(Luabunshunhou)

sgs.LoadTranslationTable {
    ["ShuukanBunshun"] = "週刊文春",
    ["&ShuukanBunshun"] = "週刊文春",
    ["#ShuukanBunshun"] = "直言不諱",
    ["designer:ShuukanBunshun"] = "Cassimolar",
    ["cv:ShuukanBunshun"] = "週刊文春",
    ["illustrator:ShuukanBunshun"] = "Cassimolar",
    ["Luacailiao"] = "采料",
    [":Luacailiao"] = "其他角色的弃牌阶段结束时，你可以获得该角色于此阶段内弃置的基本牌并置于你的武将牌旁称为“料”，“料”可以视为手牌使用或打出。",
    ["&liao"] = "料",
    ["Luabunshunhou"] = "开炮",
    [":Luabunshunhou"] = "出牌阶段，你可以将三张不同花色的“料”置于一名其他角色的武将牌上视为“文春砲”，武将牌上有“文春砲”的角色在其下三个判定阶段分别进行一次判定，若判定结果为黑桃2~9，其受到3点无来源的伤害，三次判定完成后其获得其武将牌上所有“文春砲”。",
    ["bunshunhou"] = "文春砲",
}
