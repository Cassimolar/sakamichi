require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaIkoma = sgs.General(Sakamichi, "RinaIkoma$", "Nogizaka46", 4, false)
SKMC.IKiSei.RinaIkoma = true
SKMC.SeiMeiHanDan.RinaIkoma = {
    name = {5, 15, 7, 8},
    ten_kaku = {20, "xiong"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_xi_wang = sgs.CreateTriggerSkill {
    name = "sakamichi_xi_wang$",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:getKingdom() == "Nogizaka46" and dying.who:getMark("xi_wang_used") == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self) and room:askForSkillInvoke(dying.who, self:objectName(), sgs.QVariant(
                    "invoke:" .. p:objectName() .. "::" .. self:objectName())) then
                    room:addPlayerMark(dying.who, "xi_wang_used", 1)
                    dying.who:throwAllHandCards()
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, SKMC.number_correction(p, 1)))
                    local n = 0
                    for _, pl in sgs.qlist(room:getAlivePlayers()) do
                        if pl:getKingdom() == "Nogizaka46" then
                            n = n + 1
                        end
                    end
                    room:drawCards(dying.who, n, self:objectName())
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
RinaIkoma:addSkill(sakamichi_xi_wang)

sakamichi_jiao_huan_card = sgs.CreateSkillCard {
    name = "sakamichi_jiao_huanCard",
    skill_name = "sakamichi_jiao_huan",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return to_select:getHandcardNum() >= self:subcardsLength() and to_select:getKingdom()
                       ~= sgs.Self:getKingdom()
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local cards = room:askForExchange(effect.to, self:getSkillName(), self:subcardsLength(), self:subcardsLength(),
            false, "@jiao_huang_sheng:" .. effect.from:objectName() .. "::" .. self:subcardsLength())
        room:obtainCard(effect.from, cards, false)
        room:obtainCard(effect.to, self, false)
    end,
}
sakamichi_jiao_huan = sgs.CreateViewAsSkill {
    name = "sakamichi_jiao_huan",
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local cd = sakamichi_jiao_huan_card:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            cd:setSkillName(self:objectName())
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_jiao_huanCard") and not player:isKongcheng()
                   and SKMC.has_specific_kingdom_player(player, false)
    end,
}
RinaIkoma:addSkill(sakamichi_jiao_huan)

sakamichi_shao_nian_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_shao_nian",
    view_as = function(self)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        duel:setSkillName(self:objectName())
        duel:addSubcards(sgs.Self:getHandcards())
        return duel
    end,
    enabled_at_play = function(self, player)
        return player:getMark("shao_nian_used") < 2 and not player:isKongcheng()
    end,
}
sakamichi_shao_nian = sgs.CreateTriggerSkill {
    name = "sakamichi_shao_nian",
    events = {sgs.CardFinished, sgs.PreDamageDone, sgs.EventPhaseChanging, sgs.CardUsed, sgs.DamageCaused},
    view_as_skill = sakamichi_shao_nian_view_as,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreDamageDone then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == self:objectName()
                and damage.from then
                room:drawCards(damage.to, 1, self:objectName())
                room:addPlayerMark(damage.to, "shao_nian_used")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == self:objectName() then
                room:drawCards(use.from, 1, self:objectName())
                room:addPlayerMark(use.from, "shao_nian_used")
                if use.card:hasFlag("shao_nian_damage") then
                    room:setCardFlag(use.card, "-shao_nian_damage")
                end
                if use.card:hasFlag("shao_nian_from" .. use.from:objectName()) then
                    room:setCardFlag(use.card, "-shao_nian_from" .. use.from:objectName())
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    room:setPlayerMark(p, "shao_nian_used", 0)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == self:objectName()
                and use.from:objectName() == player:objectName() and player:hasSkill(self) then
                room:setCardFlag(use.card, "shao_nian_from" .. player:objectName())
                local no_respond_list = use.no_respond_list
                for _, p in sgs.qlist(use.to) do
                    if use.card:getSubcards():length() >= p:getHp() then
                        table.insert(no_respond_list, p:objectName())
                    end
                end
                if use.card:getSubcards():length() <= use.from:getHp() then
                    room:setCardFlag(use.card, "shao_nian_damage")
                end
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("shao_nian_damage") then
                local from
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if damage.card:hasFlag("shao_nian_from" .. p:objectName()) then
                        from = p
                    end
                end
                if from then
                    damage.damage = damage.damage + SKMC.number_correction(from, 1)
                else
                    damage.damage = damage.damage + 1
                end
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RinaIkoma:addSkill(sakamichi_shao_nian)

sgs.LoadTranslationTable {
    ["RinaIkoma"] = "?????? ??????",
    ["&RinaIkoma"] = "?????? ??????",
    ["#RinaIkoma"] = "????????????",
    ["~RinaIkoma"] = "???????????????????????????????????????????????????????????????????????????",
    ["designer:RinaIkoma"] = "Cassimolar",
    ["cv:RinaIkoma"] = "?????? ??????",
    ["illustrator:RinaIkoma"] = "Cassimolar",
    ["sakamichi_xi_wang"] = "??????",
    [":sakamichi_xi_wang"] = "???????????????????????????46????????????????????????????????????????????????????????????????????????????????????1???????????????X?????????X??????????????????46?????????????????????",
    ["sakamichi_xi_wang:invoke"] = "????????????%src ??????%arg???",
    ["sakamichi_jiao_huan"] = "??????",
    [":sakamichi_jiao_huan"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@jiao_huang_sheng"] = "??????????????????%src????????? %arg ?????????",
    ["sakamichi_shao_nian"] = "??????",
    [":sakamichi_shao_nian"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????+1?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
}
