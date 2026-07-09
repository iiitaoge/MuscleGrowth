-- 事件配置
local RemoteTheta = {
	-- 移动事件
	MoveStart = {
		Name = "MoveStart",
		ClassName = "RemoteEvent",
	},
	MoveStop = {
		Name = "MoveStop",
		ClassName = "RemoteEvent",
	},
	-- 自动区事件
	OnAutoArea = {
		Name = "OnAutoArea",
		ClassName = "RemoteEvent",
	},
	LeaveAutoArea = {
		Name = "LeaveAutoArea",
		ClassName = "RemoteEvent",
	},
	-- 客户端获取数据的事件
	GetData = {
		Name = "GetData",
		ClassName = "RemoteFunction",
	},
	RequestRebirth = {
		Name = "RequestRebirth",
		ClassName = "RemoteFunction",
	},
	-- 装备杠铃事件
	RequestBarbellEquip = {
		Name = "RequestBarbellEquip",
		ClassName = "RemoteFunction",
	},
	-- 宠物事件
	RequestPetEquip = {
		Name = "RequestPetEquip",
		ClassName = "RemoteFunction",
	},
	RequestPetUnequip = {
		Name = "RequestPetUnequip",
		ClassName = "RemoteFunction",
	},
	RequestPetRoll = {
		Name = "RequestPetRoll",
		ClassName = "RemoteFunction",
	},
	RequestPetDelete = {
		Name = "RequestPetDelete",
		ClassName = "RemoteFunction",
	},
	-- 传送事件
	RequestTravelDestination = {
		Name = "RequestTravelDestination",
		ClassName = "RemoteFunction",
	},
	-- 推球事件
	RequestStartPushBall = {
		Name = "RequestStartPushBall",
		ClassName = "RemoteFunction",
	},
	RequestStopPushBall = {
		Name = "RequestStopPushBall",
		ClassName = "RemoteFunction",
	},
	PushBallLateralInput = {
		Name = "PushBallLateralInput",
		ClassName = "RemoteEvent",
	},
	PushBallPrepareTeleport = {
		Name = "PushBallPrepareTeleport",
		ClassName = "RemoteFunction",
	},
}

return RemoteTheta
