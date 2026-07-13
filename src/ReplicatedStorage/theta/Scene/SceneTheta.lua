local SceneTheta = {
	UseSceneRootPathSpec = { RootKey = "Workspace", Path = { "UseScene" } },
	ClientTrainEquipmentPathSpec = {
		RootKey = "ReplicatedStorage",
		Path = { "Assets", "ToUseScene", "TrainEquipment" },
	},
	ClientPetSourcePathSpec = {
		RootKey = "ReplicatedStorage",
		Path = { "Assets", "ToUseScene", "PetToEgg" },
	},

	BarbellDisplayModelName = "DisplayModel",
	BarbellPromptPartName = "PromptPart",
	BarbellTrainModelName = "Train",
	BarbellMaxEquipDistance = 18,
	BarbellDisplayRotationOffsetDegrees = {
		X = 30,
		Y = 35.264,
		Z = -35.264,
	},

	EggDisplayModelName = "EggModel",
	EggPromptPartName = "PromptPart",
	EggInteractionDistance = 12,

	Attributes = {
		-- 这里只是定义 Attribute 的名字
		DataLoaded = "MuscleGrowthDataLoaded",
		CurrentBarbellId = "MG_CurrentBarbellId",
		IsTraining = "MG_IsTraining",
		IsPushingBall = "MG_IsPushingBall",
		IsAutoWinEnabled = "MG_IsAutoWinEnabled",
		EquippedPetsJson = "MG_EquippedPetsJson",
		LastTrainingGainSerial = "MG_LastTrainingGainSerial",
		LastTrainingStrengthGain = "MG_LastTrainingStrengthGain",
		-- 当前被推的球实例ID
		ActivePushBallInstanceId = "MG_ActivePushBallInstanceId",
	},
}

return SceneTheta
