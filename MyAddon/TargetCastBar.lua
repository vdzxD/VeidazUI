-- Cast Bar Module for MyTargetAuraGrid
-- This should be in a separate file, e.g., CastBar.lua

-- Create a global table that will be accessed by the main addon
CastBarModule = {}

-- Function to initialize the cast bar system with the parent addon's settings
function CastBarModule:Initialize(parentAddon)
    -- Store reference to main addon table
    self.parent = parentAddon
    
    -- Create cast bars table
    self.castBars = {}
    
    -- Get settings from parent addon
    local settings = {
        horizontalGap = parentAddon.horizontalGap or 2,
        verticalGap = parentAddon.verticalGap or 8,
        maxAurasPerRow = parentAddon.maxAurasPerRow or 5,
        extraGroupGap = parentAddon.extraGroupGap or 2,
        buffsOnTop = parentAddon.buffsOnTop or true,
        targetAuraSize = parentAddon.targetAuraSize or 20,
        focusAuraSize = parentAddon.focusAuraSize or 28,
        targetGroupOffsetX = parentAddon.targetGroupOffsetX or 4,
        targetGroupOffsetY = parentAddon.targetGroupOffsetY or 32,
        focusGroupOffsetX = parentAddon.focusGroupOffsetX or 4,
        focusGroupOffsetY = parentAddon.focusGroupOffsetY or 45
    }
    
    -- Store settings locally
    self.settings = settings
    
    -- Cast Bar Configuration
    self.config = {
        target = {
            width = 140,         -- Width of the target cast bar
            height = 12,         -- Height of the target cast bar
            offsetX = 28,        -- Horizontal offset from the parent frame
            offsetY = -55,       -- Vertical offset from the parent frame (position below the aura grid)
            texture = "Interface\\Addons\\MyAddon\\Textures\\Smoothv2.tga", -- Bar texture
            font = "Fonts\\FRIZQT__.TTF",                     -- Text font
            fontSize = 10,                                     -- Text size
            fontFlags = "OUTLINE",                             -- Text outline
            borderColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}, -- Default white at full opacity
            borderWidthRatio = 1.055,   -- Border width as a ratio of the cast bar width
            borderHeightRatio = 2.0,  -- Border height as a ratio of the cast bar height
            spark = "Interface\\CastingBar\\UI-CastingBar-Spark", -- Spark texture
           -- shield = "Interface\\CastingBar\\UI-CastingBar-Small-Shield", -- Shield icon for uninterruptible casts
            iconSizeRatio = 1.4,      -- Icon size as a ratio of the cast bar height
           -- iconBorder = "Interface\\Buttons\\UI-ActionButton-Border", -- Icon border texture
            iconBorderSizeRatio = 2.5,  -- Icon border size as a ratio of the cast bar height
            iconXOffset = -5,         -- Horizontal offset for the icon from the cast bar
            iconYOffset = 1,          -- Vertical offset for the icon from the cast bar
            iconTexCoord = {0.07, 0.93, 0.07, 0.93}, -- Texture coordinates for cropping the icon
            showTimer = false,        -- Whether to show the cast time timer
            fadeTime = 0.05,           -- Fade out animation duration in seconds
        },
        focus = {
            width = 170,         -- Width of the target cast bar
            height = 16,         -- Height of the target cast bar
            offsetX = 40,        -- Horizontal offset from the parent frame
            offsetY = -80,       -- Vertical offset from the parent frame (position below the aura grid)
            texture = "Interface\\Addons\\MyAddon\\Textures\\Smoothv2.tga", -- Bar texture
            font = "Fonts\\FRIZQT__.TTF",                     -- Text font
            fontSize = 12,                                     -- Text size
            fontFlags = "OUTLINE",                             -- Text outline
            borderColor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}, -- Default white at full opacity
            borderWidthRatio = 1.1,   -- Border width as a ratio of the cast bar width
            borderHeightRatio = 2.0,  -- Border height as a ratio of the cast bar height
            spark = "Interface\\CastingBar\\UI-CastingBar-Spark", -- Spark texture
         --   shield = "Interface\\CastingBar\\UI-CastingBar-Small-Shield", -- Shield icon for uninterruptible casts
            iconSizeRatio = 1.4,      -- Icon size as a ratio of the cast bar height
          --  iconBorder = "Interface\\Buttons\\UI-ActionButton-Border", -- Icon border texture
            iconBorderSizeRatio = 2.5,  -- Icon border size as a ratio of the cast bar height
            iconXOffset = -10,         -- Horizontal offset for the icon from the cast bar
            iconYOffset = 1,          -- Vertical offset for the icon from the cast bar
            iconTexCoord = {0.07, 0.93, 0.07, 0.93}, -- Texture coordinates for cropping the icon
            showTimer = false,        -- Whether to show the cast time timer
            fadeTime = 0.05,           -- Fade out animation duration in seconds
        }
    }
    
    -- Create the event frame
    self:CreateEventFrame()
    
    -- Create initial cast bars
    self:CreateCastBar("target")
    self:CreateCastBar("focus")
    
    -- Hide default Blizzard cast bars
    if TargetFrameSpellBar then
        TargetFrameSpellBar:UnregisterAllEvents()
        TargetFrameSpellBar:Hide()
    end
    
    if FocusFrameSpellBar then
        FocusFrameSpellBar:UnregisterAllEvents()
        FocusFrameSpellBar:Hide()
    end
    
    -- Return reference to self for chaining
    return self
end

function CastBarModule:CreateCastBar(unit)
    local config = self.config[unit]
    if not config then return end
    
    local parentFrame = (unit == "target") and TargetFrame or FocusFrame
    
    -- Create the main cast bar frame
    local castBar = CreateFrame("StatusBar", "MyTargetAuraGrid"..unit.."CastBar", parentFrame)
    castBar:SetSize(config.width, config.height)
    castBar:SetStatusBarTexture(config.texture)
    castBar:SetStatusBarColor(1.0, 0.7, 0.0)
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    
    -- Store config reference in the cast bar for easier access
    castBar.config = config
    
    -- Position the cast bar based on the aura grid
    local baseOffsetY = config.offsetY
    if unit == "target" then
        baseOffsetY = baseOffsetY + self.settings.targetGroupOffsetY
    else
        baseOffsetY = baseOffsetY + self.settings.focusGroupOffsetY
    end
    
    castBar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", config.offsetX, -baseOffsetY)
    
    -- Create a background
    castBar.background = castBar:CreateTexture(nil, "BACKGROUND")
    castBar.background:SetAllPoints(castBar)
    castBar.background:SetTexture(config.texture)
    castBar.background:SetVertexColor(0, 0, 0, 0.2)
    
    -- Create atlas border instead of the old border texture
    castBar.border = castBar:CreateTexture(nil, "OVERLAY")
    castBar.border:SetAtlas("Legionfall_BarFrame")
    
    -- Set proper size for the atlas frame
    local borderWidth = config.width * config.borderWidthRatio
    local borderHeight = config.height * config.borderHeightRatio
    
    castBar.border:SetSize(borderWidth, borderHeight)
    castBar.border:SetPoint("CENTER", castBar, "CENTER", 0, 0)
    
    -- Apply the border color from config
    castBar.border:SetVertexColor(
        config.borderColor.r,
        config.borderColor.g,
        config.borderColor.b,
        config.borderColor.a
    )
    
    -- Create a spark (the moving part at the end of the cast bar)
    castBar.spark = castBar:CreateTexture(nil, "OVERLAY")
    castBar.spark:SetTexture(config.spark)
    castBar.spark:SetSize(20, config.height * 2)
    castBar.spark:SetBlendMode("ADD")
    
    -- Create text for the spell name
    castBar.text = castBar:CreateFontString(nil, "OVERLAY")
    castBar.text:SetFont(config.font, config.fontSize, config.fontFlags)
    castBar.text:SetPoint("CENTER", castBar, "CENTER", 0, 0)
    castBar.text:SetTextColor(1, 1, 1)
    
    -- Create text for the cast time (only if enabled in config)
    if config.showTimer then
        castBar.timer = castBar:CreateFontString(nil, "OVERLAY")
        castBar.timer:SetFont(config.font, config.fontSize, config.fontFlags)
        castBar.timer:SetPoint("RIGHT", castBar, "RIGHT", -5, 0)
        castBar.timer:SetTextColor(1, 1, 1)
    end
    
    -- Create a shield icon for non-interruptible casts
    castBar.shield = castBar:CreateTexture(nil, "OVERLAY")
    castBar.shield:SetTexture(config.shield)
    castBar.shield:SetSize(config.height * 2, config.height * 2)
    castBar.shield:SetPoint("CENTER", castBar.border, "CENTER", -config.width/2, 0)
    castBar.shield:Hide()
    
    -- Create an icon using configurable size ratio
    local iconSize = config.height * config.iconSizeRatio
    castBar.icon = castBar:CreateTexture(nil, "ARTWORK")
    castBar.icon:SetSize(iconSize, iconSize)
    castBar.icon:SetPoint("RIGHT", castBar, "LEFT", config.iconXOffset, config.iconYOffset)
    
    -- Use texture coordinates from config
    local iconTexCoord = config.iconTexCoord
    castBar.icon:SetTexCoord(iconTexCoord[1], iconTexCoord[2], iconTexCoord[3], iconTexCoord[4])
    
    -- Create an icon border using configurable size ratio
    local iconBorderSize = config.height * config.iconBorderSizeRatio
    castBar.iconBorder = castBar:CreateTexture(nil, "OVERLAY")
    castBar.iconBorder:SetTexture(config.iconBorder)
    castBar.iconBorder:SetSize(iconBorderSize, iconBorderSize)
    castBar.iconBorder:SetPoint("CENTER", castBar.icon, "CENTER", 0, 0)
    castBar.iconBorder:SetBlendMode("ADD")
    
    -- Initialize state variables
    castBar.casting = false
    castBar.channeling = false
    castBar.fadeOut = false
    castBar.holdTime = 0
    castBar.unit = unit
    
    -- Set the OnUpdate script
    castBar:SetScript("OnUpdate", function(self, elapsed)
        CastBarModule:OnUpdate(self, elapsed)
    end)
    
    -- Hide initially
    castBar:Hide()
    
    -- Store the cast bar in our table
    self.castBars[unit] = castBar
    
    return castBar
end

function CastBarModule:OnUpdate(castBar, elapsed)
    if castBar.casting then
        local status = GetTime()
        if status > castBar.maxValue then
            -- Cast finished
            castBar:SetValue(1)
            castBar.casting = false
            castBar.fadeOut = true
            castBar.holdTime = 0
        else
            -- Update the cast bar value
            local progress = (status - castBar.startTime) / (castBar.maxValue - castBar.startTime)
            castBar:SetValue(progress)
            
            -- Update the spark position
            local sparkPosition = progress * castBar:GetWidth()
            castBar.spark:SetPoint("CENTER", castBar, "LEFT", sparkPosition, 0)
            
            -- Update the timer (if enabled)
            if castBar.timer and castBar.config.showTimer then
                castBar.timer:SetText(format("%.1f", castBar.maxValue - status))
            end
        end
    elseif castBar.channeling then
        local status = GetTime()
        if status > castBar.endTime then
            -- Channel finished
            castBar:SetValue(0)
            castBar.channeling = false
            castBar.fadeOut = true
            castBar.holdTime = 0
        else
            -- Update the cast bar value
            local progress = (castBar.endTime - status) / (castBar.endTime - castBar.startTime)
            castBar:SetValue(progress)
            
            -- Update the spark position
            local sparkPosition = progress * castBar:GetWidth()
            castBar.spark:SetPoint("CENTER", castBar, "LEFT", sparkPosition, 0)
            
            -- Update the timer (if enabled)
            if castBar.timer and castBar.config.showTimer then
                castBar.timer:SetText(format("%.1f", castBar.endTime - status))
            end
        end
    elseif castBar.fadeOut then
        castBar.holdTime = castBar.holdTime + elapsed
        -- Use fadeTime from the config
        local fadeTime = castBar.config.fadeTime or 0.2
        local alpha = 1 - (castBar.holdTime / fadeTime)
        if alpha > 0 then
            castBar:SetAlpha(alpha)
        else
            castBar.fadeOut = false
            castBar:Hide()
            castBar:SetAlpha(1)
        end
    end
end

function CastBarModule:CastBar_Start(castBar, spellName, icon, notInterruptible, spellId)
    if not castBar then return end
    
    -- Set the spell name
    castBar.text:SetText(spellName)
    
    -- Fix for spell icon
    -- Try multiple ways to get a valid texture
    local iconTexture = icon
    
    -- If the icon is empty or results in a green square, try getting it from spell info
    if not iconTexture or iconTexture == "" then
        local spell, _, _, altIcon = GetSpellInfo(spellId or spellName)
        if altIcon then
            iconTexture = altIcon
        end
    end
    
    -- If we still don't have a valid icon, use a generic spell icon instead of a green square
    if not iconTexture or iconTexture == "" then
        iconTexture = "Interface\\Icons\\Spell_Nature_Lightning"  -- Generic spell icon
    end
    
    castBar.icon:SetTexture(iconTexture)
    
    -- Set up the bar for a cast
    castBar:SetAlpha(1)
    castBar:SetMinMaxValues(0, 1)
    castBar:SetValue(0)
    castBar.spark:Show()
    
    -- Handle non-interruptible casts
    if notInterruptible then
        castBar.shield:Show()
        castBar:SetStatusBarColor(0.7, 0.7, 0.7)
        -- Set border to grey for non-interruptible casts
        castBar.border:SetVertexColor(0.7, 0.7, 0.7, 1.0)
    else
        castBar.shield:Hide()
        castBar:SetStatusBarColor(1.0, 0.7, 0.0)
        -- Reset border to config color for normal casts
        castBar.border:SetVertexColor(
            castBar.config.borderColor.r,
            castBar.config.borderColor.g,
            castBar.config.borderColor.b,
            castBar.config.borderColor.a
        )
    end
    
    castBar:Show()
end

function CastBarModule:UpdateCastBar(castBar, unit)
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
    
    if name then
        castBar.casting = true
        castBar.channeling = false
        castBar.fadeOut = false
        
        -- Set timing information
        castBar.startTime = startTime / 1000
        castBar.maxValue = endTime / 1000
        
        -- Start the cast bar animation
        self:CastBar_Start(castBar, text, texture, notInterruptible, spellID)
        return true
    end
    
    name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
    
    if name then
        castBar.casting = false
        castBar.channeling = true
        castBar.fadeOut = false
        
        -- Set timing information
        castBar.startTime = startTime / 1000
        castBar.endTime = endTime / 1000
        
        -- Set min/max values for a channel (reverse of a cast)
        castBar:SetMinMaxValues(0, castBar.endTime - castBar.startTime)
        castBar:SetValue(castBar.endTime - GetTime())
        
        -- Start the cast bar animation
        self:CastBar_Start(castBar, text, texture, notInterruptible, spellID)
        return true
    end
    
    -- No casting or channeling
    if castBar.casting or castBar.channeling then
        -- If we were casting, fade out
        castBar.casting = false
        castBar.channeling = false
        castBar.fadeOut = true
        castBar.holdTime = 0
    end
    
    return false
end

function CastBarModule:CreateEventFrame()
    local eventFrame = CreateFrame("Frame")
    self.eventFrame = eventFrame
    
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:RegisterEvent("UNIT_TARGET")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        CastBarModule:OnEvent(event, ...)
    end)
end

function CastBarModule:OnEvent(event, ...)
    local unit = ...
    
    if event == "PLAYER_ENTERING_WORLD" then
        -- We already created the cast bars during initialization
    elseif event == "PLAYER_TARGET_CHANGED" then
        local castBar = self.castBars.target
        if castBar then
            self:UpdateCastBar(castBar, "target")
        end
    elseif event == "PLAYER_FOCUS_CHANGED" then
        local castBar = self.castBars.focus
        if castBar then
            self:UpdateCastBar(castBar, "focus")
        end
    elseif unit == "target" or unit == "focus" then
        local castBar = self.castBars[unit]
        if castBar then
            self:UpdateCastBar(castBar, unit)
        end
    end
end

-- Function to update the border color
function CastBarModule:SetBorderColor(unit, r, g, b, a)
    local castBar = self.castBars[unit]
    if not castBar or not castBar.border then return end
    
    -- Update the config
    self.config[unit].borderColor.r = r
    self.config[unit].borderColor.g = g
    self.config[unit].borderColor.b = b
    self.config[unit].borderColor.a = a or 1.0
    
    -- Apply the color
    castBar.border:SetVertexColor(r, g, b, a or 1.0)
    
    return true
end

-- Function to update interrupted cast color
function CastBarModule:SetInterruptedCast(unit)
    local castBar = self.castBars[unit]
    if not castBar or not castBar.border then return end
    
    -- Apply red color for interrupted casts
    castBar:SetStatusBarColor(1.0, 0.0, 0.0)
    castBar.border:SetVertexColor(1.0, 0.0, 0.0, 1.0)
    
    -- Make it fade out after a short time
    castBar.casting = false
    castBar.channeling = false
    castBar.fadeOut = true
    castBar.holdTime = 0
    
    return true
end

function CastBarModule:UpdatePosition(unit)
    local castBar = self.castBars[unit]
    if not castBar then return end
    
    local config = self.config[unit]
    local parentFrame = (unit == "target") and TargetFrame or FocusFrame
    
    -- Calculate where the aura grid ends
    local auraSize = (unit == "target") and self.settings.targetAuraSize or self.settings.focusAuraSize
    local visibleBuffs = 0
    local visibleDebuffs = 0
    
    if unit == "target" then
        -- Count visible buffs for target
        for i = 1, 40 do
            local frame = _G["TargetFrameBuff" .. i]
            if frame and frame:IsShown() then
                visibleBuffs = visibleBuffs + 1
            end
        end
        
        -- Count visible debuffs for target
        for i = 1, 40 do
            local frame = _G["TargetFrameDebuff" .. i]
            if frame and frame:IsShown() then
                visibleDebuffs = visibleDebuffs + 1
            end
        end
    else
        -- Count visible buffs for focus
        for i = 1, 40 do
            local frame = _G["FocusFrameBuff" .. i]
            if frame and frame:IsShown() then
                visibleBuffs = visibleBuffs + 1
            end
        end
        
        -- Count visible debuffs for focus
        for i = 1, 40 do
            local frame = _G["FocusFrameDebuff" .. i]
            if frame and frame:IsShown() then
                visibleDebuffs = visibleDebuffs + 1
            end
        end
    end
    
    -- Calculate rows needed for each aura type
    local buffRows = math.ceil(visibleBuffs / self.settings.maxAurasPerRow)
    local debuffRows = math.ceil(visibleDebuffs / self.settings.maxAurasPerRow)
    
    -- Calculate total height used by auras
    local totalAuraHeight = 0
    if self.settings.buffsOnTop then
        if buffRows > 0 then
            totalAuraHeight = totalAuraHeight + (buffRows * (auraSize + self.settings.verticalGap))
        end
        if debuffRows > 0 then
            if buffRows > 0 then
                totalAuraHeight = totalAuraHeight + self.settings.extraGroupGap
            end
            totalAuraHeight = totalAuraHeight + (debuffRows * (auraSize + self.settings.verticalGap))
        end
    else
        if debuffRows > 0 then
            totalAuraHeight = totalAuraHeight + (debuffRows * (auraSize + self.settings.verticalGap))
        end
        if buffRows > 0 then
            if debuffRows > 0 then
                totalAuraHeight = totalAuraHeight + self.settings.extraGroupGap
            end
            totalAuraHeight = totalAuraHeight + (buffRows * (auraSize + self.settings.verticalGap))
        end
    end
    
    -- Only subtract the last vertical gap if there are any auras
    if totalAuraHeight > 0 then
        totalAuraHeight = totalAuraHeight - self.settings.verticalGap
    end
    
    -- Set the cast bar position
    local baseOffsetY
    if unit == "target" then
        baseOffsetY = self.settings.targetGroupOffsetY
    else
        baseOffsetY = self.settings.focusGroupOffsetY
    end
    
    -- Position the cast bar below the aura grid
    castBar:ClearAllPoints()
    castBar:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", config.offsetX, -(baseOffsetY + totalAuraHeight + config.offsetY))
end

-- Return the module
CastBarModule.version = "1.1" -- Updated version number