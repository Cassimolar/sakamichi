require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SawaKuroshima = sgs.General(SakamichiGod, "SawaKuroshima", "god", 5, false)
table.insert(SKMC.IKiSei, "SawaKuroshima")

--[[
    技能名：真凶
    描述：起始手牌分发完毕后，你可以选择一名其他角色，令其成为你的“舔狗”；当你造成伤害时，你可以指定一名“舔狗”成为此伤害的来源；当场上除你以外所有角色都是你的“舔狗”时，你胜利。
]]
LuaRealMurderer = sgs.CreateTriggerSkill {
    name = "LuaRealMurderer",
    events = {sgs.AfterDrawInitialCards, sgs.ConfirmDamage, sgs.MarkChanged, sgs.Death},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AfterDrawInitialCards then
            if player:hasSkill(self) then
                local Lick_Dog = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@Lick_Dog_Choice", false, true)
                if Lick_Dog then
                    Lick_Dog:gainMark("@Lick_Dog")
                    room:setPlayerMark(Lick_Dog, player:objectName() .. "Lick_Dog", 1)
                end
            end
            return false
        elseif event == sgs.ConfirmDamage then
            if player:hasSkill(self) then
                local damage = data:toDamage()
                local targets_list = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark(player:objectName() .. "Lick_Dog") ~= 0 then
                        targets_list:append(p)
                    end
                end
                if targets_list:length() > 0 then
                    local Scapegoat = room:askForPlayerChosen(player, targets_list, self:objectName(),
                        "@Scapegoat_Choice", true, true)
                    if Scapegoat then
                        damage.from = Scapegoat
                        data:setValue(damage)
                    end
                end
            end
            return false
        elseif event == sgs.MarkChanged then
            local mark = data:toMark()
            if mark.name == "@Lick_Dog" and player:getMark("@Lick_Dog") ~= 0 then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:hasSkill(self) then
                        if player:getMark(p:objectName() .. "Lick_Dog") ~= 0 then
                            local win = true
                            for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                                if not (pl:getMark("@Lick_Dog") ~= 0 and pl:getMark(p:objectName() .. "Lick_Dog") ~= 0) then
                                    win = false
                                    break
                                end
                            end
                            if win then
                                room:gameOver(p:objectName())
                            end
                        end
                    end
                end
            end
            return false
        elseif event == sgs.Death then
            local death = data:toDeath()
            for _, p in sgs.qlist(room:getOtherPlayers(death.who)) do
                if p:hasSkill(self) then
                    local win = true
                    for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                        if not (pl:getMark("@Lick_Dog") ~= 0 and pl:getMark(p:objectName() .. "Lick_Dog") ~= 0) then
                            win = false
                            break
                        end
                    end
                    if win then
                        room:gameOver(p:objectName())
                    end
                end
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}
SawaKuroshima:addSkill(LuaRealMurderer)

--[[
    技能名：轮到你了
    描述：出牌阶段限一次，你可以将一张手牌交给一名其他角色令其对你指定的另一名角色使用一张【杀】，若其以此法击杀一名角色则其成为你的舔狗，若其未如此做则视为你和你的“舔狗”分别对其使用了一张【杀】。
]]
LuaanatanobandesuCard = sgs.CreateSkillCard {
    name = "LuaanatanobandesuCard",
    skill_name = "Luaanatanobandesu",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        local targets = sgs.SPlayerList()
        if sgs.Slash_IsAvailable(effect.to) then
            for _, p in sgs.qlist(room:getOtherPlayers(effect.to)) do
                if effect.to:canSlash(p, nil, false) then
                    targets:append(p)
                end
            end
        end
        local target
        if (not targets:isEmpty()) and effect.from:isAlive() then
            target = room:askForPlayerChosen(effect.from, targets, self:objectName(),
                "@dummy_slash2:" .. effect.to:objectName())
            target:setFlags("LuaanatanobandesuTarget")
        end
        effect.to:obtainCard(self)
        if target and target:hasFlag("LuaanatanobandesuTarget") then
            target:setFlags("-LuaanatanobandesuTarget")
        end
        if effect.to:canSlash(target, nil, false) then
            room:setPlayerMark(effect.to, "anatanobandesu", 1)
            room:setPlayerMark(effect.from, "realmurderer", 1)
            if not room:askForUseSlashTo(effect.to, target, "@anatanobandesu_slash:" .. target:objectName(), false) then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                slash:setSkillName("Luaanatanobandesu")
                room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to))
                for _, p in sgs.qlist(room:getOtherPlayers(effect.from)) do
                    if p:getMark("@Lick_Dog") ~= 0 and p:getMark(effect.from:objectName() .. "Lick_Dog") then
                        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        slash:setSkillName("Luaanatanobandesu")
                        room:useCard(sgs.CardUseStruct(slash, effect.from, effect.to))
                    end
                end
            end
        end
    end,
}
LuaanatanobandesuVS = sgs.CreateOneCardViewAsSkill {
    name = "Luaanatanobandesu",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = LuaanatanobandesuCard:clone()
        cd:addSubcard(card:getId())
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuaanatanobandesuCard")
    end,
}
Luaanatanobandesu = sgs.CreateTriggerSkill {
    name = "Luaanatanobandesu",
    events = {sgs.CardUsed, sgs.Death, sgs.CardFinished},
    view_as_skill = LuaanatanobandesuVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:getMark("anatanobandesu") ~= 0 then
                room:setCardFlag(use.card, "Luaanatanobandesu")
                room:setPlayerMark(player, "anatanobandesu", 0)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.card and death.damage.card:hasFlag("Luaanatanobandesu")
                and death.damage.from and death.damage.from:isAlive() then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("realmurderer") ~= 0 then
                        death.damage.from:gainMark("@Lick_Dog")
                        death.damage.from:gainMark(p:objectName() .. "Lick_Dog")
                        room:setPlayerMark(p, "realmurderer", 0)
                    end
                end
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("Luaanatanobandesu") then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("realmurderer") ~= 0 then
                        room:setPlayerMark(p, "realmurderer", 0)
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
SawaKuroshima:addSkill(Luaanatanobandesu)

--[[
    技能名：操纵
    描述：限定技，当你受到伤害时，你可以指定一名“舔狗”为你承受此伤害，若其因此伤害死亡，此技能视为未发动过。
]]
Luacontrol = sgs.CreateTriggerSkill {
    name = "Luacontrol",
    events = {sgs.DamageInflicted, sgs.DamageComplete, sgs.Death},
    frequency = sgs.Skill_Limited,
    limit_mark = "@control",
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:hasSkill(self) and player:getMark("@control") ~= 0 then
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark("@Lick_Dog") ~= 0 and p:getMark(player:objectName() .. "Lick_Dog") ~= 0 then
                        targets:append(p)
                    end
                end
                if targets:length() > 0 then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "@control_choice", true,
                        true)
                    if target then
                        player:loseMark("@control")
                        room:setPlayerFlag(target, "control")
                        local tagvalue = sgs.QVariant()
                        tagvalue:setValue(player)
                        room:setTag(target:objectName() .. "control_Tag", tagvalue)
                        damage.to = target
                        damage.transfer = true
                        room:damage(damage)
                        return true
                    end
                end
            end
        elseif event == sgs.DamageComplete then
            if player:hasFlag("control") then
                room:setPlayerFlag(player, "-control")
                room:removeTag(player:objectName() .. "control_Tag")
            end
            return false
        elseif event == sgs.Death then
            local death = data:toDeath()
            local target = room:getTag(death.who:objectName() .. "control_Tag"):toPlayer()
            if target and target:isAlive() then
                target:gainMark("@control")
            end
            room:removeTag(death.who:objectName() .. "control_Tag")
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SawaKuroshima:addSkill(Luacontrol)

--[[
    技能名：堕轨
    描述：当你受到来自你“舔狗”的伤害后，若你存活你可以选择回复2点体力或摸两张牌。
]]
Luafalling = sgs.CreateTriggerSkill {
    name = "Luafalling",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:getMark("@Lick_Dog") ~= 0
            and damage.from:getMark(player:objectName() .. "Lick_Dog") ~= 0 then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@falling_recover")) then
                room:recover(player, sgs.RecoverStruct(player, nil, 2))
            else
                room:drawCards(player, 2, self:objectName())
            end
        end
        return false
    end,
}
SawaKuroshima:addSkill(Luafalling)

--[[
    技能名：笑气
    描述：当一名其他角色进入濒死时，你可以弃置一张牌令其进行一次判定，若判定结果不为♥时，在其脱离此次濒死前，其无法使用桃。
]]
Luanitrous_oxide = sgs.CreateTriggerSkill {
    name = "Luanitrous_oxide",
    events = {sgs.EnterDying, sgs.AskForPeachesDone},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:hasSkill(self) and p:objectName() ~= dying.who:objectName() then
                    local card = room:askForCard(p, ".", "@antitrous_oxide", data, sgs.Card_MethodDiscard, nil, false,
                        self:objectName(), false)
                    if card then
                        local judge = sgs.JudgeStruct()
                        judge.pattern = ".|heart"
                        judge.good = false
                        judge.who = dying.who
                        judge.reason = self:objectName()
                        room:judge(judge)
                        if judge:isGood() then
                            dying.who:setFlags("nitrous_oxide")
                            room:setPlayerCardLimitation(dying.who, "use", "Peach", true)
                        end
                    end
                end
            end
        else
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p:hasFlag("nitrous_oxide") then
                    p:setFlags("-nitrous_oxide")
                    room:removePlayerCardLimitation(p, "use", "Peach$1")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SawaKuroshima:addSkill(Luanitrous_oxide)

sgs.LoadTranslationTable {
    ["SawaKuroshima"] = "黒島 沙和",
    ["&SawaKuroshima"] = "黒島 沙和",
    ["#SawaKuroshima"] = "二零二的殺人魔",
    ["designer:SawaKuroshima"] = "Cassimolar",
    ["cv:SawaKuroshima"] = "西野 七瀬",
    ["illustrator:SawaKuroshima"] = "Cassimolar",
    ["LuaRealMurderer"] = "真凶",
    [":LuaRealMurderer"] = "起始手牌分发完毕后，你可以选择一名其他角色，令其成为你的“舔狗”；当你造成伤害时，你可以指定一名“舔狗”成为此伤害的来源；当场上除你以外所有角色都是你的“舔狗”时，你胜利。",
    ["@Lick_Dog_Choice"] = "请选择一名其他角色成为你的初始“舔狗”",
    ["@Lick_Dog"] = "舔狗",
    ["@Scapegoat_Choice"] = "你可以选择一名你的“舔狗”成为此次伤害的伤害来源",
    ["Luaanatanobandesu"] = "轮到你了",
    [":Luaanatanobandesu"] = "出牌阶段限一次，你可以交给一名其他角色一张手牌令其对你指定的另一名角色使用一张【杀】，若其因此击杀一名角色则其成为你的“舔狗”，若其未如此做则你和你的“舔狗”分别视为对其使用一张【杀】。",
    ["@anatanobandesu_slash"] = "请对%src使用一张杀",
    ["Luacontrol"] = "操纵",
    [":Luacontrol"] = "限定技，当你受到伤害时，你可以指定一名“舔狗”为你承受此伤害，若其因此伤害死亡，此技能视为未发动过。",
    ["@control"] = "操纵",
    ["@control_choice"] = "你可以选择一名你的“舔狗”替你承受此次伤害",
    ["Luafalling"] = "堕轨",
    [":Luafalling"] = "当你受到来自你“舔狗”的伤害后，你可以选择回复2点体力或摸两张牌。",
    ["@falling_recover"] = "是否回复2点体力，否则摸两张牌",
    ["Luanitrous_oxide"] = "笑气",
    [":Luanitrous_oxide"] = "当一名其他角色进入濒死时，你可以弃置一张牌令其进行一次判定，若判定结果不为♥时，在其脱离此次濒死前，其无法使用【桃】。",
    ["@antitrous_oxide"] = "你可以弃置一张牌发动笑气",
}
