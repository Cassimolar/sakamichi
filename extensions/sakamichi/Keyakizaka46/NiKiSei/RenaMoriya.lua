require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenaMoriya = sgs.General(Sakamichi, "RenaMoriya", "Keyakizaka46", 4, false, true)
SKMC.NiKiSei.RenaMoriya = true
SKMC.SeiMeiHanDan.RenaMoriya = {
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

sakamichi_li_fa = sgs.CreateTriggerSkill {
    name = "sakamichi_li_fa",
    events = {sgs.TargetConfirming},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not use.card:isKindOf("SkillCard") and use.from and use.from:objectName() ~= player:objectName()
            and use.from:getHandcardNum() >= player:getHandcardNum()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            if not room:askForDiscard(use.from, self:objectName(), 1, 1, true, true,
                "@li_fa_discard:" .. player:objectName() .. "::" .. use.card:objectName(), ".", self:objectName()) then
                local nullified_list = use.nullified_list
                table.insert(nullified_list, player:objectName())
                use.nullified_list = nullified_list
                data:setValue(use)
            end
        end
    end,
}
RenaMoriya:addSkill(sakamichi_li_fa)

sakamichi_jie_paiCard = sgs.CreateSkillCard {
    name = "sakamichi_jie_paiCard",
    skill_name = "sakamichi_jie_pai",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:damage(
            sgs.DamageStruct(self:getSkillName(), effect.to, effect.from, SKMC.number_correction(effect.from, 1)))
        local others = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(effect.from)) do
            if p:objectName() ~= effect.to:objectName() then
                others:append(p)
            end
        end
        local target = room:askForPlayerChosen(effect.from, others, self:getSkillName(), "@jie_pai_damage", true, true)
        if target then
            room:damage(sgs.DamageStruct(self:getSkillName(), effect.from, target,
                SKMC.number_correction(effect.from, 1)))
        end
    end,
}
sakamichi_jie_pai = sgs.CreateZeroCardViewAsSkill {
    name = "sakamichi_jie_pai",
    view_as = function(self)
        return sakamichi_jie_paiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:isWounded()
    end,
}
RenaMoriya:addSkill(sakamichi_jie_pai)

sakamichi_xi_ming = sgs.CreateTriggerSkill {
    name = "sakamichi_xi_ming",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from and damage.from:isAlive() and player:canPindian(damage.from) then
                if player:pindian(damage.from, self:objectName(), nil) then
                    if not damage.from:isNude() then
                        local id = room:askForCardChosen(player, damage.from, "he", self:objectName(), false,
                            sgs.Card_MethodNone, sgs.IntList(), true)
                        if id ~= -1 then
                            room:obtainCard(player, id,
                                room:getCardPlace(sgs.Sanguosha:getCard(id)) ~= sgs.Player_PlaceHand)
                        end
                    end
                end
            end
        end
        return false
    end,
}
RenaMoriya:addSkill(sakamichi_xi_ming)

sgs.LoadTranslationTable {
    ["RenaMoriya"] = "守屋 麗奈",
    ["&RenaMoriya"] = "守屋 麗奈",
    ["#RenaMoriya"] = "花鬘正伝",
    ["~RenaMoriya"] = "れなぁ～",
    ["designer:RenaMoriya"] = "Cassimolar",
    ["cv:RenaMoriya"] = "守屋 麗奈",
    ["illustrator:RenaMoriya"] = "Cassimolar",
    ["sakamichi_li_fa"] = "礼法",
    [":sakamichi_li_fa"] = "当你成为其他角色使用牌的目标时，若你的手牌不多于其，你可以令其弃置一张牌，否则此牌对你无效。",
    ["@li_fa_discard"] = "你需要弃置一张牌，否则此【%arg】对%src无效",
    ["sakamichi_jie_pai"] = "接派",
    [":sakamichi_jie_pai"] = "出牌阶段，若你未受伤，你可以令一名其他角色对你造成1点伤害，然后你可以对另一名角色造成1点伤害。",
    ["@jie_pai_damage"] = "你可以选择一名其他角色对其造成1点伤害",
    ["sakamichi_xi_ming"] = "袭名",
    [":sakamichi_xi_ming"] = "当你受到伤害后，你可以与伤害来源拼点，若你赢，你可以获得其一张牌。",
}
