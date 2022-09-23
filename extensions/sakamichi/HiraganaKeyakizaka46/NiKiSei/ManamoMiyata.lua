require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManamoMiyata_HiraganaKeyakizaka = sgs.General(Sakamichi, "ManamoMiyata_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.NiKiSei, "ManamoMiyata_HiraganaKeyakizaka")

--[[
    技能名：魅惑
    描述：锁定技，男性角色无法响应你使用的通常锦囊牌。
]]

Luameihuo = sgs.CreateTriggerSkill {
    name = "Luameihuo",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isNDTrick() then
            local no_respond_list = use.no_respond_list
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isMale() then
                    table.insert(no_respond_list, p:objectName())
                    room:setCardFlag(use.card, "no_respond_" .. player:objectName() .. p:objectName())
                end
            end
            use.no_respond_list = no_respond_list
            data:setValue(use)
        end
    end,
}
ManamoMiyata_HiraganaKeyakizaka:addSkill(Luameihuo)

--[[
    技能名：和风
    描述：一名角色的回合结束时，若其本回合内使用过至少两张相同类型的牌，你可以摸一张牌。
]]
Luahefeng = sgs.CreateTriggerSkill {
    name = "Luahefeng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") then
                if player:hasFlag("hefeng" .. use.card:getTypeId()) then
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        room:setPlayerFlag(p, "hefeng")
                        room:setPlayerFlag(player, "hefeng_on")
                    end
                else
                    room:setPlayerFlag(player, "hefeng" .. use.card:getTypeId())
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            if player:hasFlag("hefeng_on") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:hasFlag("hefeng") and room:askForSkillInvoke(p, self:objectName(), data) then
                        room:drawCards(p, 1, self:objectName())
                        room:setPlayerFlag(p, "-hefeng")
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
ManamoMiyata_HiraganaKeyakizaka:addSkill(Luahefeng)

--[[
    技能名：古典
    描述：你使用的通常锦囊牌在结算完成后，若对至少一名其他角色造成伤害，你可以弃置一张牌获得之。
]]
Luagudian = sgs.CreateTriggerSkill {
    name = "Luagudian",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardFinished, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("gudian") then
                local ids = sgs.IntList()
                if use.card:isVirtualCard() then
                    ids = use.card:getSubcards()
                else
                    ids:append(use.card:getEffectiveId())
                end
                if not ids:isEmpty() then
                    local in_discard = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                            in_discard = false
                            break
                        end
                    end
                    if in_discard then
                        if room:askForDiscard(player, self:objectName(), 1, 1, true, true,
                            "@gudian:::" .. use.card:objectName()) then
                            room:setCardFlag(use.card, "-gudian")
                            room:obtainCard(player, use.card, true)
                        end
                    end
                end
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isNDTrick() and damage.to:objectName() ~= player:objectName() then
                room:setCardFlag(damage.card, "gudian")
            end
        end
        return false
    end,
}
ManamoMiyata_HiraganaKeyakizaka:addSkill(Luagudian)

sgs.LoadTranslationTable {
    ["ManamoMiyata_HiraganaKeyakizaka"] = "宮田 愛萌",
    ["&ManamoMiyata_HiraganaKeyakizaka"] = "宮田 愛萌",
    ["#ManamoMiyata_HiraganaKeyakizaka"] = "平安才女",
    ["designer:ManamoMiyata_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:ManamoMiyata_HiraganaKeyakizaka"] = "宮田 愛萌",
    ["illustrator:ManamoMiyata_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luameihuo"] = "魅惑",
    [":Luameihuo"] = "锁定技，男性角色无法响应你使用的通常锦囊牌。",
    ["Luahefeng"] = "和风",
    [":Luahefeng"] = "一名角色的回合结束时，若其本回合内使用过至少两张相同类型的牌，你可以摸一张牌。",
    ["Luagudian"] = "古典",
    [":Luagudian"] = "你使用的通常锦囊牌在结算完成后，若对至少一名其他角色造成伤害，你可以弃置一张牌获得之。",
    ["@gudian"] = "你可以弃置一张牌获得此【%arg】",
}
