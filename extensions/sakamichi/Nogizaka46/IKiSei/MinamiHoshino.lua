require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MinamiHoshino = sgs.General(Sakamichi, "MinamiHoshino", "Nogizaka46", 3, false)
SKMC.IKiSei.MinamiHoshino = true
SKMC.SeiMeiHanDan.MinamiHoshino = {
    name = {9, 11, 3, 5, 3},
    ten_kaku = {20, "xiong"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {11, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_ai_xin = sgs.CreateTriggerSkill {
    name = "sakamichi_ai_xin",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            local result = SKMC.run_judge(room, player, self:objectName(), ".|heart")
            if result.isGood then
                room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
            end
        end
        return false
    end,
}
MinamiHoshino:addSkill(sakamichi_ai_xin)

sakamichi_meng_hun = sgs.CreateTriggerSkill {
    name = "sakamichi_meng_hun",
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and not player:isKongcheng()
            and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
                "invoke:" .. use.from:objectName() .. "::" .. use.card:objectName() .. ":" .. self:objectName())) then
            player:throwAllHandCards()
            SKMC.send_message(room, "#meng_hun_avoid", player, nil, nil, use.card:toString(), self:objectName())
            local nullified_list = use.nullified_list
            table.insert(nullified_list, player:objectName())
            use.nullified_list = nullified_list
            data:setValue(use)
            room:drawCards(player, 1, self:objectName())
            room:drawCards(use.from, 1, self:objectName())
        end
        return false
    end,
}
MinamiHoshino:addSkill(sakamichi_meng_hun)

sakamichi_shi_ba = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_ba",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if ((move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand)
            or (move.from and move.from:objectName() == player:objectName()
                and move.from_places:contains(sgs.Player_PlaceHand))) and player:getHandcardNum() > 6 then
            SKMC.send_message(room, "#shi_ba_jin", player, nil, nil, nil, self:objectName())
            room:damage(sgs.DamageStruct(self:objectName(), nil, player, SKMC.number_correction(player, 1)))
        end
        return false
    end,
}
MinamiHoshino:addSkill(sakamichi_shi_ba)

sgs.LoadTranslationTable {
    ["MinamiHoshino"] = "星野 みなみ",
    ["&MinamiHoshino"] = "星野 みなみ",
    ["#MinamiHoshino"] = "小祖宗",
    ["~MinamiHoshino"] = "今ピンク大好きなんです❤",
    ["designer:MinamiHoshino"] = "Cassimolar",
    ["cv:MinamiHoshino"] = "星野 みなみ",
    ["illustrator:MinamiHoshino"] = "Cassimolar",
    ["sakamichi_ai_xin"] = "爱心",
    [":sakamichi_ai_xin"] = "当你受到伤害后，你可以判定，若结果为红桃，你回复1点体力。",
    ["sakamichi_meng_hun"] = "萌混",
    [":sakamichi_meng_hun"] = "当你成为【杀】或【决斗】的目标时，你可以弃置所有手牌令此牌对你无效，然后你和此牌的使用者各摸一张牌。",
    ["sakamichi_meng_hun:invoke"] = "是否弃置所有手牌发动【%arg2】令%src使用的【%arg】对你无效",
    ["sakamichi_shi_ba"] = "十八",
    [":sakamichi_shi_ba"] = "锁定技，当你手牌数发生改变后，若你的手牌数多于六张，则你受到1点无来源伤害。",
    ["#shi_ba_jin"] = "%from 受到【%arg】的影响，%from 受到1点无来源伤害",
}
