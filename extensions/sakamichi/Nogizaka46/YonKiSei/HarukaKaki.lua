require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HarukaKaki = sgs.General(Sakamichi, "HarukaKaki$", "Nogizaka46", 4, false)
SKMC.YonKiSei.HarukaKaki = true
SKMC.SeiMeiHanDan.HarukaKaki = {
    name = {12, 12, 12, 9},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {21, "ji"},
    sou_kaku = {45, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_chi_ze = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_ze$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@chi_ze",
    events = {sgs.EventPhaseProceeding, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Finish and player:hasSkill(self) and player:getMark("@chi_ze") ~= 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@chi_ze_invoke:::" .. self:objectName(), true)
                if target then
                    room:removePlayerMark(player, "@chi_ze", 1)
                    target:turnOver()
                    room:addPlayerMark(target, "&" .. self:objectName() .. "+ +_damage_start_start_clear",
                        SKMC.number_correction(player, 1))
                end
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getMark("&" .. self:objectName() .. "+ +_damage_start_start_clear") ~= 0 and damage.from
                and damage.from:getKingdom() == "Nogizaka46" then
                damage.damage = damage.damage
                                    + player:getMark("&" .. self:objectName() .. "+ +_damage_start_start_clear")
                data:setValue(damage)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HarukaKaki:addSkill(sakamichi_chi_ze)

sakamichi_bai_ya = sgs.CreateFilterSkill {
    name = "sakamichi_bai_ya",
    view_filter = function(self, to_select)
        return to_select:isBlack()
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName(self:objectName())
        new_card:setSuit(sgs.Card_NoSuit)
        new_card:setModified(true)
        return new_card
    end,
}
sakamichi_bai_ya_trigger = sgs.CreateTriggerSkill {
    name = "#sakamichi_bai_ya_trigger",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isBlack() and damage.to:hasSkill("sakamichi_bai_ya") then
            SKMC.send_message(room, "#bai_ya_damage", nil, damage.to, nil, damage.card:toString(), "sakamichi_bai_ya",
                SKMC.number_correction(damage.to, 1))
            damage.damage = damage.damage - SKMC.number_correction(damage.to, 1)
            data:setValue(damage)
            if damage.damage < 1 then
                SKMC.send_message(room, "#bai_ya_damage_nil", nil, damage.to, nil, damage.card:toString(),
                    "sakamichi_bai_ya")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HarukaKaki:addSkill(sakamichi_bai_ya)
if not sgs.Sanguosha:getSkill("#sakamichi_bai_ya_trigger") then
    SKMC.SkillList:append(sakamichi_bai_ya_trigger)
end

sakamichi_zha_nan = sgs.CreateTriggerSkill {
    name = "sakamichi_zha_nan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        local recover = data:toRecover()
        local target_list = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isWounded() then
                target_list:append(p)
            end
        end
        if not target_list:isEmpty() then
            local target = room:askForPlayerChosen(player, target_list, self:objectName(),
                "@zha_nan_invoke:::" .. recover.recover, true)
            if target then
                room:recover(target, sgs.RecoverStruct(player, recover.card, recover.recover))
            end
        end
        return false
    end,
}
HarukaKaki:addSkill(sakamichi_zha_nan)

sgs.LoadTranslationTable {
    ["HarukaKaki"] = "?????? ??????",
    ["&HarukaKaki"] = "?????? ??????",
    ["#HarukaKaki"] = "?????????",
    ["~HarukaKaki"] = "????????????????????????",
    ["designer:HarukaKaki"] = "Cassimolar",
    ["cv:HarukaKaki"] = "?????? ??????",
    ["illustrator:HarukaKaki"] = "Cassimolar",
    ["sakamichi_chi_ze"] = "??????",
    [":sakamichi_chi_ze"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????46???????????????????????????+1???",
    ["@chi_ze"] = "??????",
    ["@chi_ze_invoke"] = "??????????????????????????????????????????%arg???",
    ["_damage_start_start_clear"] = "?????????46??????+1",
    ["sakamichi_bai_ya"] = "??????",
    [":sakamichi_bai_ya"] = "???????????????????????????????????????????????????????????????????????????-1???",
    ["#bai_ya_damage"] = "%to??????%arg???????????????%card???%to???????????????-%arg2",
    ["#bai_ya_damage_nil"] = "%to??????%arg????????????,??????%card???%to???????????????",
    ["sakamichi_zha_nan"] = "??????",
    [":sakamichi_zha_nan"] = "??????????????????????????????????????????????????????????????????????????????",
    ["@zha_nan_invoke"] = "????????????????????????????????????%arg?????????",
}
