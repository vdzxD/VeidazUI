local addonName, MyAddon = ...

-- Initialize the BuffTracker module in the addon namespace
MyAddon.BuffTracker = {}

-- Configuration table
local CONFIG = {
    categories = {
        immunities = {
            priority = 1,  -- Highest priority
            spells = {

                [8178] = { iconID = 136039 },  -- Grouning totem effect     
                [48707] = { iconID = 136120 },  -- Anti-Magic Shell
                [31224] = { iconID = 136177 },  -- Cloak of Shadows
                [23920] = { iconID = 132361 },  -- Spell Reflection
                [34471] = { iconID = 132166 },  -- The Beast Within
                [47585] = { iconID = 237563 },  -- Dispersion
                [1022] = { iconID = 135964 },  -- Blessing of Protection
                [642] = { iconID = 524354 },  -- Divine Shield
                [19263] = { iconID = 132369 },  -- Deterrence
                [45438] = { iconID = 135841 },  -- Ice Block
                [46924] = { iconID = 236303 },  -- Bladestorm
            }
        },
        
        cc = {
            priority = 2,
            spells = {
                [20549] = { iconID = 132368 },  -- War Stomp
                [853] = { iconID = 135963 },  -- Hamemr of Justice
                [28730] = { iconID = 136222 },  -- Arcane Torrent (Mana)
                [25046] = { iconID = 136222 },  -- Arcane Torrent (Energy)
                [50613] = { iconID = 136222 },  -- Arcane Torrent (Runic Power)
                [47476] = { iconID = 136214 },  -- Strangulate
                [91800] = { iconID = 237524 },  -- Gnaw
                [49203] = { iconID = 135152 },  -- Hungering Cold
                [91797] = { iconID = 135860 },  -- Monstrous Blow (DK Abom stun)
                [64044] = { iconID = 237568 },  -- Psychic Horror (Horrify)
                [605] = { iconID = 136206 },  -- Mind Control
                [8122] = { iconID = 136184 },  -- Psychic Scream
                [15487] = { iconID = 458230 },  -- Silence
                [9484] = { iconID = 136091 },  -- Shackle Undead
                [87204] = { iconID = 135945 },  -- Sin and Punishment (VT dispel)
                [60995] = { iconID = 135860 },  -- Demon Charge (Metamorphosis)
                [24259] = { iconID = 136174 },  -- Spell Lock Silence
                [6358] = { iconID = 136175 },  -- Seduction
                [5782] = { iconID = 136183 },  -- Fear
                [5484] = { iconID = 136147 },  -- Howl of Terror
                [710] = { iconID = 136135 },  -- Banish
                [6789] = { iconID = 136145 },  -- Death Coil
                [22703] = { iconID = 135860 },  -- Inferno Effect
                [30283] = { iconID = 136201 },  -- Shadowfury
                [31117] = { iconID = 135975 },  -- Unstable Affliction Silence
                [89766] = { iconID = 236316 },  -- Axe Toss (felguard stun)
                [51514] = { iconID = 237579 },  -- Hex
                [58861] = { iconID = 132114 },  -- Bash (Spirit Wolf)
                [1513] = { iconID = 132118 },  -- Scare Beast
                [3355] = { iconID = 135834 },  -- Freezing Trap
                [19386] = { iconID = 135125 },  -- Wyvern Sting
                [19503] = { iconID = 132153 },  -- Scatter Shot
                [34490] = { iconID = 132323 },  -- Silencing Shot
                [90337] = { iconID = 132159 },  -- Bad Manner (monkey stun)
                [50519] = { iconID = 132182 },  -- Sonic Blast (bat pet stun)
                [50541] = { iconID = 132195 },  -- Clench (scorpid pet disarm)
                [91644] = { iconID = 136063 },  -- Snatch (bird of prey pet disarm)
                [50318] = { iconID = 135900 },  -- Serenity Dust (moth pet silence)
                [56626] = { iconID = 136093 },  -- Sting (wasp pet stun)
                [22570] = { iconID = 132134 },  -- Maim
                [9005] = { iconID = 132142 },  -- Pounce Stun
                [5211] = { iconID = 132114 },  -- Bash
                [33786] = { iconID = 136022 },  -- Cyclone
                [81261] = { iconID = 252188 },  -- Solar Beam
                [44572] = { iconID = 236214 },  -- Deep Freeze
                [55021] = { iconID = 135856 },  -- Improved Counterspell
                [82691] = { iconID = 464484 },  -- Ring of Frost
                [18469] = { iconID = 135856 },  -- Improved Counterspell
                [118] = { iconID = 136071 },  -- Polymorph
                [28271] = { iconID = 132199 },  -- polymorph turtle
                [28272] = { iconID = 135997 },  -- polymorph pig
                [71319] = { iconID = 236708 },  -- polymorph turkey
                [61305] = { iconID = 236547 },  -- polymorph cat
                [61721] = { iconID = 319458 },  -- polymorph rabbit
                [12355] = { iconID = 135821 },  -- Impact Stun
                [31661] = { iconID = 134153 },  -- Dragon's Breath
                [51722] = { iconID = 236272 },  -- Dismantle
                [1833] = { iconID = 132092 },  -- Cheap Shot
                [408] = { iconID = 132298 },  -- Kidney Shot
                [6770] = { iconID = 132310 },  -- Sap
                [2094] = { iconID = 136175 },  -- Blind
                [1776] = { iconID = 132155 },  -- Gouge
                [1330] = { iconID = 132297 },  -- Garrote Silence
                [46968] = { iconID = 236312 },  -- Shockwave
                [85388] = { iconID = 133542 },  -- Throwdown
                [20253] = { iconID = 135860 },  -- Intercept Stun
                [20615] = { iconID = 135860 },  -- intercept 2
                [12809] = { iconID = 132325 },  -- Concussion Blow
                [7922] = { iconID = 135860 },  -- Charge Stun
                [5246] = { iconID = 132154 },  -- Intimidating Shout
                [20511] = { iconID = 132154 },  -- Intimidating shout 2
            }
        },
        
        roots = {
            priority = 3,
            spells = {
                [45524] = { iconID = 135834 },  -- Chains of Ice
                [122] = { iconID = 135848 },  -- Frost Nova
                [19185] = { iconID = 136100 },  -- Entrapment
                [64803] = { iconID = 136100 },  -- Entrapment 2
                [339] = { iconID = 136100 },  -- Entangling Roots
                [19975] = { iconID = 136100 },  -- (parent = 339) - entaling roots 2
                [33395] = { iconID = 135848 },  -- Freeze
                [83302] = { iconID = 135852 },  -- Improved Cone of Cold
                [45334] = { iconID = 132183 },  -- Feral Charge Effect
            }
        },
        
        buffs_defensive = {
            priority = 4,
            spells = {
                [49039] = { iconID = 136187 },  -- Lichborne
                [58984] = { iconID = 132089 },  -- Shadowmeld
                [48792] = { iconID = 237525 },  -- Icebound Fortitude
                [50461] = { iconID = 237510 },  -- Anti-Magic Zone
                [47788] = { iconID = 237542 },  -- Guardian Spirit
                [33206] = { iconID = 135936 },  -- Pain Suppression
                [89485] = { iconID = 135863 },  -- Inner Focus
                [22842] = { iconID = 132091 },  -- Frenzied Regeneration
                [5384] = { iconID = 132293 },  -- Feign Death
                [30823] = { iconID = 136088 },  -- Shamanistic Rage
                [31821] = { iconID = 135872 },  -- Aura Mastery
                [64205] = { iconID = 253400 },  -- Divine Sacrifice
                [498] = { iconID = 524353 },  -- Divine Protection
                [6940] = { iconID = 135966 },  -- Blessing of Sacrifice
                [53480] = { iconID = 464604 },  -- Roar of Sacrifice (Hunter Pet Skill)
                [5277] = { iconID = 136205 },  -- Evasion
                [45182] = { iconID = 132285 },  -- Cheating Death
                [74001] = { iconID = 458725 },  -- Combat Readiness
                [3411] = { iconID = 132365 },  -- Intervene
                [871] = { iconID = 132362 },  -- Shield Wall
                [22812] = { iconID = 136097 },  -- Barkskin
                [61336] = { iconID = 236169 },  -- Survival Instincts
                [17116] = { iconID = 136076 },  -- Nature's Swiftness
                [16188] = { iconID = 136076 },  -- Nature's Swiftness shaman
                [87023] = { iconID = 252268 },  -- Cauterize
                
            }
        },
        
        buffs_offensive = {
            priority = 5,
            spells = {
                [2825] = { iconID = 136012 },   -- Bloodlust
                [32182] = { iconID = 135861 },  -- Heroism
                [31884] = { iconID = 135875 },  -- Avenging Wrath
                [47241] = { iconID = 237558 },  -- Metamorphosis
                [50334] = { iconID = 236149 },  -- Berserk
                [12042] = { iconID = 136048 },  -- Arcane Power
                [10060] = { iconID = 135939 },  -- Power Infusion
                [3045] = { iconID = 132208 },   -- Rapid Fire
                [19574] = { iconID = 132127 },  -- Bestial Wrath
                [1719] = { iconID = 132109 },   -- Recklessness
                [12292] = { iconID = 136146 },  -- Death Wish
                [49016] = { iconID = 237548 },  -- Unholy Frenzy
                [51713] = { iconID = 236279 },  -- Shadow Dance
                [51690] = { iconID = 236277 },  -- Killing Spree
                [13750] = { iconID = 136206 },  -- Adrenaline Rush
                [54428] = { iconID = 237537 },  -- Divine Plea
                [85696] = { iconID = 236250 },  -- Zealotry
                [11129] = { iconID = 135824 }   -- Combustion
            }
        }
    }
}

-- Frame settings
local ICON_SIZE = 44
local ICON_SPACING = 26
local POSITION = {
    x = 395,
    y = -26.2
}

-- Test mode states moved to BuffTracker
MyAddon.BuffTracker.auraTestMode = false
local testAuraActive = false

-- Check for Masque
--local Masque = LibStub("Masque", true)
local MasqueGroup
-- Create button and group if Masque is available
if Masque then
    MasqueGroup = Masque:Group(addonName, "Aura Tracker")
end

-- Add aura cache for performance
local auraCache = {}
local lastUpdateTimes = {}
local THROTTLE_DELAY = 0.2  -- Throttle updates to 0.2 seconds

-- Cache spell lookup table for quicker checking
local spellLookup = {}
local categoryLookup = {}
local priorityLookup = {}

-- Build the lookup tables for faster access
for categoryName, categoryData in pairs(CONFIG.categories) do
    for spellID, spellData in pairs(categoryData.spells) do
        spellLookup[spellID] = spellData.iconID
        categoryLookup[spellID] = categoryName
        priorityLookup[spellID] = categoryData.priority
    end
end

-- Container for all buttons
local container = CreateFrame("Frame", "AuraTrackerContainer", UIParent)
container:SetFrameStrata("LOW")
container:SetFrameLevel(2)
container:SetSize(ICON_SIZE, (ICON_SIZE * 3) + (ICON_SPACING * 2))
container:SetPoint("CENTER", UIParent, "CENTER", POSITION.x, POSITION.y)

-- Table to store all buttons
local buttons = {}

-- Function to create a single button
local function CreateButton(unitID, index)
    local button = CreateFrame("Button", "AuraTracker"..unitID, container)
    button:SetFrameStrata("LOW")
    button:SetFrameLevel(2)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    
    if index == 1 then
        button:SetPoint("TOP", container, "TOP")
    else
        button:SetPoint("TOP", buttons[index-1], "BOTTOM", 0, -ICON_SPACING)
    end

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    button.icon = icon

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetFrameLevel(button:GetFrameLevel())
    cooldown:SetDrawEdge(true)
    cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
    cooldown:SetUseCircularEdge(false)
    cooldown:SetHideCountdownNumbers(false)
    button.cooldown = cooldown

    local count = button:CreateFontString(nil, "OVERLAY")
    count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.count = count

    button.unit = unitID
    -- Store button state for better update management
    button.currentAura = nil
    button.stableIcon = nil

    if MasqueGroup then
        MasqueGroup:AddButton(button, {
            Icon = icon,
            Cooldown = cooldown,
            Count = count,
            Normal = false,
            Border = false,
            Pushed = false,
            Disabled = false,
            Checked = false,
            Highlight = false
        })
    end

    button:Hide()
    return button
end

-- Create buttons for each unit
buttons[1] = CreateButton("arena1", 1)
buttons[2] = CreateButton("arena2", 2)
buttons[3] = CreateButton("arena3", 3)

-- Test mode functions
local function ShowTestAura(button)
    if not MyAddon.BuffTracker.auraTestMode then return end
    
    button.icon:SetTexture(136071)
    button:Show()
    
    if testAuraActive then
        button.cooldown:SetCooldown(GetTime(), 30)
        button.count:SetText("2")
        button.count:Show()
    else
        button.cooldown:Clear()
        button.count:Hide()
    end
end

-- Performance-optimized GetAuras function
local function GetAuras(unit)
    -- Return empty table for non-existent units
    if not unit or not UnitExists(unit) then
        return {}
    end
    
    -- Check cache update time
    local currentTime = GetTime()
    if auraCache[unit] and auraCache[unit].time and 
       (currentTime - auraCache[unit].time) < 0.1 then
        return auraCache[unit].auras -- Return cached auras if recently updated
    end

    local auras = {}
    
    -- Only scan for buff/debuff spellIDs that we care about (much more efficient)
    -- Check buffs
    for i = 1, 40 do
        local name, icon, stacks, _, duration, expirationTime, _, _, _, id = UnitBuff(unit, i)
        if not name then break end
        if spellLookup[id] then -- Only store if it's a spell we track
            auras[id] = { 
                name = name, 
                icon = icon, 
                count = stacks, 
                duration = duration, 
                expirationTime = expirationTime,
                priority = priorityLookup[id]
            }
        end
    end
    
    -- Check debuffs
    for i = 1, 40 do
        local name, icon, stacks, _, duration, expirationTime, _, _, _, id = UnitDebuff(unit, i)
        if not name then break end
        if spellLookup[id] then -- Only store if it's a spell we track
            auras[id] = { 
                name = name, 
                icon = icon, 
                count = stacks, 
                duration = duration, 
                expirationTime = expirationTime,
                priority = priorityLookup[id]
            }
        end
    end
    
    -- Cache the result
    auraCache[unit] = {
        auras = auras,
        time = currentTime
    }
    
    return auras
end

-- Optimized GetHighestPriorityAura
local function GetHighestPriorityAura(unit)
    if MyAddon.BuffTracker.auraTestMode then
        return {
            spellID = 118,
            info = {
                icon = 136071,
                count = testAuraActive and 2 or nil,
                duration = testAuraActive and 30 or nil,
                expirationTime = testAuraActive and (GetTime() + 30) or nil
            },
            categoryPriority = 1,
            iconID = 136071
        }
    end
    
    local auras = GetAuras(unit)
    local highestPriorityAura = nil
    local highestCategoryPriority = 999

    -- Find highest priority aura directly from the auras table
    for spellID, auraInfo in pairs(auras) do
        local priority = priorityLookup[spellID]
        if priority and priority < highestCategoryPriority then
            highestPriorityAura = {
                spellID = spellID,
                info = auraInfo,
                categoryPriority = priority,
                iconID = spellLookup[spellID]
            }
            highestCategoryPriority = priority
        end
    end

    return highestPriorityAura
end

-- Check if we're in an arena
local function IsInArena()
    -- Method 1: Check if any arena unit exists
    for i = 1, 3 do
        if UnitExists("arena" .. i) then
            return true
        end
    end
    
    -- Method 2: Check instance type
    local _, instanceType = IsInInstance()
    if instanceType == "arena" then
        return true
    end
    
    return false
end

-- Update button display
local function UpdateButton(button)
    if MyAddon.BuffTracker.auraTestMode then
        ShowTestAura(button)
        return
    end

    local aura = GetHighestPriorityAura(button.unit)
    
    -- Handle test mode
    if MyAddon.BuffTracker.auraTestMode then
        ShowTestAura(button)
        return
    end
    
    -- If there's no aura but we have a stableIcon, keep it a bit longer
    if not aura and button.stableIcon and GetTime() - button.stableIconTime < 0.1 then
        return -- Keep current display
    end
    
    -- Update button display only if there's an actual change
    if not aura then
        if button:IsShown() then
            button:Hide()
            button.currentAura = nil
            button.stableIcon = nil
        end
        return
    end
    
    -- Compare with previous state - only update if something changed
    local needsUpdate = false
    
    if not button.currentAura or 
       button.currentAura.spellID ~= aura.spellID or
       button.currentAura.expirationTime ~= aura.info.expirationTime or
       button.currentAura.count ~= aura.info.count then
        needsUpdate = true
    end
    
    if needsUpdate then
        -- Update the icon only if it's different
        if not button.stableIcon or button.stableIcon ~= aura.info.icon then
            button.icon:SetTexture(aura.info.icon or aura.iconID)
            button.stableIcon = aura.info.icon
            button.stableIconTime = GetTime()
        end
        
        -- Update cooldown
        if aura.info.duration and aura.info.duration > 0 then
            button.cooldown:SetCooldown(
                aura.info.expirationTime - aura.info.duration,
                aura.info.duration
            )
        else
            button.cooldown:Clear()
        end
        
        -- Update count
        if aura.info.count and aura.info.count > 1 then
            button.count:SetText(aura.info.count)
            button.count:Show()
        else
            button.count:Hide()
        end
        
        -- Store current state
        button.currentAura = {
            spellID = aura.spellID,
            expirationTime = aura.info.expirationTime,
            count = aura.info.count
        }
        
        -- Show the button
        if not button:IsShown() then
            button:Show()
        end
    end
end

-- Update all buttons
local function UpdateAllButtons()
    -- Check if we're in an arena before updating
    if not IsInArena() then
        -- Not in arena, hide all buttons
        for _, button in ipairs(buttons) do
            if button:IsShown() then
                button:Hide()
            end
        end
        return
    end
    
    -- We are in arena, update buttons
    local needsReskin = false
    for _, button in ipairs(buttons) do
        if button and button.unit and UnitExists(button.unit) then
            local wasShown = button:IsShown()
            UpdateButton(button)
            if wasShown ~= button:IsShown() then
                needsReskin = true
            end
        elseif button:IsShown() then
            button:Hide()
            needsReskin = true
        end
    end
    
    -- Only call ReSkin once if appearance changes happened
    if MasqueGroup and needsReskin then
        MasqueGroup:ReSkin()
    end
end

-- Throttled update function
local isUpdating = false
local function ThrottledUpdate(unit)
    local currentTime = GetTime()
    
    -- If no unit specified, update all
    if not unit then
        -- Only update if not already updating and enough time has passed
        if not isUpdating and (not lastUpdateTimes.all or (currentTime - lastUpdateTimes.all > THROTTLE_DELAY)) then
            isUpdating = true
            lastUpdateTimes.all = currentTime
            
            C_Timer.After(0, function()
                UpdateAllButtons()
                isUpdating = false
            end)
        end
        return
    end
    
    -- For specific unit updates
    if not lastUpdateTimes[unit] or (currentTime - lastUpdateTimes[unit] > THROTTLE_DELAY) then
        lastUpdateTimes[unit] = currentTime
        
        -- Find and update specific button
        for _, button in ipairs(buttons) do
            if button.unit == unit then
                UpdateButton(button)
                break
            end
        end
    end
end

function MyAddon.BuffTracker:ToggleAuraTest()
    self.auraTestMode = not self.auraTestMode
    testAuraActive = false
    
    if self.auraTestMode then
        for _, button in ipairs(buttons) do
            ShowTestAura(button)
        end
    else
        for _, button in ipairs(buttons) do
            button:Hide()
        end
    end
end

function MyAddon.BuffTracker:ToggleTestAura()
    if not self.auraTestMode then return end
    
    testAuraActive = not testAuraActive
    for _, button in ipairs(buttons) do
        ShowTestAura(button)
    end
end

-- Add StartTracking function that ArenaFrame.lua is looking for
function MyAddon.BuffTracker.StartTracking(unit, iconFrame)
    -- Queue an update for this unit
    ThrottledUpdate(unit)
end

-- Clear cache function for when entering/leaving arenas
local function ClearCache()
    auraCache = {}
    lastUpdateTimes = {}
    for _, button in ipairs(buttons) do
        button.currentAura = nil
        button.stableIcon = nil
    end
end

-- Event handling
local events = CreateFrame("Frame")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
-- More reliable events for arena in Cataclysm Classic
events:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")

events:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BATTLEFIELD_STATUS" or event == "ZONE_CHANGED_NEW_AREA" then
        -- These events might indicate we entered/left an arena
        ClearCache()
        -- Use a slight delay to ensure arena frames are available
        C_Timer.After(0.5, function()
            ThrottledUpdate()
        end)
    elseif event == "UNIT_AURA" then
        -- Only process UNIT_AURA events for arena units
        if unit and string.match(unit, "arena%d") then
            -- Invalidate cache for this unit
            if auraCache[unit] then
                auraCache[unit] = nil
            end
            -- Queue update
            ThrottledUpdate(unit)
        end
    end
end)

-- Slash command registration
local function RegisterSlashCommands()
    SLASH_AURATEST1 = "/auratest"
    SLASH_AURATOGGLE1 = "/auratoggle"
    
    SlashCmdList["AURATEST"] = function(msg)
        if MyAddon and MyAddon.BuffTracker then
            MyAddon.BuffTracker:ToggleAuraTest()
            print("Aura test mode " .. (MyAddon.BuffTracker.auraTestMode and "enabled" or "disabled"))
        else
            print("Error: BuffTracker module not properly initialized")
        end
    end
    
    SlashCmdList["AURATOGGLE"] = function(msg)
        if MyAddon and MyAddon.BuffTracker then
            MyAddon.BuffTracker:ToggleTestAura()
            print("Test aura " .. (testAuraActive and "active" or "inactive"))
        else
            print("Error: BuffTracker module not properly initialized")
        end
    end
end

-- Create a loader frame
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        RegisterSlashCommands()
    end
end)

-- Position control functions
function MyAddon.BuffTracker:SetPosition(x, y)
    POSITION.x = x
    POSITION.y = y
    container:ClearAllPoints()
    container:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function MyAddon.BuffTracker:GetPosition()
    return POSITION.x, POSITION.y
end

function MyAddon.BuffTracker:SetSpacing(spacing)
    ICON_SPACING = spacing
    for i = 2, 3 do
        buttons[i]:ClearAllPoints()
        buttons[i]:SetPoint("TOP", buttons[i-1], "BOTTOM", 0, -spacing)
    end
end

-- Masque update function
function MyAddon.BuffTracker:UpdateMasqueSettings()
    if MasqueGroup then
        MasqueGroup:ReSkin()
    end
end

-- Initial update
ThrottledUpdate()