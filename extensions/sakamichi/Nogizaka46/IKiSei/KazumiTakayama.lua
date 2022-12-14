require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KazumiTakayama = sgs.General(Sakamichi, "KazumiTakayama", "Nogizaka46", 3, false)
SKMC.IKiSei.KazumiTakayama = true
SKMC.SeiMeiHanDan.KazumiTakayama = {
    name = {10, 3, 1, 8},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {4, "xiong"},
    ji_kaku = {9, "xiong"},
    soto_kaku = {18, "ji"},
    sou_kaku = {22, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_jiao_zhu = sgs.CreateTriggerSkill {
    name = "sakamichi_jiao_zhu",
    events = {sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local result = SKMC.run_judge(room, player, self:objectName(), ".|spade,club")
                if result.card:getSuit() == sgs.Card_Spade then
                    room:drawCards(p, 1, self:objectName())
                elseif result.card:getSuit() == sgs.Card_Club then
                    if p:isWounded() then
                        room:recover(p, sgs.RecoverStruct(player, nil, SKMC.number_correction(p, 1)))
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
KazumiTakayama:addSkill(sakamichi_jiao_zhu)

sakamichi_gai_ming_kazumi = sgs.CreateTriggerSkill {
    name = "sakamichi_gai_ming_kazumi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@gai_ming_kazumi",
    events = {sgs.AskForRetrial, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AskForRetrial then
            local judge = data:toJudge()
            local can_invoke = false
            if player:hasSkill(self) then
                if player:isKongcheng() then
                    for _, equip in sgs.qlist(player:getEquips()) do
                        if equip:isBlack() then
                            can_invoke = true
                            break
                        end
                    end
                else
                    can_invoke = true
                end
                if can_invoke then
                    local card = room:askForCard(player, ".|black", "@gai_ming_kazumi_card:" .. judge.who:objectName()
                        .. "::" .. judge.reason .. ":" .. judge.card:objectName(), data, sgs.Card_MethodResponse,
                        judge.who, true)
                    if card then
                        room:retrial(card, player, judge, self:objectName(), true)
                    end
                end
            end
        else
            local dying = data:toDying()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("@gai_ming_kazumi") ~= 0 and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                    "to:" .. dying.who:objectName() .. "::" .. self:objectName())) then
                    room:removePlayerMark(p, "@gai_ming_kazumi")
                    local result = SKMC.run_judge(room, dying.who, self:objectName(), ".|black", false)
                    if result.isGood == true then
                        room:recover(dying.who, sgs.RecoverStruct(p, nil, SKMC.number_correction(p, 1)))
                        local general_names = sgs.Sanguosha:getLimitedGeneralNames()
                        if (SKMC.is_normal_game_mode(room:getMode()) or room:getMode():find("_mini_") or room:getMode()
                            == "custom_scenario") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/Roles", ""):split(", "))
                        elseif (room:getMode() == "04_1v3") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/HulaoPass", ""):split(", "))
                        elseif (room:getMode() == "06_XMode") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/XMode", ""):split(", "))
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                table.removeTable(general_names, (p:getTag("XModeBackup"):toStringList()) or {})
                            end
                        elseif (room:getMode() == "02_1v1") then
                            table.removeTable(general_names, sgs.GetConfig("Banlist/1v1", ""):split(", "))
                            for _, p in sgs.qlist(room:getAlivePlayers()) do
                                table.removeTable(general_names, (p:getTag("1v1Arrange"):toStringList()) or {})
                            end
                        end
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            local name = p:getGeneralName()
                            if sgs.Sanguosha:isGeneralHidden(name) then
                                local fname = sgs.Sanguosha:findConvertFrom(name);
                                if fname ~= "" then
                                    name = fname
                                end
                            end
                            table.removeOne(general_names, name)
                            if p:getGeneral2() then
                                name = p:getGeneral2Name()
                            end
                            if sgs.Sanguosha:isGeneralHidden(name) then
                                local fname = sgs.Sanguosha:findConvertFrom(name);
                                if fname ~= "" then
                                    name = fname
                                end
                            end
                            table.removeOne(general_names, name)
                        end
                        local gai_ming_generals = {}
                        for _, name in ipairs(general_names) do
                            local general = sgs.Sanguosha:getGeneral(name)
                            if general:getKingdom() == dying.who:getKingdom() then
                                table.insert(gai_ming_generals, name)
                            end
                        end
                        local x = math.min(3, #gai_ming_generals)
                        local random = {}
                        repeat
                            local rand = math.random(1, #gai_ming_generals)
                            if not table.contains(random, gai_ming_generals[rand]) then
                                table.insert(random, (gai_ming_generals[rand]))
                            end
                        until #random == x
                        local general = room:askForGeneral(p, table.concat(random, "+"))
                        room:changeHero(dying.who, general, false)
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
KazumiTakayama:addSkill(sakamichi_gai_ming_kazumi)

sgs.LoadTranslationTable {
    ["KazumiTakayama"] = "?????? ??????",
    ["&KazumiTakayama"] = "?????? ??????",
    ["#KazumiTakayama"] = "??????",
    ["~KazumiTakayama"] = "Amazing!",
    ["designer:KazumiTakayama"] = "Cassimolar",
    ["cv:KazumiTakayama"] = "?????? ??????",
    ["illustrator:KazumiTakayama"] = "Cassimolar",
    ["sakamichi_jiao_zhu"] = "??????",
    [":sakamichi_jiao_zhu"] = "??????????????????/?????????????????????????????????????????????????????????????????????1???????????????????????????????????????",
    ["sakamichi_gai_ming_kazumi"] = "??????",
    [":sakamichi_gai_ming_kazumi"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1??????????????????????????????????????????????????????????????????????????????????????????",
    ["@gai_ming_kazumi"] = "??????",
    ["@gai_ming_kazumiCard"] = "??????????????????????????????????????? %src ??? %arg ???????????? %arg2",
    ["sakamichi_gai_ming_kazumi:to"] = "%src ???????????????????????????%arg",
}
