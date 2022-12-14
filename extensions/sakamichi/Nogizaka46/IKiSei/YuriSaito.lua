require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuriSaito = sgs.General(Sakamichi, "YuriSaito", "Nogizaka46", 4, false)
SKMC.IKiSei.YuriSaito = true
SKMC.SeiMeiHanDan.YuriSaito = {
    name = {8, 18, 17, 7},
    ten_kaku = {26, "xiong"},
    jin_kaku = {35, "ji"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {50, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_kao_mo = sgs.CreateTriggerSkill {
    name = "sakamichi_kao_mo",
    events = {sgs.Damaged, sgs.EventPhaseStart, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:getPhase() ~= sgs.Player_NotActive then
                room:setPlayerMark(damage.to, "kao_mo_target", 1)
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            local kao_mo_targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("kao_mo_target") > 0 then
                    kao_mo_targets:append(p)
                end
            end
            if kao_mo_targets:length() > 0 then
                local kaomoFrom = room:findPlayersBySkillName(self:objectName())
                for _, p in sgs.qlist(kaomoFrom) do
                    if not p:isNude() then
                        local targets_list = sgs.SPlayerList()
                        for _, target in sgs.qlist(kao_mo_targets) do
                            if p:canSlash(target, nil, false) then
                                targets_list:append(target)
                            end
                        end
                        if not targets_list:isEmpty() then
                            if p:askForSkillInvoke(self:objectName(), data) then
                                room:askForUseSlashTo(p, targets_list, "@kao_mo_slash", false, false)
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    room:setPlayerMark(p, "kao_mo_target", 0)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuriSaito:addSkill(sakamichi_kao_mo)

AutisticGroup_di = sgs.CreateTriggerSkill {
    name = "AutisticGroup_di",
    events = {sgs.Damage, sgs.Damaged, sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            room:addPlayerMark(player, damage.to:objectName() .. "qun_di_minus_finish_end_clear",
                SKMC.number_correction(player, 1))
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from then
                room:addPlayerMark(damage.from, player:objectName() .. "qun_di_plus_finish_end_clear",
                    SKMC.number_correction(player, 1))
            end
        elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:distanceTo(p) == SKMC.number_correction(player, 1) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
AutisticGroup_di_distance = sgs.CreateDistanceSkill {
    name = "#AutisticGroup_di_distance",
    correct_func = function(self, from, to)
        return 0 - from:getMark(to:objectName() .. "qun_di_minus_finish_end_clear")
                   + from:getMark(to:objectName() .. "qun_di_plus_finish_end_clear")
    end,
}
YuriSaito:addSkill(AutisticGroup_di)
if not sgs.Sanguosha:getSkill("#AutisticGroup_di_distance") then
    SKMC.SkillList:append(AutisticGroup_di_distance)
end

sgs.LoadTranslationTable {
    ["YuriSaito"] = "?????? ??????",
    ["&YuriSaito"] = "?????? ??????",
    ["#YuriSaito"] = "????????????",
    ["~YuriSaito"] = "??? ??????????????????",
    ["designer:YuriSaito"] = "Cassimolar",
    ["cv:YuriSaito"] = "?????? ??????",
    ["illustrator:YuriSaito"] = "Cassimolar",
    ["sakamichi_kao_mo"] = "??????",
    [":sakamichi_kao_mo"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@kao_mo_slash"] = "???????????????????????????????????????",
    ["AutisticGroup_di"] = "??????",
    [":AutisticGroup_di"] = "????????????????????????????????????????????????????????????????????????-1?????????????????????????????????????????????????????????????????????????????????+1????????????????????????????????????????????????1??????????????????????????????",
}
