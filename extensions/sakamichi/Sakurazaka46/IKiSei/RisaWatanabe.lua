require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RisaWatanabe_Sakurazaka = sgs.General(Sakamichi, "RisaWatanabe_Sakurazaka", "Sakurazaka46", 4, false)
SKMC.IKiSei.RisaWatanabe_Sakurazaka = true
SKMC.SeiMeiHanDan.RisaWatanabe_Sakurazaka = {
    name = {12, 17, 11, 7},
    ten_kaku = {29, "te_shu_ge"},
    jin_kaku = {28, "xiong"},
    ji_kaku = {18, "ji"},
    soto_kaku = {19, "xiong"},
    sou_kaku = {47, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_nv_wang = sgs.CreateTriggerSkill {
    name = "sakamichi_nv_wang",
    frequency = sgs.Skill_Compulsory,
    hide_skill = true,
    events = {sgs.Appear},
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            room:loseHp(p, 1)
        end
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:isWounded() then
                room:recover(p, sgs.RecoverStruct(player, nil, 1))
            end
        end
        room:addMaxCards(player, 1000, true)
        return false
    end,
}
RisaWatanabe_Sakurazaka:addSkill(sakamichi_nv_wang)

sakamichi_li_shuai = sgs.CreateTriggerSkill {
    name = "sakamichi_li_shuai",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetSpecifying},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if (use.card:isKindOf("Slash") or use.card:isNDTrick()) and player:getPhase() ~= sgs.Player_NotActive then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if use.to:contains(p) and player:getHp() < p:getHp() then
                    if player:hasFlag("li_shuai" .. p:objectName()) then
                        local no_respond_list = use.no_respond_list
                        table.insert(no_respond_list, p:objectName())
                        use.no_respond_list = no_respond_list
                        data:setValue(use)
                    else
                        room:setPlayerFlag(player, "li_shuai" .. p:objectName())
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
RisaWatanabe_Sakurazaka:addSkill(sakamichi_li_shuai)

sakamichi_xiao_pi = sgs.CreateTriggerSkill {
    name = "sakamichi_xiao_pi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.SlashHit},
    on_trigger = function(self, event, player, data, room)
        local effect = data:toSlashEffect()
        if effect.from and effect.from:objectName() == player:objectName() and player:getWeapon() then
            if effect.to:getHujia() ~= 0 then
                effect.to:loseAllHujias()
            end
            if effect.to:getArmor() then
                if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant(
                    "armor:" .. effect.to:objectName() .. "::" .. effect.to:getArmor():objectName())) then
                    room:throwCard(effect.to:getArmor(), effect.to, player)
                end
            end
        end
        return false
    end,
}
RisaWatanabe_Sakurazaka:addSkill(sakamichi_xiao_pi)

sakamichi_san_jiao = sgs.CreateTriggerSkill {
    name = "sakamichi_san_jiao",
    frequency = sgs.Skill_Frequent,
    events = {sgs.Damage, sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to:hasSkill(self) then
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
                    if p:objectName() ~= player:objectName() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(damage.to, targets, self:objectName(),
                        "san_jiao_invoke_1:" .. player:objectName(), true)
                    if target then
                        room:drawCards(target, 1, self:objectName())
                    end
                end
            end
        else
            local recover = data:toRecover()
            if player:hasSkill(self) and recover.who and recover.who:objectName() ~= player:objectName() then
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getOtherPlayers(recover.who)) do
                    if p:objectName() ~= player:objectName() and not p:isNude() then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(),
                        "san_jiao_invoke_2:" .. recover.who:objectName(), true)
                    if target then
                        local id = room:askForCardChosen(player, target, "he", self:objectName(), false,
                            sgs.Card_MethodDiscard)
                        room:throwCard(sgs.Sanguosha:getCard(id), target, player)
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
RisaWatanabe_Sakurazaka:addSkill(sakamichi_san_jiao)

sgs.LoadTranslationTable {
    ["RisaWatanabe_Sakurazaka"] = "渡邉 理佐",
    ["&RisaWatanabe_Sakurazaka"] = "渡邉 理佐",
    ["#RisaWatanabe_Sakurazaka"] = "女王大人",
    ["~RisaWatanabe_Sakurazaka"] = "絶対来ると思つたこの流れ！",
    ["designer:RisaWatanabe_Sakurazaka"] = "Cassimolar",
    ["cv:RisaWatanabe_Sakurazaka"] = "渡邉 理佐",
    ["illustrator:RisaWatanabe_Sakurazaka"] = "Cassimolar",
    ["sakamichi_nv_wang"] = "女王",
    [":sakamichi_nv_wang"] = "隐匿技，锁定技，你登场时，令所有其他角色失去1点体力然后回复1点体力，本回合内，你的手牌无上限。",
    ["sakamichi_li_shuai"] = "力衰",
    [":sakamichi_li_shuai"] = "锁定技，体力值小于你的角色于其回合内使用【杀】或通常锦囊牌指定你为目标时，若本回合内其已使用【杀】或通常锦囊牌指定你为目标过，你无法响应此牌。",
    ["sakamichi_xiao_pi"] = "削皮",
    [":sakamichi_xiao_pi"] = "你使用【杀】命中后，且你的装备区有武器牌，移除目标所有护甲，若其装备区有防具，你可以弃置之。",
    ["sakamichi_xiao_pi:armor"] = "是否弃置%src的防具【%arg】",
    ["sakamichi_san_jiao"] = "三角",
    [":sakamichi_san_jiao"] = "当一名其他角色对你造成伤害后/令你回复体力时，你可以令另一名其他角色摸一张牌/弃置另一名其他角色一张牌。",
    ["san_jiao_invoke_1"] = "你可以令除%src以外的一名其他角色摸一张牌",
    ["san_jiao_invoke_2"] = "你可以弃置除%src以外的一名其他角色一张牌",
}
