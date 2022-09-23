require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

NaoYumiki_Kenshusei = sgs.General(Sakamichi, "NaoYumiki_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.NaoYumiki_Kenshusei = true
SKMC.NiKiSei.NaoYumiki_Kenshusei = true
SKMC.SanKiSei.NaoYumiki_Kenshusei = true
SKMC.YonKiSei.NaoYumiki_Kenshusei = true
SKMC.SeiMeiHanDan.NaoYumiki_Kenshusei = {
    name = {3, 4, 8, 8},
    ten_kaku = {7, "ji"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {23, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "ji",
    },
}

NaoYumiki_Kenshusei:addSkill("sakamichi_yan_xiu")
NaoYumiki_Kenshusei:addSkill("sakamichi_tong_yao")

sgs.LoadTranslationTable {
    ["NaoYumiki_Kenshusei"] = "弓木 奈於",
    ["&NaoYumiki_Kenshusei"] = "弓木 奈於",
    ["#NaoYumiki_Kenshusei"] = "迷言制造机",
    ["~NaoYumiki_Kenshusei"] = "お醤油って知ってますか？",
    ["designer:NaoYumiki_Kenshusei"] = "Cassimolar",
    ["cv:NaoYumiki_Kenshusei"] = "弓木 奈於",
    ["illustrator:NaoYumiki_Kenshusei"] = "Cassimolar",
}
