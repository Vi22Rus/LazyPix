-- LP-0028: keyboard labels from real, public action slots only.
-- Run: lua5.1 LazyPix_Addon/tests/keybind_display_test.lua
local actions = {
    [1]={"spell",101}, [2]={"spell",102},
    [61]={"spell",103}, [25]={"spell",104},
    [62]={"macro",25}, [3]={"spell",101},
}
local bindings={
    ACTIONBUTTON1="SHIFT-1", ACTIONBUTTON2="CTRL-Q",
    MULTIACTIONBAR4BUTTON1="ALT-2", MULTIACTIONBAR1BUTTON1="F",
    ACTIONBUTTON3="CTRL-3",
}
local reads=0
_G.GetActionInfo=function(slot)
    reads=reads+1
    local v=actions[slot]
    if v then return v[1],v[2] end
end
_G.GetBindingKey=function(command) return bindings[command] end
_G.ActionButton1={action=1}
_G.ActionButton2={action=2}
_G.ActionButton3={action=3}
_G.MultiBarBottomLeftButton1={action=61}
_G.MultiBarBottomLeftButton2={action=62}
_G.MultiBarRightButton1={action=25}
local k=assert(loadfile("LazyPix_Addon/KeybindDisplay.lua"))()
assert(k.Lookup(101)=="Shift+1","must use first bound slot deterministically")
assert(k.Lookup(102)=="Ctrl+Q","Ctrl binding wrong")
assert(k.Lookup(103)=="Alt+2","multi-bar binding wrong")
assert(k.Lookup(104)=="F","right bar binding wrong")
assert(k.Lookup(25)==nil,"macro index is not the selected spell")
assert(k.Lookup(999)==nil,"unbound recommendation must have no key label")
local initial=reads
for i=1,300 do k.Lookup(101) end
assert(reads==initial,"must not scan action bars on each UI update")
bindings.ACTIONBUTTON1="CTRL-SHIFT-4"
k.OnEvent("UPDATE_BINDINGS")
assert(k.Lookup(101)=="Ctrl+Shift+4","UPDATE_BINDINGS must invalidate cache")
actions[1]={"spell",105}
k.OnEvent("ACTIONBAR_SLOT_CHANGED")
assert(k.Lookup(101)=="Ctrl+3","slot move must update binding")
assert(k.Lookup(105)=="Ctrl+Shift+4","new spell must map to changed slot")
_G.ActionButton1.action=13
actions[13]={"spell",106}
k.OnEvent("ACTIONBAR_PAGE_CHANGED")
assert(k.Lookup(105)==nil and k.Lookup(106)=="Ctrl+Shift+4",
    "paged main bar must use actual action slot, not fixed index")
local previous=reads
k.OnEvent("UNIT_AURA")
assert(k.Lookup(106)=="Ctrl+Shift+4" and reads==previous,
    "unrelated events must not invalidate")
_G.issecretvalue=function(v) return v=="SECRET" end
_G.ActionButton1.action="SECRET"
k.OnEvent("UPDATE_BINDINGS")
assert(k.Lookup(106)==nil,"secret action must not be compared")
assert(k.Lookup("SECRET")==nil,"secret recommendation must be discarded")
-- Modern namespaced API works even when the legacy API is unavailable.
_G.GetActionInfo=nil
_G.C_ActionBar={GetActionInfo=function(slot)
    local v=actions[slot]
    if v then return v[1],v[2] end
end}
_G.ActionButton1.action=1
actions[1]={"spell",107}
k.OnEvent("ACTIONBAR_SLOT_CHANGED")
assert(k.Lookup(107)=="Ctrl+Shift+4","C_ActionBar.GetActionInfo must resolve")
-- If modern API is unavailable, the global legacy API remains supported.
_G.C_ActionBar=nil
_G.GetActionInfo=function(slot)
    local v=actions[slot]
    if v then return v[1],v[2] end
end
k.OnEvent("ACTIONBAR_SLOT_CHANGED")
assert(k.Lookup(107)=="Ctrl+Shift+4","legacy GetActionInfo fallback must resolve")
-- Parent action button may already publish a visual hotkey.
bindings.ACTIONBUTTON1=nil
_G.ActionButton1.HotKey={GetText=function() return "F8" end}
k.OnEvent("UPDATE_BINDINGS")
assert(k.Lookup(107)=="F8","displayed button hotkey fallback must resolve")
print("keybind_display_test: PASS")
