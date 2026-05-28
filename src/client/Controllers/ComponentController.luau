local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PickaxeComponent = require(script.Parent.Parent.Components.PickaxeComponent)

local ComponentController = {}

function ComponentController:Init()
    self.Player = Players.LocalPlayer
    self.ActiveComponents = {}
end

function ComponentController:Start()
    if PickaxeComponent.Init then
        PickaxeComponent:Init()
    end

    local function onToolAdded(tool: Instance)
    if not tool:IsA("Tool") then return end
    if self.ActiveComponents[tool] then return end
    
    local isLocalTool = tool:IsDescendantOf(self.Player.Backpack) or (self.Player.Character and tool:IsDescendantOf(self.Player.Character))
    if not isLocalTool then return end
    
    self.ActiveComponents[tool] = PickaxeComponent.new(tool)
end

    local function onToolRemoved(tool: Instance)
        local component = self.ActiveComponents[tool]
        if component then
            component:Destroy()
            self.ActiveComponents[tool] = nil
        end
    end

    CollectionService:GetInstanceAddedSignal("PickaxeTool"):Connect(onToolAdded)
    CollectionService:GetInstanceRemovedSignal("PickaxeTool"):Connect(onToolRemoved)

    for _, tool in ipairs(CollectionService:GetTagged("PickaxeTool")) do
        task.spawn(onToolAdded, tool)
    end
end

return ComponentController