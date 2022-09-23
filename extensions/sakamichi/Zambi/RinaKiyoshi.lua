require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaKiyoshi = sgs.General(Zambi, "RinaKiyoshi", "Zambi", 4, false)
table.insert(SKMC.IKiSei, "RinaKiyoshi")

--[[
    技能名：烂漫
    描述：当你的牌因弃置而失去时，你可以防止失去此牌；当前回合结束时，若你此回合内以此法防止失去的牌数不小于2，你失去1点体力。
]]
Luaranman = sgs.CreateTriggerSkill {
    name = "Luaranman",
    events = {sgs.BeforeCardsMove, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and player:hasSkill(self)
                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                == sgs.CardMoveReason_S_REASON_DISCARD then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setPlayerFlag(player, "ranman")
                    room:addPlayerMark(player, "ranman", move.card_ids:length())
                    while not move.card_ids:isEmpty() do
                        for _, id in sgs.qlist(move.card_ids) do
                            move.from_places:removeAt(SKMC.list_index_of(move.card_ids, id))
                            move.card_ids:removeOne(id)
                        end
                    end
                    data:setValue(move)
                end
            end
        else
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("ranman") and player:hasSkill(self) then
                        if p:getMark("ranman") >= 2 then
                            room:loseHp(p)
                        end
                        room:setPlayerMark(p, "ranman", 0)
                    end
                end
            end
            return false
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaKiyoshi:addSkill(Luaranman)

--[[
    技能名：天井
    描述：锁定技，你对你不在其攻击范围内的角色使用【杀】无距离限制且你对你的上家和下家使用【杀】需要两张【闪】才能抵消。
]]
Luatenjou = sgs.CreateTriggerSkill {
    name = "Luatenjou",
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") and player:objectName() == use.from:objectName() then
            local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
            local index = 1
            for _, p in sgs.qlist(use.to) do
                if p:objectName() == player:getNextAlive():objectName() or p:getNextAlive():objectName()
                    == player:objectName() then
                    if jink_table[index] == 1 then
                        jink_table[index] = 2
                    end
                end
                index = index + 1
            end
            local jink_data = sgs.QVariant()
            jink_data:setValue(SKMC.table_to_IntList(jink_table))
            player:setTag("Jink_" .. use.card:toString(), jink_data)
        end
        return false
    end,
}
LuatenjouMod = sgs.CreateTargetModSkill {
    name = "LuatenjouMod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("Luatenjou") and to and not to:inMyAttackRange(from) then
            return 1000
        else
            return 0
        end
    end,
}
RinaKiyoshi:addSkill(Luatenjou)
if not sgs.Sanguosha:getSkill("LuatenjouMod") then
    SKMC.SkillList:append(LuatenjouMod)
end

sgs.LoadTranslationTable {
    ["RinaKiyoshi"] = "秋吉 凛",
    ["&RinaKiyoshi"] = "秋吉 凛",
    ["#RinaKiyoshi"] = "もっと可以愛く",
    ["designer:RinaKiyoshi"] = "Cassimolar",
    ["cv:RinaKiyoshi"] = "星野 みなみ",
    ["illustrator:RinaKiyoshi"] = "Cassimolar",
    ["Luaranman"] = "烂漫",
    [":Luaranman"] = "当你的牌因弃置而失去时，你可以防止失去此牌；当前回合结束时，若你此回合内以此法防止失去的牌数不小于2，你失去1点体力。",
    ["Luatenjou"] = "天井",
    [":Luatenjou"] = "锁定技，你对你不在其攻击范围内的角色使用【杀】无距离限制且你对你的上家和下家使用【杀】需要两张【闪】才能抵消。",
}
