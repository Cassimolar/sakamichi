require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MarieMorimoto_Kenshusei = sgs.General(Sakamichi, "MarieMorimoto_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.MarieMorimoto_Kenshusei = true
SKMC.NiKiSei.MarieMorimoto_Kenshusei = true
SKMC.SanKiSei.MarieMorimoto_Kenshusei = true
SKMC.YonKiSei.MarieMorimoto_Kenshusei = true

MarieMorimoto_Kenshusei:addSkill("sakamichi_yan_xiu")
MarieMorimoto_Kenshusei:addSkill("Luachaonao")

sgs.LoadTranslationTable {
    ["MarieMorimoto_Kenshusei"] = "森本 茉莉",
    ["&MarieMorimoto_Kenshusei"] = "森本 茉莉",
    ["#MarieMorimoto_Kenshusei"] = "瑪麗摩托",
    ["designer:MarieMorimoto_Kenshusei"] = "Cassimolar",
    ["cv:MarieMorimoto_Kenshusei"] = "森本 茉莉",
    ["illustrator:MarieMorimoto_Kenshusei"] = "Cassimolar",
}
