

local addonName, core = ...
local VeiPlatesAuras = {}
core.VeiPlatesAuras = VeiPlatesAuras

-- Print a message to chat for debugging
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99VeiPlatesAuras:|r " .. msg)
end

--Print("VeiPlatesAuras module loading...")

-- =======================================
-- CONFIGURATION OPTIONS
-- =======================================
local CONFIG = {
    -- Debuff display settings
    debuffSize = 24,           -- Size of debuff icons
    maxDebuffs = 8,            -- Maximum number of debuffs to show
    spacing = 2,               -- Spacing between debuff icons
    verticalOffset = 10,        -- Distance above nameplate
    scale = 0.8,               -- Scale factor for icons
    growDirection = "CENTER",   -- Options: "RIGHT", "LEFT", "CENTER"
    xOffset = 10,               -- Horizontal offset from anchor point
    
    -- Filtering options
    showOnlyMyDebuffs = true,  -- Show only player's debuffs
    enableFilterMode = false,  -- Enable filter mode
    filteredDebuffs = {},      -- List of specific debuffs to show when filter mode is on
    
    -- Blacklist - Spells that should NEVER be shown
    blacklistedSpells = {
        -- Add spell IDs or names here
        -- Example: 324, -- Spell name
        "Entangling Roots",
    },
    
    -- Appearance options
    showCooldownText = true,   -- Show cooldown spiral and text
    
    -- Debug options
    debug = false              -- Enable debug messages
}

-- Cache frequently used functions
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local select = select
local table = table
local format = string.format
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitGUID = UnitGUID
local UnitDebuff = UnitDebuff
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local UnitIsTapDenied = UnitIsTapDenied
local UnitClass = UnitClass
local UnitName = UnitName
local GetTime = GetTime
local CreateFrame = CreateFrame

-- =======================================
-- DATA STRUCTURES
-- =======================================
local DebuffContainers = {}    -- Debuff container frames indexed by unitID
local NameplatesByUnit = {}    -- Blizzard nameplates indexed by unitID
local NameplatesByGUID = {}    -- Blizzard nameplates indexed by GUID
local UnitsByGUID = {}         -- Unit IDs indexed by GUID
local GUIDByUnit = {}          -- GUIDs indexed by unit ID

-- =======================================
-- UTILITY FUNCTIONS
-- =======================================
-- Debug print function
local function DebugPrint(...)
    if CONFIG.debug then
        Print(table.concat({...}, " "))
    end
end

-- Helper function to count table entries
local function GetTableSize(tbl)
    if not tbl then return 0 end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end
-- Check if a spell is blacklisted
local function IsBlacklisted(spellID, spellName)
    -- Check by ID first
    for _, blacklistedID in ipairs(CONFIG.blacklistedSpells) do
        if type(blacklistedID) == "number" and blacklistedID == spellID then
            return true
        end
    end
    
    -- Then check by name
    for _, blacklistedSpell in ipairs(CONFIG.blacklistedSpells) do
        if type(blacklistedSpell) == "string" and spellName and 
           string.lower(blacklistedSpell) == string.lower(spellName) then
            return true
        end
    end
    
    return false
end--[[
    VeiPlatesAuras.lua - Aura tracking module for nameplate debuffs
    
    Design philosophy:
    - Uses Blizzard nameplates as direct anchors, even when VeiPlates hides them
    - GUID-based tracking to ensure auras stay with the correct unit
    - Event-driven updates for immediate responsiveness
    - Simple, direct anchoring approach based on VeiPlatesTest
]]

-- Safe string comparison
local function SafeCompare(a, b)
    if a == nil or b == nil then
        return false
    end
    return tostring(a) == tostring(b)
end

-- Handle fallback to old client versions without C_Timer
if not C_Timer then
    C_Timer = {}
    C_Timer.After = function(delay, callback)
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame.delay = delay
        frame.callback = callback
        frame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= self.delay then
                self:SetScript("OnUpdate", nil)
                self.callback()
            end
        end)
        return frame
    end
    
    C_Timer.NewTicker = function(interval, callback)
        local frame = CreateFrame("Frame")
        frame.elapsed = 0
        frame.interval = interval
        frame.callback = callback
        frame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed >= self.interval then
                self.elapsed = 0
                self.callback()
            end
        end)
        
        -- Return an object with a Cancel method for API compatibility
        return {
            Cancel = function()
                frame:SetScript("OnUpdate", nil)
            end
        }
    end
    
    DebugPrint("Created C_Timer fallback for older WoW versions")
end

-- =======================================
-- DEBUFF FRAMES CREATION
-- =======================================
-- Create debuff container and frames for a nameplate
local function CreateDebuffContainer(defaultPlate, unitID)
    if not defaultPlate then 
        DebugPrint("CreateDebuffContainer: No defaultPlate provided")
        return nil 
    end
    
    DebugPrint("Creating debuff container for unit: " .. (unitID or "unknown"))
    
    -- Find a health bar to use as anchor (just like VeiPlatesTest)
    local anchor
    
    -- First try to find the health bar in the nameplate
    if defaultPlate.UnitFrame and defaultPlate.UnitFrame.healthBar then
        -- Retail style
        anchor = defaultPlate.UnitFrame.healthBar
        DebugPrint("Using UnitFrame.healthBar as anchor")
    elseif defaultPlate.healthBar then
        -- Some custom nameplates style
        anchor = defaultPlate.healthBar
        DebugPrint("Using healthBar as anchor")
    else
        -- Try to find StatusBar children
        for _, child in pairs({defaultPlate:GetChildren()}) do
            if child:GetObjectType() == "StatusBar" then
                anchor = child
                DebugPrint("Found StatusBar child to use as anchor")
                break
            end
        end
    end
    
    -- If no health bar found, use the nameplate itself
    if not anchor then
        anchor = defaultPlate
        DebugPrint("No suitable anchor found, using nameplate itself")
    end
    
    -- Create the container frame as a direct child of the nameplate
    local container = CreateFrame("Frame", nil, defaultPlate)
    
    -- Calculate total width including spacing
    local totalWidth = CONFIG.debuffSize * CONFIG.maxDebuffs + CONFIG.spacing * (CONFIG.maxDebuffs - 1)
    container:SetSize(totalWidth, CONFIG.debuffSize)
    
    -- Update position based on growth direction and offset
    container:ClearAllPoints()
    
    if CONFIG.growDirection == "RIGHT" then
        container:SetPoint("BOTTOMLEFT", anchor, "TOP", CONFIG.xOffset, CONFIG.verticalOffset)
        DebugPrint("Container anchored at BOTTOMLEFT for RIGHT growth")
    elseif CONFIG.growDirection == "LEFT" then
        container:SetPoint("BOTTOMRIGHT", anchor, "TOP", CONFIG.xOffset, CONFIG.verticalOffset)
        DebugPrint("Container anchored at BOTTOMRIGHT for LEFT growth")
    elseif CONFIG.growDirection == "CENTER" then
        -- For centered growth, we center the container on the anchor
        container:SetPoint("BOTTOM", anchor, "TOP", CONFIG.xOffset, CONFIG.verticalOffset)
        DebugPrint("Container anchored at BOTTOM for CENTER growth")
    end
    
    container:SetScale(CONFIG.scale)
    
    container.icons = {}
    container.unitID = unitID
    container.defaultPlate = defaultPlate
    
    -- Create the individual debuff frames with proper positioning
    for i = 1, CONFIG.maxDebuffs do
        local iconFrame = CreateFrame("Frame", nil, container)
        iconFrame:SetSize(CONFIG.debuffSize, CONFIG.debuffSize)
        iconFrame:ClearAllPoints()
        
        -- Position based on grow direction
        if CONFIG.growDirection == "RIGHT" then
            iconFrame:SetPoint("LEFT", (i-1) * (CONFIG.debuffSize + CONFIG.spacing), 0)
            DebugPrint("Icon " .. i .. " positioned growing RIGHT")
        elseif CONFIG.growDirection == "LEFT" then
            iconFrame:SetPoint("RIGHT", -((i-1) * (CONFIG.debuffSize + CONFIG.spacing)), 0)
            DebugPrint("Icon " .. i .. " positioned growing LEFT")
        elseif CONFIG.growDirection == "CENTER" then
            -- Similar to your SpellTracker approach for centered icons
            local iconCount = CONFIG.maxDebuffs
            local halfWidth = ((iconCount - 1) * (CONFIG.debuffSize + CONFIG.spacing)) / 2
            local iconOffset = (i - 1) * (CONFIG.debuffSize + CONFIG.spacing) - halfWidth
            
            -- Set position relative to container center
            iconFrame:SetPoint("CENTER", iconOffset, 0)
            DebugPrint("Icon " .. i .. " positioned growing CENTER at offset " .. iconOffset)
        end
        
        -- Create texture for the icon
        iconFrame.texture = iconFrame:CreateTexture(nil, "BACKGROUND")
        iconFrame.texture:SetAllPoints(iconFrame)
        iconFrame.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Trim icon edges
        
        -- Create cooldown frame
        iconFrame.cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
        iconFrame.cooldown:SetAllPoints()
        iconFrame.cooldown:SetDrawEdge(false)
        iconFrame.cooldown:SetHideCountdownNumbers(not CONFIG.showCooldownText)
        
        -- Create border texture
        iconFrame.border = iconFrame:CreateTexture(nil, "OVERLAY")
        iconFrame.border:SetAllPoints()
        iconFrame.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        iconFrame.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        
        -- Create count text
        iconFrame.count = iconFrame:CreateFontString(nil, "OVERLAY")
        iconFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        iconFrame.count:SetPoint("BOTTOMRIGHT", 2, 0)
        
        -- Hide by default
        iconFrame:Hide()
        container.icons[i] = iconFrame
    end
    
    -- Hide the container initially
    container:Hide()
    
    return container
end

-- =======================================
-- NAMEPLATE MANAGEMENT FUNCTIONS
-- =======================================
-- Track a nameplate when it appears
function VeiPlatesAuras:TrackNameplate(unitID)
    if not unitID or not UnitExists(unitID) then return end
    
    DebugPrint("TrackNameplate called for unit:", unitID)
    
    local guid = UnitGUID(unitID)
    if not guid then 
        DebugPrint("No GUID found for unit:", unitID)
        return 
    end
    
    -- Store the GUID relationship
    UnitsByGUID[guid] = unitID
    GUIDByUnit[unitID] = guid
    
    local defaultPlate = C_NamePlate.GetNamePlateForUnit(unitID)
    if not defaultPlate then 
        DebugPrint("No nameplate found for unit:", unitID)
        return 
    end
    
    -- Store nameplate references
    NameplatesByUnit[unitID] = defaultPlate
    NameplatesByGUID[guid] = defaultPlate
    
    -- Clean up any existing container for this unit
    if DebuffContainers[unitID] then
        DebuffContainers[unitID]:Hide()
        DebuffContainers[unitID] = nil
    end
    
    -- Create debuff container (with retry mechanism)
    local function TryCreateContainer(attempts)
        if attempts <= 0 then return end
        
        local container = CreateDebuffContainer(defaultPlate, unitID)
        if container then
            DebuffContainers[unitID] = container
            -- Update debuffs immediately
            self:UpdateDebuffsForUnit(unitID)
            DebugPrint("Successfully created container for:", unitID)
        else
            -- Retry with a small delay
            DebugPrint("Failed to create container, retrying... Attempts left:", attempts-1)
            C_Timer.After(0.1, function()
                TryCreateContainer(attempts-1)
            end)
        end
    end
    
    -- Try up to 3 times to create the container
    TryCreateContainer(3)
    
    DebugPrint("Finished tracking setup for unit:", unitID, "GUID:", guid:sub(1, 8))
end

-- Stop tracking a nameplate
function VeiPlatesAuras:UntrackNameplate(unitID)
    if not unitID then return end
    
    local guid = GUIDByUnit[unitID]
    
    -- Clean up containers
    if DebuffContainers[unitID] then
        DebuffContainers[unitID]:Hide()
        DebuffContainers[unitID] = nil
    end
    
    -- Clean up references
    NameplatesByUnit[unitID] = nil
    if guid then
        NameplatesByGUID[guid] = nil
        UnitsByGUID[guid] = nil
    end
    GUIDByUnit[unitID] = nil
    
    DebugPrint("Untracking nameplate for unit:", unitID)
end

-- =======================================
-- DEBUFF UPDATES AND MANAGEMENT
-- =======================================
-- Update debuffs for a specific unit
function VeiPlatesAuras:UpdateDebuffsForUnit(unitID)
    if not unitID or not UnitExists(unitID) then return end
    
    -- Skip friendly units if desired
    if UnitIsFriend("player", unitID) then
        DebugPrint("Skipping friendly unit:", unitID)
        return
    end
    
    -- Get the debuff container
    local container = DebuffContainers[unitID]
    if not container then
        -- Try to create it if it doesn't exist
        local defaultPlate = C_NamePlate.GetNamePlateForUnit(unitID)
        if not defaultPlate then return end
        
        container = CreateDebuffContainer(defaultPlate, unitID)
        if not container then return end
        
        DebuffContainers[unitID] = container
    else
        -- Update the position if container already exists
        if container.UpdatePosition then
            container.UpdatePosition()
        end
    end
    
    -- Count displayed debuffs
    local debuffCount = 0
    local i = 1
    
    -- Track active debuffs for better centering
    local activeDebuffs = {}
    
    -- Iterate through debuffs on the unit
    while debuffCount < CONFIG.maxDebuffs do
        -- Get debuff info - different parameter order in different WoW versions
        local name, icon, count, debuffType, duration, expirationTime, caster, _, _, spellID
        
        -- Try modern API format first
        name, icon, count, debuffType, duration, expirationTime, caster, _, _, spellID = UnitDebuff(unitID, i)
        
        -- If that fails, try the classic API format
        if not name and not icon then
            name, _, icon, count, debuffType, duration, expirationTime, caster, _, _, spellID = UnitDebuff(unitID, i)
        end
        
        if not name then break end
        
        -- Determine if we should display this debuff
        local display = false
        
        -- First check if the spell is blacklisted
        if IsBlacklisted(spellID, name) then
            -- Skip this debuff entirely
            DebugPrint("Skipping blacklisted spell: " .. name)
        else
            -- Not blacklisted, proceed with normal filtering
            if CONFIG.enableFilterMode then
                -- Filter mode: only show specific debuffs in the filter list
                for _, filteredName in ipairs(CONFIG.filteredDebuffs) do
                    if SafeCompare(name, filteredName) then
                        display = true
                        break
                    end
                end
                
                -- If filter mode is enabled, also check for caster if showOnlyMyDebuffs is enabled
                if display and CONFIG.showOnlyMyDebuffs then
                    display = (caster and UnitIsUnit("player", caster))
                end
            else
                -- Normal mode: show all debuffs, or only player's debuffs if enabled
                if CONFIG.showOnlyMyDebuffs then
                    display = (caster and UnitIsUnit("player", caster))
                else
                    display = true
                end
            end
        end
        
        -- Display the debuff if it passed filtering
        if display then
            debuffCount = debuffCount + 1
            local debuffFrame = container.icons[debuffCount]
            
            -- Store this frame for later repositioning if needed
            table.insert(activeDebuffs, debuffFrame)
            
            -- Update icon texture
            debuffFrame.texture:SetTexture(icon)
            
            -- Set stack count
            if count and count > 1 then
                debuffFrame.count:SetText(count)
                debuffFrame.count:Show()
            else
                debuffFrame.count:Hide()
            end
            
            -- Set cooldown spiral
            if duration and duration > 0 and expirationTime then
                debuffFrame.cooldown:SetCooldown(expirationTime - duration, duration)
                debuffFrame.cooldown:Show()
            else
                debuffFrame.cooldown:Hide()
            end
            
            -- Set border color based on debuff type
            if debuffType and _G.DebuffTypeColor and _G.DebuffTypeColor[debuffType] then
                local color = _G.DebuffTypeColor[debuffType]
                debuffFrame.border:SetVertexColor(color.r, color.g, color.b)
            else
                -- Default to purple if no type or type color not found
                debuffFrame.border:SetVertexColor(0.8, 0, 0.8)
            end
            
            -- Store debuff info for easy access
            debuffFrame.info = {
                name = name,
                spellID = spellID,
                icon = icon,
                count = count,
                debuffType = debuffType,
                duration = duration,
                expirationTime = expirationTime,
                caster = caster
            }
            
            debuffFrame:Show()
        end
        
        i = i + 1
    end
    
    -- Hide unused debuff frames
    for i = debuffCount + 1, CONFIG.maxDebuffs do
        local debuffFrame = container.icons[i]
        if debuffFrame then
            debuffFrame:Hide()
            debuffFrame.info = nil
        end
    end
    
    -- Center the visible icons dynamically if using center growth
    if CONFIG.growDirection == "CENTER" and debuffCount > 0 and debuffCount < CONFIG.maxDebuffs then
        -- Recenter the visible debuffs
        local totalWidth = debuffCount * CONFIG.debuffSize + (debuffCount - 1) * CONFIG.spacing
        local halfWidth = totalWidth / 2
        
        for i, debuffFrame in ipairs(activeDebuffs) do
            debuffFrame:ClearAllPoints()
            local iconOffset = (i - 1) * (CONFIG.debuffSize + CONFIG.spacing) - halfWidth + (CONFIG.debuffSize / 2)
            debuffFrame:SetPoint("CENTER", container, "CENTER", iconOffset, 0)

        end
    end
    
    -- Show or hide the container based on whether we have debuffs
    if debuffCount > 0 then
        container:Show()
    else
        container:Hide()
    end
    
    return debuffCount
end

-- Update all currently tracked nameplates
function VeiPlatesAuras:UpdateAllNameplates()
    for unitID, _ in pairs(NameplatesByUnit) do
        if UnitExists(unitID) then
            self:UpdateDebuffsForUnit(unitID)
        end
    end
end

-- Handle combat log events that affect debuffs
function VeiPlatesAuras:HandleCombatLogEvent(...)
    -- Get combat log info
    local timestamp, subEvent, _, sourceGUID, _, _, _, destGUID
    
    -- Check which combat log API to use
    if CombatLogGetCurrentEventInfo then
        -- Retail/Modern API
        timestamp, subEvent, _, sourceGUID, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
    else
        -- Classic API - use the parameters passed to the function
        timestamp, subEvent, _, sourceGUID, _, _, _, destGUID = ...
    end
    
    -- Only update for events that might affect debuffs
    if subEvent == "SPELL_AURA_APPLIED" or 
       subEvent == "SPELL_AURA_REMOVED" or 
       subEvent == "SPELL_AURA_APPLIED_DOSE" or 
       subEvent == "SPELL_AURA_REMOVED_DOSE" or
       subEvent == "SPELL_AURA_REFRESH" then
        
        -- Find the unit with this GUID
        local unitID = UnitsByGUID[destGUID]
        if unitID then
            -- Small delay to ensure the aura is fully applied/removed
            C_Timer.After(0.05, function()
                VeiPlatesAuras:UpdateDebuffsForUnit(unitID)
            end)
        end
    end
end

-- =======================================
-- CONFIGURATION FUNCTIONS
-- =======================================
-- Set growth direction for debuffs
function VeiPlatesAuras:SetGrowDirection(direction)
    -- Validate and normalize input
    direction = string.upper(direction or "")
    if direction ~= "RIGHT" and direction ~= "LEFT" and direction ~= "CENTER" then
        Print("Invalid direction. Use RIGHT, LEFT, or CENTER.")
        Print("Current direction: " .. CONFIG.growDirection)
        return
    end
    
    CONFIG.growDirection = direction
    Print("Grow direction set to " .. direction)
    
    -- Recreate all containers with new growth direction
    self:ResetContainers()
end

-- Set vertical offset
function VeiPlatesAuras:SetVerticalOffset(offset)
    CONFIG.verticalOffset = offset
    Print("Vertical offset set to " .. offset)
    
    -- Recreate all containers
    self:ResetContainers()
end

-- Set horizontal offset
function VeiPlatesAuras:SetHorizontalOffset(offset)
    CONFIG.xOffset = offset
    Print("Horizontal offset set to " .. offset)
    
    -- Recreate all containers
    self:ResetContainers()
end

-- Set scale of debuff container
function VeiPlatesAuras:SetScale(scale)
    CONFIG.scale = scale
    Print("Scale set to " .. scale)
    
    -- Update scale on all containers
    for unitID, container in pairs(DebuffContainers) do
        if container then
            container:SetScale(scale)
        end
    end
end

-- Reset all containers to apply new settings
function VeiPlatesAuras:ResetContainers()
    -- Make a copy of current unit IDs
    local unitIDs = {}
    for unitID, _ in pairs(DebuffContainers) do
        table.insert(unitIDs, unitID)
    end
    
    -- Remove all containers
    for _, unitID in ipairs(unitIDs) do
        if DebuffContainers[unitID] then
            DebuffContainers[unitID]:Hide()
            DebuffContainers[unitID] = nil
        end
    end
    
    -- Create new containers for all tracked units
    for _, unitID in ipairs(unitIDs) do
        if UnitExists(unitID) then
            local defaultPlate = C_NamePlate.GetNamePlateForUnit(unitID)
            if defaultPlate then
                local container = CreateDebuffContainer(defaultPlate, unitID)
                if container then
                    DebuffContainers[unitID] = container
                    self:UpdateDebuffsForUnit(unitID)
                end
            end
        end
    end
end

-- Set size of debuff icons
function VeiPlatesAuras:SetDebuffSize(size)
    -- Update the configuration
    CONFIG.debuffSize = size
    Print("Debuff size set to " .. size)
    
    -- Recreate all containers
    self:ResetContainers()
end

-- Set maximum number of debuffs
function VeiPlatesAuras:SetMaxDebuffs(count)
    -- Update the configuration
    CONFIG.maxDebuffs = count
    Print("Maximum debuffs set to " .. count)
    
    -- Recreate all containers
    self:ResetContainers()
end

-- Set spacing between icons
function VeiPlatesAuras:SetIconSpacing(spacing)
    if not spacing or spacing < 0 then
        Print("Invalid spacing. Usage: /vpauras spacing VALUE")
        Print("Current spacing: " .. CONFIG.spacing)
        return
    end
    
    CONFIG.spacing = spacing
    Print("Icon spacing set to " .. spacing .. " pixels")
    
    -- Recreate all containers with new spacing
    self:ResetContainers()
end

-- Toggle showing only player's debuffs
function VeiPlatesAuras:ToggleMyDebuffsOnly()
    CONFIG.showOnlyMyDebuffs = not CONFIG.showOnlyMyDebuffs
    Print("Show only my debuffs: " .. (CONFIG.showOnlyMyDebuffs and "Enabled" or "Disabled"))
    
    -- Update all debuffs
    self:UpdateAllNameplates()
end

-- Toggle filter mode
function VeiPlatesAuras:ToggleFilterMode()
    CONFIG.enableFilterMode = not CONFIG.enableFilterMode
    Print("Filter mode: " .. (CONFIG.enableFilterMode and "Enabled" or "Disabled"))
    
    -- Update all debuffs
    self:UpdateAllNameplates()
end

-- Add a debuff to the filter list
function VeiPlatesAuras:AddFilteredDebuff(debuffName)
    if not debuffName or debuffName == "" then
        Print("Usage: /vpauras add DEBUFF_NAME")
        return
    end
    
    -- Check if it's already in the list
    for _, name in ipairs(CONFIG.filteredDebuffs) do
        if SafeCompare(name:lower(), debuffName:lower()) then
            Print(debuffName .. " is already in the filter list.")
            return
        end
    end
    
    -- Add to list
    table.insert(CONFIG.filteredDebuffs, debuffName)
    Print("Added " .. debuffName .. " to filter list.")
    
    -- Update if filter mode is enabled
    if CONFIG.enableFilterMode then
        self:UpdateAllNameplates()
    end
end

-- Remove a debuff from the filter list
function VeiPlatesAuras:RemoveFilteredDebuff(debuffName)
    if not debuffName or debuffName == "" then
        Print("Usage: /vpauras remove DEBUFF_NAME")
        return
    end
    
    -- Find and remove
    local removed = false
    for i, name in ipairs(CONFIG.filteredDebuffs) do
        if SafeCompare(name:lower(), debuffName:lower()) then
            table.remove(CONFIG.filteredDebuffs, i)
            Print("Removed " .. debuffName .. " from filter list.")
            removed = true
            break
        end
    end
    
    if not removed then
        Print(debuffName .. " is not in the filter list.")
    else
        -- Update if filter mode is enabled
        if CONFIG.enableFilterMode then
            self:UpdateAllNameplates()
        end
    end
end

-- List all debuffs in the filter list
function VeiPlatesAuras:ListFilteredDebuffs()
    Print("Filtered debuffs list:")
    
    if #CONFIG.filteredDebuffs == 0 then
        Print("  No filtered debuffs.")
    else
        for i, name in ipairs(CONFIG.filteredDebuffs) do
            Print("  " .. i .. ". " .. name)
        end
    end
end

-- Toggle debug mode
function VeiPlatesAuras:ToggleDebug()
    CONFIG.debug = not CONFIG.debug
    Print("Debug mode " .. (CONFIG.debug and "enabled" or "disabled"))
end

-- Force update all debuffs
function VeiPlatesAuras:ForceUpdate()
    Print("Forcing update of all nameplate debuffs")
    self:UpdateAllNameplates()
end

-- Display current settings
function VeiPlatesAuras:ShowSettings()
    Print("Current VeiPlatesAuras Settings:")
    Print("  Debuff Size: " .. CONFIG.debuffSize .. " pixels")
    Print("  Maximum Debuffs: " .. CONFIG.maxDebuffs)
    Print("  Spacing: " .. CONFIG.spacing .. " pixels")
    Print("  Vertical Offset: " .. CONFIG.verticalOffset .. " pixels")
    Print("  Horizontal Offset: " .. CONFIG.xOffset .. " pixels")
    Print("  Scale: " .. CONFIG.scale)
    Print("  Growth Direction: " .. CONFIG.growDirection)
    Print("  Show Only My Debuffs: " .. (CONFIG.showOnlyMyDebuffs and "Yes" or "No"))
    Print("  Filter Mode: " .. (CONFIG.enableFilterMode and "Enabled" or "Disabled"))
    Print("  Filtered Debuffs: " .. #CONFIG.filteredDebuffs)
    Print("  Blacklisted Spells: " .. #CONFIG.blacklistedSpells)
    Print("  Debug Mode: " .. (CONFIG.debug and "Enabled" or "Disabled"))
    
    -- Show active nameplates count
    local count = GetTableSize(DebuffContainers)
    Print("  Active Nameplate Count: " .. count)
end

-- =======================================
-- INITIALIZATION AND EVENT HANDLING
-- =======================================
-- Initialize the module
function VeiPlatesAuras:Initialize()
   -- Print("Initializing VeiPlatesAuras module...")
    
    -- Create event handling frame
    local eventFrame = CreateFrame("Frame")
    
    -- Set debug mode for initial development
    CONFIG.debug = false  -- Temporarily enable debug for troubleshooting
    
    -- Register necessary events
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    -- Print event registration info
   -- Print("Registered events: PLAYER_ENTERING_WORLD, NAME_PLATE_UNIT_ADDED, UNIT_AURA, etc.")
    
    -- Handle events
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
            -- Clean up any existing data
            VeiPlatesAuras:Cleanup()
            
           -- Print("PLAYER_ENTERING_WORLD/LOGIN event received")
            
            -- Update with a slight delay to ensure everything is loaded
            C_Timer.After(1, function()
                -- Check for all existing nameplates
                local found = 0
                for i = 1, 40 do
                    local unitID = "nameplate" .. i
                    if UnitExists(unitID) then
                        VeiPlatesAuras:TrackNameplate(unitID)
                        found = found + 1
                    end
                end
              --  Print("Found and tracked " .. found .. " existing nameplates")
            end)
            
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unitID = ...
           -- Print("NAME_PLATE_UNIT_ADDED event for " .. unitID)
            
            -- Use a short delay to ensure the nameplate is fully created
            C_Timer.After(0.1, function()
                if UnitExists(unitID) then
                    VeiPlatesAuras:TrackNameplate(unitID)
                end
            end)
            
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            local unitID = ...
           -- Print("NAME_PLATE_UNIT_REMOVED event for " .. unitID)
            VeiPlatesAuras:UntrackNameplate(unitID)
            
        elseif event == "UNIT_AURA" then
            local unitID = ...
            
            if unitID and unitID:match("nameplate%d") then
                -- DebugPrint("UNIT_AURA event for " .. unitID)
                -- Update the specific nameplate unit
                VeiPlatesAuras:UpdateDebuffsForUnit(unitID)
            elseif unitID == "target" then
                -- If it's the target, find its nameplate unit ID and update
                local targetGUID = UnitGUID("target")
                if targetGUID and UnitsByGUID[targetGUID] then
                    VeiPlatesAuras:UpdateDebuffsForUnit(UnitsByGUID[targetGUID])
                end
            end
            
        elseif event == "PLAYER_TARGET_CHANGED" then
            -- Update the current target's debuffs
            DebugPrint("PLAYER_TARGET_CHANGED event")
            if UnitExists("target") then
                local targetGUID = UnitGUID("target")
                if targetGUID and UnitsByGUID[targetGUID] then
                    VeiPlatesAuras:UpdateDebuffsForUnit(UnitsByGUID[targetGUID])
                end
            end
            
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            VeiPlatesAuras:HandleCombatLogEvent(...)
        end
    end)
    
    -- Set up continuous monitoring of nameplates to catch any issues
    -- This serves as a backup in case events are missed
    C_Timer.NewTicker(0.5, function()
        -- Scan for any existing nameplates that we might have missed
        for i = 1, 40 do
            local unitID = "nameplate" .. i
            if UnitExists(unitID) and not DebuffContainers[unitID] then
                DebugPrint("Backup ticker found untracked nameplate: " .. unitID)
                VeiPlatesAuras:TrackNameplate(unitID)
            end
        end
        
        -- Update currently tracked nameplates
        for unitID, container in pairs(DebuffContainers) do
            if UnitExists(unitID) then
                VeiPlatesAuras:UpdateDebuffsForUnit(unitID)
            end
        end
    end)
    
    -- Try to hook common nameplate functions if they exist
    if NamePlateDriverFrame and NamePlateDriverFrame.SetupClassNameplateBars then
        DebugPrint("Hooked NamePlateDriverFrame.SetupClassNameplateBars")
        hooksecurefunc(NamePlateDriverFrame, "SetupClassNameplateBars", function()
            C_Timer.After(0.2, function()
                VeiPlatesAuras:UpdateAllNameplates()
            end)
        end)
    end
    
    -- Register slash commands
    SLASH_VPAURAS1 = "/vpauras"
    SlashCmdList["VPAURAS"] = function(msg)
        local command, arg = msg:match("^(%S*)%s*(.-)$")
        command = command:lower()
        
        if command == "" then
            Print("Commands:")
            Print("  /vpauras my - Toggle showing only your debuffs")
            Print("  /vpauras filter - Toggle filter mode")
            Print("  /vpauras add NAME - Add debuff to filter list")
            Print("  /vpauras remove NAME - Remove debuff from filter list")
            Print("  /vpauras list - List filtered debuffs")
            Print("  /vpauras size SIZE - Set debuff icon size")
            Print("  /vpauras spacing VALUE - Set spacing between icons")
            Print("  /vpauras scale SCALE - Set debuff scale")
            Print("  /vpauras max COUNT - Set maximum number of debuffs")
            Print("  /vpauras yoffset OFFSET - Set vertical offset")
            Print("  /vpauras xoffset OFFSET - Set horizontal offset")
            Print("  /vpauras grow DIRECTION - Set growth direction (RIGHT, LEFT, CENTER)")
            Print("  /vpauras settings - Show current settings")
            Print("  /vpauras update - Force update all debuffs")
            Print("  /vpauras debug - Toggle debug mode")
        elseif command == "my" then
            VeiPlatesAuras:ToggleMyDebuffsOnly()
        elseif command == "filter" then
            VeiPlatesAuras:ToggleFilterMode()
        elseif command == "add" then
            VeiPlatesAuras:AddFilteredDebuff(arg)
        elseif command == "remove" then
            VeiPlatesAuras:RemoveFilteredDebuff(arg)
        elseif command == "list" then
            VeiPlatesAuras:ListFilteredDebuffs()
        elseif command == "size" then
            local size = tonumber(arg)
            if size then
                VeiPlatesAuras:SetDebuffSize(size)
            else
                Print("Invalid size. Usage: /vpauras size SIZE")
            end
        elseif command == "scale" then
            local scale = tonumber(arg)
            if scale then
                VeiPlatesAuras:SetScale(scale)
            else
                Print("Invalid scale. Usage: /vpauras scale SCALE")
            end
        elseif command == "max" then
            local count = tonumber(arg)
            if count then
                VeiPlatesAuras:SetMaxDebuffs(count)
            else
                Print("Invalid count. Usage: /vpauras max COUNT")
            end
        elseif command == "yoffset" then
            local offset = tonumber(arg)
            if offset then
                VeiPlatesAuras:SetVerticalOffset(offset)
            else
                Print("Invalid offset. Usage: /vpauras yoffset OFFSET")
            end
        elseif command == "xoffset" then
            local offset = tonumber(arg)
            if offset then
                VeiPlatesAuras:SetHorizontalOffset(offset)
            else
                Print("Invalid offset. Usage: /vpauras xoffset OFFSET")
            end
        elseif command == "grow" then
            VeiPlatesAuras:SetGrowDirection(arg)
        elseif command == "spacing" then
            local spacing = tonumber(arg)
            if spacing then
                VeiPlatesAuras:SetIconSpacing(spacing)
            else
                Print("Invalid spacing. Usage: /vpauras spacing VALUE")
            end
        elseif command == "settings" or command == "status" then
            VeiPlatesAuras:ShowSettings()
        elseif command == "update" then
            VeiPlatesAuras:ForceUpdate()
        elseif command == "debug" then
            VeiPlatesAuras:ToggleDebug()
        else
            Print("Unknown command: " .. command)
            Print("Type /vpauras for help")
        end
    end
    
   -- Print("VeiPlatesAuras initialized. Type /vpauras for commands.")
    return true
end

-- Clean up all data
function VeiPlatesAuras:Cleanup()
    -- Hide and clear all debuff containers
    for unitID, container in pairs(DebuffContainers) do
        container:Hide()
    end
    
    -- Clear all data tables
    wipe(DebuffContainers)
    wipe(NameplatesByUnit)
    wipe(NameplatesByGUID)
    wipe(UnitsByGUID)
    wipe(GUIDByUnit)
    
    DebugPrint("Cleaned up all aura tracking data")
end

-- Dump information about tracked nameplates
function VeiPlatesAuras:DumpDebugInfo()
    Print("VeiPlatesAuras Debug Info:")
    Print("Tracked nameplates: " .. GetTableSize(NameplatesByUnit))
    Print("Tracked GUIDs: " .. GetTableSize(NameplatesByGUID))
    Print("Active debuff containers: " .. GetTableSize(DebuffContainers))
    
    -- Display current configuration
    Print("\nConfiguration:")
    Print("  debuffSize: " .. CONFIG.debuffSize)
    Print("  maxDebuffs: " .. CONFIG.maxDebuffs)
    Print("  spacing: " .. CONFIG.spacing)
    Print("  verticalOffset: " .. CONFIG.verticalOffset)
    Print("  scale: " .. CONFIG.scale)
    Print("  growDirection: " .. CONFIG.growDirection)
    Print("  xOffset: " .. CONFIG.xOffset)
    Print("  showOnlyMyDebuffs: " .. (CONFIG.showOnlyMyDebuffs and "Yes" or "No"))
    Print("  enableFilterMode: " .. (CONFIG.enableFilterMode and "Yes" or "No"))
    Print("  filteredDebuffs count: " .. #CONFIG.filteredDebuffs)
    
    -- Display information about current nameplates
    Print("\nCurrent nameplates:")
    local count = 0
    for unitID, namePlate in pairs(NameplatesByUnit) do
        count = count + 1
        if count <= 5 then  -- Limit to 5 to avoid spam
            local unitName = UnitName(unitID) or "Unknown"
            local guid = GUIDByUnit[unitID] or "Unknown"
            local hasContainer = DebuffContainers[unitID] ~= nil
            
            Print(string.format("%d. %s (GUID: %s)", 
                count, 
                unitID .. " - " .. unitName, 
                guid:sub(1, 8)
            ))
            Print(string.format("   Has container: %s, Visible: %s", 
                tostring(hasContainer),
                hasContainer and tostring(DebuffContainers[unitID]:IsVisible()) or "N/A"
            ))
            
            -- Count visible debuffs
            if hasContainer then
                local visibleDebuffs = 0
                for i, icon in ipairs(DebuffContainers[unitID].icons) do
                    if icon:IsVisible() then
                        visibleDebuffs = visibleDebuffs + 1
                    end
                end
                Print("   Visible debuffs: " .. visibleDebuffs)
            end
        end
    end
    
    if count > 5 then
        Print("...and " .. (count - 5) .. " more nameplates")
    end
end

-- Start the module
VeiPlatesAuras:Initialize()