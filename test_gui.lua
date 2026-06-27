-- [[ TEST SCRIPT FOR ANTIGRAVITY MIDNIGHT 1:1 REPLICATION ]] --
local Library
local success, err = pcall(function()
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
    Title = "MIDNIGHT",
    Center = true
})

-- Enable the performance stats watermark
Library:SetWatermarkVisibility(true)

-- Create tabs in their respective sections
-- Signature: Window:AddTab(tabName, icon, sectionName)
local CombatTab = Window:AddTab("Aimbot", "combat", "Combat")

local PlayersTab = Window:AddTab("Players", "eye", "Visuals")
local ItemsTab = Window:AddTab("Items", "eye", "Visuals")
local ViewTab = Window:AddTab("View", "eye", "Visuals")
local HudTab = Window:AddTab("Hud", "eye", "Visuals")

local MainTab = Window:AddTab("Main", "settings", "Misc")
local InventoryTab = Window:AddTab("Inventory", "settings", "Misc")
local CloudTab = Window:AddTab("Cloud", "settings", "Misc")

-- 1. Aimbot Controls
local AimbotBox = CombatTab:AddLeftGroupbox("Aimbot Controls")
AimbotBox:AddToggle("AimbotEnable", { Text = "Enable Aimbot", Default = false })

-- 2. Players Tab Controls (Sub-Tabs: Enemies / Teammates)
local EnemiesSub = PlayersTab:AddSubTab("Enemies")
local TeammatesSub = PlayersTab:AddSubTab("Teammates")

-- Enemies ESP Sub-Tab
local ESPPreview = EnemiesSub:AddLeftGroupbox("ESP Preview")
ESPPreview:AddLabel("2D Box visualizer:")

local Globals = EnemiesSub:AddRightGroupbox("Globals")
Globals:AddToggle("EnableESP", { Text = "Enable", Default = true })
Globals:AddToggle("OnlyVisible", { Text = "Only visible", Default = false })
Globals:AddToggle("Offscreen", { Text = "Offscreen", Default = false }):AddKeyPicker("OffscreenBind", { Default = "V" })
Globals:AddToggle("Sounds", { Text = "Sounds", Default = true })

local Chams = EnemiesSub:AddRightGroupbox("Chams")
Chams:AddToggle("VisibleChams", { Text = "Visible", Default = true }):AddColorPicker("VisColor", { Default = Color3.fromRGB(0, 162, 255) })
Chams:AddToggle("InvisibleChams", { Text = "Invisible", Default = false }):AddColorPicker("InvisColor", { Default = Color3.fromRGB(150, 150, 150) })
Chams:AddDropdown("ChamsType", {
    Text = "Type",
    Values = {"Latex", "Flat", "Textured", "Wireframe"},
    Default = 1
})

-- 3. Settings (Main Tab)
local MenuGroup = MainTab:AddLeftGroupbox("Menu Utilities")
MenuGroup:AddButton("Unload Entire Script", function()
    Library:Unload()
end)

MenuGroup:AddLabel("Toggle Menu Key"):AddKeyPicker("MenuToggleKey", {
    Default = "End",
    Callback = function()
        Library:Notify("Menu visibility toggled!")
    end
})

Library.ThemeManager:ApplyToTab(MainTab)
Library.SaveManager:BuildConfigSection(MainTab)

Library:Notify("Midnight UI replicated successfully!", 4)
