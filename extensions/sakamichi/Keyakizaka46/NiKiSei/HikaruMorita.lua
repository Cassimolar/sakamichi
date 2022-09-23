require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HikaruMorita_Keyakizaka = sgs.General(Sakamichi, "HikaruMorita_Keyakizaka", "Keyakizaka46", 3, false)
SKMC.NiKiSei.HikaruMorita_Keyakizaka = true
SKMC.SeiMeiHanDan.HikaruMorita_Keyakizaka = {
    name = {12, 5, 2, 3, 3},
    ten_kaku = {17, "ji"},
    jin_kaku = {7, "ji"},
    ji_kaku = {8, "ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {25, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_xiao_ju_ren = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_ju_ren",
    frequency = sgs.Skill_Frequent,
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.to:contains(player) and use.card and use.card:isKindOf("Slash")
                and room:askForSkillInvoke(player, self:objectName(), data) then
                local result = SKMC.run_judge(room, player, self:objectName(), ".|" .. use.card:getSuitString())
                if result.isGood then
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, player:objectName())
                    use.nullified_list = nullified_list
                    data:setValue(use)
                    if room:askForChoice(player, self:objectName(), "xiao_ju_ren_1+xiao_ju_ren_2") == "xiao_ju_ren_1" then
                        room:obtainCard(player, use.card)
                    else
                        room:obtainCard(player, result.card)
                    end
                end
            end
        end
        return false
    end,
}
HikaruMorita_Keyakizaka:addSkill(sakamichi_xiao_ju_ren)

sakamichi_guang_di = sgs.CreateTriggerSkill {
    name = "sakamichi_guang_di",
    frequency = sgs.Skill_Frequent,
    events = {sgs.FinishJudge},
    on_trigger = function(self, event, player, data, room)
        local targets = sgs.SPlayerList()
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
        slash:setSkillName(self:objectName())
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if player:canSlash(p, slash, true) then
                targets:append(p)
            end
        end
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@guang_di_slash", true)
        if target then
            room:useCard(sgs.CardUseStruct(slash, player, target), false)
        end
    end,
}
HikaruMorita_Keyakizaka:addSkill(sakamichi_guang_di)

sgs.LoadTranslationTable {
    ["HikaruMorita_Keyakizaka"] = "森田 ひかる",
    ["&HikaruMorita_Keyakizaka"] = "森田 ひかる",
    ["#HikaruMorita_Keyakizaka"] = "坂道巨人",
    ["~HikaruMorita_Keyakizaka"] = "欅坂46に必要だと思われる人になりたい。",
    ["designer:HikaruMorita_Keyakizaka"] = "Cassimolar",
    ["cv:HikaruMorita_Keyakizaka"] = "森田 ひかる",
    ["illustrator:HikaruMorita_Keyakizaka"] = "Cassimolar",
    ["sakamichi_xiao_ju_ren"] = "小巨人",
    [":sakamichi_xiao_ju_ren"] = "当你成为【杀】的目标后，你可以判定，若结果花色与此【杀】相同，则此【杀】对你无效且你可以选择获得此【杀】或判定牌。",
    ["xiao_ju_ren_1"] = "获得此【杀】",
    ["xiao_ju_ren_2"] = "获得此判定牌",
    ["sakamichi_guang_di"] = "光帝",
    [":sakamichi_guang_di"] = "你的判定牌生效后，你可以视为对攻击范围内的一名其他角色使用了一张【杀】。",
    ["@guang_di_slash"] = "你可以选择一名其他角色视为对其使用一张【杀】",
}