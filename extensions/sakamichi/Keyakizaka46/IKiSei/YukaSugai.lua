require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YukaSugai_Keyakizaka = sgs.General(Sakamichi, "YukaSugai_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.YukaSugai_Keyakizaka = true
SKMC.SeiMeiHanDan.YukaSugai_Keyakizaka = {
    name = {11, 4, 4, 9},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {8, "ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {28, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_qian_jin = sgs.CreateTriggerSkill {
    name = "sakamichi_qian_jin",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() then
                    local card1 = room:askForExchange(p, self:objectName(), p:distanceTo(player), p:distanceTo(player),
                        true, "@qian_jin:" .. player:objectName() .. "::" .. p:distanceTo(player), true)
                    if card1 then
                        room:obtainCard(player, card1, false)
                        local card2 = room:askForExchange(player, self:objectName(), player:distanceTo(p),
                            player:distanceTo(p), true, "@qian_jin:" .. p:objectName() .. "::" .. player:distanceTo(p),
                            true)
                        if card2 then
                            room:obtainCard(p, card2, false)
                        else
                            room:setPlayerFlag(player, "qian_jin" .. p:objectName())
                        end
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                local nullified_list = use.nullified_list
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:hasFlag("qian_jin" .. p:objectName()) then
                        table.insert(nullified_list, p:objectName())
                        room:drawCards(p, 1, self:objectName())
                    end
                end
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YukaSugai_Keyakizaka:addSkill(sakamichi_qian_jin)

sakamichi_ma_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_ma_shu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Horse") then
                room:drawCards(player, 1, self:objectName())
            end
        else
            local move = data:toMoveOneTime()
            if move.from and (move.from:objectName() == player:objectName())
                and move.from_places:contains(sgs.Player_PlaceEquip) then
                local i = 0
                for _, card_id in sgs.qlist(move.card_ids) do
                    if player:isAlive() and move.from_places:at(i) == sgs.Player_PlaceEquip
                        and sgs.Sanguosha:getCard(card_id):isKindOf("Horse") then
                        room:loseHp(player)
                        i = i + 1
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_ma_shu_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_ma_shu_distance",
    correct_func = function(self, from, to)
        if to:hasSkill("sakamichi_ma_shu") then
            return 1
        end
        if from:hasSkill("sakamichi_ma_shu") then
            return -1
        end
    end,
}
YukaSugai_Keyakizaka:addSkill(sakamichi_ma_shu)
if not sgs.Sanguosha:getSkill("#sakamichi_ma_shu_distance") then
    SKMC.SkillList:append(sakamichi_ma_shu_distance)
end

sgs.LoadTranslationTable {
    ["YukaSugai_Keyakizaka"] = "菅井 友香",
    ["&YukaSugai_Keyakizaka"] = "菅井 友香",
    ["#YukaSugai_Keyakizaka"] = "菅井樣",
    ["~YukaSugai_Keyakizaka"] = "私の腕筋なめんなよ！",
    ["designer:YukaSugai_Keyakizaka"] = "Cassimolar",
    ["cv:YukaSugai_Keyakizaka"] = "菅井 友香",
    ["illustrator:YukaSugai_Keyakizaka"] = "Cassimolar",
    ["sakamichi_qian_jin"] = "千金",
    [":sakamichi_qian_jin"] = "其他角色准备阶段，你可以交给其X张牌然后其需交给你Y张牌，否则本回合内其使用牌对你无效且你可以摸一张牌（X为你与其的距离，Y为其与你的距离）。",
    ["@qian_jin"] = "你可以交给%src%arg张牌",
    ["sakamichi_ma_shu"] = "马术",
    [":sakamichi_ma_shu"] = "锁定技，你计算与其他角色的距离-1，其他角色计算与你的距离+1；你使用坐骑牌时摸一张牌；当你失去装备区的坐骑牌时失去1点体力。",
    ["@mashu_discard"] = "你须弃置一张牌，否则将失去1点体力",
}
