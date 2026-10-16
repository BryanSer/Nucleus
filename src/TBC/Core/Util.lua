local _, ns = ...
local N = ns.N

-- A default table counts as a list (kept whole, not merged key by key) if it has entries or is
-- flagged _list = true.
local function isArray(t) return type(t) == "table" and (t[1] ~= nil or t._list == true) end

function N.DeepCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = N.DeepCopy(x) end
    return out
end

-- Merges defaults into a saved table without overwriting keys; lists count as one value (a missing list is
-- seeded, removed entries are never re-added).
function N.MergeDefaults(target, defaults)
    if type(target) ~= "table" then target = {} end
    for k, v in pairs(defaults) do
        if isArray(v) then
            if target[k] == nil then target[k] = N.DeepCopy(v) end
        elseif type(v) == "table" then
            target[k] = N.MergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
    return target
end

-- Drops keys that no longer exist in defaults. Lists are left alone.
function N.PruneStale(tbl, defaults)
    if type(tbl) ~= "table" or type(defaults) ~= "table" then return end
    for k, v in pairs(tbl) do
        if defaults[k] == nil then
            tbl[k] = nil
        elseif type(v) == "table" and not isArray(defaults[k]) then
            N.PruneStale(v, defaults[k])
        end
    end
end

-- Queue for work that is not allowed in combat (layout, secure attributes). Runs on
-- PLAYER_REGEN_ENABLED.
local queue = {}
local queueFrame = CreateFrame("Frame")
N.SafeRegister(queueFrame, "PLAYER_REGEN_ENABLED")
queueFrame:SetScript("OnEvent", function()
    local run = queue
    queue = {}
    for i = 1, #run do
        local ok, err = pcall(run[i].fn)
        if not ok then geterrorhandler()(err) end
    end
end)

-- Runs fn now, or after combat. A key replaces an earlier deferral of the same action.
function N.RunWhenSafe(fn, key)
    if not InCombatLockdown() then
        fn()
        return
    end
    if key then
        for i = 1, #queue do
            if queue[i].key == key then
                queue[i].fn = fn
                return
            end
        end
    end
    queue[#queue + 1] = { fn = fn, key = key }
end

function N.Round(v)
    return floor(v + 0.5)
end

function N.Snap(frame, v)
    local PU = _G.PixelUtil
    if PU and PU.GetNearestPixelSize and frame and frame.GetEffectiveScale then
        local s = frame:GetEffectiveScale()
        if s and s > 0 then
            local r = PU.GetNearestPixelSize(math.abs(v), s, 1)
            return v < 0 and -r or r
        end
    end
    return v
end

-- Debug log; only filled while debug logging is on.
local LOG_MAX = 400
N.DebugLog = {}
local debugQueued

function N.Debug(...)
    local db = N.db
    if not (db and db.debugMode) then return end
    local ok, text = pcall(function(...) return strjoin(" ", tostringall(...)) end, ...)
    local log = N.DebugLog
    log[#log + 1] = date("%H:%M:%S") .. " " .. (ok and text or "?")
    if #log > LOG_MAX then table.remove(log, 1) end
    if N.OnDebugLog and not debugQueued then
        debugQueued = true
        C_Timer.After(0.2, function()
            debugQueued = false
            if N.OnDebugLog then N.OnDebugLog() end
        end)
    end
end

local printOut = N.Print
function N:Print(...)
    printOut(self, ...)
    N.Debug("print:", ...)
end

N:On("NUCLEUS_SETTING_CHANGED", function(_, section, path) N.Debug("setting", section, path) end)

local watcher = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD" }) do
    watcher:RegisterEvent(e)
end
watcher:SetScript("OnEvent", function(_, event, a, b)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        N.Debug(event, a, b)
    else
        N.Debug(event)
    end
end)
