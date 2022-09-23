require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MikuniTakahashi_Kenshusei = sgs.General(Sakamichi, "MikuniTakahashi_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.MikuniTakahashi_Kenshusei = true
SKMC.NiKiSei.MikuniTakahashi_Kenshusei = true
SKMC.SanKiSei.MikuniTakahashi_Kenshusei = true
SKMC.YonKiSei.MikuniTakahashi_Kenshusei = true

MikuniTakahashi_Kenshusei:addSkill("sakamichi_yan_xiu")
MikuniTakahashi_Kenshusei:addSkill("sakamichi_bu_fu")

sgs.LoadTranslationTable {
    ["MikuniTakahashi_Kenshusei"] = "髙橋 未来虹",
    ["&MikuniTakahashi_Kenshusei"] = "髙橋 未来虹",
    ["#MikuniTakahashi_Kenshusei"] = "高挑的彩虹",
    ["designer:MikuniTakahashi_Kenshusei"] = "Cassimolar",
    ["cv:MikuniTakahashi_Kenshusei"] = "髙橋 未来虹",
    ["illustrator:MikuniTakahashi_Kenshusei"] = "Cassimolar",
}
