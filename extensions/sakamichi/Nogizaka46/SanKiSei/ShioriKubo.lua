require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ShioriKubo = sgs.General(Sakamichi, "ShioriKubo", "Nogizaka46", 4, false)
SKMC.SanKiSei.ShioriKubo = true
SKMC.SeiMeiHanDan.ShioriKubo = {
    name = {3, 9, 5, 14, 7},
    ten_kaku = {12, "xiong"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {26, "xiong"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_bo_ai = sgs.CreateTriggerSkill {
    name = "sakamichi_bo_ai",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("BasicCard") then
            local legal = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not use.to:contains(p) and not room:isProhibited(player, p, use.card) then
                    if use.card:targetFixed() then
                        if not use.card:isKindOf("Peach") or p:isWounded() then
                            legal:append(p)
                        end
                    else
                        if use.card:targetFilter(sgs.PlayerList(), p, player) then
                            legal:append(p)
                        end
                    end
                end
            end
            if not legal:isEmpty() then
                local extra_targets = sgs.SPlayerList()
                while not legal:isEmpty() and not player:isKongcheng() do
                    local target = room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1,
                        legal, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                            self:objectName(), nil), "@bo_ai_invoke:::" .. use.card:objectName(), true)
                    if target then
                        legal:removeOne(target)
                        extra_targets:append(target)
                    else
                        break
                    end
                end
                if not extra_targets:isEmpty() then
                    for _, p in sgs.qlist(extra_targets) do
                        use.to:append(p)
                    end
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}
ShioriKubo:addSkill(sakamichi_bo_ai)

sakamichi_shi_qu = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_qu",
    events = {sgs.CardUsed, sgs.HpChanged, sgs.CardFinished, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and player:objectName()
                == room:getCurrent():objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if not p:hasFlag("shi_qu_used") and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                        "invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. use.card:objectName())) then
                        local choices = {"0"}
                        for i = 1, room:getAlivePlayers():length(), 1 do
                            table.insert(choices, tostring(i))
                        end
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
                        local num = tonumber(choice)
                        SKMC.send_message(room, "#shi_qu_guess", p, player, nil, use.card:toString(), self:objectName(),
                            num)
                        room:setPlayerMark(p, "shi_qu_" .. use.card:getId(), num)
                        room:setPlayerFlag(p, "shi_qu_used")
                        room:setCardFlag(use.card, "shi_qu")
                    end
                end
            end
        elseif event == sgs.HpChanged then
            local damage = data:toDamage()
            local recover = data:toRecover()
            if damage and damage.card and damage.card:hasFlag("shi_qu") and damage.damage > 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("shi_qu_" .. damage.card:getId()) ~= 0 then
                        room:addPlayerMark(p, "shi_qu_record_" .. damage.card:getId(), 1)
                    end
                end
            end
            if recover and recover.card and recover.card:hasFlag("shi_qu") and recover.recover > 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("shi_qu_" .. recover.card:getId()) ~= 0 then
                        room:addPlayerMark(p, "shi_qu_record_" .. recover.card:getId(), 1)
                    end
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("shi_qu") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    local guess_num = p:getMark("shi_qu_" .. use.card:getId())
                    local record_num = p:getMark("shi_qu_record_" .. use.card:getId())
                    room:setPlayerMark(p, "shi_qu_" .. use.card:getId(), 0)
                    room:setPlayerMark(p, "shi_qu_record_" .. use.card:getId(), 0)
                    SKMC.send_message(room, "#shi_qu_record", player, nil, nil, use.card:toString(), record_num)
                    if guess_num == record_num then
                        SKMC.send_message(room, "#shi_qu_guess_right", p)
                        room:drawCards(p, record_num, self:objectName())
                    else
                        SKMC.send_message(room, "#shi_qu_guess_wrong", p)
                    end
                end
                room:setCardFlag(use.card, "-shi_qu")
            end
        elseif event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:hasFlag("shi_qu_used") then
                        room:setPlayerFlag(p, "-shi_qu_used")
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
ShioriKubo:addSkill(sakamichi_shi_qu)

sgs.LoadTranslationTable {
    ["ShioriKubo"] = "?????? ?????????",
    ["&ShioriKubo"] = "?????? ?????????",
    ["#ShioriKubo"] = "???????????????",
    ["~ShioriKubo"] = "?????????????????????????????????",
    ["designer:ShioriKubo"] = "Cassimolar",
    ["cv:ShioriKubo"] = "?????? ?????????",
    ["illustrator:ShioriKubo"] = "Cassimolar",
    ["sakamichi_bo_ai"] = "??????",
    [":sakamichi_bo_ai"] = "???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@bo_ai_invoke"] = "????????????????????????????????????????????????????????????????????????%arg??????????????????",
    ["sakamichi_shi_qu"] = "??????",
    [":sakamichi_shi_qu"] = "???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_shi_qu:invoke"] = "???????????????%arg????????????%src ????????????%arg2??????????????????????????????",
    ["#shi_qu_guess"] = "%from ?????????%arg????????????%to ?????????%card??????????????????????????????<font color\"Yellow\"><b>%arg2</b></font>???",
    ["#shi_qu_record"] = "???%from ?????????%card??????????????????????????????<font color\"Yellow\"><b>%arg</b></font>???",
    ["#shi_qu_guess_right"] = "%from ?????????",
    ["#shi_qu_guess_wrong"] = "%from ?????????",
}
