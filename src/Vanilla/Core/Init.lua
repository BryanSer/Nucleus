-- Classic Era entry point. Sets up the namespace and a small event dispatcher, no external libraries
-- needed.

local addonName, ns = ...

ns.CLIENT = "Vanilla"
ns.ADDON = addonName
local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
ns.VERSION = getMeta and getMeta(addonName, "Version") or "1.0.2"

local N = {}
ns.N = N
_G.Nucleus = N

-- A client refuses to register an event it does not know (the modern ones are missing here), and
-- that error would stop the whole file. These register what exists and skip the rest.
function N.SafeRegister(frame, event)
    return pcall(frame.RegisterEvent, frame, event)
end
function N.SafeRegisterUnit(frame, event, unit)
    return pcall(frame.RegisterUnitEvent, frame, event, unit)
end

-- event name -> list of handlers
local handlers = {}

local dispatcher = CreateFrame("Frame")
dispatcher:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        list[i](event, ...)
    end
end)

-- Registers a handler for a game event or an internal message (see N:Fire).
function N:On(event, fn)
    local list = handlers[event]
    if not list then
        list = {}
        handlers[event] = list
        if not event:find("^NUCLEUS_") then
            N.SafeRegister(dispatcher, event)
        end
    end
    list[#list + 1] = fn
end

-- Internal messages are prefixed NUCLEUS_.
function N:Fire(message, ...)
    local list = handlers[message]
    if not list then return end
    for i = 1, #list do
        list[i](message, ...)
    end
end

local PREFIX = "|cff3399ffNucleus|r "

function N:Print(...)
    print(PREFIX .. strjoin(" ", tostringall(...)))
end
