require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MikotoShiina = sgs.General(Zambi, "MikotoShiina", "Zambi", 3, false)
table.insert(SKMC.SanKiSei, "MikotoShiina")

--[[
    技能名：漫画
    描述：当你成为黑色锦囊牌的目标时，你可以进行一次判定，若结果小于8，则此牌对你无效。
]]
Luamanga = sgs.CreateTriggerSkill {
    name = "Luamanga",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card:isKindOf("TrickCard") and use.card:isBlack() and use.to:contains(player) then
                local judge = sgs.JudgeStruct()
                judge.pattern = ".|.|1~7"
                judge.good = true
                judge.reason = self:objectName()
                judge.who = player
                room:judge(judge)
                if judge:isGood() then
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, player:objectName())
                    use.nullified_list = nullified_list
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}
MikotoShiina:addSkill(Luamanga)

--[[
    技能名：挚友
    描述：当其他角色的判定牌生效前，其可以交给你一张手牌，若如此做，你令其展示牌堆顶的两张牌并可以选择其中的一张代替之。
]]
Luabestfriend = sgs.CreateTriggerSkill {
    name = "Luabestfriend",
    events = {sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.who:objectName() == player:objectName() then
            local source = room:findPlayersBySkillName(self:objectName())
            if not source:isEmpty() then
                local target
                if source:length() == 1 then
                    target = room:askForPlayerChosen(player, source, self:objectName(), "@bestfriend_choice", false,
                        true)
                else
                    target =
                        room:askForPlayerChosen(player, source, self:objectName(), "@bestfriend_choice", true, true)
                end
                if target then
                    local card = room:askForCard(player, ".", "@bestfriend_give:" .. target:objectName(), data,
                        sgs.Card_MethodNone, target, false)
                    if card then
                        target:obtainCard(card)
                        local ids = room:getNCards(2)
                        room:fillAG(ids)
                        local id = room:askForAG(player, ids, true, self:objectName())
                        room:clearAG()
                        if id ~= -1 then
                            room:retrial(sgs.Sanguosha:getCard(id), player, judge, self:objectName(), false)
                        end
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
MikotoShiina:addSkill(Luabestfriend)

sgs.LoadTranslationTable {
    ["MikotoShiina"] = "椎名 美琴",
    ["&MikotoShiina"] = "椎名 美琴",
    ["#MikotoShiina"] = "鉾鈴は最強？",
    ["designer:MikotoShiina"] = "Cassimolar",
    ["cv:MikotoShiina"] = "中村 麗乃",
    ["illustrator:MikotoShiina"] = "Cassimolar",
    ["Luamanga"] = "漫画",
    [":Luamanga"] = "当你成为黑色锦囊牌的目标时，你可以进行一次判定，若结果小于8，则此牌对你无效。",
    ["Luabestfriend"] = "挚友",
    [":Luabestfriend"] = "当其他角色的判定牌生效前，其可以交给你一张手牌，若如此做，你令其展示牌堆顶的两张牌并可以选择其中的一张代替之。",
    ["@bestfriend_choice"] = "你可以选择一名角色发动其的【挚友】",
    ["@bestfriend_give"] = "你可以交给%src一张手牌发动其的【挚友】",
}
