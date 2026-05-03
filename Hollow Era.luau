local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB v2 | Hollow Era " .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 380),
    Acrylic = true, 
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Fluent:Notify({
    Title = "Loaded!",
    Content = "Angel Hub has succesfully been loaded! (Medium speed loops)",
    Duration = 5
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- ───────────────────────────────────────────────
--          AUTO FARM SECTION (MEDIUM SPEED)
-- ───────────────────────────────────────────────

local Section = Tabs.Main:AddSection("Farming")
-- ───────────────────────────────────────────────
--              UNIQUE MOB DROPDOWN
-- ───────────────────────────────────────────────

local MobDropdown

local function getUniqueMobs()
    local unique = {}
    local folder = workspace:FindFirstChild("Humanoids")
    
    if not folder then 
        return {"No Humanoids folder found"} 
    end
    
    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            unique[obj.Name] = true
        end
    end
    
    local list = {}
    for name in pairs(unique) do
        table.insert(list, name)
    end
    table.sort(list)
    
    return #list > 0 and list or {"No mobs found"}
end

-- Create Dropdown
MobDropdown = Section:AddDropdown({
    Title = "Select Mob",
    Values = getUniqueMobs(),
    Multi = false,
    Default = 1,
    Callback = function(Value)
        print("Selected Mob:", Value)
        -- Put your farming logic here later
    end
})

-- Auto refresh every 5 seconds
task.spawn(function()
    while task.wait(5) do
        if MobDropdown then
            local newValues = getUniqueMobs()
            MobDropdown:SetValues(newValues)
            
            -- Optional: Keep current selection if it still exists
            local current = MobDropdown.Value
            if current and table.find(newValues, current) then
                MobDropdown:SetValue(current)
            end
        end
    end
end)


-- ───────────────────────────────────────────────
--                 AUTO FARM TOGGLE
-- ───────────────────────────────────────────────

local AutoFarmEnabled = false
local CurrentTarget = nil

local AutoFarmToggle = Section:AddToggle({
    Title = "Autofarm",
    Default = false,
    Callback = function(Value)
        AutoFarmEnabled = Value
        
        if Value then
            Fluent:Notify({
                Title = "Autofarm",
                Content = "Auto farm started - Targeting: " .. (MobDropdown.Value or "None"),
                Duration = 4
            })
            StartAutoFarm()
        else
            Fluent:Notify({
                Title = "Autofarm",
                Content = "Auto farm stopped",
                Duration = 3
            })
            CurrentTarget = nil
        end
    end
})

-- Main Auto Farm Function
function StartAutoFarm()
    task.spawn(function()
        while AutoFarmEnabled do
            local mobName = MobDropdown.Value
            
            if not mobName or mobName == "No mobs found" then
                task.wait(1)
                continue
            end

            -- Find alive mobs with that name
            local possibleMobs = {}
            local folder = workspace:FindFirstChild("Humanoids")
            
            if folder then
                for _, mob in ipairs(folder:GetChildren()) do
                    if mob.Name == mobName and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                        table.insert(possibleMobs, mob)
                    end
                end
            end

            if #possibleMobs == 0 then
                task.wait(0.5)
                continue
            end

            -- Take the first alive mob
            CurrentTarget = possibleMobs[1]

            -- TP to top of the mob
            local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and CurrentTarget then
                local targetPos = CurrentTarget:GetPivot().Position
                
                -- Since no Head/parts, we use a simple height offset
                root.CFrame = CFrame.new(targetPos.X, targetPos.Y + 8, targetPos.Z) * CFrame.Angles(0, math.rad(180), 0)
            end

            -- Spam Punch Remote
            local args = {
                [1] = 1,
                [2] = {},
            }
            
            for i = 1, 8 do  -- spam 8 times per cycle
                if CurrentTarget and CurrentTarget:FindFirstChild("Humanoid") and CurrentTarget.Humanoid.Health > 0 then
                    game:GetService("ReplicatedStorage").RsPackage.Swing:FireServer(unpack(args))
                else
                    break
                end
                task.wait(0.08) -- Medium speed as requested
            end

            task.wait(0.1)
        end
    end)
end
