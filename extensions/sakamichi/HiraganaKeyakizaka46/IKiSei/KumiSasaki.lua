require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KumiSasaki_HiraganaKeyakizaka = sgs.General(Sakamichi, "KumiSasaki_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 7,
    false, false, false, 3)
SKMC.IKiSei.KumiSasaki_HiraganaKeyakizaka = true
SKMC.SeiMeiHanDan.KumiSasaki_HiraganaKeyakizaka = {
    name = {7, 3, 4, 3, 9},
    ten_kaku = {14, "xiong"},
    jin_kaku = {7, "ji"},
    ji_kaku = {12, "xiong"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {26, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sakmichi_nian_mai = sgs.CreateTriggerSkill {
    name = "sakamichi_nian_mai",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseChanging, sgs.MaxHpChanged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local n = 0
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    n = math.max(p:getSeat(), n)
                end
                if player:getSeat() == n and not room:getTag("ExtraTurn"):toBool() then
                    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                        room:loseMaxHp(p, SKMC.number_correction(p, 1))
                    end
                end
            end
        elseif event == sgs.MaxHpChanged then
            if player:hasSkill(self) then
                room:drawCards(player, player:getLostHp(), self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
KumiSasaki_HiraganaKeyakizaka:addSkill(sakmichi_nian_mai)

sakamichi_xin_lai = sgs.CreateTriggerSkill {
    name = "sakamichi_xin_lai",
    events = {sgs.EventPhaseProceeding, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseProceeding then
            if player:getPhase() == sgs.Player_Start then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if player:objectName() ~= p:objectName() and not p:isKongcheng()
                        and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                            "invoke:" .. player:objectName() .. "::" .. self:objectName())) then
                        room:setPlayerFlag(player, "xin_lai_" .. p:objectName())
                        p:turnOver()
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        dummy:deleteLater()
                        dummy:addSubcards(p:getHandcards())
                        room:moveCardTo(dummy, p, player, sgs.Player_PlaceHand, sgs.CardMoveReason(
                            sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), player:objectName(), self:objectName(),
                            nil))
                    end
                end
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.damage and dying.damage.from and dying.damage.from:getPhase() ~= sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if dying.damage.from:hasFlag("xin_lai_" .. p:objectName()) then
                        if not p:faceUp() then
                            p:turnOver()
                        end
                        if p:isChained() then
                            room:setPlayerChained(p, false)
                        end
                        room:drawCards(p, dying.who:getHandcardNum(), self:objectName())
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
KumiSasaki_HiraganaKeyakizaka:addSkill(sakamichi_xin_lai)

sgs.LoadTranslationTable {
    ["KumiSasaki_HiraganaKeyakizaka"] = "????????? ??????",
    ["&KumiSasaki_HiraganaKeyakizaka"] = "????????? ??????",
    ["#KumiSasaki_HiraganaKeyakizaka"] = "??????",
    ["~KumiSasaki_HiraganaKeyakizaka"] = "??????????????????????????????",
    ["designer:KumiSasaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:KumiSasaki_HiraganaKeyakizaka"] = "????????? ??????",
    ["illustrator:KumiSasaki_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_nian_mai"] = "??????",
    [":sakamichi_nian_mai"] = "???????????????????????????????????????1??????????????????????????????????????????????????????X?????????X?????????????????????????????????",
    ["sakamichi_xin_lai"] = "??????",
    [":sakamichi_xin_lai"] = "???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????X?????????X??????????????????????????????",
    ["sakamichi_xin_lai:invoke"] = "???????????????%arg????????????????????????%src",
}
