require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RunaHayashi = sgs.General(Sakamichi, "RunaHayashi", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.RunaHayashi = true
SKMC.SeiMeiHanDan.RunaHayashi = {
    name = {8, 14, 8},
    ten_kaku = {8, "ji"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fan_lai_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_fan_lai",
    view_as = function(self)
        local cd = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(sgs.Self:getMark("fan_lai_play_end_clear"))
            :objectName(), sgs.Sanguosha:getCard(sgs.Self:getMark("fan_lai_play_end_clear")):getSuit(),
            sgs.Sanguosha:getCard(sgs.Self:getMark("fan_lai_play_end_clear")):getNumber())
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        if player:getMark("fan_lai_used_play_end_clear") == 0 and player:getMark("fan_lai_play_end_clear") ~= 0 then
            if sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName() == "analeptic" then
                return sgs.Analeptic_IsAvailable(player)
            end
            if string.find(sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName(), "slash") then
                return sgs.Slash_IsAvailable(player)
            end
            return true
        end
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getPhase() == sgs.Player_Play and player:getMark("fan_lai_play_end_clear") ~= 0
                   and player:getMark("fan_lai_used_play_end_clear") == 0
                   and sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName() == pattern
    end,
    enabled_at_nullification = function(self, player)
        return player:getPhase() == sgs.Player_Play and player:getMark("fan_lai_play_end_clear") ~= 0
                   and player:getMark("fan_lai_used_play_end_clear") == 0
                   and sgs.Sanguosha:getCard(player:getMark("fan_lai_play_end_clear")):objectName() == "nullification"
    end,
}
sakamichi_fan_lai = sgs.CreateTriggerSkill {
    name = "sakamichi_fan_lai",
    view_as_skill = sakamichi_fan_lai_view_as,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed and player:getPhase() ~= sgs.Player_NotActive then
            local use = data:toCardUse()
            if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) and not use.card:isVirtualCard() then
                room:setPlayerMark(player, "fan_lai_play_end_clear", use.card:getId())
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, self:objectName()) then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
                room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. use.card:objectName(), 1)
            end
            if use.card:getSkillName() == self:objectName() then
                room:setPlayerMark(player, "fan_lai_used_play_end_clear", 1)
            end
        end
    end,
}
RunaHayashi:addSkill(sakamichi_fan_lai)

sakamichi_bai_yan_card = sgs.CreateSkillCard {
    name = "sakamichi_bai_yanCard",
    skill_name = "sakamichi_bai_yan",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "fan_lai_play_end_clear", 0)
    end,
}
sakamichi_bai_yan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_bai_yan",
    expand_pile = "raisu",
    filter_pattern = ".|.|.|raisu",
    view_as = function(self, card)
        local cd = sakamichi_bai_yan_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:getPile("raisu"):isEmpty() and not player:hasUsed("#sakamichi_bai_yanCard")
    end,
}
sakamichi_bai_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_bai_yan",
    view_as_skill = sakamichi_bai_yan_view_as,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:loseHp(player, SKMC.number_correction(player, 1))
            room:drawCards(player, 1, self:objectName())
            if damage.card then
                local ids = sgs.IntList()
                if damage.card:isVirtualCard() then
                    ids = damage.card:getSubcards()
                else
                    ids:append(damage.card:getEffectiveId())
                end
                if ids:length() > 0 then
                    local all_place_table = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                            all_place_table = false
                            break
                        end
                    end
                    if all_place_table then
                        room:obtainCard(player, damage.card)
                    end
                end
                if not player:isKongcheng() then
                    local card_id
                    if player:getHandcardNum() == 1 then
                        card_id = player:handCards():first()
                    else
                        local card = room:askForExchange(player, self:objectName(), 1, 1, false, "@bai_yan_push")
                        card_id = card:getEffectiveId()
                    end
                    player:addToPile("raisu", card_id)
                end
            end
        end
        return false
    end,
}
RunaHayashi:addSkill(sakamichi_bai_yan)

sgs.LoadTranslationTable {
    ["RunaHayashi"] = "林 瑠奈",
    ["&RunaHayashi"] = "林 瑠奈",
    ["#RunaHayashi"] = "林皇",
    ["~RunaHayashi"] = "ライスください",
    ["designer:RunaHayashi"] = "Cassimolar",
    ["cv:RunaHayashi"] = "林 瑠奈",
    ["illustrator:RunaHayashi"] = "Cassimolar",
    ["sakamichi_fan_lai"] = "饭来",
    [":sakamichi_fan_lai"] = "出牌阶段限一次，你可以视为使用了本回合上一张使用的非虚拟基本牌或通常锦囊牌。",
    ["sakamichi_bai_yan"] = "白眼",
    [":sakamichi_bai_yan"] = "当你受到一次伤害后，你可以失去1点体力并摸一张牌，然后获得造成伤害的牌，若如此做，你须将一张手牌置于武将牌上称为「米饭」。出牌阶段限一次，你可以移去一张「米饭」令【饭来】视为未发动过。",
    ["@bai_yan_push"] = "请将一张手牌置于武将牌上",
    ["raisu"] = "米饭",
}
