require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuriKitagawa = sgs.General(Sakamichi, "YuriKitagawa", "Nogizaka46", 3, false)
SKMC.YonKiSei.YuriKitagawa = true
SKMC.SeiMeiHanDan.YuriKitagawa = {
    name = {5, 3, 11, 11},
    ten_kaku = {8, "ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_sheng_ye_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_sheng_ye",
    filter_pattern = ".|.|.|qi_ji",
    expand_pile = "qi_ji",
    view_as = function(self, card)
        if sgs.Self:hasFlag("sheng_ye_retrial") then
            local cd = sgs.Sanguosha:cloneCard(card)
            cd:addSubcard(card)
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return not player:getPile("qi_ji"):isEmpty() and player:hasFlag("sheng_ye_retrial")
    end,
}
sakamichi_sheng_ye = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_ye",
    view_as_skill = sakamichi_sheng_ye_view_as,
    events = {sgs.StartJudge, sgs.FinishJudge, sgs.AskForRetrial, sgs.CardsMoveOneTime, sgs.EventPhaseProceeding,
        sgs.Death},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if event == sgs.StartJudge then
            if judge.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                        "guess:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. judge.reason)) then
                        local suit_str = sgs.Card_Suit2String(room:askForSuit(p, self:objectName()))
                        SKMC.choice_log(p, suit_str)
                        p:setTag(player:objectName() .. "_" .. self:objectName(), sgs.QVariant(suit_str))
                        room:setPlayerFlag(p, "sheng_ye_used")
                    end
                end
            end
        elseif event == sgs.FinishJudge then
            if judge.who:objectName() == player:objectName() then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("sheng_ye_used") then
                        local suit_str = p:getTag(player:objectName() .. "_" .. self:objectName()):toString()
                        if judge.card:getSuitString() == suit_str then
                            p:addToPile("qi_ji", room:getNCards(1))
                        end
                        room:setPlayerFlag(p, "-sheng_ye_used")
                        p:removeTag(player:objectName() .. "_" .. self:objectName())
                    end
                end
            end
        elseif event == sgs.AskForRetrial then
            if player:hasSkill(self) and not player:getPile("qi_ji"):isEmpty() then
                room:setPlayerFlag(player, "sheng_ye_retrial")
                local card = room:askForCard(player, ".|.|.|qi_ji", "@sheng_ye_card:" .. judge.who:objectName() .. "::"
                    .. judge.reason .. ":" .. judge.card:objectName(), data, sgs.Card_MethodResponse, judge.who, true)
                room:setPlayerFlag(player, "-sheng_ye_retrial")
                if card then
                    room:retrial(card, player, judge, self:objectName())
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to and move.to:objectName() == player:objectName() and player:hasSkill(self) and move.to_place
                and move.to_place == sgs.Player_PlaceSpecial and move.to_pile_name and move.to_pile_name == "qi_ji" then
                room:addPlayerMark(player, "&" .. self:objectName(), move.card_ids:length())
            end
        elseif event == sgs.EventPhaseProceeding then
            if player:hasSkill(self) and player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0
                and player:getMark("&" .. self:objectName()) >= 20 then
                room:sendShimingLog(player, self:objectName())
                while player:getMark("sheng_ye_used") <= player:getMark("&" .. self:objectName()) do
                    local basic_pattern = {}
                    for _, pattern in ipairs(SKMC.Pattern.BasicCard.Slash) do
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                            card:deleteLater()
                            card:setSkillName(self:objectName())
                            if player:canSlash(p, card, false) and not sgs.Sanguosha:isProhibited(player, p, card) then
                                table.insert(basic_pattern, pattern)
                                break
                            end
                        end
                    end
                    for _, pattern in ipairs(SKMC.Pattern.BasicCard) do
                        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                        card:deleteLater()
                        card:setSkillName(self:objectName())
                        if not card:isKindOf("Jink") and not table.contains(basic_pattern, pattern)
                            and not sgs.Sanguosha:isProhibited(player, player, card) then
                            if card:isKindOf("Peach") then
                                if player:isWounded() then
                                    table.insert(basic_pattern, pattern)
                                end
                            else
                                table.insert(basic_pattern, pattern)
                            end
                        end
                    end
                    if #basic_pattern ~= 0 then
                        local pattern = basic_pattern[math.random(1, #basic_pattern)]
                        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                        card:deleteLater()
                        card:setSkillName(self:objectName())
                        if card:isKindOf("Slash") then
                            local target_list = sgs.SPlayerList()
                            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                                if player:canSlash(p, card, false) and not sgs.Sanguosha:isProhibited(player, p, card) then
                                    target_list:append(p)
                                end
                            end
                            if not target_list:isEmpty() then
                                local target_index = math.random(1, target_list:length())
                                local index = 1
                                for _, p in sgs.qlist(target_list) do
                                    if index == target_index then
                                        room:useCard(sgs.CardUseStruct(card, player, p))
                                        room:addPlayerMark(player, "sheng_ye_used")
                                        break
                                    else
                                        index = index + 1
                                    end
                                end
                            end
                        else
                            room:useCard(sgs.CardUseStruct(card, player, player))
                            room:addPlayerMark(player, "sheng_ye_used")
                        end
                    end
                end
                room:setPlayerMark(player, "sheng_ye_used", 0)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() and player:hasSkill(self)
                and player:getMark(self:objectName()) == 0 then
                room:sendShimingLog(player, self:objectName(), false)
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@sheng_ye_chosen:::" .. self:objectName())
                room:handleAcquireDetachSkills(target, self:objectName())
                target:addToPile("qi_ji", player:getPile("qi_ji"))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuriKitagawa:addSkill(sakamichi_sheng_ye)

sakamichi_mi_ma = sgs.CreateTriggerSkill {
    name = "sakamichi_mi_ma",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() and move.to_place and move.to_place
            == sgs.Player_PlaceSpecial then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:drawCards(p, move.card_ids:length(), self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuriKitagawa:addSkill(sakamichi_mi_ma)

sgs.LoadTranslationTable {
    ["YuriKitagawa"] = "北川 悠理",
    ["&YuriKitagawa"] = "北川 悠理",
    ["#YuriKitagawa"] = "创造奇迹",
    ["~YuriKitagawa"] = "奇跡をおこす",
    ["designer:YuriKitagawa"] = "Cassimolar",
    ["cv:YuriKitagawa"] = "北川 悠理",
    ["illustrator:YuriKitagawa"] = "Cassimolar",
    ["sakamichi_sheng_ye"] = "奇迹",
    [":sakamichi_sheng_ye"] = "使命技，一名角色判定开始时，你可以猜测判定结果的花色，若正确你将牌堆顶的一张牌置于你的武将牌上称为「奇迹」；一名角色判定牌生效前，你可以打出一张「奇迹」代替之。成功：准备阶段，若你获得过至少20张「奇迹」，你视为随机使用等量的基本牌。失败，你死亡时，你令一名其他角色获得【奇迹】和你的「奇迹」。",
    ["qi_ji"] = "奇迹",
    ["sakamichi_sheng_ye:guess"] = "是否发动【%arg】猜测%src %arg2的判定牌的花色",
    ["@sheng_ye_card"] = "你可以打出一张「奇迹」来替换 %src 的 %arg 的判定牌 %arg2",
    ["@sheng_ye_chosen"] = "请选择一名其他角色令其获得【%arg】和你的「奇迹」",
    ["sakamichi_mi_ma"] = "密码",
    [":sakamichi_mi_ma"] = "当一张牌移出游戏时，你可以摸一张牌。",
}
