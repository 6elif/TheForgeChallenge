local clientFolder = script.Parent
local controllerFolder = clientFolder:WaitForChild("Controllers")

local controllers = {}

for _, controller in ipairs(controllerFolder:GetChildren()) do
    if controller:IsA("ModuleScript") then
        local controllerModule = require(controller)
        table.insert(controllers, controllerModule)

        if controllerModule.Init then
            controllerModule.Init()
        end
    end
end

for _, controller in ipairs(controllers) do
    if controller.Start then
        task.spawn(controller.Start)
    end
end