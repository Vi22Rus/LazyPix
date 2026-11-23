-- LazyPix Auto Connect: three levels, no built-in rotation-specific adapters.
local Auto = {}
_G.LazyPixAutoConnect = Auto
local providers, mappings, discovered = {}, {}, {}
local active, preferred, onChange = nil, "auto", nil
local lastScan = 0
local scanPending = false
local lastLateCheck = 0
local function public(v) return not (type(issecretvalue) == "function" and issecretvalue(v)) end
local function typed(v, t) return public(v) and type(v) == t end
local function valid(s)
    return typed(s, "string") and #s > 0 and #s <= 100 and s:match("^[%w_%.%-]+$") ~= nil
end
local function isLoaded(name)
    if not name then return true end
    if not valid(name) then return false end
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if type(f) ~= "function" then return false end
    local ok, loaded = pcall(f, name)
    return ok and public(loaded) and loaded == true
end
local function pathValue(path)
    if not typed(path, "string") or #path > 160 or
       not path:match("^[%a_][%w_%.]*$") or path:find("%.%.") then return nil end
    local value = _G
    for part in path:gmatch("[^%.]+") do
        if type(value) ~= "table" then return nil end
        local ok, nextValue = pcall(function() return value[part] end)
        if not ok or not public(nextValue) then return nil end
        value = nextValue
    end
    return value
end
local function choose()
    local options = {}
    for id, spec in pairs(providers) do
        if isLoaded(spec.addon) then
            local ready = true
            if spec.ready then
                local ok, result = pcall(spec.ready)
                ready = ok and public(result) and result == true
            end
            if ready then options[#options + 1] = id end
        end
    end
    table.sort(options, function(a, b)
        local pa, pb = providers[a].priority, providers[b].priority
        if pa == pb then return a < b end
        return pa > pb
    end)
    local candidate
    if preferred == "auto" then candidate = options[1]
    else
        for _, id in ipairs(options) do
            if id == preferred then candidate = id break end
        end
    end
    if active ~= candidate then
        active = candidate
        if onChange then pcall(onChange, active) end
    end
end
function Auto.RegisterProvider(id, spec)
    if not valid(id) or type(spec) ~= "table" or providers[id] or
        type(spec.read) ~= "function" then return false, "invalid-or-duplicate" end
    if spec.addon and not valid(spec.addon) then return false, "invalid-addon" end
    if spec.ready and type(spec.ready) ~= "function" then return false, "invalid-ready" end
    if spec.priority and (not typed(spec.priority, "number") or
        spec.priority < -100 or spec.priority > 100) then return false, "priority" end
    providers[id] = {addon=spec.addon, read=spec.read, ready=spec.ready,
        priority=spec.priority or 0}
    choose()
    return true
end
-- Generic minimal adapter: map a PUBLISHED result, never run the other addon evaluator.
function Auto.RegisterAdapter(id, mapping)
    if not valid(id) or type(mapping) ~= "table" or
        not typed(mapping.path, "string") then return false, "mapping" end
    local textureKey, spellKey = mapping.textureKey or "texture", mapping.spellKey or "spellID"
    if not valid(textureKey) or not valid(spellKey) then return false, "keys" end
    local path = mapping.path
    local ok, reason = Auto.RegisterProvider(id, {
        addon=mapping.addon, priority=mapping.priority or -10,
        ready=function() return type(pathValue(path)) == "table" end,
        read=function()
            local value = pathValue(path)
            if type(value) ~= "table" then return nil, nil end
            local worked, texture, spellID = pcall(function()
                return value[textureKey], value[spellKey]
            end)
            if not worked then return nil, nil end
            if not typed(spellID, "number") or spellID <= 0 then spellID = nil end
            return texture, spellID
        end,
    })
    if ok then mappings[id] = true end
    return ok, reason
end
local function getMetadata(addon)
    local f = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if type(f) ~= "function" then return nil end
    local ok, endpoint = pcall(f, addon, "X-LazyPix-Provider")
    if ok and typed(endpoint, "string") then return endpoint end
end
-- Discover loaded addons and explicit TOC-advertised compatible endpoints.
function Auto.Scan(diagnostic)
    local countFn = (C_AddOns and C_AddOns.GetNumAddOns) or GetNumAddOns
    local infoFn = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    if type(countFn) == "function" and type(infoFn) == "function" then
        local worked, count = pcall(countFn)
        if worked and typed(count, "number") then
            for i = 1, math.min(count, 500) do
                local ok, info = pcall(infoFn, i)
                if ok then
                    local name = type(info) == "table" and info.name or info
                    if valid(name) and isLoaded(name) then
                        discovered[name] = true
                        local path = getMetadata(name)
                        local endpoint = path and pathValue(path)
                        if type(endpoint) == "table" and
                            type(endpoint.read) == "function" and not providers[name] then
                            local ready = type(endpoint.ready) == "function" and
                                function() return endpoint.ready() end or nil
                            Auto.RegisterProvider(name, {
                                addon=name,
                                read=function() return endpoint.read() end,
                                ready=ready,
                            })
                        end
                    end
                end
            end
        end
    end
    if _G.LazyPixProtocolDiscovery then _G.LazyPixProtocolDiscovery.Scan(diagnostic) end
    lastScan = GetTime and GetTime() or 0
    scanPending = false
    choose()
end
function Auto.OnAddonLoaded(name)
    if valid(name) and isLoaded(name) then
        discovered[name] = true
        scanPending = true
    end
end
function Auto.Tick()
    local now = GetTime and GetTime() or 0
    -- Full global discovery remains strictly event-triggered.
    if scanPending and now - lastScan >= 2 then Auto.Scan(false) end
    -- Lightweight late-UI check: only previously cached candidate owners.
    -- Never enumerate _G or do diagnostic probes in this path.
    if now - lastLateCheck >= 3 then
        lastLateCheck = now
        local discovery = _G.LazyPixProtocolDiscovery
        if discovery and discovery.RefreshLate then discovery.RefreshLate() end
    end
end
function Auto.SetPreferred(value)
    if not typed(value, "string") then return false end
    -- WoW slash input is lowercased; retain the registered spelling internally.
    if value ~= "auto" and not providers[value] then
        local match
        for id in pairs(providers) do
            if id:lower() == value:lower() then
                if match then return false end -- ambiguous IDs differing only by case
                match = id
            end
        end
        if not match then return false end
        value = match
    end
    preferred = value
    choose()
    return true
end
function Auto.SetOnChange(fn) if type(fn) == "function" then onChange = fn end end
function Auto.GetActive() return active end
-- Anonymous public summary: only recognized compatible providers,
-- not the number of installed WoW addons. No internal IDs are exposed.
function Auto.ConnectionSummary()
    choose()
    local count = 0
    for _, spec in pairs(providers) do
        if isLoaded(spec.addon) then
            local ready = true
            if spec.ready then
                local ok, value = pcall(spec.ready)
                ready = ok and public(value) and value == true
            end
            if ready then count = count + 1 end
        end
    end
    return count, active ~= nil
end
function Auto.List()
    local result = {}
    for id, spec in pairs(providers) do
        result[#result + 1] = {id=id, addon=spec.addon, loaded=isLoaded(spec.addon),
            adapter=mappings[id] == true, active=id == active}
    end
    table.sort(result, function(a,b) return a.id < b.id end)
    return result
end
function Auto.Discovered()
    local result = {}
    for name in pairs(discovered) do result[#result + 1] = name end
    table.sort(result)
    return result
end
function Auto.Read()
    choose()
    local spec = active and providers[active]
    if not spec then return nil, nil end
    local ok, texture, id, dimmed, cooldown = pcall(spec.read)
    if not ok then return nil, nil end
    if not typed(id, "number") or id <= 0 then id = nil end
    -- Protected texture is never examined: the visual Blizzard API receives it directly.
    if not typed(dimmed, "boolean") then dimmed = nil end
    if not typed(cooldown, "boolean") then cooldown = nil end
    return texture, id, dimmed, cooldown
end
