require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HiyoriHamagishi_Hinatazaka = sgs.General(Sakamichi, "HiyoriHamagishi_Hinatazaka", "Hinatazaka46", 4, false)
table.insert(SKMC.NiKiSei, "HiyoriHamagishi_Hinatazaka")

--[[
    技能名：脱线
    描述：当你使用非无色基本牌结算完成后，你可以视为使用一张此牌的同名无色牌；锁定技，你使用无色基本牌时会额外指定场上体力值最低的合法目标为目标。
]]
Luatuoxian = sgs.CreateTriggerSkill {
    name = "Luatuoxian",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PreCardUsed, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("BasicCard") then
                if use.card:isBlack() or use.card:isRed() then
                    if use.card:isKindOf("Peach") then
                        local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, -1)
                        peach:setSkillName(self:objectName())
                        local targets = sgs.SPlayerList()
                        for _, p in sgs.qlist(use.to) do
                            if not room:isProhibited(player, p, peach) and p:isWounded() then
                                targets:append(p)
                            end
                        end
                        if not targets:isEmpty()
                            and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("peach")) then
                            room:useCard(sgs.CardUseStruct(peach, player, targets), false)
                        end
                    elseif use.card:isKindOf("Analeptic") then
                        local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
                        analeptic:setSkillName(self:objectName())
                        if not room:isProhibited(player, player, analeptic)
                            and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("analeptic")) then
                            room:useCard(sgs.CardUseStruct(analeptic, player, player), false)
                        end
                    elseif use.card:isKindOf("Slash") then
                        local slash = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, -1)
                        slash:setSkillName(self:objectName())
                        local targets = sgs.SPlayerList()
                        for _, p in sgs.qlist(use.to) do
                            if not room:isProhibited(player, p, slash) then
                                targets:append(p)
                            end
                        end
                        if not targets:isEmpty()
                            and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("slash")) then
                            room:useCard(sgs.CardUseStruct(slash, player, targets), false)
                        end
                    end
                end
            end
        else
            local use = data:toCardUse()
            if not use.card:isRed() and not use.card:isBlack() then
                local hp_min = player
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getHp() < hp_min:getHp() then
                        hp_min = p
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getHp() == hp_min:getHp() and not use.to:contains(p) then
                        use.to:append(p)
                    end
                end
                data:setValue(use)
            end
        end
        return false
    end,
}
HiyoriHamagishi_Hinatazaka:addSkill(Luatuoxian)

--[[
    技能名：史莱姆
    描述：游戏开始时/回合开始时，你获得两枚“史莱姆”/可以移动一枚“史莱姆”；锁定技，拥有“史莱姆”的角色受到伤害时，若此伤害无属性则伤害量-1，否则伤害量+1。
]]
LuashilaimuCard = sgs.CreateSkillCard {
    name = "LuashilaimuCard",
    skill_name = "Luashilaimu",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return to_select:getMark("@shilaimu") ~= 0
        elseif #targets == 1 then
            return to_select:getMark("@shilaimu") == 0
        elseif #targets == 2 then
            return false
        end
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    on_use = function(self, room, source, targets)
        local from, to
        if targets[1]:getMark("@shilaimu") ~= 0 then
            from = targets[1]
            to = targets[2]
        else
            from = targets[2]
            to = targets[1]
        end
        room:removePlayerMark(from, "@shilaimu")
        room:addPlayerMark(to, "@shilaimu")
    end,
}
LuashilaimuVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luashilaimu",
    response_pattern = "@@Luashilaimu",
    view_as = function(self)
        return LuashilaimuCard:clone()
    end,
}
Luashilaimu = sgs.CreateTriggerSkill {
    name = "Luashilaimu",
    frequency = sgs.Skill_Compulsory,
    view_as_skill = LuashilaimuVS,
    events = {sgs.GameStart, sgs.EventPhaseStart, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self) then
                room:addPlayerMark(player, "@shilaimu", 2)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if player:hasSkill(self) then
                    room:askForUseCard(player, "@@Luashilaimu", "@Luashilaimu-card")
                end
            end
        else
            local damage = data:toDamage()
            if player:getMark("@shilaimu") ~= 0 then
                if damage.nature == sgs.DamageStruct_Normal then
                    damage.damage = damage.damage - 1
                    if damage.damage <= 0 then
                        return true
                    end
                else
                    damage.damage = damage.damage + 1
                end
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HiyoriHamagishi_Hinatazaka:addSkill(Luashilaimu)

HiyoriHamagishi_Hinatazaka:addSkill("sakamichi_yao_jing")

sgs.LoadTranslationTable {
    ["HiyoriHamagishi_Hinatazaka"] = "濱岸 ひより",
    ["&HiyoriHamagishi_Hinatazaka"] = "濱岸 ひより",
    ["#HiyoriHamagishi_Hinatazaka"] = "禿宝",
    ["designer:HiyoriHamagishi_Hinatazaka"] = "Cassimolar",
    ["cv:HiyoriHamagishi_Hinatazaka"] = "濱岸 ひより",
    ["illustrator:HiyoriHamagishi_Hinatazaka"] = "Cassimolar",
    ["Luatuoxian"] = "脱线",
    [":Luatuoxian"] = "当你使用非无色基本牌结算完成后，你可以视为使用一张此牌的同名无色牌；锁定技，你使用无色基本牌时会额外指定场上体力值最低的合法目标为目标。",
    ["Luatuoxian:peach"] = "是否视为对相同目标使用一张无色【桃】",
    ["Luatuoxian:analeptic"] = "是否视为对相同目标使用一张无色【酒】",
    ["Luatuoxian:slash"] = "是否视为对相同目标使用一张无色【杀】",
    ["Luashilaimu"] = "史莱姆",
    [":Luashilaimu"] = "游戏开始时/回合开始时，你获得两枚“史莱姆”/可以移动一枚“史莱姆”；锁定技，拥有“史莱姆”的角色受到伤害时，若此伤害无属性则伤害量-1，否则伤害量+1。",
    ["@Luashilaimu-card"] = "你可以移动场上一枚“史莱姆”",
    ["~Luashilaimu"] = "选择一名有“史莱姆”的角色 → 选择一名没有“史莱姆” → 点击确定",
}
