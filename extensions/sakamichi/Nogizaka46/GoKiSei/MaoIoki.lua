require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaoIoki = sgs.General(Sakamichi, "MaoIoki", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.MaoIoki = true
SKMC.SeiMeiHanDan.MaoIoki = {
    name = {4, 6, 9, 8, 5},
    ten_kaku = {19, "xiong"},
    jin_kaku = {17, "ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "huo",
        san_sai = "xiong",
    },
}

sgs.LoadTranslationTable {
    ["MaoIoki"] = "五百城 茉央",
    ["&MaoIoki"] = "五百城 茉央",
    ["#MaoIoki"] = "",
    ["~MaoIoki"] = "",
    ["designer:MaoIoki"] = "Cassimolar",
    ["cv:MaoIoki"] = "五百城 茉央",
    ["illustrator:MaoIoki"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
