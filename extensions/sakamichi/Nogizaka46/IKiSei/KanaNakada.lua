require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KanaNakada = sgs.General(Sakamichi, "KanaNakada", "Nogizaka46", 1, false)
SKMC.IKiSei.KanaNakada = true
SKMC.SeiMeiHanDan.KanaNakada = {
    name = {4, 5, 7, 8},
    ten_kaku = {9, "xiong"},
    jin_kaku = {12, "xiong"},
    ji_kaku = {15, "da_ji"},
    soto_kaku = {12, "xiong"},
    sou_kaku = {24, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "shui",
        jin_kaku = "mu",
        ji_kaku = "tu",
        san_sai = "da_ji",
    },
}

sakamichi_ou_xiang_chu = sgs.CreateTriggerSkill {
    name = "sakamichi_ou_xiang_chu",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart},
    on_trigger = function(self, event, player, data, room)
        local extra = 0
        local kingdoms = {}
        table.insert(kingdoms, player:getKingdom())
        for _, p in sgs.qlist(player:getSiblings()) do
            local flag = true
            for _, k in ipairs(kingdoms) do
                if p:getKingdom() == k then
                    flag = false
                    break
                end
            end
            if flag then
                table.insert(kingdoms, p:getKingdom())
            end
        end
        extra = #kingdoms
        room:gainMaxHp(player, extra)
        room:recover(player, sgs.RecoverStruct(player, nil, extra))
    end,
}
KanaNakada:addSkill(sakamichi_ou_xiang_chu)

sakamichi_zhi_long_mi_cheng_card = sgs.CreateSkillCard {
    name = "sakamichi_zhi_long_mi_chengCard",
    skill_name = "sakamichi_zhi_long_mi_cheng",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local players = room:getOtherPlayers(source)
        for _, p in sgs.qlist(players) do
            if p:isAlive() then
                room:cardEffect(self, source, p)
            end
        end
    end,
    on_effect = function(self, effect)
        local room = effect.to:getRoom()
        room:loseHp(effect.to, SKMC.number_correction(effect.from, 1))
    end,
}
sakamichi_zhi_long_mi_cheng = sgs.CreateViewAsSkill {
    name = "sakamichi_zhi_long_mi_cheng",
    n = 3,
    view_filter = function(self, selected, to_select)
        if #selected <= 3 then
            if #selected ~= 0 then
                local suit = selected[1]:getSuit()
                return to_select:getSuit() == suit and not sgs.Self:isJilei(to_select)
            end
            return not sgs.Self:isJilei(to_select)
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 3 then
            local cd = sakamichi_zhi_long_mi_cheng_card:clone()
            for i = 1, #cards do
                cd:addSubcard(cards[i])
            end
            return cd
        end
    end,
}
KanaNakada:addSkill(sakamichi_zhi_long_mi_cheng)

sakamichi_zhong_tian_dao = sgs.CreateTriggerSkill {
    name = "sakamichi_zhong_tian_dao",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageForseen},
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        if damage.from and SKMC.is_ki_be(damage.from, 3) then
            SKMC.send_message(room, "#zhong_tian_dao", damage.from, player, nil, nil, self:objectName(),
                SKMC.number_correction(player, 1))
            damage.damage = damage.damage + SKMC.number_correction(player, 1)
            data:setValue(damage)
        end
    end,
}
KanaNakada:addSkill(sakamichi_zhong_tian_dao)

sakamichi_ma_jiang = sgs.CreateTriggerSkill {
    name = "sakamichi_ma_jiang",
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish and not player:isKongcheng()
            and room:askForSkillInvoke(player, self:objectName(), data) then
            room:showAllCards(player)
            local colors = {}
            local all_different = true
            for _, c in sgs.qlist(player:getHandcards()) do
                local flag = true
                for _, color in ipairs(colors) do
                    if c:getSuit() == color then
                        flag = false
                        all_different = false
                        break
                    end
                end
                if not all_different then
                    break
                end
                if flag then
                    table.insert(colors, c:getSuit())
                end
            end
            if all_different and #colors > 0 then
                SKMC.send_message(room, "#ma_jiang", player, nil, nil, nil, self:objectName(), #colors)
                room:drawCards(player, #colors, self:objectName())
            end
        end
        return false
    end,
}
KanaNakada:addSkill(sakamichi_ma_jiang)

sgs.LoadTranslationTable {
    ["KanaNakada"] = "?????? ??????",
    ["&KanaNakada"] = "?????? ??????",
    ["#KanaNakada"] = "????????????",
    ["~KanaNakada"] = "????????????????????????",
    ["designer:KanaNakada"] = "Cassimolar",
    ["cv:KanaNakada"] = "?????? ??????",
    ["illustrator:KanaNakada"] = "Cassimolar",
    ["sakamichi_ou_xiang_chu"] = "?????????",
    [":sakamichi_ou_xiang_chu"] = "???????????????????????????????????????X???????????????????????????X????????????X????????????????????????",
    ["sakamichi_zhi_long_mi_cheng"] = "????????????",
    [":sakamichi_zhi_long_mi_cheng"] = "?????????????????????????????????????????????????????????????????????????????????????????????1????????????",
    ["sakamichi_zhong_tian_dao"] = "?????????",
    [":sakamichi_zhong_tian_dao"] = "????????????????????????????????????????????????????????????+1???",
    ["#zhong_tian_dao"] = "%to ??????%arg???????????????????????? %from ??? %to ?????????????????????<font color=\"yellow\"><b>1</b></font>??????",
    ["sakamichi_ma_jiang"] = "??????",
    [":sakamichi_ma_jiang"] = "?????????????????????????????????????????????????????????????????????????????????????????????????????????",
    ["#ma_jiang"] = "%from ?????????%arg??????????????????????????????????????????%arg2?????????",
}
