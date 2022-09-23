require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikaOzeki_Sakurazaka = sgs.General(Sakamichi, "RikaOzeki_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.IKiSei.RikaOzeki_Sakurazaka = true
SKMC.SeiMeiHanDan.RikaOzeki_Sakurazaka = {
    name = {7, 14, 11, 9},
    ten_kaku = {21, "ji"},
    jin_kaku = {25, "ji"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {41, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_tun_ji_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_tun_ji",
    filter_pattern = ".|heart|.|.",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("amazing_grace", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}
sakamichi_tun_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_tun_ji",
    view_as_skill = sakamichi_tun_ji_view_as,
    events = {sgs.DrawNCards, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            local n = data:toInt()
            n = n + SKMC.number_correction(player, 2)
            data:setValue(n)
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Draw then
            local max = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() > player:getHandcardNum() then
                    max = false
                end
            end
            if max then
                room:loseHp(player, SKMC.number_correction(player, 1))
            end
        end
        return false
    end,
}
RikaOzeki_Sakurazaka:addSkill(sakamichi_tun_ji)

sakamichi_zhi_ren = sgs.CreateTriggerSkill {
    name = "sakamichi_zhi_ren",
    frequency = sgs.Skill_Wake,
    events = {sgs.EnterDying, sgs.DamageInflicted, sgs.PreHpLost, sgs.HpRecover, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and player:getMark(self:objectName()) == 0 then
                room:addPlayerMark(player, self:objectName())
                room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
                room:setPlayerMark(player, "zhi_ren", 1)
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getMark("zhi_ren") ~= 0 then
                if damage.nature == sgs.DamageStruct_Fire then
                    damage.damage = damage.damage + SKMC.number_correction(player, 1)
                    data:setValue(damage)
                else
                    return true
                end
            end
        elseif event == sgs.PreHpLost then
            if player:getMark("zhi_ren") ~= 0 then
                return true
            end
        elseif event == sgs.HpRecover then
            if not player:isWounded() and player:getMark("zhi_ren") ~= 0 then
                room:setPlayerMark(player, "zhi_ren", 0)
                room:handleAcquireDetachSkills(player, "sakamichi_qi_xing|sakamichi_shi_jiang")
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:isWounded() and player:getMark("zhi_ren") ~= 0 then
                room:recover(player, sgs.RecoverStruct(player, nil, 1))
            end
        end
        return false
    end,
}
RikaOzeki_Sakurazaka:addSkill(sakamichi_zhi_ren)

sgs.LoadTranslationTable {
    ["RikaOzeki_Sakurazaka"] = "尾関 梨香",
    ["&RikaOzeki_Sakurazaka"] = "尾関 梨香",
    ["#RikaOzeki_Sakurazaka"] = "限界突破",
    ["~RikaOzeki_Sakurazaka"] = "なんかそれも生え方かなって•••",
    ["designer:RikaOzeki_Sakurazaka"] = "Cassimolar",
    ["cv:RikaOzeki_Sakurazaka"] = "尾関 梨香",
    ["illustrator:RikaOzeki_Sakurazaka"] = "Cassimolar",
    ["sakamichi_tun_ji"] = "囤积",
    [":sakamichi_tun_ji"] = "摸牌阶段你的额定摸牌数+2。摸牌阶段结束时，若你的手牌数为全场最多，你失去1点体力。出牌阶段，你可以将一张红桃牌当【五谷丰登】使用。",
    ["sakamichi_zhi_ren"] = "纸人",
    [":sakamichi_zhi_ren"] = "觉醒技，当你进入濒死时，你将体力回复至1点，防止你受到的非火焰伤害和体力流失且受到的火焰伤害+1，直到你回复所有体力，在此期间，准备阶段你回复1点体力，你回复所有体力后获得【奇行】和【师匠】。",
}
