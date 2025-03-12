-- Complete MyTargetAuraGrid module with aura filtering and cast bar support
-- Main file (could be named anything, e.g., MyTargetAuraGrid.lua or TargetBuffFiltering.lua)

-- Module namespace
MyTargetAuraGrid = {}

---------------------------
-- Configuration Settings
---------------------------
-- Aura grid settings
local horizontalGap  = 2      -- Horizontal spacing between aura icons (in pixels)
local verticalGap    = 2      -- Vertical spacing between aura icons (in pixels)
local maxAurasPerRow = 5      -- Maximum number of aura icons per row
local extraGroupGap  = 2      -- Extra vertical gap between the buff and debuff groups
local buffsOnTop     = true   -- Default setting - will be dynamically changed based on unit type

-- Size settings for target auras
local targetAuraSize = 20     -- Base size (width/height) for target aura icons

-- Size settings for focus auras
local focusAuraSize  = 28     -- Base size (width/height) for focus aura icons

-- Group positional offsets for target
local targetGroupOffsetX = 4  -- Horizontal offset for the target aura group
local targetGroupOffsetY = 32 -- Vertical offset for the target aura group

-- Group positional offsets for focus
local focusGroupOffsetX  = 4  -- Horizontal offset for the focus aura group
local focusGroupOffsetY  = 45 -- Vertical offset for the focus aura group

-- Expose settings to other modules
MyTargetAuraGrid.horizontalGap  = horizontalGap
MyTargetAuraGrid.verticalGap    = verticalGap
MyTargetAuraGrid.maxAurasPerRow = maxAurasPerRow
MyTargetAuraGrid.extraGroupGap  = extraGroupGap
MyTargetAuraGrid.targetAuraSize = targetAuraSize
MyTargetAuraGrid.focusAuraSize  = focusAuraSize
MyTargetAuraGrid.targetGroupOffsetX = targetGroupOffsetX
MyTargetAuraGrid.targetGroupOffsetY = targetGroupOffsetY
MyTargetAuraGrid.focusGroupOffsetX  = focusGroupOffsetX
MyTargetAuraGrid.focusGroupOffsetY  = focusGroupOffsetY

---------------------------
-- Masque Integration (For Auras Only)
---------------------------
local Masque = LibStub and LibStub("Masque", true)
local MasqueTargetBuffs, MasqueTargetDebuffs
local MasqueFocusBuffs, MasqueFocusDebuffs
if Masque then
    MasqueTargetBuffs   = Masque:Group("MyTargetAuraGrid", "Target Buffs")
    MasqueTargetDebuffs = Masque:Group("MyTargetAuraGrid", "Target Debuffs")
    MasqueFocusBuffs    = Masque:Group("MyTargetAuraGrid", "Focus Buffs")
    MasqueFocusDebuffs  = Masque:Group("MyTargetAuraGrid", "Focus Debuffs")
end

-- Helper to add a frame to Masque if not already added
local function addToMasque(frame, group)
    if frame and group and not frame.myMasqueAdded then
        group:AddButton(frame)
        frame.myMasqueAdded = true
    end
end

---------------------------
-- Filter Function
---------------------------
-- Filter function: 
local function FilterTargetAura(auraName)
    local filteredAuras = {
        "Abomination's Might",
        "Alchemist Stone",
        "Ancestral Vigor",
        "Ancient Power",
        "Aspect of the Cheetah",
        "Aspect of the Fox",
        "Aspect of the Hawk",
        "Battle Shout",
        "Bear Form",
        "Bilgewater Champion",
        "Blood Craze",
        "Blood Tap",
        "Brittle Bones",
        "Cat Form",
        "Call of the Wild",
        "Champion of ramkahen",
        "Champion of the Dragonmaw Clan",
        "Champion of the Earthen Ring",
        "Champion of the Guardians of Hyjal",
        "Champion of the Wildhammer Clan",
        "Champion of Therazane",
        "Combat Trance",
        "Commanding Shout",
        "Concentration Aura",
        "Conviction",
        "Crusader",
        "Crusader Aura",
        "Culling the Herd",
        "Dark Evangelism",
        "Darkflight",
        "Darkglow",
        "Darnassus Champion",
        "Death and Decay",
        "Death's Advance",
        "Delayed Judgement",
        "Demonic Circle: Summon",
        "Demonic Pact",
        "Demoralizing Roar",
        "Demoralizing Shout",
        "Desecration",
        "Devotion Aura",
        "Dire Magic",
        "Divine Purpose",
        "Drain Life",
        "Drain Soul",
        "earth Shock",
        "Ebon Champion",
        "Ebon Plague",
        "Echo of Light",
        "Eclipse Lunar",
        "Eclipse Solar",
        "Elemental Devastation",
        "Elemental Oath",
        "Elemental Resistance",
        "empowered Shadow",
        "Enhanced Agility",
        "Enhanced Strength",
        "eradication",
        "Evangelism",
        "Fade",
        "Fel Armor",
        "Fel Intelligence",
        "Ferocious Inspiration",
        "fire!",
        "Flametongue Totem",
        "Flask of Flowing Water",
        "Flask of Steelskin",
        "Flask of the Draconic Mind",
        "Flask of the Winds",
        "Flask of Titanic Strength",
        "Flurry",
        "Focus Fire",
        "Frostbrand Attack",
        "Furious Howl",
        "Giant Wave",
        "Gilneas Champion",
        "Glyph of Amberskin Protection",
        "Guild Champion",
        "Harmony",
        "Haunted",
        "Heartsong",
        "Hemorrhage",
        "Holy Walk",
        "Honorable Defender",
        "Honorless Target",
        "Horn of Winter",
        "Hunting Party",
        "hurricane",
        "Improved Icy Talons",
        "Improved Steady Shot",
        "Inner Fire",
        "Inner Will",
        "Judgements of the Bold",
        "Judgements of the Pure",
        "Judgements of the Wise",
        "Juggernaut",
        "Killing Machine",
        "King of the Jungle",
        "Landslide",
        "Lesser Flask of Resistance",
        "Lightning Shield",
        "Lightweave",
        "lunar Shower",
        "Maelstrom Weapon",
        "Mana Spring",
        "Mangle",
        "Master of Sublety",
        "Master Shapeshifter",
        "Mind Quickening",
        "Mind Spike",
        "Moonkin Aura",
        "Moonkin Form",
        "Nature's Grace",
        "OWlkin Frenzy",
        "Path of Frost",
        "Pattern of Light",
        "Power Torrent",
        "Precious's Ribbon",
        "preparation",
        "Primal Madness",
        "Power Torrent",
        "Pyromaniac",
        "Rageheart",
        "Rapid Killing",
        "Rapid Killings",
        "Raptor Strike",
        "Replenishment",
        "Resistance Aura",
        "resistance is Futile!",
        "Retribution Aura",
        "Righteous Fury",
        "Roar of Courage",
        "Ruinic Return",
        "Sacred Duty",
        "Scent of Blood",
        "Seal of Insight",
        "Seal of Justice",
        "Seal of Righteousness",
        "Seal of Truth",
        "Second Wind",
        "Shadow",
        "Sic 'em!",
        "Silvermoon Champion",
        "Slaughter",
        "Slice and Dice",
        "Sniper Training",
        "Soul Fragment",
        "Soul Link",
        "Spell Warding",
        "Spirit Bond",
        "Spirit Walk",
        "Stoneform",
        "Stoneskin",
        "Stormstrike",
        "Stormwind Champion",
        "Strength of Earth",
        "Sudden Death",
        "Suffering",
        "Sunder Armor",
        "Swordguard embroidery",
        "Synapse Springs",
        "Taste for Blood",
        "Tear Armor",
        "Tentacles",
        "Thunder Bluff Champion",
        "Thunder Clap",
        "Totemic Wrath",
        "Trauma",
        "Travel Form",
        "Trueshot Aura",
        "Unholy Strength",
        "Unleash Flame",
        "Unleash Frost",
        "Unleash Life",
        "Unleash Wind",
        "Unleashed Rage",
        "Vampiric Embrace",
        "Victorious",
        "Vindication",
        "Well Fed",
        "Windfury Totem",
        "Windwalk",
            
        -- Add more aura names here
    }
    for _, name in ipairs(filteredAuras) do
        if auraName == name then
            return true
        end
    end
    return false
end

---------------------------
-- Dynamic Buff Positioning
---------------------------
-- Function to determine if buffs should be displayed on top based on unit type
local function ShouldBuffsBeOnTop(unit)
    if not unit or not UnitExists(unit) then
        return true -- Default to true if no unit exists
    end
    
    -- Get unit information
    local unitName = UnitName(unit) or "Unknown"
    
    -- First, check if we're in a duel with the unit
    local isDueling = UnitIsUnit(unit, "duelpartner")
    
    -- Next, check if unit is attackable (covers duels and other PvP situations)
    local canAttack = UnitCanAttack("player", unit)
    
    -- Finally, check standard friendship status
    local isFriendly = UnitIsFriend("player", unit)
    
    -- Determine final state for display purposes:
    -- If we can attack them OR they're our duel partner, treat as hostile
    local treatAsFriendly = isFriendly and not canAttack and not isDueling
    
    return treatAsFriendly
end

---------------------------
-- Helper Functions
---------------------------
-- Reflow a single group (buffs or debuffs) into a grid.
-- 'startY' is the starting Y offset for the group.
-- 'auraSize' is the size of the auras for this group.
-- 'groupOffsetX' and 'groupOffsetY' are the offsets for this group.
local function ReflowAuraGroup(auraFrames, startY, parentFrame, auraSize, groupOffsetX, groupOffsetY)
    local currentRow = 0
    local currentCol = 0

    for _, auraFrame in ipairs(auraFrames) do
        currentCol = currentCol + 1
        if currentCol > maxAurasPerRow then
            currentCol = 1
            currentRow = currentRow + 1
        end
        local xOffset = (currentCol - 1) * (auraSize + horizontalGap)
        local yOffset = startY - (currentRow * (auraSize + verticalGap))
        auraFrame:ClearAllPoints()
        auraFrame:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", groupOffsetX + xOffset, groupOffsetY + yOffset)
    end
    
    -- Update cast bar position if available
    local unit
    if parentFrame == TargetFrame then
        unit = "target"
    elseif parentFrame == FocusFrame then
        unit = "focus"
    end
    
    if unit and MyTargetAuraGrid.CastBar then
        MyTargetAuraGrid.CastBar:UpdatePosition(unit)
    end
end

-- Process auras for a given unit (target or focus)
local function ProcessAuras(unit, buffPrefix, debuffPrefix, buffMasqueGroup, debuffMasqueGroup, parentFrame, auraSize, groupOffsetX, groupOffsetY)
    local visibleBuffFrames   = {}
    local visibleDebuffFrames = {}

    -- Determine buff positioning dynamically based on unit type
    local shouldBuffsBeOnTop = ShouldBuffsBeOnTop(unit)

    -- Process Buffs
    for i = 1, 40 do
        local name, icon, count, dispelType, duration, expirationTime, caster, isStealable, _, spellId = UnitBuff(unit, i)
        local auraFrame = _G[buffPrefix .. i]
        if auraFrame then
            if not name then
                auraFrame:Hide()
            elseif FilterTargetAura(name) then
                auraFrame:Hide()
            else
                auraFrame:Show()
                auraFrame:SetSize(auraSize, auraSize)
                table.insert(visibleBuffFrames, auraFrame)
                if buffMasqueGroup then
                    addToMasque(auraFrame, buffMasqueGroup)
                end
            end
        end
    end

    -- Process Debuffs
    for i = 1, 40 do
        local name, icon, count, dispelType, duration, expirationTime, caster, isStealable, _, spellId = UnitDebuff(unit, i)
        local auraFrame = _G[debuffPrefix .. i]
        if auraFrame then
            if not name then
                auraFrame:Hide()
            else
                auraFrame:Show()
                auraFrame:SetSize(auraSize, auraSize)
                
                -- Hide the debuff border/type indicator
                -- Safely check if border exists and is accessible
                local border = nil
                if type(auraFrame.Border) == "table" or type(auraFrame.Border) == "userdata" then
                    border = auraFrame.Border
                else
                    -- Try to find the border among the frame's regions
                    for j = 1, auraFrame:GetNumRegions() do
                        local region = select(j, auraFrame:GetRegions())
                        if region and region:GetObjectType() == "Texture" then
                            local texturePath = region:GetTexture()
                            if texturePath and type(texturePath) == "string" and 
                            (texturePath:find("DebuffBorder") or texturePath:find("Border")) then
                                border = region
                                break
                            end
                            
                            local regionName = region:GetName()
                            if regionName and type(regionName) == "string" and regionName:find("Border") then
                                border = region
                                break
                            end
                        end
                    end
                end
                
                -- Only try to hide if we found a valid border
                if border and type(border) ~= "number" and border.Hide then
                    border:Hide()
                end
                
                table.insert(visibleDebuffFrames, auraFrame)
                if debuffMasqueGroup then
                    addToMasque(auraFrame, debuffMasqueGroup)
                end
            end
        end
    end

    -- Reflow Groups - use dynamic determination of buffs/debuffs order
    if shouldBuffsBeOnTop then
        -- Buffs on top for friendly units
        ReflowAuraGroup(visibleBuffFrames, 0, parentFrame, auraSize, groupOffsetX, groupOffsetY)
        ReflowAuraGroup(visibleDebuffFrames, - (#visibleBuffFrames > 0 and (auraSize + extraGroupGap) or 0), parentFrame, auraSize, groupOffsetX, groupOffsetY)
    else
        -- Debuffs on top for hostile units
        ReflowAuraGroup(visibleDebuffFrames, 0, parentFrame, auraSize, groupOffsetX, groupOffsetY)
        ReflowAuraGroup(visibleBuffFrames, - (#visibleDebuffFrames > 0 and (auraSize + extraGroupGap) or 0), parentFrame, auraSize, groupOffsetX, groupOffsetY)
    end
end

-- Adjust auras for a given unit (target or focus)
local function AdjustAuras(frame, unit)
    if unit == "target" then
        ProcessAuras("target", "TargetFrameBuff", "TargetFrameDebuff", MasqueTargetBuffs, MasqueTargetDebuffs, TargetFrame, targetAuraSize, targetGroupOffsetX, targetGroupOffsetY)
    elseif unit == "focus" then
        ProcessAuras("focus", "FocusFrameBuff", "FocusFrameDebuff", MasqueFocusBuffs, MasqueFocusDebuffs, FocusFrame, focusAuraSize, focusGroupOffsetX, focusGroupOffsetY)
    end
end

---------------------------
-- Initialization
---------------------------
local function InitializeAddon()
    -- Hook TargetFrame
    hooksecurefunc("TargetFrame_UpdateAuras", function(self)
        AdjustAuras(self, self.unit)
    end)
    
    -- Register for events to update auras
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            AdjustAuras(TargetFrame, "target")
        elseif event == "PLAYER_FOCUS_CHANGED" then
            AdjustAuras(FocusFrame, "focus")
        elseif event == "UNIT_AURA" then
            if unit == "target" then
                AdjustAuras(TargetFrame, "target")
            elseif unit == "focus" then
                AdjustAuras(FocusFrame, "focus")
            end
        end
    end)
    
    -- Load the CastBar module if available
    if CastBarModule then
        CastBarModule:Initialize(MyTargetAuraGrid)
        
        -- Store a reference to the module
        MyTargetAuraGrid.CastBar = CastBarModule
    end
end

-- Initialize when addon loads
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitializeAddon()
    end
end)