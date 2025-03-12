-- Simple Raid Frame Positioner for Cataclysm Classic
-- Just edit the values in the settings table below to customize

local addonName, addon = ...
local RFP = CreateFrame("Frame", "SimpleRaidFramePositioner")

-- ====================================
-- EDIT THESE VALUES TO CUSTOMIZE
-- ====================================
local settings = {
    -- Size of individual raid frames
    width = 145,     -- Default is around 72
    height = 62,     -- Default is around 36
    
    -- Scale of the entire raid frame container
    scale = 1.0,
    
    -- Position of the raid frame container
    position = {
        point = "LEFT",           -- Anchor point on the container
        relativePoint = "LEFT",   -- Anchor point on the screen
        xOffset = 193,            -- X position
        yOffset = -120            -- Y position
    },
    
    -- Buff and Debuff sizes
    buffSize = 20,              -- Size of buffs on raid frames
    debuffSize = 20,            -- Size of debuffs on raid frames
    dispelDebuffSize = 20,      -- Size of dispellable debuffs
    
    -- Adjust the spacing between auras (optional)
    auraSpacing = 2
}
-- ====================================

-- Original Blizzard functions we'll hook
local originalBuffFrameUpdate
local originalDebuffFrameUpdate
local originalDispelDebuffFrameUpdate

-- Register events
RFP:RegisterEvent("PLAYER_ENTERING_WORLD")
RFP:RegisterEvent("GROUP_ROSTER_UPDATE")
RFP:RegisterEvent("ADDON_LOADED")

-- Apply the settings to the raid frames
function RFP:ApplySettings()
    -- Wait for the raid container to exist
    if not CompactRaidFrameContainer then return end
    
    -- Override any saved profile settings
    -- This helps ensure consistent behavior across characters
    if CompactUnitFrameProfiles then
        -- These are the core profile settings that control frame size
        CompactUnitFrameProfiles.selectedProfile = CompactUnitFrameProfiles.selectedProfile or "Primary"
        
        -- Force our size settings into the current profile
        if CompactUnitFrameProfiles.profiles and CompactUnitFrameProfiles.selectedProfile then
            local profile = CompactUnitFrameProfiles.profiles[CompactUnitFrameProfiles.selectedProfile]
            if profile then
                -- These settings help control frame size and will override character defaults
                profile.frameHeight = settings.height
                profile.frameWidth = settings.width
                -- Also set aura-related settings
                profile.buffSize = settings.buffSize
                profile.debuffSize = settings.debuffSize
                profile.auraSpacing = settings.auraSpacing
            end
        end
    end
    
    -- Set position
    CompactRaidFrameContainer:ClearAllPoints()
    CompactRaidFrameContainer:SetPoint(
        settings.position.point,
        UIParent,
        settings.position.relativePoint,
        settings.position.xOffset,
        settings.position.yOffset
    )
    
    -- Set scale
    CompactRaidFrameContainer:SetScale(settings.scale)
    
    -- Set width of container (approximate)
    CompactRaidFrameContainer:SetWidth(settings.width * 5)
    
    -- Apply settings to individual raid frames
    for i = 1, 40 do
        local frameName = "CompactRaidFrame"..i
        local frame = _G[frameName]
        if frame then
            frame:SetWidth(settings.width)
            frame:SetHeight(settings.height)
        end
    end
    
    -- For Cataclysm Classic, we need to be more careful with how we update
    -- Let the game handle the update naturally without forcing it
    
    -- We can use this if it exists
    if CompactRaidFrameManager and CompactRaidFrameManager.UpdateShown then
        CompactRaidFrameManager:UpdateShown()
    end
    
  --  print("|cFF33FF99SimpleRaidFramePositioner:|r Applied custom raid frame settings")
end

-- Setup hooks for Blizzard aura functions
function RFP:SetupHooks()
    -- Only set up hooks once
    if self.hooksInitialized then return end
    
    -- Hook into CompactUnitFrame_UpdateAuras if it exists
    if CompactUnitFrame_UpdateAuras then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
            -- After Blizzard updates auras, apply our size settings
            self:AdjustAuraSizes(frame)
        end)
    end
    
    -- Hook into buff update function if it exists
    if CompactUnitFrame_UpdateBuffs then
        hooksecurefunc("CompactUnitFrame_UpdateBuffs", function(frame)
            -- After Blizzard updates buffs, apply our size settings
            if frame and frame.buffFrames then
                self:AdjustBuffSizes(frame)
            end
        end)
    end
    
    -- Hook into debuff update function if it exists
    if CompactUnitFrame_UpdateDebuffs then
        hooksecurefunc("CompactUnitFrame_UpdateDebuffs", function(frame)
            -- After Blizzard updates debuffs, apply our size settings
            if frame and frame.debuffFrames then
                self:AdjustDebuffSizes(frame)
            end
        end)
    end
    
    -- Hook into dispellable debuff update function if it exists
    if CompactUnitFrame_UpdateDispellableDebuffs then
        hooksecurefunc("CompactUnitFrame_UpdateDispellableDebuffs", function(frame)
            -- After Blizzard updates dispellable debuffs, apply our size settings
            if frame and frame.dispelDebuffFrames then
                self:AdjustDispelDebuffSizes(frame)
            end
        end)
    end
    
    -- self.hooksInitialized = true
    -- print("|cFF33FF99SimpleRaidFramePositioner:|r Hooked into Blizzard aura functions")
end

-- Function to adjust buff sizes
function RFP:AdjustBuffSizes(frame)
    if not frame or not frame.buffFrames then return end
    
    for i = 1, #frame.buffFrames do
        local buff = frame.buffFrames[i]
        if buff then
            buff:SetWidth(settings.buffSize)
            buff:SetHeight(settings.buffSize)
            
            -- Adjust icon size
            local icon = buff.icon
            if icon then
                icon:SetWidth(settings.buffSize - 2)
                icon:SetHeight(settings.buffSize - 2)
            end
        end
    end
end

-- Function to adjust debuff sizes
function RFP:AdjustDebuffSizes(frame)
    if not frame or not frame.debuffFrames then return end
    
    for i = 1, #frame.debuffFrames do
        local debuff = frame.debuffFrames[i]
        if debuff then
            debuff:SetWidth(settings.debuffSize)
            debuff:SetHeight(settings.debuffSize)
            
            -- Adjust icon size
            local icon = debuff.icon
            if icon then
                icon:SetWidth(settings.debuffSize - 2)
                icon:SetHeight(settings.debuffSize - 2)
            end
        end
    end
end

-- Function to adjust dispellable debuff sizes
function RFP:AdjustDispelDebuffSizes(frame)
    if not frame or not frame.dispelDebuffFrames then return end
    
    for i = 1, #frame.dispelDebuffFrames do
        local dispelDebuff = frame.dispelDebuffFrames[i]
        if dispelDebuff then
            dispelDebuff:SetWidth(settings.dispelDebuffSize)
            dispelDebuff:SetHeight(settings.dispelDebuffSize)
            
            -- Adjust icon size
            local icon = dispelDebuff.icon
            if icon then
                icon:SetWidth(settings.dispelDebuffSize - 2)
                icon:SetHeight(settings.dispelDebuffSize - 2)
            end
        end
    end
end

-- Function to adjust all aura sizes for a frame
function RFP:AdjustAuraSizes(frame)
    if not frame then return end
    
    self:AdjustBuffSizes(frame)
    self:AdjustDebuffSizes(frame)
    self:AdjustDispelDebuffSizes(frame)
end

-- Event handler
RFP:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        -- Add a slight delay to ensure frames are created
        C_Timer.After(0.5, function() 
            self:ApplySettings() 
            -- Try to set up hooks when we know frames should exist
            self:SetupHooks()
        end)
    elseif event == "ADDON_LOADED" and arg1 == addonName then
        -- Try to set up hooks when our addon loads
        C_Timer.After(1, function() self:SetupHooks() end)
    end
end)

-- Register for talent update events as they can reset frames
RFP:RegisterEvent("PLAYER_TALENT_UPDATE")

-- Print introduction message when loaded
--print("|cFF33FF99SimpleRaidFramePositioner|r loaded! Edit addon file to customize raid frame size, position, and aura sizes.")