require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SuzuneSakura = sgs.General(Zambi, "SuzuneSakura", "Zambi", 4, false)
table.insert(SKMC.NiKiSei, "SuzuneSakura")

--[[
    技能名：霸凌
    描述：其他角色弃牌阶段开始时，若其体力值不小于你且攻击范围内包含你，其可以对你使用一张【杀】。
]]
Luaijime = sgs.CreateTriggerSkill {
    name = "Luaijime",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Discard then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self) and player:getHp() >= p:getHp() and player:inMyAttackRange(p) then
                    room:askForUseSlashTo(player, p, "@ijime_slash:" .. p:objectName(), true, false)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SuzuneSakura:addSkill(Luaijime)

--[[
    技能名：倒茶
    描述：当你成为【杀】或黑色锦囊牌的唯一目标时，你可以进行一次判定，若判定结果为红色，你可以摸一张牌，然后你将此判定牌置于武将牌上称为“茶”；你的手牌上限+X（X为“茶”数）；当其他角色受到伤害后，你可以移去两张相同花色的“茶”令其失去/回复1点体力。
]]
LuaochaCard = sgs.CreateSkillCard {
    name = "LuaochaCard",
    skill_name = "Luaocha",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        if room:askForChoice(source, "Luaocha", "lose+recover") == "lose" then
            room:loseHp(source:getTag("LuaochaTarget"):toPlayer())
        else
            room:recover(source:getTag("LuaochaTarget"):toPlayer(), sgs.RecoverStruct(source, self))
        end
    end,
}
LuaochaVS = sgs.CreateViewAsSkill {
    name = "Luaocha",
    n = 2,
    filter_pattern = ".|.|.|ocha",
    expand_pile = "ocha",
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return sgs.Self:getPile("ocha"):contains(to_select:getEffectiveId())
        elseif (#selected == 1) then
            return sgs.Self:getPile("ocha"):contains(to_select:getEffectiveId())
                       and (to_select:getSuit() == selected[1]:getSuit())
        else
            return false
        end
    end,
    view_as = function(self, cards)
        local cd = LuaochaCard:clone()
        for _, card in pairs(cards) do
            cd:addSubcard(card)
        end
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@Luaocha")
    end,
}
Luaocha = sgs.CreateTriggerSkill {
    name = "Luaocha",
    view_as_skill = LuaochaVS,
    events = {sgs.TargetConfirming, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.card and (use.card:isKindOf("Slash") or (use.card:isKindOf("TrickCard") and use.card:isBlack()))
                and use.to:length() == 1 and use.to:contains(player) and player:hasSkill(self)
                and room:askForSkillInvoke(player, self:objectName(), data) then
                local judge = sgs.JudgeStruct()
                judge.pattern = ".|red"
                judge.good = true
                judge.reason = self:objectName()
                judge.who = player
                judge.play_animation = true
                room:judge(judge)
                if judge:isGood() then
                    room:drawCards(player, 1, self:objectName())
                    if not judge.card:isVirtualCard() then
                        player:addToPile("ocha", judge.card:getEffectiveId())
                    else
                        for _, id in sgs.qlist(card:getSubcards()) do
                            player:addToPile("ocha", id)
                        end
                    end
                end
            end
        else
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self) and p:getPile("ocha"):length() >= 2 then
                    local _data = sgs.QVariant()
                    _data:setValue(player)
                    p:setTag("LuaochaTarget", _data)
                    room:askForUseCard(p, "@@Luaocha", "@ocha", -1, sgs.Card_MethodDiscard, false)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuaochaMax = sgs.CreateMaxCardsSkill {
    name = "#LuaochaMax",
    extra_func = function(self, target)
        if target:hasSkill("Luaocha") then
            return target:getPile("ocha"):length()
        end
    end,
}
SuzuneSakura:addSkill(Luaocha)
if not sgs.Sanguosha:getSkill("#LuaochaMax") then
    SKMC.SkillList:append(LuaochaMax)
end

sgs.LoadTranslationTable {
    ["SuzuneSakura"] = "佐倉 鈴音",
    ["&SuzuneSakura"] = "佐倉 鈴音",
    ["#SuzuneSakura"] = "私の音",
    ["designer:SuzuneSakura"] = "Cassimolar",
    ["cv:SuzuneSakura"] = "渡辺 みり愛",
    ["illustrator:SuzuneSakura"] = "Cassimolar",
    ["Luaijime"] = "霸凌",
    [":Luaijime"] = "其他角色弃牌阶段开始时，若其体力值不小于你且攻击范围内包含你，其可以对你使用一张【杀】。",
    ["@ijime_slash"] = "你可以对%src使用一张【杀】",
    ["Luaocha"] = "倒茶",
    [":Luaocha"] = "当你成为【杀】或黑色锦囊牌的唯一目标时，你可以进行一次判定，若判定结果为红色，你可以摸一张牌，然后你将此判定牌置于武将牌上称为“茶”；你的手牌上限+X（X为“茶”数）；当其他角色受到伤害后，你可以移去两张相同花色的“茶”令其失去/回复1点体力。",
    ["ocha"] = "茶",
    ["Luaocha:lose"] = "令其失去1点体力",
    ["Luaocha:recover"] = "令其回复1点体力",
    ["~Luaocha"] = "选择两张相同花色的“茶” → 点击确定",
}
