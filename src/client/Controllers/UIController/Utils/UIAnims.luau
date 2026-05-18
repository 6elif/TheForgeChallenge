local TweenService = game:GetService("TweenService")

local hoverInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local unHoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local buttonsHandled = {}

local UIAnims = {}

function UIAnims.PopUpAnim(gui, defaultSize, out)
	local tween, info
	if out then
		info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		tween = TweenService:Create(gui, info, {Size = UDim2.new(defaultSize.X.Scale * 1.1, 0, defaultSize.Y.Scale * 1.1, 0)})
	else
		info = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		tween = TweenService:Create(gui, info, {Size = defaultSize})
	end

	tween:Play()
    return tween
end

function UIAnims.AddAnimationsToButton(button : GuiButton, data)
	local defaultSize : UDim2 = data.defaultSize
	local maxSize : UDim2 = data.maxSize or UDim2.fromScale(defaultSize.X.Scale * 1.05, defaultSize.Y.Scale * 1.05)
	local minSize : UDim2 = data.minSize or UDim2.fromScale(defaultSize.X.Scale * 0.95, defaultSize.Y.Scale * 0.95)
	
	local actualButton
	if data.frameInsteadOfButton then
		actualButton = button
		button = data.frameInsteadOfButton
	end
	
	local hoverTween = TweenService:Create(button, hoverInfo, {Size = maxSize})
	local unHoverTween = TweenService:Create(button, unHoverInfo, {Size = defaultSize})
	local pressedTween = TweenService:Create(button, unHoverInfo, {Size = minSize})
	
	if actualButton then button = actualButton end
	
	local cons = {
		enter = nil,
		leave = nil,
		down = nil,
		up = nil
	}

	cons.enter = button.MouseEnter:Connect(function()
		hoverTween:Play()
	end)
	
	cons.leave = button.MouseLeave:Connect(function()
		unHoverTween:Play()
	end)
	
	cons.down =  button.MouseButton1Down:Connect(function()
		pressedTween:Play()
	end)
	
	cons.up = button.MouseButton1Up:Connect(function()
		hoverTween:Play()
	end)
	
	buttonsHandled[button] = cons
end

function UIAnims.CleanUp(button)
	if buttonsHandled[button] then 
		for _, con in pairs(buttonsHandled[button]) do
			con:Disconnect()
		end
		buttonsHandled[button] = nil
	end
end

return UIAnims