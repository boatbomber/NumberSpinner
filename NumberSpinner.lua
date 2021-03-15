local TextService = game:GetService('TextService')
local TweenService = game:GetService('TweenService')

local module = {}

local typeProtection = {
	Frame = "__read-only__";
	Prefix = "string";
	Value = "number";
	Decimals = "number";
	Duration = "number";
	Font = "EnumItem";
	TextSize = "number";
	TextColor3 = "Color3";
	Visible = "boolean";
}

local function createDigit(layoutOrder, initialValues)

	local Frame = Instance.new("Frame")
	Frame.Name = "digit"
	Frame.LayoutOrder = layoutOrder
	Frame.BackgroundTransparency = 1
	Frame.Size = UDim2.new(0,0,1,0)
	Frame.ClipsDescendants = true

	local Canvas = Instance.new("Frame")
	Canvas.Name = "canvas"
	Canvas.Size = UDim2.new(1,0,10,0)
	Canvas.BackgroundTransparency = 1
	Canvas.Parent = Frame

	local digit = {
		Frame = Frame;
		Duration = initialValues.Duration or 0.5;
		Value = initialValues.Value or 0;
		Font = initialValues.Font or Enum.Font.SourceSansBold;
		TextSize = initialValues.TextSize or 25;
		TextColor3 = initialValues.TextColor3 or Color3.new(1,1,1);
		Numbers = table.create(10);
		_Destroyed = false;
	}

	function digit:Destroy()
		digit._Destroyed = true
		Frame:TweenSize(UDim2.new(0,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, digit.Duration*0.8, true, function()
			Frame:Destroy()
			table.clear(digit)
		end)
	end

	local Width = TextService:GetTextSize("1", digit.TextSize, digit.Font, Vector2.new(digit.TextSize,digit.TextSize)).X
	TweenService:Create(Frame, TweenInfo.new(digit.Duration), {Size = UDim2.new(0,Width,1,0)}):Play()
	Canvas.Position = UDim2.new(0,0,-digit.Value,0)

	for i=0,9 do
		local n = Instance.new("TextLabel")
		n.Name = "n_"..i
		n.BackgroundTransparency = 1
		n.TextSize = digit.TextSize
		n.TextColor3 = digit.TextColor3
		n.Font = digit.Font
		n.Text = i
		n.Size = UDim2.new(1,0,0.1,0)
		n.Position = UDim2.new(0,0,i*0.1,0)
		n.Parent = Canvas
		digit.Numbers[i] = n
	end

	local function Update()
		if digit._Destroyed then return end

		Width = TextService:GetTextSize("1", digit.TextSize, digit.Font, Vector2.new(digit.TextSize,digit.TextSize)).X

		for i,n in ipairs(digit.Numbers) do
			n.TextSize = digit.TextSize
			n.TextColor3 = digit.TextColor3
			n.Font = digit.Font
		end

		Frame.Size = UDim2.new(0,Width,1,0)
		TweenService:Create(Canvas, TweenInfo.new(digit.Duration), {Position = UDim2.new(0,0,-digit.Value,0)}):Play()
	end

	local digitProxy = setmetatable({}, {
		__index = digit;
		__newindex = function(_,key,value)
			digit[key] = value
			Update()
		end;
	})

	return digitProxy
end

function module.new()

	local Frame = Instance.new("Frame")
	Frame.BackgroundTransparency = 1
	Frame.ClipsDescendants = true
	Frame.Size = UDim2.new(0,200,0,50)
	Frame.Position = UDim2.new(0,0,0,0)

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	Layout.Parent = Frame

	local spinner = {}
	spinner.Prefix = "$"
	spinner.Value = 0
	spinner.Decimals = 2
	spinner.Duration = 0.6
	spinner.Font = Enum.Font.SourceSansBold
	spinner.TextSize = 25
	spinner.TextColor3 = Color3.new(1,1,1);
	spinner.Visible = true
	spinner.Frame = Frame

	local Prefix = Instance.new("TextLabel")
	Prefix.LayoutOrder = -10
	Prefix.BackgroundTransparency = 1
	Prefix.Size = UDim2.new(0,spinner.TextSize,1,0)
	Prefix.Font = spinner.Font
	Prefix.TextSize = spinner.TextSize
	Prefix.TextColor3 = spinner.TextColor3
	Prefix.Text = spinner.Prefix
	Prefix.Parent = Frame

	local Decimal = Instance.new("TextLabel")
	Decimal.LayoutOrder = 500
	Decimal.BackgroundTransparency = 1
	Decimal.Size = UDim2.new(0,spinner.TextSize,1,0)
	Decimal.Font = spinner.Font
	Decimal.TextSize = spinner.TextSize
	Decimal.TextColor3 = spinner.TextColor3
	Decimal.Text = "."
	Decimal.Parent = Frame

	local WholeDigits = table.create(2)
	local DecimalDigits = table.create(2)

	function spinner:Destroy()
		Frame:Destroy()
		table.clear(spinner)
		spinner = nil
	end

	function spinner:Update()
		Frame.Visible = spinner.Visible
		Frame.Size = UDim2.new(1,-20,0,spinner.TextSize+4)

		Prefix.Size = UDim2.new(
			0,TextService:GetTextSize(spinner.Prefix, spinner.TextSize, spinner.Font, Vector2.new(spinner.TextSize,spinner.TextSize)).X,
			1,0
		)
		Prefix.Font = spinner.Font
		Prefix.TextSize = spinner.TextSize
		Prefix.TextColor3 = spinner.TextColor3
		Prefix.Text = spinner.Prefix

		Decimal.Size = UDim2.new(
			0,TextService:GetTextSize(".", spinner.TextSize, spinner.Font, Vector2.new(spinner.TextSize,spinner.TextSize)).X,
			1,0
		)
		Decimal.Font = spinner.Font
		Decimal.TextSize = spinner.TextSize
		Decimal.TextColor3 = spinner.TextColor3

		local TextValue = string.format("%."..spinner.Decimals.."f",spinner.Value)
		local split = string.split(TextValue, ".")
		local whole,decimal = split[1],split[2]
		if not whole then return end

		for i=1,#whole do
			local d = WholeDigits[i]

			if d then
				d.Font = spinner.Font;
				d.TextSize = spinner.TextSize;
				d.TextColor = spinner.TextColor3;
				d.Duration = spinner.Duration;
				d.Value = tonumber(string.sub(whole,i,i))
			else
				d = createDigit(i, {
					Value = tonumber(string.sub(whole,i,i));
					Font = spinner.Font;
					TextSize = spinner.TextSize;
					TextColor = spinner.TextColor3;
					Duration = spinner.Duration;
				})
				d.Frame.Parent = Frame
				WholeDigits[i] = d
			end
		end
		for i=#whole+1,#WholeDigits do
			local d = WholeDigits[i]
			if d then d:Destroy(); WholeDigits[i] = nil; end
		end


		for i=1,#decimal do
			local d = DecimalDigits[i]

			if d then
				d.Font = spinner.Font;
				d.TextSize = spinner.TextSize;
				d.TextColor = spinner.TextColor3;
				d.Duration = spinner.Duration;
				d.Value = tonumber(string.sub(decimal,i,i))
			else
				d = createDigit(i+500, {
					Value = tonumber(string.sub(decimal,i,i));
					Font = spinner.Font;
					TextSize = spinner.TextSize;
					TextColor = spinner.TextColor3;
					Duration = spinner.Duration;
				})
				d.Frame.Parent = Frame
				DecimalDigits[i] = d
			end
		end
		for i=#decimal+1,#DecimalDigits do
			local d = DecimalDigits[i]
			if d then d:Destroy(); DecimalDigits[i] = nil; end
		end

	end

	spinner:Update()

	local Proxy = setmetatable({}, {
		__index = spinner;
		__newindex = function(_, key, value)
			if typeof(value) ~= typeProtection[key] then
				warn("Attempted to set Spinner."..key.." to invalid value ("..tostring(value)..")")
				return
			end
			spinner[key] = value
			spinner:Update()
		end;
	})

	return Proxy

end

return module
