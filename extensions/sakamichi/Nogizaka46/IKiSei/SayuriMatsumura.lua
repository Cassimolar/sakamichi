require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SayuriMatsumura = sgs.General(Sakamichi, "SayuriMatsumura", "Nogizaka46", 3, false)
SKMC.IKiSei.SayuriMatsumura = true
SKMC.SeiMeiHanDan.SayuriMatsumura = {
    name = {8, 7, 7, 4, 11},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {23, "ji"},
    sou_kaku = {37, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

SayuriMatsumura:addSkill("sakamichi_xia_chu")

sakamichi_chi_huo = sgs.CreateTriggerSkill {
    name = "sakamichi_chi_huo",
    events = {sgs.CardFinished, sgs.AskForRetrial},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Peach") then
                local ids = sgs.IntList()
                if use.card:isVirtualCard() then
                    ids = use.card:getSubcards()
                else
                    ids:append(use.card:getEffectiveId())
                end
                if not ids:isEmpty() then
                    local in_discard = true
                    for _, id in sgs.qlist(ids) do
                        if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
                            in_discard = false
                            break
                        end
                    end
                    if in_discard then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if player:objectName() ~= p:objectName()
                                and room:askForSkillInvoke(p, self:objectName(), data) then
                                room:loseHp(p)
                                room:obtainCard(p, use.card, true)
                                break
                            end
                        end
                    end
                end
            end
        elseif event == sgs.AskForRetrial then
            local judge = data:toJudge()
            if judge.who:objectName() == player:objectName() and player:hasSkill(self) and judge.reason
                == "supply_shortage" and room:askForSkillInvoke(player, self:objectName(), data) then
                local id = room:drawCard()
                room:getThread():delay()
                room:retrial(sgs.Sanguosha:getCard(id), player, judge, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
SayuriMatsumura:addSkill(sakamichi_chi_huo)

sakamichi_ping_guo_quan_view_as = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_ping_guo_quan",
    response_pattern = "analeptic",
    filter_pattern = "Peach",
    view_as = function(self, card)
        local cd = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
        cd:setSkillName(self:objectName())
        cd:addSubcard(card)
        return cd
    end,
    enabled_at_play = function(self, player)
        local card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
        card:deleteLater()
        if player:isCardLimited(card, sgs.Card_MethodUse) or player:isProhibited(player, card) then
            return false
        end
        return
            player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, card)
    end,
    enabled_at_response = function(self, player, pattern)
        return string.find(pattern, "analeptic")
    end,
}
sakamichi_ping_guo_quan = sgs.CreateTriggerSkill {
    name = "sakamichi_ping_guo_quan",
    view_as_skill = sakamichi_ping_guo_quan_view_as,
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Analeptic") and use.card:getSkillName() == self:objectName() and player:getPhase()
            ~= sgs.Player_NotActive then
            room:setPlayerFlag(player, "ping_guo_quan")
        end
        if use.card:isKindOf("Slash") and player:hasFlag("ping_guo_quan") then
            room:setPlayerFlag(player, "-ping_guo_quan")
        end
        return false
    end,
}
sakamichi_ping_guo_quan_Mod = sgs.CreateTargetModSkill {
    name = "#sakamichi_ping_guo_quan_Mod",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("sakamichi_ping_guo_quan") and from:hasFlag("ping_guo_quan") then
            return 1000
        else
            return 0
        end
    end,
}
SayuriMatsumura:addSkill(sakamichi_ping_guo_quan)
if not sgs.Sanguosha:getSkill("#sakamichi_ping_guo_quan_Mod") then
    SKMC.SkillList:append(sakamichi_ping_guo_quan_Mod)
end

sgs.LoadTranslationTable {
    ["SayuriMatsumura"] = "松村 沙友理",
    ["&SayuriMatsumura"] = "松村 沙友理",
    ["#SayuriMatsumura"] = "苹果公主",
    ["~SayuriMatsumura"] = "妥協じゃないです！方向転換です",
    ["designer:SayuriMatsumura"] = "Cassimolar",
    ["cv:SayuriMatsumura"] = "松村 沙友理",
    ["illustrator:"] = "Cassimolar",
    ["sakamichi_chi_huo"] = "吃货",
    [":sakamichi_chi_huo"] = "其他角色使用的【桃】结算完成时，你可以失去1点体力从弃牌堆获得之。你的【兵粮寸断】的判定牌生效前，你可以亮出牌堆顶的一张牌代替之。",
    ["sakamichi_ping_guo_quan"] = "苹果拳",
    [":sakamichi_ping_guo_quan"] = "你可以将【桃】当【酒】使用或打出。你的回合内，你以此法使用【酒】后，你使用的下一张【杀】无距离限制。",
}
