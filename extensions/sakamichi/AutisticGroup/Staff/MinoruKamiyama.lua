MinoruKamiyama = sgs.General(Sakamichi, "MinoruKamiyama", "AutisticGroup", 4, true)

--[[
    技能名：DD头子
    描述：弃牌阶段开始时，你可以摸X+1张牌（X为场上你的推数），然后你可以交给一名其他角色一张手牌，若其不为你的推则视为你对其加推。
]]
LuaDDtouzi = sgs.CreateTriggerSkill {
    name = "LuaDDtouzi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Discard then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local oshi = 0
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark("oshi" .. player:objectName()) ~= 0 then
                        oshi = oshi + 1
                    end
                end
                player:drawCards(oshi + 1)
                for _, card in sgs.qlist(player:getHandcards()) do
                    room:setCardFlag(card, "DDtouzi")
                end
                room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1,
                    room:getOtherPlayers(player), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                        player:objectName(), self:objectName(), nil), "@DDtouzi_invoke", true)
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    for _, card in sgs.qlist(p:getHandcards()) do
                        if card:hasFlag("DDtouzi") then
                            room:setCardFlag(card, "-DDtouzi")
                            if p:getMark("oshi" .. player:objectName()) == 0 then
                                local msg = sgs.LogMessage()
                                msg.type = "#DDtouzi"
                                msg.from = player
                                msg.to:append(p)
                                room:sendLog(msg)
                                room:setPlayerMark(p, "oshi" .. player:objectName(), 1)
                                room:addPlayerMark(p, "@Oshi")
                            end
                        end
                    end
                end
                for _, card in sgs.qlist(player:getHandcards()) do
                    room:setCardFlag(card, "-DDtouzi")
                end
            end
        end
        return false
    end,
}
MinoruKamiyama:addSkill(LuaDDtouzi)

--[[
    技能名：推毕业了
    描述：其他角色死亡时，若其为你的推，你可以获得其手牌区和装备区所有牌。
]]
Luatuibiyele = sgs.CreateTriggerSkill {
    name = "Luatuibiyele",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() and not player:isNude() then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isAlive() and p:hasSkill(self) and player:getMark(p:objectName() .. "Oshi") ~= 0 then
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        local cards = player:getCards("he")
                        if cards:length() > 0 then
                            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                            for _, card in sgs.qlist(cards) do
                                dummy:addSubcard(card)
                            end
                            local msg = sgs.LogMessage()
                            msg.type = "#tuibiyele"
                            msg.from = p
                            msg.to:append(player)
                            room:sendLog(msg)
                            room:obtainCard(p, dummy)
                            dummy:deleteLater()
                        end
                        break
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target then
            return not target:hasSkill(self)
        end
        return false
    end,
}
MinoruKamiyama:addSkill(Luatuibiyele)

sgs.LoadTranslationTable {
    ["MinoruKamiyama"] = "加美山 稔",
    ["&MinoruKamiyama"] = "加美山 稔",
    ["#MinoruKamiyama"] = "妄想攝影師",
    ["designer:MinoruKamiyama"] = "Cassimolar",
    ["cv:MinoruKamiyama"] = "加美山 稔",
    ["illustrator:MinoruKamiyama"] = "Cassimolar",
    ["LuaDDtouzi"] = "DD头子",
    [":LuaDDtouzi"] = "弃牌阶段开始时，你可以摸X+1张牌（X为场上你的推数），然后你可以交给一名其他角色一张手牌，若其不为你的推则视为你对其加推。",
    ["@DDtouzi_invoke"] = "你可以将一张手牌交给一名其他角色，若其不是你的推，则你加推之",
    ["#DDtouzi"] = "%from 加推了 %to",
    ["@Oshi"] = "推",
    ["Luatuibiyele"] = "推毕业了",
    [":Luatuibiyele"] = "其他角色死亡时，若其为你的推，你可以获得其手牌区和装备区所有牌。",
    ["#tuibiyele"] = "%from 的推 %to 毕业了",
}