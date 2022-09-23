require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MeiHigashimura_HiraganaKeyakizaka = sgs.General(Sakamichi, "MeiHigashimura_HiraganaKeyakizaka", "HiraganaKeyakizaka46",
    3, false)
table.insert(SKMC.IKiSei, "MeiHigashimura_HiraganaKeyakizaka")

--[[
    技能名：捣蛋
    描述：一名角色的判定区的牌开始判定时，其可以展示牌堆顶两张牌，然后其可以选择其中一张作为其的判定牌，若如此做，你获得剩余的展示的牌，若其中有装备牌，你可以使用之。。
]]
Luadaodan = sgs.CreateTriggerSkill {
    name = "Luadaodan",
    events = {sgs.StartJudge},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.reason == "indulgence" or judge.reason == "lightning" or judge.reason == "supply_shortage"
            or judge.reason == "WasabiOnigiri" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local ids = room:getNCards(2)
                    room:fillAG(ids)
                    local id = room:askForAG(player, ids, true, self:objectName())
                    room:clearAG()
                    if id ~= -1 then
                        ids:removeOne(id)
                        judge.card = sgs.Sanguosha:getCard(id)
                        room:moveCardTo(judge.card, nil, judge.who, sgs.Player_PlaceJudge, sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_JUDGE, judge.who:objectName(), self:objectName(), "",
                            judge.reason), true)
                        judge:updateResult()
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        dummy:addSubcards(ids)
                        p:obtainCard(dummy)
                        for _, card_id in sgs.qlist(ids) do
                            if sgs.Sanguosha:getCard(card_id):getTypeId() == sgs.Card_TypeEquip
                                and room:getCardOwner(sgs.Sanguosha:getCard(card_id):getEffectiveId()):objectName()
                                == p:objectName() and not p:isLocked(sgs.Sanguosha:getCard(card_id)) then
                                local will_use = room:askForSkillInvoke(p, "daodan_use", sgs.QVariant(
                                    "use:::" .. sgs.Sanguosha:getCard(card_id):objectName()))
                                if will_use then
                                    room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(card_id), p, p))
                                end
                            end
                        end
                        room:setTag("SkipGameRule", sgs.QVariant(true))
                    else
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        dummy:addSubcards(ids)
                        p:obtainCard(dummy)
                        for _, card_id in sgs.qlist(ids) do
                            if sgs.Sanguosha:getCard(card_id):getTypeId() == sgs.Card_TypeEquip
                                and room:getCardOwner(sgs.Sanguosha:getCard(card_id):getEffectiveId()):objectName()
                                == p:objectName() and not p:isLocked(sgs.Sanguosha:getCard(card_id)) then
                                local will_use = room:askForSkillInvoke(p, "daodan_use", sgs.QVariant(
                                    "use:::" .. sgs.Sanguosha:getCard(card_id):objectName()))
                                if will_use then
                                    room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(card_id), p, p))
                                end
                            end
                        end
                    end
                    if id ~= -1 then
                        break
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
MeiHigashimura_HiraganaKeyakizaka:addSkill(Luadaodan)

--[[
    技能名：舞枪
    描述：出牌阶段限一次，你可以移动场上一张装备牌，若此牌为武器牌，你可以令移动后的拥有者对另一名由你指定的其他角色使用一张【杀】，若其未如此做，你对其造成1点伤害并获得此牌。
]]
LuawuqiangCard = sgs.CreateSkillCard {
    name = "LuawuqiangCard",
    skill_name = "Luawuqiang",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:moveField(source, "Luawuqiang", false, "e")
    end,
}
LuawuqiangVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luawuqiang",
    view_as = function(self)
        return LuawuqiangCard:clone()
    end,
    enabled_at_play = function(self, player)
        if not player:getEquips():isEmpty() then
            return not player:hasUsed("#LuawuqiangCard")
        else
            for _, p in sgs.qlist(player:getAliveSiblings()) do
                if not p:getEquips():isEmpty() then
                    return not player:hasUsed("#LuawuqiangCard")
                end
            end
        end
        return false
    end,
}
Luawuqiang = sgs.CreateTriggerSkill {
    name = "Luawuqiang",
    view_as_skill = LuawuqiangVS,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, evnet, player, data, room)
        local move = data:toMoveOneTime()
        if move.reason.m_skillName and move.reason.m_skillName == self:objectName() then
            for _, id in sgs.qlist(move.card_ids) do
                if sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
                    local targets = sgs.SPlayerList()
                    local to = room:findPlayerByObjectName(move.to:objectName())
                    for _, p in sgs.qlist(room:getOtherPlayers(to)) do
                        if to:inMyAttackRange(p) then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(),
                            "@wuqiang_invoke:" .. to:objectName(), true, false)
                        if target then
                            if not room:askForUseSlashTo(to, target, "@wuqiang_slash:" .. target:objectName() .. ":"
                                .. player:objectName() .. ":" .. sgs.Sanguosha:getCard(id):objectName()) then
                                room:damage(sgs.DamageStruct(self:objectName(), player, to, 1, sgs.DamageStruct_Normal))
                                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,
                                    player:objectName())
                                room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, reason)
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
}

MeiHigashimura_HiraganaKeyakizaka:addSkill(Luawuqiang)

sgs.LoadTranslationTable {
    ["MeiHigashimura_HiraganaKeyakizaka"] = "東村 芽依",
    ["&MeiHigashimura_HiraganaKeyakizaka"] = "東村 芽依",
    ["#MeiHigashimura_HiraganaKeyakizaka"] = "搗蛋健將",
    ["designer:MeiHigashimura_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:MeiHigashimura_HiraganaKeyakizaka"] = "東村 芽依",
    ["illustrator:MeiHigashimura_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luadaodan"] = "捣蛋",
    [":Luadaodan"] = "一名角色的判定区的牌开始判定时，其可以展示牌堆顶两张牌，然后其可以选择其中一张作为其的判定牌，若如此做，你获得剩余的展示的牌，若其中有装备牌，你可以使用之。",
    ["Luawuqiang"] = "舞枪",
    [":Luawuqiang"] = "出牌阶段限一次，你可以移动场上一张装备牌，若此牌为武器牌，你可以令移动后的拥有者对另一名由你指定的其他角色使用一张【杀】，若其未如此做，你对其造成1点伤害并获得此牌。",
    ["@wuqiang_invoke"] = "你可以选择一名角色令 %src 对其使用一张【杀】",
    ["@wuqiang_slash"] = "请对 %src 使用一张【杀】否则 %dest 将获得 %arg 并对你造成1点伤害",
    ["daodan_use:use"] = "是否使用此 %arg",
}
