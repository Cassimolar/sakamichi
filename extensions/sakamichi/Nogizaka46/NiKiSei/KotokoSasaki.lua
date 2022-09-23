require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KotokoSasaki = sgs.General(Sakamichi, "KotokoSasaki", "Nogizaka46", 4, false)
SKMC.NiKiSei.KotokoSasaki = true
SKMC.SeiMeiHanDan.KotokoSasaki = {
    name = {7, 3, 4, 12, 3},
    ten_kaku = {14, "xiong"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {29, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_bing_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_bing_yan",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Predamage, sgs.DamageForseen, sgs.PreHpLost},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Predamage then
            local damage = data:toDamage()
            local current = room:getCurrent()
            if current:hasSkill(self) or player:hasSkill(self) or damage.to:hasSkill(self) then
                local from
                if current:hasSkill(self) then
                    from = current
                elseif player:hasSkill(self) then
                    from = player
                else
                    from = damage.to
                end
                SKMC.send_message(room, "#bing_yan", from, nil, nil, nil, self:objectName(), damage.damage)
                room:loseHp(damage.to, damage.damage)
                return true
            end
        elseif event == sgs.DamageForseen then
            local damage = data:toDamage()
            if not damage.from then
                local current = room:getCurrent()
                if current:hasSkill(self) then
                    SKMC.send_message(room, "#bing_yan", current, nil, nil, nil, self:objectName(), damage.damage)
                    room:loseHp(damage.to, damage.damage)
                    return true
                end
            end
        elseif event == sgs.PreHpLost then
            if player:hasSkill(self) and player:getPhase() ~= sgs.Player_NotActive then
                SKMC.send_message(room, "#bing_yan_protect", player, nil, nil, nil, self:objectName())
                room:setEmotion(player, "skill_nullify")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KotokoSasaki:addSkill(sakamichi_bing_yan)

sakamichi_sheng_you_card = sgs.CreateSkillCard {
    name = "sakamichi_sheng_youCard",
    skill_name = "sakamichi_sheng_you",
    filter = function(self, targets, to_select)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:deleteLater()
        local plist = sgs.PlayerList()
        for i = 1, #targets, 1 do
            plist:append(targets[i])
        end
        return slash:targetFilter(plist, to_select, sgs.Self) and sgs.Self:canSlash(to_select, slash, true)
    end,
    on_validate = function(self, cardUse)
        cardUse.m_isOwnerUse = false
        local player = cardUse.from
        local room = player:getRoom()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:getSkillName())) do
            if p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:getSkillName(), sgs.QVariant(
                "invoke:" .. player:objectName() .. "::" .. SKMC.number_correction(p, 1) .. ":" .. "slash")) then
                room:loseHp(p)
                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                slash:setSkillName(self:getSkillName())
                slash:deleteLater()
                return slash
            end
        end
        room:setPlayerFlag(player, "sheng_you_failed")
        return nil
    end,
}
sakamichi_sheng_you_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sheng_you_view_as&",
    view_as = function()
        return sakamichi_sheng_you_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("sheng_you_failed") and sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason()
                   == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and not player:hasFlag("sheng_you_failed")
    end,
}
sakamichi_sheng_you = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_you",
    events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.CardAsked},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
            if player:hasSkill(self) then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if not p:hasSkill("sakamichi_sheng_you_view_as") then
                        room:attachSkillToPlayer(p, "sakamichi_sheng_you_view_as")
                    end
                end
            end
        elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
            local no_one_has_this_skill = true
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:hasSkill(self) then
                    no_one_has_this_skill = false
                    break
                end
            end
            if no_one_has_this_skill then
                for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:hasSkill("sakamichi_sheng_you_view_as") then
                        room:detachSkillFromPlayer(p, self:objectName(), true)
                    end
                end
            end
        elseif event == sgs.CardAsked then
            local pattern = data:toStringList()[1]
            local prompt = data:toStringList()[2]
            if pattern == "jink" and not string.find(prompt, "@sheng_you_jink") then
                local to_help = sgs.QVariant()
                to_help:setValue(player)
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                                "invoke:" .. player:objectName() .. "::" .. SKMC.number_correction(p, 1) .. ":" .. "jink")) then
                                room:loseHp(p)
                                local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
                                jink:deleteLater()
                                jink:setSkillName(self:objectName())
                                room:provide(jink)
                                return true
                            end
                        end
                    end
                end
            end
            if pattern == "slash" and not string.find(prompt, "@sheng_you_slash") then
                local to_help = sgs.QVariant()
                to_help:setValue(player)
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() then
                        if room:askForSkillInvoke(player, self:objectName(), data) then
                            if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                                "invoke:" .. player:objectName() .. "::" .. SKMC.number_correction(p, 1) .. ":"
                                    .. "slash")) then
                                room:loseHp(p)
                                local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                                slash:setSkillName(self:objectName())
                                slash:deleteLater()
                                room:provide(slash)
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
KotokoSasaki:addSkill(sakamichi_sheng_you)
if not sgs.Sanguosha:getSkill("sakamichi_sheng_you_view_as") then
    SKMC.SkillList:append(sakamichi_sheng_you_view_as)
end

sgs.LoadTranslationTable {
    ["KotokoSasaki"] = "佐々木 琴子",
    ["&KotokoSasaki"] = "佐々木 琴子",
    ["#KotokoSasaki"] = "古风美人",
    ["~KotokoSasaki"] = "もう、欲しがりやさんね♪",
    ["designer:KotokoSasaki"] = "Cassimolar",
    ["cv:KotokoSasaki"] = "佐々木 琴子",
    ["illustrator:KotokoSasaki"] = "Cassimolar",
    ["sakamichi_bing_yan"] = "冰颜",
    [":sakamichi_bing_yan"] = "锁定技，你造成或受到伤害均视为体力流失。你的回合内所有伤害均视为体力流失。你的回合内防止你的体力流失。",
    ["#bing_yan"] = "%from 的【%arg】被触发，此次%arg2点伤害视为体力流失",
    ["#bing_yan_protect"] = "%from 的【%arg】被触发，防止此次体力流失",
    ["sakamichi_sheng_you"] = "声优",
    [":sakamichi_sheng_you"] = "其他角色需要使用或打出【杀】／【闪】时，你可以失去1点体力视为其使用或打出了一张【杀】／【闪】。",
    ["sakamichi_sheng_you:invoke"] = "你可以失去%arg点体力为%src 提供一张【%arg2】",
    ["sakamichi_sheng_you_view_as"] = "声优",
    [":sakamichi_sheng_you_view_as"] = "当你需要使用或打出一张【杀】时，【声优】拥有者可以失去1点体力视为你使用或打出一张【杀】",
}
