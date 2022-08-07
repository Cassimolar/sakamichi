--美人计

--笑里藏刀

--连计

--矜功

--十周年连计

--OL连计

--手杀连计

--屯储

--输粮

--天命
sgs.ai_skill_invoke.newtianming = function(self, data)
	return sgs.ai_skill_invoke.tianming(self, data)
end

sgs.ai_skill_discard.newtianming = function(self, discard_num, min_num, optional, include_equip)
	return sgs.ai_skill_discard.tianming(self, discard_num, min_num, optional, include_equip)
end

--观虚

--雅士

--挫锐
sgs.ai_skill_use["@@spcuorui"] = function(self, prompt)
	local targets = self:findPlayerToDiscard("h", false, false, nil, true)
	if #targets <= 0 then return "." end
	
	local tos = {}
	for i = 1, math.min(self.player:getHp(), #targets) do
		table.insert(tos, targets[i]:objectName())
	end
	return "@SpCuoruiCard=.->" .. table.concat(tos, "+")
end

--裂围
sgs.ai_skill_invoke.spliewei = function(self, data)
	return self:canDraw()
end

--挫锐-第二版

--裂围-第二版
sgs.ai_skill_invoke.secondspliewei = function(self, data)
	return self:canDraw()
end

--天算
function getSpecialMark(special_mark, player)
	player = player or self.player
	local num = 0
	local marks = player:getMarkNames()
	for _,mark in ipairs(marks) do
		if not mark:startsWith(special_mark) or player:getMark(mark) <= 0 then continue end
		num = num + 1
	end
	return num
end

--掳掠

--望归
sgs.ai_skill_playerchosen.wanggui = function(self, targets)
	if targets:first():getKingdom() == self.player:getKingdom() then
		local target = self:findPlayerToDraw(false, 1)
		if target then return target end
		if self:canDraw() then return self.player end
	else
		return self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targets)
	end
	return nil
end

--息兵
sgs.ai_skill_invoke.xibing = function(self, data)
	local target = data:toPlayer()
	local hand_num = target:getHandcardNum()
	local num = target:getHp() - hand_num
	if num <= 0 then return false end
	if self:isFriend(target) then
		if hand_num > 2 then return false end
		return true
	elseif self:isEnemy(target) then
		if hand_num <= 2 then return false end
		if hand_num >= 5 then return true end
	end
	return false
end

--诱言
sgs.ai_skill_invoke.youyan = function(self, data)
	return self:canDraw()
end

--追还
sgs.ai_skill_playerchosen.zhuihuan = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _,p in ipairs(targets) do
		if not self:isFriend(p) or p:getMark("&zhuihuan") > 0 then continue end
		return p
	end
	for _,p in ipairs(targets) do
		if not self:isFriend(p) then continue end
		return p
	end
	return nil
end

--抗歌

--节烈

--拒关

--驱徙

--齐攻

--列侯

--狼灭

--祸水

--倾城

--祈禳

--寇略

--随认

--摧坚

--同援
