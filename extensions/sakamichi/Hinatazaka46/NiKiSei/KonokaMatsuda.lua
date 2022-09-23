require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KonokaMatsuda_Hinatazaka = sgs.General(Sakamichi, "KonokaMatsuda_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.NiKiSei, "KonokaMatsuda_Hinatazaka")

--[[
    技能名：多艺
    描述：出牌阶段，当你使用牌时，若此牌与你本回合使用的上一张牌类型不同，你可以进行一次判定，若判定结果类型与此牌不同，你获得判定牌。
]]
Luaduoyi = sgs.CreateTriggerSkill {
    name = "Luaduoyi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getPhase() == sgs.Player_Play and not use.card:isKindOf("SkillCard") then
                local n = player:getMark("duoyi")
                if n ~= 0 then
                    if n ~= use.card:getTypeId() and room:askForSkillInvoke(player, self:objectName(), data) then
                        local type
                        if use.card:isKindOf("BasicCard") then
                            type = "BasicCard"
                        elseif use.card:isKindOf("TrickCard") then
                            type = "TrickCard"
                        else
                            type = "EquipCard"
                        end
                        local judge = sgs.JudgeStruct()
                        judge.pattern = type
                        judge.good = false
                        judge.reason = self:objectName()
                        judge.who = player
                        room:judge(judge)
                        if judge:isGood() then
                            player:obtainCard(judge.card)
                        end
                    end
                end
                room:setPlayerMark(player, "duoyi", use.card:getTypeId())
            end
        elseif player:getPhase() == sgs.Player_Play then
            room:setPlayerMark(player, "duoyi", 0)
        end
        return false
    end,
}
KonokaMatsuda_Hinatazaka:addSkill(Luaduoyi)

--[[
    技能名：太鼓
    描述：当一名角色使用通常锦囊牌时，你可以弃置一张点数大于此牌的手牌令此牌无法响应；出牌阶段限一次，你可以弃置一张手牌令一名角色直到你的下个回合开始前使用点数大于此牌的基本牌时不计入次数限制。
]]
LuataiguCard = sgs.CreateSkillCard {
    name = "LuataiguCard",
    skill_name = "Luataigu",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerMark(effect.to, "taigu" .. effect.from:objectName(), self:getNumber())
    end,
}
LuataiguVS = sgs.CreateOneCardViewAsSkill {
    name = "Luataigu",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skillcard = LuataiguCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuataiguCard") and not player:isKongcheng()
    end,
}
Luataigu = sgs.CreateTriggerSkill {
    name = "Luataigu",
    view_as_skill = LuataiguVS,
    events = {sgs.CardUsed, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isNDTrick() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    local card = room:askForCard(p, ".|.|" .. use.card:getNumber() + 1 .. "~14|hand", "@taigu_invoke:"
                        .. player:objectName() .. "::" .. use.card:getNumber() .. ":" .. use.card:objectName(), data,
                        sgs.Card_MethodDiscard, nil, false, self:objectName(), false, nil)
                    if card then
                        room:setCardFlag(use.card, "no_respond_" .. use.from:objectName() .. "_ALL_TARGETS")
                        local no_respond_list = use.no_respond_list
                        for _, p in sgs.qlist(room:getAllPlayers()) do
                            table.insert(no_respond_list, p:objectName())
                        end
                        use.no_respond_list = no_respond_list
                        data:setValue(use)
                    end
                end
            elseif use.card:isKindOf("BasicCard") then
                local n = 14
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getMark("taigu" .. p:objectName()) ~= 0 and player:getMark("taigu" .. p:objectName()) < n then
                        n = player:getMark("taigu" .. p:objectName())
                    end
                end
                if n ~= 14 and use.card:getNumber() < n and use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
            end
        elseif player:getPhase() == sgs.Player_Start and player:hasSkill(self) then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "taigu" .. player:objectName(), 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KonokaMatsuda_Hinatazaka:addSkill(Luataigu)

--[[
    技能名：坏花
    描述：转换技，①你失去装备区的装备牌时可以对攻击范围内的一名角色造成1点雷电伤害；②当你受到伤害后可以令一名其他角色回复1点体力。
]]
Luahuaihua = sgs.CreateTriggerSkill {
    name = "Luahuaihua",
    change_skill = true,
    events = {sgs.CardsMoveOneTime, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local n = room:getChangeSkillState(player, self:objectName())
        if event == sgs.CardsMoveOneTime and n == 1 then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
                and move.from_places:contains(sgs.Player_PlaceEquip) then
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:inMyAttackRange(p) then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@huaihua_invoke_1",
                        true, true)
                    if target then
                        room:damage(sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Thunder))
                        room:setChangeSkillState(player, self:objectName(), 2)
                    end
                end
            end
        elseif event == sgs.Damaged and n == 2 then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isWounded() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@huaihua_invoke_2", true,
                    true)
                if target then
                    room:recover(target, sgs.RecoverStruct(player, nil, 1))
                    room:setChangeSkillState(player, self:objectName(), 1)
                end
            end
        end
        return false
    end,
}
KonokaMatsuda_Hinatazaka:addSkill(Luahuaihua)

sgs.LoadTranslationTable {
    ["KonokaMatsuda_Hinatazaka"] = "松田 好花",
    ["&KonokaMatsuda_Hinatazaka"] = "松田 好花",
    ["#KonokaMatsuda_Hinatazaka"] = "才藝全能",
    ["designer:KonokaMatsuda_Hinatazaka"] = "Cassimolar",
    ["cv:KonokaMatsuda_Hinatazaka"] = "松田 好花",
    ["illustrator:KonokaMatsuda_Hinatazaka"] = "Cassimolar",
    ["Luaduoyi"] = "多艺",
    [":Luaduoyi"] = "出牌阶段，当你使用牌时，若此牌与你本回合使用的上一张牌类型不同，你可以进行一次判定，若判定结果类型与此牌不同，你获得判定牌。",
    ["Luataigu"] = "太鼓",
    [":Luataigu"] = "当一名角色使用通常锦囊牌时，你可以弃置一张点数大于此牌的手牌令此牌无法响应；出牌阶段限一次，你可以弃置一张手牌令一名角色直到你的下个回合开始前使用点数大于此牌的基本牌时不计入次数限制。",
    ["@taigu_invoke"] = "你可以弃置一张大于%arg的牌令%src使用的【%arg2】无法响应",
    ["Luahuaihua"] = "坏花",
    [":Luahuaihua"] = "转换技，①你失去装备区的装备牌时可以对攻击范围内的一名角色造成1点雷电伤害；②当你受到伤害后可以令一名其他角色回复1点体力。",
    ["@huaihua_invoke_1"] = "你可以对攻击范围内的一名角色造成1点雷电伤害",
    ["@huaihua_invoke_2"] = "你可以令一名其他角色回复1点体力",
}
