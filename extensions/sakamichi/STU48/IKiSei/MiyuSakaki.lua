require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MiyuSakaki = sgs.General(STU48, "MiyuSakaki", "STU48", 3, false)
table.insert(SKMC.IKiSei, "MiyuSakaki")

--[[
    技能名：过食
    描述：当一名角色的判定牌生效前，其可以令你获得此牌，然后你可以选择将一张手牌置于牌堆顶，然后其翻开牌堆顶的一张牌代替之。
]]
Luaguoshi = sgs.CreateTriggerSkill {
    name = "Luaguoshi",
    events = {sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.who:objectName() == player:objectName() then
            local targets = room:findPlayersBySkillName(self:objectName())
            local cd = judge.card
            if targets:length() == 1 then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("guoshi_1")) then
                    targets:first():obtainCard(cd)
                    local card = room:askForCard(targets:first(), ".|.|.|hand", "@guoshi_top", data,
                        sgs.Card_MethodNone, nil, false, self:objectName(), false)
                    if card then
                        room:moveCardsInToDrawpile(targets:first(), card, self:objectName(), 1, false)
                    end
                    local id = room:getNCards(1):first()
                    if id ~= -1 then
                        judge.card = sgs.Sanguosha:getCard(id)
                        room:retrial(sgs.Sanguosha:getCard(id), player, judge, self:objectName(), false)
                        data:setValue(judge)
                    end
                end
            elseif targets:length() > 1 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(),
                    "@guoshi_2:::" .. cd:objectName(), true, false)
                if target then
                    target:obtainCard(cd)
                    local card = room:askForCard(target, ".|.|.|hand", "@guoshi_top", data, sgs.Card_MethodNone, nil,
                        false, self:objectName(), false)
                    if card then
                        room:moveCardsInToDrawpile(target, card, self:objectName(), 1, false)
                    end
                    local id = room:getNCards(1):first()
                    if id ~= -1 then
                        judge.card = sgs.Sanguosha:getCard(id)
                        room:retrial(sgs.Sanguosha:getCard(id), player, judge, self:objectName(), false)
                        data:setValue(judge)
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
MiyuSakaki:addSkill(Luaguoshi)

--[[
    技能名：博主
    描述：出牌阶段限一次，你可以进行一次判定，在此判定牌生效后你可以令一名角色获得之并令其选择：本回合内，你对其使用与此判定牌颜色相同的牌无距离和次数限制；本回合内，你使用与此判定牌颜色不同的牌时其不是合法目标且你摸一张牌。
]]
LuabozhuCard = sgs.CreateSkillCard {
    name = "LuabozhuCard",
    skill_name = "Luabozhu",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local judge = sgs.JudgeStruct()
        judge.pattern = "."
        judge.good = true
        judge.who = source
        judge.reason = "Luabozhu"
        room:judge(judge)
        local red, black = judge.card:isRed(), judge.card:isBlack()
        local target = room:askForPlayerChosen(source, room:getAlivePlayers(), "Luabozhu",
            "@bozhu_choice:::" .. judge.card:objectName(), false, true)
        target:obtainCard(judge.card)
        if room:askForChoice(target, self:objectName(), "bozhu1+bozhu2") == "bozhu1" then
            room:setPlayerFlag(source, "bozhu1_" .. target:objectName())
        else
            room:setPlayerFlag(source, "bozhu2")
            room:setPlayerFlag(source, "bozhu2_" .. target:objectName())
        end
        if red then
            room:setPlayerFlag(source, "bozhu_red")
        end
        if black then
            room:setPlayerFlag(source, "bozhu_black")
        end
    end,
}
LuabozhuVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luabozhu",
    view_as = function(self)
        return LuabozhuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuabozhuCard")
    end,
}
Luabozhu = sgs.CreateTriggerSkill {
    name = "Luabozhu",
    view_as_skill = LuabozhuVS,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if player:hasFlag("bozhu2") and not use.card:isKindOf("SkillCard") then
            if (not use.card:isRed() and player:hasFlag("bozhu_red"))
                or (not use.card:isBlack() and player:hasFlag("bozhu_black")) then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
LuabozhuMod = sgs.CreateTargetModSkill {
    name = "#LuabozhuMod",
    pattern = ".",
    residue_func = function(self, from, card, to)
        local n = 0
        if not card:isKindOf("SkillCard")
            and ((card:isRed() and from:hasFlag("bozhu_red")) or (card:isBlack() and from:hasFlag("bozhu_black"))) and to
            and from:hasFlag("bozhu1_" .. to:objectName()) then
            n = n + 1000
        end
        return n
    end,
    distance_limit_func = function(self, from, card, to)
        local n = 0
        if not card:isKindOf("SkillCard")
            and ((card:isRed() and from:hasFlag("bozhu_red")) or (card:isBlack() and from:hasFlag("bozhu_black"))) and to
            and from:hasFlag("bozhu1_" .. to:objectName()) then
            n = n + 1000
        end
        return n
    end,
}
LuabozhuProtect = sgs.CreateProhibitSkill {
    name = "#LuabozhuProtect",
    is_prohibited = function(self, from, to, card)
        return not card:isKindOf("SkillCard")
                   and ((not card:isRed() and from:hasFlag("bozhu_red"))
                       or (not card:isBlack() and from:hasFlag("bozhu_black"))) and to
                   and from:hasFlag("bozhu2_" .. to:objectName())
    end,
}
MiyuSakaki:addSkill(Luabozhu)
if not sgs.Sanguosha:getSkill("#LuabozhuMod") then
    SKMC.SkillList:append(LuabozhuMod)
end
if not sgs.Sanguosha:getSkill("#LuabozhuProtect") then
    SKMC.SkillList:append(LuabozhuProtect)
end

sgs.LoadTranslationTable {
    ["MiyuSakaki"] = "榊 美優",
    ["&MiyuSakaki"] = "榊 美優",
    ["#MiyuSakaki"] = "CUCA",
    ["designer:MiyuSakaki"] = "Cassimolar",
    ["cv:MiyuSakaki"] = "榊 美優",
    ["illustrator:MiyuSakaki"] = "Cassimolar",
    ["Luaguoshi"] = "过食",
    [":Luaguoshi"] = "当一名角色的判定牌生效前，其可以令你获得此牌，然后你可以选择将一张手牌置于牌堆顶，然后其翻开牌堆顶的一张牌代替之。",
    ["Luaguoshi:guoshi_1"] = "你可以令【过食】拥有者获得此判定牌",
    ["@guoshi_2"] = "你可以选择一名【过食】拥有者令其获得此判定牌%arg",
    ["@guoshi_top"] = "你可以将一张手牌置于牌堆顶",
    ["Luabozhu"] = "博主",
    [":Luabozhu"] = "出牌阶段限一次，你可以进行一次判定，在此判定牌生效后你可以令一名角色获得之并令其选择：本回合内，你对其使用与此判定牌颜色相同的牌无距离和次数限制；本回合内，你使用与此判定牌颜色不同的牌时其不是合法目标且你摸一张牌。",
    ["@bozhu_choice"] = "选择一名角色令其获得此判定牌%arg",
    ["bozhu1"] = "本回合内，其对你使用与此判定牌颜色相同的牌无距离和次数限制",
    ["bozhu2"] = "本回合内，其使用与此判定牌颜色不同的牌时你不是合法目标且其摸一张牌",
}
