require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

IrohaOkuda = sgs.General(Sakamichi, "IrohaOkuda", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.IrohaOkuda = true
SKMC.SeiMeiHanDan.IrohaOkuda = {
    name = {12, 5, 2, 2, 4},
    ten_kaku = {17, "ji"},
    jin_kaku = {7, "ji"},
    ji_kaku = {8, "ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {25, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sgs.LoadTranslationTable {
    ["IrohaOkuda"] = "奥田 いろは",
    ["&IrohaOkuda"] = "奥田 いろは",
    ["#IrohaOkuda"] = "",
    ["~IrohaOkuda"] = "",
    ["designer:IrohaOkuda"] = "Cassimolar",
    ["cv:IrohaOkuda"] = "奥田 いろは",
    ["illustrator:IrohaOkuda"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
