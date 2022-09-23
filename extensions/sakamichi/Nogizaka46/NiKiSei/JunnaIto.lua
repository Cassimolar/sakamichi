require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

JunnaIto = sgs.General(Sakamichi, "JunnaIto", "Nogizaka46", 4, false)
SKMC.NiKiSei.JunnaIto = true
SKMC.SeiMeiHanDan.JunnaIto = {
    name = {6, 18, 10, 8},
    ten_kaku = {24, "da_ji"},
    jin_kaku = {28, "xiong"},
    ji_kaku = {28, "ji"},
    soto_kaku = {24, "xiong"},
    sou_kaku = {42, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_wen_mo = sgs.CreateTriggerSkill {
    name = "sakamichi_wen_mo",
    events = {sgs.TargetSpecified, sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified then
            if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
                room:setCardFlag(use.card, "wen_mo")
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:distanceTo(player) == SKMC.number_correction(player, 1) and p:getMark("wen_mo") == 0 then
                        room:setPlayerCardLimitation(p, "use,response", ".|.|.|hand", false)
                        room:addPlayerMark(p, "wen_mo")
                        targets:append(p)
                    end
                end
                SKMC.send_message(room, "#wen_mo_target", player, nil, targets, use.card:toString(), self:objectName())
            end
        elseif event == sgs.CardFinished then
            if use.card:hasFlag("wen_mo") then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("wen_mo") ~= 0 then
                        room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand$0")
                        room:setPlayerMark(p, "wen_mo", 0)
                    end
                end
            end
        end
        return false
    end,
}
JunnaIto:addSkill(sakamichi_wen_mo)

sakamichi_dan_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_dan_shi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@dan_shi",
    events = {sgs.EventPhaseStart, sgs.Death},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self)
            and player:getMark("@dan_shi") ~= 0 and room:askForSkillInvoke(player, self:objectName(), data) then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@dan_shi_invoke:::" .. self:objectName())
            if target then
                room:removePlayerMark(player, "@dan_shi")
                room:setFixedDistance(target, player, 1)
                room:setPlayerMark(target, "&" .. self:objectName() .. "+" .. player:getGeneralName(), 1)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if death.who:getMark("&" .. self:objectName() .. "+" .. p:getGeneralName()) ~= 0 then
                    room:removeFixedDistance(death.who, p, 1)
                    room:setPlayerMark(death.who, "&" .. self:objectName() .. "+" .. p:getGeneralName(), 0)
                    if p:hasSkill(self) and death.damage and death.damage.from and death.damage.from:objectName()
                        == p:objectName() then
                        room:setPlayerMark(p, "@dan_shi", 1)
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
JunnaIto:addSkill(sakamichi_dan_shi)

sgs.LoadTranslationTable {
    ["JunnaIto"] = "伊藤 純奈",
    ["&JunnaIto"] = "伊藤 純奈",
    ["#JunnaIto"] = "年龄诈称",
    ["~JunnaIto"] = "あなたはクチビルオバケに恋をする",
    ["designer:JunnaIto"] = "Cassimolar",
    ["cv:JunnaIto"] = "伊藤 純奈",
    ["illustrator:JunnaIto"] = "Cassimolar",
    ["sakamichi_wen_mo"] = "吻魔",
    [":sakamichi_wen_mo"] = "锁定技，当你使用基本牌或通常锦囊牌指定目标后，距离你为1的角色无法使用或打出手牌直到此牌结算完毕。",
    ["#wen_mo_target"] = "%from 的【%arg】被触发，%to 无法使用或打出手牌直到【%card】结算完毕",
    ["sakamichi_dan_shi"] = "胆识",
    [":sakamichi_dan_shi"] = "限定技，准备阶段，你可以选择一名其他角色，令其本局游戏剩余时间与你的距离锁定为1，该角色死亡时，若凶手是你，此技能视未发动过。",
    ["@dan_shi"] = "胆识",
    ["@dan_shi_invoke"] = "你可以发动【%arg】选择一名其他角色令其与你的距离锁定为1",
}
