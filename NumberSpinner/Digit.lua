local TextService = game:GetService('TextService')
local TweenService = game:GetService('TweenService')

local sizeTweenInfo = TweenInfo.new(0.15)

local Digit = {}

function Digit.new(Spinner, LayoutOrder, Value)
	local d = {
		Duration = Spinner.Duration;
		Value = Value;

		Labels = table.create(10);
		CanvasTweens = table.create(10);

		LabelsOverflow = table.create(10);
		CanvasTweensOverflow = table.create(10);
	}
	local tweenInfo = TweenInfo.new(Spinner.Duration, Enum.EasingStyle.Linear)

	local Frame = Instance.new("Frame")
	Frame.Name = "digit"
	Frame.LayoutOrder = LayoutOrder
	Frame.BackgroundTransparency = 1
	Frame.Size = UDim2.new(0,0,0,Spinner.TextSize+6)
	Frame.ClipsDescendants = true

	local Canvas = Instance.new("Frame")
	Canvas.Name = "canvas"
	Canvas.BackgroundTransparency = 1
	Canvas.Parent = Frame

	local ySteps = 20
	local ySize = 1/ySteps
	Canvas.Size = UDim2.new(1,0,ySteps,0)
	Canvas.Position = UDim2.new(0,0,-Value/2,0)

	-- what's actually displayed on the dial right now
	local function getDisplayedValue()
		local currentY = Canvas.Position.Y.Scale
		if (currentY <= -10) then
			currentY += 10
		end
		return -currentY
	end

	local function wrapAround()
		local currentY = Canvas.Position.Y.Scale;
		if (currentY <= -10) then
			-- quickly move back to the actual numbers instead of the overflow numbers
			Canvas.Position = UDim2.new(0,0,currentY+10,0)
		end
	end
	
	local function createTweens()
		for j=1,2 do
			for i=0,9 do
				local labelY = i + (10*(j-1))
				local tweens = j == 1 and d.CanvasTweens or d.CanvasTweensOverflow
				if (tweens[i] ~= nil and tweens[i].tweenCompleted ~= nil) then
					tweens[i].tweenCompleted:Disconnect()
				end
				local tween = TweenService:Create(Canvas, tweenInfo, {Position = UDim2.new(0,0,-labelY,0)})
				local tweenCompleted = nil
				if (j == 2) then
					tweenCompleted = tween.Completed:Connect(wrapAround)
				end
				tweens[i] = {
					tween = tween;
					tweenCompleted = tweenCompleted;
				}
			end
		end
	end

	for j=1,2 do
		local labels = j == 1 and d.Labels or d.LabelsOverflow
		for i=0,9 do
			local labelY = i + (10*(j-1))
			local n = Instance.new("TextLabel")
			n.Name = "n_"..i
			n.BackgroundTransparency = 1
			n.TextSize = Spinner.TextSize
			n.TextColor3 = Spinner.TextColor3
			n.Font = Spinner.Font
			n.Text = i
			n.Size = UDim2.new(1,0,ySize,0)
			n.Position = UDim2.new(0,0,labelY/ySteps,0)
			n.Parent = Canvas
			labels[i] = n
		end
	end
	createTweens()

	Frame.Parent = Spinner.Frame

	local Size = TextService:GetTextSize("8", Spinner.TextSize, Spinner.Font, Vector2.new(Spinner.TextSize,Spinner.TextSize))
	TweenService:Create(Frame, sizeTweenInfo, {Size = UDim2.new(0,Size.X+1,0,Size.Y+10)}):Play()

	local dProxy = setmetatable({},{
		__index = function(_,key)
			local Direct = d[key]
			if Direct then return Direct end

			local Success = pcall(function() local x = d.Labels[1][key] end)
			if Success then
				return d.Labels[1][key]
			end

			return nil
		end;
		__newindex = function(_,key,value)
			local Direct = d[key]
			if Direct then
				d[key] = value
				d:Update(key,value)
				return
			end

			local Success = pcall(function() local x = d.Labels[1][key] end)
			if Success then
				for j=1,2 do
					local labels = j == 1 and d.Labels or d.LabelsOverflow
					for i=0,9 do
						labels[i][key] = value
					end
				end
				d:Update(key,value)
			end
		end;
	})

	function d:Destroy()
		local Size = TextService:GetTextSize("8", Spinner.TextSize, Spinner.Font, Vector2.new(Spinner.TextSize,Spinner.TextSize))
		local shrinkTween = TweenService:Create(Frame, sizeTweenInfo, {Size = UDim2.new(0,0,0,Size.Y+10)})
		shrinkTween.Completed:Connect(function()
			Frame:Destroy()
			table.clear(d)
			shrinkTween:Destroy()
			local tweens = d.CanvasTweensOverflow
			if (tweens ~= nil) then
				for i=0,9 do
					if (tweens[i] ~= nil and tweens[i].tweenCompleted ~= nil) then
						tweens[i].tweenCompleted:Disconnect()
						tweens[i].tweenCompleted = nil
					end
				end
			end

		end)
		shrinkTween:Play()
	end

	function d:Update(Type,Value)
		if Type == "Duration" then
			tweenInfo = TweenInfo.new(Value, Enum.EasingStyle.Linear)
			createTweens()

		elseif Type == "Value" then
			local visibleValue = getDisplayedValue()
			-- when updating to a smaller number than what's currently visible, use the overflow tweens
			-- these will reset the canvas to the visible range when canceled/completed
			local tweens = Value < visibleValue and d.CanvasTweensOverflow or d.CanvasTweens
			tweens[Value].tween:Play()

		elseif Type == "TextSize" or Type == "Font" then
			local Size = TextService:GetTextSize("8", Spinner.TextSize, Spinner.Font, Vector2.new(Spinner.TextSize,Spinner.TextSize))
			TweenService:Create(Frame, sizeTweenInfo, {Size = UDim2.new(0,Size.X+1,0,Size.Y+10)}):Play()

		end
	end

	return dProxy
end

return Digit