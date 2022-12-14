require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ErikaIkuta = sgs.General(Sakamichi, "ErikaIkuta", "Nogizaka46", 3, false)
SKMC.IKiSei.ErikaIkuta = true
SKMC.SeiMeiHanDan.ErikaIkuta = {
    name = {5, 5, 12, 11, 7},
    ten_kaku = {10, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {30, "ji_xiong_hun_he"},
    soto_kaku = {23, "ji"},
    sou_kaku = {40, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_lan_tian = sgs.CreateTriggerSkill {
    name = "sakamichi_lan_tian$",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getKingdom() == "Nogizaka46" then
            local min = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getHandcardNum() < player:getHandcardNum() then
                    min = false
                    break
                end
            end
            if min then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                        while min do
                            room:drawCards(player, 1, self:objectName())
                            for _, pl in sgs.qlist(room:getOtherPlayers(player)) do
                                if pl:getHandcardNum() < player:getHandcardNum() then
                                    min = false
                                    break
                                end
                            end
                        end
                        break
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
ErikaIkuta:addSkill(sakamichi_lan_tian)

sakamichi_xia_chu = sgs.CreateTriggerSkill {
    name = "sakamichi_xia_chu",
    events = {sgs.AskForPeaches, sgs.PreventPeach, sgs.AfterPreventPeach},
    priority = {7, 7, 7},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if event == sgs.AskForPeaches then
            if player:objectName() == room:getAllPlayers():first():objectName() then
                local current = room:getCurrent()
                if current and current:getPhase() ~= sgs.Player_NotActive and current:hasSkill(self) then
                    room:notifySkillInvoked(current, self:objectName())
                    if current:objectName() ~= dying.who:objectName() then
                        SKMC.send_message(room, "#xia_chu_2", current, dying.who, nil, nil, self:objectName())
                    else
                        SKMC.send_message(room, "#xia_chu_1", current, nil, nil, nil, self:objectName())
                    end
                end
            end
        elseif event == sgs.PreventPeach then
            local current = room:getCurrent()
            if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive and current:hasSkill(self) then
                if player:objectName() ~= current:objectName() and player:objectName() ~= dying.who:objectName() then
                    room:setPlayerFlag(player, "xia_chu")
                    room:addPlayerMark(player, "Global_PreventPeach")
                end
            end
        elseif event == sgs.AfterPreventPeach then
            if player:hasFlag("xia_chu") and player:getMark("Global_PreventPeach") > 0 then
                room:setPlayerFlag(player, "-xia_chu")
                room:removePlayerMark(player, "Global_PreventPeach")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ErikaIkuta:addSkill(sakamichi_xia_chu)

sakamichi_gang_qin_card = sgs.CreateSkillCard {
    name = "sakamichi_gang_qinCard",
    skill_name = "sakamichi_gang_qin",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark("gang_qin_jia_target") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:throwAllHandCards()
        effect.to:turnOver()
        room:drawCards(effect.to, 2, self:getSkillName())
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:getMark("gang_qin_jia_target") ~= 0 then
                room:setPlayerMark(p, "gang_qin_jia_target", 0)
            end
        end
        room:setPlayerMark(effect.to, "gang_qin_jia_target", 1)
    end,
}
sakamichi_gang_qin = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_gang_qin",
    view_as = function()
        return sakamichi_gang_qin_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng()
    end,
}
ErikaIkuta:addSkill(sakamichi_gang_qin)

sakamichi_fen_lan_min_yao_card = sgs.CreateSkillCard {
    name = "sakamichi_fen_lan_min_yaoCard",
    skill_name = "sakamichi_fen_lan_min_yao",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@fen_lan_min_yao")
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        local players = room:getOtherPlayers(effect.to)
        local distance_list = sgs.IntList()
        local nearest = 1000
        for _, player in sgs.qlist(players) do
            local distance = effect.to:distanceTo(player)
            distance_list:append(distance)
            nearest = math.min(nearest, distance)
        end
        local targets = sgs.SPlayerList()
        local count = distance_list:length()
        for i = 0, count - 1, 1 do
            if (distance_list:at(i) == nearest) and effect.to:canSlash(players:at(i), nil, false) then
                targets:append(players:at(i))
            end
        end
        if targets:length() > 0 then
            if not room:askForUseSlashTo(effect.to, targets, "@fen_lan_min_yao_slash") then
                room:loseHp(effect.to)
            end
        else
            room:loseHp(effect.to)
        end
    end,
}
sakamichi_fen_lan_min_yao = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_fen_lan_min_yao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@fen_lan_min_yao",
    view_as = function()
        return sakamichi_fen_lan_min_yao_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@fen_lan_min_yao") >= 1
    end,
}
ErikaIkuta:addSkill(sakamichi_fen_lan_min_yao)

sgs.LoadTranslationTable {
    ["ErikaIkuta"] = "?????? ?????????",
    ["&ErikaIkuta"] = "?????? ?????????",
    ["#ErikaIkuta"] = "??????",
    ["~ErikaIkuta"] = "?????????????????????????????????????????????????????????????????????",
    ["designer:ErikaIkuta"] = "Cassimolar",
    ["cv:ErikaIkuta"] = "?????? ?????????",
    ["illustrator:ErikaIkuta"] = "Cassimolar",
    ["sakamichi_lan_tian"] = "??????",
    [":sakamichi_lan_tian"] = "?????????????????????46???????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_lan_tian:invoke"] = "?????????%src??????????????????????????????",
    ["sakamichi_xia_chu"] = "??????",
    [":sakamichi_xia_chu"] = "????????????????????????????????????????????????????????????????????????????????????????????????",
    ["#xia_chu_1"] = "%from ??????%arg????????????????????? %from ??????",
    ["#xia_chu_2"] = "%from ??????%arg????????????????????? %from ??? %to ????????? %to",
    ["sakamichi_gang_qin"] = "??????",
    ["luagangqingjia"] = "??????",
    [":sakamichi_gang_qin"] = "???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_fen_lan_min_yao"] = "??????",
    ["@fen_lan_min_yao"] = "??????",
    [":sakamichi_fen_lan_min_yao"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1????????????",
    ["@fen_lan_min_yao_slash"] = "????????????????????????????????????????????????",
}
