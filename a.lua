local CoreGui = game:GetService("CoreGui")

-- Hapus UI lama jika ada agar tidak menumpuk saat dieksekusi ulang
if CoreGui:FindFirstChild("TargetUI") then 
    CoreGui.TargetUI:Destroy() 
end

local MobileTargetUI = Instance.new("ScreenGui")
MobileTargetUI.Name = "TargetUI"
MobileTargetUI.Parent = CoreGui
MobileTargetUI.IgnoreGuiInset = true
MobileTargetUI.Enabled = false 

local TargetMainBox = Instance.new("Frame")
TargetMainBox.Name = "TargetMainBox"
TargetMainBox.Size = UDim2.new(0, 100, 0, 25)
TargetMainBox.Position = UDim2.new(0.5, 0, 0.8, 0)
TargetMainBox.AnchorPoint = Vector2.new(0.5, 0.5)
TargetMainBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TargetMainBox.BackgroundTransparency = 0.2
TargetMainBox.ZIndex = 100
TargetMainBox.Parent = MobileTargetUI

local TargetCorner = Instance.new("UICorner")
TargetCorner.CornerRadius = UDim.new(0, 8)
TargetCorner.Parent = TargetMainBox

local TargetUIStroke = Instance.new("UIStroke")
TargetUIStroke.Color = Color3.fromRGB(255, 255, 255)
TargetUIStroke.Transparency = 0.5
TargetUIStroke.Thickness = 1
TargetUIStroke.Parent = TargetMainBox

local TargetText = Instance.new("TextLabel")
TargetText.Size = UDim2.new(1, -40, 1, -15)
TargetText.Position = UDim2.new(0, 10, 0, 5)
TargetText.BackgroundTransparency = 1
TargetText.Font = Enum.Font.GothamSemibold
TargetText.TextSize = 12
TargetText.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetText.Text = "Target: Killer"
TargetText.TextXAlignment = Enum.TextXAlignment.Left
TargetText.ZIndex = 101
TargetText.Parent = TargetMainBox

local NextButton = Instance.new("TextButton")
NextButton.Size = UDim2.new(0, 20, 0, 20)
NextButton.AnchorPoint = Vector2.new(0.5, 0.5)
NextButton.Position = UDim2.new(0.85, 0, 0.5, 0)
NextButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NextButton.Text = ">"
NextButton.Font = Enum.Font.GothamBold
NextButton.TextSize = 16
NextButton.TextColor3 = Color3.fromRGB(0, 255, 100)
NextButton.ZIndex = 102
NextButton.Parent = TargetMainBox

local NextCorner = Instance.new("UICorner")
NextCorner.CornerRadius = UDim.new(0, 6)
NextCorner.Parent = NextButton

local DragBarHitbox = Instance.new("Frame")
DragBarHitbox.Size = UDim2.new(1, 0, 0, 15)
DragBarHitbox.Position = UDim2.new(0, 0, 1, 5)
DragBarHitbox.AnchorPoint = Vector2.new(0, 0.5)
DragBarHitbox.BackgroundTransparency = 1
DragBarHitbox.Active = true
DragBarHitbox.ZIndex = 103
DragBarHitbox.Parent = TargetMainBox

local DragBarVisual = Instance.new("Frame")
DragBarVisual.Size = UDim2.new(0, 60, 0, 4)
DragBarVisual.Position = UDim2.new(0.5, 0, 0.5, 0)
DragBarVisual.AnchorPoint = Vector2.new(0.5, 0.5)
DragBarVisual.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
DragBarVisual.ZIndex = 104
DragBarVisual.Parent = DragBarHitbox

local DragBarCorner = Instance.new("UICorner")
DragBarCorner.CornerRadius = UDim.new(1, 0)
DragBarCorner.Parent = DragBarVisual

-- Logika Drag UI Target
local UserInputService = game:GetService("UserInputService")
local dragTargeting = false
local dragStartTarget, startPosTarget

DragBarHitbox.InputBegan:Connect(function(input)
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

-- Return tabel berisi referensi agar main script bisa mengatur event
return {
    UI = MobileTargetUI,
    TargetText = TargetText,
    NextButton = NextButton
}
