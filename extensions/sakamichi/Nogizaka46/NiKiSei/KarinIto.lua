require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KarinIto = sgs.General(Sakamichi, "KarinIto", "Nogizaka46", 3, false)
SKMC.NiKiSei.KarinIto = true
SKMC.SeiMeiHanDan.KarinIto = {
    name = {6, 18, 3, 2, 2},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {7, "ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_jiang_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_jiang_qi",
    events = {sgs.Damage, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            if player:hasSkill(self) and room:askForSkillInvoke(player, self:objectName()) then
                room:drawCards(player, 1, self:objectName())
                player:turnOver()
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Start then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:faceUp() then
                        if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                            "invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":"
                                .. SKMC.number_correction(p, 1))) then
                            room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
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
KarinIto:addSkill(sakamichi_jiang_qi)

sakamichi_you_neng = sgs.CreateTriggerSkill {
    name = "sakamichi_you_neng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local n = SKMC.number_correction(player, 1)
        if damage.damage >= n then
            for i = 1, damage.damage, n do
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local _player = sgs.SPlayerList()
                    _player:append(player)
                    local card_ids = room:getNCards(2, false)
                    local move = sgs.CardsMoveStruct(card_ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(),
                            nil))
                    local moves = sgs.CardsMoveList()
                    moves:append(move)
                    room:notifyMoveCards(true, moves, false, _player)
                    room:notifyMoveCards(false, moves, false, _player)
                    local you_neng_ids = sgs.IntList()
                    for _, id in sgs.qlist(card_ids) do
                        you_neng_ids:append(id)
                    end
                    while room:askForYiji(player, card_ids, self:objectName(), true, false, true, -1,
                        room:getAlivePlayers()) do
                        local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand,
                            sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW,
                                player:objectName(), self:objectName(), nil))
                        for _, id in sgs.qlist(you_neng_ids) do
                            if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                                move.card_ids:append(id)
                                card_ids:removeOne(id)
                            end
                        end
                        you_neng_ids = sgs.IntList()
                        for _, id in sgs.qlist(card_ids) do
                            you_neng_ids:append(id)
                        end
                        local moves = sgs.CardsMoveList()
                        moves:append(move)
                        room:notifyMoveCards(true, moves, false, _player)
                        room:notifyMoveCards(false, moves, false, _player)
                        if not player:isAlive() then
                            return
                        end
                    end
                    if not card_ids:isEmpty() then
                        local move = sgs.CardsMoveStruct(card_ids, nil, player, sgs.Player_PlaceTable,
                            sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW,
                                player:objectName(), self:objectName(), nil))
                        local moves = sgs.CardsMoveList()
                        moves:append(move)
                        room:notifyMoveCards(true, moves, false, _player)
                        room:notifyMoveCards(false, moves, false, _player)
                        local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        card:deleteLater()
                        card:addSubcards(card_ids)
                        room:obtainCard(player, card, false)
                    end
                end
            end
        end
        return false
    end,
}
KarinIto:addSkill(sakamichi_you_neng)

sgs.LoadTranslationTable {
    ["KarinIto"] = "伊藤 かりん",
    ["&KarinIto"] = "伊藤 かりん",
    ["#KarinIto"] = "女流棋士",
    ["~KarinIto"] = "振り飛車党",
    ["designer:KarinIto"] = "Cassimolar",
    ["cv:KarinIto"] = "伊藤 かりん",
    ["illustrator:KarinIto"] = "Cassimolar",
    ["sakamichi_jiang_qi"] = "将棋",
    [":sakamichi_jiang_qi"] = "当你造成伤害后，你可以摸两张牌并翻面。其他角色准备阶段，若你的武将牌背面向上，你可以对其造成1点伤害。",
    ["sakamichi_jiang_qi:invoke"] = "你可以发动【%arg】对%src 造成%arg2点伤害",
    ["sakamichi_you_neng"] = "有能",
    [":sakamichi_you_neng"] = "当你造成1点伤害后，你可以观看牌堆顶的两张牌，然后分配给任意角色。",
}
