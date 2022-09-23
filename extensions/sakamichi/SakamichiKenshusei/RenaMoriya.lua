require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenaMoriya_Kenshusei = sgs.General(Sakamichi, "RenaMoriya_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.RenaMoriya_Kenshusei = true
SKMC.NiKiSei.RenaMoriya_Kenshusei = true
SKMC.SanKiSei.RenaMoriya_Kenshusei = true
SKMC.YonKiSei.RenaMoriya_Kenshusei = true
SKMC.SeiMeiHanDan.RenaMoriya_Kenshusei = {
    name = {6, 9, 19, 8},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {28, "xiong"},
    ji_kaku = {27, "ji_xiong_hun_he"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {42, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

RenaMoriya_Kenshusei:addSkill("sakamichi_yan_xiu")
RenaMoriya_Kenshusei:addSkill("sakamichi_li_fa")

sgs.LoadTranslationTable {
    ["RenaMoriya_Kenshusei"] = "守屋 麗奈",
    ["&RenaMoriya_Kenshusei"] = "守屋 麗奈",
    ["#RenaMoriya_Kenshusei"] = "花鬘正伝",
    ["~RenaMoriya_Kenshusei"] = "れなぁ～",
    ["designer:RenaMoriya_Kenshusei"] = "Cassimolar",
    ["cv:RenaMoriya_Kenshusei"] = "守屋 麗奈",
    ["illustrator:RenaMoriya_Kenshusei"] = "Cassimolar",
}
