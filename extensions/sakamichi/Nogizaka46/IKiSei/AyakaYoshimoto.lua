require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AyakaYoshimoto = sgs.General(Sakamichi, "AyakaYoshimoto", "Nogizaka46", 3, false)
SKMC.IKiSei.AyakaYoshimoto = true
SKMC.SeiMeiHanDan.AyakaYoshimoto = {
    name = {6, 5, 11, 10},
    ten_kaku = {11, "ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_wei_zhi = sgs.CreateTriggerSkill {
    name = "sakamichi_wei_zhi",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start and not player:isAllNude() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local m = player:getCards("hej"):length()
                local n = player:getHp()
                player:throwAllCards()
                room:drawCards(player, n, self:objectName())
                if math.abs(m - n) > player:getLostHp() then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if not p:isAllNude() then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@wei_zhi_invoke",
                            true, true)
                        if target then
                            local card = room:askForCardChosen(player, target, "hej", self:objectName(), false,
                                sgs.Card_MethodDiscard)
                            room:throwCard(card, target, player)
                        end
                    end
                end
            end
            return false
        end
    end,
}
AyakaYoshimoto:addSkill(sakamichi_wei_zhi)

sakamichi_yuan_c = sgs.CreateTriggerSkill {
    name = "sakamichi_yuan_c",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        local players = sgs.SPlayerList()
        if death.who:objectName() == player:objectName() then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == "Nogizaka46" then
                    players:append(p)
                else
                    local lord_skill = {}
                    for _, skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
                        if skill:isLordSkill() and not p:hasLordSkill(skill:objectName()) then
                            table.insert(lord_skill, skill:objectName())
                        end
                    end
                    if p:getGeneral2() then
                        for _, skill in sgs.qlist(p:getGeneral2():getVisibleSkillList()) do
                            if skill:isLordSkill() and not p:hasLordSkill(skill:objectName()) then
                                table.insert(lord_skill, skill:objectName())
                            end
                        end
                    end
                    if #lord_skill > 0 then
                        players:append(p)
                    end
                end
            end
            if not players:isEmpty() then
                local target = room:askForPlayerChosen(player, players, self:objectName(), "@yuan_c_invoke", true, true)
                if target then
                    local lord_skill = {}
                    for _, skill in sgs.qlist(target:getGeneral():getVisibleSkillList()) do
                        if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) then
                            table.insert(lord_skill, skill:objectName())
                        end
                    end
                    if target:getGeneral2() then
                        for _, skill in sgs.qlist(target:getGeneral2():getVisibleSkillList()) do
                            if skill:isLordSkill() and not target:hasLordSkill(skill:objectName()) then
                                table.insert(lord_skill, skill:objectName())
                            end
                        end
                    end
                    if #lord_skill > 0 then
                        room:handleAcquireDetachSkills(target, table.concat(lord_skill, "|"))
                    end
                    local lords = sgs.Sanguosha:getLords()
                    for _, p in sgs.qlist(room:getOtherPlayers(target)) do
                        table.removeOne(lords, p:getGeneralName())
                    end
                    local lord_skills = {}
                    for _, lord in ipairs(lords) do
                        local general = sgs.Sanguosha:getGeneral(lord)
                        local skills = general:getSkillList()
                        for _, skill in sgs.qlist(skills) do
                            if skill:isLordSkill() then
                                if not target:hasSkill(skill:objectName()) then
                                    table.insert(lord_skills, skill:objectName())
                                end
                            end
                        end
                    end
                    if #lord_skills > 0 then
                        local choices = table.concat(lord_skills, "+")
                        local skill_name = room:askForChoice(target, self:objectName(), choices)
                        SKMC.choice_log(target, skill_name)
                        local skill = sgs.Sanguosha:getSkill(skill_name)
                        room:acquireSkill(target, skill)
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self)
    end,
}
AyakaYoshimoto:addSkill(sakamichi_yuan_c)

sgs.LoadTranslationTable {
    ["AyakaYoshimoto"] = "吉本 彩華",
    ["&AyakaYoshimoto"] = "吉本 彩華",
    ["#AyakaYoshimoto"] = "未知",
    ["designer:AyakaYoshimoto"] = "Cassimolar",
    ["cv:AyakaYoshimoto"] = "吉本 彩華",
    ["illustrator:AyakaYoshimoto"] = "Cassimolar",
    ["sakamichi_wei_zhi"] = "未知",
    [":sakamichi_wei_zhi"] = "准备阶段，若你区域内有牌，你可以弃置你区域内所有的牌并摸取等同你体力值的牌，若你以此法弃置的牌与摸取的牌的差不小于你已损失的体力值，你可以弃置场上一张牌。",
    ["@wei_zhi_invoke"] = "你可以弃置场上的一张牌",
    ["sakamichi_yuan_c"] = "元C",
    [":sakamichi_yuan_c"] = "你死亡时可以选择一名其他乃木坂46势力角色或武将牌上有主公技的角色，若其武将牌上有主公技你令其获得之，然后令其选择并获得一个未上场或已阵亡角色的主公技。",
    ["@yuan_c_invoke"] = "你可以选择一名乃木坂46势力角色或武将牌上有主公技的角色",
}
