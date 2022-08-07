--掠命
local lveming_skill = {}
lveming_skill.name = "lveming"
table.insert(sgs.ai_skills, lveming_skill)
lveming_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("LvemingCard") then
		return sgs.Card_Parse("@LvemingCard=.")
	end
end

sgs.ai_skill_use_func.LvemingCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() < self.player:getEquips():length() then
			if ((friend:isNude() and not friend:isAllNude() and not friend:containsTrick("YanxiaoCard")) or
				(friend:isKongcheng() and friend:getJudgingArea():isEmpty() and self:needToThrowArmor(friend) and friend:getEquips():length() == 1) or
				(friend:getJudgingArea():isEmpty() and friend:getEquips():isEmpty() and self:needToThrowLastHandcard(friend))) then
				use.card = card
				if use.to then use.to:append(friend) end return
			end
		end
	end
	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() < self.player:getEquips():length() and not enemy:isNude() and not self:doNotDiscard(enemy, "he") then
			use.card = card
			if use.to then use.to:append(enemy) end return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() < self.player:getEquips():length() and enemy:isNude() then
			use.card = card
			if use.to then use.to:append(enemy) end return
		end
	end
end

sgs.ai_use_priority.LvemingCard = 7
sgs.ai_use_value.LvemingCard = 7

sgs.ai_card_intention.LvemingCard = function(self, card, from, tos)
	local to = tos[1]
	if ((to:isNude() and not to:isAllNude() and not to:containsTrick("YanxiaoCard")) or
		(to:isKongcheng() and to:getJudgingArea():isEmpty() and self:needToThrowArmor(to) and to:getEquips():length() == 1) or
		(to:getJudgingArea():isEmpty() and to:getEquips():isEmpty() and self:needToThrowLastHandcard(to))) then
		sgs.updateIntention(from, to, -80)
	else
		sgs.updateIntention(from, to, 80)
	end
end

sgs.ai_skill_choice.lveming = function(self, choices, data)
	local items = choices:split("+")
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasSkill("zhenyi") and p:getMark("@flziwei") > 0 and self:isEnemy(p) then
			local zhenyi_items = {}
			for _, item in ipairs(items) do
				if tonumber(item) ~= 5 then
					table.insert(zhenyi_items, item)
				end
			end
			return zhenyi_items[math.random(1,#zhenyi_items)]
		end
	end
	return items[math.random(1,#items)]
end

--屯军
function getTunjunEquipNum(player)
	local num = 0
	for i = 0, 4 do
		if player:hasEquipArea(i) and not player:getEquip(i) then
			num = num + 1
		end
	end
	return num
end

local compareByEquipNum = function(a, b)
	return getTunjunEquipNum(a) > getTunjunEquipNum(b)
end

local tunjun_skill = {}
tunjun_skill.name = "tunjun"
table.insert(sgs.ai_skills, tunjun_skill)
tunjun_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@tunjunMark") <= 0 then return end
	if self.player:getMark("&lveming")<= 0 then return end
	local friends = {}
	for _, p in ipairs(self.friends) do
		if p:hasEquipArea() then
			table.insert(friends, p)
		end
	end
	if #friends == 0 then return end
	table.sort(friends, compareByEquipNum)
	
	self.tunjun_target = nil
	for _, p in ipairs(friends) do
		if self:isWeak(p) and ((p:hasEquipArea(1) and not p:getEquip(1)) or (p:hasEquipArea(2) and not p:getEquip(2))) then
			self.tunjun_target = p
			return sgs.Card_Parse("@TunjunCard=.")
		end
	end
	
	if self.player:getMark("&lveming") >= getTunjunEquipNum(friends[1]) then
		return sgs.Card_Parse("@TunjunCard=.")
	end
	if self.player:getMark("&lveming") > 2 then
		return sgs.Card_Parse("@TunjunCard=.")
	end
end

sgs.ai_skill_use_func.TunjunCard = function(card, use, self)
	if self.tunjun_target then
		use.card = card
		if use.to then use.to:append(self.tunjun_target) end return
	end
	
	self:updatePlayers()
	local friends = {}
	for _, p in ipairs(self.friends) do
		if p:hasEquipArea() then
			table.insert(friends, p)
		end
	end
	table.sort(friends, compareByEquipNum)
	for _, friend in ipairs(friends) do
		if getTunjunEquipNum(friend) >= self.player:getMark("&lveming") then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	for _, friend in ipairs(friends) do
		if friend:hasSkills(sgs.lose_equip_skill) and not friend:getEquips():isEmpty() then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	for _, friend in ipairs(friends) do
		if friend:hasSkills(sgs.lose_equip_skill) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	for _, friend in ipairs(friends) do
		use.card = card
		if use.to then use.to:append(friend) end return
	end
end

sgs.ai_use_priority.TunjunCard = sgs.ai_use_priority.LvemingCard - 0.1
sgs.ai_use_value.TunjunCard = 7
sgs.ai_card_intention.TunjunCard = -80

--散文
sgs.ai_skill_invoke.sanwen = function(self, data)
	local ids = data:toIntList()
	for _,id in sgs.qlist(ids) do
		if sgs.Sanguosha:getCard(id):isKindOf("Peach") and self:isWeak(self.friends) then
			return false
		end
	end
	return true
end

--七哀
sgs.ai_skill_invoke.qiai = true

sgs.ai_skill_cardask["qiai-give"] = function(self, data, pattern, target, target2)
	local player = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if self:isFriend(player) then
		for _, c in ipairs(cards) do
			if isCard("Peach", c, player) or isCard("Analeptic", c, player) then
				return "$" .. c:getEffectiveId()
			end
		end
	else
		for _, c in ipairs(cards) do
			if isCard("Peach", c, player) or isCard("Analeptic", c, player) then continue end
			return "$" .. c:getEffectiveId()
		end
	end
	return "$" .. cards[1]:getEffectiveId()
end

--登楼
sgs.ai_skill_invoke.denglou = true

sgs.ai_skill_use["@@denglou!"] = function(self, prompt, method)
	local ids = self.player:property("denglou_ids"):toString():split("+")
	local cards = {}
	for _,id in ipairs(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(tonumber(id)))
	end
	
	self:sortByDynamicUsePriority(cards)
	if cards[1]:targetFixed() and self.player:canUse(cards[1]) then
		return "@DenglouCard=" .. cards[1]:getEffectiveId()
	elseif not cards[1]:targetFixed() then
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		self:useCardByClassName(cards[1], dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			local tos = {}
			for _,p in sgs.qlist(dummy_use.to) do
				table.insert(tos, p:objectName())
			end
			return "@DenglouCard=" .. cards[1]:getEffectiveId() .. "->" .. table.concat(tos, "+")
		end
	end
	return "."
end

--备战
sgs.ai_skill_playerchosen.beizhan = function(self, targets)
	local friends = {}
	for _,p in ipairs(self.friends) do
		if self:canDraw(p) and math.min(5, p:getMaxHp()) - p:getHandcardNum() > 0 then table.insert(friends, p) end
	end
	if #friends > 0 then
		local beizhansort = function(a, b)
			local c1 = math.max(0, math.min(5, a:getMaxHp()) - a:getHandcardNum())
			local c2 = math.max(0, math.min(5, b:getMaxHp()) - b:getHandcardNum())
			return c1 > c2
		end
		table.sort(friends, beizhansort)
		return friends[1]
	end
	for _, p in ipairs(self.enemies) do
		if math.min(5, p:getMaxHp()) - p:getHandcardNum() <= 0 or hasManjuanEffect(p) then
			return p
		end
	end
	for _, p in ipairs(self.enemies) do
		if self:needKongcheng(p, true) and math.min(5, p:getMaxHp()) - p:getHandcardNum() <= 1 and self:getEnemyNumBySeat(self.player, p, p) > 0 then
			return p
		end
	end
	return nil
end

--守邺
sgs.ai_skill_invoke.mobileshouye = function(self, data)
	local use = self.player:getTag("mobileshouyeForAI"):toCardUse()
	if not use then return false end
	if self:isFriend(use.from) then return false end
	if use.card:isKindOf("GlobalEffect") or use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo") or use.card:isKindOf("Analeptic") then return false end
	return true
end

sgs.ai_skill_choice.mobileshouye = function(self, choices, data)
	choices = choices:split("+")
	return choices[math.random(1, #choices)]
end

--烈直
sgs.ai_skill_use["@@mobileliezhi"] = function(self, prompt)
	local targets = self:findPlayerToDiscard("hej", false, true, nil, true)
	if #targets > 0 then
		local tos = {}
		for i = 1, math.min(2, #targets) do
			table.insert(tos, targets[i]:objectName())
		end
		return "@MobileLiezhiCard=.->" .. table.concat(tos, "+")
	end
	return "."
end

--悍勇
sgs.ai_skill_invoke.hanyong = function(self, data)
	local use = data:toCardUse()
	local earnings = 0
	local need = nil
	if use.card:isKindOf("SavageAssault") then need = "Slash"
	elseif use.card:isKindOf("ArcheryAttack") then need = "Jink" end
	if not need then return false end
	
	for _, enemy in ipairs(self.enemies) do
		if self:hasTrickEffective(use.card, enemy, from) and not enemy:hasArmorEffect("vine") and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and
			getCardsNum(need, enemy, self.player) == 0 then
			earnings = earnings + 1
			if self:isWeak(enemy) then
				earnings = earnings + 1
			end
			if self:hasEightDiagramEffect(enemy) and need == "Jink" then
				earnings = earnings - 1
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if not friend:hasArmorEffect("vine") and self:hasTrickEffective(use.card, friend, from) and self:damageIsEffective(friend, sgs.DamageStruct_Normal, self.player) and
			getCardsNum(need, friend, self.player) == 0 then
			earnings = earnings - 1
			if self:isWeak(friend) then
				earnings = earnings - 1
			end
			if self:hasEightDiagramEffect(friend) and need == "Jink" then
				earnings = earnings + 1
			end
		else
			earnings = earnings + 1
		end
	end
	return earnings >= 0
end

--十周年悍勇

--狼袭
sgs.ai_skill_playerchosen.langxi = function(self, targets)
	local tos = self:findPlayerToDamage(2, self.player, DamageStruct_Normal, targets, false, 0, true)
	if #tos > 0 then
		for _, p in ipairs(tos) do
			if self:cantDamageMore(self.player, p) then continue end
			return p
		end
		return tos[1]
	end
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() <= self.player and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantDamageMore(self.player, enemy) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() <= self.player and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) then
			return enemy
		end
	end
	return nil
end

--亦算
sgs.ai_skill_invoke.yisuan = function(self, data)
	local card = self.player:getTag("yisuanForAI"):toCard()
	if not card or self.player:getMaxHp() <= 3 then return false end
	if card:isKindOf("AOE") and self:getAoeValue(card) > 0 then return true end
	if card:isKindOf("Duel") and self:willUse(self.player, card) then return true end
	if card:isKindOf("ExNihilo") and self:getOverflow() <= -2 and self.player:getLostHp() > 0 and self:canDraw() then return true end
	if (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:willUse(self.player, card) and self.player:getLostHp() > 0 then return true end
	return false
end

--兴乱
sgs.ai_skill_invoke.xingluan = true

--贪狈
local tanbei_skill = {}
tanbei_skill.name = "tanbei"
table.insert(sgs.ai_skills, tanbei_skill)
tanbei_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("TanbeiCard") then
		return sgs.Card_Parse("@TanbeiCard=.")
	end
end

sgs.ai_skill_use_func.TanbeiCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if ((friend:isNude() and not friend:isAllNude() and not friend:containsTrick("YanxiaoCard")) or
			(friend:isKongcheng() and friend:getJudgingArea():isEmpty() and self:needToThrowArmor(friend) and friend:getEquips():length() == 1) or
			(friend:getJudgingArea():isEmpty() and friend:getEquips():isEmpty() and self:needToThrowLastHandcard(friend))) then
			use.card = card
			if use.to then use.to:append(friend) end return
		end
	end
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if self:doNotDiscard(enemy, "hej") or (enemy:isNude() and not enemy:isAllNude()) then continue end
		use.card = card
		if use.to then use.to:append(enemy) end return
	end
end

sgs.ai_use_priority.TanbeiCard = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value.TanbeiCard = 7

sgs.ai_card_intention.TanbeiCard = function(self, card, from, tos)
	local to = tos[1]
	if ((to:isNude() and not to:isAllNude() and not to:containsTrick("YanxiaoCard")) or
		(to:isKongcheng() and to:getJudgingArea():isEmpty() and self:needToThrowArmor(to) and to:getEquips():length() == 1) or
		(to:getJudgingArea():isEmpty() and to:getEquips():isEmpty() and self:needToThrowLastHandcard(to))) then
		sgs.updateIntention(from, to, -80)
	else
		sgs.updateIntention(from, to, 80)
	end
end

sgs.ai_skill_choice.tanbei = function(self, choices, data)
	local from = data:toPlayer()
	if not from or from:isDead() then return "get" end
	if self:isFriend(from) then return "get" end
	if ((self.player:isNude() and not self.player:isAllNude() and not self.player:containsTrick("YanxiaoCard")) or
		(self.player:isKongcheng() and self.player:getJudgingArea():isEmpty() and self:needToThrowArmor(self.player) and self.player:getEquips():length() == 1) or
		(self.player:getJudgingArea():isEmpty() and self.player:getEquips():isEmpty() and self:needToThrowLastHandcard(self.player))) then
		return "get"
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	local slash_num = getCardsNum("Slash", from, self.player)
	if slash_num > 0 and self:slashIsEffective(slash, self.player, from) and self:damageIsEffective(self.player, DamageStruct_Normal, from) and
		self:getCardsNum("Jink") < slash_num then
		return "get"
	end
	return "nolimit"
end

--伺盗
sgs.ai_skill_use["@@sidao"] = function(self, prompt, method)
	local target_name = prompt:split(":")[2]
	if not target_name then return "." end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	for _,id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(cards, true)
	local sp = sgs.SPlayerList()
	local to = self.room:findPlayerByObjectName(target_name)
	if not to or to:isDead() then return "." end
	sp:append(to)
	for _,c in ipairs(cards) do
		if c:isKindOf("Peach") and self:isWeak(self.friends) then continue end
		local snatch = sgs.Sanguosha:cloneCard("snatch", c:getSuit(), c:getNumber())
        snatch:setSkillName("sidao")
        snatch:addSubcard(c)
        snatch:deleteLater()
		if not self.player:canUse(snatch, sp) then continue end
		if c:isKindOf("Snatch") and self.player:canUse(c, sp) then continue end
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:objectName() ~= target_name then
				table.insert(dummy_use.current_targets, p:objectName())
			end
		end
		self:useCardSnatchOrDismantlement(snatch, dummy_use)
		if dummy_use.card and dummy_use.to:length() > 0 then
			return "@SidaoCard=" .. c:getEffectiveId()
		end
	end
end

--荐杰
local jianjie_skill = {}
jianjie_skill.name = "jianjie"
table.insert(sgs.ai_skills, jianjie_skill)
jianjie_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	for _,friend in ipairs(self.friends) do
		if friend:getMark("&dragon_signet") > 0 and friend:getMark("&phoenix_signet") > 0 and friend:getHandcardNum() >= 4 then
			return
		end
	end
	if not self.player:hasUsed("JianjieCard") and self.player:getMark("jianjie_Round-Keep") > 1 then
		return sgs.Card_Parse("@JianjieCard=.")
	end
end

sgs.ai_skill_use_func.JianjieCard = function(card, use, self)
	local dragon_player = {}
	local phoenix_player = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("&dragon_signet") > 0 then
			table.insert(dragon_player, p)
		end
		if p:getMark("&phoenix_signet") > 0 then
			table.insert(phoenix_player, p)
		end
	end
	
	local no_dragon_friend_players = {}
	local no_phoenix_friend_players = {}
	self:updatePlayers()
	self:sort(self.friends, "handcard")
	self.friends = sgs.reverse(self.friends)
	for _,friend in ipairs(self.friends) do
		if friend:getMark("&dragon_signet") == 0 and friend:faceUp() then
			table.insert(no_dragon_friend_players, friend)
		end
		if friend:getMark("&phoenix_signet") == 0 and friend:faceUp() then
			table.insert(no_phoenix_friend_players, friend)
		end
	end
	if #dragon_player > 0 and #no_dragon_friend_players > 0 then
		if self:isEnemy(dragon_player[1]) and dragon_player[1]:objectName() ~= no_dragon_friend_players[1]:objectName() then
			use.card = card
			if use.to then
				use.to:append(dragon_player[1])
				use.to:append(no_dragon_friend_players[1])
			end
			return
		end
	end
	if #phoenix_player > 0 and #no_phoenix_friend_players > 0 then
		if self:isEnemy(phoenix_player[1]) and phoenix_player[1]:objectName() ~= no_phoenix_friend_players[1]:objectName() then
			use.card = card
			if use.to then
				use.to:append(phoenix_player[1])
				use.to:append(no_phoenix_friend_players[1])
			end
			return
		end
	end
	
	if #dragon_player > 0 and #no_dragon_friend_players > 0 and dragon_player[1]:getHandcardNum() <= 2 and no_dragon_friend_players[1]:getHandcardNum() > 2 then
		if self:isFriend(dragon_player[1]) and dragon_player[1]:objectName() ~= no_dragon_friend_players[1]:objectName() then
			use.card = card
			if use.to then
				use.to:append(dragon_player[1])
				use.to:append(no_dragon_friend_players[1])
			end
			return
		end
	end
	if #phoenix_player > 0 and #no_phoenix_friend_players > 0 and phoenix_player[1]:getHandcardNum() <= 2 and no_phoenix_friend_players[1]:getHandcardNum() > 2 then
		if self:isFriend(phoenix_player[1]) and phoenix_player[1]:objectName() ~= no_phoenix_friend_players[1]:objectName() then
			use.card = card
			if use.to then
				use.to:append(phoenix_player[1])
				use.to:append(no_phoenix_friend_players[1])
			end
			return
		end
	end
end

sgs.ai_use_priority.JianjieCard = 7
sgs.ai_use_value.JianjieCard = 7

sgs.ai_skill_choice.jianjie = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end

sgs.ai_skill_use["@@jianjie!"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if #targets < 2 then
			table.insert(targets, friend:objectName())
		end
	end
	local compareBySeat = function(a, b)
		player_a = self.room:findPlayerByObjectName(a)
		player_b = self.room:findPlayerByObjectName(b)
		return self:GetAskForPeachActionOrderSeat(player_a) > self:GetAskForPeachActionOrderSeat(player_b)
	end
	local unknown_num = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if sgs.ai_role[p:objectName()] == "neutral" then
			unknown_num = unknown_num + 1
		end
	end
	if #targets == 1 then
		if unknown_num > 0 then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if sgs.ai_role[p:objectName()] == "neutral" and #targets < 2 then
					table.insert(targets, p:objectName())
				end
			end
		else
			table.insert(targets, self.player:objectName())
		end
		table.sort(targets, compareBySeat)
		return "@JianjieCard=.->" .. table.concat(targets, "+")
	elseif #targets == 2 then
		table.sort(targets, compareBySeat)
		return "@JianjieCard=.->" .. table.concat(targets, "+")
	else
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if sgs.ai_role[p:objectName()] == "neutral" and #targets < 2 then
				table.insert(targets, p:objectName())
			end
		end
		if #targets == 1 then
			table.insert(targets, self.player:objectName())
			table.sort(targets, compareBySeat)
			return "@JianjieCard=.->" .. table.concat(targets, "+")
		elseif #targets == 2 then
			table.sort(targets, compareBySeat)
			return "@JianjieCard=.->" .. table.concat(targets, "+")
		else
			table.insert(targets, self.player:objectName())
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if #targets < 2 then
					table.insert(targets, p:objectName())
				end
			end
			table.sort(targets, compareBySeat)
			return "@JianjieCard=.->" .. table.concat(targets, "+")
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.jianjie_dragon = function(self, targets)
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do
		if p:isAlive() and p:getMark("&phoenix_signet") > 0 then
			return p
		end
	end
	--if #self.friends_noself > 0 then return self.friends_noself[1] end
	for _, p in ipairs(self.friends_noself) do
		if p:isAlive() then
			return p
		end
	end
	return self.player
end

sgs.ai_skill_playerchosen.jianjie_phoenix = function(self, targets)
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do
		if p:isAlive() and p:getMark("&dragon_signet") > 0 then
			return p
		end
	end
	--if #self.friends_noself > 0 then return self.friends_noself[1] end
	for _, p in ipairs(self.friends_noself) do
		if p:isAlive() then
			return p
		end
	end
	return self.player
end

--荐杰火计

--荐杰连环

--荐杰业炎

--称好
sgs.ai_skill_invoke.chenghao = true

sgs.ai_skill_askforyiji.chenghao = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end

--袭营

--第二版袭营

--乱战  --未测试
sgs.ai_skill_use["@@luanzhan"] = function(self, prompt, method)
	if self.player:hasFlag("luanzhan_now_use_collateral") then
		local card_str = self.player:property("extra_collateral"):toString()
		local card = sgs.Card_Parse(card_str)
		if not card then return "." end
		local tos = self.player:property("extra_collateral_current_targets"):toString():split("+")
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, name in ipairs(tos) do
			table.insert(dummy_use.current_targets, name)
		end
		self:useCardCollateral(card, dummy_use)
		if dummy_use.card and dummy_use.to:length() == 2 then
			return "@ExtraCollateralCard=.->" .. dummy_use.to:first() .. "+" .. dummy_use.to:last()
		end
	else
		local use = self.player:getTag("luanzhanData"):toCardUse()
		if not use then return "." end
		local n = self.player:getMark("luanzhan_target_num-Clear")
		local friends = {}
		for _, p in ipairs(self.friends_noself) do
			if not p:hasFlag("luanzhan_canchoose") then continue end
			table.insert(friends, p)
		end
		n = math.min(n, #friends)
		if n == 0 then return "." end
		local extra = {}
		if use.card:isKindOf("ExNihilo") then
			self:sort(friends, "defense")
			for _, p in ipairs(friends) do
				if self:canDraw(p) and #extra < n and p:hasFlag("luanzhan_canchoose") then
					table.insert(extra, p:objectName())
				end
			end
			if #extra > 0 then
				return "@LuanzhanCard=." .. table.concat(extra, "+")
			end
		else
			
		end
	end
	return "."
end

--内伐

--锋略
function fenglveJudge(player, self)
	if player:getJudgingArea():isEmpty() then return true end
	if player:getJudgingArea():length() == 1 and player:containsTrick("YanxiaoCard") then return true end
	local lightning = sgs.Sanguosha:cloneCard("lightning")
	lightning:deleteLater()
	if player:getJudgingArea():length() == 1 and player:containsTrick("lightning") and not self:willUseLightning(lightning) then return true end
	return false
end

sgs.ai_skill_playerchosen.fenglve = function(self, targets)
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	if not max_card then return nil end
	local max_point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then max_point = 13 end
	if max_point >= 7 then
		self.fenglve_card = max_card:getId()
		
		for _, p in ipairs(self.friends_noself) do
			if self:getOverflow(p) > 2 and not p:containsTrick("YanxiaoCard") and p:containsTrick("indulgence") then
				return p
			end
		end
		for _, p in ipairs(self.friends_noself) do
			if not p:containsTrick("YanxiaoCard") and p:containsTrick("lightning") then
				local lightning = sgs.Sanguosha:cloneCard("lightning")
				lightning:deleteLater()
				if not self:willUseLightning(lightning) then
					return p
				end
			end
		end
		
		local enemies = {}
		for _, p in ipairs(self.enemies) do
			if not fenglveJudge(p, self) then continue end
			if not p:getEquips():isEmpty() and not self:doNotDiscard(enemies, "e") then
				table.insert(enemies, p)
			end
		end
		if #enemies > 0 then
			self:sort(enemies, "handcard")
			for _, p in ipairs(enemies) do
				if p:getHandcardNum() > 1 and not self:doNotDiscard(p, "h") then
					return p
				end
			end
			for _, p in ipairs(enemies) do
				if not self:doNotDiscard(p, "h") then
					return p
				end
			end
		end
		
		self:sort(self.enemies, "handcard")
		for _, p in ipairs(self.enemies) do
			if not fenglveJudge(p, self) then continue end
			if p:getHandcardNum() > 1 and not self:doNotDiscard(p, "h") and not (not p:getEquips():isEmpty() and not self:doNotDiscard(p, "e")) then
				return p
			end
		end
		for _, p in ipairs(self.enemies) do
			if not fenglveJudge(p, self) then continue end
			if not self:doNotDiscard(p, "h") and not (not p:getEquips():isEmpty() and not self:doNotDiscard(p, "e")) then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.fenglve = function(self, from, to)
	if self:getOverflow(to) > 2 and not to:containsTrick("YanxiaoCard") and to:containsTrick("indulgence") then
		sgs.updateIntention(from, to, -80)
	elseif not to:containsTrick("YanxiaoCard") and to:containsTrick("lightning") then
		sgs.updateIntention(from, to, -80)
	else
		sgs.updateIntention(from, to, 80)
	end
end

function sgs.ai_skill_pindian.fenglve(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_skill_use["@@fenglve!"] = function(self, prompt, method)
	local give = {}
	if not self.player:isKongcheng() then
		local hands = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(hands, true)
		table.insert(give, hands[1]:getEffectiveId())
	end
	if not self.player:getEquips():isEmpty() then
		local id = self:disEquip(false, true)
		if id then table.insert(give, id) end
		
		local equips = self.player:getEquipsId()
		id = equips:at(math.random(0, equips:length() - 1))
		table.insert(give, id)
	end
	if not self.player:getJudgingArea():isEmpty() then
		if self.player:getJudgingArea():length() == 1 then  --不单独列出来，直接self:askForCardChosen游戏会崩
			table.insert(give, self.player:getJudgingAreaID():first())
		else
			local id = self:askForCardChosen(self.player, "j", "snatch")
			table.insert(give, id)
		end
	end
	return "@FenglveCard=" .. table.concat(give, "+")
end

--谋识
local moushi_skill = {}
moushi_skill.name = "moushi"
table.insert(sgs.ai_skills, moushi_skill)
moushi_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("MoushiCard") and #self.friends_noself > 0 and not self.player:isKongcheng() then
		return sgs.Card_Parse("@MoushiCard=.")
	end
end

sgs.ai_skill_use_func.MoushiCard = function(card, use, self)
	self:sort(self.friends_noself)
	local cards, slashs = sgs.QList2Table(self.player:getCards("h")), {}
	self:sortByUseValue(cards, true)
	if cards[1]:isKindOf("Analeptic") and self:isWeak() then return end
	if cards[1]:isKindOf("Jink") and self:isWeak() and self:getCardsNum("Jink") == 1 then return end
	for _, c in ipairs(cards) do
		if c:isKindOf("Slash") then
			table.insert(slashs, c)
		end
	end
	local id = -1
	if #slashs > 0 then id = slashs[1]:getEffectiveId() else id = cards[1]:getEffectiveId() end
	
	if #slashs > 0 then
		for _, p in ipairs(self.friends_noself) do
			if hasManjuanEffect(p) or self:needKongcheng(p, true) or p:hasSkills("jueqing|gangzhi") then continue end
			if not self:canUse(sgs.Sanguosha:getCard(id), self.enemies, p) then continue end
			use.card = sgs.Card_Parse("@MoushiCard=" .. id)
			if use.to then use.to:append(p) end return
		end
	end
	
	if self:getOverflow() >= 0 then
		sgs.ai_use_priority.MoushiCard = 0
		if #slashs > 0 then
			for _, p in ipairs(self.friends_noself) do
				if hasManjuanEffect(p) or self:needKongcheng(p, true) then continue end
				if not self:canUse(sgs.Sanguosha:getCard(id), self.enemies, p) then continue end
				use.card = sgs.Card_Parse("@MoushiCard=" .. id)
				if use.to then use.to:append(p) end return
			end
		end
		
		for _, p in ipairs(self.friends_noself) do
			if hasManjuanEffect(p) or self:needKongcheng(p, true) then continue end
			use.card = sgs.Card_Parse("@MoushiCard=" .. id)
			if use.to then use.to:append(p) end return
		end
	end
end

sgs.ai_use_priority.MoushiCard = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value.MoushiCard = 5

sgs.ai_card_intention.MoushiCard = function(self, card, from, tos)
	local to = tos[1]
	local intention = -70
	if hasManjuanEffect(to) then
		intention = 0
	elseif self:needKongcheng(to, true) then
		intention = 30
	end
	sgs.updateIntention(from, to, intention)
end

--击虚
local jixu_skill = {}
jixu_skill.name = "jixu"
table.insert(sgs.ai_skills, jixu_skill)
jixu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("JixuCard") then
		if self:getOverflow() <= 1 then
			sgs.ai_use_priority.JixuCard = sgs.ai_use_priority.Indulgence - 1
			sgs.ai_use_value.JixuCard = sgs.ai_use_value.Indulgence - 1
		else
			sgs.ai_use_priority.JixuCard = sgs.ai_use_priority.Slash - 1
			sgs.ai_use_value.JixuCard = sgs.ai_use_value.Slash - 1
		end
		return sgs.Card_Parse("@JixuCard=.")
	end
end

sgs.ai_skill_use_func.JixuCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies)
	if #self.enemies == 0 then return end
	use.card = card
	local target_hp = self.enemies[1]:getHp()
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == target_hp then
			if use.to then use.to:append(enemy) end
		end
	end
end

sgs.ai_card_intention.JixuCard = 10

sgs.ai_skill_choice.jixu = function(self, choices, data)
	local source = data:toPlayer()
	if not source then
		choices = choices:split("+")
		return choices[math.random(1, #choices)]
	end
	if source:isKongcheng() then return "not" end
	local know = 0
	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), source:objectName())
	for _,c in sgs.qlist(source:getCards("h")) do
		if (c:hasFlag("visible") or c:hasFlag(flag)) then
			know = know + 1
			if c:isKindOf("Slash") then
				return "has"
			end
		end
	end
	local handnum = source:getHandcardNum() - know
	if handnum >= 3 then return "has" end
	return "not"
end

--戡难
local kannan_skill = {}
kannan_skill.name = "kannan"
table.insert(sgs.ai_skills, kannan_skill)
kannan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("KannanCard") < self.player:getHp() and self.player:getMark("kannan-PlayClear") == 0 and self.player:canPindian() then
		return sgs.Card_Parse("@KannanCard=.")
	end
end

sgs.ai_skill_use_func.KannanCard = function(card, use, self)
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
	if min_card then
		local min_point = min_card:getNumber()
		if self.player:hasSkill("tianbian") and min_card:getSuit() == sgs.Card_Heart then min_point = 13 end
		if min_point < 7 then
			self:sort(self.friends_noself, "handcard")
			self.friends_noself = sgs.reverse(self.friends_noself)
			for _, p in ipairs(self.friends_noself) do
				if p:getMark("kannan_target-PlayClear") > 0 or not self.player:canPindian(p) then continue end
				if not self:needToThrowLastHandcard(p) then continue end
				self.kannan_card = min_card
				use.card = sgs.Card_Parse("@KannanCard=.")
				if use.to then use.to:append(p) end return
			end
			for _, p in ipairs(self.friends_noself) do
				if p:getMark("kannan_target-PlayClear") > 0 or not self.player:canPindian(p) then continue end
				self.kannan_card = min_card
				use.card = sgs.Card_Parse("@KannanCard=.")
				if use.to then use.to:append(p) end return
			end
		end
	end
	
	local max_card = self:getMaxCard(self.player, cards)
	if max_card then
		local max_point = max_card:getNumber()
		if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then max_point = 13 end
		if max_point >= 7 then
			self:sort(self.enemies, "handcard")
			for _, p in ipairs(self.enemies) do
				if p:getMark("kannan_target-PlayClear") > 0 or not self.player:canPindian(p) or self:doNotDiscard(p, "h") then continue end
				self.kannan_card = max_card
				use.card = sgs.Card_Parse("@KannanCard=.")
				if use.to then use.to:append(p) end return
			end
		end
	end
end

sgs.ai_use_priority.KannanCard = 7
sgs.ai_use_value.KannanCard = 7

function sgs.ai_skill_pindian.kannan(minusecard, self, requestor)
	return self:isFriend(requestor) and self:getMaxCard() or ( self:getMinCard():getNumber() > 6 and  minusecard or self:getMinCard() )
end

--集军
sgs.ai_skill_invoke.jijun = true

--方统
sgs.ai_skill_cardask["fangtong-invoke"] = function(self, data)
	return "."
end

sgs.ai_skill_use["@@fangtong!"] = function(self, prompt, method)
	return "."
end

--奋钺

--截刀
sgs.ai_skill_invoke.jiedao = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to) and not self:cantDamageMore(self.player, to)
end

sgs.ai_skill_choice.jiedao = function(self, choices, data)
	--[[local damage = data:toDamage()
	local to = damage.to
	choices = choices:split("+")
	if to:getHp() - damage.damage < tonumber(choices[1]) then return choices[1] end
	if to:getHp() - damage.damage > tonumber(choices[#choices]) then return choices[#choices] end
	return "" .. to:getHp()]]
	choices = choices:split("+")
	return choices[#choices]
end

sgs.ai_skill_discard.jiedao = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", min_num, min_num, false, true)
end

--虚猲
sgs.ai_skill_invoke.xuhe = function(self, data)
	local num = 0
	local maxhp = self.player:getMaxHp()
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMaxHp() > maxhp then
			num = 1
			break
		end
	end
	if maxhp - 1 + num < 3 then return false end
	
	num = 0
	self.xuhe_choice = nil
	local can_dis = false
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:distanceTo(p) <= 1 then
			if self.player:canDiscard(p, "he") then
				can_dis = true
				if self:isFriend(p) then
					num = num + 1
					if self:doNotDiscard(p, "e") or self:doNotDiscard(p, "h") then
						num = num - 2
					end
				elseif self:isEnemy(p) then
					num = num - 1
					if self:doNotDiscard(p, "he") then
						num = num + 2
					end
				end
			end
		end
	end
	if num <= 0 and can_dis then 
		sgs.ai_skill_choice.xuhe = "discard"
		return true
	end
	
	num = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:distanceTo(p) <= 1 then
			if self:isFriend(p) and self:canDraw(p) then num = num + 1
			elseif self:isEnemy(p) and self:canDraw(p) then num = num - 1 end
		end
	end
	if num >= 0 then
		sgs.ai_skill_choice.xuhe = "draw"
		return true
	end
	
	return false
end

sgs.ai_skill_choice.xuhe = function(self, choices)
	if not self:canDraw() or not self:isWeak() then return "selfdraw" end
	return "recover"
end

--利熏
sgs.ai_skill_discard.lixun = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummy", discard_num, discard_num, false, false)
end

--馈珠
sgs.ai_skill_playerchosen.spkuizhu = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	if math.min(5, targets[1]:getHandcardNum()) <= self.player:getHandcardNum() then return nil end
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_use["@@spkuizhu"] = function(self, prompt)
	local hands = sgs.QList2Table(self.player:getCards("h"))
	local name = prompt:split(":")[2]
	if not name then return "." end
	local from = self.room:findPlayerByObjectName(name)
	if not from or from:isDead() then return "." end
	--[[local piles = {}
	for _,id in sgs.qlist(self.player:getPile("#spkuizhu")) do  --认为是empty
		table.insert(piles, sgs.Sanguosha:getCard(id))
	end]]
	local piles = sgs.QList2Table(from:getCards("h"))
	
	if #hands == 0 or #piles == 0 then return "." end
	
	local exchange_pile = {}
	local exchange_handcard = {}
	self:sortByCardNeed(hands)
	self:sortByCardNeed(piles)
	local max_num = math.min(#hands, #piles)
	for i = 1 , max_num, 1 do
		if self:cardNeed(piles[#piles]) > self:cardNeed(hands[1]) then
			table.insert(exchange_handcard, piles[#piles])
			table.insert(exchange_pile, hands[1])
			table.removeOne(piles, piles[#piles])
			table.removeOne(hands, hands[1])
		else
			break
		end
	end
	if #exchange_handcard == 0 then return "." end
	local exchange = {}

	for _, c in ipairs(exchange_handcard) do
		table.insert(exchange, c:getId())
	end

	for _, c in ipairs(exchange_pile) do
		table.insert(exchange, c:getId())
	end
	
	return "@SpKuizhuCard=" .. table.concat(exchange, "+")
end

--义襄
sgs.ai_skill_invoke.yixiang = function(self, data)
	return self:canDraw()
end

--揖让
sgs.ai_skill_playerchosen.yirang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "maxhp")
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets) do
		if self:canDraw(p) and self:isFriend(p) then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if hasManjuanEffect(p) then
			return p
		end
	end
	return nil
end

--评才
local pingcai_skill = {}
pingcai_skill.name = "pingcai"
table.insert(sgs.ai_skills, pingcai_skill)
pingcai_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("PingcaiCard") then
		return sgs.Card_Parse("@PingcaiCard=.")
	end
end

sgs.ai_skill_use_func.PingcaiCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.PingcaiCard = 10
sgs.ai_use_value.PingcaiCard = 5

function pingcaiMoveArmor(self)
	local friends = {}
	for _, p in ipairs(self.friends) do
		if not p:hasEquipArea(1) or p:getArmor() then continue end
		table.insert(friends, p)
	end
	if #friends == 0 then return {} end
	self:sort(friends)
	self:sort(self.friends_noself)
	self:sort(self.enemies)
	
	local pingcai = {}
	
	for _, p in ipairs(self.friends_noself) do
		if p:getArmor() and self:needToThrowArmor(p) then
			table.insert(pingcai, p)
			for _, q in ipairs(friends) do
				if q:objectName() ~= p:objectName() and q:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill) then
					table.insert(pingcai, q)
					return pingcai
				end
			end
			for _, q in ipairs(friends) do
				if q:objectName() ~= p:objectName() then
					table.insert(pingcai, q)
					return pingcai
				end
			end
		end
	end
	
	for _, p in ipairs(self.friends_noself) do
		if p:getArmor() and self:hasSkills(sgs.lose_equip_skill, p) then
			table.insert(pingcai, p)
			for _, q in ipairs(friends) do
				if q:objectName() ~= p:objectName() and q:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill) then
					table.insert(pingcai, q)
					return pingcai
				end
			end
			for _, q in ipairs(friends) do
				if q:objectName() ~= p:objectName() then
					table.insert(pingcai, q)
					return pingcai
				end
			end
		end
	end
	
	for _, p in ipairs(self.enemies) do
		if p:getArmor() and not self:doNotDiscard(p, "e") then
			table.insert(pingcai, p)
			for _, q in ipairs(friends) do
				if q:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill) then
					table.insert(pingcai, q)
					return pingcai
				end
			end
			table.insert(pingcai, friends[1])
			return pingcai
		end
	end
	
	return pingcai
end

sgs.ai_skill_choice.pingcai = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "pcxuanjian") then
		for _,p in ipairs(self.friends) do
			if self:isWeak(p) and p:getLostHp() > 0 and not self:needKongcheng(p, true) then
				return "pcxuanjian"
			end
		end
	end
	if table.contains(choices, "pcwolong") then
		for _, p in ipairs(self.enemies) do
			if self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) and self:hasHeavyDamage(self.player, nil, p, "fire") then
				return "pcwolong"
			end
		end
	end
	if table.contains(choices, "pcxuanjian") then
		for _,p in ipairs(self.enemies) do
			if p:getLostHp() == 0 and self:needKongcheng(p, true) and not hasManjuanEffect(p) and self:getEnemyNumBySeat(self.player, p, p) > 0 then
				return "pcxuanjian"
			end
		end
	end
	if table.contains(choices, "pcfengchu") and #choices > 1 then
		local fengchu = false
		for _,p in ipairs(self.enemies) do
			if not p:isChained() and not p:hasSkill("qianjie") then
				fengchu = true
				break
			end
		end
		if not fengchu then table.removeOne(choices, "pcfengchu") end
	end
	if table.contains(choices, "pcshuijing") and #choices > 1 then
		local shuijing = false
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if string.find(sgs.Sanguosha:translate(p:getGeneralName()), "司马徽") or string.find(sgs.Sanguosha:translate(p:getGeneral2Name()), "司马徽") then
				shuijing = true
				break
			end
		end
		if shuijing then
			local from, card, to = self:moveField(nil, "e")
			if not from or not card or not to then
				table.removeOne(choices, "pcshuijing")
			end
		else
			if #pingcaiMoveArmor(self) == 0 then
				table.removeOne(choices, "pcshuijing")
			end
		end
	end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen.pingcai_wolong = function(self, targets)
	local to = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Fire, targets, true)
	if to then return to end
	self:sort(self.enemies, "hp")
	for _,p in ipairs(self.enemies) do
		if self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
			return p
		end
	end
	return self.enemies[math.random(1, #self.enemies)]
end

sgs.ai_skill_use["@@pingcai1"] = function(self, prompt)
	local tos = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Fire, targets, true, 0, true)
	if #tos > 0 then
		local targets = {}
		for _,p in ipairs(tos) do
			table.insert(targets, p:objectName())
		end
		return "@PingcaiWolongCard=.->" .. table.concat(targets, "+")
	end
	return "."
end

sgs.ai_playerchosen_intention.pingcai_wolong = 80
sgs.ai_card_intention.PingcaiWolongCard = 80

sgs.ai_skill_use["@@pingcai2"] = function(self, prompt)
	local tos = {}
	local mark = self.player:getMark("pingcai_fengchu_mark-Clear")
	for _,p in ipairs(self.enemies) do
		if not p:isChained() and #tos < mark and not p:hasSkill("qianjie") then
			table.insert(tos, p:objectName())
		end
	end
	if #tos == 0 then return "." end
	return "@PingcaiFengchuCard=.->" .. table.concat(tos, "+")
end

sgs.ai_card_intention.PingcaiFengchuCard = 30

sgs.ai_skill_playerchosen.pingcai_xuanjian = function(self, targets)
	self:sort(self.friends, "hp")
	for _, p in ipairs(self.friends) do
		if p:getLostHp() > 0 and self:isWeak(p) and not self:needKongcheng(p, true) then
			return p
		end
	end
	for _, p in ipairs(self.friends) do
		if p:getLostHp() > 0 and not self:needKongcheng(p, true) and not hasManjuanEffect(p) then
			return p
		end
	end
	for _, p in ipairs(self.friends) do
		if p:getLostHp() > 0 and not self:needKongcheng(p, true) then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if p:getLostHp() == 0 and self:needKongcheng(p, true) and not hasManjuanEffect(p) then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.pingcai_xuanjian = function(self, from, to)
	local intention = -50
	if to:getLostHp() == 0 and self:needKongcheng(to, true) and not hasManjuanEffect(to) then
		intention = 50
	end
	sgs.updateIntention(from, to, intention)
end

sgs.ai_skill_playerchosen.pingcai_from = function(self, targets)
	local from, card, to = self:moveField(nil, "e")
		if from then return from
	end
end

sgs.ai_skill_cardchosen.pingcai = function(self, who, flags)
	local from, card, to = self:moveField(nil, "e")
	if card then return card end
end

sgs.ai_skill_playerchosen.pingcai_to = function(self, targets)
	local from, card, to = self:moveField(nil, "e")
		if to then return to
	end
end

sgs.ai_skill_playerchosen.pingcai_shuijing_from = function(self, targets)
	local pingcai = pingcaiMoveArmor(self)
	if #pingcai == 2 then return pingcai[1] end
	return targets:at(math.random(0, targets:length() - 1))
end

sgs.ai_skill_playerchosen.pingcai_shuijing_to = function(self, targets)
	local pingcai = pingcaiMoveArmor(self)
	if #pingcai == 2 then return pingcai[2] end
	return targets:at(math.random(0, targets:length() - 1))
end

--持节
sgs.ai_skill_invoke.chijiec = true

sgs.ai_skill_choice.chijiec = function(self, choices)
	if self.room:getLord() and self.player:isYourFriend(self.room:getLord()) then return self.room:getLord():getKingdom() end
	choices = choices:split(":")
	return choices[math.random(1, #choices)]
end

--外使
local waishi_skill = {}
waishi_skill.name = "waishi"
table.insert(sgs.ai_skills, waishi_skill)
waishi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("WaishiCard") < 1 + self.player:getMark("&waishi_extra") and not self.player:isNude() then
		return sgs.Card_Parse("@WaishiCard=.")
	end
end

sgs.ai_skill_use_func.WaishiCard = function(card, use, self)
	local kingdoms = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not table.contains(kingdoms, p:getKingdom()) then
			table.insert(kingdoms, p:getKingdom())
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
	local equip = 0
	local give = {}
	for _,c in ipairs(cards) do
		if #give >= #kingdoms then break end
		if c:isKindOf("Peach") or c:isKindOf("ExNihilo") or (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1) or (c:isKindOf("Analeptic") and self:isWeak()) then continue end
		table.insert(give, c:getEffectiveId())
		if self.player:getCards("e"):contains(c) then equip = equip + 1 end
	end
	if #give == 0 then return end
	
	local enemies = {}
    for _, enemy in ipairs(self.enemies) do
        if hasManjuanEffect(enemy, true) and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and
			not self:needToThrowLastHandcard(enemy, math.min(#give, enemy:getHandcardNum())) and enemy:getKingdom() == self.player:getKingdom() then
            table.insert(enemies, friend)
        end
    end
    if #enemies > 0 then
		self:sort(enemies)
		local give_cards = {}
		for i = 1, math.min(#give, enemies[1]:getHandcardNum()) do
			table.insert(give_cards, give[i])
		end
		if #give_cards > 0 then
			use.card = sgs.Card_Parse("@WaishiCard=" .. table.concat(give_cards, "+"))
			if use.to then use.to:append(enemies[1]) end return
		end
	end
	for _, enemy in ipairs(self.enemies) do
        if hasManjuanEffect(enemy, true) and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and
			not self:needToThrowLastHandcard(enemy, math.min(#give, enemy:getHandcardNum())) then
            table.insert(enemies, friend)
        end
    end
    if #enemies > 0 then
		self:sort(enemies)
		local give_cards = {}
		for i = 1, math.min(#give, enemies[1]:getHandcardNum()) do
			table.insert(give_cards, give[i])
		end
		if #give_cards > 0 then
			use.card = sgs.Card_Parse("@WaishiCard=" .. table.concat(give_cards, "+"))
			if use.to then use.to:append(enemies[1]) end return
		end
	end
	
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not hasManjuanEffect(enemy, true) and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and
			(enemy:getKingdom() == self.player:getKingdom() or enemy:getHandcardNum() + equip > self.player:getHandcardNum()) then
			use.card = sgs.Card_Parse("@WaishiCard=" .. table.concat(give, "+"))
			if use.to then use.to:append(enemy) end return
		end
	end
	
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and not friend:isKongcheng() and self:doNotDiscard(friend, "h") and
			(friend:getKingdom() == self.player:getKingdom() or friend:getHandcardNum() + equip > self.player:getHandcardNum()) then
			use.card = sgs.Card_Parse("@WaishiCard=" .. table.concat(give, "+"))
			if use.to then use.to:append(friend) end return
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if not hasManjuanEffect(enemy, true) and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") then
			use.card = sgs.Card_Parse("@WaishiCard=" .. table.concat(give, "+"))
			if use.to then use.to:append(enemy) end return
		end
	end
	
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and not friend:isKongcheng() and self:doNotDiscard(friend, "h") then
			use.card = sgs.Card_Parse("@WaishiCard=" .. table.concat(give, "+"))
			if use.to then use.to:append(friend) end return
		end
	end
end

sgs.ai_use_priority.WaishiCard = 0
sgs.ai_use_value.WaishiCard = 2

--忍涉
sgs.ai_skill_choice.renshe = function(self, choices)
	local new_choices = {}
	choices = choices:split("+")
	for _,choice in ipairs(choices) do
		if choice == "change" then continue end
		table.insert(new_choices, choice)
	end
	if self:canDraw() and self:findPlayerToDraw(false, 1) then
		return new_choices[math.random(1, #new_choices)]
	end
	return "extra"
end

sgs.ai_skill_choice.renshe_change = function(self, choices)
	choices = choices:split("+")
	if self.room:getLord() and self.player:isYourFriend(self.room:getLord()) and table.contains(choices, self.room:getLord():getKingdom()) then
		return self.room:getLord():getKingdom()
	end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen.renshe = function(self, targets)
	local target = self:findPlayerToDraw(false, 1)
	if target then return target end
	self:sort(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do
		if self:canDraw(p) then
			return p
		end
	end
	for _, p in ipairs(self.friends_noself) do
		if not hasManjuanEffect(p) and not self:needKongcheng(p, true) then
			return p
		end
	end
	for _, p in ipairs(self.friends_noself) do
		if not self:needKongcheng(p, true) then
			return p
		end
	end
	return self.friends_noself[math.random(1, #self.friends_noself)]
end

--血卫
sgs.ai_skill_playerchosen.xuewei = function(self, targets)
	if self:isWeak() and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 0 then return nil end
	self:sort(self.friends_noself, "hp")
	for _,p in ipairs(self.friends_noself) do
		if not self:isWeak(p) then continue end
		return p
	end
	return nil
end

--烈斥
sgs.ai_skill_discard.liechi = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummy", 1, 1, false, true)
end

--执义
sgs.ai_skill_choice.zhiyi = function(self, choices, data)
	local c = data:toCard()
	if (c:isKindOf("Peach") and self.player:getLostHp() < 2) or (c:isKindOf("Analeptic") and self:canDraw()) then
		return "draw"
	end
	if not c:targetFixed() then
		local card = sgs.Sanguosha:cloneCard(c:objectName())
		card:setSkillName("_zhiyi")
		card:deleteLater()
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardByClassName(card, dummyuse)
		if not dummyuse.card or dummyuse.to:isEmpty() then
			return "draw"
		end
	end
	return "use"
end

sgs.ai_skill_use["@@zhiyi!"] = function(self, prompt, method)
	local name = prompt:split(":")[2]
	if not name then return "." end
	local card = sgs.Sanguosha:cloneCard(name)
	card:setSkillName("_zhiyi")
	card:deleteLater()
	local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
	self:useCardByClassName(card, dummyuse)
	if dummyuse.card and not dummyuse.to:isEmpty() then
		return "@ZhiyiCard=.->" .. dummyuse.to:first():objectName()
	end
	--return card:toString()
	return "."
end

--第二版执义
sgs.ai_skill_choice.secondzhiyi = function(self, choices, data)
	choices = choices:split("+")
	local cards = {}
	for _,choice in ipairs(choices) do
		if choice == "draw" then continue end
		local card = sgs.Sanguosha:cloneCard(choice)
		card:setSkillName("_secondzhiyi")
		card:deleteLater()
		if card:targetFixed() then
			if card:isKindOf("Analeptic") then
				continue
			end
		else
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useCardByClassName(card, dummyuse)
			if dummyuse.card and not dummyuse.to:isEmpty() then
				table.insert(cards, card)
			end
		end
	end
	if #cards > 0 then
		self:sortByUseValue(cards)
		return cards[1]:objectName()
	end
	
	if table.contains(choices, "analeptic") and not self:canDraw() then return "analeptic" end
	return "draw"
end

sgs.ai_skill_use["@@secondzhiyi!"] = function(self, prompt, method)
	local name = prompt:split(":")[2]
	if not name then return "." end
	local card = sgs.Sanguosha:cloneCard(name)
	card:setSkillName("_secondzhiyi")
	card:deleteLater()
	local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
	self:useCardByClassName(card, dummyuse)
	if dummyuse.card and not dummyuse.to:isEmpty() then
		return "@SecondZhiyiCard=.->" .. dummyuse.to:first():objectName()
	end
	return "."
end

--急盟
sgs.ai_skill_playerchosen.jimeng = function(self, targets)
	if self.player:getHp() > 1 then return nil end
	return self:findPlayerToDiscard("he", false, false)
end

sgs.ai_skill_discard.jimeng = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local dis = {}
	for i = 1, math.min(#cards, min_num) do
		table.insert(dis, cards[i]:getEffectiveId())
	end
	return dis
end

--率言
sgs.ai_skill_invoke.shuaiyan = function(self, data)
	local target = self:findPlayerToDiscard("he", false, false)
	if target then
		sgs.ai_skill_playerchosen.shuaiyan = target
		return true
	end
	return false
end

sgs.ai_skill_discard.shuaiyan = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	return {cards[1]:getEffectiveId()}
end

--托孤
sgs.ai_skill_invoke.tuogu = function(self, data)
	local who = data:toPlayer()
	local good, bad = false, false
	local g = sgs.Sanguosha:getGeneral(who:getGeneralName())
	for _,skill in sgs.qlist(g:getSkillList()) do
		if not skill:isVisible() then continue end
		if skill:isLimitedSkill() or skill:getFrequency() == sgs.Skill_Wake then continue end
		if skill:isLordSkill() then continue end
		if string.find(sgs.bad_skills, skill:objectName()) then
			bad = true
			continue
		end
		good = true
	end
	if who:getGeneral2() then
		local g2 = sgs.Sanguosha:getGeneral(who:getGeneral2Name())
		for _,skill in sgs.qlist(g2:getSkillList()) do
			if not skill:isVisible() then continue end
			if skill:isLimitedSkill() or skill:getFrequency() == sgs.Skill_Wake then continue end
			if skill:isLordSkill() then continue end
			if string.find(sgs.bad_skills, skill:objectName()) then
				bad = true
				continue
			end
			good = true
		end
	end
	
	if self:isFriend(who) and good then return true end
	if not self:isFriend(who) and not bad then return true end
	return false
end

sgs.ai_skill_choice.tuogu = function(self, choices, data)
	local who = data:toPlayer()
	choices = choices:split("+")
	if self:isFriend(who) then
		for _,choice in ipairs(choices) do
			if self:isValueSkill(choice, who, true) then
				return choice
			end
		end
		for _,choice in ipairs(choices) do
			if self:isValueSkill(choice, who) then
				return choice
			end
		end
		for _,choice in ipairs(choices) do
			if string.find(sgs.bad_skills, choice) then continue end
			return choice
		end
		return choices[math.random(1, #choices)]
	else
		for _,choice in ipairs(choices) do
			if string.find(sgs.bad_skills, choice) then
				return choice
			end
		end
		for _,choice in ipairs(choices) do
			if self:isValueSkill(choice, who) then continue end
			return choice
		end
		for _,choice in ipairs(choices) do
			if self:isValueSkill(choice, who, true) then continue end
			return choice
		end
		return choices[math.random(1, #choices)]
	end
end

--擅专
sgs.ai_skill_invoke.shanzhuan = function(self, data)
	local to = data:toPlayer()
	if to then return not self:isFriend(to) end
	if data:toString() == "draw" then return self:canDraw() end
	return false
end

--第二版托孤
sgs.ai_skill_invoke.secondtuogu = function(self, data)
	return sgs.ai_skill_invoke.tuogu(self, data)
end

sgs.ai_skill_choice.secondtuogu = function(self, choices, data)
	return sgs.ai_skill_choice.tuogu(self, choices, data)
end

--诤荐
sgs.ai_skill_playerchosen.zhengjian = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getMark("&zhengjian") <= 0 then return p end
	end
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if not self:isFriend(p) and p:getMark("&zhengjian") <= 0 then return p end
	end
	
	return self.player
end

--告援
sgs.ai_skill_use["@@gaoyuan"] = function(self, prompt, method)
	local tos, source = {}, nil
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("GaoyuanSlashSource") then
			source = p
			break
		end
	end
	if not source then return "." end
	local slash = sgs.Card_Parse(self.player:property("gaoyuan"):toString())
	if not slash then return "." end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("&zhengjian") > 0 and not p:hasFlag("GaoyuanSlashSource") and source:canSlash(p, slash, false) then
			table.insert(tos, p)
		end
	end
	if #tos == 0 then return "." end
	
	local id = -1
	if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		for _,c in ipairs(cards) do
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				id = c:getEffectiveId()
				break
			end
		end
	end
	if id < 0 then return "." end
	
	self:sort(tos)
	for _, p in ipairs(tos) do
		if self:isEnemy(p) and self:slashIsEffective(slash, p, source) and not p:hasArmorEffect("eight_diagram") then
			return "@GaoyuanCard=" .. id .. "->" .. p:objectName()
		end
	end
	for _, p in ipairs(tos) do
		if self:isEnemy(p) and self:slashIsEffective(slash, p, source) then
			return "@GaoyuanCard=" .. id .. "->" .. p:objectName()
		end
	end
	
	for _, p in ipairs(tos) do
		if not self:isFriend(p) and self:slashIsEffective(slash, p, source) and not p:hasArmorEffect("eight_diagram") then
			return "@GaoyuanCard=" .. id .. "->" .. p:objectName()
		end
	end
	for _, p in ipairs(tos) do
		if not self:isFriend(p) and self:slashIsEffective(slash, p, source) then
			return "@GaoyuanCard=" .. id .. "->" .. p:objectName()
		end
	end
	
	for _, p in ipairs(tos) do
		if self:isFriend(p) and not self:slashIsEffective(slash, p, source) then
			return "@GaoyuanCard=" .. id .. "->" .. p:objectName()
		end
	end
	
	if self:isWeak() then
		tos = sgs.reverse(tos)
		for _, p in ipairs(tos) do
			if self:isFriend(p) and p:hasArmorEffect("eight_diagram") and not self:isWeak(p) then
				return "@GaoyuanCard=" .. id .. "->" .. p:objectName()
			end
		end
		
		for _, p in ipairs(tos) do
			if self:isFriend(p) and not self:isWeak(p) then
				return "@GaoyuanCard=" .. id .. "->" .. p:objectName()
			end
		end
	end
	
	return "."
end

--让节
sgs.ai_skill_invoke.rangjie = function(self, data)
	if not self.room:canMoveField("ej") and not self:canDraw() then return false end
	if self:canDraw() then return true end
	local from, card, to = self:moveField()
	if from and card and to then return true end
	return false
end

sgs.ai_skill_choice.rangjie = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "move") then
		local from, card, to = self:moveField()
		if from and card and to then return "move" end
		table.removeOne(choices, "move")
	end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen.rangjie_from = function(self, targets)
	local from, card, to = self:moveField()
		if from then return from
	end
end

sgs.ai_skill_cardchosen.rangjie = function(self, who, flags)
	local from, card, to = self:moveField()
	if card then return card end
end

sgs.ai_skill_playerchosen.rangjie_to = function(self, targets)
	local from, card, to = self:moveField()
		if to then return to
	end
end

--义争
local yizheng_skill = {}
yizheng_skill.name = "yizheng"
table.insert(sgs.ai_skills, yizheng_skill)
yizheng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("YizhengCard") then return end
	return sgs.Card_Parse("@YizhengCard=.")
end

sgs.ai_skill_use_func.YizhengCard = function(card, use, self)
	local max_card = self:getMaxCard()
	if not max_card then return end
	local point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then point = 13 end
	if (self.player:getMaxHp() <= 3 and point >=10) or point >= 7 then
		self:sort(self.enemies, "handcard")
		for _, p in ipairs(self.enemies) do
			if not self.player:canPindian(p) or self:doNotDiscard(p, "h") then continue end
			local maxcard = self:getMaxCard(p)
			if maxcard then
				local number = maxcard:getNumber()
				if p:hasSkill("tianbian") and maxcard:getSuit() == sgs.Card_Heart then number = 13 end
				if number < point then
					use.card = sgs.Card_Parse("@YizhengCard=.")
					self.yizheng_card = max_card:getEffectiveId()
					if use.to then use.to:append(p) end return
				end
			end
		end
	end
end

function sgs.ai_skill_pindian.yizheng(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_use_priority.YizhengCard = 7
sgs.ai_use_value.YizhengCard = 2
sgs.ai_card_intention.YizhengCard = 50

--知略
local xingzhilve_skill = {}
xingzhilve_skill.name = "xingzhilve"
table.insert(sgs.ai_skills, xingzhilve_skill)
xingzhilve_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("XingZhilveCard") then return end
	if self.player:getHp() > 1 then
		return sgs.Card_Parse("@XingZhilveCard=.")
	end
	if self.player:getHp() <= 1 and (hasBuquEffect(self.player) or self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0) then
		return sgs.Card_Parse("@XingZhilveCard=.")
	end
end

sgs.ai_skill_use_func.XingZhilveCard = function(card, use, self)
	if self.room:canMoveField() then
		local from, card, to = self:moveField()
		if from and card and to then
			use.card = sgs.Card_Parse("@XingZhilveCard=.")
			sgs.ai_skill_choice.xingzhilve = "move"
			return
		end
	end
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_xingzhilve")
	slash:deleteLater()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		use.card = sgs.Card_Parse("@XingZhilveCard=.")
		sgs.ai_skill_choice.xingzhilve = "draw"
	end
end

sgs.ai_skill_playerchosen.xingzhilve_from = function(self, targets)
	local from, card, to = self:moveField()
		if from then return from
	end
end

sgs.ai_skill_cardchosen.xingzhilve = function(self, who, flags)
	local from, card, to = self:moveField()
	if card then return card end
end

sgs.ai_skill_playerchosen.xingzhilve_to = function(self, targets)
	local from, card, to = self:moveField()
		if to then return to
	end
end

sgs.ai_skill_use["@@xingzhilve!"] = function(self, prompt)
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_xingzhilve")
	slash:deleteLater()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		return "@XingZhilveSlashCard=.->" .. dummy_use.to:first():objectName()
	end
	return "."
end

sgs.ai_use_priority.XingZhilveCard = 0
sgs.ai_use_value.XingZhilveCard = 2.5

--威风
sgs.ai_skill_playerchosen.xingweifeng = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _,p in ipairs(targets) do
		if not self:isFriend(p) then return p end
	end
	return targets[#targets]
end

--治严
local xingzhiyan_skill = {}
xingzhiyan_skill.name = "xingzhiyan"
table.insert(sgs.ai_skills, xingzhiyan_skill)
xingzhiyan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("xingzhiyan_give-PlayClear") <= 0 and self.player:getHandcardNum() > self.player:getHp() and not self.player:isKongcheng() then
		return sgs.Card_Parse("@XingZhiyanCard=.")
	end
	if self.player:getMark("xingzhiyan_draw-PlayClear") <= 0 and self.player:getMaxHp() > self.player:getHandcardNum() and self:canDraw() then
		return sgs.Card_Parse("@XingZhiyanDrawCard=.")
	end
end

sgs.ai_skill_use_func.XingZhiyanCard = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local num = self.player:getHandcardNum() - self.player:getHp()
	local give = {}
	for _,c in ipairs(cards) do
		if #give < num then
			table.insert(give, c:getEffectiveId())
		else
			break
		end
	end
	if #give == 0 then return end
	self:sort(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do
		if hasManjuanEffect(p) or self:needKongcheng(p, true) then continue end
		if p:hasSkills(sgs.cardneed_skill) then
			use.card = sgs.Card_Parse("@XingZhiyanCard=" .. table.concat(give, "+"))
			if use.to then use.to:append(p) end return
		end
	end
	for _, p in ipairs(self.friends_noself) do
		if hasManjuanEffect(p) or self:needKongcheng(p, true) then continue end
		use.card = sgs.Card_Parse("@XingZhiyanCard=" .. table.concat(give, "+"))
		if use.to then use.to:append(p) end return
	end
	
	self:sort(self.enemies)
	local c = sgs.Sanguosha:getCard(give[1])
	if #give == 1 and not (c:isKindOf("Jink") or c:isKindOf("Peach") or c:isKindOf("Analeptic") or c:isKindOf("ExNihilo") or c:isKindOf("AOE")) then
		sgs.ai_use_priority.XingZhiyanCard = 2
		for _, p in ipairs(self.enemies) do
			if not self:needKongcheng(p, true) or hasManjuanEffect(p, true) then continue end
			if self:getEnemyNumBySeat(self.player, p, p) == 0 then continue end
			use.card = sgs.Card_Parse("@XingZhiyanCard=" .. table.concat(give, "+"))
			if use.to then use.to:append(p) end return
		end
	end
	
	if self.player:getHandcardNum() - #give < self.player:getMaxHp() and self:canDraw() and self.player:getMark("xingzhiyan_draw-PlayClear") <= 0 then
		sgs.ai_use_priority.XingZhiyanCard = 1
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not hasManjuanEffect(p) then continue end
			use.card = sgs.Card_Parse("@XingZhiyanCard=" .. table.concat(give, "+"))
			if use.to then use.to:append(p) end return
		end
	end
end

sgs.ai_skill_use_func.XingZhiyanDrawCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.XingZhiyanCard = 8
sgs.ai_use_value.XingZhiyanCard = 8

sgs.ai_use_priority.XingZhiyanDrawCard = 0
sgs.ai_use_value.XingZhiyanDrawCard = 5

--锦帆

--射却

--第二版锦帆

--图射
sgs.ai_skill_invoke.tushe = function(self, data)
	return self:canDraw()
end

--立牧
local limu_skill = {}
limu_skill.name = "limu"
table.insert(sgs.ai_skills, limu_skill)
limu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:containsTrick("indulgence") and self.player:hasJudgeArea() then
		return sgs.Card_Parse("@LimuCard=.")
	end
end

sgs.ai_skill_use_func.LimuCard = function(card, use, self)
	local cards = {}
	local peach = 0
	
	local handcards = sgs.CardList()
	for _, c in sgs.qlist(self.player:getHandcards()) do
		handcards:append(c)
	end
	for _, id in sgs.qlist(self.player:getHandPile()) do
		handcards:append(sgs.Sanguosha:getCard(id))
	end
	
	for _, c in sgs.qlist(handcards) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			if c:getSuit() == sgs.Card_Diamond then
				local indulgence = sgs.Sanguosha:cloneCard("indulgence", c:getSuit(), c:getNumber())
				indulgence:addSubcard(c)
				indulgence:setSkillName("limu")
				indulgence:deleteLater()
				if not self.player:isLocked(indulgence) and not self.player:isProhibited(self.player, indulgence) then
					table.insert(cards, c)
				end
			end
		end
	end
	if #cards <= 0 then return end
	self:sortByKeepValue(cards)
	
	if self:isWeak() and self.player:getLostHp() > 0 then
		sgs.ai_use_priority.LimuCard = sgs.ai_use_priority.Peach - 0.1
		if cards[1]:isKindOf("Peach") then use.card = cards[1] return end
		use.card = sgs.Card_Parse("@LimuCard=" .. cards[1]:getEffectiveId())
		return
	end
	
	local slash_num = self:getCardsNum("Slash")
	local id = -1
	for _,c in ipairs(cards) do
		if isCard("Slash", c, self.player) then continue end
		id = c:getEffectiveId()
		break
	end
	if id < 0 then
		id = cards[1]:getEffectiveId()
		slash_num = slash_num - 1
	end
	
	local can_use_slash = false
	if slash_num > 1 then
		for _, slash in ipairs(self:getCards("Slash")) do
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useBasicCard(slash, dummyuse)
			if dummyuse.card and not dummyuse.to:isEmpty() then
				can_use_slash = true
			end
		end
	end
	if not can_use_slash then return end
	use.card = sgs.Card_Parse("@LimuCard=" .. id)
end

sgs.ai_use_priority.LimuCard = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value.LimuCard = sgs.ai_use_value.Slash - 0.1

--力激
local liji_skill = {}
liji_skill.name = "liji"
table.insert(sgs.ai_skills, liji_skill)
liji_skill.getTurnUseCard = function(self, inclusive)
	local alive = self.player:getMark("liji_alive_num-Clear")
	if alive <= 0 then return end
	local n = math.floor(self.player:getMark("&liji-Clear") / alive)
	if self.player:usedTimes("LijiCard") < n then
		return sgs.Card_Parse("@LijiCard=.")
	end
end

sgs.ai_skill_use_func.LijiCard = function(card, use, self)
	local target = self:findPlayerToDamage(1, self.player, nil, self.room:getOtherPlayers(self.player))
	if target then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then
			use.card = sgs.Card_Parse("@LijiCard=" .. self.player:getArmor():getEffectiveId())
			if use.to then use.to:append(target) end return
		end
		for _,c in ipairs(cards) do
			if c:isKindOf("Peach") then continue end
			if c:isKindOf("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then continue end
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				use.card = sgs.Card_Parse("@LijiCard=" .. c:getEffectiveId())
				if use.to then use.to:append(target) end return
			end
		end
	end
end

sgs.ai_use_priority.LijiCard = 2.5
sgs.ai_use_value.LijiCard = 2.5

--决死
local juesi_skill = {}
juesi_skill.name = "juesi"
table.insert(sgs.ai_skills, juesi_skill)
juesi_skill.getTurnUseCard = function(self, inclusive)
	return sgs.Card_Parse("@JuesiCard=.")
end

sgs.ai_skill_use_func.JuesiCard = function(card, use, self)
	local handcards = self.player:getHandcards()
	local slashs = {}
	for _,c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") and self.player:canDiscard(self.player, c:getEffectiveId()) then
			table.insert(slashs, c)
		end
	end
	if #slashs == 0 then return end
	self:sortByKeepValue(slashs)
	self:sort(self.enemies, "chaofeng")
	
	local enemys = {}
	for _, enemy in ipairs(self.enemies) do
		if not self.player:inMyAttackRange(enemy) then continue end
		if not enemy:canDiscard(enemy, "he") then continue end
		if self:doNotDiscard(enemy) and not (self:isWeak(enemy) and self.player:getHp() <= enemy:getHp()) then continue end
		if self:hasSkills(sgs.lose_equip_skill, enemy) and not (self:isWeak(enemy) and self.player:getHp() <= enemy:getHp()) then continue end
		if self:needToThrowLastHandcard(enemy) then continue end
		if self:getCardsNum("Slash") - 1 < getCardsNum("Slash", enemy) and self.player:getHp() <= enemy:getHp() then continue end
		table.insert(enemys, enemy)
	end
	if #enemys > 0 then
		use.card = sgs.Card_Parse("@JuesiCard=" .. slashs[1]:getEffectiveId())
		if use.to then use.to:append(enemys[1]) end return
	end
	
	if self:getOverflow() <= 0 then return end
	sgs.ai_use_priority.JuesiCard = 0
	local friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if self.player:getHp() <= friend:getHp() then continue end
		if not self.player:inMyAttackRange(friend) then continue end
		if self:needToThrowLastHandcard(friend) or (self:needToThrowArmor(friend) and friend:canDiscard(friend, friend:getArmor():getEffectiveId())) or self:hasSkills(sgs.lose_equip_skill, friend) then
			table.insert(friends, friend)
		end
	end
	if #friends > 0 then
		use.card = sgs.Card_Parse("@JuesiCard=" .. slashs[1]:getEffectiveId())
		if use.to then use.to:append(friends[1]) end return
	end
end

sgs.ai_use_priority.JuesiCard = sgs.ai_use_priority.Duel + 0.1
sgs.ai_use_value.JuesiCard = sgs.ai_use_value.Duel + 0.1

sgs.ai_skill_discard.juesi = function(self, discard_num, min_num, optional, include_equip)
	if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then return {self.player:getArmor():getEffectiveId()} end
	if self:needToThrowLastHandcard() and self.player:canDiscard(self.player, self.player:handCards():first()) then return {self.player:handCards():first()} end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local card = nil
	for _,c in ipairs(cards) do
		if self.player:canDiscard(self.player, c:getEffectiveId()) then
			card = c
			break
		end
	end
	if not card then return {} end
	
	local slashs = {}
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Slash") and self.player:canDiscard(self.player, c:getEffectiveId()) then
			table.insert(slashs, c)
		end
	end
	
	local source = self.player:getTag("juesiSource"):toPlayer()
	if not source or source:isDead() then return {card:getEffectiveId()} end
	if self.player:getHp() >= source:getHp() then
		if self:isEnemy(source) and self:getCardsNum("Slash") > getCardsNum("Slash", source) then
			if card:isKindOf("Slash") then
				for _, c in ipairs(cards) do
					if not c:isKindOf("Slash") and self.player:canDiscard(self.player, c:getEffectiveId()) then
						card = c
						break
					end
				end
			end
			return {card:getEffectiveId()}
		end
		if #slashs > 0 then return {slashs[1]:getEffectiveId()} end
		return {card:getEffectiveId()}
	end
	return {card:getEffectiveId()}
end

--誓仇
sgs.ai_skill_use["@@tenyearnewshichou"] = function(self, prompt)
	local use = self.player:getTag("tenyearnewshichou_data"):toCardUse()
	local dummyuse = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	for _, p in sgs.qlist(use.to) do
		table.insert(dummyuse.current_targets, p:objectName())
	end
	self:useCardSlash(use.card, dummyuse)
	if dummyuse.card and not dummyuse.to:isEmpty() then
		local lost = self.player:getLostHp()
		local num = 0
		local tos = {}
		for _,p in sgs.qlist(dummyuse.to) do
			if num >= lost then break end
			num = num + 1
			table.insert(tos, p:objectName())
		end
		if #tos > 0 then return "@TenyearNewShichouCard=.->" .. table.concat(tos, "+") end
	end
	return "."
end

--间书
--[[local jianshu_skill = {}
jianshu_skill.name = "jianshu"
table.insert(sgs.ai_skills, jianshu_skill)
jianshu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@jianshuMark") == 0 then return end
	local can_use = false
	self:sort(self.enemies, "chaofeng")
	for _, enemy_a in ipairs(self.enemies) do
		for _, enemy_b in ipairs(self.enemies) do
			if not enemy_a:canPindian(enemy_b) then continue end
			if not enemy_b:inMyAttackRange(enemy_a) then continue end
			can_use = true
			break
		end
		if can_use == true then break end
	end
	if can_use then
		return sgs.Card_Parse("@JianshuCard=.")
	end
end

sgs.ai_skill_use_func.JianshuCard = function(card, use, self)
	
end

sgs.ai_use_priority.JianshuCard = 0
sgs.ai_use_value.JianshuCard = 2.5
sgs.ai_card_intention.JianshuCard = 80]]

--拥嫡
function getYongdiTarget(self, targets, lord)
	local lords = {}
	local good_targets = {}
	local weaks = {}
	targets = sgs.QList2Table(targets)
	self:sort(targets, "chaofeng")
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if self:hasSkills(sgs.need_maxhp_skill, p) then
			table.insert(good_targets, p)
		end
		
		for _,skill in sgs.qlist(p:getGeneral():getVisibleSkillList()) do
			if skill:isLordSkill() and not p:hasLordSkill(skill, true) and (not lord or not p:isLord()) then
				table.insert(lords, p)
				break
			end
		end
		
		if not table.contains(lords, p) and p:getGeneral2() then
			for _,skill in sgs.qlist(p:getGeneral2():getVisibleSkillList()) do
				if skill:isLordSkill() and not p:hasLordSkill(skill, true) and (not lord or not p:isLord()) then
					table.insert(lords, p)
					break
				end
			end
		end
		if self:isWeak(p) then table.insert(weaks, p) end
	end
	
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if table.contains(lords, p) and table.contains(good_targets, p) and table.contains(weaks, p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if table.contains(lords, p) and table.contains(good_targets, p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if table.contains(good_targets, p) and table.contains(weaks, p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if table.contains(lords, p) and table.contains(weaks, p) then
			return p
		end
	end
	if #good_targets > 0 then return good_targets[1] end
	if #lords > 0 then return lords[1] end
	if #weaks > 0 then return weaks[1] end
	return nil
end

sgs.ai_skill_playerchosen.yongdi = function(self, targets)
	return getYongdiTarget(self, targets)
end

sgs.ai_playerchosen_intention.yongdi = -20

--第二版拥嫡
sgs.ai_skill_playerchosen.newyongdi = function(self, targets)
	return getYongdiTarget(self, targets, true)
end

sgs.ai_playerchosen_intention.newyongdi = sgs.ai_playerchosen_intention.yongdi

--雪恨
local newxuehen_skill = {}
newxuehen_skill.name = "newxuehen"
table.insert(sgs.ai_skills, newxuehen_skill)
newxuehen_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("NewxuehenCard") and self.player:getLostHp() > 0 then
		return sgs.Card_Parse("@NewxuehenCard=.")
	end
end

sgs.ai_skill_use_func.NewxuehenCard = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "hp")
	local targets = {}
	local lost = self.player:getLostHp()
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isChained() and not enemy:hasSkill("qianjie") and self:isWeak(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
			table.insert(targets, enemy)
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if #targets >= lost then break end
		if self:isWeak(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
			table.insert(targets, enemy)
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if #targets >= lost then break end
		if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) and not self:cantbeHurt(enemy) and not self:getDamagedEffects(enemy) and not self:needToLoseHp(enemy) then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		if c:isRed() and not c:isKindOf("Peach") and self.player:canDiscard(self.player, c:getEffectiveId()) then
			use.card = sgs.Card_Parse("@NewxuehenCard=" .. c:getEffectiveId())
			if use.to then
				for i = 1, #targets, 1 do
					use.to:append(targets[i])
				end
			end
			return
		end
	end
end

sgs.ai_use_priority.NewxuehenCard = 3
sgs.ai_use_value.NewxuehenCard = 2.35
sgs.ai_card_intention.NewxuehenCard = 20

sgs.ai_skill_playerchosen.newxuehen = function(self, targets)
	local to = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Fire, targets, false)
	if to then return to end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if not self:isEnemy(p) or not self:damageIsEffective(p, sgs.DamageStruct_Fire) then continue end
		return p
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) or not self:damageIsEffective(p, sgs.DamageStruct_Fire) then continue end
		return p
	end
	return targets[math.random(1, #targets)]
end

--应援
sgs.ai_skill_playerchosen.yingyuan = function(self, targets)
	local friends = {}
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	local card = self.player:getTag("yingyuanCard"):toCard()
	if card then
		for _,p in ipairs(targets) do
			if not self:isFriend(p) then continue end
			if (card:isKindOf("TrickCard") and p:hasSkills("tenyearjizhi|jizhi|nosjizhi")) or (card:isKindOf("EquipCard") and p:hasSkills(sgs.need_equip_skill.. "|qiangxi")) then  --极略不考虑了
				table.insert(friends, p)
			end
		end
	end
	if #friends > 0 then friends = sgs.reverse(friends) return friends[1] end
	for _,p in ipairs(targets) do
		if not self:isFriend(p) or self:needKongcheng(p, true) or hasManjuanEffect(p) then continue end
		return p
	end
	return nil
end

sgs.ai_playerchosen_intention.yingyuan = function(self, from, to)
	if hasManjuanEffect(to) then return end
	local intention = -20
	if self:needKongcheng(to, true) then intention = 20 end
	sgs.updateIntention(from, to, intention)
end

--手杀应援
sgs.ai_skill_playerchosen.mobileyingyuan = function(self, targets)
	local card = self.player:getTag("mobileyingyuanCard"):toCard()
	if card then
		local cards = {}
		if not card:isVirtualCard() then
			table.insert(cards, card)
		elseif card:subcardsLength() == 1 then
			table.insert(cards, sgs.Sanguosha:getCard(card:getSubcards():first()))
		end
		if #cards > 0 then
			local c, to = self:getCardNeedPlayer(cards)
			if to then return to end
		end
	end
	self:sort(self.friends_noself)
	for _,p in ipairs(self.friends_noself) do
		if not self:isFriend(p) or self:needKongcheng(p, true) or hasManjuanEffect(p) then continue end
		return p
	end
	return nil
end

sgs.ai_playerchosen_intention.mobileyingyuan = sgs.ai_playerchosen_intention.yingyuan

--鸩毒
sgs.ai_skill_cardask["@newzhendu-discard"] = function(self, data)
	local discard_trend = will_discard_zhendu(self, "newzhendu")
	if discard_trend <= 0 then return "." end
	if self.player:getHandcardNum() + math.random(1, 100) / 100 >= discard_trend then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not self:isValuableCard(card, self.player) then return "$" .. card:getEffectiveId() end
		end
	end
	return "."
end

--戚乱
sgs.ai_skill_invoke.newqiluan = function(self, data)
	return self:canDraw()
end

--励战
sgs.ai_skill_use["@@lizhan"] = function(self, prompt)
    local targets = {}
    for _, friend in ipairs(self.friends) do
        if friend:isWounded() and self:canDraw(friend) then
            table.insert(targets, friend:objectName())
        end 
    end
	for _, enemy in ipairs(self.enemies) do
        if enemy:isWounded() and self:needKongcheng(enemy, true) and not hasManjuanEffect(enemy) and self:getEnemyNumBySeat(self.player, enemy, enemy) > 0 then
            table.insert(targets, enemy:objectName())
        end 
    end
	if #targets == 0 then return "." end
    return "@LizhanCard=.->" .. table.concat(targets, "+")
end

sgs.ai_card_intention.LizhanCard = function(self, card, from, tos)
	local intention = -20
	for _,to in ipairs(tos) do
		if hasManjuanEffect(to) then continue end
		if self:needKongcheng(to, true) and self:getEnemyNumBySeat(from, to, to) > 0 then
			intention = 20
		end
		sgs.updateIntention(from, to, intention)
	end
end

--伪溃
local weikui_skill = {}
weikui_skill.name = "weikui"
table.insert(sgs.ai_skills, weikui_skill)
weikui_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("WeikuiCard") then return end
	if self.player:getHp() > 1 then
		return sgs.Card_Parse("@WeikuiCard=.")
	end
	if self.player:getHp() <= 1 and (hasBuquEffect(self.player) or self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0) then
		return sgs.Card_Parse("@WeikuiCard=.")
	end
end

sgs.ai_skill_use_func.WeikuiCard = function(card, use, self)
	self:sort(self.enemies)
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_weikui")
	slash:deleteLater()
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:isKongcheng() or self:doNotDiscard(enemy, "h") then continue end
		
		local jink, visible = 0, 0
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
		for _,c in sgs.qlist(enemy:getCards("h")) do
			if c:hasFlag("visible") or c:hasFlag(flag) then
				visible = visible + 1
				if c:isKindOf("Jink") then
					jink = jink + 1
				end
			end
		end
		
		if jink > 0 and (not self.player:canSlash(enemy, slash, false) or self:slashProhibit(slash, enemy)) then continue end
		if enemy:getHandcardNum() - visible > 2 and (not self.player:canSlash(enemy, slash, false) or self:slashProhibit(slash, enemy)) then continue end
		use.card = sgs.Card_Parse("@WeikuiCard=.")
		if use.to then use.to:append(enemy) end return
	end
end

sgs.ai_use_priority.WeikuiCard = sgs.ai_use_priority.Dismantlement - 0.1
sgs.ai_use_value.WeikuiCard = sgs.ai_use_value.Dismantlement - 0.1
sgs.ai_card_intention.WeikuiCard = 80

--影箭
sgs.ai_skill_use["@@yingjian"] = function(self, prompt)
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("yingjian")
	slash:deleteLater()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		return slash:toString()
	end
	return "."
end

--募兵

--资取

--调令
sgs.ai_skill_choice.diaoling = function(self, choice)
	if hasManjuanEffect(self.player) then return "recover" end
	if self:needToLoseHp() and not self:isWeak() then return "draw" end
	return "recover"
end

--谋诛

--延祸
sgs.ai_skill_invoke.spyanhuo = true

--备诛
local beizhu_skill = {}
beizhu_skill.name = "beizhu"
table.insert(sgs.ai_skills, beizhu_skill)
beizhu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("BeizhuCard") then return end
	return sgs.Card_Parse("@BeizhuCard=.")
end

sgs.ai_skill_use_func.BeizhuCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local enemies= {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:isKongcheng() or self:doNotDiscard(enemy, "he") then continue end
		local slash, visible = 0, 0
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
		for _,c in sgs.qlist(enemy:getCards("h")) do
			if c:hasFlag("visible") or c:hasFlag(flag) then
				visible = visible + 1
				if c:isKindOf("Slash") then
					slash = slash + 1
				end
			end
		end
		if slash > 0 or enemy:getHandcardNum() - visible > 2 then continue end
		table.insert(enemies, enemy)
	end
	if #enemies <= 0 then return end
	use.card = sgs.Card_Parse("@BeizhuCard=.")
	if use.to then use.to:append(enemies[1]) end
end

sgs.ai_use_priority.BeizhuCard = sgs.ai_use_priority.Dismantlement - 0.1
sgs.ai_use_value.BeizhuCard = sgs.ai_use_value.Dismantlement - 0.1
sgs.ai_card_intention.BeizhuCard = 80

sgs.ai_skill_invoke.beizhu = function(self, data)
	local name = data:toString():split(":")[2]
	if not name then return false end
	local target = self.room:findPlayerByObjectName(name)
	if not target or target:isDead() then return false end
	if self:isFriend(target) then return self:canDraw(target) end
	if self:isEnemy(target) then return not self:canDraw(target) end
	return false
end

--承诏
sgs.ai_skill_playerchosen.chengzhao = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	
	local cards = sgs.CardList()
	local peach, jink = 0, 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		elseif isCard("Jink", c, self.player) then
			if not self:isWeak() or jink > 0 then
				cards:append(c)
			else
				jink = jink + 1
			end
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	if not max_card then return nil end
	
	self.chengzhao_card = max_card:getEffectiveId()
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_chengzhao");
	slash:deleteLater()
	
	for _, p in ipairs(targets) do
		if not self:isEnemy(p) or not self.player:canSlash(p, slash, false) then continue end
		if p:hasSkill("kongcheng") and p:getHandcardNum() == 1 then continue end
		if self:doNotDiscard(p, "h") then continue end
		if not self:damageIsEffective(p, nil, self.player) then continue end
		if not self:slashIsEffective(slash, p, self.player, true) then continue end
		return p
	end
	
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getHandcardNum() == 1 and p:hasSkill("kongcheng") then
			return p
		end
	end
	
	for _, p in ipairs(targets) do
		if not self:isEnemy(p) or not self.player:canSlash(p, slash, false) then continue end
		if p:hasSkill("kongcheng") and p:getHandcardNum() == 1 then continue end
		if self:doNotDiscard(p, "h") then continue end
		return p
	end
	
	return nil
end

--咒缚
local newzhoufu_skill = {}
newzhoufu_skill.name = "newzhoufu"
table.insert(sgs.ai_skills, newzhoufu_skill)
newzhoufu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("NewZhoufuCard") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("@NewZhoufuCard=.")
end

sgs.ai_skill_use_func.NewZhoufuCard = function(card, use, self)
	local cards = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		table.insert(cards, sgs.Sanguosha:getEngineCard(card:getEffectiveId()))
	end
	self:sortByKeepValue(cards)
	self:sort(self.friends_noself)
	local zhenji
	for _, friend in ipairs(self.friends_noself) do
		if friend:getPile("incantation"):length() > 0 then continue end
		local reason = getNextJudgeReason(self, friend)
		if reason then
			if reason == "luoshen" or reason == "tenyearluoshen" then
				zhenji = friend
			elseif reason == "indulgence" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Heart or (friend:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade)
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "supply_shortage" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Club and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "lightning" and not friend:hasSkills("hongyan|wuyan|olhongyan") then
				for _, card in ipairs(cards) do
					if (card:getSuit() ~= sgs.Card_Spade or card:getNumber() == 1 or card:getNumber() > 9)
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "nosmiji" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Club or (card:getSuit() == sgs.Card_Spade and not friend:hasSkills("hongyan|olhongyan")) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "nosqianxi" or reason == "tuntian" then
				for _, card in ipairs(cards) do
					if (card:getSuit() ~= sgs.Card_Heart and not (card:getSuit() == sgs.Card_Spade and friend:hasSkills("hongyan|olhongyan")))
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "tieji" or reason == "caizhaoji_hujia" then
				for _, card in ipairs(cards) do
					if (card:isRed() or card:getSuit() == sgs.Card_Spade and friend:hasSkills("hongyan|olhongyan"))
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if zhenji then
		for _, card in ipairs(cards) do
			if card:isBlack() and not (zhenji:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade) then
				use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
				if use.to then use.to:append(zhenji) end
				return
			end
		end
	end
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getPile("incantation"):length() > 0 then continue end
		local reason = getNextJudgeReason(self, enemy)
		if not enemy:hasSkill("tiandu") and reason then
			if reason == "indulgence" then
				for _, card in ipairs(cards) do
					if not (card:getSuit() == sgs.Card_Heart or (enemy:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "supply_shortage" then
				for _, card in ipairs(cards) do
					if card:getSuit() ~= sgs.Card_Club and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "lightning" and not enemy:hasSkills("hongyan|wuyan|olhongyan") then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "nosmiji" then
				for _, card in ipairs(cards) do
					if card:isRed() or card:getSuit() == sgs.Card_Spade and enemy:hasSkills("hongyan|olhongyan") then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "nosqianxi" or reason == "tuntian" then
				for _, card in ipairs(cards) do
					if (card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade and enemy:hasSkills("hongyan|olhongyan"))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "tieji" or reason == "caizhaoji_hujia" then
				for _, card in ipairs(cards) do
					if (card:getSuit() == sgs.Card_Club or (card:getSuit() == sgs.Card_Spade and not enemy:hasSkills("hongyan|olhongyan")))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end

	local has_indulgence, has_supplyshortage
	local friend
	for _, p in ipairs(self.friends) do
		if getKnownCard(p, self.player, "Indulgence", true, "he") > 0 then
			has_indulgence = true
			friend = p
			break
		end
		if getKnownCard(p, self.player, "SupplySortage", true, "he") > 0 then
			has_supplyshortage = true
			friend = p
			break
		end
	end
	if has_indulgence then
		local indulgence = sgs.Sanguosha:cloneCard("indulgence")
		indulgence:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPile("incantation"):length() > 0 then continue end
			if self:hasTrickEffective(indulgence, enemy, friend) and self:playerGetRound(friend) < self:playerGetRound(enemy) and not self:willSkipPlayPhase(enemy) then
				for _, card in ipairs(cards) do
					if not (card:getSuit() == sgs.Card_Heart or (enemy:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	elseif has_supplyshortage then
		local supplyshortage = sgs.Sanguosha:cloneCard("supply_shortage")
		supplyshortage:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPile("incantation"):length() > 0 then continue end
			local distance = self:getDistanceLimit(supplyshortage, friend, enemy)
			if self:hasTrickEffective(supplyshortage, enemy, friend) and self:playerGetRound(friend) < self:playerGetRound(enemy)
				and not self:willSkipDrawPhase(enemy) and friend:distanceTo(enemy) <= distance then
				for _, card in ipairs(cards) do
					if card:getSuit() ~= sgs.Card_Club and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end

	for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if target:getPile("incantation"):length() > 0 then continue end
		if self:hasEightDiagramEffect(target) then
			for _, card in ipairs(cards) do
				if (card:isRed() and self:isFriend(target)) or (card:isBlack() and self:isEnemy(target)) and not self:isValuableCard(card) then
					use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
					if use.to then use.to:append(target) end
					return
				end
			end
		end
	end

	if self:getOverflow() > 0 then
		for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if target:getPile("incantation"):length() > 0 then continue end
			for _, card in ipairs(cards) do
				if not self:isValuableCard(card) and math.random() > 0.5 then
					use.card = sgs.Card_Parse("@NewZhoufuCard=" .. card:getEffectiveId())
					if use.to then use.to:append(target) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention.NewZhoufuCard = sgs.ai_card_intention.ZhoufuCard
sgs.ai_use_value.NewZhoufuCard = sgs.ai_use_value.ZhoufuCard
sgs.ai_use_priority.NewZhoufuCard = sgs.ai_use_priority.ZhoufuCard

--十周年咒缚
local tenyearzhoufu_skill = {}
tenyearzhoufu_skill.name = "tenyearzhoufu"
table.insert(sgs.ai_skills, tenyearzhoufu_skill)
tenyearzhoufu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("TenyearZhoufuCard") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("@TenyearZhoufuCard=.")
end

sgs.ai_skill_use_func.TenyearZhoufuCard = function(card, use, self)
	local cards = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		table.insert(cards, sgs.Sanguosha:getEngineCard(card:getEffectiveId()))
	end
	self:sortByKeepValue(cards)
	self:sort(self.friends_noself)
	local zhenji
	for _, friend in ipairs(self.friends_noself) do
		if friend:getPile("incantation"):length() > 0 then continue end
		local reason = getNextJudgeReason(self, friend)
		if reason then
			if reason == "luoshen" or reason == "tenyearluoshen" then
				zhenji = friend
			elseif reason == "indulgence" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Heart or (friend:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade)
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "supply_shortage" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Club and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "lightning" and not friend:hasSkills("hongyan|wuyan|olhongyan") then
				for _, card in ipairs(cards) do
					if (card:getSuit() ~= sgs.Card_Spade or card:getNumber() == 1 or card:getNumber() > 9)
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "nosmiji" then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Club or (card:getSuit() == sgs.Card_Spade and not friend:hasSkills("hongyan|olhongyan")) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "nosqianxi" or reason == "tuntian" then
				for _, card in ipairs(cards) do
					if (card:getSuit() ~= sgs.Card_Heart and not (card:getSuit() == sgs.Card_Spade and friend:hasSkills("hongyan|olhongyan")))
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			elseif reason == "tieji" or reason == "caizhaoji_hujia" then
				for _, card in ipairs(cards) do
					if (card:isRed() or card:getSuit() == sgs.Card_Spade and friend:hasSkills("hongyan|olhongyan"))
						and (friend:hasSkill("tiandu") or not self:isValuableCard(card)) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if zhenji then
		for _, card in ipairs(cards) do
			if card:isBlack() and not (zhenji:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade) then
				use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
				if use.to then use.to:append(zhenji) end
				return
			end
		end
	end
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getPile("incantation"):length() > 0 then continue end
		local reason = getNextJudgeReason(self, enemy)
		if not enemy:hasSkill("tiandu") and reason then
			if reason == "indulgence" then
				for _, card in ipairs(cards) do
					if not (card:getSuit() == sgs.Card_Heart or (enemy:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "supply_shortage" then
				for _, card in ipairs(cards) do
					if card:getSuit() ~= sgs.Card_Club and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "lightning" and not enemy:hasSkills("hongyan|wuyan|olhongyan") then
				for _, card in ipairs(cards) do
					if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "nosmiji" then
				for _, card in ipairs(cards) do
					if card:isRed() or card:getSuit() == sgs.Card_Spade and enemy:hasSkills("hongyan|olhongyan") then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "nosqianxi" or reason == "tuntian" then
				for _, card in ipairs(cards) do
					if (card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade and enemy:hasSkills("hongyan|olhongyan"))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			elseif reason == "tieji" or reason == "caizhaoji_hujia" then
				for _, card in ipairs(cards) do
					if (card:getSuit() == sgs.Card_Club or (card:getSuit() == sgs.Card_Spade and not enemy:hasSkills("hongyan|olhongyan")))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end

	local has_indulgence, has_supplyshortage
	local friend
	for _, p in ipairs(self.friends) do
		if getKnownCard(p, self.player, "Indulgence", true, "he") > 0 then
			has_indulgence = true
			friend = p
			break
		end
		if getKnownCard(p, self.player, "SupplySortage", true, "he") > 0 then
			has_supplyshortage = true
			friend = p
			break
		end
	end
	if has_indulgence then
		local indulgence = sgs.Sanguosha:cloneCard("indulgence")
		indulgence:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPile("incantation"):length() > 0 then continue end
			if self:hasTrickEffective(indulgence, enemy, friend) and self:playerGetRound(friend) < self:playerGetRound(enemy) and not self:willSkipPlayPhase(enemy) then
				for _, card in ipairs(cards) do
					if not (card:getSuit() == sgs.Card_Heart or (enemy:hasSkills("hongyan|olhongyan") and card:getSuit() == sgs.Card_Spade))
						and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	elseif has_supplyshortage then
		local supplyshortage = sgs.Sanguosha:cloneCard("supply_shortage")
		supplyshortage:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPile("incantation"):length() > 0 then continue end
			local distance = self:getDistanceLimit(supplyshortage, friend, enemy)
			if self:hasTrickEffective(supplyshortage, enemy, friend) and self:playerGetRound(friend) < self:playerGetRound(enemy)
				and not self:willSkipDrawPhase(enemy) and friend:distanceTo(enemy) <= distance then
				for _, card in ipairs(cards) do
					if card:getSuit() ~= sgs.Card_Club and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end

	for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if target:getPile("incantation"):length() > 0 then continue end
		if self:hasEightDiagramEffect(target) then
			for _, card in ipairs(cards) do
				if (card:isRed() and self:isFriend(target)) or (card:isBlack() and self:isEnemy(target)) and not self:isValuableCard(card) then
					use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
					if use.to then use.to:append(target) end
					return
				end
			end
		end
	end

	if self:getOverflow() > 0 then
		for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if target:getPile("incantation"):length() > 0 then continue end
			for _, card in ipairs(cards) do
				if not self:isValuableCard(card) and math.random() > 0.5 then
					use.card = sgs.Card_Parse("@TenyearZhoufuCard=" .. card:getEffectiveId())
					if use.to then use.to:append(target) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention.TenyearZhoufuCard = sgs.ai_card_intention.ZhoufuCard
sgs.ai_use_value.TenyearZhoufuCard = sgs.ai_use_value.ZhoufuCard
sgs.ai_use_priority.TenyearZhoufuCard = sgs.ai_use_priority.ZhoufuCard

--流矢
local liushi_skill = {}
liushi_skill.name = "liushi"
table.insert(sgs.ai_skills, liushi_skill)
liushi_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("@LiushiCard=.")
end

sgs.ai_skill_use_func.LiushiCard = function(card, use, self)
	local hearts = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:getSuit() == sgs.Card_Heart and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
			table.insert(hearts, c)
		end
	end
	if self.player:hasSkills(sgs.lose_equip_skill) then self:sortByKeepValue(hearts)
	else self:sortByUseValue(hearts, true) end
	
	if #hearts <=0 then return end
	if hearts[1]:isKindOf("Jink") and self:getCardsNum("Jink") == 1 then return end
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_liushi")
	slash:deleteLater()
	if self.player:isLocked(slash) then return end
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		use.card = sgs.Card_Parse("@LiushiCard=" .. hearts[1]:getEffectiveId())
		if use.to then use.to:append(dummy_use.to:first()) end return
	end
end

sgs.ai_use_value.LiushiCard = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority.LiushiCard = sgs.ai_use_priority.Slash + 0.1

--同疾
sgs.ai_skill_use["@@mobiletongji"] = function(self, prompt, method)
	local others = self.room:getOtherPlayers(self.player)
	local slash = self.player:getTag("mobiletongji-card"):toCard()
	others = sgs.QList2Table(others)
	local source
	for _, player in ipairs(others) do
		if player:hasFlag("MobileTongjiSlashSource") then
			source = player
			break
		end
	end
	self:sort(self.enemies, "defense")

	local doTongji = function(who, source)
		if not who:hasSkill("mobiletongji") then return "." end
		if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
			and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
			return "."
		end

		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and (not source or source:canSlash(who, slash, false)) then
				if self:isFriend(who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
					return "@MobileTongjiCard="..card:getEffectiveId().."->"..who:objectName()
				else
					return "@MobileTongjiCard="..card:getEffectiveId().."->"..who:objectName()
				end
			end
		end

		local cards = self.player:getCards("e")
		cards=sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			local range_fix = 0
			if card:isKindOf("Weapon") then range_fix = range_fix + sgs.weapon_range[card:getClassName()] - self.player:getAttackRange(false) end
			if card:isKindOf("OffensiveHorse") then range_fix = range_fix + 1 end
			if not self.player:isCardLimited(card, method) and (not source or source:canSlash(who, slash, false)) and self.player:inMyAttackRange(who, range_fix) then
				return "@MobileTongjiCard=" .. card:getEffectiveId() .. "->" .. who:objectName()
			end
		end
		return "."
	end

	for _, enemy in ipairs(self.enemies) do
		if not (source and source:objectName() == enemy:objectName()) then
			local ret = doTongji(enemy, source)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
			local ret = doTongji(player, source)
			if ret ~= "." then return ret end
		end
	end


	self:sort(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)


	for _, friend in ipairs(self.friends_noself) do
		if not self:slashIsEffective(slash, friend) or self:findLeijiTarget(friend, 50, source) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doTongji(friend, source)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend, source, true) or self:getDamagedEffects(friend, source, true) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doTongji(friend, source)
				if ret ~= "." then return ret end
			end
		end
	end

	if (self:isWeak() or self:hasHeavySlashDamage(source, slash)) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
	  and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doTongji(friend, source)
					if ret ~= "." then return ret end
				end
			end
		end
	end

	if (self:isWeak() or self:hasHeavySlashDamage(source, slash)) and not self:getCardId("Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doTongji(friend, source)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end

sgs.ai_card_intention.MobileTongjiCard = function(self, card, from, to)
	sgs.ai_mobiletongji_effect = true
	if not hasExplicitRebel(self.room) then sgs.ai_mobiletongji_user = from
	else sgs.ai_mobiletongji_user = nil end
end

--[[function sgs.ai_slash_prohibit.mobiletongji(self, from, to, card)
	
--end]]

--败移
local baiyi_skill = {}
baiyi_skill.name = "baiyi"
table.insert(sgs.ai_skills, baiyi_skill)
baiyi_skill.getTurnUseCard = function(self)
	if not self.player:isWounded() or self.player:getMark("@baiyiMark") <= 0 then return end
	if self.room:alivePlayerCount() <= 2 or self.role == "renegade" then return end
	if #self.friends_noself == 0 then return end
	local rene = 0
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if sgs.evaluatePlayerRole(aplayer) == "renegade" then rene = rene + 1 end
	end
	if #self.friends + #self.enemies + rene < self.room:alivePlayerCount() then return end
	return sgs.Card_Parse("@BaiyiCard=.")
end

sgs.ai_skill_use_func.BaiyiCard = function(card, use, self)
	if #self.friends_noself == 0 then return end
	self:sort(self.friends_noself, "handcard")
	local friend = self.friends_noself[#self.friends_noself]
	local nplayer = self.friends_noself[#self.friends_noself]
	local values, range = {}, friend:getAttackRange()
	for i = 1, self.player:aliveCount() do
		local fediff, add, isfriend = 0, 0
		local np = nplayer
		for value = #self.friends_noself, 1, -1 do
			np = np:getNextAlive()
			if np:objectName() == nplayer:objectName() then
				if self:isFriend(nplayer) then fediff = fediff + value
				else fediff = fediff - value
				end
			else
				if self:isFriend(np) then
					fediff = fediff + value
					if isfriend then add = add + 1
					else isfriend = true end
				elseif self:isEnemy(np) then
					fediff = fediff - value
					isfriend = false
				end
			end
		end
		values[nplayer:objectName()] = fediff + add
		nplayer = nplayer:getNextAlive()
	end
	local function get_value(a)
		local ret = 0
		for _, enemy in ipairs(self.enemies) do
			if a:objectName() ~= enemy:objectName() and a:distanceTo(enemy) <= range then ret = ret + 1 end
		end
		return ret
	end
	local function compare_func(a,b)
		if values[a:objectName()] ~= values[b:objectName()] then
			return values[a:objectName()] > values[b:objectName()]
		else
			return get_value(a) > get_value(b)
		end
	end
	local players = sgs.QList2Table(self.room:getAlivePlayers())
	table.sort(players, compare_func)
	if values[players[1]:objectName()] > 0 and players[1]:objectName() ~= self.player:objectName() and players[1]:objectName() ~= friend:objectName() then
		use.card = card
		if use.to then use.to:append(players[1]) use.to:append(friend) end
	end
end

sgs.ai_use_priority.BaiyiCard = 8

--景略
local jinglve_skill = {}
jinglve_skill.name = "jinglve"
table.insert(sgs.ai_skills, jinglve_skill)
jinglve_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("JinglveCard") or #self.enemies == 0 then return end
	return sgs.Card_Parse("@JinglveCard=.")
end

sgs.ai_skill_use_func.JinglveCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	for _, p in ipairs(self.enemies) do
		if p:isKongcheng() then continue end
		use.card = card
		if use.to then use.to:append(p) end return
	end
end

sgs.ai_use_priority.JinglveCard = 8
sgs.ai_card_intention.JinglveCard = 80 

--擅立
sgs.ai_skill_playerchosen.shanli = function(self, targets)
	self:sort(self.friends)
	if #self.friends > 0 then return self.friends[#self.friends] end
	return self.player
end

sgs.ai_skill_choice.shanli = function(self, choices, data)
	local player = data:toPlayer()
	choices = choices:split(":")
	if player and player:isAlive() then
		if self:isFriend(player) then
			for _, skill in ipairs(choices) do
				if player:hasLordSkill(skill, true) then continue end
				return skill
			end
		else
			for _, skill in ipairs(choices) do
				if not player:hasLordSkill(skill, true) then continue end
				return skill
			end
		end
	end
	return choices[math.random(1, #choices)]
end

--弘仪
local hongyi_skill = {}
hongyi_skill.name = "hongyi"
table.insert(sgs.ai_skills, hongyi_skill)
hongyi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("HongyiCard") or #self.enemies == 0 then return end
	return sgs.Card_Parse("@HongyiCard=.")
end

sgs.ai_skill_use_func.HongyiCard = function(card, use, self)
	if #self.enemies == 0 then return end
	
	local death = 0
	for _, p in sgs.qlist(self.room:getAllPlayers(true)) do
		if p:isDead() then death = death + 1 end
		if death >= 2 then break end
	end
	
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local enemy = self.enemies[1]
	for _, p in ipairs(self.enemies) do
		if (p:hasSkill("keji") and not self:hasCrossbowEffect(p)) or self:willSkipPlayPhase(p) then continue end
		enemy = p
		break
	end
	
	if death == 0 then
		sgs.ai_use_priority.HongyiCard = 10
		use.card = sgs.Card_Parse("@HongyiCard=.")
		if use.to then use.to:append(enemy) end
		return
	end
	
	local candis = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if self:isValuableCard(c) or not self.player:canDiscard(self.player, c:getEffectiveId()) then continue end
		table.insert(candis, c)
	end
	if #candis < death then return end
	self:sortByKeepValue(candis)
	local dis = {}
	if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then
		table.insert(dis, self.player:getArmor():getEffectiveId())
	end
	if death > #dis then
		for i = 1, death - #dis do
			table.insert(dis, candis[i]:getEffectiveId())
		end
	end
	use.card = sgs.Card_Parse("@HongyiCard=" .. table.concat(dis, "+"))
	if use.to then use.to:append(enemy) end return
end

sgs.ai_use_priority.HongyiCard = sgs.ai_use_priority.ExNihilo - 0.1
sgs.ai_card_intention.HongyiCard = 80 

--劝封
sgs.ai_skill_choice.quanfeng = function(self, choices, data)
	choices = choices:split(":")
	for _,choice in ipairs(choices) do
		if self.player:hasSkill(choice, true) or string.find(sgs.bad_skills, choice) then continue end
		if self:isValueSkill(choice, nil, true) then
			return choice
		end
	end
	for _,choice in ipairs(choices) do
		if self.player:hasSkill(choice, true) or string.find(sgs.bad_skills, choice) then continue end
		if self:isValueSkill(choice) then
			return choice
		end
	end
	local skills = {}
	for _,choice in ipairs(choices) do
		if self.player:hasSkill(choice, true) or string.find(sgs.bad_skills, choice) then continue end
		table.insert(skills, choice)
	end
	if #skills > 0 then return skills[math.random(1, #skills)] end
	for _,choice in ipairs(choices) do
		if string.find(sgs.bad_skills, choice) then continue end
		return choice
	end
	return choices[math.random(1, #choices)]
end

--第二版弘仪

--第二版劝封
