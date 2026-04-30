local RepStorage = game:GetService("ReplicatedStorage")

local oreDataModule = require(RepStorage.Shared.Data.OreData)

local sellItems = RepStorage.Assets.Network.Events.SellItems

sellItems.OnServerEvent:Connect(function(player, itemsToSell)
	local inventory = player:FindFirstChild("Inventory")
	local ores = inventory:FindFirstChild("Ores")
	local leaderstats = player:FindFirstChild("leaderstats")
	local gold = leaderstats:FindFirstChild("Gold")
	
	for oreName, quantity in pairs(itemsToSell) do
		local data = oreDataModule.Data[oreName]
		if not data then
			warn(oreName.. " Not found")
		end
		
		local orePrice = data.Price

		if ores[oreName].Value >= quantity then
			gold.Value += orePrice * quantity
			ores[oreName].Value -= quantity
			if ores[oreName].Value == 0 then
				ores[oreName]:Destroy()
			end
		end
	end
	
end)