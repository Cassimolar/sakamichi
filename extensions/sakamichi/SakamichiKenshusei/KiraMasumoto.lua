require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KiraMasumoto_Kenshusei = sgs.General(Sakamichi, "KiraMasumoto_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.KiraMasumoto_Kenshusei = true
SKMC.NiKiSei.KiraMasumoto_Kenshusei = true
SKMC.SanKiSei.KiraMasumoto_Kenshusei = true
SKMC.YonKiSei.KiraMasumoto_Kenshusei = true
SKMC.SeiMeiHanDan.KiraMasumoto_Kenshusei = {
    name = {14, 5, 14, 7},
    ten_kaku = {19, "xiong"},
    jin_kaku = {19, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {21, "ji"},
    sou_kaku = {40, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "shui",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

KiraMasumoto_Kenshusei:addSkill("sakamichi_yan_xiu")
KiraMasumoto_Kenshusei:addSkill("sakamichi_mi_yan")

sgs.LoadTranslationTable {
    ["KiraMasumoto_Kenshusei"] = "増本 綺良",
    ["&KiraMasumoto_Kenshusei"] = "増本 綺良",
    ["#KiraMasumoto_Kenshusei"] = "天马行空",
    ["~KiraMasumoto_Kenshusei"] = "私、虫は触れるのにダンボール触れないんです。",
    ["designer:KiraMasumoto_Kenshusei"] = "Cassimolar",
    ["cv:KiraMasumoto_Kenshusei"] = "増本 綺良",
    ["illustrator:KiraMasumoto_Kenshusei"] = "Cassimolar",
}
