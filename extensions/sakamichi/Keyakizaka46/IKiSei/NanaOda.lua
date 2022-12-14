require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NanaOda = sgs.General(Sakamichi, "NanaOda", "Keyakizaka46", 4, false)
SKMC.IKiSei.NanaOda = true
SKMC.SeiMeiHanDan.NanaOda = {
    name = {18, 5, 8, 7},
    ten_kaku = {23, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {25, "ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

sakamichi_he_san = sgs.CreateTriggerSkill {
    name = "sakamichi_he_san",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() then
            room:drawCards(damage.from, 1, self:objectName())
            room:drawCards(player, 1, self:objectName())
            if damage.from:getHandcardNum() > damage.from:getHp() then
                room:askForUseCard(damage.from, "slash", "@askforslash")
            end
        end
    end,
}
NanaOda:addSkill(sakamichi_he_san)

sakamichi_guan_chaCard = sgs.CreateSkillCard {
    name = "sakamichi_guan_chaCard",
    skill_name = "sakamichi_guan_cha",
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:isMale() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:showAllCards(effect.to, effect.from)
        if room:askForSkillInvoke(effect.to, self:getSKillName(),
            sgs.QVariant("@guan_cha_invoke:" .. effect.from:objectName())) then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            slash:deleteLater()
            slash:setSkillName(self:getSkillName())
            room:setPlayerFlag(effect.from, "guan_cha")
            room:useCard(sgs.CardUseStruct(slash, effect.to, effect.from))
            if not effect.from:hasFlag("guan_cha") then
                room:drawCards(effect.from, 1, self:getSkillName())
            else
                if not effect.to:isKongcheng() then
                    room:setPlayerFlag(effect.from, "-guan_cha")
                    local card_id = room:askForCardChosen(effect.from, effect.to, "he", self:getSkillName(), false,
                        sgs.Card_MethodNone, sgs.IntList(), true)
                    room:obtainCard(effect.from, card_id, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
                end
            end
        end
    end,
}
sakamichi_guan_cha_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_guan_cha",
    view_as = function(self)
        return sakamichi_guan_chaCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_guan_chaCard")
    end,
}
sakamichi_guan_cha = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_cha",
    view_as_skill = sakamichi_guan_cha_view_as,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:hasFlag("guan_cha") then
                room:setPlayerFlag("-guan_cha")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanaOda:addSkill(sakamichi_guan_cha)

sgs.LoadTranslationTable {
    ["NanaOda"] = "?????? ??????",
    ["&NanaOda"] = "?????? ??????",
    ["#NanaOda"] = "??????",
    ["~NanaOda"] = "????????????????????????????????????",
    ["designer:NanaOda"] = "Cassimolar",
    ["cv:NanaOda"] = "?????? ??????",
    ["illustrator:NanaOda"] = "Cassimolar",
    ["sakamichi_he_san"] = "??????",
    [":sakamichi_he_san"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_guan_cha"] = "??????",
    [":sakamichi_guan_cha"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_guan_cha:@guan_cha_invoke"] = "??????????????????%src?????????????????????",
}
