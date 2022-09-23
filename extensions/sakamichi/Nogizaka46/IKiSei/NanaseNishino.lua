require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NanaseNishino = sgs.General(Sakamichi, "NanaseNishino$", "Nogizaka46", 3, false)
SKMC.IKiSei.NanaseNishino = true
SKMC.SeiMeiHanDan.NanaseNishino = {
    name = {6, 11, 2, 19},
    ten_kaku = {17, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {25, "ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_ming_mei = sgs.CreateTriggerSkill {
    name = "sakamichi_ming_mei$",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:objectName() == player:objectName() and player:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("ming_mei_used" .. player:objectName()) == 0 and p:hasLordSkill(self)
                    and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                        "invoke:" .. player:objectName() .. "::" .. self:objectName())) then
                    room:addPlayerMark(p, "ming_mei_used" .. player:objectName(), 1)
                    room:recover(player, sgs.RecoverStruct(p, nil, 1))
                    room:drawCards(player, 2, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanaseNishino:addSkill(sakamichi_ming_mei)

sakamichi_qian_shui = sgs.CreateTriggerSkill {
    name = "sakamichi_qian_shui",
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    priority = 1,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
            local target = room:getTag("qian_shui_target"):toPlayer()
            room:removeTag("qian_shui_target")
            if target and target:isAlive() then
                target:gainAnExtraTurn()
            end
        elseif event == sgs.EventPhaseChanging and player:hasSkill(self) then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:turnOver()
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                        "@qian_shui_choice")
                    local _data = sgs.QVariant()
                    _data:setValue(target)
                    room:setTag("qian_shui_target", _data)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanaseNishino:addSkill(sakamichi_qian_shui)

sakamichi_yuan_lu = sgs.CreateDistanceSkill {
    name = "sakamichi_yuan_lu",
    correct_func = function(self, from, to)
        if to:hasSkill(self) then
            local m = from:getSeat()
            local n = to:getSeat()
            local l = 1
            for _, p in sgs.qlist(from:getAliveSiblings()) do
                l = l + 1
            end
            if m > n then
                return math.abs(math.abs(m - l - n) - math.abs(m - n))
            elseif n > m then
                return math.abs(math.abs(m + l - n) - math.abs(m - n))
            end
        end
    end,
}
NanaseNishino:addSkill(sakamichi_yuan_lu)

sgs.LoadTranslationTable {
    ["NanaseNishino"] = "西野 七瀬",
    ["&NanaseNishino"] = "西野 七瀬",
    ["#NanaseNishino"] = "光合成希望",
    ["~NanaseNishino"] = "勝ちたいならやれ、負けてもいいならやめろ！",
    ["designer:NanaseNishino"] = "Cassimolar",
    ["cv:NanaseNishino"] = "西野 七瀬",
    ["illustrator:NanaseNishino"] = "Cassimolar",
    ["sakamichi_ming_mei"] = "命美",
    [":sakamichi_ming_mei"] = "主公技，每名乃木坂46势力角色限一次，当其进入濒死时，你可以令其回复1点体力值并摸两张牌。",
    ["sakamichi_ming_mei:invoke"] = "是否发动对%src 发动【%arg】",
    ["sakamichi_qian_shui"] = "潜水",
    [":sakamichi_qian_shui"] = "结束阶段，你可以翻面，若如此做，你可以令一名其他角色在本回合结束后执行一个额外的回合。",
    ["@qian_shui_choice"] = "请选择一名其他角色令其进行一个额外的回合",
    ["sakamichi_yuan_lu"] = "远路",
    [":sakamichi_yuan_lu"] = "锁定技，其他角色计算与你的距离时总是选择较长路径。",
}
