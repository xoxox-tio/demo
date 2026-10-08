local UILib = {}
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local function getParent()
    return pcall(function() return CoreGui.Name end) and CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- ==========================================
-- 1. TARGET MOBILE UI (STYLE BUBBLE)
-- ==========================================
function UILib.CreateTargetUI()
    local parent = getParent()
    if parent:FindFirstChild("TargetUI") then parent.TargetUI:Destroy() end

    local MobileTargetUI = Instance.new("ScreenGui")
    MobileTargetUI.Name = "TargetUI"
    MobileTargetUI.Parent = parent
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
    Container.Size = UDim2.new(1, 0, 0, 32) 
    Container.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    Container.BackgroundTransparency = 0.5
    Container.Active = true 
    Container.Parent = MasterFrame
    Instance.new("UICorner", Container).CornerRadius = UDim.new(1, 0)

    local DragHitbox = Instance.new("Frame")
    DragHitbox.Size = UDim2.new(1, 0, 0, 16)
    DragHitbox.Position = UDim2.new(0.5, 0, 1, 0)
    DragHitbox.AnchorPoint = Vector2.new(0.5, 1)
    DragHitbox.BackgroundTransparency = 1
    DragHitbox.Active = true
    DragHitbox.Parent = MasterFrame

    local DragBarVisual = Instance.new("Frame")
    DragBarVisual.Size = UDim2.new(0, 40, 0, 4)
    DragBarVisual.Position = UDim2.new(0.5, 0, 0.5, 0) 
    DragBarVisual.AnchorPoint = Vector2.new(0.5, 0.5)
    DragBarVisual.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DragBarVisual.BackgroundTransparency = 0.2
    DragBarVisual.Parent = DragHitbox
    Instance.new("UICorner", DragBarVisual).CornerRadius = UDim.new(1, 0)

    local Padding = Instance.new("UIPadding", Container)
    Padding.PaddingLeft = UDim.new(0, 3)
    Padding.PaddingRight = UDim.new(0, 3)
    Padding.PaddingTop = UDim.new(0, 3)
    Padding.PaddingBottom = UDim.new(0, 3)

    local Layout = Instance.new("UIListLayout", Container)
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.Padding = UDim.new(0, 4)

    local Buttons = {}
    local function CreateTab(name, text, isActive)
        local Btn = Instance.new("TextButton")
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

    local dragging, dragInput, dragStart, startPos
    DragHitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, MasterFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    DragHitbox.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MasterFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return { UI = MobileTargetUI, Buttons = Buttons, UpdateVisuals = UpdateVisuals }
end

-- ==========================================
-- 2. WATERMARK UI (FPS & PING)
-- ==========================================
function UILib.CreateWatermark()
    local parent = getParent()
    if parent:FindFirstChild("WM") then parent.WM:Destroy() end

    local WatermarkUI = Instance.new("ScreenGui")
    WatermarkUI.Name = "WM"
    WatermarkUI.Parent = parent
    WatermarkUI.IgnoreGuiInset = true
    WatermarkUI.ResetOnSpawn = false

    local WmB = Instance.new("Frame")
    WmB.Name = "Bubble"
    WmB.Size = UDim2.new(0, 110, 0, 20)
    WmB.Position = UDim2.new(0.5, 0, 0.95, 0)
    WmB.AnchorPoint = Vector2.new(0.5, 0.5)
    WmB.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    WmB.BackgroundTransparency = 0.5
    WmB.Active = true
    WmB.Parent = WatermarkUI

    Instance.new("UICorner", WmB).CornerRadius = UDim.new(0, 8)
    local UIStroke = Instance.new("UIStroke", WmB)
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Transparency = 0.25

    local WatermarkText = Instance.new("TextLabel")
    WatermarkText.Size = UDim2.new(1, 0, 1, 0)
    WatermarkText.BackgroundTransparency = 1
    WatermarkText.Font = Enum.Font.GothamSemibold
    WatermarkText.TextSize = 11
    WatermarkText.TextColor3 = Color3.fromRGB(255, 255, 255)
    WatermarkText.Text = "VD_T | FPS: ... | Ping: ..."
    WatermarkText.Parent = WmB

    local dragging, dragInput, dragStart, startPos
    WmB.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, WmB.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    WmB.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            WmB.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return { UI = WatermarkUI, Text = WatermarkText }
end

-- ==========================================
-- 3. SPECTATOR & PREDICT UI
-- ==========================================
function UILib.CreateSpectator()
    local parent = getParent()
    if parent:FindFirstChild("SpcGui") then parent.SpcGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpcGui"
    screenGui.Parent = parent
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 50, 0, 18)
    mainFrame.Position = UDim2.new(0.5, 0, 0, -10)
    mainFrame.AnchorPoint = Vector2.new(0.5, 1)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 6)

    local eyeIcon = Instance.new("ImageLabel", mainFrame)
    eyeIcon.Size = UDim2.new(0, 14, 0, 14)
    eyeIcon.BackgroundTransparency = 1
    eyeIcon.Image = "rbxassetid://13321848320"

    local countText = Instance.new("TextLabel", mainFrame)
    countText.Size = UDim2.new(0, 0, 1, 0)
    countText.AutomaticSize = Enum.AutomaticSize.X 
    countText.BackgroundTransparency = 1
    countText.Font = Enum.Font.GothamMedium
    countText.TextColor3 = Color3.fromRGB(230, 230, 230)
    countText.TextSize = 12
    countText.Text = "0"

    local nextKillerFrame = Instance.new("Frame", screenGui)
    nextKillerFrame.Size = UDim2.new(0, 150, 0, 18) 
    nextKillerFrame.Position = UDim2.new(0.5, 0, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset + 20)
    nextKillerFrame.AnchorPoint = Vector2.new(0.5, 0)
    nextKillerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    nextKillerFrame.BackgroundTransparency = 0.2
    nextKillerFrame.Visible = false
    Instance.new("UICorner", nextKillerFrame).CornerRadius = UDim.new(0, 6)

    local nkText = Instance.new("TextLabel", nextKillerFrame)
    nkText.Size = UDim2.new(1, 0, 1, 0)
    nkText.BackgroundTransparency = 1
    nkText.Font = Enum.Font.GothamMedium
    nkText.TextColor3 = Color3.fromRGB(255, 85, 85)
    nkText.TextSize = 12
    nkText.Text = "Next Killer: ..."

    return { UI = screenGui, CountText = countText, KillerFrame = nextKillerFrame, KillerText = nkText }
end

-- ==========================================
-- 4. FOV UI
-- ==========================================
function UILib.CreateFOV()
    local parent = getParent()
    if parent:FindFirstChild("FovC") then parent.FovC:Destroy() end

    local FOVGui = Instance.new("ScreenGui", parent)
    FOVGui.Name = "FovC"
    FOVGui.ResetOnSpawn = false
    FOVGui.IgnoreGuiInset = true

    local FOVFrame = Instance.new("Frame", FOVGui)
    FOVFrame.BackgroundTransparency = 1
    FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    FOVFrame.Visible = false
    Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)

    local FOVStroke = Instance.new("UIStroke", FOVFrame)
    FOVStroke.Color = Color3.fromRGB(0, 255, 100)
    FOVStroke.Thickness = 0.4

    return { UI = FOVGui, Frame = FOVFrame, Stroke = FOVStroke }
end

-- ==========================================
-- 5. CROSSHAIR UI
-- ==========================================
function UILib.DrawCrosshair(config)
    local parent = getParent()
    if parent:FindFirstChild("Croshair") then parent.Croshair:Destroy() end
    if not config.Enabled then return nil end

    local CrosshairUI = Instance.new("ScreenGui", parent)
    CrosshairUI.Name = "Croshair"
    CrosshairUI.IgnoreGuiInset = true 

    local container = Instance.new("Frame", CrosshairUI)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, config.OffsetX, 0.5, config.OffsetY)
    container.Size = UDim2.new(0, 0, 0, 0)
    container.BackgroundTransparency = 1

    local size, color = config.Size, config.Color
    local thick = math.max(1, math.floor(size / 4))
    local len = size * 2
    local gap = math.max(2, math.floor(size / 1.5))

    if config.Type == "Dot" then 
        local dot = Instance.new("Frame", container)
        dot.AnchorPoint, dot.Position = Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0)
        dot.Size, dot.BackgroundColor3 = UDim2.new(0, size, 0, size), color
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    elseif config.Type == "Cross" then 
        local function makeLine(ap, s, p)
            local l = Instance.new("Frame", container)
            l.AnchorPoint, l.Size, l.Position, l.BackgroundColor3 = ap, s, p, color
        end
        makeLine(Vector2.new(0.5, 1), UDim2.new(0, thick, 0, len), UDim2.new(0.5, 0, 0.5, -gap))
        makeLine(Vector2.new(0.5, 0), UDim2.new(0, thick, 0, len), UDim2.new(0.5, 0, 0.5, gap))
        makeLine(Vector2.new(1, 0.5), UDim2.new(0, len, 0, thick), UDim2.new(0.5, -gap, 0.5, 0))
        makeLine(Vector2.new(0, 0.5), UDim2.new(0, len, 0, thick), UDim2.new(0.5, gap, 0.5, 0))
    elseif config.Type == "Circle" then 
        local circ = Instance.new("Frame", container)
        circ.AnchorPoint, circ.Position = Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0)
        circ.Size, circ.BackgroundTransparency = UDim2.new(0, size*2.5, 0, size*2.5), 1
        local stroke = Instance.new("UIStroke", circ)
        stroke.Color, stroke.Thickness = color, thick
        Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)
    end
    return CrosshairUI
end

return UILib
