require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MeiHigashimura_Hinatazaka = sgs.General(Sakamichi, "MeiHigashimura_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "MeiHigashimura_Hinatazaka")

--[[
    技能名：咩莓
    描述：当你造成伤害后，你可以摸一张牌并可以将一张红色手牌置于武将牌上称为“莓”，你可以选择这张牌在作为“莓”时是你与其他角色的距离-1或其他角色与你的距离-1；其他角色回合结束后，你可以选择将一张“莓”视为【桃】对自己使用（X为你的“莓”的数量）。
]]
Luamiemei = sgs.CreateTriggerSkill {
    name = "Luamiemei",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage and player:hasSkill(self) and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
            local card = room:askForCard(player, ".|red", "@miemei_invoke", data, sgs.Card_MethodNone)
            if card then
                player:addToPile("mei", card:getEffectiveId())
                if room:askForChoice(player, self:objectName(), "mei_1+mei_2") == "mei_1" then
                    local list = player:getTag("mei_1"):toIntList()
                    list:append(card:getEffectiveId())
                    local tag = sgs.QVariant()
                    tag:setValue(list)
                    player:setTag("mei_1", tag)
                    room:addPlayerMark(player, "&mei_1")
                else
                    local list = player:getTag("mei_2"):toIntList()
                    list:append(card:getEffectiveId())
                    local tag = sgs.QVariant()
                    tag:setValue(list)
                    player:setTag("mei_2", tag)
                    room:addPlayerMark(player, "&mei_2")
                end
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and p:isWounded() and not p:getPile("mei"):isEmpty() then
                    local ids = p:getPile("mei")
                    room:fillAG(ids)
                    local id = room:askForAG(p, ids, true, self:objectName())
                    room:clearAG()
                    if id ~= -1 then
                        local peach = sgs.Sanguosha:cloneCard("peach", sgs.Sanguosha:getCard(id):getSuit(),
                            sgs.Sanguosha:getCard(id):getNumber())
                        peach:setSkillName(self:objectName())
                        peach:addSubcard(id)
                        if p:getTag("mei_1"):toIntList():contains(id) then
                            local list = p:getTag("mei_1"):toIntList()
                            list:removeOne(id)
                            local tag = sgs.QVariant()
                            tag:setValue(list)
                            player:setTag("mei_1", tag)
                            room:removePlayerMark(p, "&mei_1")
                        elseif p:getTag("mei_2"):toIntList():contains(id) then
                            local list = p:getTag("mei_2"):toIntList()
                            list:removeOne(id)
                            local tag = sgs.QVariant()
                            tag:setValue(list)
                            player:setTag("mei_2", tag)
                            room:removePlayerMark(p, "&mei_2")
                        end
                        room:useCard(sgs.CardUseStruct(peach, p, p), true)
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
LuamiemeiDistance = sgs.CreateDistanceSkill {
    name = "#LuamiemeiDistance",
    correct_func = function(self, from, to)
        local correct = 0
        if from:getMark("&mei_1") ~= 0 then
            correct = correct - from:getMark("&mei_1")
        end
        if to:getMark("&mei_2") ~= 0 then
            correct = correct + to:getMark("&mei_2")
        end
        return correct
    end,
}
MeiHigashimura_Hinatazaka:addSkill(Luamiemei)
if not sgs.Sanguosha:getSkill("#LuamiemeiDistance") then
    SKMC.SkillList:append(LuamiemeiDistance)
end

sgs.LoadTranslationTable {
    ["MeiHigashimura_Hinatazaka"] = "東村 芽依",
    ["&MeiHigashimura_Hinatazaka"] = "東村 芽依",
    ["#MeiHigashimura_Hinatazaka"] = "奈良的獵豹",
    ["designer:MeiHigashimura_Hinatazaka"] = "Cassimolar",
    ["cv:MeiHigashimura_Hinatazaka"] = "東村 芽依",
    ["illustrator:MeiHigashimura_Hinatazaka"] = "Cassimolar",
    ["Luamiemei"] = "咩莓",
    [":Luamiemei"] = "当你造成伤害后，你可以摸一张牌并可以将一张红色手牌置于武将牌上称为“莓”，你可以选择这张牌在作为“莓”时是你与其他角色的距离-1或其他角色与你的距离-1；其他角色回合结束后，你可以选择将一张“莓”视为【桃】对自己使用（X为你的“莓”的数量）。",
    ["@miemei_invoke"] = "你可以将一张红色手牌置于武将牌上称为“莓”",
    ["mei_1"] = "-1莓",
    ["mei_2"] = "+1莓",
    ["mei"] = "莓",
}
