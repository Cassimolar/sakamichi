require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RisakoYada = sgs.General(Sakamichi, "RisakoYada", "Nogizaka46", 3, false)
SKMC.NiKiSei.RisakoYada = true
SKMC.SeiMeiHanDan.RisakoYada = {
    name = {5, 5, 7, 7, 3},
    ten_kaku = {10, "xiong"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {17, "ji"},
    soto_kaku = {15, "da_ji"},
    sou_kaku = {27, "ji_xiong_hun_he"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_bu_she = sgs.CreateTriggerSkill {
    name = "sakamichi_bu_she",
    events = {sgs.AskForPeaches},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() ~= player:objectName() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:gainMaxHp(dying.who, SKMC.number_correction(player, 1))
                room:recover(dying.who, sgs.RecoverStruct(player, nil, player:getHp()))
                if player:getCards("he"):length() > 0 then
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    dummy:deleteLater()
                    dummy:addSubcards(player:getCards("he"))
                    room:obtainCard(dying.who, dummy, false)
                end
                room:killPlayer(player)
            end
        end
        return false
    end,
}
RisakoYada:addSkill(sakamichi_bu_she)

sakamichi_zhi_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_zhi_yu",
    events = {sgs.HpRecover},
    on_trigger = function(self, event, player, data, room)
        local recover_struct = data:toRecover()
        local recover = recover_struct.recover
        for i = 1, recover, SKMC.number_correction(player, 1) do
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "@zhi_yu_invoke", true, true)
            if target then
                room:drawCards(target, 1, self:objectName())
            else
                break
            end
        end
        return false
    end,
}
RisakoYada:addSkill(sakamichi_zhi_yu)

sakamichi_bao_yu = sgs.CreateTriggerSkill {
    name = "sakamichi_bao_yu",
    events = {sgs.StartJudge},
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        if judge.reason == "indulgence" or judge.reason == "lightning" or judge.reason == "supply_shortage"
            or judge.reason == "WasabiOnigiri" then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self) then
                    local card = room:askForCard(p, ".", "@bao_yu_discard:::" .. judge.reason, data, self:objectName())
                    if card then
                        judge.good = not judge.good
                        if not card:isKindOf("BasicCard") then
                            room:drawCards(p, 1, self:objectName())
                        end
                    end
                end
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}
RisakoYada:addSkill(sakamichi_bao_yu)

sgs.LoadTranslationTable {
    ["RisakoYada"] = "矢田 里沙子",
    ["&RisakoYada"] = "矢田 里沙子",
    ["#RisakoYada"] = "二期聖母",
    ["~RisakoYada"] = "やだやだやだー 覚えてくれなきゃ？やだー！！！",
    ["designer:RisakoYada"] = "Cassimolar",
    ["cv:RisakoYada"] = "矢田 里沙子",
    ["illustrator:RisakoYada"] = "Cassimolar",
    ["sakamichi_bu_she"] = "不舍",
    [":sakamichi_bu_she"] = "当一名其他角色处于濒死时，你可以令其增加1点体力上限并回复X点体力值（X为你的体力值）并获得你所有牌，然后你死亡。",
    ["sakamichi_zhi_yu"] = "治愈",
    [":sakamichi_zhi_yu"] = "每当你回复1点体力时，你可以令一名其他角色摸一张牌。",
    ["@zhi_yu_invoke"] = "你可以令一名其他角色摸一张牌",
    ["sakamichi_bao_yu"] = "保育",
    [":sakamichi_bao_yu"] = "当一名角色判定区的牌开始判定时，你可以弃置一张手牌令其此次判定结果反转，若你以此法弃置的牌不为基本牌，你摸一张牌。",
    ["@bao_yu_discard"] = "你可以弃置一张手牌令此【%arg】判定结果反转",
}
