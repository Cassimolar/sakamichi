require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MizuhoSuzuki = sgs.General(Sakamichi, "MizuhoSuzuki", "Keyakizaka46", 3, false)
SKMC.IKiSei.MizuhoSuzuki = true
SKMC.SeiMeiHanDan.MizuhoSuzuki = {
    name = {13, 4, 9, 6},
    ten_kaku = {17, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {19, "ji"},
    sou_kaku = {31, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_nian_shao = sgs.CreateTriggerSkill {
    name = "sakamichi_nian_shao",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            if not player:canDiscard(player, "he")
                and room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@nian_shao_discard") then
                damage.damage = damage.damage - 1
                data:setValue(damage)
                if damage.damage < 1 then
                    return true
                end
            else
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
MizuhoSuzuki:addSkill(sakamichi_nian_shao)

sakamichi_qin_zuCard = sgs.CreateSkillCard {
    name = "sakamichi_qin_zuCard",
    skill_name = "sakamichi_qin_zu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:removePlayerMark(source, "@qin_zu")
        room:setPlayerProperty(source, "kingdom", sgs.QVariant("AutisticGroup"))
        room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp() + 1))
        room:recover(source, sgs.RecoverStruct(source, nil, 1))
        if source:getHandcardNum() < source:getMaxHp() then
            room:drawCards(source, 3, "sakamichi_qin_zu")
        end
    end,
}
sakamichi_qin_zu = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_qin_zu",
    frequency = sgs.Skill_Limited,
    limit_mark = "@qin_zu",
    view_as = function(self)
        return sakamichi_qin_zuCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@qin_zu") ~= 0
    end,
}
MizuhoSuzuki:addSkill(sakamichi_qin_zu)

sgs.LoadTranslationTable {
    ["MizuhoSuzuki"] = "鈴木 泉帆",
    ["&MizuhoSuzuki"] = "鈴木 泉帆",
    ["#MizuhoSuzuki"] = "立教美人",
    ["~MizuhoSuzuki"] = "鈴木泉帆って誰？",
    ["designer:MizuhoSuzuki"] = "Cassimolar",
    ["cv:MizuhoSuzuki"] = "鈴木 泉帆",
    ["illustrator:MizuhoSuzuki"] = "Cassimolar",
    ["sakamichi_nian_shao"] = "年少",
    [":sakamichi_nian_shao"] = "当你受到伤害时，若你的体力不为全场最多，你可以摸一张牌或弃置一张牌令此伤害-1。",
    ["@nian_shao_discard"] = "你可以弃置一张牌来使此伤害-1，否则摸一张牌",
    ["sakamichi_qin_zu"] = "亲阻",
    [":sakamichi_qin_zu"] = "限定技，出牌阶段，你可以将势力修改为自闭群，然后增加1点体力上限并回复1点体力，然后若你的手牌数小于体力上限，你摸三张牌。",
    ["@qin_zu"] = "亲阻",
}
