-- RebirthTheta.lua (ModuleScript)
local RebirthTheta = { -- 重生规则参数：训练通用倍率、等级上限。
	[0] = {
		Multiplier = 1,
		MaxLevel = 5,
	},
	[1] = {
		Multiplier = 1,
		MaxLevel = 10,
	},
	[2] = {
		Multiplier = 4,
		MaxLevel = 15,
	},
	[3] = {
		Multiplier = 8,
		MaxLevel = 20,
	},
	-- 未配置的重生次数，使用最后一条配置（或使用公式计算）
}

return RebirthTheta
