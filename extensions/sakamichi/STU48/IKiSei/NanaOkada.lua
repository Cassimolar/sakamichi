require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

-- 岡田 奈々（Team 4的副队长）
NanaOkada_VCOTF = sgs.General(STU48, "NanaOkada_VCOTF", "STU48", 4, false)
table.insert(SKMC.IKiSei, "NanaOkada_VCOTF")

--[[
    技能名：出航
    描述：锁定技，游戏开始时，若你为「岡田 奈々」且场上存在「甲斐心愛」并且主公为「瀧野 由美子」，你须将武将牌替换成「STU 48的舰长 - 岡田 奈々」并将你的身份牌替换为［忠臣］，然后与主公下家交换座位。
]]
Luachuhang_n = sgs.CreateTriggerSkill {
    name = "Luachuhang_n",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        if string.find(player:getGeneralName(), "NanaOkada") or string.find(player:getGeneral2Name(), "NanaOkada") then
            local lordyumiko = false
            local haskokoa = false
            local lord = room:getLord()
            if string.find(lord:getGeneralName(), "yumikotakino") or string.find(lord:getGeneral2Name(), "yumikotakino") then
                lordyumiko = true
            end
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if string.find(p:getGeneralName(), "kokoakai") or string.find(p:getGeneral2Name(), "kokoakai") then
                    haskokoa = true
                end
            end
            if lordyumiko and haskokoa then
                room:changeHero(player, "NanaOkada_COS", true, true, false, true)
                room:setPlayerProperty(player, "role", sgs.QVariant("loyalist"))
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if lord:getNextAlive():objectName() == p:objectName() then
                        room:swapSeat(player, p)
                        break
                    end
                end
            end
        end
        return false
    end,
}
NanaOkada_VCOTF:addSkill(Luachuhang_n)

--[[
    技能名：奈玉米心爱
    描述：锁定技，游戏开始时，若你为「岡田 奈々」且场上存在「瀧野 由美子」且不存在「甲斐心愛」，你须将武将牌替换为「玉米林的偶像 - 岡田 奈々」；锁定技，游戏开始时，若你为「岡田 奈々」且场上存在「甲斐心愛」且不存在「瀧野 由美子」，你须将武将牌替换为「可以可以的家長 - 岡田 奈々」。
]]
Luayumikokonana_n = sgs.CreateTriggerSkill {
    name = "Luayumikokonana_n",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        if string.find(player:getGeneralName(), "NanaOkada") or string.find(player:getGeneral2Name(), "NanaOkada") then
            local haskokoa = false
            local hasyumiko = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if string.find(p:getGeneralName(), "kokoakai") or string.find(p:getGeneral2Name(), "kokoakai") then
                    haskokoa = true
                end
                if string.find(p:getGeneralName(), "yumikotakino") or string.find(p:getGeneral2Name(), "yumikotakino") then
                    hasyumiko = true
                end
            end
            if haskokoa and not hasyumiko then
                room:changeHero(player, "NanaOkada_POKK", true, true, false, true)
            end
            if not haskokoa and hasyumiko then
                room:changeHero(player, "NanaOkada_TIOY", true, true, false, true)
            end
        end
        return false
    end,
}
NanaOkada_VCOTF:addSkill(Luayumikokonana_n)

--[[
    技能名：副队长
    描述：每当一名角色成为【杀】的目标后，你可以摸一张牌，然后正面朝上交给该角色一张牌：若该牌为装备牌，该角色可以使用之。
]]
Luafuduizhang = sgs.CreateTriggerSkill {
    name = "Luafuduizhang",
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            for _, to in sgs.qlist(use.to) do
                if not player:isAlive() then
                    break
                end
                if player:hasSkill(self) then
                    -- player:setTag("LuafuduizhangSlash", data)
                    local to_data = sgs.QVariant()
                    to_data:setValue(to)
                    local will_use = room:askForSkillInvoke(player, self:objectName(), to_data)
                    -- player:removeTag("LuafuduizhangSlash")
                    if will_use then
                        player:drawCards(1)
                        if not player:isNude() and player:objectName() ~= to:objectName() then
                            local card = nil
                            if player:getCardCount() > 1 then
                                card = room:askForCard(player, "..!", "@fuduizhang_give:" .. to:objectName(), data,
                                    sgs.Card_MethodNone)
                                if not card then
                                    card = player:getCards("he"):at(math.random(player:getCardCount()))
                                end
                            else
                                card = player:getCards("he"):first()
                            end
                            to:obtainCard(card)
                            if card:getTypeId() == sgs.Card_TypeEquip
                                and room:getCardOwner(card:getEffectiveId()):objectName() == to:objectName()
                                and not to:isLocked(card) then
                                -- local xdata = sgs.QVariant()
                                -- xdata:setValue(card)
                                -- to:setTag("LuafuduizhangSlash", data)
                                -- to:setTag("LuafuduizhangGivenCard", xdata)
                                local will_use = room:askForSkillInvoke(to, "fuduizhang_use", sgs.QVariant("use"))
                                -- to:removeTag("LuafuduizhangSlash")
                                -- to:removeTag("LuafuduizhangGivenCard")
                                if will_use then
                                    room:useCard(sgs.CardUseStruct(card, to, to))
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
NanaOkada_VCOTF:addSkill(Luafuduizhang)

sgs.LoadTranslationTable {
    ["NanaOkada_VCOTF"] = "岡田 奈々",
    ["&NanaOkada_VCOTF"] = "岡田 奈々",
    ["#NanaOkada_VCOTF"] = "Team 4的副隊長",
    ["designer:NanaOkada_VCOTF"] = "Cassimolar",
    ["cv:NanaOkada_VCOTF"] = "岡田 奈々",
    ["illustrator:NanaOkada_VCOTF"] = "Cassimolar",
    ["Luachuhang_n"] = "出航",
    [":Luachuhang_n"] = "锁定技，游戏开始时，若你为「岡田 奈々」且场上存在「甲斐心愛」并且主公为「瀧野 由美子」，你须将武将牌替换成「STU 48的舰长 - 岡田 奈々」并将你的身份牌替换为［忠臣］，然后与主公下家交换座位。",
    ["Luayumikokonana_n"] = "奈玉米心爱",
    [":Luayumikokonana_n"] = "锁定技，游戏开始时，若你为「岡田 奈々」且场上存在「瀧野 由美子」且不存在「甲斐心愛」，你须将武将牌替换为「玉米林的偶像 - 岡田 奈々」；锁定技，游戏开始时，若你为「岡田 奈々」且场上存在「甲斐心愛」且不存在「瀧野 由美子」，你须将武将牌替换为「可以可以的家長 - 岡田 奈々」。",
    ["Luafuduizhang"] = "副队长",
    [":Luafuduizhang"] = "每当一名角色成为【杀】的目标后，你可以摸一张牌，然后正面朝上交给该角色一张牌：若该牌为装备牌，该角色可以使用之。",
    ["@fuduizhang_give"] = "请交给 %src 一张牌",
}

-- 岡田 奈々（玉米林的偶像）
NanaOkada_TIOY = sgs.General(STU48, "NanaOkada_TIOY", "STU48", 4, false, true)
table.insert(SKMC.IKiSei, "NanaOkada_TIOY")

--[[
    技能名：三銃士
    描述：当你失去一次装备区里的牌时，你可以选择一项：1.令一名角色回复1点体力。2.对一名角色造成1点伤害。3.令一名其他角色摸两张牌。
]]
LuaLesTroisMousquetaires = sgs.CreateTriggerSkill {
    name = "LuaLesTroisMousquetaires",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then
                if move.from_places:contains(sgs.Player_PlaceEquip) then
                    local choice = room:askForChoice(player, self:objectName(), "recover+damage+draw+cancel")
                    if choice == "recover" then
                        local target = room:askForPlayerChosen(player, room:getAlivePlayers(),
                            "@LesTroisMousquetaires-recover")
                        room:recover(target, sgs.RecoverStruct(player))
                    elseif choice == "damage" then
                        local target = room:askForPlayerChosen(player, room:getAlivePlayers(),
                            "@LesTroisMousquetaires-damage")
                        room:damage(sgs.DamageStruct(self:objectName(), player, target))
                    elseif choice == "draw" then
                        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player),
                            "@LesTroisMousquetaires-draw")
                        target:drawCards(2)
                    end
                end
            end
        end
        return false
    end,
}
NanaOkada_TIOY:addSkill(LuaLesTroisMousquetaires)

--[[
    技能名：奈玉米
    描述：你可以重铸装备牌，你以此法重铸装备牌时额外摸一张牌。
]]
LuanayumiCard = sgs.CreateSkillCard {
    name = "LuanayumiCard",
    skill_name = "Luanayumi",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:moveCardTo(self, source, nil, sgs.Player_DiscardPile,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), "Luanayumi", ""))
        room:broadcastSkillInvoke("@recast")
        local msg = sgs.LogMessage()
        msg.type = "#UseCard_Recast"
        msg.from = source
        msg.card_str = tostring(self:getSubcards():first())
        room:sendLog(msg)
        source:drawCards(2, "recast")
    end,
}
Luanayumi = sgs.CreateOneCardViewAsSkill {
    name = "Luanayumi",
    filter_pattern = "EquipCard",
    view_as = function(self, card)
        local skill_card = LuanayumiCard:clone()
        skill_card:addSubcard(card)
        skill_card:setSkillName(self:objectName())
        return skill_card
    end,
    enabled_at_play = function(self, player)
        if player:hasEquip() then
            return true
        else
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isKindOf("EquipCard") then
                    return true
                end
            end
        end
        return false
    end,
}
NanaOkada_TIOY:addSkill(Luanayumi)

sgs.LoadTranslationTable {
    ["NanaOkada_TIOY"] = "岡田 奈々",
    ["&NanaOkada_TIOY"] = "岡田 奈々",
    ["#NanaOkada_TIOY"] = "玉米林的偶像",
    ["designer:NanaOkada_TIOY"] = "Cassimolar",
    ["cv:NanaOkada_TIOY"] = "岡田 奈々",
    ["illustrator:NanaOkada_TIOY"] = "Cassimolar",
    ["LuaLesTroisMousquetaires"] = "三銃士",
    [":LuaLesTroisMousquetaires"] = "当你失去一次装备区里的牌时，你可以选择一项：\
    1.令一名角色回复1点体力。\
    2.对一名角色造成1点伤害。\
    3.令一名其他角色摸两张牌。",
    ["LuaLesTroisMousquetaires:recover"] = "令一名角色回复1点体力",
    ["LuaLesTroisMousquetaires:damage"] = "对一名角色造成1点伤害",
    ["LuaLesTroisMousquetaires:draw"] = "令一名其他角色摸两张牌",
    ["LuaLesTroisMousquetaires:cancel"] = "取消",
    ["@LesTroisMousquetaires-recover"] = "选择一名角色令其回复1点体力",
    ["@LesTroisMousquetaires-damage"] = "选择一名角色对其造成1点伤害",
    ["@LesTroisMousquetaires-draw"] = "选择一名其他角色令其摸两张牌",
    ["Luanayumi"] = "奈玉米",
    [":Luanayumi"] = "你可以重铸装备牌，你以此法重铸装备牌时额外摸一张牌。",
}

-- 岡田 奈々（可以可以的家长）
NanaOkada_POKK = sgs.General(STU48, "NanaOkada_POKK", "STU48", 5, false, true)
table.insert(SKMC.IKiSei, "NanaOkada_POKK")

--[[
    技能名：小瓢虫Chu!
    描述：出牌阶段限一次，你可以展示一张手牌并确认此牌的花色并将之交给一名角色，令其选择一项：1．展示所有手牌并弃置所有为此花色的牌；2．失去1点体力。
]]
LuaTentomuChuCard = sgs.CreateSkillCard {
    name = "LuaTentomuChuCard",
    skill_name = "LuaTentomuChu",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    on_effect = function(self, effect)
        local player = effect.from
        local target = effect.to
        local room = player:getRoom()
        local subid = self:getSubcards():first()
        local card = sgs.Sanguosha:getCard(subid)
        local card_id = card:getEffectiveId()
        local suit = card:getSuit()
        room:showCard(player, card_id)
        room:obtainCard(target, self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
            target:objectName(), "LuaTentomuChu", ""))
        if target:isAlive() then
            if target:isNude() then
                room:loseHp(target)
            else
                if room:askForSkillInvoke(target, "TentomuChu_discard",
                    sgs.QVariant("prompt:::" .. sgs.Card_Suit2String(suit))) then
                    room:showAllCards(target)
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    for _, card in sgs.qlist(target:getCards("he")) do
                        if card:getSuit() == suit then
                            dummy:addSubcard(card)
                        end
                    end
                    if dummy:subcardsLength() > 0 then
                        room:throwCard(dummy, target)
                    end
                    dummy:deleteLater()
                else
                    room:loseHp(target)
                end
            end
        end
    end,
}
LuaTentomuChu = sgs.CreateOneCardViewAsSkill {
    name = "LuaTentomuChu",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local acard = LuaTentomuChuCard:clone()
        acard:addSubcard(card)
        acard:setSkillName(self:objectName())
        return acard
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#LuaTentomuChuCard")
    end,
}
NanaOkada_POKK:addSkill(LuaTentomuChu)

--[[
    技能名：可以可以奈奈
    描述：你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于当前体力值，则你摸一张牌。
]]
Luakokoanana = sgs.CreateTriggerSkill {
    name = "Luakokoanana",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.to and move.from:objectName() == player:objectName() and move.from:objectName()
            ~= move.to:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
            if player:getHandcardNum() < player:getHp() then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
NanaOkada_POKK:addSkill(Luakokoanana)

sgs.LoadTranslationTable {
    ["NanaOkada_POKK"] = "岡田 奈々",
    ["&NanaOkada_POKK"] = "岡田 奈々",
    ["#NanaOkada_POKK"] = "可以可以的家長",
    ["designer:NanaOkada_POKK"] = "Cassimolar",
    ["cv:NanaOkada_POKK"] = "岡田 奈々",
    ["illustrator:NanaOkada_POKK"] = "Cassimolar",
    ["LuaTentomuChu"] = "小瓢虫Chu!",
    [":LuaTentomuChu"] = "出牌阶段限一次，你可以展示一张手牌并确认此牌的花色并将之交给一名角色，令其选择一项：1．展示所有手牌并弃置所有为此花色的牌；2．失去1点体力。",
    ["LuaTentomuChuCard"] = "小瓢虫Chu!",
    ["TentomuChu_discard:prompt"] = "你可以展示所有手牌并弃置所有 %arg 牌",
    ["Luakokoanana"] = "可以可以奈奈",
    [":Luakokoanana"] = "你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于当前体力值，则你摸一张牌。",
}

-- 岡田 奈々（STU 48的舰长）
NanaOkada_COS = sgs.General(STU48, "NanaOkada_COS", "STU48", 4, false, true)
table.insert(SKMC.IKiSei, "NanaOkada_COS")

--[[
    技能名：兼任
    描述：回合结束阶段开始时，你可以进行以下四选一：
        1. 永久改变一名其他角色的势力；
        2. 永久获得一项未上场或已死亡角色的主公技。（获得后即使你不是主公仍然有效）；
        3.永久获得一项未上场或已死亡角色的限定技，你以此选项获得3次限定技后失去此选项；
        4.选择一名角色，直到你的下个回合结束阶段开始时，所有角色到该角色距离视为1。
]]
Luajianren = sgs.CreateTriggerSkill {
    name = "Luajianren",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:getMark("jianrendistance") ~= 0 then
                    room:setPlayerMark(p, "jianrendistance", 0)
                end
            end
            if room:askForSkillInvoke(player, self:objectName()) then
                local choices = {"modify", "obtainLordskill", "distance"}
                if player:getMark("jianren_limitedskill") < 3 then
                    table.insert(choices, "obtainLimitedskill")
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                local others = room:getOtherPlayers(player)
                if choice == "modify" then
                    local to_modify = room:askForPlayerChosen(player, others, self:objectName())
                    local ai_data = sgs.QVariant()
                    ai_data:setValue(to_modify)
                    room:setTag("jianrenModify", ai_data)
                    local kingdomList = sgs.Sanguosha:getKingdoms()
                    table.removeOne(kingdomList, "god")
                    local kingdom = room:askForChoice(player, self:objectName(), table.concat(kingdomList, "+"))
                    room:removeTag("jianrenModify")
                    room:setPlayerProperty(to_modify, "kingdom", sgs.QVariant(kingdom))
                elseif choice == "obtainLordskill" then
                    local lords = sgs.Sanguosha:getLords()
                    for _, p in sgs.qlist(others) do
                        table.removeOne(lords, p:getGeneralName())
                    end
                    local lord_skills = {}
                    for _, lord in ipairs(lords) do
                        local general = sgs.Sanguosha:getGeneral(lord)
                        local skills = general:getSkillList()
                        for _, skill in sgs.qlist(skills) do
                            if skill:isLordSkill() then
                                if not player:hasSkill(skill:objectName()) then
                                    table.insert(lord_skills, skill:objectName())
                                end
                            end
                        end
                    end
                    if #lord_skills > 0 then
                        local choices = table.concat(lord_skills, "+")
                        local skill_name = room:askForChoice(player, self:objectName(), choices)
                        local skill = sgs.Sanguosha:getSkill(skill_name)
                        room:acquireSkill(player, skill)
                        local EX = sgs.Sanguosha:getTriggerSkill(skill:objectName())
                        EX:trigger(sgs.GameStart, room, player, sgs.QVariant())
                    end
                elseif choice == "obtainLimitedskill" then
                    local allnames = sgs.Sanguosha:getLimitedGeneralNames()
                    for _, p in sgs.qlist(others) do
                        table.removeOne(allnames, p:getGeneralName())
                    end
                    local limited_skills = {}
                    for _, p in ipairs(allnames) do
                        local general = sgs.Sanguosha:getGeneral(p)
                        local skills = general:getSkillList()
                        for _, skill in sgs.qlist(skills) do
                            if skill:getFrequency() == sgs.Skill_Limited then
                                if not player:hasSkill(skill:objectName()) then
                                    table.insert(limited_skills, skill:objectName())
                                end
                            end
                        end
                    end
                    if #limited_skills > 0 then
                        local choices = table.concat(limited_skills, "+")
                        local skill_name = room:askForChoice(player, self:objectName(), choices)
                        local skill = sgs.Sanguosha:getSkill(skill_name)
                        room:acquireSkill(player, skill)
                        room:addPlayerMark(player, "jianren_limitedskill")
                        local EX = sgs.Sanguosha:getTriggerSkill(skill:objectName())
                        EX:trigger(sgs.GameStart, room, player, sgs.QVariant())
                    end
                else
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                        "@jianren_invoke")
                    room:setPlayerMark(target, "jianrendistance", 1)
                end
            end
        end
        return false
    end,
}
LuajianrenDistance = sgs.CreateDistanceSkill {
    name = "#LuajianrenDistance",
    correct_func = function(self, from, to)
        if to:getMark("jianrendistance") ~= 0 then
            return -1000
        end
        return 0
    end,
}
STU48:insertRelatedSkills("Luajianren", "#LuajianrenDistance")
NanaOkada_COS:addSkill(Luajianren)
NanaOkada_COS:addSkill(LuajianrenDistance)

--[[
    技能名：舰长
    描述：锁定技，「STU 48的舰长 - 岡田 奈々」、「STU 48的Center - 瀧野 由美子」、「STU 48的熊孩子 - 甲斐 心愛」计算到其他角色的距离始终-1；锁定技，其他角色计算到「STU 48的舰长 - 岡田 奈々」、「STU 48的Center - 瀧野 由美子」、「STU 48的熊孩子 - 甲斐 心愛」的距离始终+1。
]]
Luajianzhang = sgs.CreateDistanceSkill {
    name = "Luajianzhang",
    correct_func = function(self, from, to)
        local correct = 0
        if from:getGeneralName() == "yumikotakino_COS" or from:getGeneral2Name() == "yumikotakino_COS"
            or from:getGeneralName() == "kokoakai_NCOS" or from:getGeneral2Name() == "kokoakai_NCOS"
            or from:getGeneralName() == "NanaOkada_COS" or from:getGeneral2Name() == "NanaOkada_COS" then
            correct = correct - 1
        end
        if to:getGeneralName() == "yumikotakino_COS" or to:getGeneral2Name() == "yumikotakino_COS" or to:getGeneralName()
            == "kokoakai_NCOS" or to:getGeneral2Name() == "kokoakai_NCOS" or to:getGeneralName() == "NanaOkada_COS"
            or to:getGeneral2Name() == "NanaOkada_COS" then
            correct = correct + 1
        end
        return correct
    end,
}
NanaOkada_COS:addSkill(Luajianzhang)

--[[
    技能名：蛇宝
    描述：当其他角色受到雷电伤害时，若伤害值大于1，你可以承受多余的伤害；锁定技，当你受到1点雷电伤害时，你摸一张牌然后弃置场上一张牌。
]]
Luashebao = sgs.CreateTriggerSkill {
    name = "Luashebao",
    events = {sgs.DamageInflicted, sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    global = true,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.DamageInflicted then
            local source = room:findPlayerBySkillName(self:objectName())
            if not source then
                return false
            end
            if damage.to:objectName() ~= source:objectName() and damage.damage > 1 and damage.nature
                == sgs.DamageStruct_Thunder then
                if room:askForSkillInvoke(source, self:objectName(),
                    sgs.QVariant("@shebao_invoke_1:" .. damage.to:objectName())) then
                    local reduce = damage.damage - 1
                    damage.damage = 1
                    data:setValue(damage)
                    local from = damage.from or nil
                    room:damage(sgs.DamageStruct(damage.reason, from, source, reduce, damage.nature))
                end
            end
        else
            if player:hasSkill(self) and damage.nature == sgs.DamageStruct_Thunder then
                for i = 0, damage.damage - 1, 1 do
                    player:drawCards(1)
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not p:isAllNude() then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@shebao_invoke_2",
                            false, true)
                        local id = room:askForCardChosen(player, target, "hej", self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(id, target, player)
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
NanaOkada_COS:addSkill(Luashebao)

--[[
    技能名：Ja-Ba-Ja
    描述：限定技，「STU 48的Center - 瀧野 由美子」死亡时，在其死亡结算开始前，你可以弃置一张装备牌，然后与「STU 48的Center - 瀧野 由美子」交换身份牌。
]]
LuaJaBaJa = sgs.CreateTriggerSkill {
    name = "LuaJaBaJa",
    frequency = sgs.Skill_Limited,
    events = {sgs.AskForPeachesDone},
    limit_mark = "@JaBaJa",
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() and player:getHp() <= 0
            and (player:getGeneralName() == "yumikotakino_COS" or player:getGeneral2Name() == "yumikotakino_COS") then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self) then
                    if p:getMark("@JaBaJa") > 0 then
                        room:setPlayerFlag(player, "JaBaJaTarget")
                        local ai_data = sgs.QVariant()
                        ai_data:setValue(player)
                        if room:askForSkillInvoke(p, self:objectName(), ai_data) then
                            p:loseMark("@JaBaJa")
                            local role1 = p:getRole()
                            local role2 = player:getRole()
                            p:setRole(role2)
                            room:setPlayerProperty(p, "role", sgs.QVariant(role2))
                            player:setRole(role1)
                            room:setPlayerProperty(player, "role", sgs.QVariant(role1))
                        end
                        room:setPlayerFlag(player, "-JaBaJaTarget")
                        return false
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanaOkada_COS:addSkill(LuaJaBaJa)

sgs.LoadTranslationTable {
    ["NanaOkada_COS"] = "岡田 奈々",
    ["&NanaOkada_COS"] = "岡田 奈々",
    ["#NanaOkada_COS"] = "STU 48的舰长",
    ["designer:NanaOkada_COS"] = "Cassimolar",
    ["cv:NanaOkada_COS"] = "岡田 奈々",
    ["illustrator:NanaOkada_COS"] = "Cassimolar",
    ["Luajianren"] = "兼任",
    [":Luajianren"] = "回合结束阶段开始时，你可以进行以下四选一：\
    1. 永久改变一名其他角色的势力；\
    2. 永久获得一项未上场或已死亡角色的主公技。（获得后即使你不是主公仍然有效）；\
    3.永久获得一项未上场或已死亡角色的限定技，你以此选项获得3次限定技后失去此选项；\
    4.选择一名角色，直到你的下个回合结束阶段开始时，所有角色到该角色距离视为1。",
    ["Luajianren:modify"] = "改变一名其他角色的势力",
    ["Luajianren:obtainLordskill"] = "获得一个主公技",
    ["Luajianren:distance"] = "令其他角色到一名角色的距离为1",
    ["Luajianren:obtainLimitedskill"] = "获得一个限定技",
    ["Luajianzhang"] = "舰长",
    [":Luajianzhang"] = "锁定技，「STU 48的舰长 - 岡田 奈々」、「STU 48的Center - 瀧野 由美子」、「STU 48的熊孩子 - 甲斐 心愛」计算到其他角色的距离始终-1；锁定技，其他角色计算到「STU 48的舰长 - 岡田 奈々」、「STU 48的Center - 瀧野 由美子」、「STU 48的熊孩子 - 甲斐 心愛」的距离始终+1。",
    ["Luashebao"] = "蛇宝",
    [":Luashebao"] = "当其他角色受到雷电伤害时，若伤害值大于1，你可以承受多余的伤害；锁定技，当你受到1点雷电伤害时，你摸一张牌然后弃置场上一张牌。",
    ["@shebao_invoke_1"] = "是否发动【蛇宝】承受%src此次受到的雷电伤害多余1点的伤害",
    ["@shebao_invoke_2"] = "选择一名角色弃置其区域内一张牌",
    ["LuaJaBaJa"] = "Ja-Ba-Ja",
    [":LuaJaBaJa"] = "限定技，「STU 48的Center - 瀧野 由美子」死亡时，在其死亡结算开始前，你可以弃置一张装备牌，然后与「STU 48的Center - 瀧野 由美子」交换身份牌。",
    ["@JaBaJa"] = "Ja-Ba-Ja",
}
