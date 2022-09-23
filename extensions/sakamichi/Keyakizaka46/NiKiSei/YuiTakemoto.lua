require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiTakemoto_Keyakizaka = sgs.General(Sakamichi, "YuiTakemoto_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.NiKiSei.YuiTakemoto_Keyakizaka = true
SKMC.SeiMeiHanDan.YuiTakemoto_Keyakizaka = {
    name = {8, 4, 11, 6},
    ten_kaku = {12, "xiong"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_nao_ju = sgs.CreateTriggerSkill {
    name = "sakamichi_nao_ju",
    events = {sgs.EventPhaseSkipping},
    on_trigger = function(self, event, player, data, room)
        if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("skip:::" .. player:getPhaseString())) then
            local thread = room:getThread()
            player:setPhase(player:getPhase())
            room:broadcastProperty(player, "phase")
            if not thread:trigger(sgs.EventPhaseStart, room, player) then
                thread:trigger(sgs.EventPhaseProceeding, room, player)
            end
            thread:trigger(sgs.EventPhaseEnd, room, player)
            player:setPhase(sgs.Player_Finish)
            room:broadcastProperty(player, "phase")
        end
        return false
    end,
}
YuiTakemoto_Keyakizaka:addSkill(sakamichi_nao_ju)

sakamichi_jing_wu = sgs.CreateTriggerSkill {
    name = "sakamichi_jing_wu",
    events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if not player:hasFlag("jing_wu_used") and change.to ~= sgs.Player_RoundStart and change.to
                ~= sgs.Player_Start and change.to ~= sgs.Player_Finish and change.to ~= sgs.Player_NotActive then
                if not player:isSkipped(change.to)
                    and room:askForSkillInvoke(player, self:objectName(),
                        sgs.QVariant("skip:::" .. "jing_wu_" .. change.to)) then
                    room:setPlayerFlag(player, "jing_wu_used")
                    player:skip(change.to)
                end
            end
        else
            if player:getPhase() == sgs.Player_Finish and player:hasFlag("jing_wu_used") then
                if player:getHandcardNum() < player:getHp() then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not p:isAllNude() then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jing_wu_invoke",
                            true, true)
                        if target then
                            local card = room:askForCardChosen(player, target, "hej", self:objectName(), false,
                                sgs.Card_MethodDiscard)
                            room:throwCard(card, target, player)
                        end
                    end
                else
                    if player:canDiscard(player, "he") then
                        room:askForDiscard(player, self:objectName(), 1, 1, false, true)
                    end
                end
            end
        end
        return false
    end,
}
YuiTakemoto_Keyakizaka:addSkill(sakamichi_jing_wu)

sgs.LoadTranslationTable {
    ["YuiTakemoto_Keyakizaka"] = "武元 唯衣",
    ["&YuiTakemoto_Keyakizaka"] = "武元 唯衣",
    ["#YuiTakemoto_Keyakizaka"] = "唯一無二",
    ["~YuiTakemoto_Keyakizaka"] = "そういうヤツ無理やあ～",
    ["designer:YuiTakemoto_Keyakizaka"] = "Cassimolar",
    ["cv:YuiTakemoto_Keyakizaka"] = "武元 唯衣",
    ["illustrator:YuiTakemoto_Keyakizaka"] = "Cassimolar",
    ["sakamichi_nao_ju"] = "闹剧",
    [":sakamichi_nao_ju"] = "当你的一个阶段被跳过时，你可以执行一个额外的此阶段。",
    ["sakamichi_nao_ju:skip"] = "是否执行一个额外的%arg阶段",
    ["sakamichi_jing_wu"] = "劲舞",
    [":sakamichi_jing_wu"] = "<b><font color = #008000>每回合限一次</font></b>，你可以跳过除准备阶段和结束阶段外的一个阶段，若如此做，结束阶段若你的手牌数小于体力值你可以弃置场上一张牌，否则你须弃置一张牌。",
    ["@jing_wu_invoke"] = "你可以弃置场上一张牌",
    ["sakamichi_jing_wu:skip"] = "你可以跳过%arg",
    ["jing_wu_2"] = "判定阶段",
    ["jing_wu_3"] = "摸牌阶段",
    ["jing_wu_4"] = "出牌阶段",
    ["jing_wu_5"] = "弃牌阶段",
}