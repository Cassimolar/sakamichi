require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkihoOnuma_Sakurazaka = sgs.General(Sakamichi, "AkihoOnuma_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.NiKiSei.AkihoOnuma_Sakurazaka = true
SKMC.SeiMeiHanDan.AkihoOnuma_Sakurazaka = {
    name = {3, 8, 12, 9},
    ten_kaku = {11, "ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_qian_qing = sgs.CreateTriggerSkill {
    name = "sakamichi_qian_qing",
    frequency = sgs.Skill_Compulsory,
    hide_skill = true,
    events = {sgs.Appear},
    on_trigger = function(self, event, player, data, room)
        room:swapSeat(player, room:getCurrent():getNextAlive())
    end,
}
AkihoOnuma_Sakurazaka:addSkill(sakamichi_qian_qing)

sakamichi_zhao_qu = sgs.CreateTriggerSkill {
    name = "sakamichi_zhao_qu",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
                local m = use.card:getNumber()
                if player:getMark("&zhao_qu_play_end_clear") ~= 0 then
                    local n = player:getMark("&zhao_qu_play_end_clear")
                    if m > n then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            room:drawCards(player, 1, self:objectName())
                        end
                    end
                    if m - n == SKMC.number_correction(player, 1) then
                        room:drawCards(player, 1, self:objectName())
                    else
                        room:setPlayerMark(player, "&zhao_qu_play_end_clear", m)
                    end
                else
                    room:setPlayerMark(player, "&zhao_qu_play_end_clear", m)
                end
            end
        end
        return false
    end,
}
AkihoOnuma_Sakurazaka:addSkill(sakamichi_zhao_qu)

sakamichi_bi_ya = sgs.CreateTriggerSkill {
    name = "sakamichi_bi_ya",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isNDTrick() then
            local ids = sgs.IntList()
            if use.card:isVirtualCard() then
                ids = use.card:getSubcards()
            else
                ids:append(use.card:getEffectiveId())
            end
            if not ids:isEmpty() then
                local all_place_discard = true
                for _, id in sgs.qlist(ids) do
                    if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                        all_place_discard = false
                        break
                    end
                end
                if all_place_discard then
                    player:addToPile("bi_ya", ids)
                end
            end
        end
        return false
    end,
}
AkihoOnuma_Sakurazaka:addSkill(sakamichi_bi_ya)

sgs.LoadTranslationTable {
    ["AkihoOnuma_Sakurazaka"] = "大沼 晶保",
    ["&AkihoOnuma_Sakurazaka"] = "大沼 晶保",
    ["#AkihoOnuma_Sakurazaka"] = "大不思议",
    ["~AkihoOnuma_Sakurazaka"] = "無事ですか？無事ですか？",
    ["designer:AkihoOnuma_Sakurazaka"] = "Cassimolar",
    ["cv:AkihoOnuma_Sakurazaka"] = "大沼 晶保",
    ["illustrator:AkihoOnuma_Sakurazaka"] = "Cassimolar",
    ["sakamichi_qian_qing"] = "前倾",
    [":sakamichi_qian_qing"] = "隐匿技，锁定技，当你登场时，你与当前回合角色的下家交换座位。",
    ["sakamichi_zhao_qu"] = "沼曲",
    [":sakamichi_zhao_qu"] = "出牌阶段，当你本阶段使用非第一张牌时，若此牌的点数大于本阶段使用的上一张牌，你可以摸一张牌，若这两张牌点数差仅为1，你摸一张牌并令此牌不计入此技能下次结算。",
    ["zhao_qu"] = "沼曲",
    ["sakamichi_bi_ya"] = "笔压",
    [":sakamichi_bi_ya"] = "锁定技，出牌阶段，你使用的通常锦囊牌结算完成时，若此牌有对应实体牌，你将此牌对应的实体牌置于你的武将牌上，视为移出游戏。",
    ["bi_ya"] = "笔压",
}
