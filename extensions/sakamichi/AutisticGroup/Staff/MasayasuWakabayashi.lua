require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MasayasuWakabayashi = sgs.General(Sakamichi, "MasayasuWakabayashi", "AutisticGroup", 4, true)

--[[
    技能名：闪婚
    描述：限定技，其他女性角色回合开始时，若其体力值和手牌数均小于你，你可以与其各摸三张牌并回复1点体力，然后你可以将任意张手牌交给其，若如此做，其也可以将任意张手牌交给你。
]]
Luashanhun = sgs.CreateTriggerSkill {
    name = "Luashanhun",
    frequency = sgs.Skill_Limited,
    limit_mark = "@shanhun",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:isFemale() and player:getPhase() == sgs.Player_Start then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and p:getMark("@shanhun") ~= 0 and player:getHp() < p:getHp()
                    and player:getHandcardNum() < p:getHandcardNum()
                    and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                    p:loseMark("@shanhun")
                    room:drawCards(p, 3, self:objectName())
                    room:drawCards(player, 3, self:objectName())
                    if p:isWounded() then
                        room:recover(p, sgs.RecoverStruct(p, nil, 1))
                    end
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(p, nil, 1))
                    end
                    local cards = room:askForExchange(p, self:objectName(), p:getHandcardNum(), 1, false,
                        "@shanhun_give:" .. player:objectName(), true)
                    if cards then
                        room:obtainCard(player, cards, false)
                        local cards2 = room:askForExchange(player, self:objectName(), player:getHandcardNum(), 1, false,
                            "@shanhun_give:" .. p:objectName(), true)
                        if cards2 then
                            room:obtainCard(p, cards2, false)
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
MasayasuWakabayashi:addSkill(Luashanhun)

--[[
    技能名：认生
    描述：锁定技，其他角色对你造成伤害时，若其未对你造成过伤害，此次伤害+1，否则你可以对其使用一张【杀】。
]]
Luarensheng = sgs.CreateTriggerSkill {
    name = "Luarensheng",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from:objectName() == player:objectName() and damage.to:hasSkill(self) and damage.to:objectName()
            ~= player:objectName() then
            if damage.to:getMark(player:objectName() .. "rensheng") ~= 0 then
                room:askForUseSlashTo(damage.to, player, "@rensheng_slash:" .. player:objectName(), false, false, false)
            else
                room:setPlayerMark(damage.to, player:objectName() .. "rensheng", 1)
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MasayasuWakabayashi:addSkill(Luarensheng)

--[[
    技能名：偏心
    描述：其他女性角色回合开始时，你可以弃置一张手牌，若如此做，其本回合摸牌阶段额外摸一张牌，且其本回合出牌阶段可以额外使用一张【杀】。
]]
Luapianxin = sgs.CreateTriggerSkill {
    name = "Luapianxin",
    events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:isFemale() and player:getPhase() == sgs.Player_Start then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForDiscard(p, self:objectName(), 1, 1, true, false,
                        "@pianxin_discard:" .. player:objectName()) then
                        room:addPlayerMark(player, "&pianxin", 1)
                    end
                end
            end
        elseif event == sgs.DrawNCards then
            data:setValue(data:toInt() + player:getMark("&pianxin"))
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setPlayerMark(player, "&pianxin", 0)
                room:addSlashBuff(player, "c", 1, true)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MasayasuWakabayashi:addSkill(Luapianxin)

sgs.LoadTranslationTable {
    ["MasayasuWakabayashi"] = "若林 正恭",
    ["&MasayasuWakabayashi"] = "若林 正恭",
    ["#MasayasuWakabayashi"] = "怕生藝人",
    ["designer:MasayasuWakabayashi"] = "Cassimolar",
    ["cv:MasayasuWakabayashi"] = "若林 正恭",
    ["illustrator:MasayasuWakabayashi"] = "Cassimolar",
    ["Luashanhun"] = "闪婚",
    [":Luashanhun"] = "限定技，其他女性角色回合开始时，若其体力值和手牌数均小于你，你可以与其各摸三张牌并回复1点体力，然后你可以将任意张手牌交给其，若如此做，其也可以将任意张手牌交给你。",
    ["@shanhun"] = "闪婚",
    ["Luashanhun:invoke"] = "是否对%src发动【闪婚】",
    ["@shanhun_give"] = "你可以将任意张手牌交给%src",
    ["Luarensheng"] = "认生",
    [":Luarensheng"] = "锁定技，其他角色对你造成伤害时，若其未对你造成过伤害，此次伤害+1，否则你可以对其使用一张【杀】。",
    ["@rensheng_slash"] = "你可以对%src使用一张【杀】",
    ["Luapianxin"] = "偏心",
    [":Luapianxin"] = "其他女性角色回合开始时，你可以弃置一张手牌，若如此做，其本回合摸牌阶段额外摸一张牌，且其本回合出牌阶段可以额外使用一张【杀】。",
    ["@pianxin_discard"] = "你可以弃置一张手牌对%src发动【偏心】",
    ["pianxin"] = "偏心",
}
