require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AoiHarada_Sakurazaka = sgs.General(Sakamichi, "AoiHarada_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.IKiSei.AoiHarada_Sakurazaka = true
SKMC.SeiMeiHanDan.AoiHarada_Sakurazaka = {
    name = {10, 5, 12},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {17, "ji"},
    ji_kaku = {12, "xiong"},
    soto_kaku = {22, "xiong"},
    sou_kaku = {27, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_que_yue = sgs.CreateTriggerSkill {
    name = "sakamichi_que_yue",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
            player:gainHujia(SKMC.number_correction(player, 1))
        end
        return false
    end,
}
AoiHarada_Sakurazaka:addSkill(sakamichi_que_yue)

sakamichi_lian_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_lian_sheng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
            local result = SKMC.run_judge(room, player, self:objectName(), "BasicCard")
            if result.isGood then
                room:obtainCard(player, result.card, true)
                if result.card:isKindOf("Slash") then
                    room:askForUseCard(player, "slash", "@askforslash")
                end
            end
        end
        return false
    end,
}
AoiHarada_Sakurazaka:addSkill(sakamichi_lian_sheng)

sgs.LoadTranslationTable {
    ["AoiHarada_Sakurazaka"] = "原田 葵",
    ["&AoiHarada_Sakurazaka"] = "原田 葵",
    ["#AoiHarada_Sakurazaka"] = "公式小学生",
    ["~AoiHarada_Sakurazaka"] = "二十歳です！",
    ["designer:AoiHarada_Sakurazaka"] = "Cassimolar",
    ["cv:AoiHarada_Sakurazaka"] = "原田 葵",
    ["illustrator:AoiHarada_Sakurazaka"] = "Cassimolar",
    ["sakamichi_que_yue"] = "雀跃",
    [":sakamichi_que_yue"] = "你使用【杀】造成伤害后，你可以获得1点护甲。",
    ["sakamichi_lian_sheng"] = "连胜",
    [":sakamichi_lian_sheng"] = "你使用【杀】造成伤害后，你可以判定，若结果为基本牌，你获得之，若结果为【杀】，你可以使用一张【杀】。",
}
