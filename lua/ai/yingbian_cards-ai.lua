--冰属性伤害效果
sgs.ai_skill_invoke.IceDamagePrevent = function(self, data)
	local damage = self.player:getTag("IceDamageData")
	return sgs.ai_skill_invoke.ice_sword(self, damage)
end

--冰杀
function SmartAI:useCardIceSlash(...)
	self:useCardSlash(...)
end

sgs.ai_card_intention.IceSlash = sgs.ai_card_intention.Slash

sgs.ai_use_value.IceSlash = 4.65
sgs.ai_keep_value.IceSlash = 3.6
sgs.ai_use_priority.IceSlash = 2.5

--洞烛先机
function SmartAI:useCardDongzhuxianji(card, use)
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	local xiahou = self.room:findPlayerBySkillName("yanyu")
	if xiahou and self:isEnemy(xiahou) and xiahou:getMark("YanyuDiscard2") > 0 then return end

	use.card = card
	if not use.isDummy then
		self:speak("lucky")
	end
end

sgs.ai_card_intention.Dongzhuxianji = -80

sgs.ai_keep_value.Dongzhuxianji = 4
sgs.ai_use_value.Dongzhuxianji = 10.1
sgs.ai_use_priority.Dongzhuxianji = 9.4

sgs.dynamic_value.benefit.Dongzhuxianji = true

--出其不意
function SmartAI:useCardChuqibuyi(card, use)
	local same_suit_num = 0
	self:sort(self.enemies, "hp")
	
	local enemies = {}
	for _,enemy in ipairs(self.enemies) do
		if use.current_targets and table.contains(use.current_targets, enemy:objectName()) then continue end
		if self.room:isProhibited(self.player, enemy, card) then continue end
		if not self:hasTrickEffective(card, enemy, self.player) then continue end
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then continue end
		local damage = self:ajustDamage(self.player, enemy)
		if self:cantbeHurt(enemy, self.player, damage) then continue end
		table.insert(enemies, enemy)
	end
	
	if #enemies == 0 then return end
	local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if use.isDummy and use.extra_target then targets_num = targets_num + use.extra_target end
	targets_num = math.min(targets_num, #enemies)
	
	if card:getSuit() == sgs.Card_NoSuit then
		use.card = card
		for i = 1, targets_num do
			if use.to then
				use.to:append(enemies[i])
				if use.to:length() == targets_num then break end
			end
		end
		return
	end
	
	local targets = {}
	for _,enemy in ipairs(enemies) do
		local cards = getKnownCardTable(enemy, self.player, "h", card:getSuit())
		if #cards >= enemy:getHandcardNum() / 2 then continue end
		table.insert(targets, enemy)
	end
	if #targets > 0 then
		use.card = card
		for i = 1, math.min(targets_num, #targets) do
			if use.to then
				use.to:append(targets[i])
			end
		end
	end
end

sgs.ai_use_value.Chuqibuyi = 4.9
sgs.ai_keep_value.Chuqibuyi = 3.4
sgs.ai_use_priority.Chuqibuyi = sgs.ai_use_priority.Dismantlement + 0.2

sgs.dynamic_value.damage_card.Chuqibuyi = true

sgs.ai_card_intention.Chuqibuyi = 80

--逐近弃远
function SmartAI:useCardZhujinqiyuan(card, use)
	local all_distance = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:isProhibited(p, card) or not self:hasTrickEffective(card, p, self.player) then continue end
		local distance = self.player:distanceTo(p)
		if distance >=1 then
			table.insert(all_distance, p)
		end
	end
	if #all_distance == 0 then return end
	
	local targets = self:findPlayerToDiscard("hej", false, false, all_distance, true, "zhujinqiyuan")
	local new_targets = {}
	for _,p in ipairs(targets) do
		if use.current_targets and table.contains(use.current_targets, p:objectName()) then continue end
		table.insert(new_targets, p)
	end
	
	local targets_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if use.isDummy and use.extra_target then targets_num = targets_num + use.extra_target end
	targets_num = math.min(targets_num, #new_targets)
	if targets_num == 0 then return end
	
	use.card = card
	for i = 1, targets_num do
		if use.to then
			use.to:append(new_targets[i])
			if use.to:length() == targets_num then return end
		end
	end
end

sgs.ai_use_value.Zhujinqiyuan = 9
sgs.ai_use_priority.Zhujinqiyuan = 4.3
sgs.ai_keep_value.Zhujinqiyuan = 3.46

sgs.dynamic_value.control_card.Zhujinqiyuan = true

--护心镜
sgs.ai_skill_invoke.huxinjing = true

--太公阴符
sgs.ai_skill_playerchosen.taigongyinfu = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if not self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_cardask["@taigongyinfu-recast"] = function(self, data)
	local hands = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(hands, true)
	local cards = {}
	for _,c in ipairs(hands) do
		if self.player:isCardLimited(c, sgs.Card_MethodRecast, true) then continue end
		table.insert(cards, c)
	end
	if #cards == 0 or self:isValuableCard(cards[1]) then return "." end
	return "$" .. cards[1]:getEffectiveId()
end

--天机图
sgs.ai_skill_discard.tianjitu = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local discards = {}
	for _,c in ipairs(cards) do
		if c:objectName() == "tianjitu" or not self.player:canDiscard(self.player, c:getEffectiveId()) then continue end
		table.insert(discards, c)
	end
	if #discards == 0 then return discards end
	self:sortByKeepValue(discards)
	return {discards[1]:getEffectiveId()}
end

--五行鹤翎扇

--应变效果
--富甲->可使目标-1
sgs.ai_skill_playerchosen.yb_fujia2 = function(self, targets)
	local use = self.player:getTag("yb_fujia2_data"):toCardUse()
	if not use then return nil end
	if use.card:isKindOf("GodSalvation") then
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not targets:contains(enemy) then continue end
			if enemy:isWounded() and self:hasTrickEffective(use.card, enemy, self.player) then
				return enemy
			end
		end
	elseif use.card:isKindOf("AmazingGrace") then
		self:sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not targets:contains(enemy) then continue end
			if self:hasTrickEffective(use.card, enemy, self.player) and not hasManjuanEffect(enemy)
				and not self:needKongcheng(enemy, true) then
				return enemy
			end
		end
	elseif use.card:isKindOf("AOE") then
		self:sort(self.friends_noself)
		local lord = self.room:getLord()
		if lord and lord:objectName() ~= self.player:objectName() and self:isFriend(lord) and self:isWeak(lord) and targets:contains(lord) then
			return lord
		end
		for _, friend in ipairs(self.friends_noself) do
			if not targets:contains(friend) then continue end
			if self:hasTrickEffective(use.card, friend, self.player) then
				return friend
			end
		end
	end
	return nil
end

--助战->依次执行所有选项
-----弃牌待补充-----
--[[
sgs.ai_skill_discard.yb_zhuzhan1 = function(self, discard_num, min_num, optional, include_equip)
	local use = self.player:getTag("yb_zhuzhan_data"):toCardUse()
	if not use then return {} end
end]]

--助战->目标+1
-----弃牌待补充-----
--[[
sgs.ai_skill_discard.yb_zhuzhan2 = function(self, discard_num, min_num, optional, include_equip)
	local use = self.player:getTag("yb_zhuzhan_data"):toCardUse()
	if not use then return {} end
end]]

sgs.ai_skill_playerchosen.yb_zhuzhan2 = function(self, targets)
	local use = self.player:getTag("yb_zhuzhan2_data"):toCardUse()
	if not use then return nil end
	
	if use.card:isKindOf("Peach") then
		self:sort(self.friends_noself, "hp")
		for _, friend in ipairs(self.friends_noself) do
			if not targets:contains(friend) then continue end
			if friend:isWounded() and friend:getHp() < getBestHp(friend) then
				return friend
			end
		end
	elseif use.card:isKindOf("ExNihilo") or use.card:isKindOf("Dongzhuxianji") then
		local friends = self:findPlayerToDraw(false, 2, #self.friends_noself)
		if #friends > 0 then
			for _,p in ipairs(friends) do
				if not self:hasTrickEffective(card, p, self.player) or not targets:contains(p) then continue end
				return p
			end
		end
	elseif use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardSnatchOrDismantlement(use.card, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			return dummy_use.to:first()
		end
	elseif use.card:isKindOf("Slash") then
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardSlash(use.card, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			return dummy_use.to:first()
		end
	else
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardByClassName(use.card, dummy_use)
		if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
			return dummy_use.to:first()
		end
	end
	return nil
end

--空巢->目标+1
sgs.ai_skill_playerchosen.yb_kongchao3 = function(self, targets)
	local data = self.player:getTag("yb_kongchao3_data")
	if not data then return nil end
	
	self.player:setTag("yb_zhuzhan2_data", data)
	local target = sgs.ai_skill_playerchosen.yb_zhuzhan2(self, targets)
	self.player:removeTag("yb_zhuzhan2_data")
	
	return target
end

--残躯->目标+1
sgs.ai_skill_playerchosen.yb_canqu2 = function(self, targets)
	local data = self.player:getTag("yb_canqu2_data")
	if not data then return nil end
	
	self.player:setTag("yb_zhuzhan2_data", data)
	local target = sgs.ai_skill_playerchosen.yb_zhuzhan2(self, targets)
	self.player:removeTag("yb_zhuzhan2_data")
	
	return target
end
