require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinaKawata_Hinatazaka = sgs.General(Sakamichi, "HinaKawata_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.NiKiSei, "HinaKawata_Hinatazaka")

--[[
    技能名：神偷
    描述：出牌阶段限一次，你可以将一张手牌视为【顺手牵羊】使用；你使用【顺手牵羊】无距离限制；限定技，摸牌阶段，你可以放弃摸牌，若如此做，视为你对每名其他角色分别使用一张【顺手牵羊】。
]]
LuashentouVS = sgs.CreateOneCardViewAsSkill {
    name = "Luashentou",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local snatch = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
        snatch:addSubcard(card)
        snatch:setSkillName(self:objectName())
        return snatch
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("shentou_used")
    end,
}
Luashentou = sgs.CreateTriggerSkill {
    name = "Luashentou",
    frequency = sgs.Skill_Limited,
    limit_mark = "@shentou",
    view_as_skill = LuashentouVS,
    events = {sgs.CardUsed, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Snatch") and use.card:getSkillName() == self:objectName()
                and player:getPhase() == sgs.Player_Play then
                room:setPlayerFlag(player, "shentou_used")
            end
        else
            if player:getMark("@shentou") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                player:loseMark("@shentou")
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if not p:isAllNude() then
                        local snatch = sgs.Sanguosha:cloneCard("snatch", sgs.Card_NoSuit, -1)
                        snatch:setSkillName(self:objectName())
                        if not room:isProhibited(player, p, snatch) then
                            room:useCard(sgs.CardUseStruct(snatch, player, p), false)
                        end
                    end
                end
                data:setValue(0)
            end
        end
        return false
    end,
}
LuashentouTargetMod = sgs.CreateTargetModSkill {
    name = "#LuashentouTargetMod",
    pattern = "Snatch",
    distance_limit_func = function(self, player)
        if player:hasSkill("Luashentou") then
            return 1000
        else
            return 0
        end
    end,
}
HinaKawata_Hinatazaka:addSkill(Luashentou)
if not sgs.Sanguosha:getSkill("#LuashentouTargetMod") then
    SKMC.SkillList:append(LuashentouTargetMod)
end

--[[
    技能名：世界
    描述：锁定技，当你成为基本牌或通常锦囊牌的目标时，你须进行一次判定，若结果为：♥，此牌的使用者回复1点体力；♦，此牌对你无效；♠，此牌的使用者摸一张牌；♣，此牌的使用者失去1点体力。
]]
Luashijie = sgs.CreateTriggerSkill {
    name = "Luashijie",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
            local judge = sgs.JudgeStruct()
            judge.pattern = "."
            judge.good = true
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            if judge.card:getSuit() == sgs.Card_Spade then
                room:drawCards(use.from, 1, self:objectName())
            elseif judge.card:getSuit() == sgs.Card_Heart then
                if use.from:isWounded() then
                    room:recover(use.from, sgs.RecoverStruct(player, use.card))
                end
            elseif judge.card:getSuit() == sgs.Card_Club then
                room:loseHp(use.from)
            elseif judge.card:getSuit() == sgs.Card_Diamond then
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
}
HinaKawata_Hinatazaka:addSkill(Luashijie)

sgs.LoadTranslationTable {
    ["HinaKawata_Hinatazaka"] = "河田 陽菜",
    ["&HinaKawata_Hinatazaka"] = "河田 陽菜",
    ["#HinaKawata_Hinatazaka"] = "怪盜",
    ["designer:HinaKawata_Hinatazaka"] = "Cassimolar",
    ["cv:HinaKawata_Hinatazaka"] = "河田 陽菜",
    ["illustrator:HinaKawata_Hinatazaka"] = "Cassimolar",
    ["Luashentou"] = "神偷",
    [":Luashentou"] = "出牌阶段限一次，你可以将一张手牌视为【顺手牵羊】使用；你使用【顺手牵羊】无距离限制；限定技，摸牌阶段，你可以放弃摸牌，若如此做，视为你对每名其他角色分别使用一张【顺手牵羊】。",
    ["@shentou"] = "偷",
    ["Luashijie"] = "世界",
    [":Luashijie"] = "锁定技，当你成为基本牌或通常锦囊牌的目标时，你须进行一次判定，若结果为：♥，此牌的使用者回复1点体力；♦，此牌对你无效；♠，此牌的使用者摸一张牌；♣，此牌的使用者失去1点体力。",
}
