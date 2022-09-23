require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HimekaNakamoto = sgs.General(Sakamichi, "HimekaNakamoto", "Nogizaka46", 4, false)
SKMC.IKiSei.HimekaNakamoto = true
SKMC.SeiMeiHanDan.HimekaNakamoto = {
    name = {4, 4, 4, 8, 9},
    ten_kaku = {8, "ji"},
    jin_kaku = {8, "ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {21, "ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_beam_card_1 = sgs.CreateSkillCard {
    name = "sakamichi_beamCard",
    skill_name = "sakamichi_beam",
    target_fixed = false,
    will_throw = true,
    filter = function(self, target, to_select)
        if self:getSubcards():length() == 2 or self:getSubcards():length() == 4 then
            return #target == 0
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if self:getSubcards():length() == 2 then
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to,
                SKMC.number_correction(effect.from, 1)))
        elseif self:getSubcards():length() == 4 then
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, effect.to,
                SKMC.number_correction(effect.from, 4)))
        end
    end,
}
sakamichi_beam_card_2 = sgs.CreateSkillCard {
    name = "sakamichi_beamCard",
    skill_name = "sakamichi_beam",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        room:damage(
            sgs.DamageStruct(self:getSkillName(), effect.from, effect.to, SKMC.number_correction(effect.from, 1)))
    end,
}
sakamichi_beam = sgs.CreateViewAsSkill {
    name = "sakamichi_beam",
    n = 4,
    view_filter = function(self, selected, to_select)
        if #selected >= 4 then
            return false
        end
        if to_select:isEquipped() then
            return false
        end
        for _, card in ipairs(selected) do
            if card:getSuit() == to_select:getSuit() then
                return false
            end
        end
        return true
    end,
    view_as = function(self, cards)
        if #cards > 4 or #cards < 2 then
            return nil
        end
        if #cards == 2 or #cards == 4 then
            local cd = sakamichi_beam_card_1:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            return cd
        elseif #cards == 3 then
            local cd = sakamichi_beam_card_2:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            return cd
        end
    end,
}
HimekaNakamoto:addSkill(sakamichi_beam)

sakamichi_ku_bi = sgs.CreateMaxCardsSkill {
    name = "sakamichi_ku_bi",
    extra_func = function(self, target)
        if target:hasSkill(self) then
            return -1
        end
    end,
}
HimekaNakamoto:addSkill(sakamichi_ku_bi)

sakamichi_wang_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_wang_dao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death, sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.damage and death.damage.from and death.damage.from:hasSkill(self) then
                room:setPlayerMark(player, "wang_dao", 1)
            end
        elseif event == sgs.DrawNCards then
            if player:hasSkill(self) then
                local count = data:toInt()
                data:setValue(count + (player:getMark("wang_dao") * SKMC.number_correction(player, 1)))
            end
        end

    end,
    can_trigger = function(self, target)
        return target
    end,
}

sgs.LoadTranslationTable {
    ["HimekaNakamoto"] = "中元 日芽香",
    ["&HimekaNakamoto"] = "中元 日芽香",
    ["#HimekaNakamoto"] = "小公主",
    ["~HimekaNakamoto"] = "ひめたんビーム",
    ["designer:HimekaNakamoto"] = "Cassimolar",
    ["cv:HimekaNakamoto"] = "中元 日芽香",
    ["illustrator:HimekaNakamoto"] = "Cassimolar",
    ["sakamichi_beam"] = "Beam",
    [":sakamichi_beam"] = "出牌阶段，你可以：弃置两张不同花色的手牌对一名角色造成1点伤害；弃置三张不同花色的手牌对所有角色造成1点伤害；弃置四张不同花色的手牌对一名角色造成4点伤害。",
    ["~sakamichi_beam"] = "选择二到四张不同花色手牌 → 点击确定",
    ["sakamichi_ku_bi"] = "苦逼",
    [":sakamichi_ku_bi"] = "锁定技，你的手牌上限-1。",
    ["sakamichi_wang_dao"] = "王道",
    [":sakamichi_wang_dao"] = "锁定技，每当你杀死一名角色后，你的摸牌阶段额定摸牌数+1。",
}
