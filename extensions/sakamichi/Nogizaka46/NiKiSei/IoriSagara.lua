require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

IoriSagara = sgs.General(Sakamichi, "IoriSagara", "Nogizaka46", 3, false)
SKMC.NiKiSei.IoriSagara = true
SKMC.SeiMeiHanDan.IoriSagara = {
    name = {9, 13, 6, 18},
    ten_kaku = {22, "xiong"},
    jin_kaku = {19, "xiong"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {46, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "huo",
        san_sai = "xiong",
    },
}

sakamichi_ruan_meng = sgs.CreateTriggerSkill {
    name = "sakamichi_ruan_meng",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EnterDying, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                local count = 0
                for _, p in sgs.qlist(room:getAllPlayers(true)) do
                    if p:isDead() then
                        count = count + 1
                    end
                end
                if count
                    < math.floor(
                        room:alivePlayerCount() / SKMC.number_correction(player, 2) - SKMC.number_correction(player, 1)) then
                    room:recover(player,
                        sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1) - player:getHp()))
                end
            end
        elseif event == sgs.Death then
            room:addMaxCards(player, 1, false)
        end
        return false
    end,
}

IoriSagara:addSkill(sakamichi_ruan_meng)

sakamichi_chu_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_chu_xin",
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            room:addPlayerMark(player, "@chu_xin", 2)
            player:turnOver()
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                player:drawCards(1)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if player:getMark("@chu_xin") > 0 then
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
                        "extra_turn_invoke:::" .. self:objectName() .. ":" .. "@chu_xin")) then
                        room:removePlayerMark(player, "@chu_xin", 1)
                        SKMC.send_message(room, "#Fangquan", nil, player)
                        player:gainAnExtraTurn()
                    end
                end
            end
        end
        return false
    end,
}
IoriSagara:addSkill(sakamichi_chu_xin)

sgs.LoadTranslationTable {
    ["IoriSagara"] = "相楽 伊織",
    ["&IoriSagara"] = "相楽 伊織",
    ["#IoriSagara"] = "大型幼儿",
    ["~IoriSagara"] = "いや。分かるでしよ!",
    ["designer:IoriSagara"] = "Cassimolar",
    ["cv:IoriSagara"] = "相楽 伊織",
    ["illustrator:IoriSagara"] = "Cassimolar",
    [":sakamichi_ruan_meng"] = "锁定技，当你进入濒死时，若场上死亡角色数小于X/2-1（向下取整，X为场上角色数），你将体力值回复至1。当一名角色死亡时，你的手牌上限+1。",
    ["sakamichi_chu_xin"] = "初心",
    [":sakamichi_chu_xin"] = "游戏开始时，你获得两枚「初心」并翻面。回合开始时，你摸一张牌。回合结束时，你可以移除一枚「初心」执行一个额外回合。",
    ["@chu_xin"] = "初心",
    ["sakamichi_chu_xin:extra_turn_invoke"] = "你可以发动【%arg】弃置一枚“%arg2”获得一个额外的回合",
}
