sgs.ai_skill_choice.liangzhu = function(self, choices, data)
	local current = self.room:getCurrent()
	if self:isFriend(current) and (self:isWeak(current) or current:hasSkills(sgs.cardneed_skill))then
		return "letdraw"
	end
	return "draw"
end

sgs.ai_skill_invoke.cihuai = function(self, data)
	local has_slash = false
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then has_slash = true end
	end
	if has_slash then return false end

	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
		if eff and self.player:canSlash(enemy) and not self:slashProhibit(nil, enemy) then
			return true
		end
	end

return false
end

local cihuai_skill = {}
cihuai_skill.name = "cihuai"
table.insert(sgs.ai_skills, cihuai_skill)
cihuai_skill.getTurnUseCard = function(self)
	if self.player:getMark("@cihuai") > 0 then
		local card_str = ("slash:_cihuai[no_suit:0]=.")
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end
end

sgs.ai_skill_invoke.kunfen = function(self, data)
	if not self:isWeak() and (self.player:getHp() > 2 or (self:getCardsNum("Peach") > 0 and self.player:getHp() > 1)) then
		return true
	end
return false
end

local chixin_skill={}
chixin_skill.name="chixin"
table.insert(sgs.ai_skills,chixin_skill)
chixin_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local diamond_card

	self:sortByUseValue(cards,true)

	local useAll = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end


	for _,card in ipairs(cards)  do
		if card:getSuit() == sgs.Card_Diamond
		and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
		and (not isCard("Crossbow", card, self.player) and not disCrossbow)
		and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0) then
			diamond_card = card
			break
		end
	end

	if not diamond_card then return nil end
	local suit = diamond_card:getSuitString()
	local number = diamond_card:getNumberString()
	local card_id = diamond_card:getEffectiveId()
	local card_str = ("slash:chixin[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.chixin = function(card, player, card_place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:getSuit() == sgs.Card_Diamond and not card:isKindOf("Peach") and not card:hasFlag("using") then
		if class_name == "Slash" then
			return ("slash:chixin[%s:%s]=%d"):format(suit, number, card_id)
		elseif class_name == "Jink" then
			return ("jink:chixin[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_cardneed.chixin = function(to, card)
	return card:getSuit() == sgs.Card_Diamond
end

sgs.ai_skill_playerchosen.suiren = function(self, targets)
	if self.player:getMark("@suiren") == 0 then return "." end
	if self:isWeak() and (self:getOverflow() < -2 or not self:willSkipPlayPhase()) then return self.player end
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) and not self:needKongcheng(friend) then
			return friend
		end
	end
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (self:isWeak(enemy) and enemy:getHp() == 1)
			and self.player:getHandcardNum() < 2 and not self:willSkipPlayPhase() and self.player:inMyAttackRange(enemy) then
			return self.player
		end
	end
end

sgs.ai_playerchosen_intention.suiren = -60

sgs.ai_skill_use["@@jiqiao"] = function(self, prompt, method)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(usable_cards, true)
	local use_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:isKindOf("Armor") or c:isKindOf("DefensiveHorse") or c:isKindOf("OffensiveHorse") or (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() == 0) then
			table.insert(use_cards, c:getEffectiveId())
		end
	end
	if #use_cards == 0 then return end
	if #use_cards > 0 then
		return "@JiqiaoCard=" .. table.concat(use_cards, "+")
	end
end