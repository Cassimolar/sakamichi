require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

SakuraKawasaki = sgs.General(Sakamichi, "SakuraKawasaki", "Nogizaka46", 6, false, true)
SKMC.GoKiSei.SakuraKawasaki = true
SKMC.SeiMeiHanDan.SakuraKawasaki = {
    name = {3, 12, 10},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {10, "xiong"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {25, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

--[[
	技能名：花滑
	描述：
]]

sgs.LoadTranslationTable {
    ["SakuraKawasaki"] = "川﨑 桜",
    ["&SakuraKawasaki"] = "川﨑 桜",
    ["#SakuraKawasaki"] = "",
    ["~SakuraKawasaki"] = "",
    ["designer:SakuraKawasaki"] = "Cassimolar",
    ["cv:SakuraKawasaki"] = "川﨑 桜",
    ["illustrator:SakuraKawasaki"] = "Cassimolar",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
    [""] = "",
}
