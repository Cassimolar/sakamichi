require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaUemura_Sakurazaka = sgs.General(Sakamichi, "RinaUemura_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.IKiSei.RinaUemura_Sakurazaka = true
SKMC.SeiMeiHanDan.RinaUemura_Sakurazaka = {
    name = {3, 7, 10, 11},
    ten_kaku = {10, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_chuan_xi = sgs.CreateTriggerSkill {
    name = "sakamichi_chuan_xi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpChanged},
    on_trigger = function(self, event, player, data, room)
        if not player:isKongcheng() then
            local target = room:askForYiji(player, player:handCards(), self:objectName(), false, false, true, 1,
                room:getOtherPlayers(player), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                    self:objectName(), nil), "@chuan_xi_invoke:::" .. self:objectName(), false)
            if target then
                local n = SKMC.number_correction(player, 1)
                if room:askForChoice(player, self:objectName(), "chuan_xi_1=" .. target:objectName() .. "=" .. n
                    .. "+chuan_xi_2=" .. target:objectName() .. "=" .. n) == "chuan_xi_1=" .. target:objectName() .. "="
                    .. n then
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, n))
                else
                    if target:isWounded() then
                        room:recover(target, sgs.RecoverStruct(player, nil, n))
                    end
                end
            end
        end
        return false
    end,
}
RinaUemura_Sakurazaka:addSkill(sakamichi_chuan_xi)

sakamichi_mu_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_mu_xing",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and p:objectName() ~= damage.from:objectName() then
                        room:askForUseSlashTo(p, damage.from, "@mu_xing_slash:" .. damage.from:objectName())
                    end
                end
            end
        else
            local recover = data:toRecover()
            if recover.who and recover.who:objectName() ~= player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and p:objectName() ~= recover.who:objectName() then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            room:drawCards(p, 1, self:objectName())
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaUemura_Sakurazaka:addSkill(sakamichi_mu_xing)

sakamichi_shuai_shui = sgs.CreateTriggerSkill {
    name = "sakamichi_shuai_shui",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Fire then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local n = SKMC.number_correction(p, 1)
                if room:askForSkillInvoke(p, self:objectName(),
                    sgs.QVariant("invoke:" .. player:objectName() .. "::" .. n)) then
                    damage.damage = n
                    data:setValue(damage)
                end
            end
        end
        return false
    end,
}
RinaUemura_Sakurazaka:addSkill(sakamichi_shuai_shui)

sgs.LoadTranslationTable {
    ["RinaUemura_Sakurazaka"] = "上村 莉菜",
    ["&RinaUemura_Sakurazaka"] = "上村 莉菜",
    ["#RinaUemura_Sakurazaka"] = "可爱化身",
    ["~RinaUemura_Sakurazaka"] = "変えました！",
    ["designer:RinaUemura_Sakurazaka"] = "Cassimolar",
    ["cv:RinaUemura_Sakurazaka"] = "上村 莉菜",
    ["illustrator:RinaUemura_Sakurazaka"] = "Cassimolar",
    ["sakamichi_chuan_xi"] = "喘息",
    [":sakamichi_chuan_xi"] = "当你体力值发生变化时，你可以将一张手牌交给一名其他角色，若如此做，你选择对其造成1点火焰伤害或令其回复1点体力。",
    ["@chuan_xi_invoke"] = "你可以将一张手牌交给其他角色发动【%arg】",
    ["chuan_xi_1"] = "对%src造成1点伤害",
    ["chuan_xi_2"] = "令%src回复1点体力",
    ["sakamichi_mu_xing"] = "母性",
    [":sakamichi_mu_xing"] = "当其他角色对另一名其他角色造成伤害后/回复体力时，你可以对伤害来源使用一张【杀】/摸一张牌。",
    ["@mu_xing_slash"] = "你可以对%src使用一张【杀】",
    ["sakamichi_shuai_shui"] = "甩水",
    [":sakamichi_shuai_shui"] = "当一名角色受到火焰伤害时，你可以令此伤害为1点。",
    ["sakamichi_shuai_shui:invoke"] = "是否令%src此次受到的火焰伤害为%arg点",
}
