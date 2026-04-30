local TweenService = game:GetService("TweenService")
local RepStorage = game:GetService("ReplicatedStorage")

local soundManager = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Managers.SoundManager)
local oreDataManager = require(RepStorage.Shared.Data.OreData)

local miningEffectsEvent = RepStorage.Assets.Network.Events.MiningEffectsEvent

local vfx = RepStorage.Assets.Particles.VFX
local dmgTakenGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("DmgTakenGui")

local function oreCollection(rock, hrp)
	task.wait(0.1)
	for _, ore in ipairs(rock:GetChildren()) do
		if ore.Name ~= "Ore" then continue end
		task.spawn(function()
			local mainOrePart = ore.PrimaryPart
			local newPos = Vector3.new(mainOrePart.Position.X, mainOrePart.Position.Y + 3, mainOrePart.Position.Z)
			
			local oreDropVfx = vfx.OreDropped:Clone()
			oreDropVfx.Parent = ore
			local allTags = ore:GetTags()
			local _, color = oreDataManager.GetOreData(allTags[1])
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
			
			local startTime = tick()
			local duration = 0.3
			local startPos = mainOrePart.Position

			while tick() - startTime < duration do
				local t = (tick() - startTime) / duration
				t = math.min(t, 1)

				local alpha = t * t

				local targetPos = hrp.Position
				mainOrePart.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
				task.wait()
			end
			
			ore:Destroy()
		end)
		task.wait(0.1)
	end
end

local function displayRockDmgTaken(rock, dmgTaken)
	local gui = dmgTakenGui:Clone()
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

	gui:Destroy()
end

local function highlight(rock)
	local highlight = Instance.new("Highlight")
	highlight.Parent = rock
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0.7
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.new(1, 1, 1)

	task.spawn(function()
		repeat 
			highlight.FillTransparency += 0.01
			highlight.OutlineTransparency += 0.01
			task.wait(0.0025)
		until highlight.FillTransparency >= 1
		highlight:Destroy()
	end)
end

local function rockBounce(rock, hrp)
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
end

local function playSound(soundName, category, position)
	soundManager.PlaySound(soundName, category, position)
end

miningEffectsEvent.OnClientEvent:Connect(function(effect, value1, value2)
	if effect == "OreCollection" then
		oreCollection(value1, value2)
	elseif effect == "RockDamageTaken" then
		displayRockDmgTaken(value1, value2)
	elseif effect == "Highlight" then
		highlight(value1)
	elseif effect == "RockBounce" then
		rockBounce(value1, value2)
		
		
		
		--SFX
	elseif effect == "SwingSFX" then
		playSound("Swing", "SFX", value1.Position)
	elseif effect == "EquipSFX" then
		playSound("Equip", "SFX", value1.Position)
	elseif effect == "UnequipSFX" then
		playSound("Unequip", "SFX", value1.Position)
	elseif effect == "RockHitSFX" then
		playSound("RockHit", "SFX", value1.Position)
	elseif effect == "RockLastHitSFX" then
		playSound("RockLastHit", "SFX", value1.Position)
	end
end)