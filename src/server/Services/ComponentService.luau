local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local DisplayPickaxeComponent = require(ServerScriptService.Server.Components.DisplayPickaxeComponent)

local ComponentService = {}

function ComponentService:OnDisplayPickaxeAdded(instance)
    if not self.ActiveComponents[instance] then
            self.ActiveComponents[instance] = true
            DisplayPickaxeComponent.new(instance)
        end
end

function ComponentService:Init()
    self.ActiveComponents = {}
end

function ComponentService:Start()
    CollectionService:GetInstanceAddedSignal("DisplayPickaxe"):Connect(function(instance)
        self:OnDisplayPickaxeAdded(instance)
    end)

    for _, instance in ipairs(CollectionService:GetTagged("DisplayPickaxe")) do
        self:OnDisplayPickaxeAdded(instance)
    end
end

return ComponentService