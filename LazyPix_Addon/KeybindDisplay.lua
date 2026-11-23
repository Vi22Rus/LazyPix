-- LazyPix: keyboard labels for recommendations already published by a provider.
-- Never evaluate a rotation or infer bindings from a texture.
local Keybind = {}
_G.LazyPixKeybindDisplay = Keybind

local dirty, bySpell = true, {}
local bars = {
    {name="ActionButton", binding="ACTIONBUTTON"},
    {name="MultiBarBottomLeftButton", binding="MULTIACTIONBAR4BUTTON"},
    {name="MultiBarBottomRightButton", binding="MULTIACTIONBAR2BUTTON"},
    {name="MultiBarRightButton", binding="MULTIACTIONBAR1BUTTON"},
    {name="MultiBarLeftButton", binding="MULTIACTIONBAR3BUTTON"},
    {name="MultiBar5Button", binding="MULTIACTIONBAR5BUTTON"},
    {name="MultiBar6Button", binding="MULTIACTIONBAR6BUTTON"},
    {name="MultiBar7Button", binding="MULTIACTIONBAR7BUTTON"},
}
local function public(v)
    return not (type(issecretvalue) == "function" and issecretvalue(v))
end
local function safeCall(fn,...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn,...)
    if ok and public(a) and public(b) then return a,b end
end
local function field(obj,key)
    if not public(obj) or (type(obj)~="table" and type(obj)~="userdata") then return nil end
    local ok,value=pcall(function() return obj[key] end)
    if ok and public(value) then return value end
end
local function keyLabel(raw)
    if type(raw) ~= "string" or not public(raw) or #raw > 90 or raw=="" then return nil end
    local text=raw:gsub("SHIFT%-","Shift+"):gsub("CTRL%-","Ctrl+"):gsub("ALT%-","Alt+")
    text=text:gsub("META%-","Meta+")
    return text
end
local function buttonActionSlot(button)
    -- Effective action slot follows paging, stances, and temporary bars.
    -- Do NOT assume the page from the fixed button number.
    local v=field(button,"action")
    if type(v) ~= "number" then
        local getter=field(button,"GetAttribute")
        if type(getter)=="function" then v=safeCall(getter,button,"action") end
    end
    if not public(v) or type(v)~="number" or v < 1 or v > 240 then return nil end
    return v
end
local function bindingFor(button, bindingCommand)
    local getter=_G.GetBindingKey
    if type(getter)~="function" then return nil end
    local key=safeCall(getter,bindingCommand)
    if not key then
        local name=field(button,"GetName")
        if type(name)=="function" then
            local buttonName=safeCall(name,button)
            if type(buttonName)=="string" then
                key=safeCall(getter,"CLICK "..buttonName..":LeftButton")
            end
        end
    end
    return keyLabel(key)
end
function Keybind.Invalidate()
    dirty=true
end
function Keybind.Refresh()
    -- At most 96 known action buttons on explicit UI/keybinding events.
    -- No _G traversal, no per-frame scanning, no macro condition evaluation.
    local found={}
    for _, bar in ipairs(bars) do
        for i=1,12 do
            local button=field(_G,bar.name..i)
            if button then
                local action=buttonActionSlot(button)
                local actionType, actionID
                if action then
                    actionType, actionID = safeCall(_G.GetActionInfo,action)
                end
                if actionType=="spell" and type(actionID)=="number" and
                    public(actionID) and actionID>0 then
                    local key=bindingFor(button,bar.binding..i)
                    if key and not found[actionID] then found[actionID]=key end
                end
            end
        end
    end
    bySpell=found
    dirty=false
end
function Keybind.Lookup(spellID)
    if not public(spellID) or type(spellID)~="number" or spellID <= 0 then return nil end
    if dirty then Keybind.Refresh() end
    return bySpell[spellID]
end
function Keybind.OnEvent(event)
    if event=="UPDATE_BINDINGS" or event=="ACTIONBAR_SLOT_CHANGED" or
       event=="ACTIONBAR_PAGE_CHANGED" or event=="UPDATE_BONUS_ACTIONBAR" or
       event=="UPDATE_OVERRIDE_ACTIONBAR" or event=="UPDATE_VEHICLE_ACTIONBAR" or
       event=="PLAYER_ENTERING_WORLD" or event=="SPELLS_CHANGED" then
        Keybind.Invalidate()
    end
end
return Keybind
