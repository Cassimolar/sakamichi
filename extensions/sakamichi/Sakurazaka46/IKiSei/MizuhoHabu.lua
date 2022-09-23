require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MizuhoHabu_Sakurazaka = sgs.General(Sakamichi, "MizuhoHabu_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.IKiSei.MizuhoHabu_Sakurazaka = true
SKMC.SeiMeiHanDan.MizuhoHabu_Sakurazaka = {
    name = {3, 5, 13, 15},
    ten_kaku = {8, "ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {28, "xiong"},
    soto_kaku = {18, "ji"},
    sou_kaku = {36, "xiong"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zhen_tanCard = sgs.CreateSkillCard {
    name = "sakamichi_zhen_tan",
    skill_name = "sakamichi_zhen_tan",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        if source:getMark("zhen_tan") == 0 then
            local suit_str = sgs.Card_Suit2String(room:askForSuit(source, self:getSkillName()))
            SKMC.send_message(room, "#mSuitChose", source, nil, nil, suit_str)
            local result = SKMC.run_judge(room, source, self:getSkillName(), ".|" .. suit_str)
            if result.isGood then
                room:obtainCard(source, result.card)
            else
                room:setPlayerFlag(source, "zhen_tan")
                room:setPlayerMark(source, "zhen_tan", 1)
            end
        else
            local color = room:askForChoice(source, self:objectName(), "red+black")
            SKMC.send_message(room, "#mSuitChose", source, nil, nil, color)
            local result = SKMC.run_judge(room, source, self:getSkillName(), ".|" .. color)
            if result.isGood then
                room:obtainCard(source, result.card)
                room:setPlayerMark(source, "zhen_tan", 0)
            else
                room:setPlayerFlag(source, "zhen_tan")
            end
        end
    end,
}
sakamichi_zhen_tan = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_zhen_tan",
    view_as = function(self)
        return sakamichi_zhen_tanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasFlag("zhen_tan")
    end,
}
MizuhoHabu_Sakurazaka:addSkill(sakamichi_zhen_tan)

sakamichi_shen_zi = sgs.CreateTriggerSkill {
    name = "sakamichi_shen_zi",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") or use.card:isNDTrick() then
            if player:faceUp() and room:askForSkillInvoke(Player, self:objectName(), sgs.QVariant(
                "invoke:::" .. self:objectName() .. ":" .. use.card:objectName())) then
                player:turnOver()
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS")
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
        return false
    end,
}

sgs.LoadTranslationTable {
    ["MizuhoHabu_Sakurazaka"] = "土生 瑞穂",
    ["&MizuhoHabu_Sakurazaka"] = "土生 瑞穂",
    ["#MizuhoHabu_Sakurazaka"] = "名侦探",
    ["~MizuhoHabu_Sakurazaka"] = "そよことです！",
    ["designer:MizuhoHabu_Sakurazaka"] = "Cassimolar",
    ["cv:MizuhoHabu_Sakurazaka"] = "土生 瑞穂",
    ["illustrator:MizuhoHabu_Sakurazaka"] = "Cassimolar",
    ["sakamichi_zhen_tan"] = "侦探",
    [":sakamichi_zhen_tan"] = "出牌阶段限一次，你可以选择一个花色并判定，若结果与你的选择：相同，你获得判定牌且此技能视为未发动过；不同，修改本技能中的花色为颜色直到你以此法获得判定牌。",
    ["sakamichi_shen_zi"] = "神子",
    [":sakamichi_shen_zi"] = "当你使用【杀】或通常锦囊牌时，若你正面向上，你可以翻面令此牌无法响应。",
    ["sakamichi_shen_zi:invoke"] = "是否发动【%arg】令此【%arg2】无法响应",
}
