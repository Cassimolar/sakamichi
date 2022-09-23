require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KarinFujiyoshi_Keyakizaka = sgs.General(Sakamichi, "KarinFujiyoshi_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.NiKiSei.KarinFujiyoshi_Keyakizaka = true
SKMC.SeiMeiHanDan.KarinFujiyoshi_Keyakizaka = {
    name = {18, 6, 10, 13},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {23, "ji"},
    soto_kaku = {31, "da_ji"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_man_re = sgs.CreateTriggerSkill {
    name = "sakamichi_man_re",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName()
                    and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("slash:" .. player:objectName())) then
                    local use_slash = false
                    if player:canSlash(p, nil, false) then
                        use_slash = room:askForUseSlashTo(player, p, "@man_re_slash:" .. p:objectName())
                    end
                    if not use_slash then
                        room:askForUseSlashTo(p, player, "@man_re_slash2:" .. player:objectName())
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
KarinFujiyoshi_Keyakizaka:addSkill(sakamichi_man_re)

sakamichi_bu_gao_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_gao_xing",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and damage.from:objectName() ~= player:objectName() then
            room:drawCards(player, 1, self:objectName())
            local current = room:getCurrent()
            if current:getPhase() == sgs.Player_Play then
                current:endPlayPhase()
            end
        end
        return false
    end,
}
sakamichi_bu_gao_xingProhibit = sgs.CreateProhibitPindianSkill {
    name = "#sakamichi_bu_gao_xingProhibit",
    is_pindianprohibited = function(self, from, to)
        return to:hasSkill("sakamichi_bu_gao_xing")
    end,
}
KarinFujiyoshi_Keyakizaka:addSkill(sakamichi_bu_gao_xing)
if not sgs.Sanguosha:getSkill("#sakamichi_bu_gao_xingProhibit") then
    SKMC.SkillList:append(sakamichi_bu_gao_xingProhibit)
end

sgs.LoadTranslationTable {
    ["KarinFujiyoshi_Keyakizaka"] = "藤吉 夏鈴",
    ["&KarinFujiyoshi_Keyakizaka"] = "藤吉 夏鈴",
    ["#KarinFujiyoshi_Keyakizaka"] = "呆头呆脑",
    ["~KarinFujiyoshi_Keyakizaka"] = "すごい楽しいー♪",
    ["designer:KarinFujiyoshi_Keyakizaka"] = "Cassimolar",
    ["cv:KarinFujiyoshi_Keyakizaka"] = "藤吉 夏鈴",
    ["illustrator:KarinFujiyoshi_Keyakizaka"] = "Cassimolar",
    ["sakamichi_man_re"] = "慢热",
    [":sakamichi_man_re"] = "其他角色出牌阶段开始时，你可以令其对你使用一张【杀】，若其未若此做，你可以对其使用一张【杀】。",
    ["sakamichi_man_re:slash"] = "是否令%src对你使用一张【杀】",
    ["@man_re_slash"] = "你可以对%src使用一张【杀】否则其可以对你使用一张【杀】",
    ["@man_re_slash2"] = "你可以对%src使用一张【杀】",
    ["sakamichi_bu_gao_xing"] = "不高兴",
    [":sakamichi_bu_gao_xing"] = "锁定技，你不是拼点的合法目标。当你受到其他角色造成的伤害后，你摸一张牌，若当前为出牌阶段，则结束此阶段。",
}
