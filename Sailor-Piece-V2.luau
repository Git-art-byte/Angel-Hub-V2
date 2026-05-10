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

-- Remove numbers at end
-- Example:
-- Délinquant1 -> Délinquant
-- SpiritFighter3 -> SpiritFighter
local function cleanName(name)
    return string.gsub(name, "%d+$", "")
end

----------------------------------------------------------------
-- GET NEARBY MOBS ONLY
----------------------------------------------------------------

local function getNearbyMobList()
    local hrp = getHRP()

    local mobs = {}
    local added = {}

    for _, mob in ipairs(NPCFolder:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")

        if humanoid and humanoid.Health > 0 and mobHRP then
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
-- GET NEAREST MOB OF SELECTED TYPE
----------------------------------------------------------------

local function getNearestMob(name)
    local hrp = getHRP()

    local nearest = nil
    local shortest = math.huge

    for _, mob in ipairs(NPCFolder:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")

        if humanoid and humanoid.Health > 0 and mobHRP then
            if cleanName(mob.Name) == name then
                local distance = (hrp.Position - mobHRP.Position).Magnitude

                if distance < shortest then
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
    Values = getNearbyMobList(),
    Multi = false,
    Default = nil,
    Callback = function(value)
        SelectedMob = value
    end
})

----------------------------------------------------------------
-- REFRESH EVERY 5 SECONDS
----------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(5)

        local values = getNearbyMobList()

        MobDropdown:SetValues(values)

        -- reset selected if mob disappeared
        if SelectedMob and not table.find(values, SelectedMob) then
            SelectedMob = nil
        end
    end
end)

----------------------------------------------------------------
-- AUTOFARM
----------------------------------------------------------------

-- Replace your AUTOFARM toggle with this fixed version

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm",
    Default = false,

    Callback = function(state)
        Running = state

        if state then
            task.spawn(function()

                while Running do
                    task.wait(0.1)

                    if not SelectedMob then
                        continue
                    end

                    equipSword()

                    -- ALWAYS search for a new mob
                    local target = getNearestMob(SelectedMob)

                    if not target then
                        continue
                    end

                    local humanoid = target:FindFirstChildOfClass("Humanoid")
                    local targetHRP = target:FindFirstChild("HumanoidRootPart")

                    if not humanoid or not targetHRP then
                        continue
                    end

                    -- attack current mob
                    repeat
                        if not Running then
                            break
                        end

                        -- mob disappeared
                        if not target.Parent then
                            break
                        end

                        humanoid = target:FindFirstChildOfClass("Humanoid")
                        targetHRP = target:FindFirstChild("HumanoidRootPart")

                        if not humanoid or not targetHRP then
                            break
                        end

                        local hrp = getHRP()

                        -- teleport behind mob
                        hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)

                        -- spam remote
                        HitRemote:FireServer()

                        task.wait(0.05)

                    until humanoid.Health <= 0
                end
            end)
        end
    end
})
