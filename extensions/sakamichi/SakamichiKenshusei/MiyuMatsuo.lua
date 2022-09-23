require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MiyuMatsuo_Kenshusei = sgs.General(Sakamichi, "MiyuMatsuo_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.MiyuMatsuo_Kenshusei = true
SKMC.NiKiSei.MiyuMatsuo_Kenshusei = true
SKMC.SanKiSei.MiyuMatsuo_Kenshusei = true
SKMC.YonKiSei.MiyuMatsuo_Kenshusei = true
SKMC.SeiMeiHanDan.MiyuMatsuo_Kenshusei = {
    name = {8, 7, 9, 7},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {16, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

MiyuMatsuo_Kenshusei:addSkill("sakamichi_yan_xiu")
MiyuMatsuo_Kenshusei:addSkill("sakamichi_zhuan_zhe")

sgs.LoadTranslationTable {
    ["MiyuMatsuo_Kenshusei"] = "松尾 美佑",
    ["&MiyuMatsuo_Kenshusei"] = "松尾 美佑",
    ["#MiyuMatsuo_Kenshusei"] = "文武双全",
    ["~MiyuMatsuo_Kenshusei"] = "あん？",
    ["designer:MiyuMatsuo_Kenshusei"] = "Cassimolar",
    ["cv:MiyuMatsuo_Kenshusei"] = "松尾 美佑",
    ["illustrator:MiyuMatsuo_Kenshusei"] = "Cassimolar",
}
