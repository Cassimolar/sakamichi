--矫诏
local jiaozhao_skill = {}
jiaozhao_skill.name = "jiaozhao"
table.insert(sgs.ai_skills, jiaozhao_skill)
jiaozhao_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isKongcheng() and not self.player:hasUsed("JiaozhaoCard") then
		self.jiaozhao_target = nil
		local level = self.player:property("jiaozhao_level"):toInt()
		if level > 1 then
			self.jiaozhao_target = self.player
		else
			local distance = self.player:distanceTo(self.player:getNextAlive())
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self.player:distanceTo(p) < distance then
					distance = self.player:distanceTo(p)
				end
			end
			for _,p in ipairs(self.friends_noself) do
				if self.player:distanceTo(p) == distance then
					self.jiaozhao_target = p
					break
				end
			end
		end
		if not self.jiaozhao_target then return end
		return sgs.Card_Parse("@JiaozhaoCard=.")
	end
	
	local id = self.player:getMark("jiaozhao_id-Clear") - 1
	local showid = self.player:getMark("jiaozhao_showid-Clear") - 1
	if id >= 0 and showid >= 0 and (self.player:hasCard(showid) or self.player:getHandPile():contains(showid)) then
		local name = sgs.Sanguosha:getEngineCard(id):objectName()
		local card = sgs.Sanguosha:getCard(showid)
        local use_card = sgs.Sanguosha:cloneCard(name, card:getSuit(), card:getNumber())
        if use_card then
            use_card:setCanRecast(false)
            use_card:addSubcard(showid)
            use_card:setSkillName("jiaozhao")
			use_card:deleteLater()
			if self.player:canUse(use_card) then
				local card_str = (name .. ":jiaozhao[%s:%s]=%d"):format(use_card:getSuitString(), card:getNumber(), showid)
				local skillcard = sgs.Card_Parse(card_str)
				assert(skillcard)
				return skillcard
			end
		end
	end
end

sgs.ai_skill_use_func.JiaozhaoCard = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	use.card = sgs.Card_Parse("@JiaozhaoCard=" .. cards[1]:getEffectiveId())
end

sgs.ai_view_as.jiaozhao = function(card, player, card_place)
	local id = player:getMark("jiaozhao_id-Clear") - 1
	local showid = player:getMark("jiaozhao_showid-Clear") - 1
	if id >= 0 and showid >= 0 and card:getEffectiveId() == showid then
		local c = sgs.Sanguosha:getEngineCard(id)
		local name = c:objectName()
		return (name .. ":jiaozhao[%s:%s]=%d"):format(card:getSuitString(), card:getNumber(), showid)
	end
end

sgs.ai_skill_askforag.jiaozhao = function(self, ids)
	local source = self.player:getTag("jiaozhaoAI"):toPlayer()
	self.player:removeTag("jiaozhaoAI")
	if not source then return ids[1] end
	
	local card_ids = {}
	for _,id in ipairs(ids) do
		if (source:getState() == "robot" or source:getState() == "trust") and sgs.Sanguosha:getEngineCard(id):objectName() == "iron_chain" then continue end --ai会重铸铁索，故而移去
		table.insert(card_ids, id)
	end
	if #card_ids == 0 then return ids[1] end
	
	local showid = source:getMark("jiaozhao_showid-Clear") - 1
	if showid < 0 then return card_ids[1] end
	
	local c = sgs.Sanguosha:getCard(showid)
	local can_use, can_not_use = {}, {}
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getEngineCard(id):objectName(), c:getSuit(), c:getNumber())
		card:setSkillName("jiaozhao")
		card:setCanRecast(false)
        card:addSubcard(showid)
		card:deleteLater()
		if source:canUse(card) then
			table.insert(can_use, card)
		else
			table.insert(can_not_use, id)
		end
	end
	if #can_use == 0 then return card_ids[1] end
	self:sortByUseValue(can_use)
	
	if self:isEnemy(source) then
		return can_not_use[1]
	end
	
	for _, id in ipairs(card_ids) do
		if sgs.Sanguosha:getEngineCard(id):objectName() == can_use[1]:objectName() then
			return id
		end
	end
end

sgs.ai_skill_playerchosen.jiaozhao = function(self, targets)
	local data = sgs.QVariant()
	data:setValue(self.player)
	if self.jiaozhao_target then
		self.jiaozhao_target:setTag("jiaozhaoAI", data)
		return self.jiaozhao_target
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			p:setTag("jiaozhaoAI", data)
			return p
		end
	end
	targets:first():setTag("jiaozhaoAI", data)
	return targets:first()
end

sgs.ai_use_priority.JiaozhaoCard = 10

--殚心
sgs.ai_skill_invoke.danxin = function(self, data)
	local level = self.player:property("jiaozhao_level"):toInt()
	if level > 1 then
		if not self:canDraw(self.player) then return false end
	end
	return true
end

sgs.ai_skill_choice.danxin = function(self, choices)
	if not self.player:hasSkill("jiaozhao") then return "draw" end
	local items = choices:split("+")
	if self:isWeak() and self.player:getHp() < 2 and not self:canDraw(self.player) then return "up" end
	if self:isWeak() and self.player:getHp() < 2 then return "draw" end
	if table.contains(items, "up") then return "up" end
	return "draw"
end

sgs.ai_need_damaged.danxin = function(self, attacker, player)
	if not player:hasSkill("danxin") or not player:hasSkill("jiaozhao") then return false end
	if self:isWeak() then return false end
	return player:property("jiaozhao_level"):toInt() <= 1
end

--瑰藻
sgs.ai_skill_invoke.guizao = function(self, data)
	if self.player:getLostHp() <= 0 and not self:canDraw(self.player) then return false end
	return true
end

sgs.ai_skill_choice.guizao = function(self, choices)
	local items = choices:split("+")
	if table.contains(items, "recover") and self.player:getLostHp() > 0 and self:isWeak() then 
		return "recover"
	end
	if table.contains(items, "draw") and self:needBear() then 
		return "draw"
	end
	if table.contains(items, "recover") and self.player:getLostHp() > 0 then 
		return "recover"
	end
	return "draw"
end

--讥谀
local jiyu_skill = {}
jiyu_skill.name = "jiyu"
table.insert(sgs.ai_skills, jiyu_skill)
jiyu_skill.getTurnUseCard = function(self)
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isAvailable(self.player) then
			return sgs.Card_Parse("@JiyuCard=.")
		end
	end
end

sgs.ai_skill_use_func.JiyuCard = function(card, use, self)
	self:sort(self.friends, "handcard")
	self.friends = sgs.reverse(self.friends)
	self:sort(self.enemies, "handcard")
	if self.player:isKongcheng() then return end
	
	local data = sgs.QVariant()
	data:setValue(self.player)
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("jiyu-PlayClear") == 0 and not enemy:isKongcheng() and not self:needToThrowCard(enemy, "h") 
			and not (self:needKongcheng(enemy) and enemy:getHandcardNum() == 1)
			and not (self:needToLoseHp(enemy, self.player) and not (self:isWeak(enemy) or enemy:getHp() == 1)) then
				use.card = sgs.Card_Parse("@JiyuCard=.")
				if use.to then use.to:append(enemy) enemy:setTag("jiyuAI", data) end return	
		end	
	end
	
	for _, friend in ipairs(self.friends) do
		if friend:isKongcheng() then continue end
		if friend:getMark("jiyu-PlayClear") == 0 then
			local handcards = sgs.QList2Table(friend:getHandcards())
			local hasspade = false
			local hasother = false
			for _, c in ipairs(handcards) do
				local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), friend:objectName())
				if c:hasFlag("visible") or c:hasFlag(flag) then
					if c:getSuit() == sgs.Card_Spade then
						hasspade = true
					else
						hasother = true
					end
					if hasspade and hasother then break end
				end
			end
			if not self.player:faceUp() and hasspade and self:needToLoseHp(friend) then
				
			elseif hasother then
				if (self:needKongcheng(friend) and #handcards == 1) or self:needToThrowCard(friend, "h") then
					
				else
					continue 
				end
			else
				continue 
			end
			use.card = sgs.Card_Parse("@JiyuCard=.")
			if use.to then use.to:append(friend) friend:setTag("jiyuAI", data) return end	
		end
	end

	if self.player:getHp() >= 2 and not self.player:faceUp() and self.player:getMark("jiyu-PlayClear") == 0 then
		local handcards = sgs.QList2Table(self.player:getHandcards())
		local hasspade = false
		for _, c in ipairs(handcards) do
			if c:getSuit() == sgs.Card_Spade then
				hasspade = true
				break
			end
		end
		if hasspade then 
			use.card = sgs.Card_Parse("@JiyuCard=.")
			if use.to then use.to:append(self.player) self.player:setTag("jiyuAI", data) return end
		end
	end
end

sgs.ai_skill_discard.jiyu = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	
	local target = self.player:getTag("jiyuAI"):toPlayer()
	self.player:removeTag("jiyuAI")
	if not target then return cards[1]:getEffectiveId() end
	
	if self:isFriend(target) then
		for _, card in ipairs(cards) do
			if not target:faceUp() and self.player:getHp() > 1 then
				if card:getSuit() == sgs.Card_Spade then
					return card:getEffectiveId()
				end
			end
		end
		
		for _, card in ipairs(cards) do
			if target:isCardLimited(card, sgs.Card_MethodUse) then
				return card:getEffectiveId()
			end
		end
	else
		for _, card in ipairs(cards) do
			if not target:faceUp() then
				if card:getSuit() == sgs.Card_Spade then continue end
				if target:isCardLimited(card, sgs.Card_MethodUse) then continue end
				return card:getEffectiveId()
			else
				if self.player:isCardLimited(card, sgs.Card_MethodUse) then continue end
				return card:getEffectiveId()
			end
		end
	end
	
	return cards[1]:getEffectiveId()
end

sgs.ai_use_value.JiyuCard = 1
sgs.ai_use_priority.JiyuCard = 2

sgs.ai_card_intention.jiyu = function(self,card, from, tos)
	if self:needToThrowCard(tos[1], "h", true) or not from:faceUp() then return end
	sgs.updateIntention(from, tos[1], 50)
end

--督粮
local duliang_skill = {}
duliang_skill.name = "duliang"
table.insert(sgs.ai_skills, duliang_skill)
duliang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("DuliangCard") then return end
	return sgs.Card_Parse("@DuliangCard=.")
end

sgs.ai_skill_use_func.DuliangCard = function(card, use, self)
	self:updatePlayers()

	local friends, enemies, others = {}, {}, {}
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do		
		if not player:isKongcheng() and self:isFriend(player) then
			table.insert(friends, player)
		elseif not player:isKongcheng() and self:isEnemy(player) and not self:doNotDiscard(player, "h") then
			table.insert(enemies, player)
		elseif not player:isKongcheng() then
			table.insert(others, player)
		end
	end
	
	if #friends == 0 and #enemies == 0 and #others == 0 then return end
	local target
	self:sort(friends, "handcard")
	friends = sgs.reverse(friends)
	
	for _, friend in ipairs(friends) do
		if self:needToThrowCard(friend, "h") or friend:hasSkill("tuxi") then
			target = friend
			break
		end
	end
	
	if not target then
		self:sort(enemies, "defense")
		for _, enemy in ipairs(enemies) do
			if hasManjuanEffect(enemy) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkills(sgs.dont_kongcheng_skill) then
				target = enemy
				break
			end
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if enemy:hasSkills(sgs.notActive_cardneed_skill) or self:isWeak(enemy) then
			target = enemy
			break
		end
	end
	
	if not target then
		for _, enemy in ipairs(enemies) do
			target = enemy
			break
		end
	end
	
	if not target then
		for _, other in ipairs(others) do
			target = other
			break
		end
	end
	
	if not target then
		for _, friend in ipairs(friends) do
			target = friend
			break
		end
	end
	self.duliang = nil
	if not target then return end
	use.card = sgs.Card_Parse("@DuliangCard=.")
	if use.to then
		use.to:append(target)
		self.duliang = target
	end
end

sgs.ai_skill_choice.duliang = function(self, choices)
	local target = self.duliang
	if target and self:isFriend(target) then
		if hasManjuanEffect(target) or target:hasSkill("tuxi") or self:needKongcheng(target) then return "draw" end
		if self:isWeak() or self:isWeak(target) then return "watch" end
	end
	if target and not self:isFriend(target) then
		if hasManjuanEffect(target) or target:hasSkill("tuxi") or self:needKongcheng(target) then return "watch" end
		if target:hasSkills(sgs.notActive_cardneed_skill) then return "draw" end
		if target:hasSkills("nostuxi|biluan|shuangxiong|nosfuhun|mobileshuangxiong") then return "draw" end
		if self:isWeak(target) then return "draw" end
	end
    return "draw"
end

sgs.ai_use_priority.DuliangCard = 7

--寝情
sgs.ai_skill_use["@@qinqing"] = function(self, prompt, method)
	local lord = self.room:getLord()
	if not lord then return "." end
	local targets = {}
	for _, target in sgs.qlist(self.room:getAlivePlayers()) do
		if not target:inMyAttackRange(lord) then continue end
		if self:isEnemy(target) then
			if hasManjuanEffect(target) then
				table.insert(targets, target:objectName())
			elseif target:hasEquip() and not self:doNotDiscard(target, "e") and
				(self:getDangerousCard(target) or self:getValuableCard(target) or not target:hasSkills(sgs.notActive_cardneed_skill)) then
				table.insert(targets, target:objectName())
			elseif target:getHandcardNum() >= lord:getHandcardNum() and not self:doNotDiscard(target, "h") then
				table.insert(targets, target:objectName())
			end
		elseif self:isFriend(target) then
			if not hasManjuanEffect(target) then
				if self:needToThrowCard(target, "he", false, false, true) then
					table.insert(targets, target:objectName())
				elseif target:getHandcardNum() > lord:getHandcardNum() then
					table.insert(targets, target:objectName())
				elseif self:isWeak(target) and not target:hasSkills(sgs.need_equip_skill) and
					((target:getWeapon() and self.player:canDiscard(target, target:getWeapon():getId())) or
					(target:getOffensiveHorse() and self.player:canDiscard(target, target:getOffensiveHorse():getId()))) then
					table.insert(targets, target:objectName())
				elseif target:isNude() or not self.player:canDiscard(target, "he") then
					table.insert(targets, target:objectName())
				end
			end
		else
			if target:getHandcardNum() >= lord:getHandcardNum() and not target:isNude() then
				table.insert(targets, target:objectName())
			end
		end
	end
	if #targets == 0 then return "." end
	return "@QinqingCard=.->" .. table.concat(targets, "+")
end

--贿生
sgs.ai_skill_use["@@huisheng"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	self:sortByKeepValue(cards)
	
	local damage = self.room:getTag("HuishengDamage"):toDamage()
	local from = damage.from
	if not from or from:isDead() then return "." end
	if from:isNude() then
		if not cards[1]:isKindOf("Peach") and (not cards[1]:isKindOf("ExNihilo") or self:isWeak()) then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end
	local to = self.player
	local n = damage.damage
	local nature = damage.nature
	local isSlash = false
	if damage.card and damage.card:isKindOf("Slash") then 
		isSlash = true
	end
	if self:getDamagedEffects(to, from, isSlash) or self:needToLoseHp(to, from, isSlash) or not self:damageIsEffective(to, nature, from) then return "." end
	if self:isFriend(from) then
		for _, card in ipairs(cards) do
			table.insert(to_discard, card:getEffectiveId())
		end
		return "@HuishengCard=" .. table.concat(to_discard, "+")
	else
		if n > 1 or self:hasHeavyDamage(from, damage.card, to) or self:needToThrowCard(from) or self.player:getHp() <= 1 then
			for _, card in ipairs(cards) do
				if #to_discard > from:getCards("he"):length() then break end
				if not card:isKindOf("Peach") then
					table.insert(to_discard, card:getEffectiveId())
				end
			end
			return "@HuishengCard=" .. table.concat(to_discard, "+")
		else
			local m
			if self:isWeak() then
				m = math.min(from:getCards("he"):length(), 2)
			else
				m = 1
			end
			for _, card in ipairs(cards) do
				if #to_discard > m then break end
				if not self:keepCard(card) then
					table.insert(to_discard, card:getEffectiveId())
				end
			end
			return "@HuishengCard=" .. table.concat(to_discard, "+")
		end
	end
	return "."
end

sgs.ai_skill_discard.huisheng = function(self, discard_num, min_num, optional, include_equip)
	local to_dis = {}
	local cards = {}
	local ids = self.player:getTag("huisheng_ag_ids"):toIntList()
	for _,id in sgs.qlist(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("ExNihilo") then return {} end
	end
	local damage = self.room:getTag("HuishengDamage"):toDamage()
	local n = ids:length()
	if not self:isEnemy(damage.to) then return {} end
	local hcards = self.player:getCards("he")
	hcards = sgs.QList2Table(hcards)
	self:sortByKeepValue(hcards)
	if n == 1 then
		if self:needToThrowCard() then return self:askForDiscard("dummy", 1, 1, true, include_equip) end
		for _, card in ipairs(hcards) do
			if (not self:keepCard(card) and not self:isValuableCard(card)) or (damage.to:getHp() <= 1 and not hasBuquEffect(damage.to)) then
				table.insert(to_dis, card:getEffectiveId())
				return to_dis
			end
		end
	end
	
	for _, card in ipairs(hcards) do
		for _, card in ipairs(to_dis) do
			if not self:keepCard(card) and #to_dis < min_num then
				table.insert(to_dis, card:getEffectiveId())
				return to_dis
			end
		end
	end
	return to_dis
end

--匡弼
local kuangbi_skill = {}
kuangbi_skill.name = "kuangbi"
table.insert(sgs.ai_skills, kuangbi_skill)
kuangbi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("KuangbiCard") then return end
	return sgs.Card_Parse("@KuangbiCard=.")
end

sgs.ai_skill_use_func.KuangbiCard = function(card, use, self)
	local friends, enemies, others = {}, {}, {}
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do		
		if not player:isNude() and self:isFriend(player) and not hasManjuanEffect(player) then
			table.insert(friends, player)
		elseif not player:isNude() and self:isEnemy(player) and not self:needToThrowCard(player) then
			table.insert(enemies, player)
		elseif not player:isNude() then
			table.insert(others, player)
		end
	end
	
	if #friends == 0 and #enemies == 0 and #others == 0 then return end
	local target
	self:sort(friends, "handcard")
	friends = sgs.reverse(friends)
	
	for _, friend in ipairs(friends) do
		if self:needToThrowCard(friend) or (self:needKongcheng(friend) and not friend:isKongcheng()) then
			target = friend
			break
		end
	end
	
	if not target then
		self:sort(enemies, "handcard")
		for _, enemy in ipairs(enemies) do
			if hasManjuanEffect(enemy) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkills(sgs.dont_kongcheng_skill) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _, enemy in ipairs(enemies) do
			if enemy:hasSkills(sgs.notActive_cardneed_skill) or self:isWeak(enemy) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _, enemy in ipairs(enemies) do
			target = enemy
			break
		end
	end
	
	if not target then
		for _, friend in ipairs(friends) do
			if not self:isWeak(friend) then
				target = friend
				break
			end
		end
	end
	
	if not target then
		for _, other in ipairs(others) do
			target = other
			break
		end
	end
	
	if not target then return end
	use.card = sgs.Card_Parse("@KuangbiCard=.")
	if use.to then
		use.to:append(target)
		local data = sgs.QVariant()
		data:setValue(self.player)
		target:setTag("kuangbiAI", data)
	end
end

sgs.ai_skill_discard.kuangbi = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local source = self.player:getTag("kuangbiAI"):toPlayer()
	self.player:removeTag("kuangbiAI")
	if not source then return self:askForDiscard("dummy", 1, 1, false, include_equip) end
	
	local to_discard = {}
	
	if self:needToThrowArmor() then
		table.insert(to_discard, self.player:getArmor():getEffectiveId())
	end
	if self:needKongcheng() and not self.player:isKongcheng() then
		for _, card in ipairs(cards) do
			if #to_discard >= discard_num then break end
			table.insert(to_discard, card:getId())
		end
	end
	
	if self:isFriend(source) or self.player:hasSkills(sgs.lose_equip_skill) then
		for _, card in sgs.qlist(self.player:getCards("e")) do
			local equip = card:getRealCard():toEquipCard()
			local equip_index = equip:location()
			if not self.player:hasSkills(sgs.lose_equip_skill) and source:getEquip(equip_index) ~= nil then continue end
			if self:keepCard(card) then continue end
			if card:isKindOf("Weapon") then
				if card:isKindOf("Crossbow") then
					if not self:hasCrossbowEffect() and self:getCardsNum("Slash") > 1 then continue end
				end
				if card:isKindOf("Axe") and self:hasHeavySlashDamage(self.player) then continue end
			elseif card:isKindOf("Armor") then
				if self:isWeak() then
					if not self:needToThrowArmor() then continue end
				end
			elseif card:isKindOf("DefensiveHorse") then
				if self:isWeak() then continue end
			end
			if not table.contains(to_discard, card:getEffectiveId()) and (#to_discard < 1 or self.player:hasSkills("xiaoji|kofxiaoji")) then
				table.insert(to_discard, card:getEffectiveId())
			end
			if #to_discard >= discard_num then break end
		end
	end
	
	if self:isFriend(source) then
		local Max = math.min(discard_num, self.player:getHandcardNum() - self.player:getMaxCards())
		if Max > #to_discard then
			for _, card in ipairs(cards) do
				if #to_discard >= Max then break end
				if not table.contains(to_discard, card:getEffectiveId()) then
					table.insert(to_discard, card:getEffectiveId())
				end
			end
		end
	end
	
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		if (card:isKindOf("Disaster") or card:isKindOf("AmazingGrace")) and not self:isValuableCard(card) 
		and not self.player:hasSkills(sgs.notActive_cardneed_skill) and not table.contains(to_discard, card:getEffectiveId()) then
			table.insert(to_discard, card:getEffectiveId())
		end
	end
	
	if #to_discard < 1 then return self:askForDiscard("dummy", 1, 1, false, true) end
	return to_discard
end

sgs.ai_use_priority.KuangbiCard = 7

--极奢
local jishe_skill = {}
jishe_skill.name = "jishe"
table.insert(sgs.ai_skills, jishe_skill)
jishe_skill.getTurnUseCard = function(self)
	if self.player:getMaxCards() < 1 then return end
	return sgs.Card_Parse("@JisheDrawCard=.")
end

sgs.ai_skill_use_func.JisheDrawCard = function(card, use, self)
	if self.player:getHandcardNum() < self.player:getMaxCards() then use.card = card end
	self:sort(self.enemies, "defense")
	local num = 0
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isChained() and not enemy:hasSkills("qianjie|jieying") then
			num = num + 1
		end
	end
	if num > 1 and self.player:getHp() > 1 then
		if self.player:getRole() ~= "renegade" and self.player:getRole() ~= "lord" then use.card = card end
		if self.player:getMaxCards() == 1 then use.card = card end
	end
end

sgs.ai_skill_use["@@jishe"] = function(self, prompt)
	self:sort(self.enemies, "defense")
	local targets = {}
	local n = 0
	for _, enemy in ipairs(self.enemies) do
		if enemy:isChained() then
			n = n + 1
		elseif #targets < self.player:getHp() then
			if not enemy:isChained() and not enemy:hasSkills("qianjie|jieying") and not hasYinshiEffect(enemy) then
				table.insert(targets, enemy:objectName())
			end
		end	
		if n > 0 and #targets == self.player:getHp() then break end
	end
	if (n > 0 or #targets > 0) and #targets < self.player:getHp() and self.player:getRole() ~= "renegade" and self.player:getRole() ~= "lord" and self.player:hasSkill("lianhuo") and not self.player:isChained() then
		table.insert(targets, self.player:objectName())
	end
	if #targets < self.player:getHp() then
		for _, friend in ipairs(self.friends) do
			if not friend:isChained() and hasYinshiEffect(friend) then
				table.insert(targets, friend:objectName())
			end	
			if #targets == self.player:getHp() then break end
		end
	end
	return "@JisheCard=.->" .. table.concat(targets, "+")
end

sgs.ai_card_intention.JisheCard = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		if self:needHurt(to, from) or hasYinshiEffect(to) then continue end
		sgs.updateIntention(from, to, 10)
	end
end

sgs.ai_use_priority.JisheDrawCard = 9
sgs.ai_use_value.JisheDrawCard = 1

--止戈
local zhige_skill = {}
zhige_skill.name = "zhige"
table.insert(sgs.ai_skills, zhige_skill)
zhige_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("ZhigeCard") or self.player:getHandcardNum() <= self.player:getHp() then return end
	return sgs.Card_Parse("@ZhigeCard=.")
end

sgs.ai_skill_use_func.ZhigeCard = function(card,use,self)
	local targets = {}
	local best_enemy = nil
	for _, friend in ipairs(self.friends_noself) do
		if not friend:inMyAttackRange(self.player) then continue end
		local best_target, target
		if getCardsNum("Slash", friend, self.player) >= 1 then
			for _, enemy in ipairs(self.enemies) do
				local slash = sgs.Sanguosha:cloneCard("slash")
				if friend:canSlash(enemy) and not self:slashProhibit(nil, friend, enemy) and friend:inMyAttackRange(enemy)
				and self:slashIsEffective(slash, friend, enemy) and sgs.isGoodTarget(enemy, self.enemies, self, true) then
					if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then best_target = enemy break end
					if sgs.getDefense(enemy) < 6 then best_target = enemy break end
				end
			end
		end
		if getCardsNum("Slash", friend, self.player) > 1 then
			for _, enemy in ipairs(self.enemies) do
				local slash = sgs.Sanguosha:cloneCard("slash")
				if friend:canSlash(enemy) and not self:slashProhibit(nil, friend, enemy) and friend:inMyAttackRange(enemy)
				and self:slashIsEffective(slash, friend, enemy) and sgs.isGoodTarget(enemy, self.enemies, self, true) then
					target = enemy
					break
				end
			end
		end
		
		if best_target or target or self:needToThrowCard(friend, "e") then 
			table.insert(targets, friend)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getCards("e"):isEmpty() or self:needToThrowCard(enemy, "e") then continue end
		if not enemy:inMyAttackRange(self.player) then continue end
		local add_enemy = false
		if enemy:isKongcheng() and getCardsNum("Slash", enemy, self.player) < 1 then add_enemy = true end
		if not add_enemy then
			for _,friend in ipairs(self.friends) do
				local slash = sgs.Sanguosha:cloneCard("slash")
				if enemy:canSlash(friend) and not self:slashProhibit(nil, enemy, friend) and enemy:inMyAttackRange(friend)
				and self:slashIsEffective(slash, enemy, friend) and sgs.isGoodTarget(friend, self.friends, self, true) then
					if getCardsNum("Slash", enemy, self.player) > 1 then break end
					add_enemy = true
				end
			end
		end
		if add_enemy then table.insert(targets, enemy) end
	end
	if #targets == 0 then return end
	for _, target in ipairs(targets) do
		if self:isFriend(target) then continue end
		if getCardsNum("Slash", target, self.player) < 1 then
			if target:getDefensiveHorse() and not self.player:getDefensiveHorse() then
			elseif target:getOffensiveHorse() and not self.player:getOffensiveHorse() then
			elseif target:getArmor() then
				if self.player:getArmor() and self:evaluateArmor(target:getArmor()) >= self:evaluateArmor(self.player:getArmor()) then
				elseif not self.player:getArmor() then
					if self.player:hasSkills("bazhen|yizhong|linglong|fuyin") or hasYinshiEffect(self.player) then return end
				else return end
			elseif target:getWeapon() then
				if self.player:getWeapon() and self:evaluateArmor(target:getWeapon()) >= self:evaluateArmor(self.player:getWeapon()) then
				elseif not self.player:getWeapon() then
				else return end
			elseif target:getTreasure() and target:getPile("wooden_ox"):length() > 0 then
			else continue end
			best_enemy = target
			break
		end
	end
	use.card = card
	if use.to then
		if best_enemy then
			use.to:append(best_enemy)
		else
			self:sort(targets, "defenseSlash")
			use.to:append(targets[1])
		end
	end
end

sgs.ai_skill_use["zhige-slash"] = function(self, data, pattern, target)
	return sgs.ai_skill_use.slash(self, prompt)
end

sgs.ai_skill_cardask["zhige-give"] = function(self, data, pattern, target)
	local id = self:disEquip()
	if id then return "$" .. id end
	local cards = sgs.QList2Table(self.player:getCards("e"))
	self:sortByKeepValue(cards)
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_use_value.ZhigeCard = 2
sgs.ai_use_priority.ZhigeCard = 9.2

--滔乱

--十周年滔乱