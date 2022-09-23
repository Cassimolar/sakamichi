require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiKobayashi_Sakurazaka = sgs.General(Sakamichi, "YuiKobayashi_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.IKiSei.YuiKobayashi_Sakurazaka = true
SKMC.SeiMeiHanDan.YuiKobayashi_Sakurazaka = {
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

sakamichi_ba_wang = sgs.CreateTriggerSkill {
    name = "sakamichi_ba_wang",
    frequency = sgs.Skill_Frequent,
    hide_skill = true,
    events = {sgs.Appear},
    on_trigger = function(self, event, player, data, room)
        local current = room:getCurrent()
        if current:objectName() ~= player:objectName() then
            if not current:isAllNude() then
                local id = room:askForCardChosen(player, current, "hej", self:objectName(), false, sgs.Card_MethodNone,
                    sgs.IntList(), true)
                if id ~= -1 then
                    local can_slash = room:getCardPlace(id) ~= sgs.Player_PlaceHand
                    room:obtainCard(player, id)
                    if can_slash then
                        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        slash:deleteLater()
                        slash:setSkillName(self:objectName())
                        room:useCard(sgs.CardUseStruct(slash, player, current), false)
                    end
                end
            end
        end
        return false
    end,
}
YuiKobayashi_Sakurazaka:addSkill(sakamichi_ba_wang)

sakamichi_rou_ti = sgs.CreateTriggerSkill {
    name = "sakamichi_rou_ti",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:objectName() ~= player:objectName() and player:distanceTo(damage.to)
            == SKMC.number_correction(player, 1) and damage.to:hasSkill(self) then
            if not player:isAllNude() and room:askForSkillInvoke(damage.to, self:objectName(), data) then
                local id = room:askForCardChosen(damage.to, player, "hej", self:objectName(), false,
                    sgs.Card_MethodNone, sgs.IntList())
                if id ~= -1 then
                    room:obtainCard(damage.to, id)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_rou_ti_attack_range = sgs.CreateAttackRangeSkill {
    name = "#sakamichi_rou_ti_attack_range",
    frequency = sgs.Skill_Compulsory,
    extra_func = function(self, player, include_weapon)
        if player:hasSkill("sakamichi_rou_ti") then
            return SKMC.number_correction(player, 1)
        else
            return 0
        end
    end,
}
sakamichi_rou_ti_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_rou_ti_mod",
    frequency = sgs.Skill_Compulsory,
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_rou_ti") then
            return SKMC.number_correction(from, 1)
        end
    end,
}
YuiKobayashi_Sakurazaka:addSkill(sakamichi_rou_ti)
if not sgs.Sanguosha:getSkill("#sakamichi_rou_ti_attack_range") then
    SKMC.SkillList:append(sakamichi_rou_ti_attack_range)
end
if not sgs.Sanguosha:getSkill("#sakamichi_rou_ti_mod") then
    SKMC.SkillList:append(sakamichi_rou_ti_mod)
end

sakamichi_chou_fan = sgs.CreateTriggerSkill {
    name = "sakamichi_chou_fan",
    events = {sgs.CardsMoveOneTime, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.to and move.from:objectName() ~= move.to:objectName() and move.to:objectName()
                == player:objectName() then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:" .. move.from:objectName())) then
                    room:damage(sgs.DamageStruct(self:objectName(), player,
                        room:findPlayerByObjectName(move.from:objectName()), SKMC.number_correction(player, 1)))
                end
            end
        else
            local recover = data:toRecover()
            if recover.who and recover.who:objectName() ~= player:objectName() then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:" .. recover.who:objectName())) then
                    room:damage(sgs.DamageStruct(self:objectName(), player, recover.who,
                        SKMC.number_correction(player, 1)))
                end
            end
        end
        return false
    end,
}
YuiKobayashi_Sakurazaka:addSkill(sakamichi_chou_fan)

sgs.LoadTranslationTable {
    ["YuiKobayashi_Sakurazaka"] = "小林 由依",
    ["&YuiKobayashi_Sakurazaka"] = "小林 由依",
    ["#YuiKobayashi_Sakurazaka"] = "孤狼",
    ["~YuiKobayashi_Sakurazaka"] = "すごい見てるじゃないですか",
    ["designer:YuiKobayashi_Sakurazaka"] = "Cassimolar",
    ["cv:YuiKobayashi_Sakurazaka"] = "小林 由依",
    ["illustrator:YuiKobayashi_Sakurazaka"] = "Cassimolar",
    ["sakamichi_ba_wang"] = "霸王",
    [":sakamichi_ba_wang"] = "隐匿技，你于其他角色回合登场后，你可以获得其区域内的一张牌，若此牌不来自手牌，视为你对其使用一张【杀】。",
    ["sakamichi_rou_ti"] = "柔体",
    [":sakamichi_rou_ti"] = "锁定技，你的攻击距离+1；你出牌阶段使用【杀】的限制次数+1；距离你为1的角色对你造成伤害后，你获得其区域内一张牌。",
    ["sakamichi_chou_fan"] = "仇返",
    [":sakamichi_chou_fan"] = "当你获得其他角色区域内的牌时或其他角色令你回复体力值后，你可以对其造成1点伤害。",
    ["sakamichi_chou_fan:invoke"] = "是否发动【仇返】对%src造成1点伤害",
}
