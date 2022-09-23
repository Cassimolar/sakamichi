require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MomokoOozono = sgs.General(Sakamichi, "MomokoOozono$", "Nogizaka46", 3, false)
SKMC.SanKiSei.MomokoOozono = true
SKMC.SeiMeiHanDan.MomokoOozono = {
    name = {3, 13, 10, 3},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {23, "ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {6, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_shen_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_shen_jing$",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if player:getKingdom() == "Nogizaka46" and not use.card:isKindOf("SkillCard") and use.card:isVirtualCard()
            and use.card:subcardsLength() == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self) and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                    "invoke:" .. player:objectName() .. "::" .. self:objectName())) then
                    room:drawCards(player, 2, self:objectName())
                    if not player:isKongcheng() then
                        local card = room:askForCard(player, ".|.|.|hand!", "@shen_jing_give:" .. p:objectName(),
                            sgs.QVariant(), sgs.Card_MethodNone)
                        if card then
                            room:obtainCard(p, card, false)
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
MomokoOozono:addSkill(sakamichi_shen_jing)

sakamichi_ai_ku = sgs.CreateTriggerSkill {
    name = "sakamichi_ai_ku",
    events = {sgs.Damaged, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.Damaged then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local result = SKMC.run_judge(room, player, self:objectName(), ".|heart", false)
                if result.isGood then
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    slash:setSkillName(self:objectName())
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if player:canSlash(p, slash, false) then
                            targets:append(p)
                        end
                    end
                    if targets:length() ~= 0 then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@ai_ku_slash", true)
                        if target then
                            if damage.from and damage.from:isAlive() then
                                room:setPlayerMark(damage.from, "ai_ku_slash_" .. slash:getId(), 1)
                            end
                            room:useCard(sgs.CardUseStruct(slash, player, target), false)
                            if damage.from then
                                room:setPlayerMark(damage.from, "ai_ku_slash_" .. slash:getId(), 0)
                            end
                        end
                    end
                end
            end
        else
            if damage.card and damage.card:getSkillName() == self:objectName() then
                if room:askForSkillInvoke(player, self:objectName(),
                    sgs.QVariant("damage:" .. damage.to:objectName() .. "::" .. damage.card:objectName() .. ":"
                                     .. SKMC.number_correction(player, 1))) then
                    room:recover(player, sgs.RecoverStruct(player, damage.card, SKMC.number_correction(player, 1)))
                    return true
                end
            end
        end
        return false
    end,
}
MomokoOozono:addSkill(sakamichi_ai_ku)

sakamichi_tu_she_card = sgs.CreateSkillCard {
    name = "sakamichi_tu_sheCard",
    skill_name = "sakamichi_tu_she",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if room:askForChoice(effect.to, self:getSkillName(),
            "damage=" .. effect.from:objectName() .. "=" .. SKMC.number_correction(effect.from, 1) .. "+gain="
                .. effect.from:objectName()) == "damage=" .. effect.from:objectName() .. "="
            .. SKMC.number_correction(effect.from, 1) then
            room:damage(sgs.DamageStruct(self:objectName(), effect.to, effect.from,
                SKMC.number_correction(effect.from, 1)))
        else
            if not effect.to:isAllNude() then
                local card = room:askForCardChosen(effect.from, effect.to, "hej", self:getSkillName(), false,
                    sgs.Card_MethodNone)
                room:obtainCard(effect.from, card, room:getCardPlace(card) ~= sgs.Player_PlaceHand)
            end
        end
    end,
}
sakamichi_tu_she = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_tu_she",
    view_as = function(self)
        local cd = sakamichi_tu_she_card:clone()
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_tu_sheCard")
    end,
}
MomokoOozono:addSkill(sakamichi_tu_she)

sgs.LoadTranslationTable {
    ["MomokoOozono"] = "大園 桃子",
    ["&MomokoOozono"] = "大園 桃子",
    ["#MomokoOozono"] = "不再哭泣",
    ["~MomokoOozono"] = "話の分かんない人だ",
    ["designer:MomokoOozono"] = "Cassimolar",
    ["cv:MomokoOozono"] = "大園 桃子",
    ["illustrator:MomokoOozono"] = "Cassimolar",
    ["sakamichi_shen_jing"] = "蜃景",
    [":sakamichi_shen_jing"] = "主公技，乃木坂46势力角色使用卡牌结算完成时，若此牌无对应实体牌，你可以令其摸两张牌并交给你一张手牌。",
    ["sakamichi_shen_jing:invoke"] = "是否发动【%arg】令%src 摸两张牌并交给你一张手牌",
    ["@shen_jing_give"] = "请选择一张手牌交给%src",
    ["sakamichi_ai_ku"] = "爱哭",
    [":sakamichi_ai_ku"] = "当你受到伤害后，你可以判定，若结果不为红桃，你可以选择一名其他角色视为对其使用一张【杀】，若此【杀】对伤害来源造成伤害，你可以防止之并回复1点体力。",
    ["@ai_ku_slash"] = "你可以选择一名其他角色视为对其使用一张【杀】",
    ["sakamichi_ai_ku:damage"] = "是否防止此【%arg】对%src 造成的伤害并回复%arg2点体力",
    ["sakamichi_tu_she"] = "吐舌",
    [":sakamichi_tu_she"] = "出牌阶段限一次，你可以选择一名其他角色，令其选择对你造成1点伤害或令你获得其区域内的一张牌。",
    ["sakamichi_tu_she:damage"] = "对%src造成%arg点伤害",
    ["sakamichi_tu_she:gain"] = "令%src获得你区域内的一张牌",
}
