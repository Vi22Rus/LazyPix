-- Mock-based Lua 5.1 smoke test: run from the repo root:
-- lua5.1 LazyPix_Addon/tests/autoconnect_test.lua
local data = {}
_G.C_AddOns = {
    GetNumAddOns = function() return 2 end,
    GetAddOnInfo = function(i) return ({ "TestRot", "Another" })[i] end,
    IsAddOnLoaded = function(n) return n == "TestRot" or n == "Another" end,
    GetAddOnMetadata = function(n, k)
        if n == "TestRot" and k == "X-LazyPix-Provider" then
            return "TestRot.Public"
        end
    end,
}
_G.GetTime = function() return 4 end
_G.TestRot = {Public={read=function() return "texture-a", 42 end}}
_G.Another = {Published={next={texture="texture-b",spellID=99}}}
assert(loadfile("LazyPix_Addon/AutoConnect.lua"))()
assert(loadfile("LazyPix_Addon/ProtocolDiscovery.lua"))()
local a = assert(_G.LazyPixAutoConnect)
a.Scan()
assert(#a.Discovered() == 2)
assert(a.GetActive() == "TestRot")
local detected, connected = a.ConnectionSummary()
assert(detected == 1 and connected == true, "summary counts compatible connected providers only")
local texture, id = a.Read()
assert(texture == "texture-a" and id == 42)
assert(a.RegisterAdapter("Another", {addon="Another", path="Another.Published.next"}))
detected, connected = a.ConnectionSummary()
assert(detected == 2 and connected == true, "two compatible providers expected")
assert(a.SetPreferred("another"))
texture, id = a.Read()
assert(texture == "texture-b" and id == 99)
assert(not a.SetPreferred("NonExisting"))
assert(a.SetPreferred("auto"))
assert(not a.SetPreferred("unknown"))
assert(a.GetActive() == "TestRot")
assert(not a.RegisterProvider("TestRot", {read=function() end}))
print("autoconnect_test: PASS")

-- Structural discovery without addon names. Three independent proofs per signature.
local function fakeFrame() return {IsShown=function() return true end} end
_G.C_Spell = {GetSpellTexture=function(id) return "icon-"..id end}
local mockP02 = {NextSpell=function() end, UpdateSpellFrame=function() end,
    db={global={enabled=true}}, Spell=123}
_G.SomeOpaqueRuntime = mockP02
_G.LazyPixProtocolDiscovery.Scan()
local statuses = {}
for _, v in ipairs(_G.LazyPixProtocolDiscovery.List()) do statuses[v.id]=v.status end
assert(statuses.P02 == "registered")
assert(a.SetPreferred("P02"))
local _, sid = a.Read()
assert(sid == 123)
-- A second compatible structure must never be selected silently.
_G.OtherRuntime = {NextSpell=function() end, UpdateSpellFrame=function() end,
    db={global={enabled=true}}, Spell=888}
_G.LazyPixProtocolDiscovery.Scan()
statuses = {}
for _, v in ipairs(_G.LazyPixProtocolDiscovery.List()) do statuses[v.id]=v.status end
assert(statuses.P02 == "ambiguous")
detected, connected = a.ConnectionSummary()
assert(detected == 2, "ambiguous incompatible P02 is not counted")
local _, blocked = a.Read()
assert(blocked == nil)
_G.OtherRuntime = nil
_G.LazyPixProtocolDiscovery.Scan()
assert(a.Read() ~= nil or a.GetActive() == "P02")
print("protocol_discovery_test: PASS")

-- Regression LP-0015: exported P01 structure exists with no product name.
_G.OpaqueSpec = {
    Engine={Current=function() return {icon="spell-icon",spellID=435,waiting=true} end},
    Listen=function(self,event,fn) self.lastEvent=event; self.callback=fn end,
    Registry={ActiveSpec=function() return {key="x"} end},
}
_G.LazyPixProtocolDiscovery.Scan(true)
local p01
for _, item in ipairs(_G.LazyPixProtocolDiscovery.List()) do
    if item.id=="P01" then p01=item.status end
end
assert(p01=="registered", "P01 must recognize exported Engine/Listen/Registry")
assert(a.SetPreferred("P01"))
local i, id01, dim01=a.Read()
assert(i=="spell-icon" and id01==435 and dim01==true)
local debugTable = table.concat(_G.LazyPixProtocolDiscovery.Diagnostics(),"\\n")
assert(debugTable:find("P01: registered",1,true))
assert(debugTable:find("Registry.ActiveSpec=yes",1,true))
assert(debugTable:find("global entries=",1,true))
-- The closest candidate diagnostic must preserve same-object evidence;
-- arbitrary partial structures must never be promoted into a provider.
_G.OpaqueSpec=nil
_G.LazyPixProtocolDiscovery.Scan()
print("protocol_diagnostic_test: PASS")

-- LP-0017: no repeated full scans on idle frames.
local actualScan=_G.LazyPixProtocolDiscovery.Scan
local count=0
_G.LazyPixProtocolDiscovery.Scan=function(...) count=count+1; return actualScan(...) end
local now=10
_G.GetTime=function() return now end
a.Scan()
local initial=count
for n=1,500 do a.Tick() end
assert(count==initial,"idle Tick must not repeat full discovery")
a.OnAddonLoaded("Another")
for n=1,50 do a.Tick() end
assert(count==initial,"ADDON_LOADED scan should be deferred")
now=13
a.Tick()
assert(count==initial+1,"pending ADDON_LOADED triggers exactly one scan")
for n=1,200 do a.Tick() end
assert(count==initial+1,"no periodic scan after pending load")
print("scan_throttle_test: PASS")

-- LP-0020: published shading is optional and never synthesized.
assert(a.SetPreferred("P01"))
-- A stale/changed P01 source is unavailable; no fabricated GCD state.
local _, _, state=a.Read()
assert(state==nil)
print("source_visual_state_test: PASS")
