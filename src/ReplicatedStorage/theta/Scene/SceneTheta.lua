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
		CurrentBarbellId = "MG_CurrentBarbellId",
		IsTraining = "MG_IsTraining",
		IsPushingBall = "MG_IsPushingBall",
		EquippedPetsJson = "MG_EquippedPetsJson",
		LastTrainingGainSerial = "MG_LastTrainingGainSerial",
		LastTrainingStrengthGain = "MG_LastTrainingStrengthGain",
	},
}

return SceneTheta
