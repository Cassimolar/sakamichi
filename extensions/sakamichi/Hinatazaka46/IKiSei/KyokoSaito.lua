require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KyokoSaito_Hinatazaka = sgs.General(Sakamichi, "KyokoSaito_Hinatazaka", "Hinatazaka46", 4, false)
table.insert(SKMC.IKiSei, "KyokoSaito_Hinatazaka")

KyokoSaito_Hinatazaka:addSkill("sakamichi_xia_chu")

--[[
    技能名：双面
    描述：锁定技，当你对女性角色造成伤害时，若其与你的距离大于/小于你与其的距离，此伤害+1/-1。
]]
Luashuangmian = sgs.CreateTriggerSkill {
    name = "Luashuangmian",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:isFemale() then
            if player:distanceTo(damage.to) < damage.to:distanceTo(player) then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            elseif player:distanceTo(damage.to) > damage.to:distanceTo(player) then
                damage.damage = damage.damage - 1
                data:setValue(damage)
                if damage.damage <= 0 then
                    return true
                end
            end
        end
        return false
    end,
}
KyokoSaito_Hinatazaka:addSkill(Luashuangmian)

--[[
    技能名：京妹
    描述：转换技，①当你对女性角色造成伤害后，你可以将你的的性别改为女性，并可以令一名男性角色摸一张牌；②当你受到女性角色造成伤害后，你可以将你的性别改为男性，并可以令一名女性角色回复1点体力。
]]
Luajingmei = sgs.CreateTriggerSkill {
    name = "Luajingmei",
    change_skill = true,
    events = {sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local n = room:getChangeSkillState(player, self:objectName())
        if event == sgs.Damage then
            if damage.to:isFemale() and n == 1 and room:askForSkillInvoke(player, self:objectName(), data) then
                room:setChangeSkillState(player, self:objectName(), 2)
                player:setGender(sgs.General_Female)
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isMale() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jingmei_1", true, true)
                    if target then
                        room:drawCards(target, 1, self:objectName())
                    end
                end
            end
        else
            if damage.from and damage.from:isFemale() and n == 2
                and room:askForSkillInvoke(player, self:objectName(), data) then
                room:setChangeSkillState(player, self:objectName(), 1)
                player:setGender(sgs.General_Male)
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:isFemale() and p:isWounded() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jingmei_2", true, true)
                    if target then
                        room:recover(target, sgs.RecoverStruct(player))
                    end
                end
            end
        end
        return false
    end,
}
KyokoSaito_Hinatazaka:addSkill(Luajingmei)

sgs.LoadTranslationTable {
    ["KyokoSaito_Hinatazaka"] = "齊藤 京子",
    ["&KyokoSaito_Hinatazaka"] = "齊藤 京子",
    ["#KyokoSaito_Hinatazaka"] = "味增天使",
    ["designer:KyokoSaito_Hinatazaka"] = "Cassimolar",
    ["cv:KyokoSaito_Hinatazaka"] = "齊藤 京子",
    ["illustrator:KyokoSaito_Hinatazaka"] = "Cassimolar",
    ["Luashuangmian"] = "双面",
    [":Luashuangmian"] = "锁定技，当你对女性角色造成伤害时，若其与你的距离大于/小于你与其的距离，此伤害+1/-1。",
    ["Luajingmei"] = "京妹",
    [":Luajingmei"] = "转换技，①当你对女性角色造成伤害后，你可以将你的的性别改为女性，并可以令一名男性角色摸一张牌；②当你受到女性角色造成伤害后，你可以将你的性别改为男性，并可以令一名女性角色回复1点体力。",
    ["@jingmei_1"] = "你可以令一名男性角色摸一张牌",
    ["@jingmei_2"] = "你可以令一名女性角色回复1点体力",
}
