local TweenService = game:GetService("TweenService")
local RepStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local lootPlan = require(RepStorage.Shared.Util.LootPlan)
local rockData = require(RepStorage.Shared.Data.RockData)

local miningEffectsEvent = RepStorage.Assets.Network.Events.MiningEffectsEvent

local rockFolder = script.Parent
local vfx = RepStorage.Assets.Particles.VFX
local oreRepFolder = RepStorage.Assets.Models.Ores

local REWSPAWN_TIME = 4
local MAX_IDLE_TIME = 20

local rockPlan = lootPlan.newSingle()

local connections = {}


for rockName, data in pairs(rockData) do
	local rarity = (1 / data.ChanceToSpawn) * 100   -- in %
	rockPlan:AddLoot(rockName, rarity)
end

local function cleanUpCons(rock)
	if not rock then return end
	
	for _, con in pairs(connections[rock]) do
		con:Disconnect()
	end
	connections[rock] = nil
end

local function sizeRng(rockName)
	local sizeRNG
	if rockName == "Pebble" then -- 0.07 > 0.1
		sizeRNG = math.random(90, 150) / 1000
	elseif rockName == "Rock" then --  0.07 > 0.1
		sizeRNG = math.random(140, 180) / 1000
	elseif rockName == "Boulder" then -- 0.4 > 0.54
		sizeRNG = math.random(80, 100) / 100
	end
	return sizeRNG
end

local function positionRock(rock, spawnPoint, newY)
	newY = newY or rock.Main.Size.Y
	local offset = newY / 2
	rock.Main.CFrame = CFrame.new(spawnPoint.WorldPosition + Vector3.new(0, offset, 0))
end
                -- !!!! PLACEHOLDER !!!! --
local function addOreToRock(rock, maxSizeY, loot, hrp)
	local tracker = {
		size = nil,
		collected = nil
	}
	
	for _, oreName in pairs(loot) do
		local ore = if oreRepFolder:FindFirstChild(oreName) then oreRepFolder[oreName]:Clone() else oreRepFolder.Placeholder:Clone()
		ore.Name = "Ore"
		ore.Parent = rock
		
		ore:AddTag(oreName)
		
		local rngFactorX = math.random(-100, 100) / 100
		local rngFactorZ = math.random(-100, 100) / 100
		local y = rock.Main.Size.Y / 2.5
		
		local pos = rock.Main.Position + Vector3.new(rngFactorX, y, rngFactorZ)
		ore:MoveTo(pos)
	end
	
	tracker.size = rock.Main:GetPropertyChangedSignal("Size"):Connect(function()
		local rockSizeY = rock.Main.Size.Y
		local threshold = maxSizeY / 2
		
		if rockSizeY > threshold then return end
		
		for _, ore in ipairs(rock:GetChildren()) do
			if ore.Name ~= "Ore" then continue end
			
			local y = rockSizeY / 2
			local primaryPart = ore.PrimaryPart
			local pos = Vector3.new(primaryPart.Position.X, rock.Main.Position.Y + y, primaryPart.Position.Z)
			ore:MoveTo(pos)
		end
	end)
	
	tracker.collected = rock:GetAttributeChangedSignal("Collected"):Connect(function()
		local collected = rock:GetAttribute("Collected")
			
		if not collected then return end
			
		miningEffectsEvent:FireAllClients("OreCollection", rock, hrp)
	end)	
	
	connections[rock] = tracker
end

local function handleRock(spawnPoint)
	local rockName = rockPlan:GetRandomLoot()
	local rock = rockData[rockName].Model:Clone()
	rock.Parent = rockFolder
	
	local healthGui = rock:FindFirstChild("HealthGui")
	local container = healthGui.Container
	local healthBar = container.HealthBar
	local healthRn = healthBar.HealthRn
	local healthLost = healthBar.HealthLost
	local healthText = container.HealthText
	
	local maxHealth = rock.MaxHealth
	maxHealth.Value = rockData[rock.Name].Health
	local health = rock.Health
	
	rock:SetAttribute("Collected", false)
	
	local sizeRNG = sizeRng(rock.Name)
	rock:ScaleTo(sizeRNG)
	
	positionRock(rock, spawnPoint)

	healthText.Text = maxHealth.Value.." HP"
	health.Value = maxHealth.Value
	
	healthText.Text = math.clamp(health.Value, 0, math.huge).." HP"
	local newSizeX = health.Value / maxHealth.Value
	healthRn.Size = UDim2.new(newSizeX,  0, 1, 0)
	
	local previousHealthValue = health.Value
	local maxSizeY = rock.Main.Size.Y
	
	local currentIdleTime = 0

	local healthConnection
	healthConnection = health:GetPropertyChangedSignal("Value"):Connect(function()
		local damageTaken = math.round((previousHealthValue - health.Value) * 100) / 100
		health.Value = math.clamp(health.Value, 0, maxHealth.Value)
		health.Value = math.round(health.Value * 100) / 100
		
		if previousHealthValue == health.Value then return end
		
		task.spawn(function()
			local startedAttackingTime = time()
			local savedHealthValue = health.Value
			while health.Value == savedHealthValue and health.Value ~= maxHealth.Value do
				currentIdleTime = time() - startedAttackingTime

				if currentIdleTime >= MAX_IDLE_TIME then
					warn(currentIdleTime)
					health.Value = maxHealth.Value
					local newY = math.clamp((health.Value / maxHealth.Value) * maxSizeY, maxSizeY / 4, maxSizeY)
					rock.Main.Size = Vector3.new(rock.Main.Size.X, newY, rock.Main.Size.Z)
					positionRock(rock, spawnPoint)
					
					previousHealthValue = health.Value
					healthText.Text = health.Value.." HP"

					local newSizeX = health.Value / maxHealth.Value
					healthRn.Size = UDim2.new(newSizeX,  0, 1, 0)
					
					rock:SetAttribute("HitByPlayer", nil)
					rock:SetAttribute("OreRevealed", nil)
					rock:RemoveTag("OresAdded")
					cleanUpCons(rock)
					local ore = rock:FindFirstChild("Ore")
					if ore then ore:Destroy() end
				end
				
				if not rock.Parent then break end
				
				task.wait()
			end
		end)
		
		if health.Value == maxHealth.Value then return end
		
		miningEffectsEvent:FireAllClients("RockDamageTaken", rock, damageTaken)
		
		local newY = math.clamp((health.Value / maxHealth.Value) * maxSizeY, maxSizeY / 4, maxSizeY)
		rock.Main.Size = Vector3.new(rock.Main.Size.X, newY, rock.Main.Size.Z)
		
		positionRock(rock, spawnPoint, newY)
		
		-- current Rock owner
		local playerId = rock:GetAttribute("HitByPlayer")
		local player = Players:GetPlayerByUserId(playerId)
		local char = player.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		
		miningEffectsEvent:FireAllClients("RockBounce", rock, hrp)
		miningEffectsEvent:FireAllClients("Highlight", rock)
		
		previousHealthValue = health.Value
		healthText.Text = health.Value.." HP"

		local newSizeX = health.Value / maxHealth.Value
		healthRn.Size = UDim2.new(newSizeX,  0, 1, 0)
		
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local tween = TweenService:Create(healthLost, tweenInfo, {Size = UDim2.new(newSizeX, 0, 1, 0)})
		tween:Play()
		
		if rock:GetAttribute("OreRevealed") and not rock:HasTag("OresAdded") then
			local jsonString = rock:GetAttribute("OreRevealed")
			local loot = HttpService:JSONDecode(jsonString)
			
			addOreToRock(rock, maxSizeY, loot, hrp)
			rock:AddTag("OresAdded")
		end
		
		if health.Value <= 0 then
			healthConnection:Disconnect()
			healthConnection = nil
			
			rock:SetAttribute("Collected", true)
			
			task.spawn(function()
				local smoke = vfx.Smoke:Clone()
				smoke.Parent = rock.Main
				smoke:Emit(1)
			end)
			
			task.wait(REWSPAWN_TIME)
			
			rock:Destroy()
			handleRock(spawnPoint)
		end
	end)
end

for _, spawnPoint in ipairs(rockFolder:GetChildren()) do
	if not spawnPoint:IsA("Attachment") then continue end
	
	handleRock(spawnPoint)
end