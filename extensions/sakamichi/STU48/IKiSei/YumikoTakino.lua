require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YumikoTakino_FOYG = sgs.General(STU48, "YumikoTakino_FOYG$", "STU48", 4, false)
table.insert(SKMC.IKiSei, "YumikoTakino_FOYG")

--[[
    技能名：出航
    描述：主公技，锁定技，游戏开始时，若你为「瀧野 由美子」且场上同时存在「甲斐心愛」和「岡田 奈々」，你须将武将牌替换成「STU 48的Center - 瀧野 由美子」并将除了「瀧野 由美子」、「甲斐心愛」、「岡田 奈々」之外的：所有势力不为STU 48的角色的身份牌替换为［反贼］，所有势力为STU 48的角色的身份牌替换为［内奸］。
]]
Luachuhang_y = sgs.CreateTriggerSkill {
    name = "Luachuhang_y$",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        if string.find(player:getGeneralName(), "YumikoTakino") or string.find(player:getGeneral2Name(), "YumikoTakino") then
            local haskokoa = false
            local hasnana = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if string.find(p:getGeneralName(), "kokoakai") or string.find(p:getGeneral2Name(), "kokoakai") then
                    haskokoa = true
                end
                if string.find(p:getGeneralName(), "NanaOkada") or string.find(p:getGeneral2Name(), "NanaOkada") then
                    hasnana = true
                end
            end
            if haskokoa and hasnana then
                room:changeHero(player, "YumikoTakino_COS", true, true, false, true)
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if not (string.find(p:getGeneralName(), "YumikoTakino")
                        or string.find(p:getGeneral2Name(), "YumikoTakino")
                        or string.find(p:getGeneralName(), "kokoakai") or string.find(p:getGeneral2Name(), "kokoakai")
                        or string.find(p:getGeneralName(), "NanaOkada") or string.find(p:getGeneral2Name(), "NanaOkada")) then
                        if p:getKingdom() ~= "STU48" then
                            room:setPlayerProperty(p, "role", sgs.QVariant("rebel"))
                        else
                            room:setPlayerProperty(p, "role", sgs.QVariant("renegade"))
                        end
                    end
                end
            end
        end
        return false
    end,
}
YumikoTakino_FOYG:addSkill(Luachuhang_y)

--[[
    技能名：奈玉米心爱
    描述：锁定技，游戏开始时，若你为「瀧野 由美子」且场上存在「甲斐心愛」且不存在「岡田 奈々」，你须将武将牌替换为「重組家庭的年輕繼母 - 瀧野 由美子」；锁定技，游戏开始时，若你为「瀧野 由美子」且场上存在「岡田 奈々」且不存在「甲斐心愛」，你须将武将牌替换为「舰长的迷妹 - 瀧野 由美子」。
]]
Luayumikokonana_y = sgs.CreateTriggerSkill {
    name = "Luayumikokonana_y",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        if string.find(player:getGeneralName(), "YumikoTakino") or string.find(player:getGeneral2Name(), "YumikoTakino") then
            local haskokoa = false
            local hasnana = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if string.find(p:getGeneralName(), "kokoakai") or string.find(p:getGeneral2Name(), "kokoakai") then
                    haskokoa = true
                end
                if string.find(p:getGeneralName(), "NanaOkada") or string.find(p:getGeneral2Name(), "NanaOkada") then
                    hasnana = true
                end
            end
            if haskokoa and not hasnana then
                room:changeHero(player, "YumikoTakino_YSORF", true, true, false, true)
            end
            if not haskokoa and hasnana then
                room:changeHero(player, "YumikoTakino_CFOFC", true, true, false, true)
            end
        end
        return false
    end,
}
YumikoTakino_FOYG:addSkill(Luayumikokonana_y)

--[[
    技能名：县花
    描述：当你成为其他角色使用的牌的目标后，你可以弃置其至多两张牌，然后失去1点体力，若以此法弃置其少于两张牌，你摸一张牌。
]]
Luaxianhua = sgs.CreateTriggerSkill {
    name = "Luaxianhua",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.TargetConfirmed, sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
    priority = {1, 10, 10},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed and player:hasSkill(self) then
            local use = data:toCardUse()
            if use.card and use.card:getTypeId() == sgs.Card_TypeSkill
                or (use.from and use.from:objectName() == player:objectName()) or (not use.to:contains(player)) then
                return false
            end
            if player:askForSkillInvoke(self:objectName(), data) then
                room:setPlayerFlag(player, "duanzhi_InTempMoving");
                local target = use.from
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                local card_ids = sgs.IntList()
                local original_places = sgs.PlaceList()
                for i = 1, 2, 1 do
                    if not player:canDiscard(target, "he") then
                        break
                    end
                    if room:askForChoice(player, self:objectName(), "discard+cancel") == "cancel" then
                        break
                    end
                    card_ids:append(room:askForCardChosen(player, target, "he", self:objectName()))
                    original_places:append(room:getCardPlace(card_ids:at(i - 1)))
                    dummy:addSubcard(card_ids:at(i - 1))
                    target:addToPile("#xianhua", card_ids:at(i - 1), false)
                end
                local n = dummy:subcardsLength()
                if n > 0 then
                    for i = 1, n, 1 do
                        room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i - 1)), target, original_places:at(i - 1),
                            false)
                    end
                end
                room:setPlayerFlag(player, "-Luaxianhua_InTempMoving")
                if n > 0 then
                    room:throwCard(dummy, target, player)
                end
                dummy:deleteLater()
                room:loseHp(player)
                if n < 2 then
                    player:drawCards(1)
                end
            end
            return false
        elseif event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
            if player:hasFlag("Luaxianhua_InTempMoving") then
                return true
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoTakino_FOYG:addSkill(Luaxianhua)

--[[
    技能名：耍诈
    描述：主公技，限定技，当你进入濒死阶段时，你可以弃置你的区域内的所有牌，然后将武将牌替换为「骯髒的大人 - 瀧野 由美子」，然后将体力回复至体力上限并摸6张牌。
]]
Luashuazha = sgs.CreateTriggerSkill {
    name = "Luashuazha$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@shuazha",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying_data = data:toDying()
        local source = dying_data.who
        if source and source:objectName() == player:objectName() then
            if player:askForSkillInvoke(self:objectName(), data) then
                player:loseMark("@shuazha")
                player:throwAllCards()
                room:changeHero(player, "YumikoTakino_DA", true, true, false, true)
                player:drawCards(6)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target then
            if target:hasSkill(self) then
                if target:isAlive() then
                    return target:getMark("@shuazha") > 0
                end
            end
        end
        return false
    end,
}
YumikoTakino_FOYG:addSkill(Luashuazha)

sgs.LoadTranslationTable {
    ["YumikoTakino_FOYG"] = "瀧野 由美子",
    ["&YumikoTakino_FOYG"] = "瀧野 由美子",
    ["#YumikoTakino_FOYG"] = "山口之花",
    ["designer:YumikoTakino_FOYG"] = "Cassimolar",
    ["cv:YumikoTakino_FOYG"] = "瀧野 由美子",
    ["illustrator:YumikoTakino_FOYG"] = "Cassimolar",
    ["Luachuhang_y"] = "出航",
    [":Luachuhang_y"] = "主公技，锁定技，游戏开始时，若你为「瀧野 由美子」且场上同时存在「甲斐心愛」和「岡田 奈々」，你须将武将牌替换成「STU 48的Center - 瀧野 由美子」并将除了「瀧野 由美子」、「甲斐心愛」、「岡田 奈々」之外的：所有势力不为STU 48的角色的身份牌替换为［反贼］，所有势力为STU 48的角色的身份牌替换为［内奸］。",
    ["Luayumikokonana_y"] = "奈玉米心爱",
    [":Luayumikokonana_y"] = "锁定技，游戏开始时，若你为「瀧野 由美子」且场上存在「甲斐心愛」且不存在「岡田 奈々」，你须将武将牌替换为「重組家庭的年輕繼母 - 瀧野 由美子」；锁定技，游戏开始时，若你为「瀧野 由美子」且场上存在「岡田 奈々」且不存在「甲斐心愛」，你须将武将牌替换为「舰长的迷妹 - 瀧野 由美子」。",
    ["Luaxianhua"] = "县花",
    [":Luaxianhua"] = "当你成为其他角色使用的牌的目标后，你可以弃置其至多两张牌，然后失去1点体力，若以此法弃置其少于两张牌，你摸一张牌。",
    ["Luaxianhua:discard"] = "继续弃牌",
    ["Luaxianhua:cancel"] = "停止弃牌",
    ["Luashuazha"] = "耍诈",
    [":Luashuazha"] = "主公技，限定技，当你处于濒死阶段时，你可以弃置你的区域内的所有牌，然后将武将牌替换为「骯髒的大人 - 瀧野 由美子」，然后将体力回复至体力上限并摸6张牌。",
    ["@shuazha"] = "诈",
}

-- 瀧野 由美子（肮脏的大人）
YumikoTakino_DA = sgs.General(STU48, "YumikoTakino_DA$", "STU48", 3, false, true)
table.insert(SKMC.IKiSei, "YumikoTakino_DA")

--[[
    技能名：肮脏
    描述：当你成为其他角色使用【杀】或通常锦囊牌的目标后，你可以令此牌对你无效并弃置其一张牌，然后你流失1点体力。
]]
Luaangzang = sgs.CreateTriggerSkill {
    name = "Luaangzang",
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player) and use.from and (use.from:objectName() ~= player:objectName()) then
                if use.card:isKindOf("Slash") or use.card:isNDTrick() then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        local nullified_list = use.nullified_list
                        table.insert(nullified_list, player:objectName())
                        use.nullified_list = nullified_list
                        data:setValue(use)
                        if player:canDiscard(use.from, "he") then
                            local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false,
                                sgs.Card_MethodDiscard)
                            room:throwCard(sgs.Sanguosha:getCard(id), use.from, player)
                        end
                        room:loseHp(player)
                    end
                end
            end
        end
        return false
    end,
}
YumikoTakino_DA:addSkill(Luaangzang)

--[[
    技能名：诈术
    描述：当你流失1点体力时，你可以使用一张【杀】，若此杀命中则你回复1点体力。
]]
Luazhashu = sgs.CreateTriggerSkill {
    name = "Luazhashu",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpLost, sgs.CardUsed, sgs.SlashHit, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.HpLost and player:hasSkill(self) then
            local lose = data:toInt()
            for i = 1, lose, 1 do
                room:setPlayerMark(player, "zhashu-Slash", 1)
                local slash = room:askForUseCard(player, "slash", "@askforslash")
                if not slash then
                    room:removePlayerMark(player, "zhashu-Slaah")
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:getMark("zhashu-Slash") == 1 and use.from:hasSkill(self) then
                room:removePlayerMark(use.from, "zhashu-Slash")
                room:setCardFlag(use.card, "zhashu-Slash")
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("zhashu-Slash") then
                room:recover(effect.from, sgs.RecoverStruct(effect.from))
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("zhashu-Slash") then
                room:setCardFlag(use.card, "-zhashu-Slash")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoTakino_DA:addSkill(Luazhashu)

--[[
    技能名：疯化
    描述：主公技，限定技，当你处于濒死阶段时，你可以弃置你的区域内的所有牌，然后将武将牌替换为「巨型金毛 - 瀧野 由美子」，然后将体力回复至体力上限并摸6张牌。
]]
Luafenghua = sgs.CreateTriggerSkill {
    name = "Luafenghua$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@fenghua",
    events = {sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying_data = data:toDying()
        local source = dying_data.who
        if source:objectName() == player:objectName() then
            if player:askForSkillInvoke(self:objectName(), data) then
                player:loseMark("@fenghua")
                player:throwAllCards()
                room:changeHero(player, "YumikoTakino_HGR", true, true, false, true)
                player:drawCards(6)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target then
            if target:hasSkill(self) then
                if target:isAlive() then
                    return target:getMark("@fenghua") > 0
                end
            end
        end
        return false
    end,
}
YumikoTakino_DA:addSkill(Luafenghua)

sgs.LoadTranslationTable {
    ["YumikoTakino_DA"] = "瀧野 由美子",
    ["&YumikoTakino_DA"] = "瀧野 由美子",
    ["#YumikoTakino_DA"] = "骯髒的大人",
    ["designer:YumikoTakino_DA"] = "Cassimolar",
    ["cv:YumikoTakino_DA"] = "瀧野 由美子",
    ["illustrator:YumikoTakino_DA"] = "Cassimolar",
    ["Luaangzang"] = "肮脏",
    [":Luaangzang"] = "当你成为其他角色使用【杀】或通常锦囊牌的目标后，你可以令此牌对你无效并弃置其一张牌，然后你流失1点体力。",
    ["Luazhashu"] = "诈术",
    [":Luazhashu"] = "当你流失1点体力时，你可以使用一张【杀】，若此杀命中则你回复1点体力。",
    ["Luafenghua"] = "疯化",
    [":Luafenghua"] = "主公技，限定技，当你处于濒死阶段时，你可以弃置你的区域内的所有牌，然后将武将牌替换为「巨型金毛 - 瀧野 由美子」，然后将体力回复至体力上限并摸6张牌。",
    ["@fenghua"] = "疯",
}

-- 瀧野 由美子（巨型金毛）
YumikoTakino_HGR = sgs.General(STU48, "YumikoTakino_HGR", "STU48", 4, false, true)
table.insert(SKMC.IKiSei, "YumikoTakino_HGR")

--[[
    技能名：anko
    描述：锁定技，回合开始时，你分别视为对所有为你可以使用【杀】的合法目标的其他角色使用了一张【杀】，所有不为你可以使用【杀】的合法目标的其他角色视为对你使用了一张【杀】。
    引用：
]]
Luaanko = sgs.CreateTriggerSkill {
    name = "Luaanko",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                slash:setSkillName(self:objectName())
                if player:canSlash(p, slash, true) then
                    local use = sgs.CardUseStruct()
                    use.card = slash
                    use.from = player
                    use.to:append(p)
                    room:useCard(use)
                else
                    local use = sgs.CardUseStruct()
                    use.card = slash
                    use.from = p
                    use.to:append(player)
                    room:useCard(use)
                end
            end
        end
    end,
}
YumikoTakino_HGR:addSkill(Luaanko)

--[[
    技能名：wanko
    描述：锁定技，当你用【杀】杀死一名角色后，跳过奖惩结算，你摸3张牌并回复1点体力。
    引用：
]]
Luawanko = sgs.CreateTriggerSkill {
    name = "Luawanko",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.BuryVictim},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local reason = death.damage
        if reason and reason.card and reason.card:isKindOf("Slash") then
            local killer = reason.from
            if killer and killer:isAlive() and killer:hasSkill(self) then
                player:bury()
                killer:drawCards(3)
                room:recover(killer, sgs.RecoverStruct(killer))
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoTakino_HGR:addSkill(Luawanko)

--[[
    技能名：yumianko
    描述：锁定技，你的攻击范围始终等于你的手牌数与已损失体力值的较大值。
    引用：
]]
Luayumianko = sgs.CreateAttackRangeSkill {
    name = "Luayumianko",
    fixed_func = function(self, player, include_weapon)
        if player:hasSkill(self) then
            return math.max(player:getHandcardNum(), player:getLostHp())
        end
    end,
}
YumikoTakino_HGR:addSkill(Luayumianko)

sgs.LoadTranslationTable {
    ["YumikoTakino_HGR"] = "瀧野 由美子",
    ["&YumikoTakino_HGR"] = "瀧野 由美子",
    ["#YumikoTakino_HGR"] = "巨型金毛",
    ["designer:YumikoTakino_HGR"] = "Cassimolar",
    ["cv:YumikoTakino_HGR"] = "瀧野 由美子",
    ["illustrator:YumikoTakino_HGR"] = "Cassimolar",
    ["Luaanko"] = "アンコ",
    [":Luaanko"] = "锁定技，回合开始时，你分别视为对所有为你可以使用【杀】的合法目标的其他角色使用了一张【杀】，所有不为你可以使用【杀】的合法目标的其他角色视为对你使用了一张【杀】。",
    ["Luawanko"] = "ワンコ",
    [":Luawanko"] = "锁定技，当你用【杀】杀死一名角色后，跳过奖惩结算，你摸3张牌并回复1点体力。",
    ["Luayumianko"] = "ユミアンコ",
    [":Luayumianko"] = "锁定技，你的攻击范围始终等于你的手牌数与已损失体力值的较大值。",
}

-- 瀧野 由美子（重组家庭的年轻继母）
YumikoTakino_YSORF = sgs.General(STU48, "YumikoTakino_YSORF", "STU48", 5, false, true)
table.insert(SKMC.IKiSei, "YumikoTakino_YSORF")

--[[
    技能名：持家
    描述：锁定技，你的每个阶段开始时，你视为使用一张【无中生有】；锁定技，你的每个阶段结束时，你视为使用一张【五谷丰登】。
]]
Luachijia = sgs.CreateTriggerSkill {
    name = "Luachijia",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_RoundStart and player:getPhase() ~= sgs.Player_NotActive
                and player:getPhase() ~= sgs.Player_PhaseNone then
                local ex_nihilo = sgs.Sanguosha:cloneCard("ExNihilo", sgs.Card_NoSuit, -1)
                ex_nihilo:setSkillName(self:objectName())
                local use = sgs.CardUseStruct()
                use.card = ex_nihilo
                use.from = player
                use.to:append(player)
                room:useCard(use)
            end
        else
            if player:getPhase() ~= sgs.Player_RoundStart and player:getPhase() ~= sgs.Player_NotActive
                and player:getPhase() ~= sgs.Player_PhaseNone then
                local amazing_grace = sgs.Sanguosha:cloneCard("AmazingGrace", sgs.Card_NoSuit, -1)
                amazing_grace:setSkillName(self:objectName())
                local use = sgs.CardUseStruct()
                use.card = amazing_grace
                use.from = player
                use.to:append(player)
                room:useCard(use)
            end
        end
    end,
}
YumikoTakino_YSORF:addSkill(Luachijia)

--[[
    技能名：玉米心爱
    描述：锁定技，你的手牌上限始终等于「瀧野 由美子」和「甲斐心愛」的体力值之和。
]]
Luayumikoko = sgs.CreateMaxCardsSkill {
    name = "Luayumikoko",
    fixed_func = function(self, target)
        if target:hasSkill(self) then
            local n = 0
            if string.find(target:getGeneralName(), "YumikoTakino")
                or string.find(target:getGeneral2Name(), "YumikoTakino")
                or string.find(target:getGeneralName(), "kokoakai") or string.find(target:getGeneral2Name(), "kokoakai") then
                n = n + target:getHp()
            end
            for _, p in sgs.qlist(target:getSiblings()) do
                if string.find(p:getGeneralName(), "YumikoTakino") or string.find(p:getGeneral2Name(), "YumikoTakino")
                    or string.find(p:getGeneralName(), "kokoakai") or string.find(p:getGeneral2Name(), "kokoakai") then
                    n = n + p:getHp()
                end
            end
            return n
        end
        return -1
    end,
}
YumikoTakino_YSORF:addSkill(Luayumikoko)

sgs.LoadTranslationTable {
    ["YumikoTakino_YSORF"] = "瀧野 由美子",
    ["&YumikoTakino_YSORF"] = "瀧野 由美子",
    ["#YumikoTakino_YSORF"] = "重組家庭的年輕繼母",
    ["designer:YumikoTakino_YSORF"] = "Cassimolar",
    ["cv:YumikoTakino_YSORF"] = "瀧野 由美子",
    ["illustrator:YumikoTakino_YSORF"] = "Cassimolar",
    ["Luachijia"] = "持家",
    [":Luachijia"] = "锁定技，你的每个阶段开始时，你视为使用一张【无中生有】；锁定技，你的每个阶段结束时，你视为使用一张【五谷丰登】。",
    ["Luayumikoko"] = "玉米心爱",
    [":Luayumikoko"] = "锁定技，你的手牌上限始终等于「瀧野 由美子」和「甲斐心愛」的体力值之和。",
}

-- 瀧野 由美子（舰长的迷妹）
YumikoTakino_CFOFC = sgs.General(STU48, "YumikoTakino_CFOFC", "STU48", 3, false, true)
table.insert(SKMC.IKiSei, "YumikoTakino_CFOFC")

--[[
    技能名：黑白棋
    描述：出牌阶段限一次，你可以令一名装备区内有牌的其他角色进行二选一：令你获得其装备区所有牌然后其摸两张牌，或其获得其装备区所有牌然后令你摸两张牌。
]]
LuaheibaiqiCard = sgs.CreateSkillCard {
    name = "LuaheibaiqiCard",
    skill_name = "Luaheibaiqi",
    filter = function(self, targets, to_select)
        return to_select:hasEquip() and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        dummy:addSubcards(effect.to:getEquips())
        local choice = room:askForChoice(effect.to, "Luaheibaiqi", "getequips+drawcards")
        if choice == "getequips" then
            room:obtainCard(effect.from, dummy)
            effect.to:drawCards(2)
        else
            effect.from:drawCards(2)
            room:obtainCard(effect.to, dummy)
        end
        dummy:deleteLater()
    end,
}
Luaheibaiqi = sgs.CreateZeroCardViewAsSkill {
    name = "Luaheibaiqi",
    view_as = function()
        return LuaheibaiqiCard:clone()
    end,
    enabled_at_play = function(self, player)
        for _, p in sgs.qlist(player:getSiblings()) do
            if p:hasEquip() then
                return not player:hasUsed("#LuaheibaiqiCard")
            end
        end
        return false
    end,

}
YumikoTakino_CFOFC:addSkill(Luaheibaiqi)
YumikoTakino_CFOFC:addSkill("Luanayumi")

sgs.LoadTranslationTable {
    ["YumikoTakino_CFOFC"] = "瀧野 由美子",
    ["&YumikoTakino_CFOFC"] = "瀧野 由美子",
    ["#YumikoTakino_CFOFC"] = "舰长的迷妹",
    ["designer:YumikoTakino_CFOFC"] = "Cassimolar",
    ["cv:YumikoTakino_CFOFC"] = "瀧野 由美子",
    ["illustrator:YumikoTakino_CFOFC"] = "Cassimolar",
    ["Luaheibaiqi"] = "黑白棋",
    [":Luaheibaiqi"] = "出牌阶段限一次，你可以令一名装备区内有牌的其他角色进行二选一：令你获得其装备区所有牌然后其摸两张牌，或其获得其装备区所有牌然后令你摸两张牌。",
    ["Luaheibaiqi:getequips"] = "令其获得你装备区所有牌",
    ["Luaheibaiqi:drawcards"] = "令其摸两张牌",
}

-- 瀧野 由美子（STU 48的Center）
YumikoTakino_COS = sgs.General(STU48, "YumikoTakino_COS$", "STU48", 4, false, true)
table.insert(SKMC.IKiSei, "YumikoTakino_COS")

--[[
    技能名：船C
    描述：主公技，当「STU 48的熊孩子 - 甲斐心愛」或「STU 48的舰长 - 岡田 奈々」处于濒死状态时，你可以失去1点体力并弃置一张牌，令该角色回复1点体力。
]]
LuachuanCCard = sgs.CreateSkillCard {
    name = "LuachuanCCard",
    skill_name = "LuachuanC",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local who = room:getCurrentDyingPlayer()
        if not who then
            return
        end
        room:loseHp(source)
        room:recover(from, sgs.RecoverStruct(source))
    end,
}
LuachuanC = sgs.CreateViewAsSkill {
    name = "LuachuanC",
    n = 1,
    view_filter = function(self, selected, to_select)
        return #selected == 0
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        if pattern ~= "peach" or not player:canDiscard(player, "he") then
            return false
        end
        local dyingobj = player:property("currentdying"):toString()
        local who = nil
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:objectName() == dyingobj
                and (p:getGeneralName() == "NanaOkada_COS" or p:getGeneral2Name() == "NanaOkada_COS"
                    or p:getGeneralName() == "kokoakai_NCOS" or p:getGeneral2Name() == "kokoakai_NCOS") then
                who = p
                break
            end
        end
        if not who then
            return false
        end
        return true
    end,
    view_as = function(self, cards)
        if #cards ~= 1 then
            return nil
        end
        local card = LuachuanCCard:clone()
        card:addSubcard(cards[1])
        return card
    end,
}
YumikoTakino_COS:addSkill(LuachuanC)

--[[
    技能名：えへへ
    描述：限定技，当你进入濒死状态时，你可以从所有其他角色的手牌区各获得一张牌。
]]
Luaehehe = sgs.CreateTriggerSkill {
    name = "Luaehehe",
    frequency = sgs.Skill_Limited,
    events = {sgs.Dying},
    limit_mark = "@ehehe",
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        local players = room:getOtherPlayers(player)
        local can_invoke = false
        for _, p in sgs.qlist(players) do
            if not p:isKongcheng() then
                can_invoke = true
                break
            end
        end
        if can_invoke and dying.who:objectName() == player:objectName() and player:getMark("@ehehe") ~= 0 then
            if player:askForSkillInvoke(self:objectName(), data) then
                player:loseMark("@ehehe")
                for _, _player in sgs.qlist(players) do
                    if _player:isAlive() and (not _player:isKongcheng()) then
                        local card_id = room:askForCardChosen(player, _player, "h", self:objectName())
                        room:obtainCard(player, sgs.Sanguosha:getCard(card_id),
                            room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
                    end
                end
            end
        end
        return false
    end,
}
YumikoTakino_COS:addSkill(Luaehehe)

--[[
    技能名：小仙女
    描述：限定技，出牌阶段，你可以弃置一张手牌并选择一名角色，对其造成1点伤害，然后你摸三张牌，若其拥有限定技，你可以令其中一个限定技于此回合结束后视为未发动。
]]
LuaxiaoxiannvCard = sgs.CreateSkillCard {
    name = "Luaxiaoxiannv",
    skill_name = "Luaxiaoxiannv",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        from:loseMark("@xiaoxiannv")
        room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
        source:drawCards(3, self:objectName())
        local SkillList = {}
        for _, skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
            if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and skill:getFrequency()
                == sgs.Skill_Limited then
                table.insert(SkillList, skill:objectName())
            end
        end
        if #SkillList > 0 then
            local choice = room:askForChoice(source, self:objectName(), table.concat(SkillList, "+"))
            SKMC.choice_log(source, choice)
            room:addPlayerMark(targets[1], self:objectName() .. choice)
        end
    end,
}
LuaxiaoxiannvVS = sgs.CreateOneCardViewAsSkill {
    name = "Luaxiaoxiannv",
    filter_pattern = ".",
    view_as = function(self, card)
        local cards = LuaxiaoxiannvCard:clone()
        cards:addSubcard(card)
        return cards
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@xiaoxiannv") ~= 0
    end,
}
Luaxiaoxiannv = sgs.CreatePhaseChangeSkill {
    name = "Luaxiaoxiannv",
    view_as_skill = LuaxiaoxiannvVS,
    frequency = sgs.Skill_Limited,
    limit_mark = "@xiaoxiannv",
    on_phasechange = function(self, player)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            for _, skill in sgs.qlist(p:getVisibleSkillList()) do
                if p:getMark(self:objectName() .. skill:objectName()) > 0 and player:getPhase() == sgs.Player_Finish then
                    room:handleAcquireDetachSkills(p, "-" .. skill:objectName() .. "|" .. skill:objectName())
                end
            end
        end
    end,
}
YumikoTakino_COS:addSkill(Luaxiaoxiannv)

--[[
    技能名：新干线
    描述：锁定技，你使用【杀】指定目标后，若目标中有你到其距离为1的，你须为此【杀】额外指定一个合法目标，重复此流程直到目标中存在你到其不为1的目标或所有合法目标都是此【杀】的目标。
]]
Luaxinganxian = sgs.CreateTriggerSkill {
    name = "Luaxinganxian",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            local can_invoke = false
            for _, p in sgs.qlist(use.to) do
                if player:distanceTo(p) == 1 then
                    can_invoke = true
                    break
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
                local hasnotone = false
                while not targets:isEmpty() and not hasnotone do
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@xinganxian_invoke",
                        false, true)
                    local msg = sgs.LogMessage()
                    msg.type = "#xinganxian-target"
                    msg.from = player
                    msg.to:append(target)
                    msg.arg = use.card:objectName()
                    msg.arg2 = self:objectName()
                    room:sendLog(msg)
                    use.to:append(target)
                    targets:removeOne(target)
                    if player:distanceTo(target) ~= 1 then
                        hasnotone = true
                    end
                end
                data:setValue(use)
            end
        end
        return false
    end,
}
YumikoTakino_COS:addSkill(Luaxinganxian)

--[[
    技能名：铁道
    描述：锁定技，你视为处于连环状态；锁定技，处于连环状态的角色的手牌上限+2；锁定技，结束阶段开始时，你横置一名角色。
]]
Luatiedao = sgs.CreateTriggerSkill {
    name = "Luatiedao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.ChainStateChange},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if not player:isChained() then
                room:setPlayerChained(player)
            end
        end
        if event == sgs.ChainStateChange and player:isChained() then
            return true
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not p:isChained() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target =
                    room:askForPlayerChosen(player, targets, self:objectName(), "@tiedao_invoke", false, true)
                if target then
                    room:setPlayerChained(target)
                end
            end
        end
    end,
}
LuatiedaoMaxCards = sgs.CreateMaxCardsSkill {
    name = "#LuatiedaoMaxCards",
    extra_func = function(self, target)
        local n = 0
        if target:hasSkill("Luatiedao") and target:isChained() then
            n = n + 2
        end
        for _, p in sgs.qlist(target:getAliveSiblings()) do
            if p:hasSkill("Luatiedao") and target:isChained() then
                n = n + 2
                break
            end
        end
        return n
    end,
}
STU48:insertRelatedSkills("Luatiedao", "#LuatiedaoMaxCards")
YumikoTakino_COS:addSkill(Luatiedao)
YumikoTakino_COS:addSkill(LuatiedaoMaxCards)

sgs.LoadTranslationTable {
    ["YumikoTakino_COS"] = "瀧野 由美子",
    ["&YumikoTakino_COS"] = "瀧野 由美子",
    ["#YumikoTakino_COS"] = "STU 48的Center",
    ["designer:YumikoTakino_COS"] = "Cassimolar",
    ["cv:YumikoTakino_COS"] = "瀧野 由美子",
    ["illustrator:YumikoTakino_COS"] = "Cassimolar",
    ["LuachuanC"] = "船C",
    [":LuachuanC"] = "主公技，当「STU 48的熊孩子 - 甲斐心愛」或「STU 48的舰长 - 岡田 奈々」处于濒死状态时，你可以失去1点体力并弃置一张牌，令该角色回复1点体力。",
    ["LuachuanCCard"] = "船C",
    ["Luaehehe"] = "えへへ",
    [":Luaehehe"] = "限定技，当你进入濒死状态时，你可以从所有其他角色的手牌区各获得一张牌。",
    ["@ehehe"] = "えへへ",
    ["Luaxiaoxiannv"] = "小仙女",
    [":Luaxiaoxiannv"] = "限定技，出牌阶段，你可以弃置一张手牌并选择一名角色，对其造成1点伤害，然后你摸三张牌，若其拥有限定技，你可以令其中一个限定技于此回合结束后视为未发动。",
    ["@xiaoxiannv"] = "小仙女",
    ["Luaxinganxian"] = "新干线",
    [":Luaxinganxian"] = "锁定技，你使用【杀】指定目标后，若目标中有你到其距离为1的，你须为此【杀】额外指定一个合法目标，重复此流程直到目标中存在你到其不为1的目标或所有合法目标都是此【杀】的目标。",
    ["@xinganxian_invoke"] = "请为此【杀】选择一个额外目标",
    ["#xinganxian-target"] = "%from 的【%arg2】被触发，%from 选择 %to 成为【%arg】的额外目标",
    ["Luatiedao"] = "铁道",
    [":Luatiedao"] = "锁定技，你视为处于连环状态；锁定技，处于连环状态的角色的手牌上限+2；锁定技，结束阶段开始时，你横置一名角色。",
    ["@tiedao_invoke"] = "请选择要横置的角色",
}
