require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MihoWatanabe_HiraganaKeyakizaka = sgs.General(Sakamichi, "MihoWatanabe_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.NiKiSei, "MihoWatanabe_HiraganaKeyakizaka")

--[[
    技能名：三分
    描述：当你一次对一名角色造成不少于两点伤害时，你可以进行一次判定：若点数大于3，你选择一项：1.令此伤害+1 2.回复1点体力。
]]
Luathreepoints = sgs.CreateTriggerSkill {
    name = "Luathreepoints",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.damage >= 2 and room:askForSkillInvoke(player, self:objectName(), data) then
            local judge = sgs.JudgeStruct()
            judge.pattern = ".|.|4~13"
            judge.good = true
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            if judge:isGood() then
                local msg = sgs.LogMessage()
                msg.type = "#threepoints"
                msg.from = player
                if room:askForChoice(player, self:objectName(), "threepoints_damage+threepoints_recover")
                    == "threepoints_damage" then
                    msg.arg = "threepoints_damage"
                    room:sendLog(msg)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                elseif player:isWounded() then
                    msg.arg = "threepoints_recover "
                    room:sendLog(msg)
                    room:recover(player, sgs.RecoverStruct(player, nil, 1))
                end
            end
        end
        return false
    end,
}
MihoWatanabe_HiraganaKeyakizaka:addSkill(Luathreepoints)

--[[
    技能名：绝杀
    描述：限定技，当你进入濒死状态时，你可以进行一次判定：若花色为♠，你对一名其他角色造成2点伤害；若花色为♥，你回复2点体力；若为其他花色，你视为使用一张基本牌。
]]
Lualore = sgs.CreateTriggerSkill {
    name = "Lualore",
    frequency = sgs.Skill_Limited,
    limit_mark = "@lore",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if player:getMark("@lore") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            player:loseMark("@lore")
            local judge = sgs.JudgeStruct()
            judge.pattern = "."
            judge.good = true
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            if judge.card:getSuit() == sgs.Card_Spade then
                room:damage(sgs.DamageStruct(self:objectName(), player, room:askForPlayerChosen(player,
                    room:getOtherPlayers(player), self:objectName(), "@lore_invoke", false, true), 2))
            elseif judge.card:getSuit() == sgs.Card_Heart then
                if player:isWounded() then
                    room:recover(player, sgs.RecoverStruct(player, nil, 2))
                end
            else
                local basic = {"slash", "peach"}
                if not (SKMC.set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
                    table.insert(basic, 3, "analeptic")
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(basic, "+"))
                local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, -1)
                card:setSkillName(self:objectName())
                if choice == "slash" then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:canSlash(p, card, true) and not sgs.Sanguosha:isProhibited(player, p, card) then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        room:useCard(sgs.CardUseStruct(card, player, room:askForPlayerChosen(player, targets,
                            self:objectName(), "@lore_slash", false, false)))
                    end
                else
                    if not sgs.Sanguosha:isProhibited(player, player, card) then
                        room:useCard(sgs.CardUseStruct(card, player, player))
                    end
                end
            end
        end
        return false
    end,
}
MihoWatanabe_HiraganaKeyakizaka:addSkill(Lualore)

sgs.LoadTranslationTable {
    ["MihoWatanabe_HiraganaKeyakizaka"] = "渡邉 美穂",
    ["&MihoWatanabe_HiraganaKeyakizaka"] = "渡邉 美穂",
    ["#MihoWatanabe_HiraganaKeyakizaka"] = "籃網殺手",
    ["designer:MihoWatanabe_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MihoWatanabe_HiraganaKeyakizaka"] = "渡邉 美穂",
    ["illustrator:MihoWatanabe_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luathreepoints"] = "三分",
    [":Luathreepoints"] = "当你一次对一名角色造成不少于两点伤害时，你可以进行一次判定：若点数大于3，你选择一项：1.令此伤害+1；2.回复1点体力。",
    ["Lualore"] = "绝杀",
    [":Lualore"] = "限定技，当你进入濒死状态时，你可以进行一次判定：若花色为♠，你对一名其他角色造成2点伤害；若花色为♥，你回复2点体力；若为其他花色，你视为使用一张基本牌。",
    ["@lore"] = "绝杀",
    ["threepoints_damage"] = "令此伤害+1",
    ["threepoints_recover"] = "回复1点体力",
    ["#threepoints"] = "%from选择了%arg",
    ["@lore_invoke"] = "请选择一名其他角色对其造成2点伤害",
    ["@lore_slash"] = "请选择此【杀】的目标",
}
