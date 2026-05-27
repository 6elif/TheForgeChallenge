local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Hotbar = require(script.Hotbar)
local Inventory = require(script.Inventory)
local SellingMenu = require(script.SellingMenu)
local Notifications = require(script.Notifications)
local Forge = require(script.Forge)

local UIController = {}

function UIController:Init()
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    Hotbar:Init()
    Inventory:Init()
    SellingMenu:Init()
    Notifications:Init()
    Forge:Init()

    self.ActiveWindow = nil
end

function UIController:Start()
    Hotbar:Start()
    Inventory:Start()
    SellingMenu:Start()
    Notifications:Start()

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        if input.KeyCode == Enum.KeyCode.Backquote then
            self:ToggleWindow("Hotbar")
            
        elseif input.KeyCode == Enum.KeyCode.T then
            self:ToggleWindow("Inventory")
            
        elseif Hotbar.SLOT_KEYCODES[input.KeyCode] then
            local slotNum = Hotbar.SLOT_KEYCODES[input.KeyCode]

            if not slotNum then return end
            Hotbar:SelectSlot(slotNum)
        end
    end)

    Inventory.CloseRequested.Event:Connect(function()
        self:ToggleWindow("Inventory") 
    end)

    Hotbar.InventoryToggleRequested.Event:Connect(function()
        self:ToggleWindow("Inventory") 
    end)

    SellingMenu.CloseRequested.Event:Connect(function()
        self:ToggleWindow("SellingMenu") 
    end)

    Forge.ForgeToggleRequested.Event:Connect(function()
        self:ToggleWindow("Forge")
    end)

    local function setupSellingPrompt(prompt)
        if not prompt:IsA("ProximityPrompt") then return end
        
        prompt.Triggered:Connect(function()
            self:ToggleWindow("SellingMenu")
        end)
    end

    CollectionService:GetInstanceAddedSignal("ForgeModel"):Connect(function(model)
        Forge:Start(model)
    end)

    CollectionService:GetInstanceAddedSignal("SellingMenu"):Connect(function(obj)
        setupSellingPrompt(obj)
    end)

    for _, obj in ipairs(CollectionService:GetTagged("SellingMenu")) do
        setupSellingPrompt(obj)
    end

    for _, model in ipairs(CollectionService:GetTagged("ForgeModel")) do
        Forge:Start(model)
    end
end

function UIController:ToggleWindow(windowName: string)
    if self.ActiveWindow == windowName then
        if windowName == "Inventory" then
          Inventory:SetVisible(false)
        elseif windowName == "Hotbar" then
            Hotbar:ToggleHotbarInventoryFrame(false)
        elseif windowName == "SellingMenu" then
            SellingMenu:SetVisible(false)
        elseif windowName == "Forge" then
            Forge:CloseForgeGui()
        end

        self.ActiveWindow = nil
        
    else
        if self.ActiveWindow == "Inventory" then
            Inventory:SetVisible(false)
        elseif self.ActiveWindow == "Hotbar" then
            Hotbar:ToggleHotbarInventoryFrame(false)
        elseif self.ActiveWindow == "SellingMenu" then
            SellingMenu:SetVisible(false)
        elseif self.ActiveWindow == "Forge" then
            Forge:CloseForgeGui()
        end

        self.ActiveWindow = windowName
        
        if windowName == "Inventory" then
            Inventory:SetVisible(true)
        elseif windowName == "Hotbar" then
            Hotbar:ToggleHotbarInventoryFrame(true)
        elseif windowName == "SellingMenu" then
            SellingMenu:SetVisible(true)
        elseif windowName == "Forge" then
            Forge:OpenForgeGui()
        end
    end
end

return UIController