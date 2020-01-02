--[[

    DS9 Utilities - Mod Library
    ---------------------------
    Simple mod library that is required by mods
    in the DS9 Utility suite.

    License: WTFPL
	Info: https://en.wikipedia.org/wiki/WTFPL

]]

do
    local __vanilla_print = _G.print
    local __d = {
        i_modname = "ds9utils-lib",
        i_loadermod = false
    }

    -- Print override that adds mod info and timestamps
    function _G.print(...)
        local __modinfo = ""
        local __timeinfo = "(" .. os.date("%Y-%m-%d %H:%M:%S") .. ") "

        if __d.i_loadermod then
            __modinfo = "[" .. __d.i_loadermod .. "] "
        end

        io.write(__timeinfo..__modinfo)

        return __vanilla_print(...)
    end

    -- Return a callable table that, when provided a string, will set the name
    -- of the mod that included this library. If no string is returned, then do
    -- nothing but source the file.
    return setmetatable(
        {},
        {
            __call = function(_, modname)
                if type(modname) == "string" then
                    __d["i_loadermod"] = modname
                end
            end,
        }
    )
end