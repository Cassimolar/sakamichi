require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ArunoNakanishi = sgs.General(Sakamichi, "ArunoNakanishi$", "Nogizaka46", 4, false, false, false, 2)
SKMC.GoKiSei.ArunoNakanishi = true
SKMC.SeiMeiHanDan.ArunoNakanishi = {
    name = {4, 6, 2, 2, 1},
    ten_kaku = {10, "xiong"},
    jin_kaku = {8, "ji"},
    ji_kaku = {5, "ji"},
    soto_kaku = {7, "ji"},
    sou_kaku = {15, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_qi_shi_card = sgs.CreateSkillCard {
    name = "sakamichi_qi_shiCard",
    skill_name = "sakamichi_qi_shi",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getKingdom() == source:getKingdom() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:drawCards(effect.to, 2, self:getSkillName())
        if effect.to:getHandcardNum() + effect.to:getEquips():length() > 2 then
            room:askForDiscard(effect.to, self:getSkillName(), 2, 2, false, true, nil, ".", self:getSkillName())
        else
            effect.to:throwAllHandCardsAndEquips()
        end
    end,
}
sakamichi_qi_shi = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_qi_shi$",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_qi_shi_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
    end,
}
ArunoNakanishi:addSkill(sakamichi_qi_shi)

sakamichi_qi_shi_hidden_effect = sgs.CreateTriggerSkill {
    name = "#sakamichi_qi_shi_hidden_effect",
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    global = true,
    events = {sgs.AskForPeachesDone},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() and player:isLord()
            and (string.find(player:getGeneralName(), "ArunoNakanishi")
                or string.find(player:getGeneral2Name(), "ArunoNakanishi")) then
            local change = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if string.find(p:getGeneralName(), "AsukaSaito") or string.find(p:getGeneral2Name(), "AsukaSaito")
                    or string.find(p:getGeneralName(), "MizukiYamashita")
                    or string.find(p:getGeneral2Name(), "MizukiYamashita") then
                    change = true
                    room:setPlayerProperty(p, "role", sgs.QVariant("lord"))
                end
            end
            if change then
                room:setPlayerProperty(player, "role", sgs.QVariant("renegade"))
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("#sakamichi_qi_shi_hidden_effect") then
    SKMC.SkillList:append(sakamichi_qi_shi_hidden_effect)
end

sakamichi_si_mo_card = sgs.CreateSkillCard {
    name = "sakamichi_si_moCard",
    skill_name = "sakamichi_si_mo",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
                   and to_select:hasSkill(self:getSkillName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choices = {}
        local choice_1 = "use=" .. effect.to:objectName() .. "="
                             .. sgs.Sanguosha:getCard(self:getEffectiveId()):objectName()
        local choice_2
        table.insert(choices, choice_1)
        if effect.to:getEquips():length() ~= 0 then
            choice_2 = "get=" .. effect.to:objectName()
        end
        if choice_2 then
            table.insert(choices, choice_2)
        end
        if room:askForChoice(effect.from, self:getSkillName(), table.concat(choices, "+")) == choice_1 then
            room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(self:getEffectiveId()), effect.to, effect.to))
        else
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            dummy:deleteLater()
            dummy:addSubcards(effect.to:getEquips())
            room:obtainCard(effect.to, dummy)
        end
        room:addPlayerMark(effect.from, self:getSkillName() .. effect.to:objectName() .. "_finish_end_clear",
            SKMC.number_correction(effect.to, 1))
    end,
}
sakamichi_si_mo_give = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_si_mo_give&",
    filter_pattern = "EquipCard",
    view_as = function(self, card)
        local cd = sakamichi_si_mo_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_si_moCard")
    end,
}
sakamichi_si_mo = sgs.CreateTriggerSkill {
    name = "sakamichi_si_mo",
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.GameStart and player:hasSkill(self))
            or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:hasSkill("sakamichi_si_mo_give") then
                    room:attachSkillToPlayer(p, "sakamichi_si_mo_give")
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
                    room:detachSkillFromPlayer(p, "sakamichi_si_mo_give", true)
                end
            end
        elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                local num = player:getMark(self:objectName() .. p:objectName() .. "_finish_end_clear")
                if num ~= 0 then
                    room:addPlayerMark(player, "&" .. self:objectName() .. "+" .. p:getGeneralName(), num)
                    room:addPlayerMark(player, self:objectName() .. p:objectName(), num)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_si_mo_distance = sgs.CreateDistanceSkill {
    name = "#sakamichi_si_mo_distance",
    correct_func = function(self, from, to)
        return -from:getMark("sakamichi_si_mo" .. to:objectName())
    end,
}
ArunoNakanishi:addSkill(sakamichi_si_mo)
if not sgs.Sanguosha:getSkill("sakamichi_si_mo_give") then
    SKMC.SkillList:append(sakamichi_si_mo_give)
end
if not sgs.Sanguosha:getSkill("#sakamichi_si_mo_distance") then
    SKMC.SkillList:append(sakamichi_si_mo_distance)
end

sakamichi_yuan_wei_card = sgs.CreateSkillCard {
    name = "sakamichi_yuan_weiCard",
    skill_name = "sakamichi_yuan_wei",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, room:getCardPlace(self:getSubcards():first()) ~= sgs.Player_PlaceHand)
    end,
}
sakamichi_yuan_wei_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_yuan_wei",
    filter_pattern = "EquipCard",
    view_as = function(self, card)
        local cd = sakamichi_yuan_wei_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_yuan_weiCard")
    end,
}
sakamichi_yuan_wei = sgs.CreateTriggerSkill {
    name = "sakamichi_yuan_wei",
    events = {sgs.CardsMoveOneTime},
    view_as_skill = sakamichi_yuan_wei_view_as,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.to and move.to:objectName() ~= move.from:objectName() and move.from:objectName()
            == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
            local n = 0
            for _, id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):getTypeId() == sgs.Card_TypeEquip then
                    n = n + 1
                end
            end
            if n ~= 0 then
                local card = room:askForExchange(room:findPlayerByObjectName(move.to:objectName()), self:objectName(),
                    n, n, false, "@yuan_wei_invoke:" .. move.from:objectName() .. "::" .. n, true)
                if card then
                    room:obtainCard(player, card, false)
                else
                    room:damage(sgs.DamageStruct(self:objectName(), player,
                        room:findPlayerByObjectName(move.to:objectName()), n))
                    room:drawCards(player, n, self:objectName())
                end
            end
        end
        return false
    end,
}
ArunoNakanishi:addSkill(sakamichi_yuan_wei)

sgs.LoadTranslationTable {
    ["ArunoNakanishi"] = "中西 アルノ",
    ["&ArunoNakanishi"] = "中西 アルノ",
    ["#ArunoNakanishi"] = "模皇",
    ["~ArunoNakanishi"] = "植物人間って光合成するの？",
    ["designer:ArunoNakanishi"] = "Cassimolar",
    ["cv:ArunoNakanishi"] = "中西 アルノ",
    ["illustrator:ArunoNakanishi"] = "Cassimolar",
    ["sakamichi_qi_shi"] = "其实",
    [":sakamichi_qi_shi"] = "主公技，出牌阶段，你可以弃置一张手牌，若如此做，所有势力与你相同的角色摸两张牌然后弃置两张牌。",
    ["sakamichi_si_mo"] = "私模",
    [":sakamichi_si_mo"] = "其他角色出牌阶段限一次，其可以将一张装备牌交给你，然后选择令你使用之或令你获得你装备区所有牌，若如此做，本回合结束阶段，其计算与你的距离永久-1。",
    ["sakamichi_si_mo_give"] = "私模",
    [":sakamichi_si_mo_give"] = "出牌阶段限一次，你可以将一张装备牌交给【私模】的拥有者，然后选择令其使用之或令其获得其装备区所有牌，若如此做，本回合结束阶段，你计算与其的距离永久-1。",
    ["sakamichi_si_mo:use"] = "令%src使用【%arg】",
    ["sakamichi_si_mo:get"] = "令%src获得其装备区所有牌",
    ["sakamichi_yuan_wei"] = "原味",
    [":sakamichi_yuan_wei"] = "其他角色获得你装备区的牌时，其需交给你等量的手牌，否则你对其造成等量的伤害并摸等量的牌。出牌阶段限一次，你可以交给一名其他角色一张装备牌。",
    ["@yuan_wei_invoke"] = "请交给%src%arg张手牌，否则受到其造成的%arg点伤害且其摸%arg张牌",
}
