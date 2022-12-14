require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MinamiUmezawa = sgs.General(Sakamichi, "MinamiUmezawa", "Nogizaka46", 4, false)
SKMC.SanKiSei.MinamiUmezawa = true
SKMC.SeiMeiHanDan.MinamiUmezawa = {
    name = {10, 16, 9, 8},
    ten_kaku = {26, "xiong"},
    jin_kaku = {25, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {43, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_shen_chang = sgs.CreateTriggerSkill {
    name = "sakamichi_shen_chang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.SlashProceed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(use.to) do
                    if player:distanceTo(p) > SKMC.number_correction(player, 1) then
                        if use.m_addHistory then
                            room:addPlayerHistory(player, use.card:getClassName(), -1)
                            break
                        end
                    end
                end
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasSkill(self) and effect.from:distanceTo(effect.to) == SKMC.number_correction(effect.from, 1) then
                room:slashResult(effect, nil)
                return true
            end
        end
        return false
    end,
}
MinamiUmezawa:addSkill(sakamichi_shen_chang)

sakamichi_shi_fu_card = sgs.CreateSkillCard {
    name = "sakamichi_shi_fuCard",
    skill_name = "sakamichi_shi_fu",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@shi_fu")
        room:drawCards(effect.from, effect.from:getLostHp(), self:getSkillName())
        room:addPlayerMark(effect.to, "Armor_Nullified")
        room:setPlayerFlag(effect.from, "shi_fu")
        room:setPlayerFlag(effect.from, "shi_fu_" .. effect.to:objectName())
    end,
}
sakamichi_shi_fu_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_shi_fu",
    view_as = function()
        return sakamichi_shi_fu_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@shi_fu") ~= 0
    end,
}
sakamichi_shi_fu = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_fu",
    frequency = sgs.Skill_Limited,
    limit_mark = "@shi_fu",
    view_as_skill = sakamichi_shi_fu_view_as,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if player:hasFlag("shi_fu") then
                local refresh = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if player:hasFlag("shi_fu_" .. p:objectName()) then
                        room:setPlayerFlag(player, "-shi_fu_" .. p:objectName())
                        room:removePlayerMark(p, "Armor_Nullified")
                        refresh = false
                    end
                end
                if refresh then
                    room:setPlayerMark(player, "@shi_fu", 1)
                end
                room:setPlayerFlag(player, "-shi_fu")
            end
        end
        return false
    end,
}
MinamiUmezawa:addSkill(sakamichi_shi_fu)

sgs.LoadTranslationTable {
    ["MinamiUmezawa"] = "?????? ??????",
    ["&MinamiUmezawa"] = "?????? ??????",
    ["#MinamiUmezawa"] = "??????",
    ["~MinamiUmezawa"] = "??????????????????????????????????????????",
    ["designer:MinamiUmezawa"] = "Cassimolar",
    ["cv:MinamiUmezawa"] = "?????? ??????",
    ["illustrator:MinamiUmezawa"] = "Cassimolar",
    ["sakamichi_shen_chang"] = "??????",
    [":sakamichi_shen_chang"] = "????????????????????????????????????1??????????????????????????????????????????????????????????????????1???????????????????????????????????????",
    ["sakamichi_shi_fu"] = "??????",
    [":sakamichi_shi_fu"] = "???????????????????????????????????????X?????????????????????????????????????????????????????????X???????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@shi_fu"] = "??????",
}
