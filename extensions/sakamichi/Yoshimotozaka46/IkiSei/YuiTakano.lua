require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiTakano = sgs.General(Sakamichi, "YuiTakano", "Yoshimotozaka46", 3, false)
table.insert(SKMC.IKiSei, "YuiTakano")

--[[
    技能名：酒豪
    描述：你可以将任意手牌视为【酒】使用或打出；当你使用的【酒】对应的不同的实体牌达到6张时，你下一张【杀】命中后目标直接死亡，无论此杀是否命中，重置你【酒】的对应的不同的实体牌的计算。
]]
LuajiuhaoVS = sgs.CreateOneCardViewAsSkill {
    name = "Luajiuhao",
    response_pattern = "analeptic",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
        analeptic:setSkillName(self:objectName())
        analeptic:addSubcard(card)
        return analeptic
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
        card:deleteLater()
        if player:isCardLimited(card, sgs.Card_MethodUse) or player:isProhibited(player, card) then
            return false
        end
        return
            player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, card)
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "analeptic")
    end,
}
Luajiuhao = sgs.CreateTriggerSkill {
    name = "Luajiuhao",
    view_as_skill = LuajiuhaoVS,
    events = {sgs.CardUsed, sgs.CardResponded, sgs.SlashHit, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.CardUsed or event == sgs.CardResponded) and player:hasSkill(self) then
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                if use.card:isKindOf("Analeptic") then
                    local list = player:getTag("jiuhao_use"):toIntList()
                    for _, id in sgs.qlist(use.card:getSubcards()) do
                        if not list:contains(id) then
                            list:append(id)
                            room:addPlayerMark(player, "&jiuhao")
                        end
                    end
                    local tag = sgs.QVariant()
                    tag:setValue(list)
                    player:setTag("jiuhao_use", tag)
                elseif use.card:isKindOf("Slash") then
                    if player:getTag("jiuhao_use"):toIntList():length() >= 6 then
                        room:setCardFlag(use.card, "jiuhao")
                        player:removeTag("jiuhao_use")
                        room:setPlayerMark(player, "&jiuhao", 0)
                    end
                end
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    if response.m_card:isKindOf("Analeptic") then
                        local list = player:getTag("jiuhao_use"):toIntList()
                        for _, id in sgs.qlist(response.m_card:getSubcards()) do
                            if not list:contains(id) then
                                list:append(id)
                                room:addPlayerMark(player, "&jiuhao")
                            end
                        end
                        local tag = sgs.QVariant()
                        tag:setValue(list)
                        player:setTag("jiuhao_use", tag)
                    end
                end
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("jiuhao") then
                room:killPlayer(effect.to)
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.card:hasFlag("jiuhao") then
                room:setCardFlag(use.card, "-jiuhao")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuiTakano:addSkill(Luajiuhao)

--[[
    技能名：美臀
    描述：出牌阶段限一次，你可以令一名角色对你使用一张【杀】，若其未如此做，你本回合的下一张【酒】不计入使用次数限制。
]]
LuameitunCard = sgs.CreateSkillCard {
    name = "LuameitunCard",
    skill_name = "Luameitun",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local use_slash = false
        if effect.to:canSlash(effect.from, nil, true) then
            use_slash = room:askForUseSlashTo(effect.to, effect.from, "@meitun_slash:" .. effect.from:objectName())
        end
        if not use_slash then
            room:setPlayerFlag(effect.from, "meitun")
        end
    end,
}
LuameitunVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luameitun",
    view_as = function()
        return LuameitunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuameitunCard")
    end,
}
Luameitun = sgs.CreateTriggerSkill {
    name = "Luameitun",
    view_as_skill = LuameitunVS,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Analeptic") and player:hasFlag("meitun") then
            if use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
                room:setPlayerFlag(player, "-meitun")
            end
        end
    end,
}
YuiTakano:addSkill(Luameitun)

sgs.LoadTranslationTable {
    ["YuiTakano"] = "高野 祐衣",
    ["&YuiTakano"] = "高野 祐衣",
    ["#YuiTakano"] = "唎酒師",
    ["designer:YuiTakano"] = "Cassimolar",
    ["cv:YuiTakano"] = "高野 祐衣",
    ["illustrator:YuiTakano"] = "Cassimolar",
    ["Luajiuhao"] = "酒豪",
    [":Luajiuhao"] = "你可以将任意手牌视为【酒】使用或打出；当你使用的【酒】对应的不同的实体牌达到6张时，你下一张【杀】命中后目标直接死亡，无论此杀是否命中，重置你【酒】的对应的不同的实体牌的计算。",
    ["jiuhao"] = "酒豪",
    ["Luameitun"] = "美臀",
    [":Luameitun"] = "出牌阶段限一次，你可以令一名角色对你使用一张【杀】，若其未如此做，你本回合的下一张【酒】不计入使用次数限制。",
    ["@meitun_slash"] = "请对%src 使用一张【杀】否则其本回合内使用的下一张【酒】不计入使用次数",
}
