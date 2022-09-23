require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MioYakubo = sgs.General(Sakamichi, "MioYakubo", "Nogizaka46", 4, false)
SKMC.YonKiSei.MioYakubo = true
SKMC.SeiMeiHanDan.MioYakubo = {
    name = {5, 3, 9, 9, 14},
    ten_kaku = {17, "ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {23, "ji"},
    soto_kaku = {22, "xiong"},
    sou_kaku = {40, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "huo",
        san_sai = "xiong",
    },
}

sakamichi_xie_zui = sgs.CreateTriggerSkill {
    name = "sakamichi_xie_zui",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damage, sgs.Damaged, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage or event == sgs.Damaged then
            local damage = data:toDamage()
            if (event == sgs.Damage and damage.from:objectName() == player:objectName() and player:hasSkill(self))
                or (event == sgs.Damaged and damage.to:objectName() == player:objectName() and player:hasSkill(self)) then
                if not damage.from:isKongcheng() then
                    if damage.from:getHandcardNum() == 1 then
                        damage.from:throwAllHandCards()
                    else
                        room:askForDiscard(damage.from, self:objectName(), 1, 1, false, false, nil, ".",
                            self:objectName())
                    end
                end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:hasSkill(self) and death.damage
                and death.damage.from then
                local skill_list = {}
                for _, skill in sgs.qlist(death.damage.from:getVisibleSkillList()) do
                    if not skill:isAttachedLordSkill() then
                        table.insert(skill_list, "-" .. skill:objectName())
                    end
                end
                room:handleAcquireDetachSkills(death.damage.from, table.concat(skill_list, "|"))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MioYakubo:addSkill(sakamichi_xie_zui)

sakamichi_shuang_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_shuang_zi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and player:getHandcardNum() < player:getHp()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            local x = 0
            local can_trigger = player:isWounded()
            while player:getHandcardNum() < player:getHp() do
                room:drawCards(player, 1, self:objectName())
                x = x + 1
            end
            if can_trigger then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@shuang_zi_invoke:::" .. x, true)
                if target then
                    room:drawCards(target, x, self:objectName())
                end
            end
        end
        return false
    end,
}
MioYakubo:addSkill(sakamichi_shuang_zi)

sgs.LoadTranslationTable {
    ["MioYakubo"] = "矢久保 美緒",
    ["&MioYakubo"] = "矢久保 美緒",
    ["#MioYakubo"] = "可爱具象",
    ["~MioYakubo"] = "遠藤さくらちゃん♥",
    ["designer:MioYakubo"] = "Cassimolar",
    ["cv:MioYakubo"] = "矢久保 美緒",
    ["illustrator:MioYakubo"] = "Cassimolar",
    ["sakamichi_xie_zui"] = "谢罪",
    [":sakamichi_xie_zui"] = "锁定技，其他角色对你造成伤害后，其须弃置一张手牌；你死亡时，杀死你的角色失去所有技能。",
    ["sakamichi_shuang_zi"] = "双子",
    [":sakamichi_shuang_zi"] = "结束阶段，你可以将手牌补至X张（X为你的体力值），若你已受伤，你可以令一名其他角色摸等量的牌。",
    ["@shuang_zi_invoke"] = "你可以令一名其他角色摸%arg张牌",
}
