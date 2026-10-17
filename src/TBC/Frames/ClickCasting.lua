local _, ns = ...
local N = ns.N

-- Click-casting: modifier+click -> spell / item / macro on a unit frame, via secure attributes written out of
-- combat. The header's *type1 / *type2 wildcards stay for unbound clicks.

local CC = {}
N.ClickCasting = CC

local BUTTON_INDEX = { LeftButton = 1, RightButton = 2, MiddleButton = 3, Button4 = 4, Button5 = 5 }

-- Wheel and keys have no button number: while the mouse is over a frame an override binding turns them into a
-- named click ("ctrlSCROLLUP", "altQ"); a key binding is stored as button = "KEY:Q".
local WHEEL = { ScrollUp = "SCROLLUP", ScrollDown = "SCROLLDOWN" }
local WHEEL_KEY = { ScrollUp = "MOUSEWHEELUP", ScrollDown = "MOUSEWHEELDOWN" }

local function mouseIndex(button)
    local idx = BUTTON_INDEX[button]
    if idx then return idx end
    local n = tonumber(tostring(button):match("^Button(%d+)$"))
    if n and n >= 1 and n <= 31 then return n end
end

local function keyOf(button)
    return type(button) == "string" and button:match("^KEY:(.+)$") or nil
end

local function hoverName(button)
    return WHEEL[button] or keyOf(button)
end

-- Modifiers are stored in Blizzard's attribute order (alt-, ctrl-, shift-); NormalizeModifier converts older saves.
local ALL_MODS = {
    "none", "alt", "ctrl", "shift", "alt-ctrl", "alt-shift", "ctrl-shift", "alt-ctrl-shift",
}

function CC.NormalizeModifier(mod)
    if not mod or mod == "none" or mod == "" then return "none" end
    local has = {}
    for part in tostring(mod):gmatch("[^-]+") do has[part] = true end
    local out = {}
    for _, key in ipairs({ "alt", "ctrl", "shift" }) do
        if has[key] then out[#out + 1] = key end
    end
    return #out > 0 and table.concat(out, "-") or "none"
end

local function modPrefix(mod)
    mod = CC.NormalizeModifier(mod)
    return mod == "none" and "" or (mod .. "-")
end

local function wheelSuffix(mod, button)
    mod = CC.NormalizeModifier(mod)
    return "-" .. (mod == "none" and "" or (mod:gsub("-", ""))) .. hoverName(button)
end

function CC.CurrentModifier()
    local out = {}
    if IsAltKeyDown() then out[#out + 1] = "alt" end
    if IsControlKeyDown() then out[#out + 1] = "ctrl" end
    if IsShiftKeyDown() then out[#out + 1] = "shift" end
    return #out > 0 and table.concat(out, "-") or "none"
end

function CC.BindingText(binding)
    local L = N.L
    local mod = CC.NormalizeModifier(binding and binding.modifier)
    local parts = {}
    if mod ~= "none" then
        for key in mod:gmatch("[^-]+") do
            parts[#parts + 1] = key:sub(1, 1):upper() .. key:sub(2)
        end
    end
    local names = {
        LeftButton = L["Left Click"], RightButton = L["Right Click"],
        MiddleButton = L["Middle Click"], Button4 = L["Mouse Button 4"],
        Button5 = L["Mouse Button 5"], ScrollUp = L["Scroll Up"], ScrollDown = L["Scroll Down"],
    }
    local button = binding and binding.button or "LeftButton"
    local key = keyOf(button)
    local text = names[button]
    if key then
        text = _G["KEY_" .. key] or key
    elseif not text then
        local n = mouseIndex(button)
        text = n and (L["Mouse Button 4"]:gsub("4", tostring(n))) or L["Left Click"]
    end
    parts[#parts + 1] = text
    return table.concat(parts, " + ")
end

-- The attribute name/value pairs a binding needs, or nil. Macro text starts with "/" or "#", anything else
-- is a macro name.
local PLAIN_ACTIONS = { target = "target", focus = "focus", menu = "togglemenu", assist = "assist" }

local function attrPairs(binding)
    if not binding or binding.kind == "none" then return nil end
    local idx, prefix
    if hoverName(binding.button) then
        idx, prefix = wheelSuffix(binding.modifier, binding.button), ""
    else
        idx, prefix = mouseIndex(binding.button), modPrefix(binding.modifier)
    end
    if not idx then return nil end
    local typeAttr = prefix .. "type" .. idx

    -- "general" keeps the action in value; the bare kinds are older saves.
    local plain = (binding.kind == "general") and PLAIN_ACTIONS[binding.value]
        or PLAIN_ACTIONS[binding.kind]
    if plain then return typeAttr, plain end
    -- Trinket 1 / 2 follow the equipment slot; a macro, so they also work in combat.
    if binding.kind == "trinket1" or binding.kind == "trinket2" then
        local slot = (binding.kind == "trinket1") and 13 or 14
        return typeAttr, "macro", prefix .. "macrotext" .. idx, "/use [@mouseover,exists,nodead] " .. slot
    end
    if not binding.value or binding.value == "" then return nil end
    if binding.kind == "spell" then
        return typeAttr, "spell", prefix .. "spell" .. idx, binding.value
    elseif binding.kind == "item" then
        -- Equipped item by slot ("slot:13"): a macro, so it follows swaps and works in combat.
        local slot = tostring(binding.value):match("^slot:(%d+)$")
        if slot then
            return typeAttr, "macro", prefix .. "macrotext" .. idx, "/use [@mouseover,exists,nodead] " .. slot
        end
        return typeAttr, "item", prefix .. "item" .. idx, binding.value
    elseif binding.kind == "macro" then
        local v = binding.value
        if v:match("^[/#]") then
            return typeAttr, "macro", prefix .. "macrotext" .. idx, v
        end
        -- A picked macro runs as its own text; a lookup by name does not always fire.
        local ok, body = pcall(GetMacroBody, v)
        if ok and type(body) == "string" and body ~= "" then
            return typeAttr, "macro", prefix .. "macrotext" .. idx, body
        end
        return typeAttr, "macro", prefix .. "macro" .. idx, v
    end
    return nil
end

-- Blizzard's gate: "target" with a modifier or off plain left click, and "togglemenu", only work through a
-- secure proxy button, reached with type="click".
local proxyOf = setmetatable({}, { __mode = "k" }) -- kept off the secure frame
local function clickProxy(button)
    local have = proxyOf[button]
    if have or InCombatLockdown() then return have end -- a secure frame cannot be made in combat
    have = CreateFrame("Button", nil, button, "SecureActionButtonTemplate")
    -- It takes the unit from the frame it hangs on and fires on release, never by mouse itself.
    have:SetAttribute("useOnKeyDown", false)
    have:SetAttribute("useparent-unit", true)
    have:RegisterForClicks("AnyDown", "AnyUp")
    have:EnableMouse(false)
    proxyOf[button] = have
    return have
end

local function isGated(typeAttr, action)
    if action == "togglemenu" then return true end
    if action ~= "target" then return false end
    if typeAttr:find("^type%-") then return true end
    local mod, num = typeAttr:match("^(.-)type(%d+)$")
    return mod and (mod ~= "" or tonumber(num) ~= 1) or false
end

-- Sets typeAttr (e.g. "shift-type1") to a plain action, through the proxy when the
-- gate needs it.
local function setPlainAction(button, typeAttr, action)
    if isGated(typeAttr, action) then
        local proxy = clickProxy(button)
        if proxy then
            button:SetAttribute(typeAttr, "click")
            button:SetAttribute((typeAttr:gsub("type", "clickbutton")), proxy)
            proxy:SetAttribute(typeAttr, action)
            return
        end
    end
    button:SetAttribute(typeAttr, action)
end

-- Clears every click-cast attribute slot before reapplying, so a removed or retyped binding stops
-- firing.
local appliedSlots = setmetatable({}, { __mode = "k" })
local SLOT_ATTRS = { "clickbutton", "type", "spell", "item", "macro", "macrotext" }

function CC.ClearAll(button)
    local slots = appliedSlots[button]
    if slots then
        for _, slot in ipairs(slots) do
            local prefix, idx = slot[1], slot[2]
            for _, a in ipairs(SLOT_ATTRS) do
                button:SetAttribute(prefix .. a .. idx, nil)
            end
            if proxyOf[button] then proxyOf[button]:SetAttribute(prefix .. "type" .. idx, nil) end
        end
        appliedSlots[button] = nil
    end
    for _, mod in ipairs(ALL_MODS) do
        local prefix = modPrefix(mod)
        for _, idx in pairs(BUTTON_INDEX) do
            button:SetAttribute(prefix .. "clickbutton" .. idx, nil)
            if proxyOf[button] then proxyOf[button]:SetAttribute(prefix .. "type" .. idx, nil) end
            button:SetAttribute(prefix .. "type" .. idx, nil)
            button:SetAttribute(prefix .. "spell" .. idx, nil)
            button:SetAttribute(prefix .. "item" .. idx, nil)
            button:SetAttribute(prefix .. "macro" .. idx, nil)
            button:SetAttribute(prefix .. "macrotext" .. idx, nil)
        end
    end
    for _, mod in ipairs(ALL_MODS) do
        for name in pairs(WHEEL) do
            local idx = wheelSuffix(mod, name)
            button:SetAttribute("clickbutton" .. idx, nil)
            if proxyOf[button] then proxyOf[button]:SetAttribute("type" .. idx, nil) end
            button:SetAttribute("type" .. idx, nil)
            button:SetAttribute("spell" .. idx, nil)
            button:SetAttribute("item" .. idx, nil)
            button:SetAttribute("macro" .. idx, nil)
            button:SetAttribute("macrotext" .. idx, nil)
        end
    end
end

-- Wheel bindings need the mouse-over override binding. One secure handler owns it; the wrapped
-- OnEnter/OnLeave/OnHide of each frame set and clear it, so it also works in combat.
local wheelHandler = CreateFrame("Frame", "NucleusWheelHandler", UIParent, "SecureHandlerBaseTemplate")
local wheelWrapped = setmetatable({}, { __mode = "k" })

local function wheelSnippet(bindings)
    local lines, seen = { "local btn = ..." }, {}
    for _, binding in ipairs(bindings or {}) do
        local key = WHEEL_KEY[binding.button] or keyOf(binding.button)
        if key and binding.kind ~= "none" and attrPairs(binding) then
            local mod = CC.NormalizeModifier(binding.modifier)
            local name = (mod == "none" and "" or (mod:gsub("-", ""))) .. hoverName(binding.button)
            if not seen[name] then
                seen[name] = true
                local full = (mod == "none" and "" or (mod:upper() .. "-")) .. key
                lines[#lines + 1] = ("self:SetBindingClick(true, %q, btn, %q)"):format(full, name)
            end
        end
    end
    return #lines > 1 and table.concat(lines, "\n") or ""
end

local function wrapWheel(button)
    if wheelWrapped[button] or not button:GetName() then return end -- the click target is found by name
    wheelWrapped[button] = true
    pcall(function()
        SecureHandlerWrapScript(button, "OnEnter", wheelHandler, [=[
            owner:ClearBindings()
            local snippet = owner:GetAttribute("wheelsnippet")
            if snippet and snippet ~= "" then owner:Run(snippet, self:GetName()) end
        ]=])
        SecureHandlerWrapScript(button, "OnLeave", wheelHandler, [=[ owner:ClearBindings() ]=])
        SecureHandlerWrapScript(button, "OnHide", wheelHandler, [=[ owner:ClearBindings() ]=])
    end)
end

function CC.Apply(button, bindings)
    local menuOnRight = false
    local slots = {}
    for _, binding in ipairs(bindings or {}) do
        local ta, tv, va, vv = attrPairs(binding)
        if ta then
            slots[#slots + 1] = { ta:match("^(.-)type"), ta:match("type(.*)$") }
            if va then
                button:SetAttribute(ta, tv)
                button:SetAttribute(va, vv)
            else
                setPlainAction(button, ta, tv)
            end
            if ta == "type2" then menuOnRight = true end
        end
    end
    appliedSlots[button] = slots
    -- A plain right click without a binding falls back to the header's togglemenu wildcard, which
    -- the gate blocks the same way, so route it through the proxy too.
    if not menuOnRight then setPlainAction(button, "type2", "togglemenu") end
end

-- Bindings are per class: clickCasting.bindings is the played class's list, the others live in byClass.
local function knownSpell(value)
    if value == nil or value == "" then return false end
    -- "Name(Rank N)": look the spell up by its name.
    if type(value) == "string" then value = value:gsub("%b()", "") end
    local ok, info = pcall(N.Compat.Spell.GetSpellInfo, value)
    return ok and info ~= nil
end

function CC.SelectClass()
    local cc = N.db and N.db.clickCasting
    local _, class = UnitClass("player")
    if not (cc and cc.byClass and class and cc.byClass[class]) then return end
    if not cc.migrated then
        -- Older saves had one shared list: each class starts from it and drops the spells it doesn't know.
        for c in pairs(cc.byClass) do cc.byClass[c] = N.DeepCopy(cc.bindings) end
        local mine = cc.byClass[class]
        for i = #mine, 1, -1 do
            if mine[i].kind == "spell" and not knownSpell(mine[i].value) then table.remove(mine, i) end
        end
        cc.migrated = true
    end
    local specID = N.Profiles and N.Profiles.GetSpec and N.Profiles.GetSpec()
    local own = specID and type(cc.bySpec) == "table" and cc.bySpec[specID]
    cc.bindings = (type(own) == "table" and own) or cc.byClass[class]
end

-- A button is only rewritten when its bindings changed since the last pass.
local appliedSig = setmetatable({}, { __mode = "k" })

local function bindingsSig(bindings, snippet)
    local t = { snippet }
    for _, binding in ipairs(bindings or {}) do
        local ta, tv, va, vv = attrPairs(binding)
        if ta then t[#t + 1] = ta .. "=" .. tostring(tv) .. "," .. tostring(va) .. "=" .. tostring(vv) end
    end
    return table.concat(t, "\n")
end

function CC.ApplyToAll()
    if not N.db or not N.UnitFrame then return end
    N.RunWhenSafe(function()
        local bindings = N.db.clickCasting and N.db.clickCasting.bindings
        local snippet = wheelSnippet(bindings)
        wheelHandler:SetAttribute("wheelsnippet", snippet)
        local sig = bindingsSig(bindings, snippet)
        N.UnitFrame.ForEachButton(function(b)
            local child = b._secure or b -- bindings live on the secure button
            if appliedSig[child] == sig then return end
            appliedSig[child] = sig
            CC.ClearAll(child)
            child:SetAttribute("*type1", "target")
            child:SetAttribute("*type2", "togglemenu")
            CC.Apply(child, bindings)
            if snippet ~= "" then wrapWheel(child) end
        end)
    end, "clickcasting-apply")
end

N:On("NUCLEUS_SETTING_CHANGED", function(_, section)
    if section == "clickCasting" then
        CC.SelectClass() -- the list in use may have changed (a specialization got its own)
        CC.ApplyToAll()
    end
end)

-- Bound macros run the text they had when applied: re-apply when a macro is edited.
local macroWatcher = CreateFrame("Frame")
N.SafeRegister(macroWatcher, "UPDATE_MACROS")
local macroPending
macroWatcher:SetScript("OnEvent", function()
    if macroPending then return end
    macroPending = true
    C_Timer.After(1, function()
        macroPending = false
        CC.ApplyToAll()
    end)
end)

local specWatcher = CreateFrame("Frame")
N.SafeRegister(specWatcher, "PLAYER_SPECIALIZATION_CHANGED")
specWatcher:SetScript("OnEvent", function(_, _, unit)
    if unit and unit ~= "player" then return end
    C_Timer.After(0.5, function()
        CC.SelectClass()
        CC.ApplyToAll()
    end)
end)

-- Re-apply whenever the header may have (re)built children, same cadence as HeaderGroup's
-- re-style, so a child created in combat gets its bindings once combat ends.
local watcher = CreateFrame("Frame")
N.SafeRegister(watcher, "GROUP_ROSTER_UPDATE")
N.SafeRegister(watcher, "PLAYER_ENTERING_WORLD")
N.SafeRegister(watcher, "PLAYER_REGEN_ENABLED")
watcher:SetScript("OnEvent", CC.ApplyToAll)

-- Pick the class's list once the spellbook is readable (a hidden spellbook would make every spell
-- look unknown), then again on a profile switch.
local selectTries = 0
local function trySelect()
    if IsPlayerSpell and IsPlayerSpell(6603) or selectTries >= 6 then -- 6603: Auto Attack
        if IsPlayerSpell and IsPlayerSpell(6603) then
            CC.SelectClass()
            CC.ApplyToAll()
        end
    else
        selectTries = selectTries + 1
        C_Timer.After(2, trySelect)
    end
end
local selector = CreateFrame("Frame")
N.SafeRegister(selector, "PLAYER_ENTERING_WORLD")
selector:SetScript("OnEvent", function() C_Timer.After(1, trySelect) end)

N:On("NUCLEUS_PROFILE_CHANGED", function()
    CC.SelectClass()
    CC.ApplyToAll()
end)

function CC.Init()
    CC.ApplyToAll()
end

-- /nucdebug helper: what each saved binding resolves to, and what is actually
-- on the first unit button (the real secure attributes).
function CC.DebugDump()
    local cc = N.db and N.db.clickCasting
    if not cc then return end
    N:Print("click-cast: bindings =", #cc.bindings)
    local btn
    N.UnitFrame.ForEachButton(function(child) btn = btn or child._secure or child end)
    for i, b in ipairs(cc.bindings) do
        local ta, tv, va, vv = attrPairs(b)
        local live = ta and btn and btn:GetAttribute(ta) or nil
        N:Print(("  #%d mod=%s btn=%s kind=%s value=%s -> %s=%s %s=%s | on button: %s")
            :format(i, tostring(b.modifier), tostring(b.button), tostring(b.kind),
                tostring(b.value), tostring(ta), tostring(tv), tostring(va), tostring(vv),
                tostring(live)))
    end
end
