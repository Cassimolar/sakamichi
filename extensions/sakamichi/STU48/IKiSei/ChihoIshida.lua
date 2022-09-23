require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ChihoIshida = sgs.General(STU48, "ChihoIshida$", "STU48", 3, false)
table.insert(SKMC.IKiSei, "ChihoIshida")

--[[
    技能名：转嫁
    描述：你使用基本牌和锦囊牌前，你可以选择一名其他角色，令其成为此牌的使用者，其他角色以此法杀死一名角色后，你摸三张牌。
]]
Luazhuanjia = sgs.CreateTriggerSkill {
    name = "Luazhuanjia",
    events = {sgs.PreCardUsed, sgs.CardFinished, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and use.from:objectName()
                == player:objectName() and player:hasSkill(self) then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@zhuanjia_invoke:::" .. use.card:objectName(), true, true)
                if target then
                    use.from = target
                    room:setCardFlag(use.card, player:objectName() .. "zhuanjia")
                    data:setValue(use)
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if use.card:hasFlag(p:objectName() .. "zhuanjia") then
                    room:setCardFlag(use.card, "-" .. p:objectName() .. "zhuanjia")
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if death.damage.card and death.damage.card:hasFlag(p:objectName() .. "zhuanjia") then
                        room:drawCards(p, 3, self:objectName())
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
ChihoIshida:addSkill(Luazhuanjia)

--[[
    技能名：觊觎
    描述：当其他角色使用牌时，若目标唯一且不为你，你可以交给目标一张类型相同的手牌来代替其成为此牌唯一目标。
]]
Luajiyu = sgs.CreateTriggerSkill {
    name = "Luajiyu",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if not use.card:isKindOf("SkillCard") and use.to:length() == 1 and not use.to:contains(p)
                and use.from:objectName() ~= p:objectName() then
                local pattern
                if use.card:isKindOf("BasicCard") then
                    pattern = "BasicCard"
                elseif use.card:isKindOf("TrickCard") then
                    pattern = "TrickCard"
                elseif use.card:isKindOf("EquipCard") then
                    pattern = "EquipCard"
                end
                local pa = pattern
                pattern = string.format("%s|.|.|hand", pattern)
                local card = room:askForCard(p, pattern,
                    "@jiyu_give:" .. use.to:first():objectName() .. ":" .. pa .. ":" .. use.card:objectName(), data,
                    sgs.Card_MethodNone)
                if card then
                    use.to:first():obtainCard(card)
                    use.to:removeOne(use.to:first())
                    use.to:append(p)
                    data:setValue(use)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ChihoIshida:addSkill(Luajiyu)

--[[
    技能名：夺位
    描述：限定技，出牌阶段开始时，若你不是主公且当前主公有主公技，且其体力值不大于你，你可以获得其的主公技，然后其失去该主公技；你死亡时，其重新获得该主公技。
]]
Luaduowei = sgs.CreateTriggerSkill {
    name = "Luaduowei",
    events = {sgs.EventPhaseStart, sgs.Death},
    frequency = sgs.Skill_Limited,
    limit_mark = "@duowei",
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:getRole() ~= "lord" then
            local lord = room:getLord()
            local lord_skills = {}
            local lose_skills = {}
            for _, skill in sgs.qlist(lord:getGeneral():getVisibleSkillList()) do
                if skill:isLordSkill() and lord:hasLordSkill(skill:objectName()) then
                    table.insert(lord_skills, skill:objectName())
                    table.insert(lose_skills, "-" .. skill:objectName())
                end
            end
            if lord:getGeneral2() then
                for _, skill in sgs.qlist(lord:getGeneral2():getVisibleSkillList()) do
                    if skill:isLordSkill() and lord:hasLordSkill(skill:objectName()) then
                        table.insert(lord_skills, skill:objectName())
                        table.insert(lose_skills, "-" .. skill:objectName())
                    end
                end
            end
            if #lord_skills ~= 0 and lord:getHp() <= player:getHp()
                and room:askForSkillInvoke(player, self:objectName(), data) then
                player:loseMark("@duowei")
                lord:setTag("lord_skills", sgs.QVariant(table.concat(lord_skills, "+")))
                room:handleAcquireDetachSkills(player, table.concat(lord_skills, "|"), false)
                room:handleAcquireDetachSkills(lord, table.concat(lose_skills, "|"), false)
                room:setPlayerMark(player, "duowei_get", 1)
                room:setPlayerMark(lord, "duowei_lose", 1)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:getMark("duowei_get") ~= 0 then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("duowei_lose") ~= 0 then
                        local lord_skills = {}
                        local lord_String = p:getTag("lord_skills"):toString()
                        if lord_String and lord_String ~= "" then
                            lord_skills = lord_String:split("+")
                        end
                        room:handleAcquireDetachSkills(p, table.concat(lord_skills, "|"), false)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        if target then
            return target:hasSkill(self)
        end
        return false
    end,
}
ChihoIshida:addSkill(Luaduowei)

--[[
    技能名：自语
    描述：主公技，其他“STU48”势力的角色使用牌结算完成时，若此牌的目标仅为其自己，你可以摸一张牌。
]]
Luaziyu = sgs.CreateTriggerSkill {
    name = "Luaziyu$",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and player:getKingdom() == "STU48" and use.to:length() == 1
            and use.to:contains(player) then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:objectName() ~= p:objectName() then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ChihoIshida:addSkill(Luaziyu)

sgs.LoadTranslationTable {
    ["ChihoIshida"] = "石田 千穗",
    ["&ChihoIshida"] = "石田 千穗",
    ["#ChihoIshida"] = "千歲娘娘",
    ["designer:ChihoIshida"] = "Cassimolar",
    ["cv:ChihoIshida"] = "石田 千穗",
    ["illustrator:ChihoIshida"] = "Cassimolar",
    ["Luazhuanjia"] = "转嫁",
    [":Luazhuanjia"] = "你使用基本牌和锦囊牌前，你可以选择一名其他角色，令其成为此牌的使用者，其他角色以此法杀死一名角色后，你摸三张牌。",
    ["@zhuanjia_invoke"] = "你可以选择一名其他角色令其成为此【%arg】的使用者",
    ["Luajiyu"] = "觊觎",
    [":Luajiyu"] = "当其他角色使用牌时，若目标唯一且不为你，你可以交给目标一张同类型的手牌来代替其成为此牌唯一目标。",
    ["@jiyu_give"] = "你可以交给%src一张%dest手牌来代替其成为此【%arg】的目标",
    ["Luaduowei"] = "夺位",
    [":Luaduowei"] = "限定技，出牌阶段开始时，若你不是主公且当前主公有主公技，且其体力值不大于你，你可以获得其的主公技，然后其失去该主公技；你死亡时，其重新获得该主公技。",
    ["@duowei"] = "夺位",
    ["Luaziyu"] = "自语",
    [":Luaziyu"] = "主公技，其他“STU48”势力的角色使用牌结算完成时，若此牌的目标仅为其自己，你可以摸一张牌。",
}
