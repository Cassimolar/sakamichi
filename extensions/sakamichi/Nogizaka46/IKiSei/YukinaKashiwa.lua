require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YukinaKashiwa = sgs.General(Sakamichi, "YukinaKashiwa", "Nogizaka46", 3, false)
SKMC.IKiSei.YukinaKashiwa = true
SKMC.SeiMeiHanDan.YukinaKashiwa = {
    name = {9, 8, 8},
    ten_kaku = {9, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {25, "ji"},
    go_gyo_san_sai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_tong_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_tong_xing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local damage = death.damage
        if damage and damage.from and damage.from:objectName() == player:objectName() then
            room:gainMaxHp(player, SKMC.number_correction(player, 1))
            if player:isWounded() then
                room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            end
            SKMC.send_message(room, "#GetHp", player, nil, nil, nil, player:getHp(), player:getMaxHp())
        end
        return false
    end,
}
sakamichi_tong_xing_Mod = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_tong_xing_Mod",
    fixed_func = function(self, target)
        if target:hasSkill("sakamichi_tong_xing") then
            return target:getMaxHp()
        else
            return -1
        end
    end,
}
YukinaKashiwa:addSkill(sakamichi_tong_xing)
if not sgs.Sanguosha:getSkill("#sakamichi_tong_xing_Mod") then
    SKMC.SkillList:append(sakamichi_tong_xing_Mod)
end

sakamichi_gui_lian_card = sgs.CreateSkillCard {
    name = "sakamichi_gui_lianCard",
    skill_name = "sakamichi_gui_lian",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@gui_lian")
        local choice = room:askForChoice(effect.from, self:getSkillName(), "card_limitation=" .. effect.to:objectName()
            .. "+skill_invalidity=" .. effect.to:objectName())
        SKMC.choice_log(effect.from, choice)
        if choice == "card_limitation=" .. effect.to:objectName() then
            room:setPlayerCardLimitation(effect.to, "use,response", ".|.|.|hand", true)
            SKMC.send_message(room, "#gui_lian_card", effect.from, effect.to, nil, nil, self:getSkillName())
        else
            room:setPlayerFlag(effect.from, "gui_lian" .. effect.to:objectName())
            room:addPlayerMark(effect.to, "@skill_invalidity")
            SKMC.send_message(room, "#gui_lian_skill", effect.from, effect.to, nil, nil, self:getSkillName())
        end
    end,
}
sakamichi_gui_lian_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_gui_lian",
    view_as = function()
        return sakamichi_gui_lian_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@gui_lian") ~= 0
    end,
}
sakamichi_gui_lian = sgs.CreateTriggerSkill {
    name = "sakamichi_gui_lian",
    frequency = sgs.Skill_Limited,
    events = {sgs.EventPhaseChanging},
    limit_mark = "@gui_lian",
    view_as_skill = sakamichi_gui_lian_view_as,
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:hasFlag("gui_lian" .. p:objectName()) then
                    room:setPlayerFlag(player, "-gui_lian" .. p:ojectName())
                    room:removePlayerMark(p, "@skill_invalidity")
                end
            end
        end
        return false
    end,
}
YukinaKashiwa:addSkill(sakamichi_gui_lian)

sakamichi_tian_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_tian_shi",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_xiao_yan",
    events = {sgs.EventPhaseChanging},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if data:toPhaseChange().to == sgs.Player_Start and player:getMark("tian_shi_can_wake") ~= 0 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        if room:changeMaxHpForAwakenSkill(player, SKMC.number_correction(player, 1)) then
            room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            room:handleAcquireDetachSkills(player, "-sakamichi_gui_lian|sakamichi_xiao_yan")
            room:setPlayerMark(player, "@gui_lian", 0)
        end
        return false
    end,
}
sakamichi_tian_shi_record = sgs.CreateTriggerSkill {
    name = "#sakamichi_tian_shi_record",
    events = {sgs.Death, sgs.EnterDying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            local damage = death.damage
            if damage and damage.from and damage.from:objectName() == player:objectName()
                and player:hasSkill("sakamichi_tian_shi") and player:getMark("tian_shi_can_wake") == 0
                and player:getMark("sakamichi_tian_shi") == 0 then
                room:setPlayerMark(player, "tian_shi_can_wake", 1)
            end
        else
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and player:hasSkill("sakamichi_tian_shi")
                and player:getMark("tian_shi_can_wake") == 0 and player:getMark("sakamichi_tian_shi") == 0 then
                room:setPlayerMark(player, "tian_shi_can_wake", 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_tian_shi", "#sakamichi_tian_shi_record")
YukinaKashiwa:addSkill(sakamichi_tian_shi)
YukinaKashiwa:addSkill(sakamichi_tian_shi_record)

sakamichi_xiao_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from and death.damage.from:objectName() == player:objectName()
                and player:getPhase() ~= sgs.Player_NotActive then
                room:setPlayerFlag(player, "sakamichi_xiao_yan")
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and player:hasFlag("sakamichi_xiao_yan") then
                room:setPlayerFlag(player, "-sakamichi_xiao_yan")
                SKMC.send_message(room, "#Fangquan", nil, player)
                player:gainAnExtraTurn()
            end
            return false
        end
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_xiao_yan") then
    SKMC.SkillList:append(sakamichi_xiao_yan)
end

sakamichi_tao_cao = sgs.CreateTriggerSkill {
    name = "sakamichi_tao_cao",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_yi_cai",
    events = {sgs.EventPhaseStart},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPhase() == sgs.Player_Start and player:getHandcardNum() > player:getHp() and player:isWounded() then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        if room:changeMaxHpForAwakenSkill(player, -SKMC.number_correction(player, 1)) then
            if player:isWounded() then
                room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            end
            room:handleAcquireDetachSkills(player, "sakamichi_yi_cai")
        end
    end,
}
YukinaKashiwa:addSkill(sakamichi_tao_cao)

sakamichi_yi_cai = sgs.CreateTriggerSkill {
    name = "sakamichi_yi_cai",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                card = use.card
            elseif event == sgs.CardResponsed then
                card = data:toResponsed().m_card
            end
            if card and card:isNDTrick() then
                room:throwCard(card, nil)
                room:askForUseCard(player, "slash", "@askforslash")
            end
        else
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                if not damage.to:isAllNude() then
                    local card = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false,
                        sgs.Card_MethodNone)
                    room:obtainCard(player, card)
                else
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_yi_cai") then
    SKMC.SkillList:append(sakamichi_yi_cai)
end

sgs.LoadTranslationTable {
    ["YukinaKashiwa"] = "柏 幸奈",
    ["&YukinaKashiwa"] = "柏 幸奈",
    ["#YukinaKashiwa"] = "流浪偶像",
    ["~YukinaKashiwa"] = "我が道を行く",
    ["designer:YukinaKashiwa"] = "Cassimolar",
    ["cv:YukinaKashiwa"] = "柏 幸奈",
    ["illustrator:YukinaKashiwa"] = "Cassimolar",
    ["sakamichi_tong_xing"] = "童星",
    [":sakamichi_tong_xing"] = "锁定技，当你杀死一名角色后，你增加1点体力上限并回复1点体力。你的手牌上限等于你的体力上限。",
    ["sakamichi_gui_lian"] = "鬼脸",
    [":sakamichi_gui_lian"] = "限定技，出牌阶段，你可以令一名其他角色本回合内无法使用或打出手牌/非锁定技失效。",
    ["sakamichi_gui_lian:card_limitation"] = "令%src本回合内无法使用或打出手牌",
    ["sakamichi_gui_lian:skill_invalidity"] = "令%src本回合内非锁定技失效",
    ["#gui_lian_card"] = "%from 发动【%arg】令%to 本回合内无法使用或打出手牌",
    ["#gui_lian_skill"] = "%from 发动【%arg】令%to 本回合内非锁定技失效",
    ["@gui_lian"] = "鬼脸",
    ["sakamichi_tian_shi"] = "天使",
    [":sakamichi_tian_shi"] = "觉醒技，准备阶段，若你已杀死至少一名角色或进入过濒死，你增加1点体力上限并回复1点体力，然后失去【鬼脸】获得【笑颜】。",
    ["sakamichi_xiao_yan"] = "笑颜",
    [":sakamichi_xiao_yan"] = "锁定技，结束阶段，若本回合内你至少杀死一名角色，你执行一个额外的回合。",
    ["sakamichi_tao_cao"] = "桃草",
    [":sakamichi_tao_cao"] = "觉醒技，准备阶段，若你的手牌数大于你的体力值且你已受伤，你须减少1点体力上限并回复1点体力，然后获得【异才】。",
    ["sakamichi_yi_cai"] = "异才",
    [":sakamichi_yi_cai"] = "当你使用一张通常锦囊牌时（在它结算之前），你可以立即对攻击范围内的角色使用一张【杀】。当你使用【杀】造成伤害后，你可以获得目标区域内的一张牌（若目标区域内没有牌，则你摸一张牌）。",
}
