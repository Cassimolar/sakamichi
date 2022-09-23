require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ToshiakiKasuga = sgs.General(Sakamichi, "ToshiakiKasuga", "AutisticGroup", 4, true)

--[[
    技能名：背心
    描述：游戏开始时，你获得三枚“背心”；一名角色的回合结束时，若其没有防具，你可以弃置一枚“背心”令其选择并视为装备一种防具直到其下个回合开始。
]]
Luabeixin = sgs.CreateTriggerSkill {
    name = "Luabeixin",
    events = {sgs.GameStart, sgs.EventPhaseEnd, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self) then
                room:addPlayerMark(player, "@vest", 3)
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish and player:getArmor() == nil then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("@vest") ~= 0
                        and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                        p:loseMark("@vest")
                        local choices = {"eight_diagram", "renwang_shield", "vine", "silver_lion", "heiguangkai"}
                        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                        room:setPlayerMark(player, "&beixin+" .. choice, 1)
                    end
                end
            end
        else
            if player:getPhase() == sgs.Player_Start then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "&beixin+") and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
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
Luabeixin_Armor = sgs.CreateTriggerSkill {
    name = "#Luabeixin_Armor",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardAsked, sgs.SlashEffected, sgs.CardEffected, sgs.DamageInflicted, sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardAsked and player:getMark("&beixin+eight_diagram") ~= 0 then
            local pattern = data:toStringList()[1]
            if pattern == "jink" then
                if player:askForSkillInvoke("eight_diagram", data) then
                    local judge = sgs.JudgeStruct()
                    judge.pattern = ".|red"
                    judge.good = true
                    judge.reason = self:objectName()
                    judge.who = player
                    judge.play_animation = true
                    room:setEmotion(player, "armor/eight_diagram")
                    room:judge(judge)
                    if judge:isGood() then
                        local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
                        jink:setSkillName(self:objectName())
                        room:provide(jink)
                        return true
                    end
                end
            end
            return false
        elseif event == sgs.SlashEffected then
            if player:getMark("&beixin+renwang_shield") ~= 0 then
                local effect = data:toSlashEffect()
                if effect.slash:isBlack() then
                    room:setEmotion(player, "armor/renwang_shield")
                    local msg = sgs.LogMessage()
                    msg.type = "#ArmorNullify"
                    msg.from = player
                    msg.arg = "renwang_shield"
                    msg.arg2 = effect.slash:objectName()
                    room:sendLog(msg)
                    return true
                end
            elseif player:getMark("&beixin+vine") ~= 0 then
                local effect = data:toSlashEffect()
                if effect.nature == sgs.DamageStruct_Normal then
                    room:setEmotion(player, "armor/vine")
                    local msg = sgs.LogMessage()
                    msg.type = "#ArmorNullify"
                    msg.from = player
                    msg.arg = "vine"
                    msg.arg2 = effect.slash:objectName()
                    room:sendLog(msg)
                    effect.to:setFlags("Global_NonSkillNullify")
                    return true
                end
            end
        elseif event == sgs.CardEffected and player:getMark("&beixin+vine") ~= 0 then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("AOE") then
                room:setEmotion(player, "armor/vine")
                local msg = sgs.LogMessage()
                msg.type = "#ArmorNullify"
                msg.from = player
                msg.arg = "vine"
                msg.arg2 = effect.card:objectName()
                room:sendLog(msg)
                effect.to:setFlags("Global_NonSkillNullify")
                return true
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getMark("&beixin+vine") ~= 0 then
                if damage.nature == sgs.DamageStruct_Fire then
                    room:setEmotion(player, "armor/vineburn")
                    local msg = sgs.LogMessage()
                    msg.type = "#VineDamage"
                    msg.from = player
                    msg.arg = damage.damage
                    msg.arg2 = damage.damage + 1
                    room:sendLog(msg)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            elseif player:getMark("&beixin+silver_lion") ~= 0 then
                room:setEmotion(player, "armor/silver_lion")
                local msg = sgs.LogMessage()
                msg.type = "#SilverLion"
                msg.from = player
                msg.arg = damage.damage
                msg.arg2 = "silver_lion"
                room:sendLog(msg)
                damage.damage = 1
                data:setValue(damage)
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:contains(player) and use.to:length() > 1
                and player:getMark("&beixin+heiguangkai") ~= 0 then
                local msg = sgs.LogMessage()
                msg.type = "#ArmorNullify"
                msg.from = player
                msg.arg = "heiguangkai"
                msg.arg2 = use.card:objectName()
                room:sendLog(msg)
                room:setEmotion(player, "armor/heiguangkai")
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target then
            if target:isAlive() then
                if target:getArmor() == nil then
                    if target:getMark("Armor_Nullified") == 0 and not target:hasFlag("WuqianTarget") then
                        if target:getMark("Equips_Nullified_to_Yourself") == 0 then
                            local list = target:getTag("Qinggang"):toStringList()
                            return #list == 0
                        end
                    end
                end
            end
        end
        return false
    end,
}
Sakamichi:insertRelatedSkills("Luabeixin", "#Luabeixin_Armor")
ToshiakiKasuga:addSkill(Luabeixin)
ToshiakiKasuga:addSkill(Luabeixin_Armor)
-- if not sgs.Sanguosha:getSkill("#Luabeixin_Armor") then SKMC.SkillList:append(Luabeixin_Armor) end

--[[
    技能名：吝啬
    描述：每回合限一次，当其他角色获得你的手牌时，你可以用牌堆顶的等量的牌代替之。
]]
Lualinse = sgs.CreateTriggerSkill {
    name = "Lualinse",
    events = {sgs.BeforeCardsMove, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if move.from and move.to and move.from:objectName() == player:objectName() and player:hasSkill(self)
                and move.from:objectName() ~= move.to:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
                if not player:hasFlag("linse_used") and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setPlayerFlag(player, "linse_used")
                    local toReplace = sgs.IntList()
                    local i = 0
                    if move.card_ids:length() > 0 then
                        for _, id in sgs.qlist(move.card_ids) do
                            if room:getCardOwner(id):objectName() == move.from:objectName() and move.from_places:at(i)
                                == sgs.Player_PlaceHand then
                                toReplace:append(id)
                            end
                            i = i + 1
                        end
                    end
                    for _, p in sgs.qlist(toReplace) do
                        local i = move.card_ids:indexOf(p)
                        if i >= 0 then
                            move.card_ids:removeAt(i)
                            move.from_places:removeAt(i)
                        end
                    end
                    for _, p in sgs.qlist(room:getNCards(toReplace:length())) do
                        move.card_ids:append(p)
                        move.from_places:append(room:getCardPlace(p))
                    end
                    data:setValue(move)
                end
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("linse_used") then
                        room:setPlayerFlag(p, "-linse_used")
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
ToshiakiKasuga:addSkill(Lualinse)

--[[
    技能名：肌肉
    描述：锁定技，你对体力值小于你的角色使用的【杀】造成伤害时，此伤害+1；体力值小于你的角色对你使用的【杀】造成伤害时，此伤害-1。
]]
Luajirou = sgs.CreateTriggerSkill {
    name = "Luajirou",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName()
            and damage.to:hasSkill(self) and player:getHp() < damage.to:getHp() then
            damage.damage = damage.damage - 1
            data:setValue(damage)
            if damage.damage <= 0 then
                return true
            end
        end
        if damage.card and damage.card:isKindOf("Slash") and damage.from:objectName() == player:objectName()
            and player:hasSkill(self) and player:getHp() > damage.to:getHp() then
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ToshiakiKasuga:addSkill(Luajirou)

--[[
    技能名：嘴屁
    描述：出牌阶段限一次，你可以将至多X张手牌置于牌堆底，然后你摸等量的牌（X为你的体力值）。
]]
LuazuipiCard = sgs.CreateSkillCard {
    name = "LuazuipiCard",
    skill_name = "Luazuipi",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local ids = self:getSubcards()
        room:moveCardsToEndOfDrawpile(source, ids, "Luazuipi", false, true)
        room:drawCards(source, ids:length(), "Luazuipi")
    end,
}
Luazuipi = sgs.CreateViewAsSkill {
    name = "Luazuipi",
    n = 999,
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getHp() and not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cd = LuazuipiCard:clone()
            for _, c in ipairs(cards) do
                cd:addSubcard(c)
            end
            cd:setSkillName(self:objectName())
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuazuipiCard")
    end,
}
ToshiakiKasuga:addSkill(Luazuipi)

sgs.LoadTranslationTable {
    ["ToshiakiKasuga"] = "春日 俊彰",
    ["&ToshiakiKasuga"] = "春日 俊彰",
    ["#ToshiakiKasuga"] = "鐵公鷄",
    ["designer:ToshiakiKasuga"] = "Cassimolar",
    ["cv:ToshiakiKasuga"] = "春日 俊彰",
    ["illustrator:ToshiakiKasuga"] = "Cassimolar",
    ["Luabeixin"] = "背心",
    [":Luabeixin"] = "游戏开始时，你获得三枚“背心”；一名角色的回合结束时，若其没有防具，你可以弃置一枚“背心”令其选择并视为装备一种防具直到其下个回合开始。",
    ["Luabeixin:invoke"] = "你可以弃置一枚“背心”令%src选择视为装备一种防具",
    ["@Pink_vest"] = "背心",
    ["beixin"] = "背心",
    ["Lualinse"] = "吝啬",
    [":Lualinse"] = "<b><font color = #008000>每回合限一次</font></b>，当其他角色获得你的手牌时，你可以用牌堆顶等量的牌代替之。",
    ["Luajirou"] = "肌肉",
    [":Luajirou"] = "锁定技，你对体力值小于你的角色使用的【杀】造成伤害时，此伤害+1；体力值小于你的角色对你使用的【杀】造成伤害时，此伤害-1。",
    ["Luazuipi"] = "嘴屁",
    [":Luazuipi"] = "出牌阶段限一次，你可以将至多X张手牌置于牌堆底，然后你摸等量的牌（X为你的体力值）。",
}
