require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinaOkamoto = sgs.General(Sakamichi, "HinaOkamoto", "Nogizaka46", 4, false)
SKMC.GoKiSei.HinaOkamoto = true
SKMC.SeiMeiHanDan.HinaOkamoto = {
    name = {8, 5, 10, 8},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "da_ji",
    },
}

sakamichi_xie_lou = sgs.CreateTriggerSkill {
    name = "sakamichi_xie_lou",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if not player:isKongcheng() and player:getPhase() == sgs.Player_Start and player:getKingdom() == "Nogizaka46"
            and SKMC.is_ki_be(player, 5) then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:showCard(p, player:getRandomHandCardId())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaOkamoto:addSkill(sakamichi_xie_lou)

sakamichi_ba_ling = sgs.CreateTriggerSkill {
    name = "sakamichi_ba_ling",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:faceUp() and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
            "invoke:" .. damage.to:objectName() .. "::" .. SKMC.number_correction(player, 1))) then
            player:turnOver()
            room:damage(sgs.DamageStruct(self:objectName(), player, damage.to, SKMC.number_correction(player, 1)))
        end
        return false
    end,
}
HinaOkamoto:addSkill(sakamichi_ba_ling)

sakamichi_ban_you = sgs.CreateTriggerSkill {
    name = "sakamichi_ban_you",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TurnedOver, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnedOver then
            if player:hasSkill(self) and not player:faceUp() then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@ban_you_invoke", true, true)
                if target then
                    room:addPlayerMark(target, "ban_you")
                    if target:isMale() then
                        local target_list = sgs.SPlayerList()
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if not p:isKongcheng() and SKMC.is_ki_be(p, 5) then
                                target_list:append(p)
                            end
                        end
                        local p = room:askForPlayerChosen(player, target_list, self:objectName(), "@ban_you_show", true,
                            true)
                        if p then
                            room:showCard(p, p:getRandomHandCardId())
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("ban_you") ~= 0 then
                        for _ = 1, p:getMark("ban_you"), 1 do
                            room:removePlayerMark(p, "ban_you")
                            p:gainAnExtraTurn()
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
HinaOkamoto:addSkill(sakamichi_ban_you)

sgs.LoadTranslationTable {
    ["HinaOkamoto"] = "岡本 姫奈",
    ["&HinaOkamoto"] = "岡本 姫奈",
    ["#HinaOkamoto"] = "最速自肃",
    ["~HinaOkamoto"] = "2秒ってスゴイ…世界記録ですかね？",
    ["designer:HinaOkamoto"] = "Cassimolar",
    ["cv:HinaOkamoto"] = "岡本 姫奈",
    ["illustrator:HinaOkamoto"] = "Cassimolar",
    ["sakamichi_xie_lou"] = "泄露",
    [":sakamichi_xie_lou"] = "锁定技，乃木坂46五期生准备阶段，你展示其一张手牌。",
    ["sakamichi_ba_ling"] = "霸凌",
    [":sakamichi_ba_ling"] = "当你造成伤害后，若你正面向上，你可以翻面对其造成1点伤害。",
    ["sakamichi_ba_ling:invoke"] = "你可以翻面对%src造成%arg点伤害",
    ["sakamichi_ban_you"] = "伴游",
    [":sakamichi_ban_you"] = "当你翻至背面向上时，你可令一名其他角色于此回合后执行一个额外的回合，若其为男性，其可以展示一名五期生的一张手牌。",
    ["@ban_you_invoke"] = "你可以令一名其他角色于此回合结束后执行一个额外的回合",
    ["@ban_you_show"] = "你可以展示一名五期生的一张手牌",
}
