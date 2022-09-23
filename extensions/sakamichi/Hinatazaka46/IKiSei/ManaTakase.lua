require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManaTakase_Hinatazaka = sgs.General(Sakamichi, "ManaTakase_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "ManaTakase_Hinatazaka")

--[[
    技能名：吐槽
    描述：每名角色回合限一次，当一名角色造成伤害时，你可以进行一次判定，若结果为：黑色，你对其造成1点伤害并摸一张牌；红色，你须交给其一张手牌或失去1点体力。
]]
Luatucao = sgs.CreateTriggerSkill {
    name = "Luatucao",
    events = {sgs.EventPhaseEnd, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.from:isAlive() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:hasFlag("tucao_used") and room:askForSkillInvoke(p, self:objectName(), data) then
                        room:setPlayerFlag(p, "tucao_used")
                        local judge = sgs.JudgeStruct()
                        judge.pattern = ".|black"
                        judge.good = true
                        judge.reason = self:objectName()
                        judge.who = p
                        room:judge(judge)
                        if judge:isGood() then
                            room:damage(sgs.DamageStruct(self:objectName(), p, damage.from, 1))
                            room:drawCards(p, 1, self:objectName())
                        else
                            if p:isKongcheng() then
                                room:loseHp(p)
                            else
                                local card = room:askForCard(p, ".|.|.|hand",
                                    "@tucao_give:" .. damage.from:objectName(), data, sgs.Card_MethodNone)
                                if card then
                                    room:obtainCard(damage.from, card, false)
                                else
                                    room:loseHp(p)
                                end
                            end
                        end
                    end
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("tucao_used") then
                    room:setPlayerFlag(p, "-tucao_used")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ManaTakase_Hinatazaka:addSkill(Luatucao)

--[[
    技能名：毒舌
    描述：其他角色于你的回合外获得你的手牌时，若其手牌数多于你，你可以令其一个技能本回合内失效。
]]
Luadushe = sgs.CreateTriggerSkill {
    name = "Luadushe",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.to and move.from:objectName() == player:objectName() and player:hasSkill(self)
                and player:getPhase() == sgs.Player_NotActive and move.from:objectName() ~= move.to:objectName()
                and move.from_places:contains(sgs.Player_PlaceHand) then
                if player:getHandcardNum() < move.to:getHandcardNum() then
                    if move.to:getVisibleSkillList():length() ~= 0
                        and room:askForSkillInvoke(player, self:objectName(), data) then
                        local skill_List = {}
                        for _, skill in sgs.qlist(move.to:getVisibleSkillList()) do
                            table.insert(skill_List, skill:objectName())
                        end
                        local skill = room:askForChoice(player, self:objectName(), table.concat(skill_List, "+"))
                        local target
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            if p:objectName() == move.to:objectName() then
                                target = p
                            end
                        end
                        room:setPlayerFlag(target, "dushe" .. skill)
                        local msg = sgs.LogMessage()
                        msg.type = "#dushe"
                        msg.from = player
                        msg.to:append(target)
                        msg.arg = skill
                        msg.arg2 = self:objectName()
                        room:sendLog(msg)
                    end
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                for _, skill in sgs.qlist(p:getVisibleSkillList()) do
                    if p:hasFlag("dushe" .. skill:objectName()) then
                        room:setPlayerFlag(p, "-dushe" .. skill:objectName())
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
LuadusheInvalidity = sgs.CreateInvaliditySkill {
    name = "#LuadusheInvalidity",
    skill_valid = function(self, player, skill)
        if player:hasFlag("dushe" .. skill:objectName()) then
            return false
        else
            return true
        end
    end,
}
ManaTakase_Hinatazaka:addSkill(Luadushe)
if not sgs.Sanguosha:getSkill("#LuadusheInvalidity") then
    SKMC.SkillList:append(LuadusheInvalidity)
end

--[[
    技能名：无人机
    描述：出牌阶段限一次，你可以观看一名其他角色的手牌；限定技，出牌阶段结束时，你可以弃置至多三张♥手牌并失去此技能，然后选择一名其他角色对其造成等量的火焰伤害，然后顺时针和逆时针开始分别对其他角色造成上一名角色以此法受到伤害量-1的火焰伤害直至为0，若你以此法杀死一名角色，在其身份牌翻开后，若其身份不为[反贼]，你无法对其他角色使用牌直至你下次进入濒死。
]]
LuaUAVCard = sgs.CreateSkillCard {
    name = "LuaUAVCard",
    skill_name = "LuaUAV",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:showAllCards(effect.to, effect.from)
    end,
}
LuaUAVVS = sgs.CreateZeroCardViewAsSkill {
    name = "LuaUAV",
    view_as = function()
        return LuaUAVCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuaUAVCard")
    end,
}
LuaUAV = sgs.CreateTriggerSkill {
    name = "LuaUAV",
    view_as_skill = LuaUAVVS,
    frequency = sgs.Skill_Limited,
    limit_mark = "@Boom",
    events = {sgs.EventPhaseEnd, sgs.EnterDying, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:hasSkill(self) and player:getPhase() == sgs.Player_Play
            and player:getMark("@Boom") ~= 0 then
            local card = room:askForExchange(player, self:objectName(), 3, 1, false, "@UAV_discard", true, ".|heart")
            if card then
                player:loseMark("@Boom")
                room:setPlayerMark(player, "UAV_has", 1)
                local n = card:getSubcards():length()
                room:throwCard(card, player, player)
                room:handleAcquireDetachSkills(player, "-LuaUAV")
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@UAV_choice:::" .. n, false, false)
                room:damage(sgs.DamageStruct(self:objectName(), player, target, n, sgs.DamageStruct_Fire))
                if n > 1 then
                    local last, next
                    next = target:getNextAlive()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if p:getNext():objectName() == target:objectName() then
                            last = p
                        end
                    end
                    room:damage(sgs.DamageStruct(self:objectName(), player, last, n - 1, sgs.DamageStruct_Fire))
                    room:damage(sgs.DamageStruct(self:objectName(), player, next, n - 1, sgs.DamageStruct_Fire))
                    if n - 1 > 1 then
                        next = next:getNextAlive()
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if p:getNext():objectName() == last:objectName() then
                                last = p
                            end
                        end
                        room:damage(sgs.DamageStruct(self:objectName(), player, last, n - 2, sgs.DamageStruct_Fire))
                        room:damage(sgs.DamageStruct(self:objectName(), player, next, n - 2, sgs.DamageStruct_Fire))
                    end
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.reason == self:objectName() and death.damage.from
                and death.damage.from:objectName() == player:objectName() and player:getMark("UAV_has") ~= 0 then
                if death.who:getRole() ~= "rebel" then
                    room:setPlayerMark(player, "UAC_offense", 1)
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and player:getMark("UAV_has") ~= 0 then
                room:setPlayerMark(player, "UAC_offense", 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuaUAVProhibit = sgs.CreateProhibitSkill {
    name = "#LuaUAVProhibit",
    is_prohibited = function(self, from, to, card)
        return not card:isKindOf("SkillCard") and from:objectName() ~= to:objectName() and from:getMark("UAC_offense")
                   ~= 0
    end,
}
ManaTakase_Hinatazaka:addSkill(LuaUAV)
if not sgs.Sanguosha:getSkill("#LuaUAVProhibit") then
    SKMC.SkillList:append(LuaUAVProhibit)
end

sgs.LoadTranslationTable {
    ["ManaTakase_Hinatazaka"] = "高瀬愛奈",
    ["&ManaTakase_Hinatazaka"] = "高瀬愛奈",
    ["#ManaTakase_Hinatazaka"] = "最終兵器",
    ["designer:ManaTakase_Hinatazaka"] = "Cassimolar",
    ["cv:ManaTakase_Hinatazaka"] = "高瀬愛奈",
    ["illustrator:ManaTakase_Hinatazaka"] = "Cassimolar",
    ["Luatucao"] = "吐槽",
    [":Luatucao"] = "每名角色回合限一次，当一名角色造成伤害时，你可以进行一次判定，若结果为：黑色，你对其造成1点伤害并摸一张牌；红色，你须交给其一张手牌或失去1点体力。",
    ["@tucao_give"] = "你须交给%src一张手牌，否则失去1点体力",
    ["Luadushe"] = "毒舌",
    [":Luadushe"] = "其他角色于你的回合外获得你的手牌时，若其手牌数多于你，你可以令其一个技能本回合内失效。",
    ["#dushe"] = "%from发动了【%arg2】令%to的【%arg】本回合内失效",
    ["LuaUAV"] = "无人机",
    [":LuaUAV"] = "出牌阶段限一次，你可以观看一名其他角色的手牌；限定技，出牌阶段结束时，你可以弃置至多三张♥手牌并失去此技能，然后选择一名其他角色对其造成等量的火焰伤害，然后顺时针和逆时针开始分别对其他角色造成上一名角色以此法受到伤害量-1的火焰伤害直至为0，若你以此法杀死一名角色，在其身份牌翻开后，若其身份不为[反贼]，你无法对其他角色使用牌直至你下次进入濒死。",
    ["@Boom"] = "空中打击",
    ["@UAV_discard"] = "你可以弃置至多三张红桃牌发动空中打击",
    ["@UAV_choice"] = "选择一名其他角色对其造成%arg点火焰伤害",
}
