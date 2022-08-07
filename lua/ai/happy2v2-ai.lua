--溃击
local kuiji_skill = {}
kuiji_skill.name = "kuiji"
table.insert(sgs.ai_skills, kuiji_skill)
kuiji_skill.getTurnUseCard = function(self)
	if self.player:containsTrick("supply_shortage") or self.player:hasUsed("KuijiCard") or not self.player:hasJudgeArea() then return end
	return sgs.Card_Parse("@KuijiCard=.")
end

sgs.ai_skill_use_func.KuijiCard = function(card, use, self)
	local cards = {}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("BasicCard") and c:isBlack() then
			table.insert(cards, c)
		end
	end
	if #cards <= 0 then return end
	self:sortByKeepValue(cards)
	use.card = sgs.Card_Parse("@KuijiCard=" .. cards[1]:getEffectiveId())
end

sgs.ai_skill_playerchosen.kuiji = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	if not self.player:isYourFriend(targets[1]) then
		for _,p in ipairs(targets) do
                        if self:cantDamageMore(self.player, p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then return p end
		end
		for _,p in ipairs(targets) do
			if self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then return p end
		end
	end

	for _, p in ipairs(targets) do
		if self:isWeak(p) then return p end
	end
	
	return targets[#targets]
end

sgs.ai_use_priority.KuijiCard = 10
sgs.ai_use_value.KuijiCard = 10

--挫锐
sgs.ai_skill_playerchosen.happycuorui = function(self, targets)
	if self.player:isYourFriend(targets:first()) then
		local target = self:findPlayerToDiscard("hej", true, true, targets)
		return target
	end
	
	local target = self:findPlayerToDiscard("e", false, true, targets)
	if target then return target end
	
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self.player:canDiscard(p, "e") and not self:doNotDiscard(p, "e") then
			table.insert(enemies, p)
		end
	end
	if #enemies > 0 then self:sort(enemies, "defense") return enemies[1] end
	for _,p in sgs.qlist(targets) do
		if self.player:canDiscard(p, "e") then
			table.insert(enemies, p)
		end
	end
	if #enemies > 0 then self:sort(enemies, "defense") return enemies[1] end
	return targets:first()
end

sgs.ai_skill_choice.happycuorui = function(self, choices, data)
	local id = data:toInt()
	local card = sgs.Sanguosha:getCard(id)
	local enemies = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:isYourFriend(p) then continue end
		if not p:getEquips():isEmpty() then
			for _,c in sgs.qlist(p:getCards("e")) do
				if c:sameColorWith(card) and self.player:canDiscard(p, c:getEffectiveId()) and not self:doNotDiscard(p, "e") then
					table.insert(enemies, p)
				end
			end
		end
	end
	
	if #enemies > 0 then return "discard" end
	return "show"
end

sgs.ai_skill_playerchosen.happycuorui2 = function(self, targets)
	local target = self:findPlayerToDiscard("e", false, true, targets)
	return target
end

sgs.ai_skill_playerchosen.happycuorui3 = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	return targets[1]
end

