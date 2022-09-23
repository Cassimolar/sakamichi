require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SuzukaTomita_Hinatazaka = sgs.General(Sakamichi, "SuzukaTomita_Hinatazaka", "Hinatazaka46", 4, false)
table.insert(SKMC.NiKiSei, "SuzukaTomita_Hinatazaka")

--[[
    技能名：假哭
    描述：当你受到【杀】造成的伤害后，你可以令伤害来源选择是否令你回复1点体力并摸一张牌，否则你可以弃置一张【闪】视为对一名其他角色使用一张【杀】并回复1点体力，若此【杀】命中，你摸一张牌。
]]
LuajiakuCard = sgs.CreateSkillCard {
    name = "LuajiakuCard",
    skill_name = "Luajiaku",
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:canSlash(to_select, nil, false)
    end,
    on_effect = function(self, effect)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName("Luajiaku")
        slash:setFlags("jiaku")
        local use = sgs.CardUseStruct()
        use.card = slash
        use.from = effect.from
        use.to:append(effect.to)
        effect.from:getRoom():useCard(use)
    end,
}
LuajiakuVS = sgs.CreateOneCardViewAsSkill {
    name = "Luajiaku",
    view_filter = function(self, to_select)
        return not to_select:isEquipped() and to_select:isKindOf("Jink")
    end,
    view_as = function(self, cards)
        local cd = LuajiakuCard:clone()
        cd:addSubcard(cards)
        return cd
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@Luajiaku")
    end,
}
Luajiaku = sgs.CreateTriggerSkill {
    name = "Luajiaku",
    frequency = sgs.Skill_Frequent,
    view_as_skill = LuajiakuVS,
    events = {sgs.Damaged, sgs.SlashHit},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:isAlive()
                and room:askForSkillInvoke(player, self:objectName(), data) then
                local choices = {"jiaku1=" .. player:objectName()}
                if not player:isKongcheng() then
                    table.insert(choices, "jiaku2=" .. player:objectName())
                end
                if room:askForChoice(damage.from, self:objectName(), table.concat(choices, "+")) == "jiaku1="
                    .. player:objectName() then
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(damage.from, damage.card, 1))
                        room:drawCards(player, 1, self:objectName())
                    end
                else
                    --					room:showAllCards(player)
                    --					for _, card in sgs.qlist(player:getHandcards()) do
                    --						if card:isKindOf("Jink") then
                    --							local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    --							slash:setSkillName(self:objectName())
                    --							room:useCard(sgs.CardUseStruct(slash, player, damage.from))
                    --							if player:isWounded() then
                    --								room:recover(player, sgs.RecoverStruct(player))
                    --							end
                    --						end
                    --					end
                    room:askForUseCard(player, "@@Luajiaku", "@jiaku", -1, sgs.Card_MethodDiscard, false)
                end
            end
        else
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("jiaku") then
                room:drawCards(effect.from, 1, self:objectName())
            end
        end
        return false
    end,
}
SuzukaTomita_Hinatazaka:addSkill(Luajiaku)

--[[
    技能名：迷走
    描述：锁定技，非你使用的【杀】指定与你势力相同的其他角色为目标时，若你不为此【杀】的目标，你也会被指定为额外目标。
]]
Luamizou = sgs.CreateTriggerSkill {
    name = "Luamizou",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Slash") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= use.from:objectName() and p:getKingdom() == player:getKingdom()
                    and not use.to:contains(p) then
                    use.to:append(p)
                end
            end
            data:setValue(use)
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SuzukaTomita_Hinatazaka:addSkill(Luamizou)

sgs.LoadTranslationTable {
    ["SuzukaTomita_Hinatazaka"] = "富田 鈴花",
    ["&SuzukaTomita_Hinatazaka"] = "富田 鈴花",
    ["#SuzukaTomita_Hinatazaka"] = "敗者女王",
    ["designer:SuzukaTomita_Hinatazaka"] = "Cassimolar",
    ["cv:SuzukaTomita_Hinatazaka"] = "富田 鈴花",
    ["illustrator:SuzukaTomita_Hinatazaka"] = "Cassimolar",
    ["Luajiaku"] = "假哭",
    [":Luajiaku"] = "当你受到【杀】造成的伤害后，你可以令伤害来源选择是否令你回复1点体力并摸一张牌，否则你可以弃置一张【闪】视为对一名其他角色使用一张【杀】并回复1点体力，若此【杀】命中，你摸一张牌。",
    ["Luajiaku:jiaku1"] = "令%src回复1点体力并摸一张牌",
    ["Luajiaku:jiaku2"] = "令%src可以弃置一张【闪】来视为使用一张【杀】",
    ["@jiaku"] = "你可以弃置一张【闪】视为使用一张【杀】",
    ["Luamizou"] = "迷走",
    [":Luamizou"] = "锁定技，非你使用的【杀】指定与你势力相同的其他角色为目标时，若你不为此【杀】的目标，你也会被指定为额外目标。",
}
