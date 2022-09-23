SKMC = {}

SKMC.SkillList = sgs.SkillList()

SKMC.IKiSei = {}
SKMC.NiKiSei = {}
SKMC.SanKiSei = {}
SKMC.YonKiSei = {}
SKMC.GoKiSei = {}

SKMC.SeiMeiHanDan = {}

SKMC.Pattern = {
    BasicCard = {},
    TrickCard = {},
    EquipCard = {},
}
SKMC.Pattern.BasicCard = {
    Slash = {},
}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("BasicCard") and not card:isKindOf("Slash") then
        if not table.contains(SKMC.Pattern.BasicCard, card:objectName()) then
            table.insert(SKMC.Pattern.BasicCard, card:objectName())
        end
    end
end
SKMC.Pattern.BasicCard.Slash = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Slash") then
        if not table.contains(SKMC.Pattern.BasicCard.Slash, card:objectName()) then
            table.insert(SKMC.Pattern.BasicCard.Slash, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard = {
    SingleTargetTrick = {},
    MultipleTargetTrick = {},
    DelayedTrick = {},
}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("TrickCard") and not card:isKindOf("SingleTargetTrick") and not card:isKindOf("GlobalEffect")
        and not card:isKindOf("AOE") and not card:isKindOf("IronChain") and not card:isKindOf("DelayedTrick") then
        if not table.contains(SKMC.Pattern.TrickCard, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard.SingleTargetTrick = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("SingleTargetTrick") then
        if not table.contains(SKMC.Pattern.TrickCard.SingleTargetTrick, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard.SingleTargetTrick, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard.MultipleTargetTrick = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("IronChain") and card:isKindOf("GlobalEffect") or card:isKindOf("AOE") then
        if not table.contains(SKMC.Pattern.TrickCard.MultipleTargetTrick, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard.MultipleTargetTrick, card:objectName())
        end
    end
end
SKMC.Pattern.TrickCard.DelayedTrick = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("DelayedTrick") then
        if not table.contains(SKMC.Pattern.TrickCard.DelayedTrick, card:objectName()) then
            table.insert(SKMC.Pattern.TrickCard.DelayedTrick, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard = {
    Weapon = {},
    Armor = {},
    OffensiveHorse = {},
    DefensiveHorse = {},
    Treasure = {},
}
SKMC.Pattern.EquipCard.Weapon = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Weapon") then
        if not table.contains(SKMC.Pattern.EquipCard.Weapon, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.Weapon, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.Armor = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Armor") then
        if not table.contains(SKMC.Pattern.EquipCard.Armor, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.Armor, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.OffensiveHorse = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("OffensiveHorse") then
        if not table.contains(SKMC.Pattern.EquipCard.OffensiveHorse, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.OffensiveHorse, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.DefensiveHorse = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("DefensiveHorse") then
        if not table.contains(SKMC.Pattern.EquipCard.DefensiveHorse, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.DefensiveHorse, card:objectName())
        end
    end
end
SKMC.Pattern.EquipCard.Treasure = {}
for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(false)) do
    local card = sgs.Sanguosha:getEngineCard(id)
    if card:isKindOf("Treasure") then
        if not table.contains(SKMC.Pattern.EquipCard.Treasure, card:objectName()) then
            table.insert(SKMC.Pattern.EquipCard.Treasure, card:objectName())
        end
    end
end

sgs.LoadTranslationTable {
    ["Slash"] = "杀",
    ["SingleTargetTrick"] = "单目标锦囊",
    ["MultipleTargetTrick"] = "多目标锦囊",
    ["DelayedTrick"] = "延时锦囊",
    ["Weapon"] = "武器",
    ["Armor"] = "防具",
    ["OffensiveHorse"] = "进攻马",
    ["DefensiveHorse"] = "防御马",
    ["Treasure"] = "宝物",
}

---@param table table
---@return sgs.IntList
function SKMC.table_to_IntList(table)
    local list = sgs.IntList()
    for i = 1, #table, 1 do
        list:append(table[i])
    end
    return list
end

---@param table table
---@return sgs.BoolList
function SKMC.table_to_BoolList(table)
    local list = sgs.BoolList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

---@param table table
---@return sgs.CardList
function SKMC.table_to_CardList(table)
    local list = sgs.CardList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

---@param table table
---@return sgs.PlayerList
function SKMC.table_to_PlayerList(table)
    local list = sgs.PlayerList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

---@param table table
---@return sgs.SPlayerList
function SKMC.table_to_SPlayerList(table)
    local list = sgs.SPlayerList()
    for _, e in ipairs(table) do
        list:append(e)
    end
    return list
end

---@param table table
---@param value any
---@return any
function SKMC.get_pos(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return 0
end

---@param list sgs.QList
---@return table
function SKMC.set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

---@param mode_name string
---@return boolean
function SKMC.is_normal_game_mode(mode_name)
    return mode_name:endsWith("p") or mode_name:endsWith("pd") or mode_name:endsWith("pz")
end

---@param player sgs.ServerPlayer
---@param tag string
---@param remove_table table
---@return table
function SKMC.get_available_generals(player, tag, remove_table)
    local all = sgs.Sanguosha:getLimitedGeneralNames()
    local room = player:getRoom()
    if (SKMC.is_normal_game_mode(room:getMode()) or room:getMode():find("_mini_") or room:getMode() == "custom_scenario") then
        table.removeTable(all, sgs.GetConfig("Banlist/Roles", ""):split(", "))
    elseif (room:getMode() == "04_1v3") then
        table.removeTable(all, sgs.GetConfig("Banlist/HulaoPass", ""):split(", "))
    elseif (room:getMode() == "06_XMode") then
        table.removeTable(all, sgs.GetConfig("Banlist/XMode", ""):split(", "))
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            table.removeTable(all, (p:getTag("XModeBackup"):toStringList()) or {})
        end
    elseif (room:getMode() == "02_1v1") then
        table.removeTable(all, sgs.GetConfig("Banlist/1v1", ""):split(", "))
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            table.removeTable(all, (p:getTag("1v1Arrange"):toStringList()) or {})
        end
    end
    if tag then
        local tag_remove = {}
        local tag_string = player:getTag(tag):toString()
        if tag_string and tag_string ~= "" then
            tag_remove = tag_string:split("+")
        end
        table.removeTable(all, tag_remove)
    end
    if remove_table then
        table.removeTable(all, remove_table)
    end
    for _, player in sgs.qlist(room:getAlivePlayers()) do
        local name = player:getGeneralName()
        if sgs.Sanguosha:isGeneralHidden(name) then
            local fname = sgs.Sanguosha:findConvertFrom(name);
            if fname ~= "" then
                name = fname
            end
        end
        table.removeOne(all, name)
        if not player:getGeneral2() == nil then
            name = player:getGeneral2Name()
        end
        if sgs.Sanguosha:isGeneralHidden(name) then
            local fname = sgs.Sanguosha:findConvertFrom(name);
            if fname ~= "" then
                name = fname
            end
        end
        table.removeOne(all, name)
    end
    return all
end

function SKMC.has_specific_kingdom_player(player, same, kingdom, except)
    local same_kingdom = true
    if same ~= nil then
        same_kingdom = same
    end
    local target_kingdom = player:getKingdom()
    if kingdom then
        target_kingdom = kingdom
    end
    for _, p in sgs.qlist(player:getSiblings()) do
        if p:isAlive() and p:objectName() ~= except then
            if same_kingdom then
                if p:getKingdom() == target_kingdom then
                    return true
                end
            else
                if p:getKingdom() ~= target_kingdom then
                    return true
                end
            end
        end
    end
    return false
end

---@param player sgs.Player
---@param ki_be_tsu number
---@return boolean
function SKMC.is_ki_be(player, ki_be_tsu)
    local ki_be
    if ki_be_tsu == 1 then
        ki_be = SKMC.IKiSei
    elseif ki_be_tsu == 2 then
        ki_be = SKMC.NiKiSei
    elseif ki_be_tsu == 3 then
        ki_be = SKMC.SanKiSei
    elseif ki_be_tsu == 4 then
        ki_be = SKMC.YonKiSei
    elseif ki_be_tsu == 5 then
        ki_be = SKMC.GoKiSei
    end
    return ki_be[player:getGeneralName()] or ki_be[player:getGeneral2Name()]
end

---@param qlist sgs.QList
---@param item any
---@return integer
function SKMC.list_index_of(qlist, item)
    local index = 0
    for _, i in sgs.qlist(qlist) do
        if i == item then
            return index
        end
        index = index + 1
    end
end

---@param card sgs.Card
---@return string
function SKMC.true_name(card)
    if card == nil then
        return ""
    end
    if card:objectName() == "fire_slash" or card:objectName() == "thunder_slash" or card:objectName() == "ice_slash" then
        return "slash"
    end
    return card:objectName()
end

function SKMC.send_message(room, msg_type, msg_from, msg_to, msg_tos, card_str, msg_arg, msg_arg2, msg_arg3, msg_arg4,
    msg_arg5)
    local msg = sgs.LogMessage()
    if msg_type then
        msg.type = msg_type
    end
    if msg_from then
        msg.from = msg_from
    end
    if msg_to then
        msg.to:append(msg_to)
    end
    if msg.tos then
        msg.to = msg_tos
    end
    if card_str then
        msg.card_str = card_str
    end
    if msg_arg then
        msg.arg = msg_arg
    end
    if msg_arg2 then
        msg.arg2 = msg_arg2
    end
    if msg_arg3 then
        msg.arg3 = msg_arg3
    end
    if msg_arg4 then
        msg.arg4 = msg_arg4
    end
    if msg_arg5 then
        msg.arg5 = msg_arg5
    end
    room:sendLog(msg)
end

function SKMC.run_judge(room, who, reason, pattern, good, negative, play_animation, time_consuming)
    local judge = sgs.JudgeStruct()
    judge.who = who
    judge.reason = reason
    judge.pattern = pattern
    if good ~= nil then
        judge.good = good
    else
        judge.good = true
    end
    if negative ~= nil then
        judge.negative = negative
    else
        judge.negative = false
    end
    if play_animation ~= nil then
        judge.play_animation = play_animation
    else
        judge.play_animation = true
    end
    if time_consuming ~= nil then
        judge.time_consuming = time_consuming
    else
        judge.time_consuming = false
    end
    room:judge(judge)
    local result = {}
    result.card = judge.card
    result.isGood = judge:isGood()
    result.isBad = judge:isBad()
    return result
end

---@param player sgs.Player
---@param number integer
---@return integer
function SKMC.number_correction(player, number)
    local n = (number + player:getMark("&number_correction_plus") - player:getMark("&number_correction_minus"))
                  * (1 + player:getMark("&number_correction_multiple"))
    if player:getMark("&number_correction_locking") < n then
        return n
    else
        return player:getMark("&number_correction_locking")
    end
end

sgs.LoadTranslationTable {
    ["number_correction_plus"] = "阿拉伯数字增加",
    ["number_correction_minus"] = "阿拉伯数字减少",
    ["number_correction_multiple"] = "阿拉伯数字翻倍",
    ["number_correction_locking"] = "阿拉伯数字锁定为",

    ["#number_correction_plus"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字加%arg2",
    ["#number_correction_minus"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字减%arg2",
    ["#number_correction_multiple"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字翻%arg2倍",
    ["#number_correction_locking"] = "%from 发动【%arg】令%to 武将牌上的阿拉伯数字锁定为%arg2",
}

---@param str string
---@return integer
function SKMC.get_string_word_number(str)
    if not str or type(str) ~= "string" or #str <= 0 then
        return nil
    end
    local len_in_byte = #str
    local count = 0
    local i = 1
    while true do
        local cur_byte = string.byte(str, i)
        if i > len_in_byte then
            break
        end
        local byte_count = 1
        if cur_byte > 0 and cur_byte < 128 then
            byte_count = 1
        elseif cur_byte >= 128 and cur_byte < 224 then
            byte_count = 2
        elseif cur_byte >= 224 and cur_byte < 240 then
            byte_count = 3
        elseif cur_byte >= 240 and cur_byte <= 247 then
            byte_count = 4
        else
            break
        end
        i = i + byte_count
        count = count + 1
    end
    return count
end

---@param player sgs.Player
---@param choice string
function SKMC.choice_log(player, choice)
    SKMC.send_message(player:getRoom(), "#choice", player, nil, nil, nil, choice)
end

sgs.LoadTranslationTable {
    ["#choice"] = "%from 选择了 %arg",
}

function SKMC.play_conversation(room, general_name, log, audio_type)
    if type(audio_type) ~= "string" then
        audio_type = "dun"
    end
    -- room:doAnimate(2, "skill=Conversation:" .. general_name, log)
    local thread = room:getThread()
    thread:delay(295)
    local i = SKMC.get_string_word_number(sgs.Sanguosha:translate(log))
    for a = 1, i do
        room:broadcastSkillInvoke(audio_type, "system")
        thread:delay(80)
    end
    thread:delay(1100)
end

---@param room sgs.Room
---@param victim sgs.Player
function SKMC.get_winner(room, victim)
    -- if not string.find(room:getMode(),"p") then return nil end
    local function contains(plist, role)
        for _, p in sgs.qlist(plist) do
            if p:getRoleEnum() == role then
                return true
            end
        end
        return false
    end
    local r = victim:getRoleEnum()
    local sp = room:getOtherPlayers(victim)
    if r == sgs.Player_Lord then
        if (sp:length() == 1 and sp:first():getRole() == "renegade") then
            return "renegade"
        else
            return "rebel"
        end
    else
        if not contains(sp, sgs.Player_Rebel) and not contains(sp, sgs.Player_Renegade) then
            return "lord+loyalist"
        else
            return nil
        end
    end
end

-- 用法：FakeMove(拥有pile的玩家, pile的名字, id列表，布尔值，技能名)
-- movein如果是true，则从外部置入pile，如果是false，则从pile置入弃牌堆
-- ids不能填单一个id，要先把id转化成id列表，例如local ids = sgs.IntList()，然后ids:append(id)，这个设计目的是让FakeMove可以一次假移动多张牌
-- FakeMove的pile不能通过getPile获取，因为这是个假的pile，所以程序猿需自行加记录，例如用tag或者property记录
function SKMC.fake_move(room, player, pile_name, id, movein, skill_name, targets)
    local ids = sgs.IntList()
    if type(id) == "number" then
        ids:append(id)
    else
        ids = id
    end
    local players = sgs.SPlayerList()
    if targets then
        players = targets
    else
        players = room:getAllPlayers(true)
    end
    if movein then
        local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), skill_name, ""))
        move.to_pile_name = pile_name
        local moves = sgs.CardsMoveList()
        moves:append(move)
        room:notifyMoveCards(true, moves, false, players)
        room:notifyMoveCards(false, moves, false, players)
    else
        local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
            sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), skill_name, ""))
        move.from_pile_name = pile_name
        local moves = sgs.CardsMoveList()
        moves:append(move)
        room:notifyMoveCards(true, moves, false, players)
        room:notifyMoveCards(false, moves, false, players)
    end
end

player_mark_clear = sgs.CreateTriggerSkill {
    name = "#player_mark_clear",
    events = {sgs.TurnStart, sgs.EventPhaseStart, sgs.EventPhaseEnd},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TurnStart then
            local n = 15
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                n = math.min(p:getSeat(), n)
            end
            if player:getSeat() == n and not room:getTag("ExtraTurn"):toBool() then
                if player:getMark("Global_TurnCount") == 0 then
                    room:broadcastSkillInvoke("gamestart", "system")
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        room:addPlayerMark(p, "mvpexp", 1)
                    end
                end
                room:setPlayerMark(player, "@clock_time", player:getMark("Global_TurnCount") + 1)
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    for _, mark in sgs.list(p:getMarkNames()) do
                        if string.find(mark, "_lun_clear") and p:getMark(mark) ~= 0 then
                            room:setPlayerMark(p, mark, 0)
                        end
                    end
                end
            end
        else
            for _, mark in sgs.list(player:getMarkNames()) do
                local event_start = string.find(mark, "_start_clear")
                local event_end = string.find(mark, "_end_clear")
                if (event_start and event == sgs.EventPhaseStart) or (event_end and event == sgs.EventPhaseEnd) then
                    local _mark
                    if event_start then
                        _mark = string.sub(mark, 1, event_start)
                    end
                    if event_end then
                        _mark = string.sub(mark, 1, event_end)
                    end
                    if string.find(_mark, player:getPhaseString()) then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("#player_mark_clear") then
    SKMC.SkillList:append(player_mark_clear)
end

sgs.LoadTranslationTable {
    ["_start_start_clear"] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}

sakamichi_armor = sgs.CreateTriggerSkill {
    name = "sakamichi_armor",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardAsked, sgs.SlashEffected, sgs.CardEffected, sgs.DamageInflicted, sgs.TargetConfirmed,
        sgs.PreHpLost},
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardAsked then
            local has_eight_diagram = false
            local skill_name = ""
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "eight_diagram") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_eight_diagram = true
                            skill_name = string.sub(mark, 2, string.find(mark, "+") - 1)
                        end
                    else
                        has_eight_diagram = true
                        skill_name = string.sub(mark, 2, string.find(mark, "+") - 1)
                    end
                end
            end
            if has_eight_diagram then
                local pattern = data:toStringList()[1]
                if pattern == "jink" then
                    if room:askForSkillInvoke(player, "eight_diagram", data) then
                        local result = SKMC.run_judge(room, player, skill_name, ".|red", true)
                        room:setEmotion(player, "armor/eight_diagram")
                        if result.isGood then
                            local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
                            jink:deleteLater()
                            jink:setSkillName(skill_name)
                            room:provide(jink)
                            return true
                        end
                    end
                end
            end
        elseif event == sgs.SlashEffected then
            local has_renwang_shield = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "renwang_shield") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_renwang_shield = true
                        end
                    else
                        has_renwang_shield = true
                    end
                end
            end
            if has_renwang_shield then
                local effect = data:toSlashEffect()
                if effect.slash:isBlack() then
                    room:setEmotion(player, "armor/renwang_shield")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "renwang_shield",
                        effect.slash:objectName())
                    return true
                end
            end
            local has_vine = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "vine") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_vine = true
                        end
                    else
                        has_vine = true
                    end
                end
            end
            if has_vine then
                local effect = data:toSlashEffect()
                if effect.nature == sgs.DamageStruct_Normal then
                    room:setEmotion(player, "armor/vine")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "vine", effect.slash:objectName())
                    room:setPlayerFlag(effect.to, "Global_NonSkillNullify")
                    return true
                end
            end
        elseif event == sgs.CardEffected then
            local has_vine = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "vine") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_vine = true
                        end
                    else
                        has_vine = true
                    end
                end
            end
            if has_vine then
                local effect = data:toCardEffect()
                if effect.card:isKindOf("AOE") then
                    room:setEmotion(player, "armor/vine")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "vine", effect.card:objectName())
                    room:setPlayerFlag(effect.to, "Global_NonSkillNullify")
                    return true
                end
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local has_vine = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "vine") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_vine = true
                        end
                    else
                        has_vine = true
                    end
                end
            end
            if has_vine then
                if damage.nature == sgs.DamageStruct_Fire then
                    room:setEmotion(player, "armor/vineburn")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, damage.damage, damage.damage + 1)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
            local has_silver_lion = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "silver_lion") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_silver_lion = true
                        end
                    else
                        has_silver_lion = true
                    end
                end
            end
            if has_silver_lion then
                room:setEmotion(player, "armor/silver_lion")
                SKMC.send_message(room, "SilverLion", player, nil, nil, nil, damage.damage, "silver_lion")
                damage.damage = 1
                data:setValue(damage)
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local has_heiguangkai = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "heiguangkai") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_heiguangkai = true
                        end
                    else
                        has_heiguangkai = true
                    end
                end
            end
            if has_heiguangkai then
                if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and use.to:contains(player) and use.to:length()
                    > 1 then
                    room:setEmotion(player, "armor/heiguangkai")
                    SKMC.send_message(room, "#ArmorNullify", player, nil, nil, nil, "heiguangkai", use.card:objectName())
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, player:objectName())
                    use.nullified_list = nullified_list
                    data:setValue(use)
                end
            end
        elseif event == sgs.PreHpLost then
            local has_seifuku_no_manekin = false
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "seifuku_no_manekin") and player:getMark(mark) > 0 then
                    if string.find(mark, "no_armor") then
                        if not player:getArmor() then
                            has_seifuku_no_manekin = true
                        end
                    else
                        has_seifuku_no_manekin = true
                    end
                end
            end
            if has_seifuku_no_manekin then
                room:setEmotion(player, "skill_nullify")
                SKMC.send_message(room, "#seifuku_no_manekinProtect", player, nil, nil, nil, "seifuku_no_manekin")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        if target and target:isAlive() and target:getMark("Armor_Nullified") == 0 and not target:hasFlag("WuqianTarget")
            and target:getMark("Equips_Nullified_to_Yourself") == 0 then
            local list = target:getTag("Qinggang"):toStringList()
            return #list == 0
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_armor") then
    SKMC.SkillList:append(sakamichi_armor)
end

sgs.LoadTranslationTable {
    ["noarmor"] = "无防具",
}

wu_jie_te_xiao = sgs.CreateTriggerSkill {
    name = "#wu_jie_te_xiao",
    events = {sgs.CardUsed, sgs.CardResponded},
    global = true,
    on_trigger = function(self, event, player, data, room)
        local card_star
        if event == sgs.CardUsed then
            card_star = data:toCardUse().card
        else
            card_star = data:toCardResponse().m_card
        end
        if card_star:isKindOf("EquipCard") then
            return
        end
        room:setEmotion(player, "wujie\\" .. card_star:objectName())
    end,
}
if not sgs.Sanguosha:getSkill("#wu_jie_te_xiao") then
    SKMC.SkillList:append(wu_jie_te_xiao)
end

trig = sgs.CreateTriggerSkill {
    name = "trig",
    global = true,
    events = {sgs.FinishJudge, sgs.GameOverJudge, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.FinishJudge then
            local judge = data:toJudge()
            if judge:isGood() then
                return
            end
            if judge.reason == "indulgence" then
                room:setEmotion(judge.who, "indulgence")
            elseif judge.reason == "supply_shortage" then
                room:setEmotion(judge.who, "supply_shortage")
            elseif judge.reason == "lightning" then
                room:setEmotion(judge.who, "lightning")
            end
        elseif event == sgs.GameOverJudge then
            local current = room:getCurrent()
            local x = current:getMark("havekilled")
            if room:getAllPlayers(true):length() - room:alivePlayerCount() == 1 then
                sgs.Sanguosha:playSystemAudioEffect("yipo")
            end
            if (x > 1) and (x < 8) then
                sgs.Sanguosha:playSystemAudioEffect("lianpo" .. x)
                room:setEmotion(current, "lianpo\\" .. x)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_NotActive then
                room:setPlayerMark(player, "havekilled", 0)
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerMark(p, "healed", 0)
                    room:setPlayerMark(p, "rescued", 0)
                end
            elseif player:getPhase() == sgs.Player_RoundStart then
                local jsonValue = {player:objectName(), "turnstart"}
                for _, p in sgs.qlist(room:getOtherPlayers(player, true)) do
                    room:doNotify(p, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
                end
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("trig") then
    SKMC.SkillList:append(trig)
end

mobile_effect = sgs.CreateTriggerSkill {
    name = "mobile_effect",
    global = true,
    events = {sgs.Damage, sgs.DamageComplete, sgs.EnterDying, sgs.GameOverJudge, sgs.HpRecover, sgs.QuitDying},
    priority = 9,
    on_trigger = function(self, event, player, data, room)
        local function damage_effect(n)
            if n == 3 then
                room:broadcastSkillInvoke(self:objectName(), 1)
                room:getThread():delay(3325)
            elseif n >= 4 then
                room:broadcastSkillInvoke(self:objectName(), 2)
                room:getThread():delay(4000)
            end
        end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:getMark("mobile_damage") == 0 then
                damage_effect(damage.damage)
            end
        elseif event == sgs.EnterDying then
            local damage = data:toDying().damage
            if damage and damage.from and damage.to:isAlive() then
                if damage.damage >= 3 then
                    damage_effect(damage.damage)
                    room:addPlayerMark(damage.from, "mobile_damage")
                end
            end
        elseif event == sgs.DamageComplete then
            local damage = data:toDamage()
            if damage.from then
                room:setPlayerMark(damage.from, "mobile_damage", 0)
            end
        elseif event == sgs.GameOverJudge then
            local current = room:getCurrent()
            room:addPlayerMark(current, "havekilled", 1)
            local x = current:getMark("havekilled")
            if not room:getTag("FirstBlood"):toBool() then
                room:setTag("FirstBlood", sgs.QVariant(true))
                room:broadcastSkillInvoke(self:objectName(), 3)
                room:getThread():delay(2500)
            end
            if x == 2 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(2800)
            elseif x == 3 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(2800)
            elseif x == 4 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(3500)
            elseif x > 4 and x <= 7 then
                room:broadcastSkillInvoke(self:objectName(), x + 2)
                room:getThread():delay(4000)
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:objectName() == player:objectName()
                or (room:getCurrent():objectName() == player:objectName() and not recover.who) then
                room:addPlayerMark(player, "healed", recover.recover)
                if player:getMark("healed") >= 3 then
                    room:setPlayerMark(player, "healed", 0)
                    room:broadcastSkillInvoke(self:objectName(), 10)
                    room:getThread():delay(2000)
                end
            end
            if recover.who and player:objectName() ~= room:getCurrent():objectName() and recover.who:objectName()
                ~= player:objectName() then
                room:addPlayerMark(recover.who, "rescued", recover.recover)
                if recover.who:getMark("rescued") >= 3 and player:isAlive() then
                    room:setPlayerMark(recover.who, "rescued", 0)
                    room:broadcastSkillInvoke(self:objectName(), 11)
                    room:getThread():delay(2000)
                end
            end
        end
    end,
}
if not sgs.Sanguosha:getSkill("mobile_effect") then
    SKMC.SkillList:append(mobile_effect)
end

sgs.LoadTranslationTable {
    ["mobile_effect"] = "手杀特效",
    [":mobile_effect"] = "鬼晓得这些特效是怎么触发的",
    ["$mobile_effect1"] = "癫狂屠戮！",
    ["$mobile_effect2"] = "无双！万军取首！",
    ["$mobile_effect3"] = "一破！卧龙出山！",
    ["$mobile_effect4"] = "双连！一战成名！",
    ["$mobile_effect5"] = "三连！下次一定！",
    ["$mobile_effect6"] = "四连！天下无敌！",
    ["$mobile_effect7"] = "五连！诛天灭地！",
    ["$mobile_effect8"] = "六连！诛天灭地！",
    ["$mobile_effect9"] = "七连！诛天灭地！",
    ["$mobile_effect10"] = "医术高超~",
    ["$mobile_effect11"] = "妙手回春~",
}

mvp_experience = sgs.CreateTriggerSkill {
    name = "#mvp_experience",
    events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardsMoveOneTime, sgs.PreDamageDone, sgs.HpLost,
        sgs.GameOverJudge},
    global = true,
    priority = 3,
    on_trigger = function(self, event, player, data, room)
        local room = player:getRoom()
        if not string.find(room:getMode(), "p") then
            return
        end
        if room:getTag("DisableMVP"):toBool() then
            return
        end
        local x = 1
        local conv = false
        if event == sgs.PreCardUsed or event == sgs.CardResponded then
            local card = nil
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:getTypeId() == sgs.Card_TypeBasic then
                room:addPlayerMark(player, "mvpexp", x)
            elseif card:getTypeId() == sgs.Card_TypeTrick then
                room:addPlayerMark(player, "mvpexp", 3 * x)
            elseif card:getTypeId() == sgs.Card_TypeEquip then
                room:addPlayerMark(player, "mvpexp", 2 * x)
            end
            if conv and math.random() < 0.1 then
                SKMC.play_conversation(room, player:getGeneralName(), "#mvpuse" .. math.floor(math.random(6)))
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if not move.to or player:objectName() ~= move.to:objectName()
                or (move.from and move.from:objectName() == move.to:objectName())
                or (move.to_place ~= sgs.Player_PlaceHand and move.to_place ~= sgs.Player_PlaceEquip)
                or room:getTag("FirstRound"):toBool() then
                return false
            end
            room:addPlayerMark(player, "mvpexp", move.card_ids:length() * x)
        elseif event == sgs.PreDamageDone then
            local damage = data:toDamage()
            if damage.from then
                room:addPlayerMark(damage.from, "mvpexp", damage.damage * 5 * x)
                room:addPlayerMark(damage.to, "mvpexp", damage.damage * 2 * x)
                if conv then
                    SKMC.play_conversation(room, damage.from:getGeneralName(),
                        "#mvpdamage" .. math.floor(math.random(6)))
                end
            end
        elseif event == sgs.HpLost then
            local lose = data:toInt()
            room:addPlayerMark(player, "mvpexp", lose * x)
            if conv and math.random() < 0.3 then
                SKMC.play_conversation(room, player:getGeneralName(), "#mvplose" .. math.floor(math.random(6)))
            end
        elseif event == sgs.GameOverJudge then
            local death = data:toDeath()
            if not death.who:isLord() then
                room:removePlayerMark(death.who, "mvpexp", 100)
            else
                for _, p in sgs.qlist(room:getOtherPlayers(death.who)) do
                    room:addPlayerMark(p, "mvpexp", 10 * x)
                end
                local damage = death.damage
                if damage and damage.from and damage.from:isAlive() and not damage.from:isLord() then
                    room:addPlayerMark(damage.from, "mvpexp", 5 * x)
                end
            end
            local t = SKMC.get_winner(room, death.who)
            if not t then
                return
            end
            local players = sgs.QList2Table(room:getAlivePlayers())
            local function loser(p)
                local tt = t:split("+")
                if not table.contains(tt, p:getRole()) then
                    return true
                end
                return false
            end
            for _, p in ipairs(players) do
                if loser(p) then
                    table.removeOne(players, p)
                end
            end
            local comp = function(a, b)
                return a:getMark("mvpexp") > b:getMark("mvpexp")
            end
            if #players > 1 then
                table.sort(players, comp)
            end
            local str = players[1]:getGeneralName()
            local str2 = players[1]:screenName()
            room:doAnimate(2, "skill=MobileMvp:" .. str .. ":" .. str2, "~" .. str)
            room:broadcastSkillInvoke("mobile_effect", 12)
            local thread = room:getThread()
            thread:delay(1100)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
if not sgs.Sanguosha:getSkill("#mvp_experience") then
    SKMC.SkillList:append(mvp_experience)
end

ExtraCollateralCard = sgs.CreateSkillCard {
    name = "ExtraCollateral",
    filter = function(self, targets, to_select)
        local collateral = sgs.Card_Parse(sgs.Self:property("extra_collateral"):toString())
        if not collateral then
            return false
        end
        local tos = sgs.Self:property("extra_collateral_current_targets"):toString():split("+")
        if #targets == 0 then
            return not table.contains(tos, to_select:objectName()) and not sgs.Self:isProhibited(to_select, collateral)
                       and collateral:targetFilter(SKMC.table_to_PlayerList(targets), to_select, sgs.Self)
        else
            return collateral:targetFilter(SKMC.table_to_PlayerList(targets), to_select, sgs.Self)
        end
    end,
    about_to_use = function(self, room, use)
        local killer = use.to:first()
        local victim = use.to:last()
        room:setPlayerFlag(killer, "ExtraCollateralTarget")
        local _data = sgs.QVariant()
        _data:setValue(victim)
        killer:setTag("collateralVictim", _data)
    end,
}
ExtraCollateral = sgs.CreateZeroCardViewAsSkill {
    name = "ExtraCollateral",
    response_pattern = "@@ExtraCollateral",
    view_as = function()
        return ExtraCollateralCard:clone()
    end,
}
if not sgs.Sanguosha:getSkill("ExtraCollateral") then
    SKMC.SkillList:append(ExtraCollateral)
end

