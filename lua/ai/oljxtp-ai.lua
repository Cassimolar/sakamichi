--护驾
sgs.ai_skill_invoke.olhujia = function(self, data)
	return sgs.ai_skill_invoke.hujia(self, data)
end

sgs.ai_choicemade_filter.skillInvoke.olhujia = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		sgs.hujiasource = player
	end
end

function sgs.ai_slash_prohibit.olhujia(self, from, to)
	return sgs.ai_slash_prohibit.hujia(self, from, to)
end

--激将
table.insert(sgs.ai_global_flags, "oljijiangsource")
local jijiang_filter = function(self, player, carduse)
	if not carduse then self.room:writeToConsole(debug.traceback()) end
	if carduse.card:isKindOf("OLJijiangCard") then
		sgs.oljijiangsource = player
	else
		sgs.oljijiangsource = nil
	end
end

table.insert(sgs.ai_choicemade_filter.cardUsed, jijiang_filter)

sgs.ai_skill_invoke.jijiang = function(self, data)
	if not self.player:isLord() then return end
	if sgs.oljijiangsource then return false end
	local asked = data:toStringList()
	local prompt = asked[2]
	if self:askForCard("slash", prompt, 1) == "." then return false end

	local current = self.room:getCurrent()
	if self:isFriend(current) and current:getKingdom() == "shu" and self:getOverflow(current) > 2 and not self:hasCrossbowEffect(current) then
		return true
	end

	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if isCard("Slash", card, self.player) then
			return false
		end
	end

	local lieges = self.room:getLieges("shu", self.player)
	if lieges:isEmpty() then return false end
	local has_friend = false
	for _, p in sgs.qlist(lieges) do
		if not self:isEnemy(p) then
			has_friend = true
			break
		end
	end
	return has_friend
end

sgs.ai_choicemade_filter.skillInvoke.oljijiang = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		sgs.oljijiangsource = player
	end
end

local oljijiang_skill = {}
oljijiang_skill.name = "oljijiang"
table.insert(sgs.ai_skills, oljijiang_skill)
oljijiang_skill.getTurnUseCard = function(self)
	if not self.player:hasLordSkill("oljijiang") then return end
	local lieges = self.room:getLieges("shu", self.player)
	if lieges:isEmpty() then return end
	local has_friend
	for _, p in sgs.qlist(lieges) do
		if self:isFriend(p) then
			has_friend = true
			break
		end
	end
	if not has_friend then return end
	if self.player:hasUsed("OLJijiangCard") or self.player:hasFlag("Global_JijiangFailed") or not self:slashIsAvailable() then return end
	local card_str = "@OLJijiangCard=."
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash
end

sgs.ai_skill_use_func.OLJijiangCard = function(card, use, self)
	self:sort(self.enemies, "defenseSlash")

	if not sgs.oljijiangtarget then table.insert(sgs.ai_global_flags, "oljijiangtarget") end
	sgs.oljijiangtarget = {}

	local dummy_use = { isDummy = true }
	dummy_use.to = sgs.SPlayerList()
	if self.player:hasFlag("slashTargetFix") then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:hasFlag("SlashAssignee") then
				dummy_use.to:append(p)
			end
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		use.card = card
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(sgs.oljijiangtarget, p)
			if use.to then use.to:append(p) end
		end
	end
end

sgs.ai_use_value.OLJijiangCard = sgs.ai_use_value.JijiangCard + 0.1
sgs.ai_use_priority.OLJijiangCard = sgs.ai_use_priority.JijiangCard + 0.1

sgs.ai_card_intention.OLJijiangCard = function(self, card, from, tos)
	return sgs.ai_card_intention.JijiangCard(self, card, from, tos)
end

sgs.ai_choicemade_filter.cardResponded["@oljijiang-slash"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		sgs.updateIntention(player, sgs.oljijiangsource, -40)
		sgs.oljijiangsource = nil
		sgs.oljijiangtarget = nil
	elseif sgs.oljijiangsource and player:objectName() == player:getRoom():getLieges("shu", sgs.oljijiangsource):last():objectName() then
		sgs.oljijiangsource = nil
		sgs.oljijiangtarget = nil
	end
end

sgs.ai_skill_cardask["@oljijiang-slash"] = function(self, data)
	if not sgs.oljijiangsource or not self:isFriend(sgs.oljijiangsource) then return "." end
	if self:needBear() then return "." end

	local jijiangtargets = {}
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:hasFlag("JijiangTarget") then
			if self:isFriend(player) and not (self:needToLoseHp(player, sgs.oljijiangsource, true) or self:getDamagedEffects(player, sgs.oljijiangsource, true)) then return "." end
			table.insert(jijiangtargets, player)
		end
	end

	if #jijiangtargets == 0 then
		return self:getCardId("Slash") or "."
	end

	self:sort(jijiangtargets, "defenseSlash")
	local slashes = self:getCards("Slash")
	for _, slash in ipairs(slashes) do
		for _, target in ipairs(jijiangtargets) do
			if not self:slashProhibit(slash, target, sgs.oljijiangsource) and self:slashIsEffective(slash, target, sgs.oljijiangsource) then
				return slash:toString()
			end
		end
	end
	return "."
end

function sgs.ai_cardsview_valuable.oljijiang(self, class_name, player, need_lord)
	if class_name == "Slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		and not player:hasFlag("Global_JijiangFailed") and (need_lord == false or player:hasLordSkill("oljijiang")) then
		local current = self.room:getCurrent()
		if current:getKingdom() == "shu" and self:getOverflow(current) > 2 and not self:hasCrossbowEffect(current) then
			self.player:setFlags("stack_overflow_jijiang")
			local isfriend = self:isFriend(current, player)
			self.player:setFlags("-stack_overflow_jijiang")
			if isfriend then return "@OLJijiangCard=." end
		end

		local cards = player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if isCard("Slash", card, player) then return end
		end

		local lieges = self.room:getLieges("shu", player)
		if lieges:isEmpty() then return end
		local has_friend = false
		for _, p in sgs.qlist(lieges) do
			self.player:setFlags("stack_overflow_jijiang")
			has_friend = self:isFriend(p, player)
			self.player:setFlags("-stack_overflow_jijiang")
			if has_friend then break end
		end
		if has_friend then return "@OLJijiangCard=." end
	end
end

sgs.ai_skill_playerchosen.oljijiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _,p in ipairs(targets) do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end
	return nil
end

--替身
sgs.ai_skill_invoke.oltishen = function(self, data)
	return self:isWeak()
end

--龙胆
local ollongdan_skill={}
ollongdan_skill.name="ollongdan"
table.insert(sgs.ai_skills,ollongdan_skill)
ollongdan_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	for _,id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(cards, true)

	for _,c in ipairs(cards) do
		if c:isKindOf("Analeptic") then
			return sgs.Card_Parse(("peach:ollongdan[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
		end
	end
	
	for _,c in ipairs(cards) do
		if c:isKindOf("Peach") then
			return sgs.Analeptic_IsAvailable(self.player) and sgs.Card_Parse(("analeptic:ollongdan[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
		end
	end

	for _,c in ipairs(cards) do
		if c:isKindOf("Jink") then
			return sgs.Card_Parse(("slash:ollongdan[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
		end
	end
end

sgs.ai_view_as.ollongdan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("slash:ollongdan[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:ollongdan[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Peach") then
			return ("analeptic:ollongdan[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Analeptic") then
			return ("peach:ollongdan[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ollongdan_keep_value = sgs.longdan_keep_value

--涯角
sgs.ai_skill_invoke.olyajiao = true

sgs.ai_skill_playerchosen.olyajiao = function(self, targets)
	local id = self.player:getMark("olyajiao")
	local card = sgs.Sanguosha:getCard(id)
	local cards = { card }
	local c, friend = self:getCardNeedPlayer(cards, self.friends)
	if friend then return friend end

	self:sort(self.friends)
	for _, friend in ipairs(self.friends) do
		if self:isValuableCard(card, friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
	local trash = card:isKindOf("Disaster") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace")
	if trash then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPhase() > sgs.Player_Play and self:needKongcheng(enemy, true) and not hasManjuanEffect(enemy) then return enemy end
		end
	end
	for _, friend in ipairs(self.friends) do
		if not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
end

sgs.ai_playerchosen_intention.olyajiao = function(self, from, to)
	if not self:needKongcheng(to, true) and not hasManjuanEffect(to) then sgs.updateIntention(from, to, -50) end
end

sgs.ai_skill_playerchosen.olyajiao_discard = function(self, targets)
	return self:findPlayerToDiscard("hej", false, true, targets)
end

--救援
sgs.ai_skill_playerchosen.oljiuyuan = function(self, targets)
	return sgs.ai_skill_playerchosen.tenyearjiuyuan(self, targets)
end

--博图
sgs.ai_skill_invoke.olbotu = true

--雷击
sgs.ai_skill_invoke.olleiji = true

sgs.ai_skill_playerchosen.olleiji = function(self, targets)
	return sgs.ai_skill_playerchosen.leiji(self, targets)
end

sgs.ai_playerchosen_intention.olleiji = sgs.ai_playerchosen_intention.leiji

function sgs.ai_slash_prohibit.olleiji(self, from, to, card) -- @todo: Qianxi flag name
	if self:isFriend(to) then return false end
	if to:hasSkills("hongyan|olhongyan") then return false end
	if to:hasFlag("QianxiTarget") and (not self:hasEightDiagramEffect(to) or self.player:hasWeapon("qinggang_sword")) then return false end
	local hcard = to:getHandcardNum()
	if self:canLiegong(to, from) then return false end
	if from:getRole() == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(from)) do
			if sgs.evaluatePlayerRole(player) == "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and self.player:getHp() >= 4 and (self:getCardsNum("Peach") > 0  or self.player:hasSkills("ganglie|neoganglie")) then
			return false
		end
	end

	if sgs.card_lack[to:objectName()]["Jink"] == 2 then return true end
	if getKnownCard(to, self.player, "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if not from then
		from = self.room:getCurrent()
	end
	if self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) then return true end
end

--鬼道
sgs.ai_skill_cardask["@olguidao-card"]=function(self, data)
	return sgs.ai_skill_cardask["@guidao-card"](self, data)
end

function sgs.ai_cardneed.olguidao(to, card, self)
	return sgs.ai_cardneed.guidao(to, card, self)
end

sgs.ai_suit_priority.olguidao = sgs.ai_suit_priority.guidao

--黄天
local olhuangtianv_skill = {}
olhuangtianv_skill.name = "olhuangtian_attach"
table.insert(sgs.ai_skills, olhuangtianv_skill)
olhuangtianv_skill.getTurnUseCard = function(self)
	if self.player:getKingdom() ~= "qun" then return nil end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards,true)
	
	if self:getCardsNum("Jink", "h") > 1 then
		for _,acard in ipairs(cards)  do
			if acard:isKindOf("Jink") then
				card = acard
				break
			end
		end
	end
	
	if self:getOverflow(self.player) > 0 then
		for _,acard in ipairs(cards)  do
			if acard:getSuit() == sgs.Card_Spade then
				card = acard
				break
			end
		end
	end
	
	if not card then return nil end

	local card_id = card:getEffectiveId()
	local card_str = "@OLHuangtianCard=" .. card_id
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func.OLHuangtianCard = function(card, use, self)
	if self:needBear() then
		return "."
	end
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("olhuangtian") and friend:getMark("olhuangtian-PlayClear") <= 0 then
			if not hasManjuanEffect(friend) then
				table.insert(targets, friend)
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	elseif self:getCardsNum("Slash", "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("olhuangtian") and enemy:getMark("olhuangtian-PlayClear") <= 0 then
				if not hasManjuanEffect(enemy, true) then
					if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
						table.insert(targets, enemy)
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:hasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:hasUsed("XianzhenCard") then
				flag = true
			elseif self.player:hasSkill("tenyearxianzhen") and not self.player:hasUsed("TenyearXianzhenCard") then
				flag = true
			elseif self.player:hasSkill("mobilexianzhen") and not self.player:hasUsed("MobileXianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > card:getNumber() then --可以保证拼点成功
					self:sort(targets, "defense", true)
					for _,enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
							use.card = card
							enemy:setFlags("AI_HuangtianPindian")
							if use.to then
								use.to:append(enemy)
							end
							break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.OLHuangtianCard = function(self, card, from, tos)
	return sgs.ai_card_intention.HuangtianCard(self, card, from, tos)
end

sgs.ai_use_priority.OLHuangtianCard = sgs.ai_use_priority.HuangtianCard
sgs.ai_use_value.OLHuangtianCard = sgs.ai_use_value.HuangtianCard

--蛊惑
sgs.ai_skill_choice.olguhuo = function(self, choices, data)
	local yuji = data:toPlayer()
	if not yuji or self:isEnemy(yuji) then return "noquestion" end
	local guhuoname = self.room:getTag("OLGuhuoType"):toString()
	if guhuoname == "peach+analeptic" then guhuoname = "peach" end
	if guhuoname == "normal_slash" then guhuoname = "slash" end
	local guhuocard = sgs.Sanguosha:cloneCard(guhuoname)
	local guhuotype = guhuocard:getClassName()
	if guhuotype and self:getRestCardsNum(guhuotype, yuji) == 0 and self.player:getHp() > 0 then return "question" end
	if guhuotype and guhuotype == "AmazingGrace" then return "noquestion" end
	if self.player:hasSkill("hunzi") and self.player:getMark("hunzi") == 0 and math.random(1, 15) ~= 1 then return "noquestion" end
	if guhuotype:match("Slash") then
		if yuji:getState() ~= "robot" and math.random(1, 8) == 1 then return "question" end
		if not self:hasCrossbowEffect(yuji) then return "noquestion" end
	end
	local x = 5
	if guhuoname == "peach" or guhuoname == "ex_nihilo" then
		x = 2
		if getKnownCard(yuji, self.player, guhuotype, false) > 0 then x = x * 3 end
	end
	return math.random(1, x) == 1 and "question" or "noquestion"
end

local olguhuo_skill = {}
olguhuo_skill.name = "olguhuo"
table.insert(sgs.ai_skills, olguhuo_skill)
olguhuo_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:getMark("olguhuo-Clear") > 0 then return end
	local current = self.room:getCurrent()
	if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then return end

	local cards = sgs.QList2Table(self.player:getHandcards())
	local GuhuoCard_str = {}

	for _, card in ipairs(cards) do
		if card:isNDTrick() then
			local dummyuse = { isDummy = true }
			self:useTrickCard(card, dummyuse)
			if dummyuse.card then table.insert(GuhuoCard_str, "@OLGuhuoCard=" .. card:getId() .. ":" .. card:objectName()) end
		end
	end

	local peach_str = self:getGuhuoCard("Peach", true, 1)
	if peach_str then table.insert(GuhuoCard_str, peach_str) end

	local fakeCards = {}

	for _, card in sgs.qlist(self.player:getHandcards()) do
		if (card:isKindOf("Slash") and self:getCardsNum("Slash", "h") >= 2 and not self:hasCrossbowEffect())
			or (card:isKindOf("Jink") and self:getCardsNum("Jink", "h") >= 3)
			or (card:isKindOf("EquipCard") and self:getSameEquip(card))
			or card:isKindOf("Disaster") then
			table.insert(fakeCards, card)
		end
	end
	self:sortByUseValue(fakeCards, true)

	local function fake_guhuo(objectName)
		if #fakeCards == 0 then return end

		local fakeCard
		local guhuo = "peach|ex_nihilo|snatch|dismantlement|amazing_grace|archery_attack|savage_assault"
		local ban = table.concat(sgs.Sanguosha:getBanPackages(), "|")
		if not ban:match("maneuvering") then guhuo = guhuo .. "|fire_attack" end
		local guhuos = guhuo:split("|")
		for i = 1, #guhuos do
			local forbidden = guhuos[i]
			local forbid = sgs.Sanguosha:cloneCard(forbidden)
			if self.player:isLocked(forbid) then
				table.remove(guhuos, i)
				i = i - 1
			end
		end
		for i=1, 10 do
			local card = fakeCards[math.random(1, #fakeCards)]
			local newguhuo = objectName or guhuos[math.random(1, #guhuos)]
			local guhuocard = sgs.Sanguosha:cloneCard(newguhuo, card:getSuit(), card:getNumber())
			if self:getRestCardsNum(guhuocard:getClassName()) > 0 then
				local dummyuse = {isDummy = true}
				if newguhuo == "peach" then self:useBasicCard(guhuocard, dummyuse) else self:useTrickCard(guhuocard, dummyuse) end
				if dummyuse.card then
					fakeCard = sgs.Card_Parse("@OLGuhuoCard=" .. card:getId() .. ":" .. newguhuo)
					break
				end
			end
		end
		return fakeCard
	end

	local enemy_num = #self.enemies
	local can_question = enemy_num
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("chanyuan") or (enemy:hasSkill("hunzi") and enemy:getMark("hunzi") == 0) then can_question = can_question - 1 end
	end
	local ratio = (can_question == 0) and 100 or (enemy_num / can_question)
	if #GuhuoCard_str > 0 then
		local guhuo_str = GuhuoCard_str[math.random(1, #GuhuoCard_str)]

		local str = guhuo_str:split("=")
		str = str[2]:split(":")
		local cardid, cardname = str[1], str[2]

		if sgs.Sanguosha:getCard(cardid):objectName() == cardname and cardname == "ex_nihilo" then
			if math.random(1, 3) <= ratio then
				local fake_exnihilo = fake_guhuo(cardname)
				if fake_exnihilo then return fake_exnihilo end
			end
			return sgs.Card_Parse(guhuo_str)
		elseif math.random(1, 5) <= ratio then
			local fake_GuhuoCard = fake_guhuo()
			if fake_GuhuoCard then return fake_GuhuoCard end
		else
			return sgs.Card_Parse(guhuo_str)
		end
	elseif math.random(1, 5) <= 3 * ratio then
		local fake_GuhuoCard = fake_guhuo()
		if fake_GuhuoCard then return fake_GuhuoCard end
	end

	if self:isWeak() then
		local peach_str = self:getGuhuoCard("Peach", true, 1)
		if peach_str then
			local card = sgs.Card_Parse(peach_str)
			local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
			local dummyuse = { isDummy = true }
			self:useBasicCard(peach, dummyuse)
			if dummyuse.card then return card end
		end
	end
	local slash_str = self:getGuhuoCard("Slash", true, 1)
	if slash_str and self:slashIsAvailable() then
		local card = sgs.Card_Parse(slash_str)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		local dummyuse = { isDummy = true }
		self:useBasicCard(slash, dummyuse)
		if dummyuse.card then return card end
	end
end

sgs.ai_skill_use_func.OLGuhuoCard=function(card,use,self)
	local userstring=card:toString()
	userstring=(userstring:split(":"))[3]
	local guhuocard=sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	guhuocard:setSkillName("olguhuo")
	if guhuocard:getTypeId() == sgs.Card_TypeBasic then
		if not use.isDummy and use.card and guhuocard:isKindOf("Slash") and (not use.to or use.to:isEmpty()) then return end
		self:useBasicCard(guhuocard, use)
	else
		assert(guhuocard)
		self:useTrickCard(guhuocard, use)
	end
	if not use.card then return end
	use.card=card
end

sgs.ai_use_priority.OLGuhuoCard = sgs.ai_use_priority.GuhuoCard

sgs.ai_skill_choice.olguhuo_saveself = function(self, choices)
	return sgs.ai_skill_choice.guhuo_saveself(self, choices)
end

sgs.ai_skill_choice.olguhuo_slash = function(self, choices)
	return sgs.ai_skill_choice.guhuo_slash(self, choices)
end

sgs.ai_skill_discard.olguhuo = function(self, discard_num, min_num, optional, include_equip)
	if self.player:hasSkill("zhaxiang") and self:canDraw() and not self:willSkipPlayPhase() and (self.player:getHp() > 0 or hasBuquEffect(self.player) or self:getSaveNum(true) > 0) then
		return {}
	end
	return self:askForDiscard("dummy", 1, 1, false, include_equip)
end

--设变
sgs.ai_skill_invoke.olshebian = function(self, data)
	local from, card, to = self:moveField(nil, "e")
	if from and card and to then
		sgs.ai_skill_playerchosen.olshebian_from = from
		sgs.ai_skill_cardchosen.olshebian = card
		sgs.ai_skill_playerchosen.olshebian_to = to
		return true
	end
	return false
end

--奇谋
local olqimou_skill = {}
olqimou_skill.name = "olqimou"
table.insert(sgs.ai_skills, olqimou_skill)
olqimou_skill.getTurnUseCard = function(self)
	if self.player:getMark("@olqimouMark") <= 0 or #self.enemies <= 0 then return end
	if self.player:getHp() < 1 and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 0 then return end
	return sgs.Card_Parse("@OLQimouCard=.")
end

sgs.ai_skill_use_func.OLQimouCard = function(card, use, self)
	self.olqimou_lose = 0
	local slashcount = self:getCardsNum("Slash") - 1
	self.olqimou_lose = math.min(slashcount, self.player:getHp())
	if self.olqimou_lose <= 0 then return end
	
	self.room:addDistance(self.player, -self.olqimou_lose)
	local slash = self:getCard("Slash")
	if not slash then self.room:addDistance(self.player, self.olqimou_lose) return end
	
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	if slash then self:useBasicCard(slash, dummy_use) end
	self.room:addDistance(self.player, self.olqimou_lose)
	if not dummy_use.card or dummy_use.to:isEmpty() then return end
	use.card = card
end

sgs.ai_skill_choice.olqimou = function(self, choices)
	choices = choices:split("+")
	local num = self.olqimou_lose
	for _,choice in ipairs(choices) do
		if tonumber(choice) == num then return choice end
	end
	return choices[1]
end

sgs.ai_use_priority.OLQimouCard = sgs.ai_use_priority.TenyearQimouCard

--天香
sgs.ai_skill_use["@@oltianxiang"] = function(self, prompt)
	return sgs.ai_skill_use["@@tenyeartianxiang"](self, prompt)
end

--红颜
sgs.ai_suit_priority.olhongyan = sgs.ai_suit_priority.hongyan

--飘零
sgs.ai_skill_invoke.olpiaoling = true

sgs.ai_skill_playerchosen.olpiaoling = function(self, targets)
	local id = self.player:getMark("olpiaoling")
	local card = sgs.Sanguosha:getCard(id)
	local cards = { card }
	local c, friend = self:getCardNeedPlayer(cards, self.friends)
	if friend then return friend end

	self:sort(self.friends)
	for _, friend in ipairs(self.friends) do
		if self:isValuableCard(card, friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
	local trash = card:isKindOf("Disaster") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace")
	if trash then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPhase() > sgs.Player_Play and self:needKongcheng(enemy, true) and not hasManjuanEffect(enemy) then return enemy end
		end
	end
	for _, friend in ipairs(self.friends) do
		if not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
end

sgs.ai_playerchosen_intention.olpiaoling = function(self, from, to)
	if not self:needKongcheng(to, true) and not hasManjuanEffect(to) then sgs.updateIntention(from, to, -50) end
end

sgs.ai_skill_discard.olpiaoling = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, include_equip)
end

--乱击
local olluanji_skill = {}
olluanji_skill.name = "olluanji"
table.insert(sgs.ai_skills, olluanji_skill)
olluanji_skill.getTurnUseCard = function(self)
	local archery = sgs.Sanguosha:cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then

						local card_str = ("archery_attack:olluanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = { isDummy = true }
						self:useTrickCard(archeryattack, dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("archery_attack:olluanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end

sgs.ai_skill_playerchosen.olluanji = function(self, targets)
	local use = self.player:getTag("olluanji_data"):toCardUse()
	if not use then return nil end
	self:sort(self.friends_noself)
	local lord = self.room:getLord()
	if lord and lord:objectName() ~= self.player:objectName() and self:isFriend(lord) and self:isWeak(lord) and self:hasTrickEffective(use.card, lord, self.player) then
		return lord
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:hasTrickEffective(use.card, friend, self.player) then
			return friend
		end
	end
	return nil
end

--血裔
sgs.ai_skill_invoke.olxueyi = function(self, data)
	if not self:canDraw() then return false end
	if self:willSkipPlayPhase() then return false end
	local num = 2  --偷懒不管别的摸牌数了，也不管手里的【无中生有】了
	if self:willSkipDrawPhase() then
		num = 0
	end
	if self.player:getHandcardNum() >= 4 then return false end
	if self.player:getHandcardNum() + 1 + num < self.player:getMaxCards() - 2 then return true end
	return false
end

--血裔-第二版
sgs.ai_skill_invoke.secondolxueyi = function(self, data)
	if not self:canDraw() then return false end
	if self.player:getHandcardNum() >= 4 then return false end
	if self.player:getHandcardNum() + 1 < self.player:getMaxCards() - 1 then return true end
	return false
end

--火计
local olhuoji_skill={}
olhuoji_skill.name="olhuoji"
table.insert(sgs.ai_skills,olhuoji_skill)
olhuoji_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards) do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.FireAttack or self:getOverflow() > 0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = { isDummy = true , to = sgs.SPlayerList() }
				self:useBasicCard(acard, dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then keep = true break end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack + 0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("fire_attack:olhuoji[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end

sgs.ai_cardneed.olhuoji = function(to, card, self)
	return sgs.ai_cardneed.huoji(to, card, self)
end

--看破
sgs.ai_view_as.olkanpo = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or card_place == sgs.Player_PlaceEquip then
		if card:isBlack() then
			return ("nullification:olkanpo[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_cardneed.olkanpo = function(to, card, self)
	return sgs.ai_cardneed.kanpo(to, card, self)
end

sgs.olkanpo_suit_value = sgs.kanpo_suit_value

--连环
local ollianhuan_skill={}
ollianhuan_skill.name="ollianhuan"
table.insert(sgs.ai_skills,ollianhuan_skill)
ollianhuan_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end

	local card
	self:sortByUseValue(cards, true)

	local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
	if slash then
		local dummy_use = { isDummy = true }
		self:useBasicCard(slash, dummy_use)
		if not dummy_use.card then slash = nil end
	end

	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Club then
			local shouldUse = true
			if self:getUseValue(acard) > sgs.ai_use_value.IronChain and acard:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(acard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if acard:getTypeId() == sgs.Card_TypeEquip then
				local dummy_use = { isDummy = true }
				self:useEquipCard(acard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse and (not slash or slash:getEffectiveId() ~= acard:getEffectiveId()) then
				card = acard
				break
			end
		end
	end

	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("iron_chain:ollianhuan[club:%s]=%d"):format(number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_cardneed.ollianhuan = function(to, card)
	return sgs.ai_cardneed.lianhuan(to, card)
end

--涅槃
sgs.ai_skill_invoke.olniepan = function(self, data)
	return sgs.ai_skill_invoke.niepan(self, data)
end

sgs.ai_skill_choice.olniepan = function(self, choices)
	choices = choices:split("+")
	if self.player:hasArmorEffect("eight_diagram") or self.player:getArmor() then
		if table.contains(choices, "bazhen") then table.removeOne(choices, "bazhen") end
	end
	if table.contains(choices, "bazhen") then return "bazhen" end
	return choices[math.random(1, #choices)]
end

--鞬出
sgs.ai_skill_invoke.oljianchu = function(self,data)
	return sgs.ai_skill_invoke.tenyearjianchu(self,data)
end

--酣战
sgs.ai_skill_invoke.olhanzhan = function(self, data)
	local to = data:toPlayer()
	if to and not self:isFriend(to) then return true end
	return false
end

--第二版酣战
sgs.ai_skill_invoke.secondolhanzhan = function(self, data)
	return sgs.ai_skill_invoke.olhanzhan(self, data)
end

sgs.ai_skill_use["@@secondolhanzhan"] = function(self, prompt, method)
	local ids = self.player:getTag("secondolhanzhan_forAI"):toStringList()
	if #ids <= 0 then return "." end
	for _, id in ipairs(ids) do
		id = tonumber(id)
		local card = sgs.Sanguosha:getCard(id)
		if not self.player:canUse(card) then continue end
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardByClassName(card, dummyuse)
		if not dummyuse.to:isEmpty() then
			return "@SecondOLHanzhanCard=" .. id
		end
	end
	if not self:canDraw() then return "." end
	return "@SecondOLHanzhanCard=" .. tonumber(ids[1])
end

--武烈
sgs.ai_skill_use["@@olwulie"] = function(self, prompt, method)
	local num = self.player:getHp() - 1 + self:getSaveNum(true)
	if num <= 0 and hasBuquEffect(self.player) then
		local buqu, nosbuqu
		if self.player:hasSkill("buqu") then buqu = 4 - self.player:getPile("buqu") end
		if self.player:hasSkill("nosbuqu") then nosbuqu = 4 - self.player:getPile("nosbuqu") end
		num = math.max(nosbuqu, buqu)
	end
	num = math.min(num, #self.friends_noself)
	if num <= 0 then return "." end
	
	self:sort(self.friends_noself)
	local friends = {}
	for i = 1, num do
		table.insert(friends, self.friends_noself[i]:objectName())
	end
	if #friends > 0 then return "@OLWulieCard=.->" .. table.concat(friends, "+") end
	return "."
end

--酒池
local oljiuchi_skill={}
oljiuchi_skill.name="oljiuchi"
table.insert(sgs.ai_skills,oljiuchi_skill)
oljiuchi_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	for _,id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if acard:getSuit() == sgs.Card_Spade then
			card = acard
			break
		end
	end

	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("analeptic:oljiuchi[spade:%s]=%d"):format(number, card_id)
	local analeptic = sgs.Card_Parse(card_str)
	
	assert(analeptic)
	if sgs.Analeptic_IsAvailable(self.player, analeptic) then
		return analeptic
	end
end

sgs.ai_view_as.oljiuchi = function(card, player, card_place)
	local str = sgs.ai_view_as.jiuchi(card, player, card_place)
	if not str or str == "" or str == nil then return end
	return string.gsub(str, "jiuchi", "oljiuchi")
end

function sgs.ai_cardneed.oljiuchi(to, card, self)
	return sgs.ai_cardneed.jiuchi(to, card, self)
end

--暴虐
sgs.ai_skill_invoke.olbaonue = function(self, data)
	return true
end

--化身
function sgs.ai_skill_choice.olhuashen(self, choices, data, xiaode_choice)
	return sgs.ai_skill_choice.huashen(self, choices, data, xiaode_choice)
end

--放权
sgs.ai_skill_invoke.olfangquan = function(self, data)
	return sgs.ai_skill_invoke.fangquan(self, data)
end

sgs.ai_skill_use["@@olfangquan"] = function(self, prompt)
	local str = sgs.ai_skill_use["@@fangquan"](self, prompt)
	if not str or str == "" or str == nil then return "." end
	return string.gsub(str, "FangquanCard", "OLFangquanCard")
end

--思蜀
sgs.ai_skill_playerchosen.olsishu = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets) do
		if not self:isFriend(p) or p:getMark("&olsishu") > 0 then continue end
		if p:containsTrick("indulgence") then
			if p:containsTrick("YanxiaoCard") or (p:hasSkill("qiaobian") and p:canDiscard(p, "h")) then continue end
			return p
		end
	end
	for _,p in ipairs(targets) do
		if not self:isFriend(p) or p:getMark("&olsishu") > 0 then continue end
		if p:containsTrick("indulgence") then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if not self:isFriend(p) or p:getMark("&olsishu") > 0 then continue end
		return p
	end
	return nil
end

--制霸
local olzhiba_skill = {}
olzhiba_skill.name = "olzhiba"
table.insert(sgs.ai_skills, olzhiba_skill)
olzhiba_skill.getTurnUseCard = function(self)
	if not self.player:canPindian() or self:needBear() or self.player:hasUsed("OLZhibaCard") then return end
	return sgs.Card_Parse("@OLZhibaCard=.")
end

sgs.ai_use_priority.OLZhibaCard = 7

sgs.ai_skill_use_func.OLZhibaCard = function(card, use, self)
	local enemies = {}
	for _, p in ipairs(self.enemies) do
		if p:getKingdom() == "wu" and self.player:canPindian(p) then
			table.insert(enemies, p)
		end
	end
	if #enemies <= 0 then return end
	self:sort(enemies, "defense")
	
	local max_card = self:getMaxCard()
	if not max_card then return end
	local point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then point = 13 end
	
	for _, p in ipairs(enemies) do
		local zhiba_str
		
		local enemy_max_card = self:getMaxCard(p)
		if not enemy_max_card then continue end
		local enemy_point = max_card:getNumber()
		if p:hasSkill("tianbian") and enemy_max_card:getSuit() == sgs.Card_Heart then enemy_point = 13 end

		if point > 10 and point > enemy_point then
			if isCard("Jink", max_card, self.player) and self:getCardsNum("Jink") == 1 then return end
			if isCard("Peach", max_card, self.player) or isCard("Analeptic", max_card, self.player) then return end
			self.olzhiba_card = max_card
			zhiba_str = "@OLZhibaCard=."
		end

		if zhiba_str then
			use.card = sgs.Card_Parse(zhiba_str)
			if use.to then use.to:append(p) end
			return
		end
	end
end

sgs.ai_skill_choice.olzhiba_pindian_obtain = function(self, choices)
	if self.player:isKongcheng() and self:needKongcheng() then return "reject" end
	return "obtainPindianCards"
end

function sgs.ai_skill_pindian.olzhiba(minusecard, self, requestor, maxcard)
	local cards, maxcard = sgs.QList2Table(self.player:getHandcards())
	local function compare_func(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_card_intention.OLZhibaCard = 50
sgs.ai_choicemade_filter.pindian.olzhiba = 50

--制霸拼点
local olzhiba_pindian_skill = {}
olzhiba_pindian_skill.name = "olzhiba_pindian"
table.insert(sgs.ai_skills, olzhiba_pindian_skill)
olzhiba_pindian_skill.getTurnUseCard = function(self)
	if not self.player:canPindian() or self:needBear() or self:getOverflow() <= 0 or self.player:getKingdom() ~= "wu" then return end
	return sgs.Card_Parse("@OLZhibaPindianCard=.")
end

sgs.ai_use_priority.OLZhibaPindianCard = 0

sgs.ai_skill_use_func.OLZhibaPindianCard = function(card, use, self)
	local lords = {}
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:hasLordSkill("olzhiba") and self.player:canPindian(player) and player:getMark("olzhiba-PlayClear") <= 0 and self:isFriend(player) then
			table.insert(lords, player)
		end
	end
	if #lords == 0 then return end
	self:sort(lords, "defense")
	for _, lord in ipairs(lords) do
		local zhiba_str
		local cards = self.player:getHandcards()

		local max_num = 0, max_card
		local min_num = 14, min_card
		for _, hcard in sgs.qlist(cards) do
			if hcard:getNumber() > max_num then
				max_num = hcard:getNumber()
				max_card = hcard
			end

			if hcard:getNumber() <= min_num then
				if hcard:getNumber() == min_num then
					if min_card and self:getKeepValue(hcard) > self:getKeepValue(min_card) then
						min_num = hcard:getNumber()
						min_card = hcard
					end
				else
					min_num = hcard:getNumber()
					min_card = hcard
				end
			end
		end

		local lord_max_num = 0, lord_max_card
		local lord_min_num = 14, lord_min_card
		local lord_cards = lord:getHandcards()
		local flag = string.format("%s_%s_%s","visible",global_room:getCurrent():objectName(),lord:objectName())
		for _, lcard in sgs.qlist(lord_cards) do
			if (lcard:hasFlag("visible") or lcard:hasFlag(flag)) and lcard:getNumber() > lord_max_num then
				lord_max_card = lcard
				lord_max_num = lcard:getNumber()
			end
			if lcard:getNumber() < lord_min_num then
				lord_min_num = lcard:getNumber()
				lord_min_card = lcard
			end
		end

		if not lord:hasSkill("manjuan") and ((lord_max_num > 0 and min_num <= lord_max_num) or min_num < 7) then
			if isCard("Jink", min_card, self.player) and self:getCardsNum("Jink") == 1 then return end
			self.olzhiba_pindian_card = min_card
			zhiba_str = "@OLZhibaPindianCard=."
		end

		if zhiba_str then
			use.card = sgs.Card_Parse(zhiba_str)
			if use.to then use.to:append(lord) end
			return
		end
	end
end

sgs.ai_skill_choice.olzhiba_pindian = function(self, choices)
	local who = self.room:getCurrent()
	local cards = self.player:getHandcards()
	local has_large_number, all_small_number = false, true
	for _, c in sgs.qlist(cards) do
		if c:getNumber() > 11 then
			has_large_number = true
			break
		end
	end
	for _, c in sgs.qlist(cards) do
		if c:getNumber() > 4 then
			all_small_number = false
			break
		end
	end
	if all_small_number or (self:isEnemy(who) and not has_large_number) then return "reject"
	else return "accept"
	end
end

sgs.ai_skill_choice.olzhiba_pindian_obtain = function(self, choices)
	if self.player:isKongcheng() and self:needKongcheng() then return "reject" end
	return "obtainPindianCards"
end

function sgs.ai_skill_pindian.olzhiba_pindian(minusecard, self, requestor, maxcard)
	local cards, maxcard = sgs.QList2Table(self.player:getHandcards())
	local function compare_func(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_card_intention.OLZhibaPindianCard = 0

sgs.ai_choicemade_filter.pindian.olzhiba_pindian = function(self, from, promptlist)
	local number = sgs.Sanguosha:getCard(tonumber(promptlist[4])):getNumber()
	local lord = findPlayerByObjectName(self.room, promptlist[5])
	if not lord then return end
	local lord_max_card = self:getMaxCard(lord)
	if lord_max_card and lord_max_card:getNumber() >= number then sgs.updateIntention(from, lord, -60)
	elseif lord_max_card and lord_max_card:getNumber() < number then sgs.updateIntention(from, lord, 60)
	elseif number < 6 then sgs.updateIntention(from, lord, -60)
	elseif number > 8 then sgs.updateIntention(from, lord, 60)
	end
end

--屯田
sgs.ai_skill_invoke.oltuntian = function(self, data)
	return sgs.ai_skill_invoke.tuntian(self, data)
end

--趫猛
sgs.ai_skill_invoke.olqiaomeng = function(self, data)
	local player = data:toPlayer()
	if self:isFriend(player) then
		if player:getArmor() and self:needToThrowArmor(player) and self.player:canDiscard(player, player:getArmor():getEffectiveId()) then return true end
		if self.player:canDiscard(player, "j") and not player:containsTrick("YanxiaoCard") then
			if player:containsTrick("indulgence") or player:containsTrick("supply_shortage") then return true end
			if (player:containsTrick("lightning") and self:getFinalRetrial(player) == 2) or #self.enemies == 0 then return true end
		end
		return false
	end
	return not self:doNotDiscard(player, "e")
end

--长标

--挑衅

--再起

--断粮

--截辎

--巧变