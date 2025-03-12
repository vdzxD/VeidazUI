--[[
    VeiPlates.lua - Custom Nameplate Module for WoW Cataclysm Classic
    
    Key Features:
    - GUID-based tracking to prevent nameplate element mismatches
    - Performance optimizations using caching and throttling
    - Efficient event management
    - Smooth visual transitions with delayed updates
    - Separate handling for static vs. dynamic data
    - Unit data caching to prevent redundant updates
]]

local addonName, core = ...
local VeiPlates = {}
core.VeiPlates = VeiPlates

-- =======================================
-- LOCAL VARIABLE CACHING (PERFORMANCE OPTIMIZATION)
-- =======================================
-- Cache frequently used functions to reduce global lookups
local _G = _G
local select = select
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local type = type
local floor = math.floor
local min = math.min
local max = math.max
local format = string.format
local find = string.find
local match = string.match
local gsub = string.gsub
local wipe = table.wipe or wipe -- Handle Classic vs Retail difference

-- Cache frequently used WoW API functions
local UnitExists = UnitExists
local UnitName = UnitName
local UnitClass = UnitClass
local UnitLevel = UnitLevel
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitIsUnit = UnitIsUnit
local UnitIsPlayer = UnitIsPlayer
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitCanAttack = UnitCanAttack
local UnitIsTapDenied = UnitIsTapDenied
local UnitGUID = UnitGUID
local GetSpellInfo = GetSpellInfo
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetTime = GetTime
local CreateFrame = CreateFrame
local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

-- =======================================
-- DATA STRUCTURES AND CONSTANTS
-- =======================================
-- Tables for tracking and caching nameplates
local Plates = {}                -- All created nameplates
local PlatesVisible = {}         -- Currently visible nameplates
local PlatesByUnit = {}          -- Nameplates indexed by unitID
local PlatesByGUID = {}          -- Nameplates indexed by GUID
local CastDataByGUID = {}        -- Cast information indexed by GUID
local UnitCache = {}             -- Cache of unit data to prevent redundant updates

-- Constants
local PLATE_UPDATE_INTERVAL = 0.05  -- Throttle update frequency (50ms)
local FADE_DURATION = 0.3           -- Duration for smooth transitions
local MAX_CASTBAR_TIMEOUT = 30      -- Maximum cast duration before auto-cleanup

-- Visual constants
local PLATE_WIDTH = 110
local PLATE_HEIGHT = 11
local CASTBAR_HEIGHT = 11
local TEXT_SIZE = 12
local ICON_SIZE = 20
local CASTBAR_WIDTH = PLATE_WIDTH -- Default to same as plate width
local CASTBAR_HEIGHT = 20 -- Default height
local CASTBAR_ICON_SIZE = 20 -- Default icon size
local CASTBAR_TEXT_SIZE = 10 -- Default text size
local CASTBAR_X_OFFSET = 0 --cast bar
local CASTBAR_Y_OFFSET = -3.5  -- cast bar

-- Friendly nameplate dimensions
local FRIENDLY_PLATE_WIDTH = 35  -- Default width for friendly nameplates
local FRIENDLY_PLATE_HEIGHT = 35   -- Default height for friendly nameplates

-- Name text position offsets (new)
local NAME_TEXT_XOFFSET = 0
local NAME_TEXT_YOFFSET = -25
local NAME_TEXT_ANCHOR = "BOTTOM"  -- Possible values: TOP, BOTTOM, CENTER, LEFT, RIGHT

-- =======================================
-- UTILITIES AND HELPERS
-- =======================================
-- Parse GUID to extract unit information
local function ParseGUID(guid)
    if not guid then return nil, nil, nil end
    local unitType, _, _, _, _, unitID = strsplit("-", guid)
    return unitType, tonumber(unitID), guid
end

-- Create a throttled function executor (performance optimization)
local Throttle = {}
local function ThrottleFunction(key, func, interval)
    interval = interval or PLATE_UPDATE_INTERVAL
    
    if Throttle[key] then return end
    
    Throttle[key] = true
    C_Timer.After(interval, function()
        if func then func() end
        Throttle[key] = nil
    end)
end

-- Safe lookup for VeiUI colors and styles
local function GetVeiColor(colorName)
    if core.VeiUI and core.VeiUI.Color and core.VeiUI.Color[colorName] then
        return core.VeiUI.Color[colorName]
    end
    -- Default colors if VeiUI not available
    local defaults = {
        health = {r = 0.1, g = 1, b = 0.1},
        casting = {r = 1, g = 0.7, b = 0},
        interrupted = {r = 1, g = 0.3, b = 0.2},
        background = {r = 0.1, g = 0.1, b = 0.1},
        border = {r = 0, g = 0, b = 0},
        text = {r = 1, g = 1, b = 1}
    }
    return defaults[colorName] or defaults.text
end

function VeiPlates:SetNamePosition(xOffset, yOffset, anchor)
    anchor = anchor or "BOTTOM" -- Default anchor point
    
    for _, plate in pairs(Plates) do
        if plate.name then
            plate.name:ClearAllPoints()
            plate.name:SetPoint(anchor, plate.health, "TOP", xOffset, yOffset)
        end
    end
end

function VeiPlates:SetFriendlyPlateSize(width, height)
    FRIENDLY_PLATE_WIDTH = width or FRIENDLY_PLATE_WIDTH
    FRIENDLY_PLATE_HEIGHT = height or FRIENDLY_PLATE_HEIGHT
    
    -- Update existing friendly nameplates
    for unitID, plate in pairs(PlatesByUnit) do
        if UnitExists(unitID) and not UnitCanAttack("player", unitID) then
            if plate.health then
                plate.health:SetSize(FRIENDLY_PLATE_WIDTH, FRIENDLY_PLATE_HEIGHT)
            end
            
            -- Update related elements
            if plate.secureButton then
                plate.secureButton:SetSize(FRIENDLY_PLATE_WIDTH + 10, FRIENDLY_PLATE_HEIGHT + 10)
            end
            
            -- Reposition cast bar if it exists
            if plate.castBar then
                plate.castBar:SetWidth(FRIENDLY_PLATE_WIDTH)
                plate.castBar:SetPoint("TOP", plate.health, "BOTTOM", CASTBAR_X_OFFSET, CASTBAR_Y_OFFSET)
            end
        end
    end
end



-- Set size of the cast bar
function VeiPlates:SetCastBarSize(width, height)
    CASTBAR_WIDTH = width or PLATE_WIDTH -- Default to plate width if not specified
    CASTBAR_HEIGHT = height or CASTBAR_HEIGHT
    
    for _, plate in pairs(Plates) do
        if plate.castBar then
            plate.castBar:SetSize(CASTBAR_WIDTH, CASTBAR_HEIGHT)
        end
    end
    print("Cast bar size set to: " .. CASTBAR_WIDTH .. "x" .. CASTBAR_HEIGHT)
end

-- Set position of the cast bar relative to the health bar
function VeiPlates:SetCastBarPosition(x, y)
    for _, plate in pairs(Plates) do
        if plate.castBar then
            plate.castBar:ClearAllPoints()
            plate.castBar:SetPoint("CENTER", plate.health, "CENTER", x, y)
        end
    end
    print("Cast bar position set to x: " .. x .. ", y: " .. y)
end

-- Set size of the cast bar icon
function VeiPlates:SetCastBarIconSize(size)
    CASTBAR_ICON_SIZE = size or ICON_SIZE
    
    for _, plate in pairs(Plates) do
        if plate.castBar and plate.castBar.icon then
            plate.castBar.icon:SetSize(CASTBAR_ICON_SIZE, CASTBAR_ICON_SIZE)
        end
    end
    print("Cast bar icon size set to: " .. CASTBAR_ICON_SIZE)
end

-- Set position of the cast bar icon relative to the cast bar
function VeiPlates:SetCastBarIconPosition(anchor, x, y)
    anchor = anchor or "RIGHT" -- Default anchor point
    
    for _, plate in pairs(Plates) do
        if plate.castBar and plate.castBar.icon then
            plate.castBar.icon:ClearAllPoints()
            plate.castBar.icon:SetPoint(anchor, plate.castBar, anchor == "RIGHT" and "LEFT" or "RIGHT", x, y)
        end
    end
    print("Cast bar icon position set to anchor: " .. anchor .. ", x: " .. x .. ", y: " .. y)
end


-- Set font size of the cast bar text
function VeiPlates:SetCastBarTextSize(size)
    CASTBAR_TEXT_SIZE = size or TEXT_SIZE
    
    for _, plate in pairs(Plates) do
        if plate.castBar and plate.castBar.text then
            plate.castBar.text:SetFont("Fonts\\FRIZQT__.TTF", CASTBAR_TEXT_SIZE, "OUTLINE")
        end
    end
    print("Cast bar text size set to: " .. CASTBAR_TEXT_SIZE)
end

-- Set position of the cast bar text relative to the cast bar
function VeiPlates:SetCastBarTextPosition(anchor, x, y)
    anchor = anchor or "CENTER" -- Default anchor point
    
    for _, plate in pairs(Plates) do
        if plate.castBar and plate.castBar.text then
            plate.castBar.text:ClearAllPoints()
            plate.castBar.text:SetPoint(anchor, plate.castBar, anchor, x, y)
        end
    end
    print("Cast bar text position set to anchor: " .. anchor .. ", x: " .. x .. ", y: " .. y)
end

-- Adjust the cast bar background to solid black
function VeiPlates:SetCastBarBackground(makeSolidBlack)
    for _, plate in pairs(Plates) do
        if plate.castBar and plate.castBar.backdrop then
            if makeSolidBlack then
                -- Make the backdrop completely black and non-transparent
                plate.castBar.backdrop:SetTexture("Interface\\Buttons\\WHITE8X8") -- Use a solid texture
                plate.castBar.backdrop:SetVertexColor(0, 0, 0, 1.0) -- Pure black, fully opaque
            else
                -- Reset to default appearance
                plate.castBar.backdrop:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
                plate.castBar.backdrop:SetVertexColor(0.1, 0.1, 0.1, 0.8) -- Original semi-transparent dark gray
            end
        end
    end
    
  --  print("Cast bar background " .. (makeSolidBlack and "set to solid black" or "reset to default"))
end

VeiPlates:SetCastBarBackground(true)




function VeiPlates:SetHealthBarDimensions(width, height)
    for _, plate in pairs(Plates) do
        if plate.health then
            plate.health:SetSize(width, height)
            
            -- If you have a secure button, adjust its size accordingly
            if plate.secureButton then
                plate.secureButton:SetSize(width + 10, height + 10) -- Slightly larger for easier clicking
            end
            
            -- If you have a castbar that is positioned relative to health, update it
            if plate.castBar then
                plate.castBar:SetWidth(width)
                plate.castBar:SetPoint("TOP", plate.health, "BOTTOM", CASTBAR_X_OFFSET, CASTBAR_Y_OFFSET)
            end
        end
    end
end

-- Fade function for smooth transitions
local function FadeFrame(frame, startAlpha, endAlpha, duration, onFinish)
    if not frame then return end
    
    frame:SetAlpha(startAlpha)
    frame.fadeInfo = {
        startAlpha = startAlpha,
        endAlpha = endAlpha,
        duration = duration or FADE_DURATION,
        elapsed = 0,
        onFinish = onFinish
    }
    
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.fadeInfo.elapsed = self.fadeInfo.elapsed + elapsed
        local progress = min(self.fadeInfo.elapsed / self.fadeInfo.duration, 1)
        local currentAlpha = self.fadeInfo.startAlpha + (self.fadeInfo.endAlpha - self.fadeInfo.startAlpha) * progress
        
        self:SetAlpha(currentAlpha)
        
        if progress >= 1 then
            self:SetScript("OnUpdate", nil)
            if self.fadeInfo.onFinish then
                self.fadeInfo.onFinish(self)
            end
            self.fadeInfo = nil
        end
    end)
end

-- =======================================
-- NAMEPLATE CORE CREATION
-- =======================================
-- Create the main frame for handling events
local VeiPlatesCore = CreateFrame("Frame", "VeiPlatesCore", WorldFrame)

-- Initialize the nameplate system
function VeiPlates:Initialize()
    -- Register for relevant events
    VeiPlatesCore:RegisterEvent("NAME_PLATE_CREATED")
    VeiPlatesCore:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    VeiPlatesCore:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    VeiPlatesCore:RegisterEvent("UNIT_HEALTH")
    VeiPlatesCore:RegisterEvent("UNIT_MAXHEALTH")
    VeiPlatesCore:RegisterEvent("UNIT_LEVEL")
    VeiPlatesCore:RegisterEvent("UNIT_NAME_UPDATE")
    VeiPlatesCore:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_START")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_STOP")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_FAILED")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    VeiPlatesCore:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    VeiPlatesCore:RegisterEvent("PLAYER_ENTERING_WORLD")
    VeiPlatesCore:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    -- Set up the event handler
    VeiPlatesCore:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
    
    -- Create methods for events
    function VeiPlatesCore:NAME_PLATE_CREATED(namePlate)
        self:CreatePlate(namePlate)
    end
    
    function VeiPlatesCore:NAME_PLATE_UNIT_ADDED(unitID)
        self:AttachPlateToUnit(unitID)
    end
    
    function VeiPlatesCore:NAME_PLATE_UNIT_REMOVED(unitID)
        self:DetachPlateFromUnit(unitID)
    end
    
    function VeiPlatesCore:UNIT_HEALTH(unitID)
        self:UpdateUnitDynamic(unitID)
    end
    
    function VeiPlatesCore:UNIT_MAXHEALTH(unitID)
        self:UpdateUnitDynamic(unitID)
    end
    
    function VeiPlatesCore:UNIT_LEVEL(unitID)
        self:UpdateUnitIdentity(unitID)
    end
    
    function VeiPlatesCore:UNIT_NAME_UPDATE(unitID)
        self:UpdateUnitIdentity(unitID)
    end
    
    function VeiPlatesCore:UNIT_CLASSIFICATION_CHANGED(unitID)
        self:UpdateUnitIdentity(unitID)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_START(unitID, castGUID, spellID)
        self:StartCast(unitID, spellID, false)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_STOP(unitID, castGUID, spellID)
        self:StopCast(unitID, spellID)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_FAILED(unitID, castGUID, spellID)
        self:InterruptCast(unitID, spellID)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_INTERRUPTED(unitID, castGUID, spellID)
        self:InterruptCast(unitID, spellID)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_DELAYED(unitID, castGUID, spellID)
        self:UpdateCastDelay(unitID, spellID)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_CHANNEL_START(unitID, castGUID, spellID)
        self:StartCast(unitID, spellID, true)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_CHANNEL_STOP(unitID, castGUID, spellID)
        self:StopCast(unitID, spellID)
    end
    
    function VeiPlatesCore:UNIT_SPELLCAST_CHANNEL_UPDATE(unitID, castGUID, spellID)
        self:UpdateChannelDelay(unitID, spellID)
    end

    -- Set up the update ticker for highlights
    C_Timer.NewTicker(0.1, function()
        VeiPlates:UpdateHighlights()
    end)

    function VeiPlatesCore:PLAYER_TARGET_CHANGED()
        -- Clear all target highlights first
        for _, plate in pairs(Plates) do
            plate.isTarget = false
            if plate.highlight and plate.highlight:IsShown() and not plate.isMouseOver then
                plate.highlight:Hide()
            end
        end
        
        -- Highlight new target
        if UnitExists("target") then
            local targetGUID = UnitGUID("target")
            local targetPlate = PlatesByGUID[targetGUID]
            
            if targetPlate then
                targetPlate.isTarget = true
                if targetPlate.highlight then
                    targetPlate.highlight:SetVertexColor(1, 0.8, 0, 0.4) -- Golden highlight
                    targetPlate.highlight:Show()
                end
            end
        end
    end
    
    
    function VeiPlatesCore:PLAYER_ENTERING_WORLD()
        -- Clear all stored data when changing zones or logging in
        -- This helps prevent stale data from persisting
        for guid, _ in pairs(CastDataByGUID) do
            CastDataByGUID[guid] = nil
        end
        
        -- Remove all nameplate references
        for unitID, _ in pairs(PlatesByUnit) do
            PlatesByUnit[unitID] = nil
        end
        
        for guid, _ in pairs(PlatesByGUID) do
            PlatesByGUID[guid] = nil
        end
        
        wipe(PlatesVisible)
        wipe(UnitCache)
    end

    function VeiPlatesCore:MakeHealthBarClickable(plate)
        if not plate or not plate.health then return end
        
        -- IMPORTANT: Make sure the health bar doesn't capture mouse events
        -- This allows clicks to pass through to the parent plate frame
        plate.health:EnableMouse(false)
        
        -- Make all other elements non-interactive as well
        if plate.backdrop and plate.backdrop.EnableMouse then 
            plate.backdrop:EnableMouse(false) 
        end
        
        -- Make sure the main plate frame is mouse-enabled for interaction
        plate:EnableMouse(true)
        plate:SetMouseClickEnabled(true)
        plate:SetMouseMotionEnabled(true)
        
        -- Set better click handling on the plate itself
        plate:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and self.unitID and UnitExists(self.unitID) then
                TargetUnit(self.unitID)
            end
        end)
        
        -- Store the original mouse handlers
        plate.isMouseOver = false
        
        -- Setup mouse tracking
        plate:SetScript("OnEnter", function(self)
            self.isMouseOver = true
            if self.highlight then
                self.highlight:SetVertexColor(1, 1, 1, 0.3) -- White for mouseover
                self.highlight:Show()
            end
            -- Set the GameTooltip
            if self.unitID and UnitExists(self.unitID) then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetUnit(self.unitID)
                GameTooltip:Show()
            end
        end)
        
        plate:SetScript("OnLeave", function(self)
            self.isMouseOver = false
            -- Only hide if not the current target
            if self.unitID and not UnitIsUnit(self.unitID, "target") and not self.isTarget then
                if self.highlight then
                    self.highlight:Hide()
                end
            end
            GameTooltip:Hide()
        end)
    end
    


    
    -- Set some CVars to help with nameplate visibility
    SetCVar("nameplateShowAll", 1)  -- Make sure nameplates are enabled
    SetCVar("nameplateShowDebuffs", 0)  -- Disable default debuffs
    SetCVar("nameplateShowBuffs", 0)  -- Disable default buffs

    -- Register slash command for controlling plates
    SLASH_VEIPLATES1 = "/veiplates"
    SlashCmdList["VEIPLATES"] = function(msg)
        if msg == "reset" then
            VeiPlates:ResetPlates()
        elseif msg == "debug" then
            VeiPlates:DebugHighlightPlates()
        elseif msg == "show" then
            VeiPlates:TogglePlates(true)
        elseif msg == "hide" then
            VeiPlates:TogglePlates(false)
        elseif msg == "cache" then
            VeiPlates:PrintCacheStats()
        else
            print("VeiPlates commands:")
            print("  /veiplates reset - Reset all nameplates")
            print("  /veiplates debug - Highlight all active nameplates")
            print("  /veiplates show - Show all nameplates")
            print("  /veiplates hide - Hide all nameplates")
            print("  /veiplates cache - Show cache statistics")
        end
    end

    SLASH_TESTPLATES1 = "/testplates"
    SlashCmdList["TESTPLATES"] = function()
        VeiPlates:TestNameplateClicking()
    end

        -- Add a slash command for testing clickability
    SLASH_VEITEST1 = "/veitest"
    SlashCmdList["VEITEST"] = function(msg)
        VeiPlates:TestClickability()
    end

    -- Delayed initialization to ensure everything is ready
    C_Timer.After(0.5, function() 
        VeiPlates:ResetPlates() -- Ensure full initialization after UI is ready
    end)
    
    -- Run a periodic check to hide any visible Blizzard nameplates
    C_Timer.NewTicker(0.5, function()
        for i = 1, 40 do
            local unitID = "nameplate" .. i
            if UnitExists(unitID) then
                local blizzardPlate = C_NamePlate.GetNamePlateForUnit(unitID)
                if blizzardPlate then
                    for _, region in pairs({blizzardPlate:GetRegions()}) do
                        region:SetAlpha(0)
                    end
                end
            end
        end
    end)

   -- print("VeiPlates initialized with Blizzard nameplate hiding. Use /veiplates for commands.")
end




function VeiPlatesCore:SetMouseHandlers(plate)
    if not plate then return end
    
    -- Make sure the plate itself doesn't respond to mouse
    plate:EnableMouse(false)
    
    -- Ensure secure button is properly set up for clicking and highlighting
    if plate.secureButton then
        -- Make sure the secure button captures mouse events
        plate.secureButton:EnableMouse(true)
        plate.secureButton:SetMouseMotionEnabled(true)
        
        -- Handle mouseover highlighting through the secure button
        plate.secureButton:HookScript("OnEnter", function(self)
            -- Set the mouseover state on the associated plate
            plate.isMouseOver = true
            
            -- Show highlight with correct color
            if plate.highlight then
                if not plate.isTarget then
                    plate.highlight:SetVertexColor(1, 1, 1, 0.3)
                end
                plate.highlight:Show()
            end
            
            -- Show tooltip
            if plate.unitID and UnitExists(plate.unitID) then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetUnit(plate.unitID)
                GameTooltip:Show()
            end
        end)
        
        plate.secureButton:HookScript("OnLeave", function(self)
            -- Set the mouseover state on the associated plate
            plate.isMouseOver = false
            
            -- Hide highlight if not target
            if not plate.isTarget and plate.highlight then
                plate.highlight:Hide()
            elseif plate.isTarget and plate.highlight then
                -- Restore target color
                plate.highlight:SetVertexColor(1, 0.8, 0, 0.4)
            end
            
            GameTooltip:Hide()
        end)
    end
end
-- =======================================
-- NAMEPLATE CREATION AND MANAGEMENT
-- =======================================
-- Create a nameplate and its visual elements
-- Create a nameplate and its visual elements
function VeiPlatesCore:CreatePlate(namePlate)
    if not namePlate then return end
    if Plates[namePlate] then return Plates[namePlate] end
    
    -- Create unique ID for this nameplate
    local plateID = tostring(namePlate:GetName() or "Unnamed") .. "_" .. math.random(1000000)
    
    -- Create our custom plate, directly attached to WorldFrame for stability
    local plate = CreateFrame("Frame", "VeiPlate_" .. plateID, UIParent)
    plate:SetFrameStrata("BACKGROUND") -- Lower strata so it doesn't interfere with clicking
    plate:SetFrameLevel(5)
    -- Size will be set in AttachPlateToUnit when we know if it's friendly or not
    
    -- Store reference to the Blizzard nameplate
    plate.blizzardPlate = namePlate
    plate.plateID = plateID
    
    -- Create the health bar
    plate.health = CreateFrame("StatusBar", nil, plate)
    plate.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8") -- Solid texture
    -- Size will be set in AttachPlateToUnit
    plate.health:SetPoint("CENTER", plate, "CENTER", 0, 0)
    
    -- Create simple backdrop for health bar with the same solid texture
    plate.backdrop = plate.health:CreateTexture(nil, "BACKGROUND")
    plate.backdrop:SetTexture("Interface\\Buttons\\WHITE8X8") -- Solid texture
    plate.backdrop:SetAllPoints(plate.health)
    plate.backdrop:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Create highlight effect
    plate.highlight = plate.health:CreateTexture(nil, "OVERLAY")
    plate.highlight:SetAllPoints()
    plate.highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    plate.highlight:SetBlendMode("ADD")
    plate.highlight:SetVertexColor(1, 1, 1, 0.3)
    plate.highlight:Hide()
    
    -- Create a separate frame for TEXT elements
    -- Important: Create textFrame BEFORE castBar
    plate.textFrame = CreateFrame("Frame", nil, plate)
    plate.textFrame:SetAllPoints(plate)
    plate.textFrame:SetFrameLevel(plate:GetFrameLevel() + 1)
    
    -- Name text
    plate.name = plate.textFrame:CreateFontString(nil, "OVERLAY")
    plate.name:SetFont("Fonts\\FRIZQT__.TTF", TEXT_SIZE, "OUTLINE")
    plate.name:SetPoint(NAME_TEXT_ANCHOR, plate.health, "TOP", NAME_TEXT_XOFFSET, NAME_TEXT_YOFFSET)
    plate.name:SetText("")
    
    -- Level text
    plate.level = plate.textFrame:CreateFontString(nil, "OVERLAY")
    plate.level:SetFont("Fonts\\FRIZQT__.TTF", TEXT_SIZE - 2, "OUTLINE")
    plate.level:SetPoint("RIGHT", plate.health, "LEFT", -2, 0)
    plate.level:SetText("")
    plate.level:Hide() -- Hide it immediately
    
    -- Create the cast bar
    plate.castBar = CreateFrame("StatusBar", nil, plate)
    plate.castBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    plate.castBar:SetSize(PLATE_WIDTH, CASTBAR_HEIGHT) -- Default size initially
    plate.castBar:SetPoint("TOP", plate.health, "BOTTOM", CASTBAR_X_OFFSET, CASTBAR_Y_OFFSET)
    plate.castBar:Hide()
        
    -- Set higher frame level to ensure it appears above name text
    plate.castBar:SetFrameLevel(plate.textFrame:GetFrameLevel() + 5)
    plate.castBar:Hide()
    
    -- Cast bar backdrop
    plate.castBar.backdrop = plate.castBar:CreateTexture(nil, "BACKGROUND")
    plate.castBar.backdrop:SetTexture("Interface\\Buttons\\WHITE8X8") -- Solid texture
    plate.castBar.backdrop:SetAllPoints(plate.castBar)
    plate.castBar.backdrop:SetVertexColor(0, 0, 0, 1.0) -- Pure black, fully opaque
    
    -- Cast bar icon
    plate.castBar.icon = plate.castBar:CreateTexture(nil, "OVERLAY")
    plate.castBar.icon:SetSize(ICON_SIZE, ICON_SIZE)
    plate.castBar.icon:SetPoint("RIGHT", plate.castBar, "LEFT", -2, 0)
    plate.castBar.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Trim icon edges
    
    -- Cast bar text
    plate.castBar.text = plate.castBar:CreateFontString(nil, "OVERLAY")
    plate.castBar.text:SetFont("Fonts\\FRIZQT__.TTF", TEXT_SIZE, "OUTLINE")
    plate.castBar.text:SetPoint("CENTER", plate.castBar, "CENTER", 0, 0)
    
    -- Set initial health bar color
    plate.health:SetStatusBarColor(0.2, 0.8, 0.2)
    
    -- Create the secure button but allow it to capture both clicks and mouse movement
    plate.secureButton = CreateFrame("Button", "VeiPlateSecure_" .. plateID, UIParent, "SecureUnitButtonTemplate")
    plate.secureButton:SetFrameStrata("HIGH")
    plate.secureButton:SetFrameLevel(100)
    -- Size will be set in AttachPlateToUnit
    
    -- Enable mouse motion events on the secure button (default behavior)
    plate.secureButton:SetMouseMotionEnabled(true)
    
    -- Set up the secure attributes for targeting and menu
    plate.secureButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    plate.secureButton:SetAttribute("type1", "target")
    plate.secureButton:SetAttribute("type2", "togglemenu")
    
    -- Here's the key change - add OnEnter/OnLeave to the secure button that updates the plate
    plate.secureButton:HookScript("OnEnter", function(self)
        -- Set the mouseover state on the associated plate
        if plate then
            plate.isMouseOver = true
            
            -- Show highlight with correct color
            if plate.highlight then
                if not plate.isTarget then
                    plate.highlight:SetVertexColor(1, 1, 1, 0.3)
                end
                plate.highlight:Show()
            end
            
            -- Show tooltip
            if plate.unitID and UnitExists(plate.unitID) then
                GameTooltip:SetOwner(plate, "ANCHOR_BOTTOMRIGHT")
                GameTooltip:SetUnit(plate.unitID)
                GameTooltip:Show()
            end
        end
    end)
    
    plate.secureButton:HookScript("OnLeave", function(self)
        -- Set the mouseover state on the associated plate
        if plate then
            plate.isMouseOver = false
            
            -- Hide highlight if not target
            if not plate.isTarget and plate.highlight then
                plate.highlight:Hide()
            elseif plate.isTarget and plate.highlight then
                -- Restore target color
                plate.highlight:SetVertexColor(1, 0.8, 0, 0.4)
            end
            
            GameTooltip:Hide()
        end
    end)
    
    -- IMPORTANT: Disable mouse on the regular plate
    -- This allows the secure button to handle all mouse interaction
    plate:EnableMouse(false)
    
    -- Add debug border (comment out for production)
    local debugBorder = plate.secureButton:CreateTexture(nil, "OVERLAY")
    debugBorder:SetAllPoints()
    debugBorder:SetColorTexture(1, 0, 0, 0.3)
    debugBorder:Hide()
    plate.secureButton.debugBorder = debugBorder
    
    -- Store plate data
    Plates[namePlate] = plate
    
    -- Initial state
    plate:Hide()
    plate.secureButton:Hide()
    
    return plate
end


-- Replace the existing UpdateHighlights function with this improved version
function VeiPlates:UpdateHighlights()
    for unitID, plate in pairs(PlatesByUnit) do
        if not plate or not plate.highlight then 
            -- Skip plates without highlight
            return
        end
        
        -- ONLY update if the state has changed
        if plate.isTarget and not plate._lastIsTarget then
            -- Unit just became the target
            plate.highlight:SetVertexColor(1, 0.8, 0, 0.4)
            plate.highlight:Show()
            plate._lastIsTarget = true
        elseif not plate.isTarget and plate._lastIsTarget then
            -- Unit is no longer the target
            if plate.isMouseOver then
                -- Keep mouseover highlight
                plate.highlight:SetVertexColor(1, 1, 1, 0.3)
            else
                -- Hide highlight if not moused over
                plate.highlight:Hide()
            end
            plate._lastIsTarget = false
        end
    end
end



function VeiPlates:SetNameTextOffsets(xOffset, yOffset, anchor)
    -- Update the global configuration
    NAME_TEXT_XOFFSET = xOffset or NAME_TEXT_XOFFSET
    NAME_TEXT_YOFFSET = yOffset or NAME_TEXT_YOFFSET
    NAME_TEXT_ANCHOR = anchor or NAME_TEXT_ANCHOR
    
    -- Update all existing plates
    for _, plate in pairs(Plates) do
        if plate.name then
            plate.name:ClearAllPoints()
            plate.name:SetPoint(NAME_TEXT_ANCHOR, plate.health, "TOP", NAME_TEXT_XOFFSET, NAME_TEXT_YOFFSET)
        end
    end
    
    print("Name text offsets set to: x=" .. NAME_TEXT_XOFFSET .. ", y=" .. NAME_TEXT_YOFFSET .. 
          ", anchor=" .. NAME_TEXT_ANCHOR)
end





function VeiPlates:TestNameplateClicking()
    print("Testing nameplate clicking...")
    
    -- Hook the TargetUnit function to detect when it's called
    local originalTargetUnit = TargetUnit
    TargetUnit = function(unit)
        print("TargetUnit called with: " .. tostring(unit))
        originalTargetUnit(unit)
    end
    
    -- Add highlighting to clickable areas
    for unitID, plate in pairs(PlatesByUnit) do
        if plate and plate.clickButton then
            -- Create a debug texture to show the clickable area
            local debugTex = plate.clickButton:CreateTexture(nil, "OVERLAY")
            debugTex:SetAllPoints(plate.clickButton)
            debugTex:SetColorTexture(1, 0, 0, 0.3) -- Red to show clickable area
            
            -- Auto-remove after 5 seconds
            C_Timer.After(5, function()
                debugTex:Hide()
                debugTex = nil
            end)
            
            print("Highlighted clickable area for: " .. (UnitName(unitID) or "Unknown"))
        end
    end
    
    -- Restore original function after 10 seconds
    C_Timer.After(10, function()
        TargetUnit = originalTargetUnit
        print("Restored original TargetUnit function")
    end)
end



-- Attach a plate to a unit with improved resilience
function VeiPlatesCore:AttachPlateToUnit(unitID)
    -- Resilient approach with retry mechanism
    local function AttemptAttach(attempts)
        if attempts <= 0 then return end
        
        if not unitID or not UnitExists(unitID) then 
            -- Retry with fewer attempts if unit doesn't exist yet
            C_Timer.After(0.05, function() AttemptAttach(attempts - 1) end)
            return 
        end
        
        local namePlate = GetNamePlateForUnit(unitID)
        if not namePlate then 
            -- Retry with fewer attempts if nameplate doesn't exist yet
            C_Timer.After(0.05, function() AttemptAttach(attempts - 1) end)
            return 
        end
        
        local plate = Plates[namePlate]
        if not plate then 
            plate = self:CreatePlate(namePlate)
        end
        
        -- Get GUID for consistent tracking
        local guid = UnitGUID(unitID)
        if not guid then 
            -- Retry with fewer attempts if GUID isn't available
            C_Timer.After(0.05, function() AttemptAttach(attempts - 1) end)
            return 
        end
        
        -- Store references for quick lookups
        PlatesByUnit[unitID] = plate
        PlatesByGUID[guid] = plate
        PlatesVisible[plate] = true
        
        -- Store unit data on the plate
        plate.unitID = unitID
        plate.guid = guid
        
        -- CRITICAL: Set the unit attribute on the secure button
        if plate.secureButton then
            plate.secureButton:SetAttribute("unit", unitID)
        end
        
        -- Apply the appropriate size based on whether the unit is friendly or not
        if not UnitCanAttack("player", unitID) then
            -- Friendly unit
            plate:SetSize(FRIENDLY_PLATE_WIDTH, FRIENDLY_PLATE_HEIGHT)
            if plate.health then
                plate.health:SetSize(FRIENDLY_PLATE_WIDTH, FRIENDLY_PLATE_HEIGHT)
            end
            
            -- Update cast bar width
            if plate.castBar then
                plate.castBar:SetWidth(FRIENDLY_PLATE_WIDTH)
            end
            
            -- Set secure button size to match plate size with padding
            if plate.secureButton then
                plate.secureButton:SetSize(FRIENDLY_PLATE_WIDTH + 10, FRIENDLY_PLATE_HEIGHT + 10)
            end
        else
            -- Enemy unit
            plate:SetSize(PLATE_WIDTH, PLATE_HEIGHT)
            if plate.health then
                plate.health:SetSize(PLATE_WIDTH, PLATE_HEIGHT)
            end
            
            -- Update cast bar width
            if plate.castBar then
                plate.castBar:SetWidth(PLATE_WIDTH)
            end
            
            -- Set secure button size to match plate size with padding
            if plate.secureButton then
                plate.secureButton:SetSize(PLATE_WIDTH + 10, PLATE_HEIGHT + 10)
            end
        end
        
        -- Position first to ensure visibility
        self:PositionPlate(plate, namePlate)
        
        -- Show the plate
        plate:Show()
        plate.health:Show()
        
        -- Initialize unit cache if needed
        UnitCache[unitID] = {}
        
        -- Update static data first (name, level, etc.)
        self:UpdateUnitIdentity(unitID)
        
        -- Then update dynamic data (health, etc.)
        self:UpdateUnitDynamic(unitID)
        
        -- Check if unit is already casting when the nameplate appears
        if UnitExists(unitID) then
            -- Check for an existing cast
            local castName, _, _, castStartTime, castEndTime = UnitCastingInfo(unitID)
            if castName and castStartTime and castEndTime then
                -- Unit is already casting a spell
                self:StartCast(unitID, nil, false)
            else
                -- Check for an existing channel
                local channelName, _, _, channelStartTime, channelEndTime = UnitChannelInfo(unitID)
                if channelName and channelStartTime and channelEndTime then
                    -- Unit is already channeling a spell
                    self:StartCast(unitID, nil, true)
                end
            end
        end
        
        -- Check if there's existing cast data for this GUID
        if CastDataByGUID[guid] and not CastDataByGUID[guid].finished then
            self:ApplyCastData(plate, CastDataByGUID[guid])
        end
        
        -- Set up mouse handlers for highlight and tooltip functionality
        self:SetMouseHandlers(plate)
        
        -- Create highlight if it doesn't exist
        if not plate.highlight then
            plate.highlight = plate.health:CreateTexture(nil, "OVERLAY")
            plate.highlight:SetAllPoints()
            plate.highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            plate.highlight:SetBlendMode("ADD")
            plate.highlight:SetVertexColor(1, 1, 1, 0.3) -- Default highlight color
            plate.highlight:Hide()
        end
        
        -- Set highlight if this is the current target
        if UnitIsUnit(unitID, "target") then
            plate.isTarget = true
            if plate.highlight then
                plate.highlight:SetVertexColor(1, 0.8, 0, 0.4) -- Golden highlight for target
                plate.highlight:Show()
            end
        else
            plate.isTarget = false
        end
        
        -- Initialize mouseover state
        plate.isMouseOver = false
    end
    
    -- Start the attachment process with up to 3 retry attempts
    AttemptAttach(3)
end

-- Detach a plate from a unit
function VeiPlatesCore:DetachPlateFromUnit(unitID)
    if not unitID then return end
    
    local plate = PlatesByUnit[unitID]
    if not plate then return end
    
    local guid = plate.guid
    
    -- Remove from visible plates
    PlatesVisible[plate] = nil
    
    -- Clear unit references
    PlatesByUnit[unitID] = nil
    if guid then
        PlatesByGUID[guid] = nil
    end
    
    -- Clear unit cache
    UnitCache[unitID] = nil
    
    -- Hide the plate
    plate:Hide()
    
    -- Clear unit data
    plate.unitID = nil
    plate.guid = nil
    
    -- Hide cast bar
    if plate.castBar then
        plate.castBar:Hide()
    end
end

function VeiPlatesCore:AdjustNameplateStacking()
    local baseLevel = 100
    local increment = 5
    
    for i = 1, 40 do
        local unitID = "nameplate" .. i
        local plate = PlatesByUnit[unitID]
        
        if plate and PlatesVisible[plate] then
            -- Set frame level for better stacking
            plate:SetFrameLevel(baseLevel + (i * increment))
            
            -- Ensure the clickButton is always on top
            if plate.clickButton then
                plate.clickButton:SetFrameLevel(plate:GetFrameLevel() + 10)
            end
        end
    end
end

-- Call this function periodically to update stacking
C_Timer.NewTicker(0.5, function()
    VeiPlatesCore:AdjustNameplateStacking()
end)

-- Position a plate relative to its parent nameplate
function VeiPlatesCore:PositionPlate(plate, namePlate)
    if not plate or not namePlate then return end
    
    -- Clear any existing points
    plate:ClearAllPoints()
    
    -- Position relative to the Blizzard nameplate
    plate:SetPoint("CENTER", namePlate, "CENTER", 0, 0)
    
    -- IMPROVED: More aggressively hide Blizzard elements
    -- Hide all children of the nameplate
    for _, child in pairs({namePlate:GetChildren()}) do
        if child ~= plate then -- Don't hide our own plate
            if child.Hide then -- Safety check
                child:Hide()
            end
            if child.SetAlpha then
                child:SetAlpha(0)
            end
        end
    end
    
    -- Hide all regions (textures, fontstrings)
    for _, region in pairs({namePlate:GetRegions()}) do
        if region.SetAlpha then
            region:SetAlpha(0)
        end
    end
    
    -- If this is the UnitFrame element specifically, remove all scripts
    if namePlate.UnitFrame then
        namePlate.UnitFrame:UnregisterAllEvents()
        namePlate.UnitFrame:SetScript("OnShow", nil)
        namePlate.UnitFrame:SetScript("OnHide", nil)
        namePlate.UnitFrame:SetScript("OnUpdate", nil)
    end
    
    -- Apply size based on friendly status if unitID exists
    if plate.unitID and UnitExists(plate.unitID) then
        if not UnitCanAttack("player", plate.unitID) then
            -- Friendly unit
            plate:SetSize(FRIENDLY_PLATE_WIDTH, FRIENDLY_PLATE_HEIGHT)
            if plate.health then
                plate.health:SetSize(FRIENDLY_PLATE_WIDTH, FRIENDLY_PLATE_HEIGHT)
            end
            
            -- Update cast bar width
            if plate.castBar then
                plate.castBar:SetWidth(FRIENDLY_PLATE_WIDTH)
            end
            
            -- Update secure button
            if plate.secureButton then
                plate.secureButton:SetSize(FRIENDLY_PLATE_WIDTH + 10, FRIENDLY_PLATE_HEIGHT + 10)
            end
        else
            -- Enemy unit
            plate:SetSize(PLATE_WIDTH, PLATE_HEIGHT)
            if plate.health then
                plate.health:SetSize(PLATE_WIDTH, PLATE_HEIGHT)
            end
            
            -- Update cast bar width
            if plate.castBar then
                plate.castBar:SetWidth(PLATE_WIDTH)
            end
            
            -- Update secure button
            if plate.secureButton then
                plate.secureButton:SetSize(PLATE_WIDTH + 10, PLATE_HEIGHT + 10)
            end
        end
    end
end

-- Attach a plate to a unit with improved resilience and initial cast detection
function VeiPlatesCore:AttachPlateToUnit(unitID)
    -- Resilient approach with retry mechanism
    local function AttemptAttach(attempts)
        if attempts <= 0 then return end
        
        if not unitID or not UnitExists(unitID) then 
            -- Retry with fewer attempts if unit doesn't exist yet
            C_Timer.After(0.05, function() AttemptAttach(attempts - 1) end)
            return 
        end
        
        local namePlate = GetNamePlateForUnit(unitID)
        if not namePlate then 
            -- Retry with fewer attempts if nameplate doesn't exist yet
            C_Timer.After(0.05, function() AttemptAttach(attempts - 1) end)
            return 
        end
        
        local plate = Plates[namePlate]
        if not plate then 
            plate = self:CreatePlate(namePlate)
        end
        
        -- Get GUID for consistent tracking
        local guid = UnitGUID(unitID)
        if not guid then 
            -- Retry with fewer attempts if GUID isn't available
            C_Timer.After(0.05, function() AttemptAttach(attempts - 1) end)
            return 
        end
        
        -- Store references for quick lookups
        PlatesByUnit[unitID] = plate
        PlatesByGUID[guid] = plate
        PlatesVisible[plate] = true
        
        -- Store unit data on the plate
        plate.unitID = unitID
        plate.guid = guid
        
        -- CRITICAL: Set the unit attribute on the secure button
        if plate.secureButton then
            plate.secureButton:SetAttribute("unit", unitID)
            
            -- For debugging - show red border
            if plate.secureButton.debugBorder then
                plate.secureButton.debugBorder:Show()
                C_Timer.After(1, function()
                    if plate.secureButton.debugBorder then
                        plate.secureButton.debugBorder:Hide()
                    end
                end)
            end
        end
        
        -- Position first to ensure visibility
        self:PositionPlate(plate, namePlate)
        
        -- Show the plate
        plate:Show()
        plate.health:Show()
        
        -- Initialize unit cache if needed
        UnitCache[unitID] = {}
        
        -- Update static data first (name, level, etc.)
        self:UpdateUnitIdentity(unitID)
        
        -- Then update dynamic data (health, etc.)
        self:UpdateUnitDynamic(unitID)
        
        -- Check if unit is already casting when the nameplate appears
        if UnitExists(unitID) then
            -- Check for an existing cast
            local castName, _, _, castStartTime, castEndTime = UnitCastingInfo(unitID)
            if castName and castStartTime and castEndTime then
                -- Unit is already casting a spell
                self:StartCast(unitID, nil, false)
            else
                -- Check for an existing channel
                local channelName, _, _, channelStartTime, channelEndTime = UnitChannelInfo(unitID)
                if channelName and channelStartTime and channelEndTime then
                    -- Unit is already channeling a spell
                    self:StartCast(unitID, nil, true)
                end
            end
        end
        
        -- Check if there's existing cast data for this GUID
        if CastDataByGUID[guid] and not CastDataByGUID[guid].finished then
            self:ApplyCastData(plate, CastDataByGUID[guid])
        end
        
        -- Set highlight if this is the current target
        if UnitIsUnit(unitID, "target") and plate.highlight then
            plate.isTarget = true
            plate.highlight:SetVertexColor(1, 0.8, 0, 0.4) -- Golden highlight for target
            plate.highlight:Show()
        end
    end
    
    -- Start the attachment process with up to 3 retry attempts
    AttemptAttach(3)
end

-- =======================================
-- PLATE UPDATES WITH CACHING
-- =======================================
-- Shared function to check if unit data has changed
local function HasUnitDataChanged(unitID, fieldName, newValue)
    if not UnitCache[unitID] then
        UnitCache[unitID] = {}
        return true
    end
    
    if UnitCache[unitID][fieldName] ~= newValue then
        UnitCache[unitID][fieldName] = newValue
        return true
    end
    
    return false
end

function VeiPlatesCore:FixMouseoverHighlight(plate)
    if not plate then return end
    
    -- Remove any scripts from the plate itself
    plate:SetScript("OnEnter", nil)
    plate:SetScript("OnLeave", nil)
    plate:SetScript("OnMouseDown", nil)
    
    -- Make sure plate doesn't capture mouse events
    plate:EnableMouse(false)
    
    -- Ensure secure button is properly set up
    if plate.secureButton then
        -- Make sure the secure button captures mouse events
        plate.secureButton:EnableMouse(true)
        plate.secureButton:SetMouseMotionEnabled(true)
        
        -- Ensure the secure button is properly positioned
        plate.secureButton:ClearAllPoints()
        plate.secureButton:SetPoint("CENTER", plate, "CENTER", 0, 0)
    end
end

-- Update static unit information (used for rarely changing data)
function VeiPlatesCore:UpdateUnitIdentity(unitID)
    local plate = PlatesByUnit[unitID]
    if not plate or not UnitExists(unitID) then return end
    
    local dataChanged = false
    
    -- Check name
    local name = UnitName(unitID) or ""
    if HasUnitDataChanged(unitID, "name", name) then
        dataChanged = true
        if plate.name then
            plate.name:SetText(name)
        end
    end
    
    -- Check level and classification
    local level = UnitLevel(unitID) or 0
    local classification = UnitClassification(unitID) or ""
    
    if HasUnitDataChanged(unitID, "level", level) or 
       HasUnitDataChanged(unitID, "classification", classification) then
        
        dataChanged = true
        
        if plate.level then
            local levelText = level
            if level <= 0 then
                levelText = "??"
            end
            
            -- Add classification indicator
            if classification == "elite" then
                levelText = levelText .. "+"
            elseif classification == "rare" then
                levelText = levelText .. "R"
            elseif classification == "rareelite" then
                levelText = levelText .. "R+"
            end
            
            plate.level:SetText(levelText)
            
            -- Color level text based on difficulty
            local color = GetQuestDifficultyColor(level)
            if color then
                plate.level:SetTextColor(color.r, color.g, color.b)
            else
                plate.level:SetTextColor(1, 1, 1)
            end
        end
    end
    
    return dataChanged
end

-- Update dynamic unit information (used for frequently changing data)
function VeiPlatesCore:UpdateUnitDynamic(unitID)
    local plate = PlatesByUnit[unitID]
    if not plate or not UnitExists(unitID) or not plate.health then return end
    
    local dataChanged = false
    
    -- Check health
    local health = UnitHealth(unitID)
    local maxHealth = UnitHealthMax(unitID)
    
    if HasUnitDataChanged(unitID, "health", health) or 
       HasUnitDataChanged(unitID, "maxHealth", maxHealth) then
        
        dataChanged = true
        
        -- Avoid division by zero
        if maxHealth == 0 then maxHealth = 1 end
        
        -- Update the health bar
        plate.health:SetMinMaxValues(0, maxHealth)
        plate.health:SetValue(health)
        
        -- Change color for enemies vs friendly
        local color = {r = 0.2, g = 0.8, b = 0.2} -- Default green
        
        -- Special case for tapped units
        if UnitIsTapDenied(unitID) then
            color = {r = 0.5, g = 0.5, b = 0.5}
        elseif UnitIsPlayer(unitID) then
            -- If it's a player, use class color
            local _, class = UnitClass(unitID)
            if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
                color = RAID_CLASS_COLORS[class]
            end
        elseif not UnitCanAttack("player", unitID) then
            -- Friendly NPC
            color = {r = 0.2, g = 0.8, b = 0.2}
        else
            -- Enemy NPC
            color = {r = 0.8, g = 0.2, b = 0.2}
        end
        
        plate.health:SetStatusBarColor(color.r, color.g, color.b)
    end
    
    -- Check if this is the current target and highlight accordingly
    if UnitIsUnit(unitID, "target") then
        plate.isTarget = true
        if plate.highlight then
            plate.highlight:SetVertexColor(1, 0.8, 0, 0.4) -- Golden highlight for target
            plate.highlight:Show()
        end
    elseif plate.isTarget and not UnitIsUnit(unitID, "target") then
        plate.isTarget = false
        if plate.highlight and plate.highlight:IsShown() and not plate.isMouseOver then
            plate.highlight:Hide()
        end
    end
    
    return dataChanged
end

-- FUNCTION 5: PLAYER_TARGET_CHANGED
function VeiPlatesCore:PLAYER_TARGET_CHANGED()
    -- Clear all target highlights first
    for _, plate in pairs(Plates) do
        plate.isTarget = false
        if plate.highlight and plate.highlight:IsShown() and not plate.isMouseOver then
            plate.highlight:Hide()
        end
    end
    
    -- Highlight new target
    if UnitExists("target") then
        local targetGUID = UnitGUID("target")
        local targetPlate = PlatesByGUID[targetGUID]
        
        if targetPlate then
            targetPlate.isTarget = true
            if targetPlate.highlight then
                targetPlate.highlight:SetVertexColor(1, 0.8, 0, 0.4) -- Golden highlight
                targetPlate.highlight:Show()
            end
        end
    end
end

-- Optimized update plate function that uses caching
function VeiPlatesCore:UpdatePlate(plate, unitID)
    if not plate or not unitID then return end
    
    ThrottleFunction("update_" .. unitID, function()
        if plate and plate.unitID == unitID and UnitExists(unitID) then
            local identityChanged = self:UpdateUnitIdentity(unitID)
            local dynamicChanged = self:UpdateUnitDynamic(unitID)
            
            -- Only log updates when changes happen
            if identityChanged or dynamicChanged then
                -- Debug: print("Updated plate for " .. unitID .. " - Identity: " .. tostring(identityChanged) .. ", Dynamic: " .. tostring(dynamicChanged))
            end
        end
    end)
end


-- TestClickability function to debug click issues
function VeiPlates:TestClickability()
    print("Testing VeiPlates clickability...")
    
    -- Check all plates
    local count = 0
    for unitID, plate in pairs(PlatesByUnit) do
        if plate and plate.secureButton then
            count = count + 1
            
            local attrs = {
                unit = plate.secureButton:GetAttribute("unit"),
                type1 = plate.secureButton:GetAttribute("type1"),
                type2 = plate.secureButton:GetAttribute("type2")
            }
            
            -- Check positioning
            local sx, sy = plate.secureButton:GetCenter()
            local px, py = plate:GetCenter()
            
            print(string.format("%d. %s: SecureButton: %s", 
                count, 
                unitID or "unknown", 
                plate.secureButton:GetName() or "unnamed"
            ))
            print(string.format("   Unit: %s, type1: %s, type2: %s", 
                attrs.unit or "nil", 
                attrs.type1 or "nil", 
                attrs.type2 or "nil"
            ))
            print(string.format("   Mouse enabled: %s, Visible: %s", 
                tostring(plate.secureButton:IsMouseEnabled()), 
                tostring(plate.secureButton:IsVisible())
            ))
            print(string.format("   Position - Secure: %.1f, %.1f, Plate: %.1f, %.1f", 
                sx or 0, sy or 0, 
                px or 0, py or 0
            ))
            print(string.format("   Frame strata: %s, level: %d", 
                plate.secureButton:GetFrameStrata(),
                plate.secureButton:GetFrameLevel()
            ))
            
            -- Make the debug border visible
            if plate.secureButton.debugBorder then
                plate.secureButton.debugBorder:Show()
                -- Hide after 5 seconds
                C_Timer.After(5, function()
                    if plate.secureButton.debugBorder then
                        plate.secureButton.debugBorder:Hide()
                    end
                end)
            end
        end
    end
    
    if count == 0 then
        print("No plates with secure buttons found!")
    end
end
-- =======================================
-- CAST BAR MANAGEMENT
-- =======================================
-- Start a new cast
function VeiPlatesCore:StartCast(unitID, spellID, isChanneled)
    local plate = PlatesByUnit[unitID]
    if not plate or not UnitExists(unitID) then return end
    
    local guid = UnitGUID(unitID)
    if not guid then return end
    
    -- Get cast info based on whether it's a channel or normal cast
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible
    
    if isChanneled then
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unitID)
    else
        name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unitID)
    end
    
    if not name or not startTime or not endTime then return end
    
    -- Convert times from ms to seconds
    startTime = startTime / 1000
    endTime = endTime / 1000
    local duration = endTime - startTime
    
    -- Store cast data indexed by GUID to prevent mismatches
    local castData = {
        name = name,
        text = text,
        texture = texture,
        startTime = startTime,
        endTime = endTime,
        duration = duration,
        isChanneled = isChanneled,
        notInterruptible = notInterruptible,
        finished = false
    }
    
    CastDataByGUID[guid] = castData
    
    -- Apply the cast data to the plate
    self:ApplyCastData(plate, castData)
    
    -- Set timeout to clean up stale casts
    C_Timer.After(min(duration + 1, MAX_CASTBAR_TIMEOUT), function()
        if CastDataByGUID[guid] and CastDataByGUID[guid].name == name and not CastDataByGUID[guid].finished then
            CastDataByGUID[guid].finished = true
            
            -- Find the current plate for this GUID (it might have changed)
            local currentPlate = PlatesByGUID[guid]
            if currentPlate and currentPlate.castBar and currentPlate.castBar:IsShown() then
                currentPlate.castBar:Hide()
            end
        end
    end)
end

-- Apply cast data to a plate's cast bar
function VeiPlatesCore:ApplyCastData(plate, castData)
    if not plate or not castData or not plate.castBar then return end
    if not castData.startTime or not castData.duration then return end
    
    local castBar = plate.castBar
    
    -- Set up the cast bar
    castBar:SetMinMaxValues(0, castData.duration)
    
    -- Different handling for channels vs. normal casts
    if castData.isChanneled then
        castBar:SetScript("OnUpdate", function(self)
            local current = GetTime()
            -- Safety check to ensure we have valid data
            if not castData.startTime or not castData.duration then 
                self:Hide()
                return 
            end
            
            local elapsed = current - castData.startTime
            local remaining = max(0, castData.duration - elapsed)
            self:SetValue(remaining)
            
            -- Format time text
            local timeText = format("%.1f", remaining)
            if self.text then
                self.text:SetText(castData.name .. " " .. timeText)
            end
        end)
    else
        castBar:SetScript("OnUpdate", function(self)
            local current = GetTime()
            -- Safety check to ensure we have valid data
            if not castData.startTime or not castData.duration then 
                self:Hide()
                return 
            end
            
            local elapsed = current - castData.startTime
            self:SetValue(min(elapsed, castData.duration))
            
            -- Format time text
            local timeText = format("%.1f", min(elapsed, castData.duration))
            if self.text then
                self.text:SetText(castData.name .. " " .. timeText)
            end
        end)
    end
    
    -- Set icon
    if castBar.icon and castData.texture then
        castBar.icon:SetTexture(castData.texture)
    elseif castBar.icon then
        castBar.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    -- Set color
    castBar:SetStatusBarColor(1, 0.7, 0)
    
    -- Show the cast bar
    castBar:Show()
end

-- Stop a cast normally (completion)
function VeiPlatesCore:StopCast(unitID, spellID)
    local plate = PlatesByUnit[unitID]
    if not plate then return end
    
    local guid = UnitGUID(unitID)
    if not guid then return end
    
    -- Mark the cast as finished
    if CastDataByGUID[guid] then
        CastDataByGUID[guid].finished = true
    end
    
    -- Hide cast bar
    if plate.castBar then
        plate.castBar:Hide()
        plate.castBar:SetScript("OnUpdate", nil)
    end
end

-- Interrupt a cast (failure)
function VeiPlatesCore:InterruptCast(unitID, spellID)
    local plate = PlatesByUnit[unitID]
    if not plate then return end
    
    local guid = UnitGUID(unitID)
    if not guid then return end
    
    -- Mark the cast as finished
    if CastDataByGUID[guid] then
        CastDataByGUID[guid].finished = true
    end
    
    -- Show interrupted state
    if plate.castBar and plate.castBar:IsShown() then
        -- Change color to interrupted
        plate.castBar:SetStatusBarColor(1, 0.3, 0.2)
        if plate.castBar.text then
            plate.castBar.text:SetText("Interrupted")
        end
        
        -- Stop updating
        plate.castBar:SetScript("OnUpdate", nil)
        
        -- Hide after a short delay
        C_Timer.After(0.5, function()
            if plate.castBar then
                plate.castBar:Hide()
            end
        end)
    end
end

-- Update a delayed cast
function VeiPlatesCore:UpdateCastDelay(unitID, spellID)
    local plate = PlatesByUnit[unitID]
    if not plate then return end
    
    local guid = UnitGUID(unitID)
    if not guid then return end
    
    -- Get updated cast info
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unitID)
    
    if not name or not startTime or not endTime then return end
    
    -- Convert times from ms to seconds
    startTime = startTime / 1000
    endTime = endTime / 1000
    local duration = endTime - startTime
    
    -- Update cast data
    if CastDataByGUID[guid] then
        CastDataByGUID[guid].startTime = startTime
        CastDataByGUID[guid].endTime = endTime
        CastDataByGUID[guid].duration = duration
    end
end

-- Update a delayed channel
function VeiPlatesCore:UpdateChannelDelay(unitID, spellID)
    local plate = PlatesByUnit[unitID]
    if not plate then return end
    
    local guid = UnitGUID(unitID)
    if not guid then return end
    
    -- Get updated channel info
    local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unitID)
    
    if not name or not startTime or not endTime then return end
    
    -- Convert times from ms to seconds
    startTime = startTime / 1000
    endTime = endTime / 1000
    local duration = endTime - startTime
    
    -- Update cast data
    if CastDataByGUID[guid] then
        CastDataByGUID[guid].startTime = startTime
        CastDataByGUID[guid].endTime = endTime
        CastDataByGUID[guid].duration = duration
    end
end

-- =======================================
-- CLEANUP AND MAINTENANCE
-- =======================================
-- Cleanup stale cast data (run periodically)
function VeiPlates:CleanupStaleData()
    local currentTime = GetTime()
    local removedCount = 0
    
    -- Check for stale cast data
    for guid, castData in pairs(CastDataByGUID) do
        -- Remove data for casts that should have finished over 5 seconds ago
        if castData.endTime and (currentTime > castData.endTime + 5) then
            CastDataByGUID[guid] = nil
            removedCount = removedCount + 1
        end
    end
    
    -- Clean up stale unit cache entries
    for unitID, _ in pairs(UnitCache) do
        if not UnitExists(unitID) or not PlatesByUnit[unitID] then
            UnitCache[unitID] = nil
            removedCount = removedCount + 1
        end
    end
    
    -- Schedule the next cleanup
    C_Timer.After(30, function() 
        VeiPlates:CleanupStaleData()
    end)
    
    -- Return number of items cleaned up (for debug)
    return removedCount
end

-- =======================================
-- PUBLIC API
-- =======================================
-- Toggle nameplate visibility
function VeiPlates:TogglePlates(show)
    for _, plate in pairs(Plates) do
        if show then
            plate:Show()
            if plate.health then
                plate.health:Show()
            end
        else
            plate:Hide()
        end
    end
end

-- Reset all nameplates (helpful when troubleshooting)
function VeiPlates:ResetPlates()
    -- Hide and clear all plates
    for _, plate in pairs(Plates) do
        plate:Hide()
        if plate.castBar then
            plate.castBar:Hide()
        end
        plate.unitID = nil
        plate.guid = nil
    end
    
    -- Clear all tracking tables
    wipe(PlatesVisible)
    wipe(PlatesByUnit)
    wipe(PlatesByGUID)
    wipe(CastDataByGUID)
    wipe(UnitCache)
    
    -- Force refresh of any visible nameplates
    for i = 1, 40 do
        local unitID = "nameplate" .. i
        if UnitExists(unitID) then
            VeiPlatesCore:AttachPlateToUnit(unitID)
        end
    end
    
  --  print("VeiPlates reset complete.")
end

-- Get a plate by unit ID
function VeiPlates:GetPlateByUnit(unitID)
    return PlatesByUnit[unitID]
end

-- Get a plate by GUID
function VeiPlates:GetPlateByGUID(guid)
    return PlatesByGUID[guid]
end

function VeiPlates:DebugHighlightPlates()
    local count = 0
    for unitID, plate in pairs(PlatesByUnit) do
        if plate and plate.health then
            count = count + 1
            
            -- Create a highlight if it doesn't exist
            if not plate.highlight then
                plate.highlight = plate:CreateTexture(nil, "OVERLAY")
                plate.highlight:SetAllPoints(plate)
                plate.highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
                plate.highlight:SetBlendMode("ADD")
            end
            
            -- Set a bright color based on unit type
            if UnitIsPlayer(unitID) then
                plate.highlight:SetVertexColor(1, 0, 0, 0.5) -- Red for players
            else
                plate.highlight:SetVertexColor(0, 1, 0, 0.5) -- Green for NPCs
            end
            
            plate.highlight:Show()
            
            -- Debug borders for health bar and backdrop
            if not plate.health.debugBorder then
                plate.health.debugBorder = plate.health:CreateTexture(nil, "OVERLAY")
                plate.health.debugBorder:SetAllPoints(plate.health)
                plate.health.debugBorder:SetColorTexture(1, 0, 0, 0.3) -- Red border
            end
            
            if plate.backdrop and not plate.backdrop.debugBorder then
                plate.backdrop.debugBorder = plate.health:CreateTexture(nil, "OVERLAY")
                plate.backdrop.debugBorder:SetAllPoints(plate.backdrop)
                plate.backdrop.debugBorder:SetColorTexture(0, 0, 1, 0.3) -- Blue border
            end
            
            plate.health.debugBorder:Show()
            if plate.backdrop and plate.backdrop.debugBorder then
                plate.backdrop.debugBorder:Show()
            end
            
            -- Make the plate bigger temporarily
            local originalWidth, originalHeight = plate:GetSize()
            plate:SetSize(originalWidth * 1.5, originalHeight * 1.5)
            
            -- Highlight will auto-hide and restore size after 3 seconds
            C_Timer.After(3, function()
                if plate and plate.highlight then
                    plate.highlight:Hide()
                    if plate.health and plate.health.debugBorder then
                        plate.health.debugBorder:Hide()
                    end
                    if plate.backdrop and plate.backdrop.debugBorder then
                        plate.backdrop.debugBorder:Hide()
                    end
                    plate:SetSize(originalWidth, originalHeight)
                end
            end)
            
            -- Print info about this nameplate
            local name = UnitName(unitID) or "Unknown"
            local health = UnitHealth(unitID) or 0
            local maxHealth = UnitHealthMax(unitID) or 1
            print(unitID .. " (" .. name .. "): " .. health .. "/" .. maxHealth .. 
                  " | Plate visible: " .. tostring(plate:IsVisible()) .. 
                  " | Health bar visible: " .. tostring(plate.health:IsVisible()))
        end
    end
    
    print("Highlighted " .. count .. " active nameplates out of " .. GetTableCount(PlatesByUnit) .. " tracked units")
end
-- Print cache statistics
function VeiPlates:PrintCacheStats()
    local unitCacheCount = GetTableCount(UnitCache)
    local totalCachedValues = 0
    
    for _, cache in pairs(UnitCache) do
        totalCachedValues = totalCachedValues + GetTableCount(cache)
    end
    
    local guidCastCount = GetTableCount(CastDataByGUID)
    
    print("VeiPlates Cache Statistics:")
    print("  Units cached: " .. unitCacheCount)
    print("  Total cached values: " .. totalCachedValues)
    print("  Active casts tracked: " .. guidCastCount)
    print("  Total nameplates: " .. GetTableCount(Plates))
    print("  Visible nameplates: " .. GetTableCount(PlatesVisible))
    
    -- Calculate cache hit rate
    local hitRate = VeiPlates._cacheHits / (VeiPlates._cacheHits + VeiPlates._cacheMisses) * 100
    print("  Cache hit rate: " .. string.format("%.1f", hitRate) .. "%")
end

-- Cache performance tracking
VeiPlates._cacheHits = 0
VeiPlates._cacheMisses = 0

-- Helper function for counting table entries
function GetTableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Set the scale for all nameplates
function VeiPlates:SetScale(scale)
    scale = scale or 1
    
    for _, plate in pairs(Plates) do
        plate:SetScale(scale)
    end
end

-- =======================================
-- CUSTOMIZATION API
-- =======================================
-- Set custom size for nameplates
-- Set custom size for nameplates
function VeiPlates:SetPlateSize(width, height)
    PLATE_WIDTH = width or PLATE_WIDTH
    PLATE_HEIGHT = height or PLATE_HEIGHT
    
    for _, plate in pairs(Plates) do
        plate:SetSize(PLATE_WIDTH, PLATE_HEIGHT)
        if plate.health then
            plate.health:SetSize(PLATE_WIDTH, PLATE_HEIGHT)
        end
        
        -- Reposition cast bar
        if plate.castBar then
            plate.castBar:SetSize(PLATE_WIDTH, CASTBAR_HEIGHT)
            plate.castBar:SetPoint("TOP", plate.health, "BOTTOM", CASTBAR_X_OFFSET, CASTBAR_Y_OFFSET)
        end
    end
end

-- Set custom text size
function VeiPlates:SetTextSize(size)
    TEXT_SIZE = size or TEXT_SIZE
    
    for _, plate in pairs(Plates) do
        if plate.name then
            plate.name:SetFont("Fonts\\FRIZQT__.TTF", TEXT_SIZE, "OUTLINE")
        end
        if plate.level then
            plate.level:SetFont("Fonts\\FRIZQT__.TTF", TEXT_SIZE - 2, "OUTLINE")
        end
        if plate.castBar and plate.castBar.text then
            plate.castBar.text:SetFont("Fonts\\FRIZQT__.TTF", TEXT_SIZE, "OUTLINE")
        end
    end
end



-- =======================================
-- ADDON INITIALIZATION AND EVENT REGISTRATION
-- =======================================
-- Register for addon loaded event
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        VeiPlates:Initialize()
        
        -- Start the stale data cleanup timer
        VeiPlates:CleanupStaleData()
        
        -- Unregister once initialized
        self:UnregisterEvent("ADDON_LOADED")
    end

    VeiPlatesCore:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
end

-- Create initialization frame
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", OnEvent)

-- Return the module
return VeiPlates