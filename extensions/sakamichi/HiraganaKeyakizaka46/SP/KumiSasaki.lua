require "extensions.sakamichi.package"
require "extensions.sakamichi.SKMC"

KumiSasaki_HiraganaKeyakizaka_sp = sgs.General(Sakamichi, "KumiSasaki_HiraganaKeyakizaka_sp", "HiraganaKeyakizaka46", 4,
    false)
table.insert(SKMC.IKiSei, "KumiSasaki_HiraganaKeyakizaka_sp")

--[[
    技能名：不甘
    描述：当你受到/造成伤害后，你可以摸一张牌并将一张手牌置于武将牌上称为“泪”，“泪”可以视为手牌使用或打出；出牌阶段限一次，你可以将三张“泪”视为【万箭齐发】使用；在你的延时锦囊牌的判定牌生效前，你可以打出一张“泪”代替之。
]]
LuabuganVS = sgs.CreateViewAsSkill {
    name = "Luabugan",
    n = 3,
    filter_pattern = ".|.|.|&lei",
    expand_pile = "&lei",
    view_filter = function(self, selected, to_select)
        return sgs.Self:getPile("&lei"):contains(to_select:getEffectiveId())
    end,
    view_as = function(self, cards)
        if #cards == 3 then
            local cardA = cards[1]
            local cardB = cards[2]
            local cardC = cards[3]
            local suit, number
            for _, card in ipairs(cards) do
                if suit and (suit ~= card:getSuit()) then
                    suit = sgs.Card_NoSuit
                else
                    suit = card:getSuit()
                end
                if number and (number ~= card:getNumber()) then
                    number = -1
                else
                    number = card:getNumber()
                end
            end
            local cd = sgs.Sanguosha:cloneCard("archery_attack", suit, number);
            cd:addSubcard(cardA)
            cd:addSubcard(cardB)
            cd:addSubcard(cardC)
            cd:setSkillName("Luabugan")
            return cd
        end
    end,
    enabled_at_play = function(self, player)
        return player:getPile("&lei"):length() >= 3 and not player:hasFlag("bugan_used")
    end,
}
Luabugan = sgs.CreateTriggerSkill {
    name = "Luabugan",
    events = {sgs.Damaged, sgs.Damage, sgs.AskForRetrial, sgs.CardFinished},
    view_as_skill = LuabuganVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged or event == sgs.Damage then
            room:drawCards(player, 1, self:objectName())
            if not player:isKongcheng() then
                local card_id
                if player:getHandcardNum() == 1 then
                    card_id = player:handCards():first()
                else
                    card_id = room:askForExchange(player, self:objectName(), 1, 1, false, "@buganPush"):getSubcards()
                        :first()
                end
                player:addToPile("&lei", card_id)
            end
        elseif event == sgs.AskForRetrial then
            local judge = data:toJudge()
            if (judge.reason == "indulgence" or judge.reason == "lightning" or judge.reason == "supply_shortage"
                or judge.reason == "WasabiOnigiri") and judge.who:objectName() == player:objectName() then
                local prompt_list = {"@bugan-card", judge.who:objectName(), self:objectName(), judge.reason,
                    string.format("%d", judge.card:getEffectiveId())}
                local prompt = table.concat(prompt_list, ":")
                local card = room:askForCard(player, ".|.|.|&lei", prompt, data, sgs.Card_MethodResponse, judge.who,
                    true)
                if card then
                    room:retrial(card, player, judge, self:objectName(), false)
                end
            end
        else
            local use = data:toCardUse()
            if use.card:getSkillName() == self:objectName() then
                room:setPlayerFlag(player, "bugan_used")
            end
        end
        return false
    end,
}
KumiSasaki_HiraganaKeyakizaka_sp:addSkill(Luabugan)

sgs.LoadTranslationTable {
    ["KumiSasaki_HiraganaKeyakizaka_sp"] = "佐々木 久美",
    ["&KumiSasaki_HiraganaKeyakizaka_sp"] = "SP 佐々木 久美",
    ["#KumiSasaki_HiraganaKeyakizaka_sp"] = "辟徑的才女",
    ["designer:KumiSasaki_HiraganaKeyakizaka_sp"] = "Cassimolar",
    ["cv:KumiSasaki_HiraganaKeyakizaka_sp"] = "佐々木 久美",
    ["illustrator:KumiSasaki_HiraganaKeyakizaka_sp"] = "Cassimolar",
    ["Luabugan"] = "不甘",
    [":Luabugan"] = "当你受到/造成伤害后，你可以摸一张牌并将一张手牌置于武将牌上称为“泪”，“泪”可以视为手牌使用或打出；出牌阶段限一次，你可以将三张“泪”视为【万箭齐发】使用；在你的延时锦囊牌的判定牌生效前，你可以打出一张“泪”代替之。",
    ["@buganPush"] = "请选择一张手牌置于武将牌上称为“泪”",
    ["&lei"] = "泪",
    ["@bugan-card"] = "请使用【%dest】来修改 %src 的 %arg 判定",
}
