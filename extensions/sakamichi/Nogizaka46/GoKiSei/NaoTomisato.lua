require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NaoTomisato = sgs.General(Sakamichi, "NaoTomisato", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.NaoTomisato = true
SKMC.SeiMeiHanDan.NaoTomisato = {
    name = {11, 7, 8, 5},
    ten_kaku = {18, "ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {13, "da_ji"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "tu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sgs.LoadTranslationTable {
    ["NaoTomisato"] = "冨里 奈央",
    ["&NaoTomisato"] = "冨里 奈央",
    ["#NaoTomisato"] = "",
    ["~NaoTomisato"] = "",
    ["designer:NaoTomisato"] = "Cassimolar",
    ["cv:NaoTomisato"] = "冨里 奈央",
    ["illustrator:NaoTomisato"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
