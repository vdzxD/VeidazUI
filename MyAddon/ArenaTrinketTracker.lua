local addonName, MyAddon = ...



-- Initialize Masque
local MSQ = LibStub and LibStub("Masque", true)
local group -- Masque group

-- Create a new module for arena trinket tracking
MyAddon.ArenaTrinketTracker = {}
local ArenaTrinketTracker = MyAddon.ArenaTrinketTracker

-- Configuration
ArenaTrinketTracker.config = {
    size = 43.4, -- Match your arena frame icon size
    offset = {
        x = 92, -- Double the iconXOffset to place it on the other side
        y = 0
    }
}

-- Unit mapping to health bars
local unitMapping = {
    arena1 = 1,
    arena2 = 2,
    arena3 = 3
}

-- Trinket and racial spell IDs that share cooldown
local TRINKET_SPELLS = {
    [42292] = true,  -- PvP Trinket
    [59752] = true   -- Will to Survive (Human Racial)
}
local TRINKET_ICON = 133452
local TRINKET_COOLDOWN = 120

local function CreateCooldownFrame(parent, size)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(100)
    frame:SetSize(size, size)
    
    -- Create background texture with reduced alpha
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.3) -- Reduced background alpha for better visibility
    
    -- Create icon texture with full opacity
    local icon = frame:CreateTexture(nil, "BORDER")
    icon:SetAllPoints()
    icon:SetTexture(TRINKET_ICON)
    icon:SetAlpha(1)
    icon:SetVertexColor(1, 1, 1) -- Full RGB values and no alpha modification
    frame.icon = icon
    
    -- Create normal texture with full visibility
    local normalTexture = frame:CreateTexture(nil, "ARTWORK")
    normalTexture:SetAllPoints()
    normalTexture:SetAlpha(1)
    frame:SetNormalTexture(normalTexture)
    frame.normalTexture = normalTexture
    
    -- Create cooldown frame with adjusted swipe opacity
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetUseCircularEdge(true)
    cooldown:SetDrawBling(true)
    cooldown:SetDrawEdge(true)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetSwipeColor(0, 0, 0, 0.8)
    frame.cooldown = cooldown
    
    -- Add Masque support with explicit alpha settings
    if MSQ then
        group:AddButton(frame, {
            Icon = icon,
            Normal = normalTexture,
            Cooldown = cooldown,
            IconTexture = icon, -- Additional reference for Masque
        })
        
        -- Force full visibility
        icon:SetAlpha(1)
        icon:SetVertexColor(1, 1, 1)
        normalTexture:SetAlpha(1)
        frame:SetAlpha(1)
    end
    
    -- Add a script to maintain visibility
    frame:SetScript("OnShow", function()
        icon:SetAlpha(1)
        icon:SetVertexColor(1, 1, 1)
        frame:SetAlpha(1)
    end)
    
    return frame
end

-- Function to update position relative to health bar
local function UpdateTrinketPosition(frame, healthBar)
    if healthBar and healthBar:IsVisible() then
        frame:ClearAllPoints()
        frame:SetPoint("LEFT", healthBar, "LEFT", ArenaTrinketTracker.config.offset.x, ArenaTrinketTracker.config.offset.y)
        frame:Show()
    else
        frame:Hide()
    end
end

function ArenaTrinketTracker:UpdateAllPositions()
    for unit, index in pairs(unitMapping) do
        local frame = self[unit .. "Trinket"]
        if frame and MyAddon.healthBars and MyAddon.healthBars[index] then
            UpdateTrinketPosition(frame, MyAddon.healthBars[index])
        end
    end
end

function ArenaTrinketTracker:Initialize()
    -- Initialize Masque group
    if MSQ then
        group = MSQ:Group("ArenaTrinketTracker", "Arena Trinkets")
    end
    
    -- Create frames for all arena units
    for unit, index in pairs(unitMapping) do
        self[unit .. "Trinket"] = CreateCooldownFrame(UIParent, self.config.size)
    end
    
    self:UpdateAllPositions()
    
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, 
                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, 
                  spellID, spellName = CombatLogGetCurrentEventInfo()
            
            -- Check for trinket or racial use
            if eventType == "SPELL_CAST_SUCCESS" and TRINKET_SPELLS[spellID] then
                -- Find and update the correct frame
                for unit in pairs(unitMapping) do
                    if sourceGUID == UnitGUID(unit) then
                        local frame = ArenaTrinketTracker[unit .. "Trinket"]
                        if frame and frame.cooldown then
                            frame.cooldown:SetCooldown(GetTime(), TRINKET_COOLDOWN)
                        end
                        break
                    end
                end
            end


            
        elseif event == "ARENA_OPPONENT_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            ArenaTrinketTracker:UpdateAllPositions()
        end
    end)
    
    -- Update positions regularly
    C_Timer.NewTicker(0.1, function()
        ArenaTrinketTracker:UpdateAllPositions()
    end)
end

-- Initialize when the health bars are ready
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Wait for health bars to be created
        C_Timer.After(0.5, function()
            ArenaTrinketTracker:Initialize()
        end)
    end
end)