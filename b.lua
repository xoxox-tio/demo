local Survivor = {}
local ctx

function Survivor.Init(context)
    ctx = context
end

function Survivor.BandageR()
    if ctx.State.Bandage then return end
    ctx.State.Bandage = true
    
    task.spawn(function()
        pcall(function()
            local remotes = ctx.S.ReplicatedStorage:FindFirstChild("Remotes")
            local items = remotes and remotes:FindFirstChild("Items")
            local bandageFolder = items and items:FindFirstChild("Bandage")
            local Event = bandageFolder and bandageFolder:FindFirstChild("Fire")
            
            local myChar = ctx.S.LocalPlayer.Character
            if Event and myChar then
                local bandageTool = myChar:FindFirstChild("Bandage") or ctx.S.LocalPlayer.Backpack:FindFirstChild("Bandage")
                
                if bandageTool then
                    local rightArm = bandageTool:FindFirstChild("Right Arm")
                    local targetBandage = (rightArm and rightArm:FindFirstChild("Bandage")) or bandageTool
                    
                    for i = 1, 400 do
                        Event:FireServer(true, targetBandage)
                        Event:FireServer(false, targetBandage)
                    end
                end
            end
        end)
        
        task.wait(0.1)
        ctx.State.Bandage = false
    end)
end

function Survivor.TriggerMobileButton()
    pcall(function()
        local b = ctx.S.LocalPlayer:FindFirstChild("PlayerGui")
        for segment in string.gmatch("Survivor-mob.Controls.action.check", "[^%.]+") do 
            if b then b = b:FindFirstChild(segment) end
        end

        if b and b:IsA("GuiObject") and b.Visible and b.Parent and b.Parent:IsA("GuiButton") then
            local btn = b.Parent
            if type(firesignal) == "function" then
                pcall(function()
                    firesignal(btn.MouseButton1Down)
                    task.wait(0.01)
                    firesignal(btn.MouseButton1Up)
                end)
            else
                local center = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
                local inset = ctx.S.GuiService:GetGuiInset()
                local x = center.X + inset.X
                local y = center.Y + inset.Y
                ctx.S.VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                task.wait(0.02)
                ctx.S.VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            end
        else
            ctx.S.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.012)
            ctx.S.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end)
end

function Survivor.SkillCheck()
    task.spawn(function()
        local PlayerGui = ctx.S.LocalPlayer:FindFirstChild("PlayerGui")
        local prompt = PlayerGui:WaitForChild("SkillCheckPromptGui", 10)
        if not prompt then return end
        
        local check = prompt:WaitForChild("Check", 8)
        if not check then return end
        
        local line = check:WaitForChild("Line", 5)
        local goal = check:WaitForChild("Goal", 5)
        if not (line and goal) then return end
        
        if ctx.State.VisibilityConnection then ctx.State.VisibilityConnection:Disconnect() end
        
        ctx.State.VisibilityConnection = check:GetPropertyChangedSignal("Visible"):Connect(function()
            if not ctx.Config.Surv_AutoSkillCheck or not (ctx.S.LocalPlayer.Team and ctx.S.LocalPlayer.Team.Name == "Survivors") then 
                return 
            end
            if not ctx.Config.Surv_PerfectSkill then 
                if ctx.State.HeartbeatConnection then ctx.State.HeartbeatConnection:Disconnect() ctx.State.HeartbeatConnection = nil end 
                return 
            end
            
            if check.Visible then
                local isInstan = ctx.Config.Surv_InstanSkill or (ctx.Config.Surv_SkillCheckMode == "Random" and not ctx.State.RandomMode_IsNormal)
                
                if isInstan then
                    local currentGoalRotation = goal.Rotation % 360
                    line.Rotation = currentGoalRotation + 85
                end
                
                local lastHitTick = 0 
                if ctx.State.HeartbeatConnection then ctx.State.HeartbeatConnection:Disconnect() end
                
                ctx.State.HeartbeatConnection = line:GetPropertyChangedSignal("Rotation"):Connect(function()
                    if not ctx.Config.Surv_PerfectSkill then
                        ctx.State.HeartbeatConnection:Disconnect() 
                        ctx.State.HeartbeatConnection = nil 
                        return
                    end
                    
                    local isNormalMode = ctx.Config.Surv_SkillCheckMode == "Normal" or (ctx.Config.Surv_SkillCheckMode == "Random" and ctx.State.RandomMode_IsNormal)
                    
                    local lr = line.Rotation % 360
                    local gr = goal.Rotation % 360
                    local ss = (gr + 105) % 360
                    local se = (gr + 115) % 360
                    
                    if isNormalMode then
                        ss = (gr + 116) % 360
                        se = (gr + 140) % 360
                    end
                    
                    local inZone = (ss > se and (lr >= ss or lr <= se)) or (lr >= ss and lr <= se)
                    
                    if inZone then
                        if tick() - lastHitTick > 0.2 then
                            Survivor.TriggerMobileButton()
                            lastHitTick = tick() 
                        end
                    end
                end)
            else
                ctx.State.RandomMode_IsNormal = false
                if ctx.State.HeartbeatConnection then ctx.State.HeartbeatConnection:Disconnect() ctx.State.HeartbeatConnection = nil end
            end
        end)
    end)
end

function Survivor.AutoPallet(Value)
    ctx.Config.Surv_AutoPallet = Value
    
    if Value then
        if ctx.State.AutoPalletThread then task.cancel(ctx.State.AutoPalletThread) end
        
        ctx.State.AutoPalletThread = task.spawn(function()
            while ctx.Config.Surv_AutoPallet and not ctx.State.Unloaded do
                task.wait(0.1)
                
                if ctx.PalletEvent then
                    local myChar = ctx.S.LocalPlayer.Character
                    local myRoot = ctx.GetCharacterRoot()
                    
                    if myRoot and myChar then
                        local isHooked = myChar:GetAttribute("IsHooked") == true
                        local isCarried = myChar:GetAttribute("IsCarried") == true
                        local isKnocked = (myChar:GetAttribute("Knocked")) == true and not isCarried

                        local canDrop = true
                        if isHooked or isKnocked then
                            canDrop = false
                        elseif isCarried and ctx.Config.Surv_AutoPalletSM then
                            canDrop = false
                        end
                        
                        if canDrop then
                            local activeKillers = {}
                            for _, p in ipairs(ctx.ActivePlayers) do
                                if ctx.IsKiller(p) and p.Character then
                                    local kRoot = p.Character:FindFirstChild("HumanoidRootPart")
                                    if kRoot then
                                        table.insert(activeKillers, { root = kRoot, char = p.Character })
                                    end
                                end
                            end
                            
                            if #activeKillers > 0 then
                                for _, palletData in ipairs(ctx.Cache.Pallets) do
                                    local palletModel = palletData.model
                                    local triggerPoint = palletData.trigger or (palletModel and (palletModel:FindFirstChild("PalletPointSlide", true) or palletModel:FindFirstChild("PalletPoint", true)))
                                    
                                    if palletModel and palletModel.Parent and triggerPoint and not ctx.State.DroppedPallets[palletModel] then
                                        local shouldDrop = false
                                        local distToMe = (myRoot.Position - triggerPoint.Position).Magnitude
                                        
                                        for _, kData in ipairs(activeKillers) do
                                            local distToKiller = (kData.root.Position - triggerPoint.Position).Magnitude
                                            local isKillerCarrying = kData.char:GetAttribute("IsCarrying") == true or kData.char:GetAttribute("isCarrying") == true
                                            
                                            if isCarried then
                                                if distToMe <= ctx.Config.Surv_AutoPalletRadius or distToKiller <= ctx.Config.Surv_AutoPalletRadius then
                                                    shouldDrop = true
                                                    break
                                                end
                                            elseif isKillerCarrying and ctx.Config.Surv_AutoPalletSF then
                                                if distToKiller <= 6.5 then
                                                    shouldDrop = true
                                                    break
                                                end
                                            else
                                                if distToMe <= ctx.Config.Surv_AutoPalletRadius and distToKiller <= ctx.Config.Surv_AutoPalletRadius then
                                                    shouldDrop = true
                                                    break
                                                end
                                            end
                                        end
                                        
                                        if shouldDrop then
                                            pcall(function() ctx.PalletEvent:FireServer(triggerPoint) end)
                                            ctx.State.DroppedPallets[palletModel] = true 
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    else
        if ctx.State.AutoPalletThread then 
            task.cancel(ctx.State.AutoPalletThread)
            ctx.State.AutoPalletThread = nil
        end
        table.clear(ctx.State.DroppedPallets) 
    end
end

function Survivor.StartRepairEngine()
    if ctx.State.RepairEngineRunning then return end
    ctx.State.RepairEngineRunning = true
    
    task.spawn(function()
        local lastScan = 0
        local genPoints = {}
        local currentlyRepairing = {}

        while ctx.Config.AUTO_Generator and not ctx.State.Unloaded do
            if tick() - lastScan > 2 then
                genPoints = {}
                for _, v in ipairs(ctx.Cache.Generators) do
                    local prog = v.model:GetAttribute("RepairProgress") or (v.model:FindFirstChild("RepairProgress") and v.model.RepairProgress.Value) or 0
                    if prog < 100 then 
                        for _, c in ipairs(v.model:GetChildren()) do 
                            if c.Name:match("GeneratorPoint") then 
                                table.insert(genPoints, {gen = v.model, pt = c}) 
                            end 
                        end 
                    else
                        for _, c in ipairs(v.model:GetChildren()) do
                            if c.Name:match("GeneratorPoint") then currentlyRepairing[c] = nil end
                        end
                    end
                end
                lastScan = tick()
            end
            
            if ctx.RepairEvent and ctx.SkillRemote then
                local root = ctx.GetCharacterRoot()
                
                for _, data in ipairs(genPoints) do
                    if root and (root.Position - data.pt.Position).Magnitude <= 20 then
                        if not currentlyRepairing[data.pt] then
                            pcall(ctx.RepairEvent.FireServer, ctx.RepairEvent, data.pt, true)
                            currentlyRepairing[data.pt] = true
                        end
                        local currentStatus = ctx.Config.Surv_PerfectSkill and "success" or "neutral"
                        pcall(ctx.SkillRemote.FireServer, ctx.SkillRemote, currentStatus, 100, data.gen, data.pt)

                    else
                        if currentlyRepairing[data.pt] then
                            pcall(ctx.RepairEvent.FireServer, ctx.RepairEvent, data.pt, false)
                            currentlyRepairing[data.pt] = nil
                        end
                    end
                end
            end
            task.wait(0.15)
        end
        
        if ctx.RepairEvent then
            for pt, _ in pairs(currentlyRepairing) do pcall(ctx.RepairEvent.FireServer, ctx.RepairEvent, pt, false) end
        end
        ctx.State.RepairEngineRunning = false
    end)
end

function Survivor.StopAutoGen()
    ctx.Config.AUTO_Generator = false
    pcall(function()
        local r = ctx.S.ReplicatedStorage:FindFirstChild("Remotes")
        local g = r and r:FindFirstChild("Generator")
        local repairRemote = g and g:FindFirstChild("RepairEvent")
        if repairRemote then 
            for _, genData in ipairs(ctx.Cache.Generators) do 
                for _, c in ipairs(genData.model:GetChildren()) do 
                    if c.Name:match("GeneratorPoint") then pcall(function() repairRemote:FireServer(c, false) end) end 
                end 
            end 
        end
        local char = ctx.S.LocalPlayer.Character
        if not char then return end
        for _, obj in pairs(char:GetDescendants()) do 
            if obj:IsA("Weld") or obj:IsA("WeldConstraint") or obj:IsA("ManualWeld") then 
                if (obj.Part0 and not obj.Part0:IsDescendantOf(char)) or (obj.Part1 and not obj.Part1:IsDescendantOf(char)) then 
                    obj:Destroy() 
                end 
            end 
        end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if humanoid then 
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            humanoid.PlatformStand = false
            humanoid.Sit = false
            humanoid.WalkSpeed = ctx.State.OriginalSpeed or 16
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then 
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop() end 
            end
        end
        if root then 
            root.Anchored = false
            root.CFrame = root.CFrame * CFrame.new(0, 0, 1.5) 
        end
    end)
end

function Survivor.GetSafeGenerator()
    local root = ctx.GetCharacterRoot()
    if not root then return nil end
    local bestGen, bestScore = nil, math.huge
    for _, genData in ipairs(ctx.Cache.Generators) do
        local progress = genData.model:GetAttribute("RepairProgress") or (genData.model:FindFirstChild("RepairProgress") and genData.model.RepairProgress.Value) or 0
        local playersRep = genData.model:GetAttribute("PlayersRepairingCount") or (genData.model:FindFirstChild("PlayersRepairingCount") and genData.model.PlayersRepairingCount.Value) or 0
        if progress < 100 and playersRep < 4 then
            local killerDistToGen = math.huge
            for _, p in pairs(ctx.S.Players:GetPlayers()) do 
                if p ~= ctx.S.LocalPlayer and ctx.IsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then 
                    local d = (p.Character.HumanoidRootPart.Position - genData.part.Position).Magnitude
                    if d < killerDistToGen then killerDistToGen = d end 
                end 
            end
            if killerDistToGen > (ctx.Config.AUTO_LeaveDist + 15) then 
                local distToUs = ctx.GetDistance(genData.part.Position)
                if distToUs < bestScore then 
                    bestScore = distToUs
                    bestGen = genData 
                end 
            end
        end
    end
    return bestGen
end

function Survivor.LeaveGenerator()
    local root = ctx.GetCharacterRoot()
    if not root then return false end
    task.spawn(Survivor.StopAutoGen)
    local nearestKiller, killerDist = nil, math.huge
    for _, p in pairs(ctx.S.Players:GetPlayers()) do 
        if p ~= ctx.S.LocalPlayer and ctx.IsKiller(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then 
            local d = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if d < killerDist then 
                killerDist = d
                nearestKiller = p.Character.HumanoidRootPart 
            end 
        end 
    end
    if nearestKiller and killerDist <= ctx.Config.AUTO_LeaveDist then
        local dir = (root.Position - nearestKiller.Position).Unit
        if dir.Magnitude ~= dir.Magnitude then dir = Vector3.new(1,0,0) end
        local escapePos = root.Position + (dir * (ctx.Config.AUTO_LeaveDist + 20))
        root.CFrame = CFrame.new(escapePos + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

function Survivor.TeleportToGeneratorObj(targetGenData)
    local root = ctx.GetCharacterRoot()
    if not root or not targetGenData then return false end
    local dir = (root.Position - targetGenData.part.Position).Unit
    if dir.Magnitude ~= dir.Magnitude then dir = Vector3.new(0, 0, 1) end
    local safePos = targetGenData.part.Position + (dir * ctx.Config.TP_Offset)
    root.CFrame = CFrame.new(safePos + Vector3.new(0, 3, 0), targetGenData.part.Position)
    return true
end

function Survivor.MultiGen(Value)
    ctx.Config.Surv_DoubleGen = Value
    if Value then
        if ctx.State.DoubleGenThread then task.cancel(ctx.State.DoubleGenThread) end
        
        ctx.State.DoubleGenThread = task.spawn(function()
            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            local repairRemote = remotes and remotes:FindFirstChild("Generator") and remotes.Generator:FindFirstChild("RepairEvent")
            
            local lastRepairState = false
            local activeGenPoints = {} 
            
            while ctx.Config.Surv_DoubleGen and not ctx.State.Unloaded do
                task.wait(0.2)

                local myChar = ctx.S.LocalPlayer.Character
                if ctx.GetRole() == "Survivor" and myChar then
                    local interactObj = myChar:FindFirstChild("CheckInterractable")
                    local isRepairing = (interactObj and interactObj:GetAttribute("isRepairing") == true) or (myChar:GetAttribute("isRepairing") == true)

                    if isRepairing and not lastRepairState then
                        lastRepairState = true
                        activeGenPoints = {}

                        task.wait(0.2)
                        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                        if myRoot and repairRemote then
                            for _, genData in ipairs(ctx.Cache.Generators) do
                                if (myRoot.Position - genData.part.Position).Magnitude <= 15 then
                                    for _, child in ipairs(genData.model:GetChildren()) do
                                        if string.match(child.Name, "GeneratorPoint") then
                                            local isOccupied = child:GetAttribute("IsRepairing") == true or child:GetAttribute("isRepairing") == true
                                            if not isOccupied then
                                                table.insert(activeGenPoints, child)
                                                pcall(function() repairRemote:FireServer(child, true) end)
                                            end
                                        end
                                    end
                                    break
                                end
                            end
                        end

                    elseif not isRepairing and lastRepairState then
                        lastRepairState = false
                        if repairRemote then
                            for _, pt in ipairs(activeGenPoints) do
                                pcall(function() repairRemote:FireServer(pt, false) end)
                            end
                        end
                        activeGenPoints = {}
                    end
                end
            end
        end)
    else
        if ctx.State.DoubleGenThread then 
            task.cancel(ctx.State.DoubleGenThread)
            ctx.State.DoubleGenThread = nil
        end
    end
end

function Survivor.SkillS(char)
    if not char then return end

    local customSounds = {
        Great = "rbxassetid://111033165135961",
        Sound = "rbxassetid://138997442392324"
    }

    local targetScripts = {"Skillcheck-gen", "Skillcheck-player"}

    task.spawn(function()
        for _, scriptName in ipairs(targetScripts) do
            local sc = char:WaitForChild(scriptName, 5)
            if sc then
                for soundName, soundId in pairs(customSounds) do
                    local snd = sc:WaitForChild(soundName, 5)
                    if snd and snd:IsA("Sound") then
                        if not snd:GetAttribute("OriginalSoundId") then
                            snd:SetAttribute("OriginalSoundId", snd.SoundId)
                        end

                        if ctx.Config.Surv_SoundDbd then
                            snd.SoundId = soundId
                        else
                            local originalId = snd:GetAttribute("OriginalSoundId")
                            if originalId then
                                snd.SoundId = originalId
                            end
                        end
                    end
                end
            end
        end
    end)
end

function Survivor.ParryButton()
    pcall(function()
        local playerGui = ctx.S.LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local survivorMob = playerGui:FindFirstChild("Survivor-mob")
        local parryBtn = survivorMob and survivorMob:FindFirstChild("Controls") and survivorMob.Controls:FindFirstChild("Gui-mob")

        if parryBtn and parryBtn:IsA("GuiObject") and parryBtn.Visible then
            if type(firesignal) == "function" then
                pcall(function()
                    firesignal(parryBtn.MouseButton1Down)
                    task.wait(0.01)
                    firesignal(parryBtn.MouseButton1Up)
                end)
            end
        else
            pcall(function()
                ctx.S.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
                task.wait(0.01)
                ctx.S.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
            end)
        end
    end)
end

function Survivor.ExecuteParry()
    if ctx.State.ParryCooldown then return end
    pcall(function()
        if ctx.ParryRemote then
            ctx.ParryRemote:FireServer()
        end
        task.spawn(Survivor.ParryButton)
    end)
end

function Survivor.ParryV2S(isActive)
    if isActive then
        if ctx.State.Pv2Con then return end

        ctx.State.Pv2Con = ctx.S.RunService.Heartbeat:Connect(function()
            if ctx.State.ParryCooldown then return end

            local myChar = ctx.S.LocalPlayer.Character
            if not myChar or ctx.IsDowned(myChar) or not ctx.IsSafeToParry(myChar) then return end

            local myHRP = myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end

            local radius = ctx.Config.Surv_ParryRadius or 15
            local checkRadius = radius + 5

            for _, p in ipairs(ctx.ActiveKillers) do
                local kChar = p.Character
                if not kChar then continue end
                local kHRP = kChar:FindFirstChild("HumanoidRootPart")
                if not kHRP then continue end

                local dist = (myHRP.Position - kHRP.Position).Magnitude
                if dist > checkRadius then continue end

                local humanoid = kChar:FindFirstChildOfClass("Humanoid")
                if not humanoid then continue end

                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then continue end

                local isFacingMe = false
                local myPosFlat = Vector3.new(myHRP.Position.X, 0, myHRP.Position.Z)
                local kPosFlat = Vector3.new(kHRP.Position.X, 0, kHRP.Position.Z)
                local flatDelta = myPosFlat - kPosFlat

                if flatDelta.Magnitude > 0 then
                    local flatDirection = flatDelta.Unit
                    local kLookFlat = Vector3.new(kHRP.CFrame.LookVector.X, 0, kHRP.CFrame.LookVector.Z).Unit
                    local dotProduct = kLookFlat:Dot(flatDirection)
                    isFacingMe = (dotProduct >= (ctx.Config.Surv_ParryFace or 0.85))
                end

                if not isFacingMe then continue end

                local playingTracks = animator:GetPlayingAnimationTracks()
                for _, track in ipairs(playingTracks) do
                    if not ctx.State.TrackV2[track] then
                        ctx.State.TrackV2[track] = true

                        local animId = track.Animation and track.Animation.AnimationId or ""
                        local id = animId:match("%d+")
                        local attackName = ctx.VALID_PARRY_IDS[id]

                        if attackName then
                            if not (ctx.Config.Ignored_Skills_List and ctx.Config.Ignored_Skills_List[attackName]) then
                                if dist <= ctx.Config.Surv_ParryRadius then
                                    Survivor.ExecuteParry()
                                end
                            end
                        end
                    end
                end
            end

            for track, _ in pairs(ctx.State.TrackV2) do
                if not track.IsPlaying then
                    ctx.State.TrackV2[track] = nil
                end
            end
        end)
    else
        if ctx.State.Pv2Con then
            ctx.State.Pv2Con:Disconnect()
            ctx.State.Pv2Con = nil
        end
        table.clear(ctx.State.TrackV2)
    end
end

function Survivor.TriggerCrouch(time)
    pcall(function()
        local b = ctx.S.LocalPlayer:FindFirstChild("PlayerGui")

        for segment in string.gmatch("Survivor-mob.Controls.crouch.icon", "[^%.]+") do
            if b then
                b = b:FindFirstChild(segment)
            end
        end

        if b and b:IsA("GuiObject") and b.Visible and b.Parent and b.Parent:IsA("GuiButton") then
            local btn = b.Parent

            if ctx.S.UserInputService.TouchEnabled and type(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                task.wait(time)
                firesignal(btn.MouseButton1Click)
            else
                ctx.S.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(time)
                ctx.S.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            end
        else
            ctx.S.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait(time)
            ctx.S.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
    end)
end

function Survivor.TeleportToEscape()
    local root = ctx.GetCharacterRoot()
    local map = ctx.S.Workspace:FindFirstChild("Map")
    if not root or not map then return false end
    
    local exitPos = nil
    
    pcall(function()
        for _, obj in ipairs(map:GetDescendants()) do
            local nameLower = string.lower(obj.Name)
            if nameLower == "fininshline" or nameLower == "finishline" or string.find(nameLower, "finish") then
                if obj:IsA("BasePart") then
                    exitPos = obj.Position
                    break
                elseif obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        exitPos = part.Position
                        break
                    end
                end
            end
        end

        if not exitPos then
            if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then 
                exitPos = Vector3.new(3098.16, 454.04, -4918.74)
            elseif map:FindFirstChild("HooksMeat") then 
                exitPos = Vector3.new(1546.12, 152.21, -796.72)
            elseif map:FindFirstChild("churchbell") then 
                exitPos = Vector3.new(760.98, -20.14, -78.48)
            else
                for _, obj in ipairs(map:GetDescendants()) do 
                    if obj:IsA("MeshPart") and obj.Material == Enum.Material.Limestone then 
                        exitPos = Vector3.new(-947.90, 152.12, -7579.52)
                        break 
                    elseif obj:IsA("MeshPart") and obj.Material == Enum.Material.Leather then 
                        exitPos = Vector3.new(1546.12, 152.21, -796.72)
                        break 
                    end 
                end
            end
        end
    end)
    
    if exitPos then 
        root.CFrame = CFrame.new(exitPos + Vector3.new(0, 3, 0)) 
        return true
    end
    
    return false
end

return Survivor
