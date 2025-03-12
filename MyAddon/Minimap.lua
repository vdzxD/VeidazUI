local addonName, MyAddon = ...

-- Initialize the MinimapFadeToggle module in the addon namespace
MyAddon.MinimapFadeToggle = MyAddon.MinimapFadeToggle or {}
local MinimapFadeToggle = MyAddon.MinimapFadeToggle

-- Configuration
local CONFIG = {
    -- Timing settings
    initialDelay = 2.0,      -- Delay after login before starting to fade (seconds)
    fadeDuration = 1.5,      -- Duration of the fade animation in seconds
    delayBeforeHide = 0.5,   -- Delay after fade completes before hiding elements
    
    -- Alpha values
    startAlpha = 1.0,        -- Starting alpha value (fully visible)
    endAlpha = 0.05,         -- End alpha value before hiding elements
    
    -- Mouse detection
    detectRadius = 40,       -- Extra pixels around Minimap to detect mouse movement
    
    -- Debug
    debug = false            -- Enable debug output
}

-- Debug print function
local function DebugPrint(...)
    if CONFIG.debug then
        print("|cFF33FF99MinimapFadeToggle:|r", ...)
    end
end

-- Variables for tracking state
local isMouseOver = false
local isFadingOut = false
local isFadingIn = false
local isHidden = false
local fadeTimer = nil
local hideTimer = nil
local initialDelayTimer = nil

-- List of standard minimap elements to manage
local minimapElements = {
    MinimapBorder,
    MinimapZoomIn,
    MinimapZoomOut,
    MiniMapTracking,
    MiniMapMailFrame,
    MiniMapBattlefieldFrame,
    MiniMapWorldMapButton,
    GameTimeFrame,
    TimeManagerClockButton,
    MinimapZoneTextButton,
    MiniMapInstanceDifficulty,
    GuildInstanceDifficulty,
    MiniMapChallengeMode,
    -- Add any other standard elements here
}

-- Function to set alpha for the minimap and all its elements
function MinimapFadeToggle:SetMinimapAlpha(alpha)
    -- Set alpha for the main minimap
    Minimap:SetAlpha(alpha)
    
    -- Set alpha for all standard elements
    for _, element in ipairs(minimapElements) do
        if element then
            element:SetAlpha(alpha)
        end
    end
    
    -- Handle all children of the minimap
    for _, child in ipairs({Minimap:GetChildren()}) do
        if child:IsObjectType("Frame") or child:IsObjectType("Button") then
            child:SetAlpha(alpha)
        end
    end
    
    DebugPrint("Set minimap alpha to", alpha)
end

-- Function to fully show the minimap and all its elements
function MinimapFadeToggle:ShowMinimap(skipAnimation)
    -- Cancel any ongoing animations
    if fadeTimer then
        fadeTimer:Cancel()
        fadeTimer = nil
    end
    
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
    
    -- If elements are hidden, we need to show them first
    if isHidden then
        self:RestoreMinimapElements()
        isHidden = false
    end
    
    if skipAnimation then
        -- Set to full alpha immediately
        self:SetMinimapAlpha(CONFIG.startAlpha)
        isFadingIn = false
        isFadingOut = false
        return
    end
    
    -- Start fade-in animation
    isFadingIn = true
    isFadingOut = false
    
    local startTime = GetTime()
    local startAlpha = Minimap:GetAlpha()
    
    fadeTimer = C_Timer.NewTicker(0.01, function(self)
        local now = GetTime()
        local progress = (now - startTime) / CONFIG.fadeDuration
        
        if progress >= 1 then
            -- Animation complete
            MinimapFadeToggle:SetMinimapAlpha(CONFIG.startAlpha)
            isFadingIn = false
            self:Cancel()
            fadeTimer = nil
            return
        end
        
        -- Calculate current alpha
        local currentAlpha = startAlpha + (progress * (CONFIG.startAlpha - startAlpha))
        MinimapFadeToggle:SetMinimapAlpha(currentAlpha)
    end)
end

-- Function to hide all minimap elements (after fade completes)
function MinimapFadeToggle:HideMinimapElements()
    -- Hide the main minimap
    Minimap:Hide()
    
    -- Hide all standard elements
    for _, element in ipairs(minimapElements) do
        if element then
            if element:IsShown() then
                element.wasShown = true
                element:Hide()
            end
        end
    end
    
    -- Store visibility state and hide all children
    for _, child in ipairs({Minimap:GetChildren()}) do
        if child:IsShown() then
            child.wasShown = true
            child:Hide()
        end
    end
    
    isHidden = true
    DebugPrint("Hid all minimap elements")
end

-- Function to restore all minimap elements when showing
function MinimapFadeToggle:RestoreMinimapElements()
    -- Show the main minimap
    Minimap:Show()
    
    -- Restore all standard elements
    for _, element in ipairs(minimapElements) do
        if element and element.wasShown then
            element:Show()
            element.wasShown = nil
        end
    end
    
    -- Restore all children
    for _, child in ipairs({Minimap:GetChildren()}) do
        if child.wasShown then
            child:Show()
            child.wasShown = nil
        end
    end
    
    -- Ensure the player arrow is visible
    Minimap:SetPlayerTexture("Interface\\MinimapArrow\\MinimapArrow")
    
    isHidden = false
    DebugPrint("Restored all minimap elements")
end

-- Function to start fading out the minimap
function MinimapFadeToggle:FadeOutMinimap()
    -- Cancel any ongoing animations
    if fadeTimer then
        fadeTimer:Cancel()
        fadeTimer = nil
    end
    
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
    
    -- If already hidden, nothing to do
    if isHidden then
        return
    end
    
    -- Start fade-out animation
    isFadingOut = true
    isFadingIn = false
    
    local startTime = GetTime()
    local startAlpha = Minimap:GetAlpha()
    
    fadeTimer = C_Timer.NewTicker(0.01, function(self)
        local now = GetTime()
        local progress = (now - startTime) / CONFIG.fadeDuration
        
        if progress >= 1 then
            -- Animation complete - set to minimum alpha
            MinimapFadeToggle:SetMinimapAlpha(CONFIG.endAlpha)
            isFadingOut = false
            self:Cancel()
            fadeTimer = nil
            
            -- Schedule element hiding after reaching minimum alpha
            hideTimer = C_Timer.NewTimer(CONFIG.delayBeforeHide, function()
                if not isMouseOver and not isFadingIn then
                    MinimapFadeToggle:HideMinimapElements()
                end
                hideTimer = nil
            end)
            
            return
        end
        
        -- Calculate current alpha
        local currentAlpha = startAlpha - (progress * (startAlpha - CONFIG.endAlpha))
        MinimapFadeToggle:SetMinimapAlpha(currentAlpha)
    end)
end

-- Setup mouse over detection area (making it larger than the Minimap for easier discovery)
local function CreateMouseOverDetector()
    local detector = CreateFrame("Frame", "MinimapMouseDetector", UIParent)
    
    -- The Minimap is circular but has a square frame, so we'll create a slightly larger frame
    local minimapRadius = Minimap:GetWidth() / 2
    local detectorSize = (minimapRadius + CONFIG.detectRadius) * 2
    detector:SetSize(detectorSize, detectorSize)
    detector:SetPoint("CENTER", Minimap, "CENTER")
    
    -- Make it invisible and don't capture mouse events
    detector:SetFrameStrata("BACKGROUND")
    detector:EnableMouse(false)
    
    -- Optional: Add a visual indicator during development
    if CONFIG.debug then
        local texture = detector:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints()
        texture:SetColorTexture(1, 0, 0, 0.2)
    end
    
    MinimapFadeToggle.detector = detector
    return detector
end

-- Setup mouse tracking
local function SetupMouseTracking()
    -- Create a detector frame to check when the mouse is over the area
    local detector = CreateMouseOverDetector()
    
    -- Create a frame to track mouse position
    local mouseMoveDetector = CreateFrame("Frame")
    MinimapFadeToggle.mouseMoveDetector = mouseMoveDetector
    
    mouseMoveDetector:SetScript("OnUpdate", function(self, elapsed)
        -- Use direct cursor position check
        local mouseX, mouseY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        mouseX, mouseY = mouseX / scale, mouseY / scale
        
        -- Get the detector frame position
        local detectorCenterX, detectorCenterY = detector:GetCenter()
        if not detectorCenterX then return end
        
        -- Calculate distance from center of detector to cursor
        local distance = sqrt((mouseX - detectorCenterX)^2 + (mouseY - detectorCenterY)^2)
        local radius = detector:GetWidth() / 2
        
        -- Check if mouse is within the detector's radius
        local wasMouseOver = isMouseOver
        isMouseOver = (distance <= radius)
        
        -- Handle mouse state change
        if isMouseOver and not wasMouseOver then
            -- Mouse entered the detection area
            DebugPrint("Mouse entered minimap area")
            MinimapFadeToggle:ShowMinimap(true) -- Show immediately
        elseif not isMouseOver and wasMouseOver then
            -- Mouse left the detection area
            DebugPrint("Mouse left minimap area")
            -- Small delay to prevent flickering when moving mouse quickly
            C_Timer.After(0.1, function()
                if not isMouseOver then
                    MinimapFadeToggle:FadeOutMinimap()
                end
            end)
        end
    end)
end

-- Initialize the module
function MinimapFadeToggle:Initialize()
    -- Set up mouse tracking
    SetupMouseTracking()
    
    -- Set initial alpha to fully visible
    self:SetMinimapAlpha(CONFIG.startAlpha)
    
    -- Schedule initial fade out
    if initialDelayTimer then
        initialDelayTimer:Cancel()
    end
    
    initialDelayTimer = C_Timer.NewTimer(CONFIG.initialDelay, function()
        if not isMouseOver then
            self:FadeOutMinimap()
        end
        initialDelayTimer = nil
    end)
    
  
    

end

-- Create a loading mechanism
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

loadFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Initialize the module after the UI is loaded
        C_Timer.After(1, function()
            MinimapFadeToggle:Initialize()
        end)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        -- When changing zones, ensure minimap state is correct
        C_Timer.After(1, function()
            if isHidden and isMouseOver then
                MinimapFadeToggle:ShowMinimap(true)
            elseif not isHidden and not isMouseOver then
                MinimapFadeToggle:FadeOutMinimap()
            end
        end)
    end
end)

-- Export public API
MyAddon.MinimapFadeToggle = {
    Show = function(skipAnimation) MinimapFadeToggle:ShowMinimap(skipAnimation) end,
    Hide = function() MinimapFadeToggle:FadeOutMinimap() end,
    Toggle = function() 
        if isHidden or isFadingOut then
            MinimapFadeToggle:ShowMinimap(true)
        else
            MinimapFadeToggle:FadeOutMinimap()
        end
    end,
    GetConfig = function() return CONFIG end,
    SetConfig = function(newConfig)
        for k, v in pairs(newConfig) do
            CONFIG[k] = v
        end
    end
}