require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkariNibu_HiraganaKeyakizaka = sgs.General(Sakamichi, "AkariNibu_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3, false)
table.insert(SKMC.NiKiSei, "AkariNibu_HiraganaKeyakizaka")

--[[
    技能名：纯真
    描述：锁定技，你的属性【杀】均视为普通【杀】；属性【杀】对你无效。
]]
Luazhichun = sgs.CreateFilterSkill {
    name = "Luazhichun",
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, to_select)
        return to_select:objectName() == "thunder_slash" or to_select:objectName() == "fire_slash"
    end,
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:setSkillName(self:objectName())
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(slash)
        return new
    end,
}
LuazhichunProhibit = sgs.CreateTriggerSkill {
    name = "#LuazhichunProhibit",
    frequency = sgs.Skill_Frequent,
    events = {sgs.SlashEffected},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toSlashEffect()
        if effect.slash:objectName() == "thunder_slash" or effect.slash:objectName() == "fire_slash" then
            room:setEmotion(player, "skill_nullify")
            return true
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill("Luazhichun")
    end,
}
Sakamichi:insertRelatedSkills("Luazhichun", "#LuazhichunProhibit")
AkariNibu_HiraganaKeyakizaka:addSkill(Luazhichun)
AkariNibu_HiraganaKeyakizaka:addSkill(LuazhichunProhibit)

--[[
    技能名：剑道
    描述：当你装备【雌雄双股剑】、【寒冰剑】、【青釭剑】、【古锭刀】时，当你需要使用或打出【杀】时，可以视为使用或打出一张【杀】；出牌阶段开始时，你可以将一张武器牌交给一名其他角色，然后若其装备区有武器牌，你获得之。
]]
LuajiandaoVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luajiandao",
    view_as = function(self)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName(self:objectName())
        return slash
    end,
    enabled_at_play = function(self, player)
        if player:getWeapon() then
            local weapon_name = player:getWeapon():objectName()
            if weapon_name == "double_sword" or weapon_name == "qinggang_sword" or weapon_name == "ice_sword"
                or weapon_name == "guding_blade" or weapon_name == "yitian_sword" or weapon_name == "yx_sword" then
                return sgs.Slash_IsAvailable(player)
            end
        end
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        if player:getWeapon() then
            local weapon_name = player:getWeapon():objectName()
            if weapon_name == "double_sword" or weapon_name == "qinggang_sword" or weapon_name == "ice_sword"
                or weapon_name == "guding_blade" or weapon_name == "yitian_sword" or weapon_name == "yx_sword" then
                return string.find(pattern, "slash") or string.find(pattern, "Slash")
                           and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
            end
        end
        return false
    end,
}
Luajiandao = sgs.CreateTriggerSkill {
    name = "Luajiandao",
    view_as_skill = LuajiandaoVS,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            local card_ids = sgs.IntList()
            if player:getWeapon() then
                card_ids:append(player:getWeapon():getId())
            end
            for _, card in sgs.qlist(player:getHandcards()) do
                if card:isKindOf("Weapon") then
                    card_ids:append(card:getId())
                end
            end
            if not card_ids:isEmpty() then
                local target = room:askForYiji(player, card_ids, self:objectName(), false, false, true, 1,
                    room:getOtherPlayers(player), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,
                        player:objectName(), self:objectName(), nil), "@jiandao_invoke", false)
                if target then
                    if target:getWeapon() and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
                        "get:" .. target:objectName() .. "::" .. target:getWeapon():objectName())) then
                        player:obtainCard(target:getWeapon())
                    end
                end
            end
        end
        return false
    end,
}
AkariNibu_HiraganaKeyakizaka:addSkill(Luajiandao)

--[[
    技能名：诵经
    描述：出牌阶段限一次，你可以令你使用的下一张牌不计入使用次数限制；限定技，当一名角色进入濒死时，你可以令其立即死亡或将体力回复至体力上限。
]]
LuasongjingCard = sgs.CreateSkillCard {
    name = "LuasongjingCard",
    skill_name = "Luasongjing",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "@songjing", 1)
    end,
}
LuasongjingVS = sgs.CreateZeroCardViewAsSkill {
    name = "Luasongjing",
    view_as = function()
        return LuasongjingCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#LuasongjingCard")
    end,
}
Luasongjing = sgs.CreateTriggerSkill {
    name = "Luasongjing",
    frequency = sgs.Skill_Limited,
    limit_mark = "@jing",
    view_as_skill = LuasongjingVS,
    events = {sgs.CardUsed, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and use.from:objectName() == player:objectName()
                and player:hasSkill(self) and player:getMark("songjing") ~= 0 then
                room:setPlayerMark(player, "@songjing", 0)
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
            end
        else
            local dying = data:toDying()
            if dying.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:getMark("@jing") ~= 0 and room:askForSkillInvoke(p, self:objectName(), data) then
                        p:loseMark("@jing")
                        if room:askForChoice(p, self:objectName(), "songjing_1+songjing_2") == "songjing_1" then
                            room:killPlayer(player)
                        else
                            room:recover(player, sgs.RecoverStruct(p, nil, player:getMaxHp() - player:getHp()))
                        end
                        break
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
AkariNibu_HiraganaKeyakizaka:addSkill(Luasongjing)

sgs.LoadTranslationTable {
    ["AkariNibu_HiraganaKeyakizaka"] = "丹生 明里",
    ["&AkariNibu_HiraganaKeyakizaka"] = "丹生 明里",
    ["#AkariNibu_HiraganaKeyakizaka"] = "至純",
    ["designer:AkariNibu_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:AkariNibu_HiraganaKeyakizaka"] = "丹生 明里",
    ["illustrator:AkariNibu_HiraganaKeyakizaka"] = "Cassimolar",
    ["Luazhichun"] = "纯真",
    [":Luazhichun"] = "锁定技，你的属性【杀】均视为普通【杀】；属性【杀】对你无效。",
    ["Luajiandao"] = "剑道",
    [":Luajiandao"] = "当你装备【雌雄双股剑】、【寒冰剑】、【青釭剑】、【古锭刀】时，当你需要使用或打出【杀】时，可以视为使用或打出一张【杀】；出牌阶段开始时，你可以将一张武器牌交给一名其他角色，然后若其装备区有武器牌，你获得之。",
    ["@jiandao_invoke"] = "你可以将一张武器牌交给一名其他角色",
    ["Luajiandao:get"] = "是否获得%src的武器【%arg】",
    ["Luasongjing"] = "诵经",
    [":Luasongjing"] = "出牌阶段限一次，你可以令你使用的下一张牌不计入使用次数限制；限定技，当一名角色进入濒死时，你可以令其立即死亡或将体力回复至体力上限。",
    ["@jing"] = "经",
    ["Luasongjing:songjing_1"] = "令其立即死亡",
    ["Luasongjing:songjing_2"] = "令其体力回复至上限",
    ["@songjing"] = "诵",
}
