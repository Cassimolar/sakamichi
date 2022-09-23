require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuiTakemoto_Sakurazaka = sgs.General(Sakamichi, "YuiTakemoto_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.NiKiSei.YuiTakemoto_Sakurazaka = true
SKMC.SeiMeiHanDan.YuiTakemoto_Sakurazaka = {
    name = {8, 4, 11, 6},
    ten_kaku = {12, "xiong"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

Luaxiangai = sgs.CreateTriggerSkill {
    name = "Luaxiangai",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") then
            if use.from:objectName() == player:objectName() and player:hasSkill(self) then
                for _, p in sgs.qlist(use.to) do
                    if player:distanceTo(p) == 1 and room:askForSkillInvoke(player, self:objectName(), data) then
                        room:drawCards(player, 1, self:objectName())
                    end
                end
            end
            for _, p in sgs.qlist(use.to) do
                if player:distanceTo(p) == 1 and p:hasSkill(self) and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuiTakemoto_Sakurazaka:addSkill(Luaxiangai)

sakamichi_zhu_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_zhu_dao",
    events = {sgs.TurnOver, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnOver then
            if player:hasSkill(self) and not player:faceUp() and room:askForSkillInvoke(player, self:objectName(), data) then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "zhu_dao_invoke", true, true)
                if target then
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, SKMC.number_correction(player, 1)))
                    if player:getMark("zhu_dao" .. target:objectName()) == 0 then
                        room:askForUseCard(player, "Slash,TrickCard+^Nullification", "zhu_dao_use")
                    else
                        room:setPlayerMark(player, "zhu_dao" .. target:objectName(), 0)
                    end
                end
                return true
            end
        else
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() and dying.damage and dying.damage.from
                and dying.damage.from:hasSkill(self) and dying.damage.reason == self:objectName() then
                room:setPlayerMark(dying.damage.from, "zhu_dao" .. player:objectName(), 1)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuiTakemoto_Sakurazaka:addSkill(sakamichi_zhu_dao)

sakamichi_zhu_mian = sgs.CreateTriggerSkill {
    name = "sakamichi_zhu_mian",
    events = {sgs.TurnedOver},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke_1:" .. player:objectName())) then
                room:drawCards(player, 1, self:objectName())
                if p:faceUp() and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke_2")) then
                    room:drawCards(p, 1, self:objectName())
                    p:turnOver()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuiTakemoto_Sakurazaka:addSkill(sakamichi_zhu_mian)

sgs.LoadTranslationTable {
    ["YuiTakemoto_Sakurazaka"] = "武元 唯衣",
    ["&YuiTakemoto_Sakurazaka"] = "武元 唯衣",
    ["#YuiTakemoto_Sakurazaka"] = "新晋助导",
    ["~YuiTakemoto_Sakurazaka"] = "じゃあみんな私がいなくても•••",
    ["designer:YuiTakemoto_Sakurazaka"] = "Cassimolar",
    ["cv:YuiTakemoto_Sakurazaka"] = "武元 唯衣",
    ["illustrator:YuiTakemoto_Sakurazaka"] = "Cassimolar",
    ["Luaxiangai"] = "乡爱",
    [":Luaxiangai"] = "你使用牌指定距离为1的角色为目标后/与你距离为1的角色使用牌指定你为目标后，你可以摸一张牌。",
    ["sakamichi_zhu_dao"] = "助导",
    [":sakamichi_zhu_dao"] = "当你翻回正面时，你可以防止之，然后你可以对一名其他角色造成1点伤害，若其未因此进入濒死，你可以使用一张【杀】或锦囊牌。",
    ["zhu_dao_invoke"] = "你可以对一名其他角色造成1点伤害",
    ["zhu_dao_use"] = "你可以使用一张【杀】或锦囊牌",
    ["sakamichi_zhu_mian"] = "助眠",
    [":sakamichi_zhu_mian"] = "当一名角色武将牌翻面时，你可以令其摸一张牌，若你的武将正面向上，你可以摸一张牌然后将武将牌翻面。",
    ["sakamichi_zhu_mian:invoke_1"] = "是否令%src摸一张牌",
    ["sakamichi_zhu_mian:invoke_2"] = "是否摸一张牌然后将武将牌翻面",
}
