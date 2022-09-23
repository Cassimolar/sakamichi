require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HarukaKuromi_Kenshusei = sgs.General(Sakamichi, "HarukaKuromi_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.HarukaKuromi_Kenshusei = true
SKMC.NiKiSei.HarukaKuromi_Kenshusei = true
SKMC.SanKiSei.HarukaKuromi_Kenshusei = true
SKMC.YonKiSei.HarukaKuromi_Kenshusei = true
SKMC.SeiMeiHanDan.HarukaKuromi_Kenshusei = {
    name = {11, 7, 8, 9},
    ten_kaku = {18, "ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {20, "xiong"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "da_ji",
    },
}

HarukaKuromi_Kenshusei:addSkill("sakamichi_yan_xiu")
HarukaKuromi_Kenshusei:addSkill("sakamichi_san_liu_jiu")

sgs.LoadTranslationTable {
    ["HarukaKuromi_Kenshusei"] = "黒見 明香",
    ["&HarukaKuromi_Kenshusei"] = "黒見 明香",
    ["#HarukaKuromi_Kenshusei"] = "功夫美少女",
    ["~HarukaKuromi_Kenshusei"] = "考えるな感じろ",
    ["designer:HarukaKuromi_Kenshusei"] = "Cassimolar",
    ["cv:HarukaKuromi_Kenshusei"] = "黒見 明香",
    ["illustrator:HarukaKuromi_Kenshusei"] = "Cassimolar",
}
