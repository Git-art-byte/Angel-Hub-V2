local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local Window = Library:CreateWindow({
    Title = "Angel Hub V2",
    Footer = "version: 1.2",
    Icon = 95816097006870,
    NotifySide = "Right",
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local LeftGroupBox = Tab:AddLeftGroupbox("Left Groupbox", "wrench")
local RightGroupBox = Tab:AddRightGroupbox("Right Groupbox")

local Dropdown = Groupbox:AddDropdown("MyDropdown", {
    Text = "A dropdown",
    Values = { "This", "is", "a", "dropdown" },
    Default = 1,
    Multi = false,
})

local MyToggle = Groupbox:AddToggle("MyToggle", {
    Text = "Enable Speed Hack",
    Default = true,
})
