require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HikariEndo_Kenshusei = sgs.General(Sakamichi, "HikariEndo_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.HikariEndo_Kenshusei = true
SKMC.NiKiSei.HikariEndo_Kenshusei = true
SKMC.SanKiSei.HikariEndo_Kenshusei = true
SKMC.YonKiSei.HikariEndo_Kenshusei = true
SKMC.SeiMeiHanDan.HikariEndo_Kenshusei = {
    name = {13, 18, 6, 10},
    ten_kaku = {31, "da_ji"},
    jin_kaku = {24, "da_ji"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {23, "ji"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "huo",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

HikariEndo_Kenshusei:addSkill("sakamichi_yan_xiu")
HikariEndo_Kenshusei:addSkill("sakamichi_jie_wu")

sgs.LoadTranslationTable {
    ["HikariEndo_Kenshusei"] = "遠藤 光莉",
    ["&HikariEndo_Kenshusei"] = "遠藤 光莉",
    ["#HikariEndo_Kenshusei"] = "怕生全開",
    ["~HikariEndo_Kenshusei"] = "走り方な忘れちゃいました",
    ["designer:HikariEndo_Kenshusei"] = "Cassimolar",
    ["cv:HikariEndo_Kenshusei"] = "遠藤 光莉",
    ["illustrator:HikariEndo_Kenshusei"] = "Cassimolar",
}
