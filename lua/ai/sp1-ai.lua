--鼓舌
local gushe_skill={}
gushe_skill.name="gushe"
table.insert(sgs.ai_skills,gushe_skill)
gushe_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("GusheCard") then return end
	local card = self:getMaxCard()
	if not card then return end
	if card:getNumber() <= 11 and self.player:getMark("&raoshe") >= 6 then return end
	if card:getNumber() <= 6 then return end
	for _, enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) then
			return sgs.Card_Parse("@GusheCard=.")
		end
	end
end

sgs.ai_skill_use_func.GusheCard = function(card, use, self)
	local max_card = self:getMaxCard()
	if not max_card then return end
	self.gushe_card = max_card:getEffectiveId()
	self:sort(self.enemies, "handcard")
	local tos = sgs.SPlayerList()
	local mark = self.player:getMark("&raoshe")
	for _, enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) and not self:doNotDiscard(enemy, "e") then
			if tos:length() < math.max(1, math.min(3, 6 - mark)) then
				tos:append(enemy)
			end
		end
	end
	if tos:isEmpty() then return end
	use.card = card
	if use.to then use.to = tos end
end

sgs.ai_use_value.GusheCard = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_card_intention.GusheCard = 80

function sgs.ai_skill_pindian.gushe(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_skill_discard.gushe = function(self, discard_num, min_num, optional, include_equip)
	local source = self.player:getTag("gusheDiscard"):toPlayer()
	if not source then return {} end
	if self:isFriend(source) then return {} end
	local to_discard = self:askForDiscard("dummy", 1, 1, false, true)
	if #to_discard > 0 then return {to_discard[1]} end
	return {}
end

--激词
sgs.ai_skill_invoke.jici = function(self,data)
	return true
end

--十周年鼓舌
local tenyeargushe_skill={}
tenyeargushe_skill.name="tenyeargushe"
table.insert(sgs.ai_skills,tenyeargushe_skill)
tenyeargushe_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getMark("tenyeargushe_pindian_win-Clear") >= 7 - self.player:getMark("&raoshe") then return end
	local card = self:getMaxCard()
	if not card then return end
	if card:getNumber() <= 11 and self.player:getMark("&raoshe") >= 6 then return end
	if card:getNumber() <= 6 then return end
	for _, enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) then
			return sgs.Card_Parse("@TenyearGusheCard=.")
		end
	end
end

sgs.ai_skill_use_func.TenyearGusheCard = function(card, use, self)
	local max_card = self:getMaxCard()
	if not max_card then return end
	self.tenyeargushe_card = max_card:getEffectiveId()
	self:sort(self.enemies, "handcard")
	local tos = sgs.SPlayerList()
	local mark = self.player:getMark("&raoshe")
	for _, enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) and not self:doNotDiscard(enemy, "e") then
			if tos:length() < math.max(1, math.min(3, 6 - mark)) then
				tos:append(enemy)
			end
		end
	end
	if tos:isEmpty() then return end
	use.card = card
	if use.to then use.to = tos end
end

sgs.ai_use_value.TenyearGusheCard = sgs.ai_use_value.GusheCard
sgs.ai_card_intention.TenyearGusheCard = sgs.ai_card_intention.GusheCard

function sgs.ai_skill_pindian.tenyeargushe(minusecard, self, requestor)
	return sgs.ai_skill_pindian.gushe(minusecard, self, requestor)
end

sgs.ai_skill_discard.tenyeargushe = function(self, discard_num, min_num, optional, include_equip)
	local source = self.player:getTag("tenyeargusheDiscard"):toPlayer()
	if not source then return {} end
	if self:isFriend(source) then return {} end
	local to_discard = self:askForDiscard("dummy", 1, 1, false, true)
	if #to_discard > 0 then return {to_discard[1]} end
	return {}
end

--十周年激词
sgs.ai_skill_discard.tenyearjici = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, include_equip)
end

function sgs.ai_slash_prohibit.tenyearjici(self, from, to)
	if hasJueqingEffect(from, to) or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
	if from:isLord() and self:isWeak(from) then return true end
	if self.room:getLord() and from:getRole() == "renegade" then return true end
	return false
end

--清忠
sgs.ai_skill_invoke.qingzhong = function(self, data)
	local num = self.room:getOtherPlayers(self.player):first():getHandcardNum()
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		num = math.min(num, p:getHandcardNum())
	end
	
	local crossbow = false
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Crossbow") and self.player:canUse(c) then
			crossbow = true
			break
		end
	end
	
	local use, slash, analeptic = 0, false, 0
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if not self:willUse(self.player, c) then continue end
		if c:isKindOf("Slash") and not slash then
			slash = true
			use = use + 1
		elseif c:isKindOf("Slash") and slash then
			if self.player:canSlashWithoutCrossbow() or self.player:hasWeapon("crossbow") or crossbow then
				use = use + 1
			end
		elseif c:isKindOf("Analeptic") then
			analeptic = analeptic + 1
			if analeptic <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, c, self.player) then
				use = use + 1
			end
		else
			use = use + 1
		end
	end
	return self.player:getHandcardNum() + 2 - use <= num
end

sgs.ai_skill_playerchosen.qingzhong = function(self, targets)
	local selfhand, targethand = self.player:getHandcardNum(), targets:first():getHandcardNum()
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if self:doNotDiscard(p, "h") then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		return p
	end
	for _,p in ipairs(targets) do
		if not self:isEnemy(p) and not self:doNotDiscard(p, "h") then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if not self:isEnemy(p) then
			return p
		end
	end
	return targets[math.random(1, #targets)]
end

--卫境
local weijing_skill = {}
weijing_skill.name = "weijing"
table.insert(sgs.ai_skills, weijing_skill)
weijing_skill.getTurnUseCard = function(self, inclusive)
	if sgs.Slash_IsAvailable(self.player) and self.player:getMark("weijing_lun") == 0 then
		local card_str = string.format("slash:weijing[%s:%s]=.", "no_suit", 0)
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end
end

sgs.ai_cardsview_valuable.weijing = function(self, class_name, player)
	if player:getMark("weijing_lun") > 0 or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end
	if class_name == "Slash" then
		return string.format("slash:weijing[%s:%s]=.", "no_suit", 0)
	elseif class_name == "Jink" then
		return string.format("jink:weijing[%s:%s]=.", "no_suit", 0)
	end
end

--膂力
sgs.ai_skill_invoke.lvli = function(self, data)
	if self.player:getHp() > self.player:getHandcardNum() and self:canDraw(self.player) then return true end
	if self.player:getHp() < self.player:getHandcardNum() and self.player:getLostHp() > 0 then return true end
	return false
end

--清剿
sgs.ai_skill_invoke.qingjiao = function(self, data)
	if self.player:hasWeapon("cross_bow") or self.player:hasWeapon("vscrossbow") or self.player:canSlashWithoutCrossbow() or self:getCardsNum("Crossbow") > 0 or
		self:getCardsNum("VSCrossbow") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, true) and not self:slashProhibit(nil, enemy)
				and (self:getCardsNum("Slash") - enemy:getHp() >= 1 or self:getCardsNum("Slash") >= 3) then
				return false
			end
		end
	end
	local damage_cards_num = 0
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isDamageCard() and not c:isKindOf("DelayedTrick") and not c:isKindOf("Slash") then
			damage_cards_num = damage_cards_num + 1
		end
	end
	local valuable_cards_num = self:getCardsNum("Duel") + self:getCardsNum("SavageAssault") + self:getCardsNum("ArcheryAttack")
							 + self:getCardsNum("Snatch") + self:getCardsNum("Dismantlement")
	if self.player:getCards("h"):length() >= 7 then
		return not (damage_cards_num >= 2 or self.player:getLostHp() >= self:getCardsNum("Peach") or valuable_cards_num >= 3)
	end
	return true
end

--伪诚
sgs.ai_skill_invoke.weicheng = function(self, data)
	return self:canDraw(self.player)
end

--盗书
local daoshu_skill= {}
daoshu_skill.name = "daoshu"
table.insert(sgs.ai_skills, daoshu_skill)
daoshu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("DaoshuCard") then return end
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("@DaoshuCard=.")
end

sgs.ai_skill_use_func.DaoshuCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") then 
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_skill_cardask["daoshu-give"] = function(self, data)
	local list = data:toStringList()
	local to = self.room:findPlayerByObjectName(list[1])
	local suitstring = list[2]
	if not to or to:isDead() then return "." end
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:getSuitString() == suitstring then continue end
		table.insert(cards, c)
	end
	if #cards == 0 then return "." end
	self:sortByUseValue(cards, true)
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_use_value.DaoshuCard = 8
sgs.ai_use_priority.DaoshuCard = 5.3

--持节

--引裾

--谦冲
sgs.ai_skill_choice.qianchong = function(self, choices, data)
	if self:getCardsNum("Slash") < 2 or self.player:hasWeapon("cross_bow") or self.player:hasWeapon("vscrossbow") or self.player:canSlashWithoutCrossbow() or
		self:getCardsNum("Crossbow") > 0 or self:getCardsNum("VSCrossbow") > 0 then
		local choose_trick = true
		for _,enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, true) and not self:slashProhibit(slash, enemy) then
				choose_trick = false
				break
			end
		end
		if choose_trick then
			for _,c in sgs.qlist(self.player:getCards("h")) do
				if c:isKindOf("Snatch") or c:isKindOf("SupplyShortage") then  --需要判断本来是不是就是无距离限制，待补充
					return "trick"
				end
			end
		end
	end
	return "basic"
end

--尚俭
sgs.ai_skill_invoke.shangjian = function(self, data)
	return self:canDraw(self.player)
end

--怠攻
sgs.ai_skill_invoke.daigong = function(self, data)
	local from = data:toPlayer()
	if not from or from:isDead() then return false end
	if not self:isFriend(from) and from:getArmor() and self:needToThrowArmor(from) and (not self:isWeak() or self:getCardsNum("Peach") > 0) then
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if c:getSuit() == from:getArmor():getSuit() then
				return true
			end
		end
		return false
	end
	return true
end

sgs.ai_skill_cardask["daigong-give"] = function(self, data)
	local list = data:toStringList()
	local to = self.room:findPlayerByObjectName(list[1])
	local suitstring = list[2]
	if not to or to:isDead() or self:isFriend(to) then return "." end
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if not string.find(suitstring, c:getSuitString()) then continue end
		table.insert(cards, c)
	end
	if #cards == 0 then return "." end
	self:sortByUseValue(cards, true)
	return "$" .. cards[1]:getEffectiveId()
end

--昭心
local spzhaoxin_skill = {}
spzhaoxin_skill.name = "spzhaoxin"
table.insert(sgs.ai_skills, spzhaoxin_skill)
spzhaoxin_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isNude() and not self.player:hasUsed("SpZhaoxinCard") and self.player:getPile("zxwang"):length() < 3 then
		return sgs.Card_Parse("@SpZhaoxinCard=.")
	end
end

sgs.ai_skill_use_func.SpZhaoxinCard = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(zcard, dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { isDummy = true }
					self:useTrickCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end

	for index = #unpreferedCards, 1, -1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if #use_cards >= 3 - self.player:getPile("zxwang"):length() then break end
		table.insert(use_cards, unpreferedCards[index])
	end

	if #use_cards > 0 then
		use.card = sgs.Card_Parse("@SpZhaoxinCard=" .. table.concat(use_cards, "+"))
		return
	end
end

sgs.ai_use_priority.SpZhaoxinCard = 9
sgs.ai_use_value.SpZhaoxinCard = 2.61

sgs.ai_skill_use["@@spzhaoxin"] = function(self, prompt, method)
	local name = prompt:split(":")[2]
	if not name then return "." end
	local current = self.room:findPlayerByObjectName(name)
	if not current or current:isDead() or not self:isFriend(current) then return "." end
	local wang = {}
	for _,id in sgs.qlist(self.player:getPile("zxwang")) do
		table.insert(wang, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(wang)
	return "@SpZhaoxinChooseCard=" .. wang[1]:getEffectiveId()
end

sgs.ai_skill_invoke.spzhaoxin = function(self, data)
	local str = data:toString()
	str = str:split(":")
	if str[1] == "spzhaoxin_get" then
		local name = str[#str]
		local player = self.room:findPlayerByObjectName(name)
		if player and player:isAlive() and self:isFriend(player) then return true end
		if not self:isFriend(player) and self:needToLoseHp(self.player, player) then return true end
		
		local id = str[2]
		if not id or tonumber(id) < 0 then return false end
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") or (not self:isWeak() and card:isKindOf("ExNihilo")) then return true end
		return false
	elseif str[1] == "spzhaoxin_damage" then
		local name = str[2]
		local player = self.room:findPlayerByObjectName(name)
		if not player or player:isDead() then return false end
		if not self:isFriend(player) and self:needToLoseHp(player, self.player) then return false end
		if self:isFriend(player) and not self:needToLoseHp(player, self.player) then return false end
		return true
	end
	return false
end

--忠佐
sgs.ai_skill_playerchosen.zhongzuo = function(self, targets)
	self:updatePlayers()
	self:sort(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if not self:canDraw(friend) then continue end
		if (friend:getHandcardNum() + (friend:isWounded() and -2 or 1)) < (self.player:getHandcardNum() + (self.player:isWounded() and -2 or 0)) then
			return friend
		end
	end
	if self:canDraw(self.player) then return self.player end
	return nil
end

--挽澜
sgs.ai_skill_invoke.wanlan = function(self, data)
	local who = data:toPlayer()
	local current = self.room:getCurrent()
	if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return self:isFriend(who) end
	if not self:isFriend(who) then return false end
	if self.player:getHandcardNum() > ((self:isEnemy(current) and self:isWeak(current)) and 6 or 4)
		or self:getCardsNum("Peach") > ((self:isEnemy(current) and self:isWeak(current)) and 1 or 0) then return false end
	return true
end

--通渠
sgs.ai_skill_playerchosen.tongqu = function(self, targets)
	if self:isWeak() then return nil end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends, p)
		end
	end
	if #friends <= 0 then return nil end
	self:sort(friends, "handcard")
	return friends[1]
end

sgs.ai_skill_use["@@tongqu!"] = function(self, prompt, method)
	local friends = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) then
			table.insert(friends, p)
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #friends > 0 then
		self:sort(friends, "handcard")
		if self:needToThrowArmor() then return "@TongquCard=" .. self.player:getArmor():getEffectiveId() .. "->" .. friends[1]:objectName() end
		self:sortByUseValue(cards, true)
		return "@TongquCard=" .. cards[1]:getEffectiveId() .. "->" .. friends[1]:objectName()
	end
	self:sortByKeepValue(cards)
	return "@TongquCard=" .. cards[1]:getEffectiveId()
end

--新挽澜
sgs.ai_skill_invoke.newwanlan = function(self, data)
	local who = data:toPlayer()
	return self:isFriend(who) and not hasBuquEffect(who)
end

--推演
sgs.ai_skill_invoke.tuiyan = true

--卜算
local busuan_skill = {}
busuan_skill.name = "busuan"
table.insert(sgs.ai_skills, busuan_skill)
busuan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("BusuanCard") then return end
	self.busuan_target = nil
	if #self.friends_noself > 0 then
		self:sort(self.friends_noself, "hp")
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) and friend:getLostHp() > 0 then
				self.busuan_target = friend
				return sgs.Card_Parse("@BusuanCard=.")
			end
		end
	end
	if #self.enemies > 0 then
		self:sort(self.enemies, "defense")
		self.busuan_target = self.enemies[1]
		return sgs.Card_Parse("@BusuanCard=.")
	end
	return
end

sgs.ai_skill_use_func.BusuanCard = function(card, use, self)
	if not self.busuan_target then return end
	use.card = card
	if use.to then use.to:append(self.busuan_target) end
end

sgs.ai_skill_askforag.busuan = function(self, card_ids)
	if not self.busuan_target then return card_ids[1] end
	local cards = {}
	for _,id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getEngineCard(id))
	end
	self:sortByUseValue(cards, not self:isFriend(self.busuan_target))
	
	if self:isWeak(self.busuan_target) and self.busuan_target:getLostHp() > 0 and self:isFriend(self.busuan_target) then
		for _,c in ipairs(cards) do
			if c:isKindOf("Peach") then
				return c:getEffectiveId()
			end
		end
	end
	return cards[1]:getEffectiveId()
end

--命戒
sgs.ai_skill_invoke.mingjie = function(self, data)  --就写个全作弊ai吧
	if self.room:getDrawPile():isEmpty() then return false end
	local card = sgs.Sanguosha:getCard(self.room:getDrawPile():first())
	if card:isRed() or (self.player:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade) then return self:canDraw() end
	return false
end

--遣信
local spqianxin_skill = {}
spqianxin_skill.name = "spqianxin"
table.insert(sgs.ai_skills, spqianxin_skill)
spqianxin_skill.getTurnUseCard = function(self, inclusive)
	if self.room:getDrawPile():length() < self.room:alivePlayerCount() then return end
	if self.player:getMark("spqianxin_disabled") == 0 and #self.enemies > 0 and not self.player:isKongcheng() then
		return sgs.Card_Parse("@SpQianxinCard=.")
	end
end

sgs.ai_skill_use_func.SpQianxinCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = {}
	self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		if (c:isKindOf("Jink") and self:getCardsNum("Jink") > 1) or c:isKindOf("Lightning") or c:isKindOf("AmazingGrace") or c:isKindOf("GodSalvation") then
			table.insert(use_card, c:getEffectiveId())
		end
	end
	if #use_card == 0 then return end
	use.card = sgs.Card_Parse("@SpQianxinCard=" .. use_card[1])
	if use.to then use.to:append(self.enemies[1]) end
end

sgs.ai_use_priority.SpQianxinCard = 3
sgs.ai_use_value.SpQianxinCard = 3
sgs.ai_card_intention.SpQianxinCard = 50

sgs.ai_skill_choice.spqianxin = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) or not self:canDraw(target) then
			return "draw"
		else
			if self.player:getMaxCards() - self.player:getHandcardNum() >= 2 then
				return "maxcards"
			end
		end
	end
	return items[1]
end

--镇行
sgs.ai_skill_invoke.zhenxing = function(self, data)
	return self:canDraw()
end

sgs.ai_skill_choice.zhenxing = function(self, choices)
	return "3"
end

--手杀遣信
local mobilespqianxin_skill = {}
mobilespqianxin_skill.name = "mobilespqianxin"
table.insert(sgs.ai_skills, mobilespqianxin_skill)
mobilespqianxin_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isKongcheng() and not self.player:hasUsed("MobileSpQianxinCard") then
		return sgs.Card_Parse("@MobileSpQianxinCard=.")
	end
end

sgs.ai_skill_use_func.MobileSpQianxinCard = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(handcards)
	local cards = {}
	local maxnum = math.min(2, self.room:getOtherPlayers(self.player):length())
	for _, c in ipairs(handcards) do
		if not (c:isKindOf("Peach") or c:isKindOf("Nullification") or (c:isKindOf("Analeptic") and #self.friends_noself < #self.enemies)) then
			table.insert(cards, c:getEffectiveId())
		end
		if #cards >= maxnum then break end
	end
	if #cards == 0 then return end
	use.card = sgs.Card_Parse("@MobileSpQianxinCard=" .. table.concat(cards, "+"))
end

sgs.ai_use_priority.MobileSpQianxinCard = 3
sgs.ai_use_value.MobileSpQianxinCard = 3
sgs.ai_card_intention.MobileSpQianxinCard = 50

sgs.ai_skill_choice.mobilespqianxin = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) or not self:canDraw(target) then
			return "draw"
		else
			local fixed = math.max(self.player:getMaxCards() - 2, 0)
			if ((fixed > 0 and self:isEnemy(target)) and self.player:getHandcardNum() - fixed <= 3 or self.player:getHandcardNum() - fixed <= 1)
				and not self:isWeak() then
				return "maxcards"
			end
		end
	end
	return items[1]
end

--手杀镇行
sgs.ai_skill_invoke.mobilezhenxing = function(self, data)
	return self:canDraw()
end

--机捷
local jijie_skill = {}
jijie_skill.name = "jijie"
table.insert(sgs.ai_skills, jijie_skill)
jijie_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("JijieCard") then
		return sgs.Card_Parse("@JijieCard=.")
	end
end

sgs.ai_skill_use_func.JijieCard = function(card, use, self)
	use.card = card
end

sgs.ai_skill_askforyiji.jijie = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end

sgs.ai_use_priority.JijieCard = 7
sgs.ai_use_value.JijieCard = 7
sgs.ai_playerchosen_intention.jijie = -20

--急援
sgs.ai_skill_invoke.jiyuan = function(self, data)
	local current_dying_player = self.room:getCurrentDyingPlayer()
	local to = data:toPlayer()
	if current_dying_player then
		if self:isFriend(current_dying_player) and self:canDraw(current_dying_player) then
			return true
		end
	end
	if to then
		if self:isFriend(to) and self:canDraw(to) then
			return true
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.jiyuan = function(self, player, promptlist)
	local current_dying_player = self.room:getCurrentDyingPlayer()
	if current_dying_player then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, current_dying_player, -80)
		else
			sgs.updateIntention(player, current_dying_player, 80)
		end
	end
end

--资援

--秉正
sgs.ai_skill_playerchosen.bingzheng = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	local tag = sgs.QVariant()
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			if p:getHandcardNum() + 1 == p:getHp() and self:canDraw(p) then
				sgs.ai_skill_choice.bingzheng = "draw"
				tag:setValue(p)
				self.player:setTag("bingzheng_forAI", tag)
				return p
			end
		elseif self:isEnemy(p) and p:getHandcardNum() > 0 and not self:doNotDiscard(p, "h") then
			if p:getHandcardNum() - 1 == p:getHp() then
				sgs.ai_skill_choice.bingzheng = "discard"
				tag:setValue(p)
				self.player:setTag("bingzheng_forAI", tag)
				return p
			end
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getHandcardNum() > 0 and not self:doNotDiscard(p, "h") then
			sgs.ai_skill_choice.bingzheng = "discard"
			tag:setValue(p)
			self.player:setTag("bingzheng_forAI", tag)
			return p
		elseif self:isFriend(p) and self:canDraw(p) then
			sgs.ai_skill_choice.bingzheng = "draw"
			tag:setValue(p)
			self.player:setTag("bingzheng_forAI", tag)
			return p
		end
	end
	return nil
end

sgs.ai_choicemade_filter.skillChoice.bingzheng = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target = player:getTag("bingzheng_forAI"):toPlayer()
	self.player:removeTag("bingzheng_forAI")
	if target then
		if choice == "discard" then
			sgs.updateIntention(player, target, 80)
		elseif choice == "draw" then
			sgs.updateIntention(player, target, -80)
		end
	end
end

sgs.ai_skill_askforyiji.bingzheng = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end

--舍宴
sgs.ai_skill_choice.sheyan = function(self, choices, data)
	local use = data:toCardUse()
	choices = choices:split("+")
	self.sheyan_extra_target = nil
	self.sheyan_remove_target = nil
	local players = sgs.PlayerList()
	
	if use.card:isKindOf("Collateral") then
		if table.contains(choices, "add") then
			local dummy_use = { isDummy = true, from = use.from, to = sgs.SPlayerList(), current_targets = {} }
			table.insert(dummy_use.current_targets, use.from:objectName())  --ai还是可以把use.from选择为额外目标，所以这么处理
			for _, p in sgs.qlist(use.to) do
				table.insert(dummy_use.current_targets, p:objectName())
			end
			self:useCardCollateral(use.card, dummy_use)
			if dummy_use.card and dummy_use.to:length() == 2 then
				local first = dummy_use.to:at(0):objectName()
				local second = dummy_use.to:at(1):objectName()
				self.sheyan_collateral = { first, second }
				return "add"
			else
				self.sheyan_collateral = nil
			end
		elseif table.contains(choices, "remove") then
			self.sheyan_remove_target = self.player
			return "remove"
		end
	elseif use.card:isKindOf("ExNihilo") or use.card:isKindOf("Dongzhuxianji") then
		if table.contains(choices, "add") then
			self:sort(self.friends_noself, "defense")
			for _,friend in ipairs(self.friends_noself) do
				if use.to:contains(friend) or self.room:isProhibited(use.from, friend, use.card) or not self:canDraw(friend) or
					not self:hasTrickEffective(use.card, friend, use.from) then continue end
				self.sheyan_extra_target = friend
				return "add"
			end
		end
	elseif use.card:isKindOf("GodSalvation") then
		if table.contains(choices, "remove") then
			self:sort(self.enemies, "hp")
			for _, enemy in ipairs(self.enemies) do
				if use.to:contains(enemy) and enemy:isWounded() and self:hasTrickEffective(use.card, enemy, use.from) then
					self.sheyan_remove_target = enemy
					return "remove"
				end
			end
		end
	elseif use.card:isKindOf("AmazingGrace") then
		if table.contains(choices, "remove") then
			self:sort(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if use.to:contains(enemy) and self:hasTrickEffective(use.card, enemy, use.from) and not hasManjuanEffect(enemy)
					and not self:needKongcheng(enemy, true) then
					self.sheyan_remove_target = enemy
					return "remove"
				end
			end
		end
	elseif use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") then
		if table.contains(choices, "remove") then
			self:sort(self.friends)
			local lord = self.room:getLord()
			if lord and use.to:contains(lord) and lord:objectName() ~= self.player:objectName() and self:isFriend(lord) and self:isWeak(lord) and
				self:hasTrickEffective(use.card, lord, use.from) then
				self.sheyan_remove_target = lord
				return "remove"
			end
			for _, friend in ipairs(self.friends) do
				if use.to:contains(friend) and self:hasTrickEffective(use.card, friend, use.from) then
					self.sheyan_remove_target = friend
					return "remove"
				end
			end
		end
	elseif use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
		self:sort(self.friends_noself, "defense")
		self:sort(self.enemies, "defense")
		if table.contains(choices, "add") then
			if self:isFriend(use.from) then
				for _, friend in ipairs(self.friends_noself) do
					if use.to:contains(friend) or not self:hasTrickEffective(use.card, friend, use.from) or self.room:isProhibited(use.from, friend, use.card) then continue end
					if friend:getJudgingArea():isEmpty() or friend:containsTrick("YanxiaoCard") or not self:needToThrowArmor(friend) or
						(use.card:isKindOf("Dismantlement") and not use.from:canDiscard(friend, friend:getArmor():getEffectiveId())) then continue end
					if not use.card:targetFilter(players, friend, use.from) then continue end
					self.sheyan_extra_target = friend
					return "add"
				end
				for _, enemy in ipairs(self.enemies) do
					if use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) or self.room:isProhibited(use.from, enemy, use.card) then continue end
					if not use.card:targetFilter(players, enemy, use.from) or self:doNotDiscard(enemy, "he") then continue end
					self.sheyan_extra_target = enemy
					return "add"
				end
			else
				for _, friend in ipairs(self.friends_noself) do
					if use.to:contains(friend) or not self:hasTrickEffective(use.card, friend, use.from) or self.room:isProhibited(use.from, friend, use.card) then continue end
					if not use.card:targetFilter(players, friend, use.from) then continue end
					if use.card:isKindOf("Snatch") and not friend:isNude() then continue end
					if use.card:isKindOf("Dismantlement") then
						local candis = false
						for _,c in sgs.qlist(friend:getCards("he")) do
							if c:isKindOf("Armor") then continue end
							if use.from:canDiscard(friend, c:getEffectiveId()) then
								candis = true
								break
							end
						end
						if candis then continue end
					end
					if not friend:getJudgingArea():isEmpty() and not friend:containsTrick("YanxiaoCard") then
						self.sheyan_extra_target = friend
						return "add"
					elseif self:needToThrowArmor(friend) and (not use.card:isKindOf("Dismantlement") or use.from:canDiscard(friend, friend:getArmor():getEffectiveId())) then
						self.sheyan_extra_target = friend
						return "add"
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) then continue end
					if not use.card:targetFilter(players, enemy, use.from) or self:doNotDiscard(enemy, "he") then continue end
					self.sheyan_extra_target = enemy
					return "add"
				end
			end
		elseif table.contains(choices, "remove") then
			if not self:isFriend(use.from) then
				for _, enemy in ipairs(self.enemies) do
					if not use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) then continue end
					if not self:doNotDiscard(enemy, "he") or not enemy:getJudgingArea():isEmpty() then continue end
					self.sheyan_remove_target = enemy
					return "remove"
				end
				for _, friend in ipairs(self.friends_noself) do
					if not use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) then continue end
					if friend:isNude() and friend:containsTrick("YanxiaoCard") then
						self.sheyan_remove_target = friend
						return "remove"
					end
				end
			end
			for _, friend in ipairs(self.friends_noself) do
				if not use.to:contains(friend) or not self:hasTrickEffective(use.card, friend, use.from) then continue end
				if friend:isNude() or self:doNotDiscard(friend, "he") then continue end
				self.sheyan_remove_target = friend
				return "remove"
			end
		end
	elseif use.card:isKindOf("FireAttack") then
		if table.contains(choices, "add") then
			self:sort(self.enemies, "hp")
			for _, enemy in ipairs(self.enemies) do
				if use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) or self.room:isProhibited(use.from, enemy, use.card) then continue end
				if not use.card:targetFilter(players, enemy, use.from) or not self:damageIsEffective(enemy, sgs.DamageStruct_Fire, use.from) then continue end
				self.sheyan_extra_target = enemy
				return "add"
			end
			for _, enemy in ipairs(self.enemies) do
				if use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) or self.room:isProhibited(use.from, enemy, use.card) then continue end
				if not use.card:targetFilter(players, enemy, use.from) then continue end
				self.sheyan_extra_target = enemy
				return "add"
			end
		end
	elseif use.card:isKindOf("IronChain") then
		if table.contains(choices, "remove") then
			local tos = sgs.QList2Table(use.to)
			self:sort(tos, "defense")
			for _,p in ipairs(tos) do
				if not self:hasTrickEffective(use.card, p, use.from) then continue end
				if self:isFriend(p) and not p:isChained() and not p:hasSkill("qianjie") then
					self.sheyan_remove_target = p
					return "remove"
				elseif self:isEnemy(p) and p:isChained() and not p:hasSkill("jieying") then
					self.sheyan_remove_target = p
					return "remove"
				end
			end
		elseif table.contains(choices, "add") then
			self:sort(self.friends_noself, "defense")
			for _,friend in ipairs(self.friends_noself) do
				if use.to:contains(friend) or not self:hasTrickEffective(use.card, friend, use.from) or self.room:isProhibited(use.from, friend, use.card) then continue end
				if friend:isChained() and not enemy:hasSkill("jieying") then
					self.sheyan_extra_target = friend
					return "add"
				end
			end
			self:sort(self.enemies, "defense")
			for _,enemy in ipairs(self.enemies) do
				if use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) or self.room:isProhibited(use.from, enemy, use.card) then continue end
				if not enemy:isChained() and not enemy:hasSkill("qianjie") then
					self.sheyan_extra_target = enemy
					return "add"
				end
			end
		end
	elseif use.card:isKindOf("Duel") then
		if table.contains(choices, "add") then
			self:sort(self.enemies, "hp")
			for _,enemy in ipairs(self.enemies) do
				if use.to:contains(enemy) or not self:hasTrickEffective(use.card, enemy, use.from) or self.room:isProhibited(use.from, enemy, use.card) then continue end
				if not use.card:targetFilter(players, enemy, use.from) then continue end
				self.sheyan_extra_target = enemy
				return "add"
			end
		end
	else
		
	end
	return "cancel"
end

sgs.ai_skill_playerchosen.sheyan = function(self, targets)
	if not self.sheyan_extra_target and not self.sheyan_remove_target then self.room:writeToConsole("sheyan player chosen error!!") end
	return self.sheyan_extra_target or self.sheyan_remove_target
end

sgs.ai_skill_use["@@sheyan!"] = function(self, prompt) -- extra target for Collateral
	if not self.sheyan_collateral then self.room:writeToConsole("sheyan player chosen error!!") end
	return "@ExtraCollateralCard=.->" .. self.sheyan_collateral[1] .. "+" .. self.sheyan_collateral[2]
end

--抚蛮
local fuman_skill = {}
fuman_skill.name = "fuman"
table.insert(sgs.ai_skills, fuman_skill)
fuman_skill.getTurnUseCard = function(self, inclusive)
	if #self.friends_noself > 0 then
		return sgs.Card_Parse("@FumanCard=.")
	end
end

sgs.ai_skill_use_func.FumanCard = function(card, use, self)
	local handcards = self.player:getHandcards()
    local slashs = {}
    for _,c in sgs.qlist(handcards) do
        if c:isKindOf("Slash") then
			table.insert(slashs, c)
        end
    end
    if #slashs == 0 then return end
    self:sortByUseValue(slashs)
	
    self:sort(self.friends_noself, "handcard")
	for _,p in ipairs(self.friends_noself) do
        if p:getMark("fuman_target-PlayClear") == 0 and not self:needKongcheng(p, true) and not self:willSkipPlayPhase(p) and not hasManjuanEffect(p) then
			use.card = sgs.Card_Parse("@FumanCard=" .. slashs[1]:getEffectiveId())
			if use.to then
				use.to:append(p)
			end
			return
        end
    end
end

sgs.ai_use_priority.FumanCard = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value.FumanCard = 4
 
sgs.ai_card_intention.FumanCard = function(self,card, from, tos)
    local to = tos[1]
    local intention = -70
    if hasManjuanEffect(to) then
        intention = 0
    elseif self:needKongcheng(to, true) then
        intention = 0
    end
    sgs.updateIntention(from, to, intention)
end

--图南
local tunan_skill = {}
tunan_skill.name = "tunan"
table.insert(sgs.ai_skills, tunan_skill)
tunan_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("TunanCard") and #self.friends_noself > 0 then
		return sgs.Card_Parse("@TunanCard=.")
	end
end

sgs.ai_skill_use_func.TunanCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "defense")
	self:sort(self.enemies, "defense")
	local targets = {}
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for i = #self.friends_noself, 1, -1 do
		for _,enemy in ipairs(self.enemies) do
			if self.friends_noself[i]:canSlash(enemy, slash, true) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
				use.card = card
				if use.to then
					use.to:append(self.friends_noself[i])
				end
				return
			end
		end
	end
	if #self.friends_noself > 0 then
		use.card = card
		if use.to then
			use.to:append(self.friends_noself[#self.friends_noself])
		end
	end
end

sgs.ai_use_priority.TunanCard = 3
sgs.ai_use_value.TunanCard = 3
sgs.ai_card_intention.TunanCard = -80

sgs.ai_skill_choice.tunan = function(self, choices, data)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local card = data:toCard()
	if card:targetFixed() then
		if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
			local equip_index = card:getRealCard():toEquipCard():location()
			if self.player:getEquip(equip_index) == nil and self.player:canUse(card) then
				return "use"
			end
		end
		if card:isKindOf("AOE") then
			if self:getAoeValue(card) > 0 then
				return "use"
			end
		end
		if card:isKindOf("Peach") and self.player:getLostHp() > 0 then
			return "use"
		end
		if card:isKindOf("ExNihilo") and self:hasTrickEffective(card, self.player, self.player) then
			return "use"
		end
	else
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardByClassName(card, dummyuse)
		if not dummyuse.to:isEmpty() then
			return "use"
		end
	end

	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:addSubcard(card)
	slash:setSkillName("_tunan")
	slash:deleteLater()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		return "slash"
	end
	return "use"
end

sgs.ai_skill_use["@@tunan1!"] = function(self, prompt)
	local id = self.player:getMark("tunan_id-PlayClear") - 1
	if id < 0 then return "." end
	local card = sgs.Sanguosha:getEngineCard(id)
	if card:targetFixed() then
		return card:toString()
	else
		local targets = {}
		if card:isKindOf("Slash") then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
			self:useCardSlash(card, dummy_use)
			if dummy_use.card and dummy_use.to:length() > 0 then
				for _,p in sgs.qlist(dummy_use.to) do
					table.insert(targets, p:objectName())
				end
				return card:toString() .. "->" .. table.concat(targets, "+")
			end
		end
		local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardByClassName(card, dummy_use)
		if dummy_use.card and not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, p:objectName())
			end
			if #targets > 0 then
				return card:toString() .. "->" .. table.concat(targets, "+")
			end
		end
	end
	return "."
end

sgs.ai_skill_use["@@tunan2!"] = function(self, prompt)
	local id = self.player:getMark("tunan_id-PlayClear") - 1
	if id < 0 then return "." end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:addSubcard(id)
	slash:setSkillName("_tunan")
	slash:deleteLater()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		local targets = {}
		for _,p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		return slash:toString() .. "->" .. table.concat(targets, "+")
	end
	return "."
end

--闭境
sgs.ai_skill_cardask["bijing-invoke"] = function(self, data)
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Jink") then
			table.insert(cards, c)
		end
	end
	if #cards > 0 then
		self:sortByKeepValue(cards)
		return "$" .. cards[1]:getEffectiveId()
	end
	
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Slash") then
			table.insert(cards, c)
		end
	end
	if #cards > 0 then
		self:sortByKeepValue(cards)
		return "$" .. cards[1]:getEffectiveId()
	end
	
	return "."
end

--点虎
function getDianhuTarget(self, targets, RolePredictable)
	if not RolePredictable then
		for _, p in sgs.qlist(targets) do
			if p:hasSkill("shibei") then return p end
		end
		for _, p in sgs.qlist(targets) do
			if p:hasSkills(sgs.recover_skill) then return p end
		end
	else
		for _, p in sgs.qlist(targets) do
			if not self.player:isYourFriend(p) and p:hasSkill("shibei") then return p end
		end
		for _, p in sgs.qlist(targets) do
			if not self.player:isYourFriend(p) and p:hasSkills(sgs.recover_skill) then return p end
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.dianhu = function(self, targets)
	if self.player:getRole() == "rebel" and self.room:getLord() then
		return self.room:getLord()
	end
	local target = getDianhuTarget(self, targets, sgs.isRolePredictable())
	if target then return target end
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	if self.player:getRole() == "loyalist" and self.room:getLord() then
		local new_targets = sgs.SPlayerList()
		for _,p in sgs.qlist(targets) do
			if p:isLord() then continue end
			new_targets:append(p)
		end
		if not new_targets:isEmpty() then return new_targets:at(math.random(0, new_targets:length() - 1)) end
	end
	return targets:at(math.random(0, targets:length() - 1))
end

--谏计
local jianji_skill = {}
jianji_skill.name = "jianji"
table.insert(sgs.ai_skills, jianji_skill)
jianji_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("JianjiCard") and #self.friends_noself > 0 then
		return sgs.Card_Parse("@JianjiCard=.")
	end
end

sgs.ai_skill_use_func.JianjiCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend, true) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
end

sgs.ai_use_priority.JianjiCard = 7
sgs.ai_use_value.JianjiCard = 7
sgs.ai_card_intention.JianjiCard = -20

sgs.ai_skill_use["@@jianji"] = function(self, prompt)
	local id = self.player:getMark("jianji_id-PlayClear") - 1
	if id < 0 then return "." end
	local card = sgs.Sanguosha:getEngineCard(id)
	if card:targetFixed() then
		if card:isKindOf("Peach") then
			if self:isWeak() then
				return card:toString()
			end
			if self:isWeak(self.friends_noself) then
				return "."
			end
			return card:toString()
		end
		if card:isKindOf("EquipCard") then
			local equip_index = card:getRealCard():toEquipCard():location()
			if self.player:getEquip(equip_index) == nil then
				return card:toString()
			end
		end
		if card:isKindOf("AOE") then
			if self:getAoeValue(card) > 0 then
				return card:toString()
			end
		end
		if card:isKindOf("Analeptic") then
			return "."
		end
		if card:isKindOf("ExNihilo") then
			return card:toString()
		end
	else
		local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardByClassName(card, dummy_use)
		if dummy_use.card and not dummy_use.to:isEmpty() then
			local targets = {}
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, p:objectName())
			end
			if #targets > 0 then
				return card:toString() .. "->" .. table.concat(targets, "+")
			end
		end
	end
	return "."
end

--蒺藜
sgs.ai_skill_invoke.jili = function(self, data)
	return self:canDraw()
end

--翊赞
local yizan_skill = {}
yizan_skill.name = "yizan"
table.insert(sgs.ai_skills, yizan_skill)
yizan_skill.getTurnUseCard = function(self, inclusive)
	local basic, notbasic = {}, {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("BasicCard") then
			table.insert(basic, c)
		else
			if c:isKindOf("SkillCard") then continue end
			table.insert(notbasic, c)
		end
	end
	for _,id in sgs.qlist(self.player:getHandPile()) do
		local c = sgs.Sanguosha:getCard(id)
		if c:isKindOf("BasicCard") then
			table.insert(basic, c)
		else
			if c:isKindOf("SkillCard") then continue end
			table.insert(notbasic, c)
		end
	end
	local name = self:ZhanyiUseBasic()
	if name and #basic > 0 then
		local use_cards = {}
		self:sortByUseValue(basic, true)
		table.insert(use_cards, basic[1]:getEffectiveId())
		if self.player:property("yizan_level"):toInt() <= 0 then
			if #notbasic <= 0 and #basic <= 1 then return end
			if self:needToThrowArmor() and self.player:getArmor() then
				table.insert(use_cards, self.player:getArmor():getEffectiveId())
			elseif #notbasic > 0 then
				self:sortByUseValue(notbasic, true)
				table.insert(use_cards, notbasic[1]:getEffectiveId())
			else
				table.insert(use_cards, basic[2]:getEffectiveId())
			end
		end
		return sgs.Card_Parse("@YizanCard=" .. table.concat(use_cards, "+") .. ":" .. name)
	end
end

sgs.ai_skill_use_func.YizanCard = function(card, use, self)
	local userstring = card:toString()
	userstring = userstring:split(":")[3]
	local yizancard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	yizancard:setSkillName("yizan")
	if yizancard:getTypeId() == sgs.Card_TypeBasic then
		if not use.isDummy and use.card and yizancard:isKindOf("Slash") and (not use.to or use.to:isEmpty()) then return end
		self:useBasicCard(yizancard, use)
	end
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority.YizanCard = 3
sgs.ai_use_value.YizanCard = 3

sgs.ai_cardsview_valuable.yizan = function(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	
	local basic, notbasic = {}, {}
	for _,c in sgs.qlist(player:getCards("he")) do
		if c:isKindOf("BasicCard") then
			table.insert(basic, c)
		else
			table.insert(notbasic, c)
		end
	end
	for _,id in sgs.qlist(player:getHandPile()) do
		local c = sgs.Sanguosha:getCard(id)
		if c:isKindOf("BasicCard") then
			table.insert(basic, c)
		else
			table.insert(notbasic, c)
		end
	end
	
	if #basic <= 0 then return end
	local level = player:property("yizan_level"):toInt()
	if (#notbasic <= 0 and #basic <= 1) and level <= 0 then return end
	
	for _,c in ipairs(basic) do
		if c:isKindOf(class_name) then return end
	end
	
	if class_name == "Peach" and player:getMark("Global_PreventPeach") > 0 then return end
	
	local use_cards = {}
	self:sortByUseValue(basic, true)
	table.insert(use_cards, basic[1]:getEffectiveId())
	if level <= 0 then
		if self:needToThrowArmor() and player:getArmor() then
			table.insert(use_cards, player:getArmor():getEffectiveId())
		elseif #notbasic > 0 then
			self:sortByUseValue(notbasic, true)
			table.insert(use_cards, notbasic[1]:getEffectiveId())
		elseif #basic >= 2 then
			table.insert(use_cards, basic[2]:getEffectiveId())
		else
			return
		end
	end
	return ("@YizanCard=" .. table.concat(use_cards, "+") .. ":" .. name)
end

sgs.ai_skill_choice.yizan_saveself = function(self, choices)
	if self:getCard("Peach") or not self:getCard("Analeptic") then return "peach" else return "analeptic" end
end

sgs.ai_skill_choice.yizan_slash = function(self, choices)
	return "slash"
end

sgs.ai_cardneed.yizan = function(to, card, self)
	if to:property("yizan_level"):toInt() <= 0 then return false end
	return card:isKindOf("BasicCard")
end

--武缘
local wuyuan_skill = {}
wuyuan_skill.name = "wuyuan"
table.insert(sgs.ai_skills, wuyuan_skill)
wuyuan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("WuyuanCard") or #self.friends_noself == 0 then return false end
	return sgs.Card_Parse("@WuyuanCard=.")
end

sgs.ai_skill_use_func.WuyuanCard = function(card, use, self)
	local red_tf_slash, red_slash, tf_slash, slash = {}, {}, {}, {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Slash") then
			table.insert(slash, c)
			if c:isRed() and c:objectName() ~= "slash" then
				table.insert(red_tf_slash, c)
			end
			if c:isRed() then
				table.insert(red_slash, c)
			end
			if c:objectName() ~= "slash" then
				table.insert(tf_slash, c)
			end
		end
	end
	if #slash <= 0 then return end
	
	if self:isWeak(self.friends_noself) then
		self:sort(self.friends_noself, "hp")
		local target
		for _,p in ipairs(self.friends_noself) do
			if not self:isWeak(p) or p:getLostHp() <= 0 then continue end
			target = p
			break
		end
		if target then
			local id
			if #red_tf_slash > 0 then
				self:sortByUseValue(red_tf_slash)
				id = red_tf_slash[1]:getEffectiveId()
			end
			if #red_slash > 0 then
				self:sortByUseValue(red_slash)
				id = red_tf_slash[1]:getEffectiveId()
			end
			use.card = sgs.Card_Parse("@WuyuanCard=" .. id)
			if use.to then use.to:append(target) end return
		end
	end
	
	if #red_tf_slash > 0 then
		self:sortByUseValue(red_tf_slash)
		self:sort(self.friends_noself, "defense")
		for _,p in ipairs(self.friends_noself) do
			if self:canDraw(p) and p:getLostHp() > 0 then
				use.card = sgs.Card_Parse("@WuyuanCard=" .. red_tf_slash[1]:getEffectiveId())
				if use.to then use.to:append(p) end return
			end
		end
	end
	
	if #tf_slash > 0 then
		self:sortByUseValue(tf_slash)
		local friend = self:findPlayerToDraw(false, 2)
		if friend then
			use.card = sgs.Card_Parse("@WuyuanCard=" .. tf_slash[1]:getEffectiveId())
			if use.to then use.to:append(friend) end return
		end
	end
	
	if #red_tf_slash > 0 then
		self:sortByUseValue(red_tf_slash)
		local friend = self:findPlayerToDraw(false, 2)
		if friend then
			use.card = sgs.Card_Parse("@WuyuanCard=" .. red_tf_slash[1]:getEffectiveId())
			if use.to then use.to:append(friend) end return
		end
	end
	
	if #slash > 0 then
		self:sortByUseValue(slash)
		local num = 1
		if slash[1]:objectName() ~= "slash" then
			num	= 2
		end
		local friend = self:findPlayerToDraw(false, num)
		if friend then
			use.card = sgs.Card_Parse("@WuyuanCard=" .. slash[1]:getEffectiveId())
			if use.to then use.to:append(friend) end return
		end
	end
	
	if #slash > 0 then
		self:sortByUseValue(slash)
		self:sort(self.friends_noself, "defense")
		for _,p in ipairs(self.friends_noself) do
			if self:canDraw(p) then
				use.card = sgs.Card_Parse("@WuyuanCard=" .. slash[1]:getEffectiveId())
				if use.to then use.to:append(p) end return
			end
		end
	end
end

sgs.ai_use_value.WuyuanCard = 5.9
sgs.ai_use_priority.WuyuanCard = 4
sgs.ai_card_intention.WuyuanCard = -70

sgs.ai_cardneed.wuyuan = function(to, card, self)
	return card:isKindOf("Slash")
end

--誉虚
sgs.ai_skill_invoke.yuxu = true

sgs.ai_skill_discard.yuxu = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, true)
end

--实荐
sgs.ai_skill_cardask["@shijian-discard"] = function(self, data)
	local player = data:toPlayer()
	if not self:isFriend(player) then
		if player:getHandcardNum() <= 2 and self:isWeak() and self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:getLostHp() > 0 then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		return "."
	end
	if player:hasSkill("yuxu", true) then
		if self:isWeak() and self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:getLostHp() > 0 then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		return "."
	end
	
	if player:getHandcardNum() <= 2 then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	return "$" .. cards[1]:getEffectiveId()
end

--蛮嗣
sgs.ai_skill_invoke.mansi = function(self, data)
	return self:canDraw()
end

--薮影
sgs.ai_skill_cardask["souying-invoke"] = function(self, data)
	local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if damage.from:objectName() == self.player:objectName() then
		local male = damage.to
		if self:isFriend(male) then return "." end
		local n = 0
		if self:isEnemy(male) and damage.nature ~= sgs.DamageStruct_Normal and male:isChained() then
			for _,p in sgs.qlist(self.room:getAllPlayers()) do
				if not p:isChained() then continue end
				if p:getHp() > damage.damage or hasBuquEffect(p) or self:cantDamageMore(damage.from, p) or canNiepan(p) or
					not self:damageIsEffective(p, damage.nature, damage.from) then continue end
				if self:isFriend(p) then
					n = n + 1
					if p:isLord() then
						n = n + 10
					end
				elseif self:isEnemy(p) then  --判断天香 待补充
					n = n - 1
					if p:isLord() then
						n = n - 10
					end
				end
			end
		end
		if n > 0 then return "." end
		return "$" .. cards[1]:getEffectiveId()
	else
		local male = damage.from
		if self:isFriend(male) and damage.nature ~= sgs.DamageStruct_Normal and self.player:isChained() then 
			for _,p in sgs.qlist(self.room:getAllPlayers()) do
				if not p:isChained() or not self:damageIsEffective(p, damage.nature, damage.from) then continue end
				if self:isFriend(p) then
					n = n + 1
					if p:isLord() then
						n = n + 10
					end
				elseif self:isEnemy(p) then  --判断天香 待补充
					n = n - 1
					if p:isLord() then
						n = n - 10
					end
				end
			end
			if n > 0 then return "." end
			return "$" .. cards[1]:getEffectiveId()
		else
			return "$" .. cards[1]:getEffectiveId()
		end
	end
end

--战缘
sgs.ai_skill_playerchosen.zhanyuan = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:objectName() ~= self.player:objectName() then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends)
		return friends[#friends]
	end
	
	if targets:contains(self.player) then return self.player end
	return nil
end

--系力
sgs.ai_skill_cardask["xili-invoke"] = function(self, data)
	local use = data:toCardUse()
	local n, enemy_effective, friend_effective = 0, 0, 0
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local lord = self.room:getLord()
	if lord and self:isFriend(lord) and use.to:contains(lord) then return "." end
	if lord and self:isEnemy(lord) and use.to:contains(lord) and not self:cantDamageMore(use.from, lord) then
		if not self:slashIsEffective(use.card, lord, use.from) or (lord:hasArmorEffect("eight_diagram") and not self:isWeak(lord)) or
			getKnownCard(lord, self.player, "Jink", true, "hej") > 0 then return "." end
		return "$" .. cards[1]:getEffectiveId()
	end
	
	for _,p in sgs.qlist(use.to) do
		if self:slashIsEffective(use.card, p, use.from) or self:cantDamageMore(use.from, p) then
			if self:isFriend(p) then
				friend_effective = friend_effective + 1
			elseif self:isEnemy(p) then
				enemy_effective = enemy_effective + 1
			end
		end
		if p:hasArmorEffect("eight_diagram") then
			if self:isFriend(p) then
				n = n + 1
			elseif self:isEnemy(p) then
				n = n - 1
			end
		end
		if getKnownCard(p, self.player, "Jink", true, "hej") > 0 then
			if self:isFriend(p) then
				n = n + 1
			elseif self:isEnemy(p) then
				n = n - 1
			end
		end
	end
	if friend_effective >= enemy_effective or n > 0 then return "." end
	return "$" .. cards[1]:getEffectiveId()
end

--第二版蛮嗣
local secondmansi_skill = {}
secondmansi_skill.name = "secondmansi"
table.insert(sgs.ai_skills, secondmansi_skill)
secondmansi_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:hasUsed("SecondMansiCard") then return end
	local savage_assault = sgs.Sanguosha:cloneCard("savage_assault")
	savage_assault:addSubcards(self.player:getHandcards())
	savage_assault:setSkillName("secondmansi")
	savage_assault:deleteLater()
	if not savage_assault:isAvailable(self.player) or self:getAoeValue(savage_assault) <= 0 then return end
	local handcards = sgs.QList2Table(self.player:handCards())
	return sgs.Card_Parse("@SecondMansiCard=" .. table.concat(handcards, "+") .. ":" .. "savage_assault")
end

sgs.ai_skill_use_func.SecondMansiCard = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
	local sa = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	sa:setSkillName("secondmansi")
	self:useTrickCard(sa, use)
	if use.card then
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if isCard("Peach", acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded()
			and not self:needToLoseHp(self.player) then
				use.card = acard
				return
			end
		end
		use.card = card
	end
end

sgs.ai_use_priority.SecondMansiCard = 1.5

--第二版薮影
sgs.ai_skill_cardask["@secondsouying-dis"] = function(self, data)
	local use = data:toCardUse()
	if self:isWeak() and self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:getLostHp() > 0 then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards)
	if self:getUseValue(cards[#cards]) > self:getUseValue(use.card) then
		return "$" .. cards[#cards]:getEffectiveId()
	end
	return "."
end

sgs.ai_skill_cardask["@secondsouying-dis2"] = function(self, data)
	local use = data:toCardUse()
	if self:isWeak() and self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:getLostHp() > 0 then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if use.card:isKindOf("Slash") then
		if not self:slashIsEffective(use.card, self.player, use.from) then return "." end
	elseif use.card:isKindOf("TrickCard") then
		if not self:hasTrickEffective(use.card, self.player, use.from) then return "." end
		if self:isFriend(use.from) then return "." end
	end
	return "$" .. cards[1]:getEffectiveId()
end

--第二版战缘
sgs.ai_skill_playerchosen.secondzhanyuan = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:objectName() ~= self.player:objectName() then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends)
		return friends[#friends]
	end
	return nil
end

--第二版系力
sgs.ai_skill_cardask["@secondxili-dis"] = function(self, data)
	local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if self:isFriend(damage.from) and not self:isFriend(damage.to) then
		if self:isWeak() and self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:getLostHp() > 0 then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		if self:cantDamageMore(damage.from, damage.to) then return "." end
		return "$" .. cards[1]:getEffectiveId()
	elseif self:isEnemy(damage.from) and self:isEnemy(damage.to) then
		if self:isWeak() and self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:getLostHp() > 0 then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		if self:cantDamageMore(damage.from, damage.to) then return "." end
		return "$" .. cards[1]:getEffectiveId()
	else
		if self:cantDamageMore(damage.from, damage.to) then
			if self:isWeak() and self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:getLostHp() > 0 then
				return "$" .. self.player:getArmor():getEffectiveId()
			end
		end
	end
	return "."
end

--弘德
sgs.ai_skill_playerchosen.hongde = function(self, targets)
	return self:findPlayerToDraw(false, 1)
end

--定叛
local dingpan_skill = {}
dingpan_skill.name = "dingpan"
table.insert(sgs.ai_skills, dingpan_skill)
dingpan_skill.getTurnUseCard = function(self)
	local rebel = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getRole() == "rebel" then
			rebel = rebel + 1
		end
	end
    if self.player:usedTimes("DingpanCard") >= rebel then return end
	return sgs.Card_Parse("@DingpanCard=.")
end

sgs.ai_skill_use_func.DingpanCard = function(card, use, self)
	local friends, enemies = {}, {}
	for _, player in sgs.qlist(self.room:getPlayers()) do
        if not player:getEquips():isEmpty() then
            if self:isFriend(player) and self:canDraw(player) then
                table.insert(friends, player)
            elseif self:isEnemy(player) and not self:doNotDiscard(player, "e") 
                and not player:hasArmorEffect("silver_lion") and
                not self:getDamagedEffects(player) and not self:needToLoseHp(player) then
                table.insert(enemies, player)
            end
        end
    end
	if #friends == 0 and #enemies == 0 then return end
	
	if self:needToThrowArmor() then
		use.card = card
		if use.to then use.to:append(self.player) end return
	end
	
	self:sort(friends)
	self:sort(enemies)
	
	for _, friend in ipairs(friends) do
		if self:needToThrowArmor(friend) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if self:needKongcheng(enemy, true) then
			use.card = card
			if use.to then use.to:append(enemy) end return
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if enemy:containsTrick("indulgence") and not enemy:containsTrick("YanxiaoCard") then
			use.card = card
			if use.to then use.to:append(enemy) end return
        end
	end
	
	for i = #friends, 1, -1 do
		local friend = friends[i]
		if not self:isWeak(friend) and (friend:hasSkills(sgs.lose_equip_skill) or hasTuntianEffect(friend, true)) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	
	for i = #friends, 1, -1 do
		local friend = friends[i]
		if not self:isWeak(friend) and (friend:hasSkills(sgs.lose_equip_skill) or hasTuntianEffect(friend)) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	
	if #enemies == 0 then return end
	use.card = card
	if use.to then use.to:append(enemies[1]) end return
end

sgs.ai_use_priority.DingpanCard = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_choice.dingpan = function(self, choices, data)
	if (self.player:hasArmorEffect("silver_lion") and self.player:getArmor()) or self:getDamagedEffects() or self:needToLoseHp() then 
        return "get" 
    end
    return "discard"
end

--闪袭
getShanxiTarget = function(self, targets)
	targets = targets or self.room:getOtherPlayers(self.player)
	local friends, enemies = {}, {}
	for _,p in sgs.qlist(targets) do
		if not self.player:canDiscard(p, "he") then continue end
		if self.player:inMyAttackRange(p) then
			if self:isFriend(p) then
				table.insert(friends, p)
			elseif self:isEnemy(p) and not self:doNotDiscard(p, "he") then
				table.insert(enemies, p)
			end
		end
    end
	if #friends == 0 and #enemies == 0 then return nil end
	self:sort(enemies, "defense")
	self:sort(friends, "defense")
	
	for _, enemy in ipairs(enemies) do
		if self:getDangerousCard(enemy) then
			return enemy
        end
    end
	
	for _, friend in ipairs(friends) do
		if self:needToThrowArmor(friend) then
			return friend
		end
	end
	
	for _, friend in ipairs(friends) do
		if friend:hasSkill("kongcheng") and friend:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, friend) > 0 and friend:getHp() <= 2 then
			return friend
		end
	end
	
	for _, friend in ipairs(friends) do
		if (friend:hasSkill("zhiji") and friend:getMark("zhiji") == 0) or (friend:hasSkill("mobilezhiji") and friend:getMark("mobilezhiji") == 0) and
			friend:getHandcardNum() == 1 and (self:getEnemyNumBySeat(self.player, friend) == 0 or (not self:isWeak(friend) and self:getEnemyNumBySeat(self.player, friend) <= 2)) then
			return friend
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if self:getValuableCard(enemy) and not self:doNotDiscard(enemy, "e") then
			return enemy
        end
	end
	
	for _, enemy in ipairs(enemies) do
		local cards = sgs.QList2Table(enemy:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
		if #cards <= 2 and not self:doNotDiscard(enemy, "h") then
			for _, cc in ipairs(cards) do
				if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic") or cc:isKindOf("ExNihilo")) then
					return enemy
				end
            end
        end
	end
	
	for _, enemy in ipairs(enemies) do
		if not self:doNotDiscard(enemy, "e") and self.player:canDiscard(enemy, "e") then
			return enemy
		end
	end
	
	self:sort(enemies, "handcard")
	for _, enemy in ipairs(enemies) do
       if not self:doNotDiscard(enemy, "h") and self.player:canDiscard(enemy, "h") then
			return enemy
		end
	end
	
	return nil
end

local shanxi_skill = {}
shanxi_skill.name = "shanxi"
table.insert(sgs.ai_skills, shanxi_skill)
shanxi_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("ShanxiCard") then return end
	return sgs.Card_Parse("@ShanxiCard=.")
end

sgs.ai_skill_use_func.ShanxiCard = function(card, use, self)
	local handcards = self.player:getHandcards()
    local cards = {}
    for _,c in sgs.qlist(handcards) do
        if c:isKindOf("BasicCard") and c:isRed() and not c:isKindOf("Peach") then
            if self.player:canDiscard(self.player, c:getEffectiveId()) then
                table.insert(cards, c)
            end
        end
    end
    if #cards == 0 then return end
    self:sortByKeepValue(cards)
	
	if self:getOverflow() > 0 then
		local no_one_inMyAttackRange = true
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not self.player:canDiscard(p, "he") then continue end
			if self.player:inMyAttackRange(p) then
				no_one_inMyAttackRange = false
				break
			end
		end
		if no_one_inMyAttackRange then
			for _,p in ipairs(self.friends_noself) do
				if (p:hasSkill("shenxian") and p:getPhase() == sgs.Player_NotActive) or (p:hasSkill("olshenxian") and p:getPhase() == sgs.Player_NotActive and p:getMark("olshenxian") == 0) then
					use.card = sgs.Card_Parse("@ShanxiCard=" .. cards[1]:getEffectiveId())
				end
				return
			end
		end
	end
	
	self.shanxi_target = getShanxiTarget(self)
	if not self.shanxi_target then return end
	use.card = sgs.Card_Parse("@ShanxiCard=" .. cards[1]:getEffectiveId())
end

sgs.ai_skill_playerchosen.shanxi = function(self, targets)
	if not self.shanxi_target or not targets:contains(self.shanxi_target) then
		local target = getShanxiTarget(self, targets)
		if target then return target end
		local enemies = {}
		for _, p in sgs.qlist(targets) do
			if not self:isFriend(p) then
				table.insert(enemies, p)
			end
		end
		self:sort(enemies)
		for _,p in ipairs(enemies) do
			if not self:doNotDiscard(p, "he") then
				return p
			end
		end
		if #enemies > 0 then return enemies[1] end
		return targets:at(math.random(0, targets:length() - 1))
	end
	return self.shanxi_target
end

sgs.ai_use_priority.ShanxiCard = sgs.ai_use_priority.Slash + 0.1

--下书
sgs.ai_skill_playerchosen.xiashu = function(self, targets)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self:sort(self.friends_noself, "defense")
	self.xiashu_target = nil
	if (self.player:getHandcardNum() < 3 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Jink") == 0 and self:getCardsNum("Analeptic") == 0) or
		(self.player:getHandcardNum() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0) then
		local max_card_num = 0
		for _,enemy in ipairs(self.enemies) do
			max_card_num = math.max(max_card_num, enemy:getHandcardNum())
		end
		for _,enemy in ipairs(self.enemies) do
			if enemy:getHandcardNum() == max_card_num and enemy:getHandcardNum() > 0 then
				self.xiashu_target = enemy
				return enemy
			end
		end
	else
		for _,friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then
				self.xiashu_target = friend
				return friend
			end
		end
	end
	return nil
end

sgs.ai_skill_discard.xiashu = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(cards, true)
	local to_discard = {}
	local half_all_card_num = math.max(1, math.floor(self.player:getHandcardNum() / 2))
	for i = 1, half_all_card_num, 1 do
		table.insert(to_discard, cards[i]:getEffectiveId())
	end
	return to_discard
end

sgs.ai_skill_choice.xiashu = function(self, choices, data)
	local items = choices:split("+")
	if not self.xiashu_target then
		local items = choices:split("+")
		return items[math.random(1, #items)]
	end
	local ids = data:toIntList()
	local show_need, notshow_need = 0, 0
	for _,id in sgs.qlist(ids) do
		show_need = show_need + self:cardNeed(sgs.Sanguosha:getCard(id))
	end
	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), self.xiashu_target:objectName())
	for _,c in sgs.qlist(self.xiashu_target:getHandcards()) do
		if ids:contains(c:getEffectiveId()) then continue end
		if c:hasFlag("visible") or c:hasFlag(flag) then
			notshow_need = notshow_need + self:cardNeed(c)
		else
			notshow_need = notshow_need + 0.5
		end
	end
	if show_need > notshow_need then return "getshow" end
	if show_need <= notshow_need then return "getnotshow" end
	return items[math.random(1, #items)]
end

--宽释
sgs.ai_skill_playerchosen.kuanshi = function(self, targets)
	self:updatePlayers()
	self:sort(self.friends, "defense")
	for _,friend in ipairs(self.friends) do
		return friend
	end
	return nil
end

--十周年宽释

sgs.ai_skill_playerchosen.tenyearkuanshi = function(self, targets)
	return sgs.ai_skill_playerchosen.kuanshi(self, targets)
end

--过论
local guolun_skill = {}
guolun_skill.name = "guolun"
table.insert(sgs.ai_skills, guolun_skill)
guolun_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("GuolunCard") then
		return sgs.Card_Parse("@GuolunCard=.")
	end
end

sgs.ai_skill_use_func.GuolunCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "handcard")
	self:sort(self.enemies, "handcard")
	self.guolun_target = nil

	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() > 0 and not hasManjuanEffect(friend) then
			use.card = card
			if use.to then
				self.guolun_target = friend
				use.to:append(friend)
			end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > 0 then
			use.card = card
			if use.to then
				self.guolun_target = enemy
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_use_priority.GuolunCard = 7
sgs.ai_use_value.GuolunCard = 7

sgs.ai_skill_cardask["guolun-show"] = function(self, data)
	local id = data:toInt()
	if not id or id < 0 or not self.guolun_target then return "." end
	local card = sgs.Sanguosha:getCard(id)
	if self:isFriend(self.guolun_target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards, true)
		if #cards > 0 then return "$" .. cards[1]:getEffectiveId() end
	else
		local num = card:getNumber()
		local canshow = {}
		for _,c in sgs.qlist(self.player:getCards("he")) do
			if c:getNumber() < num then
				table.insert(canshow, c)
			end
		end
		if #canshow > 0 then
			self:sortByUseValue(canshow, true)
			return "$" .. canshow[1]:getEffectiveId()
		end
	end
	return "."
end

--送丧
sgs.ai_skill_invoke.songsang = true

--弼政
sgs.ai_skill_playerchosen.bizheng = function(self, targets)
	local friends = {}
	for _,p in ipairs(self.friends_noself) do
		if self:canDraw(p) and p:getHandcardNum() + 2 <= p:getMaxHp() then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends)
		return friends[1]
	end
	for _,p in ipairs(self.friends_noself) do
		if self:canDraw(p) then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		self:sort(friends)
		return friends[1]
	end
	return nil
end

sgs.ai_skill_discard.bizheng = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 2, 2, false, true)
end

--佚典
sgs.ai_skill_use["@@yidian"] = function(self, prompt) -- extra target for Collateral
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	local tos = self.player:property("extra_collateral_current_targets"):toString():split("+")
	local card_str = self.player:property("extra_collateral"):toString()
	local card = sgs.Card_Parse(card_str)
	for _,name in ipairs(tos) do
		table.insert(dummy_use.current_targets, name)
	end
	self:useCardCollateral(card, dummy_use)
	if dummy_use.card and dummy_use.to:length() == 2 then
		return "@ExtraCollateralCard=.->" .. dummy_use.to:first():objectName() .. "+" .. dummy_use.to:last():objectName()
	end
	return "."
end

sgs.ai_skill_playerchosen.yidian = function(self, targets)
	local use = self.player:getTag("YidianData"):toCardUse()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	for _,p in sgs.qlist(use.to) do
		table.insert(dummy_use.current_targets, p:objectName())
	end
	self:useCardByClassName(use.card, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		return dummy_use.to:first()
	end
	return nil
end

--联翩
sgs.ai_skill_invoke.lianpian = function(self, data)
	return self:canDraw()
end

sgs.ai_skill_playerchosen.lianpian = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isFriend(p) and not self:needKongcheng(p, true) and not hasManjuanEffect(p) then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if self:isFriend(p) and not self:needKongcheng(p, true) and not hasManjuanEffect(p, true) then
			return p
		end
	end
end

sgs.ai_playerchosen_intention.lianpian = -50

--观潮
sgs.ai_skill_invoke.guanchao = true

sgs.ai_skill_choice.guanchao = function(self, choices, data)
	local items = choices:split("+")
	local choice = items[math.random(1, #items)]
	if self.player:isKongcheng() then return choice end
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByDynamicUsePriority(handcards)
	if handcards[1]:getNumber() < handcards[2]:getNumber() then
		return "up"
	elseif handcards[1]:getNumber() > handcards[2]:getNumber() then
		return "down"
	end
	return choice
end

--逊贤
sgs.ai_skill_playerchosen.xunxian = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isFriend(p) and not self:needKongcheng(p, true) and not hasManjuanEffect(p) then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if self:isFriend(p) and not self:needKongcheng(p, true) and not hasManjuanEffect(p, true) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.xunxian = -50

--诱敌
sgs.ai_skill_playerchosen.spyoudi = function(self, targets)
	local num = 0
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Peach") or c:isKindOf("Slash") or c:isKindOf("ExNihilo") then
			num = num + 1
		end
	end
	if num > self.player:getHandcardNum() / 2 then return nil end
	if self:getCardsNum("Jink") == 1 and self:isWeak() and self.player:getHandcardNum() < 3 then return nil end
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isEnemy(p) and not p:isNude() and not self:doNotDiscard(p, "he") then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.spyoudi = 20

--断发
local duanfa_skill = {}
duanfa_skill.name = "duanfa"
table.insert(sgs.ai_skills, duanfa_skill)
duanfa_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("duanfa_num-PlayClear") < self.player:getMaxHp() then
		return sgs.Card_Parse("@DuanfaCard=.")
	end
end

sgs.ai_skill_use_func.DuanfaCard = function(card, use, self)
	if self:needToThrowArmor() and self.player:getArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) and
		self.player:getArmor():isBlack() then
		use.card = sgs.Card_Parse("@DuanfaCard=" .. self.player:getArmor():getEffectiveId())
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if self.player:hasSkills("youdi|spyoudi") then
		for _,c in ipairs(cards) do
			if c:isKindOf("Slash") and c:isBlack() then
				use.card = sgs.Card_Parse("@DuanfaCard=" .. c:getEffectiveId())
				return
			end
		end
	end
	for _,c in ipairs(cards) do
		if c:isBlack() and not (c:isKindOf("Lightning") and self:willUseLightning(c)) then
			use.card = sgs.Card_Parse("@DuanfaCard=" .. c:getEffectiveId())
			return
		end
	end
end

sgs.ai_use_priority.DuanfaCard = 0
sgs.ai_use_value.DuanfaCard = 2.61

--勤国
sgs.ai_skill_use["@@qinguo"] = function(self, prompt, method)
	local slash = sgs.Sanguosha:cloneCard("slash")
    slash:setSkillName("qinguo")
    slash:deleteLater()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		local tos = {}
		for _,p in sgs.qlist(dummy_use.to) do
			table.insert(tos, p:objectName())
		end
		return "@QinguoCard=.->" .. table.concat(tos, "+")
	end
	return "."
end

--札符
local zhafu_skill = {}
zhafu_skill.name = "zhafu"
table.insert(sgs.ai_skills, zhafu_skill)
zhafu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@zhafuMark") > 0 and #self.enemies > 0 then
		return sgs.Card_Parse("@ZhafuCard=.")
	end
end

sgs.ai_skill_use_func.ZhafuCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	use.card = card
	if use.to then
		use.to:append(self.enemies[#self.enemies])
	end
end

sgs.ai_skill_cardask["zhafu-keep"] = function(self, data)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	return "$" .. cards[#cards]:getEffectiveId()
end

--颂蜀
local songshu_skill = {}
songshu_skill.name = "songshu"
table.insert(sgs.ai_skills, songshu_skill)
songshu_skill.getTurnUseCard = function(self, inclusive)
	if self:needBear() then return end
	if not self.player:hasUsed("SongshuCard") then
		return sgs.Card_Parse("@SongshuCard=.")
	end
end

sgs.ai_skill_use_func.SongshuCard = function(card, use, self)
	self:sort(self.friends_noself, "handcard")
	self:sort(self.enemies, "handcard")
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local min_card = self:getMinCard(self.player, cards)
	local max_card = self:getMaxCard(self.player, cards)
	
	if min_card then
		local min_point = min_card:getNumber()
		if min_point < 7 then
			for _,p in ipairs(self.friends_noself) do
				if p:hasSkill("kongcheng") and p:getHandcardNum() == 1 then continue end
				if not self:canDraw(p) or not self.player:canPindian(p) then continue end
				use.card = sgs.Card_Parse("@SongshuCard=.")
				self.songshu_card = min_card
				if use.to then use.to:append(p) end return
			end
		end
	end
	
	if max_card then
		local max_point = max_card:getNumber()
		if max_point >= 7 then
			for _,p in ipairs(self.enemies) do
				if p:hasSkill("kongcheng") and p:getHandcardNum() == 1 then continue end
				if self:doNotDiscard(p, "h") or not self.player:canPindian(p) then continue end
				use.card = sgs.Card_Parse("@SongshuCard=.")
				self.songshu_card = max_card
				if use.to then use.to:append(p) end return
			end
			
			for _,p in ipairs(self.friends_noself) do
				if not (p:hasSkill("kongcheng") and p:getHandcardNum() == 1) then continue end
				if not self.player:canPindian(p) then continue end
				use.card = sgs.Card_Parse("@SongshuCard=.")
				self.songshu_card = max_card
				if use.to then use.to:append(p) end return
			end
		end
	end
end

sgs.ai_use_priority.SongshuCard = 0

function sgs.ai_skill_pindian.songshu(minusecard, self, requestor)
	return self:isFriend(requestor) and self:getMaxCard() or ( self:getMinCard():getNumber() > 6 and  minusecard or self:getMinCard() )
end

--思辩
sgs.ai_skill_invoke.sibian = true

sgs.ai_skill_playerchosen.sibian = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and self:canDraw(p) then
			table.insert(players, p)
		end
	end
	if #friends > 0 then
		self:sort(friends, "defense")
		return friends[1]
	end
	return nil
end

--表召
sgs.ai_skill_cardask["biaozhao-put"] = function(self, data)
	if self.player:getArmor() and self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("Peach") or c:isKindOf("ExNihilo") or (c:isKindOf("Jink") and (self:isWeak() or self:getCardsNum("Jink") == 1)) or
		(self:isWeak() and c:isKindOf("Analeptic")) or (self.player:getArmor() and c:getEffectiveId() == self.player:getArmor():getEffectiveId() and not self:needToThrowArmor()) or
			(c:isKindOf("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty())	then continue end
		table.insert(cards, c)
	end
	if #cards > 0 then
		self:sortByKeepValue(cards)
		return "$" .. cards[1]:getEffectiveId()
	end
	return "."
end

sgs.ai_skill_playerchosen.biaozhao = function(self, targets)
	local num = self.player:getHandcardNum()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		num = math.max(num, p:getHandcardNum())
	end
	num = math.max(num, 5)
	
	local weak = {}
	for _,p in ipairs(self.friends) do
		if hasManjuanEffect(p) and not self:needKongcheng(p, true) and p:getHp() <= 1 and self:isWeak(p) then
			table.insert(weak, p)
		end
	end
	if #weak > 0 then
		self:sort(weak)
		return weak[1]
	end
	
	function biaozhaosort(a, b)
		local c1 = a:getLostHp() + math.max(num - a:getHandcardNum(), 0) / 2
		local c2 = b:getLostHp() + math.max(num - b:getHandcardNum(), 0) / 2
		if c1 == c2 then
			return math.max(num - a:getHandcardNum(), 0) > math.max(num - b:getHandcardNum(), 0)
		end
		return c1 > c2
	end
	
	local friends = {}
	for _,p in ipairs(self.friends) do
		if self:canDraw(p) then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
		table.sort(friends, biaozhaosort)
		return friends[1]
	end
	table.sort(self.friends, biaozhaosort)
	return self.friends[1]
end

--业仇
sgs.ai_skill_playerchosen.yechou = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _,p in ipairs(targets) do
		if self:isEnemy(p) and not hasBuquEffect(p) then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return nil
end

--观微
sgs.ai_skill_cardask["guanwei-invoke"] = function(self, data, pattern, target, target2)
	local player = data:toPlayer()
	if not player or not self:isFriend(player) then return "." end
	if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	if self.player:getHandcardNum() < 2 and not self.player:hasSkill("kongcheng") then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		if not c:isKindOf("Peach") then
			return "$" .. c:getEffectiveId()
		end
	end
	return "."
end

--浮海
--[[sgs.ai_cardshow.fuhai = function(self, requestor)
	local id = self.player:getTag("FuhaiID"):toInt() - 1
	if id < 0 then return self.player:getRandomHandCard() end
	if self.player:objectName() == requestor:objectName() then
		local now = self.player:getTag("FuhaiNow"):toPlayer()
		if not now then return self.player:getRandomHandCard() end
		local next_p = now:getNextAlive()
		local last_p = now:getNextAlive(self.room:alivePlayerCount() - 1)
		
	
	else
		if self:isFriend(requestor) then
		
		
		else
		
		end
	end
end]]

--手杀浮海
local mobilefuhai_skill = {}
mobilefuhai_skill.name = "mobilefuhai"
table.insert(sgs.ai_skills, mobilefuhai_skill)
mobilefuhai_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("MobileFuhaiCard") then
		return sgs.Card_Parse("@MobileFuhaiCard=.")
	end
end

sgs.ai_skill_use_func.MobileFuhaiCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.MobileFuhaiCard = 7
sgs.ai_use_value.MobileFuhaiCard = 7

sgs.ai_skill_choice.mobilefuhai = function(self, choices, data)
	choices = choices:split("+")
	return choices[math.random(1, #choices)]
end

--问计
sgs.ai_skill_playerchosen.wenji = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
		if self:isEnemy(p) and not self:doNotDiscard(p, "he") then
			return p
		end
	end
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets) do
		if self:isFriend(p) and self:doNotDiscard(p, "he") then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if self:isFriend(p) and p:hasSkills(sgs.lose_equip_skill) and (p:getEquips():length() > 1 or p:getPile("wooden_ox"):isEmpty()) then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if self:isFriend(p) and self:getOverflow(p) > 0 then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.wenji = function(self, from, to)
	if sgs.turncount <= 1 then
		sgs.updateIntention(from, to, 80)
	end
end

sgs.ai_skill_cardask["wenji-give"] = function(self, data, pattern, target, target2)
	local from = data:toPlayer()
	if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
	if self.player:hasSkills(sgs.lose_equip_skill) then
		local id = self:disEquip(true)
		if id then return "$" .. id end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	
	if self:isFriend(from) then
		local enemies = sgs.SPlayerList()
		for _,p in ipairs(self:getEnemies(from)) do
			enemies:append(p)
		end
		
		self:sortByUseValue(cards)
		for _,c in ipairs(cards) do
			if c:isDamageCard() and not c:isKindOf("Lightning") and from:canUse(c, enemies) then
				return "$" .. c:getEffectiveId()
			end
		end
		for _,c in ipairs(cards) do
			if from:canUse(c, enemies) then
				return "$" .. c:getEffectiveId()
			end
		end
		if self.player:hasSkills(sgs.lose_equip_skill) then
			local id = self:disEquip(true)
			if id then return "$" .. id end
		end
		for _,c in ipairs(cards) do
			if from:canUse(c) then
				return "$" .. c:getEffectiveId()
			end
		end
		return "$" .. cards[1]:getEffectiveId()
	else
		self:sortByUseValue(cards, true)
		for _,c in ipairs(cards) do
			if c:isKindOf("Peach") or (c:isDamageCard() and not c:isKindOf("Lightning")) then continue end
			if not from:canUse(c) then
				return "$" .. c:getEffectiveId()
			end
		end
		for _,c in ipairs(cards) do
			if c:isKindOf("Peach") or (c:isDamageCard() and not c:isKindOf("Lightning")) then continue end
			return "$" .. c:getEffectiveId()
		end
		return "$" .. cards[1]:getEffectiveId()
	end
	return "."
end

--屯江
sgs.ai_skill_invoke.tunjiang = function(self, data)
	return self:canDraw()
end