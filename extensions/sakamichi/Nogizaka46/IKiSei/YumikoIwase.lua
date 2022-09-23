require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YumikoIwase = sgs.General(Sakamichi, "YumikoIwase", "Nogizaka46", 3, false)
SKMC.IKiSei.YumikoIwase = true
SKMC.SeiMeiHanDan.YumikoIwase = {
    name = {6, 19, 7, 9, 3},
    ten_kaku = {27, "ji_xiong_hun_he"},
    jin_kaku = {26, "xiong"},
    ji_kaku = {19, "xiong"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {46, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_da_jie = sgs.CreateTriggerSkill {
    name = "sakamichi_da_jie",
    events = {sgs.EventPhaseStart, sgs.MaxHpChanged},
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local max = 0
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMaxHp() > max then
                    max = p:getMaxHp()
                end
            end
            if player:getMaxHp() ~= max then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:gainMaxHp(player, SKMC.number_correction(player, 1))
                end
            else
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                        "@da_jie_choice:::" .. SKMC.number_correction(player, 1), true)
                    if target then
                        room:recover(target, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                    end
                end
            end
        elseif event == sgs.MaxHpChanged then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:drawCards(player, 1, self:objectName())
                room:askForUseCard(player, "slash", "@askforslash")
            end
        end
        return false
    end,
}
YumikoIwase:addSkill(sakamichi_da_jie)

sakamichi_dian_wan = sgs.CreateTriggerSkill {
    name = "sakamichi_dian_wan",
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EnterDying then
            local dying = data:toDying()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:isAlive() and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                    "invoke:" .. dying.who:objectName() .. "::" .. SKMC.number_correction(p, 1))) then
                    room:loseMaxHp(p, SKMC.number_correction(p, 1))
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, SKMC.number_correction(p, 1)))
                    room:drawCards(dying.who, 1, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoIwase:addSkill(sakamichi_dian_wan)

sakamichi_yue_tuan = sgs.CreateTriggerSkill {
    name = "sakamichi_yue_tuan",
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) and player:getMark("yue_tuan_used")
            == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:isAlive() and p:canDiscard(p, "h") then
                    if room:askForDiscard(p, self:objectName(), 1, 1, true, false, "@yue_tuan_invoke:"
                        .. player:objectName() .. "::" .. SKMC.number_correction(p, 1)) then
                        room:loseMaxHp(p, SKMC.number_correction(p, 1))
                        room:setPlayerMark(player, "yue_tuan", 1)
                        room:setPlayerMark(player, "yue_tuan" .. p:objectName(), 1)
                        room:setPlayerMark(player, "yue_tuan_used", 1)
                        player:skip(sgs.Player_Play)
                        break
                    end
                end
            end
        elseif change.to == sgs.Player_Discard then
            if player:getMark("yue_tuan") ~= 0 then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:getMark("yue_tuan" .. p:objectName()) ~= 0 then
                        room:drawCards(player, 2, self:objectName())
                        if player:isWounded() then
                            room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                        end
                        room:setPlayerMark(player, "yue_tuan" .. p:objectName(), 0)
                    end
                end
                room:setPlayerMark(player, "yue_tuan", 0)
                player:skip(sgs.Player_Discard)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YumikoIwase:addSkill(sakamichi_yue_tuan)

sgs.LoadTranslationTable {
    ["YumikoIwase"] = "岩瀬 佑美子",
    ["&YumikoIwase"] = "岩瀬 佑美子",
    ["#YumikoIwase"] = "歐巴桑",
    ["~YumikoIwase"] = "もうBBAなんて呼ばせねーからな！！",
    ["designer:YumikoIwase"] = "Cassimolar",
    ["cv:YumikoIwase"] = "岩瀬 佑美子",
    ["illustrator:YumikoIwase"] = "Cassimolar",
    ["sakamichi_da_jie"] = "大姐",
    [":sakamichi_da_jie"] = "准备阶段，若你的体力上限不为全场最多，你可以增加1点体力上限；若你的体力上限为全场最多，你可以令一名角色回复1点体力。你的体力上限变化后，你可以摸一张牌并可以使用一张【杀】。",
    ["@da_jie_choice"] = "你可以选择一名其他角色令其回复%arg点体力",
    ["sakamichi_dian_wan"] = "电玩",
    [":sakamichi_dian_wan"] = "当一名角色进入濒死时，你可以失去1点体力上限，然后令其回复1点体力并摸一张牌。",
    ["sakamichi_yue_tuan"] = "乐团",
    [":sakamichi_yue_tuan"] = "每名角色限一次，一名角色出牌阶段开始时，你可以弃置一张手牌并失去1点体力上限令其跳过出牌阶段，若如此做，其摸两张牌并回复1点体力然后跳过弃牌阶段。",
    ["@yue_tuan_invoke"] = "你可以弃置一张手牌并失去%arg点体力上限来跳过%src 的出牌阶段",
}
