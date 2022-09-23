require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ManamiMatsuoka_Kenshusei = sgs.General(Sakamichi, "ManamiMatsuoka_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.ManamiMatsuoka_Kenshusei = true
SKMC.NiKiSei.ManamiMatsuoka_Kenshusei = true
SKMC.SanKiSei.ManamiMatsuoka_Kenshusei = true
SKMC.YonKiSei.ManamiMatsuoka_Kenshusei = true
SKMC.SeiMeiHanDan.ManamiMatsuoka_Kenshusei = {
    name = {8, 8, 13, 9},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {21, "ji"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {17, "ji"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "mu",
        san_sai = "ji_xiong_hun_he",
    },
}

ManamiMatsuoka_Kenshusei:addSkill("sakamichi_yan_xiu")
ManamiMatsuoka_Kenshusei:addSkill("sakamichi_shu_xin")

sgs.LoadTranslationTable {
    ["ManamiMatsuoka_Kenshusei"] = "松岡 愛美",
    ["&ManamiMatsuoka_Kenshusei"] = "松岡 愛美",
    ["#ManamiMatsuoka_Kenshusei"] = "幻之四期",
    ["~ManamiMatsuoka_Kenshusei"] = "",
    ["designer:ManamiMatsuoka_Kenshusei"] = "Cassimolar",
    ["cv:ManamiMatsuoka_Kenshusei"] = "松岡 愛美",
    ["illustrator:ManamiMatsuoka_Kenshusei"] = "Cassimolar",
}
