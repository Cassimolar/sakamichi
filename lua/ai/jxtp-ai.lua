--制衡
local tenyearzhiheng_skill = {}
tenyearzhiheng_skill.name = "tenyearzhiheng"
table.insert(sgs.ai_skills, tenyearzhiheng_skill)
tenyearzhiheng_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("TenyearZhihengCard") then
		return sgs.Card_Parse("@TenyearZhihengCard=.")
	end
end

sgs.ai_skill_use_func.TenyearZhihengCard = function(card, use, self)
	--[[local _use = use
	sgs.ai_skill_use_func.ZhihengCard(card, _use, self)
	if _use.card then
		local str = _use.card:toString()
		str = string.gsub(str, "ZhihengCard", "TenyearZhihengCard")
		use.card = sgs.Card_Parse(str)
	end]]
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
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards > 0 then
		use.card = sgs.Card_Parse("@TenyearZhihengCard=" .. table.concat(use_cards, "+"))
		return
	end
end

sgs.ai_use_value.TenyearZhihengCard = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority.TenyearZhihengCard = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit.TenyearZhihengCard = sgs.dynamic_value.benefit.ZhihengCard

function sgs.ai_cardneed.tenyearzhiheng(to, card)
	return not card:isKindOf("Jink")
end

--救援
sgs.ai_skill_playerchosen.tenyearjiuyuan = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if self:isWeak(p) and p:isLord() then
			return p
		end
	end
	if self:isWeak() then return nil end
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		if self:isWeak(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		return p
	end
	return nil
end

--结姻
function getTenyearJieyinId(self, male, equips, cards)
	if #equips <= 0 and #cards <= 0 then return -1 end
	if self.player:hasSkills(sgs.lose_equip_skill) then
		self:sortByKeepValue(equips)
		for _,c in ipairs(equips) do
			local index = c:getRealCard():toEquipCard():location()
			if male:getEquip(index) or not male:hasEquipArea(index) or (c:isKindOf("Armor") and not male:getArmor() and male:hasSkills("bazhen|linglong|bossmanjia|yizhong")) then
				continue
			end
			return c:getEffectiveId()
		end
	end
	if self.player:getArmor() and self:needToThrowArmor() then
		local armor_id = self.player:getArmor():getEffectiveId()
		local armor = sgs.Sanguosha:getCard(armor_id)
		if not male:getEquip(1) and male:hasEquipArea(1) and not male:hasSkills("bazhen|linglong|bossmanjia|yizhong") then
			return armor_id
		end
	end
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		if self.player:canDiscard(self.player, c:getEffectiveId()) then
			return c:getEffectiveId()
		end
	end
	return -1
end

local tenyearjieyin_skill={}
tenyearjieyin_skill.name = "tenyearjieyin"
table.insert(sgs.ai_skills,tenyearjieyin_skill)
tenyearjieyin_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("TenyearJieyinCard") then return nil end
	return sgs.Card_Parse("@TenyearJieyinCard=.")
end

sgs.ai_skill_use_func.TenyearJieyinCard = function(card, use, self)
	local cards, equips = {}, {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if self.player:canDiscard(self.player, c:getEffectiveId()) then
			table.insert(cards, c)
		end
		if c:isKindOf("EquipCard") then
			table.insert(equips, c)
		end
	end
	for _,c in sgs.qlist(self.player:getCards("e")) do
		table.insert(equips, c)
	end
	if #cards <= 0 and #equips <= 0 then return end
	
	local weak_friends, recover_friends, draw_friends, not_friends, enemies = {}, {}, {}, {}, {}
	
	if self:isWeak() and self.player:getLostHp() > 0 then
		self:sort(self.friends_noself)
		for _,p in ipairs(self.friends_noself) do
			if p:getHp() > self.player:getHp() and self:canDraw(p) and p:isMale() then
				table.insert(draw_friends, p)
			end
		end
		for _,p in ipairs(draw_friends) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id > 0 then
				use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
		
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:getHp() > self.player:getHp() and not self:isEnemy(p) and p:isMale() then
				table.insert(not_friends, p)
			end
		end
		for _,p in ipairs(not_friends) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id > 0 then
				use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
		
		self:sort(self.enemies)
		for _,p in ipairs(self.enemies) do
			if p:getHp() > self.player:getHp() and not self:canDraw(p) and p:isMale() then
				table.insert(enemies, p)
			end
		end
		for _,p in ipairs(enemies) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id > 0 then
				use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
		
		self.enemies = sgs.reverse(self.enemies)
		for _,p in ipairs(self.enemies) do
			if p:getHp() > self.player:getHp() and p:isMale() then
				table.insert(enemies, p)
			end
		end
		for _,p in ipairs(enemies) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id > 0 then
				use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
	end
	
	for _,p in ipairs(self.friends_noself) do
		if self:isWeak(p) and p:getHp() < self.player:getHp() and p:getLostHp() > 0 and p:isMale() then
			table.insert(weak_friends, p)
		end
	end
	if #weak_friends > 0 then
		self:sort(weak_friends, "hp")
		for _,p in ipairs(weak_friends) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id < 0 then continue end
			use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
			if use.to then use.to:append(p) end
			return
		end
	end
	
	for _,p in ipairs(self.friends_noself) do
		if p:getHp() < self.player:getHp() and p:getLostHp() > 0 and p:isMale() then
			table.insert(recover_friends, p)
		end
	end
	if #recover_friends > 0 then
		self:sort(recover_friends)
		for _,p in ipairs(recover_friends) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id < 0 then continue end
			use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
			if use.to then use.to:append(p) end
			return
		end
	end
	
	self:sort(self.friends_noself)
	for _,p in ipairs(self.friends_noself) do
		if p:getHp() > self.player:getHp() and self:canDraw(p) and p:isMale() then
			table.insert(draw_friends, p)
		end
	end
	for _,p in ipairs(draw_friends) do
		local id = getTenyearJieyinId(self, p, equips, cards)
		if id > 0 then
			use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
			if use.to then use.to:append(p) end
			return
		end
	end
	
	if self.player:getLostHp() > 0 then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:getHp() > self.player:getHp() and not self:isEnemy(p) and p:isMale() then
				table.insert(not_friends, p)
			end
		end
		for _,p in ipairs(not_friends) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id > 0 then
				use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
		
		self:sort(self.enemies)
		for _,p in ipairs(self.enemies) do
			if p:getHp() > self.player:getHp() and not self:canDraw(p) and p:isMale() then
				table.insert(enemies, p)
			end
		end
		for _,p in ipairs(enemies) do
			local id = getTenyearJieyinId(self, p, equips, cards)
			if id > 0 then
				use.card = sgs.Card_Parse("@TenyearJieyinCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearJieyinCard = 0

--仁德
local tenyearrende_skill = {}
tenyearrende_skill.name = "tenyearrende"
table.insert(sgs.ai_skills, tenyearrende_skill)
tenyearrende_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	return sgs.Card_Parse("@TenyearRendeCard=.")
end

sgs.ai_skill_use_func.TenyearRendeCard = function(card, use, self)
    local others = self.room:getOtherPlayers(self.player)
    local friends, enemies, unknowns = {}, {}, {}
    local arrange = {}
    arrange["count"] = 0
    for _,p in sgs.qlist(others) do
        if p:getMark("tenyearrendetarget-PlayClear") <= 0 then
            arrange[p:objectName()] = {}
            if self:isFriend(p) then
                table.insert(friends, p)
            elseif self:isEnemy(p) then
                table.insert(enemies, p)
            else
                table.insert(unknowns, p)
            end
        end
    end
    local new_friends = {}
    for _,friend in ipairs(friends) do
        local exclude = false
        if self:needKongcheng(friend, true) or self:willSkipPlayPhase(friend) then
            exclude = true
            if self:hasSkills("keji|qiaobian|shensu", friend) then
                exclude = false
            elseif friend:getHp() - friend:getHandcardNum() >= 3 then
                exclude = false
            elseif friend:isLord() and self:isWeak(friend) and self:getEnemyNumBySeat(self.player, friend) >= 1 then
                exclude = false
            end
        end
        if not exclude and not hasManjuanEffect(friend) and self:objectiveLevel(friend) <= -2 then
            table.insert(new_friends, friend)
        end
    end
    friends = new_friends
    local overflow = self:getOverflow()
    if overflow <= 0 and #friends == 0 then
        return 
    end
    local handcards = self.player:getHandcards()
    handcards = sgs.QList2Table(handcards)
    self:sortByUseValue(handcards)
    while true do
        if #handcards == 0 then
            break
        end
        local target, to_give, group = OlRendeArrange(self, handcards, friends, enemies, unknowns, arrange, false)
        if target and to_give and group then
            table.insert(arrange[target:objectName()], to_give)
            arrange["count"] = arrange["count"] + 1
            handcards = self:resetCards(handcards, to_give)
        else
            break
        end
    end
    local max_count, max_name = 0, nil
    for name, cards in pairs(arrange) do
        if type(cards) == "table" then
            local count = #cards
            if count > max_count then
                max_count = count
                max_name = name
            end
        end
    end
    if max_count == 0 or not max_name then
        return 
    end
    local max_target = nil
    for _,p in sgs.qlist(others) do
        if p:objectName() == max_name then
            max_target = p
            break
        end
    end
    if max_target and type(arrange[max_name]) == "table" and #arrange[max_name] > 0 then
        local to_use = {}
        for _,c in ipairs(arrange[max_name]) do
            table.insert(to_use, c:getEffectiveId())
        end
        local card_str = "@TenyearRendeCard="..table.concat(to_use, "+")
        local acard = sgs.Card_Parse(card_str)
        assert(acard)
        use.card = acard
        if use.to then
            use.to:append(max_target)
        end
    end
end

sgs.ai_use_value.TenyearRendeCard = sgs.ai_use_value.RendeCard
sgs.ai_use_priority.TenyearRendeCard = sgs.ai_use_priority.RendeCard
sgs.ai_card_intention.TenyearRendeCard = sgs.ai_card_intention.RendeCard
sgs.dynamic_value.benefit.TenyearRendeCard = true

sgs.ai_skill_askforag.tenyearrende = function(self, card_ids)
	local cards = {}
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getEngineCard(id)
		if card:isKindOf("Analeptic") and self:getCardsNum("Slash") == 0 then continue end  --这里应该判断会不会使用【杀】，偷懒一下
		if not card:targetFixed() then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
			self:useCardByClassName(card, dummy_use)
			if dummy_use.card and dummy_use.to:length() > 0 then
				table.insert(cards, card)
			end
		else
			table.insert(cards, card)
		end
	end
	if #cards > 0 then
		self:sortByUseValue(cards)
		return cards[1]:getEffectiveId()
	end
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getEngineCard(id)
		if card:isKindOf("Analeptic") then return id end
	end
	return card_ids[1]
end

sgs.ai_skill_invoke.tenyearrende = true

sgs.ai_skill_use["@@tenyearrende"] = function(self, prompt, method)
	local name = prompt:split(":")[2]
	if not name then return "." end
	local card = sgs.Sanguosha:cloneCard(name)
	card:setSkillName("_tenyearrende")
	return card:toString()
end

--武圣
sgs.ai_view_as.tenyearwusheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:tenyearwusheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local tenyearwusheng_skill = {}
tenyearwusheng_skill.name = "tenyearwusheng"
table.insert(sgs.ai_skills, tenyearwusheng_skill)
tenyearwusheng_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local red_card
	self:sortByUseValue(cards, true)

	local useAll = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
		disCrossbow = true
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self:sort(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange()
			and getCardsNum("Jink", enemy) < 1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end

	local nuzhan_trick = false
	local nuzhan_trick_e = false
	self:sort(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") and not self.player:hasFlag("hasUsedSlash") and self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
				nuzhan_trick_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end

	for _, card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) or disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0) then
			red_card = card
			break
		end
	end

	if nuzhan_equip then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("EquipCard") then
				red_card = card
				break
			end
		end
	end

	if nuzhan_trick then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard")then
				red_card = card
				break
			end
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("slash:tenyearwusheng[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

sgs.ai_cardneed.tenyearwusheng = sgs.ai_cardneed.wusheng

--义绝
function hasRedHandcard(self, target)
	if target:isKongcheng() then return false end
	local not_red, known = 0, 0
	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
	for _,c in sgs.qlist(target:getCards("h")) do
		if self.player:canSeeHandcard(target) or c:hasFlag("visible") or c:hasFlag(flag) then
			known = known + 1
			if c:isRed() then
				return true
			else
				not_red = not_red + 1
			end
		end
	end
	if known - not_red >= 2 then return true end
	if target:getHandcardNum() >= 3 then return true end
	return false
end

local tenyearyijue_skill = {}
tenyearyijue_skill.name = "tenyearyijue"
table.insert(sgs.ai_skills, tenyearyijue_skill)
tenyearyijue_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("TenyearYijueCard") and self.player:canDiscard(self.player, "he") then
		return sgs.Card_Parse("@TenyearYijueCard=.")
	end
end

sgs.ai_skill_use_func.TenyearYijueCard = function(card, use, self)
	local id = -1
	if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		id = cards[1]:getEffectiveId()
	end
	if id < 0 then return end
	
	self:sort(self.friends_noself, "hp")
	for _,p in ipairs(self.friends_noself) do
		if self:isWeak(p) and p:getLostHp() > 0 and hasRedHandcard(self, p) then
			use.card = sgs.Card_Parse("@TenyearYijueCard=" .. id)
			if use.to then use.to:append(p) end
			return
		end
	end
	
	self:sort(self.enemies, "handcard")
	for _,p in ipairs(self.enemies) do
		if self.player:canSlash(p, nil) and not p:isKongcheng() then
			use.card = sgs.Card_Parse("@TenyearYijueCard=" .. id)
			if use.to then use.to:append(p) end
			return
		end
	end
	
	if self.player:hasArmorEffect("silver_lion") and sgs.Sanguosha:getCard(id):objectName() == "silver_lion" and self.room:getCardPlace(id) == sgs.Player_PlaceEquip and
		(self:needToThrowArmor() or (self:isWeak() and self.player:getLostHp() > 0)) then
		for _,p in ipairs(self.friends_noself) do
			if p:getLostHp() > 0 and hasRedHandcard(self, p) then
				use.card = sgs.Card_Parse("@TenyearYijueCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
		
		for _,p in ipairs(self.enemies) do
			if not p:isKongcheng() then
				use.card = sgs.Card_Parse("@TenyearYijueCard=" .. id)
				if use.to then use.to:append(p) end
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearYijueCard = sgs.ai_use_priority.Slash + 0.1
sgs.ai_use_value.TenyearYijueCard = 8.5

sgs.ai_cardshow.tenyearyijue = function(self, requestor)
	local cards, red = sgs.QList2Table(self.player:getCards("h")), {}
	self:sortByUseValue(cards, true)
	for _,c in ipairs(cards) do
		if c:isRed() then
			table.insert(red, c)
		end
	end
	if self:isFriend(requestor) and #red > 0 and (self.player:getLostHp() > 0 or self:getOverflow() > 0) then
		return red[1]
	end
	return cards[1]
end

sgs.ai_skill_invoke.tenyearyijue = function(self, data)
	local name = data:toString():split(":")
	if #name <= 1 or name[2] == "" or name[2] == nil then return false end
	local player = self.room:findPlayerByObjectName(name[2])
	if not player or player:isDead() then return false end
	return self:isFriend(player)
end

--替身
sgs.ai_skill_invoke.tenyeartishen = function(self, data)
	local hascard = false
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("TrickCard") or c:isKindOf("OffensiveHorse") or c:isKindOf("DefensiveHorse") then  --没有相应区域不能使用坐骑牌暂时未考虑
			hascard = true
			break
		end
	end
	if not hascard then return true end
	if self:getCardsNum("Jink") == 0 then return false end
	return true  --偷懒
end

--观星
sgs.ai_skill_invoke.tenyearguanxing = true

--涯角
sgs.ai_skill_invoke.tenyearyajiao = true

sgs.ai_skill_playerchosen.tenyearyajiao = function(self, targets)
	local id = self.player:getMark("tenyearyajiao")
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

sgs.ai_playerchosen_intention.tenyearyajiao = function(self, from, to)
	if not self:needKongcheng(to, true) and not hasManjuanEffect(to) then sgs.updateIntention(from, to, -50) end
end

sgs.ai_skill_discard.tenyearyajiao = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummy", 1, 1, false, true)
end

--集智
sgs.ai_skill_invoke.tenyearjizhi = function(self, choices, data)
	return self:canDraw()
end

sgs.ai_skill_invoke.tenyearjizhi_discard = function(self, choices, data)
	if self.player:getHandcardNum() <= self.player:getMaxCards() then return false end
	local id = self.player:getTag("tenyearjizhi_id"):toInt()
	local card = sgs.Sanguosha:getCard(id)
	if card:isKindOf("Jink") and self:getCardsNum("Jink") <= 1 then return false end
	if card:isKindOf("Peach") then return false end
	if not self.player:canUse(card) then return true end
	if card:isKindOf("Analeptic") and self:willUse(self.player, card) then return false end
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardByClassName(card, dummy_use)
	if not dummy_use.card or dummy_use.to:isEmpty() then return true end
	if card:isKindOf("Slash") and self:getCardsNum("Slash") > 1 and (self.player:canSlashWithoutCrossbow() or self.player:hasWeapon("Crossbow")) then return false end
	return false
end

--奸雄
sgs.ai_skill_invoke.tenyearjianxiong = function(self, choices, data)
	return self:canDraw()
end

--清俭
sgs.ai_skill_use["@@tenyearqingjian"] = function(self, prompt, method)
	--if sgs.turncount <= 1 then return "." end
	if not self.room:hasCurrent() then return "." end
	local current = self.room:getCurrent()
	if current:isDead() or not self:isFriend(current) then return "." end
	
	self:sort(self.friends_noself)
	local to
	for _,p in ipairs(self.friends_noself) do
		if hasManjuanEffect(p) or self:needKongcheng(p, true) then continue end
		to = p:objectName()
		break
	end
	if not to then return "." end
	
	local give = {}
	if self:needToThrowArmor() then table.insert(give, self.player:getArmor():getEffectiveId()) end
	if self:needToThrowLastHandcard(self.player, self.player:getHandcardNum()) and self.player:getPhase() == sgs.Player_NotActive then
		for _,id in sgs.qlist(self.player:handCards()) do
			table.insert(give, id)
		end
		if #give > 0 then
			return "@TenyearQingjianCard=" .. table.concat(give, "+") .. "->" .. to
		end
	end
	
	local basic, equip, trick, allcards = {} , {}, {}, sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(allcards)
	for _,c in ipairs(allcards) do
		if c:isKindOf("BasicCard") then
			table.insert(basic, c:getEffectiveId())
		elseif c:isKindOf("EquipCard") then
			table.insert(equip, c:getEffectiveId())
		elseif c:isKindOf("TrickCard") then
			table.insert(trick, c:getEffectiveId())
		end
	end
	if #equip > 0 and #give <= 0 then
		table.insert(give, equip[1])
	end
	if #basic > 0 then
		table.insert(give, basic[1])
	end
	if #trick > 0 then
		table.insert(give, trick[1])
	end
	if #give > 0 then
		return "@TenyearQingjianCard=" .. table.concat(give, "+") .. "->" .. to
	end
	return "."
end

--裸衣
sgs.ai_skill_invoke.tenyearluoyi = function(self)
	if self.player:getPile("yiji"):length() > 1 then return false end
	local diaochans, nosdiaochans = self.room:findPlayersBySkillName("lijian"), self.room:findPlayersBySkillName("noslijian")
	for _,diaochan in sgs.qlist(diaochans) do
		if self:isEnemy(diaochan) then
			for _, friend in ipairs(self.friends_noself) do
				if self:isWeak(friend) or friend:getHp() <= 2 then return false end
			end
		end
	end
	for _,diaochan in sgs.qlist(nosdiaochans) do
		if self:isEnemy(diaochan) then
			for _, friend in ipairs(self.friends_noself) do
				if self:isWeak(friend) or friend:getHp() <= 2 then return false end
			end
		end
	end
	local ids = self.player:getTag("tenyearluoyi_ids"):toIntList()
	local num = 0
	local slash = false
	for _,id in sgs.qlist(ids) do
		local c = sgs.Sanguosha:getCard(id)
		if c:isKindOf("Slash") then  --若其中只有一张【杀】且敌人虚弱，也可以发动技能，待补充
			slash = true
			num = num + 1
		elseif c:isKindOf("Duel") or c:isKindOf("Weapon") or c:isKindOf("Peach") then num = num + 1
		elseif c:isKindOf("Jink") and (self:getCardsNum("Jink") == 0 or (self:getCardsNum("Jink") == 1 and self:isWeak())) then num = num + 1
		elseif c:isKindOf("Analeptic") and (slash or self:getCardsNum("Slash") > 0) then num = num + 1
		end
	end
	return num >= 2
end

--遗计
sgs.ai_skill_invoke.tenyearyiji = function(self)
	return sgs.ai_skill_invoke.nosyiji(self)
end

sgs.ai_skill_askforyiji.tenyearyiji = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end

sgs.ai_need_damaged.tenyearyiji = function (self, attacker, player)
	return sgs.ai_need_damaged.nosyiji(self, attacker, player)
end

--洛神
sgs.ai_skill_invoke.tenyearluoshen = function(self, data)
	if self.player:hasFlag("AI_doNotInvoke_tenyearluoshen") then
		self.player:setFlags("-AI_doNotInvoke_tenyearluoshen")
		return false
	end
	if self.player:hasFlag("AI_TenyearLuoshen_Conflict_With_Guanxing") and self.player:getMark("AI_tenyearluoshen_times") == 0 then return false end
	if self:willSkipPlayPhase() then
		local erzhang = self.room:findPlayerBySkillName("guzheng")
		if erzhang and self:isEnemy(erzhang) and self:getOverflow() > 1 then return false end
		if self.player:getPile("incantation"):length() > 0 then
			local card = sgs.Sanguosha:getCard(self.player:getPile("incantation"):first())
			if not self.player:getJudgingArea():isEmpty() and not self.player:containsTrick("YanxiaoCard") and not self:hasWizard(self.enemies, true) then
				local trick = self.player:getJudgingArea():last()
				if trick:isKindOf("Indulgence") then
					if card:getSuit() == sgs.Card_Heart or (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade) then return false end
				elseif trick:isKindOf("SupplyShortage") then
					if card:getSuit() == sgs.Card_Club then return false end
				end
			end
			local zhangbao = self.room:findPlayerBySkillName("yingbing")
			if zhangbao and self:isEnemy(zhangbao) and not zhangbao:hasSkill("manjuan")
				and (card:isRed() or (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade)) then return false end
		end
	end
	return true
end

--突袭
sgs.ai_skill_use["@@tenyeartuxi"] = function(self, prompt)
	self:sort(self.enemies, "handcard_defense")
	local tuxi_mark = self.player:getMark("tenyeartuxi")
	local targets = {}

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying") or self.room:findPlayerBySkillName("noslianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")
	local zhijiangwei = self.room:findPlayerBySkillName("beifa")

	local add_player = function (player,isfriend)
		if player:getHandcardNum() == 0 or player:objectName() == self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and sgs.current_mode_players["rebel"] > 1 then return #targets end

		local f = false
		for _, c in ipairs(targets) do
			if c == player:objectName() then
				f = true
				break
			end
		end

		if not f then table.insert(targets, player:objectName()) end

		if isfriend and isfriend == 1 then
			self.player:setFlags("tenyeartuxi_isfriend_"..player:objectName())
		end
		return #targets
	end

	local parseTenyearTuxiCard = function()
		if #targets == 0 then return "." end
		local s = table.concat(targets, "+")
		return "@TenyearTuxiCard=.->" .. s
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount <= 1 and not lord:isKongcheng() then
		if add_player(lord) == tuxi_mark then return parseTenyearTuxiCard() end
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark("zhiji") == 0 and jiangwei:getHandcardNum()== 1
			and self:getEnemyNumBySeat(self.player,jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
		if add_player(jiangwei,1) == tuxi_mark  then return parseTenyearTuxiCard() end
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai) == 0 )
			and dengai:hasSkill("zaoxian") and dengai:getMark("zaoxian") == 0 and dengai:getPile("field"):length() == 2 and add_player(dengai, 1) == tuxi_mark then
		return parseTenyearTuxiCard()
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player,zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang,1) == tuxi_mark then return parseTenyearTuxiCard() end
		else
			local flag = string.format("%s_%s_%s","visible",self.player:objectName(),zhugeliang:objectName())
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang,1) == tuxi_mark then return parseTenyearTuxiCard() end
				end
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player,luxun) > 0 then
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards==1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun,1)==tuxi_mark  then return parseTenyearTuxiCard() end
			end
		end
	end

	if zhijiangwei and self:isFriend(zhijiangwei) and zhijiangwei:getHandcardNum()== 1 and
		self:getEnemyNumBySeat(self.player, zhijiangwei) <= (zhijiangwei:getHp() >= 3 and 1 or 0) then
		local isGood
		for _, enemy in ipairs(self.enemies) do
			local def = sgs.getDefenseSlash(enemy)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local eff = self:slashIsEffective(slash, enemy, zhijiangwei) and sgs.isGoodTarget(enemy, self.enemies, self)
			if zhijiangwei:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy, zhijiangwei) and eff and def < 4 then
				isGood = true
			end
		end
		if isGood and add_player(zhijiangwei, 1) == tuxi_mark  then return parseTenyearTuxiCard() end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _, card in ipairs(cards) do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
				if add_player(p)==tuxi_mark  then return parseTenyearTuxiCard() end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p) == tuxi_mark  then return parseTenyearTuxiCard() end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x = p:getHandcardNum()
		local good_target = true
		if x == 1 and self:needKongcheng(p) then good_target = false end
		if x >= 2 and p:hasSkill("tuntian") and p:hasSkill("zaoxian") then good_target = false end
		if good_target and add_player(p)==tuxi_mark then return parseTenyearTuxiCard() end
	end


	if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil)) == tuxi_mark then
		return parseTenyearTuxiCard()
	end

	if dengai and self:isFriend(dengai) and dengai:hasSkill("zaoxian") and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai) == 0 ) and add_player(dengai,1) == tuxi_mark then
		return parseTenyearTuxiCard()
	end

	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (other:hasSkill("tuntian") and other:hasSkill("zaoxian")) and add_player(other) == tuxi_mark then
			return parseTenyearTuxiCard()
		end
	end

	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not (other:hasSkill("tuntian") and other:hasSkill("zaoxian")) and math.random(0, 5) <= 1 and not self:hasSkills("qiaobian") then
			add_player(other)
		end
	end

	return parseTenyearTuxiCard()
end

sgs.ai_card_intention.TenyearTuxiCard = function(self, card, from, tos)
	local lord = getLord(self.player)
	local tuxi_lord = false
	if sgs.evaluatePlayerRole(from) == "neutral" and sgs.evaluatePlayerRole(tos[1]) == "neutral" and
		(not tos[2] or sgs.evaluatePlayerRole(tos[2]) == "neutral") and lord and not lord:isKongcheng() and
		not (self:needKongcheng(lord) and lord:getHandcardNum() == 1 ) and
		self:hasLoseHandcardEffective(lord) and not (lord:hasSkill("tuntian") and lord:hasSkill("zaoxian")) and from:aliveCount() >= 4 then
			sgs.updateIntention(from, lord, -80)
		return
	end
	if from:getState() == "online" then
		for _, to in ipairs(tos) do
			if to:hasSkill("kongcheng") or to:hasSkill("lianying") or to:hasSkill("zhiji")
				or (to:hasSkill("tuntian") and to:hasSkill("zaoxian")) then
			else
				sgs.updateIntention(from, to, 80)
			end
		end
	else
		for _, to in ipairs(tos) do
			if lord and to:objectName() == lord:objectName() then tuxi_lord = true end
			local intention = from:hasFlag("tenyeartuxi_isfriend_"..to:objectName()) and -5 or 80
			sgs.updateIntention(from, to, intention)
		end
		if sgs.turncount ==1 and not tuxi_lord and lord and not lord:isKongcheng() and from:getRoom():alivePlayerCount() > 2 then
			sgs.updateIntention(from, lord, -80)
		end
	end
end

--青囊
local tenyearqingnang_skill = {}
tenyearqingnang_skill.name = "tenyearqingnang"
table.insert(sgs.ai_skills, tenyearqingnang_skill)
tenyearqingnang_skill.getTurnUseCard = function(self)
	if not self.player:canDiscard(self.player, "h") or self.player:getMark("tenyearqingnang-PlayClear") > 0 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a) + ( a:isRed() and 50 or 0 ) + ( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b) + ( b:isRed() and 50 or 0 ) + ( b:isKindOf("Peach") and 50 or 0 )
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("@TenyearQingnangCard=%d"):format(cards[1]:getId())
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.TenyearQingnangCard = function(card, use, self)
	local friends = {}
	for _,p in ipairs(self.friends) do
		if p:getMark("tenyearqingnang_target-PlayClear") > 0 or p:getLostHp() <= 0 then continue end
		table.insert(friends, p)
	end
	if #friends <= 0 then return end
	
	local arr1, arr2 = self:getWoundedFriend(false, true, friends)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	if self:getOverflow() > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearQingnangCard = sgs.ai_use_priority.QingnangCard
sgs.ai_card_intention.TenyearQingnangCard = sgs.ai_card_intention.QingnangCard
sgs.dynamic_value.benefit.TenyearQingnangCard = true

--利驭

--闭月
sgs.ai_skill_invoke.tenyearbiyue = function(self, data)
	return self:canDraw()
end

--耀武
sgs.ai_skill_choice.tenyearyaowu = function(self, choices)
	return sgs.ai_skill_choice.yaowu(self, choices)
end

--烈弓
sgs.ai_skill_invoke.tenyearliegong = function(self, data)
	return sgs.ai_skill_invoke.liegong(self, data)
end

--狂骨
sgs.ai_skill_choice.tenyearkuanggu = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "recover") and self.player:getLostHp() > 0 and self:isWeak() then 
		return "recover"
	end
	if table.contains(choices, "draw") and self:needBear() then 
		return "draw"
	end
	if table.contains(choices, "recover") and self.player:getLostHp() > 0 then 
		return "recover"
	end
    return "draw"
end

--奇谋
local tenyearqimou_skill = {}
tenyearqimou_skill.name = "tenyearqimou"
table.insert(sgs.ai_skills, tenyearqimou_skill)
tenyearqimou_skill.getTurnUseCard = function(self)
	if self.player:getMark("@tenyearqimouMark") <= 0 or #self.enemies <= 0 then return end
	if self.player:getHp() < 1 and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 0 then return end
	return sgs.Card_Parse("@TenyearQimouCard=.")
end

sgs.ai_skill_use_func.TenyearQimouCard = function(card, use, self)
	self.tenyearqimou_lose = 0
	local slashcount = self:getCardsNum("Slash") - 1
	self.tenyearqimou_lose = math.min(slashcount, self.player:getHp())
	if self.tenyearqimou_lose <= 0 then return end
	
	self.room:addDistance(self.player, -self.tenyearqimou_lose)
	local slash = self:getCard("Slash")
	if not slash then self.room:addDistance(self.player, self.tenyearqimou_lose) return end
	
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	if slash then self:useBasicCard(slash, dummy_use) end
	self.room:addDistance(self.player, self.tenyearqimou_lose)
	if not dummy_use.card or dummy_use.to:isEmpty() then return end
	use.card = card
end

sgs.ai_skill_choice.tenyearqimou = function(self, choices)
	choices = choices:split("+")
	local num = self.tenyearqimou_lose
	for _,choice in ipairs(choices) do
		if tonumber(choice) == num then return choice end
	end
	return choices[1]
end

sgs.ai_use_priority.TenyearQimouCard = sgs.ai_use_priority.Slash + 0.1

--神速
sgs.ai_skill_use["@@tenyearshensu1"] = function(self, prompt)
	local card_str = sgs.ai_skill_use["@@shensu1"](self,prompt)
	if not card_str or card_str == "." then return "." end
	return string.gsub(card_str, "@ShensuCard", "@TenyearShensuCard")
end

sgs.ai_skill_use["@@tenyearshensu2"] = function(self, prompt)
	local card_str = sgs.ai_skill_use["@@shensu2"](self, prompt, method)
	if not card_str or card_str == "." then return "." end
	return string.gsub(card_str, "@ShensuCard", "@TenyearShensuCard")
end

sgs.ai_skill_use["@@tenyearshensu3"] = function(self, prompt)
	self:updatePlayers()
	self:sort(self.enemies, "defense")

	if self:needBear() then return "." end

	local selfSub = self:getOverflow()
	local selfDef = sgs.getDefense(self.player)

	for _,enemy in ipairs(self.enemies) do
		local def = sgs.getDefenseSlash(enemy, self)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		slash:setSkillName("_tenyearshensu")
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then return "@TenyearShensuCard=.->"..enemy:objectName()

		elseif selfSub >= 2 then return "@TenyearShensuCard=.->"..enemy:objectName()
		elseif selfDef < 6 then return "." end
	end

	for _,enemy in ipairs(self.enemies) do
		local def=sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		slash:setSkillName("_tenyearshensu")
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff and def < 8 then return "@TenyearShensuCard=.->"..enemy:objectName()
		else return "." end
	end
	return "."
end

sgs.ai_cardneed.tenyearshensu = function(to, card, self)
	return sgs.ai_cardneed.shensu(to, card, self)
end

sgs.ai_card_intention.TenyearShensuCard = sgs.ai_card_intention.ShensuCard
sgs.tenyearshensu_keep_value = sgs.shensu_keep_value

--据守
sgs.ai_skill_invoke.tenyearjushou = function(self, data)
	return self:canDraw()
end

sgs.ai_skill_cardask["@tenyearjushou"] = function(self, data)
	if self.player:getHandcardNum() == 1 then
		local id = self.player:handCards():first()
		return "$" .. id
	end
	
	local equips, not_equips = {}, {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in ipairs(cards) do
		if c:isKindOf("EquipCard") then
			table.insert(equips, c)
		else
			table.insert(not_equips, c)
		end
	end
	if #equips > 0 then
		self:sortByUseValue(equips)
		local sp = sgs.SPlayerList()
		sp:append(self.player)
		for _,c in ipairs(equips) do
			if self.player:canUse(c, sp) then
				local index = c:getRealCard():toEquipCard():location()
				if self.player:getEquip(index) then continue end
				return "$" .. c:getEffectiveId()
			end
		end
	end
	if #not_equips > 0 then
		self:sortByKeepValue(not_equips)
		for _,c in ipairs(not_equips) do
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				if c:isKindOf("Peach") or (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1) or (c:isKindOf("ExNihilo") and self.player:canUse(c)) then continue end
				return "$" .. c:getEffectiveId()
			end
		end
	end
	if #equips > 0 then
		self:sortByUseValue(equips)
		for _,c in ipairs(equips) do
			if self.player:canUse(c) then
				return "$" .. c:getEffectiveId()
			end
		end
	end
	return "."
end

--解围
sgs.ai_view_as.tenyearjiewei = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceEquip then
		return ("nullification:tenyearjiewei[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_cardask["@tenyearjiewei"] = function(self, data)
	local id, cards = nil, {}
	if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		for _,c in sgs.qlist(self.player:getCards("he")) do
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				table.insert(cards, c)
			end
		end
		if #cards <= 0 then return "." end
		self:sortByKeepValue(cards)
		id = cards[1]:getEffectiveId()
	end
	
	if not id then return "." end
	
	local from, card, to = self:moveField(nil, "ej")
	if from and card and to then
		sgs.ai_skill_playerchosen.tenyearjiewei_from = from
		sgs.ai_skill_cardchosen.tenyearjiewei = card
		sgs.ai_skill_playerchosen.tenyearjiewei_to = to
		return "$" .. id
	end
	return "."
end

--天香
sgs.ai_skill_use["@@tenyeartianxiang"] = function(self, prompt)
	local cards = self.player:getCards("h")
	local str = "@TenyearTianxiangCard="
	local reason = "tenyeartianxiang"
	if prompt == "@oltianxiang" then
		cards = self.player:getCards("he")
		str = "@OLTianxiangCard="
		reason = "oltianxiang"
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	
	local card_id, choice
	
	for _, card in ipairs(cards) do
		if self.player:canDiscard(self.player, card:getEffectiveId()) and card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
			card_id = card:getId()
			break
		end
	end
	if not card_id then return "." end
	self:sort(self.enemies, "hp")
	self:sort(self.friends_noself)
	
	for _,friend in ipairs(self.friends_noself) do
		if not friend:hasSkill("zhaxiang") or self:willSkipPlayPhase(friend) or self:isWeak(friend) then continue end
		sgs.ai_skill_choice[reason] = "losehp"
		return str .. card_id .. "->" .. friend:objectName()
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() <= 1 and enemy:isAlive() and not enemy:hasSkill("zhaxiang") then
			sgs.ai_skill_choice[reason] = "losehp"
			return str .. card_id .. "->" .. enemy:objectName()
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() and not enemy:hasSkill("zhaxiang") then
			sgs.ai_skill_choice[reason] = "losehp"
			return str .. card_id .. "->" .. enemy:objectName()
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() <= 1 and enemy:isAlive() and not hasBuquEffect(enemy) and self:damageIsEffective(enemy, nil, nil) then
			sgs.ai_skill_choice[reason] = "damage"
			return str .. card_id .. "->" .. enemy:objectName()
		end
	end
	
	for _, friend in ipairs(self.friends_noself) do
		if friend:getLostHp() >= 1 and friend:isAlive() and (friend:hasSkills("yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
						or self:getDamagedEffects(friend, self.player)
						or self:needToLoseHp(friend)
						or (friend:getHandcardNum() < 3 and (friend:hasSkill("nosrende") or (friend:hasSkill("rende") and not friend:hasUsed("RendeCard"))))) then
				sgs.ai_skill_choice[reason] = "damage"
				return str .. card_id .. "->" .. friend:objectName()
		elseif hasBuquEffect(friend) then
			sgs.ai_skill_choice[reason] = "damage"
			return str .. card_id .. "->" .. friend:objectName()
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:getLostHp() == 0 and enemy:isAlive() and self:damageIsEffective(enemy, nil, nil) and not self:canDraw(enemy) then
			sgs.ai_skill_choice[reason] = "damage"
			return str .. card_id .. "->" .. enemy:objectName()
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:getLostHp() == 0 and enemy:isAlive() and not self:canDraw(enemy) then
			sgs.ai_skill_choice[reason] = "damage"
			return str .. card_id .. "->" .. enemy:objectName()
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() and self:damageIsEffective(enemy, nil, nil) and not self:canDraw(enemy) then
			sgs.ai_skill_choice[reason] = "damage"
			return str .. card_id .. "->" .. enemy:objectName()
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() and self:damageIsEffective(enemy, nil, nil) then
			sgs.ai_skill_choice[reason] = "damage"
			return str .. card_id .. "->" .. enemy:objectName()
		end
	end
	return "."
end

--鞬出
sgs.ai_skill_invoke.tenyearjianchu = function(self,data)
	local target = data:toPlayer()
	if not target then return false end
	return not self:isFriend(target) and not self:doNotDiscard(target, "he")
end

--散谣
local tenyearsanyao_skill = {}
tenyearsanyao_skill.name = "tenyearsanyao"
table.insert(sgs.ai_skills, tenyearsanyao_skill)
tenyearsanyao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("TenyearSanyaoCard") or not self.player:canDiscard(self.player, "he") then return end
	return sgs.Card_Parse("@TenyearSanyaoCard=.")
end

sgs.ai_skill_use_func.TenyearSanyaoCard = function(card, use, self)
	local alives = self.room:getAlivePlayers()
	local max_hp = -1000
	for _,p in sgs.qlist(alives) do
		local hp = p:getHp()
		if hp > max_hp then
			max_hp = hp
		end
	end
	local friends, enemies = {}, {}
	for _,p in sgs.qlist(alives) do
		if p:getHp() == max_hp then
			if self:isFriend(p) then
				table.insert(friends, p)
			elseif self:isEnemy(p) then
				table.insert(enemies, p)
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local discards = {}
	for _,c in ipairs(cards) do
		if c:isKindOf("Peach") or c:isKindOf("ExNihilo") or (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1) then continue end
		if not self.player:canDiscard(self.player, c:getEffectiveId()) then continue end
		table.insert(discards, c:getEffectiveId())
	end
	if #discards <= 0 then return end
	
	local targets = {}
	if #enemies > 0 then
		self:sort(enemies, "hp")
		for _,enemy in ipairs(enemies) do
			if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
				if self:cantbeHurt(enemy, self.player) then
				elseif self:needToLoseHp(enemy, self.player, false) then
				elseif self:getDamagedEffects(enemy, self.player, false) then
				else
					table.insert(targets, enemy)
				end
			end
		end
	end
	
	if #friends > 0 and not target then
		self:sort(friends, "hp")
		friends = sgs.reverse(friends)
		for _,friend in ipairs(friends) do
			if self:damageIsEffective(friend, sgs.DamageStruct_Normal, self.player) then
				if self:needToLoseHp(friend, self.player, false) then
				elseif friend:getCards("j"):length() > 0 and self.player:hasSkill("zhiman") then
				elseif self:needToThrowArmor(friend) and self.player:hasSkill("zhiman") then
					table.insert(targets, enemy)
				end
			end
		end
	end
	
	local max_num, to_discards = math.min(#discards, #targets), {}
	for i = 1, max_num do
		table.insert(to_discards, discards[i])
	end
	use.card = sgs.Card_Parse("@TenyearSanyaoCard=" .. table.concat(to_discards, "+"))
	for i = 1, max_num do
		if use.to then use.to:append(targets[i]) end
	end
end

sgs.ai_use_value.TenyearSanyaoCard = sgs.ai_use_value.SanyaoCard
sgs.ai_card_intention.TenyearSanyaoCard = sgs.ai_card_intention.SanyaoCard

--制蛮
sgs.ai_skill_invoke.tenyearzhiman = function(self, data)
	return sgs.ai_skill_invoke.zhiman(self, data)
end

--镇军
sgs.ai_skill_playerchosen.tenyearzhenjun = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    targets = sgs.reverse(targets)
    for _,target in ipairs(targets) do
		if self:isFriend(target) and self:needToThrowArmor(target) then
			self.tenyearzhenjun_discard = false
			return target
		end
    end
    targets = sgs.reverse(targets)
    for _, target in ipairs(targets) do
        if self:isEnemy(target) and not self:doNotDiscard(target, "he") then 
            self.tenyearzhenjun_discard = true
            return target 
        end
    end
	
    if table.contains(targets, self.player) then
		local num, not_equip = math.max(1, self.player:getHandcardNum() - self.player:getHp()), 0
		num = math.min(num, self.player:getHandcardNum())
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if not c:isKindOf("EquipCard") and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
				not_equip = not_equip + 1
			end
		end
		if not_equip <= 0 then return nil end
		if not_equip > num then
			self.tenyearzhenjun_discard = false
			return self.player
		end
	end
	return nil
end

sgs.ai_skill_cardchosen.tenyearzhenjun = function(self, who, flags)
	if who:objectName() == self.player:objectName() then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		for _,c in ipairs(cards) do
			if not c:isKindOf("EquipCard") and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
				return c
			end
		end
		return cards[1]
	else
		if who:getCards(flags):length() == 1 then return who:getCards(flags):first() end
		local id = self:askForCardChosen(who, flags, "dismantlement")
		return sgs.Sanguosha:getCard(id)
	end
end

sgs.ai_skill_discard.tenyearzhenjun = function(self, discard_num, min_num, optional, include_equip)
	if not self.tenyearzhenjun_discard then return {} end
	return self:askForDiscard("dummy", discard_num, min_num, false, include_equip)
end

--第二版镇军

--精策
sgs.ai_skill_invoke.tenyearjingce = function(self,data)
	return self:canDraw()
end

--第二版精策

--当先
sgs.ai_skill_invoke.tenyeardangxian = function(self,data)
	if self:isWeak() then return false end
	if self:getCardsNum("Slash") > 1 then return false end
	local slashs = sgs.CardList()
	for _,id in sgs.qlist(self.room:getDiscardPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
			slashs:append(sgs.Sanguosha:getCard(id))
		end
	end
	if slashs:isEmpty() then return false end
	local slash
	if slashs:length() == 1 then
		slash = slashs:first()
	else
		slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
	end
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {} }
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		return true
	end
	return false
end

--伏枥
sgs.ai_skill_invoke.tenyearfuli = true

--醇醪
sgs.ai_cardneed.tenyearchunlao = function(to, card)
	return sgs.ai_cardneed.chunlao(to, card)
end

sgs.ai_card_intention.TenyearChunlaoWineCard = sgs.ai_card_intention.ChunlaoWineCard
sgs.tenyearchunlao_keep_value = sgs.chunlao_keep_value

sgs.ai_skill_use["@@tenyearchunlao"] = function(self, prompt)
	local str = sgs.ai_skill_use["@@chunlao"](self, prompt)
	if not str or str == "" or str == "." then return "." end
	return string.gsub(str, "ChunlaoCard", "TenyearChunlaoCard")
end

sgs.ai_cardsview_valuable.tenyearchunlao = function(self, class_name, player)
	if class_name == "Peach" and player:getPile("wine"):length() > 0 then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if dying then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic")
			analeptic:deleteLater()
			if dying:isLocked(analeptic) then return nil end
			
			local wine_id = player:getPile("wine"):first()
			if self:canDraw(player) and not self:willSkipPlayPhase(player) then
				for _,id in sgs.qlist(player:getPile("wine")) do
					if sgs.Sanguosha:getCard(id):isKindOf("ThunderSlash") then
						wine_id = id
						break
					end
				end
			end
			if self:isWeak(player) and player:getLostHp() > 0 then
				for _,id in sgs.qlist(player:getPile("wine")) do
					if sgs.Sanguosha:getCard(id):isKindOf("FireSlash") then
						wine_id = id
						break
					end
				end
			end
			return "@TenyearChunlaoWineCard=" .. tostring(wine_id)
		end
	end
end

--第二版疠火
function sgs.ai_cardneed.secondtenyearlihuo(to, card, self)
	return sgs.ai_cardneed.lihuo(to, card, self)
end

sgs.ai_skill_invoke.secondtenyearlihuo = function(self, data)
	if data:toString() == "put" then return true end
	return sgs.ai_skill_invoke.lihuo(self, data)
end

sgs.ai_view_as.secondtenyearlihuo = function(card, player, card_place)
	local str = sgs.ai_view_as.lihuo(card, player, card_place)
	if not str or str == "." or str == "" then return end
	str = string.gsub(str, "lihuo", "secondtenyearlihuo")
	return str
end

local secondtenyearlihuo_skill={}
secondtenyearlihuo_skill.name="secondtenyearlihuo"
table.insert(sgs.ai_skills,secondtenyearlihuo_skill)
secondtenyearlihuo_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:addHandPile(cards)
	local slash_card

	for _,card in ipairs(cards)  do
		if card:isKindOf("Slash") and not (card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash")) then
			slash_card = card
			break
		end
	end

	if not slash_card then return nil end
	local dummy_use = { to = sgs.SPlayerList(), isDummy = true }
	self:useCardFireSlash(slash_card, dummy_use)
	if dummy_use.card and dummy_use.to:length() > 0 then
		local use = sgs.CardUseStruct()
		use.from = self.player
		use.to = dummy_use.to
		use.card = slash_card
		local data = sgs.QVariant()
		data:setValue(use)
		if not sgs.ai_skill_invoke.secondtenyearlihuo(self, data) then return nil end
	else return nil end

	local suit = slash_card:getSuitString()
	local number = slash_card:getNumberString()
	local card_id = slash_card:getEffectiveId()
	local card_str = ("fire_slash:secondtenyearlihuo[%s:%s]=%d"):format(suit, number, card_id)
	local fireslash = sgs.Card_Parse(card_str)
	assert(fireslash)

	return fireslash
end

--第二版醇醪
sgs.ai_cardneed.secondtenyearchunlao = function(to, card)
	return sgs.ai_cardneed.chunlao(to, card)
end

sgs.ai_card_intention.SecondTenyearChunlaoWineCard = sgs.ai_card_intention.ChunlaoWineCard
sgs.secondtenyearchunlao_keep_value = sgs.chunlao_keep_value

sgs.ai_skill_use["@@secondtenyearchunlao"] = function(self, prompt)
	local str = sgs.ai_skill_use["@@chunlao"](self, prompt)
	if not str or str == "" or str == "." then return "." end
	return string.gsub(str, "ChunlaoCard", "SecondTenyearChunlaoCard")
end

sgs.ai_cardsview_valuable.secondtenyearchunlao = function(self, class_name, player)
	local str = sgs.ai_cardsview_valuable.tenyearchunlao(self, class_name, player)
	if not str or str == "" or str == "." then return end
	return string.gsub(str, "TenyearChunlaoWineCard", "SecondTenyearChunlaoWineCard")
end

--将驰
sgs.ai_skill_use["@@tenyearjiangchi"] = function(self, prompt)
	local choice = sgs.ai_skill_choice.jiangchi(self)
	if choice == "cancel" then return "." end
	if choice == "jiang" then
		return "@TenyearJiangchiCard=."
	end
	if choice == "chi" then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		if cards[1]:isKindOf("Slash") and self:getCardsNum("Slash") <= 2 then return "." end
		return "@TenyearJiangchiCard=" .. cards[1]:getEffectiveId()
	end
	return "."
end

function sgs.ai_cardneed.tenyearjiangchi(to, card, self)
	return sgs.ai_cardneed.jiangchi(to, card, self)
end

--怃戎
tenyearwurong_skill = {name = "tenyearwurong"}
table.insert(sgs.ai_skills, tenyearwurong_skill)
tenyearwurong_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("TenyearWurongCard") then
        return nil
    elseif self.player:isKongcheng() then
        return nil
    end
    return sgs.Card_Parse("@TenyearWurongCard=.")
end

sgs.ai_skill_use_func.TenyearWurongCard = function(card, use, self)
    local handcards = self.player:getHandcards()
    local my_slashes, my_cards = {}, {}
    for _,c in sgs.qlist(handcards) do
        if c:isKindOf("Slash") then
            table.insert(my_slashes, c)
        else
            table.insert(my_cards, c)
        end
    end
    local no_slash = ( #my_slashes == 0 ) 
    local all_slash = ( #my_cards == 0 ) 
    local need_slash, target = nil, nil
    
    --自己展示的一定不是【杀】，目标展示的必须是【闪】，方可获得目标一张牌
    if no_slash then
        local others = self.room:getOtherPlayers(self.player)
        local targets = self:findPlayerToDiscard("he", false, false, others, true)
        for _,p in ipairs(targets) do
            if not p:isKongcheng() then
                local knowns, unknowns = getKnownHandcards(self.player, p)
                if #unknowns == 0 then
                    local all_jink = true
                    for _,jink in ipairs(knowns) do
                        if not jink:isKindOf("Jink") then
                            all_jink = false
                            break
                        end
                    end
                    if all_jink then
                        need_slash, target = false, p
                        break
                    end
                end
            end
        end
    end
    
    --自己展示的一定是【杀】，目标展示的不是【闪】时，可对目标造成1点伤害
    if all_slash and not target then
        local targets = self:findPlayerToDamage(1, self.player, nil, nil, false, 5, true)
        for _,p in ipairs(targets) do
            if not p:isKongcheng() then
                local knowns, unknowns = getKnownHandcards(self.player, p)
                if self:isFriend(p) then
                    local all_jink = true
                    if #unknowns == 0 then
                        for _,c in ipairs(knowns) do
                            if not c:isKindOf("Jink") then
                                all_jink = false
                                break
                            end
                        end
                    else
                        all_jink = false --队友会配合不展示【闪】的
                    end
                    if not all_jink then
                        need_slash, target = true, p
                        break
                    end
                else
                    local all_jink = false
                    if #unknowns == 0 then
                        for _,c in ipairs(knowns) do
                            if c:isKindOf("Jink") then
                                all_jink = true
                                break
                            end
                        end
                    end
                    if not all_jink then
                        need_slash, target = true, p
                        break
                    end
                end
            end
        end
    end
    
    --自己展示的不一定是【杀】，可根据目标情况决定展示的牌
    if not target then
        local friends, enemies, others = {}, {}, {}
        local other_players = self.room:getOtherPlayers(self.player)
        for _,p in sgs.qlist(other_players) do
            if not p:isKongcheng() then
                if self:isFriend(p) then
                    table.insert(friends, p)
                elseif self:isEnemy(p) then
                    table.insert(enemies, p)
                else
                    table.insert(others, p)
                end
            end
        end
        
        local to_damage = self:findPlayerToDamage(1, self.player, nil, enemies, false, 5, true)
        for _,enemy in ipairs(to_damage) do
            local knowns, unknowns = getKnownHandcards(self.player, enemy)
            local no_jink = true
            if #unknowns == 0 then
                for _,jink in ipairs(knowns) do
                    if jink:isKindOf("Jink") then
                        no_jink = false
                        break
                    end
                end
            else
                no_jink = false
            end
            if no_jink then
                need_slash, target = true, enemy
                break
            end
        end
        
        if not target then
            local other_players = self.room:getOtherPlayers(self.player)
            local to_obtain = self:findPlayerToDiscard("he", false, false, other_players, true)
            for _,p in ipairs(to_obtain) do
                if not p:isKongcheng() then
                    local knowns, unknowns = getKnownHandcards(self.player, p)
                    if self:isFriend(p) then
                        local has_jink = false
                        for _,jink in ipairs(knowns) do
                            if jink:isKindOf("Jink") then
                                has_jink = true
                                break
                            end
                        end
                        if has_jink then
                            need_slash, target = false, p
                            break
                        end
                    else
                        local all_jink = true
                        if #unknowns == 0 then
                            for _,c in ipairs(knowns) do
                                if not c:isKindOf("Jink") then
                                    all_jink = false
                                    break
                                end
                            end
                        else
                            all_jink = false
                        end
                        if all_jink then
                            need_slash, target = false, p
                            break
                        end
                    end
                end
            end
        end
        
        if not target then
            to_damage = self:findPlayerToDamage(1, self.player, nil, friends, false, 25, true)
            for _,friend in ipairs(to_damage) do
                local knowns, unknowns = getKnownHandcards(self.player, friend)
                local all_jink = true
                for _,c in ipairs(knowns) do
                    if not c:isKindOf("Jink") then
                        all_jink = false
                        break
                    end
                end
                if not all_jink then
                    need_slash, target = true, friend
                    break
                end
            end
        end
        
        if not target then
            local victim = self:findPlayerToDamage(1, self.player, nil, others, false, 5)
            if victim then
                need_slash, target = true, victim
            end
        end
        
        --只是为了看牌……
        if not target and #my_cards > 0 then
            if #enemies > 0 then
                self:sort(enemies, "handcard")
                need_slash, target = false, enemies[1]
            elseif #others > 0 then
                self:sort(others, "threat")
                need_slash, target = false, others[1]
            end
        end
        
        if not target and #enemies > 0 then
            self:sort(enemies, "defense")
            need_slash, target = (math.random(0, 1) == 0), enemies[1]
        end
    end
    
    if target and not target:isKongcheng() then
        local use_cards = need_slash and my_slashes or my_cards
        if #use_cards > 0 then
            self:sortByUseValue(use_cards, true)
            local card_str = "@TenyearWurongCard="..use_cards[1]:getEffectiveId()
            local acard = sgs.Card_Parse(card_str)
            use.card = acard
            if use.to then
                use.to:append(target)
            end
        end
    end
end

sgs.ai_use_priority.TenyearWurongCard = sgs.ai_use_priority.WurongCard
sgs.ai_use_value.TenyearWurongCard = sgs.ai_use_value.WurongCard

--邀名
sgs.ai_skill_playerchosen.tenyearyaoming = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
		if self:isFriend(p) and self:canDraw(p) and p:getHandcardNum() < self.player:getHandcardNum() then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if self:isEnemy(p) and p:getHandcardNum() > self.player:getHandcardNum() and not self:doNotDiscard(p, "h") then
			return p
		end
	end
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets) do
		if self:isFriend(p) and not hasManjuanEffect(p) and p:getHandcardNum() == self.player:getHandcardNum() then
			return p
		end
	end
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets) do
		if self:isFriend(p) and p:getHandcardNum() > self.player:getHandcardNum() and (self:doNotDiscard(p, "h") or self:needToThrowLastHandcard(p)) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_discard.tenyearyaoming = function(self, discard_num, min_num, optional, include_equip)
	local discards, dummy = {}, self:askForDiscard("dummy", discard_num, min_num, false, include_equip)
	for _,id in ipairs(dummy) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") or card:isKindOf("ExNihilo") or (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1) then continue end
		table.insert(discards, id)
	end
	return discards
end

sgs.ai_playerchosen_intention.tenyearyaoming = function(self, from, to)
	if hasManjuanEffect(to) then sgs.updateIntention(from, to, 20) end
	if to:getHandcardNum() <= from:getHandcardNum() then
		sgs.updateIntention(from, to, -20)
	else
		if self:doNotDiscard(to) or self:needToThrowLastHandcard(p) then
			sgs.updateIntention(from, to, -20)
		else
			sgs.updateIntention(from, to, 20)
		end
	end
end

--胆守
sgs.ai_skill_invoke.tenyeardanshou = function(self, data)
	local name = data:toString():split(":")[2]
	if not name then return false end
	local target = self.room:findPlayerByObjectName(name)
	if not target or target:isDead() then return false end
	return (self:isFriend(target) and self:getDamagedEffects(target, self.player)) or (not self:isFriend(target) and self:canAttack(target))
end

--谮毁
sgs.ai_skill_playerchosen.tenyearzenhui = function(self, targetlist)
	self.tenyearzenhui_collateral = nil
	local use = self.player:getTag("tenyearzenhui"):toCardUse()
	local dummy_use = { isDummy = true, to = sgs.SPlayerList(), current_targets = {}, extra_target = 99 }
	local target = use.to:first()
	if not target then return end
	table.insert(dummy_use.current_targets, target:objectName())
	self:useCardByClassName(use.card, dummy_use)
	if dummy_use.card and use.card:getClassName() == dummy_use.card:getClassName() and not dummy_use.to:isEmpty() then
		if use.card:isKindOf("Collateral") then
			assert(dummy_use.to:length() == 2)
			local player = dummy_use.to:first()
			if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card, target, player)) then
				self.tenyearzenhui_collateral = dummy_use.to:at(1)
				return player
			end
			return false
		elseif use.card:isKindOf("Slash") then
			for _, player in sgs.qlist(dummy_use.to) do
				if targetlist:contains(player) and (self:isFriend(player) or not self:slashProhibit(use.card, target, player)) then
					return player
				end
			end
		elseif use.card:isKindOf("FireAttack") then
			for _, player in sgs.qlist(dummy_use.to) do
				if targetlist:contains(player) and not self:isFriend(player, target) and not self:isFriend(player) and self:hasTrickEffective(use.card, target, player) then
					return player
				end
			end
			dummy_use.to = sgs.QList2Table(dummy_use.to)
			self:sort(dummy_use.to, "handcard")
			dummy_use.to = sgs.reverse(dummy_use.to)
			local suits = {}
			for _, c in sgs.qlist(self.player:getHandcards()) do
				if c:getSuit() <= 3 and not table.contains(suits, c:getSuitString()) then table.insert(suits, c:getSuitString()) end
			end
			if #suits <= 2 or self:getSuitNum("heart", false, target) > 0 and self:getSuitNum("heart") == 0 then
				for _, player in ipairs(dummy_use.to) do
					if self:isFriend(player) and targetlist:contains(player) then return player end
				end
			end
		elseif use.card:isKindOf("Duel") then
			for _, player in sgs.qlist(dummy_use.to) do
				if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card, target, player)) then
					return player
				end
			end
		elseif use.card:isKindOf("Drowning") then
			for _, player in sgs.qlist(dummy_use.to) do
				if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card, target, player)) then
					return player
				end
			end
		elseif use.card:isKindOf("Dismantlement") then
			for _, player in sgs.qlist(dummy_use.to) do
				if targetlist:contains(player) and self:isFriend(player) then
					return player
				end
			end
			for _, player in sgs.qlist(dummy_use.to) do
				if targetlist:contains(player) then
					if not self:isFriend(player, target) then
						return player
					elseif not self:needToThrowArmor(target)
						and (target:getJudgingArea():isEmpty()
							or (not target:containsTrick("indulgence")
								and not target:containsTrick("supply_shortage")
								and not (target:containsTrick("lightning") and self:getFinalRetrial(target, "lightning") == 1))) then
						return player
					end
				end
			end
		elseif use.card:isKindOf("Snatch") then
			for _, player in sgs.qlist(dummy_use.to) do
				if targetlist:contains(player) and self:isFriend(player) then
					return player
				end
			end
			local friend = self:findPlayerToDraw(false)
			if friend and targetlist:contains(friend) and self:hasTrickEffective(use.card, target, friend) then
				return friend
			end
		else
			self.room:writeToConsole("playerchosen.tenyearzenhui->" .. use.card:getClassName() .. "?")
		end
	end
	return false
end

sgs.ai_skill_playerchosen.tenyearzenhui_collateral = function(self, targetlist)
	if self.tenyearzenhui_collateral then return self.tenyearzenhui_collateral end
	self.room:writeToConsole(debug.traceback())
	return targetlist:at(math.random(0, targetlist:length() - 1))
end

sgs.ai_skill_cardask["tenyearzenhui-give"] = function(self, data)
	local use = data:toCardUse()
	local target = use.to:first()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local id = cards[1]:getEffectiveId()

	if use.card:isKindOf("Snatch") then
		if self:isFriend(use.from) then
			if self:askForCardChosen(self.player, "ej", "dummyReason") or not use.from:getAI() then
				return "."
			else
				self:sortByUseValue(cards)
				return cards[1]:getEffectiveId()
			end
		elseif not self:hasTrickEffective(use.card, self.player, use.from) then
			return "."
		end
		return id
	elseif use.card:isKindOf("Slash") then
		if self:slashProhibit(use.card, self.player, use.from)
			or not self:hasHeavySlashDamage(use.from, use.card, self.player) and (self:getDamagedEffects(self.player, use.from, true) or self:needToLoseHp(self.player, use.from)) then
			return "."
		elseif self:isFriend(target) then
			if not self:slashIsEffective(use.card, target, self.player) then
				return id
			end
		elseif not self:isValuableCard(cards[1]) or self:isWeak() or self:getCardsNum("Jink") == 0 or not sgs.isJinkAvailable(use.from, self.player, use.card) then
			return id
		end
		return "."
	elseif use.card:isKindOf("Dismantlement") then
		if not self:hasTrickEffective(use.card, self.player, use.from) then
			return "."
		elseif self:isFriend(use.from) and self:askForCardChosen(self.player, "ej", "dummyReason") then
			return "."
		end
		return id
	elseif use.card:isKindOf("Duel") then
		if self:getDamagedEffects(self.player, use.from) or self:needToLoseHp(self.player, use.from) then
			return "."
		elseif not self:hasTrickEffective(use.card, self.player, use.from) then
			return "."
		elseif self:isFriend(use.from) then
			if (self:getDamagedEffects(use.from, self.player) or self:needToLoseHp(use.from, self.player))
				and self:getCardsNum("Slash") - (cards[1]:isKindOf("Slash") and 1 or 0) > 0 then
				return "."
			end
		else
			if self:getCardsNum("Slash") - (cards[1]:isKindOf("Slash") and 1 or 0) > getCardsNum("Slash", use.from, self.player) then
				return "."
			end
		end
		return id
	elseif use.card:isKindOf("FireAttack") then
		if self:getDamagedEffects(self.player, use.from) or self:needToLoseHp(self.player, use.from) then
			return "."
		end
		return id
	elseif use.card:isKindOf("Collateral") then
		local victim = self.player:getTag("collateralVictim"):toPlayer()
		if sgs.ai_skill_cardask["collateral-slash"](self, nil, nil, victim, use.from) ~= "."
			and self:isFriend(use.from) or not self:isValuableCard(cards[1]) then
			return "."
		end
		return id
	elseif use.card:isKindOf("Drowning") then
		if self:getDamagedEffects(self.player, use.from) or self:needToLoseHp(self.player, use.from) or self:needToThrowArmor() then
			return "."
		elseif self:isValuableCard(cards[1]) and self:isEnemy(use.from) then
			return "."
		end
		return id
	else
		self.room:writeToConsole("@tenyearzenhui->" .. use.card:getClassName() .. "?")
	end

	return "."
end

sgs.ai_skill_cardask["tenyearzenhui-mustgive"] = function(self, data)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end

--骄矜
sgs.ai_skill_cardask["@tenyearjiaojin"] = function(self, data)
	local id = -1
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:getTypeId() == sgs.Card_TypeEquip then id = c:getEffectiveId() break end
	end
	if id < 0 then return "." end
	local use = data:toCardUse()
	if not use then return "." end
	local card = use.card
	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireSlash") or card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire end
	if card:isKindOf("ThunderSlash") then nature = sgs.DamageStruct_Thunder end
	
	if card:isKindOf("Slash") then
		if self:slashIsEffective(card, self.player, use.from) then return "." end
		if self:damageIsEffective(self.player, nature, use.from) and not self:getDamagedEffects(self.player, use.from, true)
			and not self:needToLoseHp(self.player, use.from, true) then
			return id
		end
	else
		if not self:hasTrickEffective(card, self.player, use.from) then return "." end  --可以主动弃装备拿有价值的锦囊，这里偷懒一下
		return id
	end
	return "."
end

--奔袭

--狂斧
local tenyearkuangfu_skill = {}
tenyearkuangfu_skill.name = "tenyearkuangfu"
table.insert(sgs.ai_skills, tenyearkuangfu_skill)
tenyearkuangfu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("TenyearKuangfuCard") then return end
	return sgs.Card_Parse("@TenyearKuangfuCard=.")
end

sgs.ai_skill_use_func.TenyearKuangfuCard = function(card, use, self)
	local target = self:findPlayerToDiscard("e", true, true, self.room:getAlivePlayers())
	if target then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority.TenyearKuangfuCard = sgs.ai_use_priority.Slash - 0.1

sgs.ai_skill_use["@@tenyearkuangfu!"] = function(self, prompt)
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_tenyearkuangfu")
	slash:deleteLater()
	return slash:toString()
end

sgs.ai_skill_discard.tenyearkuangfu = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, include_equip)
end

--破军
sgs.ai_skill_invoke.tenyearpojun = function(self,data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end

sgs.ai_skill_choice.tenyearpojun_num = function(self, choices, data)
	local items = choices:split("+")
	return items[#items]
end

--断粮
local tenyearduanliang_skill={}
tenyearduanliang_skill.name="tenyearduanliang"
table.insert(sgs.ai_skills,tenyearduanliang_skill)
tenyearduanliang_skill.getTurnUseCard=function(self)
	local card = duanliang_skill.getTurnUseCard(self)
	if card then
		local str = card:toString()
		str = string.gsub(str, "duanliang", "tenyearduanliang")
		local supply_shortage = sgs.Card_Parse(str)
		assert(supply_shortage)
		return supply_shortage
	end
end

sgs.ai_cardneed.tenyearduanliang = sgs.ai_cardneed.duanliang
sgs.tenyearduanliang_suit_value = sgs.duanliang_suit_value

--残蚀
sgs.ai_skill_invoke.tenyearcanshi = function(self, data)
	return sgs.ai_skill_invoke.canshi(self, data)
end

sgs.ai_skill_discard.tenyearcanshi = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummy", discard_num, min_num, false, include_equip)
end

--宴诛
local tenyearyanzhu_skill = {}
tenyearyanzhu_skill.name = "tenyearyanzhu"
table.insert(sgs.ai_skills, tenyearyanzhu_skill)
tenyearyanzhu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("TenyearYanzhuCard") then return end
	return sgs.Card_Parse("@TenyearYanzhuCard=.")
end

sgs.ai_skill_use_func.TenyearYanzhuCard = function(card, use, self)
	if self.player:property("tenyearyanzhu_level_up"):toBool() then
		self:sort(self.enemies, "defense")
		for _,p in ipairs(self.enemies) do
			if not self:doNotDiscard(p, "he") then
				use.card = card
				if (use.to) then use.to:append(p) end
				return
			end
		end
	else
		self:sort(self.enemies, "threat")
		for _, p in ipairs(self.enemies) do
			if not p:isNude() then
				use.card = card
				if (use.to) then use.to:append(p) end
				return
			end
		end
		for _, p in ipairs(self.friends_noself) do
			if self.needToThrowArmor(p) and p:getArmor() and not p:isJilei(p:getArmor()) then
				use.card = card
				if (use.to) then use.to:append(p) end
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearYanzhuCard = sgs.ai_use_priority.YanzhuCard

sgs.ai_skill_discard.tenyearyanzhu = function(self, _, __, optional)
    if not optional then return self:askForDiscard("dummyreason", 1, 1, false, true) end
    if self:needToThrowArmor() and self.player:getArmor() and not self.player:isJilei(self.player:getArmor()) then return self.player:getArmor():getEffectiveId() end
    if self.player:getTreasure() then
        if (self.player:getCardCount() == 1) then return self.player:getTreasure():getEffectiveId()
        elseif not self.player:isKongcheng() then return self:askForDiscard("dummyreason", 1, 1, false, false) end
    end
    if self.player:getEquips():length() > 2 and not self.player:isKongcheng() then return self:askForDiscard("dummyreason", 1, 1, false, false) end
    if self.player:getEquips():length() == 1 then return {} end
    return self:askForDiscard("dummyreason", 1, 1, false, true)
end

--兴学
sgs.ai_skill_use["@@tenyearxingxue"] = function(self)
    local n = (self.player:property("tenyearyanzhu_level_up"):toBool()) and self.player:getMaxHp() or self.player:getHp()
    n = math.min(n, #self.friends)
	if n <= 0 then return "." end
	self:sort(self.friends, "defense")
    local l = sgs.SPlayerList()
    local s = {}
    for i = 1, n, 1 do
        l:append(self.friends[i])
        table.insert(s, self.friends[i]:objectName())
    end
    if #s == 0 then return "." end
    return "@TenyearXingxueCard=.->" .. (table.concat(s, "+"))
end

sgs.ai_skill_discard.tenyearxingxue = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end

--倾袭
sgs.ai_skill_invoke.tenyearqingxi = sgs.ai_skill_invoke.tenyearpojun

sgs.ai_skill_discard.tenyearqingxi = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, include_equip)
end

--夺刀
sgs.ai_skill_cardask["@tenyearduodao"] = function(self, data)
	local use = data:toCardUse()
	if not use or use.from:isDead() or not use.from:getWeapon() then
		if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then
			return "$" .. self.player:getArmor():getEffectiveId()
		elseif self.player:canDiscard(self.player, "h") and self:needToThrowLastHandcard() then
			return "$" .. self.player:handCards():first()
		else
			return "."
		end
	end
	--return sgs.ai_skill_cardask["@duodao-get"](self, data)
	local function getLeastValueCard(from)
		if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for _, c in ipairs(cards) do
			if self:getKeepValue(c) < 8 and not self.player:isJilei(c) and not self:isValuableCard(c) then return "$" .. c:getEffectiveId() end
		end
		local offhorse_avail, weapon_avail
		for _, enemy in ipairs(self.enemies) do
			if self:canAttack(enemy, self.player) then
				if not offhorse_avail and self.player:getOffensiveHorse() and self.player:distanceTo(enemy, 1) <= self.player:getAttackRange() then
					offhorse_avail = true
				end
				if not weapon_avail and self.player:getWeapon() and self.player:distanceTo(enemy) == 1 then
					weapon_avail = true
				end
			end
			if offhorse_avail and weapon_avail then break end
		end
		if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
		if weapon_avail and not self.player:isJilei(self.player:getWeapon()) and self:evaluateWeapon(self.player:getWeapon()) < self:evaluateWeapon(from:getWeapon()) then
			return "$" .. self.player:getWeapon():getEffectiveId()
		end
	end
	if self:isFriend(use.from) then
		if use.from:hasSkills("kofxiaoji|xiaoji") and self:isWeak(use.from) then
			local str = getLeastValueCard(use.from)
			if str then return str end
		else
			if self:getCardsNum("Slash") == 0 or self:willSkipPlayPhase() then return "." end
			local invoke = false
			local range = sgs.weapon_range[use.from:getWeapon():getClassName()] or 0
			if self.player:hasSkill("anjian") then
				for _, enemy in ipairs(self.enemies) do
					if not enemy:inMyAttackRange(self.player) and not self.player:inMyAttackRange(enemy) and self.player:distanceTo(enemy) <= range then
						invoke = true
						break
					end
				end
			end
			if not invoke and self:evaluateWeapon(use.from:getWeapon()) > 8 then invoke = true end
			if invoke then
				local str = getLeastValueCard(use.from)
				if str then return str end
			end
		end
	else
		if use.from:hasSkill("nosxuanfeng") then
			for _, friend in ipairs(self.friends) do
				if self:isWeak(friend) then return "." end
			end
		else
			if hasManjuanEffect(self.player) then
				if self:needToThrowArmor() and not self.player:isJilei(self.player:getArmor()) then
					return "$" .. self.player:getArmor():getEffectiveId()
				elseif self.player:canDiscard(self.player, "h") and self:needToThrowLastHandcard()then
					return "$" .. self.player:handCards():first()
				end
			else
				local str = getLeastValueCard(use.from)
				if str then return str end
			end
		end
	end
	return "."
end

--慎断
sgs.ai_skill_use["@@tenyearshenduan"] = function(self)
	local ids = self.player:getTag("tenyearshenduan_forAI"):toString():split("+")
	for _, id in ipairs(ids) do
		local card = sgs.Sanguosha:getCard(tonumber(id))
		if self.player:isCardLimited(card, sgs.Card_MethodUse) then continue end
		local card_str = ("supply_shortage:tenyearshenduan[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), tonumber(id))
		local ss = sgs.Card_Parse(card_str)
		ss:deleteLater()
		local dummy_use = { isDummy = true , to = sgs.SPlayerList() }
		self:useCardSupplyShortage(ss, dummy_use)
		if dummy_use.card and not dummy_use.to:isEmpty() then
			return "@TenyearShenduanCard=" .. tonumber(id) .. "->" .. dummy_use.to:first():objectName()
		end
	end
	return "."
end

--勇略
sgs.ai_skill_invoke.tenyearyonglve = function(self, data)
	local name = data:toString():split(":")[2]
	if not name then return false end
	local current = self.room:findPlayerByObjectName(name)
	if not current or current:isDead() then return false end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_tenyearyonglve")
	slash:deleteLater()
	if self:isFriend(current) and self:askForCardChosen(current, "j", "dummyReason", sgs.Card_MethodDiscard) then
		if self.player:inMyAttackRange(current) then return true end
		if not self:slashIsEffective(slash, current, self.player) then return true end
		if not self:isWeak(current) or getKnownCard(current, self.player, "Jink") > 0 then return true end
	elseif self:isEnemy(current) then
		if self:askForCardChosen(current, "j", "dummyReason", sgs.Card_MethodDiscard) then return true end
		for _, card in sgs.qlist(current:getJudgingArea()) do
			if card:isKindOf("SupplyShortage") and (current:getHandcardNum() > 4 or current:containsTrick("indulgence")) then
				sgs.ai_skill_cardchosen.tenyearyonglve = card:getEffectiveId()
				return true
			elseif card:isKindOf("Indulgence") and current:getHandcardNum() + self:ImitateResult_DrawNCards(current) <= self:getOverflow(current, true) then
				sgs.ai_skill_cardchosen.tenyearyonglve = card:getEffectiveId()
				return true
			end
		end
		if self.player:inMyAttackRange(current) then return true end
		if self:isWeak(current) and current:getHp() == 1 and (sgs.card_lack[current:objectName()]["Jink"] == 1 or getCardsNum("Jink", current, self.player) == 0)
			and self:slashIsEffective(slash, current, self.player) then
			sgs.ai_skill_cardchosen.tenyearyonglve = self:getCardRandomly(current, "j")
			return true
		end
	end
	return false
end

--巧说

--傲才
function sgs.ai_cardsview_valuable.tenyearaocai(self, class_name, player)
	if player:hasFlag("Global_TenyearAocaiFailed") or player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		return "@TenyearAocaiCard=.:slash"
	elseif (class_name == "Peach" and player:getMark("Global_PreventPeach") == 0) or class_name == "Analeptic" then
		local dying = self.room:getCurrentDyingPlayer()
		if dying and dying:objectName() == player:objectName() then
			local user_string = "peach+analeptic"
			if player:getMark("Global_PreventPeach") > 0 then user_string = "analeptic" end
			return "@TenyearAocaiCard=.:" .. user_string
		else
			local user_string
			if class_name == "Analeptic" then user_string = "analeptic" else user_string = "peach" end
			return "@TenyearAocaiCard=.:" .. user_string
		end
	end
end

sgs.ai_skill_invoke.tenyearaocai = function(self, data)
	return sgs.ai_skill_invoke.aocai(self, data)
end

sgs.ai_skill_askforag.tenyearaocai = function(self, card_ids)
	return sgs.ai_skill_askforag.aocai(self, card_ids)
end

--黩武
local tenyearduwu_skill = {}
tenyearduwu_skill.name = "tenyearduwu"
table.insert(sgs.ai_skills, tenyearduwu_skill)
tenyearduwu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("TenyearDuwuEnterDying") or #self.enemies == 0 then return end
	return sgs.Card_Parse("@TenyearDuwuCard=.")
end

sgs.ai_skill_use_func.TenyearDuwuCard = function(card, use, self)
	local cmp = function(a, b)
		if a:getHp() < b:getHp() then
			if a:getHp() == 1 and b:getHp() == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy, self.player) and self.player:inMyAttackRange(enemy) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end
	table.sort(enemies, cmp)
	if enemies[1]:getHp() <= 0 then
		use.card = sgs.Card_Parse("@TenyearDuwuCard=.")
		if use.to then use.to:append(enemies[1]) end
		return
	end

	-- find cards
	local card_ids = {}
	if self:needToThrowArmor() then table.insert(card_ids, self.player:getArmor():getEffectiveId()) end

	local zcards = self.player:getHandcards()
	local use_slash, keep_jink, keep_analeptic = false, false, false
	for _, zcard in sgs.qlist(zcards) do
		if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
			local shouldUse = true
			if zcard:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(zcard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
				local dummy_use = { isDummy = true }
				self:useEquipCard(zcard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if isCard("Jink", zcard, self.player) and not keep_jink then
				keep_jink = true
				shouldUse = false
			end
			if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
				keep_analeptic = true
				shouldUse = false
			end
			if shouldUse then table.insert(card_ids, zcard:getId()) end
		end
	end
	local hc_num = #card_ids
	local eq_num = 0
	if self.player:getOffensiveHorse() then
		table.insert(card_ids, self.player:getOffensiveHorse():getEffectiveId())
		eq_num = eq_num + 1
	end
	if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) < 5 then
		table.insert(card_ids, self.player:getWeapon():getEffectiveId())
		eq_num = eq_num + 2
	end

	local function getRangefix(index)
		if index <= hc_num then return 0
		elseif index == hc_num + 1 then
			if eq_num == 2 then
				return sgs.weapon_range[self.player:getWeapon():getClassName()] - self.player:getAttackRange(false)
			else
				return 1
			end
		elseif index == hc_num + 2 then
			return sgs.weapon_range[self.player:getWeapon():getClassName()]
		end
	end

	for _, enemy in ipairs(enemies) do
		if enemy:getHp() > #card_ids then continue end
		if enemy:getHp() <= 0 then
			use.card = sgs.Card_Parse("@TenyearDuwuCard=.")
			if use.to then use.to:append(enemy) end
			return
		elseif enemy:getHp() > 1 then
			local hp_ids = {}
			if self.player:distanceTo(enemy, getRangefix(enemy:getHp())) <= self.player:getAttackRange() then
				for _, id in ipairs(card_ids) do
					table.insert(hp_ids, id)
					if #hp_ids == enemy:getHp() then break end
				end
				use.card = sgs.Card_Parse("@TenyearDuwuCard=" .. table.concat(hp_ids, "+"))
				if use.to then use.to:append(enemy) end
				return
			end
		else
			if not self:isWeak() or self:getSaveNum(true) >= 1 then
				if self.player:distanceTo(enemy, getRangefix(1)) <= self.player:getAttackRange() then
					use.card = sgs.Card_Parse("@TenyearDuwuCard=" .. card_ids[1])
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.TenyearDuwuCard = sgs.ai_use_priority.DuwuCard
sgs.ai_use_priority.TenyearDuwuCard = sgs.ai_use_value.DuwuCard
sgs.dynamic_value.damage_card.TenyearDuwuCard = sgs.dynamic_value.damage_card.DuwuCard
sgs.ai_card_intention.TenyearDuwuCard = sgs.ai_card_intention.DuwuCard

--啖酪
sgs.ai_skill_invoke.tenyeardanlao = function(self, data)
	return sgs.ai_skill_invoke.danlao(self, data)
end

--鸡肋
sgs.ai_skill_invoke.tenyearjilei = function(self, data)
	return sgs.ai_skill_invoke.jilei(self, data)
end

sgs.ai_skill_choice.tenyearjilei = function(self, choices)
	return sgs.ai_skill_choice.jilei(self, choices)
end

--陷阵
local tenyearxianzhen_skill = {}
tenyearxianzhen_skill.name = "tenyearxianzhen"
table.insert(sgs.ai_skills, tenyearxianzhen_skill)
tenyearxianzhen_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("TenyearXianzhenCard") or not self.player:canPindian() then return end
	return sgs.Card_Parse("@TenyearXianzhenCard=.")
end

sgs.ai_skill_use_func.TenyearXianzhenCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end

	if slashcount > 0  then
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasFlag("AI_HuangtianPindian") and enemy:getHandcardNum() == 1 and self.player:canPindian(enemy) then
				self.tenyearxianzhen_card = max_card:getId()
				use.card = sgs.Card_Parse("@TenyearXianzhenCard=.")
				if use.to then
					use.to:append(enemy)
					enemy:setFlags("-AI_HuangtianPindian")
				end
				return
			end
		end

		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = {isDummy = true}
		self:useBasicCard(slash, dummy_use)

		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and self.player:canPindian(enemy) and self:canAttack(enemy, self.player)
				and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					self.tenyearxianzhen_card = max_card:getId()
					use.card = sgs.Card_Parse("@TenyearXianzhenCard=.")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and self.player:canPindian(enemy) and self:canAttack(enemy, self.player)
				and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
				if max_point >= 10 then
					self.tenyearxianzhen_card = max_card:getId()
					use.card = sgs.Card_Parse("@TenyearXianzhenCard=.")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if (self:getUseValue(cards[1]) < 6 and self:getKeepValue(cards[1]) < 6) or self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and self.player:canPindian(enemy) and not enemy:hasSkills("tuntian+zaoxian") then
				self.tenyearxianzhen_card = cards[1]:getId()
				use.card = sgs.Card_Parse("@TenyearXianzhenCard=.")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.tenyearxianzhen = function(to, card, self)
	return sgs.ai_cardneed.xianzhen(to, card, self)
end

function sgs.ai_skill_pindian.tenyearxianzhen(minusecard, self, requestor)
	return sgs.ai_skill_pindian.xianzhen(minusecard, self, requestor)
end

sgs.ai_card_intention.TenyearXianzhenCard = sgs.ai_card_intention.XianzhenCard
sgs.dynamic_value.control_card.TenyearXianzhenCard = sgs.dynamic_value.control_card.XianzhenCard
sgs.ai_use_value.TenyearXianzhenCard = sgs.ai_use_value.XianzhenCard
sgs.ai_use_priority.TenyearXianzhenCard = sgs.ai_use_priority.XianzhenCard

--第二版陷阵
local secondtenyearxianzhen_skill = {}
secondtenyearxianzhen_skill.name = "secondtenyearxianzhen"
table.insert(sgs.ai_skills, secondtenyearxianzhen_skill)
secondtenyearxianzhen_skill.getTurnUseCard = function(self)
	if self.player:getMark("secondtenyearxianzhen_Used-Clear") > 0 or not self.player:canPindian() then return end
	return sgs.Card_Parse("@SecondTenyearXianzhenCard=.")
end

sgs.ai_skill_use_func.SecondTenyearXianzhenCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end

	if slashcount > 0  then
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasFlag("AI_HuangtianPindian") and enemy:getHandcardNum() == 1 and self.player:canPindian(enemy) then
				self.tenyearxianzhen_card = max_card:getId()
				use.card = sgs.Card_Parse("@SecondTenyearXianzhenCard=.")
				if use.to then
					use.to:append(enemy)
					enemy:setFlags("-AI_HuangtianPindian")
				end
				return
			end
		end

		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = {isDummy = true}
		self:useBasicCard(slash, dummy_use)

		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and self.player:canPindian(enemy) and self:canAttack(enemy, self.player)
				and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					self.tenyearxianzhen_card = max_card:getId()
					use.card = sgs.Card_Parse("@SecondTenyearXianzhenCard=.")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and self.player:canPindian(enemy) and self:canAttack(enemy, self.player)
				and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
				if max_point >= 10 then
					self.tenyearxianzhen_card = max_card:getId()
					use.card = sgs.Card_Parse("@SecondTenyearXianzhenCard=.")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if (self:getUseValue(cards[1]) < 6 and self:getKeepValue(cards[1]) < 6) or self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and self.player:canPindian(enemy) and not enemy:hasSkills("tuntian+zaoxian") then
				self.tenyearxianzhen_card = cards[1]:getId()
				use.card = sgs.Card_Parse("@SecondTenyearXianzhenCard=.")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.secondtenyearxianzhen = function(to, card, self)
	return sgs.ai_cardneed.xianzhen(to, card, self)
end

function sgs.ai_skill_pindian.secondtenyearxianzhen(minusecard, self, requestor)
	return sgs.ai_skill_pindian.xianzhen(minusecard, self, requestor)
end

sgs.ai_card_intention.SecondTenyearXianzhenCard = sgs.ai_card_intention.XianzhenCard
sgs.dynamic_value.control_card.SecondTenyearXianzhenCard = sgs.dynamic_value.control_card.XianzhenCard
sgs.ai_use_value.SecondTenyearXianzhenCard = sgs.ai_use_value.XianzhenCard
sgs.ai_use_priority.SecondTenyearXianzhenCard = sgs.ai_use_priority.XianzhenCard

--避乱
sgs.ai_skill_cardask["@tenyearbiluan-discard"] = function(self, data)
	local to_discard = self:askForDiscard("tenyearbiluan", 1, 1, false, true)
	if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

function sgs.ai_cardneed.tenyearbiluan(to, card)
	return to:getCardCount() <= 2
end

--礼下
sgs.ai_skill_choice.tenyearlixia = function(self, choices, data)
	local player = data:toPlayer()
	if not player or player:isDead() then return "self" end
	if self:isFriend(player) and self:canDraw(player) then return "other" end
	if not self:isFriend(player) and self:canDraw() then return "self" end
	if self:isFriend(player) and not self:canDraw(player) then
		if self:canDraw() then return "self" end
		return "other"
	end
	return "self"
end

--自守
sgs.ai_skill_invoke.tenyearzishou = function(self, data)
	return sgs.ai_skill_invoke.zishou(self, data)
end

sgs.ai_skill_use["@@tenyearzishou"] = function(self, prompt, method)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	
	local heart, diamond, club, spade = {}, {}, {}, {}
	for _,c in ipairs(cards) do
		if not self.player:canDiscard(self.player, c:getEffectiveId()) or self:isValuableCard(c, self.player) then continue end
		if c:getSuit() == sgs.Card_Heart then
			table.insert(heart, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Diamond then
			table.insert(diamond, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Club then
			table.insert(club, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Spade then
			table.insert(spade, c:getEffectiveId())
		end
	end
	
	local dis = {}
	if #heart > 0 then table.insert(dis, heart[1]) end
	if #diamond > 0 then table.insert(dis, diamond[1]) end
	if #club > 0 then table.insert(dis, club[1]) end
	if #spade > 0 then table.insert(dis, spade[1]) end
	if #dis > 0 then return "@TenyearZishouCard=" .. table.concat(dis, "+") end
	return "."
end

--旋风
sgs.ai_skill_invoke.tenyearxuanfeng = function(self, data)
	return sgs.ai_skill_invoke.xuanfeng(self, data)
end

sgs.ai_skill_playerchosen.tenyearxuanfeng = function(self, targets)
	return sgs.ai_skill_playerchosen.xuanfeng(self, targets)
end

sgs.ai_skill_cardchosen.tenyearxuanfeng = function(self, who, flags)
	return sgs.ai_skill_cardchosen.xuanfeng(self, who, flags)
end

sgs.ai_skill_playerchosen.tenyearxuanfeng_damage = function(self, targets)
	return self:findPlayerToDamage(1, self.player, nil, targets, false)
end

sgs.tenyearxuanfeng_keep_value = sgs.xuanfeng_keep_value
sgs.ai_cardneed.tenyearxuanfeng = sgs.ai_cardneed.xuanfeng

--勇进
local tenyearyongjin_skill = {}
tenyearyongjin_skill.name = "tenyearyongjin"
table.insert(sgs.ai_skills, tenyearyongjin_skill)
tenyearyongjin_skill.getTurnUseCard = function(self)
	if self.player:getMark("@tenyearyongjinMark") <= 0 then return end
	return sgs.Card_Parse("@TenyearyongjinCard=.")
end

sgs.ai_skill_use_func.TenyearyongjinCard = function(card, use, self)
	local from, card, to = self:moveField(nil, "e")
	if from and card and to then
		use.card = sgs.Card_Parse("@TenyearyongjinCard=.")
	end
end

sgs.ai_use_priority.TenyearyongjinCard = 50

sgs.ai_skill_playerchosen.tenyearyongjin_from = function(self, targets)
	local from, card, to = self:moveField(nil, "e")
		if from then return from
	end
end
sgs.ai_skill_cardchosen.tenyearyongjin = function(self, who, flags)
	local from, card, to = self:moveField(nil, "e")
	if card then return card end
end

sgs.ai_skill_playerchosen.tenyearyongjin_to = function(self, targets)
	local from, card, to = self:moveField(nil, "e")
		if to then return to
	end
end

--恩怨
sgs.ai_skill_invoke.tenyearenyuan = function(self, data)
	return sgs.ai_skill_invoke.enyuan(self, data)
end

sgs.ai_choicemade_filter.skillInvoke.tenyearenyuan = function(self, player, promptlist)
	local invoked = (promptlist[3] == "yes")
	local intention = 0

	local EnyuanDrawTarget
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("TenyearEnyuanDrawTarget") then EnyuanDrawTarget = p break end
	end

	if EnyuanDrawTarget then
		if not invoked and not self:needKongcheng(EnyuanDrawTarget, true) then
			intention = 10
		elseif not self:needKongcheng(from, true) then
			intention = -10
		end
		sgs.updateIntention(player, EnyuanDrawTarget, intention)
	else
		local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
		if damage.from then
			if not invoked then
				intention = -10
			elseif self:needToLoseHp(damage.from, player, nil, true) then
				intention = 0
			elseif not self:hasLoseHandcardEffective(damage.from) and not damage.from:isKongcheng() then
				intention = 0
			elseif self:getOverflow(damage.from) <= 2 then
				intention = 10
			end
			sgs.updateIntention(player, damage.from, intention)
		end
	end
end

sgs.ai_skill_discard.tenyearenyuan = function(self, discard_num, min_num, optional, include_equip)
	if self.player:hasSkill("zhaxiang") and (self.player:getHp() > 1 or hasBuquEffect(self.player) or self:getSaveNum(true) >= 1) then return {} end

	local damage = self.player:getTag("tenyearenyuan_data"):toDamage()
	if not damage then return {} end
	local fazheng = damage.to
    if not fazheng then return {} end
    local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	if self:needToLoseHp(self.player, fazheng, nil, true) and not self:hasSkills(sgs.masochism_skill) then return {} end
	
	if self:isFriend(fazheng) then
		for _, card in ipairs(cards) do
			if card:getSuit() ~= sgs.Card_Heart and self:canDraw(fazheng) and isCard("Peach", card, fazheng) and
			((not self:isWeak() and self:getCardsNum("Peach") > 0) or self:getCardsNum("Peach") > 1) then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if card:getSuit() ~= sgs.Card_Heart and self:canDraw(fazheng) and isCard("Analeptic", card, fazheng) and self:getCardsNum("Analeptic") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if card:getSuit() ~= sgs.Card_Heart and self:canDraw(fazheng) and isCard("Jink", card, fazheng) and self:getCardsNum("Jink") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			
			if isCard("Peach", card, fazheng) and ((not self:isWeak() and self:getCardsNum("Peach") > 0) or self:getCardsNum("Peach") > 1) then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if isCard("Analeptic", card, fazheng) and self:getCardsNum("Analeptic") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
			if isCard("Jink", card, fazheng) and self:getCardsNum("Jink") > 1 then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
		end
	end

	if self:needToLoseHp() and not self:hasSkills(sgs.masochism_skill) then return {} end
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and card:getSuit() == sgs.Card_Heart then
			table.insert(to_discard, card:getEffectiveId())
			return to_discard
		end
	end
	for _, card in ipairs(cards) do
		if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
			table.insert(to_discard, card:getEffectiveId())
			return to_discard
		end
	end
	return {}
end

--眩惑

--惴恐
sgs.ai_skill_invoke.tenyearzhuikong = function(self, data)
	if self.player:getHandcardNum() <= (self:isWeak() and 2 or 1) then return false end
	local current = self.room:getCurrent()
	if not current or self:isFriend(current) then return false end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	if self.player:hasSkill("yingyang") then max_point = math.min(max_point + 3, 13) end
	if not (current:hasSkill("zhiji") and current:getMark("zhiji") == 0 and current:getHandcardNum() == 1) and not
		(current:hasSkill("mobilezhiji") and current:getMark("mobilezhiji") == 0 and current:getHandcardNum() == 1) then
		local enemy_max_card = self:getMaxCard(current)
		local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
		if enemy_max_card and current:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point + 3, 13) end
		if max_point > enemy_max_point or max_point > 10 then
			self.tenyearzhuikong_card = max_card:getEffectiveId()
			return true
		end
	end
	if current:distanceTo(self.player) == 1 and not self:isValuableCard(max_card) then
		self.tenyearzhuikong_card = max_card:getEffectiveId()
		return true
	end
	return false
end

--求援
sgs.ai_skill_playerchosen.tenyearqiuyuan = function(self, targets)
	return sgs.ai_skill_playerchosen.qiuyuan(self, targets)
end

sgs.ai_skill_cardask["@tenyearqiuyuan-give"] = function(self, data, pattern, target)
	local give = true
	local huanghou = self.player:getTag("tenyearqiuyuan_from"):toPlayer()
	if not huanghou or huanghou:isDead() then return "." end
	if self:isEnemy(huanghou) then
		if not (self:needKongcheng() and self.player:getHandcardNum() == 1) then
			give = false
		end
	elseif self:isFriend(huanghou) then
		if not self:isWeak(huanghou) and self:hasSkills("leiji|nosleiji") then
			give = false
		end
	end
	if give == true then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("BasicCard") and not card:isKindOf("Slash") then
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end

--司敌
sgs.ai_skill_cardask["@tenyearsidi-put"] = function(self, data, pattern, target)
	local all = sgs.QList2Table(self.player:getCards("he"))
	local cards = {}
	for _,c in ipairs(all) do
		if c:isKindOf("BasicCard") or self:isValuableCard(c) then continue end
		table.insert(cards, c)
	end
	if #cards == 0 then return "." end
	self:sortByKeepValue(cards)
	return cards[1]:toString()
end

sgs.ai_skill_use["@@tenyearsidi"] = function(self, prompt)
	local name = prompt:split(":")[2]
	if not name then return "." end
	local player = self.room:findPlayerByObjectName(name)
	if not player or player:isDead() or not self:isEnemy(player) then return "." end
	for _,id in sgs.qlist(self.player:getPile("sidi")) do
		if sgs.Sanguosha:getCard(id):isBlack() then
			return "@TenyearSidiCard=" .. id
		end
	end
	return "@TenyearSidiCard=" .. self.player:getPile("sidi"):first()
end

sgs.ai_card_intention.TenyearSidiCard = 50

--怀异
local tenyearhuaiyi_skill = {}
tenyearhuaiyi_skill.name = "tenyearhuaiyi"
table.insert(sgs.ai_skills, tenyearhuaiyi_skill)
tenyearhuaiyi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return nil end
	if not self.player:hasUsed("TenyearHuaiyiCard") then
		return sgs.Card_Parse("@TenyearHuaiyiCard=.")
	end
	if self.player:usedTimes("TenyearHuaiyiCard") < 2 and self.player:getMark("tenyearhuaiyi-PlayClear") > 0 then
		return sgs.Card_Parse("@TenyearHuaiyiCard=.")
	end
end

sgs.ai_skill_use_func.TenyearHuaiyiCard = function(card, use, self)
    local handcards = self.player:getHandcards()
    local reds, blacks = {}, {}
    for _,c in sgs.qlist(handcards) do
		local dummy_use = {
            isDummy = true,
        }
        if c:isKindOf("BasicCard") then
            self:useBasicCard(c, dummy_use)
        elseif c:isKindOf("EquipCard") then
            self:useEquipCard(c, dummy_use)
        elseif c:isKindOf("TrickCard") then
            self:useTrickCard(c, dummy_use)
        end
        if dummy_use.card then
            return --It seems that self.player should use this card first.
        end
        if c:isRed() then
            table.insert(reds, c)
        else
            table.insert(blacks, c)
        end
    end
    
    local targets = self:findPlayerToDiscard("he", false, false, nil, true)
    local n_reds, n_blacks, n_targets = #reds, #blacks, #targets
	
	if n_reds == 0 or n_blacks == 0 then
		use.card = card
	end
	
    if n_targets == 0 then
        return 
    elseif n_reds - n_targets >= 2 and n_blacks - n_targets >= 2 and handcards:length() - n_targets >= 5 then
        return 
    end
    --[[------------------
        Haven't finished.
    ]]--------------------
    use.card = card
end

sgs.ai_skill_choice.tenyearhuaiyi = function(self, choices, data)
    return sgs.ai_skill_choice.huaiyi(self, choices, data)
end

sgs.ai_skill_use["@@tenyearhuaiyi"] = function(self, prompt, method)
    local n = self.player:getMark("tenyearhuaiyi_num-PlayClear")
    if n >= 2 then
        if self:needToLoseHp() then
        elseif self:isWeak() then
            n = 1
        end
    end
    if n == 0 then
        return "."
    end
    local targets = self:findPlayerToDiscard("he", false, false, nil, true)
    local names = {}
    for index, target in ipairs(targets) do
        if index <= n then
            table.insert(names, target:objectName())
        else
            break
        end
    end
    return "@TenyearHuaiyiSnatchCard=.->"..table.concat(names, "+")
end

--绝情
sgs.ai_skill_invoke.tenyearjueqing = function(self, data)
	local damage = self.player:getTag("tenyearjueqing_data"):toDamage()
	if not damage or damage.to:isDead() or self:isFriend(damage.to) then return false end
	if self:cantDamageMore(self.player, damage.to) then return false end
	local n = damage.damage - self.player:getHp()
        if n < 0 or hasBuquEffect(self.player) or self:getSaveNum(true) >= n then return true end
	return false
end

--弓骑
local tenyeargongqi_skill={}
tenyeargongqi_skill.name = "tenyeargongqi"
table.insert(sgs.ai_skills, tenyeargongqi_skill)
tenyeargongqi_skill.getTurnUseCard = function(self,inclusive)
	if self.player:hasUsed("TenyearGongqiCard") then return end
	if self:needBear() then return end
	if #self.enemies == 0 then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self:needToThrowArmor() then
		return sgs.Card_Parse("@TenyearGongqiCard=" .. self.player:getArmor():getEffectiveId())
	end

	for _, c in ipairs(cards) do
		if c:isKindOf("Weapon") then return sgs.Card_Parse("@TenyearGongqiCard=" .. c:getEffectiveId()) end
	end

	local handcards = self.player:getHandcards()
	handcards = sgs.QList2Table(handcards)
	local has_weapon, has_armor, has_def, has_off = false, false, false, false
	local weapon, armor
	for _, c in ipairs(handcards) do
		if c:isKindOf("Weapon") then
			has_weapon = true
			if not weapon or self:evaluateWeapon(weapon) < self:evaluateWeapon(c) then weapon = c end
		end
		if c:isKindOf("Armor") then
			has_armor = true
			if not armor or self:evaluateArmor(armor) < self:evaluateArmor(c) then armor = c end
		end
		if c:isKindOf("DefensiveHorse") then has_def = true end
		if c:isKindOf("OffensiveHorse") then has_off = true end
	end
	if has_off and self.player:getOffensiveHorse() then return sgs.Card_Parse("@TenyearGongqiCard=" .. self.player:getOffensiveHorse():getEffectiveId()) end
	if has_def and self.player:getDefensiveHorse() then return sgs.Card_Parse("@TenyearGongqiCard=" .. self.player:getDefensiveHorse():getEffectiveId()) end
	if has_weapon and self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) <= self:evaluateWeapon(weapon) then
		return sgs.Card_Parse("@TenyearGongqiCard=" .. self.player:getWeapon():getEffectiveId())
	end
	if has_armor and self.player:getArmor() and self:evaluateArmor(self.player:getArmor()) <= self:evaluateArmor(armor) then
		return sgs.Card_Parse("@TenyearGongqiCard=" .. self.player:getArmor():getEffectiveId())
	end

	if self:getOverflow() > 0 and self:getCardsNum("Slash") >= 1 then
		self:sortByKeepValue(handcards)
		self:sort(self.enemies, "defense")
		for _, c in ipairs(handcards) do
			if c:isKindOf("Snatch") or c:isKindOf("Dismantlement") then
				local use = { isDummy = true }
				self:useCardSnatch(c, use)
				if use.card then return end
			elseif isCard("Peach", c, self.player)
				or isCard("ExNihilo", c, self.player)
				or (isCard("Analeptic", c, self.player) and self.player:getHp() <= 2)
				or (isCard("Jink", c, self.player) and self:getCardsNum("Jink") < 2)
				or (isCard("Nullification", c, self.player) and self:getCardsNum("Nullification") < 2)
				or (isCard("Slash", c, self.player) and self:getCardsNum("Slash") == 1) then
				-- do nothing
			elseif not c:isKindOf("EquipCard") and #self.enemies > 0 and self.player:inMyAttackRange(self.enemies[1]) then
			else
				return sgs.Card_Parse("@TenyearGongqiCard=" .. c:getEffectiveId())
			end
		end
	end
end

sgs.ai_skill_use_func.TenyearGongqiCard = function(card, use, self)
	local id = card:getSubcards():first()
	local subcard = sgs.Sanguosha:getCard(id)
	if subcard:isKindOf("SilverLion") and self.room:getCardPlace(id) == sgs.Player_PlaceHand and self:isWounded() and self.player:canUse(subcard) then
		use.card = subcard
		return
	end
	use.card = card
end

sgs.ai_skill_playerchosen.tenyeargongqi = function(self, targets)
	local player = self:findPlayerToDiscard()
	return player
end

sgs.ai_use_value.TenyearGongqiCard = sgs.ai_use_value.GongqiCard
sgs.ai_use_priority.TenyearGongqiCard = sgs.ai_use_priority.GongqiCard

--解烦
local tenyearjiefan_skill = {}
tenyearjiefan_skill.name = "tenyearjiefan"
table.insert(sgs.ai_skills, tenyearjiefan_skill)
tenyearjiefan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@tenyearjiefanMark") == 0 then return end
	return sgs.Card_Parse("@TenyearJiefanCard=.")
end

sgs.ai_skill_use_func.TenyearJiefanCard = function(card, use, self)
	local target
	local use_value = 0
	local max_value = -10000
	local p_count = 0
	for _, friend in ipairs(self.friends) do
		use_value = 0
		local count = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
			if p:inMyAttackRange(friend) then
				count = count + 1
				if self:isFriend(p) then
					if not friend:hasSkill("manjuan") then use_value = use_value + 1 end
				else
					if p:getWeapon() then
						use_value = use_value + 1.2
					else
						if not friend:hasSkill("manjuan") then use_value = use_value + p:getHandcardNum() / 5 end
					end
				end
			end
		end
		if friend:objectName() == self.player:objectName() then p_count = count end
		use_value = use_value - friend:getHandcardNum() / 2
		if use_value > max_value then
			max_value = use_value
			target = friend
		end
	end

	if (target and max_value >= self.player:aliveCount() / 2) or self.room:getTag("TurnLengthCount"):toInt() == 1 then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end

	if (self:isWeak() and p_count > 0) or self.room:getTag("TurnLengthCount"):toInt() == 1 then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end
end

sgs.ai_card_intention.TenyearJiefanCard = sgs.ai_card_intention.JiefanCard

function sgs.ai_cardneed.tenyearjiefan(to, card, self)
	return sgs.ai_cardneed.jiefan(to, card, self)
end

--忠勇

--急攻

--竭忠
sgs.ai_skill_invoke.tenyearjiezhong = function(self, data)
	return self:canDraw() and self.player:getHp() - self.player:getHandcardNum() > 1
end

--龙吟
sgs.ai_skill_cardask["@tenyearlongyin"] = function(self, data)
	return sgs.ai_skill_cardask["@longyin"](self, data)
end

--窃听

--献州

--慎行

--秉壹

--第二版镇军 第二版精策 第二版陷阵


