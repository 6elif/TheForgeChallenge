local UserInputService = game:GetService("UserInputService")

local Hotbar = require(script.Hotbar)
local Inventory = require(script.Inventory)

local UIController = {}

function UIController:Init()
    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    Hotbar:Init()
    Inventory:Init()

    self.ActiveFrame = nil
end

function UIController:Start()
    Hotbar:Start()
    Inventory:Start()

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
end

function UIController:ToggleWindow(windowName: string)
    if self.ActiveWindow == windowName then
        if windowName == "Inventory" then
          Inventory:SetVisible(false)
        elseif windowName == "Hotbar" then
            Hotbar:ToggleHotbarInventoryFrame(false)
        end
        self.ActiveWindow = nil
        
    else
        if self.ActiveWindow == "Inventory" then
            Inventory:SetVisible(false)
        elseif self.ActiveWindow == "Hotbar" then
            Hotbar:ToggleHotbarInventoryFrame(false)
        end

        if windowName == "Inventory" then
            Inventory:SetVisible(true)
        elseif windowName == "Hotbar" then
            Hotbar:ToggleHotbarInventoryFrame(true)
        end
        self.ActiveWindow = windowName
    end
end

return UIController