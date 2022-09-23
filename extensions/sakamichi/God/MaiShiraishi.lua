require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaiShiraishi_God = sgs.General(SakamichiGod, "MaiShiraishi_God", "god", 5, false)
table.insert(SKMC.IKiSei, "MaiShiraishi_God")

--[[
    技能名：护照
    描述：锁定技，当场上存在「白石麻衣」时，若不存在「生田绘梨花」则所有其他角色手牌上限-1；若存在「生田绘梨花」则除「白石麻衣」和「生田绘梨花」之外的其他角色手牌上限-2，「白石麻衣」和「生田绘梨花」的手牌上限-1。
]]
LuaPassport = sgs.CreateMaxCardsSkill {
    name = "LuaPassport",
    extra_func = function(self, target)
        local has_MaiShiraishi = false
        local both_has = false
        if (string.find(target:getGeneralName(), "MaiShiraishi") or string.find(target:getGeneral2Name(), "MaiShiraishi"))
            and target:isAlive() and target:hasSkill(self) then
            has_MaiShiraishi = true
            for _, p in sgs.qlist(target:getSiblings()) do
                if (string.find(p:getGeneralName(), "ErikaIkuta") or string.find(p:getGeneral2Name(), "ErikaIkuta"))
                    and p:isAlive() then
                    both_has = true
                    break
                end
            end
        elseif (string.find(target:getGeneralName(), "ErikaIkuta") or string.find(target:getGeneral2Name(), "ErikaIkuta"))
            and target:isAlive() then
            has_erikaikuta = true
            for _, p in sgs.qlist(target:getSiblings()) do
                if (string.find(p:getGeneralName(), "MaiShiraishi") or string.find(p:getGeneral2Name(), "MaiShiraishi"))
                    and p:isAlive() and p:hasSkill(self) then
                    has_MaiShiraishi = true
                    both_has = true
                    break
                end
            end
        else
            for _, p in sgs.qlist(target:getSiblings()) do
                if (string.find(p:getGeneralName(), "MaiShiraishi") or string.find(p:getGeneral2Name(), "MaiShiraishi"))
                    and p:isAlive() and p:hasSkill(self) then
                    has_MaiShiraishi = true
                    if has_MaiShiraishi then
                        for _, pl in sgs.qlist(p:getSiblings()) do
                            if (string.find(pl:getGeneralName(), "ErikaIkuta")
                                or string.find(pl:getGeneral2Name(), "ErikaIkuta")) and pl:isAlive() then
                                both_has = true
                                break
                            end
                        end
                    end
                end
            end
        end
        if both_has then
            if string.find(target:getGeneralName(), "MaiShiraishi")
                or string.find(target:getGeneral2Name(), "MaiShiraishi")
                or string.find(target:getGeneralName(), "ErikaIkuta")
                or string.find(target:getGeneral2Name(), "ErikaIkuta") then
                return -1
            else
                return -2
            end
        elseif has_MaiShiraishi then
            if string.find(target:getGeneralName(), "MaiShiraishi")
                or string.find(target:getGeneral2Name(), "MaiShiraishi") then
                return 0
            else
                return -1
            end
        end
    end,
}
MaiShiraishi_God:addSkill(LuaPassport)

--[[
    技能名：怂白
    描述：锁定技，当你受到一次伤害后，你获得一枚“怂”。
]]
Luasongbai = sgs.CreateTriggerSkill {
    name = "Luasongbai",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        player:gainMark("@song")
    end,
}
MaiShiraishi_God:addSkill(Luasongbai)

--[[
    技能名：ｼロンｼﾞｮ
    描述：限定技，回合开始时或当你体力值变化后不大于3点时，若你至少有3张”怂“，你可以将此技能替换为：出牌阶段，你可以弃置一枚“怂”视为使用一张【杀】，你以此法转化使用的【杀】不计入次数限制。
]]
Luashironjo = sgs.CreateTriggerSkill {
    name = "Luashironjo",
    events = {sgs.EventPhaseStart, sgs.HpChanged},
    frequency = sgs.Skill_Limited,
    limit_mark = "@shironjo",
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getMark("@song") >= 3 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                player:loseMark("@shironjo")
                room:handleAcquireDetachSkills(player, "-Luashironjo|Luashironjo_Unlimited")
            end
        elseif event == sgs.HpChanged then
            if player:getHp() <= 3 and player:getMark("@song") >= 3 then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    player:loseMark("@shironjo")
                    room:handleAcquireDetachSkills(player, "-Luashironjo|Luashironjo_Unlimited")
                end
            end
        end
        return false
    end,
}
Luashironjo_UnlimitedCard = sgs.CreateSkillCard {
    name = "Luashironjo_Unlimited",
    skill_name = "Luashironjo_Unlimited",
    target_fixed = false,
    filter = function(self, targets, to_select)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        local plist = sgs.PlayerList()
        for i = 1, #targets, 1 do
            plist:append(targets[i])
        end
        return slash:targetFilter(plist, to_select, sgs.Self)
    end,
    on_validate = function(self, card)
        local source = card.from
        source:loseMark("@song")
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName("Luashironjo_Unlimited")
        return slash
    end,
    on_validate_in_response = function(self, user)
        user:loseMark("@song")
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName("Luashironjo_Unlimited")
        return slash
    end,
}
Luashironjo_UnlimitedVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luashironjo_Unlimited",
    response_pattern = "slash",
    view_as = function()
        return Luashironjo_UnlimitedCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@song") ~= 0
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getMark("@song") ~= 0 and (string.find(pattern, "slash") or string.find(pattern, "Slash"))
                   and ((sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE))
    end,
}
Luashironjo_Unlimited = sgs.CreateTriggerSkill {
    name = "Luashironjo_Unlimited",
    events = {sgs.CardUsed},
    view_as_skill = Luashironjo_UnlimitedVS,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") and use.card:getSkillName() == "Luashironjo_Unlimited" then
            if use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
            end
        end
        return false
    end,
}
MaiShiraishi_God:addSkill(Luashironjo)
if not sgs.Sanguosha:getSkill("Luashironjo_Unlimited") then
    SKMC.SkillList:append(Luashironjo_Unlimited)
end

--[[
    技能名：神对应
    描述：锁定技，当你使用以”怂“转化而来的【杀】造成伤害时，若此次伤害为你本回合第二次/第二次以上以此法造成伤害，则此次伤害+1/+2点。
]]
Luakamitaiou = sgs.CreateTriggerSkill {
    name = "Luakamitaiou",
    events = {sgs.DamageCaused, sgs.Damaged, sgs.EventPhaseChanging},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("&kamitaiou") ~= 0 then
                        room:setPlayerMark(p, "&kamitaiou", 0)
                    end
                end
            end
        else
            local damage = data:toDamage()
            if event == sgs.Damaged then
                if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName()
                    == "Luashironjo_Unlimited" then
                    room:addPlayerMark(damage.from, "&kamitaiou")
                end
            else
                if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName()
                    == "Luashironjo_Unlimited" then
                    if damage.from:getMark("&kamitaiou") == 1 then
                        damage.damage = damage.damage + 1
                        local msg = sgs.LogMessage()
                        msg.type = "#kamitaiou2"
                        msg.from = damage.from
                        msg.to:append(damage.to)
                        msg.arg = self:objectName()
                        msg.arg2 = damage.damage
                        room:sendLog(msg)
                        data:setValue(damage)
                    elseif damage.from:getMark("&kamitaiou") >= 2 then
                        damage.damage = damage.damage + 2
                        local msg = sgs.LogMessage()
                        msg.type = "#kamitaiou3"
                        msg.from = damage.from
                        msg.to:append(damage.to)
                        msg.arg = self:objectName()
                        msg.arg2 = damage.damage
                        room:sendLog(msg)
                        data:setValue(damage)
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
MaiShiraishi_God:addSkill(Luakamitaiou)

--[[
    技能名：幸福的保护色
    描述：当其他角色成为非你使用的【杀】的目标时，你可以弃置一张【闪】来代替其成为此【杀】的目标。
]]
LuaShiawasenoHogoshoku = sgs.CreateTriggerSkill {
    name = "LuaShiawasenoHogoshoku",
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            if use.to:contains(player) then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill(self) and ((use.from and p:objectName() ~= use.from:objectName()) or not use.from) then
                        if room:askForCard(p, "Jink", "@Hogoshoku_Discard:" .. player:objectName() .. ":"
                            .. use.from:objectName() .. ":" .. use.card:objectName(), data, sgs.Card_MethodDiscard, nil,
                            false, self:objectName(), false) then
                            use.to:removeOne(player)
                            use.to:append(p)
                            data:setValue(use)
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
MaiShiraishi_God:addSkill(LuaShiawasenoHogoshoku)

sgs.LoadTranslationTable {
    ["MaiShiraishi_God"] = "白石 麻衣",
    ["&MaiShiraishi_God"] = "神·白石 麻衣",
    ["#MaiShiraishi_God"] = "皆を照らす人",
    ["designer:MaiShiraishi_God"] = "Cassimolar",
    ["cv:MaiShiraishi_God"] = "白石 麻衣",
    ["illustrator:MaiShiraishi_God"] = "Cassimolar",
    ["LuaPassport"] = "护照",
    [":LuaPassport"] = "锁定技，当场上存在「白石麻衣」时，若不存在「生田绘梨花」则所有其他角色手牌上限-1；若存在「生田绘梨花」则除「白石麻衣」和「生田绘梨花」之外的其他角色手牌上限-2，「白石麻衣」和「生田绘梨花」的手牌上限-1。",
    ["Luasongbai"] = "怂白",
    [":Luasongbai"] = "锁定技，当你受到一次伤害后，你获得一枚“怂”。",
    ["@song"] = "怂",
    ["Luashironjo"] = "白龙芝",
    [":Luashironjo"] = "限定技，回合开始时或当你体力值变化后低于3点时，若你有3张以上的“怂”，你可以将此技能替换为：出牌阶段，你可以弃置一枚“怂”视为使用一张【杀】，你以此法转化使用的【杀】不计入次数限制。",
    ["@shironjo"] = "白",
    ["Luashironjo_Unlimited"] = "白龙芝",
    [":Luashironjo_Unlimited"] = "出牌阶段，你可以弃置一枚“怂”视为使用一张【杀】，你以此法转化使用的【杀】不计入次数限制。",
    ["Luakamitaiou"] = "神对应",
    [":Luakamitaiou"] = "锁定技，当你使用以“怂”转化而来的【杀】造成伤害时，若此次伤害为你本回合第二次/第二次以上以此法造成伤害，则此次伤害+1/+2点。",
    ["kamitaiou"] = "神对应",
    ["LuaShiawasenoHogoshoku"] = "保护色",
    [":LuaShiawasenoHogoshoku"] = "当其他角色成为非你使用的【杀】的目标时，你可以弃置一张【闪】来代替其成为此【杀】的目标。",
    ["@Hogoshoku_Discard"] = "你可以弃置一张闪来代替%src成为%dest使用的%arg 的目标",
}
