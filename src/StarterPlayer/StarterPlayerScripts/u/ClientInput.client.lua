-- ClientInput
-- 客户端输入启动器，只负责组装 UI、Remote、场景输入和动作控制器。

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local modules = script.Parent:WaitForChild("ClientInputModules")

local BarbellDisplayController = require(script.Parent.Parent.T.BarbellDisplay.Controller)
local EggPanelController = require(script.Parent.Parent.T.EggPanel.Controller)
local FloatingGainController = require(script.Parent.Parent.T.FloatingGain.Controller)
local HUDController = require(script.Parent.Parent.T.HUD.Controller)
local PetInventoryController = require(script.Parent.Parent.T.PetInventory.Controller)
local PlayerVisualSync = require(script.Parent.Parent.T.PlayerVisualSync)
local RebirthPanelController = require(script.Parent.Parent.T.RebirthPanel.Controller)

local AutoAreaController = require(modules.AutoAreaController)
local EggInteractionController = require(modules.EggInteractionController)
local MovementController = require(modules.MovementController)
local PetActionController = require(modules.PetActionController)
local PetRollController = require(modules.PetRollController)
local RebirthActionController = require(modules.RebirthActionController)
local RemoteClient = require(modules.RemoteClient)
local SceneQuery = require(modules.SceneQuery)
local SnapshotController = require(modules.SnapshotController)
local TrainingGainAttributeController = require(modules.TrainingGainAttributeController)

local remoteClient = RemoteClient.Init()
local hudView = HUDController.Init(player)
local floatingGainView = FloatingGainController.Init(player)
local petInventoryView = PetInventoryController.Init(player)
local rebirthPanelView = RebirthPanelController.Init(player)
local eggPanelView = EggPanelController.Init(player)
local barbellDisplayView = BarbellDisplayController.Init()

local snapshotController = SnapshotController.Init(remoteClient, {
	HUD = hudView,
	FloatingGain = floatingGainView,
	PetInventory = petInventoryView,
	RebirthPanel = rebirthPanelView,
	EggPanel = eggPanelView,
	BarbellDisplay = barbellDisplayView,
})
local sceneQuery = SceneQuery.Init(player)
local autoAreaController = AutoAreaController.Init(remoteClient, sceneQuery)
local movementController = MovementController.Init(player, remoteClient, autoAreaController)
local eggInteractionController = EggInteractionController.Init(sceneQuery, eggPanelView, snapshotController)

PlayerVisualSync.Init()
TrainingGainAttributeController.Init(player, floatingGainView, snapshotController)
RebirthActionController.Init(remoteClient, snapshotController, hudView, rebirthPanelView)
PetActionController.Init(remoteClient, snapshotController, petInventoryView)
PetRollController.Init(remoteClient, snapshotController, eggPanelView, eggInteractionController)

movementController.Bind()
autoAreaController.BindAll()
eggInteractionController.BindAll()

snapshotController.RefreshFromServer()

while task.wait(5) do
	snapshotController.RefreshFromServer()
end
