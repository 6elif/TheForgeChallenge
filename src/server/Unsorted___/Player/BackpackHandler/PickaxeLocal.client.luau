local RepStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local animationManager = require(RepStorage.Modules.AnimationManager)

local hitEvent = RepStorage.Events.Hit
local pickaxeSfxEvent = RepStorage.Events.PickaxeSFX
local destroyingPickaxe = RepStorage.Events.DestroyingPickaxe

local pick = script.Parent
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:FindFirstChild("Humanoid")
local animator = hum:FindFirstChild("Animator")

local swing = 2
local dBounce = false
local isHoldingM1 = false

local function playImpactShake(intensity, speed, direction, hitDuration)
	local camera = workspace.CurrentCamera
	local startTime = os.clock()
	local hitDuration = hitDuration or 0.2
	local returnDuration = 0.1
	local totalDuration = hitDuration + returnDuration

	local lastOffset = 0

	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local currentOffset = 0

		if elapsed < hitDuration then
			local alpha = elapsed / hitDuration
			currentOffset = alpha * intensity * direction
		elseif elapsed < totalDuration then
			local returnElapsed = elapsed - hitDuration
			local alpha = returnElapsed / returnDuration
			local quadAlpha = 1 - (alpha * alpha)

			currentOffset = quadAlpha * intensity * direction
		else
			camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(-lastOffset), 0)
			connection:Disconnect()
			return
		end

		local delta = currentOffset - lastOffset
		camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(delta), 0)
		lastOffset = currentOffset
	end)
end

local function hit()
	swing = 3 - swing
	local track = animationManager:PlaySwing(swing)
	
	task.delay(0.3, function()
		playImpactShake(1, 5, (swing == 1) and 1 or 2, (swing == 2) and 0.4)
	end)
	local mark1 = track:GetMarkerReachedSignal("SwingStart"):Connect(function()
		pickaxeSfxEvent:FireServer("SwingSFX", char:FindFirstChild("HumanoidRootPart"))
	end)

	local mark2 = track:GetMarkerReachedSignal("Hit"):Connect(function()
		hitEvent:FireServer(pick)
	end)

	track.Ended:Wait()

	mark1:Disconnect()
	mark2:Disconnect()
	mark1 = nil
	mark2 = nil
	dBounce = false
end

pick.Equipped:Connect(function()
	pickaxeSfxEvent:FireServer("EquipSFX", char:FindFirstChild("HumanoidRootPart"))
	
	animationManager:SetEquipped(true)
end)

pick.Unequipped:Connect(function()
	pickaxeSfxEvent:FireServer("UnequipSFX", char:FindFirstChild("HumanoidRootPart"))
	animationManager:SetEquipped(false)
end)

pick.Activated:Connect(function()	
	repeat
		if dBounce then continue end
		dBounce = true
		hit()
	until not isHoldingM1
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 or 
	   input.UserInputType == Enum.UserInputType.Touch then
		isHoldingM1 = true
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or 
	   input.UserInputType == Enum.UserInputType.Touch then
		isHoldingM1 = false
	end
end)

destroyingPickaxe.OnClientInvoke = function()
	animationManager.IsPickaxeEquipped = false
end