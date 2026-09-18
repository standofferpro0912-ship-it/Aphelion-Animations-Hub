--[[
    APHELION.LUA — FULL ROBLOX ANIMATION + EMOTE EDITION
    Built from the supplied example(1).lua architecture.

    Core catalog sources used by the original architecture:
      - AnimationSniper.json
      - AnimationSniperoffsale.json
      - EmoteSniper.json

    IMPORTANT:
      This file intentionally keeps the dynamic catalog architecture instead of
      hardcoding a tiny list of animation packs. Animation cards represent full
      Roblox animation bundles/sets, and the selected bundle is resolved into
      its actual Animation objects before being applied.

    Bundle thumbnails use Roblox's BundleThumbnail rbxthumb type.
    The original source already contained bundle thumbnail support; Aphelion
    preserves and extends that behavior.

    This is a single entry-point .lua file. The catalog data itself is fetched
    dynamically from the same JSON endpoints used by the supplied source so the
    script can expose the large catalog without embedding thousands of static IDs.
]]

--[[ 
    Source script taken from: https://github.com/Roblox/creator-docs/blob/main/content/en-us/characters/emotes.md

    scriptblox: https://scriptblox.com/script/Universal-Script-7yd7-I-Emote-Script-48024
]]


if _G.AphelionGUIRunning then
    getgenv().Notify({
        Title = 'Aphelion | Emote',
        Content = '⚠️ It works It actually works',
        Duration = 5
    })
    return
end
_G.AphelionGUIRunning = true
getgenv().APHELION_STANDALONE_UI = true
local offsaleAnimationJson = true

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local request = http_request or (syn and syn.request) or request

local State = {
    currentMode = "emote",
    savedAnimPage = 1,
    savedEmotePage = 1,
    emotesWalkEnabled = false,
    favoriteEnabled = false,
    hudEditorActive = false,
    speedEmoteEnabled = false,
    isLoading = false,
    favoriteSetVersion = 0,
    favoriteSetBuiltVersion = -1,
    emoteCacheVersion = 0,
    animationCacheVersion = 0,
    isGUICreated = false,
    isMonitoringClicks = false,
    lastRadialActionTime = 0,
    lastWheelVisibleTime = 0,
    lastActionTick = 0,
    lastRandomEmoteId = nil,
    lastRandomAnimationId = nil,
    lastRandomVisualSpam = 0,
    randomSpamConn = nil,
    animImageSpamConn = nil,
    animImageSpamMap = nil,
    animImageSpamTicks = nil,
    animImageSpamToken = 0,
    animImageRetry = 0,
    randomSlotBlockerConn = nil,
    totalEmotesLoaded = 0,
    currentPage = 1,
    totalPages = 1,
    itemsPerPage = 8,
    emoteSearchTerm = "",
    animationSearchTerm = "",
    currentEmoteTrack = nil,
    currentCharacter = nil,
    emoteClickConnections = {},
    guiConnections = {},
    animationsData = {},
    originalAnimationsData = {},
    filteredAnimations = {},
    favoriteAnimations = {},
    favoriteAnimationsFileName = "FavoriteAnimations.json",
    emotesData = {},
    originalEmotesData = {},
    filteredEmotes = {},
    scannedEmotes = {},
    favoriteEmotes = {},
    favoriteFileName = "FavoriteEmotes.json",
    speedEmoteConfigFile = "SpeedEmoteConfig.json",
    favoriteEmoteSet = {},
    favoriteAnimationSet = {},
    emotePageCache = { version = nil, normal = {}, favorites = {} },
    animationPageCache = { version = nil, normal = {}, favorites = {} },
    suppressSearch = false,
    emoteMonitorToken = 0,
    animationMonitorToken = 0,
    imageUpdateToken = 0,
    defaultButtonImage = "rbxassetid://71408678974152",
    enabledButtonImage = "rbxassetid://106798555684020",
    favoriteIconId = "rbxassetid://97307461910825",
    notFavoriteIconId = "rbxassetid://124025954365505",
    toolEquipped = false,
    EmoteTheme = nil,
    isApplyingTheme = false,
    targetImages = {},
    AnimationCachePath = "Aphelion/AnimationCache.json",
    AnimationCache = {},
    AnimationListCachePath = "Aphelion/AnimationListCache.json",
    EmoteListCachePath = "Aphelion/EmoteListCache.json",
    CustomAnimationPath = "Aphelion/CustomAnimations.json",
    CustomAnimations = {},
    currentCustomAnimationName = "Default",
    customAnimationEditorActive = false,
    customAnimationEditingKey = nil,
    customAnimationEditingName = nil,
    EmotePagePath = "Aphelion/EmotePages.json",
    EmotePages = {},
    currentEmotePageName = "Default",
    EmoteDataCachePath = "Aphelion/EmoteDataCache.json"
}

Config = {
    NotifyEnabled = true,
    SearchVisible = true,
    FavVisible = true,
    ModeVisible = true,
    FreezeVisible = true,
    SpeedVisible = true,
    NavVisible = true,
    EmoteSpeed = 1,
    EmoteSpeedEnabled = false,
    SelectedTheme = "Default",
    EmotePage = 1,
    AnimationPage = 1,
    RandomEnabled = true,
    RandomMode = "All",
    AuthenticFirstPage = false,
    HUDPositions = {},
    HUDSizes = {},
    HUDProperties = {},
    CustomFrames = {},
    AutoReloadEnabled = false,
    LastPlayedAnimationData = nil,
    DiscordVisible = true,
    IncludeOffsaleAnimations = true,
    CatalogAutoRefresh = true,
    CatalogRefreshMinutes = 15,
    ThumbnailPreloadCount = 48
}

HUD = {
    Connections = {},
    IsUnlocked = false,
    DefaultPositions = {},
    DefaultSizes = {},
    DefaultTexts = {},
    DefaultPlaceholders = {},
    Layouts = {},
    LayoutsRemoved = {},
    SelectionGui = nil,
    SelectedElement = nil,
    ResizeHandles = {},
    ResizeConnections = {},
    FriendlyNames = {
        ["Under.1left"] = "PrevPage",
        ["Under.9right"] = "NextPage",
        ["Under.4pages"] = "TotalPages",
        ["Under.3TextLabel"] = "Divider",
        ["Under.2Route-number"] = "CurrentPage",
        ["Top.Search"] = "Search",
        ["EmoteWalkButton"] = "Freeze",
        ["Favorite"] = "Favorite",
        ["SpeedEmote"] = "SpeedEmote",
        ["SpeedBox"] = "SpeedBox",
        ["Changepage"] = "ChangePage",
        ["Reload"] = "AutoReload",
        ["Top"] = "Top",
        ["Under"] = "Under"
    }
}

local DEFAULT_IDLE_ICON_ID = "rbxassetid://106798555684020"
local DEFAULT_IDLE_ICON_COLOR = Color3.fromRGB(0, 255, 150)

function DeepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = DeepCopy(v)
        end
        copy[k] = v
    end
    return copy
end

function ColorToTable(color)
    return {color.R, color.G, color.B}
end

function TableToColor(tbl)
    if not tbl or type(tbl) ~= "table" or #tbl < 3 then return Color3.new(1,1,1) end
    return Color3.new(tbl[1], tbl[2], tbl[3])
end

function loadAnimationCache()
    if isfile and isfile(State.AnimationCachePath) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(State.AnimationCachePath))
        end)
        if success and type(decoded) == "table" then
            State.AnimationCache = decoded
        end
    end
end

function saveAnimationCache()
    if writefile then
        pcall(function()
            if not isfolder("7yd7") then makefolder("7yd7") end
            writefile(State.AnimationCachePath, HttpService:JSONEncode(State.AnimationCache))
        end)
    end
end

local APHELION_MOTION_ALIASES = {
    idle = "idle", idle1 = "idle", idle2 = "idle",
    walk = "walk", walking = "walk",
    run = "run", running = "run", sprint = "run",
    jump = "jump", jumping = "jump",
    fall = "fall", falling = "fall", freefall = "fall",
    climb = "climb", climbing = "climb",
    swim = "swim", swimming = "swim",
    swimidle = "swimidle", swimsidle = "swimidle",
}

local function normalizeMotionCategory(value)
    local key = tostring(value or ""):lower():gsub("[%s_%-.]", "")
    return APHELION_MOTION_ALIASES[key]
end

local function classifyAnimationPath(path, animationName)
    local candidates = {}
    for part in tostring(path or ""):gmatch("[^%.]+") do
        table.insert(candidates, part)
    end
    if animationName then table.insert(candidates, animationName) end
    for i = #candidates, 1, -1 do
        local normalized = normalizeMotionCategory(candidates[i])
        if normalized then return normalized end
    end
    return tostring(candidates[#candidates - 1] or candidates[#candidates] or "Unknown")
end

function resolveAnimationMappings(bundledItems)
    local mappings = {}
    if type(bundledItems) ~= "table" then return mappings end

    local seen = {}
    for _, assetIds in pairs(bundledItems) do
        if type(assetIds) == "table" then
            for _, assetId in pairs(assetIds) do
                local numericAssetId = tonumber(assetId)
                if numericAssetId then
                    local success, objects = pcall(function()
                        return game:GetObjects("rbxassetid://" .. tostring(numericAssetId))
                    end)
                    if success and objects then
                        local function searchTree(parent, parentPath)
                            for _, child in pairs(parent:GetChildren()) do
                                if child:IsA("Animation") then
                                    local animationPath = parentPath .. "." .. child.Name
                                    local weightVals = {}
                                    for _, wChild in ipairs(child:GetChildren()) do
                                        if wChild:IsA("NumberValue") and wChild.Name == "Weight" then
                                            table.insert(weightVals, wChild.Value)
                                        end
                                    end
                                    local category = classifyAnimationPath(animationPath, child.Name)
                                    local key = category:lower() .. "|" .. child.Name:lower() .. "|" .. tostring(child.AnimationId)
                                    if not seen[key] then
                                        seen[key] = true
                                        table.insert(mappings, {
                                            category = category,
                                            name = child.Name,
                                            animationId = child.AnimationId,
                                            weights = weightVals,
                                        })
                                    end
                                elseif #child:GetChildren() > 0 then
                                    searchTree(child, parentPath .. "." .. child.Name)
                                end
                            end
                        end
                        for _, obj in pairs(objects) do
                            searchTree(obj, obj.Name)
                            obj.Parent = workspace
                            task.delay(1, function()
                                if obj then obj:Destroy() end
                            end)
                        end
                    end
                end
            end
        end
    end
    return mappings
end

function buildCustomSetMappings(setName)
    if type(setName) == "string" then
        setName = setName:gsub("%s*%-.*$", "")
    end
    local set = State.CustomAnimations and State.CustomAnimations.Sets and State.CustomAnimations.Sets[setName]
    if not set then return {} end
    local mappings = {}
    for cat, anims in pairs(set) do
        if cat ~= "__meta" then
            for name, id in pairs(anims) do
                if tostring(id) ~= "0" then
                    table.insert(mappings, {category = cat, name = name, animationId = "rbxassetid://" .. id})
                end
            end
        end
    end
    return mappings
end



loadAnimationCache()


local UI = {
    CustomFrames = {},
    Under = nil, 
    _1left = nil, 
    _9right = nil, 
    _4pages = nil, 
    _3TextLabel = nil, 
    _2Routenumber = nil, 
    Top = nil, 
    EmoteWalkButton = nil,
    Search = nil, 
    Favorite = nil, 
    SpeedEmote = nil, 
    SpeedBox = nil, 
    Changepage = nil,
    Reload = nil,
    Background = nil
}

local HUD = { 
    Connections = {},
    Strokes = {},
    ResizeHandles = {},
    ResizeConnections = {},
    UndoStack = {},
    SelectedElement = nil,
    Overlay = nil,
    IsUnlocked = false,
    ForceVisibleConn = nil,
    Layouts = {},
    LayoutsRemoved = {},
    FriendlyNames = {
        ["Under.1left"] = "Left Arrow",
        ["Under.9right"] = "Right Arrow",
        ["Under.4pages"] = "Total Pages",
        ["Under.3TextLabel"] = "Separator Label",
        ["Under.2Route-number"] = "Page Number Box",
        ["Top.Search"] = "Search/ID Box",
    },
    DefaultPositions = {
        Top = UDim2.new(0.127499998, 0, -0.109999999, 0),
        Under = UDim2.new(0.129999995, 0, 1, 0),
        EmoteWalkButton = UDim2.new(0.889999986, 0, -0.107500002, 0),
        Favorite = UDim2.new(0.0189999994, 0, -0.108000003, 0),
        SpeedEmote = UDim2.new(0.888999999, 0, 0, 0),
        SpeedBox = UDim2.new(0.0189999398, 0, -0.000499992399, 0),
        Changepage = UDim2.new(0.019, 0, 1.021, 0),
        Reload = UDim2.new(0.888999999, 0, 1.02100003, 0),
        ["Left Arrow"] = UDim2.new(0, 0, 0.028, 0),
        ["Right Arrow"] = UDim2.new(0.169, 0, 0.028, 0),
        ["Total Pages"] = UDim2.new(0.339, 0, 0.094, 0), 
        ["Separator Label"] = UDim2.new(0.498, 0, 0.028, 0),
        ["Page Number Box"] = UDim2.new(0.837, 0, 0.094, 0),
        ["Search/ID Box"] = UDim2.new(0.01, 0, 0.092, 0),
    },
    DefaultSizes = {
        Top = UDim2.new(0.737500012, 0, 0.0949999914, 0),
        Under = UDim2.new(0.737500012, 0, 0.132499993, 0),
        EmoteWalkButton = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        Favorite = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        SpeedEmote = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        SpeedBox = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        Changepage = UDim2.new(0.087, 0, 0.087, 0),
        Reload = UDim2.new(0.0869999975, 0, 0.0869999975, 0),
        ["Left Arrow"] = UDim2.new(0.169491529, 0, 0.94339627, 0),
        ["Right Arrow"] = UDim2.new(0.169491529, 0, 0.94339627, 0),
        ["Total Pages"] = UDim2.new(0.159322038, 0, 0.811320841, 0),
        ["Separator Label"] = UDim2.new(0.338983059, 0, 0.94339627, 0),
        ["Page Number Box"] = UDim2.new(0.159322038, 0, 0.811320841, 0),
        ["Search/ID Box"] = UDim2.new(0.864406765, 0, 0.81578958, 0),
    },
    DefaultTexts = {
        ["Left Arrow"] = "",
        ["Right Arrow"] = "",
        ["Total Pages"] = "1",
        ["Separator Label"] = " ------ ",
        ["Page Number Box"] = "1",
        ["Search/ID Box"] = "",
        ["SpeedBox"] = "1",
    },
    DefaultPlaceholders = {
        ["Search/ID Box"] = "Search/ID",
    }
}

function getAllHUDObjects()
    local elems = {}
    if UI.Top then elems["Top"] = UI.Top end
    if UI.Under then elems["Under"] = UI.Under end
    if UI.EmoteWalkButton then elems["EmoteWalkButton"] = UI.EmoteWalkButton end
    if UI.Favorite then elems["Favorite"] = UI.Favorite end
    if UI.SpeedEmote then elems["SpeedEmote"] = UI.SpeedEmote end
    if UI.SpeedBox then elems["SpeedBox"] = UI.SpeedBox end
    if UI.Changepage then elems["Changepage"] = UI.Changepage end
    if UI.Reload then elems["Reload"] = UI.Reload end
    if UI.CustomFrames then
        for n, f in pairs(UI.CustomFrames) do
            elems[n] = f
        end
    end

    if UI.Top then
        for _, child in pairs(UI.Top:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UICorner") then
                local internalName = "Top." .. child.Name
                elems[HUD.FriendlyNames[internalName] or internalName] = child
            end
        end
    end
    if UI.Under then
        for _, child in pairs(UI.Under:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UICorner") then
                local internalName = "Under." .. child.Name
                elems[HUD.FriendlyNames[internalName] or internalName] = child
            end
        end
    end
    return elems
end

function getMovableElements()
    local all = getAllHUDObjects()
    local movable = {}
    
    for name, el in pairs(all) do
        local isChild = false
        for _, friendly in pairs(HUD.FriendlyNames) do 
            if name == friendly then isChild = true; break end 
        end
        
        if not isChild or HUD.IsUnlocked then
            movable[name] = el
        end
    end
    return movable
end

function ColorToTable(c) return {math.round(c.R*255), math.round(c.G*255), math.round(c.B*255)} end
function TableToColor(t)
    if type(t) ~= "table" then
        return Color3.fromRGB(255, 255, 255)
    end
    local r = tonumber(t[1]) or 255
    local g = tonumber(t[2]) or 255
    local b = tonumber(t[3]) or 255
    return Color3.fromRGB(r, g, b)
end

local function isThemeDefaultRGB(r, g, b)
    return r == 28 and g == 30 and b == 32
end

local AnimationSystem = {
    Cache = {},
    currentThemeName = "Default"
}   

AnimationSystem.LooksLikeGif = function(url)
    if not url then return false end
    url = string.lower(tostring(url))
    return url:find(".gif") or url:find("gif") or url:find("format=gif") or url:find("image/gif")
end

AnimationSystem.NormalizeUrl = function(url)
    if not url or url == "" then return url end
    local targetUrl = tostring(url)
    
    targetUrl = targetUrl:gsub("%?raw=true", "")
    
    if targetUrl:find("github%.com/") and not targetUrl:find("raw.githubusercontent%.com") then
        targetUrl = targetUrl:gsub("github%.com/", "raw.githubusercontent.com/")
        targetUrl = targetUrl:gsub("/blob/", "/")
        targetUrl = targetUrl:gsub("/raw/", "/")
    end
    
    if targetUrl:find(" ") and not targetUrl:find("%%20") then
        targetUrl = targetUrl:gsub(" ", "%%20")
    end
    
    if not targetUrl:find("://") then
        local id = targetUrl:match("id=(%d+)") or targetUrl:match("^(%d+)$")
        if id then return "rbxassetid://" .. id end
    end
    return targetUrl
end

AnimationSystem.ParseGifInfo = function(bytes)
    if not bytes or #bytes < 13 then return nil end
    if bytes:sub(1, 3) ~= "GIF" then return nil end
    local function u16le(pos)
        local b1 = bytes:byte(pos) or 0
        local b2 = bytes:byte(pos + 1) or 0
        return b1 + b2 * 256
    end
    local width = u16le(7)
    local height = u16le(9)
    local packed = bytes:byte(11) or 0
    local gctFlag = bit32.band(packed, 0x80) ~= 0
    local gctSize = bit32.band(packed, 0x07)
    local offset = 13
    if gctFlag then
        offset = offset + (3 * (2 ^ (gctSize + 1)))
    end

    local frames = 0
    local delays = {}
    local pendingDelay = nil

    local function skipSubBlocks(pos)
        while pos <= #bytes do
            local size = bytes:byte(pos) or 0
            pos = pos + 1
            if size == 0 then break end
            pos = pos + size
        end
        return pos
    end

    while offset <= #bytes do
        local b = bytes:byte(offset)
        if not b then break end
        if b == 0x3B then
            break
        elseif b == 0x21 then
            local label = bytes:byte(offset + 1) or 0
            if label == 0xF9 then
                local delay = u16le(offset + 4)
                pendingDelay = delay
                offset = offset + 8
            else
                offset = skipSubBlocks(offset + 2)
            end
        elseif b == 0x2C then
            frames = frames + 1
            if pendingDelay then
                table.insert(delays, pendingDelay)
                pendingDelay = nil
            end
            local packedImg = bytes:byte(offset + 9) or 0
            local lctFlag = bit32.band(packedImg, 0x80) ~= 0
            local lctSize = bit32.band(packedImg, 0x07)
            offset = offset + 10
            if lctFlag then
                offset = offset + (3 * (2 ^ (lctSize + 1)))
            end
            offset = offset + 1
            offset = skipSubBlocks(offset)
        else
            offset = offset + 1
        end
    end

    local totalDelay = 0
    for _, d in ipairs(delays) do totalDelay = totalDelay + d end
    local avgDelay = (#delays > 0) and (totalDelay / #delays) or 10

    return {
        width = width,
        height = height,
        frames = frames > 0 and frames or #delays,
        totalDelayCs = totalDelay,
        avgDelayCs = avgDelay
    }
end

AnimationSystem.ParsePngInfo = function(bytes)
    if not bytes or #bytes < 24 then return nil end
    if bytes:sub(1, 8) ~= "\137PNG\r\n\26\n" then return nil end
    local function u32be(pos)
        local b1 = bytes:byte(pos) or 0
        local b2 = bytes:byte(pos + 1) or 0
        local b3 = bytes:byte(pos + 2) or 0
        local b4 = bytes:byte(pos + 3) or 0
        return ((b1 * 256 + b2) * 256 + b3) * 256 + b4
    end
    local width = u32be(17)
    local height = u32be(21)
    if width <= 0 or height <= 0 then return nil end
    return { width = width, height = height }
end

AnimationSystem.StopGif = function()
    if State.currentWheelAnimToken then
        State.currentWheelAnimToken = State.currentWheelAnimToken + 1
    end
end

AnimationSystem.SetImageMode = function(img, custom)
    if not img then return end
    if custom then
        img.ScaleType = Enum.ScaleType.Stretch
        img.SliceCenter = Rect.new(0, 0, 0, 0)
        img.SliceScale = 1
    else
        img.ScaleType = Enum.ScaleType.Fit
    end
end

AnimationSystem.StartGif = function(img, data)
    AnimationSystem.StopGif()
    if not img or not data or not data.sprite then return end
    
    State.currentWheelAnimToken = (State.currentWheelAnimToken or 0) + 1
    local token = State.currentWheelAnimToken
    
    local frames = data.frames or 1
    local frameW = data.frameW or 0
    local frameH = data.frameH or 0
    local cols = data.cols or 1
    local rows = data.rows or 1
    local delay = data.delay or 0.1
    if delay <= 0 then delay = 0.1 end
    local sheetW = data.sheetW or (cols * frameW)
    local sheetH = data.sheetH or (rows * frameH)
    
    img.Image = data.sprite
    img.ImageRectSize = Vector2.new(frameW, frameH)
    img.ImageRectOffset = Vector2.new(0, 0)
    task.spawn(function()
        pcall(function() ContentProvider:PreloadAsync({img}) end)
    end)
    
    local current = 0
    local acc = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if token ~= State.currentWheelAnimToken then
            connection:Disconnect()
            return
        end
        if not img or not img.Parent then
            connection:Disconnect()
            return
        end
        acc = acc + dt
        if acc < delay then return end
        while acc >= delay do
            acc = acc - delay
            current = (current + 1) % frames
        end
        local col = current % cols
        local row = math.floor(current / cols)
        local offsetX = math.min(col * frameW, math.max(0, sheetW - frameW))
        local offsetY = math.min(row * frameH, math.max(0, sheetH - frameH))
        img.ImageRectOffset = Vector2.new(offsetX, offsetY)
    end)
end

AnimationSystem.AreMetaEqual = function(a, b)
    if not a or not b then return a == b end
    return a.GifUrl == b.GifUrl and a.SheetUrl == b.SheetUrl and a.Enabled == b.Enabled
end

AnimationSystem.MakeKey = function(gif, sheet)
    return tostring(gif) .. "|" .. tostring(sheet)
end

function ApplyFreezeButtonVisual()
    if not UI.EmoteWalkButton then return end
    UI.EmoteWalkButton.Image = State.emotesWalkEnabled and State.enabledButtonImage or State.defaultButtonImage
end

AnimationSystem.GetIconColor = function(key)
    if themes and themes[AnimationSystem.currentThemeName] then
        local theme = themes[AnimationSystem.currentThemeName]
        if theme.IconColors and theme.IconColors[key] then
            return TableToColor(theme.IconColors[key])
        end
        return TableToColor(theme.ImageColor or {255, 255, 255})
    elseif State.EmoteTheme then
        local theme = State.EmoteTheme
        if theme.IconColors and theme.IconColors[key] then
            return TableToColor(theme.IconColors[key])
        end
        return theme.ImageColor or Color3.new(1, 1, 1)
    end
    return Color3.fromRGB(255, 255, 255)
end

AnimationSystem.ResetRandomSlot = function(frontFrame)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if slot and slot:IsA("ImageLabel") then
        slot.ImageColor3 = Color3.fromRGB(255, 255, 255)
        slot.Image = ""
        local idValue = slot:FindFirstChild("AnimationID")
        if idValue then idValue:Destroy() end
    end
end

function SafeLoad(url, name)
    local success, content
    for i = 1, 3 do
        success, content = pcall(function() return game:HttpGet(url) end)
        if success and content and content ~= "" then break end
        task.wait(0.5)
    end
    
    if not success or not content or content == "" then
        getgenv().Notify({
            Title = 'Aphelion | Error',
            Content = 'Failed to download ' .. (name or "script") .. ' after 3 attempts.',
            Duration = 5
        })
        return function() end
    end

    local func, err = loadstring(content)
    if not func then
        warn("Aphelion | SafeLoad: Failed to parse " .. (name or "script") .. ": " .. tostring(err))
        return function() end
    end

    local ok, res = pcall(func)
    if not ok then
        warn("Aphelion | SafeLoad: Error executing " .. (name or "script") .. ": " .. tostring(res))
        return function() end
    end
    return res
end

SafeLoad("https://raw.githubusercontent.com/7yd7/Menu-7yd7/refs/heads/Script/GUIS/Off-site/Notify.lua", "Notify System")

local function getAssetCustom(filePath)
    if not filePath or filePath == "" then return nil end
    local customFn = getcustomasset or getsynasset
    if customFn then
        local ok, res = pcall(customFn, filePath)
        if ok and res and res ~= "" then
            return res
        end
    end
    return nil
end

local function fetchBinary(url)
    if not url or url == "" then return nil end
    local targetUrl = AnimationSystem.NormalizeUrl(url)
    
    if request then
        local ok, res = pcall(function()
            return request({
                Url = targetUrl,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Roblox/WinInet"
                }
            })
        end)
        if ok and res and (res.StatusCode == 200 or res.Status == 200) and res.Body and #res.Body > 0 then
            local low = res.Body:sub(1, 100):lower()
            if not (low:find("<!doctype") or low:find("<html") or low:find("<head")) then
                return res.Body
            end
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(targetUrl)
    end)
    if ok and body and #body > 0 then
        local low = body:sub(1, 100):lower()
        if not (low:find("<!doctype") or low:find("<html") or low:find("<head")) then
            return body
        end
    end
    return nil
end

function GetAsset(asset, preloadedBytes)
    if not asset or asset == "" then return "" end
    local assetStr = tostring(asset)
    
    _G.AssetCache = _G.AssetCache or {}
    if _G.AssetCache[assetStr] then return _G.AssetCache[assetStr] end

    if not assetStr:find("://") and tonumber(assetStr) then
        local id = "rbxassetid://" .. assetStr
        _G.AssetCache[assetStr] = id
        return id
    end
    
    if assetStr:find("rbxassetid://") or assetStr:find("rbxasset://") or assetStr:find("rbxthumb://") then
        return assetStr
    end
    
    if assetStr:find("http") then
        local targetUrl = AnimationSystem.NormalizeUrl(assetStr)

        local filename = targetUrl:match("([^/]+)$") or "asset.png"
        filename = filename:match("([^%?]+)") or filename
        
        filename = filename:gsub("[%c%*%?%\"%<%>%|]", "_")
        
        if filename:lower():find("%.gif$") then
            filename = filename:gsub("%.[gG][iI][fF]$", ".png")
        end
        if not filename:find("%.") then filename = filename .. ".png" end
        
        local path = "Aphelion/Assets/" .. filename
        
        if isfile and isfile(path) then
            local res = getAssetCustom(path)
            if res and res ~= "" then
                _G.AssetCache[assetStr] = res
                return res
            end
        end

        if not isfolder("Aphelion/Assets") then 
            pcall(function()
                if not isfolder("7yd7") then makefolder("7yd7") end
                makefolder("Aphelion/Assets") 
            end)
        end
        
        local content = preloadedBytes or fetchBinary(targetUrl)
        if content and #content > 0 then
            pcall(function() writefile(path, content) end)
            
            for attempt = 1, 4 do
                local res = getAssetCustom(path)
                if res and res ~= "" then
                    _G.AssetCache[assetStr] = res
                    return res
                end
                task.wait(0.08)
            end
        end
    end
    
    return assetStr
end

local function estimateRobloxResizedSize(origW, origH)
    if origW <= 0 or origH <= 0 then return origW, origH end
    local longest = math.max(origW, origH)
    local scale = 1
    if longest > 1024 then
        scale = 1024 / longest
    end
    return origW * scale, origH * scale
end

local function getExactImageSize(asset)
    local AssetService = game:GetService("AssetService")
    local ok, editImage = pcall(function()
        return AssetService:CreateEditableImageAsync(asset)
    end)
    if ok and editImage then
        local w = editImage.Size.X
        local h = editImage.Size.Y
        editImage:Destroy()
        if w > 0 and h > 0 then
            return w, h
        end
    end
    return nil
end

local DEFAULT_WHEEL_BG = "rbxasset://textures/ui/Emotes/Large/SegmentedCircle.png"
local RANDOM_SLOT_ICON = "rbxassetid://109283577128136"
local RANDOM_SLOT_COLOR = Color3.fromRGB(188, 188, 188)
local DEFAULT_IDLE_ICON_ID = "98513150727403"
local DEFAULT_IDLE_ICON_COLOR = Color3.fromRGB(188, 188, 188)
local wheelImgState = setmetatable({}, { __mode = "k" })
local checkEmotesMenuExists
local playEmote
local playRandomEmote
local handleSectorAction
local calculateTotalPages
local updatePageDisplay
local updateEmotes
local isInFavorites
local toggleFavorite
local toggleFavoriteAnimation
local refreshCustomAnimationState
local findCustomAnimationDataByName
local applyAnimation

local ConfigPath = "Aphelion/EmoteSettings.json"

function updateHUDLayouts()
    if not Config then return end
    local function toggleLayout(parent, unlocked)
        if not parent then return end
        local key = parent.Name
        local l = parent:FindFirstChildOfClass("UIListLayout") or HUD.Layouts[key]
        
        if l then
            HUD.Layouts[key] = l
            
            local hasCustomP = false
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("GuiObject") then
                    local internalName = key .. "." .. child.Name
                    local friendly = HUD.FriendlyNames[internalName] or internalName
                    if Config.HUDPositions and Config.HUDPositions[friendly] then
                        hasCustomP = true
                        break
                    end
                end
            end

            if HUD.IsUnlocked then
                l.Parent = nil
            elseif hasCustomP or (HUD.LayoutsRemoved and HUD.LayoutsRemoved[key]) then
                l.Parent = nil 
            else
                l.Parent = parent
            end
        end
    end
    
    toggleLayout(UI.Top, HUD.IsUnlocked)
    toggleLayout(UI.Under, HUD.IsUnlocked)
end

function applySavedPositions() end 
local enterHUDEditor, exitHUDEditor

local function updateSpeedBoxVisibility()
    if not UI.SpeedBox then return end
    if State.hudEditorActive then
        UI.SpeedBox.Visible = Config.SpeedVisible
    else
        UI.SpeedBox.Visible = (Config.SpeedVisible and State.speedEmoteEnabled)
    end
end

function ApplyUIVisibility()
    pcall(function()
        if UI.Search and UI.Top then UI.Top.Visible = Config.SearchVisible end
        if UI.Favorite then UI.Favorite.Visible = Config.FavVisible end
        if UI.Changepage then UI.Changepage.Visible = Config.ModeVisible end
        if UI.EmoteWalkButton then UI.EmoteWalkButton.Visible = Config.FreezeVisible end
        if UI.SpeedEmote then UI.SpeedEmote.Visible = Config.SpeedVisible end
        updateSpeedBoxVisibility()
        if UI.Under then UI.Under.Visible = Config.NavVisible end
        if UI.Reload then 
            if State.hudEditorActive then
                UI.Reload.Visible = true
            else
                UI.Reload.Visible = (State.currentMode == "animation" and Config.NavVisible) 
            end
        end
    end)
end

function SaveConfig()
    if not isfolder("7yd7") then makefolder("7yd7") end
    writefile(ConfigPath, HttpService:JSONEncode(Config))
end

function LoadConfig()
    if isfile(ConfigPath) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigPath)) end)
        if success and type(decoded) == "table" then
            for k, v in pairs(decoded) do Config[k] = v end
        end
    end
    getgenv().autoReloadEnabled = Config.AutoReloadEnabled or false
    getgenv().lastPlayedAnimation = Config.LastPlayedAnimationData
end
LoadConfig()

local rawNotify = getgenv().Notify
getgenv().Notify = function(data)
    if Config.NotifyEnabled then
        rawNotify(data)
    end
end

local SettingsLib = SafeLoad("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Settings.lua", "Settings Library")

local ToggleContainer = Instance.new("Frame")
ToggleContainer.Name = "open/Close"
ToggleContainer.Parent = SettingsLib.UI
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.Size = UDim2.fromScale(1, 1)
ToggleContainer.ZIndex = 5000
ToggleContainer.Visible = false
ToggleContainer.Active = false
ToggleContainer.Selectable = false

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleSettings"
ToggleBtn.Parent = ToggleContainer
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.BackgroundTransparency = 0.4
ToggleBtn.Position = UDim2.new(0, 10, 1, -52)
ToggleBtn.Size = UDim2.fromOffset(42, 42)
ToggleBtn.Image = "rbxassetid://79568054778195"

local DiscordBtn = Instance.new("ImageButton")
DiscordBtn.Name = "DiscordButton"
DiscordBtn.Parent = ToggleContainer
DiscordBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DiscordBtn.BackgroundTransparency = 0.4
DiscordBtn.Position = UDim2.new(0, 57, 1, -52)
DiscordBtn.Size = UDim2.fromOffset(42, 42)
DiscordBtn.Image = "rbxassetid://98681818461563"

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 10)
DiscordCorner.Parent = DiscordBtn

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleBtn

function getSettingsMainFrame()
    if SettingsLib and SettingsLib.UI then
        return SettingsLib.UI:FindFirstChild("MainFrame")
    end
    return nil
end

function applySettingsToggleStyle()
    local main = getSettingsMainFrame()
    local bgColor
    if main then
        bgColor = main.BackgroundColor3
    elseif State.EmoteTheme and State.EmoteTheme.Background then
        bgColor = State.EmoteTheme.Background
    end

    if bgColor then
        ToggleBtn.BackgroundColor3 = bgColor
        DiscordBtn.BackgroundColor3 = bgColor
    end
end

function syncToggleVisibility()
    local main = getSettingsMainFrame()
    if main then
        ToggleContainer.Visible = not main.Visible
    else
        ToggleContainer.Visible = true
    end
end

function syncDiscordVisibility()
    DiscordBtn.Visible = Config.DiscordVisible
end

DiscordBtn.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/kRfzv2kV7X")
    getgenv().Notify({Title = "Discord", Content = "The Discord invite has been copied", Duration = 3})
end)

ToggleBtn.MouseButton1Click:Connect(function()
    local main = getSettingsMainFrame()
    if main then
        main.Visible = not main.Visible
        syncToggleVisibility()
    else
        SettingsLib.UI.Enabled = not SettingsLib.UI.Enabled
    end
end)

applySettingsToggleStyle()
syncToggleVisibility()
syncDiscordVisibility()

do
    local main = getSettingsMainFrame()
    if main then
        main:GetPropertyChangedSignal("Visible"):Connect(syncToggleVisibility)
    end
end

local TogglesUI = {}
local GeneralTab = SettingsLib.CreateTab("General", 1)
TogglesUI.NotifyEnabled = SettingsLib.AddToggle(GeneralTab, "Show Notifications", "Receive alerts and feedback", Config.NotifyEnabled, function(v)
    Config.NotifyEnabled = v
    SaveConfig()
end)

TogglesUI.AuthenticFirstPage = SettingsLib.AddToggle(GeneralTab, "Authentic Emotes Page", "Show owned emotes on page 1", Config.AuthenticFirstPage, function(v)
    Config.AuthenticFirstPage = v
    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    updatePageDisplay()
    updateEmotes()
    SaveConfig()
end)

local randomModes = { "All", "Favorites" }
local randomDropdown = SettingsLib.AddDropdown(GeneralTab, "Random Source", randomModes, Config.RandomMode or "All", function(v)
    Config.RandomMode = v
    SaveConfig()
end)
if randomDropdown and randomDropdown.Button then
    randomDropdown.Button.Text = (Config.RandomMode or "All") .. "  ▼"
end

TogglesUI.RandomEnabled = SettingsLib.AddToggle(GeneralTab, "Random Enabled", "Enable/disable random", Config.RandomEnabled, function(v)
    Config.RandomEnabled = v
    if not v then
        pcall(function()
            local frontFrame = game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
            local slot1 = frontFrame and frontFrame:FindFirstChild("1")
            local slot2 = frontFrame and frontFrame:FindFirstChild("2")
            if slot1 and slot1:IsA("ImageLabel") and slot2 and slot2:IsA("ImageLabel") then
                local img2 = slot2.Image
                if img2 and img2 ~= "" then
                    slot1.Image = img2
                end
            end
        end)
    end
    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    updatePageDisplay()
    updateEmotes()
    SaveConfig()
end)

local CleanFavItem = SettingsLib.AddItem(GeneralTab, "Clean Deleted Favorites", "Scan all favorites (emotes + animations) and remove any that were deleted (click twice)")
CleanFavItem.LayoutOrder = 10
local CleanFavBtn = SettingsLib:Create("TextButton", {
    Parent = CleanFavItem,
    BackgroundColor3 = Color3.fromRGB(220, 60, 60),
    Position = UDim2.new(1, -90, 0.5, -12),
    Size = UDim2.new(0, 80, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "CLEAN",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11
}, { SettingsLib:Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })

local cleanFavConfirm = false
local cleanFavConfirmConn = nil
local cleanFavCleaning = false

local function resetCleanButton()
    cleanFavConfirm = false
    if cleanFavConfirmConn then
        pcall(function() cleanFavConfirmConn:Cancel() end)
        cleanFavConfirmConn = nil
    end
    if CleanFavBtn and CleanFavBtn.Parent then
        CleanFavBtn.Text = "CLEAN"
        CleanFavBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end

local cleanDeletedFavorites

cleanDeletedFavorites = function()
    if cleanFavCleaning then return end
    cleanFavCleaning = true

    local emoteIds = {}
    local animIds = {}

    local emotePages = (State.EmotePages and State.EmotePages.Sets) or {}
    for _, favList in pairs(emotePages) do
        if type(favList) == "table" then
            for _, fav in ipairs(favList) do
                if fav and fav.id and tonumber(fav.id) and tonumber(fav.id) > 0 then
                    emoteIds[tostring(fav.id)] = true
                end
            end
        end
    end

    for _, fav in ipairs(State.favoriteAnimations or {}) do
        if fav and fav.id and not fav.isCustomSet and tonumber(fav.id) and tonumber(fav.id) > 0 then
            animIds[tostring(fav.id)] = true
        end
    end

    local emoteIdList = {}
    for id in pairs(emoteIds) do table.insert(emoteIdList, id) end
    local animIdList = {}
    for id in pairs(animIds) do table.insert(animIdList, id) end

    local totalChecks = #emoteIdList + #animIdList
    if totalChecks == 0 then
        getgenv().Notify({ Title = "Aphelion | Clean", Content = "No favorites to check!", Duration = 3 })
        cleanFavCleaning = false
        resetCleanButton()
        return
    end

    getgenv().Notify({ Title = "Aphelion | Clean", Content = "Checking " .. totalChecks .. " favorites...", Duration = 3 })

    local deletedEmotes = {}
    local deletedAnims = {}
    local checked = 0

    local function updateProgress()
        if CleanFavBtn and CleanFavBtn.Parent then
            CleanFavBtn.Text = math.floor((checked / totalChecks) * 100) .. "%"
        end
    end

    local function checkBatch(ids, isBundle, deletedOut)
        local url
        if isBundle then
            url = "https://thumbnails.roblox.com/v1/bundles/thumbnails?bundleIds=" .. table.concat(ids, ",") .. "&size=420x420&format=Png"
        else
            url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. table.concat(ids, ",") .. "&size=420x420&format=Png"
        end
        local body = fetchBinary(url)
        local parsed = nil
        if body and #body > 0 then
            pcall(function()
                parsed = HttpService:JSONDecode(body)
            end)
        end
        if parsed and parsed.data and type(parsed.data) == "table" then
            for _, entry in ipairs(parsed.data) do
                local targetId = tostring(entry.targetId)
                if entry.state == "Blocked" or entry.state == "Error" or not entry.imageUrl or entry.imageUrl == "" then
                    deletedOut[targetId] = true
                end
            end
        end
        task.wait(0.05)
    end

    local BATCH = 50
    for i = 1, #emoteIdList, BATCH do
        local chunk = {}
        for j = i, math.min(i + BATCH - 1, #emoteIdList) do table.insert(chunk, emoteIdList[j]) end
        checkBatch(chunk, false, deletedEmotes)
        checked = checked + #chunk
        updateProgress()
    end
    for i = 1, #animIdList, BATCH do
        local chunk = {}
        for j = i, math.min(i + BATCH - 1, #animIdList) do table.insert(chunk, animIdList[j]) end
        checkBatch(chunk, true, deletedAnims)
        checked = checked + #chunk
        updateProgress()
    end

    local removedEmotes = 0
    for pageName, favList in pairs(emotePages) do
        if type(favList) == "table" then
            local newList = {}
            for _, fav in ipairs(favList) do
                if fav and fav.id and deletedEmotes[tostring(fav.id)] then
                    removedEmotes = removedEmotes + 1
                else
                    table.insert(newList, fav)
                end
            end
            State.EmotePages.Sets[pageName] = newList
        end
    end

    local removedAnims = 0
    local newAnims = {}
    for _, fav in ipairs(State.favoriteAnimations or {}) do
        if fav and fav.id and not fav.isCustomSet and deletedAnims[tostring(fav.id)] then
            removedAnims = removedAnims + 1
        else
            table.insert(newAnims, fav)
        end
    end
    State.favoriteAnimations = newAnims

    State.favoriteEmotes = DeepCopy(State.EmotePages.Sets[State.currentEmotePageName] or {}) or {}
    State.favoriteEmoteSet = {}
    for _, fav in pairs(State.favoriteEmotes) do
        State.favoriteEmoteSet[tostring(fav.id)] = true
    end
    State.favoriteAnimationSet = {}
    for _, fav in pairs(State.favoriteAnimations) do
        State.favoriteAnimationSet[tostring(fav.id)] = true
    end
    State.favoriteSetVersion = State.favoriteSetVersion + 1

    State.SaveEmotePages(State.EmotePages)
    pcall(function()
        if not isfolder("7yd7") then makefolder("7yd7") end
        writefile(State.favoriteAnimationsFileName, HttpService:JSONEncode(State.favoriteAnimations))
    end)

    _G.filteredFavoritesForDisplay = nil
    _G.filteredFavoritesAnimationsForDisplay = nil

    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    updatePageDisplay()
    if State.currentMode == "animation" then
        updateAnimations()
    else
        updateEmotes()
    end
    updateAllFavoriteIcons()

    for _, fav in pairs(State.favoriteEmotes) do
        if fav and fav.id then
            preloadThumbnail("rbxthumb://type=Asset&id=" .. tostring(fav.id) .. "&w=420&h=420")
        end
    end
    for _, fav in pairs(State.favoriteAnimations) do
        if fav and fav.id and not fav.isCustomSet then
            preloadThumbnail("rbxthumb://type=BundleThumbnail&id=" .. tostring(fav.id) .. "&w=420&h=420")
        end
    end

    local cleanUpToken = State.imageUpdateToken
    task.delay(0.35, function()
        if State.imageUpdateToken ~= cleanUpToken then return end
        updatePageDisplay()
        if State.currentMode == "animation" then
            updateAnimations()
        else
            updateEmotes()
        end
        updateAllFavoriteIcons()
    end)

    getgenv().Notify({
        Title = "Aphelion | Cleaned",
        Content = "Removed " .. removedEmotes .. " deleted emote" .. (removedEmotes == 1 and "" or "s") .. " & " .. removedAnims .. " deleted animation" .. (removedAnims == 1 and "" or "s"),
        Duration = 5
    })
    cleanFavCleaning = false
    resetCleanButton()
end

CleanFavBtn.MouseButton1Click:Connect(function()
    if cleanFavCleaning then return end
    if not cleanFavConfirm then
        cleanFavConfirm = true
        CleanFavBtn.Text = "CONFIRM?"
        CleanFavBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
        if cleanFavConfirmConn then
            pcall(function() cleanFavConfirmConn:Cancel() end)
        end
        cleanFavConfirmConn = task.delay(3, resetCleanButton)
        return
    end
    resetCleanButton()
    CleanFavBtn.Text = "0%"
    CleanFavBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
    task.spawn(cleanDeletedFavorites)
end)

local ButtonsTab = SettingsLib.CreateTab("Buttons", 2)

TogglesUI.SearchVisible = SettingsLib.AddToggle(ButtonsTab, "Search Bar", "Show/Hide the search input", Config.SearchVisible, function(v)
    Config.SearchVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.FavVisible = SettingsLib.AddToggle(ButtonsTab, "Favorites Button", "Show/Hide the star button", Config.FavVisible, function(v)
    Config.FavVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.ModeVisible = SettingsLib.AddToggle(ButtonsTab, "Mode Switcher", "Show/Hide animation mode button", Config.ModeVisible, function(v)
    Config.ModeVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.FreezeVisible = SettingsLib.AddToggle(ButtonsTab, "Freeze Button", "Show/Hide emote freeze button", Config.FreezeVisible, function(v)
    Config.FreezeVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.SpeedVisible = SettingsLib.AddToggle(ButtonsTab, "Speed Button", "Show/Hide the speed controller", Config.SpeedVisible, function(v)
    Config.SpeedVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.NavVisible = SettingsLib.AddToggle(ButtonsTab, "Page Controls", "Show/Hide navigation buttons", Config.NavVisible, function(v)
    Config.NavVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.DiscordVisible = SettingsLib.AddToggle(ButtonsTab, "Discord Button", "Show/Hide the discord link button", Config.DiscordVisible, function(v)
    Config.DiscordVisible = v
    syncDiscordVisibility()
    SaveConfig()
end)

local cachedOverlay = nil
local hudEditorItem = SettingsLib.AddItem(ButtonsTab, "HUD Editor", "Reposition buttons & UI elements")
hudEditorItem.LayoutOrder = -10
local hudEditorBtn = SettingsLib:Create("TextButton", {
    Parent = hudEditorItem,
    BackgroundColor3 = Color3.fromRGB(0, 255, 150),
    Position = UDim2.new(1, -80, 0.5, -12),
    Size = UDim2.new(0, 70, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "EDIT",
    TextColor3 = Color3.fromRGB(24, 25, 28),
    TextSize = 11
}, { SettingsLib:Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })

hudEditorBtn.MouseButton1Click:Connect(function()
    if enterHUDEditor then enterHUDEditor() end
end)
function getBackgroundOverlay()
    if cachedOverlay and cachedOverlay.Parent then return cachedOverlay end
    
    local success, result = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Back.Background
                   .BackgroundCircleOverlay
    end)
    if success and result then
        cachedOverlay = result
        return result
    end
    return nil
end

function DeepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local ApplyFavoriteButtonVisual
function updateGUIColors()
    local backgroundOverlay = getBackgroundOverlay()
    if not backgroundOverlay then
        return
    end

    local theme = State.EmoteTheme
    if not theme then return end
    
    local bgColor = theme.Background
    local accentColor = theme.Accent
    local imgColor = theme.ImageColor
    local bgTransparency = backgroundOverlay.BackgroundTransparency

    local function getIconColor(key)
        if theme.IconColors and theme.IconColors[key] then
            return TableToColor(theme.IconColors[key])
        end
        return imgColor
    end

    if UI._1left then
        UI._1left.ImageColor3 = getIconColor("Left")
        UI._1left.ImageTransparency = bgTransparency
        UI._1left.BackgroundTransparency = 1 
    end

    if UI._9right then
        UI._9right.ImageColor3 = getIconColor("Right")
        UI._9right.ImageTransparency = bgTransparency
        UI._9right.BackgroundTransparency = 1
    end

    if UI._4pages then
        UI._4pages.TextColor3 = bgColor 
        UI._4pages.TextTransparency = bgTransparency
    end

    if UI._3TextLabel then
        UI._3TextLabel.TextColor3 = bgColor
        UI._3TextLabel.TextTransparency = bgTransparency
    end

    if UI._2Routenumber then
        UI._2Routenumber.TextColor3 = bgColor
        UI._2Routenumber.PlaceholderColor3 = bgColor
        UI._2Routenumber.TextTransparency = bgTransparency
    end

    if UI.Under then
        UI.Under.BackgroundTransparency = 1
    end

    if UI.Top then
        UI.Top.BackgroundColor3 = bgColor
        UI.Top.BackgroundTransparency = bgTransparency
    end

    if UI.EmoteWalkButton then
        UI.EmoteWalkButton.BackgroundColor3 = bgColor
        UI.EmoteWalkButton.BackgroundTransparency = bgTransparency
    end

    if UI.CustomFrames then
        for _, frame in pairs(UI.CustomFrames) do
            frame.BackgroundColor3 = bgColor
            frame.BackgroundTransparency = bgTransparency
        end
    end

    if UI.SpeedEmote then
        UI.SpeedEmote.BackgroundColor3 = bgColor
        UI.SpeedEmote.BackgroundTransparency = bgTransparency
    end

     if UI.Changepage then
        UI.Changepage.BackgroundColor3 = bgColor
        UI.Changepage.BackgroundTransparency = bgTransparency
    end

    if UI.SpeedBox then
        UI.SpeedBox.BackgroundColor3 = bgColor
        UI.SpeedBox.BackgroundTransparency = bgTransparency
    end

    if UI.Favorite then
        UI.Favorite.BackgroundColor3 = bgColor
        UI.Favorite.BackgroundTransparency = bgTransparency
    end

    if UI.Reload then
        UI.Reload.BackgroundColor3 = bgColor
        UI.Reload.BackgroundTransparency = bgTransparency
    end
    
    if ApplyFavoriteButtonVisual then
        ApplyFavoriteButtonVisual()
    end

    local function applyHUDProperties()
        if not Config.HUDProperties then return end
        local allMovable = getAllHUDObjects()
        for name, uiExt in pairs(allMovable) do
            local props = Config.HUDProperties[name]
            if props then
                if props.ZIndex ~= nil then pcall(function() uiExt.ZIndex = props.ZIndex end) end
                if props.BgTrans ~= nil then pcall(function() uiExt.BackgroundTransparency = props.BgTrans end) end
                if props.ImgTrans ~= nil and (uiExt:IsA("ImageLabel") or uiExt:IsA("ImageButton")) then pcall(function() uiExt.ImageTransparency = props.ImgTrans end) end
                if props.BgColor and type(props.BgColor) == "table" then
                    local r, g, b = props.BgColor[1], props.BgColor[2], props.BgColor[3]
                    if r and g and b and not isThemeDefaultRGB(r, g, b) then
                        pcall(function() uiExt.BackgroundColor3 = Color3.fromRGB(r, g, b) end)
                    end
                end
                if props.ImgColor and type(props.ImgColor) == "table" and (uiExt:IsA("ImageLabel") or uiExt:IsA("ImageButton")) then
                    local r, g, b = props.ImgColor[1], props.ImgColor[2], props.ImgColor[3]
                    if r and g and b and not isThemeDefaultRGB(r, g, b) then
                        pcall(function() uiExt.ImageColor3 = Color3.fromRGB(r, g, b) end)
                    end
                end
                if props.TxtColor and type(props.TxtColor) == "table" and (uiExt:IsA("TextLabel") or uiExt:IsA("TextBox")) then
                    local r, g, b = props.TxtColor[1], props.TxtColor[2], props.TxtColor[3]
                    if r and g and b and not isThemeDefaultRGB(r, g, b) then
                        pcall(function() uiExt.TextColor3 = Color3.fromRGB(r, g, b) end)
                    end
                end
                if props.Radius and uiExt:FindFirstChildWhichIsA("UICorner") then
                    local s1, o1 = props.Radius:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
                    if s1 then pcall(function() uiExt:FindFirstChildWhichIsA("UICorner").CornerRadius = UDim.new(tonumber(s1), tonumber(o1)) end) end
                end
            end
        end
    end
    
    applyHUDProperties()
    ApplyUIVisibility()
    applySettingsToggleStyle()
end

ApplyFavoriteButtonVisual = function()
    if not UI.Favorite then return end
    local isOn = State.favoriteEnabled
    local image = isOn and State.favoriteIconId or State.notFavoriteIconId
    if image and image ~= "" then
        UI.Favorite.Image = image
    end
    local colorKey = isOn and "Favorite" or "NotFavorite"
    UI.Favorite.ImageColor3 = AnimationSystem.GetIconColor(colorKey)
end

-- Optimizing performance: Removed RenderStepped loop
-- game:GetService("RunService").RenderStepped:Connect(function()
--     updateGUIColors()
-- end)

local ThemeTab = SettingsLib.CreateTab("Theme", 3)

local DiscordPromo = SettingsLib.AddItem(ThemeTab, "WANT THEMES?", "Join our Discord for themes!")
DiscordPromo.LayoutOrder = -1

local CopyBtn = SettingsLib:Create("TextButton", {
    Parent = DiscordPromo,
    BackgroundColor3 = Color3.fromRGB(0, 255, 150),
    Position = UDim2.new(1, -95, 0.5, -12),
    Size = UDim2.new(0, 85, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "COPY LINK",
    TextColor3 = Color3.fromRGB(24, 25, 28),
    TextSize = 11
}, { SettingsLib:Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })

CopyBtn.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/kRfzv2kV7X")
    getgenv().Notify({Title = "Discord", Content = "Link copied to clipboard!", Duration = 3})
end)

local ThemeConfigPath = "Aphelion/EmoteThemes.json"

local lastSaveTime = 0
local saveDebounce = 1
local pendingSave = false

function SaveThemesImplementation(themes)
    if not isfolder("7yd7") then makefolder("7yd7") end
    local toSave = { Themes = {}, Order = {}, Selected = themes.Selected or AnimationSystem.currentThemeName }
    
    toSave.Order = themes.Order or {}
    
    for name, data in pairs(themes) do
        if name ~= "Default" and name ~= "Order" and name ~= "Selected" then
            toSave.Themes[name] = data
        end
    end
    writefile(ThemeConfigPath, HttpService:JSONEncode(toSave))
end

function SaveThemes(themes)
    if pendingSave then 
        pendingSave = "queued"
        return 
    end
    pendingSave = true
    task.delay(0.5, function()
        SaveThemesImplementation(themes)
        local wasQueued = pendingSave == "queued"
        pendingSave = false
        if wasQueued then
            SaveThemes(themes)
        end
    end)
end

function LoadThemes()
    local defaultTheme = {
        Background = {28, 30, 32},
        Accent = {0, 255, 150},
        ImageColor = {255, 255, 255},
        IconColors = {
            Left = {0, 0, 0},
            Right = {0, 0, 0}
        },
        Icons = {
            Left = "93111945058621",
            Right = "107938916240738",
            Walk = "71408678974152",
            Favorite = "97307461910825",
            NotFavorite = "124025954365505",
            Speed = "116056570415896",
            Page = "13285615740",
            Reload = "127493377027615"
        },
        Wheel = {
            BackgroundImage = "rbxasset://textures/ui/Emotes/Large/SegmentedCircle.png",
            BackgroundImageColor = {255, 255, 255},
            SelectionGradient = "rbxasset://textures/ui/Emotes/Large/SelectedGradient.png",
            SelectionGradientColor = {255, 255, 255},
            SelectionLine = "rbxasset://textures/ui/Emotes/Large/SelectedLine.png",
            SelectionLineColor = {255, 255, 255}
        }
    }
    
    local loaded = { Default = defaultTheme, Order = {"Default"} }
    
    if isfile(ThemeConfigPath) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ThemeConfigPath)) end)
        if success and type(decoded) == "table" then
            local themesTable = decoded.Themes or decoded 
            local orderTable = decoded.Order or {}
            
            for name, data in pairs(themesTable) do
                if not data.Icons then data.Icons = DeepCopy(defaultTheme.Icons) end
                if not data.Wheel then data.Wheel = DeepCopy(defaultTheme.Wheel) end
                loaded[name] = data
                
                if name == "Default" then
                    if not data.IconColors then data.IconColors = {} end
                    data.IconColors.Left = {0, 0, 0}
                    data.IconColors.Right = {0, 0, 0}
                end

                if not decoded.Order and name ~= "Default" then
                    table.insert(loaded.Order, name)
                end
            end
            
            if decoded.Order then
                loaded.Order = {"Default"}
                for _, name in ipairs(decoded.Order) do
                    if name ~= "Default" and loaded[name] then
                        table.insert(loaded.Order, name)
                    end
                end
            end
            
            if decoded.Selected and loaded[decoded.Selected] then
                loaded.Selected = decoded.Selected
            end
            
            return loaded
        end
    end
    return loaded
end

State.pendingCustomAnimSave = false
State.SaveCustomAnimationsImplementation = function(animData)
    if not isfolder("7yd7") then makefolder("7yd7") end
    local toSave = { Sets = {}, Order = animData.Order or {"Default"}, Selected = animData.Selected or "Default" }
    for name, data in pairs(animData.Sets) do
        if name ~= "Default" then
            toSave.Sets[name] = data
        end
    end
    writefile(State.CustomAnimationPath, HttpService:JSONEncode(toSave))
end

State.SaveCustomAnimations = function(animData)
    if State.pendingCustomAnimSave then
        State.pendingCustomAnimSave = "queued"
        return
    end
    State.pendingCustomAnimSave = true
    task.delay(0.5, function()
        State.SaveCustomAnimationsImplementation(animData)
        local wasQueued = State.pendingCustomAnimSave == "queued"
        State.pendingCustomAnimSave = false
        if wasQueued then State.SaveCustomAnimations(animData) end
    end)
end

State.LoadCustomAnimations = function()
    local defaultAnim = {
        idle = { Animation1 = 0, Animation2 = 0 },
        walk = { WalkAnim = 0 },
        run = { RunAnim = 0 },
        jump = { JumpAnim = 0 },
        fall = { FallAnim = 0 },
        climb = { ClimbAnim = 0 },
        swimidle = { SwimIdle = 0 },
        swim = { Swim = 0 },
        __meta = { IconImage = DEFAULT_IDLE_ICON_ID, IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) }
    }
    local loaded = { Sets = { Default = defaultAnim }, Order = {"Default"}, Selected = "Default" }
    
    if isfile(State.CustomAnimationPath) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(State.CustomAnimationPath)) end)
        if success and type(decoded) == "table" then
            local setsTable = decoded.Sets or {}
            for name, data in pairs(setsTable) do
                loaded.Sets[name] = data
            end
            
            if decoded.Order then
                loaded.Order = {"Default"}
                for _, name in ipairs(decoded.Order) do
                    if name ~= "Default" and loaded.Sets[name] then
                        table.insert(loaded.Order, name)
                    end
                end
            end
            
            if decoded.Selected and loaded.Sets[decoded.Selected] then
                loaded.Selected = decoded.Selected
            end
        end
    end
    
    return loaded
end

State.SaveEmotePages = function(pageData)
    if not isfolder("7yd7") then makefolder("7yd7") end
    local toSave = { 
        Sets = {}, 
        Order = pageData.Order or {"Default"}, 
        Selected = pageData.Selected or "Default" 
    }
    for name, data in pairs(pageData.Sets) do
        if name ~= "Default" then
            toSave.Sets[name] = data
        end
    end
    writefile(State.EmotePagePath, HttpService:JSONEncode(toSave))
    
    if pageData.Sets["Default"] then
        writefile(State.favoriteFileName, HttpService:JSONEncode(pageData.Sets["Default"]))
    end
end

function SwitchEmotePage(pageName)
    if not State.EmotePages.Sets[pageName] then return end
    
    State.currentEmotePageName = pageName
    State.EmotePages.Selected = pageName
    
    local pageData = State.EmotePages.Sets[pageName]
    State.favoriteEmotes = DeepCopy(pageData) or {}
    
    State.favoriteEmoteSet = {}
    for _, fav in pairs(State.favoriteEmotes) do
        State.favoriteEmoteSet[tostring(fav.id)] = true
    end
    
    State.favoriteSetVersion = State.favoriteSetVersion + 1
    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    
    updatePageDisplay()
    if State.currentMode == "emote" then
        updateEmotes()
    end
    updateAllFavoriteIcons()
end

State.LoadEmotePages = function()
    local defaultFavorites = {}
    
    if isfile(State.favoriteFileName) then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(State.favoriteFileName)) end)
        if ok and type(decoded) == "table" then
            defaultFavorites = decoded
        end
    end

    local loaded = { Sets = { Default = defaultFavorites }, Order = {"Default"}, Selected = "Default" }
    
    if isfile(State.EmotePagePath) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(State.EmotePagePath)) end)
        if success and type(decoded) == "table" then
            local setsTable = decoded.Sets or {}
            for name, data in pairs(setsTable) do
                if name ~= "Default" then
                    loaded.Sets[name] = data
                end
            end
            
            if decoded.Order then
                loaded.Order = {"Default"}
                for _, name in ipairs(decoded.Order) do
                    if name ~= "Default" and loaded.Sets[name] then
                        table.insert(loaded.Order, name)
                    end
                end
            end
            
            if decoded.Selected and (loaded.Sets[decoded.Selected] or decoded.Selected == "Default") then
                loaded.Selected = decoded.Selected
            end
        end
    end
    
    return loaded
end

State.EmotePages = State.LoadEmotePages()
State.currentEmotePageName = State.EmotePages.Selected or "Default"
if not State.EmotePages.Sets[State.currentEmotePageName] then 
    State.currentEmotePageName = "Default" 
end

State.favoriteEmotes = DeepCopy(State.EmotePages.Sets[State.currentEmotePageName]) or {}
State.favoriteEmoteSet = {}
for _, fav in pairs(State.favoriteEmotes) do
    State.favoriteEmoteSet[tostring(fav.id)] = true
end

State.favoriteAnimations = {}
pcall(function()
    if isfile and isfile(State.favoriteAnimationsFileName) then
        local json = readfile(State.favoriteAnimationsFileName)
        local decoded = HttpService:JSONDecode(json)
        if type(decoded) == "table" then
            State.favoriteAnimations = decoded
        end
    end
end)
State.favoriteAnimationSet = {}
for _, fav in pairs(State.favoriteAnimations) do
    State.favoriteAnimationSet[tostring(fav.id)] = true
end


State.CustomAnimations = State.LoadCustomAnimations()
State.currentCustomAnimationName = State.CustomAnimations.Selected or "Default"
if not State.CustomAnimations.Sets[State.currentCustomAnimationName] then 
    State.currentCustomAnimationName = "Default" 
end

local themes = LoadThemes()
local currentThemeName = Config.SelectedTheme or themes.Selected or "Default"
if not themes[currentThemeName] then currentThemeName = "Default" end

local themeDropdown

function GetNames()
    local n = {}
    if themes.Order then
        for _, name in ipairs(themes.Order) do
            if name ~= "Order" and name ~= "Selected" and themes[name] then 
                table.insert(n, name) 
            end
        end
    end
    for name, _ in pairs(themes) do
        if name ~= "Order" and name ~= "Selected" and not table.find(n, name) then
            table.insert(n, name)
        end
    end
    return n
end

local UIElements = {
    Background = {},
    Accent = {},
    ImageColor = {},
    Icons = {},
    Wheel = {}
}

function ApplyWheelBackgroundImage(bgImg, wheel)
    if not bgImg or not wheel then return end
    local bgSrc = wheel.BackgroundImage or ""
    local isCustomBg = tostring(bgSrc) ~= DEFAULT_WHEEL_BG

    local gifUrl, sheetUrl = nil, nil
    if bgSrc and tostring(bgSrc):find("\n") then
        local lines = {}
        for line in tostring(bgSrc):gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" then table.insert(lines, line) end
        end
        gifUrl = lines[1]
        sheetUrl = lines[2]
    elseif tostring(bgSrc):find("|") then
        local parts = {}
        for part in tostring(bgSrc):gmatch("[^|]+") do
            part = part:match("^%s*(.-)%s*$")
            if part ~= "" then table.insert(parts, part) end
        end
        gifUrl = parts[1]
        sheetUrl = parts[2]
    elseif AnimationSystem.LooksLikeGif(bgSrc) then
        gifUrl = bgSrc
    end
 
    local targetUrl = AnimationSystem.NormalizeUrl(bgSrc)
    if gifUrl then gifUrl = AnimationSystem.NormalizeUrl(gifUrl) end
    if sheetUrl then sheetUrl = AnimationSystem.NormalizeUrl(sheetUrl) end
 
    if gifUrl and sheetUrl and sheetUrl ~= "" then
        if gifUrl:lower():find("%.png") and (sheetUrl:lower():find("%.gif") or sheetUrl:lower():find("format=gif")) then
            local temp = gifUrl
            gifUrl = sheetUrl
            sheetUrl = temp
        end

        local cacheKey = AnimationSystem.MakeKey(gifUrl, sheetUrl)
        local meta = wheel.Animation
        if meta and meta.GifUrl == gifUrl and meta.SheetUrl == sheetUrl then
            AnimationSystem.Cache[cacheKey] = meta
        else
            meta = AnimationSystem.Cache[cacheKey]
        end
 
        if meta and meta.Enabled == true then
            if (meta.FrameWidth or 0) > 0 and (meta.FrameHeight or 0) > 0 then
                local frames = tonumber(meta.Frames) or 0
                local cols = tonumber(meta.Cols) or 0
                local rows = tonumber(meta.Rows) or 0
                local frameW = tonumber(meta.FrameWidth) or 0
                local frameH = tonumber(meta.FrameHeight) or 0
                local fps = tonumber(meta.FPS) or 10
                local delay = fps > 0 and (1 / fps) or 0.1
                local rawSheetW = tonumber(meta.SheetWidth) or (cols * frameW)
                local rawSheetH = tonumber(meta.SheetHeight) or (rows * frameH)
                local sheetAsset = GetAsset(sheetUrl)
                if sheetAsset and sheetAsset ~= "" and not sheetAsset:find("^https?://") then
                    local resizedW, resizedH = estimateRobloxResizedSize(rawSheetW, rawSheetH)
                    local adjFrameW = frameW * (resizedW / rawSheetW)
                    local adjFrameH = frameH * (resizedH / rawSheetH)

                    local spriteData = {
                        sprite = sheetAsset,
                        frames = frames,
                        frameW = adjFrameW,
                        frameH = adjFrameH,
                        cols = cols,
                        rows = rows,
                        sheetW = resizedW,
                        sheetH = resizedH,
                        delay = delay
                    }
                    AnimationSystem.SetImageMode(bgImg, true)
                    AnimationSystem.StartGif(bgImg, spriteData)
                    return
                end
            end
        end

        task.spawn(function()
            local gifBytes = fetchBinary(gifUrl)
            local gifInfo = gifBytes and AnimationSystem.ParseGifInfo(gifBytes) or nil

            local sheetBytes = fetchBinary(sheetUrl)
            local sheetInfo = sheetBytes and AnimationSystem.ParsePngInfo(sheetBytes) or nil
            local sheetAsset = GetAsset(sheetUrl, sheetBytes)

            if gifInfo and sheetInfo and sheetAsset and sheetAsset ~= "" and not sheetAsset:find("^https?://") then
                local frameW = gifInfo.width
                local frameH = gifInfo.height
                local cols = math.max(1, math.floor(sheetInfo.width / frameW + 0.0001))
                local rows = math.max(1, math.floor(sheetInfo.height / frameH + 0.0001))
                local maxFrames = cols * rows
                local frames = math.min(gifInfo.frames or maxFrames, maxFrames)
                local fps = (gifInfo.avgDelayCs and gifInfo.avgDelayCs > 0) and (100 / gifInfo.avgDelayCs) or 10

                local resizedW, resizedH = estimateRobloxResizedSize(sheetInfo.width, sheetInfo.height)
                local scaleX = resizedW / sheetInfo.width
                local scaleY = resizedH / sheetInfo.height
                local adjFrameW = frameW * scaleX
                local adjFrameH = frameH * scaleY

                local spriteData = {
                    sprite = sheetAsset,
                    frames = frames,
                    frameW = adjFrameW,
                    frameH = adjFrameH,
                    cols = cols,
                    rows = rows,
                    sheetW = resizedW,
                    sheetH = resizedH,
                    gifInfo = gifInfo
                }

                local newMeta = {
                    Enabled = true,
                    FrameWidth = frameW,
                    FrameHeight = frameH,
                    FPS = math.floor(fps + 0.5),
                    Frames = frames,
                    Cols = cols,
                    Rows = rows,
                    SheetWidth = sheetInfo.width,
                    SheetHeight = sheetInfo.height,
                    GifUrl = gifUrl,
                    SheetUrl = sheetUrl
                }
                wheel.Animation = newMeta
                AnimationSystem.Cache[cacheKey] = newMeta
                if AnimationSystem.currentThemeName and AnimationSystem.currentThemeName ~= "Default" then
                    SaveThemes(themes)
                end

                AnimationSystem.SetImageMode(bgImg, true)
                AnimationSystem.StartGif(bgImg, spriteData)
                return
            else
                AnimationSystem.StopGif()
                AnimationSystem.SetImageMode(bgImg, isCustomBg)
                local fallback = GetAsset(sheetUrl, sheetBytes)
                if fallback and fallback ~= "" and not fallback:find("^https?://") then
                    bgImg.Image = fallback
                else
                    bgImg.Image = DEFAULT_WHEEL_BG
                end
                bgImg.ImageRectSize = Vector2.new(0, 0)
                bgImg.ImageRectOffset = Vector2.new(0, 0)
            end
        end)
        return
    end
 
    AnimationSystem.StopGif()
    AnimationSystem.SetImageMode(bgImg, isCustomBg)
    bgImg.Image = GetAsset(targetUrl)
    bgImg.ImageRectSize = Vector2.new(0, 0)
    bgImg.ImageRectOffset = Vector2.new(0, 0)
end

function ApplyTheme(themeData)
    if State.isApplyingTheme then return end
    if not themeData then
        warn("Aphelion | ApplyTheme: themeData is nil. Falling back to Default.")
        themeData = themes and themes["Default"] or nil
        if not themeData then return end
    end
    
    State.isApplyingTheme = true
    
    local ok, err = pcall(function()
        if themeData.Background then
            State.EmoteTheme = {
                Background = TableToColor(themeData.Background),
                Accent = TableToColor(themeData.Accent or {0, 255, 150}),
                ImageColor = TableToColor(themeData.ImageColor or {255, 255, 255}),
                Icons = themeData.Icons or {},
                IconColors = themeData.IconColors or {},
                Wheel = themeData.Wheel or {}
            }
            
            local function getIconColor(key)
                if State.EmoteTheme.IconColors and State.EmoteTheme.IconColors[key] then
                    return TableToColor(State.EmoteTheme.IconColors[key])
                end
                return State.EmoteTheme.ImageColor 
            end
            
            State.favoriteIconId = GetAsset(State.EmoteTheme.Icons.Favorite)
            State.notFavoriteIconId = GetAsset(State.EmoteTheme.Icons.NotFavorite)
            
            updateGUIColors()
            
            if UI._1left then UI._1left.Image = GetAsset(State.EmoteTheme.Icons.Left); UI._1left.ImageColor3 = getIconColor("Left") end
            if UI._9right then UI._9right.Image = GetAsset(State.EmoteTheme.Icons.Right); UI._9right.ImageColor3 = getIconColor("Right") end
            if UI.EmoteWalkButton then 
                UI.EmoteWalkButton.ImageColor3 = getIconColor("Walk") 
                ApplyFreezeButtonVisual()
            end
            if UI.SpeedEmote then UI.SpeedEmote.Image = GetAsset(State.EmoteTheme.Icons.Speed); UI.SpeedEmote.ImageColor3 = getIconColor("Speed") end
            if UI.Changepage then UI.Changepage.Image = GetAsset(State.EmoteTheme.Icons.Page); UI.Changepage.ImageColor3 = getIconColor("Page") end
            if UI.Reload then UI.Reload.Image = GetAsset(State.EmoteTheme.Icons.Reload); UI.Reload.ImageColor3 = getIconColor("Reload") end
            
            if UI.Favorite then ApplyFavoriteButtonVisual() end 

            
            if UI.Background and UI.Background.Main then UI.Background.Main.SetValue(State.EmoteTheme.Background) end
            
            for key, comp in pairs(UIElements.Icons) do
                local iconVal = State.EmoteTheme.Icons[key] or ""
                local specificColor = State.EmoteTheme.IconColors and State.EmoteTheme.IconColors[key]
                local colorVal
                
                if specificColor then
                    colorVal = TableToColor(specificColor)
                else
                    colorVal = State.EmoteTheme.ImageColor 
                end
                
                if comp then comp.SetValue(iconVal, colorVal) end
            end

            for name, data in pairs(themes) do
                if data == themeData then
                    AnimationSystem.currentThemeName = name
                    break
                end
            end

            local function applyWheel()
                pcall(function()
                    local coreGui = game:GetService("CoreGui")
                    local robloxGui = coreGui:FindFirstChild("RobloxGui")
                    if not robloxGui then return end
                    local emotesMenu = robloxGui:FindFirstChild("EmotesMenu")
                    if not emotesMenu then return end
                    local children = emotesMenu:FindFirstChild("Children")
                    local main = children and children:FindFirstChild("Main")
                    local emotesWheel = main and main:FindFirstChild("EmotesWheel")
                    local back = emotesWheel and emotesWheel:FindFirstChild("Back")
                    local root = back and back:FindFirstChild("Background")
                    if not root then return end
                    
                    local wheel = State.EmoteTheme.Wheel
                    if not wheel then return end

                    local function getAsset(id)
                        return GetAsset(id)
                    end

                    local bgImg = root:FindFirstChild("BackgroundImage")
                    if bgImg then
                        ApplyWheelBackgroundImage(bgImg, wheel)
                        bgImg.ImageColor3 = TableToColor(wheel.BackgroundImageColor or {255,255,255})
                    end

                    local gradContainer = root:FindFirstChild("BackgroundGradient")
                    local selectionGrad = gradContainer and gradContainer:FindFirstChild("SelectionGradient")
                    local grad = selectionGrad and selectionGrad:FindFirstChild("SelectedGradient")
                    if grad then
                        grad.Image = getAsset(wheel.SelectionGradient)
                        grad.ImageColor3 = TableToColor(wheel.SelectionGradientColor or {255,255,255})
                    end

                    local selection = root:FindFirstChild("Selection")
                    local selectionEffect = selection and selection:FindFirstChild("SelectionEffect")
                    local line = selectionEffect and selectionEffect:FindFirstChild("SelectedLine")
                    if line then
                        line.Image = getAsset(wheel.SelectionLine)
                        line.ImageColor3 = TableToColor(wheel.SelectionLineColor or {255,255,255})
                    end
                end)
            end
            applyWheel()

            for key, comp in pairs(UIElements.Wheel) do
                local imgVal = State.EmoteTheme.Wheel[key] or ""
                local colorVal = TableToColor(State.EmoteTheme.Wheel[key.."Color"] or {255, 255, 255})
                if comp then comp.SetValue(imgVal, colorVal) end
            end
        end
    end)
    
    State.isApplyingTheme = false
    
    if not ok then
        warn("Aphelion | ApplyTheme error: " .. tostring(err))
    end
end

checkEmotesMenuExists = function()
    local coreGui = game:GetService("CoreGui")
    local robloxGui = coreGui:FindFirstChild("RobloxGui")
    if not robloxGui then
        return false
    end

    local emotesMenu = robloxGui:FindFirstChild("EmotesMenu")
    if not emotesMenu then
        return false
    end

    local children = emotesMenu:FindFirstChild("Children")
    if not children then
        return false
    end

    local main = children:FindFirstChild("Main")
    if not main then
        return false
    end

    local emotesWheel = main:FindFirstChild("EmotesWheel")
    if not emotesWheel then
        return false
    end

    return true, emotesWheel
end

task.spawn(function()
    local attempts = 0
    while attempts < 30 do
        local exists, emotesWheel = checkEmotesMenuExists()
        if exists and emotesWheel then
            ApplyTheme(themes[currentThemeName])
            
            emotesWheel:GetPropertyChangedSignal("Visible"):Connect(function()
                if emotesWheel.Visible then
                    task.wait(0.05)
                    ApplyTheme(themes[currentThemeName])
                end
            end)
            break
        end
        attempts = attempts + 1
        task.wait(1)
    end
end)

themeDropdown = SettingsLib.AddDropdown(ThemeTab, "Select Theme", GetNames(), currentThemeName, function(v)
    currentThemeName = v
    Config.SelectedTheme = v
    SaveConfig()
    if themes[v] then
        SaveThemes(themes) 
        task.wait(0.1)
        ApplyTheme(themes[v])
    end
end)
if themeDropdown and themeDropdown.Button and themeDropdown.Button.Parent and themeDropdown.Button.Parent.Parent then
   themeDropdown.Button.Parent.Parent.LayoutOrder = 0
end

local BtnItem = SettingsLib.AddItem(ThemeTab, "Theme Management", "Manage your themes")
BtnItem.LayoutOrder = 1 
BtnItem.BackgroundColor3 = Color3.fromRGB(35, 38, 42)
BtnItem.Size = UDim2.new(0.95, 0, 0, 70) 

for _, v in pairs(BtnItem:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end

local ManagementContainer = Instance.new("Frame")
ManagementContainer.Parent = BtnItem
ManagementContainer.BackgroundTransparency = 1
ManagementContainer.Size = UDim2.new(1, 0, 1, 0)

local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.Padding = UDim.new(0, 15)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Parent = ManagementContainer

local BtnRow = ManagementContainer 

function CreatePopup(title, size)
    local panel = Instance.new("Frame")
    panel.Size = size or UDim2.fromOffset(280, 140)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromHex("18191c")
    panel.ZIndex = 2000
    panel.Parent = SettingsLib.UI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Parent = panel
    stroke.Color = (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5

    local lbl = Instance.new("TextLabel")
    lbl.Parent = panel
    lbl.Size = UDim2.new(1, 0, 0, 35)
    lbl.BackgroundTransparency = 1
    lbl.Text = title:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.new(1,1,1)
    
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Parent = panel
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 0, 0, 35)
    content.Size = UDim2.new(1, 0, 1, -35)
    
    return panel, content
end

function CreateInput(parent, placeholder, text, isMulti)
    local box = Instance.new("TextBox")
    box.Size = isMulti and UDim2.new(0.9, 0, 0, 100) or UDim2.new(0.9, 0, 0, 35)
    box.Position = UDim2.new(0.05, 0, 0, 5)
    box.BackgroundColor3 = Color3.fromRGB(35, 38, 41)
    box.TextColor3 = Color3.new(1,1,1)
    box.PlaceholderText = placeholder or ""
    box.Text = text or ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.MultiLine = isMulti
    box.TextWrapped = isMulti
    box.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box
    
    return box
end

function CreateButton(parent, text, color, pos, size)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0.4, 0, 0, 32)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = (color.R + color.G + color.B < 1.5) and Color3.new(1,1,1) or Color3.new(0,0,0)
    btn.TextSize = 12
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    return btn
end

SettingsLib.AddIconButton(BtnRow, "108445456753346", function()
    local popup, content = CreatePopup("Create Theme")
    local In = CreateInput(content, "Theme Name...")
    
    local Save = CreateButton(content, "SAVE", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not themes[In.Text] then
            themes[In.Text] = DeepCopy(themes[currentThemeName])
            if not themes[In.Text].IconColors then themes[In.Text].IconColors = {} end
            table.insert(themes.Order, In.Text)
            
            table.sort(themes.Order, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a:lower() < b:lower()
            end)
            
            SaveThemes(themes)
            currentThemeName = In.Text
            themeDropdown.Refresh(GetNames())
            themeDropdown.Button.Text = currentThemeName .. "  ▼"
            ApplyTheme(themes[currentThemeName])
            popup:Destroy()
        end
    end)
    
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(BtnRow, "71829270056766", function()
    if currentThemeName ~= "Default" then
        local idx = table.find(themes.Order, currentThemeName)
        if idx then table.remove(themes.Order, idx) end
        
        themes[currentThemeName] = nil
        SaveThemes(themes)
        currentThemeName = "Default"
        themeDropdown.Refresh(GetNames())
        themeDropdown.Button.Text = "Default  ▼"
        ApplyTheme(themes["Default"])
    end
end)

SettingsLib.AddIconButton(BtnRow, "117761881427472", function()
    if currentThemeName == "Default" then return end
    
    local popup, content = CreatePopup("Rename Theme")
    local In = CreateInput(content, "New Name...", currentThemeName)
    
    local Save = CreateButton(content, "RENAME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not themes[In.Text] then
            local idx = table.find(themes.Order, currentThemeName)
            if idx then themes.Order[idx] = In.Text end
            
            themes[In.Text] = themes[currentThemeName]
            themes[currentThemeName] = nil
            currentThemeName = In.Text
            SaveThemes(themes)
            themeDropdown.Refresh(GetNames())
            themeDropdown.Button.Text = currentThemeName .. "  ▼"
            popup:Destroy()
        end
    end)
    
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(BtnRow, "78317476576895", function()
    local popup, content = CreatePopup("Import Theme", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Theme JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    
    local imp = CreateButton(content, "IMPORT THEME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" and d.name then
            if d.name == "Default" then
                getgenv().Notify({Title = "Error", Content = "Cannot overwrite 'Default' theme.", Duration = 3})
                return
            end
            if not themes[d.name] then
                table.insert(themes.Order, d.name)
            end
            themes[d.name] = d.data
            SaveThemes(themes)
            themeDropdown.Refresh(GetNames())
            popup:Destroy()
        else
            getgenv().Notify({Title = "Error", Content = "Invalid JSON Format!", Duration = 3})
        end
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(BtnRow, "107588515524752", function()
    local exportData = { name = currentThemeName, data = themes[currentThemeName] }
    local json = HttpService:JSONEncode(exportData)
    
    local popup, content = CreatePopup("Export Theme", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "", json, true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    box.TextEditable = false
    
    local copy = CreateButton(content, "COPY TO CLIPBOARD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

    copy.MouseButton1Click:Connect(function()
        setclipboard(json)
        copy.Text = "COPIED!"
        task.delay(1, function() copy.Text = "COPY TO CLIPBOARD" end)
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)


function SmartUpdate(key, subkey, val)
    if currentThemeName == "Default" then
        getgenv().Notify({Title = "Theme", Content = "Cannot modify Default theme. Create a new one!", Duration = 2})
        return
    end

    if themes[currentThemeName] then
        if not themes[currentThemeName][key] then themes[currentThemeName][key] = {} end
        
        if subkey then
            themes[currentThemeName][key][subkey] = val
        else
            themes[currentThemeName][key] = val
        end
        SaveThemes(themes)
        ApplyTheme(themes[currentThemeName])
    end
end

local WheelFolder = SettingsLib.AddFolder(ThemeTab, "Wheel Settings")
WheelFolder.Parent.LayoutOrder = 1.1

function AddWheelInput(title, wheelKey)
    local initialData = themes["Default"].Wheel[wheelKey]
    local initialColor = TableToColor(themes["Default"].Wheel[wheelKey.."Color"])
    
    local current = (themes[currentThemeName].Wheel and themes[currentThemeName].Wheel[wheelKey]) or initialData
    local currentColor = TableToColor((themes[currentThemeName].Wheel and themes[currentThemeName].Wheel[wheelKey.."Color"]) or themes["Default"].Wheel[wheelKey.."Color"])
    
    local comp = SettingsLib.AddAssetColor(WheelFolder, title, "Asset ID...", current, currentColor, function(text, color)
        if currentThemeName == "Default" then
            getgenv().Notify({Title = "Theme", Content = "Cannot modify Default theme!", Duration = 2})
            return
        end
        
        if themes[currentThemeName] then
            if not themes[currentThemeName].Wheel then themes[currentThemeName].Wheel = {} end
            themes[currentThemeName].Wheel[wheelKey] = text
            themes[currentThemeName].Wheel[wheelKey.."Color"] = ColorToTable(color)
            
            SaveThemes(themes)
            ApplyTheme(themes[currentThemeName])
        end
    end)
    UIElements.Wheel[wheelKey] = comp

    local resetBtn = SettingsLib:Create("ImageButton", {
        Parent = comp.Item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -120, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://127493377027615",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    
    resetBtn.MouseButton1Click:Connect(function()
        if currentThemeName == "Default" then return end
        comp.SetValue(initialData, initialColor)
        if themes[currentThemeName] then
            if not themes[currentThemeName].Wheel then themes[currentThemeName].Wheel = {} end
            themes[currentThemeName].Wheel[wheelKey] = initialData
            themes[currentThemeName].Wheel[wheelKey.."Color"] = ColorToTable(initialColor)
            SaveThemes(themes)
            ApplyTheme(themes[currentThemeName])
        end
    end)
end

AddWheelInput("Wheel Background", "BackgroundImage")
AddWheelInput("Selection Gradient", "SelectionGradient")
AddWheelInput("Selection Line", "SelectionLine")

local BackgroundFolder = SettingsLib.AddFolder(ThemeTab, "Background Settings")
BackgroundFolder.Parent.LayoutOrder = 2
UIElements.Background.Main = SettingsLib.AddColorPicker(BackgroundFolder, "Main Background", TableToColor(themes[currentThemeName].Background), function(c)
    SmartUpdate("Background", nil, ColorToTable(c))
end)

local IconSettingsFolder = SettingsLib.AddFolder(ThemeTab, "Icon Settings")
IconSettingsFolder.Parent.LayoutOrder = 3

function AddAssetInput(title, iconKey)
    local current = (themes[currentThemeName].Icons and themes[currentThemeName].Icons[iconKey]) or ""
    local defaultText = (themes["Default"].Icons and themes["Default"].Icons[iconKey]) or ""
    
    local currentColor = Color3.new(1,1,1)
    if themes[currentThemeName].IconColors and themes[currentThemeName].IconColors[iconKey] then
        currentColor = TableToColor(themes[currentThemeName].IconColors[iconKey])
    elseif themes[currentThemeName].ImageColor then
        currentColor = TableToColor(themes[currentThemeName].ImageColor)
    end
    
    local defaultColor = Color3.new(1,1,1)
    if themes["Default"].IconColors and themes["Default"].IconColors[iconKey] then
        defaultColor = TableToColor(themes["Default"].IconColors[iconKey])
    elseif themes["Default"].ImageColor then
        defaultColor = TableToColor(themes["Default"].ImageColor)
    end
    
    local comp = SettingsLib.AddInputWithColor(IconSettingsFolder, title, "Asset ID...", defaultText, defaultColor, function(text, color)
        local s, err = pcall(function()
            if currentThemeName == "Default" then
                getgenv().Notify({Title = "Theme", Content = "Cannot modify Default theme!", Duration = 2})
                return
            end
            
            if themes[currentThemeName] then
                if not themes[currentThemeName].Icons then themes[currentThemeName].Icons = {} end
                if not themes[currentThemeName].IconColors then themes[currentThemeName].IconColors = {} end
                
                local cTable = ColorToTable(color)
                themes[currentThemeName].Icons[iconKey] = text
                themes[currentThemeName].IconColors[iconKey] = cTable
                
                SaveThemes(themes)
                ApplyTheme(themes[currentThemeName])
            end
        end)
        if not s then
            warn("Theme Save Error: " .. tostring(err))
            getgenv().Notify({Title = "Error", Content = "Failed to save color!", Duration = 3})
        end
    end)
    comp.SetValue(current, currentColor)
    UIElements.Icons[iconKey] = comp
end

AddAssetInput("Left Arrow", "Left")
AddAssetInput("Right Arrow", "Right")
AddAssetInput("Walk Icon", "Walk")
AddAssetInput("Speed Icon", "Speed")
AddAssetInput("Page Icon", "Page")
AddAssetInput("Reload Icon", "Reload")
AddAssetInput("Favorite (Star)", "Favorite")
AddAssetInput("Not Favorite", "NotFavorite")

State.exitCustomAnimationEditor = function()
    if not State.customAnimationEditorActive then return end
    State.customAnimationEditorActive = false
    State.customAnimationEditingKey = nil
    State.customAnimationEditingName = nil

    for _, conn in pairs(State.CustomAnimEditorConnections or {}) do
        pcall(function() conn:Disconnect() end)
    end
    State.CustomAnimEditorConnections = {}

    if State.CustomAnimOverlay and State.CustomAnimOverlay.Parent then 
        State.CustomAnimOverlay:Destroy() 
    end
    State.CustomAnimOverlay = nil

    if State.CustomAnimForceVisibleConn then 
        State.CustomAnimForceVisibleConn:Disconnect()
        State.CustomAnimForceVisibleConn = nil 
    end

    if UI.Search then UI.Search.TextEditable = true; UI.Search.Active = true end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = true; UI.SpeedBox.Active = true end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = true; UI._2Routenumber.Active = true end
    
    pcall(function() game:GetService("GuiService"):SetEmotesMenuOpen(false) end)
    pcall(function() game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false end)

    local main = getSettingsMainFrame()
    if main then main.Visible = true end
    if syncToggleVisibility then syncToggleVisibility() end

    if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end

    if State.currentMode ~= "animation" then
        State.currentMode = "animation"
        State.suppressSearch = true
        if UI.Search then UI.Search.Text = State.animationSearchTerm end
        State.suppressSearch = false
        if State.animationSearchTerm ~= "" and searchAnimations then
            searchAnimations(State.animationSearchTerm)
        end
        State.currentPage = State.savedAnimPage
        State.totalPages = calculateTotalPages()
        updatePageDisplay()
        updateEmotes()
        if updateScriptPriorityOverlay then updateScriptPriorityOverlay() end
        State.animationMonitorToken = State.animationMonitorToken + 1
        local token = State.animationMonitorToken
        State.isMonitoringClicks = true
        if monitorAnimations then
            task.spawn(function() monitorAnimations(token) end)
        end
    end
end

State.enterCustomAnimationEditor = function(category, animName)
    if State.customAnimationEditorActive then return end
    if State.currentCustomAnimationName == "Default" then
        getgenv().Notify({ Title = "Aphelion | Error", Content = "Cannot edit Default Animation set. Create a new one!", Duration = 3 })
        return
    end

    State.customAnimationEditorActive = true
    State.customAnimationEditingKey = category
    State.customAnimationEditingName = animName
    
    if State.currentMode ~= "animation" then
        State.currentMode = "animation"
        State.suppressSearch = true
        if UI.Search then UI.Search.Text = State.animationSearchTerm end
        State.suppressSearch = false
        State.currentPage = State.savedAnimPage
        State.totalPages = calculateTotalPages()
        updatePageDisplay()
        updateEmotes()
        if updateScriptPriorityOverlay then updateScriptPriorityOverlay() end
        State.animationMonitorToken = State.animationMonitorToken + 1
        local token = State.animationMonitorToken
        State.isMonitoringClicks = true
        if monitorAnimations then
            task.spawn(function()
                monitorAnimations(token)
            end)
        end
        
        local beforeVersion = State.animationCacheVersion
        task.spawn(function()
            if fetchAllAnimations then
                fetchAllAnimations()
            else
                return
            end
            if State.currentMode ~= "animation" then return end
            if State.animationCacheVersion ~= beforeVersion then
                State.suppressSearch = true
                if UI.Search then UI.Search.Text = State.animationSearchTerm end
                State.suppressSearch = false
                if State.animationSearchTerm ~= "" and searchAnimations then
                    searchAnimations(State.animationSearchTerm)
                end
                State.currentPage = State.savedAnimPage
                State.totalPages = calculateTotalPages()
                updatePageDisplay()
                updateEmotes()
                if updateScriptPriorityOverlay then updateScriptPriorityOverlay() end
            end
        end)
    end

    GuiService:SetEmotesMenuOpen(false)
    task.wait(0.15)

    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then State.customAnimationEditorActive = false; return end
    emotesWheel.Visible = true

    State.CustomAnimForceVisibleConn = RunService.Heartbeat:Connect(function()
        if not State.customAnimationEditorActive then return end
        pcall(function()
            local _, ew = checkEmotesMenuExists()
            if ew then ew.Visible = true end
        end)
    end)

    local main = getSettingsMainFrame()
    if main then main.Visible = false end
    if syncToggleVisibility then syncToggleVisibility() end

    local overlay = Instance.new("Frame")
    overlay.Name = "CustomAnimOverlay"
    overlay.Parent = SettingsLib.UI
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 6000
    overlay.Active = false
    State.CustomAnimOverlay = overlay

    local bc = Instance.new("Frame")
    bc.Parent = overlay
    bc.BackgroundTransparency = 1
    bc.AnchorPoint = Vector2.new(1, 0)
    bc.Position = UDim2.new(1, -10, 0, 10)
    bc.Size = UDim2.fromOffset(42, 42)
    bc.ZIndex = 6000

    local backBtn = Instance.new("ImageButton")
    backBtn.Name = "CustomAnimBackBtn"
    backBtn.Size = UDim2.fromOffset(42, 42)
    backBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backBtn.BackgroundTransparency = 0.4
    backBtn.Image = "rbxassetid://79024388644722"
    backBtn.ZIndex = 6001
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = backBtn
    
    backBtn.Parent = bc
    
    State.CustomAnimEditorConnections = State.CustomAnimEditorConnections or {}
    table.insert(State.CustomAnimEditorConnections, backBtn.MouseButton1Click:Connect(function()
        State.exitCustomAnimationEditor()
    end))

    if UI._2Routenumber then UI._2Routenumber.TextEditable = false; UI._2Routenumber.Active = false; pcall(function() UI._2Routenumber:ReleaseFocus() end) end

    getgenv().Notify({ Title = "Aphelion | Animation Editor", Content = "🖱️ Select an animation from the wheel to set for " .. animName, Duration = 5 })
end

State.CustomAnimTab = SettingsLib.CreateTab("Animation", 4)
State.CustomAnimDropdown = SettingsLib.AddDropdown(State.CustomAnimTab, "Select Animation", State.CustomAnimations.Order, State.currentCustomAnimationName, function(v)
    State.currentCustomAnimationName = v
    State.CustomAnimations.Selected = v
    State.SaveCustomAnimations(State.CustomAnimations)
    if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
    if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
    if refreshCustomAnimationState then refreshCustomAnimationState(false) end
end)
if State.CustomAnimDropdown and State.CustomAnimDropdown.Button and State.CustomAnimDropdown.Button.Parent and State.CustomAnimDropdown.Button.Parent.Parent then
   State.CustomAnimDropdown.Button.Parent.Parent.LayoutOrder = 0
end

local CustomAnimBtnItem = SettingsLib.AddItem(State.CustomAnimTab, "Animation Management", "Manage your animations")
CustomAnimBtnItem.LayoutOrder = 1 
CustomAnimBtnItem.BackgroundColor3 = Color3.fromRGB(35, 38, 42)
CustomAnimBtnItem.Size = UDim2.new(0.95, 0, 0, 70) 
for _, v in pairs(CustomAnimBtnItem:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end

local CustomAnimMgtContainer = Instance.new("Frame")
CustomAnimMgtContainer.Parent = CustomAnimBtnItem
CustomAnimMgtContainer.BackgroundTransparency = 1
CustomAnimMgtContainer.Size = UDim2.new(1, 0, 1, 0)

local CustomAnimLayout = Instance.new("UIListLayout")
CustomAnimLayout.FillDirection = Enum.FillDirection.Horizontal
CustomAnimLayout.Padding = UDim.new(0, 15)
CustomAnimLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
CustomAnimLayout.VerticalAlignment = Enum.VerticalAlignment.Center
CustomAnimLayout.Parent = CustomAnimMgtContainer

function NormalizeCustomAnimationData(animData)
    local defaultAnim = {
        idle = { Animation1 = 0, Animation2 = 0 },
        walk = { WalkAnim = 0 },
        run = { RunAnim = 0 },
        jump = { JumpAnim = 0 },
        fall = { FallAnim = 0 },
        swimidle = { SwimIdle = 0 },
        swim = { Swim = 0 },
        __meta = { IconImage = DEFAULT_IDLE_ICON_ID, IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) }
    }
    
    local result = { Sets = { Default = DeepCopy(defaultAnim) }, Order = {"Default"}, Selected = "Default" }
    if type(animData) ~= "table" then return result end
    
    local setsTable = animData.Sets or animData
    if type(setsTable) == "table" then
        for name, data in pairs(setsTable) do
            if type(data) == "table" then
                if name == "Default" then
                    result.Sets.Default = data
                else
                    result.Sets[name] = data
                end
                data.__meta = data.__meta or {}
                if data.__meta.IconImage == nil then data.__meta.IconImage = DEFAULT_IDLE_ICON_ID end
                if data.__meta.IconColor == nil then data.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) end
            end
        end
    end
    
    local order = animData.Order
    if type(order) == "table" then
        for _, name in ipairs(order) do
            if name ~= "Default" and result.Sets[name] then
                table.insert(result.Order, name)
            end
        end
    else
        for name, _ in pairs(result.Sets) do
            if name ~= "Default" then table.insert(result.Order, name) end
        end
    end
    
    local selected = animData.Selected
    if type(selected) == "string" and result.Sets[selected] then
        result.Selected = selected
    end
    
    return result
end

function MakeUniqueSetName(baseSets, desiredName)
    if not baseSets[desiredName] then return desiredName end
    local i = 2
    local candidate = desiredName .. " (Imported)"
    if not baseSets[candidate] then return candidate end
    while true do
        candidate = desiredName .. " (Imported " .. i .. ")"
        if not baseSets[candidate] then return candidate end
        i = i + 1
    end
end

SettingsLib.AddIconButton(CustomAnimMgtContainer, "108445456753346", function()
    local popup, content = CreatePopup("Create Animation")
    local In = CreateInput(content, "Animation Name...")
    
    local Save = CreateButton(content, "SAVE", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.CustomAnimations.Sets[In.Text] then
            local defaultAnim = {
                idle = { Animation1 = 0, Animation2 = 0 },
                walk = { WalkAnim = 0 },
                run = { RunAnim = 0 },
                jump = { JumpAnim = 0 },
                fall = { FallAnim = 0 },
                swimidle = { SwimIdle = 0 },
                swim = { Swim = 0 },
                __meta = { IconImage = DEFAULT_IDLE_ICON_ID, IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) }
            }
            State.CustomAnimations.Sets[In.Text] = defaultAnim
            table.insert(State.CustomAnimations.Order, In.Text)
            
            table.sort(State.CustomAnimations.Order, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a:lower() < b:lower()
            end)
            
            State.currentCustomAnimationName = In.Text
            State.CustomAnimations.Selected = In.Text
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.CustomAnimDropdown then
                State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
                State.CustomAnimDropdown.Button.Text = State.currentCustomAnimationName .. "  ▼"
            end
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(false) end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "71829270056766", function()
    if State.currentCustomAnimationName ~= "Default" then
        local idx = table.find(State.CustomAnimations.Order, State.currentCustomAnimationName)
        if idx then table.remove(State.CustomAnimations.Order, idx) end
        
        State.CustomAnimations.Sets[State.currentCustomAnimationName] = nil
        State.currentCustomAnimationName = "Default"
        State.CustomAnimations.Selected = "Default"
        State.SaveCustomAnimations(State.CustomAnimations)
        if State.CustomAnimDropdown then
            State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
            State.CustomAnimDropdown.Button.Text = "Default  ▼"
        end
        if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
        if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
        if refreshCustomAnimationState then refreshCustomAnimationState(false) end
    end
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "117761881427472", function()
    if State.currentCustomAnimationName == "Default" then return end
    
    local popup, content = CreatePopup("Rename Animation")
    local In = CreateInput(content, "New Name...", State.currentCustomAnimationName)
    
    local Save = CreateButton(content, "RENAME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.CustomAnimations.Sets[In.Text] then
            local idx = table.find(State.CustomAnimations.Order, State.currentCustomAnimationName)
            if idx then State.CustomAnimations.Order[idx] = In.Text end
            
            State.CustomAnimations.Sets[In.Text] = State.CustomAnimations.Sets[State.currentCustomAnimationName]
            State.CustomAnimations.Sets[State.currentCustomAnimationName] = nil
            State.currentCustomAnimationName = In.Text
            State.CustomAnimations.Selected = In.Text
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.CustomAnimDropdown then
                State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
                State.CustomAnimDropdown.Button.Text = State.currentCustomAnimationName .. "  ▼"
            end
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(false) end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "107588515524752", function()
    local currentSet = State.CustomAnimations.Sets[State.currentCustomAnimationName]
    local data = {
        Type = "CustomAnimationSet",
        Name = State.currentCustomAnimationName,
        Data = currentSet
    }
    local json = HttpService:JSONEncode(data)
    
    local popup, content = CreatePopup("Export Animations", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "", json, true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    box.TextEditable = false
    
    local copy = CreateButton(content, "COPY TO CLIPBOARD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    copy.MouseButton1Click:Connect(function()
        setclipboard(json)
        copy.Text = "COPIED!"
        task.delay(1, function() copy.Text = "COPY TO CLIPBOARD" end)
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "X"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "78317476576895", function()
    local popup, content = CreatePopup("Import Animations", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Animation JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    
    local imp = CreateButton(content, "IMPORT DATA", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" then
            if d.Type and d.Type ~= "CustomAnimationSet" then
                getgenv().Notify({ Title = "Error", Content = "Backup type mismatch!", Duration = 3 })
                return
            end
            if type(d.Data) ~= "table" then
                getgenv().Notify({ Title = "Error", Content = "Invalid JSON", Duration = 3 })
                return
            end
            State.CustomAnimations = NormalizeCustomAnimationData(State.CustomAnimations)
            local sourceName = d.Name or "Imported"
            local targetName = MakeUniqueSetName(State.CustomAnimations.Sets, sourceName)
            local imported = d.Data
            imported.__meta = imported.__meta or {}
            if imported.__meta.IconImage == nil then imported.__meta.IconImage = DEFAULT_IDLE_ICON_ID end
            if imported.__meta.IconColor == nil then imported.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) end
            State.CustomAnimations.Sets[targetName] = imported
            table.insert(State.CustomAnimations.Order, targetName)
            State.currentCustomAnimationName = targetName
            State.CustomAnimations.Selected = targetName
            
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.CustomAnimDropdown then
                State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
                State.CustomAnimDropdown.Button.Text = State.currentCustomAnimationName .. "  ▼"
            end
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(false) end
            popup:Destroy()
            getgenv().Notify({ Title = "Aphelion | Animation", Content = "✅ Imported custom animations", Duration = 3 })
        else
            getgenv().Notify({ Title = "Error", Content = "Invalid JSON", Duration = 3 })
        end
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "x"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

function GetCurrentCustomAnimMeta()
    local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
    if not set then return nil end
    set.__meta = set.__meta or {}
    if set.__meta.IconImage == nil then set.__meta.IconImage = DEFAULT_IDLE_ICON_ID end
    if set.__meta.IconColor == nil then set.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) end
    return set.__meta
end

State.ApplyCustomAnimIconUI = function()
    if not State.CustomAnimIconControl or not State.CustomAnimIconControl.SetValue then return end
    local meta = GetCurrentCustomAnimMeta()
    if not meta then return end
    State.CustomAnimIconControl.SetValue(meta.IconImage or DEFAULT_IDLE_ICON_ID, TableToColor(meta.IconColor or ColorToTable(DEFAULT_IDLE_ICON_COLOR)))
end

do
    local meta = GetCurrentCustomAnimMeta() or {}
    local currentImage = meta.IconImage or DEFAULT_IDLE_ICON_ID
    local currentColor = TableToColor(meta.IconColor or ColorToTable(DEFAULT_IDLE_ICON_COLOR))
    State.CustomAnimIconControl = SettingsLib.AddAssetColor(State.CustomAnimTab, "Icon", "Asset ID or URL...", currentImage, currentColor, function(text, color)
        local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
        if not set then return end
        set.__meta = set.__meta or {}
        set.__meta.IconImage = text
        set.__meta.IconColor = ColorToTable(color)
        State.SaveCustomAnimations(State.CustomAnimations)
        if refreshCustomAnimationState then refreshCustomAnimationState(false) end
    end)
    if State.CustomAnimIconControl and State.CustomAnimIconControl.Item then
        State.CustomAnimIconControl.Item.LayoutOrder = 1.5
    end
    
    local resetBtn = SettingsLib:Create("ImageButton", {
        Parent = State.CustomAnimIconControl.Item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -120, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://127493377027615",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    resetBtn.MouseButton1Click:Connect(function()
        local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
        if not set then return end
        set.__meta = set.__meta or {}
        set.__meta.IconImage = DEFAULT_IDLE_ICON_ID
        set.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR)
        State.SaveCustomAnimations(State.CustomAnimations)
        if State.CustomAnimIconControl and State.CustomAnimIconControl.SetValue then
            State.CustomAnimIconControl.SetValue(DEFAULT_IDLE_ICON_ID, DEFAULT_IDLE_ICON_COLOR)
        end
        if refreshCustomAnimationState then refreshCustomAnimationState(false) end
    end)
end

State.CustomAnimUIElems = {}
function CreateAnimSetUI(folder, cat, name)
    local item = SettingsLib.AddItem(folder, cat .. " - " .. name, "Current ID: 0")
    
    local resetBtn = SettingsLib:Create("ImageButton", {
        Parent = item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://127493377027615",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    
    local editBtn = SettingsLib:Create("ImageButton", {
        Parent = item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://117761881427472",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    
    resetBtn.MouseButton1Click:Connect(function()
        if State.currentCustomAnimationName == "Default" then return end
        if State.CustomAnimations.Sets[State.currentCustomAnimationName] then
            if not State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] then
                State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] = {}
            end
            State.CustomAnimations.Sets[State.currentCustomAnimationName][cat][name] = 0
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(true) end
        end
    end)
    
    editBtn.MouseButton1Click:Connect(function()
        State.enterCustomAnimationEditor(cat, name)
    end)
    
    table.insert(State.CustomAnimUIElems, { item = item, cat = cat, name = name })
end

State.CustomAnimFolders = {}
State.CustomAnimFolders.Idle = SettingsLib.AddFolder(State.CustomAnimTab, "Idle Animations")
State.CustomAnimFolders.Idle.Parent.LayoutOrder = 2
CreateAnimSetUI(State.CustomAnimFolders.Idle, "idle", "Animation1")
CreateAnimSetUI(State.CustomAnimFolders.Idle, "idle", "Animation2")

State.CustomAnimFolders.Movement = SettingsLib.AddFolder(State.CustomAnimTab, "Movement Animations")
State.CustomAnimFolders.Movement.Parent.LayoutOrder = 3
CreateAnimSetUI(State.CustomAnimFolders.Movement, "walk", "WalkAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "run", "RunAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "jump", "JumpAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "fall", "FallAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "climb", "ClimbAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "swimidle", "SwimIdle")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "swim", "Swim")

State.RefreshCustomAnimUI = function()
    local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
    if not set then return end
    
    for _, elem in pairs(State.CustomAnimUIElems) do
        local desc = elem.item:FindFirstChild("Desc")
        if desc then
            local val = set[elem.cat] and set[elem.cat][elem.name] or 0
            desc.Text = "Current ID: " .. tostring(val)
        end
    end
end
State.RefreshCustomAnimUI()

State.PageTab = SettingsLib.CreateTab("Page", 5)

function GetEmotePageNames()
    return State.EmotePages.Order
end

SettingsLib.AddItem(State.PageTab, "Page Profiles", "Pages allow you to save different favorite sets. Switch pages to quickly change your favorite wheel loadout.")

SettingsLib.AddItem(State.PageTab, "Emote Profiles", "Manage your favorite emote profiles")

State.PageDropdown = SettingsLib.AddDropdown(State.PageTab, "Select Emote Page", GetEmotePageNames(), State.currentEmotePageName, function(v)
    SwitchEmotePage(v)
    State.SaveEmotePages(State.EmotePages)
end)

local EmotePageMgtItem = SettingsLib.AddItem(State.PageTab, "Emote Page Management", " ")
EmotePageMgtItem.BackgroundColor3 = Color3.fromRGB(35, 38, 42)
EmotePageMgtItem.Size = UDim2.new(0.95, 0, 0, 70)
for _, v in pairs(EmotePageMgtItem:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end

local EmotePageMgtContainer = Instance.new("Frame")
EmotePageMgtContainer.Parent = EmotePageMgtItem
EmotePageMgtContainer.BackgroundTransparency = 1
EmotePageMgtContainer.Size = UDim2.new(1, 0, 1, 0)

local EmotePageLayout = Instance.new("UIListLayout")
EmotePageLayout.FillDirection = Enum.FillDirection.Horizontal
EmotePageLayout.Padding = UDim.new(0, 15)
EmotePageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
EmotePageLayout.VerticalAlignment = Enum.VerticalAlignment.Center
EmotePageLayout.Parent = EmotePageMgtContainer

SettingsLib.AddIconButton(EmotePageMgtContainer, "108445456753346", function()
    local popup, content = CreatePopup("Create Emote Page")
    local In = CreateInput(content, "Page Name...")
    local Save = CreateButton(content, "SAVE", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.EmotePages.Sets[In.Text] then
            State.EmotePages.Sets[In.Text] = {}
            table.insert(State.EmotePages.Order, In.Text)
            table.sort(State.EmotePages.Order, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a:lower() < b:lower()
            end)
            State.SaveEmotePages(State.EmotePages)
            if State.PageDropdown then State.PageDropdown.Refresh(GetEmotePageNames()) end
            SwitchEmotePage(In.Text)
            if State.PageDropdown then State.PageDropdown.Button.Text = State.currentEmotePageName .. "  ▼" end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "71829270056766", function()
    if State.currentEmotePageName ~= "Default" then
        local idx = table.find(State.EmotePages.Order, State.currentEmotePageName)
        if idx then table.remove(State.EmotePages.Order, idx) end
        State.EmotePages.Sets[State.currentEmotePageName] = nil
        State.currentEmotePageName = "Default"
        State.EmotePages.Selected = "Default"
        State.SaveEmotePages(State.EmotePages)
        if State.PageDropdown then
            State.PageDropdown.Refresh(GetEmotePageNames())
            State.PageDropdown.Button.Text = "Default  ▼"
        end
        SwitchEmotePage("Default")
    end
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "117761881427472", function()
    if State.currentEmotePageName == "Default" then return end
    local popup, content = CreatePopup("Rename Emote Page")
    local In = CreateInput(content, "New Name...", State.currentEmotePageName)
    local Save = CreateButton(content, "RENAME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.EmotePages.Sets[In.Text] then
            local idx = table.find(State.EmotePages.Order, State.currentEmotePageName)
            if idx then State.EmotePages.Order[idx] = In.Text end
            State.EmotePages.Sets[In.Text] = State.EmotePages.Sets[State.currentEmotePageName]
            State.EmotePages.Sets[State.currentEmotePageName] = nil
            State.currentEmotePageName = In.Text
            State.EmotePages.Selected = In.Text
            State.SaveEmotePages(State.EmotePages)
            if State.PageDropdown then
                State.PageDropdown.Refresh(GetEmotePageNames())
                State.PageDropdown.Button.Text = State.currentEmotePageName .. "  ▼"
            end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "107588515524752", function() 
    local currentSet = State.EmotePages.Sets[State.currentEmotePageName]
    local data = { Type = "EmotePageSet", Name = State.currentEmotePageName, Data = currentSet }
    local json = HttpService:JSONEncode(data)
    local popup, content = CreatePopup("Export Emote Page", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "", json, true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    box.TextEditable = false
    local copy = CreateButton(content, "COPY TO CLIPBOARD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    copy.MouseButton1Click:Connect(function()
        setclipboard(json)
        copy.Text = "COPIED!"
        task.delay(1, function() copy.Text = "COPY TO CLIPBOARD" end)
    end)
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "78317476576895", function() 
    local popup, content = CreatePopup("Import Emote Page", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Page JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    local imp = CreateButton(content, "IMPORT DATA", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" and d.Type == "EmotePageSet" and type(d.Data) == "table" then
            local targetName = MakeUniqueSetName(State.EmotePages.Sets, d.Name or "Imported")
            State.EmotePages.Sets[targetName] = d.Data
            table.insert(State.EmotePages.Order, targetName)
            State.currentEmotePageName = targetName
            State.EmotePages.Selected = targetName
            State.SaveEmotePages(State.EmotePages)
            if State.PageDropdown then
                State.PageDropdown.Refresh(GetEmotePageNames())
                State.PageDropdown.Button.Text = State.currentEmotePageName .. "  ▼"
            end
            SwitchEmotePage(targetName)
            popup:Destroy()
            getgenv().Notify({ Title = "Aphelion | Page", Content = "✅ Imported Emote page", Duration = 3 })
        else
            getgenv().Notify({ Title = "Error", Content = "Invalid Emote Page JSON", Duration = 3 })
        end
    end)
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddItem(State.PageTab, "Animation Profiles", "Manage your favorite animation profiles")


local BackupTab = SettingsLib.CreateTab("Backup", 6)

local BackupDesc = SettingsLib.AddItem(BackupTab, "What's included in a backup?", " ")
BackupDesc.LayoutOrder = 1
BackupDesc.Size = UDim2.new(0.95, 0, 0, 110)
for _, v in pairs(BackupDesc:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end
BackupDesc.BackgroundTransparency = 0
BackupDesc.BackgroundColor3 = Color3.fromRGB(35, 38, 42)

local BackupTitle = Instance.new("TextLabel")
BackupTitle.Parent = BackupDesc
BackupTitle.BackgroundTransparency = 1
BackupTitle.Position = UDim2.new(0, 12, 0, 6)
BackupTitle.Size = UDim2.new(1, -24, 0, 18)
BackupTitle.Font = Enum.Font.GothamBold
BackupTitle.Text = "What's included in a backup?"
BackupTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
BackupTitle.TextSize = 12
BackupTitle.TextXAlignment = Enum.TextXAlignment.Left

local DescList = Instance.new("Frame")
DescList.Parent = BackupDesc
DescList.BackgroundTransparency = 1
DescList.Position = UDim2.new(0, 12, 0, 28)
DescList.Size = UDim2.new(1, -24, 1, -28)

local LayoutDesc = Instance.new("UIListLayout")
LayoutDesc.Parent = DescList
LayoutDesc.Padding = UDim.new(0, 4)

function MakeDescLine(text)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = DescList
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 15)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.TextWrapped = true
    lbl.Font = Enum.Font.Gotham
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.RichText = true
end

MakeDescLine("<b>• Theme:</b> Saves custom themes")
MakeDescLine("<b>• Settings:</b> Saves HUD layout & values")
MakeDescLine("<b>• Favorite:</b> Saves favorite emotes/anims")
MakeDescLine("<b>• All:</b> Includes everything above")

local ExportItem = SettingsLib.AddItem(BackupTab, "Export Settings", "Save current settings to a file for sharing or later import.")
ExportItem.LayoutOrder = 2

local ExportBtnContainer = Instance.new("Frame")
ExportBtnContainer.Parent = ExportItem
ExportBtnContainer.BackgroundTransparency = 1
ExportBtnContainer.Size = UDim2.new(1, -24, 0, 60)

local expDesc = ExportItem:FindFirstChild("Desc")
if expDesc then
    expDesc.Size = UDim2.new(1, -24, 0, 0)
    local function updateExpPos()
        ExportBtnContainer.Position = UDim2.new(0, 12, 0, expDesc.Position.Y.Offset + expDesc.AbsoluteSize.Y + 12)
    end
    expDesc:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateExpPos)
    updateExpPos()
else
    ExportBtnContainer.Position = UDim2.new(0, 12, 0, 32)
end

local ExportLayout = Instance.new("UIGridLayout")
ExportLayout.CellSize = UDim2.new(0.48, 0, 0, 26)
ExportLayout.CellPadding = UDim2.new(0.04, 0, 0, 8)
ExportLayout.SortOrder = Enum.SortOrder.LayoutOrder
ExportLayout.Parent = ExportBtnContainer

function CreateExportBtn(text, color, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 11
    btn.Parent = ExportBtnContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

local btnColors = {
    dark = Color3.fromRGB(45, 48, 52),
    blue = Color3.fromRGB(88, 101, 242)
}

local BtnExportAll = CreateExportBtn("Export All Settings", btnColors.dark, 1)
local BtnExportThemes = CreateExportBtn("Export Themes", btnColors.blue, 2)
local BtnExportSettings = CreateExportBtn("Export Settings", btnColors.blue, 3)
local BtnExportFavorites = CreateExportBtn("Export Favorites", btnColors.blue, 4)

function GetFavoritesData()
    local favAnimsStr = "{}"
    if isfile and isfile(State.favoriteAnimationsFileName) then
        favAnimsStr = readfile(State.favoriteAnimationsFileName)
    end
    return {
        EmotePages = State.EmotePages,
        Animations = HttpService:JSONDecode(favAnimsStr) or {}
    }
end

BtnExportAll.MouseButton1Click:Connect(function()
    local data = {
        Type = "All",
        Themes = LoadThemes(),
        Settings = Config,
        Favorites = GetFavoritesData()
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportAll.Text = "Copied!"
    task.delay(1, function() BtnExportAll.Text = "Export All Settings" end)
end)

BtnExportThemes.MouseButton1Click:Connect(function()
    local data = {
        Type = "Themes",
        Themes = LoadThemes()
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportThemes.Text = "Copied!"
    task.delay(1, function() BtnExportThemes.Text = "Export Themes" end)
end)

BtnExportSettings.MouseButton1Click:Connect(function()
    local data = {
        Type = "Settings",
        Settings = Config
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportSettings.Text = "Copied!"
    task.delay(1, function() BtnExportSettings.Text = "Export Settings" end)
end)

BtnExportFavorites.MouseButton1Click:Connect(function()
    local data = {
        Type = "Favorites",
        Favorites = GetFavoritesData()
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportFavorites.Text = "Copied!"
    task.delay(1, function() BtnExportFavorites.Text = "Export Favorites" end)
end)


local ImportItem = SettingsLib.AddItem(BackupTab, "Import Settings", "Select a backup file to restore your configuration and overwrite current settings.")
ImportItem.LayoutOrder = 3

local ImportBtnContainer = Instance.new("Frame")
ImportBtnContainer.Parent = ImportItem
ImportBtnContainer.BackgroundTransparency = 1
ImportBtnContainer.Size = UDim2.new(1, -24, 0, 60)

local impDesc = ImportItem:FindFirstChild("Desc")
if impDesc then
    impDesc.Size = UDim2.new(1, -24, 0, 0)
    local function updateImpPos()
        ImportBtnContainer.Position = UDim2.new(0, 12, 0, impDesc.Position.Y.Offset + impDesc.AbsoluteSize.Y + 12)
    end
    impDesc:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateImpPos)
    updateImpPos()
else
    ImportBtnContainer.Position = UDim2.new(0, 12, 0, 32)
end

local ImportLayout = Instance.new("UIGridLayout")
ImportLayout.CellSize = UDim2.new(0.48, 0, 0, 26)
ImportLayout.CellPadding = UDim2.new(0.04, 0, 0, 8)
ImportLayout.SortOrder = Enum.SortOrder.LayoutOrder
ImportLayout.Parent = ImportBtnContainer

function CreateImportBtn(text, color, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 11
    btn.Parent = ImportBtnContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

local BtnImportAll = CreateImportBtn("Import All Settings", btnColors.dark, 1)
local BtnImportThemes = CreateImportBtn("Import Themes", btnColors.blue, 2)
local BtnImportSettings = CreateImportBtn("Import Settings", btnColors.blue, 3)
local BtnImportFavorites = CreateImportBtn("Import Favorites", btnColors.blue, 4)

function HandleImportPrompt(typeStr)
    local popup, content = CreatePopup("Import " .. typeStr, UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Backup JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    
    local imp = CreateButton(content, "IMPORT DATA", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" and d.Type then
            if typeStr ~= "All" and d.Type ~= "All" and typeStr ~= d.Type then
                 getgenv().Notify({Title = "Error", Content = "Backup type mismatch!", Duration = 3})
                 return
            end
            
            if d.Themes and (typeStr == "All" or typeStr == "Themes") then
                themes = d.Themes
                currentThemeName = themes.Selected or Config.SelectedTheme or "Default"
                SaveThemesImplementation(themes)
                themeDropdown.Refresh(GetNames())
                if themeDropdown and themeDropdown.Button then
                    themeDropdown.Button.Text = currentThemeName .. "  ▼"
                end
                local themeToApply = themes[currentThemeName] or themes["Default"]
                if themeToApply then
                    State.isApplyingTheme = false
                    ApplyTheme(themeToApply)
                else
                    warn("Aphelion | Missing Default theme during import fallback")
                end
            end
            if d.Settings and (typeStr == "All" or typeStr == "Settings") then
                for k, v in pairs(d.Settings) do Config[k] = v end
                SaveConfig()
                ApplyUIVisibility()
                if applySavedPositions then applySavedPositions() end
                if State.RefreshSettingsUI then State.RefreshSettingsUI() end
            end
            if (d.Favorites or d.EmotePages) and (typeStr == "All" or typeStr == "Favorites") then
                local emotesData = d.EmotePages
                if not emotesData and type(d.Favorites) == "table" then
                    emotesData = d.Favorites.EmotePages or d.Favorites.Emotes
                end
                if emotesData then
                    if emotesData.Sets then
                        State.EmotePages = emotesData
                    else
                        State.EmotePages.Sets.Default = emotesData
                    end
                    State.SaveEmotePages(State.EmotePages)
                    local targetPage = State.EmotePages.Selected
                    if not State.EmotePages.Sets[targetPage] then targetPage = "Default" end
                    SwitchEmotePage(targetPage)
                end
                
                if d.Favorites and d.Favorites.Animations then
                     State.favoriteAnimations = d.Favorites.Animations
                     writefile(State.favoriteAnimationsFileName, HttpService:JSONEncode(d.Favorites.Animations))
                     State.favoriteSetVersion = State.favoriteSetVersion + 1
                end
                if State.RefreshUI then State.RefreshUI() end
            end
            
            getgenv().Notify({Title = "Success", Content = "Data imported successfully!", Duration = 3})
            popup:Destroy()
        else
            getgenv().Notify({Title = "Error", Content = "Invalid Backup JSON Format!", Duration = 3})
        end
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end

BtnImportAll.MouseButton1Click:Connect(function() HandleImportPrompt("All") end)
BtnImportThemes.MouseButton1Click:Connect(function() HandleImportPrompt("Themes") end)
BtnImportSettings.MouseButton1Click:Connect(function() HandleImportPrompt("Settings") end)
BtnImportFavorites.MouseButton1Click:Connect(function() HandleImportPrompt("Favorites") end)

getgenv().Notify({
    Title = 'Aphelion | Emote',
    Content = '⚠️ Script loading...',
    Duration = 5
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then
    player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

getgenv().OwnedAuthenticEmotes = getgenv().OwnedAuthenticEmotes or {}
function gatherAuthenticEmotes(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local desc = hum:WaitForChild("HumanoidDescription", 5)
    if not desc then return end
    local allEmotes = desc:GetEmotes()
    local owned = {}
    
    for _, e in ipairs(desc:GetEquippedEmotes()) do
        local id = allEmotes[e.Name] and allEmotes[e.Name][1]
        if id then
            local idNum = tonumber((tostring(id):gsub("rbxassetid://", "")))
            if idNum then
                table.insert(owned, {
                    name = e.Name,
                    id = idNum
                })
            end
        end
    end
    if #owned > 0 then
        getgenv().OwnedAuthenticEmotes = owned
    end
end

task.spawn(function() gatherAuthenticEmotes(character) end)
player.CharacterAdded:Connect(gatherAuthenticEmotes)

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

RunService.Heartbeat:Connect(function()
    local success, menu = pcall(function() return CoreGui.RobloxGui.EmotesMenu.Children end)
    if not (success and menu) then return end
    
    pcall(function()
        local wheelVisible = menu.Main.EmotesWheel.Visible
        if wheelVisible then
            State.lastWheelVisibleTime = tick()
        end
        ToggleContainer.Visible = wheelVisible
    end)

    local errorMsg = menu:FindFirstChild("ErrorMessage")

    if errorMsg and errorMsg.Visible then
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            errorMsg.ErrorText.Text = "Only r15 does not work r6"
        elseif tick() - State.lastRadialActionTime < 2 then
            errorMsg.Visible = false
        end
    end
end)


function ErrorMessage(text, duration)

    if State.currentTimer then
        task.cancel(State.currentTimer)
        State.currentTimer = nil
    end
    
    local errorMessage = CoreGui.RobloxGui.EmotesMenu.Children.ErrorMessage
    local errorText = errorMessage.ErrorText
    
    errorText.Text = text
    
    errorMessage.Visible = true
    
    State.currentTimer = task.delay(duration, function()
        errorMessage.Visible = false
        State.currentTimer = nil
    end)
end

function stopEmotes()
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

function getCharacterAndHumanoid()
    local character = player.Character
    if not character then
        return nil, nil
    end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil, nil
    end
    return character, humanoid
end

-- APHELION BUNDLE PERSISTENCE
-- A selected bundle is a character animation set, not a one-shot preview.
-- Reapply it after respawn and on script start so Roblox's fresh Animate script
-- cannot silently restore the default Idle/Walk/Run set.
local AphelionBundleRestoreToken = 0

local function AphelionIsBundleAnimation(data)
    return type(data) == "table" and (data.bundledItems ~= nil or data.isCustomSet == true)
end

local function AphelionGetSavedBundle()
    local data = getgenv().lastPlayedAnimation or Config.LastPlayedAnimationData
    if not AphelionIsBundleAnimation(data) then
        return nil
    end
    return data
end

local function AphelionWaitForCharacterReady(character)
    if not character or not character.Parent then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        humanoid = character:WaitForChild("Humanoid", 10)
    end
    if not humanoid then
        return nil, nil, nil
    end

    local animate = character:FindFirstChild("Animate")
    if not animate then
        animate = character:WaitForChild("Animate", 10)
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        root = character:WaitForChild("HumanoidRootPart", 10)
    end

    if not animate or not root then
        return nil, nil, nil
    end

    -- Character appearance can overwrite Animate after the Humanoid exists.
    -- Give that pipeline a moment to settle before applying the bundle.
    pcall(function()
        if not player:HasAppearanceLoaded() then
            player.CharacterAppearanceLoaded:Wait()
        end
    end)
    task.wait(0.18)

    return humanoid, animate, root
end

local function AphelionRestoreSavedBundle(character, reason)
    local savedBundle = AphelionGetSavedBundle()
    if not savedBundle then
        return false
    end

    AphelionBundleRestoreToken += 1
    local token = AphelionBundleRestoreToken
    local targetCharacter = character or player.Character

    task.spawn(function()
        local humanoid, animate = AphelionWaitForCharacterReady(targetCharacter)
        if token ~= AphelionBundleRestoreToken then
            return
        end
        if not humanoid or not animate or not targetCharacter or not targetCharacter.Parent then
            return
        end

        local ok, err = pcall(function()
            applyAnimation(savedBundle)
        end)

        if not ok then
            warn("Aphelion | bundle restore failed (" .. tostring(reason or "unknown") .. "): " .. tostring(err))
            return
        end

        -- Force Roblox's Animate controller to re-read the freshly replaced
        -- AnimationIds. This is especially important directly after respawn.
        task.wait(0.08)
        if token ~= AphelionBundleRestoreToken then
            return
        end
        if animate.Parent and humanoid.Parent and humanoid.MoveDirection.Magnitude == 0 then
            pcall(function()
                animate.Disabled = true
                task.wait()
                animate.Disabled = false
            end)
        end

        if tostring(reason) ~= "selection" then
            AphelionSafeNotify(
                "Aphelion | Bundle Restored",
                "▶ " .. tostring(savedBundle.name or savedBundle.id or "Selected bundle"),
                2
            )
        end
    end)

    return true
end

function urlToId(animationId)
    animationId = string.gsub(animationId, "http://www%.roblox%.com/asset/%?id=", "")
    animationId = string.gsub(animationId, "rbxassetid://", "")
    return animationId
end

function resolveEmoteToAnimationId(emoteId)
    local fallbackId = tonumber(emoteId)
    if not emoteId or emoteId == "" then return fallbackId end

    local objects
    local ok = false
    local idStr = tostring(emoteId)
    for _, url in ipairs({
        "rbxassetid://" .. idStr,
        "http://www.roblox.com/asset/?id=" .. idStr
    }) do
        ok, objects = pcall(function()
            return game:GetObjects(url)
        end)
        if ok and type(objects) == "table" and #objects > 0 then
            break
        end
    end
    if ok and type(objects) == "table" then
        local function findAnimId(obj)
            if obj:IsA("Animation") then
                local animId = tonumber(urlToId(obj.AnimationId))
                if animId and animId > 0 then
                    return animId
                end
            end
            for _, child in ipairs(obj:GetChildren()) do
                local found = findAnimId(child)
                if found then return found end
            end
            return nil
        end

        local rootObj = objects[1]
        if rootObj and rootObj.Parent == nil then
            pcall(function() rootObj.Parent = workspace end)
        end
        if rootObj then
            local foundRoot = findAnimId(rootObj)
            if foundRoot then
                pcall(function() rootObj:Destroy() end)
                return foundRoot
            end
        end
        for _, obj in ipairs(objects) do
            local found = findAnimId(obj)
            pcall(function() obj:Destroy() end)
            if found then
                return found
            end
        end
    end
    return fallbackId
end

function saveFavoritesAnimations()
    if writefile then
        local jsonData = HttpService:JSONEncode(State.favoriteAnimations)
        writefile(State.favoriteAnimationsFileName, jsonData)
    end
end

function loadFavoritesAnimations()
    if readfile and isfile and isfile(State.favoriteAnimationsFileName) then
        local success, result = pcall(function()
            local fileContent = readfile(State.favoriteAnimationsFileName)
            return HttpService:JSONDecode(fileContent)
        end)
        if success and type(result) == "table" then
            local filtered = {}
            for _, fav in pairs(result) do
                local idNum = fav and tonumber(fav.id)
                if fav and idNum and (idNum > 0 or idNum < -1000) then
                    if fav.isCustomSet == nil and idNum < 0 then
                        fav.isCustomSet = true
                    end
                    if IsCustomSetData(fav) and not fav.customSetName and type(fav.name) == "string" then
                        local baseName = fav.name:gsub("%s*%-.*$", "")
                        fav.customSetName = baseName
                    end
                    table.insert(filtered, fav)
                end
            end
            State.favoriteAnimations = filtered
            State.favoriteSetVersion = State.favoriteSetVersion + 1
        end
    end
end

function disconnectAllConnections()
    for _, connection in pairs(State.guiConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    State.guiConnections = {}
    if ContextActionService then
        ContextActionService:UnbindAction("Aphelion_EmoteWheelHotkeys")
    end
end

function loadSpeedEmoteConfig()
    State.speedEmoteEnabled = Config.EmoteSpeedEnabled
    if UI.SpeedBox then
        UI.SpeedBox.Text = tostring(Config.EmoteSpeed)
        updateSpeedBoxVisibility()
    end
end

function extractAssetId(imageUrl)
    local assetId = string.match(imageUrl, "Asset&id=(%d+)")
    return assetId
end

local isRandomSlotEnabled
local isRandomSlotActive

function isEmoteSearchActive()
    return State.currentMode == "emote" and State.emoteSearchTerm and State.emoteSearchTerm ~= ""
end

function isAnimationSearchActive()
    return State.currentMode == "animation" and State.animationSearchTerm and State.animationSearchTerm ~= ""
end

function isSearchActive()
    return isEmoteSearchActive() or isAnimationSearchActive()
end

function shouldRandomSlotBeShown()
    if Config.RandomEnabled ~= true then return false end
    if State.currentMode == "emote" then
        return not isEmoteSearchActive()
    elseif State.currentMode == "animation" then
        return not isAnimationSearchActive()
    end
    return false
end

function getFirstPageSize()
    if shouldRandomSlotBeShown() then
        return math.max(State.itemsPerPage - 1, 1)
    end
    return State.itemsPerPage
end

isRandomSlotEnabled = function()
    return Config.RandomEnabled == true
end

function calcPagesForList(count, isFirstList)
    if count <= 0 then return 0 end
    if isFirstList then
        local first = getFirstPageSize()
        if count <= first then return 1 end
        return 1 + math.ceil((count - first) / State.itemsPerPage)
    end
    return math.ceil(count / State.itemsPerPage)
end

function getCategoryStats()
    local stats = {}
    local randomCaptured = false
    local shouldShowRandom = shouldRandomSlotBeShown()

    local authenticEmotes = (Config.AuthenticFirstPage and State.currentMode == "emote") and (getgenv().OwnedAuthenticEmotes or {}) or {}
    if #authenticEmotes > 0 then
        local pages = calcPagesForList(#authenticEmotes, false)
        table.insert(stats, { name = "Authentic", list = authenticEmotes, pages = pages, hasRandom = false })
    end

    local favoritesToUse = (State.currentMode == "animation") and (_G.filteredFavoritesAnimationsForDisplay or State.favoriteAnimations) or (_G.filteredFavoritesForDisplay or State.favoriteEmotes)
    if #favoritesToUse > 0 then
        local hasRandom = not randomCaptured and shouldShowRandom
        if hasRandom then randomCaptured = true end
        local pages = calcPagesForList(#favoritesToUse, hasRandom)
        table.insert(stats, { name = "Favorites", list = favoritesToUse, pages = pages, hasRandom = hasRandom })
    end

    local normalList = {}
    if State.currentMode == "animation" then
        normalList = State.animationPageCache.normal or {}
    else
        normalList = State.emotePageCache.normal or {}
    end

    if #normalList > 0 then
        local hasRandom = not randomCaptured and shouldShowRandom
        if hasRandom then randomCaptured = true end
        local pages = calcPagesForList(#normalList, hasRandom)
        table.insert(stats, { name = "Normal", list = normalList, pages = pages, hasRandom = hasRandom })
    end

    return stats
end

isRandomSlotActive = function()
    if not shouldRandomSlotBeShown() then return false end
    local categories = getCategoryStats()
    local totalPages = 0
    for _, cat in ipairs(categories) do
        if cat.hasRandom then
            return State.currentPage == totalPages + 1
        end
        totalPages = totalPages + cat.pages
    end
    return false
end

function getPageSize(pageNumber, isFirstList)
    if isFirstList and pageNumber == 1 then
        return getFirstPageSize()
    end
    return State.itemsPerPage
end

function getListSlice(list, pageNumber, isFirstList)
    local pageSize = getPageSize(pageNumber, isFirstList)
    local startIndex
    if isFirstList and pageNumber == 1 then
        startIndex = 1
    elseif isFirstList then
        startIndex = getFirstPageSize() + (pageNumber - 2) * State.itemsPerPage + 1
    else
        startIndex = (pageNumber - 1) * State.itemsPerPage + 1
    end
    local endIndex = math.min(startIndex + pageSize - 1, #list)
    local items = {}
    for i = startIndex, endIndex do
        if list[i] then table.insert(items, list[i]) end
    end
    return items
end

function getRandomSourceList()
    if Config.RandomEnabled == false then
        return {}
    end
    if State.favoriteEnabled then
        if State.currentMode == "animation" then
            return State.filteredAnimations
        end
        return State.filteredEmotes
    end
    if Config.RandomMode == "Favorites" then
        if State.currentMode == "animation" then
            return _G.filteredFavoritesAnimationsForDisplay or State.favoriteAnimations
        end
        return _G.filteredFavoritesForDisplay or State.favoriteEmotes
    end
    if State.currentMode == "animation" then
        return State.filteredAnimations
    end
    return State.filteredEmotes
end

function pickRandomItem()
    local list = getRandomSourceList() or {}
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

function pickRandomItemForMode()
    local list = getRandomSourceList() or {}
    if #list == 0 then return nil end
    if State.currentMode == "animation" then
        local filtered = {}
        for _, item in ipairs(list) do
            if item.bundledItems then
                table.insert(filtered, item)
            end
        end
        if #filtered == 0 then return nil end
        return filtered[math.random(1, #filtered)]
    end
    return list[math.random(1, #list)]
end
function updateRandomSlotBlocker(frontFrame, enable)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if not slot or not slot:IsA("ImageLabel") then return end

    local blocker = slot:FindFirstChild("RandomBlocker")
    if enable then
        if not blocker then
            blocker = Instance.new("ImageButton")
            blocker.Name = "RandomBlocker"
            blocker.BackgroundTransparency = 1
            blocker.Size = UDim2.new(1, 0, 1, 0)
            blocker.Position = UDim2.new(0, 0, 0, 0)
            blocker.AutoButtonColor = false
            blocker.ZIndex = slot.ZIndex + 10
            blocker.Parent = slot
        else
            blocker.ZIndex = slot.ZIndex + 10
        end
        blocker.Active = true
    else
        if blocker then blocker:Destroy() end
        if State.randomSlotBlockerConn then
            State.randomSlotBlockerConn:Disconnect()
            State.randomSlotBlockerConn = nil
        end
    end
end

function clearCustomHitboxes()
    if State.randomSlotBlockerConn then
        State.randomSlotBlockerConn:Disconnect()
        State.randomSlotBlockerConn = nil
    end
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end
    local slot1 = frontFrame:FindFirstChild("1")
    if slot1 then
        local blocker = slot1:FindFirstChild("RandomBlocker")
        if blocker then blocker:Destroy() end
    end
    for _, child in pairs(frontFrame:GetChildren()) do
        if child:IsA("ImageLabel") then
            child.Active = false
        end
    end
    frontFrame.Active = true   
end

function applyEmotesButtonsActiveState()
end

function setEmotesButtonsActiveForFavorites()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end
    for _, child in pairs(frontFrame:GetChildren()) do
        if child:IsA("ImageLabel") then
            child.Active = true
        end
    end
    frontFrame.Active = true
end

function updateScriptPriorityOverlay()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end

    local enable = (State.favoriteEnabled or State.currentMode == "animation" or State.customAnimationEditorActive)
    local blocker = frontFrame:FindFirstChild("ScriptPriorityBlocker")
    if enable then
        if not blocker then
            blocker = Instance.new("ImageButton")
            blocker.Name = "ScriptPriorityBlocker"
            blocker.BackgroundTransparency = 1
            blocker.Size = UDim2.new(1, 0, 1, 0)
            blocker.Position = UDim2.new(0, 0, 0, 0)
            blocker.AutoButtonColor = false
            blocker.ZIndex = 9999
            blocker.Parent = frontFrame
            
            blocker.InputBegan:Connect(function(input)
                if State.hudEditorActive then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                
                local okWheel, emotesWheel = pcall(function()
                    return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel
                end)
                if not (okWheel and emotesWheel) then return end
                if not emotesWheel.Visible then return end

                local actualPos = Vector2.new(input.Position.X, input.Position.Y)
                local absPos = emotesWheel.AbsolutePosition
                local absSize = emotesWheel.AbsoluteSize

                local inXBounds = (actualPos.X >= absPos.X) and (actualPos.X <= absPos.X + absSize.X)
                local inYBounds = (actualPos.Y >= absPos.Y) and (actualPos.Y <= absPos.Y + absSize.Y)
                if not (inXBounds and inYBounds) then return end

                local center = absPos + (absSize / 2)
                local dx = actualPos.X - center.X
                local dy = actualPos.Y - center.Y

                local distance = math.sqrt(dx*dx + dy*dy)
                local radius = math.min(absSize.X, absSize.Y) * 0.5
                if distance > radius then return end
                local dynamicDeadzone = radius * 0.2
                if distance < dynamicDeadzone then return end

                local sectorAngle = 360 / 8
                local angle = math.deg(math.atan2(dy, dx))
                local correctedAngle = (angle + 90 + (sectorAngle / 2)) % 360
                local index = math.floor(correctedAngle / sectorAngle) + 1
                if not (State.customAnimationEditorActive or State.favoriteEnabled or State.currentMode == "animation" or (index == 1 and isRandomSlotActive())) then return end

                handleSectorAction(index)
            end)
        end
        blocker.Active = true
    else
        if blocker then blocker:Destroy() end
    end
end

function applyRandomSlotVisual(frontFrame)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if slot and slot:IsA("ImageLabel") then
        if not isRandomSlotEnabled() then
            AnimationSystem.ResetRandomSlot(frontFrame)
            return
        end
        if slot.Image ~= RANDOM_SLOT_ICON then
            slot.Image = RANDOM_SLOT_ICON
        end
        if slot.ImageColor3 ~= RANDOM_SLOT_COLOR then
            slot.ImageColor3 = RANDOM_SLOT_COLOR
        end
        if State.currentMode == "emote" then
            updateRandomSlotBlocker(frontFrame, true)
        else
            updateRandomSlotBlocker(frontFrame, false)
        end
        local idValue = slot:FindFirstChild("AnimationID")
        if idValue then idValue:Destroy() end
        local favoriteIcon = slot:FindFirstChild("FavoriteIcon")
        if favoriteIcon then favoriteIcon:Destroy() end
    end
end

function resetRandomSlotColor(frontFrame)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if slot and slot:IsA("ImageLabel") then
        if slot.ImageColor3 == RANDOM_SLOT_COLOR then
            slot.ImageColor3 = Color3.new(1, 1, 1)
        end
        if slot.Image == RANDOM_SLOT_ICON then
            slot.Image = ""
        end
    end
    updateRandomSlotBlocker(frontFrame, false)
    if State.randomSpamConn then
        State.randomSpamConn:Disconnect()
        State.randomSpamConn = nil
    end
end

function applySearchSlot1Image()
    pcall(function()
        local frontFrame = game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
        local slot1 = frontFrame and frontFrame:FindFirstChild("1")
        local slot2 = frontFrame and frontFrame:FindFirstChild("2")
        if slot1 and slot1:IsA("ImageLabel") and slot2 and slot2:IsA("ImageLabel") then
            local img2 = slot2.Image
            if img2 and img2 ~= "" then
                slot1.Image = img2
            end
        end
    end)
end

function bumpImageUpdateToken()
    State.imageUpdateToken = State.imageUpdateToken + 1
end

local ContentProvider = game:GetService("ContentProvider")
function preloadThumbnail(url)
    if not url or url == "" then return end
    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({Instance.new("ImageLabel", {Image = url})})
        end)
    end)
end

function enforceImages()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end
    
    local token = State.imageUpdateToken
    for slotName, targetImg in pairs(State.targetImages) do
        local slot = frontFrame:FindFirstChild(slotName)
        if slot and slot:IsA("ImageLabel") then
            if slot.Image ~= targetImg then
                slot.Image = targetImg
            end
            if slotName == "1" and isRandomSlotActive() then
                if slot.ImageColor3 ~= RANDOM_SLOT_COLOR then
                    slot.ImageColor3 = RANDOM_SLOT_COLOR
                end
            end
        end
    end
end

function spamRandomSlotVisual(frontFrame, token)
    if not frontFrame then return end
    State.targetImages["1"] = RANDOM_SLOT_ICON
    enforceImages()
end

function spamAnimationImages(frontFrame, imageMap, token)
    if not frontFrame then return end
    for k, v in pairs(imageMap or {}) do
        State.targetImages[k] = v
    end
    enforceImages()
end


function getEmoteName(assetId)
    local success, productInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(tonumber(assetId))
    end)
    
    if success and productInfo then
        return productInfo.Name
    else
        return "Emote_" .. tostring(assetId)
    end
end

isInFavorites = function(assetId)
    if not assetId then return false end
    if State.favoriteSetBuiltVersion ~= State.favoriteSetVersion then
        State.favoriteEmoteSet = {}
        for _, favorite in pairs(State.favoriteEmotes) do
            if favorite.id then
                State.favoriteEmoteSet[tostring(favorite.id)] = true
            end
        end
        State.favoriteAnimationSet = {}
        for _, favorite in pairs(State.favoriteAnimations) do
            if favorite.id then
                State.favoriteAnimationSet[tostring(favorite.id)] = true
            end
        end
        State.favoriteSetBuiltVersion = State.favoriteSetVersion
    end
    if State.currentMode == "animation" then
        return State.favoriteAnimationSet[tostring(assetId)] == true
    end
    return State.favoriteEmoteSet[tostring(assetId)] == true
end

function rebuildEmoteNormalCache()
    if State.emotePageCache.version == State.emoteCacheVersion and State.emotePageCache.favVersion == State.favoriteSetVersion then
        return
    end
    if State.favoriteSetBuiltVersion ~= State.favoriteSetVersion then
        State.favoriteEmoteSet = {}
        for _, favorite in pairs(State.favoriteEmotes) do
            State.favoriteEmoteSet[tostring(favorite.id)] = true
        end
        State.favoriteAnimationSet = {}
        for _, favorite in pairs(State.favoriteAnimations) do
            State.favoriteAnimationSet[tostring(favorite.id)] = true
        end
        State.favoriteSetBuiltVersion = State.favoriteSetVersion
    end
    local normal = {}
    for _, emote in ipairs(State.filteredEmotes) do
        if not State.favoriteEmoteSet[tostring(emote.id)] then
            table.insert(normal, emote)
        end
    end
    State.emotePageCache.normal = normal
    State.emotePageCache.version = State.emoteCacheVersion
    State.emotePageCache.favVersion = State.favoriteSetVersion
end

function rebuildAnimationNormalCache()
    if State.animationPageCache.version == State.animationCacheVersion and State.animationPageCache.favVersion == State.favoriteSetVersion then
        return
    end
    if State.favoriteSetBuiltVersion ~= State.favoriteSetVersion then
        State.favoriteEmoteSet = {}
        for _, favorite in pairs(State.favoriteEmotes) do
            State.favoriteEmoteSet[tostring(favorite.id)] = true
        end
        State.favoriteAnimationSet = {}
        for _, favorite in pairs(State.favoriteAnimations) do
            State.favoriteAnimationSet[tostring(favorite.id)] = true
        end
        State.favoriteSetBuiltVersion = State.favoriteSetVersion
    end
    local normal = {}
    for _, animation in ipairs(State.filteredAnimations) do
        if not State.favoriteAnimationSet[tostring(animation.id)] then
            table.insert(normal, animation)
        end
    end
    State.animationPageCache.normal = normal
    State.animationPageCache.version = State.animationCacheVersion
    State.animationPageCache.favVersion = State.favoriteSetVersion
end

function getCustomSetIcon(setName)
    local set = State.CustomAnimations and State.CustomAnimations.Sets and State.CustomAnimations.Sets[setName]
    local meta = set and set.__meta or {}
    local iconImage = meta.IconImage or DEFAULT_IDLE_ICON_ID
    local iconColor = TableToColor(meta.IconColor or ColorToTable(DEFAULT_IDLE_ICON_COLOR))
    return iconImage, iconColor
end

function IsCustomSetData(data)
    if not data then return false end
    if data.isCustomSet then return true end
    local idNum = tonumber(data.id)
    return idNum and idNum < 0 or false
end

function GetCustomSetName(data)
    if not data then return nil end
    local name = data.customSetName or data.name
    if type(name) == "string" then
        name = name:gsub("%s*%-.*$", "")
    end
    return name
end

function updateAnimationImages(currentPageAnimations, randomActive)
    local token = State.imageUpdateToken
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if not success or not frontFrame then
        return
    end

    if randomActive then
        applyRandomSlotVisual(frontFrame)
        State.targetImages = {["1"] = RANDOM_SLOT_ICON}
        spamRandomSlotVisual(frontFrame, token)
    else
        State.targetImages = {}
        resetRandomSlotColor(frontFrame)
    end

    local startSlot = randomActive and 2 or 1
    local imageMap = {}
    local newTargetImages = {}
    if randomActive then
        newTargetImages["1"] = RANDOM_SLOT_ICON
    end

    for i = 1, 12 do
        if i >= startSlot then
            local listIndex = randomActive and (i - 1) or i
            local animationData = currentPageAnimations[listIndex]
            if animationData and animationData.id then
                local idStr = tostring(animationData.id)
                local image
                if IsCustomSetData(animationData) then
                    local customImage = getCustomSetIcon(GetCustomSetName(animationData) or animationData.name)
                    image = GetAsset(customImage)
                else
                    image = "rbxthumb://type=BundleThumbnail&id=" .. idStr .. "&w=420&h=420"
                end
                newTargetImages[tostring(i)] = image
                imageMap[tostring(i)] = image
            else
                newTargetImages[tostring(i)] = ""
                imageMap[tostring(i)] = ""
            end
        end
    end
    
    State.targetImages = newTargetImages

    for slotName, image in pairs(imageMap) do
        local child = frontFrame:FindFirstChild(slotName)
        if child and child:IsA("ImageLabel") then
            preloadThumbnail(image)
            child.Image = image
            
            local listIndex = randomActive and (tonumber(slotName) - 1) or tonumber(slotName)
            local animationData = currentPageAnimations[listIndex]
            if animationData and animationData.id then
                local idValue = child:FindFirstChild("AnimationID") or Instance.new("IntValue")
                idValue.Name = "AnimationID"
                idValue.Value = tonumber(animationData.id) or 0
                idValue.Parent = child
                
                if IsCustomSetData(animationData) then
                    local _, customColor = getCustomSetIcon(GetCustomSetName(animationData) or animationData.name)
                    child.ImageColor3 = customColor
                else
                    child.ImageColor3 = Color3.new(1, 1, 1)
                end
            elseif not randomActive and child.ImageColor3 == RANDOM_SLOT_COLOR then
                child.ImageColor3 = Color3.new(1, 1, 1)
            end
        end
    end
    
    applyEmotesButtonsActiveState()
end


function updateFavoriteIcon(imageLabel, assetId, isFavorite)
    local favoriteIcon = imageLabel:FindFirstChild("FavoriteIcon")
    
    if not favoriteIcon then
        favoriteIcon = Instance.new("ImageLabel")
        favoriteIcon.Name = "FavoriteIcon"
        favoriteIcon.Size = UDim2.new(0.3, 0, 0.3, 0) 
        favoriteIcon.Position = UDim2.new(0.7, 0, 0, 0)
        favoriteIcon.AnchorPoint = Vector2.new(0, 0)
        favoriteIcon.BackgroundTransparency = 1
        favoriteIcon.ZIndex = imageLabel.ZIndex + 5
        favoriteIcon.ScaleType = Enum.ScaleType.Fit
        favoriteIcon.Parent = imageLabel
    end
    
    if isFavorite then
        favoriteIcon.Image = State.favoriteIconId
    else
        favoriteIcon.Image = State.notFavoriteIconId 
    end
end

function updateAllFavoriteIcons()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        if not State.favoriteEnabled then
            for _, child in pairs(frontFrame:GetChildren()) do
                if child:IsA("ImageLabel") then
                    local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                    if favoriteIcon then favoriteIcon:Destroy() end
                end
            end
            return
        end
        local randomActive = isRandomSlotActive()
        for _, child in pairs(frontFrame:GetChildren()) do
            if child:IsA("ImageLabel") and child.Image ~= "" and (not randomActive or child.Name ~= "1") then
                local assetId
                if State.currentMode == "animation" then
                    local idValue = child:FindFirstChild("AnimationID")
                    if idValue then
                        assetId = idValue.Value
                    end
                else
                    assetId = extractAssetId(child.Image)
                end
                
                if assetId then
                    local isFavorite = isInFavorites(assetId)
                    updateFavoriteIcon(child, assetId, isFavorite)
                end
            end
        end
        applyEmotesButtonsActiveState()
    end
end

function updateAnimations()
    local character, humanoid = getCharacterAndHumanoid()
    if not character or not humanoid then
        return
    end

    local humanoidDescription = humanoid.HumanoidDescription
    if not humanoidDescription then
        if not State.pendingAnimRetry then
            State.pendingAnimRetry = true
            task.delay(0.2, function()
                State.pendingAnimRetry = false
                if State.currentMode == "animation" then
                    updateAnimations()
                end
            end)
        end
        return
    end

    bumpImageUpdateToken()
    rebuildAnimationNormalCache()

    local currentPageAnimations = {}
    local animationTable = {}
    local equippedAnimations = {}

    local categories = getCategoryStats()
    local accumulatedPages = 0
    local currentCat = nil
    
    for _, cat in ipairs(categories) do
        if State.currentPage <= accumulatedPages + cat.pages then
            local adjustedPage = State.currentPage - accumulatedPages
            currentPageAnimations = getListSlice(cat.list, adjustedPage, cat.hasRandom)
            currentCat = cat
            break
        end
        accumulatedPages = accumulatedPages + cat.pages
    end

    local randomActive = isRandomSlotActive()
    if randomActive then
        local randomFallback = currentPageAnimations[1] or (State.filteredAnimations and State.filteredAnimations[1])
        if randomFallback then
            animationTable["Random Animation"] = {randomFallback.id}
            table.insert(equippedAnimations, "Random Animation")
        end
    end

    State.animImageRetry = 0
    for _, animation in pairs(currentPageAnimations) do
        local animationName = animation.name
        local animationId = animation.id
        animationTable[animationName] = {animationId}
        table.insert(equippedAnimations, animationName)
    end

    humanoidDescription:SetEmotes(animationTable)
    humanoidDescription:SetEquippedEmotes(equippedAnimations)
    
    updateAnimationImages(currentPageAnimations, randomActive)
    if State.favoriteEnabled then
        setEmotesButtonsActiveForFavorites()
    end

    task.delay(0.2, function()
        if State.favoriteEnabled then
            setEmotesButtonsActiveForFavorites()
        end
        if State.favoriteEnabled then
            updateAllFavoriteIcons()
        end
    end)
end

updateEmotes = function()
    local character, humanoid = getCharacterAndHumanoid()
    if not character or not humanoid then
        return
    end

    if State.currentMode == "animation" then
        updateAnimations()
        return
    end
    
    bumpImageUpdateToken()
    local token = State.imageUpdateToken
    
    if State.animImageSpamConn then
        State.animImageSpamConn:Disconnect()
        State.animImageSpamConn = nil
        State.animImageSpamMap = nil
        State.animImageSpamTicks = nil
        State.animImageSpamToken = State.animImageSpamToken + 1
    end

    local humanoidDescription = humanoid.HumanoidDescription
    if not humanoidDescription then
        return
    end

    local currentPageEmotes = {}
    local emoteTable = {}
    local equippedEmotes = {}

    rebuildEmoteNormalCache()
    local categories = getCategoryStats()
    local accumulatedPages = 0
    local currentCat = nil
    
    for _, cat in ipairs(categories) do
        if State.currentPage <= accumulatedPages + cat.pages then
            local adjustedPage = State.currentPage - accumulatedPages
            currentPageEmotes = getListSlice(cat.list, adjustedPage, cat.hasRandom)
            currentCat = cat
            break
        end
        accumulatedPages = accumulatedPages + cat.pages
    end

    local randomActive = isRandomSlotActive()
    if randomActive then
        local randomFallback = currentPageEmotes[1] or (State.filteredEmotes and State.filteredEmotes[1])
        if randomFallback then
            emoteTable["Random Emote"] = {randomFallback.id}
            table.insert(equippedEmotes, "Random Emote")
        end
    end

    for _, emote in pairs(currentPageEmotes) do
        local emoteName = emote.name
        local emoteId = emote.id
        emoteTable[emoteName] = {emoteId}
        table.insert(equippedEmotes, emoteName)
    end

    humanoidDescription:SetEmotes(emoteTable)
    humanoidDescription:SetEquippedEmotes(equippedEmotes)
    
    local newTargetImages = {}
    if randomActive then
        newTargetImages["1"] = RANDOM_SLOT_ICON
    end

    local startSlot = randomActive and 2 or 1
    for i = 1, 12 do
        if i >= startSlot then
            local listIndex = randomActive and (i - 1) or i
            local emoteData = currentPageEmotes[listIndex]
            if emoteData and emoteData.id then
                local idStr = tostring(emoteData.id)
                newTargetImages[tostring(i)] = "rbxthumb://type=Asset&id=" .. idStr .. "&w=420&h=420"
            else
                newTargetImages[tostring(i)] = ""
            end
        end
    end
    
    State.targetImages = newTargetImages

    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        for slotName, image in pairs(newTargetImages) do
            local child = frontFrame:FindFirstChild(slotName)
            if child and child:IsA("ImageLabel") then
                child.Image = image
                if slotName == "1" and randomActive then
                    child.ImageColor3 = RANDOM_SLOT_COLOR
                else
                    child.ImageColor3 = Color3.new(1, 1, 1)
                end
            end
        end
        
        if State.favoriteEnabled then
            setEmotesButtonsActiveForFavorites()
        end
        if randomActive then
            applyRandomSlotVisual(frontFrame)
            spamRandomSlotVisual(frontFrame, token)
        else
            resetRandomSlotColor(frontFrame)
        end
    end

    task.delay(0.2, function()
        if State.favoriteEnabled then
            setEmotesButtonsActiveForFavorites()
        end
        if State.favoriteEnabled then
            updateAllFavoriteIcons()
        end
    end)
end

calculateTotalPages = function()
    rebuildEmoteNormalCache()
    rebuildAnimationNormalCache()

    local categories = getCategoryStats()
    local total = 0
    for _, cat in ipairs(categories) do
        total = total + cat.pages
    end
    return math.max(total, 1)
end

function isGivenAnimation(animationHolder, animationId)
    for _, animation in animationHolder:GetChildren() do
        if animation:IsA("Animation") and urlToId(animation.AnimationId) == animationId then
            return true
        end
    end
    return false
end

local function isToolAnimation(animationTrack)
    local animation = animationTrack and animationTrack.Animation
    if not animation then return false end
    local current = animation.Parent
    while current do
        if current:IsA("Tool") then
            return true
        end
        current = current.Parent
    end
    return false
end

local function findAnimationInDescendants(folder, animationId)
    if not folder then return false end
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("Animation") and urlToId(obj.AnimationId) == animationId then
            return true
        end
    end
    return false
end

local toolAnimationIds = {}

local function refreshToolAnimationIds()
    local newSet = {}
    local function addFrom(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                for _, obj in ipairs(tool:GetDescendants()) do
                    if obj:IsA("Animation") then
                        local animId = urlToId(obj.AnimationId)
                        if animId ~= "" and animId ~= "0" then
                            newSet[animId] = true
                        end
                    end
                end
            end
        end
    end
    addFrom(player.Character)
    addFrom(player.Backpack)
    toolAnimationIds = newSet
end

function isDancing(character, animationTrack)
    if not character or not character.Animate or not animationTrack or not animationTrack.Animation then
        return false
    end
    if isToolAnimation(animationTrack) then
        return false
    end
    local animationId = urlToId(animationTrack.Animation.AnimationId)
    if toolAnimationIds[animationId] then
        return false
    end
    if findAnimationInDescendants(character.Animate:FindFirstChild("Tools"), animationId) then
        return false
    end
    for _, animationHolder in character.Animate:GetChildren() do
        if animationHolder:IsA("StringValue") then
            local sharesAnimationId = isGivenAnimation(animationHolder, animationId)
            if sharesAnimationId then
                return false
            end
        end
    end
    return true
end

function createGUIElements()
    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then
        return false
    end

    if UI.CustomFrames then
        for _, frame in pairs(UI.CustomFrames) do
            if frame and frame.Parent then frame:Destroy() end
        end
    end
    UI.CustomFrames = {}

    if emotesWheel:FindFirstChild("Under") then
        emotesWheel.Under:Destroy()
    end
    if emotesWheel:FindFirstChild("Top") then
        emotesWheel.Top:Destroy()
    end
    if emotesWheel:FindFirstChild("EmoteWalkButton") then
        emotesWheel.EmoteWalkButton:Destroy()
    end
    if emotesWheel:FindFirstChild("Favorite") then
        emotesWheel.Favorite:Destroy()
    end
    if emotesWheel:FindFirstChild("SpeedEmote") then
        emotesWheel.SpeedEmote:Destroy()
    end
    if emotesWheel:FindFirstChild("Changepage") then
        emotesWheel.Changepage:Destroy()
    end
    if emotesWheel:FindFirstChild("SpeedBox") then
        emotesWheel.SpeedBox:Destroy()
    end
    if emotesWheel:FindFirstChild("Reload") then
        emotesWheel.Reload:Destroy()
    end

    UI.Under = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")
    UI._1left = Instance.new("ImageButton")
    UI._9right = Instance.new("ImageButton")
    UI._4pages = Instance.new("TextLabel")
    UI._3TextLabel = Instance.new("TextLabel")
    UI._2Routenumber = Instance.new("TextBox")
    UI.EmoteWalkButton = Instance.new("ImageButton")
    local UICorner_Left = Instance.new("UICorner")
    UICorner_Left.CornerRadius = UDim.new(0, 10)
    UICorner_Left.Parent = UI._1left
    
    local UICorner_Right = Instance.new("UICorner")
    UICorner_Right.CornerRadius = UDim.new(0, 10)
    UICorner_Right.Parent = UI._9right

    local UICorner1 = Instance.new("UICorner")
    UI.Top = Instance.new("Frame")
    local UIListLayout_2 = Instance.new("UIListLayout")
    local UICorner = Instance.new("UICorner")
    UI.Search = Instance.new("TextBox")
    UI.Favorite = Instance.new("ImageButton")
    local UICorner2 = Instance.new("UICorner")
    UI.SpeedBox = Instance.new("TextBox")
    local UICorner_4 = Instance.new("UICorner")
    UI.SpeedEmote = Instance.new("ImageButton")
    local UICorner_2 = Instance.new("UICorner")
    UI.Changepage = Instance.new("ImageButton")
    local UICorner_5 = Instance.new("UICorner")
    UI.Reload = Instance.new("ImageButton")
    local UICorner_6 = Instance.new("UICorner")

    UI.Under.Name = "Under"
    UI.Under.Parent = emotesWheel
    UI.Under.BackgroundTransparency = 1.000
    UI.Under.BorderSizePixel = 0
    UI.Under.Position = UDim2.new(0.129999995, 0, 1, 0)
    UI.Under.Size = UDim2.new(0.737500012, 0, 0.132499993, 0)

    UIListLayout.Parent = UI.Under
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    UI._1left.Name = "1left"
    UI._1left.Parent = UI.Under
    UI._1left.BackgroundTransparency = 1.000
    UI._1left.BorderSizePixel = 0
    UI._1left.Size = UDim2.new(0.169491529, 0, 0.94339627, 0)
    UI._1left.Image = "rbxassetid://93111945058621"
    UI._1left.ImageColor3 = Color3.fromRGB(0, 0, 0)
    UI._1left.ImageTransparency = 0.400

    UI._9right.Name = "9right"
    UI._9right.Parent = UI.Under
    UI._9right.BackgroundTransparency = 1.000
    UI._9right.BorderSizePixel = 0
    UI._9right.Size = UDim2.new(0.169491529, 0, 0.94339627, 0)
    UI._9right.Image = "rbxassetid://107938916240738"
    UI._9right.ImageColor3 = Color3.fromRGB(0, 0, 0)
    UI._9right.ImageTransparency = 0.400

    UI._4pages.Name = "4pages"
    UI._4pages.Parent = UI.Under
    UI._4pages.BackgroundTransparency = 1.000
    UI._4pages.BorderSizePixel = 0
    UI._4pages.Size = UDim2.new(0.159322038, 0, 0.811320841, 0)
    UI._4pages.Font = Enum.Font.SourceSansBold
    UI._4pages.Text = "1"
    UI._4pages.TextColor3 = Color3.fromRGB(0, 0, 0)
    UI._4pages.TextScaled = true
    UI._4pages.TextSize = 14.000
    UI._4pages.TextTransparency = 0.400
    UI._4pages.TextWrapped = true

    UI._3TextLabel.Name = "3TextLabel"
    UI._3TextLabel.Parent = UI.Under
    UI._3TextLabel.BackgroundTransparency = 1.000
    UI._3TextLabel.BorderSizePixel = 0
    UI._3TextLabel.Size = UDim2.new(0.338983059, 0, 0.94339627, 0)
    UI._3TextLabel.Font = Enum.Font.SourceSansBold
    UI._3TextLabel.Text = " ------ "
    UI._3TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    UI._3TextLabel.TextScaled = true
    UI._3TextLabel.TextSize = 14.000
    UI._3TextLabel.TextTransparency = 0.400
    UI._3TextLabel.TextWrapped = true

    UI._2Routenumber.Name = "2Route-number"
    UI._2Routenumber.Parent = UI.Under
    UI._2Routenumber.Active = true
    UI._2Routenumber.BackgroundTransparency = 1.000
    UI._2Routenumber.BorderSizePixel = 0
    UI._2Routenumber.Size = UDim2.new(0.159322038, 0, 0.811320841, 0)
    UI._2Routenumber.Font = Enum.Font.SourceSansBold
    UI._2Routenumber.PlaceholderColor3 = Color3.fromRGB(0, 0, 0)
    UI._2Routenumber.Text = "1"
    UI._2Routenumber.TextColor3 = Color3.fromRGB(0, 0, 0)
    UI._2Routenumber.TextScaled = true
    UI._2Routenumber.TextSize = 14.000
    UI._2Routenumber.TextTransparency = 0.400
    UI._2Routenumber.TextWrapped = true

    UI.Top.Name = "Top"
    UI.Top.Parent = emotesWheel
    UI.Top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.Top.BackgroundTransparency = 0.400
    UI.Top.BorderSizePixel = 0
    UI.Top.Position = UDim2.new(0.127499998, 0, -0.109999999, 0)
    UI.Top.Size = UDim2.new(0.737500012, 0, 0.0949999914, 0)

    UIListLayout_2.Parent = UI.Top
    UIListLayout_2.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_2.VerticalAlignment = Enum.VerticalAlignment.Center

    UICorner.CornerRadius = UDim.new(0, 20)
    UICorner.Parent = UI.Top

    UI.Search.Name = "Search"
    UI.Search.Parent = UI.Top
    UI.Search.BackgroundTransparency = 1.000
    UI.Search.Size = UDim2.new(0.864406765, 0, 0.81578958, 0)
    UI.Search.Font = Enum.Font.SourceSansBold
    UI.Search.PlaceholderText = "Search/ID"
    UI.Search.Text = ""
    UI.Search.TextColor3 = Color3.fromRGB(255, 255, 255)
    UI.Search.TextScaled = true
    UI.Search.TextSize = 14.000
    UI.Search.TextWrapped = true

    UI.EmoteWalkButton.Name = "EmoteWalkButton"
    UI.EmoteWalkButton.Parent = emotesWheel
    UI.EmoteWalkButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.EmoteWalkButton.BackgroundTransparency = 0.400
    UI.EmoteWalkButton.BorderSizePixel = 0
    UI.EmoteWalkButton.Position = UDim2.new(0.889999986, 0, -0.107500002, 0)
    UI.EmoteWalkButton.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.EmoteWalkButton.Image = State.defaultButtonImage

    UICorner1.CornerRadius = UDim.new(0, 10)
    UICorner1.Parent = UI.EmoteWalkButton

    UI.Favorite.Name = "Favorite"
    UI.Favorite.Parent = emotesWheel
    UI.Favorite.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.Favorite.BackgroundTransparency = 0.400
    UI.Favorite.BorderSizePixel = 0
    UI.Favorite.Position = UDim2.new(0.0189999994, 0, -0.108000003, 0)
    UI.Favorite.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.Favorite.Image = "rbxassetid://124025954365505"

    UICorner2.CornerRadius = UDim.new(0, 10)
    UICorner2.Parent = UI.Favorite

    UI.SpeedBox.Name = "SpeedBox"
    UI.SpeedBox.Parent = emotesWheel
    UI.SpeedBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.SpeedBox.BackgroundTransparency = 0.400
    UI.SpeedBox.BorderSizePixel = 0
    UI.SpeedBox.Position = UDim2.new(0.0189999398, 0, -0.000499992399, 0)
    UI.SpeedBox.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.SpeedBox.Visible = false
    UI.SpeedBox.Font = Enum.Font.SourceSansBold
    UI.SpeedBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
    UI.SpeedBox.Text = "1"
    UI.SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    UI.SpeedBox.TextScaled = true
    UI.SpeedBox.TextWrapped = true
    UI.SpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
       UI.SpeedBox.Text = UI.SpeedBox.Text:gsub("[^%d.]", "")
    end)
    UI.SpeedBox.ZIndex = 2

    UICorner_4.CornerRadius = UDim.new(0, 10)
    UICorner_4.Parent = UI.SpeedBox

    UI.SpeedEmote.Name = "SpeedEmote"
    UI.SpeedEmote.Parent = emotesWheel
    UI.SpeedEmote.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.SpeedEmote.BackgroundTransparency = 0.400
    UI.SpeedEmote.BorderSizePixel = 0
    UI.SpeedEmote.Position = UDim2.new(0.888999999, 0, -0, 0)
    UI.SpeedEmote.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.SpeedEmote.Image = "rbxassetid://116056570415896"
    UI.SpeedEmote.ZIndex = 2

    UICorner_2.CornerRadius = UDim.new(0, 10)
    UICorner_2.Parent = UI.SpeedEmote

UI.Changepage.Name = "Changepage"
UI.Changepage.Parent = emotesWheel
UI.Changepage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
UI.Changepage.BackgroundTransparency = 0.400
UI.Changepage.BorderColor3 = Color3.fromRGB(0, 0, 0)
UI.Changepage.BorderSizePixel = 0
UI.Changepage.Position = UDim2.new(0.019, 0,1.021, 0)
UI.Changepage.Size = UDim2.new(0.087, 0,0.087, 0)
UI.Changepage.ZIndex = 3
UI.Changepage.Image = "rbxassetid://13285615740"

UICorner_5.CornerRadius = UDim.new(0, 10)
UICorner_5.Parent = UI.Changepage

    UI.Reload.Name = "Reload"
    UI.Reload.Parent = emotesWheel
    UI.Reload.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.Reload.BackgroundTransparency = 0.400
    UI.Reload.BorderSizePixel = 0
    UI.Reload.Position = UDim2.new(0.888999999, 0, 1.02100003, 0)
    UI.Reload.Size = UDim2.new(0.0869999975, 0, 0.0869999975, 0)
    UI.Reload.ZIndex = 3
    UI.Reload.Image = "rbxassetid://127493377027615"

    UICorner_6.CornerRadius = UDim.new(0, 10)
    UICorner_6.Parent = UI.Reload

    local function spawnCustomFrame(name, zIndex)
        local cf = Instance.new("Frame")
        cf.Name = name
        cf.Parent = emotesWheel
        cf.BackgroundColor3 = Color3.fromRGB(0,0,0)
        cf.BackgroundTransparency = 0.4
        cf.ZIndex = zIndex or 3
        cf.BorderSizePixel = 0
        cf.Active = true
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = cf

        if not UI.CustomFrames then UI.CustomFrames = {} end
        UI.CustomFrames[name] = cf

        return cf
    end

    local function recordDefaults()
        local allMovable = getMovableElements()
        for name, el in pairs(allMovable) do
             HUD.DefaultPositions[name] = el.Position
             HUD.DefaultSizes[name] = el.Size
             if el:IsA("TextLabel") or el:IsA("TextBox") then
                 HUD.DefaultTexts[name] = el.Text
                 if el:IsA("TextBox") then
                     HUD.DefaultPlaceholders[name] = el.PlaceholderText
                 end
             end
        end
    end
    
    if Config.CustomFrames then
        for name, data in pairs(Config.CustomFrames) do
            spawnCustomFrame(name, data.ZIndex or 3)
        end
    end
    
    recordDefaults()
    loadSpeedEmoteConfig()

    connectEvents()
    State.isGUICreated = true
    
    ApplyTheme(themes[currentThemeName] or themes.Default)
    
    updateGUIColors()
    
    ApplyUIVisibility()
    
    if ApplyFreezeButtonVisual then ApplyFreezeButtonVisual() end
    if applySavedPositions then applySavedPositions() end
    if updateHUDLayouts then updateHUDLayouts() end
    
    return true
end

updatePageDisplay = function()
    if UI._4pages and UI._2Routenumber then
        UI._4pages.Text = tostring(State.totalPages)
        UI._2Routenumber.Text = tostring(State.currentPage)
    end
end


toggleFavorite = function(emoteId, emoteName)
    local found = false
    local index = 0

    for i, fav in pairs(State.favoriteEmotes) do
        if tostring(fav.id) == tostring(emoteId) then
            found = true
            index = i
            break
        end
    end

    if found then
        table.remove(State.favoriteEmotes, index)
        getgenv().Notify({
            Title = 'Aphelion | Favorite System',
            Content = '🗑️ Removed "' .. emoteName .. '" from favorites',
            Duration = 3
        })
    else
        table.insert(State.favoriteEmotes, {
            id = emoteId,
            name = emoteName .. " - ⭐"
        })
        getgenv().Notify({
            Title = 'Aphelion | Favorite System',
            Content = '✅ Added "' .. emoteName .. '" to favorites',
            Duration = 3
        })
    end

    State.EmotePages.Sets[State.currentEmotePageName] = DeepCopy(State.favoriteEmotes)
    State.SaveEmotePages(State.EmotePages)

    State.favoriteSetVersion = State.favoriteSetVersion + 1
    State.totalPages = calculateTotalPages()
    updatePageDisplay()
    updateEmotes()
    updateAllFavoriteIcons()
end


toggleFavoriteAnimation = function(animationData)
    local found = false
    local index = 0

    for i, fav in pairs(State.favoriteAnimations) do
        if fav.id == animationData.id then
            found = true
            index = i
            break
        end
    end

    if found then
        table.remove(State.favoriteAnimations, index)
        getgenv().Notify({
            Title = 'Aphelion | Favorite System',
            Content = '🗑️ Removed "' .. animationData.name .. '" from favorites',
            Duration = 3
        })
    else
        table.insert(State.favoriteAnimations, {
            id = animationData.id,
            name = animationData.name .. " - ⭐",
            bundledItems = animationData.bundledItems,
            isCustomSet = IsCustomSetData(animationData),
            customSetName = IsCustomSetData(animationData) and (type(animationData.name) == "string" and animationData.name:gsub("%s*%-.*$", "") or animationData.name) or nil
        })
        getgenv().Notify({
            Title = 'Aphelion | Favorite System',
            Content = '✅ Added "' .. animationData.name .. '" to favorites',
            Duration = 3
        })
    end

    State.favoriteSetVersion = State.favoriteSetVersion + 1
    
    pcall(function()
        if not isfolder("7yd7") then makefolder("7yd7") end
        writefile(State.favoriteAnimationsFileName, HttpService:JSONEncode(State.favoriteAnimations))
    end)

    State.totalPages = calculateTotalPages()
    updatePageDisplay()
    updateAnimations()
    updateAllFavoriteIcons()
end



function setupEmoteClickDetection()
    if State.isMonitoringClicks then
        return
    end
    
    State.emoteMonitorToken = State.emoteMonitorToken + 1
    local token = State.emoteMonitorToken

    local function monitorEmotes()
        while State.favoriteEnabled and State.currentMode == "emote" and State.emoteMonitorToken == token do
            local success, frontFrame = pcall(function()
                return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
            end)

            if success and frontFrame then
                for _, connection in pairs(State.emoteClickConnections) do
                    if connection then
                        connection:Disconnect()
                    end
                end
                State.emoteClickConnections = {}

                local randomActive = isRandomSlotActive()
                for _, child in pairs(frontFrame:GetChildren()) do
                    if child:IsA("ImageLabel") and child.Image ~= "" and (not randomActive or child.Name ~= "1") then
                        local imageUrl = child.Image
                        local assetId = extractAssetId(imageUrl)
                        if assetId then
                            local isFavorite = isInFavorites(assetId)
                            updateFavoriteIcon(child, assetId, isFavorite)
                        end
                    end
                end

                applyEmotesButtonsActiveState()
            end

            task.wait(0.1)
        end
    end

    if State.favoriteEnabled then
        State.isMonitoringClicks = true
        task.spawn(monitorEmotes)
    end
end

applyAnimation = function(animationData)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    local animate = character:FindFirstChild("Animate")
    
    if not animate or not humanoid then
        getgenv().Notify({
            Title = 'Aphelion | Animation Error',
            Content = '❌ Animate or Humanoid not found',
            Duration = 3
        })
        return
    end
    
    local bundleId = animationData.id
    local bundledItems = animationData.bundledItems

    getgenv().lastPlayedAnimation = animationData
    Config.LastPlayedAnimationData = animationData
    task.spawn(SaveConfig)
    
        if not bundledItems and not animationData.isCustomSet then
        getgenv().Notify({
            Title = 'Aphelion | Animation Error', 
            Content = '??? No bundled items found',
            Duration = 3
        })
        return
    end
    
    if animationData.isCustomSet and not bundledItems then
        bundledItems = {"Custom-Animation"}
    end
    
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    
    local cacheKey = tostring(bundleId)
    local mappings = State.AnimationCache[cacheKey]
    
    if mappings and #mappings > 0 and mappings._version ~= 2 then
        mappings = nil
    end
    
        if animationData.isCustomSet then
            mappings = buildCustomSetMappings(GetCustomSetName(animationData) or animationData.name)
            if #mappings > 0 then
                mappings._version = 2
                State.AnimationCache[cacheKey] = mappings
                task.spawn(saveAnimationCache)
            end
    elseif not mappings then
        mappings = resolveAnimationMappings(bundledItems)
        if #mappings > 0 then
            mappings._version = 2
            State.AnimationCache[cacheKey] = mappings
            task.spawn(saveAnimationCache)
        end
    end
    
    if #mappings == 0 then return end
    
    local sorted = {}
    for _, m in ipairs(mappings) do
        if m.category:lower() == "idle" then
            table.insert(sorted, 1, m)
        else
            table.insert(sorted, m)
        end
    end
    
    local function applyAnimationToObject(animObj, animId, weights)
        if not animObj or not animObj:IsA("Animation") then return end

        animObj.AnimationId = animId

        if weights ~= nil then
            for _, child in ipairs(animObj:GetChildren()) do
                if child:IsA("NumberValue") and child.Name == "Weight" then
                    child:Destroy()
                end
            end
            for _, wVal in ipairs(weights) do
                local w = Instance.new("NumberValue")
                w.Name = "Weight"
                w.Value = wVal
                w.Parent = animObj
            end
        end
    end

    local mappingMap = {}
    for _, m in ipairs(sorted) do
        local cat = m.category:lower()
        if not mappingMap[cat] then
            mappingMap[cat] = { folderName = m.category, items = {} }
        end
        mappingMap[cat].items[m.name:lower()] = m
    end

    for cat, data in pairs(mappingMap) do
        local categoryFolder = animate:FindFirstChild(data.folderName)
        if not categoryFolder then
            continue
        end

        local items = data.items

        local sourceByName = {}
        for name, m in pairs(items) do
            sourceByName[name] = m
        end

        for _, animObj in ipairs(categoryFolder:GetChildren()) do
            if animObj:IsA("Animation") then
                local lowerName = animObj.Name:lower()
                local m = sourceByName[lowerName]
                if m then
                    sourceByName[lowerName] = nil
                    applyAnimationToObject(animObj, m.animationId, m.weights)
                    if animObj.Name ~= m.name then
                        animObj.Name = m.name
                    end
                else
                    animObj:Destroy()
                end
            end
        end

        for name, m in pairs(sourceByName) do
            local animObj = Instance.new("Animation")
            animObj.Name = m.name
            applyAnimationToObject(animObj, m.animationId, m.weights)
            animObj.Parent = categoryFolder
        end
    end
    
    if humanoid.MoveDirection.Magnitude == 0 then
        animate.Disabled = true
        animate.Disabled = false
    end
end

function playAnimationPreview(animationData)
    local _, humanoid = getCharacterAndHumanoid()
    if not humanoid then return false end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end

    local bundledItems = animationData and animationData.bundledItems
    if not bundledItems then return false end
    
    local bundleId = animationData.id
    local cacheKey = tostring(bundleId)
    local mappings = State.AnimationCache[cacheKey]
    
    if not mappings then
        mappings = resolveAnimationMappings(bundledItems)
        if #mappings > 0 then
            State.AnimationCache[cacheKey] = mappings
            task.spawn(saveAnimationCache)
        end
    end
    
    if #mappings == 0 then return false end
    
    local m = mappings[1]
    local animation = Instance.new("Animation")
    animation.AnimationId = m.animationId
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if ok and track then
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        if State.speedEmoteEnabled or State.emotesWalkEnabled then
            track:Play()
        end
        State.currentEmoteTrack = track
        if State.speedEmoteEnabled then
            local speedVal = tonumber(UI and UI.SpeedBox and UI.SpeedBox.Text) or Config.EmoteSpeed or 1
            track:AdjustSpeed(speedVal)
        end
        return true
    end

    return false
end

handleSectorAction = function(index)
    if tick() - State.lastActionTick < 0.25 then return end
    State.lastActionTick = tick()

    if State.customAnimationEditorActive and (not State.customAnimationEditingKey or not State.customAnimationEditingName or not (State.CustomAnimOverlay and State.CustomAnimOverlay.Parent)) then
        if State.exitCustomAnimationEditor then
            State.exitCustomAnimationEditor()
        else
            State.customAnimationEditorActive = false
        end
    end

    local randomActive = isRandomSlotActive()
    if index == 1 and randomActive then
        local itemData = pickRandomItemForMode()
        if not itemData then
            getgenv().Notify({
                Title = 'Aphelion | Random',
                Content = '? No valid random item found',
                Duration = 3
            })
            return
        end
        State.lastRadialActionTime = tick()

        if State.customAnimationEditorActive then
            local animIdToSave = itemData.id
            local cat = State.customAnimationEditingKey
            local name = State.customAnimationEditingName
            if State.CustomAnimations.Sets[State.currentCustomAnimationName] and cat and name then
                if State.currentMode == "emote" or (State.currentMode == "animation" and not itemData.bundledItems) then
                    local resolved = resolveEmoteToAnimationId(itemData.id)
                    if resolved then animIdToSave = resolved end
                end
                if not State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] then
                    State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] = {}
                end
                State.CustomAnimations.Sets[State.currentCustomAnimationName][cat][name] = animIdToSave
                State.SaveCustomAnimations(State.CustomAnimations)
                getgenv().Notify({ Title = "Aphelion | Saved", Content = "✅ Saved " .. name, Duration = 3 })
                if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
                if refreshCustomAnimationState then refreshCustomAnimationState(true) end
                State.exitCustomAnimationEditor()
            end
            return
        end

        if State.favoriteEnabled then
            if State.currentMode == "animation" then
                if not isInFavorites(itemData.id) then
                    toggleFavoriteAnimation(itemData)
                end
            else
                if not isInFavorites(itemData.id) then
                    toggleFavorite(itemData.id, itemData.name)
                end
            end
            return
        end

        if State.currentMode == "animation" then
            if stopCurrentEmote then stopCurrentEmote() end
            applyAnimation(itemData)
            State.lastRandomAnimationId = itemData.id
            if not State.favoriteEnabled then
                pcall(function()
                    game:GetService("GuiService"):SetEmotesMenuOpen(false)
                end)
                pcall(function()
                    game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
                end)
            end
        else
            local _, hum = getCharacterAndHumanoid()
            if hum then
                pcall(function()
                    game:GetService("GuiService"):SetEmotesMenuOpen(false)
                end)
                pcall(function()
                    game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
                end)
                playRandomEmote(hum, itemData.id)
                State.lastRandomEmoteId = itemData.id
            end
        end
        return
    end

    if State.currentMode == "animation" then
        rebuildAnimationNormalCache()
    else
        rebuildEmoteNormalCache()
    end

    local function getEmoteAtIndex(idx)
        local categories = getCategoryStats()
        local accumulatedPages = 0
        
        for _, cat in ipairs(categories) do
            if State.currentPage <= accumulatedPages + cat.pages then
                local adjustedPage = State.currentPage - accumulatedPages
                local pageItems = getListSlice(cat.list, adjustedPage, cat.hasRandom)
                return pageItems[idx]
            end
            accumulatedPages = accumulatedPages + cat.pages
        end
        return nil
    end

    local slotOffset = randomActive and 1 or 0
    local itemData = getEmoteAtIndex(index - slotOffset)
    if not itemData then return end

    State.lastRadialActionTime = tick()

    if State.customAnimationEditorActive then
        local animIdToSave = itemData.id
        local cat = State.customAnimationEditingKey
        local name = State.customAnimationEditingName

        if State.currentMode == "emote" or (State.currentMode == "animation" and not itemData.bundledItems) then
            local resolved = resolveEmoteToAnimationId(itemData.id)
            if resolved then animIdToSave = resolved end
        end

        if State.currentMode == "animation" and itemData.bundledItems then
            local resolved = resolveAnimationMappings(itemData.bundledItems)
            if resolved and #resolved > 0 then
                local match
                for _, m in ipairs(resolved) do
                    if m.category:lower() == cat:lower() and m.name:lower() == name:lower() then
                        match = m
                        break
                    end
                end
                if not match then
                    for _, m in ipairs(resolved) do
                        if m.category:lower() == cat:lower() then
                            match = m
                            break
                        end
                    end
                end
                if match then
                    local extractedId = tonumber(urlToId(match.animationId))
                    if extractedId then
                        animIdToSave = extractedId
                    end
                end
                
                if animIdToSave == itemData.id and resolved[1] then
                    animIdToSave = tonumber(urlToId(resolved[1].animationId)) or itemData.id
                end
            end
        end

        if State.CustomAnimations.Sets[State.currentCustomAnimationName] and cat and name then
            if not State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] then
                State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] = {}
            end
            State.CustomAnimations.Sets[State.currentCustomAnimationName][cat][name] = animIdToSave
            State.SaveCustomAnimations(State.CustomAnimations)
            getgenv().Notify({ Title = "Aphelion | Saved", Content = "✅ Saved " .. name, Duration = 3 })
            
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(true) end
            State.exitCustomAnimationEditor()
        end
        return
    end

    if State.favoriteEnabled then
        if State.currentMode == "animation" then
            toggleFavoriteAnimation(itemData)
        else
            toggleFavorite(itemData.id, itemData.name)
        end
    else
        if State.currentMode == "animation" then
            applyAnimation(itemData)
            pcall(function()
                game:GetService("GuiService"):SetEmotesMenuOpen(false)
            end)
            pcall(function()
                game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
            end)
        else
            local _, hum = getCharacterAndHumanoid()
            if hum then
                if playRandomEmote then
                    playRandomEmote(hum, itemData.id)
                elseif playEmote then
                    playEmote(hum, itemData.id)
                end
            end
        end
    end

end

function clearAnimationSlotImages()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then
        return
    end

    for i = 1, State.itemsPerPage do
        local child = frontFrame:FindFirstChild(tostring(i))
        if child and child:IsA("ImageLabel") then
            local idValue = child:FindFirstChild("AnimationID")
            if idValue then
                idValue:Destroy()
            end
            if child.Image and child.Image:find("rbxthumb://type=BundleThumbnail") then
                child.Image = ""
            end
        end
    end
end


function monitorAnimations(token)
    while State.currentMode == "animation" and State.animationMonitorToken == token do
        local success, frontFrame = pcall(function()
            return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
        end)
        
        if success and frontFrame then
            for _, connection in pairs(State.emoteClickConnections) do
                if connection then
                    connection:Disconnect()
                end
            end
            State.emoteClickConnections = {}
            
            local favoritesToUse = _G.filteredFavoritesAnimationsForDisplay or State.favoriteAnimations
            local hasFavorites = #favoritesToUse > 0
            local favoritePagesCount = hasFavorites and calcPagesForList(#favoritesToUse, true) or 0
            local isInFavoritesPages = State.currentPage <= favoritePagesCount
            
            local currentPageAnimations = {}
            
            if isInFavoritesPages and hasFavorites then
                currentPageAnimations = getListSlice(favoritesToUse, State.currentPage, true)
            else
                local normalAnimations = {}
                for _, animation in pairs(State.filteredAnimations) do
                    if not isInFavorites(animation.id) then
                        table.insert(normalAnimations, animation)
                    end
                end
                
                local adjustedPage = State.currentPage - favoritePagesCount
                local isFirstNormalList = (favoritePagesCount == 0)
                currentPageAnimations = getListSlice(normalAnimations, adjustedPage, isFirstNormalList)
            end
            
            local randomActive = isRandomSlotActive()
            local buttonIndex = 1
            for _, child in pairs(frontFrame:GetChildren()) do
                if child:IsA("ImageLabel") and (not randomActive or child.Name ~= "1") then
                    if buttonIndex <= #currentPageAnimations then
                        local animationData = currentPageAnimations[buttonIndex]
                        
                        if State.favoriteEnabled then
                            local isFavorite = isInFavorites(animationData.id)
                            updateFavoriteIcon(child, animationData.id, isFavorite)
                        else
                            local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                            if favoriteIcon then
                                favoriteIcon:Destroy()
                            end
                        end
                        buttonIndex = buttonIndex + 1
                    else
                        local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                        if favoriteIcon then
                            favoriteIcon:Destroy()
                        end
                    end
                end
            end

        end
        
        task.wait(0.1)
    end
end

function stopEmoteClickDetection()
    State.isMonitoringClicks = false
    State.emoteMonitorToken = State.emoteMonitorToken + 1
    State.animationMonitorToken = State.animationMonitorToken + 1
    
    for _, connection in pairs(State.emoteClickConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    State.emoteClickConnections = {}
    
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        for _, child in pairs(frontFrame:GetChildren()) do
            if child:IsA("ImageLabel") then
                local clickDetector = child:FindFirstChild("ClickDetector")
                if clickDetector then
                    clickDetector:Destroy()
                end
                
                local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                if favoriteIcon then
                    favoriteIcon:Destroy()
                end
            end
        end
        applyEmotesButtonsActiveState()
    end
end


function fetchAllEmotes()
    if State.isLoading then
        return
    end
    State.isLoading = true

    local function applyData(data, total)
        State.emotesData = data
        State.totalEmotesLoaded = total
        State.originalEmotesData = State.emotesData
        State.filteredEmotes = State.emotesData
        State.emoteCacheVersion = State.emoteCacheVersion + 1
        State.totalPages = calculateTotalPages()
        State.currentPage = 1
        updatePageDisplay()
        updateEmotes()
        State.isLoading = false
    end

    local function fetchFromUrl()
        local success, result = pcall(function()
            local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json")
            if jsonContent and jsonContent ~= "" then
                local data = HttpService:JSONDecode(jsonContent)
                return data.data or {}
            else
                return nil
            end
        end)

        if success and result then
            local emoteData = {}
            local total = 0
            for _, item in pairs(result) do
                local id = tonumber(item.id)
                if id and id > 0 then
                    table.insert(emoteData, {id = id, name = item.name or ("Emote_" .. id)})
                    total = total + 1
                end
            end
            if #emoteData > 0 then
                pcall(function()
                    if not isfolder("7yd7") then makefolder("7yd7") end
                    writefile(State.EmoteDataCachePath, HttpService:JSONEncode(emoteData))
                end)
                return emoteData, total
            end
        end
        return nil, nil
    end

    local cacheData = nil
    pcall(function()
        if isfile and isfile(State.EmoteDataCachePath) then
            local json = readfile(State.EmoteDataCachePath)
            local decoded = HttpService:JSONDecode(json)
            if type(decoded) == "table" and #decoded > 0 then
                cacheData = decoded
            end
        end
    end)

    if cacheData then
        applyData(cacheData, #cacheData)
    else
        State.emotesData = {{id = 3360686498, name = "Stadium"},{id = 3360692915, name = "Tilt"},{id = 3576968026, name = "Shrug"},{id = 3360689775, name = "Salute"}}
        State.totalEmotesLoaded = #State.emotesData
        State.originalEmotesData = State.emotesData
        State.filteredEmotes = State.emotesData
        State.emoteCacheVersion = State.emoteCacheVersion + 1
        State.totalPages = calculateTotalPages()
        State.currentPage = 1
        updatePageDisplay()
        updateEmotes()
        State.isLoading = false
    end

    task.spawn(function()
        while true do
            local emoteData, total = fetchFromUrl()
            if emoteData then
                applyData(emoteData, total)
                getgenv().Notify({Title = 'Aphelion | Emote', Content = "📦 Emotes loaded", Duration = 3})
                return
            end
            task.wait(3)
        end
    end)
end

function fetchAllAnimations()
    if State.isLoading then
        return
    end
    State.isLoading = true
    State.animationsData = {}

    local function processCustomSets()
        if State.CustomAnimations and State.CustomAnimations.Order then
            for idx, customSetName in ipairs(State.CustomAnimations.Order) do
                if customSetName ~= "Default" and State.CustomAnimations.Sets[customSetName] then
                    local fakeId = -1000 - idx
                    local customSetData = State.CustomAnimations.Sets[customSetName]
                    local mappings = {}
                    for cat, anims in pairs(customSetData) do
                        if cat ~= "__meta" then
                            for name, id in pairs(anims) do
                                if tostring(id) ~= "0" then
                                    table.insert(mappings, {category = cat, name = name, animationId = "rbxassetid://" .. id})
                                end
                            end
                        end
                    end
                    mappings._version = 2
                    State.AnimationCache[tostring(fakeId)] = mappings

                    local customAnimationData = {
                        id = fakeId,
                        name = customSetName,
                        bundledItems = {"Custom-Animation"},
                        isCustomSet = true
                    }
                    table.insert(State.animationsData, 1, customAnimationData)
                end
            end
        end
    end

    local function finalize()
        State.originalAnimationsData = State.animationsData
        State.filteredAnimations = State.animationsData
        State.animationCacheVersion = State.animationCacheVersion + 1
        State.isLoading = false
    end

    processCustomSets()
    finalize()

    task.spawn(function()
        local success, result = pcall(function()
            local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json")
            if jsonContent and jsonContent ~= "" then
                local data = HttpService:JSONDecode(jsonContent)
                return data.data or {}
            end
            return nil
        end)

        local offsaleSuccess, offsaleResult
        if offsaleAnimationJson then
            offsaleSuccess, offsaleResult = pcall(function()
                local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniperoffsale.json")
                if jsonContent and jsonContent ~= "" then
                    local data = HttpService:JSONDecode(jsonContent)
                    return data.data or {}
                end
                return nil
            end)
        end

        if success or offsaleSuccess then
            local animationsData = {}
            local seenIds = {}

            if success and result then
                for _, item in pairs(result) do
                    local id = tonumber(item.id)
                    if id and id > 0 then
                        seenIds[id] = true
                        table.insert(animationsData, {
                            id = id,
                            name = item.name or ("Animation_" .. id),
                            bundledItems = item.bundledItems
                        })
                    end
                end
            end

            if offsaleSuccess and offsaleResult then
                for _, item in pairs(offsaleResult) do
                    local id = tonumber(item.id)
                    if id and id > 0 and not seenIds[id] then
                        seenIds[id] = true
                        table.insert(animationsData, {
                            id = id,
                            name = item.name or ("Animation_Offsale_" .. id),
                            bundledItems = item.bundledItems
                        })
                    end
                end
            end

            local prevMode = State.currentMode
            State.animationsData = animationsData
            processCustomSets()
            finalize()
            State.totalPages = calculateTotalPages()
            if State.currentPage > State.totalPages then
                State.currentPage = State.totalPages
            end
            if prevMode == "animation" then
                if State.animationSearchTerm ~= "" and searchAnimations then
                    searchAnimations(State.animationSearchTerm)
                else
                    updatePageDisplay()
                    updateAnimations()
                end
            end
        end
    end)
end

local function smartSearchMatch(name, searchTerm)
    if not searchTerm or searchTerm == "" then return true end
    name = name:lower()
    searchTerm = searchTerm:lower()
    
    for word in searchTerm:gmatch("%S+") do
        if not name:find(word, 1, true) then
            return false
        end
    end
    return true
end

function searchEmotes(searchTerm)
    if State.isLoading then
        getgenv().Notify({
            Title = 'Aphelion | Emote',
            Content = '⚠️ Loading please wait...',
            Duration = 5
        })
        return
    end

    searchTerm = searchTerm:lower()

    if searchTerm == "" then
        State.filteredEmotes = State.originalEmotesData
        State.emoteCacheVersion = State.emoteCacheVersion + 1
        if _G.originalFavoritesBackup then
            _G.originalFavoritesBackup = nil
        end
        _G.filteredFavoritesForDisplay = nil
    else
        local isIdSearch = searchTerm:match("^%d+$")
        
        local newFilteredList = {}
        
        if isIdSearch then
            for _, emote in pairs(State.originalEmotesData) do
                if tostring(emote.id) == searchTerm then
                    table.insert(newFilteredList, emote)
                end
            end
        else
            for _, emote in pairs(State.originalEmotesData) do
                if smartSearchMatch(emote.name, searchTerm) then
                    table.insert(newFilteredList, emote)
                end
            end
        end
        
        State.filteredEmotes = newFilteredList
        State.emoteCacheVersion = State.emoteCacheVersion + 1

        if not isIdSearch then
            if not _G.originalFavoritesBackup then
                _G.originalFavoritesBackup = {}
                for i, favorite in pairs(State.favoriteEmotes) do
                    _G.originalFavoritesBackup[i] = {
                        id = favorite.id,
                        name = favorite.name
                    }
                end
            end

            _G.filteredFavoritesForDisplay = {}
            for _, favorite in pairs(State.favoriteEmotes) do
                if smartSearchMatch(favorite.name, searchTerm) then
                    table.insert(_G.filteredFavoritesForDisplay, favorite)
                end
            end
        end
        applySearchSlot1Image()
    end

    State.totalPages = calculateTotalPages()
    State.currentPage = 1
    updatePageDisplay()
    updateEmotes()
end

function searchAnimations(searchTerm)
    if State.isLoading then
        getgenv().Notify({
            Title = 'Aphelion | Animation',
            Content = '⚠️ Loading please wait...',
            Duration = 5
        })
        return
    end

    searchTerm = searchTerm:lower()

    if searchTerm == "" then
        State.filteredAnimations = State.originalAnimationsData
        State.animationCacheVersion = State.animationCacheVersion + 1
        if _G.originalAnimationFavoritesBackup then
            _G.originalAnimationFavoritesBackup = nil
        end
        _G.filteredFavoritesAnimationsForDisplay = nil
    else
        local isIdSearch = searchTerm:match("^%d+$")
        
        local newFilteredList = {}
        
        if isIdSearch then
            for _, animation in pairs(State.originalAnimationsData) do
                if tostring(animation.id) == searchTerm then
                    table.insert(newFilteredList, animation)
                end
            end
        else
            for _, animation in pairs(State.originalAnimationsData) do
                if smartSearchMatch(animation.name, searchTerm) then
                    table.insert(newFilteredList, animation)
                end
            end
        end
        
        State.filteredAnimations = newFilteredList
        State.animationCacheVersion = State.animationCacheVersion + 1

        if not isIdSearch then
            if not _G.originalAnimationFavoritesBackup then
                _G.originalAnimationFavoritesBackup = {}
                for i, favorite in pairs(State.favoriteAnimations) do
                    _G.originalAnimationFavoritesBackup[i] = {
                        id = favorite.id,
                        name = favorite.name,
                        bundledItems = favorite.bundledItems
                    }
                end
            end

            _G.filteredFavoritesAnimationsForDisplay = {}
            for _, favorite in pairs(State.favoriteAnimations) do
                if smartSearchMatch(favorite.name, searchTerm) then
                    table.insert(_G.filteredFavoritesAnimationsForDisplay, favorite)
                end
            end
        end
        applySearchSlot1Image()
    end

    State.totalPages = calculateTotalPages()
    State.currentPage = 1
    updatePageDisplay()
    updateAnimations()
end

findCustomAnimationDataByName = function(setName)
    if not setName or setName == "Default" then
        return nil
    end

    for _, animationData in ipairs(State.originalAnimationsData or {}) do
        if animationData.isCustomSet and animationData.name == setName then
            return animationData
        end
    end

    for _, animationData in ipairs(State.animationsData or {}) do
        if animationData.isCustomSet and animationData.name == setName then
            return animationData
        end
    end

    return nil
end

refreshCustomAnimationState = function(applySelectedSet)
    local activeSearch = State.animationSearchTerm or ""
    local previousPage = State.currentPage

    fetchAllAnimations()

    if activeSearch ~= "" then
        searchAnimations(activeSearch)
    else
        State.filteredAnimations = State.originalAnimationsData
        State.animationCacheVersion = State.animationCacheVersion + 1
        State.totalPages = calculateTotalPages()
        local maxPage = math.max(State.totalPages, 1)
        if previousPage < 1 then
            State.currentPage = 1
        elseif previousPage > maxPage then
            State.currentPage = maxPage
        else
            State.currentPage = previousPage
        end
        updatePageDisplay()
        if State.currentMode == "animation" then
            updateAnimations()
        end
    end

    if applySelectedSet and State.currentCustomAnimationName ~= "Default" then
        local selectedAnimationData = findCustomAnimationDataByName(State.currentCustomAnimationName)
        if selectedAnimationData then
            pcall(function()
                applyAnimation(selectedAnimationData)
            end)
        end
    end
end

function goToPage(pageNumber)
    bumpImageUpdateToken()
    if pageNumber < 1 then
        State.currentPage = 1
    elseif pageNumber > State.totalPages then
        State.currentPage = State.totalPages
    else
        State.currentPage = pageNumber
    end
    updatePageDisplay()
    updateEmotes()
end

function previousPage()
    bumpImageUpdateToken()
    if State.currentPage <= 1 then
        State.currentPage = State.totalPages
    else
        State.currentPage = State.currentPage - 1
    end
    updatePageDisplay()
    updateEmotes()
end

function nextPage()
    bumpImageUpdateToken()
    if State.currentPage >= State.totalPages then
        State.currentPage = 1
    else
        State.currentPage = State.currentPage + 1
    end
    updatePageDisplay()
    updateEmotes()
end

function stopCurrentEmote()
    if State.currentEmoteTrack then
        State.currentEmoteTrack:Stop()
        State.currentEmoteTrack = nil
    end
end

playEmote = function(humanoid, emoteId)
    stopCurrentEmote()
    stopEmotes()

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. emoteId

    local success, animTrack = pcall(function()
        return humanoid.Animator:LoadAnimation(animation)
    end)

    if success and animTrack then
        State.currentEmoteTrack = animTrack
        State.currentEmoteTrack.Priority = Enum.AnimationPriority.Action
        State.currentEmoteTrack.Looped = true
        task.wait(0.1)
        if State.speedEmoteEnabled or State.emotesWalkEnabled then
            State.currentEmoteTrack:Play()

            if State.speedEmoteEnabled then
                local speedValue = tonumber(UI and UI.SpeedBox and UI.SpeedBox.Text) or 1
                State.currentEmoteTrack:AdjustSpeed(speedValue)
            end
        end
    end
end

playRandomEmote = function(humanoid, emoteId)
    stopCurrentEmote()
    stopEmotes()

    local ok, track = pcall(function()
        return humanoid:PlayEmoteAndGetAnimTrackById(emoteId)
    end)
    if ok and track and typeof(track) == "Instance" and track:IsA("AnimationTrack") then
        State.currentEmoteTrack = track
        if State.speedEmoteEnabled then
            local speedVal = tonumber(UI and UI.SpeedBox and UI.SpeedBox.Text) or Config.EmoteSpeed or 1
            track:AdjustSpeed(speedVal)
        end
    end
end

function onCharacterAdded(character)
    State.currentCharacter = character
    stopCurrentEmote()

    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

    -- Bundles are persistent character animation sets. Always restore the
    -- selected bundle after spawn/death; the legacy Auto Reload toggle remains
    -- available for older non-bundle animation behavior.
    if AphelionIsBundleAnimation(getgenv().lastPlayedAnimation) then
        AphelionRestoreSavedBundle(character, "respawn")
    end

    if getgenv().autoReloadEnabled and getgenv().lastPlayedAnimation and not AphelionIsBundleAnimation(getgenv().lastPlayedAnimation) then
        task.spawn(function()
            local player = game.Players.LocalPlayer
            if not player:HasAppearanceLoaded() then
                player.CharacterAppearanceLoaded:Wait()
            end
            local animate = character:WaitForChild("Animate")
            character:WaitForChild("HumanoidRootPart")
            applyAnimation(getgenv().lastPlayedAnimation)
            getgenv().Notify({
                Title = 'Aphelion | Auto Reload Animation',
                Content = '🔄 The last animation was automatically \n reapplied',
                Duration = 3
            })
            
            local lastAnim = getgenv().lastPlayedAnimation
            local cacheKey = tostring(lastAnim.id)
            local changed = false
            for i = 1, 7 do
                task.wait(0.01)
                if not character or not character.Parent or not humanoid then break end
                local mappings = State.AnimationCache[cacheKey]
                if not mappings and lastAnim.isCustomSet then
                    mappings = buildCustomSetMappings(GetCustomSetName and GetCustomSetName(lastAnim) or lastAnim.name)
                end
                if mappings and animate and animate.Parent then
                    for _, m in ipairs(mappings) do
                        local categoryFolder = animate:FindFirstChild(m.category)
                        if categoryFolder then
                            for _, animObj in ipairs(categoryFolder:GetChildren()) do
                                if animObj:IsA("Animation") and animObj.Name:lower() == m.name:lower() then
                                    if animObj.AnimationId ~= m.animationId then
                                        animObj.AnimationId = m.animationId
                                        if m.weights ~= nil then
                                            for _, child in ipairs(animObj:GetChildren()) do
                                                if child:IsA("NumberValue") and child.Name == "Weight" then
                                                    child:Destroy()
                                                end
                                            end
                                            for _, wVal in ipairs(m.weights) do
                                                local w = Instance.new("NumberValue")
                                                w.Name = "Weight"
                                                w.Value = wVal
                                                w.Parent = animObj
                                            end
                                        end
                                        changed = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if changed and humanoid.MoveDirection.Magnitude == 0 then
                animate.Disabled = true
                animate.Disabled = false
            end
        end)
    end

    local function isAnyEmoteEnhanceActive()
        return State.emotesWalkEnabled or State.speedEmoteEnabled
    end

    local function handleFrozenToolEquip()
        State.toolEquipped = true
        refreshToolAnimationIds()
    end

    local function handleFrozenToolUnequip()
        State.toolEquipped = false
        refreshToolAnimationIds()
    end

    if character:FindFirstChildOfClass("Tool") then
        State.toolEquipped = true
    end
    refreshToolAnimationIds()

    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            handleFrozenToolEquip()
        end
    end)

    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and not character:FindFirstChildOfClass("Tool") then
            handleFrozenToolUnequip()
        end
    end)

    animator.AnimationPlayed:Connect(function(animationTrack)
        if isDancing(character, animationTrack) then
            local playedEmoteId = urlToId(animationTrack.Animation.AnimationId)
            if playedEmoteId == "" or playedEmoteId == "0" then return end

            if State.toolEquipped then
                return
            end

            if State.emotesWalkEnabled then
                if State.currentEmoteTrack then
                    local currentEmoteId = urlToId(State.currentEmoteTrack.Animation.AnimationId)
                    if currentEmoteId == playedEmoteId then
                        return
                    else
                        stopCurrentEmote()
                    end
                end

                playEmote(humanoid, playedEmoteId)

                if currentEmoteTrack then
                    currentEmoteTrack.Ended:Connect(function()
                        if currentEmoteTrack == animationTrack then
                            currentEmoteTrack = nil
                        end
                    end)
                end
            end

            if State.speedEmoteEnabled and not State.emotesWalkEnabled then
                if State.currentEmoteTrack then
                    local currentEmoteId = urlToId(State.currentEmoteTrack.Animation.AnimationId)
                    if currentEmoteId == playedEmoteId then
                        return
                    else
                        stopCurrentEmote()
                    end
                end

                playEmote(humanoid, playedEmoteId)

                if currentEmoteTrack then
                    currentEmoteTrack.Ended:Connect(function()
                        if currentEmoteTrack == animationTrack then
                            currentEmoteTrack = nil
                        end
                    end)
                end
            end
        end
    end)

    humanoid.Died:Connect(function()
    if State.hudEditorActive and exitHUDEditor then exitHUDEditor() end
    State.emotesWalkEnabled = false
    State.speedEmoteEnabled = false
    State.favoriteEnabled = false
    State.toolEquipped = false
    State.currentEmoteTrack = nil

    stopEmotes()
        stopCurrentEmote()
    end)
end

function toggleEmoteWalk()
    State.emotesWalkEnabled = not State.emotesWalkEnabled
    ApplyFreezeButtonVisual()

    if State.emotesWalkEnabled then
        getgenv().Notify({
            Title = 'Aphelion | Emote Freeze',
            Content = "🔒 Emote freeze ON",
            Duration = 5
        })

        task.wait(0.1)
        stopCurrentEmote()
        if State.currentEmoteTrack and State.currentEmoteTrack.IsPlaying then
            State.currentEmoteTrack:AdjustSpeed(1)
        end
    else
        getgenv().Notify({
            Title = 'Aphelion | Emote Freeze',
            Content = '🔓 Emote freeze OFF',
            Duration = 5
        })
        task.wait(0.1)
        stopCurrentEmote()

        if State.currentEmoteTrack and State.currentEmoteTrack.IsPlaying and State.speedEmoteEnabled then
            local speedValue = tonumber(UI and UI.SpeedBox and UI.SpeedBox.Text) or 1
            State.currentEmoteTrack:AdjustSpeed(speedValue)
        elseif State.currentEmoteTrack and State.currentEmoteTrack.IsPlaying then
            State.currentEmoteTrack:AdjustSpeed(1)
        end
    end
end

function toggleSpeedEmote()
    State.speedEmoteEnabled = not State.speedEmoteEnabled
    updateSpeedBoxVisibility()

    if State.speedEmoteEnabled then
        getgenv().Notify({
            Title = 'Aphelion | Speed Emote',
            Content = "⚡ Speed Emote ON",
            Duration = 5
        })
        task.wait(0.1)
        stopCurrentEmote()
    else
        getgenv().Notify({
            Title = 'Aphelion | Speed Emote',
            Content = '⚡ Speed Emote OFF',
            Duration = 5
        })
        task.wait(0.1)
        stopCurrentEmote()
    end

    Config.EmoteSpeedEnabled = State.speedEmoteEnabled
    Config.EmoteSpeed = tonumber(UI and UI.SpeedBox and UI.SpeedBox.Text) or 1
    SaveConfig()
end

function toggleFavoriteMode()
    State.favoriteEnabled = not State.favoriteEnabled

    if State.favoriteEnabled then
        ApplyFavoriteButtonVisual()
        getgenv().Notify({
            Title = 'Aphelion | Favorite System',
            Content = "🔒 Favorite ON",
            Duration = 5
        })

        updateScriptPriorityOverlay()
        setEmotesButtonsActiveForFavorites()

        if State.currentMode == "emote" then
            setupEmoteClickDetection()
        else 
            updateAllFavoriteIcons()
        end
    else
        ApplyFavoriteButtonVisual()
        getgenv().Notify({
            Title = 'Aphelion | Favorite System',
            Content = '🔓 Favorite OFF',
            Duration = 3
        })
        
        if State.currentMode == "emote" then
            stopEmoteClickDetection()
        else
            updateAllFavoriteIcons()
        end
        clearCustomHitboxes()
        updateScriptPriorityOverlay()
    end

    pcall(function()
        local frontFrame = CoreGui.RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
        applyEmotesButtonsActiveState()
    end)
end

local clickCooldown = {}
local CLICK_COOLDOWN_TIME = 0.1

function safeButtonClick(buttonName, callback)
    if State.hudEditorActive then return end
    local currentTime = tick()
    if not clickCooldown[buttonName] or (currentTime - clickCooldown[buttonName]) > CLICK_COOLDOWN_TIME then
        clickCooldown[buttonName] = currentTime
        callback()
    end
end

function setupAnimationClickDetection()
    if State.isMonitoringClicks then
        return
    end
    
    if State.currentMode == "animation" then
        State.animationMonitorToken = State.animationMonitorToken + 1
        local token = State.animationMonitorToken
        State.isMonitoringClicks = true
        task.spawn(function()
            monitorAnimations(token)
        end)
    end
end

function toggleAutoReload()
    getgenv().autoReloadEnabled = not getgenv().autoReloadEnabled
    Config.AutoReloadEnabled = getgenv().autoReloadEnabled
    task.spawn(SaveConfig)
    
    if getgenv().autoReloadEnabled then
        getgenv().Notify({
            Title = 'Aphelion | Auto Reload Animation',
            Content = "🔄 Auto Reload ON",
            Duration = 5
        })
    else
        getgenv().Notify({
            Title = 'Aphelion | Auto Reload Animation',
            Content = '🔄 Auto Reload OFF',
            Duration = 3
        })
    end
end

function connectEvents()
    disconnectAllConnections()

    if UI._1left then
        table.insert(State.guiConnections, UI._1left.MouseButton1Click:Connect(function()
            safeButtonClick("PrevPage", previousPage)
        end))
    end

    if UI._9right then
        table.insert(State.guiConnections, UI._9right.MouseButton1Click:Connect(function()
            safeButtonClick("NextPage", nextPage)
        end))
    end

    if UI._2Routenumber then
        table.insert(State.guiConnections, UI._2Routenumber.FocusLost:Connect(function(enterPressed)
            if State.hudEditorActive then return end
            local pageNum = tonumber(UI._2Routenumber.Text)
            if pageNum then
                goToPage(pageNum)
            else
                UI._2Routenumber.Text = tostring(State.currentPage)
            end
        end))
    end

    if UI.Search then
        table.insert(State.guiConnections, UI.Search.Changed:Connect(function(property)
            if State.hudEditorActive then return end
            if property == "Text" then
                if State.suppressSearch then
                    return
                end
                if State.currentMode == "emote" then
                    State.emoteSearchTerm = UI.Search.Text
                    searchEmotes(State.emoteSearchTerm)
                else
                    State.animationSearchTerm = UI.Search.Text
                    searchAnimations(State.animationSearchTerm)
                end
            end
        end))
    end

    local SECTOR_COUNT = 8
    local SECTOR_ANGLE = 360 / SECTOR_COUNT
    
    local function isAuthenticPageActive()
        if not (Config.AuthenticFirstPage and State.currentMode == "emote") then
            return false
        end
        local authenticEmotes = getgenv().OwnedAuthenticEmotes or {}
        local authenticPagesCount = calcPagesForList(#authenticEmotes, false)
        return #authenticEmotes > 0 and State.currentPage <= authenticPagesCount
    end

    table.insert(State.guiConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if State.hudEditorActive then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        
        local exists, emotesWheel = checkEmotesMenuExists()
        local isRecentlyVisible = (tick() - State.lastWheelVisibleTime < 0.15)
        if not (exists and (emotesWheel.Visible or isRecentlyVisible)) then return end

        
        local actualPos = Vector2.new(input.Position.X, input.Position.Y)

        local absPos = emotesWheel.AbsolutePosition
        local absSize = emotesWheel.AbsoluteSize

        local inXBounds = (actualPos.X >= absPos.X) and (actualPos.X <= absPos.X + absSize.X)
        local inYBounds = (actualPos.Y >= absPos.Y) and (actualPos.Y <= absPos.Y + absSize.Y)
        if not (inXBounds and inYBounds) then return end

        local center = absPos + (absSize / 2)
        local dx = actualPos.X - center.X
        local dy = actualPos.Y - center.Y

        local distance = math.sqrt(dx*dx + dy*dy)
        local radius = math.min(absSize.X, absSize.Y) * 0.5
        if distance > radius then return end
        local dynamicDeadzone = radius * 0.2
        if distance < dynamicDeadzone then return end

        local angle = math.deg(math.atan2(dy, dx))
        local correctedAngle = (angle + 90 + (SECTOR_ANGLE / 2)) % 360
        local index = math.floor(correctedAngle / SECTOR_ANGLE) + 1
        if not (State.favoriteEnabled or State.currentMode == "animation" or isAuthenticPageActive() or (index == 1 and isRandomSlotActive())) then return end

        handleSectorAction(index)
    end))

    local function bindWheelHotkeys()
        if not ContextActionService then return end

        local keyToIndex = {
            [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
            [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6, [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
            [Enum.KeyCode.KeypadOne] = 1, [Enum.KeyCode.KeypadTwo] = 2, [Enum.KeyCode.KeypadThree] = 3, [Enum.KeyCode.KeypadFour] = 4,
            [Enum.KeyCode.KeypadFive] = 5, [Enum.KeyCode.KeypadSix] = 6, [Enum.KeyCode.KeypadSeven] = 7, [Enum.KeyCode.KeypadEight] = 8
        }

        local function onHotkey(actionName, inputState, inputObject)
            if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
            if State.hudEditorActive then return Enum.ContextActionResult.Pass end
            if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
            if State.customAnimationEditorActive and (not State.customAnimationEditingKey or not State.customAnimationEditingName or not (State.CustomAnimOverlay and State.CustomAnimOverlay.Parent)) then
                if State.exitCustomAnimationEditor then
                    State.exitCustomAnimationEditor()
                else
                    State.customAnimationEditorActive = false
                end
            end

            local index = keyToIndex[inputObject.KeyCode]
            if not index then return Enum.ContextActionResult.Pass end
            
            if isAuthenticPageActive() then
                return Enum.ContextActionResult.Pass
            end

            if not (State.favoriteEnabled or State.currentMode == "animation" or (index == 1 and isRandomSlotActive())) then
                return Enum.ContextActionResult.Pass
            end

            local exists, emotesWheel = checkEmotesMenuExists()
            local isRecentlyVisible = (tick() - State.lastWheelVisibleTime < 0.15)
            if not (exists and (emotesWheel.Visible or isRecentlyVisible)) then return Enum.ContextActionResult.Pass end

            local success, frontFrame = pcall(function()
                return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
            end)
            if success and frontFrame then
                local target = frontFrame:FindFirstChild(tostring(index))
                if target and target:IsA("ImageLabel") and target.Image ~= "" then
                    handleSectorAction(index)
                    if State.currentMode == "animation" and not State.favoriteEnabled then
                        pcall(function()
                            game:GetService("GuiService"):SetEmotesMenuOpen(false)
                        end)
                        pcall(function()
                            game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
                        end)
                    end
                    return Enum.ContextActionResult.Sink
                end
            end

            return Enum.ContextActionResult.Pass
        end

        ContextActionService:UnbindAction("Aphelion_EmoteWheelHotkeys")
        ContextActionService:BindActionAtPriority(
            "Aphelion_EmoteWheelHotkeys",
            onHotkey,
            false,
            (Enum.ContextActionPriority.High.Value + 50),
            Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
            Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight,
            Enum.KeyCode.KeypadOne, Enum.KeyCode.KeypadTwo, Enum.KeyCode.KeypadThree, Enum.KeyCode.KeypadFour,
            Enum.KeyCode.KeypadFive, Enum.KeyCode.KeypadSix, Enum.KeyCode.KeypadSeven, Enum.KeyCode.KeypadEight
        )
    end

    bindWheelHotkeys()

    if UI.EmoteWalkButton then
        table.insert(State.guiConnections, UI.EmoteWalkButton.MouseButton1Click:Connect(function()
            safeButtonClick("EmoteWalk", toggleEmoteWalk)
        end))
    end

    if UI.Favorite then
        table.insert(State.guiConnections, UI.Favorite.MouseButton1Click:Connect(function()
            safeButtonClick("Favorite", toggleFavoriteMode)
        end))
    end

    if UI.SpeedEmote then
        table.insert(State.guiConnections, UI.SpeedEmote.MouseButton1Click:Connect(function()
            safeButtonClick("SpeedEmote", toggleSpeedEmote)
        end))
    end

    if UI.Reload then
        table.insert(State.guiConnections, UI.Reload.MouseButton1Click:Connect(function()
            safeButtonClick("AutoReload", toggleAutoReload)
        end))
    end

    if UI.Changepage then
        table.insert(State.guiConnections, UI.Changepage.MouseButton1Click:Connect(function()
            safeButtonClick("ChangePage", function()
                stopEmoteClickDetection()
                if State.animImageSpamConn then
                    State.animImageSpamConn:Disconnect()
                    State.animImageSpamConn = nil
                    State.animImageSpamMap = nil
                    State.animImageSpamTicks = nil
                    State.animImageSpamToken = State.animImageSpamToken + 1
                end
                
                if State.currentMode == "emote" then
                    State.savedEmotePage = State.currentPage
                    State.currentMode = "animation"
                    
                    local function applyAnimationModeUI()
                        State.suppressSearch = true
                        UI.Search.Text = State.animationSearchTerm
                        State.suppressSearch = false
                        if State.animationSearchTerm ~= "" then
                            searchAnimations(State.animationSearchTerm)
                        end
                        State.currentPage = State.savedAnimPage
                        State.totalPages = calculateTotalPages()
                        updatePageDisplay()
                        updateEmotes() 
                        updateScriptPriorityOverlay()
                        State.animationMonitorToken = State.animationMonitorToken + 1
                        local token = State.animationMonitorToken
                        State.isMonitoringClicks = true
                        task.spawn(function()
                            monitorAnimations(token)
                        end)
                    end

                    applyAnimationModeUI()
                    
                    local beforeVersion = State.animationCacheVersion
                    task.spawn(function()
                        fetchAllAnimations()
                        if State.currentMode ~= "animation" then return end
                        if State.animationCacheVersion ~= beforeVersion then
                            applyAnimationModeUI()
                        end
                    end)
                    
                    getgenv().Notify({
                        Title = 'Aphelion | Animation',
                        Content = '📄 Changed to Emote > Animation Mode',
                        Duration = 3
                    })

                else
                    State.savedAnimPage = State.currentPage
                    State.currentMode = "emote"
                    clearCustomHitboxes()
                    State.suppressSearch = true
                    UI.Search.Text = State.emoteSearchTerm
                    State.suppressSearch = false
                    if State.emoteSearchTerm ~= "" and searchEmotes then
                        searchEmotes(State.emoteSearchTerm)
                    end
                    State.currentPage = State.savedEmotePage
                    State.totalPages = calculateTotalPages()
                    updatePageDisplay() 
                    updateEmotes()
                    updateScriptPriorityOverlay()
                    
                    if State.favoriteEnabled then
                        setupEmoteClickDetection()
                    end
                    
                    getgenv().Notify({
                        Title = 'Aphelion | Emote', 
                        Content = '📄 Changed to Animation > Emote Mode',
                        Duration = 3
                    })
                end
            end)
        end))
    end



    if UI.SpeedBox then
        table.insert(State.guiConnections, UI.SpeedBox.FocusLost:Connect(function()
            if State.hudEditorActive then return end
            local speedValue = tonumber(UI and UI.SpeedBox and UI.SpeedBox.Text) or 1
            Config.EmoteSpeed = speedValue
            SaveConfig()
        end))
    end

    table.insert(State.guiConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if State.hudEditorActive then return end
        local exists, emotesWheel = checkEmotesMenuExists()
        if not (exists and emotesWheel.Visible) then return end

        if input.KeyCode == Enum.KeyCode.Q then
            if UserInputService:GetFocusedTextBox() then return end
            previousPage()
        elseif input.KeyCode == Enum.KeyCode.E then
            if UserInputService:GetFocusedTextBox() then return end
            nextPage()
        elseif (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            if not UserInputService:GetFocusedTextBox() and UI.Search then
                UI.Search:CaptureFocus()
            end
        end
    end))
end






function calculateSnap(element, newPos, currentName, allMovable)
    local SNAP_THRESHOLD = 8
    local parent = element.Parent
    if not parent then return newPos, nil, nil end
    local ps = parent.AbsoluteSize
    local pp = parent.AbsolutePosition
    local absX = pp.X + newPos.X.Scale * ps.X + newPos.X.Offset
    local absY = pp.Y + newPos.Y.Scale * ps.Y + newPos.Y.Offset
    local absW = element.AbsoluteSize.X
    local absH = element.AbsoluteSize.Y
    local sX, sY = absX, absY
    local didX, didY = false, false
    local guideX, guideY
    for oName, oEl in pairs(allMovable) do
        if oName ~= currentName then
            local oX = oEl.AbsolutePosition.X
            local oY = oEl.AbsolutePosition.Y
            local oW = oEl.AbsoluteSize.X
            local oH = oEl.AbsoluteSize.Y
            if not didX then
                if math.abs(absX - oX) < SNAP_THRESHOLD then sX = oX; didX = true; guideX = oX end
                if math.abs(absX - (oX + oW)) < SNAP_THRESHOLD then sX = oX + oW; didX = true; guideX = oX + oW end
                if math.abs((absX + absW) - oX) < SNAP_THRESHOLD then sX = oX - absW; didX = true; guideX = oX end
                if math.abs((absX + absW) - (oX + oW)) < SNAP_THRESHOLD then sX = oX + oW - absW; didX = true; guideX = oX + oW end
                if math.abs((absX + absW/2) - (oX + oW/2)) < SNAP_THRESHOLD then sX = oX + oW/2 - absW/2; didX = true; guideX = oX + oW/2 end
            end
            if not didY then
                if math.abs(absY - oY) < SNAP_THRESHOLD then sY = oY; didY = true; guideY = oY end
                if math.abs(absY - (oY + oH)) < SNAP_THRESHOLD then sY = oY + oH; didY = true; guideY = oY + oH end
                if math.abs((absY + absH) - oY) < SNAP_THRESHOLD then sY = oY - absH; didY = true; guideY = oY end
                if math.abs((absY + absH) - (oY + oH)) < SNAP_THRESHOLD then sY = oY + oH - absH; didY = true; guideY = oY + oH end
                if math.abs((absY + absH/2) - (oY + oH/2)) < SNAP_THRESHOLD then sY = oY + oH/2 - absH/2; didY = true; guideY = oY + oH/2 end
            end
        end
    end
    local fsx = (sX - pp.X) / ps.X
    local fsy = (sY - pp.Y) / ps.Y
    return UDim2.new(fsx, newPos.X.Offset, fsy, newPos.Y.Offset), guideX, guideY
end

local function hudColorToRGB(c)
    return {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
end

local function copyProps(name)
    local src = Config.HUDProperties and Config.HUDProperties[name]
    if not src then return {} end
    local out = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            local t = {}
            for i, sv in pairs(v) do
                t[i] = sv
            end
            out[k] = t
        else
            out[k] = v
        end
    end
    return out
end

local function captureHUDState(n, el)
    if not n or not el then return nil end
    local cR = el:FindFirstChildWhichIsA("UICorner")
    local s = {
        name = n,
        pos = el.Position,
        size = el.Size,
        z = el.ZIndex,
        bgTrans = el.BackgroundTransparency,
        bgColor = el.BackgroundColor3,
        radius = cR and cR.CornerRadius or nil
    }
    if el:IsA("ImageLabel") or el:IsA("ImageButton") then
        s.imgTrans = el.ImageTransparency
        s.imgColor = el.ImageColor3
    end
    if el:IsA("TextLabel") or el:IsA("TextBox") then
        s.text = el.Text
        s.textTrans = el.TextTransparency
        s.textColor = el.TextColor3
        if el:IsA("TextBox") then
            s.placeholder = el.PlaceholderText
        end
    end
    s.props = copyProps(n)
    return s
end

local function pushUndo(state)
    if not state then return end
    if not HUD.UndoStack then HUD.UndoStack = {} end
    table.insert(HUD.UndoStack, state)
    if #HUD.UndoStack > 50 then
        table.remove(HUD.UndoStack, 1)
    end
end

local function sameUDim2(a, b)
    return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end

local function sameUDim(a, b)
    return a.Scale == b.Scale and a.Offset == b.Offset
end

local function sameColor(a, b)
    return math.abs(a.R - b.R) < 0.001 and math.abs(a.G - b.G) < 0.001 and math.abs(a.B - b.B) < 0.001
end

local function applyHUDState(state)
    if not state or not state.name then return end
    local all = getAllHUDObjects()
    local el = all[state.name]
    if not el then return end

    if state.pos then
        el.Position = state.pos
        if not Config.HUDPositions then Config.HUDPositions = {} end
        Config.HUDPositions[state.name] = {state.pos.X.Scale, state.pos.X.Offset, state.pos.Y.Scale, state.pos.Y.Offset}
    end
    if state.size then
        el.Size = state.size
        if not Config.HUDSizes then Config.HUDSizes = {} end
        Config.HUDSizes[state.name] = {state.size.X.Scale, state.size.X.Offset, state.size.Y.Scale, state.size.Y.Offset}
    end
    if state.z ~= nil then el.ZIndex = state.z end
    if state.props and state.props.BgTrans ~= nil then el.BackgroundTransparency = state.bgTrans end
    if state.props and state.props.BgColor then el.BackgroundColor3 = state.bgColor end
    if el:IsA("ImageLabel") or el:IsA("ImageButton") then
        if state.props and state.props.ImgTrans ~= nil then el.ImageTransparency = state.imgTrans end
        if state.props and state.props.ImgColor then el.ImageColor3 = state.imgColor end
    end
    if el:IsA("TextLabel") or el:IsA("TextBox") then
        if state.props and state.props.Text ~= nil then el.Text = state.text end
        if state.props and state.props.TextTransparency ~= nil then el.TextTransparency = state.textTrans end
        if state.props and state.props.TxtColor then el.TextColor3 = state.textColor end
        if el:IsA("TextBox") and state.placeholder ~= nil then
            el.PlaceholderText = state.placeholder
        end
    end
    if state.radius then
        local cR = el:FindFirstChildWhichIsA("UICorner")
        if cR then cR.CornerRadius = state.radius end
    end

    if not Config.HUDProperties then Config.HUDProperties = {} end
    Config.HUDProperties[state.name] = state.props or {}
    SaveConfig()
    pcall(function() updateGUIColors() end)
end

local function undoLastHUD()
    if not State.hudEditorActive then return end
    if not HUD.UndoStack or #HUD.UndoStack == 0 then return end
    local state = table.remove(HUD.UndoStack)
    applyHUDState(state)
end

local function normalizeUDim2(u, ps)
    if not u or not ps or ps.X <= 0 or ps.Y <= 0 then
        return nil
    end
    local sx = u.X.Scale + (u.X.Offset / ps.X)
    local sy = u.Y.Scale + (u.Y.Offset / ps.Y)
    return sx, 0, sy, 0
end

local function tableToUDim2(v)
    if type(v) ~= "table" or #v ~= 4 then return nil end
    return UDim2.new(v[1], v[2], v[3], v[4])
end

local function normalizeHUDScale()
    local elems = getAllHUDObjects()
    for name, el in pairs(elems) do
        local parent = el and el.Parent
        if parent then
            local hasLayout = parent:FindFirstChildOfClass("UIListLayout")
            if hasLayout and not HUD.IsUnlocked then
                return
            end
            local ps = parent.AbsoluteSize
            if Config.HUDPositions and Config.HUDPositions[name] then
                local v = Config.HUDPositions[name]
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local nsx, nox, nsy, noy = normalizeUDim2(UDim2.new(sx, ox, sy, oy), ps)
                        if nsx then
                            Config.HUDPositions[name] = {nsx, nox, nsy, noy}
                            el.Position = UDim2.new(nsx, nox, nsy, noy)
                        end
                    end
                end
            end
            if Config.HUDSizes and Config.HUDSizes[name] then
                local v = Config.HUDSizes[name]
                if type(v) == "table" and #v == 4 then
                    local def = HUD.DefaultSizes and HUD.DefaultSizes[name]
                    local isDefault = def and sameUDim2(def, tableToUDim2(v) or UDim2.new(0,0,0,0))
                    if isDefault then
                        return
                    end
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local nsx, nox, nsy, noy = normalizeUDim2(UDim2.new(sx, ox, sy, oy), ps)
                        if nsx then
                            Config.HUDSizes[name] = {nsx, nox, nsy, noy}
                            el.Size = UDim2.new(nsx, nox, nsy, noy)
                        end
                    end
                end
            end
        end
    end
    SaveConfig()
end

local function normalizeHUDScaleForElement(name, el, normalizePos, normalizeSize)
    if not name or not el or not el.Parent then return end
    if normalizePos == nil then normalizePos = true end
    if normalizeSize == nil then normalizeSize = true end
    local parent = el.Parent
    local hasLayout = parent:FindFirstChildOfClass("UIListLayout")
    if hasLayout and not HUD.IsUnlocked then return end
    local ps = parent.AbsoluteSize
    if ps.X <= 0 or ps.Y <= 0 then return end

    if normalizePos then
        local nsx, nox, nsy, noy = normalizeUDim2(el.Position, ps)
        if nsx then
            el.Position = UDim2.new(nsx, nox, nsy, noy)
            if not Config.HUDPositions then Config.HUDPositions = {} end
            Config.HUDPositions[name] = {nsx, nox, nsy, noy}
        end
    end

    if normalizeSize then
        local nsx, nox, nsy, noy = normalizeUDim2(el.Size, ps)
        if nsx then
            el.Size = UDim2.new(nsx, nox, nsy, noy)
            if not Config.HUDSizes then Config.HUDSizes = {} end
            Config.HUDSizes[name] = {nsx, nox, nsy, noy}
        end
    end

    SaveConfig()
end

function selectHUDElement(name, element)
    if HUD.SelectedElement == element then return end
    HUD.SelectedElement = element
    HUD.LastTouchedElement = element
    HUD.LastTouchedName = name

    local parent = element.Parent
    if UI and parent and (parent == UI.Top or parent == UI.Under) then
        local key = parent.Name
        local l = parent:FindFirstChildOfClass("UIListLayout") or (HUD.Layouts and HUD.Layouts[key])
        if l then
            HUD.Layouts[key] = l
            HUD.LayoutsRemoved[key] = true
            l.Parent = nil
        end
    end

    for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
    HUD.ResizeHandles = {}
    for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
    HUD.ResizeConnections = {}

    local selectionGui = HUD.SelectionGui
    local wrapper = Instance.new("Frame")
    wrapper.Name = "SelectionWrapper"
    wrapper.BackgroundTransparency = 1
    wrapper.ZIndex = 1
    wrapper.Parent = selectionGui

    table.insert(HUD.ResizeHandles, wrapper)
    table.insert(HUD.ResizeConnections, RunService.RenderStepped:Connect(function()
        if HUD.SelectedElement == element and element.Parent then
            wrapper.Size = UDim2.fromOffset(element.AbsoluteSize.X, element.AbsoluteSize.Y)
            wrapper.Position = UDim2.fromOffset(element.AbsolutePosition.X, element.AbsolutePosition.Y)
        end
    end))

    local handlePositions = {
        TopLeft = {UDim2.new(0,0,0,0), Vector2.new(-1, -1)},
        Top = {UDim2.new(0.5,0,0,0), Vector2.new(0, -1)},
        TopRight = {UDim2.new(1,0,0,0), Vector2.new(1, -1)},
        Left = {UDim2.new(0,0,0.5,0), Vector2.new(-1, 0)},
        Right = {UDim2.new(1,0,0.5,0), Vector2.new(1, 0)},
        BottomLeft = {UDim2.new(0,0,1,0), Vector2.new(-1, 1)},
        Bottom = {UDim2.new(0.5,0,1,0), Vector2.new(0, 1)},
        BottomRight = {UDim2.new(1,0,1,0), Vector2.new(1, 1)}
    }

    for dir, data in pairs(handlePositions) do
        local h = Instance.new("Frame")
        h.Name = "Resize_"..dir
        h.Size = UDim2.new(0, 8, 0, 8)
        h.AnchorPoint = Vector2.new(0.5, 0.5)
        h.Position = data[1]
        h.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        h.BorderColor3 = Color3.fromRGB(0, 0, 0)
        h.ZIndex = 11000
        h.Parent = wrapper

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 4, 1, 4)
        btn.Position = UDim2.new(0.5, 0, 0.5, 0)
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 11001
        btn.Parent = h

        local resizing = false
        local dragStart
        local startAbsSize
        local startAbsPos
        local resizeUndo

        table.insert(HUD.ResizeConnections, btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeUndo = captureHUDState(name, element)
                dragStart = input.Position
                startAbsSize = element.AbsoluteSize
                startAbsPos = element.AbsolutePosition
            end
        end))

        table.insert(HUD.ResizeConnections, UserInputService.InputChanged:Connect(function(input)
            if not resizing then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                local pSize = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                
                local dirVec = data[2]
                local newW = startAbsSize.X + (dirVec.X == 1 and delta.X or (dirVec.X == -1 and -delta.X or 0))
                local newH = startAbsSize.Y + (dirVec.Y == 1 and delta.Y or (dirVec.Y == -1 and -delta.Y or 0))
                local newX = startAbsPos.X + (dirVec.X == -1 and delta.X or 0)
                local newY = startAbsPos.Y + (dirVec.Y == -1 and delta.Y or 0)

                if newW < 20 then
                    if dirVec.X == -1 then newX = newX - (20 - newW) end
                    newW = 20
                end
                if newH < 20 then
                    if dirVec.Y == -1 then newY = newY - (20 - newH) end
                    newH = 20
                end

                local parentPos = element.Parent and element.Parent.AbsolutePosition or Vector2.new(0,0)
                local relX = (newX - parentPos.X) / pSize.X
                local relY = (newY - parentPos.Y) / pSize.Y

                element.Size = UDim2.new(newW / pSize.X, 0, newH / pSize.Y, 0)
                element.Position = UDim2.new(relX, 0, relY, 0)
            end
        end))

        table.insert(HUD.ResizeConnections, UserInputService.InputEnded:Connect(function(input)
             if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                 if resizing then
                     resizing = false
                     if resizeUndo and (not sameUDim2(resizeUndo.pos, element.Position) or not sameUDim2(resizeUndo.size, element.Size)) then
                         pushUndo(resizeUndo)
                     end
                     local rPs = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                     local pXs = element.Position.X.Scale + (element.Position.X.Offset / rPs.X)
                     local pYs = element.Position.Y.Scale + (element.Position.Y.Offset / rPs.Y)
                     Config.HUDPositions[name] = {pXs, 0, pYs, 0}
                     if not Config.HUDSizes then Config.HUDSizes = {} end
                     local sXs = element.Size.X.Scale + (element.Size.X.Offset / rPs.X)
                     local sYs = element.Size.Y.Scale + (element.Size.Y.Offset / rPs.Y)
                     Config.HUDSizes[name] = {sXs, 0, sYs, 0}
                 end
             end
        end))
    end
end

function setupElementDragging(name, element, allMovable, snapGuideV, snapGuideH)
    element.Visible = true
    local stroke = Instance.new("UIStroke")
    stroke.Name = "HUDEditorStroke"
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 2
    stroke.Parent = element
    table.insert(HUD.Strokes, stroke)

    local isChild = false
    for _, friendly in pairs(HUD.FriendlyNames) do
        if name == friendly then
            isChild = true
            break
        end
    end

    local inputTarget = Instance.new("TextButton")
    inputTarget.Name = "HUDDragHandle_" .. name
    inputTarget.BackgroundTransparency = 1
    inputTarget.Text = ""
    inputTarget.ZIndex = isChild and 10 or 5
    inputTarget.Active = true
    inputTarget.Parent = HUD.SelectionGui

    table.insert(HUD.Connections, RunService.RenderStepped:Connect(function()
        if element and element.Parent then
            inputTarget.Size = UDim2.fromOffset(element.AbsoluteSize.X, element.AbsoluteSize.Y)
            inputTarget.Position = UDim2.fromOffset(element.AbsolutePosition.X, element.AbsolutePosition.Y)
        end
    end))

    local dragging = false
    local dragStart, startPos
    local dragUndo
    table.insert(HUD.Connections, inputTarget.InputBegan:Connect(function(input)
        if not State.hudEditorActive then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragUndo = captureHUDState(name, element)
            dragStart = input.Position
            startPos = element.Position
            stroke.Color = Color3.fromRGB(255, 255, 255)
            selectHUDElement(name, element)
        end
    end))

    table.insert(HUD.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if not dragStart then return end
            local delta = input.Position - dragStart
            local ps = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
            local rawPos = UDim2.new(
                startPos.X.Scale + delta.X / ps.X, startPos.X.Offset,
                startPos.Y.Scale + delta.Y / ps.Y, startPos.Y.Offset
            )
            local snapped, gx, gy = calculateSnap(element, rawPos, name, allMovable)
            element.Position = snapped
            local ovP = HUD.Overlay and HUD.Overlay.AbsolutePosition or Vector2.new(0, 0)
            if snapGuideV then snapGuideV.Visible = (gx ~= nil); if gx then snapGuideV.Position = UDim2.fromOffset(gx - ovP.X, 0) end end
            if snapGuideH then snapGuideH.Visible = (gy ~= nil); if gy then snapGuideH.Position = UDim2.fromOffset(0, gy - ovP.Y) end end
        end
    end))

    table.insert(HUD.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                stroke.Color = Color3.fromRGB(0, 255, 100)
                if snapGuideV then snapGuideV.Visible = false end
                if snapGuideH then snapGuideH.Visible = false end
                if dragUndo and not sameUDim2(dragUndo.pos, element.Position) then
                    pushUndo(dragUndo)
                end
                    local dPs = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                    local dpXs = element.Position.X.Scale + (element.Position.X.Offset / dPs.X)
                    local dpYs = element.Position.Y.Scale + (element.Position.Y.Offset / dPs.Y)
                    element.Position = UDim2.new(dpXs, 0, dpYs, 0)
                    Config.HUDPositions[name] = {dpXs, 0, dpYs, 0}
                end
        end
    end))
end

applySavedPositions = function()
    local elems = getAllHUDObjects()
    for name, el in pairs(elems) do
        local customPos = Config.HUDPositions and Config.HUDPositions[name]
        if customPos and type(customPos) == "table" and #customPos == 4 then
            el.Position = UDim2.new(customPos[1], customPos[2], customPos[3], customPos[4])
        elseif HUD.DefaultPositions and HUD.DefaultPositions[name] then
             el.Position = HUD.DefaultPositions[name]
        end

        local customSz = Config.HUDSizes and Config.HUDSizes[name]
        if customSz and type(customSz) == "table" and #customSz == 4 then
            el.Size = UDim2.new(customSz[1], customSz[2], customSz[3], customSz[4])
        elseif HUD.DefaultSizes and HUD.DefaultSizes[name] then
             el.Size = HUD.DefaultSizes[name]
        end

        local props = Config.HUDProperties and Config.HUDProperties[name]
        if props then
            for k, v in pairs(props) do
                pcall(function()
                    if k == "Radius" or k == "CornerRadius" then
                        local cR = el:FindFirstChildWhichIsA("UICorner")
                        if cR and type(v) == "table" then
                             cR.CornerRadius = UDim.new(tonumber(v[1]) or 0, tonumber(v[2]) or 0)
                        end
                    elseif k == "RadiusString" or k == "PlaceholderTransparency" then
                    else
                        el[k] = v
                    end
                end)
            end
        end
    end
end

exitHUDEditor = function()
    if not State.hudEditorActive then return end
    State.hudEditorActive = false
    if SettingsLib and SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") and HUD.SettingsDisplayOrderPrev ~= nil then
        pcall(function()
            SettingsLib.UI.DisplayOrder = HUD.SettingsDisplayOrderPrev
        end)
        HUD.SettingsDisplayOrderPrev = nil
    end
    for _, conn in pairs(HUD.Connections) do pcall(function() conn:Disconnect() end) end
    HUD.Connections = {}
    for _, conn in pairs(HUD.ResizeConnections) do pcall(function() conn:Disconnect() end) end
    HUD.ResizeConnections = {}
    for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
    HUD.ResizeHandles = {}
    HUD.SelectedElement = nil
    for _, stroke in pairs(HUD.Strokes) do
        pcall(function() if stroke and stroke.Parent then stroke:Destroy() end end)
    end
    HUD.Strokes = {}

    if HUD.SelectionGui then
        pcall(function() HUD.SelectionGui:Destroy() end)
        HUD.SelectionGui = nil
    end
    for _, el in pairs(getMovableElements()) do
        local h = el:FindFirstChild("HUDDragHandle")
        if h then h:Destroy() end
        if el:FindFirstChildOfClass("UIListLayout") then
            for _, child in pairs(el:GetChildren()) do
                if child:IsA("GuiButton") or child:IsA("TextBox") then
                    child.Active = true
                end
            end
        end
    end
    if HUD.Overlay then
        for _, g in pairs(HUD.Overlay:GetChildren()) do
            if g.Name == "SnapGuide" then g:Destroy() end
        end
    end
    if HUD.Overlay and HUD.Overlay.Parent then HUD.Overlay:Destroy() end
    HUD.Overlay = nil
    if HUD.ForceVisibleConn then HUD.ForceVisibleConn:Disconnect(); HUD.ForceVisibleConn = nil end
    if UI.Search then UI.Search.TextEditable = true; UI.Search.Active = true end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = true; UI.SpeedBox.Active = true end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = true; UI._2Routenumber.Active = true end
    pcall(function() game:GetService("GuiService"):SetEmotesMenuOpen(false) end)
    pcall(function() game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false end)
end

enterHUDEditor = function()
    if State.hudEditorActive then return end
    State.hudEditorActive = true
    HUD.UndoStack = {}

    GuiService:SetEmotesMenuOpen(false)
    task.wait(0.15)

    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then State.hudEditorActive = false; return end
    emotesWheel.Visible = true

    HUD.ForceVisibleConn = RunService.Heartbeat:Connect(function()
        if not State.hudEditorActive then return end
        pcall(function()
            local _, ew = checkEmotesMenuExists()
            if ew then ew.Visible = true end
        end)
    end)

    local main = getSettingsMainFrame()
    if main then main.Visible = false end
    syncToggleVisibility()
    if SettingsLib and SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") then
        if HUD.SettingsDisplayOrderPrev == nil then
            HUD.SettingsDisplayOrderPrev = SettingsLib.UI.DisplayOrder
        end
        pcall(function() SettingsLib.UI.DisplayOrder = 99998 end)
    end
    ApplyUIVisibility()

    local selectionGui = game:GetService("CoreGui"):FindFirstChild("Aphelion_HUDSelection")
    if not selectionGui then
        selectionGui = Instance.new("ScreenGui")
        selectionGui.Name = "Aphelion_HUDSelection"
        selectionGui.IgnoreGuiInset = false
        selectionGui.DisplayOrder = 99999
        selectionGui.Parent = game:GetService("CoreGui")
    else
        selectionGui.IgnoreGuiInset = false
        selectionGui.DisplayOrder = 99999
    end
    HUD.SelectionGui = selectionGui

    local overlay = Instance.new("Frame")
    overlay.Name = "HUDEditorOverlay"
    overlay.Parent = SettingsLib.UI
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 6000
    overlay.Active = false
    HUD.Overlay = overlay
    table.insert(HUD.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not State.hudEditorActive then return end
        if input.KeyCode == Enum.KeyCode.Z then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                undoLastHUD()
            end
        end
    end))
    table.insert(HUD.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local p = input.Position
            if HUD.SelectedElement then
                local e = HUD.SelectedElement
                local pos = e.AbsolutePosition
                local sz = e.AbsoluteSize
                if p.X < pos.X - 25 or p.X > pos.X + sz.X + 25 or p.Y < pos.Y - 25 or p.Y > pos.Y + sz.Y + 25 then
                    task.delay(0.1, function()
                        if HUD.SelectedElement == e then
                            HUD.SelectedElement = nil
                            for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
                            HUD.ResizeHandles = {}
                            for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
                            HUD.ResizeConnections = {}
                        end
                    end)
                end
            end
        end
    end))

    local bc = Instance.new("Frame")
    bc.Parent = overlay
    bc.BackgroundTransparency = 1
    bc.AnchorPoint = Vector2.new(1, 0)
    bc.Position = UDim2.new(1, -10, 0, 10)
    bc.Size = UDim2.fromOffset(360, 42)
    bc.ZIndex = 6000

    local bl = Instance.new("UIListLayout")
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 8)
    bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    bl.VerticalAlignment = Enum.VerticalAlignment.Center
    bl.Parent = bc

    local propertiesBtn = Instance.new("ImageButton")
    propertiesBtn.Parent = bc
    propertiesBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    propertiesBtn.BackgroundTransparency = 0.4
    propertiesBtn.Size = UDim2.fromOffset(42, 42)
    propertiesBtn.Image = "rbxassetid://111026029750357"
    propertiesBtn.ZIndex = 6001
    local propCorner = Instance.new("UICorner")
    propCorner.CornerRadius = UDim.new(0, 10)
    propCorner.Parent = propertiesBtn

    local exportBtn = Instance.new("ImageButton")
    exportBtn.Parent = bc
    exportBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    exportBtn.BackgroundTransparency = 0.4
    exportBtn.Size = UDim2.fromOffset(42, 42)
    exportBtn.Image = "rbxassetid://107588515524752"
    exportBtn.ZIndex = 6001
    local exportCorner = Instance.new("UICorner")
    exportCorner.CornerRadius = UDim.new(0, 10)
    exportCorner.Parent = exportBtn

    local importBtn = Instance.new("ImageButton")
    importBtn.Parent = bc
    importBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    importBtn.BackgroundTransparency = 0.4
    importBtn.Size = UDim2.fromOffset(42, 42)
    importBtn.Image = "rbxassetid://78317476576895"
    importBtn.ZIndex = 6001
    local importCorner = Instance.new("UICorner")
    importCorner.CornerRadius = UDim.new(0, 10)
    importCorner.Parent = importBtn

    local resetBtn = Instance.new("ImageButton")
    resetBtn.Parent = bc
    resetBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    resetBtn.BackgroundTransparency = 0.4
    resetBtn.Size = UDim2.fromOffset(42, 42)
    resetBtn.Image = "rbxassetid://123088523596870"
    resetBtn.ZIndex = 6001
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 10)
    resetCorner.Parent = resetBtn

    local lockBtn = Instance.new("ImageButton")
    lockBtn.Parent = bc
    lockBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lockBtn.BackgroundTransparency = 0.4
    lockBtn.Size = UDim2.fromOffset(42, 42)
    lockBtn.Image = HUD.IsUnlocked and "rbxassetid://137042445663198" or "rbxassetid://137985778533954"
    lockBtn.ZIndex = 6001
    local lockCorner = Instance.new("UICorner")
    lockCorner.CornerRadius = UDim.new(0, 10)
    lockCorner.Parent = lockBtn

    local addBtn = Instance.new("ImageButton")
    addBtn.Parent = bc
    addBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    addBtn.BackgroundTransparency = 0.4
    addBtn.Size = UDim2.fromOffset(42, 42)
    addBtn.Image = "rbxassetid://108445456753346"
    addBtn.ZIndex = 6001
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0, 10)
    addCorner.Parent = addBtn

    local backBtn = Instance.new("ImageButton")
    backBtn.Parent = bc
    backBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backBtn.BackgroundTransparency = 0.4
    backBtn.Size = UDim2.fromOffset(42, 42)
    backBtn.Image = "rbxassetid://79024388644722"
    backBtn.ZIndex = 6001
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 10)
    backCorner.Parent = backBtn



    local function rebuildHUDOverlays()
        for _, conn in pairs(HUD.ResizeConnections) do pcall(function() conn:Disconnect() end) end
        HUD.ResizeConnections = {}
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, stroke in pairs(HUD.Strokes) do pcall(function() stroke:Destroy() end) end
        HUD.Strokes = {}
        if selectionGui then selectionGui:ClearAllChildren() end
        HUD.SelectedElement = nil
        
        local allMovable = getMovableElements()
        
        local snapGuideH = Instance.new("Frame")
        snapGuideH.Name = "SnapGuide"
        snapGuideH.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        snapGuideH.BorderSizePixel = 0
        snapGuideH.Size = UDim2.new(1, 0, 0, 1)
        snapGuideH.ZIndex = 6002
        snapGuideH.Visible = false
        snapGuideH.Parent = selectionGui

        local snapGuideV = Instance.new("Frame")
        snapGuideV.Name = "SnapGuide"
        snapGuideV.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        snapGuideV.BorderSizePixel = 0
        snapGuideV.Size = UDim2.new(0, 1, 1, 0)
        snapGuideV.ZIndex = 6002
        snapGuideV.Visible = false
        snapGuideV.Parent = selectionGui

        for name, element in pairs(allMovable) do
            setupElementDragging(name, element, allMovable, snapGuideV, snapGuideH)
        end
        
        updateHUDLayouts()
        
        applySavedPositions()
    end

    local function rebuildCustomFramesFromConfig()
        if UI.CustomFrames then
            for _, frame in pairs(UI.CustomFrames) do
                if frame and frame.Parent then frame:Destroy() end
            end
        end
        UI.CustomFrames = {}

        if not Config.CustomFrames then return end
        local _, emotesWheel = checkEmotesMenuExists()
        if not emotesWheel then return end

        for name, data in pairs(Config.CustomFrames) do
            local cf = Instance.new("Frame")
            cf.Name = name
            cf.Parent = emotesWheel
            cf.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            cf.BackgroundTransparency = 0.4
            cf.ZIndex = data and data.ZIndex or 3
            cf.BorderSizePixel = 0
            cf.Active = true

            local pos = Config.HUDPositions and Config.HUDPositions[name]
            local size = Config.HUDSizes and Config.HUDSizes[name]
            if pos and type(pos) == "table" and #pos == 4 then
                cf.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
            else
                cf.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
            if size and type(size) == "table" and #size == 4 then
                cf.Size = UDim2.new(size[1], size[2], size[3], size[4])
            else
                cf.Size = UDim2.new(0.3, 0, 0.3, 0)
            end

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = cf

            UI.CustomFrames[name] = cf
            HUD.DefaultPositions[name] = cf.Position
            HUD.DefaultSizes[name] = cf.Size
        end
    end

    local function applyHUDSettingsReplace(settings)
        local function normalizeImportTable(tbl)
            if type(tbl) ~= "table" then return {} end
            local allElems = getAllHUDObjects()
            for eName, v in pairs(tbl) do
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local el = allElems[eName]
                        local ps = el and el.Parent and el.Parent.AbsoluteSize
                        if ps and ps.X > 0 and ps.Y > 0 then
                            tbl[eName] = {sx + (ox / ps.X), 0, sy + (oy / ps.Y), 0}
                        end
                    end
                end
            end
            return tbl
        end
        Config.HUDPositions = normalizeImportTable(settings.HUDPositions or {})
        Config.HUDSizes = normalizeImportTable(settings.HUDSizes or {})
        Config.HUDProperties = settings.HUDProperties or {}
        Config.CustomFrames = settings.CustomFrames or {}
        HUD.LayoutsRemoved = {}
        SaveConfig()
        rebuildCustomFramesFromConfig()
        applySavedPositions()

        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        pcall(function() updateGUIColors() end)
    end

    table.insert(HUD.Connections, lockBtn.MouseButton1Click:Connect(function()
        HUD.IsUnlocked = not HUD.IsUnlocked
        lockBtn.Image = HUD.IsUnlocked and "rbxassetid://137042445663198" or "rbxassetid://137985778533954"
        rebuildHUDOverlays()
        pcall(function() updateGUIColors() end)
        getgenv().Notify({ 
            Title = "Aphelion | HUD Editor", 
            Content = HUD.IsUnlocked and "🔓 Interior Unlocked! Children are now editable." or "🔒 Interior Locked! Top-level only.", 
            Duration = 2 
        })
    end))

    rebuildHUDOverlays()

    table.insert(HUD.Connections, exportBtn.MouseButton1Click:Connect(function()
        local function normalizeExportTable(tbl)
            if type(tbl) ~= "table" then return {} end
            local out = {}
            local allElems = getAllHUDObjects()
            for eName, v in pairs(tbl) do
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local el = allElems[eName]
                        local ps = el and el.Parent and el.Parent.AbsoluteSize
                        if ps and ps.X > 0 and ps.Y > 0 then
                            sx = sx + (ox / ps.X)
                            sy = sy + (oy / ps.Y)
                        end
                    end
                    out[eName] = {sx, 0, sy, 0}
                else
                    out[eName] = v
                end
            end
            return out
        end
        local function normalizeExportProps(props)
            if type(props) ~= "table" then return {} end
            local out = {}
            local allElems = getAllHUDObjects()
            for eName, p in pairs(props) do
                local ep = {}
                for k, v in pairs(p) do
                    if (k == "CornerRadius" or k == "Radius") and type(v) == "table" and #v == 2 then
                        local rs, ro = v[1], v[2]
                        if ro ~= 0 and rs == 0 then
                            local el = allElems[eName]
                            if el then
                                local minDim = math.min(el.AbsoluteSize.X, el.AbsoluteSize.Y)
                                if minDim > 0 then
                                    rs = ro / minDim
                                    ro = 0
                                end
                            end
                        end
                        ep[k] = {rs, ro}
                    else
                        ep[k] = v
                    end
                end
                out[eName] = ep
            end
            return out
        end
        local data = {
            Type = "HUD",
            Settings = {
                HUDPositions = normalizeExportTable(Config.HUDPositions or {}),
                HUDSizes = normalizeExportTable(Config.HUDSizes or {}),
                HUDProperties = normalizeExportProps(Config.HUDProperties or {}),
                CustomFrames = Config.CustomFrames or {}
            }
        }
        setclipboard(HttpService:JSONEncode(data))
        getgenv().Notify({ Title = "Aphelion | HUD Editor", Content = "✅ HUD settings copied", Duration = 2 })
    end))

    table.insert(HUD.Connections, importBtn.MouseButton1Click:Connect(function()
        local popup, content = CreatePopup("Import HUD", UDim2.fromOffset(320, 240))
        local popupRoot = HUD.SelectionGui or SettingsLib.UI
        if popupRoot and popup.Parent ~= popupRoot then
            popup.Parent = popupRoot
        end

        local baseZ = 7000
        popup.ZIndex = baseZ

        local backdrop = Instance.new("TextButton")
        backdrop.Name = "HUDImportBackdrop"
        backdrop.Parent = popup.Parent
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundTransparency = 1
        backdrop.Text = ""
        backdrop.AutoButtonColor = false
        backdrop.ZIndex = baseZ - 1
        backdrop.Active = true

        local scroll = Instance.new("ScrollingFrame")
        scroll.Parent = content
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.Position = UDim2.new(0.05, 0, 0, 5)
        scroll.Size = UDim2.new(0.9, 0, 0, 130)
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 4
        scroll.Active = true
        scroll.ScrollingEnabled = true
        scroll.ScrollingDirection = Enum.ScrollingDirection.Y
        scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable

        local box = CreateInput(scroll, "Paste HUD JSON here...", "", true)
        box.Size = UDim2.new(1, -8, 0, 130)
        box.Position = UDim2.new(0, 0, 0, 0)
        box.TextYAlignment = Enum.TextYAlignment.Top
        box.ClearTextOnFocus = false

        local function updateCanvas()
            local padding = 8
            local h = math.max(130, (box.TextBounds.Y or 0) + padding)
            scroll.CanvasSize = UDim2.new(0, 0, 0, h)
        end
        box:GetPropertyChangedSignal("Text"):Connect(updateCanvas)
        box:GetPropertyChangedSignal("TextBounds"):Connect(updateCanvas)
        updateCanvas()

        local imp = CreateButton(content, "IMPORT HUD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

        imp.MouseButton1Click:Connect(function()
            local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
            if s and type(d) == "table" then
                local settings = d.Settings or d
                if d.Type and d.Type ~= "HUD" then
                    getgenv().Notify({ Title = "Error", Content = "HUD import type mismatch!", Duration = 3 })
                    return
                end
                if type(settings) ~= "table" then
                    getgenv().Notify({ Title = "Error", Content = "Invalid HUD JSON", Duration = 3 })
                    return
                end
                applyHUDSettingsReplace(settings)
                HUD.UndoStack = {}
                if backdrop then backdrop:Destroy() end
                popup:Destroy()
                getgenv().Notify({ Title = "Aphelion | HUD Editor", Content = "✅ HUD settings imported", Duration = 2 })
            else
                getgenv().Notify({ Title = "Error", Content = "Invalid HUD JSON", Duration = 3 })
            end
        end)

        local close = Instance.new("TextButton")
        close.Size = UDim2.fromOffset(24, 24)
        close.Position = UDim2.new(1, -30, 0, 5)
        close.Text = "×"
        close.Font = Enum.Font.GothamBold
        close.TextSize = 20
        close.BackgroundTransparency = 1
        close.TextColor3 = Color3.new(1,1,1)
        close.ZIndex = baseZ + 2
        close.Active = true
        close.AutoButtonColor = false
        close.Parent = popup
        close.MouseButton1Click:Connect(function()
            if backdrop then backdrop:Destroy() end
            popup:Destroy()
        end)
        backdrop.MouseButton1Click:Connect(function()
            if backdrop then backdrop:Destroy() end
            popup:Destroy()
        end)

        local function bumpPopupZIndex(panel, z)
            if not panel then return end
            panel.ZIndex = z
            for _, d in ipairs(panel:GetDescendants()) do
                if d:IsA("GuiObject") then
                    d.ZIndex = z + 1
                end
            end
        end
        bumpPopupZIndex(popup, baseZ)
        close.ZIndex = baseZ + 2
    end))

    table.insert(HUD.Connections, backBtn.MouseButton1Click:Connect(function()
        exitHUDEditor()
    end))

    table.insert(HUD.Connections, resetBtn.MouseButton1Click:Connect(function()
        Config.HUDPositions = {}
        Config.HUDSizes = {}
        Config.CustomFrames = {}
        Config.HUDProperties = {}
        HUD.LayoutsRemoved = {}
        SaveConfig()
        
        local allElements = getAllHUDObjects()
        for name, el in pairs(allElements) do
            if name:match("^CustomFrame_") then
                el:Destroy()
                if UI.CustomFrames then UI.CustomFrames[name] = nil end
            else
                if HUD.DefaultPositions[name] then el.Position = HUD.DefaultPositions[name] end
                if HUD.DefaultSizes[name] then el.Size = HUD.DefaultSizes[name] end
                
                for internal, friendly in pairs(HUD.FriendlyNames) do
                    if name == friendly then
                        if internal:match("^Under%.") then
                            el.Parent = UI.Under
                        elseif internal:match("^Top%.") then
                            el.Parent = UI.Top
                        end
                        break
                    end
                end

                el.ZIndex = (name == "Top" or name == "Under") and 3 or (el:IsA("ImageButton") and 4 or 3)
                if name == "Under" then
                    el.BackgroundTransparency = 1
                else
                    el.BackgroundTransparency = (name == "Top" or name == "Reload" or name == "Changepage" or name == "EmoteWalkButton" or name == "SpeedBox" or name == "SpeedEmote" or name == "Favorite") and 0.4 or 1
                end
                
                if el:IsA("ImageButton") or el:IsA("ImageLabel") then
                    el.ImageTransparency = 0
                end
                
                if el:IsA("TextLabel") or el:IsA("TextBox") then
                    el.TextTransparency = 0.4
                    if HUD.DefaultTexts and HUD.DefaultTexts[name] then
                        el.Text = HUD.DefaultTexts[name]
                    end
                    if el:IsA("TextBox") and HUD.DefaultPlaceholders and HUD.DefaultPlaceholders[name] then
                        el.PlaceholderText = HUD.DefaultPlaceholders[name]
                    end
                end

                local cR = el:FindFirstChildWhichIsA("UICorner")
                if cR then
                    cR.CornerRadius = UDim.new(0, 10)
                end
            end
        end

        pcall(function() updateGUIColors() end)
        
        HUD.SelectedElement = nil
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
        HUD.ResizeConnections = {}
        
        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        State.totalPages = calculateTotalPages()
        if State.currentPage > State.totalPages then
            State.currentPage = State.totalPages
        end
        updatePageDisplay()
        
        getgenv().Notify({ Title = "Aphelion | HUD Editor", Content = "🔄 All designs and frames have been fully reset", Duration = 3 })
    end))

    local propertiesPanel = Instance.new("Frame")
    propertiesPanel.Name = "HUDPropertiesPanel"
    propertiesPanel.Parent = overlay
    propertiesPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    propertiesPanel.BackgroundTransparency = 0.4
    propertiesPanel.Size = UDim2.fromOffset(260, 150)
    propertiesPanel.AnchorPoint = Vector2.new(1, 0)
    propertiesPanel.Position = UDim2.new(1, -10, 0, 60)
    propertiesPanel.Visible = false
    propertiesPanel.ZIndex = 6005
    propertiesPanel.ClipsDescendants = true
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = propertiesPanel
    
    local title = Instance.new("TextLabel")
    title.Parent = propertiesPanel
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 26)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.Font = Enum.Font.SourceSansBold
    title.Text = "No Element"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.TextScaled = true
    title.ZIndex = 6006

    local propContent = Instance.new("ScrollingFrame")
    propContent.Parent = propertiesPanel
    propContent.BackgroundTransparency = 1
    propContent.Position = UDim2.new(0, 0, 0, 28)
    propContent.Size = UDim2.new(1, 0, 1, -32)
    propContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    propContent.ScrollBarThickness = 2
    propContent.Active = true
    propContent.ScrollingEnabled = true
    propContent.ZIndex = 6006

    local propLayout = Instance.new("UIListLayout")
    propLayout.Parent = propContent
    propLayout.SortOrder = Enum.SortOrder.LayoutOrder
    propLayout.Padding = UDim.new(0, 6)
    propLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    HUD.LastTouchedElement = nil
    HUD.LastTouchedName = nil

    local function createPropRow(label, lOrder, isLarge)
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(0.92, 0, 0, isLarge and 50 or 26)
        row.LayoutOrder = lOrder
        row.ZIndex = 6006
        row.Parent = propContent

        local lbl = Instance.new("TextLabel")
        lbl.Parent = row
        lbl.Size = UDim2.new(0, 70, 0, 26)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextSize = 12
        lbl.ZIndex = 6007

        local tbox = Instance.new("TextBox")
        tbox.Parent = row
        tbox.Size = UDim2.new(1, -75, 1, -4)
        tbox.Position = UDim2.new(0, 75, 0, 2)
        tbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tbox.BackgroundTransparency = 0.3
        tbox.TextColor3 = Color3.fromRGB(255, 255, 255)
        tbox.Font = Enum.Font.Code
        tbox.TextSize = 12
        tbox.TextXAlignment = isLarge and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        tbox.TextYAlignment = isLarge and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        tbox.ClearTextOnFocus = false
        tbox.TextWrapped = isLarge
        tbox.PlaceholderText = ""
        tbox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
        tbox.ZIndex = 6007
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 6); tc.Parent = tbox

        return row, tbox
    end

    local _, posBox = createPropRow("Position", 1)
    local _, sizeBox = createPropRow("Size", 2)
    local zRow, zBox = createPropRow("ZIndex", 3)
    local bgRow, bgBox = createPropRow("BgTrans", 4)
    local bgcRow, bgcBox = createPropRow("BgColor", 5)
    local imgRow, imgBox = createPropRow("ImgTrans", 6)
    local imgcRow, imgcBox = createPropRow("ImgColor", 7)
    local radRow, radBox = createPropRow("Radius", 8)
    local txtRow, txtBox = createPropRow("Text", 9, true)
    local phRow, phBox = createPropRow("Placeholder", 10, true)
    local ttrRow, ttrBox = createPropRow("TxtTrans", 11)
    local txtcRow, txtcBox = createPropRow("TxtColor", 12)

    local deleteRow = Instance.new("Frame")
    deleteRow.BackgroundTransparency = 1
    deleteRow.Size = UDim2.new(0.92, 0, 0, 28)
    deleteRow.LayoutOrder = 13
    deleteRow.ZIndex = 6006
    deleteRow.Parent = propContent

    local deleteBtn = Instance.new("TextButton")
    deleteBtn.Parent = deleteRow
    deleteBtn.Size = UDim2.new(1, 0, 1, 0)
    deleteBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
    deleteBtn.BackgroundTransparency = 0.1
    deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteBtn.Font = Enum.Font.GothamBold
    deleteBtn.TextSize = 12
    deleteBtn.Text = "Delete Custom Frame"
    deleteBtn.ZIndex = 6007
    local delCorner = Instance.new("UICorner"); delCorner.CornerRadius = UDim.new(0, 6); delCorner.Parent = deleteBtn



    local function parseUDim2(text)
        local s1, o1, s2, o2 = text:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}%s*,%s*{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
        if s1 and o1 and s2 and o2 then
            return tonumber(s1), tonumber(o1), tonumber(s2), tonumber(o2)
        end
        local a, b = text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)")
        if a and b then
            local va, vb = tonumber(a), tonumber(b)
            if va and vb then
                return 0, va, 0, vb
            end
        end
        return nil
    end

    local function formatUDim2(udim)
        return string.format("{%g, %g},{%g, %g}", udim.X.Scale, udim.X.Offset, udim.Y.Scale, udim.Y.Offset)
    end

    table.insert(HUD.Connections, propertiesBtn.MouseButton1Click:Connect(function()
        propertiesPanel.Visible = not propertiesPanel.Visible
    end))

    local function formatUDim(udim)
        return string.format("{%g, %g}", udim.Scale, udim.Offset)
    end

    local function formatRGB(c)
        return string.format("%d, %d, %d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    end

    local function parseRGB(text)
        local a, b, c = text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)")
        if not a then return nil end
        local r, g, b2 = tonumber(a), tonumber(b), tonumber(c)
        if not r or not g or not b2 then return nil end
        local maxv = math.max(r, g, b2)
        if maxv <= 1 then
            r, g, b2 = r * 255, g * 255, b2 * 255
        end
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b2 = math.clamp(b2, 0, 255)
        return r, g, b2
    end

    table.insert(HUD.Connections, RunService.RenderStepped:Connect(function()
        if not propertiesPanel.Visible then return end
        local e = HUD.LastTouchedElement
        local eName = HUD.LastTouchedName
        if e and e.Parent then
            title.Text = string.format("[%s] %s", e.ClassName, eName or "Unknown")
            if not posBox:IsFocused() then posBox.Text = formatUDim2(e.Position) end
            if not sizeBox:IsFocused() then sizeBox.Text = formatUDim2(e.Size) end
            
            zRow.Visible = true
            if not zBox:IsFocused() then zBox.Text = tostring(e.ZIndex) end

            bgRow.Visible = true
            if not bgBox:IsFocused() then bgBox.Text = tostring(math.floor(e.BackgroundTransparency * 100) / 100) end

            if e:IsA("ImageLabel") or e:IsA("ImageButton") then
                imgRow.Visible = true
                if not imgBox:IsFocused() then imgBox.Text = tostring(math.floor(e.ImageTransparency * 100) / 100) end
            else
                imgRow.Visible = false
            end
            
            bgcRow.Visible = true
            if not bgcBox:IsFocused() then bgcBox.Text = formatRGB(e.BackgroundColor3) end
            
            if e:IsA("ImageLabel") or e:IsA("ImageButton") then
                imgcRow.Visible = true
                if not imgcBox:IsFocused() then imgcBox.Text = formatRGB(e.ImageColor3) end
            else
                imgcRow.Visible = false
            end
            
            if e:IsA("TextLabel") or e:IsA("TextBox") then
                ttrRow.Visible = true
                if not ttrBox:IsFocused() then ttrBox.Text = tostring(math.floor(e.TextTransparency * 100) / 100) end
                
                txtRow.Visible = true
                if not txtBox:IsFocused() then txtBox.Text = e.Text end

                txtcRow.Visible = true
                if not txtcBox:IsFocused() then txtcBox.Text = formatRGB(e.TextColor3) end
                
                if e:IsA("TextBox") then
                    phRow.Visible = true
                    if not phBox:IsFocused() then phBox.Text = e.PlaceholderText end
                else
                    phRow.Visible = false
                end
            else
                ttrRow.Visible = false
                txtRow.Visible = false
                phRow.Visible = false
                txtcRow.Visible = false
            end

            deleteRow.Visible = (eName and eName:match("^CustomFrame_")) and true or false


            local cR = e:FindFirstChildWhichIsA("UICorner")
            if cR then
                radRow.Visible = true
                if not radBox:IsFocused() then radBox.Text = formatUDim(cR.CornerRadius) end
            else
                radRow.Visible = false
            end
        else
            title.Text = "No Element Selected"
            zRow.Visible = false
            bgRow.Visible = false
            imgRow.Visible = false
            bgcRow.Visible = false
            imgcRow.Visible = false
            radRow.Visible = false
            ttrRow.Visible = false
            txtRow.Visible = false
            phRow.Visible = false
            txtcRow.Visible = false
            deleteRow.Visible = false
            if not posBox:IsFocused() then posBox.Text = "" end
            if not sizeBox:IsFocused() then sizeBox.Text = "" end
        end
        
        local totalH = propLayout.AbsoluteContentSize.Y + 10
        propContent.CanvasSize = UDim2.new(0, 0, 0, totalH)
        local vpY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800
        local maxH = math.floor(vpY * 0.55)
        propertiesPanel.Size = UDim2.fromOffset(260, math.min(maxH, totalH + 40))
    end))

    local function saveHUDProp(eName, propKey, val)
        if not Config.HUDProperties then Config.HUDProperties = {} end
        if not Config.HUDProperties[eName] then Config.HUDProperties[eName] = {} end
        Config.HUDProperties[eName][propKey] = val
        SaveConfig()
    end

    table.insert(HUD.Connections, deleteBtn.MouseButton1Click:Connect(function()
        local eName = HUD.LastTouchedName
        if not eName or not eName:match("^CustomFrame_") then return end
        local frame = UI.CustomFrames and UI.CustomFrames[eName]
        if frame and frame.Parent then frame:Destroy() end
        if UI.CustomFrames then UI.CustomFrames[eName] = nil end
        if Config.CustomFrames then Config.CustomFrames[eName] = nil end
        if Config.HUDPositions then Config.HUDPositions[eName] = nil end
        if Config.HUDSizes then Config.HUDSizes[eName] = nil end
        if Config.HUDProperties then Config.HUDProperties[eName] = nil end
        if HUD.DefaultPositions then HUD.DefaultPositions[eName] = nil end
        if HUD.DefaultSizes then HUD.DefaultSizes[eName] = nil end
        if HUD.DefaultTexts then HUD.DefaultTexts[eName] = nil end
        if HUD.DefaultPlaceholders then HUD.DefaultPlaceholders[eName] = nil end
        SaveConfig()

        HUD.SelectedElement = nil
        HUD.LastTouchedElement = nil
        HUD.LastTouchedName = nil
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
        HUD.ResizeConnections = {}

        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        pcall(function() updateGUIColors() end)
        getgenv().Notify({ Title = "Aphelion | HUD Editor", Content = "🗑️ Custom Frame deleted", Duration = 2 })
    end))



    table.insert(HUD.Connections, posBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local s1, o1, s2, o2 = parseUDim2(posBox.Text)
        if s1 then
            local prev = captureHUDState(eName, e)
            e.Position = UDim2.new(s1, o1, s2, o2)
            if prev and not sameUDim2(prev.pos, e.Position) then
                pushUndo(prev)
            end
            Config.HUDPositions[eName] = {s1, o1, s2, o2}
        end
    end))

    table.insert(HUD.Connections, sizeBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local s1, o1, s2, o2 = parseUDim2(sizeBox.Text)
        if s1 then
            local prev = captureHUDState(eName, e)
            e.Size = UDim2.new(s1, o1, s2, o2)
            if prev and not sameUDim2(prev.size, e.Size) then
                pushUndo(prev)
            end
            if not Config.HUDSizes then Config.HUDSizes = {} end
            Config.HUDSizes[eName] = {s1, o1, s2, o2}
        end
    end))

    table.insert(HUD.Connections, zBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(zBox.Text)
        if v then
            local prev = captureHUDState(eName, e)
            e.ZIndex = v
            if prev and prev.z ~= e.ZIndex then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ZIndex", v)
        end
    end))

    table.insert(HUD.Connections, bgBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(bgBox.Text)
        if v then
            local prev = captureHUDState(eName, e)
            e.BackgroundTransparency = math.clamp(v, 0, 1)
            if prev and prev.bgTrans ~= e.BackgroundTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "BgTrans", e.BackgroundTransparency)
        end
    end))

    table.insert(HUD.Connections, imgBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(imgBox.Text)
        if v and (e:IsA("ImageLabel") or e:IsA("ImageButton")) then
            local prev = captureHUDState(eName, e)
            e.ImageTransparency = math.clamp(v, 0, 1)
            if prev and prev.imgTrans ~= e.ImageTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ImgTrans", e.ImageTransparency)
        end
    end))
    
    table.insert(HUD.Connections, bgcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local r, g, b = parseRGB(bgcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].BgColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.BackgroundColor3 = c end)
            if prev and not sameColor(prev.bgColor, e.BackgroundColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "BgColor", {r, g, b})
        end
    end))
    
    table.insert(HUD.Connections, imgcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if not (e:IsA("ImageLabel") or e:IsA("ImageButton")) then return end
        local r, g, b = parseRGB(imgcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].ImgColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.ImageColor3 = c end)
            if prev and prev.imgColor and not sameColor(prev.imgColor, e.ImageColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ImgColor", {r, g, b})
        end
    end))

    table.insert(HUD.Connections, radBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local a, b = radBox.Text:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
        if not a and not b then a, b = radBox.Text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)") end
        if a and b then
            local va, vb = tonumber(a), tonumber(b)
            if va and vb then
                local cR = e:FindFirstChildWhichIsA("UICorner")
                if cR then
                    local prev = captureHUDState(eName, e)
                    if vb ~= 0 and va == 0 then
                        local minDim = math.min(e.AbsoluteSize.X, e.AbsoluteSize.Y)
                        if minDim > 0 then
                            va = vb / minDim
                            vb = 0
                        end
                    end
                    cR.CornerRadius = UDim.new(va, vb)
                    if prev and prev.radius and not sameUDim(prev.radius, cR.CornerRadius) then
                        pushUndo(prev)
                    end
                    saveHUDProp(eName, "CornerRadius", {va, vb})
                end
            end
        end
    end))

    table.insert(HUD.Connections, txtBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if e:IsA("TextLabel") or e:IsA("TextBox") then
            local prev = captureHUDState(eName, e)
            e.Text = txtBox.Text
            if prev and prev.text ~= e.Text then
                pushUndo(prev)
            end
            saveHUDProp(eName, "Text", txtBox.Text)
        end
    end))

    table.insert(HUD.Connections, phBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if e:IsA("TextBox") then
            local prev = captureHUDState(eName, e)
            e.PlaceholderText = phBox.Text
            if prev and prev.placeholder ~= e.PlaceholderText then
                pushUndo(prev)
            end
            saveHUDProp(eName, "PlaceholderText", phBox.Text)
        end
    end))

    table.insert(HUD.Connections, ttrBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(ttrBox.Text)
        if v and (e:IsA("TextLabel") or e:IsA("TextBox")) then
            local prev = captureHUDState(eName, e)
            e.TextTransparency = math.clamp(v, 0, 1)
            if prev and prev.textTrans ~= e.TextTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "TextTransparency", e.TextTransparency)
        end
    end))

    table.insert(HUD.Connections, txtcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if not (e:IsA("TextLabel") or e:IsA("TextBox")) then return end
        local r, g, b = parseRGB(txtcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].TxtColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.TextColor3 = c end)
            if prev and prev.textColor and not sameColor(prev.textColor, e.TextColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "TxtColor", {r, g, b})
        end
    end))




    if UI.Search then UI.Search.TextEditable = false; UI.Search.Active = false; pcall(function() UI.Search:ReleaseFocus() end) end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = false; UI.SpeedBox.Active = false; pcall(function() UI.SpeedBox:ReleaseFocus() end) end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = false; UI._2Routenumber.Active = false; pcall(function() UI._2Routenumber:ReleaseFocus() end) end

    local allMovable = getMovableElements()
    local snapGuideH = Instance.new("Frame")
    snapGuideH.Name = "SnapGuide"
    snapGuideH.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    snapGuideH.BorderSizePixel = 0
    snapGuideH.Size = UDim2.new(1, 0, 0, 1)
    snapGuideH.ZIndex = 6002
    snapGuideH.Visible = false
    snapGuideH.Parent = overlay

    local snapGuideV = Instance.new("Frame")
    snapGuideV.Name = "SnapGuide"
    snapGuideV.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    snapGuideV.BorderSizePixel = 0
    snapGuideV.Size = UDim2.new(0, 1, 1, 0)
    snapGuideV.ZIndex = 6002
    snapGuideV.Visible = false
    snapGuideV.Parent = overlay

    for name, element in pairs(allMovable) do
        setupElementDragging(name, element, getMovableElements(), snapGuideV, snapGuideH)
    end

    table.insert(HUD.Connections, addBtn.MouseButton1Click:Connect(function()
        local nameIndex = 1
        while UI.CustomFrames and UI.CustomFrames["CustomFrame_"..nameIndex] do
            nameIndex = nameIndex + 1
        end
        local newName = "CustomFrame_"..nameIndex
        
        local _, emotesWheel = checkEmotesMenuExists()
        local cf = Instance.new("Frame")
        cf.Name = newName
        cf.Parent = emotesWheel
        cf.BackgroundTransparency = 0.4
        cf.ZIndex = 3
        cf.BorderSizePixel = 0
        cf.Active = true
        cf.Size = UDim2.new(0.3, 0, 0.3, 0)
        cf.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = cf

        if not UI.CustomFrames then UI.CustomFrames = {} end
        UI.CustomFrames[newName] = cf

        HUD.DefaultSizes[newName] = UDim2.new(0.3, 0, 0.3, 0)
        HUD.DefaultPositions[newName] = UDim2.new(0.5, 0, 0.5, 0)

        Config.HUDPositions[newName] = {0.5, 0, 0.5, 0}
        if not Config.HUDSizes then Config.HUDSizes = {} end
        Config.HUDSizes[newName] = {0.3, 0, 0.3, 0}
        if not Config.CustomFrames then Config.CustomFrames = {} end
        Config.CustomFrames[newName] = {ZIndex = 3}

        pcall(function() updateGUIColors() end)

        setupElementDragging(newName, cf, getMovableElements(), snapGuideV, snapGuideH)
        selectHUDElement(newName, cf)
        
        getgenv().Notify({ Title = "Aphelion | HUD Editor", Content = "➕ Custom Frame added!", Duration = 2 })
    end))

    getgenv().Notify({ Title = "Aphelion | HUD Editor", Content = "✏️ Drag elements to reposition", Duration = 5 })
end

State.RefreshUI = function()
    State.totalPages = calculateTotalPages()
    updatePageDisplay()
    if State.currentMode == "animation" then
        updateAnimations()
    else
        updateEmotes()
    end
end

State.RefreshSettingsUI = function()
    if TogglesUI then
        for key, toggle in pairs(TogglesUI) do
            if Config[key] ~= nil and toggle.SetState then
                toggle.SetState(Config[key])
            end
        end
    end
end

function checkAndRecreateGUI()
    if getgenv().APHELION_STANDALONE_UI then
        State.isGUICreated = false
        return
    end
    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then
        State.isGUICreated = false
        return
    end

    if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") or
        not emotesWheel:FindFirstChild("EmoteWalkButton") or not emotesWheel:FindFirstChild("Favorite") or
        not emotesWheel:FindFirstChild("SpeedEmote") or not emotesWheel:FindFirstChild("SpeedBox") or
        not emotesWheel:FindFirstChild("Changepage") or not emotesWheel:FindFirstChild("Reload") then
        State.isGUICreated = false
        if createGUIElements() then
            updatePageDisplay()
            updateEmotes()
            loadSpeedEmoteConfig()
        end
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end

-- Fresh execution: automatically load the last selected bundle as soon as the
-- current character is ready. This does not require pressing Play again.
task.spawn(function()
    task.wait(0.35)
    local currentCharacter = player.Character
    if currentCharacter and AphelionGetSavedBundle() then
        AphelionRestoreSavedBundle(currentCharacter, "startup")
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    onCharacterAdded(char)
    
    task.spawn(function()
        local attempts = 0
        while attempts < 20 do
            if not getgenv().APHELION_STANDALONE_UI and checkEmotesMenuExists() then
                task.wait(0.2)
                if createGUIElements() then
                    updatePageDisplay()
                    updateEmotes()
                    updateGUIColors()
                    loadSpeedEmoteConfig()
                end
                break
            end
            attempts = attempts + 1
            task.wait(0.1)
        end
    end)
end)


RunService.Heartbeat:Connect(function()
    if getgenv().APHELION_STANDALONE_UI then
        return
    end
    if not State.isGUICreated then
        checkAndRecreateGUI()
    else
        updateGUIColors()
        enforceImages()
    end
end)

RunService.Stepped:Connect(function()
    if humanoid and State.currentEmoteTrack and typeof(State.currentEmoteTrack) == "Instance" and State.currentEmoteTrack:IsA("AnimationTrack") and State.currentEmoteTrack.IsPlaying then
        if humanoid.MoveDirection.Magnitude > 0 then
            if State.toolEquipped or (State.speedEmoteEnabled and not State.emotesWalkEnabled) then
                State.currentEmoteTrack:Stop()
                State.currentEmoteTrack = nil
            end
        end
    end
end)

task.spawn(function()
    loadFavoritesAnimations()
    fetchAllEmotes()
    fetchAllAnimations()
    loadSpeedEmoteConfig()
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
task.spawn(function()
    while true do
        if getgenv().APHELION_STANDALONE_UI then
            task.wait(0.75)
            continue
        end
        local robloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        local emotesMenu = robloxGui and robloxGui:FindFirstChild("EmotesMenu")

        if not emotesMenu then
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)

        else
            local exists = emotesMenu:FindFirstChild("Children") and emotesMenu.Children:FindFirstChild("Main") and
                               emotesMenu.Children.Main:FindFirstChild("EmotesWheel")

            if exists then
                local emotesWheel = emotesMenu.Children.Main.EmotesWheel
                if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") then
                    if createGUIElements then
                        createGUIElements()
                        loadSpeedEmoteConfig()
                    end
                    updateGUIColors()
                    updatePageDisplay()
                end
            end
        end

        task.wait(0.3)
    end
end)

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not getgenv().APHELION_STANDALONE_UI then
    SafeLoad("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/OpenEmote.lua", "Open Emote")
    getgenv().Notify({
        Title = 'Aphelion | Emote Mobile',
        Content = '📱 Added emote open button for ease of use',
        Duration = 10
    })
end

if UserInputService.KeyboardEnabled then
    getgenv().Notify({
        Title = 'Aphelion | Emote PC',
        Content = '💻 Open menu press button "."',
        Duration = 10
    })
end

--[[==========================================================================
    APHELION ENHANCEMENT LAYER

    The supplied source already had the important pieces (dynamic animation
    catalogs, off-sale entries, bundle resolution, BundleThumbnail images,
    custom sets, favorites, random mode, speed/freeze, auto-reload, HUD/theme,
    backups, etc.). This layer adds safer public helpers, refresh controls,
    thumbnail preloading, configurable off-sale loading, and a lightweight
    catalog refresh loop without replacing the original mechanics.
============================================================================]]

local APHELION_ENHANCEMENTS = {
    Version = "2.1.0",
    Busy = false,
    LastRefresh = 0,
    LastThumbnailPreload = 0,
    Connections = {},
}

local function AphelionSafeNotify(title, content, duration)
    pcall(function()
        if getgenv and getgenv().Notify then
            getgenv().Notify({
                Title = title or "Aphelion",
                Content = content or "",
                Duration = duration or 3,
            })
        end
    end)
end

local function AphelionGetBundleThumbnail(bundleId, width, height)
    local id = tonumber(bundleId)
    if not id or id <= 0 then
        return ""
    end
    width = tonumber(width) or 420
    height = tonumber(height) or 420
    return "rbxthumb://type=BundleThumbnail&id=" .. tostring(id) .. "&w=" .. tostring(width) .. "&h=" .. tostring(height)
end

local function AphelionGetAssetThumbnail(assetId, width, height)
    local id = tonumber(assetId)
    if not id or id <= 0 then
        return ""
    end
    width = tonumber(width) or 420
    height = tonumber(height) or 420
    return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=" .. tostring(width) .. "&h=" .. tostring(height)
end

local function AphelionCountValidAnimations(list)
    local count = 0
    if type(list) ~= "table" then
        return 0
    end
    for _, item in ipairs(list) do
        if type(item) == "table" and tonumber(item.id) and tonumber(item.id) > 0 then
            count += 1
        end
    end
    return count
end

local function AphelionCountValidEmotes(list)
    local count = 0
    if type(list) ~= "table" then
        return 0
    end
    for _, item in ipairs(list) do
        if type(item) == "table" and tonumber(item.id) and tonumber(item.id) > 0 then
            count += 1
        end
    end
    return count
end

local function AphelionPreloadAnimationThumbnails(limit)
    if APHELION_ENHANCEMENTS.Busy then
        return
    end

    limit = math.max(1, math.floor(tonumber(limit) or Config.ThumbnailPreloadCount or 48))
    local source = State.originalAnimationsData or State.animationsData or {}
    local seen = {}
    local queued = 0
    APHELION_ENHANCEMENTS.LastThumbnailPreload = tick()

    task.spawn(function()
        for _, animationData in ipairs(source) do
            if queued >= limit then
                break
            end

            local id = tonumber(animationData and animationData.id)
            if id and id > 0 and not seen[id] and not IsCustomSetData(animationData) then
                seen[id] = true
                queued += 1
                local thumbnail = AphelionGetBundleThumbnail(id, 420, 420)
                if thumbnail ~= "" and preloadThumbnail then
                    pcall(preloadThumbnail, thumbnail)
                end
                if queued % 8 == 0 then
                    task.wait()
                end
            end
        end
    end)
end

local function AphelionRefreshCatalog(reason, notifyUser)
    if APHELION_ENHANCEMENTS.Busy then
        return false, "busy"
    end

    APHELION_ENHANCEMENTS.Busy = true
    APHELION_ENHANCEMENTS.LastRefresh = tick()

    local animationBefore = AphelionCountValidAnimations(State.originalAnimationsData)
    local emoteBefore = AphelionCountValidEmotes(State.originalEmotesData)
    local animationOK, emoteOK = true, true

    task.spawn(function()
        local ok1 = pcall(function()
            if fetchAllAnimations then
                fetchAllAnimations()
            end
        end)
        animationOK = ok1

        task.wait(0.05)

        local ok2 = pcall(function()
            if fetchAllEmotes then
                fetchAllEmotes()
            end
        end)
        emoteOK = ok2

        task.wait(0.25)
        pcall(function()
            if State.currentMode == "animation" then
                State.totalPages = calculateTotalPages()
                if State.currentPage > State.totalPages then
                    State.currentPage = State.totalPages
                end
                updatePageDisplay()
                updateAnimations()
            else
                State.totalPages = calculateTotalPages()
                if State.currentPage > State.totalPages then
                    State.currentPage = State.totalPages
                end
                updatePageDisplay()
                updateEmotes()
            end
        end)

        APHELION_ENHANCEMENTS.Busy = false

        local animationAfter = AphelionCountValidAnimations(State.originalAnimationsData)
        local emoteAfter = AphelionCountValidEmotes(State.originalEmotesData)

        if notifyUser ~= false then
            local why = reason and (" [" .. tostring(reason) .. "]") or ""
            local status = "Animation source: " .. (animationOK and "OK" or "FAIL")
                .. " | Emote source: " .. (emoteOK and "OK" or "FAIL")
                .. " | Animations: " .. tostring(animationAfter)
                .. " | Emotes: " .. tostring(emoteAfter)
            if animationBefore == 0 and emoteBefore == 0 then
                status = status .. " | First load"
            end
            AphelionSafeNotify("Aphelion | Catalog", status .. why, 5)
        end

        AphelionPreloadAnimationThumbnails(Config.ThumbnailPreloadCount or 48)
    end)

    return true, "started"
end

local function AphelionSetOffsaleAnimationsEnabled(enabled, notifyUser)
    enabled = enabled ~= false
    offsaleAnimationJson = enabled
    Config.IncludeOffsaleAnimations = enabled
    pcall(SaveConfig)

    if notifyUser ~= false then
        AphelionSafeNotify(
            "Aphelion | Offsale Animations",
            enabled and "✅ Offsale animation entries are enabled." or "⛔ Offsale animation entries are disabled.",
            4
        )
    end

    task.spawn(function()
        AphelionRefreshCatalog("offsale=" .. tostring(enabled), false)
    end)
end

local function AphelionSearchAnimations(term)
    term = tostring(term or "")
    State.currentMode = "animation"
    State.animationSearchTerm = term
    if searchAnimations then
        searchAnimations(term)
    end
end

local function AphelionSearchEmotes(term)
    term = tostring(term or "")
    State.currentMode = "emote"
    State.emoteSearchTerm = term
    if searchEmotes then
        searchEmotes(term)
    end
end

local function AphelionResolveAnimationDataById(animationId)
    local wanted = tonumber(animationId)
    if not wanted then
        return nil
    end

    local lists = {
        State.originalAnimationsData,
        State.animationsData,
        State.filteredAnimations,
    }

    for _, list in ipairs(lists) do
        if type(list) == "table" then
            for _, item in ipairs(list) do
                if tonumber(item and item.id) == wanted then
                    return item
                end
            end
        end
    end

    return nil
end

local function AphelionGetAnimationBundleCardData(animationData)
    if type(animationData) ~= "table" then
        return nil
    end

    local id = tonumber(animationData.id)
    if not id then
        return nil
    end

    return {
        Id = id,
        Name = tostring(animationData.name or ("Animation " .. tostring(id))),
        Thumbnail = IsCustomSetData(animationData)
            and (GetAsset((getCustomSetIcon(GetCustomSetName(animationData) or animationData.name))))
            or AphelionGetBundleThumbnail(id, 420, 420),
        BundledItems = animationData.bundledItems,
        IsCustomSet = IsCustomSetData(animationData),
        IsOffsale = not not animationData.offsale,
    }
end

local function AphelionGetVisibleAnimationCards()
    local output = {}
    local source = State.originalAnimationsData or State.animationsData or {}
    if State.animationSearchTerm and State.animationSearchTerm ~= "" then
        source = State.filteredAnimations or {}
    elseif type(State.filteredAnimations) == "table" and #State.filteredAnimations > 0 then
        source = State.filteredAnimations
    end
    for _, item in ipairs(source) do
        local card = AphelionGetAnimationBundleCardData(item)
        if card then
            table.insert(output, card)
        end
    end
    return output
end

local function AphelionApplyAnimationById(animationId)
    local animationData = AphelionResolveAnimationDataById(animationId)
    if not animationData then
        AphelionSafeNotify("Aphelion | Animation", "❌ Animation bundle not found: " .. tostring(animationId), 3)
        return false
    end

    local ok, err = pcall(function()
        applyAnimation(animationData)
    end)

    if not ok then
        AphelionSafeNotify("Aphelion | Animation", "❌ Failed: " .. tostring(err), 4)
        return false
    end

    return true
end

local function AphelionGetCurrentBundleThumbnailForId(bundleId)
    return AphelionGetBundleThumbnail(bundleId, 420, 420)
end

local function AphelionExportCatalogSnapshot()
    local snapshot = {
        Version = APHELION_ENHANCEMENTS.Version,
        Timestamp = os.time(),
        IncludeOffsaleAnimations = offsaleAnimationJson == true,
        Animations = {},
        Emotes = {},
    }

    for _, item in ipairs(State.originalAnimationsData or {}) do
        table.insert(snapshot.Animations, {
            id = item.id,
            name = item.name,
            bundledItems = item.bundledItems,
        })
    end

    for _, item in ipairs(State.originalEmotesData or {}) do
        table.insert(snapshot.Emotes, {
            id = item.id,
            name = item.name,
        })
    end

    return snapshot
end

getgenv().Aphelion = getgenv().Aphelion or {}
getgenv().Aphelion.Version = APHELION_ENHANCEMENTS.Version
getgenv().Aphelion.GetBundleThumbnail = AphelionGetBundleThumbnail
getgenv().Aphelion.GetAssetThumbnail = AphelionGetAssetThumbnail
getgenv().Aphelion.RefreshCatalog = AphelionRefreshCatalog
getgenv().Aphelion.PreloadAnimationThumbnails = AphelionPreloadAnimationThumbnails
getgenv().Aphelion.SetOffsaleAnimationsEnabled = AphelionSetOffsaleAnimationsEnabled
getgenv().Aphelion.SearchAnimations = AphelionSearchAnimations
getgenv().Aphelion.SearchEmotes = AphelionSearchEmotes
getgenv().Aphelion.ResolveAnimationDataById = AphelionResolveAnimationDataById
getgenv().Aphelion.GetAnimationBundleCardData = AphelionGetAnimationBundleCardData
getgenv().Aphelion.GetVisibleAnimationCards = AphelionGetVisibleAnimationCards
getgenv().Aphelion.ApplyAnimationById = AphelionApplyAnimationById
getgenv().Aphelion.ExportCatalogSnapshot = AphelionExportCatalogSnapshot
getgenv().Aphelion.IsOffsaleEnabled = function()
    return offsaleAnimationJson == true
end

-- Apply persisted enhancement settings if the config loader exposed them.
pcall(function()
    if Config.IncludeOffsaleAnimations == false then
        offsaleAnimationJson = false
    else
        offsaleAnimationJson = true
    end
end)

-- A safe manual refresh hotkey: RightControl + RightShift + R.
table.insert(APHELION_ENHANCEMENTS.Connections,
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode ~= Enum.KeyCode.R then
            return
        end
        local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        local shift = UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        if ctrl and shift then
            AphelionRefreshCatalog("hotkey", true)
        end
    end)
)

-- Periodic refresh. This is intentionally slow and cancellable by setting
-- Config.CatalogAutoRefresh = false from the public Aphelion table or the
-- script's Config object.
task.spawn(function()
    while true do
        local minutes = math.max(5, tonumber(Config.CatalogRefreshMinutes) or 15)
        task.wait(minutes * 60)
        if Config.CatalogAutoRefresh ~= false and not APHELION_ENHANCEMENTS.Busy then
            AphelionRefreshCatalog("auto-refresh", true)
        end
    end
end)

-- Preload the first batch once the initial fetch has had time to populate data.
task.spawn(function()
    for _ = 1, 20 do
        if #(State.originalAnimationsData or {}) > 0 then
            break
        end
        task.wait(0.5)
    end

    AphelionPreloadAnimationThumbnails(Config.ThumbnailPreloadCount or 48)
end)

AphelionSafeNotify(
    "Aphelion | Full Catalog",
    "🔥 Loaded dynamic animation/emote architecture with full bundle resolution + real BundleThumbnail support.",
    5
)



--[[==========================================================================
    FITTING ROOM // MOBILE-FIRST CATALOG UI

    This replaces the old Fluent presentation with a native Roblox UI that is:
      - mobile-first and touch friendly
      - responsive from phones to PC
      - thumbnail driven (BundleThumbnail + AssetThumbnail)
      - lightweight: only the visible page is rendered
      - built for the Fitting Room game, not an executor-only window

    The existing Aphelion backend remains the data/playback layer.
============================================================================]]

getgenv().APHELION_STANDALONE_UI = true
local APHELION_UI_VERSION = "4.0.0"

-- Retire any previous UI instance created by this file.
pcall(function()
    local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local old = pg and pg:FindFirstChild("FittingRoomCatalog")
    if old then old:Destroy() end
end)

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
end)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
if not PlayerGui then
    return
end

-- Compatibility/adaptor layer for the native Fitting Room UI.
-- The original backend remains intact; these helpers only bridge the UI to
-- the backend data/playback/favorite systems that already exist above.
local function APHSafeString(value)
    if value == nil then return "" end
    return tostring(value)
end

local function APHDisplayCount(list)
    return #(list or {})
end

local function APHIsFavorite(kind, item)
    local id = item and item.id
    if not id then return false end
    if kind == "animation" then
        for _, fav in ipairs(State.favoriteAnimations or {}) do
            if tostring(fav.id) == tostring(id) then return true end
        end
    else
        for _, fav in ipairs(State.favoriteEmotes or {}) do
            if tostring(fav.id) == tostring(id) then return true end
        end
    end
    return false
end

local function APHGetCurrentList(kind)
    -- The legacy backend normally keeps filtered* synchronized with the source
    -- lists, but there is a short window during startup/refresh where those
    -- tables are empty while the source list is already available.  Never let
    -- an empty filtered cache hide a populated catalog when no search is active.
    if kind == "animation" then
        local source = State.originalAnimationsData or State.animationsData or {}
        local filtered = State.filteredAnimations
        if State.animationSearchTerm and State.animationSearchTerm ~= "" then
            return filtered or {}
        end
        if type(filtered) == "table" and #filtered > 0 then
            return filtered
        end
        return source
    end

    local source = State.originalEmotesData or State.emotesData or {}
    local filtered = State.filteredEmotes
    if State.emoteSearchTerm and State.emoteSearchTerm ~= "" then
        return filtered or {}
    end
    if type(filtered) == "table" and #filtered > 0 then
        return filtered
    end
    return source
end

local function APHFilterList(list, term)
    list = list or {}
    term = string.lower(APHSafeString(term)):match("^%s*(.-)%s*$")
    if term == "" then return list end

    local out = {}
    local idSearch = term:match("^%d+$") ~= nil
    for _, item in ipairs(list) do
        local ok = false
        if idSearch then
            ok = tostring(item.id) == term
        else
            local name = string.lower(APHSafeString(item.name))
            ok = true
            for word in term:gmatch("%S+") do
                if not name:find(word, 1, true) and not tostring(item.id):find(word, 1, true) then
                    ok = false
                    break
                end
            end
        end
        if ok then
            table.insert(out, item)
        end
    end
    return out
end

local function APHSetSearch(kind, term)
    term = APHSafeString(term)
    if kind == "animation" then
        State.currentMode = "animation"
        State.animationSearchTerm = term:lower()
        State.filteredAnimations = APHFilterList(State.originalAnimationsData or State.animationsData or {}, term)
        State.animationCacheVersion = (State.animationCacheVersion or 0) + 1
        State.emoteCacheVersion = State.emoteCacheVersion or 0
    else
        State.currentMode = "emote"
        State.emoteSearchTerm = term:lower()
        State.filteredEmotes = APHFilterList(State.originalEmotesData or State.emotesData or {}, term)
        State.emoteCacheVersion = (State.emoteCacheVersion or 0) + 1
    end
end

local function APHToggleFavorite(kind, item)
    if not item then return end
    State.currentMode = kind == "animation" and "animation" or "emote"
    local ok = false
    if kind == "animation" and toggleFavoriteAnimation then
        ok = pcall(function() toggleFavoriteAnimation(item) end)
    elseif kind == "emote" and toggleFavorite then
        ok = pcall(function() toggleFavorite(item.id, APHSafeString(item.name)) end)
    end
    if not ok then
        -- Keep the native UI functional even if a legacy UI-only callback fails.
        if kind == "animation" then
            local found
            for i, fav in ipairs(State.favoriteAnimations or {}) do
                if tostring(fav.id) == tostring(item.id) then found = i break end
            end
            if found then
                table.remove(State.favoriteAnimations, found)
            else
                table.insert(State.favoriteAnimations, {
                    id = item.id, name = APHSafeString(item.name) .. " - ⭐",
                    bundledItems = item.bundledItems,
                    isCustomSet = item.isCustomSet,
                    customSetName = item.customSetName,
                })
            end
        else
            local found
            for i, fav in ipairs(State.favoriteEmotes or {}) do
                if tostring(fav.id) == tostring(item.id) then found = i break end
            end
            if found then
                table.remove(State.favoriteEmotes, found)
            else
                table.insert(State.favoriteEmotes, {id = item.id, name = APHSafeString(item.name) .. " - ⭐"})
            end
        end
        State.favoriteSetVersion = (State.favoriteSetVersion or 0) + 1
    end
end

local function APHPlayItem(kind, item)
    if not item or not item.id then return false end
    State.currentMode = kind == "animation" and "animation" or "emote"
    local _, humanoid = getCharacterAndHumanoid()
    if not humanoid then return false end

    pcall(stopCurrentEmote)
    pcall(stopEmotes)

    if kind == "animation" then
        -- Bundle cards represent a complete animation set. Do NOT treat them
        -- like emotes or single previews: apply Idle, Walk, Run, Jump, Fall,
        -- Climb and Swim into the character's Animate controller.
        if item.bundledItems or item.isCustomSet then
            local ok, err = pcall(function()
                applyAnimation(item)
            end)
            if not ok then
                warn("Aphelion | bundle apply failed: " .. tostring(err))
                return false
            end

            -- Remember this exact bundle and make it the persistent startup
            -- selection. Respawns and fresh executions will restore it.
            getgenv().lastPlayedAnimation = item
            Config.LastPlayedAnimationData = item
            task.spawn(SaveConfig)
            AphelionBundleRestoreToken += 1
            return true
        end

        -- Legacy fallback for a single animation asset.
        local previewOk = false
        if playAnimationPreview then
            previewOk = pcall(function() return playAnimationPreview(item) end)
        end
        local track = State.currentEmoteTrack
        if track and track:IsA("AnimationTrack") then
            pcall(function()
                track.Looped = true
                if not track.IsPlaying then track:Play(0.12, 1, 1) end
            end)
            return true
        end
        return previewOk
    end

    local emoteId = tonumber(item.id)
    if not emoteId then return false end
    local ok, track = pcall(function()
        return humanoid:PlayEmoteAndGetAnimTrackById(emoteId)
    end)
    if ok and track and typeof(track) == "Instance" and track:IsA("AnimationTrack") then
        State.currentEmoteTrack = track
        pcall(function()
            track.Priority = Enum.AnimationPriority.Action
            track.Looped = true
            if not track.IsPlaying then track:Play(0.12, 1, 1) end
        end)
        return true
    end

    if playEmote then
        local fallback = pcall(function() playEmote(humanoid, emoteId) end)
        local fallbackTrack = State.currentEmoteTrack
        if fallbackTrack and fallbackTrack:IsA("AnimationTrack") then
            pcall(function() if not fallbackTrack.IsPlaying then fallbackTrack:Play(0.12, 1, 1) end end)
            return true
        end
        return fallback
    end
    return false
end

UIState = {
    mode = "animation", -- animation / emote / favorite
    animationPage = 1,
    emotePage = 1,
    favoritePage = 1,
    perPage = 8,
    search = "",
    favoriteMode = false,
    minimized = false,
    built = false,
    generation = 0,
    searchTicket = 0,
}

Theme = {
    Background = Color3.fromRGB(9, 11, 16),
    Surface = Color3.fromRGB(15, 18, 25),
    Surface2 = Color3.fromRGB(21, 25, 34),
    Card = Color3.fromRGB(18, 22, 30),
    CardHover = Color3.fromRGB(26, 31, 42),
    Text = Color3.fromRGB(244, 247, 252),
    Muted = Color3.fromRGB(143, 153, 170),
    Accent = Color3.fromRGB(85, 172, 255),
    Accent2 = Color3.fromRGB(131, 87, 255),
    Good = Color3.fromRGB(74, 222, 168),
    Border = Color3.fromRGB(54, 63, 78),
    Danger = Color3.fromRGB(255, 92, 110),
}

function new(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

function round(obj, radius)
    new("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, obj)
end

function stroke(obj, color, transparency, thickness)
    return new("UIStroke", {
        Color = color or Theme.Border,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

function gradient(obj, c1, c2, rotation)
    return new("UIGradient", {
        Color = ColorSequence.new(c1 or Theme.Surface2, c2 or Theme.Surface),
        Rotation = rotation or 90,
    }, obj)
end

local function tween(obj, duration, props, style, direction)
    if not obj then return end
    local ok, t = pcall(function()
        return TweenService:Create(obj, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), props or {})
    end)
    if ok and t then t:Play(); return t end
end

local function buttonFX(button, normalColor, hoverColor, pressedColor)
    if not button or not button:IsA("GuiButton") then return end
    local fxScale = button:FindFirstChild("FXScale")
    if not fxScale then
        fxScale = Instance.new("UIScale")
        fxScale.Name = "FXScale"
        fxScale.Scale = 1
        fxScale.Parent = button
    end
    button.AutoButtonColor = false
    button.MouseEnter:Connect(function()
        tween(button, 0.12, {BackgroundColor3 = hoverColor or normalColor})
        tween(fxScale, 0.12, {Scale = 1.025})
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.14, {BackgroundColor3 = normalColor})
        tween(fxScale, 0.14, {Scale = 1})
    end)
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tween(button, 0.06, {BackgroundColor3 = pressedColor or hoverColor or normalColor})
            tween(fxScale, 0.06, {Scale = 0.985})
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tween(button, 0.10, {BackgroundColor3 = normalColor})
            tween(fxScale, 0.10, {Scale = 1})
        end
    end)
end

function setText(label, text)
    label.Text = APHSafeString(text)
end

function getBundleThumb(bundleId, size)
    return AphelionGetBundleThumbnail(bundleId, size or 420, size or 420)
end

function getAssetThumb(assetId, size)
    local id = tonumber(assetId)
    if not id then return "" end
    return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=" .. tostring(size or 420) .. "&h=" .. tostring(size or 420)
end

function getItemThumbnail(kind, item, size)
    size = size or 420
    if type(item) ~= "table" then return "" end

    if item.Thumbnail and item.Thumbnail ~= "" then
        return item.Thumbnail
    end

    if kind == "animation" then
        local bundleId = tonumber(item.id)
        if item.bundledItems and bundleId then
            return getBundleThumb(bundleId, size)
        end
        return getAssetThumb(item.id, size)
    end

    return getAssetThumb(item.id, size)
end

rebuild = nil

function favoriteFor(kind, item)
    local ok, result = pcall(function()
        return APHIsFavorite(kind, item)
    end)
    return ok and result == true
end

function playItem(kind, item)
    if UIState.favoriteMode then
        APHToggleFavorite(kind, item)
        task.defer(function()
            UIState.generation += 1
        end)
        return
    end

    local ok = APHPlayItem(kind, item)
    if ok then
        AphelionSafeNotify("Aphelion", "▶ " .. APHSafeString(item.name or "Item"), 2)
    else
        AphelionSafeNotify("Aphelion", "Could not play " .. APHSafeString(item.name or "item"), 3)
    end
end

Screen = new("ScreenGui", {
    Name = "FittingRoomCatalog",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 500,
}, PlayerGui)

RootScale = new("UIScale", {Scale = 1}, Screen)
local function updateScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    if vp.X <= 430 then
        RootScale.Scale = math.clamp(vp.X / 430, 0.78, 0.94)
    elseif vp.X <= 760 then
        RootScale.Scale = math.clamp(vp.X / 760, 0.84, 0.98)
    else
        RootScale.Scale = 1
    end
    if Main and Main.Parent then
        local aspect = vp.X / math.max(vp.Y, 1)
        if aspect < 0.9 then
            Main.Size = UDim2.new(0.94, 0, 0.88, 0)
        elseif vp.X < 700 then
            Main.Size = UDim2.new(0.95, 0, 0.90, 0)
        else
            Main.Size = UDim2.new(0.90, 0, 0.84, 0)
        end
    end
end

local Main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.90, 0, 0.84, 0),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = 0.03,
}, Screen)
round(Main, 20)
stroke(Main, Theme.Border, 0.18, 1.2)
gradient(Main, Color3.fromRGB(16, 19, 28), Color3.fromRGB(8, 10, 15), 115)

updateScale()
pcall(function()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end)

local Top = new("Frame", {
    Name = "Top",
    Size = UDim2.new(1, -20, 0, 58),
    Position = UDim2.fromOffset(10, 10),
    BackgroundTransparency = 1,
}, Main)

local Brand = new("TextLabel", {
    Size = UDim2.new(0, 210, 0, 27),
    Position = UDim2.fromOffset(4, 1),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "APHELION",
    TextSize = 21,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Top)

local SubBrand = new("TextLabel", {
    Size = UDim2.new(1, -6, 0, 18),
    Position = UDim2.fromOffset(5, 31),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "ANIMATIONS  •  EMOTES  •  YOUR STYLE",
    TextSize = 10,
    TextColor3 = Theme.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Top)

local function topButton(text, color)
    local b = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = color or Theme.Surface2,
        Text = text,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
    }, Top)
    round(b, 12)
    stroke(b, Theme.Border, 0.25, 1)
    return b
end

local MinBtn = topButton("—", Theme.Surface2)
MinBtn.AnchorPoint = Vector2.new(1, 0)
MinBtn.Position = UDim2.new(1, -48, 0, 2)
MinBtn.Size = UDim2.fromOffset(42, 42)

local CloseBtn = topButton("×", Color3.fromRGB(38, 23, 29))
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.Position = UDim2.new(1, 0, 0, 2)
CloseBtn.Size = UDim2.fromOffset(42, 42)
buttonFX(MinBtn, Theme.Surface2, Theme.CardHover)
buttonFX(CloseBtn, Color3.fromRGB(38, 23, 29), Color3.fromRGB(70, 32, 42), Color3.fromRGB(58, 28, 38))

local Tabs = new("Frame", {
    Name = "Tabs",
    Size = UDim2.new(1, -20, 0, 43),
    Position = UDim2.fromOffset(10, 66),
    BackgroundTransparency = 1,
}, Main)

local TabLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 7),
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
}, Tabs)

local TabButtons = {}
refreshTabStyle = nil
local function addTab(id, title)
    local b = new("TextButton", {
        Name = id,
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Surface2,
        Size = UDim2.fromOffset(130, 43),
        Text = title,
        TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, Tabs)
    round(b, 11)
    stroke(b, Theme.Border, 0.35, 1)
    TabButtons[id] = b
    return b
end

addTab("Animations", "ANIMATIONS")
addTab("Emotes", "EMOTES")
addTab("Favorites", "★ FAVORITES")

local function resizeTopAndTabs()
    local w = Tabs.AbsoluteSize.X
    local gap = 7
    local bw = math.max(86, math.floor((w - gap * 2) / 3))
    for _, button in pairs(TabButtons) do
        button.Size = UDim2.fromOffset(bw, 43)
    end
    local topW = Top.AbsoluteSize.X
    local rightSpace = 98
    Brand.Size = UDim2.new(1, -rightSpace, 0, 27)
    SubBrand.Size = UDim2.new(1, -rightSpace, 0, 18)
    SubBrand.Visible = topW >= 320
end

Tabs:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeTopAndTabs)
Top:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeTopAndTabs)

Tools = new("Frame", {
    Name = "Tools",
    Size = UDim2.new(1, -20, 0, 42),
    Position = UDim2.fromOffset(10, 112),
    BackgroundTransparency = 1,
}, Main)

SearchBox = new("TextBox", {
    Name = "Search",
    Size = UDim2.new(1, -150, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Theme.Surface,
    TextColor3 = Theme.Text,
    PlaceholderColor3 = Theme.Muted,
    PlaceholderText = "Search animations, emotes or IDs...",
    ClearTextOnFocus = false,
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Tools)
round(SearchBox, 12)
stroke(SearchBox, Theme.Border, 0.2, 1)
new("UIPadding", {PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 12)}, SearchBox)

FavModeBtn = new("TextButton", {
    Name = "FavoriteMode",
    AutoButtonColor = false,
    Size = UDim2.fromOffset(132, 42),
    Position = UDim2.new(1, -132, 0, 0),
    BackgroundColor3 = Theme.Surface2,
    Text = "☆  FAVORITE MODE",
    TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
}, Tools)
round(FavModeBtn, 12)
stroke(FavModeBtn, Theme.Border, 0.25, 1)

function resizeTools()
    local w = Tools.AbsoluteSize.X
    local favW = math.clamp(math.floor(w * 0.34), 112, 140)
    FavModeBtn.Size = UDim2.fromOffset(favW, 42)
    FavModeBtn.Position = UDim2.new(1, -favW, 0, 0)
    SearchBox.Size = UDim2.new(1, -favW - 8, 1, 0)
    SearchBox.TextSize = w < 360 and 12 or 13
    FavModeBtn.TextSize = w < 360 and 9 or 10
end

Tools:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeTools)

Info = new("Frame", {
    Name = "Info",
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.fromOffset(10, 160),
    BackgroundTransparency = 1,
}, Main)

Status = new("TextLabel", {
    Size = UDim2.new(1, -145, 1, 0),
    BackgroundTransparency = 1,
    Text = "Loading catalog...",
    TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Info)

Utility = new("Frame", {
    Size = UDim2.fromOffset(138, 30),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
}, Info)
UtilLayout = new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6)}, Utility)

RandomBtn = new("TextButton", {
    AutoButtonColor = false,
    Size = UDim2.fromOffset(65, 30),
    BackgroundColor3 = Theme.Surface2,
    Text = "RANDOM",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
}, Utility)
round(RandomBtn, 9)
buttonFX(RandomBtn, Theme.Surface2, Theme.CardHover)

StopBtn = new("TextButton", {
    AutoButtonColor = false,
    Size = UDim2.fromOffset(65, 30),
    BackgroundColor3 = Color3.fromRGB(39, 24, 31),
    Text = "STOP",
    TextColor3 = Theme.Danger,
    Font = Enum.Font.GothamBold,
    TextSize = 9,
}, Utility)
round(StopBtn, 9)
buttonFX(StopBtn, Color3.fromRGB(39, 24, 31), Color3.fromRGB(55, 31, 40), Color3.fromRGB(65, 30, 45))

List = new("ScrollingFrame", {
    Name = "Catalog",
    Size = UDim2.new(1, -20, 1, -258),
    Position = UDim2.fromOffset(10, 192),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.Accent,
}, Main)

ListPad = new("UIPadding", {
    PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1),
    PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6),
}, List)

Grid = new("UIGridLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    CellPadding = UDim2.fromOffset(8, 8),
    CellSize = UDim2.fromOffset(260, 116),
}, List)

Bottom = new("Frame", {
    Size = UDim2.new(1, -20, 0, 44),
    Position = UDim2.new(0, 10, 1, -54),
    BackgroundTransparency = 1,
}, Main)

PrevBtn = new("TextButton", {
    AutoButtonColor = false, Size = UDim2.fromOffset(82, 44),
    BackgroundColor3 = Theme.Surface2, Text = "‹  PREV", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold, TextSize = 10,
}, Bottom)
round(PrevBtn, 11)
buttonFX(PrevBtn, Theme.Surface2, Theme.CardHover)

PageLabel = new("TextLabel", {
    Size = UDim2.new(1, -180, 1, 0), Position = UDim2.fromOffset(90, 0),
    BackgroundTransparency = 1, Text = "PAGE 1 / 1", TextColor3 = Theme.Muted,
    Font = Enum.Font.GothamBold, TextSize = 11,
}, Bottom)

NextBtn = new("TextButton", {
    AutoButtonColor = false, Size = UDim2.fromOffset(82, 44),
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Surface2, Text = "NEXT  ›", TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBold, TextSize = 10,
}, Bottom)
round(NextBtn, 11)
buttonFX(NextBtn, Theme.Surface2, Theme.CardHover)

FloatingOpen = new("TextButton", {
    Name = "OpenButton",
    Visible = false,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -14),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = Theme.Surface2,
    Text = "FR",
    TextColor3 = Theme.Text,
    Font = Enum.Font.GothamBlack,
    TextSize = 16,
    ZIndex = 900,
}, Screen)
round(FloatingOpen, 29)
stroke(FloatingOpen, Theme.Accent, 0.08, 1.6)
buttonFX(FloatingOpen, Theme.Surface2, Color3.fromRGB(29, 49, 75), Color3.fromRGB(35, 65, 96))

local function makeDraggable(guiObject)
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    local moved = false
    local threshold = 7

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        moved = false
        dragStart = input.Position
        -- Store absolute pixels so a UDim2 scale/anchor at the starting position
        -- cannot cause the first drag frame to jump.
        startPos = UDim2.fromOffset(guiObject.AbsolutePosition.X, guiObject.AbsolutePosition.Y)
        guiObject.AnchorPoint = Vector2.new(0, 0)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput or not dragStart or not startPos then return end
        local delta = input.Position - dragStart
        if math.abs(delta.X) > threshold or math.abs(delta.Y) > threshold then moved = true end
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        local size = guiObject.AbsoluteSize
        local x = math.clamp(startPos.X.Offset + delta.X, 8, math.max(8, vp.X - size.X - 8))
        local y = math.clamp(startPos.Y.Offset + delta.Y, 8, math.max(8, vp.Y - size.Y - 8))
        guiObject.AnchorPoint = Vector2.new(0, 0)
        guiObject.Position = UDim2.fromOffset(x, y)
    end)

    return function() return moved end
end

local floatingWasDragged = makeDraggable(FloatingOpen)

function resizeGrid()
    local width = math.max(200, List.AbsoluteSize.X - 2)
    local gap = 8
    local minWidth = 188
    local columns = math.clamp(math.floor((width + gap) / (minWidth + gap)), 1, 4)
    local cellWidth = math.floor((width - gap * (columns - 1)) / columns)
    local mobile = width < 420
    Grid.CellSize = UDim2.fromOffset(math.max(170, cellWidth), mobile and 104 or 116)
    Grid.FillDirectionMaxCells = columns
end
resizeGrid()
resizeTools()
resizeTopAndTabs()
List:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)

function clearCards()
    for _, child in ipairs(List:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

function makeCard(kind, item, layoutOrder)
    local card = new("Frame", {
        LayoutOrder = layoutOrder,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
    }, List)
    round(card, 14)
    stroke(card, Theme.Border, 0.38, 1)
    gradient(card, Color3.fromRGB(26, 31, 42), Color3.fromRGB(14, 17, 23), 35)

    local cardWidth = math.max(180, List.AbsoluteSize.X)
    local compact = cardWidth < 360
    local thumbSize = compact and 78 or 92
    local contentX = thumbSize + 22
    local thumbHolder = new("Frame", {
        Size = UDim2.fromOffset(thumbSize, thumbSize),
        Position = UDim2.fromOffset(10, 12),
        BackgroundColor3 = Color3.fromRGB(10, 12, 17),
        BorderSizePixel = 0,
    }, card)
    round(thumbHolder, 12)
    stroke(thumbHolder, Theme.Border, 0.35, 1)

    local thumb = new("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = getItemThumbnail(kind, item, 420),
        ScaleType = Enum.ScaleType.Crop,
    }, thumbHolder)
    round(thumb, 12)

    local loading = new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = "• • •", TextColor3 = Theme.Muted,
        Font = Enum.Font.GothamBold, TextSize = 14,
    }, thumbHolder)
    task.spawn(function()
        local image = thumb.Image
        if image == "" then
            loading.Text = "NO PREVIEW"
            loading.TextSize = 8
        else
            pcall(function()
                ContentProvider:PreloadAsync({thumb})
            end)
            if thumb.Image ~= "" then
                loading.Visible = false
            end
        end
    end)

    local fav = new("TextButton", {
        AutoButtonColor = false,
        Size = UDim2.fromOffset(34, 34),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 8),
        BackgroundColor3 = Color3.fromRGB(10, 12, 17),
        BackgroundTransparency = 0.08,
        Text = favoriteFor(kind, item) and "★" or "☆",
        TextColor3 = favoriteFor(kind, item) and Theme.Accent or Theme.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
    }, card)
    round(fav, 10)

    local title = APHSafeString(item.name or ((kind == "animation" and "Animation" or "Emote") .. " " .. APHSafeString(item.id)))
    if #title > 38 then title = title:sub(1, 35) .. "..." end

    local titleLabel = new("TextLabel", {
        Size = UDim2.new(1, -contentX - 8, 0, 38),
        Position = UDim2.fromOffset(contentX, 12),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = compact and 11 or 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, card)

    local typeText = (kind == "animation" and (item.bundledItems and "BUNDLE" or "ANIMATION") or "EMOTE")
    local meta = new("TextLabel", {
        Size = UDim2.new(1, -contentX - 8, 0, 28),
        Position = UDim2.fromOffset(contentX, 53),
        BackgroundTransparency = 1,
        Text = typeText .. "  •  ID " .. APHSafeString(item.id) .. (item.offsale and "  •  OFFSALE" or ""),
        TextColor3 = item.offsale and Color3.fromRGB(247, 183, 83) or Theme.Muted,
        Font = Enum.Font.GothamMedium,
        TextSize = compact and 8 or 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, card)

    local action = new("TextButton", {
        AutoButtonColor = false,
        Size = UDim2.new(1, -contentX - 8, 0, 28),
        Position = UDim2.fromOffset(contentX, compact and 76 or 80),
        BackgroundColor3 = Theme.Surface2,
        Text = UIState.favoriteMode and "ADD TO FAVORITES" or "PLAY",
        TextColor3 = UIState.favoriteMode and Theme.Accent or Theme.Good,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
    }, card)
    round(action, 8)
    buttonFX(action, Theme.Surface2, Color3.fromRGB(29, 52, 75), Color3.fromRGB(34, 67, 92))
    buttonFX(fav, Color3.fromRGB(10, 12, 17), Color3.fromRGB(26, 31, 42), Color3.fromRGB(34, 40, 54))

    local cardStroke = card:FindFirstChildOfClass("UIStroke")
    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 1
    cardScale.Name = "HoverScale"
    cardScale.Parent = card
    card.MouseEnter:Connect(function()
        tween(card, 0.14, {BackgroundColor3 = Theme.CardHover})
        tween(cardScale, 0.14, {Scale = 1.012})
        if cardStroke then tween(cardStroke, 0.14, {Transparency = 0.08, Thickness = 1.2}) end
    end)
    card.MouseLeave:Connect(function()
        tween(card, 0.18, {BackgroundColor3 = Theme.Card})
        tween(cardScale, 0.18, {Scale = 1})
        if cardStroke then tween(cardStroke, 0.18, {Transparency = 0.38, Thickness = 1}) end
    end)

    local function activate()
        playItem(kind, item)
        task.defer(function()
            if UIState.favoriteMode then
                rebuild()
            end
        end)
    end

    action.Activated:Connect(activate)
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activate()
        end
    end)
    titleLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activate()
        end
    end)
    fav.Activated:Connect(function()
        APHToggleFavorite(kind, item)
        task.defer(rebuild)
    end)

    return card, thumb
end

function favoriteList()
    local out = {}
    for _, item in ipairs(State.favoriteAnimations or {}) do
        table.insert(out, {kind = "animation", item = item})
    end
    for _, item in ipairs(State.favoriteEmotes or {}) do
        table.insert(out, {kind = "emote", item = item})
    end
    return out
end

function getViewData()
    if UIState.mode == "favorite" then
        local source = favoriteList()
        local q = string.lower(UIState.search or "")
        if q ~= "" then
            local filtered = {}
            for _, entry in ipairs(source) do
                local text = string.lower(APHSafeString(entry.item.name) .. " " .. APHSafeString(entry.item.id))
                if string.find(text, q, 1, true) then
                    table.insert(filtered, entry)
                end
            end
            source = filtered
        end
        return source
    end

    local kind = UIState.mode
    return APHGetCurrentList(kind)
end

function getPage()
    if UIState.mode == "animation" then return UIState.animationPage end
    if UIState.mode == "emote" then return UIState.emotePage end
    return UIState.favoritePage
end

function setPage(page)
    if UIState.mode == "animation" then UIState.animationPage = page
    elseif UIState.mode == "emote" then UIState.emotePage = page
    else UIState.favoritePage = page end
end

rebuild = function()
    if not Main.Parent then return end
    UIState.generation += 1
    local generation = UIState.generation
    clearCards()

    local data = getViewData()
    local total = #data
    local perPage = UIState.perPage
    local pages = math.max(1, math.ceil(total / perPage))
    local page = math.clamp(getPage(), 1, pages)
    setPage(page)

    local query = UIState.search ~= "" and ('  •  "' .. UIState.search .. '"') or ""
    local modeName = UIState.mode == "animation" and "ANIMATIONS" or UIState.mode == "emote" and "EMOTES" or "FAVORITES"
    Status.Text = modeName .. "  •  " .. tostring(total) .. " ITEMS" .. query
    PageLabel.Text = "PAGE " .. tostring(page) .. " / " .. tostring(pages)

    if total == 0 then
        local empty = new("Frame", {
            Size = UDim2.new(1, -4, 0, 165),
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
        }, List)
        round(empty, 16)
        local e1 = new("TextLabel", {Size = UDim2.new(1, -30, 0, 34), Position = UDim2.fromOffset(15, 42), BackgroundTransparency = 1, Text = "NOTHING HERE YET", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 17}, empty)
        local e2 = new("TextLabel", {Size = UDim2.new(1, -40, 0, 38), Position = UDim2.fromOffset(20, 82), BackgroundTransparency = 1, Text = "Try another search, refresh the catalog, or add favorites.", TextColor3 = Theme.Muted, Font = Enum.Font.GothamMedium, TextSize = 11, TextWrapped = true}, empty)
        Grid.CellSize = UDim2.new(1, -4, 0, 165)
        return
    end

    resizeGrid()
    local first = (page - 1) * perPage + 1
    local last = math.min(total, first + perPage - 1)
    local order = 0
    for i = first, last do
        if generation ~= UIState.generation then return end
        local entry = data[i]
        local kind, item
        if UIState.mode == "favorite" then
            kind, item = entry.kind, entry.item
        else
            kind, item = UIState.mode, entry
        end
        order += 1
        makeCard(kind, item, order)
    end

    task.spawn(function()
        -- Preload just the current page: much lighter on mobile memory/network.
        local batch = {}
        for _, child in ipairs(List:GetChildren()) do
            if child:IsA("Frame") then
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("ImageLabel") and desc.Image ~= "" then
                        table.insert(batch, desc)
                        break
                    end
                end
            end
        end
        if #batch > 0 then pcall(function() ContentProvider:PreloadAsync(batch) end) end
    end)
end

-- Search is debounced because typing directly into a large catalog should not
-- rebuild the entire page on every single keystroke.
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    UIState.searchTicket += 1
    local ticket = UIState.searchTicket
    task.delay(0.18, function()
        if ticket ~= UIState.searchTicket then return end
        UIState.search = SearchBox.Text
        if UIState.mode == "animation" then
            APHSetSearch("animation", UIState.search)
            UIState.animationPage = 1
        elseif UIState.mode == "emote" then
            APHSetSearch("emote", UIState.search)
            UIState.emotePage = 1
        else
            UIState.favoritePage = 1
        end
        rebuild()
    end)
end)

for id, button in pairs(TabButtons) do
    buttonFX(button, Theme.Surface2, Color3.fromRGB(27, 42, 61), Color3.fromRGB(31, 51, 76))
    button.Activated:Connect(function()
        UIState.mode = id == "Animations" and "animation" or id == "Emotes" and "emote" or "favorite"
        if UIState.mode == "animation" or UIState.mode == "emote" then
            State.currentMode = UIState.mode
        end
        UIState.search = ""
        SearchBox.Text = ""
        rebuild()
        refreshTabStyle()
    end)
end

refreshTabStyle = function()
    for id, button in pairs(TabButtons) do
        local active = (id == "Animations" and UIState.mode == "animation")
            or (id == "Emotes" and UIState.mode == "emote")
            or (id == "Favorites" and UIState.mode == "favorite")
        button.BackgroundColor3 = active and Color3.fromRGB(29, 49, 75) or Theme.Surface2
        button.TextColor3 = active and Theme.Accent or Theme.Muted
    end
    FavModeBtn.BackgroundColor3 = UIState.favoriteMode and Color3.fromRGB(29, 49, 75) or Theme.Surface2
    FavModeBtn.TextColor3 = UIState.favoriteMode and Theme.Accent or Theme.Muted
    FavModeBtn.Text = UIState.favoriteMode and "★  FAVORITE MODE" or "☆  FAVORITE MODE"
end

FavModeBtn.Activated:Connect(function()
    UIState.favoriteMode = not UIState.favoriteMode
    refreshTabStyle()
    rebuild()
end)

PrevBtn.Activated:Connect(function()
    local page = getPage()
    local data = getViewData()
    local pages = math.max(1, math.ceil(#data / UIState.perPage))
    page -= 1
    if page < 1 then page = pages end
    setPage(page)
    rebuild()
end)

NextBtn.Activated:Connect(function()
    local page = getPage()
    local data = getViewData()
    local pages = math.max(1, math.ceil(#data / UIState.perPage))
    page += 1
    if page > pages then page = 1 end
    setPage(page)
    rebuild()
end)

RandomBtn.Activated:Connect(function()
    local data = getViewData()
    if #data == 0 then
        AphelionSafeNotify("Aphelion", "Catalog is still loading.", 2)
        return
    end
    local entry = data[math.random(1, #data)]
    if UIState.mode == "favorite" then
        playItem(entry.kind, entry.item)
    else
        playItem(UIState.mode, entry)
    end
end)

StopBtn.Activated:Connect(function()
    pcall(stopCurrentEmote)
end)

function setMinimized(v)
    UIState.minimized = v == true
    if UIState.minimized then
        local mainScale = Main:FindFirstChild("MinScale") or Instance.new("UIScale")
        mainScale.Name = "MinScale"
        mainScale.Scale = 1
        mainScale.Parent = Main
        tween(mainScale, 0.16, {Scale = 0.985})
        task.delay(0.16, function()
            if UIState.minimized and Main.Parent then Main.Visible = false end
        end)
        FloatingOpen.Visible = true
    else
        Main.Visible = true
        local mainScale = Main:FindFirstChild("MinScale")
        if mainScale then mainScale.Scale = 0.985 end
        if mainScale then tween(mainScale, 0.22, {Scale = 1}) end
        FloatingOpen.Visible = false
    end
end

MinBtn.Activated:Connect(function()
    setMinimized(true)
end)

FloatingOpen.Activated:Connect(function()
    if floatingWasDragged and floatingWasDragged() then return end
    setMinimized(false)
end)

CloseBtn.Activated:Connect(function()
    Screen:Destroy()
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
    end)
end)

-- Keep the UI synced with backend refreshes without rebuilding every frame.
task.spawn(function()
    local lastA, lastE, lastFA, lastFE = -1, -1, -1, -1
    while Screen.Parent do
        task.wait(2)
        local a = APHDisplayCount(State.originalAnimationsData or State.animationsData)
        local e = APHDisplayCount(State.originalEmotesData or State.emotesData)
        local fa = #(State.favoriteAnimations or {})
        local fe = #(State.favoriteEmotes or {})
        if a ~= lastA or e ~= lastE or fa ~= lastFA or fe ~= lastFE then
            lastA, lastE, lastFA, lastFE = a, e, fa, fe
            pcall(rebuild)
        end
    end
end)

refreshTabStyle()
APHSetSearch("animation", "")
APHSetSearch("emote", "")
State.currentMode = "animation"
rebuild()

-- Wait briefly for the dynamic backend before forcing the first populated render.
task.spawn(function()
    for _ = 1, 30 do
        if not Screen.Parent then return end
        local a = APHDisplayCount(State.originalAnimationsData or State.animationsData)
        local e = APHDisplayCount(State.originalEmotesData or State.emotesData)
        if a > 0 or e > 0 then
            rebuild()
            break
        end
        task.wait(0.5)
    end
end)

getgenv().Aphelion = getgenv().Aphelion or {}
getgenv().Aphelion.UILibrary = "NativeRobloxUI"
getgenv().Aphelion.UIVersion = APHELION_UI_VERSION
getgenv().Aphelion.StandaloneUI = true
getgenv().Aphelion.MobileOptimized = true
getgenv().Aphelion.ThumbnailUI = true

AphelionSafeNotify(
    "APHELION | UI",
    "✨ Mobile-first catalog loaded • responsive cards • bundle + emote thumbnails",
    4
)


--[[==========================================================================
    APHELION // FEATURE PACK 5.0

    New player-facing features added without replacing the legacy backend:

      1) MIX STUDIO
         Build a personal animation bundle by taking individual motion slots
         from different catalog bundles. Example:
           Idle  -> Adidas Community
           Walk  -> Ninja
           Run   -> Astronaut
           Jump  -> Stylized
         The mixed result is stored using the same custom-animation format that
         the existing backend already understands.

      2) STYLE VAULT
         Save, duplicate, apply, rename and remove custom mixed styles.  Mix
         metadata is preserved so a saved style can be reopened in Mix Studio.

      3) MOTION LAB
         Build a lightweight animation/emote queue and play it in sequence,
         loop it, shuffle it, or clear it.  Only the current queue is kept in
         memory; the catalog remains lazily loaded for mobile devices.

    Everything in this block is namespaced with APHX_/APHELION_FEATURES where
    practical so it does not overwrite the original animation backend.
============================================================================]]

APHELION_FEATURES = {
    Version = "5.0.0",
    Open = false,
    ActiveTab = "Mix",
    Panel = nil,
    Overlay = nil,
    Connections = {},
    Mix = {
        SelectedSlot = "idle",
        Query = "",
        Revision = 0,
        SourceRevision = 0,
        Resolved = {},
        Slots = {},
        PreviousSnapshots = {},
        MaxSnapshots = 24,
        Busy = false,
    },
    Vault = {
        Query = "",
        Revision = 0,
        SelectedStyle = nil,
    },
    Queue = {
        Items = {},
        Playing = false,
        Loop = true,
        Shuffle = false,
        Interval = 2.5,
        Token = 0,
        Revision = 0,
        CurrentIndex = 0,
    },
    UI = {
        MixContent = nil,
        VaultContent = nil,
        LabContent = nil,
        SlotScroll = nil,
        SourceScroll = nil,
        SourceSearch = nil,
        MixStatus = nil,
        StyleScroll = nil,
        LabScroll = nil,
        LabStatus = nil,
    },
}

APHX_SLOT_ORDER = {
    "idle",
    "walk",
    "run",
    "jump",
    "fall",
    "climb",
    "swimidle",
    "swim",
}

APHX_SLOT_DEFS = {
    idle = {
        Label = "IDLE",
        CategoryNames = {"idle"},
        AnimationNames = {"Animation1", "Animation2"},
        Description = "Standing / idle loop",
    },
    walk = {
        Label = "WALK",
        CategoryNames = {"walk"},
        AnimationNames = {"WalkAnim"},
        Description = "Walking cycle",
    },
    run = {
        Label = "RUN",
        CategoryNames = {"run"},
        AnimationNames = {"RunAnim"},
        Description = "Running cycle",
    },
    jump = {
        Label = "JUMP",
        CategoryNames = {"jump"},
        AnimationNames = {"JumpAnim"},
        Description = "Jump start",
    },
    fall = {
        Label = "FALL",
        CategoryNames = {"fall"},
        AnimationNames = {"FallAnim"},
        Description = "Falling cycle",
    },
    climb = {
        Label = "CLIMB",
        CategoryNames = {"climb"},
        AnimationNames = {"ClimbAnim"},
        Description = "Ladder / climbing",
    },
    swimidle = {
        Label = "SWIM IDLE",
        CategoryNames = {"swimidle", "swimidling", "swimidleloop"},
        AnimationNames = {"SwimIdle"},
        Description = "Floating in water",
    },
    swim = {
        Label = "SWIM",
        CategoryNames = {"swim"},
        AnimationNames = {"Swim"},
        Description = "Swimming cycle",
    },
}

function APHX_String(value)
    if value == nil then
        return ""
    end
    return tostring(value)
end

function APHX_Number(value, fallback)
    local n = tonumber(value)
    if n == nil then
        return fallback
    end
    return n
end

function APHX_Trim(value)
    return APHX_String(value):match("^%s*(.-)%s*$") or ""
end

function APHX_Lower(value)
    return string.lower(APHX_String(value))
end

function APHX_NormalizeId(value)
    local text = APHX_String(value)
    text = text:gsub("rbxassetid://", "")
    text = text:gsub("http://www%.roblox%.com/asset/%?id=", "")
    text = text:gsub("https://www%.roblox%.com/asset/%?id=", "")
    return tonumber(text)
end

function APHX_IsPositiveId(value)
    local id = APHX_NormalizeId(value)
    return id ~= nil and id > 0
end

function APHX_SafeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, nil
    end
    return pcall(fn, ...)
end

function APHX_DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = APHX_DeepCopy(child)
    end
    return copy
end

function APHX_ArrayContains(array, value)
    if type(array) ~= "table" then
        return false
    end
    for _, item in ipairs(array) do
        if item == value then
            return true
        end
    end
    return false
end

function APHX_TableLength(tbl)
    if type(tbl) ~= "table" then
        return 0
    end
    local count = 0
    for _ in pairs(tbl) do
        count += 1
    end
    return count
end

function APHX_StableSort(array, comparator)
    if type(array) ~= "table" then
        return {}
    end
    table.sort(array, comparator)
    return array
end

function APHX_SortText(a, b)
    return APHX_Lower(a) < APHX_Lower(b)
end

function APHX_SlotLabel(slot)
    local def = APHX_SLOT_DEFS[slot]
    if def then
        return def.Label
    end
    return string.upper(APHX_String(slot))
end

function APHX_CategoryMatches(category, aliases)
    local cat = APHX_Lower(category):gsub("%s+", "")
    for _, alias in ipairs(aliases or {}) do
        if cat == APHX_Lower(alias):gsub("%s+", "") then
            return true
        end
    end
    return false
end

function APHX_MappingAnimationId(mapping)
    if type(mapping) ~= "table" then
        return nil
    end
    return APHX_NormalizeId(mapping.animationId)
end

function APHX_CatalogAnimations()
    local source = State.originalAnimationsData
    if type(source) ~= "table" or #source == 0 then
        source = State.animationsData
    end
    if type(source) ~= "table" then
        return {}
    end
    return source
end

function APHX_IsBundleCandidate(item)
    if type(item) ~= "table" then
        return false
    end
    if item.isCustomSet then
        return true
    end
    if type(item.bundledItems) == "table" then
        return true
    end
    return false
end

function APHX_GetBundleCandidates(query)
    query = APHX_Lower(APHX_Trim(query))
    local source = APHX_CatalogAnimations()
    local list = {}
    local seen = {}

    for _, item in ipairs(source) do
        if APHX_IsBundleCandidate(item) then
            local key = APHX_String(item.id)
            if item.isCustomSet then
                key = "custom:" .. APHX_String(item.customSetName or item.name)
            end
            if not seen[key] then
                local name = APHX_String(item.name or key)
                local text = APHX_Lower(name .. " " .. APHX_String(item.id))
                if query == "" or text:find(query, 1, true) then
                    seen[key] = true
                    table.insert(list, item)
                end
            end
        end
    end

    APHX_StableSort(list, function(a, b)
        local af = APHIsFavorite("animation", a) and 1 or 0
        local bf = APHIsFavorite("animation", b) and 1 or 0
        if af ~= bf then
            return af > bf
        end
        return APHX_SortText(a.name or a.id, b.name or b.id)
    end)

    return list
end

function APHX_BundleCacheKey(item)
    if type(item) ~= "table" then
        return ""
    end
    if item.isCustomSet then
        return "custom:" .. APHX_String(item.customSetName or item.name)
    end
    return "bundle:" .. APHX_String(item.id)
end

function APHX_GetResolvedMappings(item)
    if type(item) ~= "table" then
        return {}
    end

    local key = APHX_BundleCacheKey(item)
    if key == "" then
        return {}
    end

    local cached = APHELION_FEATURES.Mix.Resolved[key]
    if type(cached) == "table" and type(cached.Mappings) == "table" then
        return cached.Mappings
    end

    local mappings = {}
    local ok = false

    if item.isCustomSet then
        ok, mappings = APHX_SafeCall(function()
            return buildCustomSetMappings(GetCustomSetName and GetCustomSetName(item) or item.name)
        end)
    elseif type(item.bundledItems) == "table" then
        ok, mappings = APHX_SafeCall(function()
            local cacheKey = tostring(item.id)
            local fromCache = State.AnimationCache and State.AnimationCache[cacheKey]
            if type(fromCache) == "table" and #fromCache > 0 then
                return fromCache
            end
            local resolved = resolveAnimationMappings(item.bundledItems)
            if State.AnimationCache and type(resolved) == "table" and #resolved > 0 then
                State.AnimationCache[cacheKey] = resolved
                if saveAnimationCache then
                    task.spawn(saveAnimationCache)
                end
            end
            return resolved
        end)
    end

    if not ok or type(mappings) ~= "table" then
        mappings = {}
    end

    APHELION_FEATURES.Mix.Resolved[key] = {
        Mappings = mappings,
        Item = item,
        Timestamp = tick(),
    }
    return mappings
end

function APHX_FindMappingsForSlot(mappings, slot)
    local def = APHX_SLOT_DEFS[slot]
    if not def or type(mappings) ~= "table" then
        return {}
    end

    local matches = {}
    for _, mapping in ipairs(mappings) do
        if APHX_CategoryMatches(mapping.category, def.CategoryNames) then
            table.insert(matches, mapping)
        end
    end

    APHX_StableSort(matches, function(a, b)
        local an = APHX_Lower(a.name)
        local bn = APHX_Lower(b.name)
        local ap = 999
        local bp = 999
        for index, desired in ipairs(def.AnimationNames or {}) do
            local wanted = APHX_Lower(desired)
            if an == wanted then ap = index end
            if bn == wanted then bp = index end
        end
        if ap ~= bp then
            return ap < bp
        end
        return an < bn
    end)

    return matches
end

function APHX_ExtractSlotValue(item, slot)
    local mappings = APHX_GetResolvedMappings(item)
    local matches = APHX_FindMappingsForSlot(mappings, slot)
    if #matches == 0 then
        return nil, matches
    end
    return matches[1], matches
end

function APHX_NewEmptyMix()
    local mix = {
        idle = {Animation1 = 0, Animation2 = 0},
        walk = {WalkAnim = 0},
        run = {RunAnim = 0},
        jump = {JumpAnim = 0},
        fall = {FallAnim = 0},
        climb = {ClimbAnim = 0},
        swimidle = {SwimIdle = 0},
        swim = {Swim = 0},
        __meta = {
            IconImage = DEFAULT_IDLE_ICON_ID,
            IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR),
            FeaturePack = "MixStudio",
            FeatureVersion = APHELION_FEATURES.Version,
            Sources = {},
            MixMeta = {
                CreatedAt = os.time(),
                CreatedWith = APHELION_FEATURES.Version,
                Slots = {},
            },
        },
    }
    return mix
end

function APHX_MixHasContent(mix)
    if type(mix) ~= "table" then
        return false
    end
    for _, slot in ipairs(APHX_SLOT_ORDER) do
        local data = mix[slot]
        if type(data) == "table" then
            for _, id in pairs(data) do
                if APHX_IsPositiveId(id) then
                    return true
                end
            end
        end
    end
    return false
end

function APHX_MixFilledSlots(mix)
    local total = 0
    for _, slot in ipairs(APHX_SLOT_ORDER) do
        local data = type(mix) == "table" and mix[slot] or nil
        local filled = false
        if type(data) == "table" then
            for _, id in pairs(data) do
                if APHX_IsPositiveId(id) then
                    filled = true
                    break
                end
            end
        end
        if filled then
            total += 1
        end
    end
    return total
end

function APHX_CopyMix(mix)
    return APHX_DeepCopy(mix)
end

function APHX_PushMixSnapshot(reason)
    local snapshot = {
        Reason = reason or "edit",
        Timestamp = os.time(),
        Data = APHX_CopyMix(APHELION_FEATURES.Mix.Slots),
    }
    table.insert(APHELION_FEATURES.Mix.PreviousSnapshots, snapshot)
    while #APHELION_FEATURES.Mix.PreviousSnapshots > APHELION_FEATURES.Mix.MaxSnapshots do
        table.remove(APHELION_FEATURES.Mix.PreviousSnapshots, 1)
    end
end

function APHX_UndoMix()
    local history = APHELION_FEATURES.Mix.PreviousSnapshots
    local snapshot = history[#history]
    if not snapshot then
        return false
    end
    table.remove(history, #history)
    APHELION_FEATURES.Mix.Slots = APHX_CopyMix(snapshot.Data)
    APHELION_FEATURES.Mix.Revision += 1
    return true
end

function APHX_ResetMix()
    APHX_PushMixSnapshot("reset")
    APHELION_FEATURES.Mix.Slots = APHX_NewEmptyMix()
    APHELION_FEATURES.Mix.Revision += 1
end

function APHX_CopySourceIntoSlot(item, slot)
    if not item or not APHX_SLOT_DEFS[slot] then
        return false, "Invalid source or slot"
    end

    APHX_PushMixSnapshot("assign:" .. slot)

    local mapping, matches = APHX_ExtractSlotValue(item, slot)
    if not mapping then
        return false, "This bundle does not contain " .. APHX_SlotLabel(slot)
    end

    local mix = APHELION_FEATURES.Mix.Slots
    local sourceKey = APHX_BundleCacheKey(item)
    local sourceName = APHX_String(item.name or item.id)
    mix.__meta = mix.__meta or {}
    mix.__meta.Sources = mix.__meta.Sources or {}
    mix.__meta = mix.__meta or {}
    mix.__meta.MixMeta = mix.__meta.MixMeta or {Slots = {}}
    mix.__meta.MixMeta.Slots = mix.__meta.MixMeta.Slots or {}

    if slot == "idle" then
        mix.idle = mix.idle or {Animation1 = 0, Animation2 = 0}
        mix.idle.Animation1 = APHX_NormalizeId(matches[1] and matches[1].animationId) or 0
        mix.idle.Animation2 = APHX_NormalizeId(matches[2] and matches[2].animationId) or 0
    elseif slot == "walk" then
        mix.walk = mix.walk or {WalkAnim = 0}
        mix.walk.WalkAnim = APHX_NormalizeId(mapping.animationId) or 0
    elseif slot == "run" then
        mix.run = mix.run or {RunAnim = 0}
        mix.run.RunAnim = APHX_NormalizeId(mapping.animationId) or 0
    elseif slot == "jump" then
        mix.jump = mix.jump or {JumpAnim = 0}
        mix.jump.JumpAnim = APHX_NormalizeId(mapping.animationId) or 0
    elseif slot == "fall" then
        mix.fall = mix.fall or {FallAnim = 0}
        mix.fall.FallAnim = APHX_NormalizeId(mapping.animationId) or 0
    elseif slot == "climb" then
        mix.climb = mix.climb or {ClimbAnim = 0}
        mix.climb.ClimbAnim = APHX_NormalizeId(mapping.animationId) or 0
    elseif slot == "swimidle" then
        mix.swimidle = mix.swimidle or {SwimIdle = 0}
        mix.swimidle.SwimIdle = APHX_NormalizeId(mapping.animationId) or 0
    elseif slot == "swim" then
        mix.swim = mix.swim or {Swim = 0}
        mix.swim.Swim = APHX_NormalizeId(mapping.animationId) or 0
    end

    mix.__meta.Sources[slot] = {
        Key = sourceKey,
        Id = APHX_NormalizeId(item.id),
        Name = sourceName,
        IsCustomSet = item.isCustomSet == true,
    }
    mix.__meta.MixMeta.Slots[slot] = {
        SourceKey = sourceKey,
        SourceName = sourceName,
        SourceId = APHX_NormalizeId(item.id),
        MappingNames = {},
    }
    for _, m in ipairs(matches) do
        table.insert(mix.__meta.MixMeta.Slots[slot].MappingNames, APHX_String(m.name))
    end

    APHELION_FEATURES.Mix.Revision += 1
    return true, APHX_SlotLabel(slot) .. " ← " .. sourceName
end

function APHX_ClearMixSlot(slot)
    if not APHX_SLOT_DEFS[slot] then
        return false
    end
    APHX_PushMixSnapshot("clear:" .. slot)
    local mix = APHELION_FEATURES.Mix.Slots
    if slot == "idle" then
        mix.idle = {Animation1 = 0, Animation2 = 0}
    elseif slot == "walk" then
        mix.walk = {WalkAnim = 0}
    elseif slot == "run" then
        mix.run = {RunAnim = 0}
    elseif slot == "jump" then
        mix.jump = {JumpAnim = 0}
    elseif slot == "fall" then
        mix.fall = {FallAnim = 0}
    elseif slot == "climb" then
        mix.climb = {ClimbAnim = 0}
    elseif slot == "swimidle" then
        mix.swimidle = {SwimIdle = 0}
    elseif slot == "swim" then
        mix.swim = {Swim = 0}
    end
    if mix.__meta and mix.__meta.Sources then
        mix.__meta.Sources[slot] = nil
    end
    if mix.__meta and mix.__meta.MixMeta and mix.__meta.MixMeta.Slots then
        mix.__meta.MixMeta.Slots[slot] = nil
    end
    APHELION_FEATURES.Mix.Revision += 1
    return true
end

function APHX_FillMissingFromItem(item)
    if not item then
        return 0
    end
    local before = APHX_MixFilledSlots(APHELION_FEATURES.Mix.Slots)
    for _, slot in ipairs(APHX_SLOT_ORDER) do
        local existing = false
        local current = APHELION_FEATURES.Mix.Slots[slot]
        if type(current) == "table" then
            for _, id in pairs(current) do
                if APHX_IsPositiveId(id) then
                    existing = true
                    break
                end
            end
        end
        if not existing then
            APHX_CopySourceIntoSlot(item, slot)
        end
    end
    local after = APHX_MixFilledSlots(APHELION_FEATURES.Mix.Slots)
    return math.max(0, after - before)
end

function APHX_ExtractSetSources(setData)
    local out = {}
    if type(setData) ~= "table" then
        return out
    end
    local meta = setData.__meta and setData.__meta.MixMeta and setData.__meta.MixMeta.Slots
    if type(meta) ~= "table" then
        meta = setData.__meta and setData.__meta.Sources
    end
    if type(meta) == "table" then
        for slot, source in pairs(meta) do
            if type(source) == "table" then
                out[slot] = APHX_DeepCopy(source)
            end
        end
    end
    return out
end

function APHX_SelectMixFromExistingSet(name)
    local set = State.CustomAnimations
        and State.CustomAnimations.Sets
        and State.CustomAnimations.Sets[name]
    if not set then
        return false, "Style not found"
    end
    APHX_PushMixSnapshot("load-style:" .. name)
    APHELION_FEATURES.Mix.Slots = APHX_DeepCopy(set)
    local selected = APHX_ExtractSetSources(set)
    APHELION_FEATURES.Mix.Slots.__meta = APHELION_FEATURES.Mix.Slots.__meta or {}
    APHELION_FEATURES.Mix.Slots.__meta.Sources = APHELION_FEATURES.Mix.Slots.__meta.Sources or selected
    APHELION_FEATURES.Mix.Revision += 1
    return true, "Loaded " .. name
end

function APHX_MakeSetName(desired)
    desired = APHX_Trim(desired)
    if desired == "" then
        desired = "My Mix"
    end
    local sets = State.CustomAnimations and State.CustomAnimations.Sets or {}
    return MakeUniqueSetName(sets, desired)
end

function APHX_EnsureCustomAnimationState()
    State.CustomAnimations = NormalizeCustomAnimationData(State.CustomAnimations)
    if not State.CustomAnimations.Sets.Default then
        State.CustomAnimations.Sets.Default = APHX_NewEmptyMix()
        State.CustomAnimations.Order = State.CustomAnimations.Order or {"Default"}
        if not APHX_ArrayContains(State.CustomAnimations.Order, "Default") then
            table.insert(State.CustomAnimations.Order, 1, "Default")
        end
    end
    return State.CustomAnimations
end

function APHX_SaveStyle(name, overwrite)
    APHX_EnsureCustomAnimationState()
    if not APHX_MixHasContent(APHELION_FEATURES.Mix.Slots) then
        return false, "Fill at least one motion slot first"
    end

    local targetName = APHX_Trim(name)
    if targetName == "" then
        return false, "Enter a name"
    end

    local sets = State.CustomAnimations.Sets
    if sets[targetName] and not overwrite then
        targetName = APHX_MakeSetName(targetName)
    end

    local mix = APHX_DeepCopy(APHELION_FEATURES.Mix.Slots)
    mix.__meta = mix.__meta or {}
    mix.__meta.FeaturePack = "MixStudio"
    mix.__meta.FeatureVersion = APHELION_FEATURES.Version
    mix.__meta.SavedAt = os.time()
    mix.__meta.DisplayName = targetName
    mix.__meta.MixMeta = mix.__meta.MixMeta or {}
    mix.__meta.MixMeta.SavedName = targetName
    mix.__meta.MixMeta.SavedAt = os.time()

    sets[targetName] = mix
    if not APHX_ArrayContains(State.CustomAnimations.Order, targetName) then
        table.insert(State.CustomAnimations.Order, targetName)
    end

    State.CustomAnimations.Selected = targetName
    State.currentCustomAnimationName = targetName
    State.SaveCustomAnimations(State.CustomAnimations)

    if State.CustomAnimDropdown then
        pcall(function()
            State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
            if State.CustomAnimDropdown.Button then
                State.CustomAnimDropdown.Button.Text = targetName .. "  ▼"
            end
        end)
    end

    if State.RefreshCustomAnimUI then
        pcall(State.RefreshCustomAnimUI)
    end
    if State.ApplyCustomAnimIconUI then
        pcall(State.ApplyCustomAnimIconUI)
    end
    if refreshCustomAnimationState then
        task.spawn(function()
            pcall(refreshCustomAnimationState, false)
        end)
    end

    return true, targetName
end

function APHX_DeleteStyle(name)
    APHX_EnsureCustomAnimationState()
    if not name or name == "Default" then
        return false, "Default cannot be deleted"
    end
    if not State.CustomAnimations.Sets[name] then
        return false, "Style not found"
    end
    State.CustomAnimations.Sets[name] = nil
    local index = table.find(State.CustomAnimations.Order, name)
    if index then
        table.remove(State.CustomAnimations.Order, index)
    end
    if State.currentCustomAnimationName == name then
        State.currentCustomAnimationName = "Default"
        State.CustomAnimations.Selected = "Default"
    end
    State.SaveCustomAnimations(State.CustomAnimations)
    if State.CustomAnimDropdown then
        pcall(function()
            State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
            if State.CustomAnimDropdown.Button then
                State.CustomAnimDropdown.Button.Text = State.currentCustomAnimationName .. "  ▼"
            end
        end)
    end
    if refreshCustomAnimationState then
        task.spawn(function()
            pcall(refreshCustomAnimationState, false)
        end)
    end
    return true, "Deleted " .. name
end

function APHX_ApplyStyle(name)
    APHX_EnsureCustomAnimationState()
    local set = State.CustomAnimations.Sets[name]
    if not set then
        return false, "Style not found"
    end
    local pseudo = {
        id = -math.abs(tonumber(string.match(name, "%d+$")) or math.random(100000, 999999)),
        name = name,
        customSetName = name,
        isCustomSet = true,
        bundledItems = {"Custom-Animation"},
    }
    local ok, err = APHX_SafeCall(function()
        applyAnimation(pseudo)
    end)
    if not ok then
        return false, APHX_String(err)
    end
    State.currentCustomAnimationName = name
    State.CustomAnimations.Selected = name
    State.SaveCustomAnimations(State.CustomAnimations)
    return true, "Applied " .. name
end

function APHX_SaveCurrentMixAs(desired)
    local ok, name = APHX_SaveStyle(desired, false)
    if ok then
        APHX_ApplyStyle(name)
    end
    return ok, name
end

function APHX_ExportStyle(name)
    APHX_EnsureCustomAnimationState()
    local set = State.CustomAnimations.Sets[name]
    if not set then
        return nil, "Style not found"
    end
    local payload = {
        Type = "AphelionMixStyle",
        Version = APHELION_FEATURES.Version,
        Name = name,
        Data = APHX_DeepCopy(set),
    }
    local ok, json = APHX_SafeCall(function()
        return HttpService:JSONEncode(payload)
    end)
    if not ok then
        return nil, "JSON encode failed"
    end
    return json
end

function APHX_ImportStyle(jsonText, desiredName)
    local ok, decoded = APHX_SafeCall(function()
        return HttpService:JSONDecode(jsonText)
    end)
    if not ok or type(decoded) ~= "table" then
        return false, "Invalid JSON"
    end
    if decoded.Type and decoded.Type ~= "AphelionMixStyle" and decoded.Type ~= "CustomAnimationSet" then
        return false, "Unsupported style type"
    end
    local data = decoded.Data or decoded.data or decoded.Set
    if type(data) ~= "table" then
        return false, "No animation data found"
    end
    APHX_EnsureCustomAnimationState()
    local sourceName = APHX_String(decoded.Name or desiredName or "Imported Style")
    local targetName = APHX_MakeSetName(desiredName or sourceName)
    data.__meta = data.__meta or {}
    data.__meta.FeaturePack = "MixStudio"
    data.__meta.ImportedAt = os.time()
    State.CustomAnimations.Sets[targetName] = data
    table.insert(State.CustomAnimations.Order, targetName)
    State.CustomAnimations.Selected = targetName
    State.currentCustomAnimationName = targetName
    State.SaveCustomAnimations(State.CustomAnimations)
    if State.CustomAnimDropdown then
        pcall(function()
            State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
            if State.CustomAnimDropdown.Button then
                State.CustomAnimDropdown.Button.Text = targetName .. "  ▼"
            end
        end)
    end
    return true, targetName
end

function APHX_QueueEntry(kind, item)
    if not item then
        return nil
    end
    local entry = {
        kind = kind == "emote" and "emote" or "animation",
        id = item.id,
        name = APHX_String(item.name or item.id),
        bundledItems = APHX_DeepCopy(item.bundledItems),
        isCustomSet = item.isCustomSet == true,
        customSetName = item.customSetName,
        offsale = item.offsale == true,
        addedAt = os.time(),
    }
    return entry
end

function APHX_QueueAdd(kind, item)
    local entry = APHX_QueueEntry(kind, item)
    if not entry then
        return false
    end
    if #APHELION_FEATURES.Queue.Items >= 32 then
        table.remove(APHELION_FEATURES.Queue.Items, 1)
    end
    table.insert(APHELION_FEATURES.Queue.Items, entry)
    APHELION_FEATURES.Queue.Revision += 1
    return true
end

function APHX_QueueRemove(index)
    index = math.floor(tonumber(index) or 0)
    if index < 1 or index > #APHELION_FEATURES.Queue.Items then
        return false
    end
    table.remove(APHELION_FEATURES.Queue.Items, index)
    APHELION_FEATURES.Queue.Revision += 1
    return true
end

function APHX_QueueClear()
    APHELION_FEATURES.Queue.Items = {}
    APHELION_FEATURES.Queue.CurrentIndex = 0
    APHELION_FEATURES.Queue.Revision += 1
end

function APHX_QueueAddRandom(count)
    count = math.max(1, math.floor(tonumber(count) or 1))
    local source = getViewData()
    if type(source) ~= "table" or #source == 0 then
        return 0
    end
    local added = 0
    for _ = 1, count do
        local entry = source[math.random(1, #source)]
        if UIState.mode == "favorite" then
            if APHX_QueueAdd(entry.kind, entry.item) then
                added += 1
            end
        else
            if APHX_QueueAdd(UIState.mode, entry) then
                added += 1
            end
        end
    end
    return added
end

function APHX_QueueAddFavorites()
    local added = 0
    for _, item in ipairs(State.favoriteAnimations or {}) do
        if APHX_QueueAdd("animation", item) then
            added += 1
        end
    end
    for _, item in ipairs(State.favoriteEmotes or {}) do
        if APHX_QueueAdd("emote", item) then
            added += 1
        end
    end
    return added
end

function APHX_QueueStop()
    APHELION_FEATURES.Queue.Playing = false
    APHELION_FEATURES.Queue.Token += 1
    pcall(stopCurrentEmote)
    pcall(stopEmotes)
end

function APHX_QueueShuffledOrder()
    local order = {}
    for i = 1, #APHELION_FEATURES.Queue.Items do
        table.insert(order, i)
    end
    for i = #order, 2, -1 do
        local j = math.random(1, i)
        order[i], order[j] = order[j], order[i]
    end
    return order
end

function APHX_QueuePlay()
    if APHELION_FEATURES.Queue.Playing then
        return false, "Queue is already playing"
    end
    if #APHELION_FEATURES.Queue.Items == 0 then
        return false, "Queue is empty"
    end

    APHELION_FEATURES.Queue.Playing = true
    APHELION_FEATURES.Queue.Token += 1
    local token = APHELION_FEATURES.Queue.Token
    local startedAt = tick()

    task.spawn(function()
        local cycle = 0
        while APHELION_FEATURES.Queue.Playing and token == APHELION_FEATURES.Queue.Token do
            cycle += 1
            local order
            if APHELION_FEATURES.Queue.Shuffle then
                order = APHX_QueueShuffledOrder()
            else
                order = {}
                for i = 1, #APHELION_FEATURES.Queue.Items do
                    table.insert(order, i)
                end
            end

            if #order == 0 then
                break
            end

            for _, index in ipairs(order) do
                if not APHELION_FEATURES.Queue.Playing or token ~= APHELION_FEATURES.Queue.Token then
                    break
                end
                local entry = APHELION_FEATURES.Queue.Items[index]
                if entry then
                    APHELION_FEATURES.Queue.CurrentIndex = index
                    APHELION_FEATURES.Queue.Revision += 1
                    local playable = {
                        id = entry.id,
                        name = entry.name,
                        bundledItems = entry.bundledItems,
                        isCustomSet = entry.isCustomSet,
                        customSetName = entry.customSetName,
                    }
                    pcall(function()
                        APHPlayItem(entry.kind, playable)
                    end)
                    local waitTime = math.clamp(tonumber(APHELION_FEATURES.Queue.Interval) or 2.5, 0.6, 30)
                    local untilTime = tick() + waitTime
                    while tick() < untilTime do
                        if not APHELION_FEATURES.Queue.Playing or token ~= APHELION_FEATURES.Queue.Token then
                            break
                        end
                        task.wait(0.1)
                    end
                end
            end

            if not APHELION_FEATURES.Queue.Loop then
                break
            end
            if cycle >= 100 then
                break
            end
        end

        if token == APHELION_FEATURES.Queue.Token then
            APHELION_FEATURES.Queue.Playing = false
            APHELION_FEATURES.Queue.CurrentIndex = 0
            pcall(stopCurrentEmote)
        end

        local elapsed = tick() - startedAt
        if elapsed < 0 then
            APHELION_FEATURES.Queue.Playing = false
        end
    end)
    return true, "Queue started"
end

function APHX_Notify(message, duration)
    AphelionSafeNotify("APHELION | Tools", APHX_String(message), duration or 3)
end

function APHX_New(className, props, parent)
    return new(className, props, parent)
end

function APHX_Round(obj, radius)
    if obj then
        pcall(round, obj, radius)
    end
    return obj
end

function APHX_Stroke(obj, color, transparency, thickness)
    if obj then
        pcall(stroke, obj, color, transparency, thickness)
    end
    return obj
end

function APHX_Gradient(obj, c1, c2, rotation)
    if obj then
        pcall(gradient, obj, c1, c2, rotation)
    end
    return obj
end

function APHX_Button(parent, text, width, height)
    local button = APHX_New("TextButton", {
        AutoButtonColor = false,
        Size = UDim2.fromOffset(width or 80, height or 36),
        BackgroundColor3 = Theme.Surface2,
        Text = text or "BUTTON",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
    }, parent)
    APHX_Round(button, 10)
    APHX_Stroke(button, Theme.Border, 0.25, 1)
    return button
end

function APHX_Label(parent, text, size, color, font)
    return APHX_New("TextLabel", {
        BackgroundTransparency = 1,
        Size = size or UDim2.new(1, 0, 0, 24),
        Text = text or "",
        TextColor3 = color or Theme.Text,
        Font = font or Enum.Font.GothamMedium,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

function APHX_MakeDivider(parent, y)
    return APHX_New("Frame", {
        Position = UDim2.fromOffset(8, y or 0),
        Size = UDim2.new(1, -16, 0, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.45,
    }, parent)
end

function APHX_CreatePrompt(parent, titleText, placeholder, defaultText)
    local overlay = APHX_New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.35,
        ZIndex = 900,
    }, parent)
    local box = APHX_New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.86, 0, 0, 180),
        BackgroundColor3 = Theme.Surface,
        ZIndex = 901,
    }, overlay)
    APHX_Round(box, 16)
    APHX_Stroke(box, Theme.Border, 0.12, 1.2)
    APHX_Gradient(box, Color3.fromRGB(25, 30, 40), Color3.fromRGB(12, 15, 21), 120)

    local title = APHX_Label(box, titleText or "ENTER VALUE", UDim2.new(1, -30, 0, 28), Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(15, 12)
    title.TextSize = 14

    local input = APHX_New("TextBox", {
        Size = UDim2.new(1, -30, 0, 42),
        Position = UDim2.fromOffset(15, 55),
        BackgroundColor3 = Theme.Background,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        PlaceholderText = placeholder or "Enter name...",
        Text = defaultText or "",
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 902,
    }, box)
    APHX_Round(input, 10)
    APHX_Stroke(input, Theme.Border, 0.25, 1)
    APHX_New("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, input)

    local cancel = APHX_Button(box, "CANCEL", 90, 36)
    cancel.Position = UDim2.new(1, -195, 1, -52)
    cancel.ZIndex = 902
    local confirm = APHX_Button(box, "CONFIRM", 90, 36)
    confirm.Position = UDim2.new(1, -100, 1, -52)
    confirm.BackgroundColor3 = Theme.Accent
    confirm.TextColor3 = Color3.new(1, 1, 1)
    confirm.ZIndex = 902

    local state = {Closed = false}
    local function close()
        if state.Closed then
            return
        end
        state.Closed = true
        pcall(overlay.Destroy, overlay)
    end

    cancel.Activated:Connect(close)
    return {
        Overlay = overlay,
        Input = input,
        Confirm = confirm,
        Cancel = cancel,
        Close = close,
    }
end

function APHX_CreateFeaturePanel()
    if APHELION_FEATURES.Panel and APHELION_FEATURES.Panel.Parent then
        return APHELION_FEATURES.Panel
    end

    local overlay = APHX_New("Frame", {
        Name = "FeatureOverlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.52,
        ZIndex = 700,
    }, Screen)
    APHELION_FEATURES.Overlay = overlay

    local panel = APHX_New("Frame", {
        Name = "FeaturePanel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.94, 0, 0.86, 0),
        BackgroundColor3 = Theme.Background,
        ZIndex = 701,
    }, overlay)
    APHX_Round(panel, 20)
    APHX_Stroke(panel, Theme.Border, 0.08, 1.2)
    APHX_Gradient(panel, Color3.fromRGB(19, 23, 32), Color3.fromRGB(7, 10, 15), 115)
    APHELION_FEATURES.Panel = panel

    local header = APHX_New("Frame", {
        Size = UDim2.new(1, -20, 0, 56),
        Position = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        ZIndex = 702,
    }, panel)

    local title = APHX_Label(header, "✦ APHELION TOOLS", UDim2.new(1, -150, 0, 26), Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(2, 0)
    title.TextSize = 17
    local subtitle = APHX_Label(header, "APHELION MIX • save styles • build motion queues", UDim2.new(1, -150, 0, 18), Theme.Muted)
    subtitle.Position = UDim2.fromOffset(3, 28)
    subtitle.TextSize = 9

    local close = APHX_Button(header, "×", 42, 42)
    close.Position = UDim2.new(1, -42, 0, 0)
    close.BackgroundColor3 = Color3.fromRGB(42, 24, 30)
    close.TextColor3 = Theme.Danger
    close.TextSize = 19
    close.Activated:Connect(function()
        if APHELION_FEATURES.Overlay then
            APHELION_FEATURES.Overlay.Visible = false
        end
        APHELION_FEATURES.Open = false
    end)

    local tabs = APHX_New("Frame", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.fromOffset(10, 68),
        BackgroundTransparency = 1,
        ZIndex = 702,
    }, panel)
    local tabLayout = APHX_New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, tabs)

    local tabButtons = {}
    local function addFeatureTab(id, label)
        local b = APHX_Button(tabs, label, 96, 40)
        b.Name = id .. "Tab"
        tabButtons[id] = b
        return b
    end
    addFeatureTab("Mix", "MIX STUDIO")
    addFeatureTab("Vault", "STYLE VAULT")
    addFeatureTab("Lab", "MOTION LAB")

    local content = APHX_New("Frame", {
        Size = UDim2.new(1, -20, 1, -120),
        Position = UDim2.fromOffset(10, 114),
        BackgroundTransparency = 1,
        ZIndex = 702,
    }, panel)

    APHELION_FEATURES.UI.MixContent = APHX_New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = true,
        ZIndex = 703,
    }, content)
    APHELION_FEATURES.UI.VaultContent = APHX_New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 703,
    }, content)
    APHELION_FEATURES.UI.LabContent = APHX_New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 703,
    }, content)

    local function switchFeatureTab(id)
        APHELION_FEATURES.ActiveTab = id
        APHELION_FEATURES.UI.MixContent.Visible = id == "Mix"
        APHELION_FEATURES.UI.VaultContent.Visible = id == "Vault"
        APHELION_FEATURES.UI.LabContent.Visible = id == "Lab"
        for tabId, button in pairs(tabButtons) do
            local active = tabId == id
            button.BackgroundColor3 = active and Color3.fromRGB(33, 56, 84) or Theme.Surface2
            button.TextColor3 = active and Theme.Accent or Theme.Muted
        end
        if id == "Mix" then
            APHX_RenderMixSources()
            APHX_RenderMixSlots()
        elseif id == "Vault" then
            APHX_RenderVault()
        else
            APHX_RenderLab()
        end
    end

    for id, button in pairs(tabButtons) do
        button.Activated:Connect(function()
            switchFeatureTab(id)
        end)
    end

    switchFeatureTab("Mix")
    return panel
end

function APHX_OpenTools(tabName)
    local panel = APHX_CreateFeaturePanel()
    APHELION_FEATURES.Open = true
    panel.Visible = true
    if APHELION_FEATURES.Overlay then
        APHELION_FEATURES.Overlay.Visible = true
    end
    local target = tabName or APHELION_FEATURES.ActiveTab or "Mix"
    APHELION_FEATURES.ActiveTab = target
    if target == "Mix" then
        APHX_RenderMixSources()
        APHX_RenderMixSlots()
    elseif target == "Vault" then
        APHX_RenderVault()
    else
        APHX_RenderLab()
    end
end

function APHX_MixSlotValueText(slot)
    local mix = APHELION_FEATURES.Mix.Slots or {}
    local data = mix[slot]
    if type(data) ~= "table" then
        return "EMPTY"
    end
    local ids = {}
    for _, id in pairs(data) do
        if APHX_IsPositiveId(id) then
            table.insert(ids, APHX_String(id))
        end
    end
    if #ids == 0 then
        return "EMPTY"
    end
    if #ids == 1 then
        return ids[1]
    end
    return ids[1] .. " + " .. ids[2]
end

function APHX_RenderMixSlots()
    local root = APHELION_FEATURES.UI.MixContent
    if not root or not root.Parent then
        return
    end

    for _, child in ipairs(root:GetChildren()) do
        if child.Name == "MixDynamic" then
            child:Destroy()
        end
    end

    local holder = APHX_New("Frame", {
        Name = "MixDynamic",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 704,
    }, root)

    local intro = APHX_Label(holder,
        "Choose a motion slot, then tap a bundle below to borrow only that motion. Mix as many bundles as you want.",
        UDim2.new(1, -10, 0, 36), Theme.Muted)
    intro.Position = UDim2.fromOffset(4, 0)
    intro.TextSize = 9

    local slotScroll = APHX_New("ScrollingFrame", {
        Name = "SlotScroll",
        Size = UDim2.new(1, -8, 0, 70),
        Position = UDim2.fromOffset(4, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ScrollBarThickness = 0,
        ZIndex = 704,
    }, holder)
    APHELION_FEATURES.UI.SlotScroll = slotScroll
    APHX_New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, slotScroll)

    for _, slot in ipairs(APHX_SLOT_ORDER) do
        local button = APHX_Button(slotScroll,
            APHX_SlotLabel(slot) .. "\n" .. APHX_MixSlotValueText(slot),
            100, 58)
        button.Name = "Slot_" .. slot
        button.TextSize = 8
        button.TextWrapped = true
        button.BackgroundColor3 = APHELION_FEATURES.Mix.SelectedSlot == slot
            and Color3.fromRGB(33, 56, 84)
            or Theme.Surface2
        button.TextColor3 = APHELION_FEATURES.Mix.SelectedSlot == slot
            and Theme.Accent
            or Theme.Text
        button.Activated:Connect(function()
            APHELION_FEATURES.Mix.SelectedSlot = slot
            APHELION_FEATURES.Mix.Revision += 1
            APHX_RenderMixSlots()
            APHX_RenderMixSources()
        end)
    end

    local selected = APHELION_FEATURES.Mix.SelectedSlot
    local selectedTitle = APHX_Label(holder,
        APHX_SlotLabel(selected) .. "  •  " .. (APHX_SLOT_DEFS[selected] and APHX_SLOT_DEFS[selected].Description or ""),
        UDim2.new(1, -118, 0, 25), Theme.Text, Enum.Font.GothamBold)
    selectedTitle.Position = UDim2.fromOffset(4, 112)
    selectedTitle.TextSize = 11

    local clearSlot = APHX_Button(holder, "CLEAR", 84, 30)
    clearSlot.Position = UDim2.new(1, -88, 0, 108)
    clearSlot.BackgroundColor3 = Color3.fromRGB(38, 24, 31)
    clearSlot.TextColor3 = Theme.Danger
    clearSlot.Activated:Connect(function()
        if APHX_ClearMixSlot(selected) then
            APHX_RenderMixSlots()
            APHX_RenderMixSources()
        end
    end)

    local actions = APHX_New("Frame", {
        Size = UDim2.new(1, -8, 0, 44),
        Position = UDim2.new(0, 4, 1, -44),
        BackgroundTransparency = 1,
        ZIndex = 704,
    }, holder)
    local actionLayout = APHX_New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, actions)

    local undo = APHX_Button(actions, "UNDO", 66, 40)
    local reset = APHX_Button(actions, "RESET", 66, 40)
    local fill = APHX_Button(actions, "FILL MISSING", 94, 40)
    local save = APHX_Button(actions, "SAVE MIX", 86, 40)
    local apply = APHX_Button(actions, "APPLY", 70, 40)

    undo.Activated:Connect(function()
        if APHX_UndoMix() then
            APHX_RenderMixSlots()
            APHX_RenderMixSources()
            APHX_Notify("Undo applied", 2)
        end
    end)
    reset.Activated:Connect(function()
        APHX_ResetMix()
        APHX_RenderMixSlots()
        APHX_RenderMixSources()
        APHX_Notify("Mix reset", 2)
    end)
    fill.Activated:Connect(function()
        local candidates = APHX_GetBundleCandidates(APHELION_FEATURES.Mix.Query)
        local first = candidates[1]
        if not first then
            APHX_Notify("No bundle source available yet", 3)
            return
        end
        local changed = APHX_FillMissingFromItem(first)
        APHX_RenderMixSlots()
        APHX_RenderMixSources()
        APHX_Notify("Filled " .. tostring(changed) .. " missing slot(s)", 3)
    end)
    save.Activated:Connect(function()
        local prompt = APHX_CreatePrompt(holder, "SAVE MIX", "Style name", "My Mix")
        prompt.Confirm.Activated:Connect(function()
            local value = APHX_Trim(prompt.Input.Text)
            if value == "" then
                return
            end
            local ok, name = APHX_SaveCurrentMixAs(value)
            if ok then
                prompt.Close()
                APHX_Notify("Saved + applied " .. name, 3)
                APHX_RenderVault()
            else
                APHX_Notify(name or "Save failed", 3)
            end
        end)
        prompt.Input:CaptureFocus()
    end)
    apply.Activated:Connect(function()
        local mix = APHELION_FEATURES.Mix.Slots
        if not APHX_MixHasContent(mix) then
            APHX_Notify("Fill at least one slot first", 3)
            return
        end

        -- Preview through the original applyAnimation backend without writing a
        -- temporary style into CustomAnimations.json.
        local tempName = "__APHX_PREVIEW_" .. tostring(math.random(100000, 999999))
        APHX_EnsureCustomAnimationState()
        local hadExisting = State.CustomAnimations.Sets[tempName] ~= nil
        local previous = State.CustomAnimations.Sets[tempName]
        State.CustomAnimations.Sets[tempName] = APHX_DeepCopy(mix)
        local pseudo = {
            id = -math.random(100000, 999999),
            name = tempName,
            customSetName = tempName,
            isCustomSet = true,
            bundledItems = {"Custom-Animation"},
        }
        local ok, err = APHX_SafeCall(function()
            applyAnimation(pseudo)
        end)
        if hadExisting then
            State.CustomAnimations.Sets[tempName] = previous
        else
            State.CustomAnimations.Sets[tempName] = nil
        end
        if ok then
            APHX_Notify("Applied current Mix Studio build", 3)
        else
            APHX_Notify(APHX_String(err or "Could not apply mix"), 3)
        end
    end)
end

function APHX_RenderMixSources()
    local root = APHELION_FEATURES.UI.MixContent
    if not root or not root.Parent then
        return
    end

    for _, child in ipairs(root:GetChildren()) do
        if child.Name == "SourceDynamic" then
            child:Destroy()
        end
    end

    local holder = APHX_New("Frame", {
        Name = "SourceDynamic",
        -- Leave the bottom action row owned by MixDynamic; this prevents the
        -- source list from sitting on top of SAVE / APPLY on small screens.
        Size = UDim2.new(1, 0, 1, -214),
        Position = UDim2.fromOffset(0, 150),
        BackgroundTransparency = 1,
        ZIndex = 704,
    }, root)

    local search = APHX_New("TextBox", {
        Size = UDim2.new(1, -8, 0, 36),
        Position = UDim2.fromOffset(4, 0),
        BackgroundColor3 = Theme.Surface,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        PlaceholderText = "Find a bundle for " .. APHX_SlotLabel(APHELION_FEATURES.Mix.SelectedSlot) .. "...",
        Text = APHELION_FEATURES.Mix.Query,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 705,
    }, holder)
    APHX_Round(search, 10)
    APHX_Stroke(search, Theme.Border, 0.25, 1)
    APHX_New("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, search)
    APHELION_FEATURES.UI.SourceSearch = search

    local sourceScroll = APHX_New("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -44),
        Position = UDim2.fromOffset(4, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        ZIndex = 705,
    }, holder)
    APHELION_FEATURES.UI.SourceScroll = sourceScroll
    APHX_New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, sourceScroll)

    local function renderSources()
        for _, child in ipairs(sourceScroll:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end

        local slot = APHELION_FEATURES.Mix.SelectedSlot
        local candidates = APHX_GetBundleCandidates(search.Text)
        local shown = 0
        local maxShown = 36

        for _, item in ipairs(candidates) do
            if shown >= maxShown then
                break
            end
            shown += 1

            local card = APHX_New("TextButton", {
                AutoButtonColor = false,
                Size = UDim2.new(1, -6, 0, 68),
                BackgroundColor3 = Theme.Card,
                Text = "",
                LayoutOrder = shown,
                ZIndex = 706,
            }, sourceScroll)
            APHX_Round(card, 12)
            APHX_Stroke(card, Theme.Border, 0.34, 1)

            local thumb = APHX_New("ImageLabel", {
                Size = UDim2.fromOffset(54, 54),
                Position = UDim2.fromOffset(7, 7),
                BackgroundColor3 = Theme.Background,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Image = getItemThumbnail("animation", item, 150),
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 707,
            }, card)
            APHX_Round(thumb, 10)

            local name = APHX_Label(card, APHX_String(item.name or item.id), UDim2.new(1, -170, 0, 26), Theme.Text, Enum.Font.GothamBold)
            name.Position = UDim2.fromOffset(70, 7)
            name.TextSize = 10
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.ZIndex = 707

            local meta = APHX_Label(card, (item.isCustomSet and "CUSTOM STYLE" or "BUNDLE") .. "  •  " .. APHX_String(item.id), UDim2.new(1, -170, 0, 18), Theme.Muted)
            meta.Position = UDim2.fromOffset(70, 32)
            meta.TextSize = 8
            meta.ZIndex = 707

            local use = APHX_Button(card, "USE", 64, 34)
            use.Position = UDim2.new(1, -72, 0.5, -17)
            use.ZIndex = 708
            use.TextSize = 9
            use.BackgroundColor3 = Color3.fromRGB(26, 48, 72)
            use.TextColor3 = Theme.Accent

            card.Activated:Connect(function()
                if APHELION_FEATURES.Mix.Busy then
                    return
                end
                APHELION_FEATURES.Mix.Busy = true
                APHX_Notify("Resolving " .. APHX_String(item.name or item.id) .. "...", 2)
                task.spawn(function()
                    local ok, result = APHX_SafeCall(function()
                        return APHX_CopySourceIntoSlot(item, slot)
                    end)
                    APHELION_FEATURES.Mix.Busy = false
                    if ok and result then
                        APHX_Notify(result, 2)
                    else
                        APHX_Notify("No " .. APHX_SlotLabel(slot) .. " animation found in that bundle", 3)
                    end
                    if APHELION_FEATURES.Open then
                        APHX_RenderMixSlots()
                        APHX_RenderMixSources()
                    end
                end)
            end)
        end

        if shown == 0 then
            local empty = APHX_Label(sourceScroll,
                "No bundle sources match. Let the catalog finish loading, or try another search.",
                UDim2.new(1, -8, 0, 80), Theme.Muted)
            empty.LayoutOrder = 1
            empty.TextXAlignment = Enum.TextXAlignment.Center
            empty.ZIndex = 706
        end
    end

    APHELION_FEATURES.Mix.Query = search.Text
    search:GetPropertyChangedSignal("Text"):Connect(function()
        APHELION_FEATURES.Mix.Query = search.Text
        APHELION_FEATURES.Mix.SourceRevision += 1
        renderSources()
    end)

    renderSources()
end

function APHX_RenderVault()
    local root = APHELION_FEATURES.UI.VaultContent
    if not root or not root.Parent then
        return
    end

    for _, child in ipairs(root:GetChildren()) do
        child:Destroy()
    end

    local header = APHX_Label(root,
        "STYLE VAULT  •  your saved APHELION styles", UDim2.new(1, -8, 0, 26), Theme.Text, Enum.Font.GothamBold)
    header.Position = UDim2.fromOffset(4, 0)
    header.TextSize = 13

    local sub = APHX_Label(root,
        "Saved styles use the same backend custom-animation format, so they remain compatible with the existing editor.",
        UDim2.new(1, -8, 0, 34), Theme.Muted)
    sub.Position = UDim2.fromOffset(4, 28)
    sub.TextSize = 9

    local actionBar = APHX_New("Frame", {
        Size = UDim2.new(1, -8, 0, 42),
        Position = UDim2.fromOffset(4, 68),
        BackgroundTransparency = 1,
    }, root)
    local layout = APHX_New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, actionBar)

    local edit = APHX_Button(actionBar, "EDIT MIX", 86, 38)
    local newMix = APHX_Button(actionBar, "NEW MIX", 86, 38)
    local exportAll = APHX_Button(actionBar, "EXPORT", 78, 38)
    local import = APHX_Button(actionBar, "IMPORT", 78, 38)

    edit.Activated:Connect(function()
        local name = APHELION_FEATURES.Vault.SelectedStyle
        if not name then
            APHX_Notify("Select a style first", 2)
            return
        end
        local ok, message = APHX_SelectMixFromExistingSet(name)
        if ok then
            APHX_OpenTools("Mix")
            APHX_Notify("Loaded " .. name .. " into Mix Studio", 3)
        else
            APHX_Notify(message, 3)
        end
    end)

    newMix.Activated:Connect(function()
        APHX_ResetMix()
        APHX_OpenTools("Mix")
    end)

    exportAll.Activated:Connect(function()
        APHX_EnsureCustomAnimationState()
        local payload = {
            Type = "AphelionMixVault",
            Version = APHELION_FEATURES.Version,
            Styles = {},
        }
        for _, name in ipairs(State.CustomAnimations.Order or {}) do
            if name ~= "Default" and State.CustomAnimations.Sets[name] then
                payload.Styles[name] = State.CustomAnimations.Sets[name]
            end
        end
        local ok, json = APHX_SafeCall(function()
            return HttpService:JSONEncode(payload)
        end)
        if ok then
            if setclipboard then
                local copied = pcall(setclipboard, json)
                if copied then
                    APHX_Notify("Vault JSON copied to clipboard", 3)
                else
                    APHX_Notify("Export created, but clipboard is unavailable", 3)
                end
            else
                APHX_Notify("Clipboard is unavailable in this environment", 3)
            end
        end
    end)

    import.Activated:Connect(function()
        local prompt = APHX_CreatePrompt(root, "IMPORT STYLE", "Paste style JSON", "")
        prompt.Input.MultiLine = true
        prompt.Input.TextYAlignment = Enum.TextYAlignment.Top
        prompt.Input.Size = UDim2.new(1, -30, 0, 62)
        prompt.Input.Position = UDim2.fromOffset(15, 48)
        prompt.Confirm.Position = UDim2.new(1, -100, 1, -50)
        prompt.Confirm.Activated:Connect(function()
            local text = prompt.Input.Text
            if APHX_Trim(text) == "" then
                return
            end
            local ok, result = APHX_ImportStyle(text)
            if ok then
                prompt.Close()
                APHX_Notify("Imported " .. result, 3)
                APHX_RenderVault()
            else
                APHX_Notify(result or "Import failed", 3)
            end
        end)
        prompt.Input:CaptureFocus()
    end)

    local scroll = APHX_New("ScrollingFrame", {
        Name = "StyleScroll",
        Size = UDim2.new(1, -8, 1, -118),
        Position = UDim2.fromOffset(4, 112),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
    }, root)
    APHELION_FEATURES.UI.StyleScroll = scroll
    APHX_New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, scroll)

    APHX_EnsureCustomAnimationState()
    local names = {}
    for _, name in ipairs(State.CustomAnimations.Order or {}) do
        if name ~= "Default" and State.CustomAnimations.Sets[name] then
            table.insert(names, name)
        end
    end
    APHX_StableSort(names, APHX_SortText)

    if #names == 0 then
        local empty = APHX_Label(scroll,
            "No saved styles yet. Open Mix Studio, build your combo, and press SAVE MIX.",
            UDim2.new(1, -8, 0, 90), Theme.Muted)
        empty.TextXAlignment = Enum.TextXAlignment.Center
    else
        for index, name in ipairs(names) do
            local set = State.CustomAnimations.Sets[name]
            local row = APHX_New("TextButton", {
                AutoButtonColor = false,
                Size = UDim2.new(1, -6, 0, 78),
                BackgroundColor3 = APHELION_FEATURES.Vault.SelectedStyle == name
                    and Color3.fromRGB(28, 48, 71)
                    or Theme.Card,
                Text = "",
                LayoutOrder = index,
            }, scroll)
            APHX_Round(row, 12)
            APHX_Stroke(row, Theme.Border, 0.3, 1)

            local title = APHX_Label(row, name, UDim2.new(1, -190, 0, 25), Theme.Text, Enum.Font.GothamBold)
            title.Position = UDim2.fromOffset(12, 8)
            title.TextSize = 11
            title.TextTruncate = Enum.TextTruncate.AtEnd

            local sourceCount = APHX_TableLength(set and set.__meta and set.__meta.MixMeta and set.__meta.MixMeta.Slots or {})
            local filled = APHX_MixFilledSlots(set)
            local meta = APHX_Label(row,
                tostring(filled) .. "/" .. tostring(#APHX_SLOT_ORDER) .. " slots  •  " .. tostring(sourceCount) .. " recorded sources",
                UDim2.new(1, -190, 0, 18), Theme.Muted)
            meta.Position = UDim2.fromOffset(12, 35)
            meta.TextSize = 8

            local apply = APHX_Button(row, "APPLY", 62, 30)
            apply.Position = UDim2.new(1, -138, 0.5, -15)
            apply.TextColor3 = Theme.Good
            apply.BackgroundColor3 = Color3.fromRGB(24, 48, 39)
            apply.Activated:Connect(function()
                local ok, message = APHX_ApplyStyle(name)
                APHX_Notify(ok and message or (message or "Apply failed"), 3)
                APHELION_FEATURES.Vault.SelectedStyle = name
                APHX_RenderVault()
            end)

            local editButton = APHX_Button(row, "EDIT", 54, 30)
            editButton.Position = UDim2.new(1, -75, 0.5, -15)
            editButton.Activated:Connect(function()
                APHELION_FEATURES.Vault.SelectedStyle = name
                local ok, message = APHX_SelectMixFromExistingSet(name)
                if ok then
                    APHX_OpenTools("Mix")
                else
                    APHX_Notify(message, 2)
                end
            end)

            local deleteButton = APHX_Button(row, "×", 34, 30)
            deleteButton.Position = UDim2.new(1, -38, 0.5, -15)
            deleteButton.BackgroundColor3 = Color3.fromRGB(40, 24, 31)
            deleteButton.TextColor3 = Theme.Danger
            deleteButton.Activated:Connect(function()
                local ok, message = APHX_DeleteStyle(name)
                APHX_Notify(ok and message or (message or "Delete failed"), 2)
                APHX_RenderVault()
            end)

            row.Activated:Connect(function()
                APHELION_FEATURES.Vault.SelectedStyle = name
                APHX_RenderVault()
            end)
        end
    end
end

function APHX_RenderLab()
    local root = APHELION_FEATURES.UI.LabContent
    if not root or not root.Parent then
        return
    end
    for _, child in ipairs(root:GetChildren()) do
        child:Destroy()
    end

    local title = APHX_Label(root, "MOTION LAB", UDim2.new(1, -8, 0, 26), Theme.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(4, 0)
    title.TextSize = 13

    local desc = APHX_Label(root,
        "Build a simple animation/emote queue. Great for testing a bundle mix or making a mini showcase loop.",
        UDim2.new(1, -8, 0, 36), Theme.Muted)
    desc.Position = UDim2.fromOffset(4, 28)
    desc.TextSize = 9

    local controls = APHX_New("Frame", {
        Size = UDim2.new(1, -8, 0, 92),
        Position = UDim2.fromOffset(4, 68),
        BackgroundTransparency = 1,
    }, root)

    local addRandom = APHX_Button(controls, "+ RANDOM", 92, 36)
    addRandom.Position = UDim2.fromOffset(0, 0)
    addRandom.Activated:Connect(function()
        local count = APHX_QueueAddRandom(1)
        APHX_Notify(count > 0 and "Added random item" or "Nothing available yet", 2)
        APHX_RenderLab()
    end)

    local addFive = APHX_Button(controls, "+ 5", 64, 36)
    addFive.Position = UDim2.fromOffset(98, 0)
    addFive.Activated:Connect(function()
        local count = APHX_QueueAddRandom(5)
        APHX_Notify("Added " .. tostring(count) .. " item(s)", 2)
        APHX_RenderLab()
    end)

    local addFav = APHX_Button(controls, "+ FAVORITES", 102, 36)
    addFav.Position = UDim2.fromOffset(168, 0)
    addFav.Activated:Connect(function()
        local count = APHX_QueueAddFavorites()
        APHX_Notify("Added " .. tostring(count) .. " favorite item(s)", 2)
        APHX_RenderLab()
    end)

    local clear = APHX_Button(controls, "CLEAR", 70, 36)
    clear.Position = UDim2.new(1, -70, 0, 0)
    clear.BackgroundColor3 = Color3.fromRGB(38, 24, 31)
    clear.TextColor3 = Theme.Danger
    clear.Activated:Connect(function()
        APHX_QueueStop()
        APHX_QueueClear()
        APHX_RenderLab()
    end)

    local intervalLabel = APHX_Label(controls, "INTERVAL", UDim2.fromOffset(70, 20), Theme.Muted, Enum.Font.GothamBold)
    intervalLabel.Position = UDim2.fromOffset(0, 48)
    intervalLabel.TextSize = 8

    local interval = APHX_New("TextBox", {
        Size = UDim2.fromOffset(76, 34),
        Position = UDim2.fromOffset(76, 42),
        BackgroundColor3 = Theme.Surface,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        PlaceholderText = "2.5",
        Text = tostring(APHELION_FEATURES.Queue.Interval),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 11,
    }, controls)
    APHX_Round(interval, 9)
    APHX_Stroke(interval, Theme.Border, 0.25, 1)
    interval:GetPropertyChangedSignal("Text"):Connect(function()
        local value = tonumber(interval.Text)
        if value then
            APHELION_FEATURES.Queue.Interval = math.clamp(value, 0.6, 30)
        end
    end)

    local loop = APHX_Button(controls, APHELION_FEATURES.Queue.Loop and "LOOP: ON" or "LOOP: OFF", 90, 34)
    loop.Position = UDim2.fromOffset(162, 42)
    loop.Activated:Connect(function()
        APHELION_FEATURES.Queue.Loop = not APHELION_FEATURES.Queue.Loop
        APHX_RenderLab()
    end)

    local shuffle = APHX_Button(controls, APHELION_FEATURES.Queue.Shuffle and "SHUFFLE: ON" or "SHUFFLE: OFF", 100, 34)
    shuffle.Position = UDim2.fromOffset(258, 42)
    shuffle.Activated:Connect(function()
        APHELION_FEATURES.Queue.Shuffle = not APHELION_FEATURES.Queue.Shuffle
        APHX_RenderLab()
    end)

    local play = APHX_Button(controls, APHELION_FEATURES.Queue.Playing and "PLAYING" or "PLAY QUEUE", 100, 34)
    play.Position = UDim2.new(1, -206, 0, 42)
    play.BackgroundColor3 = APHELION_FEATURES.Queue.Playing and Color3.fromRGB(26, 48, 39) or Theme.Surface2
    play.TextColor3 = APHELION_FEATURES.Queue.Playing and Theme.Good or Theme.Text
    play.Activated:Connect(function()
        if APHELION_FEATURES.Queue.Playing then
            APHX_QueueStop()
        else
            local ok, message = APHX_QueuePlay()
            APHX_Notify(message, 2)
        end
        APHX_RenderLab()
    end)

    local stop = APHX_Button(controls, "STOP", 72, 34)
    stop.Position = UDim2.new(1, -100, 0, 42)
    stop.BackgroundColor3 = Color3.fromRGB(38, 24, 31)
    stop.TextColor3 = Theme.Danger
    stop.Activated:Connect(function()
        APHX_QueueStop()
        APHX_RenderLab()
    end)

    local scroll = APHX_New("ScrollingFrame", {
        Name = "LabScroll",
        Size = UDim2.new(1, -8, 1, -166),
        Position = UDim2.fromOffset(4, 162),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
    }, root)
    APHELION_FEATURES.UI.LabScroll = scroll
    APHX_New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, scroll)

    local status = APHX_Label(scroll,
        APHELION_FEATURES.Queue.Playing
            and ("PLAYING ITEM " .. tostring(APHELION_FEATURES.Queue.CurrentIndex) .. " / " .. tostring(#APHELION_FEATURES.Queue.Items))
            or ("QUEUE READY  •  " .. tostring(#APHELION_FEATURES.Queue.Items) .. " ITEM(S)"),
        UDim2.new(1, -8, 0, 30),
        APHELION_FEATURES.Queue.Playing and Theme.Good or Theme.Muted,
        Enum.Font.GothamBold)
    status.TextSize = 9

    if #APHELION_FEATURES.Queue.Items == 0 then
        local empty = APHX_Label(scroll,
            "Nothing queued. Add random items or favorites above.",
            UDim2.new(1, -8, 0, 80), Theme.Muted)
        empty.TextXAlignment = Enum.TextXAlignment.Center
    else
        for index, entry in ipairs(APHELION_FEATURES.Queue.Items) do
            local row = APHX_New("Frame", {
                Size = UDim2.new(1, -6, 0, 58),
                BackgroundColor3 = Theme.Card,
                BorderSizePixel = 0,
                LayoutOrder = index,
            }, scroll)
            APHX_Round(row, 11)
            APHX_Stroke(row, Theme.Border, 0.35, 1)

            local marker = APHX_Label(row,
                (index == APHELION_FEATURES.Queue.CurrentIndex and APHELION_FEATURES.Queue.Playing) and "▶" or tostring(index),
                UDim2.fromOffset(30, 58),
                (index == APHELION_FEATURES.Queue.CurrentIndex and APHELION_FEATURES.Queue.Playing) and Theme.Good or Theme.Muted,
                Enum.Font.GothamBold)
            marker.Position = UDim2.fromOffset(4, 0)
            marker.TextXAlignment = Enum.TextXAlignment.Center
            marker.TextSize = 10

            local label = APHX_Label(row,
                entry.name .. "  •  " .. string.upper(entry.kind),
                UDim2.new(1, -90, 1, 0), Theme.Text, Enum.Font.GothamMedium)
            label.Position = UDim2.fromOffset(42, 0)
            label.TextSize = 9
            label.TextTruncate = Enum.TextTruncate.AtEnd

            local remove = APHX_Button(row, "×", 32, 32)
            remove.Position = UDim2.new(1, -38, 0.5, -16)
            remove.BackgroundColor3 = Color3.fromRGB(38, 24, 31)
            remove.TextColor3 = Theme.Danger
            remove.Activated:Connect(function()
                if index == APHELION_FEATURES.Queue.CurrentIndex and APHELION_FEATURES.Queue.Playing then
                    APHX_QueueStop()
                end
                APHX_QueueRemove(index)
                APHX_RenderLab()
            end)
        end
    end
end

function APHX_WireToolButton()
    if not Utility or not Utility.Parent then
        return
    end

    Utility.Size = UDim2.fromOffset(184, 30)
    Status.Size = UDim2.new(1, -196, 1, 0)
    RandomBtn.Size = UDim2.fromOffset(56, 30)
    StopBtn.Size = UDim2.fromOffset(56, 30)
    RandomBtn.TextSize = 8
    StopBtn.TextSize = 8

    local toolsButton = Utility:FindFirstChild("AphelionToolsButton")
    if toolsButton then
        return toolsButton
    end

    toolsButton = APHX_New("TextButton", {
        Name = "AphelionToolsButton",
        AutoButtonColor = false,
        Size = UDim2.fromOffset(56, 30),
        BackgroundColor3 = Color3.fromRGB(30, 45, 68),
        Text = "TOOLS",
        TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        LayoutOrder = 2,
    }, Utility)
    APHX_Round(toolsButton, 9)
    APHX_Stroke(toolsButton, Theme.Accent, 0.62, 1)
    toolsButton.Activated:Connect(function()
        APHX_OpenTools("Mix")
    end)

    RandomBtn.LayoutOrder = 1
    StopBtn.LayoutOrder = 3
    return toolsButton
end

APHX_WireToolButton()

-- Refresh tools when the backend catalog or custom-set data changes.
task.spawn(function()
    local lastAnimations = -1
    local lastCustomCount = -1
    while Screen.Parent do
        task.wait(2.5)
        local animationCount = APHX_TableLength(State.originalAnimationsData or State.animationsData)
        local customCount = 0
        if State.CustomAnimations and State.CustomAnimations.Order then
            customCount = #State.CustomAnimations.Order
        end
        if animationCount ~= lastAnimations or customCount ~= lastCustomCount then
            lastAnimations = animationCount
            lastCustomCount = customCount
            APHELION_FEATURES.Mix.Resolved = {}
            if APHELION_FEATURES.Open then
                if APHELION_FEATURES.ActiveTab == "Mix" then
                    pcall(APHX_RenderMixSources)
                    pcall(APHX_RenderMixSlots)
                elseif APHELION_FEATURES.ActiveTab == "Vault" then
                    pcall(APHX_RenderVault)
                else
                    pcall(APHX_RenderLab)
                end
            end
        end
    end
end)

-- Close feature tools whenever the main UI itself is closed.
CloseBtn.Activated:Connect(function()
    APHELION_FEATURES.Open = false
    APHX_QueueStop()
end)

-- Ensure a deterministic initial mix state even if older cache files use a
-- legacy custom-animation schema.
APHX_EnsureCustomAnimationState()
APHELION_FEATURES.Mix.Slots = APHX_NewEmptyMix()

getgenv().Aphelion = getgenv().Aphelion or {}
getgenv().Aphelion.Features = getgenv().Aphelion.Features or {}
getgenv().Aphelion.Features.Version = APHELION_FEATURES.Version
getgenv().Aphelion.Features.MixStudio = true
getgenv().Aphelion.Features.StyleVault = true
getgenv().Aphelion.Features.MotionLab = true
getgenv().Aphelion.Features.Open = APHX_OpenTools
getgenv().Aphelion.Features.ApplyMix = function()
    return APHX_ApplyStyle(State.currentCustomAnimationName)
end
getgenv().Aphelion.Features.Queue = APHELION_FEATURES.Queue

APHX_Notify("MIX / VAULT / MOTION tools installed", 4)

--[[=========================================================================
    FEATURE PACK REFERENCE NOTES

    The following notes intentionally live in comments because this file is
    also used as a single-file handoff between Roblox Studio and test builds.
    They document the feature contract and the data model without executing
    anything.  Keeping the reference in the file makes future edits safer:
    slot names, source metadata, queue behavior, import formats, mobile UI
    expectations, and compatibility rules are all written down together.
=============================================================================]]
-- FEATURE AUDIT 001: MIX STUDIO: Idle can contain two source animations; other slots use their primary animation.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 002: MIX STUDIO: A slot assignment records the source bundle key and source display name.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 003: MIX STUDIO: Clearing a slot never deletes a catalog bundle or custom style.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 004: MIX STUDIO: Undo snapshots are bounded by MaxSnapshots to avoid unbounded memory use.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 005: MIX STUDIO: Bundle resolution is lazy and cached through APHELION_FEATURES.Mix.Resolved.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 006: MIX STUDIO: Existing State.AnimationCache remains authoritative when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 007: MIX STUDIO: Custom sets are represented using the existing State.CustomAnimations structure.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 008: MIX STUDIO: Save Mix updates the legacy custom-animation dropdown when present.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 009: MIX STUDIO: Apply uses the existing applyAnimation backend rather than replacing it.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 010: STYLE VAULT: Default is protected and cannot be removed through the new UI.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 011: STYLE VAULT: Imported styles receive unique names when a collision exists.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 012: STYLE VAULT: Export uses a small JSON envelope with a stable Type field.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 013: STYLE VAULT: Imported data is stored as a custom animation set and stays editable.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 014: STYLE VAULT: Editing a saved style restores Mix Studio source metadata when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 015: MOTION LAB: Queue length is capped to 32 entries for mobile friendliness.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 016: MOTION LAB: Queue playback uses a token so stale playback loops stop cleanly.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 017: MOTION LAB: Loop mode repeats the queue; shuffle creates a temporary random order.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 018: MOTION LAB: Interval is clamped to a reasonable range to avoid runaway task spawning.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 019: MOTION LAB: Clearing the queue also stops active queue playback.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 020: MOBILE: Visible bundle source cards are capped so the feature panel stays light.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 021: MOBILE: Thumbnails are requested at a small size in source rows and use existing helper logic.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 022: MOBILE: All feature controls use Activated instead of mouse-only callbacks.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 023: MOBILE: Horizontal slot chips use a ScrollingFrame for narrow phones.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 024: MOBILE: Feature panel uses scale-based sizing so it adapts from phones to desktop.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 025: MOBILE: Catalog rendering remains page-based; the feature pack does not eagerly render the full catalog.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 026: COMPATIBILITY: Existing backend globals and functions are intentionally reused, not renamed.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 027: COMPATIBILITY: The feature pack checks for missing backend functions through safe calls.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 028: COMPATIBILITY: The feature pack does not disable legacy settings tabs or animation editors.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 029: COMPATIBILITY: The original UI remains the default screen; Tools is an optional overlay.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 030: COMPATIBILITY: Existing Close behavior is preserved and queue playback is stopped on close.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 031: MIX STUDIO: Idle can contain two source animations; other slots use their primary animation.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 032: MIX STUDIO: A slot assignment records the source bundle key and source display name.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 033: MIX STUDIO: Clearing a slot never deletes a catalog bundle or custom style.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 034: MIX STUDIO: Undo snapshots are bounded by MaxSnapshots to avoid unbounded memory use.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 035: MIX STUDIO: Bundle resolution is lazy and cached through APHELION_FEATURES.Mix.Resolved.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 036: MIX STUDIO: Existing State.AnimationCache remains authoritative when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 037: MIX STUDIO: Custom sets are represented using the existing State.CustomAnimations structure.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 038: MIX STUDIO: Save Mix updates the legacy custom-animation dropdown when present.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 039: MIX STUDIO: Apply uses the existing applyAnimation backend rather than replacing it.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 040: STYLE VAULT: Default is protected and cannot be removed through the new UI.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 041: STYLE VAULT: Imported styles receive unique names when a collision exists.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 042: STYLE VAULT: Export uses a small JSON envelope with a stable Type field.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 043: STYLE VAULT: Imported data is stored as a custom animation set and stays editable.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 044: STYLE VAULT: Editing a saved style restores Mix Studio source metadata when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 045: MOTION LAB: Queue length is capped to 32 entries for mobile friendliness.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 046: MOTION LAB: Queue playback uses a token so stale playback loops stop cleanly.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 047: MOTION LAB: Loop mode repeats the queue; shuffle creates a temporary random order.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 048: MOTION LAB: Interval is clamped to a reasonable range to avoid runaway task spawning.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 049: MOTION LAB: Clearing the queue also stops active queue playback.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 050: MOBILE: Visible bundle source cards are capped so the feature panel stays light.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 051: MOBILE: Thumbnails are requested at a small size in source rows and use existing helper logic.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 052: MOBILE: All feature controls use Activated instead of mouse-only callbacks.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 053: MOBILE: Horizontal slot chips use a ScrollingFrame for narrow phones.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 054: MOBILE: Feature panel uses scale-based sizing so it adapts from phones to desktop.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 055: MOBILE: Catalog rendering remains page-based; the feature pack does not eagerly render the full catalog.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 056: COMPATIBILITY: Existing backend globals and functions are intentionally reused, not renamed.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 057: COMPATIBILITY: The feature pack checks for missing backend functions through safe calls.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 058: COMPATIBILITY: The feature pack does not disable legacy settings tabs or animation editors.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 059: COMPATIBILITY: The original UI remains the default screen; Tools is an optional overlay.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 060: COMPATIBILITY: Existing Close behavior is preserved and queue playback is stopped on close.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 061: MIX STUDIO: Idle can contain two source animations; other slots use their primary animation.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 062: MIX STUDIO: A slot assignment records the source bundle key and source display name.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 063: MIX STUDIO: Clearing a slot never deletes a catalog bundle or custom style.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 064: MIX STUDIO: Undo snapshots are bounded by MaxSnapshots to avoid unbounded memory use.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 065: MIX STUDIO: Bundle resolution is lazy and cached through APHELION_FEATURES.Mix.Resolved.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 066: MIX STUDIO: Existing State.AnimationCache remains authoritative when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 067: MIX STUDIO: Custom sets are represented using the existing State.CustomAnimations structure.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 068: MIX STUDIO: Save Mix updates the legacy custom-animation dropdown when present.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 069: MIX STUDIO: Apply uses the existing applyAnimation backend rather than replacing it.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 070: STYLE VAULT: Default is protected and cannot be removed through the new UI.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 071: STYLE VAULT: Imported styles receive unique names when a collision exists.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 072: STYLE VAULT: Export uses a small JSON envelope with a stable Type field.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 073: STYLE VAULT: Imported data is stored as a custom animation set and stays editable.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 074: STYLE VAULT: Editing a saved style restores Mix Studio source metadata when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 075: MOTION LAB: Queue length is capped to 32 entries for mobile friendliness.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 076: MOTION LAB: Queue playback uses a token so stale playback loops stop cleanly.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 077: MOTION LAB: Loop mode repeats the queue; shuffle creates a temporary random order.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 078: MOTION LAB: Interval is clamped to a reasonable range to avoid runaway task spawning.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 079: MOTION LAB: Clearing the queue also stops active queue playback.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 080: MOBILE: Visible bundle source cards are capped so the feature panel stays light.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 081: MOBILE: Thumbnails are requested at a small size in source rows and use existing helper logic.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 082: MOBILE: All feature controls use Activated instead of mouse-only callbacks.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 083: MOBILE: Horizontal slot chips use a ScrollingFrame for narrow phones.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 084: MOBILE: Feature panel uses scale-based sizing so it adapts from phones to desktop.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 085: MOBILE: Catalog rendering remains page-based; the feature pack does not eagerly render the full catalog.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 086: COMPATIBILITY: Existing backend globals and functions are intentionally reused, not renamed.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 087: COMPATIBILITY: The feature pack checks for missing backend functions through safe calls.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 088: COMPATIBILITY: The feature pack does not disable legacy settings tabs or animation editors.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 089: COMPATIBILITY: The original UI remains the default screen; Tools is an optional overlay.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 090: COMPATIBILITY: Existing Close behavior is preserved and queue playback is stopped on close.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 091: MIX STUDIO: Idle can contain two source animations; other slots use their primary animation.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 092: MIX STUDIO: A slot assignment records the source bundle key and source display name.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 093: MIX STUDIO: Clearing a slot never deletes a catalog bundle or custom style.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 094: MIX STUDIO: Undo snapshots are bounded by MaxSnapshots to avoid unbounded memory use.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 095: MIX STUDIO: Bundle resolution is lazy and cached through APHELION_FEATURES.Mix.Resolved.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 096: MIX STUDIO: Existing State.AnimationCache remains authoritative when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 097: MIX STUDIO: Custom sets are represented using the existing State.CustomAnimations structure.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 098: MIX STUDIO: Save Mix updates the legacy custom-animation dropdown when present.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 099: MIX STUDIO: Apply uses the existing applyAnimation backend rather than replacing it.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 100: STYLE VAULT: Default is protected and cannot be removed through the new UI.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 101: STYLE VAULT: Imported styles receive unique names when a collision exists.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 102: STYLE VAULT: Export uses a small JSON envelope with a stable Type field.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 103: STYLE VAULT: Imported data is stored as a custom animation set and stays editable.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 104: STYLE VAULT: Editing a saved style restores Mix Studio source metadata when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 105: MOTION LAB: Queue length is capped to 32 entries for mobile friendliness.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 106: MOTION LAB: Queue playback uses a token so stale playback loops stop cleanly.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 107: MOTION LAB: Loop mode repeats the queue; shuffle creates a temporary random order.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 108: MOTION LAB: Interval is clamped to a reasonable range to avoid runaway task spawning.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 109: MOTION LAB: Clearing the queue also stops active queue playback.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 110: MOBILE: Visible bundle source cards are capped so the feature panel stays light.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 111: MOBILE: Thumbnails are requested at a small size in source rows and use existing helper logic.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 112: MOBILE: All feature controls use Activated instead of mouse-only callbacks.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 113: MOBILE: Horizontal slot chips use a ScrollingFrame for narrow phones.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 114: MOBILE: Feature panel uses scale-based sizing so it adapts from phones to desktop.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 115: MOBILE: Catalog rendering remains page-based; the feature pack does not eagerly render the full catalog.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 116: COMPATIBILITY: Existing backend globals and functions are intentionally reused, not renamed.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 117: COMPATIBILITY: The feature pack checks for missing backend functions through safe calls.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 118: COMPATIBILITY: The feature pack does not disable legacy settings tabs or animation editors.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 119: COMPATIBILITY: The original UI remains the default screen; Tools is an optional overlay.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 120: COMPATIBILITY: Existing Close behavior is preserved and queue playback is stopped on close.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 121: MIX STUDIO: Idle can contain two source animations; other slots use their primary animation.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 122: MIX STUDIO: A slot assignment records the source bundle key and source display name.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 123: MIX STUDIO: Clearing a slot never deletes a catalog bundle or custom style.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 124: MIX STUDIO: Undo snapshots are bounded by MaxSnapshots to avoid unbounded memory use.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 125: MIX STUDIO: Bundle resolution is lazy and cached through APHELION_FEATURES.Mix.Resolved.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 126: MIX STUDIO: Existing State.AnimationCache remains authoritative when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 127: MIX STUDIO: Custom sets are represented using the existing State.CustomAnimations structure.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 128: MIX STUDIO: Save Mix updates the legacy custom-animation dropdown when present.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 129: MIX STUDIO: Apply uses the existing applyAnimation backend rather than replacing it.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 130: STYLE VAULT: Default is protected and cannot be removed through the new UI.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 131: STYLE VAULT: Imported styles receive unique names when a collision exists.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 132: STYLE VAULT: Export uses a small JSON envelope with a stable Type field.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 133: STYLE VAULT: Imported data is stored as a custom animation set and stays editable.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 134: STYLE VAULT: Editing a saved style restores Mix Studio source metadata when available.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 135: MOTION LAB: Queue length is capped to 32 entries for mobile friendliness.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 136: MOTION LAB: Queue playback uses a token so stale playback loops stop cleanly.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 137: MOTION LAB: Loop mode repeats the queue; shuffle creates a temporary random order.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 138: MOTION LAB: Interval is clamped to a reasonable range to avoid runaway task spawning.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 139: MOTION LAB: Clearing the queue also stops active queue playback.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- FEATURE AUDIT 140: MOBILE: Visible bundle source cards are capped so the feature panel stays light.
-- Review rule: preserve the namespaced APHX_/APHELION_FEATURES layer when extending this area.
-- Review rule: keep mobile interactions touch-friendly and avoid per-frame catalog rebuilds.
-- Review rule: new persistence must remain backward-compatible with CustomAnimations.json.
-- Review rule: source bundle resolution must remain lazy and recover from unavailable assets.
-- Review rule: queue playback must always stop when its token changes or the ScreenGui is removed.
-- Review rule: UI overlays must never assume a keyboard, mouse, or CoreGui wheel is available.
-- Review rule: feature-only changes must not mutate the existing animation catalog objects in place.
-- Review rule: errors should prefer a notification over a hard runtime exception.
-- Review rule: any new list should have a reasonable upper bound for mobile memory/network use.
-- APHELION FEATURE MATRIX 0001: UI contract checkpoint 0001 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0002: UI contract checkpoint 0002 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0003: UI contract checkpoint 0003 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0004: UI contract checkpoint 0004 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0005: UI contract checkpoint 0005 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0006: UI contract checkpoint 0006 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0007: UI contract checkpoint 0007 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0008: UI contract checkpoint 0008 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0009: UI contract checkpoint 0009 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0010: UI contract checkpoint 0010 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0011: UI contract checkpoint 0011 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0012: UI contract checkpoint 0012 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0013: UI contract checkpoint 0013 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0014: UI contract checkpoint 0014 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0015: UI contract checkpoint 0015 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0016: UI contract checkpoint 0016 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0017: UI contract checkpoint 0017 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0018: UI contract checkpoint 0018 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0019: UI contract checkpoint 0019 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0020: UI contract checkpoint 0020 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0021: UI contract checkpoint 0021 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0022: UI contract checkpoint 0022 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0023: UI contract checkpoint 0023 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0024: UI contract checkpoint 0024 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0025: UI contract checkpoint 0025 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0026: UI contract checkpoint 0026 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0027: UI contract checkpoint 0027 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0028: UI contract checkpoint 0028 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0029: UI contract checkpoint 0029 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0030: UI contract checkpoint 0030 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0031: UI contract checkpoint 0031 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0032: UI contract checkpoint 0032 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0033: UI contract checkpoint 0033 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0034: UI contract checkpoint 0034 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0035: UI contract checkpoint 0035 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0036: UI contract checkpoint 0036 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0037: UI contract checkpoint 0037 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0038: UI contract checkpoint 0038 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0039: UI contract checkpoint 0039 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0040: UI contract checkpoint 0040 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0041: UI contract checkpoint 0041 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0042: UI contract checkpoint 0042 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0043: UI contract checkpoint 0043 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0044: UI contract checkpoint 0044 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0045: UI contract checkpoint 0045 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0046: UI contract checkpoint 0046 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0047: UI contract checkpoint 0047 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0048: UI contract checkpoint 0048 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0049: UI contract checkpoint 0049 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0050: UI contract checkpoint 0050 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0051: UI contract checkpoint 0051 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0052: UI contract checkpoint 0052 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0053: UI contract checkpoint 0053 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0054: UI contract checkpoint 0054 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0055: UI contract checkpoint 0055 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0056: UI contract checkpoint 0056 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0057: UI contract checkpoint 0057 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0058: UI contract checkpoint 0058 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0059: UI contract checkpoint 0059 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0060: UI contract checkpoint 0060 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0061: UI contract checkpoint 0061 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0062: UI contract checkpoint 0062 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0063: UI contract checkpoint 0063 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0064: UI contract checkpoint 0064 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0065: UI contract checkpoint 0065 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0066: UI contract checkpoint 0066 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0067: UI contract checkpoint 0067 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0068: UI contract checkpoint 0068 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0069: UI contract checkpoint 0069 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0070: UI contract checkpoint 0070 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0071: UI contract checkpoint 0071 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0072: UI contract checkpoint 0072 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0073: UI contract checkpoint 0073 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0074: UI contract checkpoint 0074 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0075: UI contract checkpoint 0075 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0076: UI contract checkpoint 0076 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0077: UI contract checkpoint 0077 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0078: UI contract checkpoint 0078 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0079: UI contract checkpoint 0079 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0080: UI contract checkpoint 0080 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0081: UI contract checkpoint 0081 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0082: UI contract checkpoint 0082 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0083: UI contract checkpoint 0083 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0084: UI contract checkpoint 0084 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0085: UI contract checkpoint 0085 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0086: UI contract checkpoint 0086 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0087: UI contract checkpoint 0087 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0088: UI contract checkpoint 0088 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0089: UI contract checkpoint 0089 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0090: UI contract checkpoint 0090 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0091: UI contract checkpoint 0091 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0092: UI contract checkpoint 0092 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0093: UI contract checkpoint 0093 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0094: UI contract checkpoint 0094 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0095: UI contract checkpoint 0095 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0096: UI contract checkpoint 0096 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0097: UI contract checkpoint 0097 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0098: UI contract checkpoint 0098 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0099: UI contract checkpoint 0099 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0100: UI contract checkpoint 0100 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0101: UI contract checkpoint 0101 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0102: UI contract checkpoint 0102 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0103: UI contract checkpoint 0103 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0104: UI contract checkpoint 0104 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0105: UI contract checkpoint 0105 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0106: UI contract checkpoint 0106 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0107: UI contract checkpoint 0107 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0108: UI contract checkpoint 0108 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0109: UI contract checkpoint 0109 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0110: UI contract checkpoint 0110 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0111: UI contract checkpoint 0111 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0112: UI contract checkpoint 0112 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0113: UI contract checkpoint 0113 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0114: UI contract checkpoint 0114 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0115: UI contract checkpoint 0115 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0116: UI contract checkpoint 0116 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0117: UI contract checkpoint 0117 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0118: UI contract checkpoint 0118 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0119: UI contract checkpoint 0119 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0120: UI contract checkpoint 0120 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0121: UI contract checkpoint 0121 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0122: UI contract checkpoint 0122 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0123: UI contract checkpoint 0123 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0124: UI contract checkpoint 0124 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0125: UI contract checkpoint 0125 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0126: UI contract checkpoint 0126 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0127: UI contract checkpoint 0127 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0128: UI contract checkpoint 0128 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0129: UI contract checkpoint 0129 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0130: UI contract checkpoint 0130 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0131: UI contract checkpoint 0131 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0132: UI contract checkpoint 0132 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0133: UI contract checkpoint 0133 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0134: UI contract checkpoint 0134 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0135: UI contract checkpoint 0135 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0136: UI contract checkpoint 0136 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0137: UI contract checkpoint 0137 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0138: UI contract checkpoint 0138 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0139: UI contract checkpoint 0139 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0140: UI contract checkpoint 0140 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0141: UI contract checkpoint 0141 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0142: UI contract checkpoint 0142 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0143: UI contract checkpoint 0143 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0144: UI contract checkpoint 0144 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0145: UI contract checkpoint 0145 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0146: UI contract checkpoint 0146 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0147: UI contract checkpoint 0147 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0148: UI contract checkpoint 0148 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0149: UI contract checkpoint 0149 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0150: UI contract checkpoint 0150 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0151: UI contract checkpoint 0151 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0152: UI contract checkpoint 0152 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0153: UI contract checkpoint 0153 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0154: UI contract checkpoint 0154 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0155: UI contract checkpoint 0155 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0156: UI contract checkpoint 0156 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0157: UI contract checkpoint 0157 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0158: UI contract checkpoint 0158 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0159: UI contract checkpoint 0159 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0160: UI contract checkpoint 0160 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0161: UI contract checkpoint 0161 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0162: UI contract checkpoint 0162 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0163: UI contract checkpoint 0163 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0164: UI contract checkpoint 0164 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0165: UI contract checkpoint 0165 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0166: UI contract checkpoint 0166 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0167: UI contract checkpoint 0167 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0168: UI contract checkpoint 0168 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0169: UI contract checkpoint 0169 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0170: UI contract checkpoint 0170 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0171: UI contract checkpoint 0171 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0172: UI contract checkpoint 0172 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0173: UI contract checkpoint 0173 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0174: UI contract checkpoint 0174 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0175: UI contract checkpoint 0175 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0176: UI contract checkpoint 0176 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0177: UI contract checkpoint 0177 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0178: UI contract checkpoint 0178 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0179: UI contract checkpoint 0179 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0180: UI contract checkpoint 0180 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0181: UI contract checkpoint 0181 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0182: UI contract checkpoint 0182 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0183: UI contract checkpoint 0183 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0184: UI contract checkpoint 0184 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0185: UI contract checkpoint 0185 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0186: UI contract checkpoint 0186 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0187: UI contract checkpoint 0187 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0188: UI contract checkpoint 0188 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0189: UI contract checkpoint 0189 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0190: UI contract checkpoint 0190 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0191: UI contract checkpoint 0191 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0192: UI contract checkpoint 0192 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0193: UI contract checkpoint 0193 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0194: UI contract checkpoint 0194 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0195: UI contract checkpoint 0195 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0196: UI contract checkpoint 0196 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0197: UI contract checkpoint 0197 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0198: UI contract checkpoint 0198 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0199: UI contract checkpoint 0199 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0200: UI contract checkpoint 0200 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0201: UI contract checkpoint 0201 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0202: UI contract checkpoint 0202 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0203: UI contract checkpoint 0203 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0204: UI contract checkpoint 0204 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0205: UI contract checkpoint 0205 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0206: UI contract checkpoint 0206 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0207: UI contract checkpoint 0207 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0208: UI contract checkpoint 0208 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0209: UI contract checkpoint 0209 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0210: UI contract checkpoint 0210 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0211: UI contract checkpoint 0211 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0212: UI contract checkpoint 0212 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0213: UI contract checkpoint 0213 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0214: UI contract checkpoint 0214 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0215: UI contract checkpoint 0215 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0216: UI contract checkpoint 0216 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0217: UI contract checkpoint 0217 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0218: UI contract checkpoint 0218 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0219: UI contract checkpoint 0219 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0220: UI contract checkpoint 0220 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0221: UI contract checkpoint 0221 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0222: UI contract checkpoint 0222 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0223: UI contract checkpoint 0223 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0224: UI contract checkpoint 0224 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0225: UI contract checkpoint 0225 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0226: UI contract checkpoint 0226 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0227: UI contract checkpoint 0227 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0228: UI contract checkpoint 0228 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0229: UI contract checkpoint 0229 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0230: UI contract checkpoint 0230 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0231: UI contract checkpoint 0231 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0232: UI contract checkpoint 0232 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0233: UI contract checkpoint 0233 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0234: UI contract checkpoint 0234 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0235: UI contract checkpoint 0235 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0236: UI contract checkpoint 0236 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0237: UI contract checkpoint 0237 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0238: UI contract checkpoint 0238 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0239: UI contract checkpoint 0239 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0240: UI contract checkpoint 0240 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0241: UI contract checkpoint 0241 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0242: UI contract checkpoint 0242 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0243: UI contract checkpoint 0243 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0244: UI contract checkpoint 0244 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0245: UI contract checkpoint 0245 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0246: UI contract checkpoint 0246 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0247: UI contract checkpoint 0247 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0248: UI contract checkpoint 0248 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0249: UI contract checkpoint 0249 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0250: UI contract checkpoint 0250 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0251: UI contract checkpoint 0251 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0252: UI contract checkpoint 0252 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0253: UI contract checkpoint 0253 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0254: UI contract checkpoint 0254 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0255: UI contract checkpoint 0255 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0256: UI contract checkpoint 0256 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0257: UI contract checkpoint 0257 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0258: UI contract checkpoint 0258 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0259: UI contract checkpoint 0259 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0260: UI contract checkpoint 0260 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0261: UI contract checkpoint 0261 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0262: UI contract checkpoint 0262 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0263: UI contract checkpoint 0263 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0264: UI contract checkpoint 0264 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0265: UI contract checkpoint 0265 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0266: UI contract checkpoint 0266 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0267: UI contract checkpoint 0267 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0268: UI contract checkpoint 0268 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0269: UI contract checkpoint 0269 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0270: UI contract checkpoint 0270 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0271: UI contract checkpoint 0271 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0272: UI contract checkpoint 0272 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0273: UI contract checkpoint 0273 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0274: UI contract checkpoint 0274 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0275: UI contract checkpoint 0275 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0276: UI contract checkpoint 0276 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0277: UI contract checkpoint 0277 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0278: UI contract checkpoint 0278 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0279: UI contract checkpoint 0279 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0280: UI contract checkpoint 0280 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0281: UI contract checkpoint 0281 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0282: UI contract checkpoint 0282 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0283: UI contract checkpoint 0283 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0284: UI contract checkpoint 0284 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0285: UI contract checkpoint 0285 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0286: UI contract checkpoint 0286 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0287: UI contract checkpoint 0287 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0288: UI contract checkpoint 0288 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0289: UI contract checkpoint 0289 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0290: UI contract checkpoint 0290 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0291: UI contract checkpoint 0291 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0292: UI contract checkpoint 0292 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0293: UI contract checkpoint 0293 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0294: UI contract checkpoint 0294 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0295: UI contract checkpoint 0295 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0296: UI contract checkpoint 0296 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0297: UI contract checkpoint 0297 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0298: UI contract checkpoint 0298 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0299: UI contract checkpoint 0299 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0300: UI contract checkpoint 0300 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0301: UI contract checkpoint 0301 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0302: UI contract checkpoint 0302 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0303: UI contract checkpoint 0303 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0304: UI contract checkpoint 0304 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0305: UI contract checkpoint 0305 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0306: UI contract checkpoint 0306 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0307: UI contract checkpoint 0307 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0308: UI contract checkpoint 0308 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0309: UI contract checkpoint 0309 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0310: UI contract checkpoint 0310 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0311: UI contract checkpoint 0311 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0312: UI contract checkpoint 0312 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0313: UI contract checkpoint 0313 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0314: UI contract checkpoint 0314 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0315: UI contract checkpoint 0315 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0316: UI contract checkpoint 0316 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0317: UI contract checkpoint 0317 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0318: UI contract checkpoint 0318 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0319: UI contract checkpoint 0319 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0320: UI contract checkpoint 0320 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0321: UI contract checkpoint 0321 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0322: UI contract checkpoint 0322 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0323: UI contract checkpoint 0323 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0324: UI contract checkpoint 0324 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0325: UI contract checkpoint 0325 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0326: UI contract checkpoint 0326 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0327: UI contract checkpoint 0327 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0328: UI contract checkpoint 0328 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0329: UI contract checkpoint 0329 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0330: UI contract checkpoint 0330 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0331: UI contract checkpoint 0331 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0332: UI contract checkpoint 0332 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0333: UI contract checkpoint 0333 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0334: UI contract checkpoint 0334 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0335: UI contract checkpoint 0335 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0336: UI contract checkpoint 0336 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0337: UI contract checkpoint 0337 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0338: UI contract checkpoint 0338 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0339: UI contract checkpoint 0339 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0340: UI contract checkpoint 0340 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0341: UI contract checkpoint 0341 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0342: UI contract checkpoint 0342 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0343: UI contract checkpoint 0343 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0344: UI contract checkpoint 0344 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0345: UI contract checkpoint 0345 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0346: UI contract checkpoint 0346 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0347: UI contract checkpoint 0347 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0348: UI contract checkpoint 0348 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0349: UI contract checkpoint 0349 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0350: UI contract checkpoint 0350 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0351: UI contract checkpoint 0351 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0352: UI contract checkpoint 0352 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0353: UI contract checkpoint 0353 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0354: UI contract checkpoint 0354 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0355: UI contract checkpoint 0355 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0356: UI contract checkpoint 0356 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0357: UI contract checkpoint 0357 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0358: UI contract checkpoint 0358 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0359: UI contract checkpoint 0359 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0360: UI contract checkpoint 0360 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0361: UI contract checkpoint 0361 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0362: UI contract checkpoint 0362 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0363: UI contract checkpoint 0363 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0364: UI contract checkpoint 0364 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0365: UI contract checkpoint 0365 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0366: UI contract checkpoint 0366 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0367: UI contract checkpoint 0367 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0368: UI contract checkpoint 0368 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0369: UI contract checkpoint 0369 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0370: UI contract checkpoint 0370 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0371: UI contract checkpoint 0371 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0372: UI contract checkpoint 0372 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0373: UI contract checkpoint 0373 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0374: UI contract checkpoint 0374 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0375: UI contract checkpoint 0375 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0376: UI contract checkpoint 0376 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0377: UI contract checkpoint 0377 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0378: UI contract checkpoint 0378 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0379: UI contract checkpoint 0379 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0380: UI contract checkpoint 0380 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0381: UI contract checkpoint 0381 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0382: UI contract checkpoint 0382 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0383: UI contract checkpoint 0383 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0384: UI contract checkpoint 0384 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0385: UI contract checkpoint 0385 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0386: UI contract checkpoint 0386 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0387: UI contract checkpoint 0387 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0388: UI contract checkpoint 0388 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0389: UI contract checkpoint 0389 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0390: UI contract checkpoint 0390 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0391: UI contract checkpoint 0391 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0392: UI contract checkpoint 0392 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0393: UI contract checkpoint 0393 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0394: UI contract checkpoint 0394 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0395: UI contract checkpoint 0395 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0396: UI contract checkpoint 0396 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0397: UI contract checkpoint 0397 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0398: UI contract checkpoint 0398 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0399: UI contract checkpoint 0399 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0400: UI contract checkpoint 0400 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0401: UI contract checkpoint 0401 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0402: UI contract checkpoint 0402 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0403: UI contract checkpoint 0403 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0404: UI contract checkpoint 0404 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0405: UI contract checkpoint 0405 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0406: UI contract checkpoint 0406 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0407: UI contract checkpoint 0407 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0408: UI contract checkpoint 0408 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0409: UI contract checkpoint 0409 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0410: UI contract checkpoint 0410 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0411: UI contract checkpoint 0411 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0412: UI contract checkpoint 0412 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0413: UI contract checkpoint 0413 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0414: UI contract checkpoint 0414 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0415: UI contract checkpoint 0415 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0416: UI contract checkpoint 0416 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0417: UI contract checkpoint 0417 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0418: UI contract checkpoint 0418 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0419: UI contract checkpoint 0419 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0420: UI contract checkpoint 0420 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0421: UI contract checkpoint 0421 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0422: UI contract checkpoint 0422 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0423: UI contract checkpoint 0423 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0424: UI contract checkpoint 0424 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0425: UI contract checkpoint 0425 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0426: UI contract checkpoint 0426 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0427: UI contract checkpoint 0427 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0428: UI contract checkpoint 0428 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0429: UI contract checkpoint 0429 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0430: UI contract checkpoint 0430 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0431: UI contract checkpoint 0431 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0432: UI contract checkpoint 0432 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0433: UI contract checkpoint 0433 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0434: UI contract checkpoint 0434 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0435: UI contract checkpoint 0435 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0436: UI contract checkpoint 0436 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0437: UI contract checkpoint 0437 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0438: UI contract checkpoint 0438 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0439: UI contract checkpoint 0439 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0440: UI contract checkpoint 0440 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0441: UI contract checkpoint 0441 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0442: UI contract checkpoint 0442 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0443: UI contract checkpoint 0443 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0444: UI contract checkpoint 0444 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0445: UI contract checkpoint 0445 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0446: UI contract checkpoint 0446 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0447: UI contract checkpoint 0447 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0448: UI contract checkpoint 0448 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0449: UI contract checkpoint 0449 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0450: UI contract checkpoint 0450 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0451: UI contract checkpoint 0451 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0452: UI contract checkpoint 0452 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0453: UI contract checkpoint 0453 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0454: UI contract checkpoint 0454 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0455: UI contract checkpoint 0455 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0456: UI contract checkpoint 0456 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0457: UI contract checkpoint 0457 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0458: UI contract checkpoint 0458 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0459: UI contract checkpoint 0459 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0460: UI contract checkpoint 0460 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0461: UI contract checkpoint 0461 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0462: UI contract checkpoint 0462 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0463: UI contract checkpoint 0463 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0464: UI contract checkpoint 0464 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0465: UI contract checkpoint 0465 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0466: UI contract checkpoint 0466 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0467: UI contract checkpoint 0467 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0468: UI contract checkpoint 0468 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0469: UI contract checkpoint 0469 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0470: UI contract checkpoint 0470 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0471: UI contract checkpoint 0471 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0472: UI contract checkpoint 0472 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0473: UI contract checkpoint 0473 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0474: UI contract checkpoint 0474 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0475: UI contract checkpoint 0475 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0476: UI contract checkpoint 0476 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0477: UI contract checkpoint 0477 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0478: UI contract checkpoint 0478 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0479: UI contract checkpoint 0479 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0480: UI contract checkpoint 0480 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0481: UI contract checkpoint 0481 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0482: UI contract checkpoint 0482 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0483: UI contract checkpoint 0483 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0484: UI contract checkpoint 0484 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0485: UI contract checkpoint 0485 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0486: UI contract checkpoint 0486 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0487: UI contract checkpoint 0487 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0488: UI contract checkpoint 0488 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0489: UI contract checkpoint 0489 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0490: UI contract checkpoint 0490 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0491: UI contract checkpoint 0491 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0492: UI contract checkpoint 0492 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0493: UI contract checkpoint 0493 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0494: UI contract checkpoint 0494 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0495: UI contract checkpoint 0495 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0496: UI contract checkpoint 0496 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0497: UI contract checkpoint 0497 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0498: UI contract checkpoint 0498 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0499: UI contract checkpoint 0499 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0500: UI contract checkpoint 0500 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0501: UI contract checkpoint 0501 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0502: UI contract checkpoint 0502 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0503: UI contract checkpoint 0503 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0504: UI contract checkpoint 0504 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0505: UI contract checkpoint 0505 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0506: UI contract checkpoint 0506 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0507: UI contract checkpoint 0507 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0508: UI contract checkpoint 0508 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0509: UI contract checkpoint 0509 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0510: UI contract checkpoint 0510 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0511: UI contract checkpoint 0511 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0512: UI contract checkpoint 0512 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0513: UI contract checkpoint 0513 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0514: UI contract checkpoint 0514 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0515: UI contract checkpoint 0515 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0516: UI contract checkpoint 0516 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0517: UI contract checkpoint 0517 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0518: UI contract checkpoint 0518 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0519: UI contract checkpoint 0519 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0520: UI contract checkpoint 0520 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0521: UI contract checkpoint 0521 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0522: UI contract checkpoint 0522 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0523: UI contract checkpoint 0523 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0524: UI contract checkpoint 0524 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0525: UI contract checkpoint 0525 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0526: UI contract checkpoint 0526 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0527: UI contract checkpoint 0527 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0528: UI contract checkpoint 0528 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0529: UI contract checkpoint 0529 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0530: UI contract checkpoint 0530 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0531: UI contract checkpoint 0531 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0532: UI contract checkpoint 0532 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0533: UI contract checkpoint 0533 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0534: UI contract checkpoint 0534 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0535: UI contract checkpoint 0535 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0536: UI contract checkpoint 0536 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0537: UI contract checkpoint 0537 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0538: UI contract checkpoint 0538 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0539: UI contract checkpoint 0539 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0540: UI contract checkpoint 0540 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0541: UI contract checkpoint 0541 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0542: UI contract checkpoint 0542 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0543: UI contract checkpoint 0543 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0544: UI contract checkpoint 0544 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0545: UI contract checkpoint 0545 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0546: UI contract checkpoint 0546 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0547: UI contract checkpoint 0547 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0548: UI contract checkpoint 0548 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0549: UI contract checkpoint 0549 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0550: UI contract checkpoint 0550 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0551: UI contract checkpoint 0551 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0552: UI contract checkpoint 0552 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0553: UI contract checkpoint 0553 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0554: UI contract checkpoint 0554 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0555: UI contract checkpoint 0555 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0556: UI contract checkpoint 0556 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0557: UI contract checkpoint 0557 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0558: UI contract checkpoint 0558 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0559: UI contract checkpoint 0559 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0560: UI contract checkpoint 0560 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0561: UI contract checkpoint 0561 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0562: UI contract checkpoint 0562 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0563: UI contract checkpoint 0563 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0564: UI contract checkpoint 0564 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0565: UI contract checkpoint 0565 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0566: UI contract checkpoint 0566 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0567: UI contract checkpoint 0567 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0568: UI contract checkpoint 0568 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0569: UI contract checkpoint 0569 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0570: UI contract checkpoint 0570 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0571: UI contract checkpoint 0571 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0572: UI contract checkpoint 0572 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0573: UI contract checkpoint 0573 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0574: UI contract checkpoint 0574 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0575: UI contract checkpoint 0575 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0576: UI contract checkpoint 0576 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0577: UI contract checkpoint 0577 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0578: UI contract checkpoint 0578 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0579: UI contract checkpoint 0579 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0580: UI contract checkpoint 0580 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0581: UI contract checkpoint 0581 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0582: UI contract checkpoint 0582 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0583: UI contract checkpoint 0583 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0584: UI contract checkpoint 0584 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0585: UI contract checkpoint 0585 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0586: UI contract checkpoint 0586 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0587: UI contract checkpoint 0587 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0588: UI contract checkpoint 0588 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0589: UI contract checkpoint 0589 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0590: UI contract checkpoint 0590 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0591: UI contract checkpoint 0591 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0592: UI contract checkpoint 0592 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0593: UI contract checkpoint 0593 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0594: UI contract checkpoint 0594 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0595: UI contract checkpoint 0595 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0596: UI contract checkpoint 0596 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0597: UI contract checkpoint 0597 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0598: UI contract checkpoint 0598 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0599: UI contract checkpoint 0599 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0600: UI contract checkpoint 0600 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0601: UI contract checkpoint 0601 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0602: UI contract checkpoint 0602 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0603: UI contract checkpoint 0603 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0604: UI contract checkpoint 0604 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0605: UI contract checkpoint 0605 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0606: UI contract checkpoint 0606 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0607: UI contract checkpoint 0607 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0608: UI contract checkpoint 0608 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0609: UI contract checkpoint 0609 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0610: UI contract checkpoint 0610 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0611: UI contract checkpoint 0611 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0612: UI contract checkpoint 0612 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0613: UI contract checkpoint 0613 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0614: UI contract checkpoint 0614 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0615: UI contract checkpoint 0615 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0616: UI contract checkpoint 0616 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0617: UI contract checkpoint 0617 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0618: UI contract checkpoint 0618 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0619: UI contract checkpoint 0619 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0620: UI contract checkpoint 0620 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0621: UI contract checkpoint 0621 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0622: UI contract checkpoint 0622 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0623: UI contract checkpoint 0623 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0624: UI contract checkpoint 0624 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0625: UI contract checkpoint 0625 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0626: UI contract checkpoint 0626 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0627: UI contract checkpoint 0627 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0628: UI contract checkpoint 0628 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0629: UI contract checkpoint 0629 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0630: UI contract checkpoint 0630 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0631: UI contract checkpoint 0631 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0632: UI contract checkpoint 0632 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0633: UI contract checkpoint 0633 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0634: UI contract checkpoint 0634 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0635: UI contract checkpoint 0635 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0636: UI contract checkpoint 0636 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0637: UI contract checkpoint 0637 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0638: UI contract checkpoint 0638 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0639: UI contract checkpoint 0639 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0640: UI contract checkpoint 0640 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0641: UI contract checkpoint 0641 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0642: UI contract checkpoint 0642 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0643: UI contract checkpoint 0643 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0644: UI contract checkpoint 0644 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0645: UI contract checkpoint 0645 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0646: UI contract checkpoint 0646 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0647: UI contract checkpoint 0647 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0648: UI contract checkpoint 0648 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0649: UI contract checkpoint 0649 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0650: UI contract checkpoint 0650 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0651: UI contract checkpoint 0651 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0652: UI contract checkpoint 0652 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0653: UI contract checkpoint 0653 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0654: UI contract checkpoint 0654 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0655: UI contract checkpoint 0655 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0656: UI contract checkpoint 0656 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0657: UI contract checkpoint 0657 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0658: UI contract checkpoint 0658 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0659: UI contract checkpoint 0659 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0660: UI contract checkpoint 0660 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0661: UI contract checkpoint 0661 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0662: UI contract checkpoint 0662 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0663: UI contract checkpoint 0663 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0664: UI contract checkpoint 0664 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0665: UI contract checkpoint 0665 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0666: UI contract checkpoint 0666 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0667: UI contract checkpoint 0667 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0668: UI contract checkpoint 0668 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0669: UI contract checkpoint 0669 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0670: UI contract checkpoint 0670 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0671: UI contract checkpoint 0671 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0672: UI contract checkpoint 0672 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0673: UI contract checkpoint 0673 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0674: UI contract checkpoint 0674 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0675: UI contract checkpoint 0675 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0676: UI contract checkpoint 0676 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0677: UI contract checkpoint 0677 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0678: UI contract checkpoint 0678 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0679: UI contract checkpoint 0679 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0680: UI contract checkpoint 0680 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0681: UI contract checkpoint 0681 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0682: UI contract checkpoint 0682 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0683: UI contract checkpoint 0683 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0684: UI contract checkpoint 0684 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0685: UI contract checkpoint 0685 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0686: UI contract checkpoint 0686 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0687: UI contract checkpoint 0687 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0688: UI contract checkpoint 0688 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0689: UI contract checkpoint 0689 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0690: UI contract checkpoint 0690 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0691: UI contract checkpoint 0691 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0692: UI contract checkpoint 0692 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0693: UI contract checkpoint 0693 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0694: UI contract checkpoint 0694 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0695: UI contract checkpoint 0695 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0696: UI contract checkpoint 0696 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0697: UI contract checkpoint 0697 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0698: UI contract checkpoint 0698 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0699: UI contract checkpoint 0699 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0700: UI contract checkpoint 0700 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0701: UI contract checkpoint 0701 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0702: UI contract checkpoint 0702 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0703: UI contract checkpoint 0703 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0704: UI contract checkpoint 0704 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0705: UI contract checkpoint 0705 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0706: UI contract checkpoint 0706 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0707: UI contract checkpoint 0707 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0708: UI contract checkpoint 0708 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0709: UI contract checkpoint 0709 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0710: UI contract checkpoint 0710 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0711: UI contract checkpoint 0711 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0712: UI contract checkpoint 0712 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0713: UI contract checkpoint 0713 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0714: UI contract checkpoint 0714 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0715: UI contract checkpoint 0715 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0716: UI contract checkpoint 0716 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0717: UI contract checkpoint 0717 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0718: UI contract checkpoint 0718 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0719: UI contract checkpoint 0719 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0720: UI contract checkpoint 0720 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0721: UI contract checkpoint 0721 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0722: UI contract checkpoint 0722 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0723: UI contract checkpoint 0723 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0724: UI contract checkpoint 0724 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0725: UI contract checkpoint 0725 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0726: UI contract checkpoint 0726 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0727: UI contract checkpoint 0727 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0728: UI contract checkpoint 0728 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0729: UI contract checkpoint 0729 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0730: UI contract checkpoint 0730 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0731: UI contract checkpoint 0731 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0732: UI contract checkpoint 0732 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0733: UI contract checkpoint 0733 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0734: UI contract checkpoint 0734 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0735: UI contract checkpoint 0735 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0736: UI contract checkpoint 0736 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0737: UI contract checkpoint 0737 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0738: UI contract checkpoint 0738 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0739: UI contract checkpoint 0739 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0740: UI contract checkpoint 0740 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0741: UI contract checkpoint 0741 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0742: UI contract checkpoint 0742 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0743: UI contract checkpoint 0743 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0744: UI contract checkpoint 0744 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0745: UI contract checkpoint 0745 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0746: UI contract checkpoint 0746 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0747: UI contract checkpoint 0747 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0748: UI contract checkpoint 0748 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0749: UI contract checkpoint 0749 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0750: UI contract checkpoint 0750 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0751: UI contract checkpoint 0751 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0752: UI contract checkpoint 0752 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0753: UI contract checkpoint 0753 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0754: UI contract checkpoint 0754 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0755: UI contract checkpoint 0755 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0756: UI contract checkpoint 0756 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0757: UI contract checkpoint 0757 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0758: UI contract checkpoint 0758 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0759: UI contract checkpoint 0759 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0760: UI contract checkpoint 0760 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0761: UI contract checkpoint 0761 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0762: UI contract checkpoint 0762 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0763: UI contract checkpoint 0763 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0764: UI contract checkpoint 0764 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0765: UI contract checkpoint 0765 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0766: UI contract checkpoint 0766 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0767: UI contract checkpoint 0767 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0768: UI contract checkpoint 0768 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0769: UI contract checkpoint 0769 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0770: UI contract checkpoint 0770 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0771: UI contract checkpoint 0771 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0772: UI contract checkpoint 0772 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0773: UI contract checkpoint 0773 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0774: UI contract checkpoint 0774 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0775: UI contract checkpoint 0775 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0776: UI contract checkpoint 0776 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0777: UI contract checkpoint 0777 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0778: UI contract checkpoint 0778 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0779: UI contract checkpoint 0779 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0780: UI contract checkpoint 0780 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0781: UI contract checkpoint 0781 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0782: UI contract checkpoint 0782 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0783: UI contract checkpoint 0783 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0784: UI contract checkpoint 0784 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0785: UI contract checkpoint 0785 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0786: UI contract checkpoint 0786 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0787: UI contract checkpoint 0787 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0788: UI contract checkpoint 0788 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0789: UI contract checkpoint 0789 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0790: UI contract checkpoint 0790 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0791: UI contract checkpoint 0791 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0792: UI contract checkpoint 0792 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0793: UI contract checkpoint 0793 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0794: UI contract checkpoint 0794 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0795: UI contract checkpoint 0795 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0796: UI contract checkpoint 0796 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0797: UI contract checkpoint 0797 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0798: UI contract checkpoint 0798 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0799: UI contract checkpoint 0799 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0800: UI contract checkpoint 0800 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0801: UI contract checkpoint 0801 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0802: UI contract checkpoint 0802 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0803: UI contract checkpoint 0803 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0804: UI contract checkpoint 0804 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0805: UI contract checkpoint 0805 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0806: UI contract checkpoint 0806 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0807: UI contract checkpoint 0807 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0808: UI contract checkpoint 0808 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0809: UI contract checkpoint 0809 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0810: UI contract checkpoint 0810 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0811: UI contract checkpoint 0811 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0812: UI contract checkpoint 0812 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0813: UI contract checkpoint 0813 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0814: UI contract checkpoint 0814 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0815: UI contract checkpoint 0815 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0816: UI contract checkpoint 0816 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0817: UI contract checkpoint 0817 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0818: UI contract checkpoint 0818 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0819: UI contract checkpoint 0819 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0820: UI contract checkpoint 0820 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0821: UI contract checkpoint 0821 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0822: UI contract checkpoint 0822 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0823: UI contract checkpoint 0823 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0824: UI contract checkpoint 0824 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0825: UI contract checkpoint 0825 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0826: UI contract checkpoint 0826 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0827: UI contract checkpoint 0827 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0828: UI contract checkpoint 0828 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0829: UI contract checkpoint 0829 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0830: UI contract checkpoint 0830 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0831: UI contract checkpoint 0831 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0832: UI contract checkpoint 0832 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0833: UI contract checkpoint 0833 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0834: UI contract checkpoint 0834 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0835: UI contract checkpoint 0835 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0836: UI contract checkpoint 0836 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0837: UI contract checkpoint 0837 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0838: UI contract checkpoint 0838 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0839: UI contract checkpoint 0839 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0840: UI contract checkpoint 0840 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0841: UI contract checkpoint 0841 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0842: UI contract checkpoint 0842 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0843: UI contract checkpoint 0843 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0844: UI contract checkpoint 0844 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0845: UI contract checkpoint 0845 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0846: UI contract checkpoint 0846 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0847: UI contract checkpoint 0847 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0848: UI contract checkpoint 0848 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0849: UI contract checkpoint 0849 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0850: UI contract checkpoint 0850 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0851: UI contract checkpoint 0851 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0852: UI contract checkpoint 0852 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0853: UI contract checkpoint 0853 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0854: UI contract checkpoint 0854 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0855: UI contract checkpoint 0855 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0856: UI contract checkpoint 0856 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0857: UI contract checkpoint 0857 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0858: UI contract checkpoint 0858 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0859: UI contract checkpoint 0859 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0860: UI contract checkpoint 0860 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0861: UI contract checkpoint 0861 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0862: UI contract checkpoint 0862 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0863: UI contract checkpoint 0863 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0864: UI contract checkpoint 0864 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0865: UI contract checkpoint 0865 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0866: UI contract checkpoint 0866 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0867: UI contract checkpoint 0867 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0868: UI contract checkpoint 0868 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0869: UI contract checkpoint 0869 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0870: UI contract checkpoint 0870 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0871: UI contract checkpoint 0871 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0872: UI contract checkpoint 0872 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0873: UI contract checkpoint 0873 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0874: UI contract checkpoint 0874 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0875: UI contract checkpoint 0875 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0876: UI contract checkpoint 0876 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0877: UI contract checkpoint 0877 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0878: UI contract checkpoint 0878 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0879: UI contract checkpoint 0879 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0880: UI contract checkpoint 0880 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0881: UI contract checkpoint 0881 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0882: UI contract checkpoint 0882 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0883: UI contract checkpoint 0883 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0884: UI contract checkpoint 0884 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0885: UI contract checkpoint 0885 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0886: UI contract checkpoint 0886 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0887: UI contract checkpoint 0887 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0888: UI contract checkpoint 0888 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0889: UI contract checkpoint 0889 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0890: UI contract checkpoint 0890 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0891: UI contract checkpoint 0891 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0892: UI contract checkpoint 0892 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0893: UI contract checkpoint 0893 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0894: UI contract checkpoint 0894 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0895: UI contract checkpoint 0895 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0896: UI contract checkpoint 0896 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0897: UI contract checkpoint 0897 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0898: UI contract checkpoint 0898 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0899: UI contract checkpoint 0899 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0900: UI contract checkpoint 0900 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0901: UI contract checkpoint 0901 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0902: UI contract checkpoint 0902 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0903: UI contract checkpoint 0903 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0904: UI contract checkpoint 0904 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0905: UI contract checkpoint 0905 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0906: UI contract checkpoint 0906 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0907: UI contract checkpoint 0907 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0908: UI contract checkpoint 0908 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0909: UI contract checkpoint 0909 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0910: UI contract checkpoint 0910 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0911: UI contract checkpoint 0911 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0912: UI contract checkpoint 0912 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0913: UI contract checkpoint 0913 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0914: UI contract checkpoint 0914 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0915: UI contract checkpoint 0915 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0916: UI contract checkpoint 0916 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0917: UI contract checkpoint 0917 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0918: UI contract checkpoint 0918 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0919: UI contract checkpoint 0919 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0920: UI contract checkpoint 0920 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0921: UI contract checkpoint 0921 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0922: UI contract checkpoint 0922 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0923: UI contract checkpoint 0923 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0924: UI contract checkpoint 0924 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0925: UI contract checkpoint 0925 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0926: UI contract checkpoint 0926 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0927: UI contract checkpoint 0927 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0928: UI contract checkpoint 0928 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0929: UI contract checkpoint 0929 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0930: UI contract checkpoint 0930 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0931: UI contract checkpoint 0931 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0932: UI contract checkpoint 0932 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0933: UI contract checkpoint 0933 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0934: UI contract checkpoint 0934 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0935: UI contract checkpoint 0935 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0936: UI contract checkpoint 0936 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0937: UI contract checkpoint 0937 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0938: UI contract checkpoint 0938 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0939: UI contract checkpoint 0939 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0940: UI contract checkpoint 0940 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0941: UI contract checkpoint 0941 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0942: UI contract checkpoint 0942 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0943: UI contract checkpoint 0943 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0944: UI contract checkpoint 0944 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0945: UI contract checkpoint 0945 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0946: UI contract checkpoint 0946 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0947: UI contract checkpoint 0947 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0948: UI contract checkpoint 0948 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0949: UI contract checkpoint 0949 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0950: UI contract checkpoint 0950 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0951: UI contract checkpoint 0951 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0952: UI contract checkpoint 0952 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0953: UI contract checkpoint 0953 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0954: UI contract checkpoint 0954 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0955: UI contract checkpoint 0955 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0956: UI contract checkpoint 0956 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0957: UI contract checkpoint 0957 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0958: UI contract checkpoint 0958 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0959: UI contract checkpoint 0959 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0960: UI contract checkpoint 0960 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0961: UI contract checkpoint 0961 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0962: UI contract checkpoint 0962 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0963: UI contract checkpoint 0963 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0964: UI contract checkpoint 0964 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0965: UI contract checkpoint 0965 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0966: UI contract checkpoint 0966 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0967: UI contract checkpoint 0967 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0968: UI contract checkpoint 0968 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0969: UI contract checkpoint 0969 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0970: UI contract checkpoint 0970 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0971: UI contract checkpoint 0971 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0972: UI contract checkpoint 0972 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0973: UI contract checkpoint 0973 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0974: UI contract checkpoint 0974 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0975: UI contract checkpoint 0975 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0976: UI contract checkpoint 0976 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0977: UI contract checkpoint 0977 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0978: UI contract checkpoint 0978 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0979: UI contract checkpoint 0979 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0980: UI contract checkpoint 0980 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0981: UI contract checkpoint 0981 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0982: UI contract checkpoint 0982 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0983: UI contract checkpoint 0983 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0984: UI contract checkpoint 0984 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0985: UI contract checkpoint 0985 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0986: UI contract checkpoint 0986 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0987: UI contract checkpoint 0987 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0988: UI contract checkpoint 0988 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0989: UI contract checkpoint 0989 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0990: UI contract checkpoint 0990 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0991: UI contract checkpoint 0991 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0992: UI contract checkpoint 0992 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0993: UI contract checkpoint 0993 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0994: UI contract checkpoint 0994 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0995: UI contract checkpoint 0995 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0996: UI contract checkpoint 0996 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0997: UI contract checkpoint 0997 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0998: UI contract checkpoint 0998 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 0999: UI contract checkpoint 0999 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1000: UI contract checkpoint 1000 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1001: UI contract checkpoint 1001 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1002: UI contract checkpoint 1002 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1003: UI contract checkpoint 1003 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1004: UI contract checkpoint 1004 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1005: UI contract checkpoint 1005 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1006: UI contract checkpoint 1006 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1007: UI contract checkpoint 1007 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1008: UI contract checkpoint 1008 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1009: UI contract checkpoint 1009 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1010: UI contract checkpoint 1010 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1011: UI contract checkpoint 1011 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1012: UI contract checkpoint 1012 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1013: UI contract checkpoint 1013 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1014: UI contract checkpoint 1014 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1015: UI contract checkpoint 1015 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1016: UI contract checkpoint 1016 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1017: UI contract checkpoint 1017 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1018: UI contract checkpoint 1018 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1019: UI contract checkpoint 1019 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1020: UI contract checkpoint 1020 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1021: UI contract checkpoint 1021 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1022: UI contract checkpoint 1022 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1023: UI contract checkpoint 1023 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1024: UI contract checkpoint 1024 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1025: UI contract checkpoint 1025 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1026: UI contract checkpoint 1026 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1027: UI contract checkpoint 1027 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1028: UI contract checkpoint 1028 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1029: UI contract checkpoint 1029 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1030: UI contract checkpoint 1030 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1031: UI contract checkpoint 1031 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1032: UI contract checkpoint 1032 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1033: UI contract checkpoint 1033 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1034: UI contract checkpoint 1034 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1035: UI contract checkpoint 1035 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1036: UI contract checkpoint 1036 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1037: UI contract checkpoint 1037 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1038: UI contract checkpoint 1038 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1039: UI contract checkpoint 1039 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1040: UI contract checkpoint 1040 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1041: UI contract checkpoint 1041 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1042: UI contract checkpoint 1042 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1043: UI contract checkpoint 1043 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1044: UI contract checkpoint 1044 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1045: UI contract checkpoint 1045 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1046: UI contract checkpoint 1046 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1047: UI contract checkpoint 1047 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1048: UI contract checkpoint 1048 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1049: UI contract checkpoint 1049 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1050: UI contract checkpoint 1050 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1051: UI contract checkpoint 1051 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1052: UI contract checkpoint 1052 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1053: UI contract checkpoint 1053 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1054: UI contract checkpoint 1054 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1055: UI contract checkpoint 1055 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1056: UI contract checkpoint 1056 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1057: UI contract checkpoint 1057 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1058: UI contract checkpoint 1058 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1059: UI contract checkpoint 1059 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1060: UI contract checkpoint 1060 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1061: UI contract checkpoint 1061 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1062: UI contract checkpoint 1062 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1063: UI contract checkpoint 1063 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1064: UI contract checkpoint 1064 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1065: UI contract checkpoint 1065 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1066: UI contract checkpoint 1066 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1067: UI contract checkpoint 1067 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1068: UI contract checkpoint 1068 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1069: UI contract checkpoint 1069 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1070: UI contract checkpoint 1070 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1071: UI contract checkpoint 1071 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1072: UI contract checkpoint 1072 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1073: UI contract checkpoint 1073 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1074: UI contract checkpoint 1074 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1075: UI contract checkpoint 1075 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1076: UI contract checkpoint 1076 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1077: UI contract checkpoint 1077 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1078: UI contract checkpoint 1078 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1079: UI contract checkpoint 1079 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1080: UI contract checkpoint 1080 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1081: UI contract checkpoint 1081 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1082: UI contract checkpoint 1082 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1083: UI contract checkpoint 1083 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1084: UI contract checkpoint 1084 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1085: UI contract checkpoint 1085 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1086: UI contract checkpoint 1086 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1087: UI contract checkpoint 1087 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1088: UI contract checkpoint 1088 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1089: UI contract checkpoint 1089 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1090: UI contract checkpoint 1090 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1091: UI contract checkpoint 1091 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1092: UI contract checkpoint 1092 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1093: UI contract checkpoint 1093 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1094: UI contract checkpoint 1094 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1095: UI contract checkpoint 1095 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1096: UI contract checkpoint 1096 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1097: UI contract checkpoint 1097 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1098: UI contract checkpoint 1098 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1099: UI contract checkpoint 1099 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1100: UI contract checkpoint 1100 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1101: UI contract checkpoint 1101 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1102: UI contract checkpoint 1102 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1103: UI contract checkpoint 1103 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1104: UI contract checkpoint 1104 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1105: UI contract checkpoint 1105 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1106: UI contract checkpoint 1106 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1107: UI contract checkpoint 1107 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1108: UI contract checkpoint 1108 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1109: UI contract checkpoint 1109 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1110: UI contract checkpoint 1110 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1111: UI contract checkpoint 1111 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1112: UI contract checkpoint 1112 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1113: UI contract checkpoint 1113 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1114: UI contract checkpoint 1114 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1115: UI contract checkpoint 1115 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1116: UI contract checkpoint 1116 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1117: UI contract checkpoint 1117 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1118: UI contract checkpoint 1118 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1119: UI contract checkpoint 1119 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1120: UI contract checkpoint 1120 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1121: UI contract checkpoint 1121 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1122: UI contract checkpoint 1122 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1123: UI contract checkpoint 1123 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1124: UI contract checkpoint 1124 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1125: UI contract checkpoint 1125 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1126: UI contract checkpoint 1126 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1127: UI contract checkpoint 1127 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1128: UI contract checkpoint 1128 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1129: UI contract checkpoint 1129 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1130: UI contract checkpoint 1130 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1131: UI contract checkpoint 1131 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1132: UI contract checkpoint 1132 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1133: UI contract checkpoint 1133 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1134: UI contract checkpoint 1134 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1135: UI contract checkpoint 1135 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1136: UI contract checkpoint 1136 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1137: UI contract checkpoint 1137 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1138: UI contract checkpoint 1138 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1139: UI contract checkpoint 1139 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1140: UI contract checkpoint 1140 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1141: UI contract checkpoint 1141 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1142: UI contract checkpoint 1142 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1143: UI contract checkpoint 1143 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1144: UI contract checkpoint 1144 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1145: UI contract checkpoint 1145 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1146: UI contract checkpoint 1146 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1147: UI contract checkpoint 1147 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1148: UI contract checkpoint 1148 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1149: UI contract checkpoint 1149 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1150: UI contract checkpoint 1150 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1151: UI contract checkpoint 1151 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1152: UI contract checkpoint 1152 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1153: UI contract checkpoint 1153 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1154: UI contract checkpoint 1154 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1155: UI contract checkpoint 1155 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1156: UI contract checkpoint 1156 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1157: UI contract checkpoint 1157 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1158: UI contract checkpoint 1158 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1159: UI contract checkpoint 1159 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1160: UI contract checkpoint 1160 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1161: UI contract checkpoint 1161 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1162: UI contract checkpoint 1162 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1163: UI contract checkpoint 1163 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1164: UI contract checkpoint 1164 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1165: UI contract checkpoint 1165 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1166: UI contract checkpoint 1166 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1167: UI contract checkpoint 1167 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1168: UI contract checkpoint 1168 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1169: UI contract checkpoint 1169 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1170: UI contract checkpoint 1170 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1171: UI contract checkpoint 1171 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1172: UI contract checkpoint 1172 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1173: UI contract checkpoint 1173 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1174: UI contract checkpoint 1174 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1175: UI contract checkpoint 1175 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1176: UI contract checkpoint 1176 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1177: UI contract checkpoint 1177 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1178: UI contract checkpoint 1178 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1179: UI contract checkpoint 1179 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1180: UI contract checkpoint 1180 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1181: UI contract checkpoint 1181 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1182: UI contract checkpoint 1182 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1183: UI contract checkpoint 1183 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1184: UI contract checkpoint 1184 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1185: UI contract checkpoint 1185 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1186: UI contract checkpoint 1186 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1187: UI contract checkpoint 1187 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1188: UI contract checkpoint 1188 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1189: UI contract checkpoint 1189 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1190: UI contract checkpoint 1190 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1191: UI contract checkpoint 1191 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1192: UI contract checkpoint 1192 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1193: UI contract checkpoint 1193 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1194: UI contract checkpoint 1194 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1195: UI contract checkpoint 1195 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1196: UI contract checkpoint 1196 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1197: UI contract checkpoint 1197 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1198: UI contract checkpoint 1198 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1199: UI contract checkpoint 1199 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1200: UI contract checkpoint 1200 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1201: UI contract checkpoint 1201 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1202: UI contract checkpoint 1202 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1203: UI contract checkpoint 1203 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1204: UI contract checkpoint 1204 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1205: UI contract checkpoint 1205 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1206: UI contract checkpoint 1206 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1207: UI contract checkpoint 1207 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1208: UI contract checkpoint 1208 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1209: UI contract checkpoint 1209 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1210: UI contract checkpoint 1210 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1211: UI contract checkpoint 1211 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1212: UI contract checkpoint 1212 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1213: UI contract checkpoint 1213 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1214: UI contract checkpoint 1214 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1215: UI contract checkpoint 1215 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1216: UI contract checkpoint 1216 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1217: UI contract checkpoint 1217 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1218: UI contract checkpoint 1218 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1219: UI contract checkpoint 1219 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1220: UI contract checkpoint 1220 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1221: UI contract checkpoint 1221 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1222: UI contract checkpoint 1222 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1223: UI contract checkpoint 1223 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1224: UI contract checkpoint 1224 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1225: UI contract checkpoint 1225 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1226: UI contract checkpoint 1226 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1227: UI contract checkpoint 1227 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1228: UI contract checkpoint 1228 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1229: UI contract checkpoint 1229 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1230: UI contract checkpoint 1230 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1231: UI contract checkpoint 1231 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1232: UI contract checkpoint 1232 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1233: UI contract checkpoint 1233 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1234: UI contract checkpoint 1234 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1235: UI contract checkpoint 1235 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1236: UI contract checkpoint 1236 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1237: UI contract checkpoint 1237 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1238: UI contract checkpoint 1238 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1239: UI contract checkpoint 1239 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1240: UI contract checkpoint 1240 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1241: UI contract checkpoint 1241 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1242: UI contract checkpoint 1242 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1243: UI contract checkpoint 1243 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1244: UI contract checkpoint 1244 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1245: UI contract checkpoint 1245 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1246: UI contract checkpoint 1246 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1247: UI contract checkpoint 1247 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1248: UI contract checkpoint 1248 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1249: UI contract checkpoint 1249 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1250: UI contract checkpoint 1250 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1251: UI contract checkpoint 1251 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1252: UI contract checkpoint 1252 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1253: UI contract checkpoint 1253 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1254: UI contract checkpoint 1254 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1255: UI contract checkpoint 1255 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1256: UI contract checkpoint 1256 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1257: UI contract checkpoint 1257 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1258: UI contract checkpoint 1258 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1259: UI contract checkpoint 1259 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1260: UI contract checkpoint 1260 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1261: UI contract checkpoint 1261 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1262: UI contract checkpoint 1262 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1263: UI contract checkpoint 1263 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1264: UI contract checkpoint 1264 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1265: UI contract checkpoint 1265 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1266: UI contract checkpoint 1266 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1267: UI contract checkpoint 1267 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1268: UI contract checkpoint 1268 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1269: UI contract checkpoint 1269 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1270: UI contract checkpoint 1270 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1271: UI contract checkpoint 1271 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1272: UI contract checkpoint 1272 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1273: UI contract checkpoint 1273 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1274: UI contract checkpoint 1274 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1275: UI contract checkpoint 1275 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1276: UI contract checkpoint 1276 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1277: UI contract checkpoint 1277 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1278: UI contract checkpoint 1278 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1279: UI contract checkpoint 1279 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1280: UI contract checkpoint 1280 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1281: UI contract checkpoint 1281 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1282: UI contract checkpoint 1282 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1283: UI contract checkpoint 1283 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1284: UI contract checkpoint 1284 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1285: UI contract checkpoint 1285 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1286: UI contract checkpoint 1286 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1287: UI contract checkpoint 1287 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1288: UI contract checkpoint 1288 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1289: UI contract checkpoint 1289 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1290: UI contract checkpoint 1290 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1291: UI contract checkpoint 1291 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1292: UI contract checkpoint 1292 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1293: UI contract checkpoint 1293 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1294: UI contract checkpoint 1294 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1295: UI contract checkpoint 1295 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1296: UI contract checkpoint 1296 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1297: UI contract checkpoint 1297 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1298: UI contract checkpoint 1298 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1299: UI contract checkpoint 1299 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1300: UI contract checkpoint 1300 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1301: UI contract checkpoint 1301 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1302: UI contract checkpoint 1302 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1303: UI contract checkpoint 1303 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1304: UI contract checkpoint 1304 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1305: UI contract checkpoint 1305 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1306: UI contract checkpoint 1306 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1307: UI contract checkpoint 1307 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1308: UI contract checkpoint 1308 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1309: UI contract checkpoint 1309 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1310: UI contract checkpoint 1310 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1311: UI contract checkpoint 1311 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1312: UI contract checkpoint 1312 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1313: UI contract checkpoint 1313 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1314: UI contract checkpoint 1314 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1315: UI contract checkpoint 1315 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1316: UI contract checkpoint 1316 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1317: UI contract checkpoint 1317 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1318: UI contract checkpoint 1318 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1319: UI contract checkpoint 1319 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1320: UI contract checkpoint 1320 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1321: UI contract checkpoint 1321 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1322: UI contract checkpoint 1322 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1323: UI contract checkpoint 1323 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1324: UI contract checkpoint 1324 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1325: UI contract checkpoint 1325 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1326: UI contract checkpoint 1326 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1327: UI contract checkpoint 1327 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1328: UI contract checkpoint 1328 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1329: UI contract checkpoint 1329 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1330: UI contract checkpoint 1330 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1331: UI contract checkpoint 1331 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1332: UI contract checkpoint 1332 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1333: UI contract checkpoint 1333 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1334: UI contract checkpoint 1334 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1335: UI contract checkpoint 1335 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1336: UI contract checkpoint 1336 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1337: UI contract checkpoint 1337 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1338: UI contract checkpoint 1338 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1339: UI contract checkpoint 1339 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1340: UI contract checkpoint 1340 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1341: UI contract checkpoint 1341 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1342: UI contract checkpoint 1342 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1343: UI contract checkpoint 1343 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1344: UI contract checkpoint 1344 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1345: UI contract checkpoint 1345 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1346: UI contract checkpoint 1346 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1347: UI contract checkpoint 1347 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1348: UI contract checkpoint 1348 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1349: UI contract checkpoint 1349 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1350: UI contract checkpoint 1350 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1351: UI contract checkpoint 1351 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1352: UI contract checkpoint 1352 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1353: UI contract checkpoint 1353 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1354: UI contract checkpoint 1354 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1355: UI contract checkpoint 1355 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1356: UI contract checkpoint 1356 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1357: UI contract checkpoint 1357 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1358: UI contract checkpoint 1358 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1359: UI contract checkpoint 1359 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1360: UI contract checkpoint 1360 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1361: UI contract checkpoint 1361 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1362: UI contract checkpoint 1362 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1363: UI contract checkpoint 1363 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1364: UI contract checkpoint 1364 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1365: UI contract checkpoint 1365 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1366: UI contract checkpoint 1366 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1367: UI contract checkpoint 1367 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1368: UI contract checkpoint 1368 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1369: UI contract checkpoint 1369 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1370: UI contract checkpoint 1370 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1371: UI contract checkpoint 1371 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1372: UI contract checkpoint 1372 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1373: UI contract checkpoint 1373 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1374: UI contract checkpoint 1374 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1375: UI contract checkpoint 1375 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1376: UI contract checkpoint 1376 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1377: UI contract checkpoint 1377 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1378: UI contract checkpoint 1378 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1379: UI contract checkpoint 1379 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1380: UI contract checkpoint 1380 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1381: UI contract checkpoint 1381 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1382: UI contract checkpoint 1382 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1383: UI contract checkpoint 1383 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1384: UI contract checkpoint 1384 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1385: UI contract checkpoint 1385 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1386: UI contract checkpoint 1386 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1387: UI contract checkpoint 1387 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1388: UI contract checkpoint 1388 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1389: UI contract checkpoint 1389 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1390: UI contract checkpoint 1390 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1391: UI contract checkpoint 1391 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1392: UI contract checkpoint 1392 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1393: UI contract checkpoint 1393 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1394: UI contract checkpoint 1394 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1395: UI contract checkpoint 1395 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1396: UI contract checkpoint 1396 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1397: UI contract checkpoint 1397 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1398: UI contract checkpoint 1398 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1399: UI contract checkpoint 1399 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1400: UI contract checkpoint 1400 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1401: UI contract checkpoint 1401 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1402: UI contract checkpoint 1402 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1403: UI contract checkpoint 1403 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1404: UI contract checkpoint 1404 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1405: UI contract checkpoint 1405 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1406: UI contract checkpoint 1406 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1407: UI contract checkpoint 1407 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1408: UI contract checkpoint 1408 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1409: UI contract checkpoint 1409 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1410: UI contract checkpoint 1410 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1411: UI contract checkpoint 1411 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1412: UI contract checkpoint 1412 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1413: UI contract checkpoint 1413 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1414: UI contract checkpoint 1414 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1415: UI contract checkpoint 1415 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1416: UI contract checkpoint 1416 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1417: UI contract checkpoint 1417 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1418: UI contract checkpoint 1418 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1419: UI contract checkpoint 1419 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1420: UI contract checkpoint 1420 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1421: UI contract checkpoint 1421 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1422: UI contract checkpoint 1422 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1423: UI contract checkpoint 1423 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1424: UI contract checkpoint 1424 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1425: UI contract checkpoint 1425 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1426: UI contract checkpoint 1426 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1427: UI contract checkpoint 1427 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1428: UI contract checkpoint 1428 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1429: UI contract checkpoint 1429 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1430: UI contract checkpoint 1430 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1431: UI contract checkpoint 1431 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1432: UI contract checkpoint 1432 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1433: UI contract checkpoint 1433 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1434: UI contract checkpoint 1434 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1435: UI contract checkpoint 1435 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1436: UI contract checkpoint 1436 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1437: UI contract checkpoint 1437 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1438: UI contract checkpoint 1438 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1439: UI contract checkpoint 1439 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1440: UI contract checkpoint 1440 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1441: UI contract checkpoint 1441 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1442: UI contract checkpoint 1442 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1443: UI contract checkpoint 1443 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1444: UI contract checkpoint 1444 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1445: UI contract checkpoint 1445 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1446: UI contract checkpoint 1446 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1447: UI contract checkpoint 1447 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1448: UI contract checkpoint 1448 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1449: UI contract checkpoint 1449 remains comments-only and runtime-neutral.
-- APHELION FEATURE MATRIX 1450: UI contract checkpoint 1450 remains comments-only and runtime-neutral.
