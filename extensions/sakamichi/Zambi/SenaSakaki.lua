require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SenaSakaki = sgs.General(Zambi, "SenaSakaki", "Zambi", 4, false)
table.insert(SKMC.NiKiSei, "SenaSakaki")

--[[
    技能名：好胜
    描述：当你进行以下操作前：判定/摸牌阶段摸牌/使用目标数多于一的牌，可以声明判定结果花色/摸得牌中一张牌的牌名/因此牌体力值变化的角色数，然后若结果与你声明的不同（分支2须展示摸到的牌），你可以修改判定结果的花色/弃置这些牌并摸等量的牌/对一名角色造成1点伤害。
]]
Luamasari = sgs.CreateTriggerSkill {
    name = "Luamasari",
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.StartJudge, sgs.AskForRetrial, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or event == sgs.EventAcquireSkill then
            room:handleAcquireDetachSkills(player, "#masari_spade|#masari_heart|#masari_club|#masari_diamond", false)
        elseif event == sgs.StartJudge and player:hasSkill(self)
            and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("masari-judge")) then
            room:setPlayerFlag(player, "masari")
            room:setPlayerFlag(player, "masari_" .. sgs.Card_Suit2String(room:askForSuit(player, self:objectName())))
        elseif event == sgs.AskForRetrial and player:hasSkill(self) then
            local judge = data:toJudge()
            if player:hasFlag("masari") and not player:hasFlag("masari_" .. sgs.Card_Suit2String(judge.card:getSuit())) then
                local choice = room:askForChoice(player, self:objectName(),
                    "masari_Spade+masari_Club+masari_Heart+masari_Diamond+cancel")
                local msg = sgs.LogMessage()
                msg.type = "#masari_judge_choice"
                msg.from = player
                msg.arg2 = judge.reason
                if choice == "masari_Spade" then
                    msg.arg = "spade"
                    room:setCardFlag(judge.card, "masari_spade")
                    local cardlists = sgs.CardList()
                    cardlists:append(judge.card)
                    room:filterCards(judge.who, cardlists, true)
                    judge:updateResult()
                elseif choice == "masari_Heart" then
                    msg.arg = "heart"
                    room:setCardFlag(judge.card, "masari_heart")
                    local cardlists = sgs.CardList()
                    cardlists:append(judge.card)
                    room:filterCards(judge.who, cardlists, true)
                    judge:updateResult()
                elseif choice == "masari_Club" then
                    msg.arg = "club"
                    room:setCardFlag(judge.card, "masari_club")
                    local cardlists = sgs.CardList()
                    cardlists:append(judge.card)
                    room:filterCards(judge.who, cardlists, true)
                    judge:updateResult()
                elseif choice == "masari_Diamond" then
                    msg.arg = "diamond"
                    room:setCardFlag(judge.card, "masari_diamond")
                    local cardlists = sgs.CardList()
                    cardlists:append(judge.card)
                    room:filterCards(judge.who, cardlists, true)
                    judge:updateResult()
                end
                room:sendLog(msg)
                if player:hasFlag("masari") then
                    room:setPlayerFlag(player, "-masari")
                end
                if player:hasFlag("masari_spade") then
                    room:setPlayerFlag(player, "-masari_spade")
                end
                if player:hasFlag("masari_heart") then
                    room:setPlayerFlag(player, "-masari_heart")
                end
                if player:hasFlag("masari_club") then
                    room:setPlayerFlag(player, "-masari_club")
                end
                if player:hasFlag("masari_diamond") then
                    room:setPlayerFlag(player, "-masari_diamond")
                end
            end
        elseif event == sgs.DrawNCards then
            if data:toInt() ~= 0 and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("masari-draw")) then
                local Patterns = {"BasicCard", "TrickCard", "EquipCard"}
                local BasicCard = {"slash", "jink", "peach"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                    table.insert(BasicCard, 2, "thunder_slash")
                    table.insert(BasicCard, 2, "fire_slash")
                    table.insert(BasicCard, 6, "analeptic")
                end
                local TrickCard = {"god_salvation", "amazing_grace", "savage_assault", "archery_attack", "collateral",
                    "ex_nihilo", "duel", "nullification", "snatch", "dismantlement"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                    table.insert(TrickCard, 11, "fire_attack")
                    table.insert(TrickCard, 12, "iron_chain")
                end
                local EquipCard = {"Weapon", "Armor", "Horse"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["limitation_broken"] then
                    table.insert(EquipCard, 4, "Treasure")
                end
                local Weapon = {"crossbow", "double_sword", "qinggang_sword", "blade", "spear", "axe", "halberd",
                    "kylin_bow"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["standard_ex_cards"] then
                    table.insert(Weapon, 9, "ice_sword")
                end
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                    table.insert(Weapon, 10, "guding_blade")
                    table.insert(Weapon, 11, "fan")
                end
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["sp_cards"] then
                    table.insert(Weapon, 12, "sp_moonspear")
                end
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["nostalgia"] then
                    table.insert(Weapon, 13, "moon_spear")
                end
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["SakamichiExclusiveCard"] then
                    table.insert(Weapon, 14, "_oto_ga_denai_gita")
                end
                local Armor = {"eight_diagram"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["standard_ex_cards"] then
                    table.insert(Armor, 2, "renwang_shield")
                end
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                    table.insert(Armor, 3, "vine")
                    table.insert(Armor, 4, "silver_lion")
                end
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["SakamichiExclusiveCard"] then
                    table.insert(Armor, 5, "seifuku_no_manekin")
                end
                local Horse = {"jueying", "dilu", "zhuahuangfeidian", "chitu", "dayuan", "zixing"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                    table.insert(Horse, 7, "hualiu")
                end
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["SakamichiExclusiveCard"] then
                    table.insert(Horse, 8, "hashire_baisukuru")
                    table.insert(Horse, 9, "hane_no_kioku_skill")
                end
                local Treasure = {"wooden_ox"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["SakamichiExclusiveCard"] then
                    table.insert(Treasure, 2, "yubi_boenkyo")
                end
                local choice1 = room:askForChoice(player, self:objectName(), table.concat(Patterns, "+"))
                local name
                if choice1 == "BasicCard" then
                    local choice2 = room:askForChoice(player, self:objectName(), table.concat(BasicCard, "+"))
                    name = choice2
                elseif choice1 == "TrickCard" then
                    local choice2 = room:askForChoice(player, self:objectName(), table.concat(TrickCard, "+"))
                    name = choice2
                else
                    local choice3 = room:askForChoice(player, self:objectName(), table.concat(EquipCard, "+"))
                    if choice3 == "Weapon" then
                        local choice4 = room:askForChoice(player, self:objectName(), table.concat(Weapon, "+"))
                        name = choice4
                    elseif choice3 == "Armor" then
                        local choice4 = room:askForChoice(player, self:objectName(), table.concat(Armor, "+"))
                        name = choice4
                    elseif choice3 == "Horse" then
                        local choice4 = room:askForChoice(player, self:objectName(), table.concat(Horse, "+"))
                        name = choice4
                    elseif choice3 == "Treasure" then
                        local choice4 = room:askForChoice(player, self:objectName(), table.concat(Treasure, "+"))
                        name = choice4
                    end
                end
                local msg = sgs.LogMessage()
                msg.type = "#masari_draw_choice"
                msg.from = player
                msg.arg = name
                room:sendLog(msg)
                local n = data:toInt()
                local card_ids = room:getNCards(n)
                local same = false
                for _, id in sgs.qlist(card_ids) do
                    if sgs.Sanguosha:getCard(id):objectName() == name then
                        same = true
                        break
                    end
                end
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                for _, id in sgs.qlist(card_ids) do
                    dummy:addSubcard(id)
                end
                player:obtainCard(dummy)
                for _, id in sgs.qlist(card_ids) do
                    room:showCard(player, id)
                end
                if not same then
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("masari_redraw")) then
                        room:throwCard(dummy, player, player)
                        dummy:deleteLater()
                        room:drawCards(player, n, self:objectName())
                    end
                end
                data:setValue(0)
            end
        end
        return false
    end,
}
Luamasari_part2 = sgs.CreateTriggerSkill {
    name = "#Luamasari_part2",
    events = {sgs.PreCardUsed, sgs.HpChanged, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed and player:hasSkill("Luamasari") then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and use.to:length() > 1 and use.from:objectName()
                == player:objectName()
                and room:askForSkillInvoke(player, "Luamasari", sgs.QVariant("masari_use:::" .. use.card:objectName())) then
                local targets = sgs.IntList()
                for i = 0, use.to:length(), 1 do
                    targets:append(i)
                end
                local choice = room:askForChoice(player, "Luamasari", table.concat(sgs.QList2Table(targets), "+"))
                local msg = sgs.LogMessage()
                msg.type = "#masari_use_choice"
                msg.from = player
                msg.arg = use.card:objectName()
                msg.arg2 = choice
                room:sendLog(msg)
                room:setPlayerMark(player, "masari_target_choice", choice)
                room:setCardFlag(use.card, "masari_card")
            end
        elseif event == sgs.HpChanged then
            local damage = data:toDamage()
            local recover = data:toRecover()
            if damage and damage.card and damage.card:hasFlag("masari_card") and damage.from:hasSkill("Luamasari")
                and damage.damage > 0 then
                damage.from:gainMark("masari_target")
            end
            if recover and recover.card and recover.card:hasFlag("masari_card") and recover.who:hasSkill("Luamasari")
                and recover.recover > 0 then
                recover.who:gainMark("masari_target")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:hasFlag("masari_card") and use.from and use.from:hasSkill("Luamasari") then
                if use.from:getMark("masari_target_choice") ~= use.from:getMark("masari_target") then
                    local target = room:askForPlayerChosen(use.from, room:getOtherPlayers(use.from), "Luamasari",
                        "@masari_use_target", true, false)
                    if target then
                        room:damage(sgs.DamageStruct("Luamasari", use.from, target, 1))
                    end
                end
                room:setPlayerMark(use.from, "masari_target_choice", 0)
                room:setPlayerMark(use.from, "masari_target", 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Zambi:insertRelatedSkills("Luamasari", "#Luamasari_part2")
SenaSakaki:addSkill(Luamasari)
SenaSakaki:addSkill(Luamasari_part2)

masari_spade = sgs.CreateFilterSkill {
    name = "#masari_spade",
    view_filter = function(self, to_select)
        return to_select:hasFlag("masari_spade")
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName("Luamasari")
        new_card:setSuit(sgs.Card_Spade)
        new_card:setNumber(card:getNumber())
        new_card:setModified(true)
        return new_card
    end,
}
if not sgs.Sanguosha:getSkill("#masari_spade") then
    SKMC.SkillList:append(masari_spade)
end

masari_heart = sgs.CreateFilterSkill {
    name = "#masari_heart",
    view_filter = function(self, to_select)
        return to_select:hasFlag("masari_heart")
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName("Luamasari")
        new_card:setSuit(sgs.Card_Heart)
        new_card:setNumber(card:getNumber())
        new_card:setModified(true)
        return new_card
    end,
}
if not sgs.Sanguosha:getSkill("#masari_heart") then
    SKMC.SkillList:append(masari_heart)
end

masari_club = sgs.CreateFilterSkill {
    name = "#masari_club",
    view_filter = function(self, to_select)
        return to_select:hasFlag("masari_club")
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName("Luamasari")
        new_card:setSuit(sgs.Card_Club)
        new_card:setNumber(card:getNumber())
        new_card:setModified(true)
        return new_card
    end,
}
if not sgs.Sanguosha:getSkill("#masari_club") then
    SKMC.SkillList:append(masari_club)
end

masari_diamond = sgs.CreateFilterSkill {
    name = "#masari_diamond",
    view_filter = function(self, to_select)
        return to_select:hasFlag("masari_diamond")
    end,
    view_as = function(self, card)
        local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
        new_card:setSkillName("Luamasari")
        new_card:setSuit(sgs.Card_Diamond)
        new_card:setNumber(card:getNumber())
        new_card:setModified(true)
        return new_card
    end,
}
if not sgs.Sanguosha:getSkill("#masari_diamond") then
    SKMC.SkillList:append(masari_diamond)
end

clear_masari_judge_card_flag = sgs.CreateTriggerSkill {
    name = "clear_masari_judge_card_flag",
    global = true,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        for _, id in sgs.qlist(move.card_ids) do
            if sgs.Sanguosha:getCard(id):hasFlag("masari_spade") then
                room:setCardFlag(sgs.Sanguosha:getCard(id), "-masari_spade")
            end
            if sgs.Sanguosha:getCard(id):hasFlag("masari_heart") then
                room:setCardFlag(sgs.Sanguosha:getCard(id), "-masari_heart")
            end
            if sgs.Sanguosha:getCard(id):hasFlag("masari_club") then
                room:setCardFlag(sgs.Sanguosha:getCard(id), "-masari_club")
            end
            if sgs.Sanguosha:getCard(id):hasFlag("masari_diamond") then
                room:setCardFlag(sgs.Sanguosha:getCard(id), "-masari_diamond")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("clear_masari_judge_card_flag") then
    SKMC.SkillList:append(clear_masari_judge_card_flag)
end

sgs.LoadTranslationTable {
    ["SenaSakaki"] = "榊 瀬奈",
    ["&SenaSakaki"] = "榊 瀬奈",
    ["#SenaSakaki"] = "褒め言葉",
    ["designer:SenaSakaki"] = "Cassimolar",
    ["cv:SenaSakaki"] = "寺田 蘭世",
    ["illustrator:SenaSakaki"] = "Cassimolar",
    ["Luamasari"] = "好胜",
    [":Luamasari"] = "当你进行以下操作前：判定/摸牌阶段摸牌/使用目标数多于一的牌，可以声明判定结果花色/摸得牌中一张牌的牌名/因此牌体力值变化的角色数，然后若结果与你声明的不同（分支2须展示要摸到的牌），你可以修改判定结果的花色/弃置这些牌并摸等量的牌/对一名角色造成1点伤害。",
    ["Luamasari:masari-judge"] = "是否发动【好胜】声明此次判定结果的花色",
    ["#masari_judge_choice"] = "%from 声明此%arg2 的判定花色为%arg",
    ["Luamasari:masari_Spade"] = "修改此判定结果为黑桃",
    ["Luamasari:masari_Club"] = "修改此判定结果为梅花",
    ["Luamasari:masari_Heart"] = "修改此判定结果为红桃",
    ["Luamasari:masari_Diamond"] = "修改此判定结果为方块",
    ["Luamasari:cancel"] = "不修改次判定结果",
    ["Luamasari:masari-draw"] = "是否发动【好胜】声明此次摸得牌中一张的牌名",
    ["Luamasari:Weapon"] = "武器牌",
    ["Luamasari:Armor"] = "防具牌",
    ["Luamasari:Horse"] = "坐骑牌",
    ["Luamasari:Treasure"] = "宝物牌",
    ["#masari_draw_choice"] = "%from 声明此次摸得牌中一张的牌名为：%arg",
    ["Luamasari:masari_redraw"] = "摸牌结果与声明不同是否弃置摸得的牌并摸取等量的牌",
    ["Luamasari:masari_use"] = "是否发动【好胜】声明因此【%arg】体力值变化的角色数",
    ["#masari_use_choice"] = "%from 声明因此【%arg】体力值变化的角色数为%arg2",
    ["@masari_use_target"] = "你可以对一名其他角色造成1点伤害",
}
