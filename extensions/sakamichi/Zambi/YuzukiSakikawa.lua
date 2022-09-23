require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuzukiSakikawa = sgs.General(Zambi, "YuzukiSakikawa", "Zambi", 3, false)
table.insert(SKMC.SanKiSei, "YuzukiSakikawa")

--[[
    技能名：牺牲
    描述：当你受到1点伤害后，你可以令伤害来源摸一张牌，然后若其手牌数不少于你，其须交给你一半数量（向下取整）的手牌。
]]
LuaGisei = sgs.CreateTriggerSkill {
    name = "LuaGisei",
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from then
            for i = 0, damage.damage - 1, 1 do
                if room:askForSkillInvoke(player, self:objectName(),
                    sgs.QVariant("Gisei_invoke:" .. damage.from:objectName())) then
                    room:drawCards(damage.from, 1, self:objectName())
                    if damage.from:getHandcardNum() >= player:getHandcardNum() then
                        local card = room:askForExchange(damage.from, self:objectName(),
                            math.floor(damage.from:getHandcardNum() / 2), math.floor(damage.from:getHandcardNum() / 2),
                            true, "@Gisei_give:" .. player:objectName() .. "::"
                                .. math.floor(damage.from:getHandcardNum() / 2))
                        room:obtainCard(player, card, false)
                    end
                end
            end
        end
        return false
    end,
}
YuzukiSakikawa:addSkill(LuaGisei)

--[[
    技能名：认真
    描述：锁定技，当你受到【杀】或【决斗】造成的伤害时，若你的体力值为1，防止此伤害。
]]
Luamajime = sgs.CreateTriggerSkill {
    name = "Luamajime",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) and damage.to:getHp() == 1 then
            local msg = sgs.LogMessage()
            msg.type = "#majime"
            msg.from = damage.to
            msg.arg = self:objectName()
            msg.arg2 = damage.card:objectName()
            room:sendLog(msg)
            room:setEmotion(damage.to, "skill_nullify")
            return true
        end
    end,
}
YuzukiSakikawa:addSkill(Luamajime)

sgs.LoadTranslationTable {
    ["YuzukiSakikawa"] = "先川 柚月",
    ["&YuzukiSakikawa"] = "先川 柚月",
    ["#YuzukiSakikawa"] = "アイドルのように",
    ["designer:YuzukiSakikawa"] = "Cassimolar",
    ["cv:YuzukiSakikawa"] = "大園 桃子",
    ["illustrator:YuzukiSakikawa"] = "Cassimolar",
    ["LuaGisei"] = "牺牲",
    [":LuaGisei"] = "当你受到1点伤害后，你可以令伤害来源摸一张牌，然后若其手牌数不少于你，其须交给你一半数量（向下取整）的手牌。",
    ["LuaGisei:Gisei_invoke"] = "是否发动【牺牲】令%src摸一张牌",
    ["@Gisei_give"] = "请选择%arg张手牌交给%src",
    ["Luamajime"] = "认真",
    [":Luamajime"] = "锁定技，当你受到【杀】或【决斗】造成的伤害时，若你的体力值为1，防止此伤害。",
    ["#majime"] = "%from 的【%arg】被触发，此【%arg2】的伤害被防止",
}
