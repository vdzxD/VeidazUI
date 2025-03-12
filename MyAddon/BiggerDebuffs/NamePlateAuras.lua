local addonName, MyAddon = ...

-- Initialize the NameplateAuras module in the addon namespace
MyAddon.NameplateAuras = {}

-- Configuration for aura categories and spells
local CONFIG = {
    -- Visual settings
    size = 32,                  -- Size of the priority aura icon
    verticalOffset = 24,        -- Distance above the nameplate debuff icons
    scale = 1.0,                -- Scale factor for the icon
    showCooldownText = true,    -- Show cooldown spiral and text

    -- Categories with priorities (lower number = higher priority)
    categories = {
        immunities = {
            priority = 1,  -- Highest priority
            spells = {
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
                [853] = { iconID = 135963 },  -- Hamemr of Justice
                [2637] = { iconID = 136090 },  -- Haibernate
                [20549] = { iconID = 132368 },  -- War Stomp
                [28730] = { iconID = 136222 },  -- Arcane Torrent (Mana)
                [25046] = { iconID = 136222 },  -- Arcane Torrent (Energy)
                [50613] = { iconID = 136222 },  -- Arcane Torrent (Runic Power)
                [47476] = { iconID = 136214 },  -- Strangulate
                [91800] = { iconID = 237524 },  -- Gnaw
                [49203] = { iconID = 135152 },  -- Hungering Cold
                [91797] = { iconID = 135860 },  -- Monstrous Blow (DK Abom stun)
                [64044] = { iconID = 237568 },  -- Psychic Horror (Horrify)
                [64058] = { iconID = 132343 },  -- Psychic Horror (Disarm)
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
    
    -- Debug options
    debug = false               -- Enable debug messages
}

-- Local variables
local activePlates = {}
local playerGUID = nil

-- Debug print function
local function DebugPrint(...)
    if CONFIG.debug then
        print("|cFF33FF99NameplateAuras:|r", ...)
    end
end

-- Helper function to safely compare values
local function SafeCompare(a, b)
    if a == nil or b == nil then
        return false
    end
    return tostring(a) == tostring(b)
end

-- Get aura info by spell ID
local function GetAuraInfoByID(unit, spellID)
    if not unit or not UnitExists(unit) then
        return nil
    end
    
    -- Check buffs
    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitBuff(unit, i)
        if not name then break end
        
        if spellId == spellID then
            DebugPrint("Found buff " .. name .. " with icon: " .. tostring(icon))
            return {
                name = name,
                icon = icon,
                count = count,
                duration = duration,
                expirationTime = expirationTime,
                isDebuff = false
            }
        end
    end
    
    -- Check debuffs
    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellId = UnitDebuff(unit, i)
        if not name then break end
        
        if spellId == spellID then
            DebugPrint("Found debuff " .. name .. " with icon: " .. tostring(icon))
            return {
                name = name,
                icon = icon,
                count = count,
                duration = duration,
                expirationTime = expirationTime,
                isDebuff = true
            }
        end
    end
    
    return nil
end

-- Find highest priority aura on a unit
local function GetHighestPriorityAura(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end
    
    local highestPriorityAura = nil
    local highestCategoryPriority = 999
    
    for categoryName, categoryData in pairs(CONFIG.categories) do
        for spellID, spellData in pairs(categoryData.spells) do
            local auraInfo = GetAuraInfoByID(unit, spellID)
            if auraInfo then
                if categoryData.priority < highestCategoryPriority then
                    highestPriorityAura = {
                        spellID = spellID,
                        info = auraInfo,
                        categoryPriority = categoryData.priority,
                        iconID = spellData.iconID
                    }
                    highestCategoryPriority = categoryData.priority
                end
            end
        end
    end
    
    return highestPriorityAura
end

-- Create icon frame for a nameplate
local function CreateIconFrame(healthBar)
    if healthBar.NPAuraIcon then return healthBar.NPAuraIcon end
    
    DebugPrint("Creating aura priority icon frame")
    
    -- Create the main frame
    local frame = CreateFrame("Frame", nil, healthBar)
    frame:SetSize(CONFIG.size, CONFIG.size)
    
    -- Position above the nameplate debuff container
    frame:ClearAllPoints()
    if healthBar.NDTDebuffs then
        -- If we have our debuff container, position above it
        frame:SetPoint("BOTTOM", healthBar.NDTDebuffs, "TOP", 0, 4)
    else
        -- Otherwise position above the healthbar
        frame:SetPoint("BOTTOM", healthBar, "TOP", 0, CONFIG.verticalOffset)
    end
    
    frame:SetScale(CONFIG.scale)
    
    -- Create button
    frame.button = CreateFrame("Button", nil, frame)
    frame.button:SetAllPoints(frame)
    frame.button:EnableMouse(false)
    
    -- Create icon texture - make sure it's created properly
    frame.icon = frame.button:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Trim the edges
    DebugPrint("Icon texture created")
    
    -- Create cooldown frame
    frame.cooldown = CreateFrame("Cooldown", nil, frame.button, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()
    frame.cooldown:SetDrawSwipe(true)
    frame.cooldown:SetDrawEdge(true)
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    frame.cooldown:SetHideCountdownNumbers(not CONFIG.showCooldownText)
    
    -- Create border texture with better positioning
    frame.border = frame.button:CreateTexture(nil, "OVERLAY")
    frame.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    frame.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    -- Make the border slightly larger than the icon
    frame.border:SetPoint("TOPLEFT", frame.button, "TOPLEFT", -2, 1)
    frame.border:SetPoint("BOTTOMRIGHT", frame.button, "BOTTOMRIGHT", 0, -1)
    -- Ensure border draws on top of the icon
    frame.border:SetDrawLayer("OVERLAY", 7)
    
    -- Create stack count
    frame.count = frame.button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.count:SetPoint("BOTTOMRIGHT", frame.button, "BOTTOMRIGHT", -1, 1)
    
    -- Hide by default
    frame:Hide()
    
    healthBar.NPAuraIcon = frame
    return frame
end

-- Update the aura icon for a nameplate
local function UpdateAuraIcon(nameplate)
    if not nameplate then 
        return 
    end
    
    -- Get the unit ID from the nameplate
    local unitID
    if nameplate.namePlateUnitToken then
        unitID = nameplate.namePlateUnitToken
    elseif nameplate.UnitFrame and nameplate.UnitFrame.unit then
        unitID = nameplate.UnitFrame.unit
    end
    
    if not unitID or not UnitExists(unitID) or UnitIsFriend("player", unitID) then 
        return 
    end
    
    -- Get the health bar
    local healthBar
    if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
        healthBar = nameplate.UnitFrame.healthBar
    else
        -- Try to find the health bar
        for _, child in ipairs({nameplate:GetChildren()}) do
            if child:GetObjectType() == "StatusBar" then
                healthBar = child
                break
            end
        end
    end
    
    if not healthBar then
        return
    end
    
    -- Create icon frame if it doesn't exist
    local iconFrame = CreateIconFrame(healthBar)
    
    -- Find highest priority aura
    local highestPriorityAura = GetHighestPriorityAura(unitID)
    
    if highestPriorityAura then
        DebugPrint("Found priority aura for " .. unitID .. ": " .. (highestPriorityAura.info.name or "Unknown"))
        DebugPrint("  SpellID: " .. highestPriorityAura.spellID)
        DebugPrint("  Icon from info: " .. (highestPriorityAura.info.icon and "Yes" or "No"))
        DebugPrint("  IconID from data: " .. (highestPriorityAura.iconID and tostring(highestPriorityAura.iconID) or "None"))
        
        -- Ensure we have a valid texture
        local textureToUse = highestPriorityAura.info.icon
        
        -- If aura info doesn't have an icon, use the one from our data
        if not textureToUse or textureToUse == "" then
            textureToUse = highestPriorityAura.iconID
            DebugPrint("  Using iconID from data: " .. tostring(textureToUse))
        end
        
        -- If we still don't have a texture, use a fallback
        if not textureToUse or textureToUse == "" then
            textureToUse = "Interface\\Icons\\INV_Misc_QuestionMark"
            DebugPrint("  No icon found, using fallback texture")
        end
        
        -- Ensure icon is showing and set the texture
        iconFrame.icon:SetTexture(textureToUse)
        iconFrame.icon:Show()
        
        DebugPrint("  Texture set: " .. tostring(textureToUse))
        
        -- Set border color based on aura type
        if highestPriorityAura.info.isDebuff then
            -- Find the debuff type from our existing aura info
            local debuffType
            -- Search through debuffs to find the matching one
            for i = 1, 40 do
                local name, _, _, debuffType_i, _, _, _, _, _, spellId = UnitDebuff(unitID, i)
                if not name then break end
                
                if spellId == highestPriorityAura.spellID then
                    debuffType = debuffType_i
                    break
                end
            end
            
            -- Apply color based on debuff type
            if debuffType and DebuffTypeColor and DebuffTypeColor[debuffType] then
                local color = DebuffTypeColor[debuffType]
                iconFrame.border:SetVertexColor(color.r, color.g, color.b)
            else
                iconFrame.border:SetVertexColor(0.8, 0, 0)  -- Default red for debuffs
            end
        else
            -- Default border for buffs
            iconFrame.border:SetVertexColor(0.2, 0.6, 1.0)  -- Light blue for buffs
        end
        
        -- Update cooldown
        if highestPriorityAura.info.duration and highestPriorityAura.info.duration > 0 then
            iconFrame.cooldown:SetCooldown(
                highestPriorityAura.info.expirationTime - highestPriorityAura.info.duration,
                highestPriorityAura.info.duration
            )
            iconFrame.cooldown:Show()
        else
            iconFrame.cooldown:Hide()
        end
        
        -- Update stack count
        if highestPriorityAura.info.count and highestPriorityAura.info.count > 1 then
            iconFrame.count:SetText(highestPriorityAura.info.count)
            iconFrame.count:Show()
        else
            iconFrame.count:Hide()
        end
        
        -- Show the frame
        iconFrame:Show()
    else
        -- No priority aura found, hide the frame
        iconFrame:Hide()
    end
end


-- Process all nameplates
local function ProcessAllNameplates()
    -- Access MyAddon's tracked nameplates if available
    if MyAddon.Nameplate and MyAddon.Nameplate.GetModifiedNameplates then
        local nameplates = MyAddon.Nameplate.GetModifiedNameplates()
        for nameplate, _ in pairs(nameplates) do
            UpdateAuraIcon(nameplate)
        end
    else
        -- Fallback to standard nameplate iteration
        for i = 1, 40 do
            local nameplate = _G["NamePlate" .. i]
            if nameplate and nameplate:IsVisible() then
                UpdateAuraIcon(nameplate)
            end
        end
    end
end

-- Public API: Update a specific nameplate
function MyAddon.NameplateAuras:UpdateNameplate(nameplate)
    if nameplate then
        UpdateAuraIcon(nameplate)
    end
end

-- Public API: Process all nameplates
function MyAddon.NameplateAuras:ScanAllNameplates()
    ProcessAllNameplates()
end

-- Public API: Set icon size
function MyAddon.NameplateAuras:SetIconSize(size)
    if not size or size <= 0 then
        print("|cFF33FF99NameplateAuras:|r Invalid size. Usage: /npauraiconsize SIZE")
        return
    end
    
    CONFIG.size = size
    print("|cFF33FF99NameplateAuras:|r Icon size set to " .. size)
    
    -- Update existing frames
    ProcessAllNameplates()
end

-- Public API: Set vertical offset
function MyAddon.NameplateAuras:SetVerticalOffset(offset)
    if not offset then
        print("|cFF33FF99NameplateAuras:|r Invalid offset. Usage: /npauraoffset OFFSET")
        return
    end
    
    CONFIG.verticalOffset = offset
    print("|cFF33FF99NameplateAuras:|r Vertical offset set to " .. offset)
    
    -- Update position of existing frames
    ProcessAllNameplates()
end

-- Public API: Set scale
function MyAddon.NameplateAuras:SetScale(scale)
    if not scale or scale <= 0 then
        print("|cFF33FF99NameplateAuras:|r Invalid scale. Usage: /npaurascale SCALE")
        return
    end
    
    CONFIG.scale = scale
    print("|cFF33FF99NameplateAuras:|r Scale set to " .. scale)
    
    -- Update existing frames
    ProcessAllNameplates()
end

-- Public API: Toggle debug mode
function MyAddon.NameplateAuras:ToggleDebug()
    CONFIG.debug = not CONFIG.debug
    print("|cFF33FF99NameplateAuras:|r Debug mode " .. (CONFIG.debug and "enabled" or "disabled"))
    
    if CONFIG.debug then
        -- Print some info about our spell data
        local count = 0
        local missingIcons = 0
        
        print("Checking spell icon data:")
        for categoryName, categoryData in pairs(CONFIG.categories) do
            for spellID, spellData in pairs(categoryData.spells) do
                count = count + 1
                if not spellData.iconID then
                    print("  Missing iconID for spell " .. spellID .. " in category " .. categoryName)
                    missingIcons = missingIcons + 1
                end
            end
        end
        
        print("Total spells: " .. count)
        print("Missing icons: " .. missingIcons)
    end
end

-- Initialize the module
function MyAddon.NameplateAuras:Initialize()
    playerGUID = UnitGUID("player")
    
    -- Register for events
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    frame:SetScript("OnEvent", function(self, event, ...)
        local arg1, arg2, arg3, arg4 = ...
        
        if event == "PLAYER_LOGIN" then
            C_Timer.After(1, function()
                ProcessAllNameplates()
                DebugPrint("Module initialized. Type /npaura for options.")
            end)
            
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unitID = arg1
            C_Timer.After(0.1, function()
                if unitID:match("nameplate%d") then
                    for i = 1, 40 do
                        local nameplate = _G["NamePlate" .. i]
                        if nameplate and nameplate.namePlateUnitToken == unitID then
                            UpdateAuraIcon(nameplate)
                            break
                        end
                    end
                end
            end)
            
        elseif event == "UNIT_AURA" then
            local unitID = arg1
            if unitID:match("nameplate%d") then
                for i = 1, 40 do
                    local nameplate = _G["NamePlate" .. i]
                    if nameplate and nameplate.namePlateUnitToken == unitID then
                        UpdateAuraIcon(nameplate)
                        break
                    end
                end
            end
            
        elseif event == "PLAYER_TARGET_CHANGED" then
            C_Timer.After(0.1, function()
                if UnitExists("target") then
                    for i = 1, 40 do
                        local nameplate = _G["NamePlate" .. i]
                        if nameplate and nameplate:IsVisible() and 
                           ((nameplate.namePlateUnitToken and UnitIsUnit(nameplate.namePlateUnitToken, "target")) or
                            (nameplate.UnitFrame and nameplate.UnitFrame.unit and UnitIsUnit(nameplate.UnitFrame.unit, "target"))) then
                            UpdateAuraIcon(nameplate)
                            break
                        end
                    end
                end
            end)
            
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            -- Handle both modern and classic APIs
            local timestamp, subEvent, _, sourceGUID, _, _, _, destGUID
            
            if CombatLogGetCurrentEventInfo then
                -- Retail/Modern API
                timestamp, subEvent, _, sourceGUID, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
            else
                -- Classic API approach - safer without varargs
                if arg2 then -- subEvent
                    subEvent = arg2
                    sourceGUID = arg4
                    destGUID = arg8
                end
            end
            
            -- Only update for aura events
            if subEvent and (subEvent:match("SPELL_AURA_") or subEvent == "SPELL_DISPEL" or subEvent == "SPELL_STOLEN") then
                -- Update all nameplates since we don't have an easy way to identify which nameplate corresponds to the GUID
                C_Timer.After(0.1, ProcessAllNameplates)
            end
        end
    end)
    
    -- Create a timer to scan nameplates periodically
    C_Timer.NewTicker(3, function()
        ProcessAllNameplates()
    end)
    
    -- Register slash commands
    SLASH_NPAURA1 = "/npaura"
    SlashCmdList["NPAURA"] = function(msg)
        if msg == "" then
            print("|cFF33FF99NameplateAuras:|r Commands:")
            print("  /npauraiconsize SIZE - Set icon size")
            print("  /npaurascale SCALE - Set icon scale")
            print("  /npauraoffset OFFSET - Set vertical offset")
            print("  /npaura debug - Toggle debug mode")
        elseif msg == "debug" then
            MyAddon.NameplateAuras:ToggleDebug()
        end
    end
    
    SLASH_NPAURAICONSIZE1 = "/npauraiconsize"
    SlashCmdList["NPAURAICONSIZE"] = function(msg)
        local size = tonumber(msg)
        MyAddon.NameplateAuras:SetIconSize(size)
    end
    
    SLASH_NPAURASCALE1 = "/npaurascale"
    SlashCmdList["NPAURASCALE"] = function(msg)
        local scale = tonumber(msg)
        MyAddon.NameplateAuras:SetScale(scale)
    end
    
    SLASH_NPAURAOFFSET1 = "/npauraoffset"
    SlashCmdList["NPAURAOFFSET"] = function(msg)
        local offset = tonumber(msg)
        MyAddon.NameplateAuras:SetVerticalOffset(offset)
    end
    
    DebugPrint("Module loaded. Type /npaura for options.")
end

-- Initialize the module after addon loads
C_Timer.After(2, function()
    MyAddon.NameplateAuras:Initialize()
    DebugPrint("Nameplate Aura Priority Tracker initialized!")
end)