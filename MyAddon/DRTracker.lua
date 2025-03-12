------------------------------------------------------------
-- Optimized DR Tracker for Arena Units
------------------------------------------------------------

local addonName, addon = ...

-- Configuration section - modify the border colors to have 0 alpha
local CONFIG = {
    -- Duration for each DR trigger (in seconds)
    DRDuration = 20,
    
    -- Units to track
    unitsToTrack = {"arena1", "arena2", "arena3"},
    
    -- Container positions
    unitPositions = {
        arena1 = { anchor = "TOPRIGHT", relativePoint = "BOTTOMRIGHT", x = 319, y = 112 },
        arena2 = { anchor = "TOPRIGHT", relativePoint = "BOTTOMRIGHT", x = 319, y = 40 },
        arena3 = { anchor = "TOPRIGHT", relativePoint = "BOTTOMRIGHT", x = 319, y = -30},
    },
    
    -- Icon settings
    iconSize = 25,
    iconSpacing = 5,
    borderSize = 2,
    
    -- Border colors based on DR level - set alpha to 0 to make them invisible
    borderColors = {
        [1] = {0, 1, 0, 0},     -- Green (first application) - alpha set to 0
        [2] = {1, 1, 0, 0},     -- Yellow (second application - 50% duration) - alpha set to 0
        [3] = {1, 0, 0, 0}      -- Red (third application - 25% duration) - alpha set to 0
    },
    
    -- Performance settings
    updateThrottleDelay = 0.1,  -- Time between each update of the DR display
    cleanupInterval = 1.0,      -- Time between each cleanup of expired DRs
}

-- Debug settings
local DEBUG = false
local function debugPrint(...)
    if DEBUG then
        print("|cFFAAFFAA[DRTracker]|r", ...)
    end
end

-- Define DR categories and their associated spell IDs
local DRSpellList = {
    Stuns = {
        [5211] = true,  -- Bash
        [9005] = true,  -- Pounce
        [47481] = true, -- Gnaw (Ghoul Pet)
        [91797] = true, -- Monstrous Blow (Dark Transformation)
        [22570] = true, -- Maim
        [90337] = true, -- Bad Manner (Monkey)
        [93433] = true, -- Burrow Attack (Worm)
        [24394] = true, -- Intimidation
        [56626] = true, -- Sting (Wasp)
        [50519] = true, -- Sonic Blast
        [44572] = true, -- Deep Freeze (Also shares DR with Ring of Frost)
        [83046] = true, -- Improved Polymorph (Rank 1)
        [83047] = true, -- Improved Polymorph (Rank 2)
        [853] = true,   -- Hammer of Justice
        [2812] = true,  -- Holy Wrath
        [408] = true,   -- Kidney Shot
        [1833] = true,  -- Cheap Shot
        [58861] = true, -- Bash (Spirit Wolves)
        [39796] = true, -- Stoneclaw Stun
        [93986] = true, -- Aura of Foreboding
        [89766] = true, -- Axe Toss (Felguard)
        [54786] = true, -- Demon Leap
        [22703] = true, -- Inferno Effect
        [30283] = true, -- Shadowfury
        [12809] = true, -- Concussion Blow
        [46968] = true, -- Shockwave
        [85388] = true, -- Throwdown
        [20549] = true, -- War Stomp (Racial)
    },
    Roots = {
        [339] = true,   -- Entangling Roots
        [96293] = true, -- Chains of Ice (Chilblains Rank 1)
        [96294] = true, -- Chains of Ice (Chilblains Rank 2)
        [19975] = true, -- Nature's Grasp
        [90327] = true, -- Lock Jaw (Dog)
        [54706] = true, -- Venom Web Spray (Silithid)
        [50245] = true, -- Pin (Crab)
        [4167] = true,  -- Web (Spider)
        [33395] = true, -- Freeze (Water Elemental)
        [122] = true,   -- Frost Nova
        [87193] = true, -- Paralysis
        [64695] = true, -- Earthgrab
        [63685] = true, -- Freeze (Frost Shock)
        [39965] = true, -- Frost Grenade (Item)
        [55536] = true, -- Frostweave Net (Item)
    },
    Cyclone = {
        [33786] = 136022, -- cyclone
    },
    Incapacitates = {
        [49203] = true, -- Hungering Cold
        [2637] = true,  -- Hibernate
        [3355] = true,  -- Freezing Trap Effect
        [19386] = true, -- Wyvern Sting
        [118] = true,   -- Polymorph
        [28271] = true, -- Polymorph: Turtle
        [28272] = true, -- Polymorph: Pig
        [61025] = true, -- Polymorph: Serpent
        [61721] = true, -- Polymorph: Rabbit
        [61780] = true, -- Polymorph: Turkey
        [61305] = true, -- Polymorph: Black Cat
        [82691] = true, -- Ring of Frost
        [20066] = true, -- Repentance
        [1776] = true,  -- Gouge
        [6770] = true,  -- Sap
        [710] = true,   -- Banish
        [9484] = true,  -- Shackle Undead
        [51514] = true, -- Hex
        [44572] = true, -- Deep Freeze
    },
    Fears = {
        [1513] = true,  -- Scare Beast
        [10326] = true, -- Turn Evil
        [8122] = true,  -- Psychic Scream
        [2094] = true,  -- Blind
        [5782] = true,  -- Fear
        [6358] = true,  -- Seduction (Succubus)
        [5484] = true,  -- Howl of Terror
        [5246] = true,  -- Intimidating Shout
        [20511] = true, -- Intimidating Shout (secondary targets)
        [5134] = true,  -- Flash Bomb Fear (Item)
    },
    RandomStuns = {
        [12355] = true, -- Impact
        [85387] = true, -- Aftermath
        [15283] = true, -- Stunning Blow (Weapon Proc)
        [56] = true,    -- Stun (Weapon Proc)
        [34510] = true, -- Stormherald/Deep Thunder (Weapon Proc)
    },
    Disarms = {
        [50541] = true, -- Clench (Scorpid)
        [91644] = true, -- Snatch (Bird of Prey)
        [64058] = true, -- Psychic Horror Disarm Effect
        [51722] = true, -- Dismantle
        [676] = true,   -- Disarm
    },
    Scatters = {
        [19503] = true, -- Scatter Shot
        [31661] = true, -- Dragon's Breath
    },
    DeepRof = {
    },
    RandomRoots = {
        [19185] = true, -- Entrapment (Rank 1)
        [64803] = true, -- Entrapment (Rank 2)
        [47168] = true, -- Improved Wing Clip
        [83301] = true, -- Improved Cone of Cold (Rank 1)
        [83302] = true, -- Improved Cone of Cold (Rank 2)
        [55080] = true, -- Shattered Barrier (Rank 1)
        [83073] = true, -- Shattered Barrier (Rank 2)
        [23694] = true, -- Improved Hamstring
    },
    Horrors = {
        [64044] = true, -- Psychic Horror
        [6789] = true,  -- Death Coil
    },
    MindControl = {
        [605] = true,   -- Mind Control
        [13181] = true, -- Gnomish Mind Control Cap (Item)
        [67799] = true, -- Mind Amplification Dish (Item)
    },
    Silences = {
        [47476] = true, -- Strangulate
        [50479] = true, -- Nether Shock (Nether Ray)
        [34490] = true, -- Silencing Shot
        [18469] = true, -- Silenced - Improved Counterspell (Rank 1)
        [55021] = true, -- Silenced - Improved Counterspell (Rank 2)
        [31935] = true, -- Avenger's Shield
        [15487] = true, -- Silence
        [1330] = true,  -- Garrote - Silence
        [18425] = true, -- Silenced - Improved Kick
        [86759] = true, -- Silenced - Improved Kick (Rank 2)
        [24259] = true, -- Spell Lock
        [18498] = true, -- Silenced - Gag Order
        [50613] = true, -- Arcane Torrent (Racial, Runic Power)
        [28730] = true, -- Arcane Torrent (Racial, Mana)
        [25046] = true, -- Arcane Torrent (Racial, Energy)
        [69179] = true, -- Arcane Torrent (Rage version)
        [80483] = true, -- Arcane Torrent (Focus version)
    }
}

-- Optimization: Pre-compile spell to category lookup
local spellToCategoryMap = {}
local function BuildSpellLookupTable()
    for category, spells in pairs(DRSpellList) do
        for spellId, value in pairs(spells) do
            spellToCategoryMap[spellId] = category
        end
    end
    
    -- Count total spells
    local totalSpells = 0
    for _ in pairs(spellToCategoryMap) do
        totalSpells = totalSpells + 1
    end
    
    debugPrint("Built spell lookup table with", totalSpells, "spells across", #DRSpellList, "categories")
end

-- Data structure to track DR events for each unit
local DRData = {}

-- Create container frames for tracked units
local function CreateDRContainers()
    for _, unit in ipairs(CONFIG.unitsToTrack) do
        local parent = _G[unit]
        if not parent then
            -- Create a dummy frame for testing if the arena frame doesn't exist
            parent = CreateFrame("Frame", "DRDummy_" .. unit, UIParent)
            parent:SetSize(100, 100)
            parent:SetPoint("CENTER", UIParent, "CENTER")
            debugPrint("Created dummy parent frame for", unit)
        end
        
        local pos = CONFIG.unitPositions[unit] or { anchor = "TOPRIGHT", relativePoint = "BOTTOMRIGHT", x = 0, y = 0 }
        local container = CreateFrame("Frame", "DRContainer_" .. unit, parent)
        container:SetSize(400, 36)  -- Width to accommodate multiple icons, height for one row
        container:SetPoint(pos.anchor, parent, pos.relativePoint, pos.x, pos.y)
        
        DRData[unit] = {
            container = container,
            activeDREvents = {},  -- Keyed by DR category
            DRIcons = {},         -- Array of icon frames (ordered right-to-left)
            guid = nil,           -- Track unit GUID for arena swaps
            needsUpdate = false   -- Flag to mark when display needs updating
        }
        
        debugPrint("Created DR container for", unit)
    end
end


-- Create a single DR icon frame
local function CreateDRIcon()
    local icon = CreateFrame("Frame", nil, UIParent)  -- Will be reparented later
    icon:SetSize(CONFIG.iconSize, CONFIG.iconSize)
    
    -- Border
    icon.border = icon:CreateTexture(nil, "BACKGROUND")
    icon.border:SetSize(CONFIG.iconSize + CONFIG.borderSize * 2, CONFIG.iconSize + CONFIG.borderSize * 2)
    icon.border:SetPoint("CENTER", icon, "CENTER", 0, 0)
    icon.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    
    -- Icon texture
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints(icon)
    icon.texture:SetTexture("")
    
    -- Cooldown frame
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon)
    icon.cooldown:SetDrawEdge(true)
    icon.cooldown:SetDrawSwipe(true)
    
    -- Counter text
    icon.count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    
    -- Add tracking variables for cooldown persistence
    icon.cooldownStartTime = 0
    icon.cooldownDuration = 0
    icon.drCategory = nil
    
    return icon
end

-- Handle a DR trigger for a unit
local function HandleDRTriggerForUnit(unit, spellId)
    local guid = UnitGUID(unit)
    if not guid then return end
    
    -- Check if unit exists in our tracking
    local data = DRData[unit]
    if not data then return end
    
    -- Update GUID if needed
    if data.guid ~= guid then
        data.guid = guid
        data.activeDREvents = {}  -- Reset on unit change
        debugPrint("Unit", unit, "GUID changed -", guid)
    end
    
    -- Find which DR category this spell belongs to
    local category = spellToCategoryMap[spellId]
    if not category then 
        -- Not a tracked DR spell
        return 
    end
    
    local now = GetTime()
    
    -- Update or create DR event
    local event = data.activeDREvents[category]
    if event then
        -- Existing DR for this category
        if event.level < 3 then
            event.level = event.level + 1
        end
        event.expiration = now + CONFIG.DRDuration
        event.lastSpellId = spellId
        debugPrint(unit, "DR updated:", category, "Level:", event.level)
    else
        -- New DR for this category
        data.activeDREvents[category] = {
            category = category,
            level = 1,
            expiration = now + CONFIG.DRDuration,
            triggerTime = now,
            lastSpellId = spellId
        }
        debugPrint(unit, "New DR:", category, "SpellID:", spellId)
    end
    
    -- Mark for update
    data.needsUpdate = true
end

-- Remove expired DR events
local function CleanupExpiredDRs()
    local now = GetTime()
    local eventsRemoved = false
    
    for unit, data in pairs(DRData) do
        local hadExpired = false
        
        for category, event in pairs(data.activeDREvents) do
            if event.expiration <= now then
                data.activeDREvents[category] = nil
                eventsRemoved = true
                hadExpired = true
                debugPrint(unit, "DR expired:", category)
            end
        end
        
        -- If we removed any events, mark for update
        if hadExpired then
            data.needsUpdate = true
            displayUpdater:Show() -- Make sure updater runs after expiration
        end
    end
    
    return eventsRemoved
end

-- Get sorted DR events for a unit (oldest first)
local function GetSortedDREventsForUnit(unit)
    local data = DRData[unit]
    if not data then return {} end
    
    local events = {}
    for _, event in pairs(data.activeDREvents) do
        table.insert(events, event)
    end
    
    table.sort(events, function(a, b)
        return a.triggerTime < b.triggerTime
    end)
    
    return events
end

-- Update the DR display for a unit
local function UpdateDRDisplayForUnit(unit)
    local data = DRData[unit]
    if not data or not data.container then 
        debugPrint("ERROR: No data or container for unit", unit)
        return 
    end
    
    local events = GetSortedDREventsForUnit(unit)
    local now = GetTime()
    
    -- Debug logging only if DEBUG is true
    if DEBUG then
        if #events == 0 then
            debugPrint("No active DR events for", unit)
        else
            debugPrint("Updating", #events, "DR events for", unit)
        end
    end
    
    -- Store existing cooldown information before updating
    local existingCooldowns = {}
    for i, icon in ipairs(data.DRIcons) do
        if icon:IsShown() then
            existingCooldowns[icon.drCategory] = {
                startTime = icon.cooldownStartTime,
                duration = icon.cooldownDuration
            }
        end
    end
    
    -- Process each active DR event
    for i, event in ipairs(events) do
        -- Get or create an icon
        local icon = data.DRIcons[i]
        if not icon then
            icon = CreateDRIcon()
            icon:SetParent(data.container)
            data.DRIcons[i] = icon
            debugPrint("Created new DR icon for", unit, "- slot", i)
        end
        
        -- Store the DR category for this icon (for cooldown persistence)
        icon.drCategory = event.category
        
        -- Update icon appearance
        local remaining = event.expiration - now
        local texture = GetSpellTexture(event.lastSpellId)
        
        if not texture or texture == "" then
            texture = "Interface\\Icons\\INV_Misc_QuestionMark"
            debugPrint("WARNING: No texture for spell", event.lastSpellId, "- using placeholder")
        end
        
        icon.texture:SetTexture(texture)
        
        -- Check if we have existing cooldown info for this category
        if existingCooldowns[event.category] then
            -- Reuse the existing cooldown start/duration
            local cd = existingCooldowns[event.category]
            icon.cooldownStartTime = cd.startTime
            icon.cooldownDuration = cd.duration
            icon.cooldown:SetCooldown(cd.startTime, cd.duration)
            debugPrint("Preserving cooldown for", event.category, "- start:", cd.startTime, "duration:", cd.duration)
        else
            -- New cooldown
            icon.cooldownStartTime = now - (CONFIG.DRDuration - remaining)
            icon.cooldownDuration = CONFIG.DRDuration
            icon.cooldown:SetCooldown(icon.cooldownStartTime, icon.cooldownDuration)
            debugPrint("New cooldown for", event.category, "- remaining:", remaining)
        end
        
        -- Set border color based on DR level
        local color = CONFIG.borderColors[event.level] or CONFIG.borderColors[1]
        icon.border:SetVertexColor(unpack(color))
        
        -- Show DR level in count text
        icon.count:SetText(event.level)
        icon.count:Show()
        
        -- Position the icon
        icon:ClearAllPoints()
        if i == 1 then
            -- First icon (oldest) anchored at container right
            icon:SetPoint("RIGHT", data.container, "RIGHT", 0, 0)
        else
            -- Subsequent icons to the left of the previous one
            icon:SetPoint("RIGHT", data.DRIcons[i-1], "LEFT", -CONFIG.iconSpacing, 0)
        end
        
        debugPrint("Showing DR icon:", i, "Spell:", event.lastSpellId, "Level:", event.level)
        icon:Show()
    end
    
    -- Hide unused icon frames
    for i = #events + 1, #data.DRIcons do
        if data.DRIcons[i] then
            data.DRIcons[i]:Hide()
            debugPrint("Hiding unused DR icon:", i, "for unit", unit)
        end
    end
    
    -- Mark as updated
    data.needsUpdate = false
    
    -- Show all containers in test mode
    data.container:Show()
    if data.container:GetParent() then
        data.container:GetParent():Show()
    end
end

-- Check for guid changes in arena units
local function CheckUnitGUIDs()
    for _, unit in ipairs(CONFIG.unitsToTrack) do
        local data = DRData[unit]
        if data then
            local guid = UnitGUID(unit)
            
            -- If GUID changed (different unit in arena slot), reset DRs
            if guid and data.guid ~= guid then
                data.guid = guid
                data.activeDREvents = {}
                data.needsUpdate = true
                debugPrint("Unit GUID changed for", unit, "-", guid)
            end
        end
    end
end

-- Create throttled updater
displayUpdater = CreateFrame("Frame")
displayUpdater:Hide()
displayUpdater.timeSinceLastUpdate = 0
displayUpdater.timeSinceLastCleanup = 0

displayUpdater:SetScript("OnUpdate", function(self, elapsed)
    -- Throttle updates
    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
    self.timeSinceLastCleanup = self.timeSinceLastCleanup + elapsed
    
    -- Periodic cleanup of expired DRs
    if self.timeSinceLastCleanup >= CONFIG.cleanupInterval then
        self.timeSinceLastCleanup = 0
        local hadExpired = CleanupExpiredDRs()
        
        -- Always force a display update after cleanup
        if hadExpired then
            for _, unit in ipairs(CONFIG.unitsToTrack) do
                if DRData[unit] then
                    DRData[unit].needsUpdate = true
                end
            end
        end
        
        -- Check for unit guid changes
        CheckUnitGUIDs()
    end
    
    
    -- Update displays if enough time has passed
    if self.timeSinceLastUpdate >= CONFIG.updateThrottleDelay then
        self.timeSinceLastUpdate = 0
        
        local anyUpdates = false
        for _, unit in ipairs(CONFIG.unitsToTrack) do
            if DRData[unit] and DRData[unit].needsUpdate then
                UpdateDRDisplayForUnit(unit)
                anyUpdates = true
            end
        end
        
        -- Check if there are any active DR events before deciding to hide
        local anyActiveEvents = false
        for _, unit in ipairs(CONFIG.unitsToTrack) do
            if DRData[unit] then
                for _, _ in pairs(DRData[unit].activeDREvents) do
                    anyActiveEvents = true
                    break
                end
                if anyActiveEvents then break end
            end
        end
        
        -- Only hide the updater if there are no active events AND no pending updates
        if not anyActiveEvents and not anyUpdates then
            self:Hide()
            debugPrint("DisplayUpdater hidden - no active events or updates")
        else
            -- Force another check soon if we have active events
            if anyActiveEvents then
                -- Schedule another cleanup soon to check for expirations
                self.timeSinceLastCleanup = CONFIG.cleanupInterval - 0.1
            end
        end
    end
end)

-- Helper to request an update for all units
local function RequestUpdateAll()
    for _, unit in ipairs(CONFIG.unitsToTrack) do
        if DRData[unit] then
            DRData[unit].needsUpdate = true
        end
    end
    displayUpdater:Show()
end

-- Setup event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Initialize on login/reload
        BuildSpellLookupTable()
        CreateDRContainers()
        debugPrint("DR Tracker initialized")
    elseif event == "ARENA_OPPONENT_UPDATE" then
        -- Arena opponent changed - check for GUID changes
        CheckUnitGUIDs()
        RequestUpdateAll()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, hideCaster,
              sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
              destGUID, destName, destFlags, destRaidFlags,
              spellId, spellName, spellSchool, auraType = CombatLogGetCurrentEventInfo()
              
        -- Only process debuff removed events to track DR
        if subevent ~= "SPELL_AURA_REMOVED" or auraType ~= "DEBUFF" then 
            return 
        end
        
        -- Check if this debuff removal was on a tracked arena unit
        for _, unit in ipairs(CONFIG.unitsToTrack) do
            local unitGUID = UnitGUID(unit)
            if unitGUID and destGUID == unitGUID then
                HandleDRTriggerForUnit(unit, spellId)
                displayUpdater:Show() -- Ensure updater is running
                break
            end
        end
    end
end)

-- Add slash command for testing
SLASH_DRTRACKER1 = "/drtest"
SlashCmdList["DRTRACKER"] = function(msg)
    if msg == "debug" then
        DEBUG = not DEBUG
        print("DR Tracker debug mode:", DEBUG and "ON" or "OFF")
    elseif msg == "reset" then
        -- Reset all tracking data
        for unit, data in pairs(DRData) do
            data.activeDREvents = {}
            data.needsUpdate = true
            debugPrint("Reset DR tracking for", unit)
        end
        RequestUpdateAll()
    else
        -- For testing: simulate a DR trigger for each arena unit
        local testSpellIds = {5211, 339, 8122}  -- Bash, Entangling Roots, Psychic Scream
        for _, unit in ipairs(CONFIG.unitsToTrack) do
            if UnitExists(unit) then
                -- Use WoW's random function instead of math.random
                local randomIndex = random(#testSpellIds)
                local randomSpell = testSpellIds[randomIndex]
                HandleDRTriggerForUnit(unit, randomSpell)
                debugPrint("Triggered test DR on", unit, "SpellID:", randomSpell)
            else
                debugPrint("Unit", unit, "doesn't exist - testing with dummy")
                -- Force a test even if unit doesn't exist by creating temporary data
                if not DRData[unit] or not DRData[unit].container then
                    -- Create a container if needed
                    local parent = CreateFrame("Frame", "DRTestDummy_" .. unit, UIParent)
                    parent:SetSize(100, 100)
                    
                    -- Position each dummy in a visible location
                    local yOffset = (100 * tonumber(string.match(unit, "%d+"))) or 0
                    parent:SetPoint("CENTER", UIParent, "CENTER", 0, yOffset)
                    parent:Show()
                    
                    local container = CreateFrame("Frame", "DRTestContainer_" .. unit, parent)
                    container:SetSize(400, CONFIG.iconSize + 10)
                    container:SetPoint("CENTER", parent, "CENTER", 0, 0)
                    
                    -- Create a background to make it visible
                    local bg = container:CreateTexture(nil, "BACKGROUND")
                    bg:SetAllPoints()
                    bg:SetColorTexture(0, 0, 0, 0.3)
                    
                    container:Show()
                    
                    -- Create or update DRData entry
                    if not DRData[unit] then
                        DRData[unit] = {
                            container = container,
                            activeDREvents = {},
                            DRIcons = {},
                            guid = "test-guid-" .. unit,
                            needsUpdate = true
                        }
                    else
                        DRData[unit].container = container
                    end
                    
                    debugPrint("Created test container for", unit)
                end
                
                -- Always force GUID for test mode
                DRData[unit].guid = "test-guid-" .. unit
                
                local randomIndex = random(#testSpellIds)
                local randomSpell = testSpellIds[randomIndex]
                
                -- Force a visible DR for testing
                local now = GetTime()
                local category = spellToCategoryMap[randomSpell]
                
                if category then
                    DRData[unit].activeDREvents[category] = {
                        category = category,
                        level = random(3),  -- Random DR level for testing
                        expiration = now + CONFIG.DRDuration,
                        triggerTime = now,
                        lastSpellId = randomSpell
                    }
                    DRData[unit].needsUpdate = true
                    
                    debugPrint("Triggered test DR on dummy", unit, "SpellID:", randomSpell, "Category:", category)
                else
                    debugPrint("ERROR: No category found for spell", randomSpell)
                end
            end
        end
        
        -- Force update all frames
        for unit, data in pairs(DRData) do
            if data.needsUpdate then
                UpdateDRDisplayForUnit(unit)
            end
        end
        
        displayUpdater:Show()
    end
end

-- Initial setup
BuildSpellLookupTable()
CreateDRContainers()
displayUpdater:Show() -- Make sure updater is running initially