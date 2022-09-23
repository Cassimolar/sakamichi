require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HaruyoYamaguchi = sgs.General(Sakamichi, "HaruyoYamaguchi", "Hinatazaka46", 3, false, true)
table.insert(SKMC.SanKiSei, "HaruyoYamaguchi")

--[[
    技能名：得意
    描述：游戏开始时，你获得两枚“野球”标记；当你使用的【杀】被抵消时/使用【闪】抵消【杀】时，你获得一枚“野球”标记，你至多可以拥有三枚“野球”；你的攻击距离+X（X为你的“野球”数量）。
]]
Luadeyi = sgs.CreateTriggerSkill {
    name = "Luadeyi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.GameStart, sgs.SlashMissed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self) then
                if player:getMark("@yeqiu") < 3 then
                    player:gainMark("@yeqiu", math.min(2, 3 - player:getMark("@yeqiu")))
                end
            end
        else
            local effect = data:toSlashEffect()
            if effect.from and effect.from:hasSkill(self) then
                if effect.from:getMark("@yeqiu") < 3 then
                    room:addPlayerMark(effect.from, "@yeqiu", 1)
                end
            elseif effect.to and effect.to:hasSkill(self) then
                if effect.to:getMark("@yeqiu") < 3 then
                    room:addPlayerMark(effect.to, "@yeqiu", 1)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
LuadeyiAttackRange = sgs.CreateAttackRangeSkill {
    name = "#LuadeyiAttackRange",
    extra_func = function(self, player, include_weapon)
        if player:hasSkill("Luadeyi") then
            return player:getMark("@yeqiu")
        else
            return 0
        end
    end,
}
-- HaruyoYamaguchi:addSkill(Luadeyi)
-- if not sgs.Sanguosha:getSkill("#LuadeyiAttackRange") then SKMC.SkillList:append(LuadeyiAttackRange) end

--[[
    技能名：接球
    描述：当你受到【杀】的伤害后／使用的【杀】被闪避时，若此【杀】有对应的实体牌，你可以将所有实体牌置于武将牌上称为“棒球”，“棒球”可以视为手牌使用或打出；你可以将“棒球”视为【闪】使用或打出。
]]
LuajieqiuVS = sgs.CreateOneCardViewAsSkill {
    name = "Luajieqiu",
    response_pattern = "jink",
    filter_pattern = ".|.|.|&bangqiu",
    expand_pile = "&bangqiu",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
}
Luajieqiu = sgs.CreateTriggerSkill {
    name = "Luajieqiu",
    view_as_skill = LuajieqiuVS,
    events = {sgs.Damaged, sgs.SlashMissed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                local ids = sgs.IntList()
                if damage.card:isVirtualCard() then
                    ids = damage.card:getSubcards()
                else
                    ids:append(damage.card:getEffectiveId())
                end
                if not ids:isEmpty() then
                    local all_place_table = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                            all_place_table = false
                            break
                        end
                    end
                    if all_place_table and room:askForSkillInvoke(player, self:objectName(), data) then
                        player:addToPile("&bangqiu", ids)
                    end
                end
            end
        elseif event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            local ids = sgs.IntList()
            if effect.slash:isVirtualCard() then
                ids = effect.slash:getSubcards()
            else
                ids:append(effect.slash:getEffectiveId())
            end
            if not ids:isEmpty() then
                local all_place_table = true
                for _, id in sgs.qlist(ids) do
                    if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                        all_place_table = false
                        break
                    end
                end
                if all_place_table and room:askForSkillInvoke(player, self:objectName(), data) then
                    player:addToPile("&bangqiu", ids)
                end
            end
        end
        return false
    end,
}
HaruyoYamaguchi:addSkill(Luajieqiu)

--[[
    技能名：投球
    描述：出牌阶段，你可以弃置一张“棒球”令一名其他角色本回合内到你的距离锁定为１；当一名角色使用【杀】时，你可以弃置一张点数不小于此【杀】的“棒球”令此【杀】不可以响应，若此“棒球”的颜色与此【杀】相同，此【杀】无视防具，若此“棒球”的花色与此【杀】相同，此【杀】不计入使用次数限制。
]]
-- ! 出牌阶段，你可以弃置一张“棒球”令一名其他角色本回合内到你的距离锁定为１；当一名角色使用【杀】时，你可以弃置一张点数不小于此【杀】的“棒球”令此【杀】不可以响应，若此“棒球”的颜色与此【杀】相同，此【杀】无视防具，若此“棒球”的花色与此【杀】相同，此【杀】不计入使用次数限制。
LuatouqiuCard = sgs.CreateSkillCard {
    name = "LuatouqiuCard",
    skill_name = "Luatouqiu",
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:setPlayerFlag(effect.from, "touqiu" .. effect.to:objectName())
        room:setFixedDistance(effect.from, effect.to, 1)
    end,
}
LuatouqiuVS = sgs.CreateOneCardViewAsSkill {
    name = "Luatouqiu",
    filter_pattern = ".|.|.|&bangqiu",
    expand_pile = "&bangqiu",
    view_as = function(self, card)
        local cd = LuatouqiuCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return player:getPile("&bangqiu"):length() ~= 0
    end,
}
Luatouqiu = sgs.CreateTriggerSkill {
    name = "Luatouqiu",
    view_as_skill = LuatouqiuVS,
    events = {sgs.EventPhaseEnd, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:hasFlag("touqiu" .. p:objectName()) then
                    room:removeFixedDistance(player, p, 1)
                    room:setPlayerFlag(player, "-touqiu" .. p:objectName())
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getPile("&bangqiu"):length() ~= 0 then
                        local card_ids = p:getPile("&bangqiu")
                        for _, id in sgs.qlist(card_ids) do
                            if sgs.Sanguosha:getCard(id):getNumber() < use.card:getNumber() then
                                card_ids:removeOne(id)
                            end
                        end
                        if card_ids ~= 0 and room:askForSkillInvoke(p, self:objectName(), data) then
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "",
                                p:objectName(), self:objectName(), "")
                            if not card_ids:isEmpty() then
                                room:fillAG(card_ids)
                                local card_id = room:askForAG(p, card_ids, true, self:objectName())
                                if card_id ~= -1 then
                                    card_ids:removeOne(card_id)
                                    room:setCardFlag(use.card, "no_respond_" .. player:objectName() .. "_ALL_TARGETS")
                                    local no_respond_list = use.no_respond_list
                                    for _, pl in sgs.qlist(room:getAllPlayers()) do
                                        table.insert(no_respond_list, pl:objectName())
                                    end
                                    use.no_respond_list = no_respond_list
                                    local card = sgs.Sanguosha:getCard(card_id)
                                    if use.card:getSuit() ~= sgs.Card_NoSuit then
                                        if use.card:isRed() == card:isRed() then
                                            room:setCardFlag(use.card, "SlashIgnoreArmor")
                                        end
                                        if use.card:getSuit() == card:getSuit() then
                                            if use.m_addHistory then
                                                room:addPlayerHistory(player, use.card:getClassName(), -1)
                                            end
                                        end
                                    end
                                    room:throwCard(card, reason, nil)
                                    data:setValue(use)
                                end
                                room:clearAG()
                            end
                        end
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
HaruyoYamaguchi:addSkill(Luatouqiu)

-- ! 出牌阶段限一次，你可以弃置三枚“野球”来选择其中一项：1.视为使用一张无法闪避的火【杀】；2.视为使用三张无视防具的【杀】。
--[[
LuatouqiuCard = sgs.CreateSkillCard{
    name = "LuatouqiuCard",
    skill_name = "Luatouqiu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        source:loseMark("@yeqiu", 3)
        if room:askForChoice(source, "Luatouqiu", "touqiu1+touqiu2") == "touqiu1" then
            local targets_list = sgs.SPlayerList()
            local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, -1)
            slash:setSkillName("Luatouqiu")
            room:setCardFlag(slash, "touqiu1")
            for _, target in sgs.qlist(room:getOtherPlayers(source)) do
                if source:canSlash(target, slash, false) then
                    targets_list:append(target)
                end
            end
            if not targets_list:isEmpty() then
                local target = room:askForPlayerChosen(source, targets_list, "Luatouqiu", "@touqiu1", true, true)
                if target then
                    room:useCard(sgs.CardUseStruct(slash, source, target))
                end
            end
        else
            for i = 1, 3, 1 do
                local targets_list = sgs.SPlayerList()
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                slash:setSkillName("Luatouqiu")
                room:setCardFlag(slash, "SlashIgnoreArmor")
                for _, target in sgs.qlist(room:getOtherPlayers(source)) do
                    if source:canSlash(target, slash, false) then
                        targets_list:append(target)
                    end
                end
                local target = room:askForPlayerChosen(source, targets_list, "Luatouqiu", "@touqiu2", true, true)
                if target then
                    room:useCard(sgs.CardUseStruct(slash, source, target))
                else
                    break
                end
            end
        end
    end
}
LuatouqiuVS = sgs.CreateZeroCardViewAsSkill{
    name = "Luatouqiu",
    view_as = function(self)
        return LuatouqiuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@yeqiu") == 3 and not player:hasUsed("#LuatouqiuCard")
    end
}
Luatouqiu = sgs.CreateTriggerSkill{
    name = "Luatouqiu",
    view_as_skill = LuatouqiuVS,
    events = {sgs.SlashProceed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.slash:hasFlag("touqiu1") then
                room:slashResult(effect, nil)
                return true
            end
        end
    end
}
]]

sgs.LoadTranslationTable {
    ["HaruyoYamaguchi"] = "山口 陽世",
    ["&HaruyoYamaguchi"] = "山口 陽世",
    ["#HaruyoYamaguchi"] = "投球少女",
    ["designer:HaruyoYamaguchi"] = "Cassimolar",
    ["cv:HaruyoYamaguchi"] = "山口 陽世",
    ["illustrator:HaruyoYamaguchi"] = "Cassimolar",
    --	["Luadeyi"] = "得意",
    --	[":Luadeyi"] = "游戏开始时，你获得两枚“野球”标记；当你使用的【杀】被抵消时/使用【闪】抵消【杀】时，你获得一枚“野球”标记，你至多可以拥有三枚“野球”；你的攻击距离+X（X为你的“野球”数量）。",
    --	["@yeqiu"] = "野球",
    ["Luajieqiu"] = "接球",
    [":Luajieqiu"] = "当你受到【杀】的伤害后／使用的【杀】被闪避时，若此【杀】有对应的实体牌，你可以将所有实体牌置于武将牌上称为“棒球”，“棒球”可以视为手牌使用或打出；你可以将“棒球”视为【闪】使用或打出。",
    ["&bangqiu"] = "棒球",
    ["Luatouqiu"] = "投球",
    --	[":Luatouqiu"] = "出牌阶段限一次，你可以弃置三枚“野球”来选择其中一项：1.视为使用一张无法闪避的火【杀】；2.视为使用三张无视防具的【杀】。",
    --	["Luatouqiu:touqiu1"] = "视为使用一张无法闪避的火【杀】",
    --	["Luatouqiu:touqiu2"] = "视为使用三张无视防具的【杀】",
    --	["@touqiu1"] = "你可以选择一名其他角色视为对其使用一张无法闪避的火【杀】",
    --	["@touqiu2"] = "你可以选择一名其他角色视为对其使用一张无视防具的【杀】",
    [":Luatouqiu"] = "出牌阶段，你可以弃置一张“棒球”令一名其他角色本回合内到你的距离锁定为１；当一名角色使用【杀】时，你可以弃置一张点数不小于此【杀】的“棒球”令此【杀】不可以响应，若此“棒球”的颜色与此【杀】相同，此【杀】无视防具，若此“棒球”的花色与此【杀】相同，此【杀】不计入使用次数限制。",
}
