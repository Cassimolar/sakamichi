require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YukiHimura = sgs.General(Sakamichi, "YukiHimura$", "AutisticGroup", 3, true)

--[[
    技能名：不动C
    描述：主公技，锁定技，你获得“S”标记时获得【撸胸】和【替身】，你失去“S”标记时失去【撸胸】和【替身】。
]]
Lua17thCenter = sgs.CreateTriggerSkill {
    name = "Lua17thCenter$",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == "@beiS" then
            if player:getMark("@beiS") ~= 0 then
                room:handleAcquireDetachSkills(player, "Lualuxiong|Luatishen")
            else
                room:handleAcquireDetachSkills(player, "-Lualuxiong|-Luatishen", true)
            end
        end
    end,
}
YukiHimura:addSkill(Lua17thCenter)

--[[
    技能名：被S
    描述：当你受到【杀】的伤害时，若你没有“S”标记，你可以防止此伤害然后获得“S”标记，你的回合开始时，清除你所有“S”标记。
]]
LuabeiS = sgs.CreateTriggerSkill {
    name = "LuabeiS",
    events = {sgs.DamageInflicted, sgs.EventPhaseStart, sgs.EventLoseSkill},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted and player:hasSkill(self) then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and player:getMark("@beiS") == 0 then
                if player:askForSkillInvoke(self:objectName()) then
                    player:gainMark("@beiS")
                    return true
                end
            end
        elseif event == sgs.EventPhaseStart and player:hasSkill(self) then
            if player:getPhase() == sgs.Player_RoundStart then
                player:loseAllMarks("@beiS")
                return false
            end
        elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
            player:loseAllMarks("@beiS")
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YukiHimura:addSkill(LuabeiS)

--[[
    技能名：日村赏
    描述：出牌阶段限一次，你可以弃置至多三张牌，然后令一名其他角色摸等量的牌。若你以此法弃置三张同一类别的牌，你回复1点体力。
]]
LuahimurashoCard = sgs.CreateSkillCard {
    name = "LuahimurashoCard",
    skill_name = "Luahimurasho",
    filter = function(self, selected, to_select)
        return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
    end,
    on_effect = function(self, effect)
        local n = self:subcardsLength()
        effect.to:drawCards(n)
        local room = effect.from:getRoom()
        if n == 3 then
            local thetype = nil
            for _, card_id in sgs.qlist(effect.card:getSubcards()) do
                if thetype == nil then
                    thetype = sgs.Sanguosha:getCard(card_id):getTypeId()
                elseif sgs.Sanguosha:getCard(card_id):getTypeId() ~= thetype then
                    return false
                end
            end
            room:recover(effect.from, sgs.RecoverStruct(effect.from, self))
        end
    end,
}
Luahimurasho = sgs.CreateViewAsSkill {
    name = "Luahimurasho",
    n = 3,
    view_filter = function(self, selected, to_select)
        return (#selected < 3) and (not sgs.Self:isJilei(to_select))
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local card = LuahimurashoCard:clone()
        for _, c in ipairs(cards) do
            card:addSubcard(c)
        end
        return card
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "he") and (not player:hasUsed("#LuahimurashoCard"))
    end,
}
YukiHimura:addSkill(Luahimurasho)

sgs.LoadTranslationTable {
    ["YukiHimura"] = "日村 勇紀",
    ["&YukiHimura"] = "日村 勇紀",
    ["#YukiHimura"] = "日村子",
    ["designer:YukiHimura"] = "Cassimolar",
    ["cv:YukiHimura"] = "日村 勇紀",
    ["illustrator:YukiHimura"] = "Cassimolar",
    ["Lua17thCenter"] = "不动C",
    [":Lua17thCenter"] = "主公技，锁定技，你获得“S”标记时获得【撸胸】和【替身】，你失去“S”标记时失去【撸胸】和【替身】。",
    ["LuabeiS"] = "被S",
    [":LuabeiS"] = "当你受到【杀】的伤害时，若你没有“S”标记，你可以防止此伤害然后获得一枚“S”标记，你的回合开始时，清除你所有“S”标记。",
    ["@beiS"] = "S",
    ["Luahimurasho"] = "日村赏",
    [":Luahimurasho"] = "出牌阶段限一次，你可以弃置至多三张牌，然后令一名其他角色摸等量的牌。若你以此法弃置三张同一类别的牌，你回复1点体力。",
}
