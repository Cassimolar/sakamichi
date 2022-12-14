require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SeiraHatanaka = sgs.General(Sakamichi, "SeiraHatanaka", "Nogizaka46", 3, false)
SKMC.IKiSei.SeiraHatanaka = true
SKMC.SeiMeiHanDan.SeiraHatanaka = {
    name = {10, 4, 11, 19},
    ten_kaku = {14, "xiong"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {30, "ji_xiong_hun_he"},
    soto_kaku = {29, "te_shu_ge"},
    sou_kaku = {44, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_bu_liang = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_liang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:hasSkill(self) and death.damage and death.damage.from
                and room:askForSkillInvoke(death.who, self:objectName(), data) then
                room:drawCards(death.damage.from, 3, self:objectName())
            end
        elseif event == sgs.Damage then
            if player:hasSkill(self) then
                local damage = data:toDamage()
                if damage.to:objectName() ~= player:objectName() and not damage.to:isAllNude() then
                    local card = room:askForCardChosen(player, damage.to, "hej", self:objectName())
                    local unhide = room:getCardPlace(card) ~= sgs.Player_PlaceHand
                    room:obtainCard(player, card, unhide)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SeiraHatanaka:addSkill(sakamichi_bu_liang)

sakamichi_bao_dan = sgs.CreateTriggerSkill {
    name = "sakamichi_bao_dan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local response = data:toCardResponse()
        if response.m_card:isKindOf("Jink") and room:askForSkillInvoke(player, self:objectName(), data) then
            room:askForUseCard(player, "Slash", "@askforslash")
        end
        return false
    end,
}
SeiraHatanaka:addSkill(sakamichi_bao_dan)

sgs.LoadTranslationTable {
    ["SeiraHatanaka"] = "?????? ??????",
    ["&SeiraHatanaka"] = "?????? ??????",
    ["#SeiraHatanaka"] = "????????????",
    ["~SeiraHatanaka"] = "??????????????????????????????",
    ["designer:SeiraHatanaka"] = "Cassimolar",
    ["cv:SeiraHatanaka"] = "?????? ??????",
    ["illustrator:SeiraHatanaka"] = "Cassimolar",
    ["sakamichi_bu_liang"] = "??????",
    [":sakamichi_bu_liang"] = "???????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_bao_dan"] = "??????",
    [":sakamichi_bao_dan"] = "?????????????????????????????????????????????????????????????????????",
}
