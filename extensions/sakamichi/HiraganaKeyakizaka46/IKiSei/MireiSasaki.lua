require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MireiSasaki_HiraganaKeyakizaka = sgs.General(Sakamichi, "MireiSasaki_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 4,
    false)
SKMC.IKiSei.MireiSasaki_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.MireiSasaki_HiraganaKeyakizaka = {
    name = {7, 3, 4, 9, 9},
    ten_kaku = {14, "xiong"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zhang_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_zhang_yu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.NullificationEffect, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isNDTrick() then
                local result = SKMC.run_judge(room, player, self:objectName(), ".|red")
                if result.isBad then
                    if use.card:isKindOf("Nullification") then
                        room:setCardFlag(use.card, "zhang_yu")
                    end
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, "_ALL_TARGETS")
                    use.nullified_list = nullified_list
                    data:setValue(use)
                end
            end
            if use.card:isKindOf("BasicCard") then
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS")
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        elseif event == sgs.NullificationEffect then
            local card = data:toCard()
            if card:hasFlag("zhang_yu") then
                room:setCardFlag(card, "-zhang_yu")
                return true
            end
        end
        return false
    end,
}
MireiSasaki_HiraganaKeyakizaka:addSkill(sakamichi_zhang_yu)

sakamichi_guo_yuCard = sgs.CreateSkillCard {
    name = "sakamichi_guo_yuCard",
    skill_name = "sakamichi_guo_yu",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local gain_list = sgs.IntList()
        for _, id in sgs.qlist(room:getDiscardPile()) do
            if sgs.Sanguosha:getCard(id):getSuit() == self:getSuit() and sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                gain_list:append(id)
            end
        end
        if gain_list:length() ~= 0 then
            room:fillAG(gain_list, source)
            local card_id = room:askForAG(source, gain_list, true, self:objectName())
            if card_id ~= -1 then
                room:obtainCard(source, card_id)
                room:addPlayerMark(source, "guo_yu")
            end
            room:clearAG(source)
        end
    end,
}
sakamichi_guo_yu_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_guo_yu",
    filter_pattern = "TrickCard",
    view_as = function(self, card)
        local cd = sakamichi_guo_yuCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, target)
        return target:getMark("guo_yu") <= target:getHp()
    end,
}
sakamichi_guo_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_guo_yu",
    view_as_skill = sakamichi_guo_yu_view_as,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            room:setPlayerMark(player, "guo_yu", 0)
        end
    end,
}
MireiSasaki_HiraganaKeyakizaka:addSkill(sakamichi_guo_yu)

sgs.LoadTranslationTable {
    ["MireiSasaki_HiraganaKeyakizaka"] = "佐々木 美玲",
    ["&MireiSasaki_HiraganaKeyakizaka"] = "佐々木 美玲",
    ["#MireiSasaki_HiraganaKeyakizaka"] = "N3偶像",
    ["~MireiSasaki_HiraganaKeyakizaka"] = "パンの鉄砲を撃ちますよ！",
    ["designer:MireiSasaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MireiSasaki_HiraganaKeyakizaka"] = "佐々木 美玲",
    ["illustrator:MireiSasaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_zhang_yu"] = "丈育",
    [":sakamichi_zhang_yu"] = "锁定技，你使用通常锦囊牌时须进行一次判定，若结果为黑色，此牌无效。你使用的基本牌无法响应。",
    ["sakamichi_guo_yu"] = "国语",
    [":sakamichi_guo_yu"] = "<font color=\"green\"><b>出牌阶段限X次</b></font>，你可以弃置一张锦囊牌，然后从弃牌堆里获得一张同花色的基本牌（X为你的体力值）。",
    ["sakamichi_shun_jian"] = "瞬间",
}
