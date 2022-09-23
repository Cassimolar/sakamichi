require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaIkoma_God = sgs.General(SakamichiGod, "RinaIkoma_God", "god", 0, false)
table.insert(SKMC.IKiSei, "RinaIkoma_God")

-- =============================================================专属装备==============================================================--
-- ! 武器【音が出ないギター】
OtoGaDenaiGitaSkill = sgs.CreateOneCardViewAsSkill {
    name = "_oto_ga_denai_gita",
    filter_pattern = "Slash",
    view_as = function(self, card)
        local duel = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber())
        duel:setSkillName(self:objectName());
        duel:addSubcard(card:getId());
        return duel
    end,
}
if not sgs.Sanguosha:getSkill("_oto_ga_denai_gita") then
    SKMC.SkillList:append(OtoGaDenaiGitaSkill)
end

OtoGaDenaiGita = sgs.CreateWeapon {
    name = "_oto_ga_denai_gita",
    range = 3,
    number = 1,
    suit = sgs.Card_Heart,
    on_install = function(self, player)
        local room = player:getRoom()
        room:damage(sgs.DamageStruct(self:objectName(), nil, player, 2))
        player:getRoom():acquireSkill(player, OtoGaDenaiGitaSkill)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, "_oto_ga_denai_gita")
    end,
}
OtoGaDenaiGita:clone():setParent(SakamichiExclusiveCard)

sgs.LoadTranslationTable {
    ["_oto_ga_denai_gita"] = "音が出ないギター",
    [":_oto_ga_denai_gita"] = " 装备牌·武器\
    <b>攻击范围</b>：3\
    <b>武器技能</b>：装备时受到2点伤害；你可以将【杀】视为【决斗】使用。",
}

-- ! 防具【制服のマネキン】
SeifukuNoManekinSkill = sgs.CreateTriggerSkill {
    name = "#seifuku_no_manekin",
    events = {sgs.PreHpLost},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local msg = sgs.LogMessage()
        msg.type = "#seifuku_no_manekinProtect"
        msg.from = player
        msg.arg = "_seifuku_no_manekin"
        room:sendLog(msg)
        room:setEmotion(player, "skill_nullify")
        return true
    end,
    can_trigger = function(self, target)
        if target and target:isAlive() and target:getArmor() and target:getArmor():objectName() == "_seifuku_no_manekin" then
            if target:getMark("Armor_Nullified") == 0 and not target:hasFlag("WuqianTarget") then
                if target:getMark("Equips_Nullified_to_Yourself") == 0 then
                    local list = target:getTag("Qinggang"):toStringList()
                    return #list == 0
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("#seifuku_no_manekin") then
    SKMC.SkillList:append(SeifukuNoManekinSkill)
end

SeifukuNoManekin = sgs.CreateArmor {
    name = "_seifuku_no_manekin",
    class_name = "SeifukuNoManekin",
    number = 1,
    suit = sgs.Card_Spade,
    on_install = function(self, player)
        local room = player:getRoom()
        room:damage(sgs.DamageStruct(self:objectName(), nil, player, 2))
        room:acquireSkill(player, SeifukuNoManekinSkill)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, "#seifuku_no_manekin")
        room:useCard(sgs.CardUseStruct(sgs.Sanguosha:cloneCard("SavageAssault", sgs.Card_NoSuit, -1), player,
            sgs.SPlayerList()), true)
    end,
}
SeifukuNoManekin:clone():setParent(SakamichiExclusiveCard)

sgs.LoadTranslationTable {
    ["_seifuku_no_manekin"] = "制服のマネキン",
    [":_seifuku_no_manekin"] = " 装备牌·防具\
    <b>防具技能</b>：装备时受到2点伤害；锁定技，防止你的体力流失，当此装备离开你的装备区时，视为你使用了一张【南蛮入侵】。",
    ["#seifuku_no_manekinProtect"] = "%from 的【%arg】被触发，防止此次体力流失",
}

-- ! 进攻马【走れ!Bicycle】
HashireBaisukuruSkill = sgs.CreateTriggerSkill {
    name = "#hashire_baisukuru",
    events = {sgs.SlashProceed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:getOffensiveHorse():objectName() == "hashire_baisukuru"
                and not effect.to:inMyAttackRange(effect.from) then
                room:slashResult(effect, nil)
                return true
            end
        end
    end,
}
HashireBaisukuruSkillControl = sgs.CreateTriggerSkill {
    name = "#hashire_baisukuru_skill_Control",
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() then
            if move.to_place == sgs.Player_PlaceEquip then
                for _, id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:objectName() == "_hashire_baisukuru" then
                        room:damage(sgs.DamageStruct(self:objectName(), nil, player, 2))
                        room:acquireSkill(player, HashireBaisukuruSkill)
                    end
                end
            end
        end
        if move.from and move.from:objectName() == player:objectName() then
            for _, place in sgs.qlist(move.from_places) do
                if place == sgs.Player_PlaceEquip then
                    for _, id in sgs.qlist(move.card_ids) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:objectName() == "_hashire_baisukuru" then
                            room:detachSkillFromPlayer(player, "hashire_baisukuru_skill")
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("#hashire_baisukuru") then
    SKMC.SkillList:append(HashireBaisukuruSkill)
end
if not sgs.Sanguosha:getSkill("#hashire_baisukuru_skill_Control") then
    SKMC.SkillList:append(HashireBaisukuruSkillControl)
end

HashireBaisukuru = sgs.Sanguosha:cloneCard("OffensiveHorse", sgs.Card_Diamond, 1)
HashireBaisukuru:setObjectName("_hashire_baisukuru")
HashireBaisukuru:setParent(SakamichiExclusiveCard)

sgs.LoadTranslationTable {
    ["_hashire_baisukuru"] = "走れ!Bicycle",
    [":_hashire_baisukuru"] = "装备牌·坐骑<br /><b>坐骑技能</b>：装备时受到2点伤害；你与其他角色的距离-1；锁定技，当你使用【杀】指定目标时，若你不在其攻击范围内，此【杀】不可以闪避。",
}

-- ! 防御马【羽根の記憶】
HaneNoKiokuSkill = sgs.CreateProhibitSkill {
    name = "#hane_no_kioku_skill",
    is_prohibited = function(self, from, to, card)
        return to:getDefensiveHorse() and to:getDefensiveHorse():objectName() == "hane_no_kioku" and from:objectName()
                   ~= to:objectName() and not from:inMyAttackRange(to) and not card:isKindOf("SkillCard")
    end,
}
HaneNoKiokuSkillControl = sgs.CreateTriggerSkill {
    name = "#hane_no_kioku_skill_Control",
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() then
            if move.to_place == sgs.Player_PlaceEquip then
                for _, id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:objectName() == "_hane_no_kioku" then
                        room:damage(sgs.DamageStruct(self:objectName(), nil, player, 2))
                        room:acquireSkill(player, HaneNoKiokuSkill)
                    end
                end
            end
        end
        if move.from and move.from:objectName() == player:objectName() then
            for _, place in sgs.qlist(move.from_places) do
                if place == sgs.Player_PlaceEquip then
                    for _, id in sgs.qlist(move.card_ids) do
                        local card = sgs.Sanguosha:getCard(id)
                        if card:objectName() == "_hane_no_kioku" then
                            room:detachSkillFromPlayer(player, "hane_no_kioku_skill")
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("#hane_no_kioku_skill") then
    SKMC.SkillList:append(HaneNoKiokuSkill)
end
if not sgs.Sanguosha:getSkill("#hane_no_kioku_skill_Control") then
    SKMC.SkillList:append(HaneNoKiokuSkillControl)
end

HaneNoKioku = sgs.Sanguosha:cloneCard("DefensiveHorse", sgs.Card_Club, 1)
HaneNoKioku:setObjectName("_hane_no_kioku")
HaneNoKioku:setParent(SakamichiExclusiveCard)

sgs.LoadTranslationTable {
    ["_hane_no_kioku"] = "羽根の記憶",
    [":_hane_no_kioku"] = "装备牌·坐骑<br /><b>坐骑技能</b>：装备时受到2点伤害；你与其他角色的距离+1；锁定技，你不是攻击范围内不包含你的其他角色使用卡牌的合法目标。",
}

-- ! 宝物【指望遠鏡】
YubiBoenkyoCard = sgs.CreateSkillCard {
    name = "_yubi_boenkyoCard",
    skill_name = "yubi_boenkyo",
    target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local ids = sgs.IntList()
        for _, id in sgs.qlist(effect.to:getHandcards()) do
            ids:append(id:getEffectiveId())
        end
        local card_id = room:doGongxin(effect.from, effect.to, ids, self:objectName())
        if card_id ~= -1 then
            room:setPlayerFlag(effect.from, "yubi_boenkyo_source")
            room:setPlayerMark(effect.to, "yubi_boenkyo_target", 1)
            room:setPlayerMark(effect.to, effect.from:objectName() .. "yubi_boenkyo", 1)
            room:setCardFlag(sgs.Sanguosha:getCard(card_id), "yubi_boenkyo_card")
        end
    end,
}
YubiBoenkyoViewAsSkill = sgs.CreateZeroCardViewAsSkill {
    name = "yubi_boenkyo",
    view_as = function(self)
        return YubiBoenkyoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#_yubi_boenkyoCard")
    end,
}
YubiBoenkyoSkill = sgs.CreateTriggerSkill {
    name = "_yubi_boenkyo",
    events = {sgs.EventPhaseEnd, sgs.CardsMoveOneTime},
    view_as_skill = YubiBoenkyoViewAsSkill,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, pl in sgs.qlist(room:getAllPlayers()) do
                if pl:getMark("yubi_boenkyo_target") then
                    for _, p in sgs.qlist(room:getOtherPlayers(pl)) do
                        if p:hasFlag("yubi_boenkyo_source") and pl:getMark(p:objectName() .. "yubi_boenkyo") ~= 0
                            and p:getTreasure() and p:getTreasure():objectName() == "_yubi_boenkyo" then
                            for _, card in sgs.qlist(pl:getHandcards()) do
                                if card:hasFlag("yubi_boenkyo_card") then
                                    room:damage(sgs.DamageStruct(self:objectName(), p, pl, 1))
                                end
                            end
                            room:setPlayerFlag(p, "-yubi_boenkyo_source")
                            room:setPlayerMark(pl, p:objectName() .. "yubi_boenkyo", 0)
                            room:setPlayerMark(pl, "yubi_boenkyo_target", 0)
                        else
                            for _, card in sgs.qlist(pl:getHandcards()) do
                                if card:hasFlag("yubi_boenkyo_card") then
                                    room:setCardFlag(card, "-yubi_boenkyo_card")
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then
                for _, place in sgs.qlist(move.from_places) do
                    if place == sgs.Player_PlaceHand then
                        for _, id in sgs.qlist(move.card_ids) do
                            local card = sgs.Sanguosha:getCard(id)
                            if card:hasFlag("yubi_boenkyo_card") then
                                room:setCardFlag(card, "-yubi_boenkyo_card")
                            end
                        end
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
if not sgs.Sanguosha:getSkill("_yubi_boenkyo") then
    SKMC.SkillList:append(YubiBoenkyoSkill)
end

YubiBoenkyo = sgs.CreateTreasure {
    name = "_yubi_boenkyo",
    class_name = "YubiBoenkyo",
    number = 13,
    suit = sgs.Card_Diamond,
    on_install = function(self, player)
        local room = player:getRoom()
        room:damage(sgs.DamageStruct(self:objectName(), nil, player, 2))
        player:getRoom():acquireSkill(player, YubiBoenkyoSkill)
    end,
    on_uninstall = function(self, player)
        local room = player:getRoom()
        room:detachSkillFromPlayer(player, "_yubi_boenkyo")
    end,
}
YubiBoenkyo:clone():setParent(SakamichiExclusiveCard)

sgs.LoadTranslationTable {
    ["_yubi_boenkyo"] = "指望遠鏡",
    [":_yubi_boenkyo"] = " 装备牌·宝物\
    <b>攻击范围</b>：3\
    <b>武器技能</b>：装备时受到2点伤害；出牌阶段限一次，你可以观看一名其他角色的手牌并选择其中的一张牌，回合结束时若此牌仍在其手牌中，你对其造成1点伤害。",
}

-- ========================================================================================================================================================--

--[[
    技能名：团魂
    描述：你的基础体力上限为0;锁定技，你不会受到伤害；锁定技，你始终跳过摸牌阶段且你的手牌始终为4；锁定技，起始手牌分发完毕时你拥有一套专属装备，当你的专属装备进入弃牌堆时你获得之并获得一枚“魂”，当你拥有20枚“魂”时，你死亡。
]]
Luatuanhun = sgs.CreateTriggerSkill {
    name = "Luatuanhun",
    events = {sgs.DamageInflicted, sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.MarkChanged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            room:setEmotion(player, "skill_nullify")
            return true
        elseif event == sgs.CardsMoveOneTime or event == sgs.EventPhaseChanging then
            if event == sgs.CardsMoveOneTime then
                local move = data:toMoveOneTime()
                if not move.from or move.from:objectName() ~= player:objectName() then
                    if not move.to or move.to:objectName() ~= player:objectName() then
                        return false
                    end
                end
                if move.to_place ~= sgs.Player_PlaceHand then
                    if not move.from_places:contains(sgs.Player_PlaceHand) then
                        return false
                    end
                elseif move.to_place == sgs.Player_DiscardPile then
                    return false
                end
                if player:getPhase() == sgs.Player_Discard then
                    return false
                end
            elseif event == sgs.EventPhaseChanging then
                local change = data:toPhaseChange()
                local nextphase = change.to
                if nextphase == sgs.Player_Draw then
                    player:skip(nextphase)
                    return false
                elseif nextphase ~= sgs.Player_Finish then
                    return false
                end
            end
            local count = player:getHandcardNum()
            if count == 4 then
                return false
            elseif count < 4 then
                player:drawCards(4 - count)
            elseif count > 4 then
                room:askForDiscard(player, self:objectName(), count - 4, count - 4)
            end
            return false
        elseif event == sgs.MarkChanged then
            local mark = data:toMark()
            if mark.name == "@hun" and player:getMark("@hun") >= 20 and player:hasSkill(self) then
                room:killPlayer(player)
            end
            return false
        end
    end,
}
Luatuanhun_exequip = sgs.CreateTriggerSkill {
    name = "#Luatuanhun_exequip",
    events = {sgs.CardsMoveOneTime, sgs.AfterDrawInitialCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place == sgs.Player_DiscardPile then
                for _, id in sgs.qlist(move.card_ids) do
                    if sgs.Sanguosha:getCard(id):objectName() == "_oto_ga_denai_gita" then
                        if player:getWeapon() then
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceHand,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        else
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceEquip,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        end
                    elseif sgs.Sanguosha:getCard(id):objectName() == "_seifuku_no_manekin" then
                        if player:getArmor() then
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceHand,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        else
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceEquip,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        end
                    elseif sgs.Sanguosha:getCard(id):objectName() == "_hashire_baisukuru" then
                        if player:getOffensiveHorse() then
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceHand,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        else
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceEquip,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        end
                    elseif sgs.Sanguosha:getCard(id):objectName() == "_hane_no_kioku" then
                        if player:getDefensiveHorse() then
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceHand,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        else
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceEquip,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        end
                    elseif sgs.Sanguosha:getCard(id):objectName() == "_yubi_boenkyo" then
                        if player:getTreasure() then
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceHand,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        else
                            --	local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, nil, player:objectName(), "Luatuanhun", ""))
                            --	room:moveCardsAtomic(move, false)
                            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, player, sgs.Player_PlaceEquip,
                                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(),
                                    self:objectName(), ""), false)
                            player:gainMark("@hun")
                        end
                    end
                end
            end
        elseif event == sgs.AfterDrawInitialCards then
            local ids = sgs.IntList()
            for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
                if (sgs.Sanguosha:getEngineCard(id):objectName() == "_oto_ga_denai_gita"
                    or sgs.Sanguosha:getEngineCard(id):objectName() == "_seifuku_no_manekin"
                    or sgs.Sanguosha:getEngineCard(id):objectName() == "_hashire_baisukuru"
                    or sgs.Sanguosha:getEngineCard(id):objectName() == "_hane_no_kioku"
                    or sgs.Sanguosha:getEngineCard(id):objectName() == "_yubi_boenkyo") and room:getCardPlace(id)
                    ~= sgs.Player_DrawPile then
                    player:speak(sgs.Sanguosha:getEngineCard(id):objectName())
                    player:speak(room:getCardPlace(id))
                    ids:append(id)
                end
            end
            local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceEquip,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, nil, player:objectName(), self:objectName(), ""))
            room:moveCardsAtomic(move, false)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill("Luatuanhun")
    end,
}
RinaIkoma_God:addSkill(Luatuanhun)
RinaIkoma_God:addSkill(Luatuanhun_exequip)

sgs.LoadTranslationTable {
    ["RinaIkoma_God"] = "生駒 里奈",
    ["&RinaIkoma_God"] = "神·生駒 里奈",
    ["#RinaIkoma_God"] = "臨危受命",
    ["designer:RinaIkoma_God"] = "Cassimolar",
    ["cv:RinaIkoma_God"] = "生駒 里奈",
    ["illustrator:RinaIkoma_God"] = "Cassimolar",
    ["Luatuanhun"] = "团魂",
    [":Luatuanhun"] = "你的基础体力上限为0；锁定技，你不会受到伤害；锁定技，你始终跳过摸牌阶段且你的手牌始终为4；锁定技，起始手牌分发完毕时你拥有一套专属装备，当你的专属装备进入弃牌堆时你获得之（优先进入装备栏，装备栏已有装备则进入手牌）并获得一枚“魂”，当你拥有20枚“魂”时，你死亡。",
    ["#Luatuanhun_exequip"] = "团魂",
    ["@hun"] = "魂",
}
