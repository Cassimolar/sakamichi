require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MiyuMatsuo = sgs.General(Sakamichi, "MiyuMatsuo", "Nogizaka46", 3, false)
SKMC.YonKiSei.MiyuMatsuo = true
SKMC.SeiMeiHanDan.MiyuMatsuo = {
    name = {8, 7, 9, 7},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

sakamichi_zhuan_zhe = sgs.CreateTriggerSkill {
    name = "sakamichi_zhuan_zhe",
    change_skill = true,
    events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.EventPhaseChanging, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if room:getChangeSkillState(player, self:objectName()) == 2 then
                    room:setChangeSkillState(player, self:objectName(), 1)
                    room:setPlayerProperty(player, "kingdom", sgs.QVariant("SakamichiKenshusei"))
                    room:setPlayerFlag(player, "zhuan_zhe_1")
                elseif room:getChangeSkillState(player, self:objectName()) == 1 then
                    room:setChangeSkillState(player, self:objectName(), 2)
                    room:setPlayerProperty(player, "kingdom", sgs.QVariant("Nogizaka46"))
                    room:setPlayerFlag(player, "zhuan_zhe_2")
                end
            end
        elseif event == sgs.DrawNCards then
            if player:hasFlag("zhuan_zhe_1") then
                data:setValue(data:toInt() + 1)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard and player:hasFlag("zhuan_zhe_1") then
                player:skip(change.to)
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasFlag("zhuan_zhe_2") and use.card:isKindOf("Slash") then
                room:setCardFlag(use.card, "SlashIgnoreArmor")
            end
        end
        return false
    end,
}
sakamichi_zhuan_zhe_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_zhuan_zhe_target_mod",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_zhuan_zhe") and from:hasFlag("zhuan_zhe_2") then
            return 1
        end
    end,
}
sakamichi_zhuan_zhe_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_zhuan_zhe_card_limit",
    limit_list = function(self, player)
        if player:hasFlag("zhuan_zhe_1") and player:getPhase() == sgs.Player_Play then
            return "use"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:hasFlag("zhuan_zhe_1") and player:getPhase() == sgs.Player_Play then
            return "Slash"
        else
            return ""
        end
    end,
}
MiyuMatsuo:addSkill(sakamichi_zhuan_zhe)
if not sgs.Sanguosha:getSkill("#sakamichi_zhuan_zhe_target_mod") then
    SKMC.SkillList:append(sakamichi_zhuan_zhe_target_mod)
end
if not sgs.Sanguosha:getSkill("#sakamichi_zhuan_zhe_card_limit") then
    SKMC.SkillList:append(sakamichi_zhuan_zhe_card_limit)
end

sakamichi_dan_lian = sgs.CreateTriggerSkill {
    name = "sakamichi_dan_lian",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetSpecified, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.to:length() == 1 then
                local last_target = player:getTag("sakamichi_dan_lian_last_target"):toPlayer()
                if last_target then
                    local target = use.to:first()
                    if last_target:objectName() == target:objectName() then
                        room:setCardFlag(use.card, self:objectName())
                    end
                end
                for _, mark in sgs.list(player:getMarkNames()) do
                    if mark:startsWith("&" .. self:objectName()) then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. use.to:first():getGeneralName(), 1)
                local _target = sgs.QVariant()
                _target:setValue(use.to:first())
                player:setTag("sakamichi_dan_lian_last_target", _target)
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag(self:objectName()) then
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end,
}
MiyuMatsuo:addSkill(sakamichi_dan_lian)

sakamichi_sheng_si = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_si",
    frequency = sgs.Skill_Limited,
    limit_mark = "@sheng_si",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if player:getMark("@sheng_si") ~= 0 then
                    local target_list = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getKingdom() == "Nogizaka46" and SKMC.is_ki_be(p, 4) then
                            target_list:append(p)
                        end
                    end
                    if not target_list:isEmpty() then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            room:removePlayerMark(player, "@sheng_si")
                            local target = room:askForPlayerChosen(player, target_list, self:objectName(),
                                "@sheng_si_chosen")
                            local skill_list = {}
                            for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                                table.insert(skill_list, skill:objectName())
                            end
                            if #skill_list ~= 0 then
                                local skill_name = room:askForChoice(player, self:objectName(),
                                    table.concat(skill_list, "+"))
                                SKMC.choice_log(player, skill_name)
                                room:acquireNextTurnSkills(player, self:objectName(), skill_name)
                                room:addPlayerMark(target, "&" .. self:objectName() .. "+ +" .. skill_name)
                            end
                        end
                    end
                else
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if mark:startsWith("&" .. self:objectName()) then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_sheng_si_invalidity = sgs.CreateInvaliditySkill {
    name = "#sakamichi_sheng_si_invalidity",
    skill_valid = function(self, player, skill)
        if player:getMark("&sakamichi_sheng_si+ +" .. skill:objectName()) ~= 0 then
            return false
        else
            return true
        end
    end,
}
MiyuMatsuo:addSkill(sakamichi_sheng_si)
if not sgs.Sanguosha:getSkill("#sakamichi_sheng_si_invalidity") then
    SKMC.SkillList:append(sakamichi_sheng_si_invalidity)
end

sgs.LoadTranslationTable {
    ["MiyuMatsuo"] = "松尾 美佑",
    ["&MiyuMatsuo"] = "松尾 美佑",
    ["#MiyuMatsuo"] = "文武双全",
    ["~MiyuMatsuo"] = "あん？",
    ["designer:MiyuMatsuo"] = "Cassimolar",
    ["cv:MiyuMatsuo"] = "松尾 美佑",
    ["illustrator:MiyuMatsuo"] = "Cassimolar",
    ["sakamichi_zhuan_zhe"] = "转折",
    [":sakamichi_zhuan_zhe"] = "转换技，准备阶段，①修改你的势力为坂道研修生，本回合内：摸牌阶段多摸一张牌，出牌阶段你无法使用【杀】，跳过弃牌阶段；②修改你的势力为乃木坂46，本回合内：出牌阶段你可以使用【杀】的限制次数+1，你使用的【杀】无视防具。",
    ["sakamichi_dan_lian"] = "单恋",
    [":sakamichi_dan_lian"] = "当你使用【杀】指定目标后，若目标唯一且与你使用的上一张目标唯一的【杀】的目标相同，此【杀】造成伤害时，伤害+1。",
    ["sakamichi_sheng_si"] = "声似",
    [":sakamichi_sheng_si"] = "限定技，准备阶段，你可获得场上一名其他乃木坂46势力四期角色的一个技能直到你的下个回合开始，在此期间，其此技能失效。",
}
