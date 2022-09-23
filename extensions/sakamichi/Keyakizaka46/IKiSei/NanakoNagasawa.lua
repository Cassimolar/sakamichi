require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NanakoNagasawa = sgs.General(Sakamichi, "NanakoNagasawa", "Keyakizaka46", 3, false)
SKMC.IKiSei.NanakoNagasawa = true
SKMC.SeiMeiHanDan.NanakoNagasawa = {
    name = {8, 7, 11, 3, 9},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {23, "ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "huo",
        san_sai = "xiong",
    },
}

sakamichi_xiao_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_ji",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if (event == sgs.DamageInflicted and player:getPhase() ~= sgs.Player_NotActive)
            or (event == sgs.DamageCaused and player:getPhase() == sgs.Player_NotActive) then
            damage.damage = damage.damage - SKMC.number_correction(player, 1)
            data:setValue(damage)
            if damage.damage <= 0 then
                return true
            end
        end
        return false
    end,
}
NanakoNagasawa:addSkill(sakamichi_xiao_ji)

sakamichi_da_wei = sgs.CreateTriggerSkill {
    name = "sakamichi_da_wei",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
        end
        return false
    end,
}
NanakoNagasawa:addSkill(sakamichi_da_wei)

sakamichi_mi_lianCard = sgs.CreateSkillCard {
    name = "sakamichi_mi_lianCard",
    skill_name = "sakamichi_mi_lian",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getHandcardNum() > sgs.Self:getHandcardNum()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@mi_lian")
        local _data = sgs.QVariant()
        _data:setValue(effect.to)
        effect.from:setTag("mi_lian", _data)
        room:setPlayerFlag(effect.from, "mi_lian")
        room:drawCards(effect.from, effect.to:getHandcardNum() - effect.from:getHandcardNum(), self:getSkillName())
        if effect.to:isWounded() then
            room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
        end
    end,
}
sakamichi_mi_lian_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_mi_lian",
    view_as = function(self)
        return sakamichi_mi_lianCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@mi_lian") ~= 0
    end,
}
sakamichi_mi_lian = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_lian",
    view_as_skill = sakamichi_mi_lian_view_as,
    frequency = sgs.Skill_Limited,
    limit_mark = "@mi_lian",
    events = {sgs.EnterDying, sgs.Damage, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.damage and dying.damage.from and dying.damage.from:hasFlag("mi_lian") then
                local target = dying.damage.from:getTag("mi_lian"):toPlayer()
                if target and target:isAlive() then
                    if target:getHandcardNum() > dying.damage.from:getHandcardNum() then
                        room:drawCards(dying.damage.from, target:getHandcardNum() - dying.damage.from:getHandcardNum(),
                            self:objectName())
                    end
                    if target:isWounded() then
                        room:recover(target, sgs.RecoverStruct(dying.damage.from, nil,
                            SKMC.number_correction(dying.damage.from, 1)))
                    end
                end
            end
        elseif event == sgs.Damage then
            if player:hasSkill(self) and player:hasFlag("mi_lian") then
                room:setPlayerFlag(player, "mi_lian_damage")
            end
        else
            if player:getPhase() == sgs.Player_Finish then
                if player:hasFlag("mi_lian") then
                    if not player:hasFlag("mi_lian_damage") then
                        player:throwAllHandCards()
                        room:loseHp(player, SKMC.number_correction(player, 1))
                    else
                        room:setPlayerFlag(player, "-mi_lian_damage")
                    end
                    room:setPlayerFlag(player, "-mi_lian")
                end
                if player:getTag("mi_lian") then
                    player:removeTag("mi_lian")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanakoNagasawa:addSkill(sakamichi_mi_lian)

sgs.LoadTranslationTable {
    ["NanakoNagasawa"] = "長沢 菜々香",
    ["&NanakoNagasawa"] = "長沢 菜々香",
    ["#NanakoNagasawa"] = "消極偶像",
    ["~NanakoNagasawa"] = "２人だから大丈夫だった",
    ["designer:NanakoNagasawa"] = "Cassimolar",
    ["cv:NanakoNagasawa"] = "長沢 菜々香",
    ["illustrator:NanakoNagasawa"] = "Cassimolar",
    ["sakamichi_xiao_ji"] = "消极",
    [":sakamichi_xiao_ji"] = "锁定技，你的回合内/外，你受到/造成的伤害-1。",
    ["sakamichi_da_wei"] = "大胃",
    [":sakamichi_da_wei"] = "当你使用【桃】时，你可以摸一张牌。",
    ["sakamichi_mi_lian"] = "秘恋",
    [":sakamichi_mi_lian"] = "限定技，出牌阶段，你可以选择一名手牌比你多的角色，你将手牌数补至与其相同，并令其回复1点体力，本回合内，当你令一名角色进入濒死时可以重复此流程，若你本回合未能造成伤害，你须弃置所有手牌并失去1点体力。",
    ["@mi_lian"] = "秘恋",
}
