require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YasushiAkimoto = sgs.General(Sakamichi, "YasushiAkimoto", "AutisticGroup", 4, true)

--[[
    技能名：指定
    描述：出牌阶段结束时，你可以将所有手牌交给一名其他角色，然后令所有攻击范围内包含该角色的其他角色选择对其使用一张【杀】或弃置所有手牌。
]]
Luazhiding = sgs.CreateTriggerSkill {
    name = "Luazhiding",
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@zhiding_invoke", true, true)
            if target then
                room:obtainCard(target, player:wholeHandCards(), false)
                for _, p in sgs.qlist(room:getOtherPlayers(target)) do
                    if p:inMyAttackRange(target) then
                        if not room:askForUseSlashTo(p, target, "@zhiding_slash:" .. target:objectName(), true, false) then
                            p:throwAllHandCards()
                        end
                    end
                end
            end
        end
        return false
    end,
}
YasushiAkimoto:addSkill(Luazhiding)

sgs.LoadTranslationTable {
    ["YasushiAkimoto"] = "秋元 康",
    ["&YasushiAkimoto"] = "秋元 康",
    ["#YasushiAkimoto"] = "肥秋",
    ["designer:YasushiAkimoto"] = "Cassimolar",
    ["cv:YasushiAkimoto"] = "秋元 康",
    ["illustrator:YasushiAkimoto"] = "Cassimolar",
    ["Luazhiding"] = "指定",
    [":Luazhiding"] = "出牌阶段结束时，你可以将所有手牌交给一名其他角色，然后令所有攻击范围内包含该角色的其他角色选择对其使用一张【杀】或弃置所有手牌。",
    ["@zhiding_invoke"] = "你可以选择一名其他角色将所有手牌交给其以发动【指定】",
    ["@zhiding_slash"] = "请对%src 使用一张【杀】否则你弃置所有手牌",
}
