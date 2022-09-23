require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YumiWakatsuki = sgs.General(Sakamichi, "YumiWakatsuki", "Nogizaka46", 4, false)
SKMC.IKiSei.YumiWakatsuki = true
SKMC.SeiMeiHanDan.YumiWakatsuki = {
    name = {8, 4, 7, 9},
    ten_kaku = {12, "xiong"},
    jin_kaku = {11, "ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {28, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_dou_hun = sgs.CreateTriggerSkill {
    name = "sakamichi_dou_hun",
    events = {sgs.TargetSpecified, sgs.TargetConfirmed},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (event == sgs.TargetSpecified and use.from:objectName() == player:objectName())
            or (event == sgs.TargetConfirmed and use.to:contains(player)) then
            if use.card:isKindOf("Duel") then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
YumiWakatsuki:addSkill(sakamichi_dou_hun)

sakamichi_kuai_zi_jun = sgs.CreateTriggerSkill {
    name = "sakamichi_kuai_zi_jun",
    frequency = sgs.Skill_Wake,
    wakeed_skills = "sakamichi_kou_ji",
    events = {sgs.EventPhaseStart},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPhase() == sgs.Player_Start and player:getMark("duel_damage") >= SKMC.number_correction(player, 3) then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName(), 1)
        room:handleAcquireDetachSkills(player, "sakamichi_kou_ji")
        return false
    end,
}
sakamichi_kuai_zi_jun_record = sgs.CreateTriggerSkill {
    name = "sakamichi_kuai_zi_jun_record",
    events = {sgs.Damage},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Duel") then
            room:addPlayerMark(player, "duel_damage", damage.damage)
        end
        return false
    end,
}
YumiWakatsuki:addSkill(sakamichi_kuai_zi_jun)
if not sgs.Sanguosha:getSkill("sakamichi_kuai_zi_jun_record") then
    SKMC.SkillList:append(sakamichi_kuai_zi_jun_record)
end

sakamichi_kou_ji_card = sgs.CreateSkillCard {
    name = "sakamichi_kou_jiCard",
    skill_name = "sakamichi_kou_ji",
    filter = function(self, targets, to_select)
        if #targets < 2 then
            local card = sgs.Sanguosha:cloneCard("duel", self:getSuit(), self:getNumber())
            card:deleteLater()
            card:addSubcard(self)
            card:setSkillName(self:getSkillName())
            return not to_select:isProhibited(sgs.Self, card)
        end
        return false
    end,
    on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:cloneCard("duel", self:getSuit(), self:getNumber())
        card:deleteLater()
        card:addSubcard(self)
        card:setSkillName(self:getSkillName())
        room:useCard(sgs.CardUseStruct(card, source, SKMC.table_to_SPlayerList(targets), true))
    end,
}
sakamichi_kou_ji = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_kou_ji",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_kou_ji_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#sakamichi_kou_jiCard")
    end,

}
if not sgs.Sanguosha:getSkill("sakamichi_kou_ji") then
    SKMC.SkillList:append(sakamichi_kou_ji)
end

sgs.LoadTranslationTable {
    ["YumiWakatsuki"] = "若月 佑美",
    ["&YumiWakatsuki"] = "若月 佑美",
    ["#YumiWakatsuki"] = "月少参上",
    ["~YumiWakatsuki"] = "我が輩は猫ではない。",
    ["designer:YumiWakatsuki"] = "Cassimolar",
    ["cv:YumiWakatsuki"] = "若月 佑美",
    ["illustrator:YumiWakatsuki"] = "Cassimolar",
    ["sakamichi_dou_hun"] = "斗魂",
    [":sakamichi_dou_hun"] = "当你成为【决斗】的目标后/使用【决斗】指定目标后，你可以摸一张牌。",
    ["sakamichi_kuai_zi_jun"] = "筷子君",
    [":sakamichi_kuai_zi_jun"] = "觉醒技，准备阶段，若你本局游戏内已使用【决斗】造成至少3点伤害，你获得【口技】",
    ["sakamichi_kou_ji"] = "口技",
    [":sakamichi_kou_ji"] = "出牌阶段限一次，你可以将一张手牌当【决斗】使用，你以此法使用的【决斗】可以额外指定一个目标。",
}
