require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MioShoji = sgs.General(Zambi, "MioShoji", "Zambi", 4, false)
table.insert(SKMC.SanKiSei, "MioShoji")

--[[
    技能名：武装
    描述：当你造成/受到1点伤害后，你可以与目标拼点：若你赢，你可以获得两张拼点牌或摸两张牌；若你没赢，直到你的下个回合结束，你计算到其他角色的距离时+1，其他角色计算到你的距离时-1。锁定技，当你装备区有武器牌或拼点牌为武器牌时，你的拼点牌点数视为K。
]]
Luaarmed = sgs.CreateTriggerSkill {
    name = "Luaarmed",
    events = {sgs.Damage, sgs.Damaged, sgs.PindianVerifying, sgs.Pindian, sgs.EventPhaseEnd},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage or event == sgs.Damaged then
            local damage = data:toDamage()
            local target
            if event == sgs.Damage and damage.from:objectName() == player:objectName() then
                target = damage.to
            elseif event == sgs.Damaged and damage.to and damage.to:objectName() == player:objectName() then
                target = damage.from
            end
            if target and target:objectName() ~= player:objectName() and player:canPindian(target)
                and room:askForSkillInvoke(player, self:objectName(),
                    sgs.QVariant("@armed_invoke:" .. target:objectName())) then
                player:pindian(target, self:objectName())
            end
        elseif event == sgs.Pindian then
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                if pindian.success then
                    if room:askForChoice(player, self:objectName(), "obtaincard+drawcard") == "obtaincard" then
                        player:obtainCard(pindian.to_card)
                        player:obtainCard(pindian.from_card)
                    else
                        room:drawCards(player, 2, self:objectName())
                    end
                else
                    room:setPlayerMark(player, "armed_fail", 1)
                end
            end
        elseif event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() or pindian.to:objectName() == player:objectName() then
                if player:getWeapon() or pindian.from_card:isKindOf("Weapon") then
                    pindian.from_number = 13
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            room:setPlayerMark(player, "armed_fail", 0)
        end
        return false
    end,
}
LuaarmedMod = sgs.CreateDistanceSkill {
    name = "#LuaarmedMod",
    correct_func = function(self, from, to)
        if from:getMark("armed_fail") ~= 0 then
            return 1
        end
        if to:getMark("armed_fail") ~= 0 then
            return -1
        end
    end,
}
MioShoji:addSkill(Luaarmed)
if not sgs.Sanguosha:getSkill("#LuaarmedMod") then
    SKMC.SkillList:append(LuaarmedMod)
end

sgs.LoadTranslationTable {
    ["MioShoji"] = "庄司 美緒",
    ["&MioShoji"] = "庄司 美緒",
    ["#MioShoji"] = "剣術と薙刀術",
    ["designer:MioShoji"] = "Cassimolar",
    ["cv:MioShoji"] = "向井 葉月",
    ["illustrator:MioShoji"] = "Cassimolar",
    ["Luaarmed"] = "武装",
    [":Luaarmed"] = "当你造成/受到1点伤害后，你可以与目标拼点：若你赢，你可以获得两张拼点牌或摸两张牌；若你没赢，直到你的下个回合结束，你计算到其他角色的距离时+1，其他角色计算到你的距离时-1。锁定技，当你装备区有武器牌或拼点牌为武器牌时，你的拼点牌点数视为K。",
    ["Luaarmed:@armed_invoke"] = "是否发动【武装】与%src拼点",
    ["Luaarmed:obtaincard"] = "获得两张拼点牌",
    ["Luaarmed:drawcard"] = "摸两张牌",
}
