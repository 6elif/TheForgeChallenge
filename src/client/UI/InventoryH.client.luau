local RepStorage = game:GetService("ReplicatedStorage")

local oreDataModule = require(RepStorage.Modules.OreData)
local addOresToFrame = require(RepStorage.Modules.AddOresToFrame)
local addButtonAnims = require(RepStorage.Modules.AddButtonAnims)

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local inventoryFolder = player:WaitForChild("Inventory")

local oreFolder = inventoryFolder:FindFirstChild("Ores")

local mainFrame = script.Parent.MainFrame
local innerFrame = mainFrame.InnerFrame
local inventoryFrame = innerFrame.InventoryFrame
local inventoryScroll = inventoryFrame.Inventory.ScrollingFrame
local inspect = inventoryFrame.Inspect.InnerInspect

local closeButton = inventoryFrame.Title.Close
local oresBeingTracked = {}
local connections = {}

closeButton.Activated:Connect(function()
	mainFrame.Visible = false
end)

local function addOreTracking(ore)
	local data, color = oreDataModule.GetOreData(ore.Name)
	
	oresBeingTracked[ore.Name] = true
	
	local oreButton = addOresToFrame.addOneOre(ore, inventoryScroll)
	
	-- So we can resize it
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	
	oreButton.Parent = frame
	frame.Parent = inventoryScroll

	addButtonAnims:addAnimationsToButton(oreButton, {defaultSize = oreButton.Size})

	connections[ore.Name] = ore:GetPropertyChangedSignal("Value"):Connect(function()
		if ore.Value >= 2 then
			oreButton.Quantity.Visible = true
			oreButton.Quantity.Text = "x"..ore.Value
		else
			oreButton.Quantity.Visible = false
		end
	end)	
	
	connections[ore.Name .."act"] = oreButton.Activated:Connect(function()
		inspect.Visible = true
		
		inspect.OreName.Text = ore.Name
		inspect.OreRarity.Text = data.Rarity
		inspect.OreRarity.TextColor3 = color
		inspect.Multiplier.Text = data.Multiplier.. "x Multiplier"
		inspect.DropChance.Text = "1 in "..data.Chance
		inspect.Description.Text = data.Description
		inspect.OreFrame.Glow.ImageColor3 = color
		
		for _, child in ipairs(inspect.OreFrame.Shadow:GetChildren()) do
			child:Destroy()
		end
		for _, child in ipairs(inspect.OreFrame.OreImage:GetChildren()) do
			child:Destroy()
		end
		
		local oreClone = RepStorage.Ores[ore.Name]:Clone()
		local shadow = oreClone:Clone()
		shadow.Parent = inspect.OreFrame.Shadow
		oreClone.Parent = inspect.OreFrame.OreImage
		
		
	end)
end

local function removeOreTracking(ore)
	local oreButton = inventoryScroll:FindFirstChild(ore.Name)
	
	if not oreButton then return end
	
	oreButton:Destroy()
	
	oresBeingTracked[ore.Name] = nil
	connections[ore.Name]:Disconnect()
	connections[ore.Name] = nil
	connections[ore.Name.. "act"]:Disconnect()
	connections[ore.Name.. "act"] = nil
end

oreFolder.ChildAdded:Connect(function(child)
	if not child:IsA("IntValue") then return end
	if oresBeingTracked[child] then return end
	
	addOreTracking(child)
end)

oreFolder.ChildRemoved:Connect(function(child)
	if not child:IsA("IntValue") then return end
	if oresBeingTracked[child] then return end
	
	removeOreTracking(child)
end)