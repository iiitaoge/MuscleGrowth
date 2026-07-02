-- 玩家最小持久状态 S_p：只保存无法由配置和其他字段确定推导的事实。
local PlayerProgressInitialTheta = {
	Strength = 0,
	Trophies = 0,
	Exp = 0,
	RebirthCount = 0,
	CurrentBarbellId = "T1",
	CurrentPetId = "P1",
	BodyQuality = "Normal",
}

return PlayerProgressInitialTheta
