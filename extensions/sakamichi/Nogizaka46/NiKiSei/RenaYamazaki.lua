require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

RenaYamazaki = sgs.General(Sakamichi, "RenaYamazaki", "Nogizaka46", 3, false)
SKMC.NiKiSei.RenaYamazaki = true
SKMC.SeiMeiHanDan.RenaYamazaki = {
    name = {3, 12, 8, 8},
    ten_kaku = {15, "da_ji"},
    jin_kaku = {20, "xiong"},
    ji_kaku = {16, "da_ji"},
    soto_kaku = {11, "ji"},
    sou_kaku = {31, "da_ji"},
    GoGyouSanSai = {
        ten_kaku = "tu",
        jin_kaku = "shui",
        ji_kaku = "tu",
        san_sai = "xiong",
    },
}

sakamichi_li_nv = sgs.CreateTriggerSkill {
    name = "sakamichi_li_nv",
    events = {sgs.DrawNCards},
    on_trigger = function(self, event, player, data, room)
        local n = data:toInt()
        if room:askForSkillInvoke(player, self:objectName(), data) then
            local li_nv_list = player:getTag(self:objectName()):toString():split(",")
            local list = sgs.IntList()
            local to_gain_list = sgs.IntList()
            for _, id in sgs.qlist(room:getDiscardPile()) do
                if not table.contains(li_nv_list, SKMC.true_name(sgs.Sanguosha:getCard(id))) then
                    list:append(id)
                end
            end
            if list:length() ~= 0 then
                room:fillAG(list)
                for i = 1, 2, 1 do
                    local id = room:askForAG(player, list, false, self:objectName())
                    if id ~= -1 then
                        table.insert(li_nv_list, SKMC.true_name(sgs.Sanguosha:getCard(id)))
                        room:setPlayerMark(player, "&" .. self:objectName() .. "+"
                            .. SKMC.true_name(sgs.Sanguosha:getCard(id)), 1)
                        list:removeOne(id)
                        to_gain_list:append(id)
                        room:takeAG(player, id, false)
                        if not list:isEmpty() then
                            local temp_list = list
                            for _, id1 in sgs.qlist(temp_list) do
                                if SKMC.true_name(sgs.Sanguosha:getCard(id1))
                                    == SKMC.true_name(sgs.Sanguosha:getCard(id)) then
                                    room:takeAG(nil, id1, false)
                                    list:removeOne(id1)
                                end
                            end
                        end
                    else
                        break
                    end
                end
                if to_gain_list:length() ~= 0 then
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
                    dummy:deleteLater()
                    dummy:addSubcards(to_gain_list)
                    player:obtainCard(dummy)
                end
                room:clearAG()
                room:broadcastInvoke("clearAG")
            end
            n = 0
            data:setValue(n)
            if #li_nv_list > room:getAlivePlayers():length() then
                li_nv_list = {}
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "&" .. self:objectName()) and player:getMark(mark) > 0 then
                        room:setPlayerMark(player, mark, 0)
                    end
                end
            end
            player:setTag(self:objectName(), sgs.QVariant(table.concat(li_nv_list, ",")))
        end
        return false
    end,
}
RenaYamazaki:addSkill(sakamichi_li_nv)

sakamichi_zhong_wen = sgs.CreateOneCardViewAsSkill {
    name = "sakamichi_zhong_wen",
    filter_pattern = "BasicCard|.|.|hand",
    guhuo_type = "rd",
    view_as = function(self, card)
        local cd = sgs.Self:getTag(self:objectName()):toCard()
        cd:addSubcard(card)
        cd:setSkillName(self:objectName())
        return cd
    end,
    enabled_at_play = function(self, player)
        return not player:isKongcheng() and not player:hasFlag("zhong_wen_used")
    end,
}
sakamichi_zhong_wen_used = sgs.CreateTriggerSkill {
    name = "#sakamichi_zhong_wen_used",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("TrickCard") and use.card:getSkillName() == "sakamichi_zhong_wen" then
            room:setPlayerFlag(player, "zhong_wen_used")
        end
        return false
    end,
}
Sakamichi:insertRelatedSkills("sakamichi_zhong_wen", "#sakamichi_zhong_wen_used")
RenaYamazaki:addSkill(sakamichi_zhong_wen)
RenaYamazaki:addSkill(sakamichi_zhong_wen_used)

sgs.LoadTranslationTable {
    ["RenaYamazaki"] = "山﨑 怜奈",
    ["&RenaYamazaki"] = "山﨑 怜奈",
    ["#RenaYamazaki"] = "慶應智者",
    ["~RenaYamazaki"] = "私、とにかく「失敗上等」精神なんです。",
    ["designer:RenaYamazaki"] = "Cassimolar",
    ["cv:RenaYamazaki"] = "山崎 怜奈",
    ["illustrator:RenaYamazaki"] = "Cassimolar",
    ["sakamichi_li_nv"] = "历女",
    [":sakamichi_li_nv"] = "摸牌阶段，你可以放弃摸牌，改为从弃牌堆中选择获得两张未以此法记录过牌名且不同的牌并记录牌名的牌，若已记录的牌名超过X则复原本技能记录（X为场上存活角色数）。",
    ["sakamichi_zhong_wen"] = "中文",
    [":sakamichi_zhong_wen"] = "出牌阶段限一次，你可以将手牌中的一张基本牌当一张锦囊牌使用。",
}
