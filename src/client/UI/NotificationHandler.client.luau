local RepStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local collectedEvent = RepStorage.Events.OreCollected
local hitEvent = RepStorage.Events.Hit
local notificationEvent = RepStorage.Events.Notification

local oreDataModule = require(RepStorage.Modules.OreData)
local soundManager = require(RepStorage.Modules.SoundManager)

local oreFolder = RepStorage.Ores

local notificationGui = script.Parent
local mainFrame = notificationGui.MainFrame
local flashEffect = notificationGui.Parent.MiningGui.FlashEffect

local oreDropTemplate = mainFrame.OreDropTemplate
local baseNotTemplate = mainFrame.BaseNotificationTemplate

local flashEffectDb = false
local newFlash = false

local previousFlashTween

local function popupText(canvas, dir)
	dir = dir or 1
	canvas.UIGradient.Transparency = NumberSequence.new(dir == 1 and 1 or 0)

	local waitTime = 0.02
	local edgeSoftness = 0.05

	for i = 0, 1, 0.05 do
		local keypoints = {}

		for pos = 0, 1, 0.1 do
			local transparency
			if dir == 1 then
				transparency = math.clamp((pos - i) / edgeSoftness, 0, 1)
			else
				transparency = math.clamp((pos - (1 - i)) / edgeSoftness, 0, 1)
			end
			table.insert(keypoints, NumberSequenceKeypoint.new(pos, transparency))
		end

		canvas.UIGradient.Transparency = NumberSequence.new(keypoints)
		task.wait(waitTime)
	end

	canvas.UIGradient.Transparency = NumberSequence.new(dir == 1 and 0 or 1)
end

local function orePopUp(ore, dir)
	dir = dir or 1
	
	local info, tween
	if dir == 1 then
		ore.Position = UDim2.new(0.5, 0, 1.5, 0)
		info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween = TweenService:Create(ore, info, {Position = UDim2.new(0.5, 0, 0.5, 0)})
	else
		info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween = TweenService:Create(ore, info, {Position = UDim2.new(0.5, 0, 1.5, 0)})
	end
	
	tween:Play()
end

local function fadeInOut(Ui, dir)
	dir = dir or 1
	
	local info, tween
	if dir == 1 then
		Ui.ImageTransparency = 1
		info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		tween = TweenService:Create(Ui, info, {ImageTransparency = 0})
	else
		info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween = TweenService:Create(Ui, info, {ImageTransparency = 1})
	end

	tween:Play()
end

local function playFlashEffect(finalHit, oresDropped)
	if flashEffectDb then return end

	flashEffect.Flash1.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
	flashEffect.Flash2.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))

	if flashEffect.Visible then
		newFlash = true
		previousFlashTween:Cancel()
	end
	flashEffectDb = true
	flashEffect.Visible = true

	if oresDropped then
		local highestRarity = "Common"

		for _, oreName in pairs(oresDropped) do
			local oreData, _ = oreDataModule.GetOreData(oreName)
			
			if oreData.Rarity == "Epic" then
				highestRarity = "Epic"
			elseif oreData.Rarity == "Rare" and highestRarity ~= "Epic" then
				highestRarity = "Rare"
			elseif oreData.Rarity == "Uncommon" and highestRarity ~= "Epic" and highestRarity ~= "Rare" then
				highestRarity = "Uncommon"
			end
		end

		local rarityColor = oreDataModule.RarityColors[highestRarity]

		flashEffect.Flash1.UIGradient.Color = ColorSequence.new(rarityColor)
		flashEffect.Flash2.UIGradient.Color = ColorSequence.new(rarityColor) 

	end

	local flashInfo
	if finalHit then
		flashEffect.GroupTransparency = 0
		flashInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	else
		flashEffect.GroupTransparency = 0.5
		flashInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end

	local flashTween = TweenService:Create(flashEffect, flashInfo, {GroupTransparency = 1})
	flashTween:Play()
	previousFlashTween = flashTween

	task.delay(0.2, function()
		flashEffectDb = false
	end)

	flashTween.Completed:Wait()

	if not newFlash then
		flashEffect.Visible = false
	else
		newFlash = false
	end
end

collectedEvent.OnClientEvent:Connect(function(oreName)
	local oreData, color = oreDataModule.GetOreData(oreName)
	
	if not color or not oreData then return end
	
	soundManager.PlaySound("OreCollected", "SFX")
	
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	
	local dropGui = oreDropTemplate:Clone()
	
	local oreModel = if oreFolder:FindFirstChild(oreName) then oreFolder[oreName]:Clone() else oreFolder.Placeholder:Clone()
	oreModel.Parent = dropGui.OreFrame.OreImageCanv.OreImage
	
	local message = "You just found <font color=\"rgb("..r..", "..g..", "..b..")\">"..oreData.Rarity.."</font> "
		.. oreName ..", 1 in ".. oreData.Chance .." chance!"
	dropGui.TextFrame.TextCanvas.TextLabel.Text = message
	dropGui.OreFrame.ImageLabel.ImageColor3 = color
	dropGui.Name = oreName
	dropGui.Parent = mainFrame
	
	dropGui.Visible = true
	
	task.spawn(function()
		while dropGui.Parent == mainFrame do
			dropGui.OreFrame.ImageLabel.Rotation += 1
			task.wait(0.01)
		end
	end)
	
	fadeInOut(dropGui.OreFrame.ImageLabel, 1)
	orePopUp(dropGui.OreFrame.OreImageCanv.OreImage, 1)
	popupText(dropGui.TextFrame.TextCanvas, 1)
	
	task.wait(1.5)

	fadeInOut(dropGui.OreFrame.ImageLabel, -1)
	orePopUp(dropGui.OreFrame.OreImageCanv.OreImage, -1)
	popupText(dropGui.TextFrame.TextCanvas, -1)
	
	dropGui:Destroy()
end)

local function notEnoughDmg(value)
	local gui = baseNotTemplate:Clone()
	gui.Parent = mainFrame
	gui.TextCanvas.TextLabel.TextColor3 = Color3.new(1, 0, 0.0156863)
	gui.TextCanvas.TextLabel.Text = "You need to deal at least ".. value .." base damage to mine this rock!"
	gui.Visible = true
	
	popupText(gui.TextCanvas, 1)
	
	task.wait(1.5)
	
	popupText(gui.TextCanvas, -1)
	
	gui:Destroy()
end

local function otherPlayersRock()
	local gui = baseNotTemplate:Clone()
	gui.Parent = mainFrame
	gui.TextCanvas.TextLabel.TextColor3 = Color3.new(1, 0, 0.0156863)
	gui.TextCanvas.TextLabel.Text = "Someone else is already mining this rock!"
	gui.Visible = true

	popupText(gui.TextCanvas, 1)

	task.wait(1.5)

	popupText(gui.TextCanvas, -1)

	gui:Destroy()
end

hitEvent.OnClientEvent:Connect(playFlashEffect)

notificationEvent.OnClientEvent:Connect(function(notification, value)
	if notification == "NotEnoughDmg" then
		notEnoughDmg(value)
	elseif notification == "OtherPlayersRock"  then
		otherPlayersRock()
	end
end)
