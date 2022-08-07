-- translation for YingbianPackage

local t = {
	["yingbian_cards"] = "应变篇",
	["yb_fujia1"] = "富甲",--使用时手牌最多
	["yb_fujia2"] = "富甲",
	["yb_zhuzhan1"] = "助战",--指定目标后，除目标角色外的其他角色可以弃置一张同类型的手牌
	["yb_zhuzhan2"] = "助战",
	["yb_kongchao1"] = "空巢",--使用时没有手牌
	["yb_kongchao2"] = "空巢",
	["yb_kongchao3"] = "空巢",
	["yb_canqu1"] = "残躯",--使用时体力值为1
	["yb_canqu2"] = "残躯",
	
	[":yb_fujia1"] = "富甲->不能响应",
	[":yb_fujia2"] = "富甲->可使目标-1",
	[":yb_zhuzhan1"] = "助战->依次执行所有效果",
	[":yb_zhuzhan2"] = "助战->目标+1",
	[":yb_kongchao1"] = "空巢->摸一张牌",
	[":yb_kongchao2"] = "空巢->获得响应的牌",
	[":yb_kongchao3"] = "空巢->目标+1",
	[":yb_canqu1"] = "残躯->伤害+1",
	[":yb_canqu2"] = "残躯->目标+1",
	
	["#FuJia1NoRespond"] = "%from 的“%arg”效果被触发，%card 不能被响应",
	["yb_fujia2-reduce"] = "你可以发动“富甲”效果，为【%src】减少一名目标角色",
	["yb_kongchao3-add"] = "你可以发动“空巢”效果，为【%src】增加一名目标角色",
	["yb_canqu2-add"] = "你可以发动“残躯”效果，为【%src】增加一名目标角色",
	["yb_zhuzhan2-add"] = "你可以发动“助战”效果，为【%src】增加一名目标角色",
	["#CanQu1AddDamage"] = "%from 的“%arg”效果被触发，对 %to 的伤害+1",
	["yb_zhuzhan-discard"] = "你可以弃置一张同类型的手牌为【%src】助战",

	["ice_slash"] = "冰杀",
	[":ice_slash"] = "基本牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：攻击范围内的一名角色<br /><b>效果</b>：对目标角色造成1点冰属性伤害。",
	
	["suijiyingbian"] = "随机应变",
	[":suijiyingbian"] = "锦囊牌<br /><b>效果</b>：你的回合内，你手牌中的此牌视为你本回合使用或打出的上一张基本牌或非延时类锦囊牌。",
	
	["dongzhuxianji"] = "洞烛先机",
	[":dongzhuxianji"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：目标角色卜算2，然后摸两张牌。",
	
	["chuqibuyi"] = "出其不意",
	[":chuqibuyi"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名有手牌的角色<br /><b>效果</b>：你展示目标角色一张手牌，若该牌与此牌花色不同，你对其造成1点伤害。",
	
	["zhujinqiyuan"] = "逐近弃远",
	[":zhujinqiyuan"] = "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：一名区域内有牌的其他角色<br /><b>效果</b>：若你与目标角色的距离大于1，你弃置其区域里的一张牌；"..
						"若你与目标角色的距离为1，你获得其区域里的一张牌。",
	
	["wuxinghelingshan"] = "五行鹤翎扇",
	[":wuxinghelingshan"] = "装备牌·武器<br /><b>攻击范围</b>：4<br /><b>武器技能</b>：你可以将一张属性【杀】当其他属性的【杀】使用。",

	["wutiesuolian"] = "乌铁锁链",
	[":wutiesuolian"] = "装备牌·武器<br /><b>攻击范围</b>：3<br /><b>武器技能</b>：锁定技，当你使用【杀】指定目标后，若其：横置，你观看其手牌；未横置，你横置其武将牌。",
	
	["heiguangkai"] = "黑光铠",
	[":heiguangkai"] = "装备牌·防具<br /><b>防具技能</b>：锁定技，目标数大于1的非延时类锦囊牌和【杀】对你无效。",
	
	["huxinjing"] = "护心镜",
	[":huxinjing"] = "装备牌·防具<br /><b>防具技能</b>：当你受到伤害时，若此伤害值不小于你的体力值，你可以将装备区内的此牌置入弃牌堆，防止此伤害。",
	
	["taigongyinfu"] = "太公阴符",
	[":taigongyinfu"] = "装备牌·宝物<br /><b>宝物技能</b>：出牌阶段开始时，你可以横置一名武将牌未横置的角色的武将牌；出牌阶段结束时，你可以重铸一张手牌。",
	["@taigongyinfu-chain"] = "你可以横置一名角色的武将牌",
	["@taigongyinfu-recast"] = "你可以重铸一张手牌",
	
	["tianjitu"] = "天机图",
	[":tianjitu"] = "装备牌·宝物<br /><b>宝物技能</b>：锁定技，当此牌置入你的装备区后，你弃置一张其他牌；当你失去装备区内的此牌后，将手牌摸至五张。",
	
	["tongque"] = "铜雀",
	[":tongque"] = "装备牌·宝物<br /><b>宝物技能</b>：你使用的具有应变效果的牌可以直接发动其应变效果。",
}

return t