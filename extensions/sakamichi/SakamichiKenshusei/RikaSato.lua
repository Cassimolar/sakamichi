require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RikaSato_Kenshusei = sgs.General(Sakamichi, "RikaSato_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.RikaSato_Kenshusei = true
SKMC.NiKiSei.RikaSato_Kenshusei = true
SKMC.SanKiSei.RikaSato_Kenshusei = true
SKMC.YonKiSei.RikaSato_Kenshusei = true
SKMC.SeiMeiHanDan.RikaSato_Kenshusei = {
    name = {7, 18, 15, 8},
    ten_kaku = {25, "ji"},
    jin_kaku = {33, "te_shu_ge"},
    ji_kaku = {23, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {48, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "huo",
        ji_kaku = "huo",
        san_sai = "ji",
    },
}

RikaSato_Kenshusei:addSkill("sakamichi_yan_xiu")
RikaSato_Kenshusei:addSkill("sakamichi_li_ke")

sgs.LoadTranslationTable {
    ["RikaSato_Kenshusei"] = "佐藤 璃果",
    ["&RikaSato_Kenshusei"] = "佐藤 璃果",
    ["#RikaSato_Kenshusei"] = "骇客少女",
    ["~RikaSato_Kenshusei"] = "トキメキを大切に輝きたい",
    ["designer:RikaSato_Kenshusei"] = "Cassimolar",
    ["cv:RikaSato_Kenshusei"] = "佐藤 璃果",
    ["illustrator:RikaSato_Kenshusei"] = "Cassimolar",
}
