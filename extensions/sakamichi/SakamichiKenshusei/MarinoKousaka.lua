require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MarinoKousaka_Kenshusei = sgs.General(Sakamichi, "MarinoKousaka_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.MarinoKousaka_Kenshusei = true
SKMC.NiKiSei.MarinoKousaka_Kenshusei = true
SKMC.SanKiSei.MarinoKousaka_Kenshusei = true
SKMC.YonKiSei.MarinoKousaka_Kenshusei = true
SKMC.SeiMeiHanDan.MarinoKousaka_Kenshusei = {
    name = {8, 7, 8, 7, 2},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {15, "da_ji"},
    ji_kaku = {17, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "tu",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

MarinoKousaka_Kenshusei:addSkill("sakamichi_yan_xiu")
MarinoKousaka_Kenshusei:addSkill("sakamichi_hu_la")

sgs.LoadTranslationTable {
    ["MarinoKousaka_Kenshusei"] = "幸阪 茉里乃",
    ["&MarinoKousaka_Kenshusei"] = "幸阪 茉里乃",
    ["#MarinoKousaka_Kenshusei"] = "死亡金屬",
    ["~MarinoKousaka_Kenshusei"] = "全然。全然ちゃうなぁ",
    ["designer:MarinoKousaka_Kenshusei"] = "Cassimolar",
    ["cv:MarinoKousaka_Kenshusei"] = "幸阪 茉里乃",
    ["illustrator:MarinoKousaka_Kenshusei"] = "Cassimolar",
}
