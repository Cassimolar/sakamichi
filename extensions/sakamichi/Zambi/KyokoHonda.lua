require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KyokoHonda = sgs.General(Zambi, "KyokoHonda", "Zambi", 3, false)
table.insert(SKMC.SanKiSei, "KyokoHonda")

--[[
    技能名：奔放
    描述：当你使用【杀】时，若你已受伤，你可以摸一张牌然后弃置一张牌；锁定技，出牌阶段，当你使用【杀】时，若你本回合上一张使用的牌为锦囊牌，则此【杀】不计入使用次数限制；锁定技，摸牌阶段，你额外摸X张牌。（X为你已损失体力值）
]]
Luahonpou = sgs.CreateTriggerSkill {
    name = "Luahonpou",
    events = {sgs.CardUsed, sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getPhase() == sgs.Player_Play then
                if not use.card:isKindOf("SkillCard") then
                    if use.card:isKindOf("TrickCard") then
                        room:setPlayerFlag(player, "honpou")
                    else
                        room:setPlayerFlag(player, "-honpou")
                        if use.card:isKindOf("Slash") then
                            if use.m_addHistory then
                                room:addPlayerHistory(player, use.card:getClassName(), -1)
                            end
                        end
                    end
                end
            end
            if use.card:isKindOf("Slash") and player:isWounded()
                and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("@honpou_invoke")) then
                room:drawCards(player, 1, self:objectName())
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            end
        elseif event == sgs.DrawNCards then
            data:setValue(data:toInt() + player:getLostHp())
        end
        return false
    end,
}
KyokoHonda:addSkill(Luahonpou)

--[[
    技能名：归国
    描述：限定技，回合开始时/回合结束时，你可以获得场上存活角色的任意两项技能（限定技，觉醒技除外），若如此做，你失去【奔放】。
]]
Luakikoku = sgs.CreateTriggerSkill {
    name = "Luakikoku",
    frequency = sgs.Skill_Limited,
    limit_mark = "@kikoku",
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if ((event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start)
            or (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish)) and player:getMark("@kikoku")
            ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            player:loseMark("@kikoku")
            for i = 1, 2, 1 do
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@kikoku_invoke", false, true)
                if target then
                    local kikoku_skill_List = {}
                    for _, skill in sgs.qlist(target:getVisibleSkillList()) do
                        if skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited then
                            table.insert(kikoku_skill_List, skill:objectName())
                        end
                    end
                    local new_Skill = room:askForChoice(player, self:objectName(), table.concat(kikoku_skill_List, "+"))
                    room:handleAcquireDetachSkills(player, new_Skill, true)
                    local EX = sgs.Sanguosha:getTriggerSkill(new_Skill)
                    EX:trigger(sgs.GameStart, room, player, sgs.QVariant())
                end
            end
            room:handleAcquireDetachSkills(player, "-Luahonpou")
        end
        return false
    end,
}
KyokoHonda:addSkill(Luakikoku)

sgs.LoadTranslationTable {
    ["KyokoHonda"] = "本多 恭子",
    ["&KyokoHonda"] = "本多 恭子",
    ["#KyokoHonda"] = "憧れの和装",
    ["designer:KyokoHonda"] = "Cassimolar",
    ["cv:KyokoHonda"] = "吉田 綾乃クリスティー",
    ["illustrator:KyokoHonda"] = "Cassimolar",
    ["Luahonpou"] = "奔放",
    [":Luahonpou"] = "当你使用【杀】时，若你已受伤，你可以摸一张牌然后弃置一张牌；锁定技，出牌阶段，当你使用【杀】时，若你本回合上一张使用的牌为锦囊牌，则此【杀】不计入使用次数限制；锁定技，摸牌阶段，你额外摸X张牌（X为你已损失体力值）。",
    ["@honpou_invoke"] = "是否发动【奔放】摸一张牌然后弃置一张牌",
    ["Luakikoku"] = "归国",
    [":Luakikoku"] = "限定技，回合开始时/回合结束时，你可以获得场上存活角色的任意两项技能（限定技，觉醒技除外），若如此做，你失去【奔放】。",
    ["@kikoku_invoke"] = "请选择一名存活角色获得其一项技能",
    ["@kikoku"] = "归",
}
