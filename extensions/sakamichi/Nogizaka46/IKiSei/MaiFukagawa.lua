require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

MaiFukagawa = sgs.General(Sakamichi, "MaiFukagawa$", "Nogizaka46", 3, false)
SKMC.IKiSei.MaiFukagawa = true
SKMC.SeiMeiHanDan.MaiFukagawa = {
    name = {11, 3, 11, 6},
    ten_kaku = {14, "xiong"},
    jin_kaku = {14, "xiong"},
    ji_kaku = {17, "ji"},
    soto_kaku = {17, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "huo",
        jin_kaku = "huo",
        ji_kaku = "jin",
        san_sai = "ji_xiong_hun_he",
    },
}

sakamichi_zi_yuan = sgs.CreateTriggerSkill {
    name = "sakamichi_zi_yuan$",
    events = {sgs.QuitDying},
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who and dying.who:getKingdom() == "Nogizaka46" and dying.who:isWounded() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if dying.who:objectName() ~= p:objectName() and p:hasLordSkill(self)
                    and room:askForSkillInvoke(p, self:objectName(), data) then
                    local n = SKMC.number_correction(p, 1)
                    room:loseHp(p, n)
                    room:recover(dying.who, sgs.RecoverStruct(p, nil, n))
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiFukagawa:addSkill(sakamichi_zi_yuan)

sakamichi_guang_hui = sgs.CreateTriggerSkill {
    name = "sakamichi_guang_hui",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Start then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:isWounded() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() and room:askForSkillInvoke(player, self:objectName(), data) then
                local target = room:askForPlayerChosen(player, targets, self:objectName(),
                    "@guang_hui_invoke:::" .. SKMC.number_correction(player, 1), true)
                if target then
                    room:recover(target, sgs.RecoverStruct(player, nil, SKMC.number_correction(player, 1)))
                end
            end
        end
        return false
    end,
}
MaiFukagawa:addSkill(sakamichi_guang_hui)

sakamichi_sheng_mu = sgs.CreateTriggerSkill {
    name = "sakamichi_sheng_mu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.PreHpRecover, sgs.EnterDying},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("Peach") then
                if use.from:hasSkill(self) then
                    room:setCardFlag(use.card, "sheng_mu")
                end
            end
        elseif event == sgs.PreHpRecover then
            local recover = data:toRecover()
            if recover.card and recover.card:hasFlag("sheng_mu") then
                local n = SKMC.number_correction(recover.who, 1)
                recover.recover = recover.recover + n
                data:setValue(recover)
                SKMC.send_message(room, "#sheng_mu_extra_recover", recover.who, player, nil, recover.card:toString(),
                    self:objectName(), n, recover.recover)
                room:setCardFlag(recover.card, "-sheng_mu")
            end
        elseif event == sgs.EnterDying then
            local dying = data:toDying()
            if dying.who:hasSkill(self) and dying.damage and dying.damage.from and not dying.damage.from:isKongcheng() then
                dying.damage.from:throwAllCards()
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}
MaiFukagawa:addSkill(sakamichi_sheng_mu)

sgs.LoadTranslationTable {
    ["MaiFukagawa"] = "?????? ??????",
    ["&MaiFukagawa"] = "?????? ??????",
    ["#MaiFukagawa"] = "???????????????",
    ["~MaiFukagawa"] = "?????????????????????",
    ["designer:MaiFukagawa"] = "Cassimolar",
    ["cv:MaiFukagawa"] = "?????? ??????",
    ["illustrator:MaiFukagawa"] = "Cassimolar",
    ["sakamichi_zi_yuan"] = "??????",
    [":sakamichi_zi_yuan"] = "???????????????????????????46?????????????????????????????????????????????1???????????????????????????????????????",
    ["sakamichi_guang_hui"] = "??????",
    [":sakamichi_guang_hui"] = "?????????????????????????????????????????????????????????1????????????",
    ["@guang_hui_invoke"] = "????????????????????????????????????????????????%arg?????????",
    ["sakamichi_sheng_mu"] = "??????",
    [":sakamichi_sheng_mu"] = "??????????????????????????????????????????+1????????????????????????????????????????????????????????????",
    ["#sheng_mu_extra_recover"] = "%to ??????%from ??????%arg?????????????????????%card??????????????? <font color=\"yellow\"><b>1</b></font> ????????????????????????<font color=\"yellow\"><b>%arg2</b></font> ???",
}
