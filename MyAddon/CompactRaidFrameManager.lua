-- RaidFrameFade.lua
-- Adds fade functionality to the CompactRaidFrameManager

local addonName, addon = ...
addon.RaidFrameFade = {}

-- Configuration
local CONFIG = {
    -- Timing settings
    initialDelay = 0,         -- Time in seconds before starting to fade
    fadeDuration = 2,         -- Duration of the fade animation in seconds
    
    -- Alpha values
    startAlpha = 1.0,         -- Starting alpha value (fully visible)
    endAlpha = 0,          -- End alpha value (nearly invisible)
    
    -- Debug
    debug = false             -- Enable debug output
}

-- Debug print function
local function DebugPrint(...)
    if CONFIG.debug then
        print("|cFF33FF99RaidFrameFade:|r", ...)
    end
end

-- Create main module frame
local fadeFrame = CreateFrame("Frame", "RaidFrameFade")

-- Track mouseOver state
local isMouseOver = false

-- Table of frame elements to fade
local frameElements = {
    "CompactRaidFrameManagerBg",
    "CompactRaidFrameManagerBorderRight",
    "CompactRaidFrameManagerBorderBottomRight",
    "CompactRaidFrameManagerBorderTopRight"
}

-- Timer IDs for cancellation
local fadeInTimer = nil
local fadeOutTimer = nil
local initialDelayTimer = nil

-- Apply alpha to all frame elements
local function SetFramesAlpha(alpha)
    for _, elementName in ipairs(frameElements) do
        local element = _G[elementName]
        if element then
            element:SetAlpha(alpha)
        end
    end
    
    -- Special handling for the toggle button
    local toggleButton = CompactRaidFrameManagerToggleButton
    if toggleButton then
        toggleButton:SetAlpha(alpha)
    end
    
    DebugPrint("Set frames alpha to", alpha)
end

-- Start fading out the frames
local function StartFadeOut()
    -- Cancel any existing fade timers to prevent conflicts
    if fadeInTimer then
        fadeInTimer:Cancel()
        fadeInTimer = nil
    end
    
    if fadeOutTimer then
        fadeOutTimer:Cancel()
        fadeOutTimer = nil
    end
    
    DebugPrint("Starting fade out")
    
    -- Get the current alpha value
    local currentAlpha = CONFIG.startAlpha
    if CompactRaidFrameManagerBg then
        currentAlpha = CompactRaidFrameManagerBg:GetAlpha()
    end
    
    -- Create animation ticker
    local startTime = GetTime()
    local endTime = startTime + CONFIG.fadeDuration
    
    fadeOutTimer = C_Timer.NewTicker(0.01, function(self)
        local now = GetTime()
        
        -- Calculate progress (0 to 1)
        local progress = (now - startTime) / CONFIG.fadeDuration
        
        if progress >= 1 then
            -- Animation complete
            SetFramesAlpha(CONFIG.endAlpha)
            self:Cancel()
            fadeOutTimer = nil
            return
        end
        
        -- Calculate current alpha using smooth transition
        local currentAlpha = currentAlpha - (progress * (currentAlpha - CONFIG.endAlpha))
        
        -- Apply to frames
        SetFramesAlpha(currentAlpha)
    end)
end

-- Start fading in the frames (immediately)
local function StartFadeIn()
    -- Cancel any existing fade timers to prevent conflicts
    if fadeOutTimer then
        fadeOutTimer:Cancel()
        fadeOutTimer = nil
    end
    
    if fadeInTimer then
        fadeInTimer:Cancel()
        fadeInTimer = nil
    end
    
    DebugPrint("Showing frames immediately")
    
    -- Set to full alpha immediately
    SetFramesAlpha(CONFIG.startAlpha)
end

-- Add MouseOver detection to the CompactRaidFrameManager
local function SetupMouseTracking()
    -- Create a larger hitbox for mouse detection that covers all the elements we're fading
    local mouseFrame = CreateFrame("Frame", nil, CompactRaidFrameManager)
    mouseFrame:SetFrameStrata("BACKGROUND")
    mouseFrame:SetFrameLevel(1) -- Behind other elements
    
    -- Size the frame to cover the entire manager area plus some padding
    mouseFrame:SetPoint("TOPLEFT", CompactRaidFrameManager, "TOPLEFT", -10, 10)
    mouseFrame:SetPoint("BOTTOMRIGHT", CompactRaidFrameManager, "BOTTOMRIGHT", 10, -10)
    
    -- Make the frame mouse-enabled but click-through
    mouseFrame:EnableMouse(true)
    mouseFrame:SetScript("OnEnter", function()
        isMouseOver = true
        StartFadeIn()
        DebugPrint("Mouse entered frame area")
    end)
    
    mouseFrame:SetScript("OnLeave", function()
        isMouseOver = false
        -- Schedule fade out after a small delay to allow for brief mouse exits
        C_Timer.After(0.5, function()
            if not isMouseOver then
                StartFadeOut()
            end
        end)
        DebugPrint("Mouse left frame area")
    end)
    
    -- Also track mouse on the toggle button
    local toggleButton = CompactRaidFrameManagerToggleButton
    if toggleButton then
        toggleButton:HookScript("OnEnter", function()
            isMouseOver = true
            StartFadeIn()
            DebugPrint("Mouse entered toggle button")
        end)
        
        toggleButton:HookScript("OnLeave", function()
            isMouseOver = false
            -- Schedule fade out after a small delay to allow for brief mouse exits
            C_Timer.After(0.5, function()
                if not isMouseOver then
                    StartFadeOut()
                end
            end)
            DebugPrint("Mouse left toggle button")
        end)
    end
    
    DebugPrint("Mouse tracking set up")
end

-- Initialize module
local function Initialize()
    DebugPrint("Initializing RaidFrameFade")
    
    -- Wait until the raid frame elements are created
    if not CompactRaidFrameManager then
        DebugPrint("CompactRaidFrameManager not found, waiting...")
        C_Timer.After(1, Initialize)
        return
    end
    
    -- Set up mouse tracking
    SetupMouseTracking()
    
    -- Set initial alpha to fully visible
    SetFramesAlpha(CONFIG.startAlpha)
    
    -- Schedule initial fade out
    if initialDelayTimer then
        initialDelayTimer:Cancel()
    end
    
    initialDelayTimer = C_Timer.NewTimer(CONFIG.initialDelay, function()
        if not isMouseOver then
            StartFadeOut()
        end
        initialDelayTimer = nil
    end)
    
    DebugPrint("Initialization complete")
end

-- Event handling
fadeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
fadeFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
fadeFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- After combat

fadeFrame:SetScript("OnEvent", function(self, event, ...)
    DebugPrint("Event:", event)
    
    if event == "PLAYER_ENTERING_WORLD" then
        -- Initialize on first login/reload
        C_Timer.After(1, Initialize)
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- When joining or leaving a group
        SetFramesAlpha(CONFIG.startAlpha)
        
        -- Cancel any existing timers
        if initialDelayTimer then
            initialDelayTimer:Cancel()
            initialDelayTimer = nil
        end
        
        -- Start new delay timer for fading
        initialDelayTimer = C_Timer.NewTimer(CONFIG.initialDelay, function()
            if not isMouseOver then
                StartFadeOut()
            end
            initialDelayTimer = nil
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- After combat, check if we should fade
        if not isMouseOver then
            -- Start fade out with a small delay
            C_Timer.After(0.5, function()
                if not isMouseOver then
                    StartFadeOut()
                end
            end)
        end
    end
end)

-- Add slash command for configuration
SLASH_RAIDFADE1 = "/raidfade"
SlashCmdList["RAIDFADE"] = function(msg)
    local cmd, arg = string.match(msg, "^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    
    if cmd == "debug" then
        CONFIG.debug = not CONFIG.debug
        print("RaidFrameFade: Debug mode " .. (CONFIG.debug and "enabled" or "disabled"))
    elseif cmd == "fade" then
        StartFadeOut()
        print("RaidFrameFade: Force fading out")
    elseif cmd == "show" then
        StartFadeIn()
        print("RaidFrameFade: Force fading in")
    elseif cmd == "delay" and tonumber(arg) then
        CONFIG.initialDelay = tonumber(arg)
        print("RaidFrameFade: Initial delay set to " .. CONFIG.initialDelay .. " seconds")
    elseif cmd == "duration" and tonumber(arg) then
        CONFIG.fadeDuration = tonumber(arg)
        print("RaidFrameFade: Fade duration set to " .. CONFIG.fadeDuration .. " seconds")
    elseif cmd == "alpha" and tonumber(arg) then
        CONFIG.endAlpha = tonumber(arg)
        print("RaidFrameFade: End alpha set to " .. CONFIG.endAlpha)
    else
        print("RaidFrameFade commands:")
        print("  /raidfade debug - Toggle debug mode")
        print("  /raidfade fade - Force fade out")
        print("  /raidfade show - Force fade in")
        print("  /raidfade delay <seconds> - Set initial delay")
        print("  /raidfade duration <seconds> - Set fade duration")
        print("  /raidfade alpha <0-1> - Set end alpha value")
    end
end

-- Export public API
addon.RaidFrameFade = {
    FadeIn = StartFadeIn,
    FadeOut = StartFadeOut,
    SetAlpha = SetFramesAlpha,
    GetConfig = function() return CONFIG end,
    SetConfig = function(newConfig)
        for k, v in pairs(newConfig) do
            CONFIG[k] = v
        end
    end
}