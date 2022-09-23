require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaMatsuda_Keyakizaka = sgs.General(Sakamichi, "RinaMatsuda_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.NiKiSei.RinaMatsuda_Keyakizaka = true
SKMC.SeiMeiHanDan.RinaMatsuda_Keyakizaka = {
    name = {8, 5, 7, 8},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {28, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_gui_yuanCard = sgs.CreateSkillCard {
    name = "sakamichi_gui_yuanCard",
    skill_name = "sakamichi_gui_yuan",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        effect.from:obtainCard(effect.to:getRandomHandCard())
        room:setPlayerFlag(effect.to, "gui_yuan_to" .. effect.from:objectName())
    end,
}
sakamichi_gui_yuan_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_gui_yuan",
    view_as = function(self)
        return sakamichi_gui_yuanCard:clone()
    end,
    enabled_at_play = function(self, player)
        local can = false
        for _, p in sgs.qlist(player:getSiblings()) do
            if not p:isKongcheng() then
                can = true
                break
            end
        end
        return not player:hasUsed("#sakamichi_gui_yuanCard") and can
    end,
}
sakamichi_gui_yuan = sgs.CreateTriggerSkill {
    name = "sakamichi_gui_yuan",
    view_as_skill = sakamichi_gui_yuan_view_as,
    events = {sgs.EventPhaseStart, sgs.DrawNCards, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Draw then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:hasFlag("gui_yuan_to" .. p:objectName()) then
                    local card = room:askForCard(p, ".|.|.|hand", "@gui_yuan_give_1:" .. player:objectName(), data,
                        sgs.Card_MethodNone)
                    if card then
                        player:obtainCard(card)
                    else
                        room:setPlayerFlag(p, "gui_yuan_fail" .. player:objectName())
                    end
                end
            end
        elseif event == sgs.DrawNCards then
            local n = data:toInt()
            if n > 0 then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:hasFlag("gui_yuan_fail" .. p:objectName()) then
                        room:drawCards(p, 1, self:objectName())
                        if n > 0 then
                            n = n - 1
                        else
                            break
                        end
                    end
                end
                data:setValue(n)
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            if player:getHandcardNum() < player:getMaxCards() then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:hasFlag("gui_yuan_give" .. p:objectName()) then
                        if player:getHandcardNum() < player:getMaxCards() then
                            local card = room:askForCard(p, ".|.|.|hand", "@gui_yuan_give_2:" .. player:objectName(),
                                data, sgs.Card_MethodNone)
                            if card then
                                player:obtainCard(card)
                            else
                                room:drawCards(player, math.min(player:getMaxCards() - player:getHandcardNum(),
                                    SKMC.number_correction(p, 5) - player:getHandcardNum()), self:objectName())
                            end
                        else
                            break
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
sakamichi_gui_yuan_attach = sgs.CreateTriggerSkill {
    name = "#sakamichi_gui_yuan_attach",
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == "sakamichi_gui_yuan") then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:hasSkill("sakamichi_gui_yuan_give") then
                    room:attachSkillToPlayer(p, "sakamichi_gui_yuan_give")
                end
            end
        elseif event == sgs.EventLoseSkill and data:toString() == "sakamichi_gui_yuan" then
            local no_one_has_this_skill = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill("sakamichi_gui_yuan") then
                    no_one_has_this_skill = false
                    break
                end
            end
            if no_one_has_this_skill then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:detachSkillFromPlayer(p, "sakamichi_gui_yuan_give", true)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill("sakamichi_gui_yuan")
    end,
}
sakamichi_gui_yuan_give_card = sgs.CreateSkillCard {
    name = "sakamichi_gui_yuan_give_card",
    skill_name = "sakamichi_gui_yuan_give",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:hasSkill("sakamichi_gui_yuan")
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        effect.to:obtainCard(card)
        room:setPlayerFlag(effect.from, "gui_yuan_give" .. effect.to:objectName())
    end,
}
sakamichi_gui_yuan_give = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_gui_yuan_give&",
    attached_lord_skill = true,
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local cd = sakamichi_gui_yuan_give_card:clone()
        cd:addSubcard(card:getId())
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_gui_yuan_give_card") and not player:isKongcheng()
    end,
}
RinaMatsuda_Keyakizaka:addSkill(sakamichi_gui_yuan)
RinaMatsuda_Keyakizaka:addSkill(sakamichi_gui_yuan_attach)
if not sgs.Sanguosha:getSkill("sakamichi_gui_yuan_give") then
    SKMC.SkillList:append(sakamichi_gui_yuan_give)
end

sakamichi_dian_chao = sgs.CreateTriggerSkill {
    name = "sakamichi_dian_chao",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start
            and room:askForSkillInvoke(player, self:objectName(), data) then
            local cards = room:getNCards(player:getHandcardNum(), false)
            room:askForGuanxing(player, cards, sgs.Room_GuanxingUpOnly)
        end
        return false
    end,
}
RinaMatsuda_Keyakizaka:addSkill(sakamichi_dian_chao)

sgs.LoadTranslationTable {
    ["RinaMatsuda_Keyakizaka"] = "松田 里奈",
    ["&RinaMatsuda_Keyakizaka"] = "松田 里奈",
    ["#RinaMatsuda_Keyakizaka"] = "点钞姬",
    ["~RinaMatsuda_Keyakizaka"] = "これはいけないな",
    ["designer:RinaMatsuda_Keyakizaka"] = "Cassimolar",
    ["cv:RinaMatsuda_Keyakizaka"] = "松田 里奈",
    ["illustrator:RinaMatsuda_Keyakizaka"] = "Cassimolar",
    ["sakamichi_gui_yuan"] = "柜员",
    [":sakamichi_gui_yuan"] = "出牌阶段限一次，你可以获得一名其他角色的一张手牌，若如此做，其下个摸牌阶段，你须交给其一张手牌，否则你的下个摸牌阶段你少摸一张牌且其摸一张牌；其他角色出牌阶段限一次，其可以将一张手牌交给你，若如此做，本回合结束阶段，若其手牌数小于手牌上限，你可以交给其一张手牌或令其将手牌补至手牌上限（至多为5张）。",
    ["@gui_yuan_give_1"] = "请交给%src一张手牌，否则你的下个摸牌阶段你少摸一张牌且其摸一张牌",
    ["sakamichi_gui_yuan_give"] = "柜员",
    [":sakamichi_gui_yuan_give"] = "出牌阶段限一次，你可以将一张手牌交给【柜员】的拥有者，若如此做，本回合结束时，若你的手牌数小于手牌上限，其须交给你一张手牌否则令你将手牌补至手牌上限（至多为5张）",
    ["@gui_yuan_give_2"] = "请交给%src一张手牌，否则将令其手牌补至手牌上限（至多5张）",
    ["sakamichi_dian_chao"] = "点钞",
    [":sakamichi_dian_chao"] = "准备阶段，你可以观看牌堆顶的X张牌，并可以将这些牌以任意顺序置于牌堆顶（X为你当前手牌数）。",
}
