require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NanamiHashimoto = sgs.General(Sakamichi, "NanamiHashimoto$", "Nogizaka46", 3, false)
SKMC.IKiSei.NanamiHashimoto = true
SKMC.SeiMeiHanDan.NanamiHashimoto = {
    name = {16, 5, 8, 3, 5},
    ten_kaku = {21, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {37, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_zai_jian = sgs.CreateTriggerSkill {
    name = "sakamichi_zai_jian$",
    frequency = sgs.Skill_Limited,
    limit_mark = "@zai_jian",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if player:getMark("@zai_jian") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            room:removePlayerMark(player, "@zai_jian", 1)
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getKingdom() == "Nogizaka46" then
                    if player:objectName() ~= p:objectName() then
                        targets:append(p)
                    end
                    if p:hasJudgeArea() then
                        for _, card in sgs.qlist(p:getJudgingArea()) do
                            room:throwCard(card, p, player)
                        end
                    end
                    if not p:faceUp() then
                        p:turnOver()
                    end
                    room:setPlayerChained(p, false)
                end
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(),
                "@zai_jian_choice:::" .. self:objectName(), true)
            if target then
                room:handleAcquireDetachSkills(target, self:objectName())
            end
        end
        return false
    end,
}
NanamiHashimoto:addSkill(sakamichi_zai_jian)

sakamichi_ming_yan_card = sgs.CreateSkillCard {
    name = "sakamichi_ming_yanCard",
    skill_name = "sakamichi_ming_yan",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            if self:getSuit() == sgs.Card_Club then
                if sgs.Self:distanceTo(to_select) == 1 then
                    local card = sgs.Sanguosha:cloneCard("supply_shortage", self:getSuit(), self:getNumber())
                    card:deleteLater()
                    card:addSubcard(self)
                    card:setSkillName(self:getSkillName())
                    return not to_select:containsTrick("supply_shortage") and not to_select:isProhibited(sgs.Self, card)
                end
            elseif self:getSuit() == sgs.Card_Diamond then
                local card = sgs.Sanguosha:cloneCard("indulgence", self:getSuit(), self:getNumber())
                card:deleteLater()
                card:addSubcard(self)
                card:setSkillName(self:getSkillName())
                return not to_select:containsTrick("indulgence") and not to_select:isProhibited(sgs.Self, card)
            end
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card
        if self:getSuit() == sgs.Card_Club then
            card = sgs.Sanguosha:cloneCard("supply_shortage", self:getSuit(), self:getNumber())
        elseif self:getSuit() == sgs.Card_Diamond then
            card = sgs.Sanguosha:cloneCard("indulgence", self:getSuit(), self:getNumber())
        end
        card:deleteLater()
        card:addSubcard(self)
        card:setSkillName("sakamichi_ming_yan")
        room:useCard(sgs.CardUseStruct(card, effect.from, effect.to, true))
    end,
}
sakamichi_ming_yan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_ming_yan",
    response_pattern = "",
    filter_pattern = ".|club,diamond|.|hand,equipped",
    view_filter = function(self, to_select)
        if sgs.Self:hasFlag("ming_yan_club") then
            return to_select:getSuit() == sgs.Card_Club
        end
        if sgs.Self:hasFlag("ming_yan_diamond") then
            return to_select:getSuit() == sgs.Card_Diamond
        end
        return false
    end,
    view_as = function(self, card)
        local cd = sakamichi_ming_yan_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return string.startsWith(pattern, "@@sakamichi_ming_yan")
    end,
}
sakamichi_ming_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_ming_yan",
    frequency = sgs.Skill_Frequent,
    view_as_skill = sakamichi_ming_yan_view_as,
    events = {sgs.EventPhaseSkipping},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Draw then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    room:setPlayerFlag(p, "ming_yan_club")
                    room:askForUseCard(p, "@@sakamichi_ming_yan", "@ming_yan_invoke:::club:supply_shortage", -1)
                    room:setPlayerFlag(p, "-ming_yan_club")
                end
            end
        elseif player:getPhase() == sgs.Player_Play then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    room:setPlayerFlag(p, "ming_yan_diamond")
                    room:askForUseCard(p, "@@sakamichi_ming_yan", "@ming_yan_invoke:::diamond:indulgence", -1)
                    room:setPlayerFlag(p, "-ming_yan_diamond")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanamiHashimoto:addSkill(sakamichi_ming_yan)

sakamichi_gai_ming_nanamihashimoto = sgs.CreateTriggerSkill {
    name = "sakamichi_gai_ming_nanamihashimoto",
    events = {sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        local prompt_list = {"@gai_ming_nanamihashimoto_card", judge.who:objectName(), self:objectName(), judge.reason,
            string.format("%d", judge.card:getEffectiveId())}
        local prompt = table.concat(prompt_list, ":")
        local card = room:askForCard(player, ".", prompt, data, sgs.Card_MethodResponse, judge.who, true)
        if card then
            room:retrial(card, player, judge, self:objectName(), false)
        end
        return false
    end,
    can_trigger = function(self, target)
        if not (target and target:isAlive() and target:hasSkill(self)) then
            return false
        end
        if target:isNude() then
            return false
        else
            return true
        end
    end,
}
NanamiHashimoto:addSkill(sakamichi_gai_ming_nanamihashimoto)

sgs.LoadTranslationTable {
    ["NanamiHashimoto"] = "?????? ?????????",
    ["&NanamiHashimoto"] = "?????? ?????????",
    ["#NanamiHashimoto"] = "????????????",
    ["~NanamiHashimoto"] = "????????????????????????????????????",
    ["designer:NanamiHashimoto"] = "Cassimolar",
    ["cv:NanamiHashimoto"] = "?????? ?????????",
    ["illustrator:NanamiHashimoto"] = "Cassimolar",
    ["sakamichi_zai_jian"] = "??????",
    [":sakamichi_zai_jian"] = "????????????????????????????????????????????????????????????????????????46???????????????????????????????????????????????????????????????????????????????????????????????????46????????????????????????????????????????????????????????????????????????",
    ["@zai_jian"] = "??????",
    ["@zai_jian_choice"] = "?????????????????????????????????46?????????????????????%arg???",
    ["sakamichi_ming_yan"] = "??????",
    [":sakamichi_ming_yan"] = "???????????????????????????????????????/?????????????????????????????????????????????/??????????????????????????????/???????????????????????????",
    ["@ming_yan_invoke"] = "??????????????????%arg????????????%arg2?????????",
    ["sakamichi_gai_ming_nanamihashimoto"] = "??????",
    [":sakamichi_gai_ming_nanamihashimoto"] = "????????????????????????????????????????????????????????????????????????",
    ["@gai_ming_nanamihashimoto_card"] = "????????????%dest???????????? %src ??? %arg ??????",
}
