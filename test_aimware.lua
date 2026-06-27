-- [[ TEST SCRIPT FOR AIMWARE V5 1:1 UI REPLICA ]] --
-- Run this inside your Roblox Executor to preview the 1:1 replica of the Aimware v5 UI.

local Library
local success, err = pcall(function()
    -- Force load online from GitHub with cache bypass
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/lovecruitdev/lib/main/LibraryAimware.lua?t=" .. os.time()))()
end)

if not success or not Library then
    warn("Failed to load online Library, trying local file: " .. tostring(err))
    local localSuccess, lib = pcall(function()
        if isfile("LibraryAimware.lua") then
            return loadstring(readfile("LibraryAimware.lua"))()
        else
            return loadstring(readfile("c:/Users/lovecruit/Downloads/scr/LibraryAimware.lua"))()
        end
    end)
    if localSuccess then
        Library = lib
    else
        error("Could not load LibraryAimware.lua. Error: " .. tostring(err))
    end
end

-- Create the main window
local Window = Library:CreateWindow({
    Title = "V5 DEV for Counter-Strike: Global Offensive",
    Center = true
})

-- Enable the performance stats watermark
Library:SetWatermarkVisibility(true)

-- Create top tabs (with authentic icons from screenshots)
local Tabs = {
    Legitbot = Window:AddTab("Legitbot", "🔫"),
    Ragebot = Window:AddTab("Ragebot", "💀"),
    Visuals = Window:AddTab("Visuals", "👁️"),
    Misc = Window:AddTab("Misc", "🔧"),
    Settings = Window:AddTab("Settings", "⚙️")
}

-- 1. Legitbot Sub-Tabs
local LegitAimbot = Tabs.Legitbot:AddSubTab("Aimbot")
local LegitTrigger = Tabs.Legitbot:AddSubTab("Triggerbot")
local LegitWeapon = Tabs.Legitbot:AddSubTab("Weapon")
local LegitAdvanced = Tabs.Legitbot:AddSubTab("Advanced")

-- Populate Legitbot > Aimbot
local ToggleBox = LegitAimbot:AddLeftGroupbox("Toggle")
ToggleBox:AddToggle("LegitEnable", {
    Text = "Enable Aimbot",
    Default = true
})

local AimKeyButton = ToggleBox:AddLabel("Aim Key"):AddKeyPicker("AimKeyBind", {
    Default = "Mouse1",
    NoUI = false
})

local ToggleKeyButton = ToggleBox:AddLabel("Toggle Key"):AddKeyPicker("ToggleKeyBind", {
    Default = "None",
    NoUI = false
})

-- Populate Legitbot > Weapon
local WeaponBox = LegitWeapon:AddLeftGroupbox("Weapon")
WeaponBox:AddToggle("AutoFire", {
    Text = "Auto Fire",
    Default = false
})
WeaponBox:AddToggle("FireOnPress", {
    Text = "Fire On Press",
    Default = true
})
WeaponBox:AddSlider("AutoPistolInterval", {
    Text = "Auto Pistol Interval",
    Min = 50,
    Max = 500,
    Default = 150,
    Rounding = 0
})

-- 2. Ragebot Sub-Tabs
local RageAimbot = Tabs.Ragebot:AddSubTab("Aimbot")
local RageAccuracy = Tabs.Ragebot:AddSubTab("Accuracy")
local RageAntiAim = Tabs.Ragebot:AddSubTab("Anti-Aim")

-- Populate Ragebot > Aimbot
local RageAimbotBox = RageAimbot:AddLeftGroupbox("Aimbot")
RageAimbotBox:AddToggle("RageEnable", {
    Text = "Enable Ragebot",
    Default = false
})

-- 3. Visuals Sub-Tabs
local VisualsOverlay = Tabs.Visuals:AddSubTab("Overlay")
local VisualsLocal = Tabs.Visuals:AddSubTab("Local")
local VisualsWorld = Tabs.Visuals:AddSubTab("World")
local VisualsChams = Tabs.Visuals:AddSubTab("Chams")
local VisualsSkins = Tabs.Visuals:AddSubTab("Skins")
local VisualsOther = Tabs.Visuals:AddSubTab("Other")

-- Populate Visuals > Overlay
local EnemyBox = VisualsOverlay:AddLeftGroupbox("Enemy")
EnemyBox:AddToggle("EnemyBoxEsp", {
    Text = "Box ESP",
    Default = true
}):AddColorPicker("EnemyBoxColor", {
    Default = Color3.fromRGB(240, 45, 45)
})
EnemyBox:AddToggle("EnemyNameEsp", {
    Text = "Name ESP",
    Default = true
})

local FriendlyBox = VisualsOverlay:AddRightGroupbox("Friendly")
FriendlyBox:AddToggle("FriendlyBoxEsp", {
    Text = "Box ESP",
    Default = false
}):AddColorPicker("FriendlyBoxColor", {
    Default = Color3.fromRGB(45, 120, 240)
})
FriendlyBox:AddToggle("FriendlyNameEsp", {
    Text = "Name ESP",
    Default = false
})

-- 5. Settings Sub-Tabs
local SettingsConfigs = Tabs.Settings:AddSubTab("Configurations")
local SettingsTheme = Tabs.Settings:AddSubTab("Theme")
local SettingsAdvanced = Tabs.Settings:AddSubTab("Advanced")

-- Populate Settings > Theme
Library.ThemeManager:ApplyToTab(SettingsTheme)

-- Populate Settings > Configurations
Library.SaveManager:BuildConfigSection(SettingsConfigs)

-- Menu Utilities on Settings > Advanced
local MenuGroup = SettingsAdvanced:AddLeftGroupbox("Menu Utilities")
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

local WatermarkState = true
MenuGroup:AddToggle("WatermarkToggle", {
    Text = "Show Performance Watermark",
    Default = true,
    Callback = function(val)
        Library:SetWatermarkVisibility(val)
    end
})

-- Initialize notifications
Library:Notify("Aimware v5 Replica Loaded!", 4)
Library:Notify("Press [End] to toggle the main menu visibility.", 6)
