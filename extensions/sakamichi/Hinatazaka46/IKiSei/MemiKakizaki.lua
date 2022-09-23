require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MemiKakizaki_Hinatazaka = sgs.General(Sakamichi, "MemiKakizaki_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "MemiKakizaki_Hinatazaka")

MemiKakizaki_Hinatazaka:addSkill("Luamengwang")

--[[
    技能名：隐芽
    描述：出牌阶段，若你本局游戏内已受到2/1点非黑桃/黑桃卡牌造成的伤害，你可以选择立即死亡，若如此做你可以另一名其他角色获得X枚“芽”和【萌传】（X为你当前体力值）。
]]
LuayinyaCard = sgs.CreateSkillCard {
    name = "LuayinyaCard",
    skill_name = "Luayinya",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:killPlayer(source)
        local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), "Luayinya", "@yinya_choice", false,
            false)
        room:addPlayerMark(target, "@yinya", source:getHp())
        room:handleAcquireDetachSkills(target, "Luamengchuan", true)
    end,
}
LuayinyaVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luayinya",
    view_as = function(self)
        return LuayinyaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("&yinya_spade") >= 2 or player:getMark("&yinya_not_spade") >= 1
    end,
}
Luayinya = sgs.CreateTriggerSkill {
    name = "Luayinya",
    view_as_skill = LuayinyaVS,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and not damage.card:isKindOf("SkillCard") then
            if damage.card:getSuit() == sgs.Card_Spade then
                room:addPlayerMark(player, "&yinya_spade", damage.damage)
            else
                room:addPlayerMark(player, "&yinya_not_spade", damage.damage)
            end
        end
        return false
    end,
}
MemiKakizaki_Hinatazaka:addSkill(Luayinya)

--[[
    技能名：萌传
    描述：出牌阶段，你可以弃置X枚“芽”并选择至多X名其他角色，令这些角色展示手牌并选择令你获得其中的♥牌（至少一张）或失去1点体力，然后你回复X点体力值(X为你的“芽”的数量)。
]]
LuamengchuanCard = sgs.CreateSkillCard {
    name = "LuamengchuanCard",
    skill_name = "Luamengchuan",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark("@yinya") and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "yinya", source:getMark("@yinya"))
        room:removePlayerMark(source, "@yinya", source:getMark("@yinya"))
        for _, p in ipairs(targets) do
            room:showAllCards(p)
            local choices = {}
            local ids = sgs.IntList()
            for _, card in sgs.qlist(p:getHandcards()) do
                if card:getSuit() == sgs.Card_Heart then
                    ids:append(card:getEffectiveId())
                end
            end
            if not ids:isEmpty() then
                table.insert(choices, "mengchuan_give")
            end
            table.insert(choices, "mengchuan_lose")
            if room:askForChoice(p, "Luamengchuan", table.concat(choices, "+")) == "mengchuan_lose" then
                room:loseHp(p)
            else
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                dummy:addSubcards(ids)
                source:obtainCard(dummy)
            end
        end
        room:recover(source, sgs.RecoverStruct(source, nil, source:getMark("yinya")))
        room:setPlayerMark(source, "yinya", 0)
    end,
}
Luamengchuan = sgs.CreateZeroCardViewAsSkill {
    name = "Luamengchuan",
    view_as = function(self)
        return LuamengchuanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@yinya") ~= 0
    end,
}
if not sgs.Sanguosha:getSkill("Luamengchuan") then
    SKMC.SkillList:append(Luamengchuan)
end

sgs.LoadTranslationTable {
    ["MemiKakizaki_Hinatazaka"] = "柿崎 芽実",
    ["&MemiKakizaki_Hinatazaka"] = "柿崎 芽実",
    ["#MemiKakizaki_Hinatazaka"] = "雪公主天使",
    ["designer:MemiKakizaki_Hinatazaka"] = "Cassimolar",
    ["cv:MemiKakizaki_Hinatazaka"] = "柿崎 芽実",
    ["illustrator:MemiKakizaki_Hinatazaka"] = "Cassimolar",
    ["Luayinya"] = "隐芽",
    [":Luayinya"] = "出牌阶段，若你本局游戏内已受到2/1点非黑桃/黑桃卡牌造成的伤害，你可以选择立即死亡，若如此做你可以另一名其他角色获得X枚“芽”和【萌传】（X为你当前体力值）。",
    ["@yinya_choice"] = "你可以选择一名角色令其获得 %arg 枚“芽”和【萌传】",
    ["yinya_spade"] = "隐芽 ♠",
    ["yinya_not_spade"] = "隐芽 非♠",
    ["Luamengchuan"] = "萌传",
    [":Luamengchuan"] = "出牌阶段，你可以弃置X枚“芽”并选择至多X名其他角色，令这些角色展示手牌并选择令你获得其中的♥牌（至少一张）或失去1点体力，然后你回复X点体力值(X为你的“芽”的数量)。",
    ["@yinya"] = "芽",
    ["mengchuan_give"] = "交出所有♥牌",
    ["mengchuan_lose"] = "失去1点体力",
}
