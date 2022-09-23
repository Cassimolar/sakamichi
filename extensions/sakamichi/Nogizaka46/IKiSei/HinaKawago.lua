require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

HinaKawago = sgs.General(Sakamichi, "HinaKawago", "Nogizaka46", 3, false)
SKMC.IKiSei.HinaKawago = true
SKMC.SeiMeiHanDan.HinaKawago = {
    name = {3, 9, 12, 11},
    ten_kaku = {12, "xiong"},
    jin_kaku = {21, "ji"},
    ji_kaku = {23, "ji"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {35, "ji"},
    GoGyouSanSai = {
        ten_kaku = "mu",
        jin_kaku = "mu",
        ji_kaku = "huo",
        san_sai = "da_ji",
    },
}

sakamichi_sheng_qi_card = sgs.CreateSkillCard {
    name = "sakamichi_sheng_qiCard",
    skill_name = "sakamichi_sheng_qi",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:loseHp(effect.from, SKMC.number_correction(effect.from, 1))
        room:recover(effect.to, sgs.RecoverStruct(effect.from, nil, SKMC.number_correction(effect.from, 1)))
    end,
}
sakamichi_sheng_qi_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sheng_qi",
    view_as = function(self)
        return sakamichi_sheng_qi_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@sheng_qi") ~= 0
    end,
}
sakamichi_sheng_qi = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_qi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@sheng_qi",
    view_as_skill = sakamichi_sheng_qi_view_as,
    events = {sgs.GameStart, sgs.HpRecover, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:hasSkill(self) then
                local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                    "@sheng_qi_invoke:::sheng_guang_dao_biao", true)
                if target then
                    room:addPlayerMark(target, "@sheng_guang_dao_biao")
                    room:addPlayerMark(target, "&" .. player:getGeneralName() .. "+ +" .. "sheng_guang_dao_biao")
                    room:addPlayerMark(target, player:objectName() .. "_sheng_guang_dao_biao")
                end
            end
        elseif event == sgs.HpRecover then
            local recover = data:toRecover()
            if recover.who and recover.who:hasSkill(self) and not recover.who:hasFlag("sheng_qi") then
                room:setPlayerFlag(recover.who, "sheng_qi")
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(recover.who:objectName() .. "_sheng_guang_dao_biao") ~= 0
                        or p:getMark(recover.who:objectName() .. "_xin_yang_dao_biao") ~= 0 then
                        room:recover(p, sgs.RecoverStruct(recover.who, recover.card, recover.recover))
                    end
                end
                room:setPlayerFlag(recover.who, "-sheng_qi")
            end
        elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:hasSkill(self)
            and player:getMark("@sheng_qi") ~= 0 then
            if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("invoke:::" .. self:objectName())) then
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(player:objectName() .. "_sheng_guang_dao_biao") == 0
                        or p:getMark(player:objectName() .. "_xin_yang_dao_biao") == 0 then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(),
                        "@sheng_qi_invoke:::xin_yang_dao_biao")
                    if target then
                        room:removePlayerMark(player, "@sheng_qi")
                        room:addPlayerMark(target, "@xin_yang_dao_biao")
                        room:addPlayerMark(target, "&" .. player:getGeneralName() .. "+ +" .. "xin_yang_dao_biao")
                        room:addPlayerMark(target, player:objectName() .. "_xin_yang_dao_biao")
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
HinaKawago:addSkill(sakamichi_sheng_qi)

sakamichi_sheng_liao_card = sgs.CreateSkillCard {
    name = "sakamichi_sheng_liaoCard",
    skill_name = "sakamichi_sheng_liao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:getMark("@sheng_liao_used") == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:removePlayerMark(effect.from, "@sheng_liao")
        room:recover(effect.to, sgs.RecoverStruct(effect.from, self, effect.from:getMaxHp()))
        room:addPlayerMark(effect.to, "@sheng_liao_used")
    end,
}
sakamichi_sheng_liao_view_as = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_sheng_liao",
    view_as = function(self)
        return sakamichi_sheng_liao_card:clone()
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@sheng_liao") ~= 0
    end,
}
sakamichi_sheng_liao = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_liao",
    frequency = sgs.Skill_Limited,
    limit_mark = "@sheng_liao",
    view_as_skill = sakamichi_sheng_liao_view_as,
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:getMark("@sheng_liao_used") == 0 then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("@sheng_liao") ~= 0 and room:askForSkillInvoke(p, self:objectName(), data) then
                    room:removePlayerMark(p, "@sheng_liao")
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, p:getMaxHp()))
                    room:addPlayerMark(dying.who, "@sheng_liao_used")
                    break
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
HinaKawago:addSkill(sakamichi_sheng_liao)

sgs.LoadTranslationTable {
    ["HinaKawago"] = "川後 陽菜",
    ["&HinaKawago"] = "川後 陽菜",
    ["#HinaKawago"] = "圣骑之巅",
    ["~HinaKawago"] = "歌ってもない！！出てもない！！！",
    ["designer:HinaKawago"] = "Cassimolar",
    ["cv:HinaKawago"] = "川後 陽菜",
    ["illustrator:HinaKawago"] = "Cassimolar",
    ["sakamichi_sheng_qi"] = "圣骑",
    ["@sheng_qi"] = "圣骑",
    [":sakamichi_sheng_qi"] = "游戏开始时，你可以令一名角色获得一枚「圣光道标」。出牌阶段限一次，你可以失去1点体力令一名角色回复1点体力。限定技，准备阶段，你可以失去本技能出牌阶段限一次的效果，令一名未获得你的「道标」的角色获得一枚「信仰道标」。你造成回复时，你的「道标」拥有者回复等量体力值（此回复无法被「道标」复制）。",
    ["sheng_guang_dao_biao"] = "圣光道标",
    ["xin_yang_dao_biao"] = "信仰道标",
    ["sakamichi_sheng_qi:invoke"] = "是否发动【%arg】令一名角色获得“信仰道标”",
    ["@sheng_qi_invoke"] = "你可以选择一名角色令其获得“%arg”",
    ["sakamichi_sheng_liao"] = "圣疗",
    [":sakamichi_sheng_liao"] = "限定技，一名未以此法回复过体力的角色进入濒死时/出牌阶段，你可以选择一名未以此法回复过体力的角色，你可以令其回复X点体力（X为你的体力上限）。",
}
