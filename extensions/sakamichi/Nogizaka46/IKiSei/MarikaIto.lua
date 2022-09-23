require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MarikaIto = sgs.General(Sakamichi, "MarikaIto", "Nogizaka46", 3, false)
SKMC.IKiSei.MarikaIto = true
SKMC.SeiMeiHanDan.MarikaIto = {
    name = {6, 18, 3, 11, 10},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {24, "da_ji"},
    soto_kaku = {27, "ji_xiong_hun_he"},
    sou_kaku = {48, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "huo",
        GoGyouSanSai = "ji",
    },
}

sakamichi_huan_yi_card = sgs.CreateSkillCard {
    name = "sakamichi_huan_yiCard",
    skill_name = "sakamichi_huan_yi",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return true
        elseif #targets == 1 then
            local n1 = targets[1]:getEquips():length()
            local n2 = to_select:getEquips():length()
            return math.abs(n1 - n2) <= sgs.Self:getHandcardNum() - 1
        else
            return false
        end
    end,
    feasible = function(self, targets)
        if #targets == 0 then
            return true
        end
        if #targets == 2 and (targets[1]:getEquips():length() ~= 0 or targets[2]:getEquips():length() ~= 0) then
            return true
        end
    end,
    on_use = function(self, room, source, targets)
        if #targets == 0 then
            room:moveField(source, self:getSkillName(), false, "ej")
        else
            local equips1, equips2 = sgs.IntList(), sgs.IntList()
            for _, equip in sgs.qlist(targets[1]:getEquips()) do
                equips1:append(equip:getId())
            end
            for _, equip in sgs.qlist(targets[2]:getEquips()) do
                equips2:append(equip:getId())
            end
            local exchangeMove = sgs.CardsMoveList()
            local move1 = sgs.CardsMoveStruct(equips1, targets[2], sgs.Player_PlaceEquip,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, targets[1]:objectName(), targets[2]:objectName(),
                    self:getSkillName(), ""))
            local move2 = sgs.CardsMoveStruct(equips2, targets[1], sgs.Player_PlaceEquip,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, targets[2]:objectName(), targets[1]:objectName(),
                    self:getSkillName(), ""))
            exchangeMove:append(move2)
            exchangeMove:append(move1)
            room:moveCardsAtomic(exchangeMove, false)
            SKMC.send_message(room, "#huan_yi_swap", source, nil, targets, nil, self:getSkillName())
        end
    end,
}
sakamichi_huan_yi = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_huan_yi",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_huan_yi_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "h") and not player:hasUsed("#sakamichi_huan_yiCard")
    end,
}
MarikaIto:addSkill(sakamichi_huan_yi)

sakamichi_shi_shang_card = sgs.CreateSkillCard {
    name = "sakamichi_shi_shangCard",
    skill_name = "sakamichi_shi_shang",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() then
            return to_select:getEquip(sgs.Sanguosha:getCard(self:getEffectiveId()):getRealCard():toEquipCard()
                :location()) == nil
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(),
            self:getSkillName(), "")
        room:moveCardTo(self, effect.from, effect.to, sgs.Player_PlaceEquip, reason)
        SKMC.send_message(room, "#shi_shang_equip", effect.to, nil, nil, self:getSubcards():first():toString())
        room:drawCards(effect.from, 1, self:getSkillName())
        room:addPlayerMark(effect.from, "@da_pei")
    end,
}
sakamichi_shi_shang = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_shi_shang",
    filter_pattern = "EquipCard|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_shi_shang_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}
MarikaIto:addSkill(sakamichi_shi_shang)

sakamichi_da_pei = sgs.CreateTriggerSkill {
    name = "sakamichi_da_pei",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_jiu_yi",
    events = {sgs.EventPhaseChanging},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if data:toPhaseChange().to == sgs.Player_Start and player:getMark("@da_pei") >= 5 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        local choices = {}
        if player:isWounded() then
            table.insert(choices, "recover")
        end
        table.insert(choices, "draw")
        local choice = room:askForChoice(player, self:objectName(), choices)
        SKMC.choice_log(player, choice)
        if choice == "recover" then
            room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
        else
            room:drawCards(player, 2, self:objectName())
        end
        room:handleAcquireDetachSkills(player, "sakamichi_jiu_yi")
        return false
    end,
}
MarikaIto:addSkill(sakamichi_da_pei)

sakamichi_jiu_yi = sgs.CreateTriggerSkill {
    name = "sakamichi_jiu_yi",
    events = {sgs.BeforeCardsMove},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() ~= player:objectName() then
            if move.to_place == sgs.Player_DiscardPile then
                local card_ids = sgs.IntList()
                local i = 0
                for _, id in sgs.qlist(move.card_ids) do
                    if sgs.Sanguosha:getCard(id):getTypeId() == sgs.Card_TypeEquip and room:getCardOwner(id)
                        :objectName() == move.from:objectName() and move.from_places:at(i) == sgs.Player_PlaceEquip then
                        card_ids:append(id)
                    end
                    i = i + 1
                end
                if not card_ids:isEmpty() and player:getMark("@da_pei") ~= 0
                    and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:removePlayerMark(player, "@da_pei")
                    for _, id in sgs.qlist(card_ids) do
                        if player:isDead() then
                            break
                        end
                        if move.card_ids:contains(id) then
                            move.from_places:removeAt(move.card_ids:indexOf(id))
                            move.card_ids:removeOne(id)
                            data:setValue(move)
                        end
                        room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
                    end
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_jiu_yi") then
    SKMC.SkillList:append(sakamichi_jiu_yi)
end

sgs.LoadTranslationTable {
    ["MarikaIto"] = "伊藤 万理華",
    ["&MarikaIto"] = "伊藤 万理華",
    ["#MarikaIto"] = "小圆脸",
    ["~MarikaIto"] = "アンダーの概念ぶっ壊してやる",
    ["designer:MarikaIto"] = "Cassimolar",
    ["cv:MarikaIto"] = "伊藤 万理華",
    ["illustrator:MarikaIto"] = "Cassimolar",
    ["sakamichi_huan_yi"] = "换衣",
    [":sakamichi_huan_yi"] = "出牌阶段限一次，你可以弃置一张手牌并选择一项：移动场上一张装备牌；令装备区的装备牌数量差不超过你手牌数的两名角色交换他们装备区的装备牌。",
    ["#huan_yi_swap"] = "%from 发动【%arg】交换了 %to 的装备",
    ["sakamichi_shi_shang"] = "时尚",
    [":sakamichi_shi_shang"] = "出牌阶段，你可以将手牌中的一张装备牌置于其他角色的装备区，然后你摸一张牌并获得一枚「搭配」标记。",
    ["#shi_shang_equip"] = "%from 被装备了 %card",
    ["sakamichi_da_pei"] = "搭配",
    [":sakamichi_da_pei"] = "觉醒技，准备阶段，若你拥有至少五枚「搭配」标记，你可以回复1点体力或摸两张牌，然后获得【旧衣】。",
    ["sakamichi_da_pei:recover"] = "回复体力",
    ["sakamichi_da_pei:draw"] = "摸两张牌",
    ["@da_pei"] = "搭配",
    ["sakamichi_jiu_yi"] = "旧衣",
    [":sakamichi_jiu_yi"] = "其他角色装备区的装备牌以未经转化的方式置入弃牌堆时，你可以移除一枚「搭配」获得之。",
    ["@jiu_yi_discard"] = "你需要弃置一张装备区的牌",
}
