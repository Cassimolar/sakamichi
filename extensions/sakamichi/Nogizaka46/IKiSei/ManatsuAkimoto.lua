require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManatsuAkimoto = sgs.General(Sakamichi, "ManatsuAkimoto", "Nogizaka46", 3, false)
SKMC.IKiSei.ManatsuAkimoto = true
SKMC.SeiMeiHanDan.ManatsuAkimoto = {
    name = {9, 4, 10, 10},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zi_q_card = sgs.CreateSkillCard {
    name = "sakamichi_zi_q_Card",
    skill_name = "sakamichi_zi_q",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark("zi_q_illegal_target") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:obtainCard(effect.to, self)
        local result = SKMC.run_judge(room, effect.to, self:getSkillName(), ".")
        local suit = result.card:getSuitString()
        SKMC.send_message(room, "#zi_q_" .. suit, effect.to, nil, nil, nil, self:getSkillName())
        if suit == "spade" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            room:setPlayerFlag(effect.from, "zi_q" .. effect.to:objectName())
            room:addPlayerMark(effect.to, "@skill_invalidity")
        elseif suit == "heart" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            if effect.to:isWounded() then
                room:recover(effect.to, sgs.RecoverStruct(effect.from, self, 1))
            end
            effect.to:turnOver()
            room:setPlayerMark(effect.to, "zi_q_illegal_target", 1)
        elseif suit == "club" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            room:setPlayerFlag(effect.from, "zi_q_armor" .. effect.to:objectName())
            room:addPlayerMark(effect.to, "Armor_Nullified")
        elseif suit == "diamond" then
            room:setPlayerFlag(effect.from, "zi_q_used")
            room:drawCards(effect.to, 4, self:getSkillName())
            if effect.to:getHandcardNum() + effect.to:getEquips():length() <= 2 then
                effect.to:throwAllHandCardsAndEquips()
            else
                room:askForDiscard(effect.to, self:getSkillName(), 2, 2, false, true)
            end
        end
    end,
}
sakamichi_zi_q_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_zi_q",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_zi_q_card:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        local have_legal_target = false
        for _, p in sgs.qlist(player:getSiblings()) do
            if p:getMark("zi_q_illegal_target") == 0 then
                have_legal_target = true
                break
            end
        end
        return have_legal_target and not player:hasFlag("zi_q_used")
    end,
}
sakamichi_zi_q = sgs.CreateTriggerSkill {
    name = "sakamichi_zi_q",
    events = {sgs.EventPhaseChanging},
    view_as_skill = sakamichi_zi_q_view_as,
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:hasFlag("zi_q" .. p:objectName()) then
                    room:removePlayerMark(p, "@skill_invalidity")
                    room:setPlayerFlag(player, "-zi_q" .. p:objectName())
                end
                if player:hasFlag("zi_q_armor" .. p:objectName()) then
                    room:removePlayerMark(p, "Armor_Nullified")
                    room:setPlayerFlag(player, "-zi_q_armor" .. p:objectName())
                end
            end
        end
        return false
    end,
}
ManatsuAkimoto:addSkill(sakamichi_zi_q)

sakamichi_xiao_ju_chang = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_ju_chang",
    events = {sgs.EventPhaseChanging, sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive and room:askForSkillInvoke(player, self:objectName(), data) then
                player:turnOver()
            end
        else
            local use = data:toCardUse()
            if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and not player:faceUp() then
                SKMC.send_message(room, "#xiao_ju_chang_avoid", player, nil, nil, use.card:toString(), self:objectName())
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
        return false
    end,
}
ManatsuAkimoto:addSkill(sakamichi_xiao_ju_chang)

sakamichi_mo_yin_card = sgs.CreateSkillCard {
    name = "sakamichi_mo_yinCard",
    skill_name = "sakamichi_mo_yin",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@mo_yin")
        room:addPlayerMark(source, "mo_yin_used")
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        effect.to:turnOver()
    end,
}
sakamichi_mo_yin_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_mo_yin",
    view_as = function(self)
        return sakamichi_mo_yin_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@mo_yin") ~= 0
    end,
}
sakamichi_mo_yin = sgs.CreateTriggerSkill {
    name = "sakamichi_mo_yin",
    frequency = sgs.Skill_Limited,
    limit_mark = "@mo_yin",
    view_as_skill = sakamichi_mo_yin_view_as,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start then
            if player:getMark("mo_yin_used") ~= 0 then
                room:setPlayerMark(player, "mo_yin_used", 0)
                player:turnOver()
            end
        end
        return false
    end,
}
ManatsuAkimoto:addSkill(sakamichi_mo_yin)

sgs.LoadTranslationTable {
    ["ManatsuAkimoto"] = "秋元 真夏",
    ["&ManatsuAkimoto"] = "秋元 真夏",
    ["#ManatsuAkimoto"] = "好玩不过",
    ["~ManatsuAkimoto"] = "雀の子 そこのけそこのけ 山椒の毛",
    ["designer:ManatsuAkimoto"] = "Cassimolar",
    ["cv:ManatsuAkimoto"] = "秋元 真夏",
    ["illustrator:ManatsuAkimoto"] = "Cassimolar",
    ["sakamichi_zi_q"] = "子Q",
    [":sakamichi_zi_q"] = "出牌阶段限一次，你可以将一张手牌交给一名未以此法翻面的其他角色令其判定，若结果为：黑桃，本回合内其非锁定技失效；红桃，其回复1点体力值并翻面，且此技能对其他角色视为未发动过；梅花，本回合内其防具失效；方块，其摸四张牌然后弃置两张牌。",
    ["#zi_q_spade"] = "本回合内%from 非锁定技失效",
    ["#zi_q_heart"] = "%from 回复1点体力并将武将牌翻面",
    ["#zi_q_club"] = "本回合内%from 防具失效",
    ["#zi_q_diamond"] = "%from 摸四张牌然后弃置两张牌",
    ["sakamichi_xiao_ju_chang"] = "小剧场",
    ["#xiao_ju_chang_avoid"] = "%from 的【%arg】被触发，%card对其无效",
    [":sakamichi_xiao_ju_chang"] = "结束阶段，你可以将翻面。你武将牌背面向上时，【杀】和通常锦囊牌对你无效。",
    ["sakamichi_mo_yin"] = "魔音",
    [":sakamichi_mo_yin"] = "限定技，出牌阶段，你可以令所有其他角色翻面，若如此做，你的下个准备阶段，你翻面。",
}
