require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AyaneSuzuki = sgs.General(Sakamichi, "AyaneSuzuki", "Nogizaka46", 4, false)
SKMC.NiKiSei.AyaneSuzuki = true
SKMC.SeiMeiHanDan.AyaneSuzuki = {
    name = {13, 4, 12, 9},
    ten_kaku = {17, "ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {22, "xiong"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fei_ji = sgs.CreateTargetModSkill {
    name = "sakamichi_fei_ji",
    pattern = "Slash, TrickCard",
    frequency = sgs.Skill_Compulsory,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill(self) then
            return 1000
        else
            return 0
        end
    end,
}
AyaneSuzuki:addSkill(sakamichi_fei_ji)

sakamichi_wu_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_sheng",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge)
            and not player:isSkipped(sgs.Player_Draw) then
            if player:askForSkillInvoke(self:objectName(), data) then
                player:skip(sgs.Player_Judge)
                player:skip(sgs.Player_Draw)
                local move = sgs.CardsMoveStruct()
                for _, card in sgs.qlist(player:getJudgingArea()) do
                    move.card_ids:append(card:getEffectiveId())
                end
                local candraw = false
                if move.card_ids:length() < 2 then
                    candraw = true
                end
                move.to = player
                move.to_place = sgs.Player_PlaceHand
                SKMC.send_message(room, "#wu_sheng_got", player, nil, nil,
                    table.concat(sgs.QList2Table(move.card_ids), "+"))
                room:moveCardsAtomic(move, true)
                if candraw then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
AyaneSuzuki:addSkill(sakamichi_wu_sheng)

sakamichi_jie_zi_card = sgs.CreateSkillCard {
    name = "sakamichi_jie_ziCard",
    skill_name = "sakamichi_jie_zi",
    will_throw = true,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local player = source
        local name_num = SKMC.get_string_word_number(sgs.Sanguosha:translate(
            sgs.Sanguosha:getCard(self:getEffectiveId()):objectName()))
        local card_ids = room:getNCards(name_num)
        room:fillAG(card_ids)
        local to_get = sgs.IntList()
        local to_throw = sgs.IntList()
        while true do
            local sum = 0
            for _, id in sgs.qlist(to_get) do
                sum = sum + SKMC.get_string_word_number(sgs.Sanguosha:translate(sgs.Sanguosha:getCard(id):objectName()))
            end
            for _, id in sgs.qlist(card_ids) do
                if sum + SKMC.get_string_word_number(sgs.Sanguosha:translate(sgs.Sanguosha:getCard(id):objectName()))
                    > name_num + 1 then
                    room:takeAG(nil, id, false)
                    card_ids:removeOne(id)
                    to_throw:append(id)
                end
            end
            if card_ids:isEmpty() then
                break
            end
            local card_id = room:askForAG(player, card_ids, true, self:getSkillName())
            if card_id == -1 then
                break
            end
            card_ids:removeOne(card_id)
            to_get:append(card_id)
            room:takeAG(player, card_id, false)
            if card_ids:isEmpty() then
                break
            end
        end
        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        dummy:deleteLater()
        if not to_get:isEmpty() then
            dummy:addSubcards(to_get)
            player:obtainCard(dummy)
            dummy:clearSubcards()
        end
        if not to_throw:isEmpty() or not card_ids:isEmpty() then
            dummy:addSubcards(to_throw)
            dummy:addSubcards(card_ids)
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
                self:objectName(), nil)
            room:throwCard(dummy, reason, nil)
        end
        room:clearAG()
        room:broadcastInvoke("clearAG")
    end,
}
sakamichi_jie_zi = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_jie_zi",
    filter_pattern = ".",
    view_as = function(self, card)
        local cd = sakamichi_jie_zi_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_jie_ziCard") and not player:isNude()
    end,
}
AyaneSuzuki:addSkill(sakamichi_jie_zi)

sgs.LoadTranslationTable {
    ["AyaneSuzuki"] = "鈴木 絢音",
    ["&AyaneSuzuki"] = "鈴木 絢音",
    ["#AyaneSuzuki"] = "秋田美人",
    ["~AyaneSuzuki"] = "お金ありますか？",
    ["designer:AyaneSuzuki"] = "Cassimolar",
    ["cv:AyaneSuzuki"] = "鈴木 絢音",
    ["illustrator:AyaneSuzuki"] = "Cassimolar",
    ["sakamichi_fei_ji"] = "飞机",
    [":sakamichi_fei_ji"] = "锁定技，你使用【杀】和锦囊牌无距离限制。",
    ["sakamichi_wu_sheng"] = "无声",
    [":sakamichi_wu_sheng"] = "你可以跳过你的判定阶段和摸牌阶段，然后获得你判定区内所有牌，若你以此法获得的牌少于两张，你摸一张牌。",
    ["#wu_sheng_got"] = "%from 获得其判定区内所有牌：%card",
    ["sakamichi_jie_zi"] = "解字",
    [":sakamichi_jie_zi"] = "出牌阶段限一次，你可以弃置一张牌，然后翻开牌堆顶的X张牌，选择并获得其中任意张牌名字数相加不大于X+1的牌（X为此牌的牌名字数）。",
}
