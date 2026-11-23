-- LazyPix protocol discovery: structural signatures, never names of source addons.
-- Only reads published recommendations; never calls a rotation evaluator.
local Auto = _G.LazyPixAutoConnect
local Protocol = {}
_G.LazyPixProtocolDiscovery = Protocol
local installed, states, objects, diagnostics = {}, {}, {}, {}
local lateCandidates = {P04={},P05={}}
local scanStats = {scanned=0, total=0, truncated=false}
local order = {"P01","P02","P03","P04","P05"}

local function public(v)
    return not (type(issecretvalue) == "function" and issecretvalue(v))
end
local function field(t, k)
    if not public(t) or (type(t) ~= "table" and type(t) ~= "userdata") then return nil end
    local ok, v = pcall(function() return t[k] end)
    if ok and public(v) then return v end
end
local function tableField(t,k)
    local v = field(t,k)
    return type(v) == "table" and v or nil
end
local function func(t,k) return type(field(t,k)) == "function" end
local function truth(v) return public(v) and v == true end
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
local function textureDim(tex)
    if not tex or not public(tex) then return nil end
    local ok, value = pcall(function() return tex:GetDesaturation() end)
    if ok and public(value) and type(value) == "boolean" then return value end
    return nil
end
-- Read the already-rendered parent cooldown, never invent our own 1.5s GCD.
-- GetCooldownTimes uses milliseconds on Blizzard cooldown frames.
-- Unreadable/secret timing is unknown (nil), not falsely ready.
local function parentCooldown(frame)
    if not frame or not public(frame) then return nil end
    local shown, isShown = pcall(function() return frame:IsShown() end)
    if not shown or not public(isShown) then return nil end
    if isShown ~= true then return false end
    local ok, startMs, durationMs = pcall(function()
        return frame:GetCooldownTimes()
    end)
    if not ok or not public(startMs) or not public(durationMs) or
        type(startMs) ~= "number" or type(durationMs) ~= "number" then
        return nil
    end
    if durationMs <= 0 or startMs <= 0 then return false end
    local now = type(GetTime) == "function" and GetTime() or nil
    if not public(now) or type(now) ~= "number" then return nil end
    return startMs + durationMs > now * 1000
end
local function primaryFrameCooldown(t)
    local ui = tableField(t,"UI")
    local display = ui and tableField(ui,"Display")
    if not display or not func(display,"Frames") then return nil end
    local ok, frames = pcall(function() return display:Frames() end)
    if not ok or not public(frames) then return nil end
    local mainIcon = tableField(frames,"icon")
    return parentCooldown(mainIcon and field(mainIcon,"cooldown"))
end
local function firstButtonCooldown(t)
    local b = field(tableField(t,"spellIcons"),1)
    return b and parentCooldown(field(b,"cooldown")) or nil
end
local function recommendationDim(t, rec)
    if not public(rec) then return nil end
    local waiting, noPower, oor = field(rec,"waiting"),field(rec,"noPower"),field(rec,"outOfRange")
    if (waiting ~= nil and type(waiting) ~= "boolean") or
       (noPower ~= nil and type(noPower) ~= "boolean") or
       (oor ~= nil and type(oor) ~= "boolean") then return nil end
    local settings = tableField(t,"Settings")
    local tintRange = false
    if settings and func(settings,"Get") then
        local ok, v = pcall(function() return settings:Get("showRangeTint") end)
        if ok and public(v) and type(v) == "boolean" then tintRange = v end
    end
    return waiting == true or noPower == true or (tintRange and oor == true)
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
            local cd = primaryFrameCooldown(t)
            if cd == nil and field(rec,"waiting") == true then cd = true end
            return field(rec,"icon"), spell(field(rec,"spellID") or
                field(rec,"spellId") or field(rec,"id")), recommendationDim(t,rec), cd
        end,
        connect = function(t)
            -- Subscribe only to the published event; polling remains a fallback.
            pcall(function()
                t:Listen("RECOMMENDATION", function(rec)
                    if not public(rec) then return end
                    objects.P01.cachedTexture = field(rec,"icon")
                    objects.P01.cachedSpell = spell(field(rec,"spellID") or
                        field(rec,"spellId") or field(rec,"id"))
                    objects.P01.cachedDimmed = recommendationDim(t,rec)
                    objects.P01.cachedCooldown = primaryFrameCooldown(t)
                    if objects.P01.cachedCooldown == nil and field(rec,"waiting") == true then
                        objects.P01.cachedCooldown = true
                    end
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
                and tableField(output,"Primary") and tableField(e,"settings")
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
            local settings = tableField(tableField(t,"Engine"),"settings")
            return settings and field(settings,"enabled") == true
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
            return frame and icons and func(t,"GetProfile") and
                func(t,"UpdateFrameSize") and func(frame,"IsShown")
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
            return texture(tex), spell(field(b,"spellID")), textureDim(tex),
                parentCooldown(field(b,"cooldown"))
        end,
    },
    P05 = {
        match = function(t)
            local w = tableField(t,"nextWindow")
            return w and field(w,"frame") and tableField(w,"icons") and
                func(w,"AddRecommendation") and func(w,"ReleaseChildren") and
                func(w,"Valid")
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
            return texture(art), spell(field(b,"spellId")), textureDim(art)
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
    -- Never truncate at a magic iteration count: pairs(_G) is unordered,
    -- so a loaded and matching source may occur after the cutoff.
    for _, v in pairs(_G) do
        n = n + 1
        add(v)
    end
    scanStats.total = n
    -- AceAddon registry uses an addon ID as a key, but it is not used in detection.
    if type(LibStub) == "function" or type(LibStub) == "table" then
        local ok, ace = pcall(LibStub,"AceAddon-3.0",true)
        local registry = ok and ace and tableField(ace,"addons")
        if registry then
            for _, v in pairs(registry) do add(v) end
        end
    end
    scanStats.scanned = #result
    return result
end
-- Report individual structural checks, without logging external addon names.
local probes = {
    P01 = {
        {"Engine", function(t) return tableField(t,"Engine") ~= nil end},
        {"Engine.Current", function(t) return func(tableField(t,"Engine"),"Current") end},
        {"Listen", function(t) return func(t,"Listen") end},
        {"Registry.ActiveSpec", function(t) return func(tableField(t,"Registry"),"ActiveSpec") end},
    },
    P02 = {
        {"db.global", function(t) return tableField(tableField(t,"db"),"global") ~= nil end},
        {"NextSpell", function(t) return field(t,"NextSpell") ~= nil end},
        {"UpdateSpellFrame", function(t) return func(t,"UpdateSpellFrame") end},
    },
    P03 = {
        {"Engine.Subscribe", function(t) return func(tableField(t,"Engine"),"Subscribe") end},
        {"Engine.Output.Primary", function(t)
            return tableField(tableField(tableField(t,"Engine"),"Output"),"Primary") ~= nil
        end},
        {"Engine.settings", function(t) return tableField(tableField(t,"Engine"),"settings") ~= nil end},
    },
    P04 = {
        {"mainFrame", function(t) return field(t,"mainFrame") ~= nil end},
        {"spellIcons", function(t) return tableField(t,"spellIcons") ~= nil end},
        {"GetProfile/UpdateFrameSize", function(t) return func(t,"GetProfile") and func(t,"UpdateFrameSize") end},
    },
    P05 = {
        {"nextWindow.frame", function(t)
            return field(tableField(t,"nextWindow"),"frame") ~= nil
        end},
        {"nextWindow.icons", function(t)
            return tableField(tableField(t,"nextWindow"),"icons") ~= nil
        end},
        {"window methods", function(t)
            local w = tableField(t,"nextWindow")
            return func(w,"AddRecommendation") and func(w,"ReleaseChildren") and func(w,"Valid")
        end},
    },
}
local function report(id, candidates)
    local checks = probes[id]
    local counts = {}
    local closest = {score=-1, passed={}}
    for i=1,#checks do counts[i]=0 end
    for _, obj in ipairs(candidates) do
        local score, passed = 0, {}
        for i, check in ipairs(checks) do
            local ok, yes = pcall(check[2],obj)
            if ok and yes then
                counts[i] = counts[i] + 1
                score = score + 1
                passed[i] = true
            end
        end
        -- A score of 1 is too weak to show as a probable connector,
        -- but raw counts still help diagnose missing exports.
        if score > closest.score then closest = {score=score,passed=passed} end
    end
    local lines = {}
    for i, check in ipairs(checks) do
        lines[#lines+1] = check[1] .. "=" .. (closest.passed[i] and "yes" or "no") ..
            " (seen " .. counts[i] .. ")"
    end
    diagnostics[id] = {checks=lines, best=closest.score}
end
-- Cache only plausible late-UI owners from the ONE full scan.
-- No repeated traversal of _G; RefreshLate checks this short, bounded list.
local function prepareLate(candidates)
    lateCandidates.P04, lateCandidates.P05 = {}, {}
    for _, obj in ipairs(candidates) do
        if func(obj,"GetProfile") and func(obj,"UpdateFrameSize") then
            lateCandidates.P04[#lateCandidates.P04+1] = obj
        end
        local db = tableField(obj,"db")
        local profile = db and tableField(db,"profile")
        if (db and func(obj,"GetPreviewArtChoices")) or tableField(obj,"nextWindow") then
            lateCandidates.P05[#lateCandidates.P05+1] = obj
        end
    end
end
local function refreshLateOne(id)
    if states[id] == "registered" or states[id] == "ambiguous" or
       states[id] == "changed-source" then return end
    local matches, source = 0, nil
    for _, obj in ipairs(lateCandidates[id]) do
        local ok, matched = pcall(strategies[id].match,obj)
        if ok and matched then
            matches, source = matches + 1, obj
            if matches > 1 then break end
        end
    end
    if matches == 1 and not installed[id] then
        -- The small late-candidate scan can be finalized without touching _G.
        return source
    end
end
function Protocol.RefreshLate()
    -- AutoConnect may call this on a slow cadence; never enumerate global tables.
    for _, id in ipairs({"P04","P05"}) do
        local candidate = refreshLateOne(id)
        if candidate and not installed[id] then
            local strategy = strategies[id]
            objects[id] = {source=candidate}
            local ok = Auto.RegisterProvider(id,{
                priority=10-tonumber(id:sub(2)),
                ready=function()
                    if states[id] ~= "registered" then return false end
                    if strategy.ready then
                        local safe, ready = pcall(strategy.ready,candidate)
                        return safe and ready == true
                    end
                    return true
                end,
                read=function()
                    if states[id] ~= "registered" then return nil end
                    local okRead, tex, spellId, dim, cooldown = pcall(strategy.read,candidate)
                    if okRead then return tex,spellId,dim,cooldown end
                end,
            })
            if ok then installed[id],states[id] = true,"registered" end
        end
    end
end
function Protocol.Scan(diagnostic)
    local candidates = enumerate()
    prepareLate(candidates)
    for _, id in ipairs(order) do
        local strategy = strategies[id]
        if diagnostic then report(id, candidates) end
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
                    local okRead, tex, sid, dim, cooldown = pcall(strategy.read, source)
                    if okRead and tex ~= nil then return tex, sid, dim, cooldown end
                    if id == "P01" and objects[id] then
                        return objects[id].cachedTexture, objects[id].cachedSpell,
                            objects[id].cachedDimmed,
                            objects[id].cachedCooldown
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
function Protocol.Diagnostics()
    local lines = {"global entries=" .. scanStats.total ..
        ", exported tables=" .. scanStats.scanned}
    for _, id in ipairs(order) do
        local d = diagnostics[id]
        lines[#lines+1] = id .. ": " .. (states[id] or "not-scanned")
        if d then
            for _, check in ipairs(d.checks) do lines[#lines+1] = "  " .. check end
        end
    end
    return lines
end
function Protocol.List()
    local out = {}
    for _, id in ipairs(order) do
        out[#out+1] = {id=id, status=states[id] or "not-scanned"}
    end
    return out
end
