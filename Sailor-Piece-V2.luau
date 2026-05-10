local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB | Autofarm " .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 320),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "AutoFarm", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local NPCFolder = workspace:WaitForChild("NPCs")

local HitRemote = ReplicatedStorage:WaitForChild("CombatSystem")
    :WaitForChild("Remotes"):WaitForChild("RequestHit")

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------
local SelectedMob = nil
local Running = false
local OffsetDistance = 4
local FarmPosition = "Behind"
local NoclipEnabled = false

----------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    return getCharacter():WaitForChild("HumanoidRootPart")
end

local function equipSword()
    local char = getCharacter()
    if char:FindFirstChild("Ice Queen") then return end
    local tool = LocalPlayer.Backpack:FindFirstChild("Ice Queen")
    if tool then tool.Parent = char end
end

local function cleanName(name)
    return string.gsub(name, "%d+$", "")
end

-- Noclip
local function toggleNoclip(state)
    if NoclipEnabled == state then return end
    NoclipEnabled = state
    
    if state then
        task.spawn(function()
            while NoclipEnabled and Running do
                for _, part in pairs(getCharacter():GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

----------------------------------------------------------------
-- TWEEN + FACE MOB
----------------------------------------------------------------
local function tweenToTarget(targetHRP)
    if not targetHRP then return end
    
    local hrp = getHRP()
    local offset = Vector3.new(0, 0, 0)
    
    if FarmPosition == "Behind" then
        offset = targetHRP.CFrame.LookVector * -OffsetDistance
    elseif FarmPosition == "Front" then
        offset = targetHRP.CFrame.LookVector * OffsetDistance
    elseif FarmPosition == "Upper" then
        offset = Vector3.new(0, OffsetDistance, 0)
    elseif FarmPosition == "Below" then
        offset = Vector3.new(0, -OffsetDistance, 0)
    end
    
    local targetCFrame = CFrame.new(targetHRP.Position + offset, targetHRP.Position)
    
    local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween:Wait()
end

----------------------------------------------------------------
-- GET NEAREST MOB
----------------------------------------------------------------
local function getNearestMob(name)
    if not name then return nil end
    local hrp = getHRP()
    local nearest, shortest = nil, math.huge

    for _, mob in pairs(NPCFolder:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")

        if humanoid and mobHRP and humanoid.Health > 0 and cleanName(mob.Name) == name then
            local dist = (hrp.Position - mobHRP.Position).Magnitude
            if dist <= 350 and dist < shortest then
                shortest = dist
                nearest = mob
            end
        end
    end
    return nearest
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local MobDropdown = Tabs.Main:AddDropdown("MobDropdown", {
    Title = "Nearby Mobs",
    Values = {},
    Multi = false,
    Default = nil,
    Callback = function(value) SelectedMob = value end
})

Tabs.Main:AddDropdown("PositionDropdown", {
    Title = "Autofarm Position",
    Values = {"Behind", "Front", "Upper", "Below"},
    Multi = false,
    Default = "Behind",
    Callback = function(value)
        FarmPosition = value
    end
})

Tabs.Main:AddSlider("DistanceSlider", {
    Title = "Distance",
    Description = "Offset from mob",
    Default = 4,
    Min = 1,
    Max = 15,
    Rounding = 1,
    Callback = function(value)
        OffsetDistance = value
    end
})

-- Refresh
task.spawn(function()
    while true do
        local values, added = {}, {}
        local hrp = getHRP()

        for _, mob in pairs(NPCFolder:GetChildren()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and mhrp then
                if (hrp.Position - mhrp.Position).Magnitude <= 350 then
                    local base = cleanName(mob.Name)
                    if not added[base] then
                        added[base] = true
                        table.insert(values, base)
                    end
                end
            end
        end

        table.sort(values)
        MobDropdown:SetValues(values)
        task.wait(4)
    end
end)

----------------------------------------------------------------
-- AUTOFARM
----------------------------------------------------------------
Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm",
    Default = false,
    Callback = function(state)
        Running = state
        
        if not state then 
            toggleNoclip(false)
            return 
        end

        task.spawn(function()
            while Running do
                pcall(function()
                    if not SelectedMob then 
                        task.wait(0.4)
                        return 
                    end

                    equipSword()

                    local target = getNearestMob(SelectedMob)
                    if not target then
                        task.wait(0.4)
                        return
                    end

                    local targetHRP = target:FindFirstChild("HumanoidRootPart")
                    if not targetHRP then return end

                    -- Noclip for Below position
                    toggleNoclip(FarmPosition == "Below")

                    tweenToTarget(targetHRP)

                    -- Face the mob properly
                    local hrp = getHRP()
                    hrp.CFrame = CFrame.lookAt(hrp.Position, targetHRP.Position)

                    -- Attack (Fixed - fire multiple times)
                    for i = 1, 3 do
                        HitRemote:FireServer()
                        task.wait(0.05)
                    end
                end)

                task.wait(0.07)
            end
        end)
    end
})
