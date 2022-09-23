require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HikariEndo = sgs.General(Sakamichi, "HikariEndo", "Keyakizaka46", 3, false, true)
SKMC.NiKiSei.HikariEndo = true
SKMC.SeiMeiHanDan.HikariEndo = {
    name = {13, 18, 6, 10},
    ten_kaku = {31, "da_ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {23, "ji"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_jie_wu = sgs.CreateTriggerSkill {
    name = "sakamichi_jie_wu",
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and card:isKindOf("Jink") then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:canSlash(p, nil, false) then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                room:askForUseSlashTo(player, targets, "@jie_wu_slash", false)
            end
        end
        return false
    end,
}
HikariEndo:addSkill(sakamichi_jie_wu)

sakamichi_leng_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_leng_yan",
    events = {sgs.BeforeCardsMove, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if move.from and move.from:getPhase() == sgs.Player_NotActive and move.from:hasSkill(self)
                and move.from_places:contains(sgs.Player_PlaceHand) then
                for _, id in sgs.qlist(move.card_ids) do
                    if room:getCardPlace(id) == sgs.Player_PlaceHand then
                        room:addPlayerMark(room:findPlayerByObjectName(move.from:objectName()), "leng_yan_num")
                    end
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("leng_yan_num") ~= 0 then
                    if p:getMark("leng_yan_num") >= 2
                        and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("damage:" .. player:objectName())) then
                        room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
                    end
                    room:setPlayerMark(p, "leng_yan_num", 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HikariEndo:addSkill(sakamichi_leng_yan)

sgs.LoadTranslationTable {
    ["HikariEndo"] = "遠藤 光莉",
    ["&HikariEndo"] = "遠藤 光莉",
    ["#HikariEndo"] = "怕生全开",
    ["~HikariEndo"] = "走り方な忘れちゃいました",
    ["designer:HikariEndo"] = "Cassimolar",
    ["cv:HikariEndo"] = "遠藤 光莉",
    ["illustrator:HikariEndo"] = "Cassimolar",
    ["sakamichi_jie_wu"] = "街舞",
    [":sakamichi_jie_wu"] = "当你使用或打出一张【闪】时，你可以使用一张无距离限制的【杀】。",
    ["@jie_wu_slash"] = "你可以使用一张无距离限制的【杀】",
    ["sakamichi_leng_yan"] = "冷言",
    [":sakamichi_leng_yan"] = "当前角色回合结束时，若你于此回合内失去至少两张手牌，你可以对其造成1点伤害。",
    ["sakamichi_leng_yan:damage"] = "你可以对%src造成1点伤害",
}
