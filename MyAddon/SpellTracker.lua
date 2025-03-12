-- Create saved variable structures
local addonName, MyAddon = ...

-- Initialize Masque group
local MasqueGroup = LibStub and LibStub("Masque", true) and LibStub("Masque", true):Group("SpellTracker")

-- Function to check if player is in an arena
local function IsInArena()
    -- First try IsActiveBattlefieldArena() which should be available in Cata
    if IsActiveBattlefieldArena and IsActiveBattlefieldArena() then
        return true
    end
    
    -- Check instance info
    local _, instanceType = IsInInstance()
    if instanceType == "arena" then
        return true
    end
    
    -- Fallback to zone name checking for older clients
    local arenaZones = {
        ["Nagrand Arena"] = true,
        ["Ruins of Lordaeron"] = true,
        ["Blade's Edge Arena"] = true,
        ["Dalaran Arena"] = true,
        ["The Ring of Valor"] = true,
        ["The Tiger's Peak"] = true
    }
    
    local zoneName = GetRealZoneText()
    if arenaZones[zoneName] then
        return true
    end
    
    return false
end

local arenaCooldowns = {
    -- Death Knight
    {spellID = 49576, iconID = 237532, cooldown = 25, priority = 10},     -- Death Grip
    {spellID = 77606, iconID = 135888, cooldown = 60, priority = 9},      -- Dark Simulacrum
    {spellID = 47476, iconID = 136214, cooldown = 120, priority = 8},     -- Strangulate
    {spellID = 48707, iconID = 136120, cooldown = 45, priority = 7},      -- Anti-Magic Shell
    {spellID = 48792, iconID = 237525, cooldown = 120, priority = 6},     -- Icebound Fortitude
    {spellID = 51271, iconID = 458718, cooldown = 60, priority = 5},      -- Pillar of Frost
    {spellID = 49206, iconID = 458967, cooldown = 180, priority = 4},     -- Summon Gargoyle

    -- Druid
    {spellID = 5211, iconID = 132114, cooldown = 60, priority = 10},      -- Bash
    {spellID = 50516, iconID = 236170, cooldown = 17, priority = 9},      -- Typhoon
    {spellID = 22812, iconID = 136097, cooldown = 60, priority = 5},      -- Barkskin
    {spellID = 61336, iconID = 236169, cooldown = 180, priority = 4},     -- Survival Instincts
    {spellID = 48505, iconID = 236168, cooldown = 60, priority = 3},      -- Starfall
    {spellID = 50334, iconID = 236149, cooldown = 180, priority = 2},     -- Berserk

    -- Hunter
    {spellID = 19503, iconID = 132153, cooldown = 30, priority = 10},     -- Scatter Shot -- add reset with readiness
    {spellID = 1499, iconID = 135834, cooldown = 28, priority = 9},       -- Freezing Trap -- add reset with readiness
    {spellID = 90337, iconID = 132159, cooldown = 60, priority = 8},      -- Bad Manner
    {spellID = 23989, iconID = 132206, cooldown = 180, priority = 7},     -- Readiness
    {spellID = 19263, iconID = 132369, cooldown = 90, priority = 6},      -- Deterrence

    -- Mage
    {spellID = 44572, iconID = 236214, cooldown = 30, priority = 10},     -- Deep Freeze -- add reset with Cold Snap
    {spellID = 31661, iconID = 134153, cooldown = 18, priority = 9},      -- Dragon's Breath
    {spellID = 45438, iconID = 135841, cooldown = 300, priority = 7},     -- Ice Block
    {spellID = 11958, iconID = 135865, cooldown = 384, priority = 6},     -- Cold Snap

    -- Paladin
    {spellID = 853, iconID = 135963, cooldown = 40, priority = 10},       --  Hammer of justice
    {spellID = 20066, iconID = 135942, cooldown = 60, priority = 9},       -- Repentance
    {spellID = 642, iconID = 524354, cooldown = 300, priority = 8},        -- Divine Shield
    {spellID = 1022, iconID = 135964, cooldown = 180, priority = 7},       -- Blessing of Protection
    {spellID = 6940, iconID = 135966, cooldown = 120, priority = 6},       -- Hand of Sacrifice
    {spellID = 31884, iconID = 135875, cooldown = 120, priority = 5},       -- Avenging Wrath

    -- Priest
    {spellID = 8122, iconID = 136184, cooldown = 27, priority = 10},       -- Psychic Scream
    {spellID = 32379, iconID = 136149, cooldown = 10, priority = 9},       -- Shadow Word: Death
    {spellID = 64044, iconID = 237568, cooldown = 90, priority = 8},       -- Psychic Horror
    {spellID = 33206, iconID = 135936, cooldown = 144, priority = 7},       -- Pain Suppression
    {spellID = 47585, iconID = 237563, cooldown = 75, priority = 6},        -- Dispersion
    {spellID = 6346, iconID = 135902, cooldown = 180, priority = 5},        -- Fear Ward

    -- Rogue
    {spellID = 36554, iconID = 132303, cooldown = 24, priority = 10},       -- Shadow Step -- add reset with Preparation
    {spellID = 408, iconID = 132298, cooldown = 20, priority = 7},          -- Kidney Shot
    {spellID = 2094, iconID = 136175, cooldown = 120, priority = 6},         -- Blind
    {spellID = 1856, iconID = 132331, cooldown = 120, priority = 5},         -- Vanish
    {spellID = 31224, iconID = 136177, cooldown = 90, priority = 4},         -- Cloak of Shadows
    {spellID = 5277, iconID = 136205, cooldown = 180, priority = 3},         -- Evasion
    {spellID = 74001, iconID = 458725, cooldown = 90, priority = 2},         -- Combat Readiness
    {spellID = 14185, iconID = 460693, cooldown = 300, priority = 1},         -- Preparation

    -- Shaman
    {spellID = 8177, iconID = 136039, cooldown = 22, priority = 10},         -- Grounding Totem
    {spellID = 8143, iconID = 136108, cooldown = 60, priority = 9},          -- Tremor Totem
    {spellID = 30823, iconID = 136088, cooldown = 60, priority = 8},          -- Shamanistic Rage
    {spellID = 98008, iconID = 237586, cooldown = 180, priority = 7},         -- Spirit Link Totem
    {spellID = 16188, iconID = 136076, cooldown = 180, priority = 6},         -- Nature's Swiftness

    -- Warlock
    {spellID = 5484, iconID = 136147, cooldown = 32, priority = 10},         -- Howl of Terror
    {spellID = 6789, iconID = 136145, cooldown = 240, priority = 9},         -- Death Coil
    {spellID = 30283, iconID = 136201, cooldown = 20, priority = 8},         -- Shadowfury
    {spellID = 48020, iconID = 237560, cooldown = 30, priority = 4},         -- Demonic Circle: Teleport

    -- Warrior
    {spellID = 31554, iconID = 132361, cooldown = 30, priority = 10},        -- Spell Reflection
    {spellID = 85388, iconID = 133542, cooldown = 45, priority = 7},         -- Throwdown
    {spellID = 57755, iconID = 132453, cooldown = 30, priority = 6},         -- Heroic Throw
    {spellID = 5246, iconID = 132154, cooldown = 90, priority = 5},          -- Intimidating Shout
    {spellID = 1719, iconID = 132109, cooldown = 300, priority = 3},         -- Recklessness
    {spellID = 871, iconID = 132362, cooldown = 300, priority = 2},          -- Shield Wall

}

local trackedInterrupts = {
    -- Death Knight
    {spellID = 47528, iconID = 237527, cooldown = 10, priority = 10},       -- Mind Freeze
    
    -- Druid
    {spellID = 78675, iconID = 252188, cooldown = 60, priority = 9},        -- Solar Beam
    {spellID = 80965, iconID = 236946, cooldown = 10, priority = 8},        -- Skull Bash
    
    -- Hunter
    {spellID = 34490, iconID = 132323, cooldown = 20, priority = 9},        -- Silencing Shot
    
    -- Mage
    {spellID = 2139, iconID = 135856, cooldown = 24, priority = 10},        -- Counterspell
    
    -- Paladin
    {spellID = 96231, iconID = 523893, cooldown = 10, priority = 9},        -- Rebuke
    
    -- Priest
    {spellID = 15487, iconID = 458230, cooldown = 45, priority = 8},        -- Silence
    
    -- Rogue
    {spellID = 1766, iconID = 132219, cooldown = 10, priority = 10},        -- Kick
    
    -- Shaman
    {spellID = 57994, iconID = 136018, cooldown = 15, priority = 9},        -- Wind Shear
    
    -- Warlock
    {spellID = 19647, iconID = 136174, cooldown = 24, priority = 8},        -- Spell Lock (Felhunter)
    
    -- Warrior
    {spellID = 6552, iconID = 132938, cooldown = 10, priority = 10},        -- Pummel
}

local partyCooldowns = { -- priorities are reversed since it's easier to do that than change the tracker to accomodate them growing the other way.
    -- Death Knight
    {spellID = 49576, iconID = 237532, cooldown = 25, priority = 6},     -- Death Grip
    {spellID = 47476, iconID = 136214, cooldown = 120, priority = 7},     -- Strangulate
    {spellID = 48707, iconID = 136120, cooldown = 45, priority = 8},      -- Anti-Magic Shell
    {spellID = 48792, iconID = 237525, cooldown = 120, priority = 10},    -- Icebound Fortitude

    -- Druid
    {spellID = 5211, iconID = 132114, cooldown = 60, priority = 4},       -- Bash
    {spellID = 22812, iconID = 136097, cooldown = 60, priority = 5},       -- Barkskin
    {spellID = 61336, iconID = 236169, cooldown = 180, priority = 10},     -- Survival Instincts

    -- Hunter
    {spellID = 19503, iconID = 132153, cooldown = 30, priority = 6},       -- Scatter Shot
    {spellID = 1499, iconID = 135834, cooldown = 28, priority = 7},        -- Freezing Trap
    {spellID = 90337, iconID = 132159, cooldown = 60, priority = 8},        -- Bad Manner
    {spellID = 23989, iconID = 132206, cooldown = 180, priority = 9},       -- Readiness
    {spellID = 19263, iconID = 132369, cooldown = 90, priority = 10},       -- Deterrence

    -- Mage
    {spellID = 44572, iconID = 236214, cooldown = 30, priority = 6},        -- Deep Freeze
    {spellID = 31661, iconID = 134153, cooldown = 17, priority = 7},        -- Dragon's Breath
    {spellID = 45438, iconID = 135841, cooldown = 300, priority = 9},       -- Ice Block
    {spellID = 11958, iconID = 135865, cooldown = 384, priority = 10},      -- Cold Snap

    -- Paladin
    {spellID = 853, iconID = 135963, cooldown = 40, priority = 7},          -- Hammer of justice
    {spellID = 20066, iconID = 135942, cooldown = 60, priority = 8},         -- Repentance
    {spellID = 642, iconID = 524354, cooldown = 300, priority = 9},          -- Divine Shield
    {spellID = 1022, iconID = 135964, cooldown = 180, priority = 10},        -- Blessing of Protection

    -- Priest
    {spellID = 8122, iconID = 136184, cooldown = 27, priority = 6},         -- Psychic Scream
    {spellID = 32379, iconID = 136149, cooldown = 10, priority = 7},         -- Shadow Word: Death
    {spellID = 64044, iconID = 237568, cooldown = 90, priority = 8},         -- Psychic Horror
    {spellID = 33206, iconID = 135936, cooldown = 144, priority = 9},         -- Pain Suppression
    {spellID = 47585, iconID = 237563, cooldown = 75, priority = 10},         -- Dispersion

    -- Rogue
    {spellID = 36554, iconID = 132303, cooldown = 24, priority = 1},         -- Shadow Step
    {spellID = 408, iconID = 132298, cooldown = 20, priority = 2},           -- Kidney Shot
    {spellID = 2094, iconID = 136175, cooldown = 120, priority = 3},          -- Blind
    {spellID = 1856, iconID = 132331, cooldown = 120, priority = 4},          -- Vanish
    {spellID = 31224, iconID = 136177, cooldown = 90, priority = 5},          -- Cloak of Shadows
    {spellID = 5277, iconID = 136205, cooldown = 180, priority = 6},          -- Evasion
    {spellID = 74001, iconID = 458725, cooldown = 90, priority = 7},          -- Combat Readiness
    {spellID = 14185, iconID = 460693, cooldown = 300, priority = 10},        -- Preparation

    -- Shaman
    {spellID = 8177, iconID = 136039, cooldown = 22, priority = 6},         -- Grounding Totem
    {spellID = 8143, iconID = 136108, cooldown = 60, priority = 7},         -- Tremor Totem
    {spellID = 30823, iconID = 136088, cooldown = 60, priority = 8},         -- Shamanistic Rage
    {spellID = 98008, iconID = 237586, cooldown = 180, priority = 9},         -- Spirit Link Totem
    {spellID = 16188, iconID = 136076, cooldown = 180, priority = 10},        -- Nature's Swiftness

    -- Warlock
    {spellID = 5484, iconID = 136147, cooldown = 32, priority = 4},         -- Howl of Terror
    {spellID = 6789, iconID = 136145, cooldown = 240, priority = 8},         -- Death Coil
    {spellID = 30283, iconID = 136201, cooldown = 20, priority = 9},         -- Shadowfury
    {spellID = 48020, iconID = 237560, cooldown = 30, priority = 10},        -- Demonic Circle: Teleport

    -- Warrior
    {spellID = 85388, iconID = 133542, cooldown = 45, priority = 2},         -- Throwdown
    {spellID = 57755, iconID = 132453, cooldown = 30, priority = 5},         -- Heroic Throw
    {spellID = 5246, iconID = 132154, cooldown = 90, priority = 6},          -- Intimidating Shout
    {spellID = 871, iconID = 132362, cooldown = 300, priority = 7},           -- Shield Wall
}

-- Configuration for each row with fixed positions
local rowConfigs = {
    {
        identifier = "Interrupts",
        unitIDs = {"arena1", "arena2", "arena3", "arenapet1", "arenapet2", "arenapet3"},  -- Track all arena units for interrupts
        xOffset = 0,
        yOffset = -350,
        growRight = "center",
        iconSize = 36,
        spacing = 40,
        spells = trackedInterrupts
    },
    {
        identifier = "a1",
        unitID = "arena1",
        xOffset = 574,
        yOffset = -56,
        growRight = true,
        iconSize = 31,
        spacing = 34,
        spells = arenaCooldowns
    },
    {
        identifier = "a2",
        unitID = "arena2",
        xOffset = 574,
        yOffset = -128,
        growRight = true,
        iconSize = 31,
        spacing = 34,
        spells = arenaCooldowns
    },
    {
        identifier = "a3",
        unitID = "arena3",
        xOffset = 574,
        yOffset = -197,
        growRight = true,
        iconSize = 31,
        spacing = 34,
        spells = arenaCooldowns
    },
    {
        identifier = "party1",
        unitID = "party1",
        xOffset = 183,            -- Fixed position X
        yOffset = 411.5,            -- Fixed position Y
        iconSize = 25,
        spacing = 25,
        growRight = false,        -- Grow towards left
        spells = partyCooldowns
    },
    {
        identifier = "party2",
        unitID = "party2",
        xOffset = 183,            -- Fixed position X
        yOffset = 349,            -- Fixed position Y
        iconSize = 25,
        spacing = 25,
        growRight = false,        -- Grow towards left
        spells = partyCooldowns
    }
}

-- Spell interactions table
local spellInteractions = {
    [11958] = { -- Cold Snap
        resetSpells = {
            45438, -- Ice Block
            44572, -- Deep Freeze
        }
    },
    [23989] = { -- Readiness
        resetSpells = {
            19263, -- Deterrence
            19503, -- Scatter Shot
            1499,  -- Freezing Trap
        }
    },
    [14185] = { -- Preparation
        resetSpells = {
            36554, -- Shadow Step
        }
    }
}

-- Table to store active cooldowns for each row
local activeCooldownsByRow = {}
for i = 1, #rowConfigs do
    activeCooldownsByRow[i] = {}
end

-- Function to update positions of active cooldown icons
local function UpdateCooldownPositions(rowIndex)
    local config = rowConfigs[rowIndex]
    local cooldownList = activeCooldownsByRow[rowIndex]
    
    -- Sort by priority
    table.sort(cooldownList, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)
    
    -- Fixed positioning logic for all frames
    local activeCount = #cooldownList
    local startX
    
    if config.growRight == "center" then
        startX = -((activeCount - 1) * config.spacing) / 2
    else
        startX = config.growRight and 0 or -(activeCount * config.spacing)
    end

    for i, frame in ipairs(cooldownList) do
        frame:ClearAllPoints()
        
        if config.identifier == "Interrupts" then
            -- Center interrupts position (kept as is)
            frame:SetPoint("CENTER", UIParent, "CENTER", 
                startX + (i - 1) * config.spacing + config.xOffset,
                100 + config.yOffset)
        elseif config.identifier:match("^a%d") then
            -- Arena unit positions (kept as is)
            frame:SetPoint("CENTER", UIParent, "CENTER", 
                startX + (i - 1) * config.spacing + config.xOffset,
                100 + config.yOffset)
        else
            -- Party unit positions (fixed)
            local offsetX = config.growRight and 
                ((i - 1) * config.spacing) or 
                (-((i - 1) * config.spacing))
                
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 
                config.xOffset + offsetX, 
                config.yOffset)
        end
        
        frame:Show()
    end
end

-- Function to reset cooldowns of affected spells
local function ResetLinkedCooldowns(triggerSpellID)
    local interaction = spellInteractions[triggerSpellID]
    if interaction then
        for rowIndex, cooldownList in ipairs(activeCooldownsByRow) do
            for _, frame in ipairs(cooldownList) do
                if frame.spellID and tContains(interaction.resetSpells, frame.spellID) then
                    frame.cooldown:SetCooldown(0, 0)
                    frame:Hide()
                    -- Remove from active cooldowns list
                    for i, f in ipairs(cooldownList) do
                        if f == frame then
                            table.remove(cooldownList, i)
                            break
                        end
                    end
                end
            end
            UpdateCooldownPositions(rowIndex)
        end
    end
end

-- Function to reset all active cooldown icons
local function ResetAllCooldowns()
    for rowIndex, cooldownList in ipairs(activeCooldownsByRow) do
        for i = #cooldownList, 1, -1 do
            local frame = cooldownList[i]
            frame.cooldown:SetCooldown(0, 0)
            frame:Hide()
            table.remove(cooldownList, i)
        end
        UpdateCooldownPositions(rowIndex)
    end
end

-- Function to create a cooldown tracking icon
local function CreateCooldownIcon(spellData, rowIndex)
    local config = rowConfigs[rowIndex]
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(config.iconSize, config.iconSize)
    frame:SetFrameStrata("HIGH")
    
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(frame)
    icon:SetTexture(spellData.iconID)
    frame.icon = icon

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(frame)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetDrawSwipe(true)
    frame.cooldown = cooldown

    if MasqueGroup then
        MasqueGroup:AddButton(frame, {
            Icon = frame.icon,
            Cooldown = frame.cooldown,
        })
    end

    frame.spellID = spellData.spellID
    frame.priority = spellData.priority or 0

    local function StartCooldown(unit)
        local startTime = GetTime()
        frame.cooldown:SetCooldown(startTime, spellData.cooldown)
        frame.cooldown:Show()
        frame:Show()
        frame.trackingUnit = unit
        
        -- Only add to tracking list if not already present
        local alreadyTracking = false
        for _, existingFrame in ipairs(activeCooldownsByRow[rowIndex]) do
            if existingFrame == frame then
                alreadyTracking = true
                break
            end
        end
        
        if not alreadyTracking then
            table.insert(activeCooldownsByRow[rowIndex], frame)
            UpdateCooldownPositions(rowIndex)
        end

        C_Timer.After(spellData.cooldown, function()
            frame:Hide()
            frame.trackingUnit = nil
            for i, f in ipairs(activeCooldownsByRow[rowIndex]) do
                if f == frame then
                    table.remove(activeCooldownsByRow[rowIndex], i)
                    break
                end
            end
            UpdateCooldownPositions(rowIndex)
        end)
    end

    -- Register for combat log events for interrupt tracking
    if config.identifier == "Interrupts" then
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame:SetScript("OnEvent", function(self, event)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, 
                      sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, 
                      spellID, spellName = CombatLogGetCurrentEventInfo()
                
                if eventType == "SPELL_CAST_SUCCESS" and spellID == spellData.spellID then
                    -- Check if the source is one of our arena units
                    for _, unitID in ipairs(config.unitIDs) do
                        if UnitExists(unitID) and UnitGUID(unitID) == sourceGUID then
                            StartCooldown(unitID)
                            break
                        end
                    end
                end
            end
        end)
    else
        -- Regular player spell tracking for other rows
        frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        frame:SetScript("OnEvent", function(self, event, unit, _, castSpellID)
            if unit == config.unitID and castSpellID == spellData.spellID then
                StartCooldown(unit)
            end
        end)
    end

    frame:Hide()
    return frame
end

-- Create cooldown icons for each row
for rowIndex, config in ipairs(rowConfigs) do
    for _, spellData in ipairs(config.spells) do
        CreateCooldownIcon(spellData, rowIndex)
    end
end

-- Attempt to apply Masque skins if available
if MasqueGroup then
    MasqueGroup:ReSkin()
end

-- Create a frame to monitor updates
local frameMonitor = CreateFrame("Frame")
frameMonitor:RegisterEvent("GROUP_ROSTER_UPDATE")
frameMonitor:RegisterEvent("PLAYER_ENTERING_WORLD")
frameMonitor:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Add variable to track arena status changes
local wasInArena = false

-- Update positions when UI may have changed
frameMonitor:SetScript("OnEvent", function(self, event)
    C_Timer.After(0.5, function()
        local currentlyInArena = IsInArena()
        
        -- If arena status changed, this is important
        if wasInArena ~= currentlyInArena then
            wasInArena = currentlyInArena
            print("SpellTracker: Arena status changed to " .. (currentlyInArena and "in arena" or "out of arena"))
        end
        
        -- Update all cooldown positions
        for rowIndex, _ in ipairs(rowConfigs) do
            if #activeCooldownsByRow[rowIndex] > 0 then
                UpdateCooldownPositions(rowIndex)
            end
        end
    end)
end)

-- Reset triggers via Combat Log for linked cooldown resets
local resetFrame = CreateFrame("Frame")
resetFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
resetFrame:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, 
              sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName = CombatLogGetCurrentEventInfo()
        if eventType == "SPELL_CAST_SUCCESS" then
            -- Check if this spell is a reset trigger
            if spellInteractions[spellID] then
                ResetLinkedCooldowns(spellID)
            end
        end
    end
end)

-- Reset triggers via zone changes (entering or leaving an arena)
local zoneResetFrame = CreateFrame("Frame")
zoneResetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneResetFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneResetFrame:SetScript("OnEvent", function(self, event)
    -- Reset icons when joining an arena or when leaving an instance
    ResetAllCooldowns()
    
    -- Update the display mode based on whether we're in an arena
    C_Timer.After(0.5, function()
        for rowIndex, _ in ipairs(rowConfigs) do
            if #activeCooldownsByRow[rowIndex] > 0 then
                UpdateCooldownPositions(rowIndex)
            end
        end
    end)
end)

-- Create slash command for configuration
SLASH_SPELLTRACKER1 = "/spelltracker"
SLASH_SPELLTRACKER2 = "/st"
SlashCmdList["SPELLTRACKER"] = function(msg)
    local command, arg = string.match(msg, "^(%S*)%s*(.-)$")
    command = command:lower()
    
    if command == "reset" then
        ResetAllCooldowns()
        print("SpellTracker: All cooldowns reset.")
    elseif command == "size" and tonumber(arg) then
        local size = tonumber(arg)
        -- Update icon sizes for party frames
        for i = 4, 6 do -- Indexes for party1 and party2 rows
            if rowConfigs[i] then
                rowConfigs[i].iconSize = size
                for _, frame in ipairs(activeCooldownsByRow[i]) do
                    frame:SetSize(size, size)
                end
                UpdateCooldownPositions(i)
            end
        end
        print("SpellTracker: Icon size set to " .. size)
    elseif command == "spacing" and tonumber(arg) then
        local spacing = tonumber(arg)
        -- Update spacing for party frames
        for i = 4, 6 do -- Indexes for party1 and party2 rows
            if rowConfigs[i] then
                rowConfigs[i].spacing = spacing
                UpdateCooldownPositions(i)
            end
        end
        print("SpellTracker: Icon spacing set to " .. spacing)
    elseif command:match("^pos") then
        -- Format: /st pos party1 100 300 
        local _, unitID, x, y = strsplit(" ", msg, 4)
        x = tonumber(x)
        y = tonumber(y)
        
        if x and y then
            -- Find the row with this unit ID
            for i, config in ipairs(rowConfigs) do
                if config.unitID == unitID then
                    config.xOffset = x
                    config.yOffset = y
                    print("SpellTracker: Set " .. unitID .. " position to X=" .. x .. ", Y=" .. y)
                    UpdateCooldownPositions(i)
                    return
                end
            end
            print("SpellTracker: Unknown unit '" .. (unitID or "nil") .. "'. Valid units: arena1, arena2, arena3, party1, party2")
        else
            print("Usage: /st pos [unitID] [x] [y]")
        end
    elseif command == "arena" then
        -- Force arena positioning mode for testing
        print("Current arena status: " .. (IsInArena() and "In Arena" or "Not in Arena"))
        print("Zone: " .. GetRealZoneText())
        print("Instance type: " .. select(2, IsInInstance()))
        
        -- Print current positions
        print("Current positions:")
        for i, config in ipairs(rowConfigs) do
            print(config.identifier .. ": X=" .. config.xOffset .. ", Y=" .. config.yOffset)
        end
    elseif command == "test" then
        -- Test cooldowns for all units
        print("Testing cooldowns for all units")
        
        for rowIndex, config in ipairs(rowConfigs) do
            if config.identifier:match("^party") then
                local unitID = config.unitID
                if UnitExists(unitID) then
                    print("Testing cooldowns for " .. unitID)
                    
                    -- Get some test spells to show
                    local testSpells = {}
                    for i = 1, 3 do  -- Show 3 test cooldowns
                        if config.spells[i] then
                            table.insert(testSpells, config.spells[i])
                        end
                    end
                    
                    -- Create test cooldowns
                    local startTime = GetTime()
                    for _, spellData in ipairs(testSpells) do
                        local cooldownFrame = nil
                        
                        -- Check if we already have a frame for this spell
                        for _, frame in ipairs(activeCooldownsByRow[rowIndex]) do
                            if frame.spellID == spellData.spellID then
                                cooldownFrame = frame
                                break
                            end
                        end
                        
                        -- If not found, create a new one
                        if not cooldownFrame then
                            cooldownFrame = CreateCooldownIcon(spellData, rowIndex)
                            cooldownFrame.trackingUnit = unitID
                            table.insert(activeCooldownsByRow[rowIndex], cooldownFrame)
                        end
                        
                        -- Set cooldown
                        cooldownFrame.cooldown:SetCooldown(startTime, spellData.cooldown)
                    end
                    
                    -- Update positions
                    UpdateCooldownPositions(rowIndex)
                end
            end
        end
    elseif command == "help" or command == "" then
        print("SpellTracker commands:")
        print("  /st reset - Reset all cooldowns")
        print("  /st size <number> - Set icon size for party frames")
        print("  /st spacing <number> - Set spacing between icons")
        print("  /st pos <unitID> <x> <y> - Set position for unit (e.g. /st pos party1 100 300)")
        print("  /st arena - Show arena status information")
        print("  /st test - Test party member cooldowns")
    else
        print("Unknown command. Type '/st help' for available commands.")
    end
end