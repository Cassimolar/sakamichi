require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AyameTsutsui = sgs.General(Sakamichi, "AyameTsutsui", "Nogizaka46", 3, false)
SKMC.YonKiSei.AyameTsutsui = true
SKMC.SeiMeiHanDan.AyameTsutsui = {
    name = {12, 4, 3, 3, 2},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {7, "ji"},
    ji_kaku = {8, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_la_meiCard = sgs.CreateSkillCard {
    name = "sakamichi_la_meiCard",
    skill_name = "sakamici_la_mei",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if sgs.Self:hasFlag("la_mei_recover") then
            return #targets < sgs.Self:getMark("la_mei_num") and to_select:isWounded()
        else
            return #targets < sgs.Self:getMark("la_mei_num")
        end
    end,
    on_effect = function(self, effect)
        if effect.from:hasFlag("la_mei_recover") then
            effect.from:getRoom():recover(effect.to,
                sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
        end
        if effect.from:hasFlag("la_mei_draw") then
            effect.from:getRoom():drawCards(effect.to, 1, self:getSkillName())
        end
    end,
}
sakamichi_la_mei_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_la_mei",
    view_as = function(self, cards)
        return sakamichi_la_meiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@sakamichi_la_mei"
    end,
}
sakamichi_la_mei = sgs.CreateTriggerSkill {
    name = "sakamichi_la_mei",
    view_as_skill = sakamichi_la_mei_view_as,
    events = {sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        room:setPlayerMark(player, "la_mei_num", damage.damage)
        if event == sgs.Damage then
            local can_trigger = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isWounded() then
                    can_trigger = true
                    break
                end
            end
            if can_trigger then
                room:setPlayerFlag(player, "la_mei_recover")
                room:askForUseCard(player, "@@sakamichi_la_mei", "@la_mei_recover:::" .. damage.damage)
                room:setPlayerFlag(player, "-la_mei_recover")
            end
        elseif event == sgs.Damaged then
            room:setPlayerFlag(player, "la_mei_draw")
            room:askForUseCard(player, "@@sakamichi_la_mei", "@la_mei_draw:::" .. damage.damage)
            room:setPlayerFlag(player, "-la_mei_draw")
        end
        room:setPlayerMark(player, "la_mei_num", 0)
        return false
    end,
}
AyameTsutsui:addSkill(sakamichi_la_mei)

sakamichi_chen_wen = sgs.CreateTriggerSkill {
    name = "sakamichi_chen_wen",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if player:hasSkill(self) and (use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack")) then
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if player:hasSkill(self) then
                    room:setPlayerFlag(player, "chen_wen")
                end
                local last_turn_handcards_num = player:getTag(self:objectName()):toInt()
                if last_turn_handcards_num == player:getHandcardNum() then
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        room:drawCards(p, 1, self:objectName())
                        room:drawCards(player, 1, self:objectName())
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish then
                player:setTag(self:objectName(), sgs.QVariant(player:getHandcardNum()))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_chen_wen_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_chen_wen_card_limit",
    frequency = sgs.Skill_Compulsory,
    limit_list = function(self, player)
        local can_trigger = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasSkill("sakamichi_chen_wen") and p:hasFlag("chen_wen") then
                can_trigger = true
                break
            end
        end
        if can_trigger then
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        local can_trigger = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasSkill("sakamichi_chen_wen") and p:hasFlag("chen_wen") then
                can_trigger = true
                break
            end
        end
        if can_trigger then
            return "Nullification"
        else
            return ""
        end
    end,
}
AyameTsutsui:addSkill(sakamichi_chen_wen)
if not sgs.Sanguosha:getSkill("#sakamichi_chen_wen_card_limit") then
    SKMC.SkillList:append(sakamichi_chen_wen_card_limit)
end

sgs.LoadTranslationTable {
    ["AyameTsutsui"] = "筒井 あやめ",
    ["&AyameTsutsui"] = "筒井 あやめ",
    ["#AyameTsutsui"] = "辣咩",
    ["~AyameTsutsui"] = "バーカ！",
    ["designer:AyameTsutsui"] = "Cassimolar",
    ["cv:AyameTsutsui"] = "筒井 あやめ",
    ["illustrator:AyameTsutsui"] = "Cassimolar",
    ["sakamichi_la_mei"] = "辣妹",
    [":sakamichi_la_mei"] = "当你造成伤害后，你可以令至多X名角色回复1点体力；当你受到伤害后，你可以令至多X名角色摸一张牌（X为伤害量）。。",
    ["@la_mei_recover"] = "你可以选择至多%arg名角色，令他们各回复1点体力",
    ["@la_mei_draw"] = "你可以选择至多%arg名角色，令他们各摸一张牌",
    ["sakamichi_chen_wen"] = "沉稳",
    [":sakamichi_chen_wen"] = "锁定技，【南蛮入侵】、【万箭齐发】对你无效。你的回合内其他角色无法使用【无懈可击】。一名角色准备阶段，若其手牌数与其上回合结束阶段相同，你与其各摸一张牌。",
}
