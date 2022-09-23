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
    ["ShihoKato_HiraganaKeyakizaka"] = "加藤 史帆",
    ["&ShihoKato_HiraganaKeyakizaka"] = "加藤 史帆",
    ["#ShihoKato_HiraganaKeyakizaka"] = "糊涂蛋",
    ["~ShihoKato_HiraganaKeyakizaka"] = "へにょへにょ〜",
    ["designer:ShihoKato_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:ShihoKato_HiraganaKeyakizaka"] = "加藤 史帆",
    ["illustrator:ShihoKato_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_shi_tun"] = "识臀",
    [":sakamichi_shi_tun"] = "出牌阶段限一次，你可以选择一名有手牌的其他角色并选择一种花色，然后选择并展示其一张手牌，若此牌花色与你选择的：相同，你获得之，且本技能视为未曾发动；不同，你受到其造成的1点伤害。",
    ["sakamichi_man_yan"] = "慢言",
    [":sakamichi_man_yan"] = "锁定技，当你受到或造成伤害时，防止之，该受到伤害的角色的下个结束阶段，其失去等量的体力。",
    ["#man_yan"] = "%from 发动 %arg 防止对%to 造成的 %arg2 点伤害",
}
