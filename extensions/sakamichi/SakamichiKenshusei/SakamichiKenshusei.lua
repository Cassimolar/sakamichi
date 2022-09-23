require "extensions.sakamichi.SKMC"

sakamichi_yan_xiu = sgs.CreateTriggerSkill {
    name = "sakamichi_yan_xiu",
    frequency = sgs.Skill_Wake,
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.HpLost, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 0 then
                if player:getMark("@yan_xiu") ~= 0 then
                    if string.find(player:getGeneralName(), "Kenshusei") then
                        room:changeHero(player, string.gsub(player:getGeneralName(), "_Kenshusei", ""), true, true,
                            false, true)
                        room:setPlayerMark(player, self:objectName(), 1)
                        room:setPlayerMark(player, "@yan_xiu", 0)
                    elseif string.find(player:getGeneral2Name(), "Kenshusei") then
                        room:changeHero(player, string.gsub(player:getGeneral2Name(), "_Kenshusei", ""), true, true,
                            true, true)
                        room:setPlayerMark(player, self:objectName(), 1)
                        room:setPlayerMark(player, "@yan_xiu", 0)
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Finish then
                if player:getMark(self:objectName()) == 0 then
                    room:addPlayerMark(player, "@yan_xiu", 1)
                end
            end
        elseif event == sgs.HpLost or event == sgs.Damaged then
            if player:getMark(self:objectName()) == 0 and player:getMark("@yan_xiu") ~= 0 then
                room:setPlayerMark(player, "@yan_xiu", 0)
            end
        end
        return false
    end,
}
if not sgs.Sanguosha:getSkill("sakamichi_yan_xiu") then
    SKMC.SkillList:append(sakamichi_yan_xiu)
end

sgs.LoadTranslationTable {
    ["sakamichi_yan_xiu"] = "研修",
    [":sakamichi_yan_xiu"] = "觉醒技，准备阶段，若你为坂道研修生且上个结束阶段后未失去过体力或受到伤害，你将被分配。",
}

-- require "extensions.sakamichi.SakamichiKenshusei.MarieMorimoto"
require "extensions.sakamichi.SakamichiKenshusei.RunaHayashi"
require "extensions.sakamichi.SakamichiKenshusei.HarukaKuromi"
require "extensions.sakamichi.SakamichiKenshusei.RenaMoriya"
require "extensions.sakamichi.SakamichiKenshusei.NaoYumiki"
require "extensions.sakamichi.SakamichiKenshusei.MarinoKousaka"
require "extensions.sakamichi.SakamichiKenshusei.ReiOozono"
require "extensions.sakamichi.SakamichiKenshusei.RikaSato"
-- require "extensions.sakamichi.SakamichiKenshusei.MikuniTakahashi"
require "extensions.sakamichi.SakamichiKenshusei.HikariEndo"
require "extensions.sakamichi.SakamichiKenshusei.ManamiMatsuoka"
require "extensions.sakamichi.SakamichiKenshusei.MiyuMatsuo"
require "extensions.sakamichi.SakamichiKenshusei.KiraMasumoto"
require "extensions.sakamichi.SakamichiKenshusei.AkihoOnuma"
-- require "extensions.sakamichi.SakamichiKenshusei.HaruyoYamaguchi"
