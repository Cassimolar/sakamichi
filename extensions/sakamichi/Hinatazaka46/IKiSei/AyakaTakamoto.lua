require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AyakaTakamoto_Hinatazaka = sgs.General(Sakamichi, "AyakaTakamoto_Hinatazaka", "Hinatazaka46", 4, false)
table.insert(SKMC.IKiSei, "AyakaTakamoto_Hinatazaka")

--[[
    技能名：戒酒
    描述：锁定技，你无法使用【酒】，【酒】【杀】对你造成伤害时，此伤害-X（X为此【杀】所附带的【酒】数）。
]]
Luajiejiu = sgs.CreateTriggerSkill {
    name = "Luajiejiu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
            room:setPlayerCardLimitation(player, "use", "Analeptic", false)
        elseif event == sgs.EventLoseSkill then
            room:removePlayerCardLimitation(player, "use", "Analeptic$0")
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("drank") then
                damage.damage = damage.damage - damage.card:getTag("drank"):toInt()
                local msg = sgs.LogMessage()
                msg.type = "#jiejiu"
                msg.from = damage.from
                msg.to:append(player)
                msg.arg = damage.card:getTag("drank"):toInt()
                room:sendLog(msg)
                data:setValue(damage)
            end
        end
        return false
    end,
}
AyakaTakamoto_Hinatazaka:addSkill(Luajiejiu)

--[[
    技能名：名媛
    描述：出牌阶段限一次，你可以交给一名其他角色两张手牌并获得其装备区的一张装备牌，本回合内你使用此装备牌后此技能视为未发动过。
]]
LuamingyuanCard = sgs.CreateSkillCard {
    name = "LuamingyuanCard",
    skill_name = "Luamingyuan",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets ~= 0 then
            return false
        end
        return to_select:objectName() ~= sgs.Self:objectName() and not to_select:getEquips():isEmpty()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self, false)
        local id = room:askForCardChosen(effect.from, effect.to, "e", self:objectName(), true, sgs.Card_MethodNone)
        if id then
            room:obtainCard(effect.from, id)
            room:setPlayerFlag(effect.from, "mingyuan" .. id)
            room:setPlayerFlag(effect.from, "mingyuan_used")
        end
    end,
}
LuamingyuanVS = sgs.CreateViewAsSkill {
    name = "Luamingyuan",
    n = 2,
    view_filter = function(self, selected, to_select)
        if (#selected > 1) or sgs.Self:isJilei(to_select) then
            return false
        end
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards ~= 2 then
            return nil
        end
        cd = LuamingyuanCard:clone()
        cd:addSubcard(cards[1])
        cd:addSubcard(cards[2])
        return cd
    end,
    enabled_at_play = function(self, target)
        return (target:getHandcardNum() >= 2) and (not target:hasFlag("mingyuan_used"))
    end,
}
Luamingyuan = sgs.CreateTriggerSkill {
    name = "Luamingyuan",
    view_as_skill = LuamingyuanVS,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("EquipCard") then
            if player:hasFlag("mingyuan" .. use.card:getId()) then
                room:setPlayerFlag(player, "-mingyuan_used")
                room:setPlayerFlag(player, "-mingyuan" .. use.card:getId())
            end
        end
        return false
    end,
}
AyakaTakamoto_Hinatazaka:addSkill(Luamingyuan)

--[[
    技能名：美妆
    描述：当一名角色使用装备牌时，你可以令其摸一张牌，然后其可以使用一张【杀】。
]]
Luameizhuang = sgs.CreateTriggerSkill {
    name = "Luameizhuang",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("EquipCard") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                    room:askForUseCard(player, "slash", "@askforslash")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
AyakaTakamoto_Hinatazaka:addSkill(Luameizhuang)

sgs.LoadTranslationTable {
    ["AyakaTakamoto_Hinatazaka"] = "高本 彩花",
    ["&AyakaTakamoto_Hinatazaka"] = "高本 彩花",
    ["#AyakaTakamoto_Hinatazaka"] = "笨蛋名模",
    ["designer:AyakaTakamoto_Hinatazaka"] = "Cassimolar",
    ["cv:AyakaTakamoto_Hinatazaka"] = "高本 彩花",
    ["illustrator:AyakaTakamoto_Hinatazaka"] = "Cassimolar",
    ["Luajiejiu"] = "戒酒",
    [":Luajiejiu"] = "锁定技，你无法使用【酒】，【酒】【杀】对你造成伤害时，此伤害-X（X为此【杀】所附带的【酒】数）。",
    ["#jiejiu"] = "%to 的【戒酒】被触发，%from 的此张【<font color=\"yellow\"><b>杀</b></font>】对 %to 造成的伤害减少<font color=\"yellow\"><b>%arg</b></font>点。",
    ["Luamingyuan"] = "名媛",
    [":Luamingyuan"] = "出牌阶段限一次，你可以交给一名其他角色两张手牌并获得其装备区的一张装备牌，本回合内你使用此装备牌后此技能视为未发动过。",
    ["Luameizhuang"] = "美妆",
    [":Luameizhuang"] = "当一名角色使用装备牌时，你可以令其摸一张牌，然后其可以使用一张【杀】。",
    ["Luameizhuang:invoke"] = "你可以令%src摸一张牌并可以使用一张【杀】",
}
