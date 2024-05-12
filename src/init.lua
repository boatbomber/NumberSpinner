local Digit = require(script.Digit)

local NumberSpinner = {}

local READ_ONLY = {
	Frame = true,
	Digits = true,
	CommaLabels = true,
	Text = true,
}
local CUSTOM_PROPS = {
	Value = "number",
	Duration = "number",
	Decimals = "number",
	Prefix = "string",
	Suffix = "string",
	Commas = "boolean",
}
local TEXT_TO_LAYOUT = {
	[Enum.TextXAlignment.Center] = Enum.HorizontalAlignment.Center,
	[Enum.TextXAlignment.Left] = Enum.HorizontalAlignment.Left,
	[Enum.TextXAlignment.Right] = Enum.HorizontalAlignment.Right,
}

local DUMMY_FRAME = Instance.new("Frame")
local DUMMY_LABEL = Instance.new("TextLabel")
DUMMY_LABEL.TextSize = 25
DUMMY_LABEL.TextColor3 = Color3.fromRGB(250, 250, 255)
DUMMY_LABEL.FontFace = Font.new("SourceSans")

local function newSpinner()
	local Spinner = {
		-- Props
		Value = 0,
		Duration = 0.3,
		Decimals = 2,
		Prefix = "$",
		Suffix = "",
		Commas = false,

		-- Internal
		Digits = {
			Whole = table.create(3),
			Decimal = table.create(2),
		},
		CommaLabels = table.create(2),

		-- UIs (populated later)
		Frame = nil,
		Layout = nil,
		PrefixLabel = nil,
		SuffixLabel = nil,
		DecimalLabel = nil,
		NegativeLabel = nil,
	}

	local SpinnerProxy = setmetatable({}, {
		__index = function(_, key)
			local Direct = Spinner[key]
			if Direct then
				return Direct
			end

			local propExistsForFrame = pcall(function()
				local _ = DUMMY_FRAME[key]
			end)
			if propExistsForFrame then
				return Spinner.Frame[key]
			end

			local propExistsForLabel, labelProp = pcall(function()
				return DUMMY_LABEL[key]
			end)
			if propExistsForLabel then
				local digit = Spinner.Digits.Whole[1]
				if digit then
					return digit[key]
				else
					return labelProp
				end
			end

			--warn("Nothing found for",key)
			return nil
		end,
		__newindex = function(_, key, value)
			if READ_ONLY[key] then
				warn("Attempted to set read-only value Spinner." .. key)
				return
			end

			-- Handle setting of Frame properties
			local propExistsForFrame = pcall(function()
				local _ = DUMMY_FRAME[key]
			end)
			if propExistsForFrame then
				local t = typeof(DUMMY_FRAME[key])
				if (t ~= "nil") and (t ~= typeof(value)) then
					warn("Attempted to set Spinner." .. key .. " to invalid value (" .. tostring(value) .. ")")
					return
				end
				Spinner.Frame[key] = value
				return
			end

			-- Handle alignment since it's a special case
			if key == "TextXAlignment" then
				Spinner.Layout.HorizontalAlignment = TEXT_TO_LAYOUT[value]
				return
			end

			-- Handle setting of text related properties
			local propExistsForLabel = pcall(function()
				local _ = DUMMY_LABEL[key]
			end)
			if propExistsForLabel then
				local propType = typeof(DUMMY_LABEL[key])
				if (propType ~= "nil") and (propType ~= typeof(value)) then
					warn("Attempted to set Spinner." .. key .. " to invalid value (" .. tostring(value) .. ")")
					return
				end
				for _, digit in pairs(Spinner.Digits.Whole) do
					digit[key] = value
				end
				for _, digit in pairs(Spinner.Digits.Decimal) do
					digit[key] = value
				end
				for _, comma in pairs(Spinner.CommaLabels) do
					comma[key] = value
				end
				Spinner.PrefixLabel[key] = value
				Spinner.SuffixLabel[key] = value
				Spinner.DecimalLabel[key] = value
				Spinner.NegativeLabel[key] = value
				return
			end

			-- Handle setting of the custom spinner properties
			if CUSTOM_PROPS[key] then
				if typeof(value) ~= CUSTOM_PROPS[key] then
					warn("Attempted to set Spinner." .. key .. " to invalid value (" .. tostring(value) .. ")")
					return
				end
				Spinner[key] = value
				Spinner:Update(key, value)
				return
			end
		end,
	})

	function Spinner:Destroy()
		self.Frame:Destroy()
		table.clear(self)
	end

	function Spinner:Update(Type)
		if Type == "Prefix" then
			Spinner.PrefixLabel.Text = Spinner.Prefix
			return
		elseif Type == "Suffix" then
			Spinner.SuffixLabel.Text = Spinner.Suffix
			return
		end

		local AbsValue = math.abs(Spinner.Value)
		local isNegative = Spinner.Value < 0

		if Spinner.NegativeLabel then
			Spinner.NegativeLabel.Visible = isNegative
		end

		local TextValue = Spinner.Decimals > 0 and string.format("%." .. Spinner.Decimals .. "f", AbsValue)
			or string.format("%d", AbsValue)
		local split = string.split(TextValue, ".")
		local whole, decimal = split[1], split[2]
		if not whole then
			return
		end

		local numWhole = #whole
		for i = 1, numWhole do
			local digit = Spinner.Digits.Whole[i]

			if digit then
				digit.Duration = Spinner.Duration
				digit.Value = tonumber(string.sub(whole, i, i))
			else
				digit = Digit.new(SpinnerProxy, (i * 2) - 900, tonumber(string.sub(whole, i, i)))
				Spinner.Digits.Whole[i] = digit
			end
		end
		for i = numWhole + 1, #Spinner.Digits.Whole do
			local digit = Spinner.Digits.Whole[i]
			if digit then
				digit:Destroy()
				Spinner.Digits.Whole[i] = nil
			end
		end

		if Spinner.Commas then
			local endLayout = (numWhole * 2) - 900
			local str = string.format("%d", math.floor(math.abs(Spinner.Value)))
			local commaIndex = 0
			for i = 0, #str - 1, 3 do
				if i == 0 then
					continue
				end
				commaIndex += 1
				local CommaLabel = Spinner.CommaLabels[commaIndex]
				if not CommaLabel then
					CommaLabel = Instance.new("TextLabel")
					CommaLabel.Name = "Comma"
					CommaLabel.BackgroundTransparency = 1
					CommaLabel.Size = UDim2.new(0, 0, 1, 0)
					CommaLabel.FontFace = SpinnerProxy.FontFace
					CommaLabel.TextSize = SpinnerProxy.TextSize
					CommaLabel.TextColor3 = SpinnerProxy.TextColor3
					CommaLabel.Text = ","
					CommaLabel.AutomaticSize = Enum.AutomaticSize.X
					CommaLabel.Parent = Spinner.Frame

					Spinner.CommaLabels[commaIndex] = CommaLabel
				end

				CommaLabel.LayoutOrder = (endLayout - ((i - 1) * 2) - 1)
			end

			for i = commaIndex + 1, #Spinner.CommaLabels do
				Spinner.CommaLabels[i]:Destroy()
				Spinner.CommaLabels[i] = nil
			end
		end

		if not decimal then
			if Spinner.DecimalLabel then
				Spinner.DecimalLabel.Visible = false
			end
			for _, digit in ipairs(Spinner.Digits.Decimal) do
				digit:Destroy()
			end
			table.clear(Spinner.Digits.Decimal)
			return
		end

		if Spinner.DecimalLabel then
			Spinner.DecimalLabel.Visible = true
		end
		for i = 1, #decimal do
			local digit = Spinner.Digits.Decimal[i]

			if digit then
				digit.Duration = Spinner.Duration
				digit.Value = tonumber(string.sub(decimal, i, i))
			else
				digit = Digit.new(SpinnerProxy, i, tonumber(string.sub(decimal, i, i)))
				Spinner.Digits.Decimal[i] = digit
			end
		end
		for i = #decimal + 1, #Spinner.Digits.Decimal do
			local digit = Spinner.Digits.Decimal[i]
			if digit then
				digit:Destroy()
				Spinner.Digits.Decimal[i] = nil
			end
		end
	end

	return SpinnerProxy, Spinner
end

function NumberSpinner.new()
	local Spinner, RawSpinner = newSpinner()

	local Frame = Instance.new("Frame")
	Frame.BackgroundTransparency = 1
	Frame.ClipsDescendants = true
	Frame.Size = UDim2.new(0, 200, 0, 50)
	Frame.Position = UDim2.new(0, 0, 0, 0)

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Layout.VerticalAlignment = Enum.VerticalAlignment.Center
	Layout.Padding = UDim.new(0, 0)
	Layout.Parent = Frame

	local Prefix = Instance.new("TextLabel")
	Prefix.Name = "Prefix"
	Prefix.LayoutOrder = -1000
	Prefix.BackgroundTransparency = 1
	Prefix.Size = UDim2.new(0, 0, 1, 0)
	Prefix.FontFace = Spinner.FontFace
	Prefix.TextSize = Spinner.TextSize
	Prefix.TextColor3 = Spinner.TextColor3
	Prefix.Text = Spinner.Prefix
	Prefix.AutomaticSize = Enum.AutomaticSize.X
	Prefix.Parent = Frame

	local Suffix = Instance.new("TextLabel")
	Suffix.Name = "Suffix"
	Suffix.LayoutOrder = 1000
	Suffix.BackgroundTransparency = 1
	Suffix.Size = UDim2.new(0, 0, 1, 0)
	Suffix.FontFace = Spinner.FontFace
	Suffix.TextSize = Spinner.TextSize
	Suffix.TextColor3 = Spinner.TextColor3
	Suffix.Text = Spinner.Suffix
	Suffix.AutomaticSize = Enum.AutomaticSize.X
	Suffix.Parent = Frame

	local Decimal = Instance.new("TextLabel")
	Decimal.Name = "Decimal"
	Decimal.LayoutOrder = 0
	Decimal.BackgroundTransparency = 1
	Decimal.Size = UDim2.new(0, 0, 1, 0)
	Decimal.FontFace = Spinner.FontFace
	Decimal.TextSize = Spinner.TextSize
	Decimal.TextColor3 = Spinner.TextColor3
	Decimal.Text = "."
	Decimal.AutomaticSize = Enum.AutomaticSize.X
	Decimal.Parent = Frame

	local Negative = Instance.new("TextLabel")
	Negative.Name = "Negative"
	Negative.LayoutOrder = -999
	Negative.BackgroundTransparency = 1
	Negative.Size = UDim2.new(0, 0, 1, 0)
	Negative.FontFace = Spinner.FontFace
	Negative.TextSize = Spinner.TextSize
	Negative.TextColor3 = Spinner.TextColor3
	Negative.Text = "-"
	Negative.AutomaticSize = Enum.AutomaticSize.X
	Negative.Parent = Frame

	RawSpinner.Frame = Frame
	RawSpinner.Layout = Layout
	RawSpinner.PrefixLabel = Prefix
	RawSpinner.SuffixLabel = Suffix
	RawSpinner.DecimalLabel = Decimal
	RawSpinner.NegativeLabel = Negative

	Spinner:Update()

	return Spinner
end

function NumberSpinner.fromGuiObject(GuiObject)
	if typeof(GuiObject) ~= "Instance" then
		return
	end
	if not GuiObject:IsA("GuiObject") then
		return
	end

	local Spinner = NumberSpinner.new()

	Spinner.Name = "Spinner_" .. GuiObject.Name
	Spinner.SizeConstraint = GuiObject.SizeConstraint
	Spinner.Size = GuiObject.Size
	Spinner.Position = GuiObject.Position
	Spinner.AnchorPoint = GuiObject.AnchorPoint
	Spinner.Rotation = GuiObject.Rotation
	Spinner.LayoutOrder = GuiObject.LayoutOrder
	Spinner.ZIndex = GuiObject.ZIndex
	Spinner.Visible = GuiObject.Visible
	Spinner.BackgroundColor3 = GuiObject.BackgroundColor3
	Spinner.BorderColor3 = GuiObject.BorderColor3
	Spinner.BorderSizePixel = GuiObject.BorderSizePixel
	Spinner.BackgroundTransparency = GuiObject.BackgroundTransparency

	if GuiObject:IsA("TextLabel") or GuiObject:IsA("TextButton") or GuiObject:IsA("TextBox") then
		Spinner.FontFace = GuiObject.FontFace
		Spinner.TextSize = GuiObject.TextSize
		Spinner.TextColor3 = GuiObject.TextColor3
		Spinner.TextTransparency = GuiObject.TextTransparency
		Spinner.TextStrokeColor3 = GuiObject.TextStrokeColor3
		Spinner.TextStrokeTransparency = GuiObject.TextStrokeTransparency

		Spinner.Layout.HorizontalAlignment = TEXT_TO_LAYOUT[GuiObject.TextXAlignment]
	end

	Spinner.Parent = GuiObject.Parent

	GuiObject.Visible = false

	return Spinner
end

return NumberSpinner
