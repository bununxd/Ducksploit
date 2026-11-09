local CFG = {
    TITLE_TEXT = "DUCKSPLOIT",
    TITLE_AUTHOR = "BY BUNUNXD",
    TITLE_TAG = "Standard",
    TITLE_ICON_ID = "595029582",
    START_OPEN = true,
    FlingPower = 9000,
    SpinPower = 400,
    FlingDuration = 0.1,
    RENDER_BIND_NAME = "ESP_Lock_GUI_Aim",
    ESP_BIND_NAME = "ESP_Lock_GUI_ESP",
    CAMERA_BLOCK_ACTION = "ESP_Lock_BlockCameraInput",
    LEGACY_ATTR_PREFIX = "ESP_Lock_",
    FPS_DEFAULT = 60,
    SPECTATE_DISTANCE = 12,
}

-- fling tuning

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local genv = (type(getgenv) == "function" and getgenv()) or _G


local floor = math.floor
local clamp = math.clamp
local sqrt = math.sqrt
local exp = math.exp
local maxn = math.max
local minn = math.min
local huge = math.huge
local absn = math.abs
local rad = math.rad
local deg = math.deg
local atan2 = math.atan2
local acos = math.acos

local NAME_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function randomName()
    local n = math.random(9, 14)
    local out = table.create(n)
    for i = 1, n do
        local k = math.random(1, #NAME_CHARS)
        out[i] = NAME_CHARS:sub(k, k)
    end
    return table.concat(out)
end

CFG.GUI_NAME = randomName()
CFG.HL_NAME = randomName()

--// Look
local THEME = {
    Window = Color3.fromRGB(10, 10, 10),
    Title = Color3.fromRGB(10, 10, 10),
    Side = Color3.fromRGB(14, 14, 14),
    Row = Color3.fromRGB(20, 20, 20),
    RowActive = Color3.fromRGB(40, 40, 40),
    Button = Color3.fromRGB(26, 26, 26),
    ButtonActive = Color3.fromRGB(64, 64, 64),
    ButtonLine = Color3.fromRGB(46, 46, 46),
    Line = Color3.fromRGB(36, 36, 36),
    Text = Color3.fromRGB(205, 205, 205),
    Dim = Color3.fromRGB(128, 128, 128),
    On = Color3.fromRGB(255, 255, 255),
    Off = Color3.fromRGB(30, 30, 30),
    Track = Color3.fromRGB(34, 34, 34),
    Fill = Color3.fromRGB(240, 240, 240),
    Ink = Color3.fromRGB(8, 8, 8),
    InkDim = Color3.fromRGB(100, 100, 100),
    Accent = Color3.fromRGB(240, 240, 240),
    PanelT = 0,
}
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local STAR_ON = Color3.fromRGB(255, 214, 10)
local STAR_OFF = Color3.fromRGB(90, 90, 90)

--// Helpers
local function tween(object, properties, duration, style, direction)
    local t = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
        properties
    )
    t:Play()
    return t
end

local function round(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
    return c
end

local function keyToString(key)
    if typeof(key) ~= "EnumItem" then return "K:E" end
    if key.EnumType == Enum.KeyCode then return "K:" .. key.Name end
    if key.EnumType == Enum.UserInputType then return "M:" .. key.Name end
    return "K:E"
end

local function stringToKey(value, fallback)
    fallback = fallback or Enum.KeyCode.E
    if type(value) ~= "string" then return fallback end
    local kind, name = value:match("^([KM]):([%w_]+)$")
    if kind == "K" then
        local ok, result = pcall(function() return Enum.KeyCode[name] end)
        if ok and result then return result end
    elseif kind == "M" then
        local ok, result = pcall(function() return Enum.UserInputType[name] end)
        if ok and (result == Enum.UserInputType.MouseButton1
            or result == Enum.UserInputType.MouseButton2
            or result == Enum.UserInputType.MouseButton3) then
            return result
        end
    end
    return fallback
end

local function isFiniteNumber(value)
    return type(value) == "number" and value == value
        and value ~= huge and value ~= -huge
end

local function isPointerBegin(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointerMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function pointerPos(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        local inset = GuiService:GetGuiInset()
        return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
    end
    return UserInputService:GetMouseLocation()
end

local function shortKeyName(key)
    if typeof(key) ~= "EnumItem" or key == Enum.KeyCode.Unknown then return "none" end
    if key == Enum.UserInputType.MouseButton1 then return "mouse1" end
    if key == Enum.UserInputType.MouseButton2 then return "rmb" end
    if key == Enum.UserInputType.MouseButton3 then return "mouse3" end
    if key.EnumType == Enum.KeyCode then return key.Name:lower() end
    return "none"
end

--// Settings
local state = {
    ESP = false, ShowName = true, ShowDistance = true, ShowHealth = true, ShowTool = false,
    ShowBox = true, BoxStyle = "Full", BoxFill = false,
    ShowTracer = false, TracerOrigin = "Bottom", TracerThickness = 1,
    ShowHighlight = false, TeamColor = false, HideTeammates = false,
    FadeWithDistance = true, TextSize = 14,
    ESPColor = Color3.fromRGB(255, 255, 255),
    FriendColor = Color3.fromRGB(90, 170, 255),
    EnemyColor = Color3.fromRGB(255, 70, 70),
    MaxESPDistance = 3000,
    ShowSkeleton = false, ShowChams = false, ChamsOpacity = 50,
    OutlineGlobal = true, ChamsGlobal = true,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsColor = Color3.fromRGB(255, 255, 255),

    Lock = false, HoldMode = false, MaxLockDistance = 500,
    IgnoreTeammates = false,
    WallCheck = true, UseFOV = true, FOVRadius = 100,
    ShowFOV = true, Sensitivity = 0.4, LeashAngle = 20,
    TargetBone = "UpperTorso", RandomizeBone = false,
    LockKey = Enum.UserInputType.MouseButton2,
    CircleColor = Color3.fromRGB(255, 255, 255),
    MenuKey = Enum.KeyCode.RightShift,
    AimType = "Mouse",
    HealthCheck = false, StickyAim = false, Humanized = false,
    RageMethod = false, RageType = "Camera Teleport",
    Prediction = false, PredictionAmount = 0.3,

    SilentAim = false, SilentAimToggleKey = Enum.KeyCode.E,
    SilentAimKey = Enum.UserInputType.MouseButton1,
    SilentAimMode = "Always", SilentAimFOV = 80, SilentAimBone = "Head",
    SilentAimDistance = 500, SilentAimShowFOV = true,
    SilentAimWallCheck = false, SilentAimIgnoreTeammates = true,
    SilentAimHealthCheck = false, SilentAimSticky = false,
    SilentAimPrediction = false, SilentAimPredictionAmount = 0.3,

    TriggerBot = false, TriggerBotKey = Enum.KeyCode.Q,
    TriggerBotTeamCheck = true, TriggerBotWallCheck = true,
    TriggerBotHitboxMul = 1, TriggerBotDelay = 1, TriggerBotRelease = 10,

    Resolver = false,

    FPSUnlock = true, FPSCap = 9999,

    Fly = false, FlySpeed = 55, FlyKey = Enum.KeyCode.Unknown,
    Sprint = false, SprintSpeed = 25, SprintKey = Enum.KeyCode.Unknown,
    Noclip = false,
    Spin = false, SpinSpeed = 180,

    SkyPreset = "Off",
    JumpVisuals = false, JumpRainbow = false, JumpSize = 14, JumpColor = Color3.fromRGB(120, 200, 255),
    BloomOn = false, BloomIntensity = 1.2, BloomSize = 36, BloomThreshold = 0.4,
    ColorOn = false, ColorBrightness = 0, ColorContrast = 0.1, ColorSaturation = 0.2,
    ColorTint = Color3.fromRGB(255, 255, 255),
    StretchOn = false, StretchAmount = 70,
    TrailOn = false, TrailRainbow = false, TrailColor = Color3.fromRGB(255, 255, 255), TrailWidth = 1, TrailLength = 0.5,
    CrosshairOn = false, CrosshairStyle = "Cross", CrosshairColor = Color3.fromRGB(40, 160, 255), CrosshairSize = 8, CrosshairThickness = 2, CrosshairGap = 3, CrosshairOutline = true, CrosshairSpin = false, CrosshairSpinSpeed = 180,

    AntiFling = true,
    AntiAFK = true,
    NoSpread = false,

    SpamText = "ducksploit is tuff", SpamDelay = 4,
    TungMode = false,
}

local validBones = {
    Head = true, UpperTorso = true, LowerTorso = true,
    Torso = true, HumanoidRootPart = true,
}

local BOOL_PREFS = {
    "ESP", "ShowName", "ShowDistance", "ShowHealth", "ShowTool", "ShowBox", "BoxFill",
    "ShowTracer", "ShowHighlight", "TeamColor", "HideTeammates",
    "FadeWithDistance",
    "WallCheck", "UseFOV", "ShowFOV", "RandomizeBone", "HoldMode", "FPSUnlock",
    "AntiFling", "IgnoreTeammates", "ShowSkeleton", "ShowChams", "AntiAFK",
    "OutlineGlobal", "ChamsGlobal",
    "JumpVisuals", "JumpRainbow", "BloomOn", "ColorOn", "StretchOn", "NoSpread",
    "TrailOn", "TrailRainbow", "CrosshairOn", "CrosshairOutline", "CrosshairSpin",
    "SilentAim", "SilentAimWallCheck", "SilentAimIgnoreTeammates",
    "HealthCheck", "StickyAim", "Humanized", "RageMethod", "Prediction",
    "SilentAimHealthCheck", "SilentAimSticky", "SilentAimPrediction", "SilentAimShowFOV",
    "TriggerBot", "TriggerBotTeamCheck", "TriggerBotWallCheck", "Resolver",
    "TungMode",
}
local NUM_PREFS = {
    TextSize = {10, 22},
    MaxLockDistance = {20, 1000}, FOVRadius = {30, 600},
    Sensitivity = {0.05, 1}, LeashAngle = {5, 60}, FPSCap = {30, 9999},
    SprintSpeed = {16, 300}, FlySpeed = {10, 300}, SpamDelay = {0.1, 5.5},
    ChamsOpacity = {10, 100}, SpinSpeed = {30, 20000},
    JumpSize = {6, 40},
    BloomIntensity = {0, 3}, BloomSize = {0, 56}, BloomThreshold = {0, 2},
    ColorBrightness = {-0.5, 0.5}, ColorContrast = {-0.5, 1}, ColorSaturation = {-1, 2},
    StretchAmount = {40, 100},
    TrailWidth = {0.2, 3}, TrailLength = {0.1, 2},
    CrosshairSize = {2, 30}, CrosshairThickness = {1, 6}, CrosshairGap = {0, 20}, CrosshairSpinSpeed = {10, 1080},
    SilentAimFOV = {10, 600}, SilentAimDistance = {50, 2000},
    PredictionAmount = {0, 1}, SilentAimPredictionAmount = {0, 1},
    TriggerBotHitboxMul = {0.1, 3}, TriggerBotDelay = {0, 500}, TriggerBotRelease = {0, 500},
}
local STR_PREFS = {
    BoxStyle = {"Full", "Corners"},
    TracerOrigin = {"Bottom", "Center", "Mouse"},
    SilentAimMode = {"Always", "Hold"},
    AimType = {"Mouse", "Controller"},
    RageType = {"Camera Teleport", "Camera Lerp"},
    CrosshairStyle = {"Cross", "Dot", "Cross + Dot", "Big Yahu"},
    FlyMode = {"Velocity", "Swim"},
}
local COLOR_PREFS = {"ESPColor", "FriendColor", "EnemyColor", "CircleColor", "JumpColor", "ColorTint", "OutlineColor", "ChamsColor", "TrailColor", "CrosshairColor"}

local stateVersion = 0

--// Config
local Config = {
    folder = "Ducksploit",
    dir = "Ducksploit/configs",
    auto = "Ducksploit/autosave.json",
    refresh = {},
    toggles = {},
    visualApplies = {},
    cleanups = {},
    skies = {
        {name = "Default", ids = {
            "rbxasset://textures/sky/sky512_bk.tex", "rbxasset://textures/sky/sky512_dn.tex",
            "rbxasset://textures/sky/sky512_ft.tex", "rbxasset://textures/sky/sky512_lf.tex",
            "rbxasset://textures/sky/sky512_rt.tex", "rbxasset://textures/sky/sky512_up.tex",
        }},
        {name = "Snow", model = "4604073339"},
        {name = "Retro", model = "15081949"},
        {name = "Skybox HD", model = "16553683517"},
        {name = "Candy", model = "76584711398016"},
        {name = "Dark Matter", model = "110290405998332"},
        {name = "Scary Red Sky", model = "136055162054954"},
        {name = "Purple Sky", model = "570559352"},
    },
    after = nil,
    http = game:GetService("HttpService"),
    keyFallbacks = {
        LockKey = Enum.KeyCode.E, MenuKey = Enum.KeyCode.RightShift,
        FlyKey = Enum.KeyCode.Unknown, SprintKey = Enum.KeyCode.Unknown,
        SilentAimKey = Enum.UserInputType.MouseButton1,
        SilentAimToggleKey = Enum.KeyCode.E,
        TriggerBotKey = Enum.KeyCode.Q,
    },
}

function Config.hasFS()
    return type(writefile) == "function" and type(readfile) == "function"
        and type(isfile) == "function" and type(makefolder) == "function"
        and type(isfolder) == "function"
end

function Config.ensureFolders()
    pcall(function()
        if not isfolder(Config.folder) then makefolder(Config.folder) end
        if not isfolder(Config.dir) then makefolder(Config.dir) end
    end)
end

function Config.encodeColor(color)
    return {floor(color.R * 255 + 0.5), floor(color.G * 255 + 0.5), floor(color.B * 255 + 0.5)}
end

function Config.decodeColor(value)
    if typeof(value) == "Color3" then return value end
    if type(value) == "table" and isFiniteNumber(value[1]) and isFiniteNumber(value[2]) and isFiniteNumber(value[3]) then
        return Color3.fromRGB(clamp(value[1], 0, 255), clamp(value[2], 0, 255), clamp(value[3], 0, 255))
    end
    return nil
end

function Config.snapshot()
    local snap = {
        TargetBone = state.TargetBone,
        LockKey = keyToString(state.LockKey),
        MenuKey = keyToString(state.MenuKey),
        FlyKey = keyToString(state.FlyKey),
        SprintKey = keyToString(state.SprintKey),
        SilentAimKey = keyToString(state.SilentAimKey),
        SilentAimToggleKey = keyToString(state.SilentAimToggleKey),
        TriggerBotKey = keyToString(state.TriggerBotKey),
        SilentAimBone = state.SilentAimBone,
        SpamText = state.SpamText,
    }
    for _, key in ipairs(BOOL_PREFS) do snap[key] = state[key] end
    for key in pairs(NUM_PREFS) do snap[key] = state[key] end
    for key in pairs(STR_PREFS) do snap[key] = state[key] end
    for _, key in ipairs(COLOR_PREFS) do snap[key] = Config.encodeColor(state[key]) end
    return snap
end

function Config.parse(data)
    local out = {}
    if type(data) ~= "table" then return out end
    for _, key in ipairs(BOOL_PREFS) do
        if type(data[key]) == "boolean" then out[key] = data[key] end
    end
    for key, range in pairs(NUM_PREFS) do
        local value = data[key]
        if isFiniteNumber(value) then
            local scale = range[1] < 1 and 100 or 1
            out[key] = clamp(floor(value * scale + 0.5) / scale, range[1], range[2])
        end
    end
    for key, options in pairs(STR_PREFS) do
        local value = data[key]
        if type(value) == "string" and table.find(options, value) then out[key] = value end
    end
    for _, key in ipairs(COLOR_PREFS) do
        local color = Config.decodeColor(data[key])
        if color then out[key] = color end
    end
    if type(data.TargetBone) == "string" and validBones[data.TargetBone] then
        out.TargetBone = data.TargetBone
    end
    if type(data.SilentAimBone) == "string" and validBones[data.SilentAimBone] then
        out.SilentAimBone = data.SilentAimBone
    end
    if type(data.SpamText) == "string" and data.SpamText ~= "" then
        out.SpamText = data.SpamText:sub(1, 200)
    end
    for field, fallback in pairs(Config.keyFallbacks) do
        if data[field] ~= nil then out[field] = stringToKey(data[field], fallback) end
    end
    return out
end

function Config.apply(out, live)
    for key, value in pairs(out) do
        local set = live and Config.toggles[key]
        if set then set(value) else state[key] = value end
        local redraw = live and Config.refresh[key]
        if redraw then redraw() end
    end
    if live then
        stateVersion += 1
        if Config.after then pcall(Config.after) end
    end
end

function Config.readFile(path)
    if not Config.hasFS() then return nil end
    local ok, data = pcall(function()
        if not isfile(path) then return nil end
        return Config.http:JSONDecode(readfile(path))
    end)
    if ok and type(data) == "table" then return data end
    return nil
end

function Config.writeFile(path, snapshot)
    if not Config.hasFS() then return false end
    Config.ensureFolders()
    return (pcall(function() writefile(path, Config.http:JSONEncode(snapshot)) end))
end

function Config.cleanName(text)
    local name = tostring(text or ""):gsub("[^%w _%-]", "")
    name = name:match("^%s*(.-)%s*$")
    return name:sub(1, 32)
end

function Config.list()
    local names = {}
    if not Config.hasFS() or type(listfiles) ~= "function" then return names end
    Config.ensureFolders()
    pcall(function()
        for _, path in ipairs(listfiles(Config.dir)) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then names[#names + 1] = name end
        end
    end)
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

function Config.save(name)
    return Config.writeFile(Config.dir .. "/" .. name .. ".json", Config.snapshot())
end

function Config.load(name)
    local data = Config.readFile(Config.dir .. "/" .. name .. ".json")
    if not data then return false end
    Config.apply(Config.parse(data), true)
    return true
end

function Config.delete(name)
    if type(delfile) ~= "function" then return false end
    return (pcall(function() delfile(Config.dir .. "/" .. name .. ".json") end))
end

do
    local options = {"Off"}
    for _, entry in ipairs(Config.skies) do options[#options + 1] = entry.name end
    Config.skyOptions = options
    STR_PREFS.SkyPreset = options
end

do
    local source = genv.__ESP_LOCK_PREFS
    if type(source) ~= "table" then source = Config.readFile(Config.auto) end
    Config.apply(Config.parse(source), false)
end

state.Lock = false

local function savePreferences()
    local snapshot = Config.snapshot()
    genv.__ESP_LOCK_PREFS = snapshot
    Config.writeFile(Config.auto, snapshot)
end

local scheduleSave
do
    local saveQueued = false
    scheduleSave = function()
        stateVersion += 1
        if saveQueued then return end
        saveQueued = true
        task.delay(0.65, function()
            saveQueued = false
            savePreferences()
        end)
    end
end

--// Cleanup previous
do
    local prevUnload = genv.__ESP_LOCK_UNLOAD
    if type(prevUnload) == "function" then pcall(prevUnload) end
    genv.__ESP_LOCK_UNLOAD = nil
end

do
    local oldGui = PlayerGui:FindFirstChild("ESP_Lock_GUI")
    if oldGui then oldGui:Destroy() end
end

pcall(function() RunService:UnbindFromRenderStep(CFG.RENDER_BIND_NAME) end)
pcall(function() RunService:UnbindFromRenderStep(CFG.ESP_BIND_NAME) end)
pcall(function() ContextActionService:UnbindAction(CFG.CAMERA_BLOCK_ACTION) end)

pcall(function()
    for name in pairs(LocalPlayer:GetAttributes()) do
        if name:sub(1, #CFG.LEGACY_ATTR_PREFIX) == CFG.LEGACY_ATTR_PREFIX then
            LocalPlayer:SetAttribute(name, nil)
        end
    end
end)

for _, child in ipairs(PlayerGui:GetChildren()) do
    if child.Name == "LocalPlayerESP_Label" or child.Name == "LocalPlayerESPLabel" then
        child:Destroy()
    end
end
for _, player in ipairs(Players:GetPlayers()) do
    local character = player.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Highlight")
                and (child.Name == "LocalPlayerESP_Highlight" or child.Name == "LocalPlayerESP") then
                child:Destroy()
            end
        end
    end
end

local connections = {}

local targetPlayer, targetPart = nil, nil
local lockAcquired = false
local lockedRotation = nil
local smoothedAim = nil
local lockBound = false
local lockErrorWarned = false

local function trackConnection(connection)
    connections[#connections + 1] = connection
    return connection
end

local function getAlive(player)
    local character = player and player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    return character, humanoid
end

local function aimCenter()
    Camera = workspace.CurrentCamera
    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
        return UserInputService:GetMouseLocation()
    end
    return (Camera and Camera.ViewportSize or Vector2.zero) / 2
end

--// Resolver
local Resolver = (function()
    local history = setmetatable({}, {__mode = "k"})
    local stamp = setmetatable({}, {__mode = "k"})
    local function point(part)
        if not part then return nil end
        if not state.Resolver then return part.Position end
        local list = history[part]
        if not list then
            list = {}
            history[part] = list
        end
        -- one sample per ~frame, otherwise repeated calls in the same frame flood the history
        local now = os.clock()
        if now - (stamp[part] or 0) >= 1 / 120 then
            stamp[part] = now
            list[#list + 1] = part.Position
            if #list > 4 then table.remove(list, 1) end
        end
        local sum = Vector3.zero
        for i = 1, #list do sum += list[i] end
        return sum / #list
    end
    return { point = point }
end)()

--// Targeting
local hasLineOfSight
do
    local losParams = RaycastParams.new()
    losParams.FilterType = Enum.RaycastFilterType.Exclude
    losParams.IgnoreWater = true

    hasLineOfSight = function(part, character)
        if not Camera or not part or not character then return false end
        local localCharacter = LocalPlayer.Character
        losParams.FilterDescendantsInstances = localCharacter and {character, localCharacter} or {character}
        local origin = Camera.CFrame.Position
        return workspace:Raycast(origin, part.Position - origin, losParams) == nil
    end
end

local resolveTargetPart
do
    local randomBoneNames = {
        "Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart",
        "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
    }

    local boneFallbacks = {
        Head = {"Head"},
        UpperTorso = {"UpperTorso", "Torso", "HumanoidRootPart", "Head"},
        LowerTorso = {"LowerTorso", "Torso", "HumanoidRootPart", "Head"},
        Torso = {"Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
        HumanoidRootPart = {"HumanoidRootPart", "UpperTorso", "Torso", "Head"},
    }

    resolveTargetPart = function(character, boneName)
        if not character then return nil end
        if not boneName and state.RandomizeBone then
            local available = {}
            for _, name in ipairs(randomBoneNames) do
                local part = character:FindFirstChild(name)
                if part and part:IsA("BasePart") then available[#available + 1] = part end
            end
            if #available > 0 then return available[math.random(1, #available)] end
        end
        for _, name in ipairs(boneFallbacks[boneName or state.TargetBone] or boneFallbacks.UpperTorso) do
            local part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") then return part end
        end
        return character:FindFirstChildWhichIsA("BasePart")
    end
end

local function chooseTarget()
    Camera = workspace.CurrentCamera
    if not Camera then return nil, nil end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil, nil end

    local localPos = localRoot.Position
    local center = aimCenter()
    local maxDistance = state.MaxLockDistance
    local bestPlayer, bestPart, bestScore = nil, nil, huge

    for _, player in ipairs(Players:GetPlayers()) do
        local isTeammate = player.Team ~= nil and player.Team == LocalPlayer.Team
        if player ~= LocalPlayer and not (state.IgnoreTeammates and isTeammate) then
            local character, humanoid = getAlive(player)
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local healthOk = not state.HealthCheck
                or (humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead)
            if root and healthOk then
                local distance = (root.Position - localPos).Magnitude
                if distance <= maxDistance then
                    local aimPart = resolveTargetPart(character)
                    if aimPart then
                        local score = distance
                        local allowed = true
                        if state.UseFOV then
                            local screenPoint, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                            score = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                            allowed = onScreen and screenPoint.Z > 0 and score <= state.FOVRadius
                        end
                        if allowed and score < bestScore
                            and (not state.WallCheck or hasLineOfSight(aimPart, character)) then
                            bestPlayer, bestPart, bestScore = player, aimPart, score
                        end
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart
end

--// Lock
local cameraBlocked = false

local function sinkInput() return Enum.ContextActionResult.Sink end

local function setCameraBlock(on)
    if on == cameraBlocked then return end
    if on then
        cameraBlocked = pcall(function()
            ContextActionService:BindActionAtPriority(
                CFG.CAMERA_BLOCK_ACTION, sinkInput, false,
                Enum.ContextActionPriority.High.Value + 1000,
                Enum.UserInputType.MouseMovement, Enum.KeyCode.Thumbstick2
            )
        end)
    else
        pcall(function() ContextActionService:UnbindAction(CFG.CAMERA_BLOCK_ACTION) end)
        cameraBlocked = false
    end
end

local Wheel = {name = randomName(), on = false}

function Wheel.set(on)
    if on == Wheel.on then return end
    if on then
        Wheel.on = pcall(function()
            ContextActionService:BindActionAtPriority(
                Wheel.name, sinkInput, false,
                Enum.ContextActionPriority.High.Value + 2000,
                Enum.UserInputType.MouseWheel
            )
        end)
    else
        pcall(function() ContextActionService:UnbindAction(Wheel.name) end)
        Wheel.on = false
    end
end

local function releaseLock()
    setCameraBlock(false)
    targetPlayer, targetPart = nil, nil
    lockAcquired = false
    lockedRotation = nil
    smoothedAim = nil
end

local function dropTarget()
    targetPlayer, targetPart = nil, nil
    smoothedAim = nil
    lockAcquired = false
end

local function angleBetween(a, b)
    return acos(clamp(a.LookVector:Dot(b.LookVector), -1, 1))
end

-- relative-mouse aiming keeps its sub-pixel remainder here between frames
local MouseAim = {rx = 0, ry = 0}

local function usesMouseAim()
    return state.AimType == "Mouse" and type(mousemoverel) == "function"
end

local function lockStep(deltaTime)
    Camera = workspace.CurrentCamera
    if not Camera or not state.Lock then return end
    if not getAlive(LocalPlayer) then
        if lockAcquired or cameraBlocked then releaseLock() end
        return
    end

    deltaTime = clamp(
        (type(deltaTime) == "number" and deltaTime == deltaTime) and deltaTime or (1 / 60),
        1 / 240, 1 / 15
    )

    local mouseMode = usesMouseAim()

    if not lockAcquired then
        local selectedPlayer, selectedPart = chooseTarget()
        if not (selectedPlayer and selectedPart) then
            if cameraBlocked then releaseLock() end
            return
        end
        local wasBlocked = cameraBlocked
        targetPlayer, targetPart = selectedPlayer, selectedPart
        lockAcquired = true
        MouseAim.rx, MouseAim.ry = 0, 0
        if not wasBlocked or not lockedRotation then
            lockedRotation = Camera.CFrame.Rotation
        end
        setCameraBlock(not mouseMode)
    end

    -- switching Aim Type while locked: hand the camera back / take it over cleanly
    if mouseMode and cameraBlocked then
        setCameraBlock(false)
    elseif not mouseMode and not cameraBlocked then
        lockedRotation = Camera.CFrame.Rotation
        setCameraBlock(true)
    end

    if not targetPlayer or targetPlayer.Parent ~= Players then dropTarget(); return end
    local character = getAlive(targetPlayer)
    if not character then dropTarget(); return end
    if not targetPart or not targetPart:IsDescendantOf(character) then
        targetPart = resolveTargetPart(character)
        if not targetPart then return end
    end

    if state.WallCheck and not state.StickyAim and not hasLineOfSight(targetPart, character) then
        dropTarget()
        return
    end

    local rage = state.RageMethod
    local teleport = rage and state.RageType == "Camera Teleport"
    local smoothness = maxn(1, 1 + (1 - state.Sensitivity) * 19)

    local rawAim = Resolver.point(targetPart) or targetPart.Position
    if state.Prediction then
        local troot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if troot then
            rawAim += troot.AssemblyLinearVelocity * (state.PredictionAmount * 0.35)
        end
    end
    if rage or smoothness <= 1 or not smoothedAim or (smoothedAim - rawAim).Magnitude > 30 then
        smoothedAim = rawAim
    else
        smoothedAim = smoothedAim:Lerp(rawAim, 1 - exp(-60 * deltaTime))
    end
    local aimPosition = smoothedAim

    -- Mouse aim type: drive the real cursor with relative mouse movement
    if mouseMode then
        local screenPoint = Camera:WorldToViewportPoint(aimPosition)
        if screenPoint.Z <= 0 then
            local rel = Camera.CFrame:PointToObjectSpace(aimPosition)
            pcall(mousemoverel, rel.X >= 0 and 80 or -80, 0)
            return
        end
        local mouseLocation = UserInputService:GetMouseLocation()
        local dx, dy = screenPoint.X - mouseLocation.X, screenPoint.Y - mouseLocation.Y
        local errLen = sqrt(dx * dx + dy * dy)

        local alpha = 1
        if teleport then
            alpha = 1
        elseif rage then
            alpha = 1 - exp(-45 * deltaTime)
        elseif smoothness > 1 then
            alpha = 1 - exp(-(60 / (smoothness ^ 0.65)) * deltaTime)
        end

        -- hard leash: after correction the cursor may never sit further than leashPx from the target
        if not rage and errLen > 0.001 then
            local pxPerDeg = Camera.ViewportSize.Y / maxn(Camera.FieldOfView, 1)
            local leashPx = maxn(2, pxPerDeg * state.LeashAngle * 0.05)
            if errLen * (1 - alpha) > leashPx then
                alpha = 1 - leashPx / errLen
            end
        end
        dx, dy = dx * alpha, dy * alpha

        if state.Humanized then
            dx += (math.random() - 0.5) * 0.8
            dy += (math.random() - 0.5) * 0.8
        end

        MouseAim.rx += dx
        MouseAim.ry += dy
        local ix = MouseAim.rx >= 0 and floor(MouseAim.rx) or math.ceil(MouseAim.rx)
        local iy = MouseAim.ry >= 0 and floor(MouseAim.ry) or math.ceil(MouseAim.ry)
        MouseAim.rx -= ix
        MouseAim.ry -= iy
        if ix ~= 0 or iy ~= 0 then pcall(mousemoverel, ix, iy) end
        return
    end

    -- Controller aim type: drive the camera itself
    if not lockedRotation or lockedRotation.X ~= lockedRotation.X then
        lockedRotation = Camera.CFrame.Rotation
    end

    local controllerCFrame = Camera.CFrame
    local focusPosition = Camera.Focus.Position
    local localOffset = controllerCFrame.Rotation:Inverse() * (controllerCFrame.Position - focusPosition)
    local useOrbit = localOffset.Magnitude < 200
        and (focusPosition - controllerCFrame.Position).Magnitude < 200

    local function positionFor(rotation)
        return useOrbit and (focusPosition + rotation * localOffset) or controllerCFrame.Position
    end

    local cameraPosition = positionFor(lockedRotation)

    if (aimPosition - cameraPosition).Magnitude < 0.05 then
        Camera.CFrame = CFrame.new(cameraPosition) * lockedRotation
        return
    end

    local desiredRotation = CFrame.lookAt(cameraPosition, aimPosition).Rotation
    if useOrbit then
        for _ = 1, 2 do
            local p = positionFor(desiredRotation)
            if (aimPosition - p).Magnitude < 0.05 then break end
            desiredRotation = CFrame.lookAt(p, aimPosition).Rotation
        end
    end

    if rage then
        -- Camera Teleport snaps instantly; Camera Lerp closes the gap very fast but still eases
        local alpha = teleport and 1 or (1 - exp(-45 * deltaTime))
        lockedRotation = lockedRotation:Lerp(desiredRotation, alpha)
    else
        local alpha = 1
        if smoothness > 1 then
            alpha = 1 - exp(-(60 / (smoothness ^ 0.65)) * deltaTime)
        end

        local leash = rad(state.LeashAngle)
        local errBefore = angleBetween(lockedRotation, desiredRotation)
        local boost = clamp((errBefore / leash - 0.6) / 0.4, 0, 1)
        alpha = clamp(alpha + (1 - alpha) * boost * boost, 0, 1)

        lockedRotation = lockedRotation:Lerp(desiredRotation, alpha)
        local errAfter = angleBetween(lockedRotation, desiredRotation)
        if errAfter > leash then
            lockedRotation = lockedRotation:Lerp(desiredRotation, 1 - leash / errAfter)
        end
    end

    if state.Humanized then
        local jitter = CFrame.Angles(
            (math.random() - 0.5) * 0.003, (math.random() - 0.5) * 0.003, 0
        )
        lockedRotation = lockedRotation * jitter
    end

    Camera.CFrame = CFrame.new(positionFor(lockedRotation)) * lockedRotation
end

local function safeLockStep(deltaTime)
    local ok, err = pcall(lockStep, deltaTime)
    if not ok and not lockErrorWarned then
        lockErrorWarned = true
        warn("[HUD] camlock error (camlock stays active):", err)
    end
end

local function bindLock()
    if lockBound then return end
    lockBound = pcall(function()
        RunService:BindToRenderStep(CFG.RENDER_BIND_NAME, Enum.RenderPriority.Last.Value, safeLockStep)
    end)
end

local function unbindLock()
    setCameraBlock(false)
    pcall(function() RunService:UnbindFromRenderStep(CFG.RENDER_BIND_NAME) end)
    lockBound = false
end

--// Silent Aim
local SilentAim = (function()
    local lastTarget, lastPart, lastSeenAt = nil, nil, 0
    local lastPick = 0

    local function held()
        if state.SilentAimMode == "Hold" then
            local ok, down = pcall(function()
                if state.SilentAimKey.EnumType == Enum.UserInputType then
                    return UserInputService:IsMouseButtonPressed(state.SilentAimKey)
                end
                return UserInputService:IsKeyDown(state.SilentAimKey)
            end)
            return ok and down
        end
        return true
    end

    local function pick()
        Camera = workspace.CurrentCamera
        if not Camera then return nil, nil end
        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then return nil, nil end

        local localPos = localRoot.Position
        local center = aimCenter()
        local bestPlayer, bestPart, bestScore = nil, nil, huge

        for _, player in ipairs(Players:GetPlayers()) do
            local isTeammate = player.Team ~= nil and player.Team == LocalPlayer.Team
            if player ~= LocalPlayer and not (state.SilentAimIgnoreTeammates and isTeammate) then
                local character, humanoid = getAlive(player)
                if character then
                    local healthOk = not state.SilentAimHealthCheck
                        or humanoid:GetState() ~= Enum.HumanoidStateType.Dead
                    local troot = character:FindFirstChild("HumanoidRootPart")
                    local distOk = troot and (troot.Position - localPos).Magnitude <= state.SilentAimDistance
                    if healthOk and distOk then
                        local part = resolveTargetPart(character, state.SilentAimBone)
                        if part then
                            local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen and screenPoint.Z > 0 then
                                local score = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                                if score <= state.SilentAimFOV and score < bestScore
                                    and (not state.SilentAimWallCheck or hasLineOfSight(part, character)) then
                                    bestPlayer, bestPart, bestScore = player, part, score
                                end
                            end
                        end
                    end
                end
            end
        end
        return bestPlayer, bestPart
    end

    -- refreshed at most every 0.05s: called from inside the namecall hook, must stay cheap
    local function resolve()
        local now = os.clock()
        if now - lastPick > 0.05 or not lastTarget or lastTarget.Parent ~= Players then
            lastPick = now
            local p, part = pick()
            if p then
                lastTarget, lastPart, lastSeenAt = p, part, now
            end
        end
        local window = state.SilentAimSticky and 0.25 or 0.06
        if lastTarget and lastPart and lastPart.Parent and (now - lastSeenAt) <= window then
            return lastPart
        end
        return nil
    end

    local function aimOrigin()
        Camera = workspace.CurrentCamera
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then return root.Position end
        return Camera and Camera.CFrame.Position or Vector3.zero
    end

    -- current aim point for the silent-aim hooks (nil when silent aim is off / nothing in range)
    local function target()
        if not (state.SilentAim and held()) then return nil end
        local part = resolve()
        if not part then return nil end
        local point = Resolver.point(part) or part.Position
        if state.SilentAimPrediction then
            local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
            if root then
                point += root.AssemblyLinearVelocity * (state.SilentAimPredictionAmount * 0.35)
            end
        end
        return part, point
    end

    return { resolve = resolve, held = held, aimOrigin = aimOrigin, target = target }
end)()

do
    local isOurs = type(checkcaller) == "function" and checkcaller or function() return false end

    local mouse = nil
    pcall(function() mouse = LocalPlayer:GetMouse() end)

    -- only redirect rays that look like weapon shots: long, and starting near the camera or the character
    local function plausibleShot(origin, direction)
        if direction.Magnitude < 40 then return false end
        local cam = workspace.CurrentCamera
        if cam and (origin - cam.CFrame.Position).Magnitude <= 15 then return true end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        return root ~= nil and (origin - root.Position).Magnitude <= 20
    end

    local SHOT_NAMES = {
        "shoot", "fire", "hit", "dmg", "damage", "bullet", "gun", "weapon",
        "shot", "attack", "projectile", "cast", "aim", "target", "swing", "throw",
    }

    -- only touch remotes that look like shots, or any remote while a tool is equipped
    local function looksLikeShotRemote(remote)
        local name = tostring(remote.Name):lower()
        for _, word in ipairs(SHOT_NAMES) do
            if name:find(word, 1, true) then return true end
        end
        local char = LocalPlayer.Character
        return char ~= nil and char:FindFirstChildOfClass("Tool") ~= nil
    end

    -- positions near the camera / character are ray origins, never retarget them
    local function nearOrigin(position)
        local cam = workspace.CurrentCamera
        if cam and (position - cam.CFrame.Position).Magnitude <= 12 then return true end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        return root ~= nil and (position - root.Position).Magnitude <= 12
    end

    local function rewriteArgs(args, aimPoint)
        local origin = nil
        for i = 1, args.n do
            local value = args[i]
            local kind = typeof(value)
            if kind == "CFrame" then
                args[i] = CFrame.new(value.Position, aimPoint)
            elseif kind == "Vector3" then
                local magnitude = value.Magnitude
                if magnitude > 1.5 then
                    if not nearOrigin(value) then args[i] = aimPoint end
                elseif magnitude > 1e-3 then
                    origin = origin or SilentAim.aimOrigin()
                    args[i] = (aimPoint - origin).Unit
                end
            end
        end
    end

        -- remote args, workspace raycasts, legacy FindPartOnRay and camera ray helpers
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if not state.SilentAim then return oldNamecall(self, ...) end
            local method = getnamecallmethod()
            if isOurs() then return oldNamecall(self, ...) end

            -- inner namecalls below overwrite the namecall method, so restore it before passing through
            local function pass(...)
                setnamecallmethod(method)
                return oldNamecall(self, ...)
            end

            if method == "FireServer" or method == "InvokeServer" then
                if looksLikeShotRemote(self) then
                    local part, point = SilentAim.target()
                    if part then
                        local args = table.pack(...)
                        rewriteArgs(args, point)
                        return pass(table.unpack(args, 1, args.n))
                    end
                end
            elseif method == "Raycast" then
                local origin, direction = ...
                if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" and plausibleShot(origin, direction) then
                    local part, point = SilentAim.target()
                    if part then
                        return pass(origin, (point - origin).Unit * direction.Magnitude, select(3, ...))
                    end
                end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList"
                or method == "FindPartOnRayWithWhitelist" then
                local ray = ...
                if typeof(ray) == "Ray" and plausibleShot(ray.Origin, ray.Direction) then
                    local part, point = SilentAim.target()
                    if part then
                        return pass(Ray.new(ray.Origin, (point - ray.Origin).Unit * ray.Direction.Magnitude), select(2, ...))
                    end
                end
            elseif method == "ScreenPointToRay" or method == "ViewportPointToRay" then
                if self == workspace.CurrentCamera then
                    local ray = pass(...)
                    local part, point = SilentAim.target()
                    if part and typeof(ray) == "Ray" then
                        return Ray.new(ray.Origin, (point - ray.Origin).Unit * ray.Direction.Magnitude)
                    end
                    return ray
                end
            end

            return pass(...)
        end))
    end)

    -- games that read Mouse.Hit / Mouse.Target / Mouse.UnitRay to aim.
    -- __index is hot, so this hook is only installed the first time silent aim is switched on.
    local mouseHookInstalled = false
    local function installMouseHook()
        if mouseHookInstalled or not mouse then return end
        mouseHookInstalled = true
        pcall(function()
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if state.SilentAim and rawequal(self, mouse) and not isOurs() then
                if key == "Hit" or key == "Target" or key == "UnitRay" then
                    local part, point = SilentAim.target()
                    if part then
                        if key == "Hit" then return CFrame.new(point) end
                        if key == "Target" then return part end
                        local cam = workspace.CurrentCamera
                        local from = cam and cam.CFrame.Position or SilentAim.aimOrigin()
                        return Ray.new(from, (point - from).Unit)
                    end
                end
            end
            return oldIndex(self, key)
        end))
        end)
    end
    SilentAim.installMouseHook = installMouseHook
    if state.SilentAim then installMouseHook() end
end

--// Trigger Bot
local TriggerBot = (function()
    local conn = nil
    local firing = false

    local function targetUnderCrosshair()
        Camera = workspace.CurrentCamera
        if not Camera then return nil end
        local center = aimCenter()
        local fov = 36 * maxn(state.TriggerBotHitboxMul, 0.05)
        local best, bestDist = nil, huge

        for _, player in ipairs(Players:GetPlayers()) do
            local isTeammate = player.Team ~= nil and player.Team == LocalPlayer.Team
            if player ~= LocalPlayer and not (state.TriggerBotTeamCheck and isTeammate) then
                local character = getAlive(player)
                if character then
                    local part = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
                    if part then
                        local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen and screenPoint.Z > 0 then
                            local d = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                            if d <= fov and d < bestDist
                                and (not state.TriggerBotWallCheck or hasLineOfSight(part, character)) then
                                best, bestDist = player, d
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function fire()
        if firing then return end
        firing = true
        task.delay(maxn(state.TriggerBotDelay, 0) / 1000, function()
            if not state.TriggerBot then firing = false; return end
            pcall(function()
                if type(mouse1press) == "function" then mouse1press() end
            end)
            task.delay(maxn(state.TriggerBotRelease, 0) / 1000, function()
                pcall(function()
                    if type(mouse1release) == "function" then mouse1release() end
                end)
                firing = false
            end)
        end)
    end

    local function step()
        if not state.TriggerBot then return end
        if targetUnderCrosshair() then fire() end
    end

    local function stop()
        if conn then conn:Disconnect(); conn = nil end
        firing = false
        pcall(function()
            if type(mouse1release) == "function" then mouse1release() end
        end)
    end

    local function start()
        stop()
        conn = RunService.Heartbeat:Connect(step)
    end

    return { start = start, stop = stop }
end)()

--// Spectate
local spectateTarget = nil
local spectateStatus = nil
local setLockEnabled = nil
local playerRows = {}
local rowBase

local spectateYaw, spectatePitch = 0, -0.15
local spectateLooking = false
local spectateLosParams = RaycastParams.new()
spectateLosParams.FilterType = Enum.RaycastFilterType.Exclude
spectateLosParams.IgnoreWater = true

local function updateSpectateStatus()
    local name = spectateTarget and spectateTarget.DisplayName
    if spectateStatus then
        spectateStatus.Text = name and ("Spectating: " .. name) or ""
    end
    if rowBase then
        for player, row in pairs(playerRows) do
            tween(row, {BackgroundColor3 = rowBase(player)}, 0.15)
            local sb = row:FindFirstChild("SpectateBtn", true)
            if sb then sb.Text = (spectateTarget == player) and "STOP" or "SPECTATE" end
        end
    end
end

local function resetCamera()
    local camera = workspace.CurrentCamera
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if camera then camera.CameraType = Enum.CameraType.Custom end
    if camera and humanoid then camera.CameraSubject = humanoid end
    if spectateLooking then
        spectateLooking = false
        pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
    end
end

local function spectateCameraStep()
    if not spectateTarget then return end
    local character = spectateTarget.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    if not humanoid or not root or not camera then return end
    if camera.CameraType ~= Enum.CameraType.Scriptable then camera.CameraType = Enum.CameraType.Scriptable end

    local focus = root.Position + Vector3.new(0, 2, 0)
    local rotation = CFrame.Angles(0, spectateYaw, 0) * CFrame.Angles(spectatePitch, 0, 0)
    local camPos = focus + rotation * Vector3.new(0, 0, CFG.SPECTATE_DISTANCE)

    local localCharacter = LocalPlayer.Character
    spectateLosParams.FilterDescendantsInstances = localCharacter and {character, localCharacter} or {character}
    local hit = workspace:Raycast(focus, camPos - focus, spectateLosParams)
    if hit then camPos = hit.Position + hit.Normal * 0.3 end

    camera.CFrame = CFrame.lookAt(camPos, focus)
end

local function stopSpectating()
    if not spectateTarget then return end
    spectateTarget = nil
    updateSpectateStatus()
    resetCamera()
end

local function spectate(player)
    if player == LocalPlayer or player.Parent ~= Players then return end
    local _, humanoid = getAlive(player)
    if not humanoid then return end
    if state.Lock and setLockEnabled then setLockEnabled(false) end
    spectateTarget = player
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    spectateCameraStep()
    updateSpectateStatus()
end

local function cycleSpectate(direction)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getAlive(player) then list[#list + 1] = player end
    end
    if #list == 0 then return end
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    local index = table.find(list, spectateTarget) or 0
    index = (index - 1 + direction) % #list + 1
    spectate(list[index])
end

--// FPS unlocker
local setCap = nil
do
    local ok, fn = pcall(function() return setfpscap end)
    if ok and type(fn) == "function" then setCap = fn end
end

local function applyFPS()
    if not setCap then return end
    pcall(setCap, state.FPSUnlock and state.FPSCap or CFG.FPS_DEFAULT)
end

--// GUI root
local function getGuiParent()
    local ok, holder = pcall(function() return type(gethui) == "function" and gethui() or nil end)
    if ok and typeof(holder) == "Instance" then return holder end
    return PlayerGui
end

local gui = Instance.new("ScreenGui")
gui.Name = CFG.GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getGuiParent()

local function newStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness
    s.Parent = parent
    return s
end

local playerList, lodBias, clearAllESP, removeESP, safeEspStep, Rel
do
--// ESP engine
local espLayer = Instance.new("Frame")
espLayer.Name = "ESPLayer"
espLayer.BackgroundTransparency = 1
espLayer.BorderSizePixel = 0
espLayer.Size = UDim2.fromScale(1, 1)
espLayer.ZIndex = 1
espLayer.Parent = gui

local espObjects = {}
playerList = Players:GetPlayers()
lodBias = 0
local lastEspError = nil

Rel = {map = genv.__ESP_LOCK_REL}
do
    local HttpService = game:GetService("HttpService")
    local FILE = "BunHub_Relations.json"
    if type(Rel.map) ~= "table" then
        Rel.map = {}
        pcall(function()
            if type(isfile) == "function" and type(readfile) == "function" and isfile(FILE) then
                local data = HttpService:JSONDecode(readfile(FILE))
                for _, id in ipairs(data.friends or {}) do Rel.map[id] = "friend" end
                for _, id in ipairs(data.enemies or {}) do Rel.map[id] = "enemy" end
            end
        end)
        genv.__ESP_LOCK_REL = Rel.map
    end
    function Rel.save()
        pcall(function()
            if type(writefile) ~= "function" then return end
            local friends, enemies = {}, {}
            for id, kind in pairs(Rel.map) do
                if kind == "friend" then friends[#friends + 1] = id else enemies[#enemies + 1] = id end
            end
            writefile(FILE, HttpService:JSONEncode({friends = friends, enemies = enemies}))
        end)
    end
end

local TOP_OFFSET = Vector3.new(0, 2.7, 0)
local BOT_OFFSET = Vector3.new(0, 3.1, 0)
local HP_GREEN = Color3.fromRGB(90, 255, 120)
local HP_RED = Color3.fromRGB(255, 70, 70)
local SUB_TEXT = Color3.fromRGB(215, 215, 215)

local function newFrame(parent, z)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = z or 1
    f.Parent = parent
    return f
end


local function newText(parent, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
    l.TextColor3 = WHITE
    l.ZIndex = 3
    l.TextWrapped = false
    l.Parent = parent
    local s = newStroke(l, BLACK, 1.5)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    return l, s
end

local function setRect(frame, x, y, w, h)
    frame.Position = UDim2.fromOffset(x, y)
    frame.Size = UDim2.fromOffset(w, h)
end

function removeESP(player)
    local obj = espObjects[player]
    if not obj then return end
    espObjects[player] = nil
    if obj.highlight then pcall(function() obj.highlight:Destroy() end) end
    pcall(function() obj.container:Destroy() end)
end

function clearAllESP()
    for player in pairs(espObjects) do removeESP(player) end
end

local function buildESP(player)
    local container = newFrame(espLayer, 1)
    container.Name = player.Name
    container.Visible = false

    local tracer = newFrame(container, 1)
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BackgroundTransparency = 0
    tracer.BackgroundColor3 = WHITE
    tracer.Visible = false
    local tracerStroke = newStroke(tracer, BLACK, 1)
    tracerStroke.Transparency = 0.35

    local group = newFrame(container, 1)

    local boxFull = newFrame(group, 1)
    local boxOut = newFrame(boxFull, 1)
    newStroke(boxOut, BLACK, 1)
    local box = newFrame(boxFull, 2)
    local boxStroke = newStroke(box, WHITE, 1)
    local boxIn = newFrame(boxFull, 1)
    newStroke(boxIn, BLACK, 1)

    local boxCorners = newFrame(group, 1)
    local corners = {}
    for i = 1, 8 do
        local c = newFrame(boxCorners, 2)
        c.BackgroundTransparency = 0
        c.BackgroundColor3 = WHITE
        newStroke(c, BLACK, 1)
        corners[i] = c
    end

    local nameLabel, nameStroke = newText(group, true)
    nameLabel.AnchorPoint = Vector2.new(0.5, 1)
    nameLabel.Text = player.DisplayName

    local distLabel, distStroke = newText(group, false)
    distLabel.AnchorPoint = Vector2.new(0.5, 0)
    distLabel.TextColor3 = SUB_TEXT

    local toolLabel, toolStroke = newText(group, false)
    toolLabel.AnchorPoint = Vector2.new(0.5, 0)
    toolLabel.TextColor3 = SUB_TEXT

    local hpBack = newFrame(group, 2)
    hpBack.BackgroundTransparency = 0.35
    hpBack.BackgroundColor3 = BLACK
    newStroke(hpBack, BLACK, 1)
    local hpFill = newFrame(hpBack, 3)
    hpFill.AnchorPoint = Vector2.new(0, 1)
    hpFill.Position = UDim2.fromScale(0, 1)
    hpFill.Size = UDim2.fromScale(1, 1)
    hpFill.BackgroundTransparency = 0
    hpFill.BackgroundColor3 = HP_GREEN

    -- friend / enemy face icon shown beside the name (":)" / ":(" turned a quarter turn)
    local icon = newFrame(group, 3)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Size = UDim2.fromOffset(16, 16)
    icon.Visible = false
    round(icon, 8).CornerRadius = UDim.new(0.5, 0)
    local iconStroke = newStroke(icon, WHITE, 1.5)
    local iconText = Instance.new("TextLabel")
    iconText.AnchorPoint = Vector2.new(0.5, 0.5)
    iconText.Position = UDim2.fromScale(0.5, 0.5)
    iconText.Size = UDim2.fromScale(1, 1)
    iconText.BackgroundTransparency = 1
    iconText.Font = Enum.Font.GothamBold
    iconText.TextSize = 10
    iconText.TextColor3 = WHITE
    iconText.Text = ":)"
    iconText.Rotation = 90
    iconText.ZIndex = 4
    iconText.Parent = icon

    local obj = {
        container = container, group = group, tracer = tracer,
        boxFull = boxFull, boxOut = boxOut, box = box, boxStroke = boxStroke, boxIn = boxIn,
        boxCorners = boxCorners, corners = corners,
        nameLabel = nameLabel, distLabel = distLabel, toolLabel = toolLabel,
        texts = {{nameLabel, nameStroke}, {distLabel, distStroke}, {toolLabel, toolStroke}},
        hpBack = hpBack, hpFill = hpFill,
        icon = icon, iconStroke = iconStroke, iconText = iconText, iconKind = nil,

        character = nil, humanoid = nil, root = nil, highlight = nil,
        shown = false, onScreen = true, tracerVis = false,
        skip = 0, ver = -1, fade = -1, hpQ = -1, mark = nil,
        toolName = "", toolAt = 0,
        distInt = -1, nameText = player.DisplayName,
        color = nil,
        lx = nil, ly = nil, lw = nil, lh = nil,
    }
    espObjects[player] = obj
    return obj
end

local function hideESP(obj)
    if obj.shown then
        obj.shown = false
        obj.container.Visible = false
    end
    if obj.highlight then
        obj.highlight:Destroy()
        obj.highlight = nil
    end
end

local function refreshTextVisibility(obj)
    obj.nameLabel.Visible = state.ShowName
    obj.distLabel.Visible = state.ShowDistance
    obj.toolLabel.Visible = state.ShowTool and obj.toolName ~= ""
end

local function applySettings(obj)
    obj.ver = stateVersion
    local ts = state.TextSize

    obj.nameLabel.TextSize = ts
    obj.nameLabel.Size = UDim2.fromOffset(220, ts + 2)
    obj.distLabel.TextSize = ts - 2
    obj.distLabel.Size = UDim2.fromOffset(220, ts)
    obj.toolLabel.TextSize = ts - 2
    obj.toolLabel.Size = UDim2.fromOffset(220, ts)

    refreshTextVisibility(obj)
    obj.hpBack.Visible = state.ShowHealth
    obj.boxFull.Visible = state.ShowBox and state.BoxStyle == "Full"
    obj.boxCorners.Visible = state.ShowBox and state.BoxStyle == "Corners"
    obj.box.BackgroundTransparency = state.BoxFill and 0.85 or 1

    obj.tracerVis = false
    obj.tracer.Visible = false

    obj.color = nil
    obj.fade = -1
    obj.hpQ = -1
    obj.toolAt = 0
    obj.distInt = -1
    obj.lx = nil
end

local function applyColor(obj, color)
    obj.color = color
    obj.nameLabel.TextColor3 = color
    obj.boxStroke.Color = color
    obj.box.BackgroundColor3 = color
    for i = 1, 8 do obj.corners[i].BackgroundColor3 = color end
    obj.tracer.BackgroundColor3 = color
    obj.iconStroke.Color = color
    obj.iconText.TextColor3 = color
    if obj.highlight then
        obj.highlight.OutlineColor = state.OutlineGlobal and color or state.OutlineColor
        obj.highlight.FillColor = state.ChamsGlobal and color or state.ChamsColor
    end
    if obj.lines then
        for i = 1, #obj.lines do obj.lines[i].BackgroundColor3 = color end
    end
end

local function applyFade(obj, fade)
    obj.fade = fade
    for i = 1, 3 do
        local t = obj.texts[i]
        t[1].TextTransparency = fade
        t[2].Transparency = fade
    end
    obj.boxStroke.Transparency = fade
    for i = 1, 8 do obj.corners[i].BackgroundTransparency = fade end
    obj.tracer.BackgroundTransparency = fade
    obj.hpFill.BackgroundTransparency = fade
    obj.hpBack.BackgroundTransparency = 0.35 + fade * 0.65
    if obj.lines then
        for i = 1, #obj.lines do
            obj.lines[i].BackgroundTransparency = fade
            obj.lineStrokes[i].Transparency = 0.5 + fade * 0.5
        end
    end
end

local function layoutESP(obj, x, y, bw, bh)
    local ts = state.TextSize
    local cx = x + floor(bw / 2)

    if state.ShowBox then
        if state.BoxStyle == "Full" then
            setRect(obj.boxOut, x - 1, y - 1, bw + 2, bh + 2)
            setRect(obj.box, x, y, bw, bh)
            setRect(obj.boxIn, x + 1, y + 1, maxn(bw - 2, 0), maxn(bh - 2, 0))
        else
            local len = clamp(floor(minn(bw, bh) * 0.28), 3, 40)
            local t = 2
            local c = obj.corners
            setRect(c[1], x, y, len, t)
            setRect(c[2], x, y, t, len)
            setRect(c[3], x + bw - len, y, len, t)
            setRect(c[4], x + bw - t, y, t, len)
            setRect(c[5], x, y + bh - t, len, t)
            setRect(c[6], x, y + bh - len, t, len)
            setRect(c[7], x + bw - len, y + bh - t, len, t)
            setRect(c[8], x + bw - t, y + bh - len, t, len)
        end
    end

    obj.nameLabel.Position = UDim2.fromOffset(cx, y - 3)
    local yy = y + bh + 2
    obj.distLabel.Position = UDim2.fromOffset(cx, yy)
    if state.ShowDistance then yy += ts - 1 end
    obj.toolLabel.Position = UDim2.fromOffset(cx, yy)
    setRect(obj.hpBack, x - 7, y, 3, bh)
end

local function clipToViewport(cx, cy, tx, ty, vw, vh)
    local m = 3
    if tx >= m and tx <= vw - m and ty >= m and ty <= vh - m then return tx, ty end
    local dx, dy = tx - cx, ty - cy
    local s = 1
    if tx < m then s = minn(s, (m - cx) / dx)
    elseif tx > vw - m then s = minn(s, (vw - m - cx) / dx) end
    if ty < m then s = minn(s, (m - cy) / dy)
    elseif ty > vh - m then s = minn(s, (vh - m - cy) / dy) end
    return cx + dx * s, cy + dy * s
end

--// Skeleton
local Skeleton = {
    R15 = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    },
    R6 = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
    },
    cache = {},
}

function Skeleton.build(obj, character, humanoid)
    local map = humanoid.RigType == Enum.HumanoidRigType.R15 and Skeleton.R15 or Skeleton.R6
    obj.skelChar = character
    obj.skelMap = map
    obj.joints = {}
    for i = 1, #map do obj.joints[i] = {false, false} end

    while #obj.lines < #map do
        local line = Instance.new("Frame")
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.BorderSizePixel = 0
        line.BackgroundColor3 = obj.color or WHITE
        line.BackgroundTransparency = maxn(obj.fade, 0)
        line.Size = UDim2.fromOffset(0, 1)
        line.ZIndex = 2
        line.Visible = false
        line.Parent = obj.skel
        local stroke = newStroke(line, BLACK, 1)
        stroke.Transparency = 0.5 + maxn(obj.fade, 0) * 0.5
        obj.lines[#obj.lines + 1] = line
        obj.lineStrokes[#obj.lineStrokes + 1] = stroke
    end
    for i = #map + 1, #obj.lines do obj.lines[i].Visible = false end
end

function Skeleton.project(camera, part)
    local point = Skeleton.cache[part]
    if point == nil then
        local v = camera:WorldToViewportPoint(part.Position)
        point = v.Z > 0 and v or false
        Skeleton.cache[part] = point
    end
    return point
end

function Skeleton.update(obj, camera, character, humanoid)
    if not obj.skel then
        obj.skel = newFrame(obj.container, 1)
        obj.skel.Name = "Skeleton"
        obj.lines, obj.lineStrokes = {}, {}
    end
    if obj.skelChar ~= character then Skeleton.build(obj, character, humanoid) end
    if not obj.skel.Visible then obj.skel.Visible = true end

    local map, joints, lines = obj.skelMap, obj.joints, obj.lines
    table.clear(Skeleton.cache)

    for i = 1, #map do
        local pair, slot, line = map[i], joints[i], lines[i]
        local a, b = slot[1], slot[2]
        if not a or not a.Parent then
            local found = character:FindFirstChild(pair[1])
            a = (found and found:IsA("BasePart")) and found or false
            slot[1] = a
        end
        if not b or not b.Parent then
            local found = character:FindFirstChild(pair[2])
            b = (found and found:IsA("BasePart")) and found or false
            slot[2] = b
        end

        local pa = a and Skeleton.project(camera, a)
        local pb = b and Skeleton.project(camera, b)
        if pa and pb then
            local dx, dy = pb.X - pa.X, pb.Y - pa.Y
            line.Position = UDim2.fromOffset((pa.X + pb.X) * 0.5, (pa.Y + pb.Y) * 0.5)
            line.Size = UDim2.fromOffset(sqrt(dx * dx + dy * dy), 1)
            line.Rotation = deg(atan2(dy, dx))
            if not line.Visible then line.Visible = true end
        elseif line.Visible then
            line.Visible = false
        end
    end
end

local function updateESP(player, camera, viewport, mouse, origin, now)
    local obj = espObjects[player]
    local character = player.Character
    if not character then
        if obj then hideESP(obj) end
        return
    end

    if obj and obj.skip > 0 then
        obj.skip -= 1
        return
    end

    local mark = Rel.map[player.UserId]
    if not mark and state.HideTeammates and player.Team ~= nil and player.Team == LocalPlayer.Team then
        if obj then hideESP(obj); obj.skip = 5 end
        return
    end

    local humanoid, root
    if obj and obj.character == character
        and obj.humanoid and obj.humanoid.Parent
        and obj.root and obj.root.Parent then
        humanoid, root = obj.humanoid, obj.root
    else
        humanoid = character:FindFirstChildOfClass("Humanoid")
        root = character:FindFirstChild("HumanoidRootPart")
        if obj then
            if obj.character ~= character and obj.highlight then
                obj.highlight:Destroy()
                obj.highlight = nil
            end
            obj.character, obj.humanoid, obj.root = character, humanoid, root
        end
    end

    if not humanoid or not root or humanoid.Health <= 0 then
        if obj then hideESP(obj); obj.skip = 4 end
        return
    end

    local rp = root.Position
    local distance = (origin - rp).Magnitude
    local maxDist = state.MaxESPDistance

    if distance > maxDist and not mark then
        if obj then hideESP(obj); obj.skip = 5 end
        return
    end

    if not obj then
        obj = buildESP(player)
        obj.character, obj.humanoid, obj.root = character, humanoid, root
    end

    if obj.ver ~= stateVersion then applySettings(obj) end

    local top = camera:WorldToViewportPoint(rp + TOP_OFFSET)
    local bot = camera:WorldToViewportPoint(rp - BOT_OFFSET)
    local vw, vh = viewport.X, viewport.Y

    local x, y, bw, bh = 0, 0, 0, 0
    local onScreen = false
    if top.Z > 0 and bot.Z > 0 then
        local h = absn(bot.Y - top.Y)
        if h < 6 then h = 6 end
        local w = h * 0.55
        bw, bh = floor(w + 0.5), floor(h + 0.5)
        x = floor((top.X + bot.X) * 0.5 - w * 0.5 + 0.5)
        y = floor(minn(top.Y, bot.Y) + 0.5)
        onScreen = x + bw > 0 and x < vw and y + bh > 0 and y < vh
    end

    local interval = 1
    if distance / maxDist > 0.75 then interval = 2 end
    if not onScreen and not state.ShowTracer then interval = 2 end
    if mark then interval = 1 else interval += lodBias end
    obj.skip = interval - 1

    if not obj.shown then
        obj.shown = true
        obj.container.Visible = true
    end
    if onScreen ~= obj.onScreen then
        obj.onScreen = onScreen
        obj.group.Visible = onScreen
    end

    local color = state.ESPColor
    if state.TeamColor and player.Team then color = player.TeamColor.Color end
    if mark == "friend" then color = state.FriendColor
    elseif mark == "enemy" then color = state.EnemyColor end
    if color ~= obj.color then applyColor(obj, color) end

    if mark ~= obj.mark then
        obj.mark = mark
        obj.container.ZIndex = mark and 3 or 1
        obj.nameText = nil
    end

    if state.ShowHighlight or state.ShowChams then
        local hl = obj.highlight
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.Name = CFG.HL_NAME
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.OutlineColor = state.OutlineGlobal and color or state.OutlineColor
            hl.FillColor = state.ChamsGlobal and color or state.ChamsColor
            hl.Adornee = character
            hl.Parent = gui
            obj.highlight = hl
            obj.hlVer = nil
        end
        if obj.hlVer ~= stateVersion then
            obj.hlVer = stateVersion
            hl.OutlineColor = state.OutlineGlobal and color or state.OutlineColor
            hl.FillColor = state.ChamsGlobal and color or state.ChamsColor
            hl.OutlineTransparency = state.ShowHighlight and 0 or 1
            hl.FillTransparency = state.ShowChams and (1 - state.ChamsOpacity / 100) or 1
        end
    elseif obj.highlight then
        obj.highlight:Destroy()
        obj.highlight = nil
    end

    local fade = 0
    if state.FadeWithDistance and not mark then
        fade = clamp((distance - maxDist * 0.4) / (maxDist * 0.6), 0, 1) * 0.6
    end
    fade = floor(fade * 20 + 0.5) / 20
    if fade ~= obj.fade then applyFade(obj, fade) end

    if onScreen then
        if x ~= obj.lx or y ~= obj.ly or bw ~= obj.lw or bh ~= obj.lh then
            obj.lx, obj.ly, obj.lw, obj.lh = x, y, bw, bh
            layoutESP(obj, x, y, bw, bh)
        end

        local displayName = player.DisplayName
        if displayName ~= obj.nameText then
            obj.nameText = displayName
            obj.nameLabel.Text = displayName
        end

        if mark then
            if obj.iconKind ~= mark then
                obj.iconKind = mark
                obj.iconText.Text = mark == "friend" and ":)" or ":("
            end
            local nameWidth = state.ShowName and obj.nameLabel.TextBounds.X or 0
            obj.icon.Position = UDim2.fromOffset(
                x + floor(bw / 2) - floor(nameWidth / 2) - 12,
                y - 3 - floor((state.TextSize + 2) / 2)
            )
            if not obj.icon.Visible then obj.icon.Visible = true end
        elseif obj.icon.Visible then
            obj.icon.Visible = false
            obj.iconKind = nil
        end

        if state.ShowDistance then
            local d = floor(distance + 0.5)
            if d ~= obj.distInt then
                obj.distInt = d
                obj.distLabel.Text = string.format("%dm", d)
            end
        end

        if state.ShowTool and now >= obj.toolAt then
            obj.toolAt = now + 0.4
            local tool = character:FindFirstChildOfClass("Tool")
            local toolName = tool and tool.Name or ""
            if toolName ~= obj.toolName then
                obj.toolName = toolName
                obj.toolLabel.Text = toolName
            end
            obj.toolLabel.Visible = toolName ~= ""
        end

        if state.ShowHealth then
            local frac = clamp(humanoid.Health / maxn(humanoid.MaxHealth, 1), 0, 1)
            local q = floor(frac * 40 + 0.5)
            if q ~= obj.hpQ then
                obj.hpQ = q
                obj.hpFill.Size = UDim2.fromScale(1, frac)
                obj.hpFill.BackgroundColor3 = HP_RED:Lerp(HP_GREEN, frac)
            end
        end
    end

    if state.ShowSkeleton and onScreen then
        Skeleton.update(obj, camera, character, humanoid)
    elseif obj.skel and obj.skel.Visible then
        obj.skel.Visible = false
    end

    local drawTracer = false
    if state.ShowTracer then
        local fx, fy
        if bot.Z > 0 then
            fx, fy = bot.X, bot.Y
        else
            local rel = camera.CFrame:PointToObjectSpace(rp)
            local dx, dy = rel.X, -rel.Y
            local m = sqrt(dx * dx + dy * dy)
            if m < 1e-3 then dx, dy, m = 0, 1, 1 end
            local far = vw + vh
            fx, fy = vw * 0.5 + dx / m * far, vh * 0.5 + dy / m * far
        end
        fx, fy = clipToViewport(vw * 0.5, vh * 0.5, fx, fy, vw, vh)

        local ox, oy
        local originMode = state.TracerOrigin
        if originMode == "Center" then ox, oy = vw * 0.5, vh * 0.5
        elseif originMode == "Mouse" and mouse then ox, oy = mouse.X, mouse.Y
        else ox, oy = vw * 0.5, vh - 2 end

        local dx, dy = fx - ox, fy - oy
        local len = sqrt(dx * dx + dy * dy)
        if len >= 2 then
            drawTracer = true
            local tracer = obj.tracer
            tracer.Position = UDim2.fromOffset((ox + fx) * 0.5, (oy + fy) * 0.5)
            tracer.Size = UDim2.fromOffset(len, state.TracerThickness)
            tracer.Rotation = deg(atan2(dy, dx))
        end
    end
    if drawTracer ~= obj.tracerVis then
        obj.tracerVis = drawTracer
        obj.tracer.Visible = drawTracer
    end
end

local function espStep()
    if not state.ESP then
        if next(espObjects) then clearAllESP() end
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end
    Camera = camera

    local viewport = camera.ViewportSize
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local origin = localRoot and localRoot.Position or camera.CFrame.Position
    local mouse = (state.ShowTracer and state.TracerOrigin == "Mouse")
        and UserInputService:GetMouseLocation() or nil
    local now = os.clock()

    for i = 1, #playerList do
        local player = playerList[i]
        if player ~= LocalPlayer then
            local ok, err = pcall(updateESP, player, camera, viewport, mouse, origin, now)
            if not ok then
                if err ~= lastEspError then
                    lastEspError = err
                    warn("[HUD] ESP error:", err)
                end
                pcall(removeESP, player)
            end
        end
    end
end

function safeEspStep()
    local ok, err = pcall(espStep)
    if not ok and err ~= lastEspError then
        lastEspError = err
        warn("[HUD] ESP step error:", err)
    end
end

end

--// Main window
local main = Instance.new("CanvasGroup")
main.Name = "Main"
main.Size = UDim2.fromOffset(660, 560)
main.Position = UDim2.new(0.5, -330, 0.5, -280)
main.BackgroundColor3 = THEME.Window
main.BorderSizePixel = 0
main.ZIndex = 5
main.Parent = gui
round(main, 10)

local restPosition = main.Position
newStroke(main, THEME.Line, 1)

do
    local bg = Instance.new("Frame")
    bg.Name = "Bg"
    bg.ZIndex = 0
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = THEME.Window
    bg.BorderSizePixel = 0
    bg.Parent = main
end

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = main

do
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Position = UDim2.fromOffset(16, 0)
    holder.Size = UDim2.new(1, -90, 1, 0)
    holder.Parent = titleBar

    local holderLayout = Instance.new("UIListLayout")
    holderLayout.FillDirection = Enum.FillDirection.Horizontal
    holderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
    holderLayout.Padding = UDim.new(0, 8)
    holderLayout.Parent = holder

    local icon = Instance.new("ImageLabel")
    icon.LayoutOrder = 0
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.fromOffset(22, 22)
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Image = "rbxassetid://" .. CFG.TITLE_ICON_ID
    icon.Parent = holder

    -- the asset may be a decal / model rather than a raw image, so fall back to digging the texture out of it
    task.spawn(function()
        local contentProvider = game:GetService("ContentProvider")
        pcall(function() contentProvider:PreloadAsync({icon}) end)
        local okStatus, status = pcall(function() return contentProvider:GetAssetFetchStatus(icon.Image) end)
        if okStatus and status == Enum.AssetFetchStatus.Success then return end

        local okObjects, objects = pcall(function() return game:GetObjects("rbxassetid://" .. CFG.TITLE_ICON_ID) end)
        if (not okObjects or type(objects) ~= "table") and type(getobjects) == "function" then
            okObjects, objects = pcall(getobjects, "rbxassetid://" .. CFG.TITLE_ICON_ID)
        end
        if not okObjects or type(objects) ~= "table" then return end

        local function textureOf(inst)
            local ok, value = pcall(function()
                if inst:IsA("Decal") or inst:IsA("Texture") then return inst.Texture end
                if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then return inst.Image end
                if inst:IsA("SpecialMesh") then return inst.TextureId end
                if inst:IsA("MeshPart") then return inst.TextureID end
                if inst:IsA("ShirtGraphic") then return inst.Graphic end
                return nil
            end)
            if ok and type(value) == "string" and value ~= "" then return value end
            return nil
        end

        for _, root in ipairs(objects) do
            local found = textureOf(root)
            if not found then
                for _, child in ipairs(root:GetDescendants()) do
                    found = textureOf(child)
                    if found then break end
                end
            end
            if found and icon.Parent then
                icon.Image = found
                break
            end
        end
        for _, root in ipairs(objects) do pcall(function() root:Destroy() end) end
    end)

    local title = Instance.new("TextLabel")
    title.LayoutOrder = 1
    title.BackgroundTransparency = 1
    title.AutomaticSize = Enum.AutomaticSize.X
    title.Size = UDim2.fromOffset(0, 22)
    title.Font = Enum.Font.GothamBold
    title.RichText = true
    title.TextSize = 14
    title.TextColor3 = WHITE
    title.Text = '<font color="rgb(255,214,10)">Ducksploit</font>  <font color="rgb(255,255,255)">·</font>  <font color="rgb(255,255,255)">by bununxd</font>'
    title.Parent = holder


end

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(30, 24)
closeButton.Position = UDim2.new(1, -40, 0.5, -12)
closeButton.Text = "×"
closeButton.TextSize = 20
closeButton.Font = Enum.Font.Gotham
closeButton.TextColor3 = THEME.Dim
closeButton.BackgroundTransparency = 1
closeButton.AutoButtonColor = false
closeButton.Parent = titleBar
closeButton.MouseEnter:Connect(function() tween(closeButton, {TextColor3 = WHITE}, 0.12) end)
closeButton.MouseLeave:Connect(function() tween(closeButton, {TextColor3 = THEME.Dim}, 0.15) end)

local tabBar = Instance.new("Frame")
tabBar.Name = "Tabs"
tabBar.Position = UDim2.fromOffset(0, 40)
tabBar.Size = UDim2.new(1, 0, 0, 30)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

do
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = tabBar
end

local function createPage()
    local page = Instance.new("ScrollingFrame")
    page.Position = UDim2.fromOffset(14, 78)
    page.Size = UDim2.new(1, -28, 1, -88)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = THEME.Accent
    page.ScrollBarImageTransparency = 0.5
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 10)
    end)
    return page
end

local aimbotPage = createPage()
local espPage = createPage()
local visualPage = createPage()
local spectatePage = createPage()
local movementPage = createPage()
local settingsPage = createPage()
local miscPage = createPage()

local tabs = {}
local activeTab = nil
local tabOrder = 0
local TabBar = {
    section = nil,
    moduleBase = nil,
}

local function showTab(name)
    activeTab = name
    for tabName, tab in pairs(tabs) do
        local on = tabName == name
        tab.page.Visible = on
        tween(tab.pill, {BackgroundTransparency = on and 0 or 1}, 0.18)
        tween(tab.stroke, {Transparency = on and 1 or 0}, 0.18)
        tween(tab.button, {TextColor3 = on and BLACK or THEME.Dim}, 0.18)
    end
end

-- each tab is a transparent text button sitting on top of a separate rounded pill, so the pill is always cleanly round
local function makeTab(name, text, page)
    tabOrder += 1

    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.AutomaticSize = Enum.AutomaticSize.X
    holder.Size = UDim2.fromOffset(0, 26)
    holder.LayoutOrder = tabOrder
    holder.Parent = tabBar

    local pill = Instance.new("Frame")
    pill.BackgroundColor3 = THEME.Accent
    pill.BackgroundTransparency = 1
    pill.BorderSizePixel = 0
    pill.Size = UDim2.fromScale(1, 1)
    pill.ZIndex = 1
    pill.Parent = holder
    round(pill, 13)

    local stroke = newStroke(pill, THEME.ButtonLine, 1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 0

    local button = Instance.new("TextButton")
    button.AutomaticSize = Enum.AutomaticSize.X
    button.Size = UDim2.fromOffset(0, 26)
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 11
    button.TextColor3 = THEME.Dim
    button.Text = text
    button.ZIndex = 2
    button.Parent = holder

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = button

    button.MouseEnter:Connect(function()
        if activeTab ~= name then tween(button, {TextColor3 = THEME.Text}, 0.1) end
    end)
    button.MouseLeave:Connect(function()
        if activeTab ~= name then tween(button, {TextColor3 = THEME.Dim}, 0.15) end
    end)
    button.MouseButton1Click:Connect(function() showTab(name) end)

    tabs[name] = {button = button, pill = pill, page = page, stroke = stroke}
end

makeTab("aimbot", "Combat", aimbotPage)
makeTab("esp", "ESP", espPage)
makeTab("visual", "Visual", visualPage)
makeTab("spectate", "Player List", spectatePage)
makeTab("movement", "Movement", movementPage)
makeTab("misc", "Misc", miscPage)
makeTab("settings", "Settings", settingsPage)

--// Smooth scrolling
local function enableSmoothScroll(page)
    page.ScrollingEnabled = false
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
        if not page.Visible then return end
        local mouse = UserInputService:GetMouseLocation()
        local pos, size = page.AbsolutePosition, page.AbsoluteSize
        if mouse.X < pos.X or mouse.X > pos.X + size.X
            or mouse.Y < pos.Y or mouse.Y > pos.Y + size.Y then return end
        local maxY = maxn(page.AbsoluteCanvasSize.Y - page.AbsoluteWindowSize.Y, 0)
        local target = clamp(page.CanvasPosition.Y - input.Position.Z * 60, 0, maxY)
        tween(page, {CanvasPosition = Vector2.new(0, target)}, 0.18)
    end))
end

for _, page in ipairs({aimbotPage, espPage, visualPage, spectatePage, movementPage, settingsPage, miscPage}) do
    enableSmoothScroll(page)
end

--// Row builders
local currentPage = aimbotPage

-- declared before any hotkey builder so every closure captures the same local
local pendingBind = nil

local function createRow(text, height)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -6, 0, height or 28)
    frame.BackgroundColor3 = WHITE
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = TabBar.section or currentPage
    round(frame, 5)

    frame.MouseEnter:Connect(function() tween(frame, {BackgroundTransparency = 0.95}, 0.12) end)
    frame.MouseLeave:Connect(function() tween(frame, {BackgroundTransparency = 1}, 0.15) end)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(1, -140, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = THEME.Text
    label.Text = text
    label.Parent = frame
    return frame, label
end

local function createSection(text)
    local container = Instance.new("Frame")
    container.Name = "Section"
    container.BackgroundColor3 = THEME.Row
    container.BackgroundTransparency = 0.25
    container.BorderSizePixel = 0
    container.Size = UDim2.new(1, -6, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = currentPage
    round(container, 8)
    local cardStroke = newStroke(container, THEME.Line, 1)
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = container

    local outerLayout = Instance.new("UIListLayout")
    outerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    outerLayout.Parent = container

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.AutoButtonColor = false
    header.Text = ""
    header.LayoutOrder = 1
    header.Parent = container

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(1, -4, 1, -2)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Text = text
    label.TextColor3 = THEME.On
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header

    local line = Instance.new("Frame")
    line.Position = UDim2.new(0, 0, 1, -1)
    line.Size = UDim2.new(1, -6, 0, 1)
    line.BackgroundColor3 = THEME.Line
    line.BorderSizePixel = 0
    line.Parent = header

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.ClipsDescendants = true
    body.LayoutOrder = 2
    body.Parent = container

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 4)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingTop = UDim.new(0, 6)
    bodyPad.Parent = body

    local collapsed = false
    header.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        body.Visible = not collapsed
        tween(label, {TextColor3 = collapsed and THEME.Dim or THEME.On}, 0.15)
    end)

    TabBar.moduleBase = nil
    TabBar.section = body
    return body
end

local function createRowButton(parent, text, width)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(width, 22)
    button.Position = UDim2.new(1, -(width + 6), 0.5, -11)
    button.BackgroundColor3 = THEME.Button
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 10
    button.TextColor3 = THEME.Text
    button.Text = text
    button.Parent = parent
    round(button, 11)
    local outline = newStroke(button, THEME.ButtonLine, 1)
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return button
end

local function addHover(button, baseColor, hoverColor)
    button.AutoButtonColor = false
    button.MouseEnter:Connect(function()
        local target = hoverColor and hoverColor() or baseColor():Lerp(WHITE, 0.12)
        tween(button, {BackgroundColor3 = target}, 0.12)
    end)
    button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = baseColor()}, 0.15)
    end)
end

-- small keybind pill attached to a row; clicking it starts a rebind capture
local function attachHotkeyPill(frame, field)
    local pill = Instance.new("TextButton")
    pill.Size = UDim2.fromOffset(44, 18)
    pill.Position = UDim2.new(1, -48, 0.5, -9)
    pill.BackgroundColor3 = THEME.Button
    pill.Font = Enum.Font.GothamMedium
    pill.TextSize = 10
    pill.TextColor3 = THEME.Dim
    pill.Text = shortKeyName(state[field])
    pill.AutoButtonColor = false
    pill.Parent = frame
    round(pill, 9)
    local outline = newStroke(pill, THEME.ButtonLine, 1)
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    pill.MouseButton1Click:Connect(function()
        pendingBind = {field = field, button = pill, format = shortKeyName}
        pill.Text = "..."
        tween(pill, {BackgroundColor3 = THEME.ButtonActive}, 0.15)
    end)
    Config.refresh[field] = function() pill.Text = shortKeyName(state[field]) end
    return pill
end

local function lockKeyDisplay(key)
    if key == Enum.KeyCode.Unknown then return "NONE" end
    if key == Enum.UserInputType.MouseButton1 then return "mouse1" end
    if key == Enum.UserInputType.MouseButton2 then return "mouse2" end
    if key == Enum.UserInputType.MouseButton3 then return "mouse3" end
    return key.Name:lower()
end

local function createHotkeyRow(text, field)
    local button = createRowButton(createRow(text), lockKeyDisplay(state[field]), 90)
    addHover(button, function()
        return (pendingBind and pendingBind.field == field) and THEME.ButtonActive or THEME.Button
    end)
    button.MouseButton1Click:Connect(function()
        pendingBind = {field = field, button = button, format = lockKeyDisplay}
        button.Text = "..."
        tween(button, {BackgroundColor3 = THEME.ButtonActive}, 0.15)
    end)
    Config.refresh[field] = function() button.Text = lockKeyDisplay(state[field]) end
    return button
end

local function createToggle(text, key, callback, host)
    local frame, label
    if host then
        frame = host
        label = host:FindFirstChildWhichIsA("TextLabel")
    else
        frame, label = createRow(text)
    end
    if label then
        label.Position = UDim2.fromOffset(28, 0)
        label.Size = UDim2.new(1, -140, 1, 0)
    end

    local box = Instance.new("TextButton")
    box.Size = UDim2.fromOffset(16, 16)
    box.Position = UDim2.new(0, 2, 0.5, -8)
    box.Text = ""
    box.AutoButtonColor = false
    box.BackgroundColor3 = THEME.Off
    box.Parent = frame
    round(box, 4)
    local outline = newStroke(box, THEME.ButtonLine, 1)
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local mark = Instance.new("TextLabel")
    mark.AnchorPoint = Vector2.new(0.5, 0.5)
    mark.Position = UDim2.fromScale(0.5, 0.5)
    mark.Size = UDim2.fromScale(1, 1)
    mark.BackgroundTransparency = 1
    mark.Font = Enum.Font.GothamBold
    mark.TextSize = 11
    mark.TextColor3 = THEME.Ink
    mark.Text = "✓"
    mark.TextTransparency = 1
    mark.Parent = box

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.Position = UDim2.fromOffset(24, 0)
    hit.Size = UDim2.new(1, -150, 1, 0)
    hit.Parent = frame

    local function draw()
        local on = state[key] and true or false
        tween(box, {BackgroundColor3 = on and THEME.Accent or THEME.Off}, 0.15)
        tween(outline, {Color = on and THEME.Accent or THEME.ButtonLine}, 0.15)
        tween(mark, {TextTransparency = on and 0 or 1}, 0.12)
    end

    local function set(value)
        if state[key] == value then draw(); return end
        state[key] = value
        draw()
        if callback then
            local ok, err = pcall(callback, value)
            if not ok then warn("[HUD] toggle callback error:", err) end
            draw()
        end
        scheduleSave()
    end

    box.MouseButton1Click:Connect(function() set(not state[key]) end)
    hit.MouseButton1Click:Connect(function() set(not state[key]) end)

    box.BackgroundColor3 = state[key] and THEME.Accent or THEME.Off
    outline.Color = state[key] and THEME.Accent or THEME.ButtonLine
    mark.TextTransparency = state[key] and 0 or 1
    Config.toggles[key] = set
    Config.refresh[key] = draw
    return set
end

-- row with a checkbox plus a keybind pill on the right (used for the "Enabled" rows)
local function createToggleWithHotkey(text, key, hotkeyField, callback)
    local frame = createRow(text)
    local set = createToggle(text, key, callback, frame)
    attachHotkeyPill(frame, hotkeyField)
    return set
end

--// Module header
local Module = {}

function Module.finish()
    if TabBar.moduleBase then
        TabBar.section = TabBar.moduleBase
        TabBar.moduleBase = nil
    end
end

function Module.begin(text, key, callback)
    local base = TabBar.moduleBase or TabBar.section or currentPage
    TabBar.moduleBase = base

    local container = Instance.new("Frame")
    container.Name = "Module"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -6, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = base

    local containerLayout = Instance.new("UIListLayout")
    containerLayout.Padding = UDim.new(0, 4)
    containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    containerLayout.Parent = container

    local header = Instance.new("Frame")
    header.LayoutOrder = 1
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = WHITE
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Parent = container
    round(header, 5)
    header.MouseEnter:Connect(function() tween(header, {BackgroundTransparency = 0.95}, 0.12) end)
    header.MouseLeave:Connect(function() tween(header, {BackgroundTransparency = 1}, 0.15) end)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(28, 0)
    label.Size = UDim2.new(1, -110, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = THEME.Text
    label.Text = text
    label.Parent = header

    local set = createToggle(text, key, callback, header)

    local body = Instance.new("Frame")
    body.Name = "Settings"
    body.LayoutOrder = 2
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.Visible = false
    body.Parent = container

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 4)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingLeft = UDim.new(0, 14)
    bodyPad.Parent = body

    local expand = Instance.new("TextButton")
    expand.Name = "Expand"
    expand.Size = UDim2.fromOffset(26, 22)
    expand.Position = UDim2.new(1, -34, 0.5, -11)
    expand.BackgroundTransparency = 1
    expand.AutoButtonColor = false
    expand.Font = Enum.Font.GothamBold
    expand.TextSize = 14
    expand.TextColor3 = THEME.Dim
    expand.Text = "+"
    expand.Parent = header

    local open, hovering = false, false
    local function tint()
        tween(expand, {TextColor3 = (open or hovering) and WHITE or THEME.Dim}, 0.12)
    end
    expand.MouseEnter:Connect(function() hovering = true; tint() end)
    expand.MouseLeave:Connect(function() hovering = false; tint() end)
    expand.MouseButton1Click:Connect(function()
        open = not open
        body.Visible = open
        expand.Text = open and "-" or "+"
        tint()
    end)

    TabBar.section = body
    return set
end

--// Fly module
local setFlyEnabled = nil
local fly = (function()
    local CFG = {
        verticalFactor = 0.55,
        accelTau = 0.13,
        decelTau = 0.20,
        jitterAmp = 0.01,
        jitterHz = 7.5,
        spawnGrace = 0.35,
    }

    local held = { w = false, a = false, s = false, d = false, up = false, down = false }
    local wanted = false
    local rig = nil
    local spawnC, removeC = nil, nil
    local gen = 0

    local function randn() return (math.random() + math.random() - 1) * 0.5 end

    -- Swim mode keeps the humanoid in the Swimming state, Velocity mode keeps it in Freefall
    local function holdState(hum)
        local want = state.FlyMode == "Swim" and Enum.HumanoidStateType.Swimming
            or Enum.HumanoidStateType.Freefall
        if hum:GetState() ~= want then
            pcall(function() hum:ChangeState(want) end)
        end
    end

    local function teardownRig()
        local r = rig
        rig = nil
        if not r then return end
        if r.step then r.step:Disconnect() end
        if r.died then r.died:Disconnect() end
        local hum = r.hum
        if hum and hum.Parent and hum.Health > 0 then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
    end

    local function build()
        teardownRig()

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then return false end

        local r = { root = root, hum = hum, curVel = root.AssemblyLinearVelocity, jitterV = Vector3.zero, jitterT = 0 }
        rig = r

        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) end)
        holdState(hum)

        held.w = UserInputService:IsKeyDown(Enum.KeyCode.W)
        held.a = UserInputService:IsKeyDown(Enum.KeyCode.A)
        held.s = UserInputService:IsKeyDown(Enum.KeyCode.S)
        held.d = UserInputService:IsKeyDown(Enum.KeyCode.D)
        held.up = UserInputService:IsKeyDown(Enum.KeyCode.Space)
        held.down = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

        r.died = hum.Died:Connect(function()
            if rig == r then teardownRig() end
        end)

        r.step = RunService.Stepped:Connect(function(_, dt)
            if rig ~= r then return end
            if not hum.Parent or hum.Health <= 0 or not root.Parent then
                teardownRig()
                return
            end
            local cam = workspace.CurrentCamera
            if not cam then return end
            dt = minn(dt, 0.1)

            local speed = maxn(state.FlySpeed, 1)

            if state.FlyMode == "Swim" then
                holdState(hum)
            else
                local st = hum:GetState()
                if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Climbing then
                    holdState(hum)
                end
            end

            local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
            local move = Vector3.zero
            if held.w then move += look end
            if held.s then move -= look end
            if held.d then move += right end
            if held.a then move -= right end
            if held.up then move += Vector3.yAxis * CFG.verticalFactor end
            if held.down then move -= Vector3.yAxis * CFG.verticalFactor end

            local target = move.Magnitude > 1e-4 and move.Unit * speed or Vector3.zero
            local tau = target.Magnitude > r.curVel.Magnitude and CFG.accelTau or CFG.decelTau
            r.curVel = r.curVel:Lerp(target, 1 - exp(-dt / tau))

            r.jitterT += dt
            if r.jitterT >= 1 / CFG.jitterHz then
                r.jitterT = 0
                r.jitterV = Vector3.new(randn(), randn(), randn()) * speed * CFG.jitterAmp
            end

            local v = r.curVel + r.jitterV
            if v.Magnitude > speed then v = v.Unit * speed end

            root.AssemblyLinearVelocity = v + Vector3.new(0, workspace.Gravity * dt, 0)
            root.AssemblyAngularVelocity = Vector3.zero
        end)

        return true
    end

    local function stop()
        wanted = false
        gen += 1
        if spawnC then spawnC:Disconnect(); spawnC = nil end
        if removeC then removeC:Disconnect(); removeC = nil end
        teardownRig()
        for k in pairs(held) do held[k] = false end
        state.Fly = false
    end

    local function start()
        stop()
        wanted = true
        state.Fly = true

        if not build() then
            stop()
            return false
        end

        removeC = LocalPlayer.CharacterRemoving:Connect(teardownRig)

        spawnC = LocalPlayer.CharacterAdded:Connect(function(newChar)
            gen += 1
            local myGen = gen
            teardownRig()
            pcall(function()
                newChar:WaitForChild("Humanoid", 5)
                newChar:WaitForChild("HumanoidRootPart", 5)
            end)
            task.wait(CFG.spawnGrace)
            if not wanted or myGen ~= gen then return end
            if not build() then
                if setFlyEnabled then setFlyEnabled(false) else stop() end
            end
        end)

        return true
    end

    local function keyToSlot(kc)
        if kc == Enum.KeyCode.W then return "w" end
        if kc == Enum.KeyCode.A then return "a" end
        if kc == Enum.KeyCode.S then return "s" end
        if kc == Enum.KeyCode.D then return "d" end
        if kc == Enum.KeyCode.Space then return "up" end
        if kc == Enum.KeyCode.LeftControl or kc == Enum.KeyCode.RightControl then return "down" end
        return nil
    end

    trackConnection(UserInputService.InputBegan:Connect(function(input)
        if not rig then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if UserInputService:GetFocusedTextBox() then return end
        local k = keyToSlot(input.KeyCode)
        if k then held[k] = true end
    end))

    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local k = keyToSlot(input.KeyCode)
        if k then held[k] = false end
    end))

    trackConnection(UserInputService.WindowFocusReleased:Connect(function()
        for k in pairs(held) do held[k] = false end
    end))

    return { start = start, stop = stop, isRunning = function() return rig ~= nil end }
end)()

--// Noclip module
local noclip = (function()
    local flipped = setmetatable({}, {__mode = "k"})
    local cache, rebuildAt = {}, 0
    local conn
    local running = false

    local function rebuild(char)
        cache = {}
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then cache[#cache + 1] = d end
        end
    end

    local function step()
        if not running then return end
        local char = LocalPlayer.Character
        if not char then return end
        local now = os.clock()
        if now >= rebuildAt then
            rebuildAt = now + 0.4
            rebuild(char)
        end
        for i = 1, #cache do
            local part = cache[i]
            if part.Parent and part.CanCollide then
                flipped[part] = true
                part.CanCollide = false
            end
        end
    end

    local function stop()
        running = false
        if conn then conn:Disconnect(); conn = nil end
        for part in pairs(flipped) do
            if part.Parent then pcall(function() part.CanCollide = true end) end
        end
        table.clear(flipped)
        cache = {}
        state.Noclip = false
    end

    local function start()
        if conn then conn:Disconnect() end
        running = true
        rebuildAt = 0
        state.Noclip = true
        conn = RunService.Stepped:Connect(step)
    end

    return { start = start, stop = stop, isRunning = function() return running end }
end)()

--// Anti-fling
local antiFling = (function()
    local flipped = setmetatable({}, {__mode = "k"})
    local cache, rebuildAt = {}, 0
    local history = {}
    local stepC, hbC
    local running = false

    local function rebuild()
        cache = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, d in ipairs(p.Character:GetDescendants()) do
                    if d:IsA("BasePart") then cache[#cache + 1] = d end
                end
            end
        end
    end

    local function onStepped()
        local now = os.clock()
        if now >= rebuildAt then rebuildAt = now + 0.5; rebuild() end
        for i = 1, #cache do
            local part = cache[i]
            if part.Parent and part.CanCollide then
                flipped[part] = true
                part.CanCollide = false
            end
        end
    end

    local function onHeartbeat()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 or hum.Sit then
            table.clear(history)
            return
        end

        if state.Fly or state.Sprint then
            table.clear(history)
            return
        end

        local now = os.clock()
        local v, av = root.AssemblyLinearVelocity, root.AssemblyAngularVelocity
        local expected = hum.WalkSpeed
        local horiz = Vector3.new(v.X, 0, v.Z).Magnitude
        local bad = av.Magnitude > 60 or horiz > expected * 2 + 80 or v.Y > 200

        if bad then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            local safe = history[1]
            if safe and (root.Position - safe.cf.Position).Magnitude > 8 then
                root.CFrame = safe.cf
            end
        else
            history[#history + 1] = {t = now, cf = root.CFrame}
            while history[1] and now - history[1].t > 0.4 do table.remove(history, 1) end
        end
    end

    local function stop()
        running = false
        if stepC then stepC:Disconnect(); stepC = nil end
        if hbC then hbC:Disconnect(); hbC = nil end
        for part in pairs(flipped) do
            if part.Parent then pcall(function() part.CanCollide = true end) end
        end
        table.clear(flipped)
        table.clear(history)
        cache = {}
    end

    local function start()
        stop()
        running = true
        rebuildAt = 0
        stepC = RunService.Stepped:Connect(onStepped)
        hbC = RunService.Heartbeat:Connect(onHeartbeat)
    end

    return { start = start, stop = stop }
end)()

--// Player fling
local Fling = (function()
    local FLUNG_SPEED = 250
    local FLUNG_DIST = 50
    local GAP = 0.12

    local current = nil
    local busy = false
    local aborted = false
    local buttons = {}
    local extra = {}

    local function refresh()
        for player, button in pairs(buttons) do
            if button.Parent then
                button.Text = (player == current) and "STOP" or "FLING"
            end
        end
        for player, button in pairs(extra) do
            if button.Parent then
                button.Text = (player == current) and "STOP" or "FLING"
            end
        end
    end

    local function stop(abort)
        if abort then aborted = true end
        current = nil
        refresh()
    end

    local function isFlung(troot, ref)
        return troot.AssemblyLinearVelocity.Magnitude > FLUNG_SPEED
            or (troot.Position - ref).Magnitude > FLUNG_DIST
            or troot.Position.Y < workspace.FallenPartsDestroyHeight
    end

    local function toggle(target)
        if not target or target == LocalPlayer or target.Parent ~= Players then return end
        if current == target then stop() return end
        if busy then return end

        local lchar = LocalPlayer.Character
        local lhum = lchar and lchar:FindFirstChildOfClass("Humanoid")
        local lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")
        if not lhum or not lroot or lhum.Health <= 0 then return end

        busy = true
        aborted = false
        current = target
        refresh()

        task.spawn(function()
            local wasAntiFling = state.AntiFling
            if wasAntiFling then antiFling.stop() end
            local wasFly = state.Fly
            if wasFly and setFlyEnabled then setFlyEnabled(false) end
            local wasNoclip = state.Noclip
            if wasNoclip then noclip.stop() end

            local savedCFrame = lroot.CFrame
            local savedVel = lroot.AssemblyLinearVelocity
            local savedAngVel = lroot.AssemblyAngularVelocity

            local function alive()
                return current == target and target.Parent == Players
                    and lroot.Parent ~= nil and lhum.Health > 0
            end

            local function targetRoot()
                local c = target.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if h and h.Health <= 0 then return nil, true end
                return r, false
            end

            pcall(function() lhum:ChangeState(Enum.HumanoidStateType.Physics) end)

            local ok, err = pcall(function()
                local done = false
                while not done and alive() do
                    local troot, dead = targetRoot()
                    if dead then break end
                    if not troot then
                        task.wait(0.1)
                    else
                        local ref = troot.Position
                        local t0 = os.clock()

                        while alive() and os.clock() - t0 < CFG.FlingDuration do
                            troot = targetRoot()
                            if not troot then break end
                            lroot.CFrame = troot.CFrame * CFrame.new(0, 0.5, 0)
                            lroot.AssemblyLinearVelocity = Vector3.new(CFG.SpinPower * 20, CFG.FlingPower * 0.45, CFG.SpinPower * 20)
                            lroot.AssemblyAngularVelocity = Vector3.new(CFG.SpinPower, CFG.SpinPower, CFG.SpinPower)
                            RunService.Heartbeat:Wait()
                            if troot.Parent and isFlung(troot, ref) then done = true; break end
                        end

                        if not done and troot and alive() then
                            lroot.AssemblyLinearVelocity = Vector3.zero
                            lroot.AssemblyAngularVelocity = Vector3.zero
                            local g0 = os.clock()
                            while alive() and os.clock() - g0 < GAP do
                                RunService.Heartbeat:Wait()
                                if troot.Parent and isFlung(troot, ref) then done = true; break end
                            end
                        end
                    end
                end
            end)
            if not ok then warn("[HUD] fling error:", err) end

            current = nil
            refresh()

            if lroot.Parent then
                lroot.AssemblyLinearVelocity = Vector3.zero
                lroot.AssemblyAngularVelocity = Vector3.zero
                lroot.CFrame = savedCFrame
                task.wait(0.05)
                if lroot.Parent then
                    lroot.AssemblyLinearVelocity = savedVel
                    lroot.AssemblyAngularVelocity = savedAngVel
                    pcall(function() lhum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                end
            end

            if not aborted then
                if wasNoclip then noclip.start() end
                if wasFly and setFlyEnabled then setFlyEnabled(true) end
                if wasAntiFling then antiFling.start() end
            end
            busy = false
        end)
    end

    return { toggle = toggle, stop = stop, buttons = buttons, extra = extra, refresh = refresh }
end)()

local function createCycle(text, key, options, onChange)
    local frame, label = createRow(text, 30)
    frame.ClipsDescendants = true
    label.Size = UDim2.new(1, -150, 0, 30)

    local field = Instance.new("TextButton")
    field.Size = UDim2.fromOffset(124, 22)
    field.Position = UDim2.new(1, -130, 0, 4)
    field.BackgroundColor3 = THEME.Button
    field.Text = ""
    field.AutoButtonColor = false
    field.Parent = frame
    round(field, 6)
    local fieldStroke = newStroke(field, THEME.ButtonLine, 1)
    fieldStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    addHover(field, function() return THEME.Button end)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.fromOffset(9, 0)
    valueLabel.Size = UDim2.new(1, -28, 1, 0)
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextSize = 11
    valueLabel.TextColor3 = THEME.Text
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Parent = field

    local chevron = Instance.new("TextLabel")
    chevron.AnchorPoint = Vector2.new(0.5, 0.5)
    chevron.Position = UDim2.new(1, -12, 0.5, 0)
    chevron.Size = UDim2.fromOffset(12, 12)
    chevron.BackgroundTransparency = 1
    chevron.Font = Enum.Font.GothamBold
    chevron.TextSize = 9
    chevron.TextColor3 = THEME.Dim
    chevron.Text = "v"
    chevron.Parent = field

    local buttons = {}
    local open = false
    local openHeight = 36 + #options * 26

    local function refresh()
        valueLabel.Text = tostring(state[key])
        for option, button in pairs(buttons) do
            button.TextColor3 = state[key] == option and THEME.On or THEME.Text
        end
    end

    local function setOpen(value)
        open = value
        tween(frame, {Size = UDim2.new(1, -6, 0, open and openHeight or 30)}, 0.2)
        tween(chevron, {Rotation = open and 180 or 0}, 0.2)
    end

    for i, option in ipairs(options) do
        local button = Instance.new("TextButton")
        button.Position = UDim2.fromOffset(2, 36 + (i - 1) * 26)
        button.Size = UDim2.new(1, -4, 0, 24)
        button.BackgroundColor3 = THEME.Button
        button.AutoButtonColor = false
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 11
        button.TextColor3 = THEME.Text
        button.Text = option
        button.Parent = frame
        round(button, 5)
        addHover(button, function() return THEME.Button end)
        button.MouseButton1Click:Connect(function()
            state[key] = option
            refresh()
            scheduleSave()
            if onChange then pcall(onChange) end
            setOpen(false)
        end)
        buttons[option] = button
    end

    field.MouseButton1Click:Connect(function() setOpen(not open) end)

    Config.refresh[key] = refresh
    refresh()
end

local function createSlider(text, key, minimum, maximum, step, onChange)
    local frame, label = createRow(text, 40)
    label.Size = UDim2.new(1, -100, 0, 24)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -82, 0, 0)
    valueLabel.Size = UDim2.fromOffset(70, 24)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = THEME.On
    valueLabel.Parent = frame

    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(2, 29)
    bar.Size = UDim2.new(1, -12, 0, 3)
    bar.BackgroundColor3 = THEME.Track
    bar.BorderSizePixel = 0
    bar.Parent = frame
    round(bar, 2)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = THEME.Fill
    fill.BorderSizePixel = 0
    fill.Parent = bar
    round(fill, 2)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(10, 10)
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = bar
    round(knob, 5)

    local function fraction()
        return clamp((state[key] - minimum) / (maximum - minimum), 0, 1)
    end

    local dragging = false
    local function draw()
        local f = fraction()
        tween(fill, {Size = UDim2.fromScale(f, 1)}, 0.08)
        tween(knob, {Position = UDim2.fromScale(f, 0.5)}, 0.08)
        local value = state[key]
        valueLabel.Text = (step < 1) and string.format("%.2f", value) or tostring(value)
    end

    local function setFromX(x)
        if bar.AbsoluteSize.X <= 0 then return end
        local f = clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = minimum + (maximum - minimum) * f
        local n = floor(value / step + 0.5)
        value = step < 1 and n / floor(1 / step + 0.5) or n * step
        value = clamp(value, minimum, maximum)
        if state[key] ~= value then
            state[key] = value
            draw()
            scheduleSave()
            if onChange then pcall(onChange, value) end
        end
    end

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Position = UDim2.fromOffset(0, 22)
    hit.Size = UDim2.new(1, 0, 0, 18)
    hit.Parent = frame
    hit.InputBegan:Connect(function(input)
        if isPointerBegin(input) then
            dragging = true
            tween(knob, {Size = UDim2.fromOffset(12, 12)}, 0.1)
            setFromX(input.Position.X)
        end
    end)

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and isPointerMove(input) then setFromX(input.Position.X) end
    end))

    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if isPointerBegin(input) and dragging then
            dragging = false
            tween(knob, {Size = UDim2.fromOffset(10, 10)}, 0.12)
        end
    end))

    fill.Size = UDim2.fromScale(fraction(), 1)
    knob.Position = UDim2.fromScale(fraction(), 0.5)
    draw()
    Config.refresh[key] = draw
end

local function createColorPicker(text, key, onChange)
    local frame, rowLabel = createRow(text, 32)
    rowLabel.Size = UDim2.new(1, -140, 0, 32)
    frame.ClipsDescendants = true

    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.fromOffset(34, 14)
    swatch.Position = UDim2.new(1, -46, 0, 9)
    swatch.Text = ""
    swatch.AutoButtonColor = false
    swatch.BackgroundColor3 = state[key]
    swatch.Parent = frame
    round(swatch, 3)
    local swatchOutline = newStroke(swatch, THEME.Ink, 1.5)
    swatchOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local panel = Instance.new("Frame")
    panel.BackgroundTransparency = 1
    panel.Position = UDim2.fromOffset(12, 40)
    panel.Size = UDim2.new(1, -24, 0, 82)
    panel.Parent = frame

    local sv = Instance.new("Frame")
    sv.Size = UDim2.new(1, -28, 1, 0)
    sv.BorderSizePixel = 0
    sv.BackgroundColor3 = WHITE
    sv.Parent = panel
    round(sv, 3)

    local whiteLayer = Instance.new("Frame")
    whiteLayer.Size = UDim2.fromScale(1, 1)
    whiteLayer.BorderSizePixel = 0
    whiteLayer.BackgroundColor3 = WHITE
    whiteLayer.Parent = sv
    round(whiteLayer, 3)
    local whiteGradient = Instance.new("UIGradient")
    whiteGradient.Transparency = NumberSequence.new(0, 1)
    whiteGradient.Parent = whiteLayer

    local blackLayer = Instance.new("Frame")
    blackLayer.Size = UDim2.fromScale(1, 1)
    blackLayer.BorderSizePixel = 0
    blackLayer.BackgroundColor3 = BLACK
    blackLayer.Parent = sv
    round(blackLayer, 3)
    local blackGradient = Instance.new("UIGradient")
    blackGradient.Rotation = 90
    blackGradient.Transparency = NumberSequence.new(1, 0)
    blackGradient.Parent = blackLayer

    local svCursor = Instance.new("Frame")
    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    svCursor.Size = UDim2.fromOffset(9, 9)
    svCursor.BackgroundTransparency = 1
    svCursor.ZIndex = 3
    svCursor.Parent = sv
    round(svCursor, 5)
    newStroke(svCursor, WHITE, 1.5)

    local svHit = Instance.new("TextButton")
    svHit.Size = UDim2.fromScale(1, 1)
    svHit.BackgroundTransparency = 1
    svHit.Text = ""
    svHit.AutoButtonColor = false
    svHit.ZIndex = 5
    svHit.Parent = sv

    local hueBar = Instance.new("Frame")
    hueBar.Position = UDim2.new(1, -18, 0, 0)
    hueBar.Size = UDim2.new(0, 18, 1, 0)
    hueBar.BorderSizePixel = 0
    hueBar.BackgroundColor3 = WHITE
    hueBar.Parent = panel
    round(hueBar, 3)

    local hueGradient = Instance.new("UIGradient")
    hueGradient.Rotation = 90
    local keypoints = {}
    for i = 0, 6 do
        keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1))
    end
    keypoints[#keypoints] = ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1))
    hueGradient.Color = ColorSequence.new(keypoints)
    hueGradient.Parent = hueBar

    local hueCursor = Instance.new("Frame")
    hueCursor.AnchorPoint = Vector2.new(0, 0.5)
    hueCursor.Size = UDim2.new(1, 0, 0, 3)
    hueCursor.BackgroundColor3 = WHITE
    hueCursor.BorderSizePixel = 0
    hueCursor.ZIndex = 3
    hueCursor.Parent = hueBar
    newStroke(hueCursor, BLACK, 1)

    local hueHit = Instance.new("TextButton")
    hueHit.Size = UDim2.fromScale(1, 1)
    hueHit.BackgroundTransparency = 1
    hueHit.Text = ""
    hueHit.AutoButtonColor = false
    hueHit.ZIndex = 5
    hueHit.Parent = hueBar

    local h, s, v = state[key]:ToHSV()
    local mode = nil

    local function refresh(commit)
        local color = Color3.fromHSV(h, s, v)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0, h)
        swatch.BackgroundColor3 = color
        if commit then
            state[key] = color
            scheduleSave()
            if onChange then onChange() end
        end
    end

    local function setSV(pos)
        local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
        if as.X <= 0 or as.Y <= 0 then return end
        s = clamp((pos.X - ap.X) / as.X, 0, 1)
        v = 1 - clamp((pos.Y - ap.Y) / as.Y, 0, 1)
        refresh(true)
    end

    local function setHue(pos)
        local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
        if as.Y <= 0 then return end
        h = clamp((pos.Y - ap.Y) / as.Y, 0, 0.999)
        refresh(true)
    end

    svHit.InputBegan:Connect(function(input)
        if isPointerBegin(input) then mode = "sv"; setSV(pointerPos(input)) end
    end)
    hueHit.InputBegan:Connect(function(input)
        if isPointerBegin(input) then mode = "hue"; setHue(pointerPos(input)) end
    end)

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if mode and isPointerMove(input) then
            if mode == "sv" then setSV(pointerPos(input))
            else setHue(pointerPos(input)) end
        end
    end))
    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if isPointerBegin(input) then mode = nil end
    end))

    local open = false
    swatch.MouseButton1Click:Connect(function()
        open = not open
        tween(frame, {Size = UDim2.new(1, -6, 0, open and 130 or 32)}, 0.18)
    end)

    Config.refresh[key] = function()
        h, s, v = state[key]:ToHSV()
        refresh(false)
    end
    refresh(false)
end

--// Combat cards
local function createCard(parent)
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.BackgroundColor3 = THEME.Row
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = parent
    round(card, 10)
    local stroke = newStroke(card, THEME.Line, 1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = card
    return card
end

-- title + sub-tabs across the top of a card. The title itself returns to the first panel,
-- so the main panel is always reachable after switching to a sub-tab.
local function createCardTabs(card, title, names)
    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 22)
    header.LayoutOrder = -1
    header.Parent = card

    local hLayout = Instance.new("UIListLayout")
    hLayout.FillDirection = Enum.FillDirection.Horizontal
    hLayout.Padding = UDim.new(0, 14)
    hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    hLayout.SortOrder = Enum.SortOrder.LayoutOrder
    hLayout.Parent = header

    local titleLabel = Instance.new("TextButton")
    titleLabel.LayoutOrder = 0
    titleLabel.AutoButtonColor = false
    titleLabel.BackgroundTransparency = 1
    titleLabel.AutomaticSize = Enum.AutomaticSize.X
    titleLabel.Size = UDim2.fromOffset(0, 22)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = THEME.On
    titleLabel.Text = title
    titleLabel.Parent = header

    local tabLabels = {}
    local panels = {}
    local firstName = nil

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.LayoutOrder = 1
    body.Parent = card

    local bLayout = Instance.new("UIListLayout")
    bLayout.Padding = UDim.new(0, 6)
    bLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bLayout.Parent = body

    local function select(name)
        for n, p in pairs(panels) do
            p.Visible = (n == name)
            if tabLabels[n] then
                tabLabels[n].TextColor3 = (n == name) and THEME.On or THEME.Dim
            end
        end
        titleLabel.TextColor3 = (name == firstName) and THEME.On or THEME.Text
    end

    titleLabel.MouseButton1Click:Connect(function()
        if firstName then select(firstName) end
    end)

    for order, name in ipairs(names or {}) do
        local btn = Instance.new("TextButton")
        btn.LayoutOrder = order
        btn.AutoButtonColor = false
        btn.BackgroundTransparency = 1
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.Size = UDim2.fromOffset(0, 22)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.TextColor3 = THEME.Dim
        btn.Text = name
        btn.Parent = header
        btn.MouseButton1Click:Connect(function() select(name) end)
        tabLabels[name] = btn
    end

    local api = {}
    function api.panel(name)
        local p = Instance.new("Frame")
        p.Name = name
        p.BackgroundTransparency = 1
        p.Size = UDim2.new(1, 0, 0, 0)
        p.AutomaticSize = Enum.AutomaticSize.Y
        p.Visible = false
        p.Parent = body
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = p
        panels[name] = p
        if not firstName then
            firstName = name
            select(name)
        end
        return p
    end
    return api
end

do
--// Aimbot tab (Combat)
currentPage = aimbotPage

local columns = Instance.new("Frame")
columns.Name = "Columns"
columns.BackgroundTransparency = 1
columns.Size = UDim2.new(1, -6, 0, 0)
columns.AutomaticSize = Enum.AutomaticSize.Y
columns.Parent = aimbotPage

local columnsLayout = Instance.new("UIListLayout")
columnsLayout.FillDirection = Enum.FillDirection.Horizontal
columnsLayout.Padding = UDim.new(0, 10)
columnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
columnsLayout.Parent = columns

local leftColumn = Instance.new("Frame")
leftColumn.BackgroundTransparency = 1
leftColumn.Size = UDim2.new(0.5, -5, 0, 0)
leftColumn.AutomaticSize = Enum.AutomaticSize.Y
leftColumn.Parent = columns
local leftLayout = Instance.new("UIListLayout")
leftLayout.Padding = UDim.new(0, 10)
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.Parent = leftColumn

local rightColumn = Instance.new("Frame")
rightColumn.BackgroundTransparency = 1
rightColumn.Size = UDim2.new(0.5, -5, 0, 0)
rightColumn.AutomaticSize = Enum.AutomaticSize.Y
rightColumn.Parent = columns
local rightLayout = Instance.new("UIListLayout")
rightLayout.Padding = UDim.new(0, 10)
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Parent = rightColumn

local function boneOptions()
    return {"Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}
end

local function createCardTitle(card, text)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.AutomaticSize = Enum.AutomaticSize.X
    titleLabel.Size = UDim2.fromOffset(0, 22)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = THEME.On
    titleLabel.Text = text
    titleLabel.LayoutOrder = -1
    titleLabel.Parent = card
    return titleLabel
end

-- Aimbot card
local aimbotCard = createCard(leftColumn)
local aimbotTabs = createCardTabs(aimbotCard, "Aimbot", {"Prediction", "Smoothness", "FOV"})

do
    local mainPanel = aimbotTabs.panel("Aimbot")
    TabBar.section = mainPanel

    local function lockToggleCallback(enabled)
        unbindLock()
        releaseLock()
        lockErrorWarned = false
        if enabled then
            stopSpectating()
            bindLock()
        end
    end
    setLockEnabled = createToggleWithHotkey("Enabled", "Lock", "LockKey", lockToggleCallback)
    createToggle("Hold Mode", "HoldMode")
    createToggle("Team Check", "IgnoreTeammates")
    createToggle("Visible Check", "WallCheck")
    createToggle("Health Check", "HealthCheck")
    createToggle("Sticky Aim", "StickyAim")

    createSlider("Distance", "MaxLockDistance", 20, 1000, 5)
    createSlider("Sensitivity", "Sensitivity", 0.05, 1, 0.05)

    local function refreshTargetPart()
        if targetPlayer and targetPlayer.Character then
            targetPart = resolveTargetPart(targetPlayer.Character) or targetPart
        end
    end
    createCycle("Hit Part", "TargetBone", boneOptions(), refreshTargetPart)
    local redraw = Config.refresh.TargetBone
    Config.refresh.TargetBone = function()
        redraw()
        refreshTargetPart()
    end
    createToggle("Randomize Hitbox", "RandomizeBone", refreshTargetPart)

    createCycle("Aim Type", "AimType", {"Mouse", "Controller"})

    createToggle("Rage Method", "RageMethod")
    createCycle("Type", "RageType", {"Camera Teleport", "Camera Lerp"})
end

do
    local pred = aimbotTabs.panel("Prediction")
    TabBar.section = pred
    createToggle("Prediction", "Prediction")
    createSlider("Lead Amount", "PredictionAmount", 0, 1, 0.05)
end

do
    local smooth = aimbotTabs.panel("Smoothness")
    TabBar.section = smooth
    createSlider("Camlock Leash (degrees)", "LeashAngle", 5, 60, 1)
    createToggle("Humanized", "Humanized")
end

do
    local fov = aimbotTabs.panel("FOV")
    TabBar.section = fov
    createToggle("Restrict To FOV", "UseFOV")
    createSlider("Circle Fov", "FOVRadius", 30, 600, 5)
    createToggle("Show FOV", "ShowFOV")
    createColorPicker("FOV Circle Color", "CircleColor")
end

-- Misc card (left column, under Aimbot)
do
    local miscCard = createCard(leftColumn)
    TabBar.section = miscCard
    TabBar.combatMisc = miscCard
    createCardTitle(miscCard, "Misc")
    createToggle("Resolver", "Resolver")
end

-- Silent Aim card
local silentCard = createCard(rightColumn)
local silentTabs = createCardTabs(silentCard, "Silent Aim", {"Prediction", "FOV"})

do
    local mainPanel = silentTabs.panel("Silent Aim")
    TabBar.section = mainPanel

    createToggleWithHotkey("Enabled", "SilentAim", "SilentAimToggleKey", function(enabled)
        if enabled and SilentAim.installMouseHook then SilentAim.installMouseHook() end
    end)
    createToggle("Team Check", "SilentAimIgnoreTeammates")
    createToggle("Visible Check", "SilentAimWallCheck")
    createToggle("Health Check", "SilentAimHealthCheck")
    createToggle("Sticky Aim", "SilentAimSticky")
    createSlider("Distance", "SilentAimDistance", 50, 2000, 10)
    createCycle("Hit Part", "SilentAimBone", boneOptions())
end

do
    local pred = silentTabs.panel("Prediction")
    TabBar.section = pred
    createToggle("Prediction", "SilentAimPrediction")
    createSlider("Lead Amount", "SilentAimPredictionAmount", 0, 1, 0.05)
end

do
    local fov = silentTabs.panel("FOV")
    TabBar.section = fov
    createToggle("Show FOV", "SilentAimShowFOV")
    createSlider("Silent Aim FOV", "SilentAimFOV", 10, 600, 5)
    createCycle("Trigger", "SilentAimMode", {"Always", "Hold"})
    createHotkeyRow("Silent Aim Hold Key", "SilentAimKey")
end

-- Trigger Bot card (right column, under Silent Aim)
do
    local triggerCard = createCard(rightColumn)
    TabBar.section = triggerCard
    createCardTitle(triggerCard, "Trigger Bot")

    local function triggerCallback(enabled)
        if enabled then TriggerBot.start() else TriggerBot.stop() end
    end
    createToggleWithHotkey("Enabled", "TriggerBot", "TriggerBotKey", triggerCallback)
    createToggle("Visible Check", "TriggerBotWallCheck")
    createToggle("Team Check", "TriggerBotTeamCheck")
    createSlider("Hitbox Mul", "TriggerBotHitboxMul", 0.1, 3, 0.05)
    createSlider("Delay (ms)", "TriggerBotDelay", 0, 500, 1)
    createSlider("Release (ms)", "TriggerBotRelease", 0, 500, 1)
    Config.cleanups[#Config.cleanups + 1] = TriggerBot.stop
    if state.TriggerBot then TriggerBot.start() end
end

end

--// ESP tab
currentPage = espPage
createSection("ESP")
Module.begin("ESP", "ESP", function(enabled)
    if not enabled then clearAllESP() end
end)
createToggle("Hide Teammates", "HideTeammates")
createToggle("Use Team Colors", "TeamColor")
createToggle("Fade With Distance", "FadeWithDistance")
createToggle("Show Names", "ShowName")
createToggle("Show Distance", "ShowDistance")
createToggle("Show Health Bar", "ShowHealth")
createToggle("Show Held Tool", "ShowTool")
createSlider("Text Size", "TextSize", 10, 22, 1)
createColorPicker("ESP Color", "ESPColor")

Module.begin("Box ESP", "ShowBox")
createCycle("Box Style", "BoxStyle", {"Full", "Corners"})
createToggle("Box Fill", "BoxFill")

Module.begin("Tracers", "ShowTracer")
createCycle("Tracer Origin", "TracerOrigin", {"Bottom", "Center", "Mouse"})

Module.finish()
createToggle("Skeleton ESP", "ShowSkeleton")

Module.begin("Outline Highlight", "ShowHighlight")
createToggle("Use Global ESP Color", "OutlineGlobal")
createColorPicker("Outline Color", "OutlineColor")

Module.begin("Chams", "ShowChams")
createSlider("Chams Opacity (%)", "ChamsOpacity", 10, 100, 5)
createToggle("Use Global ESP Color", "ChamsGlobal")
createColorPicker("Chams Color", "ChamsColor")

Module.finish()

createSection("Friends & Enemies")
createColorPicker("Friend Color", "FriendColor", function() if Rel.redraw then Rel.redraw() end end)
createColorPicker("Enemy Color", "EnemyColor", function() if Rel.redraw then Rel.redraw() end end)
do
    local header = createRow("Player List", 32)
    local toggleButton = createRowButton(header, "OPEN", 84)
    addHover(toggleButton, function() return THEME.Button end)

    local listBox = Instance.new("Frame")
    listBox.Name = "RelationList"
    listBox.Size = UDim2.new(1, -6, 0, 0)
    listBox.AutomaticSize = Enum.AutomaticSize.Y
    listBox.BackgroundTransparency = 1
    listBox.Visible = false
    listBox.Parent = espPage

    local boxLayout = Instance.new("UIListLayout")
    boxLayout.Padding = UDim.new(0, 4)
    boxLayout.SortOrder = Enum.SortOrder.LayoutOrder
    boxLayout.Parent = listBox

    local searchFrame = Instance.new("Frame")
    searchFrame.LayoutOrder = 1
    searchFrame.Size = UDim2.new(1, 0, 0, 32)
    searchFrame.BackgroundColor3 = THEME.Row
    searchFrame.BackgroundTransparency = THEME.PanelT
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = listBox
    round(searchFrame, 4)

    local searchBox = Instance.new("TextBox")
    searchBox.Position = UDim2.fromOffset(8, 5)
    searchBox.Size = UDim2.new(1, -16, 0, 22)
    searchBox.BackgroundColor3 = THEME.Button
    searchBox.BorderSizePixel = 0
    searchBox.Font = Enum.Font.GothamMedium
    searchBox.TextSize = 12
    searchBox.TextColor3 = THEME.Text
    searchBox.PlaceholderText = "Search players..."
    searchBox.PlaceholderColor3 = THEME.Dim
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchFrame
    round(searchBox, 3)
    local searchOutline = newStroke(searchBox, THEME.ButtonLine, 1.5)
    searchOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local searchPad = Instance.new("UIPadding")
    searchPad.PaddingLeft = UDim.new(0, 8)
    searchPad.Parent = searchBox

    local emptyNote = Instance.new("TextLabel")
    emptyNote.LayoutOrder = 9999
    emptyNote.Size = UDim2.new(1, 0, 0, 30)
    emptyNote.BackgroundTransparency = 1
    emptyNote.Font = Enum.Font.Gotham
    emptyNote.TextSize = 12
    emptyNote.TextColor3 = THEME.Dim
    emptyNote.Text = "No players found"
    emptyNote.Parent = listBox

    local rows = {}

    local function drawRow(player)
        local r = rows[player]
        if not r then return end
        local kind = Rel.map[player.UserId]
        r.friend.BackgroundColor3 = kind == "friend" and state.FriendColor or THEME.Button
        r.friend.TextColor3 = WHITE
        r.enemy.BackgroundColor3 = kind == "enemy" and state.EnemyColor or THEME.Button
        r.enemy.TextColor3 = WHITE
    end

    local function drawAll()
        for player in pairs(rows) do drawRow(player) end
    end
    Rel.redraw = drawAll

    local function reorder()
        local list = {}
        for player in pairs(rows) do list[#list + 1] = player end
        local function rank(player)
            local kind = Rel.map[player.UserId]
            return kind == "enemy" and 1 or (kind == "friend" and 2 or 3)
        end
        table.sort(list, function(a, b)
            local ra, rb = rank(a), rank(b)
            if ra ~= rb then return ra < rb end
            return a.DisplayName:lower() < b.DisplayName:lower()
        end)
        for i, player in ipairs(list) do rows[player].frame.LayoutOrder = 10 + i end
    end

    local function applyFilter()
        local query = searchBox.Text:lower():match("^%s*(.-)%s*$")
        local shown = 0
        for player, r in pairs(rows) do
            local match = query == ""
                or player.DisplayName:lower():find(query, 1, true) ~= nil
                or player.Name:lower():find(query, 1, true) ~= nil
            r.frame.Visible = match
            if match then shown += 1 end
        end
        emptyNote.Visible = shown == 0
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

    local function setKind(player, kind)
        if Rel.map[player.UserId] == kind then
            Rel.map[player.UserId] = nil
        else
            Rel.map[player.UserId] = kind
        end
        drawRow(player)
        reorder()
        Rel.save()
    end

    -- round face icon: ":)" / ":(" rotated a quarter turn reads as a smile / an upside-down smile
    local function addFace(button, happy)
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromScale(0.5, 0.5)
        ring.Size = UDim2.fromOffset(18, 18)
        ring.BackgroundTransparency = 1
        ring.ZIndex = button.ZIndex + 1
        ring.Parent = button
        round(ring, 9)
        newStroke(ring, WHITE, 1.5)

        local face = Instance.new("TextLabel")
        face.AnchorPoint = Vector2.new(0.5, 0.5)
        face.Position = UDim2.fromScale(0.5, 0.5)
        face.Size = UDim2.fromScale(1, 1)
        face.BackgroundTransparency = 1
        face.Font = Enum.Font.GothamBold
        face.TextSize = 10
        face.TextColor3 = WHITE
        face.Text = happy and ":)" or ":("
        face.Rotation = 90
        face.ZIndex = button.ZIndex + 2
        face.Parent = ring
    end

    local function addRow(player)
        if player == LocalPlayer or rows[player] then return end

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = THEME.Row
        frame.BackgroundTransparency = THEME.PanelT
        frame.BorderSizePixel = 0
        frame.Parent = listBox
        round(frame, 4)

        local display = Instance.new("TextLabel")
        display.Position = UDim2.fromOffset(10, 3)
        display.Size = UDim2.new(1, -140, 0, 16)
        display.BackgroundTransparency = 1
        display.Font = Enum.Font.GothamBold
        display.TextSize = 12
        display.TextColor3 = THEME.Text
        display.TextXAlignment = Enum.TextXAlignment.Left
        display.TextTruncate = Enum.TextTruncate.AtEnd
        display.Text = player.DisplayName
        display.Parent = frame

        local username = Instance.new("TextLabel")
        username.Position = UDim2.fromOffset(10, 19)
        username.Size = UDim2.new(1, -140, 0, 14)
        username.BackgroundTransparency = 1
        username.Font = Enum.Font.Gotham
        username.TextSize = 10
        username.TextColor3 = THEME.Dim
        username.TextXAlignment = Enum.TextXAlignment.Left
        username.TextTruncate = Enum.TextTruncate.AtEnd
        username.Text = "@" .. player.Name
        username.Parent = frame

        local function makeButton(happy, xOffset)
            local b = Instance.new("TextButton")
            b.Size = UDim2.fromOffset(54, 22)
            b.Position = UDim2.new(1, xOffset, 0.5, -11)
            b.BackgroundColor3 = THEME.Button
            b.Font = Enum.Font.GothamBold
            b.TextSize = 9
            b.TextColor3 = THEME.Text
            b.Text = ""
            b.AutoButtonColor = false
            b.Parent = frame
            round(b, 3)
            local outline = newStroke(b, THEME.ButtonLine, 1.5)
            outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            addFace(b, happy)
            return b
        end

        local friendButton = makeButton(true, -120)
        local enemyButton = makeButton(false, -62)
        friendButton.MouseButton1Click:Connect(function() setKind(player, "friend") end)
        enemyButton.MouseButton1Click:Connect(function() setKind(player, "enemy") end)

        rows[player] = {frame = frame, friend = friendButton, enemy = enemyButton}
        drawRow(player)
        reorder()
        applyFilter()
    end

    for _, player in ipairs(Players:GetPlayers()) do addRow(player) end
    applyFilter()

    trackConnection(Players.PlayerAdded:Connect(addRow))
    trackConnection(Players.PlayerRemoving:Connect(function(player)
        local r = rows[player]
        if r then
            rows[player] = nil
            r.frame:Destroy()
            applyFilter()
        end
    end))

    local open = false
    toggleButton.MouseButton1Click:Connect(function()
        open = not open
        listBox.Visible = open
        toggleButton.Text = open and "CLOSE" or "OPEN"
        if open then
            drawAll()
            reorder()
        end
    end)
end

--// Visual tab
currentPage = visualPage

createSection("Skybox")
do
    local Lighting = game:GetService("Lighting")
    local ContentProvider = game:GetService("ContentProvider")
    local FACES = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}

    local sky, created, saved = nil, false, nil
    local token = 0
    local statusLabel = nil
    local modelCache = {}
    local listButtons = {}
    local headerLabel = nil
    local drawList

    local function setStatus(text)
        if statusLabel then statusLabel.Text = text end
    end

    local function toContent(id)
        id = tostring(id)
        if id:find("^rbx") or id:find("^http") then return id end
        return "rbxassetid://" .. id
    end

    local function fetchObjects(assetId)
        local url = "rbxassetid://" .. assetId
        local ok, result = pcall(function() return game:GetObjects(url) end)
        if ok and type(result) == "table" and #result > 0 then return result end
        if type(getobjects) == "function" then
            ok, result = pcall(getobjects, url)
            if ok and type(result) == "table" and #result > 0 then return result end
        end
        return nil
    end

    local function loadModelFaces(assetId)
        local cached = modelCache[assetId]
        if cached then return cached end

        local objects = fetchObjects(assetId)
        if not objects then return nil end

        local faces = nil
        for _, root in ipairs(objects) do
            local found = nil
            if root:IsA("Sky") then
                found = root
            else
                found = root:FindFirstChildWhichIsA("Sky", true)
            end
            if found then
                local list, filled = {}, 0
                for i, face in ipairs(FACES) do
                    local value = found[face]
                    list[i] = value
                    if value ~= "" then filled += 1 end
                end
                if filled > 0 then
                    faces = list
                    break
                end
            end
        end
        for _, root in ipairs(objects) do pcall(function() root:Destroy() end) end

        if faces then modelCache[assetId] = faces end
        return faces
    end

    local function expandIds(ids)
        if type(ids) == "string" then ids = {ids} end
        local faces = {}
        for i = 1, 6 do faces[i] = toContent(ids[#ids == 1 and 1 or i]) end
        return faces
    end

    local function restore()
        token += 1
        if sky and sky.Parent then
            if created then
                sky:Destroy()
            elseif saved then
                for property, value in pairs(saved) do
                    pcall(function() sky[property] = value end)
                end
            end
        end
        sky, created, saved = nil, false, nil
    end

    local function ensureSky()
        if sky and sky.Parent then return sky end
        sky, created, saved = nil, false, nil
        local existing = Lighting:FindFirstChildOfClass("Sky")
        if existing then
            sky = existing
            saved = {CelestialBodiesShown = existing.CelestialBodiesShown}
            for _, face in ipairs(FACES) do saved[face] = existing[face] end
        else
            sky = Instance.new("Sky")
            sky.Name = randomName()
            sky.Parent = Lighting
            created = true
        end
        return sky
    end

    local function resolveFaces(choice)
        for _, entry in ipairs(Config.skies) do
            if entry.name == choice then
                if entry.model then
                    local faces = loadModelFaces(entry.model)
                    if faces then return faces end
                    return nil, "Could not load the " .. choice .. " skybox (asset " .. entry.model .. ")"
                end
                return expandIds(entry.ids)
            end
        end
        return nil, "Unknown skybox"
    end

    local function apply()
        local choice = state.SkyPreset
        if choice == "Off" then
            restore()
            setStatus("Skybox off")
            return
        end

        token += 1
        local mine = token
        setStatus("Loading " .. choice .. "...")
        task.spawn(function()
            local faces, message = resolveFaces(choice)
            if mine ~= token then return end
            if not faces then
                setStatus(message or "Failed to load skybox")
                return
            end

            local target = ensureSky()
            for i, face in ipairs(FACES) do
                target[face] = faces[i]
            end
            target.CelestialBodiesShown = false

            pcall(function() ContentProvider:PreloadAsync({target}) end)
            if mine ~= token then return end
            local failed = false
            for _, face in ipairs(FACES) do
                local ok, bad = pcall(function()
                    local status = ContentProvider:GetAssetFetchStatus(target[face])
                    return status == Enum.AssetFetchStatus.Failure or status == Enum.AssetFetchStatus.TimedOut
                end)
                if ok and bad then failed = true end
            end
            setStatus(failed and "Loaded, but a texture failed to download" or choice)
        end)
    end

    local header, label = createRow("Skybox", 32)
    headerLabel = label
    local openButton = createRowButton(header, "OPEN", 84)
    addHover(openButton, function() return THEME.Button end)

    local listBox = Instance.new("Frame")
    listBox.Name = "SkyList"
    listBox.Size = UDim2.new(1, 0, 0, 0)
    listBox.AutomaticSize = Enum.AutomaticSize.Y
    listBox.BackgroundTransparency = 1
    listBox.Visible = false
    listBox.Parent = TabBar.section

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listBox

    drawList = function()
        headerLabel.Text = "Skybox: " .. state.SkyPreset
        for name, button in pairs(listButtons) do
            local active = state.SkyPreset == name
            button.Text = active and "ACTIVE" or "SELECT"
            tween(button, {BackgroundColor3 = active and THEME.ButtonActive or THEME.Button}, 0.15)
        end
    end

    for i, name in ipairs(Config.skyOptions) do
        do
            local previous = TabBar.section
            TabBar.section = listBox
            local row = createRow(name, 30)
            TabBar.section = previous
            row.LayoutOrder = i

            local button = createRowButton(row, "SELECT", 76)
            addHover(button, function()
                return state.SkyPreset == name and THEME.ButtonActive or THEME.Button
            end)
            button.MouseButton1Click:Connect(function()
                state.SkyPreset = name
                scheduleSave()
                drawList()
                apply()
            end)
            listButtons[name] = button
        end
    end

    local open = false
    openButton.MouseButton1Click:Connect(function()
        open = not open
        listBox.Visible = open
        openButton.Text = open and "CLOSE" or "OPEN"
    end)

    Config.refresh.SkyPreset = drawList
    Config.visualApplies[#Config.visualApplies + 1] = apply
    Config.cleanups[#Config.cleanups + 1] = restore
    drawList()
    apply()
end

createSection("Effects")

do
    local conns = {}
    local lastEffect = 0
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local function colorAt(i)
        if state.JumpRainbow then
            return Color3.fromHSV((os.clock() * 0.35 + i * 0.07) % 1, 0.75, 1)
        end
        return state.JumpColor
    end

    local function newPart(holder)
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Parent = holder
        return part
    end

    local function ring(holder, origin, color, diameter, duration, thickness)
        local part = newPart(holder)
        part.Transparency = 1
        part.Size = Vector3.new(1, 0.05, 1)
        part.CFrame = CFrame.new(origin)

        local surface = Instance.new("SurfaceGui")
        surface.Face = Enum.NormalId.Top
        surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
        surface.CanvasSize = Vector2.new(256, 256)
        surface.LightInfluence = 0
        surface.Brightness = 2
        surface.Parent = part

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundTransparency = 1
        frame.Parent = surface
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = frame
        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = thickness
        stroke.Parent = frame

        local info = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(part, info, {Size = Vector3.new(diameter, 0.05, diameter)}):Play()
        TweenService:Create(stroke, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Transparency = 1, Thickness = 2}):Play()
        task.delay(duration + 0.1, function() part:Destroy() end)
    end

    local function flash(holder, origin, color, radius)
        local ball = newPart(holder)
        ball.Shape = Enum.PartType.Ball
        ball.Color = color
        ball.Transparency = 0.2
        ball.Size = Vector3.new(0.6, 0.6, 0.6)
        ball.CFrame = CFrame.new(origin + Vector3.new(0, 0.3, 0))
        local size = radius * 0.45
        local tw = TweenService:Create(ball, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(size, size, size), Transparency = 1})
        tw:Play()
        task.delay(0.45, function() ball:Destroy() end)
    end

    local function sparks(holder, origin, color, count)
        local part = newPart(holder)
        part.Transparency = 1
        part.Size = Vector3.one
        part.CFrame = CFrame.new(origin + Vector3.new(0, 0.3, 0))

        local emitter = Instance.new("ParticleEmitter")
        emitter.Color = ColorSequence.new(color, colorAt(5))
        emitter.LightEmission = 1
        emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0)})
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Lifetime = NumberRange.new(0.45, 0.9)
        emitter.Speed = NumberRange.new(9, 20)
        emitter.SpreadAngle = Vector2.new(70, 70)
        emitter.Acceleration = Vector3.new(0, -26, 0)
        emitter.Drag = 1.5
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.Rate = 0
        emitter.Parent = part
        emitter:Emit(count)
        task.delay(1.6, function() part:Destroy() end)
    end

    local function effect(origin, scale)
        local holder = workspace.CurrentCamera or workspace
        local radius = state.JumpSize * scale
        local rings = scale >= 1 and 3 or 2

        flash(holder, origin, colorAt(0), radius)
        for i = 1, rings do
            task.delay((i - 1) * 0.06, function()
                ring(holder, origin, colorAt(i), radius * (0.55 + i * 0.3), 0.5 + i * 0.12, 16 - i * 3)
            end)
        end
        sparks(holder, origin, colorAt(0), scale >= 1 and 30 or 14)
    end

    local function groundPoint(char, root)
        rayParams.FilterDescendantsInstances = {char}
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), rayParams)
        if hit then return hit.Position + Vector3.new(0, 0.08, 0) end
        return root.Position - Vector3.new(0, 3, 0)
    end

    local function hook(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local airStart = nil
        conns[#conns + 1] = hum.StateChanged:Connect(function(_, new)
            if not state.JumpVisuals then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local now = os.clock()

            if new == Enum.HumanoidStateType.Jumping then
                airStart = airStart or now
                if now - lastEffect < 0.15 then return end
                lastEffect = now
                effect(groundPoint(char, root), 1)
            elseif new == Enum.HumanoidStateType.Freefall then
                airStart = airStart or now
            elseif new == Enum.HumanoidStateType.Landed then
                local air = airStart and (now - airStart) or 0
                airStart = nil
                if air > 0.35 and now - lastEffect > 0.15 then
                    lastEffect = now
                    effect(groundPoint(char, root), 0.55)
                end
            else
                airStart = nil
            end
        end)
    end

    local function disable()
        for _, connection in ipairs(conns) do connection:Disconnect() end
        table.clear(conns)
    end

    local function enable()
        disable()
        local char = LocalPlayer.Character
        if char then task.spawn(hook, char) end
        conns[#conns + 1] = LocalPlayer.CharacterAdded:Connect(function(newChar)
            task.spawn(hook, newChar)
        end)
    end

    Module.begin("Jump Visuals", "JumpVisuals", function(enabled)
        if enabled then enable() else disable() end
    end)
    createToggle("Rainbow", "JumpRainbow")
    createColorPicker("Effect Color", "JumpColor")
    createSlider("Effect Size", "JumpSize", 6, 40, 1)

    if state.JumpVisuals then enable() end
    Config.cleanups[#Config.cleanups + 1] = disable
end

do
    local Lighting = game:GetService("Lighting")
    local effect = nil

    local function apply()
        if state.ColorOn then
            if not effect or not effect.Parent then
                effect = Instance.new("ColorCorrectionEffect")
                effect.Name = randomName()
                effect.Parent = Lighting
            end
            effect.Brightness = state.ColorBrightness
            effect.Contrast = state.ColorContrast
            effect.Saturation = state.ColorSaturation
            effect.TintColor = state.ColorTint
        elseif effect then
            effect:Destroy()
            effect = nil
        end
    end

    Module.begin("Color Correction", "ColorOn", apply)
    createSlider("Brightness", "ColorBrightness", -0.5, 0.5, 0.05, apply)
    createSlider("Contrast", "ColorContrast", -0.5, 1, 0.05, apply)
    createSlider("Saturation", "ColorSaturation", -1, 2, 0.05, apply)
    createColorPicker("Tint Color", "ColorTint", apply)

    Config.visualApplies[#Config.visualApplies + 1] = apply
    Config.cleanups[#Config.cleanups + 1] = function()
        if effect then effect:Destroy() end
        effect = nil
    end
    apply()
end

do
    local Lighting = game:GetService("Lighting")
    local effect = nil

    local function apply()
        if state.BloomOn then
            if not effect or not effect.Parent then
                effect = Instance.new("BloomEffect")
                effect.Name = randomName()
                effect.Parent = Lighting
            end
            effect.Enabled = true
            effect.Intensity = state.BloomIntensity
            effect.Size = state.BloomSize
            effect.Threshold = state.BloomThreshold
        elseif effect then
            effect:Destroy()
            effect = nil
        end
    end

    Module.begin("Bloom", "BloomOn", apply)
    createSlider("Intensity", "BloomIntensity", 0, 3, 0.1, apply)
    createSlider("Size", "BloomSize", 0, 56, 1, apply)
    createSlider("Threshold", "BloomThreshold", 0, 2, 0.05, apply)

    -- some games strip post effects from Lighting, so put it back if it disappears
    local lastCheck = 0
    trackConnection(RunService.Heartbeat:Connect(function()
        if not state.BloomOn then return end
        local now = os.clock()
        if now - lastCheck < 1 then return end
        lastCheck = now
        if not effect or not effect.Parent then apply() end
    end))

    Config.visualApplies[#Config.visualApplies + 1] = apply
    Config.cleanups[#Config.cleanups + 1] = function()
        if effect then effect:Destroy() end
        effect = nil
    end
    apply()
end

do
    local name = randomName()
    local bound = false
    local lastCFrame = nil

    local function step()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local cframe = camera.CFrame
        if cframe == lastCFrame then return end
        camera.CFrame = cframe * CFrame.new(0, 0, 0, 1, 0, 0, 0, state.StretchAmount / 100, 0, 0, 0, 1)
        lastCFrame = camera.CFrame
    end

    local function stop()
        if bound then
            pcall(function() RunService:UnbindFromRenderStep(name) end)
            bound = false
        end
        lastCFrame = nil
    end

    local function start()
        stop()
        bound = pcall(function()
            RunService:BindToRenderStep(name, Enum.RenderPriority.Last.Value + 1, step)
        end)
    end

    Module.begin("Stretched Resolution", "StretchOn", function(enabled)
        if enabled then start() else stop() end
    end)
    createSlider("Stretch (% height)", "StretchAmount", 40, 100, 1)

    if state.StretchOn then start() end
    Config.cleanups[#Config.cleanups + 1] = stop
end


createSection("Trail")
do
    local root, trail, att0, att1 = nil, nil, nil, nil

    local function rainbowSequence()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0.85, 1)),
            ColorSequenceKeypoint.new(0.25, Color3.fromHSV(0.25, 0.85, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 0.85, 1)),
            ColorSequenceKeypoint.new(0.75, Color3.fromHSV(0.75, 0.85, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 0.85, 1)),
        })
    end

    local function apply()
        if not (trail and att0 and att1) then return end
        att0.Position = Vector3.new(0, state.TrailWidth / 2, 0)
        att1.Position = Vector3.new(0, -state.TrailWidth / 2, 0)
        trail.Lifetime = state.TrailLength
        trail.Color = state.TrailRainbow and rainbowSequence() or ColorSequence.new(state.TrailColor)
    end

    local function destroyTrail()
        if trail then trail:Destroy() end
        trail, att0, att1, root = nil, nil, nil, nil
    end

    local function buildTrail(char)
        destroyTrail()
        root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
        if not root or not state.TrailOn then return end

        att0 = Instance.new("Attachment")
        att0.Name = randomName()
        att0.Parent = root

        att1 = Instance.new("Attachment")
        att1.Name = randomName()
        att1.Parent = root

        trail = Instance.new("Trail")
        trail.Name = randomName()
        trail.MinLength = 0
        trail.FaceCamera = true
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        trail.Parent = root
        apply()
    end

    local conn

    local function disable()
        if conn then conn:Disconnect(); conn = nil end
        destroyTrail()
    end

    local function enable()
        disable()
        local char = LocalPlayer.Character
        if char then task.spawn(buildTrail, char) end
        conn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            task.spawn(buildTrail, newChar)
        end)
    end

    Module.begin("Trail", "TrailOn", function(enabled)
        if enabled then enable() else disable() end
    end)
    createToggle("Rainbow", "TrailRainbow", apply)
    createColorPicker("Color", "TrailColor", apply)
    createSlider("Width", "TrailWidth", 0.2, 3, 0.1, apply)
    createSlider("Length", "TrailLength", 0.1, 2, 0.05, apply)

    if state.TrailOn then enable() end
    Config.cleanups[#Config.cleanups + 1] = disable
end

createSection("Crosshair")
do
    local layer = Instance.new("Frame")
    layer.Name = randomName()
    layer.AnchorPoint = Vector2.new(0.5, 0.5)
    layer.Position = UDim2.fromScale(0.5, 0.5)
    layer.Size = UDim2.fromOffset(0, 0)
    layer.BackgroundTransparency = 1
    layer.ZIndex = 2
    layer.Visible = state.CrosshairOn
    layer.Parent = gui

    local function bar()
        local b = Instance.new("Frame")
        b.AnchorPoint = Vector2.new(0.5, 0.5)
        b.BorderSizePixel = 0
        b.ZIndex = 2
        b.Parent = layer
        local outline = newStroke(b, BLACK, 1)
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        return b, outline
    end

    local top, topOutline = bar()
    local bottom, bottomOutline = bar()
    local left, leftOutline = bar()
    local right, rightOutline = bar()
    local bars = {top, bottom, left, right}

    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.BorderSizePixel = 0
    dot.ZIndex = 2
    dot.Parent = layer
    round(dot, 6)
    local dotOutline = newStroke(dot, BLACK, 1)
    dotOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    -- Big Yahu: star-of-david crosshair style, drawn as two overlapping triangles
    local starLines, starOutlines = {}, {}
    for i = 1, 6 do
        local b, bOutline = bar()
        starLines[i] = b
        starOutlines[i] = bOutline
    end

    local function trianglePoints(radius, pointDown)
        local base = pointDown and 90 or -90
        local pts = {}
        for i = 0, 2 do
            local a = rad(base + i * 120)
            pts[i + 1] = Vector2.new(math.cos(a) * radius, math.sin(a) * radius)
        end
        return pts
    end

    local function layoutStar(radius, thickness)
        local up = trianglePoints(radius, false)
        local down = trianglePoints(radius, true)
        local idx = 1
        for _, tri in ipairs({up, down}) do
            for e = 1, 3 do
                local p1, p2 = tri[e], tri[(e % 3) + 1]
                local dx, dy = p2.X - p1.X, p2.Y - p1.Y
                local line = starLines[idx]
                line.Size = UDim2.fromOffset(sqrt(dx * dx + dy * dy), thickness)
                line.Position = UDim2.fromOffset((p1.X + p2.X) * 0.5, (p1.Y + p2.Y) * 0.5)
                line.Rotation = deg(atan2(dy, dx))
                idx += 1
            end
        end
    end

    local outlines = {topOutline, bottomOutline, leftOutline, rightOutline, dotOutline}
    for i = 1, 6 do outlines[#outlines + 1] = starOutlines[i] end

    local function apply()
        local size, thickness, gap = state.CrosshairSize, state.CrosshairThickness, state.CrosshairGap
        local offset = gap + size / 2

        top.Size = UDim2.fromOffset(thickness, size)
        top.Position = UDim2.fromOffset(0, -offset)
        bottom.Size = UDim2.fromOffset(thickness, size)
        bottom.Position = UDim2.fromOffset(0, offset)
        left.Size = UDim2.fromOffset(size, thickness)
        left.Position = UDim2.fromOffset(-offset, 0)
        right.Size = UDim2.fromOffset(size, thickness)
        right.Position = UDim2.fromOffset(offset, 0)
        dot.Size = UDim2.fromOffset(thickness + 2, thickness + 2)

        local showCross = state.CrosshairStyle == "Cross" or state.CrosshairStyle == "Cross + Dot"
        local showDot = state.CrosshairStyle == "Dot" or state.CrosshairStyle == "Cross + Dot"
        local showStar = state.CrosshairStyle == "Big Yahu"

        if showStar then layoutStar(size * 1.1, maxn(thickness - 1, 1)) end

        for _, b in ipairs(bars) do b.BackgroundColor3 = state.CrosshairColor end
        dot.BackgroundColor3 = state.CrosshairColor
        for i = 1, 6 do starLines[i].BackgroundColor3 = state.CrosshairColor end
        for _, o in ipairs(outlines) do o.Enabled = state.CrosshairOutline end

        for _, b in ipairs(bars) do b.Visible = showCross end
        dot.Visible = showDot
        for i = 1, 6 do starLines[i].Visible = showStar end
    end

    -- crosshair spin: rotates the whole crosshair layer continuously while enabled
    local spinConn = nil
    local function setSpin(enabled)
        if enabled then
            if spinConn then return end
            spinConn = RunService.RenderStepped:Connect(function(dt)
                layer.Rotation = (layer.Rotation + state.CrosshairSpinSpeed * dt) % 360
            end)
        else
            if spinConn then spinConn:Disconnect(); spinConn = nil end
            layer.Rotation = 0
        end
    end

    Module.begin("Crosshair", "CrosshairOn", function(enabled)
        layer.Visible = enabled
    end)
    createCycle("Style", "CrosshairStyle", {"Cross", "Dot", "Cross + Dot", "Big Yahu"}, apply)
    createColorPicker("Color", "CrosshairColor", apply)
    createSlider("Size", "CrosshairSize", 2, 30, 1, apply)
    createSlider("Thickness", "CrosshairThickness", 1, 6, 1, apply)
    createSlider("Gap", "CrosshairGap", 0, 20, 1, apply)
    createToggle("Outline", "CrosshairOutline", apply)
    createToggle("Spin", "CrosshairSpin", setSpin)
    createSlider("Spin Speed", "CrosshairSpinSpeed", 10, 1080, 10)

    apply()
    if state.CrosshairSpin then setSpin(true) end
    Config.cleanups[#Config.cleanups + 1] = function()
        setSpin(false)
        layer:Destroy()
    end
end

Module.finish()

--// Spectate tab
currentPage = spectatePage

local addPlayerRow, removePlayerRow
local thumbCache = {}
do
createSection("Players")

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.fromOffset(8, 5)
searchBox.Size = UDim2.new(1, -16, 0, 22)
searchBox.BackgroundColor3 = THEME.Button
searchBox.BorderSizePixel = 0
searchBox.Font = Enum.Font.GothamMedium
searchBox.TextSize = 12
searchBox.TextColor3 = THEME.Text
searchBox.PlaceholderText = "Search players..."
searchBox.PlaceholderColor3 = THEME.Dim
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
round(searchBox, 3)
do
    local searchRow, searchHint = createRow("", 32)
    searchRow.LayoutOrder = 1
    searchHint.Visible = false
    searchBox.Parent = searchRow
    local outline = newStroke(searchBox, THEME.ButtonLine, 1.5)
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = searchBox
end

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Name = "EmptyMessage"
emptyLabel.Size = UDim2.new(1, -6, 0, 36)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Text = "No other players found"
emptyLabel.TextColor3 = THEME.Dim
emptyLabel.TextSize = 12
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.LayoutOrder = 9999
emptyLabel.Parent = spectatePage

rowBase = function(player)
    return spectateTarget == player and THEME.RowActive or THEME.Row
end

local favorites = genv.__ESP_LOCK_FAVS
local saveFavorites
do
    local HttpService = game:GetService("HttpService")
    local FAV_FILE = "BunHub_Favorites.json"

    if type(favorites) ~= "table" then
        favorites = {}
        pcall(function()
            if type(isfile) == "function" and type(readfile) == "function" and isfile(FAV_FILE) then
                for _, id in ipairs(HttpService:JSONDecode(readfile(FAV_FILE))) do favorites[id] = true end
            end
        end)
        genv.__ESP_LOCK_FAVS = favorites
    end

    saveFavorites = function()
        pcall(function()
            if type(writefile) ~= "function" then return end
            local ids = {}
            for id in pairs(favorites) do ids[#ids + 1] = id end
            writefile(FAV_FILE, HttpService:JSONEncode(ids))
        end)
    end
end

local function reorderRows()
    local list = {}
    for player in pairs(playerRows) do list[#list + 1] = player end
    table.sort(list, function(a, b)
        local fa, fb = favorites[a.UserId] == true, favorites[b.UserId] == true
        if fa ~= fb then return fa end
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)
    for i, player in ipairs(list) do
        playerRows[player].LayoutOrder = (favorites[player.UserId] and 10 or 200) + i
    end
end

local function applySearch()
    local query = searchBox.Text:lower():match("^%s*(.-)%s*$")
    local shown = 0
    for player, row in pairs(playerRows) do
        local match = query == ""
            or player.DisplayName:lower():find(query, 1, true) ~= nil
            or player.Name:lower():find(query, 1, true) ~= nil
        row.Visible = match
        if match then shown += 1 end
    end
    emptyLabel.Visible = shown == 0
    emptyLabel.Text = next(playerRows) == nil and "No other players found" or "No players match your search"
end

searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

local expandedPlayer = nil
local function setExpanded(player, on)
    local row = playerRows[player]
    if not row then return end
    if on then
        expandedPlayer = player
    elseif expandedPlayer == player then
        expandedPlayer = nil
    end
    tween(row, {Size = UDim2.new(1, -6, 0, on and 82 or 46)}, 0.18)
end

local function teleportToPlayer(player)
    local lchar = getAlive(LocalPlayer)
    local lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")
    local troot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not lroot or not troot then return false end
    lroot.AssemblyLinearVelocity = Vector3.zero
    lchar:PivotTo(troot.CFrame * CFrame.new(0, 0, 3))
    return true
end

function addPlayerRow(player)
    if player == LocalPlayer or playerRows[player] then return end

    local row = Instance.new("TextButton")
    row.Name = "PlayerRow"
    row.Size = UDim2.new(1, -6, 0, 46)
    row.BackgroundColor3 = rowBase(player)
    row.BackgroundTransparency = THEME.PanelT
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = 200
    row.Parent = spectatePage
    round(row, 4)
    playerRows[player] = row
    row.ClipsDescendants = true

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(32, 32)
    avatar.Position = UDim2.fromOffset(8, 7)
    avatar.BackgroundColor3 = THEME.Track
    avatar.BorderSizePixel = 0
    avatar.Parent = row
    round(avatar, 4)

    local display = Instance.new("TextLabel")
    display.Size = UDim2.new(1, -100, 0, 20)
    display.Position = UDim2.fromOffset(48, 6)
    display.BackgroundTransparency = 1
    display.Text = player.DisplayName
    display.TextColor3 = THEME.Text
    display.Font = Enum.Font.GothamBold
    display.TextSize = 12
    display.TextXAlignment = Enum.TextXAlignment.Left
    display.TextTruncate = Enum.TextTruncate.AtEnd
    display.Parent = row

    local username = Instance.new("TextLabel")
    username.Size = UDim2.new(1, -100, 0, 16)
    username.Position = UDim2.fromOffset(48, 24)
    username.BackgroundTransparency = 1
    username.Text = "@" .. player.Name
    username.TextColor3 = THEME.Dim
    username.Font = Enum.Font.Gotham
    username.TextSize = 10
    username.TextXAlignment = Enum.TextXAlignment.Left
    username.TextTruncate = Enum.TextTruncate.AtEnd
    username.Parent = row

    -- star: outline when idle, filled yellow when favorited
    local star = Instance.new("TextButton")
    star.Name = "Favorite"
    star.Size = UDim2.fromOffset(28, 28)
    star.Position = UDim2.new(1, -38, 0, 9)
    star.BackgroundTransparency = 1
    star.AutoButtonColor = false
    star.Font = Enum.Font.SourceSansBold
    star.TextSize = 26
    star.Text = "☆"
    star.TextXAlignment = Enum.TextXAlignment.Center
    star.TextYAlignment = Enum.TextYAlignment.Center
    star.Parent = row

    local function drawStar()
        local fav = favorites[player.UserId] == true
        star.Text = fav and "★" or "☆"
        star.TextColor3 = fav and STAR_ON or STAR_OFF
    end
    drawStar()

    star.MouseEnter:Connect(function()
        if favorites[player.UserId] ~= true then tween(star, {TextColor3 = THEME.Text}, 0.1) end
    end)
    star.MouseLeave:Connect(function()
        if favorites[player.UserId] ~= true then tween(star, {TextColor3 = STAR_OFF}, 0.12) end
    end)

    star.MouseButton1Click:Connect(function()
        if favorites[player.UserId] then
            favorites[player.UserId] = nil
        else
            favorites[player.UserId] = true
        end
        drawStar()
        reorderRows()
        saveFavorites()
    end)

    local cached = thumbCache[player.UserId]
    if cached then
        avatar.Image = cached
    else
        task.spawn(function()
            local ok, image = pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            if ok then
                thumbCache[player.UserId] = image
                if avatar.Parent then avatar.Image = image end
            end
        end)
    end

    row.MouseEnter:Connect(function()
        tween(row, {BackgroundColor3 = rowBase(player):Lerp(WHITE, 0.08)}, 0.12)
    end)
    row.MouseLeave:Connect(function()
        tween(row, {BackgroundColor3 = rowBase(player)}, 0.15)
    end)

    local actions = Instance.new("Frame")
    actions.Name = "Actions"
    actions.BackgroundTransparency = 1
    actions.Position = UDim2.fromOffset(8, 50)
    actions.Size = UDim2.new(1, -16, 0, 24)
    actions.Parent = row

    local actionsLayout = Instance.new("UIListLayout")
    actionsLayout.FillDirection = Enum.FillDirection.Horizontal
    actionsLayout.Padding = UDim.new(0, 6)
    actionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    actionsLayout.Parent = actions

    local function makeAction(order, name, text)
        local b = Instance.new("TextButton")
        b.Name = name
        b.LayoutOrder = order
        b.Size = UDim2.new(1 / 3, -4, 1, 0)
        b.BackgroundColor3 = THEME.Button
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.TextColor3 = THEME.Text
        b.Text = text
        b.AutoButtonColor = false
        b.Parent = actions
        round(b, 11)
        local outline = newStroke(b, THEME.ButtonLine, 1)
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        addHover(b, function() return THEME.Button end)
        return b
    end

    local teleportButton = makeAction(1, "TeleportBtn", "TELEPORT")
    local flingButton = makeAction(2, "FlingBtn", "FLING")
    local spectateButton = makeAction(3, "SpectateBtn", spectateTarget == player and "STOP" or "SPECTATE")

    teleportButton.MouseButton1Click:Connect(function()
        teleportToPlayer(player)
    end)
    flingButton.MouseButton1Click:Connect(function()
        Fling.toggle(player)
    end)
    spectateButton.MouseButton1Click:Connect(function()
        if spectateTarget == player then stopSpectating() else spectate(player) end
    end)
    Fling.extra[player] = flingButton
    Fling.refresh()

    row.Activated:Connect(function()
        if expandedPlayer == player then
            setExpanded(player, false)
        else
            if expandedPlayer then setExpanded(expandedPlayer, false) end
            setExpanded(player, true)
        end
    end)

    reorderRows()
    applySearch()
end

function removePlayerRow(player)
    local row = playerRows[player]
    if row then
        playerRows[player] = nil
        row:Destroy()
    end
    if expandedPlayer == player then expandedPlayer = nil end
    Fling.extra[player] = nil
    reorderRows()
    applySearch()
end

for _, player in ipairs(Players:GetPlayers()) do addPlayerRow(player) end
applySearch()

end

--// Movement tab
currentPage = movementPage
createSection("Movement")

setFlyEnabled = Module.begin("Flight", "Fly", function(enabled)
    if enabled then
        if not fly.start() then state.Fly = false end
    else
        fly.stop()
    end
end)

createSlider("Flight Speed", "FlySpeed", 10, 300, 5)
createCycle("Flight Mode", "FlyMode", {"Velocity", "Swim"}, function()
    if state.Fly then fly.start() end
end)
createHotkeyRow("Flight Hotkey", "FlyKey")

local setSprintEnabled = Module.begin("Sprint Boost", "Sprint", function(enabled)
    if enabled then sprint.start() else sprint.stop() end
end)
createSlider("Sprint Speed", "SprintSpeed", 16, 300, 1)
createHotkeyRow("Sprint Hotkey", "SprintKey")

Module.finish()
createToggle("Noclip", "Noclip", function(enabled)
    if enabled then noclip.start() else noclip.stop() end
end)

do
    local conn = nil
    local hum = nil
    local lastRoot = nil
    local savedAutoRotate = nil

    local function restore()
        if hum and hum.Parent and savedAutoRotate ~= nil then
            pcall(function() hum.AutoRotate = savedAutoRotate end)
        end
        if lastRoot and lastRoot.Parent then
            local cam = workspace.CurrentCamera
            local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 1e-3 then
                pcall(function()
                    lastRoot.CFrame = CFrame.new(lastRoot.Position, lastRoot.Position + flat.Unit)
                end)
            end
        end
        hum = nil
        lastRoot = nil
        savedAutoRotate = nil
    end

    local function stop()
        if conn then
            conn:Disconnect()
            conn = nil
        end
        restore()
        state.Spin = false
    end

    local function start()
        stop()
        state.Spin = true
        conn = RunService.Stepped:Connect(function(_, dt)
            local char = LocalPlayer.Character
            local h = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not h or not root or h.Health <= 0 or h.Sit then return end
            if h:GetState() == Enum.HumanoidStateType.Physics then return end

            if h ~= hum then
                restore()
                hum = h
                savedAutoRotate = h.AutoRotate
            end
            if h.AutoRotate then h.AutoRotate = false end
            lastRoot = root

            root.CFrame = root.CFrame * CFrame.Angles(0, rad(state.SpinSpeed) * minn(dt, 0.1), 0)
        end)
    end

    Module.begin("Spin Bot", "Spin", function(enabled)
        if enabled then start() else stop() end
    end)
    createSlider("Spin Speed (deg/sec)", "SpinSpeed", 30, 20000, 50)
    Config.stopSpin = stop
end
Module.finish()

--// Settings tab
currentPage = settingsPage
createSection("General")
createHotkeyRow("Menu Hotkey", "MenuKey")

createSection("Configs")
do
    local nameRow = createRow("", 32)
    local nameBox = Instance.new("TextBox")
    nameBox.Position = UDim2.fromOffset(8, 5)
    nameBox.Size = UDim2.new(1, -96, 0, 22)
    nameBox.BackgroundColor3 = THEME.Button
    nameBox.BorderSizePixel = 0
    nameBox.Font = Enum.Font.GothamMedium
    nameBox.TextSize = 12
    nameBox.TextColor3 = THEME.Text
    nameBox.PlaceholderText = "Config name..."
    nameBox.PlaceholderColor3 = THEME.Dim
    nameBox.Text = ""
    nameBox.ClearTextOnFocus = false
    nameBox.TextXAlignment = Enum.TextXAlignment.Left
    nameBox.Parent = nameRow
    round(nameBox, 3)
    local nameOutline = newStroke(nameBox, THEME.ButtonLine, 1.5)
    nameOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local namePad = Instance.new("UIPadding")
    namePad.PaddingLeft = UDim.new(0, 8)
    namePad.Parent = nameBox

    local saveButton = createRowButton(nameRow, "SAVE", 70)
    addHover(saveButton, function() return THEME.Button end)

    local listFrame = Instance.new("Frame")
    listFrame.Name = "ConfigList"
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = TabBar.section

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    local emptyNote = Instance.new("TextLabel")
    emptyNote.LayoutOrder = 9999
    emptyNote.Size = UDim2.new(1, 0, 0, 26)
    emptyNote.BackgroundTransparency = 1
    emptyNote.Font = Enum.Font.Gotham
    emptyNote.TextSize = 12
    emptyNote.TextColor3 = THEME.Dim
    emptyNote.Text = ""
    emptyNote.Parent = listFrame

    local function flash(button, text, restore)
        button.Text = text
        task.delay(1.2, function()
            if button.Parent then button.Text = restore end
        end)
    end

    local rebuild
    rebuild = function()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child.Name == "ConfigRow" then child:Destroy() end
        end
        if not Config.hasFS() then
            emptyNote.Text = "File access not supported by this executor"
            emptyNote.Visible = true
            return
        end
        local names = Config.list()
        emptyNote.Text = "No saved configs yet"
        emptyNote.Visible = #names == 0

        for i, name in ipairs(names) do
            local previous = TabBar.section
            TabBar.section = listFrame
            local row, label = createRow(name, 30)
            TabBar.section = previous
            row.Name = "ConfigRow"
            row.LayoutOrder = i
            label.Size = UDim2.new(1, -130, 1, 0)
            label.TextTruncate = Enum.TextTruncate.AtEnd

            local loadButton = createRowButton(row, "LOAD", 46)
            loadButton.Position = UDim2.new(1, -112, 0.5, -10)
            addHover(loadButton, function() return THEME.Button end)
            local deleteButton = createRowButton(row, "DEL", 46)
            deleteButton.Position = UDim2.new(1, -60, 0.5, -10)
            addHover(deleteButton, function() return THEME.Button end)

            loadButton.MouseButton1Click:Connect(function()
                flash(loadButton, Config.load(name) and "LOADED" or "ERROR", "LOAD")
            end)
            deleteButton.MouseButton1Click:Connect(function()
                Config.delete(name)
                rebuild()
            end)
        end
    end

    saveButton.MouseButton1Click:Connect(function()
        local name = Config.cleanName(nameBox.Text)
        if name == "" then
            flash(saveButton, "NAME?", "SAVE")
            return
        end
        local ok = Config.save(name)
        flash(saveButton, ok and "SAVED" or "ERROR", "SAVE")
        if ok then rebuild() end
    end)

    rebuild()
end

createSection("Protection")
createToggle("Anti Fling", "AntiFling", function(enabled)
    if enabled then antiFling.start() else antiFling.stop() end
end)
do
    local VirtualUser = game:GetService("VirtualUser")
    local conn = nil

    local function start()
        if conn then return end
        conn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end

    local function stop()
        if conn then
            conn:Disconnect()
            conn = nil
        end
    end

    createToggle("Anti AFK", "AntiAFK", function(enabled)
        if enabled then start() else stop() end
    end)

    if state.AntiAFK then start() end
    Config.stopAfk = stop
end

createSection("Performance")
Module.begin("FPS Unlocker", "FPSUnlock", function() applyFPS() end)
createSlider("FPS Cap", "FPSCap", 30, 9999, 10, function()
    if state.FPSUnlock then applyFPS() end
end)

local fpsValue = Instance.new("TextLabel")
fpsValue.BackgroundTransparency = 1
fpsValue.Position = UDim2.new(1, -82, 0, 0)
fpsValue.Size = UDim2.fromOffset(70, 32)
fpsValue.Font = Enum.Font.GothamMedium
fpsValue.TextSize = 12
fpsValue.TextXAlignment = Enum.TextXAlignment.Right
fpsValue.TextColor3 = THEME.Text
fpsValue.Text = "--"
fpsValue.Parent = (createRow("Current FPS", 32))
Module.finish()

do
    local NAMES = {"spread", "bloom", "deviation", "inaccura", "scatter"}
    local MAX_DEPTH = 3
    local saved = {}
    local conns = {}
    local running = false

    local function matches(key)
        if type(key) ~= "string" then return false end
        local lowered = key:lower()
        for _, name in ipairs(NAMES) do
            if lowered:find(name, 1, true) then return true end
        end
        return false
    end

    local function zeroOf(value)
        local kind = typeof(value)
        if kind == "number" then return value ~= 0 and 0 or nil end
        if kind == "Vector2" then return value ~= Vector2.zero and Vector2.zero or nil end
        if kind == "Vector3" then return value ~= Vector3.zero and Vector3.zero or nil end
        if kind == "NumberRange" then
            return (value.Min ~= 0 or value.Max ~= 0) and NumberRange.new(0) or nil
        end
        return nil
    end

    local function write(t, key, value)
        return (pcall(function()
            if table.isfrozen(t) and type(setreadonly) == "function" then setreadonly(t, false) end
            rawset(t, key, value)
        end))
    end

    local function zeroInside(t, depth)
        local count = 0
        for key, value in next, t do
            local zero = zeroOf(value)
            if zero ~= nil then
                if write(t, key, zero) then
                    saved[#saved + 1] = {t, key, value, "table"}
                    count += 1
                end
            elseif type(value) == "table" and depth < MAX_DEPTH then
                count += zeroInside(value, depth + 1)
            end
        end
        return count
    end

    local function zeroTable(t)
        local count = 0
        for key, value in next, t do
            if matches(key) then
                local zero = zeroOf(value)
                if zero ~= nil then
                    if write(t, key, zero) then
                        saved[#saved + 1] = {t, key, value, "table"}
                        count += 1
                    end
                elseif type(value) == "table" then
                    count += zeroInside(value, 1)
                end
            end
        end
        return count
    end

    local function safeRequire(module)
        local identity = type(getthreadidentity) == "function" and getthreadidentity() or nil
        if identity and type(setthreadidentity) == "function" then pcall(setthreadidentity, 2) end
        local ok, result = pcall(require, module)
        if identity and type(setthreadidentity) == "function" then pcall(setthreadidentity, identity) end
        return ok and result or nil
    end

    local function scanInstance(root)
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("NumberValue") or inst:IsA("IntValue") then
                if matches(inst.Name) and inst.Value ~= 0 then
                    saved[#saved + 1] = {inst, "Value", inst.Value, "value"}
                    inst.Value = 0
                end
            elseif inst:IsA("ModuleScript") then
                local result = safeRequire(inst)
                if type(result) == "table" then pcall(zeroTable, result) end
            end
        end
        for name, value in pairs(root:GetAttributes()) do
            if matches(name) and type(value) == "number" and value ~= 0 then
                saved[#saved + 1] = {root, name, value, "attr"}
                root:SetAttribute(name, 0)
            end
        end
    end

    local function scanTools()
        local holders = {LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack")}
        for _, holder in ipairs(holders) do
            if holder then
                for _, child in ipairs(holder:GetChildren()) do
                    if child:IsA("Tool") then scanInstance(child) end
                end
            end
        end
    end

    local function scanMemory()
        if type(getgc) ~= "function" then return end
        local seen = 0
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" then pcall(zeroTable, obj) end
            seen += 1
            if seen % 3000 == 0 then task.wait() end
        end
    end

    local function restore()
        for i = #saved, 1, -1 do
            local entry = saved[i]
            local container, key, old, kind = entry[1], entry[2], entry[3], entry[4]
            pcall(function()
                if kind == "table" then
                    rawset(container, key, old)
                elseif kind == "attr" then
                    container:SetAttribute(key, old)
                else
                    container.Value = old
                end
            end)
        end
        table.clear(saved)
    end

    local function run()
        if running then return end
        running = true
        task.spawn(function()
            local ok, err = pcall(function()
                scanTools()
                scanMemory()
            end)
            running = false
            if not ok then warn("[HUD] no spread error:", err) end
            if not state.NoSpread then restore() end
        end)
    end

    local function disconnectAll()
        for _, connection in ipairs(conns) do connection:Disconnect() end
        table.clear(conns)
    end

    local function hookCharacter(char)
        conns[#conns + 1] = char.ChildAdded:Connect(function(child)
            if state.NoSpread and child:IsA("Tool") then task.delay(0.4, run) end
        end)
    end

    local function enable()
        disconnectAll()
        if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end
        conns[#conns + 1] = LocalPlayer.CharacterAdded:Connect(hookCharacter)
        run()
    end

    local function disable()
        disconnectAll()
        restore()
    end

    local previousSection = TabBar.section
    TabBar.section = TabBar.combatMisc
    createToggle("No Spread / Bloom", "NoSpread", function(enabled)
        if enabled then enable() else disable() end
    end)
    TabBar.section = previousSection

    if state.NoSpread then enable() end
    Config.cleanups[#Config.cleanups + 1] = disable
end

--// Misc tab
currentPage = miscPage
createSection("Text Spammer")
do
    local running = false
    local gen = 0

    local sendChat
    do
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        sendChat = function(message)
            return (pcall(function()
                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                    local channels = TextChatService:FindFirstChild("TextChannels")
                    local channel = channels and channels:FindFirstChild("RBXGeneral")
                    if not channel and channels then
                        for _, child in ipairs(channels:GetChildren()) do
                            if child:IsA("TextChannel") and child.Name ~= "RBXSystem" and child.Name ~= "RBXTeam" then
                                channel = child
                                break
                            end
                        end
                    end
                    if not channel then error("no text channel") end
                    channel:SendAsync(message)
                else
                    local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                    local say = events and events:FindFirstChild("SayMessageRequest")
                    if not say then error("no chat remote") end
                    say:FireServer(message, "All")
                end
            end))
        end
    end

    local row = createRow("", 32)
    local box = Instance.new("TextBox")
    box.Position = UDim2.fromOffset(8, 5)
    box.Size = UDim2.new(1, -96, 0, 22)
    box.BackgroundColor3 = THEME.Button
    box.BorderSizePixel = 0
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 12
    box.TextColor3 = THEME.Text
    box.PlaceholderText = "Message to spam..."
    box.PlaceholderColor3 = THEME.Dim
    box.Text = state.SpamText
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = row
    round(box, 3)
    do
        local boxOutline = newStroke(box, THEME.ButtonLine, 1.5)
        boxOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        local boxPad = Instance.new("UIPadding")
        boxPad.PaddingLeft = UDim.new(0, 8)
        boxPad.Parent = box
    end

    local button = createRowButton(row, "SPAM", 70)
    addHover(button, function() return running and THEME.ButtonActive or THEME.Button end)

    local function render()
        button.Text = running and "STOP" or "SPAM"
        tween(button, {BackgroundColor3 = running and THEME.ButtonActive or THEME.Button}, 0.15)
    end

    local function stop()
        running = false
        gen += 1
        render()
    end

    local function commitText()
        local text = box.Text:match("^%s*(.-)%s*$")
        if text == "" then return false end
        state.SpamText = text:sub(1, 200)
        scheduleSave()
        return true
    end

    local function start()
        if not commitText() then
            button.Text = "EMPTY"
            task.delay(1.2, function() if button.Parent and not running then button.Text = "SPAM" end end)
            return
        end
        running = true
        gen += 1
        local myGen = gen
        render()

        task.spawn(function()
            local failures = 0
            while running and gen == myGen do
                if sendChat(state.SpamText) then failures = 0 else failures += 1 end
                if failures >= 3 then
                    if gen == myGen then stop() end
                    break
                end
                local delay = state.SpamDelay * (1 + math.random() * 0.1)
                local t0 = os.clock()
                while running and gen == myGen and os.clock() - t0 < delay do
                    task.wait(minn(0.1, maxn(delay - (os.clock() - t0), 0.01)))
                end
            end
        end)
    end

    button.MouseButton1Click:Connect(function()
        if running then stop() else start() end
    end)

    box.FocusLost:Connect(function()
        if not commitText() then box.Text = state.SpamText end
    end)

    Config.refresh.SpamText = function() box.Text = state.SpamText end
    Config.stopSpam = stop
end
createSlider("Spam Delay (seconds)", "SpamDelay", 0.1, 5.5, 0.1)

createSection("Tung Mode")
do
    local TUNG_ASSET_ID = "138151705692565"
    local cachedModel = nil
    local rigs = {}
    local hiddenParts = {}
    local heartbeatConn = nil
    local tungConns = {}

    local function fetchModel()
        if cachedModel then return cachedModel end
        local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. TUNG_ASSET_ID) end)
        if (not ok or type(objects) ~= "table") and type(getobjects) == "function" then
            ok, objects = pcall(getobjects, "rbxassetid://" .. TUNG_ASSET_ID)
        end
        if not ok or type(objects) ~= "table" then return nil end
        for _, root in ipairs(objects) do
            if root:IsA("Model") or root:IsA("BasePart") then
                cachedModel = root
            else
                local found = root:FindFirstChildWhichIsA("Model", true) or root:FindFirstChildWhichIsA("BasePart", true)
                if found then cachedModel = found end
            end
            if cachedModel then break end
        end
        return cachedModel
    end

    local function hideCharacter(character)
        if hiddenParts[character] then return end
        local saved = {}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                saved[part] = part.LocalTransparencyModifier
                part.LocalTransparencyModifier = 1
            elseif part:IsA("Decal") then
                saved[part] = part.Transparency
                part.Transparency = 1
            end
        end
        hiddenParts[character] = saved
    end

    local function restoreCharacter(character)
        local saved = hiddenParts[character]
        if not saved then return end
        for inst, value in pairs(saved) do
            if inst.Parent then
                if inst:IsA("BasePart") then
                    inst.LocalTransparencyModifier = value
                elseif inst:IsA("Decal") then
                    inst.Transparency = value
                end
            end
        end
        hiddenParts[character] = nil
    end

    local function spawnRig(player, character)
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local template = fetchModel()
        if not template then return end

        local clone = template:Clone()
        clone.Name = randomName()
        local halfHeight = 3
        if clone:IsA("Model") then
            if not clone.PrimaryPart then
                clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true)
            end
            for _, d in ipairs(clone:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored = true
                    d.CanCollide = false
                    d.CanQuery = false
                    d.CanTouch = false
                end
            end
            local ok, size = pcall(function() return clone:GetExtentsSize() end)
            if ok and size then halfHeight = size.Y / 2 end
        else
            clone.Anchored = true
            clone.CanCollide = false
            clone.CanQuery = false
            clone.CanTouch = false
            halfHeight = clone.Size.Y / 2
        end
        clone.Parent = workspace

        hideCharacter(character)
        rigs[player] = {model = clone, root = root, character = character, halfHeight = halfHeight}
    end

    local function removeRig(player)
        local info = rigs[player]
        if not info then return end
        if info.character and info.character.Parent then restoreCharacter(info.character) end
        if info.model then info.model:Destroy() end
        rigs[player] = nil
    end

    local function clearAll()
        for player in pairs(rigs) do removeRig(player) end
        table.clear(rigs)
        table.clear(hiddenParts)
    end

    local function hookPlayer(player)
        local function onCharacter(character)
            removeRig(player)
            if not state.TungMode then return end
            character:WaitForChild("HumanoidRootPart", 5)
            if character.Parent and state.TungMode then spawnRig(player, character) end
        end
        if player.Character then onCharacter(player.Character) end
        tungConns[#tungConns + 1] = player.CharacterAdded:Connect(onCharacter)
    end

    local function disable()
        if heartbeatConn then heartbeatConn:Disconnect(); heartbeatConn = nil end
        for _, c in ipairs(tungConns) do c:Disconnect() end
        table.clear(tungConns)
        clearAll()
    end

    local function enable()
        disable()
        for _, player in ipairs(Players:GetPlayers()) do task.spawn(hookPlayer, player) end
        tungConns[#tungConns + 1] = Players.PlayerAdded:Connect(function(p) task.spawn(hookPlayer, p) end)
        tungConns[#tungConns + 1] = Players.PlayerRemoving:Connect(removeRig)

        heartbeatConn = RunService.Heartbeat:Connect(function()
            for player, info in pairs(rigs) do
                if not (info.root and info.root.Parent and info.model and info.model.Parent) then
                    removeRig(player)
                else
                    local cframe = info.root.CFrame * CFrame.new(0, -3 + info.halfHeight, 0)
                    if info.model:IsA("Model") and info.model.PrimaryPart then
                        info.model:PivotTo(cframe)
                    elseif info.model:IsA("BasePart") then
                        info.model.CFrame = cframe
                    end
                end
            end
        end)
    end

    createToggle("Tung Mode", "TungMode", function(enabled)
        if enabled then enable() else disable() end
    end)

    if state.TungMode then enable() end
    Config.cleanups[#Config.cleanups + 1] = disable
end

createSection("Server")
do
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local busy = false

    local row = createRow("Server Hop", 32)
    local button = createRowButton(row, "HOP", 84)
    addHover(button, function() return THEME.Button end)

    local function flash(text)
        button.Text = text
        task.delay(1.2, function()
            if button.Parent and not busy then button.Text = "HOP" end
        end)
    end

    local function fetchPage(cursor)
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        if cursor then url ..= "&cursor=" .. cursor end
        local ok, res = pcall(request, {Url = url, Method = "GET"})
        if not ok or type(res) ~= "table" or not res.Success then return nil end
        local decoded, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
        return decoded and data or nil
    end

    local function findServer()
        local pool, cursor = {}, nil
        for _ = 1, 3 do
            local data = fetchPage(cursor)
            if not data then break end
            for _, server in ipairs(data.data or {}) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers - 1 then
                    pool[#pool + 1] = server
                end
            end
            cursor = data.nextPageCursor
            if not cursor then break end
        end
        if #pool == 0 then return nil end
        return pool[math.random(1, #pool)]
    end

    button.MouseButton1Click:Connect(function()
        if busy then return end
        if type(request) ~= "function" then flash("NO HTTP") return end
        busy = true
        button.Text = "..."

        task.spawn(function()
            local server = findServer()
            if not server then
                busy = false
                flash("NONE")
                return
            end

            local ok = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, server.id, LocalPlayer)
            if not ok then
                busy = false
                flash("ERROR")
                return
            end

            -- if the teleport silently fails, unlock the button again
            task.delay(10, function()
                busy = false
                if button.Parent then button.Text = "HOP" end
            end)
        end)
    end)
end

showTab("aimbot")

--// FOV circle
local updateFOVCircle
do
    local function makeCircle(name)
        local circle = Instance.new("Frame")
        circle.Name = name
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.Position = UDim2.fromScale(0.5, 0.5)
        circle.BackgroundTransparency = 1
        circle.Visible = false
        circle.ZIndex = 2
        circle.Parent = gui
        round(circle, 1000)
        local stroke = Instance.new("UIStroke")
        stroke.Color = state.CircleColor
        stroke.Transparency = 0.18
        stroke.Thickness = 1.5
        stroke.Parent = circle
        return circle, stroke
    end

    local fovCircle, fovStroke = makeCircle("LockFOVCircle")
    local silentCircle, silentStroke = makeCircle("SilentFOVCircle")
    fovCircle.Size = UDim2.fromOffset(state.FOVRadius * 2, state.FOVRadius * 2)
    silentCircle.Size = UDim2.fromOffset(state.SilentAimFOV * 2, state.SilentAimFOV * 2)

    local lastFovRadius, lastSilentRadius, lastFovCenter, lastFovColor = nil, nil, nil, nil
    local lastFovVisible, lastSilentVisible = nil, nil
    updateFOVCircle = function()
        Camera = workspace.CurrentCamera
        local visible = state.UseFOV and state.ShowFOV
        local silentVisible = state.SilentAim and state.SilentAimShowFOV

        if lastFovRadius ~= state.FOVRadius then
            lastFovRadius = state.FOVRadius
            fovCircle.Size = UDim2.fromOffset(state.FOVRadius * 2, state.FOVRadius * 2)
        end
        if lastSilentRadius ~= state.SilentAimFOV then
            lastSilentRadius = state.SilentAimFOV
            silentCircle.Size = UDim2.fromOffset(state.SilentAimFOV * 2, state.SilentAimFOV * 2)
        end
        local c = aimCenter()
        if lastFovCenter ~= c then
            lastFovCenter = c
            local center = UDim2.fromOffset(c.X, c.Y)
            fovCircle.Position = center
            silentCircle.Position = center
        end
        if lastFovColor ~= state.CircleColor then
            lastFovColor = state.CircleColor
            fovStroke.Color = state.CircleColor
            silentStroke.Color = state.CircleColor
        end
        if lastFovVisible ~= visible then
            lastFovVisible = visible
            fovCircle.Visible = visible
        end
        if lastSilentVisible ~= silentVisible then
            lastSilentVisible = silentVisible
            silentCircle.Visible = silentVisible
        end
    end
end

--// Menu open / close
local menuOpen = false
local menuToken = 0
local SLIDE = UDim2.fromOffset(0, 14)

local function setMenuVisible(visible)
    menuOpen = visible
    menuToken += 1
    local token = menuToken

    if visible then
        main.Visible = true
        main.GroupTransparency = 1
        main.Position = restPosition + SLIDE
        tween(main, {GroupTransparency = 0, Position = restPosition}, 0.3)
    else
        stopSpectating()
        tween(main, {GroupTransparency = 1, Position = restPosition + SLIDE}, 0.22)
        task.delay(0.28, function()
            if token == menuToken and not menuOpen then main.Visible = false end
        end)
    end
end

--// Per-frame updates
do
    local fpsClock, fpsFrames = 0, 0
    trackConnection(RunService.RenderStepped:Connect(function(dt)
        fpsClock += dt
        fpsFrames += 1
        if fpsClock >= 0.5 then
            local fps = fpsFrames / fpsClock
            if menuOpen then
                fpsValue.Text = tostring(floor(fps + 0.5))
            end

            local target = 60
            if setCap and state.FPSUnlock then target = minn(state.FPSCap, 60) end
            if state.ESP and fps < target * 0.65 and lodBias < 2 then lodBias += 1
            elseif (not state.ESP or fps > target * 0.9) and lodBias > 0 then lodBias -= 1 end
            fpsClock, fpsFrames = 0, 0
        end

        if state.Lock and not lockBound then bindLock() end
        pcall(updateFOVCircle)

        local hovering = false
        if menuOpen and main.Visible then
            local mouse = UserInputService:GetMouseLocation()
            local pos, size = main.AbsolutePosition, main.AbsoluteSize
            hovering = mouse.X >= pos.X and mouse.X <= pos.X + size.X
                and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
        end
        Wheel.set(hovering)

        if spectateTarget then
            if not getAlive(spectateTarget) then
                stopSpectating()
            else
                pcall(spectateCameraStep)
            end
        end
    end))
end

if not pcall(function()
    RunService:BindToRenderStep(CFG.ESP_BIND_NAME, Enum.RenderPriority.Last.Value + 2, safeEspStep)
end) then
    trackConnection(RunService.RenderStepped:Connect(safeEspStep))
end

trackConnection(Players.PlayerAdded:Connect(function(player)
    addPlayerRow(player)
    playerList = Players:GetPlayers()
end))

trackConnection(Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    removePlayerRow(player)
    if targetPlayer == player then releaseLock() end
    if spectateTarget == player then stopSpectating() end
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then list[#list + 1] = p end
    end
    playerList = list
end))

trackConnection(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    stopSpectating()
end))

--// Input
local function inputMatchesKey(key, input)
    if not key or key == Enum.KeyCode.Unknown then return false end
    if key.EnumType == Enum.KeyCode then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key
    end
    return input.UserInputType == key
end

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if pendingBind then
        local picked = nil
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                pendingBind.button.Text = (pendingBind.format or tostring)(state[pendingBind.field])
                tween(pendingBind.button, {BackgroundColor3 = THEME.Button}, 0.15)
                pendingBind = nil
                return
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                picked = input.KeyCode
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
            picked = input.UserInputType
        end
        if picked then
            state[pendingBind.field] = picked
            pendingBind.button.Text = (pendingBind.format or tostring)(picked)
            tween(pendingBind.button, {BackgroundColor3 = THEME.Button}, 0.15)
            scheduleSave()
            pendingBind = nil
        end
        return
    end

    if inputMatchesKey(state.MenuKey, input) then
        if spectateTarget and not menuOpen then stopSpectating()
        else setMenuVisible(not menuOpen) end
        return
    end

    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyCode = input.KeyCode
        if spectateTarget then
            if keyCode == Enum.KeyCode.Right or keyCode == Enum.KeyCode.Down then cycleSpectate(1); return
            elseif keyCode == Enum.KeyCode.Left or keyCode == Enum.KeyCode.Up then cycleSpectate(-1); return end
        end
    end

    if spectateTarget and input.UserInputType == Enum.UserInputType.MouseButton2 then
        spectateLooking = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        return
    end

    if inputMatchesKey(state.LockKey, input) then
        if state.HoldMode then
            if not state.Lock then setLockEnabled(true) end
        else
            setLockEnabled(not state.Lock)
        end
    end
    if inputMatchesKey(state.SilentAimToggleKey, input) then
        if Config.toggles.SilentAim then Config.toggles.SilentAim(not state.SilentAim) end
    end
    if inputMatchesKey(state.TriggerBotKey, input) then
        if Config.toggles.TriggerBot then Config.toggles.TriggerBot(not state.TriggerBot) end
    end
    if inputMatchesKey(state.FlyKey, input) then
        setFlyEnabled(not state.Fly)
    end
    if inputMatchesKey(state.SprintKey, input) then
        setSprintEnabled(not state.Sprint)
    end
end))

trackConnection(UserInputService.InputChanged:Connect(function(input)
    if spectateLooking and input.UserInputType == Enum.UserInputType.MouseMovement then
        local sensitivity = 0.0035
        spectateYaw -= input.Delta.X * sensitivity
        spectatePitch = clamp(spectatePitch - input.Delta.Y * sensitivity, -1.4, 1.4)
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if spectateLooking and input.UserInputType == Enum.UserInputType.MouseButton2 then
        spectateLooking = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if state.HoldMode and state.Lock and inputMatchesKey(state.LockKey, input) then
        setLockEnabled(false)
    end
end))

--// Draggable title bar
do
    local dragging = false
    local dragStart, dragStartPosition = nil, nil

    titleBar.InputBegan:Connect(function(input)
        if isPointerBegin(input) then
            dragging = true
            dragStart = input.Position
            dragStartPosition = main.Position
        end
    end)

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart and dragStartPosition and isPointerMove(input) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                dragStartPosition.X.Scale, dragStartPosition.X.Offset + delta.X,
                dragStartPosition.Y.Scale, dragStartPosition.Y.Offset + delta.Y
            )
            restPosition = main.Position
        end
    end))

    trackConnection(UserInputService.InputEnded:Connect(function(input)
        if isPointerBegin(input) then dragging = false end
    end))
end

--// Unload
local unloaded = false
local function unload()
    if unloaded then return end
    unloaded = true

    pcall(Fling.stop, true)

    pcall(savePreferences)
    state.ESP = false
    state.Lock = false
    state.SilentAim = false
    state.TriggerBot = false
    state.Fly = false
    state.Sprint = false
    state.Noclip = false
    state.FPSUnlock = false

    pcall(function() RunService:UnbindFromRenderStep(CFG.ESP_BIND_NAME) end)
    pcall(function() RunService:UnbindFromRenderStep(CFG.RENDER_BIND_NAME) end)
    pcall(function() ContextActionService:UnbindAction(CFG.CAMERA_BLOCK_ACTION) end)

    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(connections)

    pcall(function() fly.stop() end)
    pcall(function() sprint.stop() end)
    pcall(function() noclip.stop() end)
    pcall(function() antiFling.stop() end)
    pcall(function() TriggerBot.stop() end)
    pcall(releaseLock)
    pcall(unbindLock)
    pcall(Wheel.set, false)
    if Config.stopSpam then pcall(Config.stopSpam) end
    if Config.stopAfk then pcall(Config.stopAfk) end
    if Config.stopSpin then pcall(Config.stopSpin) end
    for _, fn in ipairs(Config.cleanups) do pcall(fn) end
    pcall(stopSpectating)
    pcall(clearAllESP)
    pcall(applyFPS)

    if genv.__ESP_LOCK_UNLOAD == unload then genv.__ESP_LOCK_UNLOAD = nil end

    pcall(function() gui:Destroy() end)
end

closeButton.MouseButton1Click:Connect(unload)
gui.Destroying:Connect(function() if not unloaded then unload() end end)
genv.__ESP_LOCK_UNLOAD = unload

--// Start
Config.after = function()
    applyFPS()
    if Rel.redraw then Rel.redraw() end
    for _, fn in ipairs(Config.visualApplies) do pcall(fn) end
    scheduleSave()
end

updateFOVCircle()
applyFPS()
savePreferences()

if state.AntiFling then antiFling.start() end

if CFG.START_OPEN then setMenuVisible(true) else main.Visible = false end
