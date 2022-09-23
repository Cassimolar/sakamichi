require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HonokaYamamoto = sgs.General(Sakamichi, "HonokaYamamoto", "Nogizaka46", 3, false)
SKMC.IKiSei.HonokaYamamoto = true
SKMC.SeiMeiHanDan.HonokaYamamoto = {
    name = {3, 5, 15, 2, 9},
    ten_kaku = {8, "ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {26, "xiong"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {34, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "shui",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zheng_xian = sgs.CreateTriggerSkill {
    name = "sakamichi_zheng_xian",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.TurnStart},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:objectName() ~= player:objectName() and p:faceUp()
                and room:askForSkillInvoke(p, self:objectName(), data) then
                p:turnOver()
                local tag = room:getTag("zheng_xian")
                if tag then
                    local pl = tag:toPlayer()
                    if not pl then
                        tag:setValue(player)
                        room:setTag("zheng_xian", tag)
                        room:addPlayerMark(player, "@zheng_xian")
                    end
                end
                room:setCurrent(p)
                p:play()
                return true
            end
        end
        local tag = room:getTag("zheng_xian")
        if tag then
            local p = tag:toPlayer()
            if p and not player:hasFlag("isExtraTurn") then
                room:removePlayerMark(p, "@zheng_xian")
                room:setCurrent(p)
                room:setTag("zheng_xian", sgs.QVariant())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HonokaYamamoto:addSkill(sakamichi_zheng_xian)

sakamichi_kang_zheng_card = sgs.CreateSkillCard {
    name = "sakamichi_kang_zhengCard",
    skill_name = "sakamichi_kang_zheng",
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:canSlash(to_select, nil, false)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:turnOver()
        local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        card:deleteLater()
        card:setSkillName(self:getSkillName())
        room:useCard(sgs.CardUseStruct(card, effect.from, effect.to))
    end,
}
sakamichi_kang_zheng_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_kang_zheng",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_kang_zheng_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_kang_zheng")
    end,
}
sakamichi_kang_zheng = sgs.CreateTriggerSkill {
    name = "sakamichi_kang_zheng",
    view_as_skill = sakamichi_kang_zheng_view_as,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if not player:faceUp() and not player:isKongcheng() then
            room:askForUseCard(player, "@@sakamichi_kang_zheng", "@kang_zheng_invoke", -1, sgs.Card_MethodDiscard, false)
        end
    end,
}
HonokaYamamoto:addSkill(sakamichi_kang_zheng)

sgs.LoadTranslationTable {
    ["HonokaYamamoto"] = "山本 穂乃香",
    ["&HonokaYamamoto"] = "山本 穂乃香",
    ["#HonokaYamamoto"] = "童星陨落",
    ["~HonokaYamamoto"] = "",
    ["designer:HonokaYamamoto"] = "Cassimolar",
    ["cv:HonokaYamamoto"] = "山本 穂乃香",
    ["illustrator:HonokaYamamoto"] = "Cassimolar",
    ["sakamichi_zheng_xian"] = "争先",
    [":sakamichi_zheng_xian"] = "其他角色的回合开始前，若你的武将牌正面向上，你可以翻面并执行一个额外的回合，此回合结束后，进入该角色的回合。",
    ["@zhenxian"] = "争先",
    ["sakamichi_kang_zheng"] = "抗争",
    [":sakamichi_kang_zheng"] = "当你的武将牌背面向上时受到伤害后，你可以翻面并弃置一张手牌视为对一名其他角色使用一张【杀】。",
    ["@kang_zheng_invoke"] = "你可以弃置一张手牌视为对一名其他角色使用一张【杀】",
    ["~sakamichi_kang_zheng"] = "选择一张手牌 → 选择一名其他角色 → 点击确定",
}
