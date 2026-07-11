-- CharacterMorphTheta
-- 玩家 R15 角色形态、等级阶段和尺寸配置。

local CharacterMorphTheta = {
	TemplateFolderPath = { "Assets", "Body" },
	RigNames = {
		"Rig1",
		"Rig2",
		"Rig3",
		"Rig4",
		"Rig5",
	},
	PhaseScaleStep = 0.05,
	RebirthScaleStep = 0.05,
	MinScale = 1,
	MaxScale = 2.5,
	RebirthDestinationId = "World1",
}

return CharacterMorphTheta
