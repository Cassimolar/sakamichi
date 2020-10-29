function SmartAI:useCardshit(card, use)

    local a = false
    local b = (card:getSuit() ~= sgs.Card_Spade and not self.player:hasSkill("jueqing"))
	
	if not self.player:isWounded() then
		if self.player:hasSkills(sgs.need_kongcheng) then 
		    if self.player:getHandcardNum() == 1 then 
                a = true			
			end
		end
		if self:getCardsNum("Peach") > 0 and self.player:getHandcardNum() - self.player:getHp() > 1 then
			self:sort(self.friends, "hp")
			if not self:isWeak(self.friends[1]) then
                a = true		
			end
		end
	end
	
	if self.player:hasSkill("tianxiang") then 
	    if b and self.player:getHandcardNum() > 4 then
		    local cards = self.player:getCards("h")
	        cards = sgs.QList2Table(cards)
	        for _, card in ipairs(cards) do
		        if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
                    a = true
					break
		        end
	        end
        end
    end	
	
	if self.player:getHandcardNum() - self.player:getHp() > 0 then
	
	    if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire) and card:getSuit() == sgs.Card_Heart and not self.player:hasSkill("jueqing") then
	        a = true
	    end
	
	    if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal) and card:getSuit() == sgs.Card_Diamond and not self.player:hasSkill("jueqing") then
	        a = true
	    end
	
	    if not self:damageIsEffective(self.player, sgs.DamageStruct_Thunder) and card:getSuit() == sgs.Card_Club and not self.player:hasSkill("jueqing") then
	        a = true
	    end
	
	    if self.player:hasSkills("kuanggu|kofkuanggu|yuce|mingshi") and b then 
            a = true
        end
		
    end
	
	if card:getSuit() == sgs.Card_Heart and self.player:hasArmorEffect("vine") then
     	a = false
	end	
	
	if self.player:hasSkills("shixin|jgyuhuo") then 
	    if card:getSuit() == sgs.Card_Heart then
            a = true
        end
    end		
	
	if self.player:hasSkills("nosyiji|yiji") then 
	    if b and self.player:getHandcardNum() > 3 and self:getCardsNum("Peach") > 0 then
	        if self.player:getHp() > 2 then 
                a = true
		    end
		    if self.player:getHp() <= 1 and self:getCardsNum("Analeptic") > 1 then
		        a = true
			end
		end
	end
	
	if self.player:hasSkills("shenfen+kuangbao") and b then
	    if self.player:getHp() > 2 then 
            a = true
		end
	end	
	
	if self.player:getHp() > getBestHp(self.player) then
	    a = true
	end
	
	if self.player:getHp() > 2 and self.player:hasSkills("fangzhu|chengxiang|noschengxiang") then
	    if b and self.player:getHp() > 2 then 
            a = true
		end
		if self.player:getHp() <= 1 and self:getCardsNum("Analeptic") > 1 then
		    a = true
		end
	end
	
	
	if self.player:getHp() > 2 and self.player:hasSkill("zhaxiang") and (card:getSuit() == sgs.Card_Spade or self.player:hasSkill("jueqing")) then
	    if self.player:getHp() > 2 then 
            a = true
		end
		if self.player:getHp() <= 1 and self:getCardsNum("Analeptic") > 1 then
		    a = true
		end
	end
	
	if self.player:hasSkill("jieming") then
	    if b then
		    if self:getJiemingChaofeng(self.player) <= -6 then 
                a = true
			end 
		end
	end
	
	if self.player:hasSkill("guixin") then
	    if b then
	        if not self.player:faceUp() then
                a = true
	        end
		    local value = 0
		    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			    value = value + self:getGuixinValue(player)
		    end
		    if value >= 1.3 then
			    a = true
	        end
        end		
	end
	
	if a == true then
	    use.card = card
    end
	
	return
	
end

sgs.ai_use_value.shit = -10
sgs.ai_use_priority.shit = 5
sgs.ai_keep_value.shit = 6
