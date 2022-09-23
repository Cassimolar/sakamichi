require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SayuriInoue = sgs.General(Sakamichi, "SayuriInoue", "Nogizaka46", 4, false, false, false, 3)
SKMC.IKiSei.SayuriInoue = true
SKMC.SeiMeiHanDan.SayuriInoue = {
    name = {4, 3, 3, 6, 6},
    ten_kaku = {7, "ji"},
    jin_kaku = {6, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {22, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_man_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_man_shi",
    frequency = sgs.Skill_Wake,
    events = {sgs.MarkChanged},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if event == sgs.MarkChanged then
            local mark = data:toMark()
            if mark.name == "man_shi_recover" and player:getMark("man_shi_recover") >= SKMC.number_correction(player, 3) then
                return true
            end
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:addPlayerMark(player, self:objectName())
        room:drawCards(player, 2, self:objectName())
        room:setPlayerMark(player, "man_shi_recover", 0)
        return false
    end,
}
sakamichi_man_shi_record = sgs.CreateTriggerSkill {
    name = "#sakamichi_man_shi_record",
    events = {sgs.CardFinished, sgs.HpRecover, sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Peach") then
                local ids = sgs.IntList()
                if use.card:isVirtualCard() then
                    ids = use.card:getSubcards()
                else
                    ids:append(use.card:getEffectiveId())
                end
                if not ids:isEmpty() then
                    local in_discard = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                            in_discard = false
                            break
                        end
                    end
                    if in_discard then
                        if player:hasSkill("sakamichi_man_shi") and player:getMark("man_shi_used") == 0 then
                            if player:getMark("sakamichi_man_shi") ~= 0 then
                                if room:askForSkillInvoke(player, "sakamichi_man_shi", data) then
                                    room:obtainCard(player, use.card, true)
                                    room:setPlayerMark(player, "man_shi_used", 1)
                                end
                            elseif player:getPhase() == sgs.Player_Play then
                                if room:askForSkillInvoke(player, "sakamichi_man_shi", data) then
                                    room:obtainCard(player, use.card, true)
                                    room:setPlayerMark(player, "man_shi_used", 1)
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:hasSkill("sakamichi_man_shi") and recover.who:getMark("sakamichi_man_shi")
                == 0 then
                room:addPlayerMark(recover.who, "man_shi_recover", recover.recover)
            end
        elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                room:setPlayerMark(p, "man_shi_used", 0)
                room:setPlayerMark(p, "man_shi_recover", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_man_shi_record", "#sakamichi_man_shi_record")
SayuriInoue:addSkill(sakamichi_man_shi)
SayuriInoue:addSkill(sakamichi_man_shi_record)

sakamichi_chu_jin = sgs.CreateTriggerSkill {
    name = "sakamichi_chu_jin",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if not room:getTag("FirstRound"):toBool() and move.to and move.to:objectName() == player:objectName()
            and move.to_place == sgs.Player_PlaceHand then
            room:addMaxCards(player, SKMC.number_correction(player, move.card_ids:length()), true)
            SKMC.send_message(room, "#chu_jin_max", player, nil, nil, nil, self:objectName(), player:getMaxCards())
        end
        if move.from and move.to and move.from:objectName() == player:objectName() and move.from:objectName()
            ~= move.to:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:damage(sgs.DamageStruct(self:objectName(), player,
                    room:findPlayerByObjectName(move.to:objectName()), SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
SayuriInoue:addSkill(sakamichi_chu_jin)

sakamichi_fei_ren_card = sgs.CreateSkillCard {
    name = "sakamichi_fei_renCard",
    skill_name = "sakamichi_fei_ren",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targtes)
        room:removePlayerMark(source, "@fei_ren")
        local x = source:getHp()
        room:loseHp(source, x)
        if source:isAlive() then
            room:drawCards(source, x + SKMC.number_correction(source, 1), self:getSkillName())
            room:setPlayerFlag(source, "fei_ren")
        end
    end,
}
sakamichi_fei_ren_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_fei_ren",
    view_as = function(self)
        return sakamichi_fei_ren_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@fei_ren") ~= 0
    end,
}
sakamichi_fei_ren = sgs.CreateTriggerSkill {
    name = "sakamichi_fei_ren",
    frequency = sgs.Skill_Limited,
    limit_mark = "@fei_ren",
    view_as_skill = sakamichi_fei_ren_view_as,
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and player:hasFlag("fei_ren") then
                room:setCardFlag(damage.card, "fei_ren")
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("fei_ren") and use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1)
            end
        end
    end,
}
sakamichi_fei_ren_Mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_fei_ren_Mod",
    pattern = ".",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_fei_ren") and from:hasFlag("fei_ren") then
            return 1000
        else
            return 0
        end
    end,
}
SayuriInoue:addSkill(sakamichi_fei_ren)
if not sgs.Sanguosha:getSkill("#sakamichi_fei_ren_Mod") then
    SKMC.SkillList:append(sakamichi_fei_ren_Mod)
end

sgs.LoadTranslationTable {
    ["SayuriInoue"] = "井上 小百合",
    ["&SayuriInoue"] = "井上 小百合",
    ["#SayuriInoue"] = "百合连者",
    ["~SayuriInoue"] = "この曲売れなかったら世間がおかしいと思う",
    ["designer:SayuriInoue"] = "Cassimolar",
    ["cv:SayuriInoue"] = "井上 小百合",
    ["illustrator:SayuriInoue"] = "Cassimolar",
    ["sakamichi_man_shi"] = "慢食",
    [":sakamichi_man_shi"] = "出牌阶段限一次，你使用的【桃】结算完成时，你可以获得之；觉醒技，当你于一回合内造成了至少3点回复，你摸两张牌并将本技能修改为每回合限一次。",
    ["sakamichi_chu_jin"] = "储金",
    [":sakamichi_chu_jin"] = "你的回合内，你每获得一张手牌本回合你的手牌上限+1。其他角色获得你的牌后，你可以对其造成1点伤害。",
    ["#chu_jin_max"] = "%from 发动了【%arg】，本回合内%from 的手牌上限为 %arg2 张",
    ["sakamichi_fei_ren"] = "飞人",
    [":sakamichi_fei_ren"] = "限定技，出牌阶段，你可以失去X点体力然后摸X+1张牌（X为你当前的体力值），本回合内你使用牌无距离限制、你使用的【杀】造成伤害后不计入使用次数限制。",
    ["@fei_ren"] = "飞人",
}
