require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MinamiKoike_Keyakizaka = sgs.General(Sakamichi, "MinamiKoike_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.MinamiKoike_Keyakizaka = true
SKMC.SeiMeiHanDan.MinamiKoike_Keyakizaka = {
    name = {3, 6, 9, 8},
    ten_kaku = {9, "xiong"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {26, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_sa_jiaoCard = sgs.CreateSkillCard {
    name = "sakamichi_sa_jiaoCard",
    skill_name = "sakamichi_sa_jiao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.to:isNude() then
            room:setPlayerMark(effect.to, "sa_jiao_distance", 1)
        else
            local choice = room:askForChoice(effect.from, "sakamichi_sa_jiao", "BasicCard+TrickCard+EquipCard")
            local card = room:askForCard(effect.to, choice,
                "@sa_jiao_give_1:" .. effect.from:objectName() .. "::" .. choice, sgs.QVariant(), sgs.Card_MethodNone)
            if card then
                room:moveCardTo(card, effect.from, sgs.Player_PlaceHand,
                    sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.to:objectName(),
                        effect.from:objectName(), self:getSkillName(), ""))
                room:showCard(effect.from, card:getEffectiveId())
                room:addPlayerMark(effect.from, "sa_jiao" .. card:getClassName() .. "_finish_end_clear")
            else
                room:setPlayerCardLimitation(effect.to, "use,response", ".|.|.|hand", true)
            end
        end
    end,
}
sakamichi_sa_jiao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sa_jiao",
    view_as = function()
        return sakamichi_sa_jiaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_sa_jiaoCard")
    end,
}
sakamichi_sa_jiao = sgs.CreateTriggerSkill {
    name = "sakamichi_sa_jiao",
    view_as_skill = sakamichi_sa_jiao_view_as,
    events = {sgs.CardUsed, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and player:hasSkill(self) and room:askForSkillInvoke(player, self:objectName(), data) then
                local choice = room:askForChoice(player, self:objectName(), "BasicCard+TrickCard+EquipCard")
                local card = room:askForCard(damage.from, choice,
                    "@sa_jiao_give_2:" .. player:objectName() .. "::" .. choice, sgs.QVariant(), sgs.Card_MethodNone)
                if card then
                    room:moveCardTo(card, player, sgs.Player_PlaceHand,
                        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, damage.from:objectName(),
                            player:objectName(), self:objectName(), ""))
                    room:showCard(player, card:getEffectiveId())
                    if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("sa_jiao_discard")) then
                        room:throwCard(card, player, player)
                        room:drawCards(player, 1, self:objectName())
                    end
                else
                    room:addMaxCards(damage.from, -1, true)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getMark("sa_jiao" .. use.card:getClassName() .. "_finish_end_clear") > 0 then
                local no_respond_list = use.no_respond_list
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    table.insert(no_respond_list, p:objectName())
                end
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MinamiKoike_Keyakizaka:addSkill(sakamichi_sa_jiao)

sakamichi_ruan_jiaoCard = sgs.CreateSkillCard {
    name = "sakamichi_ruan_jiaoCard",
    skill_name = "sakamichi_ruan_jiao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        -- local card = room:askForCard(effect.to, "Horse|.|.|equipped", "@ruan_jiao_discard:" .. effect.from:objectName(), sgs.QVariant(), self:objectName())
        if not room:askForDiscard(effect.to, self:getSkillName(), 1, 1, true, true,
            "@ruan_jiao_discard:" .. effect.from:objectName(), "Hourse|.|.|equipped", self:getSKillName()) then
            room:setPlayerFlag(effect.from, "ruan_jiao" .. effect.to:objectName())
        end
    end,
}
sakamichi_ruan_jiao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_ruan_jiao",
    view_as = function()
        return sakamichi_ruan_jiaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_ruan_jiaoCard")
    end,
}
sakamichi_ruan_jiao = sgs.CreateTriggerSkill {
    name = "sakamichi_ruan_jiao",
    view_as_skill = sakamichi_ruan_jiao_view_as,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if player:hasFlag("ruan_jiao" .. damage.to:objectName()) then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
MinamiKoike_Keyakizaka:addSkill(sakamichi_ruan_jiao)

sakamichi_qi_e = sgs.CreateTriggerSkill {
    name = "sakamichi_qi_e",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getHandcardNum() < player:getHp() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(p, self:objectName(), data) then
                    if room:askForChoice(p, self:objectName(), "draw=" .. player:objectName() .. "+damage="
                        .. player:objectName() .. "=" .. SKMC.number_correction(p, 1)) == "draw=" .. player:objectName() then
                        room:drawCards(player, 1, self:objectName())
                    else
                        room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(p, 1)))
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

sgs.LoadTranslationTable {
    ["MinamiKoike_Keyakizaka"] = "小池 美波",
    ["&MinamiKoike_Keyakizaka"] = "小池 美波",
    ["#MinamiKoike_Keyakizaka"] = "软池",
    ["~MinamiKoike_Keyakizaka"] = "何か悪いことしましたか？",
    ["designer:MinamiKoike_Keyakizaka"] = "Cassimolar",
    ["cv:MinamiKoike_Keyakizaka"] = "小池 美波",
    ["illustrator:MinamiKoike_Keyakizaka"] = "Cassimolar",
    ["sakamichi_sa_jiao"] = "撒娇",
    [":sakamichi_sa_jiao"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>/当你受到伤害后，你可以令一名其他角色/伤害来源交给你一张指定类型的牌并展示，本回合内你使用与此牌名称相同的牌不能被其他角色响应/你可以弃置此牌来摸一张牌；若其未如此做，本回合内其无法使用或打出手牌/其手牌上限-1。",
    ["@sa_jiao_give_1"] = "请交给%src一张%arg否则本回合内%src与你的距离为1",
    ["@sa_jiao_give_2"] = "请交给%src一张%arg否则本回合内手牌上限-1",
    ["sakamichi_sa_jiao:sa_jiao_discard"] = "是否弃置此牌来摸一张牌",
    ["sakamichi_ruan_jiao"] = "软脚",
    [":sakamichi_ruan_jiao"] = "出牌阶段限一次，你可以令一名其他角色弃置装备区的一张坐骑牌，若其未如此做，本回合内你对其造成伤害后摸一张牌。",
    ["@ruan_jiao_discard"] = "请弃置一张装备区的坐骑牌，否则本回合内%src对你造成伤害时可以摸一张牌",
    ["sakamichi_qi_e"] = "企鹅",
    [":sakamichi_qi_e"] = "每名角色结束阶段，若其手牌数小于其体力值，你可以令其摸一张牌或对其造成1点伤害。",
}
