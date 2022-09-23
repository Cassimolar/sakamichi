require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

OsamuShitara = sgs.General(Sakamichi, "OsamuShitara", "AutisticGroup", 4, true)

--[[
    技能名：S级谈话
    描述：锁定技，当你使用单目标锦囊指定目标后（【无懈可以击】除外），目标流失1点体力。
]]
LuaSjitanhua = sgs.CreateTriggerSkill {
    name = "LuaSjitanhua",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("SingleTargetTrick") then
            for _, p in sgs.qlist(use.to) do
                local msg = sgs.LogMessage()
                msg.type = "#Sjitanhua"
                msg.from = player
                msg.arg = self:objectName()
                room:sendLog(msg)
                room:loseHp(p)
            end
        end
        return false
    end,
}
OsamuShitara:addSkill(LuaSjitanhua)

sgs.LoadTranslationTable {
    ["OsamuShitara"] = "設楽 統",
    ["&OsamuShitara"] = "設楽 統",
    ["#OsamuShitara"] = "南黑頭子",
    ["designer:OsamuShitara"] = "Cassimolar",
    ["cv:OsamuShitara"] = "設楽 統",
    ["illustrator:OsamuShitara"] = "Cassimolar",
    ["LuaSjitanhua"] = "S级谈话",
    [":LuaSjitanhua"] = "锁定技，当你使用单目标锦囊指定目标后，目标流失1点体力。",
}
