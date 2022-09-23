require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MayuHarada = sgs.General(Sakamichi, "MayuHarada", "Keyakizaka46", 4, false)
SKMC.IKiSei.MayuHarada = true
SKMC.SeiMeiHanDan.MayuHarada = {
    name = {10, 5, 4, 3},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {9, "xiong"},
    ji_kaku = {7, "ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {22, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "shui",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_shi_shengCard = sgs.CreateSkillCard {
    name = "sakamichi_shi_shengCard",
    skill_name = "sakamichi_shi_sheng",
    filter = function(self, targets, to_select)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:deleteLater()
        local _targets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            _targets:append(p)
        end
        return slash:targetFilter(_targets, to_select, sgs.Self)
    end,
    on_validate = function(self, carduse)
        carduse.m_isOwnerUse = false
        local room = carduse.from:getRoom()
        local shi = nil
        for _, p in sgs.qlist(room:getOtherPlayers(carduse.from)) do
            if p:getMark("shi_sheng_" .. p:objectName() .. carduse.from:objectName()) ~= 0
                and carduse.from:getMark("shi_sheng_" .. p:objectName() .. carduse.from:objectName()) ~= 0 then
                shi = p
            end
        end
        if shi then
            local slash = room:askForCard(shi, "slash", "@shi_sheng_slash:" .. carduse.from:objectName(),
                sgs.QVariant(), sgs.Card_MethodResponse, nil, false, "", true)
            if slash then
                return slash
            end
        end
        room:setPlayerFlag(shi, "Global_Shi_Sheng_Failed")
        return nil
    end,
}
sakamichi_shi_sheng_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_shi_sheng",
    view_as = function(self, cards)
        return sakamichi_shi_shengCard:clone()
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player) and not player:hasFlag("Global_Shi_Sheng_Failed")
    end,
    enabled_at_response = function(self, player, pattern)
        return
            string.find(pattern, "slash") or string.find(pattern, "Slash") and sgs.Sanguosha:getCurrentCardUseReason()
                == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and not player:hasFlag("Global_Shi_Sheng_Failed")
    end,
}
sakamichi_shi_sheng = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_sheng",
    view_as_skill = sakamichi_shi_sheng_view_as,
    events = {sgs.GameStart, sgs.CardAsked},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart and player:hasSkill(self) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@shi_sheng_choice", false, false)
            room:setPlayerMark(player, "shi_sheng_" .. target:objectName() .. player:objectName(), 1)
            room:setPlayerMark(player, "&" .. self:objectName() .. "+ +" .. target:getGeneralName(), 1)
        elseif event == sgs.CardAsked then
            local pattern = data:toStringList()[1]
            if (string.find(pattern, "slash") or string.find(pattern, "Slash")) and player:hasSkill(self) then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if player:getMark("shi_sheng_" .. p:objectName() .. player:objectName()) ~= 0 then
                        if room:askForSkillInvoke(player, self:objectName(),
                            sgs.QVariant("@shi_sheng_slash:" .. p:objectName())) then
                            local slash = room:askForCard(p, "slash", "@shi_sheng_slash:" .. player:objectName(), data,
                                sgs.Card_MethodResponse, nil, false, "", true)
                            if slash then
                                room:provide(slash)
                                return true
                            end
                        end
                    end
                end
            elseif pattern == "jink" then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("shi_sheng_" .. player:objectName() .. p:objectName()) ~= 0 then
                        if room:askForSkillInvoke(player, self:objectName(),
                            sgs.QVariant("@shi_sheng_jink:" .. p:objectName())) then
                            local jink = room:askForCard(p, "jink", "@shi_sheng_jink:" .. player:objectName(), data,
                                sgs.Card_MethodResponse, nil, false, "", true)
                            if jink then
                                room:provide(jink)
                                return true
                            end
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
MayuHarada:addSkill(sakamichi_shi_sheng)

sakamichi_bu_ya = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_ya",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local death = data:toDeath()
        if death.who:objectName() == player:objectName() then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if (player:getMark("shi_sheng_" .. p:objectName() .. player:objectName()) ~= 0 and player:hasSkill(self))
                    or (p:getMark("shi_sheng_" .. player:objectName() .. p:objectName()) ~= 0 and p:hasSkill(self)) then
                    p:throwAllHandCardsAndEquips()
                    p:turnOver()
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MayuHarada:addSkill(sakamichi_bu_ya)

sgs.LoadTranslationTable {
    ["MayuHarada"] = "原田 まゆ",
    ["&MayuHarada"] = "原田 まゆ",
    ["#MayuHarada"] = "不老不死",
    ["~MayuHarada"] = "",
    ["designer:MayuHarada"] = "Cassimolar",
    ["cv:MayuHarada"] = "原田 まゆ",
    ["illustrator:MayuHarada"] = "Cassimolar",
    ["sakamichi_shi_sheng"] = "师生",
    [":sakamichi_shi_sheng"] = "游戏开始时，你须选择一名其他角色成为你的老师；本局游戏内，你需要使用或打出【杀】时，其可以打出一张【杀】视为由你使用或打出；其需要使用或打出【闪】时，你可以打出一张【闪】视为其使用或打出。",
    ["@shi_sheng_choice"] = "请选择一名其他角色成为你的老师",
    ["sakamichi_shi_sheng:@shi_sheng_slash"] = "是否令%src为你提供一张【杀】",
    ["@shi_sheng_slash"] = "请打出一张【杀】视为由%src使用或打出",
    ["sakamichi_shi_sheng:@shi_sheng_jink"] = "是否令%src为你提供一张【闪】",
    ["@shi_sheng_jink"] = "请打出一张【闪】视为由%src使用或打出",
    ["sakamichi_bu_ya"] = "不雅",
    [":sakamichi_bu_ya"] = "锁定技，你或你的老师死亡时，另一名角色须弃置所有牌并翻面。",
}
