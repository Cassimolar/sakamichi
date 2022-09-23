require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RiriaIto = sgs.General(Sakamichi, "RiriaIto", "Nogizaka46", 4, false)
SKMC.SanKiSei.RiriaIto = true
SKMC.SeiMeiHanDan.RiriaIto = {
    name = {6, 18, 11, 3, 7},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {29, "te_shu_ge"},
    ji_kaku = {21, "ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {45, "ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "tu",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_fa_kun = sgs.CreateTriggerSkill {
    name = "sakamichi_fa_kun",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseProceeding, sgs.TurnedOver},
    on_trigger = function(self, event, player, data, room)
        if (event == sgs.CardUsed or event == sgs.CardResponded) and player:getPhase() == sgs.Player_Play then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if not card:isKindOf("SkillCard") then
                room:addPlayerMark(player, "fa_kun_used_" .. SKMC.true_name(card) .. "_finish_end_clear", 1)
            end
        elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "fa_kun_used_") and player:getMark(mark) >= 2 then
                    player:turnOver()
                end
            end
        elseif event == sgs.TurnedOver then
            if player:faceUp() then
                room:drawCards(player, 3, self:objectName())
                room:askForUseCard(player, "slash", "@askforslash")
            else
                if player:isWounded() then
                    room:recover(player, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                end
            end
        end
        return false
    end,
}
RiriaIto:addSkill(sakamichi_fa_kun)

sakamichi_pi_ka = sgs.CreateFilterSkill {
    name = "sakamichi_pi_ka",
    view_filter = function(self, card)
        return card:isKindOf("DelayedTrick")
    end,
    view_as = function(self, card)
        local FuLei = sgs.Sanguosha:cloneCard("FuLei", card:getSuit(), card:getNumber())
        FuLei:setSkillName(self:objectName())
        local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
        wrap:takeOver(FuLei)
        return wrap
    end,
}
sakamichi_pi_ka_damage = sgs.CreateTriggerSkill {
    name = "#sakamichi_pi_ka_damage",
    frequency = sgs.Skill_Compulsory,
    global = true,
    events = {sgs.ConfirmDamage, sgs.DamageInflicted},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            damage.nature = sgs.DamageStruct_Thunder
            data:setValue(damage)
        else
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Thunder then
                SKMC.send_message(room, "#pi_ka", damage.to, nil, nil, nil, "sakamichi_pi_ka")
                room:setEmotion(damage.to, "skill_nullify")
                return true
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill("sakamichi_pi_ka")
    end,
}
RiriaIto:addSkill(sakamichi_pi_ka)
if not sgs.Sanguosha:getSkill("#sakamichi_pi_ka_damage") then
    SKMC.SkillList:append(sakamichi_pi_ka_damage)
end

sgs.LoadTranslationTable {
    ["RiriaIto"] = "伊藤 理々杏",
    ["&RiriaIto"] = "伊藤 理々杏",
    ["#RiriaIto"] = "南国之风",
    ["~RiriaIto"] = "乃木坂に南国の風を吹かせます",
    ["designer:RiriaIto"] = "Cassimolar",
    ["cv:RiriaIto"] = "伊藤 理々杏",
    ["illustrator:RiriaIto"] = "Cassimolar",
    ["sakamichi_fa_kun"] = "乏困",
    [":sakamichi_fa_kun"] = "锁定技，结束阶段，若本回合出牌阶段你使用过至少两张同名卡牌，你翻面；你牌翻至背面/正面向上时回复1点体力/摸三张牌并可以使用一张【杀】。",
    ["sakamichi_pi_ka"] = "皮卡",
    [":sakamichi_pi_ka"] = "锁定技，你的延时类锦囊均视为【浮雷】。你造成的伤害均为雷电伤害。防止你受到的雷电伤害。",
    ["#pi_ka"] = "%from 的【%arg】被触发，%from 受到的此次雷电伤害被防止",
}
