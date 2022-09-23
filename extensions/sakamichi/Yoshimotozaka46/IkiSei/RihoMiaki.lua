require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RihoMiaki = sgs.General(Sakamichi, "RihoMiaki", "Yoshimotozaka46", 4, false)
table.insert(SKMC.IKiSei, "RihoMiaki")

--[[
    技能名：二进宫
    描述：限定技，一名角色的回合开始时，若你已进入过濒死，你可以失去1点体力上限并回复1点体力，然后弃置所有手牌并摸四张牌，若如此做，你须更改你的势力。
]]
Luaerjingong = sgs.CreateTriggerSkill {
    name = "Luaerjingong",
    frequency = sgs.Skill_Limited,
    limit_mark = "@erjingong",
    events = {sgs.EventPhaseStart, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("@erjingong") ~= 0 and p:getMark("erjingong_dying") ~= 0
                    and room:askForSkillInvoke(p, self:objectName(), data) then
                    p:loseMark("@erjingong")
                    room:loseMaxHp(p)
                    if p:isWounded() then
                        room:recover(p, sgs.RecoverStruct(p, nil, 1))
                    end
                    p:throwAllHandCards()
                    room:drawCards(p, 4, self:objectName())
                    room:setPlayerProperty(p, "kingdom", sgs.QVariant(room:askForKingdom(p)))
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:hasSkill(self) and dying.who:getMark("erjingong_dying") == 0 then
                room:addPlayerMark(dying.who, "erjingong_dying")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RihoMiaki:addSkill(Luaerjingong)

--[[
    技能名：婚配
    描述：限定技，出牌阶段，你可以将一张手牌交给一名势力与你相同的其他角色然后获得其一张手牌，并受到来自其的1点伤害，然后你和其各回复2点体力值，若如此做，你须将你的势力修改为“自闭群”且本局游戏的剩余时间里，其造成伤害时你可以摸1张牌，若此受伤的角色是你，则其可以回复1点体力，你回复体力时其可以使用一张【杀】。
]]
LuahunpeiCard = sgs.CreateSkillCard {
    name = "LuahunpeiCard",
    skill_name = "Luahunpei",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getKingdom() == sgs.Self:getKingdom() and to_select:objectName()
                   ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:loseMark("@hunpei")
        effect.to:obtainCard(self)
        local id = room:askForCardChosen(effect.from, effect.to, "h", "Luahunpei")
        room:obtainCard(effect.from, sgs.Sanguosha:getCard(id), room:getCardPlace(id) ~= sgs.Player_PlaceHand)
        room:damage(sgs.DamageStruct("Luahunpei", effect.to, effect.from, 1))
        if effect.from:isWounded() then
            room:recover(effect.from, sgs.RecoverStruct(effect.from, self, math.min(2, effect.from:getLostHp())))
        end
        if effect.to:isWounded() then
            room:recover(effect.to, sgs.RecoverStruct(effect.from, self, math.min(2, effect.to:getLostHp())))
        end
        room:setPlayerProperty(effect.from, "kingdom", sgs.QVariant("AutisticGroup"))
        room:setPlayerMark(effect.from, "hunpei_recover" .. effect.from:objectName() .. effect.to:objectName(), 1)
        room:setPlayerMark(effect.to, "hunpei_damage" .. effect.to:objectName() .. effect.from:objectName(), 1)
    end,
}
LuahunpeiVS = sgs.CreateOneCardViewAsSkill {
    name = "Luahunpei",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local acard = LuahunpeiCard:clone()
        acard:addSubcard(card)
        return acard
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and player:getMark("@hunpei") ~= 0
    end,
}
Luahunpei = sgs.CreateTriggerSkill {
    name = "Luahunpei",
    view_as_skill = LuahunpeiVS,
    frequency = sgs.Skill_Limited,
    limit_mark = "@hunpei",
    events = {sgs.Damage, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "hunpei_damage") and player:getMark(mark) ~= 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:getMark("hunpei_damage" .. player:objectName() .. p:objectName()) ~= 0 then
                            room:drawCards(p, 1, self:objectName())
                            if p:objectName() == damage.to:objectName() then
                                if player:isWounded() then
                                    room:recover(player, sgs.RecoverStruct(p, nil, 1))
                                end
                            end
                        end
                    end
                end
            end
        else
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "hunpei_recover") and player:getMark(mark) ~= 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:getMark("hunpei_recover" .. player:objectName() .. p:objectName()) ~= 0 then
                            room:askForUseCard(p, "slash", "@askforslash")
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
RihoMiaki:addSkill(Luahunpei)

sgs.LoadTranslationTable {
    ["RihoMiaki"] = "三秋 里歩",
    ["&RihoMiaki"] = "三秋 里歩",
    ["#RihoMiaki"] = "李婆婆",
    ["designer:RihoMiaki"] = "Cassimolar",
    ["cv:RihoMiaki"] = "三秋 里歩",
    ["illustrator:RihoMiaki"] = "Cassimolar",
    ["Luaerjingong"] = "二进宫",
    [":Luaerjingong"] = "限定技，一名角色的回合开始时，若你已进入过濒死，你可以失去1点体力上限并回复1点体力，然后弃置所有手牌并摸四张牌，若如此做，你须更改你的势力。",
    ["@erjingong"] = "二进宫",
    ["Luahunpei"] = "婚配",
    [":Luahunpei"] = "限定技，出牌阶段，你可以将一张手牌交给一名势力与你相同的其他角色然后获得其一张手牌，并受到来自其的1点伤害，然后你和其各回复2点体力值，若如此做，你须将你的势力修改为“自闭群”且本局游戏的剩余时间里，其造成伤害时你可以摸1张牌，若此受伤的角色是你，则其可以回复1点体力，你回复体力时其可以使用一张【杀】。",
    ["@hunpei"] = "婚配",
}
