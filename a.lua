local CoreGui = game:GetService("CoreGui")

if CoreGui:FindFirstChild("TargetUI") then 
    CoreGui.TargetUI:Destroy() 
end

local MobileTargetUI = Instance.new("ScreenGui")
MobileTargetUI.Name = "TargetUI"
MobileTargetUI.Parent = CoreGui
MobileTargetUI.IgnoreGuiInset = true
MobileTargetUI.Enabled = false 

-- Wadah Utama (Bubble/Pill)
local TargetMainBox = Instance.new("Frame")
TargetMainBox.Name = "BubbleContainer"
TargetMainBox.Size = UDim2.new(0, 210, 0, 42)
TargetMainBox.Position = UDim2.new(0.5, 0, 0.8, 0)
TargetMainBox.AnchorPoint = Vector2.new(0.5, 0.5)
TargetMainBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TargetMainBox.BackgroundTransparency = 0.4
TargetMainBox.Active = true
TargetMainBox.ZIndex = 100
TargetMainBox.Parent = MobileTargetUI

Instance.new("UICorner", TargetMainBox).CornerRadius = UDim.new(1, 0)

local Stroke = Instance.new("UIStroke", TargetMainBox)
Stroke.Color = Color3.fromRGB(255, 255, 255)
Stroke.Transparency = 0.7
Stroke.Thickness = 1.2

-- Indikator Drag di bawah Bubble
local DragBarVisual = Instance.new("Frame")
DragBarVisual.Size = UDim2.new(0, 60, 0, 4)
DragBarVisual.Position = UDim2.new(0.5, 0, 1, 8)
DragBarVisual.AnchorPoint = Vector2.new(0.5, 0)
DragBarVisual.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DragBarVisual.BackgroundTransparency = 0.3
DragBarVisual.ZIndex = 104
DragBarVisual.Parent = TargetMainBox
Instance.new("UICorner", DragBarVisual).CornerRadius = UDim.new(1, 0)

-- Layout Tab
local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Padding = UDim.new(0, 6)
Layout.Parent = TargetMainBox

local Buttons = {}

local function CreateTab(name, text, isActive)
    local Btn = Instance.new("TextButton")
    Btn.Name = name
    Btn.Size = UDim2.new(0, 60, 0, 32)
    Btn.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    Btn.BackgroundTransparency = isActive and 0.1 or 1
    Btn.Text = text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.TextColor3 = isActive and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(200, 200, 200)
    Btn.ZIndex = 101
    Btn.Parent = TargetMainBox

    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)
    Buttons[name] = Btn
    return Btn
end

-- Buat 3 Tombol
local btnKiller = CreateTab("Killer", "Killer", true)
local btnSurv = CreateTab("Survivor", "Surv", false)
local btnSCP = CreateTab("SCP", "SCP", false)

-- Fungsi Update Visual
local function UpdateVisuals(activeName)
    for name, btn in pairs(Buttons) do
        if name == activeName then
            btn.BackgroundTransparency = 0.1
            btn.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

-- Logika Dragging
local UserInputService = game:GetService("UserInputService")
local dragTargeting = false
local dragStartTarget, startPosTarget

TargetMainBox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragTargeting = true
        dragStartTarget = input.Position
        startPosTarget = TargetMainBox.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragTargeting = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragTargeting and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartTarget
        TargetMainBox.Position = UDim2.new(startPosTarget.X.Scale, startPosTarget.X.Offset + delta.X, startPosTarget.Y.Scale, startPosTarget.Y.Offset + delta.Y)
    end
end)

return {
    UI = MobileTargetUI,
    Buttons = Buttons,
    UpdateVisuals = UpdateVisuals
}
