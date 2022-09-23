require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

ReiOozono_Kenshusei = sgs.General(Sakamichi, "ReiOozono_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.ReiOozono_Kenshusei = true
SKMC.NiKiSei.ReiOozono_Kenshusei = true
SKMC.SanKiSei.ReiOozono_Kenshusei = true
SKMC.YonKiSei.ReiOozono_Kenshusei = true
SKMC.SeiMeiHanDan.ReiOozono_Kenshusei = {
    name = {3, 13, 9},
    ten_kaku = {16, "da_ji"},
    jin_kaku = {22, "xiong"},
    ji_kaku = {9, "xiong"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {25, "ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "mu",
        ji_kaku = "shui",
        san_sai = "ji_xiong_hun_he",
    },
}

ReiOozono_Kenshusei:addSkill("sakamichi_yan_xiu")
ReiOozono_Kenshusei:addSkill("sakamichi_xin_li_xue")

sgs.LoadTranslationTable {
    ["ReiOozono_Kenshusei"] = "大園 玲",
    ["&ReiOozono_Kenshusei"] = "大園 玲",
    ["#ReiOozono_Kenshusei"] = "才色兼备",
    ["~ReiOozono_Kenshusei"] = "選択肢にあふれている人生を楽しんでください",
    ["designer:ReiOozono_Kenshusei"] = "Cassimolar",
    ["cv:ReiOozono_Kenshusei"] = "大園 玲",
    ["illustrator:ReiOozono_Kenshusei"] = "Cassimolar",
}
