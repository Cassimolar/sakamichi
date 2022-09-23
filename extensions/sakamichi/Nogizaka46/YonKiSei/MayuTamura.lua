require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MayuTamura = sgs.General(Sakamichi, "MayuTamura", "Nogizaka46", 3, false)
SKMC.YonKiSei.MayuTamura = true
SKMC.SeiMeiHanDan.MayuTamura = {
    name = {5, 7, 10, 7},
    ten_kaku = {12, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_da_gong = sgs.CreateTriggerSkill {
    name = "sakamichi_da_gong",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging, sgs.Damage, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
            if not player:hasFlag("da_gong_damage") then
                room:addPlayerMark(player, "&" .. self:objectName(), SKMC.number_correction(player, 1))
            end
        elseif event == sgs.Damage then
            room:setPlayerFlag(player, "da_gong_damage")
            room:setPlayerMark(player, "&" .. self:objectName(), 0)
        elseif event == sgs.DrawNCards then
            data:setValue(data:toInt() + player:getMark("&" .. self:objectName()))
        end
        return false
    end,
}
MayuTamura:addSkill(sakamichi_da_gong)

sakamichi_qiao_shou = sgs.CreateTriggerSkill {
    name = "sakamichi_qiao_shou",
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local list = sgs.IntList()
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isKindOf("Slash") or card:isKindOf("EquipCard") then
                    list:append(card:getId())
                end
            end
            for _, id in sgs.qlist(player:getEquipsId()) do
                list:append(id)
            end
            local target = room:askForYiji(player, list, self:objectName(), false, false, true, 1,
                room:getOtherPlayers(player), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(),
                    self:objectName(), nil), "@qiao_shou_invoke")
            if target then
                local target_List = room:getOtherPlayers(target)
                target_List:removeOne(player)
                local slash_target = room:askForPlayerChosen(player, target_List, self:objectName(),
                    "@qiao_shou_slash:" .. target:objectName(), false, true)
                if not room:askForUseSlashTo(target, slash_target, "@qiao_shou_slash_to:" .. slash_target:objectName()) then
                    if target:getEquips():length() ~= 0 or target:getJudgingArea():length() ~= 0 then
                        local _target = sgs.SPlayerList()
                        _target:append(target)
                        room:moveField(player, self:objectName(), false, "ej", _target)
                    end
                end
            end
        end
        return false
    end,
}
MayuTamura:addSkill(sakamichi_qiao_shou)

sakamichi_zhu_ren_card = sgs.CreateSkillCard {
    name = "sakamichi_zhu_renCard",
    skill_name = "sakamichi_zhu_ren",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:isWounded()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if self:getSubcards():length() ~= 0 then
            if sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit() ~= sgs.Card_Heart then
                room:setPlayerFlag(effect.from, "zhu_ren_used")
            end
        else
            room:loseHp(effect.from, SKMC.number_correction(effect.from, 1))
        end
        room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)), true)
    end,
}
sakamichi_zhu_ren = sgs.CreateViewAsSkill {
    name = "sakamichi_zhu_ren",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        local cd = sakamichi_zhu_ren_card:clone()
        if #cards ~= 0 then
            cd:addSubcard(cards[1])
        end
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("zhu_ren_used")
    end,
}
MayuTamura:addSkill(sakamichi_zhu_ren)

sgs.LoadTranslationTable {
    ["MayuTamura"] = "田村 真佑",
    ["&MayuTamura"] = "田村 真佑",
    ["#MayuTamura"] = "厂妹",
    ["~MayuTamura"] = "私 面白い路線じゃないから",
    ["designer:MayuTamura"] = "Cassimolar",
    ["cv:MayuTamura"] = "田村 真佑",
    ["illustrator:MayuTamura"] = "Cassimolar",
    ["sakamichi_da_gong"] = "打工",
    [":sakamichi_da_gong"] = "锁定技，结束阶段，若本回合内你未造成伤害，你的摸牌阶段额定摸牌数+1，直到你于回合内造成伤害为止。",
    ["sakamichi_qiao_shou"] = "巧手",
    [":sakamichi_qiao_shou"] = "准备阶段，你可以交给一名其他角色一张【杀】或装备牌，令其对另一名你选择的其他角色使用一张【杀】，若其未如此做，你可以移动其判定区/装备区的一张牌。",
    ["@qiao_shou_invoke"] = "你可以交给一名其他角色一张【杀】或装备牌",
    ["@qiao_shou_slash"] = "请选择令%src使用【杀】的目标",
    ["@qiao_shou_slash_to"] = "请对%src使用一张【杀】",
    ["sakamichi_zhu_ren"] = "主任",
    [":sakamichi_zhu_ren"] = "出牌阶段限一次，你可以弃置一张手牌或失去1点体力令一名其他角色回复1点体力，若以此法弃置的牌为红桃或因此失去体力，此技能视为未曾发动。",
}
