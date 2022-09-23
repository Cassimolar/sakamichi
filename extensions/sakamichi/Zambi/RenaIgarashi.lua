require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenaIgarashi = sgs.General(Zambi, "RenaIgarashi", "Zambi", 4, false)
table.insert(SKMC.NiKiSei, "RenaIgarashi")

--[[
    技能名：涂鸦
    描述：当你一次性获得/失去至少两张牌时，你可以回复1点体力值。
]]
Luarakugaki = sgs.CreateTriggerSkill {
    name = "Luarakugaki",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag("FirstRound"):toBool() and move.card_ids:length() >= 2
            and ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand)
                or (move.from and move.from:objectName() == player:objectName()
                    and (move.from_places:contains(sgs.Player_PlaceHand)
                        or move.from_places:contains(sgs.Player_PlaceEquip))
                    and not (move.to and move.to:objectName() == player:objectName()))) then
            if player:isWounded() and room:askForSkillInvoke(player, self:objectName(), data) then
                room:recover(player, sgs.RecoverStruct(player))
            end
        end
        return false
    end,
}
RenaIgarashi:addSkill(Luarakugaki)

--[[
    技能名：缓变
    描述：当你受到伤害时，你可以弃置一张牌防止此伤害，并将牌堆顶X张牌置于你的武将牌上称为“缓”（X为此次伤害值）；锁定技，回合开始时，若你有“缓”，你失去X点体力并获得这些“缓”（X为“缓”数）。
]]
Luayukkuritohenkasuru = sgs.CreateTriggerSkill {
    name = "Luayukkuritohenkasuru",
    events = {sgs.DamageInflicted, sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local card = room:askForCard(player, ".", "@yukkuritohenkasuru_discard", data, self:objectName())
            if card then
                player:addToPile("huan", room:getNCards(damage.damage))
                return true
            end
        elseif player:getPhase() == sgs.Player_Start and player:getPile("huan"):length() ~= 0 then
            room:loseHp(player, player:getPile("huan"):length())
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            for _, id in sgs.qlist(player:getPile("huan")) do
                dummy:addSubcard(id)
            end
            player:obtainCard(dummy)
        end
        return false
    end,
}
RenaIgarashi:addSkill(Luayukkuritohenkasuru)

sgs.LoadTranslationTable {
    ["RenaIgarashi"] = "五十嵐 麗奈",
    ["&RenaIgarashi"] = "五十嵐 麗奈",
    ["#RenaIgarashi"] = "カメラは肌身離さず",
    ["designer:RenaIgarashi"] = "Cassimolar",
    ["cv:RenaIgarashi"] = "伊藤 純奈",
    ["illustrator:RenaIgarashi"] = "Cassimolar",
    ["Luarakugaki"] = "涂鸦",
    [":Luarakugaki"] = "当你一次性获得/失去至少两张牌时，你可以回复1点体力值。",
    ["Luayukkuritohenkasuru"] = "缓变",
    [":Luayukkuritohenkasuru"] = "当你受到伤害时，你可以弃置一张牌防止此伤害，并将牌堆顶X张牌置于你的武将牌上称为“缓”（X为此次伤害值）；锁定技，回合开始时，若你有“缓”，你失去X点体力并获得这些“缓”（X为“缓”数）。",
    ["Luayukkuritohenkasuru:@yukkuritohenkasuru_discard"] = "你可以弃置一张牌防止此次伤害并获得等量的“缓”",
    ["huan"] = "缓",
}
