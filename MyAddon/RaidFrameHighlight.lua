local addonName, MyAddon = ...



MyAddon.Borders = {}
local Borders = MyAddon.Borders

-- Border settings with added offset
local HIGHLIGHT_BORDER = {
    TEXTURE = "Interface\\Buttons\\WHITE8X8",
    SIZE = 1.5,
    COLOR = {r = 1, g = 1, b = 1, a = 1},
    OFFSET = {
        x = 0.5,  -- Adjust this value to shift the border horizontally
        y = 0   -- Keep y offset at 0 for now, but available if needed
    }
}

-- Table to store border frames
local borderFrames = {}

-- Function to create border textures
local function CreateBorderTexture(parent, atlas, xOffset, yOffset, width, height, rotation, mirror)
    local texture = parent:CreateTexture(nil, "OVERLAY")
    texture:SetAtlas(atlas)
    texture:SetSize(width, height)
    texture:SetPoint("CENTER", parent, "CENTER", xOffset, yOffset)
    texture:SetRotation(math.rad(rotation))
    if mirror then
        texture:SetTexCoord(1, 0, 0, 1)
    end
    return texture
end

-- Function to create both highlight and decorative borders for a raid frame
local function CreateBorders(raidFrame)
    if not raidFrame or borderFrames[raidFrame] then return end
    
    local borderContainer = {
        highlight = nil,
        decorative = nil
    }
    
    -- Create highlight border with offset
    local highlightBorder = CreateFrame("Frame", nil, UIParent)
    highlightBorder:SetFrameStrata("DIALOG")
    highlightBorder:SetFrameLevel(100)
    
    -- Apply offsets to the border positioning
    highlightBorder:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", 
        -HIGHLIGHT_BORDER.SIZE + HIGHLIGHT_BORDER.OFFSET.x, 
        HIGHLIGHT_BORDER.SIZE + HIGHLIGHT_BORDER.OFFSET.y)
    highlightBorder:SetPoint("BOTTOMRIGHT", raidFrame, "BOTTOMRIGHT", 
        HIGHLIGHT_BORDER.SIZE + HIGHLIGHT_BORDER.OFFSET.x, 
        -HIGHLIGHT_BORDER.SIZE + HIGHLIGHT_BORDER.OFFSET.y)
    
    -- Create highlight border textures
    local top = highlightBorder:CreateTexture(nil, "OVERLAY")
    top:SetTexture(HIGHLIGHT_BORDER.TEXTURE)
    top:SetPoint("TOPLEFT", highlightBorder, "TOPLEFT")
    top:SetPoint("TOPRIGHT", highlightBorder, "TOPRIGHT")
    top:SetHeight(HIGHLIGHT_BORDER.SIZE)
    top:SetVertexColor(HIGHLIGHT_BORDER.COLOR.r, HIGHLIGHT_BORDER.COLOR.g, HIGHLIGHT_BORDER.COLOR.b, HIGHLIGHT_BORDER.COLOR.a)
    
    local bottom = highlightBorder:CreateTexture(nil, "OVERLAY")
    bottom:SetTexture(HIGHLIGHT_BORDER.TEXTURE)
    bottom:SetPoint("BOTTOMLEFT", highlightBorder, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", highlightBorder, "BOTTOMRIGHT")
    bottom:SetHeight(HIGHLIGHT_BORDER.SIZE)
    bottom:SetVertexColor(HIGHLIGHT_BORDER.COLOR.r, HIGHLIGHT_BORDER.COLOR.g, HIGHLIGHT_BORDER.COLOR.b, HIGHLIGHT_BORDER.COLOR.a)
    
    local left = highlightBorder:CreateTexture(nil, "OVERLAY")
    left:SetTexture(HIGHLIGHT_BORDER.TEXTURE)
    left:SetPoint("TOPLEFT", highlightBorder, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", highlightBorder, "BOTTOMLEFT")
    left:SetWidth(HIGHLIGHT_BORDER.SIZE)
    left:SetVertexColor(HIGHLIGHT_BORDER.COLOR.r, HIGHLIGHT_BORDER.COLOR.g, HIGHLIGHT_BORDER.COLOR.b, HIGHLIGHT_BORDER.COLOR.a)
    
    local right = highlightBorder:CreateTexture(nil, "OVERLAY")
    right:SetTexture(HIGHLIGHT_BORDER.TEXTURE)
    right:SetPoint("TOPRIGHT", highlightBorder, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", highlightBorder, "BOTTOMRIGHT")
    right:SetWidth(HIGHLIGHT_BORDER.SIZE)
    right:SetVertexColor(HIGHLIGHT_BORDER.COLOR.r, HIGHLIGHT_BORDER.COLOR.g, HIGHLIGHT_BORDER.COLOR.b, HIGHLIGHT_BORDER.COLOR.a)
    
    highlightBorder:Hide()
    borderContainer.highlight = highlightBorder
    
    -- Create decorative border frame
    local decorativeBorder = CreateFrame("Frame", nil, UIParent)
    decorativeBorder:SetFrameStrata("HIGH")
    decorativeBorder:SetSize(200, 200)
    decorativeBorder:SetAllPoints(raidFrame)
    
    -- Create decorative border textures
    decorativeBorder.cornerBottomRight = CreateBorderTexture(decorativeBorder, "ForgeBorder-CornerBottomRight", -62.5, -23, 20, 20, 0, true)
    decorativeBorder.cornerTopRight    = CreateBorderTexture(decorativeBorder, "ForgeBorder-CornerBottomRight", 63.5, -23, 20, 20, 90, true)
    decorativeBorder.cornerTopLeft     = CreateBorderTexture(decorativeBorder, "ForgeBorder-CornerBottomRight", 63.5, 23, 20, 20, 180, true)
    decorativeBorder.cornerBottomLeft  = CreateBorderTexture(decorativeBorder, "ForgeBorder-CornerBottomRight", -62, 23, 20, 20, 270, true)

    decorativeBorder.borderRight  = CreateBorderTexture(decorativeBorder, "!ForgeBorder-Right", 71, 0, 4.7, 35, 0, false)
    decorativeBorder.borderTop    = CreateBorderTexture(decorativeBorder, "!ForgeBorder-Right", 0, 30.5, 4.7, 110, 90, false)
    decorativeBorder.borderLeft   = CreateBorderTexture(decorativeBorder, "!ForgeBorder-Right", -70, 0, 4.85, 30, 0, true)
    decorativeBorder.borderBottom = CreateBorderTexture(decorativeBorder, "!ForgeBorder-Right", 0, -31, 4.7, 110, 90, true)
    
    borderContainer.decorative = decorativeBorder
    
    borderFrames[raidFrame] = borderContainer
end



-- Function to disable Blizzard's default highlights
local function DisableBlizzardHighlights()
    local frames = {
        CompactRaidFrame1SelectionHighlight,
        CompactRaidFrame2SelectionHighlight,
        CompactRaidFrame3SelectionHighlight
    }
    
    for _, frame in pairs(frames) do
        if frame then
            frame:SetAlpha(0)
        end
    end
end

-- Function to update highlight border visibility
local function UpdateBorderVisibility()
    -- Hide all highlight borders first
    for _, container in pairs(borderFrames) do
        container.highlight:Hide()
    end
    
    -- Show border for current target if it's in raid frames
    if UnitExists("target") then
        for i = 1, 40 do
            local frame = _G["CompactRaidFrame"..i]
            if frame and frame:IsVisible() then
                local unit = frame.unit
                if unit and UnitIsUnit(unit, "target") then
                    if borderFrames[frame] then
                        borderFrames[frame].highlight:Show()
                    end
                end
            end
        end
        
        for i = 1, 8 do
            for j = 1, 5 do
                local frame = _G["CompactRaidGroup"..i.."Member"..j]
                if frame and frame:IsVisible() then
                    local unit = frame.unit
                    if unit and UnitIsUnit(unit, "target") then
                        if borderFrames[frame] then
                            borderFrames[frame].highlight:Show()
                        end
                    end
                end
            end
        end
    end
end

-- Function to handle raid frame updates
local function UpdateRaidFrames()
    if not CompactRaidFrameContainer then return end
    
    -- Create borders for all frames
    for i = 1, 40 do
        local frame = _G["CompactRaidFrame"..i]
        if frame and frame:IsVisible() then
            CreateBorders(frame)
        end
    end
    
    for i = 1, 8 do
        for j = 1, 5 do
            local frame = _G["CompactRaidGroup"..i.."Member"..j]
            if frame and frame:IsVisible() then
                CreateBorders(frame)
            end
        end
    end
    
    UpdateBorderVisibility()
end

-- Initialize
local function Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    
    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_TARGET_CHANGED" then
            UpdateBorderVisibility()
        else
            UpdateRaidFrames()
        end
        DisableBlizzardHighlights()
    end)
    
    -- Ensure highlights stay disabled
    C_Timer.NewTicker(0.1, DisableBlizzardHighlights)
end

Initialize()