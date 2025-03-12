-- PlayerDebuffs.lua
local addonName, addon = ...

local frame = CreateFrame("Frame")

-- Initialize saved variables
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")


-- Configuration settings for debuff positions
local DEBUFF_CONFIG = {
    anchorPoint = "TOPRIGHT",        -- Anchor point on the debuff button
    parentFrame = BuffFrame,         -- Parent frame to anchor to
    parentPoint = "TOPRIGHT",        -- Point on the parent frame to anchor to
    xOffset = 0,                     -- Additional horizontal offset
    yOffset = -150,                     -- Additional vertical offset
    horizontalSpacing = 5,           -- Space between debuffs horizontally
    verticalSpacing = 5,             -- Space between debuff rows
    startAfterBuffs = true,          -- Whether debuffs should start after buffs
    debuffsPerRow = DEBUFFS_PER_ROW or 8  -- Number of debuffs per row
}

-- Initialize with filtered debuffs
local filteredDebuffs = {
    [8733] = true,    -- Blessing of Blackfathom
    [51714] = true,  -- frost vulnerability
    [81132] = true,  -- scarlet fever
    [81326] = true,  -- brittle bones
    [26016] = true,  -- vindication
    [33917] = true,  -- mangle
    [43265] = true,  -- death and decay
    [65142] = true,  -- ebon plague
    [46857] = true,  -- trauma
    [29859] = true,  -- blood frenzy
    [108043] = true,  -- sunder armor


}

-- Define DEBUFFS_PER_ROW if it doesn't exist
local DEBUFFS_PER_ROW = DEBUFFS_PER_ROW or 8

-- Function to update debuff positions
local function UpdateDebuffLayout()
    local visibleIndex = 1
    local debuffIndex = 1
    
    while true do
        local name, icon, count, debuffType, duration, expirationTime, source, 
              isStealable, nameplateShowPersonal, spellID = UnitDebuff("player", debuffIndex)
        
        if not name then break end  -- No more debuffs to check
        
        -- If this debuff isn't filtered, update its position
        if not (spellID and filteredDebuffs[spellID]) then
            local buttonName = "DebuffButton" .. visibleIndex
            local debuffButton = _G[buttonName]
            
            if debuffButton then
                local buffIndex = debuffIndex  -- Store the actual buff index
                debuffButton:SetID(buffIndex)  -- Set the proper ID for the button
                
                -- Calculate position using our config settings
                local baseYOffset = 0
                if DEBUFF_CONFIG.startAfterBuffs then
                    local numBuffs = BUFF_ACTUAL_DISPLAY or 0
                    local numBuffRows = math.ceil(numBuffs/BUFFS_PER_ROW)
                    baseYOffset = numBuffRows * (BUFF_ROW_SPACING or 15)
                end
                
                local rowOffset = math.floor((visibleIndex-1) / DEBUFF_CONFIG.debuffsPerRow)
                local colOffset = (visibleIndex-1) % DEBUFF_CONFIG.debuffsPerRow
                
                debuffButton:ClearAllPoints()
                debuffButton:SetPoint(
                    DEBUFF_CONFIG.anchorPoint, 
                    DEBUFF_CONFIG.parentFrame, 
                    DEBUFF_CONFIG.parentPoint, 
                    -colOffset * (debuffButton:GetWidth() + DEBUFF_CONFIG.horizontalSpacing) + DEBUFF_CONFIG.xOffset, 
                    -baseYOffset - rowOffset * (debuffButton:GetHeight() + DEBUFF_CONFIG.verticalSpacing) + DEBUFF_CONFIG.yOffset
                )
                
                debuffButton:Show()
                visibleIndex = visibleIndex + 1
            end
        else
            -- Hide filtered debuff
            local debuffButton = _G["DebuffButton" .. debuffIndex]
            if debuffButton then
                debuffButton:Hide()
                debuffButton:ClearAllPoints()
            end
        end
        
        debuffIndex = debuffIndex + 1
    end
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize saved variables
        DebuffFilterDB = DebuffFilterDB or {}
        DebuffFilterDB.filteredDebuffs = DebuffFilterDB.filteredDebuffs or {}
        
        -- Merge saved filtered debuffs with defaults
        for spellID in pairs(filteredDebuffs) do
            DebuffFilterDB.filteredDebuffs[spellID] = true
        end
        
        -- Update filteredDebuffs table with saved values
        filteredDebuffs = CopyTable(DebuffFilterDB.filteredDebuffs)
        
        -- Hook into the buff frame update
        BuffFrame:HookScript("OnEvent", function()
            UpdateDebuffLayout()
        end)
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            UpdateDebuffLayout()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Add a small delay to ensure debuff frames are loaded
        C_Timer.After(0.5, function()
            UpdateDebuffLayout()
        end)
    elseif event == "PLAYER_LOGOUT" then
        -- Ensure saved variables are up to date
        DebuffFilterDB.filteredDebuffs = CopyTable(filteredDebuffs)
    end
end)

-- Add slash command for managing filtered debuffs
SLASH_DEBUFFFILTER1 = "/debufffilter"
SlashCmdList["DEBUFFFILTER"] = function(msg)
    local command, rest = msg:match("^(%S+)%s*(.-)$")
    command = command and command:lower() or "help"
    
    if command == "add" and rest ~= "" then
        local spellID = tonumber(rest)
        if spellID then
            -- Add by spell ID
            filteredDebuffs[spellID] = true
            print("Added spell ID " .. spellID .. " to debuff filter")
            UpdateDebuffLayout()
        else
            -- Try to find by name
            local found = false
            for i = 1, 40 do
                local name, _, _, _, _, _, _, _, _, id = UnitDebuff("player", i)
                if name and name:lower() == rest:lower() then
                    filteredDebuffs[id] = true
                    print("Added " .. name .. " (ID: " .. id .. ") to debuff filter")
                    found = true
                    UpdateDebuffLayout()
                    break
                end
            end
            
            if not found then
                print("Could not find a debuff with the name: " .. rest)
                print("Use the spell ID instead, or make sure the debuff is active on you")
            end
        end
    elseif command == "remove" and rest ~= "" then
        local spellID = tonumber(rest)
        if spellID and filteredDebuffs[spellID] then
            filteredDebuffs[spellID] = nil
            print("Removed spell ID " .. spellID .. " from debuff filter")
            UpdateDebuffLayout()
        else
            -- Try to find by name in our list
            local found = false
            for id in pairs(filteredDebuffs) do
                local name = GetSpellInfo(id)
                if name and name:lower() == rest:lower() then
                    filteredDebuffs[id] = nil
                    print("Removed " .. name .. " (ID: " .. id .. ") from debuff filter")
                    found = true
                    UpdateDebuffLayout()
                    break
                end
            end
            
            if not found then
                print("Could not find a filtered debuff with the name or ID: " .. rest)
            end
        end
    elseif command == "list" then
        print("Currently filtered debuffs:")
        local count = 0
        for id in pairs(filteredDebuffs) do
            local name = GetSpellInfo(id)
            print("  - " .. (name or "Unknown") .. " (ID: " .. id .. ")")
            count = count + 1
        end
        if count == 0 then
            print("  No debuffs are currently filtered")
        end
    elseif command == "clear" then
        wipe(filteredDebuffs)
        print("Cleared all filtered debuffs")
        UpdateDebuffLayout()
    else
        print("Debuff Filter Commands:")
        print("  /debufffilter add NAME_OR_ID - Add a debuff to filter")
        print("  /debufffilter remove NAME_OR_ID - Remove a debuff from filter")
        print("  /debufffilter list - List all filtered debuffs")
        print("  /debufffilter clear - Clear all filtered debuffs")
    end
end