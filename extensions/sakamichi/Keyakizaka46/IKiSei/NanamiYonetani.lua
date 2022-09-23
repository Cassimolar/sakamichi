require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NanamiYonetani = sgs.General(Sakamichi, "NanamiYonetani", "Keyakizaka46", 3, false)
SKMC.IKiSei.NanamiYonetani = true
SKMC.SeiMeiHanDan.NanamiYonetani = {
    name = {6, 7, 8, 3, 5},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_zhi_nv = sgs.CreateTriggerSkill {
    name = "sakamichi_zhi_nv",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.HpRecover, sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:objectName() ~= player:objectName() and recover.who:isFemale()
                and player:canDisCard(player, "h") then
                room:askForDiscard(player, self:objectName(), 1, 1, false, false, "@zhi_nv_discard")
            end
        else
            local damage = data:toDamage()
            if damage.to and damage.to:isAlive() and damage.to:isFemale() and damage.to:objectName()
                ~= player:objectName() and player:canDiscard(damage.to, "hej") then
                local id = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false,
                    sgs.Card_MethodDiscard)
                room:throwCard(id, damage.to, player)
            end
        end
        return false
    end,
}
NanamiYonetani:addSkill(sakamichi_zhi_nv)

sakamichi_bo_xue = sgs.CreateTriggerSkill {
    name = "sakamichi_bo_xue",
    events = {sgs.CardUsed, sgs.Damaged, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("TrickCard") and not use.card:isKindOf("DelayedTrick") then
                local extra_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and not use.to:contains(p) and use.card:isAvailable(p) then
                        if use.card:targetFilter(sgs.PlayerList(), p, player)
                            and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                                "@bo_xue_invoke:" .. player:objectName() .. "::" .. use.card:objectName())) then
                            extra_targets:append(p)
                            room:setPlayerMark(p, "bo_xue" .. use.card:getEffectiveId(), 1)
                            room:setCardFlag(use.card, "bo_xue")
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
                                    "@bo_xue_collateral:" .. p:objectName() .. "::" .. use.card:objectName())
                                local _data = sgs.QVariant()
                                _data:setValue(victim)
                                p:setTag("collateralVictim", _data)
                            end
                        end
                    end
                    for _, p in sgs.qlist(extra_targets) do
                        use.to:append(p)
                    end
                end
                room:sortByActionOrder(use.to)
                data:setValue(use)
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if player:hasSkill(self) and damage.card and damage.card:hasFlag("bo_xue")
                and player:getMark("bo_xue" .. damage.card:getEffectiveId()) ~= 0 then
                player:obtainCard(damage.card)
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("bo_xue") then
                room:setCardFlag(use.card, "-bo_xue")
                for _, p in sgs.qlist(use.to) do
                    if p:getMark("bo_xue" .. use.card:getEffectiveId()) ~= 0 then
                        room:setPlayerMark(p, "bo_xue" .. use.card:getEffectiveId(), 0)
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
NanamiYonetani:addSkill(sakamichi_bo_xue)

sakamichi_wu_ju = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_ju",
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and player:hasSkill(self) and use.to:length() > 1 then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
                    "@wu_ju_invoke:" .. use.from:objectName() .. "::" .. use.card:objectName())) then
                    room:drawCards(player, 1, self:objectName())
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanamiYonetani:addSkill(sakamichi_wu_ju)

sgs.LoadTranslationTable {
    ["NanamiYonetani"] = "米谷 奈々未",
    ["&NanamiYonetani"] = "米谷 奈々未",
    ["#NanamiYonetani"] = "米警官",
    ["~NanamiYonetani"] = "色々違う！色々このグループ違う！",
    ["designer:NanamiYonetani"] = "Cassimolar",
    ["cv:NanamiYonetani"] = "米谷 奈々未",
    ["illustrator:NanamiYonetani"] = "Cassimolar",
    ["sakamichi_zhi_nv"] = "直女",
    [":sakamichi_zhi_nv"] = "锁定技，其他女性角色令你回复体力时你须弃置一张手牌；你对其他女性角色造成伤害后须弃置其区域内的一张牌。",
    ["sakamichi_bo_xue"] = "博学",
    [":sakamichi_bo_xue"] = "其他角色使用通常锦囊牌时，若你是此牌的合法目标，且不为此牌的目标，你可以成为此牌的额外目标，此牌对你造成伤害后，你获得此牌。",
    ["sakamichi_bo_xue:@bo_xue_invoke"] = "你可以成为%src使用的%arg的额外目标",
    ["sakamichi_wu_ju"] = "无惧",
    [":sakamichi_wu_ju"] = "当你成为卡牌的非唯一目标时，你可以摸一张牌令此牌无法响应。",
    ["sakamichi_wu_ju:@wu_ju_invoke"] = "你可以摸一张牌令%src使用的%arg无法响应",
}
