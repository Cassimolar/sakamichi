require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ShihoKato_Hinatazaka = sgs.General(Sakamichi, "ShihoKato_Hinatazaka$", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "ShihoKato_Hinatazaka")

--[[
    技能名：似顔絵
    描述：每回合限一次，当一名其他角色使用的基本牌或通常锦囊牌结算完成时，你可以弃置一张与此牌类型、花色、点数均不相同的手牌，若如此做，你将此牌置于你的武将牌旁成为“絵”，“絵”可以视为手牌使用或打出。
]]
Luanigaoe = sgs.CreateTriggerSkill {
    name = "Luanigaoe",
    events = {sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard")
                and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
                if not use.card:isVirtualCard()
                    or (use.card:getSubcards():length() > 0 and room:getCardPlace(use.card:getEffectiveId())
                        == sgs.Player_PlaceTable) then
                    local suit = use.card:getSuitString()
                    local num = use.card:getNumber()
                    local type
                    if use.card:isNDTrick() then
                        type = "TrickCard"
                    else
                        type = "BasicCard"
                    end
                    local number = {"A", "1", "2", "3", "4", "5", "6", "7", "8", "9", "J", "Q", "K"}
                    table.removeOne(number, num)
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if not p:hasFlag("nigaoe_used") and not p:isKongcheng() and p:objectName() ~= player:objectName() then
                            local card = room:askForCard(p, "^" .. type .. "|^" .. suit .. "|"
                                .. table.concat(number, ",") .. "|hand", "@nigaoe_invoke:::" .. use.card:objectName(),
                                data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false, nil)
                            if card then
                                p:addToPile("&nigaoe", use.card)
                                room:setPlayerFlag(p, "nigaoe_used")
                            end
                        end
                    end
                end
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("nigaoe_used") then
                        room:setPlayerFlag(p, "-nigaoe_used")
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
ShihoKato_Hinatazaka:addSkill(Luanigaoe)

--[[
    技能名：剪辑
    描述：锁定技，判定阶段开始时，若你的判定区有牌，你获得其中所有的牌，若你以此法获得的实体牌中有：【兵粮寸断】/【乐不思蜀】，你跳过摸牌/出牌阶段。
]]
Luajianji = sgs.CreateTriggerSkill {
    name = "Luajianji",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Judge and not player:getJudgingArea():isEmpty() then
            local move = sgs.CardsMoveStruct()
            for _, card in sgs.qlist(player:getJudgingArea()) do
                if sgs.Sanguosha:getEngineCard(card:getEffectiveId()):objectName() == "supply_shortage" then
                    player:skip(sgs.Player_Draw)
                end
                if sgs.Sanguosha:getEngineCard(card:getEffectiveId()):objectName() == "indulgence" then
                    player:skip(sgs.Player_Play)
                end
                move.card_ids:append(card:getEffectiveId())
            end
            local msg = sgs.LogMessage()
            msg.type = "#jianjiGot"
            msg.from = player
            msg.card_str = table.concat(sgs.QList2Table(move.card_ids), "+")
            room:sendLog(msg)
            move.to = player
            move.to_place = sgs.Player_PlaceHand
            room:moveCardsAtomic(move, true)
        end
        return false
    end,
}
ShihoKato_Hinatazaka:addSkill(Luajianji)

--[[
    技能名：痴狂
    描述：锁定技，当你造成伤害/回复时，若目标与你上次造成伤害/回复的目标相同，你令此次伤害/回复量+1。
]]
Luachikuang = sgs.CreateTriggerSkill {
    name = "Luachikuang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused, sgs.Damage, sgs.PreHpRecover, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if player:hasSkill(self) and damage.to:getMark("chikuang_damage" .. player:objectName()) ~= 0 then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to and damage.damage > 0 and player:hasSkill(self) then
                for _, p in sgs.qlist(room:getAllPlayers(true)) do
                    room:setPlayerMark(p, "chikuang_damage" .. player:objectName(), 0)
                end
                if damage.to:isAlive() then
                    room:setPlayerMark(damage.to, "chikuang_damage" .. player:objectName(), 1)
                end
            end
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:hasSkill(self)
                and player:getMark("chikuang_recover" .. recover.who:objectName()) ~= 0 then
                recover.recover = recover.recover + 1
                data:setValue(recover)
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:hasSkill(self) then
                for _, p in sgs.qlist(room:getAllPlayers(true)) do
                    room:setPlayerMark(p, "chikuang_recover" .. recover.who:objectName(), 0)
                end
                if player:isAlive() then
                    room:setPlayerMark(player, "chikuang_recover" .. recover.who:objectName(), 1)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ShihoKato_Hinatazaka:addSkill(Luachikuang)

--[[
    技能名：最强
    描述：主公技，当你对其他角色造成伤害后，其他“けやき坂46”和“日向坂46”势力的角色可以交给你一张牌。
]]
Luazuiqiang = sgs.CreateTriggerSkill {
    name = "Luazuiqiang$",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to and damage.to:objectName() ~= player:objectName() then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == "HiraganaKeyakizaka46" or p:getKingdom() == "Hinatazaka46" then
                    local card = room:askForCard(p, ".|.|.|hand,equipped", "@zuiqiang_give:" .. player:objectName(),
                        data, sgs.Card_MethodNone)
                    if card then
                        player:obtainCard(card)
                    end
                end
            end
        end
        return false
    end,
}
ShihoKato_Hinatazaka:addSkill(Luazuiqiang)

sgs.LoadTranslationTable {
    ["ShihoKato_Hinatazaka"] = "加藤 史帆",
    ["&ShihoKato_Hinatazaka"] = "加藤 史帆",
    ["#ShihoKato_Hinatazaka"] = "剪輯女王",
    ["designer:ShihoKato_Hinatazaka"] = "Cassimolar",
    ["cv:ShihoKato_Hinatazaka"] = "加藤 史帆",
    ["illustrator:ShihoKato_Hinatazaka"] = "Cassimolar",
    ["Luanigaoe"] = "似顔絵",
    [":Luanigaoe"] = "<b><font color = #008000>每回合限一次</font></b>，当一名其他角色使用的基本牌或通常锦囊牌结算完成时，你可以弃置一张与此牌类型、花色、点数均不相同的手牌，若如此做，你将此牌置于你的武将牌旁成为“絵”，“絵”可以视为手牌使用或打出。",
    ["@nigaoe_invoke"] = "你可以弃置一张与此【%arg】类型、花色、点数均不相同的手牌来将此牌置入你的“絵”",
    ["&nigaoe"] = "絵",
    ["Luajianji"] = "剪辑",
    [":Luajianji"] = "锁定技，判定阶段开始时，若你的判定区有牌，你获得其中所有的牌，若你以此法获得的实体牌中有：【兵粮寸断】/【乐不思蜀】，你跳过摸牌/出牌阶段。",
    ["#jianjiGot"] = "%from 获得其判定区内所有牌：%card",
    ["Luachikuang"] = "痴狂",
    [":Luachikuang"] = "锁定技，当你造成伤害/回复时，若目标与你上次造成伤害/回复的目标相同，你令此次伤害/回复量+1。",
    ["Luazuiqiang"] = "最强",
    [":Luazuiqiang"] = "主公技，当你对其他角色造成伤害后，其他“けやき坂46”和“日向坂46”势力的角色可以交给你一张牌。",
    ["@zuiqiang_give"] = "你可以交给%src一张牌",
}
