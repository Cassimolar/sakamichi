require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinakoKitano = sgs.General(Sakamichi, "HinakoKitano", "Nogizaka46", 4, false)
SKMC.NiKiSei.HinakoKitano = true
SKMC.SeiMeiHanDan.HinakoKitano = {
    name = {5, 11, 4, 8, 3},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

sakamichi_guai_li = sgs.CreateTriggerSkill {
    name = "sakamichi_guai_li",
    events = {sgs.DrawNCards, sgs.EventPhaseChanging, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then
            local count = data:toInt()
            if room:askForSkillInvoke(player, self:objectName(), data) then
                count = count + 1
                room:setPlayerFlag(player, self:objectName())
                room:setPlayerMark(player, self:objectName(), 1)
                data:setValue(count)
                SKMC.send_message(room, "#guai_li_draw", player)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw)
                and player:getMark(self:objectName()) ~= 0 then
                SKMC.send_message(room, "#guai_li_skip", player, nil, nil, nil, self:objectName())
                player:skip(sgs.Player_Draw)
                room:setPlayerMark(player, self:objectName(), 0)
            end
        elseif event == sgs.DamageCaused and player:hasFlag(self:objectName()) then
            local damage = data:toDamage()
            if damage.chain or damage.transfer or (not damage.by_user) then
                return false
            end
            local reason = damage.card
            if reason and (reason:isKindOf("Slash") or reason:isKindOf("Duel")) then
                local n = SKMC.number_correction(player, 1)
                SKMC.send_message(room, "#guai_li_damage", player, damage.to, nil, nil, self:objectName(), n,
                    damage.damage)
                damage.damage = damage.damage + n
                data:setValue(damage)
            end
            return false
        end
    end,
}
HinakoKitano:addSkill(sakamichi_guai_li)

sakamichi_si_guo_card = sgs.CreateSkillCard {
    name = "sakamichi_si_guoCard",
    skill_name = "sakamichi_si_guo",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@si_guo")
        if source:hasEquipArea(0) then
            source:throwEquipArea(0)
            local choices = {"si_guo_1", "si_guo_2", "si_guo_3", "si_guo_4", "si_guo_5", "si_guo_6"}
            local choice1 = room:askForChoice(source, self:getSkillName(), table.concat(choices, "+"))
            table.removeOne(choices, choice1)
            table.insert(choices, "cancel")
            local choice2 = room:askForChoice(source, self:getSkillName(), table.concat(choices, "+"))
            if choice2 ~= "cancel" then
                SKMC.send_message(room, "#si_guo_choice_2", source, nil, nil, nil, choice1, choice2)
                room:setPlayerFlag(source, choice1)
                room:setPlayerFlag(source, choice2)
            else
                SKMC.send_message(room, "#si_guo_choice", source, nil, nil, nil, choice1)
                room:setPlayerMark(source, choice1, 1)
            end
        end
    end,
}
sakamichi_si_guo_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_si_guo",
    filter_pattern = "Weapon",
    view_as = function(self, card)
        local cd = sakamichi_si_guo_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@si_guo") ~= 0
    end,
}
sakamichi_si_guo = sgs.CreateTriggerSkill {
    name = "sakamichi_si_guo",
    frequency = sgs.Skill_Limited,
    limit_mark = "@si_guo",
    view_as_skill = sakamichi_si_guo_view_as,
    events = {sgs.CardUsed, sgs.DamageCaused, sgs.SlashProceed, sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and (player:hasFlag("si_guo_3") or player:getMark("si_guo_3") ~= 0) then
                room:setCardFlag(use.card, "SlashIgnoreArmor")
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash")
                and (player:hasFlag("si_guo_4") or player:getMark("si_guo_4") ~= 0) then
                damage.damage = damage.damage + SKMC.number_correction(player, 1)
                data:setValue(damage)
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasFlag("si_guo_5") or effect.from:getMark("si_guo_5") ~= 0 then
                room:slashResult(effect, nil)
                return true
            end
        else
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and (player:hasFlag("si_guo_6") or player:getMark("si_guo_6") ~= 0) then
                for _, p in sgs.qlist(use.to) do
                    if not p:isNude() then
                        local id = room:askForCardChosen(use.from, use.to, "he", self:objectName(), false,
                            sgs.Card_MethodDiscard, sgs.IntList(), true)
                        if id ~= -1 then
                            room:throwCard(id, p, player)
                        else
                            room:drawCards(player, 1, self:objectName())
                        end
                    else
                        room:drawCards(player, 1, self:objectName())
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_si_guo_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_si_guo_target_mod",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasFlag("si_guo_2") or from:getMark("si_guo_2") ~= 0 then
            return 1000
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasFlag("si_guo_1") or from:getMark("si_guo_1") ~= 0 then
            return 1000
        else
            return 0
        end
    end,
}
HinakoKitano:addSkill(sakamichi_si_guo)
if not sgs.Sanguosha:getSkill("#sakamichi_si_guo_target_mod") then
    SKMC.SkillList:append(sakamichi_si_guo_target_mod)
end

sgs.LoadTranslationTable {
    ["HinakoKitano"] = "北野 日奈子",
    ["&HinakoKitano"] = "北野 日奈子",
    ["#HinakoKitano"] = "爆彈少女",
    ["~HinakoKitano"] = "うざい！ちね！",
    ["designer:HinakoKitano"] = "Cassimolar",
    ["cv:HinakoKitano"] = "北野 日奈子",
    ["illustrator:HinakoKitano"] = "Cassimolar",
    ["sakamichi_guai_li"] = "怪力",
    [":sakamichi_guai_li"] = "摸牌阶段，你可以多摸一张牌，本回合内你使用的【杀】和【决斗】造成伤害时，伤害+1，若如此做，跳过你的下一个摸牌阶段。",
    ["#guai_li_draw"] = "本回合内 %from 使用的【杀】和【决斗】（ %from 为伤害来源时）造成的伤害+<font color=\"yellow\"><b>1</b></font>",
    ["#guai_li_skip"] = "%from 的【%arg】被触发",
    ["#guai_li_damage"] = "%from 的【%arg】被触发，%to 此次受到的伤害+<font color=\"yellow\"><b>%arg2</b></font>, 此次伤害为<font color=\"yellow\"><b>%arg3</b></font>点",
    ["sakamichi_si_guo"] = "撕锅",
    [":sakamichi_si_guo"] = "限定技，出牌阶段，若你有武器栏，你可以弃置一张武器牌并废除武器栏然后选择，使用【杀】：无距离限制；无次数限制；无视防具；造成的伤害+1；无法闪避；指定目标时可以弃置其一张牌或摸一张牌。选择一个效果于本局游戏剩余时间内生效或选择两个效果本回合内生效。",
    ["si_guo_1"] = "使用【杀】无距离限制",
    ["si_guo_2"] = "使用【杀】无次数限制",
    ["si_guo_3"] = "使用【杀】无视防具",
    ["si_guo_4"] = "使用【杀】造成的伤害+1",
    ["si_guo_5"] = "使用【杀】无法闪避",
    ["si_guo_6"] = "使用【杀】指定目标后弃置其一张牌或摸一张牌",
    ["#si_guo_choice_1"] = "%from选择了本局游戏剩余时间内%arg",
    ["#si_guo_choice_2"] = "%from选择了本回合内%arg和%arg2",
}
