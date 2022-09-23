require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YumikoSeki_Keyakizaka = sgs.General(Sakamichi, "YumikoSeki_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.NiKiSei.YumikoSeki_Keyakizaka = true
SKMC.SeiMeiHanDan.YumikoSeki_Keyakizaka = {
    name = {14, 6, 9, 3},
    ten_kaku = {14, "xiong"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {18, "ji"},
    soto_kaku = {26, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_guan_aiCard = sgs.CreateSkillCard {
    name = "sakamichi_guan_aiCard",
    skill_name = "sakamichi_guan_ai",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
                   and not sgs.Self:hasFlag("guan_ai_" .. to_select:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local suit_str = sgs.Card_Suit2String(room:askForSuit(effect.to, self:getSkillName()))
        SKMC.send_message(room, "#mSuitChose", effect.to, nil, nil, nil, suit_str)
        local card = room:askForCard(effect.from, ".|.|.|hand",
            "@guan_ai:" .. effect.to:objectName() .. "::" .. suit_str, sgs.QVariant(), sgs.Card_MethodNone, nil, false,
            self:getSkillName(), false)
        if card then
            room:showCard(effect.from, card:getEffectiveId())
            effect.to:obtainCard(card)
            room:setPlayerFlag(effect.from, "guan_ai_" .. effect.to:objectName())
            if card:getSuitString() == suit_str then
                room:drawCards(effect.from, 2, self:objectName())
            else
                room:setPlayerFlag(effect.from, "guan_ai_fail")
            end
        end
    end,
}
sakamichi_guan_ai = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_guan_ai",
    view_as = function()
        return sakamichi_guan_aiCard:clone()
    end,
    enabled_at_play = function(self, player)
        local enable = false
        for _, p in sgs.qlist(player:getSiblings()) do
            if not player:hasFlag("guan_ai_" .. p:objectName()) then
                enable = true
                break
            end
        end
        return not player:hasFlag("guan_ai_fail") and enable
    end,
}
YumikoSeki_Keyakizaka:addSkill(sakamichi_guan_ai)

sakamichi_hui_zhang = sgs.CreateTriggerSkill {
    name = "sakamichi_hui_zhang",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DrawNCards, sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards and player:hasSkill(self) then
            local count = data:toInt() + SKMC.number_correction(player, 1)
            data:setValue(count)
        elseif event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
                and move.from_places:contains(sgs.Player_PlaceHand) then
                if event == sgs.BeforeCardsMove then
                    if move.from:isKongcheng() then
                        return false
                    end
                    for _, id in sgs.qlist(move.from:getHandcards()) do
                        if not move.card_ids:contains(id:getEffectiveId()) then
                            return false
                        end
                    end
                    if move.from:getMaxCards() == 0 and move.from:getPhase() == sgs.Player_Discard
                        and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                        == sgs.CardMoveReason_S_REASON_RULEDISCARD then
                        room:setPlayerFlag(move.from, "hui_zhang_ZeroMaxCards")
                        return false
                    end
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        room:addPlayerMark(p, self:objectName())
                    end
                else
                    if move.from:objectName() == player:objectName() then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if p:getMark(self:objectName()) ~= 0 and room:askForSkillInvoke(p, self:objectName(), data) then
                                room:setPlayerMark(p, self:objectName(), 0)
                                room:drawCards(p, 1, self:objectName())
                                if p:objectName() ~= player:objectName() then
                                    local card = room:askForCard(p, ".|.|.|hand",
                                        "@hui_zhang:" .. move.from:objectName(), data, sgs.Card_MethodNone)
                                    if card then
                                        player:obtainCard(card)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Discard and player:hasFlag("hui_zhang_ZeroMaxCards") then
                room:setPlayerFlag(player, "-hui_zhang_ZeroMaxCards")
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        room:drawCards(p, 1, self:objectName())
                        local card = room:askForCard(p, ".|.|.|hand", "@hui_zhang:" .. player:objectName(), data,
                            sgs.Card_MethodNone)
                        if card then
                            player:obtainCard(card)
                        end
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
sakamichi_hui_zhangMax = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_hui_zhangMax",
    extra_func = function(self, target)
        if target:hasSkill("sakamichi_hui_zhang") then
            return SKMC.number_correction(target, 1)
        end
    end,
}
YumikoSeki_Keyakizaka:addSkill(sakamichi_hui_zhang)
if not sgs.Sanguosha:getSkill("#sakamichi_hui_zhangMax") then
    SKMC.SkillList:append(sakamichi_hui_zhangMax)
end

sgs.LoadTranslationTable {
    ["YumikoSeki_Keyakizaka"] = "関 有美子",
    ["&YumikoSeki_Keyakizaka"] = "関 有美子",
    ["#YumikoSeki_Keyakizaka"] = "家具巨贾",
    ["~YumikoSeki_Keyakizaka"] = "生まれ変わってもまた欅坂46に入りたい",
    ["designer:YumikoSeki_Keyakizaka"] = "Cassimolar",
    ["cv:YumikoSeki_Keyakizaka"] = "関 有美子",
    ["illustrator:YumikoSeki_Keyakizaka"] = "Cassimolar",
    ["sakamichi_guan_ai"] = "关爱",
    [":sakamichi_guan_ai"] = "出牌阶段限一次，你可以令一名其他角色选择一种花色，然后你可以展示一张手牌并交给其，若此牌的花色与其选择的相同，你摸两张牌且此技能对本回合未成为过此技能目标的角色视为未曾发动。",
    ["@guan_ai"] = "%src选择了%arg，请选择一张手牌交给%src",
    ["sakamichi_hui_zhang"] = "会长",
    [":sakamichi_hui_zhang"] = "你的额定摸牌和手牌上限+1；当一名其他角色失去最后的手牌时，你可以摸一张牌并可以将一张手牌交给其。",
    ["@hui_zhang"] = "你可以将一张手牌交给%src",
}
