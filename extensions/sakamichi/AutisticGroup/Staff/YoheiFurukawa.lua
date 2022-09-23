require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YoheiFurukawa = sgs.General(Sakamichi, "YoheiFurukawa", "AutisticGroup", 4, true)

--[[
    技能名：出题
    描述：出牌阶段限一次，你可以选择一张手牌，令一名其他角色选择一种颜色后你弃置该牌，若其选择的颜色与此牌颜色不同，目标本回合内无法闪避你对其使用的【杀】。
]]
LuachutiCard = sgs.CreateSkillCard {
    name = "LuachutiCard",
    skill_name = "Luachuti",
    target_fixed = false,
    will_throw = false,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local subid = self:getSubcards():first()
        local card = sgs.Sanguosha:getCard(subid)
        local color = room:askForChoice(target, "Luachuti", "red+black")
        room:throwCard(self, source, source)
        if color == "red" and card:isBlack() then
            local msg = sgs.LogMessage()
            msg.type = "#chuti-success"
            msg.from = source
            msg.to:append(target)
            msg.arg = color
            room:sendLog(msg)
            room:setPlayerMark(source, "chuti-from", 1)
            room:setPlayerMark(target, "chuti-to", 1)
            room:setPlayerMark(target, "@no_jink", 1)
        elseif color == "black" and card:isRed() then
            local msg = sgs.LogMessage()
            msg.type = "#chuti-success"
            msg.from = source
            msg.to:append(target)
            msg.arg = color
            room:sendLog(msg)
            room:setPlayerMark(source, "chuti-from", 1)
            room:setPlayerMark(target, "chuti-to", 1)
            room:setPlayerMark(target, "@no_jink", 1)
        else
            local msg = sgs.LogMessage()
            msg.type = "#chuti-fail"
            msg.to:append(target)
            msg.arg = color
            room:sendLog(msg)
        end
    end,
}
LuachutiVS = sgs.CreateViewAsSkill {
    name = "Luachuti",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = LuachutiCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#LuachutiCard")
    end,
}
Luachuti = sgs.CreateTriggerSkill {
    name = "Luachuti",
    view_as_skill = LuachutiVS,
    events = {sgs.SlashProceed, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:getMark("chuti-from") ~= 0 and effect.to:getMark("chuti-to") ~= 0 then
                room:slashResult(effect, nil)
                return true
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setPlayerMark(player, "chuti-from", 0)
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("chuti-to") ~= 0 then
                        room:setPlayerMark(p, "chuti-to", 0)
                        room:setPlayerMark(p, "@no_jink", 0)
                    end
                end
            end
            return false
        end
    end,
}
YoheiFurukawa:addSkill(Luachuti)

sgs.LoadTranslationTable {
    ["YoheiFurukawa"] = "古川 洋平",
    ["&YoheiFurukawa"] = "古川 洋平",
    ["#YoheiFurukawa"] = "Quiz王",
    ["designer:YoheiFurukawa"] = "Cassimolar",
    ["cv:YoheiFurukawa"] = "古川 洋平",
    ["illustrator:YoheiFurukawa"] = "Cassimolar",
    ["Luachuti"] = "出题",
    [":Luachuti"] = "出牌阶段限一次，你可以选择一张手牌，令一名其他角色选择一种颜色后你弃置该牌，若其选择的颜色与此牌颜色不同，本回合内，其无法闪避你对其使用的【杀】。",
    --	[":Luachuti"] = "出牌阶段限一次，你可以令一名其他角色回答你选择的一个问题，若其未回答正确，本回合内，其无法闪避你对其使用的【杀】。",
    ["#chuti-success"] = "%to 选择了“%arg”，%to 猜错了，本回合内 %from 对 %to 使用的【杀】无法被 %to 闪避",
    ["#chuti-fail"] = "%to 选择了“%arg”，%to 猜对了",
}
