require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MizukiYamashita = sgs.General(Sakamichi, "MizukiYamashita$", "Nogizaka46", 3, false)
SKMC.SanKiSei.MizukiYamashita = true
SKMC.SeiMeiHanDan.MizukiYamashita = {
    name = {3, 3, 9, 4},
    ten_kaku = {6, "da_ji"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {7, "ji"},
    sou_kaku = {19, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

sakamichi_lian_ji = sgs.CreateTriggerSkill {
    name = "sakamichi_lian_ji$",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isNDTrick() or use.card:isKindOf("BasicCard")) and use.to:length() == 1 and use.to:contains(player)
            and player:getKingdom() == "Nogizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:hasLordSkill(self) and not use.card:hasFlag("lian_ji" .. p:objectName())
                    and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                        "invoke:" .. player:objectName() .. "::" .. use.card:objectName())) then
                    room:drawCards(p, 1, self:objectName())
                    room:setCardFlag(use.card, "lian_ji" .. p:objectName())
                    room:useCard(sgs.CardUseStruct(use.card, player, player, true), true)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MizukiYamashita:addSkill(sakamichi_lian_ji)

sakamichi_jing_ye = sgs.CreateTriggerSkill {
    name = "sakamichi_jing_ye",
    frequency = sgs.Skill_Limited,
    limit_mark = "@jing_ye",
    events = {sgs.EventPhaseStart, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:hasSkill(self) and player:getMark("@jing_ye") ~= 0 then
                local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                    "@jing_ye_invoke:::" .. self:objectName(), true)
                if target then
                    room:removePlayerMark(player, "@jing_ye")
                    player:setShownRole(true)
                    SKMC.send_message(room, "#show_role", player, nil, nil, nil, player:getRole())
                    target:setShownRole(true)
                    SKMC.send_message(room, "#show_role", target, nil, nil, nil, target:getRole())
                    local same = false
                    if ((player:getRole() == "lord" or player:getRole() == "loyalist")
                        and (target:getRole() == "lord" or target:getRole() == "loyalist"))
                        or (player:getRole() == "rebel" and target:getRole() == "rebel") then
                        same = true
                    end
                    if same then
                        room:setPlayerMark(target, "HandcardVisible_" .. player:objectName(), 1)
                        room:setPlayerMark(player, "HandcardVisible_" .. target:objectName(), 1)
                    else
                        room:setPlayerMark(target, "&" .. self:objectName() .. "+  +" .. player:getGeneralName(), 1)
                        room:setPlayerMark(target, self:objectName() .. "+" .. player:objectName(), 1)
                        room:setPlayerMark(player, "&" .. self:objectName() .. "+  +" .. target:getGeneralName(), 1)
                        room:setPlayerMark(player, self:objectName() .. "+" .. target:objectName(), 1)
                    end
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getMark(self:objectName() .. "+" .. player:objectName()) ~= 0 then
                    room:loseHp(p, damage.damage)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MizukiYamashita:addSkill(sakamichi_jing_ye)

sakamichi_yin_an = sgs.CreateTriggerSkill {
    name = "sakamichi_yin_an",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and use.card:isBlack() then
            for _, p in sgs.qlist(use.to) do
                local no_respond_list = use.no_respond_list
                if room:askForSkillInvoke(player, self:objectName(),
                    sgs.QVariant(
                        "invoke:" .. p:objectName() .. ":" .. self:objectName() .. ":" .. use.card:objectName() .. ":"
                            .. SKMC.number_correction(player, 1))) then
                    room:damage(sgs.DamageStruct(self:objectName(), p, player, SKMC.number_correction(player, 1)))
                    table.insert(no_respond_list, p:objectName())
                end
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        return false
    end,
}
sakamichi_yin_an_protect = sgs.CreateProhibitSkill {
    name = "#sakamichi_yin_an_protect",
    frequency = sgs.Skill_Compulsory,
    is_prohibited = function(self, from, to, card)
        return to:hasSkill("sakamichi_yin_an") and (card:isKindOf("BasicCard") or card:isKindOf("TrickCard"))
                   and card:isBlack()
    end,
}
MizukiYamashita:addSkill(sakamichi_yin_an)
if not sgs.Sanguosha:getSkill("#sakamichi_yin_an_protect") then
    SKMC.SkillList:append(sakamichi_yin_an_protect)
end

sgs.LoadTranslationTable {
    ["MizukiYamashita"] = "山下 美月",
    ["&MizukiYamashita"] = "山下 美月",
    ["#MizukiYamashita"] = "小恶魔",
    ["~MizukiYamashita"] = "最下位じゃなければ1位",
    ["designer:MizukiYamashita"] = "Cassimolar",
    ["cv:MizukiYamashita"] = "山下 美月",
    ["illustrator:MizukiYamashita"] = "Cassimolar",
    ["sakamichi_lian_ji"] = "恋己",
    [":sakamichi_lian_ji"] = "主公技，乃木坂46势力角色使用基本牌或通常锦囊牌结算完成时，若此牌目标仅为其，你可以摸一张牌令此牌额外结算一次。",
    ["sakamichi_lian_ji:invoke"] = "你可以摸一张牌令%src使用的此【%arg】额外结算一次",
    ["sakamichi_jing_ye"] = "敬业",
    [":sakamichi_jing_ye"] = "限定技，准备阶段，你可以选择一名其他角色，你与其展示身份牌，若你们的胜利条件：相同，本局游戏剩余时间内，你们的手牌互相可见；不同，本局游戏剩余时间内，一方受到伤害后另一方失去等量的体力值。",
    ["@jing_ye"] = "敬业",
    ["#show_role"] = "%from 的身份为%arg",
    ["@jing_ye_invoke"] = "你可以发动选择一名其他角色发动【%arg】",
    ["sakamichi_yin_an"] = "阴暗",
    [":sakamichi_yin_an"] = "锁定技，你不是黑色基本牌/锦囊牌的合法目标。当你使用黑色基本牌/通常锦囊牌指定目标后，你可以受到目标造成的1点伤害令其无法响应此牌。",
    ["sakamichi_yin_an:invoke"] = "是否发动【%dest】受到来自%src的%arg2点伤害并令其无法响应此【%arg】",
}
