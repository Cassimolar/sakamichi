require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikoMatsudaira_Sakurazaka = sgs.General(Sakamichi, "RikoMatsudaira_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.NiKiSei.RikoMatsudaira_Sakurazaka = true
SKMC.SeiMeiHanDan.RikoMatsudaira_Sakurazaka = {
    name = {8, 5, 15, 3},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {18, "ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "shui",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_shi_xian = sgs.CreateTriggerSkill {
    name = "sakamichi_shi_xian",
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
            "shi_xian_invoke", true, false)
        if target then
            room:setPlayerMark(player, "HandcardVisible_" .. target:objectName(), 1)
        end
        return false
    end,
}
RikoMatsudaira_Sakurazaka:addSkill(sakamichi_shi_xian)

RikoMatsudaira_Sakurazaka:addSkill("sakamichi_mi_zi")

sakamichi_jiao_meng = sgs.CreateTriggerSkill {
    name = "sakamichi_jiao_meng",
    events = {sgs.TargetConfirmed, sgs.TargetSpecified, sgs.Damaged, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if player:hasSkill(self) and use.card:isKindOf("Slash") and use.from:objectName() ~= player:objectName()
                and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
                room:loseHp(player, 1)
                local id = room:askForCardChosen(player, use.from, "he", self:objectName())
                room:obtainCard(player, sgs.Sanguosha:getCard(id), room:getCardPlace(id) ~= sgs.Player_PlaceHand)
                room:setCardFlag(use.card, "jiao_meng")
                room:setCardFlag(use.card, "jiao_meng" .. player:objectName())
            end
        elseif event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if player:hasSkill(self) and use.card:isKindOf("Slash") and not use.to:contains(player)
                and room:askForSkillInvoke(player, self:objectName(), data) then
                for _, p in sgs.qlist(use.to) do
                    room:loseHp(player, SKMC.number_correction(player, 1))
                    local id = room:askForCardChosen(player, p, "he", self:objectName())
                    room:obtainCard(player, sgs.Sanguosha:getCard(id), room:getCardPlace(id) ~= sgs.Player_PlaceHand)
                    room:setCardFlag(use.card, "jiao_meng")
                    room:setCardFlag(use.card, "jiao_meng" .. player:objectName())
                end
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("jiao_meng") then
                room:setCardFlag(damage.card, "-jiao_meng")
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:hasFlag("jiao_meng") then
                if use.card:hasFlag("jiao_meng" .. use.from:objectName()) then
                    if use.from:isWounded() then
                        room:recover(use.from,
                            sgs.RecoverStruct(use.from, use.card, SKMC.number_correction(use.from, 1)))
                    end
                    room:setCardFlag(use.card, "-jiao_meng" .. use.from:objectName())
                end
                for _, p in sgs.qlist(use.to) do
                    if use.card:hasFlag("jiao_meng" .. p:objectName()) then
                        if p:isWounded() then
                            room:recover(p, sgs.RecoverStruct(use.from, use.card, SKMC.number_correction(p, 1)))
                        end
                        room:setCardFlag(use.card, "-jiao_meng" .. p:objectName())
                    end
                end
                room:setCardFlag(use.card, "-jiao_meng")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RikoMatsudaira_Sakurazaka:addSkill(sakamichi_jiao_meng)

sgs.LoadTranslationTable {
    ["RikoMatsudaira_Sakurazaka"] = "松平 璃子",
    ["&RikoMatsudaira_Sakurazaka"] = "松平 璃子",
    ["#RikoMatsudaira_Sakurazaka"] = "人设迷走",
    ["~RikoMatsudaira_Sakurazaka"] = "そしたら１秒でもずつと一緒に居られるよね？",
    ["designer:RikoMatsudaira_Sakurazaka"] = "Cassimolar",
    ["cv:RikoMatsudaira_Sakurazaka"] = "松平 璃子",
    ["illustrator:RikoMatsudaira_Sakurazaka"] = "Cassimolar",
    ["sakamichi_shi_xian"] = "视线",
    [":sakamichi_shi_xian"] = "游戏开始时，你可以选择一名其他角色，本局游戏中，其手牌始终对你可见（其他角色无法得知你所选择的角色）。",
    ["shi_xian_invoke"] = "你可以选择一名其他角色，其手牌始终对你可见",
    ["sakamichi_jiao_meng"] = "娇萌",
    [":sakamichi_jiao_meng"] = "当你成为其他角色使用【杀】的目标后/你使用【杀】指定其他角色为目标后，你可以失去1点体力获得其一张牌，若此【杀】未造成伤害，你回复1点体力。",
}
