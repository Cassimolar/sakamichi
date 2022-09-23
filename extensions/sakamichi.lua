do
    require("lua.config")
    local config = config
    table.removeOne(config.kingdoms, "wei")
    table.removeOne(config.kingdoms, "shu")
    table.removeOne(config.kingdoms, "wu")
    table.removeOne(config.kingdoms, "qun")
    table.removeOne(config.kingdoms, "jin")
    table.removeOne(config.kingdoms, "god")
    table.insert(config.kingdoms, "Nogizaka46")
    table.insert(config.kingdoms, "Keyakizaka46")
    table.insert(config.kingdoms, "HiraganaKeyakizaka46")
    table.insert(config.kingdoms, "Yoshimotozaka46")
    table.insert(config.kingdoms, "Hinatazaka46")
    table.insert(config.kingdoms, "Sakurazaka46")
    table.insert(config.kingdoms, "SakamichiKenshusei")
    table.insert(config.kingdoms, "AutisticGroup")
    table.insert(config.kingdoms, "STU48")
    table.insert(config.kingdoms, "EqualLove")
    table.insert(config.kingdoms, "NotEqualMe")
    table.insert(config.kingdoms, "NearlyEqualJoy")
    table.insert(config.kingdoms, "god")
    table.insert(config.kingdoms, "Zambi")
    config.kingdom_colors.Nogizaka46 = "#7D2982"
    config.kingdom_colors.Keyakizaka46 = "#5EB054"
    config.kingdom_colors.HiraganaKeyakizaka46 = "#5EB054"
    config.kingdom_colors.Yoshimotozaka46 = "#E84709"
    config.kingdom_colors.Hinatazaka46 = "#7CC7E8"
    config.kingdom_colors.Sakurazaka46 = "#F19DB5"
    config.kingdom_colors.SakamichiKenshusei = "#738B95"
    config.kingdom_colors.AutisticGroup = "#8A807A"
    config.kingdom_colors.STU48 = "#CCEBFF"
    config.kingdom_colors.EqualLove = "#FCDBE3"
    config.kingdom_colors.NotEqualMe = "#7CCCC4"
    config.kingdom_colors.NearlyEqualJoy = "#FCE46C"
    config.kingdom_colors.Zambi = "#412BB6"
end

sgs.LoadTranslationTable {
    ["Nogizaka46"] = "乃木坂46",
    ["Keyakizaka46"] = "欅坂46",
    ["HiraganaKeyakizaka46"] = "けやき坂46",
    ["Yoshimotozaka46"] = "吉本坂46",
    ["Hinatazaka46"] = "日向坂46",
    ["Sakurazaka46"] = "櫻坂46",
    ["SakamichiKenshusei"] = "坂道研修生",
    ["AutisticGroup"] = "自闭群",
    ["STU48"] = "STU48",
    ["EqualLove"] = "＝LOVE",
    ["NotEqualMe"] = "≠ME",
    ["NearlyEqualJoy"] = "≒JOY",
    ["Zambi"] = "ザンビ",
}

local sakamichi = {}
do
    require "extensions.sakamichi.card"
    require "extensions.sakamichi.Nogizaka46.Nogizaka46"
    require "extensions.sakamichi.Keyakizaka46.Keyakizaka46"
    require "extensions.sakamichi.HiraganaKeyakizaka46.HiraganaKeyakizaka46"
    -- require "extensions.sakamichi.Yoshimotozaka46.Yoshimotozaka46"
    -- require "extensions.sakamichi.Hinatazaka46.Hinatazaka46"
    require "extensions.sakamichi.SakamichiKenshusei.SakamichiKenshusei"
    require "extensions.sakamichi.Sakurazaka46.Sakurazaka46"
    -- require "extensions.sakamichi.STU48.STU48"
    -- require "extensions.sakamichi.God.God"
    -- require "extensions.sakamichi.AutisticGroup.AutisticGroup"
    -- require "extensions.sakamichi.Zambi.Zambi"
    require "extensions.sakamichi.Avatar"
    table.insert(sakamichi, Sakamichi)
    table.insert(sakamichi, STU48)
    table.insert(sakamichi, SakamichiGod)
    table.insert(sakamichi, Zambi)
    table.insert(sakamichi, SakamichiCard)
    table.insert(sakamichi, SakamichiExclusiveCard)
end

sgs.Sanguosha:addSkills(SKMC.SkillList)

return sakamichi
