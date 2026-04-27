--!strict
--!optimize 2

local Loader = {}

local function loadRecursive(parent: Instance, out: { any })
	local children = parent:GetChildren()
	table.sort(children, function(a, b)
		return a.Name < b.Name
	end)
	for _, child in children do
		if child:IsA("ModuleScript") then
			table.insert(out, (require)(child) :: any)
		elseif child:IsA("Folder") then
			loadRecursive(child, out)
		end
	end
end

function Loader.loadAll<T>(folder: Instance): { T }
	assert(typeof(folder) == "Instance", "[Nexus] Loader expects an Instance; got " .. typeof(folder))
	local out: { T } = {}
	loadRecursive(folder, (out :: any) :: { any })
	return out
end

return Loader
