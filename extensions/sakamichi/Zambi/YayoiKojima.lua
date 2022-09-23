require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YayoiKojima = sgs.General(Zambi, "YayoiKojima", "Zambi", 3, false)
table.insert(SKMC.SanKiSei, "YayoiKojima")

--[[
    技能名：幻觉
    描述：锁定技，当一名角色的回合开始时，其与你分别进行一次判定，若两张判定牌花色不同，本回合内，其所有与其判定牌花色相同的牌的花色均视为你的判定牌的花色；否则你获得两张判定牌。
]]
Luagenkaku = sgs.CreateTriggerSkill {
    name = "Luagenkaku",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.FinishJudge},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local target = room:findPlayerBySkillName(self:objectName())
            local judge1 = sgs.JudgeStruct()
            local judge2 = sgs.JudgeStruct()
            judge1.pattern = "."
            judge2.pattern = "."
            judge1.reason = self:objectName()
            judge2.reason = self:objectName()
            judge2.who = target
            judge1.who = player
            --	room:setPlayerFlag(player, "genkaku1")
            room:judge(judge1)
            --	card1 = sgs.Sanguosha:getCard(room:getTag("genkaku1"):toInt())
            --	room:removeTag("genkaku1")
            --	room:setPlayerFlag(player, "-genkaku1")
            --	room:setPlayerFlag(target, "genkaku2")
            room:judge(judge2)
            --	card2 = sgs.Sanguosha:getCard(room:getTag("genkaku2"):toInt())
            --	room:removeTag("genkaku2")
            --	room:setPlayerFlag(target, "-genkaku2")
            card1 = judge1.card
            card2 = judge2.card
            if card1:getSuit() == card2:getSuit() then
                target:obtainCard(card1)
                target:obtainCard(card2)
            elseif card1:getSuit() == sgs.Card_Spade then
                if card2:getSuit() == sgs.Card_Club then
                    room:handleAcquireDetachSkills(player, "LuagenkakuS2C", true)
                    room:setPlayerMark(player, "&S2C", 1)
                elseif card2:getSuit() == sgs.Card_Heart then
                    room:handleAcquireDetachSkills(player, "LuagenkakuS2H", true)
                    room:setPlayerMark(player, "&S2H", 1)
                elseif card2:getSuit() == sgs.Card_Diamond then
                    room:handleAcquireDetachSkills(player, "LuagenkakuS2D", true)
                    room:setPlayerMark(player, "&S2D", 1)
                end
            elseif card1:getSuit() == sgs.Card_Club then
                if card2:getSuit() == sgs.Card_Spade then
                    room:handleAcquireDetachSkills(player, "LuagenkakuC2S", true)
                    room:setPlayerMark(player, "&C2S", 1)
                elseif card2:getSuit() == sgs.Card_Heart then
                    room:handleAcquireDetachSkills(player, "LuagenkakuC2H", true)
                    room:setPlayerMark(player, "&C2H", 1)
                elseif card2:getSuit() == sgs.Card_Diamond then
                    room:handleAcquireDetachSkills(player, "LuagenkakuC2D", true)
                    room:setPlayerMark(player, "&C2D", 1)
                end
            elseif card1:getSuit() == sgs.Card_Heart then
                if card2:getSuit() == sgs.Card_Spade then
                    room:handleAcquireDetachSkills(player, "LuagenkakuH2S", true)
                    room:setPlayerMark(player, "&H2S", 1)
                elseif card2:getSuit() == sgs.Card_Club then
                    room:handleAcquireDetachSkills(player, "LuagenkakuH2C", true)
                    room:setPlayerMark(player, "&H2C", 1)
                elseif card2:getSuit() == sgs.Card_Diamond then
                    room:handleAcquireDetachSkills(player, "LuagenkakuH2D", true)
                    room:setPlayerMark(player, "&H2D", 1)
                end
            elseif card1:getSuit() == sgs.Card_Diamond then
                if card2:getSuit() == sgs.Card_Spade then
                    room:handleAcquireDetachSkills(player, "LuagenkakuD2S", true)
                    room:setPlayerMark(player, "&D2S", 1)
                elseif card2:getSuit() == sgs.Card_Club then
                    room:handleAcquireDetachSkills(player, "LuagenkakuD2C", true)
                    room:setPlayerMark(player, "&D2C", 1)
                elseif card2:getSuit() == sgs.Card_Heart then
                    room:handleAcquireDetachSkills(player, "LuagenkakuD2H", true)
                    room:setPlayerMark(player, "&D2H", 1)
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            if player:hasSkill("LuagenkakuS2C") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuS2C", true)
                room:setPlayerMark(player, "&S2C", 0)
            end
            if player:hasSkill("LuagenkakuS2H") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuS2H", true)
                room:setPlayerMark(player, "&S2H", 0)
            end
            if player:hasSkill("LuagenkakuS2D") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuS2D", true)
                room:setPlayerMark(player, "&S2D", 0)
            end
            if player:hasSkill("LuagenkakuC2S") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuC2S", true)
                room:setPlayerMark(player, "&C2S", 0)
            end
            if player:hasSkill("LuagenkakuC2H") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuC2H", true)
                room:setPlayerMark(player, "&C2H", 0)
            end
            if player:hasSkill("LuagenkakuC2D") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuC2D", true)
                room:setPlayerMark(player, "&C2D", 0)
            end
            if player:hasSkill("LuagenkakuH2S") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuH2S", true)
                room:setPlayerMark(player, "&H2S", 0)
            end
            if player:hasSkill("LuagenkakuH2C") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuH2C", true)
                room:setPlayerMark(player, "&H2C", 0)
            end
            if player:hasSkill("LuagenkakuH2D") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuH2D", true)
                room:setPlayerMark(player, "&H2D", 0)
            end
            if player:hasSkill("LuagenkakuD2S") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuD2S", true)
                room:setPlayerMark(player, "&D2S", 0)
            end
            if player:hasSkill("LuagenkakuD2C") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuD2C", true)
                room:setPlayerMark(player, "&D2C", 0)
            end
            if player:hasSkill("LuagenkakuD2H") then
                room:handleAcquireDetachSkills(player, "-LuagenkakuD2H", true)
                room:setPlayerMark(player, "&D2H", 0)
            end
            --		elseif event == sgs.FinishJudge then
            --			local judge = data:toJudge()
            --			if judge.reason == self:objectName() then
            --				if judge.who:objectName() == player:objectName() then
            --					if player:hasFlag("genkaku1") then
            --						room:setTag("genkaku1", sgs.QVariant(judge.card:getEffectiveId()))
            --					end
            --					if player:hasFlag("genkaku2") then
            --						room:setTag("genkaku2", sgs.QVariant(judge.card:getEffectiveId()))
            --					end
            --				end
            --			end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuagenkakuS2C = sgs.CreateFilterSkill {
    name = "LuagenkakuS2C",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Spade
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Club)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuS2H = sgs.CreateFilterSkill {
    name = "LuagenkakuS2H",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Spade
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Heart)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuS2D = sgs.CreateFilterSkill {
    name = "LuagenkakuS2D",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Spade
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Diamond)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuC2S = sgs.CreateFilterSkill {
    name = "LuagenkakuC2S",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Club
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Spade)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuC2H = sgs.CreateFilterSkill {
    name = "LuagenkakuC2H",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Club
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Heart)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuC2D = sgs.CreateFilterSkill {
    name = "LuagenkakuC2D",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Club
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Diamond)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuH2S = sgs.CreateFilterSkill {
    name = "LuagenkakuH2S",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Heart
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Spade)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuH2C = sgs.CreateFilterSkill {
    name = "LuagenkakuH2C",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Heart
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Club)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuH2D = sgs.CreateFilterSkill {
    name = "LuagenkakuH2D",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Heart
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Diamond)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuD2S = sgs.CreateFilterSkill {
    name = "LuagenkakuD2S",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Diamond
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Spade)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuD2C = sgs.CreateFilterSkill {
    name = "LuagenkakuD2C",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Diamond
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Club)
        new_card:setModified(true)
        return new_card
    end,
}
LuagenkakuD2H = sgs.CreateFilterSkill {
    name = "LuagenkakuD2H",
    view_filter = function(self, to_select)
        return to_select:getSuit() == sgs.Card_Diamond
    end,
    view_as = function(self, card)
        local id = card:getEffectiveId()
        local new_card = sgs.Sanguosha:getWrappedCard(id)
        new_card:setSkillName("Luagenkaku")
        new_card:setSuit(sgs.Card_Heart)
        new_card:setModified(true)
        return new_card
    end,
}
YayoiKojima:addSkill(Luagenkaku)
if not sgs.Sanguosha:getSkill("LuagenkakuS2C") then
    SKMC.SkillList:append(LuagenkakuS2C)
end
if not sgs.Sanguosha:getSkill("LuagenkakuS2H") then
    SKMC.SkillList:append(LuagenkakuS2H)
end
if not sgs.Sanguosha:getSkill("LuagenkakuS2D") then
    SKMC.SkillList:append(LuagenkakuS2D)
end
if not sgs.Sanguosha:getSkill("LuagenkakuC2S") then
    SKMC.SkillList:append(LuagenkakuC2S)
end
if not sgs.Sanguosha:getSkill("LuagenkakuC2H") then
    SKMC.SkillList:append(LuagenkakuC2H)
end
if not sgs.Sanguosha:getSkill("LuagenkakuC2D") then
    SKMC.SkillList:append(LuagenkakuC2D)
end
if not sgs.Sanguosha:getSkill("LuagenkakuH2S") then
    SKMC.SkillList:append(LuagenkakuH2S)
end
if not sgs.Sanguosha:getSkill("LuagenkakuH2C") then
    SKMC.SkillList:append(LuagenkakuH2C)
end
if not sgs.Sanguosha:getSkill("LuagenkakuH2D") then
    SKMC.SkillList:append(LuagenkakuH2D)
end
if not sgs.Sanguosha:getSkill("LuagenkakuD2S") then
    SKMC.SkillList:append(LuagenkakuD2S)
end
if not sgs.Sanguosha:getSkill("LuagenkakuD2C") then
    SKMC.SkillList:append(LuagenkakuD2C)
end
if not sgs.Sanguosha:getSkill("LuagenkakuD2H") then
    SKMC.SkillList:append(LuagenkakuD2H)
end

--[[
    技能名：内鬼
    描述：当一名角色使用【杀】指定目标后，你可以弃置一张花色/点数与此【杀】相同的牌令其选择一项：1.目标无法使用【闪】响应此【杀】；2.此【杀】造成的伤害+1。
]]
Luainnerghost = sgs.CreateTriggerSkill {
    name = "Luainnerghost",
    events = {sgs.TargetSpecified, sgs.DamageCaused, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForCard(p, ".|" .. use.card:getSuitString() .. "#.|.|" .. use.card:getNumber(),
                        "@innerghost_discard:::" .. use.card:getSuitString() .. ":" .. use.card:getNumber(), data,
                        self:objectName()) then
                        local choice = room:askForChoice(player, self:objectName(), "innerghost_hit+innerghost_damage")
                        if choice == "innerghost_hit" then
                            local log = sgs.LogMessage()
                            log.type = "#innerghost_hit"
                            log.from = player
                            log.card_str = use.card:toString()
                            log.arg = choice
                            room:sendLog(log)
                            local index = 1
                            local jink_table =
                                sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
                            for _, p in sgs.qlist(use.to) do
                                jink_table[index] = 0
                                index = index + 1
                            end
                            local jink_data = sgs.QVariant()
                            jink_data:setValue(SKMC.table_to_IntList(jink_table))
                            player:setTag("Jink_" .. use.card:toString(), jink_data)
                        else
                            local log = sgs.LogMessage()
                            log.type = "#innerghost_damage"
                            log.from = player
                            log.card_str = use.card:toString()
                            log.arg = choice
                            room:sendLog(log)
                            room:setCardFlag(use.card, "innerghost_damage")
                        end
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.by_user and not damage.chain and not damage.transfer
                and damage.card:hasFlag("innerghost_damage") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.CardFinished and data:toCardUse().card:hasFlag("innerghost_damage") then
            room:setCardFlag(data:toCardUse().card, "-innerghost_damage")
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YayoiKojima:addSkill(Luainnerghost)

sgs.LoadTranslationTable {
    ["YayoiKojima"] = "小島 弥生",
    ["&YayoiKojima"] = "小島 弥生",
    ["#YayoiKojima"] = "私であるが故に",
    ["designer:YayoiKojima"] = "Cassimolar",
    ["cv:YayoiKojima"] = "阪口 珠美",
    ["illustrator:YayoiKojima"] = "Cassimolar",
    ["Luagenkaku"] = "幻觉",
    [":Luagenkaku"] = "锁定技，当一名角色的回合开始时，其与你分别进行一次判定，若两张判定牌花色不同，本回合内，其所有与其判定牌花色相同的牌的花色均视为你的判定牌的花色；否则你获得两张判定牌。",
    ["LuagenkakuS2C"] = "幻象",
    [":LuagenkakuS2C"] = "锁定技，你的黑桃牌均视为梅花牌。",
    ["S2C"] = "♠ → ♣",
    ["LuagenkakuS2H"] = "幻象",
    [":LuagenkakuS2H"] = "锁定技，你的黑桃牌均视为红桃牌。",
    ["S2H"] = "♠ → ♥",
    ["LuagenkakuS2D"] = "幻象",
    [":LuagenkakuS2D"] = "锁定技，你的黑桃牌均视为方块牌。",
    ["S2D"] = "♠ → ♦",
    ["LuagenkakuC2S"] = "幻象",
    [":LuagenkakuC2S"] = "锁定技，你的梅花牌均视为黑桃牌。",
    ["C2S"] = "♣ → ♠",
    ["LuagenkakuC2H"] = "幻象",
    [":LuagenkakuC2H"] = "锁定技，你的梅花牌均视为红桃牌。",
    ["C2H"] = "♣ → ♥",
    ["LuagenkakuC2D"] = "幻象",
    [":LuagenkakuC2D"] = "锁定技，你的梅花牌均视为方块牌。",
    ["C2D"] = "♣ → ♦",
    ["LuagenkakuH2S"] = "幻象",
    [":LuagenkakuH2S"] = "锁定技，你的红桃牌均视为黑桃牌。",
    ["H2S"] = "♥ → ♠",
    ["LuagenkakuH2C"] = "幻象",
    [":LuagenkakuH2C"] = "锁定技，你的红桃牌均视为梅花牌。",
    ["H2C"] = "♥ → ♣",
    ["LuagenkakuH2D"] = "幻象",
    [":LuagenkakuH2D"] = "锁定技，你的红桃牌均视为方块牌。",
    ["H2D"] = "♥ → ♦",
    ["LuagenkakuD2S"] = "幻象",
    [":LuagenkakuD2S"] = "锁定技，你的方块牌均视为黑桃牌。",
    ["D2S"] = "♦ → ♠",
    ["LuagenkakuD2C"] = "幻象",
    [":LuagenkakuD2C"] = "锁定技，你的方块牌均视为梅花牌。",
    ["D2C"] = "♦ → ♣",
    ["LuagenkakuD2H"] = "幻象",
    [":LuagenkakuD2H"] = "锁定技，你的方块牌均视为红桃牌。",
    ["D2H"] = "♦ → ♥",
    ["Luainnerghost"] = "内鬼",
    [":Luainnerghost"] = "当一名角色使用【杀】指定目标后，你可以弃置一张花色/点数与此【杀】相同的牌令其选择一项：1.目标无法使用【闪】响应此【杀】；2.此【杀】造成的伤害+1。",
    ["@innerghost_discard"] = "你可以弃置一张花色为%arg/点数为%arg2的牌发动【内鬼】",
    ["innerghost_hit"] = "目标无法使用【闪】响应此【杀】",
    ["innerghost_damage"] = "此【杀】造成的伤害+1",
    ["#innerghost_hit"] = "%from选择了%arg，%card不可以闪避。",
    ["#innerghost_damage"] = "%from选择了%arg，%card造成的伤害+1。",
}
