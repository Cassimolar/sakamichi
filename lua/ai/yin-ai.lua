--拒战
sgs.ai_skill_invoke.juzhan = function(self, data)
	local target = data:toPlayer()
	if self.player:getChangeSkillState("juzhan") == 2 then
		if self:isFriend(target) then return false end
		if self:isEnemy(target) and self:doNotDiscard(target) then return false end
	end
	return true
end

--飞军
local function has_value(self, who)
	local equips = sgs.QList2Table(who:getEquips())
	for _,equip in ipairs(equips) do
		if not self:isValuableCard(equip) then return false end
	end
	return true
end

local function can_find_feijun_target(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	self.feijun_id = cards[1]:getEffectiveId()
	self.feijun_target = nil
	self.feijun = "givehand"
	
	local hand, equip = 0, 0
	if self.room:getCardPlace(self.feijun_id) == sgs.Player_PlaceHand then
		hand = hand + 1
	else
		equip = equip + 1
	end
	
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > self.player:getEquips():length() - equip and self:getDangerousCard(enemy) and not self:needToThrowCard(enemy, "e")
		and has_value(self, enemy) and enemy:getMark("feijun_hasused_" .. self.player:objectName()) < 1 then
			self.feijun_target = enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > self.player:getEquips():length()  - equip and self:getValuableCard(enemy) and not self:needToThrowCard(enemy, "e")
			and has_value(self, enemy) and enemy:getMark("feijun_hasused_" .. self.player:objectName()) < 1 then
				self.feijun = "discardequip"
				self.feijun_target = enemy
		end
	end
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() > self.player:getEquips():length() - equip and self:needToThrowCard(friend, "e") and
			friend:getMark("feijun_hasused_" .. self.player:objectName()) < 1 then
				self.feijun = "discardequip"
				self.feijun_target = friend
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > self.player:getHandcardNum() - hand and not self:needToThrowCard(enemy, "h") and
			not (self:needKongcheng(enemy) and enemy:getHandcardNum() == 1) and enemy:getMark("feijun_hasused_" .. self.player:objectName()) < 1 then
				self.feijun_target = enemy
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() > self.player:getHandcardNum() - hand and (self:needToThrowCard(friend, "h") 
			or (self:needKongcheng(friend) and friend:getHandcardNum() == 1) or self:getOverflow(friend) > 2) and friend:getMark("feijun_hasused_" .. self.player:objectName()) < 1 then
				self.feijun_target = friend
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > self.player:getEquips():length() - equip and (self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and
			not self:needToThrowCard(enemy, "e") then
			self.feijun = "discardequip"
			self.feijun_target = enemy
		end
	end	
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() > self.player:getEquips():length() - equip and self:needToThrowCard(friend, "e") then
			self.feijun = "discardequip"
			self.feijun_target = friend
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > self.player:getHandcardNum() - hand and not self:needToThrowCard(enemy, "h") and
			not (self:needKongcheng(enemy) and enemy:getHandcardNum() == 1) then
			self.feijun_target = enemy
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() > self.player:getHandcardNum() - hand and (self:needToThrowCard(friend, "h") 
			or (self:needKongcheng(friend) and friend:getHandcardNum() == 1)) then
			self.feijun_target = friend
		end
	end
	if self.feijun_target then return true end
	return false
end

local feijun_skill = {}
feijun_skill.name = "feijun"
table.insert(sgs.ai_skills, feijun_skill)
feijun_skill.getTurnUseCard = function(self)
	if not self.player:canDiscard(self.player, "he") or self.player:hasUsed("FeijunCard") then return end
	if not can_find_feijun_target(self) then return end
	return sgs.Card_Parse("@FeijunCard=.")
end

sgs.ai_skill_use_func.FeijunCard = function(card, use, self)
	use.card = sgs.Card_Parse("@FeijunCard=" .. self.feijun_id)
end

sgs.ai_skill_choice.feijun = function(self, choices)
	return self.feijun
end

sgs.ai_skill_playerchosen.feijun = function(self, targets)
	return self.feijun_target
end

sgs.ai_skill_discard.feijun = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

sgs.ai_skill_discard.feijun_discardequip = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("e"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	table.insert(to_discard,cards[1]:getEffectiveId())
	return to_discard
end

sgs.ai_use_priority.FeijunCard = 7

--遗礼
sgs.ai_skill_playerchosen.weili = function(self, targets)
	if self.player:getMark("&orange") < 2 and self:getCardsNum("Peach") <= self.player:getLostHp() then return nil end
	for _, who in ipairs(self.friends_noself) do
		if who:getMark("&orange") < 1 and not self:hasSkills("shelie", who) then
			if sgs.turncount > 2 and #self.enemies < 2 then return who end
			if not self:hasSkills("nostuxi|qiaobian", who) then return who end
		end
	end
	return nil
end

sgs.ai_skill_choice.weili = function(self, choices)
	if self:getCardsNum("Peach") > self.player:getLostHp() or (not self:isWeak() and self.player:hasSkill("zhaxiang")) then return "losehp" end
	return "losemark"
end

sgs.ai_playerchosen_intention.weili = -80

--整论
sgs.ai_skill_invoke.zhenglun = function(self)
	if self.player:isSkipped(sgs.Player_Play) then return true end
	for _, enemy in ipairs(self.enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		if self.player:canSlash(enemy) and self:slashIsEffective(slash, enemy, self.player) 
			and sgs.isGoodTarget(enemy, self.enemies, self, true) and self:getCardsNum("Slash") < 1 then
			return false
		end
	end
	if self.player:getHandcardNum() > 1 or self.player:getHandcardNum() + 1 > self.player:getHp() then return true end
	return false
end

--溃诛
sgs.ai_skill_use["@@kuizhu"] = function(self, prompt)
	local n = self.player:getMark("kuizhu-Clear")
	local dmg
	local dmg2, dmg3, dmg4, draw = {},{},{},{}
	self:sort(self.enemies, "hp")
	self.kuizhu = nil
	
	if #self.enemies > 0 then
		for _,enemy1 in ipairs(self.enemies) do
			if enemy1:getHp() > n then break end
			if not self:canDamage(enemy1, self.player) then continue end
			if not dmg and enemy1:getHp() == n then dmg = enemy1 break end
			if enemy1:getHp() < n and #self.enemies > 1 then 
				for __,enemy2 in ipairs(self.enemies) do
					if enemy1:objectName() == enemy2:objectName() then continue end
					if not self:canDamage(enemy2, self.player) then continue end
					if enemy1:getHp() + enemy2:getHp() > n then break
					elseif enemy1:getHp() + enemy2:getHp() == n and #dmg2 < 1 then
						table.insert(dmg2, enemy1:objectName())
						table.insert(dmg2, enemy2:objectName())
					elseif #self.enemies > 2 then
						for __,enemy3 in ipairs(self.enemies) do
							if enemy1:objectName() == enemy3:objectName() or enemy2:objectName() == enemy3:objectName() then continue end
							if not self:canDamage(enemy3, self.player) then continue end
							if enemy1:getHp() + enemy2:getHp() + enemy3:getHp() > n then break
							elseif enemy1:getHp() + enemy2:getHp() + enemy3:getHp() == n and #dmg3 < 1 then
								table.insert(dmg3, enemy1:objectName())
								table.insert(dmg3, enemy2:objectName())
								table.insert(dmg3, enemy3:objectName())
							elseif #self.enemies > 3 then
								for __,enemy4 in ipairs(self.enemies) do
									if enemy1:objectName() == enemy4:objectName() or enemy2:objectName() == enemy4:objectName() or enemy3:objectName() == enemy4:objectName() then continue end
									if not self:canDamage(enemy4, self.player) then break end
									if enemy1:getHp() + enemy2:getHp() + enemy3:getHp() + enemy4:getHp() > n then break
									elseif enemy1:getHp() + enemy2:getHp() + enemy3:getHp() + enemy4:getHp() == n and #dmg4 < 1 then
										table.insert(dmg4, enemy1:objectName())
										table.insert(dmg4, enemy2:objectName())
										table.insert(dmg4, enemy3:objectName())
										table.insert(dmg4, enemy4:objectName())
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	local tos = self:findPlayerToDraw(true, 1, true)
	for _, friend in ipairs(tos) do
		if self:canDraw(friend) then
			table.insert(draw, friend:objectName())
			if #draw == n then break end
		end
	end
	
	if self:isWeak() and self.player:getHp() < 2 then
		if #draw > 2 then
			self.kuizhu = "draw"
			return "@KuizhuCard=.->" .. table.concat(draw, "+")
		end
		if dmg then
			self.kuizhu = "damage"
			return "@KuizhuCard=.->" .. dmg:objectName()
		end
		if #draw > 0 then
			self.kuizhu = "draw"
			return "@KuizhuCard=.->" .. table.concat(draw, "+")
		end
		return "."
	end
	
	if #dmg4 > 0 then
		self.kuizhu = "damage"
		return "@KuizhuCard=.->" .. table.concat(dmg4, "+")
	end
	if #dmg3 > 0 then
		self.kuizhu = "damage"
		return "@KuizhuCard=.->" .. table.concat(dmg3, "+")
	end
	if #dmg2 > 0 then
		if #draw > 2 then
			self.kuizhu = "draw"
			return "@KuizhuCard=.->" .. table.concat(draw, "+")
		end
		self.kuizhu = "damage"
		return "@KuizhuCard=.->" .. table.concat(dmg2, "+")
	end
	if dmg then
		if #draw > 2 then
			self.kuizhu = "draw"
			return "@KuizhuCard=.->" .. table.concat(draw, "+")
		end
		self.kuizhu = "damage"
		return "@KuizhuCard=.->" .. dmg:objectName()
	end
	if #draw > 0 then
		self.kuizhu = "draw"
		if #draw == 1 and #draw < n then self:noChoice(self.room:getOtherPlayers(self.player)) end
		return "@KuizhuCard=.->" .. table.concat(draw, "+")
	end
	return "."
end

sgs.ai_skill_choice.kuizhu = function(self, choices)
	return self.kuizhu
end

--掣政
sgs.ai_skill_playerchosen.chezheng = function(self, targets)
	local to = self:findPlayerToDiscard("he", false, false, targets, return_table)
	if to then return to end
	for _, to in sgs.qlist(targets) do
		if not self:isFriend(to) and not self:doNotDiscard(to) then return to end
	end
	return targets[1]
end

--立军
sgs.ai_skill_playerchosen.lijun = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
		if self:isFriend(p) and not self:needKongcheng(p, true) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.lijun = function(self, data)
	local target = data:toPlayer()
	if not target then return false end
	return self:isFriend(target) and not self:needKongcheng(friend, true)
end

--奇制
sgs.ai_skill_playerchosen.qizhi = function(self, targets)
	self:updatePlayers()
	local targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and hasManjuanEffect(target) and not target:isNude() then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and not hasManjuanEffect(target) and self:needToThrowCard(target, "he", false, false, true) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (self:getDangerousCard(target) or self:keepWoodenOx(target)) then return target end
		if self:isEnemy(target) and self:getValuableCard(target) and not self:doNotDiscard(target, "e") 
		and not target:hasSkills(sgs.notActive_cardneed_skill) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if target:objectName() == self.player:objectName() then 
			local cards = sgs.QList2Table(self.player:getCards("he"))
			for _,c in ipairs(cards) do
				if not self:keepCard(c, self.player) then return target end
			end	
		end
	end
	return nil
end

--进趋
sgs.ai_skill_invoke.jinqu = function(self)
	if self.player:getMark("&qizhi-Clear") >= self.player:getHandcardNum() then return true end
	return false
end

--荐降
sgs.ai_skill_playerchosen.jianxiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
		if self:canDraw(p) and self:isFriend(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:needKongcheng(p, true) and not self:isFriend(p) then return p end
	end
	self:noChoice(targets)
	return nil
end

--审时
local shenshi_skill = {}
shenshi_skill.name = "shenshi"
table.insert(sgs.ai_skills, shenshi_skill)
shenshi_skill.getTurnUseCard = function(self)
	if self.player:isNude() or self.player:hasUsed("ShenshiCard") or self.player:getChangeSkillState("shenshi") ~= 1 then return end
	return sgs.Card_Parse("@ShenshiCard=.")
end

sgs.ai_skill_use_func.ShenshiCard = function(card, use, self)
	local max_card_num = self.room:getOtherPlayers(self.player):first():getHandcardNum()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		max_card_num = math.max(max_card_num, p:getHandcardNum())
	end
	local target
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() == max_card_num and self:canDamage(enemy) then
			target = enemy
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() == max_card_num and self:canDamage(friend) then
				target = friend
				break
			end
		end
	end
	if not target then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	local card
	if self:needToThrowArmor() then card = self.player:getArmor() end
	if not card then
		if self:isFriend(target) then
			for _,c in ipairs(cards) do
				if not self:keepCard(c, self.player, true) then
					card = c
					break
				end
			end
		else
			for _,c in ipairs(cards) do
				if c:isKindOf("Disaster") or c:isKindOf("GodSalvation") or c:isKindOf("AmazingGrace") or c:isKindOf("FireAttack") or c:isKindOf("Slash") or c:isKindOf("Jink") then
					card = c
					break
				end
			end	
		end
	end
	if not card then return end
	use.card = sgs.Card_Parse("@ShenshiCard=" .. card:getEffectiveId())
	if use.to then
		use.to:append(target)
	end
end

sgs.ai_use_priority.ShenshiCard = 3
sgs.ai_use_value.ShenshiCard = 3

sgs.ai_skill_invoke.shenshi = function(self, data)
	if self:needToThrowArmor() then return true end
	local from = data:toPlayer()
	self.shenshi_from = from
	if self:isFriend(from) then
		return true
	end
	if self:isEnemy(from) then
		if self:getCardsNum("Jink") > 0 or self:getCardsNum("Nullification") > 0 then
			return true
		end
		if self:getCardsNum("Slash") > 0 and not (self:hasCrossbowEffect(from) or (from:inMyAttackRange(self.player) and from:canSlashWithoutCrossbow())) then
			return true
		end
	end
	return false
end

sgs.ai_skill_discard.shenshi = function(self, discard_num, min_num, optional, include_equip)
	local dis = {}
	if self:needToThrowArmor() then
		table.insert(dis, self.player:getArmor():getEffectiveId())
		return dis
	end
	if self:isEnemy(self.shenshi_from) then
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		for _,c in ipairs(handcards) do
			if c:isKindOf("Slash") and not (self:hasCrossbowEffect(self.shenshi_from) or (self.shenshi_from:inMyAttackRange(self.player) and self.shenshi_from:canSlashWithoutCrossbow())) then
				table.insert(dis, c:getEffectiveId())
				return dis
			end
			if c:isKindOf("Jink") or c:isKindOf("Nullification") then
				table.insert(dis, c:getEffectiveId())
				return dis
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	table.insert(dis, cards[1]:getEffectiveId())
	return dis
end

--成略
local chenglve_skill = {}
chenglve_skill.name = "chenglve"
table.insert(sgs.ai_skills, chenglve_skill)
chenglve_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("ChenglveCard") then
		return sgs.Card_Parse("@ChenglveCard=.")
	end
end

sgs.ai_skill_use_func.ChenglveCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.ChenglveCard = 0
sgs.ai_use_value.ChenglveCard = 7

sgs.ai_skill_discard.chenglve = function(self, discard_num, min_num, optional, include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self:getCardsNum("Slash") > 0 then
		self:sortByUseValue(handcards, true)
	else
		self:sortByKeepValue(handcards)
	end
	local to_discard = {}
	for _,c in ipairs(handcards) do
		if #to_discard < discard_num then
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	return to_discard
end

--恃才
sgs.ai_skill_invoke.yinshicai = function(self, data)
	return true
end

--明任
sgs.ai_skill_discard.mingren = function(self, discard_num, min_num, optional, include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(handcards)
	if not optional then
		local red_cards = {}
		local black_cards = {}
		for _,c in ipairs(handcards) do
			if c:isRed() then
				table.insert(red_cards, c:getEffectiveId())
			else
				table.insert(black_cards, c:getEffectiveId())
			end
		end
		if #red_cards > #black_cards then
			return red_cards[1]
		elseif #black_cards > #red_cards then
			return black_cards[1]
		elseif self.player:getPile("mrren"):isEmpty() then
			for _,c in ipairs(handcards) do
				return c:getEffectiveId()
			end
		end
	else
		local ren = sgs.Sanguosha:getCard(self.player:getPile("mrren"):first())
		for _,c in ipairs(handcards) do
			if self:getCardsNum("Nullification") > 0 and c:isKindOf("TrickCard") then 
				if ren:isKindOf("TrickCard") then 
					if not c:isKindOf("Nullification") and self:cardNeed(ren) > self:cardNeed(c) then return c:getEffectiveId() end
				else
					if not c:isKindOf("Nullification") or self:getCardsNum("Nullification") > 1 then return c:getEffectiveId() end
				end
			end
			if c:isKindOf("BasicCard") then 
				if ren:isKindOf("BasicCard") then 
					if self:cardNeed(ren) > self:cardNeed(c) then return c:getEffectiveId() end
				else
					if c:isKindOf("Slash") then return c:getEffectiveId() end
					if c:isKindOf("Jink") and self:getCardsNum("Jink") > 1 then return c:getEffectiveId() end
					if c:isKindOf("Analeptic") and self:getCardsNum("Analeptic") > 1 then return c:getEffectiveId() end
					if c:isKindOf("Peach") and self:getCardsNum("Peach") > 1 then return c:getEffectiveId() end
				end
			end			
		end	
		if self:cardNeed(ren) > self:cardNeed(handcards[1]) then return handcards[1]:getEffectiveId() end
		return {}
	end
	return {}
end

--贞良
local zhenliang_skill = {}
zhenliang_skill.name = "zhenliang"
table.insert(sgs.ai_skills, zhenliang_skill)
zhenliang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:canDiscard(self.player, "he") and not self.player:hasUsed("ZhenliangCard") and self.player:getChangeSkillState("zhenliang") <= 1 and
		not self.player:getPile("mrren"):isEmpty() then
		return sgs.Card_Parse("@ZhenliangCard=.")
	end
end

sgs.ai_skill_use_func.ZhenliangCard = function(card, use, self)
	self:sort(self.enemies, "hp")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	local target = nil
	local use_card_num = 0
	local use_card = {}
	for _, enemy in ipairs(self.enemies) do
		use_card_num = math.max(1, math.abs(enemy:getHp() - self.player:getHp()))
		if use_card_num > 2 then continue end
		use_card = {}
		if self.player:inMyAttackRange(enemy) and self:canDamage(enemy, self.player) then
			for _,c in ipairs(cards) do
				if c:sameColorWith(sgs.Sanguosha:getCard(self.player:getPile("mrren"):first())) and not c:isKindOf("Peach") then
					table.insert(use_card, c:getEffectiveId())
					if #use_card == use_card_num then target = enemy break end
				end
			end
			if target then break end
		end
	end
	if #use_card == 0 or target == nil or #use_card < use_card_num then return end
	use.card = sgs.Card_Parse("@ZhenliangCard=" .. table.concat(use_card, "+"))
	if use.to then
		use.to:append(target)
	end
end

sgs.ai_use_priority.ZhenliangCard = sgs.ai_use_priority.Snatch - 0.1
sgs.ai_use_value.ZhenliangCard = 7

sgs.ai_skill_playerchosen.zhenliang = function(self, targets)
	return self:findPlayerToDraw(true, 1)
end

--OL明任
sgs.ai_skill_discard.olmingren = function(self, discard_num, min_num, optional, include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(handcards)
	if not optional then
		local red_cards = {}
		local black_cards = {}
		for _,c in ipairs(handcards) do
			if c:isRed() then
				table.insert(red_cards, c:getEffectiveId())
			else
				table.insert(black_cards, c:getEffectiveId())
			end
		end
		if #red_cards > #black_cards then
			return red_cards[1]
		elseif #black_cards > #red_cards then
			return black_cards[1]
		elseif self.player:getPile("mrren"):isEmpty() then
			for _,c in ipairs(handcards) do
				return c:getEffectiveId()
			end
		end
	else
		local ren = sgs.Sanguosha:getCard(self.player:getPile("mrren"):first())
		for _,c in ipairs(handcards) do
			if self:cardNeed(ren) > self:cardNeed(c) then
				return c:getEffectiveId()
			end
		end
	end
	return {}
end

--OL贞良
local olzhenliang_skill = {}
olzhenliang_skill.name = "olzhenliang"
table.insert(sgs.ai_skills, olzhenliang_skill)
olzhenliang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:canDiscard(self.player, "he") and not self.player:hasUsed("OLZhenliangCard") and self.player:getChangeSkillState("olzhenliang") <= 1 and
		not self.player:getPile("mrren"):isEmpty() then
		return sgs.Card_Parse("@OLZhenliangCard=.")
	end
end

sgs.ai_skill_use_func.OLZhenliangCard = function(card, use, self)
	if #self.enemies == 0 then return end
	self:sort(self.enemies, "hp")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	local color_cards = {}
	local card = sgs.Sanguosha:getCard(self.player:getPile("mrren"):first())
	for _,c in ipairs(cards) do
		if c:sameColorWith(card) then 
			table.insert(color_cards, c)
		end
	end
	if #color_cards == 0 then return end
	use.card = sgs.Card_Parse("@OLZhenliangCard=" .. color_cards[1]:getEffectiveId())
	if use.to then
		use.to:append(self.enemies[1])
	end
end

sgs.ai_use_priority.OLZhenliangCard = sgs.ai_use_priority.Snatch - 0.1
sgs.ai_use_value.OLZhenliangCard = 7

sgs.ai_skill_playerchosen.olzhenliang = function(self, targets)
	return sgs.ai_skill_playerchosen.zhenliang(self, targets)
end