local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetInventoryPanelTheta = require(theta:WaitForChild("PetInventoryPanelTheta"))
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))

local PetInventoryRender = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5
local GENERATED_ATTRIBUTE = "MuscleGrowthGeneratedPetUi"

local DEFAULT_PET_CARD_FIELDS = {
	Icon = "Icon",
	MultiplierText = "MultiplierText",
}

local function waitForPath(root, path)
	local current = root

	for _, childName in ipairs(path) do
		if not current then
			return nil
		end

		current = current:WaitForChild(childName, NODE_WAIT_SECONDS)
		if not current then
			warn("Missing Pet UI node: " .. table.concat(path, "/"))
			return nil
		end
	end

	return current
end

local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

local function getSnapshotCount(snapshots)
	if type(snapshots) ~= "table" then
		return 0
	end

	local count = 0
	for _ in pairs(snapshots) do
		count += 1
	end

	return count
end

local function getMaxEquippedPets()
	return math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
end

local function clearGeneratedChildren(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:GetAttribute(GENERATED_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

local function setVisible(instance, isVisible)
	if instance and instance:IsA("GuiObject") then
		instance.Visible = isVisible == true
	end
end

local function findDescendant(root, childName)
	if not root or type(childName) ~= "string" or childName == "" then
		return nil
	end

	return root:FindFirstChild(childName, true)
end

local function setTextObject(textObject, value)
	if textObject and (textObject:IsA("TextLabel") or textObject:IsA("TextButton")) then
		textObject.Text = value or ""
	end
end

local function setPetIcon(root, fieldName, image)
	local icon = findDescendant(root, fieldName)
	if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
		icon.Image = image or ""
		icon.Visible = type(image) == "string" and image ~= ""
	end
end

local function setPetCard(card, petSnapshot, cardFields)
	if not card then
		return
	end

	local fields = cardFields or DEFAULT_PET_CARD_FIELDS
	local hasPet = type(petSnapshot) == "table" and type(petSnapshot.PetTypeId) == "string"
	card.Visible = hasPet

	setPetIcon(card, fields.Icon, hasPet and petSnapshot.Image or nil)
	setTextObject(findDescendant(card, fields.MultiplierText), hasPet and formatMultiplier(petSnapshot.Multiplier) or "")
end

local function setCardSelected(card, isSelected)
	if not card then
		return
	end

	local stroke = card:FindFirstChild("SelectedStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "SelectedStroke"
		stroke.Thickness = 3
		stroke.Parent = card
	end

	stroke.Color = Color3.fromRGB(255, 230, 70)
	stroke.Enabled = isSelected == true
end

local function connectActivated(root, callback)
	if not root or not callback then
		return
	end

	if root:IsA("GuiButton") then
		root.Activated:Connect(callback)
		return
	end

	local button = root:FindFirstChildWhichIsA("GuiButton", true)
	if button then
		button.Activated:Connect(callback)
		return
	end

	if root:IsA("GuiObject") then
		local hitButton = root:FindFirstChild("InteractionButton")
		if not hitButton then
			hitButton = Instance.new("TextButton")
			hitButton.Name = "InteractionButton"
			hitButton.BackgroundTransparency = 1
			hitButton.BorderSizePixel = 0
			hitButton.Text = ""
			hitButton.Size = UDim2.fromScale(1, 1)
			hitButton.Position = UDim2.fromScale(0, 0)
			hitButton.ZIndex = root.ZIndex + 100
			hitButton.Parent = root
		end

		hitButton.Activated:Connect(callback)
	end
end

local function cloneTemplate(template, parent, name, layoutOrder)
	if not template then
		return nil
	end

	local clone = template:Clone()
	clone.Name = name
	clone.LayoutOrder = layoutOrder
	clone:SetAttribute(GENERATED_ATTRIBUTE, true)
	clone.Visible = true
	clone.Parent = parent

	return clone
end

local function renderOwnedPets(container, template, cardFields, petSnapshots, selectedPetInstanceIds, onPetActivated)
	clearGeneratedChildren(container)
	setVisible(template, false)

	if type(petSnapshots) ~= "table" then
		return
	end

	for index, petSnapshot in ipairs(petSnapshots) do
		local instanceId = tostring(petSnapshot.InstanceId or index)
		local card = cloneTemplate(template, container, "Pet_" .. instanceId, index)
		if card then
			setPetCard(card, petSnapshot, cardFields)
			setCardSelected(card, selectedPetInstanceIds[instanceId] == true)
			connectActivated(card, function()
				onPetActivated(petSnapshot)
			end)
		end
	end
end

local function renderEquippedPets(container, template, cardFields, equippedSnapshots, onSlotActivated)
	clearGeneratedChildren(container)
	setVisible(template, false)

	if type(equippedSnapshots) ~= "table" then
		return 0
	end

	local equippedCount = 0
	for index, petSnapshot in ipairs(equippedSnapshots) do
		if type(petSnapshot) == "table" and type(petSnapshot.PetTypeId) == "string" then
			equippedCount += 1
			local slotIndex = tonumber(petSnapshot.SlotIndex) or index
			local card = cloneTemplate(template, container, "Equipped_" .. tostring(slotIndex), slotIndex)
			if card then
				setPetCard(card, petSnapshot, cardFields)
				connectActivated(card, function()
					onSlotActivated(slotIndex, petSnapshot)
				end)
			end
		end
	end

	return equippedCount
end

local function setEquippedText(equippedText, equippedCount, maxEquippedPets)
	local format = PetInventoryPanelTheta.EquippedTextFormat or "Equipped ( %d/%d Pets)"
	setTextObject(equippedText, string.format(format, equippedCount, maxEquippedPets))
end

local function createNoopView()
	return {
		Refresh = function() end,
		SetOpen = function() end,
		SetActionHandlers = function() end,
		GetPetButton = function()
			return nil
		end,
		GetSelectedPetInstanceIds = function()
			return {}
		end,
	}
end

function PetInventoryRender.Init(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild(PetInventoryPanelTheta.HudScreenGuiName or "HUD", GUI_WAIT_SECONDS)
	local mainGui = playerGui:WaitForChild(PetInventoryPanelTheta.ScreenGuiName or "Main", GUI_WAIT_SECONDS)

	if not hud or not mainGui then
		warn("Pet UI requires HUD and Main ScreenGui.")
		return createNoopView()
	end

	local paths = PetInventoryPanelTheta.Paths or {}
	local cardFields = PetInventoryPanelTheta.PetCardFields or DEFAULT_PET_CARD_FIELDS
	local petButton = waitForPath(hud, paths.PetButton or { "LeftButtons", "Button", "Pet" })
	local petScreen = waitForPath(mainGui, paths.PanelRoot or { "NewPet" })
	local closeButton = waitForPath(mainGui, paths.CloseButton or { "NewPet", "BackPack", "Title", "Close" })
	local ownedContainer = waitForPath(mainGui, paths.OwnedList or { "NewPet", "BackPack", "Main", "Info", "ScrollingFrame" })
	local ownedTemplate = waitForPath(
		mainGui,
		paths.OwnedTemplate or { "NewPet", "BackPack", "Main", "Info", "ScrollingFrame", "BackPackPet" }
	)
	local equippedContainer = waitForPath(mainGui, paths.EquippedList or { "NewPet", "BackPack", "Main", "Info", "PetEquipList" })
	local equippedTemplate = waitForPath(
		mainGui,
		paths.EquippedTemplate or { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedPet" }
	)
	local equippedText = waitForPath(mainGui, paths.EquippedText or { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedText" })
	local noPet = waitForPath(mainGui, paths.NoPet or { "NewPet", "BackPack", "Main", "Info", "NoPet" })
	local equipBestButton = waitForPath(mainGui, paths.EquipBestButton or { "NewPet", "BackPack", "Main", "BottomButton", "EquipBest" })
	local unequipAllButton = waitForPath(mainGui, paths.UnequipAllButton or { "NewPet", "BackPack", "Main", "BottomButton", "UnEquipAll" })
	local deleteButton = waitForPath(mainGui, paths.DeleteButton or { "NewPet", "BackPack", "Main", "BottomButton", "Delete" })

	setVisible(petScreen, false)

	local latestData = nil
	local actionHandlers = {}
	local selectedPetInstanceIds = {}
	local view = {}

	local function handleOwnedPetActivated(petSnapshot)
		if type(petSnapshot) ~= "table" or type(petSnapshot.InstanceId) ~= "string" then
			return
		end

		local instanceId = tostring(petSnapshot.InstanceId)
		selectedPetInstanceIds[instanceId] = selectedPetInstanceIds[instanceId] ~= true
		view.Refresh(latestData)
	end

	local function clearMissingSelections(ownedSnapshots)
		local ownedInstanceIds = {}
		if type(ownedSnapshots) == "table" then
			for _, petSnapshot in ipairs(ownedSnapshots) do
				if type(petSnapshot) == "table" and petSnapshot.InstanceId ~= nil then
					ownedInstanceIds[tostring(petSnapshot.InstanceId)] = true
				end
			end
		end

		for instanceId in pairs(selectedPetInstanceIds) do
			if not ownedInstanceIds[instanceId] then
				selectedPetInstanceIds[instanceId] = nil
			end
		end
	end

	local function handleEquippedPetActivated(slotIndex, petSnapshot)
		if type(petSnapshot) ~= "table" or type(petSnapshot.PetTypeId) ~= "string" then
			return
		end

		if actionHandlers.Unequip then
			actionHandlers.Unequip(slotIndex)
		end
	end

	connectActivated(closeButton, function()
		view.SetOpen(false)
	end)

	connectActivated(petButton, function()
		view.SetOpen(true)
	end)

	connectActivated(equipBestButton, function()
		if actionHandlers.EquipBest then
			actionHandlers.EquipBest()
		end
	end)

	connectActivated(unequipAllButton, function()
		if actionHandlers.UnequipAll then
			actionHandlers.UnequipAll()
		end
	end)

	connectActivated(deleteButton, function()
		if actionHandlers.DeleteSelected then
			actionHandlers.DeleteSelected(view.GetSelectedPetInstanceIds())
		end
	end)

	function view.Refresh(data)
		latestData = data

		if not petScreen then
			return
		end

		local ownedSnapshots = data and data.OwnedPetSnapshots
		local equippedSnapshots = data and data.EquippedPetSnapshots
		local maxEquippedPets = getMaxEquippedPets()
		clearMissingSelections(ownedSnapshots)
		renderOwnedPets(ownedContainer, ownedTemplate, cardFields, ownedSnapshots, selectedPetInstanceIds, handleOwnedPetActivated)
		local equippedCount = renderEquippedPets(
			equippedContainer,
			equippedTemplate,
			cardFields,
			equippedSnapshots,
			handleEquippedPetActivated
		)

		setEquippedText(equippedText, equippedCount, maxEquippedPets)
		setVisible(noPet, getSnapshotCount(ownedSnapshots) == 0)
	end

	function view.SetOpen(isOpen)
		if not petScreen then
			return
		end

		setVisible(petScreen, isOpen == true)
		if petScreen.Visible then
			view.Refresh(latestData)
		end
	end

	function view.SetActionHandlers(nextActionHandlers)
		actionHandlers = type(nextActionHandlers) == "table" and nextActionHandlers or {}
	end

	function view.GetPetButton()
		if petButton and petButton:IsA("GuiButton") then
			return petButton
		end

		return nil
	end

	function view.GetSelectedPetInstanceIds()
		local instanceIds = {}
		for instanceId in pairs(selectedPetInstanceIds) do
			table.insert(instanceIds, instanceId)
		end

		table.sort(instanceIds, function(left, right)
			return (tonumber(left) or math.huge) < (tonumber(right) or math.huge)
		end)

		return instanceIds
	end

	return view
end

return PetInventoryRender
