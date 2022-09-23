require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MireiSasaki_Hinatazaka = sgs.General(Sakamichi, "MireiSasaki_Hinatazaka$", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "MireiSasaki_Hinatazaka")

MireiSasaki_Hinatazaka:addSkill("sakamichi_zhang_yu")

--[[
    技能名：母役
    描述：其他女性角色的弃牌阶段结束时，若其于本阶段弃置的牌均为黑色且其不为你的“娘”，你可以令该角色成为你的“娘”；当你的“娘”出牌阶段结束时，若其未于此阶段使用过【杀】则你的下个出牌阶段【杀】的使用次数上限+1；你的“娘”死亡时，你摸等同于你的“娘”数目的牌，并失去此技能。
]]
Luamuyi = sgs.CreateTriggerSkill {
    name = "Luamuyi",
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local source = move.from
            if source and source:objectName() == player:objectName() and player:getPhase() == sgs.Player_Discard then
                for _, id in sgs.qlist(move.card_ids) do
                    if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                        == sgs.CardMoveReason_S_REASON_DISCARD then
                        if sgs.Sanguosha:getCard(id):isRed() then
                            room:setPlayerFlag(player, "muyi_red")
                        elseif sgs.Sanguosha:getCard(id):isBlack() then
                            room:setPlayerFlag(player, "muyi_black")
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Discard and player:hasFlag("muyi_black")
                and not player:hasFlag("muyi_red") and player:isFemale() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("muyi" .. player:objectName()) == 0 and p:objectName() ~= player:objectName()
                        and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                        room:setPlayerMark(p, "muyi" .. player:objectName(), 1)
                        room:addPlayerMark(player, "@niang")
                    end
                end
            end
            if player:getPhase() == sgs.Player_Play and player:getMark("@niang") ~= 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("muyi" .. player:objectName()) == 1 then
                        room:addPlayerMark(p, "&muyi_slash", 1)
                    end
                end
            end
            if player:getPhase() == sgs.Player_Discard then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "muyi_slash") and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        else
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:getMark("@niang") ~= 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("muyi" .. player:objectName()) ~= 0 then
                        local n = 1
                        for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                            if p:getMark("muyi" .. pl:objectName()) ~= 0 then
                                n = n + 1
                                room:setPlayerMark(p, "muyi" .. pl:objectName(), 0)
                                room:removePlayerMark(pl, "@niang", 1)
                            end
                        end
                        room:drawCards(p, n, self:objectName())
                        room:handleAcquireDetachSkills(p, "-Luamuyi")
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
LuamuyiMod = sgs.CreateTargetModSkill {
    name = "#LuamuyiMod",
    pattern = "Slash",
    residue_func = function(self, player)
        if player:hasSkill("Luamuyi") then
            local n = 0
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "muyi_slash") and player:getMark(mark) > 0 then
                    n = n + 1
                end
            end
            return n
        end
    end,
}
-- MireiSasaki_Hinatazaka:addSkill(Luamuyi)
if not sgs.Sanguosha:getSkill("#LuamuyiMod") then
    SKMC.SkillList:append(LuamuyiMod)
end

--[[
    技能名：养命
    描述：你使用【酒】时可以回复1点体力值；你使用【酒】【杀】令其他角色进入濒死时，你可以从弃牌堆选择获得一张【酒】。
]]
Luayangming = sgs.CreateTriggerSkill {
    name = "Luayangming",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Analeptic") and use.from:objectName() == player:objectName() and player:hasSkill(self)
                and player:isWounded() and room:askForSkillInvoke(player, self:objectName(), data) then
                room:recover(player, sgs.RecoverStruct(player))
            end
        else
            local dying = data:toDying()
            if dying.damage and dying.damage.from and dying.damage.from:hasSkill(self) and dying.damage.card
                and dying.damage.card:hasFlag("drank")
                and room:askForSkillInvoke(dying.damage.from, self:objectName(), data) then
                local toGainList = sgs.IntList()
                for _, id in sgs.qlist(room:getDiscardPile()) do
                    if sgs.Sanguosha:getCard(id):isKindOf("Analeptic") then
                        toGainList:append(id)
                    end
                end
                if toGainList:length() ~= 0 then
                    room:fillAG(toGainList, dying.damage.from)
                    local card_id = room:askForAG(dying.damage.from, toGainList, true, self:objectName())
                    if card_id ~= -1 then
                        room:moveCardTo(sgs.Sanguosha:getCard(card_id), dying.damage.from, sgs.Player_PlaceHand, true)
                    end
                    room:clearAG(dying.damage.from)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MireiSasaki_Hinatazaka:addSkill(Luayangming)

--[[
    技能名：微机
    描述：主公技，当你的判定结束时，其他“けやき坂46”或“日向坂46”势力的角色可以弃置一张牌进行一次判定，若结果为♥，你可以从弃牌堆选择获得一张基本牌。
]]
Luaweiji = sgs.CreateTriggerSkill {
    name = "Luaweiji$",
    events = {sgs.FinishJudge},
    on_trigger = function(self, event, player, data, room)
        if player:hasLordSkill(self) then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if (p:getKingdom() == "HiraganaKeyakizaka46" or p:getKingdom() == "Hinatazaka46") and not p:isNude() then
                    local card = room:askForCard(p, ".", "@weiji_invoke:" .. player:objectName(), data,
                        sgs.Card_MethodDiscard, nil, false, self:objectName(), false)
                    if card then
                        local judge = sgs.JudgeStruct()
                        judge.pattern = ".|heart"
                        judge.good = true
                        judge.reason = self:objectName()
                        judge.who = p
                        room:judge(judge)
                        if judge:isGood() then
                            local toGainList = sgs.IntList()
                            for _, id in sgs.qlist(room:getDiscardPile()) do
                                if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                                    toGainList:append(id)
                                end
                            end
                            if toGainList:length() ~= 0 then
                                room:fillAG(toGainList, player)
                                local card_id = room:askForAG(player, toGainList, true, self:objectName())
                                if card_id ~= -1 then
                                    room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceHand, true)
                                end
                                room:clearAG(player)
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
}
MireiSasaki_Hinatazaka:addSkill(Luaweiji)

sgs.LoadTranslationTable {
    ["MireiSasaki_Hinatazaka"] = "佐々木 美玲",
    ["&MireiSasaki_Hinatazaka"] = "佐々木 美玲",
    ["#MireiSasaki_Hinatazaka"] = "咪胖",
    ["designer:MireiSasaki_Hinatazaka"] = "Cassimolar",
    ["cv:MireiSasaki_Hinatazaka"] = "佐々木 美玲",
    ["illustrator:MireiSasaki_Hinatazaka"] = "Cassimolar",
    --	["Luamuyi"] = "母役",
    --	[":Luamuyi"] = "其他女性角色的弃牌阶段结束时，若其于本阶段弃置的牌均为黑色且其不为你的“娘”，你可以令该角色成为你的“娘”；当你的“娘”出牌阶段结束时，若其未于此阶段使用过【杀】则你的下个出牌阶段【杀】的使用次数上限+1；你的“娘”死亡时，你摸等同于你的“娘”数目的牌，并失去此技能。",
    --	["@niang"] = "娘",
    --	["muyi_slash"] = "母役杀",
    --	["Luamuyi:invoke"] = "是否令%src成为你的“娘”",
    ["Luayangming"] = "养命",
    [":Luayangming"] = "你使用【酒】时可以回复1点体力值；你使用【酒】【杀】令其他角色进入濒死时，你可以从弃牌堆选择获得一张【酒】。",
    ["Luaweiji"] = "微机",
    [":Luaweiji"] = "主公技，当你的判定结束时，其他“けやき坂46”或“日向坂46”势力的角色可以弃置一张牌进行一次判定，若结果为♥，你可以从弃牌堆选择获得一张基本牌。",
    ["@weiji_invoke"] = "你可以弃置一张牌发动%src的【微机】",
}
