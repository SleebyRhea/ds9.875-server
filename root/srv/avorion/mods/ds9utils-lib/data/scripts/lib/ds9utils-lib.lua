--[[

    DS9 Utilities - Mod Library
    ---------------------------
    Simple mod library that is required by mods
    in the DS9 Utility suite.

    License: WTFPL
	Info: https://en.wikipedia.org/wiki/WTFPL

]]

-- Used for future proofing in case the Avorion devs decide to change
-- which Lua version they are using. For now, they seem to use 5.1
-- (or more likely, a superset of Luajit). Table.unpack is done first for
-- simplicity here, but the global unpack is what is expected as of this comment.
_G.unpack = (type(table.unpack) == "function" and table.unpack or _G.unpack)

do
    local __vanilla_print = _G.print
    local __d = {
        i_modname = "ds9utils-lib",
        i_loadermod = false
    }

    -- Print override that adds mod info
    function _G.print(...)
        local __modinfo = ""

		if type(__d.i_loadermod) == "string" then
            __modinfo = "[" .. __d.i_loadermod .. "] "
        end

        io.write(__modinfo)

        return __vanilla_print(...)
    end

    -- Determines if the function[s] given are present in the global namespace
    -- and returns false (as well as outputs an error) if they are not. Not really
    -- used too much, but the Avorion binary *does* use a modified version of the 
    -- Lua interpreter, so this is here as a safeguard.
    function _G.needs(...)
        for _,v in pairs({...}) do
            if not _G[v] then
                print(
                    "Dependency unment in <"..
                    (__d.i_loadermod and __d.i_loadermod or __d.i_modname)..
                    ">. Global function ".. v..
                    " was not found in the Global namespace."
                )
                return false, "Global function "..v.." is not present"
            end
        end
    end

    -- Returns Player of a given id or name.
    -- Returns nil and an error message if not found.
    -- Modified from: https://github.com/TerminusLi/avorion-commands
    function _G.findPlayerByName(request_name)
        --[[
        MIT License

        Copyright (c) 2019 TerminusLi

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
        ]]

        -- In case if player index is passed.
        -- Players have indices starting from 1. Their list ends with faction === nil.
        local player_table = {Galaxy():getPlayerNames()}
        for k,name in pairs(player_table) do
            if request_name == name then
                return Player(k)
            end
        end
        return nil
    end

    -- Return a callable table that, when provided a string, will set the name
    -- of the mod that included this library. If no string is returned, then do
    -- nothing but source the file.
    return setmetatable(
        {},
        {
            __call = function(_, modData)
                if type(modData) == "string" then
                    __d["i_loadermod"] = modData
                end
            end,
        }
    )
end