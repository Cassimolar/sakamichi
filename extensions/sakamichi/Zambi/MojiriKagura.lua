require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MojiriKagura = sgs.General(Zambi, "MojiriKagura", "Zambi", 4, false)
table.insert(SKMC.NiKiSei, "MojiriKagura")

--[[
    技能名：美人
    描述：出牌阶段开始时，你可以展示所有手牌（至少一张）并选择一至三项：1.弃置一张基本牌，则本回合内你使用基本牌时可以额外指定一个目标；2.弃置一张锦囊牌，则本回合内你使用牌无次数和距离限制；3.弃置一张装备牌，则本回合内你无视其他角色防具牌的效果。
]]
Luautsukushiionna = sgs.CreateTriggerSkill {
    name = "Luautsukushiionna",
    events = {sgs.EventPhaseStart, sgs.TargetSpecified, sgs.PreCardUsed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:getHandcardNum() ~= 0
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:showAllCards(player)
            local basic = room:askForCard(player, "BasicCard", "@utsukushiionna_basic", data, self:objectName())
            if basic then
                room:setPlayerFlag(player, "utsukushiionna_basic")
            end
            local trick = room:askForCard(player, "TrickCard", "@utsukushiionna_trick", data, self:objectName())
            if trick then
                room:setPlayerFlag(player, "utsukushiionna_trick")
            end
            local equip = room:askForCard(player, "EquipCard", "@utsukushiionna_equip", data, self:objectName())
            if equip then
                room:setPlayerFlag(player, "utsukushiionna_equip")
            end
        elseif event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.from and use.from:objectName() == player:objectName() and player:hasFlag("utsukushiionna_equip") then
                for _, p in sgs.qlist(use.to) do
                    p:addQinggangTag(use.card)
                end
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("BasicCard") and player:hasFlag("utsukushiionna_basic") then
                if (sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY) then
                    return false
                end
                local available_targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if not ((use.to:contains(p) or room:isProhibited(player, p, use.card))) then
                        break
                    end
                    if (use.card:targetFixed()) then
                        if (not use.card:isKindOf("Peach")) or (p:isWounded()) then
                            available_targets:append(p)
                        end
                    else
                        if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
                            available_targets:append(p)
                        end
                    end
                end
                local extra = room:askForPlayerChosen(player, available_targets, "Luautsukushiionna",
                    "@utsukushiionna_add:::" .. use.card:objectName())
                local msg = sgs.LogMessage()
                msg.type = "#utsukushiionna"
                msg.from = player
                msg.to:append(extra)
                msg.card_str = use.card:toString()
                msg.arg = self:objectName()
                room:sendLog(msg)
                use.to:append(extra)
                room:sortByActionOrder(use.to)
                data:setValue(use)
            end
        end
        return false
    end,
}
LuautsukushiionnaMod = sgs.CreateTargetModSkill {
    name = "#LuautsukushiionnaMod",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from:hasFlag("utsukushiionna_trick") then
            return 1000
        end
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasFlag("utsukushiionna_trick") then
            return 1000
        end
    end,
}
MojiriKagura:addSkill(Luautsukushiionna)
if not sgs.Sanguosha:getSkill("#LuautsukushiionnaMod") then
    SKMC.SkillList:append(LuautsukushiionnaMod)
end

--[[
    技能名：活埋
    描述：当你受到来自其他角色的伤害后，其获得一枚“恨”，若此伤害有对应实体牌则你将所有对应实体牌置于你武将牌上称为“仇”；你对有“恨”的角色使用【杀】无距离限制且无视防具；出牌阶段你可以将“仇”视为【杀】使用；当你对一名角色造成伤害后，若其有“恨”，其失去一枚“恨”，若此伤害原因是由“仇”转化的【杀】，你可以回复1点体力。
]]
LuaikiumeVS = sgs.CreateOneCardViewAsSkill {
    name = "Luaikiume",
    filter_pattern = ".|.|.|chou",
    expand_pile = "chou",
    response_pattern = "slash",
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:setSkillName(self:objectName())
        slash:addSubcard(card)
        return slash
    end,
    enabled_at_play = function(self, player)
        return player:getPile("chou"):length() ~= 0 and sgs.Slash_IsAvailable(player)
    end,
}
Luaikiume = sgs.CreateTriggerSkill {
    name = "Luaikiume",
    view_as_skill = LuaikiumeVS,
    events = {sgs.Damaged, sgs.Damage, sgs.CardUsed, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from then
                damage.from:gainMark("@hen")
                if damage.card then
                    local ids = sgs.IntList()
                    if damage.card:isVirtualCard() then
                        ids = damage.card:getSubcards()
                    else
                        ids:append(damage.card:getEffectiveId())
                    end
                    player:addToPile("chou", ids, false)
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:getMark("@hen") then
                damage.to:loseMark("@hen")
                if damage.card:getSkillName() == self:objectName() then
                    if player:isWounded() then
                        room:recover(player, sgs.RecoverStruct(player, damage.card, 1))
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") then
                for _, p in sgs.qlist(use.to) do
                    if p:getMark("@hen") ~= 0 then
                        p:addQinggangTag(use.card)
                    end
                end
            end
        end
        return false
    end,
}
LuaikiumeTargetMod = sgs.CreateTargetModSkill {
    name = "#LuaikiumeTargetMod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from and from:hasSkill("Luaikiume") and to and to:getMark("@hen") ~= 0 then
            return 1000
        else
            return 0
        end
    end,
}
MojiriKagura:addSkill(Luaikiume)
if not sgs.Sanguosha:getSkill("#LuaikiumeTargetMod") then
    SKMC.SkillList:append(LuaikiumeTargetMod)
end

--[[
    技能名：始祖
    描述：觉醒技，当你进入濒死时，你须将体力回复至体力上限并将手牌补至体力上限，然后获得【神人】。
]]
Luahajimarinoonna = sgs.CreateTriggerSkill {
    name = "Luahajimarinoonna",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() and player:getMark(self:objectName()) == 0 then
            room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMaxHp()))
            if player:getHandcardNum() < player:getMaxHp() then
                room:drawCards(player, player:getMaxHp() - player:getHandcardNum(), self:objectName())
            end
            room:handleAcquireDetachSkills(player, "Luashinjin")
            room:addPlayerMark(player, self:objectName())
        end
        return false
    end,
}
MojiriKagura:addSkill(Luahajimarinoonna)

--[[
    技能名：神人
    描述：锁定技，你使用【杀】造成伤害时，防止此伤害并令目标失去1点体力上限；锁定技，你不是【桃】的合法目标；锁定技，你计算到其他角色的距离时始终+1。
]]
Luashinjin = sgs.CreateTriggerSkill {
    name = "Luashinjin",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.card and damage.card:isKindOf("Slash") then
            room:loseMaxHp(damage.to)
            damage.damage = 0
            data:setValue(damage)
        end
    end,
}
LuashinjinProtect = sgs.CreateProhibitSkill {
    name = "#LuashinjinProtect",
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("Luashinjin") and card:isKindOf("Peach")
    end,
}
LuashinjinMod = sgs.CreateDistanceSkill {
    name = "#LuashinjinMod",
    correct_func = function(self, from, to)
        if from:hasSkill("Luashinjin") then
            return 1
        end
    end,
}
if not sgs.Sanguosha:getSkill("Luashinjin") then
    SKMC.SkillList:append(Luashinjin)
end
if not sgs.Sanguosha:getSkill("#LuashinjinProtect") then
    SKMC.SkillList:append(LuashinjinProtect)
end
if not sgs.Sanguosha:getSkill("#LuashinjinMod") then
    SKMC.SkillList:append(LuashinjinMod)
end

sgs.LoadTranslationTable {
    ["MojiriKagura"] = "神楽 もみじ",
    ["&MojiriKagura"] = "神楽 もみじ",
    ["#MojiriKagura"] = "貴重なお話",
    ["designer:MojiriKagura"] = "Cassimolar",
    ["cv:MojiriKagura"] = "新内 眞衣",
    ["illustrator:MojiriKagura"] = "Cassimolar",
    ["Luautsukushiionna"] = "美人",
    [":Luautsukushiionna"] = "出牌阶段开始时，你可以展示所有手牌（至少一张）并选择一至三项：1.弃置一张基本牌，则本回合内你使用基本牌时可以额外指定一个目标；2.弃置一张锦囊牌，则本回合内你使用牌无次数和距离限制；3.弃置一张装备牌，则本回合内你无视其他角色防具牌的效果。",
    ["@utsukushiionna_basic"] = "你可以弃置一张基本牌令你本回合内使用基本牌可以额外指定一个目标",
    ["@utsukushiionna_trick"] = "你可以弃置一张锦囊牌令你本回合内使用牌无次数和距离限制",
    ["@utsukushiionna_equip"] = "你可以弃置一张装备牌令你本回合内无视其他角色防具",
    ["@utsukushiionna_add"] = "请为此【%arg】选择一个额外目标",
    ["#utsukushiionna"] = "%from 发动了【%arg】为 %card 增加了额外目标 %to",
    ["Luaikiume"] = "活埋",
    [":Luaikiume"] = "当你受到来自其他角色的伤害后，其获得一枚“恨”，若此伤害有对应实体牌则你将所有对应实体牌置于你武将牌上称为“仇”；你对有“恨”的角色使用【杀】无距离限制且无视防具；出牌阶段你可以将“仇”视为【杀】使用；当你对一名角色造成伤害后，若其有“恨”，其失去一枚“恨”，若此伤害原因是由“仇”转化的【杀】，你可以回复1点体力。",
    ["chou"] = "仇",
    ["@hen"] = "恨",
    ["Luahajimarinoonna"] = "始祖",
    [":Luahajimarinoonna"] = "觉醒技，当你进入濒死时，你须将体力回复至体力上限并将手牌补至体力上限，然后获得【神人】。",
    ["Luashinjin"] = "神人",
    [":Luashinjin"] = "锁定技，你使用【杀】造成伤害时，防止此伤害并令目标失去1点体力上限；锁定技，你不是【桃】的合法目标；锁定技，你计算到其他角色的距离时始终+1。",
}
