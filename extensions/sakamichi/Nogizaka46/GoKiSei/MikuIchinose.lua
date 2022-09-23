require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MikuIchinose = sgs.General(Sakamichi, "MikuIchinose", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.MikuIchinose = true
SKMC.SeiMeiHanDan.MikuIchinose = {
    name = {1, 1, 19, 9, 8},
    ten_kaku = {21, "ji"},
    jin_kaku = {28, "xiong"},
    ji_kaku = {17, "ji"},
    soto_kaku = {10, "xiong"},
    sou_kaku = {38, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sgs.LoadTranslationTable {
    ["MikuIchinose"] = "一ノ瀬 美空",
    ["&MikuIchinose"] = "一ノ瀬 美空",
    ["#MikuIchinose"] = "",
    ["~MikuIchinose"] = "",
    ["designer:MikuIchinose"] = "Cassimolar",
    ["cv:MikuIchinose"] = "一ノ瀬 美空",
    ["illustrator:MikuIchinose"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
