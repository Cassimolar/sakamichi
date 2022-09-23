require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaMatsuda_Sakurazaka = sgs.General(Sakamichi, "RinaMatsuda_Sakurazaka", "Sakurazaka46", 4, false, false, false, 3)
SKMC.NiKiSei.RinaMatsuda_Sakurazaka = true
SKMC.SeiMeiHanDan.RinaMatsuda_Sakurazaka = {
    name = {8, 5, 7, 8},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {28, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_fen_wei = sgs.CreateTriggerSkill {
    name = "sakamichi_fen_wei",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged, sgs.HpLost},
    on_trigger = function(self, event, player, data, room)
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
            "@fen_wei_invoke", true)
        if target then
            room:drawCards(target, 2, self:objectName())
            room:damage(sgs.DamageStruct(self:objectName(), player, target, SKMC.number_correction(player, 1)))
        end
        return false
    end,
}
RinaMatsuda_Sakurazaka:addSkill(sakamichi_fen_wei)

sakamichi_yong_qian = sgs.CreateTriggerSkill {
    name = "sakamichi_yong_qian",
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        local target
        if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:length() > 1 then
            for _, p in sgs.qlist(use.to) do
                if p:hasSkill(self) and room:askForSkillInvoke(p, self:objectName(), data) then
                    target = p
                    break
                end
            end
            if target then
                room:loseHp(target, SKMC.number_correction(target, 1))
                local nullified_list = use.nullified_list
                for _, p in sgs.qlist(use.to) do
                    if p:objectName() ~= target:objectName() then
                        table.insert(nullified_list, p:objectName())
                    end
                end
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaMatsuda_Sakurazaka:addSkill(sakamichi_yong_qian)

sakamichi_lian_jian = sgs.CreateTriggerSkill {
    name = "sakamichi_lian_jian",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.HpChanged, sgs.MaxHpChanged, sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        if player:getHp() > SKMC.number_correction(player, 2) then
            player:setGender(sgs.General_Male)
        else
            player:setGender(sgs.General_Female)
        end
        return false
    end,
}
RinaMatsuda_Sakurazaka:addSkill(sakamichi_lian_jian)

sgs.LoadTranslationTable {
    ["RinaMatsuda_Sakurazaka"] = "松田 里奈",
    ["&RinaMatsuda_Sakurazaka"] = "松田 里奈",
    ["#RinaMatsuda_Sakurazaka"] = "气氛大师",
    ["~RinaMatsuda_Sakurazaka"] = "私がグランプリだらです",
    ["designer:RinaMatsuda_Sakurazaka"] = "Cassimolar",
    ["cv:RinaMatsuda_Sakurazaka"] = "松田 里奈",
    ["illustrator:RinaMatsuda_Sakurazaka"] = "Cassimolar",
    ["sakamichi_fen_wei"] = "氛围",
    [":sakamichi_fen_wei"] = "当你受到伤害时或失去体力后，你可以令一名其他角色摸两张牌并对其造成1点伤害。",
    ["@fen_wei_invoke"] = "你可以令一名其他角色摸两张牌并对其造成1点伤害",
    ["sakamichi_yong_qian"] = "勇前",
    [":sakamichi_yong_qian"] = "其他角色使用【杀】或通常锦囊牌指定你为目标后，若你不为唯一目标，你可以失去1点体力令此牌对其他目标无效。",
    ["sakamichi_lian_jian"] = "恋鉴",
    [":sakamichi_lian_jian"] = "锁定技，你的体力值大于2时性别为男性，否则为女性。",
}
