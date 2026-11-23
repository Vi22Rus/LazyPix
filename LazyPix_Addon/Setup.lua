-- LazyPix 0.8.33-dev EXPERIMENT - anonymous protocol strategies P01-P05.
-- The recommendation is produced only by the source addon. LazyPix never casts spells.
local controller = CreateFrame("Frame")
local selected, editor, index = nil, false, 1
local auto = _G.LazyPixAutoConnect
local keybinds = _G.LazyPixKeybindDisplay
local recommendationElapsed = 0
local entries = {}
local indicator, icon, sizePanel, keybindText
local shownKeybind = nil
local currentSpellID, lastTexture = nil, nil
local inheritedDimmed = nil
local inheritedCooldown = nil
local greyOverlay = nil
local visualElapsed, dimElapsed = 0, 0
local cosmeticStart, COSMETIC_SECONDS = nil, 1.5
-- Separate estimated GCD dimming; never reads or controls cosmeticStart/rim.
local gcdDimUntil, GCD_DIM_SECONDS = 0, 1.5
-- Independent threshold for identifying a longer *spell* cooldown.
local LONG_COOLDOWN_MIN_SECONDS = 1.6
-- Repeating auto-attacks do not start the cosmetic GCD animation.
local NO_VISUAL_GCD_SPELLS = { [75] = true, [5019] = true, [6603] = true }
local shownDimmed = false
local playerCasting, playerChanneling = false, false
local rim, rimGlow, rimProgress
local rimState = nil

-- Decorative perimeter progress: always 1.5 seconds after a player spellcast.
-- This is intentionally NOT a measurement of the real game GCD.
local function SetRimState(state)
    if not rim or rimState == state then return end
    rimState = state
    for _, side in ipairs({"top", "right", "bottom", "left"}) do
        if state == "ready" then
            rim[side]:SetColorTexture(0.12, 0.95, 0.28, 1)
            rimGlow[side]:SetColorTexture(0.12, 0.95, 0.28, 0.20)
        else
            rim[side]:SetColorTexture(0.05, 0.05, 0.05, 1)
            rimGlow[side]:SetColorTexture(0.95, 0.12, 0.08, 0.16)
        end
    end
end

local function HideRimProgress()
    if rimProgress then
        for _, t in pairs(rimProgress) do t:Hide() end
    end
end

local function UpdateRimProgress(progress)
    if not rimProgress or not indicator then return end
    -- Visual-only fraction, derived from our own unprotected GetTime().
    local w, h = indicator:GetWidth(), indicator:GetHeight()
    local perimeter = 2 * (w + h)
    local remaining = math.max(0, math.min(1, progress)) * perimeter
    local lengths = {math.min(w, remaining), 0, 0, 0}
    remaining = math.max(0, remaining - w)
    lengths[2] = math.min(h, remaining)
    remaining = math.max(0, remaining - h)
    lengths[3] = math.min(w, remaining)
    remaining = math.max(0, remaining - w)
    lengths[4] = math.min(h, remaining)
    local names = {"top", "right", "bottom", "left"}
    for i, side in ipairs(names) do
        local t = rimProgress[side]
        local length = lengths[i]
        if length > 0 then
            t:ClearAllPoints()
            if side == "top" then
                t:SetSize(length, 4)
                t:SetPoint("BOTTOMLEFT", indicator, "TOPLEFT", 0, 1)
            elseif side == "right" then
                t:SetSize(4, length)
                t:SetPoint("TOPLEFT", indicator, "TOPRIGHT", 1, 0)
            elseif side == "bottom" then
                t:SetSize(length, 4)
                t:SetPoint("TOPRIGHT", indicator, "BOTTOMRIGHT", 0, -1)
            else
                t:SetSize(4, length)
                t:SetPoint("BOTTOMRIGHT", indicator, "BOTTOMLEFT", -1, 0)
            end
            t:Show()
        else
            t:Hide()
        end
    end
end
local FRAME_MIN, FRAME_MAX, FRAME_DEFAULT = 32, 160, 52
local addonDB
-- Forward declarations: PLAYER_LOGIN uses these values before minimap setup code below.
local minimapAngle = 135
local PlaceMinimapButton

local function Msg(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff7db9ffLazyPix:|r " .. message)
    end
end
local function InCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end
local function SpellTexture(id)
    if issecretvalue and issecretvalue(id) then
        return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
    end
    if not id or id == 0 then return nil end
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    if GetSpellTexture then return GetSpellTexture(id) end
end
-- The editor uses the PLAYER spellbook, not a rotation addon's spell list.
-- Enumerate only the class/general/specialization skill lines; profession
-- and pet spellbooks are intentionally excluded.
local function SpellbookSpells()
    local book = C_SpellBook
    local enums = Enum and Enum.SpellBookSpellBank
    local itemTypes = Enum and Enum.SpellBookItemType
    if not book or not enums or not itemTypes or
       not book.GetNumSpellBookSkillLines or
       not book.GetSpellBookSkillLineInfo or
       not book.GetSpellBookItemInfo then
        return {}
    end

    local result, byName = {}, {}
    local function AddSpell(id, name, texture, subName)
        if type(id) ~= "number" or id <= 0 then return end
        if C_Spell and C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(id) then return end
        name = name or (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or tostring(id)
        texture = texture or SpellTexture(id)
        if not texture or texture == 134400 then return end
        -- Different ranks have different SpellIDs but the same localized name.
        -- Use the rank from the player spellbook, not the numeric SpellID
        -- (SpellIDs are not ordered by rank). Fall back to the later book slot.
        local rank = type(subName) == "string" and tonumber(subName:match("(%d+)")) or nil
        local position = byName[name]
        if position then
            local existing = result[position]
            if existing.id == id then return end
            if rank and existing.rank and rank < existing.rank then return end
            if not rank and existing.rank then return end
            -- Equal/unknown ranks: keep the most recent spellbook entry.
            existing.key = name .. " (" .. id .. ")"
            existing.icon, existing.id, existing.rank = texture, id, rank
        else
            result[#result + 1] = {
                key = name .. " (" .. id .. ")",
                icon = texture,
                id = id,
                rank = rank,
            }
            byName[name] = #result
        end
    end

    local count = book.GetNumSpellBookSkillLines() or 0
    for tab = 1, count do
        local line = book.GetSpellBookSkillLineInfo(tab)
        if line and not line.isGuild and not line.shouldHide and
           not line.offSpecID and not line.isOffSpec then
            local first = (line.itemIndexOffset or 0) + 1
            local last = first + (line.numSpellBookItems or 0) - 1
            for slot = first, last do
                local info = book.GetSpellBookItemInfo(slot, enums.Player)
                if info and not info.isOffSpec then
                    if info.itemType == itemTypes.Spell and not info.isPassive then
                        AddSpell(info.spellID or info.actionID, info.name, info.iconID, info.subName)
                    elseif info.itemType == itemTypes.Flyout and
                        GetFlyoutInfo and GetFlyoutSlotInfo then
                        local flyoutID = info.actionID
                        local _, _, numSlots = GetFlyoutInfo(flyoutID)
                        for child = 1, (numSlots or 0) do
                            local id, override, known, name = GetFlyoutSlotInfo(flyoutID, child)
                            if known then AddSpell(override or id, name) end
                        end
                    end
                end
            end
        end
    end
    return result
end

-- All rotation protocol signatures live in ProtocolDiscovery.lua.
-- No names of external rotation addons are required in the bridge.
local function ShowHelp()
    Msg("Команды LazyPix (эксперимент Auto Connect):")
    Msg("/lazypix help — показать справку")
    Msg("/lazypix on — предпросмотр изученных способностей; /lazypix off — выйти")
    Msg("/lazypix sources — показать зарегистрированные источники")
    Msg("/lazypix protocols — результаты проверки P01–P05")
    Msg("/lazypix protocol debug — ручная полная проверка (может вызвать паузу)")
    Msg("/lazypix source auto | <id> — выбрать источник")
    Msg("/lazypix status — состояние светофора и хилпота")
    Msg("/lazypix settings — настройки; /lazypix item next — следующий предмет")
    Msg("/lazypix green | orange — переключить цвет светофора")
    Msg("Фрейм: Shift+ЛКМ — переместить; Shift+ПКМ — размер (32–160)")
end

-- WoW Forever may mark combat-derived values as secret. Never branch, compare,
-- perform arithmetic, or format a protected number/boolean in Lua.
local function Public(value)
    return not (issecretvalue and issecretvalue(value))
end
local function ValidSpellID(id)
    return Public(id) and type(id) == "number" and id > 0 and id ~= 61304
end
local function SpellCooldown(id)
    if not C_Spell or not C_Spell.GetSpellCooldown then return nil end
    return C_Spell.GetSpellCooldown(id)
end
-- Cosmetic rim has no effect on spell availability, rotation or dimming.
-- Its timer starts only on the player's successful spellcast event.
local function UpdateCosmeticRim()
    if not rim then return end
    local running = cosmeticStart and (GetTime() - cosmeticStart < COSMETIC_SECONDS)
    if not running then cosmeticStart = nil end
    -- Never draw a cosmetic overlay over the spellbook calibration preview.
    if editor or not indicator or not indicator:IsShown() or not running then
        SetRimState("ready")
        HideRimProgress()
        return
    end
    SetRimState("progress")
    UpdateRimProgress((GetTime() - cosmeticStart) / COSMETIC_SECONDS)
end
local function SetDimmed(dim)
    if not icon or shownDimmed == dim then return end
    shownDimmed = dim
    icon:SetDesaturated(dim)
    icon:SetVertexColor(dim and 0.55 or 1, dim and 0.55 or 1, dim and 0.55 or 1, 1)
end
-- Availability is owned by the source recommendation, not a local GCD timer.
local function RefreshVisuals()
    if not icon or not indicator or editor or not indicator:IsShown() then return end
    SetDimmed(inheritedDimmed == true)
    if greyOverlay then greyOverlay:SetShown(inheritedCooldown == true) end
end
local function SetKeybind(spellID)
    if not keybindText then return end
    local key = keybinds and keybinds.Lookup and keybinds.Lookup(spellID, selected == "P02") or nil
    if type(key) ~= "string" then key = nil end
    if shownKeybind == key then return end
    shownKeybind = key
    keybindText:SetText(key or "")
end
local function Draw(value, spellID, dimmed, cooldown)
    if not icon or editor then return end
    -- A protected spellID cannot be inspected or passed to our Lua comparisons.
    currentSpellID = ValidSpellID(spellID) and spellID or nil
    SetKeybind(currentSpellID)
    inheritedDimmed = Public(dimmed) and type(dimmed) == "boolean" and dimmed or nil
    inheritedCooldown = Public(cooldown) and type(cooldown) == "boolean" and cooldown or nil
    -- Value may be a protected texture handle. Forward it directly.
    if issecretvalue and issecretvalue(value) then
        icon:SetTexture(value)
        indicator:Show()
    elseif value then
        icon:SetTexture(value)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        indicator:Show()
    else
        icon:SetTexture(nil)
        inheritedCooldown = nil
        if greyOverlay then greyOverlay:Hide() end
        indicator:Hide()
        SetDimmed(false)
    end
    RefreshVisuals()
    UpdateCosmeticRim()
end
-- No source callback or adapter connections in this experiment.
-- Future Auto Connect must only call Draw after it verifies a real recommendation.
local function ClampSize(value)
    value = tonumber(value) or FRAME_DEFAULT
    if value ~= value then return FRAME_DEFAULT end
    return math.floor(math.max(FRAME_MIN, math.min(FRAME_MAX, value)) + 0.5)
end

local function SaveFrameSize(width, height)
    if not indicator or not addonDB or InCombat() then return end
    local w, h = ClampSize(width), ClampSize(height)
    addonDB.frameWidth, addonDB.frameHeight = w, h
    indicator:SetSize(w, h)
    if keybindText then keybindText:SetWidth(w + 72) end
    if indicator.previewBorder then indicator.previewBorder:SetSize(w + 18, h + 18) end
end

local function CreateSizePanel()
    if sizePanel then return sizePanel end
    local panel = CreateFrame("Frame", "LazyPixRotationSizeSettings", UIParent)
    panel:SetSize(270, 170)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetPoint("TOPLEFT", indicator, "TOPRIGHT", 12, 0)
    panel:EnableMouse(true)
    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.07, 0.09, 0.96)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -14)
    title:SetText("LazyPix — размер фрейма")
    local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    close:SetSize(28, 24)
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    close:SetText("X")
    close:SetScript("OnClick", function() panel:Hide() end)

    local function MakeSlider(label, y, initial, field)
        local caption = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        caption:SetPoint("TOPLEFT", panel, "TOPLEFT", 15, y)
        local slider = CreateFrame("Slider", nil, panel)
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(228, 16)
        slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, y - 26)
        slider:SetMinMaxValues(FRAME_MIN, FRAME_MAX)
        slider:SetValueStep(1)
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints()
        track:SetColorTexture(0.2, 0.23, 0.28, 1)
        slider:SetValue(initial)
        caption:SetText(label .. ": " .. initial)
        slider:SetScript("OnValueChanged", function(self, raw)
            if InCombat() then return end
            local value = ClampSize(raw)
            caption:SetText(label .. ": " .. value)
            if field == "width" then
                SaveFrameSize(value, addonDB.frameHeight)
            else
                SaveFrameSize(addonDB.frameWidth, value)
            end
        end)
        return slider
    end
    panel.widthSlider = MakeSlider("Ширина", -45, addonDB.frameWidth, "width")
    panel.heightSlider = MakeSlider("Высота", -107, addonDB.frameHeight, "height")
    panel:Hide()
    sizePanel = panel
    return panel
end

local function ToggleSizePanel()
    if InCombat() then Msg("Размер фрейма можно менять только вне боя.") return end
    local panel = CreateSizePanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel.widthSlider:SetValue(addonDB.frameWidth)
        panel.heightSlider:SetValue(addonDB.frameHeight)
        panel:Show()
    end
end

local function CreateIndicator()
    if indicator then return end
    addonDB.frameWidth = ClampSize(addonDB.frameWidth)
    addonDB.frameHeight = ClampSize(addonDB.frameHeight)
    indicator = CreateFrame("Button", "LazyPixRotationFrame", UIParent)
    indicator:SetSize(addonDB.frameWidth, addonDB.frameHeight)
    indicator:SetFrameStrata("MEDIUM")
    indicator:SetClampedToScreen(true)
    indicator:SetMovable(true)
    indicator:EnableMouse(true)
    indicator:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    indicator:RegisterForDrag("LeftButton")
    local pos = addonDB.rotationPosition or {}
    indicator:SetPoint("CENTER", UIParent, "CENTER", pos.x or 0, pos.y or -120)
    local background = indicator:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.75)
    icon = indicator:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    -- Text lives OUTSIDE the captured spell-icon pixels to protect Windows RGB.
    keybindText = indicator:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keybindText:SetPoint("BOTTOMRIGHT", indicator, "TOPRIGHT", 0, 4)
    keybindText:SetWidth(addonDB.frameWidth + 72)
    keybindText:SetHeight(16)
    keybindText:SetJustifyH("RIGHT")
    keybindText:SetTextColor(1, 1, 1, 1)
    keybindText:SetShadowOffset(1, -1)
    keybindText:SetText("")
    -- Parent-authored cooldown state: grey film above the icon, not a clock.
    greyOverlay = indicator:CreateTexture(nil, "OVERLAY", nil, 1)
    greyOverlay:SetAllPoints(icon)
    greyOverlay:SetColorTexture(0.12, 0.12, 0.12, 0.53)
    greyOverlay:Hide()
    local border = indicator:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetPoint("CENTER", indicator, "CENTER", 0, 0)
    border:SetSize(addonDB.frameWidth + 18, addonDB.frameHeight + 18)
    border:SetVertexColor(0.9, 0.7, 0.2, 0.7)
    border:Hide()
    -- Hollow rim: four strips outside the icon (no pixel obscuration).
    -- A soft second ring creates a subtle halo without covering the spell.
    rim = {}
    rimGlow = {}
    local function AddSide(collection, side, thickness, r, g, b, alpha, layer)
        local t = indicator:CreateTexture(nil, layer)
        t:SetColorTexture(r, g, b, alpha)
        collection[side] = t
        return t
    end
    for _, side in ipairs({"top", "right", "bottom", "left"}) do
        AddSide(rimGlow, side, 7, 1, 0.65, 0.15, 0.13, "BACKGROUND")
        AddSide(rim, side, 2, 1, 0.75, 0.3, 0.92, "BORDER")
    end
    local function PositionRim(t, offset, thickness)
        t.top:ClearAllPoints()
        t.top:SetPoint("BOTTOMLEFT", indicator, "TOPLEFT", -offset, offset)
        t.top:SetPoint("BOTTOMRIGHT", indicator, "TOPRIGHT", offset, offset)
        t.top:SetHeight(thickness)
        t.bottom:ClearAllPoints()
        t.bottom:SetPoint("TOPLEFT", indicator, "BOTTOMLEFT", -offset, -offset)
        t.bottom:SetPoint("TOPRIGHT", indicator, "BOTTOMRIGHT", offset, -offset)
        t.bottom:SetHeight(thickness)
        t.left:ClearAllPoints()
        t.left:SetPoint("TOPRIGHT", indicator, "TOPLEFT", -offset, offset)
        t.left:SetPoint("BOTTOMRIGHT", indicator, "BOTTOMLEFT", -offset, -offset)
        t.left:SetWidth(thickness)
        t.right:ClearAllPoints()
        t.right:SetPoint("TOPLEFT", indicator, "TOPRIGHT", offset, offset)
        t.right:SetPoint("BOTTOMLEFT", indicator, "BOTTOMRIGHT", offset, -offset)
        t.right:SetWidth(thickness)
    end
    PositionRim(rim, 0, 2)
    PositionRim(rimGlow, 2, 5)
    -- Four red strips fill the OUTSIDE of the icon, never its RGB area.
    rimProgress = {}
    for _, side in ipairs({"top", "right", "bottom", "left"}) do
        local t = indicator:CreateTexture(nil, "OVERLAY", nil, 6)
        t:SetColorTexture(1, 0.08, 0.05, 1)
        t:Hide()
        rimProgress[side] = t
    end
    SetRimState("ready")
    local moving = false
    indicator:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() and not InCombat() then
            moving = true
            self:StartMoving()
        end
    end)
    indicator:SetScript("OnDragStop", function(self)
        if not moving then return end
        moving = false
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        if x and y and parentX and parentY then
            addonDB.rotationPosition = {x=x-parentX, y=y-parentY}
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", addonDB.rotationPosition.x, addonDB.rotationPosition.y)
        end
    end)
    indicator:SetScript("OnClick", function(_, button)
        if IsShiftKeyDown() then
            if button == "RightButton" then ToggleSizePanel() end
            return
        end
        if not editor or InCombat() or #entries == 0 then return end
        if button == "RightButton" then index = index % #entries + 1
        elseif button == "LeftButton" then index = (index - 2) % #entries + 1 end
        addonDB.indices.spellbook = index
        local entry = entries[index]
        icon:SetTexture(entry.icon)
        Msg(index .. "/" .. #entries .. ": " .. tostring(entry.key))
    end)
    indicator:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("LazyPix: " .. (selected or "no source"))
        GameTooltip:AddLine("Shift + ЛКМ — переместить", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift + ПКМ — размер фрейма", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    indicator:SetScript("OnLeave", function() GameTooltip:Hide() end)
    indicator.previewBorder = border
    indicator:Hide() -- No recommendation at login: avoid an empty placeholder.
end
local function ReadCurrent()
    if not auto then Draw(nil, nil) return end
    local texture, spellID, dimmed, cooldown = auto.Read()
    selected = auto.GetActive()
    Draw(texture, spellID, dimmed, cooldown)
end
local function ShowSources()
    if not auto then Msg("Модуль Auto Connect не загружен.") return end
    auto.Scan()
    local sources = auto.List()
    Msg("Обнаружено загруженных аддонов: " .. #auto.Discovered() ..
        ", зарегистрировано совместимых источников: " .. #sources)
    for _, item in ipairs(sources) do
        Msg(item.id .. " [" .. (item.adapter and "adapter" or "provider") .. "] " ..
            (item.loaded and "loaded" or "not loaded") ..
            (item.active and " ACTIVE" or ""))
    end
    if #sources == 0 then Msg("Протоколы не подтверждены; /lazypix protocols — диагностика.") end
end
local function StopEditor(silent)
    if not editor then return end
    editor = false
    entries = {}
    if indicator then indicator.previewBorder:Hide() end
    SetDimmed(false)
    if greyOverlay then greyOverlay:Hide() end
    if LazyPixHealthWidget then LazyPixHealthWidget.SetPreview(false) end
    ReadCurrent()
    UpdateCosmeticRim()
    if not silent then Msg("Режим настройки выключен.") end
end
local function StartEditor()
    if InCombat() then Msg("Настройка доступна только вне боя.") return end
    if editor then return end
    local list = SpellbookSpells()
    if #list == 0 then
        Msg("В книге заклинаний не найдены изученные активные способности.")
        return
    end
    entries, editor = list, true
    index = math.max(1, math.min(#entries, tonumber(addonDB.indices.spellbook) or 1))
    -- Keep the decorative preview border hidden: it obscures ability icon pixels.
    indicator:Show() -- Preview is visible even without a live recommendation.
    currentSpellID = nil
    SetKeybind(nil)
    inheritedCooldown = nil
    if greyOverlay then greyOverlay:Hide() end
    SetDimmed(false)
    icon:SetTexture(entries[index].icon)
    UpdateCosmeticRim()
    if LazyPixHealthWidget then LazyPixHealthWidget.SetPreview(true) end
    Msg("Настройка по книге заклинаний: ПКМ следующая, ЛКМ предыдущая.")
end

controller:RegisterEvent("PLAYER_LOGIN")
controller:RegisterEvent("PLAYER_ENTERING_WORLD")
controller:RegisterEvent("UPDATE_BINDINGS")
controller:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
controller:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
controller:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
controller:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
controller:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
controller:RegisterEvent("SPELLS_CHANGED")
controller:RegisterEvent("ADDON_LOADED")
controller:RegisterEvent("PLAYER_REGEN_DISABLED")
controller:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
controller:RegisterEvent("UNIT_SPELLCAST_START")
controller:RegisterEvent("UNIT_SPELLCAST_STOP")
controller:RegisterEvent("UNIT_SPELLCAST_FAILED")
controller:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
controller:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
controller:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
controller:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
controller:SetScript("OnEvent", function(_, event, ...)
    if keybinds and keybinds.OnEvent then keybinds.OnEvent(event) end
    if event == "PLAYER_LOGIN" then
        SonahRotationSetupDB = SonahRotationSetupDB or {}
        addonDB = SonahRotationSetupDB -- keep earlier saved-variable name for upgrades
        if type(addonDB.minimapAngle) == "number" then minimapAngle = addonDB.minimapAngle end
        PlaceMinimapButton()
        addonDB.indices = addonDB.indices or {}
        CreateIndicator()
        if auto then
            auto.SetOnChange(function() if not editor then ReadCurrent() end end)
            auto.Scan()
            auto.SetPreferred(addonDB.autoConnectSource or "auto")
        end
        ReadCurrent()
        Msg("Auto Connect 0.8.42-dev готов: /lazypix sources для диагностики.")
    elseif event == "ADDON_LOADED" then
        if auto then auto.OnAddonLoaded(...) end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BINDINGS" or
        event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or
        event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_OVERRIDE_ACTIONBAR" or
        event == "UPDATE_VEHICLE_ACTIONBAR" or event == "SPELLS_CHANGED" then
        if addonDB and not editor then SetKeybind(currentSpellID) end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- No synthetic GCD/rim: source display is authoritative.
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit == "player" then
            if event == "UNIT_SPELLCAST_START" then
                playerCasting = true
            elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
                playerChanneling = true
            elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
                playerChanneling = false
            else
                playerCasting = false
            end
            if not editor then RefreshVisuals() end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        StopEditor(true)
        if sizePanel then sizePanel:Hide() end
    end
end)
controller:SetScript("OnUpdate", function(_, dt)
    if not addonDB then return end
    -- Cosmetic progress has its own update path; it never controls dimming.
    visualElapsed = visualElapsed + dt
    if visualElapsed >= 0.05 then
        visualElapsed = 0
        UpdateCosmeticRim()
    end
    if auto then auto.Tick() end
    if not editor then
        recommendationElapsed = recommendationElapsed + dt
        if recommendationElapsed >= 0.2 then
            recommendationElapsed = 0
            ReadCurrent()
        end
    end
    if not editor and indicator and indicator:IsShown() then
        dimElapsed = dimElapsed + dt
        if dimElapsed >= 0.10 then
            dimElapsed = 0
            RefreshVisuals()
        end
    end
end)

SLASH_LAZYPIX1 = "/lazypix"
SlashCmdList.LAZYPIX = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "help" or msg == "" then ShowHelp()
    elseif msg == "on" then StartEditor()
    elseif msg == "off" then StopEditor()
    elseif msg == "sources" then
        ShowSources()
    elseif msg == "protocols" then
        -- Cached state only; no full scan during ordinary status checks.
        local p = _G.LazyPixProtocolDiscovery
        if p then
            for _, result in ipairs(p.List()) do
                Msg(result.id .. ": " .. result.status)
            end
        else Msg("Модуль протоколов не загружен.") end
    elseif msg == "protocol debug" then
        if auto then auto.Scan(true) end
        local p = _G.LazyPixProtocolDiscovery
        if p and p.Diagnostics then
            for _, line in ipairs(p.Diagnostics()) do Msg(line) end
        else Msg("Диагностика протоколов недоступна.") end
    elseif msg == "source" then
        Msg("Использование: /lazypix source auto | <id>")
    elseif msg:match("^source%s+") then
        local name = msg:match("^source%s+(.+)$")
        if auto and auto.SetPreferred(name) then
            addonDB.autoConnectSource = name
            if not editor then ReadCurrent() end
            Msg("Auto Connect источник: " .. name)
        else
            Msg("Неизвестный источник: " .. tostring(name))
        end
    elseif msg == "settings" or msg == "item next" or msg == "green" or msg == "orange" or msg == "status" then
        if LazyPixHealthWidget and LazyPixHealthWidget.Command then LazyPixHealthWidget.Command(msg) end
    else
        Msg("Неизвестная команда. /lazypix help — список команд.")
    end
end

-- The minimap icon follows the minimap rim, independently of rotation/health positions.
local minimapButton = CreateFrame("Button", "LazyPixMinimapButton", Minimap)
minimapButton:SetSize(30, 30)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapButton:EnableMouse(true)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")

-- minimapAngle is declared above so PLAYER_LOGIN reads the same saved angle.
local minimapDragging = false
local minimapWasDragged = false
PlaceMinimapButton = function()
    local radius = math.min(Minimap:GetWidth(), Minimap:GetHeight()) / 2 + 8
    local radians = math.rad(minimapAngle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(radians) * radius, math.sin(radians) * radius)
end
local function UpdateMinimapButtonFromCursor()
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local mx, my = Minimap:GetCenter()
    if not cx or not cy or not mx or not my or not scale or scale == 0 then return end
    local dx, dy = cx / scale - mx, cy / scale - my
    if dx == 0 and dy == 0 then return end
    minimapAngle = math.deg(math.atan2(dy, dx))
    PlaceMinimapButton()
    if addonDB then addonDB.minimapAngle = minimapAngle end
end
minimapButton:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then minimapWasDragged = false end
end)
minimapButton:SetScript("OnDragStart", function()
    minimapDragging = true
    minimapWasDragged = true
    minimapButton:SetScript("OnUpdate", UpdateMinimapButtonFromCursor)
    UpdateMinimapButtonFromCursor()
end)
minimapButton:SetScript("OnDragStop", function()
    minimapDragging = false
    minimapButton:SetScript("OnUpdate", nil)
    if addonDB then addonDB.minimapAngle = minimapAngle end
end)
PlaceMinimapButton()
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT")
local miniIcon = minimapButton:CreateTexture(nil, "ARTWORK")
miniIcon:SetTexture("Interface\\Icons\\Ability_DualWield")
miniIcon:SetSize(19, 19)
miniIcon:SetPoint("CENTER", minimapButton, "CENTER", -1, 1)
miniIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
minimapButton:SetScript("OnClick", function(_, button)
    if not addonDB then return end
    if button == "LeftButton" and minimapWasDragged then
        minimapWasDragged = false
        return
    end
    if button == "LeftButton" then StartEditor()
    elseif button == "RightButton" then StopEditor() end
end)
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("LazyPix", 1, 1, 1)
    GameTooltip:AddLine("ЛКМ: настройка в едином фрейме", .85, .85, .85)
    GameTooltip:AddLine("ПКМ: закрыть настройку", .85, .85, .85)
    GameTooltip:AddLine("Удерживать ЛКМ: перемещение по ободу миникарты", .85, .85, .85)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
