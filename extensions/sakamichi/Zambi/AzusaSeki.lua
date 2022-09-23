require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AzusaSeki = sgs.General(Zambi, "AzusaSeki", "Zambi", 4, false)
table.insert(SKMC.SanKiSei, "AzusaSeki")

--[[
    技能名：听从
    描述：出牌阶段，你可以弃置一张牌，然后受到1点无来源的伤害。
]]
LuashitagauCard = sgs.CreateSkillCard {
    name = "LuashitagauCard",
    skill_name = "Luashitagau",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:damage(sgs.DamageStruct("Luashitagau", nil, source, 1))
        room:addPlayerMark(source, "shitagau", 1)
    end,
}
Luashitagau = sgs.CreateOneCardViewAsSkill {
    name = "Luashitagau",
    filter_pattern = ".",
    view_as = function(self, card)
        local cd = LuashitagauCard:clone()
        cd:addSubcard(card:getId())
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isNude()
    end,
}
AzusaSeki:addSkill(Luashitagau)

--[[
    技能名：动摇
    描述：每当你受到1点伤害后，你可以令一名其他角色的一项技能失效，直到当前回合结束。
]]
Luawaver = sgs.CreateTriggerSkill {
    name = "Luawaver",
    events = {sgs.Damaged, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            for i = 0, damage.damage - 1, 1 do
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getVisibleSkillList():length() ~= 0 then
                        targets:append(p)
                    end
                end
                if targets:length() ~= 0 then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@waver_invoke", true,
                        true)
                    if target then
                        local skill_List = {}
                        for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                            table.insert(skill_List, skill:objectName())
                        end
                        local skill = room:askForChoice(player, self:objectName(), table.concat(skill_List, "+"))
                        room:setPlayerFlag(target, "waver" .. skill)
                        local msg = sgs.LogMessage()
                        msg.type = "#waver"
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
                    if p:hasFlag("waver" .. skill:objectName()) then
                        room:setPlayerFlag(p, "-waver" .. skill:objectName())
                    end
                end
            end
        end
        return false
    end,
}
LuawaverInvalidity = sgs.CreateInvaliditySkill {
    name = "#LuawaverInvalidity",
    skill_valid = function(self, player, skill)
        if player:hasFlag("waver" .. skill:objectName()) then
            return false
        else
            return true
        end
    end,
}
AzusaSeki:addSkill(Luawaver)
if not sgs.Sanguosha:getSkill("#LuawaverInvalidity") then
    SKMC.SkillList:append(LuawaverInvalidity)
end

--[[
    技能名：绑架
    描述：限定技，出牌阶段你可以令至多X名角色的所有技能失效，直到当前回合结束（X为你发动【听从】的次数）。
]]
LuakidnapCard = sgs.CreateSkillCard {
    name = "LuakidnapCard",
    skill_name = "Luakidnap",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets < sgs.Self:getMark("shitagau")
    end,
    on_use = function(self, room, source, targets)
        source:loseMark("@kidnap")
        local msg = sgs.LogMessage()
        msg.type = "#kidnap"
        msg.from = source
        for _, p in pairs(targets) do
            room:setPlayerFlag(p, "kidnap")
            msg.to:append(p)
        end
        msg.arg = "Luakidnap"
        room:sendLog(msg)
    end,
}
LuakidnapVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luakidnap",
    view_as = function(self)
        return LuakidnapCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@kidnap") ~= 0 and player:getMark("shitagau") ~= 0
    end,
}
Luakidnap = sgs.CreateTriggerSkill {
    name = "Luakidnap",
    frequency = sgs.Skill_Limited,
    limit_mark = "@kidnap",
    events = {sgs.EventPhaseEnd},
    view_as_skill = LuakidnapVS,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasFlag("kidnap") then
                    room:setPlayerFlag(p, "-kidnap")
                end
            end
        end
        return false
    end,
}
LuakidnapInvalidity = sgs.CreateInvaliditySkill {
    name = "#LuakidnapInvalidity",
    skill_valid = function(self, player, skill)
        if player:hasFlag("kidnap") then
            return false
        else
            return true
        end
    end,
}
AzusaSeki:addSkill(Luakidnap)
if not sgs.Sanguosha:getSkill("#LuakidnapInvalidity") then
    SKMC.SkillList:append(LuakidnapInvalidity)
end

sgs.LoadTranslationTable {
    ["AzusaSeki"] = "関 あずさ",
    ["&AzusaSeki"] = "関 あずさ",
    ["#AzusaSeki"] = "私なりの努力",
    ["designer:AzusaSeki"] = "Cassimolar",
    ["cv:AzusaSeki"] = "佐藤 楓",
    ["illustrator:AzusaSeki"] = "Cassimolar",
    ["Luashitagau"] = "听从",
    [":Luashitagau"] = "出牌阶段，你可以弃置一张牌，然后受到1点无来源的伤害。",
    ["Luawaver"] = "动摇",
    [":Luawaver"] = "每当你受到1点伤害后，你可以令一名其他角色的一项技能失效，直到当前回合结束。",
    ["@waver_invoke"] = "你可以选择一名其他角色令其一项技能本回合内失效",
    ["#waver"] = "%from发动了【%arg2】令%to的【%arg】本回合内失效",
    ["Luakidnap"] = "绑架",
    [":Luakidnap"] = "限定技，出牌阶段你可以令至多X名角色的所有技能失效，直到当前回合结束（X为你发动【听从】的次数）。",
    ["#kidnap"] = "%from发动了【%arg】令%to的所有技能本回合失效",
}
