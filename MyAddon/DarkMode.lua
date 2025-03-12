-- DarkMode.lua
-- A standalone module for darkening specific WoW UI frame textures

local addonName, addon = ...
local DarkMode = {}

-- Configuration
DarkMode.enabled = true
DarkMode.darkenAmount = 0.35 -- 0.0 is no darkening, 1.0 is complete black

-- Specific texture names we want to target
DarkMode.targetTextures = {
    -- Player frame textures
    "PlayerFrameTexture",
    
    -- Target frame textures
    "TargetFrameTextureFrameTexture",
    "TargetFrameToTTextureFrameTexture",
    
    -- Focus frame textures
    "FocusFrameTextureFrameTexture",
    "FocusFrameToTTextureFrameTexture"
}

-- Function to darken a texture
function DarkMode:DarkenTexture(texture)
    if not texture then return end
    
    -- Store original colors if not already stored
    if not texture.originalColor then
        local r, g, b = texture:GetVertexColor()
        if not r then r, g, b = 1, 1, 1 end -- Default to white if no color is set
        texture.originalColor = {r = r, g = g, b = b}
    end
    
    -- Apply darkening to original color
    local original = texture.originalColor
    local darkR = original.r * (1 - self.darkenAmount)
    local darkG = original.g * (1 - self.darkenAmount)
    local darkB = original.b * (1 - self.darkenAmount)
    
    -- Set new color
    texture:SetVertexColor(darkR, darkG, darkB)
end

-- Apply dark mode to all target textures
function DarkMode:ApplyDarkMode()
    if not self.enabled then return end
    
    local appliedCount = 0
    for _, textureName in ipairs(self.targetTextures) do
        local texture = _G[textureName]
        if texture then
            self:DarkenTexture(texture)
            appliedCount = appliedCount + 1
        end
    end
    
    -- if appliedCount > 0 then
    --     print(addonName .. ": Applied dark mode to " .. appliedCount .. " textures")
    -- else
    --     print(addonName .. ": No textures found to darken")
    -- end
end

-- Reset textures to original colors
function DarkMode:ResetTextures()
    local resetCount = 0
    for _, textureName in ipairs(self.targetTextures) do
        local texture = _G[textureName]
        if texture and texture.originalColor then
            local original = texture.originalColor
            texture:SetVertexColor(original.r, original.g, original.b)
            resetCount = resetCount + 1
        elseif texture then
            texture:SetVertexColor(1, 1, 1) -- Default reset
            resetCount = resetCount + 1
        end
    end
    
    if resetCount > 0 then
        print(addonName .. ": Reset " .. resetCount .. " textures")
    end
end

-- Toggle dark mode on/off
function DarkMode:Toggle()
    self.enabled = not self.enabled
    if self.enabled then
        self:ApplyDarkMode()
     --   print(addonName .. ": Dark mode enabled")
    else
        self:ResetTextures()
      --  print(addonName .. ": Dark mode disabled")
    end
end

-- Debug function to help find texture names
function DarkMode:DebugFrameTextures(frameName)
    local frame = _G[frameName]
    if not frame then
      --  print(addonName .. ": Frame '" .. frameName .. "' not found")
        return
    end
    
    print("Textures in " .. frameName .. ":")
    
    -- Process direct regions
    local numRegions = frame:GetNumRegions()
    for i = 1, numRegions do
        local region = select(i, frame:GetRegions())
        if region and region:IsObjectType("Texture") and region:GetName() then
            print("  " .. region:GetName())
        end
    end
    
    -- Process child frames
    local numChildren = frame:GetNumChildren()
    for i = 1, numChildren do
        local child = select(i, frame:GetChildren())
        if child:GetName() and (child:IsObjectType("Frame") or child:IsObjectType("Button")) then
            print("Child: " .. child:GetName())
            
            -- Look for textures in this child
            local childRegions = child:GetNumRegions()
            for j = 1, childRegions do
                local region = select(j, child:GetRegions())
                if region and region:IsObjectType("Texture") and region:GetName() then
                    print("    " .. region:GetName())
                end
            end
        end
    end
end

-- Create slash commands for the module
local function SetupSlashCommands()
    SLASH_DARKMODE1 = "/darkmode"
    SLASH_DARKMODE2 = "/dm"
    
    SlashCmdList["DARKMODE"] = function(msg)
        local args = {}
        for arg in string.gmatch(msg, "%S+") do
            table.insert(args, arg)
        end
        
        local command = args[1] and args[1]:lower() or "toggle"
        
        if command == "toggle" then
            DarkMode:Toggle()
        elseif command == "on" then
            DarkMode.enabled = true
            DarkMode:ApplyDarkMode()
          --  print(addonName .. ": Dark mode enabled")
        elseif command == "off" then
            DarkMode.enabled = false
            DarkMode:ResetTextures()
          --  print(addonName .. ": Dark mode disabled")
        elseif command == "amount" and args[2] then
            local amount = tonumber(args[2])
            if amount and amount >= 0 and amount <= 1 then
                DarkMode.darkenAmount = amount
                if DarkMode.enabled then
                    DarkMode:ResetTextures()
                    DarkMode:ApplyDarkMode()
                end
                print(addonName .. ": Dark mode amount set to " .. amount)
            else
                print(addonName .. ": Invalid amount. Please use a number between 0 and 1")
            end
        elseif command == "debug" and args[2] then
            -- Debug command to help find texture names
            DarkMode:DebugFrameTextures(args[2])
        else
            print(addonName .. " Dark Mode commands:")
            print("/dm toggle - Toggle dark mode on/off")
            print("/dm on - Turn dark mode on")
            print("/dm off - Turn dark mode off")
            print("/dm amount [0-1] - Set darkness amount (0 = normal, 1 = black)")
            print("/dm debug [frameName] - List texture names in a frame for debugging")
        end
    end
end

-- Create event frame and register for events
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize once our addon is loaded
        SetupSlashCommands()
       -- print(addonName .. ": Dark Mode module loaded. Use /darkmode or /dm to toggle")
        
        -- Apply dark mode after player enters world if enabled
        if DarkMode.enabled then
            self:RegisterEvent("PLAYER_ENTERING_WORLD")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Apply after a short delay to ensure all frames are properly loaded
        C_Timer.After(0.1, function() 
            if DarkMode.enabled then
                DarkMode:ApplyDarkMode() 
            end
        end)
        -- Only need this once
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif (event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED") then
        -- Apply dark mode if enabled
        if DarkMode.enabled then
            C_Timer.After(0.1, function() 
                DarkMode:ApplyDarkMode()
            end)
        end
    end
end)

-- Save the module to avoid garbage collection
_G[addonName .. "_DarkMode"] = DarkMode

-- No need to return anything, the module is self-initializing