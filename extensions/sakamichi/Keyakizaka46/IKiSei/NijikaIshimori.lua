require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NijikaIshimori = sgs.General(Sakamichi, "NijikaIshimori", "Keyakizaka46", 3, false)
SKMC.IKiSei.NijikaIshimori = true
SKMC.SeiMeiHanDan.NijikaIshimori = {
    name = {5, 12, 9, 7},
    ten_kaku = {17, "ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

sakamichi_mi_xuanCard = sgs.CreateSkillCard {
    name = "sakamichi_mi_xuanCard",
    skill_name = "sakamichi_mi_xuan",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:gainMaxHp(source, SKMC.number_correction(source, 1))
    end,
}
sakamichi_mi_xuan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_mi_xuan",
    filter_pattern = "Peach",
    view_as = function(self, card)
        local cd = sakamichi_mi_xuanCard:clone()
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_mi_xuanCard") and not player:isWounded()
    end,
}
sakamichi_mi_xuan = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_xuan",
    view_as_skill = sakamichi_mi_xuan_view_as,
    events = {sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:hasSkill(self) then
            if player:getGeneral():getKingdom() ~= player:getKingdom()
                or (player:getGeneral2() and player:getGeneral2():getKingdom() ~= player:getKingdom()) then
                room:loseMaxHp(damage.to, SKMC.number_correction(damage.to, 1))
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NijikaIshimori:addSkill(sakamichi_mi_xuan)

sakamichi_chi_dun = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_dun",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        if math.abs(player:getHandcardNum() - player:getHp()) > n then
            n = n - 1
            data:setValue(n)
        end
        return false
    end,
}
NijikaIshimori:addSkill(sakamichi_chi_dun)

sakamichi_niu_langCard = sgs.CreateSkillCard {
    name = "sakamichi_niu_langCard",
    skill_name = "sakamichi_niu_lang",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getHp() < sgs.Self:getHp()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@niu_lang")
        room:setPlayerMark(effect.from, "niu_lang_to_" .. effect.to:objectName(), 1)
        room:setPlayerMark(effect.to, "niu_lang_from_" .. effect.from:objectName(), 1)
    end,
}
sakamichi_niu_lang_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_niu_lang",
    view_as = function(self)
        return sakamichi_niu_langCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:getMark("@niu_lang") ~= 0 then
            for _, p in sgs.qlist(player:getSiblings()) do
                if p:getHp() < player:getHp() then
                    return true
                end
            end
        end
        return false
    end,
}
sakamichi_niu_lang = sgs.CreateTriggerSkill {
    name = "sakamichi_niu_lang",
    view_as_skill = sakamichi_niu_lang_view_as,
    frequency = sgs.Skill_Limited,
    limit_mark = "@niu_lang",
    events = {sgs.EventPhaseEnd, sgs.Damage, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "niu_lang_to_") and player:getMark(mark) ~= 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if string.find(mark, p:objectName()) then
                            local card = room:askForCard(player, ".", "@niu_lang_give:" .. p:objectName(), data,
                                sgs.Card_MethodNone, p, false)
                            if card then
                                room:obtainCard(p, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                                    player:objectName(), p:objectName(), self:objectName(), ""), false)
                                if player:isWounded() then
                                    room:recover(player, sgs.RecoverStruct(p, nil, SKMC.number_correction(player, 1)))
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.Damage and player:getPhase() ~= sgs.Player_NotActive then
            local damage = data:toDamage()
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "niu_lang_from_") and player:getMark(mark) ~= 0 then
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if string.find(mark, p:objectName()) then
                            for i = SKMC.number_correction(p, 1), damage.damage, SKMC.number_correction(p, 1) do
                                room:drawCards(p, 1, self:objectName())
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if player:objectName() == dying.who:objectName() then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if (string.find(mark, "niu_lang_from_") or string.find(mark, "niu_lang_to_"))
                        and player:getMark(mark) ~= 0 then
                        room:setPlayerMark(player, mark, 0)
                        for _, p in sgs.qlist(room:getOtherPlayers()) do
                            if string.find(mark, p:objectName()) then
                                for _, _mark in sgs.list(p:getMarkNames()) do
                                    if (string.find(_mark, "niu_lang_from_") or string.find(_mark, "niu_lang_to_"))
                                        and string.find(_mark, player:objectName()) and p:getMark(mark) ~= 0 then
                                        room:setPlayerMark(p, _mark, 0)
                                    end
                                end
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
NijikaIshimori:addSkill(sakamichi_niu_lang)

sgs.LoadTranslationTable {
    ["NijikaIshimori"] = "石森 虹花",
    ["&NijikaIshimori"] = "石森 虹花",
    ["#NijikaIshimori"] = "巧克力人",
    ["~NijikaIshimori"] = "お前主食チョコだろ",
    ["designer:NijikaIshimori"] = "Cassimolar",
    ["cv:NijikaIshimori"] = "石森 虹花",
    ["illustrator:NijikaIshimori"] = "Cassimolar",
    ["sakamichi_mi_xuan"] = "密选",
    [":sakamichi_mi_xuan"] = "一名角色对你造成伤害时，若其角色势力和其武将牌势力不同，你失去1点体力上限防止此伤害。出牌阶段限一次，若你未受伤，你可以弃置一张【桃】来增加1点体力上限。",
    ["sakamichi_chi_dun"] = "迟钝",
    [":sakamichi_chi_dun"] = "锁定技，摸牌阶段，若你的体力值与你手牌数的差大于额定摸牌数，你少摸一张牌。",
    ["sakamichi_niu_lang"] = "牛郎",
    [":sakamichi_niu_lang"] = "限定技，出牌阶段，你可以选择一名体力值小于你的角色，直到你或其进入濒死：你的结束阶段可以交给其一张手牌，然后其令你回复1点体力；其于其回合内每造成1点伤害，你摸一张牌。",
    ["@niu_lang"] = "牛郎",
    ["@niu_lang_give"] = "你可以交给%src一张手牌",
}
