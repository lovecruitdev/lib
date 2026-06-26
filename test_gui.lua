-- [[ TEST SCRIPT FOR ANTIGRAVITY PREMIUM TOP-TIER GUI ]] --
-- Run this inside your Roblox Executor to preview the upgraded GUI.
-- Ensure Library.lua is located in your executor's workspace folder or readfile path.

local Library
local success, err = pcall(function()
    -- Force load online from GitHub with cache bypass to prevent executor caching issues
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/lovecruitdev/lib/main/Library.lua?t=" .. os.time()))()
end)

if not success or not Library then
    warn("Failed to load online Library, trying local file: " .. tostring(err))
    local localSuccess, lib = pcall(function()
        if isfile("Library.lua") then
            return loadstring(readfile("Library.lua"))()
        else
            return loadstring(readfile("c:/Users/lovecruit/Downloads/scr/Library.lua"))()
        end
    end)
    if localSuccess then
        Library = lib
    else
        error("Could not load Library.lua. Error: " .. tostring(err))
    end
end

-- Create the main window
local Window = Library:CreateWindow({
    Title = "Antigravity Premium v2.5 | Top-Tier Interface",
    Center = true
})

-- Enable the performance stats watermark
Library:SetWatermarkVisibility(true)

-- Create tabs
local Tabs = {
    Main = Window:AddTab("Main Controls", "home"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Settings = Window:AddTab("Settings", "settings")
}

-- 1. Main Tab Controls
local MainBox = Tabs.Main:AddLeftGroupbox("Feature Toggles")

MainBox:AddToggle("GodMode", {
    Text = "Enable Godmode",
    Default = false,
    Callback = function(val)
        Library:Notify("Godmode state: " .. tostring(val))
    end
})

MainBox:AddToggle("DesyncToggle", {
    Text = "Enable Desync",
    Default = true,
    Callback = function(val)
        Library:Notify("Desync state: " .. tostring(val))
    end
}):AddKeyPicker("DesyncBind", {
    Default = "V",
    SyncToggleState = true
}):AddColorPicker("DesyncColor", {
    Default = Color3.fromRGB(0, 255, 255),
    Callback = function(color)
        Library:Notify("Desync color: RGB(" .. math.round(color.R*255) .. ", " .. math.round(color.G*255) .. ", " .. math.round(color.B*255) .. ")")
    end
})

local MainRight = Tabs.Main:AddRightGroupbox("Adjustments")

MainRight:AddSlider("WalkSpeed", {
    Text = "Walkspeed Adjust",
    Min = 16,
    Max = 150,
    Default = 16,
    Rounding = 0,
    Callback = function(val)
        print("WalkSpeed adjusted: " .. val)
    end
})

-- Searchable Dropdown
MainRight:AddDropdown("AimPart", {
    Text = "Aim target part (Searchable)",
    Values = {"Head", "Torso", "HumanoidRootPart", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Neck", "UpperTorso", "LowerTorso"},
    Default = 1,
    Multi = false,
    Callback = function(val)
        Library:Notify("Aim target set to: " .. val)
    end
})

MainRight:AddDropdown("TargetPlayers", {
    Text = "Target Player Teams (Multi)",
    Values = {"Enemies", "Friends", "Neutral", "Admins", "VIPs", "Guests"},
    Default = {"Enemies"},
    Multi = true,
    Callback = function(tbl)
        local selected = {}
        for k, v in pairs(tbl) do
            if v then table.insert(selected, k) end
        end
        Library:Notify("Target teams: " .. table.concat(selected, ", "))
    end
})

-- 2. Visuals Tab Controls
local VisualsLeft = Tabs.Visuals:AddLeftGroupbox("ESP Config")

VisualsLeft:AddToggle("PlayerESP", {
    Text = "Show Players",
    Default = false,
    Callback = function(val)
        Library:Notify("Player ESP: " .. tostring(val))
    end
})

VisualsLeft:AddToggle("BoxESP", {
    Text = "3D Box ESP",
    Default = false,
    Callback = function(val) end
}):AddColorPicker("BoxESPColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color) end
})

VisualsLeft:AddDivider()

VisualsLeft:AddInput("SearchPlayer", {
    Text = "Filter by username",
    Default = "",
    Placeholder = "Enter username...",
    Callback = function(val)
        Library:Notify("Filtering players by: " .. val)
    end
})

-- 3. Settings Tab Controls
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu Utilities")

MenuGroup:AddButton("Unload Entire Script", function()
    Library:Notify("Unloading UI in 1.5 seconds...")
    task.wait(1.5)
    Library:Unload()
end)

MenuGroup:AddLabel("Toggle Menu UI key"):AddKeyPicker("MenuToggleKey", {
    Default = "End",
    Callback = function()
        Library:Notify("Menu visibility toggled via keybind!")
    end
})

-- Watermark Toggle
local WatermarkState = true
MenuGroup:AddToggle("WatermarkToggle", {
    Text = "Show Performance Watermark",
    Default = true,
    Callback = function(val)
        Library:SetWatermarkVisibility(val)
    end
})

Library.ThemeManager:ApplyToTab(Tabs.Settings)
Library.SaveManager:BuildConfigSection(Tabs.Settings)

-- Initialize notifications
Library:Notify("Antigravity Premium loaded successfully!", 4)
Library:Notify("Press [End] to toggle the main menu visibility.", 6)
Library:Notify("Minimize the menu using the [-] button on the top-right.", 8)
