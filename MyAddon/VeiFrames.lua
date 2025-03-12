local addonName, addon = ...

addon = addon or {}  -- Ensure addon table exists
local frame = CreateFrame("Frame")

-- Purgeable buffs hook
hooksecurefunc("TargetFrame_UpdateAuras", function(s)
    for i = 1, MAX_TARGET_BUFFS do
        if select(4, UnitAura(s.unit, i)) == 'Magic' and UnitIsEnemy('player', s.unit) then
            _G[s:GetName().."Buff"..(i).."Stealable"]:Show()
        end
    end
end)

-- Function to create a simple rectangular background for player health and mana bars
local function CreateSimplePlayerBackground()
    -- Only create if it doesn't already exist
    if not PlayerFrame.simpleBackground then
        -- Create the background texture
        local bg = PlayerFrame:CreateTexture("PlayerFrameSimpleBackground", "BACKGROUND")
        PlayerFrame.simpleBackground = bg
        
        -- Set texture (you can use a solid color or an existing texture)
        bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        
        -- Position it to cover both health and mana bars
        bg:ClearAllPoints()
        bg:SetPoint("TOPLEFT", PlayerFrame.healthbar, "TOPLEFT", -3, 3)
        bg:SetPoint("BOTTOMRIGHT", PlayerFrame.manabar, "BOTTOMRIGHT", 3, -3)
        
        -- Make sure it's visible
        bg:Show()
        
      --  print(addonName .. ": Created simple player frame background")
    end
end

-- Function to hide all rested state elements
local function HideAllRestElements()
    -- List of all rest-related elements
    local restElements = {
        PlayerRestIcon,
        PlayerRestGlow,
        PlayerStatusGlow,
        PlayerStatusTexture
    }
    
    -- Hide all elements and hook their Show methods
    for _, element in ipairs(restElements) do
        if element then
            -- Hide the element
            element:Hide()
            
            -- Set alpha to 0 as additional measure
            element:SetAlpha(0)
            
            -- Hook its Show method if not already hooked
            if not element.restHookApplied then
                hooksecurefunc(element, "Show", function(self)
                    if not InCombatLockdown() then
                        self:Hide()
                        self:SetAlpha(0)
                    end
                end)
                element.restHookApplied = true
            end
        end
    end
    
    -- Hook the main update function that controls these elements
    if not PlayerFrame.restUpdateHooked then
        hooksecurefunc("PlayerFrame_UpdateStatus", function()
            for _, element in ipairs(restElements) do
                if element and element:IsVisible() then
                    element:Hide()
                    element:SetAlpha(0)
                end
            end
        end)
        PlayerFrame.restUpdateHooked = true
    end
    
 --   print(addonName .. ": All rest elements hidden")
end

-- Function to hide all combat-related elements
local function HideAllCombatElements()
    -- List of combat-related elements
    local combatElements = {
        PlayerAttackIcon,
        PlayerAttackBackground,
        PlayerStatusGlow,
        PlayerStatusTexture,
        TargetFrameFlash,
        FocusFrameFlash
    }
    
    -- Hide all elements and set alpha to 0
    for _, element in ipairs(combatElements) do
        if element then
            -- Hide the element
            element:Hide()
            
            -- Set alpha to 0 as additional measure
            element:SetAlpha(0)
            
            -- Hook its Show method if not already hooked
            if not element.combatHookApplied then
                hooksecurefunc(element, "Show", function(self)
                    if not InCombatLockdown() then
                        self:Hide()
                        self:SetAlpha(0)
                    end
                end)
                element.combatHookApplied = true
            end
        end
    end
    
    -- Create a function that hides everything when any of the elements try to show
    local function OnShowHookScript()
        return function(frame)
            if not InCombatLockdown() then
                PlayerStatusGlow:Hide()
                PlayerStatusTexture:Hide()
                TargetFrameFlash:Hide()
                FocusFrameFlash:Hide()
                PlayerAttackIcon:Hide()
                PlayerAttackBackground:Hide()
            end
        end
    end
    
    -- Hook all the elements with this function
    if not PlayerStatusGlow.globalCombatHook then
        hooksecurefunc(PlayerStatusGlow, "Show", OnShowHookScript())
        PlayerStatusGlow.globalCombatHook = true
        
        hooksecurefunc(TargetFrameFlash, "Show", OnShowHookScript())
        TargetFrameFlash.globalCombatHook = true
        
        hooksecurefunc(FocusFrameFlash, "Show", OnShowHookScript())
        FocusFrameFlash.globalCombatHook = true
    end
    
   -- print(addonName .. ": All combat elements hidden")
end

-- Function to hide all action bars and cast bar
local function HideActionBars()
    GuildInstanceDifficultyHanger:Hide()
    GuildInstanceDifficultyBackground:Hide()
    GuildInstanceDifficultyBorder:Hide()
    GuildInstanceDifficultyEmblem:Hide()
    GuildInstanceDifficultyDarkBackground:Hide()
    GuildInstanceDifficultyText:Hide()
    MainMenuBar:Hide()
    MainMenuBarArtFrame:Hide()
    MainMenuMaxLevelBar0:Hide()
    MainMenuMaxLevelBar1:Hide()
    MainMenuMaxLevelBar2:Hide()
    MainMenuMaxLevelBar3:Hide()
    OverrideActionBar:Hide()
    MultiBarBottomLeft:Hide()
    MultiBarBottomRight:Hide()
    MultiBarRight:Hide()
    MultiBarLeft:Hide()
    StanceBarFrame:Hide()
    PossessBarFrame:Hide()
    PetActionBarFrame:Hide()
    UIWidgetTopCenterContainerFrame:Hide()
    CastingBarFrame:UnregisterAllEvents()
    PlayerStatusTexture:Hide()
    
    -- Hide stance buttons by moving them to a hidden frame
    local hiddenFrame = CreateFrame("Frame")
    hiddenFrame:Hide()
    for i = 1, 10 do
        local buttonName = "StanceButton" .. i
        local button = _G[buttonName]
        if button then
            button:SetParent(hiddenFrame)
        end
    end

    -- Force the hiding of MultiBarLeft and MultiBarRight
    for _, bar in pairs({MultiBarLeft, MultiBarRight}) do
        if bar then
            bar:SetParent(hiddenFrame)
        end
    end
end

-- Function to update target frame texture and hide elements
local function UpdateTargetTexture()
    if TargetFrameTextureFrameTexture then
    --    TargetFrameTextureFrameTexture:SetTexture("Interface\\TARGETINGFRAME\\UI-TargetingFrame-NoLevel")
        TargetFrameTextureFrameTexture:SetTexture("Interface\\Addons\\MyAddon\\Textures\\TargetingFrameNoLevel_Upscaled.blp")
        TargetFrameTextureFrameLevelText:Hide()
        TargetFrameTextureFramePVPIcon:Hide()
    end
end

-- Function to update focus frame texture and hide elements
local function UpdateFocusTexture()
    if FocusFrameTextureFrameTexture then
    --    FocusFrameTextureFrameTexture:SetTexture("Interface\\TARGETINGFRAME\\UI-SmallTargetingFrame-NoMana")
        FocusFrameTextureFrameTexture:SetTexture("Interface\\Addons\\MyAddon\\Textures\\MiniFocusFrame.blp")
        FocusFrameTextureFrameTexture:ClearAllPoints()
        FocusFrameTextureFrameTexture:SetPoint("CENTER", FocusFrame, "CENTER", 39, -17)
        FocusFrameTextureFrameTexture:SetTexCoord(1, 0, 0, 1)  -- Mirrors the texture horizontally
        FocusFrameTextureFrameTexture:ClearAllPoints()
        FocusFrameTextureFrameTexture:SetScale(0.134)
        FocusFrameTextureFrameLeaderIcon:Hide()
        FocusFrameNameBackground:Hide()
        FocusFrameBackground:Hide()
        FocusFrame.name:Hide()
        FocusFrameTextureFrameName:ClearAllPoints()
        FocusFrameTextureFrameName:SetPoint("CENTER", FocusFrameTextureFrame, "CENTER", 50, 20)
        FocusFrame:SetFrameStrata("FULLSCREEN")
        FocusFrameHealthBar:SetWidth(148)
        FocusFrameHealthBar:SetHeight(16)
        FocusFrameHealthBar:ClearAllPoints()
        FocusFrameHealthBar:SetPoint("CENTER", FocusFrameTextureFrame, "CENTER", -35, 15)
        FocusFrameManaBar:ClearAllPoints()
        FocusFrameManaBar:SetWidth(0)
        FocusFrameManaBar:SetPoint("CENTER", FocusFrameTextureFrame, "CENTER", -2, 5)
        FocusFramePortrait:ClearAllPoints()
        FocusFramePortrait:SetScale(1.3)
        FocusFramePortrait:SetPoint("CENTER", FocusFrameTextureFrame, "CENTER", 70, 15)
        FocusFrameTextureFrameTexture:SetPoint("CENTER", FocusFrameTextureFrame, "CENTER", 0, 0)
        FocusFrameTextureFrameLevelText:Hide()
        FocusFrameTextureFramePVPIcon:Hide()
    end
end



local function HideTargetOfTargetDebuffs()
    -- Check if the frame exists first
    if TargetFrameToT and TargetFrameToT.debuffs then
        -- Hide the entire debuff container
        TargetFrameToT.debuffs:Hide()
        
        -- Hook the Show method to ensure it stays hidden
        if not TargetFrameToT.debuffs.hideHookApplied then
            hooksecurefunc(TargetFrameToT.debuffs, "Show", function(self)
                if not InCombatLockdown() then
                    self:Hide()
                end
            end)
            TargetFrameToT.debuffs.hideHookApplied = true
        end
        
        -- For individual debuff icons (if they're created differently)
        for i = 1, MAX_TARGET_DEBUFFS do
            local debuffName = "TargetFrameToTDebuff" .. i
            local debuff = _G[debuffName]
            if debuff then
                debuff:Hide()
                
                -- Hook its Show method if not already hooked
                if not debuff.hideHookApplied then
                    hooksecurefunc(debuff, "Show", function(self)
                        if not InCombatLockdown() then
                            self:Hide()
                        end
                    end)
                    debuff.hideHookApplied = true
                end
            end
        end
    end
end

-- Function to hide Focus Target name
local function HideFocusTargetName()
    -- Check if the frame exists first
    if FocusFrameToT and FocusFrameToT.name then
        -- Hide the name text
        FocusFrameToT.name:Hide()
        
        -- Hook the Show method to ensure it stays hidden
        if not FocusFrameToT.name.hideHookApplied then
            hooksecurefunc(FocusFrameToT.name, "Show", function(self)
                if not InCombatLockdown() then
                    self:Hide()
                end
            end)
            FocusFrameToT.name.hideHookApplied = true
        end
    end
end

-- Function to hide Focus Target debuffs
local function HideFocusTargetDebuffs()
    -- Check if the frame exists first
    if FocusFrameToT and FocusFrameToT.debuffs then
        -- Hide the entire debuff container
        FocusFrameToT.debuffs:Hide()
        
        -- Hook the Show method to ensure it stays hidden
        if not FocusFrameToT.debuffs.hideHookApplied then
            hooksecurefunc(FocusFrameToT.debuffs, "Show", function(self)
                if not InCombatLockdown() then
                    self:Hide()
                end
            end)
            FocusFrameToT.debuffs.hideHookApplied = true
        end
        
        -- For individual debuff icons (if they're created differently)
        for i = 1, MAX_TARGET_DEBUFFS do
            local debuffName = "FocusFrameToTDebuff" .. i
            local debuff = _G[debuffName]
            if debuff then
                debuff:Hide()
                
                -- Hook its Show method if not already hooked
                if not debuff.hideHookApplied then
                    hooksecurefunc(debuff, "Show", function(self)
                        if not InCombatLockdown() then
                            self:Hide()
                        end
                    end)
                    debuff.hideHookApplied = true
                end
            end
        end
    end
end


-- Function to apply the target name background texture to player frame
local function ApplyTargetNameBackgroundToPlayer()
    -- First, make sure the TargetFrameNameBackground exists to reference
    -- We can force its creation if needed
    if not _G["TargetFrameNameBackground"] then
        -- Create a temporary target frame if needed
        local tempFrame = CreateFrame("Frame", "TempTargetFrame", UIParent)
        tempFrame:Hide()
        
        -- This should create the TargetFrameNameBackground texture
        UpdateTargetTexture()
    end
    
    -- Get reference to the target name background
    local targetNameBg = _G["TargetFrameNameBackground"]
    if not targetNameBg then
      --  print(addonName .. ": Error - Cannot find TargetFrameNameBackground")
        return
    end
    
    -- Get texture, size and position information from target
    local texture = targetNameBg:GetTexture() or "Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground"
    local width = targetNameBg:GetWidth() or 119
    local height = targetNameBg:GetHeight() or 14
    
    -- Create the player background texture if needed
    local playerNameBg = _G["PlayerNameBackground"]
    if not playerNameBg then
        playerNameBg = PlayerFrame:CreateTexture("PlayerNameBackground", "ARTWORK")
        _G["PlayerNameBackground"] = playerNameBg
    end
    
    -- Apply the exact same texture and properties
    playerNameBg:SetTexture(texture)
    playerNameBg:SetWidth(width)
    playerNameBg:SetHeight(height)
    
    -- Set the drawing layer to match target
    playerNameBg:SetDrawLayer(targetNameBg:GetDrawLayer())
    
    -- Position it appropriately on the player frame
    playerNameBg:ClearAllPoints()
    
    -- For more precise positioning, you can adjust these values
    playerNameBg:SetPoint("CENTER", PlayerFrame, "CENTER", 50, 17)
    
    -- Set color to friendly green color (same as friendly target frame)
    -- These values match the default friendly unit color
    playerNameBg:SetVertexColor(0, 0, 1)
    
    playerNameBg:Show()
    
   -- print(addonName .. ": Applied target name background texture to player frame (friendly color)")
end

-- Function to update cast bar textures
local function UpdateCastBarTextures()
    -- Player cast bar (if you decide to show it)
    if CastingBarFrame and not CastingBarFrame.textureReplaced then
        CastingBarFrame:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
        CastingBarFrame.textureReplaced = true
    end
    
    -- Target cast bar
    if TargetFrameSpellBar and not TargetFrameSpellBar.textureReplaced then
        TargetFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
        TargetFrameSpellBar.textureReplaced = true
    end
    
    -- Focus cast bar
    if FocusFrameSpellBar and not FocusFrameSpellBar.textureReplaced then
        FocusFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
        FocusFrameSpellBar.textureReplaced = true
    end
end




-- Function to hook into cast bar updates
local function HookCastBars()
    -- Only hook once
    if addon.castBarsHooked then return end
    
    -- For Target Frame Spell Bar
    if TargetFrameSpellBar then
        local originalTargetScript = TargetFrameSpellBar:GetScript("OnEvent")
        TargetFrameSpellBar:SetScript("OnEvent", function(self, event, ...)
            -- Call original script if it exists
            if originalTargetScript then
                originalTargetScript(self, event, ...)
            end
            
            -- Apply our texture
            C_Timer.After(0.05, function()
                if TargetFrameSpellBar:IsVisible() then
                    TargetFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
                end
            end)
        end)
    end
    
    -- For Focus Frame Spell Bar
    if FocusFrameSpellBar then
        local originalFocusScript = FocusFrameSpellBar:GetScript("OnEvent")
        FocusFrameSpellBar:SetScript("OnEvent", function(self, event, ...)
            -- Call original script if it exists
            if originalFocusScript then
                originalFocusScript(self, event, ...)
            end
            
            -- Apply our texture
            C_Timer.After(0.05, function()
                if FocusFrameSpellBar:IsVisible() then
                    FocusFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
                end
            end)
        end)
    end
    
    -- Also hook PLAYER_TARGET_CHANGED and PLAYER_FOCUS_CHANGED events for good measure
    frame:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" and TargetFrameSpellBar then
            C_Timer.After(0.1, function()
                TargetFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
                
                -- Refresh the simple background
                if PlayerFrame.simpleBackground then
                    PlayerFrame.simpleBackground:Show()
                else
                    CreateSimplePlayerBackground()
                end
                
                -- Update player name background
                ApplyTargetNameBackgroundToPlayer()
            end)
        elseif event == "PLAYER_FOCUS_CHANGED" and FocusFrameSpellBar then
            C_Timer.After(0.1, function()
                FocusFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
            end)
        end
    end)
    
    -- Use a repeating timer to ensure textures stay applied
    C_Timer.NewTicker(1, function()
        -- Keep cast bar textures updated
        if TargetFrameSpellBar and TargetFrameSpellBar:IsVisible() then
            TargetFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
        end
        
        if FocusFrameSpellBar and FocusFrameSpellBar:IsVisible() then
            FocusFrameSpellBar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
        end
        
        -- Also make sure rest elements stay hidden
        local restElements = {
            PlayerRestIcon,
            PlayerRestGlow,
            PlayerStatusGlow,
            PlayerStatusTexture
        }
        
        for _, element in ipairs(restElements) do
            if element and element:IsVisible() then
                element:Hide()
                element:SetAlpha(0)
            end
        end
        
        -- Also make sure combat elements stay hidden
        local combatElements = {
            PlayerAttackIcon,
            PlayerAttackBackground,
            PlayerStatusGlow,
            PlayerStatusTexture,
            TargetFrameFlash,
            FocusFrameFlash
        }
        
        for _, element in ipairs(combatElements) do
            if element and element:IsVisible() then
                element:Hide()
                element:SetAlpha(0)
            end
        end
    end)
    
    addon.castBarsHooked = true
end

-- Function to modify default unit frames
-- Function to modify default unit frames
local function ModifyUnitFrames()
    -- Hide unwanted UI elements
    UIErrorsFrame:Hide()
    
    -- Hide all rest state elements
    HideAllRestElements()
    
    -- Hide all combat elements
    HideAllCombatElements()

    -- Player Frame adjustments
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetScale(1.085)
    PlayerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 136, -120)
    PlayerPVPIcon:Hide()
    PlayerLevelText:Hide()
   -- PlayerFrameTexture:SetTexture("Interface\\TARGETINGFRAME\\UI-TargetingFrame-NoLevel")
   PlayerFrameTexture:SetTexture("Interface\\Addons\\MyAddon\\Textures\\TargetingFrameNoLevel_Upscaled.blp") --USING NEW UPSCALED TEXTURE 
    
    -- Hide the specific UI elements you want to hide
    if PlayerFrameGroupIndicatorMiddle then
        PlayerFrameGroupIndicatorMiddle:Hide()
    end
    
    if PlayerFrameGroupIndicatorText then
        PlayerFrameGroupIndicatorText:Hide()
    end
    
    PlayerFrame.healthbar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    PlayerFrame.manabar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    
    -- Create simple player frame background
    CreateSimplePlayerBackground()
    
    -- Apply target name background texture to player frame
    ApplyTargetNameBackgroundToPlayer()
    
    -- Hide action bar textures and other elements
    MainMenuBarTexture1:Hide()
    MainMenuBarTexture0:Hide()
    MainMenuBarLeftEndCap:Hide()
    MainMenuBarRightEndCap:Hide()
    ReputationWatchBar:Hide()
    MainMenuBarTexture2:Hide()
    ActionBarUpButton:Hide()
    ActionBarDownButton:Hide()
    MainMenuBarTexture3:Hide()
    CharacterBag3Slot:Hide()
    CharacterBag2Slot:Hide()
    CharacterBag1Slot:Hide()
    CharacterBag0Slot:Hide()
    MainMenuBarBackpackButton:Hide()
    MainMenuBarTextureExtender:Hide()
    MainMenuBarPageNumber:Hide()
    
    -- Minimap adjustments
    MinimapBorderTop:Hide()
    MinimapZoneText:Hide()
    GameTimeFrame:Hide()
    -- if Minimap:IsShown() then
    --     ToggleMinimap()
    -- end
    
    -- Target Frame adjustments
    TargetFrame:ClearAllPoints()
    TargetFrame:SetScale(1.102)
    TargetFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 377, -118)
    TargetFrame.healthbar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    TargetFrame.manabar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")

    
    -- Target of Target adjustments
    TargetFrameToT:ClearAllPoints()
    TargetFrameToT:SetScale(0.75)
    TargetFrameToT:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 146, -89)
    TargetFrameToT.healthbar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    TargetFrameToT.manabar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    TargetFrameToT.name:Hide()
    HideTargetOfTargetDebuffs()
    
    -- Pet Frame adjustments
    PetFrame:ClearAllPoints()
    PetFrame:SetScale(0.75)
    PetFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 120, -195)
    PetFrame.name:Hide()
    PetFrame.healthbar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    PetFrame.manabar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    
    -- Focus Frame adjustments
    FocusFrame:ClearAllPoints()
    FocusFrame:SetScale(0.7)
    FocusFrame:SetPoint("CENTER", UIParent, "CENTER", -325, -200)
    FocusFrame.healthbar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    FocusFrame.manabar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    
    -- Focus Target Frame adjustments
    FocusFrameToT.name:Hide()
    FocusFrameToT:ClearAllPoints()
    FocusFrameToT:SetScale(0.75)
    FocusFrameToT:SetPoint("TOPLEFT", FocusFrame, "TOPLEFT", 139, -5000) -- moved off-screen
    FocusFrameToT.healthbar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    FocusFrameToT.manabar:SetStatusBarTexture("Interface\\AddOns\\MyAddon\\Textures\\Smoothv2.tga")
    HideFocusTargetDebuffs()
    HideFocusTargetName()

end

-- Main event handler
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_HEALTH_FREQUENT")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("PLAYER_UPDATE_RESTING") -- For rest state changes
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
frame:RegisterEvent("UNIT_AURA") -- For aura changes (buffs/debuffs)

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        ModifyUnitFrames()
        HideActionBars()
        UpdateCastBarTextures()
        HookCastBars()
        
        -- Give a little time for the target frame texture to be fully initialized
        C_Timer.After(0.1, function()
            -- Apply the target background texture to player frame
            ApplyTargetNameBackgroundToPlayer()
            
            -- Make sure rest elements are hidden
            HideAllRestElements()
            
            -- Make sure combat elements are hidden
            HideAllCombatElements()
            
            -- Make sure ToT and Focus Target elements stay hidden
            HideTargetOfTargetDebuffs()
            HideFocusTargetName()
            HideFocusTargetDebuffs()
        end)
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateTargetTexture()
        UpdateCastBarTextures()
        
        -- Hide PVP icons and group indicators
        if PlayerPVPIcon then PlayerPVPIcon:Hide() end
        if PlayerFrameGroupIndicator then PlayerFrameGroupIndicator:Hide() end
        if PlayerFrameGroupIndicatorMiddle then PlayerFrameGroupIndicatorMiddle:Hide() end
        if PlayerFrameGroupIndicatorText then PlayerFrameGroupIndicatorText:Hide() end
        
        -- Hide target frame level text
        if TargetFrameTextureFrameLevelText then
            TargetFrameTextureFrameLevelText:Hide()
        end
        
        -- Refresh the player backgrounds when target changes
        C_Timer.After(0.1, function()
            -- Refresh the simple background
            if PlayerFrame.simpleBackground then
                PlayerFrame.simpleBackground:Show()
            else
                CreateSimplePlayerBackground()
            end
            
            -- Update player name background
            ApplyTargetNameBackgroundToPlayer()
            
            -- Make sure ToT elements stay hidden when target changes
            if TargetFrameToT and TargetFrameToT:IsVisible() then
                TargetFrameToT.name:Hide()
                HideTargetOfTargetDebuffs()
            end
        end)
    elseif event == "PLAYER_FOCUS_CHANGED" then
        UpdateFocusTexture()
        UpdateCastBarTextures()
        
        -- Hide focus frame level text
        if FocusFrameTextureFrameLevelText then
            FocusFrameTextureFrameLevelText:Hide()
        end
        
        -- Make sure Focus Target elements stay hidden when focus changes
        C_Timer.After(0.1, function()
            if FocusFrameToT and FocusFrameToT:IsVisible() then
                FocusFrameToT.name:Hide()
                HideFocusTargetDebuffs()
            end
        end)
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Reapply textures when joining/leaving a group
        UpdateTargetTexture()
        UpdateFocusTexture()
        
        -- Hide group indicators when group status changes
        if PlayerFrameGroupIndicator then PlayerFrameGroupIndicator:Hide() end
        if PlayerFrameGroupIndicatorMiddle then PlayerFrameGroupIndicatorMiddle:Hide() end
        if PlayerFrameGroupIndicatorText then PlayerFrameGroupIndicatorText:Hide() end
    elseif event == "PLAYER_UPDATE_RESTING" then
        -- Make sure rest elements are hidden when resting state changes
        HideAllRestElements()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        -- Hide combat elements when combat state changes
        HideAllCombatElements()
    elseif event == "UNIT_AURA" then
        -- When auras change, make sure debuffs stay hidden for ToT and Focus Target
        if arg1 == "targettarget" then
            HideTargetOfTargetDebuffs()
        elseif arg1 == "focustarget" then
            HideFocusTargetDebuffs()
        end
    end
end)