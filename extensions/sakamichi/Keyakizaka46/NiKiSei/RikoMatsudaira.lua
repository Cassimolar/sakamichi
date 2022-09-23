require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikoMatsudaira_Keyakizaka = sgs.General(Sakamichi, "RikoMatsudaira_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.NiKiSei.RikoMatsudaira_Keyakizaka = true
SKMC.SeiMeiHanDan.RikoMatsudaira_Keyakizaka = {
    name = {8, 5, 15, 3},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {18, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_mi_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_zi",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        local result = SKMC.run_judge(room, player, self:objectName(), ".|red")
        if result.isGood then
            n = n + 1
            data:setValue(n)
        else
            if player:canDiscard(player, "he") then
                room:askForDiscard(player, self:objectName(), 1, 1, false, true)
            end
        end
        return false
    end,
}
RikoMatsudaira_Keyakizaka:addSkill(sakamichi_mi_zi)

sakamichi_mei_tou_naoCard = sgs.CreateSkillCard {
    name = "sakamichi_mei_tou_naoCard",
    skill_name = "sakamichi_mei_tou_nao",
    will_throw = false,
    handling_method = sgs.Card_MethodPindian,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canPindian(to_select)
                   and not sgs.Self:hasFlag("mei_tou_nao_to" .. to_select:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:pindian(effect.to, self:getSkillName(), self) then
            room:setPlayerFlag(effect.from, "mei_tou_nao_sussces" .. effect.to:objectName())
        else
            room:setPlayerFlag(effect.from, "mei_tou_nao_fail" .. effect.to:objectName())
        end
        if sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() ~= 13 then
            room:setPlayerFlag(effect.from, "mei_tou_nao_used")
        end
        room:setPlayerFlag(effect.from, "mei_tou_nao_to" .. effect.to:objectName())
    end,
}
sakamichi_mei_tou_nao_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_mei_tou_nao",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local skillcard = sakamichi_mei_tou_naoCard:clone()
        skillcard:addSubcard(card)
        return skillcard
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("mei_tou_nao_used") and not player:isKongcheng()
    end,
}
sakamichi_mei_tou_nao = sgs.CreateTriggerSkill {
    name = "sakamichi_mei_tou_nao",
    view_as_skill = sakamichi_mei_tou_nao_view_as,
    events = {sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isNDTrick() or use.card:isKindOf("BasicCard") then
            if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
                local extra_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:hasFlag("mei_tou_nao_sussces" .. p:objectName())
                        and not (use.to:contains(p) or room:isProhibited(player, p, use.card)) then
                        if use.card:targetFixed() then
                            if not use.card:isKindOf("Peach") or p:isWounded() then
                                extra_targets:append(p)
                            end
                        else
                            if use.card:targetFilter(sgs.PlayerList(), p, player) then
                                extra_targets:append(p)
                            end
                        end
                    end
                end
                if not extra_targets:isEmpty() then
                    if use.card:isKindOf("Collateral") then
                        for _, p in sgs.qlist(extra_targets) do
                            local pl_list = sgs.SPlayerList()
                            for _, pl in sgs.qlist(room:getOtherPlayers(p)) do
                                local p_list = sgs.PlayerList()
                                p_list:append(p)
                                if use.card:targetFilter(p_list, pl, player) then
                                    pl_list:append(pl)
                                end
                            end
                            if pl_list:isEmpty() then
                                extra_targets:removeOne(p)
                            else
                                local victim = room:askForPlayerChosen(player, pl_list, self:objectName(),
                                    "@mei_tou_nao_collateral:" .. p:objectName() .. "::" .. use.card:objectName())
                                local _data = sgs.QVariant()
                                _data:setValue(victim)
                                p:setTag("collateralVictim", _data)
                            end
                        end
                    end
                    for _, p in sgs.qlist(extra_targets) do
                        use.to:append(p)
                    end
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
            end
        end
    end,
}
Luamei_tou_naoProtect = sgs.CreateProhibitSkill {
    name = "#Luamei_tou_naoProtect",
    is_prohibited = function(self, from, to, card)
        return from:hasFlag("mei_tou_nao_fail" .. to:objectName())
    end,
}
RikoMatsudaira_Keyakizaka:addSkill(sakamichi_mei_tou_nao)
if not sgs.Sanguosha:getSkill("#Luamei_tou_naoProtect") then
    SKMC.SkillList:append(Luamei_tou_naoProtect)
end

sgs.LoadTranslationTable {
    ["RikoMatsudaira_Keyakizaka"] = "松平 璃子",
    ["&RikoMatsudaira_Keyakizaka"] = "松平 璃子",
    ["#RikoMatsudaira_Keyakizaka"] = "没头脑",
    ["~RikoMatsudaira_Keyakizaka"] = "無理～サファリパーク♪",
    ["designer:RikoMatsudaira_Keyakizaka"] = "Cassimolar",
    ["cv:RikoMatsudaira_Keyakizaka"] = "松平 璃子",
    ["illustrator:RikoMatsudaira_Keyakizaka"] = "Cassimolar",
    ["sakamichi_mi_zi"] = "迷子",
    [":sakamichi_mi_zi"] = "锁定技，摸牌阶段，你判定，若结果为：红色，你多摸一张牌；不为红色，你须弃置一张牌。",
    ["sakamichi_mei_tou_nao"] = "没头脑",
    [":sakamichi_mei_tou_nao"] = "出牌阶段限一次，你可以拼点：若你赢，本回合内，你使用基本牌和通常锦囊牌时，若其为此牌合法目标且不为此牌的目标，则其成为此牌的额外目标；若你没赢，本回合内你使用牌其不是合法目标。若你以此法拼点的牌的点数为K，则此技能对本回合未成为此技能目标的角色视为未曾发动。",
    ["@mei_tou_nao_collateral"] = "请为此【%arg】的目标%src选择一个使用【杀】的目标",
}
