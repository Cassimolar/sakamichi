--不臣
sgs.ai_skill_invoke.jinbuchen = function(self, data)
	local player = data:toPlayer()
	if self:needKongcheng(self.player, true) then return false end
	if self:isFriend(player) and (self:doNotDiscard(player, "he") or self:needToThrowArmor(player)) then return true end
	if not self:isFriend(player) and not self:doNotDiscard(player, "he") then return true end
	return false
end

--雄志
local jinxiongzhi_skill = {}
jinxiongzhi_skill.name = "jinxiongzhi"
table.insert(sgs.ai_skills, jinxiongzhi_skill)
jinxiongzhi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@jinxiongzhiMark") > 0 then
		return sgs.Card_Parse("@JinXiongzhiCard=.")
	end
end

sgs.ai_skill_use_func.JinXiongzhiCard = function(card, use, self)
	local list = self.room:getNCards(self.player:getMaxHp(), false)
	self.room:returnToTopDrawPile(list)
	local use_num = 0
	
	for _,id in sgs.qlist(list) do
		local card = sgs.Sanguosha:getCard(id)
		if not self.player:canUse(card) then break end
		if self:willUse(self.player, card) then
			use_num = use_num + 1
		else
			break
		end
	end
	
	if use_num >= 2 then
		use.card = card
	end
end

sgs.ai_use_priority.JinXiongzhiCard = 0

sgs.ai_skill_use["@@jinxiongzhi!"] = function(self, prompt, method)
	local id = self.player:getMark("jinxiongzhi_id-PlayClear") - 1
    if id < 0 then return "." end
    local card = sgs.Sanguosha:getCard(id)
	if not self.player:canUse(card) then return "." end
	local dummyuse = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardByClassName(card, dummyuse)
	if dummyuse.card and dummyuse.to and not dummyuse.to:isEmpty() then
		local tos = {}
		for _,p in sgs.qlist(dummyuse.to) do
			table.insert(tos, p:objectName())
		end
		return "@JinXiongzhiUseCard=" .. id .. "->" .. table.concat(tos, "+")
	end
	return "."
end

--权变
sgs.ai_skill_invoke.jinquanbian = function(self, data)
	return self:canDraw()
end

--第二版权变
sgs.ai_skill_invoke.secondjinquanbian = function(self, data)
	return self:canDraw()
end

--慧识
sgs.ai_skill_invoke.jinhuishi = function(self, data)
	local num = data:toString():split(":")[2]
	num = tonumber(num)
	num = math.floor(num / 2)
	return num >= 2
end

--清冷
sgs.ai_skill_use["@@jinqingleng"] = function(self, prompt, method)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:addHandPile(cards)
	self:sortByUseValue(cards, true)
	
	local name = self.player:property("jinqingleng_now_target"):toString()
	local to = self.room:findPlayerByObjectName(name)
	if not to or to:isDead() then return "." end
	
	local slashs = {}
	for _,c in ipairs(cards) do
		local slash = sgs.Sanguosha:cloneCard("slash")
        slash:addSubcard(c)
        slash:deleteLater()
        slash:setSkillName("jinqingleng")
		if self.player:canSlash(to, slash, false) then
			self.player:setFlags("slashNoDistanceLimit")
			local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName() ~= name then
					table.insert(dummy_use.current_targets, p:objectName())
				end
			end
			self:useCardSlash(slash, dummy_use)
			self.player:setFlags("-slashNoDistanceLimit")
			if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
				table.insert(slashs, c)
			end
		end
	end
	if #slashs == 0 then return "." end
	
	for _,c in ipairs(slashs) do
		if c:isKindOf("Peach") then continue end
		if c:isKindOf("Jink") and self:getCardsNum("Jink") < 2 then continue end
		if c:isKindOf("Analeptic") and self:isWeak() then continue end
		if c:isKindOf("ExNihilo") then continue end
		return "@JinQinglengCard=" .. c:getEffectiveId()
	end
	return "."
end

--巧言
sgs.ai_skill_discard.qiaoyan = function(self, discard_num, min_num, optional, include_equip)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return {cards[1]:getEffectiveId()}
end

--献珠
sgs.ai_skill_playerchosen.xianzhu = function(self, targets)
	local cards = {}
	for _,id in sgs.qlist(self.player:getPile("qyzhu")) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local card, friend = self:getCardNeedPlayer(cards, true)
	if card and friend then return friend end
	
	self:sort(self.friends_noself)
	
	for _,p in ipairs(self.friends_noself) do
		if self:canDraw(p) and not self:willSkipPlayPhase(p) then
			return p
		end
	end
	for _,p in ipairs(self.friends_noself) do
		if not (p:isKongcheng() and self:needKongcheng(p, true)) and not self:willSkipPlayPhase(p) then
			return p
		end
	end
	for _,p in ipairs(self.friends_noself) do
		if self:canDraw(p) then
			return p
		end
	end
	for _,p in ipairs(self.friends_noself) do
		if not (p:isKongcheng() and self:needKongcheng(p, true)) then
			return p
		end
	end
	
	self:sort(self.enemies)
	for _,p in ipairs(self.enemies) do
		if not hasManjuanEffect(p) then continue end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_xianzhu")
		slash:deleteLater()
		if p:isLocked(slash) then continue end
		for _,enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) and p:canSlash(enemy, slash, false) then
				return p
			end
		end
	end
	
	if #cards == 1 then
		if not cards[1]:isKindOf("Peach") and not cards[1]:isKindOf("Jink") and not cards[1]:isKindOf("Analeptic") and not cards[1]:isKindOf("ExNihilo") then
			for _,p in ipairs(self.enemies) do
				if self:canDraw(p) then continue end
				local slash = sgs.Sanguosha:cloneCard("slash")
				slash:setSkillName("_xianzhu")
				slash:deleteLater()
				if p:isLocked(slash) then continue end
				for _,enemy in ipairs(self.enemies) do
					if self.player:inMyAttackRange(enemy) and p:canSlash(enemy, slash, false) then
						return p
					end
				end
			end
		end
	end
	
	return self.player
end

sgs.ai_skill_playerchosen.xianzhu_target = function(self, targets)
	local from = self.player:getTag("xianzhu_slash_from"):toPlayer()
	local enemies, zhongli, friends = {}, {}, {}
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(enemies, p)
		elseif self:isFriend(p) then
			table.insert(friends, p)
		else
			table.insert(zhongli, p)
		end
	end
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_xianzhu")
	slash:deleteLater()
	
	if #enemies > 0 then
		self:sort(enemies)
		for _,p in ipairs(enemies) do
			if self:slashIsEffective(slash, p, from) and not self:slashProhibit(slash, p, from) and
			((self:isEnemy(from) and not sgs.isGoodTarget(p, enemies, self, true, from)) or (self:isFriend(from) and sgs.isGoodTarget(p, enemies, self, true, from))) then
				return p
			end
		end
		for _,p in ipairs(enemies) do
			if self:slashIsEffective(slash, p, from) and not self:slashProhibit(slash, p, from) then
				return p
			end
		end
		for _,p in ipairs(enemies) do
			if self:slashIsEffective(slash, p, from) and
			((self:isEnemy(from) and not sgs.isGoodTarget(p, enemies, self, true, from)) or (self:isFriend(from) and sgs.isGoodTarget(p, enemies, self, true, from))) then
				return p
			end
		end
		for _,p in ipairs(enemies) do
			if self:slashIsEffective(slash, p, from) then
				return p
			end
		end
		return enemies[1]
	end
	
	if #zhongli > 0 then
		self:sort(zhongli)
		zhongli = sgs.reverse(zhongli)
		for _,p in ipairs(zhongli) do
			if self:slashIsEffective(slash, p, from) and not self:slashProhibit(slash, p, from) and
			((self:isEnemy(from) and not sgs.isGoodTarget(p, zhongli, self, true, from)) or (self:isFriend(from) and sgs.isGoodTarget(p, zhongli, self, true, from))) then
				return p
			end
		end
		for _,p in ipairs(zhongli) do
			if self:slashIsEffective(slash, p, from) and not self:slashProhibit(slash, p, from) then
				return p
			end
		end
		for _,p in ipairs(zhongli) do
			if self:slashIsEffective(slash, p, from) and
			((self:isEnemy(from) and not sgs.isGoodTarget(p, zhongli, self, true, from)) or (self:isFriend(from) and sgs.isGoodTarget(p, zhongli, self, true, from))) then
				return p
			end
		end
		for _,p in ipairs(zhongli) do
			if self:slashIsEffective(slash, p, from) then
				return p
			end
		end
		return zhongli[1]
	end
	
	if #friends > 0 then
		self:sort(friends)
		friends = sgs.reverse(friends)
		for _,p in ipairs(friends) do
			if self:slashIsEffective(slash, p, from) and not self:slashProhibit(slash, p, from) and
			((self:isEnemy(from) and not sgs.isGoodTarget(p, friends, self, true, from)) or (self:isFriend(from) and sgs.isGoodTarget(p, friends, self, true, from))) then
				return p
			end
		end
		for _,p in ipairs(friends) do
			if self:slashIsEffective(slash, p, from) and not self:slashProhibit(slash, p, from) then
				return p
			end
		end
		for _,p in ipairs(friends) do
			if self:slashIsEffective(slash, p, from) and
			((self:isEnemy(from) and not sgs.isGoodTarget(p, friends, self, true, from)) or (self:isFriend(from) and sgs.isGoodTarget(p, friends, self, true, from))) then
				return p
			end
		end
		for _,p in ipairs(friends) do
			if self:slashIsEffective(slash, p, from) then
				return p
			end
		end
		return friends[1]
	end
	
	return targets:at(math.random(0, targets:length() - 1))
end

--才望
sgs.ai_skill_invoke.jincaiwang = function(self, data)
	local name = data:toString():split(":")[2]
	local to = self.room:findPlayerByObjectName(name)
	if not to then return false end
	return self:isEnemy(to) and not self:doNotDiscard(to, "he")
end

--车悬

--草诏

--息兵
