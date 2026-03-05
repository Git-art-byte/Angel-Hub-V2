local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "ANGEL HUB v2 | Jujutsu Incremental " .. Fluent.Version,
    SubTitle = "by Ange",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 320),
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

local farmingLoop = nil

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

            -- Start the loop in a separate thread
            task.spawn(function()
                while task.wait(0.1) do
                    -- Only continue while toggle is still on
                    if not Fluent.Options.AutoFarmSukuna.Value then
                        break
                    end

                    pcall(function()
                        local args = {
                            "Special Grade Boss",
                            "Sukuna"
                        }
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
            -- No need to manually stop — the while loop checks the toggle value
        end
    end
})

-- You can add more toggles/buttons here later...

SaveManager:LoadAutoloadConfig()
