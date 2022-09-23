require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiKobayashi_Keyakizaka = sgs.General(Sakamichi, "YuiKobayashi_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.YuiKobayashi_Keyakizaka = true
SKMC.SeiMeiHanDan.YuiKobayashi_Keyakizaka = {
    name = {3, 8, 5, 8},
    ten_kaku = {11, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_qiao_zhong = sgs.CreateTriggerSkill {
    name = "sakamichi_qiao_zhong$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@qiao_zhong",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local hasyurina = false
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if string.find(p:getGeneralName(), "YurinaHirate") or string.find(p:getGeneral2Name(), "YurinaHirate") then
                    hasyurina = true
                    break
                end
            end
            if not hasyurina and player:isLord() and player:getMark("@qiao_zhong") ~= 0
                and room:askForSkillInvoke(player, self:objectName(), data) then
                room:removePlayerMark(player, "@qiao_zhong")
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getKingdom() == "Keyakizaka46" then
                        if not p:faceUp() then
                            p:turnOver()
                        end
                        room:setPlayerChained(p, false)
                        room:recover(p, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                        room:drawCards(p, 1, self:objectName())
                        local general_1, general_2 = p:getGeneral(), p:getGeneral2()
                        local name_1, name_2 = p:getGeneralName(), p:getGeneral2Name()
                        local _general_1, _general_2
                        if general_1 then
                            if string.find(name_1, "Keyakizaka") then
                                _general_1 = sgs.Sanguosha:getGeneral(string.gsub(name_1, "Keyakizaka", "Sakurazaka"))
                            end
                            if not _general_1 or _general_1:getKingdom() ~= "Sakurazaka46" then
                                if general_1:getKingdom() == "Sakurazaka46" then
                                    _general_1 = general_1
                                end
                            end
                        end
                        if general_2 then
                            if string.find(name_2, "Keyakizaka") then
                                _general_2 = sgs.Sanguosha:getGeneral(string.gsub(name_2, "Keyakizaka", "Sakurazaka"))
                            end
                            if not _general_2 or _general_2:getKingdom() ~= "Sakurazaka46" then
                                if general_2:getKingdom() == "Sakurazaka46" then
                                    _general_2 = general_2
                                end
                            end
                        end
                        if _general_1 then
                            room:changeHero(p, _general_1:objectName(), false)
                        end
                        if _general_2 then
                            room:changeHero(p, _general_2:objectName(), false, true, true)
                        end
                    end
                end
            end
        end
        return false
    end,
}
YuiKobayashi_Keyakizaka:addSkill(sakamichi_qiao_zhong)

sakamichi_gu_du = sgs.CreateTriggerSkill {
    name = "sakamichi_gu_du",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            if player:isWounded() and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@wu_yu_invoke")) then
                room:recover(player, sgs.RecoverStruct(player, damage.card, SKMC.number_correction(player, 1)))
            else
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
sakamichi_gu_du_protect = sgs.CreateProhibitSkill {
    name = "#sakamichi_gu_du_protect",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_gu_du") and card:isKindOf("Peach") and to:objectName() ~= from:objectName()
    end,
}
YuiKobayashi_Keyakizaka:addSkill(sakamichi_gu_du)
if not sgs.Sanguosha:getSkill("#sakamichi_gu_du_protect") then
    SKMC.SkillList:append(sakamichi_gu_du_protect)
end

sakamichi_kuang_quan = sgs.CreateTriggerSkill {
    name = "sakamichi_kuang_quan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card:isKindOf("Slash") then
                if use.card:isBlack() then
                    room:setCardFlag(use.card, "SlashIgnoreArmor")
                elseif use.card:isRed() then
                    if use.m_addHistory then
                        room:addPlayerHistory(player, use.card:getClassName(), -1)
                    end
                end
            end
        end
        return false
    end,
}
sakamichi_kuang_quan_attack_range = sgs.CreateAttackRangeSkill {
    name = "#sakamichi_kuang_quan_attack_range",
    extra_func = function(self, player, include_weapon)
        if player:hasSkill("sakamichi_kuang_quan") then
            return SKMC.number_correction(player, 1)
        else
            return 0
        end
    end,
}
YuiKobayashi_Keyakizaka:addSkill(sakamichi_kuang_quan)
if not sgs.Sanguosha:getSkill("#sakamichi_kuang_quan_attack_range") then
    SKMC.SkillList:append(sakamichi_kuang_quan_attack_range)
end

sgs.LoadTranslationTable {
    ["YuiKobayashi_Keyakizaka"] = "小林 由依",
    ["&YuiKobayashi_Keyakizaka"] = "小林 由依",
    ["#YuiKobayashi_Keyakizaka"] = "埼玉狂犬",
    ["~YuiKobayashi_Keyakizaka"] = "めっちゃ美味しい、すごいめっちゃ美味しい",
    ["designer:YuiKobayashi_Keyakizaka"] = "Cassimolar",
    ["cv:YuiKobayashi_Keyakizaka"] = "小林 由依",
    ["illustrator:YuiKobayashi_Keyakizaka"] = "Cassimolar",
    ["sakamichi_qiao_zhong"] = "敲钟",
    [":sakamichi_qiao_zhong"] = "主公技，限定技，准备阶段，若场上不存在【平手友梨奈】，你可以令场上所有欅坂46势力角色复原武将牌然后回复1点体力并摸一张牌，若该角色的武将有櫻坂46势力版本，替换其武将牌。",
    ["sakamichi_gu_du"] = "孤独",
    [":sakamichi_gu_du"] = "锁定技，你不是其他角色使用【杀】的合法目标。你使用【杀】造成伤害后，你回复1点体力或摸一张牌。",
    ["sakamichi_gu_du:@wu_yu_invoke"] = "你可以回复1点体力，否则摸一张牌",
    ["sakamichi_kuang_quan"] = "狂犬",
    [":sakamichi_kuang_quan"] = "锁定技，你的攻击范围+1；你使用的黑色【杀】无视防具；你使用的红色【杀】不计入使用次数限制。",
}
