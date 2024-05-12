local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local sizeTweenInfo = TweenInfo.new(0.15)

local Digit = {}

function Digit.new(Spinner, LayoutOrder, Value)
	local digit = {
		Duration = Spinner.Duration,
		Value = Value,

		Labels = table.create(10),
		CanvasTweens = table.create(10),
	}
	local tweenInfo = TweenInfo.new(Spinner.Duration)

	local Frame = Instance.new("Frame")
	Frame.Name = "digit"
	Frame.LayoutOrder = LayoutOrder
	Frame.BackgroundTransparency = 1
	Frame.Size = UDim2.new(0, 0, 0, Spinner.TextSize + 6)
	Frame.ClipsDescendants = true

	local Canvas = Instance.new("Frame")
	Canvas.Name = "canvas"
	Canvas.Size = UDim2.new(1, 0, 10, 0)
	Canvas.BackgroundTransparency = 1
	Canvas.Parent = Frame

	Canvas.Position = UDim2.new(0, 0, -digit.Value, 0)

	for i = 0, 9 do
		local n = Instance.new("TextLabel")
		n.Name = "n_" .. i
		n.BackgroundTransparency = 1
		n.TextSize = Spinner.TextSize
		n.TextColor3 = Spinner.TextColor3
		n.FontFace = Spinner.FontFace
		n.Text = i
		n.Size = UDim2.new(1, 0, 0.1, 0)
		n.Position = UDim2.new(0, 0, i * 0.1, 0)
		n.Parent = Canvas
		digit.Labels[i] = n
		digit.CanvasTweens[i] = TweenService:Create(Canvas, tweenInfo, { Position = UDim2.new(0, 0, -i, 0) })
	end

	Frame.Parent = Spinner.Frame

	local TextBoundsParams = Instance.new("GetTextBoundsParams")

	local function updateSize(shouldDelete)
		task.spawn(function()
			TextBoundsParams.Text = "8"
			TextBoundsParams.Font = Spinner.FontFace
			TextBoundsParams.Size = Spinner.TextSize
			TextBoundsParams.Width = Spinner.TextSize

			-- Errors like "Temp read failed." can occur for some circumstances.
			local success, textBounds = pcall(TextService.GetTextBoundsAsync, TextService, TextBoundsParams)
			if success then
				local tween = TweenService:Create(
					Frame,
					sizeTweenInfo,
					{ Size = UDim2.new(0, if shouldDelete then 0 else textBounds.X + 1, 0, textBounds.Y + 10) }
				)
				tween.Completed:Connect(function()
					if shouldDelete then
						Frame:Destroy()
						table.clear(digit)
					end
					tween:Destroy()
				end)
				tween:Play()
			end
		end)
	end

	updateSize()

	local digitProxy = setmetatable({}, {
		__index = function(_, key)
			local Direct = digit[key]
			if Direct then
				return Direct
			end

			local propExistsForLabel = pcall(function()
				local _ = digit.Labels[1][key]
			end)
			if propExistsForLabel then
				return digit.Labels[1][key]
			end

			return nil
		end,
		__newindex = function(_, key, value)
			local Direct = digit[key]
			if Direct then
				digit[key] = value
				digit:Update(key, value)
				return
			end

			local propExistsForLabel = pcall(function()
				local _ = digit.Labels[1][key]
			end)
			if propExistsForLabel then
				for i = 0, 9 do
					digit.Labels[i][key] = value
				end
				digit:Update(key, value)
			end
		end,
	})

	function digit:Destroy()
		updateSize(true)
	end

	function digit:Update(Type, UpdateValue)
		if Type == "Duration" then
			tweenInfo = TweenInfo.new(UpdateValue)
			for i = 0, 9 do
				digit.CanvasTweens[i] = TweenService:Create(Canvas, tweenInfo, { Position = UDim2.new(0, 0, -i, 0) })
			end
		elseif Type == "Value" then
			digit.CanvasTweens[UpdateValue]:Play()
		elseif Type == "TextSize" or Type == "FontFace" then
			updateSize()
		end
	end

	return digitProxy
end

return Digit
