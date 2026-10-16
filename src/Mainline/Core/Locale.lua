local _, ns = ...
local N = ns.N

-- enUS is the base, other files add overrides. Missing keys fall back to the key itself.

local base = {}
local overrides = {}
local strings = base
local reverse

N.L = setmetatable({}, {
    __index = function(_, key)
        return strings[key] or base[key] or key
    end,
})

function N.RegisterLocale(locale, tbl, isBase)
    if isBase then
        for k, v in pairs(tbl) do base[k] = base[k] or v end
        return
    end
    overrides[locale] = overrides[locale] or {}
    for k, v in pairs(tbl) do overrides[locale][k] = v end
end

-- The English text of a (translated) string, for searching in either language.
function N.EnglishOf(text)
    if not reverse then
        reverse = {}
        for key, en in pairs(base) do
            local loc = strings[key] or en
            if type(loc) == "string" and not reverse[loc] then reverse[loc] = en end
        end
    end
    return reverse[text]
end

function N.ApplyLocale(locale)
    reverse = nil
    if locale == "auto" or not locale then locale = GetLocale() end
    if overrides[locale] then
        strings = setmetatable({}, { __index = base })
        for k, v in pairs(overrides[locale]) do strings[k] = v end
    else
        strings = base
    end
end

N:On("NUCLEUS_DB_READY", function()
    N.ApplyLocale(N.db.locale)
end)
N:On("NUCLEUS_SETTING_CHANGED", function(_, _, path)
    if path == "locale" then N.ApplyLocale(N.db.locale) end
end)
