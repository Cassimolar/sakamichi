require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SayuriMatsumura_God = sgs.General(SakamichiGod, "SayuriMatsumura_God", "god", 5, false)
table.insert(SKMC.IKiSei, "SayuriMatsumura_God")

--[[
    技能名：谜之便当
    描述：出牌阶段限一次，你可以展示所有手牌并选择一名有手牌的角色，令其展示手牌并将其中花色唯一的牌对自己使用，若使用的牌不为延时锦囊牌则：黑桃视为【闪电】，红桃视为【乐不思蜀】，梅花视为【兵粮寸断】，方块视为【芥末饭团】若你以此法置于其判定区的牌多于2张时，你需要弃置等量的手牌。
]]
-- ! 锦囊【芥末饭团】
WasabiOnigiri = sgs.CreateTrickCard {
    name = "_wasabi_onigiri",
    class_name = "WasabiOnigiri",
    subtype = "delayed_trick",
    subclass = sgs.LuaTrickCard_TypeDelayedTrick,
    target_fixed = false,
    can_recast = false,
    is_cancelable = true,
    movable = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() then
            return #targets == 0 and not to_select:containsTrick(self:objectName())
        end
    end,
    on_effect = function(self, effect)
        local judge = sgs.JudgeStruct()
        local room = effect.to:getRoom()
        judge.pattern = ".|.|1~" .. self:getNumber()
        judge.good = false
        judge.reason = self:objectName()
        judge.who = effect.to
        room:judge(judge)
        if judge:isBad() then
            effect.to:turnOver()
        end
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, effect.to:objectName())
        room:throwCard(self, reason, nil)
    end,
}
WasabiOnigiri:setParent(SakamichiExclusiveCard)

sgs.LoadTranslationTable {
    ["_wasabi_onigiri"] = "芥末饭团",
    [":_wasabi_onigiri"] = " 延时锦囊\
    <b>时机</b>：出牌阶段\
    <b>目标</b>：判定区没有此牌其他角色。\
    <b>效果</b>：判定阶段，进行一次判定，若判定结果不大于此牌点数，则其武将牌翻面。然后弃置此牌。",
}

LuaSatsujinBentoCard = sgs.CreateSkillCard {
    name = "LuaSatsujinBentoCard",
    skill_name = "LuaSatsujinBento",
    filter = function(self, targets, to_select)
        return #targets == 0 and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:showAllCards(effect.from)
        room:showAllCards(effect.to)
        local heart, diamond, spade, club = 0, 0, 0, 0
        local only_heart, only_diamond, only_spade, only_club = false, false, false, false
        for _, card in sgs.qlist(effect.to:getHandcards()) do
            if card:getSuit() == sgs.Card_Heart then
                heart = heart + 1
            elseif card:getSuit() == sgs.Card_Diamond then
                diamond = diamond + 1
            elseif card:getSuit() == sgs.Card_Spade then
                spade = spade + 1
            elseif card:getSuit() == sgs.Card_Club then
                club = club + 1
            end
        end
        if heart == 1 then
            only_heart = true
        end
        if diamond == 1 then
            only_diamond = true
        end
        if spade == 1 then
            only_spade = true
        end
        if club == 1 then
            only_club = true
        end
        local num = 0
        if only_heart then
            for _, cd in sgs.qlist(effect.to:getHandcards()) do
                if cd:getSuit() == sgs.Card_Heart then
                    if not sgs.Sanguosha:getCard(cd:getEffectiveId()):isKindOf("DelayedTrick") then
                        local card = sgs.Sanguosha:cloneCard("indulgence",
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getSuit(),
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getNumber())
                        card:addSubcard(sgs.Sanguosha:getCard(cd:getEffectiveId()))
                        card:setSkillName("LuaSatsujinBento")
                        if not effect.to:containsTrick("indulgence") and not effect.to:isProhibited(effect.to, card) then
                            room:useCard(sgs.CardUseStruct(card, effect.to, effect.to, true), true)
                            num = num + 1
                        end
                    else
                        if not effect.to:containsTrick(sgs.Sanguosha:getCard(cd:getEffectiveId()):objectName())
                            and not effect.to:isProhibited(effect.to, sgs.Sanguosha:getCard(cd:getEffectiveId())) then
                            room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(cd:getEffectiveId()), effect.to,
                                effect.to, true), true)
                            num = num + 1
                        end
                    end
                end
            end
        end
        if only_diamond then
            for _, cd in sgs.qlist(effect.to:getHandcards()) do
                if cd:getSuit() == sgs.Card_Diamond then
                    if not sgs.Sanguosha:getCard(cd:getEffectiveId()):isKindOf("DelayedTrick") then
                        local card = sgs.Sanguosha:cloneCard("WasabiOnigiri",
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getSuit(),
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getNumber())
                        card:addSubcard(sgs.Sanguosha:getCard(cd:getEffectiveId()))
                        card:setSkillName("LuaSatsujinBento")
                        if not effect.to:containsTrick("WasabiOnigiri") and not effect.to:isProhibited(effect.to, card) then
                            room:useCard(sgs.CardUseStruct(card, effect.to, effect.to, true), true)
                            num = num + 1
                        end
                    else
                        if not effect.to:containsTrick(sgs.Sanguosha:getCard(cd:getEffectiveId()):objectName())
                            and not effect.to:isProhibited(effect.to, sgs.Sanguosha:getCard(cd:getEffectiveId())) then
                            room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(cd:getEffectiveId()), effect.to,
                                effect.to, true), true)
                            num = num + 1
                        end
                    end
                end
            end
        end
        if only_spade then
            for _, cd in sgs.qlist(effect.to:getHandcards()) do
                if cd:getSuit() == sgs.Card_Spade then
                    if not sgs.Sanguosha:getCard(cd:getEffectiveId()):isKindOf("DelayedTrick") then
                        local card = sgs.Sanguosha:cloneCard("lightning",
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getSuit(),
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getNumber())
                        card:addSubcard(sgs.Sanguosha:getCard(cd:getEffectiveId()))
                        card:setSkillName("LuaSatsujinBento")
                        if not effect.to:containsTrick("lightning") and not effect.to:isProhibited(effect.to, card) then
                            room:useCard(sgs.CardUseStruct(card, effect.to, effect.to, true), true)
                            num = num + 1
                        end
                    else
                        if not effect.to:containsTrick(sgs.Sanguosha:getCard(cd:getEffectiveId()):objectName())
                            and not effect.to:isProhibited(effect.to, sgs.Sanguosha:getCard(cd:getEffectiveId())) then
                            room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(cd:getEffectiveId()), effect.to,
                                effect.to, true), true)
                            num = num + 1
                        end
                    end
                end
            end
        end
        if only_club then
            for _, cd in sgs.qlist(effect.to:getHandcards()) do
                if cd:getSuit() == sgs.Card_Club then
                    if not sgs.Sanguosha:getCard(cd:getEffectiveId()):isKindOf("DelayedTrick") then
                        local card = sgs.Sanguosha:cloneCard("supply_shortage",
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getSuit(),
                            sgs.Sanguosha:getCard(cd:getEffectiveId()):getNumber())
                        card:addSubcard(sgs.Sanguosha:getCard(cd:getEffectiveId()))
                        card:setSkillName("LuaSatsujinBento")
                        if not effect.to:containsTrick("supply_shortage") and not effect.to:isProhibited(effect.to, card) then
                            room:useCard(sgs.CardUseStruct(card, effect.to, effect.to, true), true)
                            num = num + 1
                        end
                    else
                        if not effect.to:containsTrick(sgs.Sanguosha:getCard(cd:getEffectiveId()):objectName())
                            and not effect.to:isProhibited(effect.to, sgs.Sanguosha:getCard(cd:getEffectiveId())) then
                            room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(cd:getEffectiveId()), effect.to,
                                effect.to, true), true)
                            num = num + 1
                        end
                    end
                end
            end
        end
        if num > 2 then
            room:askForDiscard(effect.from, "LuaSatsujinBento", num, num, false, true)
        end
    end,
}
LuaSatsujinBento = sgs.CreateZeroCardViewAsSkill {
    name = "LuaSatsujinBento",
    view_as = function()
        return LuaSatsujinBentoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#LuaSatsujinBentoCard")
    end,
}
SayuriMatsumura_God:addSkill(LuaSatsujinBento)

--[[
    技能名：贪吃
    描述：当一名角色跳过摸牌阶段/出牌阶段时，你可以摸两张牌/于此回合结束后进行一个额外的出牌阶段。
]]
LuaGluttonous = sgs.CreateTriggerSkill {
    name = "LuaGluttonous",
    events = {sgs.EventPhaseSkipping, sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseSkipping then
            if player:getPhase() == sgs.Player_Draw then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    p:drawCards(2, self:objectName())
                end
            elseif player:getPhase() == sgs.Player_Play then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    room:setPlayerMark(p, "Gluttonous", 1)
                end
            end
            return false
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("Gluttonous") ~= 0 then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            local thread = room:getThread()
                            p:setPhase(sgs.Player_Play)
                            room:broadcastProperty(p, "phase")
                            if not thread:trigger(sgs.EventPhaseStart, room, p) then
                                thread:trigger(sgs.EventPhaseProceeding, room, p)
                            end
                            thread:trigger(sgs.EventPhaseEnd, room, p)
                            p:setPhase(sgs.Player_RoundStart)
                            room:broadcastProperty(p, "phase")
                            room:setPlayerMark(p, "Gluttonous", 0)
                        end
                    end
                end
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SayuriMatsumura_God:addSkill(LuaGluttonous)

--[[
    技能名：装傻
    描述：出牌阶段限一次，你可以将一张手牌置于一名武将牌上没有“傻”的角色的武将牌上作为“傻”，当其需要进行判定时，以“傻”作为其判定牌；一名角色回合结束后，若其有“傻”，你获得之。
]]
LuaPlaydumbCard = sgs.CreateSkillCard {
    name = "LuaPlaydumbCard",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getPile("dumb"):isEmpty()
    end,
    on_effect = function(self, effect)
        local value = sgs.QVariant()
        value:setValue(effect.from)
        effect.to:setTag("LuaPlaydumbSource" .. tostring(self:getEffectiveId()), value)
        effect.to:addToPile("dumb", self)
    end,
}
LuaPlaydumbVS = sgs.CreateOneCardViewAsSkill {
    name = "LuaPlaydumb",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = LuaPlaydumbCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuaPlaydumbCard")
    end,
}
LuaPlaydumb = sgs.CreateTriggerSkill {
    name = "LuaPlaydumb",
    events = {sgs.StartJudge, sgs.EventPhaseChanging},
    view_as_skill = LuaPlaydumbVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.StartJudge then
            local card_id = player:getPile("dumb"):first()
            local judge = data:toJudge()
            judge.card = sgs.Sanguosha:getCard(card_id)
            room:moveCardTo(judge.card, nil, judge.who, sgs.Player_PlaceJudge, sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_JUDGE, judge.who:objectName(), self:objectName(), "", judge.reason), true)
            judge:updateResult()
            room:setTag("SkipGameRule", sgs.QVariant(true))
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local id = player:getPile("dumb"):first()
                local source = player:getTag("LuaPlaydumbSource" .. tostring(id)):toPlayer()
                if source and source:isAlive() then
                    source:obtainCard(sgs.Sanguosha:getCard(id))
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:getPile("dumb"):length() > 0
    end,
}
SayuriMatsumura_God:addSkill(LuaPlaydumb)

--[[
    技能名：触角
    描述：锁定技，判定区有牌的角色无法闪避你使用的【杀】。
]]
LuaShokkaku = sgs.CreateTriggerSkill {
    name = "LuaShokkaku",
    events = {sgs.SlashProceed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasSkill(self) and effect.to:getJudgingArea():length() ~= 0 then
                room:slashResult(effect, nil)
                return true
            end
        end
    end,
}
SayuriMatsumura_God:addSkill(LuaShokkaku)

--[[
    技能名：炸鸡姐妹
    描述：限定技，当你进入濒死时，你可以分别观看其他所有角色并选择获得其中的一张红桃牌或将其中一张牌视为【乐不思蜀】对其使用。
]]
LuaKaraageshimai = sgs.CreateTriggerSkill {
    name = "LuaKaraageshimai",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Limited,
    limit_mark = "@karaage",
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() then
            if player:getMark("@karaage") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                player:loseMark("@karaage")
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    local ids = sgs.IntList()
                    for _, id in sgs.qlist(p:getHandcards()) do
                        ids:append(id:getEffectiveId())
                    end
                    local card_id = room:doGongxin(player, p, ids, self:objectName())
                    if card_id ~= -1 then
                        if sgs.Sanguosha:getCard(card_id):getSuit() ~= sgs.Card_Heart then
                            local cd = sgs.Sanguosha:cloneCard("indulgence")
                            cd:deleteLater()
                            if not p:containsTrick("indulgence") and not player:isProhibited(p, cd) then
                                local card = sgs.Sanguosha:cloneCard("indulgence",
                                    sgs.Sanguosha:getCard(card_id):getSuit(), sgs.Sanguosha:getCard(card_id):getNumber())
                                card:addSubcard(sgs.Sanguosha:getCard(card_id))
                                card:setSkillName(self:objectName())
                                room:useCard(sgs.CardUseStruct(card, player, p, false), true)
                            end
                        elseif sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Heart then
                            local choice = room:askForChoice(player, self:objectName(), "obtain+use")
                            if choice == "obtain" then
                                player:obtainCard(sgs.Sanguosha:getCard(card_id))
                            else
                                local cd = sgs.Sanguosha:cloneCard("indulgence")
                                cd:deleteLater()
                                if not p:containsTrick("indulgence") and not player:isProhibited(p, cd) then
                                    local card = sgs.Sanguosha:cloneCard("indulgence",
                                        sgs.Sanguosha:getCard(card_id):getSuit(),
                                        sgs.Sanguosha:getCard(card_id):getNumber())
                                    card:addSubcard(sgs.Sanguosha:getCard(card_id))
                                    card:setSkillName(self:objectName())
                                    room:useCard(sgs.CardUseStruct(card, player, p, false), true)
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
}
SayuriMatsumura_God:addSkill(LuaKaraageshimai)

sgs.LoadTranslationTable {
    ["SayuriMatsumura_God"] = "松村 沙友理",
    ["&SayuriMatsumura_God"] = "神·松村 沙友理",
    ["#SayuriMatsumura_God"] = "便當收割者",
    ["designer:SayuriMatsumura_God"] = "Cassimolar",
    ["cv:SayuriMatsumura_God"] = "松村 沙友理",
    ["illustrator:SayuriMatsumura_God"] = "Cassimolar",
    ["LuaSatsujinBento"] = "谜之便当",
    [":LuaSatsujinBento"] = "出牌阶段限一次，你可以展示所有手牌并选择一名有手牌的角色，令其展示手牌并将其中花色唯一的牌对自己使用，若使用的牌不为延时锦囊牌则：黑桃视为【闪电】、红桃视为【乐不思蜀】、梅花视为【兵粮寸断】、方块视为【芥末饭团】，若你以此法置于其判定区的牌多于2张时，你需要弃置等量的牌。",
    ["LuaGluttonous"] = "贪吃",
    [":LuaGluttonous"] = "当一名角色跳过摸牌阶段/出牌阶段时，你可以摸两张牌/于此回合结束后进行一个额外的出牌阶段。",
    ["LuaPlaydumb"] = "装傻",
    [":LuaPlaydumb"] = "出牌阶段限一次，你可以将一张手牌置于一名武将牌上没有“傻”的角色的武将牌上作为“傻”，当其需要进行判定时，以“傻”作为其判定牌；一名角色回合结束后，若其有“傻”，你获得之。",
    ["dumb"] = "傻",
    ["LuaShokkaku"] = "触角",
    [":LuaShokkaku"] = "锁定技，判定区有牌的角色无法闪避你使用的【杀】。",
    ["LuaKaraageshimai"] = "炸鸡姐妹",
    [":LuaKaraageshimai"] = "限定技，当你进入濒死时，你可以分别观看其他所有角色并选择获得其中的一张红桃牌或将其中一张牌视为【乐不思蜀】对其使用。",
    ["@karaage"] = "炸鸡",
    ["LuaKaraageshimai:obtain"] = "获得这张牌",
    ["LuaKaraageshimai:use"] = "视为【乐不思蜀】对其使用",
}
