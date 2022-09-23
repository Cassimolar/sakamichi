require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KonokaMatsuda_HiraganaKeyakizaka = sgs.General(Sakamichi, "KonokaMatsuda_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 4,
    false)
table.insert(SKMC.NiKiSei, "KonokaMatsuda_HiraganaKeyakizaka")

--[[
    技能名：纳豆
    描述：当你回复体力时，你可以对一名其他角色造成等量伤害。
]]
Luanadou = sgs.CreateTriggerSkill {
    name = "Luanadou",
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        local recover = data:toRecover()
        local n = recover.recover
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "nadou:::" .. n,
            true, true)
        if target then
            room:damage(sgs.DamageStruct(self:objectName(), player, target, n))
        end
        return false
    end,
}
KonokaMatsuda_HiraganaKeyakizaka:addSkill(Luanadou)

--[[
    技能名：学舌
    描述：其他角色使用基本牌或通常锦囊牌结算完成时，你可以失去1点体力使用一张同名牌。
]]
Luaxueshe = sgs.CreateTriggerSkill {
    name = "Luaxueshe",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isKindOf("BasicCard") and not use.card:isKindOf("Jink"))
            or (use.card:isNDTrick() and not use.card:isKindOf("Nullification")) then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:objectName() ~= p:objectName()
                    and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:::" .. use.card:objectName())) then
                    local name = use.card:getClassName()
                    room:loseHp(p, 1)
                    room:askForUseCard(p, name, "xueshe_use:::" .. use.card:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KonokaMatsuda_HiraganaKeyakizaka:addSkill(Luaxueshe)

sgs.LoadTranslationTable {
    ["KonokaMatsuda_HiraganaKeyakizaka"] = "松田 好花",
    ["&KonokaMatsuda_HiraganaKeyakizaka"] = "松田 好花",
    ["#KonokaMatsuda_HiraganaKeyakizaka"] = "精銳",
    ["designer:KonokaMatsuda_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:KonokaMatsuda_HiraganaKeyakizaka"] = "松田 好花",
    ["illustrator:KonokaMatsuda_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luanadou"] = "纳豆",
    [":Luanadou"] = "当你回复体力时，你可以对一名其他角色造成等量伤害。",
    ["Luaxueshe"] = "学舌",
    [":Luaxueshe"] = "其他角色使用基本牌或通常锦囊牌结算完成时，你可以失去1点体力使用一张同名牌。",
    ["Luaxueshe:invoke"] = "是否失去1点体力使用一张【%arg】",
    ["xueshe_use"] = "你可以使用一张【%arg】",
}
