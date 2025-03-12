local addonName, addon = ...

-- Debug settings
local DEBUG = false  -- Set to false to disable debug output
local function debugPrint(...)
    if DEBUG then
        print("|cFF00FF00[BuffTracker]|r", ...)
    end
end

-- Check for Masque
--local Masque = LibStub("Masque", true)
local MasqueGroup

-- Configuration table for aura categories and spell definitions
local CONFIG = {
    categories = {
        immunities = {
            priority = 1,  -- Highest priority
            spells = {
                [8178] = { iconID = 136039 },  -- Grounding totem effect
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
                [853] = { iconID = 135963 },  -- Hammer of Justice
                [2637] = { iconID = 136090 },  -- Hibernate
                [20549] = { iconID = 132368 },  -- War Stomp
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
                [49016] = { iconID = 136224 },  -- Unholy Frenzy
                [47241] = { iconID = 237558 },  -- Metamorphosis
                [79462] = { iconID = 463284 },  -- Demon Soul: Felguard
                [79460] = { iconID = 463284 },  -- Demon Soul: Felhunter
                [79459] = { iconID = 463284 },  -- Demon Soul: Imp
                [79463] = { iconID = 463284 },  -- Demon Soul: Succubus
                [79464] = { iconID = 463284 },  -- Demon Soul: Voidwalker
                [3045] = { iconID = 132208 },  -- Rapid Fire
                [19574] = { iconID = 132127 },  -- Bestial Wrath
                [1719] = { iconID = 132109 },  -- Recklessness
                [18499] = { iconID = 136009 },  -- Berserker Rage
                [31884] = { iconID = 135875 },  -- Avenging Wrath
                [12042] = { iconID = 136048 },  -- Arcane Power
                [12043] = { iconID = 136031 },  -- Presence of Mind
                [51690] = { iconID = 236277 },  -- Killing Spree
                [51713] = { iconID = 236279 },  -- Shadow Dance
            }
        }
    },
    
    -- Performance settings
    updateThrottleDelay = 0.05,    -- Minimal delay for throttled updates (seconds)
    periodicUpdateInterval = 1.0,  -- How often to do full refresh (seconds)
    batchProcessingEnabled = true, -- Enable batch processing of updates
}

-- Storage for created frames
local frames = {}

-- Optimization: Pre-compile spell lookup tables for faster searching
local spellLookup = {}
local spellToCategoryMap = {}

-- Initialize spell lookup tables
local function BuildSpellLookupTables()
    debugPrint("Building optimized spell lookup tables")
    
    for categoryName, categoryData in pairs(CONFIG.categories) do
        for spellID, spellInfo in pairs(categoryData.spells) do
            spellLookup[spellID] = true
            spellToCategoryMap[spellID] = {
                category = categoryName,
                priority = categoryData.priority,
                iconID = spellInfo.iconID
            }
        end
    end
    
    local totalSpells = 0
    for _ in pairs(spellLookup) do totalSpells = totalSpells + 1 end
    debugPrint("Tracking", totalSpells, "total spells across", #CONFIG.categories, "categories")
end

-- Cached aura information by unit
local cachedAuras = {}

-- Unit update tracking
local unitsToUpdate = {}
local lastUpdateTime = {}

-- Frame configuration for different units with size customization
local TrackedFrames = {
    target = {
        parentFrame = "TargetFrame",
        point = "CENTER",
        relativePoint = "CENTER",
        portraitRegion = "portrait",
        size = 64  -- Standard size
    },
    player = {
        parentFrame = "PlayerFrame",
        point = "CENTER",
        relativePoint = "CENTER",
        portraitRegion = "portrait",
        size = 64  -- Standard size
    },
    targettarget = {
        parentFrame = "TargetFrameToT",
        point = "CENTER",
        relativePoint = "CENTER",
        portraitRegion = "portrait",
        size = 38  -- Smaller size for ToT
    },
    focus = {
        parentFrame = "FocusFrame",
        point = "CENTER",
        relativePoint = "CENTER",
        portraitRegion = "portrait",
        size = 80  -- Standard size
    },
    focustarget = {
        parentFrame = "FocusFrameToT",
        point = "CENTER",
        relativePoint = "CENTER",
        portraitRegion = "portrait",
        size = 32  -- Smaller size for FocusTarget
    }
}

-- Optimized aura scanning function that only scans once per unit
local function GetAuraInfoByID(unit, spellID)
    if not unit or not UnitExists(unit) then
        return nil
    end
    
    -- Check if this spell is in our cached auras for this unit
    if cachedAuras[unit] and cachedAuras[unit].auras and cachedAuras[unit].auras[spellID] then
        return cachedAuras[unit].auras[spellID]
    end
    
    -- If unit has no cache yet, we need to do a full scan
    return nil
end

-- Enhanced GetHighestPriorityAura function with duration-based prioritization
local function GetHighestPriorityAura(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end
    
    local currentTime = GetTime()
    
    -- Check if we need to rebuild the cache for this unit
    if not cachedAuras[unit] or not cachedAuras[unit].scanTime or 
       (currentTime - cachedAuras[unit].scanTime) > 0.1 then  -- Refresh cache after 0.1s
       
        -- Initialize or reset the cache
        cachedAuras[unit] = {
            scanTime = currentTime,
            auras = {}
        }
        
        -- Scan buffs
        for i = 1, 40 do
            local name, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitBuff(unit, i)
            if not name then break end
            
            if spellLookup[spellID] then
                local remainingTime = 0
                if duration and duration > 0 and expirationTime then
                    remainingTime = expirationTime - currentTime
                elseif duration == 0 then
                    -- For auras with no duration (permanent), treat as very long
                    remainingTime = 9999
                end
                
                cachedAuras[unit].auras[spellID] = {
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    remainingTime = remainingTime,
                    spellID = spellID
                }
            end
        end
        
        -- Scan debuffs
        for i = 1, 40 do
            local name, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitDebuff(unit, i)
            if not name then break end
            
            if spellLookup[spellID] then
                local remainingTime = 0
                if duration and duration > 0 and expirationTime then
                    remainingTime = expirationTime - currentTime
                elseif duration == 0 then
                    -- For debuffs with no duration (permanent), treat as very long
                    remainingTime = 9999
                end
                
                cachedAuras[unit].auras[spellID] = {
                    name = name,
                    icon = icon,
                    count = count,
                    duration = duration,
                    expirationTime = expirationTime,
                    remainingTime = remainingTime,
                    spellID = spellID
                }
            end
        end
    end
    
    -- Find the highest priority aura from our cache
    local highestPriorityAura = nil
    local highestPriority = 999
    local longestDuration = -1
    
    -- Check all cached auras for this unit
    if cachedAuras[unit] and cachedAuras[unit].auras then
        for spellID, auraInfo in pairs(cachedAuras[unit].auras) do
            local categoryInfo = spellToCategoryMap[spellID]
            if categoryInfo then
                -- Determine if this aura should replace our current best
                if categoryInfo.priority < highestPriority then
                    -- Higher priority always wins
                    highestPriorityAura = {
                        spellID = spellID,
                        info = auraInfo,
                        categoryPriority = categoryInfo.priority,
                        iconID = categoryInfo.iconID,
                        remainingTime = auraInfo.remainingTime or 0
                    }
                    highestPriority = categoryInfo.priority
                    longestDuration = auraInfo.remainingTime or 0
                elseif categoryInfo.priority == highestPriority and (auraInfo.remainingTime or 0) > longestDuration then
                    -- Same priority but longer duration
                    highestPriorityAura = {
                        spellID = spellID,
                        info = auraInfo,
                        categoryPriority = categoryInfo.priority,
                        iconID = categoryInfo.iconID,
                        remainingTime = auraInfo.remainingTime or 0
                    }
                    longestDuration = auraInfo.remainingTime or 0
                end
            end
        end
    end
    
    if highestPriorityAura and DEBUG then
        debugPrint(unit, "Selected:", highestPriorityAura.info.name, 
                   "Priority:", highestPriorityAura.categoryPriority, 
                   "Remaining:", string.format("%.1f", highestPriorityAura.remainingTime))
    end
    
    return highestPriorityAura
end

-- Modified CreateBuffFrame function to handle size
local function CreateBuffFrame(unitId, config)
    local parentFrame = _G[config.parentFrame]
    if not parentFrame then
        debugPrint("Parent frame not found for unit:", unitId)
        return nil
    end

    debugPrint("Creating frame for unit:", unitId, "with parent:", config.parentFrame, "size:", config.size)
    
    local frame = {
        unit = unitId,
        currentAura = nil,
        currentGUID = nil,
        lastUpdateTime = 0
    }

    -- Create the main frame with configured size
    frame.buffFrame = CreateFrame("Frame", "MyBuffTracker_" .. unitId, parentFrame)
    frame.buffFrame:SetSize(config.size, config.size)
    frame.buffFrame:SetPoint(config.point, parentFrame[config.portraitRegion], config.relativePoint, 0, 0)
    frame.buffFrame:SetFrameStrata("BACKGROUND")
    frame.buffFrame:SetFrameLevel(1)

    -- Create button frame
    frame.buttonFrame = CreateFrame("Button", "MyBuffTrackerButton_" .. unitId, frame.buffFrame)
    frame.buttonFrame:SetAllPoints(frame.buffFrame)
    frame.buttonFrame:EnableMouse(false)
    frame.buttonFrame:SetFrameStrata("BACKGROUND")
    frame.buttonFrame:SetFrameLevel(1)

    -- Adjust stack count font size based on frame size
    local stackFontSize = config.size <= 32 and "NumberFontNormalSmall" or "NumberFontNormal"

    -- Create mask texture
    frame.maskTexture = frame.buttonFrame:CreateMaskTexture()
    frame.maskTexture:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    frame.maskTexture:SetAllPoints(frame.buttonFrame)

    -- Create icon texture
    frame.buffIcon = frame.buttonFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.buffIcon:SetAllPoints(frame.buttonFrame)
    frame.buffIcon:AddMaskTexture(frame.maskTexture)

    -- Create border
    frame.border = frame.buttonFrame:CreateTexture(nil, "BORDER", nil, 2)
    frame.border:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    frame.border:SetAllPoints(frame.buttonFrame)
    frame.border:SetVertexColor(0, 0, 0, 0.5)

    -- Create background
    frame.bg = frame.buttonFrame:CreateTexture(nil, "BACKGROUND", nil, 0)
    frame.bg:SetAllPoints(frame.buttonFrame)
    frame.bg:SetColorTexture(0, 0, 0, 0.2)
    frame.bg:AddMaskTexture(frame.maskTexture)

    -- Create cooldown frame
    frame.cooldown = CreateFrame("Cooldown", nil, frame.buttonFrame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.buttonFrame)
    frame.cooldown:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    frame.cooldown:SetDrawSwipe(true)
    frame.cooldown:SetDrawEdge(true)
    frame.cooldown:SetReverse(true)
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    frame.cooldown:SetEdgeScale(0.9)
    frame.cooldown:SetUseCircularEdge(true)
    frame.cooldown:SetHideCountdownNumbers(true)

    -- Create stack count with adjusted font size
    frame.stackCount = frame.buttonFrame:CreateFontString(nil, "OVERLAY", stackFontSize)
    frame.stackCount:SetPoint("BOTTOMRIGHT", frame.buttonFrame, "BOTTOMRIGHT", -2, 2)

    -- Add methods
    frame.ClearDisplay = function(self)
        -- Show the portrait
        local portraitRegion = _G[config.parentFrame][config.portraitRegion]
        if portraitRegion then
            portraitRegion:Show()
        end
        
        -- Hide our frames
        self.buffFrame:Hide()
        self.buttonFrame:Hide()
        
        -- Clear current aura
        self.currentAura = nil
    end

    frame.UpdateDisplay = function(self)
        -- Skip updating if we've updated recently and nothing has changed
        local currentTime = GetTime()
        if currentTime - self.lastUpdateTime < 0.05 and not unitsToUpdate[self.unit] then
            return
        end
        
        self.lastUpdateTime = currentTime
        
        -- Important: Check if unit exists and clear display if not
        if not UnitExists(self.unit) then
            self:ClearDisplay()
            return
        end
        
        -- Check if GUID has changed, which means target/focus has changed
        local guid = UnitGUID(self.unit)
        if guid ~= self.currentGUID then
            debugPrint(self.unit, "GUID changed from", self.currentGUID, "to", guid)
            self.currentGUID = guid
            
            -- Always clear display on target change before checking for new auras
            self:ClearDisplay()
            
            -- Clear unit cache for target change
            if cachedAuras[self.unit] then
                cachedAuras[self.unit] = nil
            end
        end
        
        -- Get highest priority aura for this unit
        local highestPriorityAura = GetHighestPriorityAura(self.unit)
        
        -- Check if the aura state has changed
        local needsUpdate = false
        if not highestPriorityAura and self.currentAura then
            -- Had aura, now none
            needsUpdate = true
            self.currentAura = nil
        elseif highestPriorityAura and not self.currentAura then
            -- Had none, now have one
            needsUpdate = true
            self.currentAura = highestPriorityAura
        elseif highestPriorityAura and self.currentAura then
            -- Both have auras, check if they're different
            if highestPriorityAura.spellID ~= self.currentAura.spellID or
               highestPriorityAura.info.expirationTime ~= self.currentAura.info.expirationTime or
               highestPriorityAura.info.count ~= self.currentAura.info.count then
                needsUpdate = true
                self.currentAura = highestPriorityAura
            end
        end
        
        -- Only update display if needed
        if needsUpdate then
            if self.currentAura then
                -- Hide portrait and show our frame
                if _G[config.parentFrame][config.portraitRegion] then
                    _G[config.parentFrame][config.portraitRegion]:Hide()
                end
                
                self.buffFrame:Show()
                self.buttonFrame:Show()
                
                -- Set icon
                self.buffIcon:SetTexture(self.currentAura.info.icon or self.currentAura.iconID)
                
                -- Set cooldown
                if self.currentAura.info.duration and self.currentAura.info.duration > 0 then
                    self.cooldown:SetCooldown(
                        self.currentAura.info.expirationTime - self.currentAura.info.duration,
                        self.currentAura.info.duration
                    )
                else
                    self.cooldown:Clear()
                end
                
                -- Set stack count
                if self.currentAura.info.count and self.currentAura.info.count > 1 then
                    self.stackCount:SetText(self.currentAura.info.count)
                    self.stackCount:Show()
                else
                    self.stackCount:Hide()
                end
            else
                self:ClearDisplay()
            end
        end
        
        -- Mark as updated
        unitsToUpdate[self.unit] = nil
    end

    return frame
end

-- Create throttled update processor
local updateProcessor = CreateFrame("Frame")
updateProcessor:Hide()
updateProcessor.sinceLastUpdate = 0

updateProcessor:SetScript("OnUpdate", function(self, elapsed)
    self.sinceLastUpdate = self.sinceLastUpdate + elapsed
    if self.sinceLastUpdate >= CONFIG.updateThrottleDelay then
        self.sinceLastUpdate = 0
        
        -- Process pending updates
        local updatedAny = false
        
        for unit in pairs(unitsToUpdate) do
            if frames[unit] then
                frames[unit]:UpdateDisplay()
                updatedAny = true
            end
            unitsToUpdate[unit] = nil
        end
        
        -- Hide processor if no more updates
        if not updatedAny then
            self:Hide()
        end
    end
end)

-- Request an update for a specific unit
local function RequestUnitUpdate(unit)
    if not unit then return end
    
    unitsToUpdate[unit] = true
    updateProcessor:Show()
end

-- Create periodic updater
local periodicUpdater = CreateFrame("Frame")
periodicUpdater.timeSinceLastUpdate = 0

periodicUpdater:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
    
    if self.timeSinceLastUpdate >= CONFIG.periodicUpdateInterval then
        self.timeSinceLastUpdate = 0
        
        -- Perform a full update of all frames
        for unitId, frame in pairs(frames) do
            if UnitExists(unitId) then
                -- Clear cache to force fresh scan
                if cachedAuras[unitId] then
                    cachedAuras[unitId] = nil
                end
                RequestUnitUpdate(unitId)
            end
        end
    end
end)

-- Frame configuration validation
local function ValidateFrameConfig()
    debugPrint("=== Validating frame configuration ===")
    for unitId, config in pairs(TrackedFrames) do
        local parentFrame = _G[config.parentFrame]
        if not parentFrame then
            debugPrint("WARNING: Parent frame not found:", config.parentFrame, "for unit:", unitId)
        else
            debugPrint("Found parent frame for:", unitId)
            if not parentFrame[config.portraitRegion] then
                debugPrint("WARNING: Portrait region not found:", config.portraitRegion, "for unit:", unitId)
            else
                debugPrint("Found portrait region for:", unitId)
            end
        end
    end
    debugPrint("=== Frame validation complete ===")
end

-- Frame initialization
local function InitializeFrames()
    debugPrint("=== Starting frame initialization ===")
    
    -- Build optimized spell lookup tables
    BuildSpellLookupTables()
    
    local count = 0
    for unitId, config in pairs(TrackedFrames) do
        debugPrint("Initializing frame for:", unitId)
        frames[unitId] = CreateBuffFrame(unitId, config)
        if frames[unitId] then
            count = count + 1
            debugPrint("Successfully created frame for:", unitId)
        else
            debugPrint("Failed to create frame for:", unitId)
        end
    end
    
    -- Start periodic updater
    periodicUpdater:Show()
    
    debugPrint("=== Frame initialization complete ===")
    debugPrint("Total frames created:", count)
end

-- Helper function to update dependent frames
local function UpdateDependentFrames(baseUnit)
    -- If target changes or gets aura update, check targettarget
    if baseUnit == "target" then
        if frames.targettarget then
            RequestUnitUpdate("targettarget")
        end
    -- If focus changes or gets aura update, check focustarget
    elseif baseUnit == "focus" then
        if frames.focustarget then
            RequestUnitUpdate("focustarget")
        end
    end
end

-- Add debug command function
local function AddDebugCommands()
    SLASH_BUFFTRACKER1 = "/bt"
    SlashCmdList["BUFFTRACKER"] = function(msg)
        if msg == "debug" then
            DEBUG = not DEBUG
            print("BuffTracker debug mode:", DEBUG and "ON" or "OFF")
        elseif msg == "dump" then
            if UnitExists("target") then
                print("Dumping auras for target:", UnitName("target"))
                for i = 1, 40 do
                    local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff("target", i)
                    if not name then break end
                    print(string.format("Buff %d: %s (ID: %s) - %.1f sec remaining", 
                        i, name, tostring(spellId), (expirationTime and (expirationTime - GetTime())) or 0))
                end
                
                for i = 1, 40 do
                    local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitDebuff("target", i)
                    if not name then break end
                    print(string.format("Debuff %d: %s (ID: %s) - %.1f sec remaining", 
                        i, name, tostring(spellId), (expirationTime and (expirationTime - GetTime())) or 0))
                end
            else
                print("No target selected")
            end
        elseif msg == "reset" then
            print("Resetting frames and cache")
            -- Clear all caches
            cachedAuras = {}
            unitsToUpdate = {}
            
            -- Reinitialize
            for unitId, frame in pairs(frames) do
                frame:ClearDisplay()
            end
            
            ValidateFrameConfig()
            InitializeFrames()
        elseif msg == "cache" then
            print("Cache statistics:")
            local totalCachedUnits = 0
            local totalCachedAuras = 0
            
            for unit, data in pairs(cachedAuras) do
                local auraCount = 0
                if data.auras then
                    for _ in pairs(data.auras) do auraCount = auraCount + 1 end
                end
                print(string.format("Unit: %s - %d auras cached, last scan: %.1f sec ago", 
                    UnitName(unit) or unit, auraCount, GetTime() - (data.scanTime or 0)))
                
                totalCachedUnits = totalCachedUnits + 1
                totalCachedAuras = totalCachedAuras + auraCount
            end
            
            print(string.format("Total: %d units with %d auras in cache", totalCachedUnits, totalCachedAuras))
        else
            print("BuffTracker commands:")
            print("  /bt debug - Toggle debug mode")
            print("  /bt dump - Dump auras on current target")
            print("  /bt reset - Reset and reinitialize frames")
            print("  /bt cache - Show cache statistics")
        end
    end
end

-- Intelligent unit validation - avoid processing for units that don't need it
local function ShouldProcessUnit(unit)
    if not unit then return false end
    
    -- Always process player and focus
    if unit == "player" or unit == "focus" then
        return true
    end
    
    -- For party/raid members, only process if they exist
    if unit:match("^party") or unit:match("^raid") then
        return UnitExists(unit)
    end
    
    -- For special target units, check if they exist and match frames we care about
    if unit:match("target") then
        -- Check if it's a unit we're tracking
        for trackedUnit in pairs(TrackedFrames) do
            if unit == trackedUnit then
                return UnitExists(unit)
            end
        end
    end
    
    -- Default fallback - only process if we have a frame for this unit
    return frames[unit] ~= nil and UnitExists(unit)
end

-- Create event handler frame
local EventFrame = CreateFrame("Frame")

EventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        debugPrint("=== Starting addon initialization ===")
        ValidateFrameConfig()
        InitializeFrames()
        AddDebugCommands()
        
        -- Initial update with delay to ensure all frames exist
        C_Timer.After(0.1, function()
            for unitId in pairs(frames) do
                RequestUnitUpdate(unitId)
            end
            updateProcessor:Show()
        end)
    elseif event == "PLAYER_TARGET_CHANGED" then
        -- Always clear display for target first
        if frames.target then
            frames.target:ClearDisplay()
        end
        
        -- Clear cache for target
        if cachedAuras.target then
            cachedAuras.target = nil
        end
        
        -- Clear cache for targettarget
        if cachedAuras.targettarget then
            cachedAuras.targettarget = nil
        end
        
        -- Request updates
        RequestUnitUpdate("target")
        C_Timer.After(0.05, function()
            RequestUnitUpdate("targettarget")
        end)
    elseif event == "PLAYER_FOCUS_CHANGED" then
        -- Always clear display for focus first
        if frames.focus then
            frames.focus:ClearDisplay()
        end
        
        -- Clear cache for focus
        if cachedAuras.focus then
            cachedAuras.focus = nil
        end
        
        -- Clear cache for focustarget
        if cachedAuras.focustarget then
            cachedAuras.focustarget = nil
        end
        
        -- Request updates
        RequestUnitUpdate("focus")
        C_Timer.After(0.05, function()
            RequestUnitUpdate("focustarget")
        end)
    elseif event == "UNIT_TARGET" then
        -- Only handle specific units that require cascading updates
        if unit == "target" and frames.targettarget then
            if cachedAuras.targettarget then
                cachedAuras.targettarget = nil
            end
            RequestUnitUpdate("targettarget")
        elseif unit == "focus" and frames.focustarget then
            if cachedAuras.focustarget then
                cachedAuras.focustarget = nil
            end
            RequestUnitUpdate("focustarget")
        end
    elseif event == "UNIT_AURA" then
        -- Check if we should process this unit
        if ShouldProcessUnit(unit) then
            -- Clear any cached aura data for this unit
            if cachedAuras[unit] then
                cachedAuras[unit] = nil
            end
            
            -- Request update for this unit
            RequestUnitUpdate(unit)
            
            -- Also update any dependent units
            UpdateDependentFrames(unit)
            
            -- Special case: check if this unit matches targettarget or focustarget by GUID
            local unitGUID = UnitGUID(unit)
            if unitGUID then
                if UnitExists("targettarget") and UnitGUID("targettarget") == unitGUID then
                    if cachedAuras.targettarget then
                        cachedAuras.targettarget = nil
                    end
                    RequestUnitUpdate("targettarget")
                end
                
                if UnitExists("focustarget") and UnitGUID("focustarget") == unitGUID then
                    if cachedAuras.focustarget then
                        cachedAuras.focustarget = nil
                    end
                    RequestUnitUpdate("focustarget")
                end
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        -- Combat state changed - refresh all
        C_Timer.After(0.1, function()
            for unitId in pairs(frames) do
                if UnitExists(unitId) then
                    RequestUnitUpdate(unitId)
                end
            end
        end)
    end
end)

-- Unregister any existing events
EventFrame:UnregisterAllEvents()

-- Register all needed events
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
EventFrame:RegisterEvent("UNIT_TARGET")
EventFrame:RegisterEvent("UNIT_AURA")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")