require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikaSato = sgs.General(Sakamichi, "RikaSato", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.RikaSato = true
SKMC.SeiMeiHanDan.RikaSato = {
    name = {7, 18, 15, 8},
    ten_kaku = {25, "ji"},
    jin_kaku = {33, "te_shu_ge"},
    ji_kaku = {23, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {48, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_li_ke = sgs.CreateTriggerSkill {
    name = "sakamichi_li_ke",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:canDiscard(player, "hej") and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                    "invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. use.card:objectName())) then
                    local id = room:askForCardChosen(p, player, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
                    room:throwCard(id, player, p)
                    local no_offset_list = use.no_offset_list
                    for _, pl in sgs.qlist(use.to) do
                        table.insert(no_offset_list, pl:objectName())
                    end
                    use.no_offset_list = no_offset_list
                    data:setValue(use)
                    if p:objectName() == player:objectName() then
                        room:drawCards(p, 1, self:objectName())
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
RikaSato:addSkill(sakamichi_li_ke)

sakamichi_bian_cheng = sgs.CreateTriggerSkill {
    name = "sakamichi_bian_cheng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardFinished, sgs.EventPhaseProceeding, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                if not player:hasFlag("bian_cheng_not_draw") then
                    if use.card:getNumber() > player:getMark("bian_cheng_num_finish_end_clear") then
                        room:setPlayerMark(player, "bian_cheng_num_finish_end_clear", use.card:getNumber())
                        room:addPlayerMark(player, "bian_cheng_draw_finish_end_clear")
                    else
                        room:setPlayerFlag(player, "bian_cheng_not_draw")
                    end
                end
                if not player:hasFlag("bian_cheng_extra_turn") then
                    if player:getMark("bian_cheng_suit_finish_end_clear") == 0 then
                        if use.card:getSuit() == sgs.Card_Spade then
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 1)
                        end
                    elseif player:getMark("bian_cheng_suit_finish_end_clear") == 1 then
                        if use.card:getSuit() == sgs.Card_Heart then
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 2)
                        else
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 0)
                        end
                    elseif player:getMark("bian_cheng_suit_finish_end_clear") == 2 then
                        if use.card:getSuit() == sgs.Card_Club then
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 3)
                        else
                            room:setPlayerMark(player, "bian_cheng_suit_finish_end_clear", 0)
                        end
                    elseif player:getMark("bian_cheng_suit_finish_end_clear") == 3 then
                        if use.card:getSuit() == sgs.Card_Diamond then
                            room:setPlayerFlag(player, "bian_cheng_extra_turn")
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Finish then
                if not player:hasFlag("bian_cheng_not_draw") and player:getMark("bian_cheng_draw_finish_end_clear") ~= 0 then
                    room:drawCards(player, player:getMark("bian_cheng_draw_finish_end_clear"), self:objectName())
                end
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                if player:hasFlag("bian_cheng_extra_turn") then
                    room:setPlayerFlag(player, "-bian_cheng_extra_turn")
                    player:gainAnExtraTurn()
                end
            end
        end
        return false
    end,
}
RikaSato:addSkill(sakamichi_bian_cheng)

sakamichi_ming_chan = sgs.CreateTriggerSkill {
    name = "sakamichi_ming_chan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile
            and ((player:getPhase() == sgs.Player_Play and player:getMark(self:objectName() .. "_play_end_clear") == 0)
                or ((player:getPhase() == sgs.Player_Discard
                    and player:getMark(self:objectName() .. "_discard_end_clear") == 0)))
            and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
            == sgs.CardMoveReason_S_REASON_DISCARD then
            local suits = {}
            for _, id in sgs.qlist(move.card_ids) do
                if not suits[sgs.Sanguosha:getCard(id):getSuitString()] then
                    suits[sgs.Sanguosha:getCard(id):getSuitString()] = true
                end
            end
            local ids = sgs.IntList()
            for _, id in sgs.qlist(room:getDiscardPile()) do
                if not suits[sgs.Sanguosha:getCard(id):getSuitString()] then
                    ids:append(id)
                end
            end
            if not ids:isEmpty() then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setPlayerMark(player, self:objectName() .. "_" .. player:getPhaseString() .. "_end_clear", 1)
                    room:fillAG(ids)
                    while not ids:isEmpty() do
                        local remove_list = sgs.IntList()
                        local to_gain = room:askForAG(player, ids, false, "sakamichi_ming_chan")
                        if to_gain then
                            room:takeAG(player, to_gain, true)
                            remove_list:append(to_gain)
                            for _, id in sgs.qlist(ids) do
                                if sgs.Sanguosha:getCard(id):getSuit() == sgs.Sanguosha:getCard(to_gain):getSuit() then
                                    room:takeAG(nil, id, false)
                                    remove_list:append(id)
                                end
                            end
                        else
                            break
                        end
                        for _, id in sgs.qlist(remove_list) do
                            ids:removeOne(id)
                        end
                    end
                    room:clearAG()
                    room:broadcastInvoke("clearAG")
                end
            end
        end
        return false
    end,
}
RikaSato:addSkill(sakamichi_ming_chan)

sgs.LoadTranslationTable {
    ["RikaSato"] = "佐藤 璃果",
    ["&RikaSato"] = "佐藤 璃果",
    ["#RikaSato"] = "骇客少女",
    ["~RikaSato"] = "トキメキを大切に輝きたい",
    ["designer:RikaSato"] = "Cassimolar",
    ["cv:RikaSato"] = "佐藤 璃果",
    ["illustrator:RikaSato"] = "Cassimolar",
    ["sakamichi_li_ke"] = "理科",
    [":sakamichi_li_ke"] = "一名角色使用【杀】时，你可以弃置其一张牌令此【杀】不可响应，若该角色为你，你摸一张牌。",
    ["sakamichi_li_ke:invoke"] = "是否发动【%arg】弃置%src 一张牌令其使用的此【%arg2】无法响应",
    ["sakamichi_bian_cheng"] = "编程",
    [":sakamichi_bian_cheng"] = "结束阶段，若你本回合使用过的牌的点数严格递增，你可以摸X张牌（X为你本回合使用牌的数量）；若花色严格按照黑桃红桃梅花方块的顺序循环不小于一次，你执行一个额外的回合。",
    ["sakamichi_ming_chan"] = "名产",
    [":sakamichi_ming_chan"] = "<font color=\"green\"><b>出牌阶段和弃牌阶段各限一次</b></font>，当你的牌因弃置进入弃牌堆后，你可以从弃牌堆选择并获得与弃置牌花色均不相同的牌各一张。",
}
