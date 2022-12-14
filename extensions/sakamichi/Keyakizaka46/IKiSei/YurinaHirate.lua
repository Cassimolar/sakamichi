require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YurinaHirate = sgs.General(Sakamichi, "YurinaHirate$", "Keyakizaka46", 3, false)
SKMC.IKiSei.YurinaHirate = true
SKMC.SeiMeiHanDan.YurinaHirate = {
    name = {5, 4, 4, 11, 8},
    ten_kaku = {9, "xiong"},
    jin_kaku = {8, "ji"},
    ji_kaku = {23, "ji"},
    soto_kaku = {24, "da_ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "huo",
        san_sai = "xiong",
    },
}

sakamichi_hei_yang = sgs.CreateTriggerSkill {
    name = "sakamichi_hei_yang$",
    events = {sgs.Damage, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:isDamageCard() then
                if not damage.card:hasFlag("hei_yang_damage_done") then
                    if damage.card:hasFlag("hei_yang_damage") then
                        room:setCardFlag(damage.card, "hei_yang_damage_done")
                    else
                        damage.card:setFlags("hei_yang_damage")
                        damage.card:setTag("hei_yang", sgs.QVariant(damage.to:objectName()))
                    end
                end
            end
        else
            local use = data:toCardUse()
            if use.card:hasFlag("hei_yang_damage") then
                room:setCardFlag(use.card, "-hei_yang_damage")
                if not use.card:hasFlag("hei_yang_damage_done") then
                    if use.from
                        and (use.from:getKingdom() == "Keyakizaka46" or use.from:getKingdom() == "HiraganaKeyakizaka46")
                        and use.to:length() > 1 then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if p:hasLordSkill(self) and room:askForSKillInvoke(p, self:objectName(), data) then
                                for _, pl in sgs.qlist(use.to) do
                                    if pl:objectName() ~= use.card:getTag("hei_yang"):toString() then
                                        room:damage(sgs.DamageStruct(self:objectName(), p, pl,
                                            SKMC.number_correction(p, 1)))
                                    end
                                end
                            end
                        end
                    end
                else
                    room:setCardFlag(use.card, "-hei_yang_damage_done")
                end
                use.card:removeTag("hei_yang")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YurinaHirate:addSkill(sakamichi_hei_yang)

sakamichi_ping_shou = sgs.CreateTriggerSkill {
    name = "sakamichi_ping_shou",
    events = {sgs.PindianVerifying, sgs.SlashMissed, sgs.Pindian},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PindianVerifying then
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() or pindian.to:objectName() == player:objectName() then
                local target
                local target_point
                if pindian.from:objectName() == player:objectName() then
                    target = pindian.to
                    target_point = pindian.to_number
                else
                    target = pindian.from
                    target_point = pindian.from_number
                end
                if player:canDiscard(player, "he") and room:askForDiscard(player, self:objectName(), 1, 1, true, false,
                    "@ping_shou_invoke:" .. target:objectName() .. "::" .. target_point) then
                    if pindian.from:objectName() == player:objectName() then
                        pindian.from_number = pindian.to_number
                    else
                        pindian.to_number = pindian.from_number
                    end
                end
            end
        elseif event == sgs.SlashMissed then
            local effect = data:toSlashEffect()
            if player:canPindian(effect.to)
                and room:askForSkillInvoke(player, self:objectName(),
                    sgs.QVariant("@ping_shou_pindian:" .. effect.to:objectName())) then
                player:pindian(effect.to, self:objectName())
            end
        else
            local pindian = data:toPindian()
            if pindian.from:objectName() == player:objectName() and pindian.reason == self:objectName() then
                if pindian.from_number == pindian.to_number then
                    room:drawCards(pindian.from, 1, self:objectName())
                    room:drawCards(pindian.to, 1, self:objectName())
                elseif pindian.from_number > pindian.to_number then
                    room:drawCards(pindian.to, 1, self:objectName())
                else
                    room:drawCards(pindian.from, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
YurinaHirate:addSkill(sakamichi_ping_shou)

sakamichi_ji_shang = sgs.CreateTriggerSkill {
    name = "sakamichi_ji_shang",
    frequency = sgs.Skill_Wake,
    waked_skills = "sakamichi_tuo_tui",
    events = {sgs.CardsMoveOneTime},
    can_wake = function(self, event, player, data, room)
        if player:getMark(self:objectName()) ~= 0 then
            return false
        end
        if player:canWake(self:objectName()) then
            return true
        end
        if player:getPile("shang"):length() >= 6 then
            return true
        end
        return false
    end,
    on_trigger = function(self, event, player, data, room)
        room:gainMaxHp(player, SKMC.number_correction(player, 1))
        room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
        local lord_skill = {}
        for _, skill in sgs.qlist(player:getVisibleSkillList()) do
            if skill:isLordSkill() and player:hasLordSkill(skill:objectName()) then
                table.insert(lord_skill, "-" .. skill:objectName())
            end
        end
        room:handleAcquireDetachSkills(player, table.concat(lord_skill, "|"))
        room:handleAcquireDetachSkills(player, "sakamichi_tuo_tui")
        room:setPlayerProperty(player, "kingdom", sgs.QVariant("AutisticGroup"))
        room:addPlayerMark(player, self:objectName())
        return false
    end,
}
sakamichi_ji_shang_record = sgs.CreateTriggerSkill {
    name = "#sakamichi_ji_shang_record",
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if player:hasSkill("sakamichi_ji_shang") and player:getMark("sakamichi_ji_shang") == 0 then
            local damage = data:toDamage()
            if damage.card and not damage.card:isKindOf("SkillCard") then
                local ids = sgs.IntList()
                if damage.card:isVirtualCard() then
                    ids = damage.card:getSubcards()
                else
                    ids:append(damage.card:getEffectiveId())
                end
                if ids:length() > 0 then
                    local all_place_placetable = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
                            all_place_placetable = false
                            break
                        end
                    end
                    if all_place_placetable then
                        local not_include = true
                        for _, id in sgs.qlist(player:getPile("shang")) do
                            if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(damage.card) then
                                not_include = false
                                break
                            end
                        end
                        if not_include then
                            player:addToPile("shang", damage.card)
                        end
                    end
                end
            end
        end
        return false
    end,
}
YurinaHirate:addSkill(sakamichi_ji_shang)
if not sgs.Sanguosha:getSkill("#sakamichi_ji_shang_record") then
    SKMC.SkillList:append(sakamichi_ji_shang_record)
end

sakamichi_tuo_tui = sgs.CreateTriggerSkill {
    name = "sakamichi_tuo_tui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.CardUsed then
            for _, id in sgs.qlist(player:getPile("shang")) do
                if SKMC.true_name(sgs.Sanguosha:getCard(id)) == SKMC.true_name(use.card) then
                    local no_respond_list = use.no_respond_list
                    table.insert(no_respond_list, "_ALL_TARGETS")
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                    break
                end
            end
        else
            for _, p in sgs.qlist(use.to) do
                if p:getKingdom() == "Keyakizaka46" or p:getKingdom() == "Sakurazaka46" then
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_tuo_tui") then
    SKMC.SkillList:append(sakamichi_tuo_tui)
end

sgs.LoadTranslationTable {
    ["YurinaHirate"] = "?????? ?????????",
    ["&YurinaHirate"] = "?????? ?????????",
    ["#YurinaHirate"] = "??????",
    ["~YurinaHirate"] = "????????????????????????????????????????????????????????????",
    ["designer:YurinaHirate"] = "Cassimolar",
    ["cv:YurinaHirate"] = "?????? ?????????",
    ["illustrator:YurinaHirate"] = "Cassimolar",
    ["sakamichi_hei_yang"] = "??????",
    [":sakamichi_hei_yang"] = "??????????????????46???????????????46???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1????????????",
    ["sakamichi_ping_shou"] = "??????",
    [":sakamichi_ping_shou"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["@ping_shou_invoke"] = "????????????????????????????????????????????????????????????%src?????????????????????%arg",
    ["sakamichi_ping_shou:@ping_shou_pindian"] = "????????????%src??????",
    ["sakamichi_ji_shang"] = "??????",
    [":sakamichi_ji_shang"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????1????????????????????????1???????????????????????????????????????????????????????????????????????????????????????",
    ["shang"] = "???",
    ["sakamichi_tuo_tui"] = "??????",
    [":sakamichi_tuo_tui"] = "??????????????????????????????????????????????????????????????????????????????????????????????????????46?????????46???????????????????????????????????????",
}
