require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MisaGenda = sgs.General(SakamichiGod, "MisaGenda", "god", 5, false)
table.insert(SKMC.IKiSei, "MisaGenda")

--[[
    技能名：坦诚相见
    描述：锁定技，你使用【杀】造成伤害时，若目标装备区没牌，此次伤害＋1，否则你弃置其装备区一张牌。
]]
Luafrank = sgs.CreateTriggerSkill {
    name = "Luafrank",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to and damage.to:isAlive() and damage.card and damage.card:isKindOf("Slash") then
            if damage.to:getEquips():length() == 0 then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            else
                room:throwCard(sgs.Sanguosha:getCard(room:askForCardChosen(player, damage.to, "e", self:objectName(),
                    false, sgs.Card_MethodDiscard)), damage.to, player)
            end
        end
        return false
    end,
}
MisaGenda:addSkill(Luafrank)

--[[
    技能名：倒酒
    描述：出牌阶段限一次，你可以与一名角色拼点：若你赢，此阶段你无视该角色的防具且对其使用牌无距离和次数限制，若你没赢，此阶段你不能使用杀；若你以此法拼点的牌为【杀】，本回合你手牌中的【杀】不计入手牌上限。
]]
LuapourwineCard = sgs.CreateSkillCard {
    name = "LuapourwineCard",
    skill_name = "Luapourwine",
    will_throw = false,
    handling_method = sgs.Card_MethodPindian,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("Slash") then
            room:setPlayerFlag(effect.from, "Luapourwine")
        end
        if effect.from:pindian(effect.to, "Luapourwine", self) then
            room:setPlayerProperty(effect.to, "Luapourwine", sgs.QVariant(effect.from:objectName()))
            local assignee_list = effect.from:property("extra_slash_specific_assignee"):toString():split("+")
            table.insert(assignee_list, effect.to:objectName())
            room:setPlayerProperty(effect.from, "extra_slash_specific_assignee",
                sgs.QVariant(table.concat(assignee_list, "+")))
            room:addPlayerMark(effect.to, "Armor_Nullified")
        else
            room:setPlayerFlag(effect.from, "Luapourwine-limited")
            room:setPlayerCardLimitation(effect.from, "use", "Slash", true)
        end
        effect.from:setTag("Luapourwine", sgs.QVariant(true))
    end,
}
LuapourwineVS = sgs.CreateOneCardViewAsSkill {
    name = "Luapourwine",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skillcard = LuapourwineCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return not (player:hasUsed("#LuapourwineCard") or player:isKongcheng())
    end,
}
Luapourwine = sgs.CreateTriggerSkill {
    name = "Luapourwine",
    events = {sgs.EventPhaseChanging, sgs.AskForGameruleDiscard, sgs.AfterGameruleDiscard},
    view_as_skill = LuapourwineVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if not player:getTag("Luapourwine"):toBool() then
                return false
            end
            if data:toPhaseChange().from == sgs.Player_Play then
                player:removeTag("Luapourwine")
                local assignee_list = player:property("extra_slash_specific_assignee"):toString():split("+")
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if not p:property("Luapourwine"):toString() == "" then
                        break
                    end
                    table.removeOne(assignee_list, p:objectName())
                    room:setPlayerProperty(p, "Luapourwine", sgs.QVariant())
                    room:removePlayerMark(p, "Armor_Nullified")
                end
                room:setPlayerProperty(player, "extra_slash_specific_assignee",
                    sgs.QVariant(table.concat(assignee_list, "+")))
                if player:hasFlag("Luapourwine-limited") then
                    room:setPlayerFlag(player, "-Luapourwine-limited")
                    room:removePlayerCardLimitation(player, "use", "Slash$1")
                end
            end
        else
            if player:isKongcheng() or not player:hasFlag("Luapourwine") then
                return false
            end
            if event == sgs.AskForGameruleDiscard then
                local n = room:getTag("DiscardNum"):toInt()
                for _, card in sgs.qlist(player:getHandcards()) do
                    if card:isKindOf("Slash") then
                        n = n - 1
                    end
                end
                room:setPlayerCardLimitation(player, "discard", "Slash", true)
                room:setTag("DiscardNum", sgs.QVariant(n))
            else
                room:removePlayerCardLimitation(player, "discard", "Slash$1")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuapourwineMod = sgs.CreateTargetModSkill {
    name = "#LuapourwineMod",
    pattern = ".",
    residue_func = function(self, from, card, to)
        local n = 0
        if to and to:property("Luapourwine"):toString() == from:objectName() then
            n = n + 1000
        end
        return n
    end,
    distance_limit_func = function(self, from, card, to)
        local n = 0
        if to and to:property("Luapourwine"):toString() == from:objectName() then
            n = n + 1000
        end
        return n
    end,
}
MisaGenda:addSkill(Luapourwine)
if not sgs.Sanguosha:getSkill("#LuapourwineMod") then
    SKMC.SkillList:append(LuapourwineMod)
end

--[[
    技能名：源田氏
    描述：锁定技，1.你的【酒】均视为【杀】;2.当你受到【酒】【杀】造成的伤害时，此伤害-X;（X为增加此【杀】伤害的【酒】数）3.其他角色于你回合内不能使用【酒】。
]]
Luagenda = sgs.CreateFilterSkill {
    name = "Luagenda",
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, to_select)
        return to_select:objectName() == "analeptic"
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:setSkillName(self:objectName())
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(slash)
        return new
    end,
}
LuagendaTrigger = sgs.CreateTriggerSkill {
    name = "#LuagendaTrigger",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted, sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.EventLoseSkill},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local card = damage.card
            if card and card:isKindOf("Slash") and card:getTag("analeptic-damage"):toInt() > 0 then
                damage.damage = math.max(damage.damage - card:getTag("analeptic-damage"):toInt(), 0)
                data:setValue(damage)
                if damage.damage == 0 then
                    return true
                end
            end
        else
            if (event == sgs.EventPhaseChanging and data:toPhaseChange().from == sgs.Player_NotActive)
                or (event == sgs.EventAcquireSkill and data:toString() == "Luagenda") then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:setPlayerCardLimitation(p, "use", "Analeptic", true)
                end
            elseif (event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive)
                or (event == sgs.EventLoseSkill and data:toString() == "Luagenda") then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:removePlayerCardLimitation(p, "use", "Analeptic$1")
                end
            end
        end
        return false
    end,
}
Sakamichi:insertRelatedSkills("Luagenda", "#LuagendaTrigger")
MisaGenda:addSkill(Luagenda)
MisaGenda:addSkill(LuagendaTrigger)

--[[
    技能名：绝唱
    描述：限定技，当你第一次脱离濒死后你可以增加X张手牌上限并摸X张牌或获得一枚“唱”，你可以于出牌阶段开始时失去一枚“”来增加X张手牌上限并摸X张牌。（X为此技能发动时场上存活的其他角色中没有装备的角色数）
]]
Luaswansong = sgs.CreateTriggerSkill {
    name = "Luaswansong",
    events = {sgs.QuitDying, sgs.EventPhaseStart},
    frequency = sgs.Skill_Limited,
    limit_mark = "@swansong",
    on_trigger = function(self, event, player, data, room)
        if event == sgs.QuitDying then
            local dying = data:toDying()
            if dying.who and dying.who:objectName() == player:objectName() then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local x = 0
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getEquips():length() == 0 then
                            x = x + 1
                        end
                    end
                    room:setPlayerMark(player, "SwanSongMaxCards", x)
                    room:drawCards(player, x)
                    player:loseMark("@swansong")
                else
                    room:setPlayerMark(player, "@SwanSongLater", 1)
                end
            end
        elseif player:getPhase() == sgs.Player_Play then
            if player:getMark("@SwanSongLater") ~= 0 then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local x = 0
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getEquips():length() == 0 then
                            x = x + 1
                        end
                    end
                    room:setPlayerMark(player, "@SwanSongLater", 0)
                    room:setPlayerMark(player, "SwanSongMaxCards", x)
                    room:drawCards(player, x)
                    player:loseMark("@swansong")
                end
            end
        end
        return false
    end,
}
LuaswansongMaxCards = sgs.CreateMaxCardsSkill {
    name = "#LuaswansongMaxCards",
    extra_func = function(self, target)
        if target:hasSkill("Luaswansong") then
            return target:getMark("SwanSongMaxCards")
        end
    end,
}
Sakamichi:insertRelatedSkills("Luagenda", "#LuagendaTrigger")
MisaGenda:addSkill(Luaswansong)
if not sgs.Sanguosha:getSkill("#LuaswansongMaxCards") then
    SKMC.SkillList:append(LuaswansongMaxCards)
end

--[[
    技能名：该死的源田
    描述：出牌阶段，若你没有“源田”则你可以将一张手牌置于你的武将牌上称为“源田”，其他角色使用卡牌时，若其使用的卡牌与你的“源田”的花色/点数/牌名相同，你可以弃置“源田”令此卡无效并获得之。
]]
LuafuckinggendaCard = sgs.CreateSkillCard {
    name = "LuafuckinggendaCard",
    skill_name = "Luafuckinggenda",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        source:addToPile("genda", self:getEffectiveId(), false)
    end,
}
LuafuckinggendaVS = sgs.CreateOneCardViewAsSkill {
    name = "Luafuckinggenda",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = LuafuckinggendaCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:getPile("genda"):length() == 0
    end,
}
Luafuckinggenda = sgs.CreateTriggerSkill {
    name = "Luafuckinggenda",
    events = {sgs.CardUsed, sgs.JinkEffect, sgs.NullificationEffect},
    view_as_skill = LuafuckinggendaVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.JinkEffect then
            local card = data:toCard()
            local stop = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self) and p:getPile("genda"):length() ~= 0 then
                    if (sgs.Sanguosha:getCard(p:getPile("genda"):first()):getSuit() == card:getSuit())
                        or (sgs.Sanguosha:getCard(p:getPile("genda"):first()):getNumber() == card:getNumber())
                        or (SKMC.true_name(sgs.Sanguosha:getCard(p:getPile("genda"):first())) == SKMC.true_name(card)) then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            room:throwCard(sgs.Sanguosha:getCard(p:getPile("genda"):first()), sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, p:objectName(), nil, self:objectName(),
                                nil), nil)
                            room:moveCardsAtomic(sgs.CardsMoveStruct(card:getEffectiveId(), nil, p,
                                room:getCardPlace(card:getEffectiveId()), sgs.Player_PlaceHand, sgs.CardMoveReason(
                                    sgs.CardMoveReason_S_REASON_GOTCARD, nil, p:objectName(), self:objectName(), "")),
                                false)
                            stop = true
                            return true
                        end
                    end
                end
                if stop then
                    break
                end
            end
        elseif event == sgs.NullificationEffect then
            local card = data:toCard()
            local stop = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self) and p:getPile("genda"):length() ~= 0 then
                    if (sgs.Sanguosha:getCard(p:getPile("genda"):first()):getSuit() == card:getSuit())
                        or (sgs.Sanguosha:getCard(p:getPile("genda"):first()):getNumber() == card:getNumber())
                        or (SKMC.true_name(sgs.Sanguosha:getCard(p:getPile("genda"):first())) == SKMC.true_name(card)) then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            room:throwCard(sgs.Sanguosha:getCard(p:getPile("genda"):first()), sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, p:objectName(), nil, self:objectName(),
                                nil), nil)
                            room:moveCardsAtomic(sgs.CardsMoveStruct(card:getEffectiveId(), nil, p,
                                room:getCardPlace(card:getEffectiveId()), sgs.Player_PlaceHand, sgs.CardMoveReason(
                                    sgs.CardMoveReason_S_REASON_GOTCARD, nil, p:objectName(), self:objectName(), "")),
                                false)
                            stop = true
                            return true
                        end
                    end
                end
                if stop then
                    break
                end
            end
        else
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and not use.card:isKindOf("Nullification") then
                local stop = false
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill(self) and p:getPile("genda"):length() ~= 0 then
                        if (sgs.Sanguosha:getCard(p:getPile("genda"):first()):getSuit() == use.card:getSuit())
                            or (sgs.Sanguosha:getCard(p:getPile("genda"):first()):getNumber() == use.card:getNumber())
                            or (SKMC.true_name(sgs.Sanguosha:getCard(p:getPile("genda"):first()))
                                == SKMC.true_name(use.card)) then
                            if room:askForSkillInvoke(p, self:objectName(), data) then
                                room:throwCard(sgs.Sanguosha:getCard(p:getPile("genda"):first()), sgs.CardMoveReason(
                                    sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, p:objectName(), nil,
                                    self:objectName(), nil), nil)
                                room:moveCardsAtomic(sgs.CardsMoveStruct(use.card:getEffectiveId(), nil, p,
                                    room:getCardPlace(use.card:getEffectiveId()), sgs.Player_PlaceHand,
                                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, nil, p:objectName(),
                                        self:objectName(), "")), false)
                                stop = true
                                return true
                            end
                        end
                    end
                    if stop then
                        break
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
MisaGenda:addSkill(Luafuckinggenda)

sgs.LoadTranslationTable {
    ["MisaGenda"] = "源田 美彩",
    ["&MisaGenda"] = "神·源田 美彩",
    ["#MisaGenda"] = "源田之妻",
    ["designer:MisaGenda"] = "Cassimolar",
    ["cv:MisaGenda"] = "源田 美彩",
    ["illustrator:MisaGenda"] = "Cassimolar",
    ["Luafrank"] = "坦诚相见",
    [":Luafrank"] = "锁定技，你使用【杀】造成伤害时，若目标装备区没牌，此次伤害＋1，否则你弃置其装备区一张牌。",
    ["Luapourwine"] = "倒酒",
    [":Luapourwine"] = "出牌阶段限一次，你可以与一名角色拼点：若你赢，此阶段你无视该角色的防具且对其使用牌无距离和次数限制，若你没赢，此阶段你不能使用【杀】；若你以此法拼点的牌为【杀】，本回合你手牌中的【杀】不计入手牌上限。",
    ["Luagenda"] = "源田氏",
    [":Luagenda"] = "锁定技，你的【酒】均视为【杀】；锁定技，当你受到【酒】【杀】造成的伤害时，此伤害-X（X为增加此【杀】伤害的【酒】数）；锁定技，其他角色于你回合内不能使用【酒】。",
    ["Luaswansong"] = "绝唱",
    [":Luaswansong"] = "限定技，当你第一次脱离濒死后你可以增加X张手牌上限并摸X张牌或获得一枚“唱”，你可以于出牌阶段开始时失去一枚“唱”来增加X张手牌上限并摸X张牌（X为此技能发动时场上存活的其他角色中没有装备的角色数）。",
    ["@swansong"] = "绝唱",
    ["@SwanSongLater"] = "唱",
    ["Luafuckinggenda"] = "该死的源田",
    [":Luafuckinggenda"] = "出牌阶段，若你没有“源田”则你可以将一张手牌置于你的武将牌上称为“源田”，其他角色使用卡牌时，若其使用的卡牌与你的“源田”的花色/点数/牌名相同，你可以弃置“源田”令此卡无效并获得之。",
    ["genda"] = "源田",
}
