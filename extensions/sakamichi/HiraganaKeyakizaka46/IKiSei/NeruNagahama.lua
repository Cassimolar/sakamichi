require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NeruNagahama_HiraganaKeyakizaka = sgs.General(Sakamichi, "NeruNagahama_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.IKiSei, "NeruNagahama_HiraganaKeyakizaka")

--[[
    技能名：特例
    描述：回合开始时/结束时，若你的势力为“欅坂46”/“けやき坂46”，你可以移动你判定区的一张牌/令一名角色的防具无效直到其的回合开始；锁定技，当你造成伤害后，将你的势力修改为“欅坂46”，并可以弃置场上一张牌；当你受到伤害后，将你的势力修改为“けやき坂46”，并可以令一名角色使用一张【杀】。
]]
Luateli = sgs.CreateTriggerSkill {
    name = "Luateli",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:hasSkill(self) and player:getPhase() == sgs.Player_Start and player:getKingdom() == "Keyakizaka46" then
                if not player:getJudgingArea():isEmpty() and room:askForSkillInvoke(player, self:objectName(), data) then
                    local id = room:askForCardChosen(player, player, "j", self:objectName())
                    local card = sgs.Sanguosha:getCard(id)
                    local place = room:getCardPlace(id)
                    local tos = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not player:isProhibited(p, card) and not p:containsTrick(card:objectName())
                            and p:hasJudgeArea() then
                            tos:append(p)
                        end
                    end
                    local to = room:askForPlayerChosen(player, tos, self:objectName(), "@teli1:::" .. card:objectName())
                    if to then
                        room:moveCardTo(card, player, to, place, sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), ""))
                    end
                end
            end
            if player:getMark("teli_armor") ~= 0 then
                room:removePlayerMark(player, "Armor_Nullified", player:getMark("teli_armor"))
                room:setPlayerMark(player, "teli_armor", 0)
            end
        elseif event == sgs.EventPhaseEnd then
            if player:hasSkill(self) and player:getPhase() == sgs.Player_Finish and player:getKingdom()
                == "HiraganaKeyakizaka46" then
                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@teli2",
                    true, true)
                if target then
                    room:addPlayerMark(target, "teli_armor", 1)
                    room:addPlayerMark(target, "Armor_Nullified", 1)
                end
            end
        elseif event == sgs.Damage then
            if player:hasSkill(self) then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("Keyakizaka46"))
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if not p:isAllNude() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@teli3", true, true)
                    if target then
                        local id = room:askForCardChosen(player, target, "hej", self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(id, target, player)
                    end
                end
            end
        elseif event == sgs.Damaged then
            if player:hasSkill(self) then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("HiraganaKeyakizaka46"))
                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@teli4",
                    true, true)
                if target then
                    room:askForUseCard(target, "slash", "@askforslash")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NeruNagahama_HiraganaKeyakizaka:addSkill(Luateli)

NeruNagahama_HiraganaKeyakizaka:addSkill("sakamichi_guan_tui")

--[[
    技能名：专任
    描述：限定技，当你回复体力后，若你的体力值已满，你可以对一名与你势力不同的角色造成等同于此次回复量的伤害，然后将你的武将牌替换成「等待百年 - 長濱 ねる」。
]]
Luazhuanren = sgs.CreateTriggerSkill {
    name = "Luazhuanren",
    frequency = sgs.Skill_Limited,
    limit_mark = "@zhuanren",
    events = {sgs.HpChanged},
    on_trigger = function(self, event, player, data, room)
        local recover = data:toRecover()
        if recover and not player:isWounded() and player:getMark("@zhuanren") ~= 0 then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:getKingdom() ~= p:getKingdom() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(),
                    "@zhuanren_invoke:::" .. recover.recover, true, true)
                if target then
                    player:loseMark("@zhuanren")
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, recover.recover,
                        sgs.DamageStruct_Normal))
                    local is_secondary_hero = not (sgs.Sanguosha:getGeneral(player:getGeneralName()):hasSkill(
                        self:objectName()))
                    room:changeHero(player, "NeruNagahama_Keyakizaka", false, true, is_secondary_hero, true)
                    local EX = sgs.Sanguosha:getTriggerSkill("sakamichi_chi_dao")
                    EX:trigger(sgs.GameStart, room, player, sgs.QVariant())
                end
            end
        end
        return false
    end,
}
NeruNagahama_HiraganaKeyakizaka:addSkill(Luazhuanren)

sgs.LoadTranslationTable {
    ["NeruNagahama_HiraganaKeyakizaka"] = "長濱 ねる",
    ["&NeruNagahama_HiraganaKeyakizaka"] = "長濱 ねる",
    ["#NeruNagahama_HiraganaKeyakizaka"] = "板藍根",
    ["designer:NeruNagahama_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:NeruNagahama_HiraganaKeyakizaka"] = "長濱 ねる",
    ["illustrator:NeruNagahama_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luateli"] = "特例",
    [":Luateli"] = "回合开始时/结束时，若你的势力为“欅坂46”/“けやき坂46”，你可以移动你判定区的一张牌/令一名角色的防具无效直到其的回合开始；锁定技，当你造成伤害后，将你的势力修改为“欅坂46”，并可以弃置场上一张牌；当你受到伤害后，将你的势力修改为“けやき坂46”，并可以令一名角色使用一张【杀】。",
    ["@teli1"] = "请选择移动此【%arg】的目标",
    ["@teli2"] = "你可以选择一名角色，令其在其回合开始前其防具无效",
    ["@teli3"] = "你可以选择一名角色弃置其一张牌",
    ["@teli4"] = "你可以选择一名角色令其可以使用一张【杀】",
    ["Luazhuanren"] = "专任",
    [":Luazhuanren"] = "限定技，当你回复体力后，若你的体力值已满，你可以对一名与你势力不同的角色造成等同于此次回复量的伤害，然后将你的武将牌替换成「等待百年 - 長濱 ねる」。",
    ["@zhuanren"] = "专任",
    ["@zhuanren_invoke"] = "你可以对一名势力与你不同的角色造成%arg点伤害",
}
