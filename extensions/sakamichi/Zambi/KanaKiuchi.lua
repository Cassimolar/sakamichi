require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KanaKiuchi = sgs.General(Zambi, "KanaKiuchi", "Zambi", 4, false)
table.insert(SKMC.SanKiSei, "KanaKiuchi")

--[[
    技能名：好强
    描述：摸牌阶段，你可以放弃摸牌改为和一名其他角色拼点：若你赢，你获得其一张牌，且本回合内你的攻击范围无限；若你没赢，其摸一张牌。
]]
LuamakezugiraiCard = sgs.CreateSkillCard {
    name = "LuamakezugiraiCard",
    skill_name = "Luamakezugirai",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select)
    end,
    on_use = function(self, room, source, targets)
        local success = source:pindian(targets[1], "makezugirai", self)
        if success then
            if not targets[1]:isNude() then
                local card = room:askForCardChosen(source, targets[1], "he", "Luamakezugirai", false,
                    sgs.Card_MethodNone)
                room:obtainCard(source, card)
                room:setPlayerFlag(source, "makezugirai_success")
            end
        else
            room:drawCards(targets[1], 1, "Luamakezugirai")
        end
    end,
}
LuamakezugiraiVS = sgs.CreateOneCardViewAsSkill {
    name = "Luamakezugirai",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skillcard = LuamakezugiraiCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@Luamakezugirai") and not player:isKongcheng()
    end,
}
Luamakezugirai = sgs.CreateTriggerSkill {
    name = "Luamakezugirai",
    view_as_skill = LuamakezugiraiVS,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        if room:askForUseCard(player, "@@Luamakezugirai", "@makezugirai-card") then
            n = 0
        end
        data:setValue(n)
    end,
}
LuamakezugiraiRange = sgs.CreateAttackRangeSkill {
    name = "#LuamakezugiraiRange",
    fixed_func = function(self, player, include_weapon)
        if player:hasSkill("Luamakezugirai") and player:hasFlag("makezugirai_success") then
            return 1000
        end
        return -1
    end,
}
Zambi:insertRelatedSkills("Luamakezugirai", "#LuamakezugiraiRange")
KanaKiuchi:addSkill(Luamakezugirai)
if not sgs.Sanguosha:getSkill("#LuamakezugiraiRange") then
    SKMC.SkillList:append(LuamakezugiraiRange)
end

--[[
    技能名：执行
    描述：锁定技，若所有其他角色均在你攻击范围内，你使用的【杀】无法闪避。
]]
Luakoudouryoku = sgs.CreateTriggerSkill {
    name = "Luakoudouryoku",
    events = {sgs.SlashProceed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local effect = data:toSlashEffect()
        if effect.from:hasSkill(self) then
            local all_inMyAttackRange = true
            for _, p in sgs.qlist(room:getOtherPlayers(effect.from)) do
                if not effect.from:inMyAttackRange(p) then
                    all_inMyAttackRange = false
                    break
                end
            end
            if all_inMyAttackRange then
                room:slashResult(effect, nil)
                return true
            end
        end
        return false
    end,
}
KanaKiuchi:addSkill(Luakoudouryoku)

sgs.LoadTranslationTable {
    ["KanaKiuchi"] = "木内 加奈",
    ["&KanaKiuchi"] = "木内 加奈",
    ["#KanaKiuchi"] = "私を選んだ神器",
    ["designer:KanaKiuchi"] = "Cassimolar",
    ["cv:KanaKiuchi"] = "梅澤 美波",
    ["illustrator:KanaKiuchi"] = "Cassimolar",
    ["Luamakezugirai"] = "好强",
    [":Luamakezugirai"] = "摸牌阶段，你可以放弃摸牌改为和一名其他角色拼点：若你赢，你获得其一张牌，且本回合内你的攻击范围无限；若你没赢，其摸一张牌。",
    ["@makezugirai-card"] = "你可以放弃摸牌改为和一名其他角色拼点",
    ["~Luamakezugirai"] = "选择一张手牌 → 选择一名有手牌的其他角色 → 点击确定",
    ["Luakoudouryoku"] = "执行",
    [":Luakoudouryoku"] = "锁定技，若所有其他角色均在你攻击范围内，你使用的【杀】无法闪避。",
}
