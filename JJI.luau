local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB v2 | Jujutsu Incremental " .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 380),  -- slightly taller for more toggles
    Acrylic = true, 
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

Fluent:Notify({
    Title = "Loaded!",
    Content = "Angel Hub has succesfully been loaded!",
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
--          AUTO FARM SECTION
-- ───────────────────────────────────────────────

local Section = Tabs.Main:AddSection("Farming")

-- Auto Farm Sukuna (existing)
Tabs.Main:AddToggle("AutoFarmSukuna", {
    Title = "Auto Farm Sukuna (Special Grade Boss)",
    Default = false,
    Callback = function(enabled)
        if enabled then
            Fluent:Notify({
                Title = "Auto Farm",
                Content = "Started – spamming Sukuna boss every 0.1s",
                Duration = 4
            })

            task.spawn(function()
                while task.wait(0.1) do
                    if not Fluent.Options.AutoFarmSukuna.Value then break end
                    pcall(function()
                        local args = {"Special Grade Boss", "Sukuna"}
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("JJKRemotes")
                            :WaitForChild("ResolveCombat")
                            :InvokeServer(unpack(args))
                    end)
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Farm",
                Content = "Stopped",
                Duration = 3
            })
        end
    end
})

-- ───────────────────────────────────────────────
--          NEW: AUTO GRADE & AUTO PRESTIGE
-- ───────────────────────────────────────────────

-- Auto Grade (tries to level up grade repeatedly)
Tabs.Main:AddToggle("AutoGrade", {
    Title = "Auto Grade (Upgrade Grade)",
    Default = false,
    Callback = function(enabled)
        if enabled then
            Fluent:Notify({
                Title = "Auto Grade",
                Content = "Started – attempting Grade Up every 1s",
                Duration = 4
            })

            task.spawn(function()
                while task.wait(1) do
                    if not Fluent.Options.AutoGrade.Value then break end
                    pcall(function()
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("JJKRemotes")
                            :WaitForChild("GradeUp")
                            :FireServer()
                    end)
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Grade",
                Content = "Stopped",
                Duration = 3
            })
        end
    end
})

-- Auto Prestige (prestiges when possible)
Tabs.Main:AddToggle("AutoPrestige", {
    Title = "Auto Prestige",
    Default = false,
    Callback = function(enabled)
        if enabled then
            Fluent:Notify({
                Title = "Auto Prestige",
                Content = "Started – attempting Prestige every 3s",
                Duration = 4
            })

            task.spawn(function()
                while task.wait(3) do   -- longer delay – prestige usually has cooldown / requirements
                    if not Fluent.Options.AutoPrestige.Value then break end
                    pcall(function()
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("JJKRemotes")
                            :WaitForChild("Prestige")
                            :FireServer()
                    end)
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Prestige",
                Content = "Stopped",
                Duration = 3
            })
        end
    end
})

-- You can add more features later...

SaveManager:LoadAutoloadConfig()
