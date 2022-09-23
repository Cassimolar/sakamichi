require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NaoKosaka_Hinatazaka = sgs.General(Sakamichi, "NaoKosaka_Hinatazaka$", "Hinatazaka46", 3, false)
table.insert(SKMC.NiKiSei, "NaoKosaka_Hinatazaka")

--[[
    技能名：小鱼
    描述：出牌阶段，当你使用基本牌或通常锦囊牌时，若你本回合已使用过此牌名的牌，你可以令此牌无法响应或造成伤害时伤害+1。
]]
Luaxiaoyu = sgs.CreateTriggerSkill {
    name = "Luaxiaoyu",
    events = {sgs.CardUsed, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
                and player:hasFlag("xiaoyu" .. SKMC.true_name(use.card))
                and room:askForSkillInvoke(player, self:objectName(), data) then
                if room:askForChoice(player, self:objectName(), "xiaoyu1+xiaoyu2") == "xiaoyu1" then
                    room:setCardFlag(use.card, "no_respond_" .. player:objectName() .. "_ALL_TARGETS")
                    local no_respond_list = use.no_respond_list
                    for _, p in sgs.qlist(room:getAllPlayers()) do
                        table.insert(no_respond_list, p:objectName())
                    end
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                else
                    room:setCardFlag(use.card, "xiaoyu")
                end
            end
            if (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
                and not player:hasFlag("xiaoyu" .. SKMC.true_name(use.card)) then
                room:setPlayerFlag(player, "xiaoyu" .. SKMC.true_name(use.card))
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("xiaoyu") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end,
}
NaoKosaka_Hinatazaka:addSkill(Luaxiaoyu)

--[[
    技能名：恐龙
    描述：当你对体力值不大于你的角色造成伤害后，若你已受伤，则你可以回复等量的体力值，若你未受伤，你可以失去1点体力令其武将牌翻面。
]]
Luakonglong = sgs.CreateTriggerSkill {
    name = "Luakonglong",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:getHp() <= player:getHp() then
            if player:isWounded() then
                if room:askForSkillInvoke(player, self:objectName(),
                    sgs.QVariant("1:::" .. math.min(damage.damage, player:getLostHp()))) then
                    if damage.card then
                        room:recover(player, sgs.RecoverStruct(player, damage.card,
                            math.min(damage.damage, player:getLostHp())))
                    else
                        room:recover(player, sgs.RecoverStruct(player, nil, math.min(damage.damage, player:getLostHp())))
                    end
                end
            else
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("2:" .. damage.to:objectName())) then
                    room:loseHp(player)
                    damage.to:turnOver()
                end
            end
        end
        return false
    end,
}
NaoKosaka_Hinatazaka:addSkill(Luakonglong)

--[[
    技能名：心动
    描述：主公技，其他“けやき坂46”和“日向坂46”势力的角色回复体力时可以令你摸一张牌。
]]
Luaxindong = sgs.CreateTriggerSkill {
    name = "Luaxindong$",
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if player:getKingdom() == "HiraganaKeyakizaka46" or player:getKingdom() == "Hinatazaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:objectName() ~= p:objectName()
                    and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("draw:" .. p:objectName())) then
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
NaoKosaka_Hinatazaka:addSkill(Luaxindong)

sgs.LoadTranslationTable {
    ["NaoKosaka_Hinatazaka"] = "小坂 菜緒",
    ["&NaoKosaka_Hinatazaka"] = "小坂 菜緒",
    ["#NaoKosaka_Hinatazaka"] = "日向之顏",
    ["designer:NaoKosaka_Hinatazaka"] = "Cassimolar",
    ["cv:NaoKosaka_Hinatazaka"] = "小坂 菜緒",
    ["illustrator:NaoKosaka_Hinatazaka"] = "Cassimolar",
    ["Luaxiaoyu"] = "小鱼",
    [":Luaxiaoyu"] = "出牌阶段，当你使用基本牌或通常锦囊牌时，若你本回合已使用过此牌名的牌，你可以令此牌无法响应或造成伤害时伤害+1。",
    ["Luaxiaoyu:xiaoyu1"] = "令此牌无法响应",
    ["Luaxiaoyu:xiaoyu2"] = "令此牌伤害+1",
    ["Luakonglong"] = "恐龙",
    [":Luakonglong"] = "当你对体力值不大于你的角色造成伤害后，若你已受伤，则你可以回复等量的体力值，若你未受伤，你可以失去1点体力令其武将牌翻面。",
    ["Luakonglong:1"] = "是否回复%arg点体力",
    ["Luakonglong:2"] = "是否失去1点体力令%src武将牌翻面",
    ["Luaxindong"] = "心动",
    [":Luaxindong"] = "主公技，其他“けやき坂46”和“日向坂46”势力的角色回复体力时可以令你摸一张牌。",
    ["Luaxindong:draw"] = "是否令%src摸一张牌",
}