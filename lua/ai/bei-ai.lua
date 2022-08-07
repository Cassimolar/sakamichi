--宝箧
sgs.ai_skill_invoke.jinbaoqie = function(self, data)
	return not self.player:getTreasure()
end

--宜室
sgs.ai_skill_use["@@jinyishi"] = function(self, data)
	local card_ids = self.player:getTag("jinyishi_forAI"):toString():split("+")
	local who = self.player:getTag("jinyishi_from"):toPlayer()

	if self:isLihunTarget(self.player, #card_ids - 1) then return "." end
	local invoke = (self:isFriend(who) and not (who:hasSkill("kongcheng") and who:isKongcheng()))
					or (#card_ids >= 3 and not self.player:hasSkill("manjuan"))
					or (#card_ids == 2 and not self:hasSkills(sgs.cardneed_skill, who) and not self.player:hasSkill("manjuan"))
					or (self:isEnemy(who) and who:hasSkill("kongcheng") and who:isKongcheng())
	if not invoke then return "." end

	local wulaotai = self.room:findPlayerBySkillName("buyi")
	local Need_buyi = wulaotai and who:getHp() == 1 and self:isFriend(who, wulaotai)

	local cards, except_Equip, except_Key = {}, {}, {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		if self.player:hasSkills("zhijian|mobilezhijianzhan") and not card:isKindOf("EquipCard") then
			table.insert(except_Equip, card)
		end
		if not card:isKindOf("Peach") and not card:isKindOf("Jink") and not card:isKindOf("Analeptic") and
			not card:isKindOf("Nullification") and not (card:isKindOf("EquipCard") and self.player:hasSkills("zhijian|mobilezhijianzhan")) then
			table.insert(except_Key, card)
		end
		table.insert(cards, card)
	end

	if self:isFriend(who) then

		if Need_buyi then
			local buyicard1, buyicard2
			self:sortByKeepValue(cards)
			for _, card in ipairs(cards) do
				if card:isKindOf("TrickCard") and not buyicard1 then
					buyicard1 = card:getEffectiveId()
				end
				if not card:isKindOf("BasicCard") and not buyicard2 then
					buyicard2 = card:getEffectiveId()
				end
				if buyicard1 then break end
			end
			if buyicard1 then
				return "@JinYishiCard="..buyicard1
			elseif buyicard2 then
				return "@JinYishiCard="..buyicard2
			end
		end

		local peach_num, peach, jink, analeptic, slash = 0
		for _, card in ipairs(cards) do
			if card:isKindOf("Peach") then peach = card:getEffectiveId() peach_num = peach_num + 1 end
			if card:isKindOf("Jink") then jink = card:getEffectiveId() end
			if card:isKindOf("Analeptic") then analeptic = card:getEffectiveId() end
			if card:isKindOf("Slash") then slash = card:getEffectiveId() end
		end
		if peach then
			if peach_num > 1
				or (self:getCardsNum("Peach") >= self.player:getMaxCards())
				or (who:getHp() < getBestHp(who) and who:getHp() < self.player:getHp()) then
					return "@JinYishiCard="..peach
			end
		end
		if self:isWeak(who) and (jink or analeptic) then
			if jink then
				return "@JinYishiCard="..jink
			elseif analeptic then
				return "@JinYishiCard="..analeptic
			end
		end

		for _, card in ipairs(cards) do
			if not card:isKindOf("EquipCard") then
				for _, askill in sgs.qlist(who:getVisibleSkillList(true)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback)=="function" and callback(who, card, self) then
						return "@JinYishiCard="..card:getEffectiveId()
					end
				end
			end
		end

		if jink or analeptic or slash then
			if jink then
				return "@JinYishiCard="..jink
			elseif analeptic then
				return "@JinYishiCard="..analeptic
			elseif slash then
				return "@JinYishiCard="..slash
			end
		end

		for _, card in ipairs(cards) do
			if not card:isKindOf("EquipCard") and not card:isKindOf("Peach") then
				return "@JinYishiCard="..card:getEffectiveId()
			end
		end

	else

		if Need_buyi then
			for _, card in ipairs(cards) do
				if card:isKindOf("Slash") then
					return "@JinYishiCard="..card:getEffectiveId()
				end
			end
		end

		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and self.player:hasSkills("zhijian|mobilezhijianzhan") then
				local Cant_Zhijian = true
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) then
						Cant_Zhijian = false
					end
				end
				if Cant_Zhijian then
					return "@JinYishiCard="..card:getEffectiveId()
				end
			end
		end

		local new_cards = (#except_Key > 0 and except_Key) or (#except_Equip > 0 and except_Equip) or cards

		self:sortByKeepValue(new_cards)
		local valueless, slash
		for _, card in ipairs (new_cards) do
			if card:isKindOf("Lightning") and not self:hasSkills(sgs.wizard_harm_skill, who) then
				return "@JinYishiCard="..card:getEffectiveId()
			end

			if card:isKindOf("Slash") then slash = card:getEffectiveId() end

			if not valueless and not card:isKindOf("Peach") then
				for _, askill in sgs.qlist(who:getVisibleSkillList(true)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if (type(callback)=="function" and not callback(who, card, self)) or not callback then
						valueless = card:getEffectiveId()
						break
					end
				end
			end
		end

		if slash or valueless then
			if slash then
				return "@JinYishiCard="..slash
			elseif valueless then
				return "@JinYishiCard="..valueless
			end
		end

		return "@JinYishiCard="..new_cards[1]:getEffectiveId()
	end
end

--识度
local jinshidu_skill = {}
jinshidu_skill.name = "jinshidu"
table.insert(sgs.ai_skills, jinshidu_skill)
jinshidu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("JinShiduCard") or not self.player:canPindian() then return end
	return sgs.Card_Parse("@JinShiduCard=.")
end

sgs.ai_skill_use_func.JinShiduCard = function(card, use, self)
	local max_card = self:getMaxCard()
	if max_card then
		local number = max_card:getNumber()
		if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then number = 13 end
		if number >= 7 then
			self:sort(self.enemies, "handcard")
			self.enemies = sgs.reverse(self.enemies)
			for _,p in ipairs(self.enemies) do
				if self:doNotDiscard(p, "h") or not self.player:canPindian(p) then continue end
				if math.floor((p:getHandcardNum() + self.player:getHandcardNum()) / 2) < self.player:getHandcardNum() then continue end
				use.card = card
				self.jinshidu_card = max_card
				if use.to then use.to:append(p) end
				return
			end
			
			self:sort(self.friends_noself, "handcard")
			for _,p in ipairs(self.friends_noself) do
				if not self:doNotDiscard(p, "h") or not self.player:canPindian(p) then continue end
				if math.floor((p:getHandcardNum() + self.player:getHandcardNum()) / 2) < p:getHandcardNum() then continue end
				--if self:needKongcheng(p, true) then continue end
				if p:hasSkill("kongcheng") and p:getHandcardNum() == 1 then continue end
				sgs.ai_use_priority.JinShiduCard = 5
				use.card = card
				self.jinshidu_card = max_card
				if use.to then use.to:append(p) end
				return
			end
			for _,p in ipairs(self.friends_noself) do
				if not self.player:canPindian(p) then continue end
				if math.floor((p:getHandcardNum() + self.player:getHandcardNum()) / 2) < p:getHandcardNum() then continue end
				--if self:needKongcheng(p, true) then continue end
				if p:hasSkill("kongcheng") and p:getHandcardNum() == 1 then continue end
				sgs.ai_use_priority.JinShiduCard = 5
				use.card = card
				self.jinshidu_card = max_card
				if use.to then use.to:append(p) end
				return
			end
		end
	end
	
	local min_card = self:getMinCard()
	if min_card then
		local number = min_card:getNumber()
		if number < 7 then
			self:sort(self.friends_noself, "handcard")
			for _,p in ipairs(self.friends_noself) do
				if not self.player:canPindian(p) then continue end
				if not self:needToThrowLastHandcard(p) then continue end
				sgs.ai_use_priority.JinShiduCard = 5
				use.card = card
				self.jinshidu_card = min_card
				if use.to then use.to:append(p) end
				return
			end
			self.friends_noself = sgs.reverse(self.friends_noself)
			for _,p in ipairs(self.friends_noself) do
				if not self.player:canPindian(p) then continue end
				if self:doNotDiscard(p, "h") and (not self:isWeak(p) or self:getEnemyNumBySeat(self.player, p, p) == 0) then
					sgs.ai_use_priority.JinShiduCard = 5
					use.card = card
					self.jinshidu_card = min_card
					if use.to then use.to:append(p) end
					return
				end
			end
			if self:getOverflow(self.player, true) > 0 then
				self:sort(self.enemies, "handcard")
				for _,p in ipairs(self.enemies) do
					if self:doNotDiscard(p, "h") or not self.player:canPindian(p) then continue end
					sgs.ai_use_priority.JinShiduCard = 0
					use.card = card
					self.jinshidu_card = min_card
					if use.to then use.to:append(p) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.JinShiduCard = 10.1

function sgs.ai_skill_pindian.jinshidu(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_skill_discard.jinshidu = function(self, discard_num, min_num, optional, include_equip)
	local dis = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(cards, true)
	local n = math.min(math.floor(#cards/2), min_num)
	for i = 1, n do
		table.insert(dis, cards[i]:getEffectiveId())
	end
	return dis
end

--韬隐
sgs.ai_skill_invoke.jintaoyin = function(self, data)
	local current = data:toPlayer()
	return self:isEnemy(current)
end

--夷灭
sgs.ai_skill_invoke.jinyimie = function(self, data)
	local str = data:toString():split(":")
	local name = str[2]
	local n = str[4]
	local to = self.room:findPlayerByObjectName(name)
	if not to or to:isDead() or not self:isEnemy(to) or tonumber(n) <= 0 then return false end
	if self:cantDamageMore(self.player, to) then return false end
	return true
end

--睿略
local jinruilve_give_skill = {}
jinruilve_give_skill.name = "jinruilve_give"
table.insert(sgs.ai_skills, jinruilve_give_skill)
jinruilve_give_skill.getTurnUseCard = function(self)
	if self.player:getKingdom() ~= "jin" or self:getOverflow(self.player, true) <= 0 then return end
	return sgs.Card_Parse("@JinRuilveGiveCard=.")
end

sgs.ai_skill_use_func.JinRuilveGiveCard = function(card, use, self)
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Slash") or (c:isDamageCard() and c:isKindOf("TrickCard")) then
			table.insert(cards, c)
		end
	end
	if #cards == 0 then return end
	self:sortByUseValue(cards, true)
	self:sort(self.friends_noself, "handcard")
	for _, p in ipairs(self.friends_noself) do
		if not self:canDraw(p) or not p:hasLordSkill("jinruilve") or p:getMark("jinruilve-PlayClear") > 0 then continue end
		use.card = sgs.Card_Parse("@JinRuilveGiveCard=" .. cards[1]:getEffectiveId())
		if use.to then use.to:append(p) end
		return
	end
end

sgs.ai_use_priority.JinRuilveGiveCard = 0

--慧容
sgs.ai_skill_playerchosen.jinhuirong = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
		if self:canDraw(p) and self:isWeak(p) then
			return p
		end
	end
	
	local new_targets = {}
	for _,p in ipairs(targets) do
		if self:isFriend(p) or self:isEnemy(p) then
			table.insert(new_targets, p)
		end
	end
	if #new_targets > 0 then
		local numsort = function(a, b)
			local c1, c2
			if a:getHp() > a:getHandcardNum() then
				c1 = math.min(a:getHp(), 5) - a:getHandcardNum()
			else
				c1 = a:getHandcardNum() - a:getHp()
			end
			if b:getHp() > b:getHandcardNum() then
				c2 = math.min(b:getHp(), 5) - b:getHandcardNum()
			else
				c2 = b:getHandcardNum() - b:getHp()
			end
			c1 = math.abs(c1)
			c2 = math.abs(c2)
			return c1 > c2
		end
		self:sort(targets)
		table.sort(targets, numsort)
		
		if self:isFriend(targets[1]) and targets[1]:getHandcardNum() <= targets[1]:getHp() then return targets[1] end
		if self:isEnemy(targets[1]) and targets[1]:getHandcardNum() >= targets[1]:getHp() then return targets[1] end
	end
	if self.player:getHp() >= self.player:getHandcardNum() then
		return self.player
	end
	for _,p in ipairs(targets) do
		if self:isFriend(p) or self:isEnemy(p) then continue end
		return p
	end
	return self.player
end

--慈威
sgs.ai_skill_cardask["@jinciwei-discard"] = function(self, data)
	local player = self.player:getTag("jinciwei-player"):toPlayer()
	if self:isEnemy(player) then
		local to_discard = self:askForDiscard("dummyreason", 1, 1, false, true)
		if #to_discard > 0 then return "$" .. to_discard[1] end
	end
	return "."
end

