local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local equipItemEvent = RepStorage.Assets.Network.Events.EquipItem

-- Hide default
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local pickaxeFolder = RepStorage.Assets.Models.Pickaxes

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:FindFirstChild("Humanoid")
local backpack = player.Backpack

local playerGui = player:WaitForChild("PlayerGui")
local hotbarGui = playerGui:WaitForChild("HotbarGui")
local hotbarFrame = hotbarGui.HotbarFrame
local hotbarInventoryFrame = hotbarGui.HotbarInventoryFrame
local inventoryFrame = hotbarGui.Parent.InventoryGui.MainFrame

local DEFAULT_SLOT_SIZE = hotbarFrame.Slot0.Size

local slotKeys = {
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
	[Enum.KeyCode.R] = "R"
}

local hotbarSlots = {
	[1] = nil,
	[2] = nil,
	[3] = nil,
	[4] = nil,
	[5] = nil,
	[6] = nil,
	[7] = nil,
	[8] = nil,
	[9] = nil,
	[0] = nil,
	["R"] = nil,
}

local currentlyEquipped = {}
local connectionTrackers = {}

local holdingFrame = false
local wasHoldingItem = false
-- functions
local handleTool, changeToolSlot

local function popUpAnim(gui, defaultSize, out)
	if currentlyEquipped[gui] then return end

	local tween, info
	if out then
		info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween = TweenService:Create(gui, info, {Size = UDim2.new(defaultSize.X.Scale * 1.1, 0, defaultSize.Y.Scale * 1.1, 0)})
	else
		info = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		tween = TweenService:Create(gui, info, {Size = defaultSize})
	end

	tween:Play()
end

local function addAnims(gui, defaultSize, slot)
	local tracker = {
		enter = nil,
		leave = nil,
		visible = nil
	}

	local function cleanup()
		if tracker.enter then tracker.enter:Disconnect() end
		if tracker.leave then tracker.leave:Disconnect() end
		if tracker.visible then tracker.visible:Disconnect() end
		connectionTrackers[gui] = nil
	end

	local movableFrame = gui:FindFirstChild("MovableFrame")
	local button = if movableFrame then movableFrame.Button else gui.Button

	tracker.enter = button.MouseEnter:Connect(function()
		if slot and not hotbarSlots[slot] then 
			cleanup()
			return 
		end
		popUpAnim(gui, defaultSize, true)
	end)

	tracker.leave = button.MouseLeave:Connect(function()
		popUpAnim(gui, defaultSize, false)
	end)

	tracker.visible = gui:GetPropertyChangedSignal("Visible"):Connect(function()
		if not gui.Visible then
			cleanup()
		end
	end)
	
	connectionTrackers[gui] = tracker
end

local function removeToolFromGui(tool, slot)
	local slotName = "Slot".. slot
	local slotFrame = hotbarFrame:FindFirstChild(slotName)

	slotFrame.MovableFrame.Button.Text.Visible = false
	slotFrame.MovableFrame.Button.View.Visible = false
	if not hotbarInventoryFrame.Visible then
		slotFrame.Visible = false
	end

	hotbarSlots[slot] = nil
end

local function moveFrame(frame, fromInventory)
	holdingFrame = true
	frame.ZIndex = 10

	if fromInventory then
		hotbarInventoryFrame.ZIndex = 4
	end

	local holdingCon 
	holdingCon = RunService.RenderStepped:Connect(function()
		local mouseLocation = UIS:GetMouseLocation()
		local relativeX = mouseLocation.X - frame.AbsolutePosition.X
		local relativeY = mouseLocation.Y - frame.AbsolutePosition.Y

		local inset = GuiService:GetGuiInset()
		relativeX -= inset.X
		relativeY -= inset.Y

		frame.MovableFrame.Position = UDim2.fromOffset(relativeX, relativeY)

		if not holdingFrame then
			frame.ZIndex = 1

			if fromInventory then
				hotbarInventoryFrame.ZIndex = 2
			end

			holdingCon:Disconnect()
			holdingCon = nil
		end
	end)
end

local function handleToolInHotbarInventory(frame, tool)
	local tracker = {
		pressed = nil,
		unpressed = nil
	}
	
	addAnims(frame.MovableFrame, UDim2.new(1, 0, 1, 0))

	tracker.pressed = frame.MovableFrame.Button.MouseButton1Down:Connect(function()
		if not hotbarInventoryFrame.Visible then return end
		moveFrame(frame, true)
	end)

	tracker.unpressed = frame.MovableFrame.Button.MouseButton1Up:Connect(function()
		if hotbarInventoryFrame.Visible and holdingFrame then
			changeToolSlot(frame, tool)
		end
	end)

	connectionTrackers[frame] = tracker
end

changeToolSlot = function(frame, tool, currentSlot)
	holdingFrame = false

	local mousePos = UIS:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	local objectsAtMousePos = playerGui:GetGuiObjectsAtPosition(mousePos.X - inset.X, mousePos.Y - inset.Y)

	local previousLocation = frame.Parent
	local newLocation, newSlotName
	for _, obj in ipairs(objectsAtMousePos) do

		for i = 1, 11 do
			local s = i
			if i == 10 then
				s = 0
			elseif i == 11 then
				s = "R"
			end
			local name = "Slot".. s

			if obj == hotbarFrame[name] then
				newLocation = obj
				newSlotName = s
				break
			end
		end

		if obj ~= hotbarInventoryFrame.ActualInventory then continue end

		newLocation = obj
	end

	while frame.ZIndex ~= 1 do
		task.wait()
	end

	if not newLocation or previousLocation == newLocation then
		-- put it back where it was
		frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
		return
	end

	if newLocation == hotbarInventoryFrame.ActualInventory then
		local frameCopy = frame:Clone()
		frameCopy.MovableFrame.Button.Number.Visible = false
		frameCopy.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
		frameCopy.Parent = newLocation

		hotbarSlots[currentSlot] = nil

		frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
		frame.MovableFrame.Button.Text.Visible = false
		for _, child in ipairs(frame.MovableFrame.Button.View:GetChildren()) do
			child:Destroy()
		end

		if tool.Parent == char then
			wasHoldingItem = true
			equipItemEvent:FireServer(tool, false)
		end

		handleToolInHotbarInventory(frameCopy, tool)

	elseif newLocation:IsDescendantOf(hotbarFrame) then
		-- doesn't work yet
		if hotbarSlots[newSlotName] then
			--[[
		
			frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)

			-- Store frame 1 stuff
			local frame1Parts = {}
			for _, child in ipairs(frame.MovableFrame.Button.View:GetChildren()) do
				table.insert(frame1Parts, child)
				child.Parent = nil
			end
			local frame1Text = frame.MovableFrame.Button.Text.Text


			-- Put the frame 2 stuff into frame 1
			local button = newLocation.MovableFrame.Button
			local view = button.View
			for _, child in ipairs(view:GetChildren()) do
				child.Parent = frame.MovableFrame.Button.View
			end
			-- change frame 1 texts + hotkey
			frame.MovableFrame.Button.Text.Text = button.Text.Text
			-- current tool              -- new tool
			hotbarSlots[currentSlot] = hotbarSlots[newSlotName]

			-- Put the frame 1 stuff into frame 2
			for _, part in ipairs(frame1Parts) do
				part.Parent = view
			end
			-- change frame 2 texts + hotkey
			button.Text.Text = frame1Text
			hotbarSlots[newSlotName] = tool

			-- new tool = new logic for the rest of the scripts
			tool = hotbarSlots[currentSlot]
			]]--
			warn("Not yet")
			frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)

		else
			-- Put tool in empty slot
			frame.MovableFrame.Position = UDim2.fromScale(0.5, 0.5)
			if currentSlot then
				removeToolFromGui(tool, currentSlot)
			else
				print(currentSlot)
				frame:Destroy()
			end

			hotbarSlots[newSlotName] = tool
			handleTool(tool, newSlotName)

		end
	end
end

handleTool = function(tool, currentSlot)
	hotbarSlots[currentSlot] = tool

	local pickaxeInHotbar = pickaxeFolder.ForHotbar:FindFirstChild(tool.Name):Clone()

	if not pickaxeInHotbar then return end

	local currentSlotName = "Slot".. currentSlot
	local slotFrame = hotbarFrame:FindFirstChild(currentSlotName)

	if not slotFrame then
		warn("No slot found")
	end

	local view = slotFrame.MovableFrame.Button.View
	local text = slotFrame.MovableFrame.Button.Text

	for _, child in ipairs(view:GetChildren()) do
		child:Destroy()
	end

	text.Text = "Pickaxe"
	pickaxeInHotbar.Parent = view
	text.Visible = true
	view.Visible = true
	slotFrame.Visible = true

	local defaultSize = DEFAULT_SLOT_SIZE

	addAnims(slotFrame, defaultSize, currentSlot)

	if not slotFrame:FindFirstChild("MovableFrame") then 
		return defaultSize, slotFrame
	end

	local tracker = {
		pressed = nil,
		unpressed = nil,
		visible = nil,
		tool = nil
	}

	local function cleanup()
		if tracker.pressed then tracker.pressed:Disconnect() end
		if tracker.unpressed then tracker.unpressed:Disconnect() end
		if tracker.visible then tracker.visible:Disconnect() end
		if tracker.tool then tracker.tool:Disconnect() end
		connectionTrackers[slotFrame] = nil
	end

	tracker.pressed = slotFrame.MovableFrame.Button.MouseButton1Down:Connect(function()
		if not hotbarInventoryFrame.Visible then return end
		moveFrame(slotFrame)
	end)

	tracker.unpressed = slotFrame.MovableFrame.Button.MouseButton1Up:Connect(function()
		if hotbarInventoryFrame.Visible and holdingFrame then
			changeToolSlot(slotFrame, tool, currentSlot)
		elseif not hotbarInventoryFrame.Visible then
			if tool.Parent == backpack then
				equipItemEvent:FireServer(tool, true)
			elseif tool.Parent == char then
				equipItemEvent:FireServer(tool, false)
			end
		end
	end)

	tracker.tool = tool:GetPropertyChangedSignal("Parent"):Connect(function()
		if tool.Parent == nil then
			removeToolFromGui(tool, currentSlot)
			cleanup()
			currentlyEquipped[slotFrame] = nil
			popUpAnim(slotFrame, defaultSize, false)
		elseif tool.Parent == char then
			popUpAnim(slotFrame, defaultSize, true)
			currentlyEquipped[slotFrame] = true
		elseif tool.Parent == backpack then
			currentlyEquipped[slotFrame] = nil
			popUpAnim(slotFrame, defaultSize, false)
		end
	end)

	tracker.visible = slotFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if not slotFrame.Visible then
			cleanup()
		end
	end)

	connectionTrackers[slotFrame] = tracker
	return defaultSize, slotFrame
end

backpack.ChildAdded:Connect(function(tool)
	if wasHoldingItem then
		wasHoldingItem = false
		return
	end
	local slot = 1
	for i = 1, 11 do

		local hotbarSlot
		if i == 10 then
			hotbarSlot = 0
		elseif i == 11 then
			hotbarSlot = "R"
		else
			hotbarSlot = i
		end

		if not hotbarSlots[hotbarSlot] then
			slot = hotbarSlot
			break
		end
	end

	local alreadyInHotbar = false
	for _, toolInHotbar in pairs(hotbarSlots) do
		if toolInHotbar == tool then
			alreadyInHotbar = true
		end
	end

	if alreadyInHotbar then return end

	handleTool(tool, slot)
end)

local function openHotbarInventoryFrame()
	if not hotbarInventoryFrame.Visible then
		hotbarInventoryFrame.Visible = true

		for _, frame in ipairs(hotbarFrame:GetChildren()) do
			if not frame:IsA("Frame") then continue end

			frame.Visible = true
		end

	else
		for _, frame in ipairs(hotbarFrame:GetChildren()) do
			if not frame:IsA("Frame") then continue end
			local slot = frame.Name:gsub("Slot", "")
			if slot == "Inventory" then continue end

			if slot ~= "R" then
				slot = tonumber(slot)
			end
			slot = hotbarSlots[slot]

			if slot == nil then
				frame.Visible = false
			end
		end
		hotbarInventoryFrame.Visible = false
	end
end

-- For inventory
addAnims(hotbarFrame.InventorySlot, hotbarFrame.InventorySlot.Size)
hotbarFrame.InventorySlot.Button.Activated:Connect(function()
	if not inventoryFrame.Visible then
		inventoryFrame.Visible = true
	else
		inventoryFrame.Visible = false
	end
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end


	if input.KeyCode == Enum.KeyCode.Backquote then
		openHotbarInventoryFrame()
		return
	elseif input.KeyCode == Enum.KeyCode.T then
		if not inventoryFrame.Visible then
			inventoryFrame.Visible = true
			popUpAnim(hotbarFrame.InventorySlot, DEFAULT_SLOT_SIZE, true)
		
			while inventoryFrame.Visible do task.wait() end
			
			popUpAnim(hotbarFrame.InventorySlot, DEFAULT_SLOT_SIZE, false)
		else
			inventoryFrame.Visible = false
		end
	end

	local slotNum = slotKeys[input.KeyCode]
	if not slotNum then return end

	local tool = hotbarSlots[slotNum]

	if not tool then return end

	if tool.Parent == backpack then
		hum:EquipTool(tool)
	elseif tool.Parent == char then
		hum:UnequipTools()
	end
end)