require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NeruNagahama_HiraganaKeyakizaka = sgs.General(Sakamichi, "NeruNagahama_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
SKMC.IKiSei.NeruNagahama_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.NeruNagahama_HiraganaKeyakizaka = {
    name = {8, 17, 4, 3},
    ten_kaku = {25, "ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {7, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {31, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "xiong",
    },
}

sakamichi_te_li = sgs.CreateTriggerSkill {
    name = "sakamichi_te_li",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseProceeding, sgs.EventPhaseStart, sgs.Damage, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:hasSkill(self) then
                if player:getPhase() == sgs.Player_Start and player:getKingdom() == "Keyakizaka46" then
                    if not player:getJudgingArea():isEmpty() and room:askForSkillInvoke(player, self:objectName(), data) then
                        local id = room:askForCardChosen(player, player, "j", self:objectName())
                        local card = sgs.Sanguosha:getCard(id)
                        local target_list = sgs.SPlayerList()
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if not player:isProhibited(p, card) and not p:containsTrick(card:objectName())
                                and p:hasJudgeArea() then
                                target_list:append(p)
                            end
                        end
                        local target = room:askForPlayerChosen(player, target_list, self:objectName(),
                            "@te_li_1:::" .. card:objectName())
                        if target then
                            room:moveCardTo(card, player, target, sgs.Player_Judge, sgs.CardMoveReason(
                                sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), ""))
                        end
                    end
                end
                if player:getPhase() == sgs.Player_Finish and player:getKingdom() == "HiraganaKeyakizaka46" then
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                        "@te_li_2", true, true)
                    if target then
                        room:addPlayerMark(target, "te_li_armor_nullified", 1)
                        room:addPlayerMark(target, "Armor_Nullified", 1)
                    end
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:getMark("te_li_armor_nullified") ~= 0 then
                room:removePlayerMark(player, "Armor_Nullified", player:getMark("te_li_armor_nullified"))
                room:setPlayerMark(player, "te_li_armor_nullified", 0)
            end
        elseif event == sgs.Damage then
            if player:hasSkill(self) then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("Keyakizaka46"))
                local target_list = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if not p:isAllNude() then
                        target_list:append(p)
                    end
                end
                if not target_list:isEmpty() then
                    local target = room:askForPlayerChosen(player, target_list, self:objectName(), "@te_li_3", true,
                        true)
                    if target then
                        local id = room:askForCardChosen(player, target, "hej", self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(id, target, player)
                    end
                end
            end
        elseif event == sgs.Damaged then
            if player:hasSkill(self) then
                room:setPlayerProperty(player, "kingdom", sgs.QVariant("HiraganaKeyakizaka46"))
                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@te_li_4",
                    true, true)
                if target then
                    room:askForUseCard(target, "slash", "@askforslash")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NeruNagahama_HiraganaKeyakizaka:addSkill(sakamichi_te_li)

NeruNagahama_HiraganaKeyakizaka:addSkill("sakamichi_guan_tui")

sakamichi_zhuan_ren = sgs.CreateTriggerSkill {
    name = "sakamichi_zhuan_ren",
    frequency = sgs.Skill_Limited,
    limit_mark = "@zhuan_ren",
    events = {sgs.HpChanged},
    on_trigger = function(self, event, player, data, room)
        local recover = data:toRecover()
        if recover and not player:isWounded() and player:getMark("@zhuan_ren") ~= 0 then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:getKingdom() ~= p:getKingdom() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(),
                    "@zhuan_ren_invoke:::" .. recover.recover, true, true)
                if target then
                    player:loseMark("@zhuan_ren")
                    room:damage(sgs.DamageStruct(self:objectName(), player, target, recover.recover,
                        sgs.DamageStruct_Normal))
                    local is_secondary_hero = not (sgs.Sanguosha:getGeneral(player:getGeneralName()):hasSkill(self))
                    room:changeHero(player, "NeruNagahama_Keyakizaka", false, true, is_secondary_hero, true)
                    local EX = sgs.Sanguosha:getTriggerSkill("sakamichi_chi_dao")
                    EX:trigger(sgs.GameStart, room, player, sgs.QVariant())
                end
            end
        end
        return false
    end,
}
NeruNagahama_HiraganaKeyakizaka:addSkill(sakamichi_zhuan_ren)

sgs.LoadTranslationTable {
    ["NeruNagahama_HiraganaKeyakizaka"] = "長濱 ねる",
    ["&NeruNagahama_HiraganaKeyakizaka"] = "長濱 ねる",
    ["#NeruNagahama_HiraganaKeyakizaka"] = "坂蓝根",
    ["~NeruNagahama_HiraganaKeyakizaka"] = "噛めば噛むほど美味しい味が出てきて美味しいです",
    ["designer:NeruNagahama_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:NeruNagahama_HiraganaKeyakizaka"] = "長濱 ねる",
    ["illustrator:NeruNagahama_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_te_li"] = "特例",
    [":sakamichi_te_li"] = "准备阶段/结束阶段，若你的势力为欅坂46/けやき坂46，你可以移动你判定区的一张牌/令一名角色的防具无效直到其的回合开始。锁定技，当你造成/受到伤害后，将你的势力修改为欅坂46/けやき坂46，并可以弃置场上一张牌/令一名角色使用一张【杀】。",
    ["@te_li_1"] = "请选择移动此【%arg】的目标",
    ["@te_li_2"] = "你可以选择一名角色，令其在其回合开始前其防具无效",
    ["@te_li_3"] = "你可以选择一名角色弃置其一张牌",
    ["@te_li_4"] = "你可以选择一名角色令其可以使用一张【杀】",
    ["sakamichi_zhuan_ren"] = "专任",
    [":sakamichi_zhuan_ren"] = "限定技，当你回复体力后，若你的体力值已满，你可以对一名与你势力不同的角色造成等同于此次回复量的伤害，然后将你的武将牌替换为「等待百年 - 長濱ねる」。",
    ["@zhuan_ren"] = "专任",
    ["@zhuan_ren_invoke"] = "你可以发动【%arg】对一名势力与你不同的角色造成%arg点伤害，然后将武将牌替换为「等待百年 - 長濱ねる」",
}
