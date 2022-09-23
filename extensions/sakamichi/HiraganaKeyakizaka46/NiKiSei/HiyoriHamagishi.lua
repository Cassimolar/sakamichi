require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HiyoriHamagishi_HiraganaKeyakizaka = sgs.General(Sakamichi, "HiyoriHamagishi_HiraganaKeyakizaka",
    "HiraganaKeyakizaka46", 4, false)
table.insert(SKMC.NiKiSei, "HiyoriHamagishi_HiraganaKeyakizaka")

--[[
    技能名：虫食
    描述：当你造成伤害时，你可以失去X点体力令此次伤害+X，若目标因此死亡则你回复X点体力，未死亡其回复X点体力（X为你当前体力）。
]]
Luachongshi = sgs.CreateTriggerSkill {
    name = "Luachongshi",
    events = {sgs.DamageCaused, sgs.Damage, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if player:hasSkill(self) and room:askForSkillInvoke(player, self:objectName(), data) then
                local x = player:getHp()
                room:loseHp(player, x)
                room:setPlayerMark(player, "chongshi" .. damage.to:objectName(), x)
                damage.damage = damage.damage + x
                data:setValue(damage)
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if player:getMark("chongshi" .. damage.to:objectName()) ~= 0 then
                local x = player:getMark("chongshi" .. damage.to:objectName())
                room:setPlayerMark(player, "chongshi" .. damage.to:objectName(), 0)
                if damage.to:isWounded() then
                    room:recover(damage.to, sgs.RecoverStruct(player, nil, math.min(damage.to:getLostHp(), x)))
                end
            end
        else
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                if death.damage.from and death.damage.from:getMark("chongshi" .. player:objectName()) ~= 0 then
                    local x = death.damage.from:getMark("chongshi" .. player:objectName())
                    room:setPlayerMark(death.damage.from, "chongshi" .. player:objectName(), 0)
                    if death.damage.from:isWounded() then
                        room:recover(death.damage.from, sgs.RecoverStruct(death.damage.from, nil,
                            math.min(death.damage.from:getLostHp(), x)))
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
HiyoriHamagishi_HiraganaKeyakizaka:addSkill(Luachongshi)

--[[
    技能名：谢命
    描述：当一名角色进入/脱离濒死时，你可以摸一张牌/回复1点体力。
]]
Luaxieming = sgs.CreateTriggerSkill {
    name = "Luaxieming",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EnterDying, sgs.QuitDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if event == sgs.EnterDying then
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        room:drawCards(p, 1, self:objectName())
                    end
                else
                    if p:isWounded() and room:askForSkillInvoke(p, self:objectName(), data) then
                        room:recover(p, sgs.RecoverStruct(player, nil, 1))
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
HiyoriHamagishi_HiraganaKeyakizaka:addSkill(Luaxieming)

sgs.LoadTranslationTable {
    ["HiyoriHamagishi_HiraganaKeyakizaka"] = "濱岸 ひより",
    ["&HiyoriHamagishi_HiraganaKeyakizaka"] = "濱岸 ひより",
    ["#HiyoriHamagishi_HiraganaKeyakizaka"] = "妖精夥伴",
    ["designer:HiyoriHamagishi_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:HiyoriHamagishi_HiraganaKeyakizaka"] = "濱岸 ひより",
    ["illustrator:HiyoriHamagishi_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luachongshi"] = "虫食",
    [":Luachongshi"] = "当你造成伤害时，你可以失去X点体力令此次伤害+X，若目标因此死亡则你回复X点体力，未死亡其回复X点体力（X为你当前体力）。",
    ["Luaxieming"] = "谢命",
    [":Luaxieming"] = "当一名角色进入/脱离濒死时，你可以摸一张牌/回复1点体力。",
}
