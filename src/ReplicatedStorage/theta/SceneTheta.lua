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

	EggDisplayModelName = "EggModel",
	EggPromptPartName = "PromptPart",
	EggInteractionDistance = 12,

	Attributes = {
		CurrentBarbellId = "MG_CurrentBarbellId",
		IsTraining = "MG_IsTraining",
		EquippedPetsJson = "MG_EquippedPetsJson",
	},
}

return SceneTheta
