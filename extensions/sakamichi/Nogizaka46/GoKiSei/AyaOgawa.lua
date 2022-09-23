require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AyaOgawa = sgs.General(Sakamichi, "AyaOgawa", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.AyaOgawa = true
SKMC.SeiMeiHanDan.AyaOgawa = {
    name = {3, 3, 11},
    ten_kaku = {6, "da_ji"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {11, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {17, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "mu",
        san_sai = "da_ji",
    },
}

sgs.LoadTranslationTable {
    ["AyaOgawa"] = "小川 彩",
    ["&AyaOgawa"] = "小川 彩",
    ["#AyaOgawa"] = "",
    ["~AyaOgawa"] = "",
    ["designer:AyaOgawa"] = "Cassimolar",
    ["cv:AyaOgawa"] = "小川 彩",
    ["illustrator:AyaOgawa"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
