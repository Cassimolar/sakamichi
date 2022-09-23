require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RunaHayashi_Kenshusei = sgs.General(Sakamichi, "RunaHayashi_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.RunaHayashi_Kenshusei = true
SKMC.NiKiSei.RunaHayashi_Kenshusei = true
SKMC.SanKiSei.RunaHayashi_Kenshusei = true
SKMC.YonKiSei.RunaHayashi_Kenshusei = true
SKMC.SeiMeiHanDan.RunaHayashi_Kenshusei = {
    name = {8, 14, 8},
    ten_kaku = {8, "ji"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {30, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

RunaHayashi_Kenshusei:addSkill("sakamichi_yan_xiu")
RunaHayashi_Kenshusei:addSkill("sakamichi_fan_lai")

sgs.LoadTranslationTable {
    ["RunaHayashi_Kenshusei"] = "林 瑠奈",
    ["&RunaHayashi_Kenshusei"] = "林 瑠奈",
    ["#RunaHayashi_Kenshusei"] = "林皇",
    ["~RunaHayashi_Kenshusei"] = "ライスください",
    ["designer:RunaHayashi_Kenshusei"] = "Cassimolar",
    ["cv:RunaHayashi_Kenshusei"] = "林 瑠奈",
    ["illustrator:RunaHayashi_Kenshusei"] = "Cassimolar",
}
