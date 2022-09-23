require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenkaIwamoto = sgs.General(Sakamichi, "RenkaIwamoto", "Nogizaka46", 4, false)
SKMC.SanKiSei.RenkaIwamoto = true
SKMC.SeiMeiHanDan.RenkaIwamoto = {
    name = {8, 5, 13, 5},
    ten_kaku = {13, "da_ji"},
    jin_kaku = {18, "ji"},
    ji_kaku = {18, "ji"},
    soto_kaku = {13, "da_ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "jin",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_nv_di_view_as = sgs.CreateViewAsSkill {
    name = "sakamichi_nv_di",
    n = 2,
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return to_select:isRed() or to_select:isBlack()
        elseif #selected == 1 then
            if selected[1]:isRed() then
                return to_select:isRed()
            elseif selected[1]:isBlack() then
                return to_select:isBlack()
            end
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 2 then
            local suit, number, color
            for _, card in ipairs(cards) do
                if suit and suit ~= card:getSuit() then
                    suit = sgs.Card_NoSuit
                else
                    suit = card:getSuit()
                end
                if number and number ~= card:getNumber() then
                    number = -1
                else
                    number = card:getNumber()
                end
                if card:isRed() then
                    color = "red"
                else
                    color = "black"
                end
            end
            if color == "red" then
                local archery_attack = sgs.Sanguosha:cloneCard("archery_attack", suit, number)
                archery_attack:addSubcard(cards[1])
                archery_attack:addSubcard(cards[2])
                archery_attack:setSkillName(self:objectName())
                return archery_attack
            else
                local savage_assault = sgs.Sanguosha:cloneCard("savage_assault", suit, number)
                savage_assault:addSubcard(cards[1])
                savage_assault:addSubcard(cards[2])
                savage_assault:setSkillName(self:objectName())
                return savage_assault
            end
        end
    end,
}
sakamichi_nv_di = sgs.CreateTriggerSkill {
    name = "sakamichi_nv_di",
    view_as_skill = sakamichi_nv_di_view_as,
    events = {sgs.PreCardUsed, sgs.Damage, sgs.CardFinished, sgs.CardResponded},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:getSkillName() == self:objectName() then
                room:addPlayerMark(player, "nv_di", use.to:length())
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() and player:hasSkill(self) then
                if player:getMark("nv_di_damage") == 0 then
                    room:addPlayerMark(player, "nv_di_damage")
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:getSkillName() == self:objectName() and player:hasSkill(self) then
                if player:getMark("nv_di_damage") == 0 then
                    room:drawCards(player, player:getMark("nv_di"), self:objectName())
                    room:setPlayerMark(player, "nv_di", 0)
                else
                    room:setPlayerMark(player, "nv_di", 0)
                    room:setPlayerMark(player, "nv_di_damage", 0)
                end
            end
        elseif event == sgs.CardResponded then
            local response = data:toCardResponse()
            if response.m_toCard and response.m_toCard:getSkillName() == self:objectName() then
                room:drawCards(player, 1, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RenkaIwamoto:addSkill(sakamichi_nv_di)

sakamichi_bao_xiao_card = sgs.CreateSkillCard {
    name = "sakamichi_bao_xiaoCard",
    skill_name = "sakamichi_bao_xiao",
    filter = function(self, targets, to_select)
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local difference = math.abs(effect.to:getHandcardNum() - effect.to:getMaxCards())
        if difference ~= 0 then
            if effect.to:getHandcardNum() > effect.to:getMaxCards() then
                room:askForDiscard(effect.to, self:getSkillName(), difference, difference, false, false,
                    "@bao_xiao_discard:::" .. difference, ".", self:getSkillName())
            else
                room:drawCards(effect.to, difference, self:getSkillName())
            end
            room:addMaxCards(effect.from, difference)
        end
    end,
}
sakamichi_bao_xiao = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_bao_xiao",
    view_as = function(self)
        return sakamichi_bao_xiao_card:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#sakamichi_bao_xiaoCard")
    end,
}
RenkaIwamoto:addSkill(sakamichi_bao_xiao)

sgs.LoadTranslationTable {
    ["RenkaIwamoto"] = "岩本 蓮加",
    ["&RenkaIwamoto"] = "岩本 蓮加",
    ["#RenkaIwamoto"] = "青春无敌",
    ["~RenkaIwamoto"] = "じゃーん！",
    ["designer:RenkaIwamoto"] = "Cassimolar",
    ["cv:RenkaIwamoto"] = "岩本 蓮加",
    ["illustrator:RenkaIwamoto"] = "Cassimolar",
    ["sakamichi_nv_di"] = "女帝",
    [":sakamichi_nv_di"] = "出牌阶段，你可以将两张红/黑色牌当【万箭齐发】/【南蛮入侵】使用，其他角色响应你以此法使用的【万箭齐发】/【南蛮入侵】打出【闪】/【杀】时，摸一张牌。你以此法使用的【万箭齐发】/【南蛮入侵】结算完成时，若没有角色受到伤害，你摸等同于此【万箭齐发】/【南蛮入侵】指定目标数量的牌。",
    ["sakamichi_bao_xiao"] = "爆笑",
    [":sakamichi_bao_xiao"] = "出牌阶段限一次，你可以令一名角色手牌摸至或弃置手牌上限，本回合内你的手牌上限+X（X为其因此获得或失去手牌的数量）。",
    ["@bao_xiao_discard"] = "请弃置 %arg 张手牌",
}
