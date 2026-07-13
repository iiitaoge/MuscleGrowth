-- UIRefs
-- 客户端运行时 UI/场景实例解析总入口。配置结构由 UIContract 先验证，这里只解析真实实例。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))
local ButtonMotion = require(script.Parent.ButtonMotion)
local UIContract = require(script.Parent.UIContract)

local UIRefs = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5
local SCENE_WAIT_SECONDS = 10

-- ===== 通用解析工具 =====

local function waitForChild(parent, childName, context, timeout)
	local child = parent:WaitForChild(childName, timeout or NODE_WAIT_SECONDS)
	if not child then
		error(context .. " '" .. childName .. "' was not found under " .. parent:GetFullName() .. ".", 2)
	end

	return child
end

local function resolvePathSpec(roots, pathSpec, context, timeout)
	if typeof(roots) == "Instance" then
		assert(
			type(pathSpec) == "table" and type(pathSpec.RootKey) == "string" and pathSpec.RootKey ~= "",
			(context or "UI path") .. " must use { RootKey, Path }."
		)
		roots = { [pathSpec.RootKey] = roots }
	end

	local current = InstancePath.WaitSpec(roots, pathSpec, timeout or NODE_WAIT_SECONDS)
	if current then
		return current
	end

	return InstancePath.RequireSpec(roots, pathSpec, context)
end

local waitForPath = resolvePathSpec

local function requireScreenGui(instance, context)
	assert(instance:IsA("ScreenGui"), context .. " must be a ScreenGui.")
	return instance
end

local function requireGuiObject(instance, context)
	assert(instance:IsA("GuiObject"), context .. " must be a GuiObject.")
	return instance
end

local function requireGuiButton(instance, context)
	assert(instance:IsA("GuiButton"), context .. " must be a GuiButton.")
	ButtonMotion.Bind(instance)
	return instance
end

local function requireTextLabel(instance, context)
	assert(instance:IsA("TextLabel"), context .. " must be a TextLabel.")
	return instance
end

local function requireTextObject(instance, context)
	assert(
		instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox"),
		context .. " must be a text object."
	)
	return instance
end

local function requireImageObject(instance, context)
	assert(instance:IsA("ImageLabel") or instance:IsA("ImageButton"), context .. " must be an image object.")
	return instance
end

local function waitForPlayerGui(player)
	return waitForChild(player, "PlayerGui", "PlayerGui", GUI_WAIT_SECONDS)
end

local function waitForScreenGui(playerGui, screenGuiName, context)
	return requireScreenGui(waitForChild(playerGui, screenGuiName, context, GUI_WAIT_SECONDS), context)
end

-- ===== HUD =====

function UIRefs.ResolveHUD(player)
	local config = UIContract.GetConfig("HUD")
	local playerGui = waitForPlayerGui(player)
	local hud = waitForScreenGui(playerGui, config.ScreenGuiName, "HUD ScreenGui")
	local paths = config.Paths

	return {
		StrengthText = requireTextObject(waitForPath(hud, paths.StrengthText, "HUD StrengthText"), "HUD StrengthText"),
		StrengthIconGlow = requireGuiObject(
			waitForPath(hud, paths.StrengthIconGlow, "HUD StrengthIconGlow"),
			"HUD StrengthIconGlow"
		),
		TrophiesText = requireTextObject(waitForPath(hud, paths.TrophiesText, "HUD TrophiesText"), "HUD TrophiesText"),
		RebirthMultiplierText = requireTextObject(
			waitForPath(hud, paths.RebirthMultiplierText, "HUD RebirthMultiplierText"),
			"HUD RebirthMultiplierText"
		),
		BarbellMultiplierText = requireTextObject(
			waitForPath(hud, paths.BarbellMultiplierText, "HUD BarbellMultiplierText"),
			"HUD BarbellMultiplierText"
		),
		PetMultiplierText = requireTextObject(
			waitForPath(hud, paths.PetMultiplierText, "HUD PetMultiplierText"),
			"HUD PetMultiplierText"
		),
		ExpBar = requireGuiObject(waitForPath(hud, paths.ExpBar, "HUD ExpBar"), "HUD ExpBar"),
		LevelText = requireTextObject(waitForPath(hud, paths.LevelText, "HUD LevelText"), "HUD LevelText"),
		ExpText = requireTextObject(waitForPath(hud, paths.ExpText, "HUD ExpText"), "HUD ExpText"),
		RebirthButton = requireGuiButton(
			waitForPath(hud, paths.RebirthButton, "HUD RebirthButton"),
			"HUD RebirthButton"
		),
		RebirthProgressText = requireTextObject(
			waitForPath(hud, paths.RebirthProgressText, "HUD RebirthProgressText"),
			"HUD RebirthProgressText"
		),
	}
end

-- ===== FloatingGain =====

function UIRefs.ResolveFloatingGain(player)
	local config = UIContract.GetConfig("FloatingGain")
	local playerGui = waitForPlayerGui(player)
	local hud = waitForScreenGui(playerGui, config.ScreenGuiName, "Floating gain HUD ScreenGui")
	local strengthTemplate = requireGuiObject(
		resolvePathSpec({ ScreenGui = hud }, config.Paths.StrengthGain, "Floating gain strength template"),
		"Floating gain strength template"
	)
	local trophyTemplate = requireGuiObject(
		resolvePathSpec({ ScreenGui = hud }, config.Paths.TrophyGain, "Floating gain trophy template"),
		"Floating gain trophy template"
	)

	strengthTemplate.Visible = false
	trophyTemplate.Visible = false

	return {
		StrengthTemplate = strengthTemplate,
		TrophyTemplate = trophyTemplate,
		Animation = config.Animation,
	}
end

-- ===== RebirthPanel =====

local function validateRebirthTargetType(target, targetType, context)
	if not target then
		return
	end

	if targetType == "TextObject" then
		assert(
			target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("TextBox"),
			context .. " must be a text object."
		)
	elseif targetType == "GuiButton" then
		assert(target:IsA("GuiButton"), context .. " must be a GuiButton.")
	else
		assert(target:IsA("GuiObject"), context .. " must be a GuiObject.")
	end
end

local function resolveRebirthBindingTarget(refs, binding)
	if binding.Path then
		return resolvePathSpec(
			{ PanelRoot = refs.PanelRoot },
			binding.Path,
			"Rebirth render binding " .. binding.Key
		)
	end

	return nil
end

local function resolveRebirthRenderBindings(refs, bindings)
	local resolvedBindings = {}
	for index, binding in ipairs(bindings) do
		local target = resolveRebirthBindingTarget(refs, binding)
		local targets = nil
		if binding.TargetPaths then
			targets = {}
			for targetIndex, targetPath in ipairs(binding.TargetPaths) do
				targets[targetIndex] = resolvePathSpec(
					{ PanelRoot = refs.PanelRoot },
					targetPath,
					"Rebirth render binding " .. binding.Key .. " target " .. tostring(targetIndex)
				)
			end
		end

		if target or targets then
			validateRebirthTargetType(target, binding.TargetType, "Rebirth render binding " .. binding.Key)
			for targetIndex, targetInstance in ipairs(targets or {}) do
				validateRebirthTargetType(
					targetInstance,
					binding.TargetType,
					"Rebirth render binding " .. binding.Key .. " target " .. tostring(targetIndex)
				)
			end
			resolvedBindings[index] = {
				Config = binding,
				Target = target,
				Targets = targets,
			}
		else
			error("Missing Rebirth render binding target: " .. binding.Key, 2)
		end
	end

	return resolvedBindings
end

function UIRefs.ResolveRebirthPanel(player)
	local config = UIContract.GetConfig("RebirthPanel")
	local playerGui = waitForPlayerGui(player)
	local mainGui = waitForScreenGui(playerGui, config.ScreenGuiName, "Rebirth ScreenGui")
	local panelRoot = requireGuiObject(
		waitForPath(mainGui, config.Paths.PanelRoot, "Rebirth PanelRoot"),
		"Rebirth PanelRoot"
	)
	local refs = {
		PanelRoot = panelRoot,
		CloseButton = requireGuiButton(
			waitForPath(panelRoot, config.Paths.CloseButton, "Rebirth CloseButton"),
			"Rebirth CloseButton"
		),
		RequestButton = requireGuiButton(
			waitForPath(panelRoot, config.Paths.RequestButton, "Rebirth RequestButton"),
			"Rebirth RequestButton"
		),
		TitleText = requireTextObject(
			waitForPath(panelRoot, config.Paths.TitleText, "Rebirth TitleText"),
			"Rebirth TitleText"
		),
		TipText = requireTextObject(
			waitForPath(panelRoot, config.Paths.TipText, "Rebirth TipText"),
			"Rebirth TipText"
		),
	}

	refs.RenderBindings = resolveRebirthRenderBindings(refs, config.RenderBindings)
	return refs
end

-- ===== EggPanel =====

local function resolveEggRewardSlots(mainGui, slotPaths, slotFieldPathSpecs)
	local slots = {}
	for index, path in ipairs(slotPaths) do
		local slotRoot = requireGuiObject(
			waitForPath(mainGui, path, "Egg reward slot " .. tostring(index)),
			"Egg reward slot " .. tostring(index)
		)
		slots[index] = {
			Root = slotRoot,
			Icon = requireImageObject(
				resolvePathSpec({ RewardSlot = slotRoot }, slotFieldPathSpecs.Icon, "Egg reward slot icon"),
				"Egg reward slot icon"
			),
			ChanceText = requireTextObject(
				resolvePathSpec({ RewardSlot = slotRoot }, slotFieldPathSpecs.ChanceText, "Egg reward slot chance text"),
				"Egg reward slot chance text"
			),
			MultiplierText = requireTextObject(
				resolvePathSpec(
					{ RewardSlot = slotRoot },
					slotFieldPathSpecs.MultiplierText,
					"Egg reward slot multiplier text"
				),
				"Egg reward slot multiplier text"
			),
		}
	end

	return slots, #slotPaths
end

local function resolveEggResultTemplate(mainGui, templatePath, templateFieldPathSpecs)
	local templateRoot = requireGuiObject(
		waitForPath(mainGui, templatePath, "Egg result template"),
		"Egg result template"
	)

	return {
		Root = templateRoot,
		Icon = requireImageObject(
			resolvePathSpec({ ResultTemplate = templateRoot }, templateFieldPathSpecs.Icon, "Egg result template icon"),
			"Egg result template icon"
		),
		NameText = requireTextObject(
			resolvePathSpec(
				{ ResultTemplate = templateRoot },
				templateFieldPathSpecs.NameText,
				"Egg result template name text"
			),
			"Egg result template name text"
		),
		RarityText = requireTextObject(
			resolvePathSpec(
				{ ResultTemplate = templateRoot },
				templateFieldPathSpecs.RarityText,
				"Egg result template rarity text"
			),
			"Egg result template rarity text"
		),
	}
end

function UIRefs.ResolveEggPanel(player)
	local config = UIContract.GetConfig("EggPanel")
	local playerGui = waitForPlayerGui(player)
	local mainGui = waitForScreenGui(playerGui, config.ScreenGuiName, "Egg ScreenGui")
	local paths = config.Paths
	local rewardSlots, rewardSlotCount = resolveEggRewardSlots(mainGui, paths.RewardSlots, config.RewardSlotFieldPathSpecs)

	return {
		PanelRoot = requireGuiObject(waitForPath(mainGui, paths.PanelRoot, "Egg PanelRoot"), "Egg PanelRoot"),
		TitleRoot = requireGuiObject(waitForPath(mainGui, paths.TitleRoot, "Egg TitleRoot"), "Egg TitleRoot"),
		CloseButton = requireGuiObject(waitForPath(mainGui, paths.CloseButton, "Egg CloseButton"), "Egg CloseButton"),
		RewardSlots = rewardSlots,
		RewardSlotCount = rewardSlotCount,
		ResultTemplate = resolveEggResultTemplate(mainGui, paths.ResultTemplate, config.ResultTemplateFieldPathSpecs),
		SingleButton = requireGuiObject(
			waitForPath(mainGui, paths.SingleRollButton, "Egg SingleRollButton"),
			"Egg SingleRollButton"
		),
		TripleButton = requireGuiObject(
			waitForPath(mainGui, paths.TripleRollButton, "Egg TripleRollButton"),
			"Egg TripleRollButton"
		),
		AutoButton = requireGuiObject(waitForPath(mainGui, paths.AutoRollButton, "Egg AutoRollButton"), "Egg AutoRollButton"),
	}
end

-- ===== EggRevealPanel =====

local function resolveEggRevealSlots(mainGui, slotPaths, slotFieldPathSpecs)
	local slots = {}
	for index, path in ipairs(slotPaths) do
		local slotRoot = requireGuiObject(
			waitForPath(mainGui, path, "Egg reveal slot " .. tostring(index)),
			"Egg reveal slot " .. tostring(index)
		)
		slots[index] = {
			Root = slotRoot,
			Icon = requireImageObject(
				resolvePathSpec({ RewardSlot = slotRoot }, slotFieldPathSpecs.Icon, "Egg reveal slot icon"),
				"Egg reveal slot icon"
			),
			NameText = requireTextObject(
				resolvePathSpec({ RewardSlot = slotRoot }, slotFieldPathSpecs.NameText, "Egg reveal slot name text"),
				"Egg reveal slot name text"
			),
			RarityText = requireTextObject(
				resolvePathSpec(
					{ RewardSlot = slotRoot },
					slotFieldPathSpecs.RarityText,
					"Egg reveal slot rarity text"
				),
				"Egg reveal slot rarity text"
			),
		}
	end

	return slots, #slotPaths
end

function UIRefs.ResolveEggRevealPanel(player)
	local config = UIContract.GetConfig("EggRevealPanel")
	local playerGui = waitForPlayerGui(player)
	local mainGui = waitForScreenGui(playerGui, config.ScreenGuiName, "Egg reveal ScreenGui")
	local paths = config.Paths
	local rewardSlots, rewardSlotCount = resolveEggRevealSlots(
		mainGui,
		paths.RewardSlots,
		config.RewardSlotFieldPathSpecs
	)

	return {
		PanelRoot = requireGuiObject(waitForPath(mainGui, paths.PanelRoot, "Egg reveal PanelRoot"), "Egg reveal PanelRoot"),
		Background = requireGuiObject(waitForPath(mainGui, paths.Background, "Egg reveal Background"), "Egg reveal Background"),
		RewardSlots = rewardSlots,
		RewardSlotCount = rewardSlotCount,
		ContinueButton = requireGuiObject(
			waitForPath(mainGui, paths.ContinueButton, "Egg reveal ContinueButton"),
			"Egg reveal ContinueButton"
		),
		ContinueText = requireTextObject(
			waitForPath(mainGui, paths.ContinueText, "Egg reveal ContinueText"),
			"Egg reveal ContinueText"
		),
		StopButton = requireGuiObject(
			waitForPath(mainGui, paths.StopButton, "Egg reveal StopButton"),
			"Egg reveal StopButton"
		),
		ContinuePromptText = config.ContinuePromptText,
	}
end

-- ===== PetInventory =====

function UIRefs.ResolvePetInventory(player)
	local config = UIContract.GetConfig("PetInventory")
	local playerGui = waitForPlayerGui(player)
	local hud = waitForScreenGui(playerGui, config.HudScreenGuiName, "Pet inventory HUD ScreenGui")
	local mainGui = waitForScreenGui(playerGui, config.ScreenGuiName, "Pet inventory ScreenGui")
	local paths = config.Paths

	return {
		CardFields = config.PetCardFieldPathSpecs,
		PetButton = requireGuiObject(waitForPath(hud, paths.PetButton, "PetInventory PetButton"), "PetInventory PetButton"),
		PanelRoot = requireGuiObject(
			waitForPath(mainGui, paths.PanelRoot, "PetInventory PanelRoot"),
			"PetInventory PanelRoot"
		),
		CloseButton = requireGuiObject(
			waitForPath(mainGui, paths.CloseButton, "PetInventory CloseButton"),
			"PetInventory CloseButton"
		),
		OwnedContainer = requireGuiObject(
			waitForPath(mainGui, paths.OwnedList, "PetInventory OwnedList"),
			"PetInventory OwnedList"
		),
		OwnedTemplate = requireGuiObject(
			waitForPath(mainGui, paths.OwnedTemplate, "PetInventory OwnedTemplate"),
			"PetInventory OwnedTemplate"
		),
		EquippedContainer = requireGuiObject(
			waitForPath(mainGui, paths.EquippedList, "PetInventory EquippedList"),
			"PetInventory EquippedList"
		),
		EquippedTemplate = requireGuiObject(
			waitForPath(mainGui, paths.EquippedTemplate, "PetInventory EquippedTemplate"),
			"PetInventory EquippedTemplate"
		),
		EquippedText = requireTextObject(
			waitForPath(mainGui, paths.EquippedText, "PetInventory EquippedText"),
			"PetInventory EquippedText"
		),
		NoPet = requireGuiObject(waitForPath(mainGui, paths.NoPet, "PetInventory NoPet"), "PetInventory NoPet"),
		EquipBestButton = requireGuiObject(
			waitForPath(mainGui, paths.EquipBestButton, "PetInventory EquipBestButton"),
			"PetInventory EquipBestButton"
		),
		UnequipAllButton = requireGuiObject(
			waitForPath(mainGui, paths.UnequipAllButton, "PetInventory UnequipAllButton"),
			"PetInventory UnequipAllButton"
		),
		DeleteButton = requireGuiObject(
			waitForPath(mainGui, paths.DeleteButton, "PetInventory DeleteButton"),
			"PetInventory DeleteButton"
		),
	}
end

-- ===== TravelPanel =====

function UIRefs.ResolveTravelPanel(player)
	local config = UIContract.GetConfig("TravelPanel")
	local playerGui = waitForPlayerGui(player)
	local hud = waitForScreenGui(playerGui, config.HudScreenGuiName, "Travel HUD ScreenGui")
	local mainGui = waitForScreenGui(playerGui, config.ScreenGuiName, "Travel ScreenGui")
	local paths = config.Paths
	local destinationButtons = {}

	for key, buttonConfig in pairs(config.DestinationButtons) do
		table.insert(destinationButtons, {
			Key = key,
			DestinationId = buttonConfig.DestinationId,
			Button = requireGuiButton(
				waitForPath(mainGui, buttonConfig.PathSpec, "Travel destination button " .. tostring(key)),
				"Travel destination button " .. tostring(key)
			),
		})
	end

	return {
		OpenButton = requireGuiButton(waitForPath(hud, paths.OpenButton, "Travel OpenButton"), "Travel OpenButton"),
		PanelRoot = requireGuiObject(waitForPath(mainGui, paths.PanelRoot, "Travel PanelRoot"), "Travel PanelRoot"),
		CloseButton = requireGuiButton(
			waitForPath(mainGui, paths.CloseButton, "Travel CloseButton"),
			"Travel CloseButton"
		),
		DestinationButtons = destinationButtons,
	}
end

-- ===== BarbellDisplay =====

function UIRefs.ResolveBarbellDisplay()
	local config = UIContract.GetConfig("BarbellDisplay")
	local sceneEquipment = resolvePathSpec(
		{ Workspace = Workspace },
		config.DisplayRootPathSpec,
		"Barbell display root",
		SCENE_WAIT_SECONDS
	)
	local displayNodes = {}

	for barbellId in pairs(BarbellTheta) do
		local barbellNode = waitForChild(sceneEquipment, barbellId, "Barbell scene node", SCENE_WAIT_SECONDS)
		local displayNode = waitForChild(barbellNode, config.DisplayModelName, "Barbell display model", SCENE_WAIT_SECONDS)
		local fieldPaths = config.FieldPathSpecs
		displayNodes[barbellId] = {
			PowerText = requireTextLabel(
				waitForPath(displayNode, fieldPaths.PowerText, "Barbell power text"),
				"Barbell power text"
			),
			CostText = requireTextLabel(
				waitForPath(displayNode, fieldPaths.CostText, "Barbell cost text"),
				"Barbell cost text"
			),
			Locked = requireGuiObject(
				waitForPath(displayNode, fieldPaths.Locked, "Barbell locked indicator"),
				"Barbell locked indicator"
			),
			Equip = requireGuiObject(
				waitForPath(displayNode, fieldPaths.Equip, "Barbell equip indicator"),
				"Barbell equip indicator"
			),
			Equipped = requireGuiObject(
				waitForPath(displayNode, fieldPaths.Equipped, "Barbell equipped indicator"),
				"Barbell equipped indicator"
			),
		}
	end

	return {
		DisplayNodes = displayNodes,
	}
end

-- ===== AutoAreaDisplay =====

local function warnAutoAreaDisplay(instanceId, fieldName, detail)
	warn(
		("[AutoAreaDisplay] instanceId=%s field=%s %s"):format(
			tostring(instanceId),
			tostring(fieldName),
			tostring(detail)
		)
	)
end

function UIRefs.ResolveAutoAreaDisplayInstance(instanceId, instanceConfig)
	local config = UIContract.GetConfig("AutoAreaDisplay")
	local touch = InstancePath.WaitSpec({ Workspace = Workspace }, instanceConfig.TouchPathSpec, SCENE_WAIT_SECONDS)
	if not touch then
		warnAutoAreaDisplay(instanceId, "Touch", "was not found")
		return nil
	end
	if not touch:IsA("BasePart") then
		warnAutoAreaDisplay(instanceId, "Touch", "must be a BasePart")
		return nil
	end

	local autoAreaInstance = touch.Parent
	if not autoAreaInstance then
		warnAutoAreaDisplay(instanceId, "AutoAreaInstance", "could not be resolved from Touch.Parent")
		return nil
	end

	local displayNode = {}
	for fieldName, pathSpec in pairs(config.FieldPathSpecs) do
		local field = InstancePath.WaitSpec({ AutoAreaInstance = autoAreaInstance }, pathSpec, SCENE_WAIT_SECONDS)
		if not field then
			warnAutoAreaDisplay(
				instanceId,
				fieldName,
				"was not found at " .. InstancePath.Format(pathSpec)
			)
			return nil
		end
		if not field:IsA("TextLabel") then
			warnAutoAreaDisplay(instanceId, fieldName, "must be a TextLabel, got " .. field.ClassName)
			return nil
		end
		displayNode[fieldName] = field
	end

	return displayNode
end

return UIRefs
