require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ReiSeimiya = sgs.General(Sakamichi, "ReiSeimiya", "Nogizaka46", 4, false)
SKMC.YonKiSei.ReiSeimiya = true
SKMC.SeiMeiHanDan.ReiSeimiya = {
    name = {11, 10, 1, 2},
    ten_kaku = {21, "ji"},
    jin_kaku = {11, "ji"},
    ji_kaku = {3, "ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_huo_li = sgs.CreateTriggerSkill {
    name = "sakamichi_huo_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        local n = SKMC.number_correction(player, 1)
        if event == sgs.DamageCaused and player:getPhase() ~= sgs.Player_NotActive then
            if not player:hasFlag(self:objectName() .. "_damage") then
                room:setPlayerFlag(player, self:objectName() .. "_damage")
                SKMC.send_message(room, "#huo_li_damage", player, damage.to, nil, nil, self:objectName(), damage.damage,
                    n, damage.damage + n)
                damage.damage = damage.damage + n
                data:setValue(damage)
            end
        elseif event == sgs.DamageInflicted and player:getPhase() == sgs.Player_NotActive then
            if not player:hasFlag(self:objectName() .. "_damaged") then
                room:setPlayerFlag(player, self:objectName() .. "_damaged")
                SKMC.send_message(room, "#huo_li_damaged", player, damage.from, nil, nil, self:objectName(),
                    damage.damage, n, damage.damage - n)
                damage.damage = damage.damage - n
                data:setValue(damage)
                if damage.damage < 1 then
                    SKMC.send_message(room, "#huo_li_damaged_cancel", player, damage.from, nil, nil, self:objectName())
                    return true
                end
            end
        end
        return false
    end,
}
ReiSeimiya:addSkill(sakamichi_huo_li)

sakamichi_tiao_chuang = sgs.CreateTriggerSkill {
    name = "sakamichi_tiao_chuang",
    events = {sgs.DamageInflicted, sgs.DamageComplete},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if event == sgs.DamageInflicted then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                local can_trigger = true
                if player:objectName() ~= p:objectName() then
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, self:objectName()) and p:getMark(mark) ~= 0 then
                            can_trigger = false
                        end
                    end
                    if can_trigger and room:askForSkillInvoke(p, self:objectName(), data) then
                        room:setPlayerFlag(p, self:objectName())
                        room:setPlayerMark(p, self:objectName() .. player:objectName() .. "_lun_clear", damage.damage)
                        damage.to = p
                        damage.transfer = true
                        room:damage(damage)
                        return true
                    end
                end
            end
        elseif event == sgs.DamageComplete then
            if player:hasFlag(self:objectName()) then
                room:drawCards(player, player:getLostHp(), self:objectName())
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    local n = player:getMark(self:objectName() .. p:objectName() .. "_lun_clear")
                    if n ~= 0 then
                        local card
                        if player:getHandcardNum() + player:getEquips():length() <= n then
                            card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                            card:deleteLater()
                            card:addSubcards(player:getCards("he"))
                        else
                            card = room:askForExchange(player, self:objectName(), n, n, true,
                                "@tiao_chuang:" .. p:objectName() .. "::" .. n)
                        end
                        room:obtainCard(p, card, false)
                    end
                end
                room:setPlayerFlag(player, "-" .. self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
ReiSeimiya:addSkill(sakamichi_tiao_chuang)

sgs.LoadTranslationTable {
    ["ReiSeimiya"] = "清宮 レイ",
    ["&ReiSeimiya"] = "清宮 レイ",
    ["#ReiSeimiya"] = "小太阳",
    ["~ReiSeimiya"] = "私の人生SSRだ！",
    ["designer:ReiSeimiya"] = "Cassimolar",
    ["cv:ReiSeimiya"] = "清宮 レイ",
    ["illustrator:ReiSeimiya"] = "Cassimolar",
    ["sakamichi_huo_li"] = "活力",
    [":sakamichi_huo_li"] = "锁定技，你于回合内造成的第一次伤害+1。你于回合外受到的第一次伤害-1。",
    ["#huo_li_damage"] = "%from 的【%arg】被触发，%from 对 %to 造成的此次伤害由%arg2点增加%arg3点，此次伤害为%arg4点。",
    ["#huo_li_damaged"] = "%from 的【%arg】被触发，%to 对 %from 造成的此次伤害由%arg2点减少%arg3点，此次伤害为%arg4点。",
    ["#huo_li_damaged_cancel"] = "%from 的【%arg】被触发，防止%to 对 %from 造成的此次伤害。",
    ["sakamichi_tiao_chuang"] = "跳床",
    [":sakamichi_tiao_chuang"] = "每轮限一次，一名其他角色受到伤害时，你可以代替其承受此次伤害，然后你摸X张牌并交给其等同此次伤害量的牌（X为你已损失的体力值）。",
    ["@tiao_chuang"] = "你需要交给%src %arg张牌。",
}
