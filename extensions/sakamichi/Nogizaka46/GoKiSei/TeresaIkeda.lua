require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

TeresaIkeda = sgs.General(Sakamichi, "TeresaIkeda", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.TeresaIkeda = true
SKMC.SeiMeiHanDan.TeresaIkeda = {
    name = {6, 5, 12, 10},
    ten_kaku = {11, "ji"},
    jin_kaku = {17, "ji"},
    ji_kaku = {22, "xiong"},
    soto_kaku = {16, "da_ji"},
    sou_kaku = {33, "te_shu_ge"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "jin",
        ji_kaku = "mu",
        san_sai = "xiong",
    },
}

sgs.LoadTranslationTable {
    ["TeresaIkeda"] = "池田 瑛紗",
    ["&TeresaIkeda"] = "池田 瑛紗",
    ["#TeresaIkeda"] = "",
    ["~TeresaIkeda"] = "",
    ["designer:TeresaIkeda"] = "Cassimolar",
    ["cv:TeresaIkeda"] = "池田 瑛紗",
    ["illustrator:TeresaIkeda"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
