require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikaWatanabe_Sakurazaka = sgs.General(Sakamichi, "RikaWatanabe_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.IKiSei.RikaWatanabe_Sakurazaka = true
SKMC.SeiMeiHanDan.RikaWatanabe_Sakurazaka = {
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

sakamichi_jue_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_jue_xing",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_ji_ji",
    events = {sgs.TurnedOver, sgs.ChainStateChanged, sgs.EventPhaseSkipped},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if (event == sgs.ChainStateChanged and player:isChained()) or event == sgs.TurnedOver or event
            == sgs.EventPhaseSkipped then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerMark(player, self:objectName(), 1)
        room:changeMaxHpForAwakenSkill(player, SKMC.number_correction(player, 1))
        room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
        room:handleAcquireDetachSkills(player, "sakamichi_ji_ji")
        return false
    end,
}
RikaWatanabe_Sakurazaka:addSkill(sakamichi_jue_xing)

sakamichi_ji_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_ji_ji",
    priority = 3,
    events = {sgs.StartJudge},
    on_trigger = function(self, event, player, data, room)
        if not player:isKongcheng() then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1,
                    targets, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                        self:objectName(), nil), "@ji_ji_invoke", false)
                if target then
                    local card = room:askForCard(target, ".|.|.|hand", "@ji_ji_top", data, sgs.Card_MethodNone, nil,
                        false, self:objectName(), false)
                    if card then
                        room:moveCardsInToDrawpile(target, card, self:objectName(), 1, false)
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
if not sgs.Sanguosha:getSkill("sakamichi_ji_ji") then
    SKMC.SkillList:append(sakamichi_ji_ji)
end

sakamichi_ying_ze = sgs.CreateTriggerSkill {
    name = "sakamichi_ying_ze",
    frequency = sgs.Skill_Frequent,
    events = {sgs.StartJudge},
    on_trigger = function(self, event, player, data, room)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:askForGuanxing(player, room:getNCards(player:getHp(), false), 1)
        end
        return false
    end,
}
RikaWatanabe_Sakurazaka:addSkill(sakamichi_ying_ze)

sakamichi_jian_kao = sgs.CreateTriggerSkill {
    name = "sakamichi_jian_kao",
    events = {sgs.StartJudge, sgs.FinishJudge},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.StartJudge then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:objectName(), data) then
                    local id = room:getNCards(1, false):first()
                    room:moveCardTo(sgs.Sanguosha:getCard(id), nil, nil, sgs.Player_PlaceTable, sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_TURNOVER, p:objectName(), self:objectName(), nil), true)
                    room:moveCardTo(sgs.Sanguosha:getCard(id), nil, nil, sgs.Player_DrawPile, sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_PUT, p:objectName(), nil, self:objectName(), nil), false)
                    room:setPlayerMark(player, "jian_kao", id)
                    room:setPlayerMark(p, "jian_kao_from" .. player:objectName(), 1)
                end
            end
        else
            local judge = data:toJudge()
            if player:getMark("jian_kao") ~= 0 then
                if player:getMark("jian_kao") ~= judge.card:getId() then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark("jian_kao_from" .. player:objectName()) ~= 0 then
                            room:damage(sgs.DamageStruct(self:objectName(), p, player, 1, sgs.DamageStruct_Thunder))
                            player:turnOver()
                            room:setPlayerMark(p, "jian_kao_from" .. player:objectName(), 0)
                        end
                    end
                end
                room:setPlayerMark(player, "jian_kao", 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RikaWatanabe_Sakurazaka:addSkill(sakamichi_jian_kao)

sgs.LoadTranslationTable {
    ["RikaWatanabe_Sakurazaka"] = "渡辺 梨加",
    ["&RikaWatanabe_Sakurazaka"] = "渡辺 梨加",
    ["#RikaWatanabe_Sakurazaka"] = "完美",
    ["~RikaWatanabe_Sakurazaka"] = "やればできる！",
    ["designer:RikaWatanabe_Sakurazaka"] = "Cassimolar",
    ["cv:RikaWatanabe_Sakurazaka"] = "渡辺 梨加",
    ["illustrator:RikaWatanabe_Sakurazaka"] = "Cassimolar",
    ["sakamichi_jue_xing"] = "觉醒",
    [":sakamichi_jue_xing"] = "觉醒技，当你翻面或横置或跳过任意阶段时，你增加1点体力上限并回复1点体力然后获得【积极】。",
    ["sakamichi_ji_ji"] = "积极",
    [":sakamichi_ji_ji"] = "其他角色的判定开始时，其可以将一张手牌交给你，然后你可以将一张手牌置于牌堆顶。",
    ["@ji_ji_invoke"] = "你可以将一张手牌交给【积极】的拥有者",
    ["@ji_ji_top"] = "你可以将一张手牌置于牌堆顶",
    ["sakamichi_ying_ze"] = "鹰择",
    [":sakamichi_ying_ze"] = "你的判定开始时，你可以观看牌堆顶X张牌，并可以任意顺序置于牌堆顶（X为你当前体力值）。",
    ["sakamichi_jian_kao"] = "监考",
    [":sakamichi_jian_kao"] = "其他角色的判定开始时，你可以翻开牌堆顶的一张牌，若其此次判断结果不为此牌，你对其造成1点雷电伤害并令其翻面。",
}
