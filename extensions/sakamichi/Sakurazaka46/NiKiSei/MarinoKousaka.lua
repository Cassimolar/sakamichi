require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MarinoKousaka_Sakurazaka = sgs.General(Sakamichi, "MarinoKousaka_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.NiKiSei.MarinoKousaka_Sakurazaka = true
SKMC.SeiMeiHanDan.MarinoKousaka_Sakurazaka = {
    name = {8, 7, 8, 7, 2},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_pin_weiCard = sgs.CreateSkillCard {
    name = "sakamichi_pin_weiCard",
    skill_name = "sakamichi_pin_wei",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choices1 = {}
        if effect.to:hasEquipArea() then
            table.insert(choices1, "pin_wei_1=" .. effect.to:objectName())
        end
        if not (effect.to:hasWeaponArea() and effect.to:hasArmorArea() and effect.to:hasDefensiveHorseArea()
            and effect.to:hasOffensiveHorseArea() and effect.to:hasTreasureArea()) then
            table.insert(choices1, "pin_wei_2=" .. effect.to:objectName())
        end
        if room:askForChoice(effect.from, self:getSkillName(), table.concat(choices1, "+")) == "pin_wei_1="
            .. effect.to:objectName() then
            local choices2 = {}
            for i = 0, 4, 1 do
                if effect.to:hasEquipArea(i) then
                    table.insert(choices2, "pin_wei_throw_" .. i)
                end
            end
            local choice = room:askForChoice(effect.from, self:getSkillName(), table.concat(choices2, "+"))
            if choice == "pin_wei_throw_0" then
                effect.to:throwEquipArea(0)
            elseif choice == "pin_wei_throw_1" then
                effect.to:throwEquipArea(1)
            elseif choice == "pin_wei_throw_2" then
                effect.to:throwEquipArea(2)
            elseif choice == "pin_wei_throw_3" then
                effect.to:throwEquipArea(3)
            elseif choice == "pin_wei_throw_4" then
                effect.to:throwEquipArea(4)
            end
        else
            local choices2 = {}
            for i = 0, 4, 1 do
                if not effect.to:hasEquipArea(i) then
                    table.insert(choices2, "pin_wei_obtain_" .. i)
                end
            end
            local choice = room:askForChoice(effect.from, self:getSkillName(), table.concat(choices2, "+"))
            if choice == "pin_wei_obtain_0" then
                effect.to:obtainEquipArea(0)
            elseif choice == "pin_wei_obtain_1" then
                effect.to:obtainEquipArea(1)
            elseif choice == "pin_wei_obtain_2" then
                effect.to:obtainEquipArea(2)
            elseif choice == "pin_wei_obtain_3" then
                effect.to:obtainEquipArea(3)
            elseif choice == "pin_wei_obtain_4" then
                effect.to:obtainEquipArea(4)
            end
        end
        room:removePlayerMark(effect.from, "@pin_wei")
    end,
}
sakamichi_pin_wei_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_pin_wei",
    view_as = function()
        return sakamichi_pin_weiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@pin_wei") ~= 0
    end,
}
sakamichi_pin_wei = sgs.CreateTriggerSkill {
    name = "sakamichi_pin_wei",
    view_as_skill = sakamichi_pin_wei_view_as,
    frequency = sgs.Skill_Limited,
    limit_mark = "@pin_wei",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:getEquips():length() < player:getEquips():length()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(damage.from, 1, self:objectName())
            return true
        end
        return false
    end,
}
MarinoKousaka_Sakurazaka:addSkill(sakamichi_pin_wei)

sakamichi_qin_ding = sgs.CreateTriggerSkill {
    name = "sakamichi_qin_ding",
    frequency = sgs.Skill_Frequent,
    events = {sgs.GameStart, sgs.DrawNCards, sgs.CardsMoveOneTime, sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self) then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@qin_ding_choice")
                room:addPlayerMark(target, "qing_ding")
                room:addMaxCards(target, SKMC.number_correction(player, 1), false)
                room:setPlayerMark(player, self:objectName() .. target:objectName(), 1)
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. target:getGeneralName(), 1)
            end
        elseif event == sgs.DrawNCards then
            if player:getMark("qing_ding") ~= 0 then
                local n = data:toInt()
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark(self:objectName() .. player:objectName()) ~= 0 then
                        n = n + 1
                    end
                end
                data:setValue(n)
            end
        elseif event == sgs.CardsMoveOneTime then
            if player:getPhase() == sgs.Player_Discard and player:getMark("qing_ding") ~= 0 then
                local move = data:toMoveOneTime()
                if move.from and move.from:objectName() == player:objectName()
                    and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                    == sgs.CardMoveReason_S_REASON_DISCARD then
                    room:setPlayerFlag(player, "qin_ding_discard")
                end
            end
        elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
            if player:getMark("qin_ding") and not player:hasFlag("qin_ding_discard") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark(self:objectName() .. player:objectName()) ~= 0 then
                        room:drawCards(p, 1, self:objectName())
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
MarinoKousaka_Sakurazaka:addSkill(sakamichi_qin_ding)

sakamichi_zhen_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_zhen_yan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:askForUseCard(player, "slash", "@askforslash")
        end
        return false
    end,
}
MarinoKousaka_Sakurazaka:addSkill(sakamichi_zhen_yan)

sgs.LoadTranslationTable {
    ["MarinoKousaka_Sakurazaka"] = "幸阪 茉里乃",
    ["&MarinoKousaka_Sakurazaka"] = "幸阪 茉里乃",
    ["#MarinoKousaka_Sakurazaka"] = "才能开花",
    ["~MarinoKousaka_Sakurazaka"] = "蹴り飛ばしていい？",
    ["designer:MarinoKousaka_Sakurazaka"] = "Cassimolar",
    ["cv:MarinoKousaka_Sakurazaka"] = "幸阪 茉里乃",
    ["illustrator:MarinoKousaka_Sakurazaka"] = "Cassimolar",
    ["sakamichi_pin_wei"] = "品味",
    [":sakamichi_pin_wei"] = "当你受到伤害时，若伤害来源装备数少于你，你可以令其摸一张牌然后防止此伤害。限定技，出牌阶段，你可以废除/恢复一名角色的一个装备栏。",
    ["pin_wei_1"] = "废除%src一个装备栏",
    ["pin_wei_2"] = "恢复%src一个装备栏",
    ["pin_wei_throw_0"] = "武器栏",
    ["pin_wei_throw_1"] = "防具栏",
    ["pin_wei_throw_2"] = "进攻马",
    ["pin_wei_throw_3"] = "防御马",
    ["pin_wei_throw_4"] = "宝物栏",
    ["pin_wei_obtain_0"] = "武器栏",
    ["pin_wei_obtain_1"] = "防具栏",
    ["pin_wei_obtain_2"] = "进攻马",
    ["pin_wei_obtain_3"] = "防御马",
    ["pin_wei_obtain_4"] = "宝物栏",
    ["sakamichi_qin_ding"] = "钦定",
    [":sakamichi_qin_ding"] = "游戏开始时，你选择一名其他角色，该角色：摸牌阶段额外摸一张牌；结束阶段，若其于弃牌阶段内未弃牌，你摸一张牌；手牌上限+1。",
    ["sakamichi_zhen_yan"] = "真颜",
    [":sakamichi_zhen_yan"] = "你于回合外获得牌时，你可以使用一张【杀】。",
}
