require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HikariEndo_Sakurazaka = sgs.General(Sakamichi, "HikariEndo_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.NiKiSei.HikariEndo_Sakurazaka = true
SKMC.SeiMeiHanDan.HikariEndo_Sakurazaka = {
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

sakamichi_xi_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_xi_qi",
    frequency = sgs.Skill_Frequent,
    hide_skill = true,
    events = {sgs.Appear},
    on_trigger = function(self, event, player, data, room)
        local current = room:getCurrent()
        if current:objectName() ~= player:objectName() and current:getHandcardNum() >= player:getHandcardNum()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            while current:getHandcardNum() >= player:getHandcardNum() do
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
}
HikariEndo_Sakurazaka:addSkill(sakamichi_xi_qi)

sakamichi_kong_huang = sgs.CreateTriggerSkill {
    name = "sakamichi_kong_huang",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            local good = true
            while good do
                local result = SKMC.run_judge(room, player, self:objectName(), ".|red", true, false, true, true)
                if result.isGood then
                    room:obtainCard(player, result.card)
                    good = true
                elseif result.card:isBlack() then
                    if damage.from then
                        room:loseHp(player, SKMC.number_correction(player, 1))
                        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                        slash:deleteLater()
                        slash:setSkillName(self:objectName())
                        room:useCard(sgs.CardUseStruct(slash, player, damage.from))
                    end
                    good = false
                end
            end
        end
        return false
    end,
}
HikariEndo_Sakurazaka:addSkill(sakamichi_kong_huang)

sakamichi_nan_suan = sgs.CreateTriggerSkill {
    name = "sakamichi_nan_suan",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") then
            local no_respond_list = use.no_respond_list
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if use.card:getNumber() > SKMC.number_correction(p, 9) then
                    table.insert(no_respond_list, p:objectName())
                end
            end
            use.no_respond_list = no_respond_list
            data:setValue(use)
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HikariEndo_Sakurazaka:addSkill(sakamichi_nan_suan)

sgs.LoadTranslationTable {
    ["HikariEndo_Sakurazaka"] = "遠藤 光莉",
    ["&HikariEndo_Sakurazaka"] = "遠藤 光莉",
    ["#HikariEndo_Sakurazaka"] = "坛场天才",
    ["~HikariEndo_Sakurazaka"] = "パニッケ！パニッケ！",
    ["designer:HikariEndo_Sakurazaka"] = "Cassimolar",
    ["cv:HikariEndo_Sakurazaka"] = "遠藤 光莉",
    ["illustrator:HikariEndo_Sakurazaka"] = "Cassimolar",
    ["sakamichi_xi_qi"] = "喜泣",
    [":sakamichi_xi_qi"] = "隐匿技，你于其他角色回合登场后，若其手牌数不小于你，你可以摸牌直到手牌数大于其。",
    ["sakamichi_kong_huang"] = "恐慌",
    [":sakamichi_kong_huang"] = "当你受到伤害后，你可以判定，若结果为红色，你获得判定牌并重复此流程直到判定牌为黑色，若判定牌为黑色，你失去1点体力视为对伤害来源使用一张【杀】。",
    ["sakamichi_nan_suan"] = "难算",
    [":sakamichi_nan_suan"] = "锁定技，你无法响应点数大于9的牌。",
}
