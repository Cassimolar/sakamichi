require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HazukiMukai = sgs.General(Sakamichi, "HazukiMukai", "Nogizaka46", 4, false)
SKMC.SanKiSei.HazukiMukai = true
SKMC.SeiMeiHanDan.HazukiMukai = {
    name = {6, 4, 12, 4},
    ten_kaku = {10, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {26, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_re_xue_card = sgs.CreateSkillCard {
    name = "sakamichi_re_xueCard",
    skill_name = "sakamichi_re_xue",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() then
            local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)
            duel:deleteLater()
            duel:setSkillName(self:getSkillName())
            return duel:targetFilter(sgs.PlayerList(), to_select, sgs.Self)
        end
        return false
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:loseHp(effect.from, SKMC.number_correction(effect.from, 1))
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, -1)
        duel:deleteLater()
        duel:setSkillName(self:getSkillName())
        room:useCard(sgs.CardUseStruct(duel, effect.from, effect.to))
    end,
}
sakamichi_re_xue = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_re_xue",
    view_as = function()
        return sakamichi_re_xue_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_re_xueCard")
    end,
}
HazukiMukai:addSkill(sakamichi_re_xue)

sakamichi_lian_zhan = sgs.CreateTriggerSkill {
    name = "sakamichi_lian_zhan",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Duel") then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
                if room:getCurrent():getMark("lian_zhan_" .. player:objectName() .. "_to_" .. p:objectName()
                                                 .. "_finish_end_clear") == 0 then
                    local duel = sgs.Sanguosha:cloneCard("duel", damage.card:getSuit(), damage.card:getNumber())
                    duel:deleteLater()
                    duel:setSkillName(self:objectName())
                    if duel:targetFilter(sgs.PlayerList(), p, player) then
                        targets:append(p)
                    end
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@lian_zhan_invoke", true)
                if target then
                    room:setPlayerMark(room:getCurrent(), "lian_zhan_" .. player:objectName() .. "_to_"
                        .. damage.to:objectName() .. "_finish_end_clear", 1)
                    local duel = sgs.Sanguosha:cloneCard("duel", damage.card:getSuit(), damage.card:getNumber())
                    duel:deleteLater()
                    duel:setSkillName(self:objectName())
                    room:useCard(sgs.CardUseStruct(duel, player, target, false))
                end
            end
        end
        return false
    end,
}
HazukiMukai:addSkill(sakamichi_lian_zhan)

sakamichi_qiang_yun = sgs.CreateTriggerSkill {
    name = "sakamichi_qiang_yun",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DrawInitialCards, sgs.BeforeCardsMove},
    priority = -1,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawInitialCards then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                for i = 1, 2, 1 do
                    local choices = {}
                    for k, v in pairs(SKMC.Pattern) do
                        if type(v) == "table" then
                            table.insert(choices, k)
                        else
                            table.insert(choices, v)
                        end
                    end
                    if i == 2 then
                        table.insert(choices, "cancel")
                    end
                    local choice
                    local _Pattern = SKMC.Pattern
                    while true do
                        choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                        if _Pattern[choice] ~= nil then
                            _Pattern = _Pattern[choice]
                            choices = {}
                            for k, v in pairs(_Pattern) do
                                if type(v) == "table" then
                                    table.insert(choices, k)
                                else
                                    table.insert(choices, v)
                                end
                            end
                        else
                            break
                        end
                    end
                    if choice ~= "cancel" then
                        local choice_pattern = player:getTag(self:objectName()):toString():split(",")
                        table.insert(choice_pattern, choice)
                        player:setTag(self:objectName(), sgs.QVariant(table.concat(choice_pattern, ",")))
                        if not player:hasFlag(self:objectName()) then
                            room:setPlayerFlag(player, self:objectName())
                        end
                    else
                        break
                    end
                end
            end
        elseif event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and player:hasFlag(self:objectName())
                and move.to_place == sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_DrawPile) then
                room:setPlayerFlag(player, "-" .. self:objectName())
                local choice_pattern = player:getTag(self:objectName()):toString():split(",")
                player:removeTag(self:objectName())
                local pattern_1, pattern_2
                if #choice_pattern >= 1 then
                    pattern_1 = choice_pattern[1]
                end
                if #choice_pattern == 2 then
                    pattern_2 = choice_pattern[2]
                end
                local move_list = sgs.IntList()
                if pattern_1 ~= nil then
                    for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
                        if sgs.Sanguosha:getEngineCard(id):objectName() == pattern_1 and room:getCardPlace(id)
                            == sgs.Player_DrawPile then
                            move_list:append(id)
                            break
                        end
                    end
                end
                if pattern_2 ~= nil then
                    for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
                        if sgs.Sanguosha:getEngineCard(id):objectName() == pattern_2 and room:getCardPlace(id)
                            == sgs.Player_DrawPile then
                            move_list:append(id)
                            break
                        end
                    end
                end
                for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
                    if room:getCardPlace(id) == sgs.Player_DrawPile then
                        if move_list:length() ~= move.card_ids:length() then
                            move_list:append(id)
                        else
                            break
                        end
                    end
                end
                move.card_ids = move_list
                data:setValue(move)
            end
        end
        return false
    end,
}
HazukiMukai:addSkill(sakamichi_qiang_yun)

sgs.LoadTranslationTable {
    ["HazukiMukai"] = "向井 葉月",
    ["&HazukiMukai"] = "向井 葉月",
    ["#HazukiMukai"] = "铁血南推",
    ["~HazukiMukai"] = "お〜！",
    ["designer:HazukiMukai"] = "Cassimolar",
    ["cv:HazukiMukai"] = "向井 葉月",
    ["illustrator:HazukiMukai"] = "Cassimolar",
    ["sakamichi_re_xue"] = "热血",
    [":sakamichi_re_xue"] = "出牌阶段限一次，你可以失去1点体力视为对一名其他角色使用一张【决斗】。",
    ["sakamichi_lian_zhan"] = "连战",
    [":sakamichi_lian_zhan"] = "当你使用【决斗】对其他角色造成伤害后，你可以视为对另一名其他角色使用一张【决斗】（每回合每名其他角色只可以选择一次）。",
    ["@lian_zhan_invoke"] = "你可以选择另一名其他角色视为对其使用一张【决斗】",
    ["sakamichi_qiang_yun"] = "强运",
    [":sakamichi_qiang_yun"] = "分发起始手牌时，你可以至多选择两次牌名，你的起始手牌中必定包含所选择的牌。",
}
