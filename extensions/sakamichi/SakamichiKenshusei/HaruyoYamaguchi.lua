require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HaruyoYamaguchi_Kenshusei = sgs.General(Sakamichi, "HaruyoYamaguchi_Kenshusei", "SakamichiKenshusei", 4, false)
SKMC.IKiSei.HaruyoYamaguchi_Kenshusei = true
SKMC.NiKiSei.HaruyoYamaguchi_Kenshusei = true
SKMC.SanKiSei.HaruyoYamaguchi_Kenshusei = true
SKMC.YonKiSei.HaruyoYamaguchi_Kenshusei = true

HaruyoYamaguchi_Kenshusei:addSkill("sakamichi_yan_xiu")
HaruyoYamaguchi_Kenshusei:addSkill("Luajieqiu")

sgs.LoadTranslationTable {
    ["HaruyoYamaguchi_Kenshusei"] = "山口 陽世",
    ["&HaruyoYamaguchi_Kenshusei"] = "山口 陽世",
    ["#HaruyoYamaguchi_Kenshusei"] = "投球少女",
    ["designer:HaruyoYamaguchi_Kenshusei"] = "Cassimolar",
    ["cv:HaruyoYamaguchi_Kenshusei"] = "山口 陽世",
    ["illustrator:HaruyoYamaguchi_Kenshusei"] = "Cassimolar",
}
