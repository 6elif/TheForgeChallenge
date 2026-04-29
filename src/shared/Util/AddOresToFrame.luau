local RepStorage = game:GetService("ReplicatedStorage")
local oreDataModule = require(RepStorage.Modules.OreData)

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local inventory = player:WaitForChild("Inventory")
local oresOwned = inventory:WaitForChild("Ores")

local oreTemplate = player.PlayerGui.OreFrameTemplate.OreTemplate

local oresFolder = RepStorage.Ores

local oresToFrame = {}

local function addOreToFrame(ore, frame)
	local data, color = oreDataModule.GetOreData(ore.Name)

	local oreButton = oreTemplate:Clone()
	oreButton.Name = ore.Name
	oreButton.Parent = frame
	oreButton.Visible = true
	oreButton.NameLabel.Text = ore.Name
	oreButton.NameLabel.Visible = true
	oreButton.BackgroundColor3 = color
	
	local oreModel = if oresFolder:FindFirstChild(ore.Name) then oresFolder[ore.Name]:Clone() else oresFolder.Placeholder:Clone()
	local shadow = oreModel:Clone()
	
	oreModel.Parent = oreButton.OreImage
	shadow.Parent = oreButton.Shadow

	if ore.Value >= 2 then
		oreButton.Quantity.Text = "x"..ore.Value
		oreButton.Quantity.Visible = true
	else
		oreButton.Quantity.Visible = false
	end

	local hue, sat, value = color:ToHSV()
	local value1 = value * 0.35
	local value2 = value * 0.50
	local value3 = value * 0.4
	oreButton.UIStroke.Color = Color3.fromHSV(hue, sat, value1)
	oreButton.Corners.GroupColor3 = Color3.fromHSV(hue, sat, value2)
	oreButton.BackgroundColor3 = Color3.fromHSV(hue, sat, value3)
	
	return oreButton
end

function oresToFrame.AddOres(frame)
	local allOreButtons = {}
	for _, ore in ipairs(oresOwned:GetChildren()) do
		if not ore:IsA("IntValue") then continue end
		
		local oreButton = addOreToFrame(ore, frame)
		
		table.insert(allOreButtons, oreButton)
	end
	
	return allOreButtons
end

function oresToFrame.addOneOre(ore, frame)
	return addOreToFrame(ore, frame)
end

return oresToFrame
