--谏征
sgs.ai_skill_cardask["jianzheng-put"] = function(self, data)
	local use = data:toCardUse()
	local slash = use.card
	local from = use.from
	if from and self:isFriend(from) then return "." end
	local willSave = false
	local friend
	for _, to in sgs.qlist(use.to) do
        if self:isFriend(to) and self:slashIsEffective(slash, to, from) and self:isWeak(to) then
            friend = to
			willSave = true
			break
        end
    end
	if not willSave then return "." end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	if #cards < 2 then return "." end
	self:sortByKeepValue(cards)
	if slash:isBlack() or not self:isWeak() or not self:slashIsEffective(slash, self.player, from) or self:getOverflow() > 0 then
		for _, card in ipairs(cards) do
			if not card:isKindOf("Peach") then
				sgs.updateIntention(self.player, friend, -10)
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end

--专对
sgs.ai_skill_invoke.zhuandui = function(self, data)
	local target = data:toPlayer()
	if target then
		return not self:isFriend(target)
	end
	return true
end

function sgs.ai_slash_prohibit.zhuandui(self, from, to)
	if from:getHandcardNum() <= 1 or to:isKongcheng() then return false end
	if not to:hasSkill("tianbian") then return false end
	if from:hasSkills("tieji|qianjie") or self:needKongcheng(from) then return false end
	if self:isEnemy(to, from) and self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) and #self:getEnemies(from) > 1 then return true end
	if from:getHandcardNum() <= 2 and from:isWounded() and not self:isFriend(to, from) and self:hasCardsNum("Peach", from, true) > 0 then return true end
	return false
end

--天辩
sgs.ai_skill_invoke.tianbian = function(self, data)
	local handcards = self.player:getCards("h")
	for _,c in sgs.qlist(handcards) do
		if c:getSuit() == sgs.Card_Heart and not c:isKindOf("Peach") and self:getOverflow() > 0 then
			return false
		end
	end
	return true
end

sgs.ai_cardneed.tianbian = function(to, card)
	return to:getHandcardNum() < 2 or card:getSuit() == sgs.Card_Heart
end

--福绵
sgs.ai_skill_invoke.fumian = function(self, data)
	return true
end

function fumianJudgeFriend(self, name, friends)
	local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuitRed, 0)
	if not card then return false end
	self.room:setCardFlag(card, "fumian_distance")
	card:deleteLater()
	if not self.player:canUse(card, friends) then return false end
	
	local extra_targets_and_name = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard(card:getClassName(), c, self.player) and c:isRed() then
			for _,p in sgs.qlist(friends) do
				local sp = sgs.SPlayerList()
				sp:append(p)
				if self.player:canUse(card, sp) then
					if card:targetFixed() and self.player:isProhibited(p, card) then continue end
					if card:isKindOf("TrickCard") then
						if self:hasTrickEffective(card, p, self.player) then
							table.insert(extra_targets_and_name, p)
						end
					else
						if card:isKindOf("Peach") and p:getLostHp() > 0 then
							table.insert(extra_targets_and_name, p)
						else
							table.insert(extra_targets_and_name, p)
						end
					end
				end
			end
			if #extra_targets_and_name > 0 then
				table.insert(extra_targets_and_name, name)
				table.insert(self.fumian_extra, extra_targets_and_name)
				return true
			end
		end
	end
	return false
end

function fumianJudgeEnemy(self, name, enemies)
	local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuitRed, 0)
	if not card then return false end
	self.room:setCardFlag(card, "fumian_distance")
	card:deleteLater()
	if not self.player:canUse(card, enemies) then return false end
	
	local extra_targets_and_name = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard(card:getClassName(), c, self.player) and c:isRed() then
			for _,p in sgs.qlist(enemies) do
				local sp = sgs.SPlayerList()
				sp:append(p)
				if self.player:canUse(card, sp) then
					if card:targetFixed() and self.player:isProhibited(p, card) then continue end
					if card:isKindOf("TrickCard") then
						if self:hasTrickEffective(card, p, self.player) then  --过河拆桥和顺手牵羊的处理待补充
							table.insert(extra_targets_and_name, p)
						end
					else
						if card:isKindOf("Slash") and self:slashIsEffective(card, p, self.player) then
							table.insert(extra_targets_and_name, p)
						else
							table.insert(extra_targets_and_name, p)
						end
					end
				end
			end
			if #extra_targets_and_name > 1 then
				table.insert(extra_targets_and_name, name)
				table.insert(self.fumian_extra, extra_targets_and_name)
				return true
			end
		end
	end
	return false
end

function fumianCanGetFriends(self, friends)
	local ex_nihilo = fumianJudgeFriend(self, "ex_nihilo", friends)
	local peach = fumianJudgeFriend(self, "peach", friends)
	--顺、拆、铁索等待补充，杀队友以此杀远距离敌人待补充
	return ex_nihilo or peach
end

function fumianCanGetEnemies(self, enemies)
	local slash = fumianJudgeEnemy(self, "slash", enemies)
	local fire_slash = fumianJudgeEnemy(self, "fire_slash", enemies)
	local thunder_slash = fumianJudgeEnemy(self, "thunder_slash", enemies)
	local duel = fumianJudgeEnemy(self, "duel", enemies)
	local snatch = fumianJudgeEnemy(self, "snatch", enemies)
	local dismantlement = fumianJudgeEnemy(self, "dismantlement", enemies)
	local iron_chain = fumianJudgeEnemy(self, "iron_chain", enemies)
	local fire_attack = fumianJudgeEnemy(self, "fire_attack", enemies)
	return slash or fire_slash or thunder_slash or duel or snatch or dismantlement or iron_chain or fire_attack
end

sgs.ai_skill_choice.fumian = function(self, choices, data)
	if self.player:containsTrick("indulgence") then
		return "draw"
	end
	self.fumian_extra = {}
	local friends = sgs.SPlayerList()
	for _,p in ipairs(self.friends_noself) do
		friends:append(p)
	end
	local enemies = sgs.SPlayerList()
	for _,p in ipairs(self.enemies) do
		enemies:append(p)
	end
	
	if self.player:containsTrick("supply_shortage") or self:getOverflow() > 1 then 
		if fumianCanGetFriends(self, friends) or fumianCanGetEnemies(self, enemies) then
			return "target"
		end
	end
	 
	if not friends:isEmpty() and fumianCanGetFriends(self, friends) then return "target" end
	if not enemies:isEmpty() and fumianCanGetEnemies(self, enemies) then return "target" end
	return "draw"
end

sgs.ai_skill_use["@@fumian"] = function(self, prompt, method)
	local length = string.find(prompt, ":")
	local card_name = string.sub(prompt, length + 1 , string.len(prompt))
	local maxnum = self.player:getMark("fumian_extra_target-Clear")
	local use = self.player:getTag("FuMianUse"):toCardUse()
	
	if card_name == "collateral" then  --【借刀杀人】这部分没有测试
		local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
		for _, p in sgs.qlist(use.to) do
			table.insert(dummy_use.current_targets, p:objectName())
		end
		self:useCardCollateral(use.card, dummy_use)
		if dummy_use.card and dummy_use.to:length() == 2 then
			local first = dummy_use.to:at(0):objectName()
			local second = dummy_use.to:at(1):objectName()
			return "@ExtraCollateralCard=.->" .. first .. "+" .. second
		end
	end
	
	local extra_table = {}
	for _,t in ipairs(self.fumian_extra) do
		--[[if table.contains(t, card_name) then  --会认为不contains
			extra_table = t
			break
		end]]
		if t[#t] == card_name then
			--extra_table = t
			for i = 1, #t - 1 do  --为了不把card_name一起存进去
				if not t[i]:hasFlag("fumian_canchoose") then continue end
				table.insert(extra_table, t[i])
			end
			break
		end
	end
	if #extra_table == 0 then return "." end
	--table.removeOne(extra_table, card_name)  --无法remove掉
	--if #extra_table == 0 then return "." end
	
	local extra_players = {}
	if self:isFriend(extra_table[1]) then
		if card_name == "peach" then
			self:sort(extra_table, "hp")
		elseif card_name == "ex_nihilo" then
			self:sort(extra_table, "handcard")
		else
			self:sort(extra_table, "defense")
		end
		for i = 1, math.min(maxnum, #extra_table) do
			table.insert(extra_players, extra_table[i]:objectName())
		end
		if #extra_players > 0 then
			return "@FumianCard=.->" .. table.concat(extra_players, "+")
		end
	end
	if self:isEnemy(extra_table[1]) then
		self:sort(extra_table, "defense")
		for i = 1, math.min(maxnum, #extra_table) do
			table.insert(extra_players, extra_table[i]:objectName())
		end
		if #extra_players > 0 then
			return "@FumianCard=.->" .. table.concat(extra_players, "+")
		end
	end
	return "."
end

--怠宴
sgs.ai_skill_playerchosen.daiyan = function(self, targets)
	self:sort(self.friends_noself, "defense")
	for _,friend in ipairs(self.friends_noself) do
		if hasManjuanEffect(friend) then continue end 
		if self:needKongcheng(friend, true) then continue end
		if friend:getMark("&daiyan+#" .. self.player:objectName()) == 0 or friend:hasSkill("zhaxiang") or self:needToLoseHp(friend, self.player, false, true) then
			return friend
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if hasManjuanEffect(enemy) then return enemy end 
	end
	return nil
end

sgs.ai_playerchosen_intention.daiyan = function(self, from, to)
	if self:needKongcheng(to, true) then return end
	if hasManjuanEffect(to) then return end 
	if to:getMark("&daiyan+#" .. self.player:objectName()) > 0 then return end 
	sgs.updateIntention(from, to, -10)
end

--忠鉴
local zhongjian_skill = {}
zhongjian_skill.name = "zhongjian"
table.insert(sgs.ai_skills, zhongjian_skill)
zhongjian_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("ZhongjianCard") or (self.player:getMark("zhongjian-PlayClear") > 0 and self.player:usedTimes("ZhongjianCard") < 2) then
		return sgs.Card_Parse("@ZhongjianCard=.")
	end
end

sgs.ai_skill_use_func.ZhongjianCard = function(card, use, self)
	if self.player:isKongcheng() then return end
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	self.zhongjian_target = nil
	local n = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getHandcardNum() - p:getHp() > n then
			n = p:getHandcardNum() - p:getHp()
			self.zhongjian_target = p
		end
	end
	if not self.zhongjian_target then return end
	use.card = sgs.Card_Parse("@ZhongjianCard=" .. handcards[1]:getEffectiveId())
	if use.to then use.to:append(self.zhongjian_target) end
end

sgs.ai_skill_choice.zhongjian = function(self, choices, data)
	if not self.zhongjian_target then return "draw" end
	if self:isEnemy(self.zhongjian_target) and not self:doNotDiscard(self.zhongjian_target) then return "discard" end
	if self:isFriend(self.zhongjian_target) and self:needToThrowCard(self.zhongjian_target, "e") then return "discard" end
	return "draw"
end

sgs.ai_use_priority.ZhongjianCard = 7
sgs.ai_use_value.ZhongjianCard = 7

--才识
sgs.ai_skill_invoke.caishi = function(self, data)
	self.caishi_choice = nil
	if self.player:isWounded() and (self:getCardsNum("Peach") == 0 or self.player:isSkipped(sgs.Player_Play)) then
		self.caishi_choice = "recover" 
	elseif #self.enemies < 1 or self.player:isSkipped(sgs.Player_Play) then
		self.caishi_choice = "max"
	else
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				if self:willUse(self.player, card, false, false, true) then
					return false
				end
			elseif card:isKindOf("TrickCard") and not card:isKindOf("ExNihilo") and not card:isKindOf("Nullification") then
				if self:willUse(self.player, card, false, false, true) then
					return false
				end
			end
		end
		self.caishi_choice = "max"
	end
	return self.caishi_choice ~= nil
end

sgs.ai_skill_choice.caishi = function(self, choices, data)
	if not self.caishi_choice then return "max" end
	return self.caishi_choice
end

--十周年忠鉴

--十周年才识

--OL忠鉴
local olzhongjian_skill = {}
olzhongjian_skill.name = "olzhongjian"
table.insert(sgs.ai_skills, olzhongjian_skill)
olzhongjian_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("OLZhongjianCard") or (self.player:getMark("olzhongjian-PlayClear") > 0 and self.player:usedTimes("OLZhongjianCard") < 2) then
		return sgs.Card_Parse("@OLZhongjianCard=.")
	end
end

sgs.ai_skill_use_func.OLZhongjianCard = function(card, use, self)
	if self.player:isKongcheng() then return end
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	local others = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local targets = {}
	for _, p in ipairs(others) do
		if p:isKongcheng() then continue end
		table.insert(targets, p)
	end
	if #targets == 0 then return end
	self:sort(targets, "handcard")
	use.card = sgs.Card_Parse("@OLZhongjianCard=" .. handcards[1]:getEffectiveId())
	if use.to then use.to:append(targets[#targets]) end
end

sgs.ai_skill_playerchosen.olzhongjian = function(self, targets)
	local target = self:findPlayerToDiscard("he", false, true, targets)
	if target then return target end
	return nil
end

sgs.ai_use_priority.OLZhongjianCard = sgs.ai_use_priority.ZhongjianCard
sgs.ai_use_value.OLZhongjianCard = sgs.ai_use_value.ZhongjianCard

--OL才识
sgs.ai_skill_invoke.olcaishi = true

sgs.ai_skill_choice.olcaishi = function(self, choices, data)
	if self.player:isWounded() and (self:getCardsNum("Peach") == 0 or self.player:isSkipped(sgs.Player_Play)) then
		return "recover"
	end
	return "max"
end

--清弦
function SmartAI:qingxianLose(to, from)
	from = from or self.player
	if self:isFriend(to, from) then
		if to:hasSkill("zhaxiang") and not hasManjuanEffect(to) and not self:willSkipPlayPhase(to)
			and (to:getHp() > 1 or self:getAllPeachNum() > 0) then
				return true
		end
		if self:needToLoseHp(to, self.player, false, true) then return true end
	else
		if to:hasSkill("zhaxiang") then return false end
		if self:needToLoseHp(to, self.player, false, true) then return false end
	end
	return not self:isFriend(to, from)
end

function SmartAI:qingxianRecover(to, from)
	from = from or self.player
	if to:getLostHp() < 1 then return false end
	if self:isFriend(to, from) then
		if self:needToThrowCard(to, "e") then return true end
		if self:needToLoseHp(to, self.player, false, false, true) then return false end
		local can = false
		for _, card in sgs.qlist(to:getHandcards()) do
			if card:isKindOf("EquipCard") then
				can = true
				break
			end
		end
		if not can and to:hasTreasure("wooden_ox") and not to:getPile("wooden_ox"):isEmpty() and to:getCards("e"):length() == 1 then return false end
		if self:isWeak(to) then return true end
		if not can and to:getCards("e"):length() > 0 and not to:getWeapon() and not to:getOffensiveHorse() and not (to:hasTreasure("wooden_ox") and to:getPile("wooden_ox"):isEmpty()) then 
			return false 
		end
		return true
	else
		if self:needToThrowCard(to, "e") then return false end
		if self:isWeak(to) then return false end
		if self:needToLoseHp(to, self.player, false, true, true) and to:getCards("e"):length() > 0 then return true end
		local can = false
		for _, card in sgs.qlist(to:getHandcards()) do
			if card:isKindOf("EquipCard") then
				can = true
				break
			end
		end
		if not can and to:hasTreasure("wooden_ox") and not to:getPile("wooden_ox"):isEmpty() and to:getCards("e"):length() == 1 then return true end
		return false
	end
	return self:isFriend(to, from)
end

sgs.ai_skill_invoke.qingxian = function(self, data)
	local from = data:toPlayer()
	if not from then return false end
	self.qingxian_choice = nil
	if self:isFriend(from) then
		if from:getLostHp() > 0 and self:qingxianRecover(from) then
			self.qingxian_choice = "recover"
		elseif self:qingxianLose(from) then 
			self.qingxian_choice = "losehp"
		end
	else
		if self:qingxianLose(from) then
			self.qingxian_choice = "losehp"
		elseif from:getLostHp() > 0 and self:qingxianRecover(from) then 
			self.qingxian_choice = "recover"
		end
	end
	if self.qingxian_choice then
		local new_data = sgs.QVariant()
		new_data:setValue(from)
		self.player:setTag("QingxianTarget_ForAi", new_data)
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.qingxian = function(self, targets)
	self:updatePlayers()
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	self.qingxian_choice = nil
	local new_data = sgs.QVariant()
	
	for _, to in ipairs(targets) do
		if self:isFriend(to) and self:qingxianRecover(to) then
			self.qingxian_choice = "recover"
			new_data:setValue(to)
			self.player:setTag("QingxianTarget_ForAi", new_data)
			return to
		elseif self:isEnemy(to) and self:qingxianLose(to) then
			new_data:setValue(to)
			self.player:setTag("QingxianTarget_ForAi", new_data)
			self.qingxian_choice = "losehp"
			return to
		end
	end
	targets = sgs.reverse(targets)
	for _, to in ipairs(targets) do
		if self:isFriend(to) and self:qingxianLose(to) then
			new_data:setValue(to)
			self.player:setTag("QingxianTarget_ForAi", new_data)
			self.qingxian_choice = "losehp"
			return to
		elseif not self:isFriend(to) and (self:qingxianLose(to) or self:qingxianRecover(to)) then
			new_data:setValue(to)
			self.player:setTag("QingxianTarget_ForAi", new_data)
			self.qingxian_choice = "recover"
			return to
		end
	end
	return "."
end

sgs.ai_skill_choice.qingxian = function(self, choices) 
	if not self.qingxian_choice then return choices[1] end
	return self.qingxian_choice
end

sgs.ai_skill_discard.qingxian = function(self, discard_num, min_num, optional, include_equip)
	local card_id = self:disEquip()
	if card_id then return {card_id} end
	
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("EquipCard") then
			return {card:getEffectiveId()}
		end
	end
	return "."
end

function sgs.ai_slash_prohibit.qingxian(self, from, to, card)
	if self:justDamage(to, from, true) then return false end
	if from:hasSkill("zhaxiang") then return false end
	if not self:isFriend(to, from) and not self:qingxianLose(to, from) then return false end
	if from:getHp() > 2 then return false end
	if from:hasSkills(sgs.need_equip_skill) and from:getHp() > 1 then return false end
	if to:getHp() < 2 then return false end
	return not self:isFriend(to, from) and self:isWeak(from)
end

sgs.ai_need_damaged.qingxian = function (self, attacker, player)
	if player:hasSkill("qingxian") and not self:isWeak(player) and player:getHp() > 2 and attacker then
		if self:qingxianLose(attacker, player) then return true end
		if self:isFriend(attacker, player) and self:isWeak(attacker) and attacker:isWounded() and self:qingxianRecover(attacker, player) then return true end 
	end
	return false
end

sgs.ai_choicemade_filter.skillChoice.qingxian = function(self, player, promptlist)
	local to = player:getTag("QingxianTarget_ForAi"):toPlayer()
	player:removeTag("QingxianTarget_ForAi")
	if not to then return end
	local choice = promptlist[#promptlist]
	if choice == "losehp" then 
		if to:hasSkill("zhaxiang") or self:needToLoseHp(to, player) or (to:hasSkills(sgs.need_equip_skill) and not self:isWeak(to)) then return end
		sgs.updateIntention(player, to, 10)
	end
	if choice == "recover" then 
		if self:needToLoseHp(to, player, false, false, true) then return end
		if to:hasTreasure("wooden_ox") and to:getPile("wooden_ox"):length() > 0 and to:getCards("e"):length() == 1 then return end
		sgs.updateIntention(player, to, -10) 
	end
end

--绝响
sgs.ai_skill_playerchosen.juexiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, to in ipairs(targets) do
		if self:isFriend(to) then return to end
	end
	return "."
end

--激弦
sgs.ai_skill_invoke.jixian = function(self, data)
	local from = data:toPlayer()
	if not from then return false end
	return self:qingxianLose(from)
end

--烈弦
sgs.ai_skill_playerchosen.liexian = function(self, targets)
	self:updatePlayers()
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	
	for _, to in ipairs(targets) do
		if self:isEnemy(to) and self:qingxianLose(to) then return to end
	end
	targets = sgs.reverse(targets)
	for _, to in ipairs(targets) do
		if self:isFriend(to) and self:qingxianLose(to) then return to end
	end
	return "."
end

--柔弦
sgs.ai_skill_invoke.rouxian = function(self, data)
	local to = data:toPlayer()
	return self:qingxianRecover(to)
end

--和弦
sgs.ai_skill_playerchosen.hexian = function(self, targets)
	self:updatePlayers()
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	
	for _, to in ipairs(targets) do
		if self:isFriend(to) and self:qingxianRecover(to) then return to end
	end
	targets = sgs.reverse(targets)
	for _, to in ipairs(targets) do
		if not self:isFriend(to) and self:qingxianRecover(to) then return to end
	end
	return "."
end

--手杀清弦
local mobileqingxian_skill = {}
mobileqingxian_skill.name = "mobileqingxian"
table.insert(sgs.ai_skills, mobileqingxian_skill)
mobileqingxian_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:canDiscard(self.player, "he") or self.player:getHp() <= 0 or self.player:hasUsed("MobileQingxianCard") then return end
	return sgs.Card_Parse("@MobileQingxianCard=.")
end

sgs.ai_skill_use_func.MobileQingxianCard = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local useable_cards = {}
	self:sortByKeepValue(cards)
	local use_silver_lion = 0
	if self.player:getArmor() and self:needToThrowArmor() then
		table.insert(useable_cards, self.player:getArmor():getEffectiveId())
		use_silver_lion = 1
	end
	for _,c in ipairs(cards) do
		if not c:isKindOf("Peach") and #useable_cards < math.min(self.player:getHp(), self:getOverflow() > 0 and self:getOverflow() or 1) then
			table.insert(useable_cards, c:getEffectiveId())
		end
	end
	if #useable_cards == 0 then return end
	self:sort(self.friends_noself, "hp")
	self:sort(self.enemies, "hp")
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > self.player:getEquips():length() - use_silver_lion and #targets < #useable_cards and not self:needToLoseHp(enemy, self.player, false, true) and not enemy:hasSkill("zhaxiang") then
			table.insert(targets, enemy)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() < self.player:getEquips():length() - use_silver_lion and friend:isWounded() and #targets < #useable_cards and not self:needToLoseHp(friend, self.player, false, true, true) then
			table.insert(targets, friend)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() == self.player:getEquips():length() - use_silver_lion and #targets < #useable_cards and self:canDraw(friend) then
			table.insert(targets, friend)
		end
	end
	
	if #targets == 0 then return end
	local discard = {}
	local n = #targets
	for _, id in ipairs(useable_cards) do
		table.insert(discard, id)
		n = n - 1
		if n < 1 then break end
	end
	
	use.card = sgs.Card_Parse("@MobileQingxianCard=" .. table.concat(discard, "+"))
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
		return
	end
end

sgs.ai_use_priority.MobileQingxianCard = 3
sgs.ai_use_value.MobileQingxianCard = 3

sgs.ai_card_intention.MobileQingxianCard = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		if to:getEquips():length() < from:getEquips():length() then
			if not to:isWounded() or self:needToLoseHp(to, from, false, true, true) then return end
			sgs.updateIntention(from, to, -10)
		elseif to:getEquips():length() == from:getEquips():length() then
			if not self:canDraw(to, from) then return end
			sgs.updateIntention(from, to, -10)
		else
			if self:needToLoseHp(to, from, false, true) or to:hasSkill("zhaxiang") then return end
			sgs.updateIntention(from, to, 10)
		end
	end
end

--手杀绝响
sgs.ai_skill_playerchosen.mobilejuexiang = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.mobilejuexiang_discard = function(self, targets)
	local target = self:findPlayerToDiscard("ej", true, true, targets)
	if target then return target end
	
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if not self:isFriend(p) and not self:doNotDiscard(p, "ej") then
			return p
		end
	end
	return nil
end

function sgs.ai_slash_prohibit.mobilejuexiang(self, from, to)
	if self:justDamage(to, from, true) then return false end
	if to:isLord() then return false end
	if to:getHp() > 1 or #self:getEnemies(from) == 1 then return false end
	if self:needToThrowCard(to, "e") then return false end
	if getCardsNum("Peach", to, from) + getCardsNum("Analeptic", to, from) > 0 then return false end
	return self:isWeak(from) and from:getHp() < 2
end

--残韵
local mobilecanyun_skill = {}
mobilecanyun_skill.name = "mobilecanyun"
table.insert(sgs.ai_skills, mobilecanyun_skill)
mobilecanyun_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:canDiscard(self.player, "he") or self.player:getHp() <= 0 or self.player:hasUsed("MobileCanyunCard") then return end
	return sgs.Card_Parse("@MobileCanyunCard=.")
end

sgs.ai_skill_use_func.MobileCanyunCard = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local useable_cards = {}
	self:sortByKeepValue(cards)
	local use_silver_lion = 0
	if self.player:getArmor() and self:needToThrowArmor() then
		table.insert(useable_cards, self.player:getArmor():getEffectiveId())
		use_silver_lion = 1
	end
	for _,c in ipairs(cards) do
		if not c:isKindOf("Peach") and #useable_cards < math.min(self.player:getHp(), self:getOverflow() > 0 and self:getOverflow() or 1) then
			table.insert(useable_cards, c:getEffectiveId())
		end
	end
	if #useable_cards == 0 then return end
	self:sort(self.friends_noself, "hp")
	self:sort(self.enemies, "hp")
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("mobilecanyun_used" .. self.player:objectName()) > 0 then continue end
		if enemy:getEquips():length() > self.player:getEquips():length() - use_silver_lion and #targets < #useable_cards and not self:needToLoseHp(enemy, self.player, false, true) and not enemy:hasSkill("zhaxiang") then
			table.insert(targets, enemy)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getMark("mobilecanyun_used" .. self.player:objectName()) > 0 then continue end
		if friend:getEquips():length() < self.player:getEquips():length() - use_silver_lion and friend:isWounded() and #targets < #useable_cards and not self:needToLoseHp(friend, self.player, false, true, true) then
			table.insert(targets, friend)
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getMark("mobilecanyun_used" .. self.player:objectName()) > 0 then continue end
		if friend:getEquips():length() == self.player:getEquips():length() - use_silver_lion and #targets < #useable_cards and self:canDraw(friend) then
			table.insert(targets, friend)
		end
	end
	
	if #targets == 0 then return end
	local discard = {}
	local n = #targets
	for _, id in ipairs(useable_cards) do
		table.insert(discard, id)
		n = n - 1
		if n < 1 then break end
	end
	
	use.card = sgs.Card_Parse("@MobileCanyunCard=" .. table.concat(discard, "+"))
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
		return
	end
end

sgs.ai_use_priority.MobileCanyunCard = 3
sgs.ai_use_value.MobileCanyunCard = 3

sgs.ai_card_intention.MobileCanyunCard = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		if to:getEquips():length() < from:getEquips():length() then
			if not to:isWounded() or self:needToLoseHp(to, from, false, true, true) then return end
			sgs.updateIntention(from, to, -10)
		elseif to:getEquips():length() == from:getEquips():length() then
			if not self:canDraw(to, from) then return end
			sgs.updateIntention(from, to, -10)
		else
			if self:needToLoseHp(to, from, false, true) or to:hasSkill("zhaxiang") then return end
			sgs.updateIntention(from, to, 10)
		end
	end
end

--问卦
local wengua_skill = {}
wengua_skill.name = "wengua"
table.insert(sgs.ai_skills, wengua_skill)
wengua_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isNude() or self.player:hasUsed("WenguaCard") then return end
	return sgs.Card_Parse("@WenguaCard=.")
end

sgs.ai_skill_use_func.WenguaCard = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local id = -1
	self:sortByUseValue(cards, true)
	if self:needToThrowArmor() then
		id = self.player:getArmor():getEffectiveId()
	end
	
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
		if nextAlive:objectName() == self.player:objectName() then break end
	until nextAlive:faceUp()
	
	if nextAlive:objectName() ~= self.player:objectName() or not self.player:getJudgingArea():isEmpty() then
		local reason = getNextJudgeReason(self, nextAlive, true)
		for _,c in ipairs(cards) do
			if not self:keepCard(c, self.player, true) then
				if self:goodJudge(nextAlive, reason, c) then
					id = c:getEffectiveId()
					break
				else
					if id < 0 then id = c:getEffectiveId() end
				end
			end
		end
	end

	if self:needToThrowCard() then sgs.ai_use_priority.WenguaCard = sgs.ai_use_priority.Slash + 0.1
	elseif nextAlive:getCards("j"):length() > 0 then sgs.ai_use_priority.WenguaCard = 0.1
	else sgs.ai_use_priority.WenguaCard = sgs.ai_use_priority.IronChain - 0.1
	end
	
	if id < 0 then return end
	use.card = sgs.Card_Parse("@WenguaCard=" .. id)
end

local wenguagive_skill = {}
wenguagive_skill.name = "wenguagive"
table.insert(sgs.ai_skills, wenguagive_skill)
wenguagive_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isNude() then return end
	return sgs.Card_Parse("@WenguagiveCard=.")
end

sgs.ai_skill_use_func.WenguagiveCard = function(card, use, self)
	local xushi = nil
	for _, p in ipairs(self.friends_noself) do
		if p:getMark("wengua-PlayClear") <= 0 and p:hasSkill("wengua") and not self:needKongcheng(p, true) then
			xushi = p
			break
		end
	end
	if not xushi then return end
	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local id = -1
	self:sortByUseValue(cards, true)
	if self:needToThrowArmor() then
		id = self.player:getArmor():getEffectiveId()
	end
	
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
		if nextAlive:objectName() == self.player:objectName() then break end
	until nextAlive:faceUp()
	
	if nextAlive:objectName() ~= self.player:objectName() or not self.player:getJudgingArea():isEmpty() then
		local reason = getNextJudgeReason(self, nextAlive, true)
		for _,c in ipairs(cards) do
			if not self:keepCard(c, self.player, true) then
				if self:goodJudge(nextAlive, reason, c) then
					id = c:getEffectiveId()
					break
				else
					if id < 0 then id = c:getEffectiveId() end
				end
			end
		end
	end
	
	if (sgs.evaluatePlayerRole(self.player) ~= "neutral" and sgs.evaluatePlayerRole(xushi) ~= "neutral") or self.player:hasSkill("wengua") then
		if self:needToThrowCard() then sgs.ai_use_priority.WenguagiveCard = sgs.ai_use_priority.Slash + 0.1
		elseif nextAlive:getCards("j"):length() > 0 then sgs.ai_use_priority.WenguagiveCard = 0.1
		else sgs.ai_use_priority.WenguagiveCard = sgs.ai_use_priority.IronChain - 0.1
		end
	else 
		sgs.ai_use_priority.WenguagiveCard = 0.1
	end
	if id < 0 then return end
	use.card = sgs.Card_Parse("@WenguagiveCard=" .. id)
	if use.to then use.to:append(xushi) end
end

sgs.ai_use_value.WenguaCard = 0.5
sgs.ai_use_value.WenguagiveCard = sgs.ai_use_value.WenguaCard

sgs.ai_skill_choice.wengua = function(self, choices, data)
	local name = data:toStringList()[1]
	local id = data:toStringList()[2]
	local c = sgs.Sanguosha:getCard(id)
	local from = self.room:findPlayerByObjectName(name)
	choices = choices:split("+")
	if from then
		local data = sgs.QVariant()
		data:setValue(from)
		self.player:setTag("Wengua_ForAI", data)
		
		local nextAlive = from
		repeat
			nextAlive = nextAlive:getNextAlive()
			if nextAlive:objectName() == from:objectName() then break end
		until nextAlive:faceUp()
		
		if nextAlive:objectName() ~= name or not from:getJudgingArea():isEmpty() then
			local reason = getNextJudgeReason(self, nextAlive, true)
			if self:goodJudge(nextAlive, reason, c) then return "top" end
		end
		
		if self:isFriend(from) and from:isAlive() and self:needKongcheng(from, true) and table.contains(choices, "cancel") then return "cancel" end
		
		if not self:isEnemy(from) then return "bottom" end
		if self:needKongcheng(from, true) then return "bottom" end
	end
	
	if table.contains(choices, "cancel") then return "cancel" end
	return "bottom"
end

sgs.ai_choicemade_filter.skillChoice.wengua = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local to = player:getTag("Wengua_ForAI"):toPlayer()
	player:removeTag("Wengua_ForAI")
	if not to then return end
	if self:needKongcheng(to, true) or sgs.evaluatePlayerRole(to) == "neutral" then return end
	if choice == "cancel" and not (from:isAlive() and self:needKongcheng(from, true)) then
		sgs.updateIntention(player, to, 80)
	end
end

--伏诛
sgs.ai_skill_invoke.fuzhu = function(self, data)
	local player = data:toPlayer()
	return self:isEnemy(player)
end

--复难
sgs.ai_skill_invoke.funan = function(self, data)
	if self.player:property("funan_level_up"):toBool() then return not self:needKongcheng(self.player, true) end
	local to = data:toPlayer()
	if self:isFriend(to) then return not self:needKongcheng(to, true) and not self:needKongcheng(self.player, true) end
	if not self:isFriend(to) and not self:isEnemy(to) then return not self:needKongcheng(self.player, true) end
	if self:needKongcheng(to, true) then return true end
	local card = self.player:getTag("FunanCard"):toCard()
	if not card then return false end
	if card:isKindOf("AOE") then 
		if sgs.evaluatePlayerRole(to) ~= "neutral" and self:canDraw(to) then sgs.updateIntention(self.player, to, 10) end
		return false 
	elseif card:isNDTrick() then return true 
	end
	if self:getOverflow() > 0 or self.player:getHandcardNum() >= to:getHandcardNum() then 
		if sgs.evaluatePlayerRole(to) ~= "neutral" and self:canDraw(to) then sgs.updateIntention(self.player, to, 10) end
		return false 
	end
	return true
end

--诫训
sgs.ai_skill_playerchosen.jiexun = function(self, targets)
	local diamond_count = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		for _,c in sgs.qlist(p:getCards("ej")) do
			if c:getSuit() == sgs.Card_Diamond then
				diamond_count = diamond_count + 1
			end
		end
	end
	local use_time = self.player:getMark("&jiexun-Keep")
	
	self:sort(self.enemies, "handcard")
	self:sort(self.friends_noself, "handcard")
	local second
	if use_time > diamond_count then
		local n = use_time - diamond_count
		for _,enemy in ipairs(self.enemies) do
			if hasManjuanEffect(enemy) and not self:doNotDiscard(enemy, "he", false, use_time, true) then return enemy end
			if not second and not self:needToThrowCard(enemy, "he", true) and enemy:getCardCount(true) >= n 
			and not (enemy:hasSkill("lirang") and self:findFriendsByType(sgs.Friend_Draw, enemy)) then
				second = enemy
			end
		end
	elseif use_time < diamond_count then
		for _,friend in ipairs(self.friends_noself) do
			if self:needToThrowCard(friend, "e") and not hasManjuanEffect(friend) then return friend end
			if not second and not hasManjuanEffect(friend) then second = friend end
		end
		if not second then self:noChoice(targets) end
	elseif use_time == diamond_count then
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _,friend in ipairs(self.friends_noself) do
			if self:needToThrowCard(friend, "e") and not hasManjuanEffect(friend) then return friend end
			if not second and not hasManjuanEffect(friend) then second = friend end
		end	
		if use_time == 0 then
			for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				return player
			end
		end
	end
	return second
end

--守玺
sgs.ai_skill_invoke.shouxi = function(self, data)
	local use = data:toCardUse()
	local player = use.from
	local slash = use.card
	if not self:slashIsEffective(slash, self.player, player) then return false end
	if self:getCardsNum("Jink") < 1 then self.player:setTag("Shouxi_ForAI", data) return true end
	if not self:canHit(self.player, player) then return false end
	self.player:setTag("Shouxi_ForAI", data)
	return true
end

sgs.ai_skill_askforag.shouxi = function(self, card_ids)
	local cards, basic = {}, {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getEngineCard(card_id)
		table.insert(cards, card)
		if card:isKindOf("BasicCard") then
			table.insert(basic, card)
		end
	end
	local id = -1
	local from = self.player:getTag("Shouxi_ForAI"):toCardUse().from
	self.player:removeTag("Shouxi_ForAI")
	if (not from or from:isDead() or not from:canDiscard(from, "h")) and #basic > 0 then
		self:sortByUseValue(basic, true)
		id = basic[1]:getEffectiveId()
	else
		self:sortByUseValue(cards, true)
		id = cards[1]:getEffectiveId()
	end
	if id > -1 then
		return id
	else
		return card_ids[1]
	end
end

--[[sgs.ai_skill_cardask["shouxi-discard"] = function(self, data)

end]]

--惠民
sgs.ai_skill_invoke.huimin = function(self, data)
	local friend_num = 0
	local enemy_num = 0
	for _, friend in ipairs(self.friends) do
		if friend:getHandcardNum() < friend:getHp() then
			friend_num = friend_num + 1
			if self:needKongcheng(friend, true) then return false end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() < enemy:getHp() then
			if self:needKongcheng(enemy, true) then friend_num = friend_num + 1
			else enemy_num = enemy_num + 1
			end
		end
	end
	return friend_num > 0 and friend_num >= enemy_num
end

function huiminValue(self, p, tos)
	local v = 0
	local suf, coeff = 0.9, 0.9
	local next_player = p
	if self:isFriend(p) then v = 1
	elseif self:isEnemy(p) then v = -1
	end
	repeat
		next_player = next_player:getNextAlive()
		if next_player:objectName() ~= p:objectName() and table.contains(tos, next_player) then
			if self:isFriend(next_player) then v = v + suf
			elseif self:isEnemy(next_player) then
				v = v - suf
			end
			suf = suf * coeff
		end
	until next_player:objectName() == p:objectName()
	return v
end

sgs.ai_skill_use["@@huimin!"] = function(self, prompt)
	local length = self.player:getMark("huimin_length")
	local hand, show = {}, {}
	for _, c in sgs.qlist(self.player:getCards("h")) do
		table.insert(hand, c)
	end
	length = math.min(#hand, length)
	self:sortByKeepValue(hand)
	for i = 1, length do
		table.insert(show, hand[i]:getEffectiveId())
	end
	
	local targets = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("huimin_target") then
			table.insert(targets, p)
		end
	end
	if #targets == 0 then return "." end
	if #targets == 1 then
		return "@HuiminCard=" .. table.concat(show, "+") .. "->" .. targets[1]:objectName()
	else
		local start = targets[1]
		local v = huiminValue(self, targets[1], targets)
		for _, p in ipairs(targets) do
			if huiminValue(self, p, targets) > v then 
				v = huiminValue(self, p, targets)
				start = p
			end
		end
		return "@HuiminCard=" .. table.concat(show, "+") .. "->" .. start:objectName()
	end
	return "."
end

--辟撰
sgs.ai_skill_invoke.bizhuan = function(self, data)
	return true
end

--通博
sgs.ai_skill_use["@@tongbo"] = function(self, prompt, method)
	local pile = self.player:getPile("book")
	local piles = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local max_num = math.max(pile:length(), #cards)
	if pile:isEmpty() or #cards == 0 then return "." end
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
	
	local new_piles, suits = {}, {}
	for _, c in ipairs(piles) do
		if not table.contains(exchange_to_handcard, c) then
			table.insert(new_piles, c)
		end
	end
	for _,c in ipairs(exchange_to_pile) do
		table.insert(new_piles, c)
	end
	for _, c in ipairs(new_piles) do
		if not table.contains(suits, c:getSuit()) then
			table.insert(suits, c:getSuit())
		end
	end
	if (#suits >= 4 and self:findFriendsByType(sgs.Friend_Draw)) or #suits < 4 then
		return "@TongboCard=" .. table.concat(exchange, "+")
	else
		return "."  --待补充
	end
	return "."
end

sgs.ai_skill_askforyiji.tongbo = function(self, card_ids)
	return sgs.ai_skill_askforyiji.miji(self, card_ids)
end
