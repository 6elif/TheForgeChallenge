local Players = game:GetService("Players")

local dataFolder = game:GetService("ServerScriptService").Server.Unsorted___.Data

local template = require(dataFolder.Template)
local dataHandler = require(dataFolder.DataHandler)

local function addData(player)
	dataHandler.playerProfiles[player] = template
	
	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player
	
	local ores = Instance.new("Folder")
	ores.Name = "Ores"
	ores.Parent = inventory
	
	local equippedPickaxe = Instance.new("StringValue")
	equippedPickaxe.Name = "EquippedPickaxe"
	equippedPickaxe.Value = ""
	equippedPickaxe.Parent = inventory
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = 0
	gold.Parent = leaderstats
end

Players.PlayerAdded:Connect(function(player)
	addData(player)
end)