-- Print override for timestamps
do
    local __vanilla_print = _G.print
    local __d = {
        i_modname = "ds9utils-lib",
        i_loadermod = false
    }

    function _G.print(...)
        local __modinfo = ""
        local __timeinfo = "(" .. os.date("%Y-%m-%d %H:%M:%S") .. ") "

        if __d.i_loadermod then
            __modinfo = "[" .. __d.i_loadermod .. "] "
        end

        io.write(__timeinfo..__modinfo)

        return __vanilla_print(...)
    end

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