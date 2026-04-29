local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")

local destroyingPickaxe = RepStorage.Events.DestroyingPickaxe
local equipItemEvent = RepStorage.Events.EquipItem


local pickaxeFolder = RepStorage.Pickaxes

local pickLocalScript = script.PickaxeLocal

Players.PlayerAdded:Connect(function(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local backpack = player:WaitForChild("Backpack")
	
	local inventory = player:WaitForChild("Inventory")
	local EquippedPickaxe = inventory:WaitForChild("EquippedPickaxe")
	
	local previousPickaxe = EquippedPickaxe.Value
	EquippedPickaxe:GetPropertyChangedSignal("Value"):Connect(function()
		if previousPickaxe ~= "" then
			local pickaxe = backpack:FindFirstChild(previousPickaxe) or character:FindFirstChild(previousPickaxe)
			destroyingPickaxe:InvokeClient(player)
			pickaxe:Destroy()
		end
		
		local pickaxeName = EquippedPickaxe.Value
		previousPickaxe = pickaxeName
	
		local pickaxeTool = pickaxeFolder.Tools[pickaxeName]:Clone()
		pickaxeTool.Parent = backpack
		local localScript = pickLocalScript:Clone()
		localScript.Parent = pickaxeTool
	end)
end)


equipItemEvent.OnServerEvent:Connect(function(player, tool, equip)
	if not tool then return end
	
	local backpack = player:WaitForChild("Backpack")
	local inventory = player:WaitForChild("Inventory")
	local EquippedPickaxe = inventory:WaitForChild("EquippedPickaxe")
	
	if tool.Name == EquippedPickaxe.Value then
		if equip then
			tool.Parent = player.Character
		else
			tool.Parent = backpack
		end
	end
end)

