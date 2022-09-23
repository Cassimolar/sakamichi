require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenaMoriya_Sakurazaka = sgs.General(Sakamichi, "RenaMoriya_Sakurazaka", "Sakurazaka46", 3, false)
SKMC.NiKiSei.RenaMoriya_Sakurazaka = true
SKMC.SeiMeiHanDan.RenaMoriya_Sakurazaka = {
    name = {6, 9, 19, 8},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {28, "xiong"},
    ji_kaku = {27, "ji_xiong_hun_he"},
    soto_kaku = {14, "xiong"},
    sou_kaku = {42, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji",
    },
}

sakamichi_zong_li = sgs.CreateMaxCardsSkill {
    name = "sakamichi_zong_li",
    extra_func = function(self, target)
        if target:hasSkill(self) then
            local n = 0
            for _, p in sgs.qlist(target:getAliveSiblings()) do
                if p:isWounded() then
                    n = n + 1
                end
            end
            if target:isWounded() then
                n = n + 1
            end
            return n
        end
    end,
}
RenaMoriya_Sakurazaka:addSkill(sakamichi_zong_li)

sakamichi_meng_qiaoCard = sgs.CreateSkillCard {
    name = "sakamichi_meng_qiaoCard",
    skill_name = "sakamichi_meng_qiao",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
                   and not sgs.Self:hasFlag("meng_qiao_used_" .. to_select:objectName())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local n = SKMC.number_correction(effect.from, 1)
        local choices = {}
        local choice_1 = "meng_qiao_1=" .. effect.from:objectName() .. "=" .. n
        local choice_2 = "meng_qiao_2=" .. effect.from:objectName()
        table.insert(choices, choice_1)
        if not effect.to:isKongcheng() then
            table.insert(choices, choice_2)
        end
        local choice = room:askForChoice(effect.to, self:getSkillName(), table.concat(choices, "+"))
        if choice == choice_1 then
            room:loseHp(effect.from, n)
            room:drawCards(effect.from, 3, self:getSkillName())
            room:setPlayerFlag(effect.from, "meng_qiao_used_" .. effect.to:objectName())
        else
            room:setPlayerFlag(effect.from, "meng_qiao_used")
            local id = room:doGongxin(effect.from, effect.to, effect.to:handCards(), self:getSkillName())
            if id ~= -1 then
                local card = sgs.Sanguosha:getCard(id)
                local move_choices = {}
                local move_choice_1 = "meng_qiao_put==" .. card:objectName()
                local move_choice_2 = "meng_qiao_throw==" .. card:objectName()
                table.insert(move_choices, move_choice_1)
                table.insert(move_choices, move_choice_2)
                if room:askForChoice(effect.from, self:getSkillName(), table.concat(move_choices, "+")) == move_choice_1 then
                    room:moveCardTo(card, effect.to, nil, sgs.Player_DrawPile, sgs.CardMoveReason(
                        sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), nil, self:getSkillName(), nil), true)
                else
                    room:throwCard(card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE,
                        effect.from:objectName(), nil, self:getSkillName(), nil), effect.to, effect.from)
                end
            end
        end
    end,
}
sakamichi_meng_qiao = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_meng_qiao",
    view_as = function()
        return sakamichi_meng_qiaoCard:clone()
    end,
    enabled_at_play = function(self, player)
        if player:hasFlag("meng_qiao_used") then
            return false
        end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if not player:hasFlag("meng_qiao_used_" .. p:objectName()) then
                return true
            end
        end
        return false
    end,
}
RenaMoriya_Sakurazaka:addSkill(sakamichi_meng_qiao)

sakamichi_duan_shi = sgs.CreateTriggerSkill {
    name = "sakamichi_duan_shi",
    frequency = sgs.Skill_Frequent,
    events = {sgs.HpLost, sgs.PreCardUsed, sgs.TargetSpecifying, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.HpLost then
            room:setPlayerFlag(player, "duan_shi")
            room:askForUseCard(player, "slash", "@askforslash")
            if player:hasFlag("duan_shi") then
                room:setPlayerFlag(player, "-duan_shi")
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:hasFlag("duan_shi") then
                room:setPlayerFlag(player, "-duan_shi")
                room:setCardFlag(use.card, "duan_shi")
            end
        elseif event == sgs.TargetSpecifying then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.card:hasFlag("duan_shi") then
                for _, p in sgs.qlist(use.to) do
                    room:setPlayerFlag(p, "duan_shi_invalidity")
                    room:addPlayerMark(p, "Armor_Nullified")
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and use.card:hasFlag("duan_shi") then
                for _, p in sgs.qlist(use.to) do
                    room:setPlayerFlag(p, "-duan_shi_invalidity")
                    room:removePlayerMark(p, "Armor_Nullified")
                end
            end
        end
        return false
    end,
}
sakamichi_duan_shi_Invalidity = sgs.CreateInvaliditySkill {
    name = "#sakamichi_duan_shi_Invalidity",
    skill_valid = function(self, player, skill)
        if player:hasFlag("duan_shi_invalidity") then
            return false
        else
            return true
        end
    end,
}
RenaMoriya_Sakurazaka:addSkill(sakamichi_duan_shi)
if not sgs.Sanguosha:getSkill("#sakamichi_duan_shi_Invalidity") then
    SKMC.SkillList:append(sakamichi_duan_shi_Invalidity)
end

sgs.LoadTranslationTable {
    ["RenaMoriya_Sakurazaka"] = "守屋 麗奈",
    ["&RenaMoriya_Sakurazaka"] = "守屋 麗奈",
    ["#RenaMoriya_Sakurazaka"] = "可愛上品",
    ["~RenaMoriya_Sakurazaka"] = "なんて？",
    ["designer:RenaMoriya_Sakurazaka"] = "Cassimolar",
    ["cv:RenaMoriya_Sakurazaka"] = "守屋 麗奈",
    ["illustrator:RenaMoriya_Sakurazaka"] = "Cassimolar",
    ["sakamichi_zong_li"] = "宗礼",
    [":sakamichi_zong_li"] = "锁定技，你的手牌上限+X（X为场上受伤角色数）。",
    ["sakamichi_meng_qiao"] = "萌敲",
    [":sakamichi_meng_qiao"] = "出牌阶段限一次，你选择一名其他角色令其选择：令你失去1点体力并摸三张牌且令本技能对其他未成为本技能目标过的角色视为未曾发动；观看其手牌并可以将其中一张弃置或置于牌堆顶。",
    ["meng_qiao_1"] = "令%src失去%arg点体力并摸三张牌",
    ["meng_qiao_2"] = "令%src观看你手牌并可以将其中的一张弃置或置于牌堆顶",
    ["meng_qiao_put"] = "将%arg置于牌堆顶",
    ["meng_qiao_throw"] = "将%arg弃置",
    ["sakamichi_duan_shi"] = "断石",
    [":sakamichi_duan_shi"] = "当你失去体力时，你可以使用一张【杀】，此【杀】指定目标时，其技能和防具失效直到此【杀】结算完成。",
}
