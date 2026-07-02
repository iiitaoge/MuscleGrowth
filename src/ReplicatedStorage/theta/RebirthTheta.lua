-- RebirthTheta.lua (ModuleScript)
local RebirthTheta = { -- 重生规则参数：力量倍率、经验倍率、等级上限。
	[0] = {
		StrengthMultiplier = 1,
		ExpMultiplier = 1,
		MaxLevel = 5,
	},
	[1] = {
		StrengthMultiplier = 2,
		ExpMultiplier = 1.5,
		MaxLevel = 10,
	},
	[2] = {
		StrengthMultiplier = 4,
		ExpMultiplier = 2.0,
		MaxLevel = 15,
	},
	[3] = {
		StrengthMultiplier = 8,
		ExpMultiplier = 3.0,
		MaxLevel = 20,
	},
	-- 未配置的重生次数，使用最后一条配置（或使用公式计算）
}

return RebirthTheta
