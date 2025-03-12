--[[
    VeiPlatesCC.lua - Crowdcontrol Aura Tracking Module for VeiPlates
    
    Features:
    - Tracks CC and important auras on nameplates with priority system
    - Creates a separate row of icons above nameplates
    - Based on VeiPlatesAuras functionality but with BiggerDebuffs prioritization
    - Optimized for performance with caching and throttling
]]

local addonName, core = ...
local VeiPlatesCC = {}
core.VeiPlatesCC = VeiPlatesCC

-- =======================================
-- CONFIGURATION OPTIONS
-- =======================================
local CONFIG = {
    -- Display settings
    iconSize = 28,           -- Size of CC icons
    maxIcons = 5,            -- Maximum number of icons to show
    spacing = 2,             -- Spacing between icons
    verticalOffset = 28,     -- Distance above nameplate (higher than VeiPlatesAuras)
    scale = 1.0,             -- Scale factor for icons
    growDirection = "CENTER", -- Options: "RIGHT", "LEFT", "CENTER"
    xOffset = 9,             -- Horizontal offset from anchor point
    
    -- Performance settings
    updateThrottleDelay = 0.05,  -- Throttle updates by this amount
    periodicUpdateInterval = 0.5, -- Full refresh interval
    
    -- Debug options
    debug = false            -- Enable debug messages
}

-- =======================================
-- AURA CATEGORIES WITH PRIORITY
-- =======================================
-- Priority system: lower number = higher priority
local AURA_CATEGORIES = {
    {
        name = "immunities",
        priority = 1,
        spells = {
            [48707] = { name = "Anti-Magic Shell" },
            [31224] = { name = "Cloak of Shadows" },
            [23920] = { name = "Spell Reflection" },
            [34471] = { name = "The Beast Within" },
            [47585] = { name = "Dispersion" },
            [1022]  = { name = "Blessing of Protection" },
            [642]   = { name = "Divine Shield" },
            [19263] = { name = "Deterrence" },
            [45438] = { name = "Ice Block" },
            [46924] = { name = "Bladestorm" },
        }
    },
    {
        name = "stuns",
        priority = 2,
        spells = {
            [853]   = { name = "Hammer of Justice" },
            [2637]  = { name = "Hibernate" },
            [20549] = { name = "War Stomp" },
            [28730] = { name = "Arcane Torrent (Mana)" },
            [25046] = { name = "Arcane Torrent (Energy)" },
            [50613] = { name = "Arcane Torrent (Runic Power)" },
            [47476] = { name = "Strangulate" },
            [91800] = { name = "Gnaw" },
            [49203] = { name = "Hungering Cold" },
            [91797] = { name = "Monstrous Blow" },
            [64044] = { name = "Psychic Horror" },
            [605]   = { name = "Mind Control" },
            [8122]  = { name = "Psychic Scream" },
            [15487] = { name = "Silence" },
            [9484]  = { name = "Shackle Undead" },
            [87204] = { name = "Sin and Punishment" },
            [60995] = { name = "Demon Charge" },
            [24259] = { name = "Spell Lock" },
            [6358]  = { name = "Seduction" },
            [5782]  = { name = "Fear" },
            [5484]  = { name = "Howl of Terror" },
            [710]   = { name = "Banish" },
            [6789]  = { name = "Death Coil" },
            [22703] = { name = "Inferno Effect" },
            [30283] = { name = "Shadowfury" },
            [31117] = { name = "Unstable Affliction Silence" },
            [89766] = { name = "Axe Toss" },
            [51514] = { name = "Hex" },
            [58861] = { name = "Bash (Spirit Wolf)" },
            [1513]  = { name = "Scare Beast" },
            [3355]  = { name = "Freezing Trap" },
            [19386] = { name = "Wyvern Sting" },
            [19503] = { name = "Scatter Shot" },
            [34490] = { name = "Silencing Shot" },
            [90337] = { name = "Bad Manner" },
            [50519] = { name = "Sonic Blast" },
            [50541] = { name = "Clench" },
            [91644] = { name = "Snatch" },
            [50318] = { name = "Serenity Dust" },
            [56626] = { name = "Sting" },
            [22570] = { name = "Maim" },
            [9005]  = { name = "Pounce Stun" },
            [5211]  = { name = "Bash" },
            [33786] = { name = "Cyclone" },
            [81261] = { name = "Solar Beam" },
            [44572] = { name = "Deep Freeze" },
            [55021] = { name = "Improved Counterspell" },
            [82691] = { name = "Ring of Frost" },
            [18469] = { name = "Improved Counterspell" },
            [118]   = { name = "Polymorph" },
            [28271] = { name = "Polymorph Turtle" },
            [28272] = { name = "Polymorph Pig" },
            [71319] = { name = "Polymorph Turkey" },
            [61305] = { name = "Polymorph Cat" },
            [61721] = { name = "Polymorph Rabbit" },
            [12355] = { name = "Impact Stun" },
            [31661] = { name = "Dragon's Breath" },
            [51722] = { name = "Dismantle" },
            [1833]  = { name = "Cheap Shot" },
            [408]   = { name = "Kidney Shot" },
            [6770]  = { name = "Sap" },
            [2094]  = { name = "Blind" },
            [1776]  = { name = "Gouge" },
            [1330]  = { name = "Garrote Silence" },
            [46968] = { name = "Shockwave" },
            [85388] = { name = "Throwdown" },
            [20253] = { name = "Intercept Stun" },
            [20615] = { name = "Intercept 2" },
            [12809] = { name = "Concussion Blow" },
            [7922]  = { name = "Charge Stun" },
            [5246]  = { name = "Intimidating Shout" },
            [20511] = { name = "Intimidating Shout 2" },
        }
    },
    {
        name = "roots",
        priority = 3,
        spells = {
            [45524] = { name = "Chains of Ice" },
            [122]   = { name = "Frost Nova" },
            [19185] = { name = "Entrapment" },
            [64803] = { name = "Entrapment 2" },
            [339]   = { name = "Entangling Roots" },
            [19975] = { name = "Entangling Roots 2" },
            [33395] = { name = "Freeze" },
            [83302] = { name = "Improved Cone of Cold" },
            [45334] = { name = "Feral Charge Effect" },
        }
    },
    {
        name = "defensives",
        priority = 4,
        spells = {
            [49039] = { name = "Lichborne" },
            [58984] = { name = "Shadowmeld" },
            [48792] = { name = "Icebound Fortitude" },
            [50461] = { name = "Anti-Magic Zone" },
            [47788] = { name = "Guardian Spirit" },
            [33206] = { name = "Pain Suppression" },
            [89485] = { name = "Inner Focus" },
            [22842] = { name = "Frenzied Regeneration" },
            [5384]  = { name = "Feign Death" },
            [30823] = { name = "Shamanistic Rage" },
            [31821] = { name = "Aura Mastery" },
            [64205] = { name = "Divine Sacrifice" },
            [498]   = { name = "Divine Protection" },
            [6940]  = { name = "Blessing of Sacrifice" },
            [53480] = { name = "Roar of Sacrifice" },
            [5277]  = { name = "Evasion" },
            [45182] = { name = "Cheating Death" },
            [74001] = { name = "Combat Readiness" },
            [3411]  = { name = "Intervene" },
            [871]   = { name = "Shield Wall" },
            [22812] = { name = "Barkskin" },
            [61336] = { name = "Survival Instincts" },
            [17116] = { name = "Nature's Swiftness" },
            [16188] = { name = "Nature's Swiftness Shaman" },
            [87023] = { name = "Cauterize" },
        }
    },
    {
        name = "offensives",
        priority = 5,
        spells = {
            [49016] = { name = "Unholy Frenzy" },
            [47241] = { name = "Metamorphosis" },
            [79462] = { name = "Demon Soul: Felguard" },
            [79460] = { name = "Demon Soul: Felhunter" },
            [79459] = { name = "Demon Soul: Imp" },
            [79463] = { name = "Demon Soul: Succubus" },
            [79464] = { name = "Demon Soul: Voidwalker" },
            [3045]  = { name = "Rapid Fire" },
            [19574] = { name = "Bestial Wrath" },
            [1719]  = { name = "Recklessness" },
            [18499] = { name = "Berserker Rage" },
            [31884] = { name = "Avenging Wrath" },
            [12042] = { name = "Arcane Power" },
            [12043] = { name = "Presence of Mind" },
            [51690] = { name = "Killing Spree" },
            [51713] = { name = "Shadow Dance" },
        }
    }
}

-- Cache frequently used functions
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local select = select
local table = table
local string = string
local format = string.format
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitGUID = UnitGUID
local UnitDebuff = UnitDebuff
local UnitBuff = UnitBuff
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local UnitAura = UnitAura
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local CreateFrame = CreateFrame

-- =======================================
-- DATA STRUCTURES
-- =======================================
local IconContainers = {}           -- Icon containers indexed by unitID
local NameplatesByUnit = {}         -- Blizzard nameplates indexed by unitID
local NameplatesByGUID = {}         -- Blizzard nameplates indexed by GUID
local UnitsByGUID = {}              -- Unit IDs indexed by GUID
local GUIDByUnit = {}               -- GUIDs indexed by unit ID
local ActiveAurasByUnit = {}        -- Active auras indexed by unitID
local cachedAurasByUnit = {}        -- Cached aura look results
local spellCache = {}               -- Cache for GetSpellInfo results

-- Build optimized spell lookup tables
local spellIdToCategory = {}        -- Maps spellID to category info
local totalSpellsTracked = 0

-- =======================================
-- UTILITY FUNCTIONS
-- =======================================
-- Debug print function
local function DebugPrint(...)
    if CONFIG.debug then
        local message = format("|cFF33CCFF[VeiPlatesCC]|r %s", string.join(" ", tostringall(...)))
        DEFAULT_CHAT_FRAME:AddMessage(message)
    end
end

-- Simple print function
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33CCFF[VeiPlatesCC]|r " .. msg)
end

-- Build spell lookup tables for fast access
local function BuildSpellLookupTables()
    -- Reset tables
    spellIdToCategory = {}
    totalSpellsTracked = 0
    
    -- Build lookup tables
    for _, category in ipairs(AURA_CATEGORIES) do
        for spellId, spellData in pairs(category.spells) do
            spellIdToCategory[spellId] = {
                category = category.name,
                priority = category.priority,
                name = spellData.name
            }
            totalSpellsTracked = totalSpellsTracked + 1
        end
    end
    
    DebugPrint("Built spell lookup tables with", totalSpellsTracked, "spells in", #AURA_CATEGORIES, "categories")
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
        
        return {
            Cancel = function()
                frame:SetScript("OnUpdate", nil)
            end
        }
    end
    
    DebugPrint("Created C_Timer fallback for older WoW versions")
end

-- Get spell info with caching for better performance
local function GetSpellInfoCached(spellId)
    if not spellId then return nil end
    
    if not spellCache[spellId] then
        spellCache[spellId] = {GetSpellInfo(spellId)}
    end
    
    return unpack(spellCache[spellId])
end

-- =======================================
-- ICON CONTAINER CREATION
-- =======================================
-- Create icon container and frames for a nameplate
local function CreateIconContainer(defaultPlate, unitID)
    if not defaultPlate then
        DebugPrint("CreateIconContainer: No defaultPlate provided")
        return nil
    end
    
    DebugPrint("Creating icon container for unit: " .. (unitID or "unknown"))
    
    -- Find health bar to use as anchor (similar to VeiPlatesAuras)
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
    local totalWidth = CONFIG.iconSize * CONFIG.maxIcons + CONFIG.spacing * (CONFIG.maxIcons - 1)
    container:SetSize(totalWidth, CONFIG.iconSize)
    
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
    
    -- Create the individual icon frames with proper positioning
    for i = 1, CONFIG.maxIcons do
        local iconFrame = CreateFrame("Frame", nil, container)
        iconFrame:SetSize(CONFIG.iconSize, CONFIG.iconSize)
        iconFrame:ClearAllPoints()
        
        -- Position based on grow direction
        if CONFIG.growDirection == "RIGHT" then
            iconFrame:SetPoint("LEFT", (i-1) * (CONFIG.iconSize + CONFIG.spacing), 0)
        elseif CONFIG.growDirection == "LEFT" then
            iconFrame:SetPoint("RIGHT", -((i-1) * (CONFIG.iconSize + CONFIG.spacing)), 0)
        elseif CONFIG.growDirection == "CENTER" then
            -- Center icons based on the container center
            local iconCount = CONFIG.maxIcons
            local halfWidth = ((iconCount - 1) * (CONFIG.iconSize + CONFIG.spacing)) / 2
            local iconOffset = (i - 1) * (CONFIG.iconSize + CONFIG.spacing) - halfWidth
            
            -- Set position relative to container center
            iconFrame:SetPoint("CENTER", iconOffset, 0)
        end
        
        -- Create texture for the icon
        iconFrame.texture = iconFrame:CreateTexture(nil, "BACKGROUND")
        iconFrame.texture:SetAllPoints(iconFrame)
        iconFrame.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Trim icon edges
        
        -- Create cooldown frame
        iconFrame.cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
        iconFrame.cooldown:SetAllPoints()
        iconFrame.cooldown:SetDrawEdge(false)
        iconFrame.cooldown:SetHideCountdownNumbers(false)
        
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
function VeiPlatesCC:TrackNameplate(unitID)
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
    if IconContainers[unitID] then
        IconContainers[unitID]:Hide()
        IconContainers[unitID] = nil
    end
    
    -- Create icon container (with retry mechanism)
    local function TryCreateContainer(attempts)
        if attempts <= 0 then return end
        
        local container = CreateIconContainer(defaultPlate, unitID)
        if container then
            IconContainers[unitID] = container
            -- Update auras immediately
            self:UpdateAurasForUnit(unitID)
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
function VeiPlatesCC:UntrackNameplate(unitID)
    if not unitID then return end
    
    local guid = GUIDByUnit[unitID]
    
    -- Clean up containers
    if IconContainers[unitID] then
        IconContainers[unitID]:Hide()
        IconContainers[unitID] = nil
    end
    
    -- Clean up aura cache
    if cachedAurasByUnit[unitID] then
        cachedAurasByUnit[unitID] = nil
    end
    
    -- Clean up active auras
    if ActiveAurasByUnit[unitID] then
        ActiveAurasByUnit[unitID] = nil
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
-- AURA SCANNING AND PRIORITIZATION
-- =======================================
-- Scan for auras on a unit
function VeiPlatesCC:ScanUnitAuras(unitID)
    if not unitID or not UnitExists(unitID) then return {} end
    
    -- Skip friendly units
    if UnitIsFriend("player", unitID) then
        return {}
    end
    
    local currentTime = GetTime()
    local cachedResult = cachedAurasByUnit[unitID]
    
    -- Check if we can use a cached scan (valid for 0.1 seconds)
    if cachedResult and cachedResult.time and (currentTime - cachedResult.time) < 0.1 then
        DebugPrint("Using cached aura scan for", unitID, "age:", (currentTime - cachedResult.time))
        return cachedResult.auras
    end
    
    -- New scan needed
    local foundAuras = {}
    
    -- Helper function to process both buffs and debuffs
    local function ProcessAuraType(isBuff)
        local index = 1
        while true do
            local name, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId
            
            if isBuff then
                name, icon, count, _, duration, expirationTime, unitCaster, _, _, spellId = UnitBuff(unitID, index)
            else
                name, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId = UnitDebuff(unitID, index)
            end
            
            if not name then break end
            
            -- Check if this is a spell we're tracking
            if spellId and spellIdToCategory[spellId] then
                -- Convert times and calculate remaining time
                local remaining = 0
                if duration and duration > 0 and expirationTime then
                    remaining = expirationTime - currentTime
                end
                
                table.insert(foundAuras, {
                    name = name,
                    icon = icon,
                    count = count,
                    debuffType = debuffType,
                    duration = duration,
                    expirationTime = expirationTime,
                    remaining = remaining,
                    spellId = spellId,
                    priority = spellIdToCategory[spellId].priority,
                    category = spellIdToCategory[spellId].category,
                    isBuff = isBuff
                })
            end
            
            index = index + 1
        end
    end
    
    -- Process both buffs and debuffs
    ProcessAuraType(true)   -- Buffs
    ProcessAuraType(false)  -- Debuffs
    
    -- Sort by priority (lower number = higher priority) then by remaining time (higher = better)
    table.sort(foundAuras, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority  -- Lower priority value = more important
        else
            return a.remaining > b.remaining  -- Longer remaining time = more important
        end
    end)
    
    -- Cache the result
    cachedAurasByUnit[unitID] = {
        time = currentTime,
        auras = foundAuras
    }
    
    DebugPrint("Scanned unit", unitID, "found", #foundAuras, "tracked auras")
    return foundAuras
end

-- =======================================
-- AURA UPDATES AND DISPLAY
-- =======================================
-- Update auras for a specific unit
function VeiPlatesCC:UpdateAurasForUnit(unitID)
    if not unitID or not UnitExists(unitID) then return end
    
    -- Skip friendly units
    if UnitIsFriend("player", unitID) then
        DebugPrint("Skipping friendly unit:", unitID)
        return
    end
    
    -- Get the icon container
    local container = IconContainers[unitID]
    if not container then
        -- Try to create it if it doesn't exist
        local defaultPlate = C_NamePlate.GetNamePlateForUnit(unitID)
        if not defaultPlate then return end
        
        container = CreateIconContainer(defaultPlate, unitID)
        if not container then return end
        
        IconContainers[unitID] = container
    end
    
    -- Scan for auras
    local auras = self:ScanUnitAuras(unitID)
    
    -- Store active auras
    ActiveAurasByUnit[unitID] = auras
    
    -- Count displayed auras
    local auraCount = 0
    
    -- Track active icons for better centering
    local activeIcons = {}
    
    -- Display up to maxIcons auras
    for i = 1, math.min(#auras, CONFIG.maxIcons) do
        local aura = auras[i]
        local iconFrame = container.icons[i]
        
        -- Store this frame for later repositioning if needed
        table.insert(activeIcons, iconFrame)
        
        -- Update icon texture
        iconFrame.texture:SetTexture(aura.icon)
        
        -- Set stack count
        if aura.count and aura.count > 1 then
            iconFrame.count:SetText(aura.count)
            iconFrame.count:Show()
        else
            iconFrame.count:Hide()
        end
        
        -- Set cooldown spiral
        if aura.duration and aura.duration > 0 and aura.expirationTime then
            iconFrame.cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
            iconFrame.cooldown:Show()
        else
            iconFrame.cooldown:Hide()
        end
        
-- Set border color based on aura type
if aura.debuffType and _G.DebuffTypeColor and _G.DebuffTypeColor[aura.debuffType] then
    local color = _G.DebuffTypeColor[aura.debuffType]
    iconFrame.border:SetVertexColor(color.r, color.g, color.b)
elseif aura.isBuff then
    -- Blue for buffs
    iconFrame.border:SetVertexColor(0.2, 0.6, 1.0)
else
    -- Default to purple if no type or type color not found
    iconFrame.border:SetVertexColor(0.8, 0, 0.8)
end

-- Store aura info for tooltip support
iconFrame.auraInfo = aura

-- Show the icon
iconFrame:Show()
auraCount = auraCount + 1
end

-- Hide unused icon frames
for i = auraCount + 1, CONFIG.maxIcons do
local iconFrame = container.icons[i]
if iconFrame then
    iconFrame:Hide()
    iconFrame.auraInfo = nil
end
end

-- Center the visible icons dynamically if using center growth
if CONFIG.growDirection == "CENTER" and auraCount > 0 and auraCount < CONFIG.maxIcons then
-- Recenter the visible icons
local totalWidth = auraCount * CONFIG.iconSize + (auraCount - 1) * CONFIG.spacing
local halfWidth = totalWidth / 2

for i, iconFrame in ipairs(activeIcons) do
    iconFrame:ClearAllPoints()
    local iconOffset = (i - 1) * (CONFIG.iconSize + CONFIG.spacing) - halfWidth + (CONFIG.iconSize / 2)
    iconFrame:SetPoint("CENTER", container, "CENTER", iconOffset, 0)
end
end

-- Show or hide the container based on whether we have auras
if auraCount > 0 then
container:Show()
else
container:Hide()
end

return auraCount
end

-- Update all currently tracked nameplates
function VeiPlatesCC:UpdateAllNameplates()
for unitID, _ in pairs(NameplatesByUnit) do
if UnitExists(unitID) then
    self:UpdateAurasForUnit(unitID)
end
end
end

-- Handle combat log events that affect auras
function VeiPlatesCC:HandleCombatLogEvent(...)
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

-- Only update for events that might affect auras
if subEvent == "SPELL_AURA_APPLIED" or 
subEvent == "SPELL_AURA_REMOVED" or 
subEvent == "SPELL_AURA_APPLIED_DOSE" or 
subEvent == "SPELL_AURA_REMOVED_DOSE" or
subEvent == "SPELL_AURA_REFRESH" then

-- Find the unit with this GUID
local unitID = UnitsByGUID[destGUID]
if unitID then
    -- Clear cache for this unit
    if cachedAurasByUnit[unitID] then
        cachedAurasByUnit[unitID] = nil
    end
    
    -- Small delay to ensure the aura is fully applied/removed
    C_Timer.After(0.05, function()
        VeiPlatesCC:UpdateAurasForUnit(unitID)
    end)
end
end
end

-- =======================================
-- CONFIGURATION FUNCTIONS
-- =======================================
-- Set growth direction for icons
function VeiPlatesCC:SetGrowDirection(direction)
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
function VeiPlatesCC:SetVerticalOffset(offset)
CONFIG.verticalOffset = offset
Print("Vertical offset set to " .. offset)

-- Recreate all containers
self:ResetContainers()
end

-- Set horizontal offset
function VeiPlatesCC:SetHorizontalOffset(offset)
CONFIG.xOffset = offset
Print("Horizontal offset set to " .. offset)

-- Recreate all containers
self:ResetContainers()
end

-- Set scale of icon container
function VeiPlatesCC:SetScale(scale)
CONFIG.scale = scale
Print("Scale set to " .. scale)

-- Update scale on all containers
for unitID, container in pairs(IconContainers) do
if container then
    container:SetScale(scale)
end
end
end

-- Reset all containers to apply new settings
function VeiPlatesCC:ResetContainers()
-- Make a copy of current unit IDs
local unitIDs = {}
for unitID, _ in pairs(IconContainers) do
table.insert(unitIDs, unitID)
end

-- Remove all containers
for _, unitID in ipairs(unitIDs) do
if IconContainers[unitID] then
    IconContainers[unitID]:Hide()
    IconContainers[unitID] = nil
end
end

-- Create new containers for all tracked units
for _, unitID in ipairs(unitIDs) do
if UnitExists(unitID) then
    local defaultPlate = C_NamePlate.GetNamePlateForUnit(unitID)
    if defaultPlate then
        local container = CreateIconContainer(defaultPlate, unitID)
        if container then
            IconContainers[unitID] = container
            self:UpdateAurasForUnit(unitID)
        end
    end
end
end
end

-- Set size of CC icons
function VeiPlatesCC:SetIconSize(size)
-- Update the configuration
CONFIG.iconSize = size
Print("Icon size set to " .. size)

-- Recreate all containers
self:ResetContainers()
end

-- Set maximum number of icons
function VeiPlatesCC:SetMaxIcons(count)
-- Update the configuration
CONFIG.maxIcons = count
Print("Maximum icons set to " .. count)

-- Recreate all containers
self:ResetContainers()
end

-- Set spacing between icons
function VeiPlatesCC:SetIconSpacing(spacing)
if not spacing or spacing < 0 then
Print("Invalid spacing. Usage: /vpcc spacing VALUE")
Print("Current spacing: " .. CONFIG.spacing)
return
end

CONFIG.spacing = spacing
Print("Icon spacing set to " .. spacing .. " pixels")

-- Recreate all containers with new spacing
self:ResetContainers()
end

-- Toggle debug mode
function VeiPlatesCC:ToggleDebug()
CONFIG.debug = not CONFIG.debug
Print("Debug mode " .. (CONFIG.debug and "enabled" or "disabled"))
end

-- Force update all icons
function VeiPlatesCC:ForceUpdate()
Print("Forcing update of all nameplate CC icons")

-- Clear cache for all units
cachedAurasByUnit = {}

-- Update all icons
self:UpdateAllNameplates()
end

-- Display current settings
function VeiPlatesCC:ShowSettings()
Print("Current VeiPlatesCC Settings:")
Print("  Icon Size: " .. CONFIG.iconSize .. " pixels")
Print("  Maximum Icons: " .. CONFIG.maxIcons)
Print("  Spacing: " .. CONFIG.spacing .. " pixels")
Print("  Vertical Offset: " .. CONFIG.verticalOffset .. " pixels")
Print("  Horizontal Offset: " .. CONFIG.xOffset .. " pixels")
Print("  Scale: " .. CONFIG.scale)
Print("  Growth Direction: " .. CONFIG.growDirection)
Print("  Debug Mode: " .. (CONFIG.debug and "Enabled" or "Disabled"))

-- Show active nameplates count
local count = 0
for _ in pairs(IconContainers) do count = count + 1 end
Print("  Active Nameplate Count: " .. count)

-- Show aura category counts
Print("Aura Categories:")
for i, category in ipairs(AURA_CATEGORIES) do
local spellCount = 0
for _ in pairs(category.spells) do spellCount = spellCount + 1 end
Print(string.format("  %d. %s (Priority: %d, Spells: %d)", 
    i, category.name, category.priority, spellCount))
end
end

-- =======================================
-- INITIALIZATION AND EVENT HANDLING
-- =======================================
-- Initialize the module
function VeiPlatesCC:Initialize()
-- Build lookup tables
BuildSpellLookupTables()

-- Create event handling frame
local eventFrame = CreateFrame("Frame")

-- Set debug mode to false
CONFIG.debug = false

-- Register necessary events
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Handle events
eventFrame:SetScript("OnEvent", function(self, event, ...)
if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
    -- Clean up any existing data
    VeiPlatesCC:Cleanup()
    
    -- Update with a slight delay to ensure everything is loaded
    C_Timer.After(1, function()
        -- Check for all existing nameplates
        local found = 0
        for i = 1, 40 do
            local unitID = "nameplate" .. i
            if UnitExists(unitID) then
                VeiPlatesCC:TrackNameplate(unitID)
                found = found + 1
            end
        end
    end)
    
elseif event == "NAME_PLATE_UNIT_ADDED" then
    local unitID = ...
    
    -- Use a short delay to ensure the nameplate is fully created
    C_Timer.After(0.1, function()
        if UnitExists(unitID) then
            VeiPlatesCC:TrackNameplate(unitID)
        end
    end)
    
elseif event == "NAME_PLATE_UNIT_REMOVED" then
    local unitID = ...
    VeiPlatesCC:UntrackNameplate(unitID)
    
elseif event == "UNIT_AURA" then
    local unitID = ...
    
    if unitID and unitID:match("nameplate%d") then
        -- Clear cache for this unit
        if cachedAurasByUnit[unitID] then
            cachedAurasByUnit[unitID] = nil
        end
        
        -- Update the specific nameplate unit
        VeiPlatesCC:UpdateAurasForUnit(unitID)
    elseif unitID == "target" then
        -- If it's the target, find its nameplate unit ID and update
        local targetGUID = UnitGUID("target")
        if targetGUID and UnitsByGUID[targetGUID] then
            local plateUnitID = UnitsByGUID[targetGUID]
            if cachedAurasByUnit[plateUnitID] then
                cachedAurasByUnit[plateUnitID] = nil
            end
            VeiPlatesCC:UpdateAurasForUnit(plateUnitID)
        end
    end
    
elseif event == "PLAYER_TARGET_CHANGED" then
    -- Update the current target's auras
    if UnitExists("target") then
        local targetGUID = UnitGUID("target")
        if targetGUID and UnitsByGUID[targetGUID] then
            local plateUnitID = UnitsByGUID[targetGUID]
            if cachedAurasByUnit[plateUnitID] then
                cachedAurasByUnit[plateUnitID] = nil
            end
            VeiPlatesCC:UpdateAurasForUnit(plateUnitID)
        end
    end
    
elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    VeiPlatesCC:HandleCombatLogEvent(...)
end
end)

-- Set up continuous monitoring of nameplates to catch any issues
-- This serves as a backup in case events are missed
C_Timer.NewTicker(0.5, function()
-- Scan for any existing nameplates that we might have missed
for i = 1, 40 do
    local unitID = "nameplate" .. i
    if UnitExists(unitID) and not IconContainers[unitID] then
        VeiPlatesCC:TrackNameplate(unitID)
    end
end

-- Update currently tracked nameplates
for unitID, container in pairs(IconContainers) do
    if UnitExists(unitID) then
        VeiPlatesCC:UpdateAurasForUnit(unitID)
    end
end
end)

-- Register slash commands
SLASH_VPCC1 = "/vpcc"
SlashCmdList["VPCC"] = function(msg)
local command, arg = msg:match("^(%S*)%s*(.-)$")
command = command:lower()

if command == "" then
    Print("Commands:")
    Print("  /vpcc size SIZE - Set icon size")
    Print("  /vpcc spacing VALUE - Set spacing between icons")
    Print("  /vpcc scale SCALE - Set icon scale")
    Print("  /vpcc max COUNT - Set maximum number of icons")
    Print("  /vpcc yoffset OFFSET - Set vertical offset")
    Print("  /vpcc xoffset OFFSET - Set horizontal offset")
    Print("  /vpcc grow DIRECTION - Set growth direction (RIGHT, LEFT, CENTER)")
    Print("  /vpcc settings - Show current settings")
    Print("  /vpcc update - Force update all icons")
    Print("  /vpcc debug - Toggle debug mode")
elseif command == "size" then
    local size = tonumber(arg)
    if size then
        VeiPlatesCC:SetIconSize(size)
    else
        Print("Invalid size. Usage: /vpcc size SIZE")
    end
elseif command == "scale" then
    local scale = tonumber(arg)
    if scale then
        VeiPlatesCC:SetScale(scale)
    else
        Print("Invalid scale. Usage: /vpcc scale SCALE")
    end
elseif command == "max" then
    local count = tonumber(arg)
    if count then
        VeiPlatesCC:SetMaxIcons(count)
    else
        Print("Invalid count. Usage: /vpcc max COUNT")
    end
elseif command == "yoffset" then
    local offset = tonumber(arg)
    if offset then
        VeiPlatesCC:SetVerticalOffset(offset)
    else
        Print("Invalid offset. Usage: /vpcc yoffset OFFSET")
    end
elseif command == "xoffset" then
    local offset = tonumber(arg)
    if offset then
        VeiPlatesCC:SetHorizontalOffset(offset)
    else
        Print("Invalid offset. Usage: /vpcc xoffset OFFSET")
    end
elseif command == "grow" then
    VeiPlatesCC:SetGrowDirection(arg)
elseif command == "spacing" then
    local spacing = tonumber(arg)
    if spacing then
        VeiPlatesCC:SetIconSpacing(spacing)
    else
        Print("Invalid spacing. Usage: /vpcc spacing VALUE")
    end
elseif command == "settings" or command == "status" then
    VeiPlatesCC:ShowSettings()
elseif command == "update" then
    VeiPlatesCC:ForceUpdate()
elseif command == "debug" then
    VeiPlatesCC:ToggleDebug()
else
    Print("Unknown command: " .. command)
    Print("Type /vpcc for help")
end
end

VeiPlatesCC.initialized = true
Print("VeiPlatesCC loaded. Type /vpcc for commands.")
return true
end

-- Clean up all data
function VeiPlatesCC:Cleanup()
-- Hide and clear all icon containers
for unitID, container in pairs(IconContainers) do
container:Hide()
end

-- Clear all data tables
wipe(IconContainers)
wipe(NameplatesByUnit)
wipe(NameplatesByGUID)
wipe(UnitsByGUID)
wipe(GUIDByUnit)
wipe(ActiveAurasByUnit)
wipe(cachedAurasByUnit)

DebugPrint("Cleaned up all aura tracking data")
end

-- Create a registration frame for load events
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, arg1)
if event == "ADDON_LOADED" and arg1 == addonName then
C_Timer.After(0.5, function() 
    VeiPlatesCC:Initialize() 
end)
elseif event == "PLAYER_LOGIN" then
C_Timer.After(1, function() 
    if not VeiPlatesCC.initialized then
        VeiPlatesCC:Initialize()
    end
end)
end
end)

-- Create a global debug variable (set to false)
_G.VeiPlatesCC_Debug = false