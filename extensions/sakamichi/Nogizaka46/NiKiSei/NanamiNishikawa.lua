require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NanamiNishikawa = sgs.General(Sakamichi, "NanamiNishikawa", "Nogizaka46", 4, false)
SKMC.NiKiSei.NanamiNishikawa = true
SKMC.SeiMeiHanDan.NanamiNishikawa = {
    name = {6, 3, 2, 9},
    ten_kaku = {9, "xiong"},
    jin_kaku = {5, "ji"},
    ji_kaku = {11, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {20, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "tu",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakamichi_chong_jing_card = sgs.CreateSkillCard {
    name = "sakamichi_chong_jingCard",
    skill_name = "sakamichi_chong_jing",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        room:drawCards(source, 4, self:getSkillName())
        local general_names = {}
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not table.contains(general_names, p:getGeneralName()) then
                table.insert(general_names, p:getGeneralName())
            end
            if not table.contains(general_names, p:getGeneral2Name()) then
                table.insert(general_names, p:getGeneral2Name())
            end
        end
        local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
        local chongjing_generals = {}
        for _, name in ipairs(all_generals) do
            local general = sgs.Sanguosha:getGeneral(name)
            if general:getKingdom() == "Nogizaka46" then
                if not table.contains(general_names, name) then
                    table.insert(chongjing_generals, name)
                end
            end
        end
        local general = room:askForGeneral(source, table.concat(chongjing_generals, "+"))
        source:setTag("newgeneral", sgs.QVariant(general))
        local is_secondary_hero = not sgs.Sanguosha:getGeneral(source:getGeneralName()):hasSkill(self:getSkillName())
        if is_secondary_hero then
            source:setTag("originalGeneral", sgs.QVariant(source:getGeneral2Name()))
        else
            source:setTag("originalGeneral", sgs.QVariant(source:getGeneralName()))
        end
        room:changeHero(source, general, false, false, is_secondary_hero)
        room:setPlayerFlag(source, self:getSkillName())
        room:acquireSkill(source, self:getSkillName(), false)
    end,
}
sakamichi_chong_jing_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_chong_jing",
    view_as = function()
        return sakamichi_chong_jing_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag(self:objectName())
    end,
}
sakamichi_chong_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_chong_jing",
    events = {sgs.EventPhaseChanging},
    view_as_skill = sakamichi_chong_jing_view_as,
    on_trigger = function(self, event, player, data, room)
        if data:toPhaseChange().to == sgs.Player_NotActive then
            if player:hasFlag(self:objectName()) then
                local is_secondary_hero = player:getGeneralName() ~= player:getTag("newgeneral"):toString()
                room:changeHero(player, player:getTag("originalGeneral"):toString(), false, false, is_secondary_hero)
                room:killPlayer(player)
            end
        end
        return false
    end,
}
NanamiNishikawa:addSkill(sakamichi_chong_jing)

sakamichi_ba_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_ba_qi",
    events = {sgs.Death, sgs.AskForPeachesDone},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Death then
            local death = data:toDeath()
            local alives = room:getAlivePlayers()
            if player:objectName() == death.who:objectName() and player:hasSkill(self) then
                if not alives:isEmpty() then
                    local target = room:askForPlayerChosen(player, alives, self:objectName(), "@ba_qi_invoke", true,
                        true)
                    if target then
                        local ai_data = sgs.QVariant()
                        ai_data:setValue(target)
                        local choice = room:askForChoice(player, self:objectName(), "draw+throw", ai_data)
                        if choice == "draw" then
                            room:drawCards(target, 3, self:objectName())
                        else
                            local count = math.min(3, target:getCardCount(true))
                            room:askForDiscard(target, self:objectName(), count, count, false, true)
                        end
                    end
                end
            end
            return
        else
            local dying = data:toDying()
            if player:getHp() <= 0 and dying.damage and dying.damage.from and player:hasSkill(self) then
                dying.damage.from = player
                room:killPlayer(player, dying.damage)
                room:setTag("SkipGameRule", sgs.QVariant(true))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
NanamiNishikawa:addSkill(sakamichi_ba_qi)

sakamichi_ni_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_ni_jing",
    events = {sgs.Damage},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.to:objectName() ~= player:objectName() and player:canPindian(damage.to)
            and room:askForSkillInvoke(player, self:objectName(), data) then
            local success = player:pindian(damage.to, self:objectName(), nil)
            if success then
                room:recover(player, sgs.RecoverStruct(damage.to))
                room:loseHp(damage.to)
            else
                room:recover(damage.to, sgs.RecoverStruct(player))
                room:loseHp(player)
            end
            return false
        end
    end,
}
NanamiNishikawa:addSkill(sakamichi_ni_jing)

sgs.LoadTranslationTable {
    ["NanamiNishikawa"] = "西川 七海",
    ["&NanamiNishikawa"] = "西川 七海",
    ["#NanamiNishikawa"] = "背负过去",
    ["~NanamiNishikawa"] = "",
    ["designer:NanamiNishikawa"] = "Cassimolar",
    ["cv:NanamiNishikawa"] = "西川 七海",
    ["illustrator:NanamiNishikawa"] = "Cassimolar",
    ["sakamichi_chong_jing"] = "憧憬",
    [":sakamichi_chong_jing"] = "出牌阶段，你可以摸四张牌并变身为未上场或已阵亡的乃木坂46势力角色，本回合结束后你死亡。",
    ["sakamichi_ba_qi"] = "八期",
    [":sakamichi_ba_qi"] = "当你死亡时，你可以令一名角色摸三张牌或弃三张牌。锁定技，你死亡时，凶手视为自己。",
    ["@ba_qi_invoke"] = "你可以选择一名角色令其摸三张牌或弃置三张牌",
    ["sakamichi_ni_jing"] = "逆境",
    [":sakamichi_ni_jing"] = "当你对其他角色造成伤害后，你可以与其拼点，若你赢，你回复1点体力其失去1点体力；没赢，你失去1点体力其回复1点体力。",
}
