-- BuffFilter.lua with Masque support and minimal frame positioning
local addonName, addon = ...

-- Create a frame for our events
local frame = CreateFrame("Frame")

-- Initialize with filtered buffs
local filteredBuffs = {
    [93341] = true,  -- Champion of the Guardians of Hyjal (default)
    [100977] = true, -- Mastery -- harmony
    [48418] = true, -- master shapeshifter (bear)
    [768] = true, -- cat form
    [48420] = true, --master shapeshifter (cat)
    [57669] = true, --replenishment
    [63058] = true, --glyph of amberskin protection
    [5487] = true, -- bear form
    [24907] = true, -- moonking aura
    [48421] = true, --master shapeshifter (moonkin)
    [24858] = true, --moonkin aura
    [49868] = true, --mind quickening
    [96890] = true, --electrical charge
    [96219] = true, --holy walk
    [77487] = true, --shadow orb
    [53563] = true, --beacon oflight
    [74241] = true, --power torren
    [54424] = true,  -- fel intelligence
    [51701] = true, --Honor among thieves
    -- ... other filtered buffs remain the same
}

-- Default settings
local defaultSettings = {
    buffs = {
        scale = 1.15,
        point = "TOPRIGHT",
        relativeTo = "UIParent",
        relativePoint = "TOPRIGHT",
        xOffset = -30,
        yOffset = -25
    },
    debuffs = {
        scale = 1.15,
        point = "TOPRIGHT",
        relativeTo = "UIParent",
        relativePoint = "TOPRIGHT",
        xOffset = -30,
        yOffset = -100
    },
    moveMinimapToLeft = false  -- Default: don't move minimap
}

-- Current settings
local settings = {
    buffs = {},
    debuffs = {}
}

-- Masque group variable
local MasqueGroup = nil

-- Initialize Masque if available
local function InitializeMasque()
    if not MasqueGroup and LibStub and LibStub("Masque", true) then
        MasqueGroup = LibStub("Masque"):Group(addonName, "Player Buffs")
        return true
    end
    return MasqueGroup ~= nil
end

-- Function to skin a buff button with Masque
local function SkinBuffButton(button)
    if MasqueGroup then
        -- The button structure needs to conform to Masque's expectations
        if not button.icon then
            button.icon = _G[button:GetName().."Icon"]
        end
        
        if not button.border then
            button.border = _G[button:GetName().."Border"]
        end
        
        if not button.cooldown then
            button.cooldown = _G[button:GetName().."Cooldown"]
        end
        
        -- Register the button with Masque
        MasqueGroup:AddButton(button, {
            Icon = button.icon,
            Cooldown = button.cooldown,
            Border = button.border,
            Normal = _G[button:GetName().."NormalTexture"],
            Duration = _G[button:GetName().."Duration"],
            Count = _G[button:GetName().."Count"],
        })
    end
end

-- Function to update buff positions and apply Masque
local function UpdateBuffLayout()
    local visibleIndex = 1
    local buffIndex = 1
    
    -- Try to initialize Masque if not already done
    local masqueEnabled = InitializeMasque()
    
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, 
              isStealable, nameplateShowPersonal, spellID = UnitBuff("player", buffIndex)
        
        if not name then break end  -- No more buffs to check
        
        local buffButton = _G["BuffButton" .. buffIndex]
        if not buffButton then break end
        
        -- If this buff isn't filtered, update its position
        if not (spellID and filteredBuffs[spellID]) then
            -- Update the button's attributes
            buffButton:SetID(visibleIndex)
            
            -- Calculate position
            local rows = math.floor((visibleIndex - 1) / BUFFS_PER_ROW)
            local cols = (visibleIndex - 1) % BUFFS_PER_ROW
            
            -- Clear any existing position
            buffButton:ClearAllPoints()
            
            -- Set new position
            if visibleIndex == 1 then
                buffButton:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", 0, 0)
            else
                local xOffset = -cols * (buffButton:GetWidth() + 5)
                local yOffset = -rows * (buffButton:GetHeight() + 5)
                buffButton:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", xOffset, yOffset)
            end
            
            -- Apply Masque skin if available
            if masqueEnabled then
                SkinBuffButton(buffButton)
            end
            
            buffButton:Show()
            visibleIndex = visibleIndex + 1
        else
            -- Hide filtered buff
            buffButton:Hide()
            buffButton:ClearAllPoints()
        end
        
        buffIndex = buffIndex + 1
    end
    
    -- Update the buff frame's size
    if BuffFrame.numEnchants then
        BuffFrame:SetWidth((min(visibleIndex - 1, BUFFS_PER_ROW) * 32) + 2)
        BuffFrame:SetHeight((floor((visibleIndex - 2) / BUFFS_PER_ROW) + 1) * 32 + 2)
    end
    
    -- Refresh Masque group if available
    if masqueEnabled then
        MasqueGroup:ReSkin()
    end
end

-- Function to register all existing buff buttons with Masque
local function RegisterExistingBuffButtons()
    if not InitializeMasque() then return end
    
    -- Register all visible buff buttons
    for i = 1, BUFF_MAX_DISPLAY do
        local button = _G["BuffButton" .. i]
        if button then
            SkinBuffButton(button)
        end
    end
    
    -- Refresh the group
    MasqueGroup:ReSkin()
end

-- Function to apply settings to buff and debuff frames
local function ApplyFrameSettings()
    -- Move minimap if needed (to left side of screen)
    if settings.moveMinimapToLeft then
        -- Store original minimap position if not already saved
        if not BuffFilterDB.originalMinimapPosition then
            BuffFilterDB.originalMinimapPosition = {
                point = select(1, Minimap:GetPoint(1)) or "TOPRIGHT",
                relativeTo = select(2, Minimap:GetPoint(1)) and select(2, Minimap:GetPoint(1)):GetName() or "UIParent",
                relativePoint = select(3, Minimap:GetPoint(1)) or "TOPRIGHT",
                xOffset = select(4, Minimap:GetPoint(1)) or 0,
                yOffset = select(5, Minimap:GetPoint(1)) or 0
            }
        end
        
        -- Move minimap to left side
        Minimap:ClearAllPoints()
        Minimap:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, -5)
    elseif BuffFilterDB.originalMinimapPosition then
        -- Restore original minimap position if we have it and aren't moving minimap
        Minimap:ClearAllPoints()
        Minimap:SetPoint(
            BuffFilterDB.originalMinimapPosition.point,
            _G[BuffFilterDB.originalMinimapPosition.relativeTo],
            BuffFilterDB.originalMinimapPosition.relativePoint,
            BuffFilterDB.originalMinimapPosition.xOffset,
            BuffFilterDB.originalMinimapPosition.yOffset
        )
    end
    
    -- Apply buff frame settings with strata adjustment to appear above minimap
    BuffFrame:ClearAllPoints()
    BuffFrame:SetScale(settings.buffs.scale)
    BuffFrame:SetPoint(
        settings.buffs.point,
        _G[settings.buffs.relativeTo],
        settings.buffs.relativePoint,
        settings.buffs.xOffset,
        settings.buffs.yOffset
    )
    
    -- Set buff frame strata higher to ensure it can appear above minimap if needed
    BuffFrame:SetFrameStrata("HIGH")
    
    -- Apply debuff frame settings if it exists
    local debuffFrame = DebuffFrame or BuffFrame.debuffFrames
    if debuffFrame then
        debuffFrame:ClearAllPoints()
        debuffFrame:SetScale(settings.debuffs.scale)
        debuffFrame:SetPoint(
            settings.debuffs.point,
            _G[settings.debuffs.relativeTo],
            settings.debuffs.relativePoint,
            settings.debuffs.xOffset,
            settings.debuffs.yOffset
        )
        debuffFrame:SetFrameStrata("HIGH")
    end
end

-- Event handler
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            -- Initialize saved variables
            BuffFilterDB = BuffFilterDB or {}
            BuffFilterDB.filteredBuffs = BuffFilterDB.filteredBuffs or {}
            BuffFilterDB.settings = BuffFilterDB.settings or {}
            
            -- Merge saved filtered buffs with defaults
            for spellID in pairs(filteredBuffs) do
                BuffFilterDB.filteredBuffs[spellID] = true
            end
            
            -- Update filteredBuffs table with saved values
            filteredBuffs = CopyTable(BuffFilterDB.filteredBuffs)
            
            -- Load settings
            settings.buffs = CopyTable(BuffFilterDB.settings.buffs or defaultSettings.buffs)
            settings.debuffs = CopyTable(BuffFilterDB.settings.debuffs or defaultSettings.debuffs)
            
            -- Hook into the buff frame update
            BuffFrame:HookScript("OnEvent", function()
                UpdateBuffLayout()
            end)
            
            -- Apply initial frame settings
            C_Timer.After(0.5, function()
                ApplyFrameSettings()
            end)
            
        elseif loadedAddon == "Masque" then
            -- Masque loaded after our addon
            C_Timer.After(0.5, function()
                RegisterExistingBuffButtons()
                UpdateBuffLayout()
            end)
        end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            UpdateBuffLayout()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Add a small delay to ensure buff frames are loaded
        C_Timer.After(0.5, function()
            RegisterExistingBuffButtons()
            UpdateBuffLayout()
            ApplyFrameSettings()
        end)
    elseif event == "PLAYER_LOGOUT" then
        -- Ensure saved variables are up to date
        BuffFilterDB.filteredBuffs = CopyTable(filteredBuffs)
        BuffFilterDB.settings = {
            buffs = CopyTable(settings.buffs),
            debuffs = CopyTable(settings.debuffs)
        }
    end
end)

-- Add slash command to manage filtered buffs and adjust frame positioning
SLASH_BUFFFILTER1 = "/bufffilter"
SLASH_BUFFFILTER2 = "/bf"

SlashCmdList["BUFFFILTER"] = function(msg)
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]
    
    -- Filtering commands
    if command == "add" and tonumber(args[2]) then
        local spellID = tonumber(args[2])
        filteredBuffs[spellID] = true
        print(addonName .. ": Added spell ID " .. spellID .. " to filtered buffs.")
        UpdateBuffLayout()
    elseif command == "remove" and tonumber(args[2]) then
        local spellID = tonumber(args[2])
        filteredBuffs[spellID] = nil
        print(addonName .. ": Removed spell ID " .. spellID .. " from filtered buffs.")
        UpdateBuffLayout()
    elseif command == "list" then
        print(addonName .. ": Filtered buff spell IDs:")
        for id in pairs(filteredBuffs) do
            local name = GetSpellInfo(id) or "Unknown"
            print("  " .. id .. " - " .. name)
        end
    elseif command == "current" then
        print(addonName .. ": Current player buffs:")
        local i = 1
        while true do
            local name, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
            if not name then break end
            print("  " .. spellID .. " - " .. name .. (filteredBuffs[spellID] and " (filtered)" or ""))
            i = i + 1
        end
    
    -- Scale commands
    elseif command == "scale" and args[2] and tonumber(args[3]) then
        local frameType = string.lower(args[2])
        local scale = tonumber(args[3])
        
        if frameType == "buff" or frameType == "buffs" then
            settings.buffs.scale = scale
            print(addonName .. ": Set buff scale to " .. scale)
        elseif frameType == "debuff" or frameType == "debuffs" then
            settings.debuffs.scale = scale
            print(addonName .. ": Set debuff scale to " .. scale)
        else
            print(addonName .. ": Invalid frame type. Use 'buff' or 'debuff'.")
            return
        end
        
        ApplyFrameSettings()
    
    -- Position commands
    elseif command == "position" and args[2] and args[3] and args[4] and tonumber(args[5]) and tonumber(args[6]) then
        local frameType = string.lower(args[2])
        local relativeTo = args[3]
        local point = string.upper(args[4])
        local xOffset = tonumber(args[5])
        local yOffset = tonumber(args[6])
        
        -- Validate that the relative frame exists
        if not _G[relativeTo] then
            print(addonName .. ": Frame '" .. relativeTo .. "' does not exist.")
            return
        end
        
        -- Validate the anchor point
        local validPoints = {
            ["TOPLEFT"] = true, ["TOP"] = true, ["TOPRIGHT"] = true,
            ["LEFT"] = true, ["CENTER"] = true, ["RIGHT"] = true,
            ["BOTTOMLEFT"] = true, ["BOTTOM"] = true, ["BOTTOMRIGHT"] = true
        }
        
        if not validPoints[point] then
            print(addonName .. ": Invalid anchor point. Valid points: TOPLEFT, TOP, TOPRIGHT, LEFT, CENTER, RIGHT, BOTTOMLEFT, BOTTOM, BOTTOMRIGHT")
            return
        end
        
        if frameType == "buff" or frameType == "buffs" then
            settings.buffs.relativeTo = relativeTo
            settings.buffs.point = point
            settings.buffs.relativePoint = point
            settings.buffs.xOffset = xOffset
            settings.buffs.yOffset = yOffset
            print(addonName .. ": Buff position updated.")
        elseif frameType == "debuff" or frameType == "debuffs" then
            settings.debuffs.relativeTo = relativeTo
            settings.debuffs.point = point
            settings.debuffs.relativePoint = point
            settings.debuffs.xOffset = xOffset
            settings.debuffs.yOffset = yOffset
            print(addonName .. ": Debuff position updated.")
        else
            print(addonName .. ": Invalid frame type. Use 'buff' or 'debuff'.")
            return
        end
        
        ApplyFrameSettings()
    
    -- Minimap command
    elseif command == "minimap" and args[2] then
        local option = string.lower(args[2])
        
        if option == "left" or option == "move" then
            settings.moveMinimapToLeft = true
            print(addonName .. ": Minimap will be moved to the left side of screen.")
        elseif option == "restore" or option == "reset" or option == "default" then
            settings.moveMinimapToLeft = false
            print(addonName .. ": Minimap position restored to default.")
        else
            print(addonName .. ": Invalid minimap option. Use 'left' or 'restore'.")
            return
        end
        
        ApplyFrameSettings()
    
    -- Reset command
    elseif command == "reset" and args[2] then
        local frameType = string.lower(args[2])
        
        if frameType == "buff" or frameType == "buffs" then
            settings.buffs = CopyTable(defaultSettings.buffs)
            print(addonName .. ": Reset buff settings to defaults.")
        elseif frameType == "debuff" or frameType == "debuffs" then
            settings.debuffs = CopyTable(defaultSettings.debuffs)
            print(addonName .. ": Reset debuff settings to defaults.")
        elseif frameType == "all" then
            settings.buffs = CopyTable(defaultSettings.buffs)
            settings.debuffs = CopyTable(defaultSettings.debuffs)
            settings.moveMinimapToLeft = defaultSettings.moveMinimapToLeft
            print(addonName .. ": Reset all settings to defaults.")
        else
            print(addonName .. ": Invalid frame type. Use 'buff', 'debuff', or 'all'.")
            return
        end
        
        ApplyFrameSettings()
    
    -- Help command
    else
        print(addonName .. " usage:")
        print("  Filtering commands:")
        print("    /bf add [spellID] - Add a buff to the filter list")
        print("    /bf remove [spellID] - Remove a buff from the filter list")
        print("    /bf list - List all filtered buff IDs")
        print("    /bf current - List all current player buffs with IDs")
        print("  Position and scale commands:")
        print("    /bf scale (buff|debuff) [value] - Set scale (e.g., 1.5)")
        print("    /bf position (buff|debuff) [frame] [point] [xOffset] [yOffset]")
        print("      Example: /bf position buff UIParent TOPRIGHT -5 -5")
        print("    /bf minimap (left|restore) - Move minimap to left or restore it")
        print("    /bf reset (buff|debuff|all) - Reset to default position")
    end
end