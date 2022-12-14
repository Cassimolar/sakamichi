require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaiShiraishi = sgs.General(Sakamichi, "MaiShiraishi$", "Nogizaka46", 4, false)
SKMC.IKiSei.MaiShiraishi = true
SKMC.SeiMeiHanDan.MaiShiraishi = {
    name = {5, 5, 11, 6},
    ten_kaku = {10, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {27, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_gong_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_gong_shi$",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and not use.card:isKindOf("SkillCard") and player:getKingdom() == "Nogizaka46" and player:getPhase()
            == sgs.Player_Play and not player:hasFlag("gong_shi_used") then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self)
                    and room:askForSkillInvoke(p, self:objectName(),
                        sgs.QVariant("invoke:" .. p:objectName() .. "::" .. self:objectName())) then
                    room:setPlayerFlag(player, "gong_shi_used")
                    local pattern
                    if use.card:isKindOf("BasicCard") then
                        pattern = "BasicCard"
                    elseif use.card:isKindOf("TrickCard") then
                        pattern = "TrickCard"
                    elseif use.card:isKindOf("EquipCard") then
                        pattern = "EquipCard"
                    end
                    local judge = SKMC.run_judge(room, player, self:objectName(), pattern)
                    if judge.isGood then
                        room:drawCards(player, 1, self:objectName())
                        room:drawCards(p, 1, self:objectName())
                    end
                    break
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiShiraishi:addSkill(sakamichi_gong_shi)

sakamichi_nv_shen = sgs.CreateTriggerSkill {
    name = "sakamichi_nv_shen",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TurnOver, sgs.ChainStateChange},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnOver and player:faceUp() then
            if player:hasSkill(self) then
                SKMC.send_message(room, "#nv_shen_turn_over", player, player, nil, nil, self:objectName())
                room:setEmotion(player, "skill_nullify")
                return true
            else
                local list = room:findPlayersBySkillName(self:objectName())
                for _, p in sgs.qlist(list) do
                    if not p:isNude() then
                        local has_red = false
                        for _, card in sgs.qlist(p:getCards("he")) do
                            if card:isRed() then
                                has_red = true
                                break
                            end
                        end
                        if p:canDiscard(p, "he") and has_red then
                            if p:askForSkillInvoke(self:objectName(), data) then
                                room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@nv_shen_discard", ".|red")
                                SKMC.send_message(room, "#nv_shen_turn_over", p, player, nil, nil, self:objectName())
                                room:setEmotion(player, "skill_nullify")
                                return true
                            end
                        end
                    end
                end
            end
        elseif event == sgs.ChainStateChange and (not player:isChained()) then
            if player:hasSkill(self) then
                SKMC.send_message(room, "#nv_shen_chain_state_change", player, player, nil, nil, self:objectName())
                room:setEmotion(player, "skill_nullify")
                return true
            else
                local list = room:findPlayersBySkillName(self:objectName())
                for _, p in sgs.qlist(list) do
                    if not p:isNude() then
                        local has_red = false
                        for _, card in sgs.qlist(p:getCards("he")) do
                            if card:isRed() then
                                has_red = true
                                break
                            end
                        end
                        if p:canDiscard(p, "he") and has_red then
                            if p:askForSkillInvoke(self:objectName(), data) then
                                room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@nv_shen_discard", ".|red")
                                SKMC.send_message(room, "#nv_shen_chain_state_change", p, player, nil, nil,
                                    self:objectName())
                                room:setEmotion(player, "skill_nullify")
                                return true
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
sakamichi_nv_shen_protect = sgs.CreateProhibitSkill {
    name = "#sakamichi_nv_shen_protect",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_nv_shen") and (card:isKindOf("SupplyShortage") or card:isKindOf("Indulgence"))
    end,
}
MaiShiraishi:addSkill(sakamichi_nv_shen)
if not sgs.Sanguosha:getSkill("#sakamichi_nv_shen_protect") then
    SKMC.SkillList:append(sakamichi_nv_shen_protect)
end

sakamichi_hei_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_hei_shi",
    events = {sgs.PreHpRecover},
    on_trigger = function(self, event, player, data, room)
        local recover = data:toRecover()
        if recover.who and recover.who:objectName() ~= player:objectName() and recover.who:hasSkill(self)
            and room:askForSkillInvoke(recover.who, self:objectName(),
                sgs.QVariant("invoke:" .. player:objectName() .. "::" .. self:objectName())) then
            local choice = room:askForChoice(recover.who, self:objectName(),
                "plus=" .. player:objectName() .. "+damage=" .. player:objectName() .. "=" .. recover.recover)
            SKMC.choice_log(recover.who, choice)
            if choice == "plus=" .. player:objectName() then
                recover.recover = recover.recover + SKMC.number_correction(recover.who, 1)
                data:setValue(recover)
            else
                local reason
                if recover.card then
                    reason = recover.card
                else
                    reason = self:objectName()
                end
                room:damage(sgs.DamageStruct(reason, recover.who, player, recover.recover))
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiShiraishi:addSkill(sakamichi_hei_shi)

sgs.LoadTranslationTable {
    ["MaiShiraishi"] = "?????? ??????",
    ["&MaiShiraishi"] = "?????? ??????",
    ["#MaiShiraishi"] = "????????????",
    ["~MaiShiraishi"] = "??????????????????????????????????????????",
    ["designer:MaiShiraishi"] = "Cassimolar",
    ["cv:MaiShiraishi"] = "?????? ??????",
    ["illustrator:MaiShiraishi"] = "Cassimolar",
    ["sakamichi_gong_shi"] = "??????",
    [":sakamichi_gong_shi"] = "?????????????????????46??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_gong_shi:invoke"] = "????????????%src ??????%arg???",
    ["sakamichi_nv_shen"] = "??????",
    [":sakamichi_nv_shen"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["#nv_shen_turn_over"] = "%to ?????? %from???%arg???????????????????????????????????????",
    ["#nv_shen_chain_state_change"] = "%to ?????? %from???%arg???????????????????????????????????????",
    ["@nv_shen_discard"] = "????????????????????? ??? ????????????",
    ["sakamichi_hei_shi"] = "??????",
    [":sakamichi_hei_shi"] = "???????????????????????????????????????????????????????????????+1???????????????????????????????????????????????????",
    ["sakamichi_hei_shi:invoke"] = "?????????%src ?????????%arg???",
    ["sakamichi_hei_shi:plus"] = "???%src ???????????????+1",
    ["sakamichi_hei_shi:damage"] = "???%src ??????%arg?????????",
}
