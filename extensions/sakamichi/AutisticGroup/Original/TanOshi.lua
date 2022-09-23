require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

TanOshi = sgs.General(Sakamichi, "TanOshi", "AutisticGroup", 3, true, true)

--[[
    技能名：忠粉
    描述：锁定技，游戏开始时，你须选择一名其他角色，令其成为你的“推”，你存活时你的“推”手牌上限+2。
]]
Luazhongfen = sgs.CreateTriggerSkill {
    name = "Luazhongfen",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
            "@zhongfen_invoke")
        room:setPlayerMark(target, "oshi" .. player:objectName(), 1)
        room:addPlayerMark(target, "@Oshi")
    end,
}
LuazhongfenMax = sgs.CreateMaxCardsSkill {
    name = "#LuazhongfenMax",
    extra_func = function(self, target)
        local n = 0
        for _, p in sgs.qlist(target:getAliveSiblings()) do
            if target:getMark("oshi" .. p:objectName()) ~= 0 then
                n = n + 2
            end
        end
        return n
    end,
}
TanOshi:addSkill(Luazhongfen)
if not sgs.Sanguosha:getSkill("#LuazhongfenMax") then
    SKMC.SkillList:append(LuazhongfenMax)
end

--[[
    技能名：死忠
    描述：限定技，当你的“推”进入濒死时，你可以减1点体力上限令其将体力值回复至1点，若其以此法回复的体力值为1，其摸一张牌。
]]
Luasizhong = sgs.CreateTriggerSkill {
    name = "Luasizhong",
    frequency = sgs.Skill_Limited,
    limit_mark = "@sizhong",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() and player:getMark("@Oshi") ~= 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:getMark("oshi" .. p:objectName()) ~= 0 and p:getMark("@sizhong") ~= 0
                    and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("invoke:" .. player:objectName())) then
                    p:loseMark("@sizhong")
                    room:loseMaxHp(p)
                    local n = 1 - player:getHp()
                    room:recover(player, sgs.RecoverStruct(p, nil, n))
                    if n == 1 then
                        room:drawCards(player, 1, self:objectName())
                    end
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
TanOshi:addSkill(Luasizhong)

--[[
    技能名：握手
    描述：出牌阶段限一次，若你的“推”存活，你可以弃置两张手牌，然后你回复1点体力其摸一张牌。
]]
LuawoshouCard = sgs.CreateSkillCard {
    name = "LuawoshouCard",
    skill_name = "Luawoshou",
    will_throw = true,
    filter = function(self, selected, to_select)
        return #selected == 0 and to_select:getMark("oshi" .. sgs.Self:objectName()) ~= 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:isWounded() then
            room:recover(effect.from, sgs.RecoverStruct(effect.from, self, 1))
        end
        room:drawCards(effect.to, 1, "Luawoshou")
    end,
}
Luawoshou = sgs.CreateViewAsSkill {
    name = "Luawoshou",
    n = 2,
    filter_pattern = ".|.|.|hand",
    view_filter = function(self, selected, to_select)
        return (#selected < 2) and (not sgs.Self:isJilei(to_select))
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            cd = LuawoshouCard:clone()
            cd:addSubcard(cards[1])
            cd:addSubcard(cards[2])
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:getMark("oshi" .. player:objectName()) ~= 0 then
                return player:getHandcardNum() >= 2 and not player:hasUsed("#LuawoshouCard")
            end
        end
        return false
    end,
}
TanOshi:addSkill(Luawoshou)

--[[
    技能名：应援
    描述：出牌阶段，当你使用的牌结算完成进入弃牌堆时，你可以将此牌交给你的“推”（相同牌名的牌每回合限一次）。
]]
sakamichi_ying_yuan = sgs.CreateTriggerSkill {
    name = "sakamichi_ying_yuan",
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local is_nullification = false
            for _, id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id) and sgs.Sanguosha:getCard(id):isKindOf("Nullification") then
                    is_nullification = true
                end
            end
            local move_card_can_yingyuan = false
            for _, id in sgs.qlist(move.card_ids) do
                if not player:hasFlag(self:objectName() .. SKMC.true_name(sgs.Sanguosha:getCard(id)) .. "-Clear") then
                    move_card_can_yingyuan = true
                end
            end
            if move.from
                and ((move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile)
                    or (is_nullification and move.to_place == sgs.Player_PlaceTable))
                and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                == sgs.CardMoveReason_S_REASON_USE and move.from:objectName() == player:objectName()
                and player:getPhase() ~= sgs.Player_NotActive and move_card_can_yingyuan then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                for _, id in sgs.qlist(move.card_ids) do
                    dummy:addSubcard(id)
                    room:setPlayerFlag(player,
                        self:objectName() .. SKMC.true_name(sgs.Sanguosha:getCard(id)) .. "-Clear")
                end
                if dummy:subcardsLength() > 0 then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:getMark("oshi" .. player:objectName()) ~= 0 then
                            targets:append(p)
                        end
                    end
                    local target
                    if not targets:isEmpty() then
                        target = room:askForPlayerChosen(player, targets, self:objectName(),
                            "sakamichi_ying_yuan_invoke", true, true)
                    end
                    if target then
                        room:obtainCard(target, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                            player:objectName(), target:objectName(), self:objectName(), ""), false)
                    end
                end
            end
        end
    end,
}
TanOshi:addSkill(sakamichi_ying_yuan)

sgs.LoadTranslationTable {
    ["TanOshi"] = "单推",
    ["&TanOshi"] = "单推",
    ["#TanOshi"] = "一心一意",
    ["designer:TanOshi"] = "Cassimolar",
    ["cv:TanOshi"] = "单推",
    ["illustrator:TanOshi"] = "Cassimolar",
    ["Luazhongfen"] = "忠粉",
    [":Luazhongfen"] = "锁定技，游戏开始时，你须选择一名其他角色，令其成为你的“推”，你存活时你的“推”手牌上限+2。",
    ["@zhongfen_invoke"] = "请选择一名其他角色成为你的“推”",
    ["Luasizhong"] = "死忠",
    [":Luasizhong"] = "限定技，当你的“推”进入濒死时，你可以减1点体力上限令其将体力值回复至1点，若其以此法回复的体力值为1，其摸一张牌。",
    ["@sizhong"] = "死忠",
    ["Luasizhong:invoke"] = "是否发动【死忠】令你的“推”%src体力值回复至1",
    ["Luawoshou"] = "握手",
    [":Luawoshou"] = "出牌阶段限一次，若你的“推”存活，你可以弃置两张手牌，然后你回复1点体力其摸一张牌。",
    ["sakamichi_ying_yuan"] = "应援",
    [":sakamichi_ying_yuan"] = "出牌阶段，当你使用的牌结算完成进入弃牌堆时，你可以将此牌交给你的“推”（相同牌名的牌每回合限一次）。",
    ["sakamichi_ying_yuan_invoke"] = "你可以将此牌交给一名你的“推”",
}