local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("BarbellTheta"))
local BodyQualityTheta = require(theta:WaitForChild("BodyQualityTheta"))
local LevelTheta = require(theta:WaitForChild("LevelTheta"))
local PetTheta = require(theta:WaitForChild("PetTheta"))
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))
local RebirthTheta = require(theta:WaitForChild("RebirthTheta"))

local ProgressionRules = {}	--创建模块表。后面所有对外函数都会挂到这个表上。

-- 当前测试阶段的基础收益常量。等它变成正式训练配置域时，再迁移到 theta。
local BASE_STRENGTH_GAIN = 1
local BASE_EXP_GAIN = 50

local requiredExpByLevel = {}	--创建一个查询表，用来把等级快速映射到所需经验
local maxConfiguredLevel = 1	--记录配置表里最大的等级
local lastConfiguredRebirthCount = 0	--记录 RebirthTheta 里配置过的最大重生次数

-- 把等级经验表转换成快速查询表
for _, levelInfo in ipairs(LevelTheta.RequiredExp or {}) do
	local level = tonumber(levelInfo.Level)
	local requiredExp = tonumber(levelInfo.Exp)

	if level and requiredExp then
		requiredExpByLevel[level] = requiredExp

		if level > maxConfiguredLevel then	--更新最大等级
			maxConfiguredLevel = level
		end
	end
end

-- 遍历 RebirthTheta 配置表，找出配置过的最大重生次数
for rebirthCount in pairs(RebirthTheta) do
	if type(rebirthCount) == "number" and rebirthCount > lastConfiguredRebirthCount then
		lastConfiguredRebirthCount = rebirthCount
	end
end

-- 规范化数字输入
local function normalizeRebirthCount(rebirthCount)
	return math.max(0, math.floor(tonumber(rebirthCount) or 0))
end

-- 规范化等级输入
local function normalizeLevel(level)
	return math.max(1, math.floor(tonumber(level) or 1))
end

-- 规范化倍率输入
local function normalizeMultiplier(multiplier)
	multiplier = tonumber(multiplier) or 1
	return math.max(multiplier, 0)
end

-- 规范化基础收益。基础收益不是倍率，可以为 0，但不能为负数。
local function normalizeBaseGain(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil then
		return fallback
	end

	return math.max(numberValue, 0)
end

-- 解析重生规则，输出通用训练倍率和最大等级。
function ProgressionRules.ResolveRebirthRule(rebirthCount)
	rebirthCount = normalizeRebirthCount(rebirthCount)

	local rule = RebirthTheta[rebirthCount]
	if rule then
		return rule
	end

	-- 没有配置，就取上一条配置
	local lastRule = RebirthTheta[lastConfiguredRebirthCount]
	if not lastRule then
		return {
			Multiplier = 1,
			MaxLevel = LevelTheta.DefaultMaxLevel,
		}
	end

	-- 如果后续没配置，按照公式继续增长
	local extraRebirths = rebirthCount - lastConfiguredRebirthCount
	return {
		Multiplier = lastRule.Multiplier * (2 ^ extraRebirths),
		MaxLevel = lastRule.MaxLevel + 20 * extraRebirths,
	}
end

-- 获取重生通用倍率。力量和经验都使用这一个倍率。
function ProgressionRules.GetRebirthMultiplier(rebirthCount)
	local rebirthRule = ProgressionRules.ResolveRebirthRule(rebirthCount)

	return normalizeMultiplier(rebirthRule and rebirthRule.Multiplier or 1)
end

-- 获取当前杠铃力量倍率，用于训练计算和 UI 快照。
function ProgressionRules.GetBarbellMultiplier(currentBarbellId)
	local barbell = BarbellTheta[currentBarbellId]

	return normalizeMultiplier(barbell and barbell.StrengthMultiplier or 1)
end

-- 获取当前杠铃的奖杯需求，用于快照和服务端切换校验。
function ProgressionRules.GetBarbellRequiredTrophies(currentBarbellId)
	local barbell = BarbellTheta[currentBarbellId]

	return math.max(0, tonumber(barbell and barbell.RequiredTrophies) or 0)
end

-- 获取当前宠物通用训练倍率。当前设计为同时影响力量和经验。
function ProgressionRules.GetPetTypeMultiplier(petTypeId)
	local pet = PetTheta[petTypeId]

	return normalizeMultiplier(pet and pet.Multiplier or 1)
end

local function getMaxEquippedPets()
	return math.max(0, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 0))
end

local function getEmptyPetSlot()
	return PetSystemTheta.EmptyPetSlot == nil and 0 or PetSystemTheta.EmptyPetSlot
end

local function isEmptyPetSlot(value)
	local emptySlot = getEmptyPetSlot()
	return value == nil or value == emptySlot or tostring(value) == tostring(emptySlot)
end

local function getPetInstance(progressState, petInstanceId)
	if not progressState or type(progressState.OwnedPets) ~= "table" then
		return nil
	end

	return progressState.OwnedPets[tostring(petInstanceId)]
end

function ProgressionRules.GetPetTypeSnapshot(petTypeId)
	local petConfig = PetTheta[petTypeId]
	if type(petConfig) ~= "table" then
		return nil
	end

	return {
		PetTypeId = petTypeId,
		DisplayName = petConfig.DisplayName or petTypeId,
		Rarity = petConfig.Rarity or "Common",
		Multiplier = normalizeMultiplier(petConfig.Multiplier),
		RollWeight = math.max(0, tonumber(petConfig.RollWeight) or 0),
	}
end

function ProgressionRules.GetOwnedPetSnapshots(progressState)
	local ownedPetSnapshots = {}
	local ownedPets = progressState and progressState.OwnedPets
	if type(ownedPets) ~= "table" then
		return ownedPetSnapshots
	end

	for instanceId, petInstance in pairs(ownedPets) do
		if type(petInstance) == "table" and type(petInstance.PetTypeId) == "string" then
			local petSnapshot = ProgressionRules.GetPetTypeSnapshot(petInstance.PetTypeId)
			if petSnapshot then
				petSnapshot.InstanceId = tostring(petInstance.InstanceId or instanceId)
				table.insert(ownedPetSnapshots, petSnapshot)
			end
		end
	end

	table.sort(ownedPetSnapshots, function(left, right)
		return (tonumber(left.InstanceId) or math.huge) < (tonumber(right.InstanceId) or math.huge)
	end)

	return ownedPetSnapshots
end

function ProgressionRules.GetEquippedPetSnapshots(progressState)
	local equippedPetSnapshots = {}
	local equippedSlots = progressState and progressState.EquippedPetInstanceIds
	local emptySlot = getEmptyPetSlot()
	local seenInstanceIds = {}

	for slotIndex = 1, getMaxEquippedPets() do
		local petInstanceId = type(equippedSlots) == "table" and equippedSlots[slotIndex] or emptySlot
		local petSnapshot = {
			SlotIndex = slotIndex,
			InstanceId = emptySlot,
		}

		if not isEmptyPetSlot(petInstanceId) then
			local normalizedInstanceId = tostring(petInstanceId)
			local petInstance = getPetInstance(progressState, normalizedInstanceId)
			local typeSnapshot = petInstance
				and not seenInstanceIds[normalizedInstanceId]
				and ProgressionRules.GetPetTypeSnapshot(petInstance.PetTypeId)

			if typeSnapshot then
				seenInstanceIds[normalizedInstanceId] = true
				typeSnapshot.SlotIndex = slotIndex
				typeSnapshot.InstanceId = normalizedInstanceId
				petSnapshot = typeSnapshot
			end
		end

		table.insert(equippedPetSnapshots, petSnapshot)
	end

	return equippedPetSnapshots
end

function ProgressionRules.GetEquippedPetMultiplier(progressState)
	local equippedSlots = progressState and progressState.EquippedPetInstanceIds
	if type(equippedSlots) ~= "table" then
		return 1
	end

	local seenInstanceIds = {}
	local totalMultiplier = 0

	for slotIndex = 1, getMaxEquippedPets() do
		local petInstanceId = equippedSlots[slotIndex]
		if not isEmptyPetSlot(petInstanceId) then
			local normalizedInstanceId = tostring(petInstanceId)
			local petInstance = getPetInstance(progressState, normalizedInstanceId)
			if petInstance and not seenInstanceIds[normalizedInstanceId] then
				local petConfig = PetTheta[petInstance.PetTypeId]
				if petConfig then
					totalMultiplier += normalizeMultiplier(petConfig.Multiplier)
					seenInstanceIds[normalizedInstanceId] = true
				end
			end
		end
	end

	if totalMultiplier <= 0 then
		return 1
	end

	return totalMultiplier
end

-- 获取升级所需的经验值
function ProgressionRules.GetRequiredExp(level)
	level = normalizeLevel(level)

	-- 先尝试从配置表中获取经验值，有就直接返回
	local configuredExp = requiredExpByLevel[level]
	if configuredExp then
		return configuredExp
	end

	-- 拿最后一个配置的经验
	local lastConfiguredExp = requiredExpByLevel[maxConfiguredLevel] or 0
	local extraLevels = level - maxConfiguredLevel

	-- 公式兜底
	return lastConfiguredExp + extraLevels * extraLevels * 1000
end

-- 获取最大等级
function ProgressionRules.GetMaxLevel(rebirthCount)
	local rebirthRule = ProgressionRules.ResolveRebirthRule(rebirthCount)
	if rebirthRule and rebirthRule.MaxLevel then	--存在且最大等级存在，获取
		return rebirthRule.MaxLevel
	end

	-- 兜底，获取默认最大等级
	return LevelTheta.DefaultMaxLevel
end

-- 获取最大经验值
function ProgressionRules.GetMaxExp(rebirthCount)
	return ProgressionRules.GetRequiredExp(ProgressionRules.GetMaxLevel(rebirthCount))
end

-- 对外函数：根据经验计算等级
function ProgressionRules.CalculateLevel(exp, rebirthCount)
	exp = math.max(0, tonumber(exp) or 0)

	local maxLevel = ProgressionRules.GetMaxLevel(rebirthCount)	-- 获取最大等级，防止计算超过最大等级
	local level = 1

	for currentLevel = 1, maxLevel do
		if exp >= ProgressionRules.GetRequiredExp(currentLevel) then
			level = currentLevel
		else
			break
		end
	end

	return level
end
-- 对外函数：限制经验值在合理范围内
function ProgressionRules.ClampExp(exp, rebirthCount)
	local maxExp = ProgressionRules.GetMaxExp(rebirthCount)
	return math.max(0, math.min(tonumber(exp) or 0, maxExp))
end

-- 对外函数：判断玩家是否可以重生
function ProgressionRules.CanRebirth(progressState)
	if not progressState then
		return false
	end
	-- 玩家若达到了最大等级，则可以重生
	return ProgressionRules.CalculateLevel(progressState.Exp, progressState.RebirthCount)
		>= ProgressionRules.GetMaxLevel(progressState.RebirthCount)
end

-- 杠铃目前只影响力量倍率。以后杠铃如果也影响经验，在这里扩展即可。
local function resolveBarbellMultipliers(progressState)
	return ProgressionRules.GetBarbellMultiplier(progressState and progressState.CurrentBarbellId), 1
end

-- 体质目前只影响经验倍率。以后体质如果也影响力量，在这里扩展即可。
local function resolveBodyQualityMultipliers(progressState)
	local bodyQuality = progressState and BodyQualityTheta[progressState.BodyQuality]

	return 1, bodyQuality and bodyQuality.ExpMultiplier or 1
end

-- 宠物使用同一个通用倍率，同时影响力量和经验。
local function resolvePetMultipliers(progressState)
	local multiplier = ProgressionRules.GetEquippedPetMultiplier(progressState)

	return multiplier, multiplier
end

-- 重生使用同一个通用倍率，同时影响力量和经验。
local function resolveRebirthMultipliers(progressState)
	local multiplier = ProgressionRules.GetRebirthMultiplier(progressState and progressState.RebirthCount or 0)

	return multiplier, multiplier
end

-- 自动区同时影响力量和经验。未进入自动区时，上层传入 1。
local function resolveAutoAreaMultipliers(autoAreaMultiplier)
	local multiplier = normalizeMultiplier(autoAreaMultiplier)

	return multiplier, multiplier
end

-- 把一个倍率来源乘进总倍率。所有倍率入口都经过这里，避免未来公式散落。
local function applyTrainingMultiplier(totalStrengthMultiplier, totalExpMultiplier, strengthMultiplier, expMultiplier)
	return totalStrengthMultiplier * normalizeMultiplier(strengthMultiplier),
		totalExpMultiplier * normalizeMultiplier(expMultiplier)
end

-- 聚合所有训练倍率来源。以后新增宠物/VIP/药水/活动倍率，只在这里加一行 apply。
local function resolveTrainingMultipliers(progressState, autoAreaMultiplier)
	local strengthMultiplier = 1
	local expMultiplier = 1

	local function apply(strengthSourceMultiplier, expSourceMultiplier)
		strengthMultiplier, expMultiplier = applyTrainingMultiplier(
			strengthMultiplier,
			expMultiplier,
			strengthSourceMultiplier,
			expSourceMultiplier
		)
	end

	apply(resolveBarbellMultipliers(progressState))
	apply(resolveBodyQualityMultipliers(progressState))
	apply(resolvePetMultipliers(progressState))
	apply(resolveRebirthMultipliers(progressState))
	apply(resolveAutoAreaMultipliers(autoAreaMultiplier))

	return strengthMultiplier, expMultiplier
end

-- 对外函数：计算一次训练收益值
function ProgressionRules.CalculateTrainingGainValues(progressState, autoAreaMultiplier)
	local baseStrengthGain = normalizeBaseGain(BASE_STRENGTH_GAIN, 1)
	local baseExpGain = normalizeBaseGain(BASE_EXP_GAIN, 50)
	local strengthMultiplier, expMultiplier = resolveTrainingMultipliers(progressState, autoAreaMultiplier)

	return baseStrengthGain * strengthMultiplier,
		baseExpGain * expMultiplier
end

return ProgressionRules
