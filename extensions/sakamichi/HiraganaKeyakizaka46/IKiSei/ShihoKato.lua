require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ShihoKato_HiraganaKeyakizaka = sgs.General(Sakamichi, "ShihoKato_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 4, false)
SKMC.IKiSei.ShihoKato_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.ShihoKato_HiraganaKeyakizaka = {
    name = {5, 18, 5, 6},
    ten_kaku = {23, "ji"},
    jin_kaku = {23, "ji"},
    ji_kaku = {11, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {34, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

sakamichi_shi_tunCard = sgs.CreateSkillCard {
    name = "sakamichi_shi_tunCard",
    skill_name = "sakamichi_shi_tun",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local suit = room:askForSuit(effect.from, "sakamichi_shi_tun")
        local id = room:askForCardChosen(effect.from, effect.to, "h", "sakamichi_shi_tun")
        room:showCard(effect.to, id)
        if sgs.Sanguosha:getCard(id):getSuit() == suit then
            room:obtainCard(effect.from, sgs.Sanguosha:getCard(id), false)
        else
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.to, effect.from,
                SKMC.number_correction(effect.from, 1)))
            room:setPlayerFlag(effect.from, "shi_tun_used")
        end
    end,
}
sakamichi_shi_tun = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_shi_tun",
    view_as = function()
        return sakamichi_shi_tunCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("shi_tun_used")
    end,
}
ShihoKato_HiraganaKeyakizaka:addSkill(sakamichi_shi_tun)

sakamichi_man_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_man_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused, sgs.EventPhaseProceeding, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused or event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local skill_owner
            if damage.from and damage.from:hasSKill(self) then
                skill_owner = damage.from
            elseif damage.to:hasSkill(self) then
                skill_owner = damage.to
            end
            if skill_owner then
                room:addPlayerMark(damage.to, "@man_yan_finishi_end_clear", damage.damage)
                SKMC.send_message(room, "#man_yan", skill_owner, damage.to, nil, nil, damage.damage)
                return true
            end
        elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
            if player:getMark("@man_yan_finishi_end_clear") ~= 0 then
                room:loseHp(player, player:getMark("@man_yan_finishi_end_clear"))
            end
        end
        return false
    end,
}
ShihoKato_HiraganaKeyakizaka:addSkill(sakamichi_man_yan)

sgs.LoadTranslationTable {
    ["ShihoKato_HiraganaKeyakizaka"] = "?????? ??????",
    ["&ShihoKato_HiraganaKeyakizaka"] = "?????? ??????",
    ["#ShihoKato_HiraganaKeyakizaka"] = "?????????",
    ["~ShihoKato_HiraganaKeyakizaka"] = "?????????????????????",
    ["designer:ShihoKato_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:ShihoKato_HiraganaKeyakizaka"] = "?????? ??????",
    ["illustrator:ShihoKato_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_shi_tun"] = "??????",
    [":sakamichi_shi_tun"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1????????????",
    ["sakamichi_man_yan"] = "??????",
    [":sakamichi_man_yan"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["#man_yan"] = "%from ?????? %arg ?????????%to ????????? %arg2 ?????????",
}
