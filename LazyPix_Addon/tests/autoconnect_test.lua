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
local a = assert(_G.LazyPixAutoConnect)
a.Scan()
assert(#a.Discovered() == 2)
assert(a.GetActive() == "TestRot")
local texture, id = a.Read()
assert(texture == "texture-a" and id == 42)
assert(a.RegisterAdapter("Another", {addon="Another", path="Another.Published.next"}))
assert(a.SetPreferred("Another"))
texture, id = a.Read()
assert(texture == "texture-b" and id == 99)
assert(not a.SetPreferred("NonExisting"))
assert(a.SetPreferred("auto"))
assert(a.GetActive() == "TestRot")
assert(not a.RegisterProvider("TestRot", {read=function() end}))
print("autoconnect_test: PASS")
