-- [[ MIDNIGHT.IM ROBLOX UI LIBRARY PORT ]] --
-- Premium replica of the elegant, dark glassmorphic Midnight.im CS:GO/CS2 cheat menu.
-- Features icons-only vertical sidebar, clean cyan accenting, rounded checkboxes, and minimal sliders.

local Library = {
    Options = {},
    Toggles = {},
    Registry = {},
    RegistryMap = {},
    Unloaded = false,
    OnUnloadCallbacks = {},
    AccentRegistry = {},
    Theme = {
        Background = Color3.fromRGB(16, 16, 20),   -- Rich Dark Blue-Gray
        Sidebar = Color3.fromRGB(12, 12, 15),      -- Dark Indigo-Black
        Groupbox = Color3.fromRGB(22, 22, 28),     -- Slate Gray Card
        Accent = Color3.fromRGB(0, 180, 255),      -- Midnight Cyan
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(140, 140, 150),
        Border = Color3.fromRGB(28, 28, 35),       -- Slate Border
        Font = Enum.Font.SourceSans,
        FontBold = Enum.Font.SourceSansBold
    }
}

-- Roblox Asset ID Icon mapping for Midnight style sidebar
local IconMap = {
    home = "rbxassetid://6015206346",
    aimbot = "rbxassetid://6031225818",
    combat = "rbxassetid://6031225818",
    eye = "rbxassetid://6031154749",
    visuals = "rbxassetid://6031154749",
    players = "rbxassetid://6023426915",
    items = "rbxassetid://6034853871",
    view = "rbxassetid://6031154749",
    hud = "rbxassetid://6034853721",
    settings = "rbxassetid://6031280224",
    gear = "rbxassetid://6031280224",
    misc = "rbxassetid://6022668955",
    cloud = "rbxassetid://6034853641",
    folder = "rbxassetid://6034853641"
}

-- Safe Font Resolver prioritizing Gotham
pcall(function()
    local FontEnum = Enum.Font
    local gothamExists, gothamFont = pcall(function() return FontEnum["Gotham"] end)
    local gothamBoldExists, gothamBoldFont = pcall(function() return FontEnum["GothamBold"] end)
    
    if gothamExists and gothamFont and gothamBoldExists and gothamBoldFont then
        Library.Theme.Font = gothamFont
        Library.Theme.FontBold = gothamBoldFont
    else
        local interExists, interFont = pcall(function() return FontEnum["Inter"] end)
        local interBoldExists, interBoldFont = pcall(function() return FontEnum["InterBold"] end)
        if interExists and interFont and interBoldExists and interBoldFont then
            Library.Theme.Font = interFont
            Library.Theme.FontBold = interBoldFont
        end
    end
end)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Find or create the screen gui container
local ScreenGui
do
    local success, _ = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
    end)

    if success then
        ScreenGui = Instance.new("ScreenGui", CoreGui)
    else
        ScreenGui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
    end
    ScreenGui.Name = "AntigravityUI_" .. HttpService:GenerateGUID(false):sub(1, 8)
    ScreenGui.ResetOnSpawn = false
end

-- Cleanup Registry
local function TrackInstance(instance)
    table.insert(Library.Registry, instance)
    return instance
end

-- Quick tween helper
local function Tween(obj, duration, properties, style, direction)
    local tweenInfo = TweenInfo.new(duration or 0.12, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, tweenInfo, properties)
    t:Play()
    return t
end

-- Dynamic Accent Color Registry
local function RegisterAccent(instance, property)
    table.insert(Library.AccentRegistry, {
        Instance = instance,
        Property = property
    })
    return instance
end

function Library:UpdateTheme(newColor)
    Library.Theme.Accent = newColor
    
    for _, item in ipairs(Library.AccentRegistry) do
        pcall(function()
            if item.Instance and item.Instance.Parent then
                local isToggle = item.Instance:GetAttribute("IsToggle")
                if isToggle then
                    local isActive = item.Instance:GetAttribute("Active")
                    if isActive then
                        Tween(item.Instance, 0.12, {[item.Property] = newColor})
                    end
                else
                    Tween(item.Instance, 0.12, {[item.Property] = newColor})
                end
            end
        end)
    end
end

-- Dragging logic
local function MakeDraggable(dragFrame, parentFrame)
    local dragging, dragInput, dragStart, startPos
    
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = parentFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(parentFrame, 0.08, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            })
        end
    end)
end

-- Overlay for floating menus
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundTransparency = 1
Overlay.Parent = ScreenGui

local function CloseAllPopups()
    for _, child in ipairs(Overlay:GetChildren()) do
        child:Destroy()
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        task.defer(function()
            local mousePos = UserInputService:GetMouseLocation()
            for _, popup in ipairs(Overlay:GetChildren()) do
                local pos = popup.AbsolutePosition
                local size = popup.AbsoluteSize
                if mousePos.X < pos.X or mousePos.X > pos.X + size.X or mousePos.Y < pos.Y or mousePos.Y > pos.Y + size.Y then
                    popup:Destroy()
                end
            end
        end)
    end
end)

-- Notification area (Toast Notifications)
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "Notifications"
NotificationContainer.Position = UDim2.new(1, -300, 1, -20)
NotificationContainer.Size = UDim2.new(0, 280, 0, 10)
NotificationContainer.AnchorPoint = Vector2.new(0, 1)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.Padding = UDim.new(0, 8)
NotificationLayout.Parent = NotificationContainer

function Library:Notify(text, duration)
    duration = duration or 3.5
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundColor3 = Library.Theme.Groupbox
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = NotificationContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Library.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = card
    
    -- Left-side accent indicator bar
    local leftBar = Instance.new("Frame")
    leftBar.Size = UDim2.new(0, 3, 1, 0)
    leftBar.Position = UDim2.new(0, 0, 0, 0)
    leftBar.BackgroundColor3 = Library.Theme.Accent
    leftBar.BorderSizePixel = 0
    leftBar.Parent = card
    RegisterAccent(leftBar, "BackgroundColor3")
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Library.Theme.Text
    label.Text = text
    label.TextWrapped = true
    label.Font = Library.Theme.Font
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card
    
    card.Size = UDim2.new(1, 100, 0, 42)
    card.BackgroundTransparency = 1
    
    Tween(card, 0.25, {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 0.05})
    
    task.delay(duration, function()
        local t = Tween(card, 0.25, {Size = UDim2.new(1, 100, 0, 0), BackgroundTransparency = 1})
        t.Completed:Connect(function()
            card:Destroy()
        end)
    end)
end

-- Keybind Manager
local Keybinds = {}
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local code = input.KeyCode.Name
        if Keybinds[code] then
            for _, bind in ipairs(Keybinds[code]) do
                bind()
            end
        end
    end
end)

local function AddGlobalKeybind(key, callback)
    if not Keybinds[key] then Keybinds[key] = {} end
    table.insert(Keybinds[key], callback)
end

local function RemoveGlobalKeybind(key, callback)
    if Keybinds[key] then
        for i, cb in ipairs(Keybinds[key]) do
            if cb == callback then
                table.remove(Keybinds[key], i)
                break
            end
        end
    end
end

-- Performance Watermark
local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Name = "Watermark"
WatermarkFrame.Size = UDim2.new(0, 260, 0, 26)
WatermarkFrame.Position = UDim2.new(1, -270, 0, 10)
WatermarkFrame.BackgroundColor3 = Library.Theme.Background
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.Visible = false
WatermarkFrame.Parent = ScreenGui

local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 3)
wmCorner.Parent = WatermarkFrame

local wmStroke = Instance.new("UIStroke")
wmStroke.Color = Library.Theme.Border
wmStroke.Thickness = 1
wmStroke.Parent = WatermarkFrame

local wmLabel = Instance.new("TextLabel")
wmLabel.Size = UDim2.new(1, -16, 1, 0)
wmLabel.Position = UDim2.new(0, 8, 0, 0)
wmLabel.BackgroundTransparency = 1
wmLabel.TextColor3 = Library.Theme.Text
wmLabel.Text = "midnight.im | FPS: -- | Ping: --"
wmLabel.Font = Library.Theme.FontBold
wmLabel.TextSize = 11
wmLabel.TextXAlignment = Enum.TextXAlignment.Center
wmLabel.Parent = WatermarkFrame

local fpsCount = 0
local lastFpsUpdate = os.clock()
local frameTimes = {}

RunService.RenderStepped:Connect(function()
    if not WatermarkFrame.Visible then return end
    local now = os.clock()
    table.insert(frameTimes, now)
    
    while frameTimes[1] and frameTimes[1] < now - 1 do
        table.remove(frameTimes, 1)
    end
    
    fpsCount = #frameTimes
    
    if now - lastFpsUpdate >= 1 then
        lastFpsUpdate = now
        local ping = 0
        pcall(function()
            ping = math.round(Players.LocalPlayer:GetNetworkPing() * 1000)
        end)
        local timeStr = os.date("%H:%M:%S")
        wmLabel.Text = string.format("midnight.im | %s | FPS: %d | Ping: %dms", timeStr, fpsCount, ping)
    end
end)

function Library:SetWatermarkVisibility(visible)
    WatermarkFrame.Visible = visible
end

-- MainWindow construction (Midnight style glassmorphic layout)
function Library:CreateWindow(config)
    config = config or {}
    local titleText = config.Title or "MIDNIGHT"
    local CreateGroupbox
    
    local WindowFrame = Instance.new("Frame")
    WindowFrame.Size = UDim2.new(0, 720, 0, 520)
    WindowFrame.Position = UDim2.new(0.5, -360, 0.5, -260)
    WindowFrame.BackgroundColor3 = Color3.fromRGB(12, 13, 18) -- `#0c0d12` main background
    WindowFrame.BorderSizePixel = 0
    WindowFrame.ClipsDescendants = true
    WindowFrame.Parent = TrackInstance(ScreenGui)
    
    local wCorner = Instance.new("UICorner")
    wCorner.CornerRadius = UDim.new(0, 4) -- 4px corner rounding
    wCorner.Parent = WindowFrame
    
    local wStroke = Instance.new("UIStroke")
    wStroke.Color = Color3.fromRGB(29, 32, 40) -- `#1d2028` border
    wStroke.Thickness = 1
    wStroke.Parent = WindowFrame
    
    -- Wide Sidebar on the left (160px wide, full height)
    local Sidebar = Instance.new("Frame")
    Sidebar.Position = UDim2.new(0, 0, 0, 0)
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(8, 8, 10) -- `#08080a` sidebar background
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = WindowFrame
    
    local SideSep = Instance.new("Frame")
    SideSep.Position = UDim2.new(1, -1, 0, 0)
    SideSep.Size = UDim2.new(0, 1, 1, 0)
    SideSep.BackgroundColor3 = Color3.fromRGB(29, 32, 40)
    SideSep.BorderSizePixel = 0
    SideSep.Parent = Sidebar
    
    -- Logo Frame at the top-left
    local LogoFrame = Instance.new("Frame")
    LogoFrame.Size = UDim2.new(1, 0, 0, 50)
    LogoFrame.Position = UDim2.new(0, 0, 0, 0)
    LogoFrame.BackgroundTransparency = 1
    LogoFrame.Parent = Sidebar
    
    -- Midnight logo (pyramid style triangle)
    local LogoLabel = Instance.new("TextLabel")
    LogoLabel.Size = UDim2.new(0, 24, 1, 0)
    LogoLabel.Position = UDim2.new(0, 16, 0, 0)
    LogoLabel.BackgroundTransparency = 1
    LogoLabel.Text = "▲"
    LogoLabel.TextColor3 = Library.Theme.Accent -- neon blue
    LogoLabel.TextSize = 16
    LogoLabel.Font = Library.Theme.FontBold
    LogoLabel.Parent = LogoFrame
    RegisterAccent(LogoLabel, "TextColor3")
    
    local LogoText = Instance.new("TextLabel")
    LogoText.Size = UDim2.new(1, -45, 1, 0)
    LogoText.Position = UDim2.new(0, 40, 0, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "MIDNIGHT"
    LogoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoText.TextSize = 13
    LogoText.Font = Library.Theme.FontBold
    LogoText.TextXAlignment = Enum.TextXAlignment.Left
    LogoText.Parent = LogoFrame
    
    -- Scrollable button holder inside sidebar
    local ButtonHolder = Instance.new("ScrollingFrame")
    ButtonHolder.Position = UDim2.new(0, 0, 0, 50)
    ButtonHolder.Size = UDim2.new(1, 0, 1, -50)
    ButtonHolder.BackgroundTransparency = 1
    ButtonHolder.BorderSizePixel = 0
    ButtonHolder.ScrollBarThickness = 0
    ButtonHolder.Parent = Sidebar
    
    local SideLayout = Instance.new("UIListLayout")
    SideLayout.Padding = UDim.new(0, 12)
    SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SideLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    SideLayout.Parent = ButtonHolder
    
    -- Pre-create three section containers (Combat, Visuals, Misc)
    local SectionContainers = {}
    local function CreateSection(name)
        local secFrame = Instance.new("Frame")
        secFrame.Size = UDim2.new(1, 0, 0, 0)
        secFrame.BackgroundTransparency = 1
        secFrame.Visible = false
        secFrame.Parent = ButtonHolder
        
        local OrderMap = { ["Combat"] = 1, ["Visuals"] = 2, ["Misc"] = 3 }
        secFrame.LayoutOrder = OrderMap[name] or 4
        
        local secLayout = Instance.new("UIListLayout")
        secLayout.Padding = UDim.new(0, 4)
        secLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        secLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        secLayout.SortOrder = Enum.SortOrder.LayoutOrder
        secLayout.Parent = secFrame
        
        secLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            secFrame.Size = UDim2.new(1, 0, 0, secLayout.AbsoluteContentSize.Y)
        end)
        
        local secLabel = Instance.new("TextLabel")
        secLabel.Size = UDim2.new(1, -28, 0, 18)
        secLabel.BackgroundTransparency = 1
        secLabel.Text = name
        secLabel.TextColor3 = Color3.fromRGB(90, 95, 105) -- `#5a5f69`
        secLabel.Font = Library.Theme.FontBold
        secLabel.TextSize = 10
        secLabel.TextXAlignment = Enum.TextXAlignment.Left
        secLabel.LayoutOrder = 1
        secLabel.Parent = secFrame
        
        local buttonList = Instance.new("Frame")
        buttonList.Size = UDim2.new(1, 0, 0, 0)
        buttonList.BackgroundTransparency = 1
        buttonList.LayoutOrder = 2
        buttonList.Parent = secFrame
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 4)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = buttonList
        
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            buttonList.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
        end)
        
        SectionContainers[name] = buttonList
    end
    
    CreateSection("Combat")
    CreateSection("Visuals")
    CreateSection("Misc")
    
    -- Main container on the right
    local Container = Instance.new("Frame")
    Container.Position = UDim2.new(0, 160, 0, 0)
    Container.Size = UDim2.new(1, -160, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = WindowFrame
    
    -- TopBar of the main container (holds horizontal sub-tabs and decorations)
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = Container
    
    MakeDraggable(TopBar, WindowFrame)
    
    -- Holder for Horizontal Sub-Tabs in the top bar
    local SubTabButtonsHolderFrame = Instance.new("Frame")
    SubTabButtonsHolderFrame.Position = UDim2.new(0, 16, 0, 0)
    SubTabButtonsHolderFrame.Size = UDim2.new(0.65, 0, 1, 0)
    SubTabButtonsHolderFrame.BackgroundTransparency = 1
    SubTabButtonsHolderFrame.Name = "SubTabButtonsHolder"
    SubTabButtonsHolderFrame.Parent = TopBar
    
    -- Decorative Search and Settings icons on the top-right
    local DecoHolder = Instance.new("Frame")
    DecoHolder.Size = UDim2.new(0, 60, 1, 0)
    DecoHolder.Position = UDim2.new(1, -70, 0, 0)
    DecoHolder.BackgroundTransparency = 1
    DecoHolder.Parent = TopBar
    
    local DecoLayout = Instance.new("UIListLayout")
    DecoLayout.FillDirection = Enum.FillDirection.Horizontal
    DecoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    DecoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    DecoLayout.Padding = UDim.new(0, 12)
    DecoLayout.Parent = DecoHolder
    
    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.Size = UDim2.new(0, 14, 0, 14)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Image = "rbxassetid://6031154784"
    SearchIcon.ImageColor3 = Color3.fromRGB(150, 155, 165)
    SearchIcon.Parent = DecoHolder
    
    local SettingsIcon = Instance.new("ImageLabel")
    SettingsIcon.Size = UDim2.new(0, 14, 0, 14)
    SettingsIcon.BackgroundTransparency = 1
    SettingsIcon.Image = "rbxassetid://6031280224"
    SettingsIcon.ImageColor3 = Color3.fromRGB(150, 155, 165)
    SettingsIcon.Parent = DecoHolder
    
    -- top-right close/minimize buttons (macOS style circle style for Midnight)
    local ControlFrame = Instance.new("Frame")
    ControlFrame.Position = UDim2.new(1, -55, 0, 0)
    ControlFrame.Size = UDim2.new(0, 45, 1, 0)
    ControlFrame.BackgroundTransparency = 1
    ControlFrame.Parent = TopBar
    
    local ControlLayout = Instance.new("UIListLayout")
    ControlLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlLayout.Padding = UDim.new(0, 8)
    ControlLayout.Parent = ControlFrame
    
    local MinButton = Instance.new("TextButton")
    MinButton.Size = UDim2.new(0, 10, 0, 10)
    MinButton.BackgroundColor3 = Color3.fromRGB(250, 180, 50)
    MinButton.Text = ""
    MinButton.Parent = ControlFrame
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = MinButton
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 10, 0, 10)
    CloseButton.BackgroundColor3 = Color3.fromRGB(250, 80, 80)
    CloseButton.Text = ""
    CloseButton.Parent = ControlFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = CloseButton
    
    local Minimized = false
    MinButton.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        CloseAllPopups()
        if Minimized then
            Tween(WindowFrame, 0.2, {Size = UDim2.new(0, 720, 0, 45)})
        else
            Tween(WindowFrame, 0.2, {Size = UDim2.new(0, 720, 0, 520)})
        end
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Library:Unload()
    end)
    
    local Window = {
        Tabs = {},
        ActiveTab = nil,
        Keybind = Enum.KeyCode.End
    }
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Window.Keybind then
            WindowFrame.Visible = not WindowFrame.Visible
            CloseAllPopups()
        end
    end)
    
    function Window:AddTab(tabName, icon, sectionName)
        local tabIndex = #Window.Tabs + 1
        
        -- Auto-group tabs if section name is not specified
        if not sectionName then
            local lowerName = tabName:lower()
            if string.find(lowerName, "aim") or string.find(lowerName, "combat") or string.find(lowerName, "legit") or string.find(lowerName, "rage") or string.find(lowerName, "main") then
                sectionName = "Combat"
            elseif string.find(lowerName, "visual") or string.find(lowerName, "esp") or string.find(lowerName, "player") or string.find(lowerName, "item") or string.find(lowerName, "view") or string.find(lowerName, "hud") then
                sectionName = "Visuals"
            else
                sectionName = "Misc"
            end
        end
        
        -- Make the section container visible
        local parentSection = SectionContainers[sectionName] or SectionContainers["Misc"]
        parentSection.Parent.Visible = true
        
        -- Wide tab button
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, -20, 0, 32)
        TabButton.BackgroundColor3 = Color3.fromRGB(19, 21, 28)
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Text = ""
        TabButton.Parent = parentSection
        
        local tbCorner = Instance.new("UICorner")
        tbCorner.CornerRadius = UDim.new(0, 4)
        tbCorner.Parent = TabButton
        
        -- High quality monochrome ImageLabel for the icon
        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Size = UDim2.new(0, 14, 0, 14)
        TabIcon.Position = UDim2.new(0, 12, 0.5, -7)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = IconMap[icon:lower()] or IconMap[tabName:lower()] or "rbxassetid://6015206346"
        TabIcon.ImageColor3 = Color3.fromRGB(120, 125, 135) -- `#787d87`
        TabIcon.Parent = TabButton
        
        -- TextLabel for the tab name
        local TabText = Instance.new("TextLabel")
        TabText.Size = UDim2.new(1, -40, 1, 0)
        TabText.Position = UDim2.new(0, 36, 0, 0)
        TabText.BackgroundTransparency = 1
        TabText.Text = tabName
        TabText.TextColor3 = Color3.fromRGB(120, 125, 135) -- `#787d87`
        TabText.Font = Library.Theme.FontBold
        TabText.TextSize = 11
        TabText.TextXAlignment = Enum.TextXAlignment.Left
        TabText.Parent = TabButton
        
        -- Frame to hold horizontal sub-tab buttons in the TopBar
        local SubTabButtonsHolder = Instance.new("Frame")
        SubTabButtonsHolder.Size = UDim2.new(1, 0, 1, 0)
        SubTabButtonsHolder.BackgroundTransparency = 1
        SubTabButtonsHolder.Visible = false
        SubTabButtonsHolder.Parent = SubTabButtonsHolderFrame
        
        local subLayout = Instance.new("UIListLayout")
        subLayout.FillDirection = Enum.FillDirection.Horizontal
        subLayout.Padding = UDim.new(0, 16)
        subLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        subLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        subLayout.Parent = SubTabButtonsHolder
        
        -- Main Tab Panel to hold all its sub-tab panels
        local TabPanel = Instance.new("Frame")
        TabPanel.Position = UDim2.new(0, 0, 0, 45)
        TabPanel.Size = UDim2.new(1, 0, 1, -45)
        TabPanel.BackgroundTransparency = 1
        TabPanel.Visible = false
        TabPanel.Parent = Container
        
        local Tab = {
            SubTabs = {},
            ActiveSubTab = nil,
            TabButton = TabButton,
            TabText = TabText,
            TabIcon = TabIcon,
            SubTabButtonsHolder = SubTabButtonsHolder,
            Panel = TabPanel
        }
        
        -- Hover styling
        TabButton.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabText, 0.1, {TextColor3 = Color3.fromRGB(240, 240, 240)})
                Tween(TabIcon, 0.1, {ImageColor3 = Color3.fromRGB(240, 240, 240)})
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabText, 0.1, {TextColor3 = Color3.fromRGB(120, 125, 135)})
                Tween(TabIcon, 0.1, {ImageColor3 = Color3.fromRGB(120, 125, 135)})
            end
        end)
        
        function Tab:AddSubTab(subTabName)
            local subIndex = #Tab.SubTabs + 1
            
            local SubTabButton = Instance.new("TextButton")
            SubTabButton.Size = UDim2.new(0, 80, 1, 0)
            SubTabButton.BackgroundTransparency = 1
            SubTabButton.BorderSizePixel = 0
            SubTabButton.Text = subTabName:upper()
            SubTabButton.TextColor3 = Library.Theme.TextMuted
            SubTabButton.Font = Library.Theme.FontBold
            SubTabButton.TextSize = 11
            SubTabButton.Parent = SubTabButtonsHolder
            
            -- Active Underline Indicator at the bottom of the horizontal button
            local SubIndicator = Instance.new("Frame")
            SubIndicator.Name = "SubIndicator"
            SubIndicator.Size = UDim2.new(1, 0, 0, 2)
            SubIndicator.Position = UDim2.new(0, 0, 1, -2)
            SubIndicator.BackgroundColor3 = Library.Theme.Accent -- neon blue
            SubIndicator.BorderSizePixel = 0
            SubIndicator.Visible = false
            SubIndicator.Parent = SubTabButton
            RegisterAccent(SubIndicator, "BackgroundColor3")
            
            local SubPanel = Instance.new("Frame")
            SubPanel.Size = UDim2.new(1, 0, 1, 0)
            SubPanel.BackgroundTransparency = 1
            SubPanel.Visible = false
            SubPanel.Parent = TabPanel -- parent to TabPanel instead of Container!
            
            local LeftScroll = Instance.new("ScrollingFrame")
            LeftScroll.Size = UDim2.new(0.5, -15, 1, -20)
            LeftScroll.Position = UDim2.new(0, 10, 0, 10)
            LeftScroll.BackgroundTransparency = 1
            LeftScroll.BorderSizePixel = 0
            LeftScroll.ScrollBarThickness = 3
            LeftScroll.ScrollBarImageColor3 = Library.Theme.Border
            LeftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            LeftScroll.Parent = SubPanel
            
            local LeftLayout = Instance.new("UIListLayout")
            LeftLayout.Padding = UDim.new(0, 10)
            LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
            LeftLayout.Parent = LeftScroll
            
            LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                LeftScroll.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y + 20)
            end)
            
            local RightScroll = Instance.new("ScrollingFrame")
            RightScroll.Size = UDim2.new(0.5, -15, 1, -20)
            RightScroll.Position = UDim2.new(0.5, 5, 0, 10)
            RightScroll.BackgroundTransparency = 1
            RightScroll.BorderSizePixel = 0
            RightScroll.ScrollBarThickness = 3
            RightScroll.ScrollBarImageColor3 = Library.Theme.Border
            RightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            RightScroll.Parent = SubPanel
            
            local RightLayout = Instance.new("UIListLayout")
            RightLayout.Padding = UDim.new(0, 10)
            RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
            RightLayout.Parent = RightScroll
            
            RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y + 20)
            end)
            
            local SubTab = {
                Button = SubTabButton,
                Panel = SubPanel,
                LeftScroll = LeftScroll,
                RightScroll = RightScroll
            }
            
            local function ActivateSub()
                if Tab.ActiveSubTab then
                    Tab.ActiveSubTab.Button.TextColor3 = Library.Theme.TextMuted
                    if Tab.ActiveSubTab.Button:FindFirstChild("SubIndicator") then
                        Tab.ActiveSubTab.Button.SubIndicator.Visible = false
                    end
                    Tab.ActiveSubTab.Panel.Visible = false
                end
                Tab.ActiveSubTab = SubTab
                SubTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                SubIndicator.Visible = true
                SubPanel.Visible = true
                CloseAllPopups()
            end
            
            SubTabButton.MouseButton1Click:Connect(ActivateSub)
            
            function SubTab:AddLeftGroupbox(title)
                return CreateGroupbox(title, LeftScroll)
            end
            function SubTab:AddRightGroupbox(title)
                return CreateGroupbox(title, RightScroll)
            end
            
            table.insert(Tab.SubTabs, SubTab)
            Tab.SubTabs[subTabName] = SubTab
            
            task.defer(function()
                if Tab.ActiveSubTab == nil then
                    ActivateSub()
                end
            end)
            
            return SubTab
        end
        
        -- Backwards compatibility layout fallbacks:
        function Tab:AddLeftGroupbox(title)
            local defaultSub = Tab.SubTabs["General"] or Tab:AddSubTab("General")
            return defaultSub:AddLeftGroupbox(title)
        end
        function Tab:AddRightGroupbox(title)
            local defaultSub = Tab.SubTabs["General"] or Tab:AddSubTab("General")
            return defaultSub:AddRightGroupbox(title)
        end
        
        local function Activate()
            if Window.ActiveTab then
                Tween(Window.ActiveTab.TabText, 0.1, {TextColor3 = Color3.fromRGB(120, 125, 135)})
                Tween(Window.ActiveTab.TabIcon, 0.1, {ImageColor3 = Color3.fromRGB(120, 125, 135)})
                Window.ActiveTab.TabButton.BackgroundColor3 = Color3.fromRGB(19, 21, 28)
                Window.ActiveTab.TabButton.BackgroundTransparency = 1
                Window.ActiveTab.SubTabButtonsHolder.Visible = false
                Window.ActiveTab.Panel.Visible = false -- Hide old main TabPanel!
            end
            Window.ActiveTab = Tab
            Tween(TabText, 0.1, {TextColor3 = Color3.fromRGB(255, 255, 255)})
            Tween(TabIcon, 0.1, {ImageColor3 = Color3.fromRGB(255, 255, 255)})
            TabButton.BackgroundColor3 = Color3.fromRGB(19, 21, 28) -- Active dark block
            TabButton.BackgroundTransparency = 0.5
            SubTabButtonsHolder.Visible = true
            TabPanel.Visible = true -- Show new main TabPanel!
            CloseAllPopups()
        end
        
        TabButton.MouseButton1Click:Connect(Activate)
        
        task.defer(function()
            if not Window.ActiveTab then Activate() end
        end)
        
        table.insert(Window.Tabs, Tab)
        return Tab
    end
        
        function CreateGroupbox(title, parentScroll)
            local gb = Instance.new("Frame")
            gb.Size = UDim2.new(1, -6, 0, 40)
            gb.BackgroundColor3 = Library.Theme.Groupbox
            gb.BorderSizePixel = 0
            gb.Parent = parentScroll
            
            local gbCorner = Instance.new("UICorner")
            gbCorner.CornerRadius = UDim.new(0, 3)
            gbCorner.Parent = gb
            
            local gbStroke = Instance.new("UIStroke")
            gbStroke.Color = Library.Theme.Border
            gbStroke.Thickness = 1
            gbStroke.Parent = gb
            
            local gbHeader = Instance.new("TextLabel")
            gbHeader.Position = UDim2.new(0, 12, 0, 8)
            gbHeader.Size = UDim2.new(1, -24, 0, 16)
            gbHeader.BackgroundTransparency = 1
            gbHeader.Text = title:upper()
            gbHeader.TextColor3 = Library.Theme.Text
            gbHeader.Font = Library.Theme.FontBold
            gbHeader.TextSize = 10
            gbHeader.TextXAlignment = Enum.TextXAlignment.Left
            gbHeader.Parent = gb
            
            local ContentArea = Instance.new("Frame")
            ContentArea.Position = UDim2.new(0, 12, 0, 28)
            ContentArea.Size = UDim2.new(1, -24, 1, -36)
            ContentArea.BackgroundTransparency = 1
            ContentArea.Parent = gb
            
            local ContentLayout = Instance.new("UIListLayout")
            ContentLayout.Padding = UDim.new(0, 8)
            ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ContentLayout.Parent = ContentArea
            
            ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                gb.Size = UDim2.new(1, -6, 0, ContentLayout.AbsoluteContentSize.Y + 36)
            end)
            
            local Groupbox = {}
            
            -- [[ TOGGLE COMPONENT ]] --
            function Groupbox:AddToggle(id, options)
                options = options or {}
                local text = options.Text or "Toggle"
                local default = options.Default or false
                local callback = options.Callback or function() end
                
                local toggleFrame = Instance.new("TextButton")
                toggleFrame.Size = UDim2.new(1, 0, 0, 24)
                toggleFrame.BackgroundTransparency = 1
                toggleFrame.Text = ""
                toggleFrame.Parent = ContentArea
                
                -- Checkbox frame on the left (sharp blue box when active)
                local CheckboxFrame = Instance.new("Frame")
                CheckboxFrame.Size = UDim2.new(0, 14, 0, 14)
                CheckboxFrame.Position = UDim2.new(0, 0, 0.5, -7)
                CheckboxFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                CheckboxFrame.BorderSizePixel = 0
                CheckboxFrame.Parent = toggleFrame
                
                local cbCorner = Instance.new("UICorner")
                cbCorner.CornerRadius = UDim.new(0, 3)
                cbCorner.Parent = CheckboxFrame
                
                local cbStroke = Instance.new("UIStroke")
                cbStroke.Color = Color3.fromRGB(35, 35, 45)
                cbStroke.Thickness = 1
                cbStroke.Parent = CheckboxFrame
                
                local CheckLabel = Instance.new("TextLabel")
                CheckLabel.Size = UDim2.new(1, 0, 1, 0)
                CheckLabel.BackgroundTransparency = 1
                CheckLabel.Text = "✓"
                CheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                CheckLabel.Font = Library.Theme.FontBold
                CheckLabel.TextSize = 12
                CheckLabel.Visible = false
                CheckLabel.Parent = CheckboxFrame
                
                local ToggleState = default
                
                local function SetState(val, skipCallback)
                    ToggleState = val
                    Library.Toggles[id] = { Value = val }
                    
                    if not skipCallback then
                        pcall(callback, val)
                    end
                    
                    if ToggleState then
                        Tween(CheckboxFrame, 0.08, {BackgroundColor3 = Library.Theme.Accent})
                        Tween(cbStroke, 0.08, {Color = Library.Theme.Accent})
                        CheckLabel.Visible = true
                    else
                        Tween(CheckboxFrame, 0.08, {BackgroundColor3 = Color3.fromRGB(16, 16, 20)})
                        Tween(cbStroke, 0.08, {Color = Color3.fromRGB(35, 35, 45)})
                        CheckLabel.Visible = false
                    end
                end               
                local label = Instance.new("TextLabel")
                label.Position = UDim2.new(0, 22, 0, 0) -- shifted right of checkbox
                label.Size = UDim2.new(1, -122, 1, 0) -- leave room for keybind/colorpickers on far right
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = Library.Theme.Text
                label.Font = Library.Theme.Font
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = toggleFrame
                
                local RightControls = Instance.new("Frame")
                RightControls.Size = UDim2.new(0, 95, 1, 0)
                RightControls.Position = UDim2.new(1, -95, 0, 0)
                RightControls.BackgroundTransparency = 1
                RightControls.Parent = toggleFrame
                
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                RightLayout.Padding = UDim.new(0, 6)
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightControls
                

                
                toggleFrame.MouseButton1Click:Connect(function()
                    SetState(not ToggleState)
                end)
                
                SetState(default, true)
                
                local Toggle = {
                    SetValue = function(_, v) SetState(v) end
                }
                
                function Toggle:AddKeyPicker(kpId, kpOptions)
                    kpOptions = kpOptions or {}
                    local kpDefault = kpOptions.Default or "None"
                    local syncToggle = kpOptions.SyncToggleState or false
                    
                    local KeybindButton = Instance.new("TextButton")
                    KeybindButton.Size = UDim2.new(0, 45, 0, 18)
                    KeybindButton.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                    KeybindButton.Text = "[" .. kpDefault .. "]"
                    KeybindButton.TextColor3 = Library.Theme.TextMuted
                    KeybindButton.Font = Library.Theme.Font
                    KeybindButton.TextSize = 11
                    KeybindButton.LayoutOrder = 50
                    KeybindButton.Parent = RightControls
                    
                    local kbCorner = Instance.new("UICorner")
                    kbCorner.CornerRadius = UDim.new(0, 2)
                    kbCorner.Parent = KeybindButton
                    
                    local kbStroke = Instance.new("UIStroke")
                    kbStroke.Color = Library.Theme.Border
                    kbStroke.Thickness = 1
                    kbStroke.Parent = KeybindButton
                    
                    local currentKey = kpDefault
                    local binding = false
                    
                    local function SetBind(keyName)
                        if currentKey ~= "None" then
                            RemoveGlobalKeybind(currentKey, Toggle.Trigger)
                        end
                        currentKey = keyName
                        KeybindButton.Text = "[" .. keyName .. "]"
                        Library.Options[kpId] = { Value = keyName }
                        if keyName ~= "None" then
                            AddGlobalKeybind(keyName, Toggle.Trigger)
                        end
                    end
                    
                    function Toggle.Trigger()
                        if syncToggle then
                            SetState(not ToggleState)
                        end
                    end
                    
                    KeybindButton.MouseButton1Click:Connect(function()
                        binding = true
                        KeybindButton.Text = "[...]"
                    end)
                    
                    UserInputService.InputBegan:Connect(function(input, processed)
                        if binding and not processed then
                            binding = false
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                local key = input.KeyCode.Name
                                if input.KeyCode == Enum.KeyCode.Escape then
                                    SetBind("None")
                                else
                                    SetBind(key)
                                end
                            else
                                SetBind("None")
                            end
                        end
                    end)
                    
                    SetBind(kpDefault)
                    return Toggle
                end
                
                function Toggle:AddColorPicker(cpId, cpOptions)
                    cpOptions = cpOptions or {}
                    local cpDefault = cpOptions.Default or Color3.new(1, 1, 1)
                    local cpCallback = cpOptions.Callback or function() end
                    
                    local ColorBox = Instance.new("TextButton")
                    ColorBox.Size = UDim2.new(0, 14, 0, 14)
                    ColorBox.BackgroundColor3 = cpDefault
                    ColorBox.Text = ""
                    ColorBox.LayoutOrder = 10
                    ColorBox.Parent = RightControls
                    
                    local cpCorner = Instance.new("UICorner")
                    cpCorner.CornerRadius = UDim.new(0, 2)
                    cpCorner.Parent = ColorBox
                    
                    local cpStroke = Instance.new("UIStroke")
                    cpStroke.Color = Library.Theme.Border
                    cpStroke.Thickness = 1
                    cpStroke.Parent = ColorBox
                    
                    local currentColor = cpDefault
                    Library.Options[cpId] = { Value = currentColor }
                    
                    ColorBox.MouseButton1Click:Connect(function()
                        CloseAllPopups()
                        
                        local PickerPopup = Instance.new("Frame")
                        PickerPopup.Size = UDim2.new(0, 170, 0, 180)
                        PickerPopup.BackgroundColor3 = Library.Theme.Groupbox
                        PickerPopup.Position = UDim2.new(0, ColorBox.AbsolutePosition.X - 180, 0, ColorBox.AbsolutePosition.Y)
                        PickerPopup.Parent = Overlay
                        
                        local popupCorner = Instance.new("UICorner")
                        popupCorner.CornerRadius = UDim.new(0, 3)
                        popupCorner.Parent = PickerPopup
                        
                        local popupStroke = Instance.new("UIStroke")
                        popupStroke.Color = Library.Theme.Border
                        popupStroke.Thickness = 1
                        popupStroke.Parent = PickerPopup
                        
                        local PresetsFrame = Instance.new("Frame")
                        PresetsFrame.Position = UDim2.new(0, 10, 0, 10)
                        PresetsFrame.Size = UDim2.new(1, -20, 0, 36)
                        PresetsFrame.BackgroundTransparency = 1
                        PresetsFrame.Parent = PickerPopup
                        
                        local PresetsLayout = Instance.new("UIGridLayout")
                        PresetsLayout.CellSize = UDim2.new(0, 14, 0, 14)
                        PresetsLayout.CellPadding = UDim2.new(0, 5, 0, 5)
                        PresetsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        PresetsLayout.Parent = PresetsFrame
                        
                        local list = Instance.new("Frame")
                        list.Size = UDim2.new(1, -20, 1, -56)
                        list.Position = UDim2.new(0, 10, 0, 50)
                        list.BackgroundTransparency = 1
                        list.Parent = PickerPopup
                        
                        local listLayout = Instance.new("UIListLayout")
                        listLayout.Padding = UDim.new(0, 6)
                        listLayout.Parent = list
                        
                        local r, g, b = math.round(currentColor.R * 255), math.round(currentColor.G * 255), math.round(currentColor.B * 255)
                        local sliders = {}
                        
                        local function Reevaluate()
                            local newColor = Color3.fromRGB(r, g, b)
                            currentColor = newColor
                            ColorBox.BackgroundColor3 = newColor
                            Library.Options[cpId] = { Value = newColor }
                            pcall(cpCallback, newColor)
                        end
                        
                        local function CreateRGBSlider(name, colorVal, sliderColor, changeCallback)
                            local sFrame = Instance.new("Frame")
                            sFrame.Size = UDim2.new(1, 0, 0, 22)
                            sFrame.BackgroundTransparency = 1
                            sFrame.Parent = list
                            
                            local sLabel = Instance.new("TextLabel")
                            sLabel.Size = UDim2.new(0.2, 0, 1, 0)
                            sLabel.BackgroundTransparency = 1
                            sLabel.Text = name
                            sLabel.TextColor3 = Library.Theme.TextMuted
                            sLabel.Font = Library.Theme.Font
                            sLabel.TextSize = 11
                            sLabel.Parent = sFrame
                            
                            local track = Instance.new("TextButton")
                            track.Size = UDim2.new(0.8, -5, 0, 6)
                            track.Position = UDim2.new(0.2, 5, 0.5, -3)
                            track.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                            track.BorderSizePixel = 0
                            track.Text = ""
                            track.Parent = sFrame
                            
                            local tStr = Instance.new("UIStroke")
                            tStr.Color = Library.Theme.Border
                            tStr.Thickness = 1
                            tStr.Parent = track
                            
                            local fill = Instance.new("Frame")
                            fill.Size = UDim2.new(colorVal / 255, 0, 1, 0)
                            fill.BackgroundColor3 = sliderColor
                            fill.BorderSizePixel = 0
                            fill.Parent = track
                            
                            local fCorner = Instance.new("UICorner")
                            fCorner.CornerRadius = UDim.new(1, 0)
                            fCorner.Parent = fill
                            
                            local trCorner = Instance.new("UICorner")
                            trCorner.CornerRadius = UDim.new(1, 0)
                            trCorner.Parent = track
                            
                            local function Update(input)
                                local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                                fill.Size = UDim2.new(pct, 0, 1, 0)
                                changeCallback(math.round(pct * 255))
                            end
                            
                            local dragging = false
                            track.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    dragging = true
                                    Update(input)
                                end
                            end)
                            UserInputService.InputChanged:Connect(function(input)
                                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                    Update(input)
                                end
                            end)
                            UserInputService.InputEnded:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    dragging = false
                                end
                            end)
                            
                            sliders[name] = {
                                Track = track,
                                Fill = fill,
                                UpdateValue = function(newVal)
                                    fill.Size = UDim2.new(newVal / 255, 0, 1, 0)
                                end
                            }
                        end
                        
                        CreateRGBSlider("R", r, Color3.fromRGB(255, 75, 75), function(val) r = val; Reevaluate() end)
                        CreateRGBSlider("G", g, Color3.fromRGB(0, 220, 140), function(val) g = val; Reevaluate() end)
                        CreateRGBSlider("B", b, Color3.fromRGB(85, 110, 250), function(val) b = val; Reevaluate() end)
                        
                        local presets = {
                            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
                            Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 255),
                            Color3.fromRGB(255, 128, 0), Color3.fromRGB(128, 0, 255), Color3.fromRGB(255, 255, 255),
                            Color3.fromRGB(128, 128, 128), Color3.fromRGB(30, 30, 30), Color3.fromRGB(0, 0, 0)
                        }
                        
                        for i, color in ipairs(presets) do
                            local pBtn = Instance.new("TextButton")
                            pBtn.BackgroundColor3 = color
                            pBtn.Text = ""
                            pBtn.Parent = PresetsFrame
                            
                            local pCorner = Instance.new("UICorner")
                            pCorner.CornerRadius = UDim.new(1, 0)
                            pCorner.Parent = pBtn
                            
                            local pStr = Instance.new("UIStroke")
                            pStr.Color = Color3.fromRGB(35, 35, 45)
                            pStr.Thickness = 1
                            pStr.Parent = pBtn
                            
                            pBtn.MouseButton1Click:Connect(function()
                                r = math.round(color.R * 255)
                                g = math.round(color.G * 255)
                                b = math.round(color.B * 255)
                                sliders["R"].UpdateValue(r)
                                sliders["G"].UpdateValue(g)
                                sliders["B"].UpdateValue(b)
                                Reevaluate()
                            end)
                        end
                    end)
                    
                    return Toggle
                end
                
                return Toggle
            end
            
            -- [[ SLIDER COMPONENT ]] --
            function Groupbox:AddSlider(id, options)
                options = options or {}
                local text = options.Text or "Slider"
                local min = options.Min or 0
                local max = options.Max or 100
                local default = options.Default or min
                local rounding = options.Rounding or 0
                local callback = options.Callback or function() end
                
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Size = UDim2.new(1, 0, 0, 38)
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Parent = ContentArea
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.6, 0, 0, 16)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = Library.Theme.Text
                label.Font = Library.Theme.Font
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = sliderFrame
                
                local valLabel = Instance.new("TextLabel")
                valLabel.Position = UDim2.new(0.6, 0, 0, 0)
                valLabel.Size = UDim2.new(0.4, 0, 0, 16)
                valLabel.BackgroundTransparency = 1
                valLabel.Text = "[" .. tostring(default) .. "]"
                valLabel.TextColor3 = Library.Theme.Accent
                valLabel.Font = Library.Theme.Font
                valLabel.TextSize = 12
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.Parent = sliderFrame
                RegisterAccent(valLabel, "TextColor3")
                
                local Track = Instance.new("TextButton")
                Track.Position = UDim2.new(0, 0, 0, 22)
                Track.Size = UDim2.new(1, 0, 0, 5)
                Track.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                Track.Text = ""
                Track.BorderSizePixel = 0
                Track.Parent = sliderFrame
                
                local trCorner = Instance.new("UICorner")
                trCorner.CornerRadius = UDim.new(1, 0)
                trCorner.Parent = Track
                
                local trStroke = Instance.new("UIStroke")
                trStroke.Color = Library.Theme.Border
                trStroke.Thickness = 1
                trStroke.Parent = Track
                
                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new(0, 0, 1, 0)
                Fill.BackgroundColor3 = Library.Theme.Accent
                Fill.BorderSizePixel = 0
                Fill.Parent = Track
                RegisterAccent(Fill, "BackgroundColor3")
                
                local fCorner = Instance.new("UICorner")
                fCorner.CornerRadius = UDim.new(1, 0)
                fCorner.Parent = Fill
                
                -- Small circular thumb handle
                local Thumb = Instance.new("Frame")
                Thumb.Size = UDim2.new(0, 8, 0, 8)
                Thumb.Position = UDim2.new(1, -4, 0.5, -4)
                Thumb.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
                Thumb.BorderSizePixel = 0
                Thumb.Parent = Fill
                
                local thumbCorner = Instance.new("UICorner")
                thumbCorner.CornerRadius = UDim.new(1, 0)
                thumbCorner.Parent = Thumb
                
                local thumbStroke = Instance.new("UIStroke")
                thumbStroke.Color = Library.Theme.Border
                thumbStroke.Thickness = 1
                thumbStroke.Parent = Thumb
                
                Track.MouseEnter:Connect(function()
                    Tween(Thumb, 0.1, {Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -5, 0.5, -5)})
                    Tween(trStroke, 0.1, {Color = Library.Theme.Accent})
                end)
                Track.MouseLeave:Connect(function()
                    Tween(Thumb, 0.1, {Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(1, -4, 0.5, -4)})
                    Tween(trStroke, 0.1, {Color = Library.Theme.Border})
                end)
                
                local currentValue = default
                
                local function SetValue(val, skipCallback)
                    currentValue = math.clamp(val, min, max)
                    local scale = (currentValue - min) / (max - min)
                    Fill.Size = UDim2.new(scale, 0, 1, 0)
                    
                    local factor = 10 ^ rounding
                    currentValue = math.round(currentValue * factor) / factor
                    valLabel.Text = "[" .. tostring(currentValue) .. "]"
                    Library.Options[id] = { Value = currentValue }
                    
                    if not skipCallback then
                        pcall(callback, currentValue)
                    end
                end
                
                local dragging = false
                
                local function Update(input)
                    local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local newVal = min + (max - min) * pct
                    SetValue(newVal)
                end
                
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        Update(input)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Update(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                SetValue(default, true)
                
                local Slider = {
                    SetValue = function(_, v) SetValue(v) end
                }
                return Slider
            end
            
            -- [[ SEARCHABLE DROPDOWN COMPONENT ]] --
            function Groupbox:AddDropdown(id, options)
                options = options or {}
                local text = options.Text or "Dropdown"
                local values = options.Values or {}
                local default = options.Default
                local multi = options.Multi or false
                local callback = options.Callback or function() end
                
                local dropFrame = Instance.new("Frame")
                dropFrame.Size = UDim2.new(1, 0, 0, 46)
                dropFrame.BackgroundTransparency = 1
                dropFrame.Parent = ContentArea
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 0, 16)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = Library.Theme.Text
                label.Font = Library.Theme.Font
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = dropFrame
                
                local TriggerButton = Instance.new("TextButton")
                TriggerButton.Position = UDim2.new(0, 0, 0, 20)
                TriggerButton.Size = UDim2.new(1, 0, 0, 24)
                TriggerButton.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                TriggerButton.Text = "  Select Option"
                TriggerButton.TextColor3 = Library.Theme.TextMuted
                TriggerButton.Font = Library.Theme.Font
                TriggerButton.TextSize = 12
                TriggerButton.TextXAlignment = Enum.TextXAlignment.Left
                TriggerButton.Parent = dropFrame
                
                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 2)
                tbCorner.Parent = TriggerButton
                
                local tbStroke = Instance.new("UIStroke")
                tbStroke.Color = Library.Theme.Border
                tbStroke.Thickness = 1
                tbStroke.Parent = TriggerButton
                
                TriggerButton.MouseEnter:Connect(function()
                    Tween(tbStroke, 0.1, {Color = Library.Theme.Accent})
                end)
                TriggerButton.MouseLeave:Connect(function()
                    Tween(tbStroke, 0.1, {Color = Library.Theme.Border})
                end)
                
                local Arrow = Instance.new("TextLabel")
                Arrow.Position = UDim2.new(1, -25, 0, 0)
                Arrow.Size = UDim2.new(0, 20, 1, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.Text = "▼"
                Arrow.TextColor3 = Library.Theme.TextMuted
                Arrow.Font = Library.Theme.Font
                Arrow.TextSize = 10
                Arrow.Parent = TriggerButton
                
                local Selection = {}
                if multi then
                    Selection = {}
                    if type(default) == "table" then
                        for _, v in ipairs(default) do Selection[v] = true end
                    elseif default then
                        Selection[default] = true
                    end
                else
                    if type(default) == "number" then
                        Selection = values[default]
                    else
                        Selection = default or values[1]
                    end
                end
                
                local function UpdateDisplay()
                    if multi then
                        local active = {}
                        for k, v in pairs(Selection) do if v then table.insert(active, k) end end
                        if #active == 0 then
                            TriggerButton.Text = "  None"
                        else
                            table.sort(active)
                            TriggerButton.Text = "  " .. table.concat(active, ", ")
                        end
                        Library.Options[id] = { Value = Selection }
                    else
                        TriggerButton.Text = "  " .. tostring(Selection or "None")
                        Library.Options[id] = { Value = Selection }
                    end
                end
                
                local function SelectValue(val)
                    if multi then
                        Selection[val] = not Selection[val]
                        UpdateDisplay()
                        pcall(callback, Selection)
                    else
                        Selection = val
                        UpdateDisplay()
                        CloseAllPopups()
                        pcall(callback, val)
                    end
                end
                
                TriggerButton.MouseButton1Click:Connect(function()
                    CloseAllPopups()
                    Arrow.Text = "▲"
                    
                    local popupHeight = math.min(#values * 26 + 40, 170)
                    
                    local DropdownPopup = Instance.new("Frame")
                    DropdownPopup.Size = UDim2.new(0, TriggerButton.AbsoluteSize.X, 0, popupHeight)
                    DropdownPopup.Position = UDim2.new(0, TriggerButton.AbsolutePosition.X, 0, TriggerButton.AbsolutePosition.Y + 28)
                    DropdownPopup.BackgroundColor3 = Library.Theme.Groupbox
                    DropdownPopup.BorderSizePixel = 0
                    DropdownPopup.Parent = Overlay
                    
                    DropdownPopup.Destroying:Connect(function()
                        Arrow.Text = "▼"
                    end)
                    
                    local dpCorner = Instance.new("UICorner")
                    dpCorner.CornerRadius = UDim.new(0, 2)
                    dpCorner.Parent = DropdownPopup
                    
                    local dpStroke = Instance.new("UIStroke")
                    dpStroke.Color = Library.Theme.Border
                    dpStroke.Thickness = 1
                    dpStroke.Parent = DropdownPopup
                    
                    local SearchBox = Instance.new("TextBox")
                    SearchBox.Size = UDim2.new(0.9, 0, 0, 22)
                    SearchBox.Position = UDim2.new(0.05, 0, 0, 6)
                    SearchBox.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                    SearchBox.PlaceholderText = "Search..."
                    SearchBox.PlaceholderColor3 = Library.Theme.TextMuted
                    SearchBox.TextColor3 = Library.Theme.Text
                    SearchBox.Font = Library.Theme.Font
                    SearchBox.TextSize = 11
                    SearchBox.Parent = DropdownPopup
                    
                    local sCorner = Instance.new("UICorner")
                    sCorner.CornerRadius = UDim.new(0, 2)
                    sCorner.Parent = SearchBox
                    
                    local sStroke = Instance.new("UIStroke")
                    sStroke.Color = Library.Theme.Border
                    sStroke.Thickness = 1
                    sStroke.Parent = SearchBox
                    
                    local sPad = Instance.new("UIPadding")
                    sPad.PaddingLeft = UDim.new(0, 6)
                    sPad.Parent = SearchBox
                    
                    local ListFrame = Instance.new("ScrollingFrame")
                    ListFrame.Size = UDim2.new(1, 0, 1, -34)
                    ListFrame.Position = UDim2.new(0, 0, 0, 32)
                    ListFrame.BackgroundTransparency = 1
                    ListFrame.BorderSizePixel = 0
                    ListFrame.CanvasSize = UDim2.new(0, 0, 0, #values * 26 + 6)
                    ListFrame.ScrollBarThickness = 3
                    ListFrame.ScrollBarImageColor3 = Library.Theme.Border
                    ListFrame.Parent = DropdownPopup
                    
                    local lfLayout = Instance.new("UIListLayout")
                    lfLayout.Padding = UDim.new(0, 2)
                    lfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    lfLayout.Parent = ListFrame
                    
                    local buttons = {}
                    
                    for _, val in ipairs(values) do
                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(0.95, 0, 0, 24)
                        btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                        btn.BorderSizePixel = 0
                        btn.Font = Library.Theme.Font
                        btn.TextSize = 12
                        btn.Parent = ListFrame
                        
                        local bCorner = Instance.new("UICorner")
                        bCorner.CornerRadius = UDim.new(0, 2)
                        bCorner.Parent = btn
                        
                        local bStr = Instance.new("UIStroke")
                        bStr.Color = Library.Theme.Border
                        bStr.Thickness = 0.8
                        bStr.Parent = btn
                        
                        local function Highlight()
                            local active = false
                            if multi then active = Selection[val] else active = (Selection == val) end
                            if active then
                                btn.TextColor3 = Library.Theme.Accent
                                btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
                                bStr.Color = Library.Theme.Accent
                            else
                                btn.TextColor3 = Library.Theme.TextMuted
                                btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                                bStr.Color = Library.Theme.Border
                            end
                        end
                        
                        btn.Text = "  " .. tostring(val)
                        btn.TextXAlignment = Enum.TextXAlignment.Left
                        Highlight()
                        
                        btn.MouseEnter:Connect(function()
                            if not (multi and Selection[val] or not multi and Selection == val) then
                                Tween(btn, 0.1, {TextColor3 = Library.Theme.Text})
                            end
                        end)
                        btn.MouseLeave:Connect(function()
                            Highlight()
                        end)
                        
                        btn.MouseButton1Click:Connect(function()
                            SelectValue(val)
                            Highlight()
                        end)
                        
                        buttons[val] = btn
                    end
                    
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local query = string.lower(SearchBox.Text)
                        local visibleCount = 0
                        for val, btn in pairs(buttons) do
                            local match = string.find(string.lower(tostring(val)), query) ~= nil
                            btn.Visible = match
                            if match then
                                visibleCount = visibleCount + 1
                            end
                        end
                        ListFrame.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 26 + 6)
                    end)
                end)
                
                UpdateDisplay()
                
                local Dropdown = {
                    SetValue = function(_, v)
                        if multi then
                            Selection = {}
                            if type(v) == "table" then
                                for _, item in ipairs(v) do Selection[item] = true end
                            else
                                Selection[v] = true
                            end
                        else
                            Selection = v
                        end
                        UpdateDisplay()
                    end,
                    SetValues = function(_, newVals)
                        values = newVals or {}
                        if multi then Selection = {} else Selection = values[1] end
                        UpdateDisplay()
                    end
                }
                return Dropdown
            end
            
            -- [[ INPUT COMPONENT ]] --
            function Groupbox:AddInput(id, options)
                options = options or {}
                local text = options.Text or "Input"
                local default = options.Default or ""
                local placeholder = options.Placeholder or "Type here..."
                local callback = options.Callback or function() end
                
                local inputFrame = Instance.new("Frame")
                inputFrame.Size = UDim2.new(1, 0, 0, 46)
                inputFrame.BackgroundTransparency = 1
                inputFrame.Parent = ContentArea
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 0, 16)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = Library.Theme.Text
                label.Font = Library.Theme.Font
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = inputFrame
                
                local box = Instance.new("TextBox")
                box.Position = UDim2.new(0, 0, 0, 20)
                box.Size = UDim2.new(1, 0, 0, 24)
                box.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                box.Text = default
                box.PlaceholderText = placeholder
                box.TextColor3 = Library.Theme.Text
                box.PlaceholderColor3 = Library.Theme.TextMuted
                box.Font = Library.Theme.Font
                box.TextSize = 12
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = inputFrame
                
                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 2)
                bCorner.Parent = box
                
                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.Theme.Border
                bStroke.Thickness = 1
                bStroke.Parent = box
                
                local tPad = Instance.new("UIPadding")
                tPad.PaddingLeft = UDim.new(0, 8)
                tPad.Parent = box
                
                box.Focused:Connect(function()
                    Tween(bStroke, 0.1, {Color = Library.Theme.Accent})
                end)
                
                box.FocusLost:Connect(function(enterPressed)
                    Tween(bStroke, 0.1, {Color = Library.Theme.Border})
                    local val = box.Text
                    Library.Options[id] = { Value = val }
                    pcall(callback, val)
                end)
                
                Library.Options[id] = { Value = default }
                
                local Input = {
                    SetValue = function(_, val)
                        box.Text = val
                        Library.Options[id] = { Value = val }
                    end
                }
                return Input
            end
            
            -- [[ BUTTON COMPONENT ]] --
            function Groupbox:AddButton(text, callback)
                callback = callback or function() end
                
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 26)
                btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                btn.BorderSizePixel = 0
                btn.Text = text
                btn.TextColor3 = Library.Theme.Text
                btn.Font = Library.Theme.FontBold
                btn.TextSize = 12
                btn.Parent = ContentArea
                
                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 2)
                bCorner.Parent = btn
                
                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Color3.fromRGB(45, 45, 45)
                bStroke.Thickness = 1
                bStroke.Parent = btn
                
                btn.MouseEnter:Connect(function()
                    Tween(bStroke, 0.1, {Color = Library.Theme.Accent})
                end)
                btn.MouseLeave:Connect(function()
                    Tween(bStroke, 0.1, {Color = Color3.fromRGB(45, 45, 45)})
                end)
                
                btn.MouseButton1Click:Connect(function()
                    Tween(btn, 0.05, {Size = UDim2.new(0.98, 0, 0, 24)}).Completed:Connect(function()
                        Tween(btn, 0.05, {Size = UDim2.new(1, 0, 0, 26)})
                    end)
                    pcall(callback)
                end)
                
                return btn
            end
            
            -- [[ LABEL COMPONENT ]] --
            function Groupbox:AddLabel(text)
                local labelFrame = Instance.new("Frame")
                labelFrame.Size = UDim2.new(1, 0, 0, 20)
                labelFrame.BackgroundTransparency = 1
                labelFrame.Parent = ContentArea
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = Library.Theme.Text
                label.Font = Library.Theme.Font
                label.TextSize = 12
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = labelFrame
                
                local LabelObj = {
                    Text = text
                }
                
                function LabelObj:AddKeyPicker(kpId, kpOptions)
                    kpOptions = kpOptions or {}
                    local kpDefault = kpOptions.Default or "None"
                    local kpCallback = kpOptions.Callback or function() end
                    
                    local KeybindButton = Instance.new("TextButton")
                    KeybindButton.Position = UDim2.new(1, -45, 0.5, -9)
                    KeybindButton.Size = UDim2.new(0, 45, 0, 18)
                    KeybindButton.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                    KeybindButton.Text = "[" .. kpDefault .. "]"
                    KeybindButton.TextColor3 = Library.Theme.TextMuted
                    KeybindButton.Font = Library.Theme.Font
                    KeybindButton.TextSize = 11
                    KeybindButton.Parent = labelFrame
                    
                    local kbCorner = Instance.new("UICorner")
                    kbCorner.CornerRadius = UDim.new(0, 2)
                    kbCorner.Parent = KeybindButton
                    
                    local kbStroke = Instance.new("UIStroke")
                    kbStroke.Color = Library.Theme.Border
                    kbStroke.Thickness = 1
                    kbStroke.Parent = KeybindButton
                    
                    local currentKey = kpDefault
                    local binding = false
                    
                    local function SetBind(keyName)
                        if currentKey ~= "None" then
                            RemoveGlobalKeybind(currentKey, kpCallback)
                        end
                        currentKey = keyName
                        KeybindButton.Text = "[" .. keyName .. "]"
                        Library.Options[kpId] = { Value = keyName }
                        if keyName ~= "None" then
                            AddGlobalKeybind(keyName, kpCallback)
                        end
                    end
                    
                    KeybindButton.MouseButton1Click:Connect(function()
                        binding = true
                        KeybindButton.Text = "[...]"
                    end)
                    
                    UserInputService.InputBegan:Connect(function(input, processed)
                        if binding and not processed then
                            binding = false
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                local key = input.KeyCode.Name
                                if input.KeyCode == Enum.KeyCode.Escape then
                                    SetBind("None")
                                else
                                    SetBind(key)
                                end
                            else
                                SetBind("None")
                            end
                        end
                    end)
                    
                    SetBind(kpDefault)
                    return LabelObj
                end
                
                function LabelObj:AddColorPicker(cpId, cpOptions)
                    cpOptions = cpOptions or {}
                    local cpDefault = cpOptions.Default or Color3.new(1, 1, 1)
                    local cpCallback = cpOptions.Callback or function() end
                    
                    local RightControls = labelFrame:FindFirstChild("RightControls")
                    if not RightControls then
                        RightControls = Instance.new("Frame")
                        RightControls.Name = "RightControls"
                        RightControls.Size = UDim2.new(0.5, 0, 1, 0)
                        RightControls.Position = UDim2.new(0.5, 0, 0, 0)
                        RightControls.BackgroundTransparency = 1
                        RightControls.Parent = labelFrame
                        
                        local RightLayout = Instance.new("UIListLayout")
                        RightLayout.FillDirection = Enum.FillDirection.Horizontal
                        RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                        RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                        RightLayout.Padding = UDim.new(0, 6)
                        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        RightLayout.Parent = RightControls
                    end
                    
                    local ColorBox = Instance.new("TextButton")
                    ColorBox.Size = UDim2.new(0, 14, 0, 14)
                    ColorBox.BackgroundColor3 = cpDefault
                    ColorBox.Text = ""
                    ColorBox.LayoutOrder = #RightControls:GetChildren()
                    ColorBox.Parent = RightControls
                    
                    local cpCorner = Instance.new("UICorner")
                    cpCorner.CornerRadius = UDim.new(0, 2)
                    cpCorner.Parent = ColorBox
                    
                    local cpStroke = Instance.new("UIStroke")
                    cpStroke.Color = Library.Theme.Border
                    cpStroke.Thickness = 1
                    cpStroke.Parent = ColorBox
                    
                    local currentColor = cpDefault
                    Library.Options[cpId] = { Value = currentColor }
                    
                    ColorBox.MouseButton1Click:Connect(function()
                        CloseAllPopups()
                        
                        local PickerPopup = Instance.new("Frame")
                        PickerPopup.Size = UDim2.new(0, 170, 0, 180)
                        PickerPopup.BackgroundColor3 = Library.Theme.Groupbox
                        PickerPopup.Position = UDim2.new(0, ColorBox.AbsolutePosition.X - 180, 0, ColorBox.AbsolutePosition.Y)
                        PickerPopup.Parent = Overlay
                        
                        local popupCorner = Instance.new("UICorner")
                        popupCorner.CornerRadius = UDim.new(0, 3)
                        popupCorner.Parent = PickerPopup
                        
                        local popupStroke = Instance.new("UIStroke")
                        popupStroke.Color = Library.Theme.Border
                        popupStroke.Thickness = 1
                        popupStroke.Parent = PickerPopup
                        
                        local PresetsFrame = Instance.new("Frame")
                        PresetsFrame.Position = UDim2.new(0, 10, 0, 10)
                        PresetsFrame.Size = UDim2.new(1, -20, 0, 36)
                        PresetsFrame.BackgroundTransparency = 1
                        PresetsFrame.Parent = PickerPopup
                        
                        local PresetsLayout = Instance.new("UIGridLayout")
                        PresetsLayout.CellSize = UDim2.new(0, 14, 0, 14)
                        PresetsLayout.CellPadding = UDim2.new(0, 5, 0, 5)
                        PresetsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        PresetsLayout.Parent = PresetsFrame
                        
                        local list = Instance.new("Frame")
                        list.Size = UDim2.new(1, -20, 1, -56)
                        list.Position = UDim2.new(0, 10, 0, 50)
                        list.BackgroundTransparency = 1
                        list.Parent = PickerPopup
                        
                        local listLayout = Instance.new("UIListLayout")
                        listLayout.Padding = UDim.new(0, 6)
                        listLayout.Parent = list
                        
                        local r, g, b = math.round(currentColor.R * 255), math.round(currentColor.G * 255), math.round(currentColor.B * 255)
                        local sliders = {}
                        
                        local function Reevaluate()
                            local newColor = Color3.fromRGB(r, g, b)
                            currentColor = newColor
                            ColorBox.BackgroundColor3 = newColor
                            Library.Options[cpId] = { Value = newColor }
                            pcall(cpCallback, newColor)
                        end
                        
                        local function CreateRGBSlider(name, colorVal, sliderColor, changeCallback)
                            local sFrame = Instance.new("Frame")
                            sFrame.Size = UDim2.new(1, 0, 0, 22)
                            sFrame.BackgroundTransparency = 1
                            sFrame.Parent = list
                            
                            local sLabel = Instance.new("TextLabel")
                            sLabel.Size = UDim2.new(0.2, 0, 1, 0)
                            sLabel.BackgroundTransparency = 1
                            sLabel.Text = name
                            sLabel.TextColor3 = Library.Theme.TextMuted
                            sLabel.Font = Library.Theme.Font
                            sLabel.TextSize = 11
                            sLabel.Parent = sFrame
                            
                            local track = Instance.new("TextButton")
                            track.Size = UDim2.new(0.8, -5, 0, 6)
                            track.Position = UDim2.new(0.2, 5, 0.5, -3)
                            track.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                            track.BorderSizePixel = 0
                            track.Text = ""
                            track.Parent = sFrame
                            
                            local tStr = Instance.new("UIStroke")
                            tStr.Color = Library.Theme.Border
                            tStr.Thickness = 1
                            tStr.Parent = track
                            
                            local fill = Instance.new("Frame")
                            fill.Size = UDim2.new(colorVal / 255, 0, 1, 0)
                            fill.BackgroundColor3 = sliderColor
                            fill.BorderSizePixel = 0
                            fill.Parent = track
                            
                            local fCorner = Instance.new("UICorner")
                            fCorner.CornerRadius = UDim.new(1, 0)
                            fCorner.Parent = fill
                            
                            local trCorner = Instance.new("UICorner")
                            trCorner.CornerRadius = UDim.new(1, 0)
                            trCorner.Parent = track
                            
                            local function Update(input)
                                local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                                fill.Size = UDim2.new(pct, 0, 1, 0)
                                changeCallback(math.round(pct * 255))
                            end
                            
                            local dragging = false
                            track.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    dragging = true
                                    Update(input)
                                end
                            end)
                            UserInputService.InputChanged:Connect(function(input)
                                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                    Update(input)
                                end
                            end)
                            UserInputService.InputEnded:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    dragging = false
                                end
                            end)
                            
                            sliders[name] = {
                                Track = track,
                                Fill = fill,
                                UpdateValue = function(newVal)
                                    fill.Size = UDim2.new(newVal / 255, 0, 1, 0)
                                end
                            }
                        end
                        
                        CreateRGBSlider("R", r, Color3.fromRGB(255, 75, 75), function(val) r = val; Reevaluate() end)
                        CreateRGBSlider("G", g, Color3.fromRGB(0, 220, 140), function(val) g = val; Reevaluate() end)
                        CreateRGBSlider("B", b, Color3.fromRGB(85, 110, 250), function(val) b = val; Reevaluate() end)
                        
                        local presets = {
                            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
                            Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 255),
                            Color3.fromRGB(255, 128, 0), Color3.fromRGB(128, 0, 255), Color3.fromRGB(255, 255, 255),
                            Color3.fromRGB(128, 128, 128), Color3.fromRGB(30, 30, 30), Color3.fromRGB(0, 0, 0)
                        }
                        
                        for i, color in ipairs(presets) do
                            local pBtn = Instance.new("TextButton")
                            pBtn.BackgroundColor3 = color
                            pBtn.Text = ""
                            pBtn.Parent = PresetsFrame
                            
                            local pCorner = Instance.new("UICorner")
                            pCorner.CornerRadius = UDim.new(1, 0)
                            pCorner.Parent = pBtn
                            
                            local pStr = Instance.new("UIStroke")
                            pStr.Color = Color3.fromRGB(35, 35, 45)
                            pStr.Thickness = 1
                            pStr.Parent = pBtn
                            
                            pBtn.MouseButton1Click:Connect(function()
                                r = math.round(color.R * 255)
                                g = math.round(color.G * 255)
                                b = math.round(color.B * 255)
                                sliders["R"].UpdateValue(r)
                                sliders["G"].UpdateValue(g)
                                sliders["B"].UpdateValue(b)
                                Reevaluate()
                            end)
                        end
                    end)
                    
                    return LabelObj
                end
                
                return LabelObj
            end
            
            -- [[ DIVIDER COMPONENT ]] --
            function Groupbox:AddDivider()
                local div = Instance.new("Frame")
                div.Size = UDim2.new(1, 0, 0, 1)
                div.BackgroundColor3 = Library.Theme.Border
                div.BorderSizePixel = 0
                div.Parent = ContentArea
                return div
            end
            
            return Groupbox
        end
        
        return Window
    end

-- Unload handler
function Library:OnUnload(callback)
    table.insert(Library.OnUnloadCallbacks, callback)
end

function Library:Unload()
    if Library.Unloaded then return end
    Library.Unloaded = true
    
    for _, cb in ipairs(Library.OnUnloadCallbacks) do
        pcall(cb)
    end
    
    pcall(function()
        ScreenGui:Destroy()
    end)
    CloseAllPopups()
end

-- Theme & Save Manager Compatibility layers
Library.ThemeManager = {
    SetLibrary = function(_, lib) end,
    ApplyToTab = function(_, tab)
        local group = tab:AddLeftGroupbox("Theme Settings")
        
        group:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", {
            Default = Library.Theme.Accent,
            Callback = function(color)
                Library:UpdateTheme(color)
            end
        })
        
        -- High-end theme presets
        local presets = {
            ["Midnight Cyan"] = Color3.fromRGB(0, 180, 255),
            ["Electric Mint"] = Color3.fromRGB(0, 220, 140),
            ["Royal Blue"] = Color3.fromRGB(85, 110, 250),
            ["Crimson Red"] = Color3.fromRGB(255, 50, 70),
            ["Vibrant Orange"] = Color3.fromRGB(255, 135, 0),
            ["Orchid Purple"] = Color3.fromRGB(180, 90, 255)
        }
        
        group:AddDropdown("ThemePreset", {
            Text = "Quick Theme Presets",
            Values = {"Midnight Cyan", "Electric Mint", "Royal Blue", "Crimson Red", "Vibrant Orange", "Orchid Purple"},
            Default = "Midnight Cyan",
            Callback = function(val)
                local color = presets[val]
                if color then
                    Library:UpdateTheme(color)
                end
            end
        })
        
        group:AddButton("Reset Theme", function()
            Library:UpdateTheme(Color3.fromRGB(0, 180, 255))
            Library:Notify("Theme reset to Midnight Cyan!")
        end)
    end
}

Library.SaveManager = {
    Folder = "DesyncObsidian",
    SetLibrary = function(_, lib) end,
    IgnoreThemeSettings = function() end,
    SetFolder = function(_, name) Library.SaveManager.Folder = name end,
    BuildConfigSection = function(_, tab)
        local group = tab:AddRightGroupbox("Configuration Manager")
        local configName = "default"
        
        group:AddInput("SaveCfgName", {
            Text = "Config File Name",
            Default = "default",
            Placeholder = "config_name",
            Callback = function(val) configName = val end
        })
        
        local function GetFilePath()
            return Library.SaveManager.Folder .. "/" .. configName .. ".json"
        end
        
        group:AddButton("Save Config", function()
            local data = {}
            for k, opt in pairs(Library.Options) do
                local val = opt.Value
                if type(val) == "userdata" and val.R then
                    data[k] = {R = val.R, G = val.G, B = val.B, Type = "Color3"}
                else
                    data[k] = val
                end
            end
            for k, tog in pairs(Library.Toggles) do
                data[k] = tog.Value
            end
            
            local json
            local success, _ = pcall(function()
                json = game:GetService("HttpService"):JSONEncode(data)
            end)
            if success and json then
                pcall(function()
                    makefolder(Library.SaveManager.Folder)
                end)
                local fileSuccess, err = pcall(function()
                    writefile(GetFilePath(), json)
                end)
                if fileSuccess then
                    Library:Notify("Config saved successfully to " .. configName .. ".json!")
                else
                    Library:Notify("Failed to save config: " .. tostring(err))
                end
            else
                Library:Notify("JSON encoding failed!")
            end
        end)
        
        group:AddButton("Load Config", function()
            local path = GetFilePath()
            if isfile(path) then
                local content = readfile(path)
                local data
                local success = pcall(function()
                    data = game:GetService("HttpService"):JSONDecode(content)
                end)
                if success and data then
                    for k, val in pairs(data) do
                        if type(val) == "table" and val.Type == "Color3" then
                            local c = Color3.new(val.R, val.G, val.B)
                            if Library.Options[k] then Library.Options[k].Value = c end
                        else
                            if Library.Toggles[k] then Library.Toggles[k].Value = val end
                            if Library.Options[k] then Library.Options[k].Value = val end
                        end
                    end
                    Library:Notify("Config " .. configName .. ".json loaded!")
                else
                    Library:Notify("Failed to parse config file!")
                end
            else
                Library:Notify("Config file not found!")
            end
        end)
    end
}

return Library
