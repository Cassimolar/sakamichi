require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SayaKanagawa = sgs.General(Sakamichi, "SayaKanagawa", "Nogizaka46", 4, false)
SKMC.YonKiSei.SayaKanagawa = true
SKMC.SeiMeiHanDan.SayaKanagawa = {
    name = {8, 3, 10, 9},
    ten_kaku = {11, "ji"},
    jin_kaku = {13, "da_ji"},
    ji_kaku = {19, "xiong"},
    soto_kaku = {17, "ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_guan_xing = sgs.CreateTriggerSkill {
    name = "sakamichi_guan_xing",
    shiming_skill = true,
    events = {sgs.AfterDrawInitialCards, sgs.Death, sgs.Damaged, sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AfterDrawInitialCards and player:hasSkill(self) and player:getMark(self:objectName()) == 0 then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@sakamichi_guan_xing_choice", false, true)
            local _data = sgs.QVariant()
            _data:setValue(target)
            player:setTag(self:objectName() .. "_target", _data)
            room:askForGuanxing(target, room:getNCards(
                math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, false), 0, true)
            room:askForGuanxing(player, room:getNCards(
                math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, true), 0, true)
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:objectName() ~= p:objectName() and p:getMark(self:objectName()) == 0 then
                        local target = p:getTag(self:objectName() .. "_target"):toPlayer()
                        if target and target:isAlive() then
                            room:askForGuanxing(target, room:getNCards(
                                math.min(room:alivePlayerCount(), SKMC.number_correction(p, 5)), false, false), 0, true)
                        end
                        room:askForGuanxing(p, room:getNCards(
                            math.min(room:alivePlayerCount(), SKMC.number_correction(p, 5)), false, true), 0, true)
                    end
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Thunder then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if damage.damage >= SKMC.number_correction(p, 3) then
                        if p:objectName() ~= player:objectName() then
                            if player:getMark(self:objectName()) == 0 then
                                room:sendShimingLog(p, self:objectName())
                                room:setPlayerMark(p, self:objectName() .. "_can_trigger", 1)
                            end
                        else
                            if player:getMark(self:objectName()) == 0 then
                                room:sendShimingLog(p, self:objectName(), false)
                                p:turnOver()
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Start and player:hasSkill(self) and player:getMark(self:objectName()) ~= 0
                and player:getMark(self:objectName() .. "_can_trigger") ~= 0 then
                local target = player:getTag(self:objectName() .. "_target"):toPlayer()
                if target and target:isAlive() then
                    room:askForGuanxing(target, room:getNCards(
                        math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, false), 0, true)
                end
                room:askForGuanxing(player, room:getNCards(
                    math.min(room:alivePlayerCount(), SKMC.number_correction(player, 5)), false, true), 0, true)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SayaKanagawa:addSkill(sakamichi_guan_xing)

sakamichi_ping_he = sgs.CreateTriggerSkill {
    name = "sakamichi_ping_he",
    frequency = sgs.Skill_Limited,
    limit_mark = "@ping_he",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Thunder and player:getMark("@ping_he") ~= 0
            and room:askForSkillInvoke(player, self:objectName(),
                sgs.QVariant("invoke:::" .. self:objectName() .. ":" .. damage.damage)) then
            room:removePlayerMark(player, "@ping_he", 1)
            local choices = {}
            for i = 0, damage.damage, 1 do
                local x = i
                local y = damage.damage - i
                table.insert(choices, "recover=" .. x .. "=" .. y)
            end
            local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
            local x, y = string.match(choice, "recover=(%d+)=(%d+)")
            room:recover(player, sgs.RecoverStruct(player, nil, x))
            room:drawCards(player, y, self:objectName())
            return true
        end
        return false
    end,
}
SayaKanagawa:addSkill(sakamichi_ping_he)

sgs.LoadTranslationTable {
    ["SayaKanagawa"] = "金川 紗耶",
    ["&SayaKanagawa"] = "金川 紗耶",
    ["#SayaKanagawa"] = "夜观星象",
    ["~SayaKanagawa"] = "ヘイワ！",
    ["designer:SayaKanagawa"] = "Cassimolar",
    ["cv:SayaKanagawa"] = "金川 紗耶",
    ["illustrator:SayaKanagawa"] = "Cassimolar",
    ["sakamichi_guan_xing"] = "观星",
    [":sakamichi_guan_xing"] = "使命技，分发起始手牌后，你选择一名其他角色，其与你分别观看牌堆底和牌堆顶X张牌，并可以将任意数量的牌以任意顺序置于牌堆顶或牌堆底，其他角色死亡时，你与该角色重复此流程（X为存活角色数且最大为5）。成功：当一名其他角色受到至少3点雷电伤害后，准备阶段，你可以与其重复此流程。失败：你受到至少3点雷电伤害后，你翻面。",
    ["@sakamichi_guan_xing_choice"] = "请选择一名和你一起看星星的角色",
    ["sakamichi_ping_he"] = "平和",
    [":sakamichi_ping_he"] = "限定技，当你受到雷电伤害时，你可以防止之并恢复X点体力摸Y张牌（X+Y等于此次伤害量）。",
    ["sakamichi_ping_he:invoke"] = "是否发动【%arg】防止此次%arg2点雷电伤害",
    ["sakamichi_ping_he:recover"] = "回复%src点体力摸%arg张牌",
}
