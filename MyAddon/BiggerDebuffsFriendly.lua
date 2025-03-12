local addonName, addon = ...

-- Create/initialize friendly buff tracking module
addon.FriendlyBuffTracker = addon.FriendlyBuffTracker or {}
local FriendlyBuffTracker = addon.FriendlyBuffTracker

-- Debug settings (set to false for production)
local DEBUG = false
local function debugPrint(...)
    if DEBUG then
        print("|cFF00FFAA[FriendlyBuffTracker]|r", ...)
    end
end

-- Check for Masque
local MSQ = LibStub and LibStub("Masque", true)
local masqueGroup -- Will be initialized later if MSQ is available

-- Configuration
local CONFIG = {
    -- Tracked spells with their icon IDs for fallback
    spells = {
        -- Immunities (highest priority)
        [8178] = { iconID = 136039 },  -- Grounding totem effect
        [48707] = { iconID = 136120, priority = 1 },  -- Grounding totem effect
        [31224] = { iconID = 136177, priority = 1 },  -- Cloak of Shadows
        [23920] = { iconID = 132361, priority = 1 },  -- Spell Reflection
        [34471] = { iconID = 132166, priority = 1 },  -- The Beast Within
        [47585] = { iconID = 237563, priority = 1 },  -- Dispersion
        [1022] = { iconID = 135964, priority = 1 },   -- Blessing of Protection
        [642] = { iconID = 524354, priority = 1 },    -- Divine Shield
        [19263] = { iconID = 132369, priority = 1 },  -- Deterrence
        [45438] = { iconID = 135841, priority = 1 },  -- Ice Block
        [46924] = { iconID = 236303, priority = 1 },  -- Bladestorm
--cc

        [853] = { iconID = 135963, priority = 2 },  -- Hammer of Justice
        [20066] = { iconID = 135942, priority = 2 },  -- Repentance
        [2637] = { iconID = 136090, priority = 2 },  -- Hibernate
        [20549] = { iconID = 132368, priority = 2 },  -- War Stomp
        [28730] = { iconID = 136222, priority = 2 },  -- Arcane Torrent (Mana)
        [25046] = { iconID = 136222, priority = 2 },  -- Arcane Torrent (Energy)
        [50613] = { iconID = 136222, priority = 2 },  -- Arcane Torrent (Runic Power)
        [47476] = { iconID = 136214, priority = 2 },  -- Strangulate
        [91800] = { iconID = 237524, priority = 2 },  -- Gnaw
        [49203] = { iconID = 135152, priority = 2 },  -- Hungering Cold
        [91797] = { iconID = 135860, priority = 2 },  -- Monstrous Blow (DK Abom stun)
        [64044] = { iconID = 237568, priority = 2 },  -- Psychic Horror (Horrify)
        [605] = { iconID = 136206, priority = 2 },  -- Mind Control
        [8122] = { iconID = 136184, priority = 2 },  -- Psychic Scream
        [15487] = { iconID = 458230, priority = 2 },  -- Silence
        [9484] = { iconID = 136091, priority = 2 },  -- Shackle Undead
        [87204] = { iconID = 135945, priority = 2 },  -- Sin and Punishment (VT dispel)
        [60995] = { iconID = 135860, priority = 2 },  -- Demon Charge (Metamorphosis)
        [24259] = { iconID = 136174, priority = 2 },  -- Spell Lock Silence
        [6358] = { iconID = 136175, priority = 2 },  -- Seduction
        [5782] = { iconID = 136183, priority = 2 },  -- Fear
        [5484] = { iconID = 136147, priority = 2 },  -- Howl of Terror
        [710] = { iconID = 136135, priority = 2 },  -- Banish
        [6789] = { iconID = 136145, priority = 2 },  -- Death Coil
        [22703] = { iconID = 135860, priority = 2 },  -- Inferno Effect
        [30283] = { iconID = 136201, priority = 2 },  -- Shadowfury
        [31117] = { iconID = 135975, priority = 2 },  -- Unstable Affliction Silence
        [89766] = { iconID = 236316, priority = 2 },  -- Axe Toss (felguard stun)
        [51514] = { iconID = 237579, priority = 2 },  -- Hex
        [58861] = { iconID = 132114, priority = 2 },  -- Bash (Spirit Wolf)
        [1513] = { iconID = 132118, priority = 2 },  -- Scare Beast
        [3355] = { iconID = 135834, priority = 2 },  -- Freezing Trap
        [19386] = { iconID = 135125, priority = 2 },  -- Wyvern Sting
        [19503] = { iconID = 132153, priority = 2 },  -- Scatter Shot
        [34490] = { iconID = 132323, priority = 2 },  -- Silencing Shot
        [90337] = { iconID = 132159, priority = 2 },  -- Bad Manner (monkey stun)
        [50519] = { iconID = 132182, priority = 2 },  -- Sonic Blast (bat pet stun)
        [50541] = { iconID = 132195, priority = 2 },  -- Clench (scorpid pet disarm)
        [91644] = { iconID = 136063, priority = 2 },  -- Snatch (bird of prey pet disarm)
        [50318] = { iconID = 135900, priority = 2 },  -- Serenity Dust (moth pet silence)
        [56626] = { iconID = 136093, priority = 2 },  -- Sting (wasp pet stun)
        [22570] = { iconID = 132134, priority = 2 },  -- Maim
        [9005] = { iconID = 132142, priority = 2 },  -- Pounce Stun
        [5211] = { iconID = 132114, priority = 2 },  -- Bash
        [33786] = { iconID = 136022, priority = 2 },  -- Cyclone
        [81261] = { iconID = 252188, priority = 2 },  -- Solar Beam
        [44572] = { iconID = 236214, priority = 2 },  -- Deep Freeze
        [55021] = { iconID = 135856, priority = 2 },  -- Improved Counterspell
        [82691] = { iconID = 464484, priority = 2 },  -- Ring of Frost
        [18469] = { iconID = 135856, priority = 2 },  -- Improved Counterspell
        [118] = { iconID = 136071, priority = 2 },  -- Polymorph
        [28271] = { iconID = 132199, priority = 2 },  -- polymorph turtle
        [28272] = { iconID = 135997, priority = 2 },  -- polymorph pig
        [71319] = { iconID = 236708, priority = 2 },  -- polymorph turkey
        [61305] = { iconID = 236547, priority = 2 },  -- polymorph cat
        [61721] = { iconID = 319458, priority = 2 },  -- polymorph rabbit
        [12355] = { iconID = 135821, priority = 2 },  -- Impact Stun
        [31661] = { iconID = 134153, priority = 2 },  -- Dragon's Breath
        [51722] = { iconID = 236272, priority = 2 },  -- Dismantle
        [1833] = { iconID = 132092, priority = 2 },  -- Cheap Shot
        [408] = { iconID = 132298, priority = 2 },  -- Kidney Shot
        [6770] = { iconID = 132310, priority = 2 },  -- Sap
        [2094] = { iconID = 136175, priority = 2 },  -- Blind
        [1776] = { iconID = 132155, priority = 2 },  -- Gouge
        [1330] = { iconID = 132297, priority = 2 },  -- Garrote Silence
        [46968] = { iconID = 236312, priority = 2 },  -- Shockwave
        [85388] = { iconID = 133542, priority = 2 },  -- Throwdown
        [20253] = { iconID = 135860, priority = 2 },  -- Intercept Stun
        [20615] = { iconID = 135860, priority = 2 },  -- intercept 2
        [12809] = { iconID = 132325, priority = 2 },  -- Concussion Blow
        [7922] = { iconID = 135860, priority = 2 },  -- Charge Stun
        [5246] = { iconID = 132154, priority = 2 },  -- Intimidating Shout
        [20511] = { iconID = 132154, priority = 2 },  -- Intimidating shout 2

        --roots
        [45524] = { iconID = 135834, priority = 3 },  -- Chains of Ice
        [122] = { iconID = 135848, priority = 3 },  -- Frost Nova
        [19185] = { iconID = 136100, priority = 3 },  -- Entrapment
        [64803] = { iconID = 136100, priority = 3 },  -- Entrapment 2
        [339] = { iconID = 136100, priority = 3 },  -- Entangling Roots
        [19975] = { iconID = 136100, priority = 3 },  -- (parent = 339) - entaling roots 2
        [33395] = { iconID = 135848, priority = 3 },  -- Freeze
        [83302] = { iconID = 135852, priority = 3 },  -- Improved Cone of Cold
        [45334] = { iconID = 132183, priority = 3 },  -- Feral Charge Effect




    },






    
    -- Tracked units
    units = {
        "player",
        "party1",
        "party2",
        "party3",
        "party4"
    },
    
    -- Fixed positions for each unit
    positions = {
        player = { x = 760, y = 380 },
        party1 = { x = 356.5, y = 391.5 },
        party2 = { x = 356.5, y = 330.5 },
        party3 = { x = 356.5, y = 300 },
        party4 = { x = 356.5, y = 260 }
    },
    
    -- Display settings
    frameSize = 38,              -- Size of the icons
    frameSpacing = 2.5,          -- Spacing between frames
    frameStrata = "HIGH",        -- Frame strata
    updateThrottleDelay = 0.05,  -- Delay between throttled updates (in seconds)
    periodicUpdateInterval = 1.0, -- How often to do full refresh (in seconds)
    
    -- Priority settings
    preferLongestDuration = true, -- Always prefer longest duration aura when priorities are equal
}

-- Frame tracking
local frames = {
    unitToFrame = {}  -- Map unit IDs to their tracker frames
}

-- Optimization: Pre-compile spell lookup table
local spellLookup = {}
for spellID, _ in pairs(CONFIG.spells) do
    spellLookup[spellID] = true
end

-- Track current auras for change detection
local currentAuras = {}

-- Create a frame to track auras for a specific unit
local function CreateTrackingFrame(unit)
    local frameName = "FriendlyBuffTracker_" .. unit
    local frame = CreateFrame("Button", frameName, UIParent)
    frame.unit = unit
    
    -- Set size and strata
    frame:SetSize(CONFIG.frameSize, CONFIG.frameSize)
    frame:SetFrameStrata(CONFIG.frameStrata)
    frame:Hide() -- Hide by default
    
    -- Position at fixed location
    local position = CONFIG.positions[unit]
    if position then
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", position.x, position.y)
    else
        -- Default position if not specified
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    -- Create background texture
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.5)
    frame.background = background
    
    -- Create icon texture
    local icon = frame:CreateTexture(nil, "BORDER")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trim icon edges
    frame.icon = icon
    
    -- Create normal texture
    local normalTexture = frame:CreateTexture(nil, "ARTWORK")
    normalTexture:SetAllPoints()
    normalTexture:SetAlpha(1)
    normalTexture:SetVertexColor(1, 1, 1, 1)
    frame:SetNormalTexture(normalTexture)
    frame.normalTexture = normalTexture
    
    -- Create cooldown frame
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(true)
    cooldown:SetHideCountdownNumbers(false)
    frame.cooldown = cooldown
    
    -- Create count text
    local count = frame:CreateFontString(nil, "OVERLAY")
    count:SetFont("Fonts\\FRIZQT__.TTF", CONFIG.frameSize/3, "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", 2, 0)
    count:Hide()
    frame.count = count
    
    -- Method to refresh visual state
    frame.RefreshVisuals = function(self)
        icon:SetAlpha(1)
        icon:SetVertexColor(1, 1, 1, 1)
        normalTexture:SetAlpha(1)
        normalTexture:SetVertexColor(1, 1, 1, 1)
        background:SetAlpha(0.5)
    end
    
    -- Add Masque support
    if MSQ then
        if not masqueGroup then
            masqueGroup = MSQ:Group(addonName, "Friendly Buffs")
        end
        
        masqueGroup:AddButton(frame, {
            Icon = icon,
            Normal = normalTexture,
            Cooldown = cooldown,
            Count = count,
            Disabled = false,
            Pushed = false,
            Colors = {
                Normal = {1, 1, 1, 1},
                Disabled = {1, 1, 1, 1}
            }
        })
    end
    
    -- Hook SetNormalTexture to maintain alpha
    local oldSetNormalTexture = frame.SetNormalTexture
    frame.SetNormalTexture = function(self, tex)
        oldSetNormalTexture(self, tex)
        self:RefreshVisuals()
    end
    
    return frame
end

-- Get the highest priority aura for a unit
local function GetHighestPriorityAura(unit)
    -- Return empty if unit doesn't exist
    if not unit or not UnitExists(unit) then
        return nil
    end
    
    -- Initialize tracking for highest priority aura
    local highestPriorityAura = nil
    local highestPriority = 999
    local longestDuration = 0
    local currentTime = GetTime()
    
    -- Scan buffs
    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitBuff(unit, i)
        if not name then break end
        
        if spellLookup[spellID] and CONFIG.spells[spellID] then
            local priority = CONFIG.spells[spellID].priority or 999
            local remainingTime = 0
            
            -- Calculate remaining time
            if duration and duration > 0 and expirationTime then
                remainingTime = expirationTime - currentTime
            elseif duration == 0 then
                -- For auras with no duration (permanent buffs), treat as very long
                remainingTime = 9999
            end
            
            -- If higher priority, always take it
            if priority < highestPriority then
                highestPriorityAura = {
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    spellID = spellID,
                    priority = priority,
                    remainingTime = remainingTime
                }
                highestPriority = priority
                longestDuration = remainingTime
            -- If same priority but longer duration, prefer it
            elseif priority == highestPriority and remainingTime > longestDuration then
                highestPriorityAura = {
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    spellID = spellID,
                    priority = priority,
                    remainingTime = remainingTime
                }
                longestDuration = remainingTime
            end
        end
    end
    
    -- Scan debuffs
    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitDebuff(unit, i)
        if not name then break end
        
        if spellLookup[spellID] and CONFIG.spells[spellID] then
            local priority = CONFIG.spells[spellID].priority or 999
            local remainingTime = 0
            
            -- Calculate remaining time
            if duration and duration > 0 and expirationTime then
                remainingTime = expirationTime - currentTime
            elseif duration == 0 then
                -- For auras with no duration (permanent debuffs), treat as very long
                remainingTime = 9999
            end
            
            -- If higher priority, always take it
            if priority < highestPriority then
                highestPriorityAura = {
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    spellID = spellID,
                    priority = priority,
                    remainingTime = remainingTime
                }
                highestPriority = priority
                longestDuration = remainingTime
            -- If same priority but longer duration, prefer it
            elseif priority == highestPriority and remainingTime > longestDuration then
                highestPriorityAura = {
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    spellID = spellID,
                    priority = priority,
                    remainingTime = remainingTime
                }
                longestDuration = remainingTime
            end
        end
    end
    
    if DEBUG and highestPriorityAura then
        debugPrint(unit, "Showing aura:", highestPriorityAura.name, 
                  "Priority:", highestPriorityAura.priority, 
                  "Remaining:", highestPriorityAura.remainingTime)
    end
    
    return highestPriorityAura
end

-- Update specific unit's display frame
local function UpdateUnitFrame(unit)
    local frame = frames.unitToFrame[unit]
    if not frame then return end
    
    if not UnitExists(unit) then
        frame:Hide()
        currentAuras[unit] = nil
        return
    end
    
    -- Get best aura
    local aura = GetHighestPriorityAura(unit)
    
    -- Check if current state is already displayed
    local currentAura = currentAuras[unit]
    local needsUpdate = false
    
    if (not currentAura and aura) or 
       (currentAura and not aura) or
       (currentAura and aura and (
            currentAura.spellID ~= aura.spellID or
            currentAura.expirationTime ~= aura.expirationTime or
            currentAura.count ~= aura.count
       )) then
        needsUpdate = true
    end
    
    if needsUpdate then
        if aura then
            -- Update the icon
            frame.icon:SetTexture(aura.icon or CONFIG.spells[aura.spellID].iconID)
            
            -- Update cooldown
            if aura.duration and aura.duration > 0 then
                frame.cooldown:SetCooldown(
                    aura.expirationTime - aura.duration,
                    aura.duration
                )
            else
                frame.cooldown:Clear()
            end
            
            -- Update count
            if aura.count and aura.count > 1 then
                frame.count:SetText(aura.count)
                frame.count:Show()
            else
                frame.count:Hide()
            end
            
            -- Store current state
            currentAuras[unit] = {
                spellID = aura.spellID,
                expirationTime = aura.expirationTime,
                count = aura.count
            }
            
            -- Show the frame
            frame:Show()
            frame:RefreshVisuals()
        else
            -- No aura to display, hide frame
            frame:Hide()
            currentAuras[unit] = nil
            frame.cooldown:Clear()
            frame.count:Hide()
        end
    end
end

-- Initialize frames for each tracked unit
local function InitializeFrames()
    debugPrint("Initializing frames for tracked units")
    
    -- Initialize Masque group if available
    if MSQ and not masqueGroup then
        masqueGroup = MSQ:Group(addonName, "Friendly Buffs")
        
        -- Add a callback for when skins change
        if masqueGroup then
            masqueGroup.SkinChanged = function()
                C_Timer.After(0.1, function()
                    for _, frame in pairs(frames.unitToFrame) do
                        if frame.RefreshVisuals then
                            frame:RefreshVisuals()
                        end
                    end
                end)
            end
        end
    end
    
    -- Create frames for all configured units
    for _, unit in ipairs(CONFIG.units) do
        if not frames.unitToFrame[unit] then
            frames.unitToFrame[unit] = CreateTrackingFrame(unit)
        end
    end
    
    -- Initial update for all units
    UpdateAllFrames()
end

-- Update all unit frames at once
function UpdateAllFrames()
    if InCombatLockdown() then
        -- During combat, only update if necessary
        for _, unit in ipairs(CONFIG.units) do
            if UnitExists(unit) then
                UpdateUnitFrame(unit)
            end
        end
    else
        -- Out of combat, do full update
        for _, unit in ipairs(CONFIG.units) do
            UpdateUnitFrame(unit)
        end
        
        -- Apply Masque skins if available
        if MSQ and masqueGroup then
            masqueGroup:ReSkin()
        end
    end
end

-- Unit update map to track which units need updating
local unitsToUpdate = {}

-- Request an update for a specific unit
local function RequestUnitUpdate(unit)
    unitsToUpdate[unit] = true
end

-- Create throttled batch processor for unit updates
local updateProcessor = CreateFrame("Frame")
updateProcessor:Hide()
updateProcessor.sinceLastUpdate = 0
updateProcessor:SetScript("OnUpdate", function(self, elapsed)
    self.sinceLastUpdate = self.sinceLastUpdate + elapsed
    if self.sinceLastUpdate >= CONFIG.updateThrottleDelay then
        self.sinceLastUpdate = 0
        
        -- Process all requested updates
        for unit in pairs(unitsToUpdate) do
            UpdateUnitFrame(unit)
            unitsToUpdate[unit] = nil
        end
        
        -- Hide if no more updates
        if not next(unitsToUpdate) then
            self:Hide()
        end
    end
end)

-- Periodic update timer
local periodicTimer = 0
local periodicUpdateFrame = CreateFrame("Frame")
periodicUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    periodicTimer = periodicTimer + elapsed
    if periodicTimer >= CONFIG.periodicUpdateInterval then
        periodicTimer = 0
        UpdateAllFrames()
    end
end)

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Combat start
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Combat end

-- Event handling
eventFrame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "UNIT_AURA" then
        -- Only process tracked units
        for _, trackedUnit in ipairs(CONFIG.units) do
            if unit == trackedUnit then
                RequestUnitUpdate(unit)
                updateProcessor:Show() -- Start the throttled update processor
                break
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Fully refresh everything on login/reload
        currentAuras = {}
        C_Timer.After(0.5, function()
            InitializeFrames()
        end)
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Group changes, update all frames with a small delay
        C_Timer.After(0.5, function()
            UpdateAllFrames()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        -- Combat state changed, do a full update
        C_Timer.After(0.1, UpdateAllFrames)
    end
end)

-- Public API for the module

-- Start tracking auras
function FriendlyBuffTracker:Start()
    debugPrint("Starting friendly buff tracking")
    InitializeFrames()
    periodicUpdateFrame:Show() -- Start periodic updates
end

-- Stop tracking auras
function FriendlyBuffTracker:Stop()
    debugPrint("Stopping friendly buff tracking")
    
    for _, frame in pairs(frames.unitToFrame) do
        frame:Hide()
    end
    
    currentAuras = {}
    periodicUpdateFrame:Hide() -- Stop periodic updates
end

-- Update configuration
function FriendlyBuffTracker:UpdateConfig(newConfig)
    for key, value in pairs(newConfig or {}) do
        CONFIG[key] = value
    end
    
    -- Reset frames to apply new settings
    self:Stop()
    self:Start()
end

-- Get current configuration
function FriendlyBuffTracker:GetConfig()
    return CONFIG
end

-- Set position for a specific unit
function FriendlyBuffTracker:SetUnitPosition(unit, x, y)
    if CONFIG.positions[unit] then
        CONFIG.positions[unit].x = x
        CONFIG.positions[unit].y = y
        
        -- Update frame position if it exists
        if frames.unitToFrame[unit] then
            frames.unitToFrame[unit]:ClearAllPoints()
            frames.unitToFrame[unit]:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        end
    end
end

-- Expose testing function
function FriendlyBuffTracker:TestAuraDetection(unit, spellID)
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, id = UnitBuff(unit, i)
        if id == spellID then
            print("FOUND BUFF:", name, "ID:", id, "on unit:", unit)
            return true
        end
    end
    
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, id = UnitDebuff(unit, i)
        if id == spellID then
            print("FOUND DEBUFF:", name, "ID:", id, "on unit:", unit)
            return true
        end
    end
    
    print("No aura with ID", spellID, "found on", unit)
    return false
end

-- Register slash command for testing
SLASH_FBTRACKER1 = "/fbtrack"
SlashCmdList["FBTRACKER"] = function(msg)
    local cmd, args = strsplit(" ", msg, 2)
    cmd = cmd:lower()
    
    if cmd == "test" then
        local unit, spellID = args:match("(%S+)%s+(%d+)")
        if unit and spellID then
            FriendlyBuffTracker:TestAuraDetection(unit, tonumber(spellID))
        else
            print("Usage: /fbtrack test [unit] [spellID]")
        end
    elseif cmd == "pos" then
        local unit, x, y = args:match("(%S+)%s+(%d+)%s+(%d+)")
        if unit and x and y then
            FriendlyBuffTracker:SetUnitPosition(unit, tonumber(x), tonumber(y))
            print("Set position for " .. unit .. " to X: " .. x .. ", Y: " .. y)
        else
            print("Usage: /fbtrack pos [unit] [x] [y]")
        end
    elseif cmd == "size" and tonumber(args) then
        CONFIG.frameSize = tonumber(args)
        FriendlyBuffTracker:UpdateConfig()
        print("Set icon size to " .. args)
    elseif cmd == "debug" then
        DEBUG = not DEBUG
        print("Debug mode: " .. (DEBUG and "On" or "Off"))
    elseif cmd == "status" then
        print("Status: Tracking " .. (eventFrame:IsEventRegistered("UNIT_AURA") and "enabled" or "disabled"))
        print("Debug: " .. (DEBUG and "On" or "Off"))
        print("Positions:")
        for unit, pos in pairs(CONFIG.positions) do
            print("  " .. unit .. ": X=" .. pos.x .. ", Y=" .. pos.y)
        end
    else
        print("Friendly Buff Tracker commands:")
        print("  /fbtrack test [unit] [spellID] - Test aura detection")
        print("  /fbtrack pos [unit] [x] [y] - Set position for a unit")
        print("  /fbtrack size [number] - Set icon size")
        print("  /fbtrack debug - Toggle debug mode")
        print("  /fbtrack status - Show current status and settings")
    end
end

-- Initialize on load
C_Timer.After(1, function()
    FriendlyBuffTracker:Start()
end)

-- Return the module
return FriendlyBuffTracker