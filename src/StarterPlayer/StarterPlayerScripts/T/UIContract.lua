-- UIContract
-- 统一验证客户端 UI theta 配置，并向各 UI 模块提供已验证配置。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")

local HUDPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("HUDPanelTheta"))
local FloatingGainTheta = require(theta:WaitForChild("UI"):WaitForChild("FloatingGainTheta"))
local RebirthPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("RebirthPanelTheta"))
local PetInventoryPanelTheta = require(theta:WaitForChild("UI"):WaitForChild("PetInventoryPanelTheta"))
local BarbellDisplayTheta = require(theta:WaitForChild("UI"):WaitForChild("BarbellDisplayTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))
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
	local path = requireTable(value, context)
	assert(#path > 0, context .. " must not be empty.")

	for index, childName in ipairs(path) do
		requireString(childName, context .. "[" .. tostring(index) .. "]")
	end

	return cloneValue(path)
end

local function requirePathMap(value, context, keys)
	local source = requireTable(value, context)
	local result = {}

	for _, key in ipairs(keys) do
		result[key] = requirePath(source[key], context .. "." .. key)
	end

	return result
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
	return {
		ScreenGuiName = requireString(HUDPanelTheta.ScreenGuiName, "HUDPanelTheta.ScreenGuiName"),
		Paths = requirePathMap(HUDPanelTheta.Paths, "HUDPanelTheta.Paths", {
			"StrengthText",
			"TrophiesText",
			"RebirthMultiplierText",
			"BarbellMultiplierText",
			"PetMultiplierText",
			"ExpBar",
			"LevelText",
			"ExpText",
			"RebirthButton",
		}),
	}
end

local function validateFloatingGain()
	local templates = requireStringMap(FloatingGainTheta.Templates, "FloatingGainTheta.Templates", {
		"StrengthGain",
		"TrophyGain",
	})
	local animation = requireTable(FloatingGainTheta.Animation, "FloatingGainTheta.Animation")

	return {
		ScreenGuiName = requireString(FloatingGainTheta.ScreenGuiName, "FloatingGainTheta.ScreenGuiName"),
		Templates = templates,
		Animation = {
			OffsetScaleY = requireNumber(animation.OffsetScaleY, "FloatingGainTheta.Animation.OffsetScaleY"),
			Duration = requireNumber(animation.Duration, "FloatingGainTheta.Animation.Duration"),
			DestroyDelay = requireNumber(animation.DestroyDelay, "FloatingGainTheta.Animation.DestroyDelay"),
		},
	}
end

local function validateRebirthRenderBinding(binding, index)
	local context = "RebirthPanelTheta.RenderBindings[" .. tostring(index) .. "]"
	requireTable(binding, context)

	local operation = requireString(binding.Operation, context .. ".Operation")
	assert(
		operation == "SetText"
			or operation == "SetDescendantTexts"
			or operation == "SetTextSequenceByMatch"
			or operation == "SetSizeXScale",
		context .. ".Operation is not supported: " .. operation
	)

	local result = {
		Key = requireString(binding.Key, context .. ".Key"),
		ModelKey = requireString(binding.ModelKey, context .. ".ModelKey"),
		Operation = operation,
		Optional = requireOptionalBoolean(binding.Optional, context .. ".Optional"),
	}

	if binding.Ref ~= nil then
		result.Ref = requireString(binding.Ref, context .. ".Ref")
	end
	if binding.Path ~= nil then
		result.Path = requirePath(binding.Path, context .. ".Path")
	end
	if binding.RootPath ~= nil then
		result.RootPath = requirePath(binding.RootPath, context .. ".RootPath")
	end

	if operation == "SetTextSequenceByMatch" then
		local match = requireTable(binding.Match, context .. ".Match")
		local matchType = requireString(match.MatchType, context .. ".Match.MatchType")
		assert(matchType == "Pattern" or matchType == "Contains", context .. ".Match.MatchType is not supported.")

		result.Match = {
			MatchType = matchType,
		}
		if matchType == "Pattern" then
			result.Match.Pattern = requireString(match.Pattern, context .. ".Match.Pattern")
		else
			result.Match.Contains = requireString(match.Contains, context .. ".Match.Contains")
		end
	end

	return result
end

local function validateRebirthPanel()
	local renderBindings = {}
	for index, binding in ipairs(requireTable(RebirthPanelTheta.RenderBindings, "RebirthPanelTheta.RenderBindings")) do
		renderBindings[index] = validateRebirthRenderBinding(binding, index)
	end

	return {
		ScreenGuiName = requireString(RebirthPanelTheta.ScreenGuiName, "RebirthPanelTheta.ScreenGuiName"),
		Paths = requirePathMap(RebirthPanelTheta.Paths, "RebirthPanelTheta.Paths", {
			"PanelRoot",
		}),
		Nodes = requireStringMap(RebirthPanelTheta.Nodes, "RebirthPanelTheta.Nodes", {
			"CloseButtonName",
			"ActionButtonName",
			"TitleTextName",
			"TipTextName",
			"FallbackTipTextName",
		}),
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
	clonedPaths.RewardSlots = clonedRewardSlots

	return {
		ScreenGuiName = requireString(EggPanelTheta.ScreenGuiName, "EggPanelTheta.ScreenGuiName"),
		Paths = clonedPaths,
		RewardSlotFields = requireStringMap(EggPanelTheta.RewardSlotFields, "EggPanelTheta.RewardSlotFields", {
			"Icon",
			"ChanceText",
			"MultiplierText",
		}),
		ResultTemplateFields = requireStringMap(EggPanelTheta.ResultTemplateFields, "EggPanelTheta.ResultTemplateFields", {
			"Icon",
			"NameText",
			"RarityText",
		}),
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
	clonedPaths.RewardSlots = clonedRewardSlots

	return {
		ScreenGuiName = requireString(EggRevealPanelTheta.ScreenGuiName, "EggRevealPanelTheta.ScreenGuiName"),
		Paths = clonedPaths,
		RewardSlotFields = requireStringMap(EggRevealPanelTheta.RewardSlotFields, "EggRevealPanelTheta.RewardSlotFields", {
			"Icon",
			"NameText",
			"RarityText",
		}),
		ContinuePromptText = requireString(
			EggRevealPanelTheta.ContinuePromptText,
			"EggRevealPanelTheta.ContinuePromptText"
		),
	}
end

local function validatePetInventory()
	return {
		HudScreenGuiName = requireString(PetInventoryPanelTheta.HudScreenGuiName, "PetInventoryPanelTheta.HudScreenGuiName"),
		ScreenGuiName = requireString(PetInventoryPanelTheta.ScreenGuiName, "PetInventoryPanelTheta.ScreenGuiName"),
		Paths = requirePathMap(PetInventoryPanelTheta.Paths, "PetInventoryPanelTheta.Paths", {
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
			"EquipBestButton",
			"UnequipAllButton",
			"DeleteButton",
		}),
		PetCardFields = requireStringMap(PetInventoryPanelTheta.PetCardFields, "PetInventoryPanelTheta.PetCardFields", {
			"Icon",
			"MultiplierText",
		}),
		EquippedTextFormat = requireString(PetInventoryPanelTheta.EquippedTextFormat, "PetInventoryPanelTheta.EquippedTextFormat"),
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
			Path = requirePath(buttonConfig.Path, context .. ".Path"),
		}
		hasDestinationButton = true
	end

	assert(hasDestinationButton, "TravelPanelTheta.DestinationButtons must not be empty.")

	return {
		HudScreenGuiName = requireString(TravelPanelTheta.HudScreenGuiName, "TravelPanelTheta.HudScreenGuiName"),
		ScreenGuiName = requireString(TravelPanelTheta.ScreenGuiName, "TravelPanelTheta.ScreenGuiName"),
		Paths = requirePathMap(TravelPanelTheta.Paths, "TravelPanelTheta.Paths", {
			"OpenButton",
			"PanelRoot",
			"CloseButton",
		}),
		DestinationButtons = validatedDestinationButtons,
	}
end

local function validateBarbellDisplay()
	return {
		WorkspaceRootName = requireString(SceneTheta.WorkspaceRootName, "SceneTheta.WorkspaceRootName"),
		SceneEquipmentRootName = requireString(
			BarbellDisplayTheta.SceneEquipmentRootName,
			"BarbellDisplayTheta.SceneEquipmentRootName"
		),
		DisplayModelName = requireString(BarbellDisplayTheta.DisplayModelName, "BarbellDisplayTheta.DisplayModelName"),
		BillboardGuiPath = requirePath(BarbellDisplayTheta.BillboardGuiPath, "BarbellDisplayTheta.BillboardGuiPath"),
		FieldPaths = requirePathMap(BarbellDisplayTheta.FieldPaths, "BarbellDisplayTheta.FieldPaths", {
			"PowerText",
			"CostText",
			"Locked",
			"Equip",
			"Equipped",
		}),
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
