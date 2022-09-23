require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HikaruMorita_Sakurazaka = sgs.General(Sakamichi, "HikaruMorita_Sakurazaka$", "Sakurazaka46", 4, false)
SKMC.NiKiSei.HikaruMorita_Sakurazaka = true
SKMC.SeiMeiHanDan.HikaruMorita_Sakurazaka = {
    name = {12, 5, 2, 3, 3},
    ten_kaku = {17, "ji"},
    jin_kaku = {7, "ji"},
    ji_kaku = {8, "ji"},
    soto_kaku = {18, "ji"},
    sou_kaku = {25, "ji"},
    GoGyouSanSai = {
        ten_kaku = "jin",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_wu_cuo = sgs.CreateTriggerSkill {
    name = "sakamichi_wu_cuo$",
    events = {sgs.DamageInflicted, sgs.PreHpLost},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:getKingdom() == "Sakurazaka46" and damage.from == nil then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:drawCards(p, 1, self:objectName())
                        return true
                    end
                end
            end
        else
            if player:getKingdom() == "Sakurazaka46" then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:drawCards(player, 1, self:objectName())
                        return true
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
HikaruMorita_Sakurazaka:addSkill(sakamichi_wu_cuo)

sakamichi_da_yan = sgs.CreateTriggerSkill {
    name = "sakamichi_da_yan",
    hide_skill = true,
    events = {sgs.Appear},
    on_trigger = function(self, event, player, data, room)
        local current = room:getCurrent()
        if current:objectName() ~= player:objectName() then
            if not current:isKongcheng() then
                local id = room:askForCardChosen(player, current, "h", self:objectName(), true, sgs.Card_MethodNone)
                room:showCard(player, id)
                local color
                if sgs.Sanguosha:getCard(id):isBlack() then
                    color = "black"
                elseif sgs.Sanguosha:getCard(id):isRed() then
                    color = "red"
                end
                room:setPlayerCardLimitation(current, "use,response", ".|" .. color, true)
            end
        end
        return false
    end,
}
HikaruMorita_Sakurazaka:addSkill(sakamichi_da_yan)

sakamichi_ruo_dian = sgs.CreateTriggerSkill {
    name = "sakamichi_ruo_dian",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirming, sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.card:isKindOf("ThunderSlash") then
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, player:objectName())
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.nature == sgs.DamageStruct_Thunder then
                room:askForDiscard(player, self:objectName(), 1, 1, false)
            end
        end
        return false
    end,
}
HikaruMorita_Sakurazaka:addSkill(sakamichi_ruo_dian)

sakamichi_yi_xiao = sgs.CreateTriggerSkill {
    name = "sakamichi_yi_xiao",
    frequency = sgs.Skill_Frequent,
    events = {sgs.CardResponded, sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local who
        local card
        if event == sgs.CardResponded then
            who = data:toCardResponse().m_who
            card = data:toCardResponse().m_toCard
        else
            who = data:toCardUse().who
            card = data:toCardUse().whocard
        end
        if who and who:objectName() ~= player:objectName() and card and not card:isKindOf("SkillCard")
            and player:getHandcardNum() <= player:getMaxHp() and room:askForSkillInvoke(player, self:objectName(), data) then
            room:drawCards(player, 1, self:objectName())
        end
        return false
    end,
}
HikaruMorita_Sakurazaka:addSkill(sakamichi_yi_xiao)

sgs.LoadTranslationTable {
    ["HikaruMorita_Sakurazaka"] = "森田 ひかる",
    ["&HikaruMorita_Sakurazaka"] = "森田 ひかる",
    ["#HikaruMorita_Sakurazaka"] = "光武帝",
    ["~HikaruMorita_Sakurazaka"] = "今日結構いいですね",
    ["designer:HikaruMorita_Sakurazaka"] = "Cassimolar",
    ["cv:HikaruMorita_Sakurazaka"] = "森田 ひかる",
    ["illustrator:HikaruMorita_Sakurazaka"] = "Cassimolar",
    ["sakamichi_wu_cuo"] = "无错",
    [":sakamichi_wu_cuo"] = "主公技，櫻坂46势力角色受到无来源伤害或失去体力时，你可以令其摸一张牌防止之。",
    ["sakamichi_da_yan"] = "大眼",
    [":sakamichi_da_yan"] = "隐匿技，你于其他角色回合登场后，你可以观看其手牌并展示其中的一张令其本回合内无法使用或打出与此牌颜色相同的牌。",
    ["sakamichi_ruo_dian"] = "弱电",
    [":sakamichi_ruo_dian"] = "锁定技，你无法响应雷【杀】。当你受到雷电伤害后，你须弃置一张手牌。",
    ["sakamichi_yi_xiao"] = "易笑",
    [":sakamichi_yi_xiao"] = "当你因响应其他角色使用的牌而使用或打出牌时，若你的手牌数不大于体力上限，你可以摸一张牌。",
}
