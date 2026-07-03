-- Paste this entire file into Roblox Studio's Command Bar.
-- It creates ServerStorage.__RojoExportJson. Open that ModuleScript, copy all
-- of its Source text, and paste it into exports/rojo_export.json in this repo.

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local scriptClasses = {
	Script = true,
	LocalScript = true,
	ModuleScript = true,
}

local skipClasses = {
	CoreScript = true,
}

local function getPath(instance)
	local parts = {}
	local current = instance

	while current and current ~= game do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end

	return parts
end

local function getSource(instance)
	local ok, source = pcall(function()
		return instance.Source
	end)

	if ok then
		return source
	end

	warn(("Could not read Source for %s: %s"):format(instance:GetFullName(), tostring(source)))
	return nil
end

local records = {}

for _, instance in ipairs(game:GetDescendants()) do
	if scriptClasses[instance.ClassName] and not skipClasses[instance.ClassName] then
		local source = getSource(instance)

		if source ~= nil then
			table.insert(records, {
				className = instance.ClassName,
				name = instance.Name,
				path = getPath(instance),
				fullName = instance:GetFullName(),
				source = source,
			})
		end
	end
end

table.sort(records, function(left, right)
	return left.fullName < right.fullName
end)

local json = HttpService:JSONEncode({
	generatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	placeName = game.Name,
	scripts = records,
})

local existing = ServerStorage:WaitForChild("__RojoExportJson")
if existing then
	existing:Destroy()
end

local exportScript = Instance.new("ModuleScript")
exportScript.Name = "__RojoExportJson"
exportScript.Source = json
exportScript.Parent = ServerStorage

print(("Exported %d scripts to ServerStorage.__RojoExportJson"):format(#records))
print("Open ServerStorage.__RojoExportJson, copy all Source text, and paste it into exports/rojo_export.json.")
