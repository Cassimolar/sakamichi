require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiKashiwagi = sgs.General(Sakamichi, "YuiKashiwagi", "AutisticGroup", 3, false)
table.insert(SKMC.IKiSei, "YuiKashiwagi")

--[[
    技能名：写真
    描述：出牌阶段限一次，你可以弃置一张装备区的牌，然后若你的装备区的装备数：不多于四张，你摸一张牌；不多于三张，你可以弃置一张牌对一名角色造成1点伤害；不多于两张，本回合内你使用的【杀】无法闪避；不多于一张，本回合内你使用的下一张【杀】可以额外指定一个目标；不多于零张，你可以选择一名其他角色，获取其所有手牌，然后你将武将牌翻面，你以此法翻面武将牌三次以上时失去此技能。
]]
LuaxiezhenCard = sgs.CreateSkillCard {
    name = "LuaxiezhenCard",
    skill_name = "Luaxiezhen",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local n = source:getEquips():length()
        if n <= 4 then
            room:drawCards(source, 1, "Luaxiezhen")
        end
        if n <= 3 then
            if room:askForDiscard(source, "Luaxiezhen", 1, 1, true, false, "@xiezhen_discard") then
                room:damage(sgs.DamageStruct("Luaxiezhen", source, room:askForPlayerChosen(source,
                    room:getAlivePlayers(), "Luaxiezhen", "@xiezhen_choice_1")))
            end
        end
        if n <= 2 then
            room:setPlayerFlag(source, "xiezhen_2")
        end
        if n <= 1 then
            room:setPlayerFlag(source, "xiezhen_1")
        end
        if n <= 0 then
            local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), "Luaxiezhen",
                "@xiezhen_choice_2", true)
            if target then
                room:obtainCard(source, target:wholeHandCards(), false)
                room:addPlayerMark(source, "xiezhen_num", 1)
                source:turnOver()
            end
        end
        if source:getMark("xiezhen_num") >= 3 then
            room:handleAcquireDetachSkills(source, "-Luaxiezhen", false)
        end
    end,
}
LuaxiezhenVS = sgs.CreateOneCardViewAsSkill {
    name = "Luaxiezhen",
    filter_pattern = ".|.|.|equipped",
    view_as = function(self, card)
        local acard = LuaxiezhenCard:clone()
        acard:addSubcard(card)
        acard:setSkillName(self:objectName())
        return acard
    end,
    enabled_at_play = function(self, player)
        return player:getEquips():length() > 0 and not player:hasUsed("#LuaxiezhenCard")
    end,
}
Luaxiezhen = sgs.CreateTriggerSkill {
    name = "Luaxiezhen",
    view_as_skill = LuaxiezhenVS,
    events = {sgs.SlashProceed, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasFlag("xiezhen_2") then
                room:slashResult(effect, nil)
                return true
            end
        else
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:hasFlag("xiezhen_1") then
                room:setPlayerFlag(player, "-xiezhen_1")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuaxiezhenMod = sgs.CreateTargetModSkill {
    name = "#LuaxiezhenMod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Slash",
    extra_target_func = function(self, player)
        if player:hasFlag("xiezhen_1") then
            return 1
        else
            return 0
        end
    end,
}
Sakamichi:insertRelatedSkills("Luaxiezhen", "#LuaxiezhenMod")
YuiKashiwagi:addSkill(Luaxiezhen)
YuiKashiwagi:addSkill(LuaxiezhenMod)

sgs.LoadTranslationTable {
    ["YuiKashiwagi"] = "柏木 佑井",
    ["&YuiKashiwagi"] = "柏木 佑井",
    ["#YuiKashiwagi"] = "老司機",
    ["designer:YuiKashiwagi"] = "Cassimolar",
    ["cv:YuiKashiwagi"] = "今泉 佑唯",
    ["illustrator:YuiKashiwagi"] = "Cassimolar",
    ["Luaxiezhen"] = "写真",
    [":Luaxiezhen"] = "出牌阶段限一次，你可以弃置一张装备区的牌，然后若你的装备区的装备数：不多于四张，你摸一张牌；不多于三张，你可以弃置一张牌对一名角色造成1点伤害；不多于两张，本回合内你使用的【杀】无法闪避；不多于一张，本回合内你使用的下一张【杀】可以额外指定一个目标；不多于零张，你可以选择一名其他角色，获取其所有手牌，然后你将武将牌翻面，你以此法翻面武将牌三次以上时失去此技能。",
    ["@xiezhen_discard"] = "你可以弃置一张牌来对一名角色造成1点伤害",
    ["@xiezhen_choice_1"] = "选择一名角色对其造成1点伤害",
    ["@xiezhen_choice_2"] = "你可以选择一名其他角色获得其所有手牌并将你的武将牌翻面",
}
