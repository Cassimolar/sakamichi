require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinaKawaai = sgs.General(Sakamichi, "HinaKawaai", "AutisticGroup", 3, false)
table.insert(SKMC.IKiSei, "HinaKawaai")

--[[
    技能名：腹黑
    描述：出牌阶段限一次，你可以弃置一张手牌并选择一名其他角色对其造成1点伤害，然后其选择交给你一张与你弃置的牌花色/点数/类型相同的手牌并回复1点体力或获得你弃置的牌并流失1点体力。
]]
LuafuheiCard = sgs.CreateSkillCard {
    name = "LuafuheiCard",
    skill_name = "Luafuhei",
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:damage(sgs.DamageStruct("Luafuhei", source, targets[1]))
        local types = ""
        if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("BasicCard") then
            types = "BasicCard"
        elseif sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("TrickCard") then
            types = "TrickCard"
        elseif sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("EquipCard") then
            types = "EquipCard"
        end
        local choices = {}
        if not targets[1]:isKongcheng() then
            table.insert(choices, "givecard")
        end
        table.insert(choices, "obtaincard")
        local choice = room:askForChoice(targets[1], "Luafuhei", table.concat(choices, "+"))
        if choice == "givecard" then
            local card = room:askForCard(targets[1],
                types .. "|.|.|hand#.|" .. sgs.Sanguosha:getCard(self:getSubcards():first()):getSuitString()
                    .. "|.|hand#.|.|" .. sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() .. "|hand",
                "@fuhei-ask:" .. source:objectName() .. ":" .. types .. ":"
                    .. sgs.Sanguosha:getCard(self:getSubcards():first()):getSuitString() .. ":"
                    .. sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber(), sgs.QVariant(),
                sgs.Card_MethodNone)
            if card then
                room:obtainCard(source, card)
                room:recover(targets[1], sgs.RecoverStruct(source, self))
            else
                room:obtainCard(targets[1], self)
                room:loseHp(targets[1])
            end
        else
            room:obtainCard(targets[1], self)
            room:loseHp(targets[1])
        end
    end,
}
Luafuhei = sgs.CreateViewAsSkill {
    name = "Luafuhei",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 1 then
            local card = LuafuheiCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        if not player:isKongcheng() then
            return not player:hasUsed("#LuafuheiCard")
        end
        return false
    end,
}
HinaKawaai:addSkill(Luafuhei)

--[[
    技能名：二次元
    描述：当你令其他角色进入濒死时，你可以失去1点体力上限并从随机五个未上场的武将的技能选择并获得一个；当你处于濒死时，你可以失去一个技能并增加1点体力上限。
]]
Luamote = sgs.CreateTriggerSkill {
    name = "Luamote",
    events = {sgs.EnterDying, sgs.Dying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if event == sgs.EnterDying then
            if dying.damage then
                local killer = dying.damage.from
                if killer and killer:hasSkill(self) then
                    if room:askForSkillInvoke(killer, self:objectName(), data) then
                        room:loseMaxHp(killer)
                        local allnames = sgs.Sanguosha:getLimitedGeneralNames()
                        local allplayers = room:getAllPlayers()
                        for _, p in sgs.qlist(allplayers) do
                            local name = p:getGeneralName()
                            table.removeOne(allnames, name)
                        end
                        local targets = {}
                        for i = 1, 5, 1 do
                            local count = #allnames
                            local index = math.random(1, count)
                            local selected = allnames[index]
                            table.insert(targets, selected)
                            table.removeOne(allnames, selected)
                        end
                        local generals = table.concat(targets, "+")
                        local general = room:askForGeneral(killer, generals)
                        local target = sgs.Sanguosha:getGeneral(general)
                        local skills = target:getVisibleSkillList()
                        local skillnames = {}
                        for _, skill in sgs.qlist(skills) do
                            if not skill:inherits("SPConvertSkill") then
                                local skillname = skill:objectName()
                                table.insert(skillnames, skillname)
                            end
                        end
                        local choices = table.concat(skillnames, "+")
                        local skill = room:askForChoice(killer, self:objectName(), choices)
                        room:handleAcquireDetachSkills(killer, skill, true)
                    end
                end
            end
        else
            if dying.who:hasSkill(self) then
                if room:askForSkillInvoke(dying.who, self:objectName(), data) then
                    local skills = dying.who:getVisibleSkillList()
                    local skillnames = {}
                    for _, skill in sgs.qlist(skills) do
                        if not skill:inherits("SPConvertSkill") then
                            local skillname = skill:objectName()
                            table.insert(skillnames, skillname)
                        end
                    end
                    local choices = table.concat(skillnames, "+")
                    local skill = room:askForChoice(dying.who, self:objectName(), choices)
                    room:handleAcquireDetachSkills(dying.who, "-" .. skill, true)
                    room:gainMaxHp(dying.who)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaKawaai:addSkill(Luamote)

--[[
    技能名：青春女子学園
    描述：当一名角色获得/失去技能时你可以令其摸一张牌/回复1点体力。
]]
HinaKawaai:addSkill("Luaseishu")

sgs.LoadTranslationTable {
    ["HinaKawaai"] = "川相 陽菜",
    ["&HinaKawaai"] = "川相 陽菜",
    ["#HinaKawaai"] = "魔法少女",
    ["designer:HinaKawaai"] = "Cassimolar",
    ["cv:HinaKawaai"] = "川後 陽菜",
    ["illustrator:HinaKawaai"] = "Cassimolar",
    ["Luafuhei"] = "腹黑",
    [":Luafuhei"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名其他角色对其造成1点伤害，然后其选择交给你一张与你弃置的牌花色/点数/类型相同的手牌并回复1点体力或获得你弃置的牌并流失1点体力。",
    ["Luafuhei:givecard"] = "交出一张手牌",
    ["Luafuhei:obtaincard"] = "获得被弃置的牌",
    ["@fuhei-ask"] = "请交给%src 一张%dest 或花色为%arg 或点数为%arg2 的手牌",
    ["Luamote"] = "二次元",
    [":Luamote"] = "当你令其他角色进入濒死时，你可以失去1点体力上限并从随机五个未上场的武将的技能选择并获得一个；当你处于濒死时，你可以失去一个技能并增加1点体力上限。",
}
