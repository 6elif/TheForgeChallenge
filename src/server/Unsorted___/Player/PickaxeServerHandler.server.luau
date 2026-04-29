local RepStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local rockData = require(RepStorage.Modules.RockData)
local dataHandler = require(ServerScriptService.Data.DataHandler)
local lootPlan = require(ServerScriptService.Modules.LootPlan)
local oreDataModule = require(RepStorage.Modules.OreData)

local hitEvent = RepStorage.Events.Hit
local pickaxeSfxEvent = RepStorage.Events.PickaxeSFX
local miningEffectsEvent = RepStorage.Events.MiningEffectsEvent
local collectedEvent = RepStorage.Events.OreCollected
local notification = RepStorage.Events.Notification

local vfx = RepStorage.VFX

local plans = {}

for rockName, data in pairs(rockData) do
	local orePlan = lootPlan.newMulti()
	plans[rockName] = orePlan
	
	for oreName, data in pairs(oreDataModule.Data) do
		for _, dropFromLocation in ipairs(data.DropsFrom) do
			if dropFromLocation ~= rockName then continue end
			
			local rarity = (1 / data.Chance) * 100
			orePlan:AddLoot(oreName, rarity)
		end
	end
end

local function getLoot(player, rock)
	local plan = plans[rock.Name]
	local maxOreDropAmount = rockData[rock.Name].MaxOreDropAmount
	local oreLuck = rockData[rock.Name]["Luck Boost"]
	local playerLuck = dataHandler.playerProfiles[player].Luck
	
	local lootTable
	local totalLoot = 0
	repeat
		lootTable = plan:GetRandomLoot(playerLuck + oreLuck)
		for _, loot in pairs(lootTable) do
			totalLoot += 1
		end
	until totalLoot >= 1

	local sortedLoot = {}
	for oreName, _ in pairs(lootTable) do
		table.insert(sortedLoot, {Name = oreName, Rarity = oreDataModule.Data[oreName].Chance})
	end

	table.sort(sortedLoot, function(ore1, ore2)
		return ore1.Rarity > ore2.Rarity
	end)

	local oresDropped = {}
	for i = 1, math.min(maxOreDropAmount, #sortedLoot) do
		oresDropped[sortedLoot[i]] = sortedLoot[i].Name
	end
	
	return oresDropped
end

local function putLootInInventory(player, oresDropped)
	local inventory = player:FindFirstChild("Inventory")

	for _, oreName in pairs(oresDropped) do
		if inventory.Ores:FindFirstChild(oreName) then
			inventory.Ores[oreName].Value += 1
		else
			local loot = Instance.new("IntValue")
			loot.Name = oreName
			loot.Value = 1
			loot.Parent = inventory.Ores
		end
		collectedEvent:FireClient(player, oreName)
	end
end

local function handleRock(player, hrp, rock, pickaxe)
	local miningPower = pickaxe.MiningPower.Value
	local randomFactor = math.random(90, 110) / 100
	local dmg = miningPower * randomFactor
	
	local head = pickaxe:FindFirstChild("Head")
	
	if rock:GetAttribute("Collected") == true then
		return
	end
	
	local toLook = (rock.Main.Position - hrp.Position).Unit
	local dot = hrp.CFrame.LookVector:Dot(toLook)
	
	if dot > 0.2 then
		local midpoint = (head.Position + rock.Main.Position) / 2
		local sparkles = vfx.RockHit:Clone()
		sparkles.Parent = rock.Main
		sparkles.WorldPosition = midpoint
		sparkles.Sparkles1White:Emit(10)
		sparkles.Sparkles2White:Emit(10)
		sparkles.Sparkles1:Emit(10)
		sparkles.Sparkles2:Emit(10)
		sparkles.Shockwave:Emit(1)
	end
	
	local requiredPower = rockData[rock.Name].RequiredPower
	if miningPower < requiredPower then
		notification:FireClient(player, "NotEnoughDmg", requiredPower)
		warn("Need a stronger pickaxe")
		return
	end 
	
	local maxHealth = rock.MaxHealth.Value
	local currentHealth = rock.Health.Value
	local revealOreThershold = maxHealth / 2
	local currentProgress = currentHealth - dmg
	
	if currentProgress <= revealOreThershold and not rock:GetAttribute("OreRevealed") then
		local loot = getLoot(player, rock)
		
		local jsonString = HttpService:JSONEncode(loot)
		rock:SetAttribute("OreRevealed", jsonString)
		
	end
	
	miningEffectsEvent:FireAllClients("RockHitSFX", rock.Main)
	
	if currentHealth - dmg <= 0 then
		local jsonString = rock:GetAttribute("OreRevealed")
		local loot = HttpService:JSONDecode(jsonString)
		
		hitEvent:FireClient(player, true, loot)
		putLootInInventory(player, loot)
	else
		
		hitEvent:FireClient(player, false)
	end
	
	rock.Health.Value -= dmg

	rock:SetAttribute("HitByPlayer", player.UserId)
end


hitEvent.OnServerEvent:Connect(function(player, pickaxe)
	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")

	-- HitBox
	local part = Instance.new("Part")
	part.Parent = workspace
	part.CanCollide = false
	part.Size = Vector3.new(7, 7, 7)
	part.Anchored = true
	part.Transparency = 1
	part.Color = Color3.new(1, 0, 0.0156863)
	part.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)

	-- Detection
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = {workspace.RockFolder}

	local partsInBox = workspace:GetPartBoundsInBox(part.CFrame, part.Size, overlapParams)

	if partsInBox ~= {} then 
		local rocks = {}
		for _, part in ipairs(partsInBox) do
			if rocks[part.Parent] or not part.Parent:IsA("Model") then continue end
			if part.Parent.Name == "Ore" then continue end
			
			task.spawn(function()
				local rock = part.Parent
				rocks[part.Parent] = true
				
				local rockOwnerId = rock:GetAttribute("HitByPlayer")
				if rockOwnerId == player.UserId or not rockOwnerId then
					handleRock(player, hrp, rock, pickaxe)
				else
					notification:FireClient(player, "OtherPlayersRock")
					warn("Not Owned by you")
				end
			end)
		end
	end

	task.delay(0.2, function()
		part:Destroy()
	end)
	
end)

pickaxeSfxEvent.OnServerEvent:Connect(function(player, sfx, hrp)
	miningEffectsEvent:FireAllClients(sfx, hrp)
end)