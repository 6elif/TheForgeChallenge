local RepStorage = game:GetService("ReplicatedStorage")

local armorProbabilities = require(RepStorage.Shared.Data.ArmorProbabilities)
local weaponProbabilities = require(RepStorage.Shared.Data.WeaponProbabilities)
local addOresToFrame = require(RepStorage.Shared.Util.AddOresToFrame)
local oreDataModule = require(RepStorage.Shared.Data.OreData)
local AddButtonAnims = require(RepStorage.Shared.Util.AddButtonAnims)

local pump = require(script.PumpManager)
local counterManager = require(script.CounterManager)
local camManager = require(script.CameraManager)
local bucketManager = require(script.BucketMovementManager)
local guiAnimationManager = require(script.GuiAnimationManager)
local pourManager = require(script.PourManager)

local forge = workspace:WaitForChild("Forge")

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local forgeGui = playerGui.ForgeGui
local mainFrame = forgeGui.MainFrame
local selectFrame = mainFrame.SelectFrame
local selectScroll = selectFrame.ScrollingFrame
local closeButton = selectFrame.Title.Close
local weaponButton = selectFrame.Weapon
local armorButton = selectFrame.Armor

local forgeButtonFrame = mainFrame.ForgeButtonFrame
local slotFrame = forgeButtonFrame.SlotFrame
local multiplierTextLabel = forgeButtonFrame.MultiplierFrame.TextCanvas.TextLabel

local forgeButton = forgeButtonFrame.ForgeButton

local chancesFrame = mainFrame.ChanceFrame
local weaponScroll = chancesFrame.WeaponScroll
local armorScroll = chancesFrame.ArmorScroll

local proximityPrompt = forge:WaitForChild("ProximityPart").ProximityPrompt

local player = game:GetService("Players").LocalPlayer
local _char = player.Character or player.CharacterAdded:Wait()

local MAX_HOLD_TIME = 1

local totalAmountOfOres = 0

local slots = {
	slot1 = {Button = slotFrame.Slot1, OreInFrame = nil},
	slot2 = {Button = slotFrame.Slot2, OreInFrame = nil},
	slot3 = {Button = slotFrame.Slot3, OreInFrame = nil},
	slot4 = {Button = slotFrame.Slot4, OreInFrame = nil},
}

local connections = {}

local function cleanUpOreFrame(data)
	data.OreInFrame = nil
	if data.Button:FindFirstChild("OreImage") then data.Button.OreImage:Destroy() end
	if data.Button:FindFirstChild("Shadow") then data.Button.Shadow:Destroy() end
	data.Button.NameLabel.Text = "Empty"
	data.Button.Quantity.Visible = false
	
	local quantity =  string.gsub(data.Button.Quantity.Text, "%D", "")
	quantity = tonumber(quantity)
	
	data.Button.UIStroke.Color = Color3.new(0.258824, 0.258824, 0.258824)
	data.Button.Corners.GroupColor3 = Color3.new(0.588235, 0.588235, 0.588235)
	data.Button.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
	data.Button.ImageTransparency = 1
end

local function cleanUp()
	for _, oreButton in ipairs(selectScroll:GetChildren()) do
		if not oreButton:IsA("ImageButton") then continue end
		
		AddButtonAnims:CleanUp(oreButton)
		
		oreButton:Destroy()
	end
	
	for slot, data in pairs(slots) do
		cleanUpOreFrame(data)
	end
	
	for _, tracker in pairs(connections) do
		for _, con in pairs(tracker) do
			con:Disconnect()
		end
		tracker = nil
	end
end

local function findOpenSlot()
	for slot, data in pairs(slots) do
		if not data.OreInFrame then
			return slot, data.Button
		end
	end
	return nil
end

local function checkIfOreInSlot(ore)
	for slot, data in pairs(slots) do
		if data.OreInFrame == ore then
			return data.Button
		end
	end
	return nil
end

local function updateChances()
	local function makeDefaultSingleFrame(catFrame)
		local textFrame = catFrame.TextFrame
		local textLabel = textFrame.Text

		local name = string.gsub(catFrame.Name, "([%l])([%u])", "%1 %2")
		textLabel.Text = name.." (0%)"
		catFrame.LayoutOrder = 0
		
		textFrame.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
		textFrame.UIGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 1)
		})
		
		for _, item in ipairs(catFrame.Frame:GetChildren()) do
			if not item:IsA("Frame") then continue end
			item.UIStroke.Color = Color3.new(0.4, 0.4, 0.4)
			item.ImageButton.ImageColor3 = Color3.new(0.380392, 0.380392, 0.380392)
			item.Text.TextColor3 = Color3.new(0.380392, 0.380392, 0.380392)
			item.Corners.GroupColor3 = Color3.new(0.247059, 0.247059, 0.247059)
			item.BackgroundColor3 = Color3.new(0.133333, 0.133333, 0.133333)
		end
	end
	
	local function makeDefaultAll()
		for _, catFrame in ipairs(weaponScroll:GetChildren()) do
			if not catFrame:IsA("Frame") then continue end
			
			makeDefaultSingleFrame(catFrame)
		end
		
		for _, catFrame in ipairs(armorScroll:GetChildren()) do
			if not catFrame:IsA("Frame") then continue end

			makeDefaultSingleFrame(catFrame)
		end
	end
	
	local function updateFrames(category, probability)
		local ProbPrecent = math.round(probability * 100)
		local catFrame = if weaponScroll:FindFirstChild(category) then weaponScroll[category] else armorScroll[category]
		local textFrame = catFrame.TextFrame
		local textLabel = textFrame.Text

		local name = string.gsub(category, "([%l])([%u])", "%1 %2")
		textLabel.Text = name.." ("..ProbPrecent.."%)"
		catFrame.LayoutOrder = -ProbPrecent
		
		local colorValue = 1 - (0.35 * ProbPrecent) / 100
		if ProbPrecent > 0 then
			textFrame.UIGradient.Color = ColorSequence.new(Color3.new(0.984314, 1, 0))
			textFrame.UIGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, colorValue),
				NumberSequenceKeypoint.new(1, 1)
			})
			
			for _, item in ipairs(catFrame.Frame:GetChildren()) do
				if not item:IsA("Frame") then continue end
				item.UIStroke.Color = Color3.new(1, 1, 1)
				item.ImageButton.ImageColor3 = Color3.new(1, 1, 1)
				item.Text.TextColor3 = Color3.new(1, 1, 1)
				item.Corners.GroupColor3 = Color3.new(0.407843, 0.407843, 0.407843)
				item.BackgroundColor3 = Color3.new(0.243137, 0.243137, 0.243137)
			end
		else
			makeDefaultSingleFrame(catFrame)
		end
	end
	
	local weaponProbabilityTable = weaponProbabilities[totalAmountOfOres]
	local armorProbabilityTable = armorProbabilities[totalAmountOfOres]
	
	if not weaponProbabilityTable or not armorProbabilityTable then 
		makeDefaultAll()
		return 
	end
	
	task.spawn(function()
		for category, probability in pairs(weaponProbabilityTable) do
			updateFrames(category, probability)
		end
	end)
	
	for category, probability in pairs(armorProbabilityTable) do
		updateFrames(category, probability)
	end
end

local function update()
	local totalMult = 0
	local localTotalOres = 0
	for slot, data in pairs(slots) do
		if not data.OreInFrame then continue end
		
		local quantity =  string.gsub(data.Button.Quantity.Text, "%D", "")
		quantity = tonumber(quantity)
		
		local oreData = oreDataModule.GetOreData(data.OreInFrame)
		local mult = 0
		if oreData then
			mult = oreData.Multiplier
		end
		
		localTotalOres += quantity
		
		totalMult += (mult * quantity)
	end
	
	totalAmountOfOres = localTotalOres
	
	local finalMult = math.round((totalMult / localTotalOres) * 100) / 100
	if totalMult == 0 then
		finalMult = 0
	end
	multiplierTextLabel.Text = "Multiplier: "..finalMult.."x"
	
	if totalAmountOfOres >= 3 then
		forgeButton.Text.TextColor3 = Color3.new(1, 1, 1)
		forgeButton.Corners.GroupColor3 = Color3.new(0.780392, 0.768627, 0.47451)
		forgeButton.UIStroke.Color = Color3.new(0.423529, 0.423529, 0.207843)
	else
		forgeButton.Text.TextColor3 = Color3.new(0.384314, 0.384314, 0.384314)
		forgeButton.Corners.GroupColor3 = Color3.new(0.219608, 0.219608, 0.219608)
		forgeButton.UIStroke.Color = Color3.new(0.211765, 0.211765, 0.211765)
	end
	
	updateChances()
end

local function handleSlots()
	for slot, data in pairs(slots) do
		
		local holdTime = 0
		local holdingButton = false

		data.Button.MouseButton1Down:Connect(function()
			if not data.OreInFrame then return end
			
			holdingButton = true
			local holdStart = time()
			while holdingButton do
				task.wait()
				holdTime = time() - holdStart

				if holdTime >= MAX_HOLD_TIME then
					holdingButton = false
					cleanUpOreFrame(data)
				end
			end
			
			if holdTime < MAX_HOLD_TIME then
				local quantity =  string.gsub(data.Button.Quantity.Text, "%D", "")
				quantity = tonumber(quantity)
				if quantity == 1 then
					cleanUpOreFrame(data)
				else
					data.Button.Quantity.Text = "x"..(quantity - 1)
				end
			end
			update()
		end)

		data.Button.MouseButton1Up:Connect(function()
			holdingButton = false
		end)
	end
end

local function handleButtons(oreButtons)
	for _, oreButton in ipairs(oreButtons) do
		local tracker = {
			clickCon = nil
		}
		tracker.clickCon = oreButton.Activated:Connect(function()
			local maxQuantity = string.gsub(oreButton.Quantity.Text, "%D", "")
			maxQuantity = tonumber(maxQuantity)
			
			if not oreButton.Quantity.Visible then
				maxQuantity = 1
			end
			
			local slotButton = checkIfOreInSlot(oreButton.Name)
			
			if slotButton then
				local previousQuantity =  string.gsub(slotButton.Quantity.Text, "%D", "")
				previousQuantity = tonumber(previousQuantity)
				if previousQuantity >= maxQuantity then
					warn("EverythingAdded")
				else
					slotButton.Quantity.Text = "x"..(previousQuantity + 1)
				end
			else
				local slot, slotButton = findOpenSlot()
				if slotButton then
					slots[slot].OreInFrame = oreButton.Name
					local oreImage = oreButton.OreImage:Clone()
					local oreShadow = oreButton.Shadow:Clone()
					
					oreImage.Parent = slotButton
					oreShadow.Parent = slotButton
					
					slotButton.NameLabel.Text = oreButton.Name
					slotButton.Quantity.Text = "x1"
					slotButton.Quantity.Visible = true
					
					local data, color = oreDataModule.GetOreData(oreButton.Name)
					
					local hue, sat, value = color:ToHSV()
					local value1 = value * 0.35
					local value2 = value * 0.50
					local value3 = value * 0.4
					slotButton.UIStroke.Color = Color3.fromHSV(hue, sat, value1)
					slotButton.Corners.GroupColor3 = Color3.fromHSV(hue, sat, value2)
					slotButton.BackgroundColor3 = Color3.fromHSV(hue, sat, value3)
					slotButton.ImageTransparency = 0.9
					
				end
			end
			
			update()
		end)

		connections[oreButton] = tracker
	end
end

local function openForgeGui()
	local allButtons = addOresToFrame.AddOres(selectScroll)
	
	for _, button in ipairs(allButtons) do
		-- So we can resize it
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		
		button.Parent = frame
		frame.Parent = selectScroll
		
		AddButtonAnims:addAnimationsToButton(button, {defaultSize = button.Size})
	end
	
	handleButtons(allButtons)
	update()
	
	guiAnimationManager:BlackBarsVisible(false)
	proximityPrompt.Enabled = false
	
	guiAnimationManager:FadeInPlay()
	
	guiAnimationManager:MainVisible(true)
	guiAnimationManager:BlackBarsVisible(true)
	
	camManager:SetToForge()
	
	guiAnimationManager:FadeOutPlay()
end

local function closeForgeGui()
	
	guiAnimationManager:FadeInPlay()
	cleanUp()
	
	guiAnimationManager:MainVisible(false)
	guiAnimationManager:BlackBarsVisible(false)
	proximityPrompt.Enabled = true
	
	camManager:BackToDefault()
	
	guiAnimationManager:FadeOutPlay()
end

local function changeButtonColor(button, on)
	if on then
		button.Corners.GroupColor3 = Color3.new(0.729412, 0.729412, 0.729412)
		button.UIStroke.Color = Color3.new(1, 1, 1)
		button.Text.TextColor3 = Color3.new(1, 1, 1)
		button.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0.152941, 0.152941, 0.152941)),
				ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
		})
	else
		button.Corners.GroupColor3 = Color3.new(0.313725, 0.313725, 0.313725)
		button.UIStroke.Color = Color3.new(0.568627, 0.568627, 0.568627)
		button.Text.TextColor3 = Color3.new(0.568627, 0.568627, 0.568627)
		button.UIGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0.152941, 0.152941, 0.152941)),
			ColorSequenceKeypoint.new(1, Color3.new(0.152941, 0.152941, 0.152941))
		})
	end
end

proximityPrompt.Triggered:Connect(function()
	openForgeGui()
end)


closeButton.Activated:Connect(function()
	closeForgeGui()
end)

weaponButton.Activated:Connect(function()
	weaponScroll.Visible = true
end)

armorButton.Activated:Connect(function()
	armorScroll.Visible = true
end)

weaponScroll:GetPropertyChangedSignal("Visible"):Connect(function()
	if weaponScroll.Visible then
		changeButtonColor(weaponButton, true)
		armorScroll.Visible = false
	else
		changeButtonColor(weaponButton, false)
	end
end)

armorScroll:GetPropertyChangedSignal("Visible"):Connect(function()
	if armorScroll.Visible then
		weaponScroll.Visible = false
		changeButtonColor(armorButton, true)
	else
		changeButtonColor(armorButton, false)
	end
end)

forgeButton.Activated:Connect(function()
	if totalAmountOfOres < 3 then return end
	
	guiAnimationManager:MainVisible(false)
	
	camManager:SetToPump()
	bucketManager:Pump()
	counterManager:StartCount()
	guiAnimationManager:TransitionToPump()
	pump:Start()
	pump:WaitUntilEnds()
	guiAnimationManager:TransitionOffPump()
	
	camManager:SetToPour()
	bucketManager:Pour()
	counterManager:StartCount()
	guiAnimationManager:PourVisible(true)
	pourManager:Start()
	pourManager:WaitUntilEnds()
	guiAnimationManager:PourVisible(false)
	
	closeForgeGui()
end)


-- Init
local listOfButtons = {
	armorButton,
	weaponButton,	
	forgeButton,
}

for _, button in ipairs(listOfButtons) do
	local data = {defaultSize = button.Size}
	
	if button == forgeButton then
		data = {
			defaultSize = forgeButtonFrame.Size,
			frameInsteadOfButton = forgeButtonFrame,
			maxSize = UDim2.fromScale(forgeButtonFrame.Size.X.Scale * 1.025, forgeButtonFrame.Size.Y.Scale * 1.025),
			minSize =  UDim2.fromScale(forgeButtonFrame.Size.X.Scale * 0.95, forgeButtonFrame.Size.Y.Scale * 0.95),
		}
	end
	
	AddButtonAnims:addAnimationsToButton(button, data)
end

handleSlots()