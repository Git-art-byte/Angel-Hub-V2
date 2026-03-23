local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
local Window = MacLib:Window({
    Title = "Angel Hub | Sailor Piece",
    Subtitle = "Free | V3.12",
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = true,
})
local Global_Setting = Window:GlobalSetting({
    Name = "Moderator Join Alerts",
    Default = false,
    Callback = function(State)
        print("Moderator Join Alerts " .. (State and "Enabled" or "Disabled"))
    end,
})
Window:Notify({
    Title = "Angel Hub Succesfully loaded!",
    Description = "",
    Lifetime = 5
})
local Tab = TabGroup:Tab({
  Name = "Main"
  Image = nil
})
local Section = Tab:Section({
  Side = "Left"
})
sections.MainSection1:Dropdown({
	Name = "Give Weapons",
	Search = true,
	Multi = true,
	Required = false,
	Options = {"AK-47", "M4A1", "Desert Eagle", "AWP", "MP5", "SPAS-12"},
	Default = {"M4A1", "AWP"},
	Callback = function(Value)
		local Values = {}
		for _, State in next, Value do
			if State then
				table.insert(Values, _)
			end
		end
		print("Selected Weapons:", table.concat(Values, ", "))
	end,
}, "GiveWeaponsDropdown")

sections.MainSection1:Toggle({
	Name = "Flight",
	Default = false,
	Callback = function(value)
		Window:Notify({
			Title = "Kuzu Hub",
			Description = (value and "Enabled " or "Disabled ") .. "Flight"
		})
	end,
}, "FlightToggle")
