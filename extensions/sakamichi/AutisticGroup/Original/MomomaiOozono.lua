require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MomomaiOozono = sgs.General(Sakamichi, "MomomaiOozono", "AutisticGroup", 3, false)

--[[
    技能名：桃妹四连
    描述：出牌阶段限一次，你可以展示一张手牌并交给一名其他角色，直到你的下个回合开始，若此牌花色为：红桃，目标无法使用【桃】；黑桃，目标无法使用或打出【杀】；方块，目标无法使用或打出【闪】；梅花；目标无法使用【酒】。
]]
LuataomeisilianCard = sgs.CreateSkillCard {
    name = "LuataomeisilianCard",
    skill_name = "Luataomeisilian",
    target_fixed = false,
    will_throw = false,
    on_effect = function(self, effect)
        local target = effect.to
        local player = effect.from
        local room = player:getRoom()
        local subid = self:getSubcards():first()
        local card = sgs.Sanguosha:getCard(subid)
        local card_id = card:getEffectiveId()
        local suit = card:getSuitString()
        room:showCard(player, card_id)
        target:obtainCard(self)
        local msg = sgs.LogMessage()
        msg.from = player
        msg.to:append(target)
        local mark = player:objectName() .. "taomeisilian:" .. suit
        if suit == "heart" then
            room:setPlayerCardLimitation(target, "use", "Peach", false)
            room:setPlayerMark(target, mark, 1)
            room:setPlayerMark(target, "@no_peach", 1)
            msg.type = "#taomeisilian-Heart"
        elseif suit == "spade" then
            room:setPlayerCardLimitation(target, "use,response", "Slash", false)
            room:setPlayerMark(target, mark, 1)
            room:setPlayerMark(target, "@no_slash", 1)
            msg.type = "#taomeisilian-Spade"
        elseif suit == "diamond" then
            room:setPlayerCardLimitation(target, "use,response", "Jink", false)
            room:setPlayerMark(target, mark, 1)
            room:setPlayerMark(target, "@no_jink", 1)
            msg.type = "#taomeisilian-Diamond"
        else
            room:setPlayerCardLimitation(target, "use", "Analeptic", false)
            room:setPlayerMark(target, mark, 1)
            room:setPlayerMark(target, "@no_analeptic", 1)
            msg.type = "#taomeisilian-Club"
        end
        room:sendLog(msg)
    end,
}
LuataomeisilianVS = sgs.CreateOneCardViewAsSkill {
    name = "Luataomeisilian",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local acard = LuataomeisilianCard:clone()
        acard:addSubcard(card)
        return acard
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#LuataomeisilianCard")
    end,
}
Luataomeisilian = sgs.CreateTriggerSkill {
    name = "Luataomeisilian",
    view_as_skill = LuataomeisilianVS,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                local suits = {"heart", "spade", "diamond", "club"}
                for _, suit in ipairs(suits) do
                    local mark = player:objectName() .. "taomeisilian:" .. suit
                    if p:getMark(mark) ~= 0 then
                        room:setPlayerMark(p, mark, 0)
                        if suit == "heart" then
                            room:removePlayerCardLimitation(p, "use", "Peach$0")
                            room:setPlayerMark(p, "@no_peach", 0)
                        elseif suit == "spade" then
                            room:removePlayerCardLimitation(p, "use,response", "Slash$0")
                            room:setPlayerMark(p, "@no_slash", 0)
                        elseif suit == "diamond" then
                            room:removePlayerCardLimitation(p, "use,response", "Jink$0")
                            room:setPlayerMark(p, "@no_jink", 0)
                        else
                            room:removePlayerCardLimitation(p, "use", "Analeptic$0")
                            room:setPlayerMark(p, "@no_analeptic", 0)
                        end
                    end
                end
            end
        end
        return false
    end,
}
MomomaiOozono:addSkill(Luataomeisilian)

--[[
    技能名：群宠
    描述：每当你受到1点伤害后，你可以分别从每名其他角色的区域获得一张牌，然后将你的武将牌翻面。
]]
Luaqunchong = sgs.CreateTriggerSkill {
    name = "Luaqunchong",
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local n = player:getMark("LuaqunchongTimes")
        player:setMark("LuaqunchongTimes", 0)
        local damage = data:toDamage()
        local players = room:getOtherPlayers(player)
        for i = 0, damage.damage - 1, 1 do
            local can_invoke = false
            for _, p in sgs.qlist(players) do
                if not p:isAllNude() then
                    can_invoke = true
                    break
                end
            end
            if not can_invoke then
                break
            end
            player:addMark("LuaqunchongTimes")
            if player:askForSkillInvoke(self:objectName(), data) then
                player:setFlags("LuaqunchongUsing")
                for _, _player in sgs.qlist(players) do
                    if _player:isAlive() and (not _player:isAllNude()) then
                        local card_id = room:askForCardChosen(player, _player, "hej", self:objectName())
                        room:obtainCard(player, sgs.Sanguosha:getCard(card_id),
                            room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
                    end
                end
                player:turnOver()
                player:setFlags("-LuaqunchongUsing")
            else
                break
            end
        end
        player:setMark("LuaqunchongTimes", n)
        return false
    end,
}
MomomaiOozono:addSkill(Luaqunchong)

sgs.LoadTranslationTable {
    ["MomomaiOozono"] = "大園 桃妹",
    ["&MomomaiOozono"] = "大園 桃妹",
    ["#MomomaiOozono"] = "自閉群寵",
    ["designer:MomomaiOozono"] = "Cassimolar",
    ["cv:MomomaiOozono"] = "大園 桃妹",
    ["illustrator:MomomaiOozono"] = "Cassimolar",
    ["Luataomeisilian"] = "桃妹四连",
    [":Luataomeisilian"] = "出牌阶段限一次，你可以展示一张手牌并交给一名其他角色，直到你的下个回合开始，若此牌花色为：红桃，其无法使用【桃】；黑桃，其无法使用或打出【杀】；方块，其无法使用或打出【闪】；梅花，其无法使用【酒】。",
    ["#taomeisilian-Heart"] = "%to 直到 %from 的下个回合开始前，%to 无法使用<font color=\"yellow\"><b>【桃】</b></font>",
    ["#taomeisilian-Spade"] = "%to 直到 %from 的下个回合开始前，%to 无法使用或打出<font color=\"yellow\"><b>【杀】</b></font>",
    ["#taomeisilian-Diamond"] = "%to 直到 %from 的下个回合开始前，%to 无法使用或打出<font color=\"yellow\"><b>【闪】</b></font>",
    ["#taomeisilian-Club"] = "%to 直到 %from 的下个回合开始前，%to 无法使用<font color=\"yellow\"><b>【酒】</b></font>",
    ["Luaqunchong"] = "群宠",
    [":Luaqunchong"] = "每当你受到1点伤害后，你可以分别从每名其他角色的区域获得一张牌，然后将你的武将牌翻面。",
}
