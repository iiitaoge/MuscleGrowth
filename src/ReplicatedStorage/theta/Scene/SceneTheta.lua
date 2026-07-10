local SceneTheta = {
	WorkspaceRootName = "UseScene",
	SceneEquipmentRootName = "SceneEquipment",
	SceneEggRootName = "SceneEgg",
	SceneTrainAreaRootName = "SceneTrainAreas",

	ServerToUseSceneRootName = "ToUseScene",
	ReplicatedAssetsRootName = "Assets",
	ClientToUseSceneRootName = "ToUseScene",

	EggSourceFolderName = "Egg",
	TrainEquipmentSourceFolderName = "TrainEquipment",
	PetSourceFolderName = "PetToEgg",

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
		CurrentBarbellId = "MG_CurrentBarbellId",
		IsTraining = "MG_IsTraining",
		IsPushingBall = "MG_IsPushingBall",
		EquippedPetsJson = "MG_EquippedPetsJson",
		LastTrainingGainSerial = "MG_LastTrainingGainSerial",
		LastTrainingStrengthGain = "MG_LastTrainingStrengthGain",
		-- 当前被推的球实例ID
		ActivePushBallInstanceId = "MG_ActivePushBallInstanceId",
	},
}

return SceneTheta
