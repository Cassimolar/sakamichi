require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NaoKosaka_HiraganaKeyakizaka = sgs.General(Sakamichi, "NaoKosaka_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 4, false)
table.insert(SKMC.NiKiSei, "NaoKosaka_HiraganaKeyakizaka")

--[[
    技能名：草莓
    描述：出牌阶段限一次，你可以将一张方块视为【桃园结义】使用；你的回合内，其他角色每回复1点体力你可以摸一张牌。
]]
LuacaomeiVS = sgs.CreateOneCardViewAsSkill {
    name = "Luacaomei",
    filter_pattern = ".|diamond",
    view_as = function(self, card)
        local cd
        cd = sgs.Sanguosha:cloneCard("god_salvation", card:getSuit(), card:getNumber())
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isNude() and not player:hasFlag("caomei_used")
    end,
}
Luacaomei = sgs.CreateTriggerSkill {
    name = "Luacaomei",
    view_as_skill = LuacaomeiVS,
    events = {sgs.CardUsed, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasSkill(self) and use.card:isKindOf("GodSalvation") and use.card:getSkillName()
                == self:objectName() then
                room:setPlayerFlag(player, "caomei_used")
            end
        else
            local recover = data:toRecover()
            local current = room:getCurrent()
            if current:hasSkill(self) and current:objectName() ~= player:objectName() then
                room:drawCards(current, recover.recover, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NaoKosaka_HiraganaKeyakizaka:addSkill(Luacaomei)

--[[
    技能名：软音
    描述：锁定技，你的回合内，其他角色的装备无效；你不是【决斗】的合法目标。
]]
Luaruanyin = sgs.CreateTriggerSkill {
    name = "Luaruanyin",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:addPlayerMark(p, "Equips_Nullified_to_Yourself", 1)
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:removePlayerMark(p, "Equips_Nullified_to_Yourself", 1)
            end
        end
        return false
    end,
}
LuaruanyinProhibit = sgs.CreateProhibitSkill {
    name = "#LuaruanyinProhibit",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("Luaruanyin") and card:isKindOf("Duel")
    end,
}
NaoKosaka_HiraganaKeyakizaka:addSkill(Luaruanyin)
if not sgs.Sanguosha:getSkill("#LuaruanyinProhibit") then
    SKMC.SkillList:append(LuaruanyinProhibit)
end

sgs.LoadTranslationTable {
    ["NaoKosaka_HiraganaKeyakizaka"] = "小坂 菜緒",
    ["&NaoKosaka_HiraganaKeyakizaka"] = "小坂 菜緒",
    ["#NaoKosaka_HiraganaKeyakizaka"] = "奇異少女",
    ["designer:NaoKosaka_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:NaoKosaka_HiraganaKeyakizaka"] = "小坂 菜緒",
    ["illustrator:NaoKosaka_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luacaomei"] = "草莓",
    [":Luacaomei"] = "出牌阶段限一次，你可以将一张方块视为【桃园结义】使用；你的回合内，其他角色每回复1点体力你可以摸一张牌。",
    ["Luaruanyin"] = "软音",
    [":Luaruanyin"] = "锁定技，你的回合内，其他角色的装备无效；你不是【决斗】的合法目标。",
}
