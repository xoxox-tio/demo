local CoreGui = game:GetService("CoreGui")

if CoreGui:FindFirstChild("TargetUI") then 
    CoreGui.TargetUI:Destroy() 
end

local MobileTargetUI = Instance.new("ScreenGui")
MobileTargetUI.Name = "TargetUI"
MobileTargetUI.Parent = CoreGui
MobileTargetUI.IgnoreGuiInset = true
MobileTargetUI.Enabled = false 

local MasterFrame = Instance.new("Frame")
MasterFrame.Name = "MasterFrame"
MasterFrame.Size = UDim2.new(0, 180, 0, 44) 
MasterFrame.Position = UDim2.new(0.5, 0, 0.8, 0)
MasterFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MasterFrame.BackgroundTransparency = 1
MasterFrame.Parent = MobileTargetUI

local Container = Instance.new("Frame")
Container.Name = "BubbleContainer"
Container.Size = UDim2.new(1, 0, 0, 32) 
Container.Position = UDim2.new(0, 0, 0, 0)
Container.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
Container.BackgroundTransparency = 0.5
Container.Active = true 
Container.Parent = MasterFrame
Instance.new("UICorner", Container).CornerRadius = UDim.new(1, 0)

local DragHitbox = Instance.new("Frame")
DragHitbox.Name = "DragHitbox"
DragHitbox.Size = UDim2.new(1, 0, 0, 16)
DragHitbox.Position = UDim2.new(0.5, 0, 1, 0)
DragHitbox.AnchorPoint = Vector2.new(0.5, 1)
DragHitbox.BackgroundTransparency = 1
DragHitbox.Active = true
DragHitbox.Parent = MasterFrame

local DragBarVisual = Instance.new("Frame")
DragBarVisual.Name = "DragBar"
DragBarVisual.Size = UDim2.new(0, 40, 0, 4)
DragBarVisual.Position = UDim2.new(0.5, 0, 0.5, 0) 
DragBarVisual.AnchorPoint = Vector2.new(0.5, 0.5)
DragBarVisual.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DragBarVisual.BackgroundTransparency = 0.2
DragBarVisual.Parent = DragHitbox
Instance.new("UICorner", DragBarVisual).CornerRadius = UDim.new(1, 0)

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 3)
Padding.PaddingRight = UDim.new(0, 3)
Padding.PaddingTop = UDim.new(0, 3)
Padding.PaddingBottom = UDim.new(0, 3)
Padding.Parent = Container

local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Padding = UDim.new(0, 4)
Layout.Parent = Container

local Buttons = {}

local function CreateTab(name, text, isActive)
    local Btn = Instance.new("TextButton")
    Btn.Name = name
    Btn.Size = UDim2.new(0, 55, 1, 0) 
    Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Btn.BackgroundTransparency = isActive and 0 or 1
    Btn.Text = text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12 
    Btn.TextColor3 = isActive and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(30, 30, 30)
    Btn.Parent = Container

    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)
    Buttons[name] = Btn
    return Btn
end

CreateTab("Killer", "Killer", true)
CreateTab("Survivor", "Surv", false)
CreateTab("SCP", "SCP", false)

local function UpdateVisuals(activeName)
    for btnName, btnObj in pairs(Buttons) do
        if btnName == activeName then
            btnObj.BackgroundTransparency = 0
            btnObj.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            btnObj.BackgroundTransparency = 1
            btnObj.TextColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end

local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

DragHitbox.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MasterFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

DragHitbox.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MasterFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

return {
    UI = MobileTargetUI,
    Buttons = Buttons,
    UpdateVisuals = UpdateVisuals
}
