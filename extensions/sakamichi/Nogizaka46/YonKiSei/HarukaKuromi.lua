require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HarukaKuromi = sgs.General(Sakamichi, "HarukaKuromi", "Nogizaka46", 3, false, true)
SKMC.YonKiSei.HarukaKuromi = true
SKMC.SeiMeiHanDan.HarukaKuromi = {
    name = {11, 7, 8, 9},
    ten_kaku = {18, "ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "da_ji",
    },
}

sakamichi_san_liu_jiu = sgs.CreateTriggerSkill {
    name = "sakamichi_san_liu_jiu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.MarkChanged},
    on_trigger = function(self, event, player, data, room)
        local mark = data:toMark()
        if mark.name == "@clock_time" then
            local n = player:getMark("@clock_time")
            for _, p in sgs.qlist(room:getAllPlayers(true)) do
                if p:hasSkill(self) and p:isDead() then
                    if n == SKMC.number_correction(p, 3) or n == SKMC.number_correction(p, 6) or n
                        == SKMC.number_correction(p, 9) then
                        room:revivePlayer(p)
                        room:recover(p, sgs.RecoverStruct(p, nil, p:getMaxHp() - p:getHp()))
                        room:drawCards(p, n, self:objectName())
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
HarukaKuromi:addSkill(sakamichi_san_liu_jiu)

sakamichi_jian_shu = sgs.CreateTriggerSkill {
    name = "sakamichi_jian_shu",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged, sgs.PreCardUsed, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName()
                ~= player:objectName() and damage.from:getWeapon() then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:obtainCard(player, damage.from:getWeapon())
                end
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play and use.card:getSkillName()
                ~= self:objectName() then
                for _, p in sgs.qlist(use.to) do
                    room:setPlayerMark(player, self:objectName() .. "_" .. p:objectName() .. "_used_play_end_clear", 1)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Weapon") then
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                slash:deleteLater()
                slash:setSkillName(self:objectName())
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:canSlash(p, slash, false) then
                        targets:append(p)
                    end
                end
                if targets:length() ~= 0 then
                    room:useCard(sgs.CardUseStruct(slash, player, targets))
                end
            end
        end
        return false
    end,
}
sakamichi_jian_shu_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_jian_shu_target_mod",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_jian_shu") and from:getWeapon() and from:inMyAttackRange(to)
            and from:getMark("sakamichi_jian_shu_" .. to:objectName() .. "_used_play_end_clear") == 0 then
            return 1000
        else
            return 0
        end
    end,
}
HarukaKuromi:addSkill(sakamichi_jian_shu)
if not sgs.Sanguosha:getSkill("#sakamichi_jian_shu_target_mod") then
    SKMC.SkillList:append(sakamichi_jian_shu_target_mod)
end

sgs.LoadTranslationTable {
    ["HarukaKuromi"] = "黒見 明香",
    ["&HarukaKuromi"] = "黒見 明香",
    ["#HarukaKuromi"] = "功夫美少女",
    ["~HarukaKuromi"] = "考えるな感じろ",
    ["designer:HarukaKuromi"] = "Cassimolar",
    ["cv:HarukaKuromi"] = "黒見 明香",
    ["illustrator:HarukaKuromi"] = "Cassimolar",
    ["sakamichi_san_liu_jiu"] = "三六九",
    [":sakamichi_san_liu_jiu"] = "锁定技，第3/6/9轮开始时，若你已死亡，你复活并摸等同于轮数的牌。",
    ["sakamichi_jian_shu"] = "剑术",
    [":sakamichi_jian_shu"] = "当你受到【杀】造成的伤害后，若伤害来源不为你且装备有武器，你可以获得之。出牌阶段，若你装备武器，你对攻击范围内此阶段未对其使用过【杀】的角色使用【杀】无次数限制。你使用武器牌时视为对其他角色使用一张【杀】。",
}
