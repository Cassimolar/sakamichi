require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AmonNijihiko = sgs.General(Sakamichi, "AmonNijihiko", "AutisticGroup", 3, true)

--[[
    技能名：投射
    描述：其他角色对你造成伤害后，若此伤害有对应实体牌，你可以将对应实体牌置于其武将牌上称为“投射”。
]]
Luaprojection = sgs.CreateTriggerSkill {
    name = "Luaprojection",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() and damage.card
            and not damage.card:isKindOf("SkillCard")
            and (not damage.card:isVirtualCard()
                or (damage.card:isVirtualCard() and damage.card:getSubcards():length() > 0))
            and room:askForSkillInvoke(player, self:objectName(), data) then
            damage.from:addToPile("projection", damage.card)
        end
        return false
    end,
}
AmonNijihiko:addSkill(Luaprojection)

--[[
    技能名：分析
    描述：出牌阶段限一次，你可以获得一名角色所有的“投射”，若如此做，其本回合内无法使用或打出“投射”所包含的卡牌类型。
]]
LuapsychoanalysisCard = sgs.CreateSkillCard {
    name = "LuapsychoanalysisCard",
    skill_name = "Luapsychoanalysis",
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:getPile("projection"):isEmpty()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local basic, trick, equip = false, false, false
        for _, id in sgs.qlist(effect.to:getPile("projection")) do
            if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                basic = true
            end
            if sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
                trick = true
            end
            if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
                equip = true
            end
        end
        if basic then
            room:setPlayerCardLimitation(effect.to, "use,response", "BasicCard", true)
            local msg = sgs.LogMessage()
            msg.type = "#psychoanalysis_basic"
            msg.from = effect.to
            room:sendLog(msg)
        end
        if trick then
            room:setPlayerCardLimitation(effect.to, "use,response", "TrickCard", true)
            local msg = sgs.LogMessage()
            msg.type = "#psychoanalysis_trick"
            msg.from = effect.to
            room:sendLog(msg)
        end
        if equip then
            room:setPlayerCardLimitation(effect.to, "use,response", "EquipCard", true)
            local msg = sgs.LogMessage()
            msg.type = "#psychoanalysis_equip"
            msg.from = effect.to
            room:sendLog(msg)
        end
        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        for _, id in sgs.qlist(effect.to:getPile("projection")) do
            dummy:addSubcard(id)
        end
        room:obtainCard(effect.from, dummy)
    end,
}
Luapsychoanalysis = sgs.CreateZeroCardViewAsSkill {
    name = "Luapsychoanalysis",
    view_as = function()
        return LuapsychoanalysisCard:clone()
    end,
    enabled_at_play = function(self, player)
        local can = false
        if not player:getPile("projection"):isEmpty() then
            can = true
        else
            for _, p in sgs.qlist(player:getSiblings()) do
                if not p:getPile("projection"):isEmpty() then
                    can = true
                    break
                end
            end
        end
        return not player:hasUsed("#LuapsychoanalysisCard") and can
    end,
}
AmonNijihiko:addSkill(Luapsychoanalysis)

sgs.LoadTranslationTable {
    ["AmonNijihiko"] = "亜門 虹彦",
    ["&AmonNijihiko"] = "亜門 虹彦",
    ["#AmonNijihiko"] = "公式心理師",
    ["designer:AmonNijihiko"] = "Cassimolar",
    ["cv:AmonNijihiko"] = "亜門 虹彦",
    ["illustrator:AmonNijihiko"] = "Cassimolar",
    ["Luaprojection"] = "投射",
    [":Luaprojection"] = "其他角色对你造成伤害后，若此伤害有对应实体牌，你可以将对应实体牌置于其武将牌上称为“投射”。",
    ["projection"] = "投射",
    ["Luapsychoanalysis"] = "分析",
    [":Luapsychoanalysis"] = "出牌阶段限一次，你可以获得一名角色所有的“投射”，若如此做，其本回合内无法使用或打出“投射”所包含的卡牌类型。",
    ["#psychoanalysis_basic"] = "%from 的“投射”中包含基本牌，本回合%from 无法使用或打出基本牌",
    ["#psychoanalysis_trick"] = "%from 的“投射”中包含锦囊牌，本回合%from 无法使用或打出锦囊牌",
    ["#psychoanalysis_equip"] = "%from 的“投射”中包含装备牌，本回合%from 无法使用或打出装备牌",
}
