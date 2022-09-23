require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RiraInoue_Keyakizaka = sgs.General(Sakamichi, "RiraInoue_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.NiKiSei.RiraInoue_Keyakizaka = true
SKMC.SeiMeiHanDan.RiraInoue_Keyakizaka = {
    name = {4, 3, 11, 6},
    ten_kaku = {7, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {17, "ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "xiong",
    },
}

sakamichi_hua_she = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_hua_she",
    filter_pattern = ".|.|.|hand",
    guhuo_type = "lsr",
    view_as = function(self, card)
        local cd = sgs.Self:getTag(self:objectName()):toCard()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("hua_she_used")
    end,
    enabled_at_response = function(self, player, pattern)
        return player:getPhase() == sgs.Player_Play and not player:hasFlag("hua_she_used")
    end,
    enabled_at_nullification = function(self, player)
        return player:getPhase() == sgs.Player_Play and not player:hasFlag("hua_she_used")
    end,
}
sakamichi_hua_she_used = sgs.CreateTriggerSkill {
    name = "#sakamichi_hua_she_used",
    events = {sgs.PreCardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.PreCardUsed then
            card = data:toCardUse().card
        else
            if data:toCardResponse().m_isUse then
                card = data:toCardResponse().m_card
            end
        end
        if card and card:getSkillName() == "sakamichi_hua_she" then
            room:setPlayerFlag(player, "hua_she_used")
        end
        return false
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_hua_she", "#sakamichi_hua_she_used")
RiraInoue_Keyakizaka:addSkill(sakamichi_hua_she)
RiraInoue_Keyakizaka:addSkill(sakamichi_hua_she_used)

sakamichi_chong_fuCard = sgs.CreateSkillCard {
    name = "sakamichi_chong_fuCard",
    skill_name = "sakamichi_chong_fu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "chong_fu", 1)
    end,
}
sakamichi_chong_fu_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_chong_fu",
    view_as = function(self)
        return sakamichi_chong_fuCard:clone()
    end,
    enabled_at_play = function(self, target)
        return not target:hasUsed("#sakamichi_chong_fuCard")
    end,
}
sakamichi_chong_fu = sgs.CreateTriggerSkill {
    name = "sakamichi_chong_fu",
    view_as_skill = sakamichi_chong_fu_view_as,
    events = {sgs.CardUsed, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            if use.card and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and player:getMark("chong_fu") ~= 0 then
                room:setCardFlag(use.card, "chong_fu")
                room:setPlayerMark(player, "chong_fu", 0)
                if use.card:isKindOf("Collateral") then
                    for _, p in sgs.qlist(use.to) do
                        local d = sgs.QVariant()
                        local victim = p:getTag("collateralVictim"):toPlayer()
                        d:setValue(victim)
                        p:setTag("chong_fu_Collateral", d)
                    end
                end
            end
            if use.card:isKindOf("Collateral") and use.card:hasFlag("chong_fu_2") then
                for _, p in sgs.qlist(use.to) do
                    local pl_list = sgs.SPlayerList()
                    for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                        local p_list = sgs.PlayerList()
                        p_list:append(p)
                        if use.card:targetFilter(p_list, pl, player) then
                            pl_list:append(pl)
                        end
                    end
                    if pl_list:isEmpty() then
                        use.to:removeOne(p)
                    else
                        local victim = room:askForPlayerChosen(player, pl_list, self:objectName(),
                            "@chong_fu_collateral:" .. p:objectName() .. "::" .. use.card:objectName())
                        local _data = sgs.QVariant()
                        _data:setValue(victim)
                        p:setTag("collateralVictim", _data)
                    end
                end
            end
        else
            if use.card:hasFlag("chong_fu") then
                room:setCardFlag(use.card, "-chong_fu")
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(use.to) do
                    if not room:isProhibited(player, p, use.card) then
                        if use.card:targetFixed() then
                            if not use.card:isKindOf("Peach") or p:isWounded() then
                                targets:append(p)
                            end
                        else
                            if use.card:targetFilter(sgs.PlayerList(), p, player) then
                                targets:append(p)
                            end
                        end
                    end
                end
                if not targets:isEmpty() then
                    room:setCardFlag(use.card, "chong_fu_2")
                    room:useCard(sgs.CardUseStruct(use.card, player, targets, true), true)
                end
            end
        end
        return false
    end,
}
RiraInoue_Keyakizaka:addSkill(sakamichi_chong_fu)

sgs.LoadTranslationTable {
    ["RiraInoue_Keyakizaka"] = "井上 梨名",
    ["&RiraInoue_Keyakizaka"] = "井上 梨名",
    ["#RiraInoue_Keyakizaka"] = "敢言无惧",
    ["~RiraInoue_Keyakizaka"] = "あなたのために頑張ります！",
    ["designer:RiraInoue_Keyakizaka"] = "Cassimolar",
    ["cv:RiraInoue_Keyakizaka"] = "井上 梨名",
    ["illustrator:RiraInoue_Keyakizaka"] = "Cassimolar",
    ["sakamichi_hua_she"] = "滑舌",
    [":sakamichi_hua_she"] = "出牌阶段限一次，你可以将一张手牌当任意基本牌或通常锦囊牌使用或打出。",
    ["sakamichi_chong_fu"] = "重复",
    [":sakamichi_chong_fu"] = "出牌阶段限一次，你使用的下一张基本牌或通常锦囊牌在结算完成后额外结算一次。",
    ["@chong_fu_collateral"] = "请为此【%arg】的目标%src选择一个使用【杀】的目标",
}
