-- LazyPix protocol discovery: structural signatures, never names of source addons.
-- Only reads published recommendations; never calls a rotation evaluator.
local Auto = _G.LazyPixAutoConnect
local Protocol = {}
_G.LazyPixProtocolDiscovery = Protocol
local installed, states, objects = {}, {}, {}
local order = {"P01","P02","P03","P04","P05"}

local function public(v)
    return not (type(issecretvalue) == "function" and issecretvalue(v))
end
local function field(t, k)
    if not public(t) or type(t) ~= "table" then return nil end
    local ok, v = pcall(function() return t[k] end)
    if ok and public(v) then return v end
end
local function tableField(t,k)
    local v = field(t,k)
    return type(v) == "table" and v or nil
end
local function func(t,k) return type(field(t,k)) == "function" end
local function visible(frame)
    if not frame or not public(frame) then return false end
    local ok, shown = pcall(function() return frame:IsShown() end)
    return ok and public(shown) and shown == true
end
local function texture(tex)
    if not tex or not visible(tex) then return nil end
    local ok, value = pcall(function() return tex:GetTexture() end)
    -- Protected textures must go straight to the display API.
    if ok then return value end
end
local function spell(id)
    if public(id) and type(id) == "number" and id > 0 then return id end
end
local function spellTexture(id)
    if not spell(id) then return nil end
    local f = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
    if type(f) ~= "function" then return nil end
    local ok, value = pcall(f, id)
    if ok then return value end
end
local function first(t)
    if type(t) ~= "table" then return nil end
    return field(t,1)
end
-- Independent structural proofs. Current recommendation may be nil while idle.
local strategies = {
    P01 = {
        match = function(t)
            local e, r = tableField(t,"Engine"), tableField(t,"Registry")
            return e and r and func(e,"Current") and func(t,"Listen")
                and func(r,"ActiveSpec")
        end,
        read = function(t)
            local e = field(t,"Engine")
            local ok, rec = pcall(function() return e:Current() end)
            if not ok or not public(rec) then return nil end
            return field(rec,"icon"), spell(field(rec,"spellID") or
                field(rec,"spellId") or field(rec,"id"))
        end,
        connect = function(t)
            -- Subscribe only to the published event; polling remains a fallback.
            pcall(function()
                t:Listen("RECOMMENDATION", function(rec)
                    if not public(rec) then return end
                    objects.P01.cachedTexture = field(rec,"icon")
                    objects.P01.cachedSpell = spell(field(rec,"spellID") or
                        field(rec,"spellId") or field(rec,"id"))
                end)
            end)
        end,
    },
    P02 = {
        match = function(t)
            local db = tableField(t,"db")
            return db and tableField(db,"global") and field(t,"NextSpell") ~= nil
                and func(t,"UpdateSpellFrame")
        end,
        read = function(t)
            local id = spell(field(t,"Spell"))
            return spellTexture(id), id
        end,
        ready = function(t)
            local db = tableField(t,"db")
            local global = db and tableField(db,"global")
            return global and field(global,"enabled") ~= false
        end,
    },
    P03 = {
        match = function(t)
            local e = tableField(t,"Engine")
            local output = e and tableField(e,"Output")
            return e and func(e,"Subscribe") and output
                and tableField(output,"Primary") and tableField(t,"settings")
        end,
        read = function(t)
            local e = tableField(t,"Engine")
            local output = e and tableField(e,"Output")
            for _, name in ipairs({"Primary","AOE"}) do
                local stream = output and tableField(output,name)
                local rec = stream and first(tableField(stream,"recs"))
                if rec then
                    return field(rec,"iconOverride") or field(rec,"texture"),
                        spell(field(rec,"actionID"))
                end
            end
        end,
        ready = function(t)
            local settings = tableField(t,"settings")
            return settings and field(settings,"enabled") ~= false
        end,
        connect = function(t)
            local e = field(t,"Engine")
            for _, name in ipairs({"Primary","AOE"}) do
                -- Passive subscription does not recompute the source rotation.
                pcall(function() e.Subscribe(name, function() end, true) end)
            end
        end,
    },
    P04 = {
        match = function(t)
            local icons = tableField(t,"spellIcons")
            local frame = field(t,"mainFrame")
            local b = first(icons)
            return frame and icons and b and field(b,"iconTexture")
                and type(field(frame,"IsShown")) == "function"
        end,
        ready = function(t)
            return field(t,"isDisabledMode") ~= true
                and visible(field(t,"mainFrame"))
        end,
        read = function(t)
            local b = first(tableField(t,"spellIcons"))
            if not b or not visible(b) or field(b,"isWaitingSpell") == true then return end
            local tex = field(b,"iconTexture")
            if not visible(tex) then return end
            return texture(tex), spell(field(b,"spellID"))
        end,
    },
    P05 = {
        match = function(t)
            local w = tableField(t,"nextWindow")
            local b = w and first(tableField(w,"icons"))
            return w and field(w,"frame") and b and field(b,"texture")
                and field(w,"count") ~= nil
        end,
        ready = function(t)
            local w = tableField(t,"nextWindow")
            return w and field(w,"active") == true and visible(field(w,"frame"))
        end,
        read = function(t)
            local w = tableField(t,"nextWindow")
            local b = w and first(tableField(w,"icons"))
            if not b or field(b,"sample") == true or field(b,"itemId") or
                not visible(b) then return end
            local art = field(b,"texture")
            return texture(art), spell(field(b,"spellId"))
        end,
    },
}
local function enumerate()
    local result, seen = {}, {}
    local function add(v)
        if type(v) == "table" and not seen[v] then
            seen[v] = true
            result[#result+1] = v
        end
    end
    -- Scan top-level exported tables, not the whole UI tree or secret game state.
    local n = 0
    for _, v in pairs(_G) do
        n = n + 1
        if n > 12000 then break end
        add(v)
    end
    -- AceAddon registry uses an addon ID as a key, but it is not used in detection.
    if type(LibStub) == "function" then
        local ok, ace = pcall(LibStub,"AceAddon-3.0",true)
        local registry = ok and ace and tableField(ace,"addons")
        if registry then
            for _, v in pairs(registry) do add(v) end
        end
    end
    return result
end
function Protocol.Scan()
    local candidates = enumerate()
    for _, id in ipairs(order) do
        local strategy = strategies[id]
        local matches, candidate = 0, nil
        for _, object in ipairs(candidates) do
            local ok, matched = pcall(strategy.match, object)
            if ok and matched then
                matches, candidate = matches + 1, object
                if matches > 1 then break end
            end
        end
        if matches > 1 then
            states[id] = "ambiguous"
        elseif matches == 0 then
            states[id] = installed[id] and "lost" or "not-found"
        elseif installed[id] then
            states[id] = objects[id] and objects[id].source == candidate
                and "registered" or "changed-source"
        else
            local source = candidate
            objects[id] = {source=source}
            local ok = Auto.RegisterProvider(id, {
                priority=10 - tonumber(id:sub(2)),
                ready=function()
                    if states[id] ~= "registered" then return false end
                    if strategy.ready then
                        local safe, ready = pcall(strategy.ready, source)
                        return safe and ready == true
                    end
                    return true
                end,
                read=function()
                    if states[id] ~= "registered" then return nil end
                    local okRead, tex, sid = pcall(strategy.read, source)
                    if okRead and tex ~= nil then return tex, sid end
                    if id == "P01" and objects[id] then
                        return objects[id].cachedTexture, objects[id].cachedSpell
                    end
                end,
            })
            if ok then
                installed[id] = true
                states[id] = "registered"
                if strategy.connect then pcall(strategy.connect,source) end
            else
                states[id] = "registration-failed"
            end
        end
    end
end
function Protocol.List()
    local out = {}
    for _, id in ipairs(order) do
        out[#out+1] = {id=id, status=states[id] or "not-scanned"}
    end
    return out
end
