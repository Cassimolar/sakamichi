require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MikuKanemura_Hinatazaka = sgs.General(Sakamichi, "MikuKanemura_Hinatazaka$", "Hinatazaka46", 3, false)
table.insert(SKMC.NiKiSei, "MikuKanemura_Hinatazaka")

--[[
    技能名：忍酸
    描述：出牌阶段，当你使用【杀】时，你可以失去1点体力令此【杀】额外附加一张【酒】，若此【杀】命中，你回复1点体力值并摸一张牌。
]]
Luarensuan = sgs.CreateTriggerSkill {
    name = "Luarensuan",
    events = {sgs.CardUsed, sgs.SlashHit, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
                room:loseHp(player)
                use.card:setTag("drank", sgs.QVariant(use.card:getTag("drank"):toInt() + 1))
                room:setCardFlag(use.card, "rensuan")
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("rensuan") and effect.from:isAlive() then
                if effect.from:isWounded() then
                    room:recover(effect.from, sgs.RecoverStruct(effect.from, effect.slash, 1))
                end
                room:drawCards(effect.from, 1, self:objectName())
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("rensuan") then
                room:setCardFlag(use.card, "-rensuan")
            end
        end
        return false
    end,
}
MikuKanemura_Hinatazaka:addSkill(Luarensuan)

--[[
    技能名：心捕
    描述：摸牌阶段，你可以放弃摸牌并选择等量的其他角色，直到其的下个回合结束，其回复体力时你摸等量的牌，其回合结束时，若你为因此摸牌则你摸两张牌。
]]
LuaxinbuCard = sgs.CreateSkillCard {
    name = "LuaxinbuCard",
    skill_name = "Luaxinbu",
    filter = function(self, targets, to_select)
        return #targets <= sgs.Self:getMark("xinbu") and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        effect.to:setFlags("xinbuTarget")
        effect.to:setFlags("xinbu" .. effect.from:objectName())
        effect.from:setFlags("xinbu_used")
    end,
}
LuaxinbuVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luaxinbu",
    response_pattern = "@@Luaxinbu",
    view_as = function(self)
        return LuaxinbuCard:clone()
    end,
}
Luaxinbu = sgs.CreateTriggerSkill {
    name = "Luaxinbu",
    view_as_skill = LuaxinbuVS,
    events = {sgs.DrawNCards, sgs.HpRecover, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            local n = data:toInt()
            if player:hasSkill(self) then
                local num = math.min(room:getOtherPlayers(player):length(), n)
                if num > 0 then
                    room:setPlayerMark(player, "xinbu", num)
                    room:askForUseCard(player, "@@Luaxinbu", "@xinbu-card:::" .. num)
                    room:setPlayerMark(player, "xinbu", 0)
                    if player:hasFlag("xinbu_used") then
                        data:setValue(0)
                    end
                end
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if player:hasFlag("xinbuTarget") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:hasFlag("xinbu" .. p:objectName()) then
                        room:drawCards(p, recover.recover, self:objectName())
                        if not player:hasFlag("xinbu_recover") then
                            room:setPlayerFlag(player, "xinbu_recover")
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            if player:hasFlag("xinbuTarget") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:hasFlag("xinbu" .. p:objectName()) and not player:hasFlag("xinbu_recover") then
                        room:drawCards(p, 2, self:objectName())
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
MikuKanemura_Hinatazaka:addSkill(Luaxinbu)

--[[
    技能名：嗜发
    描述：其他女性回复体力时，你可以失去1点体力令其一个武将技能失效直到你回复体力值时。
]]
Luashifa = sgs.CreateTriggerSkill {
    name = "Luashifa",
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if player:isFemale() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and not player:getVisibleSkillList():isEmpty() then
                    local skill_List = {}
                    for _, skill in sgs.qlist(player:getVisibleSkillList()) do
                        if player:getMark("&shifa+" .. skill:objectName()) == 0 then
                            table.insert(skill_List, skill:objectName())
                        end
                    end
                    if #skill_List ~= 0
                        and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                        room:loseHp(p)
                        local skill = room:askForChoice(p, self:objectName(), table.concat(skill_List, "+"))
                        room:setPlayerMark(player, "shifa" .. p:objectName(), 1)
                        room:setPlayerMark(player, "shifa" .. p:objectName() .. skill, 1)
                        room:setPlayerMark(player, "&shifa+" .. skill, 1)
                        local msg = sgs.LogMessage()
                        msg.type = "#shifa1"
                        msg.from = p
                        msg.to:append(player)
                        msg.arg = skill
                        msg.arg2 = self:objectName()
                        room:sendLog(msg)
                    end
                end
            end
        end
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getMark("shifa" .. player:objectName()) ~= 0 then
                for _, skill in sgs.qlist(p:getVisibleSkillList()) do
                    if p:getMark("shifa" .. player:objectName() .. skill:objectName()) ~= 0 then
                        room:setPlayerMark(p, "shifa" .. player:objectName() .. skill:objectName(), 0)
                        room:setPlayerMark(p, "&shifa+" .. skill:objectName(), 0)
                        local msg = sgs.LogMessage()
                        msg.type = "#shifa2"
                        msg.from = player
                        msg.to:append(p)
                        msg.arg = skill:objectName()
                        msg.arg2 = self:objectName()
                        room:sendLog(msg)
                    end
                end
                room:setPlayerMark(p, "shifa" .. player:objectName(), 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuashifaInvalidity = sgs.CreateInvaliditySkill {
    name = "#LuashifaInvalidity",
    skill_valid = function(self, player, skill)
        for _, p in sgs.qlist(player:getSiblings()) do
            if player:getMark("shifa" .. p:objectName() .. skill:objectName()) ~= 0 then
                return false
            else
                return true
            end
        end
    end,
}
MikuKanemura_Hinatazaka:addSkill(Luashifa)
if not sgs.Sanguosha:getSkill("#LuashifaInvalidity") then
    SKMC.SkillList:append(LuashifaInvalidity)
end

--[[
    技能名：话说
    描述：主公技，锁定技，你的手牌上限+X（X为场上男性角色数）。
]]
Luahuashuo = sgs.CreateMaxCardsSkill {
    name = "Luahuashuo",
    extra_func = function(self, target)
        if target:hasLordSkill(self) then
            local n = 0
            if target:isMale() then
                n = n + 1
            end
            for _, p in sgs.qlist(target:getAliveSiblings()) do
                if p:isMale() then
                    n = n + 1
                end
            end
            return n
        end
    end,
}
MikuKanemura_Hinatazaka:addSkill(Luahuashuo)

sgs.LoadTranslationTable {
    ["MikuKanemura_Hinatazaka"] = "金村 美玖",
    ["&MikuKanemura_Hinatazaka"] = "金村 美玖",
    ["#MikuKanemura_Hinatazaka"] = "俊俏美顔",
    ["designer:MikuKanemura_Hinatazaka"] = "Cassimolar",
    ["cv:MikuKanemura_Hinatazaka"] = "金村 美玖",
    ["illustrator:MikuKanemura_Hinatazaka"] = "Cassimolar",
    ["Luarensuan"] = "忍酸",
    [":Luarensuan"] = "出牌阶段，当你使用【杀】时，你可以失去1点体力令此【杀】额外附加一张【酒】，若此【杀】命中，你回复1点体力值并摸一张牌。",
    ["Luaxinbu"] = "心捕",
    [":Luaxinbu"] = "摸牌阶段，你可以放弃摸牌并选择至多等量的其他角色，直到其的下个回合结束，其回复体力时你摸等量的牌，其回合结束时，若你为因此摸牌则你摸两张牌。",
    ["@xinbu-card"] = "你可以发动【心捕】选择至多%arg名其他角色",
    ["Luashifa"] = "嗜发",
    [":Luashifa"] = "其他女性回复体力时，你可以失去1点体力令其一个武将技能失效直到你回复体力值时。",
    ["Luashifa:invoke"] = "是否失去1点体力令%src的一个技能失效",
    ["#shifa1"] = "%from发动了【%arg2】令%to的【%arg】失效",
    ["#shifa2"] = "%from因回复体力发动了【%arg2】令%to的【%arg】恢复",
    ["shifa"] = "嗜发",
    ["Luahuashuo"] = "话说",
    [":Luahuashuo"] = "主公技，锁定技，你的手牌上限+X（X为场上男性角色数）。",
}
