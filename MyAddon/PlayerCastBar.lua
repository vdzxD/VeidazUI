-- PlayerCastBarWithAtlasCorners.lua

local addonName, MyAddon = ...



---------------------------------------
-- Reuse your function that creates border atlas textures
---------------------------------------
local function CreateBorderTexture(parent, atlas, xOffset, yOffset, width, height, rotation, mirror)
    local texture = parent:CreateTexture(nil, "OVERLAY")
    texture:SetAtlas(atlas)
    texture:SetSize(width, height)
    texture:SetPoint("CENTER", parent, "CENTER", xOffset, yOffset)
    texture:SetRotation(math.rad(rotation))
    if mirror then
        texture:SetTexCoord(1, 0, 0, 1)
    end
    return texture
end

---------------------------------------
-- Create a simple player cast bar
-- that has custom atlas corners & borders
-- with explicit text font size
---------------------------------------

local playerCastBar = CreateFrame("StatusBar", "MyPlayerCastBarAtlas", UIParent, "BackdropTemplate")
playerCastBar:SetSize(220, 22)
playerCastBar:SetPoint("CENTER", UIParent, "CENTER", 0, -295)
playerCastBar:SetStatusBarTexture("Interface\\Addons\\MyAddon\\Textures\\Smoothv2.tga")
playerCastBar:SetStatusBarColor(1, 0.7, 0) -- Orange
playerCastBar:Hide()

local playerCastBar = CreateFrame("StatusBar", "MyPlayerCastBarAtlas", UIParent, "BackdropTemplate")
playerCastBar:SetSize(220, 22)
playerCastBar:SetPoint("CENTER", UIParent, "CENTER", 0, -295)
playerCastBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
playerCastBar:SetStatusBarColor(1, 0.7, 0) -- Orange
playerCastBar:Hide()

-- Optional background
local bg = playerCastBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetColorTexture(0, 0, 0, 0.5) -- Semi-transparent black

-- Add the spark texture to the player cast bar
local spark = playerCastBar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetSize(32, 32)  -- Typically the spark is slightly taller than the bar
spark:SetBlendMode("ADD")
spark:SetPoint("CENTER", playerCastBar, "LEFT", 0, 0)  -- Initial position, will be updated
playerCastBar.spark = spark

-- Optional background
local bg = playerCastBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetColorTexture(0, 0, 0, 0.5) -- Semi-transparent black

---------------------------------------
-- Custom text
---------------------------------------
local textSize = 14.75
local castText = playerCastBar:CreateFontString(nil, "OVERLAY")
castText:SetFont("Fonts\\FRIZQT__.TTF", textSize, "OUTLINE")
castText:SetPoint("CENTER", playerCastBar, "CENTER", 0, 0)
castText:SetTextColor(1, 1, 1, 1)
playerCastBar.castText = castText

---------------------------------------
-- Atlas Corner / Border Textures
---------------------------------------
playerCastBar.cornerBottomRight = CreateBorderTexture(playerCastBar, "ForgeBorder-CornerBottomRight", 105, -5.5, 16, 16, 0, false) 
playerCastBar.cornerTopRight    = CreateBorderTexture(playerCastBar, "ForgeBorder-CornerBottomRight", 105, 6.7, 16, 16, 90, false)
playerCastBar.cornerTopLeft     = CreateBorderTexture(playerCastBar, "ForgeBorder-CornerBottomRight", -105, 6.7, 16, 16, 180, false)
playerCastBar.cornerBottomLeft  = CreateBorderTexture(playerCastBar, "ForgeBorder-CornerBottomRight", -105, -5.5, 16, 16, 0, true)

playerCastBar.borderTop         = CreateBorderTexture(playerCastBar, "!ForgeBorder-Right", -0, 12.3, 4, 194, 90, false)
playerCastBar.borderBottom      = CreateBorderTexture(playerCastBar, "!ForgeBorder-Right", -0, -11, 4, 194, 90, false)

-- Hide them initially (the bar is hidden)
local function HideAllBorders()
    playerCastBar.cornerBottomRight:Hide()
    playerCastBar.cornerTopRight:Hide()
    playerCastBar.cornerTopLeft:Hide()
    playerCastBar.cornerBottomLeft:Hide()
    playerCastBar.borderTop:Hide()
    playerCastBar.borderBottom:Hide()
end

local function ShowAllBorders()
    playerCastBar.cornerBottomRight:Show()
    playerCastBar.cornerTopRight:Show()
    playerCastBar.cornerTopLeft:Show()
    playerCastBar.cornerBottomLeft:Show()
    playerCastBar.borderTop:Show()
    playerCastBar.borderBottom:Show()
end

HideAllBorders()

-- Show/hide borders with the bar
playerCastBar:HookScript("OnShow", ShowAllBorders)
playerCastBar:HookScript("OnHide", HideAllBorders)

---------------------------------------
-- Event handling
---------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

-- Update the cast bar
local function UpdatePlayerCastBar()
    local name, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo("player")
    local isChanneling = false

    if not name then
        -- check channel
        name, _, _, startTime, endTime, _, _, notInterruptible = UnitChannelInfo("player")
        isChanneling = name ~= nil
    end

    if not name then
        playerCastBar:Hide()
        return
    end

    playerCastBar:Show()
    playerCastBar.castText:SetText(name or "Casting...")

    -- Store cast information
    playerCastBar.startTime = startTime
    playerCastBar.endTime = endTime
    playerCastBar.isChanneling = isChanneling

    -- Set up the bar
    playerCastBar:SetMinMaxValues(0, endTime - startTime)
    
    -- Initial value
    local currentTime = GetTime() * 1000
    local progress = currentTime - startTime
    playerCastBar:SetValue(progress)
end

-- Smoothly animate
playerCastBar:SetScript("OnUpdate", function(self)
    if self:IsShown() then
        local currentTime = GetTime() * 1000
        local progress
        
        if self.isChanneling then
            -- For channeling, progress goes backwards
            progress = self.endTime - currentTime
        else
            -- For casting, progress goes forwards
            progress = currentTime - self.startTime
        end
        
        -- Check if cast/channel is complete
        if (not self.isChanneling and progress >= (self.endTime - self.startTime)) or
           (self.isChanneling and progress <= 0) then
            self:Hide()
        else
            self:SetValue(progress)
            
            -- Calculate and update spark position
            local barWidth = self:GetWidth()
            local position
            
            if self.isChanneling then
                -- For channeling, spark moves from right to left
                position = (progress / (self.endTime - self.startTime)) * barWidth
            else
                -- For casting, spark moves from left to right
                position = (progress / (self.endTime - self.startTime)) * barWidth
            end
            
            self.spark:SetPoint("CENTER", self, "LEFT", position, 0)
        end
    end
end)

eventFrame:SetScript("OnEvent", function(self, event, unit)
    if unit == "player" then
        if event == "UNIT_SPELLCAST_START"
           or event == "UNIT_SPELLCAST_CHANNEL_START"
           or event == "UNIT_SPELLCAST_DELAYED"
           or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
            UpdatePlayerCastBar()

        elseif event == "UNIT_SPELLCAST_STOP"
           or event == "UNIT_SPELLCAST_CHANNEL_STOP"
           or event == "UNIT_SPELLCAST_INTERRUPTED" then
            playerCastBar:Hide()
        end
    end
end)