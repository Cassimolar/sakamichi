require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenaMatsui = sgs.General(Sakamichi, "RenaMatsui", "Nogizaka46", 8, false)
SKMC.IKiSei.RenaMatsui = true
SKMC.SeiMeiHanDan.RenaMatsui = {
    name = {8, 4, 9, 8},
    ten_kaku = {12, "xiong"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_ji_la = sgs.CreateTriggerSkill {
    name = "sakamichi_ji_la",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local hp_max = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getHp() > player:getHp() then
                        hp_max = false
                        break
                    end
                end
                if hp_max then
                    local choice = room:askForChoice(player, self:objectName(), "hp+maxhp")
                    SKMC.choice_log(player, choice)
                    if choice == "hp" then
                        room:loseHp(player, SKMC.number_correction(player, 1))
                        SKMC.send_message(room, "#ji_la_hp", player, nil, nil, nil, self:objectName(), player:getHp())
                    else
                        room:loseMaxHp(player, SKMC.number_correction(player, 1))
                        SKMC.send_message(room, "#ji_la_maxhp", player, nil, nil, nil, self:objectName(),
                            player:getMaxHp())
                    end
                end
                return false
            elseif change.to == sgs.Player_Start then
                local hp_min = true
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if player:getHp() > p:getHp() then
                        hp_min = false
                        break
                    end
                end
                if hp_min then
                    room:setPlayerFlag(player, self:objectName())
                    SKMC.send_message(room, "#ji_la_vs", player, nil, nil, nil, self:objectName())
                end
                return false
            end
        elseif event == sgs.DamageCaused then
            if player:hasFlag(self:objectName()) then
                local damage = data:toDamage()
                if damage.chain or damage.transfer or not damage.by_user then
                    return false
                end
                if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
                    damage.damage = damage.damage + SKMC.number_correction(player, 1)
                    SKMC.send_message(room, "#ji_la_damage", player, damage.to, nil, damage.card:toString(),
                        self:objectName(), damage.damage)
                    data:setValue(damage)
                end
                return false
            end
        end
    end,
}
RenaMatsui:addSkill(sakamichi_ji_la)

sgs.LoadTranslationTable {
    ["RenaMatsui"] = "松井 玲奈",
    ["&RenaMatsui"] = "松井 玲奈",
    ["#RenaMatsui"] = "激辣剽勇",
    ["~RenaMatsui"] = "才能なんて誰にでも備わってるもの",
    ["designer:RenaMatsui"] = "Cassimolar",
    ["cv:RenaMatsui"] = "松井 玲奈",
    ["illustrator:RenaMatsui"] = "Cassimolar",
    ["sakamichi_ji_la"] = "激辣",
    [":sakamichi_ji_la"] = "锁定技，结束阶段，若你是全场体力最多的角色，你须失去1点体力或减少1点体力上限。准备阶段，若你是全场体力最少的角色，本回合内你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1。",
    ["sakamichi_ji_la:hp"] = "体力",
    ["sakamichi_ji_la:maxhp"] = "体力上限",
    ["#ji_la_hp"] = "%from 的【%arg】触发，%from 选择失去<font color=\"yellow\"><b>1</b></font>点体力，%from 现在的体力为 %arg2 点",
    ["#ji_la_maxhp"] = "%from 的【%arg】触发，%from 选择失去<font color=\"yellow\"><b>1</b></font>点体力上限，%from 现在的体力上限为 %arg2 点",
    ["#ji_la_vs"] = "%from 的【%arg】触发，本回合内 %from 使用的【<font color=\"yellow\"><b>杀</b></font>】或【<font color=\"yellow\"><b>决斗</b></font>】（ %from 为伤害来源时）造成的伤害+1。",
    ["#ji_la_damage"] = "%from 的【%arg】触发，此%card 对 %to 造成的伤害为 %arg2 点",
}
