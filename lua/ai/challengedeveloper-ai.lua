--略懂

--猜疑

--箭矢
function sgs.ai_cardsview_valuable.dev_jianshi(self, class_name, player)
	if class_name == "Nullification" then
	local jians = player:getPile("dev_jian")
		if jians:length() < 2 then return nil end
		local null = sgs.Sanguosha:cloneCard("nullification")
		null:deleteLater()
		if player:isLocked(null) then return nil end
		return ("nullification:%s[%s:%s]=%d+%d"):format("dev_jianshi", "to_be_decided", 0, jians:first(), jians:last())
	end
end

sgs.ai_skill_invoke.dev_jianshi = function(self, data)
	return true
end

--藏刀
sgs.ai_skill_askforyiji.dev_cangdao = function(self, card_ids)
	local enemies, id = {}, -1
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_dev_cangdao")
	slash:deleteLater()
	
	local targets = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canSlash(enemy, slash, false) then
			table.insert(targets, p)
		end
	end
	if #targets > 0 then
		local target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
		if target and self:isFriend(target) then
			return target, card_ids[1]
		end
	end
	
	for i = 1, #card_ids do
		id = card_ids[i]
		local card = sgs.Sanguosha:getCard(card_ids[i])
		local index = card:getRealCard():toEquipCard():location()
		for _,enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, slash, false) and self:slashIsEffective(slash, enemy, self.player) and
			self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
				if enemy:getEquip(index) or not enemy:hasEquipArea(index) then
					table.insert(enemies, enemy)
				end
			end
		end
		if #enemies > 0 then break end
	end
	
	if #enemies > 0 and id > 0 then
		self:sort(enemies, "defenseSlash")
		for _,enemy in ipairs(enemies) do
			if sgs.isGoodTarget(enemy, enemies, self, true, self.player) then
				return enemy, id
			end
		end
		for _,enemy in ipairs(enemies) do
			if not self:getDamagedEffects(enemy, self.player, true) then
				return enemy, id
			end
		end
	end
	
	return sgs.ai_skill_askforyiji.miji(self, card_ids)
end

sgs.ai_skill_invoke.dev_cangdao = function(self, data)
	local to = data:toPlayer()
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_dev_cangdao")
	slash:deleteLater()
	
	if self:isEnemy(to) then
		if self:slashIsEffective(slash, to, self.player) and self:damageIsEffective(to, sgs.DamageStruct_Normal, self.player) and
		not self:getDamagedEffects(enemy, self.player, true) then
			return true
		end
	end
	if self:isFriend(to) then
		local huatuo = false
		for _,p in ipairs(self.friends) do
			if self:isFriend(p) and p:hasSkill("jijiu") and p:getPhase() == sgs.Player_NotActive then
				huatuo = true
				break
			end
		end
		if not self:hasHeavySlashDamage(self.player, slash, to) and not self:slashProhibit(slash, to) and self:slashIsEffective(slash, to)
		and ((self:findLeijiTarget(to, 50, self.player, -1) or (self:findLeijiTarget(to, 50, self.player, 1) and to:isWounded()))
		or (to:isLord() and self.player:hasSkill("guagu") and to:getLostHp() >= 1 and getCardsNum("Jink", to, self.player) == 0)
		or (friend:hasSkill("jieming") and self.player:hasSkill("nosrende") and huatuo)) then
			return true
		end
	end
	return false
end

--全能
sgs.ai_skill_invoke.dev_quanneng = function(self, data)
	return true
end

sgs.ai_skill_invoke.dev_quanneng_buyi = function(self, data)
	local dying = sgs.DyingStruct()
	dying.who = data:toPlayer()
	local new_data = sgs.QVariant()
	new_data:setValue(dying)
	return sgs.ai_skill_invoke.buyi(self, new_data)
end

sgs.ai_skill_invoke.dev_quanneng_lieren = function(self, data)
	local damage = sgs.DamageStruct()
	damage.to = data:toPlayer()
	local new_data = sgs.QVariant()
	new_data:setValue(damage)
	return sgs.ai_skill_invoke.lieren(self, new_data)
end

--破风
local dev_pofeng_skill = {}
dev_pofeng_skill.name = "dev_pofeng"
table.insert(sgs.ai_skills, dev_pofeng_skill)
dev_pofeng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isNude() then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	table.sort(cards,function(a, b)
		return a:getNumber() > b:getNumber()
	end)
	if cards[1]:getNumber() >= 9 then
		if sgs.ai_skill_invoke.qinyin(self) then
			if sgs.ai_skill_choice.qinyin == "down" then
				if not self.player:hasUsed("DevPofengCard") then
					self.dev_pofeng_cardId = cards[1]:getEffectiveId()
					return sgs.Card_Parse("@DevPofengCard=.")
				else
					return 
				end
			end
		end
	elseif cards[#cards]:getNumber() <= 5 then
		if sgs.ai_skill_invoke.qinyin(self) then
			if sgs.ai_skill_choice.qinyin == "up" then
				if not self.player:hasUsed("DevPofengCard") then
					self.dev_pofeng_cardId = cards[1]:getEffectiveId()
					return sgs.Card_Parse("@DevPofengCard=.")
				else
					return 
				end
			end
		end
	end
end

sgs.ai_skill_use_func.DevPofengCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.DevPofengCard = sgs.ai_use_priority.RendeCard + 0.1
sgs.ai_use_value.DevPofengCard = 2

sgs.ai_skill_discard.dev_pofeng = function(self, discard_num, min_num, optional, include_equip)
	if self.dev_pofeng_cardId then
		local id = self.dev_pofeng_cardId
		self.dev_pofeng_cardId = nil
		return {id}
	end
	
	local n = self.player:getTag("dev_pofeng_num"):toInt()
	if n <= 0 then return self:askForDiscard("dummyreason", 1, 1, optional, include_equip) end
	
	local cards, discards = sgs.QList2Table(self.player:getCards("he")), {}
	table.sort(cards,function(a, b)
		return a:getNumber() > b:getNumber()
	end)
	
	if sgs.ai_skill_invoke.qinyin(self) then
		if sgs.ai_skill_choice.qinyin == "down" then
			for _,c in ipairs(cards) do
				if c:getNumber() < n then
					table.insert(discards, c)
				end
			end
		else
			for _,c in ipairs(cards) do
				if c:getNumber() > n then
					table.insert(discards, c)
				end
			end
		end
	end
	if #discards > 0 then
		self:sortByKeepValue(discards)
		return {discards[1]:getEffectiveId()}
	end
	
	return self:askForDiscard("dummyreason", 1, 1, optional, include_equip)
end

--销魂
local dev_xiaohun_skill = {}
dev_xiaohun_skill.name = "dev_xiaohun"
table.insert(sgs.ai_skills, dev_xiaohun_skill)
dev_xiaohun_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@dev_xiaohunMark") < 1 then return end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getHandcardNum() < self.room:getOtherPlayers(self.player):length()/2 then return end
	self:sortByKeepValue(cards)
	sgs.dev_xiaohun_CardIds = {}
	local targets = {}
	local f,e = 0,0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if #targets > self.player:getHandcardNum() then break end
		if p:getHp() == 0 or p:isDead() then continue end
		if self:isEnemy(p) then
			for _,c in sgs.list(cards)do
				if c:getNumber() % p:getHp() == 0 then
					sgs.dev_xiaohun_CardIds[p:objectName()] = c:getEffectiveId()
					table.removeOne(cards,c)
					table.insert(targets,p)
					e = e + 1
				end
			end
		elseif self:isFriend(p) then
			for _,c in sgs.list(cards)do
				if c:getNumber() % p:getHp() ~= 0 and not self:needKongcheng(p) then
					sgs.dev_xiaohun_CardIds[p:objectName()] = c:getEffectiveId()
					table.removeOne(cards,c)
					table.insert(targets,p)
					f = f + 1
				end
			end
		end
	end
	if e > 0 or f > 1 then
		return sgs.Card_Parse("@DevXiaohunCard=.")
	end
end

sgs.ai_skill_use_func.DevXiaohunCard=function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.DevXiaohunCard = sgs.ai_use_priority.DevPofengCard + 0.05

sgs.ai_skill_askforyiji.dev_xiaohun = function(self, card_ids)
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:hasFlag("dev_xiaohun") then continue end
		if sgs.dev_xiaohun_CardIds[p:objectName()] ~= nil then
			return p, sgs.dev_xiaohun_CardIds[p:objectName()]
		end
	end
	return nil, -1
end

--塞车
sgs.ai_skill_cardask["@dev_saiche-give"] = function(self, data)
	local target = data:toPlayer()
	if target:isSkipped(sgs.Player_Play) or self:willSkipPlayPhase(target) then return "." end
	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	
	if isCard("Peach", cards[1], self.player) or isCard("Jink", cards[1], self.player) then return "." end
	
	local far_enemies, near_enemies = {}, {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(target))do
		if self:isEnemy(target, p) then
			if target:distanceTo(p) > 1 then
				table.insert(far_enemies, p)
			else
				table.insert(near_enemies, p)
			end
		end
	end
	
	local num = 1
	if #self.enemies == 1 then num = 0 end
	
	if self:isFriend(target) and #far_enemies > num then return "." end
	if self:isFriend(target) and #far_enemies == 0 and not self:needKongcheng(target) then return "$" .. cards[1]:getEffectiveId() end
	if self:isEnemy(target) and self:isWeak(far_enemies) and not self:isWeak(near_enemies) and target:getHandcardNum() > 3 and target:getAttackRange() >= 2 then
		if isCard("Slash", cards[1], target) or isCard("ThunderSlash", cards[1], target) or isCard("FireSlash", cards[1], target) or isCard("IceSlash", cards[1], target) or
		isCard("ExNihilo", cards[1], target) then
			return "."
		end
		return "$" .. cards[1]:getEffectiveId()
	end
	return "."
end

--110
function sgs.ai_slash_prohibit.dev_110(self, from, to, card)
	return to:hasSkill("dev_110") and to:getMark("dev_110_first_time") <= 0 and from:faceUp() and self:isWeak(from) and to:getPhase() == sgs.Player_NotActive
end

sgs.ai_need_damaged.dev_110 = function (self, attacker, player)
	if player:getMark("dev_110_first_time") > 0 or player:getPhase() ~= sgs.Player_NotActive then return false end
	if self:isFriend(attacker) and not attacker:faceUp() then return true end
	if attacker:faceUp() and self:isWeak(attacker) and self:isEnemy(attacker) then return true end  --据守、放逐什么的再说吧
	return false
end

--假药
sgs.ai_skill_discard.dev_jiayao = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and self:getOverflow() <= 0 then return {} end
	self:sortByKeepValue(cards)

	for i = 1, #cards do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			return {card:getEffectiveId()}
		end
	end
	return {}
end

--上瘾
sgs.ai_skill_playerchosen.dev_shangyin = function(self, targets)
	local slashs = self:getCards("Slash")
	if self.player:getSlashCount() == 0 and #slashs <= 1 then return self:findPlayerToDraw(true, 1) end
	
	for _, slash in ipairs(self:getCards("Slash")) do
		if self:willUse(self.player, slash, false, false, true) then
			return self.player
		end
	end
	return self:findPlayerToDraw(true, 1)
end

--鲜橙
sgs.ai_skill_invoke.dev_shuguang = function(self, data)
	return self:canDraw()
end

--橙汁
function sgs.ai_cardsview_valuable.dev_chengzhi(self, class_name, player)
	if class_name == "Peach" then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if dying then
			local slashs = {}
			for _,c in sgs.qlist(player:getCards("h")) do
				if c:isKindOf("Slash") then
					table.insert(slashs, c)
				end
			end
			if #slashs > 0 then
				self:sortByUseValue(slashs, true)
				return "@DevChengzhiCard=" .. slashs[1]:getEffectiveId()
			end
		end
	end
end

function sgs.ai_cardneed.dev_chengzhi(to, card)
	return card:isKindOf("Slash") and to:getHandcardNum() <= 2
end

--半橙
local dev_bancheng_skill={}
dev_bancheng_skill.name = "dev_bancheng"
table.insert(sgs.ai_skills, dev_bancheng_skill)
dev_bancheng_skill.getTurnUseCard = function(self,inclusive)
	if self.player:hasUsed("DevBanchengCard") then return end
	return sgs.Card_Parse("@DevBanchengCard=.")
end

sgs.ai_skill_use_func.DevBanchengCard = function(card, use, self)
	local num = 2 + self.player:getLostHp()
	
	if num == 2 then
		self:sort(self.friends_noself, "handcard")
		for _,p in ipairs(self.friends_noself) do
			if not self:canDraw(p) then continue end
			if self:damageIsEffective(p, nil, self.player) then continue end
			use.card = card
			self.dev_bancheng_target = p:objectName()
			if use.to then
				use.to:append(p)
			end
			return
		end
		for _,p in ipairs(self.friends_noself) do
			if not self:canDraw(p) then continue end
			if self:isWeak(p) then continue end
			use.card = card
			self.dev_bancheng_target = p:objectName()
			if use.to then
				use.to:append(p)
			end
			return
		end
		for _,p in ipairs(self.friends_noself) do
			if not self:canDraw(p) then continue end
			use.card = card
			self.dev_bancheng_target = p:objectName()
			if use.to then
				use.to:append(p)
			end
			return
		end
	else
		local enemies = {}
		for _,p in ipairs(self.enemies) do
			if not self:damageIsEffective(p, nil, self.player) then continue end
			table.insert(enemies, p)
		end
		if #enemies == 0 then return end
		self:sort(enemies, "hp")
		
		for _,p in ipairs(enemies) do
			local damage = self:ajustDamage(self.player, p, 1)
			if damage >= p:getHp() and not hasBuquEffect(p) then
				use.card = card
				self.dev_bancheng_target = p:objectName()
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
		for _,p in ipairs(enemies) do
			local damage = self:ajustDamage(self.player, p, 1)
			if damage >= p:getHp() and not self:canDraw(p) then
				use.card = card
				self.dev_bancheng_target = p:objectName()
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
		for _,p in ipairs(enemies) do
			local damage = self:ajustDamage(self.player, p, 1)
			if damage >= p:getHp() then
				use.card = card
				self.dev_bancheng_target = p:objectName()
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
		for _,p in ipairs(enemies) do
			use.card = card
			self.dev_bancheng_target = p:objectName()
			if use.to then
				use.to:append(p)
			end
			return
		end
	end
end

sgs.ai_use_priority.DevBanchengCard = sgs.ai_use_priority.QiangxiCard
sgs.ai_use_value.DevBanchengCard = sgs.ai_use_value.QiangxiCard

sgs.ai_card_intention.DevBanchengCard = function(self, card, from, tos)
	local intention = 50
	for _,to in ipairs(tos) do
		if not self:damageIsEffective(to, nil, from) then intention = -20
		elseif from:getLostHp() == 0 then intention = 0 end
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_skill_use["@@dev_bancheng"] = function(self, prompt)
	local card = sgs.Card_Parse("@DevBanchengCard=.")
	local dummy_use = {isDummy = true}
	self:useSkillCard(card, dummy_use)
	if dummy_use.card then
		if self.dev_bancheng_target then
			return "@DevBanchengCard=.->" .. self.dev_bancheng_target
		end
	end
	return "."
end

sgs.ai_need_damaged.dev_bancheng = function (self, attacker, player)
	return not self:isWeak(player) and self:isWeak(self:getEnemies(player))
end

--曙光
sgs.ai_skill_invoke.dev_shuguang = function(self, data)
	local who = data:toPlayer()
	if who:getLostHp() == 0 or not self:isFriend(who) then return false end
	if who:getMaxHp() - who:getHp() == 1 and not self.player:hasFlag("Global_PreventPeach") then
		for _, peach in ipairs(self:getCards("Peach")) do
			if not self.player:isProhibited(who, peach) then
				return false
			end
		end
	end
	return true
end

--妮妮
local dev_nini_skill={}
dev_nini_skill.name = "dev_nini"
table.insert(sgs.ai_skills, dev_nini_skill)
dev_nini_skill.getTurnUseCard = function(self,inclusive)
	if self.player:hasUsed("DevNiniCard") or #self.enemies <= 0 then return end
	return sgs.Card_Parse("@DevNiniCard=.")
end

sgs.ai_skill_use_func.DevNiniCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	for _,p in ipairs(self.enemies) do
		if not self.player:canPindian(p) or self:doNotDiscard(p, "h") then continue end
		use.card = sgs.Card_Parse("@DevNiniCard=.")
		if use.to then use.to:append(p) end return
	end
end

sgs.ai_use_priority.DevNiniCard = sgs.ai_use_priority.RendeCard + 0.15

function sgs.ai_skill_pindian.dev_nini(minusecard, self, requestor)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if requestor:objectName() == self.player:objectName() then
		return cards[1]:getId()
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 5 and  minusecard or maxcard )
end

--蛋疼
sgs.ai_skill_invoke.dev_danteng = function(self, data)
	local target = data:toPlayer()
	if target:objectName() == self.player:objectName() then return self:canDraw() end
	if target:isWounded() then return self:canDraw() end
	if self:isFriend(target) then return self:canDraw() and target:getHandcardNum() <= 2 end
	return self:canDraw()
end

--更新
sgs.ai_skill_use["@@dev_gengxin"] = function(self, prompt)
	local x = {}
	local enemies, friends = {}, {}
	for _,p in ipairs(self.enemies) do
		if p:getWeapon() and self.player:canDiscard(p, p:getEquip(0):getEffectiveId()) and not self:doNotDiscard(p,"e") then
			table.insert(enemies, p)
		end
	end
	for _,p in ipairs(self.friends) do
		if p:getWeapon() and self.player:canDiscard(p, p:getEquip(0):getEffectiveId()) and (p:hasSkills(sgs.lose_equip_skill) or self:doNotDiscard(p, "e")) then
			table.insert(friends, p)
		end
	end
	if #enemies>0 then
		for _,p in ipairs(enemies) do
			table.insert(x, p:getWeapon():getRealCard():toWeapon():getRange())
		end
		table.sort(x)
		for _,p in ipairs(enemies) do
			if p:getWeapon():getRealCard():toWeapon():getRange() == x[#x] then
				return "@DevGengxinCard=.->" .. p:objectName()
			end
		end
	end
	if #friends>0 then
		for _,p in ipairs(friends) do
			table.insert(x, p:getWeapon():getRealCard():toWeapon():getRange())
		end
		table.sort(x)
		for _,p in ipairs(friends) do
			if p:getWeapon():getRealCard():toWeapon():getRange() == x[#x] then
				return "@DevGengxinCard=.->" .. p:objectName()
			end
		end
	end
	
	local weapons = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("Weapon") then
			table.insert(weapons, c)
			table.insert(x, c:getRealCard():toWeapon():getRange())
		end
	end
	if #weapons > 0 then
		table.sort(x)
		local id = -1
		for _,c in ipairs(weapons) do
			if c:getRealCard():toWeapon():getRange() == x[#x] then
				id = c:getEffectiveId()
				break
			end
		end
		for _,p in ipairs(self.friends) do
			if not p:getWeapon() and p:hasWeaponArea() then
				table.insert(friends, p)
			end
		end
		if #friends > 0 then
			function attack_range_sort(a, b)
				local c1 = a:getAttackRange()
				local c2 = b:getAttackRange()
				return c1 < c2
			end
			table.sort(friends, attack_range_sort)
			return "@DevGengxinCard=" .. id .. "->" .. friends[1]:objectName()
		end
	end
	
	if self:isWeak() and self.player:getWeapon() and self.player:canDiscard(self.player, self.player:getEquip(0):getEffectiveId()) then
		return "@DevGengxinCard=.->" .. self.player:objectName()
	end
	return "."
end

--学霸
sgs.ai_skill_invoke.dev_xueba = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_skill_choice.xuehen = function(self, choices)
	choices = choices:split("+")
	for _, choice in ipairs(choices) do
		if self:isValueSkill(choice, self.player, true) then
			return choice
		end
	end
	for _, choice in ipairs(choices) do
		if self:isValueSkill(choice, self.player) then
			return choice
		end
	end
	for _, choice in ipairs(choices) do
		if string.find(sgs.bad_skills, choice) then continue end
		return choice
	end
	return choices[math.random(1, #choices)]
end

--魅惑
sgs.ai_skill_invoke.dev_meihuo = function(self, data)
	local target = data:toPlayer()
	if target then
		return self:canDraw() and not self:isFriend(target) and (not self:doNotDiscard(target, "h") or
		(target:getHp() == 1 and target:getHandcardNum() == 1 and not hasBuquEffect(target)))
	else
		local use = data:toCardUse()
		local nature = sgs.DamageStruct_Normal
		if use.card:isKindOf("FireSlash") then nature = sgs.DamageStruct_Fire
		elseif use.card:isKindOf("ThunderSlash") then nature = sgs.DamageStruct_Thunder
		elseif use.card:isKindOf("IceSlash") then nature = sgs.DamageStruct_Ice end
		if self:canDraw() then
			if self:isFriend(use.from) then
				return self:isGoodChainTarget(self.player, use.from, nature) and self:slashIsEffective(use.card, self.player, use.from) and
					self:damageIsEffective(self.player, nature, use.from)
			end
			return true
		end
		return self:isWeak() and not self:isFriend(use.from) and self:slashIsEffective(use.card, self.player, use.from) and self:damageIsEffective(self.player, nature, use.from)
	end
	return false
end

--女神
sgs.ai_skill_playerchosen.dev_nvshen = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "HP")
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	
	if self:hasSkills(sgs.recover_hp_skill, self.friends) then
		targets = sgs.reverse(targets)
		for _,p in ipairs(targets) do
			if self:isFriend(p) then
				return p
			end
		end
	end
	
	return nil
end

--嗝屁
sgs.ai_skill_invoke.dev_gepi = function(self, data)
	if self.player:getCardCount() == 1 and not self.player:isKongcheng() and self.player:getCards("h"):first():isKindOf("Peach") and self:isWeak(self.friends) then return false end
	local target = data:toPlayer()
	local skills = {}
	for _,sk in sgs.qlist(target:getVisibleSkillList()) do
		if sk:isAttachedLordSkill() or sk:inherits("SPConvertSkill") or sk:isLordSkill() or
		sk:getFrequency() == sgs.Skill_Wake or table.contains(skills, sk:objectName()) then continue end
		table.insert(skills, sk:objectName())
	end
	if #skills == 0 then return self:canDraw(target) and self:isFriend(target) end
	if self:isFriend(target) then
		for _,sk in ipairs(skills) do
			if string.find(sgs.bad_skills, sk) then
				sgs.ai_skill_choice.dev_gepi = sk
				return true
			end
		end
	elseif self:isEnemy(target) then
		for _,sk in ipairs(skills) do
			if not string.find(sgs.Sanguosha:getSkill(sk):getDescription(), "出牌阶段") then continue end
			if self:isValueSkill(sk, target) then
				sgs.ai_skill_choice.dev_gepi = sk
				return true
			end
		end
	end
	return false
end

--柴刀
sgs.ai_skill_invoke.dev_chaidao = function(self, data)
	local str = data:toString():split(":")
	if #str ~= 2 then return false end
	local target = self.room:findPlayerByObjectName(str[2])  --被横置就先不考虑了
	if str[1] == "DamageCaused" then
		return self:isEnemy(target) and not self:cantDamageMore(self.player, target)
	elseif str[1] == "DamageInflicted" then
		return not self:isFriend(target)  --被横置就先不考虑了，有卖血技也先不考虑了
	end
	return false
end

--骚动
sgs.ai_skill_discard.dev_saodong = function(self, discard_num, min_num, optional, include_equip)
	local damage = self.player:getTag("dev_saodong_damage"):toDamage()
	if not damage or not damage.from or damage.from:isDead() or not damage.card or not damage.card:isKindOf("TrickCard") then return {} end
	
	local diamond = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:getSuit() ~= sgs.Card_Diamond then continue end
		table.insert(diamond, c)
	end
	if #diamond == 0 then return {} end
	self:sortByUseValue(diamond, true)
	
	local nature = sgs.DamageStruct_Normal
	if damage.card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire
	elseif damage.card:isKindOf("Drowning") then nature = sgs.DamageStruct_Thunder end
	
	if not self:damageIsEffective(self.player, nature, damage.from) then return {} end
	
	if self:isFriend(damage.from) then
		if self:isWeak(damage.from) and self:damageIsEffective(damage.from, nature, damage.from) then return {} end
		if not self:damageIsEffective(damage.from, nature, damage.from) then return {diamond[1]:getEffectiveId()} end
		if self:isWeak() then return {diamond[1]:getEffectiveId()} end
	else
		if diamond[1]:isKindOf("Peach") or diamond[1]:isKindOf("Analeptic") then return {} end
		if not self:isWeak() and (diamond[1]:isKindOf("ExNihilo") or diamond[1]:isKindOf("Dongzhuxianji")) then return {} end
		return {diamond[1]:getEffectiveId()}
	end
	
	return {}
end

sgs.ai_skill_cardask["@dev_saodong"] = function(self, data)
	local heart = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:getSuit() ~= sgs.Card_Heart then continue end
		table.insert(heart, c)
	end
	if #heart == 0 then return {} end
	self:sortByUseValue(heart, true)
	
	for _,c in ipairs(heart) do
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
		peach:addSubcard(c)
		peach:deleteLater()
		peach:setSkillName("dev_saodong")
		
		local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_SuitToBeDecided, -1)
		ex_nihilo:addSubcard(c)
		ex_nihilo:deleteLater()
		ex_nihilo:setSkillName("dev_saodong")
		
		if self:isWeak() then
			if peach:isAvailable(self.player) and self:getUseValue(peach) >= self:getUseValue(c) and self.player:getMark("dev_geili_effect-Clear") <= 0 then
				sgs.ai_skill_choice.dev_saodong = "peach"
				return "$" .. c:getEffectiveId()
			end
		elseif self:canDraw() then
			if self:hasTrickEffective(ex_nihilo, self.player, self.player) and ex_nihilo:isAvailable(self.player) and self:getUseValue(ex_nihilo) >= self:getUseValue(c) then
				sgs.ai_skill_choice.dev_saodong = "ex_nihilo"
				return "$" .. c:getEffectiveId()
			end
		elseif self.player:getLostHp() > 0 then
			if peach:isAvailable(self.player) and self:getUseValue(peach) >= self:getUseValue(c) and self.player:getMark("dev_geili_effect-Clear") <= 0 then
				sgs.ai_skill_choice.dev_saodong = "peach"
				return "$" .. c:getEffectiveId()
			end
		end
	end
	
	return "."
end

--治愈
sgs.ai_skill_playerchosen.dev_zhiyu = function(self, targets)
	targets = sgs.QList2Table(targets)
    self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
		    if p:getLostHp() > 1 or self:isWeak(p) then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.dev_zhiyu = -100

--指引
sgs.ai_skill_playerchosen.dev_zhiyin = function(self, targets)
	return self:findPlayerToDiscard("j", false, true, targets)
end

sgs.ai_playerchosen_intention.dev_zhiyin = -20

--教导
sgs.ai_skill_invoke.dev_jiaodao = function(self, data)
	local use = self.player:getTag("dev_jiaodao_data"):toCardUse()
	if not use then return false end
	--return self:willUse(use.from, use.card, false, false, true)
	return self:willUse(self.player, use.card, false, false, true)
end

--美工
function SmartAI:DevLimitedSkillSort(players, no_mark)
	if type(players) ~= "table" then
		players = sgs.QList2Table(players)
	end
	local func = function(a, b)
		local c1, c2 = 0, 0
		for _,skill in sgs.qlist(a:getVisibleSkillList()) do
			if not skill:isLimitedSkill() or skill:getLimitMark() == "" then continue end
			if no_mark and a:getMark(skill:getLimitMark()) > 0 then continue end
			c1 = c1 + 1
		end
		for _,skill in sgs.qlist(b:getVisibleSkillList()) do
			if not skill:isLimitedSkill() or skill:getLimitMark() == "" then continue end
			if no_mark and b:getMark(skill:getLimitMark()) > 0 then continue end
			c2 = c2 + 1
		end
		if c1 == c2 then
			return sgs.getDefenseSlash(a, self) > sgs.getDefenseSlash(b, self)
		end
		return c1 > c2
	end
	table.sort(players, func)
end

local dev_meigong_skill={}
dev_meigong_skill.name = "dev_meigong"
table.insert(sgs.ai_skills, dev_meigong_skill)
dev_meigong_skill.getTurnUseCard = function(self,inclusive)
	if self.player:hasUsed("DevMeigongCard") or #self.friends_noself <= 0 then return end
	return sgs.Card_Parse("@DevMeigongCard=.")
end

sgs.ai_skill_use_func.DevMeigongCard = function(card, use, self)
	self:DevLimitedSkillSort(self.friends_noself, true)
	local num = 0
	for _,skill in sgs.qlist(self.friends_noself[1]:getVisibleSkillList()) do
		if not skill:isLimitedSkill() or skill:getLimitMark() == "" then continue end
		if self.friends_noself[1]:getMark(skill:getLimitMark()) > 0 then continue end
		num = num + 1
	end
	if num > 0 then
		use.card = sgs.Card_Parse("@DevMeigongCard=.")
		if use.to then use.to:append(self.friends_noself[1]) end return
	end
	
	self:DevLimitedSkillSort(self.friends_noself)
	use.card = sgs.Card_Parse("@DevMeigongCard=.")
	if use.to then use.to:append(self.friends_noself[1]) end
end

--弃疗
sgs.ai_skill_playerchosen.dev_qiliao = function(self, targets)
	targets = sgs.QList2Table(targets)
	
	self:sort(targets, "hp")
	for _,p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if p:getLostHp() > 0 and self:isWeak(p) then
			return p
		end
	end
	
	return self:findPlayerToDraw(false, 1)
end

sgs.ai_playerchosen_intention.dev_qiliao = -20

sgs.ai_skill_invoke.dev_qiliao = function(self, data)
	local strs = data:toString():split(":")
	if #strs ~= 2 then return false end
	local target = self.room:findPlayerByObjectName(strs[2])
	if not target or target:isDead() then return false end
	return self:isFriend(target) and self:isWeak(target) and target:getLostHp() > 0
end

--学习
sgs.ai_skill_invoke.dev_xuexi = function(self, data)
	return self:canDraw()
end

--给力
sgs.ai_skill_invoke.dev_geili = function(self, data)
	local target = data:toPlayer()
	return self:isEnemy(target) and target:getLostHp() > 0
end

--奆佬
local dev_juanlao_skill = {}
dev_juanlao_skill.name = "dev_juanlao"
table.insert(sgs.ai_skills, dev_juanlao_skill)
dev_juanlao_skill.getTurnUseCard = function(self)
	if self.player:getMark("dev_juanlao-PlayClear") <= 0 and self.player:getPhase() == sgs.Player_Play then
		local name = self.player:property("dev_juanlao_card"):toString()
		if not name or name == nil or name == "" then return end
		local card_str = ("%s:dev_juanlao[no_suit:0]=."):format(name)
		local card = sgs.Card_Parse(card_str)
		if not card or card:isKindOf("IronChain") then return end
		assert(card)
		return card
	end
end

--饺气
sgs.ai_skill_invoke.dev_jiaoqi = function(self, data)
	local strs = data:toString():split(":")
	if #strs ~= 2 then return false end
	local target = self.room:findPlayerByObjectName(strs[2])
	if not target or target:isDead() then return false end
	if strs[1] == "discard" then
		return self:isEnemy(target) and not self:doNotDiscard(target, "e")
	elseif strs[1] == "jink" then
		return self:isEnemy(target)
	end
	return false
end

--饺猾
sgs.ai_skill_use["@@dev_jiaohua"] = function(self, prompt)
	local cards, suits = {}, {}
	for _,c in sgs.qlist(self.player:getEquips()) do
		local suit = c:getSuit()
		if not table.contains(suits, suit) then
			table.insert(suits, suit)
		end
	end
	if #suits == 0 then return "." end
	
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if not table.contains(suits, c:getSuit()) then continue end
		local slash = sgs.Sanguosha:cloneCard("slash", c:getSuit(), c:getNumber())
		slash:setSkillName("dev_jiaohua")
		slash:addSubcard(c)
		slash:deleteLater()
		
		if not self.player:isLocked(slash, true) and self:willUse(self.player, slash, false, false, true) then
			table.insert(cards, c)
		end
	end
	if #cards == 0 then return "." end
	
	self:sortByUseValue(cards, true)
	
	local targets = {}
	local slash = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
	slash:setSkillName("dev_jiaohua")
	slash:addSubcard(cards[1])
	slash:deleteLater()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		for _,p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
	end
	if #targets == 0 then return "." end
	
	return ("slash:dev_jiaohua[%s:%s]=%d->%s"):format(cards[1]:getSuitString(), cards[1]:getNumberString(), cards[1]:getEffectiveId(), table.concat(targets, "+"))
end


