--[[
    VeiPlatesBeauty.lua - Visual enhancements for VeiPlates
    
    This module adds aesthetic enhancements to VeiPlates without modifying core functionality:
    - Custom borders using atlas textures
    - Enhanced visual effects and transitions
    - Target and mouseover highlights with custom textures
    - Theme support for unified visual style
]]

-- Add a debug flag at the top for troubleshooting
local DEBUG_MODE = false

local addonName, core = ...
local VeiPlates = core.VeiPlates
local VeiPlatesBeauty = {}
core.VeiPlatesBeauty = VeiPlatesBeauty

-- Cache frequently used functions
local pairs = pairs
local ipairs = ipairs
local max = math.max
local min = math.min
local tinsert = table.insert
local format = string.format
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitGUID = UnitGUID
local GetTime = GetTime

-- Internal tracking
local hookCount = 0

-- =======================================
-- CONFIGURATION OPTIONS
-- =======================================
local CONFIG = {
    -- Global settings
    debug = DEBUG_MODE,  -- Enable debug output
    
    -- Border settings
    border = {
        enabled = true,
        atlas = "Capacitance-Blacksmithing-TimerFrame", -- Primary atlas texture
        fallbackAtlas = "UI-Frame-GenericTemplate-Border",
        fallbackTexture = "Interface\\Tooltips\\UI-Tooltip-Border",
        scale = 2,  -- Border is 20% larger than health bar 
        alpha = 1.0,
        color = { r = 1, g = 1, b = 1, a = 1 },
        xOffset = 0,
        yOffset = 0,
        
        -- Keep these for fallback compatibility
    
    },
    
    -- Target highlight
    targetHighlight = {
        enabled = true,
        atlas = "UI-HUD-UnitFrame-Target-PortraitOn-Type", -- Atlas texture for target highlight
        fallbackTexture = "Interface\\TargetingFrame\\UI-TargetingFrame-Flash",
        color = { r = 0.1, g = 0.5, b = 1, a = 1.0 },  -- White color with low alpha instead of gold
        scale = 1.1,     -- Scale multiplier for target
        glowEffect = false,  -- Turn off glow effect
        pulseEffect = false, -- Turn off pulse effect
        pulseSpeed = 1.5 -- Seconds per pulse cycle
    },
    
    -- Mouseover highlight
    mouseoverHighlight = {
        enabled = true,
        color = { r = 0.5, g = 0.5, b = 1, a = 0.1 },  -- White highlight
        glowEffect = false
    },
    
    -- Health bar styling
    healthBar = {
        texture = "Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga", -- Custom texture
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
        enemyColor = { r = 0.8, g = 0.2, b = 0.2 },     -- Red for enemies
        neutralColor = { r = 0.9, g = 0.7, b = 0 },     -- Orange for neutral
        friendlyColor = { r = 0.2, g = 0.8, b = 0.2 },  -- Green for friendly
        tappedColor = { r = 0.5, g = 0.5, b = 0.5 }    -- Gray for tapped
    },
    
    -- Cast bar styling
    castBar = {
        border = {
            enabled = true,
            atlas = "UI-Frame-Bar-Border-SM",
            color = { r = 1, g = 1, b = 1 }
        },
        texture = "Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga",
        castingColor = { r = 1, g = 0.7, b = 0 },        -- Standard cast color
        channelColor = { r = 0, g = 0.7, b = 1 },        -- Channel cast color
        interruptedColor = { r = 1, g = 0.3, b = 0.2 },  -- Interrupted cast
        nonInterruptibleColor = { r = 0.7, g = 0.7, b = 0.7 } -- Non-interruptible
    },
    
    -- Transitions and animations
    animations = {
        enabled = true,
        fadeInTime = 0.2,
        fadeOutTime = 0.3,
        smoothUpdates = true
    }
}

-- =======================================
-- UTILITY FUNCTIONS
-- =======================================
-- Helper function to debug frame positions
local function DebugDrawFrame(frame, color, duration)
    if not frame then return end
    
    -- Create a debug texture if it doesn't exist
    if not frame.debugTexture then
        frame.debugTexture = frame:CreateTexture(nil, "OVERLAY")
        frame.debugTexture:SetAllPoints(frame)
        frame.debugTexture:SetColorTexture(color.r or 1, color.g or 0, color.b or 0, color.a or 0.5)
    else
        frame.debugTexture:SetAllPoints(frame)
        frame.debugTexture:SetColorTexture(color.r or 1, color.g or 0, color.b or 0, color.a or 0.5)
    end
    
    frame.debugTexture:Show()
    
    -- Hide after duration
    C_Timer.After(duration or 5, function()
        if frame.debugTexture then
            frame.debugTexture:Hide()
        end
    end)
end

-- Safe texture setting that tries atlas textures first, then falls back
local function SetAtlasOrTexture(textureObj, atlasName, fallbackAtlas, fallbackTexture)
    if not textureObj then return false end
    
    -- Try to set the primary atlas
    local success = pcall(function() 
        textureObj:SetAtlas(atlasName)
    end)
    
    -- If that fails, try the fallback atlas
    if not success and fallbackAtlas then
        success = pcall(function() 
            textureObj:SetAtlas(fallbackAtlas)
        end)
    end
    
    -- If atlas attempts fail, use the fallback texture
    if not success and fallbackTexture then
        textureObj:SetTexture(fallbackTexture)
        return false
    end
    
    return success
end

-- Apply colors to a texture object
local function ApplyTextureColor(textureObj, color)
    if not textureObj or not color then return end
    
    textureObj:SetVertexColor(
        color.r or 1, 
        color.g or 1, 
        color.b or 1, 
        color.a or 1
    )
end





-- Convenience function to create a texture with atlas (with fallbacks)
local function CreateAtlasTexture(parent, layer, atlas, fallbackAtlas, fallbackTexture)
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    SetAtlasOrTexture(texture, atlas, fallbackAtlas, fallbackTexture)
    return texture
end

-- Create a simple animation for a texture
local function CreatePulseAnimation(frame, speed, minAlpha, maxAlpha)
    local animGroup = frame:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")
    
    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(maxAlpha or 1.0)
    fadeOut:SetToAlpha(minAlpha or 0.3)
    fadeOut:SetDuration(speed / 2)
    fadeOut:SetOrder(1)
    
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(minAlpha or 0.3)
    fadeIn:SetToAlpha(maxAlpha or 1.0)
    fadeIn:SetDuration(speed / 2)
    fadeIn:SetOrder(2)
    
    return animGroup
end

-- =======================================
-- PLATE FINDING AND ACCESS
-- =======================================
-- Create a custom finder function to get all plates safely
function VeiPlatesBeauty:FindAllPlatesInGame()
    local plates = {}
    local count = 0
    
    -- Approach 1: Check if we have direct access to the Plates table in VeiPlatesCore
    -- This is more reliable since it contains ALL created plates, not just currently visible ones
    if core.VeiPlatesCore and core.VeiPlatesCore.Plates then
        for namePlate, plate in pairs(core.VeiPlatesCore.Plates) do
            if plate and plate.health and plate.unitID and UnitExists(plate.unitID) then
                plates[plate.unitID] = plate
                count = count + 1
            end
        end
        
        if count > 0 and CONFIG.debug then
            print("VeiPlatesBeauty: Found " .. count .. " plates using VeiPlatesCore.Plates")
            return plates, count
        end
    end
    
    -- Approach 2: Try to access PlatesByUnit from VeiPlatesCore
    if core.VeiPlatesCore and core.VeiPlatesCore.PlatesByUnit then
        for unitID, plate in pairs(core.VeiPlatesCore.PlatesByUnit) do
            if plate and plate.health and UnitExists(unitID) then
                plates[unitID] = plate
                count = count + 1
            end
        end
        
        if count > 0 and CONFIG.debug then
          --  print("VeiPlatesBeauty: Found " .. count .. " plates using VeiPlatesCore.PlatesByUnit")
            return plates, count
        end
    end
    
    -- Approach 3: Try to access PlatesByUnit from VeiPlates directly
    if core.VeiPlates and core.VeiPlates.PlatesByUnit then
        for unitID, plate in pairs(core.VeiPlates.PlatesByUnit) do
            if plate and plate.health and UnitExists(unitID) then
                plates[unitID] = plate
                count = count + 1
            end
        end
        
        if count > 0 and CONFIG.debug then
           -- print("VeiPlatesBeauty: Found " .. count .. " plates using VeiPlates.PlatesByUnit")
            return plates, count
        end
    end
    
    -- Approach 4: Fall back to scanning all nameplate units directly
    for i = 1, 40 do
        local unitID = "nameplate" .. i
        if UnitExists(unitID) then
            local namePlate = C_NamePlate.GetNamePlateForUnit(unitID)
            if namePlate then
                -- Look for our custom plate in all possible places
                local foundPlate = nil
                
                -- First check if we can get it through core.VeiPlates mechanisms
                if core.VeiPlates.GetPlateByUnit then
                    foundPlate = core.VeiPlates:GetPlateByUnit(unitID)
                end
                
                -- If not found, check if it's stored directly on the Blizzard nameplate
                if not foundPlate and namePlate.VeiPlate then
                    foundPlate = namePlate.VeiPlate
                end
                
                -- Check if Blizzard plate is the key in our Plates table
                if not foundPlate and core.VeiPlatesCore and core.VeiPlatesCore.Plates and core.VeiPlatesCore.Plates[namePlate] then
                    foundPlate = core.VeiPlatesCore.Plates[namePlate]
                end
                
                -- Check all children of the nameplate for VeiPlates elements
                if not foundPlate then
                    for _, child in ipairs({namePlate:GetChildren()}) do
                        if child.VeiPlate then
                            foundPlate = child.VeiPlate
                            break
                        end
                    end
                end
                
                -- Only include plates that have the minimal structure we need
                if foundPlate and foundPlate.health then
                    plates[unitID] = foundPlate
                    count = count + 1
                end
            end
        end
    end
    
    -- if CONFIG.debug then
    --     print("VeiPlatesBeauty: Found " .. count .. " plates using direct nameplate scanning")
    -- end
    
    return plates, count
end

-- Set border padding (distance from the health bar edge)
function VeiPlatesBeauty:SetBorderPadding(padding)
    CONFIG.border.padding = padding
    self:ProcessAllPlates()
    return padding
end

-- Set border position offset
function VeiPlatesBeauty:SetBorderOffset(xOffset, yOffset)
    CONFIG.border.xOffset = xOffset
    CONFIG.border.yOffset = yOffset
    self:ProcessAllPlates()
    return xOffset, yOffset
end

-- Make sure we update borders when plate size changes
function VeiPlatesBeauty:UpdateBorderSize(plate)
    if not plate or not plate.borderFrame or not plate.health then return end
    
    -- Get the health bar size
    local healthWidth, healthHeight = plate.health:GetSize()
    
    -- Calculate border size with padding
    local borderWidth = healthWidth + (CONFIG.border.padding or 7.5) -- THIS ADJUSTS BORDER SIZE
    local borderHeight = healthHeight + (CONFIG.border.padding or 10) -- THIS ADJUSTS BORDER SIZE
    
    -- Update border frame size
    plate.borderFrame:SetSize(borderWidth, borderHeight)
    
    -- Reposition the border with current offsets
    plate.borderFrame:ClearAllPoints()
    plate.borderFrame:SetPoint("CENTER", plate.health, "CENTER", 
                             CONFIG.border.xOffset or 0, 
                             CONFIG.border.yOffset or 0)
end

-- =======================================
-- BORDER CREATION AND MANAGEMENT
-- =======================================
-- Create atlas borders for a plate
function VeiPlatesBeauty:CreateBorders(plate)
    if not plate or plate.beautified then return end
    
    -- Clean up any existing border
    if plate.borderFrame then
        plate.borderFrame:Hide()
        plate.borderFrame = nil
    end
    
    -- -- Debug info if needed
    -- if CONFIG.debug then
    --     print("Creating borders for plate:", plate:GetName() or "unnamed")
    -- end
    
    -- Create a container frame for the border
    local borderFrame = CreateFrame("Frame", nil, plate)
    
    -- Position it relative to the health bar
    local healthWidth, healthHeight = plate.health:GetSize()
    local borderScale = CONFIG.border.scale or 1.2  -- 20% larger than health bar by default
    
    -- Size the border based on health bar dimensions
    local borderWidth = healthWidth * borderScale
    local borderHeight = healthHeight * borderScale
    
    -- Set the size and position
    borderFrame:SetSize(borderWidth, borderHeight)
    borderFrame:SetPoint("CENTER", plate.health, "CENTER", 0, 0)
    
    -- Set the appropriate frame levels
    borderFrame:SetFrameStrata(plate:GetFrameStrata())
    borderFrame:SetFrameLevel(plate:GetFrameLevel() + 1)
    
    -- Create the border texture using atlas
    local borderTexture = borderFrame:CreateTexture(nil, "ARTWORK")
    borderTexture:SetAllPoints()
    borderTexture:SetAtlas("Capacitance-Blacksmithing-TimerFrame", true) -- true preserves texture aspect ratio
    borderTexture:SetDesaturated(true) -- Optional: makes it grayscale so color can be clearly applied
    
    -- Set color
    borderTexture:SetVertexColor(
        CONFIG.border.color.r or 1,
        CONFIG.border.color.g or 1, 
        CONFIG.border.color.b or 1,
        CONFIG.border.color.a or 1
    )
    
    -- Store references
    borderFrame.texture = borderTexture
    plate.borderFrame = borderFrame
    
    -- Mark as beautified
    plate.beautified = true
    
    -- Return the frame
    return borderFrame
end



-- =======================================
-- VISUAL STATE MANAGEMENT
-- =======================================
-- Update target highlight
function VeiPlatesBeauty:UpdateTargetHighlight(plate)
    if not plate or not plate.atlasHighlight then return end
    
    local isTarget = plate.isTarget
    local wasTarget = plate._wasTarget
    
    if isTarget and not wasTarget then
        -- Unit just became the target
        plate.atlasHighlight:Show()
        ApplyTextureColor(plate.atlasHighlight, CONFIG.targetHighlight.color)
        
        -- Start pulse animation if enabled
        if plate.targetPulse then
            plate.targetPulse:Play()
        end
        
        -- Hide the standard highlight if it exists
        if plate.highlight then
            plate.highlight:Hide()
        end
        
        plate._wasTarget = true
    elseif not isTarget and wasTarget then
        -- No longer the target
        plate.atlasHighlight:Hide()
        
        -- Stop pulse animation
        if plate.targetPulse and plate.targetPulse:IsPlaying() then
            plate.targetPulse:Stop()
        end
        
        -- Show mouseover highlight if needed
        if plate.isMouseOver and plate.highlight then
            plate.highlight:Show()
            plate.highlight:SetVertexColor(
                CONFIG.mouseoverHighlight.color.r,
                CONFIG.mouseoverHighlight.color.g,
                CONFIG.mouseoverHighlight.color.b,
                CONFIG.mouseoverHighlight.color.a
            )
        end
        
        plate._wasTarget = false
    end
end

-- Update cast bar border
function VeiPlatesBeauty:UpdateCastBarBorder(plate)
    if not plate or not plate.castBar then return end
    
    -- If the cast bar doesn't have a border yet, create one
    if not plate.castBar.borderFrame and CONFIG.castBar.border.enabled then
        local cbBorderFrame = CreateFrame("Frame", nil, plate.castBar)
        cbBorderFrame:SetFrameLevel(plate.castBar:GetFrameLevel() + 1)
        cbBorderFrame:SetAllPoints(plate.castBar)
        
        -- Create main border
        local castBorder = CreateAtlasTexture(
            cbBorderFrame, "OVERLAY", 
            CONFIG.castBar.border.atlas,
            nil,
            "Interface\\CastingBar\\UI-CastingBar-Border"
        )
        castBorder:SetAllPoints(cbBorderFrame)
        
        -- Apply color
        ApplyTextureColor(castBorder, CONFIG.castBar.border.color)
        
        -- Store the border
        plate.castBar.borderFrame = cbBorderFrame
        plate.castBar.border = castBorder
    end
    
    -- Update the border size to match the cast bar
    if plate.castBar.borderFrame then
        plate.castBar.borderFrame:SetAllPoints(plate.castBar)
    end
end

-- Apply custom colors to the health bar based on unit type
function VeiPlatesBeauty:UpdateHealthBarColors(plate)
    if not plate or not plate.health or not plate.unitID then return end
    
    local unitID = plate.unitID
    if not UnitExists(unitID) then return end
    
    -- Get unit information
    local isTapDenied = UnitIsTapDenied(unitID)
    local isPlayer = UnitIsPlayer(unitID)
    local reaction = UnitReaction(unitID, "player") or 4 -- Default to neutral
    local canAttack = UnitCanAttack("player", unitID)
    
    local color
    
    -- Determine color based on unit state
    if isTapDenied then
        color = CONFIG.healthBar.tappedColor
    elseif isPlayer then
        -- For players, use class color
        local _, class = UnitClass(unitID)
        if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
            color = RAID_CLASS_COLORS[class]
        elseif canAttack then
            color = CONFIG.healthBar.enemyColor
        else
            color = CONFIG.healthBar.friendlyColor
        end
    else
        -- For NPCs, use reaction-based color
        if reaction <= 2 then
            color = CONFIG.healthBar.enemyColor
        elseif reaction == 3 or reaction == 4 then
            color = CONFIG.healthBar.neutralColor
        else
            color = CONFIG.healthBar.friendlyColor
        end
    end
    
    -- Apply the color
    if color then
        plate.health:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
    end
end

-- Update cast bar color based on cast state
function VeiPlatesBeauty:UpdateCastBarColor(plate, castData)
    if not plate or not plate.castBar then return end
    
    local color
    
    if castData then
        if castData.interrupted then
            color = CONFIG.castBar.interruptedColor
        elseif castData.notInterruptible then
            color = CONFIG.castBar.nonInterruptibleColor
        elseif castData.isChanneled then
            color = CONFIG.castBar.channelColor
        else
            color = CONFIG.castBar.castingColor
        end
    else
        -- Default to standard cast color
        color = CONFIG.castBar.castingColor
    end
    
    -- Apply color
    if color then
        plate.castBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
    end
end

-- =======================================
-- PUBLIC API
-- =======================================
-- Expose configuration
function VeiPlatesBeauty:GetConfig()
    return CONFIG
end

-- Update configuration
function VeiPlatesBeauty:UpdateConfig(newConfig)
    for category, options in pairs(newConfig or {}) do
        if type(CONFIG[category]) == "table" and type(options) == "table" then
            for key, value in pairs(options) do
                CONFIG[category][key] = value
            end
        end
    end
    
    -- Apply changes
    self:ProcessAllPlates()
end

-- =======================================
-- PLATE PROCESSING AND MANAGEMENT
-- =======================================
-- Process a nameplate to add all visual enhancements
function VeiPlatesBeauty:ProcessPlate(plate)
    if not plate then return end
    
    -- Basic sanity check
    -- if not plate or not plate.health then
    --     if CONFIG.debug then
    --         print("VeiPlatesBeauty: Invalid plate or plate without health bar")
    --     end
    --     return
    -- end
    
    -- -- Debug info
    -- if CONFIG.debug then
    --     print("Processing plate: ", plate:GetName() or "unnamed", "Health:", plate.health:GetWidth(), "x", plate.health:GetHeight())
    -- end
    
    -- Create borders if they don't exist
    self:CreateBorders(plate)
    
    -- Update border size to match health bar
    self:UpdateBorderSize(plate)
    
    -- Update target highlight
    self:UpdateTargetHighlight(plate)
    
    -- Update health bar colors
    self:UpdateHealthBarColors(plate)
    
    -- Update cast bar border if the cast bar is visible
    if plate.castBar and plate.castBar:IsShown() then
        self:UpdateCastBarBorder(plate)
    end
end

-- Process all plates using our enhanced finder function
function VeiPlatesBeauty:ProcessAllPlates()
    local plates, count = self:FindAllPlatesInGame()
    
    -- Process each plate we found
    local processedCount = 0
    for unitID, plate in pairs(plates) do
        self:ProcessPlate(plate)
        processedCount = processedCount + 1
    end
    
    -- Debug output if enabled
    if CONFIG.debug then
        if processedCount == 0 then
        --    print("VeiPlatesBeauty: No plates found to process")
        else
        --    print("VeiPlatesBeauty: Processed " .. processedCount .. " plates")
        end
    end
end

function VeiPlatesBeauty:SetBorderScale(scale)
    CONFIG.border.scale = scale
  --  print("VeiPlatesBeauty: Border scale set to " .. scale)
    
    -- Force recreate all borders by marking them as not beautified
    local plates, _ = self:FindAllPlatesInGame()
    for _, plate in pairs(plates) do
        if plate.beautified then
            plate.beautified = nil
            if plate.borderFrame then
                plate.borderFrame:Hide()
                plate.borderFrame = nil
            end
        end
    end
    
    self:ProcessAllPlates()
end

-- =======================================
-- HOOK MANAGEMENT
-- =======================================
-- Hook into VeiPlates core functions
function VeiPlatesBeauty:HookIntoVeiPlates()
    -- First, check if we have access to the core objects
    if not core.VeiPlates then
     --   print("VeiPlatesBeauty: Cannot find VeiPlates object to hook")
        return false
    end
    
    local hookCount = 0
    
    -- Create and expose a PlateCreated callback for other modules to use
    if not core.VeiPlates.OnPlateCreated then
        core.VeiPlates.OnPlateCreated = function(plate) end
    end
    
    -- Create an exposed callback for plate updates
    if not core.VeiPlates.OnPlateUpdated then
        core.VeiPlates.OnPlateUpdated = function(plate) end
    end
    
    -- Create a way to expose the VeiPlatesCore.Plates table safely
    if not core.VeiPlates.GetAllPlates then
        core.VeiPlates.GetAllPlates = function()
            if core.VeiPlatesCore and core.VeiPlatesCore.Plates then
                return core.VeiPlatesCore.Plates
            else
                return {}
            end
        end
        
        hookCount = hookCount + 1
      --  print("VeiPlatesBeauty: Added GetAllPlates accessor function to VeiPlates")
    end
    
    -- Create a way to get plate by unit ID safely
    if not core.VeiPlates.GetPlateByUnit then
        core.VeiPlates.GetPlateByUnit = function(_, unitID)
            if core.VeiPlatesCore and core.VeiPlatesCore.PlatesByUnit then
                return core.VeiPlatesCore.PlatesByUnit[unitID]
            elseif core.VeiPlates.PlatesByUnit then
                return core.VeiPlates.PlatesByUnit[unitID]
            else
                return nil
            end
        end
        
        hookCount = hookCount + 1
       -- print("VeiPlatesBeauty: Added GetPlateByUnit accessor function to VeiPlates")
    end
    
    -- Hook into the main CreatePlate function in VeiPlatesCore if it exists
    if core.VeiPlatesCore and core.VeiPlatesCore.CreatePlate then
        local originalCreatePlate = core.VeiPlatesCore.CreatePlate
        
        core.VeiPlatesCore.CreatePlate = function(self, namePlate, ...)
            local plate = originalCreatePlate(self, namePlate, ...)
            
            -- Apply beautification with a slight delay to ensure all plate properties are set
            C_Timer.After(0.1, function()
                if plate then
                    VeiPlatesBeauty:ProcessPlate(plate)
                    -- Call the new OnPlateCreated callback
                    if core.VeiPlates.OnPlateCreated then
                        core.VeiPlates.OnPlateCreated(plate)
                    end
                end
            end)
            
            return plate
        end
        
        hookCount = hookCount + 1
      --  print("VeiPlatesBeauty: Hooked VeiPlatesCore.CreatePlate successfully")
    end
    
    -- Hook into AttachPlateToUnit function if it exists
    if core.VeiPlatesCore and core.VeiPlatesCore.AttachPlateToUnit then
        local originalAttachPlate = core.VeiPlatesCore.AttachPlateToUnit
        
        core.VeiPlatesCore.AttachPlateToUnit = function(self, unitID, ...)
            local result = originalAttachPlate(self, unitID, ...)
            
            -- Apply beautification after plate is attached to unit
            C_Timer.After(0.2, function()
                local plates = VeiPlatesBeauty:FindAllPlatesInGame()
                if plates[unitID] then
                    VeiPlatesBeauty:ProcessPlate(plates[unitID])
                    -- Call the OnPlateUpdated callback
                    if core.VeiPlates.OnPlateUpdated then
                        core.VeiPlates.OnPlateUpdated(plates[unitID])
                    end
                end
            end)
            
            return result
        end
        
        hookCount = hookCount + 1
     --   print("VeiPlatesBeauty: Hooked VeiPlatesCore.AttachPlateToUnit successfully")
    end
    
    -- Hook into existing target changed event
    if core.VeiPlatesCore and core.VeiPlatesCore.PLAYER_TARGET_CHANGED then
        local originalTargetChanged = core.VeiPlatesCore.PLAYER_TARGET_CHANGED
        
        core.VeiPlatesCore.PLAYER_TARGET_CHANGED = function(self, ...)
            originalTargetChanged(self, ...)
            
            -- Update all plates to ensure target highlighting works correctly
            C_Timer.After(0.05, function()
                VeiPlatesBeauty:ProcessAllPlates()
            end)
        end
        
        hookCount = hookCount + 1
     --   print("VeiPlatesBeauty: Hooked VeiPlatesCore.PLAYER_TARGET_CHANGED successfully")
    end
    
    -- Patch VeiPlates with direct references to our beautification functions
    core.VeiPlates.Beauty = {
        ProcessPlate = function(plate) VeiPlatesBeauty:ProcessPlate(plate) end,
        ProcessAllPlates = function() VeiPlatesBeauty:ProcessAllPlates() end,
        UpdateConfig = function(config) VeiPlatesBeauty:UpdateConfig(config) end,
        GetConfig = function() return VeiPlatesBeauty:GetConfig() end
    }
    
    hookCount = hookCount + 1
   -- print("VeiPlatesBeauty: Added Beauty API to VeiPlates")
    
  --  print("VeiPlatesBeauty: Successfully hooked " .. hookCount .. " functions")
    return hookCount > 0
end

-- =======================================
-- INITIALIZATION AND STARTUP
-- =======================================
function VeiPlatesBeauty:Initialize()
    -- Print initialization message
  --  print("VeiPlatesBeauty: Initializing...")
    
    -- if CONFIG.debug then
    --     -- Dump known VeiPlates structures for debugging
    --     print("VeiPlates structures:")
    --     print("  VeiPlates directly accessible:", VeiPlates ~= nil)
    --     print("  core.VeiPlates accessible:", core and core.VeiPlates ~= nil)
    --     print("  core.VeiPlatesCore accessible:", core and core.VeiPlatesCore ~= nil)
        
    --     -- Look for all possible places the nameplates data might be stored
    --     if core and core.VeiPlates then
    --         print("  core.VeiPlates.PlatesVisible:", core.VeiPlates.PlatesVisible ~= nil)
    --         print("  core.VeiPlates.PlatesByUnit:", core.VeiPlates.PlatesByUnit ~= nil)
    --         print("  core.VeiPlates.PlatesByGUID:", core.VeiPlates.PlatesByGUID ~= nil)
    --     end
        
    --     if core and core.VeiPlatesCore then
    --         print("  core.VeiPlatesCore.Plates:", core.VeiPlatesCore.Plates ~= nil)
    --         print("  core.VeiPlatesCore.PlatesVisible:", core.VeiPlatesCore.PlatesVisible ~= nil)
    --         print("  core.VeiPlatesCore.PlatesByUnit:", core.VeiPlatesCore.PlatesByUnit ~= nil)
    --         print("  core.VeiPlatesCore.PlatesByGUID:", core.VeiPlatesCore.PlatesByGUID ~= nil)
    --     end
    -- end
    
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    
    -- Register events
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    -- First run flag
    local firstRun = true
    
    -- Set up event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local addonName = ...
            
            -- Only initialize after VeiPlates is fully loaded
            if addonName == "VeiPlates" or addonName == core.addonName then
               -- print("VeiPlatesBeauty: Main addon loaded, attempting to hook...")
                
                -- Allow time for VeiPlates to fully initialize
                C_Timer.After(1, function()
                    -- Try to hook into VeiPlates functions
                    VeiPlatesBeauty:HookIntoVeiPlates()
                    
                    -- Process any existing plates
                    VeiPlatesBeauty:ProcessAllPlates()
                end)
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Initial setup (with a longer delay on first run)
            local delay = firstRun and 2 or 1
            firstRun = false
            
         --   print("VeiPlatesBeauty: Player entering world, processing plates in " .. delay .. " seconds...")
            C_Timer.After(delay, function()
                -- Try to hook again in case we missed it
                VeiPlatesBeauty:HookIntoVeiPlates()
                VeiPlatesBeauty:ProcessAllPlates()
            end)
        elseif event == "PLAYER_TARGET_CHANGED" then
            -- Update target highlighting
            C_Timer.After(0.1, function()
                VeiPlatesBeauty:ProcessAllPlates()
            end)
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unitID = ...
            
            -- Wait a brief moment for the nameplate to be fully created and attached
            C_Timer.After(0.2, function()
                -- Find all plates
                local plates = VeiPlatesBeauty:FindAllPlatesInGame()
                
                -- Process the specific plate if we can find it
                if plates[unitID] then
                    VeiPlatesBeauty:ProcessPlate(plates[unitID])
                end
            end)
        end
    end)
    
    -- Set up update ticker - less frequent to reduce performance impact
    -- Start with a short interval to catch initial plates
    C_Timer.After(0.5, function()
        VeiPlatesBeauty:ProcessAllPlates()
        
        -- Then switch to a longer interval for maintenance
        C_Timer.NewTicker(1.0, function()
            VeiPlatesBeauty:ProcessAllPlates()
        end)
    end)
    
    -- Direct access to the VeiPlatesCore object
    if core.VeiPlatesCore then
        -- Attempt to add direct references in VeiPlatesCore
        core.VeiPlatesCore.Beauty = VeiPlatesBeauty
        
        -- Fix: Check proper function type and handle correctly
        if type(core.VeiPlatesCore.UpdateUnitDynamic) == "function" then
            local originalUpdateUnitDynamic = core.VeiPlatesCore.UpdateUnitDynamic
            
            core.VeiPlatesCore.UpdateUnitDynamic = function(self, unitID, ...)
                local result = originalUpdateUnitDynamic(self, unitID, ...)
                
                -- Only update beautification occasionally to avoid performance impact
                if unitID and math.random(1, 10) == 1 then  -- 10% chance
                    local plates, _ = VeiPlatesBeauty:FindAllPlatesInGame()
                    if plates and plates[unitID] then
                        VeiPlatesBeauty:UpdateHealthBarColors(plates[unitID])
                    end
                end
                
                return result
            end
            
          --  print("VeiPlatesBeauty: Hooked UpdateUnitDynamic for incremental updates")
        end
        
        -- Hook specific cast events for cast bar beautification
        if type(core.VeiPlatesCore.StartCast) == "function" then
            local originalStartCast = core.VeiPlatesCore.StartCast
            
            core.VeiPlatesCore.StartCast = function(self, unitID, spellID, isChanneled, ...)
                local result = originalStartCast(self, unitID, spellID, isChanneled, ...)
                
                -- Wait a tiny bit for the cast bar to be fully set up
                C_Timer.After(0.05, function()
                    if unitID and UnitExists(unitID) then
                        local plates, _ = VeiPlatesBeauty:FindAllPlatesInGame()
                        if plates and plates[unitID] then
                            VeiPlatesBeauty:UpdateCastBarBorder(plates[unitID])
                        end
                    end
                end)
                
                return result
            end
            
        --    print("VeiPlatesBeauty: Hooked StartCast for cast bar beautification")
        end
    end
end

-- Create a function to try initialization multiple times
local initAttempts = 0
local function AttemptInitialization()
    initAttempts = initAttempts + 1
    
    if initAttempts > 5 then
       -- print("VeiPlatesBeauty: Giving up after 5 initialization attempts")
        return
    end
    
    if VeiPlates then
      --  print("VeiPlatesBeauty: VeiPlates found, initializing...")
        VeiPlatesBeauty:Initialize()
    else
       -- print("VeiPlatesBeauty: VeiPlates not found, will retry in 2 seconds (attempt " .. initAttempts .. "/5)")
        C_Timer.After(2, AttemptInitialization)
    end
end

-- Initialize immediately if already loaded, otherwise wait for ADDON_LOADED
if IsAddOnLoaded("VeiPlates") or (core and core.VeiPlates) then
  --  print("VeiPlatesBeauty: VeiPlates already loaded, initializing immediately")
    VeiPlatesBeauty:Initialize()
else
  --  print("VeiPlatesBeauty: Waiting for VeiPlates to load...")
    AttemptInitialization()
end

-- Register slash command
SLASH_VEIPLATESBEAUTY1 = "/vpbeauty"
SlashCmdList["VEIPLATESBEAUTY"] = function(msg)
    if msg == "reset" then
        -- Reset all plates
        VeiPlatesBeauty:ProcessAllPlates()
        print("VeiPlatesBeauty: Reset all nameplate visuals")
    elseif msg == "debug" then
        -- Toggle debug mode
        CONFIG.debug = not CONFIG.debug
        print("VeiPlatesBeauty: Debug mode " .. (CONFIG.debug and "enabled" or "disabled"))
        VeiPlatesBeauty:ProcessAllPlates()
    elseif msg == "hooks" then
        -- Try to hook into VeiPlates functions
        print("VeiPlatesBeauty: Attempting to hook VeiPlates functions...")
        VeiPlatesBeauty:HookIntoVeiPlates()
    elseif msg == "test" then
        -- Test direct plate access
        print("VeiPlatesBeauty: Testing direct plate access...")
        local plates, count = VeiPlatesBeauty:FindAllPlatesInGame()
        print("Found " .. count .. " plates")
        
        -- Process all found plates
        VeiPlatesBeauty:ProcessAllPlates()
    elseif msg == "init" then
        -- Force reinitialization
        print("VeiPlatesBeauty: Forcing reinitialization...")
        VeiPlatesBeauty:Initialize()
    else
        print("VeiPlatesBeauty commands:")
        print("  /vpbeauty reset - Reset all nameplate visuals")
        print("  /vpbeauty debug - Toggle debug mode")
        print("  /vpbeauty hooks - Attempt to hook into VeiPlates")
        print("  /vpbeauty test - Test direct plate access")
        print("  /vpbeauty init - Force reinitialization")
    end
end

-- Return the module
return VeiPlatesBeauty