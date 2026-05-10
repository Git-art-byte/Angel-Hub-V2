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

local HitRemote = ReplicatedStorage
    :WaitForChild("CombatSystem")
    :WaitForChild("Remotes")
    :WaitForChild("RequestHit")

----------------------------------------------------------------
-- VARIABLES
----------------------------------------------------------------

local SelectedMob = nil
local Running = false
local MaxDistance = 250

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

    if char:FindFirstChild("Ice Queen") then
        return
    end

    local tool = LocalPlayer.Backpack:FindFirstChild("Ice Queen")

    if tool then
        tool.Parent = char
    end
end

-- remove numbers at end
-- Délinquant1 -> Délinquant
-- SpiritFighter3 -> SpiritFighter
local function cleanName(name)
    return string.gsub(name, "%d+$", "")
end

----------------------------------------------------------------
-- GET NEARBY MOB LIST
----------------------------------------------------------------

local function getNearbyMobList()
    local hrp = getHRP()

    local mobs = {}
    local added = {}

    for _, mob in pairs(NPCFolder:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")

        if humanoid
        and humanoid.Health > 0
        and mobHRP then

            local distance = (hrp.Position - mobHRP.Position).Magnitude

            if distance <= MaxDistance then
                local baseName = cleanName(mob.Name)

                if not added[baseName] then
                    added[baseName] = true

                    table.insert(mobs, {
                        Name = baseName,
                        Distance = distance
                    })
                end
            end
        end
    end

    table.sort(mobs, function(a, b)
        return a.Distance < b.Distance
    end)

    local values = {}

    for _, mob in ipairs(mobs) do
        table.insert(values, mob.Name)
    end

    return values
end

----------------------------------------------------------------
-- GET NEAREST MOB
----------------------------------------------------------------

local function getNearestMob(name)
    local hrp = getHRP()

    local nearest = nil
    local shortest = math.huge

    for _, mob in pairs(NPCFolder:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")

        if humanoid
        and mobHRP
        and humanoid.Health > 0
        and cleanName(mob.Name) == name then

            local distance = (hrp.Position - mobHRP.Position).Magnitude

            if distance < shortest then
                shortest = distance
                nearest = mob
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
    Values = getNearbyMobList(),
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedMob = value
    end
})

----------------------------------------------------------------
-- REFRESH DROPDOWN EVERY 5 SECONDS
----------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(5)

        local values = getNearbyMobList()

        MobDropdown:SetValues(values)

        -- reset if mob disappeared
        if SelectedMob and not table.find(values, SelectedMob) then
            SelectedMob = nil
        end
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

        if state then
            task.spawn(function()

                while Running do
                    task.wait(0.05)

                    pcall(function()

                        if not SelectedMob then
                            return
                        end

                        equipSword()

                        local target = getNearestMob(SelectedMob)

                        -- no mob found yet
                        if not target then
                            return
                        end

                        local humanoid = target:FindFirstChildOfClass("Humanoid")
                        local targetHRP = target:FindFirstChild("HumanoidRootPart")

                        if not humanoid or not targetHRP then
                            return
                        end

                        local hrp = getHRP()

                        -- teleport behind mob
                        hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)

                        -- attack spam
                        HitRemote:FireServer()

                    end)
                end
            end)
        end
    end
})
