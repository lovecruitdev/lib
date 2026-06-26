-- [[ PREMIUM OFFLINE ROBLOX UI LIBRARY (TOP-TIER EDITION) ]] --
-- Fully offline, zero-dependency, ultra-sleek glassmorphic theme.
-- Features sliding tab indicators, window minimization, searchable dropdowns, preset color pickers, stats watermark, and dynamic theme switching.

local Library = {
    Options = {},
    Toggles = {},
    Registry = {},
    RegistryMap = {},
    Unloaded = false,
    OnUnloadCallbacks = {},
    AccentRegistry = {},
    Theme = {
        Background = Color3.fromRGB(12, 12, 18),
        Groupbox = Color3.fromRGB(18, 18, 26),
        Accent = Color3.fromRGB(130, 90, 255),
        AccentGradient = Color3.fromRGB(180, 70, 250),
        Text = Color3.fromRGB(245, 245, 250),
        TextMuted = Color3.fromRGB(140, 140, 160),
        Border = Color3.fromRGB(30, 30, 42),
        BorderGlow = Color3.fromRGB(120, 85, 255),
        Font = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBold
    }
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

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
    local tweenInfo = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, tweenInfo, properties)
    t:Play()
    return t
end

-- Dynamic Accent Color Registry
local function RegisterAccent(instance, property, isGradient)
    table.insert(Library.AccentRegistry, {
        Instance = instance,
        Property = property,
        IsGradient = isGradient or false
    })
    return instance
end

function Library:UpdateTheme(newColor)
    Library.Theme.Accent = newColor
    local h, s, v = newColor:ToHSV()
    local newGradient = Color3.fromHSV((h + 0.08) % 1, s, v)
    Library.Theme.AccentGradient = newGradient
    
    for _, item in ipairs(Library.AccentRegistry) do
        pcall(function()
            if item.Instance and item.Instance.Parent then
                if item.IsGradient then
                    if item.Instance:IsA("UIGradient") then
                        item.Instance.Color = ColorSequence.new(newColor, newGradient)
                    end
                else
                    local isToggleTrack = item.Instance:GetAttribute("IsToggleTrack")
                    if isToggleTrack then
                        local isToggleActive = item.Instance:GetAttribute("Active")
                        if isToggleActive then
                            Tween(item.Instance, 0.2, {[item.Property] = newColor})
                        end
                    else
                        Tween(item.Instance, 0.2, {[item.Property] = newColor})
                    end
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

-- Overlay for floating menus (dropdowns, colorpickers)
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

-- Notification area
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "Notifications"
NotificationContainer.Position = UDim2.new(1, -280, 1, -20)
NotificationContainer.Size = UDim2.new(0, 260, 0, 10)
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
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Library.Theme.Border
    stroke.Thickness = 1
    stroke.Parent = card
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -6)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Library.Theme.Text
    label.Text = text
    label.TextWrapped = true
    label.Font = Library.Theme.Font
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = Library.Theme.Accent
    progressBar.BorderSizePixel = 0
    progressBar.Parent = card
    
    local progressGrad = Instance.new("UIGradient")
    progressGrad.Color = ColorSequence.new(Library.Theme.Accent, Library.Theme.AccentGradient)
    progressGrad.Parent = progressBar
    
    card.Size = UDim2.new(1, 100, 0, 50)
    card.Position = UDim2.new(0, 100, 0, 0)
    card.BackgroundTransparency = 1
    
    Tween(card, 0.3, {Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 0.1})
    Tween(progressBar, duration, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)
    
    task.delay(duration, function()
        local t = Tween(card, 0.3, {Size = UDim2.new(1, 100, 0, 0), BackgroundTransparency = 1})
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

-- Sleek Performance Watermark
local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Name = "Watermark"
WatermarkFrame.Size = UDim2.new(0, 280, 0, 24)
WatermarkFrame.Position = UDim2.new(1, -290, 0, 10)
WatermarkFrame.BackgroundColor3 = Library.Theme.Background
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.Visible = false
WatermarkFrame.Parent = ScreenGui

local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 6)
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
wmLabel.Text = "Antigravity Premium | FPS: -- | Ping: --"
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
        wmLabel.Text = string.format("Antigravity | %s | FPS: %d | Ping: %dms", timeStr, fpsCount, ping)
    end
end)

function Library:SetWatermarkVisibility(visible)
    WatermarkFrame.Visible = visible
end

-- MainWindow construction
function Library:CreateWindow(config)
    config = config or {}
    local titleText = config.Title or "Premium Script"
    
    local WindowFrame = Instance.new("Frame")
    WindowFrame.Size = UDim2.new(0, 560, 0, 420)
    WindowFrame.Position = UDim2.new(0.5, -280, 0.5, -210)
    WindowFrame.BackgroundColor3 = Library.Theme.Background
    WindowFrame.BorderSizePixel = 0
    WindowFrame.ClipsDescendants = true
    WindowFrame.Parent = TrackInstance(ScreenGui)
    
    local wCorner = Instance.new("UICorner")
    wCorner.CornerRadius = UDim.new(0, 10)
    wCorner.Parent = WindowFrame
    
    local wStroke = Instance.new("UIStroke")
    wStroke.Color = Library.Theme.Border
    wStroke.Thickness = 1.2
    wStroke.Parent = WindowFrame
    
    local wGrad = Instance.new("UIGradient")
    wGrad.Color = ColorSequence.new(Library.Theme.Background, Color3.fromRGB(24, 24, 34))
    wGrad.Rotation = 45
    wGrad.Parent = WindowFrame
    
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Library.Theme.Border),
        ColorSequenceKeypoint.new(0.5, Library.Theme.BorderGlow),
        ColorSequenceKeypoint.new(1, Library.Theme.Border)
    })
    grad.Parent = wStroke
    
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = WindowFrame
    
    MakeDraggable(TopBar, WindowFrame)
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = titleText
    TitleLabel.TextColor3 = Library.Theme.Text
    TitleLabel.Font = Library.Theme.FontBold
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar
    
    local ControlFrame = Instance.new("Frame")
    ControlFrame.Position = UDim2.new(1, -70, 0, 0)
    ControlFrame.Size = UDim2.new(0, 60, 1, 0)
    ControlFrame.BackgroundTransparency = 1
    ControlFrame.Parent = TopBar
    
    local ControlLayout = Instance.new("UIListLayout")
    ControlLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlLayout.Padding = UDim.new(0, 8)
    ControlLayout.Parent = ControlFrame
    
    local MinButton = Instance.new("TextButton")
    MinButton.Size = UDim2.new(0, 20, 0, 20)
    MinButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    MinButton.Text = "−"
    MinButton.TextColor3 = Library.Theme.TextMuted
    MinButton.Font = Library.Theme.FontBold
    MinButton.TextSize = 12
    MinButton.Parent = ControlFrame
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 5)
    minCorner.Parent = MinButton
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 20, 0, 20)
    CloseButton.BackgroundColor3 = Color3.fromRGB(45, 25, 25)
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    CloseButton.Font = Library.Theme.FontBold
    CloseButton.TextSize = 14
    CloseButton.Parent = ControlFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = CloseButton
    
    local Minimized = false
    MinButton.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        CloseAllPopups()
        if Minimized then
            MinButton.Text = "+"
            Tween(WindowFrame, 0.25, {Size = UDim2.new(0, 560, 0, 40)})
        else
            MinButton.Text = "−"
            Tween(WindowFrame, 0.25, {Size = UDim2.new(0, 560, 0, 420)})
        end
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Library:Unload()
    end)
    
    local Sep = Instance.new("Frame")
    Sep.Position = UDim2.new(0, 0, 1, -1)
    Sep.Size = UDim2.new(1, 0, 0, 1)
    Sep.BackgroundColor3 = Library.Theme.Border
    Sep.BorderSizePixel = 0
    Sep.Parent = TopBar
    
    local Sidebar = Instance.new("Frame")
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.Size = UDim2.new(0, 140, 1, -40)
    Sidebar.BackgroundColor3 = Library.Theme.Background
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = WindowFrame
    
    local SideSep = Instance.new("Frame")
    SideSep.Position = UDim2.new(1, -1, 0, 0)
    SideSep.Size = UDim2.new(0, 1, 1, 0)
    SideSep.BackgroundColor3 = Library.Theme.Border
    SideSep.BorderSizePixel = 0
    SideSep.Parent = Sidebar
    
    -- Absolute positioned Tab Indicator
    local TabIndicator = Instance.new("Frame")
    TabIndicator.Size = UDim2.new(0.9, 0, 0, 32)
    TabIndicator.Position = UDim2.new(0.05, 0, 0, 10)
    TabIndicator.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    TabIndicator.BorderSizePixel = 0
    TabIndicator.ZIndex = 1
    TabIndicator.Parent = Sidebar
    
    local tiCorner = Instance.new("UICorner")
    tiCorner.CornerRadius = UDim.new(0, 6)
    tiCorner.Parent = TabIndicator
    
    local tiStroke = Instance.new("UIStroke")
    tiStroke.Color = Library.Theme.Accent
    tiStroke.Thickness = 1
    tiStroke.Parent = TabIndicator
    RegisterAccent(tiStroke, "Color")
    
    local tiGrad = Instance.new("UIGradient")
    tiGrad.Color = ColorSequence.new(Library.Theme.Accent, Library.Theme.AccentGradient)
    tiGrad.Parent = tiStroke
    RegisterAccent(tiGrad, "Color", true)
    
    -- Sub-container for list layout to isolate Tab Buttons from TabIndicator
    local ButtonHolder = Instance.new("Frame")
    ButtonHolder.Size = UDim2.new(1, 0, 1, 0)
    ButtonHolder.BackgroundTransparency = 1
    ButtonHolder.Parent = Sidebar
    
    local SideLayout = Instance.new("UIListLayout")
    SideLayout.Padding = UDim.new(0, 4)
    SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SideLayout.Parent = ButtonHolder
    
    local SidePadding = Instance.new("UIPadding")
    SidePadding.PaddingTop = UDim.new(0, 10)
    SidePadding.Parent = ButtonHolder
    
    local Container = Instance.new("Frame")
    Container.Position = UDim2.new(0, 140, 0, 40)
    Container.Size = UDim2.new(1, -140, 1, -40)
    Container.BackgroundTransparency = 1
    Container.Parent = WindowFrame
    
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
    
    function Window:AddTab(tabName, icon)
        local tabIndex = #Window.Tabs + 1
        
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0.9, 0, 0, 32)
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Text = "  " .. (icon and "• " or "") .. tabName
        TabButton.TextColor3 = Library.Theme.TextMuted
        TabButton.Font = Library.Theme.Font
        TabButton.TextSize = 13
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.ZIndex = 2
        TabButton.Parent = ButtonHolder
        
        local TabPanel = Instance.new("Frame")
        TabPanel.Size = UDim2.new(1, 0, 1, 0)
        TabPanel.BackgroundTransparency = 1
        TabPanel.Visible = false
        TabPanel.Parent = Container
        
        local LeftScroll = Instance.new("ScrollingFrame")
        LeftScroll.Size = UDim2.new(0.5, -15, 1, -20)
        LeftScroll.Position = UDim2.new(0, 10, 0, 10)
        LeftScroll.BackgroundTransparency = 1
        LeftScroll.BorderSizePixel = 0
        LeftScroll.ScrollBarThickness = 3
        LeftScroll.ScrollBarImageColor3 = Library.Theme.Border
        LeftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftScroll.Parent = TabPanel
        
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
        RightScroll.Parent = TabPanel
        
        local RightLayout = Instance.new("UIListLayout")
        RightLayout.Padding = UDim.new(0, 10)
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Parent = RightScroll
        
        RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            RightScroll.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y + 20)
        end)
        
        local Tab = {}
        
        local function Activate()
            if Window.ActiveTab then
                Window.ActiveTab.Button.TextColor3 = Library.Theme.TextMuted
                Window.ActiveTab.Panel.Visible = false
            end
            Window.ActiveTab = Tab
            TabButton.TextColor3 = Library.Theme.Text
            TabPanel.Visible = true
            CloseAllPopups()
            
            Tween(TabIndicator, 0.2, {
                Position = UDim2.new(0.05, 0, 0, 10 + (tabIndex - 1) * 36)
            })
        end
        
        TabButton.MouseButton1Click:Connect(Activate)
        
        task.defer(function()
            if not Window.ActiveTab then Activate() end
        end)
        
        Tab.Button = TabButton
        Tab.Panel = TabPanel
        
        local function CreateGroupbox(title, parentScroll)
            local gb = Instance.new("Frame")
            gb.Size = UDim2.new(1, -6, 0, 40)
            gb.BackgroundColor3 = Library.Theme.Groupbox
            gb.BorderSizePixel = 0
            gb.Parent = parentScroll
            
            local gbCorner = Instance.new("UICorner")
            gbCorner.CornerRadius = UDim.new(0, 8)
            gbCorner.Parent = gb
            
            local gbStroke = Instance.new("UIStroke")
            gbStroke.Color = Library.Theme.Border
            gbStroke.Thickness = 1
            gbStroke.Parent = gb
            
            local gbHeader = Instance.new("TextLabel")
            gbHeader.Position = UDim2.new(0, 10, 0, 6)
            gbHeader.Size = UDim2.new(1, -20, 0, 16)
            gbHeader.BackgroundTransparency = 1
            gbHeader.Text = title:upper()
            gbHeader.TextColor3 = Library.Theme.Accent
            gbHeader.Font = Library.Theme.FontBold
            gbHeader.TextSize = 10
            gbHeader.TextXAlignment = Enum.TextXAlignment.Left
            gbHeader.Parent = gb
            RegisterAccent(gbHeader, "TextColor3")
            
            local ContentArea = Instance.new("Frame")
            ContentArea.Position = UDim2.new(0, 10, 0, 26)
            ContentArea.Size = UDim2.new(1, -20, 1, -34)
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
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.6, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = Library.Theme.Text
                label.Font = Library.Theme.Font
                label.TextSize = 13
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = toggleFrame
                
                local RightControls = Instance.new("Frame")
                RightControls.Size = UDim2.new(0.4, 0, 1, 0)
                RightControls.Position = UDim2.new(0.6, 0, 0, 0)
                RightControls.BackgroundTransparency = 1
                RightControls.Parent = toggleFrame
                
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                RightLayout.Padding = UDim.new(0, 6)
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightControls
                
                local SwitchTrack = Instance.new("Frame")
                SwitchTrack.Size = UDim2.new(0, 32, 0, 16)
                SwitchTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                SwitchTrack.BorderSizePixel = 0
                SwitchTrack.LayoutOrder = 100
                SwitchTrack.Parent = RightControls
                SwitchTrack:SetAttribute("IsToggleTrack", true)
                RegisterAccent(SwitchTrack, "BackgroundColor3")
                
                local sCorner = Instance.new("UICorner")
                sCorner.CornerRadius = UDim.new(1, 0)
                sCorner.Parent = SwitchTrack
                
                local SwitchThumb = Instance.new("Frame")
                SwitchThumb.Size = UDim2.new(0, 12, 0, 12)
                SwitchThumb.Position = UDim2.new(0, 2, 0.5, -6)
                SwitchThumb.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
                SwitchThumb.BorderSizePixel = 0
                SwitchThumb.Parent = SwitchTrack
                
                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(1, 0)
                tCorner.Parent = SwitchThumb
                
                local ToggleState = default
                
                local function SetState(val, skipCallback)
                    ToggleState = val
                    Library.Toggles[id] = { Value = val }
                    SwitchTrack:SetAttribute("Active", val)
                    
                    if not skipCallback then
                        pcall(callback, val)
                    end
                    
                    if ToggleState then
                        Tween(SwitchTrack, 0.15, {BackgroundColor3 = Library.Theme.Accent})
                        Tween(SwitchThumb, 0.15, {Position = UDim2.new(1, -14, 0.5, -6)})
                    else
                        Tween(SwitchTrack, 0.15, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)})
                        Tween(SwitchThumb, 0.15, {Position = UDim2.new(0, 2, 0.5, -6)})
                    end
                end
                
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
                    KeybindButton.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
                    KeybindButton.Text = "[" .. kpDefault .. "]"
                    KeybindButton.TextColor3 = Library.Theme.TextMuted
                    KeybindButton.Font = Library.Theme.Font
                    KeybindButton.TextSize = 11
                    KeybindButton.LayoutOrder = 50
                    KeybindButton.Parent = RightControls
                    
                    local kbCorner = Instance.new("UICorner")
                    kbCorner.CornerRadius = UDim.new(0, 4)
                    kbCorner.Parent = KeybindButton
                    
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
                    ColorBox.Size = UDim2.new(0, 18, 0, 18)
                    ColorBox.BackgroundColor3 = cpDefault
                    ColorBox.Text = ""
                    ColorBox.LayoutOrder = 10
                    ColorBox.Parent = RightControls
                    
                    local cpCorner = Instance.new("UICorner")
                    cpCorner.CornerRadius = UDim.new(0, 4)
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
                        popupCorner.CornerRadius = UDim.new(0, 6)
                        popupCorner.Parent = PickerPopup
                        
                        local popupStroke = Instance.new("UIStroke")
                        popupStroke.Color = Library.Theme.BorderGlow
                        popupStroke.Thickness = 1
                        popupStroke.Parent = PickerPopup
                        
                        local PresetsFrame = Instance.new("Frame")
                        PresetsFrame.Position = UDim2.new(0, 10, 0, 10)
                        PresetsFrame.Size = UDim2.new(1, -20, 0, 36)
                        PresetsFrame.BackgroundTransparency = 1
                        PresetsFrame.Parent = PickerPopup
                        
                        local PresetsLayout = Instance.new("UIGridLayout")
                        PresetsLayout.CellSize = UDim2.new(0, 14, 0, 14)
                        PresetsLayout.CellSpacing = UDim2.new(0, 5, 0, 5)
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
                        
                        local function CreateRGBSlider(name, colorVal, changeCallback)
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
                            track.Size = UDim2.new(0.8, -5, 0, 8)
                            track.Position = UDim2.new(0.2, 5, 0.5, -4)
                            track.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                            track.BorderSizePixel = 0
                            track.Text = ""
                            track.Parent = sFrame
                            
                            local fill = Instance.new("Frame")
                            fill.Size = UDim2.new(colorVal / 255, 0, 1, 0)
                            fill.BackgroundColor3 = Library.Theme.Accent
                            fill.BorderSizePixel = 0
                            fill.Parent = track
                            
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
                        
                        CreateRGBSlider("R", r, function(val) r = val; Reevaluate() end)
                        CreateRGBSlider("G", g, function(val) g = val; Reevaluate() end)
                        CreateRGBSlider("B", b, function(val) b = val; Reevaluate() end)
                        
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
                            pCorner.CornerRadius = UDim.new(0, 3)
                            pCorner.Parent = pBtn
                            
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
                label.TextSize = 13
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = sliderFrame
                
                local valLabel = Instance.new("TextLabel")
                valLabel.Position = UDim2.new(0.6, 0, 0, 0)
                valLabel.Size = UDim2.new(0.4, 0, 0, 16)
                valLabel.BackgroundTransparency = 1
                valLabel.Text = tostring(default)
                valLabel.TextColor3 = Library.Theme.TextMuted
                valLabel.Font = Library.Theme.Font
                valLabel.TextSize = 12
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.Parent = sliderFrame
                
                local Track = Instance.new("TextButton")
                Track.Position = UDim2.new(0, 0, 0, 22)
                Track.Size = UDim2.new(1, 0, 0, 8)
                Track.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                Track.Text = ""
                Track.BorderSizePixel = 0
                Track.Parent = sliderFrame
                
                local tCorner = Instance.new("UICorner")
                tCorner.CornerRadius = UDim.new(1, 0)
                tCorner.Parent = Track
                
                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new(0, 0, 1, 0)
                Fill.BackgroundColor3 = Library.Theme.Accent
                Fill.BorderSizePixel = 0
                Fill.Parent = Track
                RegisterAccent(Fill, "BackgroundColor3")
                
                local fCorner = Instance.new("UICorner")
                fCorner.CornerRadius = UDim.new(1, 0)
                fCorner.Parent = Fill
                
                local fGrad = Instance.new("UIGradient")
                fGrad.Color = ColorSequence.new(Library.Theme.Accent, Library.Theme.AccentGradient)
                fGrad.Parent = Fill
                RegisterAccent(fGrad, "Color", true)
                
                local currentValue = default
                
                local function SetValue(val, skipCallback)
                    currentValue = math.clamp(val, min, max)
                    local scale = (currentValue - min) / (max - min)
                    Fill.Size = UDim2.new(scale, 0, 1, 0)
                    
                    local factor = 10 ^ rounding
                    currentValue = math.round(currentValue * factor) / factor
                    valLabel.Text = tostring(currentValue)
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
                label.TextSize = 13
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = dropFrame
                
                local TriggerButton = Instance.new("TextButton")
                TriggerButton.Position = UDim2.new(0, 0, 0, 20)
                TriggerButton.Size = UDim2.new(1, 0, 0, 24)
                TriggerButton.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
                TriggerButton.Text = "  Select Option"
                TriggerButton.TextColor3 = Library.Theme.TextMuted
                TriggerButton.Font = Library.Theme.Font
                TriggerButton.TextSize = 12
                TriggerButton.TextXAlignment = Enum.TextXAlignment.Left
                TriggerButton.Parent = dropFrame
                
                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 5)
                tbCorner.Parent = TriggerButton
                
                local tbStroke = Instance.new("UIStroke")
                tbStroke.Color = Library.Theme.Border
                tbStroke.Thickness = 1
                tbStroke.Parent = TriggerButton
                
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
                    
                    local popupHeight = math.min(#values * 26 + 40, 170)
                    
                    local DropdownPopup = Instance.new("Frame")
                    DropdownPopup.Size = UDim2.new(0, TriggerButton.AbsoluteSize.X, 0, popupHeight)
                    DropdownPopup.Position = UDim2.new(0, TriggerButton.AbsolutePosition.X, 0, TriggerButton.AbsolutePosition.Y + 28)
                    DropdownPopup.BackgroundColor3 = Library.Theme.Groupbox
                    DropdownPopup.BorderSizePixel = 0
                    DropdownPopup.Parent = Overlay
                    
                    local dpCorner = Instance.new("UICorner")
                    dpCorner.CornerRadius = UDim.new(0, 6)
                    dpCorner.Parent = DropdownPopup
                    
                    local dpStroke = Instance.new("UIStroke")
                    dpStroke.Color = Library.Theme.BorderGlow
                    dpStroke.Thickness = 1
                    dpStroke.Parent = DropdownPopup
                    
                    local SearchBox = Instance.new("TextBox")
                    SearchBox.Size = UDim2.new(0.9, 0, 0, 22)
                    SearchBox.Position = UDim2.new(0.05, 0, 0, 6)
                    SearchBox.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
                    SearchBox.PlaceholderText = "Search..."
                    SearchBox.PlaceholderColor3 = Library.Theme.TextMuted
                    SearchBox.TextColor3 = Library.Theme.Text
                    SearchBox.Font = Library.Theme.Font
                    SearchBox.TextSize = 11
                    SearchBox.Parent = DropdownPopup
                    
                    local sCorner = Instance.new("UICorner")
                    sCorner.CornerRadius = UDim.new(0, 4)
                    sCorner.Parent = SearchBox
                    
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
                        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                        btn.BorderSizePixel = 0
                        btn.Font = Library.Theme.Font
                        btn.TextSize = 12
                        btn.Parent = ListFrame
                        
                        local bCorner = Instance.new("UICorner")
                        bCorner.CornerRadius = UDim.new(0, 4)
                        bCorner.Parent = btn
                        
                        local function Highlight()
                            local active = false
                            if multi then active = Selection[val] else active = (Selection == val) end
                            if active then
                                btn.TextColor3 = Library.Theme.Text
                                btn.BackgroundColor3 = Library.Theme.Accent
                            else
                                btn.TextColor3 = Library.Theme.TextMuted
                                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                            end
                        end
                        
                        btn.Text = "  " .. tostring(val)
                        btn.TextXAlignment = Enum.TextXAlignment.Left
                        Highlight()
                        
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
                label.TextSize = 13
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = inputFrame
                
                local box = Instance.new("TextBox")
                box.Position = UDim2.new(0, 0, 0, 20)
                box.Size = UDim2.new(1, 0, 0, 24)
                box.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
                box.Text = default
                box.PlaceholderText = placeholder
                box.TextColor3 = Library.Theme.Text
                box.PlaceholderColor3 = Library.Theme.TextMuted
                box.Font = Library.Theme.Font
                box.TextSize = 12
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Parent = inputFrame
                
                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 5)
                bCorner.Parent = box
                
                local bStroke = Instance.new("UIStroke")
                bStroke.Color = Library.Theme.Border
                bStroke.Thickness = 1
                bStroke.Parent = box
                
                local tPad = Instance.new("UIPadding")
                tPad.PaddingLeft = UDim.new(0, 8)
                tPad.Parent = box
                
                Library.Options[id] = { Value = default }
                
                box.FocusLost:Connect(function(enterPressed)
                    local val = box.Text
                    Library.Options[id] = { Value = val }
                    pcall(callback, val)
                end)
                
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
                btn.BackgroundColor3 = Library.Theme.Accent
                btn.BorderSizePixel = 0
                btn.Text = text
                btn.TextColor3 = Library.Theme.Text
                btn.Font = Library.Theme.FontBold
                btn.TextSize = 12
                btn.Parent = ContentArea
                RegisterAccent(btn, "BackgroundColor3")
                
                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 5)
                bCorner.Parent = btn
                
                local bGrad = Instance.new("UIGradient")
                bGrad.Color = ColorSequence.new(Library.Theme.Accent, Library.Theme.AccentGradient)
                bGrad.Parent = btn
                RegisterAccent(bGrad, "Color", true)
                
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
                    KeybindButton.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
                    KeybindButton.Text = "[" .. kpDefault .. "]"
                    KeybindButton.TextColor3 = Library.Theme.TextMuted
                    KeybindButton.Font = Library.Theme.Font
                    KeybindButton.TextSize = 11
                    KeybindButton.Parent = labelFrame
                    
                    local kbCorner = Instance.new("UICorner")
                    kbCorner.CornerRadius = UDim.new(0, 4)
                    kbCorner.Parent = KeybindButton
                    
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
                    ColorBox.Size = UDim2.new(0, 18, 0, 18)
                    ColorBox.BackgroundColor3 = cpDefault
                    ColorBox.Text = ""
                    ColorBox.LayoutOrder = #RightControls:GetChildren()
                    ColorBox.Parent = RightControls
                    
                    local cpCorner = Instance.new("UICorner")
                    cpCorner.CornerRadius = UDim.new(0, 4)
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
                        popupCorner.CornerRadius = UDim.new(0, 6)
                        popupCorner.Parent = PickerPopup
                        
                        local popupStroke = Instance.new("UIStroke")
                        popupStroke.Color = Library.Theme.BorderGlow
                        popupStroke.Thickness = 1
                        popupStroke.Parent = PickerPopup
                        
                        local PresetsFrame = Instance.new("Frame")
                        PresetsFrame.Position = UDim2.new(0, 10, 0, 10)
                        PresetsFrame.Size = UDim2.new(1, -20, 0, 36)
                        PresetsFrame.BackgroundTransparency = 1
                        PresetsFrame.Parent = PickerPopup
                        
                        local PresetsLayout = Instance.new("UIGridLayout")
                        PresetsLayout.CellSize = UDim2.new(0, 14, 0, 14)
                        PresetsLayout.CellSpacing = UDim2.new(0, 5, 0, 5)
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
                        
                        local function CreateRGBSlider(name, colorVal, changeCallback)
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
                            track.Size = UDim2.new(0.8, -5, 0, 8)
                            track.Position = UDim2.new(0.2, 5, 0.5, -4)
                            track.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                            track.BorderSizePixel = 0
                            track.Text = ""
                            track.Parent = sFrame
                            
                            local fill = Instance.new("Frame")
                            fill.Size = UDim2.new(colorVal / 255, 0, 1, 0)
                            fill.BackgroundColor3 = Library.Theme.Accent
                            fill.BorderSizePixel = 0
                            fill.Parent = track
                            
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
                        
                        CreateRGBSlider("R", r, function(val) r = val; Reevaluate() end)
                        CreateRGBSlider("G", g, function(val) g = val; Reevaluate() end)
                        CreateRGBSlider("B", b, function(val) b = val; Reevaluate() end)
                        
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
                            pCorner.CornerRadius = UDim.new(0, 3)
                            pCorner.Parent = pBtn
                            
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
        
        function Tab:AddLeftGroupbox(title)
            return CreateGroupbox(title, LeftScroll)
        end
        
        function Tab:AddRightGroupbox(title)
            return CreateGroupbox(title, RightScroll)
        end
        
        table.insert(Window.Tabs, Tab)
        return Tab
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

-- Mock and Compatibility layers for SaveManager and ThemeManager
Library.ThemeManager = {
    SetLibrary = function(_, lib) end,
    ApplyToTab = function(_, tab)
        local group = tab:AddLeftGroupbox("Theme settings")
        
        group:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", {
            Default = Library.Theme.Accent,
            Callback = function(color)
                Library:UpdateTheme(color)
            end
        })
        
        -- Compact color presets in a single label!
        local label = group:AddLabel("Quick Themes")
        label:AddColorPicker("Preset1", { Default = Color3.fromRGB(130, 90, 255), Callback = function() Library:UpdateTheme(Color3.fromRGB(130, 90, 255)) end })
        label:AddColorPicker("Preset2", { Default = Color3.fromRGB(0, 220, 255), Callback = function() Library:UpdateTheme(Color3.fromRGB(0, 220, 255)) end })
        label:AddColorPicker("Preset3", { Default = Color3.fromRGB(255, 60, 80), Callback = function() Library:UpdateTheme(Color3.fromRGB(255, 60, 80)) end })
        label:AddColorPicker("Preset4", { Default = Color3.fromRGB(40, 220, 100), Callback = function() Library:UpdateTheme(Color3.fromRGB(40, 220, 100)) end })
        label:AddColorPicker("Preset5", { Default = Color3.fromRGB(255, 140, 0), Callback = function() Library:UpdateTheme(Color3.fromRGB(255, 140, 0)) end })
        label:AddColorPicker("Preset6", { Default = Color3.fromRGB(255, 100, 180), Callback = function() Library:UpdateTheme(Color3.fromRGB(255, 100, 180)) end })
        
        group:AddButton("Reset Theme", function()
            Library:UpdateTheme(Color3.fromRGB(130, 90, 255))
            Library:Notify("Theme reset to default!")
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
