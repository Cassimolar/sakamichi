require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HonoTamura_Keyakizaka = sgs.General(Sakamichi, "HonoTamura_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.NiKiSei.HonoTamura_Keyakizaka = true
SKMC.SeiMeiHanDan.HonoTamura_Keyakizaka = {
    name = {5, 7, 9, 2},
    ten_kaku = {12, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {11, "ji"},
    soto_kaku = {7, "ji"},
    sou_kaku = {23, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_jian_dan = sgs.CreateTriggerSkill {
    name = "sakamichi_jian_dan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.to:length() > 1 then
            local removed = room:askForPlayerChosen(player, use.to, self:objectName(),
                "@jian_dan_remove:::" .. use.card:objectName())
            use.to:removeOne(removed)
            data:setValue(use)
        end
        return false
    end,
}
HonoTamura_Keyakizaka:addSkill(sakamichi_jian_dan)

sakamichi_jiu_wo_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jiu_wo",
    filter_pattern = ".|.|.|jiuwo",
    expand_pile = "jiuwo",
    view_as = function(self, card)
        local analeptic = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
        analeptic:setSkillName(self:objectName())
        analeptic:addSubcard(card)
        return analeptic
    end,
    enabled_at_play = function(self, player)
        return player:getPile("jiuwo"):length() ~= 0 and sgs.Analeptic_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "analeptic")
    end,
}
sakamichi_jiu_wo = sgs.CreateTriggerSkill {
    name = "sakamichi_jiu_wo",
    view_as_skill = sakamichi_jiu_wo_view_as,
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and not damage.card:isKindOf("SkillCard") then
                room:addPlayerMark(player, "jiu_wo_damage", damage.damage)
            end
        else
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                if player:getMark("jiu_wo_damage") ~= 0 then
                    if player:getMark("jiu_wo_damage") >= SKMC.number_correction(player, 2) then
                        player:addToPile("jiuwo", room:drawCard(), true)
                    end
                    room:setPlayerMark(player, "jiu_wo_damage", 0)
                end
            end
        end
        return false
    end,
}
HonoTamura_Keyakizaka:addSkill(sakamichi_jiu_wo)

sakamichi_wei_xiao = sgs.CreateTriggerSkill {
    name = "sakamichi_wei_xiao",
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") then
            for _, p in sgs.qlist(use.to) do
                local card = room:askForCard(player, ".|.|.|hand",
                    "@wei_xiao_give:" .. p:objectName() .. "::" .. use.card:objectName(), data, sgs.Card_MethodNone, p,
                    false)
                if card then
                    room:obtainCard(p, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                        p:objectName(), self:objectName(), ""), false)
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, p:objectName())
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}
HonoTamura_Keyakizaka:addSkill(sakamichi_wei_xiao)

sgs.LoadTranslationTable {
    ["HonoTamura_Keyakizaka"] = "田村 保乃",
    ["&HonoTamura_Keyakizaka"] = "田村 保乃",
    ["#HonoTamura_Keyakizaka"] = "天真烂漫",
    ["~HonoTamura_Keyakizaka"] = "本当に欅坂46が大好きで。",
    ["designer:HonoTamura_Keyakizaka"] = "Cassimolar",
    ["cv:HonoTamura_Keyakizaka"] = "田村 保乃",
    ["illustrator:HonoTamura_Keyakizaka"] = "Cassimolar",
    ["sakamichi_jian_dan"] = "简单",
    [":sakamichi_jian_dan"] = "锁定技，当你使用牌时，若目标不唯一，你须取消其中一个目标。",
    ["@jian_dan_remove"] = "请选择【%arg】减少的目标",
    ["sakamichi_jiu_wo"] = "酒窝",
    [":sakamichi_jiu_wo"] = "当你使用的牌结算完成时，若此牌造成了至少2点伤害，你可以将牌堆顶的一张牌置于武将牌上称为「酒」，「酒」可以当【酒】使用或打出。",
    ["jiu_wo"] = "酒",
    ["sakamichi_wei_xiao"] = "微笑",
    [":sakamichi_wei_xiao"] = "当你使用牌指定目标后，你可以交给目标一张手牌，若如此做，其无法响应此牌。",
    ["@wei_xiao_give"] = "你可以交给%src一张手牌令其无法响应此【%arg】",
}
