require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikaOzeki_Keyakizaka = sgs.General(Sakamichi, "RikaOzeki_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.RikaOzeki_Keyakizaka = true
SKMC.SeiMeiHanDan.RikaOzeki_Keyakizaka = {
    name = {7, 14, 11, 9},
    ten_kaku = {21, "ji"},
    jin_kaku = {25, "ji"},
    ji_kaku = {20, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {41, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "tu",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_qi_xing = sgs.CreateFilterSkill {
    name = "sakamichi_qi_xing",
    frequency = sgs.Skill_Compulsory,
    view_filter = function(self, to_select)
        return string.find(to_select:objectName(), "slash") or to_select:objectName() == "jink"
    end,
    view_as = function(self, card)
        local cd
        if string.find(card:objectName(), "slash") then
            cd = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
            cd:setSkillName(self:objectName())
        else
            cd = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
            cd:setSkillName(self:objectName())
        end
        local new = sgs.Sanguosha:getWrappedCard(card:getId())
        new:takeOver(cd)
        return new
    end,
}
RikaOzeki_Keyakizaka:addSkill(sakamichi_qi_xing)

sakamichi_shi_jiang = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_jiang",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") then
            if not use.card:isVirtualCard() then
                if use.card:objectName() ~= sgs.Sanguosha:getCard(use.card:getEffectiveId()):objectName() then
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        if room:askForSkillInvoke(p, self:objectName(),
                            sgs.QVariant("@shi_jiang_invoke:" .. player:objectName())) then
                            room:drawCards(player, 1, self:objectName())
                        end
                    end
                end
            else
                if use.card:subcardsLength() > 0 then
                    local can_trigger = false
                    for _, id in sgs.qlist(use.card:getSubcards()) do
                        if use.card:objectName() ~= sgs.Sanguosha:getCard(id):objectName() then
                            can_trigger = true
                            break
                        end
                    end
                    if can_trigger then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if room:askForSkillInvoke(p, self:objectName(),
                                sgs.QVariant("@shi_jiang_invoke:" .. player:objectName())) then
                                room:drawCards(player, 1, self:objectName())
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
RikaOzeki_Keyakizaka:addSkill(sakamichi_shi_jiang)

sgs.LoadTranslationTable {
    ["RikaOzeki_Keyakizaka"] = "?????? ??????",
    ["&RikaOzeki_Keyakizaka"] = "?????? ??????",
    ["#RikaOzeki_Keyakizaka"] = "????????????",
    ["~RikaOzeki_Keyakizaka"] = "?????????????????????",
    ["designer:RikaOzeki_Keyakizaka"] = "Cassimolar",
    ["cv:RikaOzeki_Keyakizaka"] = "?????? ??????",
    ["illustrator:RikaOzeki_Keyakizaka"] = "Cassimolar",
    ["sakamichi_qi_xing"] = "??????",
    [":sakamichi_qi_xing"] = "??????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_shi_jiang"] = "??????",
    [":sakamichi_shi_jiang"] = "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["sakamichi_shi_jiang:@shi_jiang_invoke"] = "???????????????????????????%src????????????",
}
