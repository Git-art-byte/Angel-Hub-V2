-- // Dynamic Banlist Loader (fetches from your separate GitHub file)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BANLIST_URL = "https://raw.githubusercontent.com/Git-art-byte/Angel-Hub-V2/refs/heads/main/Banlist.luau"

local BlacklistedIDs = {}
local success, result = pcall(function()
    return loadstring(game:HttpGet(BANLIST_URL))()
end)

if success and typeof(result) == "table" then
    BlacklistedIDs = result
end

if table.find(BlacklistedIDs, LocalPlayer.UserId) then
    LocalPlayer:Kick("You have been from Angel Hub, you can no longer use it.")
end

if _G.XenoLoaded then
    return
end
_G.XenoLoaded = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game.Players.LocalPlayer

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local bustStart = remotes:WaitForChild("AttemptATMBustStart")
local bustEnd = remotes:WaitForChild("AttemptATMBustComplete")
local RemoteStart = remotes:WaitForChild("RequestStartJobSession")
local RemoteEnd = remotes:WaitForChild("RequestEndJobSession")

local antiAfkConnection

local function ExecuteServerHop()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceID = game.PlaceId

    -- QUEUEING (Only here, right before teleport)
    local qot = syn and syn.queue_on_teleport or queue_on_teleport
        or (fluxus and fluxus.queue_on_teleport)
    if qot then
        qot([[
repeat task.wait() until game:IsLoaded()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Git-art-byte/Angel-Hub/refs/heads/main/DrivingEmpireXeno.luau"))()
]])
    end

    local success = false
    local attempts = 0
    while not success and attempts < 10 do
        attempts = attempts + 1
        local url = 'https://games.roblox.com/v1/games/' .. PlaceID ..
            '/servers/Public?sortOrder=Desc&limit=100'
        local pcall_success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if pcall_success and response and response.data then
            local candidates = {}
            for _, server in pairs(response.data) do
                if server.id ~= game.JobId and tonumber(server.playing) <
                    tonumber(server.maxPlayers) then
                    table.insert(candidates, server)
                end
            end
            table.sort(candidates, function(a, b) return a.playing < b.playing end)
            if #candidates > 0 then
                local range = math.min(5, #candidates)
                local target = candidates[math.random(1, range)]
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(PlaceID, target.id,
                        game.Players.LocalPlayer)
                    success = true
                end)
            end
        end
        if not success then task.wait(1.5) end
    end
end

-- Default Settings (Global Variables)
_G.SpeedEnabled = false
_G.SpeedMode = "Legit"
_G.SpeedValue = 16

local Window = Rayfield:CreateWindow({
    Name = "Angel Hub | Driving Empire",
    Icon = "car",
    LoadingTitle = "Driving Empire",
    LoadingSubtitle = "by Ange",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DrivingEmpireScripts",
        FileName = "DrivingEmpireHub"
    },
})

-- Tabs
local TabPlayer = Window:CreateTab("Player", "user")
local TabVehicle = Window:CreateTab("Vehicle", "car-front")
local TabFarm = Window:CreateTab("Farms", "tractor")
local TabStats = Window:CreateTab("Statistics", "bar-chart-2")
local TabVisuals = Window:CreateTab("Visuals", "eye")
local TabJobs = Window:CreateTab("Jobs", "briefcase")
local TabTest = Window:CreateTab("Test", "user")

-- PLAYER SECTION
local function GetMyVehicle()
    local folder = workspace:FindFirstChild("Vehicles")
    if not folder then return nil end
    for _, veh in pairs(folder:GetChildren()) do
        local owner = veh:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer.Name then
            return veh
        end
    end
    return nil
end

local SelectedPlayerName = nil
local PlayerDropdown

local function getPlayerNames()
    local names = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then -- Don't add ourselves to the list
            table.insert(names, player.Name)
        end
    end
    return names
end

local TeleportSection = TabPlayer:CreateSection("General")

TabPlayer:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAfkToggle",
    Callback = function(Value)
        if Value then
            -- Enabling Anti-AFK
            if antiAfkConnection then antiAfkConnection:Disconnect() end
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(), workspace.CurrentCamera.CFrame)
            end)
            Rayfield:Notify({Title = "Player Settings", Content = "Anti-AFK has been activated!", Duration = 3})
        else
            -- Disabling Anti-AFK
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end
            Rayfield:Notify({Title = "Player Settings", Content = "Anti-AFK has been disabled.", Duration = 3})
        end
    end,
})

TabPlayer:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Rayfield:Notify({Title = "Server Hop", Content = "Searching for server...", Duration = 3})
        ExecuteServerHop()
    end,
})

-- =============================================================================
-- CONFIGURATION AND VARIABLES
-- =============================================================================
local BypassActive = false
local HookInstalled = false
local BlockCount = 0
local TargetRemotes = {
    ["StarwatchClientEventIngestor"] = true, ["_network"] = true,
    ["rsp"] = true, ["rps"] = true, ["rsi"] = true, ["rs"] = true, ["rsw"] = true,
    ["ptsstop"] = true, ["ptsstart"] = true, ["SdkTelemetryRemote"] = true,
    ["TeleportInfo"] = true, ["SendLogString"] = true, ["GetClientLogs"] = true,
    ["GetClientFPS"] = true, ["GetClientPing"] = true, ["GetClientMemoryUsage"] = true,
    ["GetClientPerformanceStats"] = true, ["GetClientReport"] = true,
    ["RepBL"] = true, ["UnauthorizedTeleport"] = true, ["ClientDetectedSoftlock"] = true,
    ["loadTime"] = true, ["InformLoadingEventFunnel"] = true, ["InformGeneralEventFunnel"] = true
}

local BypassLabel = TabPlayer:CreateLabel("Bypass: System Armed (Waiting for activation)")

-- =============================================================================
-- 1. IMMEDIATE INSTALLATION (EARLY HOOK)
-- =============================================================================
local function InstallEarlyHook()
    if HookInstalled then return end
    local success, err = pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if BypassActive and (method == "FireServer" or method == "InvokeServer") then
                local remoteName = tostring(self)
                -- [BLOCKING LOGIC]
                local shouldBlock = false

                -- A. Checking blacklist names
                if TargetRemotes[remoteName] then
                    shouldBlock = true
                end

                -- B. Checking dynamic IDs (Fixed pattern: 8 hex chars + dash)
                -- Prevents blocking "Attempt" and "Capture"
                if not shouldBlock and string.match(remoteName, "^%x%x%x%x%x%x%x%x%-") then
                    shouldBlock = true
                end

                -- C. Specific block: Location -> Boats
                if not shouldBlock and remoteName == "Location" and args[1] == "Enter" and args[2] == "Boats" then
                    shouldBlock = true
                end

                -- [EXECUTE BLOCK]
                if shouldBlock then
                    BlockCount = BlockCount + 1
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if success then
        HookInstalled = true
        print("[BYPASS] Hook installed successfully.")
    else
        warn("[BYPASS] Critical Error: " .. tostring(err))
    end
end

InstallEarlyHook()

-- =============================================================================
-- 3. MONITORING AND SYNC LOOP
-- =============================================================================
task.spawn(function()
    while true do
        if BypassActive then
            local remotesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if remotesFolder then
                BypassLabel:Set("Status: ACTIVE (" .. BlockCount .. " blocked)")
                local children = remotesFolder:GetChildren()
                for _, remote in ipairs(children) do
                    local n = remote.Name
                    -- Automatically add new GUIDs to list (with safe pattern)
                    if string.match(n, "^%x%x%x%x%x%x%x%x%-") and not TargetRemotes[n] then
                        TargetRemotes[n] = true
                    end
                end
            else
                BypassLabel:Set("Status: Waiting for game engine...")
            end
        else
            BypassLabel:Set("Status: Disabled")
        end
        task.wait(2)
    end
end)

-- =============================================================================
-- 4. TOGGLE
-- =============================================================================
TabPlayer:CreateToggle({
    Name = "Bypass Monitor Events Exe LvL 8",
    CurrentValue = false,
    Flag = "BypassToggle",
    Callback = function(Value)
        BypassActive = Value
        if Value then
            BlockCount = 0
            Rayfield:Notify({
                Title = "Bypass Active",
                Content = "Log blocking, rsp/rps and boats active.",
                Duration = 3,
                Image = 4483362458,
            })
        else
            BypassLabel:Set("Status: Disabled")
        end
    end,
})

local TeleportSection = TabPlayer:CreateSection("Player Teleport")

-- Variable storing selected player
local SelectedPlayerName = nil

-- 1. DROPDOWN (Player Selection)
local PlayerDropdown = TabPlayer:CreateDropdown({
    Name = "Select Player",
    Options = getPlayerNames(),
    CurrentOption = "",
    MultipleOptions = false,
    Flag = "TargetPlayerDropdown",
    Callback = function(Option)
        SelectedPlayerName = Option[1]
    end,
})

-- 2. REFRESH BUTTON (Manual)
TabPlayer:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        if PlayerDropdown then
            local names = getPlayerNames()
            PlayerDropdown:Set(names)
            Rayfield:Notify({
                Title = "List Updated",
                Content = "Found " .. #names .. " players in Workspace.",
                Duration = 3
            })
        end
    end,
})

TabPlayer:CreateButton({
    Name = "Teleport To Player",
    Callback = function()
        if not SelectedPlayerName then return end
        local targetPlayer = Players:FindFirstChild(SelectedPlayerName)
        if not targetPlayer or not targetPlayer.Character then return end
        -- READ WORLD PIVOT (Independent of whether player is in car or not)
        local targetPivot = targetPlayer.Character:GetPivot()
        local destCFrame = targetPivot * CFrame.new(0, 8, 0) -- 8 studs above target
        local myVeh = GetMyVehicle()
        local isDriving = myVeh and myVeh:FindFirstChild("Driver") and myVeh.Driver.Value == LocalPlayer
        if isDriving and myVeh then
            -- --- VEHICLE TELEPORT ---
            local allParts = {}
            for _, p in pairs(myVeh:GetDescendants()) do
                if p:IsA("BasePart") then table.insert(allParts, p) end
            end
            -- Vehicle pivot as reference point
            local currentVehPivot = myVeh:GetPivot()
            -- Freeze
            for _, p in pairs(allParts) do p.Anchored = true end
            -- Move entire car model to target position using PivotTo
            myVeh:PivotTo(destCFrame)
            task.wait(0.2)
            -- Unfreeze and clear physics
            for _, p in pairs(allParts) do
                p.AssemblyLinearVelocity = Vector3.new(0,0,0)
                p.AssemblyAngularVelocity = Vector3.new(0,0,0)
                p.Anchored = false
            end
        else
            -- --- PLAYER TELEPORT ---
            if LocalPlayer.Character then
                LocalPlayer.Character:PivotTo(destCFrame)
            end
        end
    end,
})

local PlayerSection = TabPlayer:CreateSection("Movement Settings")

TabPlayer:CreateToggle({
    Name = "Speed",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(Value)
        _G.SpeedEnabled = Value
        -- Reset WalkSpeed to normal value on disable
        if not Value then
            pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
        end
    end,
})

TabPlayer:CreateDropdown({
    Name = "Speed Mode",
    Options = {"Legit", "HVH", "Normal", "CFrame"},
    CurrentOption = {"Legit"},
    MultipleOptions = false,
    Flag = "SpeedMode",
    Callback = function(Options)
        _G.SpeedMode = Options[1]
    end,
})

TabPlayer:CreateSlider({
    Name = "Custom Speed",
    Range = {0, 300},
    Increment = 1,
    Suffix = " Studs",
    CurrentValue = 16,
    Flag = "SpeedValue",
    Callback = function(Value)
        _G.SpeedValue = Value
    end,
})

-- MOVEMENT CHECK FUNCTION
local function isMoving()
    local character = LocalPlayer.Character
    local camera = workspace.CurrentCamera
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false, Vector3.new()
    end
    local moveDirection = camera.CFrame.LookVector
    moveDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z)
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit
    end
    local movement = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        movement = movement + moveDirection
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        movement = movement - moveDirection
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        movement = movement + Vector3.new(-moveDirection.Z, 0, moveDirection.X)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        movement = movement + Vector3.new(moveDirection.Z, 0, -moveDirection.X)
    end
    if movement.Magnitude > 0 then
        return true, movement.Unit
    else
        return false, Vector3.new()
    end
end

-- MAIN LOGIC LOOP
RunService.RenderStepped:Connect(function()
    if _G.SpeedEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") and
            character:FindFirstChild("HumanoidRootPart") then
            local moving, direction = isMoving()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local wartoscspeed = _G.SpeedValue or 16
            if moving then
                if _G.SpeedMode == "Normal" then
                    humanoid.WalkSpeed = wartoscspeed
                elseif _G.SpeedMode == "CFrame" then
                    hrp.CFrame = hrp.CFrame + (direction * (wartoscspeed / 50))
                elseif _G.SpeedMode == "Legit" then
                    -- Movement based on Velocity (harder to detect by simple anti-cheats)
                    hrp.Velocity = Vector3.new(direction.X * wartoscspeed, hrp.Velocity.Y, direction.Z * wartoscspeed)
                elseif _G.SpeedMode == "HVH" then
                    -- Bypasses and aggressive movement (e.g., BunnyHop)
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        humanoid.Jump = true
                        hrp.Velocity = Vector3.new(direction.X * wartoscspeed, hrp.Velocity.Y, direction.Z * wartoscspeed)
                    else
                        hrp.Velocity = Vector3.new(direction.X * wartoscspeed, hrp.Velocity.Y, direction.Z * wartoscspeed)
                    end
                end
            else
                -- Stop Velocity if no keys pressed (prevents sliding)
                if _G.SpeedMode == "Legit" or _G.SpeedMode == "HVH" then
                    hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
                end
            end
        end
    end
end)

----------- Fly Mode --------------------
local flyConnection
_G.FlySpeed = _G.FlySpeed or 50
_G.FlyEnabled = false

local FlySection = TabPlayer:CreateSection("Flight Settings")

TabPlayer:CreateToggle({
    Name = "Flight",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        _G.FlyEnabled = Value
        -- Reset old connection
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if _G.FlyEnabled then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not humanoid then
                _G.FlyEnabled = false
                return
            end
            -- Create flight instances directly in HumanoidRootPart
            local vFly = hrp:FindFirstChild("IY_FlyVelocity") or Instance.new("BodyVelocity")
            vFly.Name = "IY_FlyVelocity"
            vFly.Parent = hrp
            vFly.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            vFly.Velocity = Vector3.new(0, 0, 0)
            local vGyro = hrp:FindFirstChild("IY_FlyGyro") or Instance.new("BodyGyro")
            vGyro.Name = "IY_FlyGyro"
            vGyro.Parent = hrp
            vGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            vGyro.CFrame = hrp.CFrame
            humanoid.PlatformStand = true
            -- Main fly loop
            flyConnection = RunService.RenderStepped:Connect(function()
                if _G.FlyEnabled and char and hrp and humanoid then
                    local camera = workspace.CurrentCamera
                    local direction = Vector3.new(0,0,0)
                    -- Controls
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end
                    vGyro.CFrame = camera.CFrame
                    if direction.Magnitude > 0 then
                        vFly.Velocity = direction.Unit * _G.FlySpeed
                    else
                        vFly.Velocity = Vector3.new(0, 0, 0)
                    end
                else
                    -- Clean up if character dies or Fly disabled
                    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
                end
            end)
        else
            -- DISABLE AND CLEANUP
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.PlatformStand = false end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if hrp:FindFirstChild("IY_FlyVelocity") then hrp.IY_FlyVelocity:Destroy() end
                        if hrp:FindFirstChild("IY_FlyGyro") then hrp.IY_FlyGyro:Destroy() end
                    end
                end
            end)
        end
    end,
})

TabPlayer:CreateSlider({
    Name = "Fly Speed",
    Range = {0, 500},
    Increment = 1,
    Suffix = " Velocity",
    CurrentValue = 50,
    Flag = "FlySpeedValue",
    Callback = function(Value)
        _G.FlySpeed = Value
    end,
})

------------------- ESP Mode ----------------------------
-- ==========================================
-- ESP CONFIGURATION AND VARIABLES
-- ==========================================
_G.ESP_Enabled = false
_G.ESP_Targets = {
    Players = true,
    Police = true,
    Criminals = true
}
_G.ESP_Settings = {
    Boxes = false,
    Tracers = false,
    Skeletons = false,
    Names = false,
    Thickness = 1,
}

local ESP_Objects = {}
local Camera = workspace.CurrentCamera

-- JOB COLOR FUNCTION
local function GetJobColor(player)
    local job = player:GetAttribute("JobId")
    if job == "Security" then return Color3.fromRGB(0, 0, 255) -- Deep Blue
    elseif job == "Criminal" then return Color3.fromRGB(255, 0, 0) -- Really Red
    end
    return Color3.fromRGB(0, 255, 0) -- Neutral Lime
end

-- ESP OBJECT CREATION FUNCTION
local function CreateESP(player)
    if ESP_Objects[player] then return end
    local objects = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Skeleton = {
            Spine = Drawing.new("Line"),
            LeftArm = Drawing.new("Line"),
            RightArm = Drawing.new("Line"),
            LeftLeg = Drawing.new("Line"),
            RightLeg = Drawing.new("Line")
        }
    }
    -- Base Settings
    objects.Box.Filled = false
    objects.Name.Center = true
    objects.Name.Outline = true
    objects.Name.Size = 14
    ESP_Objects[player] = objects
end

local function RemoveESP(player)
    if ESP_Objects[player] then
        local obj = ESP_Objects[player]
        obj.Box:Remove()
        obj.Tracer:Remove()
        obj.Name:Remove()
        for _, line in pairs(obj.Skeleton) do line:Remove() end
        ESP_Objects[player] = nil
    end
end

-- Initialize Players
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- ==========================================
-- USER INTERFACE (TabVisuals)
-- ==========================================
local SectionMaster = TabVisuals:CreateSection("Master Control")

TabVisuals:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP_Master",
    Callback = function(v) _G.ESP_Enabled = v end,
})

local SectionTargets = TabVisuals:CreateSection("Targets (Filters)")

TabVisuals:CreateToggle({
    Name = "Players (Neutral)",
    CurrentValue = true,
    Flag = "Target_P",
    Callback = function(v) _G.ESP_Targets.Players = v end,
})

TabVisuals:CreateToggle({
    Name = "Police (Security)",
    CurrentValue = true,
    Flag = "Target_Pol",
    Callback = function(v) _G.ESP_Targets.Police = v end,
})

TabVisuals:CreateToggle({
    Name = "Criminals",
    CurrentValue = true,
    Flag = "Target_Crim",
    Callback = function(v) _G.ESP_Targets.Criminals = v end,
})

local SectionStyles = TabVisuals:CreateSection("Visual Styles")

TabVisuals:CreateToggle({
    Name = "Boxes 2D",
    CurrentValue = false,
    Flag = "ESP_Box",
    Callback = function(v) _G.ESP_Settings.Boxes = v end,
})

TabVisuals:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "ESP_Tracers",
    Callback = function(v) _G.ESP_Settings.Tracers = v end,
})

TabVisuals:CreateToggle({
    Name = "Skeletons",
    CurrentValue = false,
    Flag = "ESP_Skeleton",
    Callback = function(v) _G.ESP_Settings.Skeletons = v end,
})

TabVisuals:CreateToggle({
    Name = "Show Names & Distance",
    CurrentValue = false,
    Flag = "ESP_Names",
    Callback = function(v) _G.ESP_Settings.Names = v end,
})

TabVisuals:CreateSlider({
    Name = "Line Thickness",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = "px",
    CurrentValue = 1,
    Flag = "ESP_Thick",
    Callback = function(v) _G.ESP_Settings.Thickness = v end,
})

-- ==========================================
-- MAIN RENDERING LOGIC (Loop)
-- ==========================================
local function GetDynamicColor(player)
    local job = player:GetAttribute("JobId")
    -- If Police AND toggle Police is on -> Blue
    if job == "Security" and _G.ESP_Targets.Police then
        return Color3.fromRGB(0, 0, 255)
    end
    -- If Criminal AND toggle Criminals is on -> Red
    if job == "Criminal" and _G.ESP_Targets.Criminals then
        return Color3.fromRGB(255, 0, 0)
    end
    -- Other cases -> Lime
    return Color3.fromRGB(0, 255, 0)
end

RunService.RenderStepped:Connect(function()
    for player, obj in pairs(ESP_Objects) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        -- VISIBILITY LOGIC
        local isTarget = _G.ESP_Enabled and _G.ESP_Targets.Players
        if isTarget and hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local color = GetDynamicColor(player)
                local dist = math.floor((Camera.CFrame.p - hrp.Position).magnitude)
                local thickness = _G.ESP_Settings.Thickness
                -- RENDER BOX 2D
                if _G.ESP_Settings.Boxes then
                    local sizeX = 2000 / pos.Z
                    local sizeY = 3000 / pos.Z
                    obj.Box.Visible = true
                    obj.Box.Color = color
                    obj.Box.Thickness = thickness
                    obj.Box.Size = Vector2.new(sizeX, sizeY)
                    obj.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                else obj.Box.Visible = false end
                -- RENDER TRACERS
                if _G.ESP_Settings.Tracers then
                    obj.Tracer.Visible = true
                    obj.Tracer.Color = color
                    obj.Tracer.Thickness = thickness
                    obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    obj.Tracer.To = Vector2.new(pos.X, pos.Y)
                else obj.Tracer.Visible = false end
                -- RENDER NAMES
                if _G.ESP_Settings.Names then
                    obj.Name.Visible = true
                    obj.Name.Color = Color3.new(1,1,1)
                    obj.Name.Position = Vector2.new(pos.X, pos.Y - (3000 / pos.Z) / 2 - 20)
                    obj.Name.Text = string.format("%s\n[%s studs]", player.Name, dist)
                else obj.Name.Visible = false end
                -- RENDER SKELETON (R15/R6 Basic)
                if _G.ESP_Settings.Skeletons and char:FindFirstChild("Head") then
                    local headPos = Camera:WorldToViewportPoint(char.Head.Position)
                    obj.Skeleton.Spine.Visible = true
                    obj.Skeleton.Spine.From = Vector2.new(headPos.X, headPos.Y)
                    obj.Skeleton.Spine.To = Vector2.new(pos.X, pos.Y)
                    obj.Skeleton.Spine.Color = color
                    obj.Skeleton.Spine.Thickness = thickness
                else
                    for _, l in pairs(obj.Skeleton) do l.Visible = false end
                end
            else
                -- Off-screen
                obj.Box.Visible = false
                obj.Tracer.Visible = false
                obj.Name.Visible = false
                for _, l in pairs(obj.Skeleton) do l.Visible = false end
            end
        else
            -- Disabled
            obj.Box.Visible = false
            obj.Tracer.Visible = false
            obj.Name.Visible = false
            for _, l in pairs(obj.Skeleton) do l.Visible = false end
        end
    end
end)

---------- Job Joiner ----------------------
local JobActions = TabJobs:CreateSection("Jobs Joiner")

-- BUTTON: POLICE JOB
TabJobs:CreateButton({
    Name = "Police Job (Join/Leave)",
    Callback = function()
        local currentJob = LocalPlayer:GetAttribute("JobId")
        if currentJob == "Security" then
            -- Leave if already Police
            local args = {"jobPad"}
            RemoteEnd:FireServer(unpack(args))
        else
            -- Join otherwise
            local args = {"Security", "jobPad"}
            RemoteStart:FireServer(unpack(args))
        end
    end,
})

-- BUTTON: CRIMINAL JOB
TabJobs:CreateButton({
    Name = "Criminal Job (Join/Leave)",
    Callback = function()
        local currentJob = LocalPlayer:GetAttribute("JobId")
        if currentJob == "Criminal" then
            -- Leave if already Criminal
            local args = {"jobPad"}
            RemoteEnd:FireServer(unpack(args))
        else
            -- Join otherwise
            local args = {"Criminal", "jobPad"}
            RemoteStart:FireServer(unpack(args))
        end
    end,
})

-- Status indicator section
local StatusSection = TabJobs:CreateSection("Current Status")
local CurrentJobLabel = TabJobs:CreateLabel("Current Role: Unknown")

task.spawn(function()
    while task.wait(1) do
        local job = LocalPlayer:GetAttribute("JobId")
        if job == "Security" then
            CurrentJobLabel:Set("Current Role: Police Officer")
        elseif job == "Criminal" then
            CurrentJobLabel:Set("Current Role: Criminal")
        else
            CurrentJobLabel:Set("Current Role: Citizen")
        end
    end
end)

------------- Vehicle Info ------------------
local VehInfoSection = TabVehicle:CreateSection("Active Vehicle Statistics")
local ModelLabel = TabVehicle:CreateLabel("Current Model: None")
local SeatLabel = TabVehicle:CreateLabel("Status: On Foot")
local PartsLabel = TabVehicle:CreateLabel("Parts Detected: 0")
local SpeedLabel = TabVehicle:CreateLabel("Current Speed: 0 SPS")

local rainbowEnabled = false
local originalColors = {} -- Store colors: [Part] = Color3

-- 4. ESP / Rainbow RGB Toggle
local RainbowToggle = TabVehicle:CreateToggle({
    Name = "Vehicle RGB ESP",
    CurrentValue = false,
    Flag = "VehRGBToggle",
    Callback = function(Value)
        rainbowEnabled = Value
        -- Restore colors immediately on disable
        if not Value then
            for part, color in pairs(originalColors) do
                if part and part.Parent then
                    part.Color = color
                end
            end
            table.clear(originalColors)
        end
    end,
})

-- Controls
local physicsEnabled = false
local accelPower = 0
local brakeForce = 0

-- 1. Main Toggle
local MainToggle = TabVehicle:CreateToggle({
    Name = "Toggle Custom Modifier",
    CurrentValue = false,
    Flag = "VehPhysicsToggle",
    Callback = function(Value)
        physicsEnabled = Value
    end,
})

-- 2. Slider: Acceleration
local AccelSlider = TabVehicle:CreateSlider({
    Name = "Acceleration Power",
    Range = {0, 100},
    Increment = 1,
    Suffix = " Boost",
    CurrentValue = 0,
    Flag = "VehAccelPower",
    Callback = function(Value)
        accelPower = Value
    end,
})

-- 3. Slider: Brake Force
local BrakeSlider = TabVehicle:CreateSlider({
    Name = "Brake Force",
    Range = {0, 150},
    Increment = 1,
    Suffix = " Grip",
    CurrentValue = 0,
    Flag = "VehBrakeForce",
    Callback = function(Value)
        brakeForce = Value
    end,
})

task.spawn(function()
    local hue = 0
    while task.wait() do
        if rainbowEnabled then
            local myVeh = GetMyVehicle()
            if myVeh then
                local allObjects = myVeh:GetDescendants()
                hue = (hue + 1) % 360
                local rainbowColor = Color3.fromHSV(hue / 360, 0.9, 1)
                for _, obj in pairs(allObjects) do
                    -- Check if object is any part
                    if obj:IsA("BasePart") then
                        -- Save color only once
                        if not originalColors[obj] then
                            originalColors[obj] = obj.Color
                        end
                        -- Apply color
                        obj.Color = rainbowColor
                    end
                end
            end
        else
            -- Longer wait if disabled to reduce CPU load
            task.wait(0.3)
        end
    end
end)

-- MAIN LOOP
task.spawn(function()
    while task.wait(0.1) do
        local myVeh = GetMyVehicle()
        if myVeh then
            local seat = myVeh:FindFirstChild("VehicleSeat")
            -- UI: Name and Status
            local carType = myVeh:FindFirstChild("CarType")
            ModelLabel:Set("Current Model: " .. tostring(carType and carType.Value or myVeh.Name))
            local driverObj = myVeh:FindFirstChild("Driver")
            SeatLabel:Set((driverObj and driverObj.Value == LocalPlayer) and "Status: Driving" or "Status: Outside")
            -- UI: Part Count
            local allParts = myVeh:GetDescendants()
            local partCount = 0
            for _, p in pairs(allParts) do
                if p:IsA("BasePart") then partCount = partCount + 1 end
            end
            PartsLabel:Set("Parts Detected: " .. tostring(partCount))
            if seat then
                local velocity = seat.AssemblyLinearVelocity
                local speed = velocity.Magnitude
                SpeedLabel:Set("Current Speed: " .. math.floor(speed) .. " SPS")
                -- PHYSICS LOGIC (Only when Toggle active)
                if physicsEnabled then
                    -- Unlock MaxSpeed in seat
                    if seat.MaxSpeed < 9000 then seat.MaxSpeed = 9999 end
                    local throttle = seat.ThrottleFloat
                    if accelPower > 0 and math.abs(throttle) > 0 then
                        -- Check if car moving forward or backward
                        local isMovingForward = seat.CFrame.LookVector:Dot(velocity) > 0
                        if throttle > 0 then -- Pressing W (Gas)
                            if isMovingForward or speed < 3 then
                                -- Forward Boost
                                seat.AssemblyLinearVelocity = velocity + (seat.CFrame.LookVector * (accelPower / 5))
                            else
                                -- Heavy Braking
                                seat.AssemblyLinearVelocity = velocity * (1 - (brakeForce / 200))
                            end
                        elseif throttle < 0 then -- Pressing S (Reverse)
                            if not isMovingForward or speed < 3 then
                                -- Backward Boost
                                seat.AssemblyLinearVelocity = velocity + (-seat.CFrame.LookVector * (accelPower / 5))
                            else
                                -- Heavy Braking
                                seat.AssemblyLinearVelocity = velocity * (1 - (brakeForce / 200))
                            end
                        end
                    end
                end
            end
        else
            -- Reset if no vehicle
            ModelLabel:Set("Current Model: No Active Vehicle")
            SeatLabel:Set("Status: On Foot")
            PartsLabel:Set("Parts Detected: 0")
            SpeedLabel:Set("Current Speed: 0 SPS")
        end
    end
end)

--------------- Stats Tab ----------------------------
local NeutralSection = TabStats:CreateSection("Local Player Attributes")

-- List of attributes to track
local attributesToTrack = {
    "CurrentChassisType",
    "CustomizationEntryRefundsCompleted",
    "CustomizationEntryRefundsProcessing",
    "CustomizationImmediateRefundsComplete",
    "CustomizationImmediateRefundsInProgress",
    "DataManagerIsLoaded",
    "Device",
    "FrameworkLoaded",
    "GachaRolls",
    "GroupRole",
    "JobId",
    "MultiplierCashMultiplier",
    "PanelsInitialized"
}

-- Labels storage for updates
local StatLabels = {}

-- Create labels on start
for _, attrName in pairs(attributesToTrack) do
    StatLabels[attrName] = TabStats:CreateLabel(attrName .. ": Loading...")
end

-- Main data reading loop
task.spawn(function()
    local Player = game:GetService("Players").LocalPlayer
    while task.wait(0.5) do
        for _, attrName in pairs(attributesToTrack) do
            local val = Player:GetAttribute(attrName)
            if val ~= nil then
                local displayValue = tostring(val)
                -- Logic for True / False
                if type(val) == "boolean" then
                    displayValue = val and "True" or "False"
                end
                -- Logic for Numbers
                if type(val) == "number" then
                    displayValue = tostring(val)
                end
                -- Logic for Text
                if type(val) == "string" then
                    displayValue = val
                end
                StatLabels[attrName]:Set(attrName .. ": " .. displayValue)
            else
                StatLabels[attrName]:Set(attrName .. ": [N/A]")
            end
        end
    end
end)

local CriminalSection = TabStats:CreateSection("Live Criminal Stats")

-- Attributes that appear dynamically in character model
local crimAttributes = {
    "ComponentServerId",
    "CrimesCommitted",
    "CriminalExpireEpoch",
    "CurrencyEarned"
}

local CrimLabels = {}

-- Initial empty labels
for _, attrName in pairs(crimAttributes) do
    CrimLabels[attrName] = TabStats:CreateLabel(attrName .. ": ---")
end

-- WORKSPACE monitoring loop
task.spawn(function()
    local Player = game:GetService("Players").LocalPlayer
    while task.wait(0.5) do
        -- Find character in workspace by name
        local charInWorkspace = workspace:FindFirstChild(Player.Name)
        if charInWorkspace then
            -- Check for attributes (only appear during actions)
            local hasAnyCrimeAttr = false
            for _, attrName in pairs(crimAttributes) do
                local val = charInWorkspace:GetAttribute(attrName)
                if val ~= nil then
                    hasAnyCrimeAttr = true
                    local display = tostring(val)
                    -- Icon formatting
                    if attrName == "CurrencyEarned" then display = "$" .. display
                    elseif attrName == "CrimesCommitted" then display = display
                    elseif attrName == "ComponentServerId" then display = display
                    end
                    CrimLabels[attrName]:Set(attrName .. ": " .. display)
                else
                    -- Hide inactive attributes
                    CrimLabels[attrName]:Set(attrName .. ": [Inactive]")
                end
            end
        else
            -- Character not found
            for _, label in pairs(CrimLabels) do
                label:Set("Character not found in Workspace")
            end
        end
    end
end)

-- Server Statistics Section
local JobSection = TabStats:CreateSection("Server Online / Job Online Players")

-- Group labels
local PoliceLabel = TabStats:CreateLabel("Police (Security): 0")
local CrimeLabel = TabStats:CreateLabel("Criminals: 0")
local CitizenLabel = TabStats:CreateLabel("Citizens: 0")
local TotalLabel = TabStats:CreateLabel("Total Players: 0")

-- Server monitoring loop
task.spawn(function()
    local Players = game:GetService("Players")
    while task.wait(1) do -- Refresh every second
        local countPolice = 0
        local countCrime = 0
        local countCitizen = 0
        local allPlayers = Players:GetPlayers()
        for _, player in pairs(allPlayers) do
            local job = player:GetAttribute("JobId")
            if job == "Security" then
                countPolice = countPolice + 1
            elseif job == "Criminal" then
                countCrime = countCrime + 1
            elseif job == nil or job == "" or job == "Citizen" then
                countCitizen = countCitizen + 1
            end
        end
        -- Update labels with icons
        PoliceLabel:Set("Police: " .. tostring(countPolice))
        CrimeLabel:Set("Criminals: " .. tostring(countCrime))
        CitizenLabel:Set("Citizens: " .. tostring(countCitizen))
        TotalLabel:Set("Total Players: " .. tostring(#allPlayers))
    end
end)

------------- Farms -----------------
local ATMFlag = { Search = false }
local noclipConnection = nil
local spawnPos = Vector3.new(-315.4537353515625, 17.595108032226562, -1660.684326171875)
local platformPositions = {
    Vector3.new(-978.8837890625, -166, 313.3407897949219),
    Vector3.new(-484.3203430175781, -166, -1226.457275390625),
    Vector3.new(220.6251220703125, -166, 137.8120880126953),
    Vector3.new(-94.29008483886719, -166, 2340.5263671875),
    Vector3.new(-866.1265258789062, -166, 3189.411865234375),
    Vector3.new(-2068.16015625, -166, 4206.7861328125),
}
local sellPos1 = Vector3.new(-2520.495849609375, 15.116586685180664, 4035.560791015625)
local sellPos2 = Vector3.new(-2542.12646484375, 15.116586685180664, 4030.9150390625)

-- UI Labels
local ProgressLabel
local StatusLabel

-- =============================================================================
-- 3. HELPER FUNCTIONS (SYSTEM)
-- =============================================================================
local function setStatus(text)
    if StatusLabel then StatusLabel:Set("Status: " .. text) end
end

local function setWeight(isHeavy)
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CustomPhysicalProperties = isHeavy and PhysicalProperties.new(100, 0.3, 0.5) or nil
            end
        end
    end
end

local function SetNoclip(state)
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end

local function createAllPlatforms()
    for _, pos in ipairs(platformPositions) do
        local platform = Instance.new("Part")
        platform.Name = "DeltaCorePlatform"
        platform.Parent = workspace
        platform.Position = pos
        platform.Size = Vector3.new(50000, 3, 50000)
        platform.Color = Color3.fromRGB(170, 0, 255)
        platform.Anchored = true
    end
end

local function removeAllPlatforms()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "DeltaCorePlatform" then obj:Destroy() end
    end
end

local function tpTo(pos)
    if not ATMFlag.Search and pos ~= spawnPos then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
    end
end

local function SimpleGoTo(destination, timeout)
    local char = LocalPlayer.Character
    local human = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not human then return end
    local startT = tick()
    timeout = timeout or 2
    while (root.Position - destination).Magnitude > 3 do
        if not ATMFlag.Search or (tick() - startT) > timeout then break end
        human:MoveTo(destination)
        -- Jump if stuck
        if root.AssemblyLinearVelocity.Magnitude < 0.5 then
            human.Jump = true
        end
        task.wait(0.1)
    end
end

local function IsPoliceNearby(radius)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p:GetAttribute("JobId") == "Security" then
            local otherRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot and (root.Position - otherRoot.Position).Magnitude <= radius then
                return true
            end
        end
    end
    return false
end

-- =============================================================================
-- 4. FARMING LOGIC
-- =============================================================================
local function GetAvailableATM()
    local spawners = workspace.Game.Jobs.CriminalATMSpawners
    for _, spawner in ipairs(spawners:GetChildren()) do
        local atm = spawner:FindFirstChild("CriminalATM")
        if atm and atm:GetAttribute("State") == "Normal" then
            return spawner, atm
        end
    end
    return nil, nil
end

local Config = {
    task1 = 0.5,  -- teleport to sellpos1
    task2 = 2.0,  -- processing sellpos2
    task3 = 0.15, -- ATM loading (start)
    task4 = 5.0,  -- robbery cooldown
    task5 = 0.15, -- ATM loading (collection)
    task6 = 0.0,  -- robbery finalization
    task7 = 5.0,  -- platform load time
    task8 = 0.0,  -- temporary break
}

local function notifyUpdate(taskName, value)
    Rayfield:Notify({
        Title = "Configuration Updated",
        Content = "Set " .. taskName .. " to: " .. value .. "s",
        Duration = 2,
        Image = 4483362458,
    })
end

local function CheckBagLimit()
    if not ATMFlag.Search then return false end
    local currentCrimes = LocalPlayer.Character and
        LocalPlayer.Character:GetAttribute("CrimesCommitted") or 0
    local limit = Rayfield.Flags.BagSlider and Rayfield.Flags.BagSlider.CurrentValue or 25
    if currentCrimes >= limit then
        setStatus("Limit reached (" .. currentCrimes .. ") - Selling...")
        -- Sales loop until bags gone
        while currentCrimes >= limit and ATMFlag.Search do
            SetNoclip(true)
            tpTo(sellPos1)
            task.wait(Config.task1)
            setStatus("Going to sell point...")
            SimpleGoTo(sellPos2, 2)
            task.wait(Config.task2) -- Time for server processing
            currentCrimes = LocalPlayer.Character and
                LocalPlayer.Character:GetAttribute("CrimesCommitted") or 0
        end
        setStatus("Sold! Returning to work.")
        return true
    end
    return false
end

local function SmartBust(targetSpawner, atmModel)
    if not ATMFlag.Search then return end
    local safePos = platformPositions[math.random(1, #platformPositions)]
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    -- STEP 1: Start
    setStatus("Starting robbery...")
    if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
    tpTo(targetSpawner.Position)
    task.wait(Config.task3)
    bustStart:InvokeServer(atmModel)
    -- STEP 2: Escape to safe platform
    setStatus("Waiting in safe place...")
    tpTo(safePos)
    task.wait(Config.task4)
    -- STEP 3: Collection
    setStatus("Collecting loot...")
    if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
    tpTo(targetSpawner.Position)
    task.wait(Config.task5)
    bustEnd:InvokeServer(atmModel)
    task.wait(Config.task6)
    tpTo(safePos)
    -- KEY: Check limit immediately after robbery!
    CheckBagLimit()
end

-- =============================================================================
-- 5. MAIN LOOP (START_LOOP)
-- =============================================================================
local function StartLoop()
    task.spawn(function()
        while ATMFlag.Search do
            -- 1. Check limit before starting new platform round
            CheckBagLimit()
            -- 2. Platform scanning
            for _, platformPos in ipairs(platformPositions) do
                if not ATMFlag.Search then break end
                -- Check limit before each platform jump to prevent flying with full bags
                if CheckBagLimit() then
                    tpTo(platformPos)
                end
                SetNoclip(true)
                setWeight(true)
                setStatus("Scanning platform...")
                tpTo(platformPos)
                task.wait(Config.task7) -- Time for ATM to load in streaming
                local spawner, atm = GetAvailableATM()
                if spawner and atm then
                    SmartBust(spawner, atm)
                    setStatus("Technical break (Cooldown)...")
                    task.wait(Config.task8)
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============================================================================
-- 6. START / STOP (STEP MANAGEMENT)
-- =============================================================================
function StartATMFarm()
    if ATMFlag.Search then return end
    ATMFlag.Search = true
    -- STEP 1: Team
    setStatus("Step 1: Team Verification")
    pcall(function() RemoteStart:FireServer("Criminal", "jobPad") end)
    task.wait(0.5)
    -- STEP 2: Platforms
    setStatus("Step 2: Creating platforms")
    removeAllPlatforms()
    createAllPlatforms()
    task.wait(0.5)
    -- STEP 3: Physics and Noclip
    setStatus("Step 3: Loading Functions")
    SetNoclip(true)
    setWeight(true)
    task.wait(1)
    -- Start loop
    StartLoop()
end

function StopATMFarm()
    if not ATMFlag.Search then return end
    ATMFlag.Search = false
    setStatus("Stopping...")
    tpTo(spawnPos)
    task.wait(0.5)
    pcall(function() RemoteEnd:FireServer("jobPad") end)
    SetNoclip(false)
    setWeight(false)
    removeAllPlatforms()
    setStatus("Farm disabled")
end

-- =============================================================================
-- 7. USER INTERFACE (RAYFIELD)
-- =============================================================================
TabFarm:CreateToggle({
    Name = "Start ATM Farm",
    CurrentValue = false,
    Flag = "ATMFarmToggle",
    Callback = function(Value)
        if Value then StartATMFarm() else StopATMFarm() end
    end,
})

TabFarm:CreateSlider({
    Name = "Bag Limit",
    Range = {6, 200},
    Increment = 1,
    Suffix = "Bags",
    CurrentValue = 25,
    Flag = "BagSlider",
    Callback = function(Value) end,
})

StatusLabel = TabFarm:CreateLabel("Status: Waiting...")
ProgressLabel = TabFarm:CreateLabel("Bag Progress: 0 / 0")

TabFarm:CreateLabel("Farm SPEED CONFIGURATION (DELAYS)")

TabFarm:CreateInput({
    Name = "Task 1: Teleport SellPos1",
    PlaceholderText = "Currently: " .. Config.task1,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task1 = val notifyUpdate("Task 1", val) end
    end,
})

TabFarm:CreateInput({
    Name = "Task 2: Processing Sales",
    PlaceholderText = "Currently: " .. Config.task2,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task2 = val notifyUpdate("Task 2", val) end
    end,
})

TabFarm:CreateInput({
    Name = "Task 3: ATM Loading (Start)",
    PlaceholderText = "Currently: " .. Config.task3,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task3 = val notifyUpdate("Task 3", val) end
    end,
})

TabFarm:CreateInput({
    Name = "Task 4: Robbery Cooldown",
    PlaceholderText = "Currently: " .. Config.task4,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task4 = val notifyUpdate("Task 4", val) end
    end,
})

TabFarm:CreateInput({
    Name = "Task 5: ATM Loading (Collection)",
    PlaceholderText = "Currently: " .. Config.task5,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task5 = val notifyUpdate("Task 5", val) end
    end,
})

TabFarm:CreateInput({
    Name = "Task 6: Robbery Finalization",
    PlaceholderText = "Currently: " .. Config.task6,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task6 = val notifyUpdate("Task 6", val) end
    end,
})

TabFarm:CreateInput({
    Name = "Task 7: Platform Loading",
    PlaceholderText = "Currently: " .. Config.task7,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task7 = val notifyUpdate("Task 7", val) end
    end,
})

TabFarm:CreateInput({
    Name = "Task 8: Temporary Break",
    PlaceholderText = "Currently: " .. Config.task8,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then Config.task8 = val notifyUpdate("Task 8", val) end
    end,
})

TabFarm:CreateButton({
    Name = "RESET ALL DELAYS",
    Callback = function()
        Config.task1 = 0.5
        Config.task2 = 2.0
        Config.task3 = 0.15
        Config.task4 = 5.0
        Config.task5 = 0.15
        Config.task6 = 0.0
        Config.task7 = 5.0
        Config.task8 = 0.0
        Rayfield:Notify({
            Title = "Config Reset",
            Content = "Restored default values.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- UI Loop (Progress)
task.spawn(function()
    while true do
        pcall(function()
            if ProgressLabel and LocalPlayer.Character then
                local cur = LocalPlayer.Character:GetAttribute("CrimesCommitted") or 0
                local lim = (Rayfield.Flags.BagSlider and Rayfield.Flags.BagSlider.CurrentValue) or 0
                ProgressLabel:Set("Bag Progress: " .. cur .. " / " .. lim)
                if cur >= lim and lim > 0 then
                    ProgressLabel:Set("Bag Progress: " .. cur .. " / " .. lim .. " (FULL!)")
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- =============================================================================
-- NEW: SECURITY SECTION (placed directly below ATM Farm as requested)
-- =============================================================================
local SecuritySection = TabFarm:CreateSection("Security")

local AutoArrestEnabled = false
local ArrestMode = "CFrame"
local autoArrestConnection = nil

local function GetOutlawPlayers()
    local outlaws = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr \~= LocalPlayer and plr:GetAttribute("JobId") == "Outlaw" then
            table.insert(outlaws, plr)
        end
    end
    return outlaws
end

local function TeleportToPlayer(target)
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end

    local destCFrame = root.CFrame * CFrame.new(0, 5, 2)

    if ArrestMode == "CFrame" then
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = destCFrame end
    else
        myChar:PivotTo(destCFrame)
    end
end

local function StartAutoArrest()
    if autoArrestConnection then autoArrestConnection:Disconnect() end
    autoArrestConnection = RunService.Heartbeat:Connect(function()
        if not AutoArrestEnabled then return end
        local targets = GetOutlawPlayers()
        if #targets == 0 then return end

        for _, target in ipairs(targets) do
            if not AutoArrestEnabled then break end
            local startTime = tick()
            while (tick() - startTime) < 7 and AutoArrestEnabled do
                TeleportToPlayer(target)
                task.wait(0.05)
            end
        end
    end)
end

local function StopAutoArrest()
    AutoArrestEnabled = false
    if autoArrestConnection then
        autoArrestConnection:Disconnect()
        autoArrestConnection = nil
    end
end

TabFarm:CreateToggle({
    Name = "Auto Arrest",
    CurrentValue = false,
    Flag = "AutoArrestToggle",
    Callback = function(Value)
        AutoArrestEnabled = Value
        if Value then
            StartAutoArrest()
            Rayfield:Notify({Title = "Auto Arrest", Content = "Enabled - Cycling Outlaws (7s each)", Duration = 3})
        else
            StopAutoArrest()
            Rayfield:Notify({Title = "Auto Arrest", Content = "Disabled", Duration = 2})
        end
    end,
})

TabFarm:CreateDropdown({
    Name = "Mode",
    Options = {"CFrame", "HumanoidRootPart"},
    CurrentOption = {"CFrame"},
    MultipleOptions = false,
    Flag = "ArrestModeDropdown",
    Callback = function(Options)
        ArrestMode = Options[1]
    end,
})

Rayfield:LoadConfiguration()
