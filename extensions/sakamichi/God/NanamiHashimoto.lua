NanamiHashimoto_God = sgs.General(SakamichiGod, "NanamiHashimoto_God", "god", 5, false)
table.insert(SKMC.IKiSei, "NanamiHashimoto_God")

--[[
    技能名：棘人
    描述：当你成为其他角色使用的基本牌或通常锦囊牌的唯一目标时，若其为此牌的合法目标，则视为你对其使用此牌。
]]
Luashijin = sgs.CreateTriggerSkill {
    name = "Luashijin",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card and not use.card:isKindOf("SkillCard") and not use.card:isKindOf("DelayedTrick")
            and use.to:contains(player) and use.to:length() == 1 and use.from and use.from:isAlive()
            and use.from:objectName() ~= player:objectName() then
            local acard = sgs.Sanguosha:cloneCard(use.card:objectName(), use.card:getSuit(), use.card:getNumber())
            acard:setSkillName(self:objectName())
            if acard:isAvailable(use.from) and not use.card:isKindOf("Slash") then
                if acard:isKindOf("Collateral") then
                    local u = sgs.CardUseStruct()
                    u.card = acard
                    u.from = player
                    local targets_list = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(use.from)) do
                        if use.from:inMyAttackRange(p) then
                            targets_list:append(p)
                        end
                    end
                    local victim = room:askForPlayerChosen(player, targets_list, self:objectName(),
                        "@shijin_Collateral_choice:" .. use.from:objectName() .. "::" .. acard:objectName())
                    if victim then
                        local log = sgs.LogMessage()
                        log.type = "#CollateralSlash"
                        log.from = use.from
                        log.to:append(victim)
                        room:sendLog(log)
                        room:doAnimate(1, use.from:objectName(), victim:objectName())
                    end
                    u.to:append(use.from)
                    u.to:append(victim)
                    room:useCard(u)
                else
                    local u = sgs.CardUseStruct()
                    u.card = acard
                    u.from = player
                    u.to:append(use.from)
                    room:useCard(u)
                end
            elseif use.card:isKindOf("Slash") then
                if player:canSlash(use.from, acard) then
                    local u = sgs.CardUseStruct()
                    u.card = acard
                    u.from = player
                    u.to:append(use.from)
                    room:useCard(u)
                end
            end
        end
        return false
    end,
}
NanamiHashimoto_God:addSkill(Luashijin)

--[[
    技能名：三枪
    描述：游戏开始时，你获得三枚”子弹“；出牌阶段限一次，你可以弃置一枚”子弹“令一名其他角色弃置所有手牌。
]]
LuasanqiangCard = sgs.CreateSkillCard {
    name = "LuasanqiangCard",
    skill_name = "Luasanqiang",
    target_fixed = false,
    filter = function(self, targets, to_select, player)
        if not to_select:isKongcheng() and to_select:objectName() ~= player:objectName() then
            return #targets == 0
        end
    end,
    on_effect = function(self, effect)
        effect.from:loseMark("@bullet")
        effect.to:throwAllHandCards()
    end,
}
LuasanqiangVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luasanqiang",
    view_as = function(self)
        return LuasanqiangCard:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@bullet") > 0 and not player:hasUsed("#LuasanqiangCard")
    end,
}
Luasanqiang = sgs.CreateTriggerSkill {
    name = "Luasanqiang",
    events = {sgs.GameStart},
    view_as_skill = LuasanqiangVS,
    on_trigger = function(self, event, player, data, room)
        player:gainMark("@bullet", 3)
        return false
    end,
}
NanamiHashimoto_God:addSkill(Luasanqiang)

--[[
    技能名：无视千年杀
    描述：锁定技，你防止你受到的非属性伤害。
]]
LuaIgnoreKancho = sgs.CreateTriggerSkill {
    name = "LuaIgnoreKancho",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.nature == sgs.DamageStruct_Normal then
            local msg = sgs.LogMessage()
            msg.type = "#IgnoreKanchoProtect"
            msg.from = player
            msg.to:append(damage.from) -- TODO 需修复无来源伤害
            msg.arg = self:objectName()
            room:sendLog(msg)
            room:setEmotion(player, "skill_nullify")
            return true
        end
    end,
}
NanamiHashimoto_God:addSkill(LuaIgnoreKancho)

--[[
    技能名：再见的意义
    描述：锁定技，当你处于濒死状态时其他角色无法对你使用【桃】。
]]
LuaSayonaranoimi = sgs.CreateTriggerSkill {
    name = "LuaSayonaranoimi",
    events = {sgs.AskForPeaches, sgs.AskForPeachesDone},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:hasSkill(self) then
            if event == sgs.AskForPeaches then
                for _, p in sgs.qlist(room:getOtherPlayers(dying.who)) do
                    if not p:hasFlag("sayonara") then
                        p:setFlags("sayonara")
                        room:addPlayerMark(p, "Global_PreventPeach")
                    end
                end
            else
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if p:hasFlag("sayonara") then
                        p:setFlags("-sayonara")
                        room:removePlayerMark(p, "Global_PreventPeach")
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
NanamiHashimoto_God:addSkill(LuaSayonaranoimi)

--[[
    技能名：说不定我们现在生活的地方就是地狱呢
    描述：觉醒技，当你第一次进入濒死状态时，场上所有其他角色获得技能【地狱】。
]]
LuaImaikiterukonosekaigajigokukamoshirenaishi = sgs.CreateTriggerSkill {
    name = "LuaImaikiterukonosekaigajigokukamoshirenaishi",
    events = {sgs.EnterDying},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() == player:objectName() and player:getMark((self:objectName())) == 0 then
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                room:handleAcquireDetachSkills(p, "Luajigoku")
            end
            room:addPlayerMark(player, self:objectName())
        end
        return false
    end,
}
NanamiHashimoto_God:addSkill(LuaImaikiterukonosekaigajigokukamoshirenaishi)

--[[
    技能名：地狱
    描述：锁定技，回合开始时，你须进行一次判定，若判定结果为黑色，直到你的下个回合开始，你的其他技能无效。
]]
Luajigoku = sgs.CreateTriggerSkill {
    name = "Luajigoku",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:getMark("jigoku") ~= 0 then
                room:setPlayerMark(player, "jigoku", 0)
            end
            local judge = sgs.JudgeStruct()
            judge.pattern = ".|black"
            judge.good = false
            judge.negative = true
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            if judge:isBad() then
                player:gainMark("jigoku")
            end
        end
    end,
}
LuajigokuInvalidity = sgs.CreateInvaliditySkill {
    name = "#LuajigokuInvalidity",
    skill_valid = function(self, player, skill)
        if player:getMark("jigoku") ~= 0 then
            return false
        else
            return true
        end
    end,
}
if not sgs.Sanguosha:getSkill("Luajigoku") then
    SKMC.SkillList:append(Luajigoku)
end
if not sgs.Sanguosha:getSkill("#LuajigokuInvalidity") then
    SKMC.SkillList:append(LuajigokuInvalidity)
end
NanamiHashimoto_God:addRelateSkill("Luajigoku")

sgs.LoadTranslationTable {
    ["NanamiHashimoto_God"] = "橋本 奈々未",
    ["&NanamiHashimoto_God"] = "神·橋本 奈々未",
    ["#NanamiHashimoto_God"] = "無冕之王",
    ["designer:NanamiHashimoto_God"] = "Cassimolar",
    ["cv:NanamiHashimoto_God"] = "橋本 奈々未",
    ["illustrator:NanamiHashimoto_God"] = "Cassimolar",
    ["Luashijin"] = "棘人",
    [":Luashijin"] = "当你成为其他角色使用的卡牌的目标时，若其为此牌的合法目标，则视为你对其使用此牌。",
    ["@shijin_Collateral_choice"] = "请为此【 %arg 】选择 %src 使用【杀】的目标",
    ["Luasanqiang"] = "三枪",
    [":Luasanqiang"] = "游戏开始时，你获得三枚“子弹”；出牌阶段限一次，你可以弃置一枚“子弹”令一名其他角色弃置所有手牌。",
    ["@bullet"] = "子弹	",
    ["LuaIgnoreKancho"] = "无视千年杀",
    [":LuaIgnoreKancho"] = "锁定技，防止你受到的非属性伤害。",
    ["#IgnoreKanchoProtect"] = "%from 的【%arg】被触发，防止%to 的非属性伤害",
    ["LuaSayonaranoimi"] = "再见的意义",
    [":LuaSayonaranoimi"] = "锁定技，当你处于濒死状态时其他角色无法对你使用【桃】。",
    ["LuaImaikiterukonosekaigajigokukamoshirenaishi"] = "格言",
    [":LuaImaikiterukonosekaigajigokukamoshirenaishi"] = "觉醒技，当你进入濒死状态时，场上所有其他角色获得技能【地狱】。",
    ["Luajigoku"] = "地狱",
    [":Luajigoku"] = "锁定技，回合开始时，你须进行一次判定，若判定结果为黑色，直到你的下个回合开始，你的其他技能无效。",
}
