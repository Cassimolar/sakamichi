require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SakuraEndo = sgs.General(Sakamichi, "SakuraEndo$", "Nogizaka46", 3, false)
SKMC.YonKiSei.SakuraEndo = true
SKMC.SeiMeiHanDan.SakuraEndo = {
    name = {13, 18, 3, 1, 3},
    ten_kaku = {31, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {7, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_ye_ming_card = sgs.CreateSkillCard {
    name = "sakamichi_ye_mingCard",
    skill_name = "sakamichi_ye_ming",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName() and to_select:getKingdom() == "Nogizaka46"
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local num = SKMC.number_correction(effect.from, 1)
        room:addPlayerMark(effect.to, "ye_ming_draw_end_clear", num)
        room:addMaxCards(effect.from, -num)
    end,
}
sakamichi_ye_ming_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ye_ming",
    view_as = function()
        return sakamichi_ye_ming_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_ye_mingCard")
    end,
}
sakamichi_ye_ming = sgs.CreateTriggerSkill {
    name = "sakamichi_ye_ming$",
    view_as_skill = sakamichi_ye_ming_view_as,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        data:setValue(n + player:getMark("ye_ming_draw_end_clear"))
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_ye_ming_max_cards = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_ye_ming_max_cards",
    extra_func = function(self, target)
        if target:hasSkill("sakamichi_ye_ming") then
            local extra = 1
            for _, p in sgs.qlist(target:getSiblings()) do
                if p:isAlive() and p:getKingdom() == "Nogizaka46" then
                    extra = extra + 1
                end
            end
            return extra
        end
        return 0
    end,
}
SakuraEndo:addSkill(sakamichi_ye_ming)
if not sgs.Sanguosha:getSkill("#sakamichi_ye_ming_max_cards") then
    SKMC.SkillList:append(sakamichi_ye_ming_max_cards)
end

sakamichi_luo_lei = sgs.CreateTriggerSkill {
    name = "sakamichi_luo_lei",
    frequency = sgs.Skill_Limited,
    limit_mark = "@luo_lei",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start and player:getMark("@luo_lei") ~= 0
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:removePlayerMark(player, "@luo_lei", 1)
            local lord_list = {}
            local lord_skills = {}
            for _, lord in ipairs(sgs.Sanguosha:getLords()) do
                if sgs.Sanguosha:getGeneral(lord):getKingdom() == "Nogizaka46" then
                    table.insert(lord_list, lord)
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                table.removeOne(lord_list, p:getGeneralName())
                table.removeOne(lord_list, p:getGeneral2Name())
            end
            if #lord_list ~= 0 then
                for _, lord in ipairs(lord_list) do
                    for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(lord):getSkillList()) do
                        if skill:isLordSkill() and not player:hasSkill(skill:objectName())
                            and not table.contains(lord_skills, skill:objectName()) then
                            table.insert(lord_skills, skill:objectName())
                        end
                    end
                end
                if #lord_skills ~= 0 then
                    local skill = sgs.Sanguosha:getSkill(room:askForChoice(player, self:objectName(),
                        table.concat(lord_skills, "+")))
                    room:handleAcquireDetachSkills(player, skill:objectName())
                end
            end
        end
        return false
    end,
}
SakuraEndo:addSkill(sakamichi_luo_lei)

sakamichi_chuan_cheng_card = sgs.CreateSkillCard {
    name = "sakamichi_chuan_chengCard",
    skill_name = "sakamichi_chuan_cheng",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getKingdom() ~= "Nogizaka46"
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local choices = {}
        if not effect.to:isKongcheng() then
            table.insert(choices, "chuan_cheng_1=" .. effect.to:objectName())
        end
        table.insert(choices,
            "chuan_cheng_2=" .. effect.to:objectName() .. "=" .. SKMC.number_correction(effect.from, 1))
        local choice = room:askForChoice(effect.from, self:getSkillName(), table.concat(choices, "+"))
        if choice == "chuan_cheng_1=" .. effect.to:objectName() then
            room:showAllCards(effect.to, effect.from)
        else
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to,
                SKMC.number_correction(effect.from, 1)))
        end
    end,
}
sakamichi_chuan_cheng = sgs.CreateTriggerSkill {
    name = "sakamichi_chuan_cheng",
    shiming_skill = true,
    events = {sgs.EventPhaseProceeding, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:hasSkill(self) and player:getMark(self:objectName()) == 0 and player:getPhase()
                == sgs.Player_Finish then
                local target_list = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getKingdom() ~= "Nogizaka46" then
                        target_list:append(p)
                    end
                end
                if target_list:length() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                    local target = room:askForPlayerChosen(player, target_list, self:objectName())
                    local choices = {}
                    if not target:isKongcheng() then
                        table.insert(choices, "chuan_cheng_1=" .. target:objectName())
                    end
                    table.insert(choices,
                        "chuan_cheng_2=" .. target:objectName() .. "=" .. SKMC.number_correction(player, 1))
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                    if choice == "chuan_cheng_1=" .. target:objectName() then
                        room:showAllCards(target, player)
                    else
                        room:damage(sgs.DamageStruct(self:objectName(), player, target,
                            SKMC.number_correction(player, 1)))
                    end
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who and dying.who:objectName() == player:objectName() and player:hasSkill(self)
                and player:getMark(self:objectName()) == 0 and dying.damage and dying.damage.from and dying.damage.from
                and dying.damage.from:objectName() ~= player:objectName() and dying.damage.from:getKingdom()
                == "Nogizaka46" then
                local detachList = {}
                for _, skill in sgs.qlist(player:getVisibleSkillList()) do
                    if skill:isLordSkill() then
                        table.insert(detachList, "-" .. skill:objectName())
                    end
                end
                room:sendShimingLog(player, self, false)
                room:handleAcquireDetachSkills(player, table.concat(detachList, "|"))
            end
            if dying.who and dying.who:objectName() == player:objectName() and player:getKingdom() == "Nogizaka46" then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark(self:objectName()) == 0 and player:objectName() ~= p:objectName() then
                        room:sendShimingLog(p, self)
                        for i = 1, 2, 1 do
                            local lord_list = {}
                            local lord_skills = {}
                            for _, lord in ipairs(sgs.Sanguosha:getLords()) do
                                if sgs.Sanguosha:getGeneral(lord):getKingdom() == "Nogizaka46" then
                                    table.insert(lord_list, lord)
                                end
                            end
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                table.removeOne(lord_list, p:getGeneralName())
                                table.removeOne(lord_list, p:getGeneral2Name())
                            end
                            if #lord_list ~= 0 then
                                for _, lord in ipairs(lord_list) do
                                    for _, skill in sgs.qlist(sgs.Sanguosha:getGeneral(lord):getSkillList()) do
                                        if skill:isLordSkill() and not p:hasSkill(skill:objectName())
                                            and not table.contains(lord_skills, skill:objectName()) then
                                            table.insert(lord_skills, skill:objectName())
                                        end
                                    end
                                end
                                if #lord_skills ~= 0 then
                                    local skill = sgs.Sanguosha:getSkill(
                                        room:askForChoice(p, self:objectName(), table.concat(lord_skills, "+")))
                                    room:handleAcquireDetachSkills(p, skill:objectName())
                                end
                            end
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
SakuraEndo:addSkill(sakamichi_chuan_cheng)

sgs.LoadTranslationTable {
    ["SakuraEndo"] = "遠藤 さくら",
    ["&SakuraEndo"] = "遠藤 さくら",
    ["#SakuraEndo"] = "乃团之巅",
    ["~SakuraEndo"] = "もう恥ずかしがらないぞー",
    ["designer:SakuraEndo"] = "Cassimolar",
    ["cv:SakuraEndo"] = "遠藤 さくら",
    ["illustrator:SakuraEndo"] = "Cassimolar",
    ["sakamichi_ye_ming"] = "夜明",
    [":sakamichi_ye_ming"] = "主公技，你的手牌上限+X（X为场上乃木坂46势力角色数）。出牌阶段限一次，你可以令任意名其他乃木坂46势力角色下个摸牌阶段额定摸牌数+1，若如此做，本回合内你减少等量的手牌上限。",
    ["sakamichi_luo_lei"] = "落泪",
    [":sakamichi_luo_lei"] = "限定技，准备阶段，你可以选择并获得一个已死亡或未登场的乃木坂46势力主公的主公技（获得后不为主公也可发动）。",
    ["@luo_lei"] = "落泪",
    ["sakamichi_chuan_cheng"] = "传承",
    [":sakamichi_chuan_cheng"] = "使命技，结束阶段，你可以选择一名非乃木坂46势力角色，观看其手牌或对其造成1点伤害。成功：其他乃木坂46势力角色进入濒死时，你选择并获得两个已死亡或未登场的乃木坂46势力主公的主公技（获得后不为主公也可发动）。失败：其他乃木坂46势力角色令你进入濒死时，你失去所有主公技。",
    ["sakamichi_chuan_cheng:chuan_cheng_1"] = "观看%src的手牌",
    ["sakamichi_chuan_cheng:chuan_cheng_2"] = "对%src造成%arg点伤害",
}
