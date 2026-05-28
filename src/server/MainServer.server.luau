local serverFolder = script.Parent
local serviceFolder = serverFolder:WaitForChild("Services")

local services = {}

for _, service in ipairs(serviceFolder:GetChildren()) do
    if service:IsA("ModuleScript") then
        local serviceModule = require(service)
        table.insert(services, serviceModule)

        if serviceModule.Init then
            serviceModule:Init()
        end
    end
end

for _, service in ipairs(services) do
    if service.Start then
        task.spawn(function()
            service:Start()
        end)
    end
end