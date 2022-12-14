require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ChiharuSaito = sgs.General(Sakamichi, "ChiharuSaito", "Nogizaka46", 4, false)
SKMC.IKiSei.ChiharuSaito = true
SKMC.SeiMeiHanDan.ChiharuSaito = {
    name = {11, 18, 3, 4, 3},
    ten_kaku = {29, "te_shu_ge"},
    jin_kaku = {21, "ji"},
    ji_kaku = {10, "xiong"},
    soto_kaku = {18, "ji"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "shui",
        san_sai = "ji",
    },
}

sakamichi_jia_ge_card = sgs.CreateSkillCard {
    name = "sakamichi_jia_geCard",
    skill_name = "sakamichi_jia_ge",
    target_fixed = true,
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    on_use = function(self, room, source, targets)
        local target
        if not source:hasFlag("jia_ge") then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getNextAlive():objectName() == source:objectName() then
                    target = p
                end
            end
        else
            target = source:getNextAlive()
        end
        room:obtainCard(target, self)
        local choice = room:askForChoice(source, self:getSkillName(), "BasicCard+TrickCard+EquipCard")
        SKMC.choice_log(source, choice)
        local card = room:askForCard(target, choice, "@jia_ge_choice:" .. source:objectName() .. "::" .. choice,
            sgs.QVariant(), sgs.Card_MethodNone)
        if card then
            room:obtainCard(source, card)
        else
            room:drawCards(source, 2, self:getSkillName())
        end
        if not source:hasFlag("jia_ge") then
            room:setPlayerFlag(source, "jia_ge")
            room:askForUseCard(source, "@@sakamichi_jia_ge", "@jia_ge_invoke", -1, sgs.Card_MethodNone, false)
        end
    end,
}
sakamichi_jia_ge = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jia_ge",
    response_pattern = "",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_jia_ge_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#sakamichi_jia_geCard")
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_jia_ge")
    end,
}
ChiharuSaito:addSkill(sakamichi_jia_ge)

sakamichi_bao_zhong = sgs.CreateTriggerSkill {
    name = "sakamichi_bao_zhong",
    events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded, sgs.EventLoseSkill, sgs.PreHpRecover},
    priority = {6, 1, 1},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive and player:hasSkill(self) then
                player:setMark(self:objectName(), 0)
                room:setPlayerMark(player, "&bao_zhong+red", 0)
                room:setPlayerMark(player, "&bao_zhong+black", 0)
            end
        elseif (event == sgs.CardUsed or event == sgs.CardResponded) and player:hasSkill(self) then
            local card = nil
            if event == sgs.CardUsed then
                local use = data:toCardUse()
                if player:objectName() == use.from:objectName() then
                    card = use.card
                end
            else
                local response = data:toCardResponse()
                if response.m_isUse then
                    card = response.m_card
                end
            end
            if card == nil or card:isKindOf("SkillCard") or player:getPhase() == sgs.Player_NotActive then
                return false
            end
            local color_int = function(acard)
                local int = 2
                if acard:isRed() then
                    int = 0
                elseif acard:isBlack() then
                    int = 1
                end
                return int
            end
            if player:getMark(self:objectName()) ~= 0 then
                local old_color = player:getMark(self:objectName()) - 1
                local d = sgs.QVariant()
                d:setValue(card)
                if old_color ~= color_int(card) and room:askForSkillInvoke(player, self:objectName(), d) then
                    room:drawCards(player, 1, self:objectName())
                end
            end
            player:setMark(self:objectName(), color_int(card) + 1)
            if player:getMark(self:objectName()) == 1 then
                room:setPlayerMark(player, "&bao_zhong+black", 0)
                room:setPlayerMark(player, "&bao_zhong+red", 1)
            end
            if player:getMark(self:objectName()) == 2 then
                room:setPlayerMark(player, "&bao_zhong+red", 0)
                room:setPlayerMark(player, "&bao_zhong+black", 1)
            end
        elseif event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() then
                room:setPlayerMark(player, "&bao_zhong+black", 0)
                room:setPlayerMark(player, "&bao_zhong+red", 0)
                room:setPlayerMark(player, self:objectName(), 0)
            end
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:isFemale() and player:hasSkill(self)
                and room:askForSkillInvoke(player, self:objectName(), data) then
                recover.recover = recover.recover + SKMC.number_correction(player, 1)
                SKMC.send_message(room, "#bao_zhong_recover", recover.who, player, nil, nil, self:objectName(),
                    recover.recover)
                data:setValue(recover)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ChiharuSaito:addSkill(sakamichi_bao_zhong)

sgs.LoadTranslationTable {
    ["ChiharuSaito"] = "?????? ?????????",
    ["&ChiharuSaito"] = "?????? ?????????",
    ["#ChiharuSaito"] = "????????????",
    ["~ChiharuSaito"] = "???????????????????????????????????????",
    ["designer:ChiharuSaito"] = "Cassimolar",
    ["cv:ChiharuSaito"] = "?????? ?????????",
    ["illustrator:ChiharuSaito"] = "Cassimolar",
    ["sakamichi_jia_ge"] = "??????",
    [":sakamichi_jia_ge"] = "???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@jia_ge_choice"] = "????????????%src ?????? %arg ?????????????????????",
    ["@jia_ge_invoke"] = "????????????????????????????????????",
    ["sakamichi_bao_zhong"] = "??????",
    [":sakamichi_bao_zhong"] = "??????????????????????????????????????????+1??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["bao_zhong"] = "??????",
    ["#bao_zhong_recover"] = "%to ?????????%arg??????%from ???%to ??????????????????????????????????????? %arg2 ???",
}
