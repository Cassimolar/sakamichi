require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YunaShibata = sgs.General(Sakamichi, "YunaShibata", "Nogizaka46", 3, false)
SKMC.YonKiSei.YunaShibata = true
SKMC.SeiMeiHanDan.YunaShibata = {
    name = {10, 5, 9, 11},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {21, "ji"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_ti_cao = sgs.CreateTriggerSkill {
    name = "sakamichi_ti_cao",
    change_skill = true,
    frequency = sgs.Skill_Frequent,
    events = {sgs.SlashHit, sgs.PreCardUsed, sgs.SlashMissed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            if effect.from and effect.from:objectName() == player:objectName() and player:hasSkill(self)
                and room:getChangeSkillState(player, self:objectName()) == 1
                and room:askForSkillInvoke(player, self:objectName(), data) then
                room:setPlayerMark(player, "ti_cao_" .. effect.to:objectName(), 1)
                SKMC.send_message(room, "#ti_cao_hit", player, effect.to, nil, effect.slash:toString())
                room:setChangeSkillState(player, self:objectName(), 2)
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                if player:hasSkill(self) then
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if player:getMark("ti_cao_" .. p:objectName()) ~= 0 then
                            room:setPlayerMark(player, "ti_cao_" .. p:objectName(), 0)
                            SKMC.send_message(room, "#ti_cao_append", player, p, nil, use.card:toString(),
                                self:objectName())
                            use.to:append(p)
                        end
                    end
                end
                for _, p in sgs.qlist(use.to) do
                    local nullified_list = use.nullified_list
                    if player:getMark(p:objectName() .. "_ti_cao") ~= 0 then
                        room:setPlayerMark(player, p:objectName() .. "_ti_cao", 0)
                        table.insert(nullified_list, p:objectName())
                        use.nullified_list = nullified_list
                    end
                end
                data:setValue(use)
            end
        elseif event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if effect.from and effect.from:objectName() == player:objectName() and effect.to:hasSkill(self)
                and room:getChangeSkillState(effect.to, self:objectName()) == 2
                and room:askForSkillInvoke(effect.to, self:objectName(), data) then
                room:setPlayerMark(player, effect.to:objectName() .. "_ti_cao", 1)
                SKMC.send_message(room, "#ti_cao_miss", effect.to, player, nil, effect.slash:toString())
                room:setChangeSkillState(effect.to, self:objectName(), 1)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YunaShibata:addSkill(sakamichi_ti_cao)

sakamichi_ni_ai_card = sgs.CreateSkillCard {
    name = "sakamichi_ni_aiCard",
    skill_name = "sakamichi_ni_ai",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            for _, skill in sgs.qlist(to_select:getVisibleSkillList()) do
                if skill:isChangeSkill() then
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        for _, skill in sgs.qlist(effect.to:getVisibleSkillList()) do
            if skill:isChangeSkill() then
                SKMC.send_message(room, "#ni_ai_change", effect.from, effect.to, nil, nil, self:getSkillName(),
                    skill:objectName())
                room:setChangeSkillState(effect.to, skill:objectName(), 1)
            end
        end
    end,
}
sakamichi_ni_ai_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ni_ai",
    view_as = function(self, card)
        return sakamichi_ni_ai_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_ni_aiCard")
    end,
}
sakamichi_ni_ai = sgs.CreateTriggerSkill {
    name = "sakamichi_ni_ai",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ni_ai",
    view_as_skill = sakamichi_ni_ai_view_as,
    events = {sgs.EventPhaseProceeding, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Finish and player:hasSkill(self) and player:getMark("@ni_ai") ~= 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@ni_ai_invoke:::" .. self:objectName(), true, true)
                if target then
                    room:removePlayerMark(player, "@ni_ai")
                    if not target:faceUp() then
                        target:turnOver()
                    end
                    room:setPlayerChained(target, false)
                    if target:getHp() ~= player:getHp() then
                        if target:getMaxHp() < player:getHp() then
                            room:setPlayerProperty(target, "maxhp", sgs.QVariant(player:getHp()))
                        end
                        room:setPlayerProperty(target, "hp", sgs.QVariant(player:getHp()))
                    end
                    if target:getHandcardNum() ~= player:getHandcardNum() then
                        if target:getHandcardNum() < player:getHandcardNum() then
                            target:drawCards(player:getHandcardNum() - target:getHandcardNum())
                        else
                            local n = target:getHandcardNum() - player:getHandcardNum()
                            room:askForDiscard(target, self:objectName(), n, n, false, false, "@ni_ai:::" .. n, ".",
                                self:objectName())
                        end
                    end
                    room:setPlayerMark(target, player:objectName() .. "_ni_ai_" .. target:objectName(), 1)
                end
            end
            if player:getPhase() == sgs.Player_Start then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:getMark(player:objectName() .. "_ni_ai_" .. p:objectName()) ~= 0 then
                        room:setPlayerMark(p, player:objectName() .. "_ni_ai_" .. p:objectName(), 0)
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() == player:objectName() then
                local can_trigger = false
                for _, mark in sgs.list(damage.to:getMarkNames()) do
                    if string.find(mark, "_ni_ai_") and damage.to:getMark(mark) ~= 0 then
                        if not string.find(mark, player:objectName()) then
                            can_trigger = true
                        end
                    end
                end
                if can_trigger then
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YunaShibata:addSkill(sakamichi_ni_ai)

sakamichi_yao_nv = sgs.CreateTriggerSkill {
    name = "sakamichi_yao_nv",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:setPlayerFlag(p, "yao_nv")
            end
        elseif change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasFlag("yao_nv") then
                    room:setPlayerFlag(p, "-yao_nv")
                end
            end
        end
        return false
    end,
}
sakamichi_yao_nv_invalidity = sgs.CreateInvaliditySkill {
    name = "#sakamichi_yao_nv_invalidity",
    frequency = sgs.Skill_Compulsory,
    skill_valid = function(self, player, skill)
        if player:hasFlag("yao_nv") and player:getKingdom() == "Nogizaka46" and SKMC.is_ki_be(player, 4) then
            return false
        else
            return true
        end
    end,
}
YunaShibata:addSkill(sakamichi_yao_nv)
if not sgs.Sanguosha:getSkill("#sakamichi_yao_nv_invalidity") then
    SKMC.SkillList:append(sakamichi_yao_nv_invalidity)
end

sgs.LoadTranslationTable {
    ["YunaShibata"] = "柴田 柚菜",
    ["&YunaShibata"] = "柴田 柚菜",
    ["#YunaShibata"] = "笑顏扶持",
    ["~YunaShibata"] = "ブ～ンブ～ン、柚菜のもとに着陸してね",
    ["designer:YunaShibata"] = "Cassimolar",
    ["cv:YunaShibata"] = "柴田 柚菜",
    ["illustrator:YunaShibata"] = "Cassimolar",
    ["sakamichi_ti_cao"] = "体操",
    [":sakamichi_ti_cao"] = "转换技，①你使用【杀】命中目标后，你使用的下一张【杀】将添加其为额外目标；②你闪避其他角色使用的【杀】后，其对你使用的下一张【杀】对你无效。",
    ["#ti_cao_hit"] = "%from 使用的%card命中%to，%from使用的下一张【杀】将添加%to为额外目标",
    ["#ti_cao_append"] = "%from 发动【%arg】将%to 添加为%card的额外目标",
    ["#ti_cao_miss"] = "%from 闪避%to 使用的%card，%to 对%from 使用的下一张【杀】对%from 无效",
    ["sakamichi_ni_ai"] = "溺爱",
    [":sakamichi_ni_ai"] = "限定技，结束阶段，你可以令一名其他角色武将牌复原然后令其体力值和手牌数与你相同，若如此做，直到你下个准备阶段，其他角色对其造成伤害+1。出牌阶段限一次，你可以将一名角色的转换技重置为①。",
    ["@ni_ai"] = "溺爱",
    ["@ni_ai_invoke"] = "你可以选择一名其他角色发动【%arg】",
    ["#ni_ai_change"] = "%from 发动【%arg】将%to 的【%arg2】重置为状态①",
    ["sakamichi_yao_nv"] = "妖女",
    [":sakamichi_yao_nv"] = "锁定技，你的回合内，其他乃木坂46势力的四期角色的技能均失效。",
}
