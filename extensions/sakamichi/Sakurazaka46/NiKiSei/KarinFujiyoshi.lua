require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KarinFujiyoshi_Sakurazaka = sgs.General(Sakamichi, "KarinFujiyoshi_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.NiKiSei.KarinFujiyoshi_Sakurazaka = true
SKMC.SeiMeiHanDan.KarinFujiyoshi_Sakurazaka = {
    name = {18, 6, 10, 13},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {23, "ji"},
    soto_kaku = {31, "da_ji"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_fa_nu = sgs.CreateTriggerSkill {
    name = "sakamichi_fa_nu",
    hide_skill = true,
    events = {sgs.Appear},
    on_trigger = function(self, event, player, data, room)
        local current = room:getCurrent()
        if current:objectName() ~= player:objectName() and room:askForSkillInvoke(player, self:objectName(), data) then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            slash:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(slash, player, current))
            if current:getPhase() == sgs.Player_Play then
                current:endPlayPhase()
            end
        end
        return false
    end,
}
KarinFujiyoshi_Sakurazaka:addSkill(sakamichi_fa_nu)

sakamichi_xiao_zhuo = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_zhuo",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Analeptic") then
                local ids = sgs.IntList()
                if use.card:isVirtualCard() then
                    ids = use.card:getSubcards()
                else
                    ids:append(use.card:getEffectiveId())
                end
                if not ids:isEmpty() then
                    room:addPlayerMark(player, "xiao_zhuo", 1)
                end
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local n = player:getMark("xiao_zhuo")
            room:setPlayerMark(player, "xiao_zhuo", 0)
            if n ~= 0 then
                for i = 1, n, 1 do
                    local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
                    analeptic:deleteLater()
                    analeptic:setSkillName(self:objectName())
                    room:useCard(sgs.CardUseStruct(analeptic, player, player))
                end
            end
        end
        return false
    end,
}
KarinFujiyoshi_Sakurazaka:addSkill(sakamichi_xiao_zhuo)

sakamichi_tie_bi_trigger = sgs.CreateTriggerSkill {
    name = "#sakamichi_tie_bi_trigger",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardsMoveOneTime},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName() and player:hasSkill("sakamichi_tie_bi")
            and move.from_places:contains(sgs.Player_PlaceEquip) then
            local i = 0
            for _, card_id in sgs.qlist(move.card_ids) do
                if player:isAlive() and move.from_places:at(i) == sgs.Player_PlaceEquip
                    and sgs.Sanguosha:getCard(card_id):isKindOf("Armor") then
                    for _, mark in sgs.list(player:getMarkNames()) do
                        if string.find(mark, "&sakamichi_tie_bi+ +") and player:getMark(mark) ~= 0 then
                            room:setPlayerMark(player, mark, 0)
                        end
                    end
                    room:setPlayerMark(player, "&sakamichi_tie_bi+ +" .. sgs.Sanguosha:getCard(card_id):objectName(), 1)
                    i = i + 1
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
sakamichi_tie_bi = sgs.CreateViewAsEquipSkill {
    name = "sakamichi_tie_bi",
    view_as_equip = function(self, player)
        local armor = ""
        for _, mark in sgs.list(player:getMarkNames()) do
            if string.find(mark, "&tie_bi+ +") and player:getMark(mark) ~= 0 then
                armor = string.gsub(mark, "&" .. self:objectName() .. "+ +", "")
            end
        end
        return armor
    end,
}
if not sgs.Sanguosha:getSkill("#sakamichi_tie_bi_trigger") then
    SKMC.SkillList:append(sakamichi_tie_bi_trigger)
end
KarinFujiyoshi_Sakurazaka:addSkill(sakamichi_tie_bi)

sgs.LoadTranslationTable {
    ["KarinFujiyoshi_Sakurazaka"] = "藤吉 夏鈴",
    ["&KarinFujiyoshi_Sakurazaka"] = "藤吉 夏鈴",
    ["#KarinFujiyoshi_Sakurazaka"] = "独特灵气",
    ["~KarinFujiyoshi_Sakurazaka"] = "いいですね。",
    ["designer:KarinFujiyoshi_Sakurazaka"] = "Cassimolar",
    ["cv:KarinFujiyoshi_Sakurazaka"] = "藤吉 夏鈴",
    ["illustrator:KarinFujiyoshi_Sakurazaka"] = "Cassimolar",
    ["sakamichi_fa_nu"] = "发怒",
    [":sakamichi_fa_nu"] = "隐匿技，你于其他角色回合登场后，你可以视为对其使用一张【杀】，若当前阶段为出牌阶段，结束当前阶段。",
    ["sakamichi_xiao_zhuo"] = "小酌",
    [":sakamichi_xiao_zhuo"] = "当你使用一张有对应实体牌的【酒】后，下个准备阶段，你视为使用一张不计入次数的【酒】。",
    ["sakamichi_tie_bi"] = "铁壁",
    [":sakamichi_tie_bi"] = "锁定技，当你失去一张装备区的防具后，你视为装备该防具直到下一次失去装备区的防具。",
}
