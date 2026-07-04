-- RebirthTheta.lua (ModuleScript)
local RebirthTheta = { -- 重生规则参数：训练通用倍率、等级上限、展示颜色。
	[0] = {
		Multiplier = 1,
		MaxLevel = 10,
		Color = "#FFF8C9",
	},
	[1] = {
		Multiplier = 2,
		MaxLevel = 15,
		Color = "#FFF4BA",
	},
	[2] = {
		Multiplier = 2.5,
		MaxLevel = 25,
		Color = "#FFF0AB",
	},
	[3] = {
		Multiplier = 3,
		MaxLevel = 35,
		Color = "#FFEB9C",
	},
	[4] = {
		Multiplier = 3.5,
		MaxLevel = 45,
		Color = "#FFE78D",
	},
	[5] = {
		Multiplier = 4,
		MaxLevel = 50,
		Color = "#FFE27E",
	},
	[6] = {
		Multiplier = 4.5,
		MaxLevel = 55,
		Color = "#FFDD70",
	},
	[7] = {
		Multiplier = 5,
		MaxLevel = 60,
		Color = "#FFD861",
	},
	[8] = {
		Multiplier = 5.5,
		MaxLevel = 65,
		Color = "#FFD352",
	},
	[9] = {
		Multiplier = 6,
		MaxLevel = 70,
		Color = "#FFCC45",
	},
	[10] = {
		Multiplier = 6.5,
		MaxLevel = 75,
		Color = "#FFC438",
	},
	[11] = {
		Multiplier = 8.5,
		MaxLevel = 85,
		Color = "#FFBA30",
	},
	[12] = {
		Multiplier = 10,
		MaxLevel = 100,
		Color = "#FFAE2A",
	},
	[13] = {
		Multiplier = 12.5,
		MaxLevel = 115,
		Color = "#FFA124",
	},
	[14] = {
		Multiplier = 15,
		MaxLevel = 135,
		Color = "#FF921F",
	},
	[15] = {
		Multiplier = 17.5,
		MaxLevel = 150,
		Color = "#FF811C",
	},
	[16] = {
		Multiplier = 18,
		MaxLevel = 175,
		Color = "#FF6E1B",
	},
	[17] = {
		Multiplier = 19.5,
		MaxLevel = 200,
		Color = "#FF591B",
	},
	-- 未配置的重生次数，使用最后一条配置（或使用公式计算）
}

return RebirthTheta
