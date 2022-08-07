--推弑
sgs.ai_skill_playerchosen.jintuishi = function(self, targets)
	local player = self.player:getTag("jintuishi_from"):toPlayer()
	if self:isFriend(player) then return nil end
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	
	for _, p in ipairs(targets) do
		if self:isEnemy(player, p) and self:slashIsEffective(slash, p, player) and self:needLeiji(p, player) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(player, p) and self:slashIsEffective(slash, p, player) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(player, p) then
			return p
		end
	end
	
	for _, p in ipairs(targets) do
		if not self:isFriend(player, p) and not self:isEnemy(player, p) then
			return p
		end
	end
	
	if getCardsNum("Slash", player, self.player) == 0 then
		targets = sgs.reverse(targets)
		return targets[1]
	end
	return nil
end

sgs.ai_skill_cardask["@jintuishi_slash"] = function(self, data, pattern, target)
	return sgs.ai_skill_cardask["@mobileniluan"](self, data, pattern, target)
end

--筹伐
local jinchoufa_skill = {}
jinchoufa_skill.name = "jinchoufa"
table.insert(sgs.ai_skills, jinchoufa_skill)
jinchoufa_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("JinChoufaCard") then return end
	return sgs.Card_Parse("@JinChoufaCard=.")
end

sgs.ai_skill_use_func.JinChoufaCard = function(card,use,self)
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	
	for _,p in ipairs(self.friends_noself) do
		if p:isKongcheng() then continue end
		if p:canSlashWithoutCrossbow() or p:hasWeapon("crossbow") or p:hasWeapon("vscrossbow") and self:willUse(p, slash) then
			use.card = card
			if use.to then use.to:append(p) end
			return
		end
	end
	
	for _,p in ipairs(self.enemies) do
		if p:isKongcheng() then continue end
		if (p:canSlashWithoutCrossbow() or p:hasWeapon("crossbow") or p:hasWeapon("vscrossbow")) and self:willUse(p, slash) then continue end
		use.card = card
		if use.to then use.to:append(p) end
		return
	end
end

sgs.ai_use_value.JinChoufaCard = 10

--昭然
sgs.ai_skill_invoke.jinzhaoran = true

sgs.ai_skill_playerchosen.jinzhaoran = function(self, targets)
	return self:findPlayerToDiscard("he", false, true, targets)
end

--识人
sgs.ai_skill_invoke.jinshiren = function(self, data)
	local current = data:toPlayer()
	if self:isFriend(current) then
		if self:needToThrowLastHandcard(current) then return true end
		if self:getOverflow(current) > 2 then return true end
		if self:doNotDiscard(current) then return true end
	elseif self:isEnemy(current) then
		if not self:needToThrowLastHandcard(current) then return true end
		if not self:doNotDiscard(current) then return true end
	else
		return true
	end
	return false
end

--宴戏
local jinyanxi_skill = {}
jinyanxi_skill.name = "jinyanxi"
table.insert(sgs.ai_skills, jinyanxi_skill)
jinyanxi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("JinYanxiCard") or #self.enemies <= 0 then return end
	return sgs.Card_Parse("@JinYanxiCard=.")
end

sgs.ai_skill_use_func.JinYanxiCard = function(card,use,self)
	if #self.enemies <= 0 then return end
	local target = nil
	self:sort(self.enemies, "handcard")
	for _,p in ipairs(self.enemies) do
		if self:doNotDiscard(p, "h") then continue end
		target = p
		break
	end
	if not target then return end
	if target:getHandcardNum() > 0 then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value.JinYanxiCard = 10
sgs.ai_card_intention.JinYanxiCard = 50

--三陈
local jinsanchen_skill = {}
jinsanchen_skill.name = "jinsanchen"
table.insert(sgs.ai_skills, jinsanchen_skill)
jinsanchen_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("JinSanchenCard") < 1 + self.player:getMark("jinsanchen_times-PlayClear") then
		return sgs.Card_Parse("@JinSanchenCard=.")
	end
end

sgs.ai_skill_use_func.JinSanchenCard = function(card,use,self)
	self:sort(self.friends, "handcard")
	self.friends = sgs.reverse(self.friends)
	for _,p in ipairs(self.friends) do
		if self:doNotDiscard(p, "h") and p:getMark("jinsanchen_target-Clear") == 0 then
			use.card = card
			if use.to then
				use.to:append(p)
			end
			return
		end
	end
	for _,p in ipairs(self.friends) do
		if p:getMark("jinsanchen_target-Clear") > 0 then continue end
		use.card = card
		if use.to then
			use.to:append(p)
		end
		return
	end
end

sgs.ai_use_value.JinSanchenCard = 10
sgs.ai_card_intention.JinSanchenCard = -50

sgs.ai_skill_discard.jinsanchen = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, include_equip)
end

--破竹
local jinpozhu_skill = {}
jinpozhu_skill.name = "jinpozhu"
table.insert(sgs.ai_skills, jinpozhu_skill)
jinpozhu_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:getMark("jinpozhu_wuxiao-Clear") > 0 then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	
	if self:getUseValue(cards[1]) > sgs.ai_use_value.Chuqibuyi then return end
	
	local suit = cards[1]:getSuitString()
	local number = cards[1]:getNumberString()
	local card_id = cards[1]:getEffectiveId()
	local card_str = ("chuqibuyi:jinpozhu[%s:%s]=%d"):format(suit, number, card_id)
	local chuqibuyi = sgs.Card_Parse(card_str)
	assert(chuqibuyi)
	return chuqibuyi
end
