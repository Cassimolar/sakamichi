require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AyanoChristieYoshida = sgs.General(Sakamichi, "AyanoChristieYoshida", "Nogizaka46", 4, false)
SKMC.SanKiSei.AyanoChristieYoshida = true
SKMC.SeiMeiHanDan.AyanoChristieYoshida = {
    name = {6, 5, 14, 2, 2, 2, 2, 3, 2, 1},
    ten_kaku = {11, "ji"},
    jin_kaku = {19, "xiong"},
    ji_kaku = {28, "xiong"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "jin",
        san_sai = "da_ji",
    },
}

sakamichi_jia_lao_wai = sgs.CreateTriggerSkill {
    name = "sakamichi_jia_lao_wai",
    events = {sgs.GameStart, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self) then
                local kingdom = room:askForKingdom(player)
                player:setTag(self:objectName(), sgs.QVariant(kingdom))
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. kingdom, 1)
            end
        elseif event == sgs.Damaged then
            if player:isAlive() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getKingdom() == p:getKingdom() or player:getKingdom()
                        == p:getTag(self:objectName()):toString() then
                        if room:askForSkillInvoke(p, self:objectName(), data) then
                            local choice_1 = "1=" .. player:objectName()
                            local choice_2 = "2=" .. player:objectName()
                            if room:askForChoice(p, self:objectName(), choice_1 .. "+" .. choice_2) == choice_1 then
                                room:drawCards(player, 1, self:objectName())
                                if not player:isNude() then
                                    if player:getHandcardNum() + player:getEquips():length() > 2 then
                                        room:askForDiscard(player, self:objectName(), 2, 2, false, true, nil, ".",
                                            self:objectName())
                                    else
                                        player:throwAllHandCardsAndEquips()
                                    end
                                end
                                room:drawCards(p, 2, self:objectName())
                                if not p:isNude() then
                                    room:askForDiscard(p, self:objectName(), 1, 1, false, true, nil, ".",
                                        self:objectName())
                                else
                                    p:throwAllHandCardsAndEquips()
                                end
                            else
                                room:drawCards(player, 2, self:objectName())
                                if not player:isNude() then
                                    room:askForDiscard(player, self:objectName(), 1, 1, false, true, nil, ".",
                                        self:objectName())
                                else
                                    player:throwAllHandCardsAndEquips()
                                end
                                room:drawCards(p, 1, self:objectName())
                                if not p:isNude() then
                                    if p:getHandcardNum() + p:getEquips():length() > 2 then
                                        room:askForDiscard(p, self:objectName(), 2, 2, false, true, nil, ".",
                                            self:objectName())
                                    else
                                        p:throwAllHandCardsAndEquips()
                                    end
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
AyanoChristieYoshida:addSkill(sakamichi_jia_lao_wai)

sakamichi_you_zhi = sgs.CreateTriggerSkill {
    name = "sakamichi_you_zhi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Start and player:getMark("you_zhi") ~= 0 then
                local difference = math.abs(player:getHandcardNum() - player:getMark("&" .. self:objectName()))
                if difference ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:drawCards(player, difference, self:objectName())
                end
            end
        else
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if player:getMark("you_zhi") == 0 then
                    room:setPlayerMark(player, "you_zhi", 1)
                end
                room:setPlayerMark(player, "&" .. self:objectName(), player:getHandcardNum())
            end
        end
        return false
    end,
}
AyanoChristieYoshida:addSkill(sakamichi_you_zhi)

sakamichi_quan_neng = sgs.CreateTriggerSkill {
    name = "sakamichi_quan_neng",
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            local skill_list = {}
            for _, skill in sgs.qlist(player:getGeneral():getVisibleSkillList()) do
                table.insert(skill_list, skill:objectName())
            end
            if player:getGeneral2() then
                for _, skill in sgs.qlist(player:getGeneral2():getVisibleSkillList()) do
                    table.insert(skill_list, skill:objectName())
                end
            end
            if #skill_list ~= 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), data) then
                        local skill_name = room:askForChoice(p, self:objectName(), table.concat(skill_list, "+"))
                        room:handleAcquireDetachSkills(p, skill_name)
                        room:loseMaxHp(p)
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
AyanoChristieYoshida:addSkill(sakamichi_quan_neng)

sgs.LoadTranslationTable {
    ["AyanoChristieYoshida"] = "?????? ????????????????????????",
    ["&AyanoChristieYoshida"] = "?????? ????????????????????????",
    ["#AyanoChristieYoshida"] = "????????????",
    ["~AyanoChristieYoshida"] = "??????????????????????????????",
    ["designer:AyanoChristieYoshida"] = "Cassimolar",
    ["cv:AyanoChristieYoshida"] = "?????? ????????????????????????",
    ["illustrator:AyanoChristieYoshida"] = "Cassimolar",
    ["sakamichi_jia_lao_wai"] = "?????????",
    [":sakamichi_jia_lao_wai"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_jia_lao_wai:1"] = "???%src?????????????????????????????????",
    ["sakamichi_jia_lao_wai:2"] = "???%src?????????????????????????????????",
    ["sakamichi_you_zhi"] = "??????",
    [":sakamichi_you_zhi"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_quan_neng"] = "??????",
    [":sakamichi_quan_neng"] = "?????????????????????????????????????????????????????????????????????????????????????????????1??????????????????",
}
