require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SeiraHayakawa = sgs.General(Sakamichi, "SeiraHayakawa", "Nogizaka46", 4, false)
SKMC.YonKiSei.SeiraHayakawa = true
SKMC.SeiMeiHanDan.SeiraHayakawa = {
    name = {6, 3, 13, 7},
    ten_kaku = {9, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_sheng_tui = sgs.CreateFilterSkill {
    name = "sakamichi_sheng_tui",
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, to_select)
        return to_select:isKindOf("EquipCard") and sgs.Sanguosha:currentRoom():getCardPlace(to_select:getEffectiveId())
                   == sgs.Player_PlaceHand
    end,
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(cd)
        return new
    end,
}
sakamichi_sheng_tui_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_sheng_tui_distance",
    correct_func = function(self, from, to)
        if from:hasSkill("sakamichi_sheng_tui") then
            return -from:getLostHp()
        end
    end,
}
SeiraHayakawa:addSkill(sakamichi_sheng_tui)
if not sgs.Sanguosha:getSkill("#sakamichi_sheng_tui_distance") then
    SKMC.SkillList:append(sakamichi_sheng_tui_distance)
end
sakamichi_ye_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_ye_xin",
    events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.CardFinished, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getKingdom() == player:getKingdom() and p:objectName() ~= player:objectName() then
                    room:setPlayerFlag(p, "ye_xin_slash")
                    local target = sgs.QVariant()
                    target:setValue(player)
                    room:setTag("ye_xin", target)
                    if room:askForUseCard(p, "slash", "@askforslash") then
                        room:addSlashCishu(player, -SKMC.number_correction(p, 1))
                        SKMC.send_message(room, "#ye_xin_slash", p, player, nil, nil, self:objectName(),
                            SKMC.number_correction(p, 1))
                    end
                    if p:hasFlag("ye_xin_slash") then
                        room:setPlayerFlag(p, "-ye_xin_slash")
                    end
                    room:removeTag("ye_xin")
                end
            end
        elseif event == sgs.CardUsed then
            if player:hasFlag("ye_xin_slash") then
                room:setCardFlag(data:toCardUse().card, "ye_xin_slash")
                room:setPlayerFlag(player, "-ye_xin_slash")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("ye_xin_slash") then
                room:setCardFlag(use.card, "-ye_xin_slash")
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("ye_xin_slash") then
                local target = room:getTag("ye_xin"):toPlayer()
                local num
                if damage.from then
                    num = -SKMC.number_correction(damage.from, 1)
                else
                    num = -1
                end
                room:addMaxCards(target, num)
                SKMC.send_message(room, "#ye_xin_max", player, target, nil, damage.card:toString(), self:objectName(),
                    num)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}

SeiraHayakawa:addSkill(sakamichi_ye_xin)

sgs.LoadTranslationTable {
    ["SeiraHayakawa"] = "早川 聖来",
    ["&SeiraHayakawa"] = "早川 聖来",
    ["#SeiraHayakawa"] = "憨憨",
    ["~SeiraHayakawa"] = "聖来はお昼寝がした～い",
    ["designer:SeiraHayakawa"] = "Cassimolar",
    ["cv:SeiraHayakawa"] = "早川 聖来",
    ["illustrator:SeiraHayakawa"] = "Cassimolar",
    ["sakamichi_sheng_tui"] = "圣腿",
    [":sakamichi_sheng_tui"] = "锁定技，你手牌中的装备牌均视为【杀】；你计算与其他角色的距离-X（X为你已损失的体力值）。",
    ["sakamichi_ye_xin"] = "野心",
    [":sakamichi_ye_xin"] = "其他与你势力相同的角色出牌阶段开始时，你可使用一张【杀】，若如此做，本回合其使用【杀】的限制次数-1，若此【杀】造成伤害，本回合其手牌上限-1。",
    ["#ye_xin_slash"] = "%from 发动【%arg】使用了一张【杀】，本回合内%to 使用【杀】的限制次数-%arg2",
    ["#ye_xin_max"] = "%from 发动【%arg】使用了%card，%card造成了伤害，本回合内%to 手牌上限-%arg2",
}
