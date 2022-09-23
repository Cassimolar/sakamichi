require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MarinaFujisaki = sgs.General(Zambi, "MarinaFujisaki", "Zambi", 4, false)
table.insert(SKMC.NiKiSei, "MarinaFujisaki")

--[[
    技能名：仓库
    描述：当你使用或打出牌时，你可以展示所有手牌（至少一张），若没有相同花色的牌，你可以从弃牌堆内获得一张与你使用或打出的牌类别相同的牌。
]]
Luasouko = sgs.CreateTriggerSkill {
    name = "Luasouko",
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and not card:isKindOf("SkillCard") and not player:isKongcheng()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:showAllCards(player)
            local different_suit = false
            local has_heart = false
            local has_diamond = false
            local has_spade = false
            local has_club = false
            if player:getHandcardNum() >= 5 then
                different_suit = true
            else
                for _, card in sgs.qlist(player:getHandcards()) do
                    if card:getSuit() == sgs.Card_Heart then
                        has_heart = true
                    elseif card:getSuit() == sgs.Card_Diamond then
                        has_diamond = true
                    elseif card:getSuit() == sgs.Card_Spade then
                        has_spade = true
                    elseif card:getSuit() == sgs.Card_Club then
                        has_club = true
                    end
                end
                local n = 0
                if has_heart then
                    n = n + 1
                end
                if has_diamond then
                    n = n + 1
                end
                if has_spade then
                    n = n + 1
                end
                if has_club then
                    n = n + 1
                end
                if player:getHandcardNum() > n then
                    different_suit = true
                end
            end
            if not different_suit then
                local toGainList = sgs.IntList()
                for _, id in sgs.qlist(room:getDiscardPile()) do
                    if sgs.Sanguosha:getCard(id):getTypeId() == card:getTypeId() then
                        toGainList:append(id)
                    end
                end
                if toGainList:length() ~= 0 then
                    room:fillAG(toGainList, player)
                    local card_id = room:askForAG(player, toGainList, true, self:objectName())
                    if card_id ~= -1 then
                        room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceHand, true)
                    end
                    room:clearAG(player)
                end
            end
        end
    end,
}
MarinaFujisaki:addSkill(Luasouko)

--[[
    技能名：正义
    描述：出牌阶段限一次，你可以将一张武器牌交给一名其他角色，令其选择对另一名你指定的其他角色使用一张【杀】或本回合内所有技能失效，若其以此法杀死一名角色其获得【仓库】。
]]
LuajusticeCard = sgs.CreateSkillCard {
    name = "LuajusticeCard",
    skill_name = "Luajustice",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        targets[1]:obtainCard(self)
        room:setPlayerFlag(targets[1], "justice")
        local target = room:askForPlayerChosen(source, room:getOtherPlayers(targets[1]), "Luajustice",
            "@justice_invoke:" .. targets[1]:objectName(), false, false)
        if not room:askForUseSlashTo(targets[1], target, "@justice_slash:" .. target:objectName(), true, false) then
            room:setPlayerFlag(targets[1], "justice_Invalidity")
        end
        if targets[1]:hasFlag("justice") then
            room:setPlayerFlag(targets[1], "-justice")
            local msg = sgs.LogMessage()
            msg.type = "#justice"
            msg.from = source
            msg.to:append(targets[1])
            msg.arg = "Luajustice"
            room:sendLog(msg)
        end
    end,
}
LuajusticeVS = sgs.CreateOneCardViewAsSkill {
    name = "Luajustice",
    filter_pattern = "Weapon",
    view_as = function(self, card)
        local skill_card = LuajusticeCard:clone()
        skill_card:addSubcard(card)
        skill_card:setSkillName(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        if player:getWeapon() then
            return not player:hasUsed("#LuajusticeCard")
        else
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isKindOf("Weapon") then
                    return not player:hasUsed("#LuajusticeCard")
                end
            end
        end
        return false
    end,
}
Luajustice = sgs.CreateTriggerSkill {
    name = "Luajustice",
    view_as_skill = LuajusticeVS,
    events = {sgs.CardUsed, sgs.CardFinished, sgs.Death, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() and player:hasFlag("justice") then
                room:setPlayerFlag(player, "-justice")
                room:setCardFlag(use.card, "justice")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("justice") then
                room:setCardFlag(use.card, "-justice")
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                local damage = death.damage
                if damage and damage.from and damage.card and damage.card:isKindOf("Slash")
                    and damage.card:hasFlag("justice") then
                    room:handleAcquireDetachSkills(damage.from, "Luasouko", true)
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("justice_Invalidity") then
                    room:setPlayerFlag(p, "-justice_Invalidity")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuajusticeInvalidity = sgs.CreateInvaliditySkill {
    name = "#LuajusticeInvalidity",
    skill_valid = function(self, player, skill)
        if player:hasFlag("justice_Invalidity") then
            return false
        else
            return true
        end
    end,
}
MarinaFujisaki:addSkill(Luajustice)
if not sgs.Sanguosha:getSkill("#LuajusticeInvalidity") then
    SKMC.SkillList:append(LuajusticeInvalidity)
end

sgs.LoadTranslationTable {
    ["MarinaFujisaki"] = "藤崎 麻里奈",
    ["&MarinaFujisaki"] = "藤崎 麻里奈",
    ["#MarinaFujisaki"] = "お揃い",
    ["designer:MarinaFujisaki"] = "Cassimolar",
    ["cv:MarinaFujisaki"] = "鈴木 絢音",
    ["illustrator:MarinaFujisaki"] = "Cassimolar",
    ["Luasouko"] = "仓库",
    [":Luasouko"] = "当你使用或打出牌时，你可以展示所有手牌（至少一张），若没有相同花色的牌，你可以从弃牌堆内获得一张与你使用或打出的牌类别相同的牌。",
    ["Luajustice"] = "正义",
    [":Luajustice"] = "出牌阶段限一次，你可以将一张武器牌交给一名其他角色，令其选择对另一名你指定的其他角色使用一张【杀】或本回合内所有技能失效，若其以此法杀死一名角色其获得【仓库】。",
    ["@justice_invoke"] = "请选择%src使用【杀】的目标",
    ["@justice_slash"] = "请对%src使用一张【杀】否则本回合内你的所有技能失效",
}
