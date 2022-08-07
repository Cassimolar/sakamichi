-- translation for MobileMouYu Package

return {
	["mobilemouyu"] = "手杀虞包",
	
	["mobilemou_huangzhong"] = "谋黄忠",
	["#mobilemou_huangzhong"] = "没金铩羽",
	["illustrator:mobilemou_huangzhong"] = "",
	["mobilemouliegong"] = "烈弓",
	[":mobilemouliegong"] = "你使用【杀】可以选择距离不大于此【杀】点数的角色为目标。你使用牌时或成为其他角色使用的牌的目标后，若此牌有花色且花色未被“烈弓”记录，记录此花色。" ..
							"当你使用【杀】指定唯一目标后，你可以展示牌堆顶的X张牌（X为你记录的花色数-1），然后此【杀】伤害+Y（Y为展示牌中被记录的花色），" ..
							"且其不能使用被记录花色的【闪】响应此【杀】。若如此做，此【杀】结算完时，清除“烈弓”的记录。",

	["mobilemou_lvmeng"] = "谋吕蒙",
	["#mobilemou_lvmeng"] = "苍海一笠",
	["illustrator:mobilemou_lvmeng"] = "",
	["mobilemoukeji"] = "克己",
	[":mobilemoukeji"] = "<font color=\"green\"><b>出牌阶段各限一次（“渡江”发动后，改为出牌阶段限一次），</b></font>你可以选择一项：" ..
						"1.弃置一张手牌，获得1点护甲；2.失去1点体力，获得2点护甲。你的手牌上限+X（X为你的护甲值）。若你不处于濒死状态，你不能使用【桃】。" ..
						"\n◆<font color=\"red\"><b>护甲上限为5</b></font>",
	["mobilemoudujiang"] = "渡江",
	[":mobilemoudujiang"] = "觉醒技，准备阶段开始时，若你拥有至少3点护甲，你获得“夺荆”。",
	["#MobileMouDujiang"] = "%from 有 %arg 点护甲，触发“%arg2”觉醒",
	["mobilemouduojing"] = "夺荆",
	[":mobilemouduojing"] = "你使用【杀】指定一名其他角色为目标时，你可以失去1点护甲，令此【杀】无视其防具，然后获得其一张手牌，且此回合可以额外使用一张【杀】。",
	
	["mobilemou_yujin"] = "谋于禁",
	["#mobilemou_yujin"] = "威严毅重",
	["illustrator:mobilemou_yujin"] = "",
	["mobilemouxiayuan"] = "狭援",
	[":mobilemouxiayuan"] = "每轮限一次，其他角色受到伤害后，若此伤害令其失去了全部护甲，你可以弃置两张手牌，令其获得此伤害失去的护甲。\n◆<font color=\"red\"><b>护甲上限为5</b></font>",
	["@mobilemouxiayuan"] = "你可以弃置两张手牌，令%src获得%arg点护甲",
	["mobilemoujieyue"] = "节钺",
	[":mobilemoujieyue"] = "结束阶段开始时，你可以令一名其他角色获得1点护甲，然后其摸两张牌并交给你两张牌。\n◆<font color=\"red\"><b>护甲上限为5</b></font>",
	["@mobilemoujieyue-invoke"] = "你可以令一名其他角色获得1点护甲，然后其摸两张牌并交给你两张牌",
	["@mobilemoujieyue-give"] = "请交给%src两张牌",
}
	