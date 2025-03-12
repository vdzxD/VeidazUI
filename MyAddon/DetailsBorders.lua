local addonName, addon = ...
addon = addon or {}  -- Ensure addon table exists



-- Function to create a border texture
local function CreateBorderTexture(parent, atlasName, x, y, width, height, rotation, isCorner)
    local texture = parent:CreateTexture(nil, "BORDER")
    texture:SetAtlas(atlasName)
    texture:SetSize(width, height)
    texture:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    if rotation and rotation ~= 0 then
        texture:SetRotation(math.rad(rotation))
    end
    
    return texture
end

-- Function to attach borders to a given Details frame
local function AttachBordersToFrame(frameName)
    local detailsFrame = _G[frameName]
    if not detailsFrame then
        return
    end
    
    -- Create a border frame as a child of the Details frame
    local borderFrame = CreateFrame("Frame", frameName .. "BorderFrame", detailsFrame)
    borderFrame:SetAllPoints(detailsFrame)
    borderFrame:SetFrameStrata("DIALOG")
    
    -- Attach border textures
    -- Adjust x, y coordinates if needed for each frame
    borderFrame.cornerBottomRight = CreateBorderTexture(borderFrame, "ForgeBorder-CornerBottomRight", 181.5, -81.2, 20, 20, 0, true)
    borderFrame.cornerTopRight = CreateBorderTexture(borderFrame, "ForgeBorder-CornerBottomRight", 181.5, 5, 20, 20, 90, true)
    borderFrame.cornerTopLeft = CreateBorderTexture(borderFrame, "ForgeBorder-CornerBottomRight", -3, 5, 20, 20, 180, true)
    borderFrame.cornerBottomLeft = CreateBorderTexture(borderFrame, "ForgeBorder-CornerBottomRight", -3, -81.2, 20, 20, 270, true)
    
    borderFrame.borderRight = CreateBorderTexture(borderFrame, "!ForgeBorder-Right", 197.2, -10, 4, 80, 0, false)
    borderFrame.borderTop = CreateBorderTexture(borderFrame, "!ForgeBorder-Right", 96, 90, 5, 175, 90, false)
    borderFrame.borderLeft = CreateBorderTexture(borderFrame, "!ForgeBorder-Right", -2.5, -10, 5, 80, 0, false)
    borderFrame.borderBottom = CreateBorderTexture(borderFrame, "!ForgeBorder-Right", 96, -15, 5, 165, 90, false)
    
end

-- Function to attach borders to both Details frames
local function AttachDetailsFrameBorders()
    AttachBordersToFrame("DetailsBaseFrame1")
    AttachBordersToFrame("DetailsBaseFrame2")
end

-- Addon initialization
local function OnLoad(self, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        -- Use a slight delay to ensure UI is ready
        C_Timer.After(1, AttachDetailsFrameBorders)
    end
end

-- Create event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnLoad)
