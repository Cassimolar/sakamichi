require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SuzukaTomita_HiraganaKeyakizaka = sgs.General(Sakamichi, "SuzukaTomita_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.NiKiSei, "SuzukaTomita_HiraganaKeyakizaka")

--[[
    技能名：负颜
    描述：当你受到其他角色造成的伤害后，你可以于其拼点，若你赢，你可以选择将其区域内的一张牌置于你的武将牌上称为“委屈”，你可以弃置一张“委屈”来跳过除回合开始和回合结束阶段外的任一阶段。
]]
Luafuyan = sgs.CreateTriggerSkill {
    name = "Luafuyan",
    events = {sgs.Damaged, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() and not player:isKongcheng()
                and player:canPindian(damage.from) then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@fuyan_invoke")) then
                    if player:pindian(damage.from, self:objectName(), nil) then
                        if not damage.from:isAllNude() then
                            local card = room:askForCardChosen(player, damage.from, "hej", self:objectName())
                            if card then
                                player:addToPile("weiqu", card)
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Judge or change.to == sgs.Player_Draw or change.to == sgs.Player_Play or change.to
                == sgs.Player_Discard then
                local index = 0
                if change.to == sgs.Player_Judge then
                    index = 1
                elseif change.to == sgs.Player_Draw then
                    index = 2
                elseif change.to == sgs.Player_Play then
                    index = 3
                elseif change.to == sgs.Player_Discard then
                    index = 4
                end
                local prompt = string.format("fuyan-%d", index)
                if player:getPile("weiqu"):length() ~= 0
                    and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(prompt)) then
                    local card_ids = player:getPile("weiqu")
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "",
                        player:objectName(), self:objectName(), "")
                    if not card_ids:isEmpty() then
                        room:fillAG(card_ids)
                        local card_id = room:askForAG(player, card_ids, true, self:objectName())
                        if card_id ~= -1 then
                            room:clearAG()
                            card_ids:removeOne(card_id)
                            room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
                            player:skip(change.to)
                        end
                    end
                end
            end
        end
        return false
    end,
}
SuzukaTomita_HiraganaKeyakizaka:addSkill(Luafuyan)

--[[
    技能名：败犬
    描述：当你拼点未成功时，你可以摸一张牌；锁定技，你的拼点牌亮出时点数-X（X未你当前体力值）。
]]
Luabaiquan = sgs.CreateTriggerSkill {
    name = "Luabaiquan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Pindian, sgs.PindianVerifying},
    on_trigger = function(self, event, player, data, room)
        local pindian = data:toPindian()
        if event == sgs.Pindian then
            if not pindian.success then
                room:drawCards(player, 1, self:objectName())
            end
        else
            if pindian.from:hasSkill(self) then
                pindian.from_number = math.max(pindian.from_number - pindian.from:getHp(), 1)
            end
            if pindian.to:hasSkill(self) then
                pindian.to_number = math.max(pindian.to_number - pindian.to:getHp(), 1)
            end
        end
    end,
}
SuzukaTomita_HiraganaKeyakizaka:addSkill(Luabaiquan)

--[[
    技能名：号泣
    描述：觉醒技，回合结束时，若你拥有五张或更多的“委屈”，你获得所有的“委屈”，并失去【负颜】并获得【较真】。
]]
Luahaoqi = sgs.CreateTriggerSkill {
    name = "Luahaoqi",
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getPile("weiqu"):length() >= 5 then
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            for _, id in sgs.qlist(player:getPile("weiqu")) do
                dummy:addSubcard(id)
            end
            player:obtainCard(dummy)
            room:handleAcquireDetachSkills(player, "-Luafuyan|Luajiaozhen")
            room:addPlayerMark(player, self:objectName())
        end
        return false
    end,
}
SuzukaTomita_HiraganaKeyakizaka:addSkill(Luahaoqi)

--[[
    技能名：较真
    描述：出牌阶段限一次，你可以选择一名可以拼点的其他角色，你摸一张牌然后和其拼点，若你赢此技能视为未发动过。
]]
LuajiaozhenCard = sgs.CreateSkillCard {
    name = "LuajiaozhenCard",
    skill_name = "Luajiaozhen",
    will_throw = false,
    handling_method = sgs.Card_MethodPindian,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:drawCards(effect.from, 1, "Luajiaozhen")
        if not effect.from:pindian(effect.to, "Luajiaozhen", nil) then
            room:setPlayerFlag(effect.from, "jiaozhen_used")
        end
    end,
}
Luajiaozhen = sgs.CreateZeroCardViewAsSkill {
    name = "Luajiaozhen",
    view_as = function()
        return LuajiaozhenCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("jiaozhen_used")
    end,
}
if not sgs.Sanguosha:getSkill("Luajiaozhen") then
    SKMC.SkillList:append(Luajiaozhen)
end
SuzukaTomita_HiraganaKeyakizaka:addRelateSkill("Luajiaozhen")

sgs.LoadTranslationTable {
    ["SuzukaTomita_HiraganaKeyakizaka"] = "富田 鈴花",
    ["&SuzukaTomita_HiraganaKeyakizaka"] = "富田 鈴花",
    ["#SuzukaTomita_HiraganaKeyakizaka"] = "大玲花",
    ["designer:SuzukaTomita_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:SuzukaTomita_HiraganaKeyakizaka"] = "富田 鈴花",
    ["illustrator:SuzukaTomita_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luafuyan"] = "负颜",
    [":Luafuyan"] = "当你受到其他角色造成的伤害后，你可以于其拼点，若你赢，你可以选择将其区域内的一张牌置于你的武将牌上称为“委屈”，你可以弃置一张“委屈”来跳过除回合开始和回合结束阶段外的任一阶段。",
    ["Luafuyan:@fuyan_invoke"] = "是否发动【负颜】",
    ["Luafuyan:fuyan1"] = "你可以弃置一张“委屈”跳过判定阶段",
    ["Luafuyan:fuyan2"] = "你可以弃置一张“委屈”跳过摸牌阶段",
    ["Luafuyan:fuyan3"] = "你可以弃置一张“委屈”跳过出牌阶段",
    ["Luafuyan:fuyan4"] = "你可以弃置一张“委屈”跳过弃牌阶段",
    ["Luabaiquan"] = "败犬",
    [":Luabaiquan"] = "当你拼点未成功时，你可以摸一张牌；锁定技，你的拼点牌亮出时点数-X（X未你当前体力值）。",
    ["weiqu"] = "委屈",
    ["Luahaoqi"] = "号泣",
    [":Luahaoqi"] = "觉醒技，回合结束时，若你拥有五张或更多的“委屈”，你获得所有的“委屈”，并失去【负颜】并获得【较真】。",
    ["Luajiaozhen"] = "较真",
    [":Luajiaozhen"] = "出牌阶段限一次，你可以选择一名可以拼点的其他角色，你摸一张牌然后和其拼点，若你赢此技能视为未发动过。",
}
