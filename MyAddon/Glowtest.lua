local addonName, MyAddon = ...

-- Check if Masque is loaded
local Masque = LibStub and LibStub("Masque", true)
local MasqueGroup = Masque and Masque:Group("GlowTest")

-- Create GlowTest module
MyAddon.GlowTest = {
    frames = {},
    currentSpec = nil,
    initialized = {}
}

---------------------------------------
-- Specialization Definitions
---------------------------------------
local SPECIALIZATIONS = {
    RESTORATION = {
        id = "restoration",
        checkSpell = 17116, -- Nature's Swiftness
    },
    BALANCE = {
        id = "balance",
        checkSpell = 24858, -- Moonkin Form
    },
    SHADOW = {
        id = "shadow",
        checkSpell = 15473, -- Shadowform
    },
    HOLY = {
        id = "holy",
        checkSpell = 82327, -- Holy Radiance
    },
    AFFLICTION = {
        id = "affliction",
        checkSpell = 48181 -- Haunt
    },
    SUBTLETY = {
        id = "subtlety",
        checkSpell =  14183-- Premeditation
    },
    FROST = {
        id = "frost",
        checkSpell =  11958-- Premeditation
    },
    FIRE = {
        id = "fire",
        checkSpell =  11129-- Combustion
    },
    DISCIPLINE = {
        id = "discipline",
        checkSpell =  33206 -- pain suppression
    },


}

---------------------------------------
-- Equipment Slots
---------------------------------------
local TRINKET1_SLOT_ID = 13
local TRINKET2_SLOT_ID = 14
local HANDS_SLOT_ID = 10

-- Special spell IDs
local PVP_TRINKET_SPELL_ID = 42292
local SHARD_OF_WOE_SPELL_ID = 91173
local GLOVES_SPELL_ID = 82174

-- Direct mapping of spells to slots
local spellToSlot = {
    [PVP_TRINKET_SPELL_ID] = TRINKET2_SLOT_ID,
    [SHARD_OF_WOE_SPELL_ID] = TRINKET1_SLOT_ID,
    [GLOVES_SPELL_ID] = HANDS_SLOT_ID
}

---------------------------------------
-- Specialization-specific spell lists
---------------------------------------
local trackedSpellsBySpec = {
    -- Restoration spells
    restoration = {
        --First row
        { spellID = 17116, name = "Nature's Swiftness", iconID = 136076, x = 0, y = -350 },
        { spellID = 33891, name = "Tree of Life", iconID = 132145, x = 50, y = -350 },
        { type = "trinket", slotID = TRINKET1_SLOT_ID, name = "Shard of Woe", x = 100, y = -350 },
        { spellID = 5229, name = "Enrage", iconID = 132126, x = 150, y = -350 },
        { spellID = 5211, name = "Bash", iconID = 132114, x = 200, y = -350 },
        { spellID = 80965, name = "Skull Bash", iconID = 236946, x = 250, y = -350 },
        { spellID = 77761, name = "Stampeding Roar", iconID = 463283, x = 300, y = -350 },
        { spellID = 22812, name = "Barkskin", iconID = 136097, x = 350, y = -350 },

        --second row    
        { spellID = 18562, name = "Swiftmend", iconID = 134914, x = 0, y = -400 },
        { spellID = 48438, name = "Wild Growth", iconID = 236153, x = 50, y = -400 }, 
        { spellID = 16689, name = "Nature's Grasp", iconID = 136063, x = 100, y = -400 },
        { spellID = 740, name = "Tranquility", iconID = 136107, x = 150, y = -400 },
        { spellID = 29166, name = "Innervate", iconID = 136048, x = 200, y = -400 },
        { spellID = 22842, name = "Frenzied Regeneration", iconID = 132091, x = 250, y = -400 },
        { spellID = 58984, name = "Shadowmeld", iconID = 132089, x = 300, y = -400 },
        { type = "trinket", slotID = TRINKET2_SLOT_ID, name = "PvP Trinket", x = 350, y = -400 },
    },
    
    -- Balance spells - add your balance spell configuration here
    balance = {
        --First row
        { spellID = 24858, name = "Moonkin Form", iconID = 136036, x = 0, y = -350 },
        { spellID = 78675, name = "Solar Beam", iconID = 252188, x = 50, y = -350 },
        { type = "trinket", slotID = TRINKET1_SLOT_ID, name = "Shard of Woe", x = 100, y = -350 },
        { type = "equipment", slotID = HANDS_SLOT_ID, name = "Gloves", x = 150, y = -350 },
        { spellID = 5211, name = "Bash", iconID = 132114, x = 200, y = -350 },
        { spellID = 80965, name = "Skull Bash", iconID = 236946, x = 250, y = -350 },
        { spellID = 77761, name = "Stampeding Roar", iconID = 463283, x = 300, y = -350 },
        { spellID = 22812, name = "Barkskin", iconID = 136097, x = 350, y = -350 },

        --second row    
        { spellID = 48505, name = "Starfall", iconID = 236168, x = 0, y = -400 },
        { spellID = 78674, name = "Starsurge", iconID = 135730, x = 50, y = -400 }, 
        { spellID = 16689, name = "Nature's Grasp", iconID = 136063, x = 100, y = -400 },
        { spellID = 33831, name = "Force of Nature", iconID = 132129, x = 150, y = -400 },
        { spellID = 29166, name = "Innervate", iconID = 136048, x = 200, y = -400 },
        { spellID = 22842, name = "Frenzied Regeneration", iconID = 132091, x = 250, y = -400 },
        { spellID = 58984, name = "Shadowmeld", iconID = 132089, x = 300, y = -400 },
        { type = "trinket", slotID = TRINKET2_SLOT_ID, name = "PvP Trinket", x = 350, y = -400 },
    },
    shadow = {
        --First row
        { spellID = 87151, name = "Archangel", iconID = 458225, x = 0, y = -350 },
        { spellID = 6346, name = "Fear Ward", iconID = 135902, x = 50, y = -350 },
        { spellID = 34433, name = "Shadowfiend", iconID = 136199, x = 100, y = -350 },
        { spellID = 64044, name = "Psychic Horror", iconID = 237568, x = 150, y = -350 },
        { spellID = 8122, name = "Psychic Scream", iconID = 136184, x = 200, y = -350 },
        { spellID = 15487, name = "Silence", iconID = 458230, x = 250, y = -350 },
        { spellID = 64843, name = "Divine Hymn", iconID = 237540, x = 300, y = -350 },
        { spellID = 47585, name = "Dispersion", iconID = 237563, x = 350, y = -350 },


        --second row    
        { spellID = 8092, name = "Mind Blast", iconID = 136224, x = 0, y = -400 },
        { spellID = 32379, name = "Shadow Word: Death", iconID = 136149, x = 50, y = -400 }, 
        { spellID = 17, name = "Power Word: Shield", iconID = 135940, x = 100, y = -400 },
        { spellID = 73325, name = "Leap of Faith", iconID = 463835, x = 150, y = -400 },
        { spellID =586, name = "Fade", iconID = 135994, x = 200, y = -400 },
        { spellID = 33076, name = "Prayer of Mending", iconID = 135944, x = 250, y = -400 },
        { spellID = 64901, name = "Hymn of Hope", iconID = 135982, x = 300, y = -400 },
        { spellID = 59752, name = "Will to Survive", iconID = 133452, x = 350, y = -400 },
    },
    affliction = {
        --First row
        { spellID = 7781, name = "Demon Soul", iconID = 463284, x = 0, y = -350 },
        { spellID = 74434, name = "Soulburn", iconID = 463286, x = 50, y = -350 },
        { type = "trinket", slotID = TRINKET1_SLOT_ID, name = "Shard of Woe", x = 100, y = -350 },
        { spellID = 19647, name = "Spell Lock", iconID = 136174, x = 150, y = -350 },
        { spellID = 6789, name = "Death Coil", iconID = 136145, x = 200, y = -350 },
        { spellID = 5484, name = "Howl of Terror", iconID = 136147, x = 250, y = -350 },
        { spellID = 6229, name = "Shadow Ward", iconID = 136121, x = 300, y = -350 },
        { spellID = 5512, name = "HealthStone", iconID = 135230, x = 350, y = -350 },


        --second row    
        { spellID = 48181, name = "Haunt", iconID = 236298, x = 0, y = -400 },
        { spellID = 86121, name = "Soul Swap", iconID = 460857, x = 50, y = -400 }, 
        { spellID = 77799, name = "Fel Flame", iconID = 135795, x = 100, y = -400 },
        { spellID = 47897, name = "Shadowflame", iconID = 236302, x = 150, y = -400 },
        { spellID =48020, name = "Demonic Circle: Teleport", iconID = 237560, x = 200, y = -400 },
        { spellID = 19505, name = "Devour Magic", iconID = 136075, x = 250, y = -400 },
        { spellID = 79268, name = "Soul Harvest", iconID = 236223, x = 300, y = -400 },
        { spellID = 59752, name = "Will to Survive", iconID = 133452, x = 350, y = -400 },
    },
    holy = {
        --First row
        { spellID = 31842, name = "Divine Favor", iconID = 135895, x = 0, y = -350 },
        { spellID = 85673, name = "Word of Glory", iconID = 133192, x = 50, y = -350 },
        { spellID = 66007, name = "Hammer of Justice", iconID = 135963, x = 100, y = -350 },
        { spellID = 31821, name = "Aura Mastery", iconID = 135872, x = 150, y = -350 },
        { spellID = 1022, name = "Hand of Protection", iconID = 135964, x = 200, y = -350 },
        { spellID = 6940, name = "Hand of Sacrifice", iconID = 135966, x = 250, y = -350 },
        { spellID = 498, name = "Divine Protection", iconID = 524353, x = 300, y = -350 },
        { spellID = 642, name = "Divine Shield", iconID = 524354, x = 350, y = -350 },



        --second row    
        { spellID = 20473, name = "Holy Shock", iconID = 135972, x = 0, y = -400 },
        { spellID = 20271, name = "Judgement", iconID = 135959, x = 50, y = -400 }, 
        { spellID = 35395, name = "Crusader Strike", iconID = 135891, x = 100, y = -400 },
        { spellID = 54428, name = "Divine Plea", iconID = 237537, x = 150, y = -400 },
        { spellID =1044, name = "Hand of Freedom", iconID = 135968, x = 200, y = -400 },
        { spellID = 31884, name = "Avenging Wrath", iconID = 135875, x = 250, y = -400 },
        { spellID = 86150, name = "Guardian of Ancient Kings", iconID = 135919, x = 300, y = -400 },
        { spellID = 59752, name = "Will to Survive", iconID = 133452, x = 350, y = -400 },
    },
    subtlety = {
        --First row
        { spellID = 51713, name = "Shadow Dance", iconID = 236279, x = 0, y = -350 },
        { type = "trinket", slotID = TRINKET1_SLOT_ID, name = "Shard of Woe", x = 50, y = -350 },
        { spellID = 408, name = "Kidney Shot", iconID = 132298, x = 100, y = -350 },
        { spellID = 1766, name = "Kick", iconID = 132219, x = 150, y = -350 },
        { spellID = 2094, name = "Blind", iconID = 136175, x = 200, y = -350 },
        { spellID = 1776, name = "Gouge", iconID = 132155, x = 250, y = -350 },
        { spellID = 5277, name = "Evasion", iconID = 136205, x = 300, y = -350 },
        { spellID = 31224, name = "Cloak of Shadows", iconID = 136177, x = 350, y = -350 },



        --second row    
        { spellID = 14183, name = "Premeditation", iconID = 136183, x = 0, y = -400 },
        { spellID = 57934, name = "Tricks of the Trade", iconID = 236283, x = 50, y = -400 }, 
        { spellID = 73981, name = "Redirect", iconID = 458729, x = 100, y = -400 },
        { spellID = 36554, name = "Shadowstep", iconID = 132303, x = 150, y = -400 },
        { spellID = 2983, name = "Sprint", iconID = 132307, x = 200, y = -400 },
        { spellID = 51722, name = "Dismantle", iconID = 236272, x = 250, y = -400 },
        { spellID = 76577, name = "Smoke Bomb", iconID = 458733, x = 300, y = -400 },
        { spellID = 59752, name = "Will to Survive", iconID = 133452, x = 350, y = -400 },
        
    },
    frost = {
        --First row
        { spellID = 33395, name = "Freeze", iconID = 135848, x = 0, y = -350 },
        { spellID = 92283, name = "Frostfire Orb", iconID = 430840, x = 50, y = -350 },
        { type = "trinket", slotID = TRINKET1_SLOT_ID, name = "Shard of Woe", x = 100, y = -350 },
        { spellID = 2139, name = "Counterspell", iconID = 135856, x = 150, y = -350 },
        { spellID = 44572, name = "Deep Freeze", iconID = 236214, x = 200, y = -350 },
        { spellID = 55342, name = "Mirror Image", iconID = 135994, x = 250, y = -350 },
        { spellID = 11958, name = "Cold Snap", iconID = 135865, x = 300, y = -350 },
        { spellID = 45438, name = "Ice Block", iconID = 135841, x = 350, y = -350 },



        --second row    
        { spellID = 129, name = "Cone of Cold", iconID = 135852, x = 0, y = -400 },
        { spellID = 122, name = "Frost Nova", iconID = 135848, x = 50, y = -400 }, 
        { spellID = 12472, name = "Icy Veins", iconID = 135838, x = 100, y = -400 },
        { spellID = 1953, name = "Blink", iconID = 135736, x = 150, y = -400 },
        { spellID = 82676, name = "Ring of Frost", iconID = 464484, x = 200, y = -400 },
        { spellID = 11426, name = "Ice Barrier", iconID = 135988, x = 250, y = -400 },
        { spellID = 1463, name = "Mana Shield", iconID = 136153, x = 300, y = -400 },
        { spellID = 59752, name = "Will to Survive", iconID = 133452, x = 350, y = -400 },

        --side Spells
        { spellID = 66, name = "Invisibility", iconID = 132220, x = 910, y = -150 },   
        { spellID = 2136, name = "Fire Blast", iconID = 135807, x = 910, y = -200 },  
        { spellID = 12051, name = "Evocation", iconID = 136075, x = 910, y = -250 },  
        { spellID = 31687, name = "Summon Water Elemental", iconID = 135862, x = 910, y = -300 },  
        
    },

    fire = {
        --First row
        { spellID = 11113, name = "Blast Wave", iconID = 135903, x = 0, y = -350 },
        { type = "trinket", slotID = TRINKET1_SLOT_ID, name = "Shard of Woe", x = 50, y = -350 },
        { spellID = 2136, name = "Fire Blast", iconID = 135807, x = 100, y = -350 },
        { spellID = 2139, name = "Counterspell", iconID = 135856, x = 150, y = -350 },
        { spellID = 31661, name = "Dragon's Breath", iconID = 134153, x = 200, y = -350 },
        { spellID = 55342, name = "Mirror Image", iconID = 135994, x = 250, y = -350 },
        { spellID = 12051, name = "Evocation", iconID = 136075, x = 300, y = -350 },
        { spellID = 45438, name = "Ice Block", iconID = 135841, x = 350, y = -350 },



        --second row    
        { spellID = 129, name = "Cone of Cold", iconID = 135852, x = 0, y = -400 },
        { spellID = 122, name = "Frost Nova", iconID = 135848, x = 50, y = -400 }, 
        { spellID = 11129, name = "Combustion", iconID = 135824, x = 100, y = -400 },
        { spellID = 1953, name = "Blink", iconID = 135736, x = 150, y = -400 },
        { spellID = 82676, name = "Ring of Frost", iconID = 464484, x = 200, y = -400 },
        { spellID = 82731, name = "Flame Orb", iconID = 451164, x = 250, y = -400 },
        { spellID = 1463, name = "Mana Shield", iconID = 136153, x = 300, y = -400 },
        { spellID = 59752, name = "Will to Survive", iconID = 133452, x = 350, y = -400 },

        --side Spells
        { spellID = 66, name = "Invisibility", iconID = 132220, x = 910, y = -150 },   

        
    },

    discipline = {




        --First row    
        { spellID = 47540, name = "Penance", iconID = 237545, x = 0, y = -350 },
        { spellID = 10060, name = "Power Infusion", iconID = 135939, x = 50, y = -350 }, 
        { spellID = 34433, name = "Shadowfiend", iconID = 136199, x = 100, y = -350 },
        { spellID = 89485, name = "Inner Focus", iconID = 135863, x = 150, y = -350 },
        { spellID = 8122, name = "Psychic Scream", iconID = 136184, x = 200, y = -350 },
        { spellID = 19236, name = "Desperate Prayer", iconID = 135954, x = 250, y = -350 },
        { spellID = 64843, name = "Divine Hymn", iconID = 237540, x = 300, y = -350 },
        { spellID = 33206, name = "Pain Suppression", iconID = 135936, x = 350, y = -350 },

        -- --Second row
         { spellID = 33076, name = "Prayer of Mending", iconID = 135944, x = 0, y = -400 },
         { spellID = 32379, name = "Shadow Word: Death", iconID = 136149, x = 50, y = -400 },
         { spellID = 62618, name = "Power Word: Barrier", iconID = 135807, x = 100, y = -400 },
         { spellID = 73325, name = "Leap of Faith", iconID = 463835, x = 150, y = -400 },
         { spellID = 14914, name = "Holy Fire", iconID = 135972, x = 200, y = -400 },
         { spellID = 6346, name = "Fear Ward", iconID = 135902, x = 250, y = -400 },
         { spellID = 64901, name = "Hymn of Hope", iconID = 135982, x = 300, y = -400 },
         { spellID = 59752, name = "Will to Survive", iconID = 133452, x = 350, y = -400 },
   

        
    },
    
    -- Add other specializations as needed
}

---------------------------------------
-- Function to Determine Current Spec
---------------------------------------
local function DetermineCurrentSpec()
    for _, spec in pairs(SPECIALIZATIONS) do
        if IsSpellKnown(spec.checkSpell) then
            return spec.id
        end
    end
    return nil
end

---------------------------------------
-- Function to Show Starburst Effect
---------------------------------------
local function ShowStarburst(frame)
    if not frame.starburst then return end
    
    frame.starburst:SetAlpha(1)
    frame.starburst:SetSize(50, 50)
    frame.starburst:Show()
    
    local animGroup = frame.starburst:CreateAnimationGroup()
    
    -- Scale animation
    local grow = animGroup:CreateAnimation("Scale")
    grow:SetScale(1.5, 1.5)
    grow:SetDuration(0.025)
    
    local shrink = animGroup:CreateAnimation("Scale")
    shrink:SetScale(0.5, 0.5)
    shrink:SetDuration(0.05)
    shrink:SetStartDelay(0.05)
    
    -- Rotation animation
    local spin = animGroup:CreateAnimation("Rotation")
    spin:SetDegrees(480)
    spin:SetDuration(0.075)
    
    -- Clean up when finished
    shrink:SetScript("OnFinished", function() 
        frame.starburst:Hide()
        frame.starburst:SetRotation(0)
    end)
    
    animGroup:Play()
end

---------------------------------------
-- Function to Create Basic Frame
---------------------------------------
local function CreateBasicFrame(spell, spec)
    local frameName = spec .. "_" .. (spell.name or "Frame") .. "Frame"
    local frame = CreateFrame("Frame", frameName, UIParent)
    frame:SetSize(50, 50)
    frame:SetPoint("CENTER", UIParent, "CENTER", spell.x - 175, spell.y)
    frame.spec = spec

    -- Create and set up the icon
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints(frame)

    frame.originalIconID = spell.iconID -- TESTING

    
    if spell.type == "trinket" or spell.type == "equipment" then
        frame.icon:SetTexture(GetInventoryItemTexture("player", spell.slotID) or 134400)
        MyAddon.GlowTest.frames[spec .. "_slot" .. spell.slotID] = frame
        frame.slotID = spell.slotID
    else
        frame.icon:SetTexture(spell.iconID)
        MyAddon.GlowTest.frames[spec .. "_" .. spell.spellID] = frame
    end

    -- Add cooldown frame
    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame)
    
    -- Set up cooldown script
    frame.cooldown:SetScript("OnCooldownDone", function()
        frame.icon:SetDesaturated(false)
    end)

    -- Add starburst texture
    frame.starburst = frame:CreateTexture(nil, "OVERLAY")
    frame.starburst:SetAllPoints(frame)
    frame.starburst:SetAtlas("OBJFX_StarBurst")
    frame.starburst:SetAlpha(0)

    -- Apply Masque Skin if available
    if MasqueGroup then
        MasqueGroup:AddButton(frame, {
            Icon = frame.icon,
            Cooldown = frame.cooldown,
        })
    end

    -- Hide frame initially
    frame:Hide()

    return frame
end

---------------------------------------
-- Function to Handle Item Use
---------------------------------------
local function HandleItemUse(spellID)
    local slotID = spellToSlot[spellID]
    if slotID and MyAddon.GlowTest.currentSpec then
        local frame = MyAddon.GlowTest.frames[MyAddon.GlowTest.currentSpec .. "_slot" .. slotID]
        if frame then
            ShowStarburst(frame)
            return true
        end
    end
    return false
end

---------------------------------------
-- Function to Update Cooldowns
---------------------------------------
local function UpdateCooldowns(spec)
    if not spec or not trackedSpellsBySpec[spec] then return end
    
    -- Update spell cooldowns
    for _, spell in ipairs(trackedSpellsBySpec[spec]) do
        if spell.spellID then
            local frame = MyAddon.GlowTest.frames[spec .. "_" .. spell.spellID]
            if frame then
                local start, duration = GetSpellCooldown(spell.spellID)
                -- Standard GCD is 1.5 seconds, checking for longer durations to identify actual cooldowns
                local isRealCooldown = duration and duration > 1.5
                
                if duration and duration > 0 then
                    frame.cooldown:SetCooldown(start, duration)
                    frame.icon:SetDesaturated(isRealCooldown)
                else
                    frame.icon:SetDesaturated(false)
                end
            end
        end
    end
    
    -- Update equipment cooldowns
    for _, spell in ipairs(trackedSpellsBySpec[spec]) do
        if spell.type == "trinket" or spell.type == "equipment" then
            local frame = MyAddon.GlowTest.frames[spec .. "_slot" .. spell.slotID]
            if frame then
                local start, duration = GetInventoryItemCooldown("player", spell.slotID)
                if duration and duration > 0 then
                    frame.cooldown:SetCooldown(start, duration)
                    frame.icon:SetDesaturated(true)
                else
                    frame.icon:SetDesaturated(false)
                end
                frame.icon:SetTexture(GetInventoryItemTexture("player", spell.slotID) or 134400)
            end
        end
    end
end

---------------------------------------
-- Function to Initialize a Specialization
---------------------------------------
function MyAddon.GlowTest.InitializeSpec(spec)
    if not spec or not trackedSpellsBySpec[spec] or MyAddon.GlowTest.initialized[spec] then return end
    
  --  print("GlowTest: Initializing for " .. spec .. " Druid")
    
    -- Initialize frames for this spec
    for _, spell in ipairs(trackedSpellsBySpec[spec]) do
        CreateBasicFrame(spell, spec)
    end
    
    -- Mark this spec as initialized
    MyAddon.GlowTest.initialized[spec] = true
end

---------------------------------------
-- Function to Hide All Frames
---------------------------------------
function MyAddon.GlowTest.HideAllFrames()
    for _, frame in pairs(MyAddon.GlowTest.frames) do
        frame:Hide()
    end
end

---------------------------------------
-- Function to Show Frames for a Spec
---------------------------------------
function MyAddon.GlowTest.ShowFramesForSpec(spec)
    if not spec then return end
    
    -- Hide all frames first
    MyAddon.GlowTest.HideAllFrames()
    
    -- Show only frames for the specified spec
    for key, frame in pairs(MyAddon.GlowTest.frames) do
        if frame.spec == spec then
            frame:Show()
        end
    end
    
    -- Update cooldowns for this spec
    UpdateCooldowns(spec)
end

---------------------------------------
-- Function to Switch Specializations
---------------------------------------
function MyAddon.GlowTest.SwitchSpec(newSpec)
    if not newSpec or newSpec == MyAddon.GlowTest.currentSpec then return end
    
    -- Initialize the spec if needed
    if not MyAddon.GlowTest.initialized[newSpec] then
        MyAddon.GlowTest.InitializeSpec(newSpec)
    end
    
    -- Update current spec
    MyAddon.GlowTest.currentSpec = newSpec
    
    -- Show frames for the new spec
    MyAddon.GlowTest.ShowFramesForSpec(newSpec)
    
   -- print("GlowTest: Switched to " .. newSpec .. " specialization")
end

---------------------------------------
-- Event Frame
---------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Check specialization on relevant events
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TALENT_UPDATE" or 
       event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
        local currentSpec = DetermineCurrentSpec()
        if currentSpec then
            MyAddon.GlowTest.SwitchSpec(currentSpec)
        else
            MyAddon.GlowTest.HideAllFrames()
            MyAddon.GlowTest.currentSpec = nil
        end
    -- Regular event handling for cooldowns and animations
    elseif MyAddon.GlowTest.currentSpec then
        if event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
            UpdateCooldowns(MyAddon.GlowTest.currentSpec)
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            UpdateCooldowns(MyAddon.GlowTest.currentSpec)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" then
            local unit, _, spellID = ...
            if unit == "player" then
                -- Check for spell frames first
                if MyAddon.GlowTest.frames[MyAddon.GlowTest.currentSpec .. "_" .. spellID] then
                    ShowStarburst(MyAddon.GlowTest.frames[MyAddon.GlowTest.currentSpec .. "_" .. spellID])
                else
                    -- Then check for item use
                    HandleItemUse(spellID)
                end
            end
        end
    end
end)

-- Initialize
C_Timer.After(1, function()
    -- Make sure the initialized table exists
    MyAddon.GlowTest.initialized = {}
    
    -- Check current spec and initialize
    local currentSpec = DetermineCurrentSpec()
    if currentSpec then
        MyAddon.GlowTest.SwitchSpec(currentSpec)
    end
end)