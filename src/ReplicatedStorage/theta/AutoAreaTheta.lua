-- AutoAreaTheta.lua

-- 自动锻炼区规则参数：名称、倍率、解锁所需重生次数。
local AutoAreaTheta = {
	R1 = {
		Name = "R1",
		Multiplier = 1.1,
		RequiredRebirth = 0,
	},
	R2 = {
		Name = "R2",
		Multiplier = 1.25,
		RequiredRebirth = 0,
	},
	R3 = {
		Name = "R3",
		Multiplier = 1.5,
		RequiredRebirth = 1,
	},
	R4 = {
		Name = "R4",
		Multiplier = 2,
		RequiredRebirth = 2,
	},
	R5 = {
		Name = "R5",
		Multiplier = 3,
		RequiredRebirth = 3,
	},
	SR1 = {
		Name = "SR1",
		Multiplier = 4,
		RequiredRebirth = 4,
	},
	SR2 = {
		Name = "SR2",
		Multiplier = 6,
		RequiredRebirth = 5,
	},
	SR3 = {
		Name = "SR3",
		Multiplier = 8,
		RequiredRebirth = 6,
	},
}

return AutoAreaTheta
