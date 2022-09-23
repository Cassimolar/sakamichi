require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

AkihoOnuma_Kenshusei = sgs.General(Sakamichi, "AkihoOnuma_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.AkihoOnuma_Kenshusei = true
SKMC.NiKiSei.AkihoOnuma_Kenshusei = true
SKMC.SanKiSei.AkihoOnuma_Kenshusei = true
SKMC.YonKiSei.AkihoOnuma_Kenshusei = true
SKMC.SeiMeiHanDan.AkihoOnuma_Kenshusei = {
    name = {3, 8, 12, 9},
    ten_kaku = {11, "ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {21, "ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {32, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "shui",
        ji_kaku = "mu",
        san_sai = "ji",
    },
}

AkihoOnuma_Kenshusei:addSkill("sakamichi_yan_xiu")
AkihoOnuma_Kenshusei:addSkill("sakamichi_heng_tiao")

sgs.LoadTranslationTable {
    ["AkihoOnuma_Kenshusei"] = "大沼 晶保",
    ["&AkihoOnuma_Kenshusei"] = "大沼 晶保",
    ["#AkihoOnuma_Kenshusei"] = "水产偶像",
    ["~AkihoOnuma_Kenshusei"] = "なんだと思いますか？",
    ["designer:AkihoOnuma_Kenshusei"] = "Cassimolar",
    ["cv:AkihoOnuma_Kenshusei"] = "大沼 晶保",
    ["illustrator:AkihoOnuma_Kenshusei"] = "Cassimolar",
}
