local addonName, MyAddon = ...


MyAddon.Borders = {}
local Borders = MyAddon.Borders

-- Function to update raid frame textures (both health bars and backgrounds)
local function UpdateRaidFrameTextures()
    for i = 1, 40 do  -- Loop over potential raid frames (adjust if necessary)
        local raidFrame = _G["CompactRaidFrame"..i]
        if raidFrame then
            -- Update health bar texture
            if raidFrame.healthBar then
                raidFrame.healthBar:SetStatusBarTexture("Interface\\Addons\\MyAddon\\Textures\\Smoothv2.tga")
            end

            -- Update background texture and force a dark color tint
            local background = _G["CompactRaidFrame"..i.."Background"]
            if background then
                background:SetTexture("Interface\\Addons\\MyAddon\\Textures\\Smoothv2.tga")
                -- Force it to be almost jet black (adjust values if needed)
                background:SetVertexColor(0, 0, 0, 0.7)
            end
        end
    end
end

-- Register for the PLAYER_ENTERING_WORLD event to apply changes when the UI loads
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateRaidFrameTextures()
    end
end)

-- Hide raid frame names
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    if frame.optionTable == DefaultCompactUnitFrameOptions then
        frame.name:Hide()
    end
end)


