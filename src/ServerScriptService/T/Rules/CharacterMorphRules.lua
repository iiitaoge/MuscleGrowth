local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local CharacterMorphTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("CharacterMorphTheta"))
local LevelRules = require(script.Parent.LevelRules)

local CharacterMorphRules = {}

local REQUIRED_R15_PARTS = {
	"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local REQUIRED_ANIMATION_JOINTS = {
	"Root", "Waist", "Neck",
	"LeftShoulder", "LeftElbow", "LeftWrist", "RightShoulder", "RightElbow", "RightWrist",
	"LeftHip", "LeftKnee", "LeftAnkle", "RightHip", "RightKnee", "RightAnkle",
}

local REQUIRED_ANIMATION_JOINT_SET = {}
for _, jointName in ipairs(REQUIRED_ANIMATION_JOINTS) do
	REQUIRED_ANIMATION_JOINT_SET[jointName] = true
end

local function normalizeNonNegativeInteger(value)
	return math.max(0, math.floor(tonumber(value) or 0))
end

local function getJointSummary(motorCount, validMotorCount, animationConstraintCount, enabledConstraintCount)
	return ("%d/%d valid Motor6D, %d/%d enabled AnimationConstraint"):format(
		validMotorCount,
		motorCount,
		enabledConstraintCount,
		animationConstraintCount
	)
end

local function validateAnimationConstraintRig(template, rigName, motorCount, validMotorCount, constraints, enabled)
	local summary = getJointSummary(motorCount, validMotorCount, #constraints, #enabled)
	if #enabled ~= #REQUIRED_ANIMATION_JOINTS then
		return false, ("Character morph template %s has incomplete R15 joints (%s; expected %d enabled AnimationConstraint)"):format(
			rigName,
			summary,
			#REQUIRED_ANIMATION_JOINTS
		)
	end

	local constraintsByName = {}
	local adjacency = {}
	local function connectParts(part0, part1)
		adjacency[part0] = adjacency[part0] or {}
		adjacency[part1] = adjacency[part1] or {}
		table.insert(adjacency[part0], part1)
		table.insert(adjacency[part1], part0)
	end

	for _, constraint in ipairs(enabled) do
		local jointName = constraint.Name
		if not REQUIRED_ANIMATION_JOINT_SET[jointName] then
			return false, ("Character morph template %s has unexpected enabled AnimationConstraint %s (%s)"):format(
				rigName,
				tostring(jointName),
				summary
			)
		end
		if constraintsByName[jointName] then
			return false, ("Character morph template %s has duplicate AnimationConstraint %s (%s)"):format(
				rigName,
				jointName,
				summary
			)
		end
		constraintsByName[jointName] = constraint

		local attachment0 = constraint.Attachment0
		local attachment1 = constraint.Attachment1
		if not attachment0 or not attachment1 then
			return false, ("Character morph template %s AnimationConstraint %s is missing Attachment0 or Attachment1 (%s)"):format(
				rigName,
				jointName,
				summary
			)
		end
		if not attachment0:IsDescendantOf(template) or not attachment1:IsDescendantOf(template) then
			return false, ("Character morph template %s AnimationConstraint %s references an Attachment outside the rig (%s)"):format(
				rigName,
				jointName,
				summary
			)
		end

		local part0 = attachment0.Parent
		local part1 = attachment1.Parent
		if not part0 or not part0:IsA("BasePart") or not part1 or not part1:IsA("BasePart") or part0 == part1 then
			return false, ("Character morph template %s AnimationConstraint %s must connect Attachments on two different BaseParts (%s)"):format(
				rigName,
				jointName,
				summary
			)
		end

		local expectedAttachmentName = jointName .. "RigAttachment"
		if attachment0.Name ~= expectedAttachmentName or attachment1.Name ~= expectedAttachmentName then
			return false, ("Character morph template %s AnimationConstraint %s must connect two %s Attachments (%s)"):format(
				rigName,
				jointName,
				expectedAttachmentName,
				summary
			)
		end
		connectParts(part0, part1)
	end

	for _, jointName in ipairs(REQUIRED_ANIMATION_JOINTS) do
		if not constraintsByName[jointName] then
			return false, ("Character morph template %s is missing AnimationConstraint %s (%s)"):format(
				rigName,
				jointName,
				summary
			)
		end
	end

	local root = template:FindFirstChild("HumanoidRootPart")
	local visited = { [root] = true }
	local queue = { root }
	local queueIndex = 1
	while queueIndex <= #queue do
		local current = queue[queueIndex]
		queueIndex += 1
		for _, neighbor in ipairs(adjacency[current] or {}) do
			if not visited[neighbor] then
				visited[neighbor] = true
				table.insert(queue, neighbor)
			end
		end
	end

	for _, partName in ipairs(REQUIRED_R15_PARTS) do
		local part = template:FindFirstChild(partName)
		if not visited[part] then
			return false, ("Character morph template %s has a disconnected R15 part %s (%s)"):format(
				rigName,
				partName,
				summary
			)
		end
	end

	return true
end

function CharacterMorphRules.ResolveRigIndex(level, maxLevel, rigCount)
	level = math.max(1, math.floor(tonumber(level) or 1))
	maxLevel = math.max(1, math.floor(tonumber(maxLevel) or 1))
	rigCount = math.max(1, math.floor(tonumber(rigCount) or 1))
	return math.clamp(math.ceil(level / maxLevel * rigCount), 1, rigCount)
end

function CharacterMorphRules.ResolveScale(rebirthCount, rigIndex)
	local minScale = math.max(0.1, tonumber(CharacterMorphTheta.MinScale) or 1)
	local maxScale = math.max(minScale, tonumber(CharacterMorphTheta.MaxScale) or minScale)
	return math.clamp(
		minScale
			+ normalizeNonNegativeInteger(rebirthCount) * (tonumber(CharacterMorphTheta.RebirthScaleStep) or 0)
			+ math.max(0, math.floor(tonumber(rigIndex) or 1) - 1) * (tonumber(CharacterMorphTheta.PhaseScaleStep) or 0),
		minScale,
		maxScale
	)
end

function CharacterMorphRules.ResolveAppearance(progressState)
	if type(progressState) ~= "table" then
		return nil, "Player data does not exist"
	end

	local rigNames = CharacterMorphTheta.RigNames
	local rigCount = type(rigNames) == "table" and #rigNames or 0
	if rigCount <= 0 then
		return nil, "CharacterMorphTheta.RigNames must not be empty"
	end

	local rebirthCount = normalizeNonNegativeInteger(progressState.RebirthCount)
	local level = LevelRules.CalculateLevel(progressState.Exp, rebirthCount)
	local maxLevel = math.max(1, LevelRules.GetMaxLevel(rebirthCount))
	local rigIndex = CharacterMorphRules.ResolveRigIndex(level, maxLevel, rigCount)
	local rigName = rigNames[rigIndex]
	if type(rigName) ~= "string" or rigName == "" then
		return nil, "CharacterMorphTheta.RigNames contains an invalid rig name at index " .. tostring(rigIndex)
	end

	return {
		RigIndex = rigIndex,
		RigName = rigName,
		Scale = CharacterMorphRules.ResolveScale(rebirthCount, rigIndex),
		Level = level,
		MaxLevel = maxLevel,
		RebirthCount = rebirthCount,
	}
end

function CharacterMorphRules.ValidateRigTemplate(template, rigName)
	rigName = tostring(rigName or (template and template.Name) or "unknown")
	if not template or not template:IsA("Model") then
		return false, "Character morph template must be a Model: " .. rigName
	end
	if not template.Archivable then
		return false, "Character morph template must be Archivable: " .. rigName
	end
	if not template.PrimaryPart or template.PrimaryPart.Name ~= "HumanoidRootPart" then
		return false, "Character morph template requires HumanoidRootPart as PrimaryPart: " .. rigName
	end

	local humanoid = template:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false, "Character morph template is missing Humanoid: " .. rigName
	end
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return false, "Character morph template must use R15: " .. rigName
	end
	for _, partName in ipairs(REQUIRED_R15_PARTS) do
		local part = template:FindFirstChild(partName)
		if not part or not part:IsA("BasePart") then
			return false, ("Character morph template %s is missing R15 part %s"):format(rigName, partName)
		end
	end

	local motorCount = 0
	local validMotorCount = 0
	local animationConstraints = {}
	local enabledAnimationConstraints = {}
	for _, descendant in ipairs(template:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			motorCount += 1
			if descendant.Part0 and descendant.Part1
				and descendant.Part0:IsDescendantOf(template)
				and descendant.Part1:IsDescendantOf(template)
			then
				validMotorCount += 1
			end
		elseif descendant:IsA("AnimationConstraint") then
			table.insert(animationConstraints, descendant)
			if descendant.Enabled then
				table.insert(enabledAnimationConstraints, descendant)
			end
		end
	end

	local summary = getJointSummary(motorCount, validMotorCount, #animationConstraints, #enabledAnimationConstraints)
	if motorCount > 0 and #enabledAnimationConstraints > 0 then
		return false, ("Character morph template %s mixes Motor6D with enabled AnimationConstraint (%s)"):format(rigName, summary)
	end

	local mode
	if motorCount > 0 then
		if validMotorCount < 14 or validMotorCount ~= motorCount then
			return false, ("Character morph template %s has incomplete traditional R15 joints (%s)"):format(rigName, summary)
		end
		mode = "Motor6D"
	elseif #enabledAnimationConstraints > 0 then
		local valid, validationError = validateAnimationConstraintRig(
			template,
			rigName,
			motorCount,
			validMotorCount,
			animationConstraints,
			enabledAnimationConstraints
		)
		if not valid then
			return false, validationError
		end
		mode = "AnimationConstraint"
	else
		return false, ("Character morph template %s has no supported R15 joints (%s)"):format(rigName, summary)
	end

	local animate = template:FindFirstChild("Animate")
	if not animate or not animate:IsA("LocalScript") or not animate.Enabled then
		return false, "Character morph template requires an enabled Animate LocalScript: " .. rigName
	end

	return true, nil, mode
end

CharacterMorphRules.RequiredR15Parts = table.freeze(REQUIRED_R15_PARTS)

return CharacterMorphRules
