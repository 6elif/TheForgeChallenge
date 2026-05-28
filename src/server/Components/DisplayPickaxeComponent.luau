local ServerScriptService = game:GetService("ServerScriptService")

local EquipmentService = require(ServerScriptService.Server.Services.EquipmentService)

local DisplayPickaxeComponent = {}
DisplayPickaxeComponent.__index = DisplayPickaxeComponent

function DisplayPickaxeComponent.new(instance)
	local self = setmetatable({}, DisplayPickaxeComponent)

    self.Instance = instance
    self.Handle = instance:WaitForChild("Handle", 5)
    self.ProximityPrompt = self.Handle and self.Handle:WaitForChild("ProximityPrompt", 5)
    self.Connection = nil
    
    self:Init()

    return self
end

function DisplayPickaxeComponent:Init()
    if not self.Handle then return end
    if not self.ProximityPrompt then 
        self.ProximityPrompt = Instance.new("ProximityPrompt")
        self.ProximityPrompt.Parent = self.Handle
    end

    self.Connection = self.ProximityPrompt.Triggered:Connect(function(player)
        EquipmentService:EquipPickaxe(player, self.Instance)
    end)
end

return DisplayPickaxeComponent
