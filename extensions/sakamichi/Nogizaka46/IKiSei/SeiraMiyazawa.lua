require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SeiraMiyazawa = sgs.General(Sakamichi, "SeiraMiyazawa", "Nogizaka46", 3, false)
SKMC.IKiSei.SeiraMiyazawa = true
SKMC.SeiMeiHanDan.SeiraMiyazawa = {
    name = {10, 16, 6, 7},
    ten_kaku = {26, "xiong"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_hun_xue = sgs.CreateTriggerSkill {
    name = "sakamichi_hun_xue",
    events = {sgs.PindianVerifying, sgs.Pindian},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() and player:getKingdom() ~= pindian.to:getKingdom() then
                if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "@hun_xue_invoke") then
                    local choice = room:askForChoice(player, self:objectName(), "up+down", data)
                    SKMC.choice_log(player, choice)
                    if choice == "up" then
                        pindian.from_number = math.min(pindian.from_number + SKMC.number_correction(player, 5), 13)
                    elseif choice == "down" then
                        pindian.from_number = math.max(pindian.from_number - SKMC.number_correction(player, 5), 1)
                    end
                    SKMC.send_message(room, "#hun_xue" .. choice, player, nil, nil, nil, self:objectName(),
                        pindian.from_number)
                end
            end
            if pindian.to:objectName() == player:objectName() and player:getKingdom() ~= pindian.from:getKingdom() then
                if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "@hun_xue_invoke") then
                    local choice = room:askForChoice(player, self:objectName(), "up+down", data)
                    SKMC.choice_log(player, choice)
                    if choice == "up" then
                        pindian.to_number = math.min(pindian.to_number + SKMC.number_correction(player, 5), 13)
                    elseif choice == "down" then
                        pindian.to_number = math.max(pindian.to_number - SKMC.number_correction(player, 5), 1)
                    end
                    SKMC.send_message(room, "#hun_xue_" .. choice, player, nil, nil, nil, self:objectName(),
                        pindian.to_number)
                end
            end
        else
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() then
                if pindian.from_number <= pindian.to_number then
                    room:drawCards(player, 1, self:objectName())
                end
            end
            if pindian.to:objectName() == player:objectName() then
                if pindian.from_number >= pindian.to_number then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
SeiraMiyazawa:addSkill(sakamichi_hun_xue)

sakamichi_ba_lei_card = sgs.CreateSkillCard {
    name = "sakamichi_ba_leiCard",
    skill_name = "sakamichi_ba_lei",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return sgs.Self:objectName() ~= to_select:objectName() and sgs.Self:canPindian(to_select)
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local success = effect.from:pindian(effect.to, self:getSkillName(), self)
        local data = sgs.QVariant()
        data:setValue(effect.to)
        while success do
            if effect.to:isKongcheng() then
                break
            elseif effect.from:isKongcheng() then
                break
            elseif room:askForSkillInvoke(effect.from, self:getSkillName(), data) then
                success = effect.from:pindian(effect.to, self:getSkillName())
            else
                break
            end
        end
        if not success then
            room:loseHp(effect.from)
        end
    end,
}
sakamichi_ba_lei_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_ba_lei",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_ba_lei_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_ba_lei") and not player:isKongcheng()
    end,
}
sakamichi_ba_lei = sgs.CreateTriggerSkill {
    name = "sakamichi_ba_lei",
    events = {sgs.EventPhaseChanging, sgs.Pindian},
    view_as_skill = sakamichi_ba_lei_view_as,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Start and not player:isWounded() and not player:isKongcheng() then
                room:askForUseCard(player, "@@sakamichi_ba_lei", "@ba_lei_invoke")
            end
        else
            local pindian = data:toPindian()
            if pindian.reason == self:objectName() then
                if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
                    room:obtainCard(player, pindian.to_card)
                end
            end
        end
        return false
    end,
}
SeiraMiyazawa:addSkill(sakamichi_ba_lei)

sakamichi_zu_qiu_card = sgs.CreateSkillCard {
    name = "sakamichi_zu_qiuCard",
    skill_name = "sakamichi_zu_qiu",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets == 0 then
            if not to_select:isKongcheng() then
                return to_select:getKingdom() ~= sgs.Self:getKingdom() and sgs.Self:canPindian(to_select)
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        effect.from:pindian(effect.to, self:getSkillName(), self)
    end,
}
sakamichi_zu_qiu_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_zu_qiu",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_zu_qiu_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_zu_qiuCard") and not player:isKongcheng()
                   and SKMC.has_specific_kingdom_player(player, false)
    end,
}
sakamichi_zu_qiu = sgs.CreateTriggerSkill {
    name = "sakamichi_zu_qiu",
    view_as_skill = sakamichi_zu_qiu_view_as,
    events = {sgs.Pindian},
    on_trigger = function(self, event, player, data, room)
        local pindian = data:toPindian()
        if pindian.from:objectName() == player:objectName() and pindian.reason == self:objectName() then
            if pindian.from_number > pindian.to_number then
                room:obtainCard(pindian.from, pindian.from_card)
                room:obtainCard(pindian.from, pindian.to_card)
            else
                if pindian.from_number < pindian.to_number then
                    room:obtainCard(pindian.to, pindian.from_card)
                    room:obtainCard(pindian.to, pindian.to_card)
                end
            end
            return false
        end
    end,
}
SeiraMiyazawa:addSkill(sakamichi_zu_qiu)

sgs.LoadTranslationTable {
    ["SeiraMiyazawa"] = "?????? ??????",
    ["&SeiraMiyazawa"] = "?????? ??????",
    ["#SeiraMiyazawa"] = "????????????",
    ["~SeiraMiyazawa"] = "",
    ["designer:SeiraMiyazawa"] = "Cassimolar",
    ["cv:SeiraMiyazawa"] = "?????? ??????",
    ["illustrator:SeiraMiyazawa"] = "Cassimolar",
    ["sakamichi_hun_xue"] = "??????",
    [":sakamichi_hun_xue"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????+5???-5???????????????????????????????????????????????????",
    ["@hun_xue_invoke"] = "???????????????????????????????????????????????????+5???-5",
    ["sakamichi_hun_xue:up"] = "???????????????????????????5",
    ["sakamichi_hun_xue:down"] = "???????????????????????????5",
    ["#hun_xue_up"] = "%from ?????????%arg???????????????????????????<font color=\"yellow\"><b>+5</b></font>???????????????????????? %arg2",
    ["#hun_xue_down"] = "%from ?????????%arg???????????????????????????<font color=\"yellow\"><b>-5</b></font>???????????????????????? %arg2",
    ["sakamichi_ba_lei"] = "??????",
    [":sakamichi_ba_lei"] = "???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1????????????",
    ["@ba_lei_invoke"] = "?????????????????????????????????",
    ["~sakamichi_ba_lei"] = "?????????????????? ??? ???????????????????????? ??? ????????????",
    ["sakamichi_zu_qiu"] = "??????",
    [":sakamichi_zu_qiu"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
}
