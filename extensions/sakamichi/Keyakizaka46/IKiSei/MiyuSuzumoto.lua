require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MiyuSuzumoto = sgs.General(Sakamichi, "MiyuSuzumoto", "Keyakizaka46", 3, false)
SKMC.IKiSei.MiyuSuzumoto = true
SKMC.SeiMeiHanDan.MiyuSuzumoto = {
    name = {13, 5, 9, 12},
    ten_kaku = {18, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {25, "ji"},
    sou_kaku = {39, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_li_ziCard = sgs.CreateSkillCard {
    name = "sakamichi_li_ziCard",
    skill_name = "sakamichi_li_zi",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:isWounded()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@li_zi",
            math.max(effect.from:getLostHp(), SKMC.number_correction(effect.from, 1)))
        room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
    end,
}
sakamichi_li_zi_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_li_zi",
    view_as = function(self)
        return sakamichi_li_ziCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_li_ziCard") and player:getMark("@li_zi")
                   >= math.max(player:getLostHp(), SKMC.number_correction(player, 1))
    end,
}
sakamichi_li_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_li_zi",
    view_as_skill = sakamichi_li_zi_view_as,
    events = {sgs.CardUsed, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasSkill(self) and not use.card:isKindOf("SkillCard") then
                room:addPlayerMark(player, "@li_zi")
            end
        else
            if player:getPhase() == sgs.Player_Finish then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and p:getMark("@li_zi")
                        > math.max(p:getMaxHp(), player:getMaxHp()) then
                        room:removePlayerMark(p, "@li_zi", p:getMark("@li_zi"))
                        if not player:isKongcheng() then
                            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                            dummy:deleteLater()
                            dummy:addSubcards(player:getHandcards())
                            room:moveCardTo(dummy, player, p, sgs.Player_PlaceHand, sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_ROB, player:objectName(), p:objectName(), self:objectName(),
                                nil))
                            room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp()))
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
MiyuSuzumoto:addSkill(sakamichi_li_zi)

sakamichi_chu_niang = sgs.CreateTriggerSkill {
    name = "sakamichi_chu_niang",
    frequency = sgs.Skill_Limited,
    limit_mark = "@chu_niang",
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.BeforeCardsMove or event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName()
                and move.from_places:contains(sgs.Player_PlaceHand) then
                if event == sgs.BeforeCardsMove then
                    if not player:isKongcheng() then
                        local can_trigger = true
                        for _, id in sgs.qlist(player:handCards()) do
                            if not move.card_ids:contains(id) then
                                can_trigger = false
                            end
                        end
                        if can_trigger then
                            if player:getMaxCards() == 0 and player:getPhase() == sgs.Player_Discard
                                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                                == sgs.CardMoveReason_S_REASON_RULEDISCARD then
                                room:setPlayerFlag(player, "chu_niang_zero_max_cards")
                            else
                                room:addPlayerMark(player, self:objectName())
                            end
                        end
                    end
                else
                    if player:getMark(self:objectName()) ~= 0 then
                        player:removeMark(self:objectName())
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if p:getMark("@chu_niang") ~= 0
                                and room:askForSkillInvoke(p, self:objectName(),
                                    sgs.QVariant("@chu_niang:" .. player:objectName())) then
                                room:removePlayerMark(p, "@chu_niang")
                                room:drawCards(player, player:getMaxHp(), self:objectName())
                            end
                        end
                    end
                end
            end
        else
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Discard and player:hasFlag("chu_niang_zero_max_cards") then
                room:setPlayerFlag(player, "-chu_niang_zero_max_cards")
                if player:getMark("@chu_niang") ~= 0
                    and room:askForSkillInvoke(player, self:objectName(),
                        sgs.QVariant("@chu_niang:" .. player:objectName())) then
                    room:removePlayerMark(player, "@chu_niang")
                    room:drawCards(player, player:getMaxHp(), self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MiyuSuzumoto:addSkill(sakamichi_chu_niang)

sakamichi_yan_yiCard = sgs.CreateSkillCard {
    name = "sakamichi_yan_yiCard",
    skill_name = "sakamichi_yan_yi",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            for _, skill in sgs.qlist(to_select:getVisibleSkillList()) do
                if skill:getFrequency() == sgs.Skill_Limited then
                    return true
                end
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@yan_yi")
        local SkillList = {}
        for _, skill in sgs.qlist(effect.to:getVisibleSkillList()) do
            if skill:getFrequency() == sgs.Skill_Limited then
                table.insert(SkillList, skill:objectName())
            end
        end
        if #SkillList > 0 then
            local skill_name = room:askForChoice(effect.from, self:objectName(), table.concat(SkillList, "+"))
            room:setPlayerMark(effect.to, sgs.Sanguosha:getSkill(skill_name):getLimitMark(), 1)
        end
    end,
}
sakamichi_yan_yi = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_yan_yi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@yan_yi",
    view_as = function(self)
        return sakamichi_yan_yiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@yan_yi") ~= 0
    end,
}
MiyuSuzumoto:addSkill(sakamichi_yan_yi)

sgs.LoadTranslationTable {
    ["MiyuSuzumoto"] = "?????? ??????",
    ["&MiyuSuzumoto"] = "?????? ??????",
    ["#MiyuSuzumoto"] = "?????????",
    ["~MiyuSuzumoto"] = "??????????????????????????????",
    ["designer:MiyuSuzumoto"] = "Cassimolar",
    ["cv:MiyuSuzumoto"] = "?????? ??????",
    ["illustrator:MiyuSuzumoto"] = "Cassimolar",
    ["sakamichi_li_zi"] = "??????",
    [":sakamichi_li_zi"] = "???????????????????????????????????????????????????????????????????????????????????????????????????X???????????????????????????????????????????????????????????????????????????????????????X?????????????????????????????????????????????????????????????????????????????????Y?????????????????????????????????1????????????Y???????????????????????????????????????1??????",
    ["@li_zi"] = "??????",
    ["sakamichi_chu_niang"] = "??????",
    [":sakamichi_chu_niang"] = "???????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@chu_niang"] = "??????",
    ["sakamichi_chu_niang:@chu_niang"] = "????????????%src???????????????????????????",
    ["sakamichi_yan_yi"] = "??????",
    [":sakamichi_yan_yi"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????",
}
