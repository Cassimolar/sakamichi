require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ReikaSakurai = sgs.General(Sakamichi, "ReikaSakurai", "Nogizaka46", 4, false)
SKMC.IKiSei.ReikaSakurai = true
SKMC.SeiMeiHanDan.ReikaSakurai = {
    name = {10, 4, 9, 9},
    ten_kaku = {14, "xiong"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_yuan_zhen = sgs.CreateTriggerSkill {
    name = "sakamichi_yuan_zhen",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.DamageCaused, sgs.PreHpRecover, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasSkill(self)
                and (use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack")
                    or use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace")) then
                room:setCardFlag(use.card, "yuan_zhen")
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("yuan_zhen")
                and (damage.card:isKindOf("SavageAssault") or damage.card:isKindOf("ArcheryAttack")) then
                SKMC.send_message(room, "#yuan_zhen_damage", damage.from, damage.to, nil, damage.card:toString(),
                    self:objectName(), damage.damage + 1)
                damage.damage = damage.damage + SKMC.number_correction(damage.from, 1)
                data:setValue(damage)
            end
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.card and recover.card:hasFlag("yuan_zhen") and recover.card:isKindOf("GodSalvation") then
                SKMC.send_message(room, "#yuan_zhen_recover", recover.who, player, nil, recover.card:toString(),
                    self:objectName(), recover.recover + 1)
                recover.recover = recover.recover + SKMC.number_correction(recover.who, 1)
                data:setValue(recover)
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("yuan_zhen") then
                if use.card:isKindOf("AmazingGrace") then
                    for _, p in sgs.qlist(use.to) do
                        if p:isAlive() then
                            room:drawCards(p, 1, self:objectName())
                        end
                    end
                end
                room:setCardFlag(use.card, "-yuan_zhen")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ReikaSakurai:addSkill(sakamichi_yuan_zhen)

sakamichi_dui_zhang = sgs.CreateTriggerSkill {
    name = "sakamichi_dui_zhang",
    events = {sgs.CardUsed},
    priority = {7},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if use.to:length() > 1 and room:askForSkillInvoke(p, self:objectName(), data) then
                    local choice = room:askForKingdom(p)
                    local remove_targets = sgs.SPlayerList()
                    local new_targets = sgs.SPlayerList()
                    for _, pl in sgs.qlist(use.to) do
                        if pl:getKingdom() == choice then
                            remove_targets:append(pl)
                        else
                            new_targets:append(pl)
                        end
                    end
                    if remove_targets:length() > 0 then
                        SKMC.send_message(room, "#dui_zhang_remove", p, nil, remove_targets, use.card:toString(),
                            self:objectName())
                    end
                    if new_targets:length() > 0 then
                        use.to = new_targets
                        data:setValue(use)
                    else
                        return true
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
ReikaSakurai:addSkill(sakamichi_dui_zhang)

sgs.LoadTranslationTable {
    ["ReikaSakurai"] = "桜井 玲香",
    ["&ReikaSakurai"] = "桜井 玲香",
    ["#ReikaSakurai"] = "乃团队长",
    ["~ReikaSakurai"] = "My head is popcorn",
    ["designer:ReikaSakurai"] = "Cassimolar",
    ["cv:ReikaSakurai"] = "桜井 玲香",
    ["illustrator:ReikaSakurai"] = "Cassimolar",
    ["sakamichi_yuan_zhen"] = "圆阵",
    [":sakamichi_yuan_zhen"] = "锁定技，你使用的【南蛮入侵】、【万箭齐发】造成的伤害+1；你使用的【桃园结义】回复的体力值+1；你使用的【五谷丰登】结算完成时所有目标摸一张牌。",
    ["#yuan_zhen_damage"] = "%from 的【%arg】触发，%card 对%to 造成的伤害+1，伤害量为 %arg2 点",
    ["#yuan_zhen_recover"] = "%from 的【%arg】触发，%card 对%to 造成的回复+1，回复量为 %arg2 点",
    ["sakamichi_dui_zhang"] = "队长",
    [":sakamichi_dui_zhang"] = "当一名角色使用目标多于一的通常锦囊牌或基本牌时，你可以选择一个势力，从此牌的目标中移除该势力角色。",
    ["#dui_zhang_remove"] = "%from 发动【%arg】，%to 从%card 的目标中移除",
}
