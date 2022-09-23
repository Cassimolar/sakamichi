require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YumikoSeki_Sakurazaka = sgs.General(Sakamichi, "YumikoSeki_Sakurazaka", "Sakurazaka46", 4, false, false, false, 3)
SKMC.NiKiSei.YumikoSeki_Sakurazaka = true
SKMC.SeiMeiHanDan.YumikoSeki_Sakurazaka = {
    name = {14, 6, 9, 3},
    ten_kaku = {14, "xiong"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {18, "ji"},
    soto_kaku = {26, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_su_mian = sgs.CreateTriggerSkill {
    name = "sakamichi_su_mian",
    events = {sgs.DamageCaused, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.to:objectName() ~= player:objectName() and player:faceUp()
                and room:askForSkillInvoke(player, self:objectName(), data) then
                player:turnOver()
                damage.damage = damage.damage + SKMC.number_correction(player, 1)
                data:setValue(damage)
                if damage.to:getHp() >= player:getHp() then
                    local card = room:askForCard(player, ".|.|.|hand,equipped",
                        "@su_mian_give:" .. damage.to:objectName(), data, sgs.Card_MethodNone)
                    if card then
                        damage.to:obtainCard(card)
                        damage.to:turnOver()
                    end
                end
            end
        else
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() ~= player:objectName() and player:faceUp()
                and room:askForSkillInvoke(player, self:objectName(), data) then
                player:turnOver()
                if damage.from:getHp() >= player:getHp() then
                    local card = room:askForCard(player, ".|.|.|hand,equipped",
                        "@su_mian_give:" .. damage.from:objectName(), data, sgs.Card_MethodNone)
                    if card then
                        damage.from:obtainCard(card)
                        damage.from:turnOver()
                    end
                end
                return true
            end
        end
        return false
    end,
}
YumikoSeki_Sakurazaka:addSkill(sakamichi_su_mian)

sakamichi_xiong_baoCard = sgs.CreateSkillCard {
    name = "sakamichi_xiong_baoCard",
    skill_name = "sakamichi_xiong_bao",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:isWounded()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
        room:setPlayerFlag(effect.from, "xiong_bao_" .. effect.to:objectName())
    end,
}
sakamichi_xiong_bao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_xiong_bao",
    view_as = function(self)
        return sakamichi_xiong_baoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_xiong_baoCard")
    end,
}
sakamichi_xiong_bao = sgs.CreateTriggerSkill {
    name = "sakamichi_xiong_bao",
    view_as_skill = sakamichi_xiong_bao_view_as,
    events = {sgs.ConfirmDamage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if player:hasFlag("xiong_bao_" .. damage.to:objectName()) then
            damage.nature = sgs.DamageStruct_Fire
            data:setValue(damage)
        end
        return false
    end,
}
YumikoSeki_Sakurazaka:addSkill(sakamichi_xiong_bao)

sakamichi_jiao_xiCard = sgs.CreateSkillCard {
    name = "sakamichi_jiao_xiCard",
    skill_name = "sakamichi_jiao_xi",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and sgs.Self:inMyAttackRange(to_select)
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@jiao_xi")
        room:setPlayerFlag(effect.from, "jiao_xi" .. effect.to:objectName())
        room:addPlayerMark(effect.to, "@skill_invalidity")
    end,
}
sakamichi_jiao_xi_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jiao_xi",
    filter_pattern = "EquipCard",
    view_as = function(self, card)
        local skillcard = sakamichi_jiao_xiCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@jiao_xi") ~= 0
    end,
}
sakamichi_jiao_xi = sgs.CreateTriggerSkill {
    name = "sakamichi_jiao_xi",
    view_as_skill = sakamichi_jiao_xi_view_as,
    frequency = sgs.Skill_Limited,
    limit_mark = "@jiao_xi",
    events = {sgs.CardUsed, sgs.EnterDying, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if player:hasFlag("jiao_xi" .. p:objectName()) then
                        room:damage(sgs.DamageStruct(use.card, player, p, SKMC.number_correction(player, 1)))
                    end
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasFlag("jiao_xi" .. player:objectName()) then
                        room:setPlayerFlag(p, "-jiao_xi" .. player:objectName())
                        room:removePlayerMark(player, "@skill_invalidity")
                    end
                end
            end
        elseif player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:hasFlag("jiao_xi" .. p:objectName()) then
                    room:setPlayerFlag(player, "-jiao_xi" .. p:objectName())
                    room:removePlayerMark(p, "@skill_invalidity")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoSeki_Sakurazaka:addSkill(sakamichi_jiao_xi)

sgs.LoadTranslationTable {
    ["YumikoSeki_Sakurazaka"] = "関 有美子",
    ["&YumikoSeki_Sakurazaka"] = "関 有美子",
    ["#YumikoSeki_Sakurazaka"] = "令和一休",
    ["~YumikoSeki_Sakurazaka"] = "眠いからー旦抜けて寝るわ",
    ["designer:YumikoSeki_Sakurazaka"] = "Cassimolar",
    ["cv:YumikoSeki_Sakurazaka"] = "関 有美子",
    ["illustrator:YumikoSeki_Sakurazaka"] = "Cassimolar",
    ["sakamichi_su_mian"] = "速眠",
    [":sakamichi_su_mian"] = "当你对其他角色造成伤害时/受到其他角色造成的伤害时，若你的武将牌正面向上，你可以将武将牌翻面，令此次伤害+1/防止此伤害，然后若其体力值不小于你，你可以交给其一张牌令其武将牌翻面。",
    ["@su_mian_give"] = "你可以将一张牌交给%src令其武将牌翻面",
    ["sakamichi_xiong_bao"] = "熊抱",
    [":sakamichi_xiong_bao"] = "出牌阶段限一次，你可以令一名其他角色回复1点体力，若如此做，本回合内，你对其造成的所有伤害均为火焰伤害。",
    ["sakamichi_jiao_xi"] = "绞袭",
    [":sakamichi_jiao_xi"] = "限定技，出牌阶段，你可以弃置一张装备牌并选择一名攻击范围内的其他角色，本回合内，其非锁定技无效，且当你使用一张牌时，对其造成1点伤害，直至其进入濒死。",
    ["@jiao_xi"] = "绞袭",
}
