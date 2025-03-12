-- ArenaFrame.lua
local addonName, MyAddon = ...
local MSQ = LibStub and LibStub("Masque", true)
local group -- Masque group

-- Test mode state
MyAddon.testMode = false

-- Function to toggle test mode
function MyAddon:ToggleTestMode()
    self.testMode = not self.testMode
    self:UpdateFrames()
end

function MyAddon:HideDefaultArenaFrames()
    local hasHiddenFrames = false

    local function HideFrames()
        if hasHiddenFrames then return end
        
        -- Hide and disable the main container
        if ArenaEnemyFrames then
            ArenaEnemyFrames:Hide()
            ArenaEnemyFrames:UnregisterAllEvents()
        end

        -- Hide all individual frames
        for i = 1, 5 do
            local frames = {
                _G["ArenaEnemyFrame"..i],
                _G["ArenaEnemyFrame"..i.."PetFrame"],
                _G["ArenaEnemyFrame"..i.."DropDown"],
                _G["ArenaEnemyPetFrame"..i],
                _G["ArenaEnemyFrame"..i.."CastingBar"]
            }
            
            for _, frame in pairs(frames) do
                if frame then
                    frame:Hide()
                    frame:UnregisterAllEvents()
                end
            end
        end

        hasHiddenFrames = true
        
        -- Once we've hidden the frames, we can unregister our events
        if watcherFrame then
            watcherFrame:UnregisterAllEvents()
        end
    end

    -- Create a frame to watch for unit power updates
    local watcherFrame = CreateFrame("Frame")
    watcherFrame:RegisterEvent("UNIT_POWER_UPDATE")
    watcherFrame:RegisterEvent("UNIT_HAPPINESS")
    
    watcherFrame:SetScript("OnEvent", function(self, event, unit)
        if unit and unit:match("^arena%d$") then
            HideFrames()
        end
    end)
end

-- Function to get the appropriate unit for a frame
local function GetAppropriateUnit(frameIndex)
    if MyAddon.testMode then
        return "player"
    else
        return "arena" .. frameIndex
    end
end

-- Function to check if a unit should be shown
local function ShouldShowUnit(unit)
    if MyAddon.testMode then
        return true
    else
        return UnitExists(unit)
    end
end

-- Class Atlas mapping (moved to MyAddon namespace for sharing)
MyAddon.classAtlasMap = {
    DEATHKNIGHT = "classicon-deathknight",
    DRUID = "classicon-druid",
    HUNTER = "classicon-hunter",
    MAGE = "classicon-mage",
    PALADIN = "classicon-paladin",
    PRIEST = "classicon-priest",
    ROGUE = "classicon-rogue",
    SHAMAN = "classicon-shaman",
    WARLOCK = "classicon-warlock",
    WARRIOR = "classicon-warrior"
}

-- Adjustable settings
local iconSize = 43.4
local iconXOffset = -43.4

-- Class Icons
local classIcons = CLASS_ICON_TCOORDS

-- Function to create border textures
local function CreateBorderTexture(parent, atlas, xOffset, yOffset, width, height, rotation, mirror)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetFrameStrata("HIGH")
    holder:SetFrameLevel(5)
    holder:SetAllPoints(parent)
    
    local texture = holder:CreateTexture(nil, "OVERLAY", nil, 7)
    texture:SetAtlas(atlas)
    texture:SetSize(width, height)
    texture:SetPoint("CENTER", parent, "CENTER", xOffset, yOffset)
    texture:SetRotation(math.rad(rotation))
    if mirror then
        texture:SetTexCoord(1, 0, 0, 1)
    end
    return texture
end

-- Function to create dynamic class icons
local function CreateDynamicIcon(parent, unit)
    local iconFrame = CreateFrame("Button", nil, parent)
    iconFrame:SetFrameStrata("LOW")
    iconFrame:SetFrameLevel(1)
    iconFrame:SetSize(iconSize, iconSize)
    iconFrame:SetPoint("LEFT", parent, "LEFT", iconXOffset, 0)
    
    local icon = iconFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    icon:SetAllPoints(iconFrame)
    iconFrame.icon = icon
    
    if MSQ then
        local normalTexture = iconFrame:CreateTexture(nil, "ARTWORK", nil, 1)
        normalTexture:SetAllPoints(iconFrame)
        iconFrame.normalTexture = normalTexture
        iconFrame.SetNormalTexture = function(self, tex)
            self.normalTexture:SetTexture(tex)
        end
        
        group:AddButton(iconFrame, {
            Icon = icon,
            Normal = normalTexture,
        })
    end
    
    return iconFrame
end

---------------------------------------------------------
-- New Composite Bar (Health + Mana/Power)
---------------------------------------------------------

local totalBarHeight = 42
local healthHeight = 33   -- roughly 3.5 parts for health
local manaHeight = totalBarHeight - healthHeight  -- about 9 pixels for mana/power

local function CreateCompositeBar(frameIndex, yOffset)
    local compositeBar = CreateFrame("Frame", nil, UIParent)
    compositeBar:SetSize(92, totalBarHeight)
    compositeBar:SetPoint("CENTER", UIParent, "CENTER", 463, 44 + yOffset)
    compositeBar.frameIndex = frameIndex

    -- Health status bar (top portion)
    compositeBar.healthStatus = CreateFrame("StatusBar", nil, compositeBar)
    compositeBar.healthStatus:SetSize(92, healthHeight)
    compositeBar.healthStatus:SetPoint("TOPLEFT", compositeBar, "TOPLEFT", 0, 0)
    compositeBar.healthStatus:SetPoint("TOPRIGHT", compositeBar, "TOPRIGHT", 0, 0)
    compositeBar.healthStatus:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    
    local healthBG = compositeBar.healthStatus:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints()
    healthBG:SetTexture("Interface\\Buttons\\WHITE8x8")
    healthBG:SetColorTexture(0, 0, 0, 0.7)

    -- Mana/Power status bar (bottom portion)
    compositeBar.manaStatus = CreateFrame("StatusBar", nil, compositeBar)
    compositeBar.manaStatus:SetSize(92, manaHeight)
    compositeBar.manaStatus:SetPoint("BOTTOMLEFT", compositeBar, "BOTTOMLEFT", 0, 0)
    compositeBar.manaStatus:SetPoint("BOTTOMRIGHT", compositeBar, "BOTTOMRIGHT", 0, 0)
    compositeBar.manaStatus:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    
    local manaBG = compositeBar.manaStatus:CreateTexture(nil, "BACKGROUND")
    manaBG:SetAllPoints()
    manaBG:SetTexture("Interface\\Buttons\\WHITE8x8")
    manaBG:SetColorTexture(0, 0, 0, 0.7)
    
    function compositeBar:UpdateUnit()
        local unit = GetAppropriateUnit(self.frameIndex)
        if ShouldShowUnit(unit) then
            -- Update health portion
            local healthMax = UnitHealthMax(unit)
            local health = UnitHealth(unit)
            self.healthStatus:SetMinMaxValues(0, healthMax)
            self.healthStatus:SetValue(health)
            local _, class = UnitClass(unit)
            local classColor = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
            self.healthStatus:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
            
            -- Update mana/power portion
            local powerType = UnitPowerType(unit)
            local powerMax = UnitPowerMax(unit)
            local power = UnitPower(unit)
            self.manaStatus:SetMinMaxValues(0, powerMax)
            self.manaStatus:SetValue(power)
            local powerColor = (PowerBarColor[powerType] or { r = 0, g = 0, b = 1 })
            self.manaStatus:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
            
            self:Show()
        else
            self:Hide()
        end
    end

    compositeBar:RegisterEvent("UNIT_HEALTH")
    compositeBar:RegisterEvent("UNIT_MAXHEALTH")
    compositeBar:RegisterEvent("UNIT_POWER_UPDATE")
    compositeBar:RegisterEvent("PLAYER_ENTERING_WORLD")
    compositeBar:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_ENTERING_WORLD" or 
           (unit and unit == GetAppropriateUnit(self.frameIndex)) then
            self:UpdateUnit()
        end
    end)

    return compositeBar
end

---------------------------------------------------------
-- Decorative Health Frame (unchanged)
---------------------------------------------------------

local function CreateHealthBar(frameIndex, yOffset)
    local healthFrame = CreateFrame("StatusBar", nil, UIParent)
    healthFrame:SetFrameStrata("LOW")
    healthFrame:SetFrameLevel(0)
    healthFrame:SetSize(138, 42)
    healthFrame:SetPoint("CENTER", UIParent, "CENTER", 486, 44 + yOffset)
    healthFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    healthFrame:SetStatusBarColor(1, 1, 1, 0)
    
    healthFrame.frameIndex = frameIndex
    healthFrame.dynamicIcon = CreateDynamicIcon(healthFrame, "player")
    
    -- Corner Textures
    healthFrame.cornerBottomRight = CreateBorderTexture(healthFrame, "ForgeBorder-CornerBottomRight", 62, -16, 16, 16, 0, false)
    healthFrame.cornerTopRight = CreateBorderTexture(healthFrame, "ForgeBorder-CornerBottomRight", 62, 16, 16, 16, 90, false)
    healthFrame.cornerTopLeft = CreateBorderTexture(healthFrame, "ForgeBorder-CornerBottomRight", -106, 16, 16, 16, 180, false)
    healthFrame.cornerBottomLeft = CreateBorderTexture(healthFrame, "ForgeBorder-CornerBottomRight", -106, -16, 16, 16, 0, true)
    
    -- Border Textures
    healthFrame.borderRight = CreateBorderTexture(healthFrame, "!ForgeBorder-Right", 68, 0, 4.3, 18, 0, false)
    healthFrame.borderTop = CreateBorderTexture(healthFrame, "!ForgeBorder-Right", -22, 22, 4.3, 152, 90, false)
    healthFrame.borderLeft = CreateBorderTexture(healthFrame, "!ForgeBorder-Right", -111.7, 0, 4.3, 18, 0, true)
    healthFrame.borderBottom = CreateBorderTexture(healthFrame, "!ForgeBorder-Right", -22, -22, 4.3, 152, 90, true)
    
    function healthFrame:UpdateUnit()
        local unit = GetAppropriateUnit(self.frameIndex)
        if ShouldShowUnit(unit) then
            local _, class = UnitClass(unit)
            if class and MyAddon.classAtlasMap[class] then
                self.dynamicIcon.icon:SetAtlas(MyAddon.classAtlasMap[class])
            end
            if MyAddon.BuffTracker then
                MyAddon.BuffTracker.StartTracking(unit, self.dynamicIcon)
            end
            self:Show()
        else
            self:Hide()
        end
    end
    
    healthFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    healthFrame:RegisterEvent("UNIT_POWER_UPDATE")
    
    healthFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_ENTERING_WORLD" or 
           (event == "UNIT_POWER_UPDATE" and unit and unit:match("^arena%d$")) then
            self:UpdateUnit()
        end
    end)
    
    return healthFrame
end

---------------------------------------------------------
-- Update All Frames
---------------------------------------------------------

function MyAddon:UpdateFrames()
    for i, frame in pairs(self.frames) do
        frame:UpdateUnit()
    end
    for i, bar in ipairs(self.healthBars) do
        bar:UpdateUnit()
    end
end

---------------------------------------------------------
-- Initialize Masque Group
---------------------------------------------------------

local function InitializeMasque()
    if MSQ then
        group = MSQ:Group(addonName, "Arena Frames")
    end
end

---------------------------------------------------------
-- PLAYER_LOGIN Initialization
---------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeMasque()
        
        -- Hide default arena frames permanently
        MyAddon:HideDefaultArenaFrames()
        
        -- Create decorative frames (from CreateHealthBar)
        local frame1 = CreateHealthBar(1, 0)
        local frame2 = CreateHealthBar(2, -71)
        local frame3 = CreateHealthBar(3, -140)
        
        -- Create composite bars (health + mana/power)
        local compositeBars = {
            CreateCompositeBar(1, 0),
            CreateCompositeBar(2, -71),
            CreateCompositeBar(3, -140)
        }
        
        -- Store the frames for future reference
        MyAddon.healthBars = compositeBars
        MyAddon.frames = {
            frame1 = frame1,
            frame2 = frame2,
            frame3 = frame3
        }
        
        -- Create a corner frame for decorative borders
        local cornerFrame = CreateFrame("Frame", "MyCornerFrame", UIParent)
        cornerFrame:SetSize(200, 200)
        cornerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

        -- Corner borders
        cornerFrame.cornerBottomRight = CreateBorderTexture(cornerFrame, "ForgeBorder-CornerBottomRight",  189,  -413, 30, 30,   0, false)
        cornerFrame.cornerTopRight    = CreateBorderTexture(cornerFrame, "ForgeBorder-CornerBottomRight",  189,   -336, 30, 30,  90, false)
        cornerFrame.cornerTopLeft     = CreateBorderTexture(cornerFrame, "ForgeBorder-CornerBottomRight", -189,  -336, 30, 30, 180, false)
        cornerFrame.cornerBottomLeft  = CreateBorderTexture(cornerFrame, "ForgeBorder-CornerBottomRight", -189, -413, 30, 30,   0, true)
        
        -- Border lines
        cornerFrame.borderRight  = CreateBorderTexture(cornerFrame, "!ForgeBorder-Right", 200, -374.5, 7, 47, 0, false) 
        cornerFrame.borderTop    = CreateBorderTexture(cornerFrame, "!ForgeBorder-Right", 0, -324.2, 7.5, 350, 90, false)
        cornerFrame.borderLeft   = CreateBorderTexture(cornerFrame, "!ForgeBorder-Right", -200, -374.5, 7, 47, 0, true)
        cornerFrame.borderBottom = CreateBorderTexture(cornerFrame, "!ForgeBorder-Right", 0, -424.5, 7.5, 347, 90, true)
        
        cornerFrame:Show()
        
        -- Register test mode slash command
        SLASH_ARENATEST1 = "/arenatest"
        SlashCmdList["ARENATEST"] = function()
            MyAddon:ToggleTestMode()
            print("Arena test mode " .. (MyAddon.testMode and "enabled" or "disabled"))
        end
    end
end)

-- End of ArenaFrame.lua
