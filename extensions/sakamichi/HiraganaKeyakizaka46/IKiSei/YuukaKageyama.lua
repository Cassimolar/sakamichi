require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

YuukaKageyama_HiraganaKeyakizaka = sgs.General(Sakamichi, "YuukaKageyama_HiraganaKeyakizaka", "HiraganaKeyakizaka46", 3,
    false)
table.insert(SKMC.IKiSei, "YuukaKageyama_HiraganaKeyakizaka")

sakamichi_dao_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_dao_shi",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Peach") then
            if not room:getCurrentDyingPlayer()
                or (room:getCurrentDyingPlayer() and room:getCurrentDyingPlayer():objectName() ~= player:objectName()) then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName()
                        and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant(
                            "invoke:" .. player:objectName() .. "::" .. self:objectName() .. ":" .. use.card:objectName())) then
                        room:loseHp(p, SKMC.number_correction(p, 1))
                        local nullified_list = use.nullified_list
                        table.insert(nullified_list, "_ALL_TARGETS")
                        use.nullified_list = nullified_list
                        data:setValue(use)
                        break
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
YuukaKageyama_HiraganaKeyakizaka:addSkill(sakamichi_dao_shi)

sakamichi_bo_shi = sgs.CreateViewAsSkill {
    name = "sakamichi_bo_shi",
    n = 999,
    response_pattern = "nullification",
    response_or_use = true,
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getHp() and not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        local cd
        if #cards == sgs.Self:getHp() then
            cd = sgs.Sanguosha:cloneCard("nullification", sgs.Card_SuitToBeDecided, -1)
            cd:setSkillName(self:objectName())
            for _, c in ipairs(cards) do
                cd:addSubcard(c)
            end
        end
        return cd
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "nullification" and player:getHandcardNum() >= player:getHp()
    end,
}
sakamichi_bo_shi_max = sgs.CreateMaxCardsSkill {
    name = "#sakamichi_bo_shi_max",
    extra_func = function(self, target)
        if target:hasSkill("sakamichi_bo_shi") then
            return target:getHp()
        end
    end,
}
YuukaKageyama_HiraganaKeyakizaka:addSkill(sakamichi_bo_shi)
if not sgs.Sanguosha:getSkill("#sakamichi_bo_shi_max") then
    SKMC.SkillList:append(sakamichi_bo_shi_max)
end

sgs.LoadTranslationTable {
    ["YuukaKageyama_HiraganaKeyakizaka"] = "?????? ??????",
    ["&YuukaKageyama_HiraganaKeyakizaka"] = "?????? ??????",
    ["#YuukaKageyama_HiraganaKeyakizaka"] = "????????????",
    ["~YuukaKageyama_HiraganaKeyakizaka"] = "?????????????????????????????????",
    ["designer:YuukaKageyama_HiraganaKeyakizaka"] = "Cassimolar",
    ["cv:YuukaKageyama_HiraganaKeyakizaka"] = "?????? ??????",
    ["illustrator:YuukaKageyama_HiraganaKeyakizaka"] = "Cassimolar",
    ["sakamichi_dao_shi"] = "??????",
    [":sakamichi_dao_shi"] = "????????????????????????????????????????????????????????????????????????1?????????????????????????????????",
    ["sakamichi_dao_shi:invoke"] = "???????????????%arg??????%src???????????????%arg2?????????",
    ["sakamichi_bo_shi"] = "??????",
    [":sakamichi_bo_sh"] = "????????????X?????????????????????????????????????????????????????????+X???X????????????????????????",
}
