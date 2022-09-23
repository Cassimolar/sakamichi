require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KokoaKai_Female = sgs.General(STU48, "KokoaKai_Female", "STU48", 3, false)
table.insert(SKMC.IKiSei, "KokoaKai_Female")

--[[
    技能名：出航
    描述：锁定技，游戏开始时，若你为「甲斐心愛」且场上存在「岡田 奈々」并且主公为「瀧野 由美子」，你须将武将牌替换成「STU 48的熊孩子 - 甲斐心愛」并将你的身份牌替换为［忠臣］，然后与主公上家交换座位。
]]
Luachuhang_k = sgs.CreateTriggerSkill {
    name = "Luachuhang_k",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        if string.find(player:getGeneralName(), "KokoaKai") or string.find(player:getGeneral2Name(), "KokoaKai") then
            local lordyumiko = false
            local hasnana = false
            local lord = room:getLord()
            if string.find(lord:getGeneralName(), "YumikoTakino") or string.find(lord:getGeneral2Name(), "YumikoTakino") then
                lordyumiko = true
            end
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if string.find(p:getGeneralName(), "NanaOkada") or string.find(p:getGeneral2Name(), "NanaOkada") then
                    hasnana = true
                end
            end
            if lordyumiko and hasnana then
                room:changeHero(player, "KokoaKai_NCOS", true, true, false, true)
                room:setPlayerProperty(player, "role", sgs.QVariant("loyalist"))
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:getNextAlive():objectName() == lord:objectName() then
                        room:swapSeat(player, p)
                        break
                    end
                end
            end
        end
        return false
    end,
}
KokoaKai_Female:addSkill(Luachuhang_k)

--[[
    技能名：奈玉米心爱
    描述：锁定技，游戏开始时，若你为「甲斐 心愛」且场上存在「瀧野 由美子」且不存在「岡田 奈々」，你须将武将牌替换为「重組家庭的拖油瓶 - 甲斐 心愛」；锁定技，游戏开始时，若你为「甲斐 心愛」且场上存在「岡田 奈々」且不存在「瀧野 由美子」，你须将武将牌替换为「舰长之子 - 甲斐 心愛」。
]]
Luayumikokonana_k = sgs.CreateTriggerSkill {
    name = "Luayumikokonana_k",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        if string.find(player:getGeneralName(), "KokoaKai") or string.find(player:getGeneral2Name(), "KokoaKai") then
            local hasnana = false
            local hasyumiko = false
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if string.find(p:getGeneralName(), "NanaOkada") or string.find(p:getGeneral2Name(), "NanaOkada") then
                    hasnana = true
                end
                if string.find(p:getGeneralName(), "YumikoTakino") or string.find(p:getGeneral2Name(), "YumikoTakino") then
                    hasyumiko = true
                end
            end
            if hasnana and not hasyumiko then
                room:changeHero(player, "KokoaKai_SOC", true, true, false, true)
            end
            if not hasnana and hasyumiko then
                room:changeHero(player, "KokoaKai_SSORF", true, true, false, true)
            end
        end
        return false
    end,
}
KokoaKai_Female:addSkill(Luayumikokonana_k)

--[[
    技能名：难辨
    描述：锁定技，回合开始时和当你受到伤害后，你必须倒转性别；锁定技，你防止异性角色对你造成的非雷电属性伤害。
]]
Luananbian = sgs.CreateTriggerSkill {
    name = "Luananbian",
    events = {sgs.EventPhaseStart, sgs.DamageInflicted, sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                if player:isMale() then
                    room:changeHero(player, "KokoaKai_Female", false, false, false, false)
                    local msg = sgs.LogMessage()
                    msg.type = "#nanbianFlip"
                    msg.from = player
                    msg.arg = self:objectName()
                    room:sendLog(msg)
                else
                    player:setGender(sgs.General_Male)
                    room:changeHero(player, "KokoaKai_Male", false, false, false, false)
                    local msg = sgs.LogMessage()
                    msg.type = "#nanbianFlip"
                    msg.from = player
                    msg.arg = self:objectName()
                    room:sendLog(msg)
                end
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if (damage.nature ~= sgs.DamageStruct_Thunder) and damage.from and (damage.from:isMale() ~= player:isMale()) then
                local msg = sgs.LogMessage()
                msg.type = "#nanbianProtect"
                msg.from = damage.from
                msg.to:append(damage.to)
                msg.arg = self:objectName()
                room:sendLog(msg)
                room:setEmotion(damage.to, "skill_nullify")
                return true
            end
        elseif event == sgs.Damaged then
            if player:isMale() then
                room:changeHero(player, "KokoaKai_Female", false, false, false, false)
            else
                room:changeHero(player, "KokoaKai_Male", false, false, false, false)
            end
            local msg = sgs.LogMessage()
            msg.type = "#nanbianFlip"
            msg.from = player
            msg.arg = self:objectName()
            room:sendLog(msg)
        end
        return false
    end,
}
KokoaKai_Female:addSkill(Luananbian)

sgs.LoadTranslationTable {
    ["KokoaKai_Female"] = "甲斐 心愛",
    ["&KokoaKai_Female"] = "甲斐 心愛",
    ["#KokoaKai_Female"] = "濑户内小公主",
    ["designer:KokoaKai_Female"] = "Cassimolar",
    ["cv:KokoaKai_Female"] = "甲斐 心愛",
    ["illustrator:KokoaKai_Female"] = "Cassimolar",
    ["Luachuhang_k"] = "出航",
    [":Luachuhang_k"] = "锁定技，游戏开始时，若你为「甲斐心愛」且场上存在「岡田 奈々」并且主公为「瀧野 由美子」，你须将武将牌替换成「STU 48的熊孩子 - 甲斐心愛」并将你的身份牌替换为［忠臣］，然后与主公上家交换座位。",
    ["Luayumikokonana_k"] = "奈玉米心爱",
    [":Luayumikokonana_k"] = "锁定技，游戏开始时，若你为「甲斐 心愛」且场上存在「瀧野 由美子」且不存在「岡田 奈々」，你须将武将牌替换为「重組家庭的拖油瓶 - 甲斐 心愛」；锁定技，游戏开始时，若你为「甲斐 心愛」且场上存在「岡田 奈々」且不存在「瀧野 由美子」，你须将武将牌替换为「舰长之子 - 甲斐 心愛」。",
    ["Luananbian"] = "难辨",
    [":Luananbian"] = "锁定技，回合开始时和当你受到一次伤害后，你须改变你的性别，异性角色对你造成的非雷电属性伤害无效",
    ["#nanbianChoose"] = "%from 选择了 %arg 作为初始性别",
    ["#nanbianFlip"] = "%from 的【%arg】被触发，性别倒置",
    ["#nanbianProtect"] = "%to 的【%arg】被触发，异性(%from)的非雷电属性伤害无效",
}

-- 甲斐 心愛（濑户内的小公子）
KokoaKai_Male = sgs.General(STU48, "KokoaKai_Male", "STU48", 3, true, true)
table.insert(SKMC.IKiSei, "KokoaKai_Male")

KokoaKai_Male:addSkill("Luachuhang_k")
KokoaKai_Male:addSkill("Luayumikokonana_k")
KokoaKai_Male:addSkill("Luananbian")

sgs.LoadTranslationTable {
    ["KokoaKai_Male"] = "甲斐 心愛",
    ["&KokoaKai_Male"] = "甲斐 心愛",
    ["#KokoaKai_Male"] = "濑户内小公子",
    ["designer:KokoaKai_Male"] = "Cassimolar",
    ["cv:KokoaKai_Male"] = "甲斐 心愛",
    ["illustrator:KokoaKai_Male"] = "Cassimolar",
}

-- 甲斐 心愛（舰长之子）
KokoaKai_SOC = sgs.General(STU48, "KokoaKai_SOC", "STU48", 3, true, true)
table.insert(SKMC.IKiSei, "KokoaKai_SOC")

--[[
    技能名：傻儿子
    描述：出牌阶段限一次，你可以选择一名角色并选择一种花色，然后获得该角色一张手牌。若此牌与你选择的花色相同，你对其造成1点伤害且此技能视为未发动过；若花色不同，则你交给该角色一张其他花色的手牌（若没有须展示所有手牌）。
]]
LuashaerziCard = sgs.CreateSkillCard {
    name = "LuashaerziCard",
    skill_name = "Luashaerzi",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return not to_select:isKongcheng()
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local card_id = target:getRandomHandCardId()
        local card = sgs.Sanguosha:getCard(card_id)
        local suit = room:askForSuit(source, "Luashaerzi")
        local msg = sgs.LogMessage()
        msg.type = "#shaerzi_suit"
        msg.from = source
        msg.arg = sgs.Card_Suit2String(suit)
        room:sendLog(msg)
        source:obtainCard(card)
        if card:getSuit() == suit then
            room:damage(sgs.DamageStruct("Luashaerzi", source, target))
        else
            local suits = {"spade", "heart", "club", "diamond"}
            local card_str = card:getSuitString()
            table.removeOne(suits, card_str)
            local canDiscard = false
            for _, card in sgs.qlist(source:getHandcards()) do
                if string.find(table.concat(suits, "|"), card:getSuitString()) then
                    canDiscard = true
                    break
                end
            end
            if canDiscard then
                local data = sgs.QVariant()
                data:setValue(source)
                local cd = room:askForCard(source, ".|" .. table.concat(suits, ", ") .. "|.|hand",
                    "@shaerzi_give:" .. target:objectName() .. "::" .. card_str, data, sgs.Card_MethodNone, nil, false,
                    "Luashaerzi", false)
                target:obtainCard(cd)
            else
                room:showAllCards(source)
            end
            room:setPlayerFlag(source, "Luashaerzi")
        end
    end,
}
Luashaerzi = sgs.CreateZeroCardViewAsSkill {
    name = "Luashaerzi",
    view_as = function()
        return LuashaerziCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("Luashaerzi")
    end,
}
KokoaKai_SOC:addSkill(Luashaerzi)
KokoaKai_SOC:addSkill("Luakokoanana")

sgs.LoadTranslationTable {
    ["KokoaKai_SOC"] = "甲斐 心愛",
    ["&KokoaKai_SOC"] = "甲斐 心愛",
    ["#KokoaKai_SOC"] = "舰长之子",
    ["designer:KokoaKai_SOC"] = "Cassimolar",
    ["cv:KokoaKai_SOC"] = "甲斐 心愛",
    ["illustrator:KokoaKai_SOC"] = "Cassimolar",
    ["Luashaerzi"] = "傻儿子",
    [":Luashaerzi"] = "出牌阶段限一次，你可以选择一名角色并选择一种花色，然后获得该角色一张手牌。若此牌与你选择的花色相同，你对其造成1点伤害且此技能视为未发动过；若花色不同，则你交给该角色一张其他花色的手牌（若没有须展示所有手牌）。",
    ["LuashaerziCard"] = "傻儿子",
    ["#shaerzi_suit"] = "%from 选择了%arg",
    ["@shaerzi_give"] = "你需要交给 %src 一张花色不为 %arg 的牌",
}

-- 甲斐 心愛（重组家庭的拖油瓶）
KokoaKai_SSORF = sgs.General(STU48, "KokoaKai_SSORF", "STU48", 4, false, true)
table.insert(SKMC.IKiSei, "KokoaKai_SSORF")

--[[
    技能名：回收
    描述：其他角色的弃牌阶段结束时，你可以将该角色于此阶段内弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段内弃置的牌。
]]
Luahuishou = sgs.CreateTriggerSkill {
    name = "Luahuishou",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local kokoa = room:findPlayerBySkillName(self:objectName())
            local current = room:getCurrent()
            local move = data:toMoveOneTime()
            local source = move.from
            if source then
                if player:objectName() == source:objectName() then
                    if kokoa and kokoa:objectName() ~= current:objectName() then
                        if current:getPhase() == sgs.Player_Discard then
                            local tag = room:getTag("huishouToGet")
                            local huishouToGet = tag:toString()
                            tag = room:getTag("huishouOther")
                            local huishouOther = tag:toString()
                            if huishouToGet == nil then
                                huishouToGet = ""
                            end
                            if huishouOther == nil then
                                huishouOther = ""
                            end
                            for _, card_id in sgs.qlist(move.card_ids) do
                                local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
                                if flag == sgs.CardMoveReason_S_REASON_DISCARD then
                                    if source:objectName() == current:objectName() then
                                        if huishouToGet == "" then
                                            huishouToGet = tostring(card_id)
                                        else
                                            huishouToGet = huishouToGet .. "+" .. tostring(card_id)
                                        end
                                    elseif not strcontain(huishouToGet, tostring(card_id)) then
                                        if huishouOther == "" then
                                            huishouOther = tostring(card_id)
                                        else
                                            huishouOther = huishouOther .. "+" .. tostring(card_id)
                                        end
                                    end
                                end
                            end
                            if huishouToGet then
                                room:setTag("huishouToGet", sgs.QVariant(huishouToGet))
                            end
                            if huishouOther then
                                room:setTag("huishouOther", sgs.QVariant(huishouOther))
                            end
                        end
                    end
                end
            end
        else
            if player:getPhase() == sgs.Player_Discard then
                if not player:isDead() then
                    local kokoa = room:findPlayerBySkillName("Luahuishou")
                    if kokoa then
                        local tag = room:getTag("huishouToGet")
                        local huishou_cardsToGet
                        local huishou_cardsOther
                        if tag then
                            huishou_cardsToGet = tag:toString():split("+")
                        else
                            return false
                        end
                        tag = room:getTag("huishouOther")
                        if tag then
                            huishou_cardsOther = tag:toString():split("+")
                        end
                        room:removeTag("huishouToGet")
                        room:removeTag("huishouOther")
                        local cardsToGet = sgs.IntList()
                        local cards = sgs.IntList()
                        for i = 1, #huishou_cardsToGet, 1 do
                            local card_data = huishou_cardsToGet[i]
                            if card_data == nil then
                                return false
                            end
                            if card_data ~= "" then
                                local card_id = tonumber(card_data)
                                if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                                    cardsToGet:append(card_id)
                                    cards:append(card_id)
                                end
                            end
                        end
                        if huishou_cardsOther then
                            for i = 1, #huishou_cardsOther, 1 do
                                local card_data = huishou_cardsOther[i]
                                if card_data == nil then
                                    return false
                                end
                                if card_data ~= "" then
                                    local card_id = tonumber(card_data)
                                    if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                                        cardsToGet:append(card_id)
                                        cards:append(card_id)
                                    end
                                end
                            end
                        end
                        if cardsToGet:length() > 0 then
                            local ai_data = sgs.QVariant()
                            ai_data:setValue(cards:length())
                            if kokoa:askForSkillInvoke(self:objectName(), ai_data) then
                                room:fillAG(cards, kokoa)
                                local to_back = room:askForAG(kokoa, cardsToGet, false, self:objectName())
                                local backcard = sgs.Sanguosha:getCard(to_back)
                                player:obtainCard(backcard)
                                cards:removeOne(to_back)
                                room:clearAG(kokoa)
                                local move = sgs.CardsMoveStruct()
                                move.card_ids = cards
                                move.to = kokoa
                                move.to_place = sgs.Player_PlaceHand
                                room:moveCardsAtomic(move, true)
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
KokoaKai_SSORF:addSkill(Luahuishou)
KokoaKai_SSORF:addSkill("Luayumikoko")

sgs.LoadTranslationTable {
    ["KokoaKai_SSORF"] = "甲斐 心愛",
    ["&KokoaKai_SSORF"] = "甲斐 心愛",
    ["#KokoaKai_SSORF"] = "重組家庭的拖油瓶",
    ["designer:KokoaKai_SSORF"] = "Cassimolar",
    ["cv:KokoaKai_SSORF"] = "甲斐 心愛",
    ["illustrator:KokoaKai_SSORF"] = "Cassimolar",
    ["Luahuishou"] = "回收",
    [":Luahuishou"] = "其他角色的弃牌阶段结束时，你可以将该角色于此阶段内弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段内弃置的牌。",
    ["#LuahuishouGet"] = "回收",
}

-- 甲斐 心愛（STU 48的熊孩子）
KokoaKai_NCOS = sgs.General(STU48, "KokoaKai_NCOS", "STU48", 4, false, true)
table.insert(SKMC.IKiSei, "KokoaKai_NCOS")

--[[
    技能名：变幻
    描述：回合开始时和当你受到伤害后，你可以选择你的性别；锁定技，若你性别为中性，你防止异性角色对你造成的属性伤害；锁定技，若你性别为男性，你防止异性角色对你造成的非火焰伤害；锁定技，若你性别为女性，你防止异性角色对你造成的非雷电属性伤害；锁定技，若你性别为无性，你防止你的体力流失。
]]
Luabianhuan = sgs.CreateTriggerSkill {
    name = "Luabianhuan",
    events = {sgs.EventPhaseStart, sgs.DamageInflicted, sgs.Damaged, sgs.PreHpLost},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) or event == sgs.Damaged then
            local gender = room:askForChoice(player, self:objectName(), "male+female+neuter+sexless+cancel")
            if gender == "male" then
                player:setGender(sgs.General_Male)
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanChoose"
                msg.from = player
                msg.arg = "Luabianhuan:male"
                room:sendLog(msg)
            elseif gender == "female" then
                player:setGender(sgs.General_Female)
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanChoose"
                msg.from = player
                msg.arg = "Luabianhuan:female"
                room:sendLog(msg)
            elseif gender == "neuter" then
                player:setGender(sgs.General_Neuter)
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanChoose"
                msg.from = player
                msg.arg = "Luabianhuan:neuter"
                room:sendLog(msg)
            elseif gender == "sexless" then
                player:setGender(sgs.General_Sexless)
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanChoose"
                msg.from = player
                msg.arg = "Luabianhuan:sexless"
                room:sendLog(msg)
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:isNeuter() and damage.nature ~= sgs.DamageStruct_Normal and damage.from
                and not damage.from:isNeuter() then
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanProtect_neuter"
                msg.from = damage.to
                msg.to:append(damage.from)
                msg.arg = self:objectName()
                room:sendLog(msg)
                room:setEmotion(damage.to, "skill_nullify")
                return true
            end
            if player:isMale() and damage.nature ~= sgs.DamageStruct_Fire and damage.from and not damage.from:isMale() then
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanProtect_male"
                msg.from = damage.to
                msg.to:append(damage.from)
                msg.arg = self:objectName()
                room:sendLog(msg)
                room:setEmotion(damage.to, "skill_nullify")
                return true
            end
            if player:isFemale() and damage.nature ~= sgs.DamageStruct_Thunder and damage.from
                and not damage.from:isFemale() then
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanProtect_female"
                msg.from = damage.to
                msg.to:append(damage.from)
                msg.arg = self:objectName()
                room:sendLog(msg)
                room:setEmotion(damage.to, "skill_nullify")
                return true
            end
        elseif event == sgs.PreHpLost then
            if player:getGender() == sgs.General_Sexless then
                local msg = sgs.LogMessage()
                msg.type = "#bianhuanProtect_sexless"
                msg.from = player
                msg.arg = self:objectName()
                room:sendLog(msg)
                room:setEmotion(player, "skill_nullify")
                return true
            end
        end
        return false
    end,
}
KokoaKai_NCOS:addSkill(Luabianhuan)

--[[
    技能名：点火
    描述：锁定技，你的【杀】始终带有火焰属性；当你对一名不处于连环状态的角色造成一次火焰伤害时，你可以选择一名其距离为1的另外一名角色并令选择的角色进行一次判定：若判定结果为红色，则你对选择的角色造成1点火焰伤害。
]]
Luadianhuo = sgs.CreateTriggerSkill {
    name = "Luadianhuo",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.PreDamageDone, sgs.DamageComplete},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed and player:hasSkill(self) then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and (not use.card:isKindOf("FireSlash")) then
                local fire_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
                if not use.card:isVirtualCard() then
                    fire_slash:addSubcard(use.card)
                elseif use.card:subcardsLength() > 0 then
                    for _, id in sgs.qlist(use.card:getSubcards()) do
                        fire_slash:addSubcard(id)
                    end
                end
                fire_slash:setSkillName(self:objectName())
                use.card = fire_slash
                data:setValue(use)
            end
        else
            local damage = data:toDamage()
            if event == sgs.PreDamageDone then
                if not player:isChained() and damage.from and damage.nature == sgs.DamageStruct_Fire
                    and damage.from:isAlive() and damage.from:hasSkill(self) then
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        if (player:distanceTo(p) == 1) then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(damage.from, targets, self:objectName(),
                            "@dianhuo_invoke:" .. damage.to:objectName(), true, true)
                        if target then
                            local _data = sgs.QVariant()
                            _data:setValue(target)
                            damage.from:setTag("LuadianhuoTarget", _data)
                        end
                    end
                end
            elseif event == sgs.DamageComplete then
                if damage.from == nil then
                    return false
                end
                local target = damage.from:getTag("LuadianhuoTarget"):toPlayer()
                damage.from:removeTag("LuadianhuoTarget")
                if not target or not damage.from or damage.from:isDead() then
                    return false
                end
                local judge = sgs.JudgeStruct()
                judge.pattern = ".|red"
                judge.good = true
                judge.reason = self:objectName()
                judge.who = target
                room:judge(judge)
                if judge:isGood() then
                    room:damage(sgs.DamageStruct(self:objectName(), damage.from, target, 1, sgs.DamageStruct_Fire))
                end
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KokoaKai_NCOS:addSkill(Luadianhuo)

--[[
    技能名：厨房
    描述：锁定技，你是所有火焰伤害的来源；当你造成火焰伤害时，你可以防止此次伤害，令目标二选一：1.回复X点体力；2.摸X张牌。（X为此次伤害值）
]]
Luachufang = sgs.CreateTriggerSkill {
    name = "Luachufang",
    events = {sgs.ConfirmDamage, sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Fire then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasSkill(self) then
                        local msg = sgs.LogMessage()
                        msg.type = "#chufang-Fire"
                        msg.from = p
                        msg.to:append(damage.from)
                        msg.arg = self:objectName()
                        room:sendLog(msg)
                        damage.from = p
                    end
                end
                data:setValue(damage)
            end
        else
            if player:hasSkill(self) then
                local damage = data:toDamage()
                if damage.nature == sgs.DamageStruct_Fire then
                    if room:askForSkillInvoke(player, self:objectName(),
                        sgs.QVariant("@chufang_invoke:" .. damage.to:objectName())) then
                        local choice = room:askForChoice(damage.to, self:objectName(), "recover+draw")
                        local msg = sgs.LogMessage()
                        msg.type = "#chufang_choice"
                        msg.from = damage.to
                        msg.arg = "Luachufang:" .. choice
                        room:sendLog(msg)
                        if choice == "recover" then
                            room:setEmotion(damage.to, "skill_nullify")
                            room:recover(damage.to, sgs.RecoverStruct(player, nil, damage.damage))
                            return true
                        else
                            room:setEmotion(damage.to, "skill_nullify")
                            damage.to:drawCards(damage.damage)
                            return true
                        end
                    end
                end
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KokoaKai_NCOS:addSkill(Luachufang)

--[[
    技能名：启航
    描述：锁定技，「STU 48的熊孩子 - 甲斐心愛」、「STU 48的Center - 瀧野 由美子」、「STU 48的舰长 - 岡田奈々」未装备防具时视为装备【藤甲】。
]]
Luaqihang = sgs.CreateTriggerSkill {
    name = "Luaqihang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.SlashEffected, sgs.CardEffected, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.SlashEffected then
            local effect = data:toSlashEffect()
            if effect.nature == sgs.DamageStruct_Normal then
                room:setEmotion(player, "armor/vine")
                local msg = sgs.LogMessage()
                msg.type = "#ArmorNullify"
                msg.from = player
                msg.arg = "vine"
                msg.arg2 = effect.slash:objectName()
                room:sendLog(msg)
                effect.to:setFlags("Global_NonSkillNullify")
                return true
            end
        elseif event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if effect.card:isKindOf("AOE") then
                room:setEmotion(player, "armor/vine")
                local msg = sgs.LogMessage()
                msg.type = "#ArmorNullify"
                msg.from = player
                msg.arg = "vine"
                msg.arg2 = effect.card:objectName()
                room:sendLog(msg)
                effect.to:setFlags("Global_NonSkillNullify")
                return true
            end
        elseif event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Fire then
                room:setEmotion(player, "armor/vineburn")
                local msg = sgs.LogMessage()
                msg.type = "#VineDamage"
                msg.from = player
                msg.arg = damage.damage
                msg.arg2 = damage.damage + 1
                room:sendLog(msg)
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        end
    end,
    can_trigger = function(self, target)
        if target and target:isAlive() and not target:getArmor() then
            if target:getGeneralName() == "YumikoTakino_COS" or target:getGeneral2Name() == "YumikoTakino_COS"
                or target:getGeneralName() == "KokoaKai_NCOS" or target:getGeneral2Name() == "KokoaKai_NCOS"
                or target:getGeneralName() == "NanaOkada_COS" or target:getGeneral2Name() == "NanaOkada_COS" then
                if target:getMark("Armor_Nullified") == 0 and not target:hasFlag("WuqianTarget") then
                    if target:getMark("Equips_Nullified_to_Yourself") == 0 then
                        local list = target:getTag("Qinggang"):toStringList()
                        return #list == 0
                    end
                end
            end
        end
        return false
    end,
}
KokoaKai_NCOS:addSkill(Luaqihang)

sgs.LoadTranslationTable {
    ["KokoaKai_NCOS"] = "甲斐 心愛",
    ["&KokoaKai_NCOS"] = "甲斐 心愛",
    ["#KokoaKai_NCOS"] = "STU 48的熊孩子",
    ["designer:KokoaKai_NCOS"] = "Cassimolar",
    ["cv:KokoaKai_NCOS"] = "甲斐 心愛",
    ["illustrator:KokoaKai_NCOS"] = "Cassimolar",
    ["Luabianhuan"] = "变幻",
    [":Luabianhuan"] = "回合开始时和当你受到伤害后，你可以选择你的性别；锁定技，若你性别为中性，你防止异性角色对你造成的属性伤害；锁定技，若你性别为男性，你防止异性角色对你造成的非火焰伤害；锁定技，若你性别为女性，你防止异性角色对你造成的非雷电属性伤害。",
    ["Luabianhuan:male"] = "男性",
    ["Luabianhuan:female"] = "女性",
    ["Luabianhuan:neuter"] = "中性",
    ["Luabianhuan:sexless"] = "无性",
    ["Luabianhuan:cancel"] = "取消",
    ["#bianhuanChoose"] = "%from 选择了“%arg”作为他的性别",
    ["#bianhuanProtect_neuter"] = "%from 的【%arg】被触发，防止异性(%to)的属性伤害",
    ["#bianhuanProtect_male"] = "%from 的【%arg】被触发，防止异性(%to)的非火焰属性伤害",
    ["#bianhuanProtect_female"] = "%from 的【%arg】被触发，防止异性(%to)的非雷电属性伤害",
    ["#bianhuanProtect_sexless"] = "%from 的【%arg】被触发，此次体力流失被防止",
    ["Luadianhuo"] = "点火",
    [":Luadianhuo"] = "锁定技，你的【杀】始终带有火焰属性；当你对一名不处于连环状态的角色造成一次火焰伤害时，你可以选择一名其距离为1的另外一名角色并令选择的角色进行一次判定：若判定结果为红色，则你对选择的角色造成1点火焰伤害。",
    ["@dianhuo_invoke"] = "请选择一名距离 %src 为1的角色",
    ["Luachufang"] = "厨房",
    [":Luachufang"] = "锁定技，你是所有火焰伤害的来源；当你造成火焰伤害时，你可以防止此次伤害，令目标二选一：1.回复X点体力；2.摸X张牌。（X为此次伤害值）",
    ["@chufang_invoke"] = "是否发动【厨房】防止此次你对%src造成的火焰伤害",
    ["#chufang-Fire"] = "%from 的【%arg】被触发，%from 成为此次 %to 造成的火焰伤害来源",
    ["Luachufang:recover"] = "回复体力值",
    ["Luachufang:draw"] = "摸牌",
    ["#chufang_choice"] = "%from 选择了“%arg”",
    ["Luaqihang"] = "启航",
    [":Luaqihang"] = "锁定技，「STU 48的熊孩子 - 甲斐心愛」、「STU 48的Center - 瀧野 由美子」、「STU 48的舰长 - 岡田奈々」未装备防具时视为装备【藤甲】。",
}
