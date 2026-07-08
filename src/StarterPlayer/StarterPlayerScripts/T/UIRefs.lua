-- UIRefs
-- 客户端运行时 UI/场景实例解析总入口。配置结构由 UIContract 先验证，这里只解析真实实例。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))
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

local function waitForPath(root, path, context, timeout)
	local current = root
	for _, childName in ipairs(path) do
		current = waitForChild(current, childName, context, timeout)
	end

	return current
end

local function findPath(root, path)
	local current = root
	for _, childName in ipairs(path) do
		current = current and current:FindFirstChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

local function findRequiredDescendant(root, childName, context)
	local descendant = root:FindFirstChild(childName, true)
	if not descendant then
		error(context .. " '" .. childName .. "' was not found under " .. root:GetFullName() .. ".", 2)
	end

	return descendant
end

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
	return instance
end

local function requireTextLabel(instance, context)
	assert(instance:IsA("TextLabel"), context .. " must be a TextLabel.")
	return instance
end

local function requireTextObject(instance, context)
	assert(instance:IsA("TextLabel") or instance:IsA("TextButton"), context .. " must be a text object.")
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
	}
end

-- ===== FloatingGain =====

function UIRefs.ResolveFloatingGain(player)
	local config = UIContract.GetConfig("FloatingGain")
	local playerGui = waitForPlayerGui(player)
	local hud = waitForScreenGui(playerGui, config.ScreenGuiName, "Floating gain HUD ScreenGui")
	local strengthTemplate = requireGuiObject(
		waitForChild(hud, config.Templates.StrengthGain, "Floating gain strength template"),
		"Floating gain strength template"
	)
	local trophyTemplate = requireGuiObject(
		waitForChild(hud, config.Templates.TrophyGain, "Floating gain trophy template"),
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

local function findFirstText(root, childName)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == childName and descendant:IsA("TextLabel") then
			return descendant
		end
	end

	return nil
end

local function requireFirstText(root, names, context)
	for _, childName in ipairs(names) do
		local textObject = findFirstText(root, childName)
		if textObject then
			return textObject
		end
	end

	error(context .. " was not found under " .. root:GetFullName() .. ".", 2)
end

local function findActionButton(root, actionButtonName)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") and descendant.Name == actionButtonName then
			return descendant
		end
	end

	error("Rebirth action button '" .. actionButtonName .. "' was not found under " .. root:GetFullName() .. ".", 2)
end

local function resolveOptionalPath(root, path)
	return findPath(root, path)
end

local function resolveRequiredPath(root, path, context)
	return waitForPath(root, path, context)
end

local function resolveRebirthBindingTarget(refs, binding)
	if binding.Ref then
		local target = refs[binding.Ref]
		assert(target, "Missing Rebirth render binding ref: " .. binding.Ref)
		return target
	end

	if binding.Path then
		if binding.Optional == true then
			return resolveOptionalPath(refs.PanelRoot, binding.Path)
		end
		return resolveRequiredPath(refs.PanelRoot, binding.Path, "Rebirth render binding " .. binding.Key)
	end

	if binding.RootPath then
		if binding.Optional == true then
			return resolveOptionalPath(refs.PanelRoot, binding.RootPath)
		end
		return resolveRequiredPath(refs.PanelRoot, binding.RootPath, "Rebirth render binding " .. binding.Key)
	end

	return refs.PanelRoot
end

local function resolveRebirthRenderBindings(refs, bindings)
	local resolvedBindings = {}
	for index, binding in ipairs(bindings) do
		local target = resolveRebirthBindingTarget(refs, binding)
		if target or binding.Optional == true then
			resolvedBindings[index] = {
				Config = binding,
				Target = target,
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
	local nodes = config.Nodes
	local refs = {
		PanelRoot = panelRoot,
		CloseButton = findActionButton(panelRoot, nodes.CloseButtonName),
		RequestButton = findActionButton(panelRoot, nodes.ActionButtonName),
		TitleText = requireFirstText(panelRoot, { nodes.TitleTextName }, "Rebirth title text"),
		TipText = requireFirstText(panelRoot, { nodes.TipTextName, nodes.FallbackTipTextName }, "Rebirth tip text"),
	}

	refs.RenderBindings = resolveRebirthRenderBindings(refs, config.RenderBindings)
	return refs
end

-- ===== EggPanel =====

local function resolveEggRewardSlots(mainGui, slotPaths, slotFields)
	local slots = {}
	for index, path in ipairs(slotPaths) do
		local slotRoot = requireGuiObject(
			waitForPath(mainGui, path, "Egg reward slot " .. tostring(index)),
			"Egg reward slot " .. tostring(index)
		)
		slots[index] = {
			Root = slotRoot,
			Icon = requireImageObject(
				findRequiredDescendant(slotRoot, slotFields.Icon, "Egg reward slot icon"),
				"Egg reward slot icon"
			),
			ChanceText = requireTextObject(
				findRequiredDescendant(slotRoot, slotFields.ChanceText, "Egg reward slot chance text"),
				"Egg reward slot chance text"
			),
			MultiplierText = requireTextObject(
				findRequiredDescendant(slotRoot, slotFields.MultiplierText, "Egg reward slot multiplier text"),
				"Egg reward slot multiplier text"
			),
		}
	end

	return slots, #slotPaths
end

local function resolveEggResultTemplate(mainGui, templatePath, templateFields)
	local templateRoot = requireGuiObject(
		waitForPath(mainGui, templatePath, "Egg result template"),
		"Egg result template"
	)

	return {
		Root = templateRoot,
		Icon = requireImageObject(
			findRequiredDescendant(templateRoot, templateFields.Icon, "Egg result template icon"),
			"Egg result template icon"
		),
		NameText = requireTextObject(
			findRequiredDescendant(templateRoot, templateFields.NameText, "Egg result template name text"),
			"Egg result template name text"
		),
		RarityText = requireTextObject(
			findRequiredDescendant(templateRoot, templateFields.RarityText, "Egg result template rarity text"),
			"Egg result template rarity text"
		),
	}
end

function UIRefs.ResolveEggPanel(player)
	local config = UIContract.GetConfig("EggPanel")
	local playerGui = waitForPlayerGui(player)
	local mainGui = waitForScreenGui(playerGui, config.ScreenGuiName, "Egg ScreenGui")
	local paths = config.Paths
	local rewardSlots, rewardSlotCount = resolveEggRewardSlots(mainGui, paths.RewardSlots, config.RewardSlotFields)

	return {
		PanelRoot = requireGuiObject(waitForPath(mainGui, paths.PanelRoot, "Egg PanelRoot"), "Egg PanelRoot"),
		TitleRoot = requireGuiObject(waitForPath(mainGui, paths.TitleRoot, "Egg TitleRoot"), "Egg TitleRoot"),
		CloseButton = requireGuiObject(waitForPath(mainGui, paths.CloseButton, "Egg CloseButton"), "Egg CloseButton"),
		RewardSlots = rewardSlots,
		RewardSlotCount = rewardSlotCount,
		ResultTemplate = resolveEggResultTemplate(mainGui, paths.ResultTemplate, config.ResultTemplateFields),
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

-- ===== PetInventory =====

function UIRefs.ResolvePetInventory(player)
	local config = UIContract.GetConfig("PetInventory")
	local playerGui = waitForPlayerGui(player)
	local hud = waitForScreenGui(playerGui, config.HudScreenGuiName, "Pet inventory HUD ScreenGui")
	local mainGui = waitForScreenGui(playerGui, config.ScreenGuiName, "Pet inventory ScreenGui")
	local paths = config.Paths

	return {
		CardFields = config.PetCardFields,
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
				waitForPath(mainGui, buttonConfig.Path, "Travel destination button " .. tostring(key)),
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
	local worldRoot = waitForChild(Workspace, config.WorkspaceRootName, "Workspace root", SCENE_WAIT_SECONDS)
	local sceneEquipment =
		waitForChild(worldRoot, config.SceneEquipmentRootName, "Barbell scene equipment", SCENE_WAIT_SECONDS)
	local displayNodes = {}

	for barbellId in pairs(BarbellTheta) do
		local barbellNode = waitForChild(sceneEquipment, barbellId, "Barbell scene node", SCENE_WAIT_SECONDS)
		local displayNode = waitForChild(barbellNode, config.DisplayModelName, "Barbell display model", SCENE_WAIT_SECONDS)
		local fieldPaths = config.FieldPaths
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

return UIRefs
