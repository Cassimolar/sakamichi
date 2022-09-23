require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

TamamiSakaguchi = sgs.General(Sakamichi, "TamamiSakaguchi", "Nogizaka46", 4, false)
SKMC.SanKiSei.TamamiSakaguchi = true
SKMC.SeiMeiHanDan.TamamiSakaguchi = {
    name = {7, 3, 10, 9},
    ten_kaku = {10, "xiong"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {19, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_wu_wei_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_wu_wei",
    response_pattern = "slash",
    filter_pattern = "Jink|.|.|hand",
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:addSubcard(card)
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
}
sakamichi_wu_wei = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_wei",
    events = {sgs.CardUsed},
    view_as_skill = sakamichi_wu_wei_view_as,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Slash") and use.card:getSkillName() == self:objectName() then
                room:setCardFlag(use.card, "SlashIgnoreArmor")
            end
        end
        return false
    end,
}
sakamichi_wu_wei_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_wu_wei_target_mod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_wu_wei") and card:getSkillName() == "sakamichi_wu_wei" then
            return 1000
        else
            return 0
        end
    end,
}
TamamiSakaguchi:addSkill(sakamichi_wu_wei)
if not sgs.Sanguosha:getSkill("#sakamichi_wu_wei_target_mod") then
    SKMC.SkillList:append(sakamichi_wu_wei_target_mod)
end

sakamichi_gen_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_gen_xing",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying_data = data:toDying()
        local source = dying_data.who
        if source:objectName() == player:objectName() then
            if player:askForSkillInvoke(self:objectName(), data) then
                local result = SKMC.run_judge(room, player, self:objectName(), "BasicCard")
                if result.isGood then
                    room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                end
            end
        end
    end,
}
TamamiSakaguchi:addSkill(sakamichi_gen_xing)

sakamichi_tou_ming = sgs.CreateTriggerSkill {
    name = "sakamichi_tou_ming",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.to:length() ~= 1 and use.from and use.from:objectName()
            ~= player:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            local nullified_list = use.nullified_list
            table.insert(nullified_list, player:objectName())
            use.nullified_list = nullified_list
            data:setValue(use)
        end
        return false
    end,
}
TamamiSakaguchi:addSkill(sakamichi_tou_ming)

sgs.LoadTranslationTable {
    ["TamamiSakaguchi"] = "阪口 珠美",
    ["&TamamiSakaguchi"] = "阪口 珠美",
    ["#TamamiSakaguchi"] = "有勇无谋",
    ["~TamamiSakaguchi"] = "根性だけは負けません!",
    ["designer:TamamiSakaguchi"] = "Cassimolar",
    ["cv:TamamiSakaguchi"] = "阪口 珠美",
    ["illustrator:TamamiSakaguchi"] = "Cassimolar",
    ["sakamichi_wu_wei"] = "无畏",
    [":sakamichi_wu_wei"] = "你可以将一张【闪】当【杀】使用或打出，你以此法使用的【杀】无距离限制且无视防具。",
    ["sakamichi_gen_xing"] = "根性",
    [":sakamichi_gen_xing"] = "当你进入濒死时，你可以判定，若结果为基本牌，你回复1点体力。",
    ["sakamichi_tou_ming"] = "透明",
    [":sakamichi_tou_ming"] = "锁定技，当你成为其他角色使用牌的目标时，若此牌目标不唯一，则此牌对你无效。",
}
