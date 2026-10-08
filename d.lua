local ESP = {}
local ctx

function ESP.Init(context)
    ctx = context
end

local isScanningMap = false
local lastScanTime = 0

function ESP.ScanMap(force)
    if isScanningMap then return end
    if not force and (os.clock() - lastScanTime < 3) then return end
    
    isScanningMap = true
    lastScanTime = os.clock()

    table.clear(ctx.Cache.Generators)
    table.clear(ctx.Cache.Windows)
    table.clear(ctx.Cache.Pallets)
    table.clear(ctx.Cache.Hooks)
    table.clear(ctx.Cache.Gates)
    table.clear(ctx.Cache.SCPs)
    table.clear(ctx.State.DroppedPallets)
        
    local descendants = ctx.S.Workspace:GetDescendants()
    for i, v in ipairs(descendants) do
        if i % 300 == 0 then task.wait() end 
        
        if v:IsA("Model") then
            local name = string.lower(v.Name)
            if name == "generator" then 
                local p = v:FindFirstChildWhichIsA("BasePart")
                if p then table.insert(ctx.Cache.Generators, {model = v, part = p}) end
            elseif name == "hook" and v:FindFirstChild("HookPoint") then 
                table.insert(ctx.Cache.Hooks, v)
            elseif name == "gate" and v:FindFirstChild("ExitLever") then
                table.insert(ctx.Cache.Gates, v)
            elseif name == "window" then 
                table.insert(ctx.Cache.Windows, v)
            elseif string.match(name, "^scp") then
                table.insert(ctx.Cache.SCPs, v)
            end
        elseif v:IsA("BasePart") and v.Name == "PrimaryPartPallet" then
            local modelUtamaPallet = v.Parent
            if modelUtamaPallet then
                local isAlreadyCached = false
                for _, item in ipairs(ctx.Cache.Pallets) do
                    if item.model == modelUtamaPallet then
                        isAlreadyCached = true
                        break
                    end
                end

                if not isAlreadyCached then
                    local triggerPoint = modelUtamaPallet:FindFirstChild("PalletPointSlide", true) 
                        or modelUtamaPallet:FindFirstChild("PalletPoint", true)

                    table.insert(ctx.Cache.Pallets, {
                        model = modelUtamaPallet,
                        trigger = triggerPoint
                    })
                end
            end
        end
    end
    
    isScanningMap = false
end

function ESP.ClearESP(tipe) 
    if tipe == "Player" then 
        for _, p in ipairs(ctx.ActivePlayers) do 
            if p.Character then 
                local peh = p.Character:FindFirstChild("PEH")
                local pe_text = p.Character:FindFirstChild("PE_Text")
                if peh then ctx.S.Debris:AddItem(peh, 0) end
                if pe_text then ctx.S.Debris:AddItem(pe_text, 0) end 
            end 
        end 
    elseif tipe == "Killer" then 
        for _, p in ipairs(ctx.ActivePlayers) do 
            if p.Character then 
                local keh = p.Character:FindFirstChild("KEH")
                local ke_text = p.Character:FindFirstChild("KE_Text")
                if keh then ctx.S.Debris:AddItem(keh, 0) end
                if ke_text then ctx.S.Debris:AddItem(ke_text, 0) end 
            end 
        end 
    elseif tipe == "Generator" then 
        for _, v in pairs(ctx.Cache.Generators) do 
            if v.model and v.model.Parent then 
                local geh = v.model:FindFirstChild("GEH")
                local ge_text = v.model:FindFirstChild("GE_Text")
                if geh then ctx.S.Debris:AddItem(geh, 0) end
                if ge_text then ctx.S.Debris:AddItem(ge_text, 0) end 
            end 
        end 
    elseif tipe == "Pallet" then 
        for _, v in pairs(ctx.Cache.Pallets) do 
            if v and v.Parent then 
                local peh = v:FindFirstChild("PalletEH")
                if peh then ctx.S.Debris:AddItem(peh, 0) end 
            end 
        end
    elseif tipe == "Hook" then 
        for _, v in pairs(ctx.Cache.Hooks) do 
            if v and v.Parent then 
                local heh = v:FindFirstChild("HookEH")
                local he_text = v:FindFirstChild("HookE_Text")
                if heh then ctx.S.Debris:AddItem(heh, 0) end
                if he_text then ctx.S.Debris:AddItem(he_text, 0) end 
            end 
        end
    elseif tipe == "Window" then 
        for _, v in pairs(ctx.Cache.Windows) do 
            if v and v.Parent then 
                local weh = v:FindFirstChild("WindowEH")
                if weh then ctx.S.Debris:AddItem(weh, 0) end
            end 
        end
    elseif tipe == "Item" then
        for plr, esp in pairs(ctx.State.ItemESPs) do 
            if esp then ctx.S.Debris:AddItem(esp, 0) end 
        end
        table.clear(ctx.State.ItemESPs)
    elseif tipe == "Gate" then 
        for _, v in pairs(ctx.Cache.Gates) do 
            if v and v.Parent then 
                local geh = v:FindFirstChild("GateEH")
                local ge_text = v:FindFirstChild("GateE_Text")
                if geh then ctx.S.Debris:AddItem(geh, 0) end
                if ge_text then ctx.S.Debris:AddItem(ge_text, 0) end 
            end 
        end
    elseif tipe == "SCP" then 
        for _, v in pairs(ctx.Cache.SCPs) do 
            if v and v.Parent then 
                local seh = v:FindFirstChild("SCPEH")
                if seh then ctx.S.Debris:AddItem(seh, 0) end
            end 
        end
    end 
end

function ESP.ClearAllESP() 
    ESP.ClearESP("Player")
    ESP.ClearESP("Killer")
    ESP.ClearESP("Generator")
    ESP.ClearESP("Pallet")
    ESP.ClearESP("Hook")
    ESP.ClearESP("Item")
    ESP.ClearESP("Gate")
    ESP.ClearESP("SCP")
    ESP.ClearESP("Window")
end

local function extractAssetId(str)
    return tostring(str):match("%d+")
end

local function getItemIcon(itemName)
    local ItemsFolder = ctx.S.ReplicatedStorage:FindFirstChild("Items")
    if not ItemsFolder then return nil end
    local item = ItemsFolder:FindFirstChild(itemName)
    if not item then return nil end
    local tex
    pcall(function() tex = item.Texture or item.Image end)
    if tex and tex ~= "" then
        local id = extractAssetId(tex)
        if id then return ("rbxthumb://type=Asset&id=%s&w=420&h=420"):format(id) end
    end
    return nil
end

function ESP.CreateEsp(parent, idName, config)
    local billboard = parent:FindFirstChild(idName)
    local scale = config.lineScale or 1
    
    if not billboard then 
        billboard = Instance.new("BillboardGui")
        billboard.Name = idName
        billboard.Parent = parent
        
        if parent:IsA("Model") then
            billboard.Adornee = parent:FindFirstChild("Head") or parent:FindFirstChild("HumanoidRootPart") or parent.PrimaryPart
        else
            billboard.Adornee = parent
        end
        
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 250, 0, 100)
        
        local yOffset = config.offsetY or 0
        billboard.StudsOffset = Vector3.new(0, yOffset, 0) 
        
        local wrapper = Instance.new("Frame")
        wrapper.Name = "Wrapper"
        wrapper.AutomaticSize = Enum.AutomaticSize.XY
        wrapper.Size = UDim2.new(0, 0, 0, 0)
        wrapper.Position = UDim2.new(0.5, 25 * scale, 0.5, -25 * scale)
        wrapper.AnchorPoint = Vector2.new(0, 1) 
        wrapper.BackgroundTransparency = 1
        wrapper.ZIndex = 2
        wrapper.Parent = billboard
        
        local wrapperLayout = Instance.new("UIListLayout")
        wrapperLayout.FillDirection = Enum.FillDirection.Vertical
        wrapperLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        wrapperLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        wrapperLayout.Padding = UDim.new(0, 0) 
        wrapperLayout.SortOrder = Enum.SortOrder.LayoutOrder
        wrapperLayout.Parent = wrapper
        
        local statusTxt = Instance.new("TextLabel")
        statusTxt.Name = "StatusText"
        statusTxt.AutomaticSize = Enum.AutomaticSize.X
        statusTxt.Size = UDim2.new(0, 0, 0, 10) 
        statusTxt.BackgroundTransparency = 1
        statusTxt.Font = Enum.Font.GothamBold
        statusTxt.TextSize = 10 
        statusTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
        statusTxt.TextXAlignment = Enum.TextXAlignment.Center
        statusTxt.TextYAlignment = Enum.TextYAlignment.Bottom 
        statusTxt.ZIndex = 3
        statusTxt.LayoutOrder = 1
        statusTxt.Parent = wrapper
        
        local box = Instance.new("Frame")
        box.Name = "Box"
        box.AutomaticSize = Enum.AutomaticSize.X 
        box.Size = UDim2.new(0, 0, 0, 16)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        box.BackgroundTransparency = 0 
        box.BorderSizePixel = 0
        box.ZIndex = 2
        box.LayoutOrder = 2
        box.Parent = wrapper
        
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)
        
        local boxGradient = Instance.new("UIGradient")
        boxGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.15, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(0.85, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        })
        boxGradient.Parent = box
        
        local padding = Instance.new("UIPadding", box)
        padding.PaddingLeft = UDim.new(0, 8)
        padding.PaddingRight = UDim.new(0, 8)
        
        local layout = Instance.new("UIListLayout", box)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.Padding = UDim.new(0, 4) 
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local icon = Instance.new("ImageLabel", box)
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 12, 0, 12) 
        icon.BackgroundTransparency = 1
        icon.ZIndex = 3
        icon.LayoutOrder = 1
        icon.Visible = false
        
        local txt = Instance.new("TextLabel", box)
        txt.Name = "Text"
        txt.AutomaticSize = Enum.AutomaticSize.X
        txt.Size = UDim2.new(0, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamMedium 
        txt.TextSize = 11 
        txt.ZIndex = 3
        txt.LayoutOrder = 2
        txt.RichText = true
        txt.TextXAlignment = Enum.TextXAlignment.Center
        txt.TextYAlignment = Enum.TextYAlignment.Center

        local line = Instance.new("Frame")
        line.Name = "Line"
        line.Size = UDim2.new(0, 1, 0, 36 * scale) 
        line.Position = UDim2.new(0.5, 12 * scale, 0.5, -12 * scale) 
        line.AnchorPoint = Vector2.new(0.5, 0.5) 
        line.Rotation = 45 
        line.BorderSizePixel = 0
        line.ZIndex = 1
        line.Parent = billboard 

        local lineGradient = Instance.new("UIGradient")
        lineGradient.Rotation = 90
        lineGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1) 
        })
        lineGradient.Parent = line
    end
    
    if billboard:FindFirstChild("Wrapper") then
        billboard.Wrapper.Position = UDim2.new(0.5, 25 * scale, 0.5, -25 * scale)
    end
    if billboard:FindFirstChild("Line") then
        billboard.Line.Size = UDim2.new(0, 1, 0, 36 * scale)
        billboard.Line.Position = UDim2.new(0.5, 12 * scale, 0.5, -12 * scale)
        billboard.Line.BackgroundColor3 = config.color
    end
    
    local hexColor = string.format("#%02X%02X%02X", config.color.R * 255, config.color.G * 255, config.color.B * 255)
    
    local hookText = ""
    if config.hookCount and config.hookCount ~= "" then
        hookText = string.format(" <font color='#FF4444'>[%s]</font>", config.hookCount)
    end
    
    local box = billboard:FindFirstChild("Wrapper") and billboard.Wrapper:FindFirstChild("Box")
    if box then
        if config.distance then
            box.Text.Text = string.format("<font color='#FFFFFF'>%s</font>%s <font color='%s'>[%dm]</font>", config.name, hookText, hexColor, config.distance)
        elseif config.subtext then
            box.Text.Text = string.format("<font color='#FFFFFF'>%s</font>%s <font color='%s'>%s</font>", config.name, hookText, hexColor, config.subtext)
        else
            box.Text.Text = string.format("<font color='#FFFFFF'>%s</font>%s", config.name, hookText)
        end
        
        if config.icon and config.icon ~= "" then
            box.Icon.Image = config.icon
            box.Icon.Visible = true
        else
            box.Icon.Visible = false
        end
    end

    local statusLabel = billboard:FindFirstChild("Wrapper") and billboard.Wrapper:FindFirstChild("StatusText")
    if statusLabel then
        if config.status and config.status ~= "" then
            statusLabel.Text = config.status
            statusLabel.Visible = true
            if config.status == "Hook" then
                statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            elseif config.status == "Knock" then
                statusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
            elseif config.status == "Injured" then
                statusLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
            end
        else
            statusLabel.Visible = false 
        end
    end
end

function ESP.UpdatePlayerESP()
    if not ctx.Config.ESP_Master then return end
    local myHRP = ctx.GetCharacterRoot()
    
    if ctx.Config.ESP_KillerWarn and myHRP and ctx.GetRole() == "Survivor" then
        local warn = myHRP:FindFirstChild("KillerWarn")
        local closestDist = math.huge
        for _, p in ipairs(ctx.S.Players:GetPlayers()) do
            if p ~= ctx.S.LocalPlayer and ctx.IsKiller(p) and p.Character then
                local kHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if kHrp then
                    local dist = (kHrp.Position - myHRP.Position).Magnitude
                    if dist < closestDist then closestDist = dist end
                end
            end
        end
        if closestDist <= 80 then
            if not warn then
                warn = Instance.new("BillboardGui")
                warn.Name = "KillerWarn"
                warn.Size = UDim2.new(0, 28, 0, 28) 
                warn.AlwaysOnTop = true
                warn.StudsOffset = Vector3.new(0, 4, 0) 
                warn.Parent = myHRP
                
                local box = Instance.new("Frame")
                box.Name = "WarnBox"
                box.Size = UDim2.new(0.65, 0, 0.65, 0)
                box.Position = UDim2.new(0.5, 0, 0.5, 0)
                box.AnchorPoint = Vector2.new(0.5, 0.5)
                box.BackgroundTransparency = 1
                box.Rotation = 45 
                box.Parent = warn
                
                local stroke = Instance.new("UIStroke")
                stroke.Name = "WarnStroke"
                stroke.Thickness = 1
                stroke.Parent = box
                
                local txt = Instance.new("TextLabel")
                txt.Name = "WarnText"
                txt.Size = UDim2.new(0.8, 0, 0.8, 0)
                txt.Position = UDim2.new(0.5, 0, 0.5, 0)
                txt.AnchorPoint = Vector2.new(0.5, 0.5)
                txt.BackgroundTransparency = 1
                txt.TextScaled = true
                txt.TextStrokeTransparency = 0.4
                txt.Font = Enum.Font.GothamBlack
                txt.Text = "!" 
                txt.ZIndex = 2
                txt.Parent = warn
            end
            
            local txt = warn:FindFirstChild("WarnText")
            local box = warn:FindFirstChild("WarnBox")
            local stroke = box and box:FindFirstChild("WarnStroke")
            
            if txt and stroke then
                if closestDist <= 40 then
                    stroke.Color = Color3.fromRGB(255, 20, 20)
                    txt.TextColor3 = Color3.fromRGB(255, 20, 20)
                else
                    stroke.Color = Color3.fromRGB(255, 220, 0)
                    txt.TextColor3 = Color3.fromRGB(255, 220, 0)
                end
            end
        else
            if warn then warn:Destroy() end
        end
    else
        local warn = myHRP and myHRP:FindFirstChild("KillerWarn")
        if warn then warn:Destroy() end
    end

    if ctx.Config.ESP_Player or ctx.Config.ESP_Killer then
        for _, p in pairs(ctx.S.Players:GetPlayers()) do 
            if p ~= ctx.S.LocalPlayer and p.Character then
                local killerStatus = ctx.IsKiller(p)
                local root = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
                
                if root and ((not killerStatus and ctx.Config.ESP_Player) or (killerStatus and ctx.Config.ESP_Killer)) then
                    local distance = myHRP and math.floor((root.Position - myHRP.Position).Magnitude) or 0
                    local hName = killerStatus and "KEH" or "PEH"
                    local tName = killerStatus and "KE_Text" or "PE_Text"
                    
                    local wrongHName = killerStatus and "PEH" or "KEH"
                    local wrongTName = killerStatus and "PE_Text" or "KE_Text"
                    if p.Character:FindFirstChild(wrongHName) then p.Character[wrongHName]:Destroy() end
                    if p.Character:FindFirstChild(wrongTName) then p.Character[wrongTName]:Destroy() end
                    
                    if distance <= ctx.Config.ESP_MaxDistance then
                        local col = killerStatus and ctx.Tuning.Colors.Killer or ctx.Tuning.Colors.Player
                        local highlight = p.Character:FindFirstChild(hName)
                        if not highlight then 
                            highlight = Instance.new("Highlight")
                            highlight.Name = hName
                            highlight.Parent = p.Character 
                        end
                        highlight.FillColor = col
                        highlight.OutlineColor = col
                        highlight.FillTransparency = ctx.Config.ESP_Outline and 1 or (ctx.Config.Trans or 0.7)
                        highlight.OutlineTransparency = 0.5
                        
                        if ctx.Config.ESP_Name then
                            local equippedIcon = nil
                            local currentStatus = ""
                            local hookStr = ""
                            
                            if not killerStatus then
                                if ctx.Config.ESP_ItemIcon then
                                    local equippedName = p:GetAttribute("EquippedItem")
                                    if equippedName and equippedName ~= "" then
                                        equippedIcon = getItemIcon(equippedName)
                                    end
                                end
                                
                                local pChar = p.Character
                                local isHooked = pChar:GetAttribute("IsHooked")
                                local isKnocked = pChar:GetAttribute("Knocked")
                                local hum = pChar:FindFirstChildOfClass("Humanoid")
                                local isInjured = hum and hum.Health <= 60 and hum.Health > 0
                                
                                if isHooked then
                                    currentStatus = "Hook"
                                elseif isKnocked then
                                    currentStatus = "Knock"
                                elseif isInjured then
                                    currentStatus = "Injured"
                                end
                                
                                local hCount = pChar:GetAttribute("HookCount") or 0
                                if hCount == 1 then
                                    hookStr = "I"
                                elseif hCount == 2 then
                                    hookStr = "II"
                                elseif hCount >= 3 then
                                    hookStr = "III"
                                end
                            end
                            
                            ESP.CreateEsp(p.Character, tName, {
                                name = p.Name,
                                distance = distance,
                                color = col,
                                icon = equippedIcon,
                                status = currentStatus,
                                hookCount = hookStr,
                                lineScale = killerStatus and 0.6 or 1
                            })
                        else
                            local old = p.Character:FindFirstChild(tName)
                            if old then old:Destroy() end
                        end
                    else
                        local highlight = p.Character:FindFirstChild(hName)
                        local textEsp = p.Character:FindFirstChild(tName)
                        if highlight then highlight:Destroy() end
                        if textEsp then textEsp:Destroy() end
                    end
                end
            end 
        end
    end
end

function ESP.UpdateStaticESP()
    if not ctx.Config.ESP_Master then return end
    
    local myRoot = ctx.GetCharacterRoot()
    
    local function getDistanceSafe(targetPos)
        if not myRoot then return 0 end
        return math.floor((targetPos - myRoot.Position).Magnitude)
    end

    if ctx.Config.ESP_Generator then
        for i, vData in pairs(ctx.Cache.Generators) do 
            local v = vData.model
            if v and v.Parent and vData.part then
                local distance = getDistanceSafe(vData.part.Position)
                
                if distance <= ctx.Config.ESP_MaxDistance then
                    local progress = math.floor(v:GetAttribute("RepairProgress") or 0)
                    local playersRep = v:GetAttribute("PlayersRepairingCount") or 0
                    local col = (progress >= 100) and ctx.Tuning.Colors.GeneratorDone or ctx.Tuning.Colors.Generator
                    
                    local h = v:FindFirstChild("GEH")
                    if not h then 
                        h = Instance.new("Highlight")
                        h.Name = "GEH"
                        h.Parent = v 
                    end
                    h.FillColor = col
                    h.OutlineColor = col
                    h.FillTransparency = ctx.Config.ESP_Outline and 1 or (ctx.Config.Trans or 0.7)
                    h.OutlineTransparency = 0.5
                    
                    if ctx.Config.ESP_NameG then
                        local genSubtext = playersRep > 0 and string.format("[%d%%] (%d plyr)", progress, playersRep) or string.format("[%d%%]", progress)

                        ESP.CreateEsp(v, "GE_Text", {
                            name = "G " .. i,
                            subtext = genSubtext,
                            color = col,
                            icon = nil,
                            lineScale = 0.2
                        })
                    else
                        local oldText = v:FindFirstChild("GE_Text")
                        if oldText then oldText:Destroy() end
                    end

                else
                    if v:FindFirstChild("GEH") then v.GEH:Destroy() end
                    if v:FindFirstChild("GE_Text") then v.GE_Text:Destroy() end 
                end
            end
        end
    end
    
    if ctx.Config.ESP_Pallet then
        for _, palletData in pairs(ctx.Cache.Pallets) do
            local v = palletData.model
            if v and v.Parent then
                local distance = getDistanceSafe(v:GetPivot().Position)
                if distance <= ctx.Config.ESP_MaxDistance then
                    local h = v:FindFirstChild("PalletEH")
                    if not h then 
                        h = Instance.new("Highlight")
                        h.Name = "PalletEH"
                        h.Parent = v
                    end
                    local col = ctx.Tuning.Colors.Pallet
                    h.Adornee = v 
                    h.FillColor = col
                    h.OutlineColor = col
                    h.FillTransparency = ctx.Config.ESP_Outline and 1 or (ctx.Config.Trans or 0.7)
                    h.OutlineTransparency = 0.5
                else
                    if v:FindFirstChild("PalletEH") then v.PalletEH:Destroy() end
                end
            end
        end
    end
    
    if ctx.Config.ESP_Window then
        for i, v in ipairs(ctx.Cache.Windows) do 
            if v and v.Parent then
                local targetPart = v:FindFirstChild("Bottom") or v:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local distance = getDistanceSafe(targetPart.Position)
                    if distance <= ctx.Config.ESP_MaxDistance then
                        local h = v:FindFirstChild("WindowEH")
                        if not h then 
                            h = Instance.new("BoxHandleAdornment")
                            h.Name = "WindowEH"
                            h.Parent = v 
                            h.AlwaysOnTop = true
                            h.ZIndex = 5
                        end
                        h.Adornee = targetPart
                        h.Size = targetPart.Size
                        local col = ctx.Tuning.Colors.Window
                        h.Color3 = col
                        h.Transparency = ctx.Config.ESP_Outline and 0.8 or 0.4
                    else
                        if v:FindFirstChild("WindowEH") then v.WindowEH:Destroy() end
                    end
                end
            end 
        end
    end
    
    if ctx.Config.ESP_Hook then
        for i, v in ipairs(ctx.Cache.Hooks) do 
            if v and v.Parent then
                local distance = getDistanceSafe(v:GetPivot().Position)
                if distance <= ctx.Config.ESP_MaxDistance then
                    local h = v:FindFirstChild("HookEH")
                    if not h then 
                        h = Instance.new("Highlight")
                        h.Name = "HookEH"
                        h.Parent = v 
                    end
                    local col = ctx.Tuning.Colors.Hook
                    h.FillColor = col
                    h.OutlineColor = col
                    h.FillTransparency = ctx.Config.ESP_Outline and 1 or (ctx.Config.Trans or 0.7)
                    h.OutlineTransparency = 0.5
                else
                    if v:FindFirstChild("HookEH") then v.HookEH:Destroy() end
                end
            end 
        end
    end
    
    if ctx.Config.ESP_Gate then
        for i, v in ipairs(ctx.Cache.Gates) do 
            if v and v.Parent then
                local distance = getDistanceSafe(v:GetPivot().Position)
                if distance <= ctx.Config.ESP_MaxDistance then
                    local h = v:FindFirstChild("GateEH")
                    if not h then 
                        h = Instance.new("Highlight")
                        h.Name = "GateEH"
                        h.Parent = v 
                    end
                    local col = ctx.Tuning.Colors.Gate
                    h.Adornee = v
                    h.FillColor = col
                    h.OutlineColor = col
                    h.FillTransparency = ctx.Config.ESP_Outline and 1 or 0.5
                    h.OutlineTransparency = 0

                    local progress = 0
                    local exitLever = v:FindFirstChild("ExitLever")
                    if exitLever then
                        local mainPart = exitLever:FindFirstChild("Main")
                        if mainPart then
                            progress = math.floor(mainPart:GetAttribute("ActivationProgress") or 0)
                        end
                    end
                    
                    local gateSubtext = string.format("[%d%%]", progress)

                    ESP.CreateEsp(v, "GateE_Text", {
                        name = "Gate " .. i,
                        subtext = gateSubtext,
                        color = col,
                        icon = nil,
                        lineScale = 0.2
                    })

                else
                    if v:FindFirstChild("GateEH") then v.GateEH:Destroy() end
                    if v:FindFirstChild("GateE_Text") then v.GateE_Text:Destroy() end
                end
            end 
        end
    end
end

function ESP.UpdateSCPESP()
    if not ctx.Config.ESP_Master then return end
    if ctx.Config.ESP_SCP then
        for _, obj in ipairs(ctx.Cache.SCPs) do
            if obj and obj.Parent then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("Head") or obj.PrimaryPart
                
                if hum and root and math.floor(hum.WalkSpeed) > 0 and math.floor(hum.WalkSpeed) ~= 16 then
                    local col = ctx.Tuning.Colors.SCP
                    
                    local highlight = obj:FindFirstChild("SCPEH")
                    if not highlight then 
                        highlight = Instance.new("Highlight")
                        highlight.Name = "SCPEH"
                        highlight.Parent = obj 
                    end
                    highlight.FillColor = col
                    highlight.OutlineColor = col
                    highlight.FillTransparency = ctx.Config.ESP_Outline and 1 or (ctx.Config.Trans or 0.7)
                    highlight.Enabled = true
                    highlight.OutlineTransparency = 0.5
                else
                    local h = obj:FindFirstChild("SCPEH")
                    if h then h.Enabled = false end
                end
            end
        end
    else
        ESP.ClearESP("SCP")
    end
end

function ESP.SmoothHdr(Value)
    local Lighting = ctx.S.Lighting
    local Workspace = ctx.S.Workspace

    if Value then
        Lighting.GlobalShadows = true 
        Lighting.ClockTime = 12
        Lighting.Brightness = 3.2
        Lighting.ExposureCompensation = 0.1
        
        Lighting.OutdoorAmbient = Color3.fromRGB(230, 230, 230) 
        Lighting.Ambient = Color3.fromRGB(210, 210, 210)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)

        Lighting.EnvironmentDiffuseScale = 1 
        Lighting.EnvironmentSpecularScale = 1 
        
        Lighting.FogStart = 50
        Lighting.FogEnd = 500
        Lighting.FogColor = Color3.fromRGB(210, 210, 210)

        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") then
                v:Destroy()
            end
        end

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "Estetik_Bloom"
        bloom.Intensity = 0.05
        bloom.Size = 24
        bloom.Threshold = 2
        bloom.Parent = Lighting

        local sunRays = Instance.new("SunRaysEffect")
        sunRays.Name = "Estetik_SunRays"
        sunRays.Intensity = 0.04
        sunRays.Spread = 0.1
        sunRays.Parent = Lighting

        local atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "Estetik_Atmosphere"
        atmosphere.Density = 0.45
        atmosphere.Offset = 0.25
        atmosphere.Color = Color3.fromRGB(210, 210, 210)
        atmosphere.Decay = Color3.fromRGB(150, 150, 150)
        atmosphere.Glare = 0.2
        atmosphere.Haze = 2.5
        atmosphere.Parent = Lighting

        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            end
        end

        local cc = Lighting:FindFirstChild("HDR_Color") or Instance.new("ColorCorrectionEffect")
        cc.Name = "HDR_Color"
        cc.Saturation = 0.45
        cc.Contrast = 0.15
        cc.Brightness = 0.03
        cc.TintColor = Color3.fromRGB(255, 255, 255)
        cc.Parent = Lighting

    else
        if Lighting:FindFirstChild("HDR_Color") then Lighting.HDR_Color:Destroy() end
        if Lighting:FindFirstChild("Estetik_Bloom") then Lighting.Estetik_Bloom:Destroy() end
        if Lighting:FindFirstChild("Estetik_SunRays") then Lighting.Estetik_SunRays:Destroy() end
        if Lighting:FindFirstChild("Estetik_Atmosphere") then Lighting.Estetik_Atmosphere:Destroy() end
        Lighting.FogEnd = 100000
    end
end

local fullbrightConnections = {}

function ESP.ApplyFullbright()
    if not ctx.Config.Misc_Fullbright then return end
    
    if ctx.S.Lighting.Brightness ~= 1 then ctx.S.Lighting.Brightness = 1 end
    if ctx.S.Lighting.FogEnd ~= 100000 then ctx.S.Lighting.FogEnd = 100000 end
    if ctx.S.Lighting.GlobalShadows ~= false then ctx.S.Lighting.GlobalShadows = false end
    if ctx.S.Lighting.OutdoorAmbient ~= Color3.fromRGB(255, 255, 255) then 
        ctx.S.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) 
    end
    if ctx.S.Lighting.Ambient ~= Color3.fromRGB(255, 255, 255) then 
        ctx.S.Lighting.Ambient = Color3.fromRGB(255, 255, 255) 
    end
    
    local atm = ctx.S.Lighting:FindFirstChildOfClass("Atmosphere")
    if atm and atm.Density ~= 0 then 
        atm.Density = 0 
    end
end

function ESP.EnableFullbrightEvents()
    for _, conn in ipairs(fullbrightConnections) do 
        if conn.Connected then conn:Disconnect() end 
    end
    table.clear(fullbrightConnections)

    local propsToWatch = {"Brightness", "FogEnd", "GlobalShadows", "OutdoorAmbient", "Ambient"}
    for _, prop in ipairs(propsToWatch) do
        local conn = ctx.S.Lighting:GetPropertyChangedSignal(prop):Connect(function()
            if ctx.Config.Misc_Fullbright then
                ESP.ApplyFullbright()
            end
        end)
        table.insert(fullbrightConnections, conn)
    end
    
    local childConn = ctx.S.Lighting.ChildAdded:Connect(function(child)
        if ctx.Config.Misc_Fullbright and child:IsA("Atmosphere") then
            child.Density = 0
        end
    end)
    table.insert(fullbrightConnections, childConn)
end

function ESP.DisableFullbrightEvents()
    for _, conn in ipairs(fullbrightConnections) do 
        if conn.Connected then conn:Disconnect() end 
    end
    table.clear(fullbrightConnections)
end

return ESP
