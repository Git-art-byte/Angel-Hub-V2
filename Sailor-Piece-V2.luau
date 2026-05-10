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

local LocalPlayer = Players.LocalPlayer
local NPCFolder = workspace:WaitForChild("NPCs")

local HitRemote = ReplicatedStorage:WaitForChild("CombatSystem")
    :WaitForChild("Remotes"):WaitForChild("RequestHit")

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------
local SelectedMob = nil
local Running = false
local MaxDistance = 300  -- increased a bit

----------------------------------------------------------------
-- FUNCTIONS
----------------------------------------------------------------
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

local function equipSword()
    local char = getCharacter()
    if char:FindFirstChild("Ice Queen") then return end
    
    local tool = LocalPlayer.Backpack:FindFirstChild("Ice Queen")
    if tool then
        tool.Parent = char
    end
end

local function cleanName(name)
    return string.gsub(name, "%d+$", "")
end

----------------------------------------------------------------
-- GET NEAREST MOB (improved)
----------------------------------------------------------------
local function getNearestMob(name)
    if not name then return nil end
    local hrp = getHRP()
    local nearest = nil
    local shortest = math.huge

    for _, mob in pairs(NPCFolder:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")

        if humanoid and mobHRP and humanoid.Health > 0 then
            if cleanName(mob.Name) == name then
                local distance = (hrp.Position - mobHRP.Position).Magnitude
                if distance <= MaxDistance and distance < shortest then
                    shortest = distance
                    nearest = mob
                end
            end
        end
    end
    return nearest
end

----------------------------------------------------------------
-- DROPDOWN
----------------------------------------------------------------
local MobDropdown = Tabs.Main:AddDropdown("MobDropdown", {
    Title = "Nearby Mobs",
    Values = {}, -- will be refreshed immediately
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedMob = value
    end
})

-- Initial + periodic refresh
task.spawn(function()
    while true do
        local values = {}
        local added = {}
        local hrp = getHRP()

        for _, mob in pairs(NPCFolder:GetChildren()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local mhrp = mob:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and mhrp then
                local dist = (hrp.Position - mhrp.Position).Magnitude
                if dist <= MaxDistance then
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
-- AUTOFARM (Fixed)
----------------------------------------------------------------
Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm",
    Default = false,
    Callback = function(state)
        Running = state
        
        if not state then return end

        task.spawn(function()
            while Running do
                pcall(function()
                    if not SelectedMob then 
                        task.wait(0.5)
                        return 
                    end

                    equipSword()

                    local target = getNearestMob(SelectedMob)
                    if not target then
                        task.wait(0.3) -- important: give time for respawn
                        return
                    end

                    local targetHRP = target:FindFirstChild("HumanoidRootPart")
                    if not targetHRP then return end

                    local hrp = getHRP()

                    -- Teleport behind + slight offset to avoid collision issues
                    hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3.5)

                    -- Attack
                    HitRemote:FireServer()
                end)

                task.wait(0.06) -- slightly slower than before, more stable
            end
        end)
    end
})
