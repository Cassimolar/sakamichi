require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikaWatanabe_Keyakizaka = sgs.General(Sakamichi, "RikaWatanabe_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.RikaWatanabe_Keyakizaka = true
SKMC.SeiMeiHanDan.RikaWatanabe_Keyakizaka = {
    name = {12, 5, 11, 5},
    ten_kaku = {17, "ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

sakamichi_pei_yin_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_pei_yin",
    view_as = function()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_nullification = function(self, player)
        local room = sgs.Sanguosha:currentRoom()
        local top_card = sgs.Sanguosha:getCard(room:getDrawPile():first())
        return top_card:isKindOf("Nullification") and top_card:isRed()
    end,
}
sakamichi_pei_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_pei_yin",
    view_as_skill = sakamichi_pei_yin_view_as,
    events = {sgs.CardsMoveOneTime, sgs.BeforeCardsMove, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local pile = room:getDrawPile()
        if pile:isEmpty() then
            room:swapPile()
        end
        local id = pile:first()
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if move.from_places:contains(sgs.Player_DrawPile) or move.to_place == sgs.Player_DrawPile then
                    local players = sgs.SPlayerList()
                    players:append(p)
                    SKMC.fake_move(room, p, "&pei_yin", p:getMark("pei_yin"), false, self:objectName(), players)
                    if sgs.Sanguosha:getCard(p:getMark("pei_yin")):isBlack() then
                        room:removePlayerCardLimitation(player, "use,response", "" .. p:getMark("pei_yin"))
                    end
                    room:setPlayerMark(p, "pei_yin_1st", 0)
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("pei_yin_1st") == 0 then
                    local players = sgs.SPlayerList()
                    players:append(p)
                    SKMC.fake_move(room, p, "&pei_yin", id, true, self:objectName(), players)
                    if sgs.Sanguosha:getCard(id):isBlack() then
                        room:setPlayerCardLimitation(player, "use,response", "" .. id, false)
                    end
                    room:addPlayerMark(p, "pei_yin_1st")
                    room:setPlayerMark(p, "pei_yin", id)
                end
            end
        elseif event == sgs.PreCardUsed then
            if data:toCardUse().card:getId() == player:getMark("pei_yin") and player:hasSkill(self) then
                room:broadcastSkillInvoke(self:objectName())
                room:notifySkillInvoked(player, self:objectName())
            end
        end
        return false
    end,
}
RikaWatanabe_Keyakizaka:addSkill(sakamichi_pei_yin)

sakamichi_dai_meng = sgs.CreateTriggerSkill {
    name = "sakamichi_dai_meng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.StartJudge},
    on_trigger = function(self, event, player, data, room)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
        end
        return false
    end,
}
RikaWatanabe_Keyakizaka:addSkill(sakamichi_dai_meng)

sakamichi_jian_wang = sgs.CreateTriggerSkill {
    name = "sakamichi_jian_wang",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if player:getHandcardNum() ~= player:getHp() and room:askForSkillInvoke(player, self:objectName(), data) then
                local card = room:askForCard(player, ".|.|.|hand", "@jian_wang_invoke", data, sgs.Card_MethodNone, nil,
                    false, self:objectName(), false)
                if card then
                    room:moveCardsInToDrawpile(player, card, self:objectName(), 1, false)
                else
                    room:drawCards(player, 1, self:objectName())
                end
                local min, max = true, true
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getHandcardNum() > player:getHandcardNum() then
                        max = false
                    elseif p:getHandcardNum() < player:getHandcardNum() then
                        min = false
                    end
                end
                if min then
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Draw)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                end
                if max then
                    local thread = room:getThread()
                    player:setPhase(sgs.Player_Play)
                    room:broadcastProperty(player, "phase")
                    if not thread:trigger(sgs.EventPhaseStart, room, player) then
                        thread:trigger(sgs.EventPhaseProceeding, room, player)
                    end
                    thread:trigger(sgs.EventPhaseEnd, room, player)
                    player:setPhase(sgs.Player_Finish)
                    room:broadcastProperty(player, "phase")
                end
            end
        end
        return false
    end,
}
RikaWatanabe_Keyakizaka:addSkill(sakamichi_jian_wang)

sgs.LoadTranslationTable {
    ["RikaWatanabe_Keyakizaka"] = "渡辺 梨加",
    ["&RikaWatanabe_Keyakizaka"] = "渡辺 梨加",
    ["#RikaWatanabe_Keyakizaka"] = "大齡團寵",
    ["~RikaWatanabe_Keyakizaka"] = "わっしょい！やぁーー！",
    ["designer:RikaWatanabe_Keyakizaka"] = "Cassimolar",
    ["cv:RikaWatanabe_Keyakizaka"] = "渡辺 梨加",
    ["illustrator:RikaWatanabe_Keyakizaka"] = "Cassimolar",
    ["sakamichi_pei_yin"] = "配音",
    [":sakamichi_pei_yin"] = "牌堆顶的牌始终对你可见，若此牌为红色，你可以视为手牌使用或打出。",
    ["&pei_yin"] = "配音",
    ["sakamichi_dai_meng"] = "呆萌",
    [":sakamichi_dai_meng"] = "你的判定开始时，你可以摸一张牌。",
    ["sakamichi_jian_wang"] = "健忘",
    [":sakamichi_jian_wang"] = "结束阶段，若你的手牌数不等于体力值，你可以将一张手牌置于牌堆顶或摸一张牌，然后若你的手牌为：全场最少，你执行一个额外的摸牌阶段；全场最多，你执行一个额外的出牌阶段。",
    ["@jian_wang_invoke"] = "你可以将一张手牌置于牌堆顶，否则摸一张牌",
}
