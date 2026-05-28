local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AnimationManager = require(script.Parent.Parent.Managers.AnimationManager)
local SoundManager = require(script.Parent.Parent.Managers.SoundManager)

local PickaxeComponent = {}
PickaxeComponent.__index = PickaxeComponent

local function playImpactShake(intensity, speed, direction, hitDuration)
	local camera = workspace.CurrentCamera
	local startTime = os.clock()
	local duration = hitDuration or 0.2
	local returnDuration = 0.1
	local totalDuration = duration + returnDuration

	local lastOffset = 0

	local connection
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		local currentOffset = 0

		if elapsed < duration then
			local alpha = elapsed / duration
			currentOffset = alpha * intensity * direction
		elseif elapsed < totalDuration then
			local returnElapsed = elapsed - duration
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

function PickaxeComponent.new(toolInstance : Tool)
    local self = setmetatable({}, PickaxeComponent)

    self.Pickaxe = toolInstance
    self.Handle = toolInstance:WaitForChild("Handle", 5)
    self.InputConnections = {}
    self.Connections = {}

    self:Start()

    return self
end

function PickaxeComponent:Init()
    local eventsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Network"):WaitForChild("Events")

	self.EffectsEvent = eventsFolder:WaitForChild("Effects")
    self.PickaxeHitEvent = eventsFolder:WaitForChild("PickaxeHit")
	self.DestroyPickaxeEvent = eventsFolder:WaitForChild("DestroyPickaxe")

	self.Player = Players.LocalPlayer
	self.Character = self.Player.Character or self.Player.CharacterAdded:Wait()
end

function PickaxeComponent:Start()
    self.Swing = 2
	self.IsSwinging = false
	self.IsHoldingM1 = false

    self.Connections.Equipped = self.Pickaxe.Equipped:Connect(function()
        SoundManager:PlaySound({soundName = "Equip", category = "SFX"})
        AnimationManager:SetEquipped(true)
        self:BindInputs()
    end)

    self.Connections.Unequipped = self.Pickaxe.Unequipped:Connect(function()
        SoundManager:PlaySound({soundName = "Unequip", category = "SFX"})
        AnimationManager:SetEquipped(false)
        self:UnbindInputs()
    end)

    self.Connections.Activated = self.Pickaxe.Activated:Connect(function()	
        if self.IsSwinging then return end
        self.IsSwinging = true
        self.IsHoldingM1 = true

        task.spawn(function()
            while self.IsHoldingM1 and self.IsSwinging do
                self:Hit()
            end
            self.IsSwinging = false
        end)
    end)

    self.Connections.DestroyPickaxe = self.DestroyPickaxeEvent.OnClientEvent:Connect(function()
	    AnimationManager.IsPickaxeEquipped = false
    end)
end

function PickaxeComponent:BindInputs()
    self.InputConnections.InputBegan = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.IsHoldingM1 = true
        end
    end)

    self.InputConnections.InputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.IsHoldingM1 = false
        end
    end)
end

function PickaxeComponent:UnbindInputs()
    for _, connection in pairs(self.InputConnections) do
        connection:Disconnect()
    end
    self.InputConnections = {}
    self.IsSwinging = false
end

function PickaxeComponent:Hit()
	self.Swing = 3 - self.Swing
	local track = AnimationManager:PlaySwing(self.Swing)
    SoundManager:PlaySound({soundName = "Swing", category = "SFX"})
	
	task.delay(0.3, function()
		playImpactShake(1, 5, (self.Swing == 1) and 1 or 2, (self.Swing == 2) and 0.4)
	end)

	local mark1 = track:GetMarkerReachedSignal("SwingStart"):Connect(function()
        SoundManager:PlaySound({soundName = "Swing", category = "SFX"})
	end)

	local mark2 = track:GetMarkerReachedSignal("Hit"):Connect(function()
        --SoundManager:PlaySound({soundName = "RockHit", category = "SFX"})
		self.PickaxeHitEvent:FireServer(self.Pickaxe)
	end)

	track.Ended:Wait()

	mark1:Disconnect()
	mark2:Disconnect()
	mark1 = nil
	mark2 = nil
end

function PickaxeComponent:Destroy()
    self:UnbindInputs()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}
    table.clear(self)
end

return PickaxeComponent