require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

Yasuo = sgs.General(Sakamichi, "Yasuo", "AutisticGroup", 8, true, true, true, 4)

--[[
    技能名：孤儿
    描述：场上身份存在且存在一名时你获得如下效果：
        主公，当一名角色受到伤害时，你可以摸一张牌然后将一张手牌交给其；
        忠臣，当一名角色武将牌状态改变时，你可以令其摸一张牌；
        内奸，当一张锦囊牌指定不少于两名目标时，你可以令此牌目标中的至多X角色摸一张牌，若如此做，该锦囊对这些角色无效（X为你已损失体力值）；
        反贼，当你造成伤害后你可以将一张手牌交给目标，然后令其选择令你摸两张牌或受到无来源的1点伤害。
]]
LuaorphanCard = sgs.CreateSkillCard {
    name = "LuaorphanCard",
    skill_name = "Luaorphan",
    target_fixed = false,
    filter = function(self, targets, to_select, player)
        if #targets < player:getLostHp() then
            return to_select:hasFlag("orphan")
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        for _, p in ipairs(targets) do
            room:setPlayerFlag(p, "orphanremove")
        end
    end,
}
LuaorphanVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luaorphan",
    view_as = function(self)
        return LuaorphanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@Luaorphan")
    end,
}
Luaorphan = sgs.CreateTriggerSkill {
    name = "Luaorphan",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.Damaged, sgs.TurnedOver, sgs.ChainStateChanged, sgs.TargetSpecifying, sgs.Damage},
    view_as_skill = LuaorphanVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("@only_lord") == 1 then
                    if room:askForSkillInvoke(p, self:objectName(),
                        sgs.QVariant("only_lord_invoke:" .. player:objectName())) then
                        room:drawCards(p, 1, self:objectName())
                        if player:isAlive() and p:isAlive() and (not p:isKongcheng()) and player:objectName()
                            ~= p:objectName() then
                            local card = room:askForExchange(p, self:objectName(), 1, 1, false,
                                "@only_lord_exchange:" .. self:objectName())
                            room:obtainCard(player, card, false)
                        end
                    end
                end
            end
            return false
        elseif event == sgs.TurnedOver or event == sgs.ChainStateChanged then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("@only_loyalist") == 1 then
                    if room:askForSkillInvoke(p, self:objectName(),
                        sgs.QVariant("only_loyalist_invoke:" .. player:objectName())) then
                        room:drawCards(player, 1, self:objectName())
                    end
                end
            end
            return false
        elseif event == sgs.TargetSpecifying then
            local use = data:toCardUse()
            local trick = use.card
            if trick and trick:isKindOf("TrickCard") then
                if use.to:length() >= 2 then
                    if trick:subcardsLength() ~= 0 or trick:getEffectiveId() ~= -1 then
                        room:moveCardTo(trick, nil, sgs.Player_PlaceTable, true)
                    end
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if p:getMark("@only_renegade") == 1 then
                            for _, pl in sgs.qlist(use.to) do
                                room:setPlayerFlag(pl, "orphan")
                            end
                            if p:isWounded()
                                and room:askForUseCard(p, "@@Luaorphan", "@only_renegade_invoke:"
                                    .. use.from:objectName() .. "::" .. trick:objectName()) then
                                local nullified_list = use.nullified_list
                                for _, pl in sgs.qlist(use.to) do
                                    room:setPlayerFlag("-orphan")
                                    if pl:hasFlag("orphanremove") then
                                        room:setPlayerFlag("-orphanremove")
                                        room:drawCards(pl, 1, self:objectName())
                                        table.insert(nullified_list, pl:objectName())
                                    end
                                end
                                use.nullified_list = nullified_list
                                data:setValue(use)
                            end
                        end
                    end
                end
            end
            return false
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if player:hasSkill(self) and player:getMark("@only_rebel") == 1 then
                if damage.to:isAlive() and not player:isKongcheng() then
                    local card = room:askForExchange(player, self:objectName(), 1, 1, false,
                        "@only_rebel_exchange:" .. damage.to:objectName(), true)
                    if card then
                        room:obtainCard(damage.to, card, false)
                        if damage.to:isAlive() then
                            if room:askForSkillInvoke(damage.to, self:objectName(),
                                sgs.QVariant("only_rebel_invoke:" .. player:objectName())) then
                                room:drawcards(player, 2, self:objectName())
                            else
                                room:damage(sgs.DamageStruct(self:objectName(), nil, damage.to))
                            end
                        end
                    end
                end
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuaorphanMark = sgs.CreateTriggerSkill {
    name = "#LuaorphanMark",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseProceeding, sgs.EventPhaseEnd, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local only_lord, only_loyalist, only_renegade, only_rebel = false, false, false, false
        local lord, loyalist, renegade, rebel = 0, 0, 0, 0
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getRole() == "lord" then
                lord = lord + 1
            elseif p:getRole() == "loyalist" then
                loyalist = loyalist + 1
            elseif p:getRole() == "renegade" then
                renegade = renegade + 1
            elseif p:getRole() == "rebel" then
                rebel = rebel + 1
            end
        end
        if lord == 1 then
            only_lord = true
        end
        if loyalist == 1 then
            only_loyalist = true
        end
        if renegade == 1 then
            only_renegade = true
        end
        if rebel == 1 then
            only_rebel = true
        end
        for _, p in sgs.qlist(room:findPlayersBySkillName("Luaorphan")) do
            if only_lord then
                room:setPlayerMark(p, "@only_lord", 1)
            else
                room:setPlayerMark(p, "@only_lord", 0)
            end
            if only_loyalist then
                room:setPlayerMark(p, "@only_loyalist", 1)
            else
                room:setPlayerMark(p, "@only_loyalist", 0)
            end
            if only_renegade then
                room:setPlayerMark(p, "@only_renegade", 1)
            else
                room:setPlayerMark(p, "@only_renegade", 0)
            end
            if only_rebel then
                room:setPlayerMark(p, "@only_rebel", 1)
            else
                room:setPlayerMark(p, "@only_rebel", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Yasuo:addSkill(Luaorphan)
if not sgs.Sanguosha:getSkill("#LuaorphanMark") then
    SKMC.SkillList:append(LuaorphanMark)
end

--[[
    技能名：孤儿
    描述：当一名角色使用一张基本牌或锦囊牌指定你为目标时，若你为唯一目标，则你需弃置一张手牌，否则失去1点体力；若你不为唯一目标，则你可以获得该角色一张牌并令该牌对你无效（若该角色区域内没有牌，则你摸一张牌）。
]]
LuaOrphanMinamiOshiVer = sgs.CreateTriggerSkill {
    name = "LuaOrphanMinamiOshiVer",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecifying then
            local use = data:toCardUse()
            if use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if use.to:contains(p) then
                        if use.to:length() == 1 then
                            if not p:isKongcheng() then
                                if not room:askForDiscard(p, self:objectName(), 1, 1, true, false,
                                    "@LuaOrphanMinamiOshiVer_discard") then
                                    room:loseHp(p)
                                end
                            end
                        else
                            if use.from:isAllNude() then
                                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                                    "@LuaOrphanMinamiOshiVer-draw:" .. player:objectName() .. "::"
                                        .. use.card:objectName())) then
                                    room:drawcards(p, 1, self:objectName())
                                    local nullified_list = use.nullified_list
                                    table.insert(nullified_list, p:objectName())
                                    use.nullified_list = nullified_list
                                    data:setValue(use)
                                end
                            else
                                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                                    "@LuaOrphanMinamiOshiVer-chosen:" .. player:objectName() .. "::"
                                        .. use.card:objectName())) then
                                    local card = room:askForCardChosen(p, use.from, "hej", self:objectName(), false,
                                        sgs.Card_MethodNone)
                                    room:obtainCard(p, card)
                                    local nullified_list = use.nullified_list
                                    table.insert(nullified_list, p:objectName())
                                    use.nullified_list = nullified_list
                                    data:setValue(use)
                                end
                            end
                        end
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
-- Yasuo:addSkill(LuaOrphanMinamiOshiVer)
if not sgs.Sanguosha:getSkill("LuaOrphanMinamiOshiVer") then
    SKMC.SkillList:append(LuaOrphanMinamiOshiVer)
end

--[[
    技能名：快乐风男
    描述：其它角色计算到你的距离时+1，你计算到其它角色的距离时-1。
]]
Luahappywindman = sgs.CreateDistanceSkill {
    name = "Luahappywindman",
    correct_func = function(self, from, to)
        if to:hasSkill(self) then
            return 1
        end
        if from:hasSkill(self) then
            return -1
        end
    end,
}
Yasuo:addSkill(Luahappywindman)

--[[
    技能名：切换版本-亚索
    描述：游戏开始时，你可以将【孤儿】换成南推版。
]]
orphanVer = sgs.CreateTriggerSkill {
    name = "#orphanVer",
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getGeneralName() == "Yasuo" or p:getGeneral2Name() == "Yasuo" then
                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("@orphanVer_invoke")) then
                    room:handleAcquireDetachSkills(p, "-Luaorphan|LuaOrphanMinamiOshiVer")
                end
            end
        end
        return false
    end,
}
Yasuo:addSkill(orphanVer)

sgs.LoadTranslationTable {
    ["Yasuo"] = "亚索",
    ["&Yasuo"] = "亚索",
    ["#Yasuo"] = "疾风剑豪",
    ["Luaorphan"] = "孤儿",
    [":Luaorphan"] = "场上身份存在且存在一名时你获得如下效果：主公，当一名角色受到伤害时，你可以摸一张牌然后将一张手牌交给其；忠臣，当一名角色武将牌状态改变时，你可以令其摸一张牌；内奸，当一张锦囊牌指定不少于两名目标时，你可以令此牌目标中的至多X角色摸一张牌，若如此做，该锦囊对这些角色无效（X为你已损失体力值）；反贼，当你造成伤害后你可以将一张手牌交给目标，然后令其选择令你摸两张牌或受到无来源的1点伤害。",
    ["Luaorphan:only_lord_invoke"] = "是否发动【孤儿】摸一张牌然后交给%src 一张手牌",
    ["Luaorphan:only_loyalist_invoke"] = "是否发动【孤儿】令%src 摸一张牌",
    ["Luaorphan:only_rebel_invoke"] = "是否令%src 摸两张牌，否则你将受到1点无来源的伤害",
    ["@only_lord_exchange"] = "请选择交给%src 的一张手牌",
    ["@only_renegade_invoke"] = "请选择【孤儿】的目标，令%src 使用的%arg 对其无效并摸一张牌",
    ["only_rebel_exchange"] = "请选择是否将一张手牌交给%src 以发动【孤儿】",
    ["#LuaorphanMark"] = "孤儿",
    ["@only_lord"] = "主",
    ["@only_loyalist"] = "忠",
    ["@only_renegade"] = "内",
    ["@only_rebel"] = "反",
    ["LuaOrphanMinamiOshiVer"] = "孤儿",
    [":LuaOrphanMinamiOshiVer"] = "当一名角色使用一张基本牌或锦囊牌指定你为目标时，若你为唯一目标，则你需弃置一张手牌，否则失去1点体力；若你不为唯一目标，则你可以获得该角色一张牌并令该牌对你无效（若该角色区域内没有牌，则你摸一张牌）。",
    ["@LuaOrphanMinamiOshiVer_discard"] = "你的【孤儿】被触发，你需要弃置一张手牌，否则流失1点体力",
    ["@LuaOrphanMinamiOshiVer-draw"] = "你可以摸一张牌令%src 使用的%arg 对你无效",
    ["@LuaOrphanMinamiOshiVer-chosen"] = "你可以从%src 处获得一张牌令%src 使用的%arg 对你无效",
    ["Luahappywindman"] = "快乐风男",
    [":Luahappywindman"] = "其它角色计算到你的距离时+1，你计算到其它角色的距离时-1。",
    ["#orphanVer:@orphanVer_invoke"] = "你可以选择将【孤儿】切换成南推版本。",
}
