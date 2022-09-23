require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

FuyukaSaito_Keyakizaka = sgs.General(Sakamichi, "FuyukaSaito_Keyakizaka", "Keyakizaka46", 4, false)
SKMC.IKiSei.FuyukaSaito = true
SKMC.SeiMeiHanDan.FuyukaSaito = {
    name = {17, 18, 5, 17, 7},
    ten_kaku = {35, "ji"},
    jin_kaku = {23, "ji"},
    ji_kaku = {29, "te_shu_ge"},
    soto_kaku = {41, "ji"},
    sou_kaku = {64, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "shui",
        san_sai = "xiong",
    },
}

sakamichi_tuan_ai = sgs.CreateTriggerSkill {
    name = "sakamichi_tuan_ai",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if player:getKingdom() == "Keyakizaka46" then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:drawCards(p, 1, self:objectName())
                end
            end
        end
        if player:hasSkill(self) then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:getKingdom() == "Keyakizaka46" then
                    targets:append(p)
                end
            end
            if targets:length() ~= 0 then
                local target =
                    room:askForPlayerChosen(player, targets, self:objectName(), "@tuanai_invoke", true, false)
                if target then
                    room:drawCards(target, 1, self:objectName())
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
FuyukaSaito_Keyakizaka:addSkill(sakamichi_tuan_ai)

sakamichi_jia_zhang = sgs.CreateTriggerSkill {
    name = "sakamichi_jia_zhang",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") and not use.card:isKindOf("SkillCard") then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isWounded() then
                    targets:append(p)
                end
            end
            if targets:length() ~= 0 then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@jia_zhang_invoke", true,
                    false)
                if target then
                    for _, p in sgs.qlist(use.to) do
                        use.to:removeOne(p)
                    end
                    use.to:append(target)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}
FuyukaSaito_Keyakizaka:addSkill(sakamichi_jia_zhang)

sgs.LoadTranslationTable {
    ["FuyukaSaito_Keyakizaka"] = "齋藤 冬優花",
    ["&FuyukaSaito_Keyakizaka"] = "齋藤 冬優花",
    ["#FuyukaSaito_Keyakizaka"] = "裏隊長",
    ["~FuyukaSaito_Keyakizaka"] = "この腹が見えねえだ！",
    ["designer:FuyukaSaito_Keyakizaka"] = "Cassimolar",
    ["cv:FuyukaSaito_Keyakizaka"] = "齋藤 冬優花",
    ["illustrator:FuyukaSaito_Keyakizaka"] = "Cassimolar",
    ["sakamichi_tuan_ai"] = "团爱",
    [":sakamichi_tuan_ai"] = "其他欅坂46势力的角色回复体力时，你可以摸一张牌；你回复体力时，你可以令一名其他欅坂46势力的角色摸一张牌。",
    ["@tuanai_invoke"] = "你可以令一名其他“欅坂46”势力的角色摸一张牌",
    ["sakamichi_jia_zhang"] = "家长",
    [":sakamichi_jia_zhang"] = "当你使用【桃】时，你可以选择一名其他角色，令其成为此【桃】的目标。",
    ["@jia_zhang_invoke"] = "你可以选择一名受伤的其他角色令其成为此【桃】的目标",
}
