require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ErikaSouda = sgs.General(Sakamichi, "ErikaSouda", "AutisticGroup", 4, false)
table.insert(SKMC.IKiSei, "ErikaSouda")

--[[
    技能名：花子
    描述：出牌阶段限一次，你可以弃置任意张牌并选择等量的角色，令其随机躲入五间厕所隔间里的随机一间，然后每间隔间分别有以下效果：第一间隔间，你令其流失1点体力，然后其摸两张牌；第二件隔间，你令其回复1点体力然后你弃置其2张牌；第三间隔间，你对其分别造成1点普通伤害，1点火焰伤害，1点雷电伤害；第四间隔间，你令其武将牌翻面，然后其可以弃置其区域内所有的牌并摸取等量的牌；第五间隔间，你摸取等同于其已损失体力值的牌，然后若你手牌不少于其，其也可以如此做。你始终可以选择你躲藏的隔间。
]]
-- ! 出牌阶段限一次，你可以令一名其他角色进行一次判定，若判定结果为3的倍数，你分别对其造成1点普通伤害，1点火焰伤害，1点雷电伤害。
--[[
LuahuaziCard = sgs.CreateSkillCard{
    name = "LuahuaziCard",
    skill_name = "Luahuazi",
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local judge = sgs.JudgeStruct()
        judge.pattern = ".|.|3, 6, 9, 12"
        judge.good = false
        judge.negative = true
        judge.reason = "Luahuazi"
        judge.who = effect.to
        room:judge(judge)
        if judge:isBad() then
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Normal))
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Fire))
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Thunder))
        end
    end
}
Luahuazi = sgs.CreateZeroCardViewAsSkill{
    name = "Luahuazi",
    view_as = function()
        return LuahuaziCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuahuaziCard")
    end
}
]]
-- ! 出牌阶段限一次，你可以弃置X张牌并选择X名其他角色，分别令其选择受到来自你的1点普通伤害，1点火焰伤害，1点雷电伤害或躲到三个厕所隔间中的随机一个；锁定技，回合结束时，你杀死所有躲在第三间厕所隔间里的角色。
--[[
LuahuaziCard = sgs.CreateSkillCard{
    name = "LuahuaziCard",
    skill_name = "Luahuazi",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets ~= self:subcardsLength()
    end,
    feasible = function(self, targets)
        return #targets == self:subcardsLength()
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        local choice = room:askForChoice(effect.to, "Luahuazi", "damage+hidden")
        if choice == "damage" then
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Normal))
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Fire))
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Thunder))
        else
            local x = math.random(1, 3)
            if x == 3 then
                local msg = sgs.LogMessage()
                msg.type = "#huazi_3"
                msg.from = effect.to
                room:sendLog(msg)
                room:setPlayerFlag(effect.to, "huazi_death")
            else
                local msg = sgs.LogMessage()
                msg.type = "#huazi_12"
                msg.from = effect.to
                if x == 1 then
                    msg.arg = "first_Compartment"
                else
                    msg.arg = "second_Compartment"
                end
                room:sendLog(msg)
            end
        end
    end
}
LuahuaziVS = sgs.CreateViewAsSkill{
    name = "Luahuazi",
    n = 999,
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local huaziVS_card = LuahuaziCard:clone()
            for _, card in pairs(cards) do
                huaziVS_card:addSubcard(card)
            end
            huaziVS_card:setSkillName(self:objectName())
            return huaziVS_card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuahuaziCard")
    end
}
Luahuazi = sgs.CreateTriggerSkill{
    name = "Luahuazi",
    view_as_skill = LuahuaziVS,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("huazi_death") then
                    local msg = sgs.LogMessage()
                    msg.type = "#huazi_death"
                    msg.from = player
                    msg.to:append(p)
                    room:sendLog(msg)
                    local killer = sgs.DamageStruct()
                    killer.from = player
                    room:killPlayer(p, killer)
                end
            end
        end
        return false
    end
}
]]
-- ! 出牌阶段限一次，你可以弃置任意张牌并选择等量的角色，令其随机躲入五间厕所隔间里的随机一间，然后每间隔间分别有以下效果：第一间隔间，你令其流失1点体力，然后其摸两张牌；第二件隔间，你令其回复1点体力然后你弃置其2张牌；第三间隔间，你对其分别造成1点普通伤害，1点火焰伤害，1点雷电伤害；第四间隔间，你令其武将牌翻面，然后其可以弃置其区域内所有的牌并摸取等量的牌；第五间隔间，你摸取等同于其已损失体力值的牌，然后若你手牌不少于其，其也可以如此做。锁定技，你始终可以选择你躲藏的隔间。
--[[
LuahuaziCard = sgs.CreateSkillCard{
    name = "LuahuaziCard",
    skill_name = "Luahuazi",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets ~= self:subcardsLength()
    end,
    feasible = function(self, targets)
        return #targets == self:subcardsLength()
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        if effect.to:objectName() == effect.from:objectName() then
            toilet = room:askForChoice(effect.to, "Luahuazi", "first_Compartment+second_Compartment+third_Compartment+fourth_Compartment+fifth_Compartment")
        else
            local x = math.random(1, 5)
            if x == 1 then
                toilet = "first_Compartment"
            elseif x == 2 then
                toilet = "second_Compartment"
            elseif x == 3 then
                toilet = "third_Compartment"
            elseif x == 4 then
                toilet = "fourth_Compartment"
            elseif x == 5 then
                toilet = "fifth_Compartment"
            end
        end
        local msg = sgs.LogMessage()
        msg.type = "#huazi_type"
        msg.from = effect.to
        msg.arg = toilet
        room:sendLog(msg)
        if toilet == "first_Compartment" then
            room:loseHp(effect.to)
            effect.to:drawCards(2)
        elseif toilet == "second_Compartment" then
            room:recover(effect.to, sgs.RecoverStruct(effect.from))
            for i = 1, 2, 1 do
                if not effect.to:isAllNude() then
                    local id = room:askForCardChosen(effect.from, effect.to, "hej", "Luahuazi", false, sgs.Card_MethodDiscard)
                    room:throwCard(id, effect.to, effect.from)
                end
            end
        elseif toilet == "third_Compartment" then
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Normal))
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Fire))
            room:damage(sgs.DamageStruct("Luahuazi", effect.from, effect.to, 1, sgs.DamageStruct_Thunder))
        elseif toilet == "fourth_Compartment" then
            effect.to:turnOver()
            if effect.to:askForSkillInvoke("Luahuazi", sgs.QVariant("throwAnddraw")) then
                local m = effect.to:getCards("hej"):length()
                effect.to:throwAllCards()
                effect.to:drawCards(m)
            end
        elseif toilet == "fifth_Compartment" then
            local n = effect.to:getLostHp()
            effect.from:drawCards(n)
            if effect.from:getHandcardNum() >= effect.to:getHandcardNum() then
                if effect.to:askForSkillInvoke("Luahuazi", sgs.QVariant("drawcards:"..effect.to:objectName())) then
                    effect.to:drawCards(n)
                end
            end
        end
    end
}
Luahuazi = sgs.CreateViewAsSkill{
    name = "Luahuazi",
    n = 999,
    view_filter = function(self, selected, to_select)
        return #selected < (sgs.Self:getAliveSiblings():length() + 1)
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local huaziVS_card = LuahuaziCard:clone()
            for _, card in pairs(cards) do
                huaziVS_card:addSubcard(card)
            end
            huaziVS_card:setSkillName(self:objectName())
            return huaziVS_card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuahuaziCard")
    end
}
]]
-- ! 锁定技，当你使用牌时，目标和你须从三个隔间中选择一个，然后与你同一隔间的其他角色无法使用或打出手牌直到此牌结算完毕，若此隔间是第三个隔间则你额外对同隔间的其他角色造成1点普通伤害、1点火焰伤害、1点雷电伤害，然后选择第三间隔间的角色选择回复1点体力值或摸一张牌。
Luahuazi = sgs.CreateTriggerSkill {
    name = "Luahuazi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed and not use.card:isKindOf("SkillCard") and use.from:objectName() == player:objectName() then
            room:setCardFlag(use.card, "huazi")
            local first_Compartment, second_Compartment, third_Compartment = sgs.SPlayerList(), sgs.SPlayerList(),
                sgs.SPlayerList()
            for _, p in sgs.qlist(use.to) do
                if p:objectName() ~= player:objectName() then
                    local choice1 = room:askForChoice(p, self:objectName(),
                        "first_Compartment+second_Compartment+third_Compartment")
                    if choice1 == "first_Compartment" then
                        first_Compartment:append(p)
                    elseif choice1 == "second_Compartment" then
                        second_Compartment:append(p)
                    else
                        third_Compartment:append(p)
                    end
                end
            end
            local choice2 = room:askForChoice(player, self:objectName(),
                "first_Compartment+second_Compartment+third_Compartment")
            if choice2 == "first_Compartment" then
                if not first_Compartment:isEmpty() then
                    local msg = sgs.LogMessage()
                    msg.type = "#huazi_first_Compartment"
                    msg.from = use.from
                    msg.arg = choice2
                    msg.arg2 = use.card:objectName()
                    msg.to = first_Compartment
                    room:sendLog(msg)
                    for _, p in sgs.qlist(first_Compartment) do
                        room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
                        room:addPlayerMark(p, "huazi")
                    end
                else
                    local msg = sgs.LogMessage()
                    msg.type = "#huaziEmpty"
                    msg.from = use.from
                    msg.arg = choice2
                    room:sendLog(msg)
                end
            elseif choice2 == "second_Compartment" then
                if not second_Compartment:isEmpty() then
                    local msg = sgs.LogMessage()
                    msg.type = "#huazi_second_Compartment"
                    msg.from = use.from
                    msg.arg = choice2
                    msg.arg2 = use.card:objectName()
                    msg.to = second_Compartment
                    room:sendLog(msg)
                    for _, p in sgs.qlist(second_Compartment) do
                        room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
                        room:addPlayerMark(p, "huazi")
                    end
                else
                    local msg = sgs.LogMessage()
                    msg.type = "#huaziEmpty"
                    msg.from = use.from
                    msg.arg = choice2
                    room:sendLog(msg)
                end
            else
                if not third_Compartment:isEmpty() then
                    local msg = sgs.LogMessage()
                    msg.type = "#huazi_third_Compartment"
                    msg.from = use.from
                    msg.arg = choice2
                    msg.arg2 = use.card:objectName()
                    msg.to = third_Compartment
                    room:sendLog(msg)
                    for _, p in sgs.qlist(third_Compartment) do
                        room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
                        room:addPlayerMark(p, "huazi")
                        room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Normal))
                        room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Fire))
                        room:damage(sgs.DamageStruct(self:objectName(), player, p, 1, sgs.DamageStruct_Thunder))
                    end
                else
                    local msg = sgs.LogMessage()
                    msg.type = "#huaziEmpty"
                    msg.from = use.from
                    msg.arg = choice2
                    room:sendLog(msg)
                end
                third_Compartment:append(player)
            end
            for _, p in sgs.qlist(third_Compartment) do
                if p:isWounded() and room:askForChoice(p, self:objectName(), "recover+draw") == "recover" then
                    room:recover(p, sgs.RecoverStruct(player, use.card, 1))
                else
                    room:drawCards(p, 1, self:objectName())
                end
            end
        elseif event == sgs.CardFinished and use.card:hasFlag("huazi") then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("huazi") ~= 0 then
                    room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand$0")
                    room:setPlayerMark(p, "huazi", 0)
                end
            end
        end
        return false
    end,
}
ErikaSouda:addSkill(Luahuazi)

--[[
    技能名：甄选
    描述：觉醒技，回合开始时，若你已受伤且手牌数大于体力值，并且场上不存在「霸王 - 生田 絵梨花」且当前主公势力为一期生，你减1点体力上限，然后获得【下厨】和【芬兰民谣】。
]]
Luazhenxuan = sgs.CreateTriggerSkill {
    name = "Luazhenxuan",
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 then
            local lord = room:getLord()
            local nothaserika = true
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getGeneral() == "ErikaIkuta" or p:getGeneral2Name() == "ErikaIkuta" then
                    nothaserika = false
                    break
                end
            end
            if lord then
                if lord:getKingdom() == "first" and nothaserika then
                    player:addMark(self:objectName())
                    room:changeMaxHpForAwakenSkill(player)
                    room:handleAcquireDetachSkills(player, "sakamichi_xia_chu|sakamichi_fen_lan_min_yao")
                end
            end
        end
        return false
    end,
}
ErikaSouda:addSkill(Luazhenxuan)

sgs.LoadTranslationTable {
    ["ErikaSouda"] = "池上 花衣",
    ["&ErikaSouda"] = "池上 花衣",
    ["#ErikaSouda"] = "鬼娃娃",
    ["designer:ErikaSouda"] = "Cassimolar",
    ["cv:ErikaSouda"] = "生田 絵梨花",
    ["illustrator:ErikaSouda"] = "Cassimolar",
    ["Luahuazi"] = "花子",
    --	[":Luahuazi"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，若判定结果为3的倍数，你分别对其造成1点普通伤害，1点火焰伤害，1点雷电伤害。",
    --	[":Luahuazi"] = "出牌阶段限一次，你可以弃置X张牌并选择X名其他角色，分别令其选择受到来自你的1点普通伤害，1点火焰伤害，1点雷电伤害或躲到三个厕所隔间中的随机一个；锁定技，回合结束时，你杀死所有躲在第三间厕所隔间里的角色。",
    --	["Luahuazi:damage"] = "正面承受伤害",
    --	["Luahuazi:hidden"] = "试图躲起来",
    ["first_Compartment"] = "第一间隔间",
    ["second_Compartment"] = "第二间隔间",
    ["third_Compartment"] = "第三间隔间",
    ["fourth_Compartment"] = "第四间隔间",
    ["fifth_Compartment"] = "第五间隔间",
    --	["#huazi_12"] = "%from 躲到了%arg ，%from 安全了",
    --	["#huazi_3"] = "%from 躲到了<font color=\"yellow\"><b>第三间隔间</b></font>，%from 已经是一个死人了",
    --	["#huazi_death"] = "%to 躲在<font color=\"yellow\"><b>第三间隔间</b></font>被 %from 发现了",
    --	[":Luahuazi"] = "出牌阶段限一次，你可以弃置任意张牌并选择等量的角色，令其随机躲入五间厕所隔间里的随机一间，然后每间隔间分别有以下效果：第一间隔间，你令其流失1点体力，然后其摸两张牌；第二件隔间，你令其回复1点体力然后你弃置其2张牌；第三间隔间，你对其分别造成1点普通伤害，1点火焰伤害，1点雷电伤害；第四间隔间，你令其武将牌翻面，然后其可以弃置其区域内所有的牌并摸取等量的牌；第五间隔间，你摸取等同于其已损失体力值的牌，然后若你手牌不少于其，其也可以如此做。你始终可以选择你躲藏的隔间。",
    [":Luahuazi"] = "锁定技，当你使用牌时，目标和你须从三个隔间中选择一个，然后与你同一隔间的其他角色无法使用或打出手牌直到此牌结算完毕，若此隔间是第三个隔间则你额外对同隔间的其他角色造成1点普通伤害、1点火焰伤害、1点雷电伤害，然后选择第三间隔间的角色选择回复1点体力值或摸一张牌。",
    ["Luahuazi:recover"] = "回复1点体力",
    ["Luahuazi:draw"] = "摸一张牌",
    ["#huaziEmpty"] = "%from 选择了%arg，但是%arg里并没有其他角色，%from 扑空了。",
    ["#huazi_first_Compartment"] = "%from 选择了%arg，%arg里的%to 直到%arg2结算完毕无法使用或打出手牌",
    ["#huazi_second_Compartment"] = "%from 选择了%arg，%arg里的%to 直到%arg2结算完毕无法使用或打出手牌",
    ["#huazi_third_Compartment"] = "%from 选择了%arg，%arg里的%to 直到%arg2结算完毕无法使用或打出手牌，且将受到1点普通伤害、1点火焰伤害、1点雷电伤害",
    ["#huazi_type"] = "%from 躲到了%arg",
    ["Luahuazi:throwAnddraw"] = "是否选择弃置区域内的所有牌并摸取等量的牌",
    ["Luahuazi:drawcards"] = "是否摸取等同于%src 已损失体力值的牌",
    ["Luazhenxuan"] = "甄选",
    [":Luazhenxuan"] = "觉醒技，回合开始时，若你已受伤且手牌数大于体力值，并且场上不存在「霸王 - 生田 絵梨花」且当前主公势力为一期生，你减1点体力上限，然后获得【下厨】和【芬兰民谣】。",
}
