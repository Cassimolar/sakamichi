require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ShioriSato = sgs.General(Sakamichi, "ShioriSato", "Keyakizaka46", 4, false)
SKMC.IKiSei.ShioriSato = true
SKMC.SeiMeiHanDan.ShioriSato = {
    name = {7, 18, 13, 18},
    ten_kaku = {25, "ji"},
    jin_kaku = {31, "da_ji"},
    ji_kaku = {31, "da_ji"},
    soto_kaku = {25, "ji"},
    sou_kaku = {56, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_hua_lao = sgs.CreateTriggerSkill {
    name = "sakamichi_hua_lao",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and not player:isKongcheng()
            and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@hua_lao")) then
            room:showAllCards(player)
            local red, black, colorless = 0, 0, 0
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isRed() then
                    red = red + 1
                elseif card:isBlack() then
                    black = black + 1
                elseif card:getColor() == sgs.Card_Colorless then
                    colorless = colorless + 1
                end
            end
            if red > black then
                if red > colorless then
                    room:setPlayerFlag(player, "hua_lao_red")
                elseif red < colorless then
                    room:setPlayerFlag(player, "hua_lao_colorless")
                else
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_colorless")
                end
            elseif black > red then
                if black > colorless then
                    room:setPlayerFlag(player, "hua_lao_black")
                elseif black < colorless then
                    room:setPlayerFlag(player, "hua_lao_colorless")
                else
                    room:setPlayerFlag(player, "hua_lao_black")
                    room:setPlayerFlag(player, "hua_lao_colorless")
                end
            elseif red == black then
                if red > colorless then
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_black")
                elseif red < colorless then
                    room:setPlayerFlag(player, "hua_lao_colorless")
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_black")
                else
                    room:setPlayerFlag(player, "hua_lao_red")
                    room:setPlayerFlag(player, "hua_lao_black")
                    room:setPlayerFlag(player, "hua_lao_colorless")
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard")
                and ((use.card:isRed() and player:hasFlag("hua_lao_red"))
                    or (use.card:isBlack() and player:hasFlag("hua_lao_black"))
                    or (use.card:getColor() == sgs.Card_Colorless and player:hasFlag("hua_lao_colorless"))) then
                room:drawCards(player, 1, self:objectName())
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
            end
        end
        return false
    end,
}
ShioriSato:addSkill(sakamichi_hua_lao)

sakamichi_she_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_she_ji",
    events = {sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not player:hasFlag("she_ji_used")
            and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@she_ji:::" .. use.card:objectName())) then
            local suit = room:askForSuit(player, self:objectName())
            use.card:setSuit(suit)
            SKMC.send_message(room, "#mSuitChose", player, nil, nil, nil, sgs.Card_Suit2String(suit))
            room:setPlayerFlag(player, "she_ji_used")
        end
    end,
}
ShioriSato:addSkill(sakamichi_she_ji)

sgs.LoadTranslationTable {
    ["ShioriSato"] = "佐藤 詩織",
    ["&ShioriSato"] = "佐藤 詩織",
    ["#ShioriSato"] = "美术担当",
    ["~ShioriSato"] = "花ことば あの人想い 花選ぶ…",
    ["designer:ShioriSato"] = "Cassimolar",
    ["cv:ShioriSato"] = "佐藤 詩織",
    ["illustrator:ShioriSato"] = "Cassimolar",
    ["sakamichi_hua_lao"] = "话痨",
    [":sakamichi_hua_lao"] = "出牌阶段开始时，你可以展示所有手牌，若如此做，本回合内你使用与你展示手牌中相同颜色最多的颜色的牌时不计入使用次数限制且可以摸一张牌。",
    ["sakamichi_hua_lao:@hua_lao"] = "是否发动【话痨】展示所有手牌",
    ["sakamichi_she_ji"] = "设计",
    [":sakamichi_she_ji"] = "出牌阶段限一次，当你使用牌时，你可以改变其花色。",
    ["sakamichi_she_ji:@she_ji"] = "是否改变此%arg的花色",
}
