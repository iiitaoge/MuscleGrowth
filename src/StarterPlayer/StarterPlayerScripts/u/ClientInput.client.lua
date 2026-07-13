-- ClientInput
-- 客户端输入启动器，只负责组装 UI、Remote、场景输入和动作控制器。

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local SceneTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("Scene"):WaitForChild("SceneTheta"))
local dataLoadedAttribute = SceneTheta.Attributes.DataLoaded

while player:GetAttribute(dataLoadedAttribute) ~= true do
	player:GetAttributeChangedSignal(dataLoadedAttribute):Wait()
end

local modules = script.Parent:WaitForChild("ClientInputModules")

local AutoAreaDisplayController = require(script.Parent.Parent.T.AutoAreaDisplay.Controller)
local BarbellDisplayController = require(script.Parent.Parent.T.BarbellDisplay.Controller)
local EggPanelController = require(script.Parent.Parent.T.EggPanel.Controller)
local EggRevealPanelController = require(script.Parent.Parent.T.EggRevealPanel.Controller)
local FloatingGainController = require(script.Parent.Parent.T.FloatingGain.Controller)
local HUDController = require(script.Parent.Parent.T.HUD.Controller)
local PetInventoryController = require(script.Parent.Parent.T.PetInventory.Controller)
local PlayerVisualSync = require(script.Parent.Parent.T.PlayerVisualSync)
local RebirthPanelController = require(script.Parent.Parent.T.RebirthPanel.Controller)
local TravelPanelController = require(script.Parent.Parent.T.TravelPanel.Controller)
local UIContract = require(script.Parent.Parent.T.UIContract)

local AutoWinActionController = require(modules.AutoWinActionController)
local AutoAreaController = require(modules.AutoAreaController)
local EggInteractionController = require(modules.EggInteractionController)
local MovementController = require(modules.MovementController)
local PetActionController = require(modules.PetActionController)
local PetRollController = require(modules.PetRollController)
local PushBallController = require(modules.PushBallController)
local RebirthActionController = require(modules.RebirthActionController)
local RemoteClient = require(modules.RemoteClient)
local SceneQuery = require(modules.SceneQuery)
local SnapshotController = require(modules.SnapshotController)
local TrainingGainAttributeController = require(modules.TrainingGainAttributeController)
local TravelActionController = require(modules.TravelActionController)

UIContract.ValidateAll()

local remoteClient = RemoteClient.Init()	-- 所有向服务器发送的事件
local hudView = HUDController.Init(player)
local floatingGainView = FloatingGainController.Init(player, hudView.GetStrengthGainTarget())
local petInventoryView = PetInventoryController.Init(player)	--初始化宠物视图
local rebirthPanelView = RebirthPanelController.Init(player)
local eggPanelView = EggPanelController.Init(player)
local eggRevealView = EggRevealPanelController.Init(player)
local autoAreaDisplayView = AutoAreaDisplayController.Init()
local barbellDisplayView = BarbellDisplayController.Init()
local travelPanelView = TravelPanelController.Init(player)

local snapshotController = SnapshotController.Init(remoteClient, {
	HUD = hudView,
	FloatingGain = floatingGainView,
	PetInventory = petInventoryView,
	RebirthPanel = rebirthPanelView,
	EggPanel = eggPanelView,
	AutoAreaDisplay = autoAreaDisplayView,
	BarbellDisplay = barbellDisplayView,
})
local sceneQuery = SceneQuery.Init(player)
local autoAreaController = AutoAreaController.Init(remoteClient, sceneQuery)
local movementController = MovementController.Init(player, remoteClient, autoAreaController)
local eggInteractionController = EggInteractionController.Init(sceneQuery, eggPanelView, snapshotController)
local pushBallController = PushBallController.Init(player, remoteClient, movementController)

PlayerVisualSync.Init()
AutoWinActionController.Init(player, snapshotController, hudView)
TrainingGainAttributeController.Init(player, floatingGainView, snapshotController)
RebirthActionController.Init(snapshotController, hudView, rebirthPanelView)
PetActionController.Init(snapshotController, petInventoryView)	-- 宠物的实际动作：视图接口和事件接口
PetRollController.Init(snapshotController, eggPanelView, eggInteractionController, eggRevealView)
TravelActionController.Init(snapshotController, travelPanelView)

movementController.Bind()
autoAreaController.BindAll()
eggInteractionController.BindAll()
pushBallController.Bind()

snapshotController.RefreshFromServer()

while task.wait(5) do
	snapshotController.RefreshFromServer()
end
