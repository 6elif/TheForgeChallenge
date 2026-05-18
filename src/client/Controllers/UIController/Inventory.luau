local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local OreDataModule = require(ReplicatedStorage.Shared.Data.OreData)
local AddOresToFrame = require(script.Parent.Utils.AddOresToFrame)
local UIAnims = require(script.Parent.Utils.UIAnims)

local Inventory = {}

Inventory.CloseRequested = Instance.new("BindableEvent")

function Inventory:AddOreTracking(ore)
	local data, color = OreDataModule.GetOreData(ore.Name)
	
	self.OresBeingTracked[ore.Name] = true
	
	local oreButton = AddOresToFrame.addOneOre(ore, self.InventoryScroll)
	
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	
	oreButton.Parent = frame
	frame.Parent = self.InventoryScroll

	UIAnims.AddAnimationsToButton(oreButton, {defaultSize = oreButton.Size})

	self.Connections[ore.Name] = ore:GetPropertyChangedSignal("Value"):Connect(function()
		if ore.Value >= 2 then
			oreButton.Quantity.Visible = true
			oreButton.Quantity.Text = "x"..ore.Value
		else
			oreButton.Quantity.Visible = false
		end
	end)	
	
	self.Connections[ore.Name .."act"] = oreButton.Activated:Connect(function()
		self.Inspect.Visible = true
		
		self.Inspect.OreName.Text = ore.Name
		self.Inspect.OreRarity.Text = data.Rarity
		self.Inspect.OreRarity.TextColor3 = color
		self.Inspect.Multiplier.Text = data.Multiplier.. "x Multiplier"
		self.Inspect.DropChance.Text = "1 in "..data.Chance
		self.Inspect.Description.Text = data.Description
		self.Inspect.OreFrame.Glow.ImageColor3 = color
		
		for _, child in ipairs(self.Inspect.OreFrame.Shadow:GetChildren()) do
			child:Destroy()
		end
		for _, child in ipairs(self.Inspect.OreFrame.OreImage:GetChildren()) do
			child:Destroy()
		end
		
		local oreClone = ReplicatedStorage.Ores[ore.Name]:Clone()
		local shadow = oreClone:Clone()
		shadow.Parent = self.Inspect.OreFrame.Shadow
		oreClone.Parent = self.Inspect.OreFrame.OreImage
	end)
end

function Inventory:removeOreTracking(ore)
	local oreButton = self.InventoryScroll:FindFirstChild(ore.Name)
	
	if not oreButton then return end
	
	oreButton:Destroy()
	
	self.OresBeingTracked[ore.Name] = nil
	self.Connections[ore.Name]:Disconnect()
	self.Connections[ore.Name] = nil
	self.Connections[ore.Name.. "act"]:Disconnect()
	self.Connections[ore.Name.. "act"] = nil
end

function Inventory:SetVisible(visible)
	self.MainFrame.Visible = visible
end

function Inventory:Init()
	self.Player = Players.LocalPlayer
	self.InventoryFolder = self.Player:WaitForChild("Inventory")

	self.OreFolder = self.InventoryFolder:FindFirstChild("Ores")

	self.PlayerGui = self.Player:WaitForChild("PlayerGui")
	self.InventoryGui = self.PlayerGui:WaitForChild("InventoryGui")
	self.MainFrame = self.InventoryGui.MainFrame
	self.InnerFrame = self.MainFrame.InnerFrame
	self.InventoryFrame = self.InnerFrame.InventoryFrame
	self.InventoryScroll = self.InventoryFrame.Inventory.ScrollingFrame
	self.Inspect = self.InventoryFrame.Inspect.InnerInspect

	self.CloseButton = self.InventoryFrame.Title.Close
	self.OresBeingTracked = {}
	self.Connections = {}
end

function Inventory:Start()
	self.OreFolder.ChildAdded:Connect(function(child)
		if not child:IsA("IntValue") then return end
		if self.OresBeingTracked[child] then return end

		self:AddOreTracking(child)
	end)

	self.OreFolder.ChildRemoved:Connect(function(child)
		if not child:IsA("IntValue") then return end
		if self.OresBeingTracked[child] then return end
		
		self:removeOreTracking(child)
	end)

	self.CloseButton.Activated:Connect(function()
		Inventory.CloseRequested:Fire()
	end)
end

return Inventory