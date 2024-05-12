local NumberSpinner = require(script.NumberSpinner)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local PriceSpinner = NumberSpinner.new()
PriceSpinner.FontFace = Font.fromEnum(Enum.Font.SourceSans)
PriceSpinner.Decimals = 3
PriceSpinner.Duration = 0.25
PriceSpinner.Parent = ScreenGui

while wait(0.5) do
	PriceSpinner.Value = math.random(100000) / 1000
end
