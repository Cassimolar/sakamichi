--往烈
sgs.ai_skill_invoke.wanglie = function(self, data)
	local use = data:toCardUse()
	return use.card:isKindOf("Duel") or use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") or use.card:isKindOf("Slash") or use.card:hasFlag("drank")
end

--罪论
sgs.ai_skill_invoke.zuilun = function(self, data)
	local n = 0
	if self.player:getMark("damage_point_round") > 0 then n = n + 1 end
	local minhandnum = true
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHandcardNum() < self.player:getHandcardNum() then
			minhandnum = false
			break
		end
	end
	if minhandnum then n = n + 1 end
	if self.player:getMark("zuilun_discard-Clear") <= 0 then n = n + 1 end
	
	if n == 0 then
		local to = self:findPlayerToLoseHp()
		if not to then return false end
		if to:getHp() > self.player:getHp() then return false end
		if (self.player:isLord() or self.player:getRole() == "renegade") and self:isWeak() then return false end
		return true
	end
	if self:hasJieyingyEffect(self.player) then return false end
	return true
end

sgs.ai_skill_playerchosen.zuilun = function(self, targets)
	return self:findPlayerToLoseHp() or targets[1]
end

sgs.ai_playerchosen_intention.zuilun = function(self, from, to)
	if self:needToLoseHp(friend, self.player, false, true) then return end
	if to:hasSkill("zhaxiang") then return end
	sgs.updateIntention(from, to, 10)
end

--良姻
sgs.ai_skill_playerchosen.liangyin = function(self, targets)
	local tos = sgs.QList2Table(targets)
	self:sort(tos)
	for _,p in ipairs(tos) do
		if p:getHandcardNum() > self.player:getHandcardNum() and self:isFriend(p) and self:canDraw(p) then
			return p
		elseif p:getHandcardNum() < self.player:getHandcardNum() and p:canDiscard(p, "he") then
			if self:isEnemy(p) and not self:needToThrowCard(p) and not (not self:hasLoseHandcardEffective(p) and not p:isKongcheng()) then return p end
			if self:isFriend(p) and self:needToThrowCard(p) then return p end
		end
	end
	if tos[1]:getHandcardNum() > self.player:getHandcardNum() then self:noChoice(targets, "draw") end
	if tos[1]:getHandcardNum() < self.player:getHandcardNum() then self:noChoice(targets, "letDis") end
	return nil
end

sgs.ai_playerchosen_intention.liangyin = function(self, from, to)
	if to:getHandcardNum() > from:getHandcardNum() and self:canDraw(to, from) then sgs.updateIntention(from, to, -10) end
	if to:getHandcardNum() < from:getHandcardNum() and not self:needToThrowCard(to) then sgs.updateIntention(from, to, 10) end
end

--箜声
sgs.ai_skill_discard.kongsheng = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	self:sortByKeepValue(cards)
	if (self:needKongcheng() and not self.player:isKongcheng()) or self.player:containsTrick("indulgence") then
		for _, card in ipairs(cards) do
			table.insert(to_discard, card:getId())
		end
	end
	
	local useSlash = false
	local slash, ana, peach = 0, 0, 0
	for _, card in ipairs(cards) do
		if (card:isKindOf("Jink") or card:isKindOf("DefensiveHorse")) and not table.contains(to_discard, card:getId()) then
			table.insert(to_discard, card:getId())
		elseif card:isKindOf("Slash") then
			if self:willUse(self.player, card, false, false, true) then
				useSlash = true
				slash = slash + 1
			else
				if not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
			end
			if slash > 1 and not self:hasCrossbowEffect() and not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		elseif card:isKindOf("Analeptic") then
			if (not useSlash or ana > 0) and not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
			ana = ana + 1
		elseif card:isKindOf("TrickCard") and not card:isKindOf("ExNihilo") and not card:isKindOf("Nullification") then
			local dummyuse = { isDummy = true }
			self:useTrickCard(card, dummyuse)
			if not dummyuse.card then
				if not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
			end
		elseif card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
			if not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		elseif card:isKindOf("Weapon") and self.player:getWeapon() and #to_discard == 0 then
			if not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		elseif card:isKindOf("Peach") then
			local dummy_use = { isDummy = true }
			self:useBasicCard(card, dummy_use)
			if dummy_use.card then
				peach = peach + 1
			else
				if not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
			end
			if peach > 1 and not table.contains(to_discard, card:getId()) then table.insert(to_discard, card:getId()) end
		end
	end
	if self:needToThrowArmor() then table.insert(to_discard, self.player:getArmor():getId()) end
	if self.player:getDefensiveHorse() then table.insert(to_discard, self.player:getDefensiveHorse():getId()) end
	return to_discard
end

--决堰
local jueyan_skill = {}
jueyan_skill.name = "jueyan"
table.insert(sgs.ai_skills, jueyan_skill)
jueyan_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("JueyanCard") and self.player:hasEquipArea() then
		return sgs.Card_Parse("@JueyanCard=.")
	end
end

sgs.ai_skill_use_func.JueyanCard = function(card, use, self)
	self.jueyan = nil
	if self:needToThrowArmor() and self.player:hasEquipArea(1) then 
		sgs.ai_use_priority.JueyanCard = 10
		self.jueyan = "1"
		use.card = card
		return
	end
	
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local w, h, t = 0, 0, 0
	for _,c in ipairs(cards) do
		if c:isKindOf("Slash") then
			if self:willUse(self.player, c, false, true) then w = w + 1 end
			if self:slashIsAvailable() and self:willUse(self.player, c, true) then h = h + 1 end
		end
		if c:isKindOf("Snatch") or c:isKindOf("SupplyShortage") and self:willUse(self.player, c, true) then h = h + 1 end
		if c:isNDTrick() and self:willUse(self.player, c) then t = t + 1 end
	end
	if t > 0 and self.player:hasEquipArea(4) and not self:keepWoodenOx() then 
		sgs.ai_use_priority.JueyanCard = 10
		self.jueyan = "4"
		use.card = card 
		return
	end
	if w > 0 and self.player:hasEquipArea(0) then 
		sgs.ai_use_priority.JueyanCard = sgs.ai_use_priority.Slash - 0.1 
		self.jueyan = "0"
		use.card = card 
		return
	end
	if h > 0 and (self.player:hasEquipArea(2) or self.player:hasEquipArea(3)) then 
		sgs.ai_use_priority.JueyanCard = sgs.ai_use_priority.Slash - 0.1 
		self.jueyan = "23"
		use.card = card 
		return
	end
	if self.player:hasEquipArea(1) and (not self.player:getArmor() or self:isWeak() or self.player:getHandcardNum() < 3) then 
		if self.player:isWounded() then sgs.ai_use_priority.JueyanCard = sgs.ai_use_priority.SilverLion - 0.1 else sgs.ai_use_priority.JueyanCard = 10 end
		self.jueyan = "1"
		use.card = card 
		return
	end
end

sgs.ai_use_priority.JueyanCard = 10

sgs.ai_skill_choice.jueyan = function(self, choices, data)
	local items = choices:split("+")
	if self.jueyan then
		return self.jueyan
	else
		return items[1]
	end
end

--怀柔
local huairou_skill = {}
huairou_skill.name = "huairou"
table.insert(sgs.ai_skills, huairou_skill)
huairou_skill.getTurnUseCard = function(self, inclusive)	--yun
	if self:needToThrowArmor() then return sgs.Card_Parse("@HuairouCard=" .. self.player:getArmor():getEffectiveId()) end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _,c in ipairs(cards) do
		if c:isKindOf("EquipCard") then
			local equip = c:getRealCard():toEquipCard()
			local equip_index = equip:location()
			if self.player:isProhibited(self.player, c) or not self.player:hasEquipArea(equip_index) then
				return sgs.Card_Parse("@HuairouCard=" .. c:getEffectiveId())
			end
			
			if self:willUse(self.player, c) then
				if c:isKindOf("Weapon") and self.player:getWeapon() then 
					return sgs.Card_Parse("@HuairouCard=" .. self.player:getWeapon():getEffectiveId())
				elseif c:isKindOf("Armor") and self.player:getArmor() then
					return sgs.Card_Parse("@HuairouCard=" .. self.player:getArmor():getEffectiveId())
				elseif c:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() then
					return sgs.Card_Parse("@HuairouCard=" .. self.player:getDefensiveHorse():getEffectiveId())
				elseif c:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
					return sgs.Card_Parse("@HuairouCard=" .. self.player:getOffensiveHorse())				
				end
			else
				return sgs.Card_Parse("@HuairouCard=" .. c:getEffectiveId())
			end
		end
	end
	return
end

sgs.ai_skill_use_func.HuairouCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.HuairouCard = 10
sgs.ai_use_value.HuairouCard = 10

--镇骨
sgs.ai_skill_playerchosen.zhengu = function(self, targets)
	local n = self.player:getHandcardNum()
	local f, e = n, n
	
	local dis, drw = 0, 0
	local fri, ene, eqf, eqe
	self:sort(self.friends_noself, "handcard")
	for _, who in ipairs(self.friends_noself) do
		if who:getHandcardNum() < f and not self:needKongcheng(who, true) and not hasManjuanEffect(who) then f = who:getHandcardNum() fri = who end
		if who:getHandcardNum() == n and not eqf and not hasManjuanEffect(who) and n > 1 then eqf = who end
	end
	
	drw = n - f
	if drw > 0 and n > 5 then 
		drw = 5 - f
	end
	
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, who in ipairs(self.enemies) do
		if who:getHandcardNum() > e and not (n==0 and self:needKongcheng(who, true)) then e = who:getHandcardNum() ene = who end
		if who:getHandcardNum() == n and n < 2 then eqe = who end
	end
	dis = e - n
	if drw > 0 and drw >= dis then return fri end
	if dis > 0 and dis >= drw then return ene end
	if drw > 0 and drw == dis then
		if n > 1 and fri then return fri end
		if n < 2 and ene then return ene end
	end
	if eqf then return eqf end
	if eqe then return eqe end
	return nil
end

sgs.ai_playerchosen_intention.zhengu = function(self, from, to)
	if to:getHandcardNum() < from:getHandcardNum() and self:canDraw(to, from) then sgs.updateIntention(from, to, -10) end
	if to:getHandcardNum() > from:getHandcardNum() and not self:needToThrowCard(to, "h") then sgs.updateIntention(from, to, 10) end
end

--征荣
sgs.ai_skill_invoke.zhengrong = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self:getOverflow(target) > 2 then return true end
		if self:needToThrowCard(target) then return true end
		if self:needKongcheng(target) and target:getHandcardNum() == 1 then return true end
		return false
	end
	if self:isEnemy(target) then
		if self:doNotDiscard(target) then return false end
		return true
	end
	return true
end

--鸿举
sgs.ai_skill_use["@@hongju"] = function(self, prompt)
    local pile = self.player:getPile("rong")
	local piles = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local max_num = math.min(pile:length(), #cards)
	for _, card_id in sgs.qlist(pile) do
		table.insert(piles, sgs.Sanguosha:getCard(card_id))
	end
	
	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	self:sortByCardNeed(cards)
	self:sortByCardNeed(piles)
	for i = 1 , max_num, 1 do
		if self:cardNeed(piles[#piles]) > self:cardNeed(cards[1]) then
			table.insert(exchange_to_handcard, piles[#piles])
			table.insert(exchange_to_pile, cards[1])
			table.removeOne(piles, piles[#piles])
			table.removeOne(cards, cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard == 0 then return "." end
	local exchange = {}

	for _, c in ipairs(exchange_to_handcard) do
		table.insert(exchange, c:getId())
	end

	for _, c in ipairs(exchange_to_pile) do
		table.insert(exchange, c:getId())
	end

	return "@HongjuCard=" .. table.concat(exchange, "+")
end

--清侧
local qingce_skill = {}
qingce_skill.name = "qingce"
table.insert(sgs.ai_skills, qingce_skill)
qingce_skill.getTurnUseCard = function(self)
	if self.player:getPile("rong"):length() < 1 then return end
	local piles = self.player:getPile("rong")
	return sgs.Card_Parse("@QingceCard=" .. piles:first())	
end

sgs.ai_skill_use_func.QingceCard = function(card, use, self)	
	local to = self:findPlayerToDiscard("ej", true, false, players, return_table)
	if not to then return end
	use.card = card			
	if use.to then
		use.to:append(to)
	end
end

sgs.ai_use_priority.QingceCard = 4.2

--OL征荣
sgs.ai_skill_playerchosen.olzhengrong = function(self, targets)
	local to = self:findPlayerToDiscard("he", true, false, targets)
	if to then return to end
	for _, to in sgs.qlist(targets) do
		if not self:isFriend(to) and not self:doNotDiscard(to) then return to end
	end
	return nil
end

--OL鸿举
sgs.ai_skill_use["@@olhongju"] = function(self, prompt)
    local pile = self.player:getPile("rong")
	local piles = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local max_num = math.min(pile:length(), #cards)
	for _, card_id in sgs.qlist(pile) do
		table.insert(piles, sgs.Sanguosha:getCard(card_id))
	end
	
	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	self:sortByCardNeed(cards)
	self:sortByCardNeed(piles)
	for i = 1 , max_num, 1 do
		if self:cardNeed(piles[#piles]) > self:cardNeed(cards[1]) then
			table.insert(exchange_to_handcard, piles[#piles])
			table.insert(exchange_to_pile, cards[1])
			table.removeOne(piles, piles[#piles])
			table.removeOne(cards, cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard == 0 then return "." end
	local exchange = {}

	for _, c in ipairs(exchange_to_handcard) do
		table.insert(exchange, c:getId())
	end

	for _, c in ipairs(exchange_to_pile) do
		table.insert(exchange, c:getId())
	end

	return "@OLHongjuCard=" .. table.concat(exchange, "+")
end

--OL清侧
local olqingce_skill = {}
olqingce_skill.name = "olqingce"
table.insert(sgs.ai_skills, olqingce_skill)
olqingce_skill.getTurnUseCard = function(self)
	if self.player:getPile("rong"):length() < 1 or not self.player:canDiscard(self.player, "h") then return end
	local hands = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(hands)
	if hands[1]:isKindOf("ExNihilo") then return end
	if self:isWeak() and hands[1]:isKindOf("Peach") then return end
	if self:isWeak() and hands[1]:isKindOf("Jink") and self:getCardsNum("Jink") < 2 then return end
	local piles = {}
	for _,id in sgs.qlist(self.player:getPile("rong")) do
		table.insert(piles, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(piles, true)
	local c = {}
	table.insert(c, hands[1]:getId())
	table.insert(c, piles[1]:getId())
	return sgs.Card_Parse("@OLQingceCard=" .. table.concat(c, "+"))	
end

sgs.ai_skill_use_func.OLQingceCard = function(card, use, self)	
	local to = self:findPlayerToDiscard("ej", true, false, players)
	if not to then return end
	use.card = card			
	if use.to then
		use.to:append(to)
	end
end

sgs.ai_use_priority.OLQingceCard = sgs.ai_use_priority.Dismantlement - 0.1

--手杀征荣
sgs.ai_skill_playerchosen.mobilezhengrong = function(self, targets)
	local to = self:findPlayerToDiscard("he", false, false, targets)
	if to then return to end
	for _, to in sgs.qlist(targets) do
		if not self:isFriend(to) and not self:doNotDiscard(to) then return to end
	end
	for _, to in sgs.qlist(targets) do
		if not self:isFriend(to) then return to end
	end
	return targets:at(math.random(0, targets:length() - 1))
end

--手杀鸿举
sgs.ai_skill_use["@@mobilehongju"] = function(self, prompt)
    local pile = self.player:getPile("rong")
	local piles = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local max_num = math.min(pile:length(), #cards)
	for _, card_id in sgs.qlist(pile) do
		table.insert(piles, sgs.Sanguosha:getCard(card_id))
	end
	
	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	self:sortByCardNeed(cards)
	self:sortByCardNeed(piles)
	for i = 1 , max_num, 1 do
		if self:cardNeed(piles[#piles]) > self:cardNeed(cards[1]) then
			table.insert(exchange_to_handcard, piles[#piles])
			table.insert(exchange_to_pile, cards[1])
			table.removeOne(piles, piles[#piles])
			table.removeOne(cards, cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard == 0 then return "." end
	local exchange = {}

	for _, c in ipairs(exchange_to_handcard) do
		table.insert(exchange, c:getId())
	end

	for _, c in ipairs(exchange_to_pile) do
		table.insert(exchange, c:getId())
	end

	return "@MobileHongjuCard=" .. table.concat(exchange, "+")
end

--伪帝
sgs.ai_skill_askforyiji.leiweidi = function(self, card_ids)
	local available_friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and not self:isLihunTarget(friend) and friend:getKingdom() == "qun" then table.insert(available_friends, friend) end
	end

	local toGive, allcards = {}, {}
	local keep
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if not keep and (isCard("Jink", card, self.player) or isCard("Analeptic", card, self.player)) then
			keep = true
		else
			table.insert(toGive, card)
		end
		table.insert(allcards, card)
	end

	local cards = #toGive > 0 and toGive or allcards
	self:sortByKeepValue(cards, true)
	local id = cards[1]:getId()

	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend and table.contains(available_friends, friend) then return friend, card:getId() end

	if #available_friends > 0 then
		self:sort(available_friends, "handcard")
		for _, afriend in ipairs(available_friends) do
			if not self:needKongcheng(afriend, true) then
				return afriend, id
			end
		end
		self:sort(available_friends, "defense")
		return available_friends[1], id
	end
	return nil, -1
end

--从谏
sgs.ai_skill_askforyiji.congjian = function(self, card_ids)
	local equips = {}
	for _, card_id in ipairs(card_ids) do
		local equip = sgs.Sanguosha:getCard(card_id)
		if not equip:isKindOf("EquipCard") then continue end
		if equip:objectName() == "wooden_ox" and not self.player:getPile("wooden_ox"):isEmpty() then continue end
		table.insert(equips, card_id)
	end
	if #equips > 0 then
		local to, id = sgs.ai_skill_askforyiji.nosyiji(self, equips)
		if to and to:objectName() ~= self.player:objectName() and id > 0 then
			return to, id
		end
	end
	local to, id = sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
	if to and to:objectName() ~= self.player:objectName() and id > 0 then
		return to, id
	end
	return nil, -1
end

--雄乱
local xiongluan_skill = {}
xiongluan_skill.name = "xiongluan"
table.insert(sgs.ai_skills, xiongluan_skill)
xiongluan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@xiongluanMark") > 0 and (self.player:hasJudgeArea() or self.player:hasEquipArea()) then
		return sgs.Card_Parse("@XiongluanCard=.")
	end
end

sgs.ai_skill_use_func.XiongluanCard = function(card, use, self)
	local target = nil
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sort(self.enemies, "hp")
	local slashes = self:getCards("Slash")
	if #slashes < 1 then return end
	for _, enemy in ipairs(self.enemies) do
		local n = 0
		for _, slash in ipairs(slashes) do
			if self.player:canSlash(enemy, slash, false) and sgs.isGoodTarget(enemy, self.enemies, self, true) 
				and self:slashIsEffective(slash, enemy, self.player) and not (self:hasEightDiagramEffect(enemy) and not IgnoreArmor(self.player, enemy)) then
					n = n + 1
					if n >= enemy:getHp() then target = enemy break end
			end
		end
		if target then break end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority.XiongluanCard = sgs.ai_use_priority.Slash + 0.1
sgs.ai_use_value.XiongluanCard = 3


