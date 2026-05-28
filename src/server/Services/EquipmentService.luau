local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EquipmentService = {}

function EquipmentService:EquipPickaxe(player: Player, pickaxe)
    local inventory = player:FindFirstChild("Inventory")
    local equippedPickaxe = inventory and inventory:FindFirstChild("EquippedPickaxe")
    
    if equippedPickaxe then
        equippedPickaxe.Value = pickaxe.Name
    end
end

function EquipmentService:GiveTool(player: Player, pickaxeName: string)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    if not backpack then return end

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then item:Destroy() end
    end
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then item:Destroy() end
        end
    end

    if pickaxeName == "" then return end

    local toolTemplate = self.PickaxeFolder.Tools:FindFirstChild(pickaxeName)
    if not toolTemplate then 
        warn("Pickaxe not found in ReplicatedStorage: " .. tostring(pickaxeName))
        return 
    end

    local pickaxeTool = toolTemplate:Clone()
    pickaxeTool:AddTag("PickaxeTool")
    pickaxeTool.Parent = backpack
end

function EquipmentService:OnPlayerAdded(player: Player)
    if self.PlayersTracked[player] then return end
    self.PlayersTracked[player] = true
    
    local inventory = player:WaitForChild("Inventory", 10)
    local equippedPickaxe = inventory and inventory:WaitForChild("EquippedPickaxe", 10)
    if not equippedPickaxe then return end

    equippedPickaxe:GetPropertyChangedSignal("Value"):Connect(function()
        self.DestroyPickaxeEvent:FireClient(player)
        self:GiveTool(player, equippedPickaxe.Value)
    end)

    player.CharacterAdded:Connect(function()
        if equippedPickaxe.Value ~= "" then
            self:GiveTool(player, equippedPickaxe.Value)
        end
    end)
end

function EquipmentService:Init()
    self.DestroyPickaxeEvent = ReplicatedStorage.Assets.Network.Events.DestroyPickaxe
    self.EquipItemEvent = ReplicatedStorage.Assets.Network.Events.EquipItem

    self.PickaxeFolder = ReplicatedStorage.Assets.Models.Pickaxes
    self.PlayersTracked = {}
end

function EquipmentService:Start()
    self.EquipItemEvent.OnServerEvent:Connect(function(player, pickaxeName)
        if type(pickaxeName) == "string" then
            self:EquipPickaxe(player, pickaxeName)
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self.PlayersTracked[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:OnPlayerAdded(player)
        end)
    end
end

return EquipmentService