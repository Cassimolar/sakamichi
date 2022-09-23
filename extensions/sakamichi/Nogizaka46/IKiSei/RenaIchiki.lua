require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenaIchiki = sgs.General(Sakamichi, "RenaIchiki", "Nogizaka46", 3, false)
SKMC.IKiSei.RenaIchiki = true
SKMC.SeiMeiHanDan.RenaIchiki = {
    name = {5, 8, 9, 8},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {17, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_guo_biao_wu_card = sgs.CreateSkillCard {
    name = "sakamichi_guo_biao_wuCard",
    skill_name = "sakamichi_guo_biao_wu",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.to:isKongcheng() then
            room:setPlayerFlag(effect.to, "guo_biao_wu")
            SKMC.send_message(room, "#guo_biao_wu", effect.from, effect.to, nil, nil, self:getSkillName())
        else
            local data_for_ai = sgs.QVariant()
            data_for_ai:setValue(effect.from)
            local card = room:askForCard(effect.to, ".|.|.|hand", "@guo_biao_wu_give:" .. effect.from:objectName(),
                data_for_ai, sgs.Card_MethodNone)
            if card then
                room:obtainCard(effect.from, card, false)
                room:showCard(effect.from, self:getEffectiveId())
                room:showCard(effect.from, card:getEffectiveId())
                if sgs.Sanguosha:getCard(self:getEffectiveId()):getTypeId() == card:getTypeId() then
                    room:addSlashJuli(effect.from, 1000, true)
                    SKMC.send_message(room, "#guo_biao_wu_type", effect.from, effect.to)
                end
                if sgs.Sanguosha:getCard(self:getEffectiveId()):getSuit() == card:getSuit() then
                    room:addSlashMubiao(effect.from, 1, true)
                    SKMC.send_message(room, "#guo_biao_wu_suit", effect.from, effect.to)
                end
                if sgs.Sanguosha:getCard(self:getEffectiveId()):getNumber() == card:getNumber() then
                    room:setPlayerFlag(effect.from, "guo_biao_wu_number")
                    SKMC.send_message(room, "#guo_biao_wu_number", effect.from, effect.to)
                end
                if SKMC.true_name(sgs.Sanguosha:getCard(self:getEffectiveId())) == SKMC.true_name(card) then
                    room:addSlashCishu(effect.from, 1000, true)
                    SKMC.send_message(room, "#guo_biao_wu_name", effect.from, effect.to)
                end
            else
                room:setPlayerFlag(effect.to, "guo_biao_wu")
                SKMC.send_message(room, "#guo_biao_wu_wu", effect.from, effect.to, nil, nil, self:getSkillName())
            end
        end
        room:throwCard(self, effect.from, effect.from)
    end,
}
sakamichi_guo_biao_wu_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_guo_biao_wu",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_guo_biao_wu_card:clone()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasUsed("#sakamichi_guo_biao_wuCard")
    end,
}
sakamichi_guo_biao_wu = sgs.CreateTriggerSkill {
    name = "sakamichi_guo_biao_wu",
    view_as_skill = sakamichi_guo_biao_wu_view_as,
    events = {sgs.EventPhaseChanging, sgs.SlashProceed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:hasFlag("guo_biao_wu") then
                        room:setPlayerFlag(p, "-guo_biao_wu")
                    end
                end
            end
        elseif event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from:hasSkill(self) and effect.from:hasFlag("guo_biao_wu_number") then
                room:slashResult(effect, nil)
                return true
            end
        end
        return false
    end,
}
sakamichi_guo_biao_wu_Invalidity = sgs.CreateInvaliditySkill {
    name = "#sakamichi_guo_biao_wu_Invalidity",
    skill_valid = function(self, player, skill)
        if player:hasFlag("guo_biao_wu") then
            return false
        else
            return true
        end
    end,
}
RenaIchiki:addSkill(sakamichi_guo_biao_wu)
if not sgs.Sanguosha:getSkill("#sakamichi_guo_biao_wu_Invalidity") then
    SKMC.SkillList:append(sakamichi_guo_biao_wu_Invalidity)
end

sakamichi_mi_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_shu",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.card:getSubcards():length() > 1 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    local ids = room:getNCards(use.card:getSubcards():length())
                    room:fillAG(ids)
                    local id1 = room:askForAG(p, ids, false, self:objectName())
                    room:moveCardTo(sgs.Sanguosha:getCard(id1), p, sgs.Player_PlaceHand, true)
                    room:takeAG(p, id1, false)
                    local id2 = room:askForAG(use.from, ids, false, self:objectName())
                    room:moveCardTo(sgs.Sanguosha:getCard(id2), use.from, sgs.Player_PlaceHand, true)
                    room:takeAG(use.from, id2, false)
                    room:clearAG()
                    room:broadcastInvoke("clearAG")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RenaIchiki:addSkill(sakamichi_mi_shu)

sgs.LoadTranslationTable {
    ["RenaIchiki"] = "市來 玲奈",
    ["&RenaIchiki"] = "市來 玲奈",
    ["#RenaIchiki"] = "初代学霸",
    ["~RenaIchiki"] = "にじゅう…",
    ["designer:RenaIchiki"] = "Cassimolar",
    ["cv:RenaIchiki"] = "市來 玲奈",
    ["illustrator:RenaIchiki"] = "Cassimolar",
    ["sakamichi_guo_biao_wu"] = "国标舞",
    [":sakamichi_guo_biao_wu"] = "出牌阶段限一次，你可以选择一张手牌并令一名其他角色交给你一张手牌，然后展示两张牌，若两张牌类别/花色/点数/牌名相同，你本回合内使用【杀】无距离限制/可以多指定一个目标/无法闪避/无次数限制；若其未交给你手牌，本回合内，其所有技能失效；然后弃置你选择的牌。",
    ["@guo_biao_wu_give"] = "请交给%src一张手牌，否则本回合你的技能失效",
    ["#guo_biao_wu"] = "%to 拒绝将一张手牌交给%from，因【%arg】其本回合内技能失效。",
    ["#guo_biao_wu_type"] = "%to 给%from 的牌与%from 选择的牌类别相同，本回合内%from 使用【杀】无距离限制。",
    ["#guo_biao_wu_suit"] = "%to 交给%from 的牌与%from 选择的牌花色相同，本回合内%from 使用【杀】可以额外指定一个目标。",
    ["#guo_biao_wu_number"] = "%to 交给%from 的牌与%from 选择的牌点数相同，本回合内%from 使用【杀】无法闪避。",
    ["#guo_biao_wu_name"] = "%to 交给%from 的牌与%from 选择的牌牌名相同，本回合内%from 使用【杀】无次数限制。",
    ["sakamichi_mi_shu"] = "秘书",
    [":sakamichi_mi_shu"] = "当一名角色使用牌时，若此牌对应的实体牌多于一张，你可以翻开牌堆顶等量的牌，你和其各选择获得其中的一张。",
}
