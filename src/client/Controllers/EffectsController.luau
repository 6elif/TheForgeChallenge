local TweenService = game:GetService("TweenService")
local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SoundManager = require(Players.LocalPlayer.PlayerScripts.Client.Managers.SoundManager)
local OreDataManager = require(RepStorage.Shared.Data.OreData)

local effectsEvent

local vfx
local dmgTakenGui
local vfxPoolingFolder

local EffectsController = {}

local function getFromPool(poolFolder, template)
    local existing = poolFolder:FindFirstChild(template.Name)
    if existing then
        existing.Parent = nil
        return existing
    end
    return template:Clone()
end

local playEffect = {
	["OreCollection"] = function(data)
		local rock = data.rock
		local hrp = data.hrp

		if not rock or not hrp then return end

		task.wait(0.1)
		for _, ore in ipairs(rock:GetChildren()) do
			if ore.Name ~= "Ore" then continue end
			task.spawn(function()
				local mainOrePart = ore.PrimaryPart
				local newPos = Vector3.new(mainOrePart.Position.X, mainOrePart.Position.Y + 3, mainOrePart.Position.Z)
				
				local oreDropVfx = getFromPool(vfxPoolingFolder, vfx.OreDropped)
				oreDropVfx.Parent = ore
				oreDropVfx.Enabled = true

				local allTags = ore:GetTags()
				local oreType = "Unknown"
				for _, tag in ipairs(allTags) do
					if OreDataManager.GetOreData(tag) then
						oreType = tag
						break
					end
				end

				if not oreType then return end

				local _, color = OreDataManager.GetOreData(oreType)
				oreDropVfx.Light.Color = ColorSequence.new(color)
				oreDropVfx.Stars.Color = ColorSequence.new(color)

				local upInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				local upTween = TweenService:Create(mainOrePart, upInfo, {CFrame = CFrame.new(newPos)})
				upTween:Play()
				upTween.Completed:Wait()

				local toPlayerInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In)
				local toPlayerTween = TweenService:Create(mainOrePart, toPlayerInfo, {CFrame = CFrame.new(hrp.Position)})
				toPlayerTween:Play()
				
				task.wait(0.6 * 0.4)
				
				toPlayerTween:Pause()
				
				local startTime = os.clock()
				local duration = 0.3
				local startPos = mainOrePart.Position

				while true do
					local elapsed = os.clock() - startTime
					local t = math.min(elapsed / duration, 1)

					local alpha = t * t
					mainOrePart.CFrame = CFrame.new(startPos:Lerp(hrp.Position, alpha))

					if t >= 1 then break end
					task.wait()
				end
				
				oreDropVfx.Enabled = false
				oreDropVfx.Parent = vfxPoolingFolder

				ore:Destroy()
			end)
			task.wait(0.1)
		end
	end,

	["DisplayRockDmgTaken"] = function(data)
		local rock = data.rock
		local dmgTaken = data.dmgTaken

		if not rock or not dmgTaken then return end

		local gui = getFromPool(vfxPoolingFolder, dmgTakenGui)
		gui.Parent = rock
		gui.Enabled = true
		gui.DamageTakenText.Text = dmgTaken

		local rngLocationX = math.random(-40, 40) / 10
		local rngLocationY = math.random(35, 65) / 10

		gui.StudsOffset = Vector3.new(rngLocationX, rngLocationY, 0)
		gui.Size = UDim2.new(2, 0, 2, 0)

		local offset = 2

		local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local properties = {
			StudsOffset = Vector3.new(gui.StudsOffset.X, gui.StudsOffset.Y + offset, 0),
			Size = UDim2.new(1, 0, 1, 0)
		}
		local Tween = TweenService:Create(gui, info, properties)
		Tween:Play()

		Tween.Completed:Wait()

		gui.Enabled = false
		gui.Parent = vfxPoolingFolder
	end,

	["Highlight"] = function(data)
		local rock = data.rock
		
		if not rock then return end

		local highlight = getFromPool(vfxPoolingFolder, Instance.new("Highlight"))
		highlight.Parent = rock
		highlight.FillTransparency = 0.7
		highlight.OutlineTransparency = 0.7
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = Color3.new(1, 1, 1)
		highlight.Enabled = true

		local info = TweenInfo.new(0.5)
		local tween = TweenService:Create(highlight, info, {
			FillTransparency = 1, 
			OutlineTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			highlight.Enabled = false
			highlight.Parent = vfxPoolingFolder
		end)
	end,

	["RockBounce"] = function(data)
		local rock = data.rock
		local hrp = data.hrp

		if not rock or not hrp then return end
		local currentPos = rock.Main.CFrame
		local direction = (rock.Main.Position - hrp.Position).Unit
		local bounceOffset = CFrame.new(direction * 0.3)

		local bounceInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local bounceTween = TweenService:Create(rock.Main, bounceInfo, {CFrame = currentPos * bounceOffset})
		bounceTween:Play()

		task.wait(0.1)

		if not rock or not rock:FindFirstChild("Main") then return end

		-- Bounce back
		local returnInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local returnTween = TweenService:Create(rock.Main, returnInfo, {CFrame = rock.Main.CFrame * bounceOffset:Inverse()})
		returnTween:Play()
	end,

	["PlaySound"] = function(data)
		SoundManager:PlaySound(data)
	end,
}

function EffectsController.Init()
	effectsEvent = RepStorage.Assets.Network.Events.Effects
	dmgTakenGui = Players.LocalPlayer.PlayerGui:WaitForChild("DmgTakenGui")
	vfx = RepStorage.Assets.Particles.VFX

	vfxPoolingFolder = Instance.new("Folder")
	vfxPoolingFolder.Name = "VFXPooling"
	vfxPoolingFolder.Parent = Players.LocalPlayer
end

function EffectsController.Start()
	effectsEvent.OnClientEvent:Connect(function(effectName, data)
		local effectFunction = playEffect[effectName]
		if effectFunction then
			effectFunction(data)
		end
	end)
end

return EffectsController