require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SarinaUshio_Hinatazaka = sgs.General(Sakamichi, "SarinaUshio_Hinatazaka", "Hinatazaka46", 3, false)
table.insert(SKMC.IKiSei, "SarinaUshio_Hinatazaka")

--[[
    技能名：道具
    描述：出牌阶段限一次，若你“道具”里的牌少于八张，你可以将一张手牌置于你的武将牌旁称为“道具”；“道具”可以视为手牌使用或打出；其他角色受到伤害后，你可以将一张“道具”交给其；锁定技，若你的“道具”数大于你的手牌数，你的手牌上限为0。
]]
LuadaojuCard = sgs.CreateSkillCard {
    name = "LuadaojuCard",
    skill_name = "Luadaoju",
    target_fixed = true,
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    on_use = function(self, room, source, targets)
        source:addToPile("&daoju", self)
    end,
}
LuadaojuVS = sgs.CreateOneCardViewAsSkill {
    name = "Luadaoju",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skillcard = LuadaojuCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return
            player:getPile("&daoju"):length() < 8 and not player:isKongcheng() and not player:hasUsed("#LuadaojuCard")
    end,
}
Luadaoju = sgs.CreateTriggerSkill {
    name = "Luadaoju",
    view_as_skill = LuadaojuVS,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:hasSkill(self) and not p:getPile("&daoju"):isEmpty()
                and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("give:" .. player:objectName())) then
                local card_ids = p:getPile("&daoju")
                room:fillAG(card_ids, p)
                local card_id = room:askForAG(p, card_ids, false, self:objectName())
                if card_id ~= -1 then
                    room:obtainCard(player, sgs.Sanguosha:getCard(card_id), sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(), ""),
                        false)
                end
                room:clearAG(p)
                --			local card = room:askForCard(p, ".|.|.|%&daoju", "@daoju_give:"..player:objectName(), data, sgs.Card_MethodNone)
                --			if card then
                --				player:obtainCard(card)
                --			end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuadaojuMax = sgs.CreateMaxCardsSkill {
    name = "#LuadaojuMax",
    fixed_func = function(self, target)
        if target:hasSkill("Luadaoju") and target:getPile("&daoju"):length() > target:getHandcardNum() then
            return 0
        end
        return -1
    end,
}
SarinaUshio_Hinatazaka:addSkill(Luadaoju)
if not sgs.Sanguosha:getSkill("#LuadaojuMax") then
    SKMC.SkillList:append(LuadaojuMax)
end

--[[
    技能名：销售
    描述：其他角色的判定牌生效前，其可以交给你一张手牌，然后你可以打出一张牌代替之。
]]
Luaxiaoshou = sgs.CreateTriggerSkill {
    name = "Luaxiaoshou",
    events = {sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.who:objectName() == player:objectName() then
            local source = room:findPlayersBySkillName(self:objectName())
            if not source:isEmpty() then
                local target
                if source:length() == 1 then
                    target = room:askForPlayerChosen(player, source, self:objectName(), "@xiaoshou_choice", false, true)
                else
                    target = room:askForPlayerChosen(player, source, self:objectName(), "@xiaoshou_choice", true, true)
                end
                if target then
                    local card = room:askForCard(player, ".", "@xiaoshou_give:" .. target:objectName(), data,
                        sgs.Card_MethodNone, target, false)
                    if card then
                        target:obtainCard(card)
                        local prompt_list = {"@xiaoshou-card", judge.who:objectName(), self:objectName(), judge.reason,
                            string.format("%d", judge.card:getEffectiveId())}
                        local prompt = table.concat(prompt_list, ":")
                        local card =
                            room:askForCard(target, ".", prompt, data, sgs.Card_MethodResponse, judge.who, true)
                        if card then
                            room:retrial(card, target, judge, self:objectName(), false)
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
SarinaUshio_Hinatazaka:addSkill(Luaxiaoshou)

sgs.LoadTranslationTable {
    ["SarinaUshio_Hinatazaka"] = "潮 紗理菜",
    ["&SarinaUshio_Hinatazaka"] = "潮 紗理菜",
    ["#SarinaUshio_Hinatazaka"] = "印尼神婆",
    ["designer:SarinaUshio_Hinatazaka"] = "Cassimolar",
    ["cv:SarinaUshio_Hinatazaka"] = "潮 紗理菜",
    ["illustrator:SarinaUshio_Hinatazaka"] = "Cassimolar",
    ["Luadaoju"] = "道具",
    [":Luadaoju"] = "出牌阶段限一次，若你“道具”里的牌少于八张，你可以将一张手牌置于你的武将牌旁称为“道具”；“道具”可以视为手牌使用或打出；其他角色受到伤害后，你可以将一张“道具”交给其；锁定技，若你的“道具”数大于你的手牌数，你的手牌上限为0。",
    ["&daoju"] = "道具",
    ["Luadaoju:give"] = "是否将一张“道具”交给%src",
    ["Luaxiaoshou"] = "销售",
    [":Luaxiaoshou"] = "其他角色的判定牌生效前，其可以交给你一张手牌，然后你可以打出一张牌代替之。",
    ["@xiaoshou_choice"] = "你可以选择一名角色发动其的【销售】",
    ["@xiaoshou_give"] = "你可以交给%src一张手牌发动其的【销售】",
    ["@xiaoshou-card"] = "请使用【%dest】来修改 %src 的 %arg 判定",
}
