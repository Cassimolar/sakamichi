require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiKanemura = sgs.General(Zambi, "YuiKanemura", "Zambi", 5, false)
table.insert(SKMC.SanKiSei, "YuiKanemura")

--[[
    技能名：蔑视
    描述：你对体力值不大于你/攻击范围内不包含你的角色使用【杀】时无视距离和防具，当你使用【杀】指定体力值不大于你/攻击范围内不包含你的角色为目标时，你可以选择一名其他角色成为此【杀】的额外目标。
]]
Luamikudasu = sgs.CreateTriggerSkill {
    name = "Luamikudasu",
    events = {sgs.CardUsed, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Slash") then
                local can_invoke = false
                for _, p in sgs.qlist(use.to) do
                    if (not p:inMyAttackRange(player)) or p:getHp() <= player:getHp() then
                        room:setCardFlag(use.card, "mikudasu")
                        room:addPlayerMark(p, "Armor_Nullified")
                        room:addPlayerMark(p, "mikudasu")
                        can_invoke = true
                    end
                end
                if can_invoke then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        for _, _p in sgs.qlist(use.to) do
                            if _p:objectName() ~= p:objectName() and player:canSlash(p, use.card, true)
                                and not sgs.Sanguosha:isProhibited(player, p, use.card) then
                                targets:append(p)
                            end
                        end
                    end
                    local stop = false
                    while not targets:isEmpty() and not stop do
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@mikudasu_invoke",
                            false, true)
                        --[[ 					local msg = sgs.LogMessage()
                        msg.type = "#mikudasu-target"
                        msg.from = player
                        msg.to:append(target)
                        msg.arg = use.card:objectName()
                        msg.arg2 = self:objectName()
                        room:sendLog(msg)		 ]]
                        use.to:append(target)
                        room:addPlayerMark(target, "Armor_Nullified")
                        room:addPlayerMark(target, "mikudasu")
                        targets:removeOne(target)
                        if target:inMyAttackRange(player) and target:getHp() > player:getHp() then
                            stop = true
                        end
                    end
                    data:setValue(use)
                end
            end
        else
            if use.card:hasFlag("mikudasu") then
                room:setCardFlag(use.card, "-mikudasu")
            end
            for _, p in sgs.qlist(use.to) do
                room:removePlayerMark(p, "Armor_Nullified")
                room:removePlayerMark(p, "mikudasu")
            end
        end
        return false
    end,
}
LuamikudasuMod = sgs.CreateTargetModSkill {
    name = "#LuamikudasuMod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("Luamikudasu") and to and ((not to:inMyAttackRange(from)) or to:getHp() <= from:getHp()) then
            return 1000
        else
            return 0
        end
    end,
}
Zambi:insertRelatedSkills("Luamikudasu", "#LuamikudasuMod")
YuiKanemura:addSkill(Luamikudasu)
if not sgs.Sanguosha:getSkill("#LuamikudasuMod") then
    SKMC.SkillList:append(LuamikudasuMod)
end

sgs.LoadTranslationTable {
    ["YuiKanemura"] = "金村 優衣",
    ["&YuiKanemura"] = "金村 優衣",
    ["#YuiKanemura"] = "ポテンシャル",
    ["designer:YuiKanemura"] = "Cassimolar",
    ["cv:YuiKanemura"] = "山下 美月",
    ["illustrator:YuiKanemura"] = "Cassimolar",
    ["Luamikudasu"] = "蔑视",
    [":Luamikudasu"] = "你对体力值不大于你/攻击范围内不包含你的角色使用【杀】时无视距离和防具，当你使用【杀】指定体力值不大于你/攻击范围内不包含你的角色为目标时，你可以选择一名其他角色成为此【杀】的额外目标。",
    ["@mikudasu_invoke"] = "请为此【杀】选择一个额外目标",
    --	["#mikudasu-target"] = "%from 发动了 %arg2 为%arg 选择了额外目标%to",
}

-- 花村 穂花
honokahanamura = sgs.General(Zambi, "honokahanamura", "Zambi", 3, false, false, false, 1)
table.insert(SKMC.SanKiSei, "honokahanamura")

--[[
    技能名：哮喘
    描述：锁定技，你手牌中的【桃】均视为【酒】；分发起始手牌时你额外分发六张，你选择其中六张置于你的武将牌上称为“药”，你可以将”药“视为【桃】使用。
]]
LuakikanshizensokuVS = sgs.CreateOneCardViewAsSkill {
    name = "Luakikanshizensoku",
    filter_pattern = ".|.|.|kusuri",
    expand_pile = "kusuri",
    view_as = function(self, card)
        local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
        peach:setSkillName(self:objectName())
        peach:addSubcard(card)
        return peach
    end,
    enabled_at_play = function(self, player)
        return player:isWounded() and player:getPile("kusuri"):length() ~= 0
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "peach")
    end,
}
Luakikanshizensoku = sgs.CreateTriggerSkill {
    name = "Luakikanshizensoku",
    priority = -1,
    view_as_skill = LuakikanshizensokuVS,
    events = {sgs.DrawInitialCards, sgs.AfterDrawInitialCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawInitialCards then
            data:setValue(data:toInt() + 6)
        elseif event == sgs.AfterDrawInitialCards then
            local exchange_card = room:askForExchange(player, self:objectName(), 6, 6, false, "@kusuri_choice")
            player:addToPile("kusuri", exchange_card:getSubcards(), false)
            exchange_card:deleteLater()
        end
    end,
}
LuakikanshizensokuFilter = sgs.CreateFilterSkill {
    name = "#LuakikanshizensokuFilter",
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, to_select)
        return to_select:objectName() == "peach" and sgs.Sanguosha:currentRoom()
            :getCardPlace(to_select:getEffectiveId()) == sgs.Player_PlaceHand
    end,
    view_as = function(self, card)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
        analeptic:setSkillName(self:objectName())
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(analeptic)
        return new
    end,
}
Zambi:insertRelatedSkills("Luakikanshizensoku", "#LuakikanshizensokuFilter")
honokahanamura:addSkill(Luakikanshizensoku)
honokahanamura:addSkill(LuakikanshizensokuFilter)

--[[
    技能名：推倒
    描述：限定技，当你进入濒死时，若你没有“药”，你可以指定一名其他角色并令除其以外所有其他角色对其使用一张【杀】，未如此做的角色令你将牌堆顶的一张牌加入你的“药”，若其因此进入濒死则你将所有因此使用而进入弃牌堆的【杀】置入你的”药“。
]]
Luaoshitaoshi = sgs.CreateTriggerSkill {
    name = "Luaoshitaoshi",
    limit_mark = "@shinyuu",
    frequency = sgs.Skill_Limited,
    events = {sgs.EnterDying, sgs.CardUsed, sgs.AskForPeachesDone},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and player:hasSkill(self) and player:getMark("@shinyuu")
                ~= 0 and player:getPile("kusuri"):length() == 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@oshitaoshi-target", true, true)
                if target then
                    player:loseMark("@shinyuu")
                    room:setPlayerMark(player, "oshitaoshi", 1)
                    room:setPlayerMark(target, "oshitaoshi-target", 1)
                    room:setPlayerMark(target, player:objectName() .. "oshitaoshi-target", 1)
                    for _, p in sgs.qlist(room:getOtherPlayers(target)) do
                        if not room:askForUseSlashTo(p, target, "@oshitaoshi_slash:" .. target:objectName() .. ":"
                            .. player:objectName(), false, false) then
                            player:addToPile("kusuri", room:drawCard())
                        end
                    end
                end
            end
            if dying.who:objectName() == player:objectName() and player:getMark("oshitaoshi-target") ~= 0 then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill(self) and player:getMark(p:objectName() .. "oshitaoshi-target") ~= 0 then
                        local list = player:getTag("oshitaoshi_slash_list"):toIntList()
                        if not list:isEmpty() then
                            for _, id in sgs.qlist(list) do
                                if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                                    p:addToPile("kusuri", id)
                                end
                            end
                        end
                        player:removeTag("oshitaoshi_slash_list")
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
                for _, p in sgs.qlist(use.to) do
                    if p:getMark("oshitaoshi-target") ~= 0 then
                        local list = player:getTag("oshitaoshi_slash_list"):toIntList()
                        if use.card:isVirtualCard() then
                            for _, id in sgs.qlist(use.card:getSubcards()) do
                                list:append(id)
                            end
                        else
                            list:append(use.card:getEffectiveId())
                        end
                        if not list:isEmpty() then
                            local tag = sgs.QVariant()
                            tag:setValue(list)
                            p:setTag("oshitaoshi_slash_list", tag)
                        end
                    end
                end
            end
        elseif event == sgs.AskForPeachesDone then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and player:hasSkill(self) and player:getMark("oshitaoshi")
                ~= 0 then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark("oshitaoshi-target") ~= 0 and p:getMark(player:objectName() .. "oshitaoshi-target") ~= 0 then
                        room:setPlayerMark(p, "oshitaoshi-target", 0)
                        room:setPlayerMark(p, player:objectName() .. "oshitaoshi-target", 0)
                        p:removeTag("oshitaoshi_slash_list")
                    end
                end
                room:setPlayerMark(player, "oshitaoshi", 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
honokahanamura:addSkill(Luaoshitaoshi)

sgs.LoadTranslationTable {
    ["honokahanamura"] = "花村 穂花",
    ["&honokahanamura"] = "花村 穂花",
    ["#honokahanamura"] = "アイドル誕生？",
    ["designer:honokahanamura"] = "Cassimolar",
    ["cv:honokahanamura"] = "久保 史緒里",
    ["illustrator:honokahanamura"] = "Cassimolar",
    ["Luakikanshizensoku"] = "哮喘",
    ["#LuakikanshizensokuFilter"] = "哮喘",
    [":Luakikanshizensoku"] = "锁定技，你手牌中的【桃】均视为【酒】；分发起始手牌时你额外分发六张，你选择其中六张置于你的武将牌上称为“药”，你可以将“药”视为【桃】使用。",
    ["kusuri"] = "药",
    ["@kusuri_choice"] = "请选择六张手牌作为你的“药”",
    ["Luaoshitaoshi"] = "推倒",
    [":Luaoshitaoshi"] = "限定技，当你进入濒死时，若你没有“药”，你可以指定一名其他角色并令除其以外所有其他角色对其使用一张【杀】，未如此做的角色令你将牌堆顶的一张牌加入你的“药”，若其因此进入濒死则你将所有因此使用而进入弃牌堆的【杀】置入你的“药”。",
    ["@shinyuu"] = "親友",
    ["@oshitaoshi-target"] = "你可以选择一名其他角色发动【推倒】",
}
