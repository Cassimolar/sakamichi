require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NeruNagahama_Keyakizaka = sgs.General(Sakamichi, "NeruNagahama_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.NeruNagahama_Keyakizaka = true
SKMC.SeiMeiHanDan.NeruNagahama_Keyakizaka = {
    name = {8, 17, 4, 3},
    ten_kaku = {25, "ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {7, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {31, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "xiong",
    },
}

sakamichi_chi_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_dao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.EventPhaseStart, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            room:setPlayerMark(player, self:objectName(), 2)
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive and player:getMark(self:objectName()) == 2 then
                -- player:skip(change.to)
                change.to = sgs.Player_NotActive
                data:setValue(change)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 1 then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant(
                    room:askForChoice(player, self:objectName(), "Keyakizaka46+HiraganaKeyakizaka46")))
                room:setPlayerMark(player, self:objectName(), 0)
                room:setPlayerFlag(player, "chi_dao")
                room:addAttackRange(player, player:getLostHp() + SKMC.number_correction(player, 2))
            elseif player:getPhase() == sgs.Player_NotActive and player:getMark(self:objectName()) == 2 then
                room:setPlayerMark(player, self:objectName(), 1)
            elseif player:getPhase() == sgs.Player_Play and player:hasFlag("chi_dao") then
                room:addSlashCishu(player, player:getLostHp() + SKMC.number_correction(player, 2))
            end
        elseif event == sgs.DrawNCards then
            local draw = data:toInt()
            if player:hasFlag("chi_dao") then
                data:setValue(draw + player:getLostHp() + SKMC.number_correction(player, 2))
            end
        end
        return false
    end,
}
NeruNagahama_Keyakizaka:addSkill(sakamichi_chi_dao)

sakamichi_guan_tui = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_tui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if player:getKingdom() == "Keyakizaka46" or player:getKingdom() == "HiraganaKeyakizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName()
                    and room:askForSkillInvoke(p, self:objectName(),
                        sgs.QVariant("@guan_tui_invoke:" .. player:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                    local card = room:askForCard(player, ".|.|.|hand!", "@guan_tui_give:" .. p:objectName(),
                        sgs.QVariant(), sgs.Card_MethodNone)
                    if card then
                        room:obtainCard(p, card, false)
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
NeruNagahama_Keyakizaka:addSkill(sakamichi_guan_tui)

sakamichi_meng_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_meng_yin",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.to:length() > 1 then
            local target = room:askForPlayerChosen(player, use.to, self:objectName(),
                "@meng_yin_choice:::" .. use.card:objectName(), true, true)
            if target then
                use.to:removeOne(target)
                data:setValue(use)
                room:damage(sgs.DamageStruct(self:objectName(), player, target, SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
NeruNagahama_Keyakizaka:addSkill(sakamichi_meng_yin)

sgs.LoadTranslationTable {
    ["NeruNagahama_Keyakizaka"] = "長濱 ねる",
    ["&NeruNagahama_Keyakizaka"] = "長濱 ねる",
    ["#NeruNagahama_Keyakizaka"] = "等待百年",
    ["~NeruNagahama_Keyakizaka"] = "8.6秒バズーカー",
    ["designer:NeruNagahama_Keyakizaka"] = "Cassimolar",
    ["cv:NeruNagahama_Keyakizaka"] = "長濱 ねる",
    ["illustrator:NeruNagahama_Keyakizaka"] = "Cassimolar",
    ["sakamichi_chi_dao"] = "迟到",
    [":sakamichi_chi_dao"] = "锁定技，跳过你的第一个回合；你的第二个回合开始时，你须将势力改为欅坂46或けやき坂46，本回合内：摸牌阶段你额外摸X张牌；出牌阶段你使用【杀】的限制次数+X；攻击范围+X（X为你已损失的体力值+2）。",
    ["sakamichi_guan_tui"] = "官推",
    [":sakamichi_guan_tui"] = "欅坂46或けやき坂46势力的角色造成伤害后，你可以令其摸一张牌然后交给你一张手牌。",
    ["sakamichi_guan_tui:@guan_tui_invoke"] = "是否令%src摸一张牌然后交给你一张手牌",
    ["@guan_tui_give"] = "请选择一张手牌交给%src",
    ["sakamichi_meng_yin"] = "萌音",
    [":sakamichi_meng_yin"] = "你使用目标多于一的卡牌时，你可以取消其中的一个目标，并对其造成1点伤害。",
    ["@meng_yin_choice"] = "你可以取消此%arg中的一个目标并对其造成1点伤害",
}
