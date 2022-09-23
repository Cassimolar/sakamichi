require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MionaHori = sgs.General(Sakamichi, "MionaHori$", "Nogizaka46", 3, false)
SKMC.NiKiSei.MionaHori = true
SKMC.SeiMeiHanDan.MionaHori = {
    name = {11, 5, 5, 8},
    ten_kaku = {11, "ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fa_jia = sgs.CreateTriggerSkill {
    name = "sakamichi_fa_jia$",
    events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasLordSkill(self)
            and SKMC.has_specific_kingdom_player(player) then
            local list = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == player:getKingdom() then
                    list:append(p)
                end
            end
            local target = room:askForPlayerChosen(player, list, self:objectName(),
                "@fa_jia_invoke:::" .. self:objectName())
            if target then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("fa_jia" .. player:objectName()) ~= 0 then
                        room:removePlayerMark(p, "@fa_jia_target", 1)
                        room:setPlayerMark(p, "fa_jia" .. player:objectName(), 0)
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if string.find(mark, "&" .. self:objectName() .. "+") then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                    end
                end
                room:addPlayerMark(target, "@fa_jia_target", 1)
                room:setPlayerMark(target, "fa_jia" .. player:objectName(), 1)
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, self:objectName()) and player:getMark(mark) ~= 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
                if target:getArmor() then
                    room:setPlayerMark(player,
                        "&" .. self:objectName() .. "+ +noarmor+ +" .. target:getArmor():objectName(), 1)
                end
                for _, mark in sgs.list(target:getMarkNames()) do
                    if string.find(mark, self:objectName()) and target:getMark(mark) ~= 0 then
                        room:setPlayerMark(target, mark, 0)
                    end
                end
                if player:getArmor() then
                    room:setPlayerMark(target,
                        "&" .. self:objectName() .. "+ +noarmor+ +" .. player:getArmor():objectName(), 1)
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceEquip)
                or (move.from and move.from:objectName() == player:objectName()
                    and move.from_places:contains(sgs.Player_PlaceEquip))) then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("fa_jia" .. player:objectName()) ~= 0 or player:getMark("fa_jia" .. p:objectName()) ~= 0 then
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if string.find(mark, self:objectName()) and p:getMark(mark) ~= 0 then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                        if player:getArmor() then
                            room:setPlayerMark(p, "&" .. self:objectName() .. "+ +noarmor+ +"
                                .. player:getArmor():objectName(), 1)
                        end
                    end
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:hasLordSkill(self) or death.who:getMark("@fa_jia_target") ~= 0 then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getMark("fa_jia" .. death.who:objectName()) ~= 0
                        or death.who:getMark("fa_jia" .. p:objectName()) ~= 0 then
                        room:setPlayerMark(p, "fa_jia" .. death.who:objectName(), 0)
                        for _, mark in sgs.list(p:getMarkNames()) do
                            if string.find(mark, self:objectName()) and p:getMark(mark) ~= 0 then
                                room:setPlayerMark(p, mark, 0)
                            end
                        end
                        if p:getMark("@fa_jia_target") ~= 0 then
                            room:removePlayerMark(p, "@fa_jia_target", 1)
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
MionaHori:addSkill(sakamichi_fa_jia)

sakamichi_kuang_xiao = sgs.CreateTriggerSkill {
    name = "sakamichi_kuang_xiao",
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local choices = {}
        if player:isWounded() then
            table.insert(choices, "kuang_xiao_1==" .. damage.damage)
        end
        if not damage.to:isAllNude() then
            table.insert(choices, "kuang_xiao_2=" .. damage.to:objectName())
        end
        if #choices ~= 0 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                if choice == "kuang_xiao_1==" .. damage.damage then
                    room:recover(player, sgs.RecoverStruct(player, damage.card, damage.damage))
                elseif choice == "kuang_xiao_2=" .. damage.to:objectName() then
                    if (damage.to:getEquips():length() + damage.to:getHandcardNum() + damage.to:getJudgingArea()
                        :length()) > 2 then
                        for i = 1, 2, 1 do
                            local id = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false,
                                sgs.Card_MethodDiscard)
                            room:throwCard(id, damage.to, player)
                        end
                    else
                        damage.to:throwAllCards()
                    end
                    room:setEmotion(damage.to, "skill_nullify")
                    return true
                end
            end
        end
        return false
    end,
}
MionaHori:addSkill(sakamichi_kuang_xiao)

sakamichi_sang_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_sang_shi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@sang_shi",
    events = {sgs.TurnedOver, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local can = true
        if event == sgs.TurnedOver then
            if not player:faceUp() then
                can = false
            end
        end
        if can and player:getMark("@sang_shi") ~= 0 and not player:isLord() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:removePlayerMark(player, "@sang_shi")
                if not player:isAllNude() then
                    local n = player:getCards("hej"):length()
                    player:throwAllCards()
                    room:drawCards(player, n, self:objectName())
                end
                local is_secondary_hero = not (sgs.Sanguosha:getGeneral(player:getGeneralName()):hasSkill(
                    self:objectName()))
                room:changeHero(player, "minorimorozumi", false, false, is_secondary_hero)
                room:recover(player, sgs.RecoverStruct(player, nil, player:getMaxHp() - player:getHp()))
            end
        end
        return false
    end,
}
MionaHori:addSkill(sakamichi_sang_shi)

sgs.LoadTranslationTable {
    ["MionaHori"] = "堀 未央奈",
    ["&MionaHori"] = "堀 未央奈",
    ["#MionaHori"] = "谜之美少女",
    ["~MionaHori"] = "みんなより5秒くらい早く起きた",
    ["designer:MionaHori"] = "Cassimolar",
    ["cv:MionaHori"] = "堀 未央奈",
    ["illustrator:MionaHori"] = "Cassimolar",
    ["sakamichi_fa_jia"] = "发夹",
    ["#Luafajia_Armor"] = "发夹",
    [":sakamichi_fa_jia"] = "主公技，结束阶段，你可以选择一名与你势力相同的其他角色，直到你下次选择，你与其未装备防具的一方视为装备另一方装备区的防具。",
    ["@fa_jia_invoke"] = "你可以选择一名势力与你相同的角色发动【%arg】",
    ["sakamichi_kuang_xiao"] = "狂笑",
    [":sakamichi_kuang_xiao"] = "当你造成伤害时，你可以回复等量的体力值或防止该伤害然后弃置该角色区域内的两张牌。",
    ["kuang_xiao_1"] = "回复%arg点体力",
    ["kuang_xiao_2"] = "弃置%src区域内的两张牌",
    ["sakamichi_sang_shi"] = "丧尸",
    [":sakamichi_sang_shi"] = "限定技，当你武将牌翻至正面向上时或你进入濒死时，若你不为主公，你可以弃置区域内的所有牌并摸等量的牌，然后将武将牌替换为【舞いの名 - 諸積 実乃梨】并回复所有体力。",
    ["@sang_shi"] = "丧尸",
}
