require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NagiInoue = sgs.General(Sakamichi, "NagiInoue", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.NagiInoue = true
SKMC.SeiMeiHanDan.NagiInoue = {
    name = {4, 3, 8},
    ten_kaku = {7, "ji"},
    jin_kaku = {11, "ji"},
    ji_kaku = {8, "ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {15, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "xiong",
    },
}

sgs.LoadTranslationTable {
    ["NagiInoue"] = "井上 和",
    ["&NagiInoue"] = "井上 和",
    ["#NagiInoue"] = "",
    ["~NagiInoue"] = "",
    ["designer:NagiInoue"] = "Cassimolar",
    ["cv:NagiInoue"] = "井上 和",
    ["illustrator:NagiInoue"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
