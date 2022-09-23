require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MemiKakizaki_HiraganaKeyakizaka = sgs.General(Sakamichi, "MemiKakizaki_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.IKiSei, "MemiKakizaki_HiraganaKeyakizaka")

--[[
    技能名：猫语
    描述：出牌阶段限一次，你可以进行一次判定，若结果为红桃，你可以选择一项：1.获得此牌；2.将此牌视为【乐不思蜀】使用。
]]
LuamaoyuCard = sgs.CreateSkillCard {
    name = "LuamaoyuCard",
    skill_name = "Luamaoyu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local judge = sgs.JudgeStruct()
        judge.pattern = ".|heart"
        judge.good = true
        judge.who = source
        judge.reason = "Luamaoyu"
        room:judge(judge)
        local suit = judge.card:getSuit()
        if suit == sgs.Card_Heart then
            local choices = {"maoyu_get"}
            local targets_list = sgs.SPlayerList()
            local card = sgs.Sanguosha:cloneCard("indulgence", suit, judge.card:getNumber())
            card:addSubcard(judge.card:getEffectiveId())
            card:setSkillName("Luamaoyu")
            for _, p in sgs.qlist(room:getOtherPlayers(source)) do
                if not p:containsTrick("indulgence") and not p:isProhibited(source, card) then
                    targets_list:append(p)
                end
            end
            if not targets_list:isEmpty() then
                table.insert(choices, "maoyu_use")
            end
            if room:askForChoice(source, "Luamaoyu", table.concat(choices, "+")) == "maoyu_get" then
                source:obtainCard(judge.card)
            else
                local target = room:askForPlayerChosen(source, targets_list, "Luamaoyu", "@maoyu_choice", false, true)
                room:useCard(sgs.CardUseStruct(card, source, target, true), true)
            end
        end
    end,
}
Luamaoyu = sgs.CreateZeroCardViewAsSkill {
    name = "Luamaoyu",
    view_as = function()
        return LuamaoyuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuamaoyuCard")
    end,
}
MemiKakizaki_HiraganaKeyakizaka:addSkill(Luamaoyu)

--[[
    技能名：萌王
    描述：锁定技，红桃【杀】对你无效；你使用红桃【杀】造成伤害时，此伤害+1；你使用红桃基本牌和通常锦囊牌时须额外选择一个合法目标。
]]
Luamengwang = sgs.CreateTriggerSkill {
    name = "Luamengwang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.SlashEffected, sgs.DamageCaused, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashEffected then
            local effect = data:toSlashEffect()
            return effect.slash:getSuit() == sgs.Card_Heart
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:getSuit() == sgs.Card_Heart then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        else
            local use = data:toCardUse()
            if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) and use.card:getSuit() == sgs.Card_Heart then
                if (sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY) then
                    return false
                end
                local available_targets = sgs.SPlayerList()
                if not use.card:isKindOf("AOE") and not use.card:isKindOf("GlobalEffect") then
                    room:setPlayerFlag(player, "wa_ga_michi_extra_target")
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not (use.to:contains(p) or room:isProhibited(player, p, use.card)) then
                            if (use.card:targetFixed()) then
                                if (not use.card:isKindOf("Peach")) or (p:isWounded()) then
                                    available_targets:append(p)
                                end
                            else
                                if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
                                    available_targets:append(p)
                                end
                            end
                        end
                    end
                    room:setPlayerFlag(player, "-wa_ga_michi_extra_target")
                end
                if not available_targets:isEmpty() then
                    local extra = nil
                    if not use.card:isKindOf("Collateral") then
                        extra = room:askForPlayerChosen(player, available_targets, self:objectName(),
                            "@wa_ga_michi_add:::" .. use.card:objectName())
                        local msg = sgs.LogMessage()
                        msg.type = "#wa_ga_michi_Add"
                        msg.from = player
                        msg.to:append(extra)
                        msg.card_str = use.card:toString()
                        msg.arg = self:objectName()
                        room:sendLog(msg)
                    else
                        local tos = {}
                        for _, t in sgs.qlist(use.to) do
                            table.insert(tos, t:objectName())
                        end
                        room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(use.card:toString()))
                        room:setPlayerProperty(player, "extra_collateral_current_targets",
                            sgs.QVariant(table.concat(tos, "+")))
                        room:askForUseCard(player, "@@ExtraCollateral", "@wa_ga_michi_add:::collateral")
                        room:setPlayerProperty(player, "extra_collateral", sgs.QVariant(""))
                        room:setPlayerProperty(player, "extra_collateral_current_targets", sgs.QVariant("+"))
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            if p:hasFlag("ExtraCollateralTarget") then
                                p:setFlags("-ExtraCollateralTarget")
                                extra = p
                                break
                            end
                        end
                    end
                    use.to:append(extra)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
            end
            data:setValue(use)
        end
        return false
    end,
}
MemiKakizaki_HiraganaKeyakizaka:addSkill(Luamengwang)

sgs.LoadTranslationTable {
    ["MemiKakizaki_HiraganaKeyakizaka"] = "柿崎 芽実",
    ["&MemiKakizaki_HiraganaKeyakizaka"] = "柿崎 芽実",
    ["#MemiKakizaki_HiraganaKeyakizaka"] = "高跳的人偶",
    ["designer:MemiKakizaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MemiKakizaki_HiraganaKeyakizaka"] = "柿崎 芽実",
    ["illustrator:MemiKakizaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luamaoyu"] = "猫语",
    [":Luamaoyu"] = "出牌阶段限一次，你可以进行一次判定，若结果为红桃，你可以选择一项：1.获得此牌；2.将此牌视为【乐不思蜀】使用。",
    ["maoyu_use"] = "将此牌视为【乐不思蜀】使用",
    ["@maoyu_choice"] = "请选择一名角色成为此【乐不思蜀】的目标",
    ["maoyu_get"] = "获得此牌",
    ["Luamengwang"] = "萌王",
    [":Luamengwang"] = "锁定技，红桃【杀】对你无效；你使用红桃【杀】造成伤害时，此伤害+1；你使用红桃基本牌和通常锦囊牌时须额外选择一个合法目标。",
}
