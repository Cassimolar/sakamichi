require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RinaUemura_Keyakizaka = sgs.General(Sakamichi, "RinaUemura_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.IKiSei.RinaUemura_Keyakizaka = true
SKMC.SeiMeiHanDan.RinaUemura_Keyakizaka = {
    name = {3, 7, 10, 11},
    ten_kaku = {10, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {21, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

sakamichi_yao_jing = sgs.CreateTriggerSkill {
    name = "sakamichi_yao_jing",
    events = {sgs.CardUsed, sgs.CardResponded, sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local card = nil
        if event == sgs.TargetConfirming or event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card:getColor() == sgs.Card_Colorless then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not p:getEquips():isEmpty() or p:getJudgingArea():length() > 0 then
                    targets:append(p)
                end
            end
            if targets:length() ~= 0 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@yaojing", true, false)
                if target then
                    local id =
                        room:askForCardChosen(player, target, "ej", self:objectName(), false, sgs.Card_MethodNone)
                    room:moveCardsInToDrawpile(player, id, self:objectName(), 1, false)
                end
            end
        end
        return false
    end,
}
RinaUemura_Keyakizaka:addSkill(sakamichi_yao_jing)

sakamichi_xiao_hao = sgs.CreateViewAsSkill {
    name = "sakamichi_xiao_hao",
    n = 2,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:isEquipped()
        elseif #selected == 1 then
            return selected[1]:getColor() ~= to_select:getColor() and to_select:isEquipped()
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1)
            jink:deleteLater()
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
            slash:deleteLater()
            local cd = nil
            if sgs.Self:getPhase() ~= sgs.Player_NotActive then
                cd = slash
            else
                cd = jink
            end
            for _, c in ipairs(cards) do
                cd:addSubcard(c)
            end
            cd:setSkillName(self:objectName())
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern)
        return (pattern == "jink" and player:getPhase() == sgs.Player_NotActive)
                   or ((string.find(pattern, "slash") or string.find(pattern, "Slash")) and player:getPhase()
                       ~= sgs.Player_NotActive)
    end,
}
RinaUemura_Keyakizaka:addSkill(sakamichi_xiao_hao)

sgs.LoadTranslationTable {
    ["RinaUemura_Keyakizaka"] = "上村 莉菜",
    ["&RinaUemura_Keyakizaka"] = "上村 莉菜",
    ["#RinaUemura_Keyakizaka"] = "千叶妖精",
    ["~RinaUemura_Keyakizaka"] = "だと思うじゃないですか？",
    ["designer:RinaUemura_Keyakizaka"] = "Cassimolar",
    ["cv:RinaUemura_Keyakizaka"] = "上村 莉菜",
    ["illustrator:RinaUemura_Keyakizaka"] = "Cassimolar",
    ["sakamichi_yao_jing"] = "妖精",
    [":sakamichi_yao_jing"] = "当你使用或打出无色卡牌时/成为无色卡牌的目标时，你可以将场上的一张牌置于牌堆顶。",
    ["@yaojing"] = "你可以将场上的一张牌置于牌堆顶",
    ["sakamichi_xiao_hao"] = "小号",
    [":sakamichi_xiao_hao"] = "你的回合内/外，你可以将两张不同颜色的手牌视为【杀】/【闪】使用或打出。",
}
