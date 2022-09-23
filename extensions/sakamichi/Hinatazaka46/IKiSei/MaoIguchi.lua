require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaoIguchi_Hinatazaka = sgs.General(Sakamichi, "MaoIguchi_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "MaoIguchi_Hinatazaka")

--[[
    技能名：脱节
    描述：锁定技，你始终跳过摸牌阶段；回合结束阶段，你可以观看牌堆顶的两张牌，然后将这些牌交给任意角色。
]]
Luatuojie = sgs.CreateTriggerSkill {
    name = "Luatuojie",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging, sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            local nextphase = change.to
            if nextphase == sgs.Player_Draw then
                player:skip(nextphase)
                return false
            elseif nextphase ~= sgs.Player_Finish then
                return false
            end
        elseif player:getPhase() == sgs.Player_Finish then
            local pl = sgs.SPlayerList()
            pl:append(player)
            local cards = room:getNCards(2, false)
            local move = sgs.CardsMoveStruct(cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
            local moves = sgs.CardsMoveList()
            moves:append(move)
            room:notifyMoveCards(true, moves, false, pl)
            room:notifyMoveCards(false, moves, false, pl)
            local ids = sgs.IntList()
            for _, id in sgs.qlist(cards) do
                ids:append(id)
            end
            while room:askForYiji(player, cards, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
                local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand,
                    sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(),
                        self:objectName(), nil))
                for _, id in sgs.qlist(ids) do
                    if room:getCardPlace(id) ~= sgs.Player_DrawPile then
                        move.card_ids:append(id)
                        cards:removeOne(id)
                    end
                end
                ids = sgs.IntList()
                for _, id in sgs.qlist(cards) do
                    ids:append(id)
                end
                local moves = sgs.CardsMoveList()
                moves:append(move)
                room:notifyMoveCards(true, moves, false, pl)
                room:notifyMoveCards(false, moves, false, pl)
                if not player:isAlive() then
                    return
                end
            end
            if not cards:isEmpty() then
                local move = sgs.CardsMoveStruct(cards, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
                local moves = sgs.CardsMoveList()
                moves:append(move)
                room:notifyMoveCards(true, moves, false, pl)
                room:notifyMoveCards(false, moves, false, pl)
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                for _, id in sgs.qlist(cards) do
                    dummy:addSubcard(id)
                end
                player:obtainCard(dummy, false)
            end
        end
        return false
    end,
}
MaoIguchi_Hinatazaka:addSkill(Luatuojie)

--[[
    技能名：闭馆
    描述：锁定技，当你受到至少两点雷电或无来源伤害后，你失去所有体力，在你脱离此次濒死前，其他角色无法使用【桃】。
]]
Luabiguan = sgs.CreateTriggerSkill {
    name = "Luabiguan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged, sgs.QuitDying, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from == nil or (damage.damage >= 2 and damage.nature == sgs.DamageStruct_Thunder) then
                room:setPlayerFlag(player, "biguan")
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:setPlayerCardLimitation(p, "use", "Peach", false)
                end
                room:loseHp(player, player:getHp())
                room:setPlayerFlag(player, "-biguan")
            end
        else
            local who
            if event == sgs.QuitDying then
                local dying = data:toDying()
                if dying.who:objectName() == player:objectName() and player:hasFlag("biguan") then
                    who = player
                end
            else
                local death = data:toDeath()
                if death.who:objectName() == player:objectName() and player:hasFlag("biguan") then
                    who = player
                end
            end
            for _, p in sgs.qlist(room:getOtherPlayers(who)) do
                room:removePlayerCardLimitation(p, "use", "Peach$0")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self)
    end,
}
MaoIguchi_Hinatazaka:addSkill(Luabiguan)

--[[
    技能名：褪蓝
    描述：限定技，当你处于濒死状态时，你可以选择一名其他角色，其获得你所有牌，若如此做，你失去【脱节】和【闭馆】并将势力改为“自闭群”，然后你摸三张牌并增加1点体力上限，然后你将体力回复至4点，若此角色势力为“けやき坂46”或“日向坂46”，你获得【宣蓝】。
]]
Luatuilan = sgs.CreateTriggerSkill {
    name = "Luatuilan",
    frequency = sgs.Skill_Limited,
    limit_mark = "@tuilan",
    events = {sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() and player:getMark("@tuilan") ~= 0 then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@tuilan_invoke", true, true)
            if target then
                player:loseMark("@tuilan")
                local card_ids = player:getEquipsId()
                if not player:isKongcheng() then
                    for _, id in sgs.qlist(player:handCards()) do
                        card_ids:append(id)
                    end
                end
                if not card_ids:isEmpty() then
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    dummy:addSubcards(card_ids)
                    target:obtainCard(dummy)
                    dummy:deleteLater()
                end
                room:handleAcquireDetachSkills(player, "-Luatuojie|-Luabiguan")
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("AutisticGroup"))
                room:drawCards(player, 3, self:objectName())
                room:gainMaxHp(player, 1)
                room:recover(player, sgs.RecoverStruct(player, nil, 4 - player:getHp()))
                if target:getKingdom() == "HiraganaKeyakizaka46" or target:getKingdom() == "Hinatazaka46" then
                    room:handleAcquireDetachSkills(player, "Luaxuanlan")
                end
            end
        end
        return false
    end,
}
MaoIguchi_Hinatazaka:addSkill(Luatuilan)

--[[
    技能名：宣蓝
    描述：当你受到伤害时，若伤害来源不为“けやき坂46”或“日向坂46”势力角色，你可以令一名势力为“けやき坂46”或“日向坂46”的角色摸一张牌。
]]
Luaxuanlan = sgs.CreateTriggerSkill {
    name = "Luaxuanlan",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local ok = false
        if not (damage.from
            and (damage.from:getKingdom() == "HiraganaKeyakizaka46" or damage.from:getKingdom() == "Hinatazaka46")) then
            ok = true
        end
        local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getKingdom() == "HiraganaKeyakizaka46" or p:getKingdom() == "Hinatazaka46" then
                targets:append(p)
            end
        end
        if ok and not targets:isEmpty() then
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "@xuanlan_invoke", true, true)
            if target then
                room:drawCards(target, 1, self:objectName())
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("Luaxuanlan") then
    SKMC.SkillList:append(Luaxuanlan)
end
MaoIguchi_Hinatazaka:addRelateSkill("Luaxuanlan")

sgs.LoadTranslationTable {
    ["MaoIguchi_Hinatazaka"] = "井口 眞緒",
    ["&MaoIguchi_Hinatazaka"] = "井口 眞緒",
    ["#MaoIguchi_Hinatazaka"] = "氛圍製造者",
    ["designer:MaoIguchi_Hinatazaka"] = "Cassimolar",
    ["cv:MaoIguchi_Hinatazaka"] = "井口 眞緒",
    ["illustrator:MaoIguchi_Hinatazaka"] = "Cassimolar",
    ["Luatuojie"] = "脱节",
    [":Luatuojie"] = "锁定技，你始终跳过摸牌阶段；回合结束阶段，你可以观看牌堆顶的两张牌，然后将这些牌交给任意角色。",
    ["Luabiguan"] = "闭馆",
    [":Luabiguan"] = "锁定技，当你受到至少两点雷电或无来源伤害后，你失去所有体力，在你脱离此次濒死前，其他角色无法使用【桃】。",
    ["Luatuilan"] = "褪蓝",
    [":Luatuilan"] = "限定技，当你处于濒死状态时，你可以选择一名其他角色，其获得你所有牌，若如此做，你失去【脱节】和【闭馆】并将势力改为“自闭群”，然后你摸三张牌并增加1点体力上限，然后你将体力回复至4点，若此角色势力为“けやき坂46”或“日向坂46”，你获得【宣蓝】。",
    ["@lan"] = "蓝",
    ["@tuilan_invoke"] = "你可以发动【褪蓝】令一名其他角色获得你的牌",
    ["Luaxuanlan"] = "宣蓝",
    [":Luaxuanlan"] = "当你受到伤害时，若伤害来源不为“けやき坂46”或“日向坂46”势力角色，你可以令一名势力为“けやき坂46”或“日向坂46”的角色摸一张牌。",
    ["@xuanlan_invoke"] = "你可以令一名势力为“けやき坂46”或“日向坂46”的角色摸一张牌",
}
