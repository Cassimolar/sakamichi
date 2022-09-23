require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManaTakase_HiraganaKeyakizaka =
    sgs.General(Sakamichi, "ManaTakase_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 4, false)
table.insert(SKMC.IKiSei, "ManaTakase_HiraganaKeyakizaka")

--[[
    技能名：语窗
    描述：当你成为黑桃牌的目标时，你可以摸一张牌；当你成为梅花牌的目标时，你可以弃置此牌使用者一张牌；当你成为红桃牌的目标时，你可以与此牌使用者各摸一张牌；当你一回合内以此法获得牌不少于两张时，此技能失效直到当前回合结束。
]]
Luayuchuang = sgs.CreateTriggerSkill {
    name = "Luayuchuang",
    --	frequency = sgs.Skill_Frequent,
    events = {sgs.TargetConfirming, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and player:hasSkill(self) then
                if use.card:getSuit() == sgs.Card_Spade
                    and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("spade")) then
                    room:drawCards(player, 1, self:objectName())
                    room:addPlayerMark(player, "yuchuang", 1)
                end
                if use.card:getSuit() == sgs.Card_Club
                    and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("club:" .. use.from:objectName())) then
                    if not use.from:isNude() then
                        local card = room:askForCardChosen(player, use.from, "he", self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(card, use.from, player)
                    end
                end
                if use.card:getSuit() == sgs.Card_Heart
                    and room:askForSkillInvoke(player, self:objectName(),
                        sgs.QVariant("heart:" .. use.from:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                    room:addPlayerMark(player, "yuchuang", 1)
                    room:drawCards(use.from, 1, self:objectName())
                    room:addPlayerMark(use.from, "yuchuang", 1)
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAllPlayers(true)) do
                if p:getMark("yuchuang") ~= 0 then
                    room:setPlayerMark(p, "yuchuang", 0)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuayuchuangInvalidity = sgs.CreateInvaliditySkill {
    name = "#LuayuchuangInvalidity",
    skill_valid = function(self, player, skill)
        if player:getMark("yuchuang") >= 2 and skill:objectName() == "Luayuchuang" then
            return false
        else
            return true
        end
    end,
}
ManaTakase_HiraganaKeyakizaka:addSkill(Luayuchuang)
if not sgs.Sanguosha:getSkill("#LuayuchuangInvalidity") then
    SKMC.SkillList:append(LuayuchuangInvalidity)
end

sgs.LoadTranslationTable {
    ["ManaTakase_HiraganaKeyakizaka"] = "高瀬 愛奈",
    ["&ManaTakase_HiraganaKeyakizaka"] = "高瀬 愛奈",
    ["#ManaTakase_HiraganaKeyakizaka"] = "假名之窗",
    ["designer:ManaTakase_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:ManaTakase_HiraganaKeyakizaka"] = "高瀬 愛奈",
    ["illustrator:ManaTakase_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luayuchuang"] = "语窗",
    [":Luayuchuang"] = "当你成为黑桃牌的目标时，你可以摸一张牌；当你成为梅花牌的目标时，你可以弃置此牌使用者一张牌；当你成为红桃牌的目标时，你可以与此牌使用者各摸一张牌；当你一回合内以此法获得牌不少于两张时，此技能失效直到当前回合结束。",
    ["Luayuchuang:spade"] = "是否摸一张牌",
    ["Luayuchuang:club"] = "是否弃置%src一张牌",
    ["Luayuchuang:heart"] = "是否和%src各摸一张牌",
}
