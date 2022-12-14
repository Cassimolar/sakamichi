require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KyokoSaito_HiraganaKeyakizaka = sgs.General(Sakamichi, "KyokoSaito_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 4,
    false, false, false, 3)
SKMC.IKiSei.KyokoSaito_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.KyokoSaito_HiraganaKeyakizaka = {
    name = {14, 18, 8, 3},
    ten_kaku = {32, "ji"},
    jin_kaku = {26, "xiong"},
    ji_kaku = {11, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {43, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_di_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_di_yin",
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") and not damage.to:faceUp()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            damage.damage = damage.damage + SKMC.number_correction(player, 1)
            data:setValue(damage)
        end
        return false
    end,
}
sakamichi_di_yin_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_di_yin_target_mod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_di_yin") and to and not to:faceUp() then
            return 1000
        else
            return 0
        end
    end,
}
KyokoSaito_HiraganaKeyakizaka:addSkill(sakamichi_di_yin)
if not sgs.Sanguosha:getSkill("#sakamichi_di_yin_target_mod") then
    SKMC.SkillList:append(sakamichi_di_yin_target_mod)
end

sakamichi_mi_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_yu",
    events = {sgs.GameStart, sgs.CardsMoveOneTime, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self) then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@mi_yu_choice", true, true)
                if target then
                    room:setPlayerMark(target, "mi_yu_" .. player:objectName(), 1)
                    room:setPlayerMark(player, "mi_yu_" .. target:objectName(), 1)
                    local players = sgs.SPlayerList()
                    players:append(player)
                    SKMC.fake_move(room, player, "&" .. self:objectName(), target:handCards(), true, self:objectName(),
                        players)
                    local players = sgs.SPlayerList()
                    players:append(target)
                    SKMC.fake_move(room, target, "&" .. self:objectName(), player:handCards(), true, self:objectName(),
                        players)
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
                and move.from_places:contains(sgs.Player_PlaceHand) then
                local ids = sgs.IntList()
                for i = 0, move.card_ids:length() - 1, 1 do
                    if move.from_places:at(i) == sgs.Player_PlaceHand then
                        ids:append(move.card_ids:at(i))
                    end
                end
                if not ids:isEmpty() then
                    for _, mark in sgs.list(player:getMarkNames()) do
                        if mark:startsWith("mi_yu_") then
                            local target_name = mark:split("_")[3]
                            if target_name then
                                local target = room:findPlayerByObjectName(target_name)
                                if target then
                                    local players = sgs.SPlayerList()
                                    players:append(room:findPlayerByObjectName(target_name))
                                    SKMC.fake_move(room, target, "&" .. self:objectName(), ids, false,
                                        self:objectName(), players)
                                end
                            end
                        end
                    end
                end
            end
            if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if mark:startsWith("mi_yu_") then
                        local target_name = mark:split("_")[3]
                        if target_name then
                            local target = room:findPlayerByObjectName(target_name)
                            if target then
                                local players = sgs.SPlayerList()
                                players:append(room:findPlayerByObjectName(target_name))
                                SKMC.fake_move(room, target, "&" .. self:objectName(), move.card_ids, true,
                                    self:objectName(), players)
                            end
                        end
                    end
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if mark:startsWith("mi_yu_") then
                        local target_name = mark:split("_")[3]
                        if target_name then
                            local target = room:findPlayerByObjectName(target_name)
                            if target then
                                room:setPlayerMark(target, mark, 0)
                                room:setPlayerMark(player, "mi_yu_" .. target:objectName(), 0)
                                if not target:handCards():isEmpty() then
                                    local players = sgs.SPlayerList()
                                    players:append(target)
                                    SKMC.fake_move(room, target, "&" .. self:objectName(), target:handCards(), false,
                                        self:objectName(), players)
                                end
                                if not player:handCards():isEmpty() then
                                    local players = sgs.SPlayerList()
                                    players:append(player)
                                    SKMC.fake_move(room, player, "&" .. self:objectName(), player:handCards(), false,
                                        self:objectName(), players)
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
KyokoSaito_HiraganaKeyakizaka:addSkill(sakamichi_mi_yu)

sakamichi_hui_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_hui_shi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") and not use.card:isVirtualCard() then
            if player:hasSkill(self) then
                local tag = player:getTag(self:objectName()):toIntList()
                if not tag:contains(use.card:getEffectiveId()) then
                    tag:append(use.card:getEffectiveId())
                    local _data = sgs.QVariant()
                    _data:setValue(tag)
                    player:setTag(self:objectName(), _data)
                    SKMC.fake_move(room, player, self:objectName(), use.card:getEffectiveId(), true, self:objectName(),
                        room:getAllPlayers(true))
                end
            end
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName()
                    and p:getTag(self:objectName()):toIntList():contains(use.card:getEffectiveId()) then
                    player:turnOver()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KyokoSaito_HiraganaKeyakizaka:addSkill(sakamichi_hui_shi)

sgs.LoadTranslationTable {
    ["KyokoSaito_HiraganaKeyakizaka"] = "?????? ??????",
    ["&KyokoSaito_HiraganaKeyakizaka"] = "?????? ??????",
    ["#KyokoSaito_HiraganaKeyakizaka"] = "????????????",
    ["~KyokoSaito_HiraganaKeyakizaka"] = "??????????????????????????????????????????",
    ["designer:KyokoSaito_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:KyokoSaito_HiraganaKeyakizaka"] = "?????? ??????",
    ["illustrator:KyokoSaito_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_di_yin"] = "??????",
    [":sakamichi_di_yin"] = "?????????????????????????????????????????????????????????????????????????????????+1???????????????????????????????????????????????????????????????",
    ["sakamichi_mi_yu"] = "??????",
    [":sakamichi_mi_yu"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@mi_yu_choice"] = "????????????????????????????????????????????????????????????????????????????????????????????????",
    ["&sakamichi_mi_yu"] = "??????",
    ["sakamichi_hui_shi"] = "??????",
    [":sakamichi_hui_shi"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
}
