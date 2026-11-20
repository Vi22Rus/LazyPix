-- LazyPix health consumable indicator + movement/target traffic light.
-- Visual-only addon: never uses items or casts spells.
local addon = CreateFrame("Frame")
local db, root, itemButton, itemIcon, shade, circle, circleTexture, settings, healthShadeBar, colorIcon, healthThresholdCurve, curveThreshold
local previewButton, previewTexture, previewLabel
local preview, previewIndex = false, 1
local available = {}
local tick = 0
local assignedItemId = nil
local lastSignal = nil
local forceManualUntil = 0
local movingFromEvents = nil -- authoritative in combat when speed is secret
local lastKnownStanding = true
local lastStanding = true
local movementEvents = 0
local lastHpState = "unknown"
-- WoW 1.60 secret values must never enter Lua arithmetic/comparisons.
local function safeNumber(v)
    if type(issecretvalue) == "function" and issecretvalue(v) then return nil end
    if type(v) == "number" then return v end
    return nil
end
local function safeBool(v)
    if type(issecretvalue) == "function" and issecretvalue(v) then return false end
    return not not v
end
local defaults = { hpThreshold = 10, width = 32, height = 36, diameter = 14, trafficMode = "green" }

-- Healthstones and healing potions available in classic-era WoW.  Ordered by
-- restored health (highest first). Additional ranks can be added by item ID.
local stones = {
    [5512] = 1, [19004] = 2, [19005] = 3, [19006] = 4, [19007] = 5,
    [19008] = 6, [19009] = 7, [19010] = 8, [19011] = 9, [19012] = 10,
    [19013] = 11, [19014] = 12, [19015] = 13, [19016] = 14,
    [22103] = 7, [22104] = 8, [22105] = 9,
}
local potions = {
    [118] = 70, [858] = 140, [929] = 280, [1710] = 455,
    [3928] = 850, [13446] = 1350, [22829] = 1800, [33447] = 2400,
    [43569] = 2400, [43531] = 2400, [40067] = 3600,
    [4596] = 70, -- Discolored Healing Potion
    [18839] = 900, [18841] = 1200,
}
-- IDs are explicit so mana potions and unrelated consumables are never shown.
local function clamp(n, lo, hi)
    n = tonumber(n) or lo
    return math.max(lo, math.min(hi, math.floor(n + 0.5)))
end
local function ensureDB()
    SonahRotationSetupDB = SonahRotationSetupDB or {}
    db = SonahRotationSetupDB
    for k, v in pairs(defaults) do if db[k] == nil then db[k] = v end end
    db.hpThreshold = clamp(db.hpThreshold, 5, 15)
    db.width = clamp(db.width, 16, 36)
    db.height = clamp(db.height, 16, 36)
    db.diameter = clamp(db.diameter, 10, 20)
    if db.trafficMode ~= "green" and db.trafficMode ~= "orange" then db.trafficMode = "green" end
end
local function bagItem(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.itemID, info.iconFileID end
    end
    if GetContainerItemID then
        return GetContainerItemID(bag, slot), nil
    end
end
local function bagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) end
    if GetContainerNumSlots then return GetContainerNumSlots(bag) end
    return 0
end
local function scanBags()
    local found = {}
    for bag = 0, 4 do
        for slot = 1, (bagSlots(bag) or 0) do
            local id, icon = bagItem(bag, slot)
            if id and (stones[id] or potions[id]) and not found[id] then
                found[id] = { id = id, icon = icon or (GetItemIcon and GetItemIcon(id)),
                    rank = stones[id] and (100000 + stones[id]) or potions[id] }
            end
        end
    end
    available = {}
    for _, entry in pairs(found) do available[#available + 1] = entry end
    table.sort(available, function(a, b)
        if a.rank ~= b.rank then return a.rank > b.rank end
        return a.id > b.id
    end)
    if previewIndex > #available then previewIndex = 1 end
end
local function cooldownReady(id)
    -- WoW Forever may protect cooldown timestamps in combat.  The dedicated
    -- spell API exposes an explicitly non-secret isActive flag for items.
    -- Do not perform arithmetic on protected times or assume nil means ready.
    if C_Spell and C_Spell.GetItemCooldown then
        local info = C_Spell.GetItemCooldown(id)
        if info and (not issecretvalue or not issecretvalue(info.isActive))
            and type(info.isActive) == "boolean" then
            local enabled = info.isEnabled
            if (not issecretvalue or not issecretvalue(enabled)) and enabled == false then
                return false, "spell:disabled"
            end
            return not info.isActive, "spell:isActive"
        end
    end
    -- Compatibility fallback for older clients and unavailable spell info.
    local start, duration, enabled
    if C_Container and C_Container.GetItemCooldown then
        start, duration, enabled = C_Container.GetItemCooldown(id)
    elseif GetItemCooldown then
        start, duration, enabled = GetItemCooldown(id)
    end
    start, duration, enabled = safeNumber(start), safeNumber(duration), safeNumber(enabled)
    if enabled == 0 then return false, "container:disabled" end
    if not start or not duration then return false, "cooldown:unknown" end
    return duration <= 0 or (GetTime() >= start + duration), "container:time"
end
local function chosen()
    if #available == 0 then return nil end
    if preview then return available[previewIndex] end
    return available[1]
end
local function targetValid()
    -- Never compare UnitHealth: it can be a protected secret number.
    return safeBool(UnitExists("target"))
        and safeBool(UnitCanAttack("player", "target"))
        and not safeBool(UnitIsDeadOrGhost("target"))
end
local function assignSecureItem(id)
    -- Never mutate secure action attributes during combat.
    if InCombatLockdown() then return end
    if assignedItemId ~= id then
        itemButton:SetAttribute("type1", id and "item" or nil)
        itemButton:SetAttribute("item1", id and ("item:" .. id) or nil)
        assignedItemId = id
    end
end
-- Build a native STEP color curve: secret HP stays inside Blizzard UI APIs.
-- 0..threshold = alpha 1 (bright icon); above threshold = alpha 0 (grey icon).
local function ensureHealthCurve()
    if healthThresholdCurve and curveThreshold == db.hpThreshold then return true end
    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step and CreateColor) then return false end
    local ok, curve = pcall(function()
        local c = C_CurveUtil.CreateColorCurve()
        c:SetType(Enum.LuaCurveType.Step)
        local threshold = db.hpThreshold / 100
        c:AddPoint(0, CreateColor(1, 1, 1, 1))
        c:AddPoint(threshold, CreateColor(1, 1, 1, 1))
        c:AddPoint(math.min(1, threshold + 0.00001), CreateColor(1, 1, 1, 0))
        c:AddPoint(1, CreateColor(1, 1, 1, 0))
        return c
    end)
    if not ok or not curve then return false end
    healthThresholdCurve, curveThreshold = curve, db.hpThreshold
    return true
end
local function updateSecretIcon()
    if not (UnitHealthPercent and ensureHealthCurve()) then return false end
    -- Never inspect, compare, stringify or branch on the returned secret color.
    -- Its alpha is passed directly to a Blizzard Texture API that accepts secrets.
    return pcall(function()
        local color = UnitHealthPercent("player", false, healthThresholdCurve)
        colorIcon:SetAlpha(select(4, color:GetRGBA()))
    end)
end
local function update()
    if not root then return end
    local entry = chosen()
    if previewButton then
        if preview and not InCombatLockdown() then
            previewButton:Show()
            previewTexture:SetTexture(entry and (entry.icon or (GetItemIcon and GetItemIcon(entry.id))) or "Interface\\Icons\\INV_Misc_QuestionMark")
            previewTexture:SetDesaturated(false)
            previewTexture:SetVertexColor(1, 1, 1, 1)
            previewLabel:SetText(#available > 0 and (previewIndex .. "/" .. #available) or "0/0")
        else
            previewButton:Hide()
        end
    end
    -- Freeze the actionable item in combat. Never display a different item
    -- from the one currently assigned to the protected button.
    if InCombatLockdown() then
        entry = nil
        for _, candidate in ipairs(available) do
            if candidate.id == assignedItemId then entry = candidate break end
        end
    end
    if not InCombatLockdown() then assignSecureItem(entry and entry.id or nil) end
    if entry then
        local icon = entry.icon or (GetItemIcon and GetItemIcon(entry.id))
        itemIcon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        itemIcon:Show()
        colorIcon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        colorIcon:Show()
        local rawMax = UnitHealthMax("player")
        local rawCurrent = UnitHealth("player")
        local maxHealth, currentHealth = safeNumber(rawMax), safeNumber(rawCurrent)
        local hp
        if maxHealth and maxHealth > 0 and currentHealth then
            hp = currentHealth * 100 / maxHealth
        end
        local cdReady, cdSource = cooldownReady(entry.id)
        lastHpState = (hp ~= nil and ("readable " .. string.format("%.1f", hp) .. "%") or "secret")
            .. ", item=" .. entry.id .. ", cd=" .. tostring(cdReady) .. " (" .. cdSource .. ")"
        -- The base is ALWAYS grayscale; the color copy is revealed only at
        -- or below the configured threshold. This also works for secret HP.
        itemIcon:SetDesaturated(true)
        itemIcon:SetVertexColor(0.65, 0.65, 0.65, 1)
        shade:SetAlpha(0)
        if healthShadeBar then healthShadeBar:Hide() end
        if hp ~= nil then
            colorIcon:SetAlpha((hp <= db.hpThreshold and cdReady) and 1 or 0)
        elseif cdReady then
            if not updateSecretIcon() then
                -- Fail closed: don't display a false "ready" indication.
                colorIcon:SetAlpha(0)
                lastHpState = lastHpState .. ", curve=unsupported"
            else
                lastHpState = lastHpState .. ", curve=step"
            end
        else
            colorIcon:SetAlpha(0)
        end
    else
        itemIcon:Hide()
        colorIcon:Hide()
        shade:SetAlpha(0)
        if healthShadeBar then healthShadeBar:Hide() end
    end
    -- Reapply the color on EVERY update; never trust a cached texture state.
    -- A manual click holds the requested color briefly so its effect is visible.
    local speed = GetUnitSpeed and safeNumber(GetUnitSpeed("player"))
    local standing
    if movingFromEvents ~= nil then
        standing = not movingFromEvents
    elseif speed ~= nil then
        standing = speed <= 0
        lastKnownStanding = standing
    else
        standing = lastKnownStanding
    end
    lastStanding = standing
    local hostile = targetValid()
    local color = db.trafficMode
    -- Green mode: hostile living target AND player standing still.
    -- Orange mode: hostile living target regardless of movement.
    -- Preserve the 2-second manual preview after clicking the circle.
    if (GetTime() or 0) >= forceManualUntil and hostile then
        if db.trafficMode == "orange" or standing then
            color = "red"
        end
    end
    lastSignal = color
    -- Swap real pre-colored textures instead of relying on vertex tint.
    -- This also ensures the visible image changes on clients with unusual texture handling.
    local texturePath = "Interface\\AddOns\\LazyPix_Addon\\CircleGreen.tga"
    if color == "red" then
        texturePath = "Interface\\AddOns\\LazyPix_Addon\\CircleRed.tga"
    elseif color == "orange" then
        texturePath = "Interface\\AddOns\\LazyPix_Addon\\CircleOrange.tga"
    end
    circleTexture:SetTexture(texturePath)
    circleTexture:SetVertexColor(1, 1, 1, 1)
    circleTexture:SetAlpha(1)
    circleTexture:Show()
end
local function reposition()
    if not root or InCombatLockdown() then return end
    root:SetSize(db.width, db.height)
    itemButton:SetAllPoints(root)
    circle:SetSize(db.diameter, db.diameter)
    circle:ClearAllPoints()
    circle:SetPoint("BOTTOM", root, "TOPLEFT", 0, 2)
    update()
end
local function slider(parent, label, lo, hi, y, key, suffix)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    title:SetText(label)
    local bar = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    bar:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 8, -13)
    bar:SetSize(220, 16)
    bar:SetMinMaxValues(lo, hi)
    bar:SetValueStep(1)
    if bar.SetObeyStepOnDrag then bar:SetObeyStepOnDrag(true) end
    bar:SetValue(db[key])
    local value = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("LEFT", bar, "RIGHT", 14, 0)
    local edit
    if key == "hpThreshold" then
        edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        edit:SetSize(39, 20)
        edit:SetPoint("LEFT", bar, "RIGHT", 12, 0)
        edit:SetAutoFocus(false)
        edit:SetNumeric(true)
        edit:SetMaxLetters(2)
        edit:SetScript("OnEnterPressed", function(self)
            local n = clamp(self:GetNumber(), lo, hi)
            bar:SetValue(n)
            self:ClearFocus()
        end)
        edit:SetScript("OnEscapePressed", function(self) self:SetText(tostring(db[key])); self:ClearFocus() end)
    end
    local function refresh(v)
        local n = clamp(v, lo, hi)
        db[key] = n
        if edit then edit:SetText(tostring(n)) else value:SetText(n .. (suffix or "")) end
        if key ~= "hpThreshold" then reposition() else update() end
    end
    bar:SetScript("OnValueChanged", function(_, v) refresh(v) end)
    refresh(db[key])
end
local function buildSettings()
    settings = CreateFrame("Frame", "LazyPixHealthSettings", UIParent, "BackdropTemplate")
    settings:SetSize(340, 355)
    settings:SetPoint("CENTER")
    settings:SetFrameStrata("DIALOG")
    settings:SetMovable(true)
    settings:EnableMouse(true)
    settings:RegisterForDrag("LeftButton")
    settings:SetScript("OnDragStart", function(self) self:StartMoving() end)
    settings:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    if settings.SetBackdrop then
        settings:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, insets = {left=8,right=8,top=8,bottom=8} })
    end
    local header = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOP", 0, -18)
    header:SetText("LazyPix - Settings / Настройки")
    local close = CreateFrame("Button", nil, settings, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    slider(settings, "1. Use when health is below / Использовать при здоровье ниже", 5, 15, -48, "hpThreshold", "%")
    slider(settings, "2. Frame width / Ширина фрейма", 16, 36, -121, "width", " px")
    slider(settings, "Frame height / Высота фрейма", 16, 36, -193, "height", " px")
    slider(settings, "3. Circle diameter / Диаметр кружка", 10, 20, -265, "diameter", " px")
    settings:Hide()
end
local function build()
    root = CreateFrame("Frame", "LazyPixHealthRoot", UIParent)
    root:SetFrameStrata("HIGH")
    root:SetMovable(true)
    root:SetClampedToScreen(true)
    root:EnableMouse(false)
    root:ClearAllPoints()
    if db.position and db.position.x and db.position.y then
        root:SetPoint("CENTER", UIParent, "CENTER", db.position.x, db.position.y)
    else
        root:SetPoint("CENTER", UIParent, "CENTER", 160, -30)
    end
    itemButton = CreateFrame("Button", "LazyPixHealthItem", root, "SecureActionButtonTemplate")
    itemButton:EnableMouse(true)
    -- Down click is reliable for secure item actions on Classic clients.
    itemButton:RegisterForClicks("LeftButtonDown")
    itemButton:RegisterForDrag("LeftButton")
    itemIcon = itemButton:CreateTexture(nil, "ARTWORK")
    itemIcon:SetAllPoints()
    colorIcon = itemButton:CreateTexture(nil, "ARTWORK", nil, 1)
    colorIcon:SetAllPoints()
    colorIcon:SetAlpha(0)
    shade = itemButton:CreateTexture(nil, "OVERLAY")
    shade:SetAllPoints()
    shade:SetColorTexture(0.28, 0.28, 0.28, 1)
    -- Native UI renders secret health values without inspecting them in Lua.
    healthShadeBar = CreateFrame("StatusBar", nil, itemButton)
    healthShadeBar:SetAllPoints(itemButton)
    healthShadeBar:SetFrameLevel(itemButton:GetFrameLevel() + 2)
    healthShadeBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    healthShadeBar:SetStatusBarColor(0.12, 0.12, 0.12, 0.82)
    healthShadeBar:SetMinMaxValues(0, 100)
    healthShadeBar:SetValue(100)
    healthShadeBar:EnableMouse(false)
    healthShadeBar:Hide()
    itemButton:SetScript("OnDragStart", function()
        if IsShiftKeyDown() and not InCombatLockdown() then root:StartMoving() end
    end)
    itemButton:SetScript("OnDragStop", function()
        if InCombatLockdown() then return end
        root:StopMovingOrSizing()
        local x, y = root:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if x and y and ux and uy then
            db.position = {x = x - ux, y = y - uy}
            root:ClearAllPoints()
            root:SetPoint("CENTER", UIParent, "CENTER", db.position.x, db.position.y)
        end
    end)
    -- Non-secure preview overlay: only visible while Sonah setup is active.
    -- Never attach preview click handlers to the secure consumable button.
    previewButton = CreateFrame("Button", "LazyPixHealthPreview", root)
    previewButton:SetAllPoints(itemButton)
    previewButton:SetFrameLevel(itemButton:GetFrameLevel() + 10)
    previewButton:EnableMouse(true)
    previewButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    previewTexture = previewButton:CreateTexture(nil, "ARTWORK")
    previewTexture:SetAllPoints()
    -- Bright red outline marks setup mode, independently of HP threshold.
    local function edge(pointA, pointB, w, h)
        local t = previewButton:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(1, 0.08, 0.08, 1)
        t:SetPoint(pointA, previewButton, pointA)
        if pointB then t:SetPoint(pointB, previewButton, pointB) end
        if w then t:SetWidth(w) end
        if h then t:SetHeight(h) end
    end
    edge("TOPLEFT", "TOPRIGHT", nil, 3)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 3)
    edge("TOPLEFT", "BOTTOMLEFT", 3, nil)
    edge("TOPRIGHT", "BOTTOMRIGHT", 3, nil)
    previewLabel = previewButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("BOTTOM", previewButton, "BOTTOM", 0, 3)
    previewLabel:SetTextColor(1, 0.15, 0.15, 1)
    previewButton:SetScript("OnClick", function(_, button)
        if not preview or InCombatLockdown() or #available == 0 then return end
        if button == "RightButton" then
            previewIndex = previewIndex % #available + 1
        elseif button == "LeftButton" then
            previewIndex = (previewIndex - 2) % #available + 1
        else return end
        update()
    end)
    previewButton:Hide()
    -- Do not install PreClick/PostClick on the protected action button.
    -- A right-click handler on it could taint secure item use in combat.
    -- Change the preview from /lazypix item next (outside combat) instead.
    circle = CreateFrame("Button", "LazyPixTrafficLight", root)
    circle:EnableMouse(true)
    circle:SetFrameStrata("DIALOG")
    circle:SetFrameLevel(itemButton:GetFrameLevel() + 15)
    circle:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown", "RightButtonDown")
    circleTexture = circle:CreateTexture(nil, "ARTWORK")
    circleTexture:SetAllPoints()
    circleTexture:SetTexture("Interface\\AddOns\\LazyPix_Addon\\CircleGreen.tga")
    -- Masked circular color: WoW's circular portrait mask is an alpha texture.
    circleTexture:SetTexCoord(0, 1, 0, 1)
    circle:SetScript("OnClick", function(_, button)
        -- Shift + right click opens settings; do not change traffic mode.
        if button == "RightButton" and IsShiftKeyDown() then
            if InCombatLockdown() then
                if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff7db9ffLazyPix:|r Settings cannot be opened in combat.") end
                return
            end
            if settings then
                if settings:IsShown() then settings:Hide() else settings:Show() end
            end
            return
        end
        if button == "LeftButton" then db.trafficMode = "green"
        elseif button == "RightButton" then db.trafficMode = "orange"
        else return end
        forceManualUntil = GetTime() + 2
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff7db9ffLazyPix 0.8.2:|r circle click -> " .. db.trafficMode)
        end
        update()
    end)
    buildSettings()
    reposition()
end
local function setPreview(on)
    if InCombatLockdown() and on then return end
    preview = not not on
    previewIndex = 1
    scanBags()
    update()
end
local function command(msg)
    if not root then return end
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "settings" then
        if InCombatLockdown() then return end
        if settings:IsShown() then settings:Hide() else settings:Show() end
    elseif msg == "item next" then
        if InCombatLockdown() then return end
        preview = true
        scanBags()
        if #available > 0 then previewIndex = previewIndex % #available + 1 end
        update()
    elseif msg == "green" or msg == "orange" then
        db.trafficMode = msg
        forceManualUntil = GetTime() + 2
        update()
    elseif msg == "status" then
        local speed = GetUnitSpeed and safeNumber(GetUnitSpeed("player"))
        local s = "LazyPix 0.8.2: mode=" .. tostring(db.trafficMode) .. ", displayed=" .. tostring(lastSignal) .. ", hostile=" .. tostring(not not targetValid()) .. ", standing=" .. tostring(lastStanding) .. ", movementEvents=" .. movementEvents .. ", speed=" .. tostring(speed) .. ", hp=" .. lastHpState .. ", circle=" .. tostring(circle and circle:IsShown())
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(s) end
    end
end
LazyPixHealthWidget = { SetPreview = setPreview, Command = command }
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_STARTED_MOVING")
addon:RegisterEvent("PLAYER_STOPPED_MOVING")
addon:RegisterEvent("BAG_UPDATE")
addon:RegisterEvent("PLAYER_TARGET_CHANGED")
addon:RegisterEvent("UNIT_HEALTH")
addon:RegisterEvent("UNIT_MAXHEALTH")
addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("BAG_UPDATE_COOLDOWN")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("PLAYER_REGEN_DISABLED")
addon:RegisterEvent("UNIT_FLAGS")
addon:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        ensureDB()
        local initialSpeed = GetUnitSpeed and safeNumber(GetUnitSpeed("player"))
        if initialSpeed ~= nil then lastKnownStanding = initialSpeed <= 0 end
        build()
        scanBags()
        update()
    elseif root then
        if event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STOPPED_MOVING" then movementEvents = movementEvents + 1 end
        if event == "PLAYER_STARTED_MOVING" then
            movingFromEvents = true
            lastKnownStanding = false
        elseif event == "PLAYER_STOPPED_MOVING" then
            movingFromEvents = false
            lastKnownStanding = true
        end
        if event == "PLAYER_REGEN_DISABLED" and preview then
            preview = false
            if previewButton then previewButton:Hide() end
        end
        if event == "PLAYER_REGEN_ENABLED" then
            scanBags()
            reposition()
        elseif event == "BAG_UPDATE" and not InCombatLockdown() then
            scanBags()
        end
        if (event ~= "UNIT_HEALTH" and event ~= "UNIT_MAXHEALTH") or unit == "player" or unit == "target" then update() end
    end
end)
addon:SetScript("OnUpdate", function(_, dt)
    if not root then return end
    tick = tick + dt
    if tick >= 0.12 then tick = 0; update() end
end)
