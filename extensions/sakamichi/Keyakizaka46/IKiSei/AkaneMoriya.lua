require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkaneMoriya_Keyakizaka = sgs.General(Sakamichi, "AkaneMoriya_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.AkaneMoriya_Keyakizaka = true
SKMC.SeiMeiHanDan.AkaneMoriya_Keyakizaka = {
    name = {6, 9, 9},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {9, "xiong"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji",
    },
}

sakamichi_yan_li = sgs.CreateTriggerSkill {
    name = "sakamichi_yan_li",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseEnd, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, "yan_li_") and p:getMark(mark) ~= 0 then
                            for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                                if mark == "yan_li_" .. p:objectName() .. pl:objectName() .. "_start_start_clear"
                                    and not player:hasFlag("yan_li_damage_" .. pl:objectName()) then
                                    room:drawCards(p, 1, self:objectName())
                                    room:askForUseSlashTo(p, pl, "@yan_li_slash:" .. pl:objectName(), false)
                                end
                            end
                        end
                    end
                end
                if player:hasSkill(self) and room:askForSkillInvoke(player, self:objectName(), data) then
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                        "@yan_li_choice", true, false)
                    if target then
                        room:setPlayerMark(player, "yan_li_" .. player:objectName() .. target:objectName()
                            .. "_start_start_clear", 1)
                        room:setPlayerMark(player,
                            "&" .. self:objectName() .. target:getGeneralName() .. "_start_start_clear", 1)
                    end
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if player:objectName() == room:getCurrent():objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if mark == "yan_li_" .. p:objectName() .. damage.to:objectName() .. "_start_start_clear"
                            and not player:hasFlag("yan_li_damage_" .. damage.to:objectName()) then
                            room:setPlayerFlag(player, "yan_li_damage_" .. damage.to:objectName())
                        end
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
AkaneMoriya_Keyakizaka:addSkill(sakamichi_yan_li)

sakamichi_bu_fu = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_fu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PindianVerifying, sgs.Damaged, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if pindian.from:hasSkill(self) then
                pindian.from_number = 13
            end
            if pindian.to:hasSkill(self) then
                pindian.to_number = 13
            end
        else
            local damage = data:toDamage()
            local target
            if event == sgs.Damage then
                target = damage.to
            else
                target = damage.from
            end
            if target and target:isAlive() and player:canPindian(damage.from) then
                if player:pindianInt(target, self:objectName(), nil) == 1 then
                    if not target:isNude() then
                        local card_id = room:askForCardChosen(player, target, "he", self:objectName())
                        room:obtainCard(player, card_id, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
                    end
                end
            end
        end
        return false
    end,
}
AkaneMoriya_Keyakizaka:addSkill(sakamichi_bu_fu)

sgs.LoadTranslationTable {
    ["AkaneMoriya_Keyakizaka"] = "守屋 茜",
    ["&AkaneMoriya_Keyakizaka"] = "守屋 茜",
    ["#AkaneMoriya_Keyakizaka"] = "軍曹",
    ["~AkaneMoriya_Keyakizaka"] = "絶対負けません",
    ["designer:AkaneMoriya_Keyakizaka"] = "Cassimolar",
    ["cv:AkaneMoriya_Keyakizaka"] = "守屋 茜",
    ["illustrator:AkaneMoriya_Keyakizaka"] = "Cassimolar",
    ["sakamichi_yan_li"] = "严厉",
    [":sakamichi_yan_li"] = "结束阶段，你可以选择一名其他角色，直到你的下个准备阶段，若其他角色的未于其回合内对该角色造成伤害，你摸一张牌并可以对该角色使用一张【杀】。",
    ["@yan_li_choice"] = "你可以选择一名其他角色发动【严厉】",
    ["@yan_li_slash"] = "你可以对%src使用一张【杀】",
    ["@yan_li"] = "严厉",
    ["sakamichi_bu_fu"] = "不服",
    [":sakamichi_bu_fu"] = "锁定技，你的拼点牌点数始终为K。当你受到其他角色造成的伤害后/对其他角色造成伤害后，你可以与其拼点，若你赢，你可以获得其一张牌。",
}
