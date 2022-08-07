--七哀
local mobilezhiqiai_skill = {}
mobilezhiqiai_skill.name = "mobilezhiqiai"
table.insert(sgs.ai_skills, mobilezhiqiai_skill)
mobilezhiqiai_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("MobileZhiQiaiCard") then
		return sgs.Card_Parse("@MobileZhiQiaiCard=.")
	end
end

sgs.ai_skill_use_func.MobileZhiQiaiCard = function(card, use, self)
	local cards = {}
	
	if self.player:getArmor() and self:needToThrowArmor() then
		table.insert(cards, sgs.Sanguosha:getCard(self.player:getArmor():getEffectiveId()))
	else
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if c:isKindOf("BasicCard") then continue end
			table.insert(cards, c)
		end
	end
	if #cards <= 0 then return end
	
	self:sortByUseValue(cards, true)
	
	local card, friend = self:getCardNeedPlayer(cards, false)
	if card and friend then
		use.card = sgs.Card_Parse("@MobileZhiQiaiCard=" .. cards[1]:getEffectiveId())
	end
	
	self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend) then
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard=" .. cards[1]:getEffectiveId())
			if use.to then use.to:append(friend) end return
		end
	end
	
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:isKongcheng() and self:needKongcheng(enemy, true) and not hasManjuanEffect(enemy) then
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard=" .. cards[1]:getEffectiveId())
			if use.to then use.to:append(enemy) end return
		end
	end
	
	if self.player:getLostHp() > 0 or self:getOverflow() - 1 <= 0 then
		for _, friend in ipairs(self.friends_noself) do
			if not (friend:isKongcheng() and self:needKongcheng(friend, true)) or hasManjuanEffect(friend) then
				use.card = sgs.Card_Parse("@MobileZhiQiaiCard=" .. cards[1]:getEffectiveId())
				if use.to then use.to:append(friend) end return
			end
		end
		
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(p) or self:isEnemy(p) then continue end
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard=" .. cards[1]:getEffectiveId())
			if use.to then use.to:append(p) end return
		end
		
		if #self.enemies > 0 and not self:isValuableCard(cards[1]) and self:canDraw() and (self.player:getHp() ~= getBestHp(self.player) or self.player:getLostHp() == 0) then
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard=" .. cards[1]:getEffectiveId())
			if use.to then use.to:append(self.enemies[1]) end return
		end
	end
end

sgs.ai_use_priority.MobileZhiQiaiCard = 1.6

sgs.ai_card_intention.MobileZhiQiaiCard = function(self, card, from, tos)
	local intention = -20
	for _,to in ipairs(tos) do
		if hasManjuanEffect(to) then continue end
		if self:needKongcheng(to, true) and to:isKongcheng() then
			intention = 20
		end
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_skill_choice.mobilezhiqiai = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if not self:canDraw() then return "recover" end
		if target:getHp() >= getBestHp(target) then return "draw" end
		return "recover"
	else
		if not self:canDraw() then return "draw" end
		if target:getHp() == getBestHp(target) then return "recover" end
		return "draw"
	end
end

--善檄
sgs.ai_skill_playerchosen.mobilezhishanxi = function(self, targets)
	local enemies = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(enemies, p)
		end
	end
	if #enemies <= 0 then return nil end
	self:sort(enemies, "hp")
	return enemies[1]
end

sgs.ai_skill_discard.mobilezhishanxi = function(self, discard_num, min_num, optional, include_equip)
	local give = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	if self:needToThrowArmor() then
		table.insert(give, self.player:getArmor():getEffectiveId())
		for _,c in ipairs(cards) do
			if c:getEffectiveId() == self.player:getArmor():getEffectiveId() then continue end
			table.insert(give, c:getEffectiveId())
			break
		end
		if #give == 2 then return give end
	end
	--if self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0 or self:getSaveNum(true) > 0 then return {} end  回复后还是会要求再选一次，不如给牌算了
	if not self:isWeak() and self.player:hasSkill("zhaxiang") and not self:willSkipPlayPhase() then return {} end
	for _,c in ipairs(cards) do
		table.insert(give, c:getEffectiveId())
		if #give == 2 then return give end
	end
	return give
end

--挽危
local mobilezhiwanwei_skill = {}
mobilezhiwanwei_skill.name = "mobilezhiwanwei"
table.insert(sgs.ai_skills, mobilezhiwanwei_skill)
mobilezhiwanwei_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isLord() then return end
	if self.player:hasUsed("MobileZhiWanweiCard") or #self.friends_noself == 0 or self.player:getHp() < 0 then return end
	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self:getSaveNum(true) <= 0 and not hasBuquEffect(self.player) then return end
	return sgs.Card_Parse("@MobileZhiWanweiCard=.")
end

sgs.ai_skill_use_func.MobileZhiWanweiCard = function(card, use, self)
	self:sort(self.friends_noself, "hp")
	for _,p in ipairs(self.friends_noself) do
		if not self:isWeak(p) then continue end
		use.card = card
		if use.to then use.to:append(p) end return
	end
end

sgs.ai_use_priority.MobileZhiWanweiCard = 1.6
sgs.ai_card_intention.MobileZhiWanweiCard = -80

sgs.ai_skill_invoke.mobilezhiwanwei = function(self, data)
	if self.player:isLord() then return false end
	local friend = data:toPlayer()
	return self:isFriend(friend)
end

--约俭
sgs.ai_skill_cardask["@mobilezhiyuejian"] = function(self, data, pattern, target)
	local dis = self:askForDiscard("dummyreason", 2, 2, false, true)
	if #dis == 2 then
		for _,id in ipairs(dis) do
			local card = sgs.Sanguosha:getCard(id)
			if (card:isKindOf("Peach") or card:isKindOf("Analeptic")) and self.player:canUse(card) then return "." end
		end
		return "$"..table.concat(dis, "+")
	end
	return "."
end

--歃盟
local mobilezhishameng_skill = {}
mobilezhishameng_skill.name = "mobilezhishameng"
table.insert(sgs.ai_skills, mobilezhishameng_skill)
mobilezhishameng_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("MobileZhiShamengCard") and self.player:getHandcardNum() >= 2 and #self.friends_noself > 0 then
		return sgs.Card_Parse("@MobileZhiShamengCard=.")
	end
end

sgs.ai_skill_use_func.MobileZhiShamengCard = function(card, use, self)
	local target
	self:sort(self.friends_noself)
	for _,p in ipairs(self.friends_noself) do
		if self:canDraw(p) and not p:isDead() then
			target = p
			break
		end
	end
	if not target then return end
	
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	
	local dis = {}
	
	for _,c in ipairs(cards) do
		local _dis = {}
		for _,c2 in ipairs(cards) do
			if c2:getEffectiveId() == c:getEffectiveId() then continue end
			if not c2:sameColorWith(c) then continue end
			table.insert(_dis, c)
			table.insert(_dis, c2)
			break
		end
		if #_dis == 2 then
			table.insert(dis, _dis)
		end
	end
	if #dis == 0 then return end
	
	local function keepvaluesort(t1, t2)
		local a = self:getKeepValue(t1[1]) + self:getKeepValue(t1[2])
		local b = self:getKeepValue(t2[1]) + self:getKeepValue(t2[2])
		return a < b
	end
	table.sort(dis, keepvaluesort)
	
	use.card = sgs.Card_Parse("@MobileZhiShamengCard=" .. dis[1][1]:getEffectiveId() .. "+" .. dis[1][2]:getEffectiveId())
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority.MobileZhiShamengCard = sgs.ai_use_priority.NosJujianCard
sgs.ai_card_intention.MobileZhiShamengCard = -80

--谏喻
local mobilezhijianyu_skill = {}
mobilezhijianyu_skill.name = "mobilezhijianyu"
table.insert(sgs.ai_skills, mobilezhijianyu_skill)
mobilezhijianyu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("MobileZhiJianyuCard") and #self.enemies > 0 then
		return sgs.Card_Parse("@MobileZhiJianyuCard=.")
	end
end

sgs.ai_skill_use_func.MobileZhiJianyuCard = function(card, use, self)
	if self.room:getAlivePlayers():length() == 2 then
		use.card = card
		if use.to then
			use.to:append(self.room:getAlivePlayers():first())
			use.to:append(self.room:getAlivePlayers():last())
		end
		return
	end
	
	self:sort(self.enemies, "threat")
	self:sort(self.friends)
	
	for _,enemy in ipairs(self.enemies) do
		for _,friend in ipairs(self.friends) do
			if enemy:canSlash(friend) then
				use.card = card
				if use.to then
					use.to:append(enemy)
					use.to:append(friend)
				end
				return
			end
		end
	end
end

sgs.ai_use_priority.MobileZhiJianyuCard = 0

--生息
sgs.ai_skill_invoke.mobilezhishengxi = function(self, data)
	return self:canDraw()
end

--辅弼
sgs.ai_skill_playerchosen.mobilezhifubi = function(self, targets)
	if self.player:getRole() == "loyalist" and self.room:getLord() and targets:contains(self.room:getLord()) then
		return self.room:getLord()
	end
	
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if p:isYourFriend(self.player) and p:getMark("&mobilezhifu") <= 0 then  --作弊
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends, "maxcards")
		return friends[1]
	end
	for _,p in sgs.qlist(targets) do
		if p:isYourFriend(self.player) then  --作弊
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends, "maxcards")
		return friends[1]
	end
	return nil
end

--罪辞
sgs.ai_skill_invoke.mobilezhizuici = function(self, data)
	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 1 - self.player:getHp() then return true end
	return false
end

sgs.ai_skill_choice.mobilezhizuici = function(self, choices, data)
	return self:throwEquipArea(choices)
end

--第二版辅弼
sgs.ai_skill_playerchosen.secondmobilezhifubi = function(self, targets)
	return sgs.ai_skill_playerchosen.mobilezhifubi(self, targets)
end

sgs.ai_skill_invoke.secondmobilezhifubi = function(self, data)
	local player = data:toPlayer()
	return self:isFriend(player)
end

sgs.ai_skill_choice.secondmobilezhifubi = function(self, choices, data)
	choices = choices:split("+")
	local player = data:toPlayer()
	if player:isSkipped(sgs.Player_Discard) then  --将会跳过弃牌阶段待补充
		if self:isFriend(player) then
			return "slash"
		else
			return "max"
		end
	end
	if player:canSlashWithoutCrossbow() then
		if self:isFriend(player) then
			return "max"
		else
			return "slash"
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	if self:canUse(slash, self:getEnemies(player), player) and getCardsNum("Slash", player, self.player) > 1 then
		if self:isFriend(player) then
			return "slash"
		else
			return "max"
		end
	end
	if self:getOverflow(player) > player:getMaxCards() then
		if self:isFriend(player) then
			return "max"
		else
			return "slash"
		end
	end
	if self:isFriend(player) then
		return "max"
	else
		return "slash"
	end
end

--第二版罪辞
local secondmobilezhizuici_skill = {}
secondmobilezhizuici_skill.name = "secondmobilezhizuici"
table.insert(sgs.ai_skills, secondmobilezhizuici_skill)
secondmobilezhizuici_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("SecondMobileZhiZuiciCard") and self:isWeak() and self.player:hasEquipArea() and not self.player:getEquips():isEmpty() then
		return sgs.Card_Parse("@SecondMobileZhiZuiciCard=.")
	end
end

sgs.ai_skill_use_func.SecondMobileZhiZuiciCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.SecondMobileZhiZuiciCard = 0

sgs.ai_skill_choice.secondmobilezhizuici = function(self, choices, data)
	return self:throwEquipArea(choices)
end

sgs.ai_skill_invoke.secondmobilezhizuici = function(self, data)
	return sgs.ai_skill_invoke.mobilezhizuici(self, data)
end

sgs.ai_skill_use["@@secondmobilezhizuici"] = function(self, prompt)
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("&mobilezhifu") > 0 then
			table.insert(enemies, enemy)
		end
	end
	if #enemies > 0 then
		self:sort(enemies, "maxcards")
		local friends = {}
		for _, friend in ipairs(self.friends) do
			if friend:getMark("&mobilezhifu") == 0 then
				table.insert(friends, friend)
			end
		end
		if #friends > 0 then
			self:sort(friends, "maxcards")
			return "@SecondMobileZhiZuiciMarkCard=.->" .. enemies[1]:objectName() .. "+" .. friends[1]:objectName()
		end
		self:sort(self.friends, "maxcards")
		return "@SecondMobileZhiZuiciMarkCard=.->" .. enemies[1]:objectName() .. "+" .. self.friends[1]:objectName()
	end
	
	--[[local friends = {}  --移友方标记待补充
	for _, friend in ipairs(self.friends) do
		if friend:getMark("&mobilezhifu") > 0 then
			table.insert(friends, friend)
		end
	end
	if #friends > 0 then
		self:sort(friends)
		
	end]]
	return "."
end

--夺冀
local mobilezhiduoji_skill = {}
mobilezhiduoji_skill.name = "mobilezhiduoji"
table.insert(sgs.ai_skills, mobilezhiduoji_skill)
mobilezhiduoji_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@mobilezhiduojiMark") == 0 or self.player:getHandcardNum() <= 2 then return end
	return sgs.Card_Parse("@MobileZhiDuojiCard=.")
end

sgs.ai_skill_use_func.MobileZhiDuojiCard = function(card, use, self)
	local cards = self:askForDiscard("dummyreason", 2, 2, false, false)
	if #cards ~= 2 then return end
	local enemies = {}
	self:sort(self.enemies, "equip")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do
		if not self:doNotDiscard(p, "e") and p:getEquips():length() >= 2 then
			sgs.ai_use_priority.MobileZhiDuojiCard = sgs.ai_use_priority.Slash + 0.1
			use.card = sgs.Card_Parse("@MobileZhiDuojiCard=" .. cards[1] .. "+" .. cards[2])
			if use.to then use.to:append(p) end
			return
		end
	end
	if self:getOverflow() >= 2 then
		self:sort(self.friends_noself)
		for _,p in ipairs(self.friends_noself) do
			if p:getEquips():length() == 1 and not (p:hasTreasure("wooden_ox") and not p:getPile("wooden_ox"):isEmpty()) then
				if self:doNotDiscard(p, "e") or self:needToThrowArmor(p) then
					use.card = sgs.Card_Parse("@MobileZhiDuojiCard=" .. cards[1] .. "+" .. cards[2])
					if use.to then use.to:append(p) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.MobileZhiDuojiCard = 1.6

--谏战
local mobilezhijianzhan_skill = {}
mobilezhijianzhan_skill.name = "mobilezhijianzhan"
table.insert(sgs.ai_skills, mobilezhijianzhan_skill)
mobilezhijianzhan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("MobileZhiJianzhanCard") then return end
	return sgs.Card_Parse("@MobileZhiJianzhanCard=.")
end

sgs.ai_skill_use_func.MobileZhiJianzhanCard = function(card, use, self)
	local target
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:setSkillName("_mobilezhijianzhan")
	slash:deleteLater()
	
	self:sort(self.friends_noself, "threat")
	self:sort(self.enemies, "defense")
	for _, friend in ipairs(self.friends_noself) do
		for _, enemy in ipairs(self.enemies) do
			if friend:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) and sgs.getDefenseSlash(enemy, self) <= 2
					and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
					and enemy:objectName() ~= self.player:objectName() and enemy:getHandcardNum() < friend:getHandcardNum() then
				target = friend
				self.MobileZhiJianzhanTarget = enemy
				break
			end
		end
		if target then break end
	end

	if not target and self:canDraw() then
		self:sort(self.friends_noself, "defense")
		target = self.friends_noself[1]
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.MobileZhiJianzhanCard = sgs.ai_use_priority.Slash + 0.05

sgs.ai_skill_choice.mobilezhijianzhan = function(self, choices, data)
	local from = data:toPlayer()
	if not self:isFriend(from) then return "draw" end
	
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:setSkillName("_mobilezhijianzhan")
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) and sgs.getDefenseSlash(enemy, self) <= 2
		and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
		and enemy:getHandcardNum() < self.player:getHandcardNum() then
			return "slash"
		end
	end
	return "draw"
end

sgs.ai_skill_playerchosen.mobilezhijianzhan = function(self, targets)
	if self.MobileZhiJianzhanTarget then return self.MobileZhiJianzhanTarget end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

--灭吴











