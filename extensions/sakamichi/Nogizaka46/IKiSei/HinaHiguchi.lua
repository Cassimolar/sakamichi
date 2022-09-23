require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinaHiguchi = sgs.General(Sakamichi, "HinaHiguchi", "Nogizaka46", 3, false)
SKMC.IKiSei.HinaHiguchi = true
SKMC.SeiMeiHanDan.HinaHiguchi = {
    name = {15, 3, 4, 8},
    ten_kaku = {18, "ji"},
    jin_kaku = {7, "ji"},
    ji_kaku = {12, "xiong"},
    soto_kaku = {23, "ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_ying_yuan_hui = sgs.CreateTriggerSkill {
    name = "sakamichi_ying_yuan_hui",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:canSlash(damage.to, nil, true) then
                    room:askForUseSlashTo(p, damage.to, "@ying_yuan_hui_slash:" .. damage.to:objectName(), true, false)
                end
            end
        end
        return false
    end,
}

HinaHiguchi:addSkill(sakamichi_ying_yuan_hui)

sakamichi_mi_gan = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_gan",
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p:isAlive() and p:objectName() ~= player:objectName() and p:canDiscard(p, "h") then
                local card = room:askForDiscard(p, self:objectName(), 1, 1, true, false,
                    "@mi_gan_discard:" .. player:objectName())
                if card then
                    local m = SKMC.number_correction(p, 1)
                    n = n + m
                    SKMC.send_message(room, "#mi_gan", p, player, nil, nil, self:objectName(), m, n)
                    room:addPlayerMark(player, "@mi_gan")
                    data:setValue(n)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaHiguchi:addSkill(sakamichi_mi_gan)

sakamichi_zhi_ming = sgs.CreateTriggerSkill {
    name = "sakamichi_zhi_ming",
    events = {sgs.Damaged, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            local m = SKMC.number_correction(player, 1)
            if damage.from and damage.from:getMark("@mi_gan") ~= 0 and room:askForSkillInvoke(player, self:objectName(),
                sgs.QVariant("invoke:" .. damage.from:objectName() .. "::" .. self:objectName() .. ":" .. m)) then
                room:addMaxCards(damage.from, -m)
                room:removePlayerMark(damage.from, "@mi_gan")
                room:setPlayerFlag(damage.from, "zhi_ming_used")
                room:setPlayerMark(player, damage.from:objectName() .. "zhi_ming", 1)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Discard then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("zhi_ming_used") then
                        if p:getHandcardNum() > p:getMaxCards() then
                            for _, pl in sgs.qlist(room:getAlivePlayers()) do
                                if pl:getMark(p:objectName() .. "zhi_ming") ~= 0 then
                                    room:drawCards(pl, 2, self:objectName())
                                    room:setPlayerMark(pl, p:objectName() .. "zhi_ming", 0)
                                end
                            end
                        end
                        room:setPlayerFlag(p, "-zhi_ming_used")
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
HinaHiguchi:addSkill(sakamichi_zhi_ming)

sgs.LoadTranslationTable {
    ["HinaHiguchi"] = "樋口 日奈",
    ["&HinaHiguchi"] = "樋口 日奈",
    ["#HinaHiguchi"] = "和风美人",
    ["~HinaHiguchi"] = "でんちゃんの目が一瞬真っ黒に",
    ["designer:HinaHiguchi"] = "Cassimolar",
    ["cv:HinaHiguchi"] = "樋口 日奈",
    ["illustrator:HinaHiguchi"] = "Cassimolar",
    ["sakamichi_ying_yuan_hui"] = "应援会",
    [":sakamichi_ying_yuan_hui"] = "锁定技，当你使用【杀】造成伤害后，所有可以对目标使用【杀】的其他角色可以对其使用一张【杀】。",
    ["@ying_yuan_hui_slash"] = "你可以对%src 使用一张【杀】",
    ["sakamichi_mi_gan"] = "蜜柑",
    [":sakamichi_mi_gan"] = "其他角色摸牌阶段，你可以弃置一张手牌，令其额定摸牌数+1并获得一枚「蜜柑」标记。",
    ["@mi_gan_discard"] = "你可以弃置一张手牌令%src 额定摸牌数+1",
    ["@mi_gan"] = "蜜柑",
    ["~mi_gan"] = "选择一张手牌 → 点击确定",
    ["#mi_gan"] = "%to 受到了%from的【%arg】的影响，额定摸牌数+%arg2，额定摸牌数为%arg3",
    ["sakamichi_zhi_ming"] = "直名",
    [":sakamichi_zhi_ming"] = "你受到有「蜜柑」的角色造成的伤害后，你可以令其本回合手牌上限-1并移除一枚「蜜柑」，若本回合弃牌阶段开始时，其手牌数不小于手牌上限，你摸两张牌。",
    ["sakamichi_zhi_ming:invoke"] = "是否发动【%arg】令%src 本回合手牌上限-%arg2",
}
