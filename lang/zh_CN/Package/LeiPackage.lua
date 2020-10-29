-- translation for Lei Package

return {
	["Lei"] = "雷包",
	
	["chendao"] = "陈到",
	["#chendao"] = "白毦督",
	["illustrator:chendao"] = "王立雄",
	["wanglie"] = "往烈",
	[":wanglie"] = "出牌阶段，你使用的第一张牌无距离限制。当你于出牌阶段使用一张牌时，你可令此牌不能被响应，若如此做，本回合你不能再使用牌。",
	
	["zhugezhan"] = "诸葛瞻",
	["#zhugezhan"] = "临难死义",
	["illustrator:zhugezhan"] = "zoo",
	["zuilun"] = "罪论",
	[":zuilun"] = "结束阶段开始时，你可以观看牌堆顶的三张牌，你每满足以下一项便保留一张，然后以任意顺序放回其余的牌：1.你于此回合内造成过伤害；2.你于此回合内未弃置过牌；3.手牌数为全场最少。若均不满足，你与一名其他角色失去1点体力。",
	["#ZuilunNum"] = "%from 共满足 %arg 项，可以获得 %arg 张牌",
	["zuilun-lose"] = "请选择一名其他角色，你与其各失去1点体力",
	["fuyin"] = "父荫",
	[":fuyin"] = "锁定技，你每回合第一次成为【杀】或【决斗】的目标后，若你的手牌数小于等于使用者，此牌对你无效。",
	
	["zhoufei"] = "周妃",
	["#zhoufei"] = "软玉温香",
	["illustrator:zhoufei"] = "眉毛子",
	["liangyin"] = "良姻",
	[":liangyin"] = "当有牌移出游戏时，你可以令手牌数大于你的一名角色摸一张牌；当有牌从游戏外加入任意角色的手牌时，你可以令手牌数小于你的一名角色弃置一张牌。",
	["liangyin-draw"] = "你可以令手牌数大于你的一名角色摸一张牌",
	["liangyin-discard"] = "你可以令手牌数小于你的一名角色弃置一张牌",
	["kongsheng"] = "箜声",
	[":kongsheng"] = "准备阶段开始时，你可以将任意张牌置于武将牌上。结束阶段开始时，你使用武将牌上的装备牌，并获得武将牌上的其他牌。",
	["kongsheng-put"] = "你可以将任意张牌置于武将牌上",
	
	["lei_lukang"] = "陆抗",
	["#lei_lukang"] = "社稷之瑰宝",
	["illustrator:lei_lukang"] = "zoo",
	["qianjie"] = "谦节",
	[":qianjie"] = "锁定技，你的武将牌不能被横置。你不能成为延时类锦囊牌或其他角色拼点的目标。",
	["jueyan"] = "决堰",
	[":jueyan"] = "出牌阶段限一次，你可以废除你装备区里的一个装备栏，然后执行对应的一项，效果持续到回合结束：武器栏，你可以多使用三张【杀】；防具栏，摸三张牌，手牌上限+3；两个坐骑栏，你使用牌无距离限制；宝物栏，获得技能“集智”。",
	["jueyan:0"] = "废除武器栏",
	["jueyan:1"] = "废除防具栏",
	["jueyan:23"] = "废除两个坐骑栏",
	["jueyan:4"] = "废除宝物栏",
	["poshi"] = "破势",
	[":poshi"] = "觉醒技，准备阶段开始时，若你的装备栏均被废除或体力值为1，你减1点体力上限，然后将手牌补至体力上限，失去技能“决堰”并获得技能“怀柔”。",
	["huairou"] = "怀柔",
	[":huairou"] = "出牌阶段，你可以重铸装备牌。",
	
	["haozhao"] = "郝昭",
	["#haozhao"] = "扣弦的豪将",
	["illustrator:haozhao"] = "秋呆呆",
	["zhengu"] = "镇骨",
	[":zhengu"] = "结束阶段开始时，你可以选择一名其他角色，你的回合结束时和该角色的下个回合结束时，其将手牌摸至或弃至与你手牌数相同（最多摸至五张）。",
	["zhengu-invoke"] = "你可以发动“镇骨”",
	["#ZhenguEffect"] = "%from 的“%arg”效果被触发",
	
	["guanqiujian"] = "毌丘俭",
	["#guanqiujian"] = "镌功铭征荣",
	["illustrator:guanqiujian"] = "凝聚永恒",
	["zhengrong"] = "征荣",
	[":zhengrong"] = "当你对其他角色造成伤害后，若其手牌数大于你，你可以将其一张牌置于你的武将牌上，称为“荣”。",
	["rong"] = "荣",
	["hongju"] = "鸿举",
	[":hongju"] = "觉醒技，准备阶段开始时，若“荣”的数量不小于3且有角色死亡，你可以用任意张手牌替换等量的“荣”，然后减1点体力上限并获得技能“清侧”。",
	["@hongju"] = "你可以用任意张手牌替换等量的“荣”",
	["~hongju"] = "选择任意张手牌和等量的“荣”→点“确定”",
	["qingce"] = "清侧",
	[":qingce"] = "出牌阶段，你可以移去一张“荣”，然后弃置场上的一张牌。",
	
	["ol_guanqiujian"] = "OL毌丘俭",
	["&ol_guanqiujian"] = "毌丘俭",
	["olzhengrong"] = "征荣",
	[":olzhengrong"] = "当你使用【杀】或伤害类锦囊牌指定目标后，你可以选择其中一个手牌数大于等于你的目标角色，将其一张牌置于你的武将牌上，称为“荣”。",
	--["olrong"] = "荣",
	["olzhengrong-invoke"] = "你可以发动“征荣”",
	["olhongju"] = "鸿举",
	[":olhongju"] = "觉醒技，准备阶段开始时，若“荣”的数量大于等于3，你可以用任意张手牌替换等量的“荣”，然后减1点体力上限并获得技能“清侧”。",
	["@olhongju"] = "你可以用任意张手牌替换等量的“荣”",
	["~olhongju"] = "选择任意张手牌和等量的“荣”→点“确定”",
	["olqingce"] = "清侧",
	[":olqingce"] = "出牌阶段，你可以获得一张“荣”并弃置一张手牌，然后弃置场上的一张牌。",
	
	["mobile_guanqiujian"] = "毌丘俭-手杀",
	["&mobile_guanqiujian"] = "毌丘俭",
	["mobilezhengrong"] = "征荣",
	[":mobilezhengrong"] = "锁定技，当你于出牌阶段使用牌时，若此牌是你本阶段使用的第偶数张牌且目标包含其他角色，你选择一名有牌的其他角色，随机将其一张牌置于你的武将牌上，称为“荣”。",
	["mobilezhengrong-invoke"] = "请选择一名有牌的其他角色，随机将其一张牌置于你的武将牌上",
	["mobilehongju"] = "鸿举",
	[":mobilehongju"] = "觉醒技，准备阶段开始时，若“荣”的数量不小于3且有角色死亡，你摸等于“荣”数量的牌，以任意张手牌替换等量的“荣”，然后你减1点体力上限，获得技能“清侧”。",
	["@mobilehongju"] = "你可以用任意张手牌替换等量的“荣”",
	["~mobilehongju"] = "选择任意张手牌和等量的“荣”→点“确定”",
	
	["lei_yuanshu"] = "袁术",
	["#lei_yuanshu"] = "仲家帝",
	["illustrator:god_yuanshu"] = "波子",
	["leiyongsi"]="庸肆",
	[":leiyongsi"]="锁定技，摸牌阶段，你改为摸X张牌（X为存活势力数）；出牌阶段结束时，若你此阶段：1.没有造成伤害，将手牌数摸至体力值；2.造成伤害数超过1点，本回合手牌上限改为已损失体力值。",
	["#LeiyongsiDrawNum"] = "%from 的“%arg”被触发，改为摸 %arg2 张牌",
	["#LeiyongsiDraw"] = "%from 的“<font color=\"yellow\"><b>庸肆</b></font>”被触发，本回合共造成 %arg 点伤害，将摸 %arg2 张牌",
	["#LeiyongsiMax"] = "%from 的“<font color=\"yellow\"><b>庸肆</b></font>”被触发，本回合共造成 %arg 点伤害，本回合手牌上限等于 %arg2",
	["leiweidi"] = "伪帝",
	[":leiweidi"] = "主公技，你于弃牌阶段弃置的牌可以交给任意名其他群势力角色各一张。",
	["leiweidi-give"] = "你可以交给任意名其他群势力角色各一张牌",
	
	["zhangxiu"] = "张绣",
	["#zhangxiu"] = "北地枪王",
	["illustrator:zhangxiu"] = "PCC",
	["congjian"] = "从谏",
	[":congjian"] = "当你成为锦囊牌的目标后，若此牌的目标数大于1，你可以交给其中一名目标角色一张牌，然后摸一张牌。若你给出的牌是装备牌，改为摸两张牌。",
	["@congjian"] = "你可以交给一名其他角色一张牌",
	["~congjian"] = "选择一张牌和一名目标角色→点“确定”",
	["xiongluan"] = "雄乱",
	[":xiongluan"] = "限定技，出牌阶段，你可以废除你的判定区和装备区并指定一名其他角色，直到回合结束，你对其使用牌无距离和次数限制，其不能使用和打出手牌。",
}
