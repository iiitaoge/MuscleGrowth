local PetInventoryRender = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5
local GENERATED_ATTRIBUTE = "MuscleGrowthGeneratedPetUi"

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

local function hideTemplateChildren(container)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and not child:GetAttribute(GENERATED_ATTRIBUTE) then
			child.Visible = false
		end
	end
end

local function setTextByName(root, childName, value)
	if not root then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == childName and descendant:IsA("TextLabel") then
			descendant.Text = value
		end
	end
end

local function setVisibleByName(root, childName, isVisible)
	if not root then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == childName and descendant:IsA("GuiObject") then
			descendant.Visible = isVisible
		end
	end
end

local function setPetIcon(root, image)
	local icon = root and root:FindFirstChild("Icon", true)
	if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
		icon.Image = image or ""
		icon.Visible = type(image) == "string" and image ~= ""
	end
end

local function setPetCard(card, petSnapshot)
	local hasPet = type(petSnapshot) == "table" and type(petSnapshot.PetTypeId) == "string"
	card.Visible = true

	setPetIcon(card, hasPet and petSnapshot.Image or nil)
	setTextByName(card, "Value", hasPet and formatMultiplier(petSnapshot.Multiplier) or "")
	setVisibleByName(card, "num", false)
end

local function setCardSelected(card, isSelected)
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

local function renderOwnedPets(container, template, petSnapshots, selectedPetInstanceIds, onPetActivated)
	clearGeneratedChildren(container)
	hideTemplateChildren(container)

	if template then
		template.Visible = false
	end

	if type(petSnapshots) ~= "table" then
		return
	end

	for index, petSnapshot in ipairs(petSnapshots) do
		local instanceId = tostring(petSnapshot.InstanceId or index)
		local card = cloneTemplate(template, container, "Pet_" .. instanceId, index)
		if card then
			setPetCard(card, petSnapshot)
			setCardSelected(card, selectedPetInstanceIds[instanceId] == true)
			connectActivated(card, function()
				onPetActivated(petSnapshot)
			end)
		end
	end
end

local function getEquippedSnapshotBySlot(equippedSnapshots)
	local snapshotBySlot = {}
	if type(equippedSnapshots) ~= "table" then
		return snapshotBySlot
	end

	for _, petSnapshot in ipairs(equippedSnapshots) do
		local slotIndex = tonumber(petSnapshot.SlotIndex)
		if slotIndex then
			snapshotBySlot[slotIndex] = petSnapshot
		end
	end

	return snapshotBySlot
end

local function renderEquippedPets(container, template, equippedSnapshots, onSlotActivated)
	clearGeneratedChildren(container)
	hideTemplateChildren(container)

	if template then
		template.Visible = false
	end

	local snapshotBySlot = getEquippedSnapshotBySlot(equippedSnapshots)
	for slotIndex = 1, 3 do
		local card = cloneTemplate(template, container, "Equipped_" .. tostring(slotIndex), slotIndex)
		if card then
			setPetCard(card, snapshotBySlot[slotIndex])
			connectActivated(card, function()
				onSlotActivated(slotIndex, snapshotBySlot[slotIndex])
			end)
		end
	end
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
	local hud = playerGui:WaitForChild("HUD", GUI_WAIT_SECONDS)
	local mainGui = playerGui:WaitForChild("Main", GUI_WAIT_SECONDS)

	if not hud or not mainGui then
		warn("Pet UI requires HUD and Main ScreenGui.")
		return createNoopView()
	end

	local petButton = waitForPath(hud, { "LeftButtons", "Button", "Pet" })
	local petScreen = waitForPath(mainGui, { "NewPet" })
	local closeButton = petScreen and waitForPath(petScreen, { "BackPack", "Title", "Close" })
	local ownedContainer = petScreen and waitForPath(petScreen, { "BackPack", "Main", "Info", "ScrollingFrame" })
	local equippedContainer = petScreen and waitForPath(petScreen, { "BackPack", "Main", "Info", "PetEquipList", "Pet" })
	local noPet = petScreen and waitForPath(petScreen, { "BackPack", "Main", "Info", "NoPet" })
	local ownedTemplate = ownedContainer and ownedContainer:FindFirstChild("1")
	local equippedTemplate = equippedContainer and equippedContainer:FindFirstChild("1")
	local equipBestButton = petScreen and petScreen:FindFirstChild("EquipBest", true)
	local unequipAllButton = petScreen
		and (petScreen:FindFirstChild("UnEquipAll", true) or petScreen:FindFirstChild("UnequipAll", true))
	local deleteButton = petScreen and petScreen:FindFirstChild("Delete", true)

	if petScreen then
		petScreen.Visible = false
	end

	if closeButton and closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(function()
			if petScreen then
				petScreen.Visible = false
			end
		end)
	end

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

	local function handleEquippedSlotActivated(slotIndex, petSnapshot)
		if type(petSnapshot) ~= "table" or type(petSnapshot.PetTypeId) ~= "string" then
			return
		end

		if actionHandlers.Unequip then
			actionHandlers.Unequip(slotIndex)
		end
	end

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
		clearMissingSelections(ownedSnapshots)
		renderOwnedPets(ownedContainer, ownedTemplate, ownedSnapshots, selectedPetInstanceIds, handleOwnedPetActivated)
		renderEquippedPets(equippedContainer, equippedTemplate, data and data.EquippedPetSnapshots, handleEquippedSlotActivated)

		if noPet and noPet:IsA("GuiObject") then
			noPet.Visible = getSnapshotCount(ownedSnapshots) == 0
		end
	end

	function view.SetOpen(isOpen)
		if not petScreen then
			return
		end

		petScreen.Visible = isOpen == true
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
