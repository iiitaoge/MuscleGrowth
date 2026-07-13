-- UIContract
-- 统一验证客户端 UI theta 配置，并向各 UI 模块提供已验证配置。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")

local AutoAreaTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("AutoAreaTheta"))
local AutoAreaSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("AutoAreaSceneTheta"))
local AutoAreaDisplayTheta = require(theta:WaitForChild("UI"):WaitForChild("AutoAreaDisplayTheta"))
local HUDPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("HUDPanelTheta"))
local FloatingGainTheta = require(theta:WaitForChild("UI"):WaitForChild("FloatingGainTheta"))
local RebirthPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("RebirthPanelTheta"))
local PetInventoryPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("PetInventoryPanelTheta"))
local BarbellDisplayTheta = require(theta:WaitForChild("UI"):WaitForChild("BarbellDisplayTheta"))
local EggPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("EggPanelTheta"))
local EggRevealPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("EggRevealPanelTheta"))
local TravelPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("TravelPanelTheta"))

local UIContract = {}

local validatedConfigs = nil

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, childValue in pairs(value) do
		copy[cloneValue(key)] = cloneValue(childValue)
	end

	return copy
end

local function requireString(value, context)
	assert(type(value) == "string" and value ~= "", context .. " must be a non-empty string.")
	return value
end

local function requireNumber(value, context)
	assert(type(value) == "number", context .. " must be a number.")
	return value
end

local function requireTable(value, context)
	assert(type(value) == "table", context .. " must be a table.")
	return value
end

local function requirePath(value, context)
	local source = requireTable(value, context)
	local rootKey = requireString(source.RootKey, context .. ".RootKey")
	local path = requireTable(source.Path, context .. ".Path")
	assert(#path > 0, context .. " must not be empty.")

	for key in pairs(path) do
		assert(
			type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #path,
			context .. ".Path must be an array of strings."
		)
	end

	for index = 1, #path do
		local childName = path[index]
		requireString(childName, context .. ".Path[" .. tostring(index) .. "]")
	end

	return {
		RootKey = rootKey,
		Path = cloneValue(path),
	}
end

local function requirePathList(value, context)
	local source = requireTable(value, context)
	assert(#source > 0, context .. " must not be empty.")
	for key in pairs(source) do
		assert(
			type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #source,
			context .. " must be an array of path specifications."
		)
	end

	local result = {}
	for index, pathSpec in ipairs(source) do
		result[index] = requirePath(pathSpec, context .. "[" .. tostring(index) .. "]")
	end
	return result
end

local function requirePathMap(value, context, keys)
	local source = requireTable(value, context)
	local result = {}

	for _, key in ipairs(keys) do
		result[key] = requirePath(source[key], context .. "." .. key)
	end

	return result
end

local function requirePathRoot(pathSpec, expectedRootKey, context)
	assert(
		pathSpec.RootKey == expectedRootKey,
		("%s.RootKey must be %s."):format(context, expectedRootKey)
	)
	return pathSpec
end

local function requireStringMap(value, context, keys)
	local source = requireTable(value, context)
	local result = {}

	for _, key in ipairs(keys) do
		result[key] = requireString(source[key], context .. "." .. key)
	end

	return result
end

local function requireOptionalBoolean(value, context)
	if value == nil then
		return nil
	end

	assert(type(value) == "boolean", context .. " must be a boolean.")
	return value
end

local function validateHUD()
	local paths = requirePathMap(HUDPanelTheta.Paths, "HUDPanelTheta.Paths", {
		"StrengthText",
		"StrengthIconGlow",
		"TrophiesText",
		"RebirthMultiplierText",
		"BarbellMultiplierText",
		"PetMultiplierText",
		"ExpBar",
		"LevelText",
		"ExpText",
		"RebirthButton",
		"RebirthProgressText",
		"AutoWinButton",
		"AutoWinOn",
		"AutoWinOff",
	})
	for key, pathSpec in pairs(paths) do
		requirePathRoot(pathSpec, "ScreenGui", "HUDPanelTheta.Paths." .. key)
	end

	return {
		ScreenGuiName = requireString(HUDPanelTheta.ScreenGuiName, "HUDPanelTheta.ScreenGuiName"),
		Paths = paths,
	}
end

local function validateFloatingGain()
	local paths = requirePathMap(FloatingGainTheta.Paths, "FloatingGainTheta.Paths", {
		"StrengthGain",
		"TrophyGain",
	})
	local animation = requireTable(FloatingGainTheta.Animation, "FloatingGainTheta.Animation")
	for key, pathSpec in pairs(paths) do
		requirePathRoot(pathSpec, "ScreenGui", "FloatingGainTheta.Paths." .. key)
	end

	return {
		ScreenGuiName = requireString(FloatingGainTheta.ScreenGuiName, "FloatingGainTheta.ScreenGuiName"),
		Paths = paths,
		Animation = {
			OffsetScaleY = requireNumber(animation.OffsetScaleY, "FloatingGainTheta.Animation.OffsetScaleY"),
			Duration = requireNumber(animation.Duration, "FloatingGainTheta.Animation.Duration"),
			FloatDuration = requireNumber(animation.FloatDuration, "FloatingGainTheta.Animation.FloatDuration"),
			ConvergeDuration = requireNumber(
				animation.ConvergeDuration,
				"FloatingGainTheta.Animation.ConvergeDuration"
			),
			DestroyDelay = requireNumber(animation.DestroyDelay, "FloatingGainTheta.Animation.DestroyDelay"),
		},
	}
end

local function validateRebirthRenderBinding(binding, index)
	local context = "RebirthPanelTheta.RenderBindings[" .. tostring(index) .. "]"
	requireTable(binding, context)

	local operation = requireString(binding.Operation, context .. ".Operation")
	local targetType = requireString(binding.TargetType, context .. ".TargetType")
	assert(
		targetType == "GuiObject" or targetType == "TextObject" or targetType == "GuiButton",
		context .. ".TargetType is not supported: " .. targetType
	)
	assert(
		operation == "SetText"
			or operation == "SetTextTargets"
			or operation == "SetSizeXScale",
		context .. ".Operation is not supported: " .. operation
	)

	local result = {
		Key = requireString(binding.Key, context .. ".Key"),
		ModelKey = requireString(binding.ModelKey, context .. ".ModelKey"),
		Operation = operation,
		TargetType = targetType,
		Optional = requireOptionalBoolean(binding.Optional, context .. ".Optional"),
	}

	if binding.Path ~= nil then
		result.Path = requirePath(binding.Path, context .. ".Path")
	end
	if binding.TargetPaths ~= nil then
		result.TargetPaths = requirePathList(binding.TargetPaths, context .. ".TargetPaths")
	end

	if operation == "SetTextTargets" then
		assert(result.TargetPaths and #result.TargetPaths > 0, context .. ".TargetPaths is required for SetTextTargets.")
		assert(result.Path == nil, context .. ".Path is not allowed for SetTextTargets.")
	else
		assert(result.Path ~= nil, context .. ".Path is required for " .. operation .. ".")
		assert(result.TargetPaths == nil, context .. ".TargetPaths is only allowed for SetTextTargets.")
	end

	return result
end

local function validateRebirthPanel()
	local renderBindings = {}
	for index, binding in ipairs(requireTable(RebirthPanelTheta.RenderBindings, "RebirthPanelTheta.RenderBindings")) do
		renderBindings[index] = validateRebirthRenderBinding(binding, index)
	end

	local paths = requirePathMap(RebirthPanelTheta.Paths, "RebirthPanelTheta.Paths", {
		"PanelRoot",
		"CloseButton",
		"RequestButton",
		"TitleText",
		"TipText",
		"LevelProgressFill",
		"LevelProgressText",
		"RequestButtonText",
	})
	paths.RebirthCountTexts = requirePathList(RebirthPanelTheta.Paths.RebirthCountTexts, "RebirthPanelTheta.Paths.RebirthCountTexts")
	paths.PowerTexts = requirePathList(RebirthPanelTheta.Paths.PowerTexts, "RebirthPanelTheta.Paths.PowerTexts")
	paths.MaxLevelTexts = requirePathList(RebirthPanelTheta.Paths.MaxLevelTexts, "RebirthPanelTheta.Paths.MaxLevelTexts")
	assert(paths.PanelRoot.RootKey == "ScreenGui", "RebirthPanelTheta.Paths.PanelRoot.RootKey must be ScreenGui.")
	for _, key in ipairs({ "CloseButton", "RequestButton", "TitleText", "TipText", "LevelProgressFill", "LevelProgressText", "RequestButtonText" }) do
		assert(paths[key].RootKey == "PanelRoot", "RebirthPanelTheta.Paths." .. key .. ".RootKey must be PanelRoot.")
	end
	for _, key in ipairs({ "RebirthCountTexts", "PowerTexts", "MaxLevelTexts" }) do
		for index, pathSpec in ipairs(paths[key]) do
			assert(
				pathSpec.RootKey == "PanelRoot",
				("RebirthPanelTheta.Paths.%s[%d].RootKey must be PanelRoot."):format(key, index)
			)
		end
	end

	for _, binding in ipairs(renderBindings) do
		if binding.Path then
			assert(
				binding.Path.RootKey == "PanelRoot",
				"Rebirth render binding " .. binding.Key .. ".Path.RootKey must be PanelRoot."
			)
		end
		for targetIndex, targetPath in ipairs(binding.TargetPaths or {}) do
			assert(
				targetPath.RootKey == "PanelRoot",
				("Rebirth render binding %s.TargetPaths[%d].RootKey must be PanelRoot."):format(binding.Key, targetIndex)
			)
		end
	end

	return {
		ScreenGuiName = requireString(RebirthPanelTheta.ScreenGuiName, "RebirthPanelTheta.ScreenGuiName"),
		Paths = paths,
		RenderBindings = renderBindings,
	}
end

local function validateEggPanel()
	local paths = requireTable(EggPanelTheta.Paths, "EggPanelTheta.Paths")
	local rewardSlots = requireTable(paths.RewardSlots, "EggPanelTheta.Paths.RewardSlots")
	assert(#rewardSlots > 0, "EggPanelTheta.Paths.RewardSlots must not be empty.")

	local clonedRewardSlots = {}
	for index, path in ipairs(rewardSlots) do
		clonedRewardSlots[index] = requirePath(path, "EggPanelTheta.Paths.RewardSlots[" .. tostring(index) .. "]")
	end

	local clonedPaths = requirePathMap(paths, "EggPanelTheta.Paths", {
		"PanelRoot",
		"TitleRoot",
		"CloseButton",
		"ResultTemplate",
		"ButtonRoot",
		"SingleRollButton",
		"TripleRollButton",
		"AutoRollButton",
	})
	for key, pathSpec in pairs(clonedPaths) do
		requirePathRoot(pathSpec, "ScreenGui", "EggPanelTheta.Paths." .. key)
	end
	for index, pathSpec in ipairs(clonedRewardSlots) do
		requirePathRoot(pathSpec, "ScreenGui", "EggPanelTheta.Paths.RewardSlots[" .. tostring(index) .. "]")
	end
	clonedPaths.RewardSlots = clonedRewardSlots
	local rewardSlotFieldPathSpecs = requirePathMap(
		EggPanelTheta.RewardSlotFieldPathSpecs,
		"EggPanelTheta.RewardSlotFieldPathSpecs",
		{ "Icon", "ChanceText", "MultiplierText" }
	)
	for key, pathSpec in pairs(rewardSlotFieldPathSpecs) do
		requirePathRoot(pathSpec, "RewardSlot", "EggPanelTheta.RewardSlotFieldPathSpecs." .. key)
	end
	local resultTemplateFieldPathSpecs = requirePathMap(
		EggPanelTheta.ResultTemplateFieldPathSpecs,
		"EggPanelTheta.ResultTemplateFieldPathSpecs",
		{ "Icon", "NameText", "RarityText" }
	)
	for key, pathSpec in pairs(resultTemplateFieldPathSpecs) do
		requirePathRoot(pathSpec, "ResultTemplate", "EggPanelTheta.ResultTemplateFieldPathSpecs." .. key)
	end

	return {
		ScreenGuiName = requireString(EggPanelTheta.ScreenGuiName, "EggPanelTheta.ScreenGuiName"),
		Paths = clonedPaths,
		RewardSlotFieldPathSpecs = rewardSlotFieldPathSpecs,
		ResultTemplateFieldPathSpecs = resultTemplateFieldPathSpecs,
		RollButtonText = requireStringMap(EggPanelTheta.RollButtonText, "EggPanelTheta.RollButtonText", {
			"Single",
			"Triple",
			"Auto",
			"AutoStop",
		}),
	}
end

local function validateEggRevealPanel()
	local paths = requireTable(EggRevealPanelTheta.Paths, "EggRevealPanelTheta.Paths")
	local rewardSlots = requireTable(paths.RewardSlots, "EggRevealPanelTheta.Paths.RewardSlots")
	assert(#rewardSlots == 3, "EggRevealPanelTheta.Paths.RewardSlots must have exactly 3 slots.")

	local clonedRewardSlots = {}
	for index, path in ipairs(rewardSlots) do
		clonedRewardSlots[index] = requirePath(path, "EggRevealPanelTheta.Paths.RewardSlots[" .. tostring(index) .. "]")
	end

	local clonedPaths = requirePathMap(paths, "EggRevealPanelTheta.Paths", {
		"PanelRoot",
		"Background",
		"ContinueButton",
		"ContinueText",
		"StopButton",
	})
	for key, pathSpec in pairs(clonedPaths) do
		requirePathRoot(pathSpec, "ScreenGui", "EggRevealPanelTheta.Paths." .. key)
	end
	for index, pathSpec in ipairs(clonedRewardSlots) do
		requirePathRoot(pathSpec, "ScreenGui", "EggRevealPanelTheta.Paths.RewardSlots[" .. tostring(index) .. "]")
	end
	clonedPaths.RewardSlots = clonedRewardSlots
	local rewardSlotFieldPathSpecs = requirePathMap(
		EggRevealPanelTheta.RewardSlotFieldPathSpecs,
		"EggRevealPanelTheta.RewardSlotFieldPathSpecs",
		{ "Icon", "NameText", "RarityText" }
	)
	for key, pathSpec in pairs(rewardSlotFieldPathSpecs) do
		requirePathRoot(pathSpec, "RewardSlot", "EggRevealPanelTheta.RewardSlotFieldPathSpecs." .. key)
	end

	return {
		ScreenGuiName = requireString(EggRevealPanelTheta.ScreenGuiName, "EggRevealPanelTheta.ScreenGuiName"),
		Paths = clonedPaths,
		RewardSlotFieldPathSpecs = rewardSlotFieldPathSpecs,
		ContinuePromptText = requireString(
			EggRevealPanelTheta.ContinuePromptText,
			"EggRevealPanelTheta.ContinuePromptText"
		),
	}
end

local function validatePetInventory()
	local paths = requirePathMap(PetInventoryPanelTheta.Paths, "PetInventoryPanelTheta.Paths", {
		"PetButton",
		"PanelRoot",
		"BackPackRoot",
		"CloseButton",
		"OwnedList",
		"OwnedTemplate",
		"EquippedList",
		"EquippedTemplate",
		"EquippedText",
		"NoPet",
		"TipRoot",
		"TipText",
		"EquipBestButton",
		"UnequipAllButton",
		"DeleteButton",
		"DeleteModeRoot",
		"SelectAllButton",
		"CancelDeleteButton",
		"ConfirmDeleteButton",
	})
	requirePathRoot(paths.PetButton, "HUDScreenGui", "PetInventoryPanelTheta.Paths.PetButton")
	for key, pathSpec in pairs(paths) do
		if key ~= "PetButton" then
			requirePathRoot(pathSpec, "ScreenGui", "PetInventoryPanelTheta.Paths." .. key)
		end
	end
	local petCardFieldPathSpecs = requirePathMap(
		PetInventoryPanelTheta.PetCardFieldPathSpecs,
		"PetInventoryPanelTheta.PetCardFieldPathSpecs",
		{ "Icon", "MultiplierText" }
	)
	for key, pathSpec in pairs(petCardFieldPathSpecs) do
		requirePathRoot(pathSpec, "PetCard", "PetInventoryPanelTheta.PetCardFieldPathSpecs." .. key)
	end

	local temporaryTipSeconds = requireNumber(
		PetInventoryPanelTheta.TemporaryTipSeconds,
		"PetInventoryPanelTheta.TemporaryTipSeconds"
	)
	assert(temporaryTipSeconds >= 0, "PetInventoryPanelTheta.TemporaryTipSeconds must be non-negative.")

	return {
		HudScreenGuiName = requireString(PetInventoryPanelTheta.HudScreenGuiName, "PetInventoryPanelTheta.HudScreenGuiName"),
		ScreenGuiName = requireString(PetInventoryPanelTheta.ScreenGuiName, "PetInventoryPanelTheta.ScreenGuiName"),
		Paths = paths,
		PetCardFieldPathSpecs = petCardFieldPathSpecs,
		EquippedTextFormat = requireString(PetInventoryPanelTheta.EquippedTextFormat, "PetInventoryPanelTheta.EquippedTextFormat"),
		Messages = requireStringMap(PetInventoryPanelTheta.Messages, "PetInventoryPanelTheta.Messages", {
			"DeletePrompt",
			"SlotFull",
			"AlreadyEquipped",
			"DeleteEquippedBlocked",
			"EmptyDeleteSelection",
			"DeleteFailed",
		}),
		TemporaryTipSeconds = temporaryTipSeconds,
	}
end

local function validateTravelPanel()
	local destinationButtons = requireTable(TravelPanelTheta.DestinationButtons, "TravelPanelTheta.DestinationButtons")
	local validatedDestinationButtons = {}
	local hasDestinationButton = false

	for key, buttonConfig in pairs(destinationButtons) do
		local context = "TravelPanelTheta.DestinationButtons." .. tostring(key)
		buttonConfig = requireTable(buttonConfig, context)
		validatedDestinationButtons[key] = {
			DestinationId = requireString(buttonConfig.DestinationId, context .. ".DestinationId"),
			PathSpec = requirePath(buttonConfig.PathSpec, context .. ".PathSpec"),
		}
		requirePathRoot(validatedDestinationButtons[key].PathSpec, "ScreenGui", context .. ".PathSpec")
		hasDestinationButton = true
	end

	assert(hasDestinationButton, "TravelPanelTheta.DestinationButtons must not be empty.")

	local paths = requirePathMap(TravelPanelTheta.Paths, "TravelPanelTheta.Paths", {
		"OpenButton",
		"PanelRoot",
		"CloseButton",
	})
	requirePathRoot(paths.OpenButton, "HUDScreenGui", "TravelPanelTheta.Paths.OpenButton")
	requirePathRoot(paths.PanelRoot, "ScreenGui", "TravelPanelTheta.Paths.PanelRoot")
	requirePathRoot(paths.CloseButton, "ScreenGui", "TravelPanelTheta.Paths.CloseButton")

	return {
		HudScreenGuiName = requireString(TravelPanelTheta.HudScreenGuiName, "TravelPanelTheta.HudScreenGuiName"),
		ScreenGuiName = requireString(TravelPanelTheta.ScreenGuiName, "TravelPanelTheta.ScreenGuiName"),
		Paths = paths,
		DestinationButtons = validatedDestinationButtons,
	}
end

local function validateBarbellDisplay()
	local displayRootPathSpec = requirePath(
		BarbellDisplayTheta.DisplayRootPathSpec,
		"BarbellDisplayTheta.DisplayRootPathSpec"
	)
	local trainSourceRootPathSpec = requirePath(
		BarbellDisplayTheta.TrainSourceRootPathSpec,
		"BarbellDisplayTheta.TrainSourceRootPathSpec"
	)
	local billboardPathSpec = requirePath(
		BarbellDisplayTheta.BillboardGuiPathSpec,
		"BarbellDisplayTheta.BillboardGuiPathSpec"
	)
	local fieldPathSpecs = requirePathMap(BarbellDisplayTheta.FieldPathSpecs, "BarbellDisplayTheta.FieldPathSpecs", {
		"PowerText",
		"CostText",
		"Locked",
		"Equip",
		"Equipped",
	})
	requirePathRoot(displayRootPathSpec, "Workspace", "BarbellDisplayTheta.DisplayRootPathSpec")
	requirePathRoot(trainSourceRootPathSpec, "ServerStorage", "BarbellDisplayTheta.TrainSourceRootPathSpec")
	requirePathRoot(billboardPathSpec, "DisplayModel", "BarbellDisplayTheta.BillboardGuiPathSpec")
	for key, pathSpec in pairs(fieldPathSpecs) do
		requirePathRoot(pathSpec, "DisplayModel", "BarbellDisplayTheta.FieldPathSpecs." .. key)
	end

	return {
		DisplayModelName = requireString(BarbellDisplayTheta.DisplayModelName, "BarbellDisplayTheta.DisplayModelName"),
		DisplayRootPathSpec = displayRootPathSpec,
		TrainSourceRootPathSpec = trainSourceRootPathSpec,
		BillboardGuiPathSpec = billboardPathSpec,
		FieldPathSpecs = fieldPathSpecs,
	}
end

local function validateAutoAreaDisplay()
	local fieldPathSpecs = requirePathMap(
		AutoAreaDisplayTheta.FieldPathSpecs,
		"AutoAreaDisplayTheta.FieldPathSpecs",
		{ "PowerText", "RebirthText", "Locked", "Unlocked" }
	)
	for key, pathSpec in pairs(fieldPathSpecs) do
		requirePathRoot(pathSpec, "AutoAreaInstance", "AutoAreaDisplayTheta.FieldPathSpecs." .. key)
	end

	local instances = {}
	local instanceCount = 0
	for instanceId, instanceConfig in pairs(requireTable(AutoAreaSceneTheta.Instances, "AutoAreaSceneTheta.Instances")) do
		local context = "AutoAreaSceneTheta.Instances." .. tostring(instanceId)
		requireString(instanceId, context .. " key")
		instanceConfig = requireTable(instanceConfig, context)

		local areaId = requireString(instanceConfig.AreaId, context .. ".AreaId")
		local areaConfig = requireTable(AutoAreaTheta[areaId], context .. ".AreaId gameplay config")
		requireNumber(areaConfig.Multiplier, "AutoAreaTheta." .. areaId .. ".Multiplier")
		local requiredRebirth = requireNumber(
			areaConfig.RequiredRebirth,
			"AutoAreaTheta." .. areaId .. ".RequiredRebirth"
		)
		assert(
			requiredRebirth >= 0 and requiredRebirth % 1 == 0,
			"AutoAreaTheta." .. areaId .. ".RequiredRebirth must be a non-negative integer."
		)

		local touchPathSpec = requirePath(instanceConfig.TouchPathSpec, context .. ".TouchPathSpec")
		requirePathRoot(touchPathSpec, "Workspace", context .. ".TouchPathSpec")
		instances[instanceId] = {
			AreaId = areaId,
			TouchPathSpec = touchPathSpec,
		}
		instanceCount += 1
	end
	assert(instanceCount > 0, "AutoAreaSceneTheta.Instances must not be empty.")

	return {
		FieldPathSpecs = fieldPathSpecs,
		Instances = instances,
	}
end

function UIContract.ValidateAll()
	if validatedConfigs then
		return validatedConfigs
	end

	validatedConfigs = {
		HUD = validateHUD(),
		FloatingGain = validateFloatingGain(),
		RebirthPanel = validateRebirthPanel(),
		EggPanel = validateEggPanel(),
		EggRevealPanel = validateEggRevealPanel(),
		PetInventory = validatePetInventory(),
		TravelPanel = validateTravelPanel(),
		BarbellDisplay = validateBarbellDisplay(),
		AutoAreaDisplay = validateAutoAreaDisplay(),
	}

	return validatedConfigs
end

function UIContract.GetConfig(configName)
	local configs = UIContract.ValidateAll()
	local config = configs[configName]
	assert(config, "Unknown UI contract config: " .. tostring(configName))
	return config
end

return UIContract
