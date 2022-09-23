require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

TenYamasaki_Sakurazaka = sgs.General(Sakamichi, "TenYamasaki_Sakurazaka$", "Sakurazaka46", 4, false)
SKMC.NiKiSei.TenYamasaki_Sakurazaka = true
SKMC.SeiMeiHanDan.TenYamasaki_Sakurazaka = {
    name = {3, 12, 4},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {4, "xiong"},
    soto_kaku = {7, "ji"},
    sou_kaku = {19, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_mei_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_mei_yu$",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if player:getMark("mei_yu") == 0 then
                local global = {}
                for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
                    local card = sgs.Sanguosha:getEngineCard(id)
                    if card:isKindOf("GlobalEffect") or card:isKindOf("AOE") then
                        if not table.contains(global, card:objectName()) then
                            table.insert(global, card:objectName())
                        end
                    end
                end
                if #global ~= 0 then
                    local choice = room:askForChoice(player, self:objectName(), table.concat(global, "+"))
                    room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. choice, 1)
                    room:setPlayerMark(player, "mei_yu_" .. choice, 1)
                end
                room:setPlayerMark(player, "mei_yu", 1)
            end
        elseif player:getPhase() == sgs.Player_Finish then
            local pattern
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "mei_yu_") and player:getMark(mark) ~= 0 then
                    SKMC.choice_log(player, mark)
                    pattern = string.gsub(mark, "mei_yu_", "")
                    SKMC.choice_log(player, pattern)
                end
            end
            if pattern then
                local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                card:deleteLater()
                card:setSkillName(self:objectName())
                room:useCard(sgs.CardUseStruct(card, player, sgs.SPlayerList()))
            end
        end
        return false
    end,
}
TenYamasaki_Sakurazaka:addSkill(sakamichi_mei_yu)

sakamichi_hui_mu = sgs.CreateTriggerSkill {
    name = "sakamichi_hui_mu",
    hide_skill = true,
    events = {sgs.Appear},
    on_trigger = function(self, event, player, data, room)
        local current = room:getCurrent()
        if current:objectName() ~= player:objectName() and room:askForSkillInvoke(player, self:objectName(), data) then
            room:setPlayerCardLimitation(current, "use,response", "BasicCard", true)
        end
        return false
    end,
}
TenYamasaki_Sakurazaka:addSkill(sakamichi_hui_mu)

sakamichi_teng_ai = sgs.CreateTriggerSkill {
    name = "sakamichi_teng_ai",
    events = {sgs.Damaged, sgs.SlashHit, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.to:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if damage.from:objectName() ~= p:objectName() then
                        room:askForUseSlashTo(p, damage.from, "teng_ai_invoke:" .. damage.from:objectName(), false,
                            false, false, nil, nil, "teng_ai_to" .. player:objectName())
                    end
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if use.card:hasFlag("teng_ai_to" .. p:objectName()) then
                        room:setCardFlag(use.card, "-teng_ai_to" .. p:objectName())
                    end
                end
            end
        elseif event == sgs.SlashHit then
            local effect = data:toSlashEffect()
            local target
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if effect.slash:hasFlag("teng_ai_to" .. p:objectName()) then
                    target = p
                end
            end
            if target then
                room:drawCards(target, 1, self:objectName())
                if target:isWounded() then
                    room:recover(target,
                        sgs.RecoverStruct(effect.from, effect.slash, SKMC.number_correction(effect.from, 1)))
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
TenYamasaki_Sakurazaka:addSkill(sakamichi_teng_ai)

sgs.LoadTranslationTable {
    ["TenYamasaki_Sakurazaka"] = "山﨑 天",
    ["&TenYamasaki_Sakurazaka"] = "山﨑 天",
    ["#TenYamasaki_Sakurazaka"] = "蜘蛛侠",
    ["~TenYamasaki_Sakurazaka"] = "諦あないことは大事ですよね",
    ["designer:TenYamasaki_Sakurazaka"] = "Cassimolar",
    ["cv:TenYamasaki_Sakurazaka"] = "山﨑 天",
    ["illustrator:TenYamasaki_Sakurazaka"] = "Cassimolar",
    ["sakamichi_mei_yu"] = "梅雨",
    [":sakamichi_mei_yu"] = "主公技，锁定技，你的第一个准备阶段，你选择一种全局锦囊牌。结束阶段，你视为使用一张该锦囊牌。",
    ["sakamichi_hui_mu"] = "绘目",
    [":sakamichi_hui_mu"] = "隐匿技，你于其他角色是的回合登场后，你可以令其无法使用或打出基本牌直到回合结束。",
    ["sakamichi_teng_ai"] = "疼愛",
    [":sakamichi_teng_ai"] = "体力值不大于你的角色受到伤害后，若伤害来源不是你，你可以对伤害来源使用一张【杀】，若此【杀】命中，你可以摸一张牌并令其回复1点体力。",
    ["teng_ai_invoke"] = "你可以对%src使用一张【杀】",
}
