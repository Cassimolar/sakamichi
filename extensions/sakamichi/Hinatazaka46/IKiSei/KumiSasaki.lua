require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KumiSasaki_Hinatazaka = sgs.General(Sakamichi, "KumiSasaki_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "KumiSasaki_Hinatazaka")

--[[
    技能名：司会
    描述：当一张锦囊牌结算完成时，若因此牌体力值变化的量不小于两点，你可以摸X张牌并将至多X张牌交给因此牌体力值变化的角色（X为因此牌体力值变化的量）；当你使用锦囊牌造成伤害时/令一名其他角色回复体力时，你可以失去1点体力，防止此伤害/回复，并灵感目标回复1点体力/对目标造成1点伤害。
]]
Luasihui = sgs.CreateTriggerSkill {
    name = "Luasihui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpChanged, sgs.CardFinished, sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.HpChanged then
            local damage = data:toDamage()
            local recover = data:toRecover()
            if damage and damage.card and damage.card:isKindOf("TrickCard") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    room:addPlayerMark(p, damage.card:getId() .. "sihui_num", damage.damage)
                    room:setPlayerMark(player, p:objectName() .. "sihui_target", 1)
                end
            end
            if recover and recover.card and recover.card:isKindOf("TrickCard") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    room:addPlayerMark(p, recover.card:getId() .. "sihui_num", recover.recover)
                    room:setPlayerMark(player, p:objectName() .. "sihui_target", 1)
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("TrickCard") and not use.card:isKindOf("Nullification") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    local targets = sgs.SPlayerList()
                    for _, pl in sgs.qlist(room:getAlivePlayers()) do
                        if pl:getMark(p:objectName() .. "sihui_target") ~= 0 then
                            targets:append(pl)
                        end
                    end
                    if p:getMark(use.card:getId() .. "sihui_num") >= 2
                        and room:askForSkillInvoke(p, self:objectName(), data) then
                        room:drawCards(p, p:getMark(use.card:getId() .. "sihui_num"), self:objectName())
                        local n = p:getMark(use.card:getId() .. "sihui_num")
                        if not targets:isEmpty() then
                            while n >= 0 do
                                local ok = room:askForYiji(p, p:handCards(), self:objectName(), false, false, true, n,
                                    targets, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(),
                                        self:objectName(), nil), "@sihui_invoke:" .. use.card:objectName() .. "::" .. n,
                                    true)
                                n = n - p:getMark("sihui_num")
                                room:setPlayerMark(p, "sihui_num", 0)
                                if not ok then
                                    break
                                end
                            end
                        end
                        room:setPlayerMark(p, use.card:getId() .. "sihui_num", 0)
                    end
                    for _, pl in sgs.qlist(targets) do
                        room:setPlayerMark(pl, p:objectName() .. "sihui_target", 0)
                    end
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.to and move.to:getMark(move.from:objectName() .. "sihui_target") ~= 0
                and move.from:hasSkill(self) and move.from:objectName() == player:objectName()
                and move.reason.m_skillName == self:objectName()
                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                == sgs.CardMoveReason_S_REASON_GOTCARD then
                room:setPlayerMark(player, "sihui_num", move.card_ids:length())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Luasihui_part2 = sgs.CreateTriggerSkill {
    name = "#Luasihui_2",
    events = {sgs.DamageCaused, sgs.PreHpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("TrickCard") and player:hasSkill("Luasihui") then
                if damage.to:hasFlag(damage.card:getId() .. "sihui_card") then
                    room:setPlayerFlag(damage.to, "-" .. damage.card:getId() .. "sihui_card")
                elseif room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
                    "sihui_damage:" .. damage.to:objectName() .. "::" .. damage.card:objectName())) then
                    room:setPlayerFlag(damage.to, damage.card:getId() .. "sihui_card")
                    if damage.to:isWounded() then
                        room:recover(damage.to, sgs.RecoverStruct(player, damage.card, 1))
                    end
                    return true
                end
            end
        else
            local recover = data:toRecover()
            if recover.card and recover.card:isKindOf("TrickCard") and recover.who:hasSkill("Luasihui") then
                if player:hasFlag(recover.card:getId() .. "sihui_card") then
                    room:setPlayerFlag(player, "-" .. recover.card:getId() .. "sihui_card")
                elseif room:askForSkillInvoke(recover.who, self:objectName(), sgs.QVariant(
                    "sihui_recover:" .. player:objectName() .. "::" .. recover.card:objectName())) then
                    room:setPlayerFlag(player, recover.card:getId() .. "sihui_card")
                    room:damage(sgs.DamageStruct(recover.card, recover.who, player))
                    return true
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Sakamichi:insertRelatedSkills("Luasihui", "#Luasihui_2")
KumiSasaki_Hinatazaka:addSkill(Luasihui)
KumiSasaki_Hinatazaka:addSkill(Luasihui_part2)

--[[
    技能名：众谋
    描述：主公技，其他“けやき坂”或“日向坂46”的角色出牌阶段限一次，其可以将一张锦囊牌正面向上交给你。
]]
Luazhongmou = sgs.CreateTriggerSkill {
    name = "Luazhongmou$",
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.EventAcquireSkill, sgs.EventLoseSkill},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:hasSkill("Luazhongmou_give") then
                    room:attachSkillToPlayer(p, "Luazhongmou_give")
                end
            end
        elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
            local no_one_has_this_skill = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self) then
                    no_one_has_this_skill = false
                    break
                end
            end
            if no_one_has_this_skill then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:detachSkillFromPlayer(p, "Luazhongmou_give", true)
                end
            end
        end
        return false
    end,
}
Luazhongmou_giveCard = sgs.CreateSkillCard {
    name = "Luazhongmou_giveCard",
    skill_name = "Luazhongmou_give",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:hasSkill("Luazhongmou")
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:obtainCard(effect.to, card, true)
    end,
}
Luazhongmou_give = sgs.CreateOneCardViewAsSkill {
    name = "Luazhongmou_give&",
    attached_lord_skill = true,
    filter_pattern = "TrickCard",
    view_as = function(self, cards)
        local cd = Luazhongmou_giveCard:clone()
        cd:addSubcard(cards:getId())
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, target)
        return not target:hasUsed("#Luazhongmou_giveCard")
                   and (target:getKingdom() == "HiraganaKeyakizaka46" or target:getKingdom() == "Hinatazaka46")
    end,
}
-- KumiSasaki_Hinatazaka:addSkill(Luazhongmou)
-- if not sgs.Sanguosha:getSkill("Luazhongmou_give") then SKMC.SkillList:append(Luazhongmou_give) end

sgs.LoadTranslationTable {
    ["KumiSasaki_Hinatazaka"] = "佐々木 久美",
    ["&KumiSasaki_Hinatazaka"] = "佐々木 久美",
    ["#KumiSasaki_Hinatazaka"] = "日向擔當",
    ["designer:KumiSasaki_Hinatazaka"] = "Cassimolar",
    ["cv:KumiSasaki_Hinatazaka"] = "佐々木 久美",
    ["illustrator:KumiSasaki_Hinatazaka"] = "Cassimolar",
    ["Luasihui"] = "司会",
    [":Luasihui"] = "当一张锦囊牌结算完成时，若因此牌体力值变化的量不小于两点，你可以摸X张牌并将至多X张手牌交给因此牌体力值变化的角色（X为因此牌体力值变化的量）；当你使用锦囊牌造成伤害时/令一名其他角色回复体力时，你可以失去1点体力，防止此伤害/回复，并灵感目标回复1点体力/对目标造成1点伤害。",
    --	["Luazhongmou"] = "众谋",
    --	[":Luazhongmou"] = "主公技，<b><font color = #008000>其他“けやき坂”或“日向坂46”的角色出牌阶段限一次</font></b>，其可以将一张锦囊牌正面向上交给你。",
    ["@sihui_invoke"] = "你可以将至多%arg张手牌交给因此【%src】体力值变化的角色",
    ["#Luasihui_2:sihui_damage"] = "是否防止此【%arg】对%src造成的伤害并为其回复1点体力",
    ["#Luasihui_2:sihui_recover"] = "是否防止此【%arg】为%src回复的体力并对其造成1点伤害",
    ["#Luasihui_2"] = "司会",
    --	["Luazhongmou_give"] = "众谋",
    --	[":Luazhongmou_give"] = "出牌阶段限一次，你可以将一张锦囊牌正面向上交给【众谋】拥有者。",
}
