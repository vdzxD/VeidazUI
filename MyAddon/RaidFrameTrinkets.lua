local addonName, MyAddon = ...

-- Initialize Masque
local MSQ = LibStub and LibStub("Masque", true)
local group -- Masque group

-- Create a new module for trinket tracking
MyAddon.TrinketTracker = {}
local TrinketTracker = MyAddon.TrinketTracker

-- Configuration - Fixed positions for each unit
TrinketTracker.config = {
    size = 24,
    positions = {
        -- Adjust these X, Y coordinates as needed
        player = { x = 208, y = 475 },
        party1 = { x = 208, y = 412 },
        party2 = { x = 208, y = 349 }
    },
    showPlayerOnlyInGroup = true -- New configuration option
}

-- Trinket and racial spell IDs that share cooldown
local TRINKET_SPELLS = {
    [42292] = true,  -- PvP Trinket
    [59752] = true   -- Will to Survive (Human Racial)
}
local TRINKET_ICON = 133452
local TRINKET_COOLDOWN = 120

-- Store frames by unit
TrinketTracker.frames = {}

-- Helper function to check if player is in a group
local function IsInGroup()
    return GetNumGroupMembers() > 0
end

-- Function to create a cooldown frame
local function CreateCooldownFrame(unit, size)
    local frame = CreateFrame("Button", nil, UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100)
    frame:SetSize(size, size)
    frame.unit = unit
    
    -- Create background texture
    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.5)
    frame.background = background
    
    -- Create icon texture with explicit alpha settings
    local icon = frame:CreateTexture(nil, "BORDER")
    icon:SetAllPoints()
    icon:SetTexture(TRINKET_ICON)
    icon:SetDesaturated(false)
    icon:SetAlpha(1)
    icon:SetVertexColor(1, 1, 1, 1)
    frame.icon = icon
    
    -- Create normal texture with explicit settings
    local normalTexture = frame:CreateTexture(nil, "ARTWORK")
    normalTexture:SetAllPoints()
    normalTexture:SetAlpha(1)
    normalTexture:SetVertexColor(1, 1, 1, 1)
    frame:SetNormalTexture(normalTexture)
    frame.normalTexture = normalTexture
    
    -- Create cooldown frame
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetUseCircularEdge(true)
    cooldown:SetDrawBling(true)
    cooldown:SetDrawEdge(true)
    cooldown:SetHideCountdownNumbers(false)
    cooldown:SetSwipeColor(0, 0, 0, 0.8)
    frame.cooldown = cooldown
    
    -- Add a frame method to refresh visual state
    frame.RefreshVisuals = function()
        icon:SetAlpha(1)
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetDesaturated(false)
        normalTexture:SetAlpha(1)
        normalTexture:SetVertexColor(1, 1, 1, 1)
        background:SetAlpha(0.5)
    end
    
    -- Add Masque support with more explicit settings
    if MSQ then
        group:AddButton(frame, {
            Icon = icon,
            Normal = normalTexture,
            Cooldown = cooldown,
            Disabled = false,
            Pushed = false,
            Colors = {
                Normal = {1, 1, 1, 1},
                Disabled = {1, 1, 1, 1}
            }
        })
        
        -- Force update after Masque
        C_Timer.After(0.1, function()
            frame.RefreshVisuals()
        end)
    end
    
    -- Hook SetNormalTexture to maintain alpha
    local oldSetNormalTexture = frame.SetNormalTexture
    frame.SetNormalTexture = function(self, tex)
        oldSetNormalTexture(self, tex)
        C_Timer.After(0, function()
            frame.RefreshVisuals()
        end)
    end
    
    return frame
end

-- Function to update position (always use fixed positions)
local function UpdateTrinketPosition(frame)
    if not frame or not frame.unit then return end
    
    -- Hide frame if unit doesn't exist
    if not UnitExists(frame.unit) then
        frame:Hide()
        return
    end
    
    -- Special handling for player frame when showPlayerOnlyInGroup is enabled
    if frame.unit == "player" and TrinketTracker.config.showPlayerOnlyInGroup then
        if not IsInGroup() then
            frame:Hide()
            return
        end
    end
    
    -- Get the configured position for this unit
    local pos = TrinketTracker.config.positions[frame.unit]
    if not pos then
        frame:Hide()
        return
    end
    
    -- Always use fixed position
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    frame:Show()
    frame.RefreshVisuals()
end

-- Update all frame positions
function TrinketTracker:UpdateAllPositions()
    for _, frame in pairs(self.frames) do
        UpdateTrinketPosition(frame)
    end
end

-- Handle combat log events
local function HandleCombatLog()
    local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, 
          sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, 
          spellID, spellName = CombatLogGetCurrentEventInfo()
    
    -- Check for trinket use
    if eventType == "SPELL_CAST_SUCCESS" and TRINKET_SPELLS[spellID] then
        -- Only check units that actually exist
        local units = {"player"}
        if UnitExists("party1") then table.insert(units, "party1") end
        if UnitExists("party2") then table.insert(units, "party2") end
        
        for _, unit in ipairs(units) do
            if sourceGUID == UnitGUID(unit) or sourceName == UnitName(unit) then
                local frame = TrinketTracker.frames[unit]
                if frame and frame.cooldown then
                    -- Set cooldown and ensure frame is visible
                    frame.cooldown:SetCooldown(GetTime(), TRINKET_COOLDOWN)
                    UpdateTrinketPosition(frame)
                end
                break
            end
        end
    end
end

-- Initialize the trinket tracker
function TrinketTracker:Initialize()
    -- Initialize Masque group
    if MSQ then
        group = MSQ:Group("TrinketTracker", "PvP Trinkets")
        group.SkinChanged = function()
            C_Timer.After(0.1, function()
                for _, frame in pairs(TrinketTracker.frames) do
                    if frame.RefreshVisuals then
                        frame.RefreshVisuals()
                    end
                end
            end)
        end
    end
    
    -- Create frames for player and first 2 party members only
    self.frames["player"] = CreateCooldownFrame("player", self.config.size)
    self.frames["party1"] = CreateCooldownFrame("party1", self.config.size)
    self.frames["party2"] = CreateCooldownFrame("party2", self.config.size)
    
    -- Initially hide all frames
    for _, frame in pairs(self.frames) do
        frame:Hide()
    end
    
    -- Update positions initially
    self:UpdateAllPositions()
    
    -- Register events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HandleCombatLog()
        elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
            -- Update positions when group composition changes
            C_Timer.After(0.5, function()
                TrinketTracker:UpdateAllPositions()
            end)
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Refresh all frames when exiting combat
            C_Timer.After(0.1, function()
                TrinketTracker:UpdateAllPositions()
            end)
        end
    end)
    
    -- Add a command for testing and configuration
    SLASH_TRINKETTRACKER1 = "/tt"
    SlashCmdList["TRINKETTRACKER"] = function(msg)
        if msg == "test" then
            -- Test cooldowns only on existing units
            local units = {"player"}
            if UnitExists("party1") then table.insert(units, "party1") end
            if UnitExists("party2") then table.insert(units, "party2") end
            
            for _, unit in ipairs(units) do
                local frame = TrinketTracker.frames[unit]
                if frame and frame.cooldown then
                    print("Testing trinket for " .. unit)
                    frame.cooldown:SetCooldown(GetTime(), TRINKET_COOLDOWN)
                    UpdateTrinketPosition(frame)
                end
            end
        elseif msg == "config" then
            -- Print current configuration
            print("TrinketTracker Config:")
            print("Size:", TrinketTracker.config.size)
            print("Show player only in group:", TrinketTracker.config.showPlayerOnlyInGroup)
            
            -- Print positions
            for unit, pos in pairs(TrinketTracker.config.positions) do
                print(unit .. " position: X=" .. pos.x .. ", Y=" .. pos.y)
            end
        elseif msg:match("^size (%d+)$") then
            -- Set size
            local newSize = tonumber(msg:match("^size (%d+)$"))
            TrinketTracker.config.size = newSize
            print("Set trinket icon size to", newSize)
            
            -- Update all frames with new size
            for unit, frame in pairs(TrinketTracker.frames) do
                frame:SetSize(newSize, newSize)
                frame.icon:SetAllPoints()
                frame.background:SetAllPoints()
                frame.normalTexture:SetAllPoints()
                frame.cooldown:SetAllPoints()
            end
        elseif msg:match("^pos (%w+) ([%-%d]+) ([%-%d]+)$") then
            -- Set position for a unit
            local unit, x, y = msg:match("^pos (%w+) ([%-%d]+) ([%-%d]+)$")
            x = tonumber(x)
            y = tonumber(y)
            
            if TrinketTracker.frames[unit] and x and y then
                TrinketTracker.config.positions[unit] = { x = x, y = y }
                print("Set " .. unit .. " position to X=" .. x .. ", Y=" .. y)
                UpdateTrinketPosition(TrinketTracker.frames[unit])
            else
                print("Usage: /tt pos [player|party1|party2] X Y")
            end
        elseif msg == "toggleplayergroup" then
            -- Toggle player in group only setting
            TrinketTracker.config.showPlayerOnlyInGroup = not TrinketTracker.config.showPlayerOnlyInGroup
            print("Show player trinket only in group:", TrinketTracker.config.showPlayerOnlyInGroup)
            TrinketTracker:UpdateAllPositions()
        end
    end
end

-- Initialize on PLAYER_LOGIN
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        TrinketTracker:Initialize()
    end
end)