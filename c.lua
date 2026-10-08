local Killer = {}
local ctx

function Killer.Init(context)
    ctx = context
end

function Killer.GetKillerUI()
    local playerGui = ctx.S.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    for _, gui in pairs(playerGui:GetChildren()) do
        if string.sub(gui.Name, -4) == "-mob" and gui.Name ~= "Survivor-mob" then
            return gui
        end
    end
    return nil
end

function Killer.KillerPredict()
    if ctx.S.LocalPlayer.Team and ctx.S.LocalPlayer.Team.Name == "Spectator" then
        if not ctx.State.isPredicting then
            ctx.State.isPredicting = true
            if ctx.UIElements.Spectator then ctx.UIElements.Spectator.KillerFrame.Visible = true end
            task.spawn(function()
                while ctx.State.isPredicting and not ctx.State.Unloaded do
                    local bestPlayer, highestChance = nil, -1
                    for _, p in ipairs(ctx.S.Players:GetPlayers()) do
                        local allowKiller = p:GetAttribute("AllowKiller")
                        local killerChance = p:GetAttribute("KillerChance")
                        if allowKiller == true and type(killerChance) == "number" and killerChance > highestChance then
                            highestChance, bestPlayer = killerChance, p
                        end
                    end
                    if not bestPlayer then
                        for _, p in ipairs(ctx.S.Players:GetPlayers()) do
                            local killerChance = p:GetAttribute("KillerChance")
                            if type(killerChance) == "number" and killerChance > highestChance then
                                highestChance, bestPlayer = killerChance, p
                            end
                        end
                    end
                    if ctx.UIElements.Spectator then
                        if bestPlayer then
                            local kType = bestPlayer:FindFirstChild("SelectedKiller") and bestPlayer.SelectedKiller.Value or bestPlayer:GetAttribute("SelectedKiller") or "Unknown"
                            ctx.UIElements.Spectator.KillerText.Text = string.format("Killer: %s (%s)", bestPlayer.Name, kType)
                        else
                            ctx.UIElements.Spectator.KillerText.Text = "Killer: Tidak ada data"
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    else
        ctx.State.isPredicting = false
        if ctx.UIElements.Spectator then ctx.UIElements.Spectator.KillerFrame.Visible = false end
    end
end

function Killer.NoCD(Value)
    if not Value then
        if getgenv().CleanupNoCD then getgenv().CleanupNoCD() end
        return
    end

    if ctx.GetRole() ~= "Killer" then
        if getgenv().Library then ctx.Notif("Akses Ditolak: Kamu bukan Killer!", 3) end
        task.defer(function() if ctx.Toggles and ctx.Toggles.Killer_NoCDToggle then ctx.Toggles.Killer_NoCDToggle:SetValue(false) end end)
        return 
    end
    
    local selectedKillerObj = ctx.S.LocalPlayer:FindFirstChild("SelectedKiller")
    local killerName = selectedKillerObj and selectedKillerObj.Value or ctx.S.LocalPlayer:GetAttribute("SelectedKiller")
    
    if killerName ~= "Hidden" and killerName ~= "Stalker" then
        if getgenv().Library then ctx.Notif("Fitur ini hanya untuk Stalker atau Hidden!", 3) end
        task.defer(function() if ctx.Toggles and ctx.Toggles.Killer_NoCDToggle then ctx.Toggles.Killer_NoCDToggle:SetValue(false) end end)
        return
    end

    getgenv().NoCD_Active = true

    if ctx.KillerNoCDLoop then task.cancel(ctx.KillerNoCDLoop) end
    
    local cachedPowers = {}
    pcall(function()
        for _, fn in pairs(getgc(true)) do
            if type(fn) == "function" and islclosure(fn) and not isexecutorclosure(fn) then
                local info = getinfo(fn)
                if info and info.source and string.find(info.source, "Powers") then
                    table.insert(cachedPowers, fn)
                end
            end
        end
    end)
    
    ctx.KillerNoCDLoop = task.spawn(function()
        while getgenv().NoCD_Active and not ctx.State.Unloaded do
            task.wait(1)
            pcall(function()
                for _, fn in ipairs(cachedPowers) do
                    local info = getinfo(fn)
                    local upvals = getupvalues(fn)
                    
                    if killerName == "Hidden" and (info.name == "tryActivate" or info.name == "playM2Animation") then
                        for i, v in pairs(upvals) do
                            if type(v) == "boolean" and v == true then
                                setupvalue(fn, i, false)
                            end
                        end
                    elseif killerName == "Stalker" then
                        if info.name == "updateUI" then
                            for k, v in pairs(upvals) do
                                if type(v) == "boolean" then
                                    setupvalue(fn, k, true) 
                                end
                            end
                        elseif info.name == "" then
                            local boolCount, totalCount, boolKey = 0, 0, nil
                            for k, v in pairs(upvals) do
                                totalCount = totalCount + 1
                                if type(v) == "boolean" then
                                    boolCount = boolCount + 1
                                    boolKey = k
                                end
                            end
                            if totalCount == 1 and boolCount == 1 then
                                setupvalue(fn, boolKey, false)
                            end
                        end
                    end
                end
            end)
        end
    end)
end

function Killer.InvisibleSlasher(Value)
    if not Value then
        if getgenv().SlasherInvisLoop then 
            task.cancel(getgenv().SlasherInvisLoop)
            getgenv().SlasherInvisLoop = nil
        end
        return
    end

    if getgenv().SlasherInvisLoop then task.cancel(getgenv().SlasherInvisLoop) end

    local cachedSlasherFns = {}
    pcall(function()
        for _, fn in pairs(getgc(true)) do
            if type(fn) == "function" and islclosure(fn) and not isexecutorclosure(fn) then
                local info = getinfo(fn)
                if info and info.source and string.find(info.source, "Powers") then
                    table.insert(cachedSlasherFns, fn)
                end
            end
        end
    end)

    getgenv().SlasherInvisLoop = task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                local selectedKiller = ctx.S.LocalPlayer:FindFirstChild("SelectedKiller")
                local killerName = selectedKiller and selectedKiller.Value or ctx.S.LocalPlayer:GetAttribute("SelectedKiller")

                if ctx.GetRole() == "Killer" and killerName == "Slasher" then
                    
                    for _, fn in ipairs(cachedSlasherFns) do
                        local upvals = getupvalues(fn)
                        for i, v in pairs(upvals) do
                            if type(v) == "boolean" and v == true then
                                setupvalue(fn, i, false)
                            end
                        end
                    end

                    local char = ctx.S.LocalPlayer.Character
                    if char then
                        if char:GetAttribute("LakeMist") then char:SetAttribute("LakeMist", false) end
                        if char:GetAttribute("Invisibility") then char:SetAttribute("Invisibility", false) end
                        
                        local checkInt = char:FindFirstChild("CheckInterractable")
                        if checkInt and checkInt:GetAttribute("action") then
                            checkInt:SetAttribute("action", false)
                        end
                    end
                end
            end)
        end
    end)
end

function Killer.GetClosestTarget()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myChar = ctx.S.LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if not myHRP then return nil end

    for _, player in ipairs(ctx.S.Players:GetPlayers()) do
        if player ~= ctx.S.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and not ctx.IsDowned(player.Character) then
                local targetHRP = player.Character.HumanoidRootPart
                local distance = (myHRP.Position - targetHRP.Position).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player.Character
                end
            end
        end
    end
    return closestPlayer
end

function Killer.DashLock()
    if ctx.State.isAimLocking then return end
    
    if tick() - (ctx.State.lastAimLockTime or 0) < 0.2 then return end 
    ctx.State.lastAimLockTime = tick()
    
    if ctx.GetRole() == "Killer" then
        ctx.State.currentTarget = Killer.GetClosestTarget()
        
        if ctx.State.currentTarget and ctx.State.currentTarget:FindFirstChild("HumanoidRootPart") then
            ctx.State.isAimLocking = true
            
            if ctx.State.lockTimerThread then task.cancel(ctx.State.lockTimerThread) end
            
            ctx.State.lockTimerThread = task.delay(2, function()
                ctx.State.isAimLocking = false
                ctx.State.currentTarget = nil
                ctx.State.lockTimerThread = nil
            end)
        end
    end
end

function Killer.AutoLock(Value)
    if not Value then
        if getgenv().DashRenderConn then getgenv().DashRenderConn:Disconnect(); getgenv().DashRenderConn = nil end
        if getgenv().DashInputConn then getgenv().DashInputConn:Disconnect(); getgenv().DashInputConn = nil end
        if getgenv().DashMobileLoop then task.cancel(getgenv().DashMobileLoop); getgenv().DashMobileLoop = nil end
        if getgenv().DashMobileBtnConn then getgenv().DashMobileBtnConn:Disconnect(); getgenv().DashMobileBtnConn = nil end
        ctx.State.isAimLocking = false
        ctx.State.currentTarget = nil
        return
    end

    getgenv().DashRenderConn = ctx.S.RunService.RenderStepped:Connect(function()
        if ctx.State.isAimLocking and ctx.State.currentTarget and ctx.State.currentTarget:FindFirstChild("HumanoidRootPart") then
            local targetPosition = ctx.State.currentTarget.HumanoidRootPart.Position
            local newCameraCFrame = CFrame.lookAt(ctx.S.Camera.CFrame.Position, targetPosition)
            ctx.S.Camera.CFrame = ctx.S.Camera.CFrame:Lerp(newCameraCFrame, 0.6)
        else
            ctx.State.isAimLocking = false
        end
    end)

    getgenv().DashInputConn = ctx.S.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Killer.DashLock()
        end
    end)

    getgenv().DashMobileLoop = task.spawn(function()
        local lastButton = nil
        local pGui = ctx.S.LocalPlayer:WaitForChild("PlayerGui", 10)
        
        while task.wait(2) do
            pcall(function()
                if pGui then
                    local hiddenMob = pGui:FindFirstChild("Hidden-mob")
                    local move2Btn = hiddenMob and hiddenMob:FindFirstChild("Controls") and hiddenMob.Controls:FindFirstChild("move2")
                    
                    if move2Btn and move2Btn ~= lastButton then
                        if getgenv().DashMobileBtnConn then getgenv().DashMobileBtnConn:Disconnect() end
                        lastButton = move2Btn
                        
                        getgenv().DashMobileBtnConn = move2Btn.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                                Killer.DashLock()
                            end
                        end)
                    end
                end
            end)
        end
    end)
end

function Killer.InfLunge()
    if ctx.State.isHoldingLunge then return end
    ctx.State.isHoldingLunge = true
    
    task.spawn(function()
        while ctx.State.isHoldingLunge and ctx.Config.Killer_InfLunge and ctx.GetRole() == "Killer" do
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.Attacks.Lunge:FireServer()
            end)
            task.wait(0.05) 
        end
    end)
end

function Killer.InfLungeV2(char)
    if not char then return end
    char:SetAttribute("lungeboost", 999)
    if ctx.State.lungeV2Connection then ctx.State.lungeV2Connection:Disconnect() end
    
    ctx.State.lungeV2Connection = char:GetAttributeChangedSignal("lungeboost"):Connect(function()
        if ctx.Config.Killer_InfLungeV2 and char:GetAttribute("lungeboost") ~= 999 then
            char:SetAttribute("lungeboost", 999)
        end
    end)
end

function Killer.FireAbyssalSkill()
    if ctx.GetRole() ~= "Killer" then return end
    local selectedKillerObj = ctx.S.LocalPlayer:FindFirstChild("SelectedKiller")
    local killerName = selectedKillerObj and selectedKillerObj.Value or ctx.S.LocalPlayer:GetAttribute("SelectedKiller")
    
    if string.find(string.lower(tostring(killerName)), "abyss") then
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.Killers.Abysswalker.corrupt:FireServer()
        end)
    end
end

function Killer.StartInfiniteAbyssal()
    if ctx.State.isHolding then return end
    ctx.State.isHolding = true
    
    task.spawn(function()
        while ctx.State.isHolding and ctx.Config.Killer_InfAbyssal and ctx.GetRole() == "Killer" do
            Killer.FireAbyssalSkill()
            task.wait(0.5)
        end
    end)
end

function Killer.BlockVault(state)
    if not ctx.GlobalRemotes then return end
    
    local windowRemotes = ctx.GlobalRemotes:FindFirstChild("Window")
    local palletRemotes = ctx.GlobalRemotes:FindFirstChild("Pallet")
    
    if windowRemotes then
        for _, windowModel in ipairs(ctx.Cache.Windows) do
            if windowModel and windowModel.Parent then
                if state then
                    local trigger = windowModel:FindFirstChild("VaultTrigger", true)
                    if trigger then
                        pcall(function()
                            windowRemotes:FindFirstChild("VaultEvent"):FireServer(trigger, true)
                        end)
                    end
                else
                    local point = windowModel:FindFirstChild("VaultPointInUse", true)
                    if point then
                        pcall(function()
                            windowRemotes:FindFirstChild("VaultCompleteEvent"):FireServer(point, false)
                        end)
                    end
                end
            end
        end
    end

    if palletRemotes then
        for _, palletModel in ipairs(ctx.Cache.Pallets) do
            if palletModel and palletModel.Parent then
                if state then
                    local slideTrigger = palletModel:FindFirstChild("PalletPointSlide", true)
                    if slideTrigger then
                        pcall(function()
                            palletRemotes:FindFirstChild("PalletSlideEvent"):FireServer(slideTrigger, true)
                        end)
                    end
                else
                    local slideInUse = palletModel:FindFirstChild("PalletPointSlideInUse", true)
                    if slideInUse then
                        pcall(function()
                            palletRemotes:FindFirstChild("PalletSlideCompleteEvent"):FireServer(slideInUse)
                        end)
                    end
                end
            end
        end
    end
end

return Killer
