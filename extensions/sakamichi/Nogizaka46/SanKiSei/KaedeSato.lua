require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KaedeSato = sgs.General(Sakamichi, "KaedeSato", "Nogizaka46", 3, false)
SKMC.SanKiSei.KaedeSato = true
SKMC.SeiMeiHanDan.KaedeSato = {
    name = {7, 18, 13},
    ten_kaku = {25, "ji"},
    jin_kaku = {31, "da_ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_bang_du = sgs.CreateTriggerSkill {
    name = "sakamichi_bang_du",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PreCardUsed, sgs.PreCardResponded, sgs.EventLoseSkill, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventLoseSkill then
            if data:toString() == self:objectName() then
                if player:getMark("&" .. self:objectName()) ~= 0 then
                    room:setPlayerMark(player, "&" .. self:objectName(), 0)
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:hasSkill(self) and player:getPhase() == sgs.Player_Play then
                if player:getMark("&" .. self:objectName()) ~= 0 then
                    room:setPlayerMark(player, "&" .. self:objectName(), 0)
                end
            end
        elseif player:hasSkill(self) and player:getPhase() == sgs.Player_Play then
            local card
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and not card:isKindOf("SkillCard") then
                local jie_li_num = SKMC.number_correction(player, 1) * player:getEquips():length()
                local num = SKMC.number_correction(player, 4)
                if player:hasSkill("sakamichi_jie_li") then
                    num = num + jie_li_num
                end
                if not card:isVirtualCard() then
                    if room:getCardPlace(card:getId()) == sgs.Player_PlaceHand then
                        room:addPlayerMark(player, "&" .. self:objectName())
                    end
                else
                    for _, id in sgs.qlist(card:getSubcards()) do
                        if room:getCardPlace(id) == sgs.Player_PlaceHand then
                            room:addPlayerMark(player, "&" .. self:objectName())
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
sakamichi_bang_du_target_mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_bang_du_target_mod",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_bang_du") then
            return 1000
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_bang_du") then
            return 1000
        else
            return 0
        end
    end,
}

sakamichi_bang_du_card_limit = sgs.CreateCardLimitSkill {
    name = "#sakamichi_bang_du_card_limit",
    limit_list = function(self, player)
        if player:hasSkill("sakamichi_bang_du") then
            local num = SKMC.number_correction(player, 4)
            if player:hasSkill("sakamichi_jie_li") then
                num = num + SKMC.number_correction(player, 1) * player:getEquips():length()
            end
            if player:getMark("&sakamichi_bang_du") >= num then
                return "use"
            end
        end
        return ""
    end,
    limit_pattern = function(self, player)
        if player:hasSkill("sakamichi_bang_du") then
            local num = SKMC.number_correction(player, 4)
            if player:hasSkill("sakamichi_jie_li") then
                num = num + SKMC.number_correction(player, 1) * player:getEquips():length()
            end
            if player:getMark("&sakamichi_bang_du") >= num then
                return ".|.|.|hand"
            end
        end
        return ""
    end,
}

KaedeSato:addSkill(sakamichi_bang_du)
if not sgs.Sanguosha:getSkill("#sakamichi_bang_du_target_mod") then
    SKMC.SkillList:append(sakamichi_bang_du_target_mod)
end
if not sgs.Sanguosha:getSkill("#sakamichi_bang_du_card_limit") then
    SKMC.SkillList:append(sakamichi_bang_du_card_limit)
end

sakamichi_jie_li = sgs.CreateTriggerSkill {
    name = "sakamichi_jie_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        local equips_num = player:getEquips():length()
        local num = math.floor(equips_num / SKMC.number_correction(player, 2))
        data:setValue(n + num)
        return false
    end,
}
KaedeSato:addSkill(sakamichi_jie_li)

sakamichi_kou_sha = sgs.CreateTriggerSkill {
    name = "sakamichi_kou_sha",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.damage and dying.damage.card and dying.damage.card:isKindOf("Slash") and dying.damage.from
            and dying.damage.from:hasSkill(self) and dying.damage.from:hasEquipArea()
            and room:askForSkillInvoke(dying.damage.from, self:objectName(),
                sgs.QVariant("invoke:" .. dying.who:objectName() .. "::" .. self:objectName() .. ":"
                                 .. SKMC.number_correction(dying.damage.from, 1))) then
            local equips_area = {"weapon_area", "armor_area", "offensive_horse_area", "defensive_horse_area",
                "treasure_area"}
            local equip_area = {}
            if dying.damage.from:hasWeaponArea() then
                table.insert(equip_area, "weapon_area")
            end
            if dying.damage.from:hasArmorArea() then
                table.insert(equip_area, "armor_area")
            end
            if dying.damage.from:hasOffensiveHorseArea() then
                table.insert(equip_area, "offensive_horse_area")
            end
            if dying.damage.from:hasDefensiveHorseArea() then
                table.insert(equip_area, "defensive_horse_area")
            end
            if dying.damage.from:hasTreasureArea() then
                table.insert(equip_area, "treasure_area")
            end
            if #equip_area > 0 then
                local choice = room:askForChoice(dying.damage.from, self:objectName(), table.concat(equip_area, "+"))
                for k, v in ipairs(equips_area) do
                    if v == choice then
                        room:loseMaxHp(dying.damage.from, SKMC.number_correction(dying.damage.from, 1))
                        dying.damage.from:throwEquipArea(k - 1)
                        room:killPlayer(dying.who, dying.damage)
                        break
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
KaedeSato:addSkill(sakamichi_kou_sha)

sgs.LoadTranslationTable {
    ["KaedeSato"] = "佐藤 楓",
    ["&KaedeSato"] = "佐藤 楓",
    ["#KaedeSato"] = "棒读偶像",
    ["~KaedeSato"] = "ソウラツイデスナオッチャッテテ···",
    ["designer:KaedeSato"] = "Cassimolar",
    ["cv:KaedeSato"] = "佐藤 楓",
    ["illustrator:KaedeSato"] = "Cassimolar",
    ["sakamichi_bang_du"] = "棒读",
    [":sakamichi_bang_du"] = "锁定技，你使用牌无距离和次数限制，但出牌阶段你至多使用4张手牌。",
    ["sakamichi_jie_li"] = "接力",
    [":sakamichi_jie_li"] = "锁定技，你【棒读】中的数字+X，摸阶段你额外摸X/2张牌（向下取整，X为你装备区装备数）。",
    ["sakamichi_kou_sha"] = "扣杀",
    [":sakamichi_kou_sha"] = "当你使用【杀】令一名角色进入濒死时，你可以失去1点体力上限并废除一个装备区，令其直接死亡。",
    ["sakamichi_kou_sha:invoke"] = "是否发动【%arg】失去%arg2点体力上限并废除一个装备区令%src立即死亡",
}
