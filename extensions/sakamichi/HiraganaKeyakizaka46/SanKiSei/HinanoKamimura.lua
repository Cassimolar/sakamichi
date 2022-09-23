require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinanoKamimura_HiraganaKeyakizaka = sgs.General(Sakamichi, "HinanoKamimura_HiraganaKeyakizaka", "HiraganaKeyakizaka46",
    3, false)
table.insert(SKMC.SanKiSei, "HinanoKamimura_HiraganaKeyakizaka")

--[[
    技能名：团宠
    描述：锁定技，你不是【决斗】、拼点的合法目标。
]]
Luatuanchong = sgs.CreateProhibitSkill {
    name = "Luatuanchong",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill(self) and (card:isKindOf("FireAttack") or card:isKindOf("Duel"))
    end,
}
LuatuanchongProhibit = sgs.CreateProhibitPindianSkill {
    name = "#LuatuanchongProhibit",
    is_pindianprohibited = function(self, from, to)
        return to:hasSkill("Luatuanchong")
    end,
}
HinanoKamimura_HiraganaKeyakizaka:addSkill(Luatuanchong)
if not sgs.Sanguosha:getSkill("#LuatuanchongProhibit") then
    SKMC.SkillList:append(LuatuanchongProhibit)
end

--[[
    技能名：稚萌
    描述：出牌阶段限一次，你可以弃置一张牌或将其置于牌堆顶，若如此做，你可以获得场上至多三张牌。
]]
LuazhimengCard = sgs.CreateSkillCard {
    name = "LuazhimengCard",
    skill_name = "Luazhimeng",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        local choices = {"zhimeng_throw"}
        local targets_list = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not p:getEquips():isEmpty() or p:getJudgingArea():length() > 0 then
                targets_list:append(p)
            end
        end
        if not targets_list:isEmpty() then
            table.insert(choices, "zhimeng_top")
        end
        if room:askForChoice(source, "Luazhimeng", table.concat(choices, "+")) == "zhimeng_throw" then
            room:throwCard(self, source)
        else
            room:moveCardsInToDrawpile(source, self, self:objectName(), 1, false)
        end
        for i = 1, 3, 1 do
            if targets_list:isEmpty() then
                break
            else
                local target =
                    room:askForPlayerChosen(source, targets_list, "Luazhimeng", "@zhimeng_invoke", true, true)
                if target then
                    local card = room:askForCardChosen(source, target, "ej", "Luazhimeng", false, sgs.Card_MethodNone)
                    if card then
                        room:obtainCard(source, card)
                    end
                    if target:getEquips():isEmpty() and target:getJudgingArea():length() == 0 then
                        targets_list:removeOne(target)
                    end
                else
                    break
                end
            end
        end
    end,
}
Luazhimeng = sgs.CreateOneCardViewAsSkill {
    name = "Luazhimeng",
    filter_pattern = ".",
    view_as = function(self, card)
        local cd = LuazhimengCard:clone()
        cd:addSubcard(card:getId())
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isNude() and not player:hasUsed("#LuazhimengCard")
    end,
}
HinanoKamimura_HiraganaKeyakizaka:addSkill(Luazhimeng)

--[[
    技能名：赤食
    描述：限定技，当你进入濒死时/因自己使用的【桃】回复体力而脱离濒死时，你可以弃置一张【桃园结义】来回复X点体力/摸X张牌并回复1点体力（X为场上存活角色数）。
]]
Luachishi = sgs.CreateTriggerSkill {
    name = "Luachishi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@chishi",
    events = {sgs.EnterDying, sgs.QuitDying, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                if player:getMark("@chishi") ~= 0 then
                    room:setPlayerFlag(player, "chishi_enter")
                    local n = room:getAlivePlayers():length()
                    local card = room:askForCard(player, "GodSalvation",
                        "@chishi_invoke:::" .. room:getAlivePlayers():length(), data, self:objectName())
                    if card then
                        player:loseMark("@chishi")
                        room:recover(player, sgs.RecoverStruct(player, card, n))
                        room:setPlayerFlag(player, "-chishi_enter")
                    end
                end
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if player:hasFlag("chishi_enter") then
                if player:getHp() > 0 then
                    if recover.who and recover.who:objectName() == player:objectName() then
                        if recover.card and recover.card:isKindOf("Peach") then
                            room:setPlayerFlag(player, "chishi_2")
                        end
                    end
                    room:setPlayerFlag(player, "-chishi_enter")
                end
            end
        else
            if player:hasFlag("chishi_2") then
                if player:getMark("@chishi") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                    player:loseMark("@chishi")
                    room:drawCards(player, room:getAlivePlayers():length(), self:objectName())
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(player, nil, 1))
                    end
                end
                room:setPlayerFlag(player, "-chishi_2")
            end
        end
        return false
    end,
}
HinanoKamimura_HiraganaKeyakizaka:addSkill(Luachishi)

sgs.LoadTranslationTable {
    ["HinanoKamimura_HiraganaKeyakizaka"] = "上村 ひなの",
    ["&HinanoKamimura_HiraganaKeyakizaka"] = "上村 ひなの",
    ["#HinanoKamimura_HiraganaKeyakizaka"] = "獨苗",
    ["designer:HinanoKamimura_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:HinanoKamimura_HiraganaKeyakizaka"] = "上村 ひなの",
    ["illustrator:HinanoKamimura_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luatuanchong"] = "团宠",
    [":Luatuanchong"] = "锁定技，你不是【决斗】、拼点的合法目标。",
    ["Luazhimeng"] = "稚萌",
    [":Luazhimeng"] = "出牌阶段限一次，你可以弃置一张牌或将其置于牌堆顶，若如此做，你可以获得场上至多三张牌。",
    ["@zhimeng_invoke"] = "你可以选择一名角色获得其一张牌",
    ["zhimeng_throw"] = "弃置此牌",
    ["zhimeng_top"] = "将此牌置于牌堆顶",
    ["Luachishi"] = "赤食",
    [":Luachishi"] = "限定技，当你进入濒死时/因自己使用的【桃】回复体力而脱离濒死时，你可以弃置一张【桃园结义】来回复X点体力/摸X张牌并回复1点体力（X为场上存活角色数）。",
    ["@chishi"] = "赤食",
    ["@chishi_invoke"] = "你可以弃置一张【桃园结义】来回复%arg点体力",
}
