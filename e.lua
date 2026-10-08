local Combat = {}
local ctx

function Combat.Init(context)
    ctx = context
end

function Combat.GetTargetPartObject(char)
    if ctx.Config.AIM_TargetPart == "Head" then
        return char:FindFirstChild("Head")
    elseif ctx.Config.AIM_TargetPart == "Root" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    end
end

function Combat.GetUnifiedTarget(targetType)
    local bestTarget = nil
    local closestDist = math.huge
    local centerScreen = Vector2.new(ctx.S.Camera.ViewportSize.X / 2, ctx.S.Camera.ViewportSize.Y / 2)
    
    local myChar = ctx.S.LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    if targetType == "Pistol" and ctx.Config.Pistol_BlockKnocked and ctx.IsPlayerBusy(myChar) then 
        return nil 
    end

    for _, p in ipairs(ctx.ActivePlayers) do
        if p.Character then
            local isKiller = ctx.IsKiller(p)
            local isValidTarget = false
            local myRole = ctx.GetRole()

            if targetType == "Survivor" and not isKiller then isValidTarget = true
            elseif targetType == "Killer" and isKiller then isValidTarget = true
            elseif targetType == "Flash" and isKiller then isValidTarget = true
            elseif targetType == "Pistol" then
                if ctx.Config.Pistol_Target == "Killer" and isKiller then
                    isValidTarget = true
                elseif ctx.Config.Pistol_Target == "Survivor" and not isKiller then
                    isValidTarget = true
                end
            elseif targetType == "Aimbot" then
                if myRole == "Survivor" and isKiller then
                    isValidTarget = true
                elseif myRole == "Killer" and not isKiller then
                    isValidTarget = true
                end
            end

            if isValidTarget then
                local targetChar = p.Character
                local hum = targetChar:FindFirstChildOfClass("Humanoid")

                if hum and hum.Health > 0 and not ctx.IsDowned(targetChar) then
                    local partName = "HumanoidRootPart"

                    if targetType == "Aimbot" or targetType == "Pistol" then
                        if ctx.Config.AIM_TargetPart == "Head" or ctx.Config.AIM_TargetPart == 1 then
                            partName = "Head"
                        elseif ctx.Config.AIM_TargetPart == "Torso" or ctx.Config.AIM_TargetPart == 2 then
                            partName = "Torso"
                        end
                    end

                    local targetPart = targetChar:FindFirstChild(partName)
                        or targetChar:FindFirstChild("Torso")
                        or targetChar:FindFirstChild("HumanoidRootPart")

                    if targetPart then
                        local dist3D = (targetPart.Position - myHRP.Position).Magnitude
                        local maxDist = math.huge

                        if targetType == "Survivor" then
                            maxDist = ctx.Config.SPEAR_MaxDist
                        elseif targetType == "Aimbot" then
                            if ctx.GetRole() == "Killer" then
                                maxDist = 10
                            else
                                maxDist = ctx.Config.Aimbot_MaxDist
                            end
                        end

                        if dist3D <= maxDist then
                            local useFOV = false
                            local fovRadius = 0

                            if targetType == "Aimbot" and ctx.Config.Aimbot_ShowFOV and ctx.GetRole() ~= "Killer" then
                                useFOV = true
                                fovRadius = ctx.Config.Aimbot_Radius
                            elseif targetType == "Pistol" and ctx.Config.Pistol_FOVMode then
                                useFOV = true
                                fovRadius = ctx.Config.Pistol_FOV
                            elseif targetType == "Survivor" and ctx.Config.Veil_ShowFOV then
                                useFOV = true
                                fovRadius = ctx.Config.Veil_FOV
                            end

                            if useFOV then
                                local screenPos, onScreen = ctx.S.Camera:WorldToViewportPoint(targetPart.Position)

                                if onScreen then
                                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude

                                    if dist2D < closestDist and dist2D <= fovRadius then
                                        closestDist = dist2D
                                        bestTarget = targetPart
                                    end
                                end
                            else
                                if dist3D < closestDist then
                                    closestDist = dist3D
                                    bestTarget = targetPart
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if targetType == "Pistol" and ctx.Config.Pistol_Target == "SCP" then
        for _, obj in ipairs(ctx.Cache.SCPs) do
            if obj and obj.Parent then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if hum and root and math.floor(hum.WalkSpeed) > 0 and math.floor(hum.WalkSpeed) ~= 16 then
                    local targetPart = root
                    if (ctx.Config.AIM_TargetPart == "Head" or ctx.Config.AIM_TargetPart == 1) and obj:FindFirstChild("Head") then targetPart = obj.Head
                    elseif (ctx.Config.AIM_TargetPart == "Torso" or ctx.Config.AIM_TargetPart == 2) and obj:FindFirstChild("Torso") then targetPart = obj.Torso end
                    
                    local screenPos, onScreen = ctx.S.Camera:WorldToViewportPoint(targetPart.Position)
                    
                    if ctx.Config.Pistol_FOVMode then
                        if onScreen then
                            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                            if dist2D < closestDist and dist2D <= ctx.Config.Pistol_FOV then
                                closestDist = dist2D
                                bestTarget = targetPart
                            end
                        end
                    else
                        local dist3D = (targetPart.Position - myHRP.Position).Magnitude
                        if dist3D < closestDist then
                            closestDist = dist3D
                            bestTarget = targetPart
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

function Combat.FaceTarget(targetPart, smoothness)
    if not targetPart then return end
    smoothness = smoothness or 0.2
    local targetCFrame = CFrame.lookAt(ctx.S.Camera.CFrame.Position, targetPart.Position)
    ctx.S.Camera.CFrame = ctx.S.Camera.CFrame:Lerp(targetCFrame, smoothness)
end

function Combat.GPP(startPos, targetPart, bulletSpeed)
    local targetPos = targetPart.Position
    
    if not ctx.Config.Predict then
        return targetPos
    end
    
    local targetChar = targetPart.Parent
    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    
    local flatVel = Vector3.new(0, 0, 0)
    local speed = 0
    
    if targetHum then
        flatVel = targetHum.MoveDirection * targetHum.WalkSpeed
        speed = flatVel.Magnitude
    end
    
    if speed < 0.1 then
        return targetPos
    end
    
    local ping = math.clamp(ctx.State.CurrentPing, 0, 0.25)
    local initialDistance = (targetPos - startPos).Magnitude
    local extraLead = ctx.Config.Pistol_PredictLead
    local timeToHit = ((initialDistance / bulletSpeed) * extraLead) + ping
    local finalPrediction = targetPos + (flatVel * timeToHit)
    
    return finalPrediction
end

function Combat.AimFire()
    local targetPart = Combat.GetUnifiedTarget("Pistol")
    local myChar = ctx.S.LocalPlayer.Character
    
    if ctx.Config.Pistol_BlockKnocked and ctx.IsPlayerBusy(myChar) then 
        return 
    end
    
    if targetPart and myChar then
        local myPart = myChar:FindFirstChild("HumanoidRootPart")
        
        if myPart then
            local twistOfFate = myChar:FindFirstChild("Twist of Fate")
            if twistOfFate then
                local weaponArg = twistOfFate
                local rightArm = twistOfFate:FindFirstChild("Right Arm")
                if rightArm then
                    if rightArm:FindFirstChild("EmperorGun") then
                        weaponArg = rightArm:FindFirstChild("EmperorGun")
                    elseif rightArm:FindFirstChild("gun") then
                        weaponArg = rightArm:FindFirstChild("gun")
                    else 
                        weaponArg = rightArm
                    end
                end
                
                local startPos = myPart.Position
                local bulletSpeed = 160
                
                local predictedPos = Combat.GPP(startPos, targetPart, bulletSpeed)
                local distanceToPredicted = (predictedPos - startPos).Magnitude
                
                if distanceToPredicted < 4 then
                    predictedPos = predictedPos - (targetPart.CFrame.RightVector * -2)
                end
                
                local offset = Vector3.new(0, ctx.Config.Pistol_AimOffset, 0)
                local aimDirection = ((predictedPos + offset) - startPos).Unit
                
                local remotes = ctx.S.ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("Items") and remotes.Items:FindFirstChild("Twist of Fate") and remotes.Items["Twist of Fate"]:FindFirstChild("Fire") then
                    remotes.Items["Twist of Fate"].Fire:FireServer(weaponArg, aimDirection)
                end
            end
        end
    end
end

function Combat.HideVeilTrajectory(trajectoryBeams, veilT)
    if trajectoryBeams then
        for _, b in ipairs(trajectoryBeams) do
            b.Enabled = false
        end
    end
    if veilT then
        veilT.Visible = false
    end
end

function Combat.UpdateTrajectoryPrediction(startPos, aimDirection, currentSpearSpeed, gravValue, myChar, targetPart, predictedPos, trajectoryBeams, beamAttachments, veilT, maxBeamSegments)
    local launchVelocity = aimDirection * currentSpearSpeed
    local maxDist = math.max(ctx.Config.SPEAR_MaxDist or 500, 500)
    local targetPos = targetPart and targetPart.Position
    local distToTarget = targetPos and (targetPos - startPos).Magnitude or 100
    
    local timeToHit = distToTarget / currentSpearSpeed
    local timeStep = timeToHit / maxBeamSegments

    local currentPos = startPos
    local currentVelocity = launchVelocity
    local gravityVec = Vector3.new(0, -gravValue, 0)

    local points = {startPos}
    local minDistanceToTarget = math.huge
    local checkPoint = predictedPos or targetPos

    for i = 1, maxBeamSegments do
        local nextPos = currentPos + (currentVelocity * timeStep) + (0.5 * gravityVec * (timeStep ^ 2))
        table.insert(points, nextPos)
        
        if checkPoint then
            local d = (nextPos - checkPoint).Magnitude
            if d < minDistanceToTarget then
                minDistanceToTarget = d
            end
        end

        currentPos = nextPos
        currentVelocity = currentVelocity + (gravityVec * timeStep)
    end

    local isHit = (targetPart ~= nil) and (distToTarget <= maxDist) and (minDistanceToTarget <= 6.0)
    local activeColor = isHit and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
    local seqColor = ColorSequence.new(activeColor)

    for i = 1, #points do
        if beamAttachments[i] then
            beamAttachments[i].WorldPosition = points[i]
        end
    end

    for i = 1, maxBeamSegments do
        if i < #points and ctx.Config.Veil_ShowLaser then
            trajectoryBeams[i].Color = seqColor
            trajectoryBeams[i].Enabled = true
        else
            trajectoryBeams[i].Enabled = false
        end
    end

    if targetPart then
        local targetViewPos, onScreen = ctx.S.Camera:WorldToViewportPoint(targetPart.Position)
        if onScreen and targetViewPos.Z > 0 then
            veilT.Position = Vector2.new(targetViewPos.X, targetViewPos.Y)
            veilT.Visible = true
            veilT.Color = isHit and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(255, 60, 60)
        else
            veilT.Visible = false
        end
    else
        veilT.Visible = false
    end
end

return Combat
