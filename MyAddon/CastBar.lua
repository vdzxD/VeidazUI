-- CastBar.lua
local addonName, MyAddon = ...


-- Adjustable settings
local castIconXOffset = -1.4

-- Function to get the appropriate unit for a frame (matching arena frames logic)
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

-- Function to create a cast bar
local function CreateCastBar(frameIndex, xOffset, yOffset)
    local castBar = CreateFrame("StatusBar", nil, UIParent)
    castBar:SetSize(156, 22)
    castBar:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    castBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    castBar:SetStatusBarColor(1, 0.7, 0)
    
    -- Store the frame index
    castBar.frameIndex = frameIndex
    
    local bg = castBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(castBar)
    bg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Border
    local border = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", castBar, "TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 2, -2)
    border:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 12 })
    border:SetBackdropBorderColor(180/255, 185/255, 190/255, 1)
    castBar.border = border
    
    local castText = castBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    castText:SetPoint("CENTER", castBar, "CENTER")
    castText:SetTextColor(1, 1, 1, 1)
    castBar.castText = castText
    
    local castIcon = castBar:CreateTexture(nil, "ARTWORK")
    castIcon:SetSize(24, 24)
    castIcon:SetPoint("RIGHT", castBar, "LEFT", castIconXOffset, 0)
    castBar.castIcon = castIcon
    
    -- Add the spark texture
    local spark = castBar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetSize(32, 32)  -- Typically the spark is slightly taller than the bar
    spark:SetBlendMode("ADD")
    spark:SetPoint("CENTER", castBar, "LEFT", 0, 0)  -- Initial position, will be updated dynamically
    castBar.spark = spark
    
    -- Update function
    function castBar:UpdateUnit()
        local unit = GetAppropriateUnit(self.frameIndex)
        if ShouldShowUnit(unit) then
            -- Unit exists, update casting information
            local name, _, icon, startTime, endTime = UnitCastingInfo(unit)
            if name then
                self.startTime = startTime
                self.endTime = endTime
                self:SetMinMaxValues(0, endTime - startTime)
                self.castText:SetText(name)
                self.castIcon:SetTexture(icon)
                
                self:SetScript("OnUpdate", function(self)
                    local currentTime = GetTime() * 1000
                    local progress = currentTime - startTime
                    
                    if progress >= (endTime - startTime) then
                        self:SetValue(endTime - startTime)
                        self:SetScript("OnUpdate", nil)
                        self:Hide()
                    else
                        self:SetValue(progress)
                        
                        -- Update spark position based on progress
                        local barWidth = self:GetWidth()
                        local position = (progress / (endTime - startTime)) * barWidth
                        self.spark:SetPoint("CENTER", self, "LEFT", position, 0)
                    end
                end)
                
                self:Show()
            else
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end
        else
            -- Unit doesn't exist, hide the cast bar
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end
    
    castBar:Hide()
    return castBar
end

-- Create cast bars for arena1, arena2, and arena3
local castBars = {
    CreateCastBar(1, 476, 12),   -- arena1/player test
    CreateCastBar(2, 476, -59),  -- arena2/player test
    CreateCastBar(3, 476, -129)  -- arena3/player test
}

-- Store cast bars in addon namespace for access from other modules
MyAddon.castBars = castBars

-- Function to update all cast bars
local function UpdateCastBars()
    for _, castBar in ipairs(castBars) do
        castBar:UpdateUnit()
    end
end

-- Register event listener
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ARENA_OPPONENT_UPDATE")

frame:SetScript("OnEvent", function(self, event, arg1)
    -- For arena specific events, update all bars
    if event == "ARENA_OPPONENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        UpdateCastBars()
        return
    end
    
    -- For unit specific events, update the appropriate bar
    for _, castBar in ipairs(castBars) do
        local unit = GetAppropriateUnit(castBar.frameIndex)
        if arg1 == unit then
            castBar:UpdateUnit()
        end
    end
end)

-- Hook into the existing test mode
if MyAddon.ToggleTestMode then
    local originalToggleTestMode = MyAddon.ToggleTestMode
    MyAddon.ToggleTestMode = function(self)
        originalToggleTestMode(self)
        UpdateCastBars()
    end
end