require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KaedeYamanuro = sgs.General(Zambi, "KaedeYamanuro", "Zambi", 3, false)
table.insert(SKMC.IKiSei, "KaedeYamanuro")

--[[
    技能名：忧郁
    描述：当一名角色在其出牌阶段外使用【杀】时，你可以弃置一张【闪】来令此【杀】无效。
]]
Luayuutsu = sgs.CreateTriggerSkill {
    name = "Luayuutsu",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") and use.from:getPhase() ~= sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForCard(p, "Jink", "@yuutsu_invoke:" .. use.from:objectName(), data, self:objectName()) then
                    local msg = sgs.LogMessage()
                    local nullified_list = use.nullified_list
                    for _, p in sgs.qlist(use.to) do
                        table.insert(nullified_list, p:objectName())
                        msg.to:append(p)
                    end
                    use.nullified_list = nullified_list
                    data:setValue(use)
                    msg.type = "#yuutsu_nullify"
                    msg.from = use.from
                    msg.arg = use.card:objectName()
                    room:sendLog(msg)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KaedeYamanuro:addSkill(Luayuutsu)

--[[
    技能名：天台
    描述：出牌阶段限一次，你可以令一名其他角色弃置你一张牌，然后你弃置其一张牌，若以此法弃置的两张牌中：没有【闪】，你获得其一张牌或对其造成1点伤害；有【闪】，你摸一张牌，此技能视为未发动过。
    引用：
]]
LuaokujiyouCard = sgs.CreateSkillCard {
    name = "LuaokujiyouCard",
    skill_name = "Luaokujiyou",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card1 = sgs.Sanguosha:getCard(room:askForCardChosen(effect.to, effect.from, "he", "Luaokujiyou", false,
            sgs.Card_MethodDiscard))
        room:throwCard(card1, effect.from, effect.to)
        local card2 = sgs.Sanguosha:getCard(room:askForCardChosen(effect.from, effect.to, "he", "Luaokujiyou", false,
            sgs.Card_MethodDiscard))
        room:throwCard(card2, effect.to, effect.from)
        if card1:isKindOf("Jink") or card2:isKindOf("Jink") then
            room:drawCards(effect.from, 1, "Luaokujiyou")
        elseif effect.to:isNude() then
            room:damage(sgs.DamageStruct("Luaokujiyou", effect.from, effect.to, 1))
            room:setPlayerFlag(effect.from, "okujiyou_used")
        else
            if room:askForChoice(effect.from, "Luaokujiyou", "obtain+damage") == "obtain" then
                local card_id = room:askForCardChosen(effect.from, effect.to, "he", "Luaokujiyou")
                local card = sgs.Sanguosha:getCard(card_id)
                local place = room:getCardPlace(card_id)
                local unhide = (place ~= sgs.Player_PlaceHand)
                room:obtainCard(effect.from, card, unhide)
                room:setPlayerFlag(effect.from, "okujiyou_used")
            else
                room:damage(sgs.DamageStruct("Luaokujiyou", effect.from, effect.to, 1))
                room:setPlayerFlag(effect.from, "okujiyou_used")
            end
        end
    end,
}
Luaokujiyou = sgs.CreateZeroCardViewAsSkill {
    name = "Luaokujiyou",
    view_as = function()
        return LuaokujiyouCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("okujiyou_used") and not player:isNude()
    end,
}
KaedeYamanuro:addSkill(Luaokujiyou)

--[[
    技能名：同寿
    描述：限定技，出牌阶段你可以选择：1，对任意名其他角色分别造成1点火焰伤害，然后你受到等同于你选择目标数的火焰伤害；2，令任意名其他角色和你的武将牌横置，然后对你选择的第一名角色造成等同于你已损失体力值的火焰伤害。
]]
LuajisatsubakudanCard = sgs.CreateSkillCard {
    name = "LuajisatsubakudanCard",
    skill_name = "Luajisatsubakudan",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName()
    end,
    feasible = function(self, targets)
        return #targets > 0
    end,
    on_use = function(self, room, source, targets)
        if room:askForChoice(source, "Luajisatsubakudan", "damage+ChainStateChange") == "damage" then
            for _, p in ipairs(targets) do
                room:damage(sgs.DamageStruct("Luajisatsubakudan", source, p, 1, sgs.DamageStruct_Fire))
            end
            room:damage(sgs.DamageStruct("Luajisatsubakudan", source, source, #targets, sgs.DamageStruct_Fire))
        else
            for _, p in ipairs(targets) do
                if not p:isChained() then
                    room:setPlayerChained(p)
                end
            end
            if not source:isChained() then
                room:setPlayerChained(source)
            end
            room:damage(sgs.DamageStruct("Luajisatsubakudan", source, targets[1], source:getLostHp(),
                sgs.DamageStruct_Fire))
        end
        source:loseMark("@gasu")
    end,
}
LuajisatsubakudanVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luajisatsubakudan",
    view_as = function()
        return LuajisatsubakudanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@gasu") ~= 0
    end,
}
Luajisatsubakudan = sgs.CreateTriggerSkill {
    name = "Luajisatsubakudan",
    frequency = sgs.Skill_Limited,
    limit_mark = "@gasu",
    events = {},
    view_as_skill = LuajisatsubakudanVS,
    on_trigger = function()
    end,
}
KaedeYamanuro:addSkill(Luajisatsubakudan)

sgs.LoadTranslationTable {
    ["KaedeYamanuro"] = "山室 楓",
    ["&KaedeYamanuro"] = "山室 楓",
    ["#KaedeYamanuro"] = "扇の行方",
    ["designer:KaedeYamanuro"] = "Cassimolar",
    ["cv:KaedeYamanuro"] = "齋藤 飛鳥",
    ["illustrator:KaedeYamanuro"] = "Cassimolar",
    ["Luayuutsu"] = "忧郁",
    [":Luayuutsu"] = "当一名角色在其出牌阶段外使用【杀】时，你可以弃置一张【闪】来令此【杀】无效。",
    ["@yuutsu_invoke"] = "你可以弃置一张【闪】令%src使用的此【杀】无效",
    ["#yuutsu_nullify"] = "%from 使用的%arg 对%to 无效",
    ["Luaokujiyou"] = "天台",
    [":Luaokujiyou"] = "出牌阶段限一次，你可以令一名其他角色弃置你一张牌，然后你弃置其一张牌，若以此法弃置的两张牌中：没有【闪】，你获得其一张牌或对其造成1点伤害；有【闪】，你摸一张牌，此技能视为未发动过。",
    ["Luaokujiyou:obtain"] = "获得其一张牌",
    ["Luaokujiyou:damage"] = "对其造成1点伤害",
    ["Luajisatsubakudan"] = "同寿",
    [":Luajisatsubakudan"] = "限定技，出牌阶段你可以选择：1.对任意名其他角色分别造成1点火焰伤害，然后你受到等同于你选择目标数的火焰伤害；2.令任意名其他角色和你的武将牌横置，然后对你选择的第一名角色造成等同于你已损失体力值的火焰伤害。",
    ["Luajisatsubakudan:damage"] = "对每名目标分别造成1点火焰伤害",
    ["Luajisatsubakudan:ChainStateChange"] = "横置所有目标并对第一名目标造成等同于你已损失体力值的伤害",
    ["@gasu"] = "煤气",
}
