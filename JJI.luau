local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB v2 | Jujutsu Incremental " .. Fluent.Version,
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

local Section = Tabs.Main:AddSection("Farming (Medium Speed)")

-- Auto Farm Gojo – now every 0.08 seconds (balanced)
Tabs.Main:AddToggle("AutoFarmGojo", {
    Title = "Auto Farm Gojo (Raid Boss)",
    Default = false,
    Callback = function(enabled)
        if enabled then
            Fluent:Notify({
                Title = "Auto Farm Gojo",
                Content = "Started – spamming every 0.08s",
                Duration = 4
            })

            task.spawn(function()
                while task.wait(0.08) do
                    if not Fluent.Options.AutoFarmGojo.Value then break end
                    pcall(function()
                        local args = {"Raid Boss", "Satoru Gojo"}
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("JJKRemotes")
                            :WaitForChild("ResolveCombat")
                            :InvokeServer(unpack(args))
                    end)
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Farm Gojo",
                Content = "Stopped",
                Duration = 3
            })
        end
    end
})

-- Auto Grade – now every 0.3 seconds
Tabs.Main:AddToggle("AutoGrade", {
    Title = "Auto Grade (Upgrade Grade)",
    Default = false,
    Callback = function(enabled)
        if enabled then
            Fluent:Notify({
                Title = "Auto Grade",
                Content = "Started – attempting every 0.3s",
                Duration = 4
            })

            task.spawn(function()
                while task.wait(0.3) do
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

-- Auto Prestige – now every 1 second
Tabs.Main:AddToggle("AutoPrestige", {
    Title = "Auto Prestige",
    Default = false,
    Callback = function(enabled)
        if enabled then
            Fluent:Notify({
                Title = "Auto Prestige",
                Content = "Started – attempting every 1s",
                Duration = 4
            })

            task.spawn(function()
                while task.wait(1) do
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

SaveManager:LoadAutoloadConfig()
