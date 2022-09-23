require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MikumoAndo = sgs.General(Sakamichi, "MikumoAndo", "Nogizaka46", 3, false)
SKMC.IKiSei.MikumoAndo = true
SKMC.SeiMeiHanDan.MikumoAndo = {
    name = {6, 18, 9, 12},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {27, "ji_xiong_hun_he"},
    ji_kaku = {21, "ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {45, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_xiang_nan = sgs.CreateTriggerSkill {
    name = "sakamichi_xiang_nan",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw then
            if not player:isSkipped(sgs.Player_Draw) then
                if player:askForSkillInvoke(self:objectName(), sgs.QVariant("draw2play")) then
                    SKMC.send_message(room, "#draw2play", player, nil, nil, nil, self:objectName())
                    change.to = sgs.Player_Play
                    data:setValue(change)
                end
            end
        elseif change.to == sgs.Player_Play then
            if not player:isSkipped(sgs.Player_Play) then
                if player:askForSkillInvoke(self:objectName(), sgs.QVariant("play2draw")) then
                    SKMC.send_message(room, "#play2draw", player, nil, nil, nil, self:objectName())
                    change.to = sgs.Player_Draw
                    data:setValue(change)
                end
            end
        end
        return false
    end,
}
MikumoAndo:addSkill(sakamichi_xiang_nan)

sakamichi_yuan_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_yuan_qi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Discard and math.abs(player:getHandcardNum() - player:getHp()) <= player:getMaxHp() then
            SKMC.send_message(room, "#yuan_qi", player, nil, nil, nil, self:objectName())
            player:skip(change.to)
        end
        return false
    end,
}
MikumoAndo:addSkill(sakamichi_yuan_qi)

sakamichi_yu_jia = sgs.CreateTriggerSkill {
    name = "sakamichi_yu_jia",
    frequency = sgs.Skill_Frequent,
    events = {sgs.FinishJudge},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        local card = judge.card
        local card_data = sgs.QVariant()
        card_data:setValue(card)
        if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@yu_jia_invoke",
                true, true)
            if target and target:objectName() ~= player:objectName() then
                room:obtainCard(target, card)
                room:drawCards(player, 1, self:objectName())
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            else
                room:obtainCard(player, card)
            end
        end
    end,
}
MikumoAndo:addSkill(sakamichi_yu_jia)

sgs.LoadTranslationTable {
    ["MikumoAndo"] = "安藤 美雲",
    ["&MikumoAndo"] = "安藤 美雲",
    ["#MikumoAndo"] = "元気っ子",
    ["~MikumoAndo"] = "",
    ["designer:MikumoAndo"] = "Cassimolar",
    ["cv:MikumoAndo"] = "安藤 美雲",
    ["illustrator:MikumoAndo"] = "Cassimolar",
    ["sakamichi_xiang_nan"] = "湘南",
    [":sakamichi_xiang_nan"] = "你可以将你的摸牌阶段视为出牌阶段，出牌阶段视为摸牌阶段执行。",
    ["sakamichi_xiang_nan:draw2play"] = "您是否想发动【湘南】将 摸牌阶段 视为 出牌阶段？",
    ["sakamichi_xiang_nan:play2draw"] = "您是否想发动【湘南】将 出牌阶段 视为 摸牌阶段？",
    ["#draw2play"] = "%from 发动【%arg】将<font color=\"yellow\"><b> 摸牌阶段 </b></font>视为<font color=\"yellow\"><b> 出牌阶段 </b></font>",
    ["#play2draw"] = "%from 发动【%arg】将<font color=\"yellow\"><b> 出牌阶段 </b></font>视为<font color=\"yellow\"><b> 摸牌阶段 </b></font>",
    ["sakamichi_yuan_qi"] = "元气",
    [":sakamichi_yuan_qi"] = "锁定技，若你的手牌数与体力值的差不大于你的体力上限，你跳过弃牌阶段。",
    ["#yuan_qi"] = "%from 的【%arg】被触发",
    ["sakamichi_yu_jia"] = "瑜伽",
    [":sakamichi_yu_jia"] = "当你的判定牌生效后，你可以令一名角色获得之，若其不为你，你可以摸一张牌然后弃一张牌。",
    ["@yu_jia_invoke"] = "你可以选择一名角色令其获得此张判定牌",
}
