local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RepStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local UIAnims = require(script.Parent.Utils.UIAnims)

local Hotbar = {}

Hotbar.InventoryToggleRequested = Instance.new("BindableEvent")

local pickaxeFolder = RepStorage.Assets.Models.Pickaxes

Hotbar.SLOT_ORDER = {1, 2, 3, 4, 5, 6, 7, 8, 9, 0, "R"}

Hotbar.SLOT_KEYCODES = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
	[Enum.KeyCode.Zero] = 0,
	[Enum.KeyCode.R] = "R",
}

function Hotbar:AddAnims(gui, defaultSize, slot)
    local tracker = { enter = nil, leave = nil, visible = nil }

    local function cleanup()
        if tracker.enter then tracker.enter:Disconnect() end
        if tracker.leave then tracker.leave:Disconnect() end
        if tracker.visible then tracker.visible:Disconnect() end
        self.ConnectionTrackers[gui] = nil
    end

    local movableFrame = gui:FindFirstChild("MovableFrame")
    local button = if movableFrame then movableFrame.Button else gui.Button

    tracker.enter = button.MouseEnter:Connect(function()
        if slot and not self.HotbarSlots[slot] then 
            cleanup()
            return 
        end
        UIAnims.PopUpAnim(gui, defaultSize, true)
    end)

    tracker.leave = button.MouseLeave:Connect(function()
        UIAnims.PopUpAnim(gui, defaultSize, false)
    end)

    tracker.visible = gui:GetPropertyChangedSignal("Visible"):Connect(function()
        if not gui.Visible then cleanup() end
    end)
    
    self.ConnectionTrackers[gui] = tracker
end

function Hotbar:RemoveToolFromGui(tool, slot)
    local slotName = "Slot" .. slot
    local slotFrame = self.HotbarFrame:FindFirstChild(slotName)

    slotFrame.MovableFrame.Button.Text.Visible = false
    slotFrame.MovableFrame.Button.View.Visible = false
    if not self.HotbarInventoryFrame.Visible then
        slotFrame.Visible = false
    end

    self.HotbarSlots[slot] = nil
end

function Hotbar:MoveFrame(frame, fromInventory)
    self.HoldingFrame = true
    frame.ZIndex = 10

    if fromInventory then
        self.HotbarInventoryFrame.ZIndex = 4
    end

    local holdingCon 
    holdingCon = RunService.RenderStepped:Connect(function()
        local mouseLocation = UserInputService:GetMouseLocation()
        local relativeX = mouseLocation.X - frame.AbsolutePosition.X
        local relativeY = mouseLocation.Y - frame.AbsolutePosition.Y

        local inset = GuiService:GetGuiInset()
        relativeX -= inset.X
        relativeY -= inset.Y

        frame.MovableFrame.Position = UDim2.fromOffset(relativeX, relativeY)

        if not self.HoldingFrame then
            frame.ZIndex = 1

            if fromInventory then
                self.HotbarInventoryFrame.ZIndex = 2
            end

            holdingCon:Disconnect()
            holdingCon = nil
        end
    end)
end

function Hotbar:HandleToolInHotbarInventory(frame, tool)
    local tracker = { pressed = nil, unpressed = nil }
    
    self:AddAnims(frame.MovableFrame, UDim2.new(1, 0, 1, 0))

    tracker.pressed = frame.MovableFrame.Button.MouseButton1Down:Connect(function()
        if not self.HotbarInventoryFrame.Visible then return end
        self:MoveFrame(frame, true)
    end)

    tracker.unpressed = frame.MovableFrame.Button.MouseButton1Up:Connect(function()
        if self.HotbarInventoryFrame.Visible and self.HoldingFrame then
            self:ChangeToolSlot(frame, tool)
        end
    end)

    self.ConnectionTrackers[frame] = tracker
end

function Hotbar:ChangeToolSlot(frame, tool, currentSlot)
    self.HoldingFrame = false

    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local objectsAtMousePos = self.PlayerGui:GetGuiObjectsAtPosition(mousePos.X - inset.X, mousePos.Y - inset.Y)

    local previousLocation = frame.Parent
    local newLocation, newSlotName
    
    for _, obj in ipairs(objectsAtMousePos) do
        for _, s in ipairs(self.SLOT_ORDER) do
            local name = "Slot" .. tostring(s)
            if obj == self.HotbarFrame[name] then
                newLocation = obj
                newSlotName = s
                break
            end
        end
        if obj == self.HotbarInventoryFrame.ActualInventory then 
            newLocation = obj
        end
    end

    while frame.ZIndex ~= 1 do task.wait() end

    if not newLocation or previousLocation == newLocation then
        frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
        return
    end

    if newLocation == self.HotbarInventoryFrame.ActualInventory then
        local frameCopy = frame:Clone()
        frameCopy.MovableFrame.Button.Number.Visible = false
        frameCopy.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
        frameCopy.Parent = newLocation

        self.HotbarSlots[currentSlot] = nil

        frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
        frame.MovableFrame.Button.Text.Visible = false
        
        for _, child in ipairs(frame.MovableFrame.Button.View:GetChildren()) do
            child:Destroy()
        end

        if tool.Parent == self.Character then
            self.WasHoldingItem = true
            self.EquipItemEvent:FireServer(tool, false)
        end

        self:HandleToolInHotbarInventory(frameCopy, tool)

    elseif newLocation:IsDescendantOf(self.HotbarFrame) then
        if self.HotbarSlots[newSlotName] then
            warn("Slot swap logic goes here!")
            frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
        else
            frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
            if currentSlot then
                self:RemoveToolFromGui(tool, currentSlot)
            else
                frame:Destroy()
            end

            self.HotbarSlots[newSlotName] = tool
            self:HandleTool(tool, newSlotName)
        end
    end
end

function Hotbar:HandleTool(tool, currentSlot)
    self.HotbarSlots[currentSlot] = tool

    local forHotbar = pickaxeFolder:FindFirstChild("ForHotbar")
    if not forHotbar then warn("ForHotbar missing") return end
    local pickaxeTemplate = forHotbar:FindFirstChild(tool.Name)
    if not pickaxeTemplate then return end
    local pickaxeInHotbar = pickaxeTemplate:Clone()

    local currentSlotName = "Slot" .. currentSlot
    local slotFrame = self.HotbarFrame:FindFirstChild(currentSlotName)
    if not slotFrame then warn("No slot found") end

    local view = slotFrame.MovableFrame.Button.View
    local text = slotFrame.MovableFrame.Button.Text

    for _, child in ipairs(view:GetChildren()) do child:Destroy() end

    text.Text = "Pickaxe"
    pickaxeInHotbar.Parent = view
    text.Visible = true
    view.Visible = true
    slotFrame.Visible = true

    local defaultSize = self.DEFAULT_SLOT_SIZE
    self:AddAnims(slotFrame, defaultSize, currentSlot)

    if not slotFrame:FindFirstChild("MovableFrame") then 
        return defaultSize, slotFrame
    end

    local tracker = { pressed = nil, unpressed = nil, visible = nil, tool = nil }

    local function cleanup()
        if tracker.pressed then tracker.pressed:Disconnect() end
        if tracker.unpressed then tracker.unpressed:Disconnect() end
        if tracker.visible then tracker.visible:Disconnect() end
        if tracker.tool then tracker.tool:Disconnect() end
        self.ConnectionTrackers[slotFrame] = nil
    end

    tracker.pressed = slotFrame.MovableFrame.Button.MouseButton1Down:Connect(function()
        if not self.HotbarInventoryFrame.Visible then return end
        self:MoveFrame(slotFrame)
    end)

    tracker.unpressed = slotFrame.MovableFrame.Button.MouseButton1Up:Connect(function()
        if self.HotbarInventoryFrame.Visible and self.HoldingFrame then
            self:ChangeToolSlot(slotFrame, tool, currentSlot)
        elseif not self.HotbarInventoryFrame.Visible then
            if tool.Parent == self.Backpack then
                self.EquipItemEvent:FireServer(tool, true)
            elseif tool.Parent == self.Character then
                self.EquipItemEvent:FireServer(tool, false)
            end
        end
    end)

    tracker.tool = tool:GetPropertyChangedSignal("Parent"):Connect(function()
        if tool.Parent == nil then
            self:RemoveToolFromGui(tool, currentSlot)
            cleanup()
            self.CurrentlyEquipped[slotFrame] = nil
            UIAnims.PopUpAnim(slotFrame, defaultSize, false)
        elseif tool.Parent == self.Character then
            UIAnims.PopUpAnim(slotFrame, defaultSize, true)
            self.CurrentlyEquipped[slotFrame] = true
        elseif tool.Parent == self.Backpack then
            self.CurrentlyEquipped[slotFrame] = nil
            UIAnims.PopUpAnim(slotFrame, defaultSize, false)
        end
    end)

    tracker.visible = slotFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not slotFrame.Visible then cleanup() end
    end)

    self.ConnectionTrackers[slotFrame] = tracker
    return defaultSize, slotFrame
end

function Hotbar:HandleBackpackChildAdded(tool)
    if self.WasHoldingItem then
        self.WasHoldingItem = false
        return
    end

    local slot = 1
    for _, hotbarSlot in ipairs(self.SLOT_ORDER) do
        if not self.HotbarSlots[hotbarSlot] then
            slot = hotbarSlot
            break
        end
    end

    local alreadyInHotbar = false
    for _, toolInHotbar in pairs(self.HotbarSlots) do
        if toolInHotbar == tool then alreadyInHotbar = true end
    end

    if alreadyInHotbar then return end
    self:HandleTool(tool, slot)
end

function Hotbar:ToggleHotbarInventoryFrame(open)
    if open then
        self.HotbarInventoryFrame.Visible = true
        for _, frame in ipairs(self.HotbarFrame:GetChildren()) do
            if not frame:IsA("Frame") then continue end
            frame.Visible = true
        end
    else
        for _, frame in ipairs(self.HotbarFrame:GetChildren()) do
            if not frame:IsA("Frame") then continue end
            local slot = frame.Name:gsub("Slot", "")
            if slot == "Inventory" then continue end

            if slot ~= "R" then slot = tonumber(slot) end
            slot = self.HotbarSlots[slot]

            if slot == nil then frame.Visible = false end
        end
        self.HotbarInventoryFrame.Visible = false
    end
end

function Hotbar:SelectSlot(slotNum)
	local tool = self.HotbarSlots[slotNum]

	if not tool then return end
	
	if tool.Parent == self.Backpack then
		self.Humanoid:EquipTool(tool)
	elseif tool.Parent == self.Character then
		self.Humanoid:UnequipTools()
	end
end

function Hotbar:Init()
    self.EquipItemEvent = RepStorage.Assets.Network.Events.EquipItem

    self.Player = Players.LocalPlayer
    self.Character = self.Player.Character or self.Player.CharacterAdded:Wait()
    self.Humanoid = self.Character:FindFirstChild("Humanoid")
    self.Backpack = self.Player.Backpack

    self.PlayerGui = self.Player:WaitForChild("PlayerGui")
    self.HotbarGui = self.PlayerGui:WaitForChild("HotbarGui")
    self.HotbarFrame = self.HotbarGui.HotbarFrame
    self.HotbarInventoryFrame = self.HotbarGui.HotbarInventoryFrame

    self.DEFAULT_SLOT_SIZE = self.HotbarFrame.Slot0.Size

    self.CurrentlyEquipped = {}
    self.ConnectionTrackers = {}
    self.HoldingFrame = false
    self.WasHoldingItem = false

    self.HotbarSlots = {
        [1] = nil, [2] = nil, [3] = nil, [4] = nil, [5] = nil,
        [6] = nil, [7] = nil, [8] = nil, [9] = nil, [0] = nil, ["R"] = nil,
    }
end

function Hotbar:Start()
    self.Backpack.ChildAdded:Connect(function(tool)
        self:HandleBackpackChildAdded(tool)
    end)
    
    self:AddAnims(self.HotbarFrame.InventorySlot, self.HotbarFrame.InventorySlot.Size)

    self.HotbarFrame.InventorySlot.Button.Activated:Connect(function()
        self.InventoryToggleRequested:Fire()
    end)
end

return Hotbar