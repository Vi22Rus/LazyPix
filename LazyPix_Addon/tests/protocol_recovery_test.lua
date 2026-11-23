-- LP-0022: mock regression for anonymous P03, P04, P05.
-- Run: lua5.1 LazyPix_Addon/tests/protocol_recovery_test.lua
local clock = 4
_G.GetTime = function() return clock end
_G.C_AddOns = {
    GetNumAddOns = function() return 0 end,
    GetAddOnInfo = function() return nil end,
    IsAddOnLoaded = function() return false end,
}
-- Callable TABLE form of the embedded library resolver, not a function.
local ace = {addons={}}
_G.LibStub = setmetatable({}, {
    __call=function(_, key) if key=="AceAddon-3.0" then return ace end end,
})
local function frame()
    return {IsShown=function() return true end}
end
local function art(icon)
    return {IsShown=function() return true end,
        GetTexture=function() return icon end,
        GetDesaturation=function() return false end}
end
assert(loadfile("LazyPix_Addon/AutoConnect.lua"))()
assert(loadfile("LazyPix_Addon/ProtocolDiscovery.lua"))()
local auto = _G.LazyPixAutoConnect
local proto = _G.LazyPixProtocolDiscovery

-- Event/output provider: configuration is under Engine, not on the root.
_G.SourceThree = {Engine={
    Subscribe=function() return true end,
    Output={Primary={count=1,recs={{texture="p03-texture",actionID=303}}}},
    settings={enabled=true},
}}
-- UI provider may export the owner before making its frame and first icon.
local sourceFour = {
    GetProfile=function() return {} end,
    UpdateFrameSize=function() end,
}
ace.addons.opaque = sourceFour
-- Preview provider may export an owner before its preview window exists.
_G.SourceFive = {
    db={profile={preview_spells=true}},
    GetPreviewArtChoices=function() return {} end,
}

auto.Scan()
local function status(id)
    for _, row in ipairs(proto.List()) do if row.id==id then return row.status end end
end
assert(status("P03")=="registered", "P03 Engine.settings discovery failed")
assert(status("P04")=="not-found", "P04 must wait for its UI")
assert(status("P05")=="not-found", "P05 must wait for preview window")
assert(auto.SetPreferred("P03"))
local tex, spell = auto.Read()
assert(tex=="p03-texture" and spell==303, "P03 output not read")

sourceFour.mainFrame = frame()
sourceFour.spellIcons = {{iconTexture=art("p04-texture"),
    spellID=404,IsShown=function() return true end}}
_G.SourceFive.nextWindow = {
    frame=frame(),active=true,count=1,
    icons={{texture=art("p05-texture"),spellId=505,
        IsShown=function() return true end}},
    AddRecommendation=function() end,
    ReleaseChildren=function() end,
    Valid=function() return true end,
}
-- A cheap retry checks cached owners only, not the global registry.
proto.RefreshLate()
assert(status("P04")=="registered", "P04 AceAddon cached owner not activated")
assert(status("P05")=="registered", "P05 late window not activated")
assert(auto.SetPreferred("P04"))
tex, spell = auto.Read()
assert(tex=="p04-texture" and spell==404, "P04 icon not forwarded")
assert(auto.SetPreferred("P05"))
tex, spell = auto.Read()
assert(tex=="p05-texture" and spell==505, "P05 preview icon not forwarded")

-- The frame-driven late retry must never cause a full _G rescan.
local calls=0
local original = proto.Scan
proto.Scan=function(...) calls=calls+1; return original(...) end
clock=7
for i=1,500 do auto.Tick() end
assert(calls==0, "idle ticks unexpectedly performed a full rescan")
print("protocol_recovery_test: PASS")
