-- [[ CONFIGURATION ]] --
local shareUrl = "https://ratssdrat.online" 
local EncryptionKey = "0O;#4cz{BJ2hOy,;yfa=/dg._WFpAIB7>6–qK[VBw*am@VpnFTI%<JL:**4zF1?G" 

if getgenv().EnableAdmin == nil then getgenv().EnableAdmin = true end

-- [[ SERVICES ]] --
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- [[ UTILS ]] --
local function Crypt(data, key)
    local output = {}
    for i = 1, #data do
        local b = string.byte(data, i)
        local k = string.byte(key, (i - 1) % #key + 1)
        table.insert(output, string.char(bit32.bxor(b, k)))
    end
    if crypt and crypt.base64 then return crypt.base64.encode(table.concat(output)) end
    return game:GetService("HttpService"):JSONEncode({d=table.concat(output)}) 
end

local function Decrypt(data, key)
    local raw = ""
    if crypt and crypt.base64 then raw = crypt.base64.decode(data)
    else local s, r = pcall(function() return game:GetService("HttpService"):JSONDecode(data).d end); if s then raw = r else raw = data end end
    local output = {}
    for i = 1, #raw do
        local b = string.byte(raw, i)
        local k = string.byte(key, (i - 1) % #key + 1)
        table.insert(output, string.char(bit32.bxor(b, k)))
    end
    return table.concat(output)
end

-- [[ MAIN SCRIPT ]] --
function loadMainScript(IsAdmin)
    if getgenv().DesyncScriptCleanup then
        pcall(getgenv().DesyncScriptCleanup)
        getgenv().DesyncScriptCleanup = nil
    end

    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/lovecruitdev/lib/main/Library.lua"))()
    local ThemeManager = Library.ThemeManager
    local SaveManager = Library.SaveManager

    local Options = Library.Options
    local Toggles = Library.Toggles

    local Window = Library:CreateWindow({ Title = "Script", Center = true, AutoShow = true, TabPadding = 8 })

    getgenv().DesyncSettings = {
        Desync = { Enabled = false, FrozenTick = 0 },
        ESP = {
            Enabled = false,
            Box = false, BoxColor = Color3.fromRGB(255, 0, 0),
            Tracers = false, TracerColor = Color3.fromRGB(255, 0, 0), TracerLength = 2.1,
            Skeletons = false, SkeletonColor = Color3.fromRGB(255, 255, 255),
            HeadDot = false, 
            Chams = false, ChamsFill = Color3.fromRGB(255, 0, 0), ChamsOutline = Color3.fromRGB(255, 255, 255),
            Names = false, NameColor = Color3.fromRGB(255, 255, 255), NameFont = Enum.Font.GothamBlack
        },
        Tank = {
            Enabled = false,
            TeamCheck = false,
            DebugMode = false,
            Name = false,
            Occupants = false,
            NameColor = Color3.fromRGB(255, 215, 0),
            Highlight = false, FillColor = Color3.fromRGB(255, 100, 0), OutlineColor = Color3.fromRGB(255, 255, 0),
            HideEmpty = false,
            MaxDistance = 5000
        }
    }
    
    local FontsTable = { 
        ["Gotham Black"] = Enum.Font.GothamBlack, ["Gotham Bold"] = Enum.Font.GothamBold, ["Luckiest Guy"] = Enum.Font.LuckiestGuy, 
        ["Fredoka One"] = Enum.Font.FredokaOne, ["Bangers"] = Enum.Font.Bangers, ["Code"] = Enum.Font.Code,
        ["Arial"] = Enum.Font.Arial, ["Arial Bold"] = Enum.Font.ArialBold, ["Source Sans"] = Enum.Font.SourceSans,
        ["Source Sans Bold"] = Enum.Font.SourceSansBold, ["Sarpanch"] = Enum.Font.Sarpanch, ["Roboto"] = Enum.Font.Roboto,
        ["Oswald"] = Enum.Font.Oswald, ["Amatic SC"] = Enum.Font.AmaticSC, ["Michroma"] = Enum.Font.Michroma, ["Arcade"] = Enum.Font.Arcade
    }
    local FontKeys = {}; for k, v in pairs(FontsTable) do table.insert(FontKeys, k) end; table.sort(FontKeys)

    -- [[ CLOUD FUNCTIONS ]] --
    local ConfigList = {}
    local ConfigIds = {} 
    local ConfigOwners = {}

    local function FetchConfigs()
        local ok, response = pcall(function()
            return request({ 
                Url = shareUrl .. "/configs", 
                Method = "GET",
                Headers = {["Authorization"] = "Bearer " .. (getgenv().DesyncKey or "")}
            })
        end)
        if not ok or response.StatusCode ~= 200 then return false end
        local data = HttpService:JSONDecode(response.Body)
        if data.success then
            ConfigList = {}
            ConfigIds = {}
            ConfigOwners = {}
            for _, cfg in ipairs(data.configs) do
                local locked = cfg.locked and "🔒 " or ""
                local adminInfo = cfg.admin_pass and (" ["..cfg.admin_pass.."]") or ""
                local ownMark = cfg.is_owner and " [OWNER]" or ""
                local shortAuth = #cfg.author > 4 and cfg.author:sub(1,4)..".." or cfg.author
                local name = string.format("%s%s (%s)%s%s", locked, cfg.name, shortAuth, adminInfo, ownMark)
                table.insert(ConfigList, name)
                ConfigIds[name] = cfg.id 
                ConfigOwners[name] = cfg.is_owner
            end
            return true
        end
        return false
    end

    local function UploadConfig(cfgName, cfgPass, isPublic)
        local raw_json = HttpService:JSONEncode(getgenv().DesyncSettings)
        local encrypted_data = Crypt(raw_json, EncryptionKey)
        local response = request({
            Url = shareUrl .. "/share",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. (getgenv().DesyncKey or "")},
            Body = HttpService:JSONEncode({
                config = encrypted_data,
                name = cfgName,
                author = LocalPlayer.Name,
                password = cfgPass,
                is_public = isPublic
            })
        })
        if response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data.success then
                setclipboard(data.id)
                Library:Notify("Uploaded! ID Copied: " .. data.id)
                FetchConfigs() 
                if Options.CloudCfgList then 
                    Options.CloudCfgList:SetValues(ConfigList) 
                    Options.CloudCfgList:SetValue(ConfigList[1] or nil)
                end
                if Options.AdminMultiDelete then 
                    Options.AdminMultiDelete:SetValues(ConfigList) 
                    Options.AdminMultiDelete:SetValue({})
                end
            else
                Library:Notify("Error: " .. (data.message or "Unknown"))
            end
        else Library:Notify("Server Error: " .. tostring(response.StatusCode)) end
    end

    local function UpdateUI()
        local s = getgenv().DesyncSettings
        if Toggles.DesyncToggle then Toggles.DesyncToggle:SetValue(s.Desync.Enabled) end
        if Toggles.ESPMaster then Toggles.ESPMaster:SetValue(s.ESP.Enabled) end
        if Toggles.ESPBox then Toggles.ESPBox:SetValue(s.ESP.Box) end
        if Toggles.ESPSkel then Toggles.ESPSkel:SetValue(s.ESP.Skeletons) end
        if Toggles.ESPHeadDot then Toggles.ESPHeadDot:SetValue(s.ESP.HeadDot) end
        if Toggles.ESPTracer then Toggles.ESPTracer:SetValue(s.ESP.Tracers) end
        if Toggles.ESPName then Toggles.ESPName:SetValue(s.ESP.Names) end
        if Toggles.ESPChams then Toggles.ESPChams:SetValue(s.ESP.Chams) end
        if s.ESP.TracerLength and Options.ESPTracerLen then Options.ESPTracerLen:SetValue(s.ESP.TracerLength) end
        if Toggles.TankESP then Toggles.TankESP:SetValue(s.Tank.Enabled) end
        if Toggles.TankTeamCheck then Toggles.TankTeamCheck:SetValue(s.Tank.TeamCheck) end
        if Toggles.TankDebug then Toggles.TankDebug:SetValue(s.Tank.DebugMode) end
        if Toggles.TankName then Toggles.TankName:SetValue(s.Tank.Name) end
        if Toggles.TankOcc then Toggles.TankOcc:SetValue(s.Tank.Occupants) end
        if Toggles.TankHide then Toggles.TankHide:SetValue(s.Tank.HideEmpty) end
        if Toggles.TankHighlight then Toggles.TankHighlight:SetValue(s.Tank.Highlight) end
        if s.Tank.MaxDistance and Options.TankDist then Options.TankDist:SetValue(s.Tank.MaxDistance) end
    end

    local function LoadCloudConfig(cfgId, cfgPass)
        local response = request({
            Url = shareUrl .. "/load_config",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. (getgenv().DesyncKey or "")},
            Body = HttpService:JSONEncode({ id = cfgId, password = cfgPass })
        })
        if response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data.success then
                local decrypted_json = Decrypt(data.data, EncryptionKey)
                local s, settings = pcall(function() return HttpService:JSONDecode(decrypted_json) end)
                if not s then return Library:Notify("Decryption Failed!") end
                for category, values in pairs(settings) do
                    if getgenv().DesyncSettings[category] then
                        for k, v in pairs(values) do
                            getgenv().DesyncSettings[category][k] = v
                        end
                    end
                end
                UpdateUI()
                Library:Notify("Loaded: " .. data.name)
            else
                Library:Notify(data.message)
            end
        else Library:Notify("Server Error") end
    end

    local function DeleteMultipleConfigs(idList)
        request({
            Url = shareUrl .. "/delete_config",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. (getgenv().DesyncKey or "")},
            Body = HttpService:JSONEncode({ ids = idList })
        })
        FetchConfigs()
        if Options.CloudCfgList then 
            Options.CloudCfgList:SetValues(ConfigList) 
            Options.CloudCfgList:SetValue(ConfigList[1] or nil)
        end
        if Options.AdminMultiDelete then 
            Options.AdminMultiDelete:SetValues(ConfigList)
            Options.AdminMultiDelete:SetValue({})
        end
        Library:Notify("Deleted & Refreshed")
    end

    local function SetAutoLoad(id, pass)
        writefile("desync_autoload.txt", id .. "|" .. pass)
        Library:Notify("Set as AutoLoad!")
    end

    local function CheckAutoLoad()
        if isfile("desync_autoload.txt") then
            local content = readfile("desync_autoload.txt")
            local id, pass = content:match("^(.-)|(.*)$")
            if id then
                Library:Notify("Auto-Loading...")
                LoadCloudConfig(id, pass)
            end
        end
    end

    -- [[ UI ]] --
    local Tabs = {
        Main = Window:AddTab("Main", "home"),
        Visuals = Window:AddTab("Visuals", "eye"),
        Settings = Window:AddTab("Settings", "settings"),
    }

    local MainBox = Tabs.Main:AddLeftGroupbox("Desync Controls")
    MainBox:AddToggle("DesyncToggle", {
        Text = "Enable Desync",
        Default = false,
        Callback = function(Value) getgenv().DesyncSettings.Desync.Enabled = Value end
    }):AddKeyPicker("DesyncKey", { Default = "None", Mode = "Toggle", Text = "Desync Bind", SyncToggleState = true })

    local VisualsBox = Tabs.Visuals:AddLeftGroupbox("Player ESP")
    VisualsBox:AddToggle("ESPMaster", { Text = "Master Switch", Default = false, Callback = function(v) getgenv().DesyncSettings.ESP.Enabled = v end })
    VisualsBox:AddToggle("ESPBox", { Text = "Box 3D", Default = false, Callback = function(v) getgenv().DesyncSettings.ESP.Box = v end })
        :AddColorPicker("ESPBoxColor", { Default = Color3.new(1,0,0), Callback = function(v) getgenv().DesyncSettings.ESP.BoxColor = v end })
    VisualsBox:AddToggle("ESPSkel", { Text = "Skeletons", Default = false, Callback = function(v) getgenv().DesyncSettings.ESP.Skeletons = v end })
        :AddColorPicker("ESPSkelColor", { Default = Color3.new(1,1,1), Callback = function(v) getgenv().DesyncSettings.ESP.SkeletonColor = v end })
    VisualsBox:AddToggle("ESPHeadDot", { Text = "Head Dot", Default = false, Callback = function(v) getgenv().DesyncSettings.ESP.HeadDot = v end })
    VisualsBox:AddToggle("ESPTracer", { Text = "Tracers", Default = false, Callback = function(v) getgenv().DesyncSettings.ESP.Tracers = v end })
        :AddColorPicker("ESPTracerColor", { Default = Color3.new(1,0,0), Callback = function(v) getgenv().DesyncSettings.ESP.TracerColor = v end })
    VisualsBox:AddSlider("ESPTracerLen", { Text = "Length", Default = 2.1, Min = 0.5, Max = 10, Rounding = 1, Callback = function(v) getgenv().DesyncSettings.ESP.TracerLength = v end })
    VisualsBox:AddDivider()
    VisualsBox:AddToggle("ESPName", { Text = "Names", Default = false, Callback = function(v) getgenv().DesyncSettings.ESP.Names = v end })
        :AddColorPicker("ESPNameColor", { Default = Color3.new(1,1,1), Callback = function(v) getgenv().DesyncSettings.ESP.NameColor = v end })
    VisualsBox:AddDropdown("ESPFont", { Values = FontKeys, Default = "Gotham Black", Text = "Name Font", Callback = function(v) getgenv().DesyncSettings.ESP.NameFont = FontsTable[v] end })
    VisualsBox:AddToggle("ESPChams", { Text = "Chams", Default = false, Callback = function(v) getgenv().DesyncSettings.ESP.Chams = v end })
        :AddColorPicker("ESPChamsFill", { Default = Color3.new(1,0,0), Title = "Fill", Callback = function(v) getgenv().DesyncSettings.ESP.ChamsFill = v end })
        :AddColorPicker("ESPChamsOut", { Default = Color3.new(1,1,1), Title = "Outline", Callback = function(v) getgenv().DesyncSettings.ESP.ChamsOutline = v end })

    local VehicleBox = Tabs.Visuals:AddRightGroupbox("Vehicle ESP")
    VehicleBox:AddToggle("TankESP", { Text = "Enable Tank ESP", Default = false, Callback = function(v) getgenv().DesyncSettings.Tank.Enabled = v end })
    VehicleBox:AddToggle("TankTeamCheck", { Text = "Team Check", Default = false, Callback = function(v) getgenv().DesyncSettings.Tank.TeamCheck = v end })
    VehicleBox:AddToggle("TankDebug", { Text = "Debug Info (F9)", Default = false, Callback = function(v) getgenv().DesyncSettings.Tank.DebugMode = v end })
    VehicleBox:AddToggle("TankName", { Text = "Show Model Name", Default = false, Callback = function(v) getgenv().DesyncSettings.Tank.Name = v end })
    VehicleBox:AddToggle("TankOcc", { Text = "Show Occupants", Default = false, Callback = function(v) getgenv().DesyncSettings.Tank.Occupants = v end })
        :AddColorPicker("TankNameColor", { Default = Color3.fromRGB(255, 215, 0), Callback = function(v) getgenv().DesyncSettings.Tank.NameColor = v end })
    VehicleBox:AddToggle("TankHide", { Text = "Hide Empty", Default = false, Callback = function(v) getgenv().DesyncSettings.Tank.HideEmpty = v end })
    VehicleBox:AddToggle("TankHighlight", { Text = "Highlight", Default = false, Callback = function(v) getgenv().DesyncSettings.Tank.Highlight = v end })
        :AddColorPicker("TankFill", { Default = Color3.fromRGB(255, 100, 0), Title = "Fill", Callback = function(v) getgenv().DesyncSettings.Tank.FillColor = v end })
        :AddColorPicker("TankOutline", { Default = Color3.fromRGB(255, 255, 0), Title = "Outline", Callback = function(v) getgenv().DesyncSettings.Tank.OutlineColor = v end })
    VehicleBox:AddSlider("TankDist", { Text = "Max Distance", Default = 5000, Min = 100, Max = 10000, Rounding = 0, Callback = function(v) getgenv().DesyncSettings.Tank.MaxDistance = v end })

    -- [[ MARKET UI ]] --
    local CloudMarket = Tabs.Settings:AddRightGroupbox("Cloud Market")
    local CloudImport = Tabs.Settings:AddRightGroupbox("Import Code")
    local CloudUpload = Tabs.Settings:AddLeftGroupbox("Upload")
    local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu Settings")
    local AdminGroup = nil

    if IsAdmin then
        AdminGroup = Tabs.Settings:AddLeftGroupbox("ADMIN CONTROL")
    end

    FetchConfigs()

    local _MarketPass = ""
    local _ImportID = ""
    local _ImportPass = ""
    local _UploadName = "My Config"
    local _UploadPass = ""
    local _IsPublic = true 
    
    CloudMarket:AddDropdown("CloudCfgList", { Values = ConfigList, Default = 1, Multi = false, Text = "Configs" })
    CloudMarket:AddInput("CloudPassLoad", { Default = "", Text = "Password", Placeholder = "Optional", Callback = function(val) _MarketPass = val end })
    CloudMarket:AddButton("Load Selected", function() 
        local id = ConfigIds[Options.CloudCfgList.Value]
        if id then LoadCloudConfig(id, _MarketPass) end 
    end)
    CloudMarket:AddButton("Set as AutoLoad", function()
        local id = ConfigIds[Options.CloudCfgList.Value]
        if id then SetAutoLoad(id, _MarketPass) end
    end)
    CloudMarket:AddButton("Delete Selected (Owner)", function()
        local name = Options.CloudCfgList.Value
        local id = ConfigIds[name]
        local isOwner = ConfigOwners[name]
        if id and isOwner then DeleteMultipleConfigs({id}) 
        elseif id then Library:Notify("You don't own this!") end
    end)
    CloudMarket:AddButton("Refresh", function() 
        FetchConfigs()
        Options.CloudCfgList:SetValues(ConfigList)
        Options.CloudCfgList:SetValue(ConfigList[1] or nil) 
        if IsAdmin and Options.AdminMultiDelete then 
            Options.AdminMultiDelete:SetValues(ConfigList)
            Options.AdminMultiDelete:SetValue({})
        end
    end)

    CloudImport:AddInput("ImportId", { Default = "", Text = "ID", Placeholder = "CFG-XXXXXX", Callback = function(val) _ImportID = val end })
    CloudImport:AddInput("ImportPass", { Default = "", Text = "Pass", Placeholder = "Optional", Callback = function(val) _ImportPass = val end })
    CloudImport:AddButton("Load From ID", function() if _ImportID ~= "" then LoadCloudConfig(_ImportID, _ImportPass) end end)
    CloudImport:AddButton("Set as AutoLoad", function()
        if _ImportID ~= "" then SetAutoLoad(_ImportID, _ImportPass) else Library:Notify("Enter ID first!") end
    end)

    CloudUpload:AddInput("CloudCfgName", { Default = "Config", Text = "Name", Callback = function(val) _UploadName = val end })
    CloudUpload:AddInput("CloudCfgPass", { Default = "", Text = "Password", Callback = function(val) _UploadPass = val end })
    CloudUpload:AddToggle("CloudPublic", { Text = "Publish to Market", Default = true, Callback = function(val) _IsPublic = val end })
    local upDb = false
    CloudUpload:AddButton("Upload", function()
        if upDb then return end; upDb = true
        local name = _UploadName == "" and "Unnamed" or _UploadName
        UploadConfig(name, _UploadPass, _IsPublic)
        task.wait(2); upDb = false
    end)

    if IsAdmin and AdminGroup then
        MenuGroup:AddToggle("AdminToggle", {
            Text = "Admin Mode",
            Default = true,
            Callback = function(val)
                pcall(function() AdminGroup.Visible = val end)
            end
        })
        AdminGroup:AddDropdown("AdminMultiDelete", { Values = ConfigList, Default = 1, Multi = true, Text = "Bulk Delete" })
        AdminGroup:AddButton("DELETE SELECTED", function()
            local ids = {}
            for name, sel in pairs(Options.AdminMultiDelete.Value) do if sel then table.insert(ids, ConfigIds[name]) end end
            if #ids > 0 then DeleteMultipleConfigs(ids) end
        end)
    end

    MenuGroup:AddButton("Unload Script", function() Library:Unload() end)
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })
    Library.ToggleKeybind = Options.MenuKeybind 

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetFolder("DesyncObsidian")
    SaveManager:BuildConfigSection(Tabs.Settings)
    ThemeManager:ApplyToTab(Tabs.Settings)

    -- [[ RENDER LOGIC ]] --
    local Connections = {}
    local ESP_Cache = {}
    local Tank_Cache = {}
    local workingOffset = 1
    local raknetSendHook = nil
    local unloaded = false
    local lastCacheCleanup = 0

    -- [[ GHOST SPHERE ]] --
    local ghostSphere = nil
    local lastGhostPosition = nil

    local function createGhostSphere(position)
        if ghostSphere then ghostSphere:Destroy() end
        local part = Instance.new("Part")
        part.Name = "DesyncGhostSphere"
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(4, 4, 4)
        part.Position = position
        part.Anchored = true
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(0, 200, 255)
        part.Transparency = 0.3
        part.CastShadow = false
        part.Parent = Camera

        local hl = Instance.new("Highlight", part)
        hl.FillColor = Color3.fromRGB(0, 200, 255)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        local bb = Instance.new("BillboardGui", part)
        bb.Size = UDim2.new(0, 120, 0, 30)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "DESYNC POS"
        lbl.TextColor3 = Color3.fromRGB(0, 200, 255)
        lbl.TextStrokeTransparency = 0.2
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 13

        ghostSphere = part
    end

    local SkeletonJointsR15 = {{"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
    local SkeletonJointsR6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}

    local function Draw(t) local o=Drawing.new(t); o.Visible=false; o.Transparency=1; o.Color=Color3.new(1,1,1); if t=="Line" then o.Thickness=1 elseif t=="Text" then o.Center=true; o.Outline=true elseif t=="Circle" then o.Filled=false; o.Radius=10 end; return o end
    
    local function SafeRemove(obj)
        if obj then pcall(function() obj:Remove() end) end
    end

    local function SafeDestroy(obj)
        if obj then pcall(function() obj:Destroy() end) end
    end

    local function ClearESP(p)
        local cache = ESP_Cache[p]
        if not cache then return end

        for _, v in pairs(cache.Lines or {}) do SafeRemove(v) end
        for _, v in pairs(cache.Skel or {}) do SafeRemove(v) end
        SafeRemove(cache.Tracer)
        SafeRemove(cache.HeadCircle)
        SafeDestroy(cache.NameTag)

        local hl = CoreGui:FindFirstChild(p.Name .. "_DesyncChams")
        SafeDestroy(hl)
        ESP_Cache[p] = nil
    end

    local function InitESP(p)
        if p == LocalPlayer then return end
        ClearESP(p)

        local lines = {}
        local skeleton = {}
        for i = 1, 12 do lines[i] = Draw("Line") end
        for i = 1, 15 do skeleton[i] = Draw("Line") end

        ESP_Cache[p] = {
            Lines = lines,
            Skel = skeleton,
            Tracer = Draw("Line"),
            HeadCircle = Draw("Circle"),
            NameTag = nil
        }
    end

    local function ClearTankESP(model)
        local cache = Tank_Cache[model]
        if not cache then return end

        SafeDestroy(cache.Highlight)
        SafeDestroy(cache.Billboard)
        Tank_Cache[model] = nil
    end

    local function SetupTankESP(model)
        if Tank_Cache[model] or not model or not model.Parent then return end

        local seats = {}
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("VehicleSeat") then
                seats[#seats + 1] = child
            end
        end

        if #seats == 0 then return end
        Tank_Cache[model] = { Model = model, Highlight = nil, Billboard = nil, Seats = seats }
    end

    local function GetTankOccupants(cache)
        local occupants = {}
        local mainSeat = nil

        for i = #cache.Seats, 1, -1 do
            local seat = cache.Seats[i]
            if not seat or not seat.Parent then
                table.remove(cache.Seats, i)
            else
                mainSeat = mainSeat or seat
                if seat.Occupant and seat.Occupant.Parent then
                    occupants[#occupants + 1] = seat.Occupant.Parent.Name
                end
            end
        end

        return occupants, mainSeat
    end

    local function UpdateTankVisuals(model)
        local cache = Tank_Cache[model]; if not cache then return end; if not model.Parent then ClearTankESP(model) return end
        local occupants, bestSeat = GetTankOccupants(cache)
        if not bestSeat then ClearTankESP(model) return end
        local hasDriver = (#occupants > 0)
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
        local dist = (bestSeat.Position - root.Position).Magnitude
        local isTeamMate = false
        if hasDriver then
            local firstPlayer = Players:FindFirstChild(occupants[1])
            if firstPlayer and firstPlayer ~= LocalPlayer and firstPlayer.Team == LocalPlayer.Team then isTeamMate = true end
        end
        if not isTeamMate and getgenv().DesyncSettings.Tank.TeamCheck then
            local attrTeam = model:GetAttribute("Team")
            if attrTeam then
                local myTeamColor = tostring(LocalPlayer.TeamColor.Name)
                local myTeamName = LocalPlayer.Team and LocalPlayer.Team.Name or ""
                if string.lower(tostring(attrTeam)) == string.lower(myTeamColor) then isTeamMate = true end
                if string.lower(tostring(attrTeam)) == string.lower(myTeamName) then isTeamMate = true end
            end
        end
        if dist > getgenv().DesyncSettings.Tank.MaxDistance or (getgenv().DesyncSettings.Tank.HideEmpty and not hasDriver) or (getgenv().DesyncSettings.Tank.TeamCheck and isTeamMate) then 
            if cache.Highlight then cache.Highlight.Enabled = false end; if cache.Billboard then cache.Billboard.Enabled = false end; return 
        end
        local isMyTank = false; for _, name in pairs(occupants) do if name == LocalPlayer.Name then isMyTank = true break end end
        if isMyTank then if cache.Highlight then cache.Highlight.Enabled = false end; if cache.Billboard then cache.Billboard.Enabled = false end; return end
        if getgenv().DesyncSettings.Tank.Highlight and getgenv().DesyncSettings.Tank.Enabled then if not cache.Highlight then local hl = Instance.new("Highlight"); hl.Name = "DesyncTankHL"; hl.Adornee = model; hl.Parent = CoreGui; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; cache.Highlight = hl end; cache.Highlight.FillColor = getgenv().DesyncSettings.Tank.FillColor; cache.Highlight.OutlineColor = getgenv().DesyncSettings.Tank.OutlineColor; cache.Highlight.FillTransparency = 0.5; cache.Highlight.OutlineTransparency = 0; cache.Highlight.Enabled = true else if cache.Highlight then cache.Highlight.Enabled = false end end
        if (getgenv().DesyncSettings.Tank.Name or getgenv().DesyncSettings.Tank.Occupants) and getgenv().DesyncSettings.Tank.Enabled then 
            if not cache.Billboard then local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 200, 0, 50); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 7, 0); bb.Adornee = bestSeat; bb.Parent = CoreGui; local txt = Instance.new("TextLabel", bb); txt.Name = "Info"; txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextStrokeTransparency = 0.3; txt.Font = Enum.Font.GothamBold; txt.TextSize = 13; cache.Billboard = bb end
            local txtLabel = cache.Billboard:FindFirstChild("Info")
            if txtLabel then 
                local textLines = {}
                if getgenv().DesyncSettings.Tank.Occupants then
                    if hasDriver then table.insert(textLines, table.concat(occupants, ", ")) else table.insert(textLines, "[Empty]") end
                end
                if getgenv().DesyncSettings.Tank.Name then table.insert(textLines, model.Name) end
                txtLabel.Text = table.concat(textLines, "\n"); txtLabel.TextColor3 = getgenv().DesyncSettings.Tank.NameColor 
            end; cache.Billboard.Enabled = true 
        else if cache.Billboard then cache.Billboard.Enabled = false end end
    end

    local TargetFolder = Workspace:FindFirstChild("SpawnedVehicles")
    local function MonitorVehicles()
        if not TargetFolder then return end
        for _, child in pairs(TargetFolder:GetChildren()) do if child:IsA("Model") then SetupTankESP(child) end end
        Connections.VehicleAdded = TargetFolder.ChildAdded:Connect(function(child) if child:IsA("Model") then task.wait(0.5) SetupTankESP(child) end end)
        Connections.VehicleRemoved = TargetFolder.ChildRemoved:Connect(function(child) ClearTankESP(child) end)
    end
    if TargetFolder then MonitorVehicles() end

    -- [[ DESYNC RENDER ]] --
    Connections.DesyncRender = RunService.RenderStepped:Connect(function()
        local s = getgenv().DesyncSettings
        if not s then return end

        if s.Desync.Enabled then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- Первый запуск десинка — запоминаем текущую позицию
            if lastGhostPosition == nil then
                lastGhostPosition = root.Position
            end

            -- Создаём или обновляем сферку
            if not ghostSphere or not ghostSphere.Parent then
                createGhostSphere(lastGhostPosition)
            else
                ghostSphere.Position = lastGhostPosition
            end
        else
            -- Десинк выключен — обновляем позицию под текущую
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                lastGhostPosition = root.Position
            end
            if ghostSphere then ghostSphere:Destroy(); ghostSphere = nil end
        end
    end)

    -- [[ RAKNET HOOK ]] --
    if raknet then
        raknetSendHook = raknet.add_send_hook(function(message)
            if not getgenv().DesyncSettings or not getgenv().DesyncSettings.Desync then return end
            if message.PacketId ~= 0x1B then return end
            if message.Size < workingOffset + 4 then return end

            local packetData = message.AsBuffer

            if getgenv().DesyncSettings.Desync.Enabled then
                local newBuf = buffer.create(message.Size)
                buffer.copy(newBuf, 0, packetData, 0, message.Size)
                buffer.writeu32(newBuf, workingOffset, getgenv().DesyncSettings.Desync.FrozenTick)
                message:SetData(newBuf)
            else
                getgenv().DesyncSettings.Desync.FrozenTick = buffer.readu32(packetData, workingOffset)
            end
        end)
    end

    -- [[ ESP RENDER ]] --
    Connections.MainRender = RunService.RenderStepped:Connect(function()
        local now = os.clock()
        if now - lastCacheCleanup >= 5 then
            lastCacheCleanup = now
            for p, _ in pairs(ESP_Cache) do
                if not p.Parent then ClearESP(p) end
            end
            for model, _ in pairs(Tank_Cache) do
                if not model.Parent then ClearTankESP(model) end
            end
            pcall(function() collectgarbage("step", 200) end)
        end

        for p, d in pairs(ESP_Cache) do
            local c = p.Character; local r = c and c:FindFirstChild("HumanoidRootPart"); local h = c and c:FindFirstChild("Head")
            if getgenv().DesyncSettings.ESP.Enabled and c and r and h and p ~= LocalPlayer then
                local v, vis = Camera:WorldToViewportPoint(r.Position)
                if getgenv().DesyncSettings.ESP.Chams then local hl = CoreGui:FindFirstChild(p.Name .. "_DesyncChams"); if not hl then hl = Instance.new("Highlight"); hl.Name = p.Name .. "_DesyncChams"; hl.Parent = CoreGui; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end; hl.Adornee = c; hl.FillColor = getgenv().DesyncSettings.ESP.ChamsFill; hl.OutlineColor = getgenv().DesyncSettings.ESP.ChamsOutline; hl.FillTransparency = 0.5; hl.Enabled = true else local hl = CoreGui:FindFirstChild(p.Name .. "_DesyncChams"); if hl then hl:Destroy() end end
                if vis then
                    if getgenv().DesyncSettings.ESP.Box then
                        local s=c:GetExtentsSize(); local cf=r.CFrame*CFrame.new(0,-0.5,0); local pts={}; local corn={Vector3.new(s.X/2,s.Y/2,s.Z/2),Vector3.new(s.X/2,s.Y/2,-s.Z/2),Vector3.new(-s.X/2,s.Y/2,s.Z/2),Vector3.new(-s.X/2,s.Y/2,-s.Z/2),Vector3.new(s.X/2,-s.Y/2,s.Z/2),Vector3.new(s.X/2,-s.Y/2,-s.Z/2),Vector3.new(-s.X/2,-s.Y/2,s.Z/2),Vector3.new(-s.X/2,-s.Y/2,-s.Z/2)}; for _,vec in pairs(corn) do local sc=Camera:WorldToViewportPoint(cf:PointToWorldSpace(vec)); table.insert(pts, Vector2.new(sc.X, sc.Y)) end; local ind={1,2, 1,3, 1,5, 2,4, 2,6, 3,4, 3,7, 4,8, 5,6, 5,7, 6,8, 7,8}; for i=1,12 do local l=d.Lines[i]; l.Visible=true; l.Color=getgenv().DesyncSettings.ESP.BoxColor; l.From=pts[ind[i*2-1]]; l.To=pts[ind[i*2]] end
                    else for i=1,12 do d.Lines[i].Visible=false end end
                    if getgenv().DesyncSettings.ESP.Skeletons then 
                        local isR15 = (c:FindFirstChild("Humanoid") and c.Humanoid.RigType == Enum.HumanoidRigType.R15)
                        local joints = isR15 and SkeletonJointsR15 or SkeletonJointsR6
                        for i, joint in pairs(joints) do 
                            local p1, p2 = c:FindFirstChild(joint[1]), c:FindFirstChild(joint[2])
                            local ln = d.Skel[i]
                            if ln and p1 and p2 then 
                                local v1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                                local v2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                                if vis1 and vis2 then 
                                    ln.Visible=true; ln.Color=getgenv().DesyncSettings.ESP.SkeletonColor; ln.From=Vector2.new(v1.X,v1.Y); ln.To=Vector2.new(v2.X,v2.Y) 
                                else ln.Visible=false end 
                            elseif ln then ln.Visible=false end 
                        end
                        local vh, vish = Camera:WorldToViewportPoint(h.Position)
                        if vish and getgenv().DesyncSettings.ESP.HeadDot then 
                            local dist = (Camera.CFrame.Position - h.Position).Magnitude
                            local scale = math.clamp(1000 / dist, 2, 15)
                            d.HeadCircle.Visible = true
                            d.HeadCircle.Radius = scale
                            d.HeadCircle.Color = getgenv().DesyncSettings.ESP.SkeletonColor
                            d.HeadCircle.Position = Vector2.new(vh.X, vh.Y) 
                        else d.HeadCircle.Visible = false end 
                    else 
                        for _,l in pairs(d.Skel) do l.Visible=false end; d.HeadCircle.Visible = false 
                    end
                    if getgenv().DesyncSettings.ESP.Tracers then local hp=Camera:WorldToViewportPoint(h.Position); local ep=Camera:WorldToViewportPoint(h.Position+h.CFrame.LookVector*getgenv().DesyncSettings.ESP.TracerLength); d.Tracer.Visible=true; d.Tracer.Color=getgenv().DesyncSettings.ESP.TracerColor; d.Tracer.From=Vector2.new(hp.X,hp.Y); d.Tracer.To=Vector2.new(ep.X,ep.Y) else d.Tracer.Visible=false end
                    if getgenv().DesyncSettings.ESP.Names then if not d.NameTag then local b=Instance.new("BillboardGui",CoreGui); b.Size=UDim2.new(0,200,0,50); b.AlwaysOnTop=true; b.StudsOffset=Vector3.new(0, 2.0, 0); local t=Instance.new("TextLabel",b); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1; t.TextStrokeTransparency=0.2; d.NameTag=b end; d.NameTag.Adornee=h; d.NameTag.Enabled=true; local lbl = d.NameTag.TextLabel; lbl.Text=p.Name; lbl.TextColor3=getgenv().DesyncSettings.ESP.NameColor; lbl.Font=getgenv().DesyncSettings.ESP.NameFont or Enum.Font.GothamBlack; lbl.TextSize=14 else if d.NameTag then d.NameTag.Enabled=false end end
                else
                    for _,l in pairs(d.Lines) do l.Visible=false end; for _,l in pairs(d.Skel) do l.Visible=false end; d.Tracer.Visible=false; d.HeadCircle.Visible=false; if d.NameTag then d.NameTag.Enabled=false end
                end
            else
               for _,l in pairs(d.Lines) do l.Visible=false end; for _,l in pairs(d.Skel) do l.Visible=false end; d.Tracer.Visible=false; d.HeadCircle.Visible=false; if d.NameTag then d.NameTag:Destroy(); d.NameTag=nil end; local hl = CoreGui:FindFirstChild(p.Name .. "_DesyncChams"); if hl then hl:Destroy() end
            end
        end
        if getgenv().DesyncSettings.Tank.Enabled then
            for model, _ in pairs(Tank_Cache) do pcall(function() UpdateTankVisuals(model) end) end
        else
            for model, cache in pairs(Tank_Cache) do if cache.Highlight then cache.Highlight.Enabled = false end; if cache.Billboard then cache.Billboard.Enabled = false end end
        end
    end)
    
    for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then InitESP(p) end end
    Connections.PlayerAdded = Players.PlayerAdded:Connect(InitESP)
    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(ClearESP)
    
    local function CleanupScript()
        if unloaded then return end
        unloaded = true

        for name, conn in pairs(Connections) do if conn then conn:Disconnect() end end
        if raknet and raknetSendHook then raknet.remove_send_hook(raknetSendHook) end
        for p, _ in pairs(ESP_Cache) do ClearESP(p) end
        for m, _ in pairs(Tank_Cache) do ClearTankESP(m) end
        if ghostSphere then ghostSphere:Destroy(); ghostSphere = nil end
        for _, p in pairs(Players:GetPlayers()) do local hl = CoreGui:FindFirstChild(p.Name .. "_DesyncChams"); if hl then hl:Destroy() end end
        pcall(function() collectgarbage("collect") end)
    end

    getgenv().DesyncScriptCleanup = CleanupScript

    Library:OnUnload(function()
        CleanupScript()
        if getgenv().DesyncScriptCleanup == CleanupScript then
            getgenv().DesyncScriptCleanup = nil
        end
    end)

    task.delay(1, CheckAutoLoad)
end

-- [[ START ]] --
loadMainScript(false)
