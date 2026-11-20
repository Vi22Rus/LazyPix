-- LazyG 0.8.30 TEST - separate GCD dimming from cosmetic perimeter animation.
-- The recommendation is produced only by the source addon. LazyG never casts spells.
local controller = CreateFrame("Frame")
local adapters = {}
local preference = "auto"
local selected, editor, index = nil, false, 1
local entries = {}
local elapsed, detectElapsed = 0, 0
local startupElapsed, startupAnnounced = 0, false
local indicator, icon, sizePanel
local currentSpellID, lastTexture = nil, nil
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
        DEFAULT_CHAT_FRAME:AddMessage("|cff7db9ffLazyG:|r " .. message)
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

-- Adapter contract: ready(), connect(callback), read() (optional).
-- Only LIVE recommendations come from rotation addons; editor spells do not.
adapters.sonah = {
    ready = function()
        local s = _G.Sonah
        return s and s.Engine and s.Engine.Current and s.Listen and s.Registry
            and s.Registry.ActiveSpec and s.Registry.ActiveSpec()
    end,
    connect = function(push)
        local s = _G.Sonah
        if not s or not s.Listen then return false end
        s:Listen("RECOMMENDATION", function(rec)
            push("sonah", rec and rec.icon, rec and (rec.spellID or rec.spellId or rec.id))
        end)
        return true
    end,
    read = function()
        local s = _G.Sonah
        local rec = s and s.Engine and s.Engine.Current and s.Engine:Current()
        return rec and rec.icon, rec and (rec.spellID or rec.spellId or rec.id)
    end,
}
adapters.maxdps = {
    ready = function()
        local m = _G.MaxDps
        return m and m.NextSpell and m.db and m.db.global and m.db.global.enabled ~= false
    end,
    read = function()
        local m = _G.MaxDps
        -- No other-addon event; read the last computed spell (no rotation evaluation).
        return m and SpellTexture(m.Spell), m and m.Spell
    end,
}
-- Hekili can show the Primary or AOE display; each display has its own
-- published recommendation. Prefer the icon actually drawn by Hekili's UI
-- (including iconOverride) so our frame follows the player's visible rotation.
local function HekiliIcon()
    local h = _G.Hekili
    if not h then return nil end
    for _, name in ipairs({"Primary", "AOE"}) do
        local frame = _G["HekiliDisplay" .. name]
        if frame and frame.alpha and frame.alpha > 0 then
            local button = frame.Buttons and frame.Buttons[1]
            local texture = button and button.Texture
            if button and button:IsShown() and texture and texture:IsShown() then
                -- The returned texture may be a secret value: forward it as-is.
                local output = h.Engine and h.Engine.Output
                local stream = output and output[name]
                local rec = stream and stream.recs and stream.recs[1]
                return texture:GetTexture(), rec and rec.actionID
            end
        end
    end
    local output = h.Engine and h.Engine.Output
    if not output then return nil end
    -- If the display has not drawn yet, use the most recent published choice.
    for _, name in ipairs({"Primary", "AOE"}) do
        local stream = output[name]
        local rec = stream and stream.count > 0 and stream.recs and stream.recs[1]
        if rec then return rec.iconOverride or rec.texture, rec.actionID end
    end
end
adapters.hekili = {
    ready = function()
        local h = _G.Hekili
        return h and h.Engine and h.Engine.Subscribe and h.Engine.Output
            and h.Engine.Output.Primary and h.Engine.settings and h.Engine.settings.enabled
    end,
    connect = function(push)
        local engine = _G.Hekili and _G.Hekili.Engine
        if not engine or not engine.Subscribe then return false end
        -- Passive subscriptions: no extra Hekili rotation computations.
        -- Polling below also covers a full subscriber list and late UI draws.
        local function updated()
            local texture, spellID = HekiliIcon()
            push("hekili", texture, spellID)
        end
        local primary = engine.Subscribe("Primary", updated, true)
        local aoe = engine.Subscribe("AOE", updated, true)
        return primary or aoe
    end,
    read = HekiliIcon,
}


-- JustAC (JustAssistedCombat) publishes its recommendation by rendering the
-- first button of its queue. Read only that completed UI result: calling
-- SpellQueue.GetCurrentSpellQueue() would evaluate its rotation a second time.
local function JustACAddon()
    if not LibStub then return nil end
    local ace = LibStub("AceAddon-3.0", true)
    return ace and ace.GetAddon and ace:GetAddon("JustAssistedCombat", true)
end

local function JustACIcon()
    local a = JustACAddon()
    if not a or a.isDisabledMode or not a.mainFrame or
       not a.mainFrame:IsShown() then return nil end
    local button = a.spellIcons and a.spellIcons[1]
    local art = button and button.iconTexture
    if not button or not button:IsShown() or
       not art or not art:IsShown() then return nil end
    -- JustAC's own WAIT placeholder is not a recommended ability.
    if button.isWaitingSpell then return nil end
    local id = button.spellID
    if issecretvalue and issecretvalue(id) then id = nil end
    -- Negative IDs represent items in JustAC, not spell cooldown IDs.
    if type(id) ~= "number" or id <= 0 then id = nil end
    -- The art is the actual rendered recommendation, including icon overrides.
    return art:GetTexture(), id
end

adapters.justac = {
    ready = function()
        local a = JustACAddon()
        return a and not a.isDisabledMode and a.mainFrame and a.spellIcons
    end,
    read = JustACIcon,
}


-- Rotation Master: use its already-rendered first recommendation.
-- Never call its evaluator or force the addon to create a preview window.
-- Its Preview Spells setting must be enabled for a live icon to exist.
local function RotationMasterIcon()
    local a = _G.RotationMaster
    local w = a and a.nextWindow
    if not w or not w.active or not w.frame or not w.frame:IsShown()
        or not w.icons or (w.count or 0) < 1 then return nil end
    local button = w.icons[1]
    local art = button and button.texture
    if not button or button.sample or not button:IsShown()
        or not art or not art:IsShown() then return nil end
    local id = button.spellId
    if issecretvalue and issecretvalue(id) then id = nil end
    if type(id) ~= "number" or id <= 0 or button.itemId then id = nil end
    return art:GetTexture(), id
end

adapters.rotationmaster = {
    ready = function()
        local a = _G.RotationMaster
        return a and a.db and a.db.profile and a.nextWindow
            and a.nextWindow.active and a.nextWindow.frame
    end,
    read = RotationMasterIcon,
}

local connected = {}
local function ChooseSource()
    if preference ~= "auto" then
        local a = adapters[preference]
        if a and a.ready() then return preference end
        return nil
    end
    -- Predictable precedence when multiple engines are loaded; manual override available.
    for _, name in ipairs({"sonah", "maxdps", "hekili", "justac", "rotationmaster"}) do
        if adapters[name].ready() then return name end
    end
end
local sourceOrder = {"sonah", "maxdps", "hekili", "justac", "rotationmaster"}
local sourceNames = {sonah = "Sonah", maxdps = "MaxDPS", hekili = "Hekili", justac = "JustAC", rotationmaster = "RotationMaster"}
local function AvailableSources()
    local result = {}
    for _, name in ipairs(sourceOrder) do
        if adapters[name].ready() then result[#result + 1] = name end
    end
    return result
end
local function AnnounceSources()
    local found = AvailableSources()
    if #found == 0 then
        Msg("Ротационные аддоны не обнаружены. Светофор и хилпот доступны.")
        return
    end
    local names = {}
    for _, name in ipairs(found) do names[#names + 1] = sourceNames[name] end
    if #found > 1 then
        Msg("Обнаружено несколько ротационных аддонов: " .. table.concat(names, ", ") .. ".")
        if selected then
            Msg("LazyG использует: " .. sourceNames[selected] .. ". Для переключения: /lazyg source <sonah|maxdps|hekili|justac|rotationmaster>.")
        else
            Msg("Выбранный источник недоступен. /lazyg source auto или /lazyg source <sonah|maxdps|hekili|justac|rotationmaster>.")
        end
    else
        if selected then
            Msg("Обнаружен " .. names[1] .. ". LazyG использует: " .. sourceNames[selected] .. ".")
        else
            Msg("Обнаружен " .. names[1] .. ", но выбранный источник недоступен. /lazyg source auto")
        end
    end
end
local function ShowHelp()
    Msg("Команды LazyG:")
    Msg("/lazyg help — показать эту справку")
    Msg("/lazyg on — включить настройку иконок; /lazyg off — выйти")
    Msg("/lazyg source auto — автоматический выбор источника")
    Msg("/lazyg source sonah|maxdps|hekili|justac|rotationmaster — выбрать источник вручную")
    Msg("/lazyg status — состояние светофора и хилпота")
    Msg("/lazyg settings — настройки; /lazyg item next — следующий предмет")
    Msg("/lazyg green | orange — переключить цвет светофора")
    Msg("Фрейм ротации: Shift+ЛКМ — переместить; Shift+ПКМ — ширина и высота (32–160)")
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
local function RefreshVisuals()
    if not icon or not indicator or editor or not indicator:IsShown() then return end
    local now = GetTime()
    local onCD, outOfRange = false, false
    if ValidSpellID(currentSpellID) then
        local cd = SpellCooldown(currentSpellID)
        if cd and Public(cd.startTime) and Public(cd.duration) and
            type(cd.startTime) == "number" and type(cd.duration) == "number" then
            -- Avoid mistaking a short shared cooldown for a long ability cooldown.
            -- This is independent of the purely cosmetic rim timer.
            onCD = cd.startTime > 0 and cd.duration > LONG_COOLDOWN_MIN_SECONDS
                and cd.startTime + cd.duration > now
        end
        if C_Spell and C_Spell.IsSpellInRange then
            local range = C_Spell.IsSpellInRange(currentSpellID)
            if Public(range) and range == false then outOfRange = true end
        end
    end
    -- Independent availability feedback: never use cosmetic rim progress/state.
    SetDimmed(now < gcdDimUntil or onCD or outOfRange or playerCasting or playerChanneling)
end
local function Draw(value, spellID)
    if not icon or editor then return end
    -- A protected spellID cannot be inspected or passed to our Lua comparisons.
    currentSpellID = ValidSpellID(spellID) and spellID or nil
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
        indicator:Hide()
        SetDimmed(false)
    end
    RefreshVisuals()
    UpdateCosmeticRim()
end
local function Push(name, value, spellID)
    if selected == name and not editor then Draw(value, spellID) end
end
local function Connect()
    for name, a in pairs(adapters) do
        if a.connect and not connected[name] and a.ready() then
            connected[name] = a.connect(Push) and true or false
        end
    end
end
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
    if indicator.previewBorder then indicator.previewBorder:SetSize(w + 18, h + 18) end
end

local function CreateSizePanel()
    if sizePanel then return sizePanel end
    local panel = CreateFrame("Frame", "LazyGRotationSizeSettings", UIParent)
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
    title:SetText("LazyG — размер фрейма")
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
    indicator = CreateFrame("Button", "LazyGRotationFrame", UIParent)
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
        GameTooltip:AddLine("LazyG: " .. (selected or "no source"))
        GameTooltip:AddLine("Shift + ЛКМ — переместить", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift + ПКМ — размер фрейма", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    indicator:SetScript("OnLeave", function() GameTooltip:Hide() end)
    indicator.previewBorder = border
    indicator:Hide() -- No recommendation at login: avoid an empty placeholder.
end
local function ReadCurrent()
    local a = selected and adapters[selected]
    if a and a.read then Draw(a.read()) else Draw(nil, nil) end
end
local function SetSource(name)
    if selected == name then return end
    selected = name
    if not editor then ReadCurrent() end
end
local function StopEditor(silent)
    if not editor then return end
    editor = false
    entries = {}
    if indicator then indicator.previewBorder:Hide() end
    SetDimmed(false)
    if LazyGHealthWidget then LazyGHealthWidget.SetPreview(false) end
    ReadCurrent()
    UpdateCosmeticRim()
    if not silent then Msg("Режим настройки выключен.") end
end
local function StartEditor()
    if InCombat() then Msg("Настройка доступна только вне боя.") return end
    if editor then return end
    SetSource(ChooseSource())
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
    SetDimmed(false)
    icon:SetTexture(entries[index].icon)
    UpdateCosmeticRim()
    if LazyGHealthWidget then LazyGHealthWidget.SetPreview(true) end
    Msg("Настройка по книге заклинаний: ПКМ следующая, ЛКМ предыдущая.")
end

controller:RegisterEvent("PLAYER_LOGIN")
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
    if event == "PLAYER_LOGIN" then
        SonahRotationSetupDB = SonahRotationSetupDB or {}
        addonDB = SonahRotationSetupDB -- keep earlier saved-variable name for upgrades
        if type(addonDB.minimapAngle) == "number" then minimapAngle = addonDB.minimapAngle end
        PlaceMinimapButton()
        addonDB.indices = addonDB.indices or {}
        preference = addonDB.source or "auto"
        if preference ~= "auto" and not adapters[preference] then preference = "auto" end
        CreateIndicator()
        Connect()
        SetSource(ChooseSource())
        Msg("Фрейм готов. /lazyg help — список команд.")
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and not editor
            and (not Public(spellID) or not NO_VISUAL_GCD_SPELLS[spellID]) then
            local now = GetTime()
            -- Two independent consumers of the cast event.  The cosmetic rim
            -- is never consulted by dimming (and vice versa).
            cosmeticStart = now
            gcdDimUntil = now + GCD_DIM_SECONDS
            UpdateCosmeticRim()
            RefreshVisuals()
        end
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
    elseif event == "ADDON_LOADED" and addonDB then
        Connect()
    end
end)
controller:SetScript("OnUpdate", function(_, dt)
    if not addonDB then return end
    -- Wait briefly until other rotation addons finish their own startup.
    -- Announce once per login, not on every periodic source check.
    if not startupAnnounced then
        startupElapsed = startupElapsed + dt
        if startupElapsed >= 2 then
            startupAnnounced = true
            Connect()
            SetSource(ChooseSource())
            AnnounceSources()
        end
    end
    -- Cosmetic progress has its own update path; it never controls dimming.
    visualElapsed = visualElapsed + dt
    if visualElapsed >= 0.05 then
        visualElapsed = 0
        UpdateCosmeticRim()
    end
    if not editor and indicator and indicator:IsShown() then
        dimElapsed = dimElapsed + dt
        if dimElapsed >= 0.10 then
            dimElapsed = 0
            RefreshVisuals()
        end
    end
    detectElapsed = detectElapsed + dt
    if detectElapsed >= 1 then
        detectElapsed = 0
        Connect()
        if not editor then SetSource(ChooseSource()) end
    end
    if editor or not selected then return end
    elapsed = elapsed + dt
    if elapsed >= 0.2 then
        elapsed = 0
        ReadCurrent()
    end
end)

SLASH_LAZYG1 = "/lazyg"
SlashCmdList.LAZYG = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "help" or msg == "" then ShowHelp()
    elseif msg == "on" then StartEditor()
    elseif msg == "off" then StopEditor()
    elseif msg == "source auto" or msg == "source sonah" or msg == "source maxdps" or msg == "source hekili" or msg == "source justac" or msg == "source rotationmaster" then
        StopEditor(true)
        preference = msg:match("^source (.+)$")
        addonDB.source = preference
        SetSource(ChooseSource())
        Msg("Источник: " .. (selected or "не доступен") .. " (режим " .. preference .. ")")
    elseif msg == "settings" or msg == "item next" or msg == "green" or msg == "orange" or msg == "status" then
        if LazyGHealthWidget and LazyGHealthWidget.Command then LazyGHealthWidget.Command(msg) end
    else
        Msg("Неизвестная команда. /lazyg help — список команд.")
    end
end

-- The minimap icon follows the minimap rim, independently of rotation/health positions.
local minimapButton = CreateFrame("Button", "LazyGMinimapButton", Minimap)
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
    GameTooltip:AddLine("LazyG", 1, 1, 1)
    GameTooltip:AddLine("ЛКМ: настройка в едином фрейме", .85, .85, .85)
    GameTooltip:AddLine("ПКМ: закрыть настройку", .85, .85, .85)
    GameTooltip:AddLine("Удерживать ЛКМ: перемещение по ободу миникарты", .85, .85, .85)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
