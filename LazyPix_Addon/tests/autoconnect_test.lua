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
local texture, id = a.Read()
assert(texture == "texture-a" and id == 42)
assert(a.RegisterAdapter("Another", {addon="Another", path="Another.Published.next"}))
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
local _, blocked = a.Read()
assert(blocked == nil)
_G.OtherRuntime = nil
_G.LazyPixProtocolDiscovery.Scan()
assert(a.Read() ~= nil or a.GetActive() == "P02")
print("protocol_discovery_test: PASS")
